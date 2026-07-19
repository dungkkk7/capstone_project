#include "OLLVMDeobf.h"

#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/MemorySSA.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/SHA256.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"
#include <z3++.h>

#include <algorithm>
#include <climits>
#include <functional>
#include <optional>
#include <string>
#include <tuple>
#include <unordered_map>

using namespace llvm;

namespace brighten_ollvm_deobf {
namespace {

static cl::opt<std::string> ReportPath(
    "ollvm-deobf-report", cl::desc("Write the OLLVM proof ledger as JSON"),
    cl::init(""));

struct Metrics {
  unsigned Functions = 0;
  unsigned Switches = 0;
  unsigned LargeSwitches = 0;
  unsigned LiftedFunctions = 0;
  unsigned FlagsSanitized = 0;
  unsigned FlagConesRecovered = 0;
  unsigned BVRewrites = 0;
  unsigned InstSubRewrites = 0;
  unsigned OpaqueEdgesPruned = 0;
  unsigned PathConstrainedOpaqueEdges = 0;
  unsigned MemorySSAConstrainedOpaqueEdges = 0;
  unsigned PathStateITEOpaqueEdges = 0;
  unsigned InductivePhiOpaqueEdges = 0;
  unsigned MemorySSAReachingLoads = 0;
  unsigned MemorySSAPhisResolved = 0;
  unsigned MemorySSABarriers = 0;
  unsigned CompareLaddersRecovered = 0;
  unsigned EGraphRewrites = 0;
  unsigned PoisonSupportRejects = 0;
  unsigned DispatchersRecovered = 0;
  unsigned DispatchersUnresolved = 0;
  unsigned VerifierFailures = 0;
};

struct LiftProfile {
  struct FrameObject {
    std::string Base;
    int64_t Offset = 0;
    uint64_t Size = 0;
    unsigned Loads = 0;
    unsigned Stores = 0;
    bool HasOverlappingViews = false;
    std::string Role = "frame.local";
  };
  unsigned DefinedFunctions = 0;
  unsigned RuntimeHelpers = 0;
  unsigned SmallWrapperCandidates = 0;
  unsigned FrameBackingGlobals = 0;
  unsigned StateStructTypes = 0;
  unsigned InlineAsmCalls = 0;
  unsigned IndirectCalls = 0;
  unsigned IndirectBranches = 0;
  unsigned AddressConversions = 0;
  unsigned UndefOperands = 0;
  unsigned PoisonOperands = 0;
  unsigned ConditionalBranches = 0;
  unsigned ConstantCompareBranches = 0;
  SmallVector<std::string, 8> CandidateStateLocations;
  SmallVector<FrameObject, 16> FrameObjects;
};

struct ProofRecord {
  std::string Function;
  std::string Kind;
  std::string Origin;
  std::string Engine;
  std::string Result;
  std::string ResidualReason;
  std::string OldHash;
  std::string NewHash;
  std::string ProofQueryHash;
  SmallVector<std::string, 2> Dependencies;
};

static std::string hashText(StringRef Text) {
  SHA256 Hash;
  Hash.update(Text);
  auto Digest = Hash.final();
  return toHex(ArrayRef<uint8_t>(Digest), true);
}

static std::string valueText(const Value &V) {
  std::string Text;
  raw_string_ostream OS(Text);
  V.print(OS);
  return Text;
}

static void importExistingProofs(Module &M, Metrics &Stats,
                                 SmallVectorImpl<ProofRecord> &Proofs) {
  NamedMDNode *Ledger = M.getNamedMetadata("ollvm.deobf.proofs");
  if (!Ledger) return;
  for (MDNode *Node : Ledger->operands()) {
    if (Node->getNumOperands() < 5) continue;
    auto Get = [&](unsigned I) -> std::string {
      auto *S = dyn_cast<MDString>(Node->getOperand(I));
      return S ? S->getString().str() : std::string();
    };
    ProofRecord P{Get(0), Get(1), Get(2), Get(3), Get(4),
                  Node->getNumOperands() > 5 ? Get(5) : std::string()};
    if (Node->getNumOperands() > 6) P.OldHash = Get(6);
    if (Node->getNumOperands() > 7) P.NewHash = Get(7);
    if (Node->getNumOperands() > 8) P.ProofQueryHash = Get(8);
    if (Node->getNumOperands() > 9) {
      std::string EncodedDependencies = Get(9);
      SmallVector<StringRef, 4> Parts;
      StringRef(EncodedDependencies).split(Parts, '\x1f', -1, false);
      for (StringRef Part : Parts) P.Dependencies.push_back(Part.str());
    }
    if (P.Result == "unresolved" && P.Kind == "cff_candidate") {
      // Carry the obligation until end-of-round reconciliation.  Merely
      // changing the state PHI/switch shape must never erase a residual.
      ++Stats.DispatchersUnresolved;
      Proofs.push_back(std::move(P));
      continue;
    }
    // Unresolved classifications must be re-evaluated after cleanup; only
    // completed proofs survive into the next fixed-point round.
    if (P.Result != "proved") continue;
    if (P.Kind == "lifted_semantics_sanitize") ++Stats.FlagsSanitized;
    else if (P.Kind == "x86_flag_recovery") ++Stats.FlagConesRecovered;
    else if (P.Kind == "bv_canonicalize") ++Stats.BVRewrites;
    else if (P.Kind == "instsub_rewrite") {
      ++Stats.BVRewrites;
      ++Stats.InstSubRewrites;
    } else if (P.Kind == "opaque_edge") {
      ++Stats.OpaqueEdgesPruned;
      if (StringRef(P.Engine).contains("dominating_constraints"))
        ++Stats.PathConstrainedOpaqueEdges;
      if (StringRef(P.Engine).starts_with("z3_memoryssa"))
        ++Stats.MemorySSAConstrainedOpaqueEdges;
      if (StringRef(P.Engine).contains("path_state_ite"))
        ++Stats.PathStateITEOpaqueEdges;
      if (StringRef(P.Engine).contains("inductive_constant_phi"))
        ++Stats.InductivePhiOpaqueEdges;
    }
    else if (P.Kind == "compare_ladder") ++Stats.CompareLaddersRecovered;
    else if (P.Kind == "bv_egraph_rewrite") ++Stats.EGraphRewrites;
    else if (P.Kind == "cff_dispatcher") ++Stats.DispatchersRecovered;
    Proofs.push_back(std::move(P));
  }
}

static std::string valueName(const Value &V) {
  if (V.hasName())
    return V.getName().str();
  std::string S;
  raw_string_ostream OS(S);
  V.printAsOperand(OS, false);
  return S;
}

static bool containsLiftMarker(StringRef S) {
  return S.contains_insensitive("remill") ||
         S.contains_insensitive("mcsema") ||
         S.contains_insensitive("frame_storage_backing") ||
         S.contains_insensitive("struct.State");
}

static bool valueContainsLiftMarker(const Value *V, unsigned Depth = 0) {
  if (!V || Depth > 12) return false;
  if (const auto *GV = dyn_cast<GlobalValue>(V))
    return containsLiftMarker(GV->getName());
  if (V->hasName() && containsLiftMarker(V->getName())) return true;
  const auto *U = dyn_cast<User>(V);
  if (!U) return false;
  for (const Use &Op : U->operands())
    if (valueContainsLiftMarker(Op.get(), Depth + 1)) return true;
  return false;
}

static bool isLiftedFunction(const Function &F) {
  if (containsLiftMarker(F.getName()))
    return true;
  for (const Argument &A : F.args()) {
    if (A.hasName() && containsLiftMarker(A.getName()))
      return true;
  }
  for (const Instruction &I : instructions(F)) {
    for (const Use &U : I.operands())
      if (valueContainsLiftMarker(U.get())) return true;
  }
  return false;
}

static bool hasPoisonGeneratingFlags(const Value *V) {
  const auto *OBO = dyn_cast<OverflowingBinaryOperator>(V);
  if (OBO && (OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap()))
    return true;
  const auto *PEO = dyn_cast<PossiblyExactOperator>(V);
  return PEO && PEO->isExact();
}

static bool samePair(Value *A0, Value *A1, Value *B0, Value *B1) {
  return (A0 == B0 && A1 == B1) || (A0 == B1 && A1 == B0);
}

static bool matchBin(Value *V, unsigned Opcode, Value *&A, Value *&B) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Opcode)
    return false;
  A = BO->getOperand(0);
  B = BO->getOperand(1);
  return true;
}

static bool matchAllOnesXor(Value *V, Value *&X) {
  Value *A = nullptr, *B = nullptr;
  if (!matchBin(V, Instruction::Xor, A, B))
    return false;
  auto IsAllOnes = [](Value *C) {
    auto *CI = dyn_cast<ConstantInt>(C);
    return CI && CI->isMinusOne();
  };
  if (IsAllOnes(A)) { X = B; return true; }
  if (IsAllOnes(B)) { X = A; return true; }
  return false;
}

static Value *createBinLike(BinaryOperator &Old, unsigned Opcode, Value *A,
                            Value *B) {
  IRBuilder<> Builder(&Old);
  return Builder.CreateBinOp(static_cast<Instruction::BinaryOps>(Opcode), A, B,
                             Old.getName() + ".deobf");
}

// Exact APInt/bit-vector identities only.  No rule here assumes unbounded
// integer arithmetic or crosses a memory/call boundary.
static Value *matchCanonicalRewrite(BinaryOperator &I, bool &InstSub) {
  if (!I.getType()->isIntOrIntVectorTy() || hasPoisonGeneratingFlags(&I))
    return nullptr;
  Value *A = I.getOperand(0), *B = I.getOperand(1);
  Value *X = nullptr, *Y = nullptr, *P = nullptr, *Q = nullptr;
  auto IsZeroConstant = [](Value *V) {
    auto *C = dyn_cast<Constant>(V);
    return C && C->isNullValue();
  };
  auto IsAllOnesConstant = [](Value *V) {
    auto *C = dyn_cast<Constant>(V);
    return C && C->isAllOnesValue();
  };

  // Neutral elements, valid at every fixed integer width.
  if ((I.getOpcode() == Instruction::Add ||
       I.getOpcode() == Instruction::Xor ||
       I.getOpcode() == Instruction::Or) && IsZeroConstant(B))
    return A;
  if (I.getOpcode() == Instruction::Add && IsZeroConstant(A)) return B;
  if (I.getOpcode() == Instruction::And && IsAllOnesConstant(B)) return A;
  if (I.getOpcode() == Instruction::And && IsAllOnesConstant(A)) return B;

  // ~~x, with LLVM's canonical not representation xor -1.
  if (I.getOpcode() == Instruction::Xor && IsAllOnesConstant(B) &&
      matchAllOnesXor(A, X) && !hasPoisonGeneratingFlags(A))
    return X;

  // (x + C) - C and (x - C) + C.
  if ((I.getOpcode() == Instruction::Sub ||
       I.getOpcode() == Instruction::Add) && isa<ConstantInt>(B)) {
    unsigned InnerOp = I.getOpcode() == Instruction::Sub
                           ? Instruction::Add : Instruction::Sub;
    if (matchBin(A, InnerOp, X, Y) && Y == B &&
        !hasPoisonGeneratingFlags(A))
      return X;
  }

  // (x & ~C) + (x | C) == x + (x ^ C).
  if (I.getOpcode() == Instruction::Add) {
    Value *AndV = A, *OrV = B;
    if (!isa<BinaryOperator>(AndV) ||
        cast<BinaryOperator>(AndV)->getOpcode() != Instruction::And)
      std::swap(AndV, OrV);
    Value *AndX = nullptr, *AndMask = nullptr, *OrX = nullptr, *OrMask = nullptr;
    if (matchBin(AndV, Instruction::And, AndX, AndMask) &&
        matchBin(OrV, Instruction::Or, OrX, OrMask)) {
      auto TryMask = [&](Value *VX, Value *NotMask, Value *OX,
                         Value *Mask) -> Value * {
        auto *NC = dyn_cast<ConstantInt>(NotMask);
        auto *C = dyn_cast<ConstantInt>(Mask);
        if (VX != OX || !NC || !C || NC->getValue() != ~C->getValue())
          return nullptr;
        Value *XC = createBinLike(I, Instruction::Xor, VX, Mask);
        InstSub = true;
        return createBinLike(I, Instruction::Add, VX, XC);
      };
      if (Value *R = TryMask(AndX, AndMask, OrX, OrMask)) return R;
      if (Value *R = TryMask(AndMask, AndX, OrX, OrMask)) return R;
      if (Value *R = TryMask(AndX, AndMask, OrMask, OrX)) return R;
      if (Value *R = TryMask(AndMask, AndX, OrMask, OrX)) return R;
    }
  }

  // (x | y) + (x & y) == x + y, including commuted outer operands.
  if (I.getOpcode() == Instruction::Add) {
    Value *OrV = A, *AndV = B;
    if (!matchBin(OrV, Instruction::Or, X, Y)) {
      std::swap(OrV, AndV);
      X = Y = nullptr;
    }
    if (matchBin(OrV, Instruction::Or, X, Y) &&
        matchBin(AndV, Instruction::And, P, Q) &&
        samePair(X, Y, P, Q)) {
      InstSub = true;
      return createBinLike(I, Instruction::Add, X, Y);
    }
  }

  // (x ^ y) + 2*(x & y) == x + y.
  if (I.getOpcode() == Instruction::Add) {
    Value *XorV = A, *CarryV = B;
    if (!matchBin(XorV, Instruction::Xor, X, Y)) {
      std::swap(XorV, CarryV);
      X = Y = nullptr;
    }
    if (!matchBin(XorV, Instruction::Xor, X, Y)) return nullptr;
    Value *M0 = nullptr, *M1 = nullptr;
    if (matchBin(CarryV, Instruction::Mul, M0, M1)) {
      auto IsTwo = [](Value *V) {
        auto *C = dyn_cast<ConstantInt>(V);
        return C && C->equalsInt(2);
      };
      Value *AndV = IsTwo(M0) ? M1 : (IsTwo(M1) ? M0 : nullptr);
      if (AndV && matchBin(AndV, Instruction::And, P, Q) &&
          samePair(X, Y, P, Q)) {
        InstSub = true;
        return createBinLike(I, Instruction::Add, X, Y);
      }
    }
    Value *Shifted = nullptr, *One = nullptr;
    if (matchBin(CarryV, Instruction::Shl, Shifted, One)) {
      auto *C = dyn_cast<ConstantInt>(One);
      if (C && C->isOne() &&
          matchBin(Shifted, Instruction::And, P, Q) &&
          samePair(X, Y, P, Q)) {
        InstSub = true;
        return createBinLike(I, Instruction::Add, X, Y);
      }
    }
  }

  // (x + y) - (x | y) == x & y.
  if (I.getOpcode() == Instruction::Sub &&
      matchBin(A, Instruction::Add, X, Y) &&
      matchBin(B, Instruction::Or, P, Q) && samePair(X, Y, P, Q) &&
      !hasPoisonGeneratingFlags(A)) {
    InstSub = true;
    return createBinLike(I, Instruction::And, X, Y);
  }

  // (a & b) | (a ^ b) == a | b.
  if (I.getOpcode() == Instruction::Or &&
      matchBin(A, Instruction::And, X, Y) &&
      matchBin(B, Instruction::Xor, P, Q) && samePair(X, Y, P, Q)) {
    InstSub = true;
    return createBinLike(I, Instruction::Or, X, Y);
  }

  // (~a & b) | (a & ~b) == a ^ b.
  if (I.getOpcode() == Instruction::Or &&
      matchBin(A, Instruction::And, X, Y) &&
      matchBin(B, Instruction::And, P, Q)) {
    Value *NX = nullptr, *NQ = nullptr;
    if (matchAllOnesXor(X, NX) && matchAllOnesXor(Q, NQ) &&
        NX == P && Y == NQ) {
      InstSub = true;
      return createBinLike(I, Instruction::Xor, P, Y);
    }
    if (matchAllOnesXor(Y, NX) && matchAllOnesXor(P, NQ) &&
        NX == Q && X == NQ) {
      InstSub = true;
      return createBinLike(I, Instruction::Xor, X, Q);
    }
  }
  return nullptr;
}

static bool isOne(const Value *V) {
  const auto *C = dyn_cast<ConstantInt>(V);
  return C && C->isOne();
}

static bool isZero(const Value *V) {
  const auto *C = dyn_cast<ConstantInt>(V);
  return C && C->isZero();
}

static bool isAdjacentProduct(Value *V) {
  Value *A = nullptr, *B = nullptr;
  if (!matchBin(V, Instruction::Mul, A, B) || hasPoisonGeneratingFlags(V))
    return false;
  auto IsMinusOneFrom = [](Value *Candidate, Value *Root) {
    Value *L = nullptr, *R = nullptr;
    if (matchBin(Candidate, Instruction::Sub, L, R))
      return L == Root && isOne(R) && !hasPoisonGeneratingFlags(Candidate);
    if (matchBin(Candidate, Instruction::Add, L, R)) {
      auto *C = dyn_cast<ConstantInt>(R);
      return L == Root && C && C->isMinusOne() &&
             !hasPoisonGeneratingFlags(Candidate);
    }
    return false;
  };
  return IsMinusOneFrom(A, B) || IsMinusOneFrom(B, A);
}

// Proves only theorem-library facts.  Unknown is represented by nullopt and
// is never converted into a rewrite.
static std::optional<bool> proveBoolean(Value *V, unsigned Depth = 0) {
  if (Depth > 12)
    return std::nullopt;
  if (auto *C = dyn_cast<ConstantInt>(V))
    if (C->getType()->isIntegerTy(1))
      return !C->isZero();

  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    Value *L = Cmp->getOperand(0), *R = Cmp->getOperand(1);
    Value *AndL = nullptr, *Mask = nullptr;
    if (!matchBin(L, Instruction::And, AndL, Mask)) {
      std::swap(L, R);
      if (!matchBin(L, Instruction::And, AndL, Mask))
        return std::nullopt;
    }
    if (!isOne(Mask) || !isZero(R) || !isAdjacentProduct(AndL))
      return std::nullopt;
    if (Cmp->getPredicate() == ICmpInst::ICMP_EQ)
      return true;
    if (Cmp->getPredicate() == ICmpInst::ICMP_NE)
      return false;
    return std::nullopt;
  }

  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || !BO->getType()->isIntegerTy(1))
    return std::nullopt;
  auto L = proveBoolean(BO->getOperand(0), Depth + 1);
  auto R = proveBoolean(BO->getOperand(1), Depth + 1);
  if (BO->getOpcode() == Instruction::Or) {
    if ((L && *L) || (R && *R)) return true;
    if (L && R) return *L || *R;
  }
  if (BO->getOpcode() == Instruction::And) {
    if ((L && !*L) || (R && !*R)) return false;
    if (L && R) return *L && *R;
  }
  if (BO->getOpcode() == Instruction::Xor && L && R)
    return *L != *R;
  return std::nullopt;
}

static std::optional<APInt> evalStateExpr(Value *V, PHINode *Root,
                                          const APInt &State,
                                          unsigned Depth = 0);
static std::optional<bool> evalStatePredicate(Value *V, PHINode *Root,
                                              const APInt &State,
                                              unsigned Depth = 0);

class Z3BVTranslator {
  z3::context &Ctx;
  std::unordered_map<const Value *, z3::expr> Cache;
  const DenseMap<const LoadInst *, Value *> *ReachingLoadValues = nullptr;
  SmallPtrSet<const LoadInst *, 8> ResolvedLoads;
  SmallPtrSet<const PHINode *, 8> ResolvedDiamondPhis;
  SmallPtrSet<const PHINode *, 8> ResolvedSwitchPhis;
  SmallPtrSet<const PHINode *, 8> ResolvedInductivePhis;
  SmallPtrSet<const Value *, 8> TranslationStack;
  std::string SliceCertificate;
  unsigned SymbolID = 0;

  std::optional<z3::expr> makeLeaf(Value *V) {
    Type *Ty = V->getType();
    std::string Name = "llvm_v_" + std::to_string(SymbolID++);
    if (Ty->isIntegerTy(1)) return Ctx.bool_const(Name.c_str());
    if (Ty->isIntegerTy())
      return Ctx.bv_const(Name.c_str(), Ty->getIntegerBitWidth());
    return std::nullopt;
  }

  std::optional<z3::expr> translateBinary(BinaryOperator &BO) {
    if (hasPoisonGeneratingFlags(&BO)) return std::nullopt;
    auto L = translate(BO.getOperand(0));
    auto R = translate(BO.getOperand(1));
    if (!L || !R) return std::nullopt;
    if (BO.getType()->isIntegerTy(1)) {
      if (!L->is_bool() || !R->is_bool()) return std::nullopt;
      switch (BO.getOpcode()) {
      case Instruction::And: return *L && *R;
      case Instruction::Or: return *L || *R;
      case Instruction::Xor: return *L != *R;
      default: return std::nullopt;
      }
    }
    if (!L->is_bv() || !R->is_bv()) return std::nullopt;
    switch (BO.getOpcode()) {
    case Instruction::Add: return *L + *R;
    case Instruction::Sub: return *L - *R;
    case Instruction::Mul: return *L * *R;
    case Instruction::And: return *L & *R;
    case Instruction::Or: return *L | *R;
    case Instruction::Xor: return *L ^ *R;
    case Instruction::Shl:
    case Instruction::LShr:
    case Instruction::AShr: {
      auto *Count = dyn_cast<ConstantInt>(BO.getOperand(1));
      if (!Count || Count->getValue().uge(BO.getType()->getIntegerBitWidth()))
        return std::nullopt;
      if (BO.getOpcode() == Instruction::Shl) return z3::shl(*L, *R);
      if (BO.getOpcode() == Instruction::LShr) return z3::lshr(*L, *R);
      return z3::ashr(*L, *R);
    }
    default: return std::nullopt;
    }
  }

public:
  explicit Z3BVTranslator(
      z3::context &C,
      const DenseMap<const LoadInst *, Value *> *ReachingLoadValues = nullptr)
      : Ctx(C), ReachingLoadValues(ReachingLoadValues) {}

  unsigned getResolvedLoadCount() const { return ResolvedLoads.size(); }
  unsigned getResolvedDiamondPhiCount() const {
    return ResolvedDiamondPhis.size();
  }
  unsigned getResolvedSwitchPhiCount() const {
    return ResolvedSwitchPhis.size();
  }
  unsigned getResolvedInductivePhiCount() const {
    return ResolvedInductivePhis.size();
  }
  StringRef getSliceCertificate() const { return SliceCertificate; }

  std::optional<z3::expr> translate(Value *V) {
    auto Cached = Cache.find(V);
    if (Cached != Cache.end()) return Cached->second;
    if (!TranslationStack.insert(V).second) return std::nullopt;
    std::optional<z3::expr> Result;
    if (auto *CI = dyn_cast<ConstantInt>(V)) {
      if (CI->getType()->isIntegerTy(1)) {
        Result = Ctx.bool_val(!CI->isZero());
      } else {
        SmallString<80> Text;
        CI->getValue().toString(Text, 10, false);
        Result = Ctx.bv_val(Text.c_str(), CI->getBitWidth());
      }
    } else if (auto *LI = dyn_cast<LoadInst>(V)) {
      if (ReachingLoadValues) {
        auto It = ReachingLoadValues->find(LI);
        if (It != ReachingLoadValues->end()) {
          Result = translate(It->second);
          if (Result && ResolvedLoads.insert(LI).second) {
            raw_string_ostream OS(SliceCertificate);
            OS << "memoryssa-load:" << valueText(*LI) << '\n'
               << "reaching-value:" << valueText(*It->second) << '\n';
          }
        }
      }
      if (!Result) Result = makeLeaf(V);
    } else if (auto *II = dyn_cast<IntrinsicInst>(V)) {
      if (II->getIntrinsicID() == Intrinsic::ctpop &&
          II->getType()->isIntegerTy()) {
        auto Op = translate(II->getArgOperand(0));
        unsigned Width = II->getType()->getIntegerBitWidth();
        if (Op && Op->is_bv()) {
          z3::expr Sum = Ctx.bv_val(0, Width);
          for (unsigned Bit = 0; Bit != Width; ++Bit)
            Sum = Sum + z3::zext(Op->extract(Bit, Bit), Width - 1);
          Result = Sum;
        }
      } else if ((II->getIntrinsicID() == Intrinsic::bswap ||
                  II->getIntrinsicID() == Intrinsic::bitreverse) &&
                 II->getType()->isIntegerTy()) {
        auto Op = translate(II->getArgOperand(0));
        unsigned Width = II->getType()->getIntegerBitWidth();
        unsigned Unit = II->getIntrinsicID() == Intrinsic::bswap ? 8 : 1;
        if (Op && Op->is_bv() && Width % Unit == 0 && Width >= Unit) {
          z3::expr Reversed = Op->extract(Unit - 1, 0);
          for (unsigned Low = Unit; Low != Width; Low += Unit)
            Reversed = z3::concat(
                Reversed, Op->extract(Low + Unit - 1, Low));
          Result = Reversed;
        }
      } else if ((II->getIntrinsicID() == Intrinsic::fshl ||
           II->getIntrinsicID() == Intrinsic::fshr) &&
          II->getArgOperand(0) == II->getArgOperand(1) &&
          II->getType()->isIntegerTy()) {
        auto Op = translate(II->getArgOperand(0));
        auto Amount = translate(II->getArgOperand(2));
        unsigned Width = II->getType()->getIntegerBitWidth();
        if (Amount && Op && Op->is_bv() && Amount->is_bv() &&
            Amount->get_sort().bv_size() == Width) {
          z3::expr WidthBV = Ctx.bv_val(Width, Width);
          z3::expr Rotate = z3::urem(*Amount, WidthBV);
          z3::expr Reverse = z3::urem(WidthBV - Rotate, WidthBV);
          Result = II->getIntrinsicID() == Intrinsic::fshl
                       ? z3::shl(*Op, Rotate) | z3::lshr(*Op, Reverse)
                       : z3::lshr(*Op, Rotate) | z3::shl(*Op, Reverse);
        }
      }
    } else if (auto *PN = dyn_cast<PHINode>(V)) {
      if (PN->getNumIncomingValues() == 2) {
        BasicBlock *P0 = PN->getIncomingBlock(0);
        BasicBlock *P1 = PN->getIncomingBlock(1);
        BasicBlock *Split = P0->getSinglePredecessor();
        auto *BI = Split && Split == P1->getSinglePredecessor()
                       ? dyn_cast<BranchInst>(Split->getTerminator())
                       : nullptr;
        if (BI && BI->isConditional() &&
            ((BI->getSuccessor(0) == P0 && BI->getSuccessor(1) == P1) ||
             (BI->getSuccessor(0) == P1 && BI->getSuccessor(1) == P0))) {
          auto C = translate(BI->getCondition());
          auto V0 = translate(PN->getIncomingValue(0));
          auto V1 = translate(PN->getIncomingValue(1));
          if (C && V0 && V1 && C->is_bool() &&
              V0->get_sort().is_bool() == V1->get_sort().is_bool() &&
              V0->get_sort().is_bv() == V1->get_sort().is_bv()) {
            Result = BI->getSuccessor(0) == P0
                         ? z3::ite(*C, *V0, *V1)
                         : z3::ite(*C, *V1, *V0);
            if (ResolvedDiamondPhis.insert(PN).second) {
              raw_string_ostream OS(SliceCertificate);
              OS << "diamond-phi:" << valueText(*PN) << '\n'
                 << "diamond-guard:" << valueText(*BI->getCondition()) << '\n'
                 << "diamond-true:"
                 << valueText(*(BI->getSuccessor(0) == P0
                                    ? PN->getIncomingValue(0)
                                    : PN->getIncomingValue(1)))
                 << '\n' << "diamond-false:"
                 << valueText(*(BI->getSuccessor(0) == P0
                                    ? PN->getIncomingValue(1)
                                    : PN->getIncomingValue(0)))
                 << '\n';
            }
          }
        }
      }
      if (!Result && PN->getNumIncomingValues() >= 2) {
        BasicBlock *Split = PN->getIncomingBlock(0)->getSinglePredecessor();
        auto *SI = Split ? dyn_cast<SwitchInst>(Split->getTerminator()) : nullptr;
        bool ExactFunnel = SI != nullptr;
        for (unsigned I = 0; ExactFunnel && I != PN->getNumIncomingValues();
             ++I) {
          BasicBlock *Arm = PN->getIncomingBlock(I);
          auto *ArmBranch = dyn_cast<BranchInst>(Arm->getTerminator());
          bool IsSwitchSuccessor = false;
          for (unsigned S = 0; S != SI->getNumSuccessors(); ++S)
            IsSwitchSuccessor |= SI->getSuccessor(S) == Arm;
          ExactFunnel = Arm->getSinglePredecessor() == Split &&
                        ArmBranch && ArmBranch->isUnconditional() &&
                        ArmBranch->getSuccessor(0) == PN->getParent() &&
                        IsSwitchSuccessor;
        }
        for (unsigned S = 0; ExactFunnel && S != SI->getNumSuccessors(); ++S)
          ExactFunnel = PN->getBasicBlockIndex(SI->getSuccessor(S)) >= 0;
        if (ExactFunnel) {
          auto Condition = translate(SI->getCondition());
          int DefaultIndex = PN->getBasicBlockIndex(SI->getDefaultDest());
          auto Acc = DefaultIndex >= 0
                         ? translate(PN->getIncomingValue(DefaultIndex))
                         : std::optional<z3::expr>();
          if (Condition && Acc) {
            for (const auto &Case : SI->cases()) {
              int ArmIndex = PN->getBasicBlockIndex(Case.getCaseSuccessor());
              auto Key = translate(Case.getCaseValue());
              auto Arm = ArmIndex >= 0
                             ? translate(PN->getIncomingValue(ArmIndex))
                             : std::optional<z3::expr>();
              if (!Key || !Arm) {
                Acc.reset();
                break;
              }
              Acc = z3::ite(*Condition == *Key, *Arm, *Acc);
            }
          }
          if (Acc) {
            Result = *Acc;
            if (ResolvedSwitchPhis.insert(PN).second) {
              raw_string_ostream OS(SliceCertificate);
              OS << "switch-funnel-phi:" << valueText(*PN) << '\n'
                 << "switch-condition:" << valueText(*SI->getCondition())
                 << '\n';
              for (const auto &Case : SI->cases()) {
                int ArmIndex =
                    PN->getBasicBlockIndex(Case.getCaseSuccessor());
                OS << "switch-case:" << valueText(*Case.getCaseValue())
                   << "=>" << valueText(*PN->getIncomingValue(ArmIndex))
                   << '\n';
              }
              OS << "switch-default:"
                 << valueText(*PN->getIncomingValue(DefaultIndex)) << '\n';
            }
          }
        }
      }
      if (!Result && PN->getType()->isIntegerTy()) {
        ConstantInt *Seed = nullptr;
        BasicBlock *Header = PN->getParent();
        for (unsigned I = 0; I != PN->getNumIncomingValues(); ++I) {
          BasicBlock *Pred = PN->getIncomingBlock(I);
          auto *C = dyn_cast<ConstantInt>(PN->getIncomingValue(I));
          if (C && !isPotentiallyReachable(Header, Pred)) {
            Seed = C;
            break;
          }
        }
        bool Invariant = Seed != nullptr;
        for (unsigned I = 0; Invariant && I != PN->getNumIncomingValues();
             ++I) {
          BasicBlock *Pred = PN->getIncomingBlock(I);
          Value *Incoming = PN->getIncomingValue(I);
          if (!isPotentiallyReachable(Header, Pred)) {
            auto *C = dyn_cast<ConstantInt>(Incoming);
            Invariant = C && C->getValue() == Seed->getValue();
            continue;
          }
          auto Next = evalStateExpr(Incoming, PN, Seed->getValue(), 0);
          Invariant = Next && *Next == Seed->getValue();
        }
        if (Invariant) {
          SmallString<80> Text;
          Seed->getValue().toString(Text, 10, false);
          Result = Seed->getType()->isIntegerTy(1)
                       ? std::optional<z3::expr>(Ctx.bool_val(!Seed->isZero()))
                       : std::optional<z3::expr>(Ctx.bv_val(
                             Text.c_str(), Seed->getBitWidth()));
          if (ResolvedInductivePhis.insert(PN).second) {
            raw_string_ostream OS(SliceCertificate);
            OS << "inductive-constant-phi:" << valueText(*PN) << '\n'
               << "inductive-seed:" << valueText(*Seed) << '\n';
            for (unsigned I = 0; I != PN->getNumIncomingValues(); ++I)
              OS << "inductive-incoming:"
                 << valueText(*PN->getIncomingValue(I)) << '\n';
          }
        }
      }
      if (!Result) Result = makeLeaf(V);
    } else if (isa<Argument>(V)) {
      Result = makeLeaf(V);
    } else if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      Result = translateBinary(*BO);
    } else if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
      auto L = translate(Cmp->getOperand(0));
      auto R = translate(Cmp->getOperand(1));
      if (L && R) {
        switch (Cmp->getPredicate()) {
        case ICmpInst::ICMP_EQ: Result = *L == *R; break;
        case ICmpInst::ICMP_NE: Result = *L != *R; break;
        case ICmpInst::ICMP_UGT: Result = z3::ugt(*L, *R); break;
        case ICmpInst::ICMP_UGE: Result = z3::uge(*L, *R); break;
        case ICmpInst::ICMP_ULT: Result = z3::ult(*L, *R); break;
        case ICmpInst::ICMP_ULE: Result = z3::ule(*L, *R); break;
        case ICmpInst::ICMP_SGT: Result = *L > *R; break;
        case ICmpInst::ICMP_SGE: Result = *L >= *R; break;
        case ICmpInst::ICMP_SLT: Result = *L < *R; break;
        case ICmpInst::ICMP_SLE: Result = *L <= *R; break;
        default: break;
        }
      }
    } else if (auto *Sel = dyn_cast<SelectInst>(V)) {
      auto C = translate(Sel->getCondition());
      auto T = translate(Sel->getTrueValue());
      auto F = translate(Sel->getFalseValue());
      if (C && T && F && C->is_bool()) Result = z3::ite(*C, *T, *F);
    } else if (auto *Cast = dyn_cast<CastInst>(V)) {
      auto Op = translate(Cast->getOperand(0));
      if (Op && Cast->getType()->isIntegerTy() &&
          Cast->getSrcTy()->isIntegerTy()) {
        unsigned DstW = Cast->getType()->getIntegerBitWidth();
        unsigned SrcW = Cast->getSrcTy()->getIntegerBitWidth();
        if (Cast->getOpcode() == Instruction::ZExt) {
          if (Op->is_bool())
            Result = z3::ite(*Op, Ctx.bv_val(1, DstW), Ctx.bv_val(0, DstW));
          else
            Result = z3::zext(*Op, DstW - SrcW);
        } else if (Cast->getOpcode() == Instruction::SExt) {
          if (Op->is_bool())
            Result = z3::ite(*Op, Ctx.bv_val(-1, DstW), Ctx.bv_val(0, DstW));
          else
            Result = z3::sext(*Op, DstW - SrcW);
        } else if (Cast->getOpcode() == Instruction::Trunc) {
          auto *TI = cast<TruncInst>(Cast);
          if (!TI->hasNoUnsignedWrap()) {
            z3::expr Truncated = Op->extract(DstW - 1, 0);
            Result = DstW == 1
                         ? std::optional<z3::expr>(
                               Truncated == Ctx.bv_val(1, 1))
                         : std::optional<z3::expr>(Truncated);
          }
        } else if (Cast->getOpcode() == Instruction::BitCast && SrcW == DstW) {
          Result = *Op;
        }
      }
    } else if (isa<FreezeInst>(V)) {
      // freeze(poison) is an arbitrary but stable value, not the operand's
      // mathematical value.  Model the instruction itself as one symbol so
      // repeated uses agree without introducing a false relation to poison.
      Result = makeLeaf(V);
    }
    TranslationStack.erase(V);
    if (Result) Cache.emplace(V, *Result);
    return Result;
  }
};

struct SMTBooleanProof {
  bool Value = false;
  unsigned ConstraintCount = 0;
  std::string ConstraintCertificate;
  unsigned MemoryLoadsResolved = 0;
  unsigned PathStateITEsResolved = 0;
  unsigned SwitchPathStateITEsResolved = 0;
  unsigned InductivePhisResolved = 0;
};

using PathConstraint = std::pair<Value *, bool>;

static SmallVector<PathConstraint, 16>
collectDominatingConstraints(BranchInst &Target, DominatorTree &DT) {
  SmallVector<PathConstraint, 16> Constraints;
  BasicBlock *TargetBB = Target.getParent();
  for (DomTreeNode *Node = DT.getNode(TargetBB); Node && Constraints.size() < 32;
       Node = Node->getIDom()) {
    BasicBlock *BB = Node->getBlock();
    for (Instruction &I : *BB) {
      if (&I == &Target) break;
      auto *II = dyn_cast<IntrinsicInst>(&I);
      if (II && II->getIntrinsicID() == Intrinsic::assume)
        Constraints.push_back({II->getArgOperand(0), true});
      if (Constraints.size() == 32) break;
    }
    if (BB == TargetBB || Constraints.size() == 32) continue;
    auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
    if (!BI || !BI->isConditional()) continue;
    bool TrueDominates = DT.dominates(BI->getSuccessor(0), TargetBB);
    bool FalseDominates = DT.dominates(BI->getSuccessor(1), TargetBB);
    if (TrueDominates != FalseDominates)
      Constraints.push_back({BI->getCondition(), TrueDominates});
  }
  return Constraints;
}

static std::optional<SMTBooleanProof>
proveBooleanSMT(
    Value *Condition, ArrayRef<PathConstraint> Constraints = {},
    const DenseMap<const LoadInst *, Value *> *ReachingLoadValues = nullptr) {
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx, ReachingLoadValues);
    auto Expr = Translator.translate(Condition);
    if (!Expr || !Expr->is_bool()) return std::nullopt;
    z3::params Params(Ctx);
    Params.set("timeout", 250u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    std::string Certificate;
    raw_string_ostream CertificateOS(Certificate);
    unsigned Added = 0;
    for (const PathConstraint &Constraint : Constraints) {
      auto ConstraintExpr = Translator.translate(Constraint.first);
      if (!ConstraintExpr || !ConstraintExpr->is_bool()) return std::nullopt;
      Solver.add(Constraint.second ? *ConstraintExpr : !*ConstraintExpr);
      CertificateOS << (Constraint.second ? "true:" : "false:")
                    << valueText(*Constraint.first) << '\n';
      ++Added;
    }
    CertificateOS << Translator.getSliceCertificate();
    CertificateOS.flush();
    // Never discharge an obligation by explosion from inconsistent path
    // facts.  An unreachable block is left to CFG cleanup, not called an
    // opaque-predicate proof.
    if (Solver.check() != z3::sat) return std::nullopt;
    Solver.push();
    Solver.add(!*Expr);
    z3::check_result TrueResult = Solver.check();
    Solver.pop();
    if (TrueResult == z3::unsat)
      return SMTBooleanProof{true, Added, std::move(Certificate),
                             Translator.getResolvedLoadCount(),
                             Translator.getResolvedDiamondPhiCount(),
                             Translator.getResolvedSwitchPhiCount(),
                             Translator.getResolvedInductivePhiCount()};
    Solver.push();
    Solver.add(*Expr);
    z3::check_result FalseResult = Solver.check();
    Solver.pop();
    if (FalseResult == z3::unsat)
      return SMTBooleanProof{false, Added, std::move(Certificate),
                             Translator.getResolvedLoadCount(),
                             Translator.getResolvedDiamondPhiCount(),
                             Translator.getResolvedSwitchPhiCount(),
                             Translator.getResolvedInductivePhiCount()};
  } catch (const z3::exception &) {
    return std::nullopt;
  }
  return std::nullopt;
}

struct CyclicPredicateProof {
  bool Value = false;
  std::string Certificate;
};

static void collectConditionPHIs(Value *V,
                                 SmallPtrSetImpl<PHINode *> &Phis,
                                 SmallPtrSetImpl<Value *> &Seen,
                                 unsigned Depth = 0) {
  if (!V || Depth > 48 || !Seen.insert(V).second) return;
  if (auto *Phi = dyn_cast<PHINode>(V)) {
    Phis.insert(Phi);
    return;
  }
  if (auto *U = dyn_cast<User>(V))
    for (Value *Op : U->operands())
      collectConditionPHIs(Op, Phis, Seen, Depth + 1);
}

// Prove a loop predicate by one-step induction over one cyclic integer PHI.
// This is deliberately stronger than path-bounded unrolling: non-PHI inputs
// remain universally quantified Z3 symbols, every external seed must establish
// the same truth value, and every backedge recurrence must preserve it.
static std::optional<CyclicPredicateProof>
proveBooleanCyclicInduction(Value *Condition) {
  if (!Condition || !Condition->getType()->isIntegerTy(1)) return std::nullopt;
  SmallPtrSet<PHINode *, 4> Phis;
  SmallPtrSet<Value *, 32> Seen;
  collectConditionPHIs(Condition, Phis, Seen);
  PHINode *Phi = nullptr;
  for (PHINode *Candidate : Phis) {
    bool Cyclic = false;
    for (unsigned I = 0; I != Candidate->getNumIncomingValues(); ++I)
      Cyclic |= isPotentiallyReachable(Candidate->getParent(),
                                      Candidate->getIncomingBlock(I));
    if (!Cyclic) continue;
    if (Phi) return std::nullopt;
    Phi = Candidate;
  }
  if (!Phi || !Phi->getType()->isIntegerTy()) return std::nullopt;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto Predicate = Translator.translate(Condition);
    auto PhiExpr = Translator.translate(Phi);
    if (!Predicate || !Predicate->is_bool() || !PhiExpr || !PhiExpr->is_bv())
      return std::nullopt;
    z3::params Params(Ctx);
    Params.set("timeout", 1000u);
    auto SubstitutePhi = [&](const z3::expr &Replacement) {
      z3::expr_vector From(Ctx), To(Ctx);
      From.push_back(*PhiExpr);
      To.push_back(Replacement);
      return Predicate->substitute(From, To);
    };
    std::optional<bool> InvariantValue;
    std::string Certificate;
    raw_string_ostream OS(Certificate);
    OS << "cyclic-phi:" << valueText(*Phi) << '\n';
    for (unsigned I = 0; I != Phi->getNumIncomingValues(); ++I) {
      BasicBlock *Pred = Phi->getIncomingBlock(I);
      if (isPotentiallyReachable(Phi->getParent(), Pred)) continue;
      auto Seed = Translator.translate(Phi->getIncomingValue(I));
      if (!Seed || !Seed->is_bv() ||
          Seed->get_sort().bv_size() != PhiExpr->get_sort().bv_size())
        return std::nullopt;
      z3::expr SeedPredicate = SubstitutePhi(*Seed);
      z3::solver TrueSolver(Ctx), FalseSolver(Ctx);
      TrueSolver.set(Params);
      FalseSolver.set(Params);
      TrueSolver.add(!SeedPredicate);
      FalseSolver.add(SeedPredicate);
      std::optional<bool> SeedValue;
      if (TrueSolver.check() == z3::unsat) SeedValue = true;
      else if (FalseSolver.check() == z3::unsat) SeedValue = false;
      if (!SeedValue || (InvariantValue && *InvariantValue != *SeedValue))
        return std::nullopt;
      InvariantValue = SeedValue;
      OS << "seed:" << valueText(*Phi->getIncomingValue(I)) << '\n';
    }
    if (!InvariantValue) return std::nullopt;
    unsigned Backedges = 0;
    for (unsigned I = 0; I != Phi->getNumIncomingValues(); ++I) {
      BasicBlock *Pred = Phi->getIncomingBlock(I);
      if (!isPotentiallyReachable(Phi->getParent(), Pred)) continue;
      auto Next = Translator.translate(Phi->getIncomingValue(I));
      if (!Next || !Next->is_bv() ||
          Next->get_sort().bv_size() != PhiExpr->get_sort().bv_size())
        return std::nullopt;
      z3::expr NextPredicate = SubstitutePhi(*Next);
      z3::solver Step(Ctx);
      Step.set(Params);
      Step.add(*InvariantValue ? *Predicate : !*Predicate);
      Step.add(*InvariantValue ? !NextPredicate : NextPredicate);
      if (Step.check() != z3::unsat) return std::nullopt;
      ++Backedges;
      OS << "backedge:" << valueText(*Phi->getIncomingValue(I)) << '\n';
    }
    if (!Backedges) return std::nullopt;
    OS << "invariant:" << (*InvariantValue ? "true" : "false") << '\n';
    OS.flush();
    return CyclicPredicateProof{*InvariantValue, std::move(Certificate)};
  } catch (const z3::exception &) {
    return std::nullopt;
  }
}

static bool sameFrameAddress(Value *A, Value *B);

static Value *resolveMemorySSAValue(
    MemoryAccess *Access, LoadInst &LI, MemorySSA &MSSA,
    MemorySSAWalker &Walker, SmallPtrSetImpl<MemoryAccess *> &Seen,
    bool &UsedPhi, unsigned Depth = 0) {
  if (!Access || Depth > 16 || !Seen.insert(Access).second ||
      MSSA.isLiveOnEntryDef(Access))
    return nullptr;
  if (auto *Def = dyn_cast<MemoryDef>(Access)) {
    auto *SI = dyn_cast_or_null<StoreInst>(Def->getMemoryInst());
    if (!SI || SI->isVolatile() || SI->isAtomic() ||
        !sameFrameAddress(SI->getPointerOperand(), LI.getPointerOperand()) ||
        SI->getValueOperand()->getType() != LI.getType())
      return nullptr;
    return SI->getValueOperand();
  }
  auto *Phi = dyn_cast<MemoryPhi>(Access);
  if (!Phi || Phi->getNumIncomingValues() == 0) return nullptr;
  UsedPhi = true;
  Value *Common = nullptr;
  MemoryLocation Location = MemoryLocation::get(&LI);
  for (Use &IncomingUse : Phi->incoming_values()) {
    auto *Incoming = cast<MemoryAccess>(IncomingUse.get());
    MemoryAccess *Clobber =
        Walker.getClobberingMemoryAccess(Incoming, Location);
    SmallPtrSet<MemoryAccess *, 16> ArmSeen;
    ArmSeen.insert(Seen.begin(), Seen.end());
    Value *Arm = resolveMemorySSAValue(Clobber, LI, MSSA, Walker, ArmSeen,
                                       UsedPhi, Depth + 1);
    if (!Arm) return nullptr;
    if (!Common) Common = Arm;
    else if (Common != Arm) {
      auto *LC = dyn_cast<Constant>(Common);
      auto *RC = dyn_cast<Constant>(Arm);
      if (!LC || !RC || LC != RC) return nullptr;
    }
  }
  return Common;
}

static DenseMap<const LoadInst *, Value *>
buildMemorySSAReachingValues(Function &F, MemorySSA &MSSA, Metrics &M) {
  DenseMap<const LoadInst *, Value *> Reaching;
  MSSA.ensureOptimizedUses();
  MemorySSAWalker *Walker = MSSA.getWalker();
  for (Instruction &I : instructions(F)) {
    auto *LI = dyn_cast<LoadInst>(&I);
    if (!LI) continue;
    if (LI->isVolatile() || LI->isAtomic()) {
      ++M.MemorySSABarriers;
      continue;
    }
    MemoryAccess *Clobber = Walker->getClobberingMemoryAccess(LI);
    if (!Clobber || MSSA.isLiveOnEntryDef(Clobber)) continue;
    SmallPtrSet<MemoryAccess *, 16> Seen;
    bool UsedPhi = false;
    Value *ReachingValue = resolveMemorySSAValue(
        Clobber, *LI, MSSA, *Walker, Seen, UsedPhi);
    if (!ReachingValue) {
      ++M.MemorySSABarriers;
      continue;
    }
    Reaching.try_emplace(LI, ReachingValue);
    ++M.MemorySSAReachingLoads;
    if (UsedPhi) ++M.MemorySSAPhisResolved;
  }
  return Reaching;
}

static bool proveEquivalentSMT(Value *Old, Value *Replacement) {
  if (!Old || !Replacement || Old->getType() != Replacement->getType())
    return false;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto L = Translator.translate(Old);
    auto R = Translator.translate(Replacement);
    if (!L || !R || L->is_bool() != R->is_bool() || L->is_bv() != R->is_bv())
      return false;
    z3::params Params(Ctx);
    Params.set("timeout", 500u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(*L != *R);
    return Solver.check() == z3::unsat;
  } catch (const z3::exception &) {
    return false;
  }
}

static bool proveTupleEquivalentSMT(ArrayRef<Value *> OldRoots,
                                    Value *Replacement);

static bool collectPoisonSupport(Value *V,
                                 SmallPtrSetImpl<const Value *> &Support,
                                 unsigned Depth = 0) {
  if (!V || Depth > 64) return false;
  if (isa<Constant>(V) || isa<FreezeInst>(V)) return true;
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (hasPoisonGeneratingFlags(BO)) {
      Support.insert(V);
      return true;
    }
    if (BO->isShift()) {
      auto *Count = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (!Count || Count->getValue().uge(BO->getType()->getIntegerBitWidth())) {
        Support.insert(V);
        return true;
      }
    }
    return collectPoisonSupport(BO->getOperand(0), Support, Depth + 1) &&
           collectPoisonSupport(BO->getOperand(1), Support, Depth + 1);
  }
  if (auto *Cmp = dyn_cast<ICmpInst>(V))
    return collectPoisonSupport(Cmp->getOperand(0), Support, Depth + 1) &&
           collectPoisonSupport(Cmp->getOperand(1), Support, Depth + 1);
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    if (auto *TI = dyn_cast<TruncInst>(Cast); TI && TI->hasNoUnsignedWrap()) {
      Support.insert(V);
      return true;
    }
    return collectPoisonSupport(Cast->getOperand(0), Support, Depth + 1);
  }
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    if (II->getIntrinsicID() == Intrinsic::ctpop &&
        II->getType()->isIntegerTy())
      return collectPoisonSupport(II->getArgOperand(0), Support, Depth + 1);
    if ((II->getIntrinsicID() == Intrinsic::fshl ||
         II->getIntrinsicID() == Intrinsic::fshr) &&
        II->getArgOperand(0) == II->getArgOperand(1) &&
        isa<ConstantInt>(II->getArgOperand(2)))
      return collectPoisonSupport(II->getArgOperand(0), Support, Depth + 1);
  }
  // Select has path-dependent poison propagation and unsupported operations
  // may have their own poison rules.  Treat the complete value as one source
  // rather than inventing a relation that the BV solver cannot express.
  Support.insert(V);
  return true;
}

static bool hasSamePoisonSupport(Value *Old, Value *Replacement) {
  SmallPtrSet<const Value *, 16> OldSupport, NewSupport;
  if (!collectPoisonSupport(Old, OldSupport) ||
      !collectPoisonSupport(Replacement, NewSupport) ||
      OldSupport.size() != NewSupport.size())
    return false;
  for (const Value *V : OldSupport)
    if (!NewSupport.contains(V)) return false;
  return true;
}

static bool sanitizeLiftedFunction(Function &F, Metrics &M,
                                   SmallVectorImpl<ProofRecord> &Proofs) {
  if (!isLiftedFunction(F))
    return false;
  ++M.LiftedFunctions;
  bool Changed = false;
  for (Instruction &I : instructions(F)) {
    bool Local = false;
    if (auto *OBO = dyn_cast<OverflowingBinaryOperator>(&I)) {
      Local |= OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap();
      if (Local) {
        auto *BO = cast<BinaryOperator>(&I);
        BO->setHasNoSignedWrap(false);
        BO->setHasNoUnsignedWrap(false);
      }
    }
    if (auto *PEO = dyn_cast<PossiblyExactOperator>(&I); PEO && PEO->isExact()) {
      cast<BinaryOperator>(&I)->setIsExact(false);
      Local = true;
    }
    if (auto *GEP = dyn_cast<GetElementPtrInst>(&I); GEP && GEP->isInBounds()) {
      GEP->setNoWrapFlags(GEPNoWrapFlags::none());
      Local = true;
    }
    if (auto *TI = dyn_cast<TruncInst>(&I);
        TI && TI->hasNoUnsignedWrap()) {
      TI->setHasNoUnsignedWrap(false);
      Local = true;
    }
    if (!Local) continue;
    Changed = true;
    ++M.FlagsSanitized;
    Proofs.push_back({F.getName().str(), "lifted_semantics_sanitize",
                      valueName(I), "lifted_provenance", "proved"});
  }
  return Changed;
}

struct AffineBVExpr {
  APInt Constant;
  SmallVector<std::pair<Value *, APInt>, 8> Terms;
  unsigned Nodes = 0;
  bool Valid = false;

  explicit AffineBVExpr(unsigned Width)
      : Constant(Width, 0), Valid(true) {}
};

static void addAffineTerm(AffineBVExpr &Expr, Value *Leaf,
                          const APInt &Coefficient) {
  for (auto &Term : Expr.Terms)
    if (Term.first == Leaf) {
      Term.second += Coefficient;
      return;
    }
  Expr.Terms.push_back({Leaf, Coefficient});
}

static std::optional<AffineBVExpr> parseAffineBV(Value *V, unsigned Width,
                                                 unsigned &Budget,
                                                 unsigned Depth = 0) {
  if (Depth > 32 || Budget == 0 || !V->getType()->isIntegerTy(Width))
    return std::nullopt;
  if (auto *C = dyn_cast<ConstantInt>(V)) {
    AffineBVExpr Result(Width);
    Result.Constant = C->getValue();
    return Result;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || hasPoisonGeneratingFlags(BO) ||
      (BO->getOpcode() != Instruction::Add &&
       BO->getOpcode() != Instruction::Sub &&
       BO->getOpcode() != Instruction::Mul)) {
    AffineBVExpr Leaf(Width);
    addAffineTerm(Leaf, V, APInt(Width, 1));
    return Leaf;
  }
  --Budget;
  if (BO->getOpcode() == Instruction::Mul) {
    auto *LC = dyn_cast<ConstantInt>(BO->getOperand(0));
    auto *RC = dyn_cast<ConstantInt>(BO->getOperand(1));
    ConstantInt *Scale = RC ? RC : LC;
    Value *Variable = RC ? BO->getOperand(0) : BO->getOperand(1);
    if (!Scale) {
      AffineBVExpr Leaf(Width);
      addAffineTerm(Leaf, V, APInt(Width, 1));
      return Leaf;
    }
    auto Inner = parseAffineBV(Variable, Width, Budget, Depth + 1);
    if (!Inner) return std::nullopt;
    Inner->Constant *= Scale->getValue();
    for (auto &Term : Inner->Terms) Term.second *= Scale->getValue();
    ++Inner->Nodes;
    return Inner;
  }
  auto L = parseAffineBV(BO->getOperand(0), Width, Budget, Depth + 1);
  auto R = parseAffineBV(BO->getOperand(1), Width, Budget, Depth + 1);
  if (!L || !R) return std::nullopt;
  bool Subtract = BO->getOpcode() == Instruction::Sub;
  L->Constant = Subtract ? L->Constant - R->Constant
                         : L->Constant + R->Constant;
  for (auto &Term : R->Terms)
    addAffineTerm(*L, Term.first,
                  Subtract ? -Term.second : Term.second);
  L->Nodes += R->Nodes + 1;
  return L;
}

static unsigned affineExtractionCost(const AffineBVExpr &Expr) {
  unsigned Values = !Expr.Constant.isZero();
  unsigned Cost = 0;
  for (const auto &Term : Expr.Terms) {
    if (Term.second.isZero()) continue;
    ++Values;
    Cost += !Term.second.isOne();
  }
  if (Values > 1) Cost += Values - 1;
  return Cost;
}

static Value *buildAffineBV(const AffineBVExpr &Expr, Instruction *Before) {
  IRBuilder<> B(Before);
  Value *Result = nullptr;
  auto Append = [&](Value *Term) {
    Result = Result ? B.CreateAdd(Result, Term, "deobf.affine.sum") : Term;
  };
  for (const auto &Item : Expr.Terms) {
    if (Item.second.isZero()) continue;
    Value *Term = Item.first;
    if (!Item.second.isOne())
      Term = B.CreateMul(Term, ConstantInt::get(Term->getType(), Item.second),
                         "deobf.affine.scale");
    Append(Term);
  }
  if (!Expr.Constant.isZero())
    Append(ConstantInt::get(Before->getType(), Expr.Constant));
  return Result ? Result : ConstantInt::get(Before->getType(), 0);
}

static bool sameAffineBV(const AffineBVExpr &L, const AffineBVExpr &R) {
  if (L.Constant != R.Constant) return false;
  unsigned LCount = llvm::count_if(
      L.Terms, [](const auto &Term) { return !Term.second.isZero(); });
  unsigned RCount = llvm::count_if(
      R.Terms, [](const auto &Term) { return !Term.second.isZero(); });
  if (LCount != RCount) return false;
  for (const auto &LT : L.Terms) {
    if (LT.second.isZero()) continue;
    auto It = llvm::find_if(R.Terms, [&](const auto &RT) {
      return RT.first == LT.first && RT.second == LT.second;
    });
    if (It == R.Terms.end()) return false;
  }
  return true;
}

// Extract one dominating representative for multiple equivalent affine
// roots.  The proof query rejects a model if any old root differs from the
// shared replacement, so cross-root sharing is validated as a tuple rather
// than inferred from independent local rewrites.
static bool rewriteMultiRootAffineBVRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  struct Candidate {
    BinaryOperator *Root;
    AffineBVExpr Expr;
  };
  SmallVector<Candidate, 32> Candidates;
  for (Instruction &I : instructions(F)) {
    auto *Root = dyn_cast<BinaryOperator>(&I);
    if (!Root || !Root->getType()->isIntegerTy() ||
        Root->getType()->getIntegerBitWidth() > 256)
      continue;
    unsigned Budget = 40;
    auto Expr = parseAffineBV(Root, Root->getType()->getIntegerBitWidth(),
                              Budget);
    if (Expr && Expr->Nodes >= 1)
      Candidates.push_back({Root, std::move(*Expr)});
  }
  DominatorTree DT(F);
  auto DominatesInstruction = [&](Instruction *A, Instruction *B) {
    if (A == B) return true;
    if (A->getParent() == B->getParent()) return A->comesBefore(B);
    return DT.dominates(A, B);
  };
  SmallVector<bool, 32> Consumed(Candidates.size(), false);
  for (unsigned I = 0; I != Candidates.size(); ++I) {
    if (Consumed[I]) continue;
    SmallVector<unsigned, 8> Group{I};
    for (unsigned J = I + 1; J != Candidates.size(); ++J)
      if (!Consumed[J] && Candidates[I].Root->getType() ==
                              Candidates[J].Root->getType() &&
          sameAffineBV(Candidates[I].Expr, Candidates[J].Expr))
        Group.push_back(J);
    if (Group.size() < 2) continue;

    BinaryOperator *Anchor = nullptr;
    for (unsigned Index : Group) {
      BinaryOperator *Probe = Candidates[Index].Root;
      if (llvm::all_of(Group, [&](unsigned Other) {
            return DominatesInstruction(Probe, Candidates[Other].Root);
          })) {
        Anchor = Probe;
        break;
      }
    }
    if (!Anchor) continue;
    bool SelfLeaf = llvm::any_of(Candidates[I].Expr.Terms, [&](const auto &T) {
      return llvm::any_of(Group, [&](unsigned Index) {
        return T.first == Candidates[Index].Root;
      });
    });
    if (SelfLeaf) continue;
    unsigned OldCost = 0;
    for (unsigned Index : Group) OldCost += Candidates[Index].Expr.Nodes;
    if (affineExtractionCost(Candidates[I].Expr) >= OldCost) continue;

    Value *Replacement = buildAffineBV(Candidates[I].Expr, Anchor);
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    SmallVector<Value *, 8> OldRoots;
    bool SamePoison = true;
    std::string OldTupleText;
    raw_string_ostream OldOS(OldTupleText);
    for (unsigned Index : Group) {
      Value *Root = Candidates[Index].Root;
      OldRoots.push_back(Root);
      SamePoison &= hasSamePoisonSupport(Root, Replacement);
      OldOS << valueText(*Root) << '\n';
    }
    OldOS.flush();
    if (!SamePoison || !proveTupleEquivalentSMT(OldRoots, Replacement)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string NewText = valueText(*Replacement);
    std::string Origins;
    raw_string_ostream OriginOS(Origins);
    for (unsigned K = 0; K != Group.size(); ++K) {
      if (K) OriginOS << ',';
      OriginOS << valueName(*Candidates[Group[K]].Root);
    }
    OriginOS.flush();
    llvm::sort(Group, [&](unsigned A, unsigned B) {
      Instruction *RA = Candidates[A].Root;
      Instruction *RB = Candidates[B].Root;
      if (DominatesInstruction(RA, RB) && RA != RB) return false;
      if (DominatesInstruction(RB, RA) && RA != RB) return true;
      return A > B;
    });
    for (unsigned Index : Group) {
      BinaryOperator *Root = Candidates[Index].Root;
      Root->replaceAllUsesWith(Replacement);
      Consumed[Index] = true;
    }
    // Construct tracking handles only after every RAUW.  TrackingVH follows
    // RAUW, so creating it earlier would retarget the handle to Replacement
    // and leave the old roots alive indefinitely.
    SmallVector<WeakTrackingVH, 8> DeadRoots;
    for (unsigned Index : Group)
      DeadRoots.emplace_back(Candidates[Index].Root);
    for (WeakTrackingVH &Handle : DeadRoots)
      if (auto *Root = dyn_cast_or_null<Instruction>(Handle))
        RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origins,
                       "multi_root_affine_tuple_z3_unsat", "proved"};
    Record.OldHash = hashText(OldTupleText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldTupleText + "\n!=tuple\n" + NewText);
    Record.Dependencies.push_back("pure_integer_multi_root_dag");
    Record.Dependencies.push_back("shared_dominating_extraction");
    Record.Dependencies.push_back("identical_poison_support_per_root");
    Proofs.push_back(std::move(Record));
    // Recursive deletion may erase other candidate instructions.  Stop this
    // snapshot after one transaction; the production fixed point rebuilds a
    // fresh candidate graph before considering the next equivalence class.
    return true;
  }
  return false;
}

static bool feedsSyntheticNativePointerSelect(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 4) return false;
  for (User *U : V->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I) continue;
    if (auto *SI = dyn_cast<SelectInst>(I);
        SI && SI->hasName() &&
        SI->getName().starts_with("native.data.pointer.select"))
      return true;
    if ((isa<ICmpInst>(I) || isa<BinaryOperator>(I) || isa<CastInst>(I)) &&
        feedsSyntheticNativePointerSelect(I, Depth + 1))
      return true;
  }
  return false;
}

static bool rewriteAffineBVRegions(Function &F, Metrics &M,
                                   SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 64> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getType()->isIntegerTy() &&
        BO->getType()->getIntegerBitWidth() <= 256)
      Work.emplace_back(BO);
  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    // These affine bounds are emitted by native data-pointer recovery, not by
    // OLLVM.  Treating them as MBA candidates creates false mandatory
    // residuals when the speculative cheaper form is (correctly) rejected by
    // Z3.  The native cleanup owns this synthetic cone.
    if (feedsSyntheticNativePointerSelect(Root)) continue;
    unsigned Width = Root->getType()->getIntegerBitWidth();
    unsigned Budget = 40;
    auto Expr = parseAffineBV(Root, Width, Budget);
    if (!Expr || Expr->Nodes < 3 ||
        affineExtractionCost(*Expr) >= Expr->Nodes)
      continue;
    bool SelfLeaf = false;
    for (const auto &Term : Expr->Terms) SelfLeaf |= Term.first == Root;
    if (SelfLeaf) continue;
    Value *Replacement = buildAffineBV(*Expr, Root);
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    if (!hasSamePoisonSupport(Root, Replacement)) {
      ++M.PoisonSupportRejects;
      if (auto *RI = dyn_cast<Instruction>(Replacement); RI && RI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }
    if (!proveEquivalentSMT(Root, Replacement)) {
      if (auto *RI = dyn_cast<Instruction>(Replacement); RI && RI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(RI);
      ProofRecord Record{F.getName().str(), "bv_egraph_candidate",
                         valueName(*Root), "z3_bv_equivalence", "unresolved",
                         "affine_extraction_equivalence_not_unsat"};
      Record.OldHash = hashText(OldText);
      Record.NewHash = hashText(NewText);
      Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
      Proofs.push_back(std::move(Record));
      continue;
    }
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origin,
                       "affine_saturation_z3_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("pure_integer_dag");
    Record.Dependencies.push_back("llvm_poison_flags_absent");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

struct ACBitVectorExpr {
  unsigned Opcode = 0;
  APInt Constant;
  SmallVector<Value *, 16> Terms;
  unsigned Nodes = 0;

  ACBitVectorExpr(unsigned Opcode, unsigned Width)
      : Opcode(Opcode),
        Constant(Opcode == Instruction::And ? APInt::getAllOnes(Width)
                                             : APInt::getZero(Width)) {}
};

static bool flattenACBitVector(Value *V, ACBitVectorExpr &Expr,
                               unsigned &Budget, unsigned Depth = 0) {
  if (Depth > 32 || Budget == 0 ||
      !V->getType()->isIntegerTy(Expr.Constant.getBitWidth()))
    return false;
  if (auto *C = dyn_cast<ConstantInt>(V)) {
    if (Expr.Opcode == Instruction::And) Expr.Constant &= C->getValue();
    else if (Expr.Opcode == Instruction::Or) Expr.Constant |= C->getValue();
    else Expr.Constant ^= C->getValue();
    return true;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Expr.Opcode || hasPoisonGeneratingFlags(BO)) {
    Expr.Terms.push_back(V);
    return true;
  }
  --Budget;
  ++Expr.Nodes;
  return flattenACBitVector(BO->getOperand(0), Expr, Budget, Depth + 1) &&
         flattenACBitVector(BO->getOperand(1), Expr, Budget, Depth + 1);
}

static Value *buildACBitVector(ACBitVectorExpr &Expr, Instruction *Before,
                               unsigned &NewNodes) {
  SmallVector<Value *, 16> Unique;
  for (Value *Term : Expr.Terms) {
    auto It = llvm::find(Unique, Term);
    if (Expr.Opcode == Instruction::Xor) {
      if (It == Unique.end()) Unique.push_back(Term);
      else Unique.erase(It);
    } else if (It == Unique.end()) {
      Unique.push_back(Term);
    }
  }
  IRBuilder<> B(Before);
  Value *Result = nullptr;
  auto Append = [&](Value *Term) {
    if (!Result) Result = Term;
    else Result = B.CreateBinOp(static_cast<Instruction::BinaryOps>(Expr.Opcode),
                                Result, Term, "deobf.ac");
  };
  for (Value *Term : Unique) Append(Term);
  bool IsIdentity = Expr.Opcode == Instruction::And
                        ? Expr.Constant.isAllOnes()
                        : Expr.Constant.isZero();
  if (!IsIdentity || !Result)
    Append(ConstantInt::get(Before->getType(), Expr.Constant));
  unsigned ValueCount = Unique.size() + (!IsIdentity || Unique.empty());
  NewNodes = ValueCount ? ValueCount - 1 : 0;
  return Result;
}

static SmallVector<Value *, 16>
canonicalACTerms(const ACBitVectorExpr &Expr) {
  SmallVector<Value *, 16> Result;
  for (Value *Term : Expr.Terms) {
    auto It = llvm::find(Result, Term);
    if (Expr.Opcode == Instruction::Xor) {
      if (It == Result.end()) Result.push_back(Term);
      else Result.erase(It);
    } else if (It == Result.end()) {
      Result.push_back(Term);
    }
  }
  llvm::sort(Result, std::less<Value *>{});
  return Result;
}

// Multi-root extraction for AC e-classes.  Unlike the affine-only extractor,
// this handles xor/and/or equivalence classes (including cancellation and
// idempotence) and shares one dominating canonical representative.  All roots
// are committed as one tuple transaction.
static bool rewriteMultiRootACBitVectorRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  struct Candidate {
    BinaryOperator *Root = nullptr;
    ACBitVectorExpr Expr;
    SmallVector<Value *, 16> CanonicalTerms;

    Candidate(BinaryOperator *Root, ACBitVectorExpr Expr,
              SmallVector<Value *, 16> Terms)
        : Root(Root), Expr(std::move(Expr)),
          CanonicalTerms(std::move(Terms)) {}
  };
  SmallVector<Candidate, 32> Candidates;
  for (Instruction &I : instructions(F)) {
    auto *Root = dyn_cast<BinaryOperator>(&I);
    if (!Root || !Root->getType()->isIntegerTy() ||
        Root->getType()->getIntegerBitWidth() > 256 ||
        (Root->getOpcode() != Instruction::And &&
         Root->getOpcode() != Instruction::Or &&
         Root->getOpcode() != Instruction::Xor))
      continue;
    unsigned Budget = 40;
    ACBitVectorExpr Expr(Root->getOpcode(),
                         Root->getType()->getIntegerBitWidth());
    if (!flattenACBitVector(Root, Expr, Budget) || Expr.Nodes == 0) continue;
    SmallVector<Value *, 16> Terms = canonicalACTerms(Expr);
    Candidates.emplace_back(Root, std::move(Expr), std::move(Terms));
  }
  DominatorTree DT(F);
  auto DominatesInstruction = [&](Instruction *A, Instruction *B) {
    if (A == B) return true;
    if (A->getParent() == B->getParent()) return A->comesBefore(B);
    return DT.dominates(A, B);
  };
  for (unsigned I = 0; I != Candidates.size(); ++I) {
    SmallVector<unsigned, 8> Group{I};
    for (unsigned J = I + 1; J != Candidates.size(); ++J) {
      const Candidate &A = Candidates[I], &B = Candidates[J];
      if (A.Root->getType() == B.Root->getType() &&
          A.Expr.Opcode == B.Expr.Opcode &&
          A.Expr.Constant == B.Expr.Constant &&
          A.CanonicalTerms == B.CanonicalTerms)
        Group.push_back(J);
    }
    if (Group.size() < 2) continue;
    BinaryOperator *Anchor = nullptr;
    for (unsigned Index : Group) {
      BinaryOperator *Probe = Candidates[Index].Root;
      if (llvm::all_of(Group, [&](unsigned Other) {
            return DominatesInstruction(Probe, Candidates[Other].Root);
          })) {
        Anchor = Probe;
        break;
      }
    }
    if (!Anchor) continue;
    bool SelfLeaf = llvm::any_of(Candidates[I].CanonicalTerms, [&](Value *V) {
      return llvm::any_of(Group, [&](unsigned Index) {
        return V == Candidates[Index].Root;
      });
    });
    if (SelfLeaf) continue;
    unsigned OldNodes = 0;
    for (unsigned Index : Group) OldNodes += Candidates[Index].Expr.Nodes;
    unsigned NewNodes = 0;
    Value *Replacement =
        buildACBitVector(Candidates[I].Expr, Anchor, NewNodes);
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    if (NewNodes >= OldNodes) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    SmallVector<Value *, 8> OldRoots;
    std::string OldTupleText;
    raw_string_ostream OldOS(OldTupleText);
    bool SamePoison = true;
    for (unsigned Index : Group) {
      Value *Root = Candidates[Index].Root;
      OldRoots.push_back(Root);
      SamePoison &= hasSamePoisonSupport(Root, Replacement);
      OldOS << valueText(*Root) << '\n';
    }
    OldOS.flush();
    if (!SamePoison || !proveTupleEquivalentSMT(OldRoots, Replacement)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string NewText = valueText(*Replacement);
    std::string Origins;
    raw_string_ostream OriginOS(Origins);
    for (unsigned K = 0; K != Group.size(); ++K) {
      if (K) OriginOS << ',';
      OriginOS << valueName(*Candidates[Group[K]].Root);
    }
    OriginOS.flush();
    llvm::sort(Group, [&](unsigned A, unsigned B) {
      Instruction *RA = Candidates[A].Root;
      Instruction *RB = Candidates[B].Root;
      if (RA->getParent() == RB->getParent()) return RB->comesBefore(RA);
      bool ADominates = DT.dominates(RA, RB);
      bool BDominates = DT.dominates(RB, RA);
      if (ADominates != BDominates) return BDominates;
      return std::less<Instruction *>{}(RB, RA);
    });
    for (unsigned Index : Group) {
      BinaryOperator *Root = Candidates[Index].Root;
      Root->replaceAllUsesWith(Replacement);
    }
    SmallVector<WeakTrackingVH, 8> DeadRoots;
    for (unsigned Index : Group)
      DeadRoots.emplace_back(Candidates[Index].Root);
    for (WeakTrackingVH &Handle : DeadRoots)
      if (auto *Root = dyn_cast_or_null<Instruction>(Handle))
        RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origins,
                       "multi_root_ac_tuple_z3_unsat", "proved"};
    Record.OldHash = hashText(OldTupleText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash =
        hashText(OldTupleText + "\n!=tuple\n" + NewText);
    Record.Dependencies.push_back("pure_integer_multi_root_dag");
    Record.Dependencies.push_back("shared_dominating_ac_extraction");
    Record.Dependencies.push_back("identical_poison_support_per_root");
    Proofs.push_back(std::move(Record));
    return true;
  }
  return false;
}

static bool collectGeneralBVRegion(
    Value *V, SmallPtrSetImpl<Instruction *> &Nodes,
    SmallPtrSetImpl<Value *> &Leaves, unsigned Depth = 0) {
  if (!V || Depth > 40 || !V->getType()->isIntegerTy()) return false;
  if (isa<ConstantInt>(V)) return true;
  if (isa<Argument>(V) || isa<FreezeInst>(V)) {
    Leaves.insert(V);
    return true;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->mayReadOrWriteMemory() || !Nodes.insert(I).second)
    return I != nullptr && Nodes.contains(I);
  if (Nodes.size() > 40) return false;
  if (auto *BO = dyn_cast<BinaryOperator>(I)) {
    if (hasPoisonGeneratingFlags(BO)) return false;
    if (BO->isShift()) {
      auto *Count = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (!Count || Count->getValue().uge(BO->getType()->getIntegerBitWidth()))
        return false;
    }
  } else if (auto *Cast = dyn_cast<CastInst>(I)) {
    if (!Cast->getSrcTy()->isIntegerTy() ||
        (isa<TruncInst>(Cast) && cast<TruncInst>(Cast)->hasNoUnsignedWrap()))
      return false;
  } else if (auto *Cmp = dyn_cast<ICmpInst>(I)) {
    (void)Cmp;
  } else if (auto *II = dyn_cast<IntrinsicInst>(I)) {
    Intrinsic::ID ID = II->getIntrinsicID();
    if (ID != Intrinsic::ctpop && ID != Intrinsic::bswap &&
        ID != Intrinsic::bitreverse && ID != Intrinsic::fshl &&
        ID != Intrinsic::fshr)
      return false;
  } else {
    return false;
  }
  for (Value *Op : I->operands())
    if (!collectGeneralBVRegion(Op, Nodes, Leaves, Depth + 1)) return false;
  return true;
}

static unsigned generalBVRegionCost(ArrayRef<Instruction *> Nodes) {
  unsigned Cost = 0;
  for (Instruction *I : Nodes) {
    Cost += 1;
    if (isa<CastInst>(I)) Cost += 3;
    if (isa<IntrinsicInst>(I)) Cost += 8;
    if (auto *BO = dyn_cast<BinaryOperator>(I);
        BO && BO->getOpcode() == Instruction::Mul &&
        (isa<ConstantInt>(BO->getOperand(0)) ||
         isa<ConstantInt>(BO->getOperand(1))))
      Cost += 4;
    if (isa<ICmpInst>(I) && Cost >= 3) Cost -= 3;
  }
  return Cost;
}

// General mixed-operator e-class extraction.  Structural leaf equality is
// only a cheap candidate filter; semantic membership is established by Z3.
// An existing cheaper representative must dominate every root, so no cloning
// or speculative motion is required.  At least two non-representative roots
// are committed together under one tuple proof.
static bool rewriteMultiRootGeneralBVRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  struct Candidate {
    Instruction *Root = nullptr;
    SmallVector<Instruction *, 40> Nodes;
    SmallVector<Value *, 16> Leaves;
    unsigned Cost = 0;
  };
  SmallVector<Candidate, 32> Candidates;
  for (Instruction &I : instructions(F)) {
    if (!I.getType()->isIntegerTy() ||
        I.getType()->getIntegerBitWidth() > 256)
      continue;
    SmallPtrSet<Instruction *, 32> NodeSet;
    SmallPtrSet<Value *, 16> LeafSet;
    if (!collectGeneralBVRegion(&I, NodeSet, LeafSet) || NodeSet.size() < 2)
      continue;
    Candidate C;
    C.Root = &I;
    C.Nodes.append(NodeSet.begin(), NodeSet.end());
    C.Leaves.append(LeafSet.begin(), LeafSet.end());
    llvm::sort(C.Leaves, std::less<Value *>{});
    C.Cost = generalBVRegionCost(C.Nodes);
    Candidates.push_back(std::move(C));
    if (Candidates.size() == 32) break;
  }
  DominatorTree DT(F);
  auto Dominates = [&](Instruction *A, Instruction *B) {
    if (A == B) return true;
    if (A->getParent() == B->getParent()) return A->comesBefore(B);
    return DT.dominates(A, B);
  };
  unsigned ComparisonBudget = 96;
  for (unsigned R = 0; R != Candidates.size() && ComparisonBudget; ++R) {
    Candidate &Representative = Candidates[R];
    SmallVector<unsigned, 8> Equivalent;
    for (unsigned I = 0; I != Candidates.size() && ComparisonBudget; ++I) {
      if (I == R) continue;
      Candidate &Probe = Candidates[I];
      if (Probe.Root->getType() != Representative.Root->getType() ||
          Probe.Cost <= Representative.Cost ||
          Probe.Leaves != Representative.Leaves ||
          !Dominates(Representative.Root, Probe.Root) ||
          !hasSamePoisonSupport(Probe.Root, Representative.Root))
        continue;
      --ComparisonBudget;
      if (proveEquivalentSMT(Probe.Root, Representative.Root))
        Equivalent.push_back(I);
    }
    if (Equivalent.size() < 2) continue;
    SmallVector<Value *, 8> OldRoots{Representative.Root};
    std::string OldTupleText;
    raw_string_ostream OldOS(OldTupleText);
    OldOS << valueText(*Representative.Root) << '\n';
    for (unsigned Index : Equivalent) {
      OldRoots.push_back(Candidates[Index].Root);
      OldOS << valueText(*Candidates[Index].Root) << '\n';
    }
    OldOS.flush();
    if (!proveTupleEquivalentSMT(OldRoots, Representative.Root)) continue;

    std::string Origins = valueName(*Representative.Root);
    for (unsigned Index : Equivalent)
      Origins += "," + valueName(*Candidates[Index].Root);
    for (unsigned Index : Equivalent)
      Candidates[Index].Root->replaceAllUsesWith(Representative.Root);
    SmallVector<WeakTrackingVH, 8> DeadRoots;
    for (unsigned Index : Equivalent)
      DeadRoots.emplace_back(Candidates[Index].Root);
    for (WeakTrackingVH &Handle : DeadRoots)
      if (auto *Root = dyn_cast_or_null<Instruction>(Handle))
        RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origins,
                       "multi_root_mixed_bv_tuple_z3_unsat", "proved"};
    Record.OldHash = hashText(OldTupleText);
    Record.NewHash = hashText(valueText(*Representative.Root));
    Record.ProofQueryHash = hashText(
        OldTupleText + "\n!=tuple\n" + valueText(*Representative.Root));
    Record.Dependencies.push_back("bounded_pure_integer_mixed_operator_dag");
    Record.Dependencies.push_back("cheaper_existing_dominating_representative");
    Record.Dependencies.push_back("identical_poison_support_per_root");
    Proofs.push_back(std::move(Record));
    return true;
  }
  return false;
}

static bool rewriteACBitVectorRegions(Function &F, Metrics &M,
                                      SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 64> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && (BO->getOpcode() == Instruction::And ||
               BO->getOpcode() == Instruction::Or ||
               BO->getOpcode() == Instruction::Xor) &&
        BO->getType()->isIntegerTy() &&
        BO->getType()->getIntegerBitWidth() <= 256)
      Work.emplace_back(BO);
  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    unsigned Budget = 40;
    ACBitVectorExpr Expr(Root->getOpcode(),
                         Root->getType()->getIntegerBitWidth());
    if (!flattenACBitVector(Root, Expr, Budget) || Expr.Nodes == 0) continue;
    unsigned NewNodes = 0;
    Value *Replacement = buildACBitVector(Expr, Root, NewNodes);
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    if (Replacement == Root || NewNodes >= Expr.Nodes) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    if (!hasSamePoisonSupport(Root, Replacement)) {
      ++M.PoisonSupportRejects;
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    if (!proveEquivalentSMT(Root, Replacement)) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origin,
                       "ac_saturation_z3_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("pure_integer_dag");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

static bool matchBitwiseNot(Value *V, Value *&Operand) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Xor ||
      !BO->getType()->isIntegerTy() || hasPoisonGeneratingFlags(BO))
    return false;
  auto *L = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *R = dyn_cast<ConstantInt>(BO->getOperand(1));
  ConstantInt *Mask = R ? R : L;
  if (!Mask || !Mask->isMinusOne()) return false;
  Operand = R ? BO->getOperand(0) : BO->getOperand(1);
  return true;
}

static bool matchMaskedValue(Value *V, unsigned Opcode, Value *&Variable,
                             ConstantInt *&Mask) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Opcode || hasPoisonGeneratingFlags(BO))
    return false;
  auto *L = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *R = dyn_cast<ConstantInt>(BO->getOperand(1));
  Mask = R ? R : L;
  if (!Mask) return false;
  Variable = R ? BO->getOperand(0) : BO->getOperand(1);
  return true;
}

// Cost-reducing e-graph rules that require new IR construction.  The local
// structural guards are only candidate generation: poison support and a
// fixed-width Z3 equality proof remain mandatory before committing.
static bool rewriteDeMorganCastRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 32> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getType()->isIntegerTy() &&
        (BO->getOpcode() == Instruction::And ||
         BO->getOpcode() == Instruction::Or ||
         BO->getOpcode() == Instruction::Xor))
      Work.emplace_back(BO);

  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    Value *Replacement = nullptr;
    StringRef Rule;
    IRBuilder<> B(Root);

    if (Root->getOpcode() == Instruction::And ||
        Root->getOpcode() == Instruction::Or) {
      Value *L = nullptr, *R = nullptr;
      auto *LI = dyn_cast<Instruction>(Root->getOperand(0));
      auto *RI = dyn_cast<Instruction>(Root->getOperand(1));
      if (LI && RI && LI->hasOneUse() && RI->hasOneUse() &&
          matchBitwiseNot(LI, L) && matchBitwiseNot(RI, R)) {
        unsigned InnerOpcode = Root->getOpcode() == Instruction::And
                                   ? Instruction::Or
                                   : Instruction::And;
        Value *Inner = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(InnerOpcode), L, R,
            "deobf.demorgan.inner");
        Replacement = B.CreateNot(Inner, "deobf.demorgan");
        Rule = "demorgan_z3_unsat";
      }
    }

    if (!Replacement) {
      auto *LC = dyn_cast<CastInst>(Root->getOperand(0));
      auto *RC = dyn_cast<CastInst>(Root->getOperand(1));
      if (LC && RC && LC->hasOneUse() && RC->hasOneUse() &&
          LC->getOpcode() == RC->getOpcode() &&
          (LC->getOpcode() == Instruction::ZExt ||
           LC->getOpcode() == Instruction::SExt) &&
          LC->getSrcTy() == RC->getSrcTy() &&
          LC->getDestTy() == RC->getDestTy() &&
          LC->getSrcTy()->isIntegerTy()) {
        Value *Inner = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(Root->getOpcode()),
            LC->getOperand(0), RC->getOperand(0), "deobf.cast.inner");
        Replacement = LC->getOpcode() == Instruction::ZExt
                          ? B.CreateZExt(Inner, Root->getType(),
                                        "deobf.cast.factor")
                          : B.CreateSExt(Inner, Root->getType(),
                                        "deobf.cast.factor");
        Rule = "bitwise_cast_factor_z3_unsat";
      }
    }

    if (!Replacement) {
      unsigned InnerOpcode = 0, OuterOpcode = 0;
      if (Root->getOpcode() == Instruction::Or ||
          Root->getOpcode() == Instruction::Xor) {
        InnerOpcode = Root->getOpcode();
        OuterOpcode = Instruction::And;
      } else if (Root->getOpcode() == Instruction::And) {
        InnerOpcode = Instruction::And;
        OuterOpcode = Instruction::Or;
      }
      Value *L = nullptr, *R = nullptr;
      ConstantInt *LM = nullptr, *RM = nullptr;
      auto *LI = dyn_cast<Instruction>(Root->getOperand(0));
      auto *RI = dyn_cast<Instruction>(Root->getOperand(1));
      if (InnerOpcode && LI && RI && LI->hasOneUse() && RI->hasOneUse() &&
          matchMaskedValue(LI, OuterOpcode, L, LM) &&
          matchMaskedValue(RI, OuterOpcode, R, RM) &&
          LM->getValue() == RM->getValue()) {
        Value *Inner = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(InnerOpcode), L, R,
            "deobf.mask.inner");
        Replacement = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(OuterOpcode), Inner, LM,
            "deobf.mask.factor");
        Rule = "mask_factor_z3_unsat";
      }
    }

    if (!Replacement) continue;
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    if (!hasSamePoisonSupport(Root, Replacement) ||
        !proveEquivalentSMT(Root, Replacement)) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origin,
                       Rule.str(), "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("cost_reducing_pure_integer_dag");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

static bool matchSignBit(Value *V, Value *&Source) {
  Source = nullptr;
  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    if (Cmp->getPredicate() == ICmpInst::ICMP_SLT &&
        isa<ConstantInt>(Cmp->getOperand(1)) &&
        cast<ConstantInt>(Cmp->getOperand(1))->isZero()) {
      Source = Cmp->getOperand(0);
      return true;
    }
  }
  auto *Trunc = dyn_cast<TruncInst>(V);
  if (!Trunc || !Trunc->getType()->isIntegerTy(1) ||
      Trunc->hasNoUnsignedWrap())
    return false;
  auto *Shift = dyn_cast<BinaryOperator>(Trunc->getOperand(0));
  if (!Shift || Shift->getOpcode() != Instruction::LShr ||
      hasPoisonGeneratingFlags(Shift))
    return false;
  auto *Amount = dyn_cast<ConstantInt>(Shift->getOperand(1));
  Value *Input = Shift->getOperand(0);
  if (!Amount || !Input->getType()->isIntegerTy() ||
      !Amount->equalsInt(Input->getType()->getIntegerBitWidth() - 1))
    return false;
  Source = Input;
  return true;
}

static bool matchLogicalShiftXorStage(Value *V, unsigned Amount,
                                      Value *&Input) {
  Value *A = nullptr, *B = nullptr;
  if (!matchBin(V, Instruction::Xor, A, B)) return false;
  auto Try = [&](Value *Plain, Value *Shifted) {
    auto *Shift = dyn_cast<BinaryOperator>(Shifted);
    auto *Count = Shift ? dyn_cast<ConstantInt>(Shift->getOperand(1)) : nullptr;
    if (!Shift || Shift->getOpcode() != Instruction::LShr ||
        hasPoisonGeneratingFlags(Shift) || Shift->getOperand(0) != Plain ||
        !Count || !Count->equalsInt(Amount))
      return false;
    Input = Plain;
    return true;
  };
  return Try(A, B) || Try(B, A);
}

static bool matchLowByteEvenParity(Value *V, Value *&Byte) {
  Value *Bit = nullptr, *One = nullptr;
  if (!matchBin(V, Instruction::Xor, Bit, One)) return false;
  auto *True = dyn_cast<ConstantInt>(One);
  if (!True || !True->getType()->isIntegerTy(1) || !True->isOne()) {
    std::swap(Bit, One);
    True = dyn_cast<ConstantInt>(One);
  }
  auto *Trunc = dyn_cast<TruncInst>(Bit);
  if (!True || !True->isOne() || !Trunc ||
      !Trunc->getType()->isIntegerTy(1) || Trunc->hasNoUnsignedWrap())
    return false;
  Value *S2 = nullptr, *S4 = nullptr;
  if (!matchLogicalShiftXorStage(Trunc->getOperand(0), 1, S2) ||
      !matchLogicalShiftXorStage(S2, 2, S4) ||
      !matchLogicalShiftXorStage(S4, 4, Byte) ||
      !Byte->getType()->isIntegerTy(8))
    return false;
  return true;
}

static bool matchAddCarryCone(Value *Cone, BinaryOperator *&Add) {
  Value *T0 = nullptr, *T1 = nullptr;
  if (!matchBin(Cone, Instruction::Or, T0, T1)) return false;
  auto Try = [&](Value *ABTerm, Value *PropagateTerm) {
    Value *A = nullptr, *B = nullptr, *P = nullptr, *Q = nullptr;
    if (!matchBin(ABTerm, Instruction::And, A, B) ||
        !matchBin(PropagateTerm, Instruction::And, P, Q))
      return false;
    Value *NotSum = P, *AOrB = Q, *Sum = nullptr;
    if (!matchBitwiseNot(NotSum, Sum)) {
      std::swap(NotSum, AOrB);
      if (!matchBitwiseNot(NotSum, Sum)) return false;
    }
    auto *Candidate = dyn_cast<BinaryOperator>(Sum);
    Value *OA = nullptr, *OB = nullptr;
    if (!Candidate || Candidate->getOpcode() != Instruction::Add ||
        hasPoisonGeneratingFlags(Candidate) ||
        !matchBin(AOrB, Instruction::Or, OA, OB) ||
        !samePair(A, B, Candidate->getOperand(0), Candidate->getOperand(1)) ||
        !samePair(OA, OB, Candidate->getOperand(0), Candidate->getOperand(1)))
      return false;
    Add = Candidate;
    return true;
  };
  return Try(T0, T1) || Try(T1, T0);
}

static bool matchAddCarryBit(Value *V, BinaryOperator *&Add) {
  Value *Cone = nullptr;
  return matchSignBit(V, Cone) && matchAddCarryCone(Cone, Add);
}

static bool matchSubBorrowCone(Value *Cone, BinaryOperator *&Sub) {
  Value *T0 = nullptr, *T1 = nullptr;
  if (!matchBin(Cone, Instruction::Or, T0, T1)) return false;
  auto Try = [&](Value *GenerateTerm, Value *PropagateTerm) {
    Value *G0 = nullptr, *G1 = nullptr, *P0 = nullptr, *P1 = nullptr;
    if (!matchBin(GenerateTerm, Instruction::And, G0, G1) ||
        !matchBin(PropagateTerm, Instruction::And, P0, P1))
      return false;
    Value *A = nullptr, *B = G1;
    if (!matchBitwiseNot(G0, A)) {
      B = G0;
      if (!matchBitwiseNot(G1, A)) return false;
    }
    Value *NotXor = P0, *Diff = P1, *Xor = nullptr;
    if (!matchBitwiseNot(NotXor, Xor)) {
      std::swap(NotXor, Diff);
      if (!matchBitwiseNot(NotXor, Xor)) return false;
    }
    auto *Candidate = dyn_cast<BinaryOperator>(Diff);
    Value *XA = nullptr, *XB = nullptr;
    if (!Candidate || Candidate->getOpcode() != Instruction::Sub ||
        hasPoisonGeneratingFlags(Candidate) ||
        Candidate->getOperand(0) != A || Candidate->getOperand(1) != B ||
        !matchBin(Xor, Instruction::Xor, XA, XB) ||
        !samePair(XA, XB, A, B))
      return false;
    Sub = Candidate;
    return true;
  };
  return Try(T0, T1) || Try(T1, T0);
}

static bool matchSubBorrowBit(Value *V, BinaryOperator *&Sub) {
  Value *Cone = nullptr;
  return matchSignBit(V, Cone) && matchSubBorrowCone(Cone, Sub);
}

static bool matchSubOverflowBit(Value *V, BinaryOperator *Sub) {
  Value *Cone = nullptr;
  if (!matchSignBit(V, Cone)) return false;
  Value *X0 = nullptr, *X1 = nullptr, *Y0 = nullptr, *Y1 = nullptr;
  if (!matchBin(Cone, Instruction::And, X0, X1)) return false;
  auto Matches = [&](Value *First, Value *Second) {
    if (!matchBin(First, Instruction::Xor, Y0, Y1) ||
        !samePair(Y0, Y1, Sub->getOperand(0), Sub->getOperand(1)))
      return false;
    Value *P = nullptr, *Q = nullptr;
    return matchBin(Second, Instruction::Xor, P, Q) &&
           samePair(P, Q, Sub->getOperand(0), Sub);
  };
  return Matches(X0, X1) || Matches(X1, X0);
}

static bool sameICmpOperands(ICmpInst *A, ICmpInst *B) {
  return A->getOperand(0) == B->getOperand(0) &&
         A->getOperand(1) == B->getOperand(1);
}

static bool matchBooleanNot(Value *V, Value *&Inner) {
  Value *L = nullptr, *R = nullptr;
  if (!matchBin(V, Instruction::Xor, L, R) ||
      !V->getType()->isIntegerTy(1))
    return false;
  if (auto *C = dyn_cast<ConstantInt>(R); C && C->isOne()) {
    Inner = L;
    return true;
  }
  if (auto *C = dyn_cast<ConstantInt>(L); C && C->isOne()) {
    Inner = R;
    return true;
  }
  return false;
}

static bool proveTupleEquivalentSMT(ArrayRef<Value *> OldRoots,
                                    Value *Replacement) {
  if (OldRoots.empty() || !Replacement) return false;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto NewExpr = Translator.translate(Replacement);
    if (!NewExpr) return false;
    z3::expr AnyDifference = Ctx.bool_val(false);
    for (Value *Old : OldRoots) {
      if (!Old || Old->getType() != Replacement->getType()) return false;
      auto OldExpr = Translator.translate(Old);
      if (!OldExpr || OldExpr->is_bool() != NewExpr->is_bool() ||
          OldExpr->is_bv() != NewExpr->is_bv())
        return false;
      AnyDifference = AnyDifference || (*OldExpr != *NewExpr);
    }
    z3::params Params(Ctx);
    Params.set("timeout", 1000u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(AnyDifference);
    return Solver.check() == z3::unsat;
  } catch (const z3::exception &) {
    return false;
  }
}

static bool provePairwiseTupleEquivalentSMT(ArrayRef<Value *> OldRoots,
                                            ArrayRef<Value *> NewRoots) {
  if (OldRoots.empty() || OldRoots.size() != NewRoots.size()) return false;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    z3::expr AnyDifference = Ctx.bool_val(false);
    for (unsigned I = 0; I != OldRoots.size(); ++I) {
      if (!OldRoots[I] || !NewRoots[I] ||
          OldRoots[I]->getType() != NewRoots[I]->getType())
        return false;
      auto OldExpr = Translator.translate(OldRoots[I]);
      auto NewExpr = Translator.translate(NewRoots[I]);
      if (!OldExpr || !NewExpr ||
          OldExpr->is_bool() != NewExpr->is_bool() ||
          OldExpr->is_bv() != NewExpr->is_bv())
        return false;
      AnyDifference = AnyDifference || (*OldExpr != *NewExpr);
    }
    z3::params Params(Ctx);
    Params.set("timeout", 1500u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(AnyDifference);
    return Solver.check() == z3::unsat;
  } catch (const z3::exception &) {
    return false;
  }
}

static bool matchSubZeroFlag(Value *V, BinaryOperator *&Sub,
                             bool &IsZero) {
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
               Cmp->getPredicate() != ICmpInst::ICMP_NE))
    return false;
  Value *Expr = Cmp->getOperand(0);
  auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
  if (!Zero || !Zero->isZero()) {
    Expr = Cmp->getOperand(1);
    Zero = dyn_cast<ConstantInt>(Cmp->getOperand(0));
  }
  auto *Candidate = dyn_cast<BinaryOperator>(Expr);
  if (!Zero || !Zero->isZero() || !Candidate ||
      Candidate->getOpcode() != Instruction::Sub ||
      hasPoisonGeneratingFlags(Candidate))
    return false;
  Sub = Candidate;
  IsZero = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
  return true;
}

static bool matchSubSignedLessFlag(Value *V, BinaryOperator *&Sub) {
  Value *SFSource = nullptr;
  Value *SF = nullptr, *OF = nullptr;
  if (!matchBin(V, Instruction::Xor, SF, OF) ||
      !V->getType()->isIntegerTy(1))
    return false;
  if (!matchSignBit(SF, SFSource)) {
    std::swap(SF, OF);
    SFSource = nullptr;
    if (!matchSignBit(SF, SFSource))
      return false;
  }
  auto *Candidate = dyn_cast_or_null<BinaryOperator>(SFSource);
  if (!Candidate || Candidate->getOpcode() != Instruction::Sub ||
      hasPoisonGeneratingFlags(Candidate) ||
      !matchSubOverflowBit(OF, Candidate))
    return false;
  Sub = Candidate;
  return true;
}

static bool matchSubBorrowFlagFor(Value *V, BinaryOperator *Sub) {
  BinaryOperator *Candidate = nullptr;
  if (matchSubBorrowBit(V, Candidate))
    return Candidate == Sub;
  auto *Cmp = dyn_cast<ICmpInst>(V);
  return Cmp && Cmp->getPredicate() == ICmpInst::ICMP_ULT &&
         Cmp->getOperand(0) == Sub->getOperand(0) &&
         Cmp->getOperand(1) == Sub->getOperand(1);
}

static bool matchSubZeroFlagFor(Value *V, BinaryOperator *Sub) {
  BinaryOperator *Candidate = nullptr;
  bool IsZero = false;
  return matchSubZeroFlag(V, Candidate, IsZero) && IsZero && Candidate == Sub;
}

static bool matchSubSignedLessFlagFor(Value *V, BinaryOperator *Sub) {
  BinaryOperator *Candidate = nullptr;
  if (matchSubSignedLessFlag(V, Candidate))
    return Candidate == Sub;
  auto *Cmp = dyn_cast<ICmpInst>(V);
  return Cmp && Cmp->getPredicate() == ICmpInst::ICMP_SLT &&
         Cmp->getOperand(0) == Sub->getOperand(0) &&
         Cmp->getOperand(1) == Sub->getOperand(1);
}

static bool matchSubCombinedFlag(Value *V, bool Signed,
                                 BinaryOperator *&Sub) {
  Value *L = nullptr, *R = nullptr;
  if (!matchBin(V, Instruction::Or, L, R) ||
      !V->getType()->isIntegerTy(1))
    return false;
  BinaryOperator *Candidate = nullptr;
  bool IsZero = false;
  auto Try = [&](Value *Primary, Value *ZeroFlag) {
    if (!matchSubZeroFlag(ZeroFlag, Candidate, IsZero) || !IsZero)
      return false;
    bool MatchesPrimary = Signed
                              ? matchSubSignedLessFlagFor(Primary, Candidate)
                              : matchSubBorrowFlagFor(Primary, Candidate);
    if (!MatchesPrimary)
      return false;
    Sub = Candidate;
    return true;
  };
  return Try(L, R) || Try(R, L);
}

static bool matchUnsignedLessOperands(Value *V, Value *&A, Value *&B) {
  BinaryOperator *Sub = nullptr;
  if (matchSubBorrowBit(V, Sub)) {
    A = Sub->getOperand(0);
    B = Sub->getOperand(1);
    return true;
  }
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_ULT)
    return false;
  A = Cmp->getOperand(0);
  B = Cmp->getOperand(1);
  return true;
}

static bool matchSignedLessOperands(Value *V, Value *&A, Value *&B) {
  BinaryOperator *Sub = nullptr;
  if (matchSubSignedLessFlag(V, Sub)) {
    A = Sub->getOperand(0);
    B = Sub->getOperand(1);
    return true;
  }
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_SLT)
    return false;
  A = Cmp->getOperand(0);
  B = Cmp->getOperand(1);
  return true;
}

static bool matchCombinedConditionOperands(Value *V, bool Signed,
                                           Value *&A, Value *&B) {
  BinaryOperator *Sub = nullptr;
  if (matchSubCombinedFlag(V, Signed, Sub)) {
    A = Sub->getOperand(0);
    B = Sub->getOperand(1);
    return true;
  }
  Value *L = nullptr, *R = nullptr;
  if (!matchBin(V, Instruction::Or, L, R) ||
      !V->getType()->isIntegerTy(1))
    return false;
  auto *LCmp = dyn_cast<ICmpInst>(L);
  auto *RCmp = dyn_cast<ICmpInst>(R);
  if (!LCmp || !RCmp || !sameICmpOperands(LCmp, RCmp))
    return false;
  ICmpInst *Primary = LCmp, *Zero = RCmp;
  if (Primary->getPredicate() == ICmpInst::ICMP_EQ)
    std::swap(Primary, Zero);
  ICmpInst::Predicate Expected =
      Signed ? ICmpInst::ICMP_SLT : ICmpInst::ICMP_ULT;
  if (Primary->getPredicate() != Expected ||
      Zero->getPredicate() != ICmpInst::ICMP_EQ)
    return false;
  A = Primary->getOperand(0);
  B = Primary->getOperand(1);
  return true;
}

// Do not rewrite an intermediate flag bit before a compound condition-code
// cone (CF|ZF, SF^OF, or their inversions) has been recognized.  Replacing an
// inner bit first is individually sound, but destroys producer-wide evidence
// needed to prove and collapse the complete terminal predicate.
static bool feedsFlagBooleanCombiner(const Instruction &I) {
  for (const User *U : I.users()) {
    auto *BO = dyn_cast<BinaryOperator>(U);
    if (BO && BO->getType()->isIntegerTy(1) &&
        (BO->getOpcode() == Instruction::Or ||
         BO->getOpcode() == Instruction::Xor))
      return true;
  }
  return false;
}

enum class SubFlagKind { ZF, NZ, SF, OF, CF, AE, BE, A, L, GE, LE, G, PF };

struct SubFlagCandidate {
  Instruction *Root = nullptr;
  SubFlagKind Kind = SubFlagKind::ZF;
};

static bool collectCoveredFlagCone(
    Value *V, BinaryOperator *Producer,
    SmallPtrSetImpl<Instruction *> &Nodes, unsigned Depth = 0) {
  if (!V || Depth > 64 || V == Producer ||
      V == Producer->getOperand(0) || V == Producer->getOperand(1) ||
      isa<Constant>(V) || isa<Argument>(V))
    return V != nullptr;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getFunction() != Producer->getFunction() ||
      !I->getType()->isIntegerTy() || I->mayReadOrWriteMemory())
    return false;
  if (auto *CB = dyn_cast<CallBase>(I); CB && !isa<IntrinsicInst>(CB))
    return false;
  if (!Nodes.insert(I).second) return true;
  for (Value *Op : I->operands())
    if (!collectCoveredFlagCone(Op, Producer, Nodes, Depth + 1))
      return false;
  return true;
}

static bool isLowByteOfProducer(Value *Byte, BinaryOperator *Producer) {
  if (Producer->getType()->isIntegerTy(8)) return Byte == Producer;
  auto *Trunc = dyn_cast<TruncInst>(Byte);
  return Trunc && Trunc->getType()->isIntegerTy(8) &&
         Trunc->getOperand(0) == Producer && !Trunc->hasNoUnsignedWrap();
}

static Value *buildLowByteParityPredicate(IRBuilder<> &B,
                                          BinaryOperator *Producer,
                                          StringRef Prefix) {
  Type *I8 = Type::getInt8Ty(Producer->getContext());
  Value *Byte = Producer->getType()->isIntegerTy(8)
                    ? static_cast<Value *>(Producer)
                    : B.CreateTrunc(Producer, I8, Prefix + ".byte");
  Function *Ctpop = Intrinsic::getOrInsertDeclaration(
      Producer->getModule(), Intrinsic::ctpop, {I8});
  Value *Count = B.CreateCall(Ctpop, {Byte}, Prefix + ".count");
  Value *LowBit =
      B.CreateAnd(Count, ConstantInt::get(I8, 1), Prefix + ".bit");
  return B.CreateICmpEQ(LowBit, ConstantInt::get(I8, 0), Prefix);
}

static Value *buildSubFlagPredicate(const SubFlagCandidate &Candidate,
                                    BinaryOperator *Sub) {
  IRBuilder<> B(Candidate.Root);
  Value *A = Sub->getOperand(0), *RHS = Sub->getOperand(1);
  switch (Candidate.Kind) {
  case SubFlagKind::ZF: return B.CreateICmpEQ(A, RHS, "deobf.bundle.zf");
  case SubFlagKind::NZ: return B.CreateICmpNE(A, RHS, "deobf.bundle.nz");
  case SubFlagKind::SF:
    return B.CreateICmpSLT(Sub, ConstantInt::get(Sub->getType(), 0),
                           "deobf.bundle.sf");
  case SubFlagKind::CF: return B.CreateICmpULT(A, RHS, "deobf.bundle.cf");
  case SubFlagKind::AE: return B.CreateICmpUGE(A, RHS, "deobf.bundle.ae");
  case SubFlagKind::BE: return B.CreateICmpULE(A, RHS, "deobf.bundle.be");
  case SubFlagKind::A: return B.CreateICmpUGT(A, RHS, "deobf.bundle.a");
  case SubFlagKind::L: return B.CreateICmpSLT(A, RHS, "deobf.bundle.l");
  case SubFlagKind::GE: return B.CreateICmpSGE(A, RHS, "deobf.bundle.ge");
  case SubFlagKind::LE: return B.CreateICmpSLE(A, RHS, "deobf.bundle.le");
  case SubFlagKind::G: return B.CreateICmpSGT(A, RHS, "deobf.bundle.g");
  case SubFlagKind::OF: {
    Value *Zero = ConstantInt::get(Sub->getType(), 0);
    Value *RHSNegative = B.CreateICmpSLT(RHS, Zero, "deobf.bundle.of.bn");
    Value *DiffBelowA = B.CreateICmpSLT(Sub, A, "deobf.bundle.of.da");
    Value *NegativeOverflow =
        B.CreateAnd(RHSNegative, DiffBelowA, "deobf.bundle.of.neg");
    Value *RHSPositive = B.CreateICmpSGT(RHS, Zero, "deobf.bundle.of.bp");
    Value *DiffAboveA = B.CreateICmpSGT(Sub, A, "deobf.bundle.of.db");
    Value *PositiveOverflow =
        B.CreateAnd(RHSPositive, DiffAboveA, "deobf.bundle.of.pos");
    return B.CreateOr(NegativeOverflow, PositiveOverflow,
                      "deobf.bundle.of");
  }
  case SubFlagKind::PF: {
    return buildLowByteParityPredicate(B, Sub, "deobf.bundle.pf");
  }
  }
  llvm_unreachable("unknown subtraction flag kind");
}

static bool rewriteOneSubFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<BinaryOperator *, 16> Producers;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::Sub &&
        BO->getType()->isIntegerTy() && !hasPoisonGeneratingFlags(BO))
      Producers.push_back(BO);

  for (BinaryOperator *Sub : Producers) {
    SmallVector<SubFlagCandidate, 16> Candidates;
    auto Add = [&](Instruction *Root, SubFlagKind Kind) {
      if (!llvm::any_of(Candidates,
                        [&](const SubFlagCandidate &C) { return C.Root == Root; }))
        Candidates.push_back({Root, Kind});
    };
    for (Instruction &I : instructions(F)) {
      if (!I.getType()->isIntegerTy(1)) continue;
      BinaryOperator *Matched = nullptr;
      bool IsZero = false;
      Value *Negated = nullptr;
      Value *ParityByte = nullptr;
      if (matchSubZeroFlag(&I, Matched, IsZero) && Matched == Sub)
        Add(&I, IsZero ? SubFlagKind::ZF : SubFlagKind::NZ);
      else if (matchSubCombinedFlag(&I, false, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::BE);
      else if (matchSubCombinedFlag(&I, true, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::LE);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubCombinedFlag(Negated, false, Matched) &&
               Matched == Sub)
        Add(&I, SubFlagKind::A);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubCombinedFlag(Negated, true, Matched) &&
               Matched == Sub)
        Add(&I, SubFlagKind::G);
      else if (matchSubBorrowBit(&I, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::CF);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubBorrowBit(Negated, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::AE);
      else if (matchSubSignedLessFlag(&I, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::L);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubSignedLessFlag(Negated, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::GE);
      else {
        Value *SFSource = nullptr;
        if (matchSignBit(&I, SFSource) && SFSource == Sub)
          Add(&I, SubFlagKind::SF);
        else if (matchSubOverflowBit(&I, Sub))
          Add(&I, SubFlagKind::OF);
        else if (matchLowByteEvenParity(&I, ParityByte) &&
                 isLowByteOfProducer(ParityByte, Sub))
          Add(&I, SubFlagKind::PF);
      }
    }
    if (Candidates.size() < 2 ||
        llvm::all_of(Candidates, [](const SubFlagCandidate &C) {
          return isa<ICmpInst>(C.Root);
        }))
      continue;

    SmallPtrSet<Instruction *, 32> ConeNodes;
    SmallPtrSet<Instruction *, 16> Roots;
    bool Covered = true;
    for (const SubFlagCandidate &C : Candidates) {
      Roots.insert(C.Root);
      Covered &= collectCoveredFlagCone(C.Root, Sub, ConeNodes);
    }
    for (Instruction *Node : ConeNodes) {
      if (Roots.contains(Node)) continue;
      for (User *U : Node->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || !ConeNodes.contains(UI)) {
          Covered = false;
          break;
        }
      }
      if (!Covered) break;
    }
    if (!Covered) continue;

    SmallVector<Value *, 16> OldRoots, NewRoots;
    SmallVector<std::string, 16> OldTexts, NewTexts;
    SmallVector<std::string, 16> Origins;
    bool SamePoison = true;
    for (const SubFlagCandidate &C : Candidates) {
      Value *Replacement = buildSubFlagPredicate(C, Sub);
      OldRoots.push_back(C.Root);
      NewRoots.push_back(Replacement);
      OldTexts.push_back(valueText(*C.Root));
      NewTexts.push_back(valueText(*Replacement));
      Origins.push_back(valueName(*C.Root));
      SamePoison &= hasSamePoisonSupport(C.Root, Replacement);
    }
    if (!SamePoison ||
        !provePairwiseTupleEquivalentSMT(OldRoots, NewRoots)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      for (Value *Replacement : NewRoots)
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI && RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }

    std::string TupleCertificate;
    raw_string_ostream TupleOS(TupleCertificate);
    for (unsigned I = 0; I != Candidates.size(); ++I)
      TupleOS << OldTexts[I] << "\n==\n" << NewTexts[I] << '\n';
    TupleOS.flush();
    // Inner flags dominate the compound condition roots in canonical lifted
    // cones.  Replacing in dominance order keeps every outer root alive until
    // its pre-built replacement is installed.
    DominatorTree DT(F);
    llvm::sort(Candidates, [&](const SubFlagCandidate &A,
                               const SubFlagCandidate &B) {
      if (A.Root->getParent() == B.Root->getParent())
        return A.Root->comesBefore(B.Root);
      bool ADominates = DT.dominates(A.Root, B.Root);
      bool BDominates = DT.dominates(B.Root, A.Root);
      if (ADominates != BDominates) return ADominates;
      return std::less<Instruction *>{}(A.Root, B.Root);
    });
    for (const SubFlagCandidate &C : Candidates) {
      unsigned Index = llvm::find(OldRoots, C.Root) - OldRoots.begin();
      C.Root->replaceAllUsesWith(NewRoots[Index]);
      RecursivelyDeleteTriviallyDeadInstructions(C.Root);
      ++M.FlagConesRecovered;
      ProofRecord Record{F.getName().str(), "x86_flag_recovery",
                         Origins[Index],
                         "z3_bv_tuple_equivalence_unsat", "proved"};
      Record.OldHash = hashText(OldTexts[Index]);
      Record.NewHash = hashText(NewTexts[Index]);
      Record.ProofQueryHash = hashText(TupleCertificate);
      Record.Dependencies.push_back("complete_sub_flag_bundle_use_coverage");
      Record.Dependencies.push_back("fixed_width_x86_flag_formula");
      Record.Dependencies.push_back("identical_poison_support_per_flag");
      Proofs.push_back(std::move(Record));
    }
    return true;
  }
  return false;
}

enum class AddFlagKind { ZF, NZ, SF, OF, CF, PF };

struct AddFlagCandidate {
  Instruction *Root = nullptr;
  AddFlagKind Kind = AddFlagKind::ZF;
};

static bool matchAddZeroFlag(Value *V, BinaryOperator *&Add, bool &IsZero) {
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
               Cmp->getPredicate() != ICmpInst::ICMP_NE))
    return false;
  Value *Expr = Cmp->getOperand(0);
  auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
  if (!Zero || !Zero->isZero()) {
    Expr = Cmp->getOperand(1);
    Zero = dyn_cast<ConstantInt>(Cmp->getOperand(0));
  }
  auto *Candidate = dyn_cast<BinaryOperator>(Expr);
  if (!Zero || !Zero->isZero() || !Candidate ||
      Candidate->getOpcode() != Instruction::Add ||
      hasPoisonGeneratingFlags(Candidate))
    return false;
  Add = Candidate;
  IsZero = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
  return true;
}

static bool matchAddOverflowBit(Value *V, BinaryOperator *Add) {
  Value *Cone = nullptr;
  if (!matchSignBit(V, Cone)) return false;
  Value *X0 = nullptr, *X1 = nullptr;
  if (!matchBin(Cone, Instruction::And, X0, X1)) return false;
  auto Matches = [&](Value *NotSameSign, Value *ChangedSign) {
    Value *SameSignXor = nullptr;
    if (!matchBitwiseNot(NotSameSign, SameSignXor)) return false;
    Value *P = nullptr, *Q = nullptr;
    if (!matchBin(SameSignXor, Instruction::Xor, P, Q) ||
        !samePair(P, Q, Add->getOperand(0), Add->getOperand(1)))
      return false;
    if (!matchBin(ChangedSign, Instruction::Xor, P, Q)) return false;
    return samePair(P, Q, Add->getOperand(0), Add) ||
           samePair(P, Q, Add->getOperand(1), Add);
  };
  return Matches(X0, X1) || Matches(X1, X0);
}

static Value *buildAddFlagPredicate(const AddFlagCandidate &Candidate,
                                    BinaryOperator *Add) {
  IRBuilder<> B(Candidate.Root);
  Value *A = Add->getOperand(0), *RHS = Add->getOperand(1);
  Value *Zero = ConstantInt::get(Add->getType(), 0);
  switch (Candidate.Kind) {
  case AddFlagKind::ZF: return B.CreateICmpEQ(Add, Zero, "deobf.add.zf");
  case AddFlagKind::NZ: return B.CreateICmpNE(Add, Zero, "deobf.add.nz");
  case AddFlagKind::SF: return B.CreateICmpSLT(Add, Zero, "deobf.add.sf");
  case AddFlagKind::CF: return B.CreateICmpULT(Add, A, "deobf.add.cf");
  case AddFlagKind::OF: {
    Value *RHSPositive = B.CreateICmpSGT(RHS, Zero, "deobf.add.of.bp");
    Value *SumBelowA = B.CreateICmpSLT(Add, A, "deobf.add.of.sa");
    Value *PositiveOverflow =
        B.CreateAnd(RHSPositive, SumBelowA, "deobf.add.of.pos");
    Value *RHSNegative = B.CreateICmpSLT(RHS, Zero, "deobf.add.of.bn");
    Value *SumAboveA = B.CreateICmpSGT(Add, A, "deobf.add.of.sb");
    Value *NegativeOverflow =
        B.CreateAnd(RHSNegative, SumAboveA, "deobf.add.of.neg");
    return B.CreateOr(PositiveOverflow, NegativeOverflow, "deobf.add.of");
  }
  case AddFlagKind::PF: {
    return buildLowByteParityPredicate(B, Add, "deobf.add.pf");
  }
  }
  llvm_unreachable("unknown addition flag kind");
}

static bool rewriteOneAddFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<BinaryOperator *, 16> Producers;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::Add &&
        BO->getType()->isIntegerTy() && !hasPoisonGeneratingFlags(BO))
      Producers.push_back(BO);
  for (BinaryOperator *Add : Producers) {
    SmallVector<AddFlagCandidate, 8> Candidates;
    auto AddCandidate = [&](Instruction *Root, AddFlagKind Kind) {
      if (!llvm::any_of(Candidates,
                        [&](const AddFlagCandidate &C) { return C.Root == Root; }))
        Candidates.push_back({Root, Kind});
    };
    for (Instruction &I : instructions(F)) {
      if (!I.getType()->isIntegerTy(1)) continue;
      BinaryOperator *Matched = nullptr;
      bool IsZero = false;
      Value *ParityByte = nullptr, *SFSource = nullptr;
      if (matchAddZeroFlag(&I, Matched, IsZero) && Matched == Add)
        AddCandidate(&I, IsZero ? AddFlagKind::ZF : AddFlagKind::NZ);
      else if (matchAddCarryBit(&I, Matched) && Matched == Add)
        AddCandidate(&I, AddFlagKind::CF);
      else if (matchSignBit(&I, SFSource) && SFSource == Add)
        AddCandidate(&I, AddFlagKind::SF);
      else if (matchAddOverflowBit(&I, Add))
        AddCandidate(&I, AddFlagKind::OF);
      else if (matchLowByteEvenParity(&I, ParityByte) &&
               isLowByteOfProducer(ParityByte, Add))
        AddCandidate(&I, AddFlagKind::PF);
    }
    if (Candidates.size() < 2 ||
        llvm::all_of(Candidates, [](const AddFlagCandidate &C) {
          return isa<ICmpInst>(C.Root);
        }))
      continue;
    SmallPtrSet<Instruction *, 32> ConeNodes;
    SmallPtrSet<Instruction *, 8> Roots;
    bool Covered = true;
    for (const AddFlagCandidate &C : Candidates) {
      Roots.insert(C.Root);
      Covered &= collectCoveredFlagCone(C.Root, Add, ConeNodes);
    }
    for (Instruction *Node : ConeNodes) {
      if (Roots.contains(Node)) continue;
      for (User *U : Node->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || !ConeNodes.contains(UI)) {
          Covered = false;
          break;
        }
      }
      if (!Covered) break;
    }
    if (!Covered) continue;

    SmallVector<Value *, 8> OldRoots, NewRoots;
    SmallVector<std::string, 8> OldTexts, NewTexts, Origins;
    bool SamePoison = true;
    for (const AddFlagCandidate &C : Candidates) {
      Value *Replacement = buildAddFlagPredicate(C, Add);
      OldRoots.push_back(C.Root);
      NewRoots.push_back(Replacement);
      OldTexts.push_back(valueText(*C.Root));
      NewTexts.push_back(valueText(*Replacement));
      Origins.push_back(valueName(*C.Root));
      SamePoison &= hasSamePoisonSupport(C.Root, Replacement);
    }
    if (!SamePoison ||
        !provePairwiseTupleEquivalentSMT(OldRoots, NewRoots)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      for (Value *Replacement : NewRoots)
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI && RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }
    std::string TupleCertificate;
    raw_string_ostream TupleOS(TupleCertificate);
    for (unsigned I = 0; I != Candidates.size(); ++I)
      TupleOS << OldTexts[I] << "\n==\n" << NewTexts[I] << '\n';
    TupleOS.flush();
    DominatorTree DT(F);
    llvm::sort(Candidates, [&](const AddFlagCandidate &A,
                               const AddFlagCandidate &B) {
      if (A.Root->getParent() == B.Root->getParent())
        return A.Root->comesBefore(B.Root);
      bool ADominates = DT.dominates(A.Root, B.Root);
      bool BDominates = DT.dominates(B.Root, A.Root);
      if (ADominates != BDominates) return ADominates;
      return std::less<Instruction *>{}(A.Root, B.Root);
    });
    for (const AddFlagCandidate &C : Candidates) {
      unsigned Index = llvm::find(OldRoots, C.Root) - OldRoots.begin();
      C.Root->replaceAllUsesWith(NewRoots[Index]);
      RecursivelyDeleteTriviallyDeadInstructions(C.Root);
      ++M.FlagConesRecovered;
      ProofRecord Record{F.getName().str(), "x86_flag_recovery",
                         Origins[Index], "z3_bv_tuple_equivalence_unsat",
                         "proved"};
      Record.OldHash = hashText(OldTexts[Index]);
      Record.NewHash = hashText(NewTexts[Index]);
      Record.ProofQueryHash = hashText(TupleCertificate);
      Record.Dependencies.push_back("complete_add_flag_bundle_use_coverage");
      Record.Dependencies.push_back("fixed_width_x86_flag_formula");
      Record.Dependencies.push_back("identical_poison_support_per_flag");
      Proofs.push_back(std::move(Record));
    }
    return true;
  }
  return false;
}

enum class TestFlagKind { ZF, NZ, SF, PF };

struct TestFlagCandidate {
  Instruction *Root = nullptr;
  TestFlagKind Kind = TestFlagKind::ZF;
};

static bool matchTestZeroFlag(Value *V, BinaryOperator *&Test,
                              bool &IsZero) {
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
               Cmp->getPredicate() != ICmpInst::ICMP_NE))
    return false;
  Value *Expr = Cmp->getOperand(0);
  auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
  if (!Zero || !Zero->isZero()) {
    Expr = Cmp->getOperand(1);
    Zero = dyn_cast<ConstantInt>(Cmp->getOperand(0));
  }
  auto *Candidate = dyn_cast<BinaryOperator>(Expr);
  if (!Zero || !Zero->isZero() || !Candidate ||
      Candidate->getOpcode() != Instruction::And)
    return false;
  Test = Candidate;
  IsZero = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
  return true;
}

static Value *buildTestFlagPredicate(const TestFlagCandidate &Candidate,
                                     BinaryOperator *Test) {
  IRBuilder<> B(Candidate.Root);
  Value *Zero = ConstantInt::get(Test->getType(), 0);
  switch (Candidate.Kind) {
  case TestFlagKind::ZF:
    return B.CreateICmpEQ(Test, Zero, "deobf.test.zf");
  case TestFlagKind::NZ:
    return B.CreateICmpNE(Test, Zero, "deobf.test.nz");
  case TestFlagKind::SF:
    return B.CreateICmpSLT(Test, Zero, "deobf.test.sf");
  case TestFlagKind::PF: {
    return buildLowByteParityPredicate(B, Test, "deobf.test.pf");
  }
  }
  llvm_unreachable("unknown test flag kind");
}

static bool rewriteOneTestFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<BinaryOperator *, 16> Producers;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::And &&
        BO->getType()->isIntegerTy())
      Producers.push_back(BO);

  for (BinaryOperator *Test : Producers) {
    SmallVector<TestFlagCandidate, 8> Candidates;
    auto AddCandidate = [&](Instruction *Root, TestFlagKind Kind) {
      if (!llvm::any_of(Candidates, [&](const TestFlagCandidate &C) {
            return C.Root == Root;
          }))
        Candidates.push_back({Root, Kind});
    };
    for (Instruction &I : instructions(F)) {
      if (!I.getType()->isIntegerTy(1)) continue;
      BinaryOperator *Matched = nullptr;
      bool IsZero = false;
      Value *ParityByte = nullptr, *SFSource = nullptr;
      if (matchTestZeroFlag(&I, Matched, IsZero) && Matched == Test)
        AddCandidate(&I, IsZero ? TestFlagKind::ZF : TestFlagKind::NZ);
      else if (matchSignBit(&I, SFSource) && SFSource == Test)
        AddCandidate(&I, TestFlagKind::SF);
      else if (matchLowByteEvenParity(&I, ParityByte) &&
               isLowByteOfProducer(ParityByte, Test))
        AddCandidate(&I, TestFlagKind::PF);
    }
    if (Candidates.size() < 2 ||
        llvm::all_of(Candidates, [](const TestFlagCandidate &C) {
          return isa<ICmpInst>(C.Root);
        }))
      continue;

    SmallPtrSet<Instruction *, 32> ConeNodes;
    SmallPtrSet<Instruction *, 8> Roots;
    bool Covered = true;
    for (const TestFlagCandidate &C : Candidates) {
      Roots.insert(C.Root);
      Covered &= collectCoveredFlagCone(C.Root, Test, ConeNodes);
    }
    for (Instruction *Node : ConeNodes) {
      if (Roots.contains(Node)) continue;
      for (User *U : Node->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || !ConeNodes.contains(UI)) {
          Covered = false;
          break;
        }
      }
      if (!Covered) break;
    }
    if (!Covered) continue;

    SmallVector<Value *, 8> OldRoots, NewRoots;
    SmallVector<std::string, 8> OldTexts, NewTexts, Origins;
    bool SamePoison = true;
    for (const TestFlagCandidate &C : Candidates) {
      Value *Replacement = buildTestFlagPredicate(C, Test);
      OldRoots.push_back(C.Root);
      NewRoots.push_back(Replacement);
      OldTexts.push_back(valueText(*C.Root));
      NewTexts.push_back(valueText(*Replacement));
      Origins.push_back(valueName(*C.Root));
      SamePoison &= hasSamePoisonSupport(C.Root, Replacement);
    }
    if (!SamePoison || !provePairwiseTupleEquivalentSMT(OldRoots, NewRoots)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      for (Value *Replacement : NewRoots)
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI && RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }

    std::string TupleCertificate;
    raw_string_ostream TupleOS(TupleCertificate);
    for (unsigned I = 0; I != Candidates.size(); ++I)
      TupleOS << OldTexts[I] << "\n==\n" << NewTexts[I] << '\n';
    TupleOS.flush();
    DominatorTree DT(F);
    llvm::sort(Candidates, [&](const TestFlagCandidate &A,
                               const TestFlagCandidate &B) {
      if (A.Root->getParent() == B.Root->getParent())
        return A.Root->comesBefore(B.Root);
      bool ADominates = DT.dominates(A.Root, B.Root);
      bool BDominates = DT.dominates(B.Root, A.Root);
      if (ADominates != BDominates) return ADominates;
      return std::less<Instruction *>{}(A.Root, B.Root);
    });
    for (const TestFlagCandidate &C : Candidates) {
      unsigned Index = llvm::find(OldRoots, C.Root) - OldRoots.begin();
      C.Root->replaceAllUsesWith(NewRoots[Index]);
      RecursivelyDeleteTriviallyDeadInstructions(C.Root);
      ++M.FlagConesRecovered;
      ProofRecord Record{F.getName().str(), "x86_flag_recovery",
                         Origins[Index], "z3_bv_tuple_equivalence_unsat",
                         "proved"};
      Record.OldHash = hashText(OldTexts[Index]);
      Record.NewHash = hashText(NewTexts[Index]);
      Record.ProofQueryHash = hashText(TupleCertificate);
      Record.Dependencies.push_back("complete_test_flag_bundle_use_coverage");
      Record.Dependencies.push_back("fixed_width_x86_flag_formula");
      Record.Dependencies.push_back("identical_poison_support_per_flag");
      Proofs.push_back(std::move(Record));
    }
    return true;
  }
  return false;
}

static bool rewriteX86FlagCones(Function &F, Metrics &M,
                                SmallVectorImpl<ProofRecord> &Proofs) {
  bool Changed = false;
  for (unsigned Transaction = 0; Transaction != 16; ++Transaction) {
    bool Local = rewriteOneTestFlagBundle(F, M, Proofs);
    Changed |= Local;
    if (!Local) break;
  }
  for (unsigned Transaction = 0; Transaction != 16; ++Transaction) {
    bool Local = rewriteOneAddFlagBundle(F, M, Proofs);
    Changed |= Local;
    if (!Local) break;
  }
  for (unsigned Transaction = 0; Transaction != 16; ++Transaction) {
    bool Local = rewriteOneSubFlagBundle(F, M, Proofs);
    Changed |= Local;
    if (!Local) break;
  }
  SmallVector<WeakTrackingVH, 32> Work;
  for (Instruction &I : instructions(F))
    if (I.getType()->isIntegerTy(1)) Work.emplace_back(&I);
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<Instruction>(Handle);
    if (!Root) continue;
    Value *Replacement = nullptr;
    IRBuilder<> B(Root);
    Value *StandaloneSFSource = nullptr;
    BinaryOperator *FlagOperation = nullptr;
    Value *ParityByte = nullptr;
    Value *Negated = nullptr;
    Value *ConditionA = nullptr, *ConditionB = nullptr;
    if (feedsFlagBooleanCombiner(*Root)) {
      continue;
    } else if (matchBooleanNot(Root, Negated) &&
        matchCombinedConditionOperands(Negated, false, ConditionA,
                                       ConditionB)) {
      Replacement = B.CreateICmpUGT(ConditionA, ConditionB,
                                    "deobf.cc.a");
    } else if (matchBooleanNot(Root, Negated) &&
               matchCombinedConditionOperands(Negated, true, ConditionA,
                                              ConditionB)) {
      Replacement = B.CreateICmpSGT(ConditionA, ConditionB,
                                    "deobf.cc.g");
    } else if (matchBooleanNot(Root, Negated) &&
               matchUnsignedLessOperands(Negated, ConditionA, ConditionB)) {
      Replacement = B.CreateICmpUGE(ConditionA, ConditionB,
                                    "deobf.cc.ae");
    } else if (matchBooleanNot(Root, Negated) &&
               matchSignedLessOperands(Negated, ConditionA, ConditionB)) {
      Replacement = B.CreateICmpSGE(ConditionA, ConditionB,
                                    "deobf.cc.ge");
    } else if (matchCombinedConditionOperands(Root, false, ConditionA,
                                              ConditionB)) {
      Replacement = B.CreateICmpULE(ConditionA, ConditionB,
                                    "deobf.cc.be");
    } else if (matchCombinedConditionOperands(Root, true, ConditionA,
                                              ConditionB)) {
      Replacement = B.CreateICmpSLE(ConditionA, ConditionB,
                                    "deobf.cc.le");
    } else if (isa<TruncInst>(Root) &&
               matchAddCarryBit(Root, FlagOperation)) {
      Replacement = B.CreateICmpULT(FlagOperation,
                                    FlagOperation->getOperand(0),
                                    "deobf.cf.add");
    } else if (isa<TruncInst>(Root) &&
               matchSubBorrowBit(Root, FlagOperation)) {
      Replacement = B.CreateICmpULT(FlagOperation->getOperand(0),
                                    FlagOperation->getOperand(1),
                                    "deobf.cf.sub");
    } else if (matchLowByteEvenParity(Root, ParityByte)) {
      Function *Ctpop = Intrinsic::getOrInsertDeclaration(
          F.getParent(), Intrinsic::ctpop, {ParityByte->getType()});
      Value *Count = B.CreateCall(Ctpop, {ParityByte}, "deobf.pf.count");
      Value *LowBit = B.CreateAnd(
          Count, ConstantInt::get(ParityByte->getType(), 1),
          "deobf.pf.bit");
      Replacement = B.CreateICmpEQ(
          LowBit, ConstantInt::get(ParityByte->getType(), 0), "deobf.pf");
    } else if (isa<TruncInst>(Root) &&
               matchSignBit(Root, StandaloneSFSource)) {
      Replacement = B.CreateICmpSLT(
          StandaloneSFSource,
          ConstantInt::get(StandaloneSFSource->getType(), 0), "deobf.sf");
    } else if (auto *Cmp = dyn_cast<ICmpInst>(Root)) {
      if (Cmp->getPredicate() == ICmpInst::ICMP_EQ ||
          Cmp->getPredicate() == ICmpInst::ICMP_NE) {
        Value *Expr = Cmp->getOperand(0);
        auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
        if (!Zero || !Zero->isZero()) {
          Expr = Cmp->getOperand(1);
          Zero = dyn_cast<ConstantInt>(Cmp->getOperand(0));
        }
        auto *Sub = dyn_cast<BinaryOperator>(Expr);
        if (Zero && Zero->isZero() && Sub &&
            Sub->getOpcode() == Instruction::Sub &&
            !hasPoisonGeneratingFlags(Sub)) {
          ICmpInst::Predicate Predicate =
              Cmp->getPredicate() == ICmpInst::ICMP_NE
                  ? ICmpInst::ICMP_NE
                  : ICmpInst::ICMP_EQ;
          Replacement = B.CreateICmp(Predicate, Sub->getOperand(0),
                                     Sub->getOperand(1), "deobf.zf");
        }
      }
    } else if (auto *BO = dyn_cast<BinaryOperator>(Root)) {
      if (BO->getOpcode() == Instruction::Or) {
        auto *L = dyn_cast<ICmpInst>(BO->getOperand(0));
        auto *R = dyn_cast<ICmpInst>(BO->getOperand(1));
        if (L && R && sameICmpOperands(L, R)) {
          ICmpInst *CF = L, *ZF = R;
          if (CF->getPredicate() == ICmpInst::ICMP_EQ) std::swap(CF, ZF);
          if (CF->getPredicate() == ICmpInst::ICMP_ULT &&
              ZF->getPredicate() == ICmpInst::ICMP_EQ)
            Replacement = B.CreateICmpULE(CF->getOperand(0), CF->getOperand(1),
                                          "deobf.cf_or_zf");
        }
      } else if (BO->getOpcode() == Instruction::Xor) {
        Value *SFSource = nullptr;
        Value *SF = BO->getOperand(0), *OF = BO->getOperand(1);
        if (!matchSignBit(SF, SFSource)) {
          std::swap(SF, OF);
          SFSource = nullptr;
        }
        auto *Sub = dyn_cast_or_null<BinaryOperator>(SFSource);
        if (Sub && Sub->getOpcode() == Instruction::Sub &&
            !hasPoisonGeneratingFlags(Sub) && matchSubOverflowBit(OF, Sub))
          Replacement = B.CreateICmpSLT(Sub->getOperand(0), Sub->getOperand(1),
                                        "deobf.sf_xor_of");
      }
    }
    if (!Replacement) continue;
    auto *ReplacementI = cast<Instruction>(Replacement);
    bool SamePoison = hasSamePoisonSupport(Root, Replacement);
    bool Equivalent = SamePoison && proveEquivalentSMT(Root, Replacement);
    if (!Equivalent) {
      if (ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.FlagConesRecovered;
    ProofRecord Record{F.getName().str(), "x86_flag_recovery", Origin,
                       "z3_bv_equivalence_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("fixed_width_x86_flag_formula");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

static bool matchRotateLeftIdiom(BinaryOperator &Root, Value *&Input,
                                 unsigned &Amount) {
  if (Root.getOpcode() != Instruction::Or ||
      !Root.getType()->isIntegerTy())
    return false;
  auto Try = [&](Value *ShlValue, Value *LShrValue) {
    auto *Shl = dyn_cast<BinaryOperator>(ShlValue);
    auto *LShr = dyn_cast<BinaryOperator>(LShrValue);
    if (!Shl || !LShr || Shl->getOpcode() != Instruction::Shl ||
        LShr->getOpcode() != Instruction::LShr ||
        hasPoisonGeneratingFlags(Shl) || hasPoisonGeneratingFlags(LShr) ||
        Shl->getOperand(0) != LShr->getOperand(0))
      return false;
    auto *Left = dyn_cast<ConstantInt>(Shl->getOperand(1));
    auto *Right = dyn_cast<ConstantInt>(LShr->getOperand(1));
    unsigned Width = Root.getType()->getIntegerBitWidth();
    if (!Left || !Right || Left->getValue().uge(Width) ||
        Right->getValue().uge(Width) || Left->isZero() || Right->isZero() ||
        Left->getValue().urem(Width) + Right->getValue().urem(Width) != Width)
      return false;
    Input = Shl->getOperand(0);
    Amount = static_cast<unsigned>(Left->getValue().urem(Width));
    return true;
  };
  return Try(Root.getOperand(0), Root.getOperand(1)) ||
         Try(Root.getOperand(1), Root.getOperand(0));
}

static bool rewriteRotateRegions(Function &F, Metrics &M,
                                 SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 16> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::Or)
      Work.emplace_back(BO);
  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    Value *Input = nullptr;
    unsigned Amount = 0;
    if (!matchRotateLeftIdiom(*Root, Input, Amount)) continue;
    Function *Fshl = Intrinsic::getOrInsertDeclaration(
        F.getParent(), Intrinsic::fshl, {Root->getType()});
    IRBuilder<> B(Root);
    Value *Replacement = B.CreateCall(
        Fshl, {Input, Input, ConstantInt::get(Root->getType(), Amount)},
        "deobf.rotl");
    auto *ReplacementI = cast<Instruction>(Replacement);
    if (!hasSamePoisonSupport(Root, Replacement) ||
        !proveEquivalentSMT(Root, Replacement)) {
      if (ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origin,
                       "rotate_idiom_z3_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("constant_shift_counts_in_range");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

static bool rewriteFunction(Function &F, MemorySSA &MSSA, Metrics &M,
                            SmallVectorImpl<ProofRecord> &Proofs) {
  bool Changed = false;
  for (unsigned Round = 0; Round != 16; ++Round) {
    bool RoundChanged = false;
    SmallVector<BinaryOperator *, 64> Work;
    for (Instruction &I : instructions(F))
      if (auto *BO = dyn_cast<BinaryOperator>(&I))
        Work.push_back(BO);
    for (BinaryOperator *BO : Work) {
      if (!BO->getParent()) continue;
      bool InstSub = false;
      Value *Replacement = matchCanonicalRewrite(*BO, InstSub);
      if (!Replacement || Replacement == BO) continue;
      std::string Origin = valueName(*BO);
      std::string OldText = valueText(*BO);
      std::string NewText = valueText(*Replacement);
      std::string QueryHash = hashText(OldText + "\n!=\n" + NewText);
      if (!hasSamePoisonSupport(BO, Replacement)) {
        ++M.PoisonSupportRejects;
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
        continue;
      }
      if (!proveEquivalentSMT(BO, Replacement)) {
        ProofRecord Record{F.getName().str(), "rewrite_candidate", Origin,
                           "z3_bv_equivalence", "unresolved",
                           "equivalence_query_not_unsat"};
        Record.OldHash = hashText(OldText);
        Record.NewHash = hashText(NewText);
        Record.ProofQueryHash = QueryHash;
        Record.Dependencies.push_back("llvm_poison_flags_absent");
        Proofs.push_back(std::move(Record));
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
        continue;
      }
      BO->replaceAllUsesWith(Replacement);
      if (BO->use_empty()) BO->eraseFromParent();
      ++M.BVRewrites;
      if (InstSub) ++M.InstSubRewrites;
      ProofRecord Record{F.getName().str(),
                         InstSub ? "instsub_rewrite" : "bv_canonicalize",
                         Origin, "z3_bv_equivalence_unsat", "proved"};
      Record.OldHash = hashText(OldText);
      Record.NewHash = hashText(NewText);
      Record.ProofQueryHash = QueryHash;
      Record.Dependencies.push_back("llvm_poison_flags_absent");
      Proofs.push_back(std::move(Record));
      Changed = RoundChanged = true;
    }
    if (!RoundChanged) break;
  }

  Changed |= rewriteX86FlagCones(F, M, Proofs);
  Changed |= rewriteDeMorganCastRegions(F, M, Proofs);
  Changed |= rewriteRotateRegions(F, M, Proofs);

  SmallVector<BranchInst *, 16> Branches;
  for (BasicBlock &BB : F)
    if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
        BI && BI->isConditional())
      Branches.push_back(BI);
  DominatorTree DT(F);
  DenseMap<const LoadInst *, Value *> ReachingLoadValues =
      buildMemorySSAReachingValues(F, MSSA, M);
  struct ProvenBranch {
    BranchInst *BI = nullptr;
    bool TakenTrue = false;
    std::string Engine;
    std::string ConstraintCertificate;
    unsigned ConstraintCount = 0;
    unsigned MemoryLoadsResolved = 0;
    unsigned PathStateITEsResolved = 0;
    unsigned SwitchPathStateITEsResolved = 0;
    unsigned InductivePhisResolved = 0;
    bool CyclicPredicateInduction = false;
  };
  SmallVector<ProvenBranch, 16> ProvenBranches;
  for (BranchInst *BI : Branches) {
    std::optional<bool> Proof = proveBoolean(BI->getCondition());
    std::string ProofEngine = "adjacent_product_parity";
    std::string ConstraintCertificate;
    unsigned ConstraintCount = 0;
    unsigned MemoryLoadsResolved = 0;
    unsigned PathStateITEsResolved = 0;
    unsigned SwitchPathStateITEsResolved = 0;
    unsigned InductivePhisResolved = 0;
    bool CyclicPredicateInduction = false;
    if (!Proof) {
      SmallVector<PathConstraint, 16> Constraints =
          collectDominatingConstraints(*BI, DT);
      auto SMTProof = proveBooleanSMT(BI->getCondition(), Constraints,
                                      &ReachingLoadValues);
      if (SMTProof) {
        Proof = SMTProof->Value;
        ConstraintCount = SMTProof->ConstraintCount;
        ConstraintCertificate = std::move(SMTProof->ConstraintCertificate);
        MemoryLoadsResolved = SMTProof->MemoryLoadsResolved;
        SwitchPathStateITEsResolved =
            SMTProof->SwitchPathStateITEsResolved;
        InductivePhisResolved = SMTProof->InductivePhisResolved;
        PathStateITEsResolved = SMTProof->PathStateITEsResolved +
                                SwitchPathStateITEsResolved;
        if (InductivePhisResolved && MemoryLoadsResolved && ConstraintCount)
          ProofEngine =
              "z3_memoryssa_inductive_constant_phi_with_dominating_constraints_unsat";
        else if (InductivePhisResolved && MemoryLoadsResolved)
          ProofEngine = "z3_memoryssa_inductive_constant_phi_unsat";
        else if (InductivePhisResolved && ConstraintCount)
          ProofEngine =
              "z3_inductive_constant_phi_with_dominating_constraints_unsat";
        else if (InductivePhisResolved)
          ProofEngine = "z3_inductive_constant_phi_unsat";
        else if (MemoryLoadsResolved && PathStateITEsResolved && ConstraintCount)
          ProofEngine =
              "z3_memoryssa_path_state_ite_with_dominating_constraints_unsat";
        else if (MemoryLoadsResolved && PathStateITEsResolved)
          ProofEngine = "z3_memoryssa_path_state_ite_unsat";
        else if (PathStateITEsResolved && ConstraintCount)
          ProofEngine =
              "z3_path_state_ite_with_dominating_constraints_unsat";
        else if (PathStateITEsResolved)
          ProofEngine = "z3_path_state_ite_unsat";
        else if (MemoryLoadsResolved && ConstraintCount)
          ProofEngine =
              "z3_memoryssa_with_dominating_constraints_unsat";
        else if (MemoryLoadsResolved)
          ProofEngine = "z3_memoryssa_bitvector_unsat";
        else if (ConstraintCount)
          ProofEngine = "z3_bitvector_with_dominating_constraints_unsat";
        else
          ProofEngine = "z3_bitvector_unsat";
      }
    }
    if (!Proof) {
      auto CyclicProof = proveBooleanCyclicInduction(BI->getCondition());
      if (CyclicProof) {
        Proof = CyclicProof->Value;
        ProofEngine = "z3_cyclic_predicate_induction_unsat";
        ConstraintCertificate = std::move(CyclicProof->Certificate);
        InductivePhisResolved = 1;
        CyclicPredicateInduction = true;
      }
    }
    if (!Proof) continue;
    ProvenBranches.push_back({BI, *Proof, std::move(ProofEngine),
                              std::move(ConstraintCertificate),
                              ConstraintCount, MemoryLoadsResolved,
                              PathStateITEsResolved,
                              SwitchPathStateITEsResolved,
                              InductivePhisResolved,
                              CyclicPredicateInduction});
  }
  for (const ProvenBranch &Proven : ProvenBranches) {
    BranchInst *BI = Proven.BI;
    bool Proof = Proven.TakenTrue;
    BasicBlock *Taken = BI->getSuccessor(Proof ? 0 : 1);
    BasicBlock *Dead = BI->getSuccessor(Proof ? 1 : 0);
    if (Dead != Taken)
      Dead->removePredecessor(BI->getParent());
    std::string Origin = BI->getParent()->getName().str();
    std::string ConditionText = valueText(*BI->getCondition());
    std::string TargetText = ("branch:" + Taken->getName()).str();
    BranchInst::Create(Taken, BI->getIterator());
    BI->eraseFromParent();
    ++M.OpaqueEdgesPruned;
    if (Proven.ConstraintCount) ++M.PathConstrainedOpaqueEdges;
    ProofRecord Record{F.getName().str(), "opaque_edge", Origin,
                       Proven.Engine, "proved"};
    Record.OldHash = hashText(ConditionText);
    Record.NewHash = hashText(TargetText);
    Record.ProofQueryHash =
        hashText(ConditionText + (Proof ? "\nprove:true\n" : "\nprove:false\n") +
                 Proven.ConstraintCertificate);
    Record.Dependencies.push_back("fixed_width_bitvector_semantics");
    if (Proven.ConstraintCount) {
      Record.Dependencies.push_back("dominating_path_constraints_sat");
      Record.Dependencies.push_back(
          "path_constraint_count=" + std::to_string(Proven.ConstraintCount));
    }
    if (Proven.MemoryLoadsResolved) {
      ++M.MemorySSAConstrainedOpaqueEdges;
      Record.Dependencies.push_back("memoryssa_exact_reaching_store");
      Record.Dependencies.push_back(
          "memoryssa_load_count=" +
          std::to_string(Proven.MemoryLoadsResolved));
    }
    if (Proven.PathStateITEsResolved) {
      ++M.PathStateITEOpaqueEdges;
      if (Proven.PathStateITEsResolved >
          Proven.SwitchPathStateITEsResolved)
        Record.Dependencies.push_back("exact_two_arm_diamond_phi_ite");
      if (Proven.SwitchPathStateITEsResolved)
        Record.Dependencies.push_back("exact_multi_arm_switch_funnel_phi_ite");
      Record.Dependencies.push_back(
          "path_state_ite_count=" +
          std::to_string(Proven.PathStateITEsResolved));
    }
    if (Proven.InductivePhisResolved) {
      ++M.InductivePhiOpaqueEdges;
      if (Proven.CyclicPredicateInduction) {
        Record.Dependencies.push_back(
            "all_external_seeds_establish_predicate");
        Record.Dependencies.push_back(
            "all_backedge_recurrences_preserve_predicate_by_z3_induction");
      } else {
        Record.Dependencies.push_back(
            "inductive_seed_from_non_backedge_constant");
        Record.Dependencies.push_back(
            "all_backedge_recurrences_preserve_seed");
      }
      Record.Dependencies.push_back(
          "inductive_phi_count=" +
          std::to_string(Proven.InductivePhisResolved));
    }
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

static PHINode *findStateRoot(Value *V, unsigned Depth = 0) {
  if (Depth > 8) return nullptr;
  if (auto *PN = dyn_cast<PHINode>(V)) return PN;
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    if (II->getIntrinsicID() == Intrinsic::bswap)
      return findStateRoot(II->getArgOperand(0), Depth + 1);
    if ((II->getIntrinsicID() == Intrinsic::fshl ||
         II->getIntrinsicID() == Intrinsic::fshr) &&
        II->getArgOperand(0) == II->getArgOperand(1) &&
        isa<ConstantInt>(II->getArgOperand(2)))
      return findStateRoot(II->getArgOperand(0), Depth + 1);
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || !BO->getType()->isIntegerTy()) return nullptr;
  Value *A = BO->getOperand(0), *B = BO->getOperand(1);
  if (isa<ConstantInt>(B)) return findStateRoot(A, Depth + 1);
  if (BO->isCommutative() && isa<ConstantInt>(A))
    return findStateRoot(B, Depth + 1);
  return nullptr;
}

static std::optional<bool> evalStatePredicate(Value *V, PHINode *Root,
                                              const APInt &State,
                                              unsigned Depth) {
  if (Depth > 12) return std::nullopt;
  if (auto *C = dyn_cast<ConstantInt>(V))
    if (C->getType()->isIntegerTy(1)) return !C->isZero();
  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    auto L = evalStateExpr(Cmp->getOperand(0), Root, State, Depth + 1);
    auto R = evalStateExpr(Cmp->getOperand(1), Root, State, Depth + 1);
    if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
    switch (Cmp->getPredicate()) {
    case ICmpInst::ICMP_EQ: return *L == *R;
    case ICmpInst::ICMP_NE: return *L != *R;
    case ICmpInst::ICMP_UGT: return L->ugt(*R);
    case ICmpInst::ICMP_UGE: return L->uge(*R);
    case ICmpInst::ICMP_ULT: return L->ult(*R);
    case ICmpInst::ICMP_ULE: return L->ule(*R);
    case ICmpInst::ICMP_SGT: return L->sgt(*R);
    case ICmpInst::ICMP_SGE: return L->sge(*R);
    case ICmpInst::ICMP_SLT: return L->slt(*R);
    case ICmpInst::ICMP_SLE: return L->sle(*R);
    default: return std::nullopt;
    }
  }
  if (auto *BO = dyn_cast<BinaryOperator>(V);
      BO && BO->getType()->isIntegerTy(1) &&
      !hasPoisonGeneratingFlags(BO)) {
    auto L = evalStatePredicate(BO->getOperand(0), Root, State, Depth + 1);
    auto R = evalStatePredicate(BO->getOperand(1), Root, State, Depth + 1);
    if (!L || !R) return std::nullopt;
    if (BO->getOpcode() == Instruction::And) return *L && *R;
    if (BO->getOpcode() == Instruction::Or) return *L || *R;
    if (BO->getOpcode() == Instruction::Xor) return *L != *R;
  }
  auto E = evalStateExpr(V, Root, State, Depth + 1);
  if (E && E->getBitWidth() == 1) return !E->isZero();
  return std::nullopt;
}

static std::optional<APInt> evalStateExpr(Value *V, PHINode *Root,
                                          const APInt &State,
                                          unsigned Depth) {
  if (Depth > 12) return std::nullopt;
  if (V == Root) return State;
  if (auto *CI = dyn_cast<ConstantInt>(V)) return CI->getValue();
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    auto Op = evalStateExpr(Cast->getOperand(0), Root, State, Depth + 1);
    if (!Op || !Cast->getType()->isIntegerTy()) return std::nullopt;
    unsigned Width = Cast->getType()->getIntegerBitWidth();
    switch (Cast->getOpcode()) {
    case Instruction::Trunc:
      if (cast<TruncInst>(Cast)->hasNoUnsignedWrap()) return std::nullopt;
      return Op->trunc(Width);
    case Instruction::ZExt: return Op->zext(Width);
    case Instruction::SExt: return Op->sext(Width);
    case Instruction::BitCast:
      return Op->getBitWidth() == Width ? Op : std::optional<APInt>();
    default: return std::nullopt;
    }
  }
  if (auto *Select = dyn_cast<SelectInst>(V)) {
    auto T = evalStateExpr(Select->getTrueValue(), Root, State, Depth + 1);
    auto F = evalStateExpr(Select->getFalseValue(), Root, State, Depth + 1);
    if (!T || !F) return std::nullopt;
    if (*T == *F) return T;
    auto C = evalStatePredicate(Select->getCondition(), Root, State,
                                Depth + 1);
    return C ? (*C ? T : F) : std::nullopt;
  }
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    auto Op = evalStateExpr(II->getArgOperand(0), Root, State, Depth + 1);
    if (!Op) return std::nullopt;
    if (II->getIntrinsicID() == Intrinsic::bswap)
      return Op->getBitWidth() % 16 == 0
                 ? std::optional<APInt>(Op->byteSwap())
                 : std::nullopt;
    auto *Amount = dyn_cast<ConstantInt>(II->getArgOperand(2));
    if (!Amount || II->getArgOperand(0) != II->getArgOperand(1))
      return std::nullopt;
    unsigned Rotate = Amount->getValue().urem(Op->getBitWidth());
    if (II->getIntrinsicID() == Intrinsic::fshl) return Op->rotl(Rotate);
    if (II->getIntrinsicID() == Intrinsic::fshr) return Op->rotr(Rotate);
    return std::nullopt;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || hasPoisonGeneratingFlags(BO)) return std::nullopt;
  auto L = evalStateExpr(BO->getOperand(0), Root, State, Depth + 1);
  auto R = evalStateExpr(BO->getOperand(1), Root, State, Depth + 1);
  if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
  switch (BO->getOpcode()) {
  case Instruction::Add: return *L + *R;
  case Instruction::Sub: return *L - *R;
  case Instruction::Mul: return *L * *R;
  case Instruction::Xor: return *L ^ *R;
  case Instruction::And: return *L & *R;
  case Instruction::Or: return *L | *R;
  case Instruction::Shl:
  case Instruction::LShr:
  case Instruction::AShr: {
    uint64_t Amount = R->getLimitedValue(L->getBitWidth());
    if (Amount >= L->getBitWidth()) return std::nullopt;
    if (BO->getOpcode() == Instruction::Shl) return L->shl(Amount);
    if (BO->getOpcode() == Instruction::LShr) return L->lshr(Amount);
    return L->ashr(Amount);
  }
  default: return std::nullopt;
  }
}

static std::optional<APInt> decodeStateExpr(Value *V, PHINode *Root,
                                            const APInt &Encoded,
                                            unsigned Depth = 0) {
  if (Depth > 12) return std::nullopt;
  if (V == Root) return Encoded;
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    if (II->getIntrinsicID() == Intrinsic::bswap) {
      if (Encoded.getBitWidth() % 16 != 0) return std::nullopt;
      return decodeStateExpr(II->getArgOperand(0), Root, Encoded.byteSwap(),
                             Depth + 1);
    }
    auto *Amount = dyn_cast<ConstantInt>(II->getArgOperand(2));
    if (!Amount || II->getArgOperand(0) != II->getArgOperand(1))
      return std::nullopt;
    unsigned Rotate = Amount->getValue().urem(Encoded.getBitWidth());
    if (II->getIntrinsicID() == Intrinsic::fshl)
      return decodeStateExpr(II->getArgOperand(0), Root,
                             Encoded.rotr(Rotate), Depth + 1);
    if (II->getIntrinsicID() == Intrinsic::fshr)
      return decodeStateExpr(II->getArgOperand(0), Root,
                             Encoded.rotl(Rotate), Depth + 1);
    return std::nullopt;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || hasPoisonGeneratingFlags(BO)) return std::nullopt;
  auto *LC = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *RC = dyn_cast<ConstantInt>(BO->getOperand(1));
  Value *Variable = nullptr;
  APInt Next = Encoded;
  switch (BO->getOpcode()) {
  case Instruction::Add:
    if (RC) { Variable = BO->getOperand(0); Next -= RC->getValue(); }
    else if (LC) { Variable = BO->getOperand(1); Next -= LC->getValue(); }
    break;
  case Instruction::Sub:
    if (RC) { Variable = BO->getOperand(0); Next += RC->getValue(); }
    else if (LC) { Variable = BO->getOperand(1); Next = LC->getValue() - Next; }
    break;
  case Instruction::Xor:
    if (RC) { Variable = BO->getOperand(0); Next ^= RC->getValue(); }
    else if (LC) { Variable = BO->getOperand(1); Next ^= LC->getValue(); }
    break;
  case Instruction::Mul: {
    ConstantInt *C = RC ? RC : LC;
    if (!C || !C->getValue()[0]) break;
    Variable = RC ? BO->getOperand(0) : BO->getOperand(1);
    Next *= C->getValue().multiplicativeInverse();
    break;
  }
  default: break;
  }
  if (!Variable) return std::nullopt;
  return decodeStateExpr(Variable, Root, Next, Depth + 1);
}

struct ProvenTransition {
  BasicBlock *Source = nullptr;
  Value *Condition = nullptr;
  BasicBlock *TrueTarget = nullptr;
  BasicBlock *FalseTarget = nullptr;
};

struct IntAffine {
  const GlobalValue *Base = nullptr;
  int Coeff = 0;
  APInt Offset = APInt(64, 0);
  bool Valid = false;
};

static IntAffine parsePointerAffine(Value *V, unsigned Depth = 0);

static IntAffine combineAffine(const IntAffine &L, const IntAffine &R,
                               bool Subtract) {
  if (!L.Valid || !R.Valid) return {};
  if (L.Base && R.Base && L.Base != R.Base) return {};
  IntAffine Out;
  Out.Valid = true;
  Out.Base = L.Base ? L.Base : R.Base;
  int RCoeff = Subtract ? -R.Coeff : R.Coeff;
  Out.Coeff = L.Coeff + RCoeff;
  Out.Offset = Subtract ? L.Offset - R.Offset : L.Offset + R.Offset;
  if (Out.Coeff == 0) Out.Base = nullptr;
  return Out;
}

static IntAffine parseIntegerAffine(Value *V, unsigned Depth = 0) {
  if (Depth > 24) return {};
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    IntAffine Out;
    Out.Valid = true;
    Out.Offset = CI->getValue().sextOrTrunc(64);
    return Out;
  }
  auto *Op = dyn_cast<Operator>(V);
  if (!Op) return {};
  if (Op->getOpcode() == Instruction::PtrToInt) {
    IntAffine Out = parsePointerAffine(Op->getOperand(0), Depth + 1);
    if (!Out.Valid) return {};
    Out.Offset = Out.Offset.sextOrTrunc(64);
    return Out;
  }
  if (Op->getOpcode() != Instruction::Add &&
      Op->getOpcode() != Instruction::Sub)
    return {};
  IntAffine L = parseIntegerAffine(Op->getOperand(0), Depth + 1);
  IntAffine R = parseIntegerAffine(Op->getOperand(1), Depth + 1);
  return combineAffine(L, R, Op->getOpcode() == Instruction::Sub);
}

static IntAffine parsePointerAffine(Value *V, unsigned Depth) {
  if (Depth > 24) return {};
  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    IntAffine Out;
    Out.Base = GV;
    Out.Coeff = 1;
    Out.Valid = true;
    return Out;
  }
  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    if (!GEP->getSourceElementType()->isIntegerTy(8) ||
        GEP->getNumIndices() != 1)
      return {};
    IntAffine Base = parsePointerAffine(GEP->getPointerOperand(), Depth + 1);
    IntAffine Index = parseIntegerAffine(*GEP->idx_begin(), Depth + 1);
    return combineAffine(Base, Index, false);
  }
  auto *Op = dyn_cast<Operator>(V);
  if (Op && Op->getOpcode() == Instruction::IntToPtr)
    return parseIntegerAffine(Op->getOperand(0), Depth + 1);
  return {};
}

static bool sameFrameAddress(Value *A, Value *B) {
  if (A == B) return true;
  IntAffine PA = parsePointerAffine(A), PB = parsePointerAffine(B);
  return PA.Valid && PB.Valid && PA.Base && PA.Base == PB.Base &&
         PA.Coeff == 1 && PB.Coeff == 1 && PA.Offset == PB.Offset;
}

static std::optional<APInt> evalTransitionExpr(Value *V, Value *StatePointer,
                                               const APInt &EntryState,
                                               unsigned Depth = 0,
                                               const DenseMap<const Value *,
                                                              APInt> *Bindings =
                                                   nullptr) {
  if (Depth > 32) return std::nullopt;
  if (Bindings) {
    auto It = Bindings->find(V);
    if (It != Bindings->end()) return It->second;
  }
  if (auto *C = dyn_cast<ConstantInt>(V)) return C->getValue();
  if (auto *Arg = dyn_cast<Argument>(V)) {
    if (!Bindings) return std::nullopt;
    auto It = Bindings->find(Arg);
    return It == Bindings->end() ? std::nullopt
                                 : std::optional<APInt>(It->second);
  }
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    if (!LI->isAtomic() && !LI->isVolatile() &&
        sameFrameAddress(LI->getPointerOperand(), StatePointer))
      return EntryState;
    if (LI->isAtomic() || LI->isVolatile()) return std::nullopt;
    if (auto *GV = dyn_cast<GlobalVariable>(
            LI->getPointerOperand()->stripPointerCasts());
        GV && GV->isConstant() && GV->hasDefinitiveInitializer()) {
      auto *CI = dyn_cast<ConstantInt>(GV->getInitializer());
      if (CI && CI->getType() == LI->getType()) return CI->getValue();
    }
    // Model a second frame object only when its reaching definition is an
    // exact local store.  Intervening writes are crossed solely when their
    // identified byte ranges are proven disjoint; unknown aliasing remains a
    // hard symbolic-execution barrier.
    const DataLayout &DL = LI->getModule()->getDataLayout();
    IntAffine LoadAddress = parsePointerAffine(LI->getPointerOperand());
    TypeSize LoadSize = DL.getTypeStoreSize(LI->getType());
    if (!LoadAddress.Valid || !LoadAddress.Base || LoadAddress.Coeff != 1 ||
        LoadSize.isScalable())
      return std::nullopt;
    for (auto It = LI->getIterator(); It != LI->getParent()->begin();) {
      --It;
      auto *SI = dyn_cast<StoreInst>(&*It);
      if (!SI) {
        if (It->mayWriteToMemory()) return std::nullopt;
        continue;
      }
      if (SI->isAtomic() || SI->isVolatile()) return std::nullopt;
      TypeSize StoreSize = DL.getTypeStoreSize(
          SI->getValueOperand()->getType());
      if (sameFrameAddress(SI->getPointerOperand(), LI->getPointerOperand())) {
        if (StoreSize.isScalable() || StoreSize != LoadSize ||
            !SI->getValueOperand()->getType()->isIntegerTy() ||
            SI->getValueOperand()->getType() != LI->getType())
          return std::nullopt;
        return evalTransitionExpr(SI->getValueOperand(), StatePointer,
                                  EntryState, Depth + 1, Bindings);
      }
      IntAffine StoreAddress = parsePointerAffine(SI->getPointerOperand());
      if (!StoreAddress.Valid || !StoreAddress.Base ||
          StoreAddress.Coeff != 1 || StoreSize.isScalable())
        return std::nullopt;
      if (StoreAddress.Base != LoadAddress.Base) continue;
      uint64_t LoadBytes = LoadSize.getFixedValue();
      uint64_t StoreBytes = StoreSize.getFixedValue();
      if (LoadBytes > uint64_t(std::numeric_limits<int64_t>::max()) ||
          StoreBytes > uint64_t(std::numeric_limits<int64_t>::max()))
        return std::nullopt;
      int64_t LoadBegin = LoadAddress.Offset.getSExtValue();
      int64_t StoreBegin = StoreAddress.Offset.getSExtValue();
      if (LoadBegin > std::numeric_limits<int64_t>::max() -
                          int64_t(LoadBytes) ||
          StoreBegin > std::numeric_limits<int64_t>::max() -
                           int64_t(StoreBytes))
        return std::nullopt;
      int64_t LoadEnd = LoadBegin + int64_t(LoadBytes);
      int64_t StoreEnd = StoreBegin + int64_t(StoreBytes);
      if (StoreEnd <= LoadBegin || LoadEnd <= StoreBegin) continue;
      return std::nullopt;
    }
    // Continue through predecessor blocks with a bounded persistent-object
    // map.  A merge is accepted only when every incoming path reaches the
    // same exact APInt value; cycles, path-dependent values, and any unknown
    // aliasing write remain barriers.
    SmallPtrSet<BasicBlock *, 16> SeenBlocks;
    std::function<std::optional<APInt>(BasicBlock *, unsigned)> FindInBlock;
    FindInBlock = [&](BasicBlock *BB,
                      unsigned BlockDepth) -> std::optional<APInt> {
      if (!BB || BlockDepth > 12 || !SeenBlocks.insert(BB).second)
        return std::nullopt;
      for (auto It = BB->rbegin(), End = BB->rend(); It != End; ++It) {
        auto *SI = dyn_cast<StoreInst>(&*It);
        if (!SI) {
          if (It->mayWriteToMemory()) return std::nullopt;
          continue;
        }
        if (SI->isAtomic() || SI->isVolatile()) return std::nullopt;
        TypeSize StoreSize =
            DL.getTypeStoreSize(SI->getValueOperand()->getType());
        if (sameFrameAddress(SI->getPointerOperand(),
                             LI->getPointerOperand())) {
          if (StoreSize.isScalable() || StoreSize != LoadSize ||
              !SI->getValueOperand()->getType()->isIntegerTy() ||
              SI->getValueOperand()->getType() != LI->getType())
            return std::nullopt;
          return evalTransitionExpr(SI->getValueOperand(), StatePointer,
                                    EntryState, Depth + 1, Bindings);
        }
        IntAffine StoreAddress = parsePointerAffine(SI->getPointerOperand());
        if (!StoreAddress.Valid || !StoreAddress.Base ||
            StoreAddress.Coeff != 1 || StoreSize.isScalable())
          return std::nullopt;
        if (StoreAddress.Base != LoadAddress.Base) continue;
        uint64_t LoadBytes = LoadSize.getFixedValue();
        uint64_t StoreBytes = StoreSize.getFixedValue();
        if (LoadBytes > uint64_t(std::numeric_limits<int64_t>::max()) ||
            StoreBytes > uint64_t(std::numeric_limits<int64_t>::max()))
          return std::nullopt;
        int64_t LoadBegin = LoadAddress.Offset.getSExtValue();
        int64_t StoreBegin = StoreAddress.Offset.getSExtValue();
        if (LoadBegin > std::numeric_limits<int64_t>::max() -
                            int64_t(LoadBytes) ||
            StoreBegin > std::numeric_limits<int64_t>::max() -
                             int64_t(StoreBytes))
          return std::nullopt;
        int64_t LoadEnd = LoadBegin + int64_t(LoadBytes);
        int64_t StoreEnd = StoreBegin + int64_t(StoreBytes);
        if (StoreEnd <= LoadBegin || LoadEnd <= StoreBegin) continue;
        return std::nullopt;
      }
      std::optional<APInt> Common;
      unsigned PredCount = 0;
      for (BasicBlock *Pred : predecessors(BB)) {
        if (++PredCount > 8) return std::nullopt;
        auto Incoming = FindInBlock(Pred, BlockDepth + 1);
        if (!Incoming) return std::nullopt;
        if (Common && *Common != *Incoming) return std::nullopt;
        Common = std::move(Incoming);
      }
      return Common;
    };
    std::optional<APInt> Common;
    unsigned PredCount = 0;
    for (BasicBlock *Pred : predecessors(LI->getParent())) {
      if (++PredCount > 8) return std::nullopt;
      auto Incoming = FindInBlock(Pred, 0);
      if (!Incoming) return std::nullopt;
      if (Common && *Common != *Incoming) return std::nullopt;
      Common = std::move(Incoming);
    }
    return Common;
  }
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    Intrinsic::ID ID = II->getIntrinsicID();
    auto Op = evalTransitionExpr(II->getArgOperand(0), StatePointer,
                                 EntryState, Depth + 1, Bindings);
    if (!Op) return std::nullopt;
    if (ID == Intrinsic::bswap)
      return Op->getBitWidth() % 16 == 0
                 ? std::optional<APInt>(Op->byteSwap())
                 : std::nullopt;
    if (ID == Intrinsic::bitreverse) return Op->reverseBits();
    if (ID == Intrinsic::ctpop)
      return APInt(Op->getBitWidth(), Op->popcount());
    if ((ID == Intrinsic::fshl || ID == Intrinsic::fshr) &&
        II->getArgOperand(0) == II->getArgOperand(1)) {
      auto Amount = evalTransitionExpr(II->getArgOperand(2), StatePointer,
                                       EntryState, Depth + 1, Bindings);
      if (!Amount) return std::nullopt;
      unsigned Rotate = unsigned(Amount->urem(Op->getBitWidth()));
      return ID == Intrinsic::fshl ? Op->rotl(Rotate) : Op->rotr(Rotate);
    }
    return std::nullopt;
  }
  if (auto *CB = dyn_cast<CallBase>(V)) {
    Function *Callee = CB->getCalledFunction();
    if (!Callee || Callee->isDeclaration() || Callee->isVarArg() ||
        !Callee->getReturnType()->isIntegerTy() ||
        CB->arg_size() != Callee->arg_size() ||
        (!Callee->doesNotAccessMemory() && !Callee->onlyReadsMemory()) ||
        Callee->size() != 1)
      return std::nullopt;
    auto *RI = dyn_cast<ReturnInst>(Callee->front().getTerminator());
    if (!RI || !RI->getReturnValue()) return std::nullopt;
    DenseMap<const Value *, APInt> LocalBindings;
    unsigned ArgNo = 0;
    for (Argument &Formal : Callee->args()) {
      auto Actual = evalTransitionExpr(CB->getArgOperand(ArgNo++),
                                       StatePointer, EntryState, Depth + 1,
                                       Bindings);
      if (!Actual || !Formal.getType()->isIntegerTy() ||
          Actual->getBitWidth() != Formal.getType()->getIntegerBitWidth())
        return std::nullopt;
      LocalBindings.try_emplace(&Formal, *Actual);
    }
    return evalTransitionExpr(RI->getReturnValue(), StatePointer, EntryState,
                              Depth + 1, &LocalBindings);
  }
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (hasPoisonGeneratingFlags(BO)) return std::nullopt;
    auto L = evalTransitionExpr(BO->getOperand(0), StatePointer, EntryState,
                                Depth + 1, Bindings);
    auto R = evalTransitionExpr(BO->getOperand(1), StatePointer, EntryState,
                                Depth + 1, Bindings);
    if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
    switch (BO->getOpcode()) {
    case Instruction::Add: return *L + *R;
    case Instruction::Sub: return *L - *R;
    case Instruction::Mul: return *L * *R;
    case Instruction::And: return *L & *R;
    case Instruction::Or: return *L | *R;
    case Instruction::Xor: return *L ^ *R;
    case Instruction::Shl:
      if (R->uge(L->getBitWidth())) return std::nullopt;
      return L->shl(R->getZExtValue());
    case Instruction::LShr:
      if (R->uge(L->getBitWidth())) return std::nullopt;
      return L->lshr(R->getZExtValue());
    case Instruction::AShr:
      if (R->uge(L->getBitWidth())) return std::nullopt;
      return L->ashr(R->getZExtValue());
    default: return std::nullopt;
    }
  }
  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    auto L = evalTransitionExpr(Cmp->getOperand(0), StatePointer, EntryState,
                                Depth + 1, Bindings);
    auto R = evalTransitionExpr(Cmp->getOperand(1), StatePointer, EntryState,
                                Depth + 1, Bindings);
    if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
    return APInt(1, ICmpInst::compare(*L, *R, Cmp->getPredicate()));
  }
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    auto C = evalTransitionExpr(Sel->getCondition(), StatePointer, EntryState,
                                Depth + 1, Bindings);
    if (!C || C->getBitWidth() != 1) return std::nullopt;
    return evalTransitionExpr(C->isZero() ? Sel->getFalseValue()
                                          : Sel->getTrueValue(),
                              StatePointer, EntryState, Depth + 1, Bindings);
  }
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    if (!Cast->getType()->isIntegerTy() || !Cast->getSrcTy()->isIntegerTy())
      return std::nullopt;
    auto Op = evalTransitionExpr(Cast->getOperand(0), StatePointer, EntryState,
                                 Depth + 1, Bindings);
    if (!Op) return std::nullopt;
    unsigned Width = Cast->getType()->getIntegerBitWidth();
    switch (Cast->getOpcode()) {
    case Instruction::Trunc:
      if (cast<TruncInst>(Cast)->hasNoUnsignedWrap()) return std::nullopt;
      return Op->trunc(Width);
    case Instruction::ZExt: return Op->zext(Width);
    case Instruction::SExt: return Op->sext(Width);
    case Instruction::BitCast:
      if (Width == Op->getBitWidth()) return *Op;
      return std::nullopt;
    default: return std::nullopt;
    }
  }
  if (auto *Freeze = dyn_cast<FreezeInst>(V))
    return evalTransitionExpr(Freeze->getOperand(0), StatePointer, EntryState,
                              Depth + 1, Bindings);
  return std::nullopt;
}

static Value *findUnboundTransitionChoice(
    Value *V, const DenseMap<const Value *, APInt> &Bindings,
    SmallPtrSetImpl<Value *> &Seen, unsigned Depth = 0) {
  if (!V || Depth > 48 || Bindings.count(V) || isa<Constant>(V) ||
      isa<Argument>(V) || !Seen.insert(V).second)
    return nullptr;
  if ((isa<SelectInst>(V) || isa<PHINode>(V)) &&
      V->getType()->isIntegerTy())
    return V;
  auto *U = dyn_cast<User>(V);
  if (!U) return nullptr;
  for (Value *Op : U->operands())
    if (Value *Choice =
            findUnboundTransitionChoice(Op, Bindings, Seen, Depth + 1))
      return Choice;
  return nullptr;
}

static bool appendUniqueTransitionValue(SmallVectorImpl<APInt> &Values,
                                        const APInt &Value,
                                        unsigned Limit = 32) {
  if (llvm::is_contained(Values, Value)) return true;
  if (Values.size() >= Limit) return false;
  Values.push_back(Value);
  return true;
}

// Bounded acyclic executor for transition expressions containing nested
// select/PHI forks.  It enumerates every structurally possible arm, binds the
// chosen PHI/select value, then reuses the exact APInt evaluator for the whole
// expression.  Cyclic choices, unsupported operations, and outcome explosion
// fail closed.
static bool enumerateTransitionValues(
    Value *Root, Value *StatePointer, const APInt &EntryState,
    const DenseMap<const Value *, APInt> &Bindings,
    SmallVectorImpl<APInt> &Values, unsigned &Budget, unsigned Depth = 0,
    SmallPtrSetImpl<Value *> *ActiveChoices = nullptr) {
  if (Depth > 32 || Budget == 0) return false;
  --Budget;
  if (auto Constant = evalTransitionExpr(Root, StatePointer, EntryState, 0,
                                         &Bindings))
    return appendUniqueTransitionValue(Values, *Constant);

  SmallPtrSet<Value *, 32> Seen;
  Value *Choice = findUnboundTransitionChoice(Root, Bindings, Seen);
  if (!Choice) return false;
  SmallPtrSet<Value *, 8> LocalActive;
  if (!ActiveChoices) ActiveChoices = &LocalActive;
  if (!ActiveChoices->insert(Choice).second) return false;

  SmallVector<Value *, 8> Arms;
  if (auto *Sel = dyn_cast<SelectInst>(Choice)) {
    Arms.push_back(Sel->getTrueValue());
    Arms.push_back(Sel->getFalseValue());
  } else {
    auto *Phi = cast<PHINode>(Choice);
    if (Phi->getNumIncomingValues() < 2 ||
        Phi->getNumIncomingValues() > 16) {
      ActiveChoices->erase(Choice);
      return false;
    }
    for (Value *Incoming : Phi->incoming_values()) Arms.push_back(Incoming);
  }

  bool Complete = true;
  for (Value *Arm : Arms) {
    SmallVector<APInt, 8> ArmValues;
    if (!enumerateTransitionValues(Arm, StatePointer, EntryState, Bindings,
                                   ArmValues, Budget, Depth + 1,
                                   ActiveChoices) ||
        ArmValues.empty()) {
      Complete = false;
      break;
    }
    for (const APInt &ArmValue : ArmValues) {
      if (!Choice->getType()->isIntegerTy(ArmValue.getBitWidth())) {
        Complete = false;
        break;
      }
      DenseMap<const Value *, APInt> Extended(Bindings);
      Extended[Choice] = ArmValue;
      if (!enumerateTransitionValues(Root, StatePointer, EntryState, Extended,
                                     Values, Budget, Depth + 1,
                                     ActiveChoices)) {
        Complete = false;
        break;
      }
    }
    if (!Complete) break;
  }
  ActiveChoices->erase(Choice);
  return Complete;
}

static bool proveFiniteTransitionSetSMT(Value *Root,
                                        ArrayRef<APInt> Values,
                                        std::string &Certificate) {
  if (!Root || !Root->getType()->isIntegerTy() || Values.empty()) return false;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto Expr = Translator.translate(Root);
    if (!Expr || !Expr->is_bv() ||
        Expr->get_sort().bv_size() !=
            Root->getType()->getIntegerBitWidth())
      return false;
    z3::expr Outside = Ctx.bool_val(true);
    raw_string_ostream OS(Certificate);
    OS << valueText(*Root) << "\nnot-in{";
    for (unsigned I = 0; I != Values.size(); ++I) {
      if (Values[I].getBitWidth() !=
          Root->getType()->getIntegerBitWidth())
        return false;
      SmallString<80> Text;
      Values[I].toString(Text, 10, false);
      z3::expr Constant = Ctx.bv_val(
          Text.c_str(), Root->getType()->getIntegerBitWidth());
      Outside = Outside && (*Expr != Constant);
      if (I) OS << ',';
      OS << Text;
    }
    OS << "}\n" << Translator.getSliceCertificate();
    OS.flush();
    z3::params Params(Ctx);
    Params.set("timeout", 1500u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(Outside);
    return Solver.check() == z3::unsat;
  } catch (const z3::exception &) {
    return false;
  }
}

static ConstantInt *findLocalReachingConstant(LoadInst &LI,
                                               BasicBlock *Source) {
  if (LI.getParent() != Source) return nullptr;
  for (auto It = LI.getIterator(); It != Source->begin();) {
    --It;
    if (auto *SI = dyn_cast<StoreInst>(&*It)) {
      if (sameFrameAddress(SI->getPointerOperand(), LI.getPointerOperand()))
        return dyn_cast<ConstantInt>(SI->getValueOperand());
      continue;
    }
    if (It->mayWriteToMemory())
      return nullptr;
  }
  return nullptr;
}

static ConstantInt *asTransitionConstant(Value *V, BasicBlock *Source) {
  if (auto *C = dyn_cast<ConstantInt>(V)) return C;
  if (auto *LI = dyn_cast<LoadInst>(V))
    return findLocalReachingConstant(*LI, Source);
  return nullptr;
}

struct PlumbingStage {
  BasicBlock *Block = nullptr;
  PHINode *StatePhi = nullptr;
  Value *EdgeValue = nullptr;
};

struct FunnelEdge {
  BasicBlock *Source = nullptr;
  Value *RawState = nullptr;
  Value *Condition = nullptr;
  BasicBlock *TrueTarget = nullptr;
  BasicBlock *FalseTarget = nullptr;
  SmallVector<PlumbingStage, 4> Stages;
};

static bool validatePlumbingStage(const PlumbingStage &Stage) {
  for (Instruction &I : *Stage.Block) {
    if (isa<PHINode>(I) || I.isTerminator() || isa<DbgInfoIntrinsic>(I))
      continue;
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || SI->isAtomic() || SI->isVolatile()) return false;
    for (Value *Op : SI->operands())
      if (auto *OI = dyn_cast<Instruction>(Op);
          OI && OI->getParent() == Stage.Block && OI != Stage.StatePhi)
        return false;
  }
  return true;
}

static void clonePlumbingStage(const PlumbingStage &Stage,
                               Instruction *InsertBefore) {
  for (Instruction &I : *Stage.Block) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI) continue;
    Value *Stored = SI->getValueOperand();
    if (Stored == Stage.StatePhi) Stored = Stage.EdgeValue;
    IRBuilder<> B(InsertBefore);
    StoreInst *Clone = B.CreateStore(Stored, SI->getPointerOperand());
    Clone->setAlignment(SI->getAlign());
    Clone->copyMetadata(*SI);
  }
}

static bool tryRecoverFunnelDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() == Header ||
      !SI.getDefaultDest()->hasNPredecessors(2))
    return false;
  // The default must be the header's self-loop, not a semantic default path.
  if (SI.getDefaultDest() != Header) return false;
  BasicBlock *Outer = State->getParent();
  auto *OuterBr = dyn_cast<BranchInst>(Outer->getTerminator());
  if (!OuterBr || !OuterBr->isUnconditional() ||
      OuterBr->getSuccessor(0) != Header)
    return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  for (auto Case : SI.cases()) {
    BasicBlock *Target = Case.getCaseSuccessor();
    CaseMap[Case.getCaseValue()->getValue()] = Target;
  }
  if (CaseMap.size() < 4) return false;

  SmallVector<FunnelEdge, 16> Edges;
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    Value *Incoming = State->getIncomingValue(I);
    BasicBlock *Pred = State->getIncomingBlock(I);
    if (auto *SinkPhi = dyn_cast<PHINode>(Incoming)) {
      BasicBlock *Sink = SinkPhi->getParent();
      auto *SinkBr = dyn_cast<BranchInst>(Sink->getTerminator());
      if (SinkBr && SinkBr->isUnconditional() &&
          SinkBr->getSuccessor(0) == Outer) {
        for (unsigned J = 0; J != SinkPhi->getNumIncomingValues(); ++J) {
          BasicBlock *Source = SinkPhi->getIncomingBlock(J);
          if (Source == Header) continue; // handled as a case-table chain below
          auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
          if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Sink)
            return false;
          FunnelEdge E;
          E.Source = Source;
          E.RawState = SinkPhi->getIncomingValue(J);
          E.Stages.push_back({Sink, SinkPhi, E.RawState});
          E.Stages.push_back({Outer, State, E.RawState});
          Edges.push_back(std::move(E));
        }
        continue;
      }
    }
    auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Outer)
      return false;
    FunnelEdge E;
    E.Source = Pred;
    E.RawState = Incoming;
    E.Stages.push_back({Outer, State, Incoming});
    Edges.push_back(std::move(E));
  }
  if (Edges.empty()) return false;

  auto ResolveConstant = [&](ConstantInt *Raw, FunnelEdge &E) -> BasicBlock * {
    SmallPtrSet<BasicBlock *, 4> Seen;
    for (unsigned Depth = 0; Depth != 8; ++Depth) {
      auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
      if (!Encoded) return nullptr;
      auto It = CaseMap.find(*Encoded);
      if (It == CaseMap.end()) return nullptr;
      BasicBlock *Target = It->second;
      if (!Seen.insert(Target).second) return nullptr;
      // A case may deliberately route back through the state sink.  Resolve
      // its header-specific PHI input and preserve both state stores.
      PHINode *SinkPhi = nullptr;
      for (Instruction &I : *Target) {
        auto *PN = dyn_cast<PHINode>(&I);
        if (!PN) break;
        if (PN->getBasicBlockIndex(Header) >= 0) { SinkPhi = PN; break; }
      }
      auto *TargetBr = dyn_cast<BranchInst>(Target->getTerminator());
      if (!SinkPhi || !TargetBr || !TargetBr->isUnconditional() ||
          TargetBr->getSuccessor(0) != Outer) {
        if (Target->phis().begin() != Target->phis().end()) return nullptr;
        return Target;
      }
      auto *Next = dyn_cast<ConstantInt>(
          SinkPhi->getIncomingValueForBlock(Header));
      if (!Next) return nullptr;
      E.Stages.push_back({Target, SinkPhi, Next});
      E.Stages.push_back({Outer, State, Next});
      Raw = Next;
    }
    return nullptr;
  };

  for (FunnelEdge &E : Edges) {
    for (const PlumbingStage &Stage : E.Stages)
      if (!validatePlumbingStage(Stage)) return false;
    if (auto *Sel = dyn_cast<SelectInst>(E.RawState)) {
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return false;
      FunnelEdge TrueProbe = E, FalseProbe = E;
      E.TrueTarget = ResolveConstant(TC, TrueProbe);
      E.FalseTarget = ResolveConstant(FC, FalseProbe);
      // Branch-dependent extra state plumbing cannot be hoisted safely.
      if (TrueProbe.Stages.size() != E.Stages.size() ||
          FalseProbe.Stages.size() != E.Stages.size())
        return false;
      E.Condition = Sel->getCondition();
    } else {
      ConstantInt *C = asTransitionConstant(E.RawState, E.Source);
      if (!C) return false;
      E.TrueTarget = ResolveConstant(C, E);
    }
    if (!E.TrueTarget || (E.Condition && !E.FalseTarget)) return false;
    for (const PlumbingStage &Stage : E.Stages)
      if (!validatePlumbingStage(Stage)) return false;
  }

  std::string FunctionName = Header->getParent()->getName().str();
  std::string HeaderName = Header->getName().str();
  Function *F = Header->getParent();
  for (FunnelEdge &E : Edges) {
    Instruction *Old = E.Source->getTerminator();
    for (const PlumbingStage &Stage : E.Stages)
      clonePlumbingStage(Stage, Old);
    if (E.Condition)
      BranchInst::Create(E.TrueTarget, E.FalseTarget, E.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(E.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    Proofs.push_back({FunctionName, "cff_transition",
                      E.Source->getName().str(), "funnel_transition_set",
                      "proved"});
  }
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  Proofs.push_back({FunctionName, "cff_dispatcher", HeaderName,
                    "complete_funnel_transition_set", "proved"});
  return true;
}

static void cloneBlockPlumbing(ArrayRef<Instruction *> Body,
                               Instruction *InsertBefore,
                               DenseMap<const Value *, Value *> &Map) {
  for (Instruction *I : Body) {
    Instruction *Clone = I->clone();
    for (unsigned O = 0; O != Clone->getNumOperands(); ++O) {
      auto It = Map.find(Clone->getOperand(O));
      if (It != Map.end()) Clone->setOperand(O, It->second);
    }
    if (!Clone->getType()->isVoidTy())
      Clone->setName(I->getName() + ".deobf.plumbing");
    Clone->insertBefore(InsertBefore->getIterator());
    Map[I] = Clone;
  }
}

// Recover a dispatcher whose state is already one PHI input per returning
// case.  A self-looping default is removable only by an exhaustive induction:
// at least one non-header seed reaches a returning source, every non-default
// incoming state resolves to a real case, and the default has no predecessor
// other than the dispatcher.  Thus the default is unreachable at the base and
// remains unreachable after every proved transition.
static bool tryRecoverMultiIncomingSSADispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *F = Header->getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header ||
      State->getNumIncomingValues() < 3)
    return false;

  BasicBlock *Default = SI.getDefaultDest();
  auto *DefaultBr = dyn_cast<BranchInst>(Default->getTerminator());
  if (!Default->hasNPredecessors(1) ||
      *pred_begin(Default) != Header || !DefaultBr ||
      !DefaultBr->isUnconditional() || DefaultBr->getSuccessor(0) != Header ||
      State->getBasicBlockIndex(Default) < 0)
    return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  for (auto Case : SI.cases()) {
    BasicBlock *Target = Case.getCaseSuccessor();
    if (Target == Default || Target == Header || !Target->phis().empty())
      return false;
    CaseMap[Case.getCaseValue()->getValue()] = Target;
  }
  if (CaseMap.size() < 4) return false;

  for (PHINode &PN : Header->phis())
    for (User *U : PN.users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || UI->getParent() != Header) return false;
    }
  SmallVector<Instruction *, 16> HeaderBody;
  for (Instruction &I : *Header)
    if (!isa<PHINode>(I) && !I.isTerminator() && !isa<DbgInfoIntrinsic>(I)) {
      for (User *U : I.users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || UI->getParent() != Header) return false;
      }
      HeaderBody.push_back(&I);
    }

  auto Resolve = [&](ConstantInt *Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    return It == CaseMap.end() ? nullptr : It->second;
  };

  SmallVector<ProvenTransition, 32> Transitions;
  bool HasExternalSeed = false;
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    BasicBlock *Pred = State->getIncomingBlock(I);
    if (Pred == Default) continue;
    auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Header)
      return false;
    for (BasicBlock *PredPred : predecessors(Pred))
      if (PredPred != Header &&
          !isPotentiallyReachable(Header, PredPred))
        HasExternalSeed = true;

    Value *Raw = State->getIncomingValue(I);
    ProvenTransition T;
    T.Source = Pred;
    if (auto *C = asTransitionConstant(Raw, Pred)) {
      T.TrueTarget = Resolve(C);
    } else if (auto *Sel = dyn_cast<SelectInst>(Raw)) {
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return false;
      T.Condition = Sel->getCondition();
      T.TrueTarget = Resolve(TC);
      T.FalseTarget = Resolve(FC);
    } else {
      return false;
    }
    if (!T.TrueTarget || (T.Condition && !T.FalseTarget)) return false;
    Transitions.push_back(T);
  }
  if (!HasExternalSeed || Transitions.empty()) return false;
  for (const ProvenTransition &T : Transitions)
    for (PHINode &PN : Header->phis())
      if (PN.getBasicBlockIndex(T.Source) < 0) return false;

  std::string OldFunctionText = valueText(*F);
  std::string HeaderName = Header->getName().str();
  std::string Certificate;
  raw_string_ostream CertificateOS(Certificate);
  CertificateOS << "default:" << valueName(*Default)
                << ":header-only-self-loop\n";
  for (const ProvenTransition &T : Transitions) {
    CertificateOS << valueName(*T.Source) << "->"
                  << valueName(*T.TrueTarget);
    if (T.FalseTarget) CertificateOS << ',' << valueName(*T.FalseTarget);
    CertificateOS << '\n';
  }
  CertificateOS.flush();

  std::string FunctionName = F->getName().str();
  for (const ProvenTransition &T : Transitions) {
    Instruction *Old = T.Source->getTerminator();
    std::string OldText = valueText(*Old);
    DenseMap<const Value *, Value *> Map;
    for (PHINode &PN : Header->phis()) {
      int Index = PN.getBasicBlockIndex(T.Source);
      assert(Index >= 0 && "preflighted header PHI input disappeared");
      Map[&PN] = PN.getIncomingValue(Index);
    }
    cloneBlockPlumbing(HeaderBody, Old, Map);
    if (T.Condition)
      BranchInst::Create(T.TrueTarget, T.FalseTarget, T.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(T.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    ProofRecord Edge{FunctionName, "cff_transition", valueName(*T.Source),
                     "multi_incoming_ssa_default_induction", "proved"};
    Edge.OldHash = hashText(OldText);
    Edge.NewHash = hashText(valueText(*T.Source->getTerminator()));
    Edge.ProofQueryHash = hashText(Certificate);
    Edge.Dependencies.push_back("exhaustive_known_state_induction");
    Edge.Dependencies.push_back("exact_header_plumbing_clone");
    Proofs.push_back(std::move(Edge));
  }
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{FunctionName, "cff_dispatcher", HeaderName,
                     "multi_incoming_ssa_default_induction", "proved"};
  Record.OldHash = hashText(OldFunctionText);
  Record.NewHash = hashText(valueText(*F));
  Record.ProofQueryHash = hashText(Certificate);
  Record.Dependencies.push_back("external_seed_exists");
  Record.Dependencies.push_back("exhaustive_known_state_induction");
  Record.Dependencies.push_back("default_only_header_predecessor");
  Record.Dependencies.push_back("exact_header_plumbing_clone");
  Proofs.push_back(std::move(Record));
  return true;
}

// Recover an SSA dispatcher whose header carries additional loop variables.
// The non-dispatch PHIs are semantic state, so bypassing the header directly
// would freeze their first-iteration values.  Lower the header/latch PHIs to
// private stack slots, then clone the exact latch+header plumbing on every
// proved edge.  This is an SSA-preserving form of the P24 update step and does
// not infer or discard any side effect.
static StoreInst *findReachingStateStore(BasicBlock *Source,
                                         Value *StatePointer,
                                         unsigned Depth = 0,
                                         bool *HitBarrier = nullptr);

static bool tryRecoverSSAPlumbingDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *F = Header->getParent();
  auto Reject = [](StringRef) { return false; };
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header ||
      State->getNumIncomingValues() != 2)
    return Reject("state-root");
  // Keep the compact direct-SSA rewrite for the single-state-PHI shape.
  if (std::next(Header->phis().begin()) == Header->phis().end())
    return Reject("single-header-phi");

  PHINode *LatchState = nullptr;
  LoadInst *LatchStateLoad = nullptr;
  ConstantInt *Initial = nullptr;
  BasicBlock *EntryPred = nullptr, *Latch = nullptr;
  for (unsigned I = 0; I != 2; ++I) {
    Value *V = State->getIncomingValue(I);
    if (auto *C = dyn_cast<ConstantInt>(V)) {
      Initial = C;
      EntryPred = State->getIncomingBlock(I);
    } else if (auto *PN = dyn_cast<PHINode>(V)) {
      LatchState = PN;
      Latch = State->getIncomingBlock(I);
    } else if (auto *LI = dyn_cast<LoadInst>(V)) {
      LatchStateLoad = LI;
      Latch = State->getIncomingBlock(I);
    }
  }
  // Late pointer canonicalization can expose a complete memory recurrence
  // only after the broad State-SSA sweep has run. Promote that exact join load
  // to a latch PHI. The dispatcher default edge carries the current state;
  // every other predecessor must have one exact reaching store.
  if (Initial && !LatchState && LatchStateLoad && Latch &&
      LatchStateLoad->getParent() == Latch &&
      !LatchStateLoad->isAtomic() && !LatchStateLoad->isVolatile()) {
    bool Safe = true;
    for (Instruction &I : *Latch) {
      if (&I == LatchStateLoad) break;
      if (!isa<PHINode>(I) && !isa<DbgInfoIntrinsic>(I) &&
          I.mayWriteToMemory()) {
        Safe = false;
        break;
      }
    }
    SmallVector<std::pair<Value *, BasicBlock *>, 64> Incoming;
    for (BasicBlock *Pred : predecessors(Latch)) {
      unsigned EdgeCount = 0;
      for (BasicBlock *Succ : successors(Pred)) EdgeCount += Succ == Latch;
      if (EdgeCount != 1) {
        Safe = false;
        break;
      }
      bool HitBarrier = false;
      StoreInst *Store = findReachingStateStore(
          Pred, LatchStateLoad->getPointerOperand(), 0, &HitBarrier);
      if (Pred == Header && !Store && !HitBarrier) {
        Incoming.push_back({State, Pred});
        continue;
      }
      if (!Store || HitBarrier || Store->isAtomic() || Store->isVolatile() ||
          Store->getValueOperand()->getType() != LatchStateLoad->getType() ||
          !sameFrameAddress(Store->getPointerOperand(),
                            LatchStateLoad->getPointerOperand())) {
        Safe = false;
        break;
      }
      Incoming.push_back({Store->getValueOperand(), Pred});
    }
    if (Safe && Incoming.size() == pred_size(Latch)) {
      LatchState = PHINode::Create(
          LatchStateLoad->getType(), Incoming.size(),
          "deobf.memory.latch.state", LatchStateLoad->getIterator());
      for (const auto &[IncomingValue, Pred] : Incoming)
        LatchState->addIncoming(IncomingValue, Pred);
      LatchStateLoad->replaceAllUsesWith(LatchState);
      LatchStateLoad->eraseFromParent();
      ++M.MemorySSAPhisResolved;
      ProofRecord Promotion{F->getName().str(), "cff_state_promotion",
                            Header->getName().str(),
                            "exact_memory_join_to_latch_phi", "proved"};
      Promotion.Dependencies.push_back("complete_predecessor_coverage");
      Promotion.Dependencies.push_back("exact_reaching_state_stores");
      Promotion.Dependencies.push_back("default_self_edge_state_passthrough");
      Proofs.push_back(std::move(Promotion));
    }
  }
  if (!Initial || !LatchState || LatchState->getParent() != Latch ||
      !Header->hasNPredecessors(2))
    return Reject("entry-latch-shape");
  auto *EntryBr = dyn_cast<BranchInst>(EntryPred->getTerminator());
  auto *LatchBr = dyn_cast<BranchInst>(Latch->getTerminator());
  if (!EntryBr || !EntryBr->isUnconditional() ||
      EntryBr->getSuccessor(0) != Header || !LatchBr ||
      !LatchBr->isUnconditional() || LatchBr->getSuccessor(0) != Header)
    return Reject("entry-latch-branches");

  SmallVector<PHINode *, 8> HeaderPhis;
  SmallVector<PHINode *, 8> LatchPhis;
  for (PHINode &HP : Header->phis()) {
    if (HP.getNumIncomingValues() != 2 ||
        HP.getBasicBlockIndex(EntryPred) < 0 ||
        HP.getBasicBlockIndex(Latch) < 0)
      return Reject("header-phi-shape");
    auto *LP = dyn_cast<PHINode>(HP.getIncomingValueForBlock(Latch));
    if (!LP || LP->getParent() != Latch) return Reject("latch-phi-pair");
    HeaderPhis.push_back(&HP);
    LatchPhis.push_back(LP);
  }
  llvm::sort(LatchPhis);
  LatchPhis.erase(std::unique(LatchPhis.begin(), LatchPhis.end()),
                   LatchPhis.end());
  for (PHINode &LP : Latch->phis())
    if (!llvm::is_contained(LatchPhis, &LP))
      return Reject("unpaired-latch-phi");

  DenseMap<APInt, BasicBlock *> CaseMap;
  SmallPtrSet<BasicBlock *, 32> CaseEntries;
  for (auto Case : SI.cases()) {
    BasicBlock *Target = Case.getCaseSuccessor();
    if (!Target->phis().empty()) return Reject("case-phi");
    CaseMap[Case.getCaseValue()->getValue()] = Target;
    CaseEntries.insert(Target);
  }
  if (CaseMap.size() < 4) return Reject("case-map");

  // A case may contain internal branches (for example a checked libc call)
  // before reaching the latch.  Classify each latch predecessor by walking
  // backward to one unique switch case entry.  The default predecessor has no
  // such root and is intentionally excluded.
  SmallVector<BasicBlock *, 32> ReturningCases;
  SmallPtrSet<BasicBlock *, 32> ReturningRoots;
  for (BasicBlock *Source : predecessors(Latch)) {
    SmallVector<BasicBlock *, 16> Work{Source};
    SmallPtrSet<BasicBlock *, 32> Seen;
    BasicBlock *Root = nullptr;
    while (!Work.empty() && Seen.size() <= 64) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (CaseEntries.contains(BB)) {
        if (Root && Root != BB) return Reject("ambiguous-case-root");
        Root = BB;
        continue;
      }
      if (BB == Header || BB == Latch) continue;
      for (BasicBlock *Pred : predecessors(BB)) Work.push_back(Pred);
    }
    if (!Root) continue;
    ReturningCases.push_back(Source);
    ReturningRoots.insert(Root);
  }
  if (ReturningCases.empty()) return Reject("no-returning-cases");
  // Whole-function reachability is too broad here: a genuine nested-CFF exit
  // can reach this header again only after returning to an outer dispatcher
  // and starting a later invocation.  It is a returning case for this loop
  // only when it reaches the latch without first crossing the header.
  auto ReachesLatchLocally = [&](BasicBlock *Start) -> std::optional<bool> {
    SmallVector<BasicBlock *, 32> Work{Start};
    SmallPtrSet<BasicBlock *, 32> Seen;
    while (!Work.empty()) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (Seen.size() > 256) return std::nullopt;
      for (BasicBlock *Succ : successors(BB)) {
        if (Succ == Latch) return true;
        if (Succ != Header) Work.push_back(Succ);
      }
    }
    return false;
  };
  for (BasicBlock *CaseEntry : CaseEntries) {
    if (ReturningRoots.contains(CaseEntry)) continue;
    std::optional<bool> Reaches = ReachesLatchLocally(CaseEntry);
    if (!Reaches || *Reaches) return Reject("unclassified-returning-case");
  }
  for (PHINode *LP : LatchPhis)
    for (BasicBlock *CaseBB : ReturningCases)
      if (LP->getBasicBlockIndex(CaseBB) < 0) return Reject("latch-input");

  auto Resolve = [&](ConstantInt *Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    return It == CaseMap.end() ? nullptr : It->second;
  };
  BasicBlock *InitialTarget = Resolve(Initial);
  if (!InitialTarget) return Reject("initial-target");

  SmallVector<ProvenTransition, 32> Transitions;
  for (BasicBlock *CaseBB : ReturningCases) {
    int Index = LatchState->getBasicBlockIndex(CaseBB);
    if (Index < 0) return Reject("state-latch-input");
    Value *Next = LatchState->getIncomingValue(Index);
    ProvenTransition T;
    T.Source = CaseBB;
    if (auto *C = dyn_cast<ConstantInt>(Next)) {
      T.TrueTarget = Resolve(C);
    } else if (auto *Sel = dyn_cast<SelectInst>(Next)) {
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return Reject("nonconstant-select");
      T.Condition = Sel->getCondition();
      T.TrueTarget = Resolve(TC);
      T.FalseTarget = Resolve(FC);
    } else {
      return Reject("nonconstant-transition");
    }
    if (!T.TrueTarget || (T.Condition && !T.FalseTarget))
      return Reject("unresolved-target");
    Transitions.push_back(T);
  }

  std::string OldFunctionText = valueText(*F);
  std::string TransitionCertificate;
  raw_string_ostream CertificateOS(TransitionCertificate);
  CertificateOS << "entry:" << Initial->getValue() << "->"
                << valueName(*InitialTarget) << '\n';
  for (const ProvenTransition &T : Transitions) {
    CertificateOS << valueName(*T.Source) << "->"
                  << valueName(*T.TrueTarget);
    if (T.FalseTarget) CertificateOS << "," << valueName(*T.FalseTarget);
    CertificateOS << '\n';
  }
  CertificateOS.flush();

  // All structural and transition checks completed.  From this point every
  // mutation is an exact LLVM utility lowering or a clone of executed IR.
  Instruction *AllocaPoint = &*F->getEntryBlock().getFirstInsertionPt();
  for (PHINode *LP : LatchPhis)
    DemotePHIToStack(LP, AllocaPoint->getIterator());
  for (PHINode *HP : HeaderPhis)
    DemotePHIToStack(HP, AllocaPoint->getIterator());

  SmallVector<Instruction *, 16> HeaderBeforeDemotion;
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBeforeDemotion.push_back(&I);
  for (Instruction *I : HeaderBeforeDemotion) {
    if (I->getType()->isVoidTy() || I->use_empty()) continue;
    bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
      auto *UI = dyn_cast<Instruction>(U);
      return UI && UI->getParent() != Header;
    });
    if (UsedOutside)
      DemoteRegToStack(*I, false, AllocaPoint->getIterator());
  }

  SmallVector<Instruction *, 32> LatchBody, HeaderBody;
  for (Instruction &I : *Latch)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      LatchBody.push_back(&I);
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBody.push_back(&I);

  {
    Instruction *Old = EntryPred->getTerminator();
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(HeaderBody, Old, Map);
    BranchInst::Create(InitialTarget, Old->getIterator());
    Old->eraseFromParent();
  }
  std::string FunctionName = F->getName().str();
  std::string HeaderName = Header->getName().str();
  for (const ProvenTransition &T : Transitions) {
    Instruction *Old = T.Source->getTerminator();
    std::string OldTerminatorText = valueText(*Old);
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(LatchBody, Old, Map);
    cloneBlockPlumbing(HeaderBody, Old, Map);
    if (T.Condition)
      BranchInst::Create(T.TrueTarget, T.FalseTarget, T.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(T.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    Instruction *NewTerminator = T.Source->getTerminator();
    ProofRecord TransitionRecord{
        FunctionName, "cff_transition", valueName(*T.Source),
        "ssa_phi_demotion_exact_plumbing", "proved"};
    TransitionRecord.OldHash = hashText(OldTerminatorText);
    TransitionRecord.NewHash = hashText(valueText(*NewTerminator));
    TransitionRecord.ProofQueryHash = hashText(TransitionCertificate);
    TransitionRecord.Dependencies.push_back("llvm_phi_demotion");
    TransitionRecord.Dependencies.push_back("exact_latch_header_clone");
    Proofs.push_back(std::move(TransitionRecord));
  }
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{FunctionName, "cff_dispatcher", HeaderName,
                     "complete_ssa_transition_and_plumbing_set", "proved"};
  Record.OldHash = hashText(OldFunctionText);
  Record.NewHash = hashText(valueText(*F));
  Record.ProofQueryHash = hashText(TransitionCertificate);
  Record.Dependencies.push_back("llvm_phi_demotion");
  Record.Dependencies.push_back("exact_latch_header_clone");
  Proofs.push_back(std::move(Record));
  return true;
}

// Conservative SSA-CFF recovery.  It commits only when the initial state and
// every case transition are constants (or a select of constants), all encoded
// targets exist in the case table, and case entries need no dispatcher PHIs.
static bool tryRecoverSSADispatcher(SwitchInst &SI, Metrics &M,
                                    SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *ParentFunction = Header->getParent();
  std::string FunctionName = ParentFunction->getName().str();
  std::string HeaderName = Header->getName().str();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header || State->getNumIncomingValues() != 2)
    return false;

  PHINode *LatchState = nullptr;
  ConstantInt *Initial = nullptr;
  BasicBlock *EntryPred = nullptr, *Latch = nullptr;
  for (unsigned I = 0; I != 2; ++I) {
    Value *V = State->getIncomingValue(I);
    if (auto *C = dyn_cast<ConstantInt>(V)) {
      Initial = C;
      EntryPred = State->getIncomingBlock(I);
    } else if (auto *PN = dyn_cast<PHINode>(V)) {
      LatchState = PN;
      Latch = State->getIncomingBlock(I);
    }
  }
  if (!Initial || !LatchState || LatchState->getParent() != Latch)
    return false;
  auto *LatchBr = dyn_cast<BranchInst>(Latch->getTerminator());
  if (!LatchBr || !LatchBr->isUnconditional() ||
      LatchBr->getSuccessor(0) != Header)
    return false;

  SmallVector<BasicBlock *, 16> CaseBlocks;
  DenseMap<APInt, BasicBlock *> CaseMap;
  for (auto Case : SI.cases()) {
    BasicBlock *BB = Case.getCaseSuccessor();
    if (BB->phis().begin() != BB->phis().end()) return false;
    auto *Br = dyn_cast<BranchInst>(BB->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Latch)
      return false;
    CaseMap[Case.getCaseValue()->getValue()] = BB;
    CaseBlocks.push_back(BB);
  }
  if (CaseBlocks.size() < 4 || LatchState->getNumIncomingValues() != CaseBlocks.size())
    return false;
  // Default ladders require the symbolic resolver and are deliberately not
  // guessed by this MVP.  It must be reachable only from this switch.
  BasicBlock *Default = SI.getDefaultDest();
  if (!Default->hasNPredecessors(1)) return false;

  auto Resolve = [&](ConstantInt *Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    return It == CaseMap.end() ? nullptr : It->second;
  };
  BasicBlock *InitialTarget = Resolve(Initial);
  if (!InitialTarget) return false;

  SmallVector<ProvenTransition, 16> Transitions;
  for (BasicBlock *CaseBB : CaseBlocks) {
    int Index = LatchState->getBasicBlockIndex(CaseBB);
    if (Index < 0) return false;
    Value *Next = LatchState->getIncomingValue(Index);
    ProvenTransition T;
    T.Source = CaseBB;
    if (auto *C = dyn_cast<ConstantInt>(Next)) {
      T.TrueTarget = Resolve(C);
    } else if (auto *Sel = dyn_cast<SelectInst>(Next)) {
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return false;
      T.Condition = Sel->getCondition();
      T.TrueTarget = Resolve(TC);
      T.FalseTarget = Resolve(FC);
    } else {
      return false;
    }
    if (!T.TrueTarget || (T.Condition && !T.FalseTarget)) return false;
    Transitions.push_back(T);
  }

  auto *EntryTerm = EntryPred->getTerminator();
  bool FoundHeaderEdge = false;
  for (unsigned I = 0; I != EntryTerm->getNumSuccessors(); ++I)
    if (EntryTerm->getSuccessor(I) == Header) {
      EntryTerm->setSuccessor(I, InitialTarget);
      FoundHeaderEdge = true;
    }
  if (!FoundHeaderEdge) return false;
  for (const ProvenTransition &T : Transitions) {
    Instruction *Old = T.Source->getTerminator();
    if (T.Condition)
      BranchInst::Create(T.TrueTarget, T.FalseTarget, T.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(T.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    Proofs.push_back({FunctionName, "cff_transition",
                      T.Source->getName().str(), "ssa_constant_transition",
                      "proved"});
  }
  removeUnreachableBlocks(*ParentFunction);
  ++M.DispatchersRecovered;
  Proofs.push_back({FunctionName, "cff_dispatcher", HeaderName,
                    "complete_transition_set",
                    "proved"});
  return true;
}

static bool canCloneHeaderPlumbing(BasicBlock *Header, PHINode *State) {
  SmallPtrSet<const Value *, 16> Available;
  Available.insert(State);
  for (Instruction &I : *Header) {
    if (&I == State || isa<DbgInfoIntrinsic>(I)) continue;
    if (isa<PHINode>(I)) return false;
    if (I.isTerminator()) return isa<SwitchInst>(I);
    if (hasPoisonGeneratingFlags(&I)) return false;
    if (auto *TI = dyn_cast<TruncInst>(&I); TI && TI->hasNoUnsignedWrap())
      return false;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (SI->isAtomic() || SI->isVolatile()) return false;
    } else if (!isa<BinaryOperator>(I) && !isa<CastInst>(I) &&
               !isa<ICmpInst>(I) && !isa<SelectInst>(I) &&
               !isa<FreezeInst>(I)) {
      return false;
    }
    for (Value *Op : I.operands()) {
      auto *OI = dyn_cast<Instruction>(Op);
      if (OI && OI->getParent() == Header && !Available.contains(OI))
        return false;
    }
    Available.insert(&I);
  }
  return false;
}

static void cloneHeaderPlumbing(BasicBlock *Header, PHINode *State,
                                Value *RawState, Instruction *InsertBefore,
                                DenseMap<const Value *, Value *> *ResultMap =
                                    nullptr) {
  DenseMap<const Value *, Value *> Map;
  Map[State] = RawState;
  for (Instruction &I : *Header) {
    if (&I == State || isa<PHINode>(I) || isa<DbgInfoIntrinsic>(I)) continue;
    if (I.isTerminator()) break;
    Instruction *Clone = I.clone();
    for (unsigned O = 0; O != Clone->getNumOperands(); ++O) {
      auto It = Map.find(Clone->getOperand(O));
      if (It != Map.end()) Clone->setOperand(O, It->second);
    }
    if (!Clone->getType()->isVoidTy())
      Clone->setName(I.getName() + ".deobf.edge");
    Clone->insertBefore(InsertBefore->getIterator());
    Map[&I] = Clone;
  }
  if (ResultMap) *ResultMap = std::move(Map);
}

static bool canCloneDefaultEntry(BasicBlock *Default) {
  if (!Default || !Default->phis().empty()) return false;
  if (!isa<BranchInst>(Default->getTerminator()) &&
      !isa<SwitchInst>(Default->getTerminator()))
    return false;
  for (BasicBlock *Succ : successors(Default))
    if (!Succ->phis().empty()) return false;
  return true;
}

static BasicBlock *cloneDefaultEntry(
    BasicBlock *Default, DenseMap<const Value *, Value *> Map,
    StringRef Suffix) {
  BasicBlock *Clone = BasicBlock::Create(
      Default->getContext(), Default->getName() + Suffix,
      Default->getParent(), Default);
  for (Instruction &I : *Default) {
    Instruction *Copy = I.clone();
    for (unsigned O = 0; O != Copy->getNumOperands(); ++O) {
      auto It = Map.find(Copy->getOperand(O));
      if (It != Map.end()) Copy->setOperand(O, It->second);
    }
    if (!Copy->getType()->isVoidTy())
      Copy->setName(I.getName() + ".deobf.default");
    Copy->insertInto(Clone, Clone->end());
    Map[&I] = Copy;
  }
  return Clone;
}

struct MemoryJoinEdge {
  BasicBlock *Source = nullptr;
  BasicBlock *Through = nullptr;
  Value *RawState = nullptr;
  Value *Condition = nullptr;
  BasicBlock *TrueTarget = nullptr;
  BasicBlock *FalseTarget = nullptr;
  unsigned SuccessorIndex = 0;
  BasicBlock *EdgeBlock = nullptr;
  bool TrueViaDefault = false;
  bool FalseViaDefault = false;
  SmallVector<APInt, 8> FiniteRawValues;
  SmallVector<BasicBlock *, 8> FiniteTargets;
  SmallVector<bool, 8> FiniteViaDefault;
  std::string FiniteSetCertificate;
  bool ExactSwitchClone = false;
  DenseMap<const Value *, Value *> HeaderMap;
  BasicBlock *DefaultClone = nullptr;
};

static StoreInst *findReachingStateStore(BasicBlock *Source,
                                         Value *StatePointer,
                                         unsigned Depth,
                                         bool *HitBarrier) {
  if (Depth > 8) return nullptr;
  for (auto It = Source->rbegin(), End = Source->rend(); It != End; ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) {
      if (It->mayWriteToMemory()) {
        if (HitBarrier) *HitBarrier = true;
        return nullptr;
      }
      continue;
    }
    if (sameFrameAddress(SI->getPointerOperand(), StatePointer)) return SI;
    IntAffine Stored = parsePointerAffine(SI->getPointerOperand());
    IntAffine State = parsePointerAffine(StatePointer);
    if (!Stored.Valid || !State.Valid || !Stored.Base || !State.Base) {
      if (HitBarrier) *HitBarrier = true;
      return nullptr;
    }
    // Distinct identified globals cannot alias.  Continue through their
    // stores while remaining conservative for every unidentified object.
    if (Stored.Base != State.Base) continue;
  }
  if (Source->hasNPredecessors(1))
    return findReachingStateStore(*pred_begin(Source), StatePointer, Depth + 1,
                                  HitBarrier);
  return nullptr;
}

static PHINode *buildMergedReachingStateValue(BasicBlock *Merge,
                                              Value *StatePointer,
                                              Type *StateType) {
  if (!Merge || !StateType || !StateType->isIntegerTy()) return nullptr;
  SmallVector<std::pair<Value *, BasicBlock *>, 8> Incoming;
  for (Instruction &I : *Merge) {
    if (isa<PHINode>(I) || isa<DbgInfoIntrinsic>(I) || I.isTerminator())
      continue;
    if (I.mayWriteToMemory()) return nullptr;
  }
  for (BasicBlock *Pred : predecessors(Merge)) {
    unsigned EdgeCount = 0;
    for (BasicBlock *Succ : successors(Pred)) EdgeCount += Succ == Merge;
    if (EdgeCount != 1 || Incoming.size() == 8) return nullptr;
    bool HitBarrier = false;
    StoreInst *Store =
        findReachingStateStore(Pred, StatePointer, 0, &HitBarrier);
    if (!Store || HitBarrier || Store->isAtomic() || Store->isVolatile() ||
        Store->getValueOperand()->getType() != StateType ||
        !sameFrameAddress(Store->getPointerOperand(), StatePointer))
      return nullptr;
    Incoming.push_back({Store->getValueOperand(), Pred});
  }
  if (Incoming.size() < 2) return nullptr;
  auto *Merged = PHINode::Create(StateType, Incoming.size(),
                                 "deobf.merged.state",
                                 Merge->getFirstNonPHIIt());
  for (const auto &[Value, Pred] : Incoming) Merged->addIncoming(Value, Pred);
  return Merged;
}

static std::optional<APInt> findUniqueCaseEntryState(
    BasicBlock *Source, BasicBlock *Header, BasicBlock *Join,
    const DenseMap<BasicBlock *, APInt> &CaseStates) {
  SmallVector<BasicBlock *, 16> Work{Source};
  SmallPtrSet<BasicBlock *, 32> Seen;
  std::optional<APInt> Found;
  while (!Work.empty() && Seen.size() <= 64) {
    BasicBlock *BB = Work.pop_back_val();
    if (!Seen.insert(BB).second) continue;
    auto It = CaseStates.find(BB);
    if (It != CaseStates.end()) {
      if (Found && *Found != It->second) return std::nullopt;
      Found = It->second;
      continue;
    }
    if (BB == Header || BB == Join) continue;
    for (BasicBlock *Pred : predecessors(BB))
      Work.push_back(Pred);
  }
  return Found;
}

// Proves and bypasses the subset of a memory-join dispatcher whose reaching
// state definitions are constants or selects of constants.  The central
// dispatcher remains for every unproved predecessor; this is the minimal
// residual form required by the design, not a completeness claim.
static unsigned recoverMemoryJoinTransitions(
    SwitchInst &SI, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header ||
      !canCloneHeaderPlumbing(Header, State))
    return 0;

  DenseMap<APInt, BasicBlock *> CaseMap;
  DenseMap<BasicBlock *, APInt> CaseStates;
  SmallPtrSet<BasicBlock *, 8> AmbiguousCaseStates;
  for (auto Case : SI.cases())
    CaseMap[Case.getCaseValue()->getValue()] = Case.getCaseSuccessor();
  if (CaseMap.size() < 4) return 0;
  for (auto Case : SI.cases()) {
    auto Raw = decodeStateExpr(SI.getCondition(), State,
                               Case.getCaseValue()->getValue());
    if (!Raw) continue;
    BasicBlock *Target = Case.getCaseSuccessor();
    auto It = CaseStates.find(Target);
    if (It == CaseStates.end())
      CaseStates.try_emplace(Target, *Raw);
    else if (It->second != *Raw)
      AmbiguousCaseStates.insert(Target);
  }
  for (BasicBlock *BB : AmbiguousCaseStates) CaseStates.erase(BB);
  auto Resolve = [&](const APInt &Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw);
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    if (It == CaseMap.end() ||
        It->second->phis().begin() != It->second->phis().end())
      return nullptr;
    return It->second;
  };
  const bool DefaultCloneable = canCloneDefaultEntry(SI.getDefaultDest());
  const bool ExactSwitchTargetsCloneable =
      DefaultCloneable && llvm::all_of(successors(Header), [](BasicBlock *BB) {
        return BB->phis().empty();
      });

  SmallVector<MemoryJoinEdge, 64> Edges;
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    Value *Incoming = State->getIncomingValue(I);
    BasicBlock *Pred = State->getIncomingBlock(I);
    if (auto *Initial = dyn_cast<ConstantInt>(Incoming)) {
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      BasicBlock *Target = Resolve(Initial->getValue());
      if (Br && Br->isUnconditional() && Br->getSuccessor(0) == Header &&
          Target) {
        MemoryJoinEdge E;
        E.Source = Pred;
        E.Through = Header;
        E.RawState = Initial;
        E.TrueTarget = Target;
        Edges.push_back(std::move(E));
      }
      continue;
    }
    auto *LI = dyn_cast<LoadInst>(Incoming);
    if (!LI || LI->isAtomic() || LI->isVolatile() || LI->getParent() != Pred)
      continue;
    IntAffine StateAddress = parsePointerAffine(LI->getPointerOperand());
    if (!StateAddress.Valid || !StateAddress.Base || StateAddress.Coeff != 1)
      continue;
    auto *JoinBr = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!JoinBr || !JoinBr->isUnconditional() ||
        JoinBr->getSuccessor(0) != Header)
      continue;
    for (BasicBlock *Source : predecessors(Pred)) {
      auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
      if (!Br) continue;
      unsigned EdgeIndex = 0, EdgeCount = 0;
      for (unsigned S = 0; S != Br->getNumSuccessors(); ++S)
        if (Br->getSuccessor(S) == Pred) {
          EdgeIndex = S;
          ++EdgeCount;
        }
      if (EdgeCount != 1) continue;
      bool HitBarrier = false;
      StoreInst *Store = findReachingStateStore(
          Source, LI->getPointerOperand(), 0, &HitBarrier);
      PHINode *MergedState = nullptr;
      if (!Store && !HitBarrier)
        MergedState = buildMergedReachingStateValue(
            Source, LI->getPointerOperand(), LI->getType());
      if (!Store && !MergedState) {
        if (HitBarrier)
          Proofs.push_back({Header->getParent()->getName().str(),
                            "cff_transition_candidate", Source->getName().str(),
                            "memory_join_bv_evaluator", "barrier",
                            "unknown_memory_write_or_alias_barrier"});
        continue;
      }
      Value *Raw = Store ? Store->getValueOperand()
                         : static_cast<Value *>(MergedState);
      auto EntryState = findUniqueCaseEntryState(Source, Header, Pred,
                                                 CaseStates);
      std::optional<APInt> RawConstant;
      if (auto *C = dyn_cast<ConstantInt>(Raw))
        RawConstant = C->getValue();
      else if (EntryState)
        RawConstant = evalTransitionExpr(Raw, LI->getPointerOperand(),
                                         *EntryState);
      if (RawConstant) {
        MemoryJoinEdge E;
        E.Source = Source;
        E.Through = Pred;
        E.RawState = Raw;
        E.SuccessorIndex = EdgeIndex;
        E.TrueTarget = Resolve(*RawConstant);
        if (!E.TrueTarget && DefaultCloneable) {
          E.TrueTarget = SI.getDefaultDest();
          E.TrueViaDefault = true;
        }
        if (E.TrueTarget) {
          Edges.push_back(std::move(E));
        } else {
          Proofs.push_back({Header->getParent()->getName().str(),
                            "cff_transition_candidate", Source->getName().str(),
                            "memory_join_bv_evaluator", "unresolved",
                            "default_entry_not_safely_cloneable"});
          if (MergedState && MergedState->use_empty())
            MergedState->eraseFromParent();
        }
        continue;
      }
      auto *Sel = dyn_cast<SelectInst>(Raw);
      if (!Sel) {
        SmallVector<APInt, 8> FiniteValues;
        DenseMap<const Value *, APInt> NoBindings;
        unsigned ExecutionBudget = 128;
        std::string Certificate;
        bool Finite = EntryState &&
                      enumerateTransitionValues(
                          Raw, LI->getPointerOperand(), *EntryState,
                          NoBindings, FiniteValues, ExecutionBudget) &&
                      FiniteValues.size() >= 2 &&
                      proveFiniteTransitionSetSMT(Raw, FiniteValues,
                                                  Certificate);
        MemoryJoinEdge E;
        if (Finite) {
          E.Source = Source;
          E.Through = Pred;
          E.RawState = Raw;
          E.SuccessorIndex = EdgeIndex;
          E.FiniteRawValues = FiniteValues;
          E.FiniteSetCertificate = std::move(Certificate);
          for (const APInt &Value : FiniteValues) {
            BasicBlock *Target = Resolve(Value);
            bool ViaDefault = false;
            if (!Target && DefaultCloneable) {
              Target = SI.getDefaultDest();
              ViaDefault = true;
            }
            if (!Target) {
              Finite = false;
              break;
            }
            E.FiniteTargets.push_back(Target);
            E.FiniteViaDefault.push_back(ViaDefault);
          }
        }
        if (Finite) {
          Edges.push_back(std::move(E));
          continue;
        }
        if (EntryState && ExactSwitchTargetsCloneable) {
          E = MemoryJoinEdge();
          E.Source = Source;
          E.Through = Pred;
          E.RawState = Raw;
          E.SuccessorIndex = EdgeIndex;
          E.ExactSwitchClone = true;
          Edges.push_back(std::move(E));
          continue;
        }
        Proofs.push_back({
            Header->getParent()->getName().str(),
            "cff_transition_candidate", Source->getName().str(),
            "memory_join_finite_set_executor", "unresolved",
            EntryState
                ? "transition_set_not_exhaustive_or_smt_membership_unproved"
                : "case_entry_state_not_unique"});
        if (MergedState && MergedState->use_empty())
          MergedState->eraseFromParent();
        continue;
      }
      auto EvalArm = [&](Value *Arm) -> std::optional<APInt> {
        if (auto *C = dyn_cast<ConstantInt>(Arm)) return C->getValue();
        if (!EntryState) return std::nullopt;
        return evalTransitionExpr(Arm, LI->getPointerOperand(), *EntryState);
      };
      auto TC = EvalArm(Sel->getTrueValue());
      auto FC = EvalArm(Sel->getFalseValue());
      if (!TC || !FC) {
        Proofs.push_back({Header->getParent()->getName().str(),
                          "cff_transition_candidate", Source->getName().str(),
                          "memory_join_bv_evaluator", "unresolved",
                          "ite_arm_not_reduced_to_constant"});
        if (MergedState && MergedState->use_empty())
          MergedState->eraseFromParent();
        continue;
      }
      MemoryJoinEdge E;
      E.Source = Source;
      E.Through = Pred;
      E.RawState = Raw;
      E.Condition = Sel->getCondition();
      E.SuccessorIndex = EdgeIndex;
      E.TrueTarget = Resolve(*TC);
      E.FalseTarget = Resolve(*FC);
      if (!E.TrueTarget && DefaultCloneable) {
        E.TrueTarget = SI.getDefaultDest();
        E.TrueViaDefault = true;
      }
      if (!E.FalseTarget && DefaultCloneable) {
        E.FalseTarget = SI.getDefaultDest();
        E.FalseViaDefault = true;
      }
      if (E.TrueTarget && E.FalseTarget)
        Edges.push_back(std::move(E));
      else
        Proofs.push_back({Header->getParent()->getName().str(),
                          "cff_transition_candidate", Source->getName().str(),
                          "memory_join_bv_evaluator", "unresolved",
                          "ite_default_entry_not_safely_cloneable"});
      if ((!E.TrueTarget || !E.FalseTarget) && MergedState &&
          MergedState->use_empty())
        MergedState->eraseFromParent();
    }
  }
  if (Edges.empty()) return 0;

  std::string FunctionName = Header->getParent()->getName().str();
  // Clone every copy of the dispatcher plumbing before removing any incoming
  // edge.  removePredecessor() may simplify (and delete) the state PHI.
  for (MemoryJoinEdge &E : Edges) {
    Instruction *Old = E.Source->getTerminator();
    if (Old->getNumSuccessors() == 1) {
      cloneHeaderPlumbing(Header, State, E.RawState, Old, &E.HeaderMap);
    } else {
      E.EdgeBlock = BasicBlock::Create(
          Header->getContext(), E.Source->getName() + ".deobf.dispatch.edge",
          Header->getParent(), E.Through);
      Instruction *Temporary = BranchInst::Create(E.Through, E.EdgeBlock);
      cloneHeaderPlumbing(Header, State, E.RawState, Temporary, &E.HeaderMap);
    }
    bool FiniteUsesDefault = llvm::is_contained(E.FiniteViaDefault, true);
    if (E.TrueViaDefault || E.FalseViaDefault || FiniteUsesDefault ||
        E.ExactSwitchClone) {
      std::string Suffix = ".deobf.from." + E.Source->getName().str();
      E.DefaultClone = cloneDefaultEntry(
          SI.getDefaultDest(), E.HeaderMap, Suffix);
      if (E.TrueViaDefault) E.TrueTarget = E.DefaultClone;
      if (E.FalseViaDefault) E.FalseTarget = E.DefaultClone;
      for (unsigned I = 0; I != E.FiniteTargets.size(); ++I)
        if (E.FiniteViaDefault[I]) E.FiniteTargets[I] = E.DefaultClone;
    }
  }
  for (MemoryJoinEdge &E : Edges) {
    Instruction *Old = E.Source->getTerminator();
    E.Through->removePredecessor(E.Source);
    Instruction *Replace = Old;
    if (E.EdgeBlock) {
      Old->setSuccessor(E.SuccessorIndex, E.EdgeBlock);
      Replace = E.EdgeBlock->getTerminator();
    }
    if (E.ExactSwitchClone) {
      Value *Condition = E.HeaderMap.lookup(SI.getCondition());
      if (!Condition)
        report_fatal_error("exact dispatcher clone lost mapped condition");
      auto *ExactSwitch = SwitchInst::Create(
          Condition, E.DefaultClone, SI.getNumCases(), Replace->getIterator());
      for (auto Case : SI.cases())
        ExactSwitch->addCase(Case.getCaseValue(), Case.getCaseSuccessor());
    } else if (!E.FiniteRawValues.empty()) {
      auto *FiniteSwitch = SwitchInst::Create(
          E.RawState, E.FiniteTargets.front(),
          E.FiniteRawValues.size() - 1, Replace->getIterator());
      for (unsigned I = 1; I != E.FiniteRawValues.size(); ++I)
        FiniteSwitch->addCase(
            ConstantInt::get(E.RawState->getContext(), E.FiniteRawValues[I]),
            E.FiniteTargets[I]);
    } else if (E.Condition)
      BranchInst::Create(E.TrueTarget, E.FalseTarget, E.Condition,
                         Replace->getIterator());
    else
      BranchInst::Create(E.TrueTarget, Replace->getIterator());
    Replace->eraseFromParent();
    if (E.ExactSwitchClone) {
      ProofRecord Record{FunctionName, "cff_transition",
                         E.Source->getName().str(),
                         "memory_join_exact_dispatcher_clone", "proved"};
      Record.ProofQueryHash = hashText(valueText(SI));
      Record.Dependencies.push_back("exact_header_plumbing_clone");
      Record.Dependencies.push_back("exhaustive_original_switch_cases");
      Record.Dependencies.push_back("exact_default_entry_clone");
      Proofs.push_back(std::move(Record));
    } else if (!E.FiniteRawValues.empty()) {
      ProofRecord Record{FunctionName, "cff_transition",
                         E.Source->getName().str(),
                         "memory_join_finite_set_z3_unsat", "proved"};
      Record.ProofQueryHash = hashText(E.FiniteSetCertificate);
      Record.Dependencies.push_back("bounded_acyclic_fork_merge_enumeration");
      Record.Dependencies.push_back("exhaustive_transition_set_smt_membership");
      Record.Dependencies.push_back("exact_header_plumbing_clone");
      Proofs.push_back(std::move(Record));
    } else {
      Proofs.push_back({FunctionName, "cff_transition",
                        E.Source->getName().str(),
                        (E.TrueViaDefault || E.FalseViaDefault)
                            ? "memory_join_default_entry_clone"
                            : "memory_join_constant_or_select",
                        "proved"});
    }
  }
  return Edges.size();
}

static std::string describeDispatcherResidual(SwitchInst &SI) {
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State) return "state_root_or_transition_set_not_recovered";
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    auto *LI = dyn_cast<LoadInst>(State->getIncomingValue(I));
    BasicBlock *Join = State->getIncomingBlock(I);
    if (!LI || LI->getParent() != Join) continue;
    auto *Br = dyn_cast<BranchInst>(Join->getTerminator());
    if (!Br || !Br->isUnconditional() ||
        Br->getSuccessor(0) != State->getParent())
      continue;
    unsigned Preds = 0, MatchingStores = 0;
    for (BasicBlock *Pred : predecessors(Join)) {
      ++Preds;
      for (auto It = Pred->rbegin(), End = Pred->rend(); It != End; ++It) {
        auto *Store = dyn_cast<StoreInst>(&*It);
        if (!Store) continue;
        if (sameFrameAddress(Store->getPointerOperand(),
                             LI->getPointerOperand()))
          ++MatchingStores;
        break;
      }
    }
    return "memory_join_recurrence:matching_stores=" +
           std::to_string(MatchingStores) + "/" + std::to_string(Preds) +
           ";default_dispatcher_resolver_required=" +
           (SI.getDefaultDest() == SI.getParent() ? "false" : "true");
  }
  return "state_root_or_transition_set_not_recovered";
}

struct LadderCase {
  BasicBlock *Block = nullptr;
  ConstantInt *Key = nullptr;
  BasicBlock *Target = nullptr;
};

static bool recoverCompareLadders(Function &F, Metrics &M,
                                  SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 16> Work;
  for (BasicBlock &BB : F)
    if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
        BI && BI->isConditional())
      Work.emplace_back(BI);
  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *FirstBranch = dyn_cast_or_null<BranchInst>(Handle);
    if (!FirstBranch || !FirstBranch->isConditional()) continue;
    BasicBlock *First = FirstBranch->getParent();
    Value *Expression = nullptr;
    SmallVector<LadderCase, 8> Cases;
    SmallPtrSet<BasicBlock *, 8> LadderBlocks;
    BasicBlock *Current = First;
    BasicBlock *Tail = nullptr;
    while (Cases.size() < 256) {
      auto *BI = dyn_cast<BranchInst>(Current->getTerminator());
      auto *Cmp = BI && BI->isConditional()
                      ? dyn_cast<ICmpInst>(BI->getCondition())
                      : nullptr;
      if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
                   Cmp->getPredicate() != ICmpInst::ICMP_NE)) {
        Tail = Current;
        break;
      }
      Value *Compared = nullptr;
      ConstantInt *Key = dyn_cast<ConstantInt>(Cmp->getOperand(1));
      if (Key) Compared = Cmp->getOperand(0);
      else if ((Key = dyn_cast<ConstantInt>(Cmp->getOperand(0))))
        Compared = Cmp->getOperand(1);
      if (!Key || !Compared->getType()->isIntegerTy() ||
          (Expression && Compared != Expression)) {
        Tail = Current;
        break;
      }
      if (!Expression) Expression = Compared;
      bool EqualOnTrue = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
      BasicBlock *Target = BI->getSuccessor(EqualOnTrue ? 0 : 1);
      BasicBlock *Next = BI->getSuccessor(EqualOnTrue ? 1 : 0);
      if (!Target->phis().empty() || !LadderBlocks.insert(Current).second)
        break;
      bool Safe = true;
      for (Instruction &I : *Current) {
        if (&I == Cmp || I.isTerminator() || isa<DbgInfoIntrinsic>(I)) continue;
        if (Current != First || I.mayHaveSideEffects()) {
          Safe = false;
          break;
        }
      }
      if (!Safe) break;
      for (const LadderCase &Existing : Cases)
        if (Existing.Key->getValue() == Key->getValue()) Safe = false;
      if (!Safe) break;
      Cases.push_back({Current, Key, Target});
      if (!Next->hasNPredecessors(1)) {
        Tail = Next;
        break;
      }
      Current = Next;
    }
    if (Cases.size() < 4 || !Tail || !Tail->phis().empty()) continue;
    bool TargetIsLadder = false;
    for (const LadderCase &C : Cases)
      TargetIsLadder |= LadderBlocks.contains(C.Target);
    if (TargetIsLadder) continue;

    Instruction *Old = First->getTerminator();
    auto *NewSwitch = SwitchInst::Create(Expression, Tail, Cases.size(),
                                         Old->getIterator());
    for (const LadderCase &C : Cases)
      NewSwitch->addCase(C.Key, C.Target);
    for (unsigned I = 1; I != Cases.size(); ++I)
      Cases[I].Target->removePredecessor(Cases[I].Block);
    Tail->removePredecessor(Cases.back().Block);
    Old->eraseFromParent();
    removeUnreachableBlocks(F);
    ++M.CompareLaddersRecovered;
    Proofs.push_back({F.getName().str(), "compare_ladder",
                      First->getName().str(),
                      "same_bv_expression_exhaustive_chain", "proved"});
    if (verifyFunction(F, &errs())) {
      ++M.VerifierFailures;
      report_fatal_error("compare-ladder rewrite produced invalid IR");
    }
    Changed = true;
  }
  return Changed;
}

static bool recoverDispatchers(Function &F, Metrics &M,
                               SmallVectorImpl<ProofRecord> &Proofs) {
  // Full recovery can delete other unreachable dispatchers.  Tracking handles
  // make the worklist deletion-safe instead of probing a dangling pointer.
  SmallVector<WeakTrackingVH, 16> Candidates;
  for (BasicBlock &BB : F)
    if (auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
        SI && SI->getNumCases() >= 4) {
      SmallPtrSet<BasicBlock *, 16> Successors;
      for (BasicBlock *Succ : successors(&BB)) Successors.insert(Succ);
      unsigned Returning = 0;
      for (BasicBlock *Succ : Successors)
        Returning += Succ == &BB || isPotentiallyReachable(Succ, &BB);
      // Acyclic application switches are not CFF candidates.  Require both a
      // real recurrence and majority return coverage; this is classification
      // only and is never used as a rewrite proof.
      if (findStateRoot(SI->getCondition()) && Returning >= 2 &&
          Returning * 2 >= Successors.size())
        Candidates.emplace_back(SI);
    }
  bool Changed = false;
  for (WeakTrackingVH &Candidate : Candidates) {
    auto *SI = dyn_cast_or_null<SwitchInst>(Candidate);
    if (!SI) continue;
    bool CandidateChanged = false;
    std::string Origin = SI->getParent()->getName().str();
    if (tryRecoverMultiIncomingSSADispatcher(*SI, M, Proofs) ||
        tryRecoverSSAPlumbingDispatcher(*SI, M, Proofs) ||
        tryRecoverSSADispatcher(*SI, M, Proofs) ||
        tryRecoverFunnelDispatcher(*SI, M, Proofs)) {
      Changed = CandidateChanged = true;
    } else {
      // Capture the structural diagnosis before partial bypassing can simplify
      // the state PHI into its sole remaining load.
      std::string Residual = describeDispatcherResidual(*SI);
      unsigned ProvedTransitions = recoverMemoryJoinTransitions(*SI, Proofs);
      Changed |= ProvedTransitions != 0;
      CandidateChanged = ProvedTransitions != 0;
      if (ProvedTransitions)
        Residual += ";proved_direct_transitions=" +
                    std::to_string(ProvedTransitions);
      auto Existing = std::find_if(Proofs.begin(), Proofs.end(),
                                   [&](const ProofRecord &P) {
        return P.Function == F.getName() && P.Kind == "cff_candidate" &&
               P.Origin == Origin && P.Result == "unresolved";
      });
      if (Existing != Proofs.end()) {
        Existing->ResidualReason = Residual;
      } else {
        ++M.DispatchersUnresolved;
        Proofs.push_back({F.getName().str(), "cff_candidate", Origin,
                          "structural_ssa_analysis", "unresolved", Residual});
      }
    }
    if (CandidateChanged && verifyFunction(F, &errs())) {
      ++M.VerifierFailures;
      report_fatal_error("dispatcher rewrite produced invalid IR");
    }
  }
  if (Changed) removeUnreachableBlocks(F);
  return Changed;
}

static void reconcileDispatcherProofs(Module &M, Metrics &Stats,
                                      SmallVectorImpl<ProofRecord> &Proofs) {
  for (ProofRecord &P : Proofs) {
    if (P.Kind != "cff_candidate" || P.Result != "unresolved") continue;
    Function *F = M.getFunction(P.Function);
    BasicBlock *Origin = nullptr;
    if (F)
      for (BasicBlock &BB : *F)
        if (BB.getName() == P.Origin) {
          Origin = &BB;
          break;
        }
    if (Origin) {
      if (!isa<SwitchInst>(Origin->getTerminator()))
        P.ResidualReason = "dispatcher_origin_survives_without_switch";
      continue;
    }
    P.Kind = "cff_dispatcher";
    P.Engine = "dead_after_proved_transition_rewrites";
    P.Result = "proved";
    P.ResidualReason.clear();
    if (Stats.DispatchersUnresolved) --Stats.DispatchersUnresolved;
    ++Stats.DispatchersRecovered;
  }
}

static LiftProfile inventoryModule(Module &M) {
  LiftProfile P;
  struct RawFrameAccess {
    std::string Base;
    int64_t Offset = 0;
    uint64_t Size = 0;
    bool IsStore = false;
  };
  SmallVector<RawFrameAccess, 64> FrameAccesses;
  const DataLayout &DL = M.getDataLayout();
  for (GlobalVariable &GV : M.globals())
    if (containsLiftMarker(GV.getName()) ||
        GV.getName().contains_insensitive("frame_storage"))
      ++P.FrameBackingGlobals;
  for (StructType *ST : M.getIdentifiedStructTypes())
    if (ST->hasName() && containsLiftMarker(ST->getName()))
      ++P.StateStructTypes;

  SmallPtrSet<const Value *, 32> SeenLocations;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    ++P.DefinedFunctions;
    if (containsLiftMarker(F.getName())) ++P.RuntimeHelpers;
    unsigned Instructions = 0, Calls = 0;
    for (Instruction &I : instructions(F)) {
      ++Instructions;
      Value *AccessPointer = nullptr;
      Type *AccessType = nullptr;
      bool IsStore = false;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        AccessPointer = LI->getPointerOperand();
        AccessType = LI->getType();
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        AccessPointer = SI->getPointerOperand();
        AccessType = SI->getValueOperand()->getType();
        IsStore = true;
      }
      if (AccessPointer && AccessType && AccessType->isSized()) {
        IntAffine A = parsePointerAffine(AccessPointer);
        TypeSize TS = DL.getTypeStoreSize(AccessType);
        if (A.Valid && A.Base && A.Coeff == 1 && !TS.isScalable() &&
            (containsLiftMarker(A.Base->getName()) ||
             A.Base->getName().contains_insensitive("frame_storage"))) {
          uint64_t Size = TS.getFixedValue();
          int64_t Offset = A.Offset.getSExtValue();
          if (Size && Size <= static_cast<uint64_t>(INT64_MAX) &&
              Offset <= INT64_MAX - static_cast<int64_t>(Size))
            FrameAccesses.push_back(
                {A.Base->getName().str(), Offset, Size, IsStore});
        }
      }
      if (isa<PtrToIntInst>(I) || isa<IntToPtrInst>(I))
        ++P.AddressConversions;
      for (Value *Op : I.operands()) {
        P.UndefOperands += isa<UndefValue>(Op);
        P.PoisonOperands += isa<PoisonValue>(Op);
      }
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        ++Calls;
        if (CB->isInlineAsm()) ++P.InlineAsmCalls;
        else if (!CB->getCalledFunction()) ++P.IndirectCalls;
      }
      if (isa<IndirectBrInst>(I)) ++P.IndirectBranches;
      if (auto *BI = dyn_cast<BranchInst>(&I); BI && BI->isConditional()) {
        ++P.ConditionalBranches;
        if (auto *Cmp = dyn_cast<ICmpInst>(BI->getCondition());
            Cmp && (isa<ConstantInt>(Cmp->getOperand(0)) ||
                    isa<ConstantInt>(Cmp->getOperand(1))))
          ++P.ConstantCompareBranches;
      }
      auto *SI = dyn_cast<SwitchInst>(&I);
      if (!SI || SI->getNumCases() < 4) continue;
      PHINode *State = findStateRoot(SI->getCondition());
      if (!State) continue;
      for (Value *Incoming : State->incoming_values()) {
        auto *LI = dyn_cast<LoadInst>(Incoming);
        if (!LI || !SeenLocations.insert(LI->getPointerOperand()).second)
          continue;
        IntAffine A = parsePointerAffine(LI->getPointerOperand());
        if (!A.Valid || !A.Base || A.Coeff != 1) continue;
        SmallString<32> Offset;
        A.Offset.toStringSigned(Offset);
        P.CandidateStateLocations.push_back(
            (A.Base->getName() + ":" + Offset).str());
      }
    }
    if (Instructions <= 8 && Calls == 1) ++P.SmallWrapperCandidates;
  }
  llvm::sort(P.CandidateStateLocations);
  P.CandidateStateLocations.erase(
      std::unique(P.CandidateStateLocations.begin(),
                  P.CandidateStateLocations.end()),
      P.CandidateStateLocations.end());
  llvm::sort(FrameAccesses, [](const RawFrameAccess &A,
                              const RawFrameAccess &B) {
    return std::tie(A.Base, A.Offset, A.Size) <
           std::tie(B.Base, B.Offset, B.Size);
  });
  for (const RawFrameAccess &Access : FrameAccesses) {
    bool Overlaps = false;
    if (!P.FrameObjects.empty()) {
      LiftProfile::FrameObject &Last = P.FrameObjects.back();
      int64_t LastEnd = Last.Offset + static_cast<int64_t>(Last.Size);
      Overlaps = Last.Base == Access.Base && Access.Offset < LastEnd;
      if (Overlaps) {
        int64_t AccessEnd = Access.Offset + static_cast<int64_t>(Access.Size);
        Last.HasOverlappingViews |=
            Last.Offset != Access.Offset || Last.Size != Access.Size;
        Last.Size = static_cast<uint64_t>(std::max(LastEnd, AccessEnd) -
                                         Last.Offset);
        Last.Loads += !Access.IsStore;
        Last.Stores += Access.IsStore;
      }
    }
    if (!Overlaps) {
      LiftProfile::FrameObject Object;
      Object.Base = Access.Base;
      Object.Offset = Access.Offset;
      Object.Size = Access.Size;
      Object.Loads = !Access.IsStore;
      Object.Stores = Access.IsStore;
      P.FrameObjects.push_back(std::move(Object));
    }
  }
  for (LiftProfile::FrameObject &Object : P.FrameObjects) {
    std::string Location =
        Object.Base + ":" + std::to_string(Object.Offset);
    if (std::find(P.CandidateStateLocations.begin(),
                  P.CandidateStateLocations.end(), Location) !=
        P.CandidateStateLocations.end())
      Object.Role = "cff.state_candidate";
    else if (Object.HasOverlappingViews)
      Object.Role = "frame.overlapping_views";
  }
  return P;
}

static bool importExistingInventory(Module &M, LiftProfile &P) {
  NamedMDNode *Inventory = M.getNamedMetadata("ollvm.deobf.inventory");
  if (!Inventory || Inventory->getNumOperands() == 0) return false;
  MDNode *Header = Inventory->getOperand(0);
  if (Header->getNumOperands() != 14) return false;
  auto GetString = [&](unsigned Index) -> StringRef {
    auto *S = dyn_cast<MDString>(Header->getOperand(Index));
    return S ? S->getString() : StringRef();
  };
  if (GetString(0) != "v1") return false;
  unsigned *Fields[] = {
      &P.DefinedFunctions, &P.RuntimeHelpers, &P.SmallWrapperCandidates,
      &P.FrameBackingGlobals, &P.StateStructTypes, &P.InlineAsmCalls,
      &P.IndirectCalls, &P.IndirectBranches, &P.AddressConversions,
      &P.UndefOperands, &P.PoisonOperands, &P.ConditionalBranches,
      &P.ConstantCompareBranches};
  for (unsigned I = 0; I != 13; ++I)
    if (GetString(I + 1).getAsInteger(10, *Fields[I])) return false;
  P.CandidateStateLocations.clear();
  P.FrameObjects.clear();
  for (unsigned I = 1; I != Inventory->getNumOperands(); ++I) {
    MDNode *Node = Inventory->getOperand(I);
    auto Field = [&](unsigned Index) -> StringRef {
      if (Index >= Node->getNumOperands()) return {};
      auto *S = dyn_cast<MDString>(Node->getOperand(Index));
      return S ? S->getString() : StringRef();
    };
    if (Node->getNumOperands() == 1) {
      P.CandidateStateLocations.push_back(Field(0).str());
    } else if (Field(0) == "state" && Node->getNumOperands() == 2) {
      P.CandidateStateLocations.push_back(Field(1).str());
    } else if (Field(0) == "object" &&
               (Node->getNumOperands() == 7 ||
                Node->getNumOperands() == 8)) {
      LiftProfile::FrameObject Object;
      Object.Base = Field(1).str();
      if (Field(2).getAsInteger(10, Object.Offset) ||
          Field(3).getAsInteger(10, Object.Size) ||
          Field(4).getAsInteger(10, Object.Loads) ||
          Field(5).getAsInteger(10, Object.Stores))
        return false;
      Object.HasOverlappingViews = Field(6) == "1";
      if (Node->getNumOperands() == 8) Object.Role = Field(7).str();
      P.FrameObjects.push_back(std::move(Object));
    }
  }
  return true;
}

static void addModuleMetadata(Module &M, const Metrics &Stats,
                              const LiftProfile &Inventory,
                              ArrayRef<ProofRecord> Proofs) {
  LLVMContext &C = M.getContext();
  NamedMDNode *Profile = M.getOrInsertNamedMetadata("ollvm.deobf.profile");
  Profile->clearOperands();
  auto S = [&](unsigned V) { return MDString::get(C, std::to_string(V)); };
  Profile->addOperand(MDNode::get(C, {
      MDString::get(C, "v2"), S(Stats.Functions), S(Stats.Switches),
      S(Stats.LargeSwitches), S(Stats.LiftedFunctions),
      S(Stats.FlagsSanitized), S(Stats.BVRewrites),
      S(Stats.InstSubRewrites), S(Stats.OpaqueEdgesPruned),
      S(Stats.CompareLaddersRecovered),
      S(Inventory.IndirectCalls), S(Inventory.InlineAsmCalls),
      S(Inventory.UndefOperands), S(Inventory.PoisonOperands)}));
  NamedMDNode *InventoryMD =
      M.getOrInsertNamedMetadata("ollvm.deobf.inventory");
  InventoryMD->clearOperands();
  InventoryMD->addOperand(MDNode::get(C, {
      MDString::get(C, "v1"), S(Inventory.DefinedFunctions),
      S(Inventory.RuntimeHelpers), S(Inventory.SmallWrapperCandidates),
      S(Inventory.FrameBackingGlobals), S(Inventory.StateStructTypes),
      S(Inventory.InlineAsmCalls), S(Inventory.IndirectCalls),
      S(Inventory.IndirectBranches), S(Inventory.AddressConversions),
      S(Inventory.UndefOperands), S(Inventory.PoisonOperands),
      S(Inventory.ConditionalBranches),
      S(Inventory.ConstantCompareBranches)}));
  for (const std::string &Location : Inventory.CandidateStateLocations)
    InventoryMD->addOperand(
        MDNode::get(C, {MDString::get(C, "state"),
                        MDString::get(C, Location)}));
  for (const LiftProfile::FrameObject &Object : Inventory.FrameObjects)
    InventoryMD->addOperand(MDNode::get(C, {
        MDString::get(C, "object"), MDString::get(C, Object.Base),
        MDString::get(C, std::to_string(Object.Offset)),
        MDString::get(C, std::to_string(Object.Size)),
        MDString::get(C, std::to_string(Object.Loads)),
        MDString::get(C, std::to_string(Object.Stores)),
        MDString::get(C, Object.HasOverlappingViews ? "1" : "0"),
        MDString::get(C, Object.Role)}));
  NamedMDNode *Ledger = M.getOrInsertNamedMetadata("ollvm.deobf.proofs");
  Ledger->clearOperands();
  for (const ProofRecord &P : Proofs) {
    std::string Dependencies;
    for (const std::string &Dependency : P.Dependencies) {
      if (!Dependencies.empty()) Dependencies.push_back('\x1f');
      Dependencies += Dependency;
    }
    Ledger->addOperand(MDNode::get(C, {MDString::get(C, P.Function),
                                      MDString::get(C, P.Kind),
                                      MDString::get(C, P.Origin),
                                      MDString::get(C, P.Engine),
                                      MDString::get(C, P.Result),
                                      MDString::get(C, P.ResidualReason),
                                      MDString::get(C, P.OldHash),
                                      MDString::get(C, P.NewHash),
                                      MDString::get(C, P.ProofQueryHash),
                                      MDString::get(C, Dependencies)}));
  }
}

static void writeReport(const Module &M, const Metrics &Stats,
                        const LiftProfile &Inventory,
                        ArrayRef<ProofRecord> Proofs) {
  if (ReportPath.empty()) return;
  json::Array Records;
  bool HasResiduals = false;
  for (const ProofRecord &P : Proofs) {
    HasResiduals |= P.Result != "proved";
    json::Object Record{{"function", P.Function}, {"kind", P.Kind},
                        {"origin", P.Origin}, {"proof_engine", P.Engine},
                        {"result", P.Result}};
    Record["old_hash"] = P.OldHash.empty()
                             ? json::Value(nullptr)
                             : json::Value(P.OldHash);
    Record["new_hash"] = P.NewHash.empty()
                             ? json::Value(nullptr)
                             : json::Value(P.NewHash);
    Record["proof_query_hash"] = P.ProofQueryHash.empty()
                                     ? json::Value(nullptr)
                                     : json::Value(P.ProofQueryHash);
    json::Array Dependencies;
    for (const std::string &Dependency : P.Dependencies)
      Dependencies.push_back(Dependency);
    Record["dependencies"] = std::move(Dependencies);
    if (P.ResidualReason.empty())
      Record["residual_reason"] = nullptr;
    else
      Record["residual_reason"] = P.ResidualReason;
    Records.push_back(std::move(Record));
  }
  json::Array StateLocations;
  for (const std::string &Location : Inventory.CandidateStateLocations)
    StateLocations.push_back(Location);
  json::Array FrameObjects;
  for (const LiftProfile::FrameObject &Object : Inventory.FrameObjects)
    FrameObjects.push_back(json::Object{
        {"base", Object.Base}, {"signed_offset", Object.Offset},
        {"size", Object.Size}, {"loads", Object.Loads},
        {"stores", Object.Stores},
        {"has_overlapping_views", Object.HasOverlappingViews},
        {"role", Object.Role}});
  json::Object Root{
      {"schema", "ollvm-deobf-ledger-v2"},
      {"status", !HasResiduals && Stats.DispatchersUnresolved == 0 &&
                         Stats.VerifierFailures == 0
                     ? "pass_detected_scope"
                     : "partial_with_residuals"},
      {"implemented_scope", json::Array{"lifted_flag_sanitize",
                                          "exact_bv_templates",
                                          "z3_rewrite_equivalence_gate",
                                          "adjacent_product_parity",
                                          "z3_pure_ssa_predicates",
                                          "ssa_constant_cff",
                                          "funnel_cff",
                                          "affine_frame_addresses",
                                          "memory_join_bv_transitions",
                                          "transition_local_object_memory_map",
                                          "transition_predecessor_memory_merge",
                                          "transition_cfg_arm_state_store_phi",
                                          "transition_rotate_bswap_ctpop_semantics",
                                          "transition_readnone_readonly_call_summaries",
                                          "transition_acyclic_fork_merge_finite_set_smt",
                                          "transition_exact_dynamic_dispatcher_clone",
                                          "path_local_edge_splitting",
                                          "side_effect_plumbing_clone",
                                          "default_entry_clone",
                                          "pure_compare_ladder_to_switch",
                                          "affine_bv_local_saturation",
                                          "multi_root_affine_tuple_extraction",
                                          "multi_root_ac_tuple_extraction",
                                          "multi_root_mixed_operator_eclass_extraction",
                                          "ac_bitvector_local_saturation",
                                          "demorgan_bitvector_saturation",
                                          "bitwise_zext_sext_factoring",
                                          "bitwise_common_mask_factoring",
                                          "constant_rotate_idiom_saturation",
                                          "path_sensitive_dominating_constraints",
                                          "symbolic_rotate_bswap_bitreverse_slices",
                                          "exact_diamond_phi_path_state_ite",
                                          "exact_switch_funnel_phi_path_state_ite",
                                          "inductive_constant_phi_resolution",
                                          "cyclic_predicate_z3_induction",
                                          "multi_incoming_default_state_induction",
                                          "memoryssa_exact_reaching_store_slices",
                                          "poison_support_equivalence_gate",
                                          "x86_zf_sf_cf_of_pf_predicate_recovery",
                                          "x86_add_carry_sub_borrow_recovery",
                                          "x86_low_byte_parity_recovery",
                                          "x86_terminal_condition_code_recovery",
                                          "producer_wide_sub_flag_bundle_transaction",
                                          "producer_wide_add_flag_bundle_transaction",
                                          "producer_wide_test_flag_bundle_transaction",
                                          "fixed_point_proof_reconciliation",
                                          "differential_validation_harness"}},
      {"unimplemented_components",
       json::Array{}},
      {"component_coverage", json::Object{
          {"P00", "implemented: inventory plus persistent frame intervals"},
          {"P01", "implemented: lifted poison-flag sanitization"},
          {"P02", "upstream: wrapper/runtime materialization passes"},
          {"P03", "implemented across the pipeline: persistent affine frame intervals and overlap views feed global/argument/non-escaping-local byte-accurate State SSA promotion, while the strict native post-pass compacts only fully proved constant frame objects and retains unknown escapes as barriers"},
          {"P04", "upstream: global/argument and non-escaping local byte-accurate overlapping-view State SSA with call/return synchronization"},
          {"P05", "implemented for canonical lifted cmp/sub, add, and test/and flag bundles: subtraction transactionally recovers ZF/NZ/SF/OF/CF/PF plus E/NE/B/AE/BE/A/L/GE/LE/G, addition recovers ZF/NZ/SF/OF/CF/PF, and TEST recovers ZF/NZ/SF/PF while architectural CF/OF are constant zero; every transaction requires complete internal-use coverage, identical poison support, and one old/new tuple Z3 proof, with PF taken strictly from the low byte at wider widths"},
          {"P06", "upstream: devirtualization/address/call recovery passes"},
          {"P10", "implemented: exact APInt/BV canonicalization"},
          {"P20", "implemented: conservative cyclic dispatcher classifier"},
          {"P21", "implemented for pure equality ladders"},
          {"P22", "implemented for proved SSA/memory recurrences and invertible encodings"},
          {"P23", "implemented as a bounded fail-closed CFG/transition executor: APInt BV semantics cover casts, in-range shifts, rotate/bswap/bitreverse/ctpop/select; persistent frame values use exact reaching stores across up to 12 predecessor blocks, equal-value merges across eight paths, and synthesized proof-only PHIs for same-location stores on separate CFG arms; proven-disjoint ranges, single-block readnone/readonly summaries, constant loop invariants, and exhaustive multi-incoming default induction are supported; nested select/PHI forks enumerate at most 32 outcomes and require a Z3 finite-set proof, while irreducibly symbolic states use an exact cloned encoded switch only with cloneable plumbing and PHI-free targets; unknown aliasing, unsupported effects, cycles outside proved induction, and cap hits are explicit barriers rather than guessed transitions"},
          {"P24", "implemented for complete proved transition sets including multi-incoming SSA dispatchers with self-looping defaults; residual-strict otherwise"},
          {"P30", "implemented for bounded proof slices: SSA plus SAT-checked dominating branch/assume constraints, symbolic modulo-width rotates, bswap/bitreverse/ctpop, exact diamond/switch-funnel PHIs as ITEs, inductively proved constant cyclic PHIs, exact MemorySSA stores and equal-value MemoryPhi joins; nonconstant one-PHI cyclic predicates additionally require universal Z3 seed/backedge 1-induction, while unsupported operations and multi-PHI cyclic relations remain explicit barriers"},
          {"P31", "implemented: theorem library plus Z3 UNSAT gate"},
          {"P32", "implemented: proved-edge pruning only"},
          {"P40", "implemented: exact OLLVM substitution templates"},
          {"P41", "implemented for bounded pure integer regions: affine/AC saturation, De Morgan, zext/sext and common-mask factoring, constant rotate recovery, dominating multi-root affine and AC extraction, plus mixed-operator semantic e-classes across different AST shapes; mixed extraction is capped at 40 nodes/32 roots/96 candidate comparisons, reuses only a cheaper dominating representative, requires at least two non-representative roots, identical poison support, and one final tuple Z3 proof"},
          {"P42", "implemented: identical poison support plus Z3 equivalence required per rewrite"},
          {"P50", "implemented in production driver: semantic fixed point"},
          {"P60", "implemented: JSON/metadata proof ledger v2"}}},
      {"module", M.getName().str()},
      {"inventory", json::Object{
          {"defined_functions", Inventory.DefinedFunctions},
          {"runtime_helpers", Inventory.RuntimeHelpers},
          {"small_wrapper_candidates", Inventory.SmallWrapperCandidates},
          {"frame_backing_globals", Inventory.FrameBackingGlobals},
          {"state_struct_types", Inventory.StateStructTypes},
          {"inline_asm_calls", Inventory.InlineAsmCalls},
          {"indirect_calls", Inventory.IndirectCalls},
          {"indirect_branches", Inventory.IndirectBranches},
          {"address_conversions", Inventory.AddressConversions},
          {"undef_operands", Inventory.UndefOperands},
          {"poison_operands", Inventory.PoisonOperands},
          {"conditional_branches", Inventory.ConditionalBranches},
          {"constant_compare_branches", Inventory.ConstantCompareBranches},
          {"candidate_state_locations", std::move(StateLocations)},
          {"frame_objects", std::move(FrameObjects)}}},
      {"metrics", json::Object{{"functions", Stats.Functions},
                                {"switches", Stats.Switches},
                                {"large_switches", Stats.LargeSwitches},
                                {"lifted_functions", Stats.LiftedFunctions},
                                {"flags_sanitized", Stats.FlagsSanitized},
                                {"flag_cones_recovered",
                                 Stats.FlagConesRecovered},
                                {"bv_rewrites", Stats.BVRewrites},
                                {"instsub_rewrites", Stats.InstSubRewrites},
                                {"opaque_edges_pruned", Stats.OpaqueEdgesPruned},
                                {"path_constrained_opaque_edges",
                                 Stats.PathConstrainedOpaqueEdges},
                                {"memoryssa_constrained_opaque_edges",
                                 Stats.MemorySSAConstrainedOpaqueEdges},
                                {"path_state_ite_opaque_edges",
                                 Stats.PathStateITEOpaqueEdges},
                                {"inductive_phi_opaque_edges",
                                 Stats.InductivePhiOpaqueEdges},
                                {"memoryssa_reaching_loads",
                                 Stats.MemorySSAReachingLoads},
                                {"memoryssa_phis_resolved",
                                 Stats.MemorySSAPhisResolved},
                                {"memoryssa_barriers",
                                 Stats.MemorySSABarriers},
                                {"compare_ladders_recovered",
                                 Stats.CompareLaddersRecovered},
                                {"egraph_rewrites", Stats.EGraphRewrites},
                                {"poison_support_rejects",
                                 Stats.PoisonSupportRejects},
                                {"dispatchers_recovered", Stats.DispatchersRecovered},
                                {"dispatchers_unresolved", Stats.DispatchersUnresolved},
                                {"verifier_failures", Stats.VerifierFailures}}},
      {"proofs", std::move(Records)}};
  std::error_code EC;
  raw_fd_ostream OS(ReportPath, EC);
  if (EC) {
    errs() << "ollvm-deobf: cannot write report: " << EC.message() << '\n';
    return;
  }
  OS << formatv("{0:2}\n", json::Value(std::move(Root)));
}

} // namespace

PreservedAnalyses OLLVMDeobfPass::run(Module &M,
                                      ModuleAnalysisManager &MAM) {
  Metrics Stats;
  LiftProfile Inventory = inventoryModule(M);
  importExistingInventory(M, Inventory);
  SmallVector<ProofRecord, 64> Proofs;
  importExistingProofs(M, Stats, Proofs);
  bool Changed = false;
  FunctionAnalysisManager &FAM =
      MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    ++Stats.Functions;
    for (BasicBlock &BB : F)
      if (auto *SI = dyn_cast<SwitchInst>(BB.getTerminator())) {
        ++Stats.Switches;
        if (SI->getNumCases() >= 4) ++Stats.LargeSwitches;
    }
    MemorySSA &MSSA = FAM.getResult<MemorySSAAnalysis>(F).getMSSA();
    Changed |= sanitizeLiftedFunction(F, Stats, Proofs);
    Changed |= rewriteFunction(F, MSSA, Stats, Proofs);
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootGeneralBVRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootAffineBVRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    Changed |= rewriteAffineBVRegions(F, Stats, Proofs);
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootAffineBVRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootACBitVectorRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    Changed |= rewriteACBitVectorRegions(F, Stats, Proofs);
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootACBitVectorRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    Changed |= recoverCompareLadders(F, Stats, Proofs);
    Changed |= recoverDispatchers(F, Stats, Proofs);
  }
  reconcileDispatcherProofs(M, Stats, Proofs);
  addModuleMetadata(M, Stats, Inventory, Proofs);
  Changed = true; // inventory and proof metadata are intentionally emitted.
  if (verifyModule(M, &errs())) {
    ++Stats.VerifierFailures;
    report_fatal_error("OLLVM deobfuscation produced invalid IR");
  }
  writeReport(M, Stats, Inventory, Proofs);
  errs() << "ollvm-deobf: functions=" << Stats.Functions
         << " switches=" << Stats.Switches
         << " bv_rewrites=" << Stats.BVRewrites
         << " instsub_rewrites=" << Stats.InstSubRewrites
         << " egraph_rewrites=" << Stats.EGraphRewrites
         << " opaque_edges_pruned=" << Stats.OpaqueEdgesPruned << '\n';
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_ollvm_deobf

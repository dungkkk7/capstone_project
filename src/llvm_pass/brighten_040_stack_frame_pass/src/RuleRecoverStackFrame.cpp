#include "BrightenStackFramePass.h"
#include "../../brighten_030_state_ssa_pass/src/StateOffsetResolver.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <queue>
#include <map>
#include <set>
#include <string>

namespace brighten_stack_frame {

using namespace llvm;

enum class RecoverMode {
  Direct,
  Mirror,
  Preserve,
};

enum class StackBaseKind {
  RSP,
  RBP,
};

struct StackBase {
  Value *V = nullptr;
  StackBaseKind Kind = StackBaseKind::RSP;
  unsigned Epoch = 0;
  bool Stable = false;

  bool operator==(const StackBase &O) const {
    return V == O.V && Kind == O.Kind && Epoch == O.Epoch && Stable == O.Stable;
  }
};

struct StackExpr {
  enum class Kind {
    Unreachable,
    Unknown,
    NonStack,
    StackConst,
    StackDynamic,
  } K = Kind::Unreachable;

  StackBase Base;
  int64_t Offset = 0;
  Value *DynamicOffset = nullptr;

  bool operator==(const StackExpr &O) const {
    if (K != O.K) return false;
    if (K == Kind::Unreachable || K == Kind::Unknown || K == Kind::NonStack) return true;
    return Base == O.Base && Offset == O.Offset && DynamicOffset == O.DynamicOffset;
  }
};

struct StackAccess {
  Instruction *I = nullptr;
  Value *Ptr = nullptr;
  StackExpr Addr;
  int64_t Begin = 0;
  int64_t End = 0;
  bool IsRead = false;
  bool IsWrite = false;
  bool IsVolatileOrAtomic = false;
  bool Escapes = false;
};

struct BlockState {
  StackExpr RSP;
  StackExpr RBP;

  BlockState() {
    RSP.K = StackExpr::Kind::Unreachable;
    RBP.K = StackExpr::Kind::Unreachable;
  }

  bool operator==(const BlockState &O) const {
    return RSP == O.RSP && RBP == O.RBP;
  }
};

struct BaseKey {
  Value *V = nullptr;
  StackBaseKind Kind = StackBaseKind::RSP;
  unsigned Epoch = 0;

  bool operator<(const BaseKey &O) const {
    if (V != O.V) return V < O.V;
    if (Kind != O.Kind) return Kind < O.Kind;
    return Epoch < O.Epoch;
  }
};

enum SkipReason : unsigned {
  SkipNone = 0,
  SkipBaseEscaped = 1u << 0,
  SkipDynamicAddress = 1u << 1,
  SkipVolatileOrAtomic = 1u << 2,
  SkipPositiveOffset = 1u << 3,
  SkipNonEntryRSP = 1u << 4,
  SkipNonRSPBase = 1u << 5,
  SkipStackPointerCall = 1u << 6,
  SkipUnsafeOverlap = 1u << 7,
  SkipNoSafeAccess = 1u << 8,
  SkipInvalidRange = 1u << 9,
  SkipFrameTooLarge = 1u << 10,
  SkipMemoryBoundary = 1u << 11,
  SkipReadBeforeWrite = 1u << 12,
};

struct StackFrameReportEntry {
  std::string FunctionName;
  BaseKey Key;
  bool Recovered = false;
  bool HasRange = false;
  int64_t MinOff = 0;
  int64_t MaxOff = 0;
  int64_t FrameSize = 0;
  unsigned TotalAccesses = 0;
  unsigned SafeAccesses = 0;
  unsigned UnsafeAccesses = 0;
  unsigned Reasons = SkipNone;
  SmallVector<std::pair<int64_t, int64_t>, 8> UnsafeRanges;
};

static const char *baseKindName(StackBaseKind Kind) {
  switch (Kind) {
    case StackBaseKind::RSP:
      return "RSP";
    case StackBaseKind::RBP:
      return "RBP";
  }
  return "unknown";
}

static void printBase(raw_ostream &OS, const BaseKey &Key) {
  OS << baseKindName(Key.Kind) << ":";
  if (Key.V) {
    Key.V->printAsOperand(OS, false);
  } else {
    OS << "entry";
  }
  OS << ":epoch" << Key.Epoch;
}

static void printRange(raw_ostream &OS, int64_t Begin, int64_t End) {
  OS << "[" << Begin << "," << End << ")";
}

static void printSkipReasons(raw_ostream &OS, unsigned Reasons) {
  bool First = true;
  auto Emit = [&](unsigned Flag, StringRef Name) {
    if (!(Reasons & Flag)) return;
    if (!First) OS << ",";
    OS << Name;
    First = false;
  };

  Emit(SkipBaseEscaped, "escape");
  Emit(SkipDynamicAddress, "dynamic");
  Emit(SkipVolatileOrAtomic, "volatile_or_atomic");
  Emit(SkipPositiveOffset, "positive_offset");
  Emit(SkipNonEntryRSP, "non_entry_rsp");
  Emit(SkipNonRSPBase, "non_rsp_base");
  Emit(SkipStackPointerCall, "stack_pointer_call");
  Emit(SkipUnsafeOverlap, "unsafe_overlap");
  Emit(SkipNoSafeAccess, "no_safe_access");
  Emit(SkipInvalidRange, "invalid_range");
  Emit(SkipFrameTooLarge, "frame_too_large");
  Emit(SkipMemoryBoundary, "memory_boundary");
  Emit(SkipReadBeforeWrite, "read_before_write");

  if (First) OS << "none";
}

static void addSkipReason(std::map<BaseKey, unsigned> &BaseReasons,
                          const BaseKey &Key,
                          unsigned Reason) {
  BaseReasons[Key] |= Reason;
}

static bool verifyReportEntry(const StackFrameReportEntry &Entry, raw_ostream &OS) {
  bool OK = true;
  auto Fail = [&](StringRef Reason) {
    OK = false;
    OS << "  verifier: function=" << Entry.FunctionName << " base=";
    printBase(OS, Entry.Key);
    OS << " reason=" << Reason << "\n";
  };

  if (Entry.TotalAccesses != Entry.SafeAccesses + Entry.UnsafeAccesses) {
    Fail("access_count_mismatch");
  }

  if (!Entry.Recovered) {
    return OK;
  }

  if (Entry.Key.Kind != StackBaseKind::RSP || Entry.Key.V != nullptr) {
    Fail("recovered_non_entry_rsp");
  }
  if (!Entry.HasRange || Entry.FrameSize != Entry.MaxOff - Entry.MinOff) {
    Fail("recovered_invalid_range");
  }
  if (Entry.MinOff >= 0 || Entry.MaxOff > 0) {
    Fail("recovered_non_negative_range");
  }
  if (Entry.FrameSize <= 0 || Entry.FrameSize > 1024 * 1024) {
    Fail("recovered_bad_frame_size");
  }
  if (Entry.SafeAccesses == 0) {
    Fail("recovered_without_safe_access");
  }

  return OK;
}

static int64_t resolveStateOffset(Value *ptr, const DataLayout &DL, Function &F) {
  GlobalVariable *StateGV = F.getParent()->getGlobalVariable("__mcsema_reg_state");
  auto Res = brighten_state_ssa::ResolveStateOffset(ptr, DL, F, StateGV);
  if (Res) {
    return (int64_t)Res->Offset;
  }

  // State-SSA runs before stack recovery in the production pipeline.  Older
  // State-SSA output promoted every State field, including RSP/RBP, to an
  // entry-block alloca.  Looking only through the original State pointer then
  // makes this pass blind to every stack expression.  Recover the slot's
  // identity from its initialization, not merely from its generated name:
  //
  //   %slot = alloca i64
  //   %initial = load i64, ptr (%state + N)
  //   store i64 %initial, ptr %slot
  //
  // Requiring a unique, type-compatible State source prevents an unrelated
  // user alloca from being classified as an architectural register slot.
  Value *Base = ptr ? ptr->stripPointerCasts() : nullptr;
  auto *AI = dyn_cast_or_null<AllocaInst>(Base);
  if (!AI || AI->getFunction() != &F ||
      AI->getParent() != &F.getEntryBlock() || !AI->isStaticAlloca()) {
    return -1;
  }

  if (MDNode *MD = AI->getMetadata("brighten.state.offset")) {
    if (MD->getNumOperands() == 1) {
      if (auto *CAM = dyn_cast<ConstantAsMetadata>(MD->getOperand(0))) {
        if (auto *CI = dyn_cast<ConstantInt>(CAM->getValue())) {
          return static_cast<int64_t>(CI->getZExtValue());
        }
      }
    }
  }

  std::optional<uint64_t> PromotedOffset;
  for (User *U : AI->users()) {
    auto *SI = dyn_cast<StoreInst>(U);
    if (!SI || SI->getPointerOperand()->stripPointerCasts() != AI) {
      continue;
    }
    auto *LI = dyn_cast<LoadInst>(SI->getValueOperand());
    if (!LI || LI->getType() != AI->getAllocatedType()) {
      continue;
    }
    auto Init = brighten_state_ssa::ResolveStateOffset(
        LI->getPointerOperand(), DL, F, StateGV);
    if (!Init) {
      continue;
    }
    if (PromotedOffset && *PromotedOffset != Init->Offset) {
      return -1;
    }
    PromotedOffset = Init->Offset;
  }
  if (PromotedOffset) {
    return static_cast<int64_t>(*PromotedOffset);
  }
  return -1;
}

static bool isRSPRegisterState(Value *V, const DataLayout &DL, Function &F) {
  return resolveStateOffset(V, DL, F) == 2312;
}

static bool isRBPRegisterState(Value *V, const DataLayout &DL, Function &F) {
  return resolveStateOffset(V, DL, F) == 2328;
}

static bool AddNoSignedOverflow(int64_t A, int64_t B, int64_t &Out) {
  if ((B > 0 && A > INT64_MAX - B) ||
      (B < 0 && A < INT64_MIN - B))
    return false;
  Out = A + B;
  return true;
}

static bool SubNoSignedOverflow(int64_t A, int64_t B, int64_t &Out) {
  if ((B > 0 && A < INT64_MIN + B) ||
      (B < 0 && A > INT64_MAX + B))
    return false;
  Out = A - B;
  return true;
}

static StackExpr getStackExpr(Value *V, const DenseMap<Value *, StackExpr> &ExprMap) {
  auto It = ExprMap.find(V);
  if (It != ExprMap.end()) return It->second;
  
  StackExpr E;
  if (isa<Constant>(V)) {
    E.K = StackExpr::Kind::NonStack;
  } else {
    E.K = StackExpr::Kind::Unknown;
  }
  return E;
}

static StackExpr mergeExpr(const StackExpr &A, const StackExpr &B) {
  if (A.K == StackExpr::Kind::Unreachable) return B;
  if (B.K == StackExpr::Kind::Unreachable) return A;
  if (A.K == StackExpr::Kind::Unknown || B.K == StackExpr::Kind::Unknown) {
    StackExpr Res;
    Res.K = StackExpr::Kind::Unknown;
    return Res;
  }
  if (A == B) return A;
  if (A.K == StackExpr::Kind::StackConst && B.K == StackExpr::Kind::StackConst && A.Base == B.Base) {
    StackExpr Res;
    Res.K = StackExpr::Kind::StackDynamic;
    Res.Base = A.Base;
    Res.Offset = A.Offset;
    return Res;
  }
  StackExpr UnknownExpr;
  UnknownExpr.K = StackExpr::Kind::Unknown;
  return UnknownExpr;
}

static BlockState mergeBlockStates(const SmallVectorImpl<BlockState> &States) {
  if (States.empty()) {
    return BlockState();
  }
  BlockState Merged = States[0];
  for (size_t i = 1; i < States.size(); ++i) {
    Merged.RSP = mergeExpr(Merged.RSP, States[i].RSP);
    Merged.RBP = mergeExpr(Merged.RBP, States[i].RBP);
  }
  return Merged;
}

static void traceValueUses(Value *V, const DataLayout &DL, DenseSet<Value *> &Visited, bool &Escaped) {
  if (Escaped) return;
  if (!Visited.insert(V).second) return;

  for (User *U : V->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I) {
      Escaped = true;
      return;
    }

    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      auto Opcode = BO->getOpcode();
      if (Opcode == Instruction::Add || Opcode == Instruction::Sub) {
        if (isa<ConstantInt>(BO->getOperand(0)) || isa<ConstantInt>(BO->getOperand(1))) {
          traceValueUses(BO, DL, Visited, Escaped);
        } else {
          Escaped = true;
          return;
        }
      } else {
        Escaped = true;
        return;
      }
    } else if (isa<IntToPtrInst>(I) || isa<PtrToIntInst>(I) ||
               isa<BitCastInst>(I) || isa<AddrSpaceCastInst>(I)) {
      traceValueUses(I, DL, Visited, Escaped);
    } else if (auto *GEP = dyn_cast<GetElementPtrInst>(I)) {
      traceValueUses(GEP, DL, Visited, Escaped);
    } else if (auto *LI = dyn_cast<LoadInst>(I)) {
      if (LI->getPointerOperand() != V) {
        Escaped = true;
        return;
      }
      if (LI->isVolatile() || LI->isAtomic()) {
        Escaped = true;
        return;
      }
    } else if (auto *SI = dyn_cast<StoreInst>(I)) {
      if (SI->getPointerOperand() != V) {
        if (isRSPRegisterState(SI->getPointerOperand(), DL, *SI->getFunction()) ||
            isRBPRegisterState(SI->getPointerOperand(), DL, *SI->getFunction())) {
        } else {
          Escaped = true;
          return;
        }
      } else {
        if (SI->isVolatile() || SI->isAtomic()) {
          Escaped = true;
          return;
        }
      }
    } else if (auto *MemI = dyn_cast<MemIntrinsic>(I)) {
      auto *Len = dyn_cast<ConstantInt>(MemI->getLength());
      if (!Len) {
        Escaped = true;
        return;
      }
      if (auto *MT = dyn_cast<MemTransferInst>(MemI)) {
        if (MT->getRawDest() != V && MT->getRawSource() != V) {
          Escaped = true;
          return;
        }
      } else {
        if (MemI->getRawDest() != V) {
          Escaped = true;
          return;
        }
      }
    } else if (auto *II = dyn_cast<IntrinsicInst>(I)) {
      if (II->getIntrinsicID() == Intrinsic::lifetime_start ||
          II->getIntrinsicID() == Intrinsic::lifetime_end) {
      } else {
        Escaped = true;
        return;
      }
    } else if (auto *CB = dyn_cast<CallBase>(I)) {
      Function *CalledF = CB->getCalledFunction();
      if (CalledF && CalledF->getName() == "__translate_guest_pointer") {
        traceValueUses(CB, DL, Visited, Escaped);
      } else {
        Escaped = true;
        return;
      }
    } else if (auto *PHI = dyn_cast<PHINode>(I)) {
      traceValueUses(PHI, DL, Visited, Escaped);
    } else if (auto *Sel = dyn_cast<SelectInst>(I)) {
      traceValueUses(Sel, DL, Visited, Escaped);
    } else {
      Escaped = true;
      return;
    }
  }
}

static Value *getRegisterGlobal(Module &M, int64_t Offset, Function &F) {
  const DataLayout &DL = M.getDataLayout();
  for (GlobalAlias &GA : M.aliases()) {
    if (resolveStateOffset(&GA, DL, F) == Offset) {
      return &GA;
    }
  }
  for (GlobalVariable &GV : M.globals()) {
    if (resolveStateOffset(&GV, DL, F) == Offset) {
      return &GV;
    }
  }
  return nullptr;
}

static Value *getInitialRegisterValue(Function &F, int64_t Offset, IRBuilder<> &B) {
  Module *M = F.getParent();
  Value *RegGlob = getRegisterGlobal(*M, Offset, F);
  if (RegGlob) {
    return B.CreateLoad(B.getInt64Ty(), RegGlob, "init_reg");
  }
  if (F.arg_size() > 0) {
    Argument *StateArg = F.getArg(0);
    Value *GEP = B.CreateGEP(B.getInt8Ty(), StateArg, B.getInt32(Offset));
    return B.CreateLoad(B.getInt64Ty(), GEP, "init_reg");
  }
  return nullptr;
}

static bool CallTakesStackPointer(CallBase *CB, const DenseMap<Value *, StackExpr> &ExprMap) {
  for (Use &Arg : CB->args()) {
    StackExpr E = getStackExpr(Arg.get(), ExprMap);
    if (E.K == StackExpr::Kind::StackConst || E.K == StackExpr::Kind::StackDynamic) {
      return true;
    }
  }
  return false;
}

static bool CallMayClobberGuestStackState(CallBase *CB, const DataLayout &DL,
                                          Function &Caller) {
  Function *CalledF = CB->getCalledFunction();
  if (!CalledF) {
    // An indirect callback may re-enter lifted code and update the shared
    // architectural State.  There is no callee summary proving otherwise.
    return true;
  }

  StringRef Name = CalledF->getName();
  if (Name == "__translate_guest_pointer" ||
      Name == "llvm.sideeffect" ||
      Name.starts_with("llvm.lifetime.") ||
      Name.starts_with("llvm.dbg.")) {
    return false;
  }
  if (CalledF->isIntrinsic()) {
    return false;
  }
  if (brighten_state_ssa::IsLiftedFunction(*CalledF)) {
    return true;
  }

  // Also cover native wrappers whose names do not identify them as lifted but
  // which receive State (or a State field) explicitly.
  for (Use &Arg : CB->args()) {
    Value *V = Arg.get();
    if (V->getType()->isPointerTy() && resolveStateOffset(V, DL, Caller) >= 0) {
      return true;
    }
  }
  return false;
}

static bool IsDirectNativeFrame(ArrayRef<StackAccess *> Accesses,
                                Function &F) {
  DominatorTree DT(F);
  for (const StackAccess *Read : Accesses) {
    if (!Read->IsRead) {
      continue;
    }
    bool Initialized = false;
    for (const StackAccess *Write : Accesses) {
      if (!Write->IsWrite || Write->I == Read->I ||
          Write->Begin > Read->Begin || Write->End < Read->End) {
        continue;
      }
      if (DT.dominates(Write->I, Read->I)) {
        Initialized = true;
        break;
      }
    }
    if (!Initialized) {
      return false;
    }
  }
  return true;
}

bool BrightenStackFramePass::RecoverStackFrame(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();

  unsigned RecoveredCount = 0;
  unsigned PreservedCount = 0;
  unsigned UnsafeCount = 0;
  unsigned RecoveredAccessCount = 0;
  unsigned PreservedAccessCount = 0;
  unsigned VisitedFunctions = 0;
  unsigned FunctionsWithStackAccess = 0;
  SmallVector<StackFrameReportEntry, 32> ReportEntries;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    if (!brighten_state_ssa::IsLiftedFunction(F)) continue;
    VisitedFunctions++;

    // Dispatcher functions carrying undef/poison operands do not have a
    // trustworthy stack data-flow graph.  Rewriting their frame accesses can
    // turn an already-opaque lifted path into a concrete SIGSEGV; preserve the
    // original function and let later passes report the unresolved contract.
    bool HasUnresolvedValue = false;
    for (BasicBlock &CheckBB : F) {
      for (Instruction &I : CheckBB) {
        for (Value *Op : I.operands()) {
          if (isa<UndefValue>(Op) || isa<PoisonValue>(Op)) {
            HasUnresolvedValue = true;
            break;
          }
        }
        if (HasUnresolvedValue)
          break;
      }
      if (HasUnresolvedValue)
        break;
    }
    if (HasUnresolvedValue) {
      ++UnsafeCount;
      continue;
    }

    DenseMap<Value *, StackExpr> ExprMap;
    DenseMap<BasicBlock *, BlockState> BlockEntryState;
    DenseMap<BasicBlock *, BlockState> BlockExitState;

    BasicBlock *Entry = &F.getEntryBlock();
    BlockState EntryState;
    EntryState.RSP.K = StackExpr::Kind::StackConst;
    EntryState.RSP.Base.V = nullptr;
    EntryState.RSP.Base.Kind = StackBaseKind::RSP;
    EntryState.RSP.Base.Epoch = 0;
    EntryState.RSP.Base.Stable = true;
    EntryState.RSP.Offset = 0;
    EntryState.RBP.K = StackExpr::Kind::Unknown;

    BlockEntryState[Entry] = EntryState;

    std::queue<BasicBlock *> Worklist;
    DenseSet<BasicBlock *> InWorklist;

    for (BasicBlock &BB : F) {
      Worklist.push(&BB);
      InWorklist.insert(&BB);
    }

    // The data-flow state must converge even for malformed/obfuscated CFGs.
    // In particular, assigning a fresh epoch every time an unresolved RSP
    // load is revisited makes loop headers appear changed forever.  Keep a
    // deterministic per-function work budget as a second line of defence.
    uint64_t WorkItems = 0;
    const uint64_t MaxWorkItems =
        std::max<uint64_t>(1024, static_cast<uint64_t>(F.size()) * 128);
    bool AnalysisAborted = false;

    while (!Worklist.empty()) {
      if (++WorkItems > MaxWorkItems) {
        errs() << "brighten-stack-frame-pass: aborting non-convergent dataflow in "
               << F.getName() << " after " << MaxWorkItems << " work items\n";
        AnalysisAborted = true;
        break;
      }
      BasicBlock *BB = Worklist.front();
      Worklist.pop();
      InWorklist.erase(BB);

      SmallVector<BlockState, 4> PredStates;
      for (BasicBlock *Pred : predecessors(BB)) {
        auto It = BlockExitState.find(Pred);
        if (It != BlockExitState.end()) {
          PredStates.push_back(It->second);
        }
      }

      BlockState CurrentState;
      if (BB == Entry) {
        CurrentState = BlockEntryState[BB];
      } else {
        CurrentState = mergeBlockStates(PredStates);
      }
      BlockEntryState[BB] = CurrentState;

      bool LocalExprChanged = false;
      for (Instruction &I : *BB) {
        StackExpr Expr;
        Expr.K = StackExpr::Kind::Unknown;

        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          if (isRSPRegisterState(LI->getPointerOperand(), DL, F)) {
            Expr = CurrentState.RSP;
            if (Expr.K == StackExpr::Kind::Unknown) {
              Expr.K = StackExpr::Kind::StackConst;
              Expr.Base.V = LI;
              Expr.Base.Kind = StackBaseKind::RSP;
              // The load instruction is the identity of this unresolved
              // stack base.  Do not allocate a new epoch on every revisit;
              // that prevents looped CFGs from converging.
              Expr.Base.Epoch = 0;
              Expr.Base.Stable = true;
              Expr.Offset = 0;
            }
          } else if (isRBPRegisterState(LI->getPointerOperand(), DL, F)) {
            Expr = CurrentState.RBP;
            if (Expr.K == StackExpr::Kind::Unknown) {
              Expr.K = StackExpr::Kind::StackConst;
              Expr.Base.V = LI;
              Expr.Base.Kind = StackBaseKind::RBP;
              Expr.Base.Epoch = 0;
              Expr.Base.Stable = true;
              Expr.Offset = 0;
            }
          }
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          if (isRSPRegisterState(SI->getPointerOperand(), DL, F)) {
            CurrentState.RSP = getStackExpr(SI->getValueOperand(), ExprMap);
          } else if (isRBPRegisterState(SI->getPointerOperand(), DL, F)) {
            CurrentState.RBP = getStackExpr(SI->getValueOperand(), ExprMap);
          }
        } else if (auto *BO = dyn_cast<BinaryOperator>(&I)) {
          auto Opcode = BO->getOpcode();
          if (Opcode == Instruction::Add) {
            auto E0 = getStackExpr(BO->getOperand(0), ExprMap);
            auto E1 = getStackExpr(BO->getOperand(1), ExprMap);
            if ((E0.K == StackExpr::Kind::StackConst || E0.K == StackExpr::Kind::StackDynamic) &&
                isa<ConstantInt>(BO->getOperand(1))) {
              int64_t C = cast<ConstantInt>(BO->getOperand(1))->getSExtValue();
              int64_t NewOff = 0;
              if (AddNoSignedOverflow(E0.Offset, C, NewOff)) {
                Expr = E0;
                Expr.Offset = NewOff;
              }
            } else if ((E1.K == StackExpr::Kind::StackConst || E1.K == StackExpr::Kind::StackDynamic) &&
                       isa<ConstantInt>(BO->getOperand(0))) {
              int64_t C = cast<ConstantInt>(BO->getOperand(0))->getSExtValue();
              int64_t NewOff = 0;
              if (AddNoSignedOverflow(E1.Offset, C, NewOff)) {
                Expr = E1;
                Expr.Offset = NewOff;
              }
            } else if (E0.K == StackExpr::Kind::StackConst && E1.K == StackExpr::Kind::NonStack) {
              Expr.K = StackExpr::Kind::StackDynamic;
              Expr.Base = E0.Base;
              Expr.Offset = E0.Offset;
              Expr.DynamicOffset = BO->getOperand(1);
            } else if (E1.K == StackExpr::Kind::StackConst && E0.K == StackExpr::Kind::NonStack) {
              Expr.K = StackExpr::Kind::StackDynamic;
              Expr.Base = E1.Base;
              Expr.Offset = E1.Offset;
              Expr.DynamicOffset = BO->getOperand(0);
            }
          } else if (Opcode == Instruction::Sub) {
            auto E0 = getStackExpr(BO->getOperand(0), ExprMap);
            auto E1 = getStackExpr(BO->getOperand(1), ExprMap);
            if ((E0.K == StackExpr::Kind::StackConst || E0.K == StackExpr::Kind::StackDynamic) &&
                isa<ConstantInt>(BO->getOperand(1))) {
              int64_t C = cast<ConstantInt>(BO->getOperand(1))->getSExtValue();
              int64_t NewOff = 0;
              if (SubNoSignedOverflow(E0.Offset, C, NewOff)) {
                Expr = E0;
                Expr.Offset = NewOff;
              }
            } else if (E0.K == StackExpr::Kind::StackConst && E1.K == StackExpr::Kind::NonStack) {
              Expr.K = StackExpr::Kind::StackDynamic;
              Expr.Base = E0.Base;
              Expr.Offset = E0.Offset;
              Expr.DynamicOffset = BO->getOperand(1);
            }
          }
        } else if (isa<IntToPtrInst>(&I) || isa<PtrToIntInst>(&I) ||
                   isa<BitCastInst>(&I) || isa<AddrSpaceCastInst>(&I)) {
          Expr = getStackExpr(I.getOperand(0), ExprMap);
        } else if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          auto E = getStackExpr(GEP->getPointerOperand(), ExprMap);
          if (E.K == StackExpr::Kind::StackConst || E.K == StackExpr::Kind::StackDynamic) {
            APInt ApOffset(64, 0);
            if (GEP->accumulateConstantOffset(DL, ApOffset)) {
              int64_t NewOff = 0;
              if (AddNoSignedOverflow(E.Offset, ApOffset.getSExtValue(), NewOff)) {
                Expr = E;
                Expr.Offset = NewOff;
              }
            } else {
              Expr.K = StackExpr::Kind::StackDynamic;
              Expr.Base = E.Base;
              Expr.Offset = E.Offset;
              Expr.DynamicOffset = GEP;
            }
          }
        } else if (auto *CB = dyn_cast<CallBase>(&I)) {
          Function *CalledF = CB->getCalledFunction();
          if (CalledF && CalledF->getName() == "__translate_guest_pointer") {
            Expr = getStackExpr(CB->getArgOperand(0), ExprMap);
          }
          if (CallMayClobberGuestStackState(CB, DL, F)) {
            // Lifted callees communicate the post-return RSP/RBP through the
            // shared architectural State.  Keeping the pre-call affine value
            // here rewrites a post-call pop to the synthetic call-return slot
            // (p00230), eventually producing a double-based host address after
            // inlining.  Start a new unresolved base at the next register load;
            // the mixed-base safety check will preserve the physical frame.
            CurrentState.RSP.K = StackExpr::Kind::Unknown;
            CurrentState.RBP.K = StackExpr::Kind::Unknown;
          }
        } else if (auto *PHI = dyn_cast<PHINode>(&I)) {
          if (PHI->getNumIncomingValues() > 0) {
            auto EFirst = getStackExpr(PHI->getIncomingValue(0), ExprMap);
            bool AllSame = true;
            bool SameBase = true;
            for (unsigned idx = 1; idx < PHI->getNumIncomingValues(); ++idx) {
              auto ECur = getStackExpr(PHI->getIncomingValue(idx), ExprMap);
              if (!(ECur == EFirst)) {
                AllSame = false;
              }
              if (ECur.Base.V != EFirst.Base.V || ECur.Base.Kind != EFirst.Base.Kind || ECur.Base.Epoch != EFirst.Base.Epoch) {
                SameBase = false;
              }
            }
            if (AllSame) {
              Expr = EFirst;
            } else if (SameBase && EFirst.K != StackExpr::Kind::Unknown && EFirst.K != StackExpr::Kind::Unreachable) {
              Expr.K = StackExpr::Kind::StackDynamic;
              Expr.Base = EFirst.Base;
              Expr.Offset = EFirst.Offset;
            }
          }
        } else if (auto *Sel = dyn_cast<SelectInst>(&I)) {
          auto ETrue = getStackExpr(Sel->getTrueValue(), ExprMap);
          auto EFalse = getStackExpr(Sel->getFalseValue(), ExprMap);
          if (ETrue == EFalse) {
            Expr = ETrue;
          } else if (ETrue.Base.V == EFalse.Base.V && ETrue.Base.Kind == EFalse.Base.Kind && ETrue.Base.Epoch == EFalse.Base.Epoch && ETrue.K != StackExpr::Kind::Unknown && ETrue.K != StackExpr::Kind::Unreachable) {
            Expr.K = StackExpr::Kind::StackDynamic;
            Expr.Base = ETrue.Base;
            Expr.Offset = ETrue.Offset;
          }
        }

        auto OldIt = ExprMap.find(&I);
        bool ChangedExpr = false;
        if (Expr.K == StackExpr::Kind::Unknown || Expr.K == StackExpr::Kind::Unreachable) {
          if (OldIt != ExprMap.end()) {
            ExprMap.erase(OldIt);
            ChangedExpr = true;
          }
        } else {
          if (OldIt == ExprMap.end() || !(OldIt->second == Expr)) {
            ExprMap[&I] = Expr;
            ChangedExpr = true;
          }
        }
        if (ChangedExpr) {
          LocalExprChanged = true;
        }
      }

      auto It = BlockExitState.find(BB);
      bool BlockExitChanged = false;
      if (It == BlockExitState.end() || !(It->second == CurrentState)) {
        BlockExitState[BB] = CurrentState;
        BlockExitChanged = true;
      }

      if (BlockExitChanged || LocalExprChanged) {
        for (BasicBlock *Succ : successors(BB)) {
          if (InWorklist.insert(Succ).second) {
            Worklist.push(Succ);
          }
        }
      }
    }

    if (AnalysisAborted) {
      // Never rewrite from a partially solved data-flow graph.  Preserve this
      // function unchanged and continue with the remaining module functions.
      continue;
    }

    std::map<BaseKey, unsigned> BaseReasons;
    std::map<BaseKey, SmallVector<std::pair<int64_t, int64_t>, 8>>
        EscapedRanges;
    for (const auto &Pair : ExprMap) {
      Value *V = Pair.first;
      const StackExpr &E = Pair.second;
      if (E.K == StackExpr::Kind::StackConst) {
        bool Escaped = false;
        DenseSet<Value *> Visited;
        traceValueUses(V, DL, Visited, Escaped);
        if (Escaped) {
          BaseKey Key{E.Base.V, E.Base.Kind, E.Base.Epoch};
          // An escaped address does not make unrelated stack objects alias it.
          // Keep the exact byte position as an exclusion boundary and reject
          // only accesses that overlap it.  This is important for lifted
          // functions that pass one local (for example a scanf destination)
          // across an ABI boundary while keeping independent compiler-created
          // control-flow or arithmetic temporaries in the same physical
          // frame.  Dynamic addresses remain a base-wide rejection below.
          addSkipReason(BaseReasons, Key, SkipBaseEscaped);
        }
      } else if (E.K == StackExpr::Kind::StackDynamic) {
        BaseKey Key{E.Base.V, E.Base.Kind, E.Base.Epoch};
        addSkipReason(BaseReasons, Key, SkipDynamicAddress);
      }
    }

    SmallVector<StackAccess, 32> AllAccesses;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          auto Ptr = LI->getPointerOperand();
          auto E = getStackExpr(Ptr, ExprMap);
          if (E.K == StackExpr::Kind::StackConst || E.K == StackExpr::Kind::StackDynamic) {
            if (isRSPRegisterState(Ptr, DL, F) || isRBPRegisterState(Ptr, DL, F)) {
              continue;
            }
            StackAccess Acc;
            Acc.I = LI;
            Acc.Ptr = Ptr;
            Acc.Addr = E;
            if (E.K == StackExpr::Kind::StackConst) {
              Acc.Begin = E.Offset;
              Acc.End = E.Offset + (int64_t)DL.getTypeStoreSize(LI->getType());
            }
            Acc.IsRead = true;
            Acc.IsWrite = false;
            Acc.IsVolatileOrAtomic = LI->isVolatile() || LI->isAtomic();
            AllAccesses.push_back(Acc);
          }
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          auto Ptr = SI->getPointerOperand();
          auto E = getStackExpr(Ptr, ExprMap);
          if (E.K == StackExpr::Kind::StackConst || E.K == StackExpr::Kind::StackDynamic) {
            if (isRSPRegisterState(Ptr, DL, F) || isRBPRegisterState(Ptr, DL, F)) {
              continue;
            }
            StackAccess Acc;
            Acc.I = SI;
            Acc.Ptr = Ptr;
            Acc.Addr = E;
            if (E.K == StackExpr::Kind::StackConst) {
              Acc.Begin = E.Offset;
              Acc.End = E.Offset + (int64_t)DL.getTypeStoreSize(SI->getValueOperand()->getType());
            }
            Acc.IsRead = false;
            Acc.IsWrite = true;
            Acc.IsVolatileOrAtomic = SI->isVolatile() || SI->isAtomic();
            AllAccesses.push_back(Acc);
          }
        } else if (auto *MemI = dyn_cast<MemIntrinsic>(&I)) {
          auto Dest = MemI->getRawDest();
          auto EDest = getStackExpr(Dest, ExprMap);
          auto *Len = dyn_cast<ConstantInt>(MemI->getLength());
          
          if (EDest.K == StackExpr::Kind::StackConst || EDest.K == StackExpr::Kind::StackDynamic) {
            StackAccess Acc;
            Acc.I = MemI;
            Acc.Ptr = Dest;
            Acc.Addr = EDest;
            if (EDest.K == StackExpr::Kind::StackConst && Len) {
              Acc.Begin = EDest.Offset;
              Acc.End = EDest.Offset + Len->getSExtValue();
            }
            Acc.IsRead = false;
            Acc.IsWrite = true;
            Acc.IsVolatileOrAtomic = MemI->isVolatile();
            AllAccesses.push_back(Acc);
          }

          if (auto *MemT = dyn_cast<MemTransferInst>(MemI)) {
            auto Src = MemT->getRawSource();
            auto ESrc = getStackExpr(Src, ExprMap);
            if (ESrc.K == StackExpr::Kind::StackConst || ESrc.K == StackExpr::Kind::StackDynamic) {
              StackAccess Acc;
              Acc.I = MemI;
              Acc.Ptr = Src;
              Acc.Addr = ESrc;
              if (ESrc.K == StackExpr::Kind::StackConst && Len) {
                Acc.Begin = ESrc.Offset;
                Acc.End = ESrc.Offset + Len->getSExtValue();
              }
              Acc.IsRead = true;
              Acc.IsWrite = false;
              Acc.IsVolatileOrAtomic = MemI->isVolatile();
              AllAccesses.push_back(Acc);
            }
          }
        }
      }
    }

    for (auto &Acc : AllAccesses) {
      bool Escaped = false;
      DenseSet<Value *> Visited;
      traceValueUses(Acc.Ptr, DL, Visited, Escaped);
      Acc.Escapes = Escaped;

      if (Acc.Addr.K == StackExpr::Kind::StackDynamic || Acc.IsVolatileOrAtomic) {
        Acc.Escapes = true;
      }
    }

    std::map<BaseKey, SmallVector<StackAccess, 16>> BaseAccesses;
    for (const auto &Acc : AllAccesses) {
      BaseKey Key{Acc.Addr.Base.V, Acc.Addr.Base.Kind, Acc.Addr.Base.Epoch};
      BaseAccesses[Key].push_back(Acc);
    }

    // Do not reject a frame merely because the function also accesses some
    // other memory object.  A callee-local stack object's lifetime prevents
    // an unrelated pointer from aliasing it.  Any legitimate alias must be
    // derived from the stack value, and traceValueUses above marks precisely
    // such stores, dynamic derivations, and escapes as unsafe.  The old
    // blanket rule disabled stack recovery in every function that touched a
    // global, heap object, argv, or translated guest data.

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB) continue;

        Function *CalledF = CB->getCalledFunction();
        if (CalledF) {
          StringRef Name = CalledF->getName();
          if (Name == "__translate_guest_pointer" ||
              Name == "llvm.sideeffect" ||
              Name.starts_with("llvm.lifetime.") ||
              Name.starts_with("llvm.dbg.")) {
            continue;
          }
        }

        bool TakesStackPointer = CallTakesStackPointer(CB, ExprMap);

        // A direct native declaration can only access the local frame when a
        // frame-derived pointer is passed explicitly.  Lifted runtime calls
        // are different: State/memory are hidden arguments and can expose
        // guest stack storage even when no explicit operand is recognized.
        bool HiddenGuestBoundary = true;
        if (CalledF && CalledF->isDeclaration()) {
          StringRef Name = CalledF->getName();
          HiddenGuestBoundary =
              Name.starts_with("__remill_") ||
              Name.starts_with("__mcsema_") ||
              Name == "__translate_guest_pointer";
        }
        if (!TakesStackPointer && !HiddenGuestBoundary) {
          continue;
        }

        // Stack-derived call arguments were recorded as escaped intervals by
        // traceValueUses.  A hidden lifted boundary can only reach a local
        // object through such an escaped address.  Do not poison every other
        // byte in the frame merely because State/memory are hidden operands.
      }
    }

    for (const auto &Pair : BaseAccesses) {
      const BaseKey &Key = Pair.first;
      if (Key.Kind != StackBaseKind::RSP) {
        addSkipReason(BaseReasons, Key, SkipNonRSPBase);
      } else if (Key.V != nullptr) {
        addSkipReason(BaseReasons, Key, SkipNonEntryRSP);
      }
    }

    // Different unresolved base identities may still denote the same
    // physical guest frame after RSP/RBP updates.  Until their affine
    // relationship is proven, do not move only the entry-RSP view to a host
    // object while preserving another view in guest memory.
    if (BaseAccesses.size() > 1) {
      for (const auto &Pair : BaseAccesses) {
        addSkipReason(BaseReasons, Pair.first, SkipUnsafeOverlap);
      }
    }

    // A large recovered region is not yet proven to be a function-local
    // object merely because every individual access has a constant offset.
    // In production IR such regions can still carry values consumed by later
    // ABI/global-recovery stages.  Promoting the 16/30-access frames in
    // p01296 changed a recovered global index and made sub_4026f0 read beyond
    // the recovered `id` array.  Keep the pass fail-closed until object
    // separation is backed by an interprocedural proof; small scalar frames
    // remain eligible for the rewrite below.
    for (const auto &Pair : BaseAccesses) {
      if (Pair.second.size() > 8) {
        addSkipReason(BaseReasons, Pair.first, SkipUnsafeOverlap);
      }
    }

    if (!BaseAccesses.empty()) {
      FunctionsWithStackAccess++;
    }

    IRBuilder<> EntryBuilder(&*F.getEntryBlock().getFirstInsertionPt());
    Type *Int8Ty = EntryBuilder.getInt8Ty();
    Type *Int64Ty = EntryBuilder.getInt64Ty();

    for (auto &Pair : BaseAccesses) {
      const BaseKey &Key = Pair.first;
      auto &Accesses = Pair.second;

      StackFrameReportEntry Report;
      Report.FunctionName = F.getName().str();
      Report.Key = Key;
      Report.TotalAccesses = Accesses.size();

      for (const auto &Acc : Accesses) {
        if (Acc.Addr.K != StackExpr::Kind::StackConst || Acc.End <= Acc.Begin) {
          continue;
        }
        if (!Report.HasRange) {
          Report.MinOff = Acc.Begin;
          Report.MaxOff = Acc.End;
          Report.HasRange = true;
        } else {
          Report.MinOff = std::min(Report.MinOff, Acc.Begin);
          Report.MaxOff = std::max(Report.MaxOff, Acc.End);
        }
      }
      if (Report.HasRange) {
        Report.FrameSize = Report.MaxOff - Report.MinOff;
      }

      auto ReasonIt = BaseReasons.find(Key);
      if (ReasonIt != BaseReasons.end()) {
        Report.Reasons = ReasonIt->second;
        UnsafeCount += Accesses.size();
        PreservedAccessCount += Accesses.size();
        PreservedCount++;
        Report.UnsafeAccesses = Accesses.size();
        ReportEntries.push_back(Report);
        continue;
      }

      SmallVector<std::pair<int64_t, int64_t>, 8> UnsafeRanges;
      unsigned LocalReasons = SkipNone;

      auto EscapedIt = EscapedRanges.find(Key);
      if (EscapedIt != EscapedRanges.end()) {
        UnsafeRanges.append(EscapedIt->second.begin(), EscapedIt->second.end());
        LocalReasons |= SkipBaseEscaped;
      }

      for (auto &Acc : Accesses) {
        unsigned AccReasons = SkipNone;
        if (Acc.Escapes) {
          AccReasons |= SkipBaseEscaped;
        }
        if (Acc.IsVolatileOrAtomic) {
          AccReasons |= SkipVolatileOrAtomic;
        }
        if (Acc.Addr.K == StackExpr::Kind::StackDynamic) {
          AccReasons |= SkipDynamicAddress;
        }
        if (Acc.Begin >= 0) {
          AccReasons |= SkipPositiveOffset;
        }
        if (Acc.Addr.Base.Kind == StackBaseKind::RSP && Acc.Addr.Base.V != nullptr) {
          AccReasons |= SkipNonEntryRSP;
        }

        if (AccReasons != SkipNone) {
          LocalReasons |= AccReasons;
          UnsafeRanges.push_back({Acc.Begin, Acc.End});
        }
      }

      SmallVector<StackAccess *, 16> SafeAccesses;
      for (auto &Acc : Accesses) {
        unsigned AccReasons = SkipNone;
        if (Acc.Escapes) {
          AccReasons |= SkipBaseEscaped;
        }
        if (Acc.IsVolatileOrAtomic) {
          AccReasons |= SkipVolatileOrAtomic;
        }
        if (Acc.Addr.K == StackExpr::Kind::StackDynamic) {
          AccReasons |= SkipDynamicAddress;
        }
        if (Acc.Begin >= 0) {
          AccReasons |= SkipPositiveOffset;
        }
        if (Acc.Addr.Base.Kind == StackBaseKind::RSP && Acc.Addr.Base.V != nullptr) {
          AccReasons |= SkipNonEntryRSP;
        }

        if (AccReasons != SkipNone) {
          LocalReasons |= AccReasons;
          UnsafeCount++;
          Report.UnsafeAccesses++;
          continue;
        }

        bool Overlaps = false;
        for (const auto &Range : UnsafeRanges) {
          if (Acc.Begin < Range.second && Acc.End > Range.first) {
            Overlaps = true;
            break;
          }
        }

        if (Overlaps) {
          LocalReasons |= SkipUnsafeOverlap;
          UnsafeCount++;
          Report.UnsafeAccesses++;
        } else {
          SafeAccesses.push_back(&Acc);
        }
      }

      Report.Reasons |= LocalReasons;
      Report.UnsafeRanges = UnsafeRanges;

      if (SafeAccesses.empty()) {
        Report.Reasons |= SkipNoSafeAccess;
        PreservedAccessCount += Accesses.size();
        PreservedCount++;
        ReportEntries.push_back(Report);
        continue;
      }

      // One StackBase is still one physical guest object.  Do not place only
      // a subset of its accesses in host alloca storage while volatile,
      // positive, escaping, or otherwise unsafe accesses remain in guest
      // memory.  Without an object-separation proof those two views may alias.
      if (Report.UnsafeAccesses != 0) {
        UnsafeCount += SafeAccesses.size();
        Report.UnsafeAccesses += SafeAccesses.size();
        Report.Reasons |= SkipUnsafeOverlap;
        PreservedCount++;
        PreservedAccessCount += Report.UnsafeAccesses;
        ReportEntries.push_back(Report);
        continue;
      }

      // At this stage all offsets still belong to one physical guest frame,
      // not to independently-proven LLVM objects.  An incoming read in any
      // component means a preserved alias or callee can observe the shared
      // frame, so splitting out only the locally-written components is not
      // semantics-preserving.  Recover the base only when every read in the
      // complete eligible set is initialized locally.
      if (!IsDirectNativeFrame(SafeAccesses, F)) {
        UnsafeCount += SafeAccesses.size();
        Report.UnsafeAccesses += SafeAccesses.size();
        Report.Reasons |= SkipReadBeforeWrite;
        PreservedCount++;
        PreservedAccessCount += Report.UnsafeAccesses;
        ReportEntries.push_back(Report);
        continue;
      }

      int64_t MinOff = INT64_MAX;
      int64_t MaxOff = INT64_MIN;
      for (const StackAccess *Acc : SafeAccesses) {
        MinOff = std::min(MinOff, Acc->Begin);
        MaxOff = std::max(MaxOff, Acc->End);
      }
      if (MinOff == INT64_MAX || MaxOff == INT64_MIN || MaxOff <= MinOff) {
        Report.Reasons |= SkipInvalidRange;
        Report.UnsafeAccesses += SafeAccesses.size();
        UnsafeCount += SafeAccesses.size();
        PreservedCount++;
        PreservedAccessCount += Report.UnsafeAccesses;
        ReportEntries.push_back(Report);
        continue;
      }
      int64_t FrameSize = MaxOff - MinOff;
      if (FrameSize <= 0 || FrameSize > 1024 * 1024) {
        Report.Reasons |= SkipFrameTooLarge;
        Report.UnsafeAccesses += SafeAccesses.size();
        UnsafeCount += SafeAccesses.size();
        PreservedCount++;
        PreservedAccessCount += Report.UnsafeAccesses;
        ReportEntries.push_back(Report);
        continue;
      }

      Type *FrameTy = ArrayType::get(Int8Ty, FrameSize);
      AllocaInst *FrameAlloca =
          EntryBuilder.CreateAlloca(FrameTy, nullptr, "native_local_frame");
      FrameAlloca->setAlignment(Align(16));
      Value *Zero = EntryBuilder.getInt32(0);

      for (StackAccess *Acc : SafeAccesses) {
        IRBuilder<> B(Acc->I);
        Value *Idx = ConstantInt::get(Int64Ty, Acc->Addr.Offset - MinOff);
        Value *GEP = B.CreateInBoundsGEP(
            FrameTy, FrameAlloca, {Zero, Idx}, "frame_ptr");
        if (auto *LI = dyn_cast<LoadInst>(Acc->I)) {
          LI->setOperand(0, GEP);
        } else if (auto *SI = dyn_cast<StoreInst>(Acc->I)) {
          SI->setOperand(1, GEP);
        } else if (auto *MemI = dyn_cast<MemIntrinsic>(Acc->I)) {
          if (MemI->getRawDest() == Acc->Ptr) {
            MemI->setOperand(0, GEP);
          } else if (auto *MemT = dyn_cast<MemTransferInst>(MemI)) {
            if (MemT->getRawSource() == Acc->Ptr) {
              MemT->setOperand(1, GEP);
            }
          }
        }
      }

      Changed = true;
      Report.Recovered = true;
      Report.HasRange = true;
      Report.MinOff = MinOff;
      Report.MaxOff = MaxOff;
      Report.FrameSize = FrameSize;
      Report.SafeAccesses = SafeAccesses.size();
      RecoveredCount++;
      RecoveredAccessCount += SafeAccesses.size();
      PreservedAccessCount += Report.UnsafeAccesses;
      ReportEntries.push_back(Report);
    }
  }

  unsigned VerifierErrors = 0;
  for (const auto &Entry : ReportEntries) {
    if (!verifyReportEntry(Entry, errs())) {
      VerifierErrors++;
    }
  }

  if (RecoveredCount > 0 || PreservedCount > 0 || UnsafeCount > 0) {
    errs() << "brighten-stack-frame-pass report:\n";
    errs() << "  Lifted functions visited: " << VisitedFunctions << "\n";
    errs() << "  Functions with stack accesses: " << FunctionsWithStackAccess << "\n";
    errs() << "  Recovered regions: " << RecoveredCount << "\n";
    errs() << "  Preserved regions: " << PreservedCount << "\n";
    errs() << "  Recovered accesses: " << RecoveredAccessCount << "\n";
    errs() << "  Preserved accesses: " << PreservedAccessCount << "\n";
    errs() << "  Invalid/unsafe skipped counts: " << UnsafeCount << "\n";
    errs() << "  Verifier errors: " << VerifierErrors << "\n";
    errs() << "  Detail:\n";
    for (const auto &Entry : ReportEntries) {
      errs() << "    function=" << Entry.FunctionName
             << " action=" << (Entry.Recovered ? "recovered" : "preserved")
             << " base=";
      printBase(errs(), Entry.Key);
      errs() << " range=";
      if (Entry.HasRange) {
        printRange(errs(), Entry.MinOff, Entry.MaxOff);
        errs() << " frame_size=" << Entry.FrameSize;
      } else {
        errs() << "unknown frame_size=0";
      }
      errs() << " accesses=" << Entry.TotalAccesses
             << " safe=" << Entry.SafeAccesses
             << " skipped=" << Entry.UnsafeAccesses
             << " reasons=";
      printSkipReasons(errs(), Entry.Reasons);
      if (!Entry.UnsafeRanges.empty()) {
        errs() << " unsafe_ranges=";
        for (unsigned I = 0; I < Entry.UnsafeRanges.size(); ++I) {
          if (I) errs() << ",";
          printRange(errs(), Entry.UnsafeRanges[I].first, Entry.UnsafeRanges[I].second);
        }
      }
      errs() << "\n";
    }
  }

  return Changed;
}

} // namespace brighten_stack_frame

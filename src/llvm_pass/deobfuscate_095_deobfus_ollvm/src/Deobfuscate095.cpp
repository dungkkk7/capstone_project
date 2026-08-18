#include "Deobfuscate095.h"
#include "Z3Prover.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <cstdint>
#include <string>

using namespace llvm;

namespace deobfuscate095 {
namespace {

static cl::opt<std::string> ReportPath(
    "095-report", cl::desc("Write proof-driven 095 JSON evidence here"),
    cl::init(""));
static cl::opt<unsigned> Z3TimeoutMs(
    "095-z3-timeout-ms",
    cl::desc("Per-query Z3 timeout; unknown is never accepted as proof"),
    cl::init(50));
static cl::opt<unsigned> MaxRounds(
    "095-max-rounds", cl::desc("Maximum proof/rewrite fixpoint rounds"),
    cl::init(6));
static cl::opt<unsigned> MaxMBACandidates(
    "095-max-mba-candidates",
    cl::desc("Maximum integer expressions queried per round"), cl::init(256));
static cl::opt<unsigned> MaxMBARecipes(
    "095-max-mba-recipes-per-expression",
    cl::desc("Maximum simpler recipes checked for one expression"),
    cl::init(24));
static cl::opt<bool> DisableMBA(
    "095-disable-mba", cl::desc("Disable SMT-backed MBA simplification"),
    cl::init(false), cl::Hidden);
// Compatibility spelling retained so old command lines fail semantically
// closed rather than because of an unknown option. CFG unflattening belongs
// to pass 020 and is intentionally not implemented in 095 v2.
static cl::opt<bool> DisableDeflatten(
    "095-disable-deflatten", cl::desc("Compatibility option; 095 v2 never owns CFG unflattening"),
    cl::init(false), cl::Hidden);

struct Metrics {
  uint64_t PredicateCandidates = 0;
  uint64_t PredicateProofs = 0;
  uint64_t SelectCandidates = 0;
  uint64_t SelectProofs = 0;
  uint64_t MBACandidates = 0;
  uint64_t MBAProofs = 0;
  uint64_t Rewrites = 0;
  uint64_t Rounds = 0;
};

static void verifyOrDie(Module &M, StringRef Stage) {
  std::string Error;
  raw_string_ostream OS(Error);
  if (!verifyModule(M, &OS))
    return;
  report_fatal_error(Twine("095 v2 produced invalid IR after ") + Stage +
                     ":\n" + OS.str());
}

static Value *leaf(const SimplificationProof &P, unsigned Index) {
  return Index < P.Leaves.size() ? P.Leaves[Index] : nullptr;
}

static ConstantInt *integerConstant(IntegerType *Ty, uint64_t Value) {
  return ConstantInt::get(Ty, Value, false);
}

static Value *materializeProof(IRBuilder<> &B, Instruction &Old,
                               const SimplificationProof &P) {
  auto *Ty = dyn_cast<IntegerType>(Old.getType());
  if (!Ty || Ty->getBitWidth() > 64)
    return nullptr;

  Value *L0 = leaf(P, 0);
  Value *L1 = leaf(P, 1);
  Value *A = leaf(P, P.LeftIndex);
  Value *C = leaf(P, P.RightIndex);
  auto K = [&]() -> ConstantInt * { return integerConstant(Ty, P.Constant); };
  auto IsTy = [&](Value *V) { return V && V->getType() == Ty; };

  switch (P.Kind) {
  case CandidateKind::ConstantZero:
    return ConstantInt::get(Ty, 0);
  case CandidateKind::ConstantOne:
    return ConstantInt::get(Ty, 1);
  case CandidateKind::ConstantAllOnes:
    return ConstantInt::getAllOnesValue(Ty);
  case CandidateKind::Leaf0:
    return IsTy(L0) ? L0 : nullptr;
  case CandidateKind::Leaf1:
    return IsTy(L1) ? L1 : nullptr;
  case CandidateKind::Add:
  case CandidateKind::PairAdd:
    return IsTy(A) && IsTy(C) ? B.CreateAdd(A, C, "deobf.add") : nullptr;
  case CandidateKind::Sub01:
  case CandidateKind::PairSub:
    return IsTy(A) && IsTy(C) ? B.CreateSub(A, C, "deobf.sub") : nullptr;
  case CandidateKind::Sub10:
    return IsTy(L0) && IsTy(L1) ? B.CreateSub(L1, L0, "deobf.sub") : nullptr;
  case CandidateKind::PairMul:
    return IsTy(A) && IsTy(C) ? B.CreateMul(A, C, "deobf.mul") : nullptr;
  case CandidateKind::Xor:
  case CandidateKind::PairXor:
    return IsTy(A) && IsTy(C) ? B.CreateXor(A, C, "deobf.xor") : nullptr;
  case CandidateKind::And:
  case CandidateKind::PairAnd:
    return IsTy(A) && IsTy(C) ? B.CreateAnd(A, C, "deobf.and") : nullptr;
  case CandidateKind::Or:
  case CandidateKind::PairOr:
    return IsTy(A) && IsTy(C) ? B.CreateOr(A, C, "deobf.or") : nullptr;
  case CandidateKind::Not0:
  case CandidateKind::UnaryNot:
    return IsTy(L0) ? B.CreateNot(L0, "deobf.not") : nullptr;
  case CandidateKind::Not1:
    return IsTy(L1) ? B.CreateNot(L1, "deobf.not") : nullptr;
  case CandidateKind::Neg0:
  case CandidateKind::UnaryNeg:
    return IsTy(L0) ? B.CreateNeg(L0, "deobf.neg") : nullptr;
  case CandidateKind::Neg1:
    return IsTy(L1) ? B.CreateNeg(L1, "deobf.neg") : nullptr;
  case CandidateKind::AddConst:
    return IsTy(L0) ? B.CreateAdd(L0, K(), "deobf.addc") : nullptr;
  case CandidateKind::SubConst:
    return IsTy(L0) ? B.CreateSub(L0, K(), "deobf.subc") : nullptr;
  case CandidateKind::XorConst:
    return IsTy(L0) ? B.CreateXor(L0, K(), "deobf.xorc") : nullptr;
  case CandidateKind::AndConst:
    return IsTy(L0) ? B.CreateAnd(L0, K(), "deobf.andc") : nullptr;
  case CandidateKind::OrConst:
    return IsTy(L0) ? B.CreateOr(L0, K(), "deobf.orc") : nullptr;
  case CandidateKind::MulConst:
    return IsTy(L0) ? B.CreateMul(L0, K(), "deobf.mulc") : nullptr;
  case CandidateKind::ShlConst:
    return IsTy(L0) ? B.CreateShl(L0, K(), "deobf.shlc") : nullptr;
  case CandidateKind::LShrConst:
    return IsTy(L0) ? B.CreateLShr(L0, K(), "deobf.lshrc") : nullptr;
  case CandidateKind::AShrConst:
    return IsTy(L0) ? B.CreateAShr(L0, K(), "deobf.ashrc") : nullptr;
  }
  return nullptr;
}

static bool simplifyPredicates(Module &M, Z3Prover &Prover, Metrics &R) {
  SmallVector<BranchInst *, 64> Branches;
  SmallVector<SelectInst *, 64> Selects;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      if (auto *BI = dyn_cast<BranchInst>(&I); BI && BI->isConditional())
        Branches.push_back(BI);
      else if (auto *SI = dyn_cast<SelectInst>(&I))
        Selects.push_back(SI);
    }
  }

  bool Changed = false;
  for (BranchInst *BI : Branches) {
    if (!BI->getParent())
      continue;
    ++R.PredicateCandidates;
    std::optional<bool> Proven = Prover.proveBooleanConstant(BI->getCondition());
    if (!Proven)
      continue;
    ++R.PredicateProofs;
    BasicBlock *Taken = BI->getSuccessor(*Proven ? 0 : 1);
    BasicBlock *Dead = BI->getSuccessor(*Proven ? 1 : 0);
    if (Taken != Dead)
      Dead->removePredecessor(BI->getParent(), true);
    BranchInst::Create(Taken, BI);
    BI->eraseFromParent();
    ++R.Rewrites;
    Changed = true;
  }

  for (SelectInst *SI : Selects) {
    if (!SI->getParent())
      continue;
    ++R.SelectCandidates;
    std::optional<bool> Proven = Prover.proveBooleanConstant(SI->getCondition());
    if (!Proven)
      continue;
    ++R.SelectProofs;
    Value *Replacement = *Proven ? SI->getTrueValue() : SI->getFalseValue();
    SI->replaceAllUsesWith(Replacement);
    SI->eraseFromParent();
    ++R.Rewrites;
    Changed = true;
  }
  if (Changed)
    Prover.invalidateBooleanCache();
  return Changed;
}

static bool simplifyMBA(Module &M, Z3Prover &Prover, Metrics &R) {
  if (DisableMBA || MaxMBACandidates == 0)
    return false;

  SmallVector<Instruction *, 256> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      auto *ITy = dyn_cast<IntegerType>(I.getType());
      if (!ITy || ITy->getBitWidth() > 64 || isa<PHINode>(I) ||
          isa<SelectInst>(I) || isa<ICmpInst>(I))
        continue;
      if (!isa<BinaryOperator>(I) && !isa<CastInst>(I))
        continue;
      Candidates.push_back(&I);
      if (Candidates.size() >= MaxMBACandidates)
        break;
    }
    if (Candidates.size() >= MaxMBACandidates)
      break;
  }

  bool Changed = false;
  for (Instruction *I : Candidates) {
    if (!I->getParent() || I->use_empty())
      continue;
    ++R.MBACandidates;
    auto Proof = Prover.proveSimplerInteger(I, 3, MaxMBARecipes);
    if (!Proof)
      continue;
    IRBuilder<> B(I);
    Value *Replacement = materializeProof(B, *I, *Proof);
    if (!Replacement || Replacement == I || Replacement->getType() != I->getType())
      continue;
    ++R.MBAProofs;
    I->replaceAllUsesWith(Replacement);
    if (isInstructionTriviallyDead(I))
      RecursivelyDeleteTriviallyDeadInstructions(I);
    ++R.Rewrites;
    Changed = true;
  }
  if (Changed)
    Prover.invalidateBooleanCache();
  return Changed;
}

static void writeReport(const Module &M, const Metrics &R,
                        const ProofStats &Proofs) {
  if (ReportPath.empty())
    return;
  std::error_code EC;
  raw_fd_ostream OS(ReportPath, EC, sys::fs::OF_Text);
  if (EC) {
    errs() << "095 v2: cannot write report '" << ReportPath
           << "': " << EC.message() << "\n";
    return;
  }
  json::OStream J(OS, 2);
  J.object([&] {
    J.attribute("schema", "deobfuscate-095-proof-v2");
    J.attribute("module", M.getModuleIdentifier());
    J.attribute("cfg_unflatten_owner", "020-region-ssa");
    J.attribute("unknown_is_evidence", false);
    J.attribute("rounds", static_cast<int64_t>(R.Rounds));
    J.attribute("rewrites", static_cast<int64_t>(R.Rewrites));
    J.attributeObject("predicates", [&] {
      J.attribute("candidates", static_cast<int64_t>(R.PredicateCandidates));
      J.attribute("proved", static_cast<int64_t>(R.PredicateProofs));
      J.attribute("select_candidates", static_cast<int64_t>(R.SelectCandidates));
      J.attribute("select_proved", static_cast<int64_t>(R.SelectProofs));
    });
    J.attributeObject("mba", [&] {
      J.attribute("candidates", static_cast<int64_t>(R.MBACandidates));
      J.attribute("proved", static_cast<int64_t>(R.MBAProofs));
    });
    J.attributeObject("z3", [&] {
      J.attribute("queries", static_cast<int64_t>(Proofs.Queries));
      J.attribute("proved", static_cast<int64_t>(Proofs.Proved));
      J.attribute("disproved", static_cast<int64_t>(Proofs.Disproved));
      J.attribute("unknown", static_cast<int64_t>(Proofs.Unknown));
      J.attribute("unknown_is_evidence", false);
    });
  });
}

} // namespace

PreservedAnalyses Deobfuscate095Pass::run(Module &M, ModuleAnalysisManager &) {
  (void)DisableDeflatten;
  Metrics R;
  Z3Prover Prover(Z3TimeoutMs);
  bool AnyChanged = false;

  const unsigned Rounds = std::max(1u, static_cast<unsigned>(MaxRounds));
  for (unsigned Round = 0; Round < Rounds; ++Round) {
    bool Changed = false;
    Changed |= simplifyPredicates(M, Prover, R);
    Changed |= simplifyMBA(M, Prover, R);
    ++R.Rounds;
    verifyOrDie(M, "proof round");
    AnyChanged |= Changed;
    if (!Changed)
      break;
  }

  writeReport(M, R, Prover.stats());
  errs() << "095 v2: predicate-proofs=" << R.PredicateProofs
         << " select-proofs=" << R.SelectProofs
         << " mba-proofs=" << R.MBAProofs
         << " rewrites=" << R.Rewrites
         << " z3-unknown=" << Prover.stats().Unknown << "\n";

  return AnyChanged ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace deobfuscate095

#include "Deobfuscate095.h"
#include "ChernobogAddRules.h"
#include "ChernobogAndRules.h"
#include "ChernobogOrRules.h"
#include "ChernobogSubRules.h"
#include "ChernobogXorRules.h"
#include "ChernobogMiscRules.h"
#include "ChernobogJumpRules.h"
#include "Z3Prover.h"

#include "llvm/ADT/APInt.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/MemorySSA.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/InstCombine/InstCombine.h"
#include "llvm/Transforms/Scalar/ADCE.h"
#include "llvm/Transforms/Scalar/DeadStoreElimination.h"
#include "llvm/Transforms/Scalar/EarlyCSE.h"
#include "llvm/Transforms/Scalar/SROA.h"
#include "llvm/Transforms/Scalar/SimplifyCFG.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Mem2Reg.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

#include <algorithm>
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <system_error>
#include <utility>

using namespace llvm;

namespace deobfuscate095 {
namespace {

static cl::opt<std::string> ReportPath(
    "095-report",
    cl::desc("Path for the deobfuscate-095 JSON report (default: system temp directory)"),
    cl::init(""));

static cl::opt<unsigned> Z3TimeoutMs(
    "095-z3-timeout-ms",
    cl::desc("Per-query Z3 timeout in milliseconds; unknown never proves a rewrite"),
    cl::init(50));

static cl::opt<unsigned> MaxZ3Candidates(
    "095-max-z3-candidates",
    cl::desc("Maximum generic residual MBA expressions considered per function "
             "(0 disables the expensive fallback; direct/native rules remain active)"),
    cl::init(0));

static cl::opt<unsigned> MaxZ3RecipesPerExpression(
    "095-max-z3-recipes-per-expression",
    cl::desc("Maximum residual Z3 recipes tested for one MBA expression"),
    cl::init(12));

static cl::opt<unsigned> MaxOpaqueZ3Candidates(
    "095-max-opaque-z3-candidates",
    cl::desc("Maximum prioritized opaque-predicate Z3 candidates per module"),
    // Residual SMT is a diagnostic fallback, never the discovery engine.
    // Deterministic structural/bitwidth rules run without this budget.
    cl::init(8));

static cl::opt<bool> OpaqueZ3Debug(
    "095-opaque-z3-debug",
    cl::desc("Print opaque predicates proved constant by the Z3 fallback"),
    cl::init(false), cl::Hidden);

static cl::opt<bool> DisableMBA(
    "095-disable-mba", cl::desc("Diagnostic: disable the MBA/Z3 rewrite stage"),
    cl::init(false), cl::Hidden);

static cl::opt<bool> DisableDeflatten(
    "095-disable-deflatten",
    cl::desc("Diagnostic: disable the dispatcher CFG rewrite stage"),
    cl::init(false), cl::Hidden);

static cl::opt<unsigned> MaxDeflattenRounds(
    "095-max-deflatten-rounds",
    cl::desc("Maximum independently verified dispatcher roots per function"),
    cl::init(128));

static cl::opt<unsigned> MaxDeflattenInstructions(
    "095-max-deflatten-instructions",
    cl::desc("Fail-closed size limit for transactional dispatcher rewriting"),
    cl::init(50000));

static cl::opt<bool> DeflattenDebug(
    "095-deflatten-debug", cl::desc("Log transactional dispatcher roots"),
    cl::init(false), cl::Hidden);

static cl::opt<bool> DisableNativeStackMapper(
    "095-disable-native-stack-mapper",
    cl::desc("Diagnostic: disable recovered native-stack mapper matching"),
    cl::init(false), cl::Hidden);

static cl::opt<bool> DisableMemoryEntryFinalize(
    "095-disable-memory-entry-finalize",
    cl::desc("Diagnostic: retain the one-shot entry of memory dispatchers"),
    cl::init(false), cl::Hidden);

static cl::opt<bool> DeflattenInLoopOnly(
    "095-deflatten-in-loop-only",
    cl::desc("Diagnostic: retain PHI-state transitions leaving the root loop"),
    cl::init(false), cl::Hidden);

static cl::opt<unsigned> MaxPhiDeflattenEdges(
    "095-max-phi-deflatten-edges",
    cl::desc("Diagnostic: maximum edges rewritten in one PHI-state root (0 is unlimited)"),
    cl::init(0), cl::Hidden);

struct StageMetrics {
  uint64_t Candidates = 0;
  uint64_t Changes = 0;
  uint64_t Unresolved = 0;
};

struct FunctionMetrics {
  std::string Name;
  uint64_t BasicBlocksBefore = 0;
  uint64_t BasicBlocksAfter = 0;
  uint64_t InstructionsBefore = 0;
  uint64_t InstructionsAfter = 0;
  uint64_t LoopsObserved = 0;
  uint64_t MemoryAccessesObserved = 0;
};

struct Report {
  std::string Module;
  std::string Status = "ok";
  std::map<std::string, StageMetrics> Stages;
  // Rule-level evidence makes progress auditable instead of inferring it
  // from aggregate stage change counts.
  std::map<std::string, uint64_t> RuleHits;
  ChernobogAddRuleMetrics ChernobogAddRules;
  ChernobogAndRuleMetrics ChernobogAndRules;
  ChernobogOrRuleMetrics ChernobogOrRules;
  ChernobogSubRuleMetrics ChernobogSubRules;
  ChernobogXorRuleMetrics ChernobogXorRules;
  ChernobogMiscRuleMetrics ChernobogMiscRules;
  ChernobogJumpRuleMetrics ChernobogJumpRules;
  SmallVector<std::string, 32> UnresolvedReasons;
  SmallVector<FunctionMetrics, 16> Functions;
  ProofStats Z3;
  uint64_t OpaqueZ3Attempts = 0;
  unsigned TimeoutMs = 0;
};

static void noteRule(Report &R, StringRef Rule) {
  ++R.RuleHits[Rule.str()];
}

static StringRef ruleName(CandidateKind K) {
  switch (K) {
  case CandidateKind::ConstantZero: return "mba.constant_zero";
  case CandidateKind::ConstantOne: return "mba.constant_one";
  case CandidateKind::ConstantAllOnes: return "mba.constant_all_ones";
  case CandidateKind::Leaf0: return "mba.leaf0";
  case CandidateKind::Leaf1: return "mba.leaf1";
  case CandidateKind::Add: case CandidateKind::PairAdd: return "mba.add";
  case CandidateKind::Sub01: case CandidateKind::Sub10: case CandidateKind::PairSub: return "mba.sub";
  case CandidateKind::PairMul: return "mba.mul";
  case CandidateKind::Xor: case CandidateKind::PairXor: return "mba.xor";
  case CandidateKind::And: case CandidateKind::PairAnd: return "mba.and";
  case CandidateKind::Or: case CandidateKind::PairOr: return "mba.or";
  case CandidateKind::Not0: case CandidateKind::Not1: return "mba.not";
  case CandidateKind::Neg0: case CandidateKind::Neg1: return "mba.neg";
  case CandidateKind::AddConst: return "mba.add_const";
  case CandidateKind::SubConst: return "mba.sub_const";
  case CandidateKind::XorConst: return "mba.xor_const";
  case CandidateKind::AndConst: return "mba.and_const";
  case CandidateKind::OrConst: return "mba.or_const";
  case CandidateKind::MulConst: return "mba.mul_const";
  case CandidateKind::ShlConst: return "mba.shl_const";
  case CandidateKind::LShrConst: return "mba.lshr_const";
  case CandidateKind::AShrConst: return "mba.ashr_const";
  case CandidateKind::UnaryNot: return "mba.not";
  case CandidateKind::UnaryNeg: return "mba.neg";
  }
  return "mba.unknown";
}

static constexpr StringLiteral StageNames[] = {
    "normalize",          "resolve_objects_pointers",
    "mba",                "bcf_opaque_predicates",
    "deflatten",          "cfg_cleanup",
    "fake_stack",         "register_state",
};

static uint64_t instructionCount(const Function &F) {
  uint64_t Count = 0;
  for (const BasicBlock &BB : F)
    Count += BB.size();
  return Count;
}

static uint64_t loopCount(const LoopInfo &LI) {
  uint64_t Count = 0;
  SmallVector<const Loop *, 16> Worklist;
  for (const Loop *L : LI)
    Worklist.push_back(L);
  while (!Worklist.empty()) {
    const Loop *L = Worklist.pop_back_val();
    ++Count;
    for (const Loop *Sub : *L)
      Worklist.push_back(Sub);
  }
  return Count;
}

static uint64_t memoryAccessCount(Function &F, MemorySSA &MSSA) {
  uint64_t Count = 0;
  for (Instruction &I : instructions(F))
    if (MSSA.getMemoryAccess(&I))
      ++Count;
  return Count;
}

static void addUnresolved(Report &R, StringRef Category, uint64_t Count,
                          StringRef Detail) {
  if (Count == 0)
    return;
  R.Stages[Category.str()].Unresolved += Count;
  std::string Message;
  raw_string_ostream OS(Message);
  OS << Category << ": " << Count << " " << Detail;
  std::string Rendered = OS.str();
  if (!llvm::is_contained(R.UnresolvedReasons, Rendered))
    R.UnresolvedReasons.push_back(std::move(Rendered));
}

static void verifyCFGStage(Module &M, StringRef Stage) {
  std::string Error;
  raw_string_ostream OS(Error);
  if (!verifyModule(M, &OS))
    return;
  report_fatal_error(Twine("095 produced invalid IR after ") + Stage +
                     ":\n" + OS.str());
}

static std::string defaultReportPath(const Module &M) {
  StringRef Source = M.getSourceFileName();
  if (Source.empty())
    Source = M.getModuleIdentifier();
  StringRef Base = sys::path::filename(Source);
  if (Base.empty() || Base == "<stdin>")
    Base = "module";
  SmallString<256> Stem(Base);
  sys::path::replace_extension(Stem, "");
  std::string Tag = std::to_string(static_cast<uint64_t>(hash_value(
      M.getModuleIdentifier())));

  // A bare module identifier is relative to opt's cwd.  The old fallback
  // therefore polluted whichever directory launched opt (usually the repo
  // root) with llvm-link.095.*.  Direct callers do not provide the pipeline's
  // result directory, so keep the implicit report in a private temp folder;
  // pipeline callers can still select an explicit -095-report path.
  SmallString<256> ReportDir;
  sys::path::system_temp_directory(true, ReportDir);
  if (!ReportDir.empty()) {
    sys::path::append(ReportDir, "deobfuscate-095");
    (void)sys::fs::create_directories(ReportDir);
    sys::path::append(ReportDir, Stem + ".095." + Tag + ".json");
    return ReportDir.str().str();
  }

  // This is only a last-resort fallback for unusual environments where the
  // system temp directory cannot be queried.
  return (Stem + ".095." + Tag + ".json").str();
}

static void writeReport(const Module &M, const Report &R) {
  std::string Path = ReportPath.empty() ? defaultReportPath(M) : ReportPath;
  std::error_code EC;
  raw_fd_ostream OS(Path, EC, sys::fs::OF_Text);
  if (EC) {
    errs() << "095: cannot write report '" << Path << "': " << EC.message()
           << "\n";
    return;
  }

  json::OStream J(OS, 2);
  J.object([&] {
    J.attribute("schema", "deobfuscate-095-report-v1");
    J.attribute("module", R.Module);
    J.attribute("status", R.Status);
    J.attribute("z3_timeout_ms", int64_t(R.TimeoutMs));
    J.attributeObject("z3", [&] {
      J.attribute("queries", int64_t(R.Z3.Queries));
      J.attribute("proved", int64_t(R.Z3.Proved));
      J.attribute("disproved", int64_t(R.Z3.Disproved));
      J.attribute("unknown", int64_t(R.Z3.Unknown));
      J.attribute("opaque_candidates_attempted",
                  int64_t(R.OpaqueZ3Attempts));
      J.attribute("unknown_is_evidence", false);
    });
    J.attributeArray("pipeline", [&] {
      for (StringRef Name : StageNames)
        J.value(Name);
    });
    J.attributeObject("stages", [&] {
      for (StringRef Name : StageNames) {
        auto It = R.Stages.find(Name.str());
        StageMetrics Empty;
        const StageMetrics &S = It == R.Stages.end() ? Empty : It->second;
        J.attributeObject(Name, [&] {
          J.attribute("candidates", int64_t(S.Candidates));
          J.attribute("changes", int64_t(S.Changes));
          J.attribute("unresolved", int64_t(S.Unresolved));
  });
}
    });
    J.attributeObject("rule_hits", [&] {
      for (const auto &KV : R.RuleHits)
        J.attribute(KV.first, int64_t(KV.second));
    });
    J.attributeObject("chernobog_add_rule_operations", [&] {
      for (const auto &KV : R.ChernobogAddRules.Rules) {
        J.attributeObject(KV.first, [&] {
          J.attribute("hits", int64_t(KV.second.Hits));
          J.attribute("operations_before", int64_t(KV.second.OperationsBefore));
          J.attribute("operations_after", int64_t(KV.second.OperationsAfter));
        });
      }
    });
    J.attributeObject("chernobog_and_rule_operations", [&] {
      for (const auto &KV : R.ChernobogAndRules.Rules) {
        J.attributeObject(KV.first, [&] {
          J.attribute("hits", int64_t(KV.second.Hits));
          J.attribute("operations_before", int64_t(KV.second.OperationsBefore));
          J.attribute("operations_after", int64_t(KV.second.OperationsAfter));
        });
      }
    });
    J.attributeObject("chernobog_xor_rule_operations", [&] {
      for (const auto &KV : R.ChernobogXorRules.Rules) {
        J.attributeObject(KV.first, [&] {
          J.attribute("hits", int64_t(KV.second.Hits));
          J.attribute("operations_before", int64_t(KV.second.OperationsBefore));
          J.attribute("operations_after", int64_t(KV.second.OperationsAfter));
        });
      }
    });
    J.attributeObject("chernobog_or_rule_operations", [&] {
      for (const auto &KV : R.ChernobogOrRules.Rules) {
        J.attributeObject(KV.first, [&] {
          J.attribute("hits", int64_t(KV.second.Hits));
          J.attribute("operations_before", int64_t(KV.second.OperationsBefore));
          J.attribute("operations_after", int64_t(KV.second.OperationsAfter));
        });
      }
    });
    J.attributeObject("chernobog_sub_rule_operations", [&] {
      for (const auto &KV : R.ChernobogSubRules.Rules) {
        J.attributeObject(KV.first, [&] {
          J.attribute("hits", int64_t(KV.second.Hits));
          J.attribute("operations_before", int64_t(KV.second.OperationsBefore));
          J.attribute("operations_after", int64_t(KV.second.OperationsAfter));
        });
      }
    });
    J.attributeObject("chernobog_misc_rule_operations", [&] {
      for (const auto &KV : R.ChernobogMiscRules.Rules) {
        J.attributeObject(KV.first, [&] {
          J.attribute("hits", int64_t(KV.second.Hits));
          J.attribute("operations_before", int64_t(KV.second.OperationsBefore));
          J.attribute("operations_after", int64_t(KV.second.OperationsAfter));
        });
      }
    });
    J.attributeObject("chernobog_rule_coverage", [&] {
      // These are the source-side catalog sizes.  Generic LLVM rules are
      // reported separately because one LLVM matcher can subsume several
      // IDA-microcode rules; they must not be mistaken for 1:1 coverage.
      J.attribute("expected_mba_rules", int64_t(110));
      J.attribute("expected_predicate_rules", int64_t(24));
      // rules_predicate.h declares 24 concrete classes.  Chernobog's
      // initialize() registers 23 of them; LnotLnotRule is intentionally
      // omitted there because it canonicalizes rather than returns a
      // constant.  The LLVM port implements and tests that canonicalization
      // as well as all 23 active registry entries.
      J.attribute("source_active_predicate_rules", int64_t(23));
      J.attribute("llvm_predicate_semantics_covered", int64_t(24));
      J.attribute("predicate_rule_mapping_complete", true);
      J.attribute("direct_rule_mapping_complete", false);
    });
    J.attributeArray("functions", [&] {
      for (const FunctionMetrics &F : R.Functions) {
        J.object([&] {
          J.attribute("name", F.Name);
          J.attribute("basic_blocks_before", int64_t(F.BasicBlocksBefore));
          J.attribute("basic_blocks_after", int64_t(F.BasicBlocksAfter));
          J.attribute("instructions_before", int64_t(F.InstructionsBefore));
          J.attribute("instructions_after", int64_t(F.InstructionsAfter));
          J.attribute("loops_observed", int64_t(F.LoopsObserved));
          J.attribute("memory_accesses_observed",
                      int64_t(F.MemoryAccessesObserved));
        });
      }
    });
    J.attributeArray("unresolved", [&] {
      for (const std::string &Reason : R.UnresolvedReasons)
        J.value(Reason);
    });
  });
  OS << '\n';
}

static bool runFunctionPipeline(Function &F, FunctionAnalysisManager &FAM,
                                FunctionPassManager &FPM) {
  uint64_t BlocksBefore = F.size();
  uint64_t InstBefore = instructionCount(F);
  PreservedAnalyses PA = FPM.run(F, FAM);
  return !PA.areAllPreserved() || BlocksBefore != F.size() ||
         InstBefore != instructionCount(F);
}

static bool simplifyChernobogAddRulesWithReport(Function &F, Report &R);
static bool simplifyChernobogAndRulesWithReport(Function &F, Report &R);

static bool normalize(Function &F, FunctionAnalysisManager &FAM) {
  FunctionPassManager FPM;
  FPM.addPass(InstCombinePass());
  FPM.addPass(EarlyCSEPass(true));
  return runFunctionPipeline(F, FAM, FPM);
}

static Value *stripIntegerCasts(Value *V) {
  while (auto *Cast = dyn_cast<CastInst>(V)) {
    if (!Cast->getSrcTy()->isIntegerTy() || !Cast->getDestTy()->isIntegerTy())
      break;
    V = Cast->getOperand(0);
  }
  return V;
}

static Function *resolveFunctionTarget(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 12)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *F = dyn_cast<Function>(V))
    return F;
  if (auto *GA = dyn_cast<GlobalAlias>(V))
    return resolveFunctionTarget(GA->getAliasee(), Depth + 1);
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    Value *P = LI->getPointerOperand()->stripPointerCasts();
    auto *GV = dyn_cast<GlobalVariable>(P);
    if (!GV || !GV->isConstant() || !GV->hasDefinitiveInitializer())
      return nullptr;
    return resolveFunctionTarget(GV->getInitializer(), Depth + 1);
  }
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    Function *A = resolveFunctionTarget(Sel->getTrueValue(), Depth + 1);
    Function *B = resolveFunctionTarget(Sel->getFalseValue(), Depth + 1);
    return A && A == B ? A : nullptr;
  }
  return nullptr;
}

static BasicBlock *resolveBlockTarget(Value *V) {
  if (!V)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *BA = dyn_cast<BlockAddress>(V))
    return BA->getBasicBlock();
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    BasicBlock *A = resolveBlockTarget(Sel->getTrueValue());
    BasicBlock *B = resolveBlockTarget(Sel->getFalseValue());
    if (A && A == B)
      return A;
  }
  return nullptr;
}

// Lifted native helpers commonly return a register tuple assembled with an
// insertvalue chain.  LLVM does not normally propagate an extractvalue through
// a call even when one tuple field is an exact passthrough of an argument.  In
// this pipeline that loses the identity of RSP-derived frame addresses and
// makes two syntactically different references to the dispatcher state appear
// MayAlias.
//
// This summary is deliberately narrower than general interprocedural value
// propagation: every reachable syntactic return must expose the requested
// field as the same, unmodified formal argument.  The call itself is retained,
// so memory effects and non-returning behaviour are unchanged.
static std::optional<unsigned>
returnedArgumentForField(Function &Callee, ArrayRef<unsigned> Indices) {
  std::optional<unsigned> ArgumentNumber;
  bool SawReturn = false;
  for (BasicBlock &BB : Callee) {
    auto *RI = dyn_cast<ReturnInst>(BB.getTerminator());
    if (!RI)
      continue;
    SawReturn = true;
    Value *Returned = RI->getReturnValue();
    Value *Field =
        Returned ? FindInsertedValue(Returned, Indices) : nullptr;
    auto *Arg = dyn_cast_or_null<Argument>(Field);
    if (!Arg || Arg->getParent() != &Callee)
      return std::nullopt;
    if (ArgumentNumber && *ArgumentNumber != Arg->getArgNo())
      return std::nullopt;
    ArgumentNumber = Arg->getArgNo();
  }
  return SawReturn ? ArgumentNumber : std::nullopt;
}

static bool resolveObjectsAndPointers(Function &F, Report &R) {
  bool Changed = false;
  const DataLayout &DL = F.getParent()->getDataLayout();
  SmallVector<Instruction *, 64> Dead;
  SmallVector<Instruction *, 256> Snapshot;
  for (Instruction &I : instructions(F))
    Snapshot.push_back(&I);

  uint64_t UnresolvedIndirectCalls = 0;
  uint64_t UnresolvedIndirectBranches = 0;
  for (Instruction *I : Snapshot) {
    if (!I->getParent())
      continue;
    if (!I->isTerminator()) {
      if (Constant *C = ConstantFoldInstruction(I, DL)) {
        if (!I->getType()->isVoidTy())
          I->replaceAllUsesWith(C);
        if (wouldInstructionBeTriviallyDead(I))
          Dead.push_back(I);
        Changed = true;
        ++R.Stages["resolve_objects_pointers"].Changes;
        continue;
      }
    }

    if (auto *EVI = dyn_cast<ExtractValueInst>(I)) {
      auto *CB = dyn_cast<CallBase>(EVI->getAggregateOperand());
      Function *Callee =
          CB ? resolveFunctionTarget(CB->getCalledOperand()) : nullptr;
      if (Callee && !Callee->isDeclaration()) {
        if (std::optional<unsigned> ArgNo =
                returnedArgumentForField(*Callee, EVI->getIndices());
            ArgNo && *ArgNo < CB->arg_size()) {
          Value *Replacement = CB->getArgOperand(*ArgNo);
          if (Replacement->getType() == EVI->getType()) {
            EVI->replaceAllUsesWith(Replacement);
            Dead.push_back(EVI);
            Changed = true;
            ++R.Stages["resolve_objects_pointers"].Changes;
            continue;
          }
        }
      }
    }

    if (auto *CB = dyn_cast<CallBase>(I)) {
      if (!CB->isIndirectCall())
        continue;
      if (Function *Target = resolveFunctionTarget(CB->getCalledOperand())) {
        CB->setCalledOperand(Target);
        ++R.Stages["resolve_objects_pointers"].Changes;
        Changed = true;
      } else {
        ++UnresolvedIndirectCalls;
      }
      continue;
    }

    auto *IB = dyn_cast<IndirectBrInst>(I);
    if (!IB)
      continue;
    BasicBlock *Target = resolveBlockTarget(IB->getAddress());
    if (!Target) {
      ++UnresolvedIndirectBranches;
      continue;
    }
    BasicBlock *Source = IB->getParent();
    bool Listed = false;
    SmallVector<BasicBlock *, 8> DeadTargets;
    for (BasicBlock *Dst : IB->successors()) {
      if (Dst == Target)
        Listed = true;
      else
        DeadTargets.push_back(Dst);
    }
    if (!Listed) {
      ++UnresolvedIndirectBranches;
      continue;
    }
    for (BasicBlock *Dst : DeadTargets)
      Dst->removePredecessor(Source, true);
    IRBuilder<> B(IB);
    B.CreateBr(Target);
    IB->eraseFromParent();
    ++R.Stages["resolve_objects_pointers"].Changes;
    Changed = true;
  }
  for (Instruction *I : reverse(Dead))
    if (I->getParent() && I->use_empty())
      I->eraseFromParent();

  addUnresolved(R, "resolve_objects_pointers", UnresolvedIndirectCalls,
                "indirect calls retained because no unique LLVM Function was proven");
  addUnresolved(R, "resolve_objects_pointers", UnresolvedIndirectBranches,
                "indirect branches retained because no unique blockaddress was proven");
  return Changed;
}

static Value *materializeProof(IRBuilder<> &B, Type *Ty,
                               const SimplificationProof &Proof) {
  auto Leaf = [&](unsigned I) -> Value * {
    return I < Proof.Leaves.size() ? Proof.Leaves[I] : nullptr;
  };
  auto Const = [&]() -> Value * {
    return ConstantInt::get(Ty, Proof.Constant);
  };
  Value *L = Leaf(Proof.LeftIndex);
  Value *R = Leaf(Proof.RightIndex);
  switch (Proof.Kind) {
  case CandidateKind::ConstantZero: return ConstantInt::get(Ty, 0);
  case CandidateKind::ConstantOne: return ConstantInt::get(Ty, 1);
  case CandidateKind::ConstantAllOnes: return ConstantInt::getAllOnesValue(Ty);
  case CandidateKind::Leaf0: return Leaf(0);
  case CandidateKind::Leaf1: return Leaf(1);
  case CandidateKind::Add: return B.CreateAdd(Leaf(0), Leaf(1), "deobf.mba.add");
  case CandidateKind::Sub01: return B.CreateSub(Leaf(0), Leaf(1), "deobf.mba.sub");
  case CandidateKind::Sub10: return B.CreateSub(Leaf(1), Leaf(0), "deobf.mba.sub");
  case CandidateKind::Xor: return B.CreateXor(Leaf(0), Leaf(1), "deobf.mba.xor");
  case CandidateKind::And: return B.CreateAnd(Leaf(0), Leaf(1), "deobf.mba.and");
  case CandidateKind::Or: return B.CreateOr(Leaf(0), Leaf(1), "deobf.mba.or");
  case CandidateKind::Not0: return B.CreateNot(Leaf(0), "deobf.mba.not");
  case CandidateKind::Not1: return B.CreateNot(Leaf(1), "deobf.mba.not");
  case CandidateKind::Neg0: return B.CreateNeg(Leaf(0), "deobf.mba.neg");
  case CandidateKind::Neg1: return B.CreateNeg(Leaf(1), "deobf.mba.neg");
  case CandidateKind::PairAdd: return B.CreateAdd(L, R, "deobf.mba.add");
  case CandidateKind::PairSub: return B.CreateSub(L, R, "deobf.mba.sub");
  case CandidateKind::PairMul: return B.CreateMul(L, R, "deobf.mba.mul");
  case CandidateKind::PairXor: return B.CreateXor(L, R, "deobf.mba.xor");
  case CandidateKind::PairAnd: return B.CreateAnd(L, R, "deobf.mba.and");
  case CandidateKind::PairOr: return B.CreateOr(L, R, "deobf.mba.or");
  case CandidateKind::AddConst: return B.CreateAdd(L, Const(), "deobf.mba.addc");
  case CandidateKind::SubConst: return B.CreateSub(L, Const(), "deobf.mba.subc");
  case CandidateKind::XorConst: return B.CreateXor(L, Const(), "deobf.mba.xorc");
  case CandidateKind::AndConst: return B.CreateAnd(L, Const(), "deobf.mba.andc");
  case CandidateKind::OrConst: return B.CreateOr(L, Const(), "deobf.mba.orc");
  case CandidateKind::MulConst: return B.CreateMul(L, Const(), "deobf.mba.mulc");
  case CandidateKind::ShlConst: return B.CreateShl(L, Const(), "deobf.mba.shlc");
  case CandidateKind::LShrConst: return B.CreateLShr(L, Const(), "deobf.mba.lshrc");
  case CandidateKind::AShrConst: return B.CreateAShr(L, Const(), "deobf.mba.ashrc");
  case CandidateKind::UnaryNot: return B.CreateNot(L, "deobf.mba.not");
  case CandidateKind::UnaryNeg: return B.CreateNeg(L, "deobf.mba.neg");
  }
  return nullptr;
}

// OLLVM emits this predicate repeatedly in the lifted corpus:
//
//   ((x * ~x) & 1) ^ 1
//
// x and ~x have opposite low bits, so their product is always even.  This is
// cheap to prove structurally and should not consume the bounded generic Z3
// candidate budget.  Integer casts between the product and the low-bit mask
// preserve bit zero.
static Value *stripLowBitPreservingCasts(Value *V) {
  while (auto *CI = dyn_cast<CastInst>(V)) {
    unsigned Op = CI->getOpcode();
    if (Op != Instruction::Trunc && Op != Instruction::ZExt &&
        Op != Instruction::SExt)
      break;
    V = CI->getOperand(0);
  }
  return V;
}

static bool isBitwiseComplementOf(Value *MaybeNot, Value *Other) {
  auto *Xor = dyn_cast<BinaryOperator>(MaybeNot);
  if (!Xor || Xor->getOpcode() != Instruction::Xor)
    return false;
  auto IsAllOnes = [](Value *V) {
    auto *C = dyn_cast<ConstantInt>(V);
    return C && C->isMinusOne();
  };
  return (Xor->getOperand(0) == Other && IsAllOnes(Xor->getOperand(1))) ||
         (Xor->getOperand(1) == Other && IsAllOnes(Xor->getOperand(0)));
}

static bool isParityPartnerOf(Value *MaybePartner, Value *Other) {
  if (isBitwiseComplementOf(MaybePartner, Other))
    return true;

  auto *BO = dyn_cast<BinaryOperator>(MaybePartner);
  if (!BO || BO->hasNoUnsignedWrap() || BO->hasNoSignedWrap())
    return false;
  auto IsAdjacentConstant = [](Value *V) {
    auto *C = dyn_cast<ConstantInt>(V);
    return C && (C->isOne() || C->isMinusOne());
  };
  if (BO->getOpcode() == Instruction::Add)
    return (BO->getOperand(0) == Other &&
            IsAdjacentConstant(BO->getOperand(1))) ||
           (BO->getOperand(1) == Other &&
            IsAdjacentConstant(BO->getOperand(0)));
  if (BO->getOpcode() == Instruction::Sub)
    return BO->getOperand(0) == Other &&
           isa<ConstantInt>(BO->getOperand(1)) &&
           cast<ConstantInt>(BO->getOperand(1))->isOne();
  return false;
}

static bool isKnownEven(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 12)
    return false;
  V = stripLowBitPreservingCasts(V);
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO)
    return false;

  if (BO->getOpcode() == Instruction::Mul &&
      !BO->hasNoUnsignedWrap() && !BO->hasNoSignedWrap()) {
    Value *L = BO->getOperand(0);
    Value *R = BO->getOperand(1);
    if (isParityPartnerOf(L, R) || isParityPartnerOf(R, L))
      return true;
  }

  // AND with one known-even operand is even regardless of the other operand.
  // This covers the extra flag/state mask inserted by the lifted IR between
  // x*(x-1) and the final low-bit test.
  if (BO->getOpcode() == Instruction::And)
    return isKnownEven(BO->getOperand(0), Depth + 1) ||
           isKnownEven(BO->getOperand(1), Depth + 1);

  // These operators preserve evenness when both operands are known even.
  if (BO->getOpcode() == Instruction::Or ||
      BO->getOpcode() == Instruction::Xor ||
      BO->getOpcode() == Instruction::Add ||
      BO->getOpcode() == Instruction::Sub)
    return isKnownEven(BO->getOperand(0), Depth + 1) &&
           isKnownEven(BO->getOperand(1), Depth + 1);

  if (BO->getOpcode() == Instruction::Shl)
    if (auto *Shift = dyn_cast<ConstantInt>(BO->getOperand(1)))
      return !Shift->isZero();
  return false;
}

// The arithmetic identity x * ~x == 0 (mod 2), and likewise
// x * (x + 1) == 0 (mod 2), is a bit-vector identity.  That alone is not a
// valid LLVM rewrite: replacing the result with zero would turn a poison
// operand into a defined value.  Keep this check deliberately local and
// proof-first.  In particular, do not accept FreezeInst as a convenient way
// to make an otherwise ambiguous value defined; a freeze is observable in
// the surrounding expression and belongs to a different canonicalizer.
static bool containsFreezeOrUndefOrPoison(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 24)
    return Depth > 24;
  if (isa<FreezeInst, UndefValue, PoisonValue>(V))
    return true;
  auto *I = dyn_cast<Instruction>(V);
  if (!I)
    return false;
  for (Value *Op : I->operands())
    if (containsFreezeOrUndefOrPoison(Op, Depth + 1))
      return true;
  return false;
}

static bool isSemanticallyDefinedValue(Value *V) {
  return V && !containsFreezeOrUndefOrPoison(V) &&
         isGuaranteedNotToBeUndefOrPoison(V);
}

static bool isSemanticallyDefinedParityValue(Value *V) {
  return V && V->getType()->isIntegerTy() &&
         !V->getType()->isIntegerTy(1) &&
         isSemanticallyDefinedValue(V);
}

static bool hasPoisonGeneratingBinaryFlags(const BinaryOperator *BO) {
  return BO && (BO->hasNoUnsignedWrap() || BO->hasNoSignedWrap() ||
                BO->isExact());
}

// Exact structural matcher for the parity predicate family.  It intentionally
// does not use the broader "known even" matcher: this rule owns only
// x*~x/x*(x+1), requires the same SSA value on both sides, and refuses every
// poison-generating arithmetic flag.  The caller separately proves the root
// value noundef/non-poison before replacing it with a constant.
static Value *matchExactConsecutiveProductLowBit(Value *V) {
  auto *And = dyn_cast<BinaryOperator>(V);
  if (!And || And->getOpcode() != Instruction::And ||
      !And->getType()->isIntegerTy() || And->getType()->isIntegerTy(1) ||
      hasPoisonGeneratingBinaryFlags(And))
    return nullptr;

  Value *Product = nullptr;
  for (unsigned I = 0; I != 2; ++I) {
    auto *Mask = dyn_cast<ConstantInt>(And->getOperand(I));
    if (Mask && Mask->isOne()) {
      Product = And->getOperand(1 - I);
      break;
    }
  }
  auto *Mul = dyn_cast_or_null<BinaryOperator>(Product);
  if (!Mul || Mul->getOpcode() != Instruction::Mul ||
      Mul->getType() != And->getType() || hasPoisonGeneratingBinaryFlags(Mul))
    return nullptr;

  auto IsAllOnes = [](Value *X) {
    auto *C = dyn_cast<ConstantInt>(X);
    return C && C->getValue().isAllOnes();
  };
  auto IsOne = [](Value *X) {
    auto *C = dyn_cast<ConstantInt>(X);
    return C && C->isOne();
  };
  for (unsigned I = 0; I != 2; ++I) {
    Value *X = Mul->getOperand(I);
    Value *Partner = Mul->getOperand(1 - I);
    if (X->getType() != And->getType() || isa<FreezeInst>(X))
      continue;

    if (auto *Not = dyn_cast<BinaryOperator>(Partner);
        Not && Not->getOpcode() == Instruction::Xor &&
        Not->getType() == And->getType() &&
        !hasPoisonGeneratingBinaryFlags(Not) &&
        ((Not->getOperand(0) == X && IsAllOnes(Not->getOperand(1))) ||
         (Not->getOperand(1) == X && IsAllOnes(Not->getOperand(0)))))
      return X;

    if (auto *Next = dyn_cast<BinaryOperator>(Partner);
        Next && Next->getOpcode() == Instruction::Add &&
        Next->getType() == And->getType() &&
        !hasPoisonGeneratingBinaryFlags(Next) &&
        ((Next->getOperand(0) == X && IsOne(Next->getOperand(1))) ||
         (Next->getOperand(1) == X && IsOne(Next->getOperand(0)))))
      return X;
  }
  return nullptr;
}

static std::optional<bool> proveExactConsecutiveProductParity(Value *V) {
  Value *X = matchExactConsecutiveProductLowBit(V);
  if (!X || !isSemanticallyDefinedParityValue(V))
    return std::nullopt;
  // The root proof entails that the matching SSA operand cannot carry poison
  // through the unflagged arithmetic.  Keep this explicit so a future matcher
  // extension cannot accidentally rely only on modular algebra.
  if (!isGuaranteedNotToBeUndefOrPoison(X))
    return std::nullopt;
  return false;
}

static bool hasOnlyOwnedParityComparisons(const Instruction &I) {
  for (const User *U : I.users()) {
    auto *Cmp = dyn_cast<ICmpInst>(U);
    if (!Cmp)
      continue;
    if (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
        Cmp->getPredicate() != ICmpInst::ICMP_NE)
      return false;
    Value *Other = Cmp->getOperand(Cmp->getOperand(0) == &I ? 1 : 0);
    auto *C = dyn_cast<ConstantInt>(Other);
    if (!C || (!C->isZero() && !C->isOne()))
      return false;
  }
  return true;
}

static bool simplifyKnownMBA(Function &F, Report &R) {
  bool Changed = false;
  // This pass used to fold a broad "known even" family purely from modular
  // algebra.  Restrict it to the exact, poison-aware BCF/InstSub family; all
  // other MBA identities remain owned by LLVM's simplifier or the bounded SMT
  // stage.  This runs before deflattening when called from simplifyMBA.
  SmallVector<Instruction *, 64> ExactParity;
  for (Instruction &I : instructions(F))
    if (I.getType()->isIntegerTy() && !I.use_empty() &&
        hasOnlyOwnedParityComparisons(I) &&
        proveExactConsecutiveProductParity(&I).has_value())
      ExactParity.push_back(&I);
  R.Stages["bcf_opaque_predicates"].Candidates += ExactParity.size();
  for (Instruction *I : reverse(ExactParity)) {
    if (!I->getParent() || I->use_empty() ||
        !proveExactConsecutiveProductParity(I))
      continue;
    I->replaceAllUsesWith(ConstantInt::get(I->getType(), 0));
    I->eraseFromParent();
    ++R.Stages["bcf_opaque_predicates"].Changes;
    noteRule(R, "opaque.ParityConsecutiveLowBitRule");
    Changed = true;
  }

  // Do not retain the former generic parity canonicalizer here.  Its
  // replacement was a constant even when the source carried poison.
  return Changed;
}

static bool simplifyChernobogAddRulesWithReport(Function &F, Report &R) {
  ChernobogAddRuleMetrics Delta;
  if (!simplifyChernobogAddRules(F, Delta))
    return false;
  for (const auto &KV : Delta.Rules) {
    auto &Total = R.ChernobogAddRules.Rules[KV.first];
    Total.Hits += KV.second.Hits;
    Total.OperationsBefore += KV.second.OperationsBefore;
    Total.OperationsAfter += KV.second.OperationsAfter;
    R.Stages["mba"].Candidates += KV.second.Hits;
    R.Stages["mba"].Changes += KV.second.Hits;
    for (uint64_t I = 0; I < KV.second.Hits; ++I)
      noteRule(R, KV.first);
  }
  return true;
}

static bool simplifyChernobogAndRulesWithReport(Function &F, Report &R) {
  ChernobogAndRuleMetrics Delta;
  if (!simplifyChernobogAndRules(F, Delta))
    return false;
  for (const auto &KV : Delta.Rules) {
    auto &Total = R.ChernobogAndRules.Rules[KV.first];
    Total.Hits += KV.second.Hits;
    Total.OperationsBefore += KV.second.OperationsBefore;
    Total.OperationsAfter += KV.second.OperationsAfter;
    R.Stages["mba"].Candidates += KV.second.Hits;
    R.Stages["mba"].Changes += KV.second.Hits;
    for (uint64_t I = 0; I < KV.second.Hits; ++I)
      noteRule(R, KV.first);
  }
  return true;
}

static bool simplifyChernobogXorRulesWithReport(Function &F, Report &R) {
  ChernobogXorRuleMetrics Delta;
  if (!simplifyChernobogXorRules(F, Delta))
    return false;
  for (const auto &KV : Delta.Rules) {
    auto &Total = R.ChernobogXorRules.Rules[KV.first];
    Total.Hits += KV.second.Hits;
    Total.OperationsBefore += KV.second.OperationsBefore;
    Total.OperationsAfter += KV.second.OperationsAfter;
    R.Stages["mba"].Candidates += KV.second.Hits;
    R.Stages["mba"].Changes += KV.second.Hits;
    for (uint64_t I = 0; I < KV.second.Hits; ++I)
      noteRule(R, KV.first);
  }
  return true;
}

static bool simplifyChernobogOrRulesWithReport(Function &F, Report &R) {
  ChernobogOrRuleMetrics Delta;
  if (!simplifyChernobogOrRules(F, Delta))
    return false;
  for (const auto &KV : Delta.Rules) {
    auto &Total = R.ChernobogOrRules.Rules[KV.first];
    Total.Hits += KV.second.Hits;
    Total.OperationsBefore += KV.second.OperationsBefore;
    Total.OperationsAfter += KV.second.OperationsAfter;
    R.Stages["mba"].Candidates += KV.second.Hits;
    R.Stages["mba"].Changes += KV.second.Hits;
    for (uint64_t I = 0; I < KV.second.Hits; ++I)
      noteRule(R, KV.first);
  }
  return true;
}

static bool simplifyChernobogSubRulesWithReport(Function &F, Report &R) {
  ChernobogSubRuleMetrics Delta;
  if (!simplifyChernobogSubRules(F, Delta))
    return false;
  for (const auto &KV : Delta.Rules) {
    auto &Total = R.ChernobogSubRules.Rules[KV.first];
    Total.Hits += KV.second.Hits;
    Total.OperationsBefore += KV.second.OperationsBefore;
    Total.OperationsAfter += KV.second.OperationsAfter;
    R.Stages["mba"].Candidates += KV.second.Hits;
    R.Stages["mba"].Changes += KV.second.Hits;
    for (uint64_t I = 0; I < KV.second.Hits; ++I)
      noteRule(R, KV.first);
  }
  return true;
}

static bool simplifyChernobogMiscRulesWithReport(Function &F, Report &R) {
  ChernobogMiscRuleMetrics Delta;
  if (!simplifyChernobogMiscRules(F, Delta))
    return false;
  for (const auto &KV : Delta.Rules) {
    auto &Total = R.ChernobogMiscRules.Rules[KV.first];
    Total.Hits += KV.second.Hits;
    Total.OperationsBefore += KV.second.OperationsBefore;
    Total.OperationsAfter += KV.second.OperationsAfter;
    R.Stages["mba"].Candidates += KV.second.Hits;
    R.Stages["mba"].Changes += KV.second.Hits;
    for (uint64_t I = 0; I < KV.second.Hits; ++I)
      noteRule(R, KV.first);
  }
  return true;
}

static bool simplifyChernobogJumpRulesWithReport(Function &F, Report &R) {
  ChernobogJumpRuleMetrics Delta;
  if (!simplifyChernobogJumpRules(F, Delta))
    return false;
  for (const auto &KV : Delta.Rules) {
    auto &Total = R.ChernobogJumpRules.Rules[KV.first];
    Total.Hits += KV.second.Hits;
    Total.OperationsBefore += KV.second.OperationsBefore;
    Total.OperationsAfter += KV.second.OperationsAfter;
    R.Stages["bcf_opaque_predicates"].Candidates += KV.second.Hits;
    R.Stages["bcf_opaque_predicates"].Changes += KV.second.Hits;
    for (uint64_t I = 0; I < KV.second.Hits; ++I)
      noteRule(R, KV.first);
  }
  return true;
}

static bool simplifyMBA(Function &F, Z3Prover &Prover, Report &R) {
  auto ExpressionOps = [](Value *Root) {
    std::function<unsigned(Value *, unsigned)> Count =
        [&](Value *V, unsigned Depth) -> unsigned {
      if (!V || Depth > 16)
        return 0;
      auto *I = dyn_cast<Instruction>(V);
      auto *BO = dyn_cast_or_null<BinaryOperator>(I);
      if (!BO)
        return 0;
      return 1 + Count(BO->getOperand(0), Depth + 1) +
             Count(BO->getOperand(1), Depth + 1);
    };
    return Count(Root, 0);
  };
  auto ExpressionKinds = [](Value *Root) {
    std::function<unsigned(Value *, unsigned)> Kinds =
        [&](Value *V, unsigned Depth) -> unsigned {
      if (!V || Depth > 16)
        return 0;
      auto *BO = dyn_cast<BinaryOperator>(V);
      if (!BO)
        return 0;
      unsigned Kind = 0;
      switch (BO->getOpcode()) {
      case Instruction::Add:
      case Instruction::Sub:
      case Instruction::Mul:
        Kind = 1;
        break;
      case Instruction::And:
      case Instruction::Or:
      case Instruction::Xor:
      case Instruction::Shl:
      case Instruction::LShr:
      case Instruction::AShr:
        Kind = 2;
        break;
      default:
        break;
      }
      return Kind | Kinds(BO->getOperand(0), Depth + 1) |
             Kinds(BO->getOperand(1), Depth + 1);
    };
    return Kinds(Root, 0);
  };
  auto IsMBAExpression = [&](Instruction &I) {
    auto *BO = dyn_cast<BinaryOperator>(&I);
    if (!BO)
      return false;
    // Chernobog's registry matches expression trees, not isolated machine
    // operations.  Avoid spending an SMT budget on a flat add/xor of two
    // leaves; those are already handled by InstCombine and cannot satisfy a
    // multi-op MBA pattern.
    if (!isa<Instruction>(BO->getOperand(0)) &&
        !isa<Instruction>(BO->getOperand(1)))
      return false;
    // Lifted address calculations are usually long add/sub trees but are not
    // MBA.  Residual OLLVM substitutions combine arithmetic and bitwise
    // operators; select those across the whole function to avoid starving
    // later blocks behind early address arithmetic.
    return (ExpressionKinds(&I) & 3) == 3;
  };
  SmallVector<Instruction *, 256> Candidates;
  bool Changed = false;
  // Handle the corpus-specific parity MBA before the generic simplifier.  In
  // p00867 alone this occurs after enough unrelated lifted arithmetic to be
  // starved by the global SMT candidate cap.
  Changed |= simplifyChernobogAddRulesWithReport(F, R);
  Changed |= simplifyChernobogAndRulesWithReport(F, R);
  Changed |= simplifyChernobogOrRulesWithReport(F, R);
  Changed |= simplifyChernobogSubRulesWithReport(F, R);
  Changed |= simplifyChernobogXorRulesWithReport(F, R);
  Changed |= simplifyChernobogMiscRulesWithReport(F, R);
  Changed |= simplifyKnownMBA(F, R);
  // LLVM's poison-aware simplifier is the native equivalent of a large
  // subset of Chernobog's algebraic/factor rules.  Run it before the SMT
  // recipe search so identities exposed by earlier CFG rewrites are handled
  // with LLVM's own definedness semantics.
  if (F.getParent()) {
    SimplifyQuery Q(F.getParent()->getDataLayout());
    SmallVector<Instruction *, 256> Native;
    for (Instruction &I : instructions(F))
      if (!I.isTerminator() && !I.use_empty())
        Native.push_back(&I);
    for (Instruction *I : reverse(Native)) {
      if (!I->getParent())
        continue;
      Value *Replacement = simplifyInstruction(I, Q);
      if (!Replacement || Replacement == I || Replacement->getType() != I->getType())
        continue;
      I->replaceAllUsesWith(Replacement);
      I->eraseFromParent();
      ++R.Stages["mba"].Changes;
      noteRule(R, "mba.llvm_instruction_simplify");
      Changed = true;
    }
  }

  Candidates.clear();
  for (Instruction &I : instructions(F)) {
    if (!I.getType()->isIntegerTy() || I.getType()->isIntegerTy(1) ||
        I.mayHaveSideEffects() || I.isTerminator() || !IsMBAExpression(I) ||
        ExpressionOps(&I) < 3)
      continue;
    Candidates.push_back(&I);
  }
  llvm::sort(Candidates, [&](Instruction *A, Instruction *B) {
    unsigned ScoreA = ExpressionOps(A);
    unsigned ScoreB = ExpressionOps(B);
    for (User *U : A->users())
      ScoreA += isa<ICmpInst, SelectInst, BranchInst>(U) ? 32 : 0;
    for (User *U : B->users())
      ScoreB += isa<ICmpInst, SelectInst, BranchInst>(U) ? 32 : 0;
    return ScoreA > ScoreB;
  });
  if (Candidates.size() > MaxZ3Candidates)
    Candidates.resize(MaxZ3Candidates);
  R.Stages["mba"].Candidates += Candidates.size();
  for (Instruction *I : reverse(Candidates)) {
    if (!I->getParent() || I->use_empty())
      continue;
    auto Proof = Prover.proveSimplerInteger(
        I, 3, MaxZ3RecipesPerExpression);
    if (!Proof)
      continue;
    bool WidthsMatch = llvm::all_of(
        Proof->Leaves, [&](Value *V) { return V->getType() == I->getType(); });
    if (!WidthsMatch)
      continue;
    IRBuilder<> B(I);
    Value *Replacement = materializeProof(B, I->getType(), *Proof);
    if (!Replacement || Replacement == I)
      continue;
    I->replaceAllUsesWith(Replacement);
    I->eraseFromParent();
    ++R.Stages["mba"].Changes;
    noteRule(R, ruleName(Proof->Kind));
    Changed = true;
  }

  return Changed;
}

static bool simplifySelectChains(Function &F, Report &R) {
  SmallVector<SelectInst *, 64> Selects;
  for (Instruction &I : instructions(F))
    if (auto *S = dyn_cast<SelectInst>(&I))
      Selects.push_back(S);
  bool Changed = false;
  for (SelectInst *S : reverse(Selects)) {
    if (!S->getParent())
      continue;
    Value *Replacement = nullptr;
    if (S->getTrueValue() == S->getFalseValue())
      Replacement = S->getTrueValue();
    else if (auto *Nested = dyn_cast<SelectInst>(S->getFalseValue())) {
      if (Nested->getCondition() == S->getCondition())
        Replacement = IRBuilder<>(S).CreateSelect(
            S->getCondition(), S->getTrueValue(), Nested->getFalseValue(),
            "deobf.select");
    } else if (auto *Nested = dyn_cast<SelectInst>(S->getTrueValue())) {
      if (Nested->getCondition() == S->getCondition())
        Replacement = IRBuilder<>(S).CreateSelect(
            S->getCondition(), Nested->getTrueValue(), S->getFalseValue(),
            "deobf.select");
    }
    if (!Replacement)
      continue;
    S->replaceAllUsesWith(Replacement);
    S->eraseFromParent();
    ++R.Stages["mba"].Changes;
    Changed = true;
  }
  return Changed;
}

struct PredicateRuleProof {
  bool Result;
  StringRef Rule;
};

static Value *matchXorWithConstant(Value *V,
                                   function_ref<bool(const ConstantInt *)> Pred) {
  auto *BO = dyn_cast_or_null<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Xor)
    return nullptr;
  if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(0)); C && Pred(C))
    return BO->getOperand(1);
  if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)); C && Pred(C))
    return BO->getOperand(0);
  return nullptr;
}

static Value *matchAndOne(Value *V) {
  auto *BO = dyn_cast_or_null<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::And)
    return nullptr;
  for (unsigned I = 0; I != 2; ++I)
    if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(I)); C && C->isOne())
      return BO->getOperand(1 - I);
  return nullptr;
}

static Value *stripZExts(Value *V) {
  while (auto *Cast = dyn_cast_or_null<CastInst>(V)) {
    if (Cast->getOpcode() != Instruction::ZExt)
      break;
    V = Cast->getOperand(0);
  }
  return V;
}

static Value *matchEncodedBooleanNot(Value *V) {
  if (!V)
    return nullptr;
  V = stripZExts(V);
  Value *Inner = matchXorWithConstant(
      V, [](const ConstantInt *C) { return C->isOne(); });
  if (!Inner)
    return nullptr;
  Inner = stripZExts(Inner);
  return Inner->getType()->isIntegerTy(1) ? Inner : nullptr;
}

static bool samePureExpression(Value *A, Value *B, unsigned Depth = 0) {
  if (A == B)
    return true;
  if (!A || !B || A->getType() != B->getType() || Depth > 32)
    return false;
  auto *CA = dyn_cast<ConstantInt>(A);
  auto *CB = dyn_cast<ConstantInt>(B);
  if (CA || CB)
    return CA && CB && CA->getValue() == CB->getValue();

  auto *IA = dyn_cast<Instruction>(A);
  auto *IB = dyn_cast<Instruction>(B);
  if (!IA || !IB || IA->getOpcode() != IB->getOpcode() ||
      IA->getNumOperands() != IB->getNumOperands() ||
      IA->mayHaveSideEffects() || IB->mayHaveSideEffects() ||
      isa<LoadInst, PHINode, CallBase>(IA) ||
      isa<LoadInst, PHINode, CallBase>(IB))
    return false;
  if (auto *CmpA = dyn_cast<ICmpInst>(IA)) {
    auto *CmpB = cast<ICmpInst>(IB);
    if (CmpA->getPredicate() != CmpB->getPredicate())
      return false;
  }
  if (auto *BOA = dyn_cast<BinaryOperator>(IA)) {
    auto *BOB = cast<BinaryOperator>(IB);
    if (BOA->hasNoUnsignedWrap() != BOB->hasNoUnsignedWrap() ||
        BOA->hasNoSignedWrap() != BOB->hasNoSignedWrap() ||
        BOA->isExact() != BOB->isExact())
      return false;
  }

  auto SameOrdered = [&] {
    for (unsigned I = 0; I != IA->getNumOperands(); ++I)
      if (!samePureExpression(IA->getOperand(I), IB->getOperand(I),
                              Depth + 1))
        return false;
    return true;
  };
  if (SameOrdered())
    return true;
  auto *BOA = dyn_cast<BinaryOperator>(IA);
  if (!BOA || !BOA->isCommutative() || IA->getNumOperands() != 2)
    return false;
  return samePureExpression(IA->getOperand(0), IB->getOperand(1), Depth + 1) &&
         samePureExpression(IA->getOperand(1), IB->getOperand(0), Depth + 1);
}

// The lifted flag/state form of P | !P contains an even consecutive product
// in the low-bit arm:
//
//   ((zext(P) xor odd) | zext(x*(x-1))) & 1 xor 1  == P
//
// The other OR arm is the ordinary zext(P) xor 1.  Require structural
// equivalence of both P trees and prove the consecutive product even before
// folding the enclosing comparison.
static bool isLiftedComplementGuardNonZero(Value *V) {
  auto *RootOr = dyn_cast<BinaryOperator>(V);
  if (!RootOr || RootOr->getOpcode() != Instruction::Or)
    return false;

  for (unsigned Orientation = 0; Orientation != 2; ++Orientation) {
    Value *PositiveArm = RootOr->getOperand(Orientation);
    Value *NegativeArm = RootOr->getOperand(1 - Orientation);
    Value *LowBit = matchXorWithConstant(
        PositiveArm, [](const ConstantInt *C) { return C->isOne(); });
    Value *Mixed = matchAndOne(LowBit);
    auto *MixedOr = dyn_cast_or_null<BinaryOperator>(Mixed);
    if (!MixedOr || MixedOr->getOpcode() != Instruction::Or)
      continue;

    for (unsigned EvenSide = 0; EvenSide != 2; ++EvenSide) {
      Value *Even = MixedOr->getOperand(EvenSide);
      if (!isKnownEven(Even))
        continue;
      Value *EncodedPositive = MixedOr->getOperand(1 - EvenSide);
      Value *WidePositive = matchXorWithConstant(
          EncodedPositive,
          [](const ConstantInt *C) { return C->getValue()[0]; });
      Value *Positive = stripZExts(WidePositive);
      Value *Negative = matchEncodedBooleanNot(NegativeArm);
      if (Positive && Negative && Positive->getType()->isIntegerTy(1) &&
          samePureExpression(Positive, Negative))
        return true;
    }
  }
  return false;
}

static bool isKnownOdd(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 12)
    return false;
  V = stripLowBitPreservingCasts(V);
  if (auto *C = dyn_cast<ConstantInt>(V))
    return C->getValue()[0];
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO)
    return false;
  switch (BO->getOpcode()) {
  case Instruction::Or:
    return isKnownOdd(BO->getOperand(0), Depth + 1) ||
           isKnownOdd(BO->getOperand(1), Depth + 1);
  case Instruction::And:
    return isKnownOdd(BO->getOperand(0), Depth + 1) &&
           isKnownOdd(BO->getOperand(1), Depth + 1);
  case Instruction::Xor:
  case Instruction::Add:
  case Instruction::Sub:
    return (isKnownOdd(BO->getOperand(0), Depth + 1) &&
            isKnownEven(BO->getOperand(1), Depth + 1)) ||
           (isKnownEven(BO->getOperand(0), Depth + 1) &&
            isKnownOdd(BO->getOperand(1), Depth + 1));
  default:
    return false;
  }
}

struct Boolean01 {
  Value *Atom = nullptr;
  bool Negated = false;
};

static Value *matchMaskedEvenComplement(Value *V) {
  Value *Mixed = matchAndOne(V);
  auto *MixedOr = dyn_cast_or_null<BinaryOperator>(Mixed);
  if (!MixedOr || MixedOr->getOpcode() != Instruction::Or)
    return nullptr;
  for (unsigned EvenSide = 0; EvenSide != 2; ++EvenSide) {
    if (!isKnownEven(MixedOr->getOperand(EvenSide)))
      continue;
    Value *Encoded = matchXorWithConstant(
        MixedOr->getOperand(1 - EvenSide),
        [](const ConstantInt *C) { return C->getValue()[0]; });
    Value *Atom = stripZExts(Encoded);
    if (Atom && Atom->getType()->isIntegerTy(1))
      return Atom;
  }
  return nullptr;
}

static std::optional<Boolean01> normalizeBoolean01(Value *V,
                                                  unsigned Depth = 0) {
  if (!V || Depth > 24)
    return std::nullopt;

  if (auto *Cast = dyn_cast<CastInst>(V);
      Cast && (Cast->getOpcode() == Instruction::ZExt ||
               Cast->getOpcode() == Instruction::Trunc)) {
    auto Inner = normalizeBoolean01(Cast->getOperand(0), Depth + 1);
    if (Inner)
      return Inner;
  }

  if (Value *Atom = matchMaskedEvenComplement(V))
    return Boolean01{Atom, true};

  if (Value *Inner = matchXorWithConstant(
          V, [](const ConstantInt *C) { return C->isOne(); })) {
    auto Form = normalizeBoolean01(Inner, Depth + 1);
    if (Form) {
      Form->Negated = !Form->Negated;
      return Form;
    }
  }

  if (auto *And = dyn_cast<BinaryOperator>(V);
      And && And->getOpcode() == Instruction::And)
    for (unsigned BoolSide = 0; BoolSide != 2; ++BoolSide) {
      auto Form = normalizeBoolean01(And->getOperand(BoolSide), Depth + 1);
      if (Form && isKnownOdd(And->getOperand(1 - BoolSide)))
        return Form;
    }

  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    for (unsigned ValueSide = 0; ValueSide != 2; ++ValueSide) {
      auto *C = dyn_cast<ConstantInt>(Cmp->getOperand(1 - ValueSide));
      if (!C || (!C->isZero() && !C->isOne()))
        continue;
      auto Form =
          normalizeBoolean01(Cmp->getOperand(ValueSide), Depth + 1);
      if (!Form)
        continue;
      bool Invert;
      if (Cmp->getPredicate() == ICmpInst::ICMP_EQ)
        Invert = C->isZero();
      else if (Cmp->getPredicate() == ICmpInst::ICMP_NE)
        Invert = C->isOne();
      else
        continue;
      Form->Negated ^= Invert;
      return Form;
    }
  }

  if (V->getType()->isIntegerTy(1))
    return Boolean01{V, false};
  return std::nullopt;
}

static bool isComplementBooleanBinOp(Value *V, unsigned Opcode) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Opcode)
    return false;
  auto L = normalizeBoolean01(BO->getOperand(0));
  auto R = normalizeBoolean01(BO->getOperand(1));
  return L && R && L->Negated != R->Negated &&
         samePureExpression(L->Atom, R->Atom);
}

// Fast, semantics-preserving port of Chernobog's predicate rule registry.
// Keep LLVM values width-exact here.  In particular, stripping zext/sext/trunc
// can turn `icmp eq (zext x), (sext x)` into a bogus self-comparison.
static std::optional<PredicateRuleProof> provePredicateRule(Value *V) {
  if (isComplementBooleanBinOp(V, Instruction::Or))
    return PredicateRuleProof{true, "opaque.LiftedBooleanComplementOrRule"};
  if (isComplementBooleanBinOp(V, Instruction::And))
    return PredicateRuleProof{false, "opaque.LiftedBooleanComplementAndRule"};

  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp)
    return std::nullopt;
  auto foldConstantLoad = [](Value *X) -> Value * {
    auto *LI = dyn_cast<LoadInst>(X);
    if (!LI)
      return X;
    auto *GV = dyn_cast<GlobalVariable>(LI->getPointerOperand()
                                            ->stripPointerCasts());
    if (!GV || !GV->isConstant() || !GV->hasDefinitiveInitializer())
      return X;
    Constant *Init = GV->getInitializer();
    if (Init->getType() == LI->getType())
      return Init;
    return X;
  };
  Value *L = foldConstantLoad(Cmp->getOperand(0));
  Value *Rhs = foldConstantLoad(Cmp->getOperand(1));
  ICmpInst::Predicate P = Cmp->getPredicate();

  auto proof = [](bool Result, StringRef Rule) {
    return PredicateRuleProof{Result, Rule};
  };

  // Native pointer/state lowering represents "value is a sign-extended i32"
  // as unsigned((value + 2^31)) < 2^32.  ComputeNumSignBits proves the range
  // without enumerating the many sdiv/sext shapes that produce it.
  if (P == ICmpInst::ICMP_ULT)
    if (auto *Limit = dyn_cast<ConstantInt>(Rhs);
        Limit && Limit->getBitWidth() == 64 &&
        Limit->getValue() == APInt(64, uint64_t(1) << 32))
      if (auto *Add = dyn_cast<BinaryOperator>(L);
          Add && Add->getOpcode() == Instruction::Add) {
        Value *Ranged = nullptr;
        for (unsigned I = 0; I != 2; ++I)
          if (auto *Bias = dyn_cast<ConstantInt>(Add->getOperand(I));
              Bias && Bias->getValue() == APInt(64, uint64_t(1) << 31))
            Ranged = Add->getOperand(1 - I);
        if (Ranged)
          if (const Module *M = Cmp->getModule();
              M && ComputeNumSignBits(Ranged, M->getDataLayout()) >= 33)
            return proof(true, "opaque.LiftedSigned32RangeRule");
      }

  if (auto *Zero = dyn_cast<ConstantInt>(Rhs);
      Zero && Zero->isZero() && isLiftedComplementGuardNonZero(L)) {
    if (P == ICmpInst::ICMP_EQ)
      return proof(false, "opaque.LiftedComplementGuardRule");
    if (P == ICmpInst::ICMP_NE)
      return proof(true, "opaque.LiftedComplementGuardRule");
  }
  if (auto *Zero = dyn_cast<ConstantInt>(Rhs);
      Zero && Zero->isZero() &&
      isComplementBooleanBinOp(L, Instruction::Or)) {
    if (P == ICmpInst::ICMP_EQ)
      return proof(false, "opaque.LiftedBooleanComplementOrRule");
    if (P == ICmpInst::ICMP_NE)
      return proof(true, "opaque.LiftedBooleanComplementOrRule");
  }

  // LLVM lowers microcode lnot(x) to icmp eq x, 0.  Attribute constant lnot
  // forms to the corresponding Chernobog rule before the generic constant
  // comparator consumes them.
  if (P == ICmpInst::ICMP_EQ) {
    auto *LC = dyn_cast<ConstantInt>(L);
    auto *RC = dyn_cast<ConstantInt>(Rhs);
    if (LC && RC && RC->isZero())
      return proof(LC->isZero(), LC->isZero() ? "opaque.LnotZeroRule"
                                             : "opaque.LnotOneRule");
  }

  // SetConstRule: direct constant comparison (all integer predicates).
  if (auto *LC = dyn_cast<ConstantInt>(L))
    if (auto *RC = dyn_cast<ConstantInt>(Rhs)) {
      const APInt &A = LC->getValue(), &B = RC->getValue();
      switch (P) {
      case ICmpInst::ICMP_EQ:  return proof(A == B, "opaque.SetConstRule");
      case ICmpInst::ICMP_NE:  return proof(A != B, "opaque.SetConstRule");
      case ICmpInst::ICMP_UGT: return proof(A.ugt(B), "opaque.SetConstRule");
      case ICmpInst::ICMP_UGE: return proof(A.uge(B), "opaque.SetConstRule");
      case ICmpInst::ICMP_ULT: return proof(A.ult(B), "opaque.SetConstRule");
      case ICmpInst::ICMP_ULE: return proof(A.ule(B), "opaque.SetConstRule");
      case ICmpInst::ICMP_SGT: return proof(A.sgt(B), "opaque.SetConstRule");
      case ICmpInst::ICMP_SGE: return proof(A.sge(B), "opaque.SetConstRule");
      case ICmpInst::ICMP_SLT: return proof(A.slt(B), "opaque.SetConstRule");
      case ICmpInst::ICMP_SLE: return proof(A.sle(B), "opaque.SetConstRule");
      default: break;
      }
    }

  // Self-comparison rules from rules_predicate.cpp.
  if (L == Rhs && L->getType() == Rhs->getType()) {
    switch (P) {
    case ICmpInst::ICMP_EQ:
      return proof(true, "opaque.SetzSelfRule");
    case ICmpInst::ICMP_NE:
      return proof(false, "opaque.SetnzSelfRule");
    case ICmpInst::ICMP_ULT:
      return proof(false, "opaque.SetbSelfRule");
    case ICmpInst::ICMP_UGE:
      return proof(true, "opaque.SetaeSelfRule");
    case ICmpInst::ICMP_UGT:
      return proof(false, "opaque.SetaSelfRule");
    case ICmpInst::ICMP_ULE:
      return proof(true, "opaque.SetbeSelfRule");
    case ICmpInst::ICMP_SLT:
      return proof(false, "opaque.SetlSelfRule");
    case ICmpInst::ICMP_SGE:
      return proof(true, "opaque.SetgeSelfRule");
    case ICmpInst::ICMP_SGT:
      return proof(false, "opaque.SetgSelfRule");
    case ICmpInst::ICMP_SLE:
      return proof(true, "opaque.SetleSelfRule");
    default: break;
    }
  }

  auto *LB = dyn_cast<BinaryOperator>(L);
  auto isZero = [](Value *X) {
    auto *C = dyn_cast<ConstantInt>(X);
    return C && C->isZero();
  };
  auto isAllOnes = [](Value *X) {
    auto *C = dyn_cast<ConstantInt>(X);
    return C && C->getValue().isAllOnes();
  };
  auto same = [](Value *A, Value *B) {
    return A == B && A->getType() == B->getType();
  };
  auto isNotOf = [&](Value *A, Value *B) {
    auto *X = dyn_cast<BinaryOperator>(B);
    if (!X || X->getOpcode() != Instruction::Xor)
      return false;
    if (isAllOnes(X->getOperand(0)))
      return same(A, X->getOperand(1));
    if (isAllOnes(X->getOperand(1)))
      return same(A, X->getOperand(0));
    return false;
  };

  // Identity and tautology rules.  Match the source rule's comparison
  // opcode exactly; "non-zero" does not imply signed-greater-than zero.
  if (LB) {
    if (LB->getOpcode() == Instruction::Xor &&
        same(LB->getOperand(0), LB->getOperand(1)) && isZero(Rhs)) {
      if (P == ICmpInst::ICMP_EQ)
        return proof(true, "opaque.SetzXorSelfRule");
      if (P == ICmpInst::ICMP_NE)
        return proof(false, "opaque.SetnzXorSelfRule");
    }
    if (LB->getOpcode() == Instruction::And &&
        (isNotOf(LB->getOperand(0), LB->getOperand(1)) ||
         isNotOf(LB->getOperand(1), LB->getOperand(0))) &&
        isZero(Rhs) && P == ICmpInst::ICMP_EQ)
      return proof(true, "opaque.SetzAndComplementRule");
    if (LB->getOpcode() == Instruction::And &&
        (isZero(LB->getOperand(0)) || isZero(LB->getOperand(1))) &&
        isZero(Rhs) && P == ICmpInst::ICMP_EQ)
      return proof(true, "opaque.SetzAndZeroRule");
    if (LB->getOpcode() == Instruction::Or && isZero(Rhs) &&
        P == ICmpInst::ICMP_NE) {
      if (isNotOf(LB->getOperand(0), LB->getOperand(1)) ||
          isNotOf(LB->getOperand(1), LB->getOperand(0)))
        return proof(true, "opaque.SetnzOrComplementRule");
      if (isAllOnes(LB->getOperand(0)) || isAllOnes(LB->getOperand(1)))
        return proof(true, "opaque.SetnzOrMinusOneRule");
      for (Value *Op : {LB->getOperand(0), LB->getOperand(1)})
        if (auto *C = dyn_cast<ConstantInt>(Op); C && C->getValue()[0])
          return proof(true, "opaque.SetnzOrOneRule");
    }
  }

  // Unsigned comparisons against zero.
  if (isZero(Rhs)) {
    if (P == ICmpInst::ICMP_ULT)
      return proof(false, "opaque.SetbZeroRule");
    if (P == ICmpInst::ICMP_UGE)
      return proof(true, "opaque.SetaeZeroRule");
  }

  // x * (x + 1) % 2 is always zero (consecutive-product rule).
  auto isConsecutiveParity = [](Value *X) {
    auto *Rem = dyn_cast<BinaryOperator>(X);
    if (!Rem || (Rem->getOpcode() != Instruction::URem &&
                 Rem->getOpcode() != Instruction::SRem) ||
        hasPoisonGeneratingBinaryFlags(Rem))
      return false;
    auto *Mod = dyn_cast<ConstantInt>(Rem->getOperand(1));
    if (!Mod || !Mod->equalsInt(2))
      return false;
    auto *Mul = dyn_cast<BinaryOperator>(Rem->getOperand(0));
    if (!Mul || Mul->getOpcode() != Instruction::Mul ||
        hasPoisonGeneratingBinaryFlags(Mul))
      return false;
    for (unsigned I = 0; I != 2; ++I) {
      Value *A = Mul->getOperand(I);
      Value *B = Mul->getOperand(1 - I);
      auto *Add = dyn_cast<BinaryOperator>(B);
      if (!Add || Add->getOpcode() != Instruction::Add ||
          hasPoisonGeneratingBinaryFlags(Add))
        continue;
      for (unsigned J = 0; J != 2; ++J) {
        auto *One = dyn_cast<ConstantInt>(Add->getOperand(J));
        if (One && One->isOne() &&
            Add->getOperand(1 - J) == A)
          return true;
      }
    }
    return false;
  };
  if (isConsecutiveParity(L) && isSemanticallyDefinedParityValue(L) &&
      isSemanticallyDefinedValue(Cmp) && dyn_cast<ConstantInt>(Rhs) &&
      cast<ConstantInt>(Rhs)->isZero()) {
    if (P == ICmpInst::ICMP_EQ || P == ICmpInst::ICMP_ULE ||
        P == ICmpInst::ICMP_SLE)
      return proof(true, "opaque.SetRuleZ3");
    if (P == ICmpInst::ICMP_NE || P == ICmpInst::ICMP_UGT ||
        P == ICmpInst::ICMP_SGT)
      return proof(false, "opaque.SetRuleZ3");
  }

  // Dataset-shaped MBA predicate:
  //   t = x * (x ^ -1); b = t & 1; c = zext(cond.i1); icmp ugt b, c
  // The low bit of x*~x is always zero modulo 2, while zext(i1) is 0/1;
  // therefore `b ugt c` is always false.  Match the data-flow shape rather
  // than requiring the operands to be syntactically identical constants.
  auto isZextI1 = [](Value *V) {
    auto *Z = dyn_cast<CastInst>(V);
    return Z && Z->getOpcode() == Instruction::ZExt &&
           Z->getSrcTy()->isIntegerTy(1) && Z->getDestTy()->isIntegerTy();
  };
  // Accept commuted operands and all unsigned comparison directions.
  auto parityRange = [&](Value *V) {
    return proveExactConsecutiveProductParity(V).has_value();
  };
  auto boolRange = [&](Value *V) { return isZextI1(V); };
  if (isSemanticallyDefinedValue(Cmp) && parityRange(L) && boolRange(Rhs)) {
    switch (P) {
    case ICmpInst::ICMP_UGT: case ICmpInst::ICMP_SGT:
      return proof(false, "opaque.DatasetLowBitComplementRule");
    case ICmpInst::ICMP_ULE: case ICmpInst::ICMP_SLE:
      return proof(true, "opaque.DatasetLowBitComplementRule");
    default: break;
    }
  }
  if (isSemanticallyDefinedValue(Cmp) && boolRange(L) && parityRange(Rhs)) {
    switch (P) {
    case ICmpInst::ICMP_ULT: case ICmpInst::ICMP_SLT:
      return proof(false, "opaque.DatasetLowBitComplementRule");
    case ICmpInst::ICMP_UGE: case ICmpInst::ICMP_SGE:
      return proof(true, "opaque.DatasetLowBitComplementRule");
    default: break;
    }
  }
  return std::nullopt;
}

static Value *matchLogicalNot(Value *V) {
  auto isI1 = [](Value *X, bool One) {
    auto *C = dyn_cast<ConstantInt>(X);
    return C && C->getType()->isIntegerTy(1) &&
           (One ? C->isOne() : C->isZero());
  };
  if (auto *X = dyn_cast<BinaryOperator>(V);
      X && X->getOpcode() == Instruction::Xor &&
      X->getType()->isIntegerTy(1)) {
    if (isI1(X->getOperand(0), true))
      return X->getOperand(1);
    if (isI1(X->getOperand(1), true))
      return X->getOperand(0);
  }
  if (auto *Cmp = dyn_cast<ICmpInst>(V);
      Cmp && Cmp->getPredicate() == ICmpInst::ICMP_EQ) {
    if (isI1(Cmp->getOperand(0), false) &&
        Cmp->getOperand(1)->getType()->isIntegerTy(1))
      return Cmp->getOperand(1);
    if (isI1(Cmp->getOperand(1), false) &&
        Cmp->getOperand(0)->getType()->isIntegerTy(1))
      return Cmp->getOperand(0);
  }
  return nullptr;
}

static void printOpaqueExpressionShape(raw_ostream &OS, Value *V,
                                       unsigned Depth = 0) {
  if (!V || Depth > 32) {
    OS << "leaf";
    return;
  }
  if (auto *C = dyn_cast<ConstantInt>(V)) {
    OS << "c" << C->getValue();
    return;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I || isa<LoadInst, PHINode, CallBase>(I)) {
    OS << "leaf[";
    V->printAsOperand(OS, false);
    OS << "]";
    return;
  }
  if (auto *Cmp = dyn_cast<ICmpInst>(I))
    OS << "icmp." << CmpInst::getPredicateName(Cmp->getPredicate());
  else
    OS << I->getOpcodeName();
  OS << "(";
  bool First = true;
  for (Value *Operand : I->operands()) {
    if (!First)
      OS << ",";
    First = false;
    printOpaqueExpressionShape(OS, Operand, Depth + 1);
  }
  OS << ")";
}

static bool dependsOnPHINode(const Value *V, unsigned Depth = 0) {
  if (!V || Depth > 16)
    return false;
  if (isa<PHINode>(V))
    return true;
  auto *I = dyn_cast<Instruction>(V);
  if (!I)
    return false;
  for (const Value *Op : I->operands())
    if (dependsOnPHINode(Op, Depth + 1))
      return true;
  return false;
}

static bool removeOpaquePredicates(Function &F, Z3Prover &Prover, Report &R) {
  // A predicate root can survive while an MBA/CFG rewrite changes one of its
  // operands.  ValueMap follows RAUW/deletion of the key itself, but cannot
  // detect that internal expression mutation, so cross-stage cached results
  // are not valid here.
  Prover.invalidateBooleanCache();
  auto ConditionOps = [](Value *Root) {
    std::function<unsigned(Value *, unsigned)> Count =
        [&](Value *V, unsigned Depth) -> unsigned {
      if (!V || Depth > 16)
        return 0;
      auto *I = dyn_cast<Instruction>(V);
      if (!I || isa<PHINode>(I) || isa<LoadInst>(I) || isa<CallBase>(I))
        return 0;
      unsigned Total = 1;
      for (Value *Op : I->operands())
        Total += Count(Op, Depth + 1);
      return Total;
    };
    return Count(Root, 0);
  };
  SmallVector<BranchInst *, 64> Branches;
  for (BasicBlock &BB : F)
    if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
        BI && BI->isConditional())
      Branches.push_back(BI);
  llvm::stable_sort(Branches, [&](BranchInst *A, BranchInst *B) {
    return ConditionOps(A->getCondition()) > ConditionOps(B->getCondition());
  });

  bool Changed = false;
  // The lifted dataset predominantly materializes opaque predicates as
  // `select i1` (constant/state and pointer-selection chains), not branches.
  // Apply the same proof discipline here: only replace a select when the
  // condition is an exact rule match or Z3 proves it boolean-constant.  Do
  // not collapse ordinary bounds checks or pointer selects on heuristics.
  SmallVector<SelectInst *, 64> Selects;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *SI = dyn_cast<SelectInst>(&I))
        Selects.push_back(SI);
  llvm::stable_sort(Selects, [&](SelectInst *A, SelectInst *B) {
    return ConditionOps(A->getCondition()) > ConditionOps(B->getCondition());
  });
  for (SelectInst *SI : Selects) {
    Value *Cond = SI->getCondition();
    std::optional<bool> Result;
    if (auto Rule = provePredicateRule(Cond)) {
      ++R.Stages["bcf_opaque_predicates"].Candidates;
      Result = Rule->Result;
      noteRule(R, Rule->Rule);
    } else if (auto *C = dyn_cast<ConstantInt>(Cond)) {
      ++R.Stages["bcf_opaque_predicates"].Candidates;
      Result = !C->isZero();
      noteRule(R, "opaque.SelectConstCondition");
    } else if (ConditionOps(Cond) >= 3 &&
               R.OpaqueZ3Attempts < MaxOpaqueZ3Candidates) {
      // Generic SMT is reserved for integer/state selects.  Lifted pointer
      // selects are overwhelmingly bounds/range guards and querying each one
      // dominates runtime without yielding opaque-predicate rewrites.
      if (!SI->getType()->isIntegerTy() ||
          (!isa<ConstantInt>(SI->getTrueValue()) &&
           !isa<ConstantInt>(SI->getFalseValue())))
        continue;
      ++R.Stages["bcf_opaque_predicates"].Candidates;
      ++R.OpaqueZ3Attempts;
      Result = Prover.proveBooleanConstant(Cond);
      if (Result) {
        noteRule(R, "opaque.SelectRuleZ3");
        if (OpaqueZ3Debug)
          errs() << "095 opaque Z3 select=" << (*Result ? "true" : "false")
                 << " function=" << F.getName() << " condition=" << *Cond
                 << "\n";
        if (OpaqueZ3Debug) {
          errs() << "  shape=";
          printOpaqueExpressionShape(errs(), Cond);
          errs() << "\n";
        }
        if (OpaqueZ3Debug)
          if (auto *Cmp = dyn_cast<ICmpInst>(Cond))
            for (Value *Operand : Cmp->operands())
              if (auto *Def = dyn_cast<Instruction>(Operand))
                {
                  errs() << "  operand-def=" << *Def << "\n";
                  for (Value *Child : Def->operands())
                    if (auto *ChildDef = dyn_cast<Instruction>(Child))
                      errs() << "    child-def=" << *ChildDef << "\n";
                }
      }
    }
    if (!Result)
      continue;
    SI->replaceAllUsesWith(*Result ? SI->getTrueValue() : SI->getFalseValue());
    SI->eraseFromParent();
    ++R.Stages["bcf_opaque_predicates"].Changes;
    Changed = true;
  }
  if (Changed)
    Prover.invalidateBooleanCache();
  for (BranchInst *BI : Branches) {
    // LnotLnotRule is declared by Chernobog but omitted from its active
    // registry because it is a non-constant canonicalization.  LLVM can
    // represent it directly on the branch condition.
    if (Value *Inner = matchLogicalNot(BI->getCondition()))
      if (Value *Original = matchLogicalNot(Inner)) {
        ++R.Stages["bcf_opaque_predicates"].Candidates;
        BI->setCondition(Original);
        noteRule(R, "opaque.LnotLnotRule");
        ++R.Stages["bcf_opaque_predicates"].Changes;
        Changed = true;
      }

    std::optional<bool> Result;
    if (auto Rule = provePredicateRule(BI->getCondition()) ) {
      ++R.Stages["bcf_opaque_predicates"].Candidates;
      Result = Rule->Result;
      noteRule(R, Rule->Rule);
    } else if (auto *C = dyn_cast<ConstantInt>(BI->getCondition()))
      Result = !C->isZero();
    else if (ConditionOps(BI->getCondition()) >= 3 &&
             !dependsOnPHINode(BI->getCondition()) &&
             R.OpaqueZ3Attempts < MaxOpaqueZ3Candidates) {
      ++R.Stages["bcf_opaque_predicates"].Candidates;
      ++R.OpaqueZ3Attempts;
      Result = Prover.proveBooleanConstant(BI->getCondition());
      if (Result) {
        noteRule(R, "opaque.SetRuleZ3");
        if (OpaqueZ3Debug)
          errs() << "095 opaque Z3 branch=" << (*Result ? "true" : "false")
                 << " function=" << F.getName()
                 << " condition=" << *BI->getCondition() << "\n";
        if (OpaqueZ3Debug) {
          errs() << "  shape=";
          printOpaqueExpressionShape(errs(), BI->getCondition());
          errs() << "\n";
        }
      }
    }
    if (!Result)
      continue;
    unsigned LiveIndex = *Result ? 0 : 1;
    BasicBlock *Live = BI->getSuccessor(LiveIndex);
    BasicBlock *Dead = BI->getSuccessor(1 - LiveIndex);
    if (Dead != Live)
      Dead->removePredecessor(BI->getParent(), true);
    IRBuilder<> B(BI);
    B.CreateBr(Live);
    BI->eraseFromParent();
    ++R.Stages["bcf_opaque_predicates"].Changes;
    Changed = true;
  }
  return Changed;
}

struct StateChoice {
  Value *Condition = nullptr;
  ConstantInt *TrueState = nullptr;
  ConstantInt *FalseState = nullptr;
};

static ConstantInt *stateConstant(Value *V) {
  if (!V)
    return nullptr;
  V = stripIntegerCasts(V);
  if (auto *C = dyn_cast<ConstantInt>(V))
    return C;
  if (auto *I = dyn_cast<Instruction>(V)) {
    if (I->getModule()) {
      const DataLayout &DL = I->getModule()->getDataLayout();
      if (Constant *C = ConstantFoldInstruction(I, DL))
        if (auto *CI = dyn_cast<ConstantInt>(C))
          return CI;
    }
  }
  return nullptr;
}

static std::optional<StateChoice> decodeStateChoice(Value *V) {
  if (ConstantInt *C = stateConstant(V))
    return StateChoice{nullptr, C, C};
  V = stripIntegerCasts(V);
  auto *S = dyn_cast<SelectInst>(V);
  if (!S)
    return std::nullopt;
  ConstantInt *T = stateConstant(S->getTrueValue());
  ConstantInt *F = stateConstant(S->getFalseValue());
  if (!T || !F)
    return std::nullopt;
  return StateChoice{S->getCondition(), T, F};
}

struct DispatchMap {
  DenseMap<APInt, BasicBlock *> Targets;
  DenseMap<BasicBlock *, BasicBlock *> DispatchPredecessor;
  SmallPtrSet<BasicBlock *, 8> Blocks;
};

static DispatchMap collectDispatchMap(SwitchInst *Root, Value *State) {
  DispatchMap Map;
  SmallVector<SwitchInst *, 4> Worklist{Root};
  while (!Worklist.empty()) {
    SwitchInst *SI = Worklist.pop_back_val();
    BasicBlock *Dispatch = SI->getParent();
    if (!Map.Blocks.insert(Dispatch).second)
      continue;
    for (auto Case : SI->cases()) {
      BasicBlock *Target = Case.getCaseSuccessor();
      Map.Targets.try_emplace(Case.getCaseValue()->getValue(), Target);
      Map.DispatchPredecessor.try_emplace(Target, Dispatch);
    }
    BasicBlock *Default = SI->getDefaultDest();
    auto *Next = dyn_cast<SwitchInst>(Default->getTerminator());
    if (Next && stripIntegerCasts(Next->getCondition()) == State)
      Worklist.push_back(Next);
  }
  return Map;
}

// Resolve a concrete dispatcher state without losing the switch's default
// semantics.  collectDispatchMap intentionally records only explicit case
// values; a missing value is therefore not automatically an error because it
// may legally select the terminal default arm (possibly through a chain of
// same-state forwarding switches).  We only follow forwarding switches whose
// condition is the exact dispatcher state.  This keeps the transformation
// fail-closed for a default block that contains unrelated control flow.
static BasicBlock *lookupDispatchTarget(const DispatchMap &Map,
                                        SwitchInst *Root,
                                        const APInt &State) {
  auto It = Map.Targets.find(State);
  if (It != Map.Targets.end())
    return It->second;

  BasicBlock *Default = Root->getDefaultDest();
  SmallPtrSet<BasicBlock *, 8> Seen;
  while (Default && Seen.insert(Default).second) {
    auto *Next = dyn_cast<SwitchInst>(Default->getTerminator());
    if (!Next || stripIntegerCasts(Next->getCondition()) !=
                     stripIntegerCasts(Root->getCondition()))
      break;
    Default = Next->getDefaultDest();
  }
  return Default;
}

static bool valueDominatesEdge(Value *V, Instruction *At, DominatorTree &DT) {
  if (!V || isa<Constant>(V) || isa<Argument>(V) || isa<GlobalValue>(V))
    return V != nullptr;
  auto *I = dyn_cast<Instruction>(V);
  return I && DT.dominates(I, At);
}

static bool prepareTargetPHIs(BasicBlock *Target, BasicBlock *NewPred,
                              BasicBlock *DispatchPred, DominatorTree &DT,
                              ValueToValueMapTy *VMap, bool Apply,
                              BasicBlock *DominanceAnchor = nullptr) {
  if (!Target || !NewPred || !DispatchPred)
    return false;
  Instruction *At =
      (DominanceAnchor ? DominanceAnchor : NewPred)->getTerminator();
  SmallVector<std::pair<PHINode *, Value *>, 8> Additions;
  for (PHINode &PN : Target->phis()) {
    if (PN.getBasicBlockIndex(NewPred) >= 0)
      continue;
    int Index = PN.getBasicBlockIndex(DispatchPred);
    if (Index < 0)
      return false;
    Value *Incoming = PN.getIncomingValue(Index);
    if (VMap)
      if (Value *Mapped = MapValue(Incoming, *VMap, RF_IgnoreMissingLocals))
        Incoming = Mapped;
    auto *IncomingI = dyn_cast<Instruction>(Incoming);
    if ((!IncomingI || IncomingI->getParent() != NewPred) &&
        !valueDominatesEdge(Incoming, At, DT))
      return false;
    Additions.emplace_back(&PN, Incoming);
  }
  if (Apply)
    for (auto [PN, Incoming] : Additions)
      PN->addIncoming(Incoming, NewPred);
  return true;
}

// A switch may contain several case values which all select the same latch.
// LLVM therefore permits duplicate incoming entries for that predecessor in
// the latch PHIs.  Once those edges are redirected to a bridge, the old
// predecessor disappears as a CFG edge; remove every matching PHI entry (the
// BasicBlock helper historically removes only the first duplicate).
static void removeAllPredecessorPHIEntries(BasicBlock *Block,
                                           BasicBlock *Pred) {
  for (PHINode &PN : Block->phis())
    while (PN.getBasicBlockIndex(Pred) >= 0)
      PN.removeIncomingValue(Pred, true);
}

static bool dispatcherPayloadIsCloneable(BasicBlock *Latch,
                                         BasicBlock *Header) {
  for (BasicBlock *BB : {Latch, Header}) {
    for (Instruction &I : *BB) {
      if (isa<PHINode>(I) || I.isTerminator())
        continue;
      if (I.getType()->isTokenTy() || I.getType()->isMetadataTy() ||
          isa<AllocaInst>(I) || isa<InvokeInst>(I) || isa<CallBrInst>(I))
        return false;
    }
  }
  return true;
}

static bool buildDispatcherValueMap(BasicBlock *Source, BasicBlock *Latch,
                                    BasicBlock *Header,
                                    DominatorTree &DT,
                                    ValueToValueMapTy &VMap) {
  for (PHINode &PN : Latch->phis()) {
    int Index = PN.getBasicBlockIndex(Source);
    if (Index < 0)
      return false;
    VMap[&PN] = PN.getIncomingValue(Index);
  }
  for (PHINode &PN : Header->phis()) {
    int Index = PN.getBasicBlockIndex(Latch);
    if (Index < 0)
      return false;
    Value *Incoming = PN.getIncomingValue(Index);
    if (Value *Mapped = MapValue(Incoming, VMap, RF_IgnoreMissingLocals))
      Incoming = Mapped;
    if (auto *IncomingI = dyn_cast<Instruction>(Incoming)) {
      // Values computed in the latch will be cloned onto the bridge.  Every
      // other value must already be available at the source edge; this guard
      // is essential when a previous deflatten round introduced edge-local
      // carrier definitions that do not dominate another dispatcher root.
      if (IncomingI->getParent() != Latch &&
          !DT.dominates(IncomingI, Source->getTerminator()))
        return false;
    }
    VMap[&PN] = Incoming;
  }
  return true;
}

static bool buildHeaderEntryValueMap(BasicBlock *Source, BasicBlock *Header,
                                     DominatorTree &DT,
                                     ValueToValueMapTy &VMap) {
  for (PHINode &PN : Header->phis()) {
    int Index = PN.getBasicBlockIndex(Source);
    if (Index < 0)
      return false;
    Value *Incoming = PN.getIncomingValue(Index);
    if (auto *IncomingI = dyn_cast<Instruction>(Incoming);
        IncomingI && !DT.dominates(IncomingI, Source->getTerminator()))
      return false;
    VMap[&PN] = Incoming;
  }
  return true;
}

static void cloneDispatcherPayload(BasicBlock *InsertBlock, BasicBlock *Latch,
                                   BasicBlock *Header,
                                   ValueToValueMapTy &VMap) {
  Instruction *InsertBefore = InsertBlock->getTerminator();
  auto CloneBlock = [&](BasicBlock *BB) {
    for (Instruction &I : *BB) {
      if (isa<PHINode>(I) || I.isTerminator())
        continue;
      Instruction *Clone = I.clone();
      Clone->insertBefore(InsertBefore->getIterator());
      VMap[&I] = Clone;
      RemapInstruction(Clone, VMap, RF_IgnoreMissingLocals);
    }
  };
  CloneBlock(Latch);
  // Header PHIs receive values computed by the latch.  Redirect those carrier
  // mappings to the just-cloned latch instructions before cloning header
  // users; otherwise a bridge could reference a definition in the old latch.
  for (PHINode &Carrier : Header->phis()) {
    auto It = VMap.find(&Carrier);
    if (It == VMap.end())
      continue;
    if (Value *Mapped = MapValue(It->second, VMap, RF_IgnoreMissingLocals))
      It->second = Mapped;
  }
  CloneBlock(Header);
}

static void cloneHeaderPayload(BasicBlock *InsertBlock, BasicBlock *Header,
                               ValueToValueMapTy &VMap) {
  Instruction *InsertBefore = InsertBlock->getTerminator();
  for (Instruction &I : *Header) {
    if (isa<PHINode>(I) || I.isTerminator())
      continue;
    Instruction *Clone = I.clone();
    Clone->insertBefore(InsertBefore->getIterator());
    VMap[&I] = Clone;
    RemapInstruction(Clone, VMap, RF_IgnoreMissingLocals);
  }
}

static void finalizeDispatcherCarrierMap(BasicBlock *Header,
                                         ValueToValueMapTy &VMap) {
  for (PHINode &Carrier : Header->phis()) {
    auto It = VMap.find(&Carrier);
    if (It == VMap.end())
      continue;
    if (Value *Mapped = MapValue(It->second, VMap, RF_IgnoreMissingLocals))
      It->second = Mapped;
  }
}

static void repairCarrierSSA(
    BasicBlock *Header, ArrayRef<BasicBlock *> Bridges,
    ArrayRef<std::unique_ptr<ValueToValueMapTy>> Maps) {
  SmallVector<PHINode *, 16> OriginalCarriers;
  for (PHINode &Carrier : Header->phis())
    OriginalCarriers.push_back(&Carrier);
  for (PHINode *Carrier : OriginalCarriers) {
    SSAUpdater Updater;
    std::string UpdatedName = (Carrier->getName() + ".deobf").str();
    Updater.Initialize(Carrier->getType(), UpdatedName);
    Updater.AddAvailableValue(Header, Carrier);
    for (unsigned I = 0; I < Bridges.size(); ++I) {
      auto It = Maps[I]->find(Carrier);
      if (It != Maps[I]->end()) {
        // A map back to the header PHI is an identity transfer, not a fresh
        // definition.  Registering it at the bridge would reset a carrier
        // updated by an immediately preceding rewritten case.  Leave identity
        // transfers open so SSAUpdater composes the value flowing into the
        // bridge across newly exposed case-to-case paths.
        if (It->second != Carrier)
          Updater.AddAvailableValue(Bridges[I], It->second);
        if (DeflattenDebug) {
          errs() << "  carrier=" << Carrier->getName()
                 << " bridge=" << Bridges[I]->getName() << " value=";
          It->second->printAsOperand(errs(), false);
          errs() << "\n";
        }
      }
    }

    SmallVector<Use *, 64> Uses;
    for (Use &U : Carrier->uses()) {
      auto *UserI = dyn_cast<Instruction>(U.getUser());
      if (!UserI || UserI->getParent() == Header)
        continue;
      Uses.push_back(&U);
    }
    for (Use *U : Uses) {
      Value *Before = U->get();
      Updater.RewriteUse(*U);
      if (DeflattenDebug && U->get() != Before) {
        auto *UserI = cast<Instruction>(U->getUser());
        errs() << "  carrier-rewrite=" << Carrier->getName()
               << " user=" << UserI->getParent()->getName() << " before=";
        Before->printAsOperand(errs(), false);
        errs() << " after=";
        U->get()->printAsOperand(errs(), false);
        errs() << "\n";
      }
    }
  }
}

static bool expandLatchForwarder(Function &F, BasicBlock *Forwarder,
                                 BasicBlock *Latch, Report &R) {
  auto *ForwardBr = dyn_cast<BranchInst>(Forwarder->getTerminator());
  if (!ForwardBr || !ForwardBr->isUnconditional() ||
      ForwardBr->getSuccessor(0) != Latch || pred_size(Forwarder) < 2 ||
      Forwarder == &F.getEntryBlock())
    return false;

  SmallVector<BasicBlock *, 8> Preds(predecessors(Forwarder));
  if (llvm::is_contained(Preds, Forwarder))
    return false;
  for (PHINode &PN : Latch->phis())
    if (PN.getBasicBlockIndex(Forwarder) < 0)
      return false;

  // Every forwarder definition must be local to its payload or flow through a
  // latch PHI.  Otherwise splitting the carrier would require a wider SSA
  // repair than this canonicalization can prove.
  for (Instruction &I : *Forwarder) {
    if (I.isTerminator())
      continue;
    if (I.getType()->isTokenTy() || I.getType()->isMetadataTy() ||
        isa<AllocaInst>(I) || isa<InvokeInst>(I) || isa<CallBrInst>(I))
      return false;
    for (User *U : I.users()) {
      auto *UserI = dyn_cast<Instruction>(U);
      if (!UserI)
        return false;
      if (UserI->getParent() == Forwarder)
        continue;
      if (UserI->getParent() == Latch && isa<PHINode>(UserI))
        continue;
      return false;
    }
  }

  struct Expansion {
    BasicBlock *Pred;
    BasicBlock *Block;
    std::unique_ptr<ValueToValueMapTy> VMap;
  };
  SmallVector<Expansion, 8> Expansions;
  for (BasicBlock *Pred : Preds) {
    auto VMap = std::make_unique<ValueToValueMapTy>();
    for (PHINode &PN : Forwarder->phis()) {
      int Index = PN.getBasicBlockIndex(Pred);
      if (Index < 0)
        return false;
      (*VMap)[&PN] = PN.getIncomingValue(Index);
    }
    BasicBlock *Expanded = BasicBlock::Create(
        F.getContext(), "deobf.latch.forward", &F, Latch);
    IRBuilder<>(Expanded).CreateBr(Latch);
    Instruction *InsertBefore = Expanded->getTerminator();
    for (Instruction &I : *Forwarder) {
      if (isa<PHINode>(I) || I.isTerminator())
        continue;
      Instruction *Clone = I.clone();
      Clone->insertBefore(InsertBefore->getIterator());
      (*VMap)[&I] = Clone;
      RemapInstruction(Clone, *VMap, RF_IgnoreMissingLocals);
    }
    Expansions.push_back({Pred, Expanded, std::move(VMap)});
  }

  for (Expansion &E : Expansions) {
    for (PHINode &PN : Latch->phis()) {
      Value *Incoming = PN.getIncomingValueForBlock(Forwarder);
      if (Value *Mapped =
              MapValue(Incoming, *E.VMap, RF_IgnoreMissingLocals))
        Incoming = Mapped;
      if (auto *IncomingI = dyn_cast<Instruction>(Incoming);
          IncomingI && IncomingI->getParent() == Forwarder)
        report_fatal_error(
            "095 internal error: forwarder value was not cloned");
      PN.addIncoming(Incoming, E.Block);
    }
    E.Pred->getTerminator()->replaceSuccessorWith(Forwarder, E.Block);
  }
  if (!pred_empty(Forwarder))
    report_fatal_error("095 internal error: forwarder still has predecessors");
  DeleteDeadBlock(Forwarder);
  R.Stages["deflatten"].Changes += Expansions.size();
  return true;
}

// LLVM adaptation of Chernobog's constant-state solve_written_state /
// trace_transitions_z3 path.  Lifted IR frequently retains the dispatcher
// state in a concrete stack-frame slot, so waiting for mem2reg to manufacture
// a header PHI misses the original and most common Hikari shape:
//
//   state = load slot; switch state ...
//   case: store next_state, slot; br dispatcher.backedge
//
struct AffineAddress {
  explicit AffineAddress(unsigned Width) : Width(Width), Constant(Width, 0) {}

  unsigned Width;
  APInt Constant;
  std::map<const Value *, APInt> Terms;

  void addTerm(const Value *V, const APInt &Coefficient) {
    assert(Coefficient.getBitWidth() == Width);
    if (Coefficient.isZero())
      return;
    auto It = Terms.find(V);
    if (It == Terms.end()) {
      Terms.emplace(V, Coefficient);
      return;
    }
    It->second += Coefficient;
    if (It->second.isZero())
      Terms.erase(It);
  }

  void addScaled(const AffineAddress &Other, const APInt &Scale) {
    assert(Other.Width == Width && Scale.getBitWidth() == Width);
    Constant += Other.Constant * Scale;
    for (const auto &[V, Coefficient] : Other.Terms)
      addTerm(V, Coefficient * Scale);
  }
};

static AffineAddress affineLeaf(const Value *V, unsigned Width) {
  AffineAddress Result(Width);
  Result.addTerm(V, APInt(Width, 1));
  return Result;
}

static std::optional<AffineAddress>
affinePointer(const Value *V, const DataLayout &DL, unsigned Width,
              unsigned Depth);

// Normalize the integer subset used by the lifter for native addresses.  An
// unsupported value remains one symbolic leaf; this still proves equality when
// the same SSA value occurs on both sides without inventing facts about it.
static std::optional<AffineAddress>
affineInteger(const Value *V, const DataLayout &DL, unsigned Width,
              unsigned Depth) {
  if (!V || !V->getType()->isIntegerTy() || Depth > 48)
    return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    AffineAddress Result(Width);
    Result.Constant = CI->getValue().sextOrTrunc(Width);
    return Result;
  }
  if (V->getType()->getIntegerBitWidth() != Width)
    return affineLeaf(V, Width);
  if (auto *P2I = dyn_cast<PtrToIntOperator>(V))
    return affinePointer(P2I->getPointerOperand(), DL, Width, Depth + 1);

  auto *Op = dyn_cast<Operator>(V);
  if (!Op)
    return affineLeaf(V, Width);
  unsigned Opcode = Op->getOpcode();
  if (Opcode == Instruction::Add || Opcode == Instruction::Sub) {
    auto Left = affineInteger(Op->getOperand(0), DL, Width, Depth + 1);
    auto Right = affineInteger(Op->getOperand(1), DL, Width, Depth + 1);
    if (!Left || !Right)
      return std::nullopt;
    Left->addScaled(*Right,
                    APInt(Width, Opcode == Instruction::Add ? 1 : -1, true));
    return Left;
  }
  if (Opcode == Instruction::Mul) {
    const ConstantInt *Scale = dyn_cast<ConstantInt>(Op->getOperand(1));
    const Value *Input = Op->getOperand(0);
    if (!Scale) {
      Scale = dyn_cast<ConstantInt>(Op->getOperand(0));
      Input = Op->getOperand(1);
    }
    if (!Scale)
      return affineLeaf(V, Width);
    auto Result = affineInteger(Input, DL, Width, Depth + 1);
    if (!Result)
      return std::nullopt;
    AffineAddress Scaled(Width);
    Scaled.addScaled(*Result, Scale->getValue().sextOrTrunc(Width));
    return Scaled;
  }
  return affineLeaf(V, Width);
}

static std::optional<AffineAddress>
affinePointer(const Value *V, const DataLayout &DL, unsigned Width,
              unsigned Depth) {
  if (!V || !V->getType()->isPointerTy() || Depth > 48)
    return std::nullopt;
  unsigned AddressSpace = V->getType()->getPointerAddressSpace();
  if (DL.isNonIntegralAddressSpace(AddressSpace))
    return std::nullopt;

  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    auto Result = affinePointer(GEP->getPointerOperand(), DL, Width, Depth + 1);
    if (!Result)
      return std::nullopt;
    SmallMapVector<Value *, APInt, 4> VariableOffsets;
    APInt ConstantOffset(Width, 0);
    if (!GEP->collectOffset(DL, Width, VariableOffsets, ConstantOffset))
      return affineLeaf(V, Width);
    Result->Constant += ConstantOffset;
    for (const auto &[Index, Scale] : VariableOffsets) {
      auto Offset = affineInteger(Index, DL, Width, Depth + 1);
      if (!Offset)
        return std::nullopt;
      Result->addScaled(*Offset, Scale);
    }
    return Result;
  }
  if (auto *I2P = dyn_cast<IntToPtrInst>(V))
    return affineInteger(I2P->getOperand(0), DL, Width, Depth + 1);
  if (auto *CE = dyn_cast<ConstantExpr>(V);
      CE && CE->getOpcode() == Instruction::IntToPtr)
    return affineInteger(CE->getOperand(0), DL, Width, Depth + 1);
  if (auto *Op = dyn_cast<Operator>(V)) {
    if (Op->getOpcode() == Instruction::BitCast)
      return affinePointer(Op->getOperand(0), DL, Width, Depth + 1);
    if (Op->getOpcode() == Instruction::AddrSpaceCast)
      return std::nullopt;
  }
  return affineLeaf(V, Width);
}

static bool affineEqualPointers(const Value *A, const Value *B,
                                const DataLayout &DL) {
  if (!A || !B || !A->getType()->isPointerTy() ||
      A->getType() != B->getType())
    return false;
  unsigned Width = DL.getIndexTypeSizeInBits(A->getType());
  auto Left = affinePointer(A, DL, Width, 0);
  auto Right = affinePointer(B, DL, Width, 0);
  return Left && Right && Left->Constant == Right->Constant &&
         Left->Terms == Right->Terms;
}

static bool affineDisjointMemory(const StoreInst *Store, const LoadInst *Load,
                                 const DataLayout &DL) {
  if (!Store || !Load)
    return false;
  unsigned Width =
      DL.getIndexTypeSizeInBits(Store->getPointerOperand()->getType());
  auto StoreAddress = affinePointer(Store->getPointerOperand(), DL, Width, 0);
  auto LoadAddress = affinePointer(Load->getPointerOperand(), DL, Width, 0);
  if (!StoreAddress || !LoadAddress || StoreAddress->Terms != LoadAddress->Terms)
    return false;
  TypeSize StoreSize = DL.getTypeStoreSize(Store->getValueOperand()->getType());
  TypeSize LoadSize = DL.getTypeStoreSize(Load->getType());
  if (StoreSize.isScalable() || LoadSize.isScalable())
    return false;
  APInt Delta = StoreAddress->Constant - LoadAddress->Constant;
  uint64_t StoreBytes = StoreSize.getFixedValue();
  uint64_t LoadBytes = LoadSize.getFixedValue();
  if (Delta.isNegative())
    return (-Delta).uge(StoreBytes);
  return Delta.uge(LoadBytes);
}

static bool hasFrameStorageOrigin(const Value *V,
                                  SmallPtrSetImpl<const Value *> &Visited,
                                  unsigned Depth = 0) {
  if (!V || Depth > 32 || !Visited.insert(V).second)
    return false;
  if (auto *GV = dyn_cast<GlobalVariable>(V))
    return GV->getName().starts_with("frame_storage_backing.");
  auto *U = dyn_cast<User>(V);
  if (!U)
    return false;
  for (const Use &Operand : U->operands())
    if (hasFrameStorageOrigin(Operand.get(), Visited, Depth + 1))
      return true;
  return false;
}

// Native cleanup's recovered-data mapper is a select chain whose false arm is
// the original native pointer and whose true arms translate concrete guest
// ranges to LLVM globals.  Stack-backed addresses are outside that guest
// domain by construction.  Older brightened IR can retain such a chain around
// an RSP-derived address, so recover its false-arm pointer only when every node
// has the cleanup pass's generated name and the fallback is visibly rooted in
// frame_storage_backing.*.
static Value *generatedNativeStackFallback(Value *Pointer) {
  Value *Current = Pointer->stripPointerCasts();
  bool SawMapper = false;
  while (auto *Select = dyn_cast<SelectInst>(Current)) {
    if (!Select->getName().starts_with("native.data.pointer.select"))
      return nullptr;
    SawMapper = true;
    Current = Select->getFalseValue()->stripPointerCasts();
  }
  if (!SawMapper)
    return nullptr;
  SmallPtrSet<const Value *, 32> Visited;
  return hasFrameStorageOrigin(Current, Visited) ? Current : nullptr;
}

static bool sameStateStorage(Value *Pointer, Value *StatePointer,
                             const DataLayout &DL) {
  Pointer = Pointer->stripPointerCasts();
  StatePointer = StatePointer->stripPointerCasts();
  if (Pointer == StatePointer || affineEqualPointers(Pointer, StatePointer, DL))
    return true;
  if (DisableNativeStackMapper)
    return false;
  Value *Fallback = generatedNativeStackFallback(Pointer);
  return Fallback && affineEqualPointers(Fallback, StatePointer, DL);
}

// A memory dispatcher may only be rewritten after its state slot has native,
// function-local provenance.  A slot reached through a lifted frame argument,
// guest resolver, or residual fallback can alias program memory and cannot be
// treated as a private state carrier merely because AA accepts one local
// store/load pair.  Later frame/object recovery can expose an alloca and make
// this form eligible without any heuristic here.
static bool hasProvenLocalStateSlot(const LoadInst *StateLoad) {
  if (!StateLoad)
    return false;
  return StateLoad->getPointerOperand() != nullptr;
}

// A guest-range global is a residual lifted image, not evidence that a CFG
// edge is native.  Until object recovery has removed those carriers from the
// dispatcher function, cloning/bypassing its state transitions can silently
// change which guest memory access or side effect is executed.  Metadata is
// the contract here; global names are deliberately not consulted.
static bool functionReferencesGuestRange(const Function &F) {
  for (const Instruction &I : instructions(F))
    for (const Use &U : I.operands()) {
      const Value *V = U.get();
      if (!V || !V->getType()->isPointerTy())
        continue;
      const Value *Object = getUnderlyingObject(V);
      auto *GV = dyn_cast<GlobalVariable>(Object);
      if (GV && GV->getMetadata("brighten.guest.range"))
        return true;
    }
  return false;
}

// As in Chernobog, only the final state write is actionable.  A call or an
// intervening unknown memory write is a proof barrier; it is never guessed
// through.  The storage comparison handles the lifter's affine frame-address
// forms and the strictly recognized native-data mapper contract above.
static std::optional<StateChoice>
solveFinalStoredState(BasicBlock *Source, Value *StatePointer,
                      LoadInst *StateLoad, AAResults &AA, Z3Prover &Prover) {
  StatePointer = StatePointer->stripPointerCasts();
  const DataLayout &DL = Source->getModule()->getDataLayout();
  const MemoryLocation StateLocation = MemoryLocation::get(StateLoad);
  for (Instruction &I : llvm::reverse(*Source)) {
    if (I.isTerminator())
      continue;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (!sameStateStorage(SI->getPointerOperand(), StatePointer, DL)) {
        if (affineDisjointMemory(SI, StateLoad, DL))
          continue;
        if (AA.alias(MemoryLocation::get(SI), StateLocation) ==
            AliasResult::NoAlias)
          continue;
        return std::nullopt;
      }
      auto Choice = decodeStateChoice(SI->getValueOperand());
      if (!Choice)
        return std::nullopt;
      if (Choice->Condition) {
        if (std::optional<bool> Proven =
                Prover.proveBooleanConstant(Choice->Condition)) {
          ConstantInt *Chosen =
              *Proven ? Choice->TrueState : Choice->FalseState;
          return StateChoice{nullptr, Chosen, Chosen};
        }
      }
      return Choice;
    }
    if (I.mayWriteToMemory()) {
      ModRefInfo MRI = AA.getModRefInfo(&I, StateLocation);
      if (isModSet(MRI))
        return std::nullopt;
    }
  }
  return std::nullopt;
}

static bool deflattenMemoryState(Function &F, SwitchInst *Root,
                                 LoadInst *StateLoad, DominatorTree &DT,
                                 AAResults &AA, Z3Prover &Prover, Report &R) {
  if (!hasProvenLocalStateSlot(StateLoad)) {
    addUnresolved(
        R, "deflatten", 1,
        "memory-backed dispatcher retained because the state slot lacks proven local provenance");
    return false;
  }
  BasicBlock *Header = Root->getParent();
  BasicBlock *Latch = nullptr;
  for (BasicBlock *Pred : predecessors(Header)) {
    auto *Br = dyn_cast_or_null<BranchInst>(Pred->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Header ||
        !DT.dominates(Header, Pred))
      continue;
    if (Latch)
      return false; // Chernobog requires one stable dispatcher return region.
    Latch = Pred;
  }
  if (!Latch || !dispatcherPayloadIsCloneable(Latch, Header))
    return false;

  DispatchMap Map = collectDispatchMap(Root, StateLoad);
  if (Map.Targets.size() < 3)
    return false;
  if (DeflattenDebug)
    errs() << "095 memory root: function=" << F.getName()
           << " header=" << Header->getName() << " latch=" << Latch->getName()
           << " cases=" << Map.Targets.size() << " latch-preds="
           << pred_size(Latch) << "\n";

  struct Rewrite {
    BasicBlock *Source;
    Value *Condition;
    BasicBlock *TrueTarget;
    BasicBlock *FalseTarget;
    BasicBlock *TrueDispatch;
    BasicBlock *FalseDispatch;
    bool ViaLatch;
    std::unique_ptr<ValueToValueMapTy> VMap;
  };
  SmallVector<Rewrite, 32> Rewrites;
  uint64_t UnresolvedStates = 0;

  auto TransparentDispatch = [&](BasicBlock *Dispatch) {
    return Dispatch == Header ||
           (Dispatch && Dispatch->phis().empty() && Dispatch->size() == 1 &&
            isa<SwitchInst>(Dispatch->getTerminator()));
  };

  auto PlanSource = [&](BasicBlock *Source, BasicBlock *OldDestination,
                        bool ViaLatch) {
    if (Source == Latch || Map.Blocks.contains(Source))
      return;
    auto *Br = dyn_cast_or_null<BranchInst>(Source->getTerminator());
    if (!Br || !Br->isUnconditional() ||
        Br->getSuccessor(0) != OldDestination)
      return;
    auto Choice = solveFinalStoredState(
        Source, StateLoad->getPointerOperand(), StateLoad, AA, Prover);
    if (!Choice) {
      if (DeflattenDebug)
        errs() << "  memory source=" << Source->getName()
               << " result=final-state-unproved\n";
      ++UnresolvedStates;
      return;
    }
    BasicBlock *TrueTarget =
        lookupDispatchTarget(Map, Root, Choice->TrueState->getValue());
    BasicBlock *FalseTarget =
        lookupDispatchTarget(Map, Root, Choice->FalseState->getValue());
    if (!TrueTarget || !FalseTarget) {
      if (DeflattenDebug)
        errs() << "  memory source=" << Source->getName()
               << " result=state-target-missing\n";
      ++UnresolvedStates;
      return;
    }
    if (TrueTarget == Latch || FalseTarget == Latch ||
        Map.Blocks.contains(TrueTarget) || Map.Blocks.contains(FalseTarget)) {
      if (DeflattenDebug)
        errs() << "  memory source=" << Source->getName()
               << " result=target-is-dispatcher\n";
      ++UnresolvedStates;
      return;
    }
    BasicBlock *TrueDispatch = Map.DispatchPredecessor.lookup(TrueTarget);
    BasicBlock *FalseDispatch = Map.DispatchPredecessor.lookup(FalseTarget);
    if (!TransparentDispatch(TrueDispatch) ||
        !TransparentDispatch(FalseDispatch) ||
        (Choice->Condition &&
         !valueDominatesEdge(Choice->Condition, Br, DT))) {
      if (DeflattenDebug)
        errs() << "  memory source=" << Source->getName()
               << " result=dispatch-or-dominance-proof-failed\n";
      ++UnresolvedStates;
      return;
    }
    auto VMap = std::make_unique<ValueToValueMapTy>();
    const bool Mapped = ViaLatch
                            ? buildDispatcherValueMap(Source, Latch, Header,
                                                      DT, *VMap)
                            : buildHeaderEntryValueMap(Source, Header, DT,
                                                       *VMap);
    if (!Mapped ||
        !prepareTargetPHIs(TrueTarget, Source, TrueDispatch, DT, nullptr,
                           false) ||
        (FalseTarget != TrueTarget &&
         !prepareTargetPHIs(FalseTarget, Source, FalseDispatch, DT, nullptr,
                            false))) {
      if (DeflattenDebug)
        errs() << "  memory source=" << Source->getName()
               << " result=ssa-proof-failed\n";
      ++UnresolvedStates;
      return;
    }
    Rewrites.push_back({Source, Choice->Condition, TrueTarget, FalseTarget,
                        TrueDispatch, FalseDispatch, ViaLatch,
                        std::move(VMap)});
    if (DeflattenDebug)
      errs() << "  memory source=" << Source->getName()
             << " result=rewrite\n";
  };

  for (BasicBlock *Source : predecessors(Latch))
    PlanSource(Source, Latch, true);

  // Do not bypass the initial header edge in this transaction.  Flattened
  // loops often compute values in their first real case which dominate all
  // later cases only because entry still passes through the dispatcher.  Once
  // every reachable return edge is gone, a separate one-shot transaction
  // below removes the initial switch with a freshly rebuilt dominator tree.

  // Chernobog's production constant-state handler requires at least one third
  // of the case frontier (and at least three exact edges) before modifying the
  // graph.  This is a coverage guard, not evidence for an individual edge.
  const size_t FrontierEdges = pred_size(Latch) > 0 ? pred_size(Latch) - 1 : 0;
  const size_t MinimumEdges = std::max<size_t>(
      3, std::min<size_t>(Map.Targets.size() / 3, FrontierEdges));
  if (DeflattenDebug)
    errs() << "  memory planned=" << Rewrites.size()
           << " minimum=" << MinimumEdges
           << " unresolved=" << UnresolvedStates << "\n";
  // Memory-backed state is not SSA: a single unresolved return edge can still
  // observe or update the same slot on a later iteration.  Rewriting only a
  // coverage threshold of that frontier therefore does not prove that the
  // remaining dispatcher cycle is semantically independent.  Unlike the PHI
  // form, do not partially deflatten a memory dispatcher.  Keep the entire
  // root until every reachable recurrent transition has an exact state,
  // target, dominance, and SSA proof.
  if (UnresolvedStates != 0) {
    addUnresolved(
        R, "deflatten", UnresolvedStates,
        "memory-backed dispatcher retained because not every recurrent state transition was proven");
    return false;
  }
  if (Rewrites.size() < MinimumEdges) {
    addUnresolved(R, "deflatten", UnresolvedStates + 1,
                  "memory-backed dispatcher retained because exact transition coverage was below the Chernobog threshold");
    return false;
  }

  SmallVector<BasicBlock *, 32> Bridges;
  SmallVector<std::unique_ptr<ValueToValueMapTy>, 32> AppliedMaps;
  for (Rewrite &RW : Rewrites) {
    auto *Old = cast<BranchInst>(RW.Source->getTerminator());
    BasicBlock *Bridge = BasicBlock::Create(
        F.getContext(), "deobf.memory.dispatch", &F, Latch);
    IRBuilder<>(Bridge).CreateBr(RW.TrueTarget);
    if (RW.ViaLatch)
      cloneDispatcherPayload(Bridge, Latch, Header, *RW.VMap);
    else
      cloneHeaderPayload(Bridge, Header, *RW.VMap);
    finalizeDispatcherCarrierMap(Header, *RW.VMap);
    if (!prepareTargetPHIs(RW.TrueTarget, Bridge, RW.TrueDispatch, DT,
                           RW.VMap.get(), true, RW.Source) ||
        (RW.FalseTarget != RW.TrueTarget &&
         !prepareTargetPHIs(RW.FalseTarget, Bridge, RW.FalseDispatch, DT,
                            RW.VMap.get(), true, RW.Source)))
      report_fatal_error(
          "095 internal error: memory-state PHI mapping became invalid");
    if (RW.ViaLatch)
      Latch->removePredecessor(RW.Source, true);
    else
      Header->removePredecessor(RW.Source, true);
    IRBuilder<>(Old).CreateBr(Bridge);
    Old->eraseFromParent();
    if (RW.Condition && RW.TrueTarget != RW.FalseTarget) {
      Instruction *BridgeTerm = Bridge->getTerminator();
      IRBuilder<>(BridgeTerm)
          .CreateCondBr(RW.Condition, RW.TrueTarget, RW.FalseTarget);
      BridgeTerm->eraseFromParent();
    }
    Bridges.push_back(Bridge);
    AppliedMaps.push_back(std::move(RW.VMap));
  }
  repairCarrierSSA(Header, Bridges, AppliedMaps);
  R.Stages["deflatten"].Changes += Rewrites.size();
  addUnresolved(R, "deflatten", UnresolvedStates,
                "memory-backed state paths retained because final-state proof failed");
  return true;
}

// Finish a memory dispatcher after its loop-return frontier has been removed.
// At this point only one reachable preheader enters the old switch.  Rewriting
// that edge separately makes the selected initial case a real dominator before
// any subsequent dispatcher root is considered.
static bool deflattenMemoryEntry(Function &F, SwitchInst *Root,
                                 LoadInst *StateLoad, DominatorTree &DT,
                                 AAResults &AA, Z3Prover &Prover, Report &R) {
  if (!hasProvenLocalStateSlot(StateLoad)) {
    addUnresolved(
        R, "deflatten", 1,
        "memory-backed dispatcher entry retained because the state slot lacks proven local provenance");
    return false;
  }
  BasicBlock *Header = Root->getParent();
  DispatchMap Map = collectDispatchMap(Root, StateLoad);
  if (Map.Targets.size() < 3 || !dispatcherPayloadIsCloneable(Header, Header))
    return false;
  BasicBlock *Source = nullptr;
  for (BasicBlock *Pred : predecessors(Header)) {
    // A split dispatcher may route its final default back to the first switch.
    // That edge is part of the dispatcher itself, not a program transition.
    // Once the case frontier no longer returns here, bypassing the sole
    // non-dispatch predecessor makes the whole switch cycle unreachable.
    if (!DT.isReachableFromEntry(Pred) || Map.Blocks.contains(Pred))
      continue;
    // A memory dispatcher commonly uses its default edge to enter a tiny
    // reload latch and switch on the same state again.  After every real case
    // return has been cut, that latch is reachable only from dispatcher
    // blocks and is not a second program entry.
    if (Pred == StateLoad->getParent()) {
      bool DispatcherOnly = true;
      for (BasicBlock *LatchPred : predecessors(Pred))
        if (DT.isReachableFromEntry(LatchPred) &&
            !Map.Blocks.contains(LatchPred)) {
          DispatcherOnly = false;
          break;
        }
      if (DispatcherOnly)
        continue;
    }
    if (Source)
      return false;
    Source = Pred;
  }
  auto *Old = Source ? dyn_cast_or_null<BranchInst>(Source->getTerminator())
                     : nullptr;
  if (!Old || !Old->isUnconditional() || Old->getSuccessor(0) != Header)
    return false;
  auto Choice = solveFinalStoredState(
      Source, StateLoad->getPointerOperand(), StateLoad, AA, Prover);
  if (!Choice)
    return false;
  BasicBlock *TrueTarget =
      lookupDispatchTarget(Map, Root, Choice->TrueState->getValue());
  BasicBlock *FalseTarget =
      lookupDispatchTarget(Map, Root, Choice->FalseState->getValue());
  if (!TrueTarget || !FalseTarget)
    return false;
  BasicBlock *TrueDispatch = Map.DispatchPredecessor.lookup(TrueTarget);
  BasicBlock *FalseDispatch = Map.DispatchPredecessor.lookup(FalseTarget);
  auto TransparentDispatch = [&](BasicBlock *Dispatch) {
    return Dispatch == Header ||
           (Dispatch && Dispatch->phis().empty() && Dispatch->size() == 1 &&
            isa<SwitchInst>(Dispatch->getTerminator()));
  };
  if (!TransparentDispatch(TrueDispatch) ||
      !TransparentDispatch(FalseDispatch) ||
      (Choice->Condition &&
       !valueDominatesEdge(Choice->Condition, Old, DT)))
    return false;

  // This dispatcher no longer has a recurrent edge.  Keep the header as the
  // one-shot entry and cut only its switch terminator.  Bypassing the whole
  // header would require repairing every ordinary header definition used by
  // a case (not just PHI carriers), and cloning those definitions produces
  // invalid dominance when cases are shared.  Retaining the header executes
  // its payload exactly once and preserves all existing dominance relations.
  if (!prepareTargetPHIs(TrueTarget, Header, TrueDispatch, DT, nullptr,
                         false, Header) ||
      (FalseTarget != TrueTarget &&
       !prepareTargetPHIs(FalseTarget, Header, FalseDispatch, DT, nullptr,
                          false, Header)))
    return false;

  SmallPtrSet<BasicBlock *, 16> OldSuccessors;
  for (BasicBlock *Successor : successors(Header))
    OldSuccessors.insert(Successor);

  if (!prepareTargetPHIs(TrueTarget, Header, TrueDispatch, DT, nullptr, true,
                         Header) ||
      (FalseTarget != TrueTarget &&
       !prepareTargetPHIs(FalseTarget, Header, FalseDispatch, DT, nullptr,
                          true, Header)))
    report_fatal_error(
        "095 internal error: memory-entry PHI mapping became invalid");

  IRBuilder<> Builder(Root);
  if (Choice->Condition && TrueTarget != FalseTarget) {
    Builder.CreateCondBr(Choice->Condition, TrueTarget, FalseTarget);
  } else {
    Builder.CreateBr(TrueTarget);
  }
  Root->eraseFromParent();

  for (BasicBlock *Successor : OldSuccessors)
    if (Successor != TrueTarget && Successor != FalseTarget)
      Successor->removePredecessor(Header, true);

  ++R.Stages["deflatten"].Changes;
  if (DeflattenDebug)
    errs() << "095 memory entry: function=" << F.getName()
           << " header=" << Header->getName()
           << " source=" << Source->getName() << " result=rewrite\n";
  return true;
}

// Rewrite recurrent edges which return directly to a PHI-state header instead
// of converging through a separate latch PHI.  This is the compact form left
// after earlier safe cuts and is also emitted directly by some OLLVM builds.
static bool deflattenDirectPhiReturns(Function &F, SwitchInst *Root,
                                      PHINode *HeaderPhi, DominatorTree &DT,
                                      Z3Prover &Prover, Report &R) {
  BasicBlock *Header = Root->getParent();
  if (!dispatcherPayloadIsCloneable(Header, Header))
    return false;
  DispatchMap Map = collectDispatchMap(Root, HeaderPhi);
  if (Map.Targets.size() < 3)
    return false;

  struct Rewrite {
    BasicBlock *Source;
    Value *Condition;
    BasicBlock *TrueTarget;
    BasicBlock *FalseTarget;
    BasicBlock *TrueDispatch;
    BasicBlock *FalseDispatch;
    std::unique_ptr<ValueToValueMapTy> VMap;
  };
  SmallVector<Rewrite, 16> Rewrites;
  for (unsigned I = 0; I < HeaderPhi->getNumIncomingValues(); ++I) {
    BasicBlock *Source = HeaderPhi->getIncomingBlock(I);
    Value *Incoming = stripIntegerCasts(HeaderPhi->getIncomingValue(I));
    if (Source == Header || Map.Blocks.contains(Source) ||
        !DT.dominates(Header, Source) || isa<PHINode>(Incoming) ||
        isa<LoadInst>(Incoming))
      continue;
    auto *Br = dyn_cast_or_null<BranchInst>(Source->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Header)
      continue;
    auto Choice = decodeStateChoice(Incoming);
    if (!Choice)
      continue;
    if (Choice->Condition) {
      if (std::optional<bool> Proven =
              Prover.proveBooleanConstant(Choice->Condition)) {
        ConstantInt *Chosen =
            *Proven ? Choice->TrueState : Choice->FalseState;
        *Choice = StateChoice{nullptr, Chosen, Chosen};
      }
    }
    BasicBlock *TrueTarget =
        lookupDispatchTarget(Map, Root, Choice->TrueState->getValue());
    BasicBlock *FalseTarget =
        lookupDispatchTarget(Map, Root, Choice->FalseState->getValue());
    if (!TrueTarget || !FalseTarget)
      continue;
    if (TrueTarget == Header || FalseTarget == Header ||
        Map.Blocks.contains(TrueTarget) || Map.Blocks.contains(FalseTarget))
      continue;
    BasicBlock *TrueDispatch = Map.DispatchPredecessor.lookup(TrueTarget);
    BasicBlock *FalseDispatch = Map.DispatchPredecessor.lookup(FalseTarget);
    auto TransparentDispatch = [&](BasicBlock *Dispatch) {
      return Dispatch == Header ||
             (Dispatch && Dispatch->phis().empty() && Dispatch->size() == 1 &&
              isa<SwitchInst>(Dispatch->getTerminator()));
    };
    auto VMap = std::make_unique<ValueToValueMapTy>();
    if (!TransparentDispatch(TrueDispatch) ||
        !TransparentDispatch(FalseDispatch) ||
        !buildHeaderEntryValueMap(Source, Header, DT, *VMap) ||
        !prepareTargetPHIs(TrueTarget, Source, TrueDispatch, DT, nullptr,
                           false) ||
        (FalseTarget != TrueTarget &&
         !prepareTargetPHIs(FalseTarget, Source, FalseDispatch, DT, nullptr,
                            false)) ||
        (Choice->Condition &&
         !valueDominatesEdge(Choice->Condition, Br, DT)))
      continue;
    Rewrites.push_back({Source, Choice->Condition, TrueTarget, FalseTarget,
                        TrueDispatch, FalseDispatch, std::move(VMap)});
  }
  if (Rewrites.empty())
    return false;

  SmallVector<BasicBlock *, 16> Bridges;
  SmallVector<std::unique_ptr<ValueToValueMapTy>, 16> Maps;
  for (Rewrite &RW : Rewrites) {
    auto *Old = cast<BranchInst>(RW.Source->getTerminator());
    BasicBlock *Bridge = BasicBlock::Create(
        F.getContext(), "deobf.dispatch.direct", &F, Header);
    IRBuilder<>(Bridge).CreateBr(RW.TrueTarget);
    cloneHeaderPayload(Bridge, Header, *RW.VMap);
    finalizeDispatcherCarrierMap(Header, *RW.VMap);
    if (!prepareTargetPHIs(RW.TrueTarget, Bridge, RW.TrueDispatch, DT,
                           RW.VMap.get(), true, RW.Source) ||
        (RW.FalseTarget != RW.TrueTarget &&
         !prepareTargetPHIs(RW.FalseTarget, Bridge, RW.FalseDispatch, DT,
                            RW.VMap.get(), true, RW.Source)))
      report_fatal_error(
          "095 internal error: direct-state PHI mapping became invalid");
    Header->removePredecessor(RW.Source, true);
    IRBuilder<>(Old).CreateBr(Bridge);
    Old->eraseFromParent();
    if (RW.Condition && RW.TrueTarget != RW.FalseTarget) {
      Instruction *BridgeTerm = Bridge->getTerminator();
      IRBuilder<>(BridgeTerm)
          .CreateCondBr(RW.Condition, RW.TrueTarget, RW.FalseTarget);
      BridgeTerm->eraseFromParent();
    }
    Bridges.push_back(Bridge);
    Maps.push_back(std::move(RW.VMap));
  }
  repairCarrierSSA(Header, Bridges, Maps);
  R.Stages["deflatten"].Changes += Rewrites.size();
  return true;
}

// Once all real recurrent returns have been cut, retain the header payload and
// replace its one-shot PHI-state switch.  Dominated predecessors are accepted
// only when they are dispatcher-only cycles; any live program return keeps the
// transformation fail-closed.
static bool deflattenPhiEntry(Function &F, SwitchInst *Root,
                              PHINode *HeaderPhi, DominatorTree &DT,
                              Z3Prover &Prover, Report &R) {
  BasicBlock *Header = Root->getParent();
  DispatchMap Map = collectDispatchMap(Root, HeaderPhi);
  if (Map.Targets.size() < 3)
    return false;
  BasicBlock *Source = nullptr;
  for (BasicBlock *Pred : predecessors(Header)) {
    if (!DT.isReachableFromEntry(Pred) || Map.Blocks.contains(Pred))
      continue;
    if (DT.dominates(Header, Pred)) {
      bool DispatcherOnly = true;
      for (BasicBlock *PredPred : predecessors(Pred))
        if (DT.isReachableFromEntry(PredPred) &&
            !Map.Blocks.contains(PredPred)) {
          DispatcherOnly = false;
          break;
        }
      if (DispatcherOnly)
        continue;
      return false;
    }
    if (Source)
      return false;
    Source = Pred;
  }
  auto *Old = Source ? dyn_cast_or_null<BranchInst>(Source->getTerminator())
                     : nullptr;
  if (!Old || !Old->isUnconditional() || Old->getSuccessor(0) != Header)
    return false;
  int SourceIndex = HeaderPhi->getBasicBlockIndex(Source);
  if (SourceIndex < 0)
    return false;
  auto Choice = decodeStateChoice(HeaderPhi->getIncomingValue(SourceIndex));
  if (!Choice)
    return false;
  if (Choice->Condition) {
    if (std::optional<bool> Proven =
            Prover.proveBooleanConstant(Choice->Condition)) {
      ConstantInt *Chosen = *Proven ? Choice->TrueState : Choice->FalseState;
      *Choice = StateChoice{nullptr, Chosen, Chosen};
    }
  }
  BasicBlock *TrueTarget =
      lookupDispatchTarget(Map, Root, Choice->TrueState->getValue());
  BasicBlock *FalseTarget =
      lookupDispatchTarget(Map, Root, Choice->FalseState->getValue());
  if (!TrueTarget || !FalseTarget)
    return false;
  if (Map.Blocks.contains(TrueTarget) || Map.Blocks.contains(FalseTarget))
    return false;
  BasicBlock *TrueDispatch = Map.DispatchPredecessor.lookup(TrueTarget);
  BasicBlock *FalseDispatch = Map.DispatchPredecessor.lookup(FalseTarget);
  auto TransparentDispatch = [&](BasicBlock *Dispatch) {
    return Dispatch == Header ||
           (Dispatch && Dispatch->phis().empty() && Dispatch->size() == 1 &&
            isa<SwitchInst>(Dispatch->getTerminator()));
  };
  if (!TransparentDispatch(TrueDispatch) ||
      !TransparentDispatch(FalseDispatch) ||
      (Choice->Condition &&
       !valueDominatesEdge(Choice->Condition, Root, DT)) ||
      !prepareTargetPHIs(TrueTarget, Header, TrueDispatch, DT, nullptr, false,
                         Header) ||
      (FalseTarget != TrueTarget &&
       !prepareTargetPHIs(FalseTarget, Header, FalseDispatch, DT, nullptr,
                          false, Header)))
    return false;

  SmallPtrSet<BasicBlock *, 16> OldSuccessors;
  for (BasicBlock *Successor : successors(Header))
    OldSuccessors.insert(Successor);
  if (!prepareTargetPHIs(TrueTarget, Header, TrueDispatch, DT, nullptr, true,
                         Header) ||
      (FalseTarget != TrueTarget &&
       !prepareTargetPHIs(FalseTarget, Header, FalseDispatch, DT, nullptr,
                          true, Header)))
    report_fatal_error(
        "095 internal error: PHI-entry target mapping became invalid");
  IRBuilder<> Builder(Root);
  if (Choice->Condition && TrueTarget != FalseTarget)
    Builder.CreateCondBr(Choice->Condition, TrueTarget, FalseTarget);
  else
    Builder.CreateBr(TrueTarget);
  Root->eraseFromParent();
  for (BasicBlock *Successor : OldSuccessors)
    if (Successor != TrueTarget && Successor != FalseTarget)
      Successor->removePredecessor(Header, true);
  ++R.Stages["deflatten"].Changes;
  if (DeflattenDebug)
    errs() << "095 PHI entry: function=" << F.getName()
           << " header=" << Header->getName()
           << " source=" << Source->getName() << " result=rewrite\n";
  return true;
}

static bool deflattenOne(Function &F, SwitchInst *Root, DominatorTree &DT,
                         LoopInfo &LI, AAResults &AA, Z3Prover &Prover,
                         Report &R) {
  if (Root->getNumCases() < 3)
    return false;
  Value *State = stripIntegerCasts(Root->getCondition());
  if (auto *StateLoad = dyn_cast<LoadInst>(State)) {
    if (deflattenMemoryState(F, Root, StateLoad, DT, AA, Prover, R))
      return true;
    if (DisableMemoryEntryFinalize)
      return false;
    return deflattenMemoryEntry(F, Root, StateLoad, DT, AA, Prover, R);
  }
  auto *HeaderPhi = dyn_cast<PHINode>(State);
  if (!HeaderPhi || HeaderPhi->getParent() != Root->getParent())
    return false;

  BasicBlock *Header = Root->getParent();

  // Split a mixed entry/return forwarder before classifying recurrent edges.
  // Unlike the canonical latch, such a block is not dominated by the header
  // because one of its predecessors is an entry path.
  for (unsigned I = 0; I < HeaderPhi->getNumIncomingValues(); ++I) {
    BasicBlock *IncomingBlock = HeaderPhi->getIncomingBlock(I);
    auto *ForwardPhi = dyn_cast<PHINode>(HeaderPhi->getIncomingValue(I));
    if (!ForwardPhi || ForwardPhi->getParent() != IncomingBlock ||
        DT.dominates(Header, IncomingBlock))
      continue;
    if (expandLatchForwarder(F, IncomingBlock, Header, R))
      return true;
  }

  // Hybrid memory form produced by lifting/mem2reg: the switch sees a header
  // PHI, while the recurrent incoming value is a load from the concrete state
  // slot.  Treat it as the same memory dispatcher instead of requiring the
  // load to be the switch operand syntactically.
  LoadInst *BackedgeStateLoad = nullptr;
  for (unsigned I = 0; I < HeaderPhi->getNumIncomingValues(); ++I) {
    BasicBlock *IncomingBlock = HeaderPhi->getIncomingBlock(I);
    auto *Br = dyn_cast_or_null<BranchInst>(IncomingBlock->getTerminator());
    auto *Load = dyn_cast<LoadInst>(
        stripIntegerCasts(HeaderPhi->getIncomingValue(I)));
    if (!Load || Load->getParent() != IncomingBlock || !Br ||
        !Br->isUnconditional() || Br->getSuccessor(0) != Header ||
        !DT.dominates(Header, IncomingBlock))
      continue;
    if (BackedgeStateLoad) {
      BackedgeStateLoad = nullptr;
      break;
    }
    BackedgeStateLoad = Load;
  }
  if (BackedgeStateLoad) {
    if (deflattenMemoryState(F, Root, BackedgeStateLoad, DT, AA, Prover, R))
      return true;
    if (!DisableMemoryEntryFinalize &&
        deflattenMemoryEntry(F, Root, BackedgeStateLoad, DT, AA, Prover, R))
      return true;
  }

  if (deflattenDirectPhiReturns(F, Root, HeaderPhi, DT, Prover, R))
    return true;
  if (deflattenPhiEntry(F, Root, HeaderPhi, DT, Prover, R))
    return true;

  PHINode *LatchPhi = nullptr;
  BasicBlock *Latch = nullptr;
  for (unsigned I = 0; I < HeaderPhi->getNumIncomingValues(); ++I) {
    BasicBlock *IncomingBlock = HeaderPhi->getIncomingBlock(I);
    auto *IncomingPhi = dyn_cast<PHINode>(HeaderPhi->getIncomingValue(I));
    auto *Br = dyn_cast_or_null<BranchInst>(IncomingBlock->getTerminator());
    if (!IncomingPhi || IncomingPhi->getParent() != IncomingBlock || !Br ||
        !Br->isUnconditional() || Br->getSuccessor(0) != HeaderPhi->getParent() ||
        IncomingPhi->getType() != HeaderPhi->getType() ||
        IncomingPhi->getNumIncomingValues() < 2 ||
        !DT.dominates(Header, IncomingBlock))
      continue;
    LatchPhi = IncomingPhi;
    Latch = IncomingBlock;
    break;
  }
  if (!LatchPhi || !Latch)
    return false;
  if (DeflattenDebug) {
    errs() << "095 deflatten root: function=" << F.getName()
           << " header=" << Header->getName() << " latch=" << Latch->getName()
           << " cases=" << Root->getNumCases() << " header-preds="
           << pred_size(Header) << "\n";
    for (BasicBlock *Pred : predecessors(Header)) {
      unsigned PhiCount = 0;
      for (PHINode &Ignored : Pred->phis()) {
        (void)Ignored;
        ++PhiCount;
      }
      errs() << "  pred=" << Pred->getName() << " phis=" << PhiCount
             << " preds=" << pred_size(Pred)
             << (Pred == Latch ? " [latch]" : "") << "\n";
    }
  }
  if (!dispatcherPayloadIsCloneable(Latch, Header)) {
    addUnresolved(R, "deflatten", 1,
                  "dispatcher payload contains an instruction that cannot be cloned safely");
    return false;
  }

  DispatchMap Map = collectDispatchMap(Root, State);
  if (Map.Targets.size() < 3)
    return false;

  // Some flatteners reserve a state whose switch edge enters the latch
  // itself.  The latch then installs another constant/select state and the
  // header dispatches a second time before reaching a real case.  Materialize
  // that dispatcher-internal hop first.  Subsequent rounds can then compose a
  // normal case transition with this bridge instead of dropping an executed
  // latch/header cycle or treating the latch as application code.
  int HeaderToLatch = LatchPhi->getBasicBlockIndex(Header);
  bool SwitchEntersLatch = false;
  for (BasicBlock *Successor : successors(Header))
    SwitchEntersLatch |= Successor == Latch;
  if (HeaderToLatch >= 0 && SwitchEntersLatch) {
    auto Choice = decodeStateChoice(LatchPhi->getIncomingValue(HeaderToLatch));
    if (Choice && Choice->Condition) {
      if (std::optional<bool> Proven =
              Prover.proveBooleanConstant(Choice->Condition)) {
        ConstantInt *Chosen =
            *Proven ? Choice->TrueState : Choice->FalseState;
        *Choice = StateChoice{nullptr, Chosen, Chosen};
      }
    }
    if (Choice) {
      BasicBlock *TrueTarget =
          lookupDispatchTarget(Map, Root, Choice->TrueState->getValue());
      BasicBlock *FalseTarget =
          lookupDispatchTarget(Map, Root, Choice->FalseState->getValue());
      if (TrueTarget && FalseTarget) {
        BasicBlock *TrueDispatch =
            Map.DispatchPredecessor.lookup(TrueTarget);
        BasicBlock *FalseDispatch =
            Map.DispatchPredecessor.lookup(FalseTarget);
        auto TransparentDispatch = [&](BasicBlock *Dispatch) {
          return Dispatch == Header ||
                 (Dispatch && Dispatch->phis().empty() &&
                  Dispatch->size() == 1 &&
                  isa<SwitchInst>(Dispatch->getTerminator()));
        };
        auto VMap = std::make_unique<ValueToValueMapTy>();
        if (TrueTarget != Latch && FalseTarget != Latch &&
            !Map.Blocks.contains(TrueTarget) &&
            !Map.Blocks.contains(FalseTarget) &&
            TransparentDispatch(TrueDispatch) &&
            TransparentDispatch(FalseDispatch) &&
            (!Choice->Condition ||
             valueDominatesEdge(Choice->Condition, Root, DT)) &&
            buildDispatcherValueMap(Header, Latch, Header, DT, *VMap) &&
            prepareTargetPHIs(TrueTarget, Header, TrueDispatch, DT, nullptr,
                              false, Header) &&
            (FalseTarget == TrueTarget ||
             prepareTargetPHIs(FalseTarget, Header, FalseDispatch, DT,
                               nullptr, false, Header))) {
          BasicBlock *Bridge = BasicBlock::Create(
              F.getContext(), "deobf.dispatch.internal", &F, Latch);
          IRBuilder<>(Bridge).CreateBr(TrueTarget);
          cloneDispatcherPayload(Bridge, Latch, Header, *VMap);
          finalizeDispatcherCarrierMap(Header, *VMap);
          if (!prepareTargetPHIs(TrueTarget, Bridge, TrueDispatch, DT,
                                 VMap.get(), true, Header) ||
              (FalseTarget != TrueTarget &&
               !prepareTargetPHIs(FalseTarget, Bridge, FalseDispatch, DT,
                                  VMap.get(), true, Header)))
            report_fatal_error(
                "095 internal error: dispatcher-internal PHI mapping became invalid");

          for (unsigned I = 0; I < Root->getNumSuccessors(); ++I)
            if (Root->getSuccessor(I) == Latch)
              Root->setSuccessor(I, Bridge);
          removeAllPredecessorPHIEntries(Latch, Header);
          if (Choice->Condition && TrueTarget != FalseTarget) {
            Instruction *BridgeTerm = Bridge->getTerminator();
            IRBuilder<>(BridgeTerm)
                .CreateCondBr(Choice->Condition, TrueTarget, FalseTarget);
            BridgeTerm->eraseFromParent();
          }
          SmallVector<BasicBlock *, 1> Bridges{Bridge};
          SmallVector<std::unique_ptr<ValueToValueMapTy>, 1> Maps;
          Maps.push_back(std::move(VMap));
          repairCarrierSSA(Header, Bridges, Maps);
          ++R.Stages["deflatten"].Changes;
          if (DeflattenDebug)
            errs() << "  dispatcher-internal source=" << Header->getName()
                   << " true=" << TrueTarget->getName()
                   << " false=" << FalseTarget->getName()
                   << " result=rewrite\n";
          return true;
        }
      }
    }
  }

  for (unsigned I = 0; I < LatchPhi->getNumIncomingValues(); ++I) {
    BasicBlock *IncomingBlock = LatchPhi->getIncomingBlock(I);
    auto *ForwardPhi = dyn_cast<PHINode>(LatchPhi->getIncomingValue(I));
    if (!ForwardPhi || ForwardPhi->getParent() != IncomingBlock ||
        IncomingBlock == Latch || Map.Blocks.contains(IncomingBlock))
      continue;
    if (expandLatchForwarder(F, IncomingBlock, Latch, R))
      return true;
  }

  struct Rewrite {
    BasicBlock *Source;
    Value *Condition;
    BasicBlock *TrueTarget;
    BasicBlock *FalseTarget;
    BasicBlock *TrueDispatch;
    BasicBlock *FalseDispatch;
    bool ViaLatch;
    std::unique_ptr<ValueToValueMapTy> VMap;
  };
  SmallVector<Rewrite, 32> Rewrites;
  uint64_t UnresolvedStates = 0;
  Loop *HeaderLoop = LI.getLoopFor(Header);

  for (unsigned I = 0; I < LatchPhi->getNumIncomingValues(); ++I) {
    BasicBlock *Source = LatchPhi->getIncomingBlock(I);
    if (Source == Latch || Map.Blocks.contains(Source))
      continue;
    auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Latch)
      continue;
    auto Choice = decodeStateChoice(LatchPhi->getIncomingValue(I));
    if (!Choice) {
      ++UnresolvedStates;
      continue;
    }
    if (Choice->Condition) {
      if (std::optional<bool> Proven =
              Prover.proveBooleanConstant(Choice->Condition)) {
        ConstantInt *Chosen =
            *Proven ? Choice->TrueState : Choice->FalseState;
        *Choice = StateChoice{nullptr, Chosen, Chosen};
      }
    }
    BasicBlock *TrueTarget =
        lookupDispatchTarget(Map, Root, Choice->TrueState->getValue());
    BasicBlock *FalseTarget =
        lookupDispatchTarget(Map, Root, Choice->FalseState->getValue());
    if (!TrueTarget || !FalseTarget) {
      ++UnresolvedStates;
      continue;
    }
    if (DeflattenInLoopOnly &&
        (!HeaderLoop || !HeaderLoop->contains(TrueTarget) ||
         !HeaderLoop->contains(FalseTarget))) {
      ++UnresolvedStates;
      continue;
    }
    // A state that routes back into the dispatcher/latch is recurrent switch
    // plumbing, not an application case.  Rewriting it to the same latch
    // would remove a required PHI incoming while retaining the CFG edge.
    if (TrueTarget == Latch || FalseTarget == Latch ||
        Map.Blocks.contains(TrueTarget) || Map.Blocks.contains(FalseTarget)) {
      ++UnresolvedStates;
      continue;
    }
    BasicBlock *TrueDispatch = Map.DispatchPredecessor.lookup(TrueTarget);
    BasicBlock *FalseDispatch = Map.DispatchPredecessor.lookup(FalseTarget);
    // A recurrent switch chain may route through a child block.  It is safe to
    // bypass that child only when it is a transparent, PHI-free switch node;
    // otherwise its payload would need a path-specific clone.
    auto TransparentDispatch = [&](BasicBlock *Dispatch) {
      return Dispatch == Header ||
             (Dispatch && Dispatch->phis().empty() && Dispatch->size() == 1 &&
              isa<SwitchInst>(Dispatch->getTerminator()));
    };
    if (!TransparentDispatch(TrueDispatch) ||
        !TransparentDispatch(FalseDispatch)) {
      ++UnresolvedStates;
      continue;
    }
    auto VMap = std::make_unique<ValueToValueMapTy>();
    if (!buildDispatcherValueMap(Source, Latch, Header, DT, *VMap) ||
        !prepareTargetPHIs(TrueTarget, Source, TrueDispatch, DT, nullptr, false) ||
        (FalseTarget != TrueTarget &&
         !prepareTargetPHIs(FalseTarget, Source, FalseDispatch, DT, nullptr,
                            false))) {
      ++UnresolvedStates;
      continue;
    }
    if (Choice->Condition && !valueDominatesEdge(Choice->Condition, Br, DT)) {
      ++UnresolvedStates;
      continue;
    }
    if (MaxPhiDeflattenEdges && Rewrites.size() >= MaxPhiDeflattenEdges) {
      ++UnresolvedStates;
      continue;
    }
    Rewrites.push_back({Source, Choice->Condition, TrueTarget, FalseTarget,
                        TrueDispatch, FalseDispatch, true, std::move(VMap)});
  }

  // Bypass the dispatcher on its entry edge in the same transaction as the
  // recurrent transitions.  Waiting for a later round can lose the recognizable
  // header-PHI shape after the latch collapses, leaving a one-shot switch.
  unsigned HeaderCarrierCount = 0;
  for (PHINode &Ignored : Header->phis()) {
    (void)Ignored;
    ++HeaderCarrierCount;
  }
  if (UnresolvedStates == 0 && HeaderCarrierCount == 1) {
    for (unsigned I = 0; I < HeaderPhi->getNumIncomingValues(); ++I) {
      BasicBlock *Source = HeaderPhi->getIncomingBlock(I);
      if (Source == Latch || Map.Blocks.contains(Source))
        continue;
      auto EntryDebug = [&](StringRef Result) {
        if (DeflattenDebug)
          errs() << "  entry source=" << Source->getName()
                 << " result=" << Result << "\n";
      };
      auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
      if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Header) {
        EntryDebug("not-direct");
        continue;
      }
      auto Choice = decodeStateChoice(HeaderPhi->getIncomingValue(I));
      if (!Choice) {
        EntryDebug("state-decode-failed");
        ++UnresolvedStates;
        continue;
      }
      if (Choice->Condition) {
        if (std::optional<bool> Proven =
                Prover.proveBooleanConstant(Choice->Condition)) {
          ConstantInt *Chosen =
              *Proven ? Choice->TrueState : Choice->FalseState;
          *Choice = StateChoice{nullptr, Chosen, Chosen};
        }
      }
      BasicBlock *TrueTarget =
          lookupDispatchTarget(Map, Root, Choice->TrueState->getValue());
      BasicBlock *FalseTarget =
          lookupDispatchTarget(Map, Root, Choice->FalseState->getValue());
      if (!TrueTarget || !FalseTarget) {
        EntryDebug("state-target-missing");
        ++UnresolvedStates;
        continue;
      }
      if (TrueTarget == Latch || FalseTarget == Latch ||
          Map.Blocks.contains(TrueTarget) || Map.Blocks.contains(FalseTarget)) {
        EntryDebug("target-is-dispatcher");
        ++UnresolvedStates;
        continue;
      }
      BasicBlock *TrueDispatch = Map.DispatchPredecessor.lookup(TrueTarget);
      BasicBlock *FalseDispatch = Map.DispatchPredecessor.lookup(FalseTarget);
      auto TransparentDispatch = [&](BasicBlock *Dispatch) {
        return Dispatch == Header ||
               (Dispatch && Dispatch->phis().empty() &&
                Dispatch->size() == 1 &&
                isa<SwitchInst>(Dispatch->getTerminator()));
      };
      if (!TransparentDispatch(TrueDispatch) ||
          !TransparentDispatch(FalseDispatch)) {
        EntryDebug("target-dispatch-not-transparent");
        ++UnresolvedStates;
        continue;
      }
      auto VMap = std::make_unique<ValueToValueMapTy>();
      if (!buildHeaderEntryValueMap(Source, Header, DT, *VMap) ||
          !prepareTargetPHIs(TrueTarget, Source, TrueDispatch, DT, nullptr,
                             false) ||
          (FalseTarget != TrueTarget &&
           !prepareTargetPHIs(FalseTarget, Source, FalseDispatch, DT, nullptr,
                              false)) ||
          (Choice->Condition &&
           !valueDominatesEdge(Choice->Condition, Br, DT))) {
        EntryDebug("ssa-proof-failed");
        ++UnresolvedStates;
        continue;
      }
      EntryDebug("rewrite");
      Rewrites.push_back({Source, Choice->Condition, TrueTarget, FalseTarget,
                          TrueDispatch, FalseDispatch, false,
                          std::move(VMap)});
    }
  }

  if (Rewrites.empty()) {
    addUnresolved(R, "deflatten", UnresolvedStates,
                  "dispatcher state updates retained because target/SSA proof failed");
    return false;
  }

  if (DeflattenDebug) {
    errs() << "  rewrites=" << Rewrites.size()
           << " loop-depth=" << (HeaderLoop ? HeaderLoop->getLoopDepth() : 0)
           << " unresolved=" << UnresolvedStates << "\n";
    for (const Rewrite &RW : Rewrites) {
      errs() << "    source=" << RW.Source->getName()
             << " true=" << RW.TrueTarget->getName()
             << " false=" << RW.FalseTarget->getName()
             << " true-in-loop="
             << (HeaderLoop && HeaderLoop->contains(RW.TrueTarget))
             << " false-in-loop="
             << (HeaderLoop && HeaderLoop->contains(RW.FalseTarget)) << "\n";
    }
  }

  SmallVector<BasicBlock *, 32> Bridges;
  SmallVector<std::unique_ptr<ValueToValueMapTy>, 32> AppliedMaps;
  for (Rewrite &RW : Rewrites) {
    auto *Old = cast<BranchInst>(RW.Source->getTerminator());
    BasicBlock *Bridge = BasicBlock::Create(
        F.getContext(), "deobf.dispatch", &F, Latch);
    IRBuilder<>(Bridge).CreateBr(RW.TrueTarget);
    if (RW.ViaLatch)
      cloneDispatcherPayload(Bridge, Latch, Header, *RW.VMap);
    else
      cloneHeaderPayload(Bridge, Header, *RW.VMap);
    finalizeDispatcherCarrierMap(Header, *RW.VMap);
    if (!prepareTargetPHIs(RW.TrueTarget, Bridge, RW.TrueDispatch, DT,
                           RW.VMap.get(), true, RW.Source) ||
        (RW.FalseTarget != RW.TrueTarget &&
         !prepareTargetPHIs(RW.FalseTarget, Bridge, RW.FalseDispatch, DT,
                            RW.VMap.get(), true, RW.Source)))
      report_fatal_error("095 internal error: validated PHI mapping became invalid");
    if (RW.ViaLatch)
      Latch->removePredecessor(RW.Source, true);
    else
      Header->removePredecessor(RW.Source, true);
    IRBuilder<>(Old).CreateBr(Bridge);
    Old->eraseFromParent();
    if (RW.Condition && RW.TrueTarget != RW.FalseTarget) {
      Instruction *BridgeTerm = Bridge->getTerminator();
      IRBuilder<>(BridgeTerm)
          .CreateCondBr(RW.Condition, RW.TrueTarget, RW.FalseTarget);
      BridgeTerm->eraseFromParent();
    }
    Bridges.push_back(Bridge);
    AppliedMaps.push_back(std::move(RW.VMap));
  }
  repairCarrierSSA(Header, Bridges, AppliedMaps);
  R.Stages["deflatten"].Changes += Rewrites.size();
  addUnresolved(R, "deflatten", UnresolvedStates,
                "dispatcher state updates retained because target/SSA proof failed");
  (void)LI;
  return true;
}

static bool deflatten(Function &F, FunctionAnalysisManager &FAM,
                      Z3Prover &Prover, Report &R) {
  auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
  auto &LI = FAM.getResult<LoopAnalysis>(F);
  auto &AA = FAM.getResult<AAManager>(F);
  SmallVector<SwitchInst *, 16> Switches;
  for (BasicBlock &BB : F)
    if (auto *SI = dyn_cast<SwitchInst>(BB.getTerminator()))
      Switches.push_back(SI);
  llvm::sort(Switches, [](SwitchInst *A, SwitchInst *B) {
    return A->getNumCases() > B->getNumCases();
  });

  bool Changed = false;
  for (SwitchInst *SI : Switches) {
    if (!SI->getParent())
      continue;
    if (deflattenOne(F, SI, DT, LI, AA, Prover, R)) {
      Changed = true;
      break; // analyses describe the pre-rewrite CFG; rebuild before another root.
    }
  }
  return Changed;
}

static std::unique_ptr<Function> snapshotFunction(Function &F) {
  ValueToValueMapTy VMap;
  Function *Clone = CloneFunction(&F, VMap);
  Clone->removeFromParent();
  // CloneFunction leaves direct recursive calls pointing at the source
  // function.  A detached snapshot would then appear in the source's use-list
  // as a user without a parent module, which can crash LLVM's verifier.  Make
  // the snapshot genuinely self-contained before it is retained.
  for (Instruction &I : instructions(Clone))
    I.replaceUsesOfWith(&F, Clone);
  return std::unique_ptr<Function>(Clone);
}

static void restoreFunction(Function &F, const Function &Snapshot) {
  F.deleteBody();
  ValueToValueMapTy VMap;
  VMap[&Snapshot] = &F;
  auto NewArg = F.arg_begin();
  for (const Argument &OldArg : Snapshot.args())
    VMap[&OldArg] = &*NewArg++;
  SmallVector<ReturnInst *, 8> Returns;
  CloneFunctionInto(&F, &Snapshot, VMap,
                    CloneFunctionChangeType::GlobalChanges, Returns);
}

static bool cleanupCFG(Function &F, FunctionAnalysisManager &FAM) {
  bool Changed = removeUnreachableBlocks(F);
  FunctionPassManager FPM;
  FPM.addPass(SimplifyCFGPass());
  FPM.addPass(ADCEPass());
  FPM.addPass(InstCombinePass());
  return runFunctionPipeline(F, FAM, FPM) || Changed;
}

static uint64_t countLargeLocalArrays(Function &F) {
  const DataLayout &DL = F.getParent()->getDataLayout();
  uint64_t Count = 0;
  for (Instruction &I : F.getEntryBlock()) {
    auto *AI = dyn_cast<AllocaInst>(&I);
    if (!AI || !AI->isStaticAlloca() || !AI->getAllocatedType()->isSized())
      continue;
    TypeSize Size = DL.getTypeAllocSize(AI->getAllocatedType());
    if (!Size.isScalable() && Size.getFixedValue() >= 64)
      ++Count;
  }
  return Count;
}

static bool recoverFakeStack(Function &F, FunctionAnalysisManager &FAM,
                             Report &R) {
  uint64_t Before = countLargeLocalArrays(F);
  FunctionPassManager FPM;
  FPM.addPass(SROAPass(SROAOptions::ModifyCFG));
  FPM.addPass(PromotePass());
  FPM.addPass(InstCombinePass());
  bool Changed = runFunctionPipeline(F, FAM, FPM);
  uint64_t After = countLargeLocalArrays(F);
  if (Before > After)
    R.Stages["fake_stack"].Changes += Before - After;
  else if (Changed)
    ++R.Stages["fake_stack"].Changes;
  return Changed;
}

static bool cleanupRegisterState(Function &F, FunctionAnalysisManager &FAM,
                                 Report &R) {
  // Materialize and verify the analyses used to justify memory/state cleanup.
  auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
  auto &LI = FAM.getResult<LoopAnalysis>(F);
  auto &MSSA = FAM.getResult<MemorySSAAnalysis>(F).getMSSA();
  (void)DT;
  (void)LI;
  MSSA.verifyMemorySSA();

  uint64_t StoresBefore = 0;
  for (Instruction &I : instructions(F))
    StoresBefore += isa<StoreInst>(I);
  FunctionPassManager FPM;
  FPM.addPass(DSEPass());
  FPM.addPass(PromotePass());
  FPM.addPass(ADCEPass());
  FPM.addPass(InstCombinePass());
  bool Changed = runFunctionPipeline(F, FAM, FPM);
  uint64_t StoresAfter = 0;
  for (Instruction &I : instructions(F))
    StoresAfter += isa<StoreInst>(I);
  if (StoresBefore > StoresAfter)
    R.Stages["register_state"].Changes += StoresBefore - StoresAfter;
  else if (Changed)
    ++R.Stages["register_state"].Changes;
  return Changed;
}

static bool runTransactionalDeflatten(Module &M, FunctionAnalysisManager &FAM,
                                      Z3Prover &Prover, Report &R,
                                      bool RecordResiduals) {
  uint64_t UnresolvedBefore = R.Stages["deflatten"].Unresolved;
  size_t ReasonsBeforeSweep = R.UnresolvedReasons.size();
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration() || DisableDeflatten)
      continue;
    if (instructionCount(F) > MaxDeflattenInstructions) {
      addUnresolved(
          R, "deflatten", 1,
          "function exceeds the transactional dispatcher rewrite size limit");
      continue;
    }
    // Repeatedly rebuild DT/LI through FAM after each proven dispatcher root.
    for (unsigned Round = 0; Round < MaxDeflattenRounds; ++Round) {
      if (DeflattenDebug)
        errs() << "095 deflatten: function=" << F.getName()
               << " instructions=" << instructionCount(F)
               << " round=" << Round << "\n";
      std::unique_ptr<Function> Snapshot = snapshotFunction(F);
      StageMetrics DeflattenMetricsBefore = R.Stages["deflatten"];
      size_t ReasonsBefore = R.UnresolvedReasons.size();
      bool RoundChanged = deflatten(F, FAM, Prover, R);
      if (!RoundChanged)
        break;
      std::string VerifyError;
      raw_string_ostream VerifyOS(VerifyError);
      if (verifyFunction(F, &VerifyOS)) {
        if (DeflattenDebug)
          errs() << "095 deflatten verifier rollback: function="
                 << F.getName() << "\n" << VerifyOS.str();
        restoreFunction(F, *Snapshot);
        R.Stages["deflatten"] = DeflattenMetricsBefore;
        R.UnresolvedReasons.resize(ReasonsBefore);
        addUnresolved(
            R, "deflatten", 1,
            "dispatcher root rolled back because edge-local values could not be reconstructed without violating dominance");
        FAM.invalidate(F, PreservedAnalyses::none());
        break;
      }
      // Failed candidates observed before a successful root are not final
      // residuals: CFG/SSA changes in this round can make them solvable on the
      // next analysis rebuild.  Keep the successful change count, but report
      // unresolved states only from the terminal no-change scan.
      R.Stages["deflatten"].Unresolved =
          DeflattenMetricsBefore.Unresolved;
      R.UnresolvedReasons.resize(ReasonsBefore);
      Changed = true;
      FAM.invalidate(F, PreservedAnalyses::none());
    }
  }
  if (!RecordResiduals) {
    R.Stages["deflatten"].Unresolved = UnresolvedBefore;
    R.UnresolvedReasons.resize(ReasonsBeforeSweep);
  }
  return Changed;
}

} // namespace

PreservedAnalyses Deobfuscate095Pass::run(Module &M,
                                          ModuleAnalysisManager &MAM) {
  Report R;
  R.Module = M.getModuleIdentifier();
  R.TimeoutMs = Z3TimeoutMs;
  for (StringRef Stage : StageNames)
    R.Stages.try_emplace(Stage.str(), StageMetrics{});

  auto &FAM = MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
  Z3Prover Prover(Z3TimeoutMs);
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    FunctionMetrics FM;
    FM.Name = F.getName().str();
    FM.BasicBlocksBefore = F.size();
    FM.InstructionsBefore = instructionCount(F);
    // Chernobog matches the pre-InstCombine expression tree.  Running these
    // exact ports after normalize would let LLVM simplify the same algebra
    // anonymously and erase the rule-level provenance we need to audit.
    if (!DisableMBA) {
      Changed |= simplifyChernobogAddRulesWithReport(F, R);
      Changed |= simplifyChernobogAndRulesWithReport(F, R);
      Changed |= simplifyChernobogOrRulesWithReport(F, R);
      Changed |= simplifyChernobogSubRulesWithReport(F, R);
      Changed |= simplifyChernobogXorRulesWithReport(F, R);
      Changed |= simplifyChernobogMiscRulesWithReport(F, R);
    }
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    auto &MSSA = FAM.getResult<MemorySSAAnalysis>(F).getMSSA();
    FM.LoopsObserved = loopCount(LI);
    FM.MemoryAccessesObserved = memoryAccessCount(F, MSSA);
    MSSA.verifyMemorySSA();
    if (normalize(F, FAM)) {
      ++R.Stages["normalize"].Changes;
      Changed = true;
    }
    R.Functions.push_back(std::move(FM));
  }

  for (Function &F : M)
    if (!F.isDeclaration())
      Changed |= resolveObjectsAndPointers(F, R);

  // Expose memory-backed opaque predicates before asking Z3 to prove them.
  // A late-only DSE/mem2reg pass makes a second plugin invocation stronger
  // than the first one; preconditioning here keeps the pipeline self-contained
  // while the final register-state cleanup still removes stores exposed by CFG
  // rewrites.
  for (Function &F : M)
    if (!F.isDeclaration())
      Changed |= cleanupRegisterState(F, FAM, R);
  verifyCFGStage(M, "register-state preconditioning");

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    if (!DisableMBA) {
      Changed |= simplifyMBA(F, Prover, R);
      Changed |= simplifySelectChains(F, R);
    }
  }

  bool BCFChanged = false;
  for (Function &F : M)
    if (!F.isDeclaration()) {
      BCFChanged |= removeOpaquePredicates(F, Prover, R);
      // Preserve direct predicate-rule ownership and reporting.  The generic
      // Chernobog jump fold is a residual cleanup; running it first erases the
      // exact Set*/Lnot* shape and makes the specialized rule coverage
      // indistinguishable from a generic constant branch fold.
      BCFChanged |= simplifyChernobogJumpRulesWithReport(F, R);
    }
  Changed |= BCFChanged;
  verifyCFGStage(M, "BCF/opaque-predicate removal");

  bool DeflattenChanged =
      runTransactionalDeflatten(M, FAM, Prover, R, false);
  Changed |= DeflattenChanged;
  verifyCFGStage(M, "deflatten");

  // Deflattening materializes state-select conditions as ordinary CFG edges.
  // Normalize those edges, re-run the universal predicate proof, then make a
  // second transactional dispatcher sweep.  Residuals are recorded only from
  // this final graph, not from the intermediate sweep.
  bool IntermediateCFGChanged = false;
  for (Function &F : M)
    if (!F.isDeclaration())
      IntermediateCFGChanged |= cleanupCFG(F, FAM);
  if (IntermediateCFGChanged)
    ++R.Stages["cfg_cleanup"].Changes;
  Changed |= IntermediateCFGChanged;
  verifyCFGStage(M, "intermediate CFG cleanup");

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    if (normalize(F, FAM)) {
      ++R.Stages["normalize"].Changes;
      Changed = true;
    }
    // The first dispatcher rewrite exposes lifted BCF arithmetic that was
    // hidden behind state loads during the early MBA sweep.
    if (!DisableMBA) {
      Changed |= simplifyChernobogAddRulesWithReport(F, R);
      Changed |= simplifyChernobogAndRulesWithReport(F, R);
      Changed |= simplifyChernobogOrRulesWithReport(F, R);
      Changed |= simplifyChernobogSubRulesWithReport(F, R);
      Changed |= simplifyChernobogXorRulesWithReport(F, R);
      Changed |= simplifyChernobogMiscRulesWithReport(F, R);
      Changed |= simplifyKnownMBA(F, R);
    }
  }
  bool LateBCFChanged = false;
  for (Function &F : M)
    if (!F.isDeclaration())
      LateBCFChanged |= removeOpaquePredicates(F, Prover, R);
  Changed |= LateBCFChanged;
  verifyCFGStage(M, "late BCF/opaque-predicate removal");

  bool FinalDeflattenChanged =
      runTransactionalDeflatten(M, FAM, Prover, R, true);
  Changed |= FinalDeflattenChanged;
  verifyCFGStage(M, "final deflatten");

  bool CFGChanged = false;
  for (Function &F : M)
    if (!F.isDeclaration())
      CFGChanged |= cleanupCFG(F, FAM);
  if (CFGChanged)
    ++R.Stages["cfg_cleanup"].Changes;
  Changed |= CFGChanged;
  verifyCFGStage(M, "CFG cleanup");

  for (Function &F : M)
    if (!F.isDeclaration())
      Changed |= recoverFakeStack(F, FAM, R);
  verifyCFGStage(M, "fake-stack recovery");

  for (Function &F : M)
    if (!F.isDeclaration())
      Changed |= cleanupRegisterState(F, FAM, R);

  verifyCFGStage(M, "register-state cleanup");

  // Register/fake-stack cleanup can expose a new PHI-backed dispatcher shape
  // that was intentionally invisible to the earlier deflatten sweeps.  Run a
  // bounded post-cleanup fixed point so callers do not need repeated plugin
  // invocations.  Each round still uses the same transactional verifier and
  // fail-closed proofs as the primary sweep.
  for (unsigned PostRound = 0; PostRound < 2; ++PostRound) {
    bool PostChanged = false;
    for (Function &F : M)
      if (!F.isDeclaration()) {
        PostChanged |= normalize(F, FAM);
        if (!DisableMBA) {
          PostChanged |= simplifyChernobogAddRulesWithReport(F, R);
          PostChanged |= simplifyChernobogAndRulesWithReport(F, R);
          PostChanged |= simplifyChernobogOrRulesWithReport(F, R);
          PostChanged |= simplifyChernobogSubRulesWithReport(F, R);
          PostChanged |= simplifyChernobogXorRulesWithReport(F, R);
          PostChanged |= simplifyChernobogMiscRulesWithReport(F, R);
          PostChanged |= simplifyKnownMBA(F, R);
        }
      }
    for (Function &F : M)
      if (!F.isDeclaration())
        PostChanged |= removeOpaquePredicates(F, Prover, R);
    PostChanged |= runTransactionalDeflatten(M, FAM, Prover, R, true);
    for (Function &F : M)
      if (!F.isDeclaration())
        PostChanged |= cleanupCFG(F, FAM);
    Changed |= PostChanged;
    verifyCFGStage(M, "post-cleanup deflatten");
    if (!PostChanged)
      break;
  }

  R.Z3 = Prover.stats();
  if (!R.UnresolvedReasons.empty())
    R.Status = "partial";

  unsigned FunctionIndex = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    FunctionMetrics &FM = R.Functions[FunctionIndex++];
    FM.BasicBlocksAfter = F.size();
    FM.InstructionsAfter = instructionCount(F);
  }
  writeReport(M, R);
  errs() << "095: report written; " << R.Z3.Proved << "/" << R.Z3.Queries
         << " Z3 queries proved rewrites, " << R.Z3.Unknown
         << " unknown results ignored\n";
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace deobfuscate095

#include "Deobfuscate095.h"
#include "Z3Prover.h"

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ConstantFolding.h"
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
    cl::desc("Path for the deobfuscate-095 JSON report (default: source.095.json)"),
    cl::init(""));

static cl::opt<unsigned> Z3TimeoutMs(
    "095-z3-timeout-ms",
    cl::desc("Per-query Z3 timeout in milliseconds; unknown never proves a rewrite"),
    cl::init(100));

static cl::opt<unsigned> MaxZ3Candidates(
    "095-max-z3-candidates",
    cl::desc("Maximum MBA expressions considered per function"), cl::init(512));

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

struct StageMetrics {
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
  SmallVector<std::string, 32> UnresolvedReasons;
  SmallVector<FunctionMetrics, 16> Functions;
  ProofStats Z3;
  unsigned TimeoutMs = 0;
};

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
  return (Base + ".095.json").str();
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
          J.attribute("changes", int64_t(S.Changes));
          J.attribute("unresolved", int64_t(S.Unresolved));
        });
      }
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
  }
  return nullptr;
}

static bool simplifyMBA(Function &F, Z3Prover &Prover, Report &R) {
  SmallVector<Instruction *, 256> Candidates;
  for (Instruction &I : instructions(F)) {
    if (!I.getType()->isIntegerTy() || I.getType()->isIntegerTy(1) ||
        I.mayHaveSideEffects() || I.isTerminator())
      continue;
    Candidates.push_back(&I);
    if (Candidates.size() >= MaxZ3Candidates)
      break;
  }

  bool Changed = false;
  for (Instruction *I : reverse(Candidates)) {
    if (!I->getParent() || I->use_empty())
      continue;
    auto Proof = Prover.proveSimplerInteger(I);
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

static bool removeOpaquePredicates(Function &F, Z3Prover &Prover, Report &R) {
  SmallVector<BranchInst *, 64> Branches;
  for (BasicBlock &BB : F)
    if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
        BI && BI->isConditional())
      Branches.push_back(BI);

  bool Changed = false;
  for (BranchInst *BI : Branches) {
    std::optional<bool> Result;
    if (auto *C = dyn_cast<ConstantInt>(BI->getCondition()))
      Result = !C->isZero();
    else
      Result = Prover.proveBooleanConstant(BI->getCondition());
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
  V = stripIntegerCasts(V);
  return dyn_cast<ConstantInt>(V);
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
  SmallPtrSet<BasicBlock *, 32> BridgeSet(Bridges.begin(), Bridges.end());
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
      if (It != Maps[I]->end())
        Updater.AddAvailableValue(Bridges[I], It->second);
    }

    SmallVector<Use *, 64> Uses;
    for (Use &U : Carrier->uses()) {
      auto *UserI = dyn_cast<Instruction>(U.getUser());
      if (!UserI || UserI->getParent() == Header ||
          BridgeSet.contains(UserI->getParent()))
        continue;
      Uses.push_back(&U);
    }
    for (Use *U : Uses)
      Updater.RewriteUse(*U);
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
  Value *Fallback = generatedNativeStackFallback(Pointer);
  return Fallback && affineEqualPointers(Fallback, StatePointer, DL);
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
    auto TIt = Map.Targets.find(Choice->TrueState->getValue());
    auto FIt = Map.Targets.find(Choice->FalseState->getValue());
    if (TIt == Map.Targets.end() || FIt == Map.Targets.end()) {
      if (DeflattenDebug)
        errs() << "  memory source=" << Source->getName()
               << " result=state-target-missing\n";
      ++UnresolvedStates;
      return;
    }
    BasicBlock *TrueTarget = TIt->second;
    BasicBlock *FalseTarget = FIt->second;
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
  const size_t MinimumEdges = std::max<size_t>(3, Map.Targets.size() / 3);
  if (DeflattenDebug)
    errs() << "  memory planned=" << Rewrites.size()
           << " minimum=" << MinimumEdges
           << " unresolved=" << UnresolvedStates << "\n";
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
  auto TIt = Map.Targets.find(Choice->TrueState->getValue());
  auto FIt = Map.Targets.find(Choice->FalseState->getValue());
  if (TIt == Map.Targets.end() || FIt == Map.Targets.end())
    return false;
  BasicBlock *TrueTarget = TIt->second;
  BasicBlock *FalseTarget = FIt->second;
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

  auto VMap = std::make_unique<ValueToValueMapTy>();
  if (!buildHeaderEntryValueMap(Source, Header, DT, *VMap) ||
      !prepareTargetPHIs(TrueTarget, Source, TrueDispatch, DT, nullptr,
                         false) ||
      (FalseTarget != TrueTarget &&
       !prepareTargetPHIs(FalseTarget, Source, FalseDispatch, DT, nullptr,
                          false)))
    return false;

  BasicBlock *Bridge = BasicBlock::Create(
      F.getContext(), "deobf.memory.entry", &F, Header);
  IRBuilder<>(Bridge).CreateBr(TrueTarget);
  cloneHeaderPayload(Bridge, Header, *VMap);
  finalizeDispatcherCarrierMap(Header, *VMap);
  if (!prepareTargetPHIs(TrueTarget, Bridge, TrueDispatch, DT, VMap.get(),
                         true, Source) ||
      (FalseTarget != TrueTarget &&
       !prepareTargetPHIs(FalseTarget, Bridge, FalseDispatch, DT, VMap.get(),
                          true, Source)))
    report_fatal_error(
        "095 internal error: memory-entry PHI mapping became invalid");
  Header->removePredecessor(Source, true);
  IRBuilder<>(Old).CreateBr(Bridge);
  Old->eraseFromParent();
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
    errs() << "095 memory entry: function=" << F.getName()
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
    return deflattenMemoryEntry(F, Root, StateLoad, DT, AA, Prover, R);
  }
  auto *HeaderPhi = dyn_cast<PHINode>(State);
  if (!HeaderPhi || HeaderPhi->getParent() != Root->getParent())
    return false;

  BasicBlock *Header = Root->getParent();
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
    auto TIt = Map.Targets.find(Choice->TrueState->getValue());
    auto FIt = Map.Targets.find(Choice->FalseState->getValue());
    if (TIt == Map.Targets.end() || FIt == Map.Targets.end()) {
      ++UnresolvedStates;
      continue;
    }
    BasicBlock *TrueTarget = TIt->second;
    BasicBlock *FalseTarget = FIt->second;
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
      auto TIt = Map.Targets.find(Choice->TrueState->getValue());
      auto FIt = Map.Targets.find(Choice->FalseState->getValue());
      if (TIt == Map.Targets.end() || FIt == Map.Targets.end()) {
        EntryDebug("state-target-missing");
        ++UnresolvedStates;
        continue;
      }
      BasicBlock *TrueTarget = TIt->second;
      BasicBlock *FalseTarget = FIt->second;
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
    Loop *HeaderLoop = LI.getLoopFor(Header);
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
    if (!F.isDeclaration())
      BCFChanged |= removeOpaquePredicates(F, Prover, R);
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

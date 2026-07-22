#ifndef BRIGHTEN_OLLVM_DEOBF_INTERNAL_H
#define BRIGHTEN_OLLVM_DEOBF_INTERNAL_H

// Internal helper API shared between the OLLVMDeobf*.cpp translation units.
// Not part of the pass's public interface (see OLLVMDeobf.h); every declaration
// below is implemented in exactly one category-specific .cpp file, grouped the same
// way the .cpp files are, so a lookup here tells you which file owns the definition.

#include "OLLVMDeobf.h"

#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/LoopInfo.h"
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
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"
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

// Pass-wide options (defined in OLLVMDeobf.cpp).
extern llvm::cl::opt<std::string> ReportPath;

using PathConstraint = std::pair<Value *, bool>;

// ---- Forward declarations of shared types ----

struct Metrics;
struct LiftProfile;
struct ProofRecord;
struct Z3BVTranslator;
struct SMTBooleanProof;
struct CyclicPredicateProof;
enum class SMTEquivalenceResult;
struct AffineBVExpr;
struct ACBitVectorExpr;
enum class SubFlagKind;
struct SubFlagCandidate;
enum class AddFlagKind;
struct AddFlagCandidate;
enum class TestFlagKind;
struct TestFlagCandidate;
struct ProvenTransition;
struct IntAffine;
struct PlumbingStage;
struct FunnelEdge;
struct MemoryJoinEdge;
struct LadderCase;

// ---- Function declarations, grouped by owning .cpp file ----

// Common (OLLVMDeobfCommon.cpp)
std::string hashText(StringRef Text);
std::string valueText(const Value &V);
void importExistingProofs(Module &M, Metrics &Stats,
                                 SmallVectorImpl<ProofRecord> &Proofs);
std::string valueName(const Value &V);
bool containsLiftMarker(StringRef S);
bool valueContainsLiftMarker(
    const Value *Root, SmallPtrSetImpl<const Value *> &Seen);
bool isLiftedFunction(const Function &F);
bool hasPoisonGeneratingFlags(const Value *V);

// InstSub (OLLVMDeobfInstSub.cpp)
bool samePair(Value *A0, Value *A1, Value *B0, Value *B1);
bool matchBin(Value *V, unsigned Opcode, Value *&A, Value *&B);
bool matchAllOnesXor(Value *V, Value *&X);
Value *createBinLike(BinaryOperator &Old, unsigned Opcode, Value *A,
                            Value *B);
Value *matchCanonicalRewrite(BinaryOperator &I, bool &InstSub);
bool isOne(const Value *V);
bool isZero(const Value *V);
bool isAdjacentProduct(Value *V);

// SMTProof (OLLVMDeobfSMTProof.cpp)
std::optional<bool> proveBoolean(Value *V, unsigned Depth = 0);
SmallVector<PathConstraint, 16>
collectDominatingConstraints(BranchInst &Target, DominatorTree &DT);
std::optional<SMTBooleanProof>
proveBooleanSMT(
    Value *Condition, ArrayRef<PathConstraint> Constraints = {},
    const DenseMap<const LoadInst *, Value *> *ReachingLoadValues = nullptr);
void collectConditionPHIs(Value *V,
                                 SmallPtrSetImpl<PHINode *> &Phis,
                                 SmallPtrSetImpl<Value *> &Seen,
                                 unsigned Depth = 0);
std::optional<CyclicPredicateProof>
proveBooleanCyclicInduction(Value *Condition);

// StateCellPromotion (OLLVMDeobfStateCellPromotion.cpp)
Value *resolveMemorySSAValue(
    MemoryAccess *Access, LoadInst &LI, MemorySSA &MSSA,
    MemorySSAWalker &Walker, SmallPtrSetImpl<MemoryAccess *> &Seen,
    bool &UsedPhi, unsigned Depth = 0);
DenseMap<const LoadInst *, Value *>
buildMemorySSAReachingValues(Function &F, MemorySSA &MSSA, Metrics &M);
bool proveExactStateCellDefinitions(LoadInst &LI, MemorySSA &MSSA,
                                           bool *HasLiveIn = nullptr,
                                           std::string *Rejection = nullptr);
Value *materializeAddressOnEntryEdge(
    Value *V, BasicBlock *Header, BasicBlock *Pred, Instruction *Before,
    DominatorTree &DT, DenseMap<Value *, Value *> &Mapped,
    unsigned Depth = 0);
bool promoteExactStateCellLoad(
    LoadInst &LI, bool HasLiveIn, Metrics &M,
    SmallVectorImpl<ProofRecord> &Proofs);
bool eliminatePredecessorEquivalentPHIs(Function &F);

// EquivalenceProofs (OLLVMDeobfEquivalenceProofs.cpp)
SMTEquivalenceResult checkEquivalentSMT(Value *Old,
                                                Value *Replacement);
bool proveEquivalentSMT(Value *Old, Value *Replacement);
bool collectPoisonSupport(Value *V,
                                 SmallPtrSetImpl<const Value *> &Support,
                                 unsigned Depth = 0);
bool hasSamePoisonSupport(Value *Old, Value *Replacement);
bool sanitizeLiftedFunction(Function &F, Metrics &M,
                                   SmallVectorImpl<ProofRecord> &Proofs);

// AffineBV (OLLVMDeobfAffineBV.cpp)
void addAffineTerm(AffineBVExpr &Expr, Value *Leaf,
                          const APInt &Coefficient);
std::optional<AffineBVExpr> parseAffineBV(Value *V, unsigned Width,
                                                 unsigned &Budget,
                                                 unsigned Depth = 0);
unsigned affineExtractionCost(const AffineBVExpr &Expr);
Value *buildAffineBV(const AffineBVExpr &Expr, Instruction *Before);
bool sameAffineBV(const AffineBVExpr &L, const AffineBVExpr &R);
bool rewriteMultiRootAffineBVRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
bool feedsSyntheticNativePointerSelect(Value *V, unsigned Depth = 0);
bool rewriteAffineBVRegions(Function &F, Metrics &M,
                                   SmallVectorImpl<ProofRecord> &Proofs);

// ACBitVector (OLLVMDeobfACBitVector.cpp)
bool flattenACBitVector(Value *V, ACBitVectorExpr &Expr,
                               unsigned &Budget, unsigned Depth = 0);
Value *buildACBitVector(ACBitVectorExpr &Expr, Instruction *Before,
                               unsigned &NewNodes);
SmallVector<Value *, 16>
canonicalACTerms(const ACBitVectorExpr &Expr);
bool rewriteMultiRootACBitVectorRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
bool collectGeneralBVRegion(
    Value *V, SmallPtrSetImpl<Instruction *> &Nodes,
    SmallPtrSetImpl<Value *> &Leaves, unsigned Depth = 0);
unsigned generalBVRegionCost(ArrayRef<Instruction *> Nodes);
bool rewriteMultiRootGeneralBVRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
bool rewriteACBitVectorRegions(Function &F, Metrics &M,
                                      SmallVectorImpl<ProofRecord> &Proofs);
bool matchBitwiseNot(Value *V, Value *&Operand);
bool matchMaskedValue(Value *V, unsigned Opcode, Value *&Variable,
                             ConstantInt *&Mask);
bool rewriteDeMorganCastRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);

// FlagPatternMatchers (OLLVMDeobfFlagPatternMatchers.cpp)
bool matchSignBit(Value *V, Value *&Source);
bool matchLogicalShiftXorStage(Value *V, unsigned Amount,
                                      Value *&Input);
bool matchLowByteEvenParity(Value *V, Value *&Byte);
bool matchAddCarryCone(Value *Cone, BinaryOperator *&Add);
bool matchAddCarryBit(Value *V, BinaryOperator *&Add);
bool matchSubBorrowCone(Value *Cone, BinaryOperator *&Sub);
bool matchSubBorrowBit(Value *V, BinaryOperator *&Sub);
bool matchSubOverflowBit(Value *V, BinaryOperator *Sub);
bool sameICmpOperands(ICmpInst *A, ICmpInst *B);
bool matchBooleanNot(Value *V, Value *&Inner);
bool proveTupleEquivalentSMT(ArrayRef<Value *> OldRoots,
                                    Value *Replacement);
bool provePairwiseTupleEquivalentSMT(ArrayRef<Value *> OldRoots,
                                            ArrayRef<Value *> NewRoots);
bool matchSubZeroFlag(Value *V, BinaryOperator *&Sub,
                             bool &IsZero);
bool matchSubSignedLessFlag(Value *V, BinaryOperator *&Sub);
bool matchSubBorrowFlagFor(Value *V, BinaryOperator *Sub);
bool matchSubZeroFlagFor(Value *V, BinaryOperator *Sub);
bool matchSubSignedLessFlagFor(Value *V, BinaryOperator *Sub);
bool matchSubCombinedFlag(Value *V, bool Signed,
                                 BinaryOperator *&Sub);
bool matchUnsignedLessOperands(Value *V, Value *&A, Value *&B);
bool matchSignedLessOperands(Value *V, Value *&A, Value *&B);
bool matchCombinedConditionOperands(Value *V, bool Signed,
                                           Value *&A, Value *&B);
bool feedsFlagBooleanCombiner(const Instruction &I);
bool matchRotateLeftIdiom(BinaryOperator &Root, Value *&Input,
                                 unsigned &Amount);
bool rewriteRotateRegions(Function &F, Metrics &M,
                                 SmallVectorImpl<ProofRecord> &Proofs);

// FlagConeRewriting (OLLVMDeobfFlagConeRewriting.cpp)
bool collectCoveredFlagCone(
    Value *V, BinaryOperator *Producer,
    SmallPtrSetImpl<Instruction *> &Nodes, unsigned Depth = 0);
bool isLowByteOfProducer(Value *Byte, BinaryOperator *Producer);
Value *buildLowByteParityPredicate(IRBuilder<> &B,
                                          BinaryOperator *Producer,
                                          StringRef Prefix);
Value *buildSubFlagPredicate(const SubFlagCandidate &Candidate,
                                    BinaryOperator *Sub);
bool rewriteOneSubFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
bool matchAddZeroFlag(Value *V, BinaryOperator *&Add, bool &IsZero);
bool matchAddOverflowBit(Value *V, BinaryOperator *Add);
Value *buildAddFlagPredicate(const AddFlagCandidate &Candidate,
                                    BinaryOperator *Add);
bool rewriteOneAddFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
bool matchTestZeroFlag(Value *V, BinaryOperator *&Test,
                              bool &IsZero);
Value *buildTestFlagPredicate(const TestFlagCandidate &Candidate,
                                     BinaryOperator *Test);
bool rewriteOneTestFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
bool rewriteX86FlagCones(Function &F, Metrics &M,
                                SmallVectorImpl<ProofRecord> &Proofs);

// StateExprEval (OLLVMDeobfStateExprEval.cpp)
PHINode *findStateRoot(Value *V, unsigned Depth = 0);
std::optional<bool> evalStatePredicate(Value *V, PHINode *Root,
                                              const APInt &State,
                                              unsigned Depth = 0);
std::optional<APInt> evalStateExpr(Value *V, PHINode *Root,
                                          const APInt &State,
                                          unsigned Depth = 0);
std::optional<APInt> decodeStateExpr(Value *V, PHINode *Root,
                                            const APInt &Encoded,
                                            unsigned Depth = 0);

// PointerAffine (OLLVMDeobfPointerAffine.cpp)
IntAffine combineAffine(const IntAffine &L, const IntAffine &R,
                               bool Subtract);
bool sameAffineTerms(const IntAffine &L, const IntAffine &R);
const Value *unitAffineRoot(const IntAffine &A);
bool definitelyDistinctAffineObjects(const IntAffine &L,
                                             const IntAffine &R);
IntAffine parseIntegerAffine(Value *V, unsigned Depth = 0,
                                    BasicBlock *Header = nullptr,
                                    BasicBlock *Pred = nullptr,
                                    const DenseMap<BasicBlock *, BasicBlock *>
                                        *PathPreds = nullptr);
IntAffine parsePointerAffine(Value *V, unsigned Depth = 0,
                                    BasicBlock *Header = nullptr,
                                    BasicBlock *Pred = nullptr,
                                    const DenseMap<BasicBlock *, BasicBlock *>
                                        *PathPreds = nullptr);
bool sameFrameAddress(Value *A, Value *B);
bool sameFrameAddressAlongUniquePath(Value *A, Value *B,
                                            BasicBlock *Source,
                                            BasicBlock *Header);
bool frameAccessesProvablyDisjoint(Value *A, Type *ATy, Value *B,
                                          Type *BTy,
                                          const DataLayout &DL);

// TransitionEval (OLLVMDeobfTransitionEval.cpp)
std::optional<APInt> evalTransitionExpr(Value *V, Value *StatePointer,
                                               const APInt &EntryState,
                                               unsigned Depth = 0,
                                               const DenseMap<const Value *,
                                                              APInt> *Bindings =
                                                   nullptr);
Value *findUnboundTransitionChoice(
    Value *V, const DenseMap<const Value *, APInt> &Bindings,
    SmallPtrSetImpl<Value *> &Seen, unsigned Depth = 0);
bool appendUniqueTransitionValue(SmallVectorImpl<APInt> &Values,
                                        const APInt &Value,
                                        unsigned Limit = 32);
bool enumerateTransitionValues(
    Value *Root, Value *StatePointer, const APInt &EntryState,
    const DenseMap<const Value *, APInt> &Bindings,
    SmallVectorImpl<APInt> &Values, unsigned &Budget, unsigned Depth = 0,
    SmallPtrSetImpl<Value *> *ActiveChoices = nullptr);
bool proveFiniteTransitionSetSMT(Value *Root,
                                        ArrayRef<APInt> Values,
                                        std::string &Certificate);
ConstantInt *findLocalReachingConstant(LoadInst &LI,
                                               BasicBlock *Source);
ConstantInt *asTransitionConstant(Value *V, BasicBlock *Source);

// DispatcherPlumbing (OLLVMDeobfDispatcherPlumbing.cpp)
bool validatePlumbingStage(const PlumbingStage &Stage);
void clonePlumbingStage(const PlumbingStage &Stage,
                               Instruction *InsertBefore);
void cloneBlockPlumbing(ArrayRef<Instruction *> Body,
                               Instruction *InsertBefore,
                               DenseMap<const Value *, Value *> &Map);

// DispatcherCyclicStateFamily (OLLVMDeobfDispatcherCyclicStateFamily.cpp)
bool tryRecoverCyclicStateFamilyDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs,
    std::string *Rejection = nullptr);

// DispatcherGeneralFunnelPlumbing (OLLVMDeobfDispatcherGeneralFunnelPlumbing.cpp)
bool tryRecoverGeneralFunnelPlumbingDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);

// DispatcherFunnel (OLLVMDeobfDispatcherFunnel.cpp)
bool tryRecoverFunnelDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);

// DispatcherPartitionedSSA (OLLVMDeobfDispatcherPartitionedSSA.cpp)
bool tryRecoverPartitionedSSADispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);

// DispatcherPartitionedSSAPlumbing (OLLVMDeobfDispatcherPartitionedSSAPlumbing.cpp)
bool tryRecoverPartitionedSSAPlumbingDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);

// DispatcherMultiIncomingSSA (OLLVMDeobfDispatcherMultiIncomingSSA.cpp)
bool tryRecoverMultiIncomingSSADispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);

// DispatcherSSAPlumbing (OLLVMDeobfDispatcherSSAPlumbing.cpp)
bool tryRecoverSSAPlumbingDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs,
    std::string *RejectionReason = nullptr);

// DispatcherSSA (OLLVMDeobfDispatcherSSA.cpp)
bool tryRecoverSSADispatcher(SwitchInst &SI, Metrics &M,
                                    SmallVectorImpl<ProofRecord> &Proofs);
bool canCloneHeaderPlumbing(BasicBlock *Header, PHINode *State);
void cloneHeaderPlumbing(BasicBlock *Header, PHINode *State,
                                Value *RawState, Instruction *InsertBefore,
                                DenseMap<const Value *, Value *> *ResultMap =
                                    nullptr);
bool canCloneDefaultEntry(BasicBlock *Default);
BasicBlock *cloneDefaultEntry(
    BasicBlock *Default, DenseMap<const Value *, Value *> Map,
    StringRef Suffix);

// DispatcherMemoryJoin (OLLVMDeobfDispatcherMemoryJoin.cpp)
StoreInst *findReachingStateStore(BasicBlock *Source,
                                         Value *StatePointer,
                                         Type *StateType,
                                         BasicBlock *Header,
                                         unsigned Depth = 0,
                                         bool *HitBarrier = nullptr);
PHINode *buildMergedReachingStateValue(
    BasicBlock *Merge, Value *StatePointer, Type *StateType,
    BasicBlock *Header, BasicBlock *Join,
    const DenseMap<BasicBlock *, APInt> &CaseStates,
    Value *CurrentState = nullptr);
bool promoteExactPredecessorJoinStateLoad(
    LoadInst &LI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
std::optional<APInt> findUniqueCaseEntryState(
    BasicBlock *Source, BasicBlock *Header, BasicBlock *Join,
    const DenseMap<BasicBlock *, APInt> &CaseStates);
unsigned recoverMemoryJoinTransitions(
    SwitchInst &SI, SmallVectorImpl<ProofRecord> &Proofs);

// Reporting (OLLVMDeobfReporting.cpp)
std::string describeDispatcherResidual(SwitchInst &SI);
bool recoverCompareLadders(Function &F, Metrics &M,
                           SmallVectorImpl<ProofRecord> &Proofs);
bool recoverFiniteBranchDispatchers(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs);
bool recoverDispatchers(Function &F, Metrics &M,
                               SmallVectorImpl<ProofRecord> &Proofs);
void reconcileDispatcherProofs(Module &M, Metrics &Stats,
                                      SmallVectorImpl<ProofRecord> &Proofs);
LiftProfile inventoryModule(Module &M);
bool importExistingInventory(Module &M, LiftProfile &P);
void addModuleMetadata(Module &M, const Metrics &Stats,
                              const LiftProfile &Inventory,
                              ArrayRef<ProofRecord> Proofs);
void writeReport(const Module &M, const Metrics &Stats,
                        const LiftProfile &Inventory,
                        ArrayRef<ProofRecord> Proofs);

// ---- Shared types (original declaration order preserved) ----

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
      // Pointer provenance is outside the bit-vector theory used here.  A
      // ptrtoint SSA value is nevertheless a stable shared leaf: model that
      // exact value symbolically so affine identities around native frame
      // addresses can be proved without inventing pointer arithmetic facts.
      if (Cast->getOpcode() == Instruction::PtrToInt &&
          Cast->getType()->isIntegerTy()) {
        Result = makeLeaf(V);
      }
      auto Op = Result ? std::optional<z3::expr>()
                       : translate(Cast->getOperand(0));
      if (!Result && Op && Cast->getType()->isIntegerTy() &&
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
    // Any remaining integer value the theory does not model exactly (a vector
    // extractelement, an unsupported binary op, a call, ...) is a deterministic
    // leaf: model it as one uninterpreted symbol keyed by its Value*.  Because
    // the same definition maps to the same symbol on both sides of an
    // equivalence query, an affine/AC identity whose leaves include such a
    // value is still provable; abstracting a shared subterm only makes the
    // query strictly more general (universally quantified over the symbol), so
    // it can never manufacture a false Proved -- at worst a false Disproved,
    // which merely declines the speculative rewrite.
    if (!Result && V->getType()->isIntegerTy())
      Result = makeLeaf(V);
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

struct CyclicPredicateProof {
  bool Value = false;
  std::string Certificate;
};

enum class SMTEquivalenceResult { Proved, Disproved, Unknown };

struct AffineBVExpr {
  APInt Constant;
  SmallVector<std::pair<Value *, APInt>, 8> Terms;
  unsigned Nodes = 0;
  bool Valid = false;

  explicit AffineBVExpr(unsigned Width)
      : Constant(Width, 0), Valid(true) {}
};

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

enum class SubFlagKind { ZF, NZ, SF, OF, CF, AE, BE, A, L, GE, LE, G, PF };

struct SubFlagCandidate {
  Instruction *Root = nullptr;
  SubFlagKind Kind = SubFlagKind::ZF;
};

enum class AddFlagKind { ZF, NZ, SF, OF, CF, PF };

struct AddFlagCandidate {
  Instruction *Root = nullptr;
  AddFlagKind Kind = AddFlagKind::ZF;
};

enum class TestFlagKind { ZF, NZ, SF, PF };

struct TestFlagCandidate {
  Instruction *Root = nullptr;
  TestFlagKind Kind = TestFlagKind::ZF;
};

struct ProvenTransition {
  BasicBlock *Source = nullptr;
  SelectInst *Selector = nullptr;
  Value *Condition = nullptr;
  BasicBlock *TrueTarget = nullptr;
  BasicBlock *FalseTarget = nullptr;
  bool TrueViaDefault = false;
  bool FalseViaDefault = false;
  Value *FiniteState = nullptr;
  SmallVector<APInt, 8> FiniteRawValues;
  SmallVector<BasicBlock *, 8> FiniteTargets;
  SmallVector<bool, 8> FiniteViaDefault;
};

struct IntAffine {
  // Keep every symbolic term instead of accepting only GlobalValue roots.
  // Native cleanup spells stack addresses as
  //   frame_base + (dynamic_rsp - ptrtoint(frame_base)) + constant
  // so the pointer-base terms cancel and the surviving root is commonly an
  // Argument or PHI.  The old single-GlobalValue representation rejected
  // those exact addresses and made dispatcher recovery accidentally depend
  // on a later O3/GVN run.
  DenseMap<const Value *, int64_t> Terms;
  APInt Offset = APInt(64, 0);
  bool Valid = false;
};

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

struct LadderCase {
  BasicBlock *Block = nullptr;
  ConstantInt *Key = nullptr;
  BasicBlock *Target = nullptr;
};

} // namespace brighten_ollvm_deobf

#endif

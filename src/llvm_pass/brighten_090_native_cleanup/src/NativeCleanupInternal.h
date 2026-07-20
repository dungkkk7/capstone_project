#ifndef BRIGHTEN_NATIVE_CLEANUP_INTERNAL_H
#define BRIGHTEN_NATIVE_CLEANUP_INTERNAL_H

// Internal helper API shared between the NativeCleanup*.cpp translation units.
// Not part of the pass's public interface (see NativeCleanup.h); every declaration
// below is implemented in exactly one category-specific .cpp file, grouped the same
// way the .cpp files are, so a lookup here tells you which file owns the definition.

#include "NativeCleanup.h"
#include "NativeStateSSA.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <string>
#include <algorithm>
#include <functional>
#include <limits>
#include <map>
#include <optional>
#include <set>

using namespace llvm;

namespace brighten_native_cleanup {

// Pass-wide options (defined in NativeCleanup.cpp).
extern llvm::cl::opt<bool> NativeStrict;
extern llvm::cl::opt<bool> NativeStateSSA;

// ---- Common ------------------------------------------------------

bool isLiftedFunctionName(StringRef Name);
bool isLiftedGlobalName(StringRef Name);
bool isStateType(Type *Ty);
bool isLiftedABI(Function &F);
bool isAddressArtifact(Value *V);
bool containsUndefined(Value *V);
void addFinding(SmallVectorImpl<std::string> &Findings,
                       StringRef Category, StringRef Name);

// ---- UndefPoison -------------------------------------------------

unsigned canonicalizeDeadLiftedArguments(Module &M);
unsigned canonicalizeEquivalentPhiUndefined(Module &M);
unsigned freezeUndefinedInstructionOperands(Module &M);
Constant *definedScaffold(Constant *C);
unsigned lowerFullyOverwrittenUndefinedScaffolds(Module &M);
bool isVectorLaneUnobserved(Value *V, unsigned Lane,
                                   std::set<std::pair<Value *, unsigned>> &Seen);
unsigned lowerUnobservedUndefinedShuffleLanes(Module &M);
unsigned lowerSingleLaneVectorBroadcasts(Module &M);

// ---- PointerAnalysis ---------------------------------------------

bool isNativeStateSlot(Value *V);
bool isNativeInteger(Value *V, SmallPtrSetImpl<Value *> &Visited);
bool isNativePointerValue(Value *V,
                                 SmallPtrSetImpl<Value *> &Visited);
Value *getDirectNativePointerCarrier(Value *V);
Value *findNativeVarargAddressCarrier(Value *V,
                                             SmallPtrSetImpl<Value *> &Seen);
Value *findNativeVarargCarrierInRecoveredDispatch(Value *V);
std::optional<uint64_t> parseGuestAddressPrefix(StringRef Name,
                                                       StringRef Prefix);
void setGuestBaseMetadata(Module &M, GlobalVariable &GV,
                                 uint64_t GuestBase);
unsigned lowerProvenNativePointerTranslations(Module &M,
                                                      bool &Changed);
bool IsNativeVarargSaveSlot(Value *Ptr);
bool containsNativeStackInteger(
    Value *V, SmallPtrSetImpl<Value *> &Seen);
Argument *findNativeStackArgument(Function &F);
Value *findNativeStackAnchor(Function &F);
Value *getNativeStackFrameTop(IRBuilder<> &B, Function &F,
                                     Value *NativeStack);
Value *findInitialStateStackInteger(Function &F);
Value *materializeEntryIntegerAt(
    Value *V, IRBuilder<> &B, Function &F,
    DenseMap<Value *, Value *> &Mapped,
    SmallVectorImpl<Instruction *> &Created, unsigned Depth = 0);
bool isNativeStackPointer(Value *V,
                                 SmallPtrSetImpl<Value *> &Seen);
bool IsDirectControlPredicate(Instruction *I);
bool containsNativeStackAnchorInteger(
    Value *V, SmallPtrSetImpl<Value *> &Seen);
Value *lowerNativeStackInteger(IRBuilder<> &B, Value *Integer,
                                      Function &F);
bool hasRawNativeStackIntToPtrCandidate(Module &M);
unsigned lowerRawNativeStackIntToPtrs(Module &M, bool &Changed);
unsigned rewriteNativeDataStackGEPs(Module &M, bool &Changed);

// ---- GuestData ---------------------------------------------------

struct GuestAddressExpression {
  GlobalVariable *Segment = nullptr;
  uint64_t SegmentOffset = 0;
  Value *DynamicOffset = nullptr;
};

struct ConstantGuestInteger {
  APInt Value;
  bool UsedRecoveredPointer = false;
};

std::optional<std::pair<GlobalVariable *, uint64_t>>
resolveConstantGlobalPointer(Value *V, const DataLayout &DL,
                             unsigned Depth = 0);
bool formatHasAnyConversion(StringRef Text);
std::optional<std::string>
readConstantFormatString(Value *Format, const DataLayout &DL);
AllocaInst *getRootAlloca(Value *V);
std::optional<uint64_t> getConstantGEPByteOffset(Value *Ptr,
                                                         AllocaInst *Root,
                                                         const DataLayout &DL);
void collectFormatPointerSlots(StringRef Format, bool IsScanf,
                                      unsigned FirstVarargOffset,
                                      SmallVectorImpl<unsigned> &Slots);
std::optional<std::pair<GlobalVariable *, uint64_t>>
FindRecoveredGlobalForGuestAddress(Module &M, uint64_t Address);
std::optional<std::pair<GlobalVariable *, uint64_t>>
FindNativeSegmentForGuestRange(Module &M, uint64_t Begin, uint64_t End);
std::optional<std::pair<uint64_t, uint64_t>>
getGuestRange(GlobalVariable &GV);
std::optional<uint64_t> getConstantGuestPointer(Value *V);
unsigned materializeResidualLibcFormats(Module &M, bool &Changed);
void preserveRecoveredGlobalsAcrossOptimization(Module &M);
void setGuestRangeMetadata(Module &M, GlobalVariable &GV,
                                  uint64_t Begin, uint64_t End);
unsigned widenOverNarrowRecoveredScalars(Module &M, bool &Changed);
unsigned rewriteRecoveredGlobalsToNativeSegments(Module &M,
                                                         bool &Changed);
unsigned inlineGuestPointerTranslators(Module &M, bool &Changed);
unsigned rewriteRemainingDataAliasesToNativeSegments(Module &M,
                                                            bool &Changed);
unsigned rewriteConstantGuestPointerOperands(Module &M,
                                                    bool &Changed);
unsigned rewriteDeadRIPDataAliases(Module &M, bool &Changed);
bool isProvenScalarLibcCallArgument(Value *V, CallBase &CB);
unsigned rewriteGuestAddressIdentityAliasIntegers(Module &M,
                                                         bool &Changed);
std::optional<uint64_t>
findConstantRecoveredGuestAddress(Module &M, Value *V, unsigned Depth = 0);
std::optional<ConstantGuestInteger>
evaluateConstantGuestInteger(Module &M, Constant *C, unsigned Depth = 0);
unsigned rewriteRecoveredPointerIntegerIdentities(Module &M,
                                                        bool &Changed);
std::optional<GuestAddressExpression>
findGuestAddressExpression(Module &M, Value *V, IRBuilder<> &B,
                           unsigned Depth = 0);
unsigned rewriteNativeScanfVarargAddresses(Module &M,
                                                   bool &Changed);
unsigned rewriteDynamicGuestAddressIntToPtr(Module &M,
                                                     bool &Changed);

// ---- PointerMaterialization --------------------------------------

bool isRecoveredPointerExternalArgument(StringRef Name,
                                               unsigned Index);
Function *getOrCreateRecoveredDataPointerMapper(Module &M);
GlobalVariable *getOrCreateRecoveredOobScratch(Module &M);
Value *createRecoveredOobScratchPointer(Module &M, IRBuilder<> &B,
                                               Value *GuestAddress,
                                               StringRef Name);
Value *materializeRecoveredDataPointer(Module &M, IRBuilder<> &B,
                                              Value *Address);
unsigned rewriteResidualRecoveredDataIntToPtrs(Module &M,
                                                       bool &Changed);
Value *
findMaterializedRecoveredGuestAddress(Value *V, SmallPtrSetImpl<Value *> &Seen);
unsigned rewriteMaterializedRecoveredPointerByteGEPs(Module &M,
                                                            bool &Changed);
unsigned rewriteRecoveredGlobalStackIndexedGEPs(Module &M,
                                                       bool &Changed);
unsigned rewriteRecoveredExternalPointerArguments(Module &M,
                                                          bool &Changed,
                                                          bool ScanfOnly = false);
unsigned rewriteNativeVarargExternalPointerArguments(Module &M,
                                                            bool &Changed);
unsigned rewriteRecoveredVarargSaveSlots(Module &M, bool &Changed);

// ---- ExternalABI -------------------------------------------------

unsigned repairNativeAllocatorRAX(Module &M, bool &Changed);
FunctionType *nativeExternalType(Module &M, StringRef Name);
Value *coerceNativeExternalValue(IRBuilder<> &B, Value *V, Type *Dst);
unsigned normalizeNativeExternalABIs(Module &M, bool &Changed,
                                             SmallVectorImpl<std::string> *Findings);
unsigned materializeMissingScanfDestinations(Module &M, bool &Changed);
bool parseStateSlotName(StringRef Name, StringRef Prefix,
                               uint64_t &Offset);
bool isStateOutputValue(Value *V, uint64_t Offset,
                               SmallPtrSetImpl<Value *> &Seen);
std::optional<unsigned>
findStateOutputIndex(Value *Aggregate, uint64_t Offset,
                     SmallPtrSetImpl<Value *> &Seen);
unsigned preserveNativeRBPOutputs(Module &M, bool &Changed);
unsigned inlineExternalLiftedWrappers(Module &M, bool &Changed);

// ---- Segments ----------------------------------------------------

bool readConstantByte(Constant *C, const DataLayout &DL,
                             uint64_t Offset, uint8_t &Byte);
std::optional<uint64_t> segmentPointerOffset(Value *V,
                                                     GlobalVariable *Segment,
                                                     const DataLayout &DL);
unsigned materializeNativeSegmentPointers(Module &M, bool &Changed);
unsigned rewriteExactNativeSegmentGEPs(Module &M, bool &Changed);

// ---- ContractReport ----------------------------------------------

bool isRemillMetadataName(StringRef Name);
bool isGuestStackRegister(Value *V,
                                 SmallPtrSetImpl<Value *> &Seen);
void collectNativeContractViolations(
    Module &M, SmallVectorImpl<std::string> &Findings);
unsigned countStateGlobals(Module &M);
void reportNativeContract(Module &M, unsigned RemovedFunctions,
                                 unsigned RemovedGlobals,
                                 bool EnforceStrict);
void stripRemillMetadata(Module &M, bool &Changed,
                                bool StripGuestRanges = true);
void foldExactPointerRoundTrips(Module &M, bool &Changed);

// ---- Callbacks ---------------------------------------------------

Function *resolveCallbackFunction(Value *V,
                                         SmallPtrSetImpl<Value *> &Seen);
Value *coerceCallbackArgument(IRBuilder<> &B, Value *V, Type *Ty,
                                     const Twine &Name);
unsigned lowerNativeCallbackTrampolines(Module &M, bool &Changed);
unsigned lowerNativeQsortCallbacks(Module &M, bool &Changed);

// ---- DeadCode ----------------------------------------------------

unsigned eraseBrightenReturnMarkers(Module &M, bool &Changed);
unsigned eraseUnusedLiftedFunctions(Module &M, bool &Changed);
unsigned eraseDeadInlineAsmTrampolines(Module &M, bool &Changed);
unsigned eraseUnusedInlineAsmCalls(Module &M, bool &Changed);
unsigned eraseUnusedInternalGlobals(Module &M, bool &Changed);
unsigned eraseUnusedNativeDataArtifacts(Module &M, bool &Changed);

// ---- Entrypoint --------------------------------------------------

GlobalVariable *ensureNativeEntrypointStackStorage(Module &M);
bool normalizeNativeEntrypoint(Module &M, bool &Changed);
unsigned preserveNativeEntrypointStateBoundary(Module &M,
                                                       bool &Changed);
unsigned preserveNestedNativeFrameBoundaries(Module &M,
                                                     bool &Changed);
bool IsStartupOnlyUse(User *U, Function *Target);
bool RemoveTargetFromDispatcher(Function &Dispatcher,
                                       Function *Target);
bool RemoveTargetFromGuestPointerTranslator(Module &M,
                                                    Function *Target,
                                                    uint64_t GuestPC);
unsigned eraseDeadSyntheticStartupDispatch(Module &M, bool &Changed);
unsigned eraseUnusedLiftedGlobals(Module &M, bool &Changed);
unsigned eraseDeadStateGlobals(Module &M, bool &Changed);
bool constantContainsStateGlobal(Constant *C, GlobalVariable *GV,
                                        SmallPtrSetImpl<Constant *> &Seen);
bool collectStateGlobalInstructionUsers(
    Value *V, Function *&Owner, SmallPtrSetImpl<Value *> &Seen);
Value *materializeStateConstantForAlloca(Constant *C,
                                                GlobalVariable *GV,
                                                AllocaInst *Storage,
                                                Instruction *InsertBefore);
unsigned localizePrivateStateGlobals(Module &M, bool &Changed);
Value *materializeHubValueOnPred(Value *V, BasicBlock *Hub,
                                        BasicBlock *Pred, IRBuilder<> &B,
                                        DenseMap<Value *, Value *> &Cache);
bool isDispatcherStateValue(Value *V, SwitchInst *SW,
                                   SmallPtrSetImpl<Value *> &Seen);
bool isDispatcherStateValue(Value *V, SwitchInst *SW);
StoreInst *findDispatcherStateStore(BasicBlock *BB, Value *Ptr,
                                           SwitchInst *SW);
unsigned promoteStackDispatcherStateSlots(Module &M, bool &Changed);
unsigned eraseDeadMcsemaEntrypoint(Module &M, bool &Changed);

// ---- StackFrame --------------------------------------------------

struct ProvenFrameAccess {
  Instruction *Inst = nullptr;
  unsigned PointerOperand = 0;
  int64_t Begin = 0;
  int64_t End = 0;
  bool Reads = false;
  bool Writes = false;
};

struct FrameAffineInteger {
  APInt Constant;
  int64_t RootCoefficient = 0;
};

bool addSignedOffset(int64_t Base, int64_t Delta, int64_t &Result);
std::optional<FrameAffineInteger>
evaluateFrameInteger(Value *V, GlobalVariable &Backing, const DataLayout &DL,
                     unsigned Bits, SmallPtrSetImpl<Value *> &IntegerSeen);
std::optional<int64_t>
evaluateFramePointerOffset(Value *V, GlobalVariable &Backing,
                           const DataLayout &DL,
                           SmallPtrSetImpl<Value *> &PointerSeen);
unsigned canonicalizeFrameBackingAffinePointers(Module &M,
                                                        bool &Changed);
unsigned collapseFrameProvenantDataPointerSelects(Module &M,
                                                          bool &Changed);
std::optional<uint64_t>
getScanfDestinationSize(CallBase &CB, unsigned ArgNo,
                        const DataLayout &DL);
unsigned isolateRecoveredScanfDestinations(Module &M, bool &Changed);
bool proveConstantFrameBacking(GlobalVariable &Backing,
                                      SmallVectorImpl<ProvenFrameAccess> &Out,
                                      Function *&Owner, uint64_t &ObjectSize);
bool readsAreDominatedByWrites(ArrayRef<ProvenFrameAccess> Accesses,
                                      Function &Owner);
unsigned compactProvenConstantFrameBackings(Module &M, bool &Changed);

// ---- BoundsGuards ------------------------------------------------

unsigned seedFailedIntegerScanfDestinations(Module &M, bool &Changed);
bool isRecoveredWorkArrayName(StringRef Name);
uint64_t getRecoveredWorkArrayGuestBase(GlobalVariable &GV);
unsigned guardRecoveredGlobalBounds(Module &M, bool &Changed);
unsigned guardRecoveredStackBounds(Module &M, bool &Changed);
unsigned isolateRecoveredWorkArrayPrefix(Module &M, bool &Changed);
GlobalVariable *findRecoveredArrayRoot(Value *V, bool &HasDynamic,
                                              unsigned Depth = 0);
bool isResidualConstantPointer(Value *V);
unsigned rewriteResidualQsortArrayArguments(Module &M, bool &Changed);

} // namespace brighten_native_cleanup

#endif

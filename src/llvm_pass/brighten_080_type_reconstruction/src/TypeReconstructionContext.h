#ifndef BRIGHTEN_080_TYPE_RECONSTRUCTION_CONTEXT_H
#define BRIGHTEN_080_TYPE_RECONSTRUCTION_CONTEXT_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/CommandLine.h"

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace brighten_type {

using namespace llvm;

enum class TypeMode {
  Conservative,
  Balanced,
  Aggressive
};

enum class ObjectKind {
  Stack,
  Global,
  OtherProven
};

enum class EvidenceKind {
  CallSignature,
  LoadStoreType,
  AffineArray,
  ConstantOffset,
  ArithmeticClue,
  InitializerBytes
};

struct AccessFact {
  Value *BaseObject = nullptr;
  std::optional<int64_t> ConstantOffset;
  Value *DynamicIndexExpr = nullptr;
  int64_t Stride = 0;
  uint64_t AccessSize = 0;
  Type *ObservedType = nullptr;
  bool IsWrite = false;
  Align Alignment;
  bool IsVolatile = false;
  bool IsAtomic = false;
  AtomicOrdering Ordering = AtomicOrdering::NotAtomic;
  SyncScope::ID SyncScope = SyncScope::SingleThread;
  Instruction *SourceInst = nullptr;
  EvidenceKind Kind = EvidenceKind::LoadStoreType;
  bool IsPointerClue = false;
  bool IsFloatClue = false;
  bool IsIntegerClue = false;
  bool IsAggregateClue = false;
  bool IsSignedClue = false;
};

struct ObjectCandidate {
  Value *BaseVal = nullptr; // AllocaInst or GlobalVariable
  uint64_t ObjectSize = 0;
  Align ABIAlignment;
  unsigned AddressSpace = 0;
  ObjectKind Kind = ObjectKind::Stack;
  bool Escaped = false;
  GlobalValue::LinkageTypes Linkage = GlobalValue::InternalLinkage;
  std::vector<AccessFact> Accesses;
  unsigned Confidence = 100;
  std::vector<std::string> RejectionReasons;
  std::string Name;
};

struct InferredTypePlan {
  ObjectCandidate *Candidate = nullptr;
  Type *ProposedRootType = nullptr;
  // Field offset to type mapping for struct, or element type for array
  std::map<uint64_t, Type *> FieldLayout;
  uint64_t ElementCount = 0; // For arrays
  bool IsArray = false;
  uint64_t TotalSize = 0;
  unsigned Confidence = 100;
  std::vector<std::string> RejectionReasons;
  bool Committed = false;
};

struct TypeReconstructionReport {
  unsigned ObjectsAnalyzed = 0;
  unsigned ObjectsReconstructed = 0;
  unsigned StructsReconstructed = 0;
  unsigned ArraysRecovered = 0;
  unsigned GlobalsRetyped = 0;
  unsigned AllocasRetyped = 0;
  unsigned GEPsRewritten = 0;
  unsigned ObjectsRejectedOverlap = 0;
  unsigned ObjectsRejectedEscape = 0;
  unsigned ObjectsRejectedUnknownOffset = 0;
  unsigned ObjectsRejectedInitializer = 0;
  unsigned VerificationFailures = 0;
  std::vector<std::string> LogMessages;
};

struct TypeReconstructionContext {
  Module &M;
  const DataLayout &DL;
  TypeMode Mode = TypeMode::Conservative;
  unsigned MinConfidence = 0;
  unsigned MaxDepth = 4;
  unsigned MinArrayElements = 2;
  std::string ReportPath;
  bool Verify = false;
  bool DumpRejections = false;

  std::vector<std::unique_ptr<ObjectCandidate>> Candidates;
  std::map<Value *, std::unique_ptr<InferredTypePlan>> Plans;
  TypeReconstructionReport Report;

  explicit TypeReconstructionContext(Module &Mod)
      : M(Mod), DL(Mod.getDataLayout()) {}
};

} // namespace brighten_type

#endif

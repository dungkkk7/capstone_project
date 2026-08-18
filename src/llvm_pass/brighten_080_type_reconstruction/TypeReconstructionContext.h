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

#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

namespace brighten_type {

using namespace llvm;

// The production pass is intentionally proof-oriented.  The mode is retained
// as an experiment factor, but no mode is allowed to resolve contradictory
// observations by guessing a type or by silently converting a union into raw
// bytes.  A conflict is a refusal in every mode.
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

enum class TypeFamily {
  Integer,
  Floating,
  Pointer,
  Aggregate,
  ByteSequence,
  Unsupported
};

struct AccessFact {
  Value *BaseObject = nullptr;
  std::optional<int64_t> ConstantOffset;
  Value *DynamicIndexExpr = nullptr;
  int64_t Stride = 0;
  uint64_t AccessSize = 0;
  Type *ObservedType = nullptr;
  bool IsWrite = false;
  Align Alignment = Align(1);
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
  bool IsWeak = false;
};

struct SolvedField {
  uint64_t Offset = 0;
  uint64_t Size = 0;
  Type *Ty = nullptr;
  TypeFamily Family = TypeFamily::Unsupported;
  Align MinimumAlignment = Align(1);
  bool HasRead = false;
  bool HasWrite = false;
  bool HasVolatile = false;
  bool HasAtomic = false;
  unsigned EvidenceCount = 0;
};

struct TypeConstraintSolution {
  bool Valid = false;
  bool HasDynamicIndex = false;
  Value *DynamicIndexExpr = nullptr;
  uint64_t ElementStride = 0;
  uint64_t ElementCount = 0;
  unsigned Confidence = 0;
  std::vector<SolvedField> Fields;
  std::vector<std::string> RejectionReasons;
};

struct ObjectCandidate {
  Value *BaseVal = nullptr; // AllocaInst or GlobalVariable
  uint64_t ObjectSize = 0;
  Align ABIAlignment = Align(1);
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
  std::map<uint64_t, Type *> FieldLayout;
  uint64_t ElementCount = 0;
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
  unsigned ObjectsRejectedConflict = 0;
  unsigned ObjectsRejectedEscape = 0;
  unsigned ObjectsRejectedUnknownOffset = 0;
  unsigned ObjectsRejectedNonAffine = 0;
  unsigned ObjectsRejectedOutOfBounds = 0;
  unsigned ObjectsRejectedInitializer = 0;
  unsigned VerificationFailures = 0;
  std::vector<std::string> LogMessages;
};

struct TypeReconstructionContext {
  Module &M;
  const DataLayout &DL;
  TypeMode Mode = TypeMode::Conservative;
  unsigned MinConfidence = 80;
  unsigned MaxDepth = 16;
  unsigned MinArrayElements = 2;
  std::string ReportPath;
  bool Verify = true;
  bool DumpRejections = false;

  std::vector<std::unique_ptr<ObjectCandidate>> Candidates;
  std::map<ObjectCandidate *, TypeConstraintSolution> Solutions;
  std::map<Value *, std::unique_ptr<InferredTypePlan>> Plans;
  TypeReconstructionReport Report;

  explicit TypeReconstructionContext(Module &Mod)
      : M(Mod), DL(Mod.getDataLayout()) {}
};

TypeFamily ClassifyTypeFamily(Type *Ty);
bool AreEvidenceTypesCompatible(Type *A, Type *B, const DataLayout &DL);
bool CollectAccessEvidence(TypeReconstructionContext &Ctx);
bool SolveTypeConstraints(TypeReconstructionContext &Ctx);
const TypeConstraintSolution *GetTypeSolution(const ObjectCandidate &Cand,
                                              const TypeReconstructionContext &Ctx);

Type *BuildStructTypeFromSolvedFields(ObjectCandidate &Cand,
                                      ArrayRef<SolvedField> Fields,
                                      uint64_t ObjectSize,
                                      TypeReconstructionContext &Ctx,
                                      StringRef NameSuffix = "");

} // namespace brighten_type

#endif

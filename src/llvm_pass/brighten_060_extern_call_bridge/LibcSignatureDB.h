#ifndef BRIGHTEN_060_LIBC_SIGNATURE_DB_H
#define BRIGHTEN_060_LIBC_SIGNATURE_DB_H

#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Type.h"

#include <string>
#include <vector>

namespace brighten_extern {

enum class LibcParamKind {
  Integer,
  SizeT,
  Pointer,
  ConstPointer,
  WritePointer,
  FilePointer,
  VoidStar,
  Double,
  Float,
  Char,
};

enum class LibcSpecialKind {
  None,
  PrintfLike,
  ScanfLike,
  SprintfLike,
  SnprintfLike,
  FprintfLike,
  SscanfLike,
  FscanfLike,
  Allocator,
  Deallocator,
  NoReturn,
};

struct LibcParam {
  LibcParamKind Kind;
  const char *Name;
  bool IsWritePointer;

  bool isPointer() const {
    return Kind == LibcParamKind::Pointer ||
           Kind == LibcParamKind::ConstPointer ||
           Kind == LibcParamKind::WritePointer ||
           Kind == LibcParamKind::FilePointer ||
           Kind == LibcParamKind::VoidStar;
  }
};

enum class VarargType {
  IntI32,
  IntI64,
  UintI32,
  UintI64,
  CharI8,
  Pointer,
  Double,
  Percent,
  WidthStar,
  PrecisionStar,
  ScanfSuppressed,
  Unknown,
};

struct VarargSpecifier {
  VarargType Ty;
  std::string Raw;
  bool UsesGPReg;
  bool UsesXMMReg;
  bool ConsumesArg;
};

struct LibcSignature {
  const char *Name;
  LibcParamKind ReturnKind;
  std::vector<LibcParam> FixedParams;
  bool IsVarArg;
  bool WritesMemory;
  bool ReadsMemory;
  bool AllocatesMemory;
  bool FreesMemory;
  bool ReturnsPointer;
  bool ReturnMayAliasArg;
  LibcSpecialKind Special;
};

class LibcSignatureDB {
public:
  void initialize(llvm::LLVMContext &Ctx);
  const LibcSignature *lookup(llvm::StringRef Name) const;

  llvm::FunctionType *buildFunctionType(llvm::LLVMContext &Ctx,
                                        const LibcSignature &Sig) const;

  llvm::Type *paramType(llvm::LLVMContext &Ctx, LibcParamKind Kind) const;
  llvm::Type *returnType(llvm::LLVMContext &Ctx,
                         const LibcSignature &Sig) const;

private:
  llvm::StringMap<LibcSignature> Entries;
  bool Initialized = false;

  void addEntry(LibcSignature Sig);
};

bool parseFormatString(llvm::StringRef Fmt,
                       llvm::SmallVectorImpl<VarargSpecifier> &Out,
                       bool IsScanfFamily);

bool isScanfFamilyKind(LibcSpecialKind K);

} // namespace brighten_extern

#endif

#include "LibcSignatureDB.h"

#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/raw_ostream.h"

#include <cctype>

namespace brighten_extern {

using namespace llvm;

void LibcSignatureDB::addEntry(LibcSignature Sig) {
  Entries.try_emplace(Sig.Name, std::move(Sig));
}

bool isScanfFamilyKind(LibcSpecialKind K) {
  return K == LibcSpecialKind::ScanfLike ||
         K == LibcSpecialKind::SscanfLike ||
         K == LibcSpecialKind::FscanfLike;
}

void LibcSignatureDB::initialize(LLVMContext &Ctx) {
  if (Initialized)
    return;
  Initialized = true;

  using PK = LibcParamKind;
  using SK = LibcSpecialKind;

  addEntry({"puts", PK::Integer,
            {{PK::ConstPointer, "s", false}},
            false, false, true, false, false, false, false, SK::None});
  addEntry({"strlen", PK::SizeT,
            {{PK::ConstPointer, "s", false}},
            false, false, true, false, false, false, false, SK::None});
  addEntry({"strcmp", PK::Integer,
            {{PK::ConstPointer, "s1", false}, {PK::ConstPointer, "s2", false}},
            false, false, true, false, false, false, false, SK::None});
  addEntry({"strncmp", PK::Integer,
            {{PK::ConstPointer, "s1", false}, {PK::ConstPointer, "s2", false},
             {PK::SizeT, "n", false}},
            false, false, true, false, false, false, false, SK::None});
  addEntry({"strcpy", PK::Pointer,
            {{PK::WritePointer, "dst", true}, {PK::ConstPointer, "src", false}},
            false, true, true, false, false, true, true, SK::None});
  addEntry({"strncpy", PK::Pointer,
            {{PK::WritePointer, "dst", true}, {PK::ConstPointer, "src", false},
             {PK::SizeT, "n", false}},
            false, true, true, false, false, true, true, SK::None});
  addEntry({"strcat", PK::Pointer,
            {{PK::WritePointer, "dst", true}, {PK::ConstPointer, "src", false}},
            false, true, true, false, false, true, true, SK::None});
  addEntry({"strncat", PK::Pointer,
            {{PK::WritePointer, "dst", true}, {PK::ConstPointer, "src", false},
             {PK::SizeT, "n", false}},
            false, true, true, false, false, true, true, SK::None});
  addEntry({"memcpy", PK::Pointer,
            {{PK::WritePointer, "dst", true}, {PK::ConstPointer, "src", false},
             {PK::SizeT, "n", false}},
            false, true, true, false, false, true, true, SK::None});
  addEntry({"memmove", PK::Pointer,
            {{PK::WritePointer, "dst", true}, {PK::ConstPointer, "src", false},
             {PK::SizeT, "n", false}},
            false, true, true, false, false, true, true, SK::None});
  addEntry({"memset", PK::Pointer,
            {{PK::WritePointer, "dst", true}, {PK::Integer, "c", false},
             {PK::SizeT, "n", false}},
            false, true, false, false, false, true, true, SK::None});
  addEntry({"memcmp", PK::Integer,
            {{PK::ConstPointer, "s1", false}, {PK::ConstPointer, "s2", false},
             {PK::SizeT, "n", false}},
            false, false, true, false, false, false, false, SK::None});

  // Allocators disabled for safety against pointer truncation bugs
  /*
  addEntry({"malloc", PK::Pointer,
            {{PK::SizeT, "size", false}},
            false, false, false, true, false, true, false, SK::Allocator});
  addEntry({"calloc", PK::Pointer,
            {{PK::SizeT, "nmemb", false}, {PK::SizeT, "size", false}},
            false, false, false, true, false, true, false, SK::Allocator});
  addEntry({"realloc", PK::Pointer,
            {{PK::VoidStar, "ptr", false}, {PK::SizeT, "size", false}},
            false, false, false, true, true, true, false, SK::Allocator});
  addEntry({"free", PK::Integer,
            {{PK::VoidStar, "ptr", false}},
            false, false, false, false, true, false, false, SK::Deallocator});
  */

  addEntry({"exit", PK::Integer,
            {{PK::Integer, "status", false}},
            false, false, false, false, false, false, false, SK::NoReturn});
  addEntry({"abort", PK::Integer,
            {},
            false, false, false, false, false, false, false, SK::NoReturn});
  addEntry({"atoi", PK::Integer,
            {{PK::ConstPointer, "nptr", false}},
            false, false, true, false, false, false, false, SK::None});
  addEntry({"atol", PK::SizeT,
            {{PK::ConstPointer, "nptr", false}},
            false, false, true, false, false, false, false, SK::None});
  addEntry({"atoll", PK::SizeT,
            {{PK::ConstPointer, "nptr", false}},
            false, false, true, false, false, false, false, SK::None});
  addEntry({"abs", PK::Integer,
            {{PK::Integer, "j", false}},
            false, false, false, false, false, false, false, SK::None});
  addEntry({"labs", PK::SizeT,
            {{PK::SizeT, "j", false}},
            false, false, false, false, false, false, false, SK::None});

  // Vararg: printf family
  addEntry({"printf", PK::Integer,
            {{PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::PrintfLike});
  addEntry({"fprintf", PK::Integer,
            {{PK::FilePointer, "stream", false},
             {PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::FprintfLike});
  addEntry({"sprintf", PK::Integer,
            {{PK::WritePointer, "buf", true},
             {PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::SprintfLike});
  addEntry({"snprintf", PK::Integer,
            {{PK::WritePointer, "buf", true}, {PK::SizeT, "size", false},
             {PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::SnprintfLike});

  // Vararg: scanf family
  addEntry({"scanf", PK::Integer,
            {{PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::ScanfLike});
  addEntry({"__isoc99_scanf", PK::Integer,
            {{PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::ScanfLike});
  addEntry({"__isoc23_scanf", PK::Integer,
            {{PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::ScanfLike});
  addEntry({"fscanf", PK::Integer,
            {{PK::FilePointer, "stream", false},
             {PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::FscanfLike});
  addEntry({"__isoc99_fscanf", PK::Integer,
            {{PK::FilePointer, "stream", false},
             {PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::FscanfLike});
  addEntry({"sscanf", PK::Integer,
            {{PK::ConstPointer, "str", false},
             {PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::SscanfLike});
  addEntry({"__isoc99_sscanf", PK::Integer,
            {{PK::ConstPointer, "str", false},
             {PK::ConstPointer, "fmt", false}},
            true, true, true, false, false, false, false, SK::SscanfLike});
}

const LibcSignature *LibcSignatureDB::lookup(StringRef Name) const {
  auto It = Entries.find(Name);
  if (It == Entries.end())
    return nullptr;
  return &It->second;
}

Type *LibcSignatureDB::paramType(LLVMContext &Ctx, LibcParamKind Kind) const {
  switch (Kind) {
  case LibcParamKind::Integer:
  case LibcParamKind::Char:
    return Type::getInt32Ty(Ctx);
  case LibcParamKind::SizeT:
    return Type::getInt64Ty(Ctx);
  case LibcParamKind::Pointer:
  case LibcParamKind::ConstPointer:
  case LibcParamKind::WritePointer:
  case LibcParamKind::FilePointer:
  case LibcParamKind::VoidStar:
    return PointerType::getUnqual(Ctx);
  case LibcParamKind::Double:
    return Type::getDoubleTy(Ctx);
  case LibcParamKind::Float:
    return Type::getFloatTy(Ctx);
  }
  return Type::getInt64Ty(Ctx);
}

Type *LibcSignatureDB::returnType(LLVMContext &Ctx,
                                  const LibcSignature &Sig) const {
  if (Sig.Special == LibcSpecialKind::Deallocator ||
      Sig.Special == LibcSpecialKind::NoReturn) {
    return Type::getVoidTy(Ctx);
  }
  switch (Sig.ReturnKind) {
  case LibcParamKind::Integer:
  case LibcParamKind::Char:
    return Type::getInt32Ty(Ctx);
  case LibcParamKind::SizeT:
    return Type::getInt64Ty(Ctx);
  case LibcParamKind::Pointer:
  case LibcParamKind::ConstPointer:
  case LibcParamKind::WritePointer:
  case LibcParamKind::FilePointer:
  case LibcParamKind::VoidStar:
    return PointerType::getUnqual(Ctx);
  case LibcParamKind::Double:
    return Type::getDoubleTy(Ctx);
  case LibcParamKind::Float:
    return Type::getFloatTy(Ctx);
  }
  return Type::getInt32Ty(Ctx);
}

FunctionType *LibcSignatureDB::buildFunctionType(LLVMContext &Ctx,
                                                 const LibcSignature &Sig) const {
  Type *RetTy = returnType(Ctx, Sig);
  SmallVector<Type *, 8> ParamTys;
  for (const LibcParam &P : Sig.FixedParams) {
    ParamTys.push_back(paramType(Ctx, P.Kind));
  }
  return FunctionType::get(RetTy, ParamTys, Sig.IsVarArg);
}

// --- Format string parser ---

static VarargType classifyPrintfSpec(StringRef Spec) {
  if (Spec == "%%")
    return VarargType::Percent;

  char Last = Spec.back();
  bool HasLong = false;
  bool HasLongLong = false;

  for (size_t I = 1; I < Spec.size() - 1; ++I) {
    if (Spec[I] == 'l') {
      if (I + 1 < Spec.size() - 1 && Spec[I + 1] == 'l') {
        HasLongLong = true;
        ++I;
      } else {
        HasLong = true;
      }
    }
  }

  switch (Last) {
  case 'd': case 'i':
    return (HasLongLong || HasLong) ? VarargType::IntI64 : VarargType::IntI32;
  case 'u': case 'x': case 'X': case 'o':
    return (HasLongLong || HasLong) ? VarargType::UintI64 : VarargType::UintI32;
  case 'c':
    return VarargType::CharI8;
  case 's':
    return VarargType::Pointer;
  case 'p':
    return VarargType::Pointer;
  case 'f': case 'F': case 'e': case 'E': case 'g': case 'G': case 'a':
  case 'A':
    return VarargType::Double;
  case 'n':
    return VarargType::Pointer;
  default:
    return VarargType::Unknown;
  }
}

static VarargType classifyScanfSpec(StringRef Spec) {
  if (Spec == "%%")
    return VarargType::Percent;

  char Last = Spec.back();
  bool HasLong = false;
  bool HasLongLong = false;

  for (size_t I = 1; I < Spec.size() - 1; ++I) {
    if (Spec[I] == 'l') {
      if (I + 1 < Spec.size() - 1 && Spec[I + 1] == 'l') {
        HasLongLong = true;
        ++I;
      } else {
        HasLong = true;
      }
    }
  }

  switch (Last) {
  case 'd': case 'i':
    return (HasLongLong || HasLong) ? VarargType::IntI64 : VarargType::IntI32;
  case 'u': case 'x': case 'X': case 'o':
    return (HasLongLong || HasLong) ? VarargType::UintI64 : VarargType::UintI32;
  case 'c':
    return VarargType::CharI8;
  case 's':
    return VarargType::Pointer;
  case 'p':
    return VarargType::Pointer;
  case 'f': case 'F': case 'e': case 'E': case 'g': case 'G': case 'a':
  case 'A':
    return HasLong ? VarargType::Double : VarargType::Double;
  case 'n':
    return VarargType::Pointer;
  case '[':
    return VarargType::Pointer;
  default:
    return VarargType::Unknown;
  }
}

bool parseFormatString(StringRef Fmt, SmallVectorImpl<VarargSpecifier> &Out,
                       bool IsScanfFamily) {
  Out.clear();
  size_t Pos = 0;
  size_t Len = Fmt.size();

  while (Pos < Len) {
    size_t Pct = Fmt.find('%', Pos);
    if (Pct == StringRef::npos)
      break;
    if (Pct + 1 >= Len)
      return false;
    if (Fmt[Pct + 1] == '%') {
      Pos = Pct + 2;
      continue;
    }

    size_t Start = Pct;
    size_t I = Pct + 1;

    bool Suppressed = false;
    if (IsScanfFamily) {
      if (I < Len && Fmt[I] == '*') {
        Suppressed = true;
        ++I;
      }
    } else {
      while (I < Len && (Fmt[I] == '-' || Fmt[I] == '+' || Fmt[I] == ' ' ||
                         Fmt[I] == '#' || Fmt[I] == '0'))
        ++I;
    }

    bool WidthStar = false;
    if (!IsScanfFamily && I < Len && Fmt[I] == '*') {
      WidthStar = true;
      ++I;
    } else {
      while (I < Len && std::isdigit(static_cast<unsigned char>(Fmt[I])))
        ++I;
    }

    bool PrecisionStar = false;
    if (!IsScanfFamily && I < Len && Fmt[I] == '.') {
      ++I;
      if (I < Len && Fmt[I] == '*') {
        PrecisionStar = true;
        ++I;
      } else {
        while (I < Len && std::isdigit(static_cast<unsigned char>(Fmt[I])))
          ++I;
      }
    }

    while (I < Len && (Fmt[I] == 'h' || Fmt[I] == 'l' || Fmt[I] == 'L' ||
                       Fmt[I] == 'z' || Fmt[I] == 'j' || Fmt[I] == 't' ||
                       Fmt[I] == 'q'))
      ++I;

    if (IsScanfFamily && I < Len && Fmt[I] == '[') {
      ++I;
      if (I < Len && Fmt[I] == '^') ++I;
      if (I < Len && Fmt[I] == ']') ++I;
      while (I < Len && Fmt[I] != ']') ++I;
      if (I < Len) ++I;
    } else {
      if (I >= Len)
        return false;
      ++I;
    }

    StringRef SpecStr = Fmt.substr(Start, I - Start);

    if (WidthStar) {
      VarargSpecifier WS;
      WS.Ty = VarargType::WidthStar;
      WS.Raw = SpecStr.str();
      WS.UsesGPReg = true;
      WS.UsesXMMReg = false;
      WS.ConsumesArg = true;
      Out.push_back(WS);
    }
    if (PrecisionStar) {
      VarargSpecifier PS;
      PS.Ty = VarargType::PrecisionStar;
      PS.Raw = SpecStr.str();
      PS.UsesGPReg = true;
      PS.UsesXMMReg = false;
      PS.ConsumesArg = true;
      Out.push_back(PS);
    }

    VarargType VT = IsScanfFamily ? classifyScanfSpec(SpecStr)
                                   : classifyPrintfSpec(SpecStr);
    if (VT == VarargType::Percent) {
      Pos = I;
      continue;
    }
    if (VT == VarargType::Unknown)
      return false;

    if (Suppressed) {
      VarargSpecifier VS;
      VS.Ty = VarargType::ScanfSuppressed;
      VS.Raw = SpecStr.str();
      VS.UsesGPReg = false;
      VS.UsesXMMReg = false;
      VS.ConsumesArg = false;
      Out.push_back(VS);
    } else {
      VarargSpecifier VS;
      VS.Ty = VT;
      VS.Raw = SpecStr.str();
      VS.UsesGPReg = (VT != VarargType::Double) || IsScanfFamily;
      VS.UsesXMMReg = (VT == VarargType::Double) && !IsScanfFamily;
      VS.ConsumesArg = true;
      Out.push_back(VS);
    }

    Pos = I;
  }
  return true;
}

} // namespace brighten_extern

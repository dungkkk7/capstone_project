// Strip attributes co the dan toi poison/UB.
// - Loai bo noalias/nonull/deref/no-undef
// - Ap dung cho function va call-site
#include "BrightenRepairPass.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

static bool IsLiftedInternalFunction(const Function &F) {
  // Chỉ strip attribute trên hàm internal do lifter/pipeline sinh ra.
  if (F.isDeclaration()) {
    return false;
  }
  StringRef Name = F.getName();
  return Name.starts_with("sub_") || Name.starts_with("callback_sub_") ||
         Name.starts_with("__lifter_refine_");
}

static bool StripReturnAttrs(LLVMContext &Ctx, AttributeList &Attrs) {
  // Loại bỏ nhóm return attributes có thể đẩy optimizer tới giả định quá mạnh.
  bool Changed = false;
  for (Attribute::AttrKind Kind : {
           Attribute::NoAlias,
           Attribute::NonNull,
           Attribute::Dereferenceable,
           Attribute::DereferenceableOrNull,
           Attribute::NoUndef,
       }) {
    if (Attrs.hasRetAttr(Kind)) {
      Attrs = Attrs.removeRetAttribute(Ctx, Kind);
      Changed = true;
    }
  }
  return Changed;
}

static bool StripParamAttrs(LLVMContext &Ctx, AttributeList &Attrs, unsigned ArgCount) {
  // Tương tự với parameter attributes "poison-driving".
  bool Changed = false;
  for (unsigned I = 0; I < ArgCount; ++I) {
    for (Attribute::AttrKind Kind : {
             Attribute::NoAlias,
             Attribute::NonNull,
             Attribute::Dereferenceable,
             Attribute::DereferenceableOrNull,
             Attribute::NoUndef,
             Attribute::Alignment,
         }) {
      if (Attrs.hasParamAttr(I, Kind)) {
        Attrs = Attrs.removeParamAttribute(Ctx, I, Kind);
        Changed = true;
      }
    }
  }
  return Changed;
}

bool BrightenRepairPass::StripPoisonDrivingAttributes(Module &M) {
  // Áp dụng cho cả function definition và call-site gọi tới lifted internal function.
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();

  for (Function &F : M) {
    if (!IsLiftedInternalFunction(F)) {
      continue;
    }
    AttributeList Attrs = F.getAttributes();
    bool LocalChanged = false;
    LocalChanged |= StripReturnAttrs(Ctx, Attrs);
    LocalChanged |= StripParamAttrs(Ctx, Attrs, F.arg_size());
    if (LocalChanged) {
      F.setAttributes(Attrs);
      Changed = true;
    }
  }

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || CB->isInlineAsm()) {
          continue;
        }
        Function *Callee = CB->getCalledFunction();
        if (!Callee || !IsLiftedInternalFunction(*Callee)) {
          continue;
        }

        AttributeList Attrs = CB->getAttributes();
        bool LocalChanged = false;
        LocalChanged |= StripReturnAttrs(Ctx, Attrs);
        LocalChanged |= StripParamAttrs(Ctx, Attrs, CB->arg_size());
        if (LocalChanged) {
          CB->setAttributes(Attrs);
          Changed = true;
        }
      }
    }
  }

  return Changed;
}

}  // namespace brighten_repair

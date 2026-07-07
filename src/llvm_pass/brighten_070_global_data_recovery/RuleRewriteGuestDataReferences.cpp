#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_global {

using namespace llvm;

static Value *CreateGEPToObject(IRBuilder<> &Builder, RecoveredObject *Obj,
                                 uint64_t GuestAddr) {
  if (!Obj || !Obj->GV)
    return nullptr;

  uint64_t Offset = GuestAddr - Obj->Begin;
  Type *ObjTy = Obj->GV->getValueType();

  if (Obj->Kind == ObjectKind::StringLiteral) {
    if (Offset == 0) {
      return Builder.CreateGEP(
          ObjTy, Obj->GV,
          {Builder.getInt64(0), Builder.getInt64(0)});
    }
    return Builder.CreateGEP(
        ObjTy, Obj->GV,
        {Builder.getInt64(0), Builder.getInt64(Offset)});
  }

  if (Obj->Kind == ObjectKind::Scalar) {
    if (Offset != 0)
      return nullptr;
    return Obj->GV;
  }

  if (Obj->Kind == ObjectKind::Array || Obj->Kind == ObjectKind::RawBytes) {
    auto *ArrTy = dyn_cast<ArrayType>(ObjTy);
    if (!ArrTy)
      return nullptr;
    unsigned ElemSize = Obj->GV->getParent()->getDataLayout().getTypeStoreSize(
        ArrTy->getElementType());
    if (ElemSize == 0)
      return nullptr;
    if (Offset % ElemSize != 0)
      return nullptr;
    uint64_t Idx = Offset / ElemSize;
    return Builder.CreateGEP(
        ObjTy, Obj->GV,
        {Builder.getInt64(0), Builder.getInt64(Idx)});
  }

  if (Obj->Kind == ObjectKind::PointerTable) {
    auto *ArrTy = dyn_cast<ArrayType>(ObjTy);
    if (!ArrTy)
      return nullptr;
    unsigned ElemSize = Obj->GV->getParent()->getDataLayout().getTypeStoreSize(
        ArrTy->getElementType());
    if (ElemSize == 0 || Offset % ElemSize != 0)
      return nullptr;
    uint64_t Idx = Offset / ElemSize;
    return Builder.CreateGEP(
        ObjTy, Obj->GV,
        {Builder.getInt64(0), Builder.getInt64(Idx)});
  }

  return nullptr;
}

static Constant *CreateConstantGEPToObject(RecoveredObject *Obj,
                                           uint64_t GuestAddr,
                                           Type *ExpectedTy) {
  if (!Obj || !Obj->GV)
    return nullptr;

  uint64_t Offset = GuestAddr - Obj->Begin;
  Type *ObjTy = Obj->GV->getValueType();
  LLVMContext &LCtx = Obj->GV->getContext();

  Constant *GEP = nullptr;
  if (Obj->Kind == ObjectKind::StringLiteral) {
    GEP = ConstantExpr::getGetElementPtr(
        ObjTy, Obj->GV,
        ArrayRef<Constant *>{ConstantInt::get(Type::getInt64Ty(LCtx), 0),
                             ConstantInt::get(Type::getInt64Ty(LCtx), Offset)});
  } else if (Obj->Kind == ObjectKind::Scalar) {
    if (Offset == 0)
      GEP = Obj->GV;
  } else if (Obj->Kind == ObjectKind::Array || Obj->Kind == ObjectKind::PointerTable ||
             Obj->Kind == ObjectKind::RawBytes) {
    auto *ArrTy = dyn_cast<ArrayType>(ObjTy);
    if (ArrTy) {
      unsigned ElemSize = Obj->GV->getParent()->getDataLayout().getTypeStoreSize(
          ArrTy->getElementType());
      if (ElemSize != 0 && Offset % ElemSize == 0) {
        uint64_t Idx = Offset / ElemSize;
        GEP = ConstantExpr::getGetElementPtr(
            ObjTy, Obj->GV,
            ArrayRef<Constant *>{ConstantInt::get(Type::getInt64Ty(LCtx), 0),
                                 ConstantInt::get(Type::getInt64Ty(LCtx), Idx)});
      }
    }
  }

  if (GEP && GEP->getType() != ExpectedTy) {
    if (ExpectedTy->isPointerTy())
      GEP = ConstantExpr::getBitCast(GEP, ExpectedTy);
    else if (ExpectedTy->isIntegerTy())
      GEP = ConstantExpr::getPtrToInt(GEP, ExpectedTy);
  }
  return GEP;
}

static bool IsAddressIdentitySensitive(GuestAddressRef *Ref) {
  if (!Ref->UserInst)
    return false;
  // In NativeStrict, only treat ICmp (comparison) as identity sensitive.
  // Arithmetic (like ptrtoint used in xor/add) is safe to rewrite because
  // we just map the pointer value to the new global.
  if (Ref->ConsumerKind == DataConsumerKind::ComparisonOnly)
    return true;
  return false;
}

bool BrightenGlobalDataRecoveryPass::RewriteGuestDataReferences(
    GlobalDataContext &Ctx) {
  unsigned Count = 0;

  // 1. Constant Address Refs (including new raw byte locations)
  for (auto &Ref : Ctx.AddressRefs) {
    if (Ref->Rewritten)
      continue;
    if (Ref->SkipReason.size() > 0) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }
    if (!Ref->Segment || !Ref->Segment->BaseResolved) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    // Address identity sensitive check in NativeStrict mode
    if (Ctx.Mode == DataRecoveryMode::NativeStrict &&
        IsAddressIdentitySensitive(Ref.get())) {
      Ref->SkipReason = "address-identity-observable";
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    auto It = Ctx.RecoveredObjects.upper_bound(Ref->GuestAddr);
    RecoveredObject *Obj = nullptr;
    if (It != Ctx.RecoveredObjects.begin()) {
      --It;
      if (Ref->GuestAddr >= It->second->Begin &&
          Ref->GuestAddr < It->second->End)
        Obj = It->second.get();
    }

    if (!Obj) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    Instruction *UserInst = Ref->UserInst;
    if (!UserInst) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    Value *OrigVal = Ref->OriginalValue;
    if (!OrigVal) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    bool LocalRewritten = false;
    if (auto *CE = dyn_cast<ConstantExpr>(OrigVal)) {
      Constant *NewConst = CreateConstantGEPToObject(Obj, Ref->GuestAddr, CE->getType());
      if (NewConst) {
        UserInst->replaceUsesOfWith(CE, NewConst);
        Ref->Rewritten = true;
        LocalRewritten = true;
        ++Count;
      }
    }

    if (!LocalRewritten) {
      IRBuilder<> Builder(UserInst);
      Value *NewPtr = CreateGEPToObject(Builder, Obj, Ref->GuestAddr);
      if (NewPtr) {
        Type *ExpectedTy = OrigVal->getType();
        bool TypeOk = true;
        if (NewPtr->getType() != ExpectedTy) {
          if (ExpectedTy->isPointerTy())
            NewPtr = Builder.CreateBitCast(NewPtr, ExpectedTy);
          else if (ExpectedTy->isIntegerTy())
            NewPtr = Builder.CreatePtrToInt(NewPtr, ExpectedTy);
          else
            TypeOk = false;
        }

        if (TypeOk) {
          UserInst->replaceUsesOfWith(OrigVal, NewPtr);
          Ref->Rewritten = true;
          LocalRewritten = true;
          ++Count;
        }
      }
    }

    if (!Ref->Rewritten) {
      ++Ctx.Report.PreservedRefs;
    }
  }

  // 2. Rewrite dynamic users of segment globals to point to appropriate recovered or raw-byte objects
  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV || !Seg->BaseResolved)
      continue;

    const RecoveredObject *Obj = Ctx.findObjectAt(Seg->GuestBase);
    if (!Obj || !Obj->GV)
      continue;

    SmallVector<User *, 8> Users(Seg->GV->users());
    for (User *U : Users) {
      if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
        Value *Idx = nullptr;
        uint64_t BaseOffset = 0;
        if (GEP->getNumIndices() == 1) {
          Idx = GEP->getOperand(1);
        } else if (GEP->getNumIndices() >= 2) {
          Idx = GEP->getOperand(2);
          if (auto *ConstFirst = dyn_cast<ConstantInt>(GEP->getOperand(1))) {
            // usually 0
          }
        }

        if (Idx && !isa<ConstantInt>(Idx)) {
          uint64_t GuestAddr = Seg->GuestBase + BaseOffset;
          const RecoveredObject *Obj = Ctx.findObjectAt(GuestAddr);
          if (Obj && Obj->GV && (Obj->End - Obj->Begin == Seg->Size)) {
            IRBuilder<> Builder(GEP);
            Value *NewBase = Obj->GV;
            if (NewBase->getType() != GEP->getPointerOperand()->getType()) {
              NewBase = Builder.CreateBitCast(NewBase, GEP->getPointerOperand()->getType());
            }
            GEP->setOperand(0, NewBase);
            ++Count;
          }
        }
      }
    }
  }

  Ctx.Report.DataRefsRewritten = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-global-data] rewritten " << Count
           << " data references\n";

  return Count > 0;
}



bool BrightenGlobalDataRecoveryPass::RewriteGuestPointerTranslatorCalls(
    GlobalDataContext &Ctx) {
  Module &M = Ctx.M;
  Function *TranslateFn = M.getFunction("__translate_guest_pointer");
  if (!TranslateFn)
    return false;

  bool Changed = false;
  unsigned TranslatorCount = 0;
  SmallVector<CallInst *, 64> Calls;
  for (User *U : TranslateFn->users()) {
    if (auto *CI = dyn_cast<CallInst>(U)) {
      if (CI->getCalledFunction() == TranslateFn) {
        Calls.push_back(CI);
      }
    }
  }

  for (CallInst *CI : Calls) {
    Value *AddrVal = CI->getArgOperand(0);

    // Case 1: Constant address
    if (auto *CI_Addr = dyn_cast<ConstantInt>(AddrVal)) {
      uint64_t Addr = CI_Addr->getZExtValue();
      const RecoveredObject *Obj = Ctx.findObjectAt(Addr);
      if (Obj && Obj->GV) {
        IRBuilder<> Builder(CI);
        Value *NewPtr = CreateGEPToObject(Builder, const_cast<RecoveredObject *>(Obj), Addr);
        if (NewPtr) {
          if (NewPtr->getType() != CI->getType()) {
            NewPtr = Builder.CreateBitCast(NewPtr, CI->getType());
          }
          CI->replaceAllUsesWith(NewPtr);
          CI->eraseFromParent();
          Changed = true;
          ++TranslatorCount;
          continue;
        }
      }
    }
  }

  if (TranslatorCount > 0) {
    Ctx.Report.DataRefsRewritten += TranslatorCount;
  }



  return Changed;
}

} // namespace brighten_global

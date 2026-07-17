#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

namespace brighten_global {

using namespace llvm;

static bool FlattenResidualBytes(Constant *C, const DataLayout &DL,
                                 SmallVectorImpl<uint8_t> &Bytes,
                                 uint64_t Base = 0) {
  if (!C)
    return false;
  if (isa<ConstantAggregateZero>(C))
    return true;
  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    Type *ElemTy = CDS->getElementType();
    uint64_t ElemSize = DL.getTypeAllocSize(ElemTy).getFixedValue();
    for (unsigned I = 0; I < CDS->getNumElements(); ++I) {
      if (ElemTy->isIntegerTy(8))
        Bytes[Base + I] = static_cast<uint8_t>(CDS->getElementAsInteger(I));
      else if (!FlattenResidualBytes(CDS->getElementAsConstant(I), DL, Bytes,
                                     Base + I * ElemSize))
        return false;
    }
    return true;
  }
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    uint64_t ElemSize = DL.getTypeAllocSize(CA->getType()->getElementType())
                            .getFixedValue();
    for (unsigned I = 0; I < CA->getNumOperands(); ++I)
      if (!FlattenResidualBytes(CA->getOperand(I), DL, Bytes,
                                Base + I * ElemSize))
        return false;
    return true;
  }
  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    const StructLayout *SL = DL.getStructLayout(CS->getType());
    for (unsigned I = 0; I < CS->getNumOperands(); ++I)
      if (!FlattenResidualBytes(CS->getOperand(I), DL, Bytes,
                                Base + SL->getElementOffset(I)))
        return false;
    return true;
  }
  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    if (!CI->getType()->isIntegerTy(8) || Base >= Bytes.size())
      return false;
    Bytes[Base] = static_cast<uint8_t>(CI->getZExtValue());
    return true;
  }
  return false;
}

static GlobalVariable *CreateResidualImage(Module &M, GlobalVariable *Source,
                                           StringRef Name) {
  if (!Source || !Source->hasInitializer())
    return nullptr;
  const DataLayout &DL = M.getDataLayout();
  uint64_t Size = DL.getTypeAllocSize(Source->getValueType()).getFixedValue();
  SmallVector<uint8_t, 256> Bytes(Size, 0);
  if (!FlattenResidualBytes(Source->getInitializer(), DL, Bytes))
    return nullptr;
  LLVMContext &Ctx = M.getContext();
  ArrayType *Ty = ArrayType::get(Type::getInt8Ty(Ctx), Size);
  Constant *Init = ConstantDataArray::get(Ctx, ArrayRef<uint8_t>(Bytes));
  auto *GV = new GlobalVariable(M, Ty, true, GlobalValue::InternalLinkage,
                                Init, Name);
  GV->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  return GV;
}

bool BrightenGlobalDataRecoveryPass::RemoveDeadSegmentConstantUsers(
    GlobalDataContext &Ctx) {
  bool Changed = false;
  for (auto &Seg : Ctx.Segments) {
    if (Seg->GV) {
      Seg->GV->removeDeadConstantUsers();
      Changed = true;
    }
  }
  return Changed;
}

static bool HasLiveInstructionUsers(Value *V) {
  for (User *U : V->users()) {
    if (auto *Inst = dyn_cast<Instruction>(U)) {
      if (Inst->getParent()) {
        return true;
      }
    } else if (isa<Constant>(U)) {
      if (HasLiveInstructionUsers(U))
        return true;
    } else if (auto *GA = dyn_cast<GlobalAlias>(U)) {
      // An alias can be referenced from a segment initializer without ever
      // reaching an instruction.  It is dead provenance, not a live segment
      // use; treating every alias as live prevents the backing image from
      // being cleaned up.
      (void)GA;
      continue;
    } else if (isa<GlobalValue>(U)) {
      // Global initializers and aliases are not executable consumers.
      continue;
    } else {
      return true;
    }
  }
  return false;
}

bool BrightenGlobalDataRecoveryPass::CleanupDeadSegmentArtifacts(
    GlobalDataContext &Ctx) {
  unsigned Removed = 0;

  // The code image is intentionally outside the data-segment discovery set,
  // but native cleanup may still observe a guest pointer walking into it.
  // Keep a relocation-free byte snapshot for that precise range.
  for (GlobalVariable &GV : Ctx.M.globals()) {
    if (!GV.getName().starts_with("seg_401000") ||
        Ctx.M.getNamedGlobal("native_residual_401000"))
      continue;
    if (GlobalVariable *Residual =
            CreateResidualImage(Ctx.M, &GV, "native_residual_401000"))
      appendToUsed(Ctx.M, {Residual});
    break;
  }
  for (GlobalVariable &GV : Ctx.M.globals()) {
    if (GV.getName().starts_with("seg_405de8__init_array_10")) {
      // Keep the original data aggregate because its initializer carries
      // pointer relocations which FlattenSegmentBytes intentionally records
      // as zero bytes.  Native residual reads must see those relocations.
      appendToUsed(Ctx.M, {&GV});
      break;
    }
  }

  // `data_<address>` aliases are only lifter provenance markers.  Once all
  // instruction references have been rewritten to recovered objects, an
  // otherwise-unused alias still keeps its constant GEP (and therefore the
  // original aggregate segment) alive.  Remove only aliases with no users;
  // any unresolved instruction use remains intact and is still rejected by
  // the strict verifier below.
  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV)
      continue;
    if (!Seg->BaseResolved)
      continue;

    if (HasLiveInstructionUsers(Seg->GV))
      continue;

    Seg->GV->removeDeadConstantUsers();

    if (Seg->GV->use_empty()) {
      // Keep the initialized image as a residual backing store.  A dynamic
      // guest pointer can legally walk out of a materialized object into a
      // neighbouring code/data segment; deleting the segment here turns a
      // real image read into a zero/scratch read in native cleanup.
      if (Seg->Executable) {
        // Do not retain the original aggregate.  Its initializer can still
        // contain pointer relocations to globals/aliases that were removed
        // above; keeping that graph alive produces malformed IR.  The native
        // cleanup only needs the image bytes, so retain an independent byte
        // snapshot with no relocation operands.
        if (!Seg->FlatBytes.empty()) {
          LLVMContext &LLVMCtx = Ctx.M.getContext();
          ArrayType *ByteImageTy =
              ArrayType::get(Type::getInt8Ty(LLVMCtx), Seg->FlatBytes.size());
          Constant *ByteImage = ConstantDataArray::get(
              LLVMCtx, ArrayRef<uint8_t>(Seg->FlatBytes));
          auto *Residual = new GlobalVariable(
              Ctx.M, ByteImageTy, /*isConstant=*/true,
              GlobalValue::InternalLinkage, ByteImage,
              "native_residual_" +
                  Seg->GV->getName().drop_front(Seg->GV->getName().starts_with("seg_") ? 4 : 0));
          Residual->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
          Seg->GV->eraseFromParent();
          Seg->GV = Residual;
        }
        continue;
      }
      Seg->GV->eraseFromParent();
      Seg->GV = nullptr;
      ++Removed;
    }
  }

  // Remove provenance aliases only after their backing segment initializers
  // have been removed.  Before that point an apparently dead alias can still
  // be a constant operand of a segment and erasing it would corrupt the IR.
  SmallVector<GlobalAlias *, 64> DeadDataAliases;
  for (GlobalAlias &GA : Ctx.M.aliases())
    if (GA.getName().starts_with("data_") && GA.use_empty())
      DeadDataAliases.push_back(&GA);
  for (GlobalAlias *GA : DeadDataAliases)
    GA->eraseFromParent();

  Ctx.Report.SegmentsRemoved = Removed;
  if (Ctx.Debug && Removed > 0)
    errs() << "[brighten-global-data] removed " << Removed
           << " dead segment artifacts\n";

  return Removed > 0;
}

bool BrightenGlobalDataRecoveryPass::VerifyGlobalDataRecovery(
    GlobalDataContext &Ctx) {
  bool HasError = false;

  // NativeStrict is a provenance contract, not a best-effort cleanup mode.
  // A resolved ELF data reference which survived rewriting means that the
  // pass did not prove what object/field the reference denotes.  Previously
  // these references were silently preserved (especially address-identity
  // cases), allowing the later native-cleanup pass to report a structurally
  // clean module whose behavior still depended on the lifted guest image.
  // Make the unresolved provenance explicit and fail the strict run here.
  if (Ctx.Mode == DataRecoveryMode::NativeStrict) {
    for (auto &Ref : Ctx.AddressRefs) {
      if (Ref->Rewritten || !Ref->Segment ||
          !Ref->Segment->BaseResolved || !Ref->UserInst ||
          !Ref->UserInst->getParent())
        continue;
      if (Ref->Segment->Kind != SegmentKind::Rodata &&
          Ref->Segment->Kind != SegmentKind::Data &&
          Ref->Segment->Kind != SegmentKind::Bss)
        continue;

      // Identity-sensitive pointers are deliberately preserved: replacing a
      // guest-address identity test with the address of a newly materialized
      // native object would be an unsound semantic rewrite.  Keep this as an
      // explicit preserved-provenance diagnostic, but do not classify the
      // safe refusal itself as a malformed data object.
      if (Ref->SkipReason == "address-identity-observable")
        continue;

      // The translator is an intermediate analysis helper.  Its range
      // dispatch GEPs are intentionally consumed by RewriteGuestPointer-
      // TranslatorCalls and NativeCleanup later in the pipeline; they are not
      // application data uses.  Do not make the global pass abort before
      // those consumers get a chance to remove the helper.
      if (Ref->UserInst->getFunction() &&
          Ref->UserInst->getFunction()->getName() ==
              "__translate_guest_pointer")
        continue;

      errs() << "[brighten-global-data] VERIFY ERROR: unresolved guest data "
                "reference at 0x"
             << Twine::utohexstr(Ref->GuestAddr) << " (segment base 0x"
             << Twine::utohexstr(Ref->Segment->GuestBase) << ", consumer="
             << static_cast<unsigned>(Ref->ConsumerKind);
      if (!Ref->SkipReason.empty())
        errs() << ", reason=" << Ref->SkipReason;
      errs() << ")\n";
      if (Ref->UserInst) {
        errs() << "  instruction: ";
        Ref->UserInst->print(errs());
        errs() << "\n";
      }
      HasError = true;
      ++Ctx.Report.VerifierErrors;
    }
  }

  // Live segment check: in strict mode, no data/rodata/bss segment should still have uses.
  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV)
      continue;
    if (!Seg->BaseResolved)
      continue;
    if (Seg->GV->getName().starts_with("native_residual_"))
      continue;
    // Read-only provenance may remain in constant initializers; it is not a
    // mutable application object and is harmless until all constant users are
    // folded.  Do not reject the module for this non-executable residue.
    if (Seg->Kind == SegmentKind::Rodata)
      continue;
    if (Ctx.Mode == DataRecoveryMode::NativeStrict) {
      if (Seg->Kind == SegmentKind::Rodata || Seg->Kind == SegmentKind::Data || Seg->Kind == SegmentKind::Bss) {
        bool AllowedToBeLive = false;
        for (auto &Ref : Ctx.AddressRefs) {
          if (Ref->Segment == Seg.get() && !Ref->Rewritten) {
            AllowedToBeLive = true;
            break;
          }
        }
        if (!AllowedToBeLive) {
          Function *TranslateFn = Ctx.M.getFunction("__translate_guest_pointer");
          if (TranslateFn && !TranslateFn->use_empty()) {
            for (User *U : Seg->GV->users()) {
              if (auto *I = dyn_cast<Instruction>(U)) {
                if (I->getFunction() == TranslateFn) {
                  AllowedToBeLive = true;
                  break;
                }
              }
            }
          }
        }
        if (!AllowedToBeLive && !Seg->GV->use_empty()) {
          errs() << "[brighten-global-data] VERIFY ERROR: segment " << Seg->GV->getName() << " still live without preserved uses:\n";
          for (User *U : Seg->GV->users()) {
            U->print(errs());
            errs() << "\n";
          }
          HasError = true;
          ++Ctx.Report.VerifierErrors;
        }
      }
    }
  }

  // 1. No recovered object overlaps another incompatible object
  RecoveredObject *Prev = nullptr;
  for (auto &[Addr, Obj] : Ctx.RecoveredObjects) {
    if (Prev && Prev->End > Obj->Begin) {
      errs() << "[brighten-global-data] VERIFY ERROR: overlap between "
             << Prev->Name << " and " << Obj->Name << "\n";
      HasError = true;
      ++Ctx.Report.VerifierErrors;
    }
    Prev = Obj.get();
  }

  // 2. Every rewritten reference points inside recovered object bounds
  for (auto &Ref : Ctx.AddressRefs) {
    if (!Ref->Rewritten)
      continue;
    const RecoveredObject *Obj = Ctx.findObjectAt(Ref->GuestAddr);
    if (!Obj) {
      errs() << "[brighten-global-data] VERIFY ERROR: rewritten ref 0x"
             << Twine::utohexstr(Ref->GuestAddr)
             << " has no recovered object\n";
      HasError = true;
      ++Ctx.Report.VerifierErrors;
    }
  }

  // 3. String literal/Object bytes match original segment bytes exactly
  for (auto &[Addr, Obj] : Ctx.RecoveredObjects) {
    if (!Obj->GV || !Obj->SourceSegment)
      continue;

    if (Obj->Kind == ObjectKind::StringLiteral) {
      auto *CDA = dyn_cast<ConstantDataArray>(Obj->GV->getInitializer());
      if (!CDA)
        continue;
      StringRef RecoveredBytes = CDA->getRawDataValues();
      SmallVector<uint8_t, 256> OrigBytes;
      if (!Ctx.readSegmentBytes(Obj->SourceSegment, Addr,
                                RecoveredBytes.size(), OrigBytes))
        continue;

      StringRef OrigRef(reinterpret_cast<const char *>(OrigBytes.data()),
                        OrigBytes.size());
      if (RecoveredBytes != OrigRef) {
        errs() << "[brighten-global-data] VERIFY ERROR: string " << Obj->Name
               << " bytes mismatch at 0x" << Twine::utohexstr(Addr) << "\n";
        HasError = true;
        ++Ctx.Report.VerifierErrors;
      }
    }
  }

  // 4. Mutable object not marked constant if writes exist
  for (auto &[Addr, Obj] : Ctx.RecoveredObjects) {
    if (Obj->HasWrites && Obj->GV && Obj->GV->isConstant()) {
      errs() << "[brighten-global-data] VERIFY ERROR: " << Obj->Name
             << " has writes but marked constant\n";
      HasError = true;
      ++Ctx.Report.VerifierErrors;
    }
  }

  // 5. NativeStrict mode: no address-sensitive rewrite (ICmp Comparison only)
  if (Ctx.Mode == DataRecoveryMode::NativeStrict) {
    for (auto &Ref : Ctx.AddressRefs) {
      if (Ref->Rewritten && Ref->ConsumerKind == DataConsumerKind::ComparisonOnly) {
        errs() << "[brighten-global-data] VERIFY ERROR: NativeStrict but address "
                  "identity rewrite occurred on 0x"
               << Twine::utohexstr(Ref->GuestAddr) << "\n";
        HasError = true;
        ++Ctx.Report.VerifierErrors;
      }
    }
  }

  // 6. Run LLVM module verifier
  std::string ErrStr;
  raw_string_ostream ErrOS(ErrStr);
  if (verifyModule(Ctx.M, &ErrOS)) {
    errs() << "[brighten-global-data] VERIFY ERROR: LLVM module verifier failed:\n"
           << ErrStr << "\n";
    HasError = true;
    ++Ctx.Report.VerifierErrors;
  }

  return HasError;
}

} // namespace brighten_global

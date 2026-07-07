#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_global {

using namespace llvm;

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

bool BrightenGlobalDataRecoveryPass::CleanupDeadSegmentArtifacts(
    GlobalDataContext &Ctx) {
  unsigned Removed = 0;

  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV)
      continue;
    if (!Seg->BaseResolved)
      continue;

    bool AllUsesRewritten = true;
    for (User *U : Seg->GV->users()) {
      if (auto *Inst = dyn_cast<Instruction>(U)) {
        if (Inst->getParent())
          AllUsesRewritten = false;
      } else if (auto *CE = dyn_cast<ConstantExpr>(U)) {
        for (User *CEU : CE->users()) {
          if (auto *Inst = dyn_cast<Instruction>(CEU)) {
            if (Inst->getParent())
              AllUsesRewritten = false;
          }
        }
      } else {
        AllUsesRewritten = false;
      }
    }

    if (!AllUsesRewritten)
      continue;

    if (Seg->GV->use_empty()) {
      Seg->GV->eraseFromParent();
      Seg->GV = nullptr;
      ++Removed;
    }
  }

  Ctx.Report.SegmentsRemoved = Removed;
  if (Ctx.Debug && Removed > 0)
    errs() << "[brighten-global-data] removed " << Removed
           << " dead segment artifacts\n";

  return Removed > 0;
}

bool BrightenGlobalDataRecoveryPass::VerifyGlobalDataRecovery(
    GlobalDataContext &Ctx) {
  bool HasError = false;

  // Live segment check: in strict mode, no data/rodata/bss segment should still have uses.
  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV)
      continue;
    if (!Seg->BaseResolved)
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

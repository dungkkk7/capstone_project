#include "BrightenExternCallBridgePass.h"

#include "llvm/Support/raw_ostream.h"

namespace brighten_extern {

using namespace llvm;

bool BrightenExternCallBridgePass::PrintExternalCallRecoveryReport(
    ExternCallContext &Ctx) {
  // Count preserved
  unsigned Preserved = 0;
  for (auto &CS : Ctx.Callsites) {
    if (!CS->Rewritten)
      ++Preserved;
  }
  Ctx.Report.Preserved = Preserved;

  errs() << "brighten-extern-call-bridge report:\n"
         << "  External callsites discovered: " << Ctx.Report.Discovered << "\n"
         << "  Rewritten native calls: " << Ctx.Report.RewrittenNative << "\n"
         << "  Rewritten compat fallback calls: " << Ctx.Report.RewrittenCompat
         << "\n"
         << "  Preserved callsites: " << Ctx.Report.Preserved << "\n"
         << "  Vararg calls recovered: " << Ctx.Report.VarargRecovered << "\n"
         << "  Format strings recovered: "
         << Ctx.Report.FormatStringsRecovered << "\n"
         << "  Pointer args native: " << Ctx.Report.PointerArgsNative << "\n"
         << "  Pointer args fallback-translated: "
         << Ctx.Report.PointerArgsFallback << "\n"
         << "  Verifier errors: " << Ctx.Report.VerifierErrors << "\n"
         << "  Detail:\n";

  for (auto &CS : Ctx.Callsites) {
    errs() << "    caller=" << CS->Caller->getName()
           << " target=" << CS->Target.SymbolName;
    if (CS->Rewritten) {
      errs() << " action=" << CS->Action << " args=" << CS->Args.size();
      if (CS->Target.Signature) {
        Type *RetTy =
            Ctx.SigDB.returnType(Ctx.M.getContext(), *CS->Target.Signature);
        std::string RetStr;
        raw_string_ostream ROS(RetStr);
        RetTy->print(ROS);
        errs() << " ret=" << RetStr;
      }
    } else {
      errs() << " action=preserve";
      if (!CS->SkipReason.empty())
        errs() << " reason=" << CS->SkipReason;
    }
    errs() << "\n";
  }

  return false;
}

} // namespace brighten_extern

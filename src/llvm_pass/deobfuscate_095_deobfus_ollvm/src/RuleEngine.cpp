#include "RuleEngine.h"
#include "RuleEngineInternal.h"

#include <algorithm>

namespace deobfuscate095 {

bool RuleEngine::run(llvm::Module &M, unsigned MaxRounds,
                     RuleEngineStats &Stats) const {
  bool AnyChanged = false;
  const unsigned Limit = std::max(1u, MaxRounds);

  for (unsigned Round = 0; Round < Limit; ++Round) {
    bool Changed = false;
    Changed |= rule_detail::applyLogicalNotRules(M, Stats);
    Changed |= rule_detail::applyJumpRules(M, Stats);
    Changed |= rule_detail::applyPredicateRules(M, Stats);
    if (EnableMBA)
      Changed |= rule_detail::applyMBARules(M, Stats);
    Changed |= rule_detail::foldConstantControl(M, Stats);
    ++Stats.Rounds;
    AnyChanged |= Changed;
    if (!Changed)
      break;
  }
  return AnyChanged;
}

} // namespace deobfuscate095

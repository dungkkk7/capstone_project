#include "BrightenDevirtPass.h"

#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

// Dynamic PC dispatch is intentionally left intact in semantic-core-v2 until
// its selector and all target signatures can be proved together.  The previous
// implementation synthesized a switch from a bounded name/value walk and could
// silently lose target states outside that walk.  Constant PC transfers are
// still lowered by the direct call/jump rules; finite dynamic targets remain on
// the original Remill dispatcher instead of being guessed.
bool LowerFiniteRemillPCSwitch(Module &, CallInst *, Function *, bool) {
  return false;
}

} // namespace brighten_devirt

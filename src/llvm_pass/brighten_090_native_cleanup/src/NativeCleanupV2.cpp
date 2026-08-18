#include "NativeCleanup.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"

using namespace llvm;
namespace brighten_native_cleanup {
namespace {
static cl::opt<bool> Strict("brighten-native-strict", cl::init(false));

static bool lifterName(StringRef N) {
  return N.starts_with("__remill_") || N.starts_with("__mcsema_") ||
         N.starts_with("__lifter_") || N == "__translate_guest_pointer" ||
         N.starts_with("__translate_guest_pointer.");
}
static bool regName(StringRef N) {
  static constexpr StringLiteral P[] = {"RAX_","RBX_","RCX_","RDX_","RSI_","RDI_","RSP_","RBP_","RIP_","XMM","ZF_","CF_","OF_","SF_","PF_","AF_","DF_"};
  for (StringRef X : P) if (N.starts_with(X)) return true;
  return false;
}
static bool liftedSig(const Function &F) {
  if (F.arg_size()!=3 || !F.getReturnType()->isPointerTy()) return false;
  auto I=F.arg_begin(); Type *A=(I++)->getType(), *B=(I++)->getType(), *C=(I++)->getType();
  return A->isPointerTy() && B->isIntegerTy(64) && C->isPointerTy();
}
static bool prune(Module &M) {
  bool Any=false, Again=true;
  while (Again) {
    Again=false;
    SmallVector<GlobalAlias*,16> As;
    for (GlobalAlias &A:M.aliases()) if (A.use_empty()&&(lifterName(A.getName())||regName(A.getName()))) As.push_back(&A);
    for (auto *A:As) { A->eraseFromParent(); Again=Any=true; }
    SmallVector<GlobalVariable*,32> Gs;
    for (GlobalVariable &G:M.globals()) if (G.use_empty()&&(lifterName(G.getName())||regName(G.getName())||G.getName()=="__mcsema_reg_state")) Gs.push_back(&G);
    for (auto *G:Gs) { G->eraseFromParent(); Again=Any=true; }
    SmallVector<Function*,32> Fs;
    for (Function &F:M) if (F.use_empty()&&(lifterName(F.getName())||(F.hasLocalLinkage()&&liftedSig(F)))) Fs.push_back(&F);
    for (auto *F:Fs) { F->eraseFromParent(); Again=Any=true; }
  }
  return Any;
}
static bool localCleanup(Module &M) {
  bool C=false;
  for (Function &F:M) if (!F.isDeclaration()) {
    C |= removeUnreachableBlocks(F);
    SmallVector<Instruction*,32> D;
    for (Instruction &I:instructions(F)) if (isInstructionTriviallyDead(&I)) D.push_back(&I);
    for (Instruction *I:D) if (I->getParent()&&isInstructionTriviallyDead(I)) { RecursivelyDeleteTriviallyDeadInstructions(I); C=true; }
  }
  return C;
}
static SmallVector<std::string,16> violations(Module &M) {
  SmallVector<std::string,16> V;
  for (Function &F:M) {
    if (lifterName(F.getName()) || (!F.isDeclaration()&&liftedSig(F))) V.push_back((Twine("function @")+F.getName()).str());
    for (Instruction &I:instructions(F)) if (auto *CB=dyn_cast<CallBase>(&I)) if (Function *C=CB->getCalledFunction(); C&&lifterName(C->getName())) V.push_back((Twine("call @")+C->getName()+" in @"+F.getName()).str());
  }
  for (GlobalVariable &G:M.globals()) if (G.getName()=="__mcsema_reg_state"||lifterName(G.getName())||regName(G.getName())) V.push_back((Twine("global @")+G.getName()).str());
  for (GlobalAlias &A:M.aliases()) if (lifterName(A.getName())||regName(A.getName())) V.push_back((Twine("alias @")+A.getName()).str());
  for (StructType *S:M.getIdentifiedStructTypes()) if (S->hasName()&&(S->getName()=="struct.State"||S->getName().contains("remill")||S->getName().contains("mcsema"))) V.push_back((Twine("type %")+S->getName()).str());
  return V;
}
static void verify(Module &M, bool Enforce) {
  std::string E; raw_string_ostream OS(E); if (verifyModule(M,&OS)) report_fatal_error(Twine("090 invalid IR:\n")+OS.str());
  auto V=violations(M); errs()<<"brighten-native-cleanup report:\n  native contract violations: "<<V.size()<<"\n";
  for (auto &X:V) errs()<<"  native contract finding: "<<X<<"\n";
  if ((Enforce||Strict)&&!V.empty()) report_fatal_error("090 strict clean contract failed: residual lifted semantics remain");
}
}
bool NativeCleanupPass::cleanupModule(Module &M,bool EnforceStrict,bool) { bool C=localCleanup(M); C|=prune(M); verify(M,EnforceStrict); return C; }
bool NativeCleanupPass::finalizeCompactedFrames(Module &M) { bool C=localCleanup(M); C|=prune(M); verify(M,false); return C; }
} // namespace brighten_native_cleanup

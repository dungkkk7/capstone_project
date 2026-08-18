#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/Compiler.h"

#include <cstdint>

using namespace llvm;

namespace {

static uint32_t stableSeed(StringRef Name) {
  uint32_t Value = 2166136261u;
  for (unsigned char Byte : Name.bytes()) {
    Value ^= Byte;
    Value *= 16777619u;
  }
  return Value | 1u;
}

class InstructionSubstitutionPass
    : public PassInfoMixin<InstructionSubstitutionPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    SmallVector<BinaryOperator *, 64> Work;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO || !BO->getType()->isIntegerTy())
          continue;
        if (BO->getOpcode() == Instruction::Add ||
            BO->getOpcode() == Instruction::Sub ||
            BO->getOpcode() == Instruction::Xor)
          Work.push_back(BO);
      }
    }

    bool Changed = false;
    for (BinaryOperator *BO : Work) {
      IRBuilder<> B(BO);
      Value *A = BO->getOperand(0);
      Value *C = BO->getOperand(1);
      Value *Replacement = nullptr;
      if (BO->getOpcode() == Instruction::Add) {
        Value *Carry = B.CreateAnd(A, C, "own.instsub.carry");
        Value *Sum = B.CreateXor(A, C, "own.instsub.sum");
        Replacement = B.CreateAdd(
            Sum, B.CreateShl(Carry, ConstantInt::get(BO->getType(), 1),
                             "own.instsub.shift"),
            "own.instsub.add");
      } else if (BO->getOpcode() == Instruction::Sub) {
        Value *Neg = B.CreateAdd(
            B.CreateNot(C, "own.instsub.not"),
            ConstantInt::get(BO->getType(), 1), "own.instsub.neg");
        Replacement = B.CreateAdd(A, Neg, "own.instsub.sub");
      } else {
        Value *Either = B.CreateOr(A, C, "own.instsub.or");
        Value *Both = B.CreateAnd(A, C, "own.instsub.and");
        Replacement =
            B.CreateAnd(Either, B.CreateNot(Both, "own.instsub.notand"),
                        "own.instsub.xor");
      }
      BO->replaceAllUsesWith(Replacement);
      BO->eraseFromParent();
      Changed = true;
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

class ControlFlowFlatteningPass
    : public PassInfoMixin<ControlFlowFlatteningPass> {
  static Value *stateForTerminator(
      Instruction *Term, IRBuilder<> &B,
      const DenseMap<BasicBlock *, uint32_t> &StateByBlock) {
    auto StateOf = [&](BasicBlock *Target) -> ConstantInt * {
      auto It = StateByBlock.find(Target);
      if (It == StateByBlock.end())
        return nullptr;
      return B.getInt32(It->second);
    };

    if (auto *Branch = dyn_cast<BranchInst>(Term)) {
      if (Branch->isUnconditional())
        return StateOf(Branch->getSuccessor(0));
      ConstantInt *TrueState = StateOf(Branch->getSuccessor(0));
      ConstantInt *FalseState = StateOf(Branch->getSuccessor(1));
      if (!TrueState || !FalseState)
        return nullptr;
      return B.CreateSelect(Branch->getCondition(), TrueState, FalseState,
                            "own.fla.next");
    }

    auto *Switch = dyn_cast<SwitchInst>(Term);
    if (!Switch)
      return nullptr;
    Value *Next = StateOf(Switch->getDefaultDest());
    if (!Next)
      return nullptr;
    for (auto Case = Switch->case_begin(), End = Switch->case_end(); Case != End;
         ++Case) {
      ConstantInt *CaseState = StateOf(Case->getCaseSuccessor());
      if (!CaseState)
        return nullptr;
      Value *Match = B.CreateICmpEQ(Switch->getCondition(), Case->getCaseValue(),
                                    "own.fla.case.match");
      Next = B.CreateSelect(Match, CaseState, Next, "own.fla.case.next");
    }
    return Next;
  }

public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || F.size() < 3)
      return PreservedAnalyses::all();

    BasicBlock &Entry = F.getEntryBlock();
    SmallVector<BasicBlock *, 32> Blocks;
    for (BasicBlock &BB : F) {
      if (&BB == &Entry)
        continue;
      if (BB.hasAddressTaken() || BB.isEHPad() || !BB.phis().empty())
        return PreservedAnalyses::all();
      Instruction *Term = BB.getTerminator();
      if (!isa<BranchInst>(Term) && !isa<SwitchInst>(Term) &&
          !isa<ReturnInst>(Term) && !isa<UnreachableInst>(Term))
        return PreservedAnalyses::all();
      for (BasicBlock *Successor : successors(&BB))
        if (Successor == &Entry)
          return PreservedAnalyses::all();
      Blocks.push_back(&BB);
    }

    Instruction *EntryTerm = Entry.getTerminator();
    if (!isa<BranchInst>(EntryTerm) && !isa<SwitchInst>(EntryTerm))
      return PreservedAnalyses::all();

    DenseMap<BasicBlock *, uint32_t> StateByBlock;
    uint32_t Seed = stableSeed(F.getName());
    for (size_t Index = 0; Index < Blocks.size(); ++Index)
      StateByBlock[Blocks[Index]] = Seed + static_cast<uint32_t>(Index * 0x101u);

    IRBuilder<> EntryAlloca(&*Entry.getFirstInsertionPt());
    AllocaInst *State = EntryAlloca.CreateAlloca(EntryAlloca.getInt32Ty(), nullptr,
                                                 "own.fla.state");
    IRBuilder<> EntryBuilder(EntryTerm);
    Value *Initial = stateForTerminator(EntryTerm, EntryBuilder, StateByBlock);
    if (!Initial) {
      State->eraseFromParent();
      return PreservedAnalyses::all();
    }

    BasicBlock *Dispatcher = BasicBlock::Create(
        F.getContext(), "own.fla.dispatch", &F, Blocks.front());
    EntryBuilder.CreateStore(Initial, State);
    EntryBuilder.CreateBr(Dispatcher);
    EntryTerm->eraseFromParent();

    IRBuilder<> DispatchBuilder(Dispatcher);
    LoadInst *Current =
        DispatchBuilder.CreateLoad(DispatchBuilder.getInt32Ty(), State,
                                   "own.fla.current");
    SwitchInst *Dispatch = DispatchBuilder.CreateSwitch(Current, Blocks.front(),
                                                        Blocks.size());
    for (BasicBlock *BB : Blocks)
      Dispatch->addCase(DispatchBuilder.getInt32(StateByBlock[BB]), BB);

    for (BasicBlock *BB : Blocks) {
      Instruction *Term = BB->getTerminator();
      if (isa<ReturnInst>(Term) || isa<UnreachableInst>(Term))
        continue;
      IRBuilder<> B(Term);
      Value *Next = stateForTerminator(Term, B, StateByBlock);
      if (!Next)
        continue;
      B.CreateStore(Next, State);
      B.CreateBr(Dispatcher);
      Term->eraseFromParent();
    }

    return PreservedAnalyses::none();
  }
};

class BogusControlFlowPass : public PassInfoMixin<BogusControlFlowPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || F.size() < 2)
      return PreservedAnalyses::all();

    Module *M = F.getParent();
    LLVMContext &Context = F.getContext();
    GlobalVariable *Seed = M->getGlobalVariable("__own_obf_seed");
    if (!Seed) {
      Seed = new GlobalVariable(
          *M, Type::getInt32Ty(Context), false, GlobalValue::InternalLinkage,
          ConstantInt::get(Type::getInt32Ty(Context), 0x51a7b3c5u),
          "__own_obf_seed");
      Seed->setAlignment(Align(4));
    }

    SmallVector<BasicBlock *, 32> Targets;
    unsigned Budget = 12;
    for (BasicBlock &BB : F) {
      if (&BB == &F.getEntryBlock() || BB.isEHPad() || !BB.phis().empty() ||
          BB.getName().starts_with("own.bcf.") || pred_empty(&BB))
        continue;
      Targets.push_back(&BB);
      if (Targets.size() == Budget)
        break;
    }

    for (BasicBlock *Target : Targets) {
      BasicBlock *Guard = BasicBlock::Create(Context, "own.bcf.guard", &F, Target);
      BasicBlock *Bogus = BasicBlock::Create(Context, "own.bcf.bogus", &F, Target);
      SmallVector<BasicBlock *, 16> Predecessors(predecessors(Target));
      for (BasicBlock *Pred : Predecessors)
        Pred->getTerminator()->replaceSuccessorWith(Target, Guard);

      IRBuilder<> G(Guard);
      LoadInst *X = G.CreateLoad(G.getInt32Ty(), Seed, "own.bcf.seed");
      X->setVolatile(true);
      Value *Product = G.CreateMul(X, X, "own.bcf.square");
      Value *Even = G.CreateAnd(G.CreateAdd(Product, X, "own.bcf.even"),
                                G.getInt32(1), "own.bcf.parity");
      Value *Opaque = G.CreateICmpEQ(Even, G.getInt32(0), "own.bcf.opaque");
      G.CreateCondBr(Opaque, Target, Bogus);

      IRBuilder<> B(Bogus);
      LoadInst *Noise = B.CreateLoad(B.getInt32Ty(), Seed, "own.bcf.noise");
      Noise->setVolatile(true);
      Value *Mixed = B.CreateXor(B.CreateMul(Noise, B.getInt32(33)),
                                 B.getInt32(0x5a17), "own.bcf.mix");
      StoreInst *Store = B.CreateStore(Mixed, Seed);
      Store->setVolatile(true);
      B.CreateBr(Target);
    }

    return Targets.empty() ? PreservedAnalyses::all()
                           : PreservedAnalyses::none();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "OwnObfuscator", "1.0.0",
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "own-instsub") {
                    FPM.addPass(InstructionSubstitutionPass());
                    return true;
                  }
                  if (Name == "own-fla") {
                    FPM.addPass(ControlFlowFlatteningPass());
                    return true;
                  }
                  if (Name == "own-bcf") {
                    FPM.addPass(BogusControlFlowPass());
                    return true;
                  }
                  return false;
                });
          }};
}

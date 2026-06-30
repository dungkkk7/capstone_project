// Normalize bieu thuc PC trong switch dispatch.
// - Chuyen ptrtoint(data_xxx) ve hang PC
// - Don gian hoa condition de pass sau hoat dong
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <optional>

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

static std::optional<uint64_t> ParseDataPC(const Value *V) {
  // Parse symbol data_<hex_pc> thành giá trị PC.
  V = V->stripPointerCasts();
  const auto *GV = dyn_cast<GlobalValue>(V);
  if (!GV) {
    return std::nullopt;
  }

  StringRef Name = GV->getName();
  if (!Name.starts_with("data_")) {
    return std::nullopt;
  }
  Name = Name.drop_front(5);
  if (Name.empty()) {
    return std::nullopt;
  }

  size_t End = 0;
  while (End < Name.size() && std::isxdigit(static_cast<unsigned char>(Name[End]))) {
    ++End;
  }
  if (End == 0) {
    return std::nullopt;
  }

  uint64_t PC = 0;
  if (Name.take_front(End).getAsInteger(16, PC)) {
    return std::nullopt;
  }
  return PC;
}

static std::optional<uint64_t> PtrToIntDataPC(Value *V) {
  // Nhận diện ptrtoint(data_<pc>) ở nhiều dạng value khác nhau.
  if (auto *PTI = dyn_cast<PtrToIntInst>(V)) {
    return ParseDataPC(PTI->getPointerOperand());
  }

  auto *CE = dyn_cast<ConstantExpr>(V);
  if (CE && CE->getOpcode() == Instruction::PtrToInt) {
    return ParseDataPC(CE->getOperand(0));
  }

  auto *Op = dyn_cast<Operator>(V);
  if (Op && Op->getOpcode() == Instruction::PtrToInt) {
    return ParseDataPC(Op->getOperand(0));
  }

  return std::nullopt;
}

static bool SwitchLooksLikeLiftedDispatch(const SwitchInst &SW) {
  // Heuristic dispatch switch của lifted code.
  unsigned InstTargets = 0;
  for (auto Case : SW.cases()) {
    if (Case.getCaseSuccessor()->getName().starts_with("inst_")) {
      ++InstTargets;
    }
  }
  return InstTargets >= 2;
}

static bool NormalizeBinaryPCBase(BinaryOperator &BO) {
  // Chuẩn hoá biểu thức cộng/trừ có base dạng ptrtoint(data_xxx)
  // thành hằng số PC trực tiếp để đơn giản hoá condition của switch.
  if (BO.getOpcode() != Instruction::Add && BO.getOpcode() != Instruction::Sub) {
    return false;
  }
  if (!BO.getType()->isIntegerTy()) {
    return false;
  }

  bool Changed = false;
  for (unsigned I = 0; I != 2; ++I) {
    auto PC = PtrToIntDataPC(BO.getOperand(I));
    if (!PC.has_value()) {
      continue;
    }

    BO.setOperand(I, ConstantInt::get(BO.getType(), *PC));
    Changed = true;
  }
  return Changed;
}

static bool NormalizePCExpression(Value *V, DenseSet<Value *> &Seen) {
  // DFS có chống lặp để chuẩn hoá đệ quy các node liên quan expression PC.
  if (!V || Seen.contains(V)) {
    return false;
  }
  Seen.insert(V);

  auto *I = dyn_cast<Instruction>(V);
  if (!I) {
    return false;
  }

  bool Changed = false;
  if (auto *BO = dyn_cast<BinaryOperator>(I)) {
    Changed |= NormalizeBinaryPCBase(*BO);
  }

  switch (I->getOpcode()) {
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::Trunc:
    case Instruction::ZExt:
    case Instruction::SExt:
    case Instruction::And:
    case Instruction::Or:
    case Instruction::Xor:
      for (Use &U : I->operands()) {
        Changed |= NormalizePCExpression(U.get(), Seen);
      }
      break;
    default:
      break;
  }

  return Changed;
}

bool BrightenRepairPass::NormalizeJumpTableTargets(Module &M) {
  // Rule này chỉ đụng condition của switch dispatch lifted.
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (BasicBlock &BB : F) {
      auto *SW = dyn_cast<SwitchInst>(BB.getTerminator());
      if (!SW || !SW->getCondition()->getType()->isIntegerTy() ||
          !SwitchLooksLikeLiftedDispatch(*SW)) {
        continue;
      }

      DenseSet<Value *> Seen;
      Changed |= NormalizePCExpression(SW->getCondition(), Seen);
    }
  }

  return Changed;
}

}  // namespace brighten_repair

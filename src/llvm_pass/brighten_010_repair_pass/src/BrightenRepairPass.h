// Khai bao BrightenRepairPass va cac helper API.
// - Dinh nghia danh sach rule chinh
// - Khai bao helper nhan dien IR pattern
// - Cung cap utility cho cac rule khac
#pragma once

#include <cstdint>
#include <optional>
#include <string>

#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Passes/PassBuilder.h"

namespace brighten_repair {

// Pass tinh chỉnh semantic hậu-lifting:
// - giảm các giả định nguy hiểm gây sai mô hình IR,
// - sửa/chuẩn hoá các mẫu IR do Remill/McSema sinh ra,
// - chuẩn hoá các mẫu obfuscation để IR dễ phân tích hơn.
class BrightenRepairPass : public llvm::PassInfoMixin<BrightenRepairPass> {
 public:
  // Entry point của module pass.
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

 private:
  // Nhóm rule xử lý cờ/attribute có thể dẫn tới poison hoặc UB giả.
  static bool StripPoisonDrivingFlags(llvm::Module &M);
  static bool StripPoisonDrivingAttributes(llvm::Module &M);

  // Bổ sung/chuẩn hoá luồng gọi Remill.
  static bool DefineRemillControlHelpers(llvm::Module &M);
  static bool AddRemillEntryDispatchers(llvm::Module &M);
  static bool NormalizeRemillFunctionCalls(llvm::Module &M);
  static bool SynthesizeMissingMain(llvm::Module &M);
  static bool PruneUnusedRemillMcSemaHelpers(llvm::Module &M);

  // Sửa/hardening runtime state do McSema sinh ra.
  static bool GrowMcSemaSyntheticStack(llvm::Module &M);

  // Cleanup conservative cho noise do McSema/Remill sinh ra.
  static bool ForwardMcSemaFlagLoads(llvm::Module &M);
  static bool PruneDeadMcSemaFlagStores(llvm::Module &M);
  static bool PruneDeadRipStores(llvm::Module &M);
  static bool ForwardMcSemaStateLoads(llvm::Module &M);
  static bool ForwardMcSemaGuestStackSlots(llvm::Module &M);
  static bool PruneUnusedMcSemaStateStores(llvm::Module &M);
  static bool InlineMcSemaExternalWrappers(llvm::Module &M);

  // Hardening cho các thư viện C dễ gây lỗi bộ nhớ.
  static bool HardenUnsafeScanf(llvm::Module &M);
  static bool CanonicalizeObfuscatedCompares(llvm::Module &M);
  static bool SanitizeDangerousStrlen(llvm::Module &M);
  static bool RepairRemillVarArgFPCalls(llvm::Module &M);
  static bool RepairRemillX87LibCalls(llvm::Module &M);
  static bool RepairMcSemaX87PseudoDoubleLoads(llvm::Module &M);

  // Chuẩn hoá đích nhảy và khôi phục target fallthrough thiếu.
  static bool NormalizeJumpTableTargets(llvm::Module &M);
  static bool RecoverNoReturnFallthroughTargets(llvm::Module &M);

  // Chặn/guard các lời gọi gián tiếp thô (inttoptr call).
  static bool RepairMcSemaRawIndirectCallStack(llvm::Module &M);
  static bool GuardRawIndirectCalls(llvm::Module &M);
};

// Tạo (hoặc lấy lại) helper fallback trả về memory không đổi.
llvm::Function *GetOrCreateNoopCallHelper(llvm::Module &M, llvm::FunctionType *FTy);
// Tìm lifted subroutine theo PC dạng tên sub_<hex>.
llvm::Function *FindLiftedSubroutineByPC(llvm::Module &M, uint64_t PC);

// Các helper nhận diện mẫu IR nhỏ phục vụ rule canonicalization.
bool IsConstInt(llvm::Value *V, int64_t SignedVal);
bool MatchAddIntMin32(llvm::Value *V, llvm::Value *&X);

// Helper nhận diện scanf-like và parse format dạng đơn giản %s / %<width>s.
bool IsScanfLikeCall(const llvm::CallInst *CI);
bool ParseSimplePercentS(llvm::StringRef Fmt, bool &HasWidth, uint64_t &Width);

// Suy luận kích thước vùng ghi để hardening scanf/strlen an toàn hơn.
std::optional<uint64_t> InferBaseObjectBytes(llvm::Value *Base, const llvm::DataLayout &DL);
std::optional<uint64_t> InferWritableBytesAtPointer(llvm::Value *Ptr, const llvm::DataLayout &DL);

}  // namespace brighten_repair

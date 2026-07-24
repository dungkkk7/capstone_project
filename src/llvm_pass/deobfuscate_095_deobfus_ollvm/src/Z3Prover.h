#ifndef DEOBFUSCATE_095_Z3_PROVER_H
#define DEOBFUSCATE_095_Z3_PROVER_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Value.h"

#include <memory>
#include <optional>
#include <string>

namespace deobfuscate095 {

enum class ProofResult { Proved, Disproved, Unknown };

struct ProofStats {
  uint64_t Queries = 0;
  uint64_t Proved = 0;
  uint64_t Disproved = 0;
  uint64_t Unknown = 0;
};

enum class CandidateKind {
  ConstantZero,
  ConstantOne,
  ConstantAllOnes,
  Leaf0,
  Leaf1,
  Add,
  Sub01,
  Sub10,
  Xor,
  And,
  Or,
  Not0,
  Not1,
  Neg0,
  Neg1,
};

struct SimplificationProof {
  CandidateKind Kind;
  llvm::SmallVector<llvm::Value *, 2> Leaves;
};

class Z3Prover {
public:
  explicit Z3Prover(unsigned TimeoutMs);
  ~Z3Prover();

  Z3Prover(const Z3Prover &) = delete;
  Z3Prover &operator=(const Z3Prover &) = delete;

  std::optional<bool> proveBooleanConstant(llvm::Value *V);
  std::optional<SimplificationProof> proveSimplerInteger(llvm::Value *V,
                                                        unsigned MinOps = 3);
  const ProofStats &stats() const { return Stats; }

private:
  class Impl;
  std::unique_ptr<Impl> P;
  ProofStats Stats;
};

} // namespace deobfuscate095

#endif


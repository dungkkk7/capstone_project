#ifndef DEOBFUSCATE_095_Z3_PROVER_H
#define DEOBFUSCATE_095_Z3_PROVER_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/ValueMap.h"
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
  // Binary/constant recipes used by the LLVM adapter for larger rule
  // families. The proof records operand indices so a rewrite
  // is not tied to traversal order beyond the verified translation.
  PairAdd,
  PairSub,
  PairMul,
  PairXor,
  PairAnd,
  PairOr,
  AddConst,
  SubConst,
  XorConst,
  AndConst,
  OrConst,
  MulConst,
  ShlConst,
  LShrConst,
  AShrConst,
  UnaryNot,
  UnaryNeg,
};

struct SimplificationProof {
  CandidateKind Kind;
  llvm::SmallVector<llvm::Value *, 2> Leaves;
  unsigned LeftIndex = 0;
  unsigned RightIndex = 1;
  uint64_t Constant = 0;
};

class Z3Prover {
public:
  explicit Z3Prover(unsigned TimeoutMs);
  ~Z3Prover();

  Z3Prover(const Z3Prover &) = delete;
  Z3Prover &operator=(const Z3Prover &) = delete;

  std::optional<bool> proveBooleanConstant(llvm::Value *V);
  std::optional<SimplificationProof> proveSimplerInteger(llvm::Value *V,
                                                        unsigned MinOps = 3,
                                                        unsigned MaxChecks = 24);
  void invalidateBooleanCache() { BooleanCache.clear(); }
  const ProofStats &stats() const { return Stats; }

private:
  class Impl;
  std::unique_ptr<Impl> P;
  ProofStats Stats;
  // ValueMap follows RAUW/deletion, so cached predicate proofs cannot become
  // stale when CFG/MBA rewrites replace or erase the original LLVM Value.
  llvm::ValueMap<llvm::Value *, int8_t> BooleanCache;
};

} // namespace deobfuscate095

#endif

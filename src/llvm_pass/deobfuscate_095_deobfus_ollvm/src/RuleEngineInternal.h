#ifndef DEOBFUSCATE_095_RULE_ENGINE_INTERNAL_H
#define DEOBFUSCATE_095_RULE_ENGINE_INTERNAL_H

#include "RuleCatalog.h"
#include "RuleEngine.h"

#include "llvm/IR/Module.h"

namespace deobfuscate095::rule_detail {

bool applyMBARules(llvm::Module &M, RuleEngineStats &Stats);
bool applyPredicateRules(llvm::Module &M, RuleEngineStats &Stats);
bool applyLogicalNotRules(llvm::Module &M, RuleEngineStats &Stats);
bool applyJumpRules(llvm::Module &M, RuleEngineStats &Stats);
bool foldConstantControl(llvm::Module &M, RuleEngineStats &Stats);

bool matchCatalogExpression(const RuleExprRef &Pattern,
                            llvm::Value *Candidate,
                            llvm::IntegerType *Type);

} // namespace deobfuscate095::rule_detail

#endif

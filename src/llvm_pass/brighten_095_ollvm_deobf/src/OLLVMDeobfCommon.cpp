#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

std::string hashText(StringRef Text) {
  SHA256 Hash;
  Hash.update(Text);
  auto Digest = Hash.final();
  return toHex(ArrayRef<uint8_t>(Digest), true);
}

std::string valueText(const Value &V) {
  std::string Text;
  raw_string_ostream OS(Text);
  V.print(OS);
  return Text;
}

void importExistingProofs(Module &M, Metrics &Stats,
                                 SmallVectorImpl<ProofRecord> &Proofs) {
  NamedMDNode *Ledger = M.getNamedMetadata("ollvm.deobf.proofs");
  if (!Ledger) return;
  for (MDNode *Node : Ledger->operands()) {
    if (Node->getNumOperands() < 5) continue;
    auto Get = [&](unsigned I) -> std::string {
      auto *S = dyn_cast<MDString>(Node->getOperand(I));
      return S ? S->getString().str() : std::string();
    };
    ProofRecord P{Get(0), Get(1), Get(2), Get(3), Get(4),
                  Node->getNumOperands() > 5 ? Get(5) : std::string()};
    if (Node->getNumOperands() > 6) P.OldHash = Get(6);
    if (Node->getNumOperands() > 7) P.NewHash = Get(7);
    if (Node->getNumOperands() > 8) P.ProofQueryHash = Get(8);
    if (Node->getNumOperands() > 9) {
      std::string EncodedDependencies = Get(9);
      SmallVector<StringRef, 4> Parts;
      StringRef(EncodedDependencies).split(Parts, '\x1f', -1, false);
      for (StringRef Part : Parts) P.Dependencies.push_back(Part.str());
    }
    if (P.Result == "unresolved" && P.Kind == "cff_candidate") {
      // Carry the obligation until end-of-round reconciliation.  Merely
      // changing the state PHI/switch shape must never erase a residual.
      ++Stats.DispatchersUnresolved;
      Proofs.push_back(std::move(P));
      continue;
    }
    // Unresolved classifications must be re-evaluated after cleanup; only
    // completed proofs survive into the next fixed-point round.
    if (P.Result != "proved") continue;
    if (P.Kind == "lifted_semantics_sanitize") ++Stats.FlagsSanitized;
    else if (P.Kind == "x86_flag_recovery") ++Stats.FlagConesRecovered;
    else if (P.Kind == "bv_canonicalize") ++Stats.BVRewrites;
    else if (P.Kind == "instsub_rewrite") {
      ++Stats.BVRewrites;
      ++Stats.InstSubRewrites;
    } else if (P.Kind == "opaque_edge") {
      ++Stats.OpaqueEdgesPruned;
      if (StringRef(P.Engine).contains("dominating_constraints"))
        ++Stats.PathConstrainedOpaqueEdges;
      if (StringRef(P.Engine).starts_with("z3_memoryssa"))
        ++Stats.MemorySSAConstrainedOpaqueEdges;
      if (StringRef(P.Engine).contains("path_state_ite"))
        ++Stats.PathStateITEOpaqueEdges;
      if (StringRef(P.Engine).contains("inductive_constant_phi"))
        ++Stats.InductivePhiOpaqueEdges;
    }
    else if (P.Kind == "compare_ladder") ++Stats.CompareLaddersRecovered;
    else if (P.Kind == "bv_egraph_rewrite") ++Stats.EGraphRewrites;
    else if (P.Kind == "cff_dispatcher") ++Stats.DispatchersRecovered;
    Proofs.push_back(std::move(P));
  }
}

std::string valueName(const Value &V) {
  if (V.hasName())
    return V.getName().str();
  std::string S;
  raw_string_ostream OS(S);
  V.printAsOperand(OS, false);
  return S;
}

bool containsLiftMarker(StringRef S) {
  return S.contains_insensitive("remill") ||
         S.contains_insensitive("mcsema") ||
         S.contains_insensitive("frame_storage_backing") ||
         S.contains_insensitive("struct.State");
}

bool valueContainsLiftMarker(
    const Value *Root, SmallPtrSetImpl<const Value *> &Seen) {
  SmallVector<const Value *, 32> Work;
  if (Root) Work.push_back(Root);
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second) continue;
    if (const auto *GV = dyn_cast<GlobalValue>(V);
        GV && containsLiftMarker(GV->getName()))
      return true;
    if (V->hasName() && containsLiftMarker(V->getName())) return true;
    if (const auto *U = dyn_cast<User>(V))
      for (const Use &Op : U->operands())
        Work.push_back(Op.get());
  }
  return false;
}

bool isLiftedFunction(const Function &F) {
  if (containsLiftMarker(F.getName()))
    return true;
  for (const Argument &A : F.args()) {
    if (A.hasName() && containsLiftMarker(A.getName()))
      return true;
  }
  // Share visited state across the complete function.  The lifted SSA graph
  // is highly reconvergent (thousands of selects can share the same cones),
  // so independent depth-limited recursion is exponential on valid modules.
  SmallPtrSet<const Value *, 32> Seen;
  for (const Instruction &I : instructions(F)) {
    for (const Use &U : I.operands())
      if (valueContainsLiftMarker(U.get(), Seen)) return true;
  }
  return false;
}

bool hasPoisonGeneratingFlags(const Value *V) {
  const auto *OBO = dyn_cast<OverflowingBinaryOperator>(V);
  if (OBO && (OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap()))
    return true;
  const auto *PEO = dyn_cast<PossiblyExactOperator>(V);
  return PEO && PEO->isExact();
}

} // namespace brighten_ollvm_deobf

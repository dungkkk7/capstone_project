# Repository-owned LLVM 21 obfuscator

This pass plugin provides three deterministic, auditable transformations for
building `own_dataset` binaries:

- `own-instsub`: bit-vector instruction substitution for integer add/sub/xor;
- `own-fla`: dispatcher/state-machine control-flow flattening;
- `own-bcf`: opaque-predicate guards and unreachable bogus blocks.

The dataset builder compiles C to LLVM bitcode at `-O0`, demotes any incidental
SSA PHI nodes with LLVM's semantics-preserving `reg2mem`, runs all three
obfuscation passes, verifies the module, and links the resulting bitcode to an ELF.
It also rejects outputs whose IR lacks markers from any of the three passes.
This is an OLLVM-style repository-owned implementation, not an unmodified
upstream Obfuscator-LLVM distribution; publication text and manifests must use
that exact description.

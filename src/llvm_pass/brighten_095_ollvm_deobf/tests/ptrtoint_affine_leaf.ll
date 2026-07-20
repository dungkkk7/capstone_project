; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and not any(x['result']=='unresolved' for x in d['proofs'])"

; ptrtoint is an opaque but stable native-address leaf.  The solver may prove
; integer identities around the same SSA value without modeling pointers.
define i64 @ptrtoint_affine_leaf(ptr %base.ptr, i64 %index) {
entry:
  %base = ptrtoint ptr %base.ptr to i64
  %frame.0 = add i64 %base, -40
  %frame.1 = add i64 %frame.0, -208
  %scaled = shl i64 %index, 2
  %address = add i64 %scaled, %frame.1
  ret i64 %address
}

define i32 @main() {
  %value = call i64 @ptrtoint_affine_leaf(ptr null, i64 3)
  %bad = icmp ne i64 %value, -236
  %status = zext i1 %bad to i32
  ret i32 %status
}

; Two recovered guest ranges overlap.  Neither mapped arm has unique object
; provenance, so final cleanup must preserve the generated select/fallback
; chain and strict mode must reject it rather than guess a native GEP.
target triple = "x86_64-pc-linux-gnu"

@dyn_bytes_overlap_a = internal global [64 x i8] zeroinitializer,
  !brighten.guest.range !0
@dyn_bytes_overlap_b = internal global [64 x i8] zeroinitializer,
  !brighten.guest.range !1

define void @ambiguous_overlap_store(i64 %guest.address, i8 %value) {
entry:
  %native.address.fallback = inttoptr i64 %guest.address to ptr

  %delta.a = add i64 %guest.address, -5242880
  %in.a = icmp ult i64 %delta.a, 64
  %mapped.a = getelementptr i8, ptr @dyn_bytes_overlap_a, i64 %delta.a

  %delta.b = add i64 %guest.address, -5242912
  %in.b = icmp ult i64 %delta.b, 64
  %mapped.b = getelementptr i8, ptr @dyn_bytes_overlap_b, i64 %delta.b

  %native.data.pointer.select.b = select i1 %in.b, ptr %mapped.b,
      ptr %native.address.fallback
  %native.data.pointer.select = select i1 %in.a, ptr %mapped.a,
      ptr %native.data.pointer.select.b
  store volatile i8 %value, ptr %native.data.pointer.select, align 1
  ret void
}

!0 = !{i64 5242880, i64 5242944}
!1 = !{i64 5242912, i64 5242976}

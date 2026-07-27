; RUN: opt -load-pass-plugin %llvmshlibdir/BrightenNativeCleanupPass%shlibext -passes='brighten-native-cleanup-pass,verify' -S %s | FileCheck %s
;
; The inverse mapper operates on host-object identity.  Native cleanup may
; canonicalize guest integer carriers elsewhere, but it must never replace a
; mapper base with its guest numeric range start.  The ranges deliberately
; overlap; precedence and the unknown-pointer fallback remain observable.

@native_residual_404000 = internal global [32 x i8] zeroinitializer, !brighten.guest.range !0
@native_residual_404010 = internal global [32 x i8] zeroinitializer, !brighten.guest.range !1

define internal i64 @__guest_pointer_to_address(ptr %host) noinline optnone {
entry:
  %host_int = ptrtoint ptr %host to i64
  %base0 = ptrtoint ptr @native_residual_404000 to i64
  %offset0 = sub i64 %host_int, %base0
  %after0 = icmp uge i64 %host_int, %base0
  %in0 = icmp ult i64 %offset0, 32
  %match0 = and i1 %after0, %in0
  br i1 %match0, label %hit0, label %next0

hit0:
  %guest0 = add i64 4210688, %offset0
  ret i64 %guest0

next0:
  %base1 = ptrtoint ptr @native_residual_404010 to i64
  %offset1 = sub i64 %host_int, %base1
  %after1 = icmp uge i64 %host_int, %base1
  %in1 = icmp ult i64 %offset1, 32
  %match1 = and i1 %after1, %in1
  br i1 %match1, label %hit1, label %fallback

hit1:
  %guest1 = add i64 4210704, %offset1
  ret i64 %guest1

fallback:
  ret i64 %host_int
}

; CHECK-LABEL: define internal i64 @__guest_pointer_to_address
; CHECK: %base0 = ptrtoint ptr @native_residual_404000 to i64
; CHECK: %base1 = ptrtoint ptr @native_residual_404010 to i64
; CHECK: ret i64 %host_int
; CHECK-NOT: ptrtoint ptr inttoptr (i64 4210688 to ptr)

!0 = !{i64 4210688, i64 4210720}
!1 = !{i64 4210704, i64 4210736}

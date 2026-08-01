declare void @abort() noreturn

define i32 @signed_zero(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %zero_fault, label %check
check:
  %ismin = icmp eq i32 %dividend, -2147483648
  %isminusone = icmp eq i32 %divisor, -1
  %overflow = and i1 %ismin, %isminusone
  br i1 %overflow, label %overflow_fault, label %normal
zero_fault:
  call void @abort()
  unreachable
overflow_fault:
  call void @abort()
  unreachable
normal:
  %q = sdiv i32 %dividend, %divisor
  ret i32 %q
}

define i32 @unsigned_zero(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %fault, label %normal
fault:
  call void @abort()
  unreachable
normal:
  %q = udiv i32 %dividend, %divisor
  ret i32 %q
}

define i32 @signed_overflow(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %zero_fault, label %check
check:
  %ismin = icmp eq i32 %dividend, -2147483648
  %isminusone = icmp eq i32 %divisor, -1
  %overflow = and i1 %ismin, %isminusone
  br i1 %overflow, label %overflow_fault, label %normal
zero_fault:
  call void @abort()
  unreachable
overflow_fault:
  call void @abort()
  unreachable
normal:
  %q = sdiv i32 %dividend, %divisor
  ret i32 %q
}

define i32 @main(i32 %argc, ptr nocapture readnone %argv) {
entry:
  switch i32 %argc, label %overflow [
    i32 1, label %signed_zero
    i32 2, label %unsigned_zero
  ]
signed_zero:
  %a = call i32 @signed_zero(i32 1, i32 0)
  ret i32 %a
unsigned_zero:
  %b = call i32 @unsigned_zero(i32 1, i32 0)
  ret i32 %b
overflow:
  %c = call i32 @signed_overflow(i32 -2147483648, i32 -1)
  ret i32 %c
}

; Regression fixture for the production 095 pass.  No names or constants in
; this file are consulted by the implementation.

@fmt = private constant [10 x i8] c"%d %d %d\0A\00"
@callee_slot = private constant ptr @target

declare i32 @printf(ptr, ...)

define i32 @target(i32 %x) {
entry:
  %r = add i32 %x, 7
  ret i32 %r
}

define i32 @indirect(i32 %x) {
entry:
  %fp = load ptr, ptr @callee_slot
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @mba(i32 %x, i32 %y) {
entry:
  %a = xor i32 %x, %y
  %b = and i32 %x, %y
  %twice = mul i32 %b, 2
  %mixed = add i32 %a, %twice
  ret i32 %mixed
}

define i32 @opaque(i32 %x) {
entry:
  %xm1 = sub i32 %x, 1
  %product = mul i32 %x, %xm1
  %low = and i32 %product, 1
  %always = icmp eq i32 %low, 0
  br i1 %always, label %live, label %bogus

live:
  %good = add i32 %x, 1
  ret i32 %good

bogus:
  %bad = add i32 %x, 99
  ret i32 %bad
}

define i32 @flat(i1 %choose) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 17, %entry ], [ %next, %latch ]
  switch i32 %state, label %trap [
    i32 17, label %case_a
    i32 91, label %case_b
    i32 203, label %done
  ]

case_a:
  %from_a = select i1 %choose, i32 91, i32 203
  br label %latch

case_b:
  br label %latch

latch:
  %next = phi i32 [ %from_a, %case_a ], [ 203, %case_b ]
  br label %dispatch

done:
  ret i32 42

trap:
  ret i32 -1
}

define i32 @fake_stack(i32 %x) {
entry:
  %frame = alloca [128 x i8], align 16
  %slot = getelementptr inbounds [128 x i8], ptr %frame, i64 0, i64 24
  store i32 %x, ptr %slot, align 4
  %v = load i32, ptr %slot, align 4
  ret i32 %v
}

define i32 @main() {
entry:
  %a = call i32 @indirect(i32 5)
  %b = call i32 @mba(i32 11, i32 13)
  %c = call i32 @opaque(i32 123)
  %d = call i32 @flat(i1 true)
  %e = call i32 @fake_stack(i32 9)
  %sum0 = add i32 %c, %d
  %sum = add i32 %sum0, %e
  %ignored = call i32 (ptr, ...) @printf(ptr @fmt, i32 %a, i32 %b, i32 %sum)
  ret i32 0
}


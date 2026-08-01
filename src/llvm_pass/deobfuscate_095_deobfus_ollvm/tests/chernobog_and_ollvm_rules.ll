; Exact LLVM ports of Chernobog And_OllvmRule_1..3.  Root order distinguishes
; Rule_1/Rule_2; individual bitwise operands exercise legal commutation only.

define i8 @r1_i8(i8 noundef %x, i8 noundef %y) { entry:
  %o = or i8 %y, %x
  %q = xor i8 %y, %x
  %n = xor i8 -1, %q
  %z = and i8 %o, %n
  ret i8 %z }
define i32 @r1_i32(i32 noundef %x, i32 noundef %y) { entry:
  %o = or i32 %x, %y
  %q = xor i32 %x, %y
  %n = xor i32 %q, -1
  %z = and i32 %o, %n
  ret i32 %z }
define i64 @r1_i64(i64 noundef %x, i64 noundef %y) { entry:
  %o = or i64 %y, %x
  %q = xor i64 %x, %y
  %n = xor i64 -1, %q
  %z = and i64 %o, %n
  ret i64 %z }

define i8 @r2_i8(i8 noundef %x, i8 noundef %y) { entry:
  %q = xor i8 %x, %y
  %n = xor i8 %q, -1
  %o = or i8 %y, %x
  %z = and i8 %n, %o
  ret i8 %z }
define i32 @r2_i32(i32 noundef %x, i32 noundef %y) { entry:
  %q = xor i32 %y, %x
  %n = xor i32 -1, %q
  %o = or i32 %x, %y
  %z = and i32 %n, %o
  ret i32 %z }
define i64 @r2_i64(i64 noundef %x, i64 noundef %y) { entry:
  %q = xor i64 %y, %x
  %n = xor i64 %q, -1
  %o = or i64 %y, %x
  %z = and i64 %n, %o
  ret i64 %z }

define i8 @r3_i8(i8 noundef %x, i8 noundef %y) { entry:
  %nx = xor i8 -1, %x
  %a = or i8 %y, %nx
  %ny = xor i8 %y, -1
  %b = or i8 %x, %ny
  %ab = and i8 %b, %a
  %c = or i8 %y, %x
  %z = and i8 %c, %ab
  ret i8 %z }
define i32 @r3_i32(i32 noundef %x, i32 noundef %y) { entry:
  %nx = xor i32 %x, -1
  %a = or i32 %nx, %y
  %ny = xor i32 -1, %y
  %b = or i32 %ny, %x
  %ab = and i32 %a, %b
  %c = or i32 %x, %y
  %z = and i32 %ab, %c
  ret i32 %z }
define i64 @r3_i64(i64 noundef %x, i64 noundef %y) { entry:
  %nx = xor i64 -1, %x
  %a = or i64 %y, %nx
  %ny = xor i64 %y, -1
  %b = or i64 %x, %ny
  %ab = and i64 %a, %b
  %c = or i64 %y, %x
  %z = and i64 %ab, %c
  ret i64 %z }

define i32 @negative_flags(i32 noundef %x, i32 noundef %y) { entry:
  %f = add nsw i32 %x, 0
  %o = or i32 %f, %y
  %q = xor i32 %f, %y
  %n = xor i32 %q, -1
  %z = and i32 %o, %n
  ret i32 %z }
define i32 @negative_different_ssa(i32 noundef %x, i32 noundef %y, i32 noundef %z) { entry:
  %o = or i32 %x, %y
  %q = xor i32 %x, %z
  %n = xor i32 %q, -1
  %r = and i32 %o, %n
  ret i32 %r }
define i32 @negative_cast(i8 noundef %x, i8 noundef %y) { entry:
  %xx = zext i8 %x to i32
  %yy = zext i8 %y to i32
  %o = or i32 %xx, %yy
  %q = xor i32 %xx, %yy
  %n = xor i32 %q, -1
  %r = and i32 %o, %n
  ret i32 %r }
define i8 @negative_undef(i8 noundef %y) { entry:
  %o = or i8 undef, %y
  %q = xor i8 undef, %y
  %n = xor i8 %q, -1
  %r = and i8 %o, %n
  ret i8 %r }
define i8 @negative_poison(i8 noundef %x, i8 noundef %y) { entry:
  %p = add nsw i8 %x, %y
  %o = or i8 %p, %y
  %q = xor i8 %p, %y
  %n = xor i8 %q, -1
  %r = and i8 %o, %n
  ret i8 %r }
define i8 @negative_freeze(i8 noundef %x, i8 noundef %y) { entry:
  %f = freeze i8 %x
  %o = or i8 %f, %y
  %q = xor i8 %f, %y
  %n = xor i8 %q, -1
  %r = and i8 %o, %n
  ret i8 %r }
define <4 x i8> @negative_vector(<4 x i8> %x, <4 x i8> %y) { entry:
  %o = or <4 x i8> %x, %y
  %q = xor <4 x i8> %x, %y
  %n = xor <4 x i8> %q, <i8 -1, i8 -1, i8 -1, i8 -1>
  %r = and <4 x i8> %o, %n
  ret <4 x i8> %r }

@volatile_source = global i8 0
@atomic_source = global i8 0
declare i8 @opaque_source()
define i8 @side_effect_volatile(i8 noundef %y) { entry:
  %x = load volatile i8, ptr @volatile_source
  %o = or i8 %x, %y
  %q = xor i8 %x, %y
  %n = xor i8 %q, -1
  %r = and i8 %o, %n
  ret i8 %r }
define i8 @side_effect_call(i8 noundef %y) { entry:
  %x = call i8 @opaque_source()
  %o = or i8 %x, %y
  %q = xor i8 %x, %y
  %n = xor i8 %q, -1
  %r = and i8 %o, %n
  ret i8 %r }
define i8 @side_effect_atomic(i8 noundef %y) { entry:
  %x = load atomic i8, ptr @atomic_source monotonic, align 1
  %o = or i8 %x, %y
  %q = xor i8 %x, %y
  %n = xor i8 %q, -1
  %r = and i8 %o, %n
  ret i8 %r }

; Exact LLVM ports of Chernobog Add_OllvmRule_1..4.  Every positive input is
; scalar, fixed-width and noundef.  The negative roots are intentionally not
; called by the differential driver.

define i8 @r1_i8(i8 noundef %x, i8 noundef %y) { entry: %a = and i8 %y, %x
  %o = or i8 %x, %y
  %r = add i8 %o, %a
  ret i8 %r }
define i32 @r1_i32(i32 noundef %x, i32 noundef %y) { entry: %a = and i32 %x, %y
  %o = or i32 %x, %y
  %r = add i32 %a, %o
  ret i32 %r }
define i64 @r1_i64(i64 noundef %x, i64 noundef %y) { entry: %a = and i64 %y, %x
  %o = or i64 %y, %x
  %r = add i64 %o, %a
  ret i64 %r }

define i8 @r2_i8(i8 noundef %x, i8 noundef %y) { entry: %nx = xor i8 -1, %x
  %ny = xor i8 %y, -1
  %s = add i8 %ny, %nx
  %n = xor i8 %s, -1
  %r = add i8 1, %n
  ret i8 %r }
define i32 @r2_i32(i32 noundef %x, i32 noundef %y) { entry: %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %s = add i32 %nx, %ny
  %n = xor i32 %s, -1
  %r = add i32 %n, 1
  ret i32 %r }
define i64 @r2_i64(i64 noundef %x, i64 noundef %y) { entry: %nx = xor i64 -1, %x
  %ny = xor i64 -1, %y
  %s = add i64 %ny, %nx
  %n = xor i64 -1, %s
  %r = add i64 1, %n
  ret i64 %r }

define i8 @r3_i8(i8 noundef %x, i8 noundef %y) { entry: %nx = xor i8 %x, -1
  %ny = xor i8 -1, %y
  %p = add i8 %ny, %nx
  %s = add i8 2, %p
  %r = sub i8 0, %s
  ret i8 %r }
define i32 @r3_i32(i32 noundef %x, i32 noundef %y) { entry: %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %p = add i32 %nx, %ny
  %s = add i32 %p, 2
  %r = sub i32 0, %s
  ret i32 %r }
define i64 @r3_i64(i64 noundef %x, i64 noundef %y) { entry: %nx = xor i64 -1, %x
  %ny = xor i64 %y, -1
  %p = add i64 %ny, %nx
  %s = add i64 2, %p
  %r = sub i64 0, %s
  ret i64 %r }

define i8 @r4_i8(i8 noundef %x, i8 noundef %y) { entry: %nx = xor i8 %x, -1
  %ny = xor i8 -1, %y
  %fo = or i8 %ny, %nx
  %f = xor i8 -1, %fo
  %ny2 = xor i8 %y, -1
  %so = or i8 %ny2, %x
  %s = xor i8 %so, -1
  %a = add i8 %s, %f
  %r = add i8 1, %a
  ret i8 %r }
define i32 @r4_i32(i32 noundef %x, i32 noundef %y) { entry: %nx = xor i32 %x, -1
  %ny = xor i32 %y, -1
  %fo = or i32 %nx, %ny
  %f = xor i32 %fo, -1
  %ny2 = xor i32 %y, -1
  %so = or i32 %x, %ny2
  %s = xor i32 %so, -1
  %a = add i32 %f, %s
  %r = add i32 %a, 1
  ret i32 %r }
define i64 @r4_i64(i64 noundef %x, i64 noundef %y) { entry: %nx = xor i64 -1, %x
  %ny = xor i64 -1, %y
  %fo = or i64 %ny, %nx
  %f = xor i64 -1, %fo
  %ny2 = xor i64 -1, %y
  %so = or i64 %ny2, %x
  %s = xor i64 -1, %so
  %a = add i64 %s, %f
  %r = add i64 1, %a
  ret i64 %r }

define i32 @negative_flags(i32 noundef %x, i32 noundef %y) { entry:
  %a = and i32 %x, %y
  %o = or i32 %x, %y
  %r = add nsw i32 %a, %o
  ret i32 %r }
define i32 @negative_different_ssa(i32 noundef %x, i32 noundef %y, i32 noundef %z) { entry:
  %a = and i32 %x, %y
  %o = or i32 %x, %z
  %r = add i32 %a, %o
  ret i32 %r }
define i32 @negative_cast(i8 noundef %x, i8 noundef %y) { entry:
  %xx = zext i8 %x to i32
  %yy = zext i8 %y to i32
  %a = and i32 %xx, %yy
  %o = or i32 %xx, %yy
  %r = add i32 %a, %o
  ret i32 %r }
define i8 @negative_undef(i8 noundef %y) { entry:
  %a = and i8 undef, %y
  %o = or i8 undef, %y
  %r = add i8 %a, %o
  ret i8 %r }
define i8 @negative_poison_flag_leaf(i8 noundef %x, i8 noundef %y) { entry:
  %p = add nsw i8 %x, %y
  %a = and i8 %p, %y
  %o = or i8 %p, %y
  %r = add i8 %a, %o
  ret i8 %r }
define i8 @negative_freeze(i8 noundef %x, i8 noundef %y) { entry:
  %f = freeze i8 %x
  %a = and i8 %f, %y
  %o = or i8 %f, %y
  %r = add i8 %a, %o
  ret i8 %r }
define <4 x i8> @negative_vector(<4 x i8> %x, <4 x i8> %y) { entry:
  %a = and <4 x i8> %x, %y
  %o = or <4 x i8> %x, %y
  %r = add <4 x i8> %a, %o
  ret <4 x i8> %r }
@volatile_source = global i8 0
declare i8 @opaque_source()
define i8 @negative_volatile(i8 noundef %y) { entry:
  %x = load volatile i8, ptr @volatile_source
  %a = and i8 %x, %y
  %o = or i8 %x, %y
  %r = add i8 %a, %o
  ret i8 %r }
define i8 @negative_call(i8 noundef %y) { entry:
  %x = call i8 @opaque_source()
  %a = and i8 %x, %y
  %o = or i8 %x, %y
  %r = add i8 %a, %o
  ret i8 %r }

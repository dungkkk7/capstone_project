; Exact LLVM ports of Chernobog Xor_OllvmRule_1..3.  Chernobog commutes every
; bitwise node while matching and selects the first registered rule.  Rule 1
; is registered before Rule 2, so both equivalent XNOR root orderings belong
; to Rule 1 attribution; Rule 2 must receive no direct hit.

define i8 @r1_i8(i8 noundef %x, i8 noundef %y) { entry:
  %nx = xor i8 -1, %x
  %l = or i8 %y, %nx
  %ny = xor i8 %y, -1
  %r = or i8 %x, %ny
  %z = and i8 %l, %r
  ret i8 %z }
define i32 @r1_i32(i32 noundef %x, i32 noundef %y) { entry:
  %nx = xor i32 %x, -1
  %l = or i32 %nx, %y
  %ny = xor i32 -1, %y
  %r = or i32 %ny, %x
  %z = and i32 %l, %r
  ret i32 %z }
define i64 @r1_i64(i64 noundef %x, i64 noundef %y) { entry:
  %nx = xor i64 -1, %x
  %l = or i64 %nx, %y
  %ny = xor i64 %y, -1
  %r = or i64 %x, %ny
  %z = and i64 %l, %r
  ret i64 %z }

define i8 @r2_i8(i8 noundef %x, i8 noundef %y) { entry:
  %ny = xor i8 %y, -1
  %l = or i8 %ny, %x
  %nx = xor i8 -1, %x
  %r = or i8 %y, %nx
  %z = and i8 %l, %r
  ret i8 %z }
define i32 @r2_i32(i32 noundef %x, i32 noundef %y) { entry:
  %ny = xor i32 -1, %y
  %l = or i32 %x, %ny
  %nx = xor i32 %x, -1
  %r = or i32 %nx, %y
  %z = and i32 %l, %r
  ret i32 %z }
define i64 @r2_i64(i64 noundef %x, i64 noundef %y) { entry:
  %ny = xor i64 %y, -1
  %l = or i64 %ny, %x
  %nx = xor i64 -1, %x
  %r = or i64 %y, %nx
  %z = and i64 %l, %r
  ret i64 %z }

define i8 @r3_i8(i8 noundef %x, i8 noundef %y) { entry:
  %nx = xor i8 -1, %x
  %ny = xor i8 %y, -1
  %na = and i8 %ny, %nx
  %l = xor i8 %na, -1
  %a = and i8 %y, %x
  %r = xor i8 -1, %a
  %z = and i8 %l, %r
  ret i8 %z }
define i32 @r3_i32(i32 noundef %x, i32 noundef %y) { entry:
  %nx = xor i32 %x, -1
  %ny = xor i32 -1, %y
  %na = and i32 %nx, %ny
  %l = xor i32 %na, -1
  %a = and i32 %x, %y
  %r = xor i32 -1, %a
  %z = and i32 %l, %r
  ret i32 %z }
define i64 @r3_i64(i64 noundef %x, i64 noundef %y) { entry:
  %nx = xor i64 -1, %x
  %ny = xor i64 %y, -1
  %na = and i64 %ny, %nx
  %l = xor i64 -1, %na
  %a = and i64 %y, %x
  %r = xor i64 %a, -1
  %z = and i64 %r, %l
  ret i64 %z }

define i32 @negative_flags(i32 noundef %x, i32 noundef %y) { entry:
  ; Do not use add nsw x, 0 here: LLVM may legally erase that identity before
  ; a later catalog sweep, which would no longer test flags at all.
  %flagged = add nsw i32 %x, 1
  %nx = xor i32 %flagged, -1
  %l = or i32 %nx, %y
  %ny = xor i32 %y, -1
  %r = or i32 %flagged, %ny
  %z = and i32 %l, %r
  ret i32 %z }
define i32 @negative_different_ssa(i32 noundef %x, i32 noundef %y, i32 noundef %z) { entry:
  %nx = xor i32 %x, -1
  %l = or i32 %nx, %y
  %nz = xor i32 %z, -1
  %r = or i32 %x, %nz
  %v = and i32 %l, %r
  ret i32 %v }
define i32 @negative_cast(i8 noundef %x, i8 noundef %y) { entry:
  %xx = zext i8 %x to i32
  %yy = zext i8 %y to i32
  %nx = xor i32 %xx, -1
  %l = or i32 %nx, %yy
  %ny = xor i32 %yy, -1
  %r = or i32 %xx, %ny
  %z = and i32 %l, %r
  ret i32 %z }
define i8 @negative_undef(i8 noundef %y) { entry:
  %nx = xor i8 undef, -1
  %l = or i8 %nx, %y
  %ny = xor i8 %y, -1
  %r = or i8 undef, %ny
  %z = and i8 %l, %r
  ret i8 %z }
define i8 @negative_poison(i8 noundef %x, i8 noundef %y) { entry:
  %p = add nsw i8 %x, %y
  %nx = xor i8 %p, -1
  %l = or i8 %nx, %y
  %ny = xor i8 %y, -1
  %r = or i8 %p, %ny
  %z = and i8 %l, %r
  ret i8 %z }
define i8 @negative_freeze(i8 %x, i8 noundef %y) { entry:
  %f = freeze i8 %x
  %nx = xor i8 %f, -1
  %l = or i8 %nx, %y
  %ny = xor i8 %y, -1
  %r = or i8 %f, %ny
  %z = and i8 %l, %r
  ret i8 %z }
define <4 x i8> @negative_vector(<4 x i8> %x, <4 x i8> %y) { entry:
  %nx = xor <4 x i8> %x, <i8 -1, i8 -1, i8 -1, i8 -1>
  %l = or <4 x i8> %nx, %y
  %ny = xor <4 x i8> %y, <i8 -1, i8 -1, i8 -1, i8 -1>
  %r = or <4 x i8> %x, %ny
  %z = and <4 x i8> %l, %r
  ret <4 x i8> %z }
@volatile_source = global i8 0
declare i8 @opaque_source() #0
define i8 @side_effect_volatile(i8 noundef %y) { entry:
  %x = load volatile i8, ptr @volatile_source
  %nx = xor i8 %x, -1
  %l = or i8 %nx, %y
  %ny = xor i8 %y, -1
  %r = or i8 %x, %ny
  %z = and i8 %l, %r
  ret i8 %z }
define i8 @side_effect_call(i8 noundef %y) { entry:
  %x = call noundef i8 @opaque_source()
  %nx = xor i8 %x, -1
  %l = or i8 %nx, %y
  %ny = xor i8 %y, -1
  %r = or i8 %x, %ny
  %z = and i8 %l, %r
  ret i8 %z }
attributes #0 = { nounwind }

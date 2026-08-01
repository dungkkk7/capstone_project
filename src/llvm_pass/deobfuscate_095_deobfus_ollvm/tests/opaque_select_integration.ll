; Real-shaped lifted form: opaque predicates are values feeding select, not br.
; This mirrors the constant/state selects emitted by the dataset lifter.
attributes #0 = { noinline optnone }

define i32 @select_dataset_mba(i32 noundef %x, i1 noundef %cond) #0 {
  %not = xor i32 %x, -1
  %mul = mul i32 %x, %not
  %low = and i32 %mul, 1
  %wide = zext i1 %cond to i32
  %opaque = icmp ugt i32 %low, %wide
  %v = select i1 %opaque, i32 7, i32 -7
  ret i32 %v
}

; These artifacts previously passed strict verification despite preserving
; the CPU-state slot ABI, fake stack, guest-address casts, raw code bytes and
; recovered guest-range metadata.
target triple = "x86_64-pc-linux-gnu"

%sub_main.state_result = type { i64, i64 }
@addr_carrier_cand_401000 = internal constant [4 x i8] c"\90\90\C3\00", !brighten.guest.range !0

define %sub_main.state_result @sub_main(ptr %native_stack, i64 %state_in_2216) {
entry:
  %native.ptr = inttoptr i64 %state_in_2216 to ptr
  %value = load i64, ptr %native.ptr
  %r0 = insertvalue %sub_main.state_result zeroinitializer, i64 %value, 0
  %r1 = insertvalue %sub_main.state_result %r0, i64 %state_in_2216, 1
  ret %sub_main.state_result %r1
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %native_stack_storage = alloca i8, i64 262144, align 16
  %guest_address = ptrtoint ptr @addr_carrier_cand_401000 to i64
  %result = call %sub_main.state_result @sub_main(ptr %native_stack_storage, i64 %guest_address)
  %value = extractvalue %sub_main.state_result %result, 0
  %exit = trunc i64 %value to i32
  ret i32 %exit
}

!0 = !{i64 4198400, i64 4198404}

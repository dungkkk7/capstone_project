from pathlib import Path

from tools.llvm_to_c import transpile_llvm_ir_to_c


def render(tmp_path: Path, ir: str) -> str:
    source = tmp_path / "input.ll"
    output = tmp_path / "output.c"
    source.write_text(ir, encoding="utf-8")
    transpile_llvm_ir_to_c(str(source), str(output))
    return output.read_text(encoding="utf-8")


def test_renderer_preserves_widths_signatures_labels_and_unknown_ops(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@message = private constant [4 x i8] c"ok\0A\00"

declare void @sink(i16)

define i32 @main(i32 %0, ptr %argv) {
entry:
  %words = alloca [4 x i16], align 8
  %slot = getelementptr inbounds [4 x i16], ptr %words, i64 0, i64 2
  store i16 41, ptr %slot, align 2
  %loaded = load i16, ptr %slot, align 2
  %next = add i16 %loaded, 1
  call void @sink(i16 %next)
  fence seq_cst
  ret i32 0
}
''',
    )

    assert 'static const char message[] = "ok\\n";' in pseudocode
    assert "uint32_t main(uint32_t v0, void * argv)" in pseudocode
    assert "uint16_t words[4];" in pseudocode
    assert "store<uint16_t>(slot, 41);" in pseudocode
    assert "uint16_t loaded = load<uint16_t>(slot);" in pseudocode
    assert "uint16_t next = loaded + 1;" in pseudocode
    assert "sink(next);" in pseudocode
    assert "/* LLVM: fence seq_cst */" in pseudocode
    assert "uint64_t 0" not in pseudocode
    assert "@message" not in pseudocode


def test_phi_values_are_parallel_copied_on_their_exact_cfg_edges(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
define i32 @choose(i1 %condition, i32 %left, i32 %right) {
entry:
  br i1 %condition, label %merge, label %other

other:                                            ; preds = %entry
  br label %merge

merge:                                            ; preds = %other, %entry
  %value = phi i32 [ %left, %entry ], [ %right, %other ]
  ret i32 %value
}
''',
    )

    assert "uint32_t value; /* control-flow value */" in pseudocode
    assert "value = left;" in pseudocode
    assert "value = right;" in pseudocode
    assert "goto " not in pseudocode
    assert "bb_merge:" not in pseudocode


def test_multiple_phi_values_use_explicit_simultaneous_assignment(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
define i32 @swap_loop(i1 %again, i32 %left, i32 %right) {
entry:
  br label %loop

loop:
  %a = phi i32 [ %left, %entry ], [ %b, %loop ]
  %b = phi i32 [ %right, %entry ], [ %a, %loop ]
  br i1 %again, label %loop, label %exit

exit:
  %result = add i32 %a, %b
  ret i32 %result
}
''',
    )

    assert "(a, b) = (left, right); /* simultaneous PHI transfer */" in pseudocode
    assert "(a, b) = (b, a); /* simultaneous PHI transfer */" in pseudocode
    assert "phi_tmp_" not in pseudocode


def test_multiline_switch_and_indirect_calls_are_semantic_not_raw_llvm(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
define i32 @dispatch(ptr %callback, i32 %state) {
entry:
  switch i32 %state, label %fallback [
    i32 1, label %one
    i32 2, label %two
  ]

one:                                              ; preds = %entry
  %a = call i32 %callback(i32 10)
  ret i32 %a

two:                                              ; preds = %entry
  ret i32 20

fallback:                                         ; preds = %entry
  ret i32 -1
}
''',
    )

    assert "switch (state)" in pseudocode
    assert "case 1:" in pseudocode
    assert "goto bb_one;" in pseudocode
    assert "case 2:" in pseudocode
    assert "default:" in pseudocode
    assert "uint32_t a = callback(10);" in pseudocode
    assert "/* LLVM: switch" not in pseudocode


def test_call_result_used_only_by_phi_is_not_discarded(tmp_path: Path) -> None:
    pseudocode = render(
        tmp_path,
        r'''
declare i32 @produce()

define i32 @keep_call_result(i1 %condition) {
entry:
  br i1 %condition, label %called, label %empty

called:
  %result = call i32 @produce()
  br label %merge

empty:
  br label %merge

merge:
  %value = phi i32 [ %result, %called ], [ 0, %empty ]
  ret i32 %value
}
''',
    )

    assert "uint32_t result = produce();" in pseudocode
    assert "value = result;" in pseudocode


def test_constant_expression_geps_remain_complete_load_store_operands(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@image = internal global [32 x i8] zeroinitializer

define i32 @access_image() {
entry:
  %value = load i32, ptr getelementptr inbounds (i8, ptr @image, i64 12), align 4
  store i32 %value, ptr getelementptr inbounds (i8, ptr @image, i64 16), align 4
  ret i32 %value
}
''',
    )

    assert (
        "uint32_t value = "
        "load<uint32_t>(get_element_pointer_inbounds(image, 12));"
        in pseudocode
    )
    assert (
        "store<uint32_t>(get_element_pointer_inbounds(image, 16), value);"
        in pseudocode
    )
    assert "getelementptr inbounds" not in pseudocode


def test_scalar_globals_are_declared_with_exact_types_and_initializers(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@counter = internal unnamed_addr global i64 7, align 8
@enabled = private constant i1 true
@input_stream = external global ptr, align 8

define i64 @read_counter() {
entry:
  %value = load i64, ptr @counter, align 8
  ret i64 %value
}
''',
    )

    assert "static uint64_t counter = 7;" in pseudocode
    assert "static const bool enabled = true;" in pseudocode
    assert "extern void * input_stream;" in pseudocode
    assert "load<uint64_t>(counter)" in pseudocode


def test_residual_aliases_are_declared_as_exact_shared_backing_views(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@native_residual_image = internal global [64 x i8] zeroinitializer
@native_scalar_1008 = internal alias i32, getelementptr (i8, ptr @native_residual_image, i64 8)
@native_scalar_1013 = internal alias i8, getelementptr (i8, ptr @native_residual_image, i64 19)
@native_object_1010 = internal alias i8, getelementptr (i8, ptr @native_residual_image, i64 16)

define i32 @read_scalar() {
entry:
  %value = load i32, ptr @native_scalar_1008, align 4
  %element = getelementptr i8, ptr @native_object_1010, i64 3
  %byte = load i8, ptr %element, align 1
  %wide = zext i8 %byte to i32
  %result = add i32 %value, %wide
  ret i32 %result
}
''',
    )

    assert (
        "extern uint32_t native_scalar_1008; "
        "/* exact view into shared residual backing */"
    ) in pseudocode
    assert (
        "extern uint8_t native_object_1010[]; "
        "/* exact view into shared residual backing */"
    ) in pseudocode
    assert (
        "extern uint8_t native_scalar_1013; "
        "/* exact view into shared residual backing */"
    ) in pseudocode
    assert "load<uint32_t>(native_scalar_1008)" in pseudocode
    assert "get_element_pointer(native_object_1010, 3)" in pseudocode


def test_modern_samesign_icmp_is_rendered_semantically(tmp_path: Path) -> None:
    pseudocode = render(
        tmp_path,
        r'''
define i1 @bounded_index(i64 %index) {
entry:
  %inside = icmp samesign ult i64 %index, 100
  ret i1 %inside
}
''',
    )

    assert "bool inside = index < 100;" in pseudocode
    assert "operands have the same sign bit" in pseudocode
    assert "/* LLVM:" not in pseudocode


def test_canonical_nested_loops_are_structured_without_guessing(tmp_path: Path) -> None:
    pseudocode = render(
        tmp_path,
        r'''
define i32 @nested(i1 %run, i32 %limit) {
entry:
  br i1 %run, label %outer, label %exit

outer:
  %i = phi i32 [ 0, %entry ], [ %next_i, %latch ]
  %count = phi i32 [ 0, %entry ], [ %next_count, %latch ]
  br label %inner

inner:
  %j = phi i32 [ 0, %outer ], [ %next_j, %inner ]
  %inner_count = phi i32 [ %count, %outer ], [ %incremented, %inner ]
  %incremented = add i32 %inner_count, 1
  %next_j = add i32 %j, 1
  %inner_done = icmp sgt i32 %next_j, %limit
  br i1 %inner_done, label %latch, label %inner

latch:
  %next_count = add i32 %inner_count, 1
  %next_i = add i32 %i, 1
  %outer_done = icmp sgt i32 %next_i, %limit
  br i1 %outer_done, label %exit, label %outer

exit:
  %result = phi i32 [ 0, %entry ], [ %next_count, %latch ]
  ret i32 %result
}
''',
    )

    assert pseudocode.count("while (true)") == 2
    assert "outer recovered loop" in pseudocode
    assert "inner recovered loop" in pseudocode
    assert pseudocode.count("break;") == 2
    assert "goto " not in pseudocode
    assert "/* loop-carried value */" in pseudocode


def test_reducible_sequential_loops_and_diamond_are_structured(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
declare void @consume(i32)

define i32 @pipeline(i1 %skip, i1 %copy) {
entry:
  br i1 %skip, label %merge, label %input

input:
  %i = phi i32 [ 0, %entry ], [ %next, %input ]
  call void @consume(i32 %i)
  %next = add i32 %i, 1
  %done = icmp eq i32 %next, 10
  br i1 %done, label %prepare, label %input

prepare:
  br i1 %copy, label %copy_block, label %cleanup

copy_block:
  call void @consume(i32 12)
  br label %cleanup

cleanup:
  br label %merge

merge:
  %result = phi i32 [ 0, %entry ], [ 12, %cleanup ]
  br label %check

body:
  call void @consume(i32 %j)
  %inc = add i32 %j, 1
  br label %check

check:
  %j = phi i32 [ 0, %merge ], [ %inc, %body ]
  %again = icmp slt i32 %j, 3
  br i1 %again, label %body, label %exit

exit:
  ret i32 %result
}
''',
    )

    assert pseudocode.count("while (") == 2
    assert "goto " not in pseudocode
    assert "\nbb_" not in pseudocode
    assert "if (copy)" in pseudocode
    assert "result = 0;" in pseudocode
    assert "result = 12;" in pseudocode


def test_closed_shared_acyclic_region_is_duplicated_without_gotos(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
declare void @prepare()
declare void @consume(i32)

define i32 @side_entry_diamond(i1 %direct, i1 %use_shared) {
entry:
  br i1 %direct, label %shared, label %choose

choose:
  call void @prepare()
  br i1 %use_shared, label %shared, label %join

shared:
  %shared_value = phi i32 [ 7, %entry ], [ 8, %choose ]
  call void @consume(i32 %shared_value)
  br label %join

join:
  %result = phi i32 [ %shared_value, %shared ], [ 0, %choose ]
  ret i32 %result
}
''',
    )

    assert "if (direct)" in pseudocode
    assert "prepare();" in pseudocode
    assert pseudocode.count("consume(shared_value);") == 2
    assert "shared_value = 7;" in pseudocode
    assert "shared_value = 8;" in pseudocode
    assert pseudocode.count("result = shared_value;") == 2
    assert "result = 0;" in pseudocode
    assert "goto " not in pseudocode
    assert "\nbb_" not in pseudocode


def test_nested_natural_loops_with_internal_diamond_are_structured(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
declare void @consume(i32)

define i32 @nested_diamond(i32 %limit, i1 %choose_left) {
entry:
  br label %outer

outer:
  %i = phi i32 [ 0, %entry ], [ %next_i, %outer_latch ]
  %outer_more = icmp slt i32 %i, %limit
  br i1 %outer_more, label %inner, label %exit

inner:
  %j = phi i32 [ 0, %outer ], [ %next_j, %inner_latch ]
  %inner_more = icmp slt i32 %j, %limit
  br i1 %inner_more, label %choose, label %outer_latch

choose:
  br i1 %choose_left, label %left, label %right

left:
  call void @consume(i32 %j)
  br label %inner_latch

right:
  call void @consume(i32 %i)
  br label %inner_latch

inner_latch:
  %next_j = add i32 %j, 1
  br label %inner

outer_latch:
  %next_i = add i32 %i, 1
  br label %outer

exit:
  ret i32 %i
}
''',
    )

    assert pseudocode.count("while (") == 2
    assert "if (choose_left)" in pseudocode
    assert "consume(j);" in pseudocode
    assert "consume(i);" in pseudocode
    assert "goto " not in pseudocode
    assert "\nbb_" not in pseudocode


def test_rotated_loop_with_optional_exit_test_and_error_arm_is_structured(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
define i32 @optional_exit_test(i1 %skip_test, i1 %bad) {
entry:
  br label %header

header:
  %value = phi i32 [ 0, %entry ], [ %next, %latch ]
  br i1 %skip_test, label %body, label %exit_test

exit_test:
  %done = icmp eq i32 %value, 10
  br i1 %done, label %exit, label %body

body:
  br i1 %bad, label %error, label %latch

latch:
  %next = add i32 %value, 1
  br label %header

error:
  unreachable

exit:
  ret i32 %value
}
''',
    )

    assert "while (true)" in pseudocode
    assert "break;" in pseudocode
    assert "unreachable();" in pseudocode
    assert "goto " not in pseudocode
    assert "\nbb_" not in pseudocode


def test_production_deobfuscation_fixture_has_no_invalid_llvm_identifiers(
    tmp_path: Path,
) -> None:
    root = Path(__file__).resolve().parents[1]
    source = (
        root
        / "src/llvm_pass/deobfuscate_095_deobfus_ollvm/tests/production_cases.ll"
    )
    output = tmp_path / "production.c"
    transpile_llvm_ir_to_c(str(source), str(output))
    pseudocode = output.read_text(encoding="utf-8")

    assert "uint32_t r = fp(x);" in pseudocode
    assert "uint8_t frame[128];" in pseudocode
    assert "switch (state)" in pseudocode
    assert "uint64_t 0" not in pseudocode
    assert "@fmt" not in pseudocode
    assert "%state" not in pseudocode
    assert "/* LLVM:" not in pseudocode


def test_closed_guest_address_range_chains_are_rendered_as_one_exact_mapping(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [4096 x i8] zeroinitializer
@rodata = internal constant [64 x i8] zeroinitializer

define i32 @direct(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %data_offset = add i64 %address, -4096
  %in_data = icmp ult i64 %data_offset, 4096
  %data_pointer = getelementptr i8, ptr getelementptr (i8, ptr @data, i64 -4096), i64 %address
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add i64 %address, -8192
  %in_rodata = icmp ult i64 %rodata_offset, 64
  %rodata_pointer = getelementptr i8, ptr getelementptr (i8, ptr @rodata, i64 -8192), i64 %address
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  %value = load i32, ptr %resolved
  ret i32 %value
}

define void @affine(i64 %index, i64 %value) {
entry:
  %scaled = shl i64 %index, 4
  %guest = add i64 %scaled, 4444792
  %fallback = inttoptr i64 %guest to ptr
  %data_offset = add i64 %scaled, 213624
  %in_data = icmp ult i64 %data_offset, 1030192
  %data_pointer = getelementptr i8, ptr getelementptr (i8, ptr @data, i64 213624), i64 %scaled
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add i64 %scaled, 217720
  %in_rodata = icmp ult i64 %rodata_offset, 672
  %rodata_pointer = getelementptr i8, ptr getelementptr (i8, ptr @rodata, i64 217720), i64 %scaled
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  store i64 %value, ptr %resolved
  ret void
}
''',
    )

    assert "resolve_guest_or_native_address(address, recovered_address_map)" in pseudocode
    assert "resolve_guest_or_native_address(guest, recovered_address_map_1)" in pseudocode
    assert "recovered_range(rodata, 8192, 64)," in pseudocode
    assert "recovered_range(data, 4096, 4096)," in pseudocode
    assert "recovered_range(rodata, 4227072, 672)," in pseudocode
    assert "recovered_range(data, 4231168, 1030192)," in pseudocode
    assert "Ranges are tried in order" in pseudocode
    assert "integer_to_pointer" not in pseudocode
    assert "data_offset" not in pseudocode
    assert "rodata_offset" not in pseudocode


def test_exact_outlined_address_resolver_is_inlined_at_module_calls(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [4096 x i8] zeroinitializer
@rodata = internal constant [64 x i8] zeroinitializer

define i32 @read(i64 %address) {
entry:
  %resolved = call ptr @opaque_mapper(i64 %address)
  %value = load i32, ptr %resolved
  ret i32 %value
}

define internal ptr @opaque_mapper(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %data_offset = add i64 %address, -4096
  %in_data = icmp ult i64 %data_offset, 4096
  %data_pointer = getelementptr i8, ptr @data, i64 %data_offset
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add i64 %address, -8192
  %in_rodata = icmp ult i64 %rodata_offset, 64
  %rodata_pointer = getelementptr i8, ptr @rodata, i64 %rodata_offset
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  ret ptr %resolved
}
''',
    )

    assert (
        "resolve_guest_or_native_address(address, recovered_address_map)"
        in pseudocode
    )
    assert "opaque_mapper(" not in pseudocode
    assert "integer_to_pointer" not in pseudocode


def test_address_taken_outlined_resolver_remains_explicit(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [4096 x i8] zeroinitializer
@rodata = internal constant [64 x i8] zeroinitializer
@mapper_pointer = internal global ptr @observed_mapper

define ptr @observed_mapper(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %data_offset = add i64 %address, -4096
  %in_data = icmp ult i64 %data_offset, 4096
  %data_pointer = getelementptr i8, ptr @data, i64 %data_offset
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add i64 %address, -8192
  %in_rodata = icmp ult i64 %rodata_offset, 64
  %rodata_pointer = getelementptr i8, ptr @rodata, i64 %rodata_offset
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  ret ptr %resolved
}
''',
    )

    assert "void * observed_mapper(uint64_t address)" in pseudocode
    assert "static void * mapper_pointer = observed_mapper;" in pseudocode
    assert "return resolved;" in pseudocode


def test_public_exact_outlined_resolver_remains_in_the_interface(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [4096 x i8] zeroinitializer
@rodata = internal constant [64 x i8] zeroinitializer

define ptr @call_public(i64 %address) {
entry:
  %resolved = call ptr @public_mapper(i64 %address)
  ret ptr %resolved
}

define ptr @public_mapper(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %data_offset = add i64 %address, -4096
  %in_data = icmp ult i64 %data_offset, 4096
  %data_pointer = getelementptr i8, ptr @data, i64 %data_offset
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add i64 %address, -8192
  %in_rodata = icmp ult i64 %rodata_offset, 64
  %rodata_pointer = getelementptr i8, ptr @rodata, i64 %rodata_offset
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  ret ptr %resolved
}
''',
    )

    assert "public_mapper(address)" in pseudocode
    assert "void * public_mapper(uint64_t address)" in pseudocode


def test_flagged_affine_outlined_resolver_preserves_poison_contract(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [4096 x i8] zeroinitializer
@rodata = internal constant [64 x i8] zeroinitializer

define ptr @use_mapper(i64 %root, i64 %guest) {
entry:
  %resolved = call ptr @flagged_mapper(i64 %root, i64 %guest)
  ret ptr %resolved
}

define internal ptr @flagged_mapper.1(i64 %value) {
entry:
  %pointer = inttoptr i64 %value to ptr
  ret ptr %pointer
}

define internal ptr @flagged_mapper(i64 %root, i64 %guest) {
entry:
  %fallback = inttoptr i64 %guest to ptr
  %data_offset = add nsw i64 %root, 8
  %in_data = icmp ult i64 %data_offset, 4096
  %data_pointer = getelementptr i8, ptr getelementptr inbounds nuw (i8, ptr @data, i64 8), i64 %root
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add nsw i64 %root, 16
  %in_rodata = icmp ult i64 %rodata_offset, 64
  %rodata_pointer = getelementptr i8, ptr getelementptr (i8, ptr @rodata, i64 16), i64 %root
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  ret ptr %resolved
}
''',
    )

    assert (
        "resolve_affine_guest_or_native_address("
        "root, guest, recovered_affine_address_map)" in pseudocode
    )
    assert "recovered_affine_range(data, 8, 4096," in pseudocode
    assert "add_guarantees(nsw), gep_guarantees(inbounds, nuw)" in pseudocode
    assert "flagged_mapper(" not in pseudocode


def test_guest_address_range_chain_is_not_folded_when_an_intermediate_escapes(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [4096 x i8] zeroinitializer
@rodata = internal constant [64 x i8] zeroinitializer

declare void @observe(i64)

define i32 @escaped(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %data_offset = add i64 %address, -4096
  %in_data = icmp ult i64 %data_offset, 4096
  %data_pointer = getelementptr i8, ptr getelementptr (i8, ptr @data, i64 -4096), i64 %address
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add i64 %address, -8192
  %in_rodata = icmp ult i64 %rodata_offset, 64
  %rodata_pointer = getelementptr i8, ptr getelementptr (i8, ptr @rodata, i64 -8192), i64 %address
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  call void @observe(i64 %data_offset)
  %value = load i32, ptr %resolved
  ret i32 %value
}
''',
    )

    assert "resolve_guest_or_native_address" not in pseudocode
    assert "uint64_t data_offset = address - 4096;" in pseudocode
    assert "void * fallback = integer_to_pointer<void *>(address);" in pseudocode
    assert "observe(data_offset);" in pseudocode


def test_poison_generating_address_flags_are_preserved_not_folded(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [4096 x i8] zeroinitializer
@rodata = internal constant [64 x i8] zeroinitializer

define i32 @flagged(i64 %address) {
entry:
  %fallback = inttoptr i64 %address to ptr
  %data_offset = add nsw i64 %address, -4096
  %in_data = icmp ult i64 %data_offset, 4096
  %data_pointer = getelementptr i8, ptr getelementptr (i8, ptr @data, i64 -4096), i64 %address
  %data_or_native = select i1 %in_data, ptr %data_pointer, ptr %fallback
  %rodata_offset = add i64 %address, -8192
  %in_rodata = icmp ult i64 %rodata_offset, 64
  %rodata_pointer = getelementptr i8, ptr getelementptr (i8, ptr @rodata, i64 -8192), i64 %address
  %resolved = select i1 %in_rodata, ptr %rodata_pointer, ptr %data_or_native
  %value = load i32, ptr %resolved
  ret i32 %value
}
''',
    )

    assert "resolve_guest_or_native_address" not in pseudocode
    assert "uint64_t data_offset = address - 4096; /* no signed wrap */" in pseudocode
    assert "void * fallback = integer_to_pointer<void *>(address);" in pseudocode


def test_nested_gep_poison_guarantees_are_part_of_the_helper_name(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
@data = internal global [16 x i8] zeroinitializer

define ptr @flagged_gep(i64 %index) {
entry:
  %pointer = getelementptr inbounds nuw i8, ptr getelementptr inbounds nuw (i8, ptr @data, i64 8), i64 %index
  ret ptr %pointer
}
''',
    )

    assert (
        "get_element_pointer_inbounds_nuw("
        "get_element_pointer_inbounds_nuw(data, 8), index)"
    ) in pseudocode
    assert "LLVM GEP guarantees" not in pseudocode


def test_multi_exit_inner_loop_with_closed_exit_path_is_structured(
    tmp_path: Path,
) -> None:
    pseudocode = render(
        tmp_path,
        r'''
define i32 @multi_exit_loop(i32 %limit, i1 %skip) {
entry:
  br label %outer

outer:
  %i = phi i32 [ 0, %entry ], [ %next, %join ]
  %keep_going = icmp slt i32 %i, %limit
  br i1 %keep_going, label %inner, label %exit

inner:
  %again = phi i1 [ true, %outer ], [ false, %latch ]
  br i1 %skip, label %exit_path, label %latch

latch:
  br i1 %again, label %inner, label %join

exit_path:
  call void @observe(i32 %i)
  br label %join

join:
  %next = add i32 %i, 1
  br label %outer

exit:
  ret i32 %i
}

declare void @observe(i32)
''',
    )

    assert "while ((int32_t)i < (int32_t)limit)" in pseudocode
    assert pseudocode.count("while (true)") == 1
    assert "observe(i);" in pseudocode
    assert "break;" in pseudocode
    assert "continue;" in pseudocode
    assert "goto " not in pseudocode
    assert "\nbb_" not in pseudocode

import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from experiments.deobfuscation_metrics import (  # noqa: E402
    extract_binary_metrics,
    extract_c_metrics,
)
from experiments.ir_metrics import extract_ir_metrics  # noqa: E402


def test_ir_metrics_capture_deobfuscation_structure(tmp_path):
    ir = tmp_path / "program.ll"
    ir.write_text(
        """
@state = global i32 0
declare void @__remill_error()
define i32 @main() {
entry:
  %x = load i32, ptr @state
  %ok = icmp eq i32 %x, 0
  br i1 %ok, label %yes, label %no
yes:
  call void @__remill_error()
  ret i32 0
no:
  ret i32 1
}
""",
        encoding="utf-8",
    )

    metrics = extract_ir_metrics(ir)

    assert metrics["function_count"] == 1
    assert metrics["basic_block_count"] == 3
    assert metrics["cfg_edge_count"] == 2
    assert metrics["conditional_branch_count"] == 1
    assert metrics["helper_reference_count"] >= 2
    assert metrics["cyclomatic_complexity"] >= 2


def test_c_metrics_capture_residual_decompiler_artifacts(tmp_path):
    source = tmp_path / "candidate.c"
    source.write_text(
        """
int main(void) {
    int uVar1 = 0;
    if (uVar1) goto LAB_0010;
LAB_0010:
    return uVar1;
}
""",
        encoding="utf-8",
    )

    metrics = extract_c_metrics(source)

    assert metrics["function_count"] == 1
    assert metrics["goto_count"] == 1
    assert metrics["label_count"] == 1
    assert metrics["decompiler_artifact_count"] >= 2


def test_binary_metrics_are_format_agnostic(tmp_path):
    binary = tmp_path / "artifact.bin"
    binary.write_bytes(b"\x00\x00HELLO\x00" * 16)

    metrics = extract_binary_metrics(binary)

    assert metrics["size_bytes"] == 128
    assert metrics["printable_string_count"] == 16
    assert 0.0 <= metrics["entropy_bits_per_byte"] <= 8.0

from pathlib import Path
import subprocess
import sys

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DELIFT_DIR = (
    PROJECT_ROOT / "src" / "llvm_pass" / "brighten_100_delift_bundle"
)


def _resolver_heavy_ir(selects: int = 1200) -> str:
    definitions = "\n".join(
        f"  %s{index} = select i1 %cond, ptr %yes, ptr %no"
        for index in range(selects)
    )
    return (
        "define void @resolver(i1 %cond, ptr %yes, ptr %no) {\n"
        "entry:\n"
        f"{definitions}\n"
        f"  store i8 0, ptr %s{selects - 1}\n"
        "  ret void\n"
        "}\n"
    )


@pytest.mark.parametrize(
    "script_name",
    ["dedup_pointer_selects.py", "delift_storage.py"],
)
def test_pointer_select_dedup_is_linear_and_preserves_dominance(
    tmp_path, script_name
):
    source = tmp_path / "resolver.ll"
    output = tmp_path / f"{script_name}.ll"
    source.write_text(_resolver_heavy_ir())

    completed = subprocess.run(
        [sys.executable, str(DELIFT_DIR / script_name), str(source), str(output)],
        capture_output=True,
        text=True,
        timeout=5,
        check=True,
    )

    rewritten = output.read_text()
    assert "duplicate pointer selects removed: 1199" in completed.stdout
    assert rewritten.count(" = select i1 ") == 1
    assert "store i8 0, ptr %s0" in rewritten

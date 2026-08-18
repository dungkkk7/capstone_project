from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BUNDLE = (
    PROJECT_ROOT
    / "src"
    / "llvm_pass"
    / "brighten_100_delift_bundle"
    / "run_brighten_delift_pipeline.sh"
)


def test_bundle_preserves_and_checks_public_entrypoint() -> None:
    script = BUNDLE.read_text(encoding="utf-8")
    assert 'ENTRYPOINT_SYMBOL="${BRIGHTEN_ENTRYPOINT_SYMBOL:-main}"' in script
    assert '"-internalize-public-api-list=$ENTRYPOINT_SYMBOL"' in script
    assert '--report "$ENTRYPOINT_PRE_REPORT"' in script
    assert '--report "$ENTRYPOINT_FINAL_REPORT"' in script
    assert script.index("ENTRYPOINT_PRE_REPORT") < script.index("NATIVE_CLEANUP_PLUGIN")
    assert script.index("ENTRYPOINT_FINAL_REPORT") < script.index('CLANG_BIN=')


def test_bundle_removes_stale_release_artifacts_before_work() -> None:
    script = BUNDLE.read_text(encoding="utf-8")
    cleanup = 'rm -f   "$S1" "$S2" "$S3" "$S4" "$S5"   "$FINAL_LL" "$FINAL_O" "$FINAL_BIN"'
    assert cleanup in script
    assert script.index(cleanup) < script.index('-passes=verify "$INPUT"')

import sys
import time
import signal
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from fuzzing_equi_check.fuzzing import (  # noqa: E402
    check_equivalence,
    DEFAULT_EXECUTION_TIMEOUT,
    generate_structured_seed_inputs,
    is_seed_shape_compatible,
    is_inconclusive_pair,
    run_binary,
    seed_shape_rejection_reason,
    SemanticFuzzer,
)


class TimeoutSemanticsTests(unittest.TestCase):
    def test_default_execution_deadline_allows_normal_process_startup(self):
        self.assertEqual(DEFAULT_EXECUTION_TIMEOUT, 0.5)

    def test_shared_timeout_is_inconclusive_and_asymmetric_timeout_is_failure(self):
        shared = {"status": "timeout", "returncode": -1, "stdout": b"", "stderr": b""}
        success = {"status": "success", "returncode": 0, "stdout": b"", "stderr": b""}

        self.assertEqual(
            check_equivalence(shared, shared),
            (False, "Inconclusive shared timeout"),
        )
        self.assertFalse(check_equivalence(shared, success)[0])
        self.assertTrue(is_inconclusive_pair(shared, success))


class StructuredSeedMutationTests(unittest.TestCase):
    def test_case_seed_disables_afl_mutation_by_default(self):
        fuzzer = SemanticFuzzer.__new__(SemanticFuzzer)
        fuzzer.seed_inputs = [b"3\n1 2\n"]
        fuzzer.afl_cc = "/bin/true"
        fuzzer.afl_fuzz = "/bin/true"
        sentinel = {"mode": "exact-seed"}

        def fallback(*args, **kwargs):
            return sentinel

        fuzzer.run_differential_test_fallback = fallback
        with patch.dict("os.environ", {}, clear=True):
            result = fuzzer.run_differential_test(
                iterations=100,
                generator=lambda: ([], b"random"),
            )

        self.assertIs(result, sentinel)

    def test_afl_shape_filter_keeps_values_but_rejects_broken_counts_or_layout(self):
        seed = b"3\n0 7\n-1048576 0\n-3 5\n"

        self.assertTrue(is_seed_shape_compatible(b"3\n0 8\n-1048576 0\n-3 6\n", seed))
        self.assertFalse(is_seed_shape_compatible(b"999\n0 8\n-1048576 0\n-3 6\n", seed))
        self.assertFalse(is_seed_shape_compatible(b"3\n0 8 9\n-1048576 0\n-3 6\n", seed))

    def test_rejects_real_dataset_mutation_that_desynchronizes_record_count(self):
        seed = (
            b"1 3 3 1 3\n1 3 2000\n1 2 1000\n2 3 1000\n"
            b"2 3 3 1 3\n1 3 2300\n1 2 1000\n2 3 1200\n"
            b"0 0 0 0 0\n"
        )
        broken = seed.replace(b"1 3 3 1 3", b"1 3 1 1 3", 1)
        valid_value_mutation = seed.replace(b"2 3 1200", b"2 3 1199", 1)

        self.assertFalse(is_seed_shape_compatible(broken, seed))
        self.assertTrue(is_seed_shape_compatible(valid_value_mutation, seed))
        self.assertIn("structural_token_changed", seed_shape_rejection_reason(broken, seed))

    def test_mutates_single_scalar_seed(self):
        mutations = generate_structured_seed_inputs([b"35\n"], 10)

        self.assertGreater(len(mutations), 1)
        self.assertTrue(all(mutation.endswith(b"\n") for mutation in mutations))

    def test_preserves_record_shape_and_leading_count_tokens(self):
        seed = b"3\n0 7\n-1048576 0\n-3 5\n"
        mutations = generate_structured_seed_inputs([seed], 20)

        self.assertEqual(mutations[0], seed)
        self.assertGreater(len(mutations), 1)
        expected_leading_tokens = [b"3", b"0", b"-1048576", b"-3"]
        for mutation in mutations:
            self.assertEqual(mutation.count(b"\n"), seed.count(b"\n"))
            self.assertEqual(
                [line.split()[0] for line in mutation.splitlines()],
                expected_leading_tokens,
            )


class HardTimeoutTests(unittest.TestCase):
    def test_negative_returncode_is_reported_as_crash(self):
        result = run_binary(
            "/bin/sh",
            ["-c", "kill -TERM $$"],
            b"",
            timeout=0.1,
        )

        self.assertEqual(result["status"], "crash")
        self.assertEqual(result["returncode"], -signal.SIGTERM)
        self.assertEqual(result["signal"], signal.SIGTERM)

    @unittest.skipUnless(Path("/proc/self/status").exists(), "requires Linux procfs")
    def test_core_dumping_signal_is_reported_as_crash_at_deadline(self):
        started = time.perf_counter()
        result = run_binary(
            "/bin/sh",
            ["-c", "kill -SEGV $$"],
            b"",
            timeout=0.1,
        )
        elapsed = time.perf_counter() - started

        self.assertEqual(result["status"], "crash")
        self.assertEqual(result["returncode"], -signal.SIGSEGV)
        self.assertEqual(result["signal"], signal.SIGSEGV)
        self.assertLess(elapsed, 0.25)

    def test_kills_descendant_processes_at_deadline(self):
        started = time.perf_counter()
        result = run_binary(
            "/bin/sh",
            ["-c", "sleep 10 & wait"],
            b"",
            timeout=0.1,
        )
        elapsed = time.perf_counter() - started

        self.assertEqual(result["status"], "timeout")
        self.assertLess(elapsed, 0.5)


class AsymmetricCrashReportTests(unittest.TestCase):
    payload = b"crash-input\n"

    @staticmethod
    def _mock_execution(bin_path, args, stdin_data, timeout):
        if bin_path.endswith("f1.bin"):
            return {
                "status": "crash",
                "returncode": -signal.SIGSEGV,
                "signal": signal.SIGSEGV,
                "stdout": b"",
                "stderr": b"segmentation fault",
                "bin_path": bin_path,
                "elapsed": 0.001,
            }
        return {
            "status": "success",
            "returncode": 0,
            "stdout": b"ok\n",
            "stderr": b"",
            "bin_path": bin_path,
            "elapsed": 0.001,
        }

    def _assert_complete_crash_report(self, report):
        self.assertEqual(report["total_runs"], 1)
        self.assertEqual(report["mismatches"], 1)
        self.assertEqual(report["crashes"], {"bin1": 1, "bin2": 0, "both": 0})
        self.assertTrue(report["early_stopped"])
        self.assertEqual(len(report["mismatch_examples"]), 1)
        sample = report["mismatch_examples"][0]
        self.assertEqual(sample["stdin"], self.payload.decode())
        self.assertEqual(sample["prog1"]["status"], "crash")
        self.assertEqual(sample["prog1"]["returncode"], -signal.SIGSEGV)
        self.assertEqual(sample["prog1"]["signal"], signal.SIGSEGV)
        self.assertEqual(sample["prog2"]["status"], "success")
        self.assertIn("asymmetric crash", report["early_stop_reason"])

    def test_fallback_fail_fast_accounts_asymmetric_crash_before_cancel(self):
        fuzzer = SemanticFuzzer.__new__(SemanticFuzzer)
        fuzzer.bin1 = "/tmp/recovered_f1.bin"
        fuzzer.bin2 = "/tmp/original_f2.bin"
        fuzzer.seed_inputs = [self.payload]

        with patch("fuzzing_equi_check.fuzzing.run_binary", self._mock_execution):
            report = fuzzer.run_differential_test_fallback(
                iterations=5,
                generator=lambda: ([], b"unused"),
                timeout=0.1,
            )

        self._assert_complete_crash_report(report)
        self.assertEqual(report["fuzz_config"]["engine"], "fallback")
        self.assertEqual(report["fuzz_config"]["timeout_seconds"], 0.1)

    def test_afl_fail_fast_accounts_asymmetric_crash_before_cancel(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            fuzzer = SemanticFuzzer.__new__(SemanticFuzzer)
            fuzzer.bin1 = "/tmp/recovered_f1.bin"
            fuzzer.bin2 = "/tmp/original_f2.bin"
            fuzzer.seed_inputs = [self.payload]
            fuzzer.afl_cc = "/bin/true"
            fuzzer.afl_fuzz = "/bin/true"
            fuzzer.afl_path = "/tmp"
            fuzzer.tmp_dir = tmp_dir
            fuzzer.file1 = "/tmp/recovered.c"
            fuzzer.compiler_flags = None

            completed = subprocess.CompletedProcess([], 0, b"", b"")
            with patch.dict(
                "os.environ",
                {"BRIGHTEN_USE_AFL": "1", "BRIGHTEN_MUTATE_SEEDS": "raw"},
                clear=True,
            ), patch(
                "fuzzing_equi_check.fuzzing.subprocess.run",
                return_value=completed,
            ), patch(
                "fuzzing_equi_check.fuzzing.run_binary",
                self._mock_execution,
            ):
                report = fuzzer.run_differential_test(
                    iterations=1,
                    generator=lambda: ([], self.payload),
                    timeout=0.1,
                )

        self._assert_complete_crash_report(report)
        self.assertEqual(report["fuzz_config"]["engine"], "afl++")
        self.assertEqual(report["fuzz_config"]["seed_mutation_mode"], "raw")
        self.assertEqual(report["fuzz_config"]["timeout_seconds"], 0.1)


if __name__ == "__main__":
    unittest.main()

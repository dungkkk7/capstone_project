from __future__ import annotations

import csv
import math
import random
from collections import Counter, defaultdict
from pathlib import Path
from statistics import NormalDist
from typing import Any, Dict, Iterable

from .storage import atomic_write_json, atomic_write_text, load_json
from .ir_metrics import extract_ir_metrics
from .visualization import generate_visualizations


class AggregateIntegrityError(RuntimeError):
    """Aggregate inputs are incomplete or violate the enrolled study design."""


def _generation_cost_usd(
    generation: Dict[str, Any], llm_config: Dict[str, Any]
) -> float:
    """Estimate one request using the provider's long-context price tier."""
    input_tokens = int(generation.get("input_tokens") or 0)
    billable_output = int(
        generation.get(
            "billable_output_tokens",
            generation.get("output_tokens") or 0,
        )
        or 0
    )
    input_price = float(
        llm_config.get("pricing_usd_per_million_input_tokens") or 0
    )
    output_price = float(
        llm_config.get("pricing_usd_per_million_output_tokens") or 0
    )
    threshold = llm_config.get("pricing_long_context_threshold_tokens")
    if threshold is not None and input_tokens > int(threshold):
        input_price = float(
            llm_config.get(
                "pricing_usd_per_million_input_tokens_long_context",
                input_price,
            )
        )
        output_price = float(
            llm_config.get(
                "pricing_usd_per_million_output_tokens_long_context",
                output_price,
            )
        )
    return (input_tokens * input_price + billable_output * output_price) / 1_000_000


def _load_results(run_root: Path) -> list[Dict[str, Any]]:
    results = []
    samples_root = run_root / "samples"
    if not samples_root.is_dir():
        return results
    for path in sorted(samples_root.glob("*/*/result.json")):
        result = load_json(path)
        result["_path"] = str(path)
        discovery_path = (
            path.parent
            / "evaluation"
            / "discovery"
            / "fuzz_discovery.json"
        )
        if discovery_path.is_file():
            result["_discovery"] = load_json(discovery_path)
        results.append(result)
    return results


def _validate_aggregate_inputs(
    results: list[Dict[str, Any]],
    config: Dict[str, Any],
    experiment_manifest: Dict[str, Any] | None = None,
) -> None:
    if not results:
        raise AggregateIntegrityError("No variant results are available")
    expected_methods = {
        str(method) for method in config["experiment"]["methods"]
    }
    manifest_methods = set(
        (experiment_manifest or {}).get("methods") or []
    )
    if manifest_methods and manifest_methods != expected_methods:
        raise AggregateIntegrityError(
            "Config method set differs from experiment manifest"
        )
    seen: set[tuple[str, str]] = set()
    sample_methods: Dict[str, set[str]] = defaultdict(set)
    run_ids = set()
    union_hashes: Dict[str, set[str]] = defaultdict(set)
    reference_hashes: Dict[str, set[str]] = defaultdict(set)
    errors: list[str] = []
    for result in results:
        sample_id = str(result.get("sample_id") or "")
        method = str(result.get("method") or "")
        key = (sample_id, method)
        if key in seen:
            errors.append(f"duplicate variant result: {sample_id}/{method}")
        seen.add(key)
        sample_methods[sample_id].add(method)
        run_ids.add(result.get("run_id"))
        if method not in expected_methods:
            errors.append(f"unexpected method: {sample_id}/{method}")
        if result.get("final_stage") != "finalized":
            errors.append(f"nonterminal variant: {sample_id}/{method}")
        status = result.get("terminal_status")
        if bool(result.get("e2e_pass")) != (status == "PASS"):
            errors.append(f"e2e_pass/status mismatch: {sample_id}/{method}")
        generation = result.get("generation") or {}
        if method in {"A0", "B0"} and generation:
            if generation.get("logical_generation_count") != 1:
                errors.append(
                    f"one-shot logical-generation violation: {sample_id}/{method}"
                )
            if generation.get("model_call_count") != 1:
                errors.append(
                    f"one-shot accepted-call violation: {sample_id}/{method}"
                )
        if method == "P0" and generation:
            if int(generation.get("model_call_count") or 0) > 5:
                errors.append(f"P0 accepted-call violation: {sample_id}")
            if int(generation.get("iterations") or 0) > 5:
                errors.append(f"P0 iteration violation: {sample_id}")
        if result.get("evaluation"):
            integrity = result.get("integrity") or {}
            corpus_hash = integrity.get("union_corpus_sha256")
            reference_hash = integrity.get("reference_sha256")
            if corpus_hash:
                union_hashes[sample_id].add(str(corpus_hash))
            if reference_hash:
                reference_hashes[sample_id].add(str(reference_hash))
        path_value = result.get("_path")
        if path_value:
            path = Path(path_value)
            if path.parent.name != method or path.parent.parent.name != sample_id:
                errors.append(f"result identity/path mismatch: {sample_id}/{method}")
    if len(run_ids) != 1:
        errors.append("variant results contain multiple run_id values")
    for sample_id, methods in sorted(sample_methods.items()):
        if methods != expected_methods:
            errors.append(
                f"incomplete method set for {sample_id}: "
                f"expected {sorted(expected_methods)}, got {sorted(methods)}"
            )
        if len(union_hashes[sample_id]) > 1:
            errors.append(f"union corpus mismatch: {sample_id}")
        if len(reference_hashes[sample_id]) > 1:
            errors.append(f"reference mismatch: {sample_id}")
    expected_sample_ids = set(
        (experiment_manifest or {}).get("sample_ids") or []
    )
    if expected_sample_ids and set(sample_methods) != expected_sample_ids:
        missing = sorted(expected_sample_ids - set(sample_methods))
        extra = sorted(set(sample_methods) - expected_sample_ids)
        errors.append(
            f"enrolled sample set mismatch: missing={missing}, extra={extra}"
        )
    if errors:
        raise AggregateIntegrityError("; ".join(errors))


def _write_csv(path: Path, rows: list[Dict[str, Any]], columns: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def _flatten_variant(result: Dict[str, Any]) -> Dict[str, Any]:
    representation = result.get("representation") or {}
    generation = result.get("generation") or {}
    build = result.get("build") or {}
    evaluation = result.get("evaluation") or {}
    integrity = result.get("integrity") or {}
    timing = result.get("timing") or {}
    discovery = result.get("_discovery") or {}
    discovery_report = discovery.get("report") or {}
    fuzz_config = discovery_report.get("fuzz_config") or {}
    afl_stats = discovery_report.get("afl_stats") or {}
    return {
        "run_id": result.get("run_id"),
        "sample_id": result.get("sample_id"),
        "method": result.get("method"),
        "terminal_status": result.get("terminal_status"),
        "e2e_pass": bool(result.get("e2e_pass")),
        "original_elf_sha256": (result.get("identity") or {}).get(
            "original_elf_sha256"
        ),
        "representation_sha256": representation.get("primary_sha256"),
        "representation_bytes": representation.get("byte_count"),
        "representation_tokens": representation.get("token_count"),
        "evidence_bytes": representation.get(
            "evidence_byte_count", representation.get("byte_count")
        ),
        "evidence_tokens": representation.get(
            "evidence_token_count", representation.get("token_count")
        ),
        "context_fit": (
            result.get("terminal_status") != "CONTEXT_OVERFLOW"
            if representation
            else False
        ),
        "model_call_count": generation.get("model_call_count"),
        "api_attempt_count": generation.get(
            "api_attempt_count", generation.get("model_call_count")
        ),
        "quota_throttle_count": generation.get(
            "quota_throttle_count"
        ),
        "quota_wait_duration_ms": generation.get(
            "quota_wait_duration_ms"
        ),
        "logical_generation_count": generation.get(
            "logical_generation_count"
        ),
        "iterations": generation.get("iterations"),
        "input_tokens": generation.get("input_tokens"),
        "output_tokens": generation.get("output_tokens"),
        "thinking_tokens": generation.get("thinking_tokens"),
        "billable_output_tokens": generation.get(
            "billable_output_tokens", generation.get("output_tokens")
        ),
        "llm_latency_ms": generation.get("latency_ms"),
        "candidate_sha256": generation.get("candidate_sha256"),
        "build_ok": bool(build.get("ok")),
        "build_duration_ms": build.get("duration_ms"),
        "representation_duration_ms": timing.get(
            "representation_duration_ms"
        ),
        "generation_duration_ms": timing.get("generation_duration_ms"),
        "generation_pipeline_duration_ms": timing.get(
            "generation_pipeline_duration_ms"
        ),
        "evaluation_duration_ms": timing.get("evaluation_duration_ms"),
        "runnable": evaluation.get("union_input_count") is not None,
        "union_input_count": evaluation.get("union_input_count"),
        "confirmed_inputs": evaluation.get("confirmed_inputs"),
        "matches": evaluation.get("matches"),
        "mismatches": evaluation.get("mismatches"),
        "inconclusive": evaluation.get("inconclusive"),
        "reference_sha256": integrity.get("reference_sha256"),
        "corpus_manifest_sha256": integrity.get("union_corpus_sha256"),
        "total_duration_ms": timing.get("total_duration_ms"),
        "failure_code": result.get("failure_code"),
        "discovery_engine": fuzz_config.get("engine"),
        "discovery_tested_input_count": len(
            discovery_report.get("tested_payloads") or []
        ),
        "unique_discovered_input_count": len(
            discovery.get("inputs") or []
        ),
        "afl_candidate_count": fuzz_config.get("afl_candidates"),
        "afl_accepted_count": fuzz_config.get("afl_accepted"),
        "afl_bitmap_coverage": afl_stats.get("bitmap_cvg"),
        "afl_paths_total": afl_stats.get("paths_total"),
        "afl_execs_done": afl_stats.get("execs_done"),
        "afl_execs_per_sec": afl_stats.get("execs_per_sec"),
    }


VARIANT_COLUMNS = [
    "run_id",
    "sample_id",
    "method",
    "terminal_status",
    "e2e_pass",
    "original_elf_sha256",
    "representation_sha256",
    "representation_bytes",
    "representation_tokens",
    "evidence_bytes",
    "evidence_tokens",
    "context_fit",
    "model_call_count",
    "api_attempt_count",
    "quota_throttle_count",
    "quota_wait_duration_ms",
    "logical_generation_count",
    "iterations",
    "input_tokens",
    "output_tokens",
    "thinking_tokens",
    "billable_output_tokens",
    "llm_latency_ms",
    "candidate_sha256",
    "build_ok",
    "build_duration_ms",
    "representation_duration_ms",
    "generation_duration_ms",
    "generation_pipeline_duration_ms",
    "evaluation_duration_ms",
    "runnable",
    "union_input_count",
    "confirmed_inputs",
    "matches",
    "mismatches",
    "inconclusive",
    "reference_sha256",
    "corpus_manifest_sha256",
    "total_duration_ms",
    "failure_code",
    "discovery_engine",
    "discovery_tested_input_count",
    "unique_discovered_input_count",
    "afl_candidate_count",
    "afl_accepted_count",
    "afl_bitmap_coverage",
    "afl_paths_total",
    "afl_execs_done",
    "afl_execs_per_sec",
]


def _rate(numerator: int, denominator: int) -> float:
    return numerator / denominator if denominator else 0.0


def _wilson_interval(
    successes: int, total: int, confidence: float
) -> list[float] | None:
    if total <= 0:
        return None
    z = NormalDist().inv_cdf(0.5 + confidence / 2.0)
    proportion = successes / total
    denominator = 1 + z * z / total
    center = (proportion + z * z / (2 * total)) / denominator
    margin = (
        z
        * math.sqrt(
            proportion * (1 - proportion) / total
            + z * z / (4 * total * total)
        )
        / denominator
    )
    return [max(0.0, center - margin), min(1.0, center + margin)]


def _distribution(values: Iterable[Any]) -> Dict[str, float] | None:
    numbers = sorted(
        float(value) for value in values if value is not None
    )
    if not numbers:
        return None
    return {
        "min": numbers[0],
        "q1": _percentile(numbers, 0.25),
        "median": _percentile(numbers, 0.50),
        "q3": _percentile(numbers, 0.75),
        "max": numbers[-1],
    }


def _method_summary(
    results: list[Dict[str, Any]], config: Dict[str, Any]
) -> Dict[str, Any]:
    grouped: Dict[str, list[Dict[str, Any]]] = defaultdict(list)
    for result in results:
        grouped[result["method"]].append(result)
    summary = {}
    for method, items in sorted(grouped.items()):
        n = len(items)
        rep_ok = sum(bool(item.get("representation")) for item in items)
        context_fit = sum(
            bool(item.get("representation"))
            and item.get("terminal_status") != "CONTEXT_OVERFLOW"
            for item in items
        )
        llm_responses = sum(
            int((item.get("generation") or {}).get("model_call_count") or 0)
            > 0
            for item in items
        )
        generated = sum(
            bool((item.get("generation") or {}).get("candidate_sha256"))
            for item in items
        )
        built = sum(bool((item.get("build") or {}).get("ok")) for item in items)
        runnable = sum(
            (item.get("evaluation") or {}).get("smoke_runnable") is True
            for item in items
        )
        passed = sum(bool(item.get("e2e_pass")) for item in items)
        statuses = Counter(item["terminal_status"] for item in items)
        context_overflow = statuses.get("CONTEXT_OVERFLOW", 0)
        infra_failures = statuses.get("INFRA_ERROR", 0)
        confirmed_non_equivalence = statuses.get("BEHAVIOR_MISMATCH", 0)
        inconclusive = statuses.get("EVAL_INCONCLUSIVE", 0)
        calls = sum(
            int((item.get("generation") or {}).get("model_call_count") or 0)
            for item in items
        )
        api_attempts = sum(
            int(
                (item.get("generation") or {}).get(
                    "api_attempt_count",
                    (item.get("generation") or {}).get(
                        "model_call_count", 0
                    ),
                )
                or 0
            )
            for item in items
        )
        quota_throttles = sum(
            int(
                (item.get("generation") or {}).get("quota_throttle_count")
                or 0
            )
            for item in items
        )
        quota_wait_ms = sum(
            int(
                (item.get("generation") or {}).get(
                    "quota_wait_duration_ms"
                )
                or 0
            )
            for item in items
        )
        discovery_tested = [
            len(
                (
                    (item.get("_discovery") or {}).get("report") or {}
                ).get("tested_payloads") or []
            )
            for item in items
            if item.get("_discovery")
        ]
        unique_discovered = [
            len((item.get("_discovery") or {}).get("inputs") or [])
            for item in items
            if item.get("_discovery")
        ]
        discovery_engines = Counter(
            str(
                (
                    (
                        (item.get("_discovery") or {}).get("report") or {}
                    ).get("fuzz_config") or {}
                ).get("engine") or "unknown"
            )
            for item in items
            if item.get("_discovery")
        )
        input_tokens = sum(
            int((item.get("generation") or {}).get("input_tokens") or 0)
            for item in items
        )
        output_tokens = sum(
            int((item.get("generation") or {}).get("output_tokens") or 0)
            for item in items
        )
        thinking_tokens = sum(
            int(
                (item.get("generation") or {}).get("thinking_tokens")
                or 0
            )
            for item in items
        )
        billable_output_tokens = sum(
            int(
                (item.get("generation") or {}).get(
                    "billable_output_tokens",
                    (item.get("generation") or {}).get("output_tokens"),
                )
                or 0
            )
            for item in items
        )
        input_price = config["llm"].get("pricing_usd_per_million_input_tokens")
        output_price = config["llm"].get("pricing_usd_per_million_output_tokens")
        total_cost = None
        if (
            input_price is not None
            and output_price is not None
            and not config["llm"].get("fake_response_path")
        ):
            total_cost = sum(
                _generation_cost_usd(item.get("generation") or {}, config["llm"])
                for item in items
            )
        summary[method] = {
            "enrolled": n,
            "representation_success_count": rep_ok,
            "context_fit_count": context_fit,
            "llm_response_count": llm_responses,
            "candidate_extraction_count": generated,
            "build_success_count": built,
            "runnable_count": runnable,
            "pass": passed,
            "e2e_rate": _rate(passed, n),
            "e2e_rate_wilson_ci": _wilson_interval(
                passed,
                n,
                float(config["statistics"]["confidence_level"]),
            ),
            "representation_success_unconditional": _rate(rep_ok, n),
            "context_fit_unconditional": _rate(context_fit, n),
            "context_fit_conditional": _rate(context_fit, rep_ok),
            "llm_response_unconditional": _rate(llm_responses, n),
            "llm_response_conditional": _rate(llm_responses, context_fit),
            "generation_unconditional": _rate(generated, n),
            "generation_conditional": _rate(generated, context_fit),
            "build_success_unconditional": _rate(built, n),
            "build_success_conditional": _rate(built, generated),
            "runnable_unconditional": _rate(runnable, n),
            "confirmed_non_equivalence_unconditional": _rate(
                confirmed_non_equivalence, n
            ),
            "inconclusive_unconditional": _rate(inconclusive, n),
            "context_overflow_unconditional": _rate(context_overflow, n),
            "infra_failure_unconditional": _rate(infra_failures, n),
            "status_counts": dict(sorted(statuses.items())),
            "total_model_calls": calls,
            "total_api_attempts": api_attempts,
            "total_quota_throttles": quota_throttles,
            "total_quota_wait_duration_ms": quota_wait_ms,
            "total_input_tokens": input_tokens,
            "total_output_tokens": output_tokens,
            "total_thinking_tokens": thinking_tokens,
            "total_billable_output_tokens": billable_output_tokens,
            "total_discovery_tested_inputs": sum(discovery_tested),
            "total_unique_discovered_inputs": sum(unique_discovered),
            "discovery_engine_counts": dict(
                sorted(discovery_engines.items())
            ),
            "estimated_total_cost_usd": total_cost,
            "cost_per_pass_usd": (
                total_cost / passed
                if total_cost is not None and passed
                else None
            ),
            "model_call_distribution": _distribution(
                (item.get("generation") or {}).get("model_call_count")
                for item in items
            ),
            "api_attempt_distribution": _distribution(
                (item.get("generation") or {}).get(
                    "api_attempt_count",
                    (item.get("generation") or {}).get(
                        "model_call_count"
                    ),
                )
                for item in items
            ),
            "quota_wait_duration_ms_distribution": _distribution(
                (item.get("generation") or {}).get(
                    "quota_wait_duration_ms"
                )
                for item in items
            ),
            "input_token_distribution": _distribution(
                (item.get("generation") or {}).get("input_tokens")
                for item in items
            ),
            "output_token_distribution": _distribution(
                (item.get("generation") or {}).get("output_tokens")
                for item in items
            ),
            "llm_latency_ms_distribution": _distribution(
                (item.get("generation") or {}).get("latency_ms")
                for item in items
            ),
            "representation_token_distribution": _distribution(
                (item.get("representation") or {}).get("token_count")
                for item in items
            ),
            "evidence_token_distribution": _distribution(
                (item.get("representation") or {}).get(
                    "evidence_token_count",
                    (item.get("representation") or {}).get("token_count"),
                )
                for item in items
            ),
            "discovery_tested_input_distribution": _distribution(
                discovery_tested
            ),
            "unique_discovered_input_distribution": _distribution(
                unique_discovered
            ),
            "build_duration_ms_distribution": _distribution(
                (item.get("build") or {}).get("duration_ms")
                for item in items
            ),
            "evaluation_duration_ms_distribution": _distribution(
                (item.get("timing") or {}).get("evaluation_duration_ms")
                for item in items
            ),
            "total_duration_ms_distribution": _distribution(
                (item.get("timing") or {}).get("total_duration_ms")
                for item in items
            ),
        }
    return summary


def _metrics_long_rows(
    method_summary: Dict[str, Any],
    statistics: list[Dict[str, Any]],
) -> list[Dict[str, Any]]:
    rows: list[Dict[str, Any]] = []

    def add(
        *,
        scope: str,
        metric: str,
        value: Any,
        unit: str,
        method: str = "",
        comparison: str = "",
        statistic: str = "point",
        denominator: Any = "",
    ) -> None:
        if value is None:
            return
        rows.append(
            {
                "scope": scope,
                "method": method,
                "comparison": comparison,
                "metric": metric,
                "statistic": statistic,
                "value": value,
                "unit": unit,
                "denominator": denominator,
            }
        )

    rate_metrics = (
        "representation_success_unconditional",
        "context_fit_unconditional",
        "context_fit_conditional",
        "llm_response_unconditional",
        "llm_response_conditional",
        "generation_unconditional",
        "generation_conditional",
        "build_success_unconditional",
        "build_success_conditional",
        "runnable_unconditional",
        "confirmed_non_equivalence_unconditional",
        "inconclusive_unconditional",
        "context_overflow_unconditional",
        "infra_failure_unconditional",
        "e2e_rate",
    )
    for method, summary in sorted(method_summary.items()):
        enrolled = summary["enrolled"]
        conditional_denominators = {
            "context_fit_conditional": summary[
                "representation_success_count"
            ],
            "llm_response_conditional": summary["context_fit_count"],
            "generation_conditional": summary["context_fit_count"],
            "build_success_conditional": summary[
                "candidate_extraction_count"
            ],
        }
        add(
            scope="method",
            method=method,
            metric="enrolled",
            value=enrolled,
            unit="programs",
        )
        add(
            scope="method",
            method=method,
            metric="pass",
            value=summary["pass"],
            unit="programs",
            denominator=enrolled,
        )
        for metric in rate_metrics:
            add(
                scope="method",
                method=method,
                metric=metric,
                value=summary[metric],
                unit="proportion",
                denominator=(
                    conditional_denominators.get(metric, enrolled)
                ),
            )
        e2e_ci = summary.get("e2e_rate_wilson_ci")
        if e2e_ci:
            add(
                scope="method",
                method=method,
                metric="e2e_rate",
                value=e2e_ci[0],
                unit="proportion",
                statistic="ci_low",
                denominator=enrolled,
            )
            add(
                scope="method",
                method=method,
                metric="e2e_rate",
                value=e2e_ci[1],
                unit="proportion",
                statistic="ci_high",
                denominator=enrolled,
            )
        for metric in (
            "total_model_calls",
            "total_api_attempts",
            "total_quota_throttles",
            "total_quota_wait_duration_ms",
            "total_input_tokens",
            "total_output_tokens",
            "total_thinking_tokens",
            "total_billable_output_tokens",
            "total_discovery_tested_inputs",
            "total_unique_discovered_inputs",
            "estimated_total_cost_usd",
            "cost_per_pass_usd",
        ):
            unit = (
                "USD"
                if metric.endswith("_usd")
                else (
                    "milliseconds"
                    if "duration" in metric
                    else (
                        "tokens"
                        if "tokens" in metric
                        else (
                            "inputs"
                            if "inputs" in metric
                            else (
                            "events"
                            if "throttles" in metric
                            else "calls"
                            )
                        )
                    )
                )
            )
            add(
                scope="method",
                method=method,
                metric=metric,
                value=summary.get(metric),
                unit=unit,
            )
        for metric in (
            "model_call_distribution",
            "api_attempt_distribution",
            "quota_wait_duration_ms_distribution",
            "input_token_distribution",
            "output_token_distribution",
            "llm_latency_ms_distribution",
            "representation_token_distribution",
            "evidence_token_distribution",
            "discovery_tested_input_distribution",
            "unique_discovered_input_distribution",
            "build_duration_ms_distribution",
            "evaluation_duration_ms_distribution",
            "total_duration_ms_distribution",
        ):
            distribution = summary.get(metric) or {}
            unit = (
                "milliseconds"
                if "duration" in metric or "latency" in metric
                else (
                    "tokens"
                    if "token" in metric
                    else ("inputs" if "input" in metric else "calls")
                )
            )
            for statistic, value in distribution.items():
                add(
                    scope="method",
                    method=method,
                    metric=metric,
                    value=value,
                    unit=unit,
                    statistic=statistic,
                )
        for status, count in sorted(summary.get("status_counts", {}).items()):
            add(
                scope="method",
                method=method,
                metric=f"terminal_status.{status}",
                value=count,
                unit="programs",
                denominator=enrolled,
            )
        for engine, count in sorted(
            summary.get("discovery_engine_counts", {}).items()
        ):
            add(
                scope="method",
                method=method,
                metric=f"discovery_engine.{engine}",
                value=count,
                unit="programs",
                denominator=enrolled,
            )

    for item in statistics:
        comparison = item["comparison"]
        for metric, unit in (
            ("risk_difference", "proportion"),
            ("risk_difference_percentage_points", "percentage_points"),
            ("discordant_p0_wins", "programs"),
            ("discordant_p0_losses", "programs"),
            ("mcnemar_exact_p", "probability"),
            ("holm_adjusted_p", "probability"),
        ):
            add(
                scope="pairwise",
                comparison=comparison,
                metric=metric,
                value=item.get(metric),
                unit=unit,
                denominator=item.get("n"),
            )
        ci = item.get("bootstrap_ci_percentage_points") or []
        if len(ci) == 2:
            add(
                scope="pairwise",
                comparison=comparison,
                metric="risk_difference_percentage_points",
                value=ci[0],
                unit="percentage_points",
                statistic="ci_low",
                denominator=item.get("n"),
            )
            add(
                scope="pairwise",
                comparison=comparison,
                metric="risk_difference_percentage_points",
                value=ci[1],
                unit="percentage_points",
                statistic="ci_high",
                denominator=item.get("n"),
            )
    return rows


def _percentile(sorted_values: list[float], probability: float) -> float:
    if not sorted_values:
        return 0.0
    index = probability * (len(sorted_values) - 1)
    low = math.floor(index)
    high = math.ceil(index)
    if low == high:
        return sorted_values[low]
    weight = index - low
    return sorted_values[low] * (1 - weight) + sorted_values[high] * weight


def _bootstrap_delta(
    pairs: list[tuple[int, int]], resamples: int, seed: int, confidence: float
) -> tuple[float, float]:
    if not pairs:
        return (0.0, 0.0)
    rng = random.Random(seed)
    deltas = []
    for _ in range(resamples):
        sample = [pairs[rng.randrange(len(pairs))] for _ in pairs]
        deltas.append(
            sum(left - right for left, right in sample) / len(sample)
        )
    deltas.sort()
    alpha = 1.0 - confidence
    return (
        _percentile(deltas, alpha / 2),
        _percentile(deltas, 1 - alpha / 2),
    )


def _exact_mcnemar(b: int, c: int) -> float:
    n = b + c
    if n == 0:
        return 1.0
    tail = min(b, c)
    probability = sum(math.comb(n, k) for k in range(tail + 1)) / (2**n)
    return min(1.0, 2.0 * probability)


def _pairwise(
    results: list[Dict[str, Any]],
    right_method: str,
    config: Dict[str, Any],
) -> tuple[list[Dict[str, Any]], Dict[str, Any]]:
    by_key = {
        (item["sample_id"], item["method"]): item for item in results
    }
    sample_ids = sorted(
        sample_id
        for sample_id, method in by_key
        if method == "P0" and (sample_id, right_method) in by_key
    )
    rows = []
    pairs = []
    b = c = 0
    for sample_id in sample_ids:
        left = by_key[(sample_id, "P0")]
        right = by_key[(sample_id, right_method)]
        left_pass = int(bool(left.get("e2e_pass")))
        right_pass = int(bool(right.get("e2e_pass")))
        pairs.append((left_pass, right_pass))
        if left_pass and not right_pass:
            category = "P0_WIN"
            b += 1
        elif not left_pass and right_pass:
            category = "P0_LOSS"
            c += 1
        elif left_pass:
            category = "TIE_PASS"
        else:
            category = "TIE_FAIL"
        rows.append(
            {
                "sample_id": sample_id,
                "P0_status": left["terminal_status"],
                f"{right_method}_status": right["terminal_status"],
                "category": category,
            }
        )
    delta = (
        sum(left - right for left, right in pairs) / len(pairs)
        if pairs
        else 0.0
    )
    stats_config = config["statistics"]
    ci_low, ci_high = _bootstrap_delta(
        pairs,
        int(stats_config["bootstrap_resamples"]),
        int(stats_config["bootstrap_seed"]),
        float(stats_config["confidence_level"]),
    )
    stats = {
        "comparison": f"P0-current_vs_{right_method}-one-shot",
        "n": len(pairs),
        "risk_difference": delta,
        "risk_difference_percentage_points": delta * 100,
        "bootstrap_ci": [ci_low, ci_high],
        "bootstrap_ci_percentage_points": [ci_low * 100, ci_high * 100],
        "discordant_p0_wins": b,
        "discordant_p0_losses": c,
        "mcnemar_exact_p": _exact_mcnemar(b, c),
    }
    return rows, stats


def _holm_adjust(stats: list[Dict[str, Any]], alpha: float) -> None:
    ordered = sorted(
        enumerate(stats), key=lambda item: item[1]["mcnemar_exact_p"]
    )
    total = len(ordered)
    running_adjusted = 0.0
    rejected_so_far = True
    for rank, (original_index, item) in enumerate(ordered):
        multiplier = total - rank
        adjusted = min(1.0, item["mcnemar_exact_p"] * multiplier)
        adjusted = max(running_adjusted, adjusted)
        running_adjusted = adjusted
        item["holm_adjusted_p"] = adjusted
        threshold = alpha / multiplier
        item["holm_reject"] = (
            rejected_so_far and item["mcnemar_exact_p"] <= threshold
        )
        if not item["holm_reject"]:
            rejected_so_far = False


def aggregate_run(
    run_root: str | Path, config: Dict[str, Any]
) -> Dict[str, Any]:
    root = Path(run_root)
    aggregate = root / "aggregate"
    results = _load_results(root)
    experiment_manifest_path = root / "experiment_manifest.json"
    experiment_manifest = (
        load_json(experiment_manifest_path)
        if experiment_manifest_path.is_file()
        else {}
    )
    _validate_aggregate_inputs(results, config, experiment_manifest)
    aggregate.mkdir(parents=True, exist_ok=True)
    variants = [_flatten_variant(item) for item in results]
    _write_csv(aggregate / "variants.csv", variants, VARIANT_COLUMNS)
    failures = [
        row for row in variants if row["terminal_status"] != "PASS"
    ]
    _write_csv(
        aggregate / "failures.csv",
        failures,
        ["sample_id", "method", "terminal_status", "failure_code"],
    )

    method_summary = _method_summary(results, config)
    atomic_write_json(aggregate / "method_summary.json", method_summary)
    funnel_rows = []
    for method, summary in method_summary.items():
        for metric in (
            "representation_success_unconditional",
            "context_fit_unconditional",
            "context_fit_conditional",
            "llm_response_unconditional",
            "llm_response_conditional",
            "generation_unconditional",
            "generation_conditional",
            "build_success_unconditional",
            "build_success_conditional",
            "runnable_unconditional",
            "confirmed_non_equivalence_unconditional",
            "inconclusive_unconditional",
            "context_overflow_unconditional",
            "infra_failure_unconditional",
            "e2e_rate",
        ):
            funnel_rows.append(
                {"method": method, "metric": metric, "value": summary[metric]}
            )
    _write_csv(
        aggregate / "stage_funnel.csv",
        funnel_rows,
        ["method", "metric", "value"],
    )

    statistics = []
    for right in ("B0", "A0"):
        if "P0" not in method_summary or right not in method_summary:
            continue
        rows, stats = _pairwise(results, right, config)
        _write_csv(
            aggregate / f"pairwise_p0_{right.lower()}.csv",
            rows,
            ["sample_id", "P0_status", f"{right}_status", "category"],
        )
        statistics.append(stats)
    _holm_adjust(statistics, float(config["statistics"]["alpha"]))
    atomic_write_json(aggregate / "statistics.json", statistics)

    by_sample_method = {
        (item["sample_id"], item["method"]): item for item in results
    }
    ir_rows = []
    for sample_id in sorted({item["sample_id"] for item in results}):
        a0 = by_sample_method.get((sample_id, "A0"))
        p0 = by_sample_method.get((sample_id, "P0"))
        if not a0 or not p0:
            continue
        a0_metrics = extract_ir_metrics(
            (a0.get("representation") or {}).get("primary_path", "")
        )
        p0_metrics = extract_ir_metrics(
            (p0.get("representation") or {}).get("primary_path", "")
        )
        if not a0_metrics or not p0_metrics:
            continue
        row: Dict[str, Any] = {"sample_id": sample_id}
        for name in (
            "instruction_count",
            "basic_block_count",
            "cfg_edge_count",
            "function_count",
        ):
            raw = a0_metrics[name]
            enhanced = p0_metrics[name]
            row[f"A0_{name}"] = raw
            row[f"P0_{name}"] = enhanced
            row[f"{name}_reduction"] = (
                (raw - enhanced) / raw if raw else None
            )
        ir_rows.append(row)
    if ir_rows:
        _write_csv(
            aggregate / "ir_cfg_metrics.csv",
            ir_rows,
            list(ir_rows[0].keys()),
        )

    metrics_rows = _metrics_long_rows(method_summary, statistics)
    _write_csv(
        aggregate / "metrics_long.csv",
        metrics_rows,
        [
            "scope",
            "method",
            "comparison",
            "metric",
            "statistic",
            "value",
            "unit",
            "denominator",
        ],
    )
    fake_llm = bool(config["llm"].get("fake_response_path"))
    environment = experiment_manifest.get("environment") or {}
    git_dirty = bool(environment.get("git_dirty"))
    study_scope = str(
        config["experiment"].get("study_scope") or "unspecified"
    )
    if fake_llm:
        evidence_eligibility = "pipeline_validation_only"
    elif study_scope == "primary_full_dataset" and not git_dirty:
        evidence_eligibility = "primary_research_evidence"
    elif git_dirty:
        evidence_eligibility = (
            "scoped_research_evidence_dirty_worktree"
        )
    else:
        evidence_eligibility = "scoped_research_evidence"
    execution_context = {
        "run_id": root.name,
        "study_scope": study_scope,
        "sample_count": len(
            {
                str(result.get("sample_id"))
                for result in results
                if result.get("sample_id")
            }
        ),
        "provider": (
            "fake"
            if fake_llm
            else str(config["llm"].get("provider") or "unknown")
        ),
        "model_id": str(config["llm"].get("model_id") or "unknown"),
        "fake_llm": fake_llm,
        "git_commit": environment.get("git_commit"),
        "git_dirty": git_dirty,
        "evidence_eligibility": evidence_eligibility,
    }
    metrics_document = {
        "schema_version": "1.0",
        "execution_context": execution_context,
        "pricing": {
            "plan": config["llm"].get("pricing_plan"),
            "usd_per_million_input_tokens": config["llm"].get(
                "pricing_usd_per_million_input_tokens"
            ),
            "usd_per_million_output_tokens": config["llm"].get(
                "pricing_usd_per_million_output_tokens"
            ),
            "long_context_threshold_tokens": config["llm"].get(
                "pricing_long_context_threshold_tokens"
            ),
            "usd_per_million_input_tokens_long_context": config["llm"].get(
                "pricing_usd_per_million_input_tokens_long_context"
            ),
            "usd_per_million_output_tokens_long_context": config["llm"].get(
                "pricing_usd_per_million_output_tokens_long_context"
            ),
            "source": config["llm"].get("pricing_source"),
            "verified_date": config["llm"].get(
                "pricing_verified_date"
            ),
            "estimate_scope": (
                "provider-reported input plus response-and-reasoning "
                "output tokens only; fake runs always report null "
                "estimated cost"
            ),
        },
        "primary_endpoint": {
            "name": "e2e_rate",
            "numerator": "programs with exact behavioral PASS",
            "denominator": "all enrolled programs for the method",
            "reference": "original obfuscated ELF",
            "interval": (
                "Wilson score interval at configured confidence level"
            ),
        },
        "study_design": {
            "comparison": "end-to-end method performance",
            "P0": "unchanged iterative repair pipeline, at most five LLM calls",
            "A0": "raw LLVM IR, one logical LLM generation",
            "B0": "Ghidra pseudocode from original obfuscated ELF, one logical LLM generation",
            "causal_claim": (
                "Not a representation-only causal comparison because the "
                "generation protocols differ."
            ),
        },
        "metric_definitions": {
            "representation_success_unconditional": (
                "representation built / all enrolled programs"
            ),
            "context_fit_unconditional": (
                "representation fits configured context / all enrolled programs"
            ),
            "generation_unconditional": (
                "candidate C extraction completed / all enrolled programs"
            ),
            "llm_response_unconditional": (
                "at least one accepted provider response / all enrolled programs"
            ),
            "build_success_unconditional": (
                "candidate compiled / all enrolled programs"
            ),
            "runnable_unconditional": (
                "candidate completed the smoke execution contract / all enrolled programs"
            ),
            "confirmed_non_equivalence_unconditional": (
                "programs with at least one confirmed behavioral mismatch / "
                "all enrolled programs"
            ),
            "inconclusive_unconditional": (
                "programs with insufficient conclusive oracle evidence / "
                "all enrolled programs"
            ),
            "context_overflow_unconditional": (
                "programs rejected by the frozen context gate / "
                "all enrolled programs"
            ),
            "infra_failure_unconditional": (
                "programs ending in infrastructure error / all enrolled programs"
            ),
            "total_discovery_tested_inputs": (
                "structured candidate-specific discovery executions summed "
                "over programs; diagnostic only, not an independent-sample "
                "denominator"
            ),
            "total_unique_discovered_inputs": (
                "unique non-base inputs contributed to frozen union corpora"
            ),
            "e2e_rate": (
                "exact behavioral PASS / all enrolled programs"
            ),
            "risk_difference": (
                "paired P0 PASS indicator minus comparator PASS indicator"
            ),
            "mcnemar_exact_p": (
                "two-sided exact McNemar test on discordant paired outcomes"
            ),
        },
        "methods": method_summary,
        "pairwise_statistics": statistics,
        "ir_structure": ir_rows,
        "long_format_row_count": len(metrics_rows),
    }
    atomic_write_json(aggregate / "metrics.json", metrics_document)
    visual_manifest = generate_visualizations(
        aggregate,
        method_summary,
        statistics,
        ir_rows,
        execution_context,
    )

    lines = [
        "# P0/A0/B0 Experiment Report",
        "",
        (
            "**NOT A RESEARCH RESULT:** this run used a fake LLM response and "
            "is eligible only for pipeline validation."
            if fake_llm
            else (
                f"Real-provider run (`{evidence_eligibility}`) using "
                f"`{execution_context['provider']}` / "
                f"`{execution_context['model_id']}`."
            )
        ),
        "",
        (
            f"Study scope: `{execution_context['study_scope']}`; "
            f"enrolled samples: `{execution_context['sample_count']}`."
        ),
        "",
        "P0 is the unchanged legacy iterative method with at most five "
        "compiler/fuzz-feedback iterations. A0 and B0 are one-shot methods. "
        "The comparison therefore measures end-to-end method performance, "
        "not a representation-only causal effect.",
        "",
        "The B0 prompt is group-designed and informed by BinDeObfBench task "
        "framing; it is not represented as the exact prompt from the paper.",
        "",
        "Audit evidence is stored as a hash-chained JSONL event log and a "
        "SHA-256 artifact manifest. Machine-readable metrics are available in "
        "`metrics.json` and `metrics_long.csv`; publication-ready SVG figures "
        "and an HTML evidence index are generated under `aggregate/`.",
        "",
        "## Method summary",
        "",
        "| Method | Enrolled | PASS | E2E | Accepted calls | API attempts | Quota wait |",
        "|---|---:|---:|---:|---:|---:|---:|",
    ]
    for method, summary in sorted(method_summary.items()):
        lines.append(
            f"| {method} | {summary['enrolled']} | {summary['pass']} | "
            f"{summary['e2e_rate'] * 100:.2f}% | "
            f"{summary['total_model_calls']} | "
            f"{summary['total_api_attempts']} | "
            f"{summary['total_quota_wait_duration_ms'] / 1000:.1f}s |"
        )
    if statistics:
        lines.extend(
            [
                "",
                "## Pairwise comparison",
                "",
                "| Comparison | Risk difference | 95% paired bootstrap CI | "
                "McNemar p | Holm-adjusted p |",
                "|---|---:|---:|---:|---:|",
            ]
        )
        for item in statistics:
            ci = item["bootstrap_ci_percentage_points"]
            lines.append(
                f"| {item['comparison']} | "
                f"{item['risk_difference_percentage_points']:+.2f} pp | "
                f"[{ci[0]:+.2f}, {ci[1]:+.2f}] pp | "
                f"{item['mcnemar_exact_p']:.6g} | "
                f"{item['holm_adjusted_p']:.6g} |"
            )
    atomic_write_text(aggregate / "report.md", "\n".join(lines) + "\n")
    return {
        "method_summary": method_summary,
        "statistics": statistics,
        "variant_count": len(results),
        "metric_count": len(metrics_rows),
        "figure_count": visual_manifest["figure_count"],
    }

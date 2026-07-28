from evaluation.metric_definitions import (
    compilation_repair_success_rate,
    counterexample_reproducibility_rate,
    final_rsr_at_r,
    first_pass_rsr,
    format_percentage_points,
    format_percent,
    input_behavioral_match_rate,
    percentage_point_gain,
    valid_input_rate,
)


def test_recompilation_rates_and_gain_use_percent_and_pp():
    first = first_pass_rsr(36, 40)
    final = final_rsr_at_r(37, 40)

    assert first == 90.0
    assert final == 92.5
    assert percentage_point_gain(final, first) == 2.5
    assert format_percent(final) == "92.50%"
    assert format_percentage_points(2.5) == "+2.50 pp"


def test_compilation_repair_success_rate_uses_initial_failures_only():
    assert compilation_repair_success_rate(1, 4) == 25.0


def test_match_rate_excludes_inconclusive_runs_from_denominator():
    # 95 confirmed observations plus 5 inconclusive executions.
    assert input_behavioral_match_rate(90, 95) == 90 / 95 * 100


def test_valid_input_rate_uses_raw_generated_input_denominator():
    assert valid_input_rate(75, 100) == 75.0


def test_undefined_ratios_are_not_reported_as_artificial_100_percent():
    assert compilation_repair_success_rate(0, 0) is None
    assert valid_input_rate(0, 0) is None
    assert counterexample_reproducibility_rate(0, 0) is None
    assert format_percent(None) == "N/A"

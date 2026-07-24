from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Support both ``python src/main.py ... experiment`` and
# ``python -m src.experiments.cli`` in this non-packaged legacy repository.
SRC_ROOT = Path(__file__).resolve().parents[1]
if str(SRC_ROOT) not in sys.path:
    sys.path.insert(0, str(SRC_ROOT))

from .config import load_config, validate_config
from .identity import read_dataset
from .runner import ExperimentRunner
from .storage import stable_json_sha256


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run reproducible P0/A0/B0 experiments"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    def common(subparser: argparse.ArgumentParser) -> None:
        subparser.add_argument("dataset")
        subparser.add_argument("--config", required=True)
        subparser.add_argument("--run-id", required=True)
        subparser.add_argument("--pilot", type=int)
        subparser.add_argument("--sample-id", action="append", default=[])
        subparser.add_argument("--methods")
        subparser.add_argument(
            "--fake-response-path",
            help=(
                "Use a fixed local response for pipeline validation only; "
                "never eligible as research evidence"
            ),
        )
        subparser.add_argument("--no-resume", action="store_true")

    run_parser = subparsers.add_parser("run")
    common(run_parser)
    prepare_parser = subparsers.add_parser("prepare")
    common(prepare_parser)
    generate_parser = subparsers.add_parser("generate")
    common(generate_parser)
    evaluate_parser = subparsers.add_parser("evaluate")
    common(evaluate_parser)
    aggregate_parser = subparsers.add_parser("aggregate")
    common(aggregate_parser)
    verify_parser = subparsers.add_parser("verify-integrity")
    common(verify_parser)
    return parser


def _runner_from_args(args: argparse.Namespace) -> ExperimentRunner:
    project_root = SRC_ROOT.parent
    config = load_config(args.config, project_root)
    if args.methods:
        methods = [
            value.strip().upper()
            for value in args.methods.split(",")
            if value.strip()
        ]
        config["experiment"]["methods"] = methods
        configured_order = config["experiment"].get(
            "variant_order", methods
        )
        config["experiment"]["variant_order"] = [
            method for method in configured_order if method in methods
        ]
    if args.fake_response_path:
        fake_path = Path(args.fake_response_path).expanduser()
        if not fake_path.is_absolute():
            fake_path = project_root / fake_path
        config["llm"]["fake_response_path"] = str(fake_path.resolve())
    if args.no_resume:
        config["experiment"]["resume"] = False
    validate_config(config)
    config["_config_sha256"] = stable_json_sha256(
        {
            key: value
            for key, value in config.items()
            if not key.startswith("_")
        }
    )
    return ExperimentRunner(
        args.dataset,
        config,
        args.run_id,
        pilot=args.pilot,
        sample_ids=args.sample_id or None,
    )


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    runner = _runner_from_args(args)
    if args.command == "prepare":
        runner.prepare()
        return 0
    if args.command == "run":
        runner.run()
        return 0
    if args.command == "generate":
        runner.generate()
        return 0
    if args.command == "evaluate":
        runner.evaluate()
        return 0
    if args.command == "aggregate":
        runner.aggregate()
        return 0
    if args.command == "verify-integrity":
        runner.verify()
        return 0
    return 2


def main_from_legacy(argv: list[str]) -> int:
    """Translate ``<dataset> experiment ...`` accepted by legacy main.py."""
    if "experiment" not in argv:
        raise ValueError("missing experiment marker")
    marker = argv.index("experiment")
    if marker == 0:
        raise ValueError("dataset path must precede experiment")
    dataset = argv[0]
    tail = argv[marker + 1 :]
    translated = ["run", dataset]
    index = 0
    while index < len(tail):
        item = tail[index]
        if item == "--protocol":
            # The mixed protocol is fixed: P0 legacy, A0/B0 one-shot.
            index += 2
            continue
        translated.append(item)
        index += 1
    return main(translated)


if __name__ == "__main__":
    raise SystemExit(main())

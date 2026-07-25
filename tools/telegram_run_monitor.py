#!/usr/bin/env python3
"""Telegram monitor for one experiment run.

Usage:
  TELEGRAM_BOT_TOKEN='...' TELEGRAM_CHAT_ID='...' \
    python3 tools/telegram_run_monitor.py

The monitor sends a detailed update every five minutes and uploads the final
reports/dashboard when the run reaches the evaluation phase.
"""

from __future__ import annotations

import json
import os
import threading
import time
from pathlib import Path
from typing import Any

import telebot


PROJECT_ROOT = Path("/home/dungbv/ev/capstone_project")
RUN_ID = os.environ.get(
    "RUN_ID", "25_7_2026_full-experiment-gemini25pro"
)
RUN_ROOT = PROJECT_ROOT / "result" / "experiments" / RUN_ID
INTERVAL_SECONDS = int(os.environ.get("MONITOR_INTERVAL_SECONDS", "300"))
TOKEN = "8638656900:AAHgw3Cdf1MnBCTXmIzYULMLq4wEDOyfPkQ"
TARGET_CHAT_ID: int | None = None

bot = telebot.TeleBot(TOKEN)


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def result_files() -> list[Path]:
    return sorted(RUN_ROOT.glob("samples/*/*/result.json"))


def status_snapshot() -> dict[str, Any]:
    results = [load_json(path) for path in result_files()]
    methods = {"P0": {}, "A0": {}, "B0": {}}
    for method in methods:
        rows = [row for row in results if row.get("method") == method]
        methods[method] = {
            "total": len(rows),
            "llm_done": sum(bool(row.get("generation")) for row in rows),
            "build_failed": sum(
                row.get("failure_code") == "CANDIDATE_BUILD_FAILED"
                for row in rows
            ),
            "finalized": sum(row.get("final_stage") == "finalized" for row in rows),
            "waiting_quota": sum(
                row.get("terminal_status") == "WAITING_FOR_QUOTA" for row in rows
            ),
        }

    sample_ids = sorted({row.get("sample_id") for row in results if row.get("sample_id")})
    fully_generated = 0
    for sample_id in sample_ids:
        sample_rows = [row for row in results if row.get("sample_id") == sample_id]
        if {row.get("method") for row in sample_rows if row.get("generation")} == {"P0", "A0", "B0"}:
            fully_generated += 1

    audit_path = RUN_ROOT / "audit" / "events.jsonl"
    last_event: dict[str, Any] = {}
    try:
        lines = audit_path.read_text(encoding="utf-8").splitlines()
        if lines:
            last_event = json.loads(lines[-1])
    except (OSError, ValueError):
        pass

    return {
        "methods": methods,
        "sample_count": len(sample_ids),
        "fully_generated": fully_generated,
        "preparation": len(list(RUN_ROOT.glob("samples/*/preparation_manifest.json"))),
        "processing": len(list(RUN_ROOT.glob("samples/*/processing_manifest.json"))),
        "aggregate": sorted(path.name for path in (RUN_ROOT / "aggregate").glob("*") if path.is_file()),
        "last_event": last_event,
        "complete": (RUN_ROOT / "integrity_report.json").is_file()
        and (RUN_ROOT / "aggregate" / "dashboard.html").is_file(),
    }


def format_update(snapshot: dict[str, Any]) -> str:
    event = snapshot["last_event"]
    payload = event.get("payload") or {}
    lines = [
        f"📊 Run: {RUN_ID}",
        f"Preparation: {snapshot['preparation']}/40",
        f"Generation đủ P0/A0/B0: {snapshot['fully_generated']}/40",
        f"Processing manifests: {snapshot['processing']}/40",
        "",
    ]
    for method, data in snapshot["methods"].items():
        lines.append(
            f"{method}: LLM {data['llm_done']}/{data['total']} | "
            f"finalized {data['finalized']} | build fail {data['build_failed']} | "
            f"quota wait {data['waiting_quota']}"
        )
    lines += [
        "",
        f"Phase/event: {event.get('stage', '?')} / {event.get('event_type', '?')}",
        f"Sample: {event.get('sample_id', '?')}  Method: {event.get('method', '?')}",
        f"Status: {event.get('status', '?')}",
    ]
    if payload.get("failure_code"):
        lines.append(f"Failure: {payload['failure_code']}")
    if snapshot["aggregate"]:
        lines.append("Aggregate: " + ", ".join(snapshot["aggregate"][:8]))
    if snapshot["complete"]:
        lines.insert(1, "✅ RUN COMPLETE")
    return "\n".join(lines)


def send_file(path: Path, caption: str) -> None:
    if TARGET_CHAT_ID is not None and path.is_file():
        with path.open("rb") as handle:
            bot.send_document(TARGET_CHAT_ID, handle, caption=caption)


def send_final_report() -> None:
    if TARGET_CHAT_ID is None:
        return
    aggregate = RUN_ROOT / "aggregate"
    bot.send_message(TARGET_CHAT_ID, "✅ Full pipeline đã hoàn tất. Đang gửi full report...")
    for name in (
        "report.md",
        "metrics.json",
        "metrics_long.csv",
        "statistics.json",
        "dashboard.html",
        "figures_manifest.json",
    ):
        send_file(aggregate / name, f"{RUN_ID} - {name}")
    send_file(RUN_ROOT / "integrity_report.json", f"{RUN_ID} - integrity report")


@bot.message_handler(commands=["report"])
def report_command(message: Any) -> None:
    """Send an immediate status report, plus full artifacts when complete."""
    global TARGET_CHAT_ID
    TARGET_CHAT_ID = message.chat.id
    snapshot = status_snapshot()
    bot.send_message(message.chat.id, format_update(snapshot))
    if snapshot["complete"]:
        aggregate = RUN_ROOT / "aggregate"
        for name in (
            "report.md",
            "metrics.json",
            "metrics_long.csv",
            "statistics.json",
            "dashboard.html",
            "figures_manifest.json",
        ):
            path = aggregate / name
            if path.is_file():
                with path.open("rb") as handle:
                    bot.send_document(message.chat.id, handle, caption=f"{RUN_ID} - {name}")
        integrity = RUN_ROOT / "integrity_report.json"
        if integrity.is_file():
            with integrity.open("rb") as handle:
                bot.send_document(message.chat.id, handle, caption=f"{RUN_ID} - integrity report")


@bot.message_handler(commands=["start"])
def start_command(message: Any) -> None:
    global TARGET_CHAT_ID
    TARGET_CHAT_ID = message.chat.id
    bot.send_message(
        message.chat.id,
        f"Monitor {RUN_ID} đang hoạt động. Dùng /report để lấy trạng thái ngay.",
    )


def polling() -> None:
    bot.infinity_polling(skip_pending=True)


def monitor() -> None:
    if not RUN_ROOT.is_dir():
        bot.send_message(CHAT_ID, f"❌ Không tìm thấy run directory: {RUN_ROOT}")
        return
    last_message = ""
    final_sent = False
    while True:
        snapshot = status_snapshot()
        message = format_update(snapshot)
        if TARGET_CHAT_ID is not None and message != last_message:
            bot.send_message(TARGET_CHAT_ID, message)
            last_message = message
        if snapshot["complete"] and not final_sent:
            send_final_report()
            final_sent = True
            return
        time.sleep(INTERVAL_SECONDS)


if __name__ == "__main__":
    threading.Thread(target=monitor, daemon=True).start()
    polling()

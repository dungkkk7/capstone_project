import os
import sys
import subprocess
import glob
import json
from pathlib import Path

# Add project root to sys.path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from tools.llvm_to_c import transpile_llvm_ir_to_c
from src.metrics_evaluator import calculate_ir_metrics, calculate_c_metrics

def load_env_config(env_path: str = None) -> dict:
    if env_path is None:
        env_path = os.path.join(PROJECT_ROOT, "configs", "pipeline_config.env")
        
    config = {
        "LLM_MODEL": "gemini-2.5-flash",
        "LLM_TEMPERATURE": "0.1",
        "PROMPT_MODE_RAW_IR": "",
        "PROMPT_MODE_CLEAN_PSEUDOCODE": "",
        "PROMPT_MODE_CLEAN_IR": "",
        "PROMPT_MODE_CLEAN_IR_AND_PSEUDOCODE": ""
    }
    
    if os.path.exists(env_path):
        with open(env_path, "r", encoding="utf-8") as f:
            content = f.read()
            # Simple env parser
            current_key = None
            current_val = []
            for line in content.splitlines():
                if line.startswith("#") or not line.strip():
                    continue
                if "=" in line and not line.startswith(" ") and not line.startswith("\t"):
                    if current_key:
                        config[current_key] = "\n".join(current_val).strip('"').strip("'")
                    k, v = line.split("=", 1)
                    current_key = k.strip()
                    current_val = [v.strip()]
                elif current_key:
                    current_val.append(line)
            if current_key:
                config[current_key] = "\n".join(current_val).strip('"').strip("'")
    return config

def run_pipeline_mode(
    mode: str,
    raw_ir_path: str,
    clean_ir_path: str,
    output_dir: str,
    env_config: dict = None
) -> dict:
    """Executes one of the 4 modes and evaluates IR + C metrics."""
    if env_config is None:
        env_config = load_env_config()

    os.makedirs(output_dir, exist_ok=True)
    case_name = Path(output_dir).name

    clean_pseudocode_path = os.path.join(output_dir, f"{case_name}_clean_pseudocode.c")

    # Always generate LLVM-to-C transpiled C if clean_ir exists
    if os.path.exists(clean_ir_path):
        transpile_llvm_ir_to_c(clean_ir_path, clean_pseudocode_path)
    elif os.path.exists(raw_ir_path):
        transpile_llvm_ir_to_c(raw_ir_path, clean_pseudocode_path)

    # Calculate IR deobfuscation metrics
    ir_metrics = calculate_ir_metrics(raw_ir_path, clean_ir_path)

    # Determine prompt & LLM representation based on Mode
    prompt_template = ""
    ir_text = ""
    pseudo_text = ""

    if mode == "raw_ir":
        prompt_template = env_config.get("PROMPT_MODE_RAW_IR", "")
        if os.path.exists(raw_ir_path):
            ir_text = open(raw_ir_path, errors="ignore").read()
        formatted_prompt = prompt_template.replace("{RAW_IR}", ir_text)

    elif mode == "clean_pseudocode":
        prompt_template = env_config.get("PROMPT_MODE_CLEAN_PSEUDOCODE", "")
        if os.path.exists(clean_pseudocode_path):
            pseudo_text = open(clean_pseudocode_path, errors="ignore").read()
        formatted_prompt = prompt_template.replace("{CLEAN_PSEUDOCODE}", pseudo_text)

    elif mode == "clean_ir":
        prompt_template = env_config.get("PROMPT_MODE_CLEAN_IR", "")
        if os.path.exists(clean_ir_path):
            ir_text = open(clean_ir_path, errors="ignore").read()
        formatted_prompt = prompt_template.replace("{CLEAN_IR}", ir_text)

    elif mode == "clean_ir_and_pseudocode":
        prompt_template = env_config.get("PROMPT_MODE_CLEAN_IR_AND_PSEUDOCODE", "")
        if os.path.exists(clean_ir_path):
            ir_text = open(clean_ir_path, errors="ignore").read()
        if os.path.exists(clean_pseudocode_path):
            pseudo_text = open(clean_pseudocode_path, errors="ignore").read()
        formatted_prompt = prompt_template.replace("{CLEAN_IR}", ir_text).replace("{CLEAN_PSEUDOCODE}", pseudo_text)
    else:
        raise ValueError(f"Unknown mode: {mode}")

    # Calculate C metrics
    c_metrics = calculate_c_metrics(clean_pseudocode_path)

    report = {
        "case": case_name,
        "mode": mode,
        "llm_model": env_config.get("LLM_MODEL", "gemini-2.5-flash"),
        "ir_metrics": ir_metrics,
        "c_metrics": c_metrics,
        "formatted_prompt_length": len(formatted_prompt)
    }

    report_path = os.path.join(output_dir, f"{case_name}_mode_{mode}_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    return report

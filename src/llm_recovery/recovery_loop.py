import os
import sys
import re
import json
import subprocess
import shutil
import requests
from typing import Optional, Dict, List, Tuple

# Import SemanticFuzzer and other utilities from the existing fuzzing module
from fuzzing_equi_check.fuzzing import SemanticFuzzer, TemplateEvaluator, make_bytes_generator, DEFAULT_TEMPLATES, find_clang

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

def log_info(msg):
    print(f"{Color.BLUE}[*] {msg}{Color.END}")

def log_success(msg):
    print(f"{Color.GREEN}[✓] {msg}{Color.END}")

def log_warning(msg):
    print(f"{Color.YELLOW}[!] {msg}{Color.END}")

def log_error(msg):
    print(f"{Color.RED}[✗] {msg}{Color.END}")

def query_llm(messages: List[Dict[str, str]], api_key: Optional[str] = None, api_base: Optional[str] = None, model: Optional[str] = None) -> str:
    if not api_key:
        api_key = os.environ.get("DEEPSEEK_API_KEY") or os.environ.get("OPENAI_API_KEY")
        
    if not api_base:
        if "DEEPSEEK_API_KEY" in os.environ and "DEEPSEEK_API_BASE" in os.environ:
            api_base = os.environ.get("DEEPSEEK_API_BASE")
        elif "DEEPSEEK_API_KEY" in os.environ:
            api_base = "https://api.deepseek.com/chat/completions"
        else:
            api_base = os.environ.get("DEEPSEEK_API_BASE") or os.environ.get("OPENAI_API_BASE") or os.environ.get("OPENAI_BASE_URL") or "https://api.deepseek.com/chat/completions"
            
    if not model:
        if "deepseek.com" in api_base:
            model = os.environ.get("DEEPSEEK_MODEL") or "deepseek-chat"
        elif "localhost" in api_base:
            model = os.environ.get("DEEPSEEK_MODEL") or "ag/gemini-3-flash"
        else:
            model = os.environ.get("DEEPSEEK_MODEL") or "deepseek-chat"
        
    if not api_key:
        raise ValueError("API key not found. Please set DEEPSEEK_API_KEY or OPENAI_API_KEY environment variable.")
        
    if not api_base.endswith("/chat/completions") and not api_base.endswith("/completions"):
        if api_base.endswith("/"):
            api_base += "chat/completions"
        else:
            api_base += "/chat/completions"
            
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    
    data = {
        "model": model,
        "messages": messages,
        "temperature": 0.1,
        "stream": True
    }
    
    log_info(f"Querying LLM ({model}) at {api_base}...")
    
    try:
        response = requests.post(api_base, headers=headers, json=data, stream=True, timeout=180)
        response.raise_for_status()
    except Exception as re_err:
        if 'response' in locals() and response is not None:
            raise RuntimeError(f"HTTP Request failed: {re_err}. Status: {response.status_code}. Response: {response.text[:500]}")
        else:
            raise RuntimeError(f"HTTP Request failed: {re_err}")
    
    content_chunks = []
    raw_lines = []
    
    try:
        for line in response.iter_lines():
            if not line:
                continue
            line_str = line.decode('utf-8', errors='ignore').strip()
            raw_lines.append(line_str)
            
            if line_str.startswith("data: "):
                data_content = line_str[6:]
                if data_content == "[DONE]":
                    continue
                try:
                    chunk_json = json.loads(data_content)
                    if "error" in chunk_json:
                        raise RuntimeError(f"API Error streamed: {chunk_json['error']}")
                    if "choices" in chunk_json and len(chunk_json["choices"]) > 0:
                        delta = chunk_json["choices"][0].get("delta", {})
                        if "content" in delta:
                            content_chunks.append(delta["content"])
                except Exception as je:
                    if "API Error" in str(je):
                        raise je
            else:
                try:
                    full_json = json.loads(line_str)
                    if "error" in full_json:
                        raise RuntimeError(f"API Error in body: {full_json['error']}")
                    if "choices" in full_json and len(full_json["choices"]) > 0:
                        content = full_json["choices"][0]["message"]["content"]
                        if content:
                            return content
                except Exception as je:
                    if "API Error" in str(je):
                        raise je
    except Exception as stream_err:
        if "API Error" in str(stream_err):
            raise stream_err
        raise RuntimeError(f"Error reading stream: {stream_err}. Raw buffer: {' '.join(raw_lines[:5])}")
                
    if content_chunks:
        return "".join(content_chunks)
        
    raw_buf = "\n".join(raw_lines[:10])
    raise RuntimeError(f"LLM returned empty response or stream did not match expected SSE data format. Raw response head:\n{raw_buf}")

def extract_c_code(text: str) -> str:
    match = re.search(r"```c(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1).strip()
    match = re.search(r"```(.*?)```", text, re.DOTALL)
    if match:
        return match.group(1).strip()
    return text.strip()

def run_ida_to_list_functions(ida_path: str, binary_path: str, output_json_path: str) -> List[Dict]:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    list_script = os.path.join(script_dir, "list_functions.py")
    
    env = os.environ.copy()
    env["TVHEADLESS"] = "1"
    env["IDALOG"] = "/dev/null"
    
    cmd_str = f'{ida_path} -B -S"{list_script} {output_json_path}" {binary_path}'
    
    try:
        subprocess.run(cmd_str, shell=True, env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
        if os.path.exists(output_json_path):
            with open(output_json_path, "r") as f:
                return json.load(f)
    except Exception as e:
        log_error(f"Failed to list functions with IDA: {e}")
        
    return []

def run_ida_to_decompile_function(ida_path: str, binary_path: str, func_name: str, output_c_path: str) -> bool:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    decompile_script = os.path.join(script_dir, "decompile_func.py")
    
    env = os.environ.copy()
    env["TVHEADLESS"] = "1"
    env["IDALOG"] = "/dev/null"
    
    cmd_str = f'{ida_path} -B -S"{decompile_script} {func_name} {output_c_path}" {binary_path}'
    
    try:
        subprocess.run(cmd_str, shell=True, env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
        return os.path.exists(output_c_path) and os.path.getsize(output_c_path) > 0
    except Exception as e:
        log_warning(f"Timeout/Error decompiling function {func_name} with IDA: {e}")
        return False

def get_candidate_pseudocode(binary_path: str, case_output_dir: str, ida_path: str = "/opt/ida-pro-9.3/idat") -> str:
    funcs_json = os.path.join(case_output_dir, "funcs.json")
    funcs = run_ida_to_list_functions(ida_path, binary_path, funcs_json)
    
    if not funcs:
        log_error("Could not obtain function list from IDA Pro.")
        return ""
        
    # Decompile ALL functions returned by IDA Pro to recover full binary code
    candidates = [f["name"] for f in funcs]
    log_info(f"Found candidate functions for full binary decompilation: {candidates}")
    
    decompiled_blocks = []
    
    for name in candidates:
        log_info(f"Decompiling function: {name}")
        out_func_c = os.path.join(case_output_dir, f"decomp_{name}.c")
        if os.path.exists(out_func_c):
            os.remove(out_func_c)
            
        success = run_ida_to_decompile_function(ida_path, binary_path, name, out_func_c)
        if success:
            with open(out_func_c, "r") as f:
                code = f.read()
            decompiled_blocks.append(f"// Function: {name}\n{code}\n")
        else:
            log_warning(f"Skipping decompilation of {name} due to IDA timeout/crash.")
            
    return "\n".join(decompiled_blocks)

def run_recovery_loop(
    obfuscated_binary_path: str,
    brightened_bc_path: str,
    output_recovered_c_path: str,
    case_output_dir: str,
    max_iters: int = 5,
    ida_path: str = "/opt/ida-pro-9.3/idat"
) -> bool:
    log_info(f"Starting LLM Recovery Loop for {obfuscated_binary_path}")
    
    tmp_bin = os.path.join(case_output_dir, "brightened_O0.bin")
    if os.path.exists(tmp_bin):
        os.remove(tmp_bin)
        
    clang = find_clang()
    log_info(f"Compiling {brightened_bc_path} to {tmp_bin} using {clang} -O0...")
    comp_cmd = [clang, "-O0", "-lm", brightened_bc_path, "-o", tmp_bin]
    try:
        subprocess.run(comp_cmd, check=True, capture_output=True)
        log_success(f"Compiled successfully to {tmp_bin}")
    except subprocess.CalledProcessError as e:
        log_error(f"Failed to compile brightened bitcode: {e.stderr.decode()}")
        return False
        
    pseudocode = get_candidate_pseudocode(tmp_bin, case_output_dir, ida_path)
    if not pseudocode:
        log_error("Failed to recover any pseudocode candidate.")
        return False
        
    log_info(f"Obtained pseudocode (length {len(pseudocode)} chars)")
    
    raw_pseudocode_path = os.path.join(case_output_dir, "raw_pseudocode.c")
    with open(raw_pseudocode_path, "w") as f:
        f.write(pseudocode)
    log_info(f"Saved raw pseudocode to {raw_pseudocode_path}")
    
    system_prompt = (
        "You are an expert software engineer and reverse engineer.\n"
        "Your task is to analyze candidate C pseudocode (decompiled from a lifted binary) and rewrite it into clean, readable, standard C code that matches the original functionality.\n\n"
        "Guidelines:\n"
        "1. Remove all McSema/Remill architecture-specific registers state boilerplate (like &_mcsema_reg_state, _mcsema_reg_state, RAX, RBX, etc.).\n"
        "2. Restore clean function signatures (e.g., main(int argc, char **argv) instead of sub_xxx_native(__int64 a1, __int64 a2)).\n"
        "3. Reconstruct clear loops, condition checks, array indexing, and standard types (int, char, char*, void*, etc.).\n"
        "4. Use standard library functions (printf, malloc, free, scanf, strlen, memset, etc.) where appropriate.\n"
        "5. Ensure the rewritten code is syntactically valid C and compiles cleanly.\n"
        "6. The code must be semantically equivalent to the original logic so that differential fuzzing succeeds.\n"
        "7. Return ONLY the final C code wrapped inside a ```c ... ``` code block. Do not write any explanations before or after."
    )
    
    user_prompt = (
        f"Here is the raw decompiled candidate pseudocode from the binary:\n\n"
        f"```c\n{pseudocode}\n```\n\n"
        f"Please rewrite this into clean, functional, and semantically equivalent C code."
    )
    
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]
    
    template_content = None
    for key in DEFAULT_TEMPLATES.keys():
        if key in obfuscated_binary_path.lower():
            template_content = DEFAULT_TEMPLATES[key]
            log_info(f"Fuzzer using template configuration for benchmark '{key}'")
            break
            
    if template_content:
        generator = TemplateEvaluator(template_content)
    else:
        log_warning("No matching benchmark template. Fuzzer will use random bytes generator.")
        generator = make_bytes_generator()
        
    for iteration in range(1, max_iters + 1):
        log_info(f"--- LLM Recovery Iteration {iteration}/{max_iters} ---")
        
        try:
            llm_response = query_llm(messages)
        except Exception as e:
            log_error(f"Error querying LLM: {e}")
            return False
            
        recovered_c = extract_c_code(llm_response)
        
        temp_c_path = os.path.join(case_output_dir, f"recovered_c_iter{iteration}.c")
        with open(temp_c_path, "w") as f:
            f.write(recovered_c)
            
        clang_compiler = find_clang()
        recovered_bin_path = os.path.join(case_output_dir, f"recovered_bin_iter{iteration}.bin")
        if os.path.exists(recovered_bin_path):
            os.remove(recovered_bin_path)
            
        log_info(f"Compiling recovered C code to {recovered_bin_path}...")
        compile_cmd = [clang_compiler, "-O2", "-lm", temp_c_path, "-o", recovered_bin_path]
        comp_proc = subprocess.run(compile_cmd, capture_output=True)
        
        if comp_proc.returncode != 0:
            stderr_msg = comp_proc.stderr.decode('utf-8', errors='replace')
            log_error(f"Compilation failed for recovered C code:\n{stderr_msg}")
            
            messages.append({"role": "assistant", "content": llm_response})
            messages.append({
                "role": "user",
                "content": f"The C code you generated failed to compile. Here are the compilation errors:\n\n```\n{stderr_msg}\n```\n\nPlease correct the C code to fix these compilation errors while keeping the same logic."
            })
            continue
            
        log_success("Compilation succeeded. Running differential fuzzing check...")
        
        fuzzer = None
        try:
            fuzzer = SemanticFuzzer(recovered_bin_path, obfuscated_binary_path)
            fuzz_report = fuzzer.run_differential_test(
                iterations=100,
                generator=generator,
                num_workers=4
            )
            
            ratio = fuzz_report["equivalence_ratio"]
            is_fully_equivalent = fuzz_report.get("is_fully_equivalent", ratio == 100.0)
            
            log_info(f"Fuzzing report: Strict Equivalence = {ratio:.2f}% (Matches: {fuzz_report['matches']}, Mismatches: {fuzz_report['mismatches']})")
            
            if is_fully_equivalent:
                log_success("SEMANTIC EQUIVALENCE CONFIRMED! Final product recovered successfully.")
                shutil.copy2(temp_c_path, output_recovered_c_path)
                log_success(f"Saved final recovered source code to: {output_recovered_c_path}")
                return True
            else:
                log_warning("Fuzzing failed to confirm full semantic equivalence.")
                
                mismatch_context = "The code compiled, but differential fuzzing showed it is NOT semantically equivalent to the original obfuscated binary.\n"
                mismatch_context += "Here are the details of the mismatching test cases:\n\n"
                
                if "mismatch_examples" in fuzz_report and fuzz_report["mismatch_examples"]:
                    for sample in fuzz_report["mismatch_examples"][:5]:
                        mismatch_context += f"--- Mismatch Case #{sample['index']} ---\n"
                        if sample['args']:
                            mismatch_context += f"Arguments: {sample['args']}\n"
                        mismatch_context += f"Stdin input: {repr(sample['stdin'])}\n"
                        mismatch_context += f"Expected output (Original): Exit code {sample['prog2']['returncode']}, stdout: {repr(sample['prog2']['stdout'])}, stderr: {repr(sample['prog2']['stderr'])}\n"
                        mismatch_context += f"Actual output (Your code): Exit code {sample['prog1']['returncode']}, stdout: {repr(sample['prog1']['stdout'])}, stderr: {repr(sample['prog1']['stderr'])}\n\n"
                else:
                    mismatch_context += f"Mismatches: {fuzz_report['mismatches']}\n"
                    mismatch_context += f"Timeouts: F1={fuzz_report['timeouts']['bin1']}, F2={fuzz_report['timeouts']['bin2']}\n"
                    mismatch_context += f"Crashes: F1={fuzz_report['crashes']['bin1']}, F2={fuzz_report['crashes']['bin2']}\n"
                    
                mismatch_context += "Please identify the logic difference between your rewritten C code and the expected behavior, and fix the rewritten C code."
                
                messages.append({"role": "assistant", "content": llm_response})
                messages.append({"role": "user", "content": mismatch_context})
                
        except Exception as fe:
            log_error(f"Fuzzing exception: {fe}")
            return False
        finally:
            if fuzzer:
                fuzzer.cleanup()
                
    log_error("Max recovery iterations reached. Failed to recover fully equivalent source code.")
    return False

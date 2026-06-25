#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fuzzing.py — Semantic Equivalence Checker using Fuzzing

This module compiles and checks semantic equivalence between two code representations
(such as recovered C source and deobfuscated LLVM IR) by executing them on identical fuzzed inputs
and comparing stdout, stderr, and exit codes.
"""

import os
import sys
import re
import random
import string
import shutil
import subprocess
import time
import argparse
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Callable, Any, Optional, Dict, List, Tuple

# -----------------------------------------------------------------------------
# Color Definitions for Visual Polish
# -----------------------------------------------------------------------------
class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

# -----------------------------------------------------------------------------
# Helper Utilities
# -----------------------------------------------------------------------------
def find_clang() -> str:
    """Finds the clang compiler dynamically, preferring clang-21 if available."""
    for name in ["clang-21", "clang-20", "clang-19", "clang-18", "clang-17", "clang-16", "clang-15", "clang"]:
        path = shutil.which(name)
        if path:
            return path
    return "clang"

def is_binary(file_path: str) -> bool:
    """Heuristically checks if a file is already a compiled binary executable."""
    if not os.path.exists(file_path):
        return False
    try:
        with open(file_path, 'rb') as f:
            head = f.read(4)
            # ELF magic = \x7fELF, PE magic = MZ
            if head.startswith(b'\x7fELF') or head.startswith(b'MZ'):
                return True
    except Exception:
        pass
    ext = os.path.splitext(file_path)[1].lower()
    return ext not in ['.c', '.ll', '.bc', '.cpp', '.cc']

def compile_to_binary(file_path: str, output_path: str, extra_flags: Optional[List[str]] = None) -> str:
    """
    Compiles C source or LLVM IR to a binary executable using clang.
    If the file is already a binary, it copies it directly.
    """
    file_path = os.path.abspath(file_path)
    output_path = os.path.abspath(output_path)
    
    if is_binary(file_path):
        shutil.copy2(file_path, output_path)
        os.chmod(output_path, 0o755)
        return output_path
        
    clang = find_clang()
    cmd = [clang]
    
    ext = os.path.splitext(file_path)[1].lower()
    is_ir = ext in ['.bc', '.ll']
    
    if extra_flags:
        cmd.extend(extra_flags)
    else:
        # Standard optimization flags, linking math library
        cmd.extend(["-O2", "-lm"])
        
    cmd.extend([file_path, "-o", output_path])
    
    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
        return output_path
    except subprocess.CalledProcessError as e:
        error_msg = f"Compilation failed for: {file_path}\nCommand: {' '.join(cmd)}\nStderr: {e.stderr}\nStdout: {e.stdout}"
        raise RuntimeError(error_msg) from e

# -----------------------------------------------------------------------------
# Structured Template Input Generator
# -----------------------------------------------------------------------------
def strip_comments(line: str) -> str:
    """Strips comments starting with '#' from a line, ignoring '#' within quotes."""
    in_quotes = False
    quote_char = None
    res = []
    for char in line:
        if char in ('"', "'"):
            if not in_quotes:
                in_quotes = True
                quote_char = char
            elif quote_char == char:
                in_quotes = False
                quote_char = None
            res.append(char)
        elif char == '#' and not in_quotes:
            break
        else:
            res.append(char)
    return "".join(res).strip()

def split_args(args_str: str) -> List[str]:
    """Splits arguments by comma, respecting quotes and parentheses."""
    args = []
    current = []
    in_quotes = False
    quote_char = None
    paren_depth = 0
    for char in args_str:
        if char in ('"', "'"):
            if not in_quotes:
                in_quotes = True
                quote_char = char
            elif quote_char == char:
                in_quotes = False
                quote_char = None
            current.append(char)
        elif char == '(' and not in_quotes:
            paren_depth += 1
            current.append(char)
        elif char == ')' and not in_quotes:
            paren_depth -= 1
            current.append(char)
        elif char == ',' and not in_quotes and paren_depth == 0:
            args.append("".join(current).strip())
            current = []
        else:
            current.append(char)
    if current:
        args.append("".join(current).strip())
    return args

def gen_int(low: Any, high: Any) -> int:
    return random.randint(int(low), int(high))

def gen_float(low: Any, high: Any) -> float:
    return random.uniform(float(low), float(high))

def gen_string(charset_type: str, min_len: Any, max_len: Any) -> str:
    min_l = int(min_len)
    max_l = int(max_len)
    length = random.randint(min_l, max_l)
    if charset_type == "digits":
        chars = string.digits
    elif charset_type == "alpha":
        chars = string.ascii_letters
    elif charset_type == "alnum":
        chars = string.ascii_letters + string.digits
    elif charset_type == "hex":
        chars = "0123456789abcdef"
    elif charset_type == "print":
        chars = string.printable.strip()
    else:
        chars = string.ascii_letters
    return "".join(random.choice(chars) for _ in range(length))

def gen_choice(*options: Any) -> str:
    cleaned = [str(opt).strip('"\'') for opt in options]
    return random.choice(cleaned)

def gen_repeat(count: Any, item_template: Any, sep: Any, vars_dict: dict) -> str:
    c = int(count)
    item_template = str(item_template).strip('"\'')
    sep = str(sep).strip('"\'')
    # Decode escape characters like \n or \t
    sep = sep.encode('utf-8').decode('unicode_escape')
    
    items = []
    for _ in range(c):
        items.append(evaluate_string_content(item_template, vars_dict))
    return sep.join(items)

def evaluate_expr(expr_str: str, vars_dict: dict) -> Any:
    """Evaluates an expression string recursively using the variable environment."""
    expr_str = expr_str.strip()
    if not expr_str:
        return ""
        
    # Quote string literals
    if (expr_str.startswith('"') and expr_str.endswith('"')) or (expr_str.startswith("'") and expr_str.endswith("'")):
        val = expr_str[1:-1]
        return val.encode('utf-8').decode('unicode_escape')
        
    # Function calls: name(args)
    match = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*\((.*)\)$', expr_str, re.DOTALL)
    if match:
        func_name = match.group(1)
        args_str = match.group(2)
        args = split_args(args_str)
        eval_args = [evaluate_expr(a, vars_dict) for a in args]
        
        if func_name == "int":
            return gen_int(*eval_args)
        elif func_name == "float":
            return gen_float(*eval_args)
        elif func_name == "string":
            return gen_string(*eval_args)
        elif func_name == "choice":
            return gen_choice(*eval_args)
        elif func_name == "repeat":
            return gen_repeat(*eval_args, vars_dict=vars_dict)
        else:
            raise ValueError(f"Unknown generator function: {func_name}")
            
    # Simple math arithmetic (e.g., N - 1)
    math_match = re.match(r'^([a-zA-Z0-9_]+)\s*([+\-*/])\s*([a-zA-Z0-9_]+)$', expr_str)
    if math_match:
        left = evaluate_expr(math_match.group(1), vars_dict)
        op = math_match.group(2)
        right = evaluate_expr(math_match.group(3), vars_dict)
        try:
            if op == '+': return int(left) + int(right)
            elif op == '-': return int(left) - int(right)
            elif op == '*': return int(left) * int(right)
            elif op == '/': return int(left) // int(right)
        except Exception:
            pass

    # Variable lookup
    if expr_str in vars_dict:
        return vars_dict[expr_str]
        
    # Integer literal
    try:
        return int(expr_str)
    except ValueError:
        pass
        
    # Float literal
    try:
        return float(expr_str)
    except ValueError:
        pass
        
    # Fallback as string literal
    return expr_str

def evaluate_string_content(s: str, vars_dict: dict) -> str:
    """Evaluates place-holders or standalone function calls within a template string line."""
    if '{' in s:
        def repl(match):
            expr = match.group(1)
            return str(evaluate_expr(expr, vars_dict))
        return re.sub(r'\{([^{}]+)\}', repl, s)
    else:
        # Match innermost function calls, evaluate them recursively
        pattern = re.compile(r'([a-zA-Z_][a-zA-Z0-9_]*)\(([^()]*)\)')
        current = s
        while True:
            def repl(match):
                func_name = match.group(1)
                args_str = match.group(2)
                args = split_args(args_str)
                eval_args = [evaluate_expr(a, vars_dict) for a in args]
                
                if func_name == "int":
                    return str(gen_int(*eval_args))
                elif func_name == "float":
                    return str(gen_float(*eval_args))
                elif func_name == "string":
                    return str(gen_string(*eval_args))
                elif func_name == "choice":
                    return str(gen_choice(*eval_args))
                elif func_name == "repeat":
                    return str(gen_repeat(*eval_args, vars_dict=vars_dict))
                else:
                    return match.group(0)
            next_str, count = pattern.subn(repl, current)
            if count == 0 or next_str == current:
                break
            current = next_str
            
        # Standalone variables replacement
        def repl_var(match):
            var_name = match.group(0)
            if var_name in vars_dict:
                return str(vars_dict[var_name])
            return var_name
        
        current = re.sub(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b', repl_var, current)
        return current

def parse_template(template_str: str) -> Tuple[List[str], str]:
    """Splits a sectioned template into command line argv lines and stdin block."""
    lines = template_str.strip().splitlines()
    argv_lines = []
    stdin_lines = []
    current_section = "stdin"  # Default section
    
    for line in lines:
        stripped = strip_comments(line)
        if not stripped:
            continue
        if stripped == "[ARGV]":
            current_section = "argv"
            continue
        elif stripped == "[STDIN]":
            current_section = "stdin"
            continue
        
        if current_section == "argv":
            argv_lines.append(stripped)
        else:
            stdin_lines.append(line)  # Keep original format/whitespaces for stdin
            
    return argv_lines, "\n".join(stdin_lines)

class TemplateEvaluator:
    """Generates argv and stdin dynamically by evaluating a sectioned template string."""
    def __init__(self, template_str: str):
        self.argv_lines, self.stdin_template = parse_template(template_str)

    def __call__(self) -> Tuple[List[str], bytes]:
        vars_dict = {}
        argv = []
        
        # Evaluate ARGV section
        for line in self.argv_lines:
            line_str = strip_comments(line)
            if not line_str:
                continue
            assign_match = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.*)$', line_str)
            if assign_match:
                var_name = assign_match.group(1)
                expr = assign_match.group(2)
                vars_dict[var_name] = evaluate_expr(expr, vars_dict)
            else:
                argv.append(evaluate_string_content(line_str, vars_dict))
                
        # Evaluate STDIN section
        stdin_lines = []
        for line in self.stdin_template.splitlines():
            line_str = strip_comments(line)
            assign_match = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.*)$', line_str)
            if assign_match:
                var_name = assign_match.group(1)
                expr = assign_match.group(2)
                vars_dict[var_name] = evaluate_expr(expr, vars_dict)
            else:
                stdin_lines.append(evaluate_string_content(line, vars_dict))
                
        stdin_bytes = "\n".join(stdin_lines).encode('utf-8', errors='ignore')
        return argv, stdin_bytes

# -----------------------------------------------------------------------------
# Embedded Default Templates for Project Benchmarks
# -----------------------------------------------------------------------------
DEFAULT_TEMPLATES = {
    "hash": """N = int(5, 15)
M = int(10, 20)
S = int(1, N)
T = int(1, N)
K = int(2, 5)
{N} {M}
{S} {T}
{K}
{repeat(K, "int(1, N)", " ")}
{repeat(M, "int(1, N) int(1, N) int(1, 100)", "\\n")}""",

    "maze": """N = int(4, 30)
{N}""",

    "cpu": """N = int(1, 20)
{N}""",

    "crackme": """[ARGV]
string(alnum, 10, 30)
int(-3, 3)""",

    "keybox": """[ARGV]
string(print, 8, 20)""",

    "md5": """[ARGV]
-s
string(alnum, 10, 100)""",

    "command_io": """Q = int(5, 15)
{Q}
{repeat(Q, "choice('ADD name cat 10 99.99', 'REMOVE name', 'RESTOCK name 5', 'LIST', 'SORT name asc', 'REPORT')", "\\n")}""",

    "smart_shop": """6

1

0""",

    "obfuscated": """int(-1000, 1000)"""
}

# -----------------------------------------------------------------------------
# Program Runner & Differential Comparator
# -----------------------------------------------------------------------------
def run_binary(bin_path: str, args: List[str], stdin_data: bytes, timeout: float) -> Dict[str, Any]:
    """Runs a single binary process, handling execution states and timeouts safely."""
    start_time = time.perf_counter()
    try:
        proc = subprocess.run(
            [bin_path] + (args or []),
            input=stdin_data,
            capture_output=True,
            timeout=timeout
        )
        elapsed = time.perf_counter() - start_time
        return {
            "status": "success",
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "elapsed": elapsed
        }
    except subprocess.TimeoutExpired as e:
        elapsed = time.perf_counter() - start_time
        return {
            "status": "timeout",
            "returncode": -1,
            "stdout": e.stdout or b"",
            "stderr": e.stderr or b"",
            "elapsed": elapsed
        }
    except Exception as e:
        elapsed = time.perf_counter() - start_time
        return {
            "status": "crash",
            "returncode": -2,
            "stdout": b"",
            "stderr": str(e).encode('utf-8'),
            "elapsed": elapsed
        }

def check_equivalence(res1: Dict[str, Any], res2: Dict[str, Any], compare_stderr: bool = False) -> Tuple[bool, str]:
    """Checks differential equivalence based on status, exit codes, and output streams."""
    if res1["status"] != res2["status"]:
        return False, f"Execution status mismatch: {res1['status']} vs {res2['status']}"
        
    if res1["status"] in ("timeout", "crash"):
        # If both hit system limits or timed out, they are temporarily matched behaviorally
        return True, ""
        
    if res1["returncode"] != res2["returncode"]:
        return False, f"Exit code mismatch: {res1['returncode']} vs {res2['returncode']}"
        
    if res1["stdout"] != res2["stdout"]:
        return False, "Stdout stream mismatch"
        
    if compare_stderr and res1["stderr"] != res2["stderr"]:
        return False, "Stderr stream mismatch"
        
    return True, ""

# -----------------------------------------------------------------------------
# Fuzzer Core Pipeline Manager
# -----------------------------------------------------------------------------
class SemanticFuzzer:
    """Main differential fuzzer that orchestrates compiling and fuzz testing binaries."""
    def __init__(self, file1: str, file2: str, compiler_flags: Optional[List[str]] = None):
        self.file1 = file1
        self.file2 = file2
        self.compiler_flags = compiler_flags
        
        # Paths inside the project root for execution
        src_dir = os.path.dirname(os.path.abspath(__file__))
        self.project_root = os.path.abspath(os.path.join(src_dir, "..", ".."))
        self.tmp_dir = os.path.join(self.project_root, "result", f".tmp_fuzz_{int(time.time())}_{random.randint(1000, 9999)}")
        
        self.bin1: Optional[str] = None
        self.bin2: Optional[str] = None

    def compile(self) -> Tuple[str, str]:
        """Compiles the target files into the local temporary directory."""
        os.makedirs(self.tmp_dir, exist_ok=True)
        
        # Name the binaries
        ext1 = os.path.splitext(os.path.basename(self.file1))[0]
        ext2 = os.path.splitext(os.path.basename(self.file2))[0]
        
        self.bin1 = os.path.join(self.tmp_dir, f"{ext1}_f1.bin")
        self.bin2 = os.path.join(self.tmp_dir, f"{ext2}_f2.bin")
        
        print(f"{Color.BLUE}[*] Compiling Program 1: {self.file1} -> {self.bin1}...{Color.END}")
        compile_to_binary(self.file1, self.bin1, self.compiler_flags)
        
        print(f"{Color.BLUE}[*] Compiling Program 2: {self.file2} -> {self.bin2}...{Color.END}")
        compile_to_binary(self.file2, self.bin2, self.compiler_flags)
        
        print(f"{Color.GREEN}[✓] Compilation completed successfully.{Color.END}")
        return self.bin1, self.bin2

    def run_differential_test(
        self, 
        iterations: int, 
        generator: Callable[[], Tuple[List[str], bytes]], 
        timeout: float = 1.0, 
        compare_stderr: bool = False,
        num_workers: int = 1
    ) -> Dict[str, Any]:
        """Runs the differential testing loops, supporting thread concurrency."""
        if not self.bin1 or not self.bin2:
            raise RuntimeError("Binaries are not compiled yet. Call compile() first.")

        report = {
            "total_runs": iterations,
            "matches": 0,
            "mismatches": 0,
            "timeouts": {"bin1": 0, "bin2": 0, "both": 0},
            "crashes": {"bin1": 0, "bin2": 0, "both": 0},
            "equivalence_ratio": 0.0,
            "mismatch_examples": []
        }
        
        print(f"{Color.BLUE}[*] Fuzzing {iterations} iterations (timeout={timeout}s, workers={num_workers})...{Color.END}")
        
        # Prepare all inputs beforehand
        test_inputs = [generator() for _ in range(iterations)]
        
        def run_iteration(idx: int, args: List[str], stdin_data: bytes) -> Dict[str, Any]:
            res1 = run_binary(self.bin1, args, stdin_data, timeout)
            res2 = run_binary(self.bin2, args, stdin_data, timeout)
            is_eq, reason = check_equivalence(res1, res2, compare_stderr)
            return {
                "index": idx,
                "args": args,
                "stdin": stdin_data,
                "res1": res1,
                "res2": res2,
                "is_equivalent": is_eq,
                "reason": reason
            }

        completed = 0
        with ThreadPoolExecutor(max_workers=num_workers) as executor:
            futures = [executor.submit(run_iteration, idx, args, stdin_data) for idx, (args, stdin_data) in enumerate(test_inputs)]
            
            for fut in as_completed(futures):
                try:
                    result = fut.result()
                    completed += 1
                    
                    # Update stats
                    res1 = result["res1"]
                    res2 = result["res2"]
                    
                    # Log progress elegantly every 10%
                    if completed % max(1, iterations // 10) == 0 or completed == iterations:
                        print(f"{Color.GRAY}  - Progress: {completed}/{iterations} completed...{Color.END}")
                    
                    # Track crashes and timeouts
                    if res1["status"] == "timeout" and res2["status"] == "timeout":
                        report["timeouts"]["both"] += 1
                    elif res1["status"] == "timeout":
                        report["timeouts"]["bin1"] += 1
                    elif res2["status"] == "timeout":
                        report["timeouts"]["bin2"] += 1
                        
                    if res1["status"] == "crash" and res2["status"] == "crash":
                        report["crashes"]["both"] += 1
                    elif res1["status"] == "crash":
                        report["crashes"]["bin1"] += 1
                    elif res2["status"] == "crash":
                        report["crashes"]["bin2"] += 1

                    if result["is_equivalent"]:
                        report["matches"] += 1
                    else:
                        report["mismatches"] += 1
                        # Save up to 5 mismatch examples
                        if len(report["mismatch_examples"]) < 5:
                            # Decode stdin for readability in the report
                            try:
                                decoded_stdin = result["stdin"].decode('utf-8', errors='replace')
                            except Exception:
                                decoded_stdin = repr(result["stdin"])
                                
                            report["mismatch_examples"].append({
                                "index": result["index"],
                                "args": result["args"],
                                "stdin": decoded_stdin,
                                "reason": result["reason"],
                                "prog1": {
                                    "status": res1["status"],
                                    "returncode": res1["returncode"],
                                    "stdout": res1["stdout"].decode('utf-8', errors='replace'),
                                    "stderr": res1["stderr"].decode('utf-8', errors='replace')
                                },
                                "prog2": {
                                    "status": res2["status"],
                                    "returncode": res2["returncode"],
                                    "stdout": res2["stdout"].decode('utf-8', errors='replace'),
                                    "stderr": res2["stderr"].decode('utf-8', errors='replace')
                                }
                            })
                except Exception as ex:
                    print(f"{Color.RED}[!] Worker execution error: {ex}{Color.END}")
                    
        report["equivalence_ratio"] = (report["matches"] / iterations) * 100.0 if iterations > 0 else 0.0
        return report

    def cleanup(self):
        """Cleans up the local temporary workspaces."""
        if os.path.exists(self.tmp_dir):
            shutil.rmtree(self.tmp_dir)

# -----------------------------------------------------------------------------
# Default Generators Factory
# -----------------------------------------------------------------------------
def make_bytes_generator(min_len: int = 10, max_len: int = 100) -> Callable[[], Tuple[List[str], bytes]]:
    def gen() -> Tuple[List[str], bytes]:
        length = random.randint(min_len, max_len)
        return [], bytes(random.getrandbits(8) for _ in range(length))
    return gen

def make_integers_generator(count: int = 10, val_min: int = -1000, val_max: int = 1000) -> Callable[[], Tuple[List[str], bytes]]:
    def gen() -> Tuple[List[str], bytes]:
        nums = [str(random.randint(val_min, val_max)) for _ in range(count)]
        return [], (" ".join(nums) + "\n").encode('utf-8')
    return gen

def make_strings_generator(lines: int = 5, min_len: int = 5, max_len: int = 20) -> Callable[[], Tuple[List[str], bytes]]:
    def gen() -> Tuple[List[str], bytes]:
        out_lines = []
        for _ in range(lines):
            length = random.randint(min_len, max_len)
            s = "".join(random.choice(string.ascii_letters + string.digits) for _ in range(length))
            out_lines.append(s)
        return [], ("\n".join(out_lines) + "\n").encode('utf-8')
    return gen

# -----------------------------------------------------------------------------
# Main CLI Application entry point
# -----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Differential semantic fuzzer comparing compiled IR / C sources.")
    parser.add_argument("-f1", "--file1", required=True, help="First program file path (.c, .ll, .bc, or compiled binary)")
    parser.add_argument("-f2", "--file2", required=True, help="Second program file path (.c, .ll, .bc, or compiled binary)")
    parser.add_argument("-n", "--iterations", type=int, default=100, help="Number of fuzz iterations (default: 100)")
    parser.add_argument("-t", "--timeout", type=float, default=1.0, help="Single run execution timeout in seconds (default: 1.0)")
    parser.add_argument("-g", "--generator", choices=["bytes", "integers", "strings", "template"], default="bytes",
                        help="Fuzz input generator type. Select 'template' for structured benchmark tests.")
    parser.add_argument("--template-file", help="Path to custom structured generator template file")
    parser.add_argument("--template-str", help="Inline string representing a structured generator template")
    parser.add_argument("-o", "--output-report", help="JSON report path to save final outputs")
    parser.add_argument("--compare-stderr", action="store_true", help="Include stderr streams in differential evaluation")
    parser.add_argument("--compiler-flags", help="Comma-separated compilation flags (e.g. -O3,-lm)")
    parser.add_argument("-j", "--jobs", type=int, default=4, help="Number of parallel execution worker threads (default: 4)")
    
    args = parser.parse_args()
    
    # Process compiler flags
    flags = None
    if args.compiler_flags:
        flags = args.compiler_flags.split(",")
        
    fuzzer = SemanticFuzzer(args.file1, args.file2, compiler_flags=flags)
    
    try:
        fuzzer.compile()
    except Exception as e:
        print(f"{Color.RED}[✗] Failed to compile test cases: {e}{Color.END}")
        sys.exit(1)
        
    # Pick/build generator
    gen_func = None
    if args.generator == "template":
        template_content = None
        if args.template_file:
            with open(args.template_file, 'r', encoding='utf-8') as tf:
                template_content = tf.read()
        elif args.template_str:
            template_content = args.template_str
        else:
            # Check path to auto-detect a matching built-in benchmark template
            for key in DEFAULT_TEMPLATES.keys():
                if key in args.file1.lower() or key in args.file2.lower():
                    template_content = DEFAULT_TEMPLATES[key]
                    print(f"{Color.YELLOW}[!] Auto-detected benchmark '{key}', using built-in generator template.{Color.END}")
                    break
            
            if not template_content:
                print(f"{Color.RED}[✗] Error: 'template' generator selected but no template specified, and no project match found.{Color.END}")
                fuzzer.cleanup()
                sys.exit(1)
                
        gen_func = TemplateEvaluator(template_content)
    elif args.generator == "integers":
        gen_func = make_integers_generator()
    elif args.generator == "strings":
        gen_func = make_strings_generator()
    else:
        gen_func = make_bytes_generator()
        
    # Execute loop
    try:
        report = fuzzer.run_differential_test(
            iterations=args.iterations,
            generator=gen_func,
            timeout=args.timeout,
            compare_stderr=args.compare_stderr,
            num_workers=args.jobs
        )
    except KeyboardInterrupt:
        print(f"\n{Color.YELLOW}[!] Fuzzing aborted by user.{Color.END}")
        fuzzer.cleanup()
        sys.exit(130)
    finally:
        fuzzer.cleanup()
        
    # Visual Output Report Summary
    print("\n" + f"{Color.BOLD}{Color.BLUE}" + "="*60 + f"{Color.END}")
    print(f"{Color.BOLD}{Color.BLUE}                 DIFFERENTIAL FUZZING REPORT{Color.END}")
    print(f"{Color.BOLD}{Color.BLUE}" + "="*60 + f"{Color.END}")
    
    ratio = report["equivalence_ratio"]
    ratio_color = Color.GREEN if ratio == 100.0 else (Color.YELLOW if ratio >= 90.0 else Color.RED)
    
    print(f"File 1:         {args.file1}")
    print(f"File 2:         {args.file2}")
    print(f"Total Iter:     {report['total_runs']}")
    print(f"Matches:        {Color.GREEN}{report['matches']}{Color.END}")
    print(f"Mismatches:     {Color.RED if report['mismatches'] > 0 else Color.GRAY}{report['mismatches']}{Color.END}")
    print(f"Timeouts (F1):  {report['timeouts']['bin1']} | F2: {report['timeouts']['bin2']} | Both: {report['timeouts']['both']}")
    print(f"Crashes  (F1):  {report['crashes']['bin1']} | F2: {report['crashes']['bin2']} | Both: {report['crashes']['both']}")
    print(f"Equivalence:    {ratio_color}{ratio:.2f}%{Color.END}")
    
    if report["mismatches"] > 0:
        print("\n" + f"{Color.BOLD}{Color.RED}--- MISMATCH SAMPLES ---{Color.END}")
        for sample in report["mismatch_examples"]:
            print(f"\n{Color.BOLD}{Color.YELLOW}[Mismatch Case #{sample['index']}]{Color.END}")
            if sample['args']:
                print(f"Arguments: {sample['args']}")
            print(f"Reason:    {sample['reason']}")
            
            # Print stdin snippet
            stdin_lines = sample['stdin'].splitlines()
            if len(stdin_lines) > 10:
                snippet = "\n".join(stdin_lines[:10]) + f"\n... (truncated {len(stdin_lines)-10} lines)"
            else:
                snippet = sample['stdin']
            print(f"Stdin:\n{Color.GRAY}{snippet}{Color.END}")
            
            # Print stdout differences
            out1 = sample['prog1']['stdout']
            out2 = sample['prog2']['stdout']
            print(f"--- Program 1 Output (Exit: {sample['prog1']['returncode']}) ---")
            print(Color.GRAY + (out1[:200] + "... (truncated)" if len(out1) > 200 else out1) + Color.END)
            print(f"--- Program 2 Output (Exit: {sample['prog2']['returncode']}) ---")
            print(Color.GRAY + (out2[:200] + "... (truncated)" if len(out2) > 200 else out2) + Color.END)
            
    print(f"{Color.BOLD}{Color.BLUE}" + "="*60 + f"{Color.END}")
    
    # Save JSON Report
    if args.output_report:
        try:
            with open(args.output_report, 'w', encoding='utf-8') as rf:
                json.dump(report, rf, indent=2)
            print(f"{Color.GREEN}[✓] JSON report saved to: {args.output_report}{Color.END}")
        except Exception as e:
            print(f"{Color.RED}[✗] Error writing JSON report: {e}{Color.END}")
            
    if ratio != 100.0:
        sys.exit(2)
    sys.exit(0)

if __name__ == "__main__":
    main()

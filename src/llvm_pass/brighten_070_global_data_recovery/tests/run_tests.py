import os
import sys
import subprocess
import glob

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
PASS_DIR = os.path.dirname(TESTS_DIR)
BUILD_DIR = os.path.join(PASS_DIR, "build")
PLUGIN_PATH = os.path.join(BUILD_DIR, "BrightenGlobalDataRecoveryPass.so")

OPT_BIN = "opt-21"
FILECHECK_BIN = "FileCheck-21"

failed = 0
passed = 0

test_files = glob.glob(os.path.join(TESTS_DIR, "test_*.ll"))
test_files.sort()

for test_path in test_files:
    name = os.path.basename(test_path)
    print(f"Running test: {name} ...", end=" ")
    sys.stdout.flush()

    # Read the RUN lines from the test file
    run_lines = []
    with open(test_path, "r") as f:
        for line in f:
            if line.startswith("; RUN:"):
                run_lines.append(line[len("; RUN:"):].strip())

    if not run_lines:
        print("SKIP (No RUN lines found)")
        continue

    # Join lines and replace %builddir/ or %s or < %s
    full_cmd_str = " ".join(run_lines)
    full_cmd_str = full_cmd_str.replace("\\", " ")
    full_cmd_str = full_cmd_str.replace("%builddir", BUILD_DIR)
    full_cmd_str = full_cmd_str.replace("opt", OPT_BIN)
    full_cmd_str = full_cmd_str.replace("FileCheck", FILECHECK_BIN)
    
    # We will execute the command using a shell pipeline
    # To run it safely, we can replace %s with the actual test path
    # and < %s with < test_path
    full_cmd_str = full_cmd_str.replace("< %s", f"< {test_path}")
    full_cmd_str = full_cmd_str.replace("%s", test_path)

    try:
        proc = subprocess.run(full_cmd_str, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if proc.returncode == 0:
            print("PASS")
            passed += 1
        else:
            print("FAIL")
            print("Command:", full_cmd_str)
            print("Stdout:", proc.stdout.decode())
            print("Stderr:", proc.stderr.decode())
            failed += 1
    except Exception as e:
        print(f"FAIL (Exception: {e})")
        failed += 1

print(f"\nTest Summary: {passed} passed, {failed} failed")
if failed > 0:
    sys.exit(1)
else:
    sys.exit(0)

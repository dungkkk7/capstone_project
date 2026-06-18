#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import argparse
import subprocess
import shutil
import time

# --- ĐƯỜNG DẪN TƯƠNG ĐỐI CHUẨN XÁC TỪ SCRIPT ĐẾN THƯ MỤC 'dependency' ---
# File script nằm tại: src/binary_lifting/lifting.py
# Thư mục chứa các công cụ nằm tại: dependency/
# Do đó cần đi lên 2 cấp (../..) từ thư mục chứa script để truy cập vào 'dependency'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MCSEMA_BIN = os.path.join(SCRIPT_DIR, "../../dependency/mcsema/mcsema/bin")
MCSEMA_LIB = os.path.join(SCRIPT_DIR, "../../dependency/mcsema/mcsema/lib")
REMILL_BIN = os.path.join(SCRIPT_DIR, "../../dependency/mcsema/remill/bin")
MCSEMA_DISASS = os.path.join(MCSEMA_BIN, "mcsema-disass")
MCSEMA_LIFT = os.path.join(MCSEMA_BIN, "mcsema-lift-10.0")


class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'

def setup_python_path():
    """
    Cấu hình PYTHONPATH để Python nhận diện các gói thư viện (.egg) đi kèm của McSema
    nằm trong thư mục dependency/mcsema/mcsema/lib/python3/site-packages.
    """
    site_packages_dir = os.path.join(MCSEMA_LIB, "python3", "site-packages")
    if os.path.exists(site_packages_dir):
        python_paths = [os.path.abspath(site_packages_dir)]
        # Quét và thêm tất cả các file/thư mục .egg vào PYTHONPATH
        for item in os.listdir(site_packages_dir):
            if item.endswith(".egg"):
                python_paths.append(os.path.abspath(os.path.join(site_packages_dir, item)))
        
        # Nối các đường dẫn này vào đầu biến môi trường PYTHONPATH hiện tại
        existing_pythonpath = os.environ.get("PYTHONPATH", "")
        new_pythonpath = os.pathsep.join(python_paths)
        if existing_pythonpath:
            os.environ["PYTHONPATH"] = f"{new_pythonpath}{os.pathsep}{existing_pythonpath}"
        else:
            os.environ["PYTHONPATH"] = new_pythonpath
        # Chỉ in log cấu hình này ở màu xám mờ để đỡ rối mắt
        print(f"{Color.GRAY}[*] Đã cấu hình PYTHONPATH cho các thư viện đi kèm của McSema.{Color.END}")
    else:
        print(f"{Color.YELLOW}[!] Cảnh báo: Không tìm thấy thư mục site-packages tại '{site_packages_dir}'{Color.END}")

def run_command(cmd, step_name):
    """ Hàm thực thi lệnh hệ thống và stream log thời gian thực """
    print(f"{Color.BLUE}{Color.BOLD}    → Bắt đầu: {step_name}...{Color.END}")
    print(f"{Color.GRAY}      Lệnh: {' '.join(cmd)}{Color.END}")
    
    start_time = time.time()
    try:
        # Merge stdout and stderr to display all outputs in real time
        process = subprocess.Popen(
            cmd,
            env=os.environ,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        
        # Read the output stream in real-time
        for line in process.stdout:
            stripped = line.strip()
            if stripped:
                elapsed = int(time.time() - start_time)
                # Print each log line in muted gray prefixed with running elapsed time
                print(f"{Color.GRAY}      [{elapsed}s] {stripped}{Color.END}")
                
        process.wait()
        elapsed_total = int(time.time() - start_time)
        
        if process.returncode == 0:
            print(f"{Color.GREEN}      [✓] Hoàn thành: {step_name} (Tổng thời gian: {elapsed_total}s){Color.END}")
            return True
        else:
            print(f"{Color.RED}      [✗] Thất bại tại: {step_name} (Mã lỗi: {process.returncode}, Tổng thời gian: {elapsed_total}s){Color.END}")
            return False
    except Exception as e:
        print(f"{Color.RED}      [✗] Lỗi thực thi hệ thống: {e}{Color.END}")
        return False

def lift_binary(binary_path, disassembler="/opt/ida-pro-9.3/idat", ghidra=None, output=None, arch="amd64", os_name="linux", entrypoint="main"):
    # Kiểm tra file binary đầu vào
    if not os.path.exists(binary_path):
        print(f"{Color.RED}[✗] Lỗi: Không tìm thấy file binary tại '{binary_path}'{Color.END}")
        return False

    # Thiết lập PYTHONPATH cho các dependency thư viện của McSema (.egg)
    setup_python_path()

    # Thêm Remill vào PATH để mcsema-lift có thể tìm thấy remill-lift tại runtime
    if os.path.exists(REMILL_BIN):
        os.environ["PATH"] = f"{os.path.abspath(REMILL_BIN)}{os.pathsep}{os.environ.get('PATH', '')}"
    else:
        print(f"{Color.YELLOW}[!] Cảnh báo: Không tìm thấy thư mục Remill tại '{REMILL_BIN}'{Color.END}")

    # Xác định disassembler thực tế sử dụng
    disass_bin = disassembler
    if ghidra:
        print(f"{Color.YELLOW}[!] Cảnh báo: Phiên bản McSema hiện tại được cài đặt không hỗ trợ Ghidra (chỉ hỗ trợ IDA Pro).{Color.END}")
        print(f"{Color.YELLOW}    Script sẽ tự động chuyển sang sử dụng IDA Pro làm disassembler backend.{Color.END}")
        if "ida" not in ghidra.lower():
            disass_bin = "/opt/ida-pro-9.3/idat"
        else:
            disass_bin = ghidra

    # Xác định đường dẫn đầu ra trong thư mục 'result/'
    if output:
        output_bc = output
        output_dir = os.path.dirname(os.path.abspath(output_bc))
        base_name = os.path.splitext(os.path.basename(output_bc))[0]
        os.makedirs(output_dir, exist_ok=True)
        cfg_file = os.path.join(output_dir, f"{base_name}.cfg")
        log_file = os.path.join(output_dir, f"{base_name}_disass.log")
    else:
        binary_abs = os.path.abspath(binary_path)
        project_root = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
        result_root = os.path.join(project_root, "result")
        
        # Tìm đường dẫn tương đối của binary đối với thư mục data/obfuscated/ hoặc thư mục dự án
        data_obfuscated_root = os.path.join(project_root, "data/obfuscated")
        data_clean_root = os.path.join(project_root, "data/clean_src")
        
        rel_path = None
        if binary_abs.startswith(data_obfuscated_root):
            rel_path = os.path.relpath(binary_abs, data_obfuscated_root)
        elif binary_abs.startswith(data_clean_root):
            rel_path = os.path.relpath(binary_abs, data_clean_root)
        elif binary_abs.startswith(project_root):
            rel_path = os.path.relpath(binary_abs, project_root)
            
        if rel_path:
            rel_dir = os.path.dirname(rel_path)
            base_name = os.path.splitext(os.path.basename(binary_path))[0]
            output_dir = os.path.join(result_root, rel_dir)
        else:
            base_name = os.path.splitext(os.path.basename(binary_path))[0]
            output_dir = result_root
            
        os.makedirs(output_dir, exist_ok=True)
        output_bc = os.path.join(output_dir, f"{base_name}.bc")
        cfg_file = os.path.join(output_dir, f"{base_name}.cfg")
        log_file = os.path.join(output_dir, f"{base_name}_disass.log")

    print(f"{Color.BLUE}{Color.BOLD}" + "=" * 60 + f"{Color.END}")
    print(f"{Color.BLUE}[*] Đang xử lý: {binary_path}{Color.END}")
    print(f"{Color.BLUE}[*] Disassembler thực tế sử dụng: {disass_bin}{Color.END}")
    print(f"{Color.BLUE}[*] Thư mục đầu ra kết quả: {output_dir}{Color.END}")
    print(f"{Color.BLUE}{Color.BOLD}" + "=" * 60 + f"{Color.END}")

    # --- BƯỚC 1: DISASSEMBLY (Phân tích sinh file .cfg) ---
    disass_cmd = [
        sys.executable,
        MCSEMA_DISASS,
        "--disassembler", disass_bin,
        "--binary", binary_path,
        "--output", cfg_file,
        "--log_file", log_file,
        "--arch", arch,
        "--os", os_name,
        "--entrypoint", entrypoint
    ]

    if not run_command(disass_cmd, "Bước 1: Phân rã sinh cấu trúc CFG"):
        return False

    # --- BƯỚC 2: LIFTING (Chuyển CFG lên LLVM Bitcode .bc) ---
    lift_cmd = [
        MCSEMA_LIFT,
        "--os", os_name,
        "--arch", arch,
        "--cfg", cfg_file,
        "--output", output_bc
    ]

    # Tự động định vị thư mục semantics của Remill
    remill_share_dir = os.path.join(SCRIPT_DIR, "../../dependency/mcsema/remill/share/remill")
    semantics_path = None
    if os.path.exists(remill_share_dir):
        for version in os.listdir(remill_share_dir):
            candidate = os.path.join(remill_share_dir, version, "semantics")
            if os.path.exists(candidate):
                semantics_path = os.path.abspath(candidate)
                break

    if semantics_path:
        lift_cmd.extend(["--semantics_search_paths", semantics_path])
    else:
        print(f"{Color.YELLOW}[!] Cảnh báo: Không tự động tìm thấy thư mục chứa semantics của Remill.{Color.END}")

    if not run_command(lift_cmd, "Bước 2: Nâng mã (Lift) lên LLVM Bitcode"):
        return False

    # --- BƯỚC 3: DỊCH SANG ĐỊNH DẠNG ĐỌC ĐƯỢC .ll (Tùy chọn) ---
    output_ll = f"{os.path.splitext(output_bc)[0]}.ll"
    llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
    
    if llvm_dis:
        if run_command([llvm_dis, output_bc, "-o", output_ll], "Bước 3: Chuyển đổi sang LLVM IR (.ll)"):
            print(f"{Color.GREEN}[✓] Hoàn tất bước nâng mã thô (Raw Lift)! Tệp LLVM IR thô (chưa làm sạch) nằm tại: {output_ll}{Color.END}")
            return True
    else:
        print(f"{Color.YELLOW}[!] Gợi ý: Hãy chạy lệnh 'llvm-dis {output_bc}' (hoặc llvm-dis-21) để sinh mã IR dạng văn bản.{Color.END}")
        return True
    return False

def main():
    parser = argparse.ArgumentParser(description="McSema Lifter with Clean Relative Paths")
    
    # Các tham số cấu hình
    parser.add_argument("-b", "--binary", required=True, help="Đường dẫn tới file binary cần lift")
    parser.add_argument("-d", "--disassembler", default="/opt/ida-pro-9.3/idat", help="Đường dẫn tới disassembler (mặc định: IDA Pro tại /opt/ida-pro-9.3/idat)")
    parser.add_argument("-g", "--ghidra", help="Đường dẫn Ghidra (nếu truyền vào thì script sẽ cảnh báo và tự động chuyển sang sử dụng IDA Pro)")
    parser.add_argument("-o", "--output", help="File .bc đầu ra (mặc định: [binary].bc)")
    parser.add_argument("-a", "--arch", default="amd64", choices=["x86", "amd64", "aarch64"], help="Kiến trúc CPU")
    parser.add_argument("-s", "--os", default="linux", choices=["linux", "windows", "macos"], help="Hệ điều hành đích")
    parser.add_argument("-e", "--entrypoint", default="main", help="Hàm bắt đầu phân tích")
    
    args = parser.parse_args()

    success = lift_binary(
        binary_path=args.binary,
        disassembler=args.disassembler,
        ghidra=args.ghidra,
        output=args.output,
        arch=args.arch,
        os_name=args.os,
        entrypoint=args.entrypoint
    )
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import argparse
import subprocess
import shutil
import time
import hashlib
import json

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

# --- THƯ MỤC CACHE LIFTING ---
# Cache nằm tại: result/.lifting_cache/
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))
LIFTING_CACHE_DIR = os.path.join(PROJECT_ROOT, "result", ".lifting_cache")
LIFTING_CACHE_INDEX = os.path.join(LIFTING_CACHE_DIR, "cache_index.json")


class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'

# =============================================================================
# LIFTING CACHE MECHANISM
# =============================================================================

def compute_binary_hash(binary_path: str) -> str:
    """
    Tính MD5 hash của file binary để làm khóa cache.
    Hash được tính từ nội dung file, không phải tên file.
    """
    md5 = hashlib.md5()
    with open(binary_path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            md5.update(chunk)
    return md5.hexdigest()

def load_cache_index() -> dict:
    """Tải cache index từ file JSON. Trả về dict rỗng nếu chưa có."""
    if not os.path.exists(LIFTING_CACHE_INDEX):
        return {}
    try:
        with open(LIFTING_CACHE_INDEX, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {}

def save_cache_index(index: dict):
    """Lưu cache index vào file JSON."""
    os.makedirs(LIFTING_CACHE_DIR, exist_ok=True)
    try:
        with open(LIFTING_CACHE_INDEX, 'w', encoding='utf-8') as f:
            json.dump(index, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"{Color.YELLOW}[!] Cảnh báo: Không thể lưu cache index: {e}{Color.END}")

def make_cache_key(binary_hash: str, arch: str, os_name: str, entrypoint: str) -> str:
    """Tạo cache key duy nhất từ hash binary + tham số lifting."""
    return f"{binary_hash}_{arch}_{os_name}_{entrypoint}"

def get_cached_lifting(binary_path: str, arch: str, os_name: str, entrypoint: str):
    """
    Kiểm tra và trả về kết quả lifting đã cache nếu tồn tại.
    
    Returns:
        Tuple (cached_bc_path, cached_ll_path) nếu cache hit.
        None nếu cache miss.
    """
    try:
        binary_hash = compute_binary_hash(binary_path)
        cache_key = make_cache_key(binary_hash, arch, os_name, entrypoint)
        index = load_cache_index()
        
        if cache_key not in index:
            return None
        
        entry = index[cache_key]
        cached_bc = entry.get("bc_path")
        cached_ll = entry.get("ll_path")
        cached_cfg = entry.get("cfg_path")
        
        # Kiểm tra các file cache còn tồn tại không
        if cached_bc and os.path.exists(cached_bc):
            print(f"{Color.GREEN}[✓] Cache HIT: Đã tìm thấy kết quả lifting được cache cho binary này.{Color.END}")
            print(f"{Color.GRAY}      Hash: {binary_hash}{Color.END}")
            print(f"{Color.GRAY}      Cached .bc: {cached_bc}{Color.END}")
            if cached_ll and os.path.exists(cached_ll):
                print(f"{Color.GRAY}      Cached .ll: {cached_ll}{Color.END}")
            print(f"{Color.GRAY}      Cached lúc: {entry.get('timestamp', 'N/A')}{Color.END}")
            return cached_bc, cached_ll, cached_cfg
        else:
            # File cache bị xóa ngoài, xóa entry cũ
            print(f"{Color.YELLOW}[!] Cache entry tồn tại nhưng file đã bị xóa, sẽ lift lại.{Color.END}")
            del index[cache_key]
            save_cache_index(index)
            return None
    except Exception as e:
        print(f"{Color.YELLOW}[!] Lỗi khi kiểm tra cache: {e}. Bỏ qua cache.{Color.END}")
        return None

def save_to_cache(binary_path: str, arch: str, os_name: str, entrypoint: str,
                  bc_path: str, ll_path: str, cfg_path: str):
    """
    Lưu đường dẫn kết quả lifting vào cache index.
    Cache không sao chép file, chỉ lưu đường dẫn tuyệt đối đến file đã sinh ra.
    """
    try:
        binary_hash = compute_binary_hash(binary_path)
        cache_key = make_cache_key(binary_hash, arch, os_name, entrypoint)
        index = load_cache_index()
        
        index[cache_key] = {
            "binary_path": os.path.abspath(binary_path),
            "binary_hash": binary_hash,
            "arch": arch,
            "os_name": os_name,
            "entrypoint": entrypoint,
            "bc_path": os.path.abspath(bc_path) if bc_path and os.path.exists(bc_path) else None,
            "ll_path": os.path.abspath(ll_path) if ll_path and os.path.exists(ll_path) else None,
            "cfg_path": os.path.abspath(cfg_path) if cfg_path and os.path.exists(cfg_path) else None,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        }
        
        save_cache_index(index)
        print(f"{Color.GREEN}[✓] Đã lưu kết quả lifting vào cache (key: {cache_key[:16]}...).{Color.END}")
    except Exception as e:
        print(f"{Color.YELLOW}[!] Cảnh báo: Không thể lưu vào cache: {e}{Color.END}")

def copy_cached_to_output(cached_bc: str, cached_ll: str, cached_cfg: str,
                          output_bc: str, output_dir: str, base_name: str) -> bool:
    """
    Sao chép file từ cache đến thư mục output mới của lần chạy này.
    Trả về True nếu thành công.
    """
    try:
        os.makedirs(output_dir, exist_ok=True)
        
        # Copy .bc
        if cached_bc and os.path.exists(cached_bc):
            shutil.copy2(cached_bc, output_bc)
            print(f"{Color.GREEN}      [✓] Đã sao chép .bc từ cache: {output_bc}{Color.END}")
        
        # Copy .ll
        output_ll = os.path.join(output_dir, f"{base_name}.ll")
        if cached_ll and os.path.exists(cached_ll):
            shutil.copy2(cached_ll, output_ll)
            print(f"{Color.GREEN}      [✓] Đã sao chép .ll từ cache: {output_ll}{Color.END}")
        
        # Copy .cfg
        output_cfg = os.path.join(output_dir, f"{base_name}.cfg")
        if cached_cfg and os.path.exists(cached_cfg):
            shutil.copy2(cached_cfg, output_cfg)
            print(f"{Color.GREEN}      [✓] Đã sao chép .cfg từ cache: {output_cfg}{Color.END}")
        
        return True
    except Exception as e:
        print(f"{Color.RED}[✗] Lỗi khi sao chép từ cache: {e}{Color.END}")
        return False

def list_cache_entries():
    """In danh sách tất cả các entry trong cache."""
    index = load_cache_index()
    if not index:
        print(f"{Color.YELLOW}[!] Cache rỗng. Chưa có kết quả lifting nào được cache.{Color.END}")
        return
    
    print(f"{Color.BLUE}{Color.BOLD}=== Lifting Cache Index ({len(index)} entries) ==={Color.END}")
    for key, entry in index.items():
        print(f"{Color.GRAY}  Key: {key[:20]}...{Color.END}")
        print(f"{Color.GRAY}    Binary: {entry.get('binary_path', 'N/A')}{Color.END}")
        print(f"{Color.GRAY}    Hash:   {entry.get('binary_hash', 'N/A')}{Color.END}")
        print(f"{Color.GRAY}    Cached: {entry.get('timestamp', 'N/A')}{Color.END}")
        print()

def clear_cache():
    """Xóa toàn bộ lifting cache."""
    if os.path.exists(LIFTING_CACHE_DIR):
        shutil.rmtree(LIFTING_CACHE_DIR)
        print(f"{Color.GREEN}[✓] Đã xóa toàn bộ lifting cache tại: {LIFTING_CACHE_DIR}{Color.END}")
    else:
        print(f"{Color.YELLOW}[!] Cache directory không tồn tại: {LIFTING_CACHE_DIR}{Color.END}")

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

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

# =============================================================================
# MAIN LIFT BINARY FUNCTION (WITH CACHE)
# =============================================================================

def lift_binary(binary_path, disassembler="/opt/ida-pro-9.3/idat", ghidra=None, output=None,
                arch="amd64", os_name="linux", entrypoint="main",
                use_cache: bool = True, force_relift: bool = False):
    """
    Nâng mã binary lên LLVM IR (.bc/.ll) sử dụng McSema.
    
    Cơ chế cache (Phase 1 - Lifting Cache):
    - Tính MD5 hash của file binary đầu vào.
    - Nếu đã có kết quả lifting trong cache (và không bị force_relift), sao chép từ cache.
    - Sau khi lift thành công, lưu đường dẫn kết quả vào cache index.
    
    Args:
        binary_path:   Đường dẫn file binary cần lift.
        disassembler:  Đường dẫn tới IDA Pro.
        ghidra:        Đường dẫn Ghidra (sẽ bị ignore, chuyển sang IDA).
        output:        File .bc đầu ra (nếu None thì tự sinh trong result/).
        arch:          Kiến trúc CPU (amd64, x86, aarch64).
        os_name:       Hệ điều hành (linux, windows, macos).
        entrypoint:    Hàm bắt đầu phân tích.
        use_cache:     Bật/tắt cơ chế cache lifting (mặc định: True).
        force_relift:  Bắt buộc lift lại dù có cache (mặc định: False).
    """
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
        result_root = os.path.join(PROJECT_ROOT, "result")
        
        # Tìm đường dẫn tương đối của binary đối với thư mục data/obfuscated/ hoặc thư mục dự án
        data_obfuscated_root = os.path.join(PROJECT_ROOT, "data/obfuscated")
        data_clean_root = os.path.join(PROJECT_ROOT, "data/clean_src")
        
        rel_path = None
        if binary_abs.startswith(data_obfuscated_root):
            rel_path = os.path.relpath(binary_abs, data_obfuscated_root)
        elif binary_abs.startswith(data_clean_root):
            rel_path = os.path.relpath(binary_abs, data_clean_root)
        elif binary_abs.startswith(PROJECT_ROOT):
            rel_path = os.path.relpath(binary_abs, PROJECT_ROOT)
            
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

    output_ll = f"{os.path.splitext(output_bc)[0]}.ll"

    print(f"{Color.BLUE}{Color.BOLD}" + "=" * 60 + f"{Color.END}")
    print(f"{Color.BLUE}[*] Đang xử lý: {binary_path}{Color.END}")
    print(f"{Color.BLUE}[*] Disassembler thực tế sử dụng: {disass_bin}{Color.END}")
    print(f"{Color.BLUE}[*] Thư mục đầu ra kết quả: {output_dir}{Color.END}")
    print(f"{Color.BLUE}{Color.BOLD}" + "=" * 60 + f"{Color.END}")

    # -------------------------------------------------------------------------
    # KIỂM TRA CACHE (Phase 1 - Lifting Cache)
    # -------------------------------------------------------------------------
    if use_cache and not force_relift:
        print(f"{Color.BLUE}[*] Đang kiểm tra lifting cache (P1)...{Color.END}")
        cache_result = get_cached_lifting(binary_path, arch, os_name, entrypoint)
        
        if cache_result is not None:
            cached_bc, cached_ll, cached_cfg = cache_result
            print(f"{Color.GREEN}{Color.BOLD}[✓] SỬ DỤNG KẾT QUẢ TỪ CACHE — Bỏ qua bước Disassembly + Lifting.{Color.END}")
            
            # Sao chép file từ cache đến output dir hiện tại
            if copy_cached_to_output(cached_bc, cached_ll, cached_cfg, output_bc, output_dir, base_name):
                print(f"{Color.GREEN}[✓] Hoàn tất (từ cache)! Tệp LLVM IR thô: {output_ll}{Color.END}")
                return True
            else:
                print(f"{Color.YELLOW}[!] Không thể dùng cache, tiếp tục lift lại...{Color.END}")
    elif force_relift:
        print(f"{Color.YELLOW}[!] force_relift=True: Bỏ qua cache, thực hiện lifting lại từ đầu.{Color.END}")
    else:
        print(f"{Color.YELLOW}[!] use_cache=False: Cache bị tắt, thực hiện lifting trực tiếp.{Color.END}")

    # -------------------------------------------------------------------------
    # BƯỚC 1: DISASSEMBLY (Phân tích sinh file .cfg)
    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # BƯỚC 2: LIFTING (Chuyển CFG lên LLVM Bitcode .bc)
    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # BƯỚC 3: DỊCH SANG ĐỊNH DẠNG ĐỌC ĐƯỢC .ll (Tùy chọn)
    # -------------------------------------------------------------------------
    llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
    ll_success = False
    
    if llvm_dis:
        if run_command([llvm_dis, output_bc, "-o", output_ll], "Bước 3: Chuyển đổi sang LLVM IR (.ll)"):
            print(f"{Color.GREEN}[✓] Hoàn tất bước nâng mã thô (Raw Lift)! Tệp LLVM IR thô (chưa làm sạch) nằm tại: {output_ll}{Color.END}")
            ll_success = True
    else:
        print(f"{Color.YELLOW}[!] Gợi ý: Hãy chạy lệnh 'llvm-dis {output_bc}' (hoặc llvm-dis-21) để sinh mã IR dạng văn bản.{Color.END}")

    # -------------------------------------------------------------------------
    # LƯU VÀO CACHE SAU KHI LIFT THÀNH CÔNG
    # -------------------------------------------------------------------------
    if use_cache:
        save_to_cache(
            binary_path=binary_path,
            arch=arch,
            os_name=os_name,
            entrypoint=entrypoint,
            bc_path=output_bc,
            ll_path=output_ll if ll_success else None,
            cfg_path=cfg_file,
        )

    return True


def main():
    parser = argparse.ArgumentParser(description="McSema Lifter with Clean Relative Paths + Lifting Cache")
    
    # Các tham số cấu hình
    parser.add_argument("-b", "--binary", required=True, help="Đường dẫn tới file binary cần lift")
    parser.add_argument("-d", "--disassembler", default="/opt/ida-pro-9.3/idat", help="Đường dẫn tới disassembler (mặc định: IDA Pro tại /opt/ida-pro-9.3/idat)")
    parser.add_argument("-g", "--ghidra", help="Đường dẫn Ghidra (nếu truyền vào thì script sẽ cảnh báo và tự động chuyển sang sử dụng IDA Pro)")
    parser.add_argument("-o", "--output", help="File .bc đầu ra (mặc định: [binary].bc)")
    parser.add_argument("-a", "--arch", default="amd64", choices=["x86", "amd64", "aarch64"], help="Kiến trúc CPU")
    parser.add_argument("-s", "--os", default="linux", choices=["linux", "windows", "macos"], help="Hệ điều hành đích")
    parser.add_argument("-e", "--entrypoint", default="main", help="Hàm bắt đầu phân tích")
    
    # Cache options
    parser.add_argument("--no-cache", action="store_true", help="Tắt cơ chế lifting cache")
    parser.add_argument("--force-relift", action="store_true", help="Bắt buộc lift lại dù đã có cache")
    parser.add_argument("--list-cache", action="store_true", help="Hiển thị danh sách cache entries và thoát")
    parser.add_argument("--clear-cache", action="store_true", help="Xóa toàn bộ lifting cache và thoát")
    
    args = parser.parse_args()

    # Xử lý các lệnh cache đặc biệt
    if args.list_cache:
        list_cache_entries()
        sys.exit(0)
    
    if args.clear_cache:
        clear_cache()
        sys.exit(0)

    success = lift_binary(
        binary_path=args.binary,
        disassembler=args.disassembler,
        ghidra=args.ghidra,
        output=args.output,
        arch=args.arch,
        os_name=args.os,
        entrypoint=args.entrypoint,
        use_cache=not args.no_cache,
        force_relift=args.force_relift,
    )
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
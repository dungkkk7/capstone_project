import sys
import os
import csv
import datetime

# Thêm thư mục hiện tại (src) vào sys.path để nhận diện package binary_lifting
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from binary_lifting.lifting import lift_binary

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'

def main(argv=None):
    print(f"{Color.BLUE}{Color.BOLD}==== Binary Deobfuscation based on LLVM and LLMs ===={Color.END}")

    # Nếu không truyền argv thì lấy từ command line
    if argv is None:
        argv = sys.argv[1:]

    # Kiểm tra tham số
    if len(argv) < 1:
        print(f"{Color.YELLOW}Usage: python main.py <obfuscated_bin_list.csv>{Color.END}")
        return 1

    # CSV chứa danh sách binary bị obfuscate
    list_obfuscated_bin = argv[0]
    print(f"{Color.BLUE}[*] Danh sách tệp binary cần lift: {list_obfuscated_bin}{Color.END}")

    # Đọc danh sách các tệp binary từ tệp CSV
    if not os.path.exists(list_obfuscated_bin):
        print(f"{Color.RED}[✗] Lỗi: Không tìm thấy tệp CSV tại '{list_obfuscated_bin}'{Color.END}")
        return 1

    binary_paths = []
    try:
        with open(list_obfuscated_bin, mode='r', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)
            
            if not rows:
                print(f"{Color.YELLOW}[!] Cảnh báo: Tệp CSV '{list_obfuscated_bin}' rỗng.{Color.END}")
                return 0

            # Xác định header nếu có
            header = [cell.strip().lower() for cell in rows[0]]
            path_col_index = -1
            for name in ["binary_path", "binary", "path", "file", "filepath"]:
                if name in header:
                    path_col_index = header.index(name)
                    break
            
            start_row = 1 if path_col_index != -1 else 0
            if path_col_index == -1:
                # Nếu không tìm thấy header, mặc định lấy cột đầu tiên (index 0)
                path_col_index = 0

            for row in rows[start_row:]:
                if not row or len(row) <= path_col_index:
                    continue
                path = row[path_col_index].strip()
                if path:
                    binary_paths.append(path)
    except Exception as e:
        print(f"{Color.RED}[✗] Lỗi khi đọc tệp CSV: {e}{Color.END}")
        return 1

    print(f"{Color.BLUE}[*] Tìm thấy {len(binary_paths)} tệp binary cần xử lý:{Color.END}")
    for path in binary_paths:
        print(f"{Color.GRAY}  - {path}{Color.END}")

    # Tạo thư mục con trong result kiểu pipeline_<timestamp> để chứa kết quả của lần chạy này
    pipeline_time = datetime.datetime.now().strftime("pipeline_%Y%m%d_%H%M%S")
    project_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    result_pipeline_root = os.path.join(project_root, "result", pipeline_time)
    print(f"{Color.BLUE}[*] Thư mục pipeline kết quả lần chạy này: {result_pipeline_root}{Color.END}")

    # Chạy lifting lần lượt cho từng tệp
    success_count = 0
    for path in binary_paths:
        print("\n" + f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")
        print(f"{Color.BLUE}{Color.BOLD}[*] Đang thực hiện lifting cho: {path}{Color.END}")
        print(f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")
        
        # Xác định đường dẫn con cho case (ví dụ: hash, keybox,...)
        binary_abs = os.path.abspath(path)
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
            base_name = os.path.splitext(os.path.basename(path))[0]
            case_output_dir = os.path.join(result_pipeline_root, rel_dir)
        else:
            base_name = os.path.splitext(os.path.basename(path))[0]
            case_output_dir = result_pipeline_root
            
        os.makedirs(case_output_dir, exist_ok=True)
        output_bc = os.path.join(case_output_dir, f"{base_name}.bc")

        # Gọi hàm lift_binary từ module binary_lifting.lifting, truyền output_bc chỉ định thư mục pipeline con
        success = lift_binary(binary_path=path, output=output_bc)
        if success:
            print(f"{Color.GREEN}[✓] Nâng mã (Lift) thành công cho: {path}{Color.END}")
            success_count += 1
        else:
            print(f"{Color.RED}[✗] Nâng mã (Lift) THẤT BẠI cho: {path}{Color.END}")

    print("\n" + f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")
    print(f"{Color.GREEN}{Color.BOLD}[✓] Đã hoàn thành xử lý. Thành công: {success_count}/{len(binary_paths)}{Color.END}")
    print(f"{Color.BLUE}[*] Tất cả kết quả được lưu tại: {result_pipeline_root}{Color.END}")
    print(f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
import sys
import os
import csv
import datetime

# Thêm thư mục hiện tại (src) vào sys.path để nhận diện package binary_lifting
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from binary_lifting.lifting import lift_binary
from llvm_pass.britening_ir import brighten_ir
from fuzzing_equi_check.fuzzing import (
    SemanticFuzzer,
    TemplateEvaluator,
    make_bytes_generator,
    make_integers_generator,
    DEFAULT_TEMPLATES,
)

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'


def _resolve_seed_paths(project_root, binary_path):
    """Resolve seed sources for one binary from `data/seeds/<case>/`.

    Returns:
        (seed_paths, seed_dir)
        - seed_paths: list of exact per-binary seed files if available.
        - seed_dir: directory containing .seed files to use as AFL corpus.
    """
    binary_abs = os.path.abspath(binary_path)
    seed_root = os.path.join(project_root, "data", "seeds")
    candidate_case = None

    data_obfuscated_root = os.path.join(project_root, "data", "obfuscated")
    data_clean_root = os.path.join(project_root, "data", "clean_src")

    if binary_abs.startswith(data_obfuscated_root + os.sep):
        rel_path = os.path.relpath(binary_abs, data_obfuscated_root)
        candidate_case = rel_path.split(os.sep)[0]
    elif binary_abs.startswith(data_clean_root + os.sep):
        rel_path = os.path.relpath(binary_abs, data_clean_root)
        candidate_case = rel_path.split(os.sep)[0]
    else:
        for part in reversed(binary_abs.split(os.sep)):
            if part.startswith("p000"):
                candidate_case = part
                break

    if not candidate_case:
        return ([], None)

    seed_dir = os.path.join(seed_root, candidate_case)
    if not os.path.isdir(seed_dir):
        return ([], None)

    exact_seed_file = os.path.join(seed_dir, f"{os.path.basename(binary_abs)}.seed")
    seed_paths = [exact_seed_file] if os.path.isfile(exact_seed_file) else []
    if not seed_paths:
        # Some dataset cases provide one canonical seed as <case>_seed.txt
        # rather than a per-binary .seed file.  It is still valid for all
        # obfuscation variants of that case.
        case_seed = os.path.join(seed_dir, f"{candidate_case}_seed.txt")
        if os.path.isfile(case_seed):
            seed_paths.append(case_seed)
    return (seed_paths, seed_dir)


def _find_reference_source(project_root, binary_path):
    """Find the clean C source belonging to a dataset binary, if present."""
    binary_abs = os.path.abspath(binary_path)
    obfuscated_root = os.path.join(project_root, "data", "obfuscated")
    if not binary_abs.startswith(obfuscated_root + os.sep):
        return None
    rel_path = os.path.relpath(binary_abs, obfuscated_root)
    case = rel_path.split(os.sep)[0]
    stem = os.path.splitext(os.path.basename(binary_abs))[0]
    source_stem = stem.split("_", 1)[0]
    candidate = os.path.join(project_root, "data", "clean_src", case, source_stem + ".c")
    if os.path.isfile(candidate):
        return candidate
    return None


def _select_generator(project_root, binary_path, template_content):
    """Select a valid input domain for the benchmark instead of raw bytes."""
    if template_content:
        return TemplateEvaluator(template_content), "template"

    source = _find_reference_source(project_root, binary_path)
    if source:
        try:
            with open(source, "r", encoding="utf-8", errors="ignore") as f:
                source_text = f.read()
            if "%d" in source_text or "%i" in source_text:
                return make_integers_generator(), "integer stdin inferred from clean source"
        except OSError:
            pass
    return make_bytes_generator(), "raw byte fallback"

def main(argv=None):
    print(f"{Color.BLUE}{Color.BOLD}==== Binary Deobfuscation based on LLVM and LLMs ===={Color.END}")

    # Nếu không truyền argv thì lấy từ command line
    if argv is None:
        argv = sys.argv[1:]

    # Kiểm tra tham số
    if len(argv) < 1:
        print(f"{Color.YELLOW}Usage: python main.py <obfuscated_bin_list.csv> [--no-cache] [--force-relift]{Color.END}")
        return 1

    # Phân tích tham số cache từ command line
    use_cache = "--no-cache" not in argv
    force_relift = "--force-relift" in argv
    # Lọc ra các flag để lấy đường dẫn CSV
    positional_args = [a for a in argv if not a.startswith("--")]
    if not positional_args:
        print(f"{Color.YELLOW}Usage: python main.py <obfuscated_bin_list.csv> [--no-cache] [--force-relift]{Color.END}")
        return 1

    # CSV chứa danh sách binary bị obfuscate
    list_obfuscated_bin = positional_args[0]
    print(f"{Color.BLUE}[*] Danh sách tệp binary cần lift: {list_obfuscated_bin}{Color.END}")
    if not use_cache:
        print(f"{Color.YELLOW}[!] Lifting cache: TẮT (--no-cache){Color.END}")
    elif force_relift:
        print(f"{Color.YELLOW}[!] Lifting cache: BẮT BUỘC LIFT LẠI (--force-relift){Color.END}")
    else:
        print(f"{Color.GREEN}[✓] Lifting cache: BẬT — Các binary đã lift sẽ được tái sử dụng.{Color.END}")

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
        # use_cache và force_relift được truyền từ tham số dòng lệnh
        success = lift_binary(binary_path=path, output=output_bc,
                              use_cache=use_cache, force_relift=force_relift)
        if success:
            print(f"{Color.GREEN}[✓] Nâng mã (Lift) thành công cho: {path}{Color.END}")
            
            # --- BƯỚC THÊM: LÀM ĐẸP MÃ IR (BRIGHTENING) ---
            output_brightened_bc = os.path.join(case_output_dir, f"{base_name}_brightened.bc")
            print(f"{Color.BLUE}{Color.BOLD}    → Bắt đầu làm đẹp mã IR (Brightening) cho: {path}...{Color.END}")
            
            try:
                brighten_success = brighten_ir(output_bc, output_brightened_bc, binary_path=path)
                if brighten_success:
                    output_brightened_ll = f"{os.path.splitext(output_brightened_bc)[0]}.ll"
                    print(f"{Color.GREEN}[✓] Làm đẹp mã IR thành công cho: {path}{Color.END}")
                    print(f"{Color.GREEN}{Color.BOLD}    [✓] FILE NATIVE LLVM IR SẠCH (ĐÃ LÀM ĐẸP & ĐỂ XEM):{Color.END}")
                    print(f"{Color.GREEN}{Color.BOLD}        {output_brightened_ll}{Color.END}")
                    success_count += 1
                    
                    # --- BƯỚC THÊM: KIỂM TRA SEMANTIC EQUIVALENCE (FUZZING CHECK) ---
                    print(f"{Color.BLUE}{Color.BOLD}    → Bắt đầu kiểm tra Semantic Equivalence cho: {path}...{Color.END}")
                    try:
                        # Tìm template phù hợp cho benchmark
                        template_content = None
                        for key in DEFAULT_TEMPLATES.keys():
                            if key in path.lower():
                                template_content = DEFAULT_TEMPLATES[key]
                                print(f"{Color.YELLOW}      [!] Phát hiện benchmark '{key}', sử dụng cấu hình template.{Color.END}")
                                break
                        
                        generator, generator_reason = _select_generator(
                            project_root, path, template_content
                        )
                        if template_content:
                            print(f"{Color.YELLOW}      [!] Phát hiện benchmark, sử dụng template generator.{Color.END}")
                        else:
                            print(f"{Color.BLUE}      [*] Input generator: {generator_reason}.{Color.END}")
                        
                        seed_paths, seed_dir = _resolve_seed_paths(project_root, path)
                        if seed_paths:
                            print(f"{Color.BLUE}    [*] Tìm thấy seed corpus riêng cho binary: {seed_paths[0]}{Color.END}")
                        elif seed_dir:
                            print(f"{Color.BLUE}    [*] Tìm thấy seed directory cho case: {seed_dir}{Color.END}")

                        fuzzer = SemanticFuzzer(
                            output_brightened_bc,
                            path,
                            seed_paths=seed_paths,
                            seed_dir=seed_dir,
                        )
                        fuzzer.compile()
                        
                        # Chạy 100 iterations với 4 thread
                        fuzz_report = fuzzer.run_differential_test(
                            iterations=100,
                            generator=generator,
                            timeout=1.0,
                            compare_stderr=False,
                            num_workers=1
                        )
                        # fuzzer.cleanup()
                        
                        ratio = fuzz_report["equivalence_ratio"]
                        ratio_color = Color.GREEN if ratio == 100.0 else (Color.YELLOW if ratio >= 90.0 else Color.RED)
                        
                        print(f"      {Color.BOLD}Kết quả kiểm tra Semantic Equivalence:{Color.END}")
                        if "afl_stats" in fuzz_report:
                            stats = fuzz_report["afl_stats"]
                            print(f"      - AFL++ Coverage: {stats['bitmap_cvg']} bitmap | {stats['paths_total']} paths | {stats['execs_done']} execs ({stats['execs_per_sec']} execs/s)")
                        print(f"      - Tổng số lần chạy: {fuzz_report['total_runs']}")
                        print(f"      - Số lần chạy có kết luận (Confirmed): {fuzz_report.get('confirmed_runs', fuzz_report['matches'] + fuzz_report['mismatches'])}")
                        print(f"      - Khớp hoàn toàn (Matches): {Color.GREEN}{fuzz_report['matches']}{Color.END}")
                        print(f"      - Không khớp (Mismatches): {Color.RED if fuzz_report['mismatches'] > 0 else Color.GRAY}{fuzz_report['mismatches']}{Color.END}")
                        print(f"      - Timeouts: F1: {fuzz_report['timeouts']['bin1']} | F2: {fuzz_report['timeouts']['bin2']} | Both: {fuzz_report['timeouts']['both']}")
                        print(f"      - Crashes: F1: {fuzz_report['crashes']['bin1']} | F2: {fuzz_report['crashes']['bin2']} | Both: {fuzz_report['crashes']['both']}")
                        print(f"      - Không kết luận (Inconclusive): {Color.YELLOW if fuzz_report.get('inconclusive', 0) > 0 else Color.GRAY}{fuzz_report.get('inconclusive', 0)}{Color.END}")
                        confirmed_ratio = fuzz_report.get('confirmed_equivalence_ratio', ratio)
                        print(f"      - Tỉ lệ tương đương nghiêm ngặt (Strict Equivalence): {ratio_color}{ratio:.2f}%{Color.END}")
                        print(f"      - Tỉ lệ trên ca có kết luận (Confirmed Subset): {confirmed_ratio:.2f}%")
                        
                        if fuzz_report.get("is_fully_equivalent", ratio == 100.0):
                            print(f"      {Color.GREEN}[✓] XÁC NHẬN SEMANTIC EQUIVALENT.{Color.END}")
                        elif fuzz_report.get("inconclusive", 0) > 0 and fuzz_report["mismatches"] == 0:
                            both_timeouts = fuzz_report["timeouts"]["both"]
                            both_crashes = fuzz_report["crashes"]["both"]
                            if both_timeouts and both_crashes:
                                reason = "timeout/crash cả hai bên"
                            elif both_timeouts:
                                reason = "timeout cả hai bên"
                            elif both_crashes:
                                reason = "crash cả hai bên"
                            else:
                                reason = "trạng thái không kết luận"
                            print(f"      {Color.YELLOW}[!] CHƯA THỂ XÁC NHẬN ĐẦY ĐỦ: còn input {reason}.{Color.END}")
                        else:
                            print(f"      {Color.RED}[✗] CẢNH BÁO: PHÁT HIỆN SỰ KHÁC BIỆT SEMANTIC CHƯA ĐƯỢC GIẢI QUYẾT.{Color.END}")
                            if "mismatch_examples" in fuzz_report and fuzz_report["mismatch_examples"]:
                                print(f"      {Color.YELLOW}--- Chi tiết mẫu không khớp (Mismatch Samples) ---{Color.END}")
                                for sample in fuzz_report["mismatch_examples"]:
                                    print(f"      * [Mẫu #{sample['index']}]: Lý do: {sample['reason']}")
                                    print(f"        Arguments: {sample['args']}")
                                    print(f"        Stdin: {repr(sample['stdin'])}")
                                    print(f"        Prog1 (Brightened): status={sample['prog1']['status']}, code={sample['prog1']['returncode']}, stdout={repr(sample['prog1']['stdout'])}, stderr={repr(sample['prog1']['stderr'])}")
                                    print(f"        Prog2 (Obfuscated): status={sample['prog2']['status']}, code={sample['prog2']['returncode']}, stdout={repr(sample['prog2']['stdout'])}, stderr={repr(sample['prog2']['stderr'])}")
                            
                    except Exception as fe:
                        print(f"{Color.RED}      [✗] Lỗi xảy ra khi chạy kiểm tra Semantic Equivalence: {fe}{Color.END}")
                else:
                    print(f"{Color.RED}[✗] Làm đẹp mã IR THẤT BẠI cho: {path}{Color.END}")
            except Exception as e:
                print(f"{Color.RED}[✗] Lỗi khi làm đẹp mã IR: {e}{Color.END}")
        else:
            print(f"{Color.RED}[✗] Nâng mã (Lift) THẤT BẠI cho: {path}{Color.END}")

    print("\n" + f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")
    print(f"{Color.GREEN}{Color.BOLD}[✓] Đã hoàn thành xử lý. Thành công: {success_count}/{len(binary_paths)}{Color.END}")
    print(f"{Color.BLUE}[*] Tất cả kết quả được lưu tại: {result_pipeline_root}{Color.END}")
    print(f"{Color.BLUE}{Color.BOLD}" + "="*80 + f"{Color.END}")

    return 0

if __name__ == "__main__":
    sys.exit(main())

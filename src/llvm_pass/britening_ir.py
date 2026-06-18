#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""
[ ĐẦU VÀO: obfuscated.bc ] (Mã máy dạng thô được nâng lên LLVM IR, chứa cấu trúc CPU State)
         │  
         ▼
┌────────────────────────────────────────────────────────────────────────┐
│ GIAI ĐOẠN 1: Sửa chữa & Chuyển đổi trạng thái ban đầu                  │
│ 1. brighten-repair-pass         ──> Sửa các lỗi cấu trúc IR khi nâng   │
│ 2. brighten-state-ssa-pass      ──> Chuyển các thanh ghi thô thành SSA │
│ 3. [LLVM Chuẩn]* (sroa, gvn...) ──> Tối ưu hóa, dọn dẹp biến cục bộ    │
└────────────────────────────────────────────────────────────────────────┘
         │  
         ▼
┌────────────────────────────────────────────────────────────────────────┐
│ GIAI ĐOẠN 2: Khôi phục cấu trúc Ngăn xếp (Stack)                       │
│ 1. brighten-stack-ssa-pass      ──> Phân tích toán học trên RSP        │
│ 2. brighten-state-forward-pass  ──> Lan truyền giá trị thanh ghi       │
│ 3. [LLVM Chuẩn]* (sroa, cse...) ──> Rút gọn các lệnh load/store bộ nhớ │
└────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────────────---- ┐
│ GIAI ĐOẠN 3: Khôi phục Giao diện Hàm (ABI) & Liên kết Hàm                   │
│ 1. brighten-host-frame-pass      ──> Tái tạo lại 'alloca' cho Stack         │ 
│ 2. brighten-libc-prototype-pass  ──> Khôi phục hàm hệ thống (printf...)     │
│ 3. brighten-internal-call-argify ──> Biến thanh ghi truyền vào thành tham số│
│ 4. Lặp lại (stack-ssa, forward..)──> Đưa các tham số vừa tạo vào SSA        │
│ 5. [LLVM Chuẩn]* (gvn,cfg...)    ──> Ép cấu trúc hàm về dạng chuẩn          │
└────────────────────────────────────────────────────────────────────────---- ┘
         │
         ▼
┌────────────────────────────────────────────────────────────────────────  ┐
│ GIAI ĐOẠN 4: Phân loại bộ nhớ & Loại bỏ mã chết (DCE)                    │
│ 1. brighten-memory-classify-pass ──> Phân biệt vùng nhớ Stack/Heap/Global│
│ 2. brighten-host-frame-pass      ──> Cập nhật lại khung bộ nhớ           │
│ 3. dce (Dead Code Elimination)   ──> Xóa bỏ các lệnh giả lập thừa        │
│ 4. brighten-libc-prototype-pass  ──> Đồng bộ lại với các hàm libc        │
│ 5. [LLVM Chuẩn]* (Vòng lặp cuối)  ──> Thu gọn tối đa cấu trúc IR         │
└────────────────────────────────────────────────────────────────────────  ┘
         |
         │ (Toàn bộ chuỗi trên được lặp lại một lần nữa ở cuối lệnh để đảm bảo sạch mã)
         ▼
┌────────────────────────────────────────────────────────────────────────  ┐
│ VÒNG LẶP CUỐI (Clean-up Phase)                                           │
│ Chạy lại toàn bộ chuỗi: stack-ssa -> forward -> argify -> sroa -> gvn    │
│ Nhằm dọn dẹp các tàn dư phát sinh sau khi phân loại bộ nhớ ở GĐ 4.       │
└────────────────────────────────────────────────────────────────────────  ┘
         │
         ▼
[ ĐẦU RA: obfuscated_brightened.bc ] (Mã IR đã được khử một phần cấu trúc McSema)

"""
import os
import sys
import argparse
import subprocess
import shutil
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Thư mục gốc dự án
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../.."))

# Danh sách các pass plugin và đường dẫn tương đối từ SCRIPT_DIR
PLUGINS = [
    "brighten_010_repair_pass/build/BrightenRepairPass.so",
    "brighten_020_state_ssa_pass/build/BrightenStateSSAPass.so",
    "brighten_030_stack_ssa_pass/build/BrightenStackSSAPass.so",
    "brighten_031_state_forward_pass/build/BrightenStateForwardPass.so",
    "brighten_032_host_frame_pass/build/BrightenHostFramePass.so",
    "brighten_033_libc_prototype_pass/build/BrightenLibcPrototypePass.so",
    "brighten_034_internal_call_argify_pass/build/BrightenInternalCallArgifyPass.so",
    "brighten_040_memory_classify_pass/build/BrightenMemoryClassifyPass.so"
]

PASS_PIPELINE = (
    "brighten-repair-pass,brighten-state-ssa-pass,brighten-host-frame-pass,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,"
    "gvn,instcombine<no-verify-fixpoint>,simplifycfg,brighten-stack-ssa-pass,brighten-state-forward-pass,"
    "sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,gvn,instcombine<no-verify-fixpoint>,simplifycfg,"
    "brighten-host-frame-pass,brighten-libc-prototype-pass,brighten-internal-call-argify-pass,always-inline,brighten-state-ssa-pass,"
    "brighten-host-frame-pass,brighten-stack-ssa-pass,brighten-state-forward-pass,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,"
    "gvn,instcombine<no-verify-fixpoint>,simplifycfg,brighten-memory-classify-pass,brighten-host-frame-pass,dce,"
    "brighten-memory-classify-pass,brighten-libc-prototype-pass,dce,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,"
    "gvn,instcombine<no-verify-fixpoint>,simplifycfg,brighten-stack-ssa-pass,brighten-state-forward-pass,"
    "brighten-internal-call-argify-pass,always-inline,brighten-state-ssa-pass,brighten-host-frame-pass,brighten-stack-ssa-pass,brighten-state-forward-pass,sroa,early-cse,"
    "instcombine<no-verify-fixpoint>,simplifycfg,gvn,instcombine<no-verify-fixpoint>,simplifycfg,"
    "brighten-memory-classify-pass,brighten-host-frame-pass,dce,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,"
    "gvn,instcombine<no-verify-fixpoint>,simplifycfg,deadargelim,globaldce,brighten-state-ssa-pass"
)

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'

def clean_ir_file(ll_path):
    if not os.path.exists(ll_path):
        return False
    with open(ll_path, 'r') as f:
        content = f.read()
    
    # 1. Thay thế các con trỏ đến __mcsema_* trong static data segment bằng null
    # Để tránh việc clang/ld báo lỗi undefined reference
    content = re.sub(r'ptr\s+@__mcsema_[a-zA-Z0-9_]+', 'ptr null', content)
    
    # Tìm hàm native đại diện cho main
    main_native_name = None
    wrapper_match = re.search(r'define internal ptr @main_wrapper\([^)]*\)[^{]*\{([\s\S]*?)\}', content)
    if wrapper_match:
        body = wrapper_match.group(1)
        call_match = re.search(r'call \w+ @(sub_[0-9a-fA-F]+_main_native|sub_[0-9a-fA-F]+_native)', body)
        if call_match:
            main_native_name = call_match.group(1)
        else:
            call_match = re.search(r'call \w+ @(sub_[0-9a-fA-F]+)', body)
            if call_match:
                main_native_name = call_match.group(1)
                
    if not main_native_name:
        func_names = re.findall(r'define \w+ @(sub_[0-9a-fA-F]+_main_native)', content)
        if func_names:
            main_native_name = func_names[0]
            
    lines = content.split('\n')
    new_lines = []
    in_function_to_strip = False
    brace_count = 0
    stripped_funcs = set()
    
    strip_patterns = [
        r'^(define|declare)\s+.*@__mcsema_',
        r'^(define|declare)\s+.*@__remill_',
        r'^(define|declare)\s+.*@callback_',
        r'^(define|declare)\s+.*_wrapper\s*\(',
        r'^(define|declare)\s+.*@main\s*\(',
        r'^(define|declare)\s+.*@start\s*\('
    ]
    
    # Pattern để khớp alias segment (kể cả có thread_local): @data_36060 = internal alias i8, getelementptr ... hoặc @data_3e000 = internal alias i32, ptr ...
    alias_pattern = r'^@([a-zA-Z0-9_]+)\s*=\s*(.*?)\balias\s+([^,]+),\s*(.*)$'
    
    for line in lines:
        if not in_function_to_strip and re.match(r'^@[0-9]+\s*=\s*', line):
            continue
        if not in_function_to_strip:
            is_strip = False
            for pat in strip_patterns:
                if re.match(pat, line):
                    is_strip = True
                    break
            if is_strip:
                name_match = re.search(r'@([a-zA-Z0-9_]+)', line)
                if name_match:
                    stripped_funcs.add(name_match.group(1))
                    
                if line.strip().startswith("declare"):
                    # Nếu là declare, chỉ bỏ qua dòng này
                    continue
                else:
                    # Nếu là define, bắt đầu bỏ qua block hàm
                    in_function_to_strip = True
                    brace_count = 0
                    if '{' in line:
                        brace_count += line.count('{') - line.count('}')
                    continue
        else:
            brace_count += line.count('{') - line.count('}')
            if brace_count <= 0 and '}' in line:
                in_function_to_strip = False
            continue
            
        # Dọn dẹp structs/unions CPU ảo của McSema
        if re.match(r'^%struct\.', line) or re.match(r'^%union\.', line):
            continue
            
        # Xóa global register state
        if re.match(r'^@__mcsema_reg_state\s*=', line):
            continue
            
        new_lines.append(line)
        
    if main_native_name:
        main_ir = f"""
define dso_local i32 @main(i32 %argc, ptr %argv) {{
entry:
  %argc.ext = sext i32 %argc to i64
  %argv.int = ptrtoint ptr %argv to i64
  %res = call i64 @{main_native_name}(i64 %argc.ext, i64 %argv.int)
  %res.trunc = trunc i64 %res to i32
  ret i32 %res.trunc
}}
"""
        new_lines.append(main_ir)
        if "main" in stripped_funcs:
            stripped_funcs.remove("main")
            
    # Thêm declarations và stubs cho tất cả các hàm bị xóa
    content_so_far = '\n'.join(new_lines)
    stubs_list = []
    
    if re.search(r'@__remill_function_call\b', content_so_far):
        stubs_list.append("""
define ptr @__remill_function_call(ptr %0, i64 %1, ptr %2) {
entry:
  ret ptr %2
}""")
    if re.search(r'@__remill_jump\b', content_so_far):
        stubs_list.append("""
define ptr @__remill_jump(ptr %0, i64 %1, ptr %2) {
entry:
  ret ptr %2
}""")

    if "__remill_function_call" in stripped_funcs:
        stripped_funcs.remove("__remill_function_call")
    if "__remill_jump" in stripped_funcs:
        stripped_funcs.remove("__remill_jump")
        
    for func in sorted(stripped_funcs):
        # Không tạo stub cho __mcsema_ để giữ IR sạch 100%
        if func.startswith("__mcsema_"):
            continue
        if re.search(rf'@{func}\b', content_so_far):
            stubs_list.append(f"""
define void @{func}() {{
entry:
  ret void
}}""")
        
    if stubs_list:
        stubs_ir = "\n".join(stubs_list)
        new_lines.append(stubs_ir)
        
    cleaned_content = '\n'.join(new_lines)
    cleaned_content = re.sub(r'\n{3,}', '\n\n', cleaned_content)
    with open(ll_path, 'w') as f:
        f.write(cleaned_content)
    return True

def brighten_ir(input_path, output_path=None):
    """
    Chạy llvm opt với các pass plugin làm đẹp IR (brightening) và dọn dẹp boilerplate
    """
    if not os.path.exists(input_path):
        print(f"{Color.RED}[✗] Lỗi: Không tìm thấy file đầu vào tại '{input_path}'{Color.END}")
        return False

    opt_bin = shutil.which("opt-21") or shutil.which("opt")
    if not opt_bin:
        print(f"{Color.RED}[✗] Lỗi: Không tìm thấy 'opt-21' hoặc 'opt' trong hệ thống.{Color.END}")
        return False

    # Xác định đường dẫn output
    if not output_path:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_brightened{ext}"

    # Build command
    cmd = [opt_bin]

    # Load plugins
    for plugin_rel in PLUGINS:
        plugin_path = os.path.abspath(os.path.join(SCRIPT_DIR, plugin_rel))
        if not os.path.exists(plugin_path):
            print(f"{Color.RED}[✗] Lỗi: Không tìm thấy pass plugin tại '{plugin_path}'{Color.END}")
            return False
        cmd.extend(["-load-pass-plugin", plugin_path])

    # Thiết lập pipeline pass và file input/output
    cmd.extend([
        "-passes", PASS_PIPELINE,
        input_path,
        "-o", output_path
    ])

    print(f"{Color.BLUE}[*] Đang thực thi brightening với: {opt_bin}{Color.END}")
    print(f"{Color.GRAY}    Lệnh: {' '.join(cmd)}{Color.END}")

    try:
        env = os.environ.copy()
        env["REMILL_STACK_SSA_ALLOW_BOUNDARY"] = "0"
        res = subprocess.run(cmd, capture_output=True, text=True, env=env)
        if res.returncode == 0:
            print(f"{Color.GREEN}[✓] Brightening hoàn tất! Kết quả đã ghi ra: {output_path}{Color.END}")
            
            # Chạy llvm-dis để sinh file .ll cho dễ đọc nếu file output là .bc
            if output_path.endswith(".bc"):
                llvm_dis = shutil.which("llvm-dis-21") or shutil.which("llvm-dis")
                if llvm_dis:
                    output_ll = f"{os.path.splitext(output_path)[0]}.ll"
                    subprocess.run([llvm_dis, output_path, "-o", output_ll])
                    print(f"{Color.BLUE}[*] Đang tiến hành dọn dẹp boilerplate và struct rác trong: {output_ll}{Color.END}")
                    
                    # Gọi hàm dọn dẹp file .ll
                    if clean_ir_file(output_ll):
                        print(f"{Color.GREEN}[✓] Dọn dẹp IR thành công!{Color.END}")
                        
                        # Biên dịch ngược lại .ll đã dọn dẹp thành .bc
                        llvm_as = shutil.which("llvm-as-21") or shutil.which("llvm-as")
                        if llvm_as:
                            as_res = subprocess.run([llvm_as, output_ll, "-o", output_path], capture_output=True, text=True)
                            if as_res.returncode == 0:
                                print(f"{Color.GREEN}[✓] Đã cập nhật tệp Bitcode sạch: {output_path}{Color.END}")
                            else:
                                print(f"{Color.RED}[✗] Lỗi khi chạy llvm-as (Mã lỗi: {as_res.returncode}){Color.END}")
                                print(f"{Color.RED}    Stderr: {as_res.stderr}{Color.END}")
                                return False
            return True
        else:
            print(f"{Color.RED}[✗] Lỗi khi chạy opt (Mã lỗi: {res.returncode}){Color.END}")
            print(f"{Color.RED}    Stderr: {res.stderr}{Color.END}")
            return False
    except Exception as e:
        print(f"{Color.RED}[✗] Lỗi thực thi: {e}{Color.END}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Chạy các pass brightening IR bằng các plugin .so có sẵn")
    parser.add_argument("-i", "--input", required=True, help="Đường dẫn file LLVM Bitcode (.bc) hoặc IR (.ll) đầu vào")
    parser.add_argument("-o", "--output", help="Đường dẫn file đầu ra (.bc hoặc .ll)")
    args = parser.parse_args()

    success = brighten_ir(args.input, args.output)
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()

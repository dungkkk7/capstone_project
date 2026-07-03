#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""
### Phân tích chi tiết và đề xuất bổ sung cho từng Phase:

  #### PHASE 0 — Symbol Discovery

  - Chi tiết: Nên thu thập thêm bảng ký hiệu từ ELF gốc (nếu có) hoặc xuất từ IDA Pro để ánh xạ địa chỉ PC (sub_XXXX) sang tên hàm gốc ngay từ đầu.
  - Verify: Đảm bảo metadata được đính kèm dưới dạng LLVM Named Metadata (ví dụ: !brighten.symbols) để các pass sau truy vấn trực tiếp.

  #### PHASE 1 — Structural Repair

  - Chi tiết: Cần bổ sung việc loại bỏ các directive vô nghĩa của Assembly cũ được nhúng qua inline asm của McSema (gây crash compiler mới).

  #### PHASE 2 — Call / Return Devirtualization

  - Chi tiết:
      - brighten-remill-return-lower: Chuyển đổi lệnh return thô (McSema lưu RAX vào State rồi RET void) thành lệnh ret trả về giá trị thực tế của RAX.
      - Cần đảm bảo globaldce chạy ở cuối phase này để xóa bỏ các hàm thunk/dispatcher không còn ai gọi.

  #### PHASE 3 — Register State SSA

  - Chi tiết:
      - brighten-flag-lower: Chuyển đổi toàn bộ các phép tính toán cờ CPU phức tạp (CF, ZF...) thành các biến logic i1 cục bộ. LLVM gvn và dce sau đó sẽ dễ dàng tối giản các lệnh so sánh nhảy.

  #### PHASE 4 — Stack Frame Recovery

  - Chi tiết:
      - brighten-stack-model: Dựng lại bản đồ stack frame bằng cách tìm toán hạng RSP trong SSA.
      - brighten-host-frame: Thay thế các truy cập offset bằng alloca. Chú ý: Cần xử lý trường hợp biến cục bộ bị truyền địa chỉ (passed by pointer/reference) sang hàm khác.

  #### PHASE 5 — ABI Recovery / Function Signature Rewrite

  - Chi tiết:
      - brighten-livein-liveout: Phân tích thanh ghi nào là đầu vào (Live-in) và đầu ra (Live-out) của từng hàm để quyết định danh sách tham số.
      - Chạy deadargelim ngay sau đó để xóa bỏ các tham số thừa (ví dụ hàm không dùng đến RDX nhưng ABI mặc định truyền vào).

  #### PHASE 6 — Global/Data Recovery

  - Chi tiết:
      - brighten-string-recover: Cực kỳ quan trọng. Quét phân đoạn @seg_...__rodata để dựng lại @.str = private unnamed_addr constant ....
      - brighten-jumptable-recover: Nhận diện cấu trúc Jump Table từ lệnh switch gián tiếp để khôi phục cấu trúc điều khiển chuẩn (chuỗi if-else hoặc switch-case sạch).

  #### PHASE 7 — Type Reconstruction

  - Chi tiết:
      - Phân tích các lệnh getelementptr dựa trên kiểu dữ liệu của alloca ở Phase 4 để nhóm các biến đơn lẻ thành struct/array C gốc.

  #### PHASE 8 — Final Native Cleanup

  - Chi tiết:
      - brighten-type-cleanup: Loại bỏ định nghĩa %struct.State và các type thừa ra khỏi IR.
      - function-attrs: Tự động suy luận các thuộc tính hàm (readonly, readnone, nofree) để IR đầu ra chuẩn hóa tối đa.


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
    "brighten_015_runtime_helper_materialization/build/BrightenRuntimeHelperPass.so",
    "brighten_020_devirt_pass/build/BrightenDevirtPass.so",
    "brighten_030_state_ssa_pass/build/BrightenStateSSAPass.so",
    "brighten_040_stack_frame_pass/build/BrightenStackFramePass.so",
    "brighten_050_abi_recovery/build/BrightenABIRecoveryPass.so",
    "brighten_060_extern_call_bridge/build/BrightenExternCallBridgePass.so",
    "brighten_070_global_data_recovery/build/BrightenGlobalDataRecoveryPass.so"
]
# Danh sách các pass plugin và đường dẫn tương đối từ SCRIPT_DIR
PLUGINS1 = [
    "brighten_010_repair_pass/build/BrightenRepairPass.so",
    "brighten_015_runtime_helper_materialization/build/BrightenRuntimeHelperPass.so",
    "brighten_020_devirt_pass/build/BrightenDevirtPass.so",
    "brighten_030_state_ssa_pass/build/BrightenStateSSAPass.so",
    "brighten_040_stack_frame_pass/build/BrightenStackFramePass.so",
    "brighten_050_abi_recovery/build/BrightenABIRecoveryPass.so",
    "brighten_060_extern_call_bridge/build/BrightenExternCallBridgePass.so",
    "brighten_070_global_data_recovery/build/BrightenGlobalDataRecoveryPass.so"
]

PASS_PIPELINE = (
    "brighten-repair-pass,brighten-remill-runtime-pass,brighten-devirt-pass,always-inline,brighten-state-ssa-pass,brighten-stack-frame-pass,brighten-abi-recovery-pass,brighten-extern-call-bridge,brighten-global-data-recovery-pass,deadargelim,function-attrs,ipsccp,globaldce,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce"
)
PASS_PIPELINE1 = (
    "brighten-repair-pass,brighten-remill-runtime-pass,brighten-devirt-pass,always-inline,brighten-state-ssa-pass,brighten-stack-frame-pass,brighten-abi-recovery-pass,brighten-extern-call-bridge,brighten-global-data-recovery-pass,deadargelim,function-attrs,ipsccp,globaldce,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,gvn,dce"
)
class Color:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    END = '\033[0m'

def clean_unused_types_and_globals(content):
    # 1. Skip function stripping (keep all defined functions to avoid undefined reference errors)
    new_lines = content.split('\n')
    
    # 2. Iterate to remove unused globals and aliases
    while True:
        lines = content.split('\n')
        globals_def = {}
        for i, line in enumerate(lines):
            match = re.match(r'^@([a-zA-Z0-9_.]+)\s*=\s*(?:internal\s+)?(?:constant|global|alias|thread_local)\s+', line)
            if match:
                globals_def[match.group(1)] = i
                
        if not globals_def:
            break
            
        global_ref_counts = {name: 0 for name in globals_def}
        for i, line in enumerate(lines):
            def_match = re.match(r'^@([a-zA-Z0-9_.]+)\s*=\s*', line)
            def_name = def_match.group(1) if def_match else None
            
            refs = re.findall(r'@([a-zA-Z0-9_.]+)\b', line)
            for ref in refs:
                if ref in global_ref_counts:
                    if ref != def_name:
                        global_ref_counts[ref] += 1
                        
        unused_globals = [name for name, count in global_ref_counts.items() if count == 0]
        if not unused_globals:
            break
            
        new_lines = []
        for i, line in enumerate(lines):
            match = re.match(r'^@([a-zA-Z0-9_.]+)\s*=\s*', line)
            if match and match.group(1) in unused_globals:
                continue
            new_lines.append(line)
        content = '\n'.join(new_lines)
        
    # 3. Remove unused struct/type definitions
    while True:
        lines = content.split('\n')
        types_def = {}
        for i, line in enumerate(lines):
            match = re.match(r'^%([a-zA-Z0-9_.]+)\s*=\s*type\s+', line)
            if match:
                types_def[match.group(1)] = i
                
        if not types_def:
            break
            
        type_ref_counts = {name: 0 for name in types_def}
        for i, line in enumerate(lines):
            def_match = re.match(r'^%([a-zA-Z0-9_.]+)\s*=\s*', line)
            def_name = def_match.group(1) if def_match else None
            
            refs = re.findall(r'%([a-zA-Z0-9_.]+)\b', line)
            for ref in refs:
                if ref in type_ref_counts:
                    if ref != def_name:
                        type_ref_counts[ref] += 1
                        
        unused_types = [name for name, count in type_ref_counts.items() if count == 0]
        if not unused_types:
            break
            
        new_lines = []
        for i, line in enumerate(lines):
            match = re.match(r'^%([a-zA-Z0-9_.]+)\s*=\s*', line)
            if match and match.group(1) in unused_types:
                continue
            new_lines.append(line)
        content = '\n'.join(new_lines)
        
    return content

def clean_ir_file(ll_path, binary_path=None):
    if not os.path.exists(ll_path):
        return False
    with open(ll_path, 'r') as f:
        content = f.read()
    
    # 1. Thay thế các con trỏ đến __mcsema_* trong static data segment bằng null (loại trừ __mcsema_reg_state)
    # Để tránh việc clang/ld báo lỗi undefined reference
    content = re.sub(r'ptr\s+@__mcsema_(?!reg_state\b)[a-zA-Z0-9_]+', 'ptr null', content)
    
    # 2. Biến define của __remill_function_call và __remill_jump thành declare để tránh multiple definition (commented out because we compile standalone)
    # content = re.sub(
    #     r'define\s+(?:[a-zA-Z0-9_]+\s+)*ptr\s+@(__remill_function_call|__remill_jump)\([^)]*\)[^{]*\{[\s\S]*?\}',
    #     r'declare ptr @\1(ptr, i64, ptr)',
    #     content
    # )
        
    # 3. Trích xuất entry point PC từ inline assembly của main cũ (tìm trong function @main)
    main_match = re.search(r'define\s+[^@{]*@main\b[^{]*\{([\s\S]*?)\}', content)
    if main_match:
        main_body = main_match.group(1)
        pc_match = re.search(r'pushq\s+\$\$0x([0-9a-fA-F]+)', main_body)
        pc_val = int(pc_match.group(1), 16) if pc_match else 0
    else:
        pc_match = re.search(r'pushq\s+\$\$0x([0-9a-fA-F]+)', content)
        pc_val = int(pc_match.group(1), 16) if pc_match else 0
    
    # 4. Quét và loại bỏ tất cả các hàm chứa inline assembly (gây crash clang-21)
    lines = content.split('\n')
    new_lines = []
    in_func = False
    func_lines = []
    func_name = None
    stripped_funcs = set()
    
    for line in lines:
        if not in_func:
            if line.startswith('define '):
                in_func = True
                func_lines = [line]
                name_match = re.search(r'@([a-zA-Z0-9_.]+)', line)
                func_name = name_match.group(1) if name_match else None
            else:
                new_lines.append(line)
        else:
            func_lines.append(line)
            if line.startswith('}'):
                in_func = False
                has_asm = any('asm sideeffect' in l for l in func_lines)
                if has_asm and func_name not in ['main', 'start', 'main_wrapper', 'start_wrapper']:
                    if func_name:
                        stripped_funcs.add(func_name)
                else:
                    new_lines.extend(func_lines)
    content = '\n'.join(new_lines)
    print(f"DEBUG: Stripped functions: {sorted(list(stripped_funcs))}")
    print(f"DEBUG: main_wrapper defined in content: {'@main_wrapper' in content}")
    for func in stripped_funcs:
        content = re.sub(rf'ptr @{re.escape(func)}\b', 'ptr null', content)
    
    # 5. Xác định kiểu dữ liệu thực tế của @__mcsema_reg_state (thường bị đổi tên thành %0)
    state_type = "%struct.State"
    state_type_match = re.search(r'@__mcsema_reg_state\s*=\s*(?:thread_local\([^)]*\)\s+)?global\s+([%a-zA-Z0-9_.]+)', content)
    if state_type_match:
        state_type = state_type_match.group(1)

    # 6. Thêm hàm main mới sạch sẽ gọi main_wrapper và trả về RAX từ State
    # Chỉ thêm guest stack nếu chưa được định nghĩa
    if not re.search(r'@__lifter_guest_stack\s*=\s*', content):
        content = "@__lifter_guest_stack = internal global [8388608 x i8] zeroinitializer, align 16\n" + content

    # Chỉ thêm nếu chưa có định nghĩa @main trong content (để tránh trùng với định nghĩa do pass 015 tự sinh)
    if not re.search(r'define\s+(?:[a-zA-Z0-9_]+\s+)*@main\b', content):
        new_main_ir = f"""
define dso_local i32 @main(i32 %argc, ptr %argv) {{
entry:
  %fs_base = call i64 asm sideeffect "movq %fs:0, $0", "=r"()
  %fs_base_ptr = getelementptr {state_type}, ptr @__mcsema_reg_state, i32 0, i32 5, i32 7
  store i64 %fs_base, ptr %fs_base_ptr, align 8
  %rsp_ptr = getelementptr {state_type}, ptr @__mcsema_reg_state, i32 0, i32 6, i32 13, i32 0, i32 0
  store i64 ptrtoint (ptr getelementptr inbounds ([8388608 x i8], ptr @__lifter_guest_stack, i64 0, i64 8388480) to i64), ptr %rsp_ptr, align 8
  %edi_ptr = getelementptr {state_type}, ptr @__mcsema_reg_state, i32 0, i32 6, i32 11, i32 0, i32 0
  store i32 %argc, ptr %edi_ptr, align 4
  %rsi_ptr = getelementptr {state_type}, ptr @__mcsema_reg_state, i32 0, i32 6, i32 9, i32 0, i32 0
  %argv_val = ptrtoint ptr %argv to i64
  store i64 %argv_val, ptr %rsi_ptr, align 8
  %res = call ptr @main_wrapper(ptr null, i64 {pc_val}, ptr null)
  %rax_ptr = getelementptr {state_type}, ptr @__mcsema_reg_state, i32 0, i32 6, i32 1, i32 0, i32 0
  %rax_val = load i64, ptr %rax_ptr, align 8
  %res_i32 = trunc i64 %rax_val to i32
  ret i32 %res_i32
}}
"""
        content += new_main_ir
        
    cleaned_content = clean_unused_types_and_globals(content)
    with open(ll_path, 'w') as f:
        f.write(cleaned_content)
    return True

def brighten_ir(input_path, output_path=None, binary_path=None):
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
        env["REMILL_STACK_SSA_ALLOW_BOUNDARY"] = "1"
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
                    if clean_ir_file(output_ll, binary_path):
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

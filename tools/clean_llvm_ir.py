#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import re

def clean_ir(input_file, output_file):
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' does not exist.")
        return False

    with open(input_file, 'r') as f:
        content = f.read()

    # 1. Tìm hàm native đại diện cho main
    # Thường được gọi trong main_wrapper
    main_native_name = None
    wrapper_match = re.search(r'define internal ptr @main_wrapper\([^)]*\)[^{]*\{([\s\S]*?)\}', content)
    if wrapper_match:
        body = wrapper_match.group(1)
        # Tìm lệnh gọi hàm native trong wrapper
        call_match = re.search(r'call \w+ @(sub_[0-9a-fA-F]+_main_native|sub_[0-9a-fA-F]+_native)', body)
        if call_match:
            main_native_name = call_match.group(1)
            print(f"Found main native function: @{main_native_name}")
        else:
            # Fallback nếu không tìm thấy pattern main_native
            call_match = re.search(r'call \w+ @(sub_[0-9a-fA-F]+)', body)
            if call_match:
                main_native_name = call_match.group(1)
                print(f"Fallback: Found main native function: @{main_native_name}")

    if not main_native_name:
        # Thử tìm các hàm chứa _main_native trong module
        func_names = re.findall(r'define \w+ @(sub_[0-9a-fA-F]+_main_native)', content)
        if func_names:
            main_native_name = func_names[0]
            print(f"Heuristic: Found main native function: @{main_native_name}")

    lines = content.split('\n')
    new_lines = []
    
    in_function_to_strip = False
    brace_count = 0
    stripped_funcs = []

    # Danh sách các hàm boilerplate cần xóa
    strip_patterns = [
        r'^define\s+.*@__mcsema_',
        r'^define\s+.*@__remill_',
        r'^define\s+.*@callback_',
        r'^define\s+.*_wrapper\s*\(',
        r'^define\s+.*@main\s*\(',
        r'^define\s+.*@start\s*\('
    ]

    for line in lines:
        # Kiểm tra bắt đầu hàm
        if not in_function_to_strip:
            is_strip = False
            for pat in strip_patterns:
                if re.match(pat, line):
                    is_strip = True
                    # Tìm tên hàm để log
                    name_match = re.search(r'@([a-zA-Z0-9_]+)', line)
                    if name_match:
                        stripped_funcs.append(name_match.group(1))
                    break
            
            if is_strip:
                in_function_to_strip = True
                brace_count = 0
                # Bỏ qua dòng này
                if '{' in line:
                    brace_count += line.count('{') - line.count('}')
                continue
        else:
            # Đang trong hàm cần xóa, theo dõi dấu ngoặc nhọn
            brace_count += line.count('{') - line.count('}')
            if brace_count <= 0 and '}' in line:
                in_function_to_strip = False
            continue

        # Lọc các dòng top-level rác: struct, union, global register state
        if re.match(r'^%struct\.', line) or re.match(r'^%union\.', line):
            # Bỏ qua dòng khai báo struct/union rác
            continue
        if re.match(r'^@__mcsema_reg_state\s*=', line):
            # Bỏ qua khai báo global state
            continue

        new_lines.append(line)

    print(f"Stripped {len(stripped_funcs)} boilerplate/wrapper functions: {', '.join(stripped_funcs[:5])}...")

    # 2. Sinh hàm main mới sạch sẽ gọi trực tiếp native main nếu tìm thấy
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
        print("Generated new native @main entry point calling the main native function.")
    else:
        print("Warning: Could not identify main native function. No @main entry point generated.")

    # Ghi file kết quả
    cleaned_content = '\n'.join(new_lines)
    
    # 3. Clean up double/triple newlines
    cleaned_content = re.sub(r'\n{3,}', '\n\n', cleaned_content)

    with open(output_file, 'w') as f:
        f.write(cleaned_content)
    
    print(f"Successfully cleaned LLVM IR and saved to: {output_file}")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 clean_llvm_ir.py <input.ll> <output.ll>")
        sys.exit(1)
    clean_ir(sys.argv[1], sys.argv[2])

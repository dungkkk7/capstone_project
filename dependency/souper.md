 Bạn KHÔNG NGHĨA LÀ PHẢI COPY CẢ REPO sang project khác!

  Souper được thiết kế dưới dạng bộ công cụ độc lập (standalone tools) và Plugin cho Clang/LLVM. Sau khi build xong trong thư mục build-llvm21, bạn chỉ cần đem các file binary/plugin tạo ra đi dùng cho
  bất kỳ dự án C/C++/LLVM nào:
  ──────
  ### Các cách đem Souper sang dự án khác sử dụng:

  #### 1. Dùng làm Plugin trực tiếp cho clang / clang++ (Khuyên dùng)

  Bạn chỉ cần đem duy nhất file plugin libsouperPass.so đi và load nó khi biên dịch code ở dự án khác:

    clang-21 -fplugin=/path/to/souper/build-llvm21/libsouperPass.so -z3-path=/usr/bin/z3 -O3 main.c -o main

  #### 2. Dùng bộ trình biên dịch bọc sẵn (sclang / sclang++)

  Trong thư mục build-llvm21/utils/, Souper tạo ra 2 trình bọc sclang và sclang++. Bạn có thể dùng chúng thay thế cho gcc/clang trong Makefile hoặc CMake của dự án khác:

    # Trong dự án C/C++ khác của bạn:
    ./configure CC=/path/to/souper/build-llvm21/utils/sclang CXX=/path/to/souper/build-llvm21/utils/sclang++
    make

  #### 3. Dùng công cụ dòng lệnh độc lập (souper / souper-check)

  Bạn xuất file bitcode (.bc) từ dự án khác bằng clang -emit-llvm -c file.c -o file.bc, sau đó truyền file .bc đó cho souper phân tích:

    /path/to/souper/build-llvm21/souper -z3-path=/usr/bin/z3 file.bc
    ──────
  ### Tóm lại:

  • Tệp cần lấy đi: Bạn chỉ cần thư mục biên dịch build-llvm21/ (chứa các file thực thi souper, souper-check và thư viện plugin libsouperPass.so).
  • Không cần copy mã nguồn repo Souper vào dự án của bạn.

## Tích hợp trong capstone_project

Pipeline gọi Souper tự động sau khi toàn bộ custom brightening passes và native
cleanup hoàn tất. Lệnh tương đương:

```bash
opt-21 \
  -load-pass-plugin dependency/souper/build-llvm21/libsouperPass.so \
  -passes='function(souper),dce,instcombine,simplifycfg,verify' \
  input_brightened.bc -o output.bc
```

Các runtime artifact được đóng gói trong `dependency/souper/`:

- `build-llvm21/libsouperPass.so`: LLVM 21 new-pass-manager plugin.
- `build-llvm21/souper`, `build-llvm21/souper-check`: standalone tools.
- `bin/z3` và `lib/libz3.so.4.13`: solver/runtime đúng phiên bản của build.

Output chỉ thay thế bitcode brightened sau khi Souper chạy thành công và pass
`verify` chấp nhận module. Mỗi case sinh thêm `<name>_souper_report.json`.
Pipeline cũng giữ ba IR snapshot để so sánh:

- `<name>_before_brightening.ll`
- `<name>_before_souper.ll`
- `<name>_after_souper.ll`

Mặc định dùng mode `maximum`: CEGIS synthesis, tối đa bốn component,
arithmetic/bitwise/comparison/select components, operand harvesting và block
path conditions. Mode này mạnh nhưng có thể chậm hơn rất nhiều so với mode
`safe`.

Souper CEGIS hiện có upstream bug trên một số lifted IR mixed-width. Pipeline
luôn thử `maximum` trước; nếu process abort, verifier fail hoặc timeout thì tự
động chạy lại bằng `safe`. Report ghi `status=pass_with_fallback`,
`requested_mode=maximum` và `effective_mode=safe`. Bitcode trước Souper được
giữ nguyên cho đến khi một lần chạy đã qua `verify`, nên maximum failure không
làm hỏng artifact hoặc biến cả case thành brightening fail.

Biến môi trường:

- `BRIGHTEN_SOUPER=0`: tắt bước Souper để debug.
- `BRIGHTEN_SOUPER_MODE=maximum|safe`: chọn CEGIS mạnh nhất hoặc inference mặc định.
- `BRIGHTEN_SOUPER_TIMEOUT=...`: timeout toàn module; mặc định maximum=900s, safe=120s.
- `BRIGHTEN_SOUPER_SOLVER_TIMEOUT=...`: timeout mỗi query; mặc định maximum=60s, safe=15s.
- `BRIGHTEN_SOUPER_PLUGIN=/path/libsouperPass.so`: override plugin.
- `BRIGHTEN_SOUPER_PIPELINE=...`: override pass pipeline của Souper.

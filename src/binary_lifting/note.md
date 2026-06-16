chmod +x lift.sh

#### 2. Cài đặt các Dependencies (Nếu chưa có)
McSema hoạt động bằng cách gọi một Disassembler làm backend để đọc cấu trúc Control Flow Graph. Bạn cần chuẩn bị sẵn một trong các công cụ sau:
* **IDA Pro:** (Khuyên dùng cho độ chính xác cao nhất với McSema). Ví dụ đường dẫn: `/home/user/idapro-7.7/idat64`
* **Ghidra:** Đường dẫn tới thư mục cài đặt Ghidra.
* **Binary Ninja:** Đường dẫn tới file thực thi `binaryninja`.

Ngoài ra, hãy đảm bảo hệ thống đã cài đặt gói `llvm` (để có sẵn lệnh `llvm-dis` chuyển đổi mã từ dạng nhị phân `.bc` sang dạng văn bản `.ll` dễ đọc).

#### 3. Thực thi câu lệnh Lift
Cách sử dụng script lifting.py sau khi đã được sửa đổi
  như sau:

  ### 1. Câu lệnh chạy cơ bản (Khuyên dùng)
  Nếu binary của mày chạy trên Linux kiến trúc x64 (amd64) và
  phân tích bắt đầu từ hàm  main , mày chỉ cần truyền vào
  đường dẫn tệp binary bằng tham số  -b  (hoặc  --binary ):

    python3 src/binary_lifting/lifting.py -b                  
  data/obfuscated/hash/clean.bin                              

  (Script sẽ tự động tìm IDA Pro 9.3 và lưu kết quả vào thư   
  mục  result/hash/ )
  ──────
  ### 2. Các tham số tùy chỉnh nâng cao

  Script hỗ trợ các cờ tùy biến sau:

   Cờ (Flag)           | Ý nghĩa             | Mặc định
  ---------------------|---------------------|----------------
    -b ,  --binary     | (Bắt buộc) Đường    | (Không có)
                       | dẫn tới file binary |
                       | cần lift.           |
    -o ,  --output     | Đường dẫn file LLVM |  result/[subdir
                       | Bitcode  .bc  đầu   | ]/[name].bc 
                       | ra mong muốn.       |
    -a ,  --arch       | Kiến trúc CPU ( x86 |  amd64 
                       | ,  amd64 ,  aarch64 |                
                       | ).                  |
    -s ,  --os         | Hệ điều hành nguồn  |  linux 
                       | ( linux ,  windows  |
                       | ,  macos ).         |
    -e ,  --entrypoint | Tên hàm bắt đầu     |  main 
                       | phân tích (điểm bắt |
                       | đầu dịch).          |
    -d ,  --           | Đường dẫn tới tệp   |  /opt/ida-pro-
   disassembler        | thực thi  idat  của | 9.3/idat 
                       | IDA Pro.            |
  ──────
  ### 3. Ví dụ các trường hợp tùy chỉnh

  Ví dụ 1: Thay đổi hàm bắt đầu dịch ngược sang một hàm cụ thể
  (ví dụ:  verify_key )

    python3 src/binary_lifting/lifting.py \
      -b data/obfuscated/keybox/clean.bin \
      -e verify_key

  Ví dụ 2: Chỉ định trực tiếp tệp đầu ra và chạy kiến trúc x86
  (32-bit)

    python3 src/binary_lifting/lifting.py \
      -b data/obfuscated/hash/clean.bin \
      -a x86 \
      -o result/my_custom_output.bc
  ──────
  ### 4. Kết quả đầu ra nằm ở đâu?

  Theo cơ chế tự động phân bổ đường dẫn mới, kết quả sẽ nằm
  gọn gàng trong thư mục  result/<tên_dự_án>/ .
  Ví dụ sau khi chạy cho tệp  clean.bin  trong dự án  hash ,
  thư mục  result/hash/  sẽ chứa:

  1.  clean.cfg : File cấu trúc luồng điều khiển của IDA Pro
  sinh ra.
  2.  clean.bc : File LLVM Bitcode (mã IR nhị phân sau khi
  lift).
  3.  clean.ll : File mã nguồn LLVM IR dạng văn bản đọc được
  (mày có thể dùng file này để phân tích hoặc đưa vào mô hình
  LLM).
  4.  clean_disass.log : Nhật ký dịch ngược của IDA Pro (hữu
  ích khi cần debug lỗi phân rã mã).

  Về mặt kỹ thuật, không thể biên dịch tệp LLVM IR do McSema  
  tạo ra nếu hoàn toàn không sử dụng thư viện runtime này.

  Lý do là vì mã nguồn trong  obfuscated.ll  được thiết kế
  xung quanh cấu trúc "CPU ảo" của McSema. Nếu không có thư
  viện định nghĩa cách khởi tạo và vận hành "CPU ảo" này,
  trình biên dịch sẽ không hiểu các lệnh nhảy và gọi hàm.

  Tuy nhiên, tùy thuộc vào mục đích của mày (muốn file chạy
  độc lập hay muốn mã nguồn IR sạch hơn), có các giải pháp
  sau:
  ──────
  ### Giải pháp 1: Liên kết tĩnh (Static Linking) — Bản chất  
  tệp đầu ra đã ĐỘC LẬP

  Khi mày chạy lệnh compile có chứa tệp static library  .a :

    clang-21 obfuscated.ll
  dependency/mcsema/mcsema/lib/libmcsema_rt64-10.0.a ...      

  Trình biên dịch sẽ sao chép toàn bộ mã nguồn cần thiết từ   
  file  .a  và nhúng thẳng vào trong tệp thực thi đầu ra ( out
  ).

  • Kết quả: Tệp thực thi  out  sau khi build xong là hoàn    
  toàn độc lập. Mày có thể copy file  out  này sang bất kỳ máy
  Linux nào khác và chạy bình thường mà không cần mang theo
  tệp  libmcsema_rt64-10.0.a  nữa.
  ──────
  ### Giải pháp 2: Sử dụng các Pass tối ưu hóa của LLVM (Làm  
  sạch mã nguồn IR)

  Nếu mày muốn mã IR trong tệp  .ll  sạch hơn, không bị ngập
  tràn các lệnh truy xuất thanh ghi ảo ( State.gpr.rax ...),
  mày có thể chạy các Pass tối ưu hóa của LLVM như  mem2reg 
  (Memory to Register) hoặc  sroa  để biến đổi các biến cấu
  trúc CPU ảo thành các thanh ghi SSA chuẩn của LLVM.

  • Cách làm: Sử dụng công cụ tối ưu hóa  opt :
    opt-21 -passes=mem2reg,sroa result/hash/obfuscated.bc -o  
  result/hash/obfuscated_clean.bc
    llvm-dis-21 result/hash/obfuscated_clean.bc -o            
  result/hash/obfuscated_clean.ll

  • Kết quả: Tệp  .ll  mới sẽ cực kỳ gọn gàng và giống mã
  nguồn viết tay hơn, tuy nhiên mày vẫn cần link thư viện
  runtime ở bước dịch ra binary vì các điểm khởi đầu (        
  __mcsema_attach_call ) vẫn cần thiết để kích hoạt chương
  trình.
  ──────
  ### Giải pháp 3: Dịch ngược ra ngôn ngữ C (Decompilation)

  Nếu dự án của mày hoàn toàn không muốn phụ thuộc vào bất kỳ
  thư viện giả lập nào và muốn có mã nguồn độc lập thực sự:

  • Mày nên sử dụng trình dịch ngược mã nguồn như Decompiler  
  của Ghidra hoặc Hex-Rays Decompiler của IDA Pro để xuất trực
  tiếp mã máy thành mã nguồn C.
  • Mã nguồn C sử dụng các biến cục bộ/toàn cục chuẩn nên có
  thể biên dịch bằng  gcc  hay  clang  thông thường mà không
  cần bất kỳ thư viện runtime đặc biệt nào.


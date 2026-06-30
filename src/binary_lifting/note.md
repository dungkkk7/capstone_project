# Binary lifting with revng

Pipeline hiện tại dùng revng thay cho MC-Sema.

Luồng xử lý:

1. `revng2 project init <binary>` tạo project và `model.yml`.
2. `revng2 project artifact lift` sinh artifact LLVM bitcode.
3. Script decode payload artifact của revng ra `.bc`.
4. `llvm-dis-21` hoặc `llvm-dis` sinh `.ll`.

Mặc định script tìm revng tại:

```sh
dependency/revng/root
```

Trong workspace này path đó chứa trực tiếp build revng từ orchestra.

```sh
python3 src/binary_lifting/lifting.py -b data/obfuscated/hash/obfuscated.bin
```

Có thể override bằng biến môi trường:

```sh
REVNG_ROOT=/path/to/orchestra/root python3 src/binary_lifting/lifting.py -b data/obfuscated/hash/obfuscated.bin
```

#include <stdint.h>
#include <stdio.h>

extern int32_t parity_i8_not(int8_t);
extern int32_t parity_i32_next(int32_t);
extern int64_t parity_i64_integer(int64_t);

int main(void) {
  for (unsigned x = 0; x != 256; ++x) {
    int8_t v = (int8_t)x;
    if (parity_i8_not(v) != 1) return 1;
    if (parity_i32_next((int32_t)v) != 1) return 2;
    if (parity_i64_integer((int64_t)v) != 0) return 3;
  }
  puts("parity truth table passed");
  return 0;
}

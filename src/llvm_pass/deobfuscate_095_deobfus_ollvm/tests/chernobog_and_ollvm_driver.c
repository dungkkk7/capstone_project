#include <stdint.h>

uint8_t r1_i8(uint8_t, uint8_t), r2_i8(uint8_t, uint8_t), r3_i8(uint8_t, uint8_t);
uint32_t r1_i32(uint32_t, uint32_t), r2_i32(uint32_t, uint32_t), r3_i32(uint32_t, uint32_t);
uint64_t r1_i64(uint64_t, uint64_t), r2_i64(uint64_t, uint64_t), r3_i64(uint64_t, uint64_t);
uint8_t opaque_source(void) { return 0; }

int main(void) {
  for (unsigned x = 0; x != 256; ++x)
    for (unsigned y = 0; y != 256; ++y)
      if (r1_i8(x, y) != (uint8_t)(x & y) ||
          r2_i8(x, y) != (uint8_t)(x & y) ||
          r3_i8(x, y) != (uint8_t)(x & y)) return 1;
  uint32_t a = 0xf0000001u, b = 0x7fffffffu;
  if (r1_i32(a,b) != (a&b) || r2_i32(a,b) != (a&b) || r3_i32(a,b) != (a&b)) return 2;
  uint64_t c = UINT64_C(0xf000000000000001), d = UINT64_C(0x7fffffffffffffff);
  if (r1_i64(c,d) != (c&d) || r2_i64(c,d) != (c&d) || r3_i64(c,d) != (c&d)) return 3;
  return 0;
}

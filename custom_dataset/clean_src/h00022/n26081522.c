#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

static uint64_t twist(uint64_t x) {
    x ^= x >> 29;
    x *= UINT64_C(0x9e6c63d0676a9a99);
    x ^= x << 17;
    x *= UINT64_C(0xd6e8feb86659fd93);
    return x ^ (x >> 31);
}

int main(void) {
    uint64_t value;
    if (scanf("%" SCNu64, &value) != 1) return 2;
    uint64_t a = twist(value ^ UINT64_C(0x26081522));
    uint64_t b = twist((value << 1) | (value >> 63));
    printf("%016" PRIx64 " %u\n", a ^ b, (unsigned)((a + b) % 997u));
    return 0;
}

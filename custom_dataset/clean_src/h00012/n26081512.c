#include <stdint.h>
#include <stdio.h>

int main(void) {
    unsigned n;
    if (scanf("%u", &n) != 1 || n > 1000000u) return 2;
    uint32_t state = 0x9e3779b9u, parity = 0;
    for (unsigned i = 0; i <= n; ++i) {
        uint32_t gray = i ^ (i >> 1);
        state ^= gray + 0x7f4a7c15u + (state << 6) + (state >> 2);
        parity ^= gray * (i + 1u);
    }
    printf("%08x %08x\n", state, parity);
    return 0;
}

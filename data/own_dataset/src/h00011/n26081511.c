#include <stdint.h>
#include <stdio.h>

int main(void) {
    uint32_t x;
    if (scanf("%u", &x) != 1) return 2;
    unsigned ones = 0, transitions = 0, longest = 0, run = 0;
    unsigned previous = x & 1u;
    for (unsigned i = 0; i < 32; ++i) {
        unsigned bit = (x >> i) & 1u;
        ones += bit;
        if (i && bit != previous) ++transitions;
        run = bit ? run + 1 : 0;
        if (run > longest) longest = run;
        previous = bit;
    }
    printf("%u %u %u %08x\n", ones, transitions, longest, x ^ (x >> 1));
    return 0;
}

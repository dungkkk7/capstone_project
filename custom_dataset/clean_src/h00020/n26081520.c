#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n;
    if (scanf("%d", &n) != 1 || n < 1 || n > 100) return 2;
    uint32_t state = 7, visits[8] = {0};
    for (int i = 0; i < n; ++i) {
        int value;
        if (scanf("%d", &value) != 1) return 3;
        uint32_t cls = (uint32_t)((value % 8 + 8) % 8);
        state = (state * 5u + cls * 3u + (uint32_t)i) & 7u;
        if (((value ^ i) & 1) != 0) state ^= 3u;
        ++visits[state];
    }
    uint32_t fingerprint = 0;
    for (unsigned i = 0; i < 8; ++i) fingerprint = fingerprint * 17u + visits[i] * (i + 1u);
    printf("%u %u", state, fingerprint);
    for (unsigned i = 0; i < 8; ++i) printf(" %u", visits[i]);
    putchar('\n');
    return 0;
}

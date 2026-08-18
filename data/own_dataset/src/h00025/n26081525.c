#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n;
    if (scanf("%d", &n) != 1 || n < 1 || n > 64) return 2;
    uint64_t score = 0;
    unsigned buckets[3] = {0, 0, 0};
    for (int i = 0; i < n; ++i) {
        uint64_t x;
        if (scanf("%" SCNu64, &x) != 1) return 3;
        unsigned steps = 0;
        while (x > 1 && steps < 12) {
            x = (x & 1u) ? (x * 3u + 1u) : (x >> 1);
            steps++;
        }
        buckets[steps % 3u]++;
        score ^= (x + UINT64_C(0x25a7) * (unsigned)(i + 1)) << (steps % 13u);
    }
    printf("%" PRIu64 " %u/%u/%u\n", score, buckets[0], buckets[1], buckets[2]);
    return 0;
}

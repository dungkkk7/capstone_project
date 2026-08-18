#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n;
    if (scanf("%d", &n) != 1 || n < 1 || n > 64) return 2;
    int64_t acc = 41, lo = INT64_MAX, hi = INT64_MIN;
    for (int i = 0; i < n; ++i) {
        int64_t x;
        if (scanf("%" SCNd64, &x) != 1) return 3;
        if (x < lo) lo = x;
        if (x > hi) hi = x;
        int64_t term = (x * (i + 3)) ^ (int64_t)(0x5a5a + 17 * i);
        acc = (acc * 97 + term) % 1000000007;
        if (acc < 0) acc += 1000000007;
    }
    printf("%" PRId64 " %" PRId64 " %" PRId64 "\n", acc, lo, hi);
    return 0;
}

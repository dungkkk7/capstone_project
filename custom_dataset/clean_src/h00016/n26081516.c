#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n;
    int64_t values[64];
    if (scanf("%d", &n) != 1 || n < 1 || n > 64) return 2;
    for (int i = 0; i < n; ++i) if (scanf("%" SCNd64, &values[i]) != 1) return 3;
    uint64_t signature = 1469598103934665603ull;
    int negative = 0, nonnegative = 0;
    for (int phase = 0; phase < 2; ++phase) {
        for (int i = 0; i < n; ++i) {
            if ((values[i] < 0) != (phase == 0)) continue;
            if (values[i] < 0) ++negative; else ++nonnegative;
            signature ^= (uint64_t)values[i] + (uint64_t)(i * 131 + phase * 17);
            signature *= 1099511628211ull;
        }
    }
    printf("%d %d %016" PRIx64 "\n", negative, nonnegative, signature);
    return 0;
}

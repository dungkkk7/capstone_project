#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n;
    if (scanf("%d", &n) != 1 || n < 2 || n > 80) return 2;
    int64_t first, prev, score = 0, turns = 0;
    if (scanf("%" SCNd64, &first) != 1) return 3;
    prev = first;
    int sign = 0;
    for (int i = 1; i < n; ++i) {
        int64_t cur;
        if (scanf("%" SCNd64, &cur) != 1) return 3;
        int64_t delta = cur - prev;
        int next_sign = (delta > 0) - (delta < 0);
        if (sign && next_sign && sign != next_sign) ++turns;
        if (next_sign) sign = next_sign;
        score += (delta < 0 ? -delta : delta) * (i + 1);
        prev = cur;
    }
    printf("%" PRId64 " %" PRId64 " %" PRId64 "\n", score, turns, prev - first);
    return 0;
}

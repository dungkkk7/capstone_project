#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n, width;
    int64_t a[80];
    if (scanf("%d%d", &n, &width) != 2 || n < 1 || n > 80 || width < 1 || width > n) return 2;
    for (int i = 0; i < n; ++i) if (scanf("%" SCNd64, &a[i]) != 1) return 3;
    int64_t sum = 0, best = INT64_MIN, worst = INT64_MAX;
    int best_at = 0;
    for (int i = 0; i < n; ++i) {
        sum += a[i];
        if (i >= width) sum -= a[i - width];
        if (i + 1 >= width) {
            if (sum > best) { best = sum; best_at = i + 1 - width; }
            if (sum < worst) worst = sum;
        }
    }
    printf("%" PRId64 " %d %" PRId64 "\n", best, best_at, worst);
    return 0;
}

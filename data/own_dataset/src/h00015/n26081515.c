#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n;
    if (scanf("%d", &n) != 1 || n < 1 || n > 32) return 2;
    int64_t coeff[32];
    for (int i = 0; i < n; ++i) if (scanf("%" SCNd64, &coeff[i]) != 1) return 3;
    int64_t at2 = 0, atm3 = 0;
    for (int i = n - 1; i >= 0; --i) {
        at2 = (at2 * 2 + coeff[i]) % 1000003;
        atm3 = (atm3 * -3 + coeff[i]) % 1000033;
    }
    if (at2 < 0) at2 += 1000003;
    if (atm3 < 0) atm3 += 1000033;
    printf("%" PRId64 " %" PRId64 "\n", at2, atm3);
    return 0;
}

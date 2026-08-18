#include <stdio.h>

int main(void) {
    int n;
    long values[80];
    if (scanf("%d", &n) != 1 || n < 2 || n > 80) return 2;
    for (int i = 0; i < n; ++i) if (scanf("%ld", &values[i]) != 1) return 3;
    int best = 1, current = 1;
    long signature = 0;
    for (int i = 1; i < n; ++i) {
        if (((values[i] ^ values[i - 1]) & 1L) != 0) current++;
        else current = 1;
        if (current > best) best = current;
        signature = (signature * 131L + values[i] - values[i - 1]) % 1000003L;
    }
    long peak = values[0] + values[1];
    for (int i = 2; i < n; ++i) {
        long window = values[i] + values[i - 1] + values[i - 2];
        if (window > peak) peak = window;
    }
    printf("zig=%d peak=%ld sig=%ld\n", best, peak, signature);
    return 0;
}

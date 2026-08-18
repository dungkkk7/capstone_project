#include <stdio.h>

static int leap(int year) { return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0); }
static long ordinal(int y, int m, int d) {
    static const int before[] = {0,0,31,59,90,120,151,181,212,243,273,304,334};
    return 365L * (y - 1) + (y - 1) / 4 - (y - 1) / 100 + (y - 1) / 400 + before[m] + d + (m > 2 && leap(y));
}

int main(void) {
    long values[3];
    for (int i = 0; i < 3; ++i) {
        int y, m, d;
        if (scanf("%d%d%d", &y, &m, &d) != 3 || y < 1600 || y > 2600 || m < 1 || m > 12 || d < 1 || d > 31) return 2;
        values[i] = ordinal(y, m, d);
    }
    long span = values[2] - values[0], gap = values[1] - values[0];
    printf("span=%ld pivot=%ld code=%ld\n", span, gap, (values[0] ^ values[1] ^ values[2]) % 100003L);
    return 0;
}

#include <stdio.h>

static int leap(int year) { return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0); }
int main(void) {
    int year, month, day;
    static const int days[] = {0,31,28,31,30,31,30,31,31,30,31,30,31};
    if (scanf("%d%d%d", &year, &month, &day) != 3 || year < 1600 || year > 2600 || month < 1 || month > 12) return 2;
    int limit = days[month] + (month == 2 && leap(year));
    if (day < 1 || day > limit) return 3;
    int ordinal = day;
    for (int m = 1; m < month; ++m) ordinal += days[m] + (m == 2 && leap(year));
    int code = (year * 37 + ordinal * 19 + month * month) % 10007;
    printf("%03d %04d %s\n", ordinal, code, leap(year) ? "L" : "N");
    return 0;
}

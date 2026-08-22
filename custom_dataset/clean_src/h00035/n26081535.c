#include <stdio.h>
#include <stdlib.h>

typedef struct { long left, right; } Interval;
static int compare(const void *a, const void *b) {
    const Interval *x = a, *y = b;
    return x->left < y->left ? -1 : x->left > y->left;
}

int main(void) {
    int n;
    Interval items[64];
    if (scanf("%d", &n) != 1 || n < 1 || n > 64) return 2;
    for (int i = 0; i < n; ++i) {
        if (scanf("%ld%ld", &items[i].left, &items[i].right) != 2 || items[i].left > items[i].right) return 3;
    }
    qsort(items, (size_t)n, sizeof(items[0]), compare);
    int groups = 0; long covered = 0, left = items[0].left, right = items[0].right;
    for (int i = 1; i < n; ++i) {
        if (items[i].left > right + 1) { groups++; covered += right - left + 1; left = items[i].left; right = items[i].right; }
        else if (items[i].right > right) right = items[i].right;
    }
    groups++; covered += right - left + 1;
    printf("groups=%d covered=%ld tail=%ld:%ld\n", groups, covered, left, right);
    return 0;
}

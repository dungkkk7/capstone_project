#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct { int64_t lo, hi; } Span;
static int compare(const void *a, const void *b) {
    const Span *x = a, *y = b;
    return (x->lo > y->lo) - (x->lo < y->lo);
}
int main(void) {
    int n;
    Span spans[40];
    if (scanf("%d", &n) != 1 || n < 1 || n > 40) return 2;
    for (int i = 0; i < n; ++i) {
        if (scanf("%" SCNd64 "%" SCNd64, &spans[i].lo, &spans[i].hi) != 2) return 3;
        if (spans[i].lo > spans[i].hi) { int64_t t = spans[i].lo; spans[i].lo = spans[i].hi; spans[i].hi = t; }
    }
    qsort(spans, (size_t)n, sizeof(spans[0]), compare);
    int groups = 1;
    int64_t lo = spans[0].lo, hi = spans[0].hi, covered = 0, gap = 0;
    for (int i = 1; i < n; ++i) {
        if (spans[i].lo <= hi + 1) { if (spans[i].hi > hi) hi = spans[i].hi; }
        else { covered += hi - lo + 1; gap += spans[i].lo - hi - 1; lo = spans[i].lo; hi = spans[i].hi; ++groups; }
    }
    covered += hi - lo + 1;
    printf("%d %" PRId64 " %" PRId64 "\n", groups, covered, gap);
    return 0;
}

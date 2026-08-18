#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

struct Element {
    int64_t x;
    int64_t y;
};

int compare(const void *a, const void *b) {
    int64_t ax = ((const struct Element*)a)->x;
    int64_t bx = ((const struct Element*)b)->x;
    if (ax < bx) return -1;
    if (ax > bx) return 1;
    return 0;
}

int main(void) {
    int n;
    if (scanf("%d", &n) != 1) {
        return 2;
    }
    if (n < 1 || n > 64) {
        return 2;
    }
    struct Element arr[64];
    for (int i = 0; i < n; i++) {
        if (scanf("%ld%ld", &arr[i].x, &arr[i].y) != 2) {
            return 3;
        }
        if (arr[i].x > arr[i].y) {
            return 3;
        }
    }

    qsort(arr, n, sizeof(struct Element), compare);

    int groups = 0;
    int64_t covered = 0;
    int64_t tail_x = arr[0].x;
    int64_t tail_y = arr[0].y;

    for (int i = 1; i < n; i++) {
        if (arr[i].x > tail_y + 1) {
            groups++;
            covered += (tail_y - tail_x + 1);
            tail_x = arr[i].x;
            tail_y = arr[i].y;
        } else {
            if (arr[i].y > tail_y) {
                tail_y = arr[i].y;
            }
        }
    }
    groups++;
    covered += (tail_y - tail_x + 1);

    printf("groups=%d covered=%ld tail=%ld:%ld\n", groups, covered, tail_x, tail_y);
    return 0;
}

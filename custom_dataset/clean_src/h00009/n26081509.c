#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    int rows, cols;
    if (scanf("%d%d", &rows, &cols) != 2 || rows < 1 || rows > 12 || cols < 1 || cols > 12) return 2;
    int64_t border = 0, checker = 0, diagonal = 0;
    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c) {
            int64_t x;
            if (scanf("%" SCNd64, &x) != 1) return 3;
            if (r == 0 || c == 0 || r == rows - 1 || c == cols - 1) border += x;
            checker += ((r + c) & 1) ? -x : x;
            if (r == c || r + c == cols - 1) diagonal += x;
        }
    }
    printf("%" PRId64 " %" PRId64 " %" PRId64 "\n", border, checker, diagonal);
    return 0;
}

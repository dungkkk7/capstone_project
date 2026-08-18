#include <stdio.h>

int main(void) {
    int n, m, q, d[12][12];
    if (scanf("%d%d%d", &n, &m, &q) != 3 || n < 1 || n > 12 || m < 0 || m > 80 || q < 0 || q > 20) return 2;
    for (int i = 0; i < n; ++i) for (int j = 0; j < n; ++j) d[i][j] = i == j ? 0 : 1000000;
    for (int i = 0; i < m; ++i) {
        int a, b, w;
        if (scanf("%d%d%d", &a, &b, &w) != 3 || a < 0 || b < 0 || a >= n || b >= n || w < 0) return 3;
        if (w < d[a][b]) d[a][b] = w;
    }
    for (int k = 0; k < n; ++k) for (int i = 0; i < n; ++i) for (int j = 0; j < n; ++j)
        if (d[i][k] + d[k][j] < d[i][j]) d[i][j] = d[i][k] + d[k][j];
    long total = 0;
    for (int i = 0; i < q; ++i) {
        int a, b;
        if (scanf("%d%d", &a, &b) != 2 || a < 0 || b < 0 || a >= n || b >= n) return 4;
        total += d[a][b] == 1000000 ? -1 : d[a][b];
    }
    printf("total=%ld diag=%d\n", total, d[0][n - 1] == 1000000 ? -1 : d[0][n - 1]);
    return 0;
}

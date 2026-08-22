#include <stdio.h>

int main(void) {
    int n, m, edge[20][20] = {{0}}, degree[20] = {0}, order[20];
    if (scanf("%d%d", &n, &m) != 2 || n < 1 || n > 20 || m < 0 || m > 100) return 2;
    for (int i = 0; i < m; ++i) {
        int a, b;
        if (scanf("%d%d", &a, &b) != 2 || a < 0 || b < 0 || a >= n || b >= n) return 3;
        if (!edge[a][b]) { edge[a][b] = 1; degree[b]++; }
    }
    int count = 0;
    while (count < n) {
        int chosen = -1;
        for (int i = 0; i < n; ++i) if (degree[i] == 0) { chosen = i; break; }
        if (chosen < 0) break;
        order[count++] = chosen;
        degree[chosen] = -1;
        for (int j = 0; j < n; ++j) if (edge[chosen][j]) degree[j]--;
    }
    if (count != n) printf("cycle:%d\n", n - count);
    else {
        int hash = 0;
        for (int i = 0; i < n; ++i) hash = hash * 37 + order[i] + 11;
        printf("dag:%d:%d\n", count, hash);
    }
    return 0;
}

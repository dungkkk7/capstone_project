#include <stdio.h>

int main(void) {
    int n, m, start, goal;
    int graph[16][16] = {{0}}, queue[16], distance[16];
    if (scanf("%d%d%d%d", &n, &m, &start, &goal) != 4 || n < 1 || n > 16 || m < 0 || m > 80) return 2;
    for (int i = 0; i < n; ++i) distance[i] = -1;
    for (int i = 0; i < m; ++i) {
        int a, b;
        if (scanf("%d%d", &a, &b) != 2 || a < 0 || b < 0 || a >= n || b >= n) return 3;
        graph[a][b] = graph[b][a] = 1;
    }
    if (start < 0 || goal < 0 || start >= n || goal >= n) return 4;
    int head = 0, tail = 0;
    queue[tail++] = start;
    distance[start] = 0;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < n; ++v) if (graph[u][v] && distance[v] < 0) {
            distance[v] = distance[u] + 1;
            queue[tail++] = v;
        }
    }
    int signature = 0;
    for (int i = 0; i < n; ++i) signature = signature * 31 + distance[i] + 2;
    printf("dist=%d sig=%d\n", distance[goal], signature);
    return 0;
}

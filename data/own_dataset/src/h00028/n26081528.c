#include <stdio.h>

int main(void) {
    int rows, cols, qr[144], qc[144], dist[12][12];
    char grid[12][13];
    if (scanf("%d%d", &rows, &cols) != 2 || rows < 1 || rows > 12 || cols < 1 || cols > 12) return 2;
    int sr = -1, sc = -1, tr = -1, tc = -1;
    for (int r = 0; r < rows; ++r) {
        if (scanf("%12s", grid[r]) != 1) return 3;
        for (int c = 0; c < cols; ++c) {
            dist[r][c] = -1;
            if (grid[r][c] == 'S') { sr = r; sc = c; }
            if (grid[r][c] == 'T') { tr = r; tc = c; }
        }
    }
    if (sr < 0 || tr < 0) return 4;
    int head = 0, tail = 0, dr[4] = {-1, 1, 0, 0}, dc[4] = {0, 0, -1, 1};
    qr[tail] = sr; qc[tail++] = sc; dist[sr][sc] = 0;
    while (head < tail) {
        int r = qr[head], c = qc[head++];
        for (int k = 0; k < 4; ++k) {
            int nr = r + dr[k], nc = c + dc[k];
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc] != '#' && dist[nr][nc] < 0) {
                dist[nr][nc] = dist[r][c] + 1; qr[tail] = nr; qc[tail++] = nc;
            }
        }
    }
    printf("route=%d visited=%d\n", dist[tr][tc], tail);
    return 0;
}

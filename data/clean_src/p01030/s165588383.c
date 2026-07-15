// AOJ 1543 Changing Grids
// 2019.2.27 bal4u

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INF 0x30303030
int H, W, N;
char map[17][22][22];
int T[17];
int mv[4][2] = { {-1,0},{1,0},{0,-1},{0,1} };
int SR, SC, GR, GC;  // start, goal
int visited[22][22];
int ans;

#define QMAX 10000000
typedef struct { char r, c; int t, s; } Q;
Q q[QMAX + 2]; int top, end;

// 幅優先探索
int bfs(int id)
{
	int i, r, c, t, s, rr, cc;
	int tmax;

	top = end = 0;
	for (r = 0; r < H; r++) for (c = 0; c < W; c++) {
		if (map[id][r][c] == '#') visited[r][c] = INF;
		else if (visited[r][c] < INF) {
			q[end].r = r, q[end].c = c;
			q[end].t = T[id], q[end].s = visited[r][c];
			end++;
		}
	}
	tmax = T[id + 1];

	/*
	printf("id=%d, tmax=%d\n", id, tmax);
	for (r = 0; r < H; r++) {
		for (c = 0; c < W; c++) {
			if (visited[r][c] == INF) printf("-1 ");
			else printf("%2d ", visited[r][c]);
		}
		printf("\n");
	}
	*/

	while (top != end) {
		r = q[top].r, c = q[top].c, t = q[top].t, s = q[top].s;
		if (++top == QMAX) top = 0;
		if (r == GR && c == GC) {
			if (ans < 0 || s < ans) ans = s;
			continue;
		}
//		if (t >= tmax) continue;

		t++, s++;
		// 上下左右に移動
		for (i = 0; i < 4; i++) {
			rr = r + mv[i][0], cc = c + mv[i][1];
			if (rr < 0 || rr >= H || cc < 0 || cc >= W) continue;
			if (map[id][rr][cc] == '.') {
				if (t < tmax && s < visited[rr][cc]) {
					visited[rr][cc] = s;
					q[end].r = rr, q[end].c = cc, q[end].t = t, q[end].s = s;
					if (++end == QMAX) end = 0;
				}
			}
			if (map[id+1][rr][cc] == '.') {
				if (s < visited[rr][cc]) visited[rr][cc] = s;
			}
		}
	}
	return -1;
}

int main()
{
	int i, f, r, c;

	memset(visited, INF, sizeof(visited));  // 初期化

	// 入力処理
	scanf("%d%d", &H, &W);
	for (r = 0; r < H; r++) {
		scanf("%s", map[0][r]);
		for (c = 0; c < W; c++) {
			if (map[0][r][c] == 'S') SR = r, SC = c, map[0][r][c] = '.';
			else if (map[0][r][c] == 'G') GR = r, GC = c, map[0][r][c] = '.';
		}
	}
	scanf("%d", &N);
	T[N+1] = INF;

	for (i = 1; i <= N; i++) {
		scanf("%d", T + i);
		f = 0;    // すべてが'"'か
		for (r = 0; r < H; r++) {
			scanf("%s", map[i][r]);
			if (!f) for (c = 0; c < W; c++) if (map[i][r][c] == '.') f = 1;
		}
		if (!f) { N = i - 1; break; }
	}
	while (N > 0) {
		if (map[N][GR][GC] == '.') break;
		N--;
	}

	ans = -1;
	visited[SR][SC] = 0;
	for (i = 0; ; i++) {
		if (i > N) break;
		bfs(i);
	}
	printf("%d\n", ans);
	return 0;
}

// AOJ 1038 Dr. Nakamura's Lab.
// 2019.4.3 bal4u

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char uchar;
typedef struct { uchar pos[7]; int step; } Q;
Q que[250000]; int top, end;
char encode[128];

char map[12][12]; int H, W;
int mv[4][2] = { {-1,0}, {0,1}, {1,0}, {0,-1} };

// 数値のハッシュ関数
#define HASHSIZ 2000081
long long hash[HASHSIZ + 5], *hashend = hash + HASHSIZ;

int insert(uchar *pos)
{
	int i;
	long long x;
	long long *p;

	x = 0; for (i = 0; i < 7; i++) x = (x << 8) | pos[i];
	p = hash + (int)(x % HASHSIZ);
	while (*p) {
		if (*p == x) return 0;
		if (++p == hashend) p = hash;
	}
	*p = x;
	return 1;
}

int bfs(uchar goal, uchar *init)
{
	int i, j, r, c, nr, nc, ic, step;
	uchar pos[7], npos[7], np;

	top = 0, end = 1;
	memcpy(que[0].pos, init, 7), que[0].step = 0;
	while (top != end) {
		memcpy(pos, que[top].pos, 7), step = que[top].step, top++;
		if (pos[0] == goal) return step;

		if (!insert(pos)) continue;   // 同一状態がすでにあった

		r = pos[0] >> 4, c = pos[0] & 0xf;
		for (i = 0; i < 4; i++) {
			memcpy(npos, pos, 7);
			nr = r + mv[i][0], nc = c + mv[i][1], np = (nr << 4) | nc;
			if (map[nr][nc] == '#') continue;
			if (pos[1] == np || pos[2] == np || pos[3] == np) continue;
			for (ic = 4; ic < 7; ic++) if (pos[ic] == np) break;
			if (ic < 7) {  // 移動先がコンテナ
				uchar cr = nr + mv[i][0], cc = nc + mv[i][1];
				uchar cp0 = np, cp = (cr << 4) | cc;
				if (map[cr][cc] == '#') continue;    // コンテナの先が壁か別のコンテナ？
				if (pos[4] == cp || pos[5] == cp || pos[6] == cp) continue;

				while (1) {
					for (j = 1; j < 7; j++) if (pos[j] == cp) break;
					if (j < 7) break;
					cr += mv[i][0], cc += mv[i][1], cp0 = cp, cp = (cr << 4) | cc; // 移動し続ける
					if (map[cr][cc] != '.') break;
				}
				if (j < 4) npos[j] = npos[ic] = 0;    // コンテナとパネルが消滅
				else npos[ic] = cp0;
				que[end].step = step;
			}
			else npos[0] = np, que[end].step = step + 1;
			memcpy(que[end].pos, npos, 7);
			end++;
		}
	}
	return -1;
}

int main()
{
	int k, r, c, nc, np;
	uchar goal, pos[7], p;

	memset(encode, -1, sizeof(encode));
	encode['@'] = 0, encode['w'] = 1, encode['c'] = 4, encode['E'] = 10;
	while (scanf("%d%d", &H, &W) && H) {
		memset(hash, 0, sizeof(hash));
		memset(pos, 0, 7);
		np = nc = 0;
		for (r = 0; r < H; r++) {
			scanf("%s", map[r]);
			for (c = 0; c < W; c++) {
				if ((k = encode[map[r][c]]) < 0) continue;
				p = (r << 4) | c;
				if (k == 0) pos[k] = p;              // Dr.中村 
				else if (k < 4) pos[k + np++] = p;   // パネル
				else if (k < 7) pos[k + nc++] = p;   // コンテナ
				else goal = p;                       // 出口
				map[r][c] = '.';
			}
		}
		printf("%d\n", bfs(goal, pos));
	}
	return 0;
}

// AOJ 2178 Futon
// 2018.3.17 bal4u

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 数値入力
#if 1
#define gc() getchar_unlocked()
#else
#define gc() getchar()
#endif
int in()  // 非負整数
{
	int n = 0, c = gc();
	do n = 10 * n + (c & 0xf), c = gc(); while (c >= '0');
	return n;
}


// ハッシュテーブル
#define HASHSIZ 299993
typedef struct { long long xy; int id; } HASH;
HASH hash[HASHSIZ + 5], *hashend = hash + HASHSIZ;
int hashcnt;
int lookup(int x, int y)  // (x,y)からidを得る
{
	long long k;
	HASH *p;
	if (x < 0 || y < 0) return -1;
	k = ((long long)(++x) << 31) | (++y);
	p = hash + (int)(k % HASHSIZ);
	while (p->xy) {
		if (p->xy == k) return p->id;
		if (++p == hashend) p = hash;
		hashcnt++;
	}
	return -1;
}

void insert(int x, int y, int id)  // (x,y)とid を記録する
{
	long long k = ((long long)(++x) << 31) | (++y);
	HASH *p = hash + (int)(k % HASHSIZ);
//printf("insert xy (%d,%d) id=%d\n", x - 1, y - 1, id);
	while (p->xy) {
		if (++p == hashend) p = hash;
	}
	p->xy = k, p->id = id;
}


/* UNION-FIND library */
#define MAX 40050
int id[MAX], size[MAX];
void init(int n) { int i; for (i = 0; i < n; i++) id[i] = i, size[i] = 1; }
int root(int i) { while (i != id[i]) id[i] = id[id[i]], i = id[i]; return i; }
int connected(int p, int q) { return root(p) == root(q); }
void unite(int p, int q)
{
	int i = root(p), j = root(q); if (i == j) return;
	if (size[i] < size[j]) id[i] = j, size[j] += size[i]; else id[j] = i, size[i] += size[j];
}

typedef struct { int id, f; } Q;
Q q[MAX]; int top, end;
int N, N2;                 // N2 = 2*N
int hi[MAX], *group[MAX];
char flg[MAX];             // すべてのidペアは0か1に矛盾なく帰着できるか

int bfs(int k, int f)
{
	int i, g, x, y;

	q[0].id = k, q[0].f = f, top = 0, end = 1;
	while (top != end) {
		k = q[top].id, f = q[top].f, ++top;
		g = id[k]; for (i = 0; i < hi[g]; i++) {
			x = group[g][i];
			if (flg[x] < 0) flg[x] = f;
			else if (flg[x] != f) return 0;
			y = (x & 1) ? x - 1 : x + 1;
			if (flg[y] < 0) q[end].id = y, q[end].f = !f, ++end;
		}
	}
	return 1;
}

int main()
{
	int i, j, k, x, y, d, t;

	while (N = in()) {
		N2 = N << 1;
		init(N2);     // Union Setの初期化
		memset(hash, 0, sizeof(hash));     // ハッシュテーブルの初期化
		for (i = 0; i < N; i++) {
			x = in(), y = in(), d = gc(), gc();

			k = i << 1;
			if (d == 'x') {
				for (j = -1; j <= 1; j+=2) {
					insert(x, y, k);
					if ((t = lookup(x, y - 1)) >= 0) unite(t, k);
					if ((t = lookup(x + j, y)) >= 0) unite(t, k);
					if ((t = lookup(x, y + 1)) >= 0) unite(t, k);
					k++, x++;
				}
			}
			else {
				for (j = -1; j <= 1; j+=2) {
					insert(x, y, k);
					if ((t = lookup(x - 1, y)) >= 0) unite(t, k);
					if ((t = lookup(x, y + j)) >= 0) unite(t, k);
					if ((t = lookup(x + 1, y)) >= 0) unite(t, k);
					k++, y++;
				}
			}
		}

		memset(hi, 0, N2*sizeof(int));
		for (i = 0; i < N2; i += 2) {
			int x = root(i), y = root(i + 1);
			if (x == y) goto No;
			hi[x]++, hi[y]++;
		}
		for (i = 0; i < N2; i++) if (hi[i] > 0) group[i] = malloc(hi[i] * sizeof(int));
		memset(hi, 0, N2*sizeof(int));
		for (i = 0; i < N2; i++) group[id[i]][hi[id[i]]++] = i;
		
		memset(flg, -1, N2*sizeof(char));
		for (i = 0; i < N2; i++) if (flg[i] < 0) {
			if (!(t = bfs(i, 0))) break;
		}
		for (i = 0; i < N2; i++) if (hi[i] > 0) free(group[i]);

		if (t) {
			for (i = 0; i < N2; i += 2) if (flg[i] == flg[i + 1]) goto No;
			puts("Yes");
		}
		else {
No:			puts("No");
		}
	}
	return 0;
}

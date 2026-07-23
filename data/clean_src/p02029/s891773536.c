// AOJ 2929 Chisaki and Picnic
// 2019.4.6 bal4u

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

//// 高速入力
#if 1
#define gc() getchar_unlocked()
#else
#define gc() getchar()
#endif
int in()
{
	int n = 0, c = gc();
	while (isspace(c)) c = gc();
	do n = 10 * n + (c & 0xf), c = gc(); while (c >= '0');
	return n;
}


//// 優先度付きキュー（降順用）
#define QSIZE 110000
#define PARENT(i) ((i)>>1)
#define LEFT(i)   ((i)<<1)
#define RIGHT(i)  (((i)<<1)+1)

typedef int QUE;
QUE que[QSIZE + 5];
int qsize;

void max_heapify(int i)
{
	int max, l = LEFT(i), r = RIGHT(i);
	if (l < qsize && que[l] > que[i]) max = l; else max = i;
	if (r < qsize && que[r] > que[max]) max = r;
	if (max != i) {
		QUE qt = que[i]; que[i] = que[max], que[max] = qt;
		max_heapify(max);
	}
}

void deq()
{
	que[0] = que[--qsize];
	max_heapify(0);
}

void enq(int t)
{
	int max, i = qsize++;
	que[i] = t;
	while (i > 0 && que[max = PARENT(i)] < que[i]) {
		QUE qt = que[i]; que[i] = que[max], que[max] = qt;
		i = max;
	}
}


//// 本問題関連
#define INF 1000000005
#define MAX 100005
int N, M;
int a[MAX], b[MAX];
int c[MAX], d[MAX];

int upper_bound(int l, int x)
{
	int m, r = N;
	while (l < r) {
		m = (l + r) >> 1;
		if (a[m] <= x) l = m + 1; else r = m;
	}
	return l - 1;
}

int main()
{
	int i, j, k, n, lim;
	long long ans;

	N = in(), M = in();
	for (i = 0; i < N; i++) a[i] = in(), b[i] = in();
	c[0] = in(), d[0] = lim = in(), i = 0;
	while (lim > 1 && --M) {
		k = in(), lim = in();
		if (lim >= d[i]) continue;
		if (k > c[i]) c[++i] = k;
		d[i] = lim;
	}
	if (lim == 1) N = upper_bound(0, c[i--] - 1) + 1;
	M = i + 1, c[M] = INF, d[M] = 1;

	ans = 0; a[N] = INF + 5;  // 番兵
	for (i = 0; a[i] < c[0]; i++) ans += b[i];  // 嫌われるほど、価値のないお菓子を積算

	qsize = 0, lim = d[0];
	for (j = 1; i < N && j <= M; j++) {
		if (j == M) k = N - 1;
		else k = upper_bound(i, c[j] - 1);  // c[j]より価値の高くないお菓子
		while (i <= k) enq(b[i++]);
		n = lim - d[j], lim = d[j];
		while (n-- && qsize) ans += que[0], deq();
	}
	printf("%lld\n", ans);
	return 0;
}


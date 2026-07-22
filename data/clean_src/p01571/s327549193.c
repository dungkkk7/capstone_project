// AOJ 2457 Adhoc Translation
// 2018.3.6 bal4u

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define QMAX 10005
typedef struct { int t, s; } QUE;
QUE que[QMAX]; int qsize;

#define PARENT(i) ((i)>>1)
#define LEFT(i)   ((i)<<1)
#define RIGHT(i)  (((i)<<1)+1)

void min_heapify(int i)
{
	int l, r, min;
	QUE qt;

	l = LEFT(i), r = RIGHT(i);
	if (l < qsize && que[l].t < que[i].t) min = l; else min = i;
	if (r < qsize && que[r].t < que[min].t) min = r;
	if (min != i) {
		qt = que[i], que[i] = que[min], que[min] = qt;
		min_heapify(min);
	}
}

void deq()
{
	que[0] = que[--qsize];
	min_heapify(0);
}

void enq(int s, int t)
{
	int i, min;
	QUE qt;

	i = qsize++;
	que[i].s = s, que[i].t = t;
	while (i > 0 && que[min = PARENT(i)].t > que[i].t) {
		qt = que[i], que[i] = que[min], que[min] = qt;
		i = min;
	}
}

#define INF 0x01010101
#define MAX 805
typedef struct { int to, rev; int cap, cost; } E;
E *edge[MAX]; int hi[MAX], lim[MAX];
int V;				// 頂点数
int potential[MAX], min_cost[MAX], prevv[MAX], preve[MAX];

void check_lim(int a)
{
	if (hi[a] < lim[a]) return;
	if (lim[a] == 0) {
		lim[a] = 4, hi[a] = 0;
		edge[a] = malloc(sizeof(E) *lim[a]);
	} else if (hi[a] == lim[a]) {
		int k = lim[a];
		if (k > 256) k = 256;
		lim[a] += k;
		edge[a] = realloc(edge[a], sizeof(E) *lim[a]);
	}
}

void add_edge(int from, int to, int cap, int cost)
{
	int f, t;
	E *ep;

	check_lim(from), check_lim(to);
	f = hi[from]++, t = hi[to]++;
	ep = &edge[from][f], ep->to = to, ep->cap = cap, ep->cost = cost, ep->rev = t; 
	ep = &edge[to][t], ep->to = from, ep->cap = 0, ep->cost = -cost, ep->rev = f;
}

int minCostFlow(int S, int T, int F)
{
	int i, s, ns, t, nt, ret;
	E *ep;

	ret = 0;
//	memset(potential, 0, V << 2);
  
    while (F > 0) {
		memset(min_cost, INF, V << 2);
		qsize = 0;
		enq(S, 0), min_cost[S] = 0;
  
		while (qsize) {
			s = que[0].s, t = que[0].t, deq();
			if (min_cost[s] < t) continue;

			for (i = 0; i < hi[s]; i++) {
				ep = &edge[s][i], ns = ep->to;
				nt = t + ep->cost + potential[s] - potential[ns];
				if(ep->cap > 0 && min_cost[ns] > nt) {
					min_cost[ns] = nt;
					prevv[ns] = s, preve[ns] = i;
					enq(ns, nt);
				}
			}
		}
		if (min_cost[T] == INF) return -1;
		for (s = 0; s < V; s++) potential[s] += min_cost[s];

		t = F;
		for (s = T; s != S; s = prevv[s]) {
			ep = &edge[prevv[s]][preve[s]];
			if (t > ep->cap) t = ep->cap;
		}
		F -= t;

		ret += t * potential[T];
		for (s = T; s != S; s = prevv[s]) {
			ep = &edge[prevv[s]][preve[s]];
			ep->cap -= t;
			edge[s][ep->rev].cap += t;
		}
	}
	return ret;
}

typedef struct { int c, w; char *s; } S;	// w:len, c:cnt
S web[50000]; int sz;
S dic[402];
char buf[102][1005];
char word[402][25];
char dp0[22][22], dp[22][22];

int string_distance(char *s1, int w1, char *s2, int w2)
{
	int  i, j, d, min;

	memcpy(dp, dp0, sizeof(dp));
	for (j = 1; j <= w1; j++) for (i = 1; i <= w2; i++) {
		d = (s1[j-1] != s2[i-1]);
		min =     dp[j-1][i  ] + 1;
		if (min > dp[j  ][i-1] + 1) min = dp[j  ][i-1] + 1;
		if (min > dp[j-1][i-1] + d) min = dp[j-1][i-1] + d;
		dp[j][i] = min;
	}
	return dp[w1][w2];
}

int cmp(S *a, S *b) { return strcmp(a->s, b->s); }

int uniq(S *a, int n)
{
	int i, j, k;
	
	for (i = 0, j = 1; j < n; j++) {
		k = j; while (j < n && a[i].w == a[j].w && !memcmp(a[i].s, a[j].s, a[i].w)) j++;
		a[i].c = j-k+1; if (j < n) if (++i != j) a[i] = a[j];
	}
	return i+1;
}

int main()
{
	int N, M, i, j, source, sink;
	char b[20], *p, *q;

	i = 21; while (i--) dp0[i][0] = i;
	i = 21; while (i--) dp0[0][i] = i;

	fgets(b, 20, stdin), sscanf(b, "%d%d", &N, &M);
	sz = 0; for (i = 0; i < N; i++) {
		fgets(p=buf[i], 1002, stdin);
		while (1) {
			q = p; while (*p > ' ') p++;
			web[sz].c = 1, web[sz].s = q, web[sz++].w = p-q;
			if (*p < ' ') { *p = 0; break; }
			*p++ = 0;
		}
	}
	qsort(web, sz, sizeof(S), cmp), sz = uniq(web, sz);

	for (i = 0; i < M; i++) {
		fgets(p=word[i], 22, stdin);
		q = p; while (*p > ' ') p++; *p = 0;
		dic[i].s = q, dic[i].w = p-q;
	}

	source = sz + M, sink = source + 1, V = sink + 1;

	for (i = 0; i < sz; i++) add_edge(source, i, 1, 0);
	for (i = 0; i < sz; i++) for (j = 0; j < M; j++) {
		add_edge(i, sz+j, 1, web[i].c*string_distance(web[i].s, web[i].w, dic[j].s, dic[j].w));
	}
	for (j = 0; j < M; j++) add_edge(sz+j, sink, 1, 0);

	printf("%d\n", minCostFlow(source, sink, sz));
	return 0;
}

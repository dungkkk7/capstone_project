// AOJ 1280: Slim Span
// 2017.10.22 bal4u@uu

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX 100
/* UNION-FIND library */
int p[MAX], rank[MAX], pp[MAX];
void make_set(int x) { p[x] = x, rank[x] = 0; }
void link(int x, int y) {
	if (rank[x] > rank[y]) p[y] = x;
	else { p[x] = y; if (rank[x] == rank[y]) rank[y] = rank[y] + 1;	}
}
int find_set(int x) { if (x != p[x]) p[x] = find_set(p[x]);	return p[x]; }
void union_set(int x, int y) { link(find_set(x), find_set(y)); }

typedef struct { int x, y, w; } EDGE;
EDGE edge[5000], *end;
int f[10002], max;

int cmp(EDGE *a, EDGE *b) { return a->w - b->w; }

char buf[130], *b;
int getInt(void)
{
	int n = 0;
	if (*b == ' ') b++;
	n = 0; while (*b >= '0' ) n = (n<<3) + (n<<1) + (*b++ & 0xf);
	return n;
}

int main() 
{
	int n, m, i, j, k, ans, sz;
	EDGE *ep;

	for (j = 0; j < 100; j++)  pp[j] = j;
	while (fgets(b=buf, 128, stdin) && *b != '0') {
		n = getInt(), m = getInt();
		sz = sizeof(int)*n;
		for (ep = edge, k = m; k--; ep++) {
			fgets(b=buf, 128, stdin);
			ep->x = getInt()-1, ep->y = getInt()-1, ep->w = getInt();
		}
		end = ep;

		qsort(edge, m, sizeof(EDGE), cmp);
	
		ans = -1;
		for (i = 0; i < m; i++) {
			memcpy(p, pp, sz), memset(rank, 0, sz);
			for (k = 1, ep = edge+i; ep < end; ep++) {
				if (find_set(ep->x) != find_set(ep->y)) {
					union_set(ep->x, ep->y);
					if (++k == n) {
						if (ans < 0 || ep->w - edge[i].w < ans) {
							ans = ep->w - edge[i].w;
							if (ans == 0) goto done;
						}
						break;
					}
				}
			}
		}
done:	printf("%d\n", ans);
	}
	return 0; 
}
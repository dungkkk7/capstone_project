/*
   Aizu Vol-1 0165: Lottery
   2017.8.15 bal4u@uu
   ?´???°??¨?????????
*/

#include <stdio.h>

#define MAX  1000000
#define SQRT 1000     // sqrt(MAX)

char prime[MAX + 5], *p, *q, *pmax = prime + MAX;
int table[MAX + 5], *t;


int main()
{
	int N, P, M;
	int k, a, b, ans;

	for (k = 3, p = prime + 3; k <= SQRT; k += 2, p += 2) {
		if (!*p) {
			for (q = p + k; q <= pmax; q += k) *q = 1;
		}
	}
	table[2] = k = 1, t = table + 3;
	for (p = prime + 3; p <= pmax; p += 2) {
		if (!*p) k++;
		*t++ = k, *t++ = k;
	}
	while (1) {
		scanf("%d", &N); if (!N) break;
		for (ans = 0, k = 0; k < N; k++) {
			scanf("%d%d", &P, &M);
			a = P - M, b = P + M;
			if (a < 2) a = 2;
			if (b > 1000000) b = 1000000;
			ans += table[b] - table[a - 1] - 1;
		}
		if (ans < 0) ans = 0;
		printf("%d\n", ans);
	}
	return 0;
}
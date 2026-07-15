// AOJ 0606: Tower of JOIOI
// 2018.1.10 bal4u@uu

#include <stdio.h>
#include <stdlib.h>

char s[1000005], *p;

int check(char *p, int m)
{
	int i, si, oi, soi, n;

	i = si = oi = soi = n = 0;
	while (*p) {
		if (*p == 'J') {
			if (soi > oi) { oi++; if (++n == m) return 1; }
		} else if (*p == 'O') {
			if (si > i && soi < m) soi++, i++;
		} else {						// *p == 'I'
			if (si < m) si++;
			else if (soi > oi) { oi++; if (++n == m) return 1; }
		}
		p--;
	}
	return 0;
}

int main()
{
	int n, i, oi, ans;
	int lo, hi, m;

	fgets(s+1, 10, stdin), n = atoi(s+1);
	fgets(s+1, 1000005, stdin);
	ans = i = oi = 0;	// i:'I'の数, oi:"OI"ペア数
	p = s+n; while (*p) {
		if (*p == 'J') {
			if (oi) ans++, oi--;
		} else if (*p == 'I') {
			i++;
		} else /* if (*p == 'O') */ {
			if (i) oi++, i--;
		}
		p--;
	}
	if (!oi) goto done;

	m = ans + (i + oi)/2;
	if (check(s+n, m)) { ans = m; goto done; }

	if (i > oi) {
		m = ans + oi;
		if (check(s+n, m)) { ans = m; goto done; }
	}

	lo = ans;
	hi = ans + 1 + (i + oi)/2;
	while (lo + 1 < hi) {
		m = (lo + hi) >> 1;
		if (check(s+n, m)) lo = m; else hi = m;
	}
	ans = lo;

done:
	printf("%d\n", ans);
	return 0;
}

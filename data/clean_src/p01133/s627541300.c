// AOJ 2008: Dragon Fantasy
// 2017.11.22 bal4u@uu

#include <stdio.h>
#include <string.h>
#include <math.h>

int cx[22], cy[22], n;
double dh[22], dd[22];
double dc[22][22];

double dist(int x1, int y1, int x2, int y2)
{
	return hypot(x1-x2, y1-y2);
}

int rec(int i, int s, double d)
{
	int j, jj;

	if (s == (1<<n) - 1) return 1;
	for (jj = 1, j = 0; j < n; j++, jj <<= 1) {
		if (s & jj) continue;
		if (dd[j] < d + dc[i][j]) return 0;
	}
	for (jj = 1, j = 0; j < n; j++, jj <<= 1) {
		if (s & jj) continue;
		if (dd[j] > d + dc[i][j] && rec(j, s | jj, d + dc[i][j])) return 1;
	}
	return 0;
}

int main()
{
	int i, j, hx, hy, dx, dy;

	while (scanf("%d%d%d%d%d", &n, &hx, &hy, &dx, &dy) && n > 0) {
		n++;
		cx[0] = hx, cy[0] = hy;	for (i = 1; i < n; i++) scanf("%d%d", cx+i, cy+i);
		for (i = 0; i < n; i++) {
			dd[i] = dist(cx[i], cy[i], dx, dy);
			dh[i] = dist(cx[i], cy[i], hx, hy);
			dc[i][i] = 0;
			for (j = i+1; j < n; j++) {
				dc[i][j] = dc[j][i] = dist(cx[i], cy[i], cx[j], cy[j]);
			}
		}

		for (i = 1; i < n; i++) if (dh[i] > dd[i]) break;
		if (i < n) puts("NO");
		else puts(rec(0, 0, 0) ? "YES" : "NO");
	}
	return 0;
}
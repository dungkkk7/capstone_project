// AOJ 1239: Viva Confetti
// 2017.12.18 bal4u@uu

#include <stdio.h>
#include <string.h>
#include <math.h>

#define EPS 1e-20

typedef struct { double x, y, r; } C;
C c[101]; int n;

double dist(double x1, double y1, double x2, double y2)
{
	return hypot(x1-x2, y1-y2);
}

int intersect(C c1, C c2, double *cx1, double *cy1, double *cx2, double *cy2)
{
	double x1 = c1.x, y1 = c1.y, r1 = c1.r;
	double x2 = c2.x, y2 = c2.y, r2 = c2.r;
	double d = dist(x1, y1, x2, y2);
	double w, n, x, y, p, q;
	double u, v;

	u = r1+r2, v = fabs(r1-r2);

	if ((fabs(d-u) > EPS && d >= u) || fabs(v-d) > EPS && d <= v) return 0;
	w = ((r1*r1 - r2*r2)/d + d) / 2;
	n = sqrt(r1*r1 - w*w);
	x = x1 + (x2-x1)*w / d;
	y = y1 + (y2-y1)*w / d;
	p = (y2-y1)*n / d;
	q = (x2-x1)*n / d;

	*cx1 = x+p, *cx2 = x-p;
	*cy1 = y-q; *cy2 = y+q;
	if (fabs(d-u) <= EPS) return 1;
	if (d == r1+r2) return 1;
	return 2;
}

int include_circle(int i, int j)
{
	double d = hypot(c[i].x-c[j].x, c[i].y-c[j].y);
	double x = c[i].r - (d + c[j].r);
	if (fabs(x) <= EPS || x >= 0) return 1;
	return 0;
}

int include_point(int i, double x, double y)
{
	double d = c[i].r - hypot(c[i].x - x, c[i].y - y);
	if (fabs(d) <= EPS || d >= 0) return 1;
	return 0;
}

int find_c(double x, double y, int i, int j)
{
	for (; i <= j; j--) {
		if (include_point(j, x, y)) return j;
	}
	return -1;
}

int cross_method()
{
	int i, j, k, b, n1, ans = 0;
	double x[2], y[2];
	int gc[101];
	char mk[101];

	for (i = 0; i < n; i++) {
		gc[i] = 0, mk[i] = 0;
		for (j = i+1; j < n; j++) {
			n1 = intersect(c[i], c[j], x, y, x+1, y+1);
			gc[i] += n1;
			for (k = 0; k < n1; k++) {
				if (find_c(x[k], y[k], i+1, j-1) < 0 &&
					find_c(x[k], y[k], j+1, n-1) < 0) {
					mk[i] = 1;
					b = find_c(x[k], y[k], 0, i-1);
					if (b >= 0) mk[b] = 1;
				}
			}
		}
	}

	ans = 0;
	for (i = 0; i < n; i++) {
		if (mk[i]) ans++;
		else if (!gc[i]) {
			for (j = i+1; j < n; j++) {
				if (include_circle(j, i)) break;
			}
			if (j >= n) ans++;
		}
	}
	return ans;
}

int main()
{
	int i;

	while(scanf("%d", &n) && n > 0) {
		for (i = 0; i < n; i++) {
			scanf("%lf%lf%lf", &c[i].x, &c[i].y, &c[i].r);
		}
		printf("%d\n", cross_method());
	}
	return 0;
}
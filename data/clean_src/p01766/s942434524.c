// AOJ 2662: Soccer
// 2018.1.3 bal4u@uu

#include <stdio.h>
#include <math.h>

int f[101], a[101], t[101], x[101], y[101];
int lmax[2], tmin[2];

int main()
{
	int n, i, d;

    scanf("%d", &n);
    for (i = 0; i < n; i++) scanf("%d%d%d%d%d", f+i, a+i, t+i, x+i, y+i);
 
	lmax[0] = lmax[1] = -1;
    for (i = 1; i < n; i++) if (t[i] == t[i-1] && a[i] != a[i-1]) {
		d = (x[i]-x[i-1])*(x[i]-x[i-1]) + (y[i]-y[i-1])*(y[i]-y[i-1]);
		if (d > lmax[t[i]]) lmax[t[i]] = d, tmin[t[i]] = f[i]-f[i-1];
		else if (d == lmax[t[i]]) {
			if (tmin[t[i]] > f[i]-f[i-1]) tmin[t[i]] = f[i]-f[i-1];
		}
    }

    for (i = 0; i < 2; i++) {
		if (lmax[i] < 0) puts("-1 -1");
        else printf("%.8lf %.8lf\n", sqrt(lmax[i]), tmin[i]/60.0);
    }
	return 0;
}


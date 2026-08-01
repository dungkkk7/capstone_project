// AOJ 1093: KND Runs for Sweets
// 2017.11.16 bal4u@uu

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define KAI 50
int x[101], y[101], v[101]; int n;
int max;

double fx(double a, double b)
{
	int i;
	double d, max;
	
	max = 0;
	for (i = 0; i < n; i++) {
		d = hypot(a-x[i], b-y[i]) / v[i];
		if (d > max) max = d;
	}
	return max;
}

double srchy(double x)
{
	int i;
	double l, r, a, b;

	l = 0, r = max;
	i = KAI; while (i--) {
		a = (2*l + r) / 3;
		b = (l + 2*r) / 3;
		if (fx(x, a) < fx(x, b) ) r = b;
		else                      l = a;
	}
	return fx(x, (l+r)/2);
}

double srch3()
{
	int i;
	double l, r, a, b;
	
	l = 0, r = max;
	i = KAI; while (i--) {
		a = (2*l + r) / 3;
		b = (l + 2*r) / 3;
		if (srchy(a) < srchy(b)) r = b;
		else                     l = a;
	}
	return srchy((l+r) / 2) ;
}

int main()
{
	int i;

	while (scanf("%d", &n) && n > 0) {
		max = 0;
		for (i = 0; i < n; i++)	{
			scanf("%d%d%d", x+i, y+i, v+i);
			if (x[i] > max) max = x[i];
			if (y[i] > max) max = y[i];
		}
		printf("%.8f\n", srch3());
	}
	return 0;
}
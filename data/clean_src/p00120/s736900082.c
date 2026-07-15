#include <stdio.h>          // printf(), scanf()
#include <stdlib.h>         // abs(), qsort()
#include <math.h>           // sqrt(), round()
#include <stdbool.h>

// #define DEBUG 1
#define MAX_N 12

int n;
int r[MAX_N];
int w;
int lineno;
#ifdef DEBUG
double wmin;
#endif

int
cmp_func(const void *l_, const void *r_)
{
	const int *l = (const int*) l_;
	const int *r = (const int*) r_;

	if (*l < *r)
		return -1;

	if (*l > *r)
		return 1;

	return 0;
}

double
width(const int a[MAX_N * 2 - 1])
{
	double tw = a[0];
	for (int i = 1; i < n; ++i)
	{
		int rc = a[i - 1] + a[i];
		int ra = abs(a[i - 1] - a[i]);
		tw += sqrt(rc * rc - ra * ra);
	}

	tw += a[n - 1];
	tw = round(tw * 1000000000.0) / 1000000000.0;
	return tw;
}

bool
solve()
{
	qsort(r, n, sizeof(int), cmp_func);

	int a[MAX_N * 2 - 1];
	int l = 0, h = n - 1;
	int tl = n - 1, th = n - 1;
	a[tl] = r[h--];

	for (int i = 1; i < n; ++i)
	{
		int b;
		if (i & 1)
			b = r[l++];
		else
			b = r[h--];

		int lw = abs(a[tl] - b);
		int hw = abs(a[th] - b);
		if (lw > hw)
			a[--tl] = b;
		else if (lw < hw)
			a[++th] = b;
		else
		{
			if (a[tl] < a[th])
				a[--tl] = b;
			else
				a[++th] = b;
		}
	}

#ifndef DEBUG
	double wmin = width(&a[tl]);
#else
	wmin = width(&a[tl]);
#endif

	l = 0, h = n - 1;
	tl = n - 1; th = n - 1;
	a[tl] = r[l++];

	for (int i = 1; i < n; ++i)
	{
		int b;
		if (i & 1)
			b = r[h--];
		else
			b = r[l++];

		int lw = abs(a[tl] - b);
		int hw = abs(a[th] - b);
		if (lw > hw)
			a[--tl] = b;
		else if (lw < hw)
			a[++th] = b;
		else
		{
			if (a[tl] < a[th])
				a[--tl] = b;
			else
				a[++th] = b;
		}
	}

	double d = width(&a[tl]);
	if (d < wmin)
		wmin = d;

	return wmin <= w;
}

bool
ope_line()
{

	lineno++;
	int i = scanf("%d", &w);
	if (i == EOF)
		return false;

	for (n = 0;; ++n)
	{
		char c;
		scanf("%c", &c);
		if (c == '\n' || c == EOF)
			break;

		scanf("%d", &r[n]);
	}

#ifndef DEBUG
	printf("%s\n", solve() ? "OK" : "NA");
#else
	bool b = solve();
	printf("%s: %.9f\n", b ? "OK" : "NA", wmin);
#endif
	return true;
}

int
main(int argc, char **argv)
{
	lineno = 0;
	while (true) // process for each line
	{
		if (!ope_line())
			break;
	}

	return 0;
}
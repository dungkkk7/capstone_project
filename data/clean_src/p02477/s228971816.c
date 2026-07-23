// AOJ NTL_2_F Multiplication of Big Integers II
// 2019.3.8 bal4u

#include <stdio.h>
#include <stdlib.h>

#define N       1000000000

int a[30000], b[30000], ab[60000];
int a_minus, b_minus;
char buf[500000];

char *mpStr2Num(int *num, char *str)
{
	char *ss, *end;
	int  *nn;
	int  k, x;

//	while (*str == ' ' || *str == '\t') str++;
	while (*str == '0') str++;
	ss = str;

	x = 0;
	while (*ss >= '0' && *ss <= '9') ss++, x++;
	end = ss;
	if (ss == str) { *num = 0; return end; }

	x = 0, k = 1, nn = num;
	do {
		x += (*--ss - '0') * k;
		k *= 10;
		if (k == N || ss == str) *++nn = x, x = 0, k = 1;
	} while (ss != str);

	*num = nn - num;
	return end;
}

void mpNum2Str(char *str, int *num)
{
	int  i, j, x;
	char *ss;

	if (*num == 0 || (*num == 1 && *(num + 1) == 0)) {
		*str++ = '0', *str = '\0';
		return;
	}

	ss = str - 1;
	for (i = *num; i > 0; i--) {
		x = *++num;
		for (j = 1; j < N; j *= 10) {
			*++ss = x % 10 + '0';
			x /= 10;
		}
	}
	while (*ss == '0') ss--;

	*(ss + 1) = '\0';
	while (str < ss) {
		x = *str;
		*str++ = *ss;
		*ss-- = x;
	}
}

void mpAdd(int *ret, int *a, int *b)
{
	int  i, lr, la, lb, x;
	int  *rr;

	la = *a, lb = *b;
	lr = (la >= lb) ? la : lb;
	rr = ret, x = 0;
	for (i = 1; i <= lr; i++) {
		if (i <= la) x += *++a;
		if (i <= lb) x += *++b;
		if (x < N) *++rr = x, x = 0;
		else       *++rr = x - N, x = 1;
	}
	*++rr = x;
	*ret = lr + x;
}

void mpSub(int *ret, int *a, int *b)
{
	int  i, la, lb, x;
	int  *rr;

	la = *a, lb = *b;
	rr = ret, x = 0;
	for (i = 1; i <= la; i++) {
		x += *++a;
		if (i <= lb) x -= *++b;
		if (x >= 0) *++rr = x, x = 0;
		else 		*++rr = x + N, x = -1;
	}
	while (--i > 0) if (*rr-- != 0) break;
	*ret = i;
}

int mpCmp(int *a, int *b)
{
	int  *aa;

	if (*a != *b) return *a - *b;
	aa = a, a += *aa, b += *aa;
	while (a != aa) {
		if (*a != *b) return *a - *b;
		a--, b--;
	}
	return 0;
}

int mpAddSub(int *ret, int *a, int a_minus, int *b, int b_minus)
{
	int k, minus = 0;

	if (a_minus && b_minus) minus = 1, a_minus = 0, b_minus = 0;
	if (!a_minus && !b_minus) mpAdd(ret, a, b);
	else {
		k = mpCmp(a, b);
		if (k == 0) *ret = 0, minus = 0;
		else if (k > 0) mpSub(ret, a, b), minus = a_minus;
		else            mpSub(ret, b, a), minus = b_minus;
	}
	return minus;
}

void mpMul(int *ret, int *a, int *b)
{
	int  i, j, la, lb;
	int  *aa;
	int  ca;
	unsigned long long x;

	la = *a, lb = *b;

	if (la == 0 || lb == 0) { *ret = 0; return; }

	for (i = la + lb; i > 0; i--) *(ret + i) = 0;

	for (j = 1; j <= lb; j++) {
		ca = 0;
		b++;
		aa = a;
		for (i = 1; i <= la; i++) {
			x = *++aa;
			x = x * *b + *(ret + i + j - 1) + ca;
			*(ret + i + j - 1) = (int)(x % N);
			ca = (int)(x / N);
		}
		*(ret + i + j - 1) = ca;
	}
	*ret = (ca != 0) ? la + lb : la + lb - 1;
}

int mpDiv(int *q, int *r, int *za, int *zb)
{
	int  i;
	int  m, n;
	int  *aa, *bb, *qq, *rr, *t;
	int  ca;
	long long x;
	int  k, Q;
	static int atmp[1000], btmp[1000];
	int  *a = atmp, *b = btmp;

	*q = 0, *r = 0;
	if (*zb == 0) return -2;
	if (*za == 0) return 0;

	if (*za < *zb) {
		for (aa = za, rr = r, i = *za; i >= 0; i--) *rr++ = *aa++;
		return 0;
	}

	if (*zb == 1) {
		*q = *za;
		zb++;
		for (ca = 0, aa = za + *za, qq = q + *q, i = *za; i > 0; i--) {
			x = (long long)N * ca + *aa--;
			*qq-- = (int)(x / *zb), ca = (int)(x % *zb);
		}
		if (*(q + *q) == 0) (*q)--;
		if (ca > 0) {
			*r++ = 1;
			*r = ca;
		}
		else *r = 0;
		return 0;
	}

	for (aa = a, i = *za; i >= 0; i--) *aa++ = *za++;
	for (bb = b, i = *zb; i >= 0; i--) *bb++ = *zb++;

	if ((k = (N / 2 - 1) / *(b + *b) + 1) > 1) {
		for (ca = 0, aa = a, qq = q, i = 0; i < *a; i++) {
			x = (long long)k * *++aa + ca;      /* a = a * k */
			*++qq = x % N, ca = (int)(x / N);
		}
		*++qq = ca;
		*q = i + (ca > 0);
		for (qq = q, aa = a, i = *q; i >= 0; i--) *aa++ = *qq++;

		for (ca = 0, bb = b, qq = q, i = 0; i < *b; i++) {
			x = (long long)k * *++bb + ca;      /* b = b * k */
			*++qq = x % N, ca = (int)(x / N);
		}
		*++qq = ca;
		*q = i + (ca > 0);
		for (qq = q, bb = b, i = *q; i >= 0; i--) *bb++ = *qq++;
	}

	*q = *a - *b + 1;
	for (qq = q, i = *q; i > 0; i--) *++qq = 0;
	n = *b;
	while ((m = *a) >= n) {
		if (*(a + *a) >= *(b + *b)) {
			for (aa = a + *a, bb = b + *b; bb != b; aa--, bb--)
				if (*aa != *bb) break;
			if (bb == b) {
				*a -= *b;
				*(q + m - n + 1) = 1;
				continue;
			}
			else if (*aa > *bb) {
				for (t = bb, ca = 0, aa = a + m - n, bb = b; bb < t; ) {
					*++aa -= *++bb + ca;
					ca = 0;
					if (*aa < 0) *aa += N, ca = 1;
				}
				while (*aa == 0) aa--;
				*a = aa - a;
				*(q + m - n + 1) = 1;
				continue;
			}
			Q = N - 1;
		}
		else Q = ((long long)N * *(a + *a) + *(a + *a - 1)) / *(b + *b);
		if (m == n) break;

		for (; ; ) {
			if (Q == 1) {
				*(b + *b + 1) = 0;
				for (ca = 0, aa = a + (*a - *b - 1), bb = b, i = *b; i >= 0; i--) {
					*++aa -= *++bb + ca;
					ca = 0;
					if (*aa < 0) *aa += N, ca = 1;
				}
				while (*aa == 0) aa--;
				*a = aa - a;
				break;
			}
			for (ca = 0, rr = r, bb = b, i = 0; i < *b; i++) {
				x = (long long)Q * *++bb + ca;
				*++rr = x % N, ca = (int)(x / N);
			}
			*++rr = ca;
			*r = i + 1;
			for (aa = a + *a, rr = r + *r; rr != r; aa--, rr--)
				if (*aa != *rr) break;
			if (rr == r) {
				*a -= *r;
				break;
			}
			else if (*aa > *rr) {
				for (t = rr, ca = 0, aa = a + (*a - *r), rr = r; rr < t; ) {
					*++aa -= *++rr + ca;
					ca = 0;
					if (*aa < 0) *aa += N, ca = 1;
				}
				while (*aa == 0) aa--;
				*a = aa - a;
				break;
			}
			else Q--;
		}
		*(q + m - n) = Q;
	}
	if (*(q + *q) == 0) (*q)--;

	if (k > 1) {
		for (ca = 0, aa = a + *a, rr = r + *a, i = *a; i > 0; i--) {
			x = (long long)N * ca + *aa--;
			*rr-- = (int)(x / k), ca = (int)(x % k);
		}
		*r = *a - (*(r + *a) == 0);
		if (*r < 0) *r = 0;
	}
	else for (aa = a, rr = r, i = *a; i >= 0; i--) *rr++ = *aa++;

	return 0;
}

int main()
{
	int minus;
	char *p, *q;

	fgets(p = buf, 5000000, stdin);
	if (*p == '-') a_minus = 1, p++;
	p = mpStr2Num(a, p);
	while (*p == ' ') p++;

	q = p;
	if (*p == '-') b_minus = 1, p++;
	p = mpStr2Num(b, p);

	minus = a_minus ^ b_minus;
	mpMul(ab, a, b);

	if (*ab == 0) minus = 0;
	if (minus) putchar('-');
	mpNum2Str(buf, ab);
	puts(buf);
	return 0;
}

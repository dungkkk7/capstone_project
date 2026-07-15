#if 0
cat <<EOF >mistaken-paste
#endif
// thx Ebi-chan!

// #pragma GCC optimize("unroll-loops")
// #pragma GCC optimize("O3")

#pragma GCC diagnostic ignored "-Wincompatible-pointer-types"
#define _USE_MATH_DEFINES

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <time.h>

#define BIG 2000000007LL
#define VERYBIG 20000000000000007LL
#define ULTRABIG 3000000000000000000LL

#define MOD 1000000007LL
#define FOD  998244353LL
typedef uint64_t ull;
typedef  int64_t sll;

#define N_MAX 1048576

#ifdef __cplusplus
#include <queue>
#include <stack>
#include <tuple>
#include <set>
#include <map>
#include <string>
#include <algorithm>
#include <functional>
#include <array>

using std::queue;
using std::priority_queue;
using std::stack;
using std::tuple;
using std::set;
using std::map;
using std::vector;
using std::greater;
using std::pair;
using std::string;
using std::get;
using std::function;

template <typename T, typename U>
pair<T, U> operator+(pair<T, U> l, pair<T, U> r) {
	return pair<T, U>(l.first + r.first, l.second + r.second);
}

#endif

#ifndef M_PI
#define M_PI 3.14159265358979323846264338327950
#endif

typedef struct {
	sll a;
	sll b;
} hwll;

typedef struct {
	sll a;
	sll b;
	sll c;
} hwllc;

typedef struct {
	hwll a;
	hwll b;
} linell;

typedef struct {
	double a;
	double b;
} hwreal;

sll n, m;
sll h, w;
sll k;
sll q;
sll va, vb, vc, vd, ve, vf;
ull ua, ub, uc, ud, ue, uf;
long double vra, vrb, vrc;
double vda, vdb, vdc;
char ch, dh;

ull umin (ull x, ull y) {
	return (x < y) ? x : y;
}

ull umax (ull x, ull y) {
	return (x > y) ? x : y;
}

sll smin (sll x, sll y) {
	return (x < y) ? x : y;
}

sll smax (sll x, sll y) {
	return (x > y) ? x : y;
}

double dmin (double x, double y) {
	return (x < y) ? x : y;
}

double dmax (double x, double y) {
	return (x > y) ? x : y;
}

ull gcd (ull x, ull y) {
	if (y == 0) {
		return x;
	} else {
		return gcd(y, x % y);
	}
}

ull bitpow (ull a, ull x, ull modulo) {
	ull result = 1;
	while (x) {
		if (x & 1) {
			result *= a;
			result %= modulo;
		}
		x /= 2;
		a = (a * a) % modulo;
	}
	return result;
}

ull divide (ull a, ull b, ull modulo) {
	return (a * bitpow(b, modulo - 2, modulo)) % modulo;
}

ull udiff (ull a, ull b) {
	if (a >= b) {
		return a - b;
	} else {
		return b - a;
	}
}

sll sdiff (sll a, sll b) {
	if (a >= b) {
		return a - b;
	} else {
		return b - a;
	}
}

int bitcount (ull n) {
	int result = 0;
	while (n) {
		if (n & 1) result++;
		n /= 2;
	}
	return result;
}

#define BEGCMP(NAME) int32_t NAME (const void *left, const void *right)
#define DEFLR(TYPE) TYPE l=*(TYPE*)left,r=*(TYPE*)right
#define CMPRET(L, R) if((L)<(R))return-1;if((L)>(R))return+1

// int32_t pullcomp (const void *left, const void *right) {
// 	ull l = *(ull*)left;
// 	ull r = *(ull*)right;
// 	if (l < r) {
// 		return -1;
// 	}
// 	if (l > r) {
// 		return +1;
// 	}
// 	return 0;
// }
BEGCMP(pullcomp){
	DEFLR(ull);
	CMPRET(l, r);
	return 0;
}
BEGCMP(prevcomp){
	DEFLR(sll);
	CMPRET(r, l);
	return 0;
}
BEGCMP(psllcomp){
	DEFLR(sll);
	CMPRET(l, r);
	return 0;
}
BEGCMP(pcharcomp){
	DEFLR(char);
	CMPRET(l, r);
	return 0;
}
BEGCMP(pdoublecomp){
	DEFLR(double);
	CMPRET(l, r);
	return 0;
}

int32_t pstrcomp (const void *left, const void *right) {
	char* l = *(char**)left;
	char* r = *(char**)right;

	return strcmp(l, r);
}

BEGCMP(phwllABcomp){
	DEFLR(hwll);
	CMPRET(l.a, r.a);
	CMPRET(l.b, r.b);
	return 0;
}
BEGCMP(phwllREVcomp){
	DEFLR(hwll);
	CMPRET(l.b, r.b);
	CMPRET(l.a, r.a);
	return 0;
}
BEGCMP(ptriplecomp){
	DEFLR(hwllc);
	CMPRET(l.a, r.a);
	CMPRET(l.b, r.b);
	CMPRET(l.c, r.c);
	return 0;
}
BEGCMP(ptripleREVcomp){
	DEFLR(hwllc);
	CMPRET(l.b, r.b);
	CMPRET(l.a, r.a);
	CMPRET(l.c, r.c);
	return 0;
}
BEGCMP(ptripleCABcomp){
	DEFLR(hwllc);
	CMPRET(l.c, r.c);
	CMPRET(l.a, r.a);
	CMPRET(l.b, r.b);
	return 0;
}
BEGCMP(phwrealcomp){
	DEFLR(hwreal);
	CMPRET(l.a, r.a);
	CMPRET(l.b, r.b);
	return 0;
}

int32_t pquadcomp (const void *left, const void *right) {
	linell l = *(linell*)left;
	linell r = *(linell*)right;

	sll ac = phwllABcomp(&(l.a), &(r.a));
	if (ac) return ac;
	sll bc = phwllABcomp(&(l.b), &(r.b));
	if (bc) return bc;

	return 0;
}
int32_t pfracomp (const void *left, const void *right) {
	hwllc l = *(hwllc*)left;
	hwllc r = *(hwllc*)right;

	CMPRET(l.a * r.b, l.b * r.a);
	return 0;
}
bool isinrange (sll left, sll x, sll right) {
	return (left <= x && x <= right);
}

bool isinrange_soft (sll left, sll x, sll right) {
	return (left <= x && x <= right) || (left >= x && x >= right);
}

void sw (sll *l, sll *r) {
	if (*l == *r) return;
	sll t = *l;
	*l = *r;
	*r = t;
}

ull frac[N_MAX * 3], invf[N_MAX * 3];
ull ncr (sll n, sll r, ull m) {
	if (n < 0 || r < 0 || n < r) return 0;
	return frac[n] * (invf[r] * invf[n - r] % m) % m;
}

sll a[N_MAX * 5];
// ull a[N_MAX + 5];
// sll a[3001][3001];
sll b[N_MAX * 5];
// ull b[N_MAX + 5];
// sll b[3001][3001];
sll c[N_MAX * 5];
sll d[N_MAX * 5];
sll e[N_MAX * 4];
char s[N_MAX + 1];
// char s[3010][3010];
char t[N_MAX + 1];
// char t[3010][3010];
char u[N_MAX + 1];
hwll xy[N_MAX + 5];
hwllc tup[N_MAX + 5];
sll table[3005][3005];
ull gin[N_MAX];
// here we go

/*

考察メモ


K + 0~2N-1 > 2N~3N-1
K + 2(2N-1)N > N(3N-1)3/2
K + 4n^2 - n > 9/2n^2 - 3/2n
K + 1/2n > 


1 2 3 4 5 6
1 3 5, 2 4 6


1 2 3 4
5 6 7 8
9 10 11 12



2 3 4 5
6 7 8 9
10 11 12 13

すくなくともこれはだめ:
(K + (K+2N-1)) * 2N > (K + (K+3N-1)) * 3/2N

2(2K+2N-1) > 3/2(2K+3N-1)

8K+8N-4 > 6K + 9N - 3
2K>N+1



2K<=N+1 が必要

N=3,K=2

2 4 3
6 5 7
8 9 10

N=5,K=3


3~7
8~12
13~17

03 06 04 07 05
10 08 11 09 12
13 14 15 16 17


N=4,K=2

2 4 3 5
8 6 9 7
10 11 12 13

*/


ull solve () {
	sll i, j, ki, li;
	// ull result = 0;
	sll result = 0;
	double dresult = 0;
	// ull maybe = 0;
	sll maybe = 0;
	// ull sum = 0;
	sll sum = 0;
	sll item;
	sll *dpcell;

	if (k * 2 > n + 1) goto fail;

	ull x = k, y = k + n, z = k + n + n;
	for (i = 0; i < n * 2; i++) {
		ull v = (i % n);
		if (i < n) {
			if (v % 2 == 0) {
				a[v] = x;
				x++;
			} else {
				b[v] = y;
				y++;
			}
			c[v] = z;
			z++;
		} else {
			if (v % 2 == 0) {
				b[v] = y;
				y++;
			} else {
				a[v] = x;
				x++;
			}
		}
	}

	for (i = 0; i < n; i++) {
		printf("%llu %llu %llu\n", a[i], b[i], c[i]);
	}

	// printf("%lld\n", result);
	// printf("%.15f\n", dresult);
	// puts(s);

	return 0;

	success:
	puts("YES");
	// puts("Yes");
	// printf("%llu\n", result);
	// puts("0");
	// puts("First");
	return 0;

	fail:
	// puts("NO");
	// puts("No");
	// puts("0");
	puts("-1");
	// puts("-1 -1 -1");
	// puts("Second");
	return 1;
}

int32_t main (int argc, char *argv[]) {
	int32_t i, j;

	n = 3;
	m = 0;

	// scanf("%llu", &m);
	// scanf("%llu%llu", &h, &w);
	scanf("%llu", &n, &m);
	scanf("%llu", &k, &n, &m);
	// scanf("%llu%llu", &h, &w);
	// scanf("%llu", &q);
	// scanf("%lld%lld", &va, &vb, &vc, &vd);
	// va--;
	// vb--;
	// scanf("%llu%llu%llu%llu", &ua, &ub, &uc, &ud, &ue);
	// scanf("%s", s);
	// scanf("%s", t);
	// scanf("%s", u);
	// scanf("%llu", &k);
	// scanf("%lld", &m);
	// for (i = 0; i < n; i++) {
	// 	// scanf("%lld", &a[i]);
	// 	scanf("%lld", &d[i]);
	// }
	// scanf("%llu", &q);
	for (i = 0; i < 0; i++) {
		// scanf("%lld%lld", &xy[i].a, &xy[i].b);
		// scanf("%lld%lld%lld", &tup[i].a, &tup[i].b, &tup[i].c);
		// scanf("%lld", &c[i]);

		scanf("%lld", &a[i]);
		scanf("%lld", &b[i]);
		scanf("%lld", &c[i]);
		// scanf("%lld", &d[i]);
		a[i]--;
		b[i]--;
		// c[i]--;
		// d[i]--;
		// xy[i].a--;
		// xy[i].b--;
		// tup[i].a--;
		// tup[i].b--;
	}
	// scanf("%lld%lld", &va, &vb);
	// scanf("%llu", &m);
	// scanf("%llu", &q);
	// scanf("%s", s);
	// for (i = 0; i < n; i++) {
	// 	// scanf("%lld%lld", &xy[i].a, &xy[i].b);
	// 	// xy[i].a--;
	// 	// xy[i].b--;
	// 	// scanf("%lld", &a[i], &b[i]);
	// 	// scanf("%lld", &b[i]);
	// 	// a[i]--;
	// 	// b[i]--;
	// 	scanf("%lld", &c[i]);
	// 	// scanf("%lld", &d[i]);
	// 	// scanf("%lld", &e[i]);
	// 	// c[i]--;
	// 	// d[i]--;
	// }

	// for (i = 0; i < q; i++) {
	// 	// scanf("%lld%lld", &xy[i].a, &xy[i].b);
	// 	scanf("%lld", &c[i]);
	// 	// xy[i].a--;
	// 	// xy[i].b--;
	// }

	// for (i = 0; i < h; i++) {
	// 	for (j = 0; j < w; j++) {
	// 		scanf("%lld", &table[i][j]);
	// 		// table[i][j]--;
	// 	}
	// }
	// for (i = 0; i < n; i++) {
	// 	scanf("%s", s[i]);
	// }
	// scanf("%llu", &q);

	solve();

	return 0;
}

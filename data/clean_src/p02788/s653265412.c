// ABC 153-F
// 2020.1.26 bal4u

#include <stdio.h>
#include <string.h>

typedef long long ll;

#define gc() getchar_unlocked()

int in() {   // 非負整数の入力
	int n = 0; int c;
	c = gc();
	do n = 10 * n + (c & 0xf); while ((c = gc()) >= '0');
	return n;
}

// セグメント木
#define MAXN (1<<18)      // セグメント木のサイズ。2のべき乗にすべし

int size;
ll segVal[2 * MAXN];
ll segLazy[2 * MAXN];

void segInit(int n)
{
	size = 1; while (size < n) size <<= 1;
//	memset(segVal, 0, sizeof(segVal));
//  memset(segLazy, 0, sizeof(segLazy));
}

void lazy(int k, int width)
{
	int k2 = k << 1;
	if (k2 < (size << 1) - 2) {
		segLazy[k2 + 1] += segLazy[k];
		segLazy[k2 + 2] += segLazy[k];
	}
	segVal[k] += segLazy[k] * width;
	segLazy[k] = 0;
}

ll add(int a, int b, ll x, int k, int l, int r)
{
	ll ans;

	lazy(k, r - l);
	if (r <= a || b <= l) return segVal[k] + segLazy[k] * (r - l);
	if (a <= l && r <= b) {
		segLazy[k] += x;
		return segVal[k] + segLazy[k] * (r - l);
	}
	lazy(k, r - l);
	ans = add(a, b, x, (k << 1) + 1, l, (l + r) >> 1);
	ans += add(a, b, x, (k << 1) + 2, (l + r) >> 1, r);
	return segVal[k] = ans;
}

ll getSum(int a, int b, int k, int l, int r)
{
	ll ans;

	lazy(k, r - l);
	if (r <= a || b <= l) return 0;
	if (a <= l && r <= b) return segVal[k];
	ans = getSum(a, b, (k << 1) + 1, l, (l + r) >> 1);
	ans += getSum(a, b, (k << 1) + 2, (l + r) >> 1, r);
	return ans;
}

typedef struct { int X, H; } T;
T a[200005]; int N;

void Qsort(T *a, int l, int r) {
	int i, j, m; T t;
	
	i = l, j = r, m = a[(l+r) >> 1].X;
	while (1) {
        // 昇順
		while (a[i].X < m) i++;
		while (m < a[j].X) j--;

		if (i >= j)	break;
		t = a[i], a[i] = a[j], a[j] = t;
		i++, j--;
	}
	if (l+1 < i) Qsort(a, l, i-1);
	if (j+1 < r) Qsort(a, j+1, r);
}

// 見つからなければ、一つ小さい要素を返す
int bs(int x) {
	int m, l = 0, r = N;

    while (l < r) {
        m = (l+r) >> 1;
        if (a[m].X <= x) l = m + 1; else r = m;
    }
	return l-1;
}

int main()
{
	int i, A, D;
	ll ans;
	
	N = in(), D = in(), A = in();
	for (i = 0; i < N; ++i) a[i].X = in(), a[i].H = in();
	Qsort(a, 0, N-1);
	
	segInit(N);
	for (i = 0; i < N; ++i) add(i, i+1, a[i].H, 0, 0, N);
	if ((ll)D*2 > a[N-1].X) D = a[N-1].X; else D *= 2;
	
	ans = 0;
	for (i = 0; i < N; ++i) {
		ll h = getSum(i, i+1, 0, 0, N);
		if (h > 0) {
			ll t = (h-1)/A + 1;
			ans += t;
			int j = bs(a[i].X + D);
			add(i, j+1, -t*A, 0, 0, N);
		}
	}
	printf("%lld\n", ans);
	return 0;
}

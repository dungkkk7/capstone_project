// AOJ 0398 Beautiful Sequence
// 2019.3.25 bal4u

#include <stdio.h>
#include <stdlib.h>

#define MOD 1000000007
#define MAX 100000
int p2[MAX+5];
int f[MAX + 5];

int main()
{
	int i, t;
	int N, M;

	// p2[n] = 2^n  (2のペキ乗）
	p2[0] = 1; for (i = 1; i <= MAX; i++) p2[i] = (p2[i - 1] << 1) % MOD;

	scanf("%d%d", &N, &M);

	f[M] = 1;    // 自明

	// f[n] = 2*f[n-1] + 2^(n-m-1)  if n <= 2*m
	for (i = M + 1; i < N && i <= 2 * M; i++) {
		f[i] = ((f[i - 1] << 1) % MOD + p2[i - M - 1]) % MOD;
	}

	// f[n] = 2*f[n-1] + 2^(n-m-1) - f[n-m-1]  if n >= 2*m+1
	for (; i <= N; i++) {
		t = p2[i - M - 1] - f[i - M - 1];
		if (t < 0) t += MOD;
		f[i] = ((f[i - 1] << 1) % MOD + t) % MOD;
	}
	printf("%d\n", f[N]);
	return 0;
}

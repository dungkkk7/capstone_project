// AOJ 2870 The Diversity of Prime Factorization
// 2018.3.29 bal4u

#include <stdio.h>
#include <string.h>

//#define getchar_unlocked()  getchar()
int in()
{
	int n = 0, c = getchar_unlocked();
	do n = 10*n + (c & 0xf), c = getchar_unlocked(); while (c >= '0');
	return n;
}

#define M 1000000007
char prime[1000010];         // prime table
int  q[100005];
int dp[100005];

void mkprime()
{
#define MAX  1000005
#define SQRT 1000	     // sqrt(MAX)
	int i, j;

	memset(prime+2, 1, 1000003);
	for (i = 4; i <= MAX; i += 2) prime[i] = 0;
	for (i = 3; i <= SQRT; i += 2) {
		for (j = i*i; j <= MAX; j += i) prime[j] = 0;  // j = i*i !!!!!
	}
}

int main()
{
	int N, i;

	mkprime();

	N = in();
	for (i = 0; i < N; i++) q[i] = in();
	q[N] = 1000003;

	dp[0] = 1;
	for (i = 0; i < N; i++) if (prime[q[i]]) {
		if (prime[q[i+1]] && q[i] < q[i+1]) {
			dp[i+1] += dp[i]; if (dp[i+1] >= M) dp[i+1] -= M;
		}
		if (prime[q[i+2]] && q[i] < q[i+2]) {
			dp[i+2] += dp[i]; if (dp[i+2] >= M) dp[i+1] -= M;
		}
	}
	printf("%d\n", dp[N]);
	return 0;
}

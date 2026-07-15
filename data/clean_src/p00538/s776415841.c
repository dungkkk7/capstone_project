#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#define S_MAX 1000
#define N_MAX 2000
#define M_MAX 100000
#define INF 2000000000
#define MOD 1000000007
#define SMAP(a, b) ((a)!=(b))&&((a)^=((b)^=((a)^= (b))))

typedef unsigned long long ull;
typedef   signed long long dll;

typedef struct {
	int a;
	int b;
	int c;
} moneydata;

int n, m;
int h, w;
int i, j;
int k;

ull a[N_MAX];
ull dp[N_MAX][N_MAX]; // dp[i][j] := a[i] kara a[i + 2j + b] madede JOIkun ga IOIchan wo ryonareru MAX

ull max(ull a, ull b){
	return (a > b) ? a : b;
}

ull min(ull a, ull b){
	return (a < b) ? a : b;
}

void solve(){
	const int nbool = (n & 1) ^ 1;
	int rangelen;
	ull result = 0;

	switch (nbool) {
	case 0:
		for (i = 0; i < n; i++) {
			dp[i][0] = a[i];
		}
		break;
	case 1:
		for (i = 0; i < n; i++) {
			dp[i][0] = max(a[i], a[(i + 1) % n]);
		}
		break;
	}

	for (rangelen = 1; (rangelen << 1) + nbool < n; rangelen++) {
		for (i = 0; i < n; i++) {
			ull lc, rc;
			if (a[(i + (rangelen << 1) + nbool) % n] > a[(i + 1) % n]) {
				lc = dp[(i + 1) % n][rangelen - 1];
			} else {
				lc = dp[(i + 2) % n][rangelen - 1];
			}
			if (a[(i + (rangelen << 1) + nbool - 1) % n] > a[i]) {
				rc = dp[i][rangelen - 1];
			} else {
				rc = dp[(i + 1) % n][rangelen - 1];
			}
			dp[i][rangelen] = max(
				a[i] + lc, a[(i + (rangelen << 1) + nbool) % n] + rc);
		}
	}

	// for (i = 0; i < n; i++) {
	// 	printf("[%d] ", i);
	// 	for (rangelen = 0; (rangelen << 1) + nbool < n; rangelen++) {
	// 		printf("%d ", dp[i][rangelen]);
	// 	}
	// 	putchar('\n');
	// }

	for (i = 0; i < n; i++) {
		result = max(result, dp[i][((n + 1) >> 1) - 1]);
	}

	printf("%llu\n", result);

	return;
}

int main (void) {
	scanf("%d", &n);
	for (i = 0; i < n; i++) scanf("%llu", &a[i]);
	
	solve();
	
	return 0;
}
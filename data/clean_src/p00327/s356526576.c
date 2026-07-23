// AOJ 0332: Disappearing Sequence
// 2017.10.28 bal4u@uu

#include <stdio.h>

int c[102];
char dp[102][102];
 
int main()
{
	int n, i, j, k, m;

	scanf("%d", &n);
	for (i = 0; i < n; i++) scanf("%d", c+i);
    for (i = 1; i < n; i++) if (c[i-1] == c[i]) dp[i-1][i+1] = 1;
    for (m = 2; m <= n; m++) for (i = 0; i <= n-m; i++) {
		j = i+m;
		for (k = i+1; k < j; k++) {
			dp[i][j] |= dp[i][k] & dp[k][j];
			if (c[i] == c[j-1]) {
				dp[i][j] |= dp[i+1][j-1];
				if (c[i] == c[k]) dp[i][j] |= dp[i+1][k] & dp[k+1][j-1];
			}
		}
		if (c[i] && c[j-1]) {
			if (i > 0 && c[i-1] == c[i]) dp[i-1][k] |= dp[i][j];
			if (j < n && c[j-1] == c[j]) dp[i][j+1] |= dp[i][j];
		}
	}
	puts(dp[0][n] ? "yes" : "no");
    return 0;
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* constant */

#define MAX_C	(15)
#define MAX_D	(30)
#define MAX_W	(50)
#define MAX_X	(5)

/* typedef */

/* global variables */

static int es[MAX_C][MAX_D];
static int fs[MAX_C][MAX_D];
static int dp[MAX_D + 1][MAX_W + 1][MAX_X + 1];

/* subroutines */

/* main */

int main(int argc, char **argv) {
  int c, d, i, j, k, r, w, x;
  int dp0, dp1, dpijk, j0, j1, r1;
  int max_dp, dpdjk;
  
  for (;;) {
    scanf("%d", &c);
    scanf("%d", &d);
    scanf("%d", &w);
    scanf("%d", &x);

    if ((c | d | w | x) == 0) break;

    for (i = 0; i < c; i++)
      for (j = 0; j < d; j++)
	scanf("%d", &(es[i][j]));

    for (i = 0; i < c; i++)
      for (j = 0; j < d; j++)
	scanf("%d", &(fs[i][j]));

    for (i = 0; i <= d; i++)
      for (j = 0; j <= w; j++)
	for (k = 0; k <= x; k++)
	  dp[i][j][k] = -1;
    dp[0][0][0] = 0;

    for (i = 0; i < d; i++)
      for (j = 0; j <= w; j++)
	for (k = 0; k <= x; k++) {
	  dpijk = dp[i][j][k];
	  if (dpijk < 0) continue;

	  if (dp[i + 1][j][k] < dpijk) dp[i + 1][j][k] = dpijk;

	  for (r = 0; r < c; r++) {
	    if (es[r][i] == 0) continue;
	    j0 = j + fs[r][i];
	    if (j0 <= w) {
	      dp0 = dpijk + es[r][i];
	      if (dp[i + 1][j0][k] < dp0) dp[i + 1][j0][k] = dp0;

	      if (k == x) continue;

	      dp1 = dp0;
	      j1 = j0;

	      for (r1 = r + 1; r1 < c; r1++) {
		if (es[r1][i] == 0) break;
		dp1 += es[r1][i];
		j1 += fs[r1][i];
		if (j1 > w) break;
		if (dp[i + 1][j1][k + 1] < dp1) dp[i + 1][j1][k + 1] = dp1;
	      }

	      dp1 = dp0;
	      j1 = j0;

	      for (r1 = r - 1; r1 >= 0; r1--) {
		if (es[r1][i] == 0) break;
		dp1 += es[r1][i];
		j1 += fs[r1][i];
		if (j1 > w) break;
		if (dp[i + 1][j1][k + 1] < dp1) dp[i + 1][j1][k + 1] = dp1;
	      }
	    }
	  }
	}

    max_dp = 0;
    for (j = 0; j <= w; j++)
      for (k = 0; k <= x; k++) {
	dpdjk = dp[d][j][k];
	if (max_dp < dpdjk) max_dp = dpdjk;
      }

    printf("%d\n", max_dp);
  }

  return 0;
}
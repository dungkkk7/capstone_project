#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<inttypes.h>
#include<string.h>

typedef int32_t i32;
typedef int64_t i64;

const i32 mod = 1000000007;

#define ADD(x, a) do{(x) += (a); if ((x) >= mod) (x) -= mod;} while (0)

i32 mod_pow (i32 r, i32 n) {
  i32 t = 1;
  i32 s = r;
  while (n > 0) {
    if (n & 1) t = (i64) t * s % mod;
    s = (i64) s * s % mod;
    n >>= 1;
  }
  return t;
}

i32 inv (i32 a) {
  return mod_pow (a, mod - 2);
}

#define ALLOC(size,type) ((type*)calloc((size),sizeof(type)))

#define POS(i, j) (((i) & 1) * (n + 1) + (j))

void run (void) {
  i32 n;
  scanf ("%" SCNi32, &n);
  char *s = ALLOC (n + 1, char);
  scanf ("%s", s);
  i32 k = strlen (s);
  free (s);
  i32 *dp = ALLOC (2 * (n + 1), i32);
  dp[POS(0, 0)] = 1;
  for (i32 i = 1; i <= n; ++i) {
    memset (dp + POS(i, 0), 0, sizeof (i32) * (n + 1));
    ADD(dp[POS(i, 0)], dp[POS(i - 1, 0)]);
    ADD(dp[POS(i, 1)], dp[POS(i - 1, 0)]);
    ADD(dp[POS(i, 1)], dp[POS(i - 1, 0)]);
    for (i32 j = 1; j < i; ++j) {
      ADD(dp[POS(i, j - 1)], dp[POS(i - 1, j)]);
      ADD(dp[POS(i, j + 1)], dp[POS(i - 1, j)]);
      ADD(dp[POS(i, j + 1)], dp[POS(i - 1, j)]);
    }
  }
  i32 ans = (i64) dp[POS(n, k)] * mod_pow (inv (2), k) % mod;
  printf ("%" PRIi32 "\n", ans);
}

int main (void) {
  run();
  return 0;
}

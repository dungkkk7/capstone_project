#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<inttypes.h>

typedef int32_t i32;
typedef int64_t i64;
typedef uint64_t u64;

void set_at (u64 *b, i32 k) {
  b[k >> 6] |= (u64) 1 << (k & 63);
}

i32 get_at (u64 *b, i32 k) {
  return (b[k >> 6] >> (k & 63)) & 1;
}

int func (u64 * restrict a, u64 * restrict b, u64 * restrict c, i32 l, i32 r) {
  const u64 t = ~(u64)0;
  if (l / 64 == r / 64) {
    return (((a[l / 64] & b[l / 64] & c[l / 64]) >> (l & 63)) & (t >> (64 - (r - l + 1)))) != 0;
  }
  i32 k = l / 64;
  u64 x = (a[k] & b[k] & c[k]) >> (l & 63);
  if (x) return 1;
  k = r / 64;
  x = (a[k] & b[k] & c[k]) & (t >> (63 - r));
  if (x) return 1;
  for (i32 i = (l + 64) / 64 * 64; i + 63 <= r; i += 64) {
    if ((a[i / 64] & b[i / 64] & c[i / 64]) != 0) {
      return 1;
    }
  }
  return 0;
}

void run (void) {
  i32 n;
  scanf ("%" SCNi32, &n);
  i32 len = (n + 63) / 64;
  u64 *array = (u64 *) calloc (3 * n * len, sizeof (u64));
  u64 **win = (u64 **) calloc (n, sizeof (u64 *));
  for (i32 i = 0; i < n; ++i) {
    win[i] = array;
    array += len;
  }
  char *s = (char *) calloc (n + 1, sizeof (char));
  for (i32 i = 1; i < n; ++i) {
    scanf ("%s", s);
    for (i32 j = 0; j < i; ++j) {
      if (s[j] == '0') {
        set_at (win[j], i);
      } else {
        set_at (win[i], j);
      }
    }
  }
  u64 **dpL = (u64 **) calloc (n, sizeof (u64 *));
  u64 **dpR = (u64 **) calloc (n, sizeof (u64 *));
  for (i32 i = 0; i < n; ++i) {
    dpL[i] = array;
    array += len;
    set_at (dpL[i], i);
    dpR[i] = array;
    array += len;
    set_at (dpR[i], i);
  }
  for (i32 len = 2; len <= n; ++len) {
    for (i32 l = 0; l + len - 1 < n; ++l) {
      i32 r = l + len - 1;
      if (func (win[l], dpR[l + 1], dpL[r], l + 1, r)) {
	set_at (dpL[r], l);
      }
      if (func (win[r], dpR[l], dpL[r - 1], l, r - 1)) {
	set_at (dpR[l], r);
      }
    }
  }
  i32 ans = 0;
  for (i32 i = 0; i < n; ++i) {
    ans += get_at (dpR[0], i) & get_at (dpL[n - 1], i);
  }
  printf ("%" PRIi32 "\n", ans);
}

int main (void) {
  run();
  return 0;
}

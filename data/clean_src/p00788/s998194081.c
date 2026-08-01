#include <stdio.h>
#include <stdint.h>

#define SQ(X) \
  ( (X) * (X) )
#define REDUCE(N,D) \
  { const int G__19 = gcd ( N, D ); \
    (N) /= G__19; (D) /= G__19; \
  }

#if 0
static int
sqrt2 (
  uint64_t a
  )
{
  uint64_t res = a;

  while ( a < SQ( res ) || a >= SQ( res + 1 ) )
  {
    res = ( SQ( res ) + a ) / 2 / res;
  }

  return ( res );
}
#endif

static int
sqrt3 (
  uint64_t a,
  uint64_t w
  )
{
  uint64_t res = a * w;

  a *= SQ( w );
  while ( a < SQ( res ) || a >= SQ( res + 1 ) )
  {
    res = ( SQ( res ) + a ) / 2 / res;
  }

  return ( res );
}

static int
gcd (
  int a,
  int b
  )
{
  do
  {
    const int t = a;
    a = b % a;
    b = t;
  }
  while ( a );

  return ( b );
}

/** Application main entry point. */
int
main (
  int     argc,
  char  * argv[ ]
  )
{
  int i;

  for ( ; ; )
  {
    int ln = 0,     ld = 1
      , un = 10000, ud = 1;
    int p, n;

    scanf ( "%d%d", &p, &n );
    if ( !( p | n ) ) break ;

    for ( i = 1; i <= n; ++i )
    {
      int t = sqrt3 ( p, i );

      if ( t > n ) continue ;

      if ( t * ld > ln * i )
        { ln = t; ld = i; }
      if ( t < n && ( t + 1 ) * ud < un * i )
        { un = t + 1; ud = i; }
    }

    REDUCE( ln, ld ); REDUCE( un, ud );
    printf ( "%d/%d %d/%d\n", un, ud, ln, ld );
  }

  return ( 0 );
}
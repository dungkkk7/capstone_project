#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BLN 65536

static char *p;
static char *query;
static char buffer[ BLN ];

struct line
{
  int ind;
  char *a;
  char *b;
};
typedef struct line line;
static line lp[ BLN ];
static int ln = 0;

int
main (
  int   argc,
  char *argv[ ]
  )
{
  char *q, *nq;
  int b, lv;

  for ( p = buffer; ; )
  {
    q = fgets ( p, BLN - ( p - buffer ), stdin );
    if ( q == NULL ) break ;
    p = q + strlen ( q );
  }

  query = buffer;
  p = strchr ( buffer, '\n' );
  *( p++ ) = '\0';

  for ( ; *p != '\0' ; ++ln )
  {
    for ( lp[ ln ].ind = 0; *p == ' '; ++lp[ ln ].ind, ++p ) ;
    lp[ ln ].a = p;
    p = strchr ( p, ':' );
    *( p++ ) = '\0';
    if ( *p == '\n' )
    {
      lp[ ln ].b = NULL;
      ++p;
    }
    else
    {
      lp[ ln ].b = ++p;
      p = strchr ( p, '\n' );
      *( p++ ) = '\0';
    }
  }

  lv = 0; ++query;
  nq = strchr ( query, '.' );
  if ( nq != NULL )
    *( nq++ ) = '\0';
  for ( b = 0; b < ln; ++b )
  {
    if ( lp[ b ].ind < lv )
    {
      b = ln;
      continue ;
    }
    else if ( lp[ b ].ind > lv )
      continue ;

    if ( !strcmp ( lp[ b ].a, query ) )
    {
      if ( nq == NULL )
      {
        if ( lp[ b ].b == NULL )
          puts ( "object" );
        else
          printf ( "string \"%s\"\n", lp[ b ].b );
        break ;
      }
      else if ( lp[ b ].b != NULL )
      {
        b = ln;
        continue ;
      }

      query = nq;

      nq = strchr ( query, '.' );
      if ( nq != NULL )
        *( nq++ ) = '\0';

      lv = lp[ b + 1 ].ind;
    }
  }
  if ( b >= ln )
    puts ( "no such property" );

  return ( EXIT_SUCCESS );
}
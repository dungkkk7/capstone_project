#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

int VAR00 [ 1000 ] [ 2 ] ;

void FUNC00 ( int * , int , int ) ;

void FUNC01 ( int * , int , int , int ) ;

void FUNC02 ( int * , int , int ) ;

long FUNC03 ( int * , int * , int ) ;

int FUNC04 ( int * , int * , int ) ;

long FUNC05 ( int * ) ;

long FUNC06 ( int * , int * , int ) ;

long FUNC07 ( int * , int * , int , long ) ;

long FUNC08 ( int * , int * , int ) ;

int main ( )
{
  int VAR01 , VAR02 , * VAR03 , * VAR04 ;

  long VAR05 ;

  scanf ( "%d" , & VAR02 ) ;

  VAR03 = ( int * ) malloc ( sizeof ( int ) * VAR02 ) ;
  VAR04 = ( int * ) malloc ( sizeof ( int ) * VAR02 ) ;

  for ( VAR01 = 0 ; VAR01 < VAR02 ; VAR01 ++ )
    {
      scanf ( "%d" , VAR03 + VAR01 ) ;
      VAR04 [ VAR01 ] = VAR03 [ VAR01 ] ;
    }

  FUNC02 ( VAR04 , 0 , VAR02 ) ;

  VAR05 = FUNC08 ( VAR03 , VAR04 , VAR02 ) ;
  VAR05 += FUNC07 ( VAR03 , VAR04 , VAR02 , 0 ) ;

  printf ( "%ld\n" , VAR05 ) ;

  return 0 ;
}

void FUNC00 ( int * ARG00 , int ARG01 , int ARG02 ) {

  int VAR06 ;

  VAR06 = ARG00 [ ARG01 ] ;
  ARG00 [ ARG01 ] = ARG00 [ ARG02 ] ;
  ARG00 [ ARG02 ] = VAR06 ;
}

void FUNC01 ( int * ARG03 , int ARG04 , int ARG05 , int ARG06 ) {

  int VAR07 , VAR08 , * VAR09 , * VAR10 , VAR11 , VAR12 , VAR13 ;

  VAR07 = ARG05 - ARG04 ;
  VAR08 = ARG06 - ARG05 ;
  VAR09 = ( int * ) malloc ( sizeof ( int ) * ( VAR07 + 1 ) ) ;
  VAR10 = ( int * ) malloc ( sizeof ( int ) * ( VAR08 + 1 ) ) ;

  for ( VAR11 = 0 ; VAR11 < VAR07 ; VAR11 ++ ) {
    VAR09 [ VAR11 ] = ARG03 [ ARG04 + VAR11 ] ;
  }
  for ( VAR11 = 0 ; VAR11 < VAR08 ; VAR11 ++ ) {
    VAR10 [ VAR11 ] = ARG03 [ ARG05 + VAR11 ] ;
  }

  VAR09 [ VAR07 ] = INT_MAX ; VAR10 [ VAR08 ] = INT_MAX ;

  VAR11 = 0 ;
  VAR12 = 0 ;

  for ( VAR13 = ARG04 ; VAR13 < ARG06 ; VAR13 ++ )
    {
      if ( VAR09 [ VAR11 ] < VAR10 [ VAR12 ] ) {
 ARG03 [ VAR13 ] = VAR09 [ VAR11 ] ;
 VAR11 ++ ;
      } else {
 ARG03 [ VAR13 ] = VAR10 [ VAR12 ] ;
 VAR12 ++ ;
      }
    }
  free ( VAR09 ) ;
  free ( VAR10 ) ;
}

void FUNC02 ( int * ARG07 , int ARG08 , int ARG09 ) {
  if ( ARG08 + 1 < ARG09 )
    {
      int VAR14 = ( ARG08 + ARG09 ) / 2 ;

      FUNC02 ( ARG07 , ARG08 , VAR14 ) ;
      FUNC02 ( ARG07 , VAR14 , ARG09 ) ;
      FUNC01 ( ARG07 , ARG08 , VAR14 , ARG09 ) ;
    }
}

long FUNC03 ( int * ARG10 , int * ARG11 , int ARG12 ) {

  int VAR15 , VAR16 ;

  long VAR17 = 0 ;

  VAR16 = 0 ;

  while ( ARG10 [ ARG12 ] != ARG11 [ ARG12 ] ) {
    VAR15 = 0 ;
    while ( ARG10 [ VAR15 ] != ARG11 [ ARG12 ] ) VAR15 ++ ;

    VAR17 += ARG10 [ ARG12 ] + ARG10 [ VAR15 ] ;
    FUNC00 ( ARG10 , ARG12 , VAR15 ) ;
    VAR00 [ VAR16 ] [ 0 ] = ARG12 ;
    VAR00 [ VAR16 ] [ 1 ] = VAR15 ;
    ARG12 = VAR15 ;
    VAR16 ++ ;
  }
  VAR00 [ VAR16 ] [ 0 ] = 0 ;
  VAR00 [ VAR16 ] [ 1 ] = 0 ;
  return VAR17 ;
}

int FUNC04 ( int * ARG13 , int * ARG14 , int ARG15 ) {

  int VAR18 , VAR19 ;

  VAR18 = 0 ;

  while ( 1 ) {
    VAR19 = 0 ;
    while ( ARG13 [ VAR19 ] != ARG14 [ VAR18 ] ) VAR19 ++ ;
    if ( VAR18 != VAR19 ) break ;
    VAR18 ++ ;
    if ( VAR18 >= ARG15 ) return ARG15 ;
  }
  return VAR19 ;
}

long FUNC05 ( int * ARG16 ) {

  int VAR20 = 0 ;

  long VAR21 = 0 ;

  while ( VAR00 [ VAR20 ] [ 0 ] != VAR00 [ VAR20 ] [ 1 ] )
    {
      VAR21 += ARG16 [ VAR00 [ VAR20 ] [ 0 ] ] + ARG16 [ VAR00 [ VAR20 ] [ 1 ] ] ;
      FUNC00 ( ARG16 , VAR00 [ VAR20 ] [ 0 ] , VAR00 [ VAR20 ] [ 1 ] ) ;
      VAR20 ++ ;
    }
  return VAR21 ;
}

long FUNC06 ( int * ARG17 , int * ARG18 , int ARG19 ) {

  long VAR22 ;

  if ( ARG17 [ 0 ] != ARG18 [ 0 ] ) return LONG_MAX ;

  int VAR23 = 0 ;

  while ( ARG17 [ ARG19 ] != ARG18 [ VAR23 ] ) VAR23 ++ ;

  VAR22 = ARG17 [ ARG19 ] + ARG17 [ 0 ] ;
  FUNC00 ( ARG17 , ARG19 , 0 ) ;
  VAR22 += FUNC05 ( ARG17 ) ;
  VAR22 += ARG17 [ 0 ] + ARG17 [ VAR23 ] ;
  FUNC00 ( ARG17 , 0 , VAR23 ) ;

  return VAR22 ;
}

long FUNC07 ( int * ARG20 , int * ARG21 , int ARG22 , long ARG23 ) {

  int VAR24 ;
  int VAR25 [ ARG22 ] ;
  long VAR26 , VAR27 ;

  for ( VAR24 = 0 ; VAR24 < ARG22 ; VAR24 ++ ) {
    VAR25 [ VAR24 ] = ARG20 [ VAR24 ] ;
  }

  VAR24 = FUNC04 ( ARG20 , ARG21 , ARG22 ) ;

  if ( VAR24 == ARG22 ) return ARG23 ;

  VAR26 = FUNC03 ( ARG20 , ARG21 , VAR24 ) ;
  VAR27 = FUNC06 ( VAR25 , ARG21 , VAR24 ) ;

  long VAR28 = ( VAR26 < VAR27 ) ? VAR26 : VAR27 ;

  return FUNC07 ( ARG20 , ARG21 , ARG22 , ARG23 + VAR28 ) ;
}

long FUNC08 ( int * ARG24 , int * ARG25 , int ARG26 ) {

  int VAR29 , VAR30 ;
  long VAR31 = 0 ;
  char * VAR32 = ( char * ) calloc ( ARG26 , sizeof ( char ) ) ;

  VAR29 = 0 ;

  while ( VAR29 < ARG26 ) {
    VAR30 = 0 ;
    while ( ARG24 [ VAR30 ] != ARG25 [ VAR29 ] ) VAR30 ++ ;

    if ( VAR29 != VAR30 ) {
      if ( ARG25 [ VAR30 ] == ARG24 [ VAR29 ] ) {
 VAR31 += ARG24 [ VAR29 ] + ARG24 [ VAR30 ] ;
 FUNC00 ( ARG24 , VAR29 , VAR30 ) ;
      }
    }
    VAR32 [ VAR29 ] = 1 ;
    VAR32 [ VAR30 ] = 1 ;
    while ( VAR29 < ARG26 && VAR32 [ VAR29 ] != 0 ) VAR29 ++ ;
  }
  free ( VAR32 ) ;
  return VAR31 ;
}

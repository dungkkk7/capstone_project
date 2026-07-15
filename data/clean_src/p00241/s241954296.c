#include <stdio.h>

int x3;
int y3;
int z3;
int w3;

void multi( int a, int b, int c, int d, int e, int f, int g, int h );
void get( int* inx3, int* iny3, int* inz3, int* inw3 );

int main( void )
{
	int numOfPear;
	
	int x1;
	int x2;
	int y1;
	int y2;
	int z1;
	int z2;
	int w1;
	int w2;
	
	int out[4];
	
	int i;
	
	while( 1 )
	{
		scanf( "%d", &numOfPear );
		if( numOfPear == 0 )break;
		
		for( i = 0; i < numOfPear; i++ )
		{
			scanf( "%d%d%d%d%d%d%d%d", &x1, &y1, &z1, &w1, &x2, &y2, &z2, &w2 );
			multi( x1, y1, z1, w1, x2, y2, z2, w2 );
			
			get( &out[0], &out[1], &out[2], &out[3] );
			printf( "%d %d %d %d\n", out[0], out[1], out[2], out[3] );
		}
	}
	return (0);
}

void multi( int a, int b, int c, int d, int e, int f, int g, int h )
{
	x3 = (a * e) - (b * f) - (c * g) - (d * h);
	y3 = (a * f) + (b * e) + (c * h) - (d * g);
	z3 = (a * g) - (b * h) + (c * e) + (d * f);
	w3 = (a * h) + (b * g) - (c * f) + (d * e);
}

void get( int* inx3, int* iny3, int* inz3, int* inw3 )
{
	*inx3 = x3;
	*iny3 = y3;
	*inz3 = z3;
	*inw3 = w3;
}
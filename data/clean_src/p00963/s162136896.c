// AOJ 1384 Rendezvous on a Tetrahedron
// 2018.4.6 bal4u

#include <stdio.h>
#include <math.h>

#define BASE     100
#define PI180    0.01745329251994329576923690768489    // PI/180
#define tan60	 (sqrt(3))				// tan 60 = sqrt(3)
#define sin60    (sqrt(3)/2)			// sin 60 = sqrt(3)/2

#define A 0
#define B 1
#define C 2
#define D 3
int ans[2][2][2] = { B,A,C,D,D,C,A,B };

int calc(char *edge, int d, int l)
{
	int ix, iy, one;
	double delta, x, y;

	if      (*edge == 'D') d += 60;
	else if (*edge == 'B') d += 120;
	delta = d * PI180;			// d/180*PI

	x = BASE + l * (cos(delta) - sin(delta)/tan60);
	y = l * sin(delta)/sin60;

	ix = (int)x, iy = (int)y;
	one = ((x-ix) + (y-iy)) >= 1;
	return ans[ix&1][iy&1][one];
}

int main()
{
	int d, l, fp, fq;
	char edge[5];

	scanf("%s%d%d", edge, &d, &l);
	fp = calc(edge, d, l);
	scanf("%s%d%d", edge, &d, &l);
	fq = calc(edge, d, l);
	puts(fp == fq? "YES": "NO");
	return 0;
}

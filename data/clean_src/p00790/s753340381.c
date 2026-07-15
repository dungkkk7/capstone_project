// AOJ 1210: Die Game
// 2017.10.15

#include <stdio.h>

//char t[7] = { 0, 's', 'w', 'e', 'n' };
char tr['z'];

int rot[5][7] = { { 0,1,2,3,4,5,6 },
{ 0,2,6,3,4,1,5 },{ 0,4,2,1,6,5,3 },{ 0,3,2,6,1,5,4 },{ 0,5,1,3,4,6,2 } };
	
int main()
{
	int n, i, j, k1, k2;
	int dice[2][7];
	char b[10];

	tr['s'] = 1, tr['w'] = 2, tr['e'] = 3, tr['n'] = 4;
	while (scanf("%d", &n) && n > 0) {
		for (i = 1; i <= 6; i++) dice[0][i] = i;
		for (k1 = 0, k2 = 1; n-- > 0; k1 = k2, k2 = !k2) {
			scanf("%s", b); j = tr[*b];
			for (i = 1; i <= 6; i++) dice[k2][i] = dice[k1][rot[j][i]];
		}
		printf("%d\n", dice[k1][1]);
	}
	return 0;
}
#include <stdio.h>

int proc_x[2] = {1, 0};
int proc_y[2] = {0, 1};

int done[128][128][3][2];
int memo[128][128][3][2];

int num(int w, int h, int x, int y, int angle, int turn)
{
	int r, u;
	
	if (done[x][y][angle][turn]){
		return (memo[x][y][angle][turn]);
	}
	
	if (x == w && y == h){
		return (1);
	}
	
	if (x > w || y > h){
		return (0);
	}
	
	done[x][y][angle][turn] = 1;
	
	if (angle == 2){
		memo[x][y][angle][turn] = (num(w, h, x + 1, y, 0, 0) + num(w, h, x, y + 1, 1, 0)) % 100000;
		
		return (memo[x][y][angle][turn]);
	}
	
	if (turn == 0) {
		memo[x][y][angle][turn] = (num(w, h, x + proc_x[angle], y + proc_y[angle], angle, 0)
		+ num(w, h, x + proc_x[!angle], y + proc_y[!angle], !angle, 1)) % 100000;
		return (memo[x][y][angle][turn]);
	}
	
	memo[x][y][angle][turn] = num(w, h, x + proc_x[angle], y + proc_y[angle], angle, 0) % 100000;
	
	return (memo[x][y][angle][turn]);
}

int main(void)
{
	int w, h;
	int i, j, k, l;
	
	while (1){
		scanf("%d %d", &w, &h);
		
		if (!w && !h){
			break;
		}
		
		for (i = 0; i < 128; i++){
			for (j = 0; j < 128; j++){
				for (k = 0; k < 3; k++){
					for (l = 0; l < 2; l++){
						done[i][j][k][l] = 0;
						memo[i][j][k][l] = 0;
					}
				}
			}
		}
		
		printf("%d\n", num(w, h, 1, 1, 2, 0));
	}
	
	return (0);
}
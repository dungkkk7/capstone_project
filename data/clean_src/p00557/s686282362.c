#include <stdio.h>
#include <stdlib.h>

const int d[4][2] = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}};

int H, W;
int M[1024][1024];

int count = 0;
int counted[1024][1024];
int visited[1024][1024];

int queue[1024 * 1024][2];

void nuru(int sy, int sx, int num) {
	int queue_start, queue_end;
	int i;
	queue_start = 0;
	queue_end = 1;
	queue[0][0] = sy;
	queue[0][1] = sx;
	if (visited[sy][sx] != 0 && counted[sy][sx] == 0) {
		count++;
		counted[sy][sx] = 1;
	}
	visited[sy][sx] = num;
	while (queue_start < queue_end) {
		int y = queue[queue_start][0];
		int x = queue[queue_start][1];
		queue_start++;
		for (i = 0; i < 4; i++) {
			int ny = y + d[i][0];
			int nx = x + d[i][1];
			if (M[y][x] < M[ny][nx] && visited[ny][nx] != num) {
				int already_one = 0;
				if (visited[ny][nx] != 0 && counted[ny][nx] == 0) {
					count++;
					counted[ny][nx] = 1;
				} else {
					if (counted[ny][nx]) already_one = 1;
				}
				visited[ny][nx] = num;
				if (!already_one) {
					queue[queue_end][0] = ny;
					queue[queue_end][1] = nx;
					queue_end++;
				}
			}
		}
	}
}

int main(void) {
	int i, j, k;
	if (scanf("%d%d", &H, &W) != 2) return 1;
	for (i = 1; i <= H; i++) {
		for (j = 1; j <= W; j++) {
			if (scanf("%d", &M[i][j]) != 1) return 1;
		}
	}

	for (i = 1; i <= H; i++) {
		for (j = 1; j <= W; j++) {
		int tomatuharuka = 0;
			for (k = 0; k < 4; k++) {
				int y = i + d[k][0];
				int x = j + d[k][1];
				if (M[y][x] == 0 || M[i][j] < M[y][x]) {
					tomatuharuka++;
				}
			}
			if (tomatuharuka == 4) {
				nuru(i, j, M[i][j]);
			}
		}
	}

	printf("%d\n", count);
	return 0;
}
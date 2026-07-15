#include <stdio.h>

#define USER_NUM 100
#define DATA_NUM 100

#define NODE_NUM (USER_NUM + DATA_NUM)

int nyaaan[NODE_NUM][NODE_NUM];

int main(void) {
	int N;
	int i, j, k;
	if (scanf("%d", &N) != 1) return 1;
	for (i = 0; i < NODE_NUM; i++) {
		for (j = 0; j < NODE_NUM; j++) {
			nyaaan[i][j] = NODE_NUM * 10;
		}
		nyaaan[i][i] = 0;
	}
	for (i = 0; i < N; i++) {
		int u, d;
		char lock[16];
		if (scanf("%d%s%d", &u, lock, &d) != 3) return 1;
		u--;
		d--;
		if (lock[0] == 'l') {
			/* lock : data -> user */
			nyaaan[d + USER_NUM][u] = -1;
		} else {
			/* wait : user -> data */
			nyaaan[u][d + USER_NUM] = -1;
		}
	}
	for (k = 0; k < NODE_NUM; k++) {
		for (i = 0; i < NODE_NUM; i++) {
			for (j = 0; j < NODE_NUM; j++) {
				if (nyaaan[i][j] > nyaaan[i][k] + nyaaan[k][j]) {
					nyaaan[i][j] = nyaaan[i][k] + nyaaan[k][j];
				}
			}
		}
	}
	for (i = 0; i < NODE_NUM; i++) {
		if (nyaaan[i][i] < 0) {
			puts("1");
			return 0;
		}
	}
	puts("0");
	return 0;
}
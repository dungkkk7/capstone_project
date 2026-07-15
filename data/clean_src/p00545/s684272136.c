#include <stdio.h>
#include <inttypes.h>

int N;
int64_t T;
int Q;

int64_t A[114514];
int D[114514];

int X[1024];

int scNum;
int64_t stopPoints[114514];

int main(void) {
	int i;
	if (scanf("%d%" SCNd64 "%d", &N, &T, &Q) != 3) return 1;
	for (i = 1; i <= N; i++) {
		if (scanf("%" SCNd64 "%d", &A[i], &D[i]) != 2) return 1;
	}
	for (i = 0; i < Q; i++) {
		if (scanf("%d", &X[i]) != 1) return 1;
	}
	for (i = 1; i < N; i++) {
		if (D[i] == 1 && D[i + 1] == 2) {
			stopPoints[scNum++] = A[i] + (A[i + 1] - A[i]) / 2;
		}
	}
	for (i = 0; i < Q; i++) {
		int idx = X[i];
		if (D[idx] == 1) {
			if (stopPoints[scNum - 1] < A[idx]) {
				printf("%" PRId64 "\n", A[idx] + T);
			} else {
				int left = 0, right = scNum - 1;
				int64_t sumipe;
				if (A[idx] < stopPoints[0]) {
					right = 0;
				} else {
					while (left + 1 < right) {
						int mid = left + (right - left) / 2;
						if (A[idx] < stopPoints[mid]) right = mid; else left = mid;
					}
				}
				sumipe = stopPoints[right] - A[idx];
				if (T < sumipe) sumipe = T;
				printf("%" PRId64 "\n", A[idx] + sumipe);
			}
		} else {
			if (A[idx] < stopPoints[0]) {
				printf("%" PRId64 "\n", A[idx] - T);
			} else {
				int left = 0, right = scNum - 1;
				int64_t sumipe;
				if (stopPoints[scNum - 1] < A[idx]) {
					left = scNum - 1;
				} else {
					while (left + 1 < right) {
						int mid = left + (right - left) / 2;
						if (A[idx] < stopPoints[mid]) right = mid; else left = mid;
					}
				}
				sumipe = A[idx] - stopPoints[left];
				if (T < sumipe) sumipe = T;
				printf("%" PRId64 "\n", A[idx] - sumipe);
			}
		}
	}
	return 0;
}


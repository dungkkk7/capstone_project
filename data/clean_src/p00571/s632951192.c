#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

struct bizyutuhin_t {
	int64_t A, B;
};

int cmp(const void* x, const void* y) {
	int64_t a = ((const struct bizyutuhin_t*)x)->A;
	int64_t b = ((const struct bizyutuhin_t*)y)->A;
	return a < b ? -1 : a > b;
}

int32_t N;
struct bizyutuhin_t AB[555555];

/* sore wo hazusu to doredake score ga fueru ka */
int64_t katen_left[555555], katen_right[555555];

int64_t katen_left_max[555555], katen_right_max[555555];

int main(void) {
	int32_t i;
	int64_t kihon = 0;
	int64_t acc;
	int64_t kotae = 0;
	if (scanf("%" SCNd32, &N) != 1) return 1;
	for (i = 0; i < N; i++) {
		if (scanf("%" SCNd64 "%" SCNd64, &AB[i].A, &AB[i].B) != 2) return 1;
		kihon += AB[i].B;
	}
	qsort(AB, N, sizeof(*AB), cmp);
	kihon -= AB[N - 1].A - AB[0].A;
	for (i = 0; i < N - 1; i++) {
		katen_left[i] = AB[i + 1].A - AB[i].A - AB[i].B;
	}
	for (i = 1; i < N; i++) {
		katen_right[i] = AB[i].A - AB[i - 1].A - AB[i].B;
	}
	acc = katen_left[0];
	katen_left_max[0] = 0;
	for (i = 1; i < N; i++) {
		katen_left_max[i] = katen_left_max[i - 1] < acc ? acc : katen_left_max[i - 1];
		acc += katen_left[i];
	}
	acc = katen_right[N - 1];
	katen_right_max[N - 1] = 0;
	for (i = N - 1 - 1; i >= 0; i--) {
		katen_right_max[i] = katen_right_max[i + 1] < acc ? acc : katen_right_max[i + 1];
		acc += katen_right[i];
	}
	for (i = 0; i < N; i++) {
		int64_t candidate = kihon + katen_left_max[i] + katen_right_max[i];
		if (i == 0 || candidate > kotae) kotae = candidate;
	}
	printf("%" PRId64 "\n", kotae);
	return 0;
}


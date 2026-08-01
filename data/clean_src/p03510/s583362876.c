#include <stdio.h>
#include <stdlib.h>
#define int long long
#define ms_valtype pair

typedef struct {
	int num;
	int val;
}pair;

//比較関数
int compare_ms(ms_valtype a, ms_valtype b){
	return b.val - a.val;
}

//昇順
void sort_sub(ms_valtype *origin, int left, int right, ms_valtype *tmp){
	if(right - left > 1){
		int i, j, k, half = (left + right) / 2;
		sort_sub(origin, left, half, tmp);
		sort_sub(origin, half, right, tmp);
		for(i = left; i < right; i++){
			tmp[i] = origin[i];
		}
		for(i = left, j = left, k = half; i < right; i++){
			if(k == right){
				origin[i] = tmp[j];
				j++;
			}
			else if(compare_ms(tmp[j], tmp[k]) <= 0 && j < half){
				origin[i] = tmp[j];
				j++;
			}
			else{
				origin[i] = tmp[k];
				k++;
			}
		}
	}
}

void sort(ms_valtype *origin, int N){
	ms_valtype *tmp = (ms_valtype *)malloc(sizeof(ms_valtype) * N);
	sort_sub(origin, 0, N, tmp);
	free(tmp);
}

int max(int a, int b){
	return a >= b ? a : b;
}

signed main(){
	int N, i, j, ans = 0;
	scanf("%lld", &N);
	int *x = (int *)malloc(sizeof(int) * (N + 1));
	int *s = (int *)malloc(sizeof(int) * (N + 1));
	int *sum = (int *)malloc(sizeof(int) * (N + 1));
	pair *p = (pair *)malloc(sizeof(pair) * (N + 1));
	x[0] = 0;
	s[0] = 0;
	sum[0] = 0;
	p[0].num = 0;
	p[0].val = 0;
	for(i = 1; i <= N; i++){
		scanf("%lld%lld", &x[i], &s[i]);
		sum[i] = sum[i - 1] + s[i];
		p[i].num = i;
	}
	for(i = 1; i <= N; i++){
		p[i].val = sum[i] - x[i];
	}
/*	for(i = 1; i <= N; i++){
		printf("(i, num, val) = (%lld, %lld, %lld)\n", i, p[i].num, p[i].val);
	}
*/	sort(&p[1], N);
/*	for(i = 1; i <= N; i++){
		printf("(i, num, val) = (%lld, %lld, %lld)\n", i, p[i].num, p[i].val);
	}
*/	for(i = 1, j = 1; i <= N; i++){
//		printf("i = %lld\n", i);
		while(p[j].num < i){
			j++;
		}
//		printf("j = %lld\n", j);
		ans = max(ans, (sum[p[j].num] - sum[i - 1]) - (x[p[j].num] - x[i]));
	}
	printf("%lld\n", ans);
	return 0;
}
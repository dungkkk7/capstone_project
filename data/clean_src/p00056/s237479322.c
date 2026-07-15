// AOJ 0056: Goldbach's Conjecture
// 2017.10.28 bal4u@uu

#include <stdio.h>
#include <stdlib.h>
#define TM 0
#if TM
#include <time.h>
#endif

#define MAX  50000
#define HALF 2761			// prime[2760]=24989, prime[2761]=25013
char tbl[MAX+1];			// zero: if prime 

int sz;						// max sz = 5132
int prime[5200] = {   		// prime[46] = 223, 223^2 = 49729
  3,  5,  7, 11, 13, 17, 19, 23, 29, 
 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 
 73, 79, 83, 89, 97,101,103,107,109,113, 
127,131,137,139,149,151,157,163,167,173, 
179,181,191,193,197,199,211,223 };

int sqp[47] = {				// squre of prime: sqp[i] = prime[i] * prime[i]
  9,25,49,121,169,289,361,529,841,961,
1369,1681,1849,2209,2809,3481,3721,4489,5041,
5329,6241,6889,7921,9409,10201,10609,11449,11881,12769,
16129,17161,18769,19321,22201,22801,24649,26569,27889,29929,
32041,32761,36481,37249,38809,39601,44521,49729 };

int ans[MAX+MAX] = {0,0,0,0,1,0};

int main()
{
	int i, j, k;
	char buf[10], *p;
#if TM
	clock_t start, finish;
	start = clock();
#endif

	for (i = 0; i < 47; i++) {
		k = prime[i];
//		for (j = k+k; j < MAX; j += k) tbl[j] = 1;		// k+k ? 
//		for (j = k*k; j < MAX; j += k) tbl[j] = 1;		// k*k ?
		for (j = sqp[i]; j < MAX; j += k) tbl[j] = 1;
	}
	for (sz = 47, i = 225; i <= MAX; i += 2) if (!tbl[i]) prime[sz++] = i;
	for (i = 0; i < HALF; i++) {
		for (j = i; prime[i]+prime[j] <= MAX; j++) ans[prime[i]+prime[j]]++;
	}

	while (fgets(p=buf, 8, stdin) && *p != '0') {
		i = 0; while (*p >= '0') i = (i<<3) + (i<<1) + (*p++ & 0xf);
		if (i & 1) putchar('1'-tbl[i-2]);
		else printf("%d", ans[i]);
		putchar('\n');
	}
#if TM
	finish = clock();
	printf("time %lf\n", (double)(finish-start)/CLOCKS_PER_SEC);
#endif
	return 0;
}
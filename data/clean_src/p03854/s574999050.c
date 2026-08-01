
#pragma warning(disable:4996)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include <float.h>

#pragma region 定義
typedef long long  ll;
typedef unsigned long long  ull;


#define _itoa(A,N) sprintf(A, "%d", N);

int i_dsort(const void* a, const void* b);
int i_asort(const void* a, const void* b);

int  _gcd(int a, int b);
int  _swp(int* a, int* b);
int _cknum(char* a, int n);
int _atoi(char* s, int len);

int s_asort(const void* a, const void* b);
int s_dsort(const void* a, const void* b);

//昇順
int s_asort(const void* a, const void* b) {
	return(strcmp((char*)a, (char*)b));
}
int s_dsort(const void* a, const void* b) {
	return(strcmp((char*)b, (char*)a));
}

int i_dsort(const void* a, const void* b) {
	return(*(int*)b - *(int*)a);
}
int i_asort(const void* a, const void* b) {
	return(*(int*)a - *(int*)b);
}


int i_gcd(int a, int b);
int i_gcd(int a, int b) {
	if (!b)return a;
	return i_gcd(b, a % b);
}
int i_lcm(int a, int b);
int i_lcm(int a, int b) {
	return (a * b) / i_gcd(a, b);
}
int ll_gcd(ll a, ll b);
int ll_gcd(ll a, ll b) {
	if (!b)return a;
	return ll_gcd(b, a % b);
}
int ll_lcm(ll a, ll b);
int ll_lcm(ll a, ll b) {
	return (a * b) / ll_gcd(a, b);
}

// puts("Yes\n") puts("No\n")
// scanf("%d.%d") 浮動小数点入力を整数２つで得る


//#define pai  3.1415926535 
//#define  _USE_MATH_DEFINES でM_PIが使える

#define deg_rad(X)  (X*(M_PI/180))


int _swp(int* a, int* b)
{
	int tmp;
	tmp = *b; *b = *a; *a = tmp;
	return 0;
}
#define _abs(x) ((x)>0?(x):-(x))
#define _min(x,y) ((x)<(y)?(x):(y))
#define _max(x,y) ((x)<(y)?(y):(x))

int _cknum(char* a, int n) {
	int i;
	char t = '0';

	for (i = 0; i < n; i++) {
		if (a[i] < '0' || a[i]>'9') return 1;
	}
	return 0;
}


int _atoi(char* s, int len) {
	char tmp[20];
	memcpy(tmp, s, len);
	tmp[len] = 0x00;
	return (atoi(tmp));
}

//素因数分解　pf素数が入る　pc 素数の数
//ll _pfact(ll a);
//static ll pf[100000000];
//static ll pc;
//
//ll _pfact(ll a) {
//	long i, r;
//	if (a % 2 == 0) {
//		pf[pc] = 2; pc++;
//		return(_pfact(a / 2));
//	}
//	r = sqrt(a);
//	for (i = 3; i <= r; i += 2) {
//		if (a % i == 0) {
//			pf[pc] = i; pc++;
//			return(_pfact(a / i));
//		}
//	}
//	if (a != 1) {
//		pf[pc] = a; pc++;
//	}
//	return 0;
//
//}

//同じものの最初の文字をNULLにして降順
int _sort(const void* a, const void* b);
int _sort(const void* a, const void* b) {
	char rc;

	rc = strcmp((char*)b, (char*)a);
	if (rc == 0) {
		*(char*)a = 0x00;
		return(1);
	}
	return(rc);
}
// 立っている ビットの数
int bitcount(unsigned int uc);
int bitcount(unsigned int uc)
{
	int bit;

	for (bit = 0; 0 != uc; uc = (unsigned int)(uc >> 1))
		if (0 != (uc & 1))++bit;

	return bit;
}//bitco

//10進数の桁数の総和
int _sumdig(int n);
int _sumdig(int n) {
	int sum = 0;
	while (n > 0) {	sum += n % 10;n /= 10;}
	return(sum);
}



#define _rnd(a,b)    ((a+b-1)/b) //　A/Bの余りを繰り上げる
#define _abs(x) ((x)<0 ? -(x) : (x))
#define _MAX 200000
#pragma endregion

// ABC145 C - Average Length
//int main(void) {
//	int n,i, x[9],y[9],cnt=0;
//	double  sum=0;
//
//	scanf("%d", &n);
//	for (i = 0; i < n; i++) 
//		scanf("%d %d", &x[i], &y[i]);
//
//		for(i=0;i<n-1;i++)
//			for (int j = i + 1; j < n; j++) {
//				sum += hypot(x[i] - x[j], y[i] - y[j]);
//				cnt++;
//				printf("%d %lf\n", cnt, sum);
//			}
//	printf("%lf\n",sum/cnt);
//	return 0;
//}

//ABC049 C - 白昼夢
#define _MAX 100010

static char  s[_MAX];
int main(void)
{
	int  i,l;

	scanf("%s", &s[1]); l = strlen(&s[1]);

	int p = 1;
	while (p <= l) {
		if (memcmp(&s[p], "dream", 5) == 0){
			p += 5; s[p - 1] = '1'; continue;
		}
		if( memcmp(&s[p], "erase", 5) == 0){
			p += 5; s[p - 1] = '2'; continue;
		}
		if (s[p - 1] == '2' && s[p] == 'r') {
			p += 1; continue;
		}
		if (s[p - 1] == '1' && memcmp(&s[p], "er", 2) == 0) {
			p += 2; continue;
		}
		printf("NO\n"); return 0;
	}
	p--;
	(p == l) ? printf("YES\n") : printf("NO\n");
	
	return 0;
}




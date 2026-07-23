#include <float.h>
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <math.h>
#ifdef __cplusplus
#include <bits/stdc++.h>
#endif

long comb[51][51];

void comb_init(int n){
	for(int i=0; i<=n; i++){
		for(int j=0; j<=i; j++){
			if(j==0 || j==i){
				comb[i][j]=1;
			}else{
				comb[i][j]=comb[i-1][j-1]+comb[i-1][j];
			}
		}
	}
}

void rsortr_u64(void *base, const int count){
	typedef uint64_t rsort_t;
	rsort_t *a=base;
	rsort_t *b=malloc(count*sizeof(rsort_t));
	int c[0x100];
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(0<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(0<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(1<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(1<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(2<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(2<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(3<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(3<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(4<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(4<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(5<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(5<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(6<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(6<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	memset(c, 0, sizeof(c)); for(int i=0; i<count; i++){ c[(a[i]>>(7<<3))&0xFF]++; } for(int i=0xFE; i>=0; i--) c[i]+=c[i+1]; for(int i=count-1; i>=0; i--){ b[--c[(a[i]>>(7<<3))&0xFF]]=a[i]; }{void *t=a; a=b; b=t;}
	free(b);
}
int32_t nextint(void){ char c=getchar_unlocked(); while(c!='-'&&(c<'0'||'9'<c)) c=getchar_unlocked(); bool s=false; if(c=='-'){s=true;c=getchar_unlocked();} uint32_t x=0; while('0'<=c && c<='9'){ x=x*10+c-'0'; c=getchar_unlocked(); } return s?-x:x; }
int64_t nextlong(void){ char c=getchar_unlocked(); while(c!='-'&&(c<'0'||'9'<c)) c=getchar_unlocked(); int s=0; if(c=='-'){s=1;c=getchar_unlocked();} uint64_t x=0; while('0'<=c && c<='9'){ x=x*10+c-'0'; c=getchar_unlocked(); } return s?-x:x; }

long v[50];
int main(void){
	int n=nextint();
	int a=nextint();
	int b=nextint();
	for(int i=0; i<n; i++){
		v[i]=nextlong();
	}
	rsortr_u64(v, n);
	long sum=0;
	for(int i=0; i<a; i++){
		sum+=v[i];
	}
	double ave=(double)sum/a;
	printf("%.6lf\n", ave);
	if(v[0]==v[a-1]){
		int c=0;
		for(int i=0; i<n; i++){
			c+=(v[i]==v[0]);
		}
		comb_init(c);
		long ans=0;
		for(int i=b<c?b:c; i>=a; i--){
			ans+=comb[c][i];
		}
		printf("%ld\n", ans);
	}else{
		int c=0;
		for(int i=0; i<n; i++){
			c+=(v[i]==v[a-1]);
		}
		int d=0;
		for(int i=0; i<a; i++){
			d+=(v[i]==v[a-1]);
		}
		comb_init(c);
		long ans=comb[c][d];
		printf("%ld\n", ans);
	}
}

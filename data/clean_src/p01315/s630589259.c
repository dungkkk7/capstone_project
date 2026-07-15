#define _USE_MATH_DEFINES
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ctype.h>
#include <limits.h>
#define EPS 1e-10
#define sq(n) ((n)*(n))
#define rep(i,n) for(i=0;i<n;i++)
#define rev(i,n) for(i=n-1;i>=0;i--)
#define sort(a,n) qsort(a,n,sizeof(TYPE),cmp)
#define sort_r(a,n) qsort(a,n,sizeof(TYPE),cmp_r);
#define chsort(s,n) qsort(s,n,sizeof(char),cmp)
#define chsort_r(s,n) qsort(s,n,sizeof(char),char_cmp_r);
#define TYPE int
#define MEMSET(a) memset(a,0,sizeof(a))
long long mod=(long long)1e09+7;
int inf=1<<29;
long long llinf=1ll<<60;

int in(void){
    int i;scanf("%d",&i);
    return i;
}
long long llin(void){
    long long i;scanf("%lld",&i);
    return i;
}
double din(void){
    double i;scanf("%lf",&i);
    return i;
}
void chin(char s[]){
    scanf("%s",s);
}
void print(int a){
    printf("%d\n",a);
}
void llprint(long long a){
    printf("%lld\n",a);
}
void dprint(double a){
    printf("%.10f\n",a);
}
void print2(int a,int b){
    printf("%d %d\n",a,b);
}
long long max(long long a,long long b){
    return a>b?a:b;
}
long long min(long long a,long long b){
    return a<b?a:b;
}
int cmp(const void *a,const void *b){
    return *(TYPE *)a-*(TYPE *)b;
}
int cmp_r(const void *a,const void *b){
    return *(TYPE *)b-*(TYPE *)a;
}
int char_cmp(const void *a,const void *b){
    return strcmp((char *)a,(char *)b);
}
int char_cmp_r(const void *a,const void *b){
    return strcmp((char *)b,(char *)a);
}
void swap(int *a,int *b){
    int t=*a;
    *a=*b;
    *b=t;
}
long long gcd(long long x,long long y){
    return x%y?gcd(y,x%y):y;
}
long long lcm(long long x,long long y){
    return x/gcd(x,y)*y;
}

// write codes below this
// when you use 'sort',
// make sure TYPE macro is correct
typedef struct{
    double eff;
    char l[21];
}data;

int main(void){
    int n,p,a,b,c,d,e,f,s,m,i,j,time,income;
    data w[50],tmp;
    while(1){
        n=in();
        if(!n)break;
        rep(i,n){
            chin(w[i].l);
            p=in();
            a=in();
            b=in();
            c=in();
            d=in();
            e=in();
            f=in();
            s=in();
            m=in();
            time=a+b+c+(d+e)*m;
            income=f*s*m-p;
            w[i].eff=(double)income/time;
        }
        rep(i,n-1){
            for(j=n-1;j>i;j--){
                if(w[j-1].eff<w[j].eff||fabs(w[j-1].eff-w[j].eff)<EPS&&strcmp(w[j-1].l,w[j].l)>0){
                    tmp=w[j-1];
                    w[j-1]=w[j];
                    w[j]=tmp;
                }
            }
        }
        rep(i,n)puts(w[i].l);
        puts("#");
    }
    return 0;
}

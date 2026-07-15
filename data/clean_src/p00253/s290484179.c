#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#define FOR(n) for(int i=0;i<n;i++)
#define FORJ(n) for(int j=0;j<n;j++)
#define PRN(n) printf("%d\n",n)
#define PRF(n) printf("%lf\n",n)
#define PRL(n) printf("%lld\n",n)
#define PRS(s) printf("%s\n",s)
#define PRC(c) printf("%c",c)
#define mod 1000000007
typedef long long int ll;
int u(const void *a, const void *b){
    return *(ll*)a-*(ll*)b;
}
int d(const void *a, const void *b){
    return *(ll*)b-*(ll*)a;
}
int z(int a){
  if(a<1)a*=-1;
  return a;
}
int min(int a,int b){
  if(a>b)return b;
  return a;
}
int max(int a,int b){
  if(a>b)return a;
  return b;
}
int gcd(int a,int b){
  if(!b)return a;
  return gcd(b,a%b);
}
int kt(ll a){
  int sum=0;
  while(a){
    a/=10;
    sum++;
  }
  return sum;
}
int ks(ll a){
  int sum=0;
  while(a){
    sum+=a%10;
    a/=10;
  }
  return sum;
}
int n;
int f(int b,int c){
  return c*((n-1)/b+1);
}
int main(void){
  int n;
  ll a[105],x[105];
  while(1){
    scanf("%d",&n);
    if(!n)break;
    FOR(n+1)scanf("%lld",&x[i]);
    FOR(n+1){
      int l=0;
      FORJ(n+1){
        a[l]=x[j];
        if(i!=j)l++;
      }
      a[n]=x[i];
      int flg=1;
      FORJ(n-2)if(a[j]-a[j+1]!=a[j+1]-a[j+2])flg=0;
      if(flg){
        PRL(a[n]);
        break;
      }
    }
  }
  return 0;
}


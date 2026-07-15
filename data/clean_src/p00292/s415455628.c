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
ll dp[100001];
int u(const void *a, const void *b){
    return *(ll*)a-*(ll*)b;
}
int d(const void *a, const void *b){
    return *(ll*)b-*(ll*)a;
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
int main(void) {
  int n,a,b;
  scanf("%d",&n);
  FOR(n){
    scanf("%d %d",&a,&b);
    PRN((a-1)%b+1);
  }
  return 0;
}

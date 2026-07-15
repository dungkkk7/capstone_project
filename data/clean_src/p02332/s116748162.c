//Twelvefold way[syazou 12-sou]
//https://onlinejudge.u-aizu.ac.jp/problems/DPL_5_A
//https://qiita.com/drken/items/f2ea4b58b0d21621bd51
//https://mathtrain.jp/twelveway

#include<stdio.h>
#define mod 1000000007
#define faclim 1048576
#define partition_nlim 1024
#define partition_klim 1024

long long power(long long a,long long b){
  long long x=1,y=a;
  while(b>0){
    if(b&1ll){
      x=(x*y)%mod;
    }
    y=(y*y)%mod;
    b>>=1;
  }
  return x%mod;
}

long long modular_inverse(long long n){
  return power(n,mod-2);
}

long long factorial[faclim];
long long invfact[faclim];
long long bce[faclim];

void cfact(){
  long long i;
  factorial[0]=1;
  factorial[1]=1;
  for(i=2;i<faclim;i++){
    factorial[i]=factorial[i-1]*i;
    factorial[i]%=mod;
  }
  invfact[faclim-1]=modular_inverse(factorial[faclim-1]);
  for(i=faclim-2;i>=0;i--){
    invfact[i]=invfact[i+1]*(i+1);
    invfact[i]%=mod;
  }
  for(i=0;i<faclim;i++){
    if(i%2==1){bce[i]=mod-1;}
    else{bce[i]=1;}
    bce[i]*=invfact[i];
    bce[i]%=mod;
    if(i!=0){
      bce[i]+=bce[i-1];
      if(bce[i]>=mod){bce[i]-=mod;}
    }
  }
}

long long calcnCr(long long n,long long k){
  if(k<0 || n<k){return 0;}
  return (factorial[n]*((invfact[k]*invfact[n-k])%mod))%mod;
}

long long partition[partition_nlim][partition_klim];
long long partition_isinit=0;

void partition_init(){
  if(partition_isinit==1){return;}
  partition_isinit=1;
  long long i,j;
  for(i=0;i<partition_nlim;i++){
    for(j=0;j<partition_klim;j++){
      partition[i][j]=-1;
    }
  }
}

long long partition_rep(long long n,long long k){
  if(n<0 || k<0){return 0;}
  if(n==0){return 1;}
  if(k==0){
    if(n==0){return 1;}
    else{return 0;}
  }
  if(partition[n][k]!=-1){return partition[n][k];}
  partition[n][k]=(partition_rep(n,k-1)+partition_rep(n-k,k))%mod;
  return partition[n][k];
}

// packing n balls using k boxes
// |  distinguish  |  each boxes contains the balls limited  |
// | balls | boxes |  no limits  |  at most 1  | at least 1  |
// |  can  |  can  |      1      |      2      |      3      |
// | can't |  can  |      4      |      5      |      6      |
// |  can  | can't |      7      |      8      |      9      |
// | can't | can't |     10      |     11      |     12      |

long long twelvefold_way(long long n,long long k,long long type){
  long long i,r=0,dt;
  switch(type){
    case 1:
      return power(k,n);
      break;
    case 2:
      if(k<n){return 0;}
      return (factorial[k]*invfact[k-n])%mod;
      break;
    case 3:
      if(n<k){return 0;}
      for(i=0;i<=k;i++){
        dt=(calcnCr(k,i)*power(i,n))%mod;
        if((k-i)%2==1){r+=(mod-dt);}
        else{r+=dt;}
        if(r>=mod){r-=mod;}
      }
      return r;
      break;
    case 4:
      return calcnCr(n+k-1,n);
      break;
    case 5:
      if(k<n){return 0;}
      return calcnCr(k,n);
      break;
    case 6:
      if(n<k){return 0;}
      return calcnCr(n-1,k-1);
      break;
    case 7:
      for(i=0;i<=k;i++){
        dt=(power(i,n)*invfact[i])%mod;
        r+=dt*bce[k-i];
        r%=mod;
      }
      return r;
    case 8:
      if(k<n){return 0;}
      return 1;
      break;
    case 9:
      if(n<k){return 0;}
      for(i=0;i<=k;i++){
        dt=(calcnCr(k,i)*power(i,n))%mod;
        if((k-i)%2==1){r+=(mod-dt);}
        else{r+=dt;}
        if(r>=mod){r-=mod;}
      }
      r*=invfact[k];r%=mod;
      return r;
      break;
    case 10:
      partition_init();
      return partition_rep(n,k);
      break;
    case 11:
      if(k<n){return 0;}
      return 1;
      break;
    case 12:
      if(n<k){return 0;}
      partition_init();
      return partition_rep(n-k,k);
      break;
  }
}

int main(){
  cfact();
  long long n,k;
  scanf("%lld%lld",&n,&k);
  printf("%lld\n",twelvefold_way(n,k,2));
}


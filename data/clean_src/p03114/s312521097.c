//AWTF2019-B
#include<stdio.h>
#include<stdlib.h>
#define mod 1000000007

long long llmax(long long a,long long b){if(a>b){return a;}return b;}

long long power(long long a,long long b){
  long long x=1,y=a;
  while(b>0){
    if(b%2){
      x=(x*y)%mod;
    }
    y=(y*y)%mod;
    b/=2;
  }
  return x%mod;
}

long long modular_inverse(long long n){
  return power(n,mod-2);
}

typedef struct{
    long long par;
    long long dep;
    long long size;
}node;

node uft[64];

void resuf(){
    long long i;
    for(i=0;i<64;i++){
        uft[i].par=i;uft[i].dep=0;uft[i].size=1;
    }
    return;
}

long long find(long long x){
    if(uft[x].par==x){return x;}
    else{uft[x].par=find(uft[x].par);return uft[x].par;}
}

void uni(long long x,long long y){
    long long xp,yp;
    xp=find(x);yp=find(y);
    if(xp==yp){return;}
    if(uft[xp].dep>uft[yp].dep){
        uft[yp].par=xp;
        uft[xp].size+=uft[yp].size;
    }
    else{
        uft[xp].par=yp;
        uft[yp].size+=uft[xp].size;
        if(uft[xp].dep==uft[yp].dep){uft[yp].dep++;}
    }
    return;
}

long long size(long long x){
    x=find(x);
    return uft[x].size;
}

typedef struct{
long long val;
long long node;
}sd;

int sdsortfnc(const void *a,const void *b){
if(((sd*)a)->val < ((sd*)b)->val){return -1;}
if(((sd*)a)->val > ((sd*)b)->val){return 1;}
return 0;
}

void coordinate_comp(long long a[],long long n){
  long long i,c=0;
  sd dat[64];
  for(i=0;i<n;i++){
    dat[i].val=a[i];
    dat[i].node=i;
  }
  qsort(dat,n,sizeof(dat[0]),sdsortfnc);
  a[dat[0].node]=c;
  for(i=1;i<n;i++){
    if(dat[i-1].val!=dat[i].val){c++;}
    a[dat[i].node]=c;
  }
}

typedef struct{
  long long val;
  long long id;
}data;

int sortfnc(const void *a,const void *b){
if(((data*)a)->val < ((data*)b)->val){return -1;}
if(((data*)a)->val > ((data*)b)->val){return 1;}
return 0;
}

int main(){
  resuf();
  long long n,q,i,j,w;
  long long l[16],r[16],gr[32],v=0,gid,p;
  long long ce[32];
  long long res=1,inv9=modular_inverse(9);
  long long k1,k2;
  long long dp[32768]={0};
  long long allce[32768];
  data dat[32];
  scanf("%lld%lld",&n,&q);
  for(i=0;i<q;i++){
    scanf("%lld%lld",&l[i],&r[i]);
    dat[i].val=l[i]-1;
    dat[i].id=i;
    dat[q+i].val=r[i];
    dat[q+i].id=i;
  }
  qsort(dat,2*q,sizeof(dat[0]),sortfnc);

  for(i=1;i<2*q;i++){
    if(dat[i-1].val==dat[i].val){
      uni(dat[i-1].id,dat[i].id);
      ce[i]=1;
    }
    else{
      p=(power(10,dat[i].val-dat[i-1].val)+mod-1)%mod;
      p*=inv9;p%=mod;
      res*=p;res%=mod;
      ce[i]=((p+1)*modular_inverse(p))%mod;
    }
  }
  res*=power(10,n-dat[2*q-1].val);res%=mod;

  for(i=0;i<2*q;i++){
    gr[i]=find(dat[i].id);
  }
  coordinate_comp(gr,2*q);
  for(i=0;i<2*q;i++){
    dat[i].id=gr[i];
    v=llmax(v,gr[i]);
  }
  v++;

  for(i=0;i<(1ll<<v);i++){
    allce[i]=1;
    for(j=1;j<2*q;j++){
      if((i&(1ll<<dat[j-1].id))!=0 && (i&(1ll<<dat[j].id))!=0){
        allce[i]*=ce[j];allce[i]%=mod;
      }
    }
  }

  //O(3^N) bitDP
  //https://topcoder.g.hatena.ne.jp/jackpersel/20100804/1281196966
  gid=0;
  //(For detail of {x_i},see the official editorial.)
  //k1... if x_0 == 0
  //k2... if x_0 != 0
  k2=((power(10,dat[0].val)-1)*inv9)%mod;
  k1=(k2+1)%mod;
  i=(1ll<<v)-1;
  for(j=i;j>0;j=((j-1)&i)){
    if((j&(1<<dat[0].id))!=0){w=k1;}else{w=k2;}
    w*=allce[j];w%=mod;
    dp[i^j]+=w;
    dp[i^j]%=mod;
  }
  dp[(1ll<<v)-1]=k2;

  for(gid=1;gid<=8;gid++){
    for(i=0;i<(1ll<<v);i++){
      if(dp[i]==0){continue;}
      for(j=i;j>0;j=((j-1)&i)){
        w=(dp[i]*allce[j])%mod;
        dp[i^j]+=w;
        dp[i^j]%=mod;
      }
    }
  }
  printf("%lld\n",(res*dp[0])%mod);
  return 0;
}

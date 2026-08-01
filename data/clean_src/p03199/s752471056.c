#include<stdio.h>
#include<stdlib.h>

#define MAX(a,b) ((a)>(b)?(a):(b))
#define ABS(a) ((a)>=0?(a):-(a))

const int mod=998244353;

typedef long long int int64;

int modPow(int r,int64 n){
  int t=1;
  int s=r;
  while(n>0){
    if(n%2) t=(int64)t*s%mod;
    s=(int64)s*s%mod;
    n>>=1;
  }
  return t;
}

typedef struct masu{
  int a,b,c;
} node;

int cmpE(const void *a,const void *b){
  node *p=(node *)a;
  node *q=(node *)b;
  if(p->a!=q->a) return p->a-q->a;
  return p->b-q->b;
}

int calcWay(int n,node *e,int len){
  int64 cnt=(int64)(n-3)*(n-2)/2;
  int ok=1;
  int i=0;
  while(i<len){
    cnt--;
    i++;
    if(i<len && cmpE(e+i,e+i-1)==0){
      if(e[i].c!=e[i-1].c){
	ok=0;
      }
      i++;
    }
  }
  return (int64)ok*modPow(2,cnt)%mod;
}

int cmpD(const void *a,const void *b){
  node *p=(node *)a;
  node *q=(node *)b;
  int x=MAX(p->a,p->b);
  int y=MAX(q->a,q->b);
  if(x!=y) return x-y;
  return (p->a-p->b)-(q->a-q->b);
}

int popcnt(int n){
  int res=0;
  while(n){
    res+=n&1;
    n>>=1;
  }
  return res;
}

void run(void){
  int n,m;
  scanf("%d%d",&n,&m);
  node *d=(node *)calloc(m,sizeof(node));
  node *e=(node *)calloc(m,sizeof(node));
  int dlen=0;
  int elen=0;
  while(m--){
    int a,b,c;
    scanf("%d%d%d",&a,&b,&c);
    if(ABS(a-b)<=2){
      d[dlen++]=(node){a,b,c};
    } else {
      if(b<a){
	int s=a;
	a=b;
	b=s;
      }
      e[elen++]=(node){a,b,c};
    }
  }
  qsort(d,dlen,sizeof(node),cmpD);
  qsort(e,elen,sizeof(node),cmpE);
  int way=calcWay(n,e,elen);
  int dp[4]={0,0,0,0};
  int i,j,k;
  for(i=0;i<(1<<4);i++){
    if(popcnt(i)&1) continue;
    int ok=1;
    for(j=0;j<dlen && cmpD(d+j,&((node){2,1,0}))<=0;j++){
      int shift=d[j].a-1+2*(d[j].b-1);
      if(d[j].c!=((i>>shift)&1)) ok=0;
    }
    dp[i>>3]+=ok;
  }
  int now=0;
  k=0;
  for(i=3;i<=n;i++){
    while(k<dlen && cmpD(d+k,&((node){i-2,i,0}))<0) k++;
    int next=now^2;
    dp[next]=dp[next+1]=0;
    for(j=0;j<(1<<5);j++){
      if(popcnt(j)%2==1) continue;
      int ok=1;
      for(int l=k;l<dlen && cmpD(d+l,&((node){i,i-2,0}))<=0;l++){
	int shift=cmpD(d+l,&((node){i-2,i,0}));
	if(d[l].c!=((j>>shift)&1)) ok=0;
      }
      if(ok){
	int index=next+((j>>2)&1);
	dp[index]=(dp[index]+dp[now+popcnt((j>>1)&7)%2])%mod;
      }
    }
    now=next;
  }
  int ans=(int64)(dp[now]+dp[now+1])*way%mod;
  printf("%d\n",ans);
}

int main(void){
  run();
  return 0;
}

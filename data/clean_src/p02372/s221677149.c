#include <stdio.h>
#include <stdlib.h>
#define ll long long
#define rep(i,l,r)for(ll i=(l);i<(r);i++)
#define max(p,q)((p)>(q)?(p):(q))

//辺の情報を個別に持つタイプ
typedef struct edge{ll s,g,c;}E;
typedef struct graph{
	int vcnt,ecnt;
	E  e[200010];//適宜変える
	int id[100010];//適宜変える
}G;

int esort(const void*a,const void*b){
	E*p=(E*)a,*q=(E*)b;
	if((*p).s<(*q).s)return -1;
	if((*p).s>(*q).s)return  1;
	if((*p).g<(*q).g)return -1;
	return 1;
}

G g;
void readgraph(){
	//適宜変える
	ll n;
	scanf("%lld",&n);
	rep(i,0,n-1){
		ll x,y,c;
		scanf("%lld%lld%lld",&x,&y,&c);
		g.e[2*i].s=x;
		g.e[2*i].g=y;
		g.e[2*i].c=c;
		g.e[2*i+1].s=y;
		g.e[2*i+1].g=x;
		g.e[2*i+1].c=c;
	}
	g.vcnt=n;
	g.ecnt=2*n-2;
	qsort(g.e,g.ecnt,sizeof(E),esort);
 
	int p=0;
	rep(i,0,g.vcnt){
		while(p<g.ecnt&&g.e[p].s<i)p++;
		g.id[i]=p;
	}
	g.id[g.vcnt]=g.ecnt;//番兵
}

ll dp1[100010];//頂点に対する答え
ll dp2[200010];//辺に対する答え
ll cum[2][200010];//累積和
ll munit=0;//単位元
ll monoop(ll x,ll y){return max(x,y);}

ll dfs2(int);
ll dfs1(int v){
	if(dp1[v]!=-1)return dp1[v];
	rep(i,g.id[v],g.id[v+1]){
		if(i==g.id[v])cum[0][i]=munit;
		else cum[0][i]=monoop(cum[0][i-1],dfs2(i-1)+g.e[i-1].c);
	}
	for(int i=g.id[v+1]-1;i>=g.id[v];i--){
		if(i==g.id[v+1]-1)cum[1][i]=munit;
		else cum[1][i]=monoop(cum[1][i+1],dfs2(i+1)+g.e[i+1].c);
	}
 
	ll temp=munit;
	rep(i,g.id[v],g.id[v+1])temp=monoop(temp,dfs2(i)+g.e[i].c);
	return dp1[v]=temp;
}
ll dfs2(int e){
	if(dp2[e]!=-1)return dp2[e];
	if(dp1[g.e[e].g]!=-1){
		//逆辺のindexが必要
		int v=g.e[e].g;
		int l=g.id[v],r=g.id[v+1];
		while(r-l>1){
			int m=(l+r)/2;
			if(g.e[m].g<=g.e[e].s)l=m;
			else r=m;
		}
		return dp2[e]=monoop(cum[0][l],cum[1][l]);
	}
	ll temp=munit;
	int v=g.e[e].g;
	rep(i,g.id[v],g.id[v+1]){
		if(g.e[i].g!=g.e[e].s)temp=monoop(temp,dfs2(i)+g.e[i].c);
	}
	return dp2[e]=temp;
}

int main(){
	readgraph();
	rep(i,0,g.vcnt)dp1[i]=-1;
	rep(i,0,g.ecnt)dp2[i]=cum[0][i]=cum[1][i]=-1;
	rep(i,0,g.vcnt)printf("%lld\n",dfs1(i));
}

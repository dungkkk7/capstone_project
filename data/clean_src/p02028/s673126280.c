#include<stdio.h>
#include<stdlib.h>
#define ll long long
#define rep(i,l,r)for(ll i=(l);i<(r);i++)
int downll(const void*a, const void*b){return*(ll*)a<*(ll*)b?1:*(ll*)a>*(ll*)b?-1:0;}
void sortdown(ll*a,int n){qsort(a,n,sizeof(ll),downll);}

//*
//プラキュー（二分ヒープ）（最低限バージョン）
//int PQhikaku(int i,int j);//jの方が優先度が高いならtrueを返す
int PQhikaku(ll*heap,int i,int j){return heap[i]<heap[j];}
void heap_utod(ll*heap,int n){
	if(2*n>heap[0])return;
	int rflag=(2*n+1<=heap[0])&&(PQhikaku(heap,2*n,2*n+1));
	if(PQhikaku(heap,n,2*n+rflag)){
		ll temp=heap[2*n+rflag];
		heap[2*n+rflag]=heap[n];
		heap[n]=temp;
		heap_utod(heap,2*n+rflag);
	}
}
void heap_dtou(ll*heap,int n){
	if(n==1||PQhikaku(heap,n,n/2))return;
	ll temp=heap[n];
	heap[n]=heap[n/2];
	heap[n/2]=temp;
	heap_dtou(heap,n/2);
}
ll PQpop(ll*heap){
	ll rr=heap[1];
	heap[1]=heap[heap[0]--];
	heap_utod(heap,1);
	return rr;
}
void PQpush(ll*heap,ll n){
	heap[++heap[0]]=n;
	heap_dtou(heap,heap[0]);
}
//*/

ll a[200010];
ll h[200010];
int main(){
	ll n,m;
	scanf("%lld%lld",&n,&m);
	rep(i,0,n)scanf("%lld",a+i);
	sortdown(a,n);
	
	ll sum=0;
	rep(i,0,m){
		int t;
		scanf("%d",&t);
		sum+=t;
		PQpush(h,t);
	}

	ll ans=0,cnt=0;
	rep(i,0,n){
		while(h[0]&&h[1]>a[i]){
			sum-=PQpop(h);
			cnt++;
		}
		ans+=cnt*a[i]+sum;
	}
	printf("%lld\n",ans);
}

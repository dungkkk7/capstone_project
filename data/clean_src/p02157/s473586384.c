#include<stdio.h>
#define min(p,q)((p)<(q)?(p):(q))
#define in(l,r,k) ((l<r&&(l<=k&&k<r)) || (l>r&&(k<r||l<=k)))

long long L[50],R[50];
int main(){
	long long n,q,k,d;
	scanf("%lld%lld%lld%lld",&n,&q,&k,&d);
	k--,d--;
	int temp=min(q,50);
	long long l=d,r=d+1;
	L[0]=l;
	R[0]=r;
	int flag=0;
	for(int i=0;i<temp;i++){
		l*=2;
		r*=2;
		if((l<r&&r-l>=n)||(l>r&&l-r<=n)){
			flag=1;
			temp=i+1;
			break;
		}
		L[i+1]=l%=n;
		R[i+1]=r%=n;
	}
	if(flag==0){
		if(!in(l,r,k)){
			puts("-1");
			return 0;
		}
	}
	for(int i=0;i<q-temp;i++){
		puts("0");
		k=(k/2)+(n/2)*(k%2);
	}
	while(temp--){
		k=(k/2)+(n/2)*(k%2);
		if(in(L[temp],R[temp],k))puts("0");
		else{
			k=(k+n/2)%n;
			puts("1");
		}
	}
}


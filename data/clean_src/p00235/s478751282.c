#include<stdio.h>

int main(){
	int n, a, b, t, ans=0;
	int i, j, k, l, p, q, far=0, sta[20]={0}, now=0, tail=0, count;
	int lis[20][23];//0-19隣接リスト,20隣接する島への時間の合計,21隣接する島の数,22島1からの時間
	scanf("%d", &n);
	while(n>0)
	{
		for(p=0;p<20;p++)
		{
			for(q=0;q<23;q++)
			{
				lis[p][q]=0;
			}
		}
		for(i=0;i<n-1;i++)
		{
			scanf("%d %d %d", &a, &b, &t);
			lis[a-1][b-1]=t;
			lis[a-1][20]+=t;
			lis[a-1][21]++;
			lis[b-1][a-1]=t;
			lis[b-1][20]+=t;
			lis[b-1][21]++;
		}
		for(j=0;j<n;j++)
		{
			if(lis[j][21]>=2 || j==0) ans+=lis[j][20];
			else if(lis[j][21]==1) ans-=lis[j][20];
		}
		while(now>=0)
		{
			count=0;
			for(k=0;k<n;k++)
			{
				if(lis[sta[now]][k]>0 && lis[k][21]>=2 && lis[k][22]==0 && k>0)
				{
					lis[k][22] = lis[sta[now]][k] + lis[sta[now]][22];
					sta[tail+1] = k;
					tail++;
					count++;
				}
			}
			if(count==0) tail--;
			now=tail;
		}
		for(l=0;l<n;l++)
		{
			if(lis[l][22]>far)far=lis[l][22];
		}
		ans -= far;
		printf("%d\n", ans);
		
		
		scanf("%d", &n);
		far=0;
		now=0;
		tail=0;
		ans=0;
	}
	return 0;
}
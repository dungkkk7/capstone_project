#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int gcd(int x,int y)
{
	while(1)
	{
		x %= y;
		if(x == 0)
			return y;
		y %= x;
		if(y == 0)
			return x;
	}
}

typedef struct mb
{
	struct mb* red;
	struct mb* blue;
	struct mb* parent;
	long long int weight_r;
	long long int weight_b;
	int ratio_r;
	int ratio_b;
	int flug;
} mobile;

int main()
{
	int n;
	int i,j;
	mobile* list;
	while(scanf("%d",&n),n)
	{
		list = (mobile*)malloc(sizeof(mobile)*n);
		for(i = 0;i < n;i++)
		{
			list[i].parent = NULL;
			list[i].flug = 1;
		}
		for(i = 0;i < n;i++)
		{
			int p,q,r,b;
			scanf("%d %d %d %d",&p,&q,&r,&b);
			list[i].ratio_r = p;
			list[i].ratio_b = q;
			list[i].weight_r = 0;
			list[i].weight_b = 0;
			if(r)
			{
				list[i].red = &list[r-1];
				list[r-1].parent = &list[i];
			}
			else
				list[i].red = NULL;
			if(b)
			{
				list[i].blue = &list[b-1];
				list[b-1].parent = &list[i];
			}
			else
				list[i].blue = NULL;
		}
		while(1)
		{
			for(j = 0;j < n;j++)
			{
				if(list[j].red == NULL && list[j].blue == NULL && list[j].flug)
				{
					if(list[j].weight_r == 0 && list[j].weight_b == 0)
					{
						list[j].weight_r = list[j].ratio_b/gcd(list[j].ratio_r,list[j].ratio_b);
						list[j].weight_b = list[j].ratio_r/gcd(list[j].ratio_r,list[j].ratio_b);
					}
					else if(list[j].weight_r == 0)
					{
						list[j].weight_r = list[j].ratio_b*list[j].weight_b/gcd(list[j].ratio_r,list[j].ratio_b*list[j].weight_b);
						list[j].weight_b = list[j].ratio_r*list[j].weight_b/gcd(list[j].ratio_r,list[j].ratio_b*list[j].weight_b);
					}
					else if(list[j].weight_b == 0)
					{
						list[j].weight_r = list[j].ratio_b*list[j].weight_r/gcd(list[j].ratio_r*list[j].weight_r,list[j].ratio_b);
						list[j].weight_b = list[j].ratio_r*list[j].weight_r/gcd(list[j].ratio_r*list[j].weight_r,list[j].ratio_b);
					}
					else
					{
						list[j].weight_r = list[j].weight_r*list[j].weight_b*list[j].ratio_b/gcd(list[j].ratio_r*list[j].weight_r,list[j].ratio_b*list[j].weight_b);
						list[j].weight_b = list[j].weight_b*list[j].weight_r*list[j].ratio_r/gcd(list[j].ratio_r*list[j].weight_r,list[j].ratio_b*list[j].weight_b);
					}
					if(list[j].parent == NULL)
					{
						printf("%lld\n",list[j].weight_r+list[j].weight_b);
						goto hell;
					}
					else if(list[j].parent->red == &list[j])
					{
						list[j].parent->red = NULL;
						list[j].parent->weight_r = list[j].weight_r+list[j].weight_b;
					}
					else
					{
						list[j].parent->blue = NULL;
						list[j].parent->weight_b = list[j].weight_r+list[j].weight_b;
					}
					list[j].flug = 0;
				}
			}
		}
		hell:;
	}
	return 0;
}
#include<stdio.h>
int main()
{
	int i,n;
	int tag=0;
	int flag=0;
	int a,b,c,d;
	int count=0;
	int t[1000][4];
	while(scanf("%d",&n)!=EOF)
	{
		for(a=0;a<10;a++)
		{
			for(b=0;b<10;b++)
			{
				for(c=0;c<10;c++)
				{
					for(d=0;d<10;d++)
					{
						if(a+b+c+d==n)
						{
							for(i=0;i<flag;i++)
							{
								if(t[i][0]!=a || t[i][1]!=b || t[i][2]!=c || t[i][3]!=d)
									tag++;
							}
			
							if(tag==flag)
							{
								t[flag][0]=a;
								t[flag][1]=b;
								t[flag][2]=c;
								t[flag][3]=d;
							}
							flag++;
							tag=0;
						}
					}
				}
			}
		}
		printf("%d\n",flag);
		flag=0;
	}
	return 0;
}
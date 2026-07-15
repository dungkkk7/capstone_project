#include<stdio.h>
#include<string.h>
char S[300];
int A,a,b,T[300],W[300];

int ltr(char *S)
{
	int r=S[0]-'0',i,t;
	for(i=2;S[i];i+=2)
	{
		t=S[i]-'0';
		if(S[i-1]=='+')r+=t;
		else r*=t;
	}
	return r;
}

int cal()
{
	int i,j,t;
	for(i=0;i<strlen(S);i++)
		T[i]=S[i]=='*'?-2:S[i]=='+'?-1:S[i]-'0';
	T[i]=-3;
	for(;;)
	{
		for(i=1,j=0;T[i]!=-3;i+=2)
		{
			if(T[i]==-2)
			{
				W[j++]=T[i-1]*T[i+1];
				for(i=i+2;T[i-1]!=-3;i++)W[j++]=T[i];
				break;
			}
			else 
			{
				W[j++]=T[i-1];
				W[j++]=T[i];
			}
		}
		if(T[i]==-3)break;
		memcpy(T,W,sizeof(T));
	}
	t=0;
	for(i=0;T[i-1]!=-3;i+=2)t+=T[i];
	return t;
}

int main()
{
	gets(S);
	scanf("%d",&A);
	a=ltr(S);
	b=cal();
	if(a==b&&A==a)puts("U");
	else if(a==A)puts("L");
	else if(b==A)puts("M");
	else puts("I");
	return 0;
}
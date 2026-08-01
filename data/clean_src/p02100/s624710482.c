#include <stdio.h>

char s[999],*p=s;
int d[10];

char*f(char*t){
	int sn=1;
	if(*t=='-')sn=-1;
	t++;
	int coe=0;
	while('0'<=*t&&*t<='9')coe=coe*10+*t++-'0';
	if(coe==0)coe=1;
	int deg;
	if(*t!='x')deg=0;
	else{
		t++;
		if(*t=='^')deg=*++t-'0',t++;
		else deg=1;
	}
	d[deg]=sn*coe;
	return t;
}

long calc(long x){
	long ans=0,s=1;
	for(int i=0;i<=5;i++)ans+=d[i]*s,s*=x;
	return ans;
}

int main(){
	scanf("%s",s+1);
	s[0]='+';
	while(*(p=f(p)));
	for(int x=-2000;x<=2000;x++)if(calc(-x)==0)printf("(x%+d)",x);
	puts("");
}

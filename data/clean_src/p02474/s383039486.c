#include <stdio.h>
#include <string.h>

char s[1010];
char t[1010];
int snum[1010],tnum[1010];
int ans[1000010];
int main(){
	scanf("%s %s",s,t);
	int sm=(s[0]=='-'),tm=(t[0]=='-');
	int sn=strlen(s+sm),tn=strlen(t+tm);
	for(int i=0;i<sn;i++)snum[i]=s[sn+sm-1-i]-'0';
	for(int i=0;i<tn;i++)tnum[i]+=t[tn+tm-1-i]-'0';
	for(int i=0;i<=1000;i++)for(int j=0;j<=1000;j++){
		ans[i+j]+=snum[i]*tnum[j];
	}
	for(int i=0;i<1000010;i++){
		ans[i+1]+=ans[i]/10;
		ans[i]%=10;
	}
	int digit=0;
	for(int i=0;i<1000010;i++)if(ans[i])digit=i;
	if((sm^tm)&&(digit>0||ans[0]!=0))printf("-");
	for(int i=digit;i>=0;i--)printf("%d",ans[i]);
	puts("");
}

#include<stdio.h>

int h[4][4],w[4][4];
char b[10][20];

int f(int n,int flag){
	if(!flag&&f(n+1,1))return 1;
	if(n==4)return 1;
	for(int i=0;i<4;i++)for(int j=0;j<10;j++){
		int cnt=0;
		for(int k=0;k<4;k++){
			if(b[i+h[n][k]][j+w[n][k]]=='.')cnt++;
			b[i+h[n][k]][j+w[n][k]]^=10;
		}
		if(cnt==4&&f(n+1,flag))return 1;
		for(int k=0;k<4;k++)b[i+h[n][k]][j+w[n][k]]^=10;
	}
	return 0;
}

int main(){
	for(int n=0;n<4;n++){
		int hh,ww,cnt=0;
		scanf("%d%d",&hh,&ww);
		for(int i=0;i<hh;i++){
			char s[10];
			scanf("%s",s);
			for(int j=0;j<ww;j++)if(s[j]=='#'){
				h[n][cnt]=i;
				w[n][cnt]=j;
				cnt++;
			}
		}
	}
	int q;
	scanf("%d",&q);
	while(q--){
		for(int n=0;n<4;n++)scanf("%s",b[n]);
		puts(f(0,0)?"Yes":"No");
	}
}


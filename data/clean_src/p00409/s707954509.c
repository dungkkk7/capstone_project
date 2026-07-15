#include<stdio.h>
#include<string.h>
#include<stdlib.h>

int main(void){
int N,Q;
scanf("%d %d",&N,&Q);
char str[N+1];
char s[2*N+1];
scanf("%s",str);
memcpy(s,str,N+1);
strcat(s,str);
int same_l;

int* p=(int*)calloc(1000,sizeof(int));
int* ps=p;
int k=0;
	for(int i=1;i<=N/2;i++){
				if(N%i==0){p[k]=i;k++;}
	}

for(int i=0;i<Q;i++){
int pi;char c;int iwa=0;

scanf("%d %c",&pi,&c);
//printf("pi-1=%d\nww3\n",pi-1);


if(i>=1 && s[pi-1]==c){
printf("%d\n",same_l);continue;
}else{
	s[pi-1]=c;
	s[N+pi-1]=c;
}


//printf("str=%s\n",s);

	for(int l=0;l<k;l++){
		iwa=0;	//printf("l=%d ",l);
//		if(N%l==0){
			for(int m=0;m<N/2;m++){
				//printf("m=%d ",m);
				if(s[m]!=s[m+p[l]]||s[N-m-1]!=s[N-m+p[l]-1]){iwa=1;break;}
			}
			if(iwa==0){printf("%d\n",p[l]);iwa=100;same_l=p[l];break;}
//		}
	}
	if(iwa!=100){same_l=N;;printf("%d\n",N);}
}

free(p);
return 0;
}


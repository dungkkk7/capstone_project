#include<stdio.h>
#define N 1000
#define M 100

int main(void){
  int i,num,j;
  char ch[M],hoge;
  int digit,c,co,count[N][M],cdigit[N];

  for(i=0;;i++){
    for(j=0;;j++){
      scanf("%c",&ch[j]);
      if(ch[j]=='\n')
        break;
    }
    digit=j;
    ch[j]=0;
    if(ch[0]=='E' &&
        ch[1]=='N' &&
        ch[2]=='D' &&
        ch[3]==' ' &&
        ch[4]=='O' &&
        ch[5]=='F' &&
        ch[6]==' ' &&
        ch[7]=='I' &&
        ch[8]=='N' &&
        ch[9]=='P' &&
        ch[10]=='U' &&
        ch[11]=='T')
      break;
    for(j=0,c=0,co=0;j<=digit;j++,co++){
      if(ch[j]==' ' || ch[j]==0){
        count[i][c]=co-1;
        c++;
        co=0;
      }
    }
    count[i][0]++;
    cdigit[i]=c;
  }

  num=i;
  for(i=0;i<num;i++){
    for(j=0;j<cdigit[i];j++)
      printf("%d",count[i][j]);
    printf("\n");
  }
  return 0;
}
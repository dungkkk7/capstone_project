/*
  AOJ 2190
  Title:
  @kankichi573
*/
#include <stdio.h>
#include <string.h>
char stairs[50001][3];
char music[50001][3];
int m,n;
char oct[]="C C#D D# E F F#G G#A A#B ";

int t2n(char tt[3])
{
        int num;
	char t[3];
	memcpy(t,tt,3);
 
        if(t[1]=='\0')
        {       t[1]=' ';
                t[2]='\0';
        }
        num=(strstr(oct,t)-oct)/2;
        return(num);
} 
int diff(char t1[],char t2[])
{
  int ret=t2n(t2)-t2n(t1);
  //printf("diff %c%c %c%c\n",t1[0],t1[1],t2[0],t2[1]);
  if(ret<0)
    ret+=12;
  return(ret);
}
solve(int st,int mu,int lv)
{
  int i;
#ifdef DEBUG
  for(i=0;i<lv;i++)printf(">");
  printf("st,mu=%d %d \n",st,mu);
#endif
  if(st>=m-1 && mu==n)
    return(1);
  if(mu==n)
    return(0);
  if(diff(&stairs[st+1][0],&music[mu+1][0])==0)
    if(solve(st+1,mu+1,lv+1))
      return(1);
  if(st < n-1 && diff(&stairs[st+2][0],&music[mu+1][0])==1)
    if(solve(st+2,mu+1,lv+1))
      return(1);
  if(st > 1 && diff(&stairs[st-1][0],&music[mu+1][0])==11)
    return(solve(st-1,mu+1,lv+1));
  return(0);
}
void dump()
{
  int i;
  for(i=1;i<=m;i++)
    printf("%2s|",&stairs[i][0]);
  printf("\n");
  for(i=1;i<=n;i++)
    printf("%2s|",&music[i][0]);
  printf("\n");
  printf("----------------\n");
}
int check_last()
{
  int diff1,diff2;

  diff1=diff(&stairs[m][0],&music[n][0]);
  diff2=diff(&stairs[m-1][0],&music[n][0]);
  return ((diff1==0||diff1==1||diff1==11) || (diff2==0||diff2==1||diff2==11));
}
main()
{
  int d,i,j,ret;
  scanf("%d",&d);
  for(i=0;i<d;i++)
    {
      scanf("%d %d",&m,&n);
      for(j=1;j<=m;j++)
	scanf("%s ",&stairs[j][0]);
      for(j=1;j<=n;j++)
	scanf("%s ",&music[j][0]);
#ifdef DEBUG
      dump();
#endif
      ret=(  check_last() && solve(0,0,0));
      printf("%s\n",ret?"Yes":"No");
    }
  return(0);
}
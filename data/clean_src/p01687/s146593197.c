/*
  AOJ 2575
  Title:D's Ambition
  @kankichi573
*/
#include <stdio.h>
#include <string.h>

char D[1001];
char result[1001];
char moji[]="AIDUNY";
char replace[]="AIZUNYAN";
int  cnt[6];
rev_sch(char * s)
{
  int i;
  char c,*p;
  /*  
  for(i=-7;i<=0;i++)
    printf("%c|",s[i]);
  printf("\n");
  */

  
  memset(cnt,0,sizeof(int)*6);
  for(i=0;i<8;i++)
    {
      if(!(p=strchr(moji,s[-i])))
	return(i);

      cnt[ p - moji]++;
      if(cnt[0]>2 || cnt[1]>1 || cnt[2]>1 || cnt[3]>1 || cnt[4]>2
	 || cnt[5]>1)
	return(7);
    }
  /* 
  for(i=0;i<6;i++)
    printf("%d:",cnt[i]);
  printf("\n");
  */
  if(cnt[0]==2 && cnt[1]==1 && cnt[2]==1 && cnt[3]==1 && cnt[4]==2
     && cnt[5]==1)
    return(-1);
  else
    return(0);
  
}
void solve()
{
  char *p,*q;
  int ret,len;

  p=D;q=result;
  strcpy(result,D);
  len=strlen(D);
  if(len<8)
    return;
  while(1)
    {
      ret=rev_sch(p+7);
      //printf("ret=%d\n",ret);
      if(ret==-1)
	{
	  strncpy(q,replace,8);
	  p+=8;
	  q+=8;
	}
      else
	{
	  p+=(8-ret);
	  q+=(8-ret);
	}
      if(p>D+len)
	break;
    }
}


main()
{
  scanf("%s",&D[0]);
  solve();
  printf("%s\n",result);
  return(0);
}
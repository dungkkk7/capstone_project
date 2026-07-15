/*
AizuOnline A1006
Title
*/
#include <stdio.h>
// Select Below
#include <stdlib.h>
#include <string.h>
//#include <float.h>
//#include <math.h>
//#include <limits.h>
//Global data section
#define MAXLEN 1000
int n;
int k;
int from[MAXLEN],to[MAXLEN];
int kugiri[MAXLEN*2+2];
int cm_flag[MAXLEN*2+2];
int start_time;
int end_time;
int total_n_of_period;
int total_kugiri;
//
int time_diff(int f,int t)
{
  int f1,t1;
  f1=(f / 100)*60 + (f % 100);
  t1=(t / 100)*60 + (t % 100);
  return(t1-f1);
}
void mv_kugiri()
{
  int i;

  kugiri[0]=start_time;
  //printf("k0:%d\n",kugiri[0]);
  for(i=0;i<total_n_of_period;i++)
    { 
      kugiri[1+i]=from[i];
      kugiri[total_n_of_period+i+1]=to[i];
    }
  kugiri[total_n_of_period*2+1]=end_time;
  total_kugiri=total_n_of_period*2+2;
}
int comp(void * x,void * y)
{
  return(*(int *)x - *(int *)y);
}
void sort_kugiri()
{
  qsort(kugiri,total_n_of_period*2+1,sizeof(int),(__compar_fn_t)comp);
}
void clear_cm_flag()
{
  memset(cm_flag,0,sizeof(cm_flag)/sizeof(int));
}
void uniq_kugiri()
{
  int i,j,p;
  p=0;
  for(i=0,j=0;i<total_n_of_period*2+2;i++)
    {
      if(i!=j)
	kugiri[j]=kugiri[i];
      if(kugiri[i+1]!=kugiri[i])
	j++;
    }
  total_kugiri=j;
}
void show()
{
  int i;

  for(i=0;i<total_kugiri;i++)
    printf("%d\n",kugiri[i]);
  printf("----\n");
}
void show2()
{
  int i;

  for(i=0;i<total_kugiri;i++)
    printf("%d(%d)\n",kugiri[i],cm_flag[i]);
  printf("----\n");
}
set_cm_flag()
{
  int i,j,p,st,en;

  for(i=0;i<total_n_of_period;i++)
    {
      st=from[i];en=to[i];
      for(j=0;j<total_kugiri;j++)
	if(kugiri[j]==st)
	  p=j;
      while(kugiri[p]<en)
	{
	  cm_flag[p]++;
	  p++;
	}
    }
}
get_max_cm_period()
{
  int i,m,s;
  m=0;s=0;

#ifdef DEBUG
	  printf("TK:%d\n",total_kugiri);
#endif

  for(i=0;i<total_kugiri-1;i++)
    {

      if(cm_flag[i] < n)
	{
	  s += time_diff(kugiri[i],kugiri[i+1]);
#ifdef DEBUG
	  printf("T:%d",s);
#endif
	  if(s > m)
	    m = s;
	}
      else
	s=0;
    }
  return(m);
}

int calc()
{
  mv_kugiri();
  sort_kugiri();
  uniq_kugiri();
  //show();
  
  clear_cm_flag();
  
  set_cm_flag();
#ifdef DEBUG
  show2();
#endif
  return(get_max_cm_period());
  /*
  return(0);
  */
}
main()
{
  int i,j,p,q,ret;

 
  while(EOF!=scanf("%d %d %d",&n,&start_time,&end_time) 
	&& (n||start_time||end_time))
    {
      q=0;
      for(i=0;i<n;i++)
	{
	  scanf("%d",&k);
	  for(p=0;p<k;p++)
	    {
	      scanf("%d ",&(from[q]));
	      scanf("%d ",&(to[q]));
	      q++;
	    }
	}
      total_n_of_period=q;
      ret=calc();
      printf("%d\n",ret);      
    }
return(0);
}
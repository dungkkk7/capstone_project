/*
  AOJ #1568
  title:String Conversion
  @kankichi57301
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


char s[100001],t[100001];
int s_cnt[26],t_cnt[26];
int n;

int comp( const void * a , const void * b ) {

  if( *( int * )a > *( int * )b ) {
    return 1;
  }
  else
  if( *( int * )a == *( int * )b ) {
    return 0;
  }
  return -1;
}

int solve(int s_c[],int t_c[])
{
  int i,ret;

  qsort(s_c,26,sizeof(int),comp);
  qsort(t_c,26,sizeof(int),comp);

  for(i=0,ret=0;i<26;i++)
    if(s_c[i]>t_c[i])
      ret += (s_c[i]-t_c[i]);
  return(ret);
}
int main()
{
  int i,ret;
  
  
  scanf("%d",&n);
  scanf("%s",s);
  scanf("%s",t);
  for(i=0;i<n;i++)
    {
      s_cnt[s[i]-'a']++;
      t_cnt[t[i]-'a']++;
    }


  ret=solve(s_cnt,t_cnt);
  printf("%d\n",ret);
  return(0);
}


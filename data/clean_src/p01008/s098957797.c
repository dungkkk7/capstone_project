/*
  AOJ 1518
  Title:Last One
  @kankichi573
*/
#include <stdio.h>
int conv(char c)
{
  if(isdigit(c))
    return(c-'0');
  if(isupper(c))
    return(c-'A'+10);
  if(islower(c))
    return(c-'a'+36);
}
int count_bits(int n)
{
  int ret=0;

  while(n)
    {
      ret += (n & 1);
      n >>= 1;
    }
  return(ret);
}
int count_bits_N(char * s,int radix)
{
  int ret=0;

  while(1)
    {
      ret += conv(*s);
      s++;
      if(!*s)	break;
      ret *= radix;
    }
  //printf("ret=%d\n",ret);
  return(count_bits(ret));
}
main()
{
  int n,p,i;
  char m[10];
  int cnt;
    
  scanf("%d",&n);
  for(i=0,cnt=0;i<n;i++)
    {
      scanf("%d %s",&p,m);
      cnt ^= count_bits_N(m,p);
    }
  printf("%s\n",(cnt)?"win":"lose");
  
  return(0);
}
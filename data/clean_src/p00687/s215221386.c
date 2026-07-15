/*
AizuOnline A1105v1
Unable Count
(TimeLimitExceeded)
*/
#include <stdio.h>

int prime[10]={2,3,5,7,11,13,17,19,23,29};
int gcd(int x,int y)
{ int w,r;
  int i,pr;
  
  for(i=0;i<10;i++)
    {
      pr=prime[i];
      if(x % pr == 0 && y % pr == 0)
	return(pr*gcd(x/pr,y/pr));
    }
  
  if(x < y)
    {
      w = x;
      x = y;
      y=  w;
    }
  if((r = x % y) ==0)
    return(y);
  return(gcd (y, r));
}

/*
int lcm(int x, int y)
{
  return(x/gcd(x,y)*y);
}
*/
/*valid n <= lcm(a,b)*/
int unable_count_simple2(int n,int a,int b)
{
  int i,j,c,ret;

  c=0;
  for(i=0;(float)i<(float)n/a;i++)
    {
      c += ((n - a*i)/b+((i)?1:0));
#ifdef DEBUG
    printf("c=%d\n",c);
#endif
    }
  ret = n-c;   
  return(ret);
}
int unable_count_single(int n,int a)
{
  return(n/a*(a-1) + (n % a)); 
}
int unable_count(int n,int a,int b)
{
  int ret;
  int gcd_ab = gcd(a,b);
  int lcm_ab = a/gcd_ab*b;

  if(lcm_ab >= n)
    return(unable_count_simple2(n,a,b));

  ret = unable_count_simple2(lcm_ab,a,b);
  ret += unable_count_single(n-lcm_ab,gcd_ab);
  return(ret);
    
}
main()
{
  int n,a,b,ret;


  while(EOF !=scanf(" %d %d %d",&n,&a,&b) && (n||a||b))
    {
      printf("%d\n",unable_count(n,a,b));
    }
return(0);
}
/*
  AOJ 2086
  Title:!
  @kankichi573
*/
#include <stdio.h>
#include <string.h>
#define min(x,y) (((x)<(y))?(x):(y))

int N;
char M[12];
char primes[]={2,3,5,7,11,13,17,19,23,29,31};
int biggest_prime(int x)
{
  int i;
  for(i=10;i>=0;i--)
    {
      //printf("%d %d::",primes[i],x % primes[i]);
      if((x % primes[i])==0)
	return(primes[i]);
    }
  return(-1);
}
// (24,2)=>3
// (16,2)=>4
int biggest_prime_times(int x,int p)
{
  if((x % p)!=0)
    return(0);
  return(1+biggest_prime_times(x/p,p));
}
int myatoi(char c)
{
  if(isdigit(c))
    return(c-'0');
  else
    return(c-'A'+10);
}
unsigned long long todecimal(char x[],int base)
{
  int i,l;
  unsigned long long ret;
  l=strlen(x);
  ret=0;
  for(i=0;i<l;i++)
    {
      ret *= base;
      ret += myatoi(x[i]);
    }
  return(ret);
}


unsigned long long devide_times(unsigned long long n,int d)
{
  unsigned long long ret,dd;
  ret=0;dd=d;
  while(dd <= n)
    {
      ret += n/dd;
      dd *= d;
    }

  return(ret);
}
main()
{
  unsigned long long ret;
  int bp; // prime

  //printf("%llu\n",devide_times(100,5));
  
  while(scanf("%d %s",&N,M) && (N || M[0]!='0'))
    {
      if(N==12)
	{
	  ret=min(devide_times(todecimal(M,N),2)/2,
		  devide_times(todecimal(M,N),3));
	}
      else if(N==24)
	{
	  ret=min(devide_times(todecimal(M,N),2)/3,
		  devide_times(todecimal(M,N),3));
	}
      else
	{
	  bp=biggest_prime(N);
	  ret=devide_times(todecimal(M,N),bp)/biggest_prime_times(N,bp);
	}
      printf("%llu\n",ret);
    }
  
  return(0);
}
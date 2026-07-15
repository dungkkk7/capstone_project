/*
 AOJ #2773
 title:Periodic Sequence
 @kankichi573
*/
#include <stdio.h>
#include <string.h>

int n,s[200000],hist[100000],fc;

int gcd(int a,int b)
{
        int c;
        while (b > 0) {
                c = a % b;
                a = b;
                b = c;
        }
        return a;
}


int all_gcd(int n,int hist[])
{
  int i,ret;

  ret = n;
  for(i=0;i<100000;i++)
    if(hist[i])
      {
	//printf("%d[%d]\n",i,hist[i]);
	ret = gcd(ret,hist[i]);
      }
  return(ret);
}
int check(int s[],int n,int g)
{
  int i;

  for(i=0;i<n-n/g;i++)
    if(s[i]!=s[i+n/g])
      return(0);
  return(1);
}

int main()
{
  int i,v,gcd_;
  scanf("%d",&n);

  for(i=0;i<n;i++)
    {
      scanf("%d",&v);
      s[i]=v;
      hist[v]++;
    }
  gcd_=all_gcd(n,hist);
  //printf("all gcd=%d\n",gcd_);
  for(i=gcd_;i>=2;i--)
    if((gcd_ % i)==0 && check(s,n,i))
      {
	printf("%d\n",i);
	goto END;
      }
  printf("1\n");
 END:
  return 0;
}
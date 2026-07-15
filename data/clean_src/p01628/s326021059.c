/*
  AOJ 2516.
  Title:next permutation
  @kankichi573
*/
#include <stdio.h>
#include <string.h>
#include <limits.h>
#define mydiff(x,y) (((x)>(y))?((x)-(y)):((y)-(x)))
int n,m;

int compare(const void *a, const void *b)
{
    return *(int*)a - *(int*)b;
}

int next_perm(int a[],int n)
{
  int i,j,p,min_,min_p,wk;

  if(a[n-2]<a[n-1])
    {
	wk=a[n-1];
	a[n-1]=a[n-2];
	a[n-2]=wk;
	return(-1);
    }


  for(i=n-1;i>=1;i--)
    if(a[i]>a[i-1])
      {
	p=a[i-1];
	min_=INT_MAX;
	for(j=i;j<n;j++)
	  if(a[j] > p && min_ > a[j])
	    {
	      min_=a[j];
	      min_p=j;
	    }
	wk=a[min_p];
	a[min_p]=a[i-1];
	a[i-1]=wk;
	qsort(&a[i],n-i,sizeof(int),compare);
        return(-1);
      }
 
  return(0);
}


void amida(int x[],int r[],int n,int m)
{
  int i,wk;
  for(i=1;i<=n;i++)
    r[i]=i;
  for(i=0;i<m;i++)
    {
      wk=r[x[i]];
      r[x[i]]=r[x[i]+1];
      r[x[i]+1]=wk;
    }
}

int height(int x[],int m)
{
  int i,j,ret,y[8],max_,max_max;

  y[0]=1;max_max=1;
  for(i=1;i<m;i++)
    {
      max_=0;
      for(j=i-1;j>=0;j--)
	if(mydiff(x[i],x[j])<2)
	    {
	      if(y[j]>max_)
		max_=y[j];
	    }
      y[i]=max_+1;
      if(y[i]>max_max)
	max_max=y[i];
    }
  return(max_max);
}

dump(int x[],int n)
{
  int i;

  for(i=0;i<n;i++)
    printf("%d|",x[i]);
  printf("\n");
}

dump2(int x[],int n)
{
  int i;

  for(i=1;i<=n;i++)
    printf("%d|",x[i]);
  printf("\n");
}

main()
{
  int i,j,x[9],r[9],r1[9],min_,h;
  

  scanf("%d %d",&n,&m);
  for(i=0;i<m;i++)
    {
      scanf("%d",&x[i]);
    }
  if(m>1)
    {
      min_=height(x,m);
      amida(x,r,n,m);
#ifdef DEBUG
      dump(x,m);
      dump2(r,n);
#endif
      qsort(x,m,sizeof(int),compare);  
      
      do
	{
	  amida(x,r1,n,m);
#ifdef DEBUG
	  dump(x,m);
	  dump2(r1,n);
#endif
	  
	  if(memcmp(r+1,r1+1,n*sizeof(int)))
	    continue;
	  
	  
	  h=height(x,m);
#ifdef DEBUG
	  printf(":h=%d\n",h);
#endif
	  if(h<min_)
	    min_=h;
	END:;	
	}  while(next_perm(x,m));
    }
  else
    min_=1;
  printf("%d\n",min_);

  return(0);
  
}
/*
A0409.c Floor
@kankichi57301

 */
#include <stdio.h>
#define LIM 34
int rect[100][4];   //0:x,1:y,2:size,3:color

void prepare()
{
  int i,siz;
  rect[0][0]=0;
  rect[0][1]=0;
  rect[0][2]=1;
  rect[0][3]=1;
  
  rect[1][0]=1;
  rect[1][1]=0;
  rect[1][2]=1;
  rect[1][3]=2;
  
  for(i=2,siz=1;i<LIM;i++)
  {
      if(i<=1)
	siz=1;
      else
        siz=rect[i-2][2]+rect[i-1][2];

    switch (i%4)
      {
      case 1:// east
	{
	  rect[i][0]=rect[i-1][0]+rect[i-1][2];
	  rect[i][1]=rect[i-1][1];
	  break;
	}
      case 2: //north
	{
	  rect[i][0]=rect[i-2][0];
	  rect[i][1]=rect[i-2][1]+rect[i-2][2];
	  break;
	}
      case 3: //west
	{
	  rect[i][0]=rect[i-3][0]-siz;
	  rect[i][1]=rect[i-2][1];
	  break;
	}
      case 0: //south
	{
	  rect[i][0]=rect[i-1][0];
	  rect[i][1]=rect[i-1][1]-siz;
	  break;
	}
      }
    rect[i][2]=siz;
    rect[i][3]=1+(i%3);
  }
}
int solve(int x,int y)
{
  int i;
  for(i=0;i<LIM;i++)
    if(x >= rect[i][0] && x< rect[i][0]+rect[i][2] && y >= rect[i][1] && y< rect[i][1]+rect[i][2])
      return(rect[i][3]);
  return(-1);  // never reach
}
void dump()
{
  int i;
  for(i=0;i<LIM;i++)
    printf("%d:%d:%d:%d \n",rect[i][0],rect[i][1],rect[i][2],rect[i][3]);
}
int main()
{
  int ret,x,y;
  prepare();
  //dump();
  scanf("%d %d",&x,&y);
  ret=solve(x,y);
  printf("%d\n",ret);
  return 0;
}


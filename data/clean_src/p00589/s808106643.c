/*
AizuOnline A1003
Title Extraordinally Grid II
*/
#include <stdio.h>
// Select Below
#include <stdlib.h>
#include <string.h>
//#include <float.h>
//#include <math.h>
//#include <limits.h>
//Global data section
char s[10001];
char result[10001];
//
char key_table(char key,int times)
{
  if(key=='1')
    return("',.!?"[times-1]);
  if(key=='7')
    return("pqrsPQRS"[times-1]);
  if(key=='8')
    return("tuvTUV"[times-1]);
  if(key=='9')
    return("wxyzWXYZ"[times-1]);
  return(((times>3)?('A'-'a'):0)+'a'+(key-'0'-2)*3+((times+2) % 3));
}
void translate()
{
  int key,times,prevkey;
  char *p,*r;

  p=s;r=result;prevkey=-1;
  while(key=*p++)
    {
      if(key=='0')
	{

	  if(prevkey=='0')
	    *r++=' ';
	  else if (prevkey != -1)
	    *r++=key_table(prevkey,times);
	  prevkey='0';
	}
      else
	if(prevkey==key)
	  {
	    times++;
	    if(key=='7' || key=='9')
	      {
		if(times >= 9)
		  times=1;
	      }
	    else if(key=='1')
	      {
		if(times >= 6)
		  times=1;
	      }
	    else
	      {
		if(times >= 7)
		  times=1;
      	      }
	  }
        else
	  {
	    if(prevkey > '0')
	      *r++=key_table(prevkey,times);
	    prevkey=key;
	    times=1;
	  }
    }
}
main()
{
  while(NULL!=fgets(s,sizeof(s),stdin))
    {
      translate();
      printf("%s\n",result);
      memset(result,0,sizeof(result));
    }
return(0);
}
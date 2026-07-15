/*
  AOJ 1087
  Title:Dimensional Analysis
  @kankichi573
  2015/9/24 WA 4/7
*/
#include <stdio.h>
#include <string.h>
#include <setjmp.h>
jmp_buf jb;
int n,m,p;
struct ryou_st
{
  char name[21];
  int  dim[5];
} ryou[10],var[15];

char D[21],formula[101];

struct ryou_st *find_var(char s[])
{
  int i;

  for(i=0;i<m;i++)
      if(0==strcmp(s,&(var[i].name[0])))
	return(&var[i]);
  return(NULL);
}

struct ryou_st *find_ryou(char s[])
{
  int i;

  for(i=0;i<m;i++)
    if(0==strcmp(s,&(ryou[i].name[0])))
      return(&ryou[i]);
  return(NULL);
}

struct ryou_st *find_ryou2(struct ryou_st *r)
{
  int i;

  for(i=m-1;i>=0;i--)
    if(0==memcmp(r->dim,ryou[i].dim,n*sizeof(int)))
      return(&ryou[i]);
  return(NULL);
}

char find_operators(char s[],int len,char s1[],char s2[],char ops[3])
{
  int i,j,lv;
  char *p;

  for(i=len-1,lv=0;i>0;i--)
    {
      if(s[i]==')')
	lv++;
      else if(s[i]=='(')
	lv--;
      if(lv==0 && (s[i]==ops[0]||s[i]==ops[1]))
      {
	for(j=0;j<i;j++)
	  s1[j]=s[j];
	s1[i]='\0';
	for(j=0;j<(len-i-1);j++)
	  s2[j]=s[j+i+1];
	s2[len-i-1]='\0';
	return(s[i]);
      }
    }
  return('\0');
}

char plus_minus(char s[],int len,char s1[],char s2[])
{
  return find_operators(s,len,s1,s2,"+-");
}
char mult_div(char s[],int len,char s1[],char s2[])
{
  return find_operators(s,len,s1,s2,"*/");
}

int is_paren_enclosed(char s[],int len)
{
  int lv,i;

  if(s[0]!='(' || s[len-1]!= ')' || len<3)
    return(0);
  for(i=lv=1;i<len-1;i++)
    {
      if(s[i]=='(')
	lv++;
      else if(s[i]==')')
	lv--;
      if(lv==0)
	return(0);
    }

  return(1);
}


struct ryou_st solve(char s[])
{
  char s1[100],s2[100],*p1,*p,*q;
  int len,multi_flag,i;
  struct ryou_st r1,r2,*ret;

  //printf("sol=%s\n",s);

  if((ret=find_var(s))!=NULL)
      return(*ret);

  len=strlen(s);
  if(is_paren_enclosed(s,len))
    {
      //printf("paren encl\n");
      strcpy(s1,s+1);
      s1[len-2]='\0';
      return(solve(s1));
    }
  
  if(plus_minus(s,len,s1,s2))
    {
      r1=solve(s1);
      r2=solve(s2);

      if(0==memcmp(r1.dim,r2.dim,5))
	return(r1);
      else
	longjmp(jb,1);
    }
  
  if(multi_flag=mult_div(s,len,s1,s2))
    {
      r1=solve(s1);
      r2=solve(s2);

      //printf("s1=%s\n",r1.name);
      //printf("s2=%s\n",r2.name);

      if(multi_flag=='*')
	for(i=0;i<n;i++)
	  r1.dim[i] += r2.dim[i];
      else
	for(i=0;i<n;i++)
	  r1.dim[i] -= r2.dim[i];
      return(r1);
    }
}


dump0(struct ryou_st * r)
{
  int i;

  printf("%s\t|",r->name);
  for(i=0;i<n;i++)
    printf("%-2d|",r->dim[i]);
  printf("\n");
}

dump1()
{
  int i;
  for(i=0;i<m;i++)
    dump0(&ryou[i]);
}

dump2()
{
  int i;

  for(i=0;i<p;i++)
    dump0(&var[i]);
}

main()
{
  int i,j;
  struct ryou_st result,*f,*ret;
  
  while(scanf("%d %d %d",&n,&m,&p)  && (n||m||p))
    {
      memset(ryou,0,sizeof(ryou));
      memset(var ,0,sizeof(var ));

      for(i=0;i<m;i++)
	{
	  scanf("%s",&(ryou[i].name[0]));
	  for(j=0;j<n;j++)
	    scanf("%d",&ryou[i].dim[j]);
	}
      //dump1();      
      scanf("%s",formula);
      for(i=0;i<p;i++)
	{
	  scanf("%s %s",var[i].name,D);
	  if((f=find_ryou(D)))
	      memcpy(&(var[i].dim[0]),&(f->dim[0]),n*sizeof(int));
	}
      //dump2();
      if(setjmp( jb ) == 0 ) 
	result=solve(formula);
      else
	{
	  printf("error\n");
	  continue;
	}
      //dump0(&result);
      ret=find_ryou2(&result);
      if(ret==NULL)
	printf("undefined\n");
      else
	printf("%s\n",ret->name);
	
    }
  return(0);
}
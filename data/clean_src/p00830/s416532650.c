#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define F 105
#define zero(n) memset(n,0,sizeof(n))
typedef struct dir
{
	int ch_num;
	char child_name[50][F],name[F];
	struct dir *child[100],*parent;
}dir;

dir *useP[500];
int used;
char stack[F][105];

dir* init(char *name,dir *pa)
{
	dir* p=(dir*)malloc(sizeof(dir));
	useP[used++]=p;
	strcpy(p->name,name);
	p->parent=pa;
	p->ch_num=0;
	return p;
}

void input()
{
	int i;char s[F],*p,d[150]="root";
	zero(stack);
	gets(s);
	strcat(d,s);
	if(d[strlen(d)-1]=='/')strcat(d,"?");
	for(i=0,p=strtok(d,"/");p;p=strtok(NULL,"/"),i++)strcpy(stack[i],p);
}

void push(int sp,dir *np)
{
	int i;
	if(!stack[sp][0])return;
	for(i=0;i<np->ch_num;i++)
		if(!strcmp(stack[sp],np->child_name[i]))
		{
			push(sp+1,np->child[i]);
			return;
		}
	strcpy(np->child_name[i],stack[sp]);
	np->child[i]=init(stack[sp],np);
	np->ch_num++;
	push(sp+1,np->child[i]);
	return;
}

dir *access(int sp,dir *np)
{
	int i;
	if(!stack[sp+1][0])//end of url
	{
		if(np->ch_num==0&&(!strcmp(stack[sp],np->name)||!strcmp("index.html",np->name)))
			return np;//np is file and dist name
		for(i=0;i<np->ch_num;i++)
			if(!strcmp("index.html",np->child_name[i])&&np->child[i]->ch_num==0)
				return np->child[i];
		return 0;
	}
	if(!strcmp(stack[sp+1],"."))
		return access(sp+1,np);
	if(!strcmp(stack[sp+1],".."))
		return (np->ch_num==0||!strcmp("root",np->name))?0:access(sp+1,np->parent);
	if(!strcmp(stack[sp+1],"?"))
	{
		for(i=0;i<np->ch_num;i++)
			if(!strcmp("index.html",np->child_name[i])&&np->child[i]->ch_num==0)
				return np->child[i];
	}
	for(i=0;i<np->ch_num;i++)
		if(!strcmp(stack[sp+1],np->child_name[i]))
			return access(sp+1,np->child[i]);
	return 0;
}

int main()
{
	int N,M,i;
		dir dbg;
	for(;scanf("%d%d\n",&N,&M),N;)
	{
		zero(useP);
		used=0;
		dir* root=init("root",0);
		for(i=0;i<N;i++)
		{
			input();
			push(1,root);
		}
		for(i=0;i<M;i++)
		{
			dir *r1,*r2;
			input();
			r1=access(0,root);
			input();
			r2=access(0,root);
			if(r1==0||r2==0)puts("not found");
			else if(r1==r2) puts("yes");
			else puts("no");
		}
		for(i=0;i<used;i++)free(useP[i]);
	}
	return 0;
}
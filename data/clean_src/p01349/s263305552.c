/*
AizuOnline A2232
Title Ennichi
*/
#include <stdio.h>
// Select Below
//#include <stdlib.h>
//#include <string.h>
//#include <float.h>
//#include <math.h>
//#include <limits.h>
//Global data section
int w,h,n;
char ban[30][30];
char ban2[30][30];
char flag[30][30];
//
int isempty()
{
        int i,j;

        for(i=0;i<h;i++)
                for(j=0;j<w;j++)
                        if(isupper(ban2[i][j]))
                                return(0);
        
        return(-1);
}
void print_ban(char ban[][30],int num)
{
        int i,j;
#ifndef DEBUG
        //if(num!=4)
                return;
#endif
        printf("---%d---\n",num);
        for(i=0;i<h;i++)
        {
                for(j=0;j<w;j++)
                        printf("%c",ban[i][j]);
                printf("\n");
        }
}
void clear_flag()
{
        int i,j;

        for(i=0;i<h;i++)
                for(j=0;j<w;j++)
                        flag[i][j]=0;
}
chk_right(int y,int x)
{
        int i;
        for(i=1;i<w-x;i++)
                if(ban2[y][x+i]!=ban2[y][x])
                        return(i);
        return(w-x);
}
chk_down(int y,int x)
{
        int i;
        for(i=1;i<h-y;i++)
                if(ban2[y+i][x]!=ban2[y][x])
                        return(i);
        return(h-y);
}

void set_flag_right(int y,int x,int l)
{
        int i;
        for(i=0;i<l;i++)
                flag[y][x+i]+=1;
}
void set_flag_down(int y,int x,int l)
{
        int i;
        for(i=0;i<l;i++)
                flag[y+i][x]+=2;
}
int all_empty(int y,int x)
{
        int i;

        if(y==0)
                return(-1);

        for(i=y-1;i>=0;i--)
                if(isalpha(ban2[i][x]))
                        return(0);
        return(-1);
}
int fall_block_in_space()
{
        int i,j,k;
        int erase_flag;

        erase_flag=0;

        for(i=0;i<h;i++)
                for(j=0;j<w;j++)
                        if(flag[i][j])
                                ban2[i][j]='.';
        print_ban(ban2,3);

        for(i=h-1;i>=0;i--)
                for(j=0;j<w;j++)
                        if(!all_empty(i,j))
                        {
                                while(ban2[i][j]=='.')
                                {
                                        erase_flag=-1;
                                        for(k=i;k>0;k--)
                                                ban2[k][j]=ban2[k-1][j];
                                        ban2[0][j]='.';
                                }
                        }
        return(erase_flag);
}
int can_all_erase()
{
        int i,j,ret1,ret2,erase_flag;

        (void)fall_block_in_space();

        do {       
                clear_flag();
            
                for(i=0;i<h;i++)
                        for(j=0;j<w;j++)
                                if(isalpha(ban2[i][j]))
                                {
                                        if(!(flag[i][j] & 1))
                                        {
                                                ret1=chk_right(i,j);
                                                //printf("CHR %d %d %d\n",i,j,ret1);
                                                if(ret1 >= n)
                                                {
                                                        set_flag_right(i,j,ret1);
                                                }
                                        }
                                        if(!(flag[i][j] & 2))
                                        {
                                                ret2=chk_down(i,j);
                                                //printf("CHD %d %d %d\n",i,j,ret2);
                                                if(ret2 >= n)
                                                {
                                                        set_flag_down(i,j,ret2);
                                                }
                                        }
                                }
                
                print_ban(ban2,2);
                erase_flag=fall_block_in_space();
                print_ban(ban2,4);
                
        
        }while(erase_flag);
        return(isempty());
}
 
void copy_ban()
{
        int i,j;

        for(i=0;i<h;i++)
                for(j=0;j<w;j++)
                        ban2[i][j]=ban[i][j];
}

int all_erasable()
{
        int i,j,wk,ret=0;
        for(i=0;i<h;i++)
                for(j=0;j<w;j++)
                {                        
                        // swap right
                        if(j<w-1 
                           && (isalpha(ban[i][j]) 
                               || isalpha(ban[i][j+1]))
                           && (ban[i][j] != ban[i][j+1]))
                        {
                                copy_ban();
                                wk=ban2[i][j];
                                ban2[i][j]=ban2[i][j+1];
                                ban2[i][j+1]=wk;
 
                                print_ban(ban2,1);
                                ret=can_all_erase();
                                if(ret)
                                        return(-1);
                        }
                }
        return(0);
}
main()
{
        int i,ret;

        while(EOF!=scanf("%d %d %d ",&h,&w,&n) && (h||w||n))
        {
                for(i=0;i<h;i++)
                        scanf("%s",&ban[i][0]);
                print_ban(ban,1);

                ret=all_erasable();

                printf("%s\n",ret?"YES":"NO");

                break;
        }
return(0);
}
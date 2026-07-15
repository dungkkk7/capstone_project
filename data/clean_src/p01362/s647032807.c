#include<stdio.h>
char dice[8][5][5];
int i,j,res,flag1,flag2;
int MIN(int x,int y){ return x<y?x:y; }
int input()
{
    for(i=1;i<=6;i++)
    {
        for(j=2;j>=0;j--)
        {
            scanf("%s",dice[i][j]);
            if(i==1&&j==2&&dice[i][j][0]=='#') return 0;
        }
    }
    return 1;
}
void f1(int a,int b)
{
    for(flag1=i=0;i<3;i++) if(dice[a][b][i]=='*') flag1=1;
}
void f2(int a,int b)
{
    for(flag2=i=0;i<3;i++) if(dice[a][b][i]=='*') flag2=1;
}
void f3(int a,int b)
{
    for(flag1=i=0;i<3;i++) if(dice[a][i][b]=='*') flag1=1;
}
void f4(int a,int b)
{
    for(flag2=i=0;i<3;i++) if(dice[a][i][b]=='*') flag2=1;
}
void C(int x)
{
    if(flag1&&flag2) res=MIN(res,x);
}
int main()
{
    while(input())
    {
        res=10000;

        f1(1,0),f2(3,0),C(0);
        f1(1,2),f2(3,2),C(2);
        f3(1,0),f4(3,2),C(1);
        f3(1,2),f4(3,0),C(1);

        f1(2,0),f2(4,0),C(3);
        f1(2,2),f2(4,2),C(3);
        f3(2,0),f4(4,2),C(2);
        f3(2,2),f4(4,0),C(2);

        for(flag1=i=0;i<3;i++) if(dice[5][0][i]=='*') flag1=1;
        for(flag2=i=0;i<3;i++) if(dice[6][2][i]=='*') flag2=1;
        C(1);
        for(flag1=i=0;i<3;i++) if(dice[5][2][i]=='*') flag1=1;
        for(flag2=i=0;i<3;i++) if(dice[6][0][i]=='*') flag2=1;
        C(1);
        for(flag1=i=0;i<3;i++) if(dice[5][i][0]=='*') flag1=1;
        for(flag2=i=0;i<3;i++) if(dice[6][2-i][0]=='*') flag2=1;
        C(2);
        for(flag1=i=0;i<3;i++) if(dice[5][i][2]=='*') flag1=1;
        for(flag2=i=0;i<3;i++) if(dice[6][2-i][2]=='*') flag2=1;
        C(2);

        printf("%d\n",res);
    }
    return 0;
}
#include<stdio.h>
int main()
{
    int c[3][2];
    int coin;
    coin=0;
    int t,n;
    int x,y;
    for(t=0;t<3;t++){
        for(n=0;n<2;n++){
            scanf("%d",&c[t][n]);
        }
    }
    for(t=0;t<3;t++){
        for(n=0;n<2;n++){
            for(x=0;x<t;x++){
                c[t][n]=c[t][n]*10;
            }
            for(y=0;y<n;y++){
                c[t][n]=c[t][n]*5;
            }
        }
    }
    for(t=0;t<3;t++){
        for(n=0;n<2;n++){
            coin=coin+c[t][n];
        }
    }
    if(1000<=coin){
        printf("1\n");
    }
    else{
        printf("0\n");
    }
    return 0;
}
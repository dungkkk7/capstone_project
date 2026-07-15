#include <stdio.h>


int main(void){
    int N;
    scanf("%d",&N);
    int a[N];
    for(int i=0;i<N;i++)scanf("%d",&a[i]);
    int b[N];
    int po[N];
    for(int i=0;i<N;i++)po[i]=0;
    for(int i=0;i<N;i++){
        scanf("%d",&b[i]);
        po[b[i]-1]++;
    }
    for(int i=0;i<N;i++){
        if(po[i]==0){
            printf("No\n");
            for(int j=0;j<N;j++){
                if(a[j]==i+1){
                    printf("1");
                }
                else printf("%d",a[j]);
                if(j!=N-1)printf(" ");
            }
            printf("\n");
            for(int j=0;j<N;j++){
                if(a[j]==i+1){
                    printf("2");
                }
                else printf("%d",a[j]);
                if(j!=N-1)printf(" ");
            }
            printf("\n");
            return 0;
        }
    }
    printf("Yes\n");
    return 0;
}

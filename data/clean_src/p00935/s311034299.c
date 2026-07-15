#include<stdio.h>

int main(void){
int n,a,i,ii,y,s[2048];
scanf("%d",&n);
for(i=1;i<=n;i++){
    scanf("%d",&a);
    s[i] = a;
}
for(i=0;i<=9;i++){
    y=0;
    for(ii=1;ii<=n;ii++){ 
        if(s[ii]==i){
            y=1;
            break;
        }
    }
    if(y==0){
        printf("%d\n",i);
        return 0;
    }
}
for(i=10;i<=99;i++){
    y=0;
    for(ii=1;ii<=n-1;ii++){ 
        if(s[ii]==i/10 &&s[ii+1]==i%10){
            y=1;
            break;
        }
    }
    if(y==0){
        printf("%d\n",i);
        return 0;
    }
}
for(i=100;i<=999;i++){
    y=0;
    for(ii=1;ii<=n-2;ii++){ 
        if(s[ii]==i/100 &&s[ii+1]==(i/10)%10 &&s[ii+2]==i%10){
            y=1;
            break;
        }
    }
    if(y==0){
        printf("%d\n",i);
        return 0;
    }
}
return 0;
}
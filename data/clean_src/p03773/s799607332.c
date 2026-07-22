#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stdlib.h>
#include <stdbool.h>
#define MOD 1000000007
#define END printf("\n");return 0;
void input_array(int how_data,int *data);
void input_array2(int first , int second , int data[][60]);
int get_random(int min, int max);
int factorial(int n);
int fibonacci(int n);
int qsort_09(const int *sys1 , const int *sys2);
int qsort_90(const int *sys1 , const int *sys2);
int sel_max(int a , int b);
int sel_min(int a , int b);
int array_max(int how_data,int *data);
int array_min(int how_data,int *data);
int can_DP(int how_data,int *data,int how_can,bool *can);
int array_sum(int how_data,int *data);
int Leven_dist(char *now , char *target);

int loop1,loop2,loop3,loop4,loop5,i_temp;
char c_temp;

int main(void){
    int a,b;
    scanf("%d %d",&a,&b);
    printf("%d\n",(a+b)%24);
    return 0;
}


//how_data個の配列data[]に標準入力
//input_array(how_data,data);
void input_array(int how_data,int *data){
    int loop;
    for(loop=0;loop<how_data;loop++){
        scanf("%d",&data[loop]);
    }
    return ;
}

void input_array2(int first,int second,int data[][60]){
    int loopA,loopB;
    for(loopA=0;loopA<first;loopA++){
        for(loopB=0;loopB<second;loopB++){
            scanf("%d",&data[loopA][loopB]);
        }
    }
    return ;
}

int get_random(int min, int max){   //指定の範囲から乱数を1つ返すやつ
    //srand((unsigned int)time(0));   //現在時刻で疑似乱数初期化
    rand();rand();rand();rand();    //乱数を空打ち
    return (rand()%(max+1-min))+min;
}


int factorial(int n){//n!のMOD10^9+7を返すやつ
    unsigned long long int ret=1;
    for(int i=1;i<=n;i++)ret=(ret*i)%1000000007;
    return (int)ret;
}

int qsort_09(const int *sys1 , const int *sys2){ //小さいのが上にくるやつ
    //qsort(data,how_data,sizeof(int),(int (*)(const void *,const void *))qsort_09);
    if(*sys1<*sys2){
        return -1;
    }else if(*sys1==*sys2){
        return 0;
    }else{
        return 1;
    }
}

int qsort_90(const int *sys1 , const int *sys2){ //大きいのが上にくるやつ
    //qsort(data,how_data,sizeof(int),(int (*)(const void *,const void *))qsort_90);
    if(*sys1<*sys2){
        return 1;
    }else if(*sys1==*sys2){
        return 0;
    }else{
        return -1;
    }
}

int fibonacci(int n){
    switch(n){
        case 0:return 0;
        case 1:return 1;
        default :return fibonacci(n-1)+fibonacci(n-2);
    }
}

int sel_max(int a,int b){
    if(a>b)return a;
    return b;
}

int sel_min(int a,int b){
    if(a>b)return b;
    return a;
}

int can_DP(int how_data,int *data,int how_can,bool *can){//Typical DP Contest A
    //data内で組み合わせられる和をcanに0 or 1で入れる
    //返り値はパターン数
    int loopA,loopB;
    int ret=0;
    for(loopA=0;loopA<how_can;loopA++){//初期化
        can[loopA]=0;
    }
    can[0]=1;//絶対にありえる
    for(loopA=0;loopA<how_data;loopA++){
        for(loopB=how_can-1;loopB>=0;loopB--){
            if(can[loopB]==1 && loopB+data[loopA]<how_can){
                can[loopB+data[loopA]]=1;
            }
        }
    }
    for(loopA=0;loopA<how_can;loopA++){
        if(can[loopA]==1){
            ret++;
        }
    }
    return ret;
}
int array_max(int how_data,int *data){
    int loop;
    int ret=data[0];
    for(loop=0;loop<how_data;loop++){
        if(ret<data[loop])ret=data[loop];
    }
    return ret;
}
int array_min(int how_data,int *data){
    int loop;
    int ret=data[0];
    for(loop=0;loop<how_data;loop++){
        if(ret>data[loop])ret=data[loop];
    }
    return ret;
}
int array_sum(int how_data,int *data){
    int ret=0;
    int loop;
    for(loop=0;loop<how_data;loop++){
        ret+=data[loop];
    }
    return ret;
}
int Leven_dist(char *now , char *target){
    int loopA,loopB;
    //レーベンシュタイン距離を求める
    // 参考文献
    // http://nw.tsuda.ac.jp/class/algoB/c13.html  (アルゴリズム理解)
    // http://d.hatena.ne.jp/ohnishiakira/20090809/1249845529  (実装)
    int len_now=strlen(now)+1;
    int len_target=strlen(target)+1;
    int d[len_now][len_target]; //計算用
    for(loopA=0;loopA<len_now;loopA++) d[loopA][0]=loopA;
    for(loopA=0;loopA<len_target;loopA++) d[0][loopA]=loopA;
    for(loopA=1;loopA<len_now;loopA++){
        for(loopB=1;loopB<len_target;loopB++){
            int cost=(now[loopA-1]==target[loopB-1] ? 0:1);
            d[loopA][loopB]=sel_min(sel_min(d[loopA-1][loopB]+1,d[loopA][loopB-1]+1),d[loopA-1][loopB-1]+cost);
        }
    }
    return d[len_now-1][len_target-1];
}

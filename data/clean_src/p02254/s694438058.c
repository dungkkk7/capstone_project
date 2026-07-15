#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define AZ 'z'-'a'+1

typedef struct t{
    struct t *parent;
    int score;
}Tree;

Tree* make(int count){
    Tree *t=(Tree*)malloc(sizeof(Tree));
    t->score = count;
    t->parent = NULL;
    return t;
}

int depth(Tree *t,int c){
    if(t==NULL){
        if(c==0){c=1;}
        return c;
    }
    return depth(t->parent,c+1);
}

int main(void){
    char s[100001];
    int count[AZ][2];
    int n,nn,len,i,j,f;
    int min1,num1,min2,num2,sum;
    Tree *ts,**t,*p,*exc;
    scanf("%s",s);
    len = strlen(s);
    n=0;
    for(i=0;i<len;i++){
        f=0;
        for(j=0;j<n;j++){
            if(count[j][0]==s[i]){
                count[j][1]++;
                f=1;
                break;
            }
        }
        if(f==0){
            count[n][0]=s[i];
            count[n][1]=1;
            n++;
        }
    }
    nn=n;
    ts = (Tree*)malloc(sizeof(Tree)*n);t = (Tree**)malloc(sizeof(Tree*)*n);
    for(i=0;i<n;i++){
        ts[i].score=count[i][1];
        ts[i].parent=NULL;
        t[i] = &ts[i];
    }
    while(nn>1){
        min1 = t[0]->score;num1=0;
        min2 = t[1]->score;num2=1;
        if(min1>min2){
            i=min1;min1=min2;min2=i;
            i=num1;num1=num2;num2=i;
        }
        for(i=2;i<nn;i++){
            if(min1>t[i]->score){
                min2=min1;num2=num1;
                min1=t[i]->score;num1=i;
            }else if(min2>t[i]->score){
                min2=t[i]->score;num2=i;
            }
        }
        p = make(t[num1]->score+t[num2]->score);
        t[num1]->parent=p;t[num2]->parent=p;
        if(num1==nn-1){
            if(num2!=nn-2){
                exc=t[num2];t[num2]=t[nn-2];t[nn-2]=exc;
            }
        }else if(num1==nn-2){
            if(num2!=nn-1){
                exc=t[num2];t[num2]=t[nn-1];t[nn-1]=exc;
            }
        }else if(num2==nn-1){
            exc=t[num1];t[num1]=t[nn-2];t[nn-2]=exc;
        }else if(num2==nn-2){
            exc=t[num1];t[num1]=t[nn-1];t[nn-1]=exc;
        }else{
            exc=t[num1];t[num1]=t[nn-1];t[nn-1]=exc;
            exc=t[num2];t[num2]=t[nn-2];t[nn-2]=exc;
        }
        nn--;
        t[nn-1]=p;
    }
    sum=0;
    for(i=0;i<n;i++){
        sum+=depth(ts[i].parent,0)*ts[i].score;
    }
    printf("%d\n",sum);
}

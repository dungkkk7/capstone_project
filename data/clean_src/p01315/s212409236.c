#include<stdio.h>
#include<string.h>

int N;
typedef 
struct data{
  long long a,b;
} data;
 
data t[50];
char u[50][21];

int check(int x,int y){
  if(t[x].a*t[y].b < t[y].a*t[x].b)return 1;
  else if(t[x].a*t[y].b == t[y].a*t[x].b)return 0;
  else return -1;
}

void change(int x,int y){
  data tmp;
  tmp=t[x];
  t[x]=t[y];
  t[y]=tmp;
  char tmp2[21];
  strcpy(tmp2,u[x]);
  strcpy(u[x],u[y]);
  strcpy(u[y],tmp2);
}

int main(){
  int i,j;
  while(1){
    scanf("%d",&N);
    if(N==0)break;

    for(i=0;i<N;i++){
      int p,a,b,c,d,e,f,s,m;
      scanf("%s %d %d %d %d %d %d",u[i],&p,&a,&b,&c,&d,&e);
      scanf("%d %d %d",&f,&s,&m);
      t[i]=(data){f*s*m-p,a+b+c+(d+e)*m};
    }
    for(i=N-1;i>0;i--){
      for(j=0;j<i;j++){
        if(check(j,j+1)==1){
          change(j,j+1);
        }else if(check(j,j+1)==0 && strcmp(u[j],u[j+1]) > 0){
          change(j,j+1);
        }
      }
    }
    for(i=0;i<N;i++)printf("%s\n",u[i]);
    printf("#\n");
  }
  return 0;
}
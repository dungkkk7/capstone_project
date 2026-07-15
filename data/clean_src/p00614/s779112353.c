#include<stdio.h>
#include<limits.h>
#define LIM  667000
int P,C[6] = {1,5,10,50,100,500};
int N[6],R[6],limit;
int clerk[LIM];
int i,j;
  

int getChange(int sum){ // clerk
  int ret = 0;
  int l;
  for(l=5;l>=0;l--){
    if(sum >= C[l]){
      ret += sum/C[l];
      sum -= sum/C[l]*C[l];
    }    
  }
  return ret;
}

int getChangeBy(int sum){
  int ret = 0;
  int index = sum;
  int e;
  for(e = 0;e<6;e++)R[e] = 0;
  for(e=5;e>=0;e--){
    if(sum >= C[e] && N[e] != 0){
      R[e] = sum/C[e]>N[e]?N[e]:sum/C[e];
      sum -= R[e]*C[e];
ret += R[e];      
    } 
  }
  if(sum != 0)return -1;
  return ret;
}

void createChange(){
  for(i=0;i<LIM;i++)clerk[i] = 0;
  int B,f;
  for(f=1;f<666001;f++){  
    B = getChange(f);
    clerk[f] = B;
    //if(f < 100)printf("%d\n",clerk[f]);
  }

}


int main(){
  createChange();
 
  while(scanf("%d",&P) && P){
    int cnt,pay,ans,res;

 
    
     limit = 0;
     int u;
     for(u=0;u<6;u++){
       scanf("%d",&N[u]);
       
       limit += N[u]*C[u];
     }

    
    ans = INT_MAX;
    for(i=0;i<limit;i++)clerk[i] = -1;
    for(i=P;i<=P+500;i++){
      cnt = getChangeBy(i); 
      if(cnt == -1 || ans <= cnt)continue;
      pay = 0;
      for(j = 0;j<6;j++)pay += C[j]*R[j];
      if(clerk[pay-P] == -1)clerk[pay-P] = getChange(pay-P);
      if(cnt+clerk[pay-P] < ans){
	ans = cnt+clerk[pay-P];
      }
    }
    printf("%d\n",ans);

  }
  return 0;
}
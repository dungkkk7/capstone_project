#include <stdio.h>

struct data{
  int x, y;
}map[100][100];

int keisan(int, int,int);
int hantei[100][100];
int n, ans;
main(){
  int i, j, ans;

  while(1){
    scanf("%d", &n);
    if(n==0) break;

    for(i=0;i<n;i++){
      for(j=0;j<n;j++){
	scanf("%d%d", &map[i][j].x, &map[i][j].y);
      }
    }
    
    ans=0;
    for(i=0;i<n;i++){
      for(j=0;j<n;j++){
	hantei[i][j]=0;
      }
    }

    for(i=0;i<n;i++){
      for(j=0;j<n;j++){
	if(hantei[i][j]==0){
	  ans=keisan(i,j, ans);
	}
      }
    }

     printf("%d\n", ans);
  }
  return 0;
}

int keisan(int y, int x, int ans){
  int i, j, tx, ty, f=0, a, b;
  int hantei2[100][100];
  for(i=0;i<n;i++){
    for(j=0;j<n;j++){
      hantei2[i][j]=0;
    }
  }
  while(1){
    if(y==0 && x==3){
    }
    if(hantei[y][x]==1 && hantei2[y][x]==1){
      f=1;
      hantei[y][x]=2;
    }
    else if(hantei[y][x]==1 && hantei2[y][x]==0){
      f=0;
      break;
    }
    else if(hantei[y][x]==2){ 
      break;
    }
    else{
      if(y==0 && x==3){
    }
      hantei[y][x]=1;
      hantei2[y][x]=1;
    }
    tx = map[y][x].x;
    ty = map[y][x].y;      
    x=tx;
    y=ty;
  }
  if(f){
    ans++;
  }
  return ans;
}
#include <stdio.h>

main(){
  int n, i, j, k, l, f;
  int data[5][5];
  int ans, temp[2], count;

  scanf("%d", &n);

  for(i=0;i<n;i++){
    for(j=0;j<5;j++){
      for(k=0;k<5;k++){
        scanf("%d", &data[j][k]);
      }
    }
    ans=-1;

    for(j=0;j<5;j++){
      temp[0]=0;
      for(k=0;k<5;k++){
        if(data[j][k]==1){
          temp[1]=0;
          for(l=0;k+l<5;l++){
            if(data[j][k+l]==0) break;
            else if(data[j][k+l]==1) temp[1]++;
          }
          if(temp[0]<temp[1]) temp[0]=temp[1];
          k=k+l-1;
        }
      }
      if(ans<temp[0]) ans=temp[0];
    }
    for(j=0;j<4;j++){
      temp[0]=0;
      for(k=0;k<5;k++){
        if(data[j][k]==1 && data[j+1][k]==1){
          temp[1]=0;
          for(l=0;k+l<5;l++){
            if(data[j][k+l]==0 || data[j+1][k+l]==0) break;
            else if(data[j][k+l]==1 && data[j+1][k+l]==1) temp[1]+=2;
          }
          if(temp[0]<temp[1]) temp[0]=temp[1];
        }
      }
      if(ans<temp[0]) ans=temp[0];
    }
    for(j=0;j<3;j++){
      temp[0]=0;
      for(k=0;k<5;k++){
        if(data[j][k]==1 && data[j+1][k]==1 && data[j+2][k]==1){
          temp[1]=0;
          for(l=0;k+l<5;l++){
            if(data[j][k+l]==0 || data[j+1][k+l]==0 || data[j+2][k+l]==0) break;
            else if(data[j][k+l]==1 && data[j+1][k+l]==1 && data[j+2][k+l]==1) temp[1]+=3\
;
          }
          if(temp[0]<temp[1]) temp[0]=temp[1];
        }
      }
      if(ans<temp[0]) ans=temp[0];
    }
    for(j=0;j<2;j++){
      temp[0]=0;
      for(k=0;k<5;k++){
        if(data[j][k]==1 && data[j+1][k]==1 && data[j+2][k]==1 && data[j+3][k]==1){
          temp[1]=0;
          for(l=0;k+l<5;l++){
            if(data[j][k+l]==0 || data[j+1][k+l]==0 || data[j+2][k+l]==0 || data[j+3][k+l\
]==0) break;
            else if(data[j][k+l]==1 && data[j+1][k+l]==1 && data[j+2][k+l]==1 && data[j+3\
][k+l]==1) temp[1]+=4;
          }
          if(temp[0]<temp[1]) temp[0]=temp[1];
        }
      }
      if(ans<temp[0]) ans=temp[0];
    }
    for(j=0;j<1;j++){
      temp[0]=0;
      for(k=0;k<5;k++){
        if(data[j][k]==1 && data[j+1][k]==1 && data[j+2][k]==1 && data[j+3][k]==1 && data\
[j+4][k]==1){
          temp[1]=0;
          for(l=0;k+l<5;l++){
            if(data[j][k+l]==0 || data[j+1][k+l]==0 || data[j+2][k+l]==0 || data[j+3][k+l\
]==0 || data[j+4][k+l]==0) break;
            else if(data[j][k+l]==1 && data[j+1][k+l]==1 && data[j+2][k+l]==1 && data[j+3\
][k+l]==1 && data[j+4][k+l]==1) temp[1]+=5;
          }
          if(temp[0]<temp[1]) temp[0]=temp[1];
        }
      }
      if(ans<temp[0]) ans=temp[0];
    }
    printf("%d\n", ans);
  }
  return 0;
}
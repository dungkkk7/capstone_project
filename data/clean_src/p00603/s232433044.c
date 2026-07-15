#include <stdio.h>
int data[51], a[51], b[51], c1[51];
int n, t, count;

void shuffle(int);
int toridasia(int);
int toridasib(int);

main(){
  int r, i, c;

  while(1){
    if(scanf("%d %d", &n, &r)==EOF) break;

    for(i=0;i<n;i++){
      data[i]=i;
    }
    
    if(n%2==0) t=n/2;
    else t=n/2+1;

    for(i=0;i<r;i++){
      scanf("%d", &c);

      shuffle(c);
    }

    printf("%d\n", data[n-1]);
  }
  return 0;
}

void shuffle(int c){
  int i, j, p1, p2;

  for(i=0, j=0;i<n;i++, j++){
    if(i==n-t){
      b[j]=-1;
      j=0;
    }
    if(i<=n-t-1){
      b[j]=data[i];
    }
    else{
      a[j]=data[i];
    }
  }
  a[j]=-1;

  count=0;
  while(1){
    p1=toridasia(c);
    p2=toridasib(c);
    if(p1==1 && p2==1) break;
  }


  for(i=0;i<n;i++){
    data[i]=c1[i];
  }
}

int toridasia(int c){
  int temp[50];
  int i, j, temp1;

  for(i=0;i<c;i++){
    if(a[i]==-1) return 1;
    c1[count]=a[i];
    count++;
  }
  temp1=i;
  for(i=0;i<50;i++){
    if(a[temp1+i]==-1) break;
    temp[i]=a[temp1+i];
  }
  
  temp[i]=-1;

  for(i=0;i<50;i++){
    a[i]=temp[i];
    if(temp[i]==-1) break;
  }
  return 0;
}


int toridasib(int c){
  int temp[50];
  int i, j, temp1;

  for(i=0;i<c;i++){
    if(b[i]==-1) return 1;
    c1[count]=b[i];
    count++;
  }
  temp1=i;
  for(i=0;i<50;i++){
    if(b[temp1+i]==-1) break;
    temp[i]=b[temp1+i];
  }
  
  temp[i]=-1;

  for(i=0;i<50;i++){
    b[i]=temp[i];
    if(temp[i]==-1) break;
  }
  return 0;
}
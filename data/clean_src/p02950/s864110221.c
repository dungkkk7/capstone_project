#include <stdio.h>

int p;
int b0;
int A[3000];
int primes[11];
int ps;

int root;
int iroot;
int dlog[3000];

int modpow(int x, int n){
  int r=1;
  for(;n;n>>=1){
    if(n&1) r = r * x % p;
    x = x * x % p;
  }
  return r;
}



int main(){
  int i, j, x, q;
  scanf("%d", &p);
  if(p == 2) root = 1;
  else {
    q = p-1;
    for(i=2;i*i<=q;i++){
      if(q % i == 0){
        primes[ps++] = i;
        do {q /= i;} while(q % i == 0);
      }
    }
    if(q != 1) primes[ps++] = q;
    for(i=2;i<30;i++){
      for(j=0;j<ps;j++){
        if(modpow(i, (p-1)/primes[j]) == 1) break;
      }
      if(j == ps){
        root = i;
        break;
      }
    }
  }
  x = 1;
  for(i=0;i<p-1;i++){
    dlog[x] = i;
    x = x * root % p;
  }
  iroot = modpow(root, p-2);
  scanf("%d", &b0);
  for(i=1;i<p;i++){
    int x;
    scanf("%d", &x);
    A[dlog[i]] = (x + p - b0) * modpow(i, p-2) % p;
  }

  printf("%d ", b0);
  for(i=0;i<p-1;i++){
    int r=0;
    for(j=0;j<p-1;j++){
      r = (r + modpow(iroot, i*j) * A[j]) % p;
    }
    r = r * modpow(p-1, p-2) % p;
    printf("%d ", r);
  }

  return 0;
}

/*
 * FileName:     rotate
 * CreatedDate:  2020-05-24 16:16:25 +0900
 * LastModified: 2020-07-10 22:06:17 +0900
 */

#include <stdio.h>
#include <stdlib.h>
void rotate(long int *a, long int *c, int b, int m, int e){
    for(int k=0; k<e-b; k++){
        int modul = (k+(e-m))%(e-b);
        c[b+modul] = a[b+k];
    }
}
void copy(long int *a, long int *c, int n){
    for(int i=0; i<n; i++){
        a[i] = c[i];
    }
}
int main(void){
    int n;scanf("%d", &n);
    long int *a = malloc(n*sizeof(long int));
    long int *c = malloc(n*sizeof(long int));
    for(int i=0; i<n; i++){
        scanf("%ld", a+i);
        c[i] = a[i];
    }

    int q;scanf("%d", &q);
    for(int i=0; i<q; i++){
        int b, m, e;scanf("%d%d%d", &b, &m, &e);
        rotate(a, c, b, m, e);
        copy(a, c, n);
    }
    printf("%ld", a[0]);
    for(int i=1; i<n; i++){
        printf(" %ld", a[i]);
    }
    printf("\n");
    free(a);
    free(c);
    return 0;
}


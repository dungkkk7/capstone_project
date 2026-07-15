#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef struct {
    int time;
    int len;
    int no;
} ICICLE;

int mymax(int a, int b)
{
    if (a > b){
        return (a);
    }
    return (b);
}

int comp(const void *a , const void *b)
{
    ICICLE *x, *y;
    x = (ICICLE*) a;
    y = (ICICLE*) b;
    
    return ((y->len) - (x->len));
}

int main(void)
{
    static ICICLE t[100001], m[100001];
    int mlen;
    int n, r;
    int i, j;
    int ans;
    
    scanf("%d%d", &n, &mlen);
    
    for (i = 0; i < n; i++){
        scanf("%d", &t[i].len);
        t[i].no = i;
    }
    
    memcpy(m, t, sizeof(t));
    
    qsort(t, n, sizeof(ICICLE), comp);
    r = n;
    
    ans = 0;
    while (r){
        for (i = 0; i < n; i++){
            if (t[i].no != 0 && t[i].no != n - 1){
                if (t[i].time == 0 && (m[t[i].no - 1].len < t[i].len || m[t[i].no - 1].time != 0) && (m[t[i].no + 1].len < t[i].len || m[t[i].no + 1].time != 0)){
                    t[i].time = (mlen - t[i].len) + mymax(m[t[i].no - 1].time, m[t[i].no + 1].time);
                    ans = mymax(ans, t[i].time);
                    m[t[i].no].time = t[i].time;
                    r--;
                }
            }
            else if (t[i].no == 0){
                if (t[i].time == 0 && (m[t[i].no + 1].len < t[i].len || m[t[i].no + 1].time != 0)){
                    t[i].time = (mlen - t[i].len) + m[t[i].no + 1].time;
                    ans = mymax(ans, t[i].time);
                    m[t[i].no].time = t[i].time;
                    r--;
                }
            }
            else {
                if (t[i].time == 0 && (m[t[i].no - 1].len < t[i].len || m[t[i].no - 1].time != 0)){
                    t[i].time = (mlen - t[i].len) + m[t[i].no - 1].time;
                    ans = mymax(ans, t[i].time);
                    m[t[i].no].time = t[i].time;
                    r--;
                }
            }
        }
    }
    
    printf("%d\n", ans);
    
    return (0);
}
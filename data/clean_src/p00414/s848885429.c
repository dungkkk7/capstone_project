#include <stdio.h>
#include <string.h>

unsigned long long ipow(unsigned long long x, unsigned long long y)
{
    unsigned long long r;
    
    r = 1;
    while (y-- > 0){
        r *= x;
    }
    
    return (r);
}


int main(void)
{
    int L, N;
    char snake[102];
    unsigned long long len_o;
    unsigned long long len_x;
    unsigned long long sum;
    int i;
    
    scanf("%d%d", &L, &N);
    scanf("%s", snake);
    strcat(snake, "x");
    L++;

    sum = 0;
    len_o = 0;
    len_x = 0;
    for (i = 0; i <= L; i++){
        if (snake[i] == 'x'){
            len_x++;
        }
        if (len_o == 0){
            if (snake[i] == 'o'){
                len_o = 1;
            }
        }
        else {
            if (snake[i] == 'o'){
                len_o++;
            }
            else {
                sum += 3 * (ipow(2, N) - 1) * (len_o - 1) + len_o;
                len_o = 0;
            }
        }
    }
    
    sum += len_x - 1;
    
    printf("%llu\n", sum);

    return (0);
}


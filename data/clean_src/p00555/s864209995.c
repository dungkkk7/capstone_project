#include <stdio.h>

int field[100][100][3];

int main(void)
{
    int N, M, D;
    char in_str[101];
    int n;
    int i, j;
    
    scanf("%d%d%d", &N, &M, &D);
    
    for (i = 0; i < N; i++){
        scanf("%s", in_str);
        for (j = 0; j < M; j++){
            if (in_str[j] == '#'){
                field[i][j][0] = 1;
            }
        }
    }
    
    for (i = 0; i < N; i++){
        n = 0;
        for (j = M - 1; j >= 0; j--){
            if (field[i][j][0] == 0){
                n++;
                field[i][j][1] = n;
            }
            else {
                n = 0;
            }
        }
    }
    
    for (j = 0; j < M; j++){
        n = 0;
        for (i = N - 1; i >= 0; i--){
            if (field[i][j][0] == 0){
                n++;
                field[i][j][2] = n;
            }
            else {
                n = 0;
            }
        }
    }
#if 0
    for (i = 0; i < N; i++){
        for (j = 0; j < M; j++){
            printf("[%d,%d]", field[i][j][1], field[i][j][2]);
        }
        printf("\n");
    }
#endif
    n = 0;
    for (i = 0; i < N; i++){
        for (j = 0; j < M; j++){
            if (field[i][j][1] >= D){
                n++;
            }
            if (field[i][j][2] >= D){
                n++;
            }
        }
    }

    printf("%d\n", n);
    
    return (0);
}







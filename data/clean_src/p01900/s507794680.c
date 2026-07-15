//AOJ V28_2800 Mod!Mod!
//Author:Mikoron

#include<stdio.h>
#include<stdlib.h>
#include<string.h>

int main(void) {

        int det_num, det_count = 0, sum = 0;
        int count_zero = 0, count_one = 0, count_two = 0;
        int i;
        char *tp, uma_rod[500000*2];

        scanf("%d\n", &det_num);
        if(det_num < 0 || det_num > 500000) return 1;

        fgets(uma_rod, sizeof(uma_rod),stdin);
        tp = strtok(uma_rod, " ");
        i = 0;
        while(tp) {
                uma_rod[i] = atoi(tp);
                if(uma_rod[i] < 1 || uma_rod[i] > 9) return 1;
                tp = strtok(NULL, " ");
                i++;
        }

        //mod 3 の結果でケースを分ける
        for(i = 0; i < det_num; i++) {
                switch(uma_rod[i]%3) {
                        case 0:
                                count_zero++;
                                break;
                        case 1:
                                count_one++;
                                break;
                        case 2:
                                count_two++;
                                break;
                        default:
                                return 1;
                }
        }

        //printf("case0:%d, case1:%d, case2:%d\n", count_zero, count_one, count_two);

        //各ケースから数を取り出し足し合わせて,盗める人数を計算
        while(1) {

                //printf("det_num=%d:sum=%d:count_zero=%d:count_one=%d:count_two=%d\n", det_num, sum, count_zero, count_one, count_two);

                //1回目にケース0しかない場合はその時点で終了
                if(det_count == 0 && count_one == 0 && count_two == 0) {
                        det_count++;
                        break;
                }

                //合計が3の倍数にならないように、かつ、個数の多いケースから足し合わせていく
                if((count_one >= count_two || count_two <= 0 || (sum+2)%3 == 0) && (sum+1)%3 != 0 && count_one > 0) {
                        count_one--;
                        det_count++;
                        sum++;
                }else if((sum+2)%3 != 0 && count_two > 0) {
                        count_two--;
                        det_count++;
                        sum += 2;
                }else if(count_zero > 0) {
                        count_zero--;
                        det_count++;
                }else{
                        if(count_one > 0 || count_two > 0) det_count++;
                        break;
                }
        }

        printf("%d\n", det_count);

        return 0;
}


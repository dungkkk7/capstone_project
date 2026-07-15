#include<stdio.h>
#define TMAX 100001
#define THALF 70000
int main(void){
    int N, T, in, out, sw, max=0, i, j;
	int time[TMAX];
    scanf("%d%d", &N, &T);
	scanf("%d%d", &in, &out);
	sw = (THALF > out-in ? 1 : 2);
	switch(sw){
		case 1:
			for(j=0; j<T; j++){
				*(time+j) = 0;
			}
  			for(j=in; j<out; j++){
               	*(time+j) += 1;
            }
			for(i=1; i<N; i++){
				scanf("%d%d", &in, &out);
 		    	for(j=in; j<out; j++){
               		*(time+j) += 1;
           		}
    		}
		    for(j=0; j<T; j++){
		        max = (max < *(time+j) ? *(time+j) : max);
		    }
			break;
		case 2:
			for(j=0; j<T; j++){
				*(time+j) = N;
			}
			for(j=0; j<in; j++){
				*(time+j) -= 1;
			}
			for(j=out; j<=T; j++){
				*(time+j) -= 1;
			}
			for(i=1; i<N; i++){
				scanf("%d%d", &in, &out);
				for(j=0; j<in; j++){
					*(time+j) -= 1;
				}
				for(j=out; j<=T; j++){
					*(time+j) -= 1;
				}
			}
			for(j=0; j<T; j++){
				max = (max < *(time+j) ? *(time+j) : max);
			}
			break;
		default:
			break;
	}
    printf("%d\n", max);
    return 0;
}
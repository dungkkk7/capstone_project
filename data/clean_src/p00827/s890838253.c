#include <stdio.h>

#define INF 999999999

void updateAns(int a,int b,int ta,int tb,int *ans_a,int *ans_b){
	if(*ans_a + *ans_b > ta + tb){
		*ans_a = ta;
		*ans_b = tb;
	}
	else if(*ans_a + *ans_b == ta + tb){
		if(a * ta + b * tb < a * (*ans_a) + b * (*ans_b)){
			*ans_a = ta;
			*ans_b = tb;
		}
	}
}

int main(void){
	int i,j;
	int a,b,d;
	int ta,tb,ans_a,ans_b;

	while(scanf("%d%d%d",&a,&b,&d) && (a||b||d)){
		ans_a = INF;
		ans_b = INF;

		for(i=0;i<=100000;i++){
			if((a * i + d) % b == 0){
				ta = i;
				tb = (a * i + d) / b;
				updateAns(a,b,ta,tb,&ans_a,&ans_b);
			}
			if(a * i >= d && (a * i - d) % b == 0){
				ta = i;
				tb = (a * i - d) / b;
				updateAns(a,b,ta,tb,&ans_a,&ans_b);
			}
			if(a * i <= d && (d - a * i) % b == 0){
				ta = i;
				tb = (d - a * i) / b;
				updateAns(a,b,ta,tb,&ans_a,&ans_b);
			}
		}

		printf("%d %d\n",ans_a,ans_b);
	}

	return 0;
}
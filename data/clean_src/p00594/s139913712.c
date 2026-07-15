#include<stdio.h>
#include<stdlib.h>

int compare_int(const void *a,const void *b){
	return *(int*)a - *(int*)b;
}

int x[100000000];

int main(void){
	int n;
	int i,j;
	int count = 1;
	int ans = -1;
	while(scanf("%d",&n)){
		if(n == 0){
			break;
		}
		if(n == 1){
			scanf("%d",&x[0]);
			printf("%d\n",x[0]);
			continue;
		}
		for(i = 0;i < n;i++){
			scanf("%d",&x[i]);
		}
		qsort(x,n,sizeof(int),compare_int);
		/*for(i = 0;i < n + 3;i++){
			printf("%d ",x[i]);
		}
		printf("\n");*/
		for(i = 0;i < n - 1;i++){
			if(x[i] == x[i+1]){
				for(j = i;j < n - 1;j++){
					if(x[j] == x[j+1]){
						count++;
					}
					else{
						break;
					}
				}
			}
			if(count > n / 2){
				ans = x[i];
				break;
			}
			count = 1;
		}
		if(ans == -1){
			printf("NO COLOR\n");
			count = 1;
		}
		else{
			printf("%d\n",ans);
			ans = -1;
			count = 1;
		}
	}
	return 0;
}
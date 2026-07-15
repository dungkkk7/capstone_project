#include<stdio.h>
#include<math.h>
#define STANDARD 22;

struct BodyData
{
	int number;
	double bmi;
	double ideal_body;
};

int main(void) {
	int n,h,w,flag;
	int i,j;
	double a;
	struct BodyData data[1000],*p,temp;

	p = data;
	while (1) {
		scanf("%d",&n);
		if (n == 0)break;
		for (i = 0; i < n; i++) {
			scanf("%d %d %d",&data[i].number,&h,&w);
			data[i].bmi = w / pow((double)h / 100, 2);
			a = data[i].bmi - STANDARD;
			data[i].ideal_body = fabs(a);
		}
	
		for (i = 0; i < n; i++) {
			for (j = i+1; j < n; j++) {
				flag = 0;
				if ((p + i)->ideal_body == (p + j)->ideal_body) {
					if ((p + i)->number > (p + j)->number)flag = 1;
				}
				else if ((p + i)->ideal_body > (p + j)->ideal_body)
					flag = 1;
				if (flag) {
					temp = *(p + i);
					*(p + i) = *(p + j);
					*(p + j) = temp;
				}
			}
		}
		printf("%d\n",p->number);
	}
	return 0;
}
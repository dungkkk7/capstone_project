#define _CRT_SECURE_NO_WARNINGS
#define _USE_MATH_DEFINES
 
#include<stdio.h>
#include<math.h>
#include<string.h>
#include<stdlib.h>
#include<stdarg.h>
#include<malloc.h>

int main()
{
	char RF[128];
	int AF, i;

	while(scanf("%s", RF) != EOF){

		i = 0;
		AF = 0;

		while(1){

			if(RF[i] == 'M') {
				AF += 1000;
				i++;
			} else if(RF[i] == 'D') {
				if(RF[i+1] == 'M') {
					AF += 500;
					i += 2;
				} else {
					AF += 500;
					i++;
				}
			} else if(RF[i] == 'C') {
				if(RF[i+1] == 'D') {
					AF += 400;
					i += 2;
				} else if(RF[i+1] == 'M') {
					AF += 900;
					i += 2;
				} else {
					AF += 100;
					i++;
				}
			} else if(RF[i] == 'L') {
				if(RF[i+1] == 'C') {
					AF += 50;
					i += 2;
				} else if(RF[i+1] == 'D') {
					AF += 450;
					i += 2;
				} else if(RF[i+1] == 'M') {
					AF += 950;
					i += 2;
				} else {
					AF += 50;
					i++;
				}
			} else if(RF[i] == 'X') {
				if(RF[i+1] == 'L') {
					AF += 40;
					i += 2;
				} else if(RF[i+1] == 'C') {
					AF += 90;
					i += 2;
				} else if(RF[i+1] == 'D') {
					AF += 490;
					i += 2;
				} else if(RF[i+1] == 'M') {
					AF += 990;
					i += 2;
				} else {
					AF += 10;
					i++;
				}
			} else if(RF[i] == 'V') {
				if(RF[i+1] == 'X') {
					AF += 5;
					i += 2;
				} else if(RF[i+1] == 'L') {
					AF += 45;
					i += 2;
				} else if(RF[i+1] == 'C') {
					AF += 95;
					i += 2;
				} else if(RF[i+1] == 'D') {
					AF += 495;
					i += 2;
				} else if(RF[i+1] == 'M') {
					AF += 995;
					i += 2;
				} else {
					AF += 5;
					i++;
				}
			} else if(RF[i] == 'I') {
				if(RF[i+1] == 'V') {
					AF += 4;
					i += 2;
				} else if(RF[i+1] == 'X') {
					AF += 9;
					i += 2;
				} else if(RF[i+1] == 'L') {
					AF += 49;
					i += 2;
				} else if(RF[i+1] == 'C') {
					AF += 99;
					i += 2;
				} else if(RF[i+1] == 'D') {
					AF += 499;
					i += 2;
				} else if(RF[i+1] == 'M') {
					AF += 999;
					i += 2;
				} else {
					AF++;
					i++;
				}
			} else
				break;

		}
		printf("%d\n", AF);

	}

	return 0;
}
#include <stdio.h>
int main(void) {
	int n, count;
	int a, b, c, d;

	while (scanf("%d", &n) != EOF){
		count = 0;
		a = 9; b = 9; c = 9; d = 9;
		if (n >= 37){
			printf("%d\n", count);
		}
		else{
			if ((9 + 9 + 9 + 9) == n) count++;
			for (d = 8; d >= 0; d--){
				if ((a + b + c + d) == n){
					count++;
				}
			}

			for (c = 8; c >= 0; c--){
				for (d = 9; d >= 0; d--){
					if ((a + b + c + d) == n){
						count++;
					}
				}
			}
			for (b = 8; b >= 0; b--){
				for (c = 9; c >= 0; c--){
					for (d = 9; d >= 0; d--){
						if ((a + b + c + d) == n){
							count++;
						}
					}
				}
			}
			for (a = 8; a >= 0; a--){
				for (b = 9; b >= 0; b--){
					for (c = 9; c >= 0; c--){
						for (d = 9; d >= 0; d--){
							if ((a + b + c + d) == n){
								count++;
							}
						}
					}
				}
			}
			printf("%d\n", count);
		}
	}
	return 0;
}
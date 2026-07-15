#include <stdio.h>
#include <string.h>

unsigned int Binary(int a)
{
	int keta;
	int ans;
	
	ans = 0;
	keta = 1;
	while (a != 0){
		ans += keta * (a % 2);
		a /= 2;
		keta *= 10;
	}
	
	return (ans);
}

int main(void)
{
	char str[10000];
	char *str2;
	char s[50000];
	char buf[10000];
	char str3[50000];
	int i;
	char c;
	
	
	
	while (fgets(str, sizeof(str), stdin) != NULL){
		str[strlen(str) - 1] = '\0';
		str2 = s;
		
		
		s[0] = '\0';
		for (i = 0; i < strlen(str); i++){
			if ('A' <= str[i] && str[i] <= 'Z'){
				snprintf(buf, 6, "%05d", Binary(str[i] - 'A'));
			}
			else {
				switch (str[i]){
				  case ' ':
				  	snprintf(buf, 6, "%05d", 11010);
					break;
					
				  case '.':
				  	snprintf(buf, 6, "%05d", 11011);
					break;
					
				  case ',':
				  	snprintf(buf, 6, "%05d", 11100);
					break;
					
				  case '-':
				  	snprintf(buf, 6, "%05d", 11101);
					break;
					
				  case 39:
				  	snprintf(buf, 6, "%05d", 11110);
					break;
					
				  case '?':
				  	snprintf(buf, 6, "%05d", 11111);
					break;
				}
			}
			
			strcat(s, buf);
		}
		
		/*printf("%s\n", str2);*/
		
		
		/*復号*/
		str3[0] = '\0';
		while (1){
			/*1行目*/
			if (strncmp("101", str2, 3) == 0){
				strcat(str3, " ");
				str2 += 3;
				continue;
			}
			if (strncmp("000000", str2, 6) == 0){
				strcat(str3, "'");
				str2 += 6;
				continue;
			}
			if (strncmp("000011", str2, 6) == 0){
				strcat(str3, ",");
				str2 += 6;
				continue;
			}
			if (strncmp("10010001", str2, 8) == 0){
				strcat(str3, "-");
				str2 += 8;
				continue;
			}
			if (strncmp("010001", str2, 6) == 0){
				strcat(str3, ".");
				str2 += 6;
				continue;
			}
			if (strncmp("000001", str2, 6) == 0){
				strcat(str3, "?");
				str2 += 6;
				continue;
			}
			if (strncmp("100101", str2, 6) == 0){
				strcat(str3, "A");
				str2 += 6;
				continue;
			}
			if (strncmp("10011010", str2, 8) == 0){
				strcat(str3, "B");
				str2 += 8;
				continue;
			}
			
			/*2行目*/
			if (strncmp("0101", str2, 4) == 0){
				strcat(str3, "C");
				str2 += 4;
				continue;
			}
			if (strncmp("0001", str2, 4) == 0){
				strcat(str3, "D");
				str2 += 4;
				continue;
			}
			if (strncmp("110", str2, 3) == 0){
				strcat(str3, "E");
				str2 += 3;
				continue;
			}
			if (strncmp("01001", str2, 5) == 0){
				strcat(str3, "F");
				str2 += 5;
				continue;
			}
			if (strncmp("10011011", str2, 8) == 0){
				strcat(str3, "G");
				str2 += 8;
				continue;
			}
			if (strncmp("010000", str2, 6) == 0){
				strcat(str3, "H");
				str2 += 6;
				continue;
			}
			if (strncmp("0111", str2, 4) == 0){
				strcat(str3, "I");
				str2 += 4;
				continue;
			}
			if (strncmp("10011000", str2, 8) == 0){
				strcat(str3, "J");
				str2 += 8;
				continue;
			}
			
			/*3行目*/
			if (strncmp("0110", str2, 4) == 0){
				strcat(str3, "K");
				str2 += 4;
				continue;
			}
			if (strncmp("00100", str2, 5) == 0){
				strcat(str3, "L");
				str2 += 5;
				continue;
			}
			if (strncmp("10011001", str2, 8) == 0){
				strcat(str3, "M");
				str2 += 8;
				continue;
			}
			if (strncmp("10011110", str2, 8) == 0){
				strcat(str3, "N");
				str2 += 8;
				continue;
			}
			if (strncmp("00101", str2, 5) == 0){
				strcat(str3, "O");
				str2 += 5;
				continue;
			}
			if (strncmp("111", str2, 3) == 0){
				strcat(str3, "P");
				str2 += 3;
				continue;
			}
			if (strncmp("10011111", str2, 8) == 0){
				strcat(str3, "Q");
				str2 += 8;
				continue;
			}
			if (strncmp("1000", str2, 4) == 0){
				strcat(str3, "R");
				str2 += 4;
				continue;
			}
			
			/*4行目*/
			if (strncmp("00110", str2, 5) == 0){
				strcat(str3, "S");
				str2 += 5;
				continue;
			}
			if (strncmp("00111", str2, 5) == 0){
				strcat(str3, "T");
				str2 += 5;
				continue;
			}
			if (strncmp("10011100", str2, 8) == 0){
				strcat(str3, "U");
				str2 += 8;
				continue;
			}
			if (strncmp("10011101", str2, 8) == 0){
				strcat(str3, "V");
				str2 += 8;
				continue;
			}
			if (strncmp("000010", str2, 6) == 0){
				strcat(str3, "W");
				str2 += 6;
				continue;
			}
			if (strncmp("10010010", str2, 8) == 0){
				strcat(str3, "X");
				str2 += 8;
				continue;
			}
			if (strncmp("10010011", str2, 8) == 0){
				strcat(str3, "Y");
				str2 += 8;
				continue;
			}
			if (strncmp("10010000", str2, 8) == 0){
				strcat(str3, "Z");
				str2 += 8;
				continue;
			}
			break;
		}
		/*printf("OK\n");*/
		printf("%s\n", str3);
	}
	
	return (0);
}
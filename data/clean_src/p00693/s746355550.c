#include <stdio.h>

typedef struct {
	int permit;
	char from_addr[12];
	char to_addr[12];
} rule_t;

typedef struct {
	char from_addr[12];
	char to_addr[12];
	char message[52];
	int allowed;
} packet_t;

int rule_num;
rule_t rules[1024];
int packet_num;
packet_t packets[1024];

int is_match(const char* addr,const char* rule) {
	int i;
	for(i=0;i<8;i++) {
		if(rule[i]!='?' && addr[i]!=rule[i])return 0;
	}
	return 1;
}

int main(void) {
	char buffer[8];
	int i,j;
	int allowed_num;
	while(1) {
		scanf("%d%d",&rule_num,&packet_num);
		if(rule_num==0 && packet_num==0)break;
		for(i=0;i<rule_num;i++) {
			scanf("%s%s%s",buffer,rules[i].from_addr,rules[i].to_addr);
			if(buffer[0]=='p')rules[i].permit=1;
			else rules[i].permit=0;
		}
		allowed_num=0;
		for(i=0;i<packet_num;i++) {
			scanf("%s%s%s",packets[i].from_addr,packets[i].to_addr,
				packets[i].message);
			packets[i].allowed=0;
			for(j=0;j<rule_num;j++) {
				if(is_match(packets[i].from_addr,rules[j].from_addr) &&
						is_match(packets[i].to_addr,rules[j].to_addr)) {
					packets[i].allowed=rules[j].permit;
				}
			}
			if(packets[i].allowed)allowed_num++;
		}
		printf("%d\n",allowed_num);
		for(i=0;i<packet_num;i++) {
			if(packets[i].allowed) {
				printf("%s %s %s\n",
					packets[i].from_addr,packets[i].to_addr,
					packets[i].message);
			}
		}
	}
	return 0;
}
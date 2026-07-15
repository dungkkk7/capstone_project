#include <stdio.h>

/*[which card][for multiple cards of the same number]*/
int acl[1001][5000];
int acl_num[1001];
int acl_used[1001];

int main(void) {
	int b_cards[5000];
	int num_a,num_b;
	int start;
	int i,j;
	int currentcard;
	int currentpos=-1;
	int currentscore=0;
	int maxscore=0;
	int ok;
	scanf("%d%d",&num_a,&num_b);
	for(i=0;i<num_a;i++) {
		scanf("%d",&currentcard);
		/*record where the cards are*/
		acl[currentcard][acl_num[currentcard]]=i;
		acl_num[currentcard]++;
	}
	for(i=0;i<num_b;i++) {
		scanf("%d",&b_cards[i]);
	}
	for(start=0;start<num_b;start++) {
		for(j=1;j<=1000;j++)acl_used[j]=0;
		currentscore=0;
		currentpos=-1;
		for(i=start;i<num_b;i++) {
			currentcard=b_cards[i];
			ok=0;
			while(acl_num[currentcard]-acl_used[currentcard]>0) {
				if(acl[currentcard][acl_used[currentcard]]>currentpos) {
					ok=1;
					break;
				}
				acl_used[currentcard]++;
			}
			if(ok) {
				currentpos=acl[currentcard][acl_used[currentcard]];
				acl_used[currentcard]++;
				currentscore++;
			} else {
				break;
			}
		}
		if(currentscore>maxscore)maxscore=currentscore;
	}
	printf("%d\n",maxscore);
	return 0;
}
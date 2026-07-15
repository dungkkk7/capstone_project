#include <stdio.h>
#include <string.h>

#define UF_MAX 26

int uf_table[UF_MAX];

void uf_init(void) {
	int i;
	for(i=0;i<UF_MAX;i++)uf_table[i]=0;
}

void uf_merge(int a,int b) {
	int next;
	while(uf_table[a]>0) {
		next=uf_table[a]-1;
		if(uf_table[next]>0)uf_table[a]=uf_table[next];
		a=next;
	}
	while(uf_table[b]>0) {
		next=uf_table[b]-1;
		if(uf_table[next]>0)uf_table[b]=uf_table[next];
		b=next;
	}
	if(a!=b)uf_table[a]=b+1;
}

int uf_issame(int a,int b) {
	int next;
	while(uf_table[a]>0) {
		next=uf_table[a]-1;
		if(uf_table[next]>0)uf_table[a]=uf_table[next];
		a=next;
	}
	while(uf_table[b]>0) {
		next=uf_table[b]-1;
		if(uf_table[next]>0)uf_table[b]=uf_table[next];
		b=next;
	}
	return a==b;
}

int main(void) {
	int n,i;
	int count_first[26];
	int count_last[26];
	int have_connection[26];
	char now_word[36];
	int now_first,now_last;
	int first_exist;
	while(1) {
		scanf("%d",&n);
		if(n==0)break;
		uf_init();
		memset(count_first,0,sizeof(count_first));
		memset(count_last,0,sizeof(count_last));
		memset(have_connection,0,sizeof(have_connection));
		for(i=0;i<n;i++) {
			scanf("%s",now_word);
			now_first=now_word[0]-'a';
			now_last=now_word[strlen(now_word)-1]-'a';
			count_first[now_first]++;
			count_last[now_last]++;
			if(now_first!=now_last)uf_merge(now_first,now_last);
		}
		first_exist=-1;
		for(i=0;i<26;i++) {
			if(count_first[i]>0 || count_last[i]>0) {
				if(first_exist<0)first_exist=i;
				if(!uf_issame(first_exist,i))break;
			}
			if(count_first[i]!=count_last[i])break;
		}
		puts(i<26?"NG":"OK");
	}
	return 0;
}
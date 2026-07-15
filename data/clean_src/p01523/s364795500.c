#include <stdio.h>
#include <stdlib.h>

int pqueue_max=0;
int pqueue[128];

void pqueue_adjust(int pos) {
	while(1) {
		int max=pos;
		int pos2;
		pos2=pos*2+1;
		if(pos2<pqueue_max && pqueue[pos2]>pqueue[max])max=pos2;
		pos2=pos*2+2;
		if(pos2<pqueue_max && pqueue[pos2]>pqueue[max])max=pos2;
		if(max!=pos) {
			int temp;
			temp=pqueue[pos];
			pqueue[pos]=pqueue[max];
			pqueue[max]=temp;
			pos=max;
		} else {
			if(pos==0)break;
			pos=(pos-1)/2;
		}
	}
}

void pqueue_add(int num) {
	int pos=pqueue_max++;
	pqueue[pos]=num;
	pqueue_adjust(pos);
}

int pqueue_top(void) {
	if(pqueue_max<=0)return 0;
	return pqueue[0];
}

void pqueue_pop(void) {
	if(pqueue_max<=0)return;
	pqueue[0]=pqueue[--pqueue_max];
	pqueue_adjust(0);
}

typedef struct {
	int a,b;
} kyozyu_t;

int qsort_comp(const void* x,const void* y) {
	const kyozyu_t* a=(const kyozyu_t*)x;
	const kyozyu_t* b=(const kyozyu_t*)y;
	/* syozyun of a */
	if((a->a)>(b->a))return 1;
	if((a->a)<(b->a))return -1;
	/* kozyun of b */
	if((a->b)<(b->b))return 1;
	if((a->b)>(b->b))return -1;
	return 0;
}

int main(void) {
	int N,M;
	kyozyu_t kyozyu[100];
	int i;
	int now=0;
	int count=0;
	scanf("%d%d",&N,&M);
	for(i=0;i<M;i++)scanf("%d%d",&kyozyu[i].a,&kyozyu[i].b);
	qsort(kyozyu,M,sizeof(kyozyu_t),qsort_comp);
	for(i=0;i<M;i++) {
		if(kyozyu[i].a<=now+1) {
			pqueue_add(kyozyu[i].b);
		} else {
			int next=pqueue_top();
			if(next<=now) {
				count=-1;
				break;
			}
			count++;
			now=next;
			pqueue_pop();
			i--;
			if(now>=N)break;
		}
	}
	if(now<N) {
		if(pqueue_top()<N)count=-1;
		else count++;
	}
	if(count<0)puts("Impossible"); else printf("%d\n",count);
	return 0;
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DIJKSTRA_MAX_NODE 11000
#define DIJKSTRA_MAX_EDGE 2000000

typedef struct {
	short from,to;
	int cost;
} dijkstra_edge_t;

typedef struct {
	short node;
	int cost;
} dijkstra_node_t;

int dijkstra_edge_num;
dijkstra_edge_t dijkstra_edge[DIJKSTRA_MAX_EDGE];
int dijkstra_node_edge[DIJKSTRA_MAX_NODE][2];
int dijkstra_queue_num;
dijkstra_node_t dijkstra_queue[DIJKSTRA_MAX_EDGE+1];
int dijkstra_cost[DIJKSTRA_MAX_NODE];
char dijkstra_visited[DIJKSTRA_MAX_NODE];

int dijkstra_comp(const void* x,const void* y) {
	const dijkstra_edge_t* a=(const dijkstra_edge_t*)x;
	const dijkstra_edge_t* b=(const dijkstra_edge_t*)y;
	if((a->from)>(b->from))return 1;
	if((a->from)<(b->from))return -1;
	if((a->to)>(b->to))return 1;
	if((a->to)<(b->to))return -1;
	return 0;
}

void dijkstra_queue_adjust(int pos) {
	int min=pos;
	if(pos*2+1<dijkstra_queue_num &&
		dijkstra_queue[min].cost>dijkstra_queue[pos*2+1].cost)
			min=pos*2+1;
	if(pos*2+2<dijkstra_queue_num &&
		dijkstra_queue[min].cost>dijkstra_queue[pos*2+2].cost)
			min=pos*2+2;
	if(min!=pos) {
		dijkstra_node_t temp;
		temp=dijkstra_queue[min];
		dijkstra_queue[min]=dijkstra_queue[pos];
		dijkstra_queue[pos]=temp;
		dijkstra_queue_adjust(min);
	} else if(pos>0)dijkstra_queue_adjust((pos-1)/2);
}

void dijkstra_queue_push(short node,int cost) {
	dijkstra_node_t topush;
	topush.node=node;topush.cost=cost;
	dijkstra_queue[dijkstra_queue_num++]=topush;
	dijkstra_queue_adjust(dijkstra_queue_num-1);
}

dijkstra_node_t dijkstra_queue_pop(void) {
	dijkstra_node_t result=dijkstra_queue[0];
	if(dijkstra_queue_num>0) {
		dijkstra_queue[0]=dijkstra_queue[--dijkstra_queue_num];
		dijkstra_queue_adjust(0);
	}
	return result;
}

void dijkstra_init(void) {
	dijkstra_edge_num=0;
}

void dijkstra_addedge(short from,short to,int cost) {
	dijkstra_edge[dijkstra_edge_num].from=from;
	dijkstra_edge[dijkstra_edge_num].to=to;
	dijkstra_edge[dijkstra_edge_num].cost=cost;
	dijkstra_edge_num++;
}

void dijkstra_setup(void) {
	int i;
	int prev;
	qsort(dijkstra_edge,dijkstra_edge_num,
		sizeof(dijkstra_edge_t),dijkstra_comp);
	prev=0;
	memset(dijkstra_node_edge,0,sizeof(dijkstra_node_edge));
	dijkstra_node_edge[0][0]=0;
	for(i=0;i<dijkstra_edge_num;i++) {
		if(dijkstra_edge[i].from!=dijkstra_edge[prev].from) {
			dijkstra_node_edge[dijkstra_edge[prev].from][1]=i;
			dijkstra_node_edge[dijkstra_edge[i].from][0]=i;
			prev=i;
		}
	}
	dijkstra_node_edge[dijkstra_edge[prev].from][1]=i;
}

int dijkstra_search(short from,short to) {
	int i;
	memset(dijkstra_cost,0xFF,sizeof(dijkstra_cost));
	memset(dijkstra_visited,0,sizeof(dijkstra_visited));
	dijkstra_queue_num=0;
	dijkstra_queue_push(from,0);
	while(dijkstra_queue_num>0) {
		dijkstra_node_t nownode=dijkstra_queue_pop();
		if(!dijkstra_visited[nownode.node]) {
			dijkstra_visited[nownode.node]=1;
			dijkstra_cost[nownode.node]=nownode.cost;
			for(i=dijkstra_node_edge[nownode.node][0];
					i<dijkstra_node_edge[nownode.node][1];i++) {
				if(!dijkstra_visited[dijkstra_edge[i].to] &&
						(dijkstra_cost[dijkstra_edge[i].to]<0 ||
						dijkstra_cost[dijkstra_edge[i].to]>nownode.cost+dijkstra_edge[i].cost)) {
					dijkstra_queue_push(
						dijkstra_edge[i].to,
						nownode.cost+dijkstra_edge[i].cost
					);
					dijkstra_cost[dijkstra_edge[i].to]=nownode.cost+dijkstra_edge[i].cost;
				}
			}
		}
	}
	return dijkstra_cost[to];
}

int get_id(int node, int syozikin) {
	return syozikin*100+node;
}

int main(void) {
	int N,M,L;
	while(scanf("%d%d%d",&N,&M,&L)==3 && (N|M|L)!=0) {
		int i,j;
		dijkstra_init();
		for(i=0;i<M;i++) {
			int A,B,D,E;
			scanf("%d%d%d%d",&A,&B,&D,&E);
			A--;B--;
			for(j=0;j<=100;j++) {
				/* mukakin (osowareru) */
				dijkstra_addedge(get_id(A,j),get_id(B,j),E);
				dijkstra_addedge(get_id(B,j),get_id(A,j),E);
				/* kakin (osowarenai) */
				if(j>=D) {
					dijkstra_addedge(get_id(A,j),get_id(B,j-D),0);
					dijkstra_addedge(get_id(B,j),get_id(A,j-D),0);
				}
			}
		}
		/* goal */
		for(i=1;i<=100;i++) {
			dijkstra_addedge(get_id(N-1,i),get_id(N-1,i-1),0);
		}
		dijkstra_setup();
		printf("%d\n",dijkstra_search(get_id(0,L),get_id(N-1,0)));
	}
	return 0;
}
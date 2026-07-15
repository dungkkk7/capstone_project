#include <stdio.h>

#define TRUE        1
#define FALSE       0

#define CITY_MAX    101
#define TICKET_MAX  10
#define LINE_MAX    (501*2)

#define COST_MAX    10000000

#define QUE_SIZE    (LINE_MAX*TICKET_MAX)


int mincost[CITY_MAX][TICKET_MAX];
int gone[CITY_MAX][TICKET_MAX];

int first_line[CITY_MAX]; /* first index of a bus departing from the city */

int line_dst[LINE_MAX];  /* destination */
int line_cost[LINE_MAX]; /* cost */
int line_next[LINE_MAX]; /* next index of a bus departing from the same city */

/* priority queue */
typedef struct _QueItem {
    int cost;
    int city;
    int ticket;
} QueItem;
QueItem heapq[QUE_SIZE]; /* index 0: unuse, index 1.. : que */
int quecnt;

void enq(QueItem a);
QueItem deq();
int qcmp(QueItem a, QueItem b);


int main(){
    QueItem item,item2;
    int c,n,m,s,d;
    int a,b,f;
    int i,j;
    int ans;

    while(1){
        /* ram init */
        quecnt=0;
        for(i=0;i<CITY_MAX;i++){
            first_line[i]=-1;
            for(j=0;j<TICKET_MAX;j++){
                mincost[i][j]=COST_MAX;
                gone[i][j]=FALSE;
            }
        }

        /* input */
        scanf("%d %d %d %d %d",&c,&n,&m,&s,&d);
        if(c==0)break;

        for( i=0; i<m; i++ ){
            scanf("%d %d %d",&a,&b,&f);
            /* b -> a */
            line_dst[i*2] = a;
            line_cost[i*2] = f;
            line_next[i*2] = first_line[b];
            first_line[b] = i*2;
            /* a -> b */
            line_dst[i*2+1] = b;
            line_cost[i*2+1] = f;
            line_next[i*2+1] = first_line[a];
            first_line[a] = i*2+1;
        }

        /* dijkstra */
        item.cost=0;
        item.city=s;
        item.ticket=c;
        enq(item);
        while(quecnt>0){
            item = deq();
            if(gone[item.city][item.ticket])continue;
            gone[item.city][item.ticket] = TRUE;
            mincost[item.city][item.ticket] = item.cost;

            /* all bus line from item.city */
            i=first_line[item.city];
            while(i>=0){
                int dst = line_dst[i];
                int cost = line_cost[i];
                /* ticket nouse */
                if(gone[dst][item.ticket]==FALSE){
                    item2.cost=item.cost+cost;
                    item2.city=dst;
                    item2.ticket=item.ticket;
                    enq(item2);
                }
                /* ticket use */
                if(item.ticket>0 && gone[dst][item.ticket]==FALSE){
                    item2.cost=item.cost+cost/2;
                    item2.city=dst;
                    item2.ticket=item.ticket-1;
                    enq(item2);
                }
                i = line_next[i];
            }
        }

        ans=COST_MAX;
        for(i=0;i<c;i++){
            if(mincost[d][i]<ans)ans=mincost[d][i];
        }
        printf("%d\n",ans);
    }

    return 0;
}

/* add a to heapq */
void enq(QueItem a){
    int i;
    QueItem tmp;
    quecnt++;
    heapq[quecnt] = a;
    for(i=quecnt;i/2>0;i/=2){
        if(qcmp(heapq[i/2],heapq[i]))break;
        tmp = heapq[i];
        heapq[i] = heapq[i/2];
        heapq[i/2] = tmp;
    }
}

/* get highest priority item in heapq */
QueItem deq(){
    int i,target;
    QueItem tmp,ret;
    ret = heapq[1];
    heapq[1] = heapq[quecnt];
    quecnt--;
    for(i=1;i*2<=quecnt;){
        if( i*2+1<=quecnt && qcmp(heapq[i*2+1],heapq[i]) ){
            if( qcmp(heapq[i*2],heapq[i*2+1]) ){
                target = i*2;
            }else{
                target = i*2+1;
            }
        }else if( qcmp(heapq[i*2],heapq[i]) ){
            target = i*2;
        }else{
            break;
        }
        tmp = heapq[i];
        heapq[i] = heapq[target];
        heapq[target] = tmp;
        i = target;
    }
    return ret;
}

/* return TRUE if priority(a) > priority(b) */
int qcmp(QueItem a, QueItem b){
    return (a.cost<b.cost);
}
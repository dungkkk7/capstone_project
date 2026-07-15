#include <stdio.h>

#define INF 100000000

#define MAX_N_NODE 100
int nodes_c[MAX_N_NODE][MAX_N_NODE];
int nodes_t[MAX_N_NODE][MAX_N_NODE];
int n_nodes;
int min_cost[MAX_N_NODE];
int is_used[MAX_N_NODE];

void init_nodes(void)
{
    int i,j;
    for(i=0;i<MAX_N_NODE;i++){
        for(j=0;j<MAX_N_NODE;j++){
            nodes_c[i][j]=-1;
            nodes_t[i][j]=-1;
        }
    }
}

//warning: a,b starts from one
void set_node(int a,int b,int c,int t)
{
    a--; b--;
    nodes_c[a][b]=nodes_c[b][a]=c;
    nodes_t[a][b]=nodes_t[b][a]=t;
}

//warning: p,q starts from one
int dijkstra_c(int p,int q)
{
    int start=p-1,goal=q-1;

    int i;
    for(i=0;i<n_nodes;i++){
        min_cost[i]=INF;
        is_used[i]=0;
    }
    min_cost[goal]=0;

    while(1){
        // the unused node with minimum cost become used
        int min_val=INF, min_node;
        int n_unused=0;
        for(i=0;i<n_nodes;i++){
            if(is_used[i]){ continue; }
            if(min_val>=min_cost[i]){
                min_val=min_cost[i];
                min_node=i;
            }
            n_unused++;
        }
        //no unused node, then exit
        if(n_unused==0){ return min_cost[start]; }
        //become used
        is_used[min_node]=1;
        //updated cost of node connected new used node
        for(i=0;i<n_nodes;i++){
            if(nodes_c[min_node][i]<0){ continue; }
            if(min_cost[i]>min_cost[min_node]+nodes_c[min_node][i]){
                min_cost[i]=min_cost[min_node]+nodes_c[min_node][i];
            }
        }
    }
}
int dijkstra_t(int p,int q)
{
    int start=p-1,goal=q-1;

    int i;
    for(i=0;i<n_nodes;i++){
        min_cost[i]=INF;
        is_used[i]=0;
    }
    min_cost[goal]=0;

    while(1){
        int min_val=INF, min_node, n_unused=0;
        for(i=0;i<n_nodes;i++){
            if(is_used[i]){ continue; }
            if(min_val>=min_cost[i]){
                min_val=min_cost[i]; 
                min_node=i;
            }
            n_unused++;
        }
        if(n_unused==0){ return min_cost[start]; }
        is_used[min_node]=1;

        for(i=0;i<n_nodes;i++){
            if(nodes_t[min_node][i]<0){ continue; }
            if(min_cost[i]>min_cost[min_node]+nodes_t[min_node][i]){
                min_cost[i]=min_cost[min_node]+nodes_t[min_node][i];
            }
        }
    }
}

//#define DEBUG
int main(void)
{
    FILE *fpin;
#ifdef DEBUG
    fpin=fopen("input.txt","r");
#else
    fpin=stdin;
#endif

    while(1){
        int n,m; //num of lines and station
        fscanf(fpin,"%d %d\n",&n,&m);
        if(n==0 && m==0){ break; } //exit case

        init_nodes();
        n_nodes=m;
        int i;
        for(i=0;i<n;i++){
            int a,b,c,t; //start, goal, cost, time
            fscanf(fpin,"%d %d %d %d\n",&a,&b,&c,&t);
            set_node(a,b,c,t); 
        }

        int k; //num of access
        fscanf(fpin,"%d\n",&k);
        for(i=0;i<k;i++){
            int p,q,r;
            fscanf(fpin,"%d %d %d\n",&p,&q,&r);
            printf("%d\n",
                    (r==0)?
                    dijkstra_c(p,q):
                    dijkstra_t(p,q));
        }

    }
    return 0;
}
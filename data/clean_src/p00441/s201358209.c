#include <stdio.h>
#include <string.h>

#define TREE_MAX 3000

typedef struct {
	int x,y;
} xy_t;

int xy_comp(xy_t a,xy_t b) {
	if(a.x>b.x)return 1;
	if(a.x<b.x)return -1;
	if(a.y>b.y)return 1;
	if(a.y<b.y)return -1;
	return 0;
}

typedef struct {
	xy_t key;
	int isred;
	int parent;
	int left;
	int right;
} rbt_node_t;

int rbt_node_used;
rbt_node_t rbt_node[TREE_MAX+1];

void rbt_init(void) {
	rbt_node_used=1;
	memset(rbt_node,0,sizeof(rbt_node));
	rbt_node[0].key.x=-0x7fffffff;
	rbt_node[0].key.y=-0x7fffffff;
}

int rbt_search(int search_x,int search_y) {
	xy_t searchfor={search_x,search_y};
	int pos=rbt_node[0].right;
	while(pos>0) {
		if(xy_comp(rbt_node[pos].key,searchfor)==0) {
			return 1;
		} else if(xy_comp(rbt_node[pos].key,searchfor)<0) {
			pos=rbt_node[pos].right;
		} else {
			pos=rbt_node[pos].left;
		}
	}
	return 0;
}

int rbt_insert(int x,int y) {
	xy_t key={x,y};
	int pos=0;
	int parent,p_parent,p_left,p_right;
	int pp_parent,pp_left,pp_right;
	while(1) {
		if(xy_comp(rbt_node[pos].key,key)==0) {
			return 0;
		} else if(xy_comp(rbt_node[pos].key,key)<0) {
			if(rbt_node[pos].right==0)break;
			pos=rbt_node[pos].right;
		} else {
			if(rbt_node[pos].left==0)break;
			pos=rbt_node[pos].left;
		}
	}
	if(rbt_node_used>TREE_MAX)return 0;
	rbt_node[rbt_node_used].key.x=key.x;
	rbt_node[rbt_node_used].key.y=key.y;
	rbt_node[rbt_node_used].isred=1;
	rbt_node[rbt_node_used].parent=pos;
	rbt_node[rbt_node_used].left=0;
	rbt_node[rbt_node_used].right=0;
	if(xy_comp(rbt_node[pos].key,key)<0) {
		rbt_node[pos].right=rbt_node_used;
	} else {
		rbt_node[pos].left=rbt_node_used;
	}
	pos=rbt_node_used;
	rbt_node_used++;

	while(pos>0) {
		if(rbt_node[pos].parent==0) {
			rbt_node[pos].isred=0;
			break;
		}
		parent=rbt_node[pos].parent;
		p_parent=rbt_node[parent].parent;
		p_left=rbt_node[parent].left;
		p_right=rbt_node[parent].right;
		if(!rbt_node[parent].isred) {
			break;
		}
		pp_parent=rbt_node[p_parent].parent;
		pp_left=rbt_node[p_parent].left;
		pp_right=rbt_node[p_parent].right;
		if(rbt_node[pp_left].isred && rbt_node[pp_right].isred) {
			rbt_node[pp_left].isred=0;
			rbt_node[pp_right].isred=0;
			rbt_node[p_parent].isred=1;
			pos=p_parent;
		} else {
			if(pos==p_right && parent==pp_left) {
				rbt_node[parent].right=rbt_node[pos].left;
				rbt_node[parent].parent=pos;
				rbt_node[pos].left=parent;
				rbt_node[pos].parent=p_parent;
				rbt_node[p_parent].left=pos;
				pos=parent;
			} else if(pos==p_left && parent==pp_right) {
				rbt_node[parent].left=rbt_node[pos].right;
				rbt_node[parent].parent=pos;
				rbt_node[pos].right=parent;
				rbt_node[pos].parent=p_parent;
				rbt_node[p_parent].right=pos;
				pos=parent;
			} else if(pos==p_left && parent==pp_left) {
				if(rbt_node[pp_parent].left==p_parent) {
					rbt_node[pp_parent].left=parent;
				} else if(rbt_node[pp_parent].right==p_parent) {
					rbt_node[pp_parent].right=parent;
				} else {
					/* error! bug! */
					return 0;
				}
				rbt_node[p_parent].left=rbt_node[parent].right;
				rbt_node[p_parent].parent=parent;
				rbt_node[parent].right=p_parent;
				rbt_node[parent].parent=pp_parent;
				rbt_node[p_parent].isred=1;
				rbt_node[parent].isred=0;
				break;
			} else if(pos==p_right && parent==pp_right) {
				if(rbt_node[pp_parent].left==p_parent) {
					rbt_node[pp_parent].left=parent;
				} else if(rbt_node[pp_parent].right==p_parent) {
					rbt_node[pp_parent].right=parent;
				} else {
					/* error! bug! */
					return 0;
				}
				rbt_node[p_parent].right=rbt_node[parent].left;
				rbt_node[p_parent].parent=parent;
				rbt_node[parent].left=p_parent;
				rbt_node[parent].parent=pp_parent;
				rbt_node[p_parent].isred=1;
				rbt_node[parent].isred=0;
				break;
			} else {
				/* error! bug! */
				return 0;
			}
		}
	}
	rbt_node[0].parent=0;
	rbt_node[0].left=0;
	rbt_node[0].isred=0;
	return 1;
}

int main(void) {
	int n;
	xy_t input_xy[3000];
	int i,j;
	int sa_x,sa_y;
	int result;
	while(1) {
		scanf("%d",&n);
		if(n==0)break;
		rbt_init();
		for(i=0;i<n;i++) {
			scanf("%d%d",&input_xy[i].x,&input_xy[i].y);
			rbt_insert(input_xy[i].x,input_xy[i].y);
		}
		result=0;
		for(i=0;i<n;i++) {
			for(j=i+1;j<n;j++) {
				sa_x=input_xy[j].x-input_xy[i].x;
				sa_y=input_xy[j].y-input_xy[i].y;
				if(rbt_search(input_xy[i].x+sa_y,input_xy[i].y-sa_x) &&
					rbt_search(input_xy[j].x+sa_y,input_xy[j].y-sa_x)) {
						if(sa_x*sa_x+sa_y*sa_y>result) {
							result=sa_x*sa_x+sa_y*sa_y;
						}
				}
			}
		}
		printf("%d\n",result);
	}
	return 0;
}
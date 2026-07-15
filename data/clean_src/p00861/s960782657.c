#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define TREE_MAX 1000

typedef struct {
	int key;
	int data;
	int isred;
	int parent;
	int left;
	int right;
} rbt_node_t;

int rbt_node_used[52];
rbt_node_t rbt_node[52][TREE_MAX+1];

void rbt_init(void) {
	int i;
	memset(rbt_node,0,sizeof(rbt_node));
	for(i=0;i<52;i++) {
		rbt_node_used[i]=1;
		rbt_node[i][0].key=-0x7fffffff;
	}
}

int rbt_search(int id,int searchfor) {
	int pos=rbt_node[id][0].right;
	while(pos>0) {
		if(rbt_node[id][pos].key==searchfor) {
			return rbt_node[id][pos].data;
		} else if(rbt_node[id][pos].key<searchfor) {
			pos=rbt_node[id][pos].right;
		} else {
			pos=rbt_node[id][pos].left;
		}
	}
	return -1;
}

int rbt_insert(int id,int key,int data) {
	int pos=0;
	int parent,p_parent,p_left,p_right;
	int pp_parent,pp_left,pp_right;
	while(1) {
		if(rbt_node[id][pos].key==key) {
			rbt_node[id][pos].data=data;
			return 1;
		} else if(rbt_node[id][pos].key<key) {
			if(rbt_node[id][pos].right==0)break;
			pos=rbt_node[id][pos].right;
		} else {
			if(rbt_node[id][pos].left==0)break;
			pos=rbt_node[id][pos].left;
		}
	}
	if(rbt_node_used[id]>TREE_MAX)return 0;
	rbt_node[id][rbt_node_used[id]].key=key;
	rbt_node[id][rbt_node_used[id]].data=data;
	rbt_node[id][rbt_node_used[id]].isred=1;
	rbt_node[id][rbt_node_used[id]].parent=pos;
	rbt_node[id][rbt_node_used[id]].left=0;
	rbt_node[id][rbt_node_used[id]].right=0;
	if(rbt_node[id][pos].key<key) {
		rbt_node[id][pos].right=rbt_node_used[id];
	} else {
		rbt_node[id][pos].left=rbt_node_used[id];
	}
	pos=rbt_node_used[id];
	rbt_node_used[id]++;

	while(pos>0) {
		if(rbt_node[id][pos].parent==0) {
			rbt_node[id][pos].isred=0;
			break;
		}
		parent=rbt_node[id][pos].parent;
		p_parent=rbt_node[id][parent].parent;
		p_left=rbt_node[id][parent].left;
		p_right=rbt_node[id][parent].right;
		if(!rbt_node[id][parent].isred) {
			break;
		}
		pp_parent=rbt_node[id][p_parent].parent;
		pp_left=rbt_node[id][p_parent].left;
		pp_right=rbt_node[id][p_parent].right;
		if(rbt_node[id][pp_left].isred && rbt_node[id][pp_right].isred) {
			rbt_node[id][pp_left].isred=0;
			rbt_node[id][pp_right].isred=0;
			rbt_node[id][p_parent].isred=1;
			pos=p_parent;
		} else {
			if(pos==p_right && parent==pp_left) {
				rbt_node[id][parent].right=rbt_node[id][pos].left;
				rbt_node[id][parent].parent=pos;
				rbt_node[id][pos].left=parent;
				rbt_node[id][pos].parent=p_parent;
				rbt_node[id][p_parent].left=pos;
				pos=parent;
			} else if(pos==p_left && parent==pp_right) {
				rbt_node[id][parent].left=rbt_node[id][pos].right;
				rbt_node[id][parent].parent=pos;
				rbt_node[id][pos].right=parent;
				rbt_node[id][pos].parent=p_parent;
				rbt_node[id][p_parent].right=pos;
				pos=parent;
			} else if(pos==p_left && parent==pp_left) {
				if(rbt_node[id][pp_parent].left==p_parent) {
					rbt_node[id][pp_parent].left=parent;
				} else if(rbt_node[id][pp_parent].right==p_parent) {
					rbt_node[id][pp_parent].right=parent;
				} else {
					/* error! bug! */
					return 0;
				}
				rbt_node[id][p_parent].left=rbt_node[id][parent].right;
				rbt_node[id][p_parent].parent=parent;
				rbt_node[id][parent].right=p_parent;
				rbt_node[id][parent].parent=pp_parent;
				rbt_node[id][p_parent].isred=1;
				rbt_node[id][parent].isred=0;
				break;
			} else if(pos==p_right && parent==pp_right) {
				if(rbt_node[id][pp_parent].left==p_parent) {
					rbt_node[id][pp_parent].left=parent;
				} else if(rbt_node[id][pp_parent].right==p_parent) {
					rbt_node[id][pp_parent].right=parent;
				} else {
					/* error! bug! */
					return 0;
				}
				rbt_node[id][p_parent].right=rbt_node[id][parent].left;
				rbt_node[id][p_parent].parent=parent;
				rbt_node[id][parent].left=p_parent;
				rbt_node[id][parent].parent=pp_parent;
				rbt_node[id][p_parent].isred=1;
				rbt_node[id][parent].isred=0;
				break;
			} else {
				/* error! bug! */
				return 0;
			}
		}
	}
	rbt_node[id][0].parent=0;
	rbt_node[id][0].left=0;
	rbt_node[id][0].isred=0;
	return 1;
}

int array_max[52];

int get_arr_no(char c) {
	if(c>='a' && c<='z')return c-'a';
	else if(c>='A' && c<='Z')return c-'A'+26;
	return -1;
}

int get_array(char c,int index) {
	int arr_no;
	if(c>='a' && c<='z')arr_no=c-'a';
	else if(c>='A' && c<='Z')arr_no=c-'A'+26;
	else return -1;
	if(index>=array_max[arr_no] || index<0)return -1;
	return rbt_search(arr_no,index);
}

int getvalue_from_str(const char* input,int start,int end) {
	int result,i;
	int kakko_nest;
	if(isdigit(input[start])) {
		result=0;
		for(i=start;i<end;i++) {
			if(!isdigit(input[i]))return -1;
			result=result*10+(input[i]-'0');
		}
	} else {
		if(input[start+1]!='[')return -1;
		kakko_nest=1;
		for(i=start+2;i<end;i++) {
			if(input[i]=='[')kakko_nest++;
			if(input[i]==']')kakko_nest--;
			if(kakko_nest<=0)break;
		}
		if(kakko_nest>0)return -1;
		result=getvalue_from_str(input,start+2,i);
		result=get_array(input[start],result);
	}
	return result;
}

int main(void) {
	char input[100];
	char *cptr1,*cptr2;
	int line=1;
	int bug_line=0;
	int atai;
	int arr_no,arr_index;
	memset(array_max,0,sizeof(array_max));
	rbt_init();
	while(1) {
		scanf("%s",input);
		if(strcmp(input,".")==0) {
			if(line>1)printf("%d\n",bug_line);
			else break;
			line=1;
			bug_line=0;
			memset(array_max,0,sizeof(array_max));
			rbt_init();
			continue;
		}
		if(bug_line>0)continue;
		cptr1=strchr(input,'=');
		if(cptr1==NULL) {
			cptr1=strchr(input,'[');
			cptr2=strchr(input,']');
			if(cptr1==NULL || cptr2==NULL)return 1;
			*cptr2=0;
			array_max[get_arr_no(input[0])]=atoi(cptr1+1);
		} else {
			*cptr1=0;
			atai=getvalue_from_str(cptr1+1,0,strlen(cptr1+1));
			if(atai<0)bug_line=line;
			else {
				cptr1=strchr(input,'[');
				cptr2=strrchr(input,']');
				if(cptr1==NULL || cptr2==NULL)return 1;
				*cptr2=0;
				arr_no=get_arr_no(input[0]);
				arr_index=getvalue_from_str(cptr1+1,0,strlen(cptr1+1));
				if(arr_index>=array_max[arr_no] || arr_index<0)bug_line=line;
				else rbt_insert(arr_no,arr_index,atai);
			}
		}
		line++;
	}
	return 0;
}
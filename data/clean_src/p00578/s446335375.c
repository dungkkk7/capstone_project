#include <stdio.h>
#include "stdlib.h"

#define MAXN 100000

typedef uint bool;

typedef struct{
    uint height;//海拔
    uint index;//序号
    bool hasProbed;//记录其是否被检查过
}area,*areaptr;


typedef struct {
    areaptr *content;
    size_t len;
}max_heap;

static area input[MAXN];
static size_t N;

void new_max_heap(size_t len,area input[len],max_heap* out){
    out->content=(areaptr*)malloc(sizeof(areaptr)*len);
    out->len=len;

    for (uint i=0;i<len;i++) out->content[i]=input+i;

    for (uint i=len;i>=1;i--){

        //TODO 修正健堆
        for(uint cur=i;cur<=len;){
            uint cur_height=out->content[cur-1]->height;
            uint left_child=cur*2,right_child=left_child+1;

            if(right_child<=len){
                uint max_index=out->content[left_child-1]->height>out->content[right_child-1]->height?left_child:right_child;
                if(out->content[max_index-1]->height>=out->content[cur-1]->height){
                    areaptr temp=out->content[cur-1];
                    out->content[cur-1]=out->content[max_index-1];
                    out->content[max_index-1]=temp;
                    cur=max_index;
                }else{
                    break;
                }
            }else if (left_child<=len){
                //若左子节点海拔高
                if(out->content[left_child-1]->height>=out->content[cur-1]->height){
                    areaptr temp=out->content[cur-1];
                    out->content[cur-1]=out->content[left_child-1];
                    out->content[left_child-1]=temp;
                    cur=left_child;
                }else{
                    break;
                }
            }else
                break;
        }
    }
}

areaptr get_max(max_heap* self){
    return self->content[0];
}

areaptr extract_max(max_heap* self){
    areaptr ret=self->content[0];

    //交换首位
    self->content[0]=self->content[--self->len];

    uint cur=1;
    while(cur<self->len){
        uint left_child=cur*2,right_child=left_child+1;

        if(right_child<=self->len){
            uint max_index=self->content[left_child-1]->height>self->content[right_child-1]->height?left_child:right_child;
            if(self->content[max_index-1]->height>=self->content[cur-1]->height){
                areaptr temp=self->content[cur-1];
                self->content[cur-1]=self->content[max_index-1];
                self->content[max_index-1]=temp;
                cur=max_index;
            }else{
                break;
            }
        }else if (left_child<=self->len){
            //若左子节点海拔高
            if(self->content[left_child-1]->height>=self->content[cur-1]->height){
                   areaptr temp=self->content[cur-1];
                   self->content[cur-1]=self->content[left_child-1];
                   self->content[left_child-1]=temp;
                   cur=left_child;
            }else{
                break;
            }
        }else{
            break;//当前节点没有子节点时则结束
        }


    }

    return ret;
}

void show_heap(max_heap* self){
    for (int i=0;i<self->len;i++)
        printf("%d ",self->content[i]->height);
}

bool is_empty(max_heap* self){
    return self->len==0;
}

//TODO:处理全岛均在海平线之下的情况
int main() {
    max_heap heap;
    uint max_island_num=0,cur_island_num=max_island_num;

    //获得输入，并初始化堆
    scanf("%lu",&N);

    for(uint i=0;i<N;i++) {
        uint height;
        scanf("%u",&height);
        input[i].height=height;
        input[i].index=i;
        input[i].hasProbed=0;
    }

    if(N==1){
        if(input[0].height==0)
            puts("0");
        else
            puts("1");
        return 0;
    }

    //以下均建立在N不为1的基础上
    new_max_heap(N,input,&heap);

    //根据海拔从高到低扫描扫描各区域
    while(!is_empty(&heap)){
        //当前拓展的登高线高度
        uint current_height=get_max(&heap)->height;

        if (current_height==0)
            break;

        //对当前等高线进行扫描,以更新岛屿数
        while(!is_empty(&heap)&&current_height==get_max(&heap)->height){
            areaptr cur_area=extract_max(&heap);
            uint cur_index=cur_area->index;

            //printf("%d ",cur_index);

            //若当前区域在最左侧
            if(cur_index==0){
                if(!input[cur_index+1].hasProbed)
                    cur_island_num++;
            }else if(cur_index==N-1){
                if(!input[cur_index-1].hasProbed)
                    cur_island_num++;
            }else{
                if(input[cur_index+1].hasProbed==input[cur_index-1].hasProbed)
                    if(input[cur_index+1].hasProbed)//若两侧均检查过
                        cur_island_num--;
                    else
                        cur_island_num++;
            }

            cur_area->hasProbed=1;
        }

        max_island_num=max_island_num<cur_island_num?cur_island_num:max_island_num;

    }

    printf("%u\n",max_island_num);


    return 0;
}

#include <stdio.h>
#include <stdlib.h>

typedef struct _set{
    int *element;
    int eCnt;
    struct _set *next;
}SET;

SET* initSet(int n){
    int i;
    SET *p,*head;
    for(i=0;i<n;i++){
        if(i==0){
            head=(SET*)malloc(sizeof(SET));
            p=head;
        }else{
            p->next=(SET*)malloc(sizeof(SET));
            p=p->next;
        }
        p->element=(int*)malloc(sizeof(int));
        p->element[0]=i;
        p->eCnt=1;
    }
    p->next=NULL;
    
    return head;
}
void printSet(SET *head){
    int i;
    SET *p=head;
    printf("-----printSet-----\n");
    while(p!=NULL){
        for(i=0;i<p->eCnt;i++)printf("%d ",p->element[i]);
        printf("\n");
        p=p->next;
    }
    printf("------end------\n");
}
SET* getTarget(SET *head,int target){
    int i;
    SET *p=head;
    while(p!=NULL){
        for(i=0;i<p->eCnt;i++){
            if(p->element[i]==target)return p;
        }
        p=p->next;
    }
    return NULL;
}
SET* del(SET *head,SET *target){
    SET *p=head;
    
    if(head==target){
        head=head->next;
        free(p->element);
        free(p);
        return head;
    }
    
    while(p!=NULL&&p->next!=target)p=p->next;
    if(p==NULL)return head;
    
    p->next=target->next;
    
    free(target->element);
    free(target);
    
    return head;
}
SET* unite(SET *head,int x,int y){
    SET *xp,*yp;
    xp=getTarget(head,x);
    yp=getTarget(head,y);
    
    if(xp==NULL||yp==NULL||xp==yp)return head;

    xp->element=(int*)realloc(xp->element,sizeof(int)*(xp->eCnt+yp->eCnt));
    int i,j;
    for(i=xp->eCnt,j=0;j<yp->eCnt;i++,j++)xp->element[i]=yp->element[j];
    xp->eCnt+=yp->eCnt;
    
    return head=del(head,yp);
}
void same(SET *head,int x,int y){
    SET *xp,*yp;
    xp=getTarget(head,x);
    yp=getTarget(head,y);
    if(xp==yp)printf("1\n");
    else printf("0\n");
}
void delAll(SET *head){
    SET *p=head;
    while(p!=NULL){
        head=head->next;
        free(p->element);
        free(p);
        p=head;
    }
}
int main(void){
    int i;
    
    int n;
    scanf("%d ",&n);
    
    SET *head;
    head=initSet(n);

    int q;
    scanf("%d\n",&q);
    
    int com,x,y;
    for(i=0;i<q;i++){
        scanf("%d %d %d\n",&com,&x,&y);
        switch(com){
            case 0:
                head=unite(head,x,y);
                break;
            case 1:
                same(head,x,y);
                break;
        }
    }

    delAll(head);
    
    return 0;
}


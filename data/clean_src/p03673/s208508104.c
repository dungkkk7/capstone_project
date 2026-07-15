


/*
======================================================
C template generator
	URL : https://github.com/skentagon/c-template-generator.git
======================================================
*/
/*
======================================================
C template generator
	class name : 'list'
	type : 'long long'
	mnemonic : 'long_long'
======================================================
*/

#ifndef C_LIST_long_long_GENERATOR_HEADER_INCLUDED
#define C_LIST_long_long_GENERATOR_HEADER_INCLUDED

/*

list samples
  https://atcoder.jp/contests/abc066/submissions/11643502

*/

#include <stdlib.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdarg.h>

struct list_item_long_long_internal__ {
  long long value;
  struct list_item_long_long_internal__* prev;
  struct list_item_long_long_internal__* next;
};
typedef struct list_item_long_long_internal__ list_item_long_long;

typedef struct {
  list_item_long_long* front;
  list_item_long_long* back;
  size_t size;
} list_long_long;

typedef struct list_item_long_long_internal__* list_item_ptr_long_long;


/*
======================================================
C template generator
	class name : 'list'
	type : 'list_item_ptr_long_long'
	mnemonic : 'list_item_ptr_long_long'
======================================================
*/

#ifndef C_UTILITY_list_item_ptr_long_long_GENERATOR_HEADER_INCLUDED
#define C_UTILITY_list_item_ptr_long_long_GENERATOR_HEADER_INCLUDED

void swap_list_item_ptr_long_long( list_item_ptr_long_long* l, list_item_ptr_long_long* r ){ list_item_ptr_long_long t = *l; *l = *r; *r = t; }

#endif
/*
======================================================
C template generator
	class name : 'list'
	type : 'list_long_long'
	mnemonic : 'list_long_long'
======================================================
*/

#ifndef C_UTILITY_list_long_long_GENERATOR_HEADER_INCLUDED
#define C_UTILITY_list_long_long_GENERATOR_HEADER_INCLUDED

void swap_list_long_long( list_long_long* l, list_long_long* r ){ list_long_long t = *l; *l = *r; *r = t; }

#endif
/*
======================================================
C template generator
	class name : 'list'
	type : 'list_item_long_long'
	mnemonic : 'list_item_long_long'
======================================================
*/

#ifndef C_UTILITY_list_item_long_long_GENERATOR_HEADER_INCLUDED
#define C_UTILITY_list_item_long_long_GENERATOR_HEADER_INCLUDED

void swap_list_item_long_long( list_item_long_long* l, list_item_long_long* r ){ list_item_long_long t = *l; *l = *r; *r = t; }

#endif
void list_constructor_long_long( list_long_long* l ){ l->front = l->back = NULL; l->size = 0; };
void list_deconstructor_long_long( list_long_long* l );
bool list_empty_long_long( list_long_long* l ){ return l->front == NULL; };
size_t list_size_long_long( list_long_long* l ){ return l->size; };
//size_t list_max_size_long_long( list_long_long* l );
list_long_long* list_resize_long_long( list_long_long* l, size_t sz );
list_long_long* list_resize_default_long_long( list_long_long* l, size_t sz, long long* p );
list_item_long_long* list_front_long_long( list_long_long* l ){ return l->front; };
list_item_long_long* list_back_long_long( list_long_long* l ){ return l->back; };
list_item_long_long* list_push_front_long_long( list_long_long* l, long long* p );
list_item_long_long* list_push_back_long_long( list_long_long* l, long long* p );
list_item_long_long* list_push_front_empty_long_long( list_long_long* l );
list_item_long_long* list_push_back_empty_long_long( list_long_long* l );
list_item_long_long* list_insert_long_long( list_long_long* l, list_item_long_long* itm, long long* p );
list_item_long_long* list_insert_va_long_long( list_long_long* l, list_item_long_long* itm, int num, ... );
list_item_long_long* list_insert_multiple_long_long( list_long_long* l, list_item_long_long* itm, int num, long long* p );
list_item_long_long* list_pop_front_long_long( list_long_long* l );
list_item_long_long* list_pop_back_long_long( list_long_long* l );
list_item_long_long* list_erase_long_long( list_long_long* l, list_item_long_long* itm );
list_item_long_long* list_erase_range_long_long( list_long_long* l, list_item_long_long* bgn, list_item_long_long* end );
list_item_long_long* list_erase_if_long_long( list_long_long* l, bool(*f)(list_item_long_long*,list_item_long_long*) );
list_long_long* list_clear_long_long( list_long_long* l );
void list_swap_long_long( list_long_long* l, list_long_long* r ){ swap_list_long_long(l,r); }
void list_swap_item_long_long( list_item_long_long* l, list_item_long_long* r ){ swap_list_item_long_long(l,r); }
list_long_long* list_splice_long_long( list_long_long* l, list_item_long_long* pos, list_long_long* r );
list_long_long* list_splice_item_long_long( list_long_long* l, list_item_long_long* pos, list_long_long* r, list_item_long_long* itm );
//list_long_long* list_splice_range_long_long( list_long_long* l, list_item_long_long* pos, list_long_long* r, list_item_long_long* bgn, list_item_long_long* end );
size_t list_remove_long_long( list_long_long* l, list_item_long_long* itm ){ list_erase_long_long(l,itm); }
//size_t list_remove_if_long_long( list_long_long* l, bool(*f)(list_item_long_long*) );
//list_long_long* list_unique_long_long( list_long_long* l );
//list_long_long* list_unique_if_long_long( list_long_long* l, bool(*f)(list_item_long_long*,list_item_long_long*) );
//list_long_long* list_merge_long_long( list_long_long* l, list_long_long* r );
//list_long_long* list_merge_if_long_long( list_long_long* l, list_long_long* r, bool(*f)(list_int_item*,list_int_item*) );
//list_long_long* list_sort_long_long( list_long_long* l );
//list_long_long* list_sort_if_long_long( list_long_long* l, bool(*f)(list_item_long_long*,list_item_long_long*) );
//list_long_long* list_reverse_long_long( list_long_long* l );

void list_deconstructor_long_long( list_long_long* l ){ list_clear_long_long(l); }
list_long_long* list_resize_long_long( list_long_long* l, size_t sz ){
  while( list_size_long_long(l) > sz ){ list_erase_long_long(l,list_back_long_long(l)); }
  while( list_size_long_long(l) < sz ){ list_push_back_empty_long_long(l); }
  return l;
};
list_long_long* list_resize_default_long_long( list_long_long* l, size_t sz, long long* p ){
  while( list_size_long_long(l) > sz ){ list_erase_long_long(l,list_back_long_long(l)); }
  while( list_size_long_long(l) < sz ){ list_push_back_long_long(l,p); }
  return l;
};
list_item_long_long* list_push_front_long_long( list_long_long* l, long long* p ){
  list_item_long_long* t = list_push_front_empty_long_long(l);
  if (!t){ return NULL; }
  t->value = *p;
  return t;
};
list_item_long_long* list_push_back_long_long( list_long_long* l, long long* p ){
  list_item_long_long* t = list_push_back_empty_long_long(l);
  if (!t){ return NULL; }
  t->value = *p;
  return t;
};
list_item_long_long* list_push_front_empty_long_long( list_long_long* l ){
  list_item_long_long* t = (list_item_long_long*)malloc(sizeof(list_item_long_long));
  if (!t)return NULL;
  if (list_empty_long_long(l)){
    l->front = l->back = t;
    l->front->prev = l->front->prev = NULL;
  } else {
    l->front->prev = t;
    l->front->prev->next = l->front;
    l->front = l->front->prev;
    l->front->prev = NULL;
  }
  return t;
};
list_item_long_long* list_push_back_empty_long_long( list_long_long* l ){
  list_item_long_long* t = (list_item_long_long*)malloc(sizeof(list_item_long_long));
  if (!t)return NULL;
  if (list_empty_long_long(l)){
    l->front = l->back = t;
    l->front->prev = l->front->prev = NULL;
  } else {
    l->back->next = t;
    l->back->next->prev = l->back;
    l->back = l->back->next;
    l->back->next = NULL;
  }
  return t;
};
list_item_long_long* list_insert_long_long( list_long_long* l, list_item_long_long* itm, long long* p ){
  list_item_long_long* t = (list_item_long_long*)malloc(sizeof(list_item_long_long));
  if ( t == NULL )return NULL;
  if ( l->back == itm )l->back = t;
  t->next = itm->next;
  t->prev = itm;
  itm->next = t;
  if ( t->next != NULL )t->next->prev = t;
  return t;
};
list_item_long_long* list_insert_va_long_long( list_long_long* l, list_item_long_long* itm, int num, ... ){
  va_list args; va_start( args, num );
  list_item_long_long* itr = itm;
  for( int i=0; i<num; ++i ) itr = list_insert_long_long( l, itr, va_arg(args,long long*) );
  va_end(args);
  return itr;
};
list_item_long_long* list_insert_multiple_long_long( list_long_long* l, list_item_long_long* itm, int num, long long* p ){
  list_item_long_long* itr = itm;
  for( int i=0; i<num; ++i ) itr = list_insert_long_long( l, itr, p );
  return itr;
}
list_item_long_long* list_pop_front_long_long( list_long_long* l ){ list_erase_long_long(l,l->front); }
list_item_long_long* list_pop_back_long_long( list_long_long* l ){ list_erase_long_long(l,l->back); }
list_item_long_long* list_erase_long_long( list_long_long* l, list_item_long_long* itm ){
  list_item_long_long* t;
  if ( itm->prev ){
    if ( itm->next ){
      itm->prev->next = itm->next;
      t = itm->next;
    } else {
      itm->prev->next = NULL;
      l->back = itm->prev;
      t = itm->prev;
    }
  } else {
    if ( itm->next ){
      itm->next->prev = NULL;
      l->front = itm->next;
      t = itm->next;
    } else { l->front = l->back = t = NULL; }
  }
  free(itm); --l->size;
  return t;
};
list_item_long_long* list_erase_range_long_long( list_long_long* l, list_item_long_long* bgn, list_item_long_long* end ){
  list_item_long_long* t = bgn;
  end->prev = bgn->prev;
  if ( !bgn->prev ){ l->front = end; }
  while( t != end ){
    t = t->next;
    free(t->prev);
    --l->size;
  }
  return end;
};
list_long_long* list_clear_long_long( list_long_long* l ){
  list_item_long_long* t = l->front;
  if (!t)return l;
  while(t->next){t=t->next;free(t->prev);}
  free(l->back);
  l->front = l->back = NULL;
  l->size = 0;
  return l;
};
list_long_long* list_splice_long_long( list_long_long* l, list_item_long_long* pos, list_long_long* r ){
  if (r->size){
    l->size +=  r->size;
    r->front->prev = pos;
    r->back->next = pos->next;
    pos->next->prev = r->back;
    pos->next = r->front;
    r->front = r->back = NULL;
    r->size = 0;
  }
  return l;
};

#endif

// コード本体
#include <stdio.h>

int main(){

  // listの宣言
  list_long_long l;
  // listの初期化
  list_constructor_long_long(&l);

  int n;
  scanf("%d\n",&n);
  for( int i=0; i<n; ++i ){
    long long a;
    scanf("%lld",&a);
    if (i&0x01){
      list_push_back_long_long(&l,&a);
    } else {
      list_push_front_long_long(&l,&a);
    }
  }

  if (n&0x01){
    while(!list_empty_long_long(&l)){
      printf("%lld ",list_front_long_long(&l)->value);
      list_pop_front_long_long(&l);
    }
  }else{
    while(!list_empty_long_long(&l)){
      printf("%lld ",list_back_long_long(&l)->value);
      list_pop_back_long_long(&l);
    }
  }
  puts("");
  list_deconstructor_long_long(&l);
}
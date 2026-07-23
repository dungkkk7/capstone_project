#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
#define MAX_COMMAND_NUM 2000000
#define MAX_KEY_VALUE   2000000000
#define MAX_DEPTH       31				/* MAX Heap Tree Depth (2^30 < 2000000000 < 2^31) */
#define ARRAY_OFFSET    1

#define ROOT_POINT       0
#define RIGHT_POINT      1
#define LEFT_POINT       2
#define TOP_POINT        3

int NewInsertPoint;									/* Insert Point */

typedef struct ST_HEAP_TREE HeapTree_t;

typedef struct ST_HEAP_TREE
{
	HeapTree_t *top;		/* Heap Tree Top Pointer */
	HeapTree_t *left;		/* Heap Tree Left Pointer */
	HeapTree_t *right;		/* Heap Tree Right Pointer */
	int        value;		/* leaf value */
} HEAP_TREE;


static void SetTreePoint(HeapTree_t **pt_tree_point, int key, int direct);	/* Set Tree Point data */
static int  SearchInsertPoint(int * direct_point);							/* Search Way to Insert Point Data */
static void InsertPorocess(HeapTree_t **pt_tree_point,  int key);			/* Insert key Value process */
static void ExtractPorocess(HeapTree_t **pt_tree_point);					/* Extract Max key Value process */
static void UpHeapSort(HeapTree_t **pt_tree_point);							/* Insert Data Sort with up-heap */
static void DownHeapSort(HeapTree_t **pt_tree_point);						/* Insert Data Sort with down-heap */
static void ExchangeValue(HeapTree_t *pt_tree_point, int direct);			/* Exchange two value */

/***********************************************************************************
 ++module <main>
 ++outline
	main function
 ++arguments
	<>			<>					[]
 ++supp
 	<return>
 	  0		: success end
 ++end_module
************************************************************************************/
int main(void)
{
	int key;											/* insert key */
	char command[8];									/* command name */
	int loop = 0;
	
	HeapTree_t *pt_root_pointer = (HeapTree_t *)malloc(sizeof(HeapTree_t));		/* heap tree top pointer */
	HeapTree_t *pt_now_pointer;													/* haep tree calc pointer */
	NewInsertPoint = 1;															/* Root point */
	
	/* run all process or end commmand */
	while(((scanf("%s %d", command, &key)) != EOF) && (loop <= MAX_COMMAND_NUM))
	{
		/* set root pointer */
		pt_now_pointer = pt_root_pointer;
		
		if(strncmp(command, "end", 3) == 0) 			/* End Process */
		{
			break;
		}
		else if(strncmp(command, "insert", 6) == 0) 	/* Insert Process */
		{
			if(key <= MAX_KEY_VALUE)
			{
				InsertPorocess( &pt_now_pointer, key );		/* run Inseart porcess */
			}
			else
			{
				/* error key value */
			}
		}
		else if(strncmp(command, "extract", 7) == 0) 	/* Extract Process */
		{
			ExtractPorocess( &pt_now_pointer );			/* run Extract porcess */
		}
		else
		{
			/* error input */
		}
		loop++;
	}
	
    return 0;
}

/***********************************************************************************
 ++module <SetTreePoint>
 ++outline
	Set Tree Point data
 ++arguments
	<HeapTree_t>	<pt_tree_point>			[heap tree point]
	<int>			<key>					[set key value]
	<int>			<direct>				[Insert point direction]
 ++supp
 	<return>
 	  nothing
 ++end_module
************************************************************************************/
static void SetTreePoint(HeapTree_t **pt_tree_point, int key, int direct)
{
	HeapTree_t *pt_insert_data;			/* Insert Data */
	
	/* make new data */
	pt_insert_data = (HeapTree_t *)malloc(sizeof(HeapTree_t));
	pt_insert_data->value   = key;
	pt_insert_data->top	    = (*pt_tree_point);
	pt_insert_data->left    = NULL;
	pt_insert_data->right   = NULL;

	if(direct == RIGHT_POINT)							/* if right point new data */
	{
		(*pt_tree_point)->right = pt_insert_data;		/* set right point new data */
	}
	else if(direct == LEFT_POINT)						/* if left point new data */
	{
		(*pt_tree_point)->left = pt_insert_data;		/* set left point new data */
	}
	else												/* if now point new data */
	{
		(*pt_tree_point) = pt_insert_data;				/* set now point new data */
	}
}


/***********************************************************************************
 ++module <SearchInsertPoint>
 ++outline
	Search Way to Insert Point Data
 ++arguments
	<int>			<direct_point>			[Way to Insert Point]
 ++supp
 	<return>
 	  depth : depth value
 ++end_module
************************************************************************************/
static int SearchInsertPoint(int * direct_point)
{
	int search_depth = NewInsertPoint;				/* Search Point Number */
	int depth = 0;									/* Insert Point depth */
	
	while(search_depth > 1)							/* whle Not Root Point Num */
	{
		direct_point[depth] = search_depth % 2;		/* set left or right */
		search_depth = search_depth / 2;			/* top point from now */
		depth++;
	}
	
	return depth;
}


/***********************************************************************************
 ++module <InsertPorocess>
 ++outline
	Insert key data process
 ++arguments
	<HeapTree_t>	<pt_tree_point>			[heap tree point]
	<int>			<key>					[set key value]
 ++supp
 	<return>
 	  nothing
 ++end_module
************************************************************************************/
static void InsertPorocess(HeapTree_t **pt_tree_point,  int key)
{
	HeapTree_t * pt_insert_point = (*pt_tree_point);			/* Insert Point Data */
	int direct_point[MAX_DEPTH];								/* Way to Insert Point */
	int depth;													/* Insert Point depth */
	
	if(NewInsertPoint != 1)										/* if Insert Point is not Root */
	{
		depth = SearchInsertPoint(direct_point);				/* search insert point */
		while(depth > 1)										/* go to Insert Top Point */
		{
			depth--;
			if(direct_point[depth] == RIGHT_POINT)				/* if Right Point */
			{
				pt_insert_point = pt_insert_point->right;		/* go to right pointer */
			}
			else												/* if Left Point */	
			{
				pt_insert_point = pt_insert_point->left;		/* go to left pointer */
			}
		}
		
		if(direct_point[0] == RIGHT_POINT)						/* if Set point is Right Point */
		{
			SetTreePoint(&pt_insert_point, key, RIGHT_POINT);	/* Insert right pointer */
			pt_insert_point = pt_insert_point->right;			/* go to Insert Pointer */
		}
		else													/* if Set point is  Left Point */	
		{
			SetTreePoint(&pt_insert_point, key, LEFT_POINT);	/* Insert left pointer */
			pt_insert_point = pt_insert_point->left;			/* go to Insert Pointer */
		}
		
		UpHeapSort(&pt_insert_point);	/* sort up heap */
	}
	else
	{
		pt_insert_point->value = key;
		pt_insert_point->top   = NULL;
		pt_insert_point->left  = NULL;
		pt_insert_point->right = NULL;
	}
	NewInsertPoint++;						/* plus data point */
}


/***********************************************************************************
 ++module <ExtractPorocess>
 ++outline
	Extract Max key Value process
 ++arguments
	<HeapTree_t>	<pt_tree_point>			[heap tree point]
 ++supp
 	<return>
 	  nothing
 ++end_module
************************************************************************************/
static void ExtractPorocess(HeapTree_t **pt_tree_point)
{
	HeapTree_t * pt_swap_point = (*pt_tree_point);			/* Swap Point Data */
	int direct_point[MAX_DEPTH];							/* Way to Swap Point */
	int depth;												/* Swap Point depth */
	
	if(NewInsertPoint == 2)									/* data is root point only */
	{
		printf("%d\n", (*pt_tree_point)->value);			/* output data */
		NewInsertPoint--;									/* minus data point num */
	}
	else if(NewInsertPoint > 2)								/* data is not empty */
	{
		printf("%d\n", (*pt_tree_point)->value);			/* output data */
		NewInsertPoint--;									/* minus data point num */
		
		depth = SearchInsertPoint(direct_point);			/* search swap point */
		
		while(depth > 0)									/* go to swap Point */
		{
			depth--;
			if(direct_point[depth] == RIGHT_POINT)			/* if Right Point */
			{
				pt_swap_point = pt_swap_point->right;		/* go to right pointer */
			}
			else											/* if Left Point */	
			{
				pt_swap_point = pt_swap_point->left;		/* go to left pointer */
			}
		}

		(*pt_tree_point)->value = pt_swap_point->value;		/* set last input value to Root Point */
		pt_swap_point = pt_swap_point->top;					/* go to swap point top */
		
		if(direct_point[0] == RIGHT_POINT)					/* if swap point is Right Point */
		{
			free(pt_swap_point->right);						/* free swap point */
			pt_swap_point->right = NULL;					/* Set NULL Free Pointer */
		}
		else												/* if swap point is  Left Point */	
		{
			free(pt_swap_point->left);						/* free swap point */
			pt_swap_point->left = NULL;						/* Set NULL Free Pointer */
		}

		DownHeapSort(pt_tree_point);						/* down heap Root Point */
	}
	else
	{
		/* nothing */
	}

}

/***********************************************************************************
 ++module <UpHeapSort>
 ++outline
	Insert Data Sort with up-heap
 ++arguments
	<HeapTree_t>	<pt_tree_point>		[exchange top point]
 ++supp
 	<return>
 	  nothing
 ++end_module
************************************************************************************/
static void UpHeapSort(HeapTree_t **pt_tree_point)
{
	int top_point;												/* Temporary preservation top point  */
	HeapTree_t * pt_top_point;									/* top Point Data */
	
	while((*pt_tree_point)->top != NULL)						/* not Root point */
	{
		/* set top point */
		pt_top_point = (*pt_tree_point)->top;					/* set top point */ 
		
		/* compare swap point value */
		if((*pt_tree_point)->value > pt_top_point->value)		/* top point is little */
		{
			ExchangeValue((*pt_tree_point), TOP_POINT);			/* exchange value heap tree */
			(*pt_tree_point) = (*pt_tree_point)->top;			/* continue upheap */
		}
		else
		{
			break;												/* finish up heap */
		}
	}
}


/***********************************************************************************
 ++module <DownHeapSort>
 ++outline
	Data Sort with down-heap
 ++arguments
	<HeapTree_t>	<pt_tree_point>		[exchange top point]
 ++supp
 	<return>
 	  nothing
 ++end_module
************************************************************************************/
static void DownHeapSort(HeapTree_t **pt_tree_point)
{
	HeapTree_t *pt_swap_point = (*pt_tree_point);	/* Swap Pointer */
	HeapTree_t *pt_heap_left;						/* Left Pointer */
	HeapTree_t *pt_heap_right;						/* Right Pointer */
	
	while(pt_swap_point != NULL)								/* exchange data exist point */
	{
		pt_heap_left = pt_swap_point->left;						/* get left pointer */
		pt_heap_right = pt_swap_point->right;					/* get right pointer */
		
		if(pt_heap_left == NULL)								/* no leaf */
		{
			break;
		}
		else if(pt_heap_right == NULL)							/* right leaf is empty */
		{
			pt_heap_left = pt_swap_point->left;					/* get left pointer */
			if(pt_swap_point->value < pt_heap_left->value)		/* leaf is bigger than top */
			{
				ExchangeValue(pt_swap_point, LEFT_POINT);		/* exchange left leaf and top */
			}
			break;												/* finish down heap */
		}
		else
		{
			if(pt_heap_left->value > pt_heap_right->value)		/* left leaf is bigger than right leaf */
			{
				if(pt_heap_left->value > pt_swap_point->value)	/* left leaf is bigger than top */
				{
					ExchangeValue(pt_swap_point, LEFT_POINT);	/* exchange left leaf and top */
					pt_swap_point = pt_heap_left;				/* next left pointer */
				}
				else
				{
					break;										/* finish down heap */
				}
			}
			else												/* right leaf is bigger than left leaf */
			{
				if(pt_heap_right->value > pt_swap_point->value)	/* right leaf is bigger than top */
				{
					ExchangeValue(pt_swap_point, RIGHT_POINT);	/* exchange right leaf and top */
					pt_swap_point = pt_heap_right;				/* next right pointer */
				}
				else
				{
					break;										/* finish down heap */
				}
			}
		}
	}
}

/***********************************************************************************
 ++module <ExchangeValue>
 ++outline
	Exchange two value
 ++arguments
	<HeapTree_t>	<pt_tree_point>		[exchange point]
	<int>			<direct>			[swap point dirction]
 ++supp
 	<return>
 	  nothing
 ++end_module
************************************************************************************/
static void ExchangeValue(HeapTree_t *pt_tree_point, int direct)
{
	int swap;										/* Temporary preservation swap value  */
	HeapTree_t *pt_swap_point;						/* Swap Point Data */
	
	swap = pt_tree_point->value;					/* save swap data */
	
	if(direct == RIGHT_POINT)						/* if exchange right point */
	{
		pt_swap_point = pt_tree_point->right;		/* set right pointer */
	}
	else if(direct == LEFT_POINT)					/* if exchange left point */
	{
		pt_swap_point = pt_tree_point->left;		/* set left pointer */
	}
	else											/* if exchange top point */
	{
		pt_swap_point = pt_tree_point->top;			/* set top pointer */
	}
	
	pt_tree_point->value = pt_swap_point->value;	/* set exchange point value */
	pt_swap_point->value = swap;					/* set swap point value */
}


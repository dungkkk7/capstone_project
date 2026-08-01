/***************************************************************************************
 * There is a data which provides heights (in meter) of mountains.
 * The data is only for ten mountains.
 *
 * Write a program which prints heights of the top three mountains in descending order.
 ***************************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DATA_SIZE   (10)
#define SEARCH_CNT  (3)
#define TOP3        (3)

static int* allocateInputData(size_t size);
static int* findTop3OfHeight(size_t size, const int *data);
static void putsData(const int *data);
static int cmp( const void *p, const void *q );

int main(void)
{
    int *vec = NULL;
    int *top3 = NULL;

    vec = allocateInputData(DATA_SIZE);
    top3 = findTop3OfHeight(TOP3, vec);
    putsData(top3);

    free(vec);
    free(top3);

    return 0;
}

static int* allocateInputData(size_t size)
{
    int i = 0;
    int *arr = (int *) malloc(size * sizeof(int));

    if ( NULL != arr ) {
        for (i = 0; i < DATA_SIZE; i++) {
            scanf("%d", &arr[i]);
        }
    }

    return arr;
}

static int* findTop3OfHeight(size_t size, const int *data)
{
    int i = 0;
    int *t = NULL;
    int *arr = NULL;

    if ( NULL != data) {
        t = (int *) malloc( DATA_SIZE * sizeof(int));
        for ( i = 0; i < DATA_SIZE; i++ ) {
            t[i] = data[i];
        }
        qsort(t, DATA_SIZE, sizeof(int), cmp);
        arr = (int *) malloc( size * sizeof(int));
        if ( NULL != arr ) {
            for ( i = 0; i < SEARCH_CNT; i++ ) {
                memcpy(&arr[i], &t[i], sizeof(int));
            }
        }

        free(t);
    }

    return arr;
}

static void putsData(const int *data)
{
    int i = 0;

    for ( i = 0; i < TOP3; i++ ) {
        printf( "%d\n", data[i]);
    }
}

static int cmp( const void *p, const void *q )
{
    return *(int*)q - *(int*)p;
}
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>



/*以下便利なマクロを定義する。*/

#define rep(i, min, max) for(i=min; i<=max; i=i+1)



#define if_forall(i, min, max, prop)\
	bool if_forall_condition=1;\
\
	for(i=min; i<=max; i=i+1)\
	{\
		if(!(prop))\
		{\
			if_forall_condition=0;\
			break;\
		}\
	}\
\
	if(if_forall_condition==1)\



#define if_exists(i, min, max, prop)\
	bool if_exists_condition=0;\
\
	for(i=min; i<=max; i=i+1)\
	{\
		if(prop)\
		{\
			if_exists_condition=1;\
			break;\
		}\
	}\
\
	if(if_exists_condition==1)\











/*以下便利な関数を定義する。*/



void ini_int(int array[], int num)
{
	int i=0;

	for(i=0; i<=num; i=i+1)
	{
		array[i]=0;
	}

}



void ini_char(char array[], int num)
{
	int i=0;

	for(i=0; i<=num; i=i+1)
	{
		array[i]='\0';
	}

}



int powi(int base, unsigned int exponent)
{
	int answer=1;

	answer=(int)pow((double)base, (double)exponent);

	return answer;
}



void  swap_int(int* x, int* y)
{
    int  tmp;

    tmp = *x;
    *x = *y;
    *y = tmp;
}



void  swap_int_array(int x[], int y[], int min, int max)
{
	int i;

    for(i=min; i<=max; i=i+1)
	{
		swap_int(&x[i], &y[i]);
	}
}



void  swap_char(char* x, char* y)
{
    char  tmp;

    tmp = *x;
    *x = *y;
    *y = tmp;
}



void  swap_char_array(char x[], char y[], int min, int max)
{
	int i;

    for(i=min; i<=max; i=i+1)
	{
		swap_char(&x[i], &y[i]);
	}
}



void sort_asc_int(int array[], int min, int max)
{
	int i, j;
	int dumy;

	for(i=min; i<=max; i=i+1)
	{
		for(j=i+1; j<=max; j=j+1)
		{
			if(array[i]>array[j])
			{
				dumy=array[i];
				array[i]=array[j];
				array[j]=dumy;
			}
		}
	}
}



void sort_des_int(int array[], int min, int max)
{
	int i, j;
	int dumy;

	for(i=min; i<=max; i=i+1)
	{
		for(j=i+1; j<=max; j=j+1)
		{
			if(array[i]<array[j])
			{
				dumy=array[i];
				array[i]=array[j];
				array[j]=dumy;
			}
		}
	}
}



int max_int(int var1, int var2)
{
	int answer=var1;

	if(answer<var2)
	{
		answer=var2;
	}

	return answer;
}



int max_int_array(int array[], int min, int max)
{
	int i;
	int answer;

	answer=array[min];

	for(i=min+1; i<=max; i=i+1)
	{
		answer=max_int(answer, array[i]);
	}

	return answer;
}



int min_int(int var1, int var2)
{
	int answer=var1;

	if(answer>var2)
	{
		answer=var2;
	}

	return answer;
}



int min_int_array(int array[], int min, int max)
{
	int i;
	int answer;

	answer=array[min];

	for(i=min+1; i<=max; i=i+1)
	{
		answer=min_int(answer, array[i]);
	}

	return answer;
}



int sum_array(int array[], int min, int max)
{
	int i=min;
	int answer=0;

	for(i=min; i<=max; i=i+1)
	{
		answer=answer+array[i];
	}

	return answer;
}



bool containelement_int(int array[], int min, int max, int element)
{
	int i;
	bool answer=0;

	if_exists(i, min, max, array[i]==element)
	{
		answer=1;
	}

	return answer;
}



int count_differentelement_int(int array[], int min, int max)
{
	int i=min;
	int pickup[max];
	ini_int(pickup, max);
	int answer=0;

	for(i=min; i<=max; i=i+1)
	{
		if(containelement_int(pickup, 0, answer-1, array[i])==0)
		{
			pickup[answer]=array[i];
			answer=answer+1;
		}
	}

	return answer;
}



int count_equalelement_int(int array[], int min, int max, int element)
{
	int i;
	int answer=0;

	for(i=min; i<=max; i=i+1)
	{
		if(array[i]==element)
		{
			answer=answer+1;
		}
	}

	return answer;
}











int main()
{
	int x;
	scanf("%d", &x);
	if(x<1200)
	{
		printf("ABC\n");
	}
	else
	{
		printf("ARC\n");
	}
	return 0;
}

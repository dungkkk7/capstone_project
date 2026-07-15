const char* version[]=
{
	"+---------version--------------+",
	"+last update:2014/10/28/20:26  +",
	"+author:Shitonai Rindo         +",
	"+------------------------------+",
	"endl"
};
const char* help[]=
{
	"+--------help-------------------------+",
	"+summary:sale Result:exceed int limit +",
	"+required inputs (stdin):data count,  +",
	"+sales data                           +",
	"+supported comandline options:-h -v   +",
	"+-------------------------------------+",
	"endl"
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
void manage_helpAndVersionOutput(char arg_line[]);
void saleResult(int datac);
bool is_existID(int query,int database[]);

const int MAX_SALESMAN_MEMBER=4000;/*社員は最大4000人*/
const int SENTINEL=999999; /*番兵。無限の代用*/

int main(int argc, char* argv[])
{
	manage_helpAndVersionOutput(argv[argc-1]);
	
	int datac;
	while(scanf("%d",&datac),datac)
	{
		saleResult(datac);
	}
	
	return 0;
}

void saleResult(int datac)
{
	int salesmanID,salePrice,soldCount;
	int roop_resultdata;
	int IDs[MAX_SALESMAN_MEMBER+1],IDcount=0;
	double ID_result[MAX_SALESMAN_MEMBER+1]; /*IDの入力順IDs、IDごとの合計売上を格納する配列ID_result(桁あふれを考慮したdouble型)を用意。ID_resultの添字はIDとする*/
	
	int roop_init;
	for(roop_init=0;roop_init<=MAX_SALESMAN_MEMBER;roop_init++)/*配列の初期化*/
	{
		ID_result[roop_init]=0;
	}
	
	scanf("%d %d %d",&salesmanID,&salePrice,&soldCount);/*各行のデータ読み取り*/
	IDs[IDcount++]=salesmanID;
	IDs[IDcount]=SENTINEL; /*番兵。配列の終わりを示す*/
	ID_result[salesmanID]+=(double)salePrice*soldCount;
	
	for(roop_resultdata=1;roop_resultdata<datac;roop_resultdata++)
	{
		scanf("%d %d %d",&salesmanID,&salePrice,&soldCount);/*各行のデータ読み取り*/
		
		ID_result[salesmanID]+=(double)salePrice*soldCount;/*売上を足す*/
		if(!is_existID(salesmanID,IDs))/*既出のIDかどうか。違えば入力順の一番最後にIDを追加*/
		{
			IDs[IDcount++]=salesmanID;
			IDs[IDcount]=SENTINEL;
		}
	}
	
	int roop_output;
	bool NAflag=true;/*売り上げを満たす社員がいた場合にflagがfalseになる*/
	for(roop_output=0;IDs[roop_output]!=SENTINEL;roop_output++)
	{
		if(ID_result[IDs[roop_output]]>=1000000)
		{
			printf("%d\n",IDs[roop_output]);
			NAflag=false;
		}
	}
	if(NAflag)
	{
		printf("NA\n");
	}
}

bool is_existID(int query,int database[])/*簡単のため線形探索。遅ければここを二分探索にすることも考えられる*/
{
	int roop_search;
	for(roop_search=0;database[roop_search]!=SENTINEL;roop_search++)
	{
		if(query==database[roop_search])
		{
			return true;
		}
	}
	return false;
}




void manage_helpAndVersionOutput(char arg_line[])
{
	int line;
	if(strcmp(arg_line,"-h")==0)
	{
		for(line=0;strcmp(help[line],"endl");line++)
		{
			printf("%s\n",help[line]);
		}
		exit(0);
	}
	else if(strcmp(arg_line,"-v")==0)
	{
		for(line=0;strcmp(version[line],"endl");line++)
		{
			printf("%s\n",version[line]);
		}
		exit(0);
	}
}
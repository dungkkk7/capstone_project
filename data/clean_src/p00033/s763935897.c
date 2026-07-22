#include<stdio.h>
#include<math.h>
int Check(int*);
int main(){
	int Count,KAZU,Ball[10];
	int Bzone[10],Czone[10];
	int *Result;
	for(Count=0;Count<10;Count++){
		Bzone[Count]=20*(Count+1);
		Czone[Count]=20*(Count+1);
	}

	scanf("%d",&KAZU);
	Result= (int*)malloc(KAZU);
	for(Count=0;Count<KAZU;Count++){
		int Count2,Count3;
		int YorN=0;
		scanf("%d %d %d %d %d %d %d %d %d %d",&Ball[0],&Ball[1],&Ball[2],&Ball[3],&Ball[4],&Ball[5],&Ball[6],&Ball[7],&Ball[8],&Ball[9]);

		for(Count2=0;Count2<1024;Count2++){
			int B=0,C=0;
			int V;
			for(V=0;V<10;V++){
				Bzone[V]=20*(V+1);
				Czone[V]=20*(V+1);
			}
			for(Count3=0;Count3<10;Count3++){
				if(0!=(((int)pow(2.0,Count3))&Count2)){//真ならCにいれる
					Czone[C]=Ball[Count3];
					C++;
				}
				else {
					Bzone[B]=Ball[Count3];
					B++;
				}
			}
			//振り分け完了
			if(Check(Bzone)==1&&Check(Czone)==1){
				YorN=1;
				break;
			}
		}
		*(Result+Count)=YorN;
	}
	for(Count=0;Count<KAZU;Count++){
		if(*(Result+Count)==1){
			printf("YES\n");
		}
		else printf("NO\n");
	}

	for(Count=0;Count<10;Count++){
		Bzone[Count]=20*(Count+1);
		Czone[Count]=20*(Count+1);
	}

	return 0;
}


int Check(int *BALL){
	int Count,Check=1;
	for(Count=0;Count<9;Count++){
		if(BALL[Count]>=BALL[Count+1]){
			Check=0;
		}
	}
	return Check;
}
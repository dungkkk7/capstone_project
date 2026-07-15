#include <stdio.h>
#include <stdlib.h>
#include <math.h>

double eps=1e-9;
double inf=1e30;
int N;
int M;


typedef struct tag_Point{
	double X;
	double Y;
}Point;

Point Add(const Point v,const Point w){
	Point P;
	P.X=v.X+w.X;
	P.Y=v.Y+w.Y;
	return P;
}

Point Times(const double r,const Point v){
	Point P;
	P.X=r*v.X;
	P.Y=r*v.Y;
	return P;
}
Point setPoint(const double x,const double y){
	Point P;
	P.X=x;
	P.Y=y;
	return P;
}	
double Length(const Point v){
	double r=sqrt(v.X*v.X+v.Y*v.Y);
	return r;
}


void solve(){
	Point Dogs[N];
	double Velo[N];
	Point Fris[M];
	Point FVelo[M];
	
	int i;
	double d[4];
	
	for(i=0;i<N;i++){
		scanf("%lf %lf %lf\n",&d[0],&d[1],&d[2]);
		Dogs[i].X=d[0];
		Dogs[i].Y=d[1];
		Velo[i]=d[2];
	}
	for(i=0;i<M;i++){
		scanf("%lf %lf %lf %lf\n",&d[0],&d[1],&d[2],&d[3]);
		Fris[i].X=d[0];
		Fris[i].Y=d[1];
		FVelo[i].X=d[2];
		FVelo[i].Y=d[3];
	}

	int Catch[N];
	for(i=0;i<N;i++)Catch[i]=0;
	
	Point UMove[N];
	double Time[N];
	
	int j;
	
	for(i=0;i<M;i++){
		for(j=0;j<N;j++){
			double A=FVelo[i].X*FVelo[i].X+FVelo[i].Y*FVelo[i].Y-Velo[j]*Velo[j];
			double B=2*(Fris[i].X-Dogs[j].X)*FVelo[i].X+2*(Fris[i].Y-Dogs[j].Y)*FVelo[i].Y;
			double C=(Fris[i].X-Dogs[j].X)*(Fris[i].X-Dogs[j].X)+(Fris[i].Y-Dogs[j].Y)*(Fris[i].Y-Dogs[j].Y);
			double D=B*B-4*A*C;
			
			if(A<=eps&&A>=-eps){
				//A=0の場合、犬とフリスビーが等速
				//　C=0（犬の位置とフリスビー位置が同じ（このケースは無い筈）
				//　B<0の時のみ解をもつ（犬とフリスビーを結ぶ線分の垂直二等分線とフリスビー軌道が交わる
				if(C<=eps&&C>=-eps){
					Time[j]=0.0;
					UMove[j]=setPoint(0,0);
				}else{
					if(B>-eps){
						Time[j]=inf;
						UMove[j]=setPoint(0,0);
					}else{
						Time[j]=-C/B;
						Point Ptemp1=Fris[i];
						//Ptemp1=Ptemp1.Add(FVelo[i].Times(Time[j]));
						//Ptemp1=Ptemp1.Add(Dogs[j].Times(-1.0));
						Ptemp1=Add(Ptemp1,Times(Time[j],FVelo[i]));
						Ptemp1=Add(Ptemp1,Times(-1.0,Dogs[j]));
						if(Length(Ptemp1)!=0){
							//UMove[j]=Ptemp1.Times(Velo[j]/Ptemp1.Length);
							UMove[j]=Times(Velo[j]/Length(Ptemp1),Ptemp1);
						}else{	UMove[j]=setPoint(0,0);}
					}
				}
			}
			if(A<-eps){
				//A<0の時は必ず解があり、かつ0の両側にある
				//（A<0⇔犬の方が速い）
				//　フリスビーがアポロニウスの円に囲まれている
				Time[j]=(-B-sqrt(D))/(2.0*A);//正の解
				Point Ptemp=Fris[i];
				//Ptemp=Ptemp.Add(FVelo[i].Times(Time[j]));
				//Ptemp=Ptemp.Add(Dogs[j].Times(-1.0));
				Ptemp=Add(Ptemp,Times(Time[j],FVelo[i]));
				Ptemp=Add(Ptemp,Times(-1.0,Dogs[j]));
				if(Length(Ptemp)!=0){
					//UMove[j]=Ptemp.Times(Velo[j]/Ptemp.Length);
					UMove[j]=Times(Velo[j]/Length(Ptemp),Ptemp);
				}else{	UMove[j]=setPoint(0,0);}
			}
			if(A>eps){
				//A>0の時は解がある時とない時がある						//（A<0⇔犬の方が速い）
				//　犬がアポロニウスの円に囲まれている
				//　フリスビー軌跡がT>0でアポロニウスの円と交わる時のみキャッチ可
				//　　⇔D>=0 かつ　解が正　この時、小さいほうの解を取る
				//　(解は 正,正 または 負,負　しかない）
				if(D<-eps){
					Time[j]=inf;
					UMove[j]=setPoint(0,0);
				}else{
					//D+=eps;//RE避ける
					Time[j]=(-B-sqrt(D))/(2.0*A);//小さい方の符号を見ればよい
					if(Time[j]<-eps){
						Time[j]=inf;
						UMove[j]=setPoint(0,0);
					}else{
						Point Ptemp=Fris[i];
						//Ptemp=Ptemp.Add(FVelo[i].Times(Time[j]));
						//Ptemp=Ptemp.Add(Dogs[j].Times(-1.0));
						Ptemp=Add(Ptemp,Times(Time[j],FVelo[i]));
						Ptemp=Add(Ptemp,Times(-1.0,Dogs[j]));

						if(Length(Ptemp)!=0){
							//UMove[j]=Ptemp.Times(Velo[j]/Ptemp.Length);
							UMove[j]=Times(Velo[j]/Length(Ptemp),Ptemp);
						}else{	UMove[j]=setPoint(0,0);}
					}
				}
			}
		}
		
		double Tmin=inf;
		int idx=-1;
		for(j=0;j<N;j++){
			if(Tmin>Time[j]){
				Tmin=Time[j];
				idx=j;
			}
		}
		//if(idx==-1)idx=0;
		Catch[idx]++;
		for(j=0;j<N;j++){
			Dogs[j]=Add(Dogs[j],Times(Tmin,UMove[j]));
		}		
	}
	
	for(i=0;i<N;i++){
		printf(i==0?"%d":" %d",Catch[i]);
	}
	printf("\n");
	
	

}





int main(){
	while(1){
		scanf("%d %d\n",&N,&M);
		if(!N&&!M)break;
		solve();
	}
	return 0;
}
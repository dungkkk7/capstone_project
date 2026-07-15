#include <stdio.h>

int cross(int x1,int y1,int x2,int y2,
		int x3,int y3,int x4,int y4) {
	long long b12x,b12y,b34x,b34y;
	long long b24x,b24y;
	long long b13x,b13y,b14x,b14y,b32x,b32y;
	long long g1213,g1214,g3431,g3432;
	long long n1213,n1214,n3431,n3432;
	long long n2123,n2124,n4341,n4342;

	b12x=x2-x1;b12y=y2-y1;
	b34x=x4-x3;b34y=y4-y3;
	b13x=x3-x1;b13y=y3-y1;
	b14x=x4-x1;b14y=y4-y1;
	b32x=x2-x3;b32y=y2-y3;
	b24x=x4-x2;b24y=y4-y2;

	g1213=b12x*b13y-b13x*b12y;
	g1214=b12x*b14y-b14x*b12y;
	g3431=b34x*(-b13y)-(-b13x)*b34y;
	g3432=b34x*b32y-b32x*b34y;

	n1213=b12x*b13x+b12y*b13y;
	n1214=b12x*b14x+b12y*b14y;
	n3431=b34x*(-b13x)+b34y*(-b13y);
	n3432=b34x*b32x+b34y*b32y;
	n2123=(-b12x)*(-b32x)+(-b12y)*(-b32y);
	n2124=(-b12x)*b24x+(-b12y)*b24y;
	n4341=(-b34x)*(-b14x)+(-b34y)*(-b14y);
	n4342=(-b34x)*(-b24x)+(-b34y)*(-b24y);

	if(
		((g1213<0 && g1214>0) || (g1213>0 && g1214<0)) &&
		((g3431<0 && g3432>0) || (g3431>0 && g3432<0))
	) return 1;
	if(
		(g1213==0 && n1213>=0 && n2123>=0) ||
		(g1214==0 && n1214>=0 && n2124>=0) ||
		(g3431==0 && n3431>=0 && n4341>=0) ||
		(g3432==0 && n3432>=0 && n4342>=0)
	) return 1;

	return 0;
}

/*
a1x+b1y=c1
a2x+b2y=c2
*/
int solve_houteisiki(double* x,double* y,
		double a1,double b1,double c1,
		double a2,double b2,double c2) {
	double d;
	d=a1*b2-b1*a2;
	if(-1e-8<d && d<1e-8)return 0;
	*x=(b2*c1-b1*c2)/d;
	*y=(-a2*c1+a1*c2)/d;
	return 1;
}

int main(void) {
	int x[6],y[6];
	int no_triangle;
	double x1,y1,t1,x2,y2,t2,x3,y3,t3;
	double tx1,ty1,tx2,ty2,tx3,ty3;
	double s;
	while(1) {
		scanf("%d%d%d%d",&x[0],&y[0],&x[1],&y[1]);
		if((x[0]|y[0]|x[1]|y[1])==0)break;
		scanf("%d%d%d%d",&x[2],&y[2],&x[3],&y[3]);
		scanf("%d%d%d%d",&x[4],&y[4],&x[5],&y[5]);
		no_triangle=0;
		no_triangle=no_triangle ||
			!cross(x[0],y[0],x[1],y[1],x[2],y[2],x[3],y[3]);
		no_triangle=no_triangle ||
			!cross(x[2],y[2],x[3],y[3],x[4],y[4],x[5],y[5]);
		no_triangle=no_triangle ||
			!cross(x[4],y[4],x[5],y[5],x[0],y[0],x[1],y[1]);
		if(!no_triangle) {
			x1=y[1]-y[0];
			y1=-(x[1]-x[0]);
			t1=x[0]*(y[1]-y[0])-y[0]*(x[1]-x[0]);
			x2=y[3]-y[2];
			y2=-(x[3]-x[2]);
			t2=x[2]*(y[3]-y[2])-y[2]*(x[3]-x[2]);
			x3=y[5]-y[4];
			y3=-(x[5]-x[4]);
			t3=x[4]*(y[5]-y[4])-y[4]*(x[5]-x[4]);
			no_triangle=no_triangle ||
				!solve_houteisiki(&tx1,&ty1,
					x1,y1,t1,x2,y2,t2);
			no_triangle=no_triangle ||
				!solve_houteisiki(&tx2,&ty2,
					x2,y2,t2,x3,y3,t3);
			no_triangle=no_triangle ||
				!solve_houteisiki(&tx3,&ty3,
					x3,y3,t3,x1,y1,t1);
		}
		if(!no_triangle) {
			s=((tx2-tx1)*(ty3-ty1)-(tx3-tx1)*(ty2-ty1))/2;
			if(s<0)s=-s;
			if(s<1e-8)puts("kyo");
			else if(s<100000+1e-8)puts("syo-kichi");
			else if(s<1000000+1e-8)puts("kichi");
			else if(s<1900000+1e-8)puts("chu-kichi");
			else puts("dai-kichi");
		} else puts("kyo");
	}
	return 0;
}
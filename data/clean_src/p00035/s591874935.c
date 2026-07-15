#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#define DOWN 0
#define UP 1
#define RIGHT 2
#define LEFT 3
#define CENTER 4

int func(double a, double b, double xp, double yp);
double slant(double x1, double y1, double x2, double y2);
double intercept(double x1, double y1, double x2, double y2);
double length(double x1, double y1, double x2, double y2);
int IsInTriangle(double x1, double x2, double x3, double y1, double y2, double y3, double xp, double yp);

int main(void){
	double xa, xb, xc, xd, ya, yb, yc, yd;
	int f1, f2, f3, f4;

	while(scanf("%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf", &xa, &ya, &xb, &yb, &xc, &yc, &xd, &yd) != EOF){
		f1 = IsInTriangle(xa, ya, xb, yb, xd, yd, xc, yc);
		f2 = IsInTriangle(xa, ya, xb, yb, xc, yc, xd, yd);
		f3 = IsInTriangle(xa, ya, xc, yc, xd, yd, xb, yb);
		f4 = IsInTriangle(xb, yb, xc, yc, xd, yd, xa, ya);

		if(f1 == 1 || f2 == 1 || f3 == 1 || f4 == 1){
			printf("NO\n");
		}else{
			printf("YES\n");
		}
	}

	return 0;
}

int IsInTriangle(double x1, double y1, double x2,  double y2, double x3, double y3, double xp, double yp){
	double a1, b1, a2, b2, a3, b3;
	int dir[3];
	int x_flag;
	int x_big, x_small, x_dir;
	int right, left;

	x_flag = -1;
	right = 0;
	left = 0;

	if(x1 > x2 && x1 > x3){
		right = 1;
	}else if(x2 > x1 && x2 > x3){
		right = 2;
	}else if(x3 > x1 && x3 > x2){
		right = 3;
	}
	if(x1 < x2 && x1 < x3){
		left =  1;
	}else if(x2 < x1 && x2 < x3){
		left = 2;
	}else if(x3 < x1 && x3 < x2){
		left = 3;
	}

	if(x1 != x2)a1 = slant(x1, y1, x2, y2);
	if(x1 != x2)b1 = intercept(x1, y1, x2, y2);
	if(x2 != x3)a2 = slant(x2, y2, x3, y3);
	if(x2 != x3)b2 = intercept(x2, y2, x3, y3);
	if(x3 != x1)a3 = slant(x3, y3, x1, y1);
	if(x3 != x1)b3 = intercept(x3, y3, x1, y1);

	if(x1 == x2){
		x_flag = 0;
		if(x1 < x3) dir[0] = RIGHT;
		else dir[0] = LEFT;
	}else{
		dir[0] = func(a1, b1, xp, yp);
	}

	if(x2 == x3){
		x_flag = 1;
		if(x2 < x1) dir[1] = RIGHT;
		else dir[1] = LEFT;
	}else{
		dir[1] = func(a2, b2, xp, yp);
	}

	if(x3 == x1){
		x_flag = 2;
		if(x1 < x2) dir[2] = RIGHT;
		else dir[2] = LEFT;
	}else{
		dir[2] = func(a3, b3, xp, yp);
	}

	if(x1 == x2 || x2 == x3 || x3 == x1){
		if(x_flag == 0){
			if(y2 > y1) {			//1
				x_big = dir[1];
				x_small = dir[2];
			}else{
				x_big = dir[2];
				x_small = dir[1];
			}
			if(x1 == xp){
				x_dir = CENTER;
			} else if(x1 < xp){
				x_dir = RIGHT;
			}else{
				x_dir = LEFT;
			}
			if(dir[0] == x_dir && x_big == DOWN && x_small == UP){
				return 1;
			}else{
				return 0;
			}
		}else if(x_flag == 1){						//2
			if(y3 > y2) {
				x_big = dir[2];
				x_small = dir[0];
			}else{
				x_big = dir[0];
				x_small = dir[2];
			}
			if(x2 == xp){
				x_dir = CENTER;
			}else if(x2 < xp){
				x_dir = RIGHT;
			}else{
				x_dir = LEFT;
			}
			if(dir[1] == x_dir && x_big == DOWN && x_small == UP){
				return 1;
			}else{
				return 0;
			}
		}else if(x_flag == 2){						//3
			if(y1 > y3) {
				x_big = dir[0];
				x_small = dir[1];
			}else{
				x_big = dir[1];
				x_small = dir[0];
			}
			if(x3 == xp){
				x_dir = CENTER;
			}else if(x3 < xp){
				x_dir = RIGHT;
			}else{
				x_dir = LEFT;
			}
			if(dir[2] == x_dir && x_big == DOWN && x_small == UP){
				return 1;
			}else{
				return 0;
			}
		}
	}else if((right == 1 && left == 2) || (right == 2 && left == 1)){	//1
		if(func(a1, b1, x3, y3) == UP){
			if(dir[0] == UP && dir[1] == DOWN && dir[2] == DOWN){
				return 1;
			}else{
				return 0;
			}
		}else if(func(a1, b1, x3, y3) == DOWN){
			if(dir[0] == DOWN && dir[1] == UP && dir[2] == UP){
				return 1;
			}else{
				return 0;
			}
		}
	}else if(right == 2 && left == 3 || right == 3 && left == 2){	//2
		if(func(a2, b2, x1, y1) == UP){
			if(dir[0] == DOWN && dir[1] == UP && dir[2] == DOWN){
				return 1;
			}else{
				return 0;
			}
		}else if(func(a2, b2, x1, y1) == DOWN){
			if(dir[0] == UP && dir[1] == DOWN && dir[2] == UP){
				return 1;
			}else{
				return 0;
			}
		}
	}else if(right == 3 && left == 1 || right == 1 && left == 3){	//3
		if(func(a3, b3, x2, y2) == UP){
			if(dir[0] == DOWN && dir[1] == DOWN && dir[2] == UP){
				return 1;
			}else{
				return 0;
			}
		}else if(func(a3, b3, x2, y2) == DOWN){
			if(dir[0] == UP && dir[1] == UP && dir[2] == DOWN){
				return 1;
			}else{
				return 0;
			}
		}
	}


	return 0;
}

double slant(double x1, double y1, double x2, double y2){
	return (y1-y2)/(x1 - x2);
}

double intercept(double x1, double y1, double x2, double y2){
	return y1 - slant(x1, y1, x2, y2) * x1;
}

int func(double a, double b, double xp, double yp){
	double y;
	y = a * xp + b;
	if(yp == y){
		return CENTER;
	}else if(yp > y){
		return UP;
	}else{
		return DOWN;
	}
}

double length(double x1, double y1, double x2, double y2){
	return sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1));
}
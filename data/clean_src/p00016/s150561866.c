#include <stdio.h>
#include <math.h>

typedef struct _point {
	double x, y;
} point;

point walk(int r, int d) {
	int d2 = (d + 360*10000) % 360;
	point p;
	if(d2 == 0) {
		p.x = r;
		p.y = 0;
		return p;
	} else if(d2 == 90) {
		p.x = 0;
		p.y = r;
		return p;
	} else if(d2 == 180) {
		p.x = -r;
		p.y = 0;
		return p;
	} else if(d2 == 270) {
		p.x = 0;
		p.y = -r;
		return p;
	} else if(0 < d2 && d2 < 90) {
		p.x = r * fabs(cos(d2 * M_PI / 180));
		p.y = r * fabs(sin(d2 * M_PI / 180));
		return p;
	} else if(90 < d2 && d2 < 180) {
		p.x = -r * fabs(cos((180-d2) * M_PI / 180));
		p.y = r * fabs(sin((180-d2) * M_PI / 180));
		return p;
	} else if(180 < d2 && d2 < 270) {
		p.x = -r * fabs(cos((d2-180) * M_PI / 180));
		p.y = -r * fabs(sin((d2-180) * M_PI / 180));
		return p;
	} else {
		p.x = r * fabs(cos((360-d2) * M_PI / 180));
		p.y = -r * fabs(sin((360-d2) * M_PI / 180));
		return p;
	}
}

int main(void) {
	int angle = 90+36000;
	int r, d;
	char c;
	double x = 0.0;
	double y = 0.0;
	point p;
	
	while(scanf("%d%c%d\n", &r, &c, &d)==3) {
		if(r == 0 && d == 0) break;
		
//		angle -= d;
		p = walk(r, angle);
//		printf("%lf %lf %d %d %d\n", p.x, p.y, r, d, angle%360);
		x = x + p.x;
		y = y + p.y;
		angle -= d;
	}
	
	printf("%d\n%d\n", (int)x, (int)y);
	
	return 0;
}
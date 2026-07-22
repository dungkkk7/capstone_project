// AOJ 1213: Heavenly Jewels
// 2017.12.17 bal4u@uu

#include <stdio.h>
#include <string.h>
#include <math.h>

#define EPS 1e-8

typedef struct { double x, y; } PP;
typedef struct { PP s, e; } LINE;

PP p[3];
PP pol0[5] = {{0,0},{10000,0},{10000,10000},{0,10000},{0,0}};

int dcmp(double x)
{
	if (fabs(x) < EPS) return 0;
	return x < 0 ? -1 : 1;
}

double cross(double ax, double ay, double bx, double by) { return ax*by - ay*bx; }

void lineIntersection(PP *p, LINE *a, PP *vs, PP *ve)
{
    double a1, a2;

	a1 = cross(ve->x  - vs->x, ve->y  - vs->y,
			   a->s.x - vs->x, a->s.y - vs->y);
	a2 = cross(ve->x  - vs->x, ve->y  - vs->y,
			   a->e.x - vs->x, a->e.y - vs->y);
	p->x = (a->s.x*a2 - a->e.x*a1) / (a2-a1);
	p->y = (a->s.y*a2 - a->e.y*a1) / (a2-a1);
}

int convex_cut(LINE *u, int n, PP *p, PP *po)
{
	int i, d1, d2, top = 0;

    for (i = 0; i < n; i++) {
        d1 = dcmp(cross(u->e.x - u->s.x, u->e.y - u->s.y,
						p[i].x - u->s.x, p[i].y - u->s.y));
        d2 = dcmp(cross(u->e.x - u->s.x, u->e.y - u->s.y,
				      p[i+1].x - u->s.x, p[i+1].y - u->s.y));
        if (d1 >= 0) po[top++] = p[i];
        if (d1*d2 < 0) lineIntersection(po + top++, u, p+i, p+i+1);
    }
	po[top].x = po[0].x, po[top].y = po[0].y;
    return top;
}

// ?????´????????????
void bisector(LINE *u, PP a, PP b)
{
	double ax = (a.x + b.x)/2;
	double ay = (a.y + b.y)/2;
	u->s.x = ax, u->s.y = ay;
	if (fabs(a.y - b.y) <= EPS) u->e.x = ax, u->e.y = ay + (b.x-a.x)*4096;
	else u->e.x = ax-(b.y-a.y)*4096, u->e.y = (ax - u->e.x)*(b.x - a.x)/(b.y - a.y) + ay;
}

double polygonArea(int n, PP *p)
{
    double area = 0;
    for (int i = 1; i < n-1; i++) {
        area += cross(p[i].x-p[0].x, p[i].y-p[0].y, p[i+1].x-p[0].x, p[i+1].y-p[0].y);
    }
    return fabs(area) / 2;
}

int main()
{
	int cno = 0, k;
	PP pol[10], pol2[10];
	LINE u;

	while(scanf("%lf%lf%lf%lf%lf%lf", &p[0].x, &p[0].y, &p[1].x, &p[1].y, &p[2].x, &p[2].y) && p[0].x > 0) {
		memcpy(pol, pol0, sizeof(pol0));

		bisector(&u, p[0], p[1]);
		k = convex_cut(&u, 4, pol, pol2);

		bisector(&u, p[0], p[2]);
		k = convex_cut(&u, k, pol2, pol);

		printf("%d %.5lf\n", ++cno, polygonArea(k, pol) / ((double)10000*10000));
	}
	return 0;
}
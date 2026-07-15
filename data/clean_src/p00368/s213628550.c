// AOJ 0373: Checkered Pattern
// 2018.1.22 bal4u@uu

#include <stdio.h>

#define ABS(a)  ((a)>=0?(a):-(a))

int s[2][1001];
char buf[2005];

int in()
{
	int n = 0;
	int c = getchar();
	do n = (n<<3)+(n<<1) + (c & 0xf), c = getchar();
	while (c >= '0');
	return n;
}

int main()
{
	int w, h, a, x, y, x1, y1, ans;
	char *p;

	w = in(), h = in();
	ans = x1 = y1 = 0;
	for (y = 0; y < h; y++) {
		fgets(p=buf, 2005, stdin);
		a = *p & 1, y1 += a, s[a][0] += a;
		for (x = 1; x < w; x++) p += 2, s[a][x] += *p & 1;
	}

	for (x = 0; x < w; x++) {
		if (s[1][x] && (s[1][x] !=   y1 || s[0][x])) goto done;
		if (s[0][x] && (s[0][x] != h-y1 || s[1][x])) goto done;
		if (s[1][x]) x1++;
	}

	if (ABS(2*x1-w) > 1 || ABS(2*y1-h) > 1) goto done;
	a = x1*y1+(w-x1)*(h-y1);
	if (ABS(2*a-h*w) > 1) goto done;
	ans = 1;
done:
	puts(ans? "yes": "no");
	return 0;
}


// AOJ 2223: Kaeru Jump
// 2017.12.9

#include <stdio.h>
#include <string.h>

char m[12][12]; int h, w;
int tr['Z'];
char sd[4] = {'U','R','D','L'};
int mv[4][2] = {{-1,0},{0,1},{1,0},{0,-1}};
char ans[100];
char buf[10], *p;
int getint()
{
	int n = 0;
	while (*p >= '0') n = (n<<3) + (n<<1) + (*p++ & 0xf);
	p++;
	return n;
}

int rec(int r, int c, int dir, int leaf, char *p)
{
	int d, r2, c2;

	if (leaf == 1) { *p = 0; return 1; }
	dir += 2; if (dir >= 4) dir -= 4;
	for (d = 0; d < 4; d++) {
		if (d == dir) continue;
		r2 = r, c2 = c;
		while (1) {
			r2 += mv[d][0], c2 += mv[d][1];
			if (r2 < 0 || r2 >= h || c2 < 0 || c2 >= w) break;
			if (m[r2][c2] == 'o') {
				*p = sd[d];
				m[r][c] = '.';
				if (rec(r2, c2, d, leaf-1, p+1)) return 1;
				m[r][c] = 'o';
				break;
			}
		}
	}
	return 0;
}

int main()
{
	int r, c, sr, sc, leaf, d;

	tr['U'] = 0, tr['R'] = 1, tr['D'] = 2, tr['L'] = 3;
	fgets(p=buf, 10, stdin), h = getint(), w = getint();
	leaf = 0;
	for (r = 0; r < h; r++) {
		fgets(m[r], 12, stdin);
		for (c = 0; c < w; c++) {
			if      (m[r][c] == '.');
			else if (m[r][c] == 'o') leaf++;
			else {
				d = tr[m[r][c]];
				sr = r, sc = c;
				m[r][c] = 'o', leaf++;
			}
		}
	}
	rec(sr, sc, d, leaf, ans);
	puts(ans);
	return 0;
}
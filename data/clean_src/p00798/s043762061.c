// AOJ 1218: Push!!
// 2018.1.23 bal4u@uu

#include <stdio.h>
#include <string.h>

#define QMAX 5000
#define BASE 1000
typedef struct { char pr, pc, cr, cc; int k; } Q;
Q q[QMAX+2]; int top, end;

char map[8][8];
char mk[8][8][8][8];
int mv[4][2] = {{-1,0},{0,1},{1,0},{0,-1}};
 
int in()
{
	int n;
	int c = getchar();
	n = c & 0xf, getchar();
	return n;
}

int main()
{
	int w, h, i, r, c, d, cr, cc, gr, gc, ans;
	Q t;

	while (w = in()) {
		h = in();
		
		memset(mk, 0, sizeof(mk));
		top = BASE, end = top+1;
		for (r = 0; r < h; r++) for (c = 0; c < w; c++) {
			d = in();
			if      (d == 2) q[top].cr = r, q[top].cc = c;
			else if (d == 3) gr = r, gc = c;
			else if (d == 4) q[top].pr = r, q[top].pc = c;
			if (d != 1) d = 0;
			map[r][c] = d;
		}

		q[top].k = 0;
		ans = -1;
		while (top != end) {
			t = q[top++];

			if (t.cr == gr && t.cc == gc) { ans = t.k; break; }

			if (mk[t.pr][t.pc][t.cr][t.cc]) continue;
			mk[t.pr][t.pc][t.cr][t.cc] = 1;

			for (i = 0; i < 4; i++) {
				r = t.pr + mv[i][0], c = t.pc + mv[i][1];
				if (r == t.cr && c == t.cc) continue;
				if (r < 0 || r >= h || c < 0 || c >= w || map[r][c]) continue;
				q[--top] = t, q[top].pr = r, q[top].pc = c;
			}

		    for (i = 0 ; i < 4; i++) {
				r  = t.pr + mv[i][0];
				c  = t.pc + mv[i][1];
				cr = t.cr + mv[i][0];
				cc = t.cc + mv[i][1];
				if ((r == t.cr && c == t.cc) && (r >= 0 && r < h && c >= 0 && c < w && !map[r][c]) &&
					(cr >= 0 && cr < h && cc >= 0 && cc < w && !map[cr][cc])) {
					q[end].pr = r, q[end].pc = c, q[end].cr = cr, q[end].cc = cc, q[end++].k = t.k+1;
				}
			}
        }
		printf("%d\n", ans);
	}
	return 0;
}

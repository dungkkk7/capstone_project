// AOJ 1134: Name the Crossing
// 2017.11.13 bal4u@uu

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HASHSIZ 503
typedef struct { char *s; int id; } HASH;
HASH hash[HASHSIZ+2], *hashend = hash+HASHSIZ;			// Hash table

int insert(char *s, int w, int id)
{
	int i = (101 * *s + 103 * *(s+w-1) + 107 * w) % HASHSIZ;
	HASH *tp = hash + i;

	while (tp->s != NULL) {
		if (!strcmp(tp->s, s)) return tp->id;
		if (++tp == hashend) tp = hash;
	}
	tp->s = s, tp->id = id;
	return -1;
}

int lookup(char *s, int w)
{
	int i = (101 * *s + 103 * *(s+w-1) + 107 * w) % HASHSIZ;
	HASH *tp = hash + i;

	while (tp->s != NULL) {
		if (!strcmp(tp->s, s)) return tp->id;
		if (++tp == hashend) tp = hash;
	}
	return -1;
}

char name[202][36]; int sz;
char rel[202][202], tmp[202][202];
int cross[202];

void found(int j, int k)
{
	int i;

	cross[j] = k;
	for (i = 0; i < sz; i++) {
		if (!cross[i] && (rel[i][j] || rel[j][i])) found(i, -k);
	}
}

int main()
{
	int n, m, w, i, j, k;
	char buf[36], *p, *q;

	while (fgets(buf, 10, stdin) && *buf != '0') {
		memset(hash, 0, sizeof(hash));
		memset(rel, 0, sizeof(rel));

		n = atoi(buf), sz = 0;
		while (n--) {
			fgets(name[sz], 35, stdin);
			p = q = name[sz]; while (*p != '-') p++; w = p - q, *p++ = 0;
			if ((i = insert(q, w, sz)) < 0) i = sz++;
			q = p; while (*p > ' ') p++; w = p - q, *p = 0;
			if ((j = insert(q, w, sz)) < 0) j = sz++;
			rel[i][j] = 1;
		}
		printf("%d\n", sz);

		memset(cross, 0, sizeof(cross));
		for (k = 1, i = 0; i < sz; i++)	if (!cross[i]) found(i, k++);

		memset(tmp, 0, sizeof(tmp));
		for (i = 0; i < sz; i++) for (j = 0; j < sz; j++) if (j != i) {
			int comm = 0, strong = 1;
			for (k = 0; k < sz; k++) if (k != i && k != j) {
				if ((rel[i][k] || rel[k][i]) && (rel[j][k] || rel[k][j])) comm = 1;
				if ((rel[i][k] && rel[k][j]) || (rel[j][k] && rel[k][i])) strong = 0;
				if (comm && !strong) break;
			}
			if (comm && strong) tmp[i][j] = 1;
		}
		for (i = 0; i < sz; i++) for (j = 0; j < sz; j++) rel[i][j] |= tmp[i][j];

		for (k = 0; k < sz; k++) for (i = 0; i < sz; i++) for (j = 0; j < sz; j++)
			if (rel[i][k] && rel[k][j]) rel[i][j] = 1;

		fgets(buf, 10, stdin); m = atoi(buf);
		while (m--) {
			fgets(buf, 35, stdin);
			p = q = buf; while (*p != '-') p++;	w = p - q, *p++ = 0;
			if ((i = lookup(q, w)) < 0) goto no;
			q = p; while (*p > ' ') p++; w = p - q, *p = 0;
			if ((j = lookup(q, w)) < 0) goto no;
			if (cross[i] == -cross[j] && rel[i][j]) puts("YES");
			else {
no:				puts("NO");
			}
		}
	}
	return 0;

}
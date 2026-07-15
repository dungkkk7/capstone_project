#include <stdio.h>
#include <stdlib.h>

#define N	20000
#define N_	(N * 2)

int xx[N_], n;

int compare(const void *a, const void *b) {
	int i = *(int *) a;
	int j = *(int *) b;

	return xx[i] - xx[j];
}

int ii[N_], pp[N_], ll[N_], rr[N_];

int ds[N_], rr_[N_];

int find(int i) {
	return ds[i] < 0 ? i : (ds[i] = find(ds[i]));
}

void join(int i, int j) {
	i = find(i);
	j = find(j);
	if (i == j)
		return;
	if (ds[i] > ds[j]) {
		ds[i] = j;
	} else {
		if (ds[i] == ds[j])
			ds[i]--;
		ds[j] = i;
		rr_[i] = rr_[j];
	}
}

int cc[N_];

void update(int i, int c) {
	cc[i] = c;
	if (i > 0 && cc[i - 1])
		join(i - 1, i);
	if (i + 1 < n * 2 && cc[i + 1])
		join(i, i + 1);
}

int get(int i) {
	return i >= n * 2 || !cc[i] ? i : rr_[find(i)] + 1;
}

int qu[N_], cnt;

void dfs1(int i) {
	int l, j;

	update(pp[ii[i] ^ 1], -1);
	l = ll[i];
	while ((j = get(l)) <= rr[i])
		if (j == i)
			l = i + 1;
		else
			dfs1(pp[ii[j] ^ 1]);
	qu[--cnt] = i;
}

void dfs2(int i, int c) {
	int l, j;

	update(i, c);
	i = pp[ii[i] ^ 1], l = ll[i];
	while ((j = get(l)) <= rr[i])
		if (j == i)
			l = i + 1;
		else
			dfs2(j, c);
}

int solve(int d) {
	int h, i, l, r, c;

	for (i = 0, l = 0, r = 0; i < n * 2; i++) {
		while (l < i && xx[ii[i]] - xx[ii[l]] >= d)
			l++;
		while (r < n * 2 && xx[ii[r]] - xx[ii[i]] < d)
			r++;
		ll[i] = l, rr[i] = r - 1;
	}
	for (i = 0; i < n * 2; i++)
		ds[i] = -1, rr_[i] = i, cc[i] = 0;
	cnt = n * 2;
	for (i = 0; i < n * 2; i++)
		if (!cc[pp[ii[i] ^ 1]])
			dfs1(i);
	for (i = 0; i < n * 2; i++)
		ds[i] = -1, rr_[i] = i, cc[i] = 0;
	c = 0;
	for (h = 0; h < n * 2; h++) {
		i = qu[h];
		if (!cc[i])
			dfs2(i, ++c);
	}
	for (i = 0; i < n; i++)
		if (cc[pp[i << 1 | 0]] == cc[pp[i << 1 | 1]])
			return 0;
	return 1;
}

int main() {
	int i, lower, upper;

	scanf("%d", &n);
	for (i = 0; i < n * 2; i++)
		scanf("%d", &xx[i]);
	for (i = 0; i < n * 2; i++)
		ii[i] = i;
	qsort(ii, n * 2, sizeof *ii, compare);
	for (i = 0; i < n * 2; i++)
		pp[ii[i]] = i;
	lower = 0, upper = 1000000000;
	while (upper - lower > 1) {
		int d = (lower + upper) / 2;

		if (solve(d))
			lower = d;
		else
			upper = d;
	}
	printf("%d\n", lower);
	return 0;
}

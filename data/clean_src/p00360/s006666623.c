// AOJ 0365 Swapping Characters
// 2018.4.19 bal4u

#include <stdio.h>
#include <stdlib.h>

// BIT library
int bit[200005]; int n;

int sum(int i)
{
	int s = 0;
	while (i) {
		s += bit[i];
		i -= i & -i;
	}
	return s;
}

void add(int i)
{
	while (i <= n) {
		bit[i]++;
		i += i & -i;
	}
}

void sub(int i)
{
	while (i <= n) {
		bit[i]--;
		i += i & -i;
	}
}

char s[200005];
int  c['z'+1];

void calc(int ch)
{
	while (c[ch] < n && s[c[ch]] != ch) c[ch]++;
}

int main()
{
	int k, i, j, f;
	char b[15], *p;

	fgets(p=s, sizeof(s), stdin);
	while (*p > ' ') p++; n = p-s;
	fgets(b, 15, stdin), k = atoi(b);

	for (i = 1; i <= n; i++) add(i);
	for (i = 'a'; i <= 'z'; i++) calc(i);
	for (i = 0; i < n; i++) for(j = 'a'; j <= 'z'; j++) {
		if (c[j] == n) continue;
		if ((f = sum(c[j])) <= k) {
			k -= f;
			sub(c[j]+1);
			putchar(j);
			c[j]++;
			calc(j);
			break;
		}
	}
	putchar('\n');
	return 0;
}

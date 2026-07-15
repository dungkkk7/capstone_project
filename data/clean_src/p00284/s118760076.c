#include <stdio.h>

int motomeru(int s, int d) {
	int i;
	int answer = 0;
	while (s < d) {
		int limit = -1;
		int umetai = -1;
		for (i = 0; (1 << i) <= d; i++) {
			int delta = 1 << i;
			if ((s & delta) && limit < 0) limit = delta;
			if (!(s & delta) && (d & delta)) umetai = delta;
		}
		s += limit > 0 && limit < umetai ? limit : umetai;
		answer++;
	}
	return answer;
}

int main(void) {
	int N;
	int s[128], d[128];
	int i;
	if (scanf("%d", &N) != 1) return 1;
	for (i = 0; i < N; i++) {
		if (scanf("%d%d", &s[i], &d[i]) != 2) return 1;
	}
	for (i = 0; i < N; i++) {
		if (0 <= s[i]) printf("%d\n", motomeru(s[i], d[i]));
		else if (0 <= d[i]) printf("%d\n", motomeru(0, -s[i]) + motomeru(0, d[i]));
		else printf("%d\n", motomeru(-d[i], -s[i]));
	}
	return 0;
}


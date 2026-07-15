#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

int cmpItem(const char* a, const char* b) {
	int id1 = isdigit((unsigned char)*a), id2 = isdigit((unsigned char)*b);
	if (*a == '\0' && *b != '\0') return -1;
	if (*a != '\0' && *b == '\0') return 1;
	if (id1 && !id2) return -1;
	if (!id1 && id2) return 1;
	if (id1) {
		int aa = atoi(a), bb = atoi(b);
		return aa < bb ? -1 : aa > bb;
	} else {
		return (unsigned char)*a - (unsigned char)*b;
	}
}

char* getNextItem(char* out, char* in) {
	if (isdigit((unsigned char)*in)) {
		while (isdigit((unsigned char)*in)) {
			*(out++) = *(in++);
		}
		*out = '\0';
		return in;
	} else {
		out[0] = *in;
		out[1] = '\0';
		return in + 1;
	}
}

int main(void) {
	int n;
	int i;
	char s0[16];
	char s[16];
	if (scanf("%d", &n) != 1) return 1;
	if (scanf("%15s", s0) != 1) return 1;
	for (i = 0; i < n; i++) {
		char* s0ptr, *sptr;
		if (scanf("%15s", s) != 1) return 1;
		s0ptr = s0;
		sptr = s;
		for (;;) {
			char item1[16], item2[16];
			int cres;
			s0ptr = getNextItem(item1, s0ptr);
			sptr = getNextItem(item2, sptr);
			cres = cmpItem(item1, item2);
			if (cres != 0) {
				printf("%c\n", cres > 0 ? '-' : '+');
				break;
			} else if (*item1 == '\0' && *item2 == '\0') {
				puts("+");
				break;
			}
		}
	}
	return 0;
}


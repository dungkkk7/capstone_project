#include <stdio.h>
#include <string.h>

int main(void) {
    char s[241];
    if (!fgets(s, sizeof(s), stdin)) return 2;
    size_t n = strcspn(s, "\n");
    if (n == 0) { puts("0|-|0"); return 0; }
    unsigned runs = 1, longest = 1, current = 1;
    char leader = s[0];
    for (size_t i = 1; i < n; ++i) {
        if (s[i] == s[i - 1]) ++current;
        else { ++runs; current = 1; }
        if (current > longest) { longest = current; leader = s[i]; }
    }
    printf("%u|%c|%u\n", runs, leader, longest);
    return 0;
}

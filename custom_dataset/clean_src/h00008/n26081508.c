#include <ctype.h>
#include <stdio.h>

int main(void) {
    char line[321];
    if (!fgets(line, sizeof(line), stdin)) return 2;
    unsigned words = 0, alpha = 0, digits = 0, other = 0, longest = 0, run = 0;
    int inside = 0;
    for (size_t i = 0; line[i] && line[i] != '\n'; ++i) {
        unsigned char c = (unsigned char)line[i];
        if (isalnum(c)) {
            if (!inside) { inside = 1; ++words; run = 0; }
            ++run;
            if (run > longest) longest = run;
            if (isalpha(c)) ++alpha; else ++digits;
        } else { inside = 0; ++other; }
    }
    printf("%u %u %u %u %u\n", words, alpha, digits, other, longest);
    return 0;
}

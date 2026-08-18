#include <ctype.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    char line[513], words[32][24];
    int counts[32] = {0}, used = 0;
    if (!fgets(line, sizeof(line), stdin)) return 2;
    char token[24]; int length = 0;
    for (size_t i = 0;; ++i) {
        unsigned char ch = (unsigned char)line[i];
        if (isalnum(ch) && length < 23) token[length++] = (char)tolower(ch);
        if (!isalnum(ch) || ch == '\0') {
            if (length) {
                token[length] = '\0'; int at = -1;
                for (int j = 0; j < used; ++j) if (strcmp(words[j], token) == 0) at = j;
                if (at < 0 && used < 32) { at = used++; strcpy(words[at], token); }
                if (at >= 0) counts[at]++;
                length = 0;
            }
            if (ch == '\0') break;
        }
    }
    int best = 0, hash = 0;
    for (int i = 0; i < used; ++i) { if (counts[i] > counts[best]) best = i; hash = hash * 53 + counts[i] * (int)strlen(words[i]); }
    printf("unique=%d top=%s:%d hash=%d\n", used, used ? words[best] : "-", used ? counts[best] : 0, hash);
    return 0;
}

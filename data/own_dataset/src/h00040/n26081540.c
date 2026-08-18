#include <ctype.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    char line[256], keys[24][32], values[24][64];
    int count = 0, replaced = 0;
    while (fgets(line, sizeof(line), stdin)) {
        line[strcspn(line, "\r\n")] = '\0';
        if (strcmp(line, "end") == 0) break;
        char *equal = strchr(line, '=');
        if (!equal) continue;
        *equal++ = '\0';
        for (char *p = line; *p; ++p) *p = (char)tolower((unsigned char)*p);
        int at = -1;
        for (int i = 0; i < count; ++i) if (strcmp(keys[i], line) == 0) at = i;
        if (at < 0 && count < 24) { at = count++; snprintf(keys[at], sizeof(keys[at]), "%s", line); }
        else if (at >= 0) replaced++;
        if (at >= 0) snprintf(values[at], sizeof(values[at]), "%s", equal);
    }
    unsigned hash = 0x40u;
    for (int i = 0; i < count; ++i) for (size_t j = 0; keys[i][j]; ++j) hash = hash * 131u + (unsigned char)keys[i][j];
    for (int i = 0; i < count; ++i) for (size_t j = 0; values[i][j]; ++j) hash = hash * 137u + (unsigned char)values[i][j];
    printf("keys=%d replaced=%d hash=%08x\n", count, replaced, hash);
    return 0;
}

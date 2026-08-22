#include <stdint.h>
#include <stdio.h>

static int digit36(unsigned char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'Z') return c - 'A' + 10;
    if (c >= 'a' && c <= 'z') return c - 'a' + 10;
    return -1;
}

int main(void) {
    char line[257];
    if (!fgets(line, sizeof(line), stdin)) return 2;
    uint32_t hash = 2166136261u, accepted = 0, rejected = 0;
    for (size_t i = 0; line[i] && line[i] != '\n'; ++i) {
        int d = digit36((unsigned char)line[i]);
        if (d < 0) { ++rejected; continue; }
        hash = (hash ^ (uint32_t)(d + accepted * 7u)) * 16777619u;
        ++accepted;
    }
    printf("%08x %u %u\n", hash, accepted, rejected);
    return 0;
}

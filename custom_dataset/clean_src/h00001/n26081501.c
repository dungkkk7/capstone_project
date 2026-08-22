#include <stdint.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    char line[257];
    if (!fgets(line, sizeof(line), stdin)) return 2;
    uint32_t even = 0x13579bdu, odd = 0x2468aceu;
    size_t letters = 0;
    for (size_t i = 0; line[i] && line[i] != '\n'; ++i) {
        unsigned char c = (unsigned char)line[i];
        uint32_t v = (uint32_t)(c ^ (unsigned char)(17u + i * 13u));
        if ((i & 1u) == 0) even = (even << 5) ^ (even >> 2) ^ v;
        else odd = (odd << 3) ^ (odd >> 1) ^ (v * 33u);
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) ++letters;
    }
    printf("%08x:%08x:%zu\n", even, odd, letters);
    return 0;
}

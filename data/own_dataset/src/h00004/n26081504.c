#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint32_t rol(uint32_t x, unsigned n) { return (x << n) | (x >> (32u - n)); }

int main(void) {
    char op[16];
    uint32_t r = 0x31415926u;
    unsigned steps = 0, rejected = 0;
    while (scanf("%15s", op) == 1) {
        unsigned v = 0;
        if (strcmp(op, "end") == 0) break;
        if (scanf("%u", &v) != 1) return 3;
        if (strcmp(op, "mix") == 0) r = rol(r ^ v, 7);
        else if (strcmp(op, "add") == 0) r += v * 2654435761u;
        else if (strcmp(op, "mask") == 0) r = (r & v) ^ rol(v, 11);
        else { ++rejected; continue; }
        ++steps;
    }
    printf("%08x %u %u\n", r, steps, rejected);
    return 0;
}

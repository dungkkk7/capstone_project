#include <stdint.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    char op[16];
    uint32_t state = 0x4d3c2b1au;
    unsigned events = 0;
    while (scanf("%15s", op) == 1) {
        unsigned value = 0;
        if (strcmp(op, "stop") == 0) break;
        if (strcmp(op, "emit") == 0) {
            printf("%08x\n", state);
            events++;
            continue;
        }
        if (strcmp(op, "reset") == 0) {
            state = 0x4d3c2b1au ^ events;
            continue;
        }
        if (scanf("%u", &value) != 1) return 2;
        if (strcmp(op, "push") == 0) state = (state << 5) ^ (state >> 3) ^ value;
        else if (strcmp(op, "mul") == 0) state = state * (value | 1u) + 0x731u;
        else if (strcmp(op, "xor") == 0) state ^= value * 0x45d9f3bu;
        else return 3;
        events++;
    }
    printf("final:%08x:%u\n", state, events);
    return 0;
}

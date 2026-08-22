#include <stdint.h>
#include <stdio.h>

int main(void) {
    uint32_t state = 0xa5c31927u;
    int ch; unsigned count = 0;
    while ((ch = getchar()) != EOF && ch != '\n') {
        state ^= (unsigned char)ch;
        for (int bit = 0; bit < 8; ++bit)
            state = (state >> 1) ^ (0xed5b8832u & (0u - (state & 1u)));
        state = (state << 7) | (state >> 25);
        count++;
    }
    printf("%08x:%u\n", state ^ (count * 0x1021u), count);
    return 0;
}

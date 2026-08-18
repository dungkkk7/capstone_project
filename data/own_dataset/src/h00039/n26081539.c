#include <stdint.h>
#include <stdio.h>

int main(void) {
    int n;
    if (scanf("%d", &n) != 1 || n < 1 || n > 40) return 2;
    uint32_t stream = 0x3900cafeu;
    unsigned accepted = 0;
    for (int i = 0; i < n; ++i) {
        unsigned type, length, sequence, checksum;
        if (scanf("%u%u%u%u", &type, &length, &sequence, &checksum) != 4) return 3;
        uint32_t expected = (type * 17u + length * 31u + sequence * 13u + 0x39u) & 255u;
        if ((checksum & 255u) == expected) { accepted++; stream = (stream << 3) ^ (stream >> 2) ^ expected ^ sequence; }
        else stream += checksum ^ 0xbad00u;
    }
    printf("ok=%u bad=%u stream=%08x\n", accepted, (unsigned)n - accepted, stream);
    return 0;
}

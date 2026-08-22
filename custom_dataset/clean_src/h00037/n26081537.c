#include <stdio.h>
#include <string.h>

int main(void) {
    static const char alphabet[] = "346789ABCDEFGHJKLMNPQRTUVWXY";
    unsigned char input[128];
    if (!fgets((char *)input, sizeof(input), stdin)) return 2;
    size_t n = strcspn((char *)input, "\r\n"), bit_count = 0;
    unsigned buffer = 0, checksum = 0;
    for (size_t i = 0; i < n; ++i) {
        buffer = (buffer << 8) | input[i]; bit_count += 8; checksum = checksum * 29u + input[i];
        while (bit_count >= 5) { bit_count -= 5; putchar(alphabet[(buffer >> bit_count) & 31u]); }
    }
    if (bit_count) putchar(alphabet[(buffer << (5 - bit_count)) & 31u]);
    printf("-%03u\n", checksum % 997u);
    return 0;
}

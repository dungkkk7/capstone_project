#include <stdio.h>
#include <string.h>

int main(void) {
    char text[241];
    if (!fgets(text, sizeof(text), stdin)) return 2;
    text[strcspn(text, "\r\n")] = '\0';
    unsigned checksum = 17;
    for (size_t i = 0; text[i] != '\0';) {
        size_t j = i + 1;
        while (text[j] == text[i] && j - i < 99) j++;
        unsigned char ch = (unsigned char)text[i];
        printf("%02x%02zu", ch, j - i);
        checksum = (checksum * 257u) ^ (ch + (unsigned)(j - i) * 19u);
        i = j;
    }
    printf("|%08x\n", checksum);
    return 0;
}

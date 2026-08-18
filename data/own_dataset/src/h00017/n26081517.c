#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    int64_t queue[16], checksum = 0;
    int head = 0, size = 0, dropped = 0;
    char op[16];
    while (scanf("%15s", op) == 1 && strcmp(op, "end") != 0) {
        if (strcmp(op, "push") == 0) {
            int64_t x;
            if (scanf("%" SCNd64, &x) != 1) return 3;
            if (size == 16) { ++dropped; continue; }
            queue[(head + size) % 16] = x; ++size;
        } else if (strcmp(op, "pop") == 0) {
            if (!size) { ++dropped; continue; }
            checksum = checksum * 31 + queue[head]; head = (head + 1) % 16; --size;
        } else return 4;
    }
    while (size) { checksum = checksum * 31 + queue[head]; head = (head + 1) % 16; --size; }
    printf("%" PRId64 " %d\n", checksum, dropped);
    return 0;
}

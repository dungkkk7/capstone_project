#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    uint64_t seed, mul, count;
    if (scanf("%" SCNu64 "%" SCNu64 "%" SCNu64, &seed, &mul, &count) != 3 || count > 1000000) return 2;
    uint64_t x = seed % 1000003u, sum = 0, high = 0;
    for (uint64_t i = 0; i < count; ++i) {
        x = (x * (mul | 1u) + 97u + i * i) % 1000003u;
        sum = (sum + x * (i + 11u)) % 1000000007u;
        if (x > high) high = x;
    }
    printf("%" PRIu64 " %" PRIu64 " %" PRIu64 "\n", x, sum, high);
    return 0;
}

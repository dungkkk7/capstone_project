#include <stdio.h>

int main(void) {
    char line[257];
    if (!fgets(line, sizeof(line), stdin)) return 2;
    int round = 0, square = 0, depth = 0, peak = 0, faults = 0;
    for (size_t i = 0; line[i] && line[i] != '\n'; ++i) {
        if (line[i] == '(') { ++round; ++depth; }
        else if (line[i] == '[') { ++square; ++depth; }
        else if (line[i] == ')') { if (round) { --round; --depth; } else ++faults; }
        else if (line[i] == ']') { if (square) { --square; --depth; } else ++faults; }
        if (depth > peak) peak = depth;
    }
    faults += round + square;
    printf("%d %d %d\n", peak, faults, depth);
    return 0;
}

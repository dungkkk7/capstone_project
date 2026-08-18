#include <stdio.h>
#include <string.h>

int main(void) {
    int capacity, keys[16], ages[16], count = 0, clock = 0, hits = 0, misses = 0;
    if (scanf("%d", &capacity) != 1 || capacity < 1 || capacity > 16) return 2;
    char op[8];
    while (scanf("%7s", op) == 1 && strcmp(op, "end") != 0) {
        int key;
        if (scanf("%d", &key) != 1) return 3;
        int found = -1;
        for (int i = 0; i < count; ++i) if (keys[i] == key) found = i;
        if (strcmp(op, "get") == 0) { if (found >= 0) hits++; else misses++; }
        if (found >= 0) ages[found] = ++clock;
        else if (strcmp(op, "put") == 0) {
            int slot = count;
            if (count < capacity) count++;
            else { slot = 0; for (int i = 1; i < count; ++i) if (ages[i] < ages[slot]) slot = i; }
            keys[slot] = key; ages[slot] = ++clock;
        }
    }
    int hash = 0;
    for (int i = 0; i < count; ++i) hash ^= keys[i] * 97 + ages[i] * 13;
    printf("%d/%d size=%d hash=%d\n", hits, misses, count, hash);
    return 0;
}

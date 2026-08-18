#include <stdio.h>
#include <string.h>

int main(void) {
    int heap[128], size = 0, popped = 0, signature = 0;
    char op[8];
    while (scanf("%7s", op) == 1 && strcmp(op, "end") != 0) {
        if (strcmp(op, "add") == 0) {
            int value;
            if (scanf("%d", &value) != 1 || size == 128) return 2;
            int i = size++; heap[i] = value;
            while (i > 0) { int p = (i - 1) / 2; if (heap[p] <= heap[i]) break; int t = heap[p]; heap[p] = heap[i]; heap[i] = t; i = p; }
        } else if (strcmp(op, "pop") == 0) {
            if (size == 0) { signature ^= 0x733; continue; }
            int value = heap[0]; heap[0] = heap[--size];
            for (int i = 0;;) { int l = i * 2 + 1, r = l + 1, s = i; if (l < size && heap[l] < heap[s]) s = l; if (r < size && heap[r] < heap[s]) s = r; if (s == i) break; int t = heap[s]; heap[s] = heap[i]; heap[i] = t; i = s; }
            signature = signature * 43 + value; popped++;
        } else return 3;
    }
    printf("popped=%d left=%d sig=%d\n", popped, size, signature);
    return 0;
}

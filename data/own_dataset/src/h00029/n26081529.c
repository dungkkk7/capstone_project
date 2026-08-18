#include <stdio.h>
#include <string.h>

static int root(int parent[], int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

int main(void) {
    int n, parent[32], size[32], answers = 0, yes = 0;
    if (scanf("%d", &n) != 1 || n < 1 || n > 32) return 2;
    for (int i = 0; i < n; ++i) { parent[i] = i; size[i] = 1; }
    char op[8];
    while (scanf("%7s", op) == 1 && strcmp(op, "end") != 0) {
        int a, b;
        if (scanf("%d%d", &a, &b) != 2 || a < 0 || b < 0 || a >= n || b >= n) return 3;
        int ra = root(parent, a), rb = root(parent, b);
        if (strcmp(op, "join") == 0 && ra != rb) {
            if (size[ra] < size[rb]) { int t = ra; ra = rb; rb = t; }
            parent[rb] = ra; size[ra] += size[rb];
        } else if (strcmp(op, "ask") == 0) { answers++; yes += ra == rb; }
    }
    int groups = 0, signature = 0;
    for (int i = 0; i < n; ++i) if (root(parent, i) == i) { groups++; signature = signature * 41 + size[i]; }
    printf("answers=%d/%d groups=%d sig=%d\n", yes, answers, groups, signature);
    return 0;
}

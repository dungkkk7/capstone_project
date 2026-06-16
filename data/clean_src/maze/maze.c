#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INF 1000000000
#define MAX_TREASURES 8

typedef struct Point {
    int r;
    int c;
} Point;

typedef struct HeapNode {
    int id;
    int dist;
} HeapNode;

typedef struct MinHeap {
    HeapNode *a;
    int size;
    int cap;
} MinHeap;

int N;
char **grid;

int dr[4] = {-1, 1, 0, 0};
int dc[4] = {0, 0, -1, 1};

int inside(int r, int c) {
    return r >= 0 && r < N && c >= 0 && c < N;
}

int idOf(int r, int c) {
    return r * N + c;
}

Point pointOf(int id) {
    Point p;
    p.r = id / N;
    p.c = id % N;
    return p;
}

int terrainCost(char ch) {
    if (ch == '#') return INF;
    if (ch == '^') return 5;
    if (ch == '~') return 3;
    return 1;
}

MinHeap *createHeap(int cap) {
    MinHeap *h = (MinHeap *)malloc(sizeof(MinHeap));
    h->a = (HeapNode *)malloc(sizeof(HeapNode) * (cap + 5));
    h->size = 0;
    h->cap = cap;
    return h;
}

void swapNode(HeapNode *x, HeapNode *y) {
    HeapNode t = *x;
    *x = *y;
    *y = t;
}

void pushHeap(MinHeap *h, int id, int dist) {
    if (h->size + 2 >= h->cap) {
        h->cap *= 2;
        h->a = (HeapNode *)realloc(h->a, sizeof(HeapNode) * (h->cap + 5));
    }

    h->size++;
    int i = h->size;

    h->a[i].id = id;
    h->a[i].dist = dist;

    while (i > 1) {
        int p = i / 2;

        if (h->a[p].dist < h->a[i].dist) break;

        if (h->a[p].dist == h->a[i].dist && h->a[p].id < h->a[i].id) {
            break;
        }

        swapNode(&h->a[p], &h->a[i]);
        i = p;
    }
}

HeapNode popHeap(MinHeap *h) {
    HeapNode res = h->a[1];

    h->a[1] = h->a[h->size];
    h->size--;

    int i = 1;

    while (1) {
        int l = i * 2;
        int r = i * 2 + 1;
        int best = i;

        if (l <= h->size) {
            if (
                h->a[l].dist < h->a[best].dist ||
                (h->a[l].dist == h->a[best].dist && h->a[l].id < h->a[best].id)
            ) {
                best = l;
            }
        }

        if (r <= h->size) {
            if (
                h->a[r].dist < h->a[best].dist ||
                (h->a[r].dist == h->a[best].dist && h->a[r].id < h->a[best].id)
            ) {
                best = r;
            }
        }

        if (best == i) break;

        swapNode(&h->a[i], &h->a[best]);
        i = best;
    }

    return res;
}

int emptyHeap(MinHeap *h) {
    return h->size == 0;
}

void freeHeap(MinHeap *h) {
    free(h->a);
    free(h);
}

void allocateGrid() {
    grid = (char **)malloc(sizeof(char *) * N);

    for (int r = 0; r < N; r++) {
        grid[r] = (char *)malloc(sizeof(char) * (N + 1));
        grid[r][N] = '\0';
    }
}

void freeGrid() {
    for (int r = 0; r < N; r++) {
        free(grid[r]);
    }

    free(grid);
}

void carveRow(int r, int c1, int c2) {
    if (c1 > c2) {
        int t = c1;
        c1 = c2;
        c2 = t;
    }

    for (int c = c1; c <= c2; c++) {
        grid[r][c] = '.';
    }
}

void carveCol(int c, int r1, int r2) {
    if (r1 > r2) {
        int t = r1;
        r1 = r2;
        r2 = t;
    }

    for (int r = r1; r <= r2; r++) {
        grid[r][c] = '.';
    }
}

int samePoint(Point a, Point b) {
    return a.r == b.r && a.c == b.c;
}

int usedPoint(Point *arr, int count, Point p) {
    for (int i = 0; i < count; i++) {
        if (samePoint(arr[i], p)) return 1;
    }

    return 0;
}

void generateDungeon(
    Point *start,
    Point *exitPoint,
    Point *treasures,
    int *treasureCount
) {
    start->r = 0;
    start->c = 0;

    exitPoint->r = N - 1;
    exitPoint->c = N - 1;

    for (int r = 0; r < N; r++) {
        for (int c = 0; c < N; c++) {
            int v = (r * 37 + c * 19 + N * 11 + r * c * 7) % 17;

            if (v < 3) {
                grid[r][c] = '#';
            } else if (v < 5) {
                grid[r][c] = '^';
            } else if (v < 7) {
                grid[r][c] = '~';
            } else {
                grid[r][c] = '.';
            }
        }
    }

    carveRow(0, 0, N - 1);
    carveCol(N - 1, 0, N - 1);

    int k = N / 3;

    if (k < 1) k = 1;
    if (k > MAX_TREASURES) k = MAX_TREASURES;

    *treasureCount = 0;

    for (int i = 0; i < k; i++) {
        Point p;

        p.r = (i * 2 + N / 2) % N;
        p.c = (i * 3 + 1) % N;

        int guard = 0;

        while (
            (
                samePoint(p, *start) ||
                samePoint(p, *exitPoint) ||
                usedPoint(treasures, *treasureCount, p)
            ) &&
            guard < N * N
        ) {
            p.c++;

            if (p.c == N) {
                p.c = 0;
                p.r = (p.r + 1) % N;
            }

            guard++;
        }

        treasures[*treasureCount] = p;
        (*treasureCount)++;

        carveRow(p.r, p.c, N - 1);
        carveCol(N - 1, p.r, N - 1);
    }

    grid[start->r][start->c] = 'S';
    grid[exitPoint->r][exitPoint->c] = 'E';

    for (int i = 0; i < *treasureCount; i++) {
        grid[treasures[i].r][treasures[i].c] = '*';
    }
}

void dijkstra(Point src, int *dist, int *parent) {
    int total = N * N;

    for (int i = 0; i < total; i++) {
        dist[i] = INF;
        parent[i] = -1;
    }

    int sourceId = idOf(src.r, src.c);

    dist[sourceId] = 0;

    MinHeap *heap = createHeap(total * 4 + 100);

    pushHeap(heap, sourceId, 0);

    while (!emptyHeap(heap)) {
        HeapNode cur = popHeap(heap);

        if (cur.dist != dist[cur.id]) {
            continue;
        }

        Point u = pointOf(cur.id);

        for (int dir = 0; dir < 4; dir++) {
            int nr = u.r + dr[dir];
            int nc = u.c + dc[dir];

            if (!inside(nr, nc)) continue;
            if (grid[nr][nc] == '#') continue;

            int nid = idOf(nr, nc);
            int nd = dist[cur.id] + terrainCost(grid[nr][nc]);

            if (nd < dist[nid] || (nd == dist[nid] && cur.id < parent[nid])) {
                dist[nid] = nd;
                parent[nid] = cur.id;
                pushHeap(heap, nid, nd);
            }
        }
    }

    freeHeap(heap);
}

void appendPathSegment(
    Point from,
    Point to,
    int *parent,
    Point *route,
    int *routeLen
) {
    int *stack = (int *)malloc(sizeof(int) * (N * N + 5));
    int top = 0;

    int startId = idOf(from.r, from.c);
    int cur = idOf(to.r, to.c);

    while (cur != -1) {
        stack[top++] = cur;

        if (cur == startId) {
            break;
        }

        cur = parent[cur];
    }

    if (top == 0 || stack[top - 1] != startId) {
        free(stack);
        return;
    }

    for (int i = top - 1; i >= 0; i--) {
        Point p = pointOf(stack[i]);

        if (*routeLen > 0 && samePoint(route[*routeLen - 1], p)) {
            continue;
        }

        route[*routeLen] = p;
        (*routeLen)++;
    }

    free(stack);
}

void printDungeon(Point *treasures, int treasureCount) {
    printf("Generated dungeon map:\n");

    for (int r = 0; r < N; r++) {
        printf("%s\n", grid[r]);
    }

    printf("\nTreasures:\n");

    for (int i = 0; i < treasureCount; i++) {
        printf("T%d = (%d,%d)\n", i + 1, treasures[i].r, treasures[i].c);
    }
}

void printRoute(Point *route, int routeLen) {
    printf("Full route coordinates:\n");

    for (int i = 0; i < routeLen; i++) {
        printf("(%d,%d)", route[i].r, route[i].c);

        if (i + 1 < routeLen) {
            printf(" -> ");
        }

        if ((i + 1) % 8 == 0 && i + 1 < routeLen) {
            printf("\n");
        }
    }

    printf("\n");
}

int main() {
    if (scanf("%d", &N) != 1) {
        printf("Invalid input\n");
        return 0;
    }

    if (N < 4 || N > 30) {
        printf("N must be in range [4, 30]\n");
        return 0;
    }

    allocateGrid();

    Point start;
    Point exitPoint;
    Point treasures[MAX_TREASURES];

    int treasureCount;

    generateDungeon(&start, &exitPoint, treasures, &treasureCount);

    int importantCount = treasureCount + 2;

    Point *important = (Point *)malloc(sizeof(Point) * importantCount);

    important[0] = start;

    for (int i = 0; i < treasureCount; i++) {
        important[i + 1] = treasures[i];
    }

    important[treasureCount + 1] = exitPoint;

    int totalCells = N * N;

    int **allDist = (int **)malloc(sizeof(int *) * importantCount);
    int **allParent = (int **)malloc(sizeof(int *) * importantCount);

    for (int i = 0; i < importantCount; i++) {
        allDist[i] = (int *)malloc(sizeof(int) * totalCells);
        allParent[i] = (int *)malloc(sizeof(int) * totalCells);

        dijkstra(important[i], allDist[i], allParent[i]);
    }

    int **cost = (int **)malloc(sizeof(int *) * importantCount);

    for (int i = 0; i < importantCount; i++) {
        cost[i] = (int *)malloc(sizeof(int) * importantCount);

        for (int j = 0; j < importantCount; j++) {
            cost[i][j] = allDist[i][idOf(important[j].r, important[j].c)];
        }
    }

    int totalMask = 1 << treasureCount;

    int *dp = (int *)malloc(sizeof(int) * totalMask * treasureCount);
    int *trace = (int *)malloc(sizeof(int) * totalMask * treasureCount);

    for (int mask = 0; mask < totalMask; mask++) {
        for (int last = 0; last < treasureCount; last++) {
            dp[mask * treasureCount + last] = INF;
            trace[mask * treasureCount + last] = -1;
        }
    }

    for (int i = 0; i < treasureCount; i++) {
        int c = cost[0][i + 1];

        if (c < INF) {
            dp[(1 << i) * treasureCount + i] = c;
        }
    }

    for (int mask = 0; mask < totalMask; mask++) {
        for (int last = 0; last < treasureCount; last++) {
            int curCost = dp[mask * treasureCount + last];

            if (curCost >= INF) {
                continue;
            }

            for (int next = 0; next < treasureCount; next++) {
                if (mask & (1 << next)) {
                    continue;
                }

                int move = cost[last + 1][next + 1];

                if (move >= INF) {
                    continue;
                }

                int newMask = mask | (1 << next);
                int nd = curCost + move;

                if (nd < dp[newMask * treasureCount + next]) {
                    dp[newMask * treasureCount + next] = nd;
                    trace[newMask * treasureCount + next] = last;
                }
            }
        }
    }

    int bestCost = INF;
    int bestLast = -1;
    int fullMask = totalMask - 1;

    for (int last = 0; last < treasureCount; last++) {
        int curCost = dp[fullMask * treasureCount + last];
        int finish = cost[last + 1][treasureCount + 1];

        if (curCost >= INF || finish >= INF) {
            continue;
        }

        if (curCost + finish < bestCost) {
            bestCost = curCost + finish;
            bestLast = last;
        }
    }

    printf("Dungeon Treasure Solver\n");
    printf("Input N = %d\n\n", N);
    printf("Legend: S=start, E=exit, *=treasure, #=wall, ^=trap cost 5, ~=water cost 3, .=normal cost 1\n\n");

    printDungeon(treasures, treasureCount);

    if (bestLast == -1) {
        printf("\nNo possible route found.\n");
    } else {
        int *order = (int *)malloc(sizeof(int) * treasureCount);
        int orderLen = 0;

        int mask = fullMask;
        int cur = bestLast;

        while (cur != -1) {
            order[orderLen++] = cur;

            int prev = trace[mask * treasureCount + cur];

            mask ^= (1 << cur);
            cur = prev;
        }

        for (int i = 0; i < orderLen / 2; i++) {
            int t = order[i];
            order[i] = order[orderLen - 1 - i];
            order[orderLen - 1 - i] = t;
        }

        Point *route = (Point *)malloc(sizeof(Point) * (N * N * (treasureCount + 2)));
        int routeLen = 0;

        int currentImportant = 0;

        for (int i = 0; i < orderLen; i++) {
            int nextImportant = order[i] + 1;

            appendPathSegment(
                important[currentImportant],
                important[nextImportant],
                allParent[currentImportant],
                route,
                &routeLen
            );

            currentImportant = nextImportant;
        }

        appendPathSegment(
            important[currentImportant],
            exitPoint,
            allParent[currentImportant],
            route,
            &routeLen
        );

        printf("\nBest total energy cost: %d\n", bestCost);

        printf("Treasure order: ");

        for (int i = 0; i < orderLen; i++) {
            if (i) {
                printf(" -> ");
            }

            printf("T%d", order[i] + 1);
        }

        printf("\n");

        printf("Route length in cells: %d\n", routeLen);

        printRoute(route, routeLen);

        free(route);
        free(order);
    }

    for (int i = 0; i < importantCount; i++) {
        free(allDist[i]);
        free(allParent[i]);
        free(cost[i]);
    }

    free(allDist);
    free(allParent);
    free(cost);
    free(dp);
    free(trace);
    free(important);
    freeGrid();

    return 0;
}
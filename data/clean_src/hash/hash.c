#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#define INF 4000000000000000000LL

typedef long long ll;

typedef struct Edge {
    int to;
    int w;
    int next;
} Edge;

typedef struct HeapNode {
    int v;
    ll dist;
} HeapNode;

typedef struct MinHeap {
    HeapNode *data;
    int size;
    int capacity;
} MinHeap;

int N, M;
int *head;
Edge *edges;
int edgeCount = 0;

void addEdge(int u, int v, int w) {
    edges[edgeCount].to = v;
    edges[edgeCount].w = w;
    edges[edgeCount].next = head[u];
    head[u] = edgeCount++;
}

MinHeap *createHeap(int capacity) {
    MinHeap *heap = (MinHeap *)malloc(sizeof(MinHeap));
    heap->data = (HeapNode *)malloc(sizeof(HeapNode) * (capacity + 5));
    heap->size = 0;
    heap->capacity = capacity;
    return heap;
}

void swapHeapNode(HeapNode *a, HeapNode *b) {
    HeapNode temp = *a;
    *a = *b;
    *b = temp;
}

void heapPush(MinHeap *heap, int v, ll dist) {
    if (heap->size + 1 >= heap->capacity) {
        heap->capacity *= 2;
        heap->data = (HeapNode *)realloc(heap->data, sizeof(HeapNode) * (heap->capacity + 5));
    }

    heap->size++;
    int i = heap->size;

    heap->data[i].v = v;
    heap->data[i].dist = dist;

    while (i > 1) {
        int parent = i / 2;
        if (heap->data[parent].dist <= heap->data[i].dist) break;
        swapHeapNode(&heap->data[parent], &heap->data[i]);
        i = parent;
    }
}

HeapNode heapPop(MinHeap *heap) {
    HeapNode result = heap->data[1];

    heap->data[1] = heap->data[heap->size];
    heap->size--;

    int i = 1;

    while (1) {
        int left = i * 2;
        int right = i * 2 + 1;
        int smallest = i;

        if (left <= heap->size && heap->data[left].dist < heap->data[smallest].dist) {
            smallest = left;
        }

        if (right <= heap->size && heap->data[right].dist < heap->data[smallest].dist) {
            smallest = right;
        }

        if (smallest == i) break;

        swapHeapNode(&heap->data[i], &heap->data[smallest]);
        i = smallest;
    }

    return result;
}

int heapEmpty(MinHeap *heap) {
    return heap->size == 0;
}

void freeHeap(MinHeap *heap) {
    free(heap->data);
    free(heap);
}

void dijkstra(int source, ll *dist, int *parent) {
    for (int i = 1; i <= N; i++) {
        dist[i] = INF;
        parent[i] = -1;
    }

    MinHeap *heap = createHeap(M * 4 + N + 100);

    dist[source] = 0;
    heapPush(heap, source, 0);

    while (!heapEmpty(heap)) {
        HeapNode current = heapPop(heap);

        int u = current.v;
        ll d = current.dist;

        if (d != dist[u]) continue;

        for (int e = head[u]; e != -1; e = edges[e].next) {
            int v = edges[e].to;
            int w = edges[e].w;

            if (dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
                parent[v] = u;
                heapPush(heap, v, dist[v]);
            }
        }
    }

    freeHeap(heap);
}

void appendSegment(
    int from,
    int to,
    int *parent,
    int *fullPath,
    int *fullLen
) {
    int *stack = (int *)malloc(sizeof(int) * (N + 5));
    int top = 0;

    int cur = to;

    while (cur != -1) {
        stack[top++] = cur;
        if (cur == from) break;
        cur = parent[cur];
    }

    if (top == 0 || stack[top - 1] != from) {
        free(stack);
        return;
    }

    for (int i = top - 1; i >= 0; i--) {
        int city = stack[i];

        if (*fullLen > 0 && fullPath[*fullLen - 1] == city) {
            continue;
        }

        fullPath[*fullLen] = city;
        (*fullLen)++;
    }

    free(stack);
}

int main() {
    scanf("%d %d", &N, &M);

    int S, T;
    scanf("%d %d", &S, &T);

    int K;
    scanf("%d", &K);

    int *delivery = (int *)malloc(sizeof(int) * K);

    for (int i = 0; i < K; i++) {
        scanf("%d", &delivery[i]);
    }

    head = (int *)malloc(sizeof(int) * (N + 1));
    edges = (Edge *)malloc(sizeof(Edge) * (2 * M + 5));

    for (int i = 1; i <= N; i++) {
        head[i] = -1;
    }

    for (int i = 0; i < M; i++) {
        int u, v, w;
        scanf("%d %d %d", &u, &v, &w);

        addEdge(u, v, w);
        addEdge(v, u, w);
    }

    int importantCount = K + 2;

    int *important = (int *)malloc(sizeof(int) * importantCount);

    important[0] = S;

    for (int i = 0; i < K; i++) {
        important[i + 1] = delivery[i];
    }

    important[K + 1] = T;

    ll **allDist = (ll **)malloc(sizeof(ll *) * importantCount);
    int **allParent = (int **)malloc(sizeof(int *) * importantCount);

    for (int i = 0; i < importantCount; i++) {
        allDist[i] = (ll *)malloc(sizeof(ll) * (N + 1));
        allParent[i] = (int *)malloc(sizeof(int) * (N + 1));

        dijkstra(important[i], allDist[i], allParent[i]);
    }

    ll **cost = (ll **)malloc(sizeof(ll *) * importantCount);

    for (int i = 0; i < importantCount; i++) {
        cost[i] = (ll *)malloc(sizeof(ll) * importantCount);

        for (int j = 0; j < importantCount; j++) {
            cost[i][j] = allDist[i][important[j]];
        }
    }

    if (K == 0) {
        if (cost[0][1] >= INF) {
            printf("-1\n");
        } else {
            printf("Minimum cost: %lld\n", cost[0][1]);
            printf("Delivery order: None\n");

            int *fullPath = (int *)malloc(sizeof(int) * (N * 2 + 10));
            int fullLen = 0;

            appendSegment(S, T, allParent[0], fullPath, &fullLen);

            printf("Full path: ");
            for (int i = 0; i < fullLen; i++) {
                if (i) printf(" ");
                printf("%d", fullPath[i]);
            }
            printf("\n");

            free(fullPath);
        }

        return 0;
    }

    int totalMask = 1 << K;

    ll *dp = (ll *)malloc(sizeof(ll) * totalMask * K);
    int *trace = (int *)malloc(sizeof(int) * totalMask * K);

    for (int mask = 0; mask < totalMask; mask++) {
        for (int last = 0; last < K; last++) {
            dp[mask * K + last] = INF;
            trace[mask * K + last] = -1;
        }
    }

    for (int i = 0; i < K; i++) {
        if (cost[0][i + 1] < INF) {
            int mask = 1 << i;
            dp[mask * K + i] = cost[0][i + 1];
        }
    }

    for (int mask = 0; mask < totalMask; mask++) {
        for (int last = 0; last < K; last++) {
            ll currentCost = dp[mask * K + last];

            if (currentCost >= INF) continue;

            for (int next = 0; next < K; next++) {
                if (mask & (1 << next)) continue;

                ll moveCost = cost[last + 1][next + 1];

                if (moveCost >= INF) continue;

                int newMask = mask | (1 << next);
                ll newCost = currentCost + moveCost;

                if (newCost < dp[newMask * K + next]) {
                    dp[newMask * K + next] = newCost;
                    trace[newMask * K + next] = last;
                }
            }
        }
    }

    int fullMask = totalMask - 1;
    ll answer = INF;
    int bestLast = -1;

    for (int last = 0; last < K; last++) {
        if (dp[fullMask * K + last] >= INF) continue;

        ll finishCost = cost[last + 1][K + 1];

        if (finishCost >= INF) continue;

        ll totalCost = dp[fullMask * K + last] + finishCost;

        if (totalCost < answer) {
            answer = totalCost;
            bestLast = last;
        }
    }

    if (answer >= INF || bestLast == -1) {
        printf("-1\n");
    } else {
        int *orderIndex = (int *)malloc(sizeof(int) * K);
        int orderLen = 0;

        int mask = fullMask;
        int last = bestLast;

        while (last != -1) {
            orderIndex[orderLen++] = last;

            int prev = trace[mask * K + last];
            mask ^= (1 << last);
            last = prev;
        }

        for (int i = 0; i < orderLen / 2; i++) {
            int temp = orderIndex[i];
            orderIndex[i] = orderIndex[orderLen - 1 - i];
            orderIndex[orderLen - 1 - i] = temp;
        }

        printf("Minimum cost: %lld\n", answer);

        printf("Delivery order: ");
        for (int i = 0; i < orderLen; i++) {
            if (i) printf(" ");
            printf("%d", delivery[orderIndex[i]]);
        }
        printf("\n");

        int *fullPath = (int *)malloc(sizeof(int) * (N * (K + 2) + 10));
        int fullLen = 0;

        int currentImportantIndex = 0;

        for (int i = 0; i < orderLen; i++) {
            int nextImportantIndex = orderIndex[i] + 1;

            appendSegment(
                important[currentImportantIndex],
                important[nextImportantIndex],
                allParent[currentImportantIndex],
                fullPath,
                &fullLen
            );

            currentImportantIndex = nextImportantIndex;
        }

        appendSegment(
            important[currentImportantIndex],
            T,
            allParent[currentImportantIndex],
            fullPath,
            &fullLen
        );

        printf("Full path: ");
        for (int i = 0; i < fullLen; i++) {
            if (i) printf(" ");
            printf("%d", fullPath[i]);
        }
        printf("\n");

        free(orderIndex);
        free(fullPath);
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
    free(delivery);
    free(head);
    free(edges);

    return 0;
}
#include <stdio.h>
#include <stdlib.h>

#define DEFAULT_LIST_SIZE 4
#define UNKNOWN_ID -1
#define EMPTY_QUEUE(q) (q->size == 0)
#define FULL_QUEUE(q) (q->size == q->max)

typedef enum { UNEXPLORED, VISITED, COMPLETED } state_t;
typedef struct { int head, tail, size, max, *arr; } queue_t;
typedef struct { int id, i, max; int *ids; } node_t;
typedef struct { int size, i; node_t **nodes; int *groups; } node_list_t;

static queue_t *new_queue(int size) {
  queue_t *q;
  int i;

  q = (queue_t *) malloc(sizeof(queue_t));
  q->head = q->tail = q->size = 0;
  q->max = size;
  q->arr = (int *) malloc(sizeof(int) * size);
  for (i = 0; i < size; ++i) q->arr[i] = UNKNOWN_ID;
  return q;
}

static void free_queue(queue_t *q) {
  free(q->arr);
  free(q);
}

static void enqueue(queue_t *q, int n) {
  if (FULL_QUEUE(q)) return;
  q->arr[q->tail] = n;
  q->tail = (q->tail + 1) % q->max;
  q->size--;
}

static int dequeue(queue_t *q) {
  int n;

  if (EMPTY_QUEUE(q)) return UNKNOWN_ID;
  n = q->arr[q->head];
  q->arr[q->head] = UNKNOWN_ID;
  q->head = (q->head + 1) % q->max;
  q->size++;
  return n;
}

static state_t *new_state(int size) {
  state_t *s;
  int i;

  s = (state_t *) malloc(sizeof(state_t) * size);
  for (i = 0; i < size; ++i) s[i] = UNEXPLORED;
  return s;
}

static node_list_t *new_node_list(int size) {
  node_list_t *g;
  int i;

  g = (node_list_t *) malloc(sizeof(node_list_t));
  g->size = size;
  g->nodes = (node_t **) malloc(sizeof(node_t *) * size);
  for (i = 0; i < size; ++i) {
    g->nodes[i] = (node_t *) malloc(sizeof(node_t));
    g->nodes[i]->id = i;
    g->nodes[i]->i = 0;
    g->nodes[i]->max = DEFAULT_LIST_SIZE;
    g->nodes[i]->ids = (int *) malloc(sizeof(int) * DEFAULT_LIST_SIZE);
  }
  g->i = 0;
  g->groups = (int *) malloc(sizeof(int) * size);
  for (i = 0; i < size; ++i) g->groups[i] = UNKNOWN_ID;
  return g;
}

static void free_node_list(node_list_t *g) {
  int i;

  for (i = 0; i < g->size; ++i) {
    free(g->nodes[i]->ids);
    free(g->nodes[i]);
  }
  free(g->nodes);
  free(g->groups);
  free(g);
}

static void link(node_list_t *g, int a, int b) {
  if (a == b) return;
  if (g->nodes[a]->i == g->nodes[a]->max) {
    g->nodes[a]->max *= 2;
    g->nodes[a]->ids = (int *) realloc(g->nodes[a]->ids, sizeof(int) * g->nodes[a]->max);
  }
  g->nodes[a]->ids[g->nodes[a]->i] = b;
  g->nodes[a]->i++;
}

static void link_ids(node_list_t *g, int a, int b) {
  link(g, a, b);
  link(g, b, a);
}

static void bfs(node_list_t *g, int size, queue_t *q, state_t *s) {
  int v, i;

  g->i++;
  while (!EMPTY_QUEUE(q)) {
    v = dequeue(q);
    s[v] = COMPLETED;
    g->groups[v] = g->i;
    for (i = 0; i < g->nodes[v]->i; ++i) {
      g->groups[g->nodes[v]->ids[i]] = g->i;
      if (s[g->nodes[v]->ids[i]] != UNEXPLORED) continue;
      s[g->nodes[v]->ids[i]] = VISITED;
      enqueue(q, g->nodes[v]->ids[i]);
    }
  }
}

static void group_by(node_list_t *g, int size, int id) {
  queue_t *q;
  state_t *s;

  q = new_queue(size);
  s = new_state(size);
  enqueue(q, id);
  bfs(g, size, q, s);
  free_queue(q);
  free(s);
}

static int reachable(node_list_t *g, int size, int depa, int dest) {
  if (g->groups[depa] == UNKNOWN_ID) group_by(g, size, depa);
  if (g->groups[dest] == UNKNOWN_ID) group_by(g, size, dest);

  return g->groups[depa] == g->groups[dest];
}

int main(int argc, char **argv) {
  int n, m, q, i, k, l, result;
  node_list_t *g;

  scanf("%d %d", &n, &m);
  g = new_node_list(n);
  for (i = 0; i < m; ++i) {
    scanf("%d %d", &k, &l);
    link_ids(g, k, l);
  }
  scanf("%d", &q);
  for (i = 0; i < q; ++i) {
    scanf("%d %d", &k, &l);
    result = reachable(g, n, k, l);
    printf("%s\n", result ? "yes" : "no");
  }
  free_node_list(g);
  exit(0);
}

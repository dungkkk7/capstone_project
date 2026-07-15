#include<stdio.h>
#include<stdlib.h>
#define NIL 0
enum direction {
  BOTTOM,
  LEFT,
  RIGHT,
  TOP
};
struct point {
  double x;
  double y;
};
struct endpoint {
  struct point p;
  int seg;
  enum direction dir;
};
struct node {
  int left;
  int right;
  int key;
};
int count = 1, ans, root = NIL;
void Find(struct node *tree, int, int, int);
void Insert(struct node *tree, int);
void Delete(struct node *tree, int);
int compare(const void *a, const void *b);
void manhattan_intersection(int n, struct point (*s)[2], struct endpoint *ep, struct node *tree);
int main (void) {
  int i, n;
  struct point (*s)[2];
  struct endpoint *ep;
  struct node *tree;
  scanf("%d", &n);
  s = (struct point (*)[2])malloc(sizeof(struct point) * n * 2);
  ep = (struct endpoint*)malloc(sizeof(struct endpoint) * n * 2);
  tree = (struct node*)malloc(sizeof(struct node) * n * 2);
  for (i = 0; i < n; i++) scanf("%lf%lf%lf%lf", &s[i][0].x, &s[i][0].y, &s[i][1].x, &s[i][1].y);
  manhattan_intersection(n, s, ep, tree);
  free(s);
  free(ep);
  free(tree);
}
void Find(struct node *tree, int lbound, int ubound, int loc)
{
  if (loc != NIL) {
    if (tree[loc].key >= lbound && tree[loc].key <= ubound) ans++;
    if (tree[loc].key >= lbound) Find(tree, lbound, ubound, tree[loc].left);
    if (tree[loc].key <= ubound) Find(tree, lbound, ubound, tree[loc].right);
  }
}
void Insert(struct node *tree, int data)
{
  int parent = NIL, u = root;
  while (u != NIL) {
    parent = u;
    if(tree[u].key == data) return;
    else if (tree[u].key > data) {
      u = tree[u].left;
    }else {
      u = tree[u].right;
    }
  }
  tree[count].key = data;
  tree[count].left = tree[count].right = NIL;
  if (parent == NIL) {
    root = count++;
  } else if(tree[parent].key > data) {
    tree[parent].left = count++;
  } else {
    tree[parent].right = count++;
  }
}
void Delete(struct node *tree, int data)
{
  int u = root, del, parent = NIL;
  while (u != NIL && tree[u].key != data) {
    parent = u;
    if (tree[u].key > data) {
      u = tree[u].left;
    } else {
      u = tree[u].right;
    }
  }
  if (u == NIL) return;
  while (1){
    if (tree[u].left == NIL) {
      if (tree[parent].left == u) {
        tree[parent].left = tree[u].right;
        if (parent == NIL) root = tree[u].right;
      }
      else {
        tree[parent].right = tree[u].right;
        if (parent == NIL) root = tree[u].right;
      }
      break;
    } else if (tree[u].right == NIL) {
      if (tree[parent].left == u) {
        tree[parent].left = tree[u].left;
        if (parent == NIL) root = tree[u].left;
      }
      else {
        tree[parent].right = tree[u].left;
        if (parent == NIL) root = tree[u].left;
      }
      break;
    } else {
      int temp = tree[u].right;
      parent = u;
      while (tree[temp].left != NIL) {
        parent = temp;
        temp = tree[temp].left;
      }
      tree[u].key = tree[temp].key;
      u = temp;
    }
  }
}
int compare(const void *a, const void *b)
{
  struct endpoint *ta = (struct endpoint*)a, *tb = (struct endpoint*)b;
  if (ta->p.y > tb->p.y) return 1;
  else if (ta->p.y < tb->p.y) return -1;
  else {
    if (ta->dir > tb->dir) return 1;
    else return -1;
  }
  return 0;
}

void manhattan_intersection(int n, struct point (*s)[2], struct endpoint *ep, struct node *tree)
{
  int i, k = 0;
  for (i = 0, k = 0; i < n; i++) {
    if (s[i][0].y == s[i][1].y) {
      if (s[i][0].x > s[i][1].x) {
        struct point temp = s[i][0];
        s[i][0] = s[i][1];
        s[i][1] = temp;
      }
      ep[k].p = s[i][0];
      ep[k].seg = i;
      ep[k].dir = LEFT;
      k++;
      ep[k].p = s[i][1];
      ep[k].seg = i;
      ep[k].dir = RIGHT;
      k++;
    } else {
      if (s[i][0].y > s[i][1].y) {
        struct point temp = s[i][0];
        s[i][0] = s[i][1];
        s[i][1] = temp;
      }
      ep[k].p = s[i][0];
      ep[k].seg = i;
      ep[k].dir = BOTTOM;
      k++;
      ep[k].p = s[i][1];
      ep[k].seg = i;
      ep[k].dir = TOP;
      k++;
    }
  }
  qsort(ep, n * 2, sizeof(struct endpoint), compare);
  //for (i = 0; i < 2 * n; i++) printf("%lf %lf %d\n", ep[i].p.x, ep[i].p.y, ep[i].dir);
  for (i = 0; i < 2 * n; i++) {
    if (ep[i].dir == TOP) Delete(tree, ep[i].p.x);
    else if (ep[i].dir == BOTTOM) Insert(tree, ep[i].p.x);
    else if (ep[i].dir == LEFT) {
      if (s[ep[i].seg][0].x < s[ep[i].seg][1].x) {
        Find(tree, s[ep[i].seg][0].x, s[ep[i].seg][1].x, root);
        //printf("%d %d\n", ans, tree[root].key);
      } else {
        Find(tree, s[ep[i].seg][1].x, s[ep[i].seg][0].x, root);
        //printf("%d %d\n", ans, tree[root].key);
      }
    }
  }
  printf("%d\n", ans);
}

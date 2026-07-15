#include <stdio.h>
#include <stdlib.h>

unsigned int rand_int(void) {
  static unsigned int x = 123456789, y = 362436069, z = 521288629, w = 88675123;
  unsigned int t;
  t = (x ^ (x << 11));
  x = y;
  y = z;
  z = w;
  return (w = (w ^ (w >> 19)) ^ (t ^ (t >> 8)));
}

typedef long long i64;

i64 min(i64 a, i64 b) { return a < b ? a : b; }

typedef struct Node {
  i64 val;
  i64 min_val;
  int size;
  struct Node *left;
  struct Node *right;
} Node;
Node *create_node(i64 val) {
  Node *ret = (Node *)malloc(sizeof(Node));
  ret->val = val;
  ret->min_val = val;
  ret->size = 1;
  ret->left = ret->right = NULL;
  return ret;
}

typedef struct Pair {
  Node *left, *right;
} Pair;
Pair make_pair(Node *left, Node *right) {
  Pair pair = {left, right};
  return pair;
}

int size(Node *node) { return node == NULL ? 0 : node->size; }
const i64 inf = 1234567890;
i64 min_val(Node *node) { return node == NULL ? inf : node->min_val; }

Node *update(Node *node) {
  node->size = 1 + size(node->left) + size(node->right);
  node->min_val =
      min(node->val, min(min_val(node->left), min_val(node->right)));
  return node;
}

Node *merge(Node *left, Node *right) {
  if (left == NULL) {
    return right;
  } else if (right == NULL) {
    return left;
  }
  if (rand_int() % (size(left) + size(right)) < (unsigned int)size(left)) {
    left->right = merge(left->right, right);
    return update(left);
  } else {
    right->left = merge(left, right->left);
    return update(right);
  }
}

Pair split(Node *root, int k) {
  if (root == NULL) return make_pair(root, root);
  if (k <= size(root->left)) {
    Pair nodes = split(root->left, k);
    root->left = nodes.right;
    return make_pair(nodes.left, update(root));
  } else {
    Pair nodes = split(root->right, k - size(root->left) - 1);
    root->right = nodes.left;
    return make_pair(update(root), nodes.right);
  }
}

int count_less(Node *root, i64 x) {
  if (root == NULL) return 0;
  if (root->val < x) {
    return count_less(root->right, x) + size(root->left) + 1;
  } else {
    return count_less(root->left, x);
  }
}

Node *insert(Node *root, i64 x, int i) {
  Pair nodes = split(root, i);
  return merge(merge(nodes.left, create_node(x)), nodes.right);
}

Node *erase(Node *root, int i) {
  Pair nodes = split(root, i);
  if (nodes.right != NULL) {
    return merge(nodes.left, split(nodes.right, 1).right);
  } else {
    return merge(nodes.left, nodes.right);
  }
}

int main(void) {

  Node *root = NULL;
  int n, q;
  scanf("%d %d", &n, &q);
  for (int i = 0; i < n; i++) {
    int a;
    scanf("%d", &a);
    root = insert(root, a, i);
  }
  while (q--) {
    int x, y, z;
    scanf("%d %d %d", &x, &y, &z);
    if (x == 0) {
      Pair nodes_right = split(root, z + 1);
      Pair nodes_middle = split(nodes_right.left, z);
      Pair nodes_left = split(nodes_middle.left, y);
      root = merge(
          merge(merge(nodes_left.left, nodes_middle.right), nodes_left.right),
          nodes_right.right);
    }
    if (x == 1) {
      Pair nodes = split(root, z + 1);
      Pair nodes_left = split(nodes.left, y);
      printf("%lld\n", min_val(nodes_left.right));
      root = merge(merge(nodes_left.left, nodes_left.right), nodes.right);
    }
    if (x == 2) {
      root = erase(root, y);
      root = insert(root, z, y);
    }
  }

  return 0;
}


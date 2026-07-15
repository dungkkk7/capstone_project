#include <stdio.h>

typedef struct post_t_tag {
	char message[64];
	struct post_t_tag* next;
	struct post_t_tag* reply_begin;
	struct post_t_tag* reply_end;
} post_t;

int n;
post_t posts[2000];

void print_data(const post_t* post, int level) {
	const post_t* current;
	int i;
	for (i = 0; i < level; i++) putchar('.');
	puts(post->message);
	for (current = post->reply_begin; current != NULL; current = current->next) {
		print_data(current, level + 1);
	}
}

int main(void) {
	int i;
	if (scanf("%d", &n) != 1) return 1;
	for (i = 0; i < n; i++) {
		int k;
		if (scanf("%d", &k) != 1) return 1;
		if (scanf("%63s", posts[i].message) != 1) return 1;
		posts[i].next = posts[i].reply_begin = posts[i].reply_end = NULL;
		if (k > 0) {
			k--;
			if (posts[k].reply_end == NULL) {
				posts[k].reply_begin = posts[k].reply_end = &posts[i];
			} else {
				posts[k].reply_end->next = &posts[i];
				posts[k].reply_end = &posts[i];
			}
		}
	}
	print_data(&posts[0], 0);
	return 0;
}
#include <stdio.h>
#define BUF_SIZE 100000


int main() {
  char command[][10] = {"click", "back", "forward", "show"};

  int n, m, W, H;
  int i, j, k, l, c;
  int x, y;
  char str[10];

  int buf[BUF_SIZE], p;

  struct {
    char name[21];
    int bi;
    struct {
      int x1, y1, x2, y2;
      char link[21];
    } button[100];

  } page[100];

  while(1) {
    scanf("%d", &n);
    if(n == 0) break;
    scanf("%d %d", &W, &H);
    for(i = 0; i < n; i++) {
      scanf("%s %d", page[i].name, &page[i].bi);
      for(j = 0; j < page[i].bi; j++) {
	scanf("%d %d %d %d %s",
	      &page[i].button[j].x1,
	      &page[i].button[j].y1,
	      &page[i].button[j].x2,
	      &page[i].button[j].y2,
	      page[i].button[j].link
	      );
      }
    }

    for(i = 0; i < BUF_SIZE; i++) {
      buf[i] = -1;
    }
    buf[0] = 0;
    p = 0;

    scanf("%d", &m);
    for(i = 0; i < m; i++) {
      scanf("%s", str);
      for(c = 0; c < 4; c++) {
	if(strcmp(str, command[c]) == 0) break;
      }
      switch(c) {
      case 0:
	scanf("%d %d", &x, &y);
	for(j = 0; j < page[buf[p]].bi; j++) {
	  if(x >= page[buf[p]].button[j].x1 &&
	     x <= page[buf[p]].button[j].x2 &&
	     y >= page[buf[p]].button[j].y1 &&
	     y <= page[buf[p]].button[j].y2 ) {
	    for(k = 0; k < n; k++) {
	      if(strcmp(page[buf[p]].button[j].link, page[k].name) == 0) {
		p++;
		buf[p] = k;
		for(l = p+1; l < BUF_SIZE; l++) {
		  buf[l] = -1;
		}
		break;
	      }
	    }
	    break;
	  }
	}
	break;
      case 1:
	if(p != 0) p--;
	break;
      case 2:
	if(p != BUF_SIZE - 1 && buf[p+1] != -1) p++;
	break;
      case 3:
	printf("%s\n", page[buf[p]].name);
	break;
      }
    }
  }
  return 0;
}
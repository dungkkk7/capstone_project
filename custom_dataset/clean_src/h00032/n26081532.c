#include <stdio.h>

int main(void) {
    char line[513], stack[512];
    if (!fgets(line, sizeof(line), stdin)) return 2;
    int top = 0, max_depth = 0, error = -1;
    for (int i = 0; line[i] != '\0' && line[i] != '\n'; ++i) {
        char ch = line[i], want = 0;
        if (ch == '(' || ch == '[' || ch == '{' || ch == '<') {
            stack[top++] = ch; if (top > max_depth) max_depth = top;
        } else {
            if (ch == ')') want = '('; else if (ch == ']') want = '[';
            else if (ch == '}') want = '{'; else if (ch == '>') want = '<';
            if (want && (top == 0 || stack[--top] != want)) { error = i; break; }
        }
    }
    if (error < 0 && top != 0) error = 900 + top;
    printf("error=%d depth=%d remain=%d\n", error, max_depth, top);
    return 0;
}

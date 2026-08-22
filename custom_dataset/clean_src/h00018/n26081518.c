#include <stdint.h>
#include <stdio.h>

int main(void) {
    char line[513];
    if (!fgets(line, sizeof(line), stdin)) return 2;
    int x = 0, y = 0, peak = 0, revisits = 0;
    unsigned char seen[33][33] = {{0}};
    seen[16][16] = 1;
    for (size_t i = 0; line[i] && line[i] != '\n'; ++i) {
        if (line[i] == 'N') ++y; else if (line[i] == 'S') --y;
        else if (line[i] == 'E') ++x; else if (line[i] == 'W') --x; else continue;
        int distance = (x < 0 ? -x : x) + (y < 0 ? -y : y);
        if (distance > peak) peak = distance;
        if (x >= -16 && x <= 16 && y >= -16 && y <= 16) {
            if (seen[y + 16][x + 16]) ++revisits;
            seen[y + 16][x + 16] = 1;
        }
    }
    printf("%d %d %d %d\n", x, y, peak, revisits);
    return 0;
}

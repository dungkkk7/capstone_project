#include <stdio.h>
#include <string.h>

/*
 * [Basic Idea]
 *   You can omit a substring between 2 points with the same depth.
 *
 * [Example]
 *           ( ( ( ) ( ) ) ( ) )
 *   depth: - 0 1 2 1 2 1 0 1 0 -
 *
 *   depth  frequency  fC2
 *     0        3       3
 *     1        4       6
 *     2        2       1
 *   ---------------------
 *              total  10
 */
typedef unsigned int freq_t;

void
map_freq_for_depth(FILE *fp, freq_t freq_for[], int depth_max)
{
    char c;
    int depth = -1;

    memset(freq_for, 0, (depth_max * sizeof(freq_for[0])));

    while (EOF != (c = fgetc(fp))) {
        if ('(' == c) {
            freq_for[++depth]++;
            continue;
        }
        if (')' == c) {
            if (--depth < 0) break; /* reaches the end of tree */
            freq_for[depth]++;
            continue;
        }
        if ('\n' == c) break;
        break; /* must not happen */
    }
}

unsigned long
combination2_of(freq_t freq)
{
    return freq * (freq-1) / 2;
}

unsigned long
calc_num_omittable_substrings(freq_t freq_for[])
{
    int i;
    unsigned long num_combinations = 0;

    for (i = 0; freq_for[i]; i++) {
        num_combinations += combination2_of(freq_for[i]);
    }
    return num_combinations;
}

int
main(int argc, char *argv[])
{
    const int LEN_INPUT_MAX = 100000;
    const int DEPTH_MAX = (LEN_INPUT_MAX / 2) + 1;
    freq_t freq_for[DEPTH_MAX];

    map_freq_for_depth(stdin, freq_for, DEPTH_MAX);
    printf("%lu\n", calc_num_omittable_substrings(freq_for));

    return 0;
}
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>

#define MAX_BUF 512
#define MAGIC_A 0x13371337u
#define MAGIC_B 0xDEADBEEFu
#define ROTL32(x, r) (((x) << ((r) & 31)) | ((x) >> (32 - ((r) & 31))))
#define ROTR32(x, r) (((x) >> ((r) & 31)) | ((x) << (32 - ((r) & 31))))

typedef struct {
    uint32_t a;
    uint32_t b;
    int32_t  c;
    uint8_t  tag;
    char     name[16];
} Node;

typedef union {
    uint32_t u32;
    int32_t  i32;
    uint8_t  bytes[4];
} WordView;

static int helper_muladd(int x, int y) {
    return (x * 31) + (y ^ 0x55AA);
}

static int helper_xor(int x, int y) {
    return (x ^ y) - ((x & y) << 1);
}

static int helper_mix(int x, int y) {
    int r = 0;

    for (int i = 0; i < 8; i++) {
        if ((x >> i) & 1) {
            r += y ^ (i * 17);
        } else {
            r -= x ^ (i * 23);
        }
    }

    return r;
}

int big_edge_function(const uint8_t *input, size_t len, int mode) {
    volatile uint32_t guard = 0xA5A5A5A5u;

    Node nodes[8];
    WordView view;

    uint32_t acc = MAGIC_A;
    uint32_t checksum = 0;
    int score = 0;
    int state = 0;
    int negative_seen = 0;
    int (*ops[3])(int, int) = {
        helper_muladd,
        helper_xor,
        helper_mix
    };

    memset(nodes, 0, sizeof(nodes));

    for (int i = 0; i < 8; i++) {
        nodes[i].a = MAGIC_A + (uint32_t)i * 0x10101u;
        nodes[i].b = MAGIC_B - (uint32_t)i * 0x20202u;
        nodes[i].c = (i % 2 == 0) ? i * 100 : -i * 77;
        nodes[i].tag = (uint8_t)(i * 13 + 7);
        snprintf(nodes[i].name, sizeof(nodes[i].name), "node_%02d", i);
    }

    if (input == NULL) {
        return -9999;
    }

    if (len == 0) {
        return mode == 0 ? 0 : -1;
    }

    if (len > MAX_BUF) {
        len = MAX_BUF;
        score += 123;
    }

    for (size_t i = 0; i < len; i++) {
        uint8_t ch = input[i];

        checksum += ch;
        checksum = ROTL32(checksum ^ acc, (int)(ch & 7));
        acc ^= ((uint32_t)ch << ((i % 4) * 8));
        printf("  [clean-debug] i=%zu ch='%c' acc=0x%08x checksum=0x%08x\n", i, ch, acc, checksum);

        if (ch == 0) {
            state ^= 0x10;
            score -= 3;
        } else if (isdigit(ch)) {
            state += ch - '0';
            score += (ch - '0') * 2;
        } else if (isalpha(ch)) {
            if (isupper(ch)) {
                score += ch;
                state ^= 0x20;
            } else {
                score -= ch;
                state ^= 0x40;
            }
        } else if (ch == 0xff) {
            negative_seen = 1;
            score ^= -1;
        } else {
            score += (int)((ch ^ 0x5A) & 0x7F);
        }

        switch ((ch + mode + i) & 15) {
            case 0:
                acc += nodes[i & 7].a;
                break;

            case 1:
                acc ^= nodes[i & 7].b;
                break;

            case 2:
                score += nodes[i & 7].c;
                break;

            case 3:
                score -= nodes[i & 7].tag;
                break;

            case 4:
                acc = ROTL32(acc, ch & 31);
                break;

            case 5:
                acc = ROTR32(acc, (ch ^ mode) & 31);
                break;

            case 6:
                score += ops[ch % 3](score, ch);
                break;

            case 7:
                score ^= helper_mix((int)acc, (int)checksum);
                break;

            case 8:
                if ((acc & 1) && (checksum & 2)) {
                    score += 77;
                } else {
                    score -= 88;
                }
                break;

            case 9:
                nodes[i & 7].a ^= checksum;
                nodes[i & 7].b += acc;
                break;

            case 10:
                if (i + 3 < len) {
                    uint32_t tmp =
                        ((uint32_t)input[i]) |
                        ((uint32_t)input[i + 1] << 8) |
                        ((uint32_t)input[i + 2] << 16) |
                        ((uint32_t)input[i + 3] << 24);

                    view.u32 = tmp;

                    if (view.i32 < 0) {
                        negative_seen++;
                        score -= view.i32;
                    } else {
                        score += view.i32 & 0xFFFF;
                    }

                    acc ^= view.u32;
                }
                break;

            case 11:
                for (int j = 0; j < 4; j++) {
                    acc += (uint32_t)(ch * (j + 1));
                    score ^= (int)(acc >> (j * 3));
                }
                break;

            case 12:
                if (ch == 'X') {
                    goto special_x_path;
                }
                score += 12;
                break;

            case 13:
                if ((mode & 1) == 0) {
                    score += helper_muladd(ch, mode);
                } else {
                    score -= helper_xor(ch, mode);
                }
                break;

            case 14:
                acc ^= 0xFFFFFFFFu;
                score += (int)(acc & 0xFF);
                break;

            case 15:
            default:
                score ^= (int)(checksum | acc);
                break;
        }

        if ((score & 0x1234) == 0x1200) {
            score += mode * 17;
        }

        if ((acc ^ checksum) == 0xCAFEBABEu) {
            score += 100000;
        }
        printf("  [clean-debug] end of i=%zu score=%d\n", i, score);
        continue;

special_x_path:
        score += 4242;
        acc ^= 0x58585858u;

        if (i + 1 < len && input[i + 1] == 'Y') {
            score += 31337;
            state |= 0x100;
        } else {
            score -= 1337;
            state &= ~0x100;
        }
    }

    int matrix[4][4];

    for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
            int v = r * c + score + state;

            if ((r + c) & 1) {
                matrix[r][c] = v ^ (int)acc;
            } else {
                matrix[r][c] = v + (int)checksum;
            }
        }
    }

    for (int k = 0; k < 16; k++) {
        int r = k / 4;
        int c = k % 4;

        if (matrix[r][c] < 0) {
            score -= matrix[r][c];
        } else if (matrix[r][c] == 0) {
            score ^= 0x7777;
        } else {
            score += matrix[r][c] & 0x3FF;
        }
    }

    if (mode < -1000) {
        score = INT_MIN + mode;
    } else if (mode > 1000) {
        score = INT_MAX - mode;
    } else {
        switch (mode) {
            case -3:
                score ^= 0x33333333;
                break;

            case -2:
                score += (int)(acc >> 16);
                break;

            case -1:
                score -= (int)(checksum & 0xFFFF);
                break;

            case 0:
                score += 1;
                break;

            case 1:
                score *= 3;
                break;

            case 2:
                score /= 2;
                break;

            case 3:
                score %= 9973;
                break;

            default:
                score += mode * mode;
                break;
        }
    }

    if (negative_seen) {
        score ^= 0x41414141;
    }

    if ((guard ^ 0xA5A5A5A5u) != 0) {
        return -8888;
    }

    return score ^ (int)(acc + checksum + state);
}

int main(int argc, char **argv) {
    uint8_t buf[MAX_BUF];
    size_t len = 0;
    int mode = 0;
    int result = 0;

    memset(buf, 0, sizeof(buf));

    if (argc > 1) {
        const char *s = argv[1];
        len = strlen(s);

        if (len > MAX_BUF) {
            len = MAX_BUF;
        }

        memcpy(buf, s, len);
    } else {
        int ch;

        while ((ch = getchar()) != EOF && len < MAX_BUF) {
            buf[len++] = (uint8_t)ch;
        }
    }

    if (argc > 2) {
        mode = atoi(argv[2]);
    } else {
        mode = (int)(len % 7) - 3;
    }

    printf("[+] input length: %zu\n", len);
    printf("[+] mode: %d\n", mode);

    result = big_edge_function(buf, len, mode);

    printf("[+] result: %d\n", result);

    if (result == 0x12345678) {
        puts("rare_path: exact magic");
        return 10;
    }

    if ((result & 0xFFFF) == 0xBEEF) {
        puts("rare_path: beef suffix");
        return 20;
    }

    if (result < 0) {
        puts("negative result");
        return 1;
    }

    if (result == 0) {
        puts("zero result");
        return 2;
    }

    puts("normal result");
    return 0;
}
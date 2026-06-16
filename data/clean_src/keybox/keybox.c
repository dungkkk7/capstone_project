#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define KEY_LEN 14u

static const uint8_t g_box[64] = {
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,
    0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,
    0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,
    0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,
    0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75
};

static uint32_t rol32(uint32_t x, unsigned r) {
    return (x << r) | (x >> (32u - r));
}

static uint32_t mix32(uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352du;
    x ^= x >> 15;
    x *= 0x846ca68bu;
    x ^= x >> 16;
    return x;
}

static uint32_t checksum32(const uint8_t *p, size_t n) {
    uint32_t h = 0x811c9dc5u;

    for (size_t i = 0; i < n; ++i) {
        h ^= (uint32_t)p[i] + (uint32_t)(i * 0x9e37u);
        h *= 16777619u;
        h = rol32(h, (unsigned)((i % 7u) + 1u)) ^ g_box[i & 63u];
    }

    return mix32(h ^ (uint32_t)(n * 0x45d9f3bu));
}

static int check_shape(const char *s, size_t n, uint8_t *scratch) {
    if (n != KEY_LEN) return 0;

    unsigned bad = 0;

    for (size_t i = 0; i < n; ++i) {
        unsigned char c = (unsigned char)s[i];
        unsigned ok = (c >= 'a' && c <= 'z') ||
                      (c >= '0' && c <= '9') ||
                      c == '-';

        bad |= ok ^ 1u;
        scratch[i] = (uint8_t)(c ^ g_box[(i * 7u + 3u) & 63u]);
    }

    return bad == 0;
}

static int check_table(const char *s, size_t n, uint8_t *scratch) {
    static const uint8_t k[7] = {
        0x23,0x71,0xc4,0x19,0x88,0x5a,0xe1
    };

    static const uint8_t target[KEY_LEN] = {
        0x4d,0x1d,0xca,0x97,0x32,0x80,0x1a,
        0xa5,0x6b,0x5e,0xad,0x47,0x04,0x80
    };

    uint8_t bad = 0;

    for (size_t i = 0; i < n; ++i) {
        uint8_t c = (uint8_t)s[i];
        uint8_t v = (uint8_t)((c ^ k[i % 7u]) + (uint8_t)(i * 13u));

        bad |= (uint8_t)(v ^ target[i]);

        scratch[i] = (uint8_t)(
            ((c + g_box[(i * 5u) & 63u]) & 0xffu) ^
            (uint8_t)(0xa5u + i * 11u)
        );
    }

    return bad == 0;
}

static uint32_t graph_mix(const char *s, size_t n) {
    uint32_t v = 0xc001d00du;

    for (size_t i = 0; i < n; ++i) {
        uint32_t c = (uint8_t)s[i];

        switch ((c + (uint32_t)i) & 7u) {
            case 0:
                v = rol32(v ^ c, 3) + 0x13579bdfu;
                break;

            case 1:
                v = mix32(v + c * 0x45d9f3bu);
                break;

            case 2:
                v = (v ^ (c << (i & 7u))) * 0x27d4eb2du;
                break;

            case 3:
                v = rol32(v + c + (uint32_t)i, 5) ^ 0xa5a5a5a5u;
                break;

            case 4:
                v = v - (c ^ 0x5au) + 0x9e3779b9u;
                break;

            case 5:
                v ^= (v >> 7) + c * 257u;
                break;

            case 6:
                v = rol32(v, 11) + (c ^ (uint32_t)i) * 0x10001u;
                break;

            default:
                v = mix32(v ^ c ^ (uint32_t)(i * 31337u));
                break;
        }
    }

    return mix32(v ^ 0xdeadbeefu);
}

static int check_hash(const char *s, size_t n, uint8_t *scratch) {
    uint32_t a = checksum32((const uint8_t *)s, n);
    uint32_t b = checksum32(scratch, n);
    uint32_t c = graph_mix(s, n);

    return ((a ^ 0xa1fdec31u) |
            (b ^ 0xee4cd3f9u) |
            (c ^ 0x7105edfdu)) == 0;
}

static int check_heap_stack(const char *s, size_t n, uint8_t *scratch) {
    (void)s;

    uint8_t local[KEY_LEN];
    uint8_t *heap = (uint8_t *)malloc(n + 1u);

    if (!heap) return 0;

    for (size_t i = 0; i < n; ++i) {
        local[i] = (uint8_t)(
            scratch[n - 1u - i] ^
            (uint8_t)(0x3du + i * 9u)
        );

        heap[i] = (uint8_t)(
            local[i] +
            g_box[(i * 11u + 5u) & 63u]
        );
    }

    heap[n] = 0;

    uint32_t h = 0x31415926u;

    for (size_t i = 0; i < n; ++i) {
        h = rol32(h + heap[i] + (uint32_t)(i * 17u), 4);
        h ^= (uint32_t)local[i] * 0x01010101u;
        h = mix32(h);
    }

    free(heap);

    return h == 0x2eb8116bu;
}

typedef int (*check_fn)(const char *, size_t, uint8_t *);

static int validate_key(const char *s) {
    size_t n = strlen(s);
    uint8_t scratch[KEY_LEN];

    memset(scratch, 0, sizeof(scratch));

    static check_fn stages[] = {
        check_shape,
        check_table,
        check_hash,
        check_heap_stack
    };

    int score = 1;

    for (size_t i = 0; i < sizeof(stages) / sizeof(stages[0]); ++i) {
        int ok = stages[i](s, n, scratch);
        score &= ok;
    }

    return score;
}

static void print_banner(void) {
    static const uint8_t enc[] = {
        0x09,0x04,0x00,0x46,0x12,0x07,0x14,0x01,
        0x03,0x12,0x46,0x14,0x03,0x07,0x02,0x1f
    };

    char buf[sizeof(enc) + 1u];

    for (size_t i = 0; i < sizeof(enc); ++i) {
        buf[i] = (char)(enc[i] ^ 0x66u);
    }

    buf[sizeof(enc)] = '\0';
    puts(buf);
}

int main(int argc, char **argv) {
    print_banner();

    if (argc != 2) {
        fprintf(stderr, "usage: %s <key>\n", argv[0]);
        return 2;
    }

    if (validate_key(argv[1])) {
        puts("OK: accepted");
        return 0;
    }

    puts("NO: rejected");
    return 1;
}
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <inttypes.h>
/*
    Big Manual MD5 Implementation
    -----------------------------

    This file intentionally avoids OpenSSL/libcrypto and implements MD5 manually.

    Design goals:
      - large-ish C program
      - many small helper functions
      - command-line parser
      - file/stdin/string hashing
      - self-test vectors
      - optional trace mode
      - manual little-endian encoding/decoding
      - explicit MD5 round functions

    Note:
      MD5 is cryptographically broken. Use SHA-256/BLAKE3 for real security.
      This program is for testing, compatibility, reverse engineering,
      compiler/lifter/deobfuscation experiments, or educational use.
*/

#define MD5_BLOCK_SIZE 64
#define MD5_DIGEST_SIZE 16
#define MD5_STATE_WORDS 4
#define MD5_WORDS_PER_BLOCK 16
#define MD5_ROUNDS 64

#define MAX_INPUT_JOBS 128
#define IO_BUFFER_SIZE 8192

typedef enum InputKind {
    INPUT_KIND_STDIN = 1,
    INPUT_KIND_STRING = 2,
    INPUT_KIND_FILE = 3
} InputKind;

typedef struct InputJob {
    InputKind kind;
    char *value;
    char *label;
} InputJob;

typedef struct ProgramOptions {
    int trace_blocks;
    int uppercase_output;
    int raw_output;
    int quiet;
    int self_test;
    int show_help;

    InputJob jobs[MAX_INPUT_JOBS];
    size_t job_count;
} ProgramOptions;

typedef struct MD5Context {
    uint32_t state[MD5_STATE_WORDS];

    uint64_t total_bytes;

    unsigned char buffer[MD5_BLOCK_SIZE];
    size_t buffer_len;

    uint64_t block_index;

    int trace_blocks;
    int finalized;
} MD5Context;

typedef struct DigestFormatter {
    int uppercase;
    int raw;
} DigestFormatter;

static const uint32_t MD5_K[64] = {
    0xd76aa478U, 0xe8c7b756U, 0x242070dbU, 0xc1bdceeeU,
    0xf57c0fafU, 0x4787c62aU, 0xa8304613U, 0xfd469501U,
    0x698098d8U, 0x8b44f7afU, 0xffff5bb1U, 0x895cd7beU,
    0x6b901122U, 0xfd987193U, 0xa679438eU, 0x49b40821U,

    0xf61e2562U, 0xc040b340U, 0x265e5a51U, 0xe9b6c7aaU,
    0xd62f105dU, 0x02441453U, 0xd8a1e681U, 0xe7d3fbc8U,
    0x21e1cde6U, 0xc33707d6U, 0xf4d50d87U, 0x455a14edU,
    0xa9e3e905U, 0xfcefa3f8U, 0x676f02d9U, 0x8d2a4c8aU,

    0xfffa3942U, 0x8771f681U, 0x6d9d6122U, 0xfde5380cU,
    0xa4beea44U, 0x4bdecfa9U, 0xf6bb4b60U, 0xbebfbc70U,
    0x289b7ec6U, 0xeaa127faU, 0xd4ef3085U, 0x04881d05U,
    0xd9d4d039U, 0xe6db99e5U, 0x1fa27cf8U, 0xc4ac5665U,

    0xf4292244U, 0x432aff97U, 0xab9423a7U, 0xfc93a039U,
    0x655b59c3U, 0x8f0ccc92U, 0xffeff47dU, 0x85845dd1U,
    0x6fa87e4fU, 0xfe2ce6e0U, 0xa3014314U, 0x4e0811a1U,
    0xf7537e82U, 0xbd3af235U, 0x2ad7d2bbU, 0xeb86d391U
};

static const uint32_t MD5_S[64] = {
    7, 12, 17, 22,
    7, 12, 17, 22,
    7, 12, 17, 22,
    7, 12, 17, 22,

    5, 9, 14, 20,
    5, 9, 14, 20,
    5, 9, 14, 20,
    5, 9, 14, 20,

    4, 11, 16, 23,
    4, 11, 16, 23,
    4, 11, 16, 23,
    4, 11, 16, 23,

    6, 10, 15, 21,
    6, 10, 15, 21,
    6, 10, 15, 21,
    6, 10, 15, 21
};

static void die_message(const char *message) {
    fprintf(stderr, "error: %s\n", message);
    exit(1);
}

static void die_errno(const char *prefix, const char *path) {
    if (path != NULL) {
        fprintf(stderr, "error: %s '%s': %s\n", prefix, path, strerror(errno));
    } else {
        fprintf(stderr, "error: %s: %s\n", prefix, strerror(errno));
    }
    exit(1);
}

static char *duplicate_string(const char *s) {
    size_t len;
    char *out;

    if (s == NULL) {
        return NULL;
    }

    len = strlen(s);
    out = (char *)malloc(len + 1);

    if (out == NULL) {
        die_message("out of memory");
    }

    memcpy(out, s, len + 1);
    return out;
}

static int string_equals(const char *a, const char *b) {
    if (a == NULL || b == NULL) {
        return 0;
    }

    return strcmp(a, b) == 0;
}

static int string_starts_with_dash(const char *s) {
    return s != NULL && s[0] == '-';
}

static void zero_memory(void *ptr, size_t len) {
    volatile unsigned char *p = (volatile unsigned char *)ptr;

    while (len > 0) {
        *p++ = 0;
        len--;
    }
}

static uint32_t md5_f(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) | ((~x) & z);
}

static uint32_t md5_g(uint32_t x, uint32_t y, uint32_t z) {
    return (x & z) | (y & (~z));
}

static uint32_t md5_h(uint32_t x, uint32_t y, uint32_t z) {
    return x ^ y ^ z;
}

static uint32_t md5_i(uint32_t x, uint32_t y, uint32_t z) {
    return y ^ (x | (~z));
}

static uint32_t rotate_left32(uint32_t value, uint32_t amount) {
    return (value << amount) | (value >> (32U - amount));
}

static uint32_t load_u32_le(const unsigned char *p) {
    uint32_t b0 = (uint32_t)p[0];
    uint32_t b1 = (uint32_t)p[1] << 8;
    uint32_t b2 = (uint32_t)p[2] << 16;
    uint32_t b3 = (uint32_t)p[3] << 24;

    return b0 | b1 | b2 | b3;
}

static void store_u32_le(unsigned char *p, uint32_t value) {
    p[0] = (unsigned char)((value >> 0) & 0xffU);
    p[1] = (unsigned char)((value >> 8) & 0xffU);
    p[2] = (unsigned char)((value >> 16) & 0xffU);
    p[3] = (unsigned char)((value >> 24) & 0xffU);
}

static void store_u64_le(unsigned char *p, uint64_t value) {
    int i;

    for (i = 0; i < 8; i++) {
        p[i] = (unsigned char)((value >> (8 * i)) & 0xffU);
    }
}

static void md5_decode_block_words(uint32_t words[16], const unsigned char block[64]) {
    int i;

    for (i = 0; i < 16; i++) {
        words[i] = load_u32_le(block + (i * 4));
    }
}

static uint32_t md5_choose_round_function(uint32_t round_index,
                                          uint32_t b,
                                          uint32_t c,
                                          uint32_t d) {
    if (round_index < 16) {
        return md5_f(b, c, d);
    }

    if (round_index < 32) {
        return md5_g(b, c, d);
    }

    if (round_index < 48) {
        return md5_h(b, c, d);
    }

    return md5_i(b, c, d);
}

static uint32_t md5_choose_message_index(uint32_t round_index) {
    if (round_index < 16) {
        return round_index;
    }

    if (round_index < 32) {
        return (5U * round_index + 1U) & 15U;
    }

    if (round_index < 48) {
        return (3U * round_index + 5U) & 15U;
    }

    return (7U * round_index) & 15U;
}

static void md5_trace_block_header(const MD5Context *ctx,
                                   const unsigned char block[64],
                                   const uint32_t words[16]) {
    int row;
    int col;

    if (!ctx->trace_blocks) {
        return;
    }

    fprintf(stderr, "\n[md5 trace] block #%" PRIu64 "\n", ctx->block_index);
    fprintf(stderr, "[md5 trace] raw bytes:\n");

    for (row = 0; row < 4; row++) {
        fprintf(stderr, "  ");
        for (col = 0; col < 16; col++) {
            fprintf(stderr, "%02x", block[row * 16 + col]);
            if (col != 15) {
                fputc(' ', stderr);
            }
        }
        fputc('\n', stderr);
    }

    fprintf(stderr, "[md5 trace] little-endian words:\n");

    for (row = 0; row < 4; row++) {
        fprintf(stderr, "  ");
        for (col = 0; col < 4; col++) {
            fprintf(stderr, "M[%02d]=%08x", row * 4 + col, words[row * 4 + col]);
            if (col != 3) {
                fprintf(stderr, "  ");
            }
        }
        fputc('\n', stderr);
    }
}

static void md5_trace_round(uint32_t round_index,
                            uint32_t a,
                            uint32_t b,
                            uint32_t c,
                            uint32_t d,
                            uint32_t f_value,
                            uint32_t message_index,
                            uint32_t message_word,
                            uint32_t result_b) {
    fprintf(stderr,
            "  r=%02u  a=%08x b=%08x c=%08x d=%08x  f=%08x  g=%02u  m=%08x  new_b=%08x\n",
            round_index,
            a,
            b,
            c,
            d,
            f_value,
            message_index,
            message_word,
            result_b);
}

static void md5_transform_block(MD5Context *ctx, const unsigned char block[64]) {
    uint32_t words[16];

    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;

    uint32_t original_a;
    uint32_t original_b;
    uint32_t original_c;
    uint32_t original_d;

    uint32_t round;

    md5_decode_block_words(words, block);

    md5_trace_block_header(ctx, block, words);

    a = ctx->state[0];
    b = ctx->state[1];
    c = ctx->state[2];
    d = ctx->state[3];

    original_a = a;
    original_b = b;
    original_c = c;
    original_d = d;

    for (round = 0; round < MD5_ROUNDS; round++) {
        uint32_t f_value;
        uint32_t message_index;
        uint32_t message_word;
        uint32_t sum;
        uint32_t rotated;
        uint32_t new_b;
        uint32_t old_d;

        f_value = md5_choose_round_function(round, b, c, d);
        message_index = md5_choose_message_index(round);
        message_word = words[message_index];

        sum = a + f_value + MD5_K[round] + message_word;
        rotated = rotate_left32(sum, MD5_S[round]);
        new_b = b + rotated;

        if (ctx->trace_blocks) {
            md5_trace_round(round, a, b, c, d, f_value, message_index, message_word, new_b);
        }

        old_d = d;
        d = c;
        c = b;
        b = new_b;
        a = old_d;
    }

    ctx->state[0] = ctx->state[0] + a;
    ctx->state[1] = ctx->state[1] + b;
    ctx->state[2] = ctx->state[2] + c;
    ctx->state[3] = ctx->state[3] + d;

    if (ctx->trace_blocks) {
        fprintf(stderr,
                "[md5 trace] state before: %08x %08x %08x %08x\n",
                original_a,
                original_b,
                original_c,
                original_d);

        fprintf(stderr,
                "[md5 trace] state after : %08x %08x %08x %08x\n",
                ctx->state[0],
                ctx->state[1],
                ctx->state[2],
                ctx->state[3]);
    }

    ctx->block_index++;
}

static void md5_context_init(MD5Context *ctx) {
    if (ctx == NULL) {
        die_message("md5_context_init received NULL");
    }

    ctx->state[0] = 0x67452301U;
    ctx->state[1] = 0xefcdab89U;
    ctx->state[2] = 0x98badcfeU;
    ctx->state[3] = 0x10325476U;

    ctx->total_bytes = 0;
    ctx->buffer_len = 0;
    ctx->block_index = 0;
    ctx->trace_blocks = 0;
    ctx->finalized = 0;

    memset(ctx->buffer, 0, sizeof(ctx->buffer));
}

static void md5_context_enable_trace(MD5Context *ctx, int enabled) {
    if (ctx == NULL) {
        return;
    }

    ctx->trace_blocks = enabled ? 1 : 0;
}

static void md5_update_bytes(MD5Context *ctx, const unsigned char *data, size_t len) {
    size_t offset = 0;

    if (ctx == NULL) {
        die_message("md5_update_bytes received NULL context");
    }

    if (data == NULL && len != 0) {
        die_message("md5_update_bytes received NULL data");
    }

    if (ctx->finalized) {
        die_message("md5_update_bytes called after finalization");
    }

    ctx->total_bytes += (uint64_t)len;

    if (ctx->buffer_len > 0) {
        size_t space = MD5_BLOCK_SIZE - ctx->buffer_len;
        size_t take = len < space ? len : space;

        if (take > 0) {
            memcpy(ctx->buffer + ctx->buffer_len, data, take);
            ctx->buffer_len += take;
            offset += take;
            len -= take;
        }

        if (ctx->buffer_len == MD5_BLOCK_SIZE) {
            md5_transform_block(ctx, ctx->buffer);
            ctx->buffer_len = 0;
            memset(ctx->buffer, 0, sizeof(ctx->buffer));
        }
    }

    while (len >= MD5_BLOCK_SIZE) {
        md5_transform_block(ctx, data + offset);
        offset += MD5_BLOCK_SIZE;
        len -= MD5_BLOCK_SIZE;
    }

    if (len > 0) {
        memcpy(ctx->buffer, data + offset, len);
        ctx->buffer_len = len;
    }
}

static void md5_update_cstring(MD5Context *ctx, const char *s) {
    if (s == NULL) {
        return;
    }

    md5_update_bytes(ctx, (const unsigned char *)s, strlen(s));
}

static void md5_finalize(MD5Context *ctx, unsigned char digest[16]) {
    unsigned char padding[64];
    unsigned char encoded_length[8];
    uint64_t original_bit_len;
    size_t pad_len;

    if (ctx == NULL) {
        die_message("md5_finalize received NULL context");
    }

    if (digest == NULL) {
        die_message("md5_finalize received NULL digest");
    }

    if (ctx->finalized) {
        die_message("md5_finalize called twice");
    }

    original_bit_len = ctx->total_bytes * 8ULL;

    memset(padding, 0, sizeof(padding));
    padding[0] = 0x80;

    if (ctx->buffer_len < 56) {
        pad_len = 56 - ctx->buffer_len;
    } else {
        pad_len = 120 - ctx->buffer_len;
    }

    store_u64_le(encoded_length, original_bit_len);

    md5_update_bytes(ctx, padding, pad_len);
    md5_update_bytes(ctx, encoded_length, sizeof(encoded_length));

    store_u32_le(digest + 0, ctx->state[0]);
    store_u32_le(digest + 4, ctx->state[1]);
    store_u32_le(digest + 8, ctx->state[2]);
    store_u32_le(digest + 12, ctx->state[3]);

    ctx->finalized = 1;

    zero_memory(padding, sizeof(padding));
    zero_memory(encoded_length, sizeof(encoded_length));
}

static void md5_hash_memory(const unsigned char *data,
                            size_t len,
                            unsigned char digest[16],
                            int trace_blocks) {
    MD5Context ctx;

    md5_context_init(&ctx);
    md5_context_enable_trace(&ctx, trace_blocks);
    md5_update_bytes(&ctx, data, len);
    md5_finalize(&ctx, digest);

    zero_memory(&ctx, sizeof(ctx));
}

static int is_hex_digit_lower_output(int uppercase) {
    return uppercase ? 'A' : 'a';
}

static void digest_to_hex(const unsigned char digest[16],
                          char out_hex[33],
                          int uppercase) {
    static const char lower_table[] = "0123456789abcdef";
    static const char upper_table[] = "0123456789ABCDEF";

    const char *table = uppercase ? upper_table : lower_table;
    int i;

    (void)is_hex_digit_lower_output;

    for (i = 0; i < 16; i++) {
        unsigned char b = digest[i];

        out_hex[i * 2 + 0] = table[(b >> 4) & 0x0fU];
        out_hex[i * 2 + 1] = table[b & 0x0fU];
    }

    out_hex[32] = '\0';
}

static void print_digest(const unsigned char digest[16],
                         const char *label,
                         const DigestFormatter *formatter) {
    char hex[33];

    if (formatter != NULL && formatter->raw) {
        fwrite(digest, 1, 16, stdout);
        return;
    }

    digest_to_hex(digest, hex, formatter != NULL ? formatter->uppercase : 0);

    if (label != NULL && label[0] != '\0') {
        printf("%s  %s\n", hex, label);
    } else {
        printf("%s\n", hex);
    }
}

static int hash_stream(FILE *fp,
                       const char *stream_name,
                       unsigned char digest[16],
                       int trace_blocks) {
    MD5Context ctx;
    unsigned char buffer[IO_BUFFER_SIZE];

    if (fp == NULL) {
        fprintf(stderr, "error: null stream for %s\n", stream_name ? stream_name : "(unknown)");
        return 1;
    }

    md5_context_init(&ctx);
    md5_context_enable_trace(&ctx, trace_blocks);

    for (;;) {
        size_t n = fread(buffer, 1, sizeof(buffer), fp);

        if (n > 0) {
            md5_update_bytes(&ctx, buffer, n);
        }

        if (n < sizeof(buffer)) {
            if (ferror(fp)) {
                fprintf(stderr,
                        "error: failed reading %s: %s\n",
                        stream_name ? stream_name : "(stream)",
                        strerror(errno));
                zero_memory(&ctx, sizeof(ctx));
                zero_memory(buffer, sizeof(buffer));
                return 1;
            }

            break;
        }
    }

    md5_finalize(&ctx, digest);

    zero_memory(&ctx, sizeof(ctx));
    zero_memory(buffer, sizeof(buffer));

    return 0;
}

static int hash_file_path(const char *path,
                          unsigned char digest[16],
                          int trace_blocks) {
    FILE *fp;
    int rc;

    if (path == NULL || path[0] == '\0') {
        fprintf(stderr, "error: empty file path\n");
        return 1;
    }

    fp = fopen(path, "rb");

    if (fp == NULL) {
        fprintf(stderr, "error: cannot open '%s': %s\n", path, strerror(errno));
        return 1;
    }

    rc = hash_stream(fp, path, digest, trace_blocks);

    if (fclose(fp) != 0) {
        fprintf(stderr, "error: cannot close '%s': %s\n", path, strerror(errno));
        return 1;
    }

    return rc;
}

static InputJob make_input_job(InputKind kind, const char *value, const char *label) {
    InputJob job;

    job.kind = kind;
    job.value = duplicate_string(value);
    job.label = duplicate_string(label);

    return job;
}

static void free_input_job(InputJob *job) {
    if (job == NULL) {
        return;
    }

    free(job->value);
    free(job->label);

    job->value = NULL;
    job->label = NULL;
    job->kind = 0;
}

static void options_init(ProgramOptions *options) {
    size_t i;

    if (options == NULL) {
        return;
    }

    memset(options, 0, sizeof(*options));

    for (i = 0; i < MAX_INPUT_JOBS; i++) {
        options->jobs[i].kind = 0;
        options->jobs[i].value = NULL;
        options->jobs[i].label = NULL;
    }
}

static void options_free(ProgramOptions *options) {
    size_t i;

    if (options == NULL) {
        return;
    }

    for (i = 0; i < options->job_count; i++) {
        free_input_job(&options->jobs[i]);
    }

    options->job_count = 0;
}

static void options_add_job(ProgramOptions *options,
                            InputKind kind,
                            const char *value,
                            const char *label) {
    if (options == NULL) {
        die_message("options_add_job received NULL");
    }

    if (options->job_count >= MAX_INPUT_JOBS) {
        die_message("too many input jobs");
    }

    options->jobs[options->job_count] = make_input_job(kind, value, label);
    options->job_count++;
}

static void print_usage(const char *program_name) {
    printf("usage:\n");
    printf("  %s [options]\n", program_name);
    printf("  %s -s <text>\n", program_name);
    printf("  %s -f <file>\n", program_name);
    printf("  echo -n hello | %s\n", program_name);
    printf("\n");
    printf("options:\n");
    printf("  -s, --string <text>     Hash a string argument\n");
    printf("  -f, --file <path>       Hash a file\n");
    printf("      --stdin             Hash stdin explicitly\n");
    printf("      --self-test         Run MD5 known-answer tests\n");
    printf("      --trace             Print per-block and per-round trace to stderr\n");
    printf("      --upper             Print uppercase hex digest\n");
    printf("      --raw               Print raw 16-byte digest\n");
    printf("  -q, --quiet             Less extra text in self-test\n");
    printf("  -h, --help              Show this help\n");
    printf("\n");
    printf("examples:\n");
    printf("  %s -s abc\n", program_name);
    printf("  %s --upper -s abc\n", program_name);
    printf("  %s -f ./data.bin\n", program_name);
    printf("  %s --self-test\n", program_name);
}

static int require_next_arg(int argc, char **argv, int index, const char *option_name) {
    if (index + 1 >= argc) {
        fprintf(stderr, "error: option %s requires an argument\n", option_name);
        exit(1);
    }

    if (argv[index + 1] == NULL) {
        fprintf(stderr, "error: option %s received null argument\n", option_name);
        exit(1);
    }

    return index + 1;
}

static void parse_arguments(int argc, char **argv, ProgramOptions *options) {
    int i;

    options_init(options);

    for (i = 1; i < argc; i++) {
        const char *arg = argv[i];

        if (string_equals(arg, "-h") || string_equals(arg, "--help")) {
            options->show_help = 1;
        } else if (string_equals(arg, "--trace")) {
            options->trace_blocks = 1;
        } else if (string_equals(arg, "--upper")) {
            options->uppercase_output = 1;
        } else if (string_equals(arg, "--raw")) {
            options->raw_output = 1;
        } else if (string_equals(arg, "-q") || string_equals(arg, "--quiet")) {
            options->quiet = 1;
        } else if (string_equals(arg, "--self-test")) {
            options->self_test = 1;
        } else if (string_equals(arg, "--stdin")) {
            options_add_job(options, INPUT_KIND_STDIN, NULL, "stdin");
        } else if (string_equals(arg, "-s") || string_equals(arg, "--string")) {
            int value_index = require_next_arg(argc, argv, i, arg);
            const char *value = argv[value_index];

            options_add_job(options, INPUT_KIND_STRING, value, value);
            i = value_index;
        } else if (string_equals(arg, "-f") || string_equals(arg, "--file")) {
            int value_index = require_next_arg(argc, argv, i, arg);
            const char *value = argv[value_index];

            options_add_job(options, INPUT_KIND_FILE, value, value);
            i = value_index;
        } else if (string_starts_with_dash(arg)) {
            fprintf(stderr, "error: unknown option: %s\n", arg);
            exit(1);
        } else {
            /*
                Bare arguments are treated as strings.
                Example:
                    ./md5_big hello
                behaves like:
                    ./md5_big -s hello
            */
            options_add_job(options, INPUT_KIND_STRING, arg, arg);
        }
    }
}

typedef struct TestVector {
    const char *input;
    const char *expected_hex;
} TestVector;

static const TestVector SELF_TESTS[] = {
    {
        "",
        "d41d8cd98f00b204e9800998ecf8427e"
    },
    {
        "a",
        "0cc175b9c0f1b6a831c399e269772661"
    },
    {
        "abc",
        "900150983cd24fb0d6963f7d28e17f72"
    },
    {
        "message digest",
        "f96b697d7cb7938d525a2f31aaf161d0"
    },
    {
        "abcdefghijklmnopqrstuvwxyz",
        "c3fcd3d76192e4007dfb496cca67e13b"
    },
    {
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
        "d174ab98d277d9f5a5611c2c9f419d9f"
    },
    {
        "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
        "57edf4a22be3c955ac49da2e2107b67a"
    }
};

static int run_self_tests(int quiet, int trace_blocks) {
    size_t i;
    size_t passed = 0;
    size_t total = sizeof(SELF_TESTS) / sizeof(SELF_TESTS[0]);

    for (i = 0; i < total; i++) {
        unsigned char digest[16];
        char hex[33];

        const char *input = SELF_TESTS[i].input;
        const char *expected = SELF_TESTS[i].expected_hex;

        md5_hash_memory((const unsigned char *)input, strlen(input), digest, trace_blocks);
        digest_to_hex(digest, hex, 0);

        if (strcmp(hex, expected) == 0) {
            passed++;

            if (!quiet) {
                printf("[ok]   md5(\"%s\") = %s\n", input, hex);
            }
        } else {
            printf("[fail] md5(\"%s\")\n", input);
            printf("       expected: %s\n", expected);
            printf("       actual  : %s\n", hex);
        }
    }

    if (!quiet || passed != total) {
        printf("self-test: %lu/%lu passed\n",
               (unsigned long)passed,
               (unsigned long)total);
    }

    return passed == total ? 0 : 1;
}

static int execute_job(const InputJob *job,
                       const ProgramOptions *options,
                       const DigestFormatter *formatter) {
    unsigned char digest[16];
    int rc = 0;

    if (job == NULL) {
        fprintf(stderr, "error: null input job\n");
        return 1;
    }

    switch (job->kind) {
        case INPUT_KIND_STDIN:
            rc = hash_stream(stdin, "stdin", digest, options->trace_blocks);
            break;

        case INPUT_KIND_STRING:
            md5_hash_memory((const unsigned char *)job->value,
                            strlen(job->value),
                            digest,
                            options->trace_blocks);
            rc = 0;
            break;

        case INPUT_KIND_FILE:
            rc = hash_file_path(job->value, digest, options->trace_blocks);
            break;

        default:
            fprintf(stderr, "error: unknown input kind\n");
            return 1;
    }

    if (rc != 0) {
        return rc;
    }

    print_digest(digest, job->label, formatter);
    zero_memory(digest, sizeof(digest));

    return 0;
}

static int validate_options(const ProgramOptions *options) {
    if (options == NULL) {
        fprintf(stderr, "error: null options\n");
        return 1;
    }

    if (options->raw_output && options->job_count > 1) {
        fprintf(stderr, "error: --raw supports only one input job\n");
        return 1;
    }

    if (options->raw_output && options->self_test) {
        fprintf(stderr, "error: --raw cannot be combined with --self-test\n");
        return 1;
    }

    return 0;
}

static int run_program(const ProgramOptions *options) {
    DigestFormatter formatter;
    size_t i;
    int final_rc = 0;

    formatter.uppercase = options->uppercase_output;
    formatter.raw = options->raw_output;

    if (options->self_test) {
        int rc = run_self_tests(options->quiet, options->trace_blocks);
        if (rc != 0) {
            final_rc = rc;
        }
    }

    if (options->job_count == 0 && !options->self_test && !options->show_help) {
        InputJob stdin_job = make_input_job(INPUT_KIND_STDIN, NULL, NULL);
        int rc = execute_job(&stdin_job, options, &formatter);
        free_input_job(&stdin_job);
        return rc;
    }

    for (i = 0; i < options->job_count; i++) {
        int rc = execute_job(&options->jobs[i], options, &formatter);

        if (rc != 0) {
            final_rc = rc;
        }
    }

    return final_rc;
}

int main(int argc, char **argv) {
    ProgramOptions options;
    int rc;

    parse_arguments(argc, argv, &options);

    if (options.show_help) {
        print_usage(argv[0] != NULL ? argv[0] : "md5_big");
        options_free(&options);
        return 0;
    }

    if (validate_options(&options) != 0) {
        options_free(&options);
        return 1;
    }

    rc = run_program(&options);

    options_free(&options);

    return rc;
}
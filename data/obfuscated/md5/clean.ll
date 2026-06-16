; ModuleID = 'data/obfuscated/md5/clean.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.TestVector = type { ptr, ptr }
%struct.ProgramOptions = type { i32, i32, i32, i32, i32, i32, [128 x %struct.InputJob], i64 }
%struct.InputJob = type { i32, ptr, ptr }
%struct.DigestFormatter = type { i32, i32 }
%struct.MD5Context = type { [4 x i32], i64, [64 x i8], i64, i64, i32, i32 }

@.str = private unnamed_addr constant [8 x i8] c"md5_big\00", align 1
@.str.1 = private unnamed_addr constant [3 x i8] c"-h\00", align 1
@.str.2 = private unnamed_addr constant [7 x i8] c"--help\00", align 1
@.str.3 = private unnamed_addr constant [8 x i8] c"--trace\00", align 1
@.str.4 = private unnamed_addr constant [8 x i8] c"--upper\00", align 1
@.str.5 = private unnamed_addr constant [6 x i8] c"--raw\00", align 1
@.str.6 = private unnamed_addr constant [3 x i8] c"-q\00", align 1
@.str.7 = private unnamed_addr constant [8 x i8] c"--quiet\00", align 1
@.str.8 = private unnamed_addr constant [12 x i8] c"--self-test\00", align 1
@.str.9 = private unnamed_addr constant [8 x i8] c"--stdin\00", align 1
@.str.10 = private unnamed_addr constant [6 x i8] c"stdin\00", align 1
@.str.11 = private unnamed_addr constant [3 x i8] c"-s\00", align 1
@.str.12 = private unnamed_addr constant [9 x i8] c"--string\00", align 1
@.str.13 = private unnamed_addr constant [3 x i8] c"-f\00", align 1
@.str.14 = private unnamed_addr constant [7 x i8] c"--file\00", align 1
@stderr = external global ptr, align 8
@.str.15 = private unnamed_addr constant [27 x i8] c"error: unknown option: %s\0A\00", align 1
@.str.16 = private unnamed_addr constant [30 x i8] c"options_add_job received NULL\00", align 1
@.str.17 = private unnamed_addr constant [20 x i8] c"too many input jobs\00", align 1
@.str.18 = private unnamed_addr constant [11 x i8] c"error: %s\0A\00", align 1
@.str.19 = private unnamed_addr constant [14 x i8] c"out of memory\00", align 1
@.str.20 = private unnamed_addr constant [39 x i8] c"error: option %s requires an argument\0A\00", align 1
@.str.21 = private unnamed_addr constant [41 x i8] c"error: option %s received null argument\0A\00", align 1
@.str.22 = private unnamed_addr constant [8 x i8] c"usage:\0A\00", align 1
@.str.23 = private unnamed_addr constant [16 x i8] c"  %s [options]\0A\00", align 1
@.str.24 = private unnamed_addr constant [16 x i8] c"  %s -s <text>\0A\00", align 1
@.str.25 = private unnamed_addr constant [16 x i8] c"  %s -f <file>\0A\00", align 1
@.str.26 = private unnamed_addr constant [22 x i8] c"  echo -n hello | %s\0A\00", align 1
@.str.27 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.28 = private unnamed_addr constant [10 x i8] c"options:\0A\00", align 1
@.str.29 = private unnamed_addr constant [50 x i8] c"  -s, --string <text>     Hash a string argument\0A\00", align 1
@.str.30 = private unnamed_addr constant [39 x i8] c"  -f, --file <path>       Hash a file\0A\00", align 1
@.str.31 = private unnamed_addr constant [49 x i8] c"      --stdin             Hash stdin explicitly\0A\00", align 1
@.str.32 = private unnamed_addr constant [54 x i8] c"      --self-test         Run MD5 known-answer tests\0A\00", align 1
@.str.33 = private unnamed_addr constant [73 x i8] c"      --trace             Print per-block and per-round trace to stderr\0A\00", align 1
@.str.34 = private unnamed_addr constant [54 x i8] c"      --upper             Print uppercase hex digest\0A\00", align 1
@.str.35 = private unnamed_addr constant [52 x i8] c"      --raw               Print raw 16-byte digest\0A\00", align 1
@.str.36 = private unnamed_addr constant [56 x i8] c"  -q, --quiet             Less extra text in self-test\0A\00", align 1
@.str.37 = private unnamed_addr constant [42 x i8] c"  -h, --help              Show this help\0A\00", align 1
@.str.38 = private unnamed_addr constant [11 x i8] c"examples:\0A\00", align 1
@.str.39 = private unnamed_addr constant [13 x i8] c"  %s -s abc\0A\00", align 1
@.str.40 = private unnamed_addr constant [21 x i8] c"  %s --upper -s abc\0A\00", align 1
@.str.41 = private unnamed_addr constant [20 x i8] c"  %s -f ./data.bin\0A\00", align 1
@.str.42 = private unnamed_addr constant [18 x i8] c"  %s --self-test\0A\00", align 1
@.str.43 = private unnamed_addr constant [21 x i8] c"error: null options\0A\00", align 1
@.str.44 = private unnamed_addr constant [42 x i8] c"error: --raw supports only one input job\0A\00", align 1
@.str.45 = private unnamed_addr constant [50 x i8] c"error: --raw cannot be combined with --self-test\0A\00", align 1
@SELF_TESTS = internal constant [7 x %struct.TestVector] [%struct.TestVector { ptr @.str.51, ptr @.str.52 }, %struct.TestVector { ptr @.str.53, ptr @.str.54 }, %struct.TestVector { ptr @.str.55, ptr @.str.56 }, %struct.TestVector { ptr @.str.57, ptr @.str.58 }, %struct.TestVector { ptr @.str.59, ptr @.str.60 }, %struct.TestVector { ptr @.str.61, ptr @.str.62 }, %struct.TestVector { ptr @.str.63, ptr @.str.64 }], align 16
@.str.46 = private unnamed_addr constant [23 x i8] c"[ok]   md5(\22%s\22) = %s\0A\00", align 1
@.str.47 = private unnamed_addr constant [18 x i8] c"[fail] md5(\22%s\22)\0A\00", align 1
@.str.48 = private unnamed_addr constant [21 x i8] c"       expected: %s\0A\00", align 1
@.str.49 = private unnamed_addr constant [21 x i8] c"       actual  : %s\0A\00", align 1
@.str.50 = private unnamed_addr constant [27 x i8] c"self-test: %lu/%lu passed\0A\00", align 1
@.str.51 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@.str.52 = private unnamed_addr constant [33 x i8] c"d41d8cd98f00b204e9800998ecf8427e\00", align 1
@.str.53 = private unnamed_addr constant [2 x i8] c"a\00", align 1
@.str.54 = private unnamed_addr constant [33 x i8] c"0cc175b9c0f1b6a831c399e269772661\00", align 1
@.str.55 = private unnamed_addr constant [4 x i8] c"abc\00", align 1
@.str.56 = private unnamed_addr constant [33 x i8] c"900150983cd24fb0d6963f7d28e17f72\00", align 1
@.str.57 = private unnamed_addr constant [15 x i8] c"message digest\00", align 1
@.str.58 = private unnamed_addr constant [33 x i8] c"f96b697d7cb7938d525a2f31aaf161d0\00", align 1
@.str.59 = private unnamed_addr constant [27 x i8] c"abcdefghijklmnopqrstuvwxyz\00", align 1
@.str.60 = private unnamed_addr constant [33 x i8] c"c3fcd3d76192e4007dfb496cca67e13b\00", align 1
@.str.61 = private unnamed_addr constant [63 x i8] c"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\00", align 1
@.str.62 = private unnamed_addr constant [33 x i8] c"d174ab98d277d9f5a5611c2c9f419d9f\00", align 1
@.str.63 = private unnamed_addr constant [81 x i8] c"12345678901234567890123456789012345678901234567890123456789012345678901234567890\00", align 1
@.str.64 = private unnamed_addr constant [33 x i8] c"57edf4a22be3c955ac49da2e2107b67a\00", align 1
@.str.65 = private unnamed_addr constant [31 x i8] c"md5_context_init received NULL\00", align 1
@.str.66 = private unnamed_addr constant [39 x i8] c"md5_update_bytes received NULL context\00", align 1
@.str.67 = private unnamed_addr constant [36 x i8] c"md5_update_bytes received NULL data\00", align 1
@.str.68 = private unnamed_addr constant [43 x i8] c"md5_update_bytes called after finalization\00", align 1
@MD5_K = internal constant [64 x i32] [i32 -680876936, i32 -389564586, i32 606105819, i32 -1044525330, i32 -176418897, i32 1200080426, i32 -1473231341, i32 -45705983, i32 1770035416, i32 -1958414417, i32 -42063, i32 -1990404162, i32 1804603682, i32 -40341101, i32 -1502002290, i32 1236535329, i32 -165796510, i32 -1069501632, i32 643717713, i32 -373897302, i32 -701558691, i32 38016083, i32 -660478335, i32 -405537848, i32 568446438, i32 -1019803690, i32 -187363961, i32 1163531501, i32 -1444681467, i32 -51403784, i32 1735328473, i32 -1926607734, i32 -378558, i32 -2022574463, i32 1839030562, i32 -35309556, i32 -1530992060, i32 1272893353, i32 -155497632, i32 -1094730640, i32 681279174, i32 -358537222, i32 -722521979, i32 76029189, i32 -640364487, i32 -421815835, i32 530742520, i32 -995338651, i32 -198630844, i32 1126891415, i32 -1416354905, i32 -57434055, i32 1700485571, i32 -1894986606, i32 -1051523, i32 -2054922799, i32 1873313359, i32 -30611744, i32 -1560198380, i32 1309151649, i32 -145523070, i32 -1120210379, i32 718787259, i32 -343485551], align 16
@MD5_S = internal constant [64 x i32] [i32 7, i32 12, i32 17, i32 22, i32 7, i32 12, i32 17, i32 22, i32 7, i32 12, i32 17, i32 22, i32 7, i32 12, i32 17, i32 22, i32 5, i32 9, i32 14, i32 20, i32 5, i32 9, i32 14, i32 20, i32 5, i32 9, i32 14, i32 20, i32 5, i32 9, i32 14, i32 20, i32 4, i32 11, i32 16, i32 23, i32 4, i32 11, i32 16, i32 23, i32 4, i32 11, i32 16, i32 23, i32 4, i32 11, i32 16, i32 23, i32 6, i32 10, i32 15, i32 21, i32 6, i32 10, i32 15, i32 21, i32 6, i32 10, i32 15, i32 21, i32 6, i32 10, i32 15, i32 21], align 16
@.str.69 = private unnamed_addr constant [47 x i8] c"[md5 trace] state before: %08x %08x %08x %08x\0A\00", align 1
@.str.70 = private unnamed_addr constant [47 x i8] c"[md5 trace] state after : %08x %08x %08x %08x\0A\00", align 1
@.str.71 = private unnamed_addr constant [25 x i8] c"\0A[md5 trace] block #%lu\0A\00", align 1
@.str.72 = private unnamed_addr constant [24 x i8] c"[md5 trace] raw bytes:\0A\00", align 1
@.str.73 = private unnamed_addr constant [3 x i8] c"  \00", align 1
@.str.74 = private unnamed_addr constant [5 x i8] c"%02x\00", align 1
@.str.75 = private unnamed_addr constant [34 x i8] c"[md5 trace] little-endian words:\0A\00", align 1
@.str.76 = private unnamed_addr constant [13 x i8] c"M[%02d]=%08x\00", align 1
@.str.77 = private unnamed_addr constant [75 x i8] c"  r=%02u  a=%08x b=%08x c=%08x d=%08x  f=%08x  g=%02u  m=%08x  new_b=%08x\0A\00", align 1
@.str.78 = private unnamed_addr constant [35 x i8] c"md5_finalize received NULL context\00", align 1
@.str.79 = private unnamed_addr constant [34 x i8] c"md5_finalize received NULL digest\00", align 1
@.str.80 = private unnamed_addr constant [26 x i8] c"md5_finalize called twice\00", align 1
@digest_to_hex.lower_table = internal constant [17 x i8] c"0123456789abcdef\00", align 16
@digest_to_hex.upper_table = internal constant [17 x i8] c"0123456789ABCDEF\00", align 16
@.str.81 = private unnamed_addr constant [23 x i8] c"error: null input job\0A\00", align 1
@stdin = external global ptr, align 8
@.str.82 = private unnamed_addr constant [27 x i8] c"error: unknown input kind\0A\00", align 1
@.str.83 = private unnamed_addr constant [27 x i8] c"error: null stream for %s\0A\00", align 1
@.str.84 = private unnamed_addr constant [10 x i8] c"(unknown)\00", align 1
@.str.85 = private unnamed_addr constant [30 x i8] c"error: failed reading %s: %s\0A\00", align 1
@.str.86 = private unnamed_addr constant [9 x i8] c"(stream)\00", align 1
@.str.87 = private unnamed_addr constant [24 x i8] c"error: empty file path\0A\00", align 1
@.str.88 = private unnamed_addr constant [3 x i8] c"rb\00", align 1
@.str.89 = private unnamed_addr constant [29 x i8] c"error: cannot open '%s': %s\0A\00", align 1
@.str.90 = private unnamed_addr constant [30 x i8] c"error: cannot close '%s': %s\0A\00", align 1
@stdout = external global ptr, align 8
@.str.91 = private unnamed_addr constant [8 x i8] c"%s  %s\0A\00", align 1
@.str.92 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca %struct.ProgramOptions, align 8
  %7 = alloca i32, align 4
  store i32 0, ptr %3, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  %8 = load i32, ptr %4, align 4
  %9 = load ptr, ptr %5, align 8
  call void @parse_arguments(i32 noundef %8, ptr noundef %9, ptr noundef %6)
  %10 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %6, i32 0, i32 5
  %11 = load i32, ptr %10, align 4
  %12 = icmp ne i32 %11, 0
  br i1 %12, label %13, label %25

13:                                               ; preds = %2
  %14 = load ptr, ptr %5, align 8
  %15 = getelementptr inbounds ptr, ptr %14, i64 0
  %16 = load ptr, ptr %15, align 8
  %17 = icmp ne ptr %16, null
  br i1 %17, label %18, label %22

18:                                               ; preds = %13
  %19 = load ptr, ptr %5, align 8
  %20 = getelementptr inbounds ptr, ptr %19, i64 0
  %21 = load ptr, ptr %20, align 8
  br label %23

22:                                               ; preds = %13
  br label %23

23:                                               ; preds = %22, %18
  %24 = phi ptr [ %21, %18 ], [ @.str, %22 ]
  call void @print_usage(ptr noundef %24)
  call void @options_free(ptr noundef %6)
  store i32 0, ptr %3, align 4
  br label %32

25:                                               ; preds = %2
  %26 = call i32 @validate_options(ptr noundef %6)
  %27 = icmp ne i32 %26, 0
  br i1 %27, label %28, label %29

28:                                               ; preds = %25
  call void @options_free(ptr noundef %6)
  store i32 1, ptr %3, align 4
  br label %32

29:                                               ; preds = %25
  %30 = call i32 @run_program(ptr noundef %6)
  store i32 %30, ptr %7, align 4
  call void @options_free(ptr noundef %6)
  %31 = load i32, ptr %7, align 4
  store i32 %31, ptr %3, align 4
  br label %32

32:                                               ; preds = %29, %28, %23
  %33 = load i32, ptr %3, align 4
  ret i32 %33
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @parse_arguments(i32 noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca ptr, align 8
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %13 = load ptr, ptr %6, align 8
  call void @options_init(ptr noundef %13)
  store i32 1, ptr %7, align 4
  br label %14

14:                                               ; preds = %147, %3
  %15 = load i32, ptr %7, align 4
  %16 = load i32, ptr %4, align 4
  %17 = icmp slt i32 %15, %16
  br i1 %17, label %18, label %150

18:                                               ; preds = %14
  %19 = load ptr, ptr %5, align 8
  %20 = load i32, ptr %7, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds ptr, ptr %19, i64 %21
  %23 = load ptr, ptr %22, align 8
  store ptr %23, ptr %8, align 8
  %24 = load ptr, ptr %8, align 8
  %25 = call i32 @string_equals(ptr noundef %24, ptr noundef @.str.1)
  %26 = icmp ne i32 %25, 0
  br i1 %26, label %31, label %27

27:                                               ; preds = %18
  %28 = load ptr, ptr %8, align 8
  %29 = call i32 @string_equals(ptr noundef %28, ptr noundef @.str.2)
  %30 = icmp ne i32 %29, 0
  br i1 %30, label %31, label %34

31:                                               ; preds = %27, %18
  %32 = load ptr, ptr %6, align 8
  %33 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %32, i32 0, i32 5
  store i32 1, ptr %33, align 4
  br label %146

34:                                               ; preds = %27
  %35 = load ptr, ptr %8, align 8
  %36 = call i32 @string_equals(ptr noundef %35, ptr noundef @.str.3)
  %37 = icmp ne i32 %36, 0
  br i1 %37, label %38, label %41

38:                                               ; preds = %34
  %39 = load ptr, ptr %6, align 8
  %40 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %39, i32 0, i32 0
  store i32 1, ptr %40, align 8
  br label %145

41:                                               ; preds = %34
  %42 = load ptr, ptr %8, align 8
  %43 = call i32 @string_equals(ptr noundef %42, ptr noundef @.str.4)
  %44 = icmp ne i32 %43, 0
  br i1 %44, label %45, label %48

45:                                               ; preds = %41
  %46 = load ptr, ptr %6, align 8
  %47 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %46, i32 0, i32 1
  store i32 1, ptr %47, align 4
  br label %144

48:                                               ; preds = %41
  %49 = load ptr, ptr %8, align 8
  %50 = call i32 @string_equals(ptr noundef %49, ptr noundef @.str.5)
  %51 = icmp ne i32 %50, 0
  br i1 %51, label %52, label %55

52:                                               ; preds = %48
  %53 = load ptr, ptr %6, align 8
  %54 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %53, i32 0, i32 2
  store i32 1, ptr %54, align 8
  br label %143

55:                                               ; preds = %48
  %56 = load ptr, ptr %8, align 8
  %57 = call i32 @string_equals(ptr noundef %56, ptr noundef @.str.6)
  %58 = icmp ne i32 %57, 0
  br i1 %58, label %63, label %59

59:                                               ; preds = %55
  %60 = load ptr, ptr %8, align 8
  %61 = call i32 @string_equals(ptr noundef %60, ptr noundef @.str.7)
  %62 = icmp ne i32 %61, 0
  br i1 %62, label %63, label %66

63:                                               ; preds = %59, %55
  %64 = load ptr, ptr %6, align 8
  %65 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %64, i32 0, i32 3
  store i32 1, ptr %65, align 4
  br label %142

66:                                               ; preds = %59
  %67 = load ptr, ptr %8, align 8
  %68 = call i32 @string_equals(ptr noundef %67, ptr noundef @.str.8)
  %69 = icmp ne i32 %68, 0
  br i1 %69, label %70, label %73

70:                                               ; preds = %66
  %71 = load ptr, ptr %6, align 8
  %72 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %71, i32 0, i32 4
  store i32 1, ptr %72, align 8
  br label %141

73:                                               ; preds = %66
  %74 = load ptr, ptr %8, align 8
  %75 = call i32 @string_equals(ptr noundef %74, ptr noundef @.str.9)
  %76 = icmp ne i32 %75, 0
  br i1 %76, label %77, label %79

77:                                               ; preds = %73
  %78 = load ptr, ptr %6, align 8
  call void @options_add_job(ptr noundef %78, i32 noundef 1, ptr noundef null, ptr noundef @.str.10)
  br label %140

79:                                               ; preds = %73
  %80 = load ptr, ptr %8, align 8
  %81 = call i32 @string_equals(ptr noundef %80, ptr noundef @.str.11)
  %82 = icmp ne i32 %81, 0
  br i1 %82, label %87, label %83

83:                                               ; preds = %79
  %84 = load ptr, ptr %8, align 8
  %85 = call i32 @string_equals(ptr noundef %84, ptr noundef @.str.12)
  %86 = icmp ne i32 %85, 0
  br i1 %86, label %87, label %102

87:                                               ; preds = %83, %79
  %88 = load i32, ptr %4, align 4
  %89 = load ptr, ptr %5, align 8
  %90 = load i32, ptr %7, align 4
  %91 = load ptr, ptr %8, align 8
  %92 = call i32 @require_next_arg(i32 noundef %88, ptr noundef %89, i32 noundef %90, ptr noundef %91)
  store i32 %92, ptr %9, align 4
  %93 = load ptr, ptr %5, align 8
  %94 = load i32, ptr %9, align 4
  %95 = sext i32 %94 to i64
  %96 = getelementptr inbounds ptr, ptr %93, i64 %95
  %97 = load ptr, ptr %96, align 8
  store ptr %97, ptr %10, align 8
  %98 = load ptr, ptr %6, align 8
  %99 = load ptr, ptr %10, align 8
  %100 = load ptr, ptr %10, align 8
  call void @options_add_job(ptr noundef %98, i32 noundef 2, ptr noundef %99, ptr noundef %100)
  %101 = load i32, ptr %9, align 4
  store i32 %101, ptr %7, align 4
  br label %139

102:                                              ; preds = %83
  %103 = load ptr, ptr %8, align 8
  %104 = call i32 @string_equals(ptr noundef %103, ptr noundef @.str.13)
  %105 = icmp ne i32 %104, 0
  br i1 %105, label %110, label %106

106:                                              ; preds = %102
  %107 = load ptr, ptr %8, align 8
  %108 = call i32 @string_equals(ptr noundef %107, ptr noundef @.str.14)
  %109 = icmp ne i32 %108, 0
  br i1 %109, label %110, label %125

110:                                              ; preds = %106, %102
  %111 = load i32, ptr %4, align 4
  %112 = load ptr, ptr %5, align 8
  %113 = load i32, ptr %7, align 4
  %114 = load ptr, ptr %8, align 8
  %115 = call i32 @require_next_arg(i32 noundef %111, ptr noundef %112, i32 noundef %113, ptr noundef %114)
  store i32 %115, ptr %11, align 4
  %116 = load ptr, ptr %5, align 8
  %117 = load i32, ptr %11, align 4
  %118 = sext i32 %117 to i64
  %119 = getelementptr inbounds ptr, ptr %116, i64 %118
  %120 = load ptr, ptr %119, align 8
  store ptr %120, ptr %12, align 8
  %121 = load ptr, ptr %6, align 8
  %122 = load ptr, ptr %12, align 8
  %123 = load ptr, ptr %12, align 8
  call void @options_add_job(ptr noundef %121, i32 noundef 3, ptr noundef %122, ptr noundef %123)
  %124 = load i32, ptr %11, align 4
  store i32 %124, ptr %7, align 4
  br label %138

125:                                              ; preds = %106
  %126 = load ptr, ptr %8, align 8
  %127 = call i32 @string_starts_with_dash(ptr noundef %126)
  %128 = icmp ne i32 %127, 0
  br i1 %128, label %129, label %133

129:                                              ; preds = %125
  %130 = load ptr, ptr @stderr, align 8
  %131 = load ptr, ptr %8, align 8
  %132 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %130, ptr noundef @.str.15, ptr noundef %131) #9
  call void @exit(i32 noundef 1) #10
  unreachable

133:                                              ; preds = %125
  %134 = load ptr, ptr %6, align 8
  %135 = load ptr, ptr %8, align 8
  %136 = load ptr, ptr %8, align 8
  call void @options_add_job(ptr noundef %134, i32 noundef 2, ptr noundef %135, ptr noundef %136)
  br label %137

137:                                              ; preds = %133
  br label %138

138:                                              ; preds = %137, %110
  br label %139

139:                                              ; preds = %138, %87
  br label %140

140:                                              ; preds = %139, %77
  br label %141

141:                                              ; preds = %140, %70
  br label %142

142:                                              ; preds = %141, %63
  br label %143

143:                                              ; preds = %142, %52
  br label %144

144:                                              ; preds = %143, %45
  br label %145

145:                                              ; preds = %144, %38
  br label %146

146:                                              ; preds = %145, %31
  br label %147

147:                                              ; preds = %146
  %148 = load i32, ptr %7, align 4
  %149 = add nsw i32 %148, 1
  store i32 %149, ptr %7, align 4
  br label %14, !llvm.loop !6

150:                                              ; preds = %14
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @print_usage(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = call i32 (ptr, ...) @printf(ptr noundef @.str.22)
  %4 = load ptr, ptr %2, align 8
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.23, ptr noundef %4)
  %6 = load ptr, ptr %2, align 8
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.24, ptr noundef %6)
  %8 = load ptr, ptr %2, align 8
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.25, ptr noundef %8)
  %10 = load ptr, ptr %2, align 8
  %11 = call i32 (ptr, ...) @printf(ptr noundef @.str.26, ptr noundef %10)
  %12 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %13 = call i32 (ptr, ...) @printf(ptr noundef @.str.28)
  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str.29)
  %15 = call i32 (ptr, ...) @printf(ptr noundef @.str.30)
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.31)
  %17 = call i32 (ptr, ...) @printf(ptr noundef @.str.32)
  %18 = call i32 (ptr, ...) @printf(ptr noundef @.str.33)
  %19 = call i32 (ptr, ...) @printf(ptr noundef @.str.34)
  %20 = call i32 (ptr, ...) @printf(ptr noundef @.str.35)
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.36)
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.37)
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.38)
  %25 = load ptr, ptr %2, align 8
  %26 = call i32 (ptr, ...) @printf(ptr noundef @.str.39, ptr noundef %25)
  %27 = load ptr, ptr %2, align 8
  %28 = call i32 (ptr, ...) @printf(ptr noundef @.str.40, ptr noundef %27)
  %29 = load ptr, ptr %2, align 8
  %30 = call i32 (ptr, ...) @printf(ptr noundef @.str.41, ptr noundef %29)
  %31 = load ptr, ptr %2, align 8
  %32 = call i32 (ptr, ...) @printf(ptr noundef @.str.42, ptr noundef %31)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @options_free(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i64, align 8
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = icmp eq ptr %4, null
  br i1 %5, label %6, label %7

6:                                                ; preds = %1
  br label %25

7:                                                ; preds = %1
  store i64 0, ptr %3, align 8
  br label %8

8:                                                ; preds = %19, %7
  %9 = load i64, ptr %3, align 8
  %10 = load ptr, ptr %2, align 8
  %11 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %10, i32 0, i32 7
  %12 = load i64, ptr %11, align 8
  %13 = icmp ult i64 %9, %12
  br i1 %13, label %14, label %22

14:                                               ; preds = %8
  %15 = load ptr, ptr %2, align 8
  %16 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %15, i32 0, i32 6
  %17 = load i64, ptr %3, align 8
  %18 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %16, i64 0, i64 %17
  call void @free_input_job(ptr noundef %18)
  br label %19

19:                                               ; preds = %14
  %20 = load i64, ptr %3, align 8
  %21 = add i64 %20, 1
  store i64 %21, ptr %3, align 8
  br label %8, !llvm.loop !8

22:                                               ; preds = %8
  %23 = load ptr, ptr %2, align 8
  %24 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %23, i32 0, i32 7
  store i64 0, ptr %24, align 8
  br label %25

25:                                               ; preds = %22, %6
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @validate_options(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  %4 = load ptr, ptr %3, align 8
  %5 = icmp eq ptr %4, null
  br i1 %5, label %6, label %9

6:                                                ; preds = %1
  %7 = load ptr, ptr @stderr, align 8
  %8 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %7, ptr noundef @.str.43) #9
  store i32 1, ptr %2, align 4
  br label %36

9:                                                ; preds = %1
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %10, i32 0, i32 2
  %12 = load i32, ptr %11, align 8
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %14, label %22

14:                                               ; preds = %9
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %15, i32 0, i32 7
  %17 = load i64, ptr %16, align 8
  %18 = icmp ugt i64 %17, 1
  br i1 %18, label %19, label %22

19:                                               ; preds = %14
  %20 = load ptr, ptr @stderr, align 8
  %21 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %20, ptr noundef @.str.44) #9
  store i32 1, ptr %2, align 4
  br label %36

22:                                               ; preds = %14, %9
  %23 = load ptr, ptr %3, align 8
  %24 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %23, i32 0, i32 2
  %25 = load i32, ptr %24, align 8
  %26 = icmp ne i32 %25, 0
  br i1 %26, label %27, label %35

27:                                               ; preds = %22
  %28 = load ptr, ptr %3, align 8
  %29 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %28, i32 0, i32 4
  %30 = load i32, ptr %29, align 8
  %31 = icmp ne i32 %30, 0
  br i1 %31, label %32, label %35

32:                                               ; preds = %27
  %33 = load ptr, ptr @stderr, align 8
  %34 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %33, ptr noundef @.str.45) #9
  store i32 1, ptr %2, align 4
  br label %36

35:                                               ; preds = %27, %22
  store i32 0, ptr %2, align 4
  br label %36

36:                                               ; preds = %35, %32, %19, %6
  %37 = load i32, ptr %2, align 4
  ret i32 %37
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @run_program(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca %struct.DigestFormatter, align 4
  %5 = alloca i64, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca %struct.InputJob, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 0, ptr %6, align 4
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %11, i32 0, i32 1
  %13 = load i32, ptr %12, align 4
  %14 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %4, i32 0, i32 0
  store i32 %13, ptr %14, align 4
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %15, i32 0, i32 2
  %17 = load i32, ptr %16, align 8
  %18 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %4, i32 0, i32 1
  store i32 %17, ptr %18, align 4
  %19 = load ptr, ptr %3, align 8
  %20 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %19, i32 0, i32 4
  %21 = load i32, ptr %20, align 8
  %22 = icmp ne i32 %21, 0
  br i1 %22, label %23, label %36

23:                                               ; preds = %1
  %24 = load ptr, ptr %3, align 8
  %25 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %24, i32 0, i32 3
  %26 = load i32, ptr %25, align 4
  %27 = load ptr, ptr %3, align 8
  %28 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %27, i32 0, i32 0
  %29 = load i32, ptr %28, align 8
  %30 = call i32 @run_self_tests(i32 noundef %26, i32 noundef %29)
  store i32 %30, ptr %7, align 4
  %31 = load i32, ptr %7, align 4
  %32 = icmp ne i32 %31, 0
  br i1 %32, label %33, label %35

33:                                               ; preds = %23
  %34 = load i32, ptr %7, align 4
  store i32 %34, ptr %6, align 4
  br label %35

35:                                               ; preds = %33, %23
  br label %36

36:                                               ; preds = %35, %1
  %37 = load ptr, ptr %3, align 8
  %38 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %37, i32 0, i32 7
  %39 = load i64, ptr %38, align 8
  %40 = icmp eq i64 %39, 0
  br i1 %40, label %41, label %55

41:                                               ; preds = %36
  %42 = load ptr, ptr %3, align 8
  %43 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %42, i32 0, i32 4
  %44 = load i32, ptr %43, align 8
  %45 = icmp ne i32 %44, 0
  br i1 %45, label %55, label %46

46:                                               ; preds = %41
  %47 = load ptr, ptr %3, align 8
  %48 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %47, i32 0, i32 5
  %49 = load i32, ptr %48, align 4
  %50 = icmp ne i32 %49, 0
  br i1 %50, label %55, label %51

51:                                               ; preds = %46
  call void @make_input_job(ptr dead_on_unwind writable sret(%struct.InputJob) align 8 %8, i32 noundef 1, ptr noundef null, ptr noundef null)
  %52 = load ptr, ptr %3, align 8
  %53 = call i32 @execute_job(ptr noundef %8, ptr noundef %52, ptr noundef %4)
  store i32 %53, ptr %9, align 4
  call void @free_input_job(ptr noundef %8)
  %54 = load i32, ptr %9, align 4
  store i32 %54, ptr %2, align 4
  br label %79

55:                                               ; preds = %46, %41, %36
  store i64 0, ptr %5, align 8
  br label %56

56:                                               ; preds = %74, %55
  %57 = load i64, ptr %5, align 8
  %58 = load ptr, ptr %3, align 8
  %59 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %58, i32 0, i32 7
  %60 = load i64, ptr %59, align 8
  %61 = icmp ult i64 %57, %60
  br i1 %61, label %62, label %77

62:                                               ; preds = %56
  %63 = load ptr, ptr %3, align 8
  %64 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %63, i32 0, i32 6
  %65 = load i64, ptr %5, align 8
  %66 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %64, i64 0, i64 %65
  %67 = load ptr, ptr %3, align 8
  %68 = call i32 @execute_job(ptr noundef %66, ptr noundef %67, ptr noundef %4)
  store i32 %68, ptr %10, align 4
  %69 = load i32, ptr %10, align 4
  %70 = icmp ne i32 %69, 0
  br i1 %70, label %71, label %73

71:                                               ; preds = %62
  %72 = load i32, ptr %10, align 4
  store i32 %72, ptr %6, align 4
  br label %73

73:                                               ; preds = %71, %62
  br label %74

74:                                               ; preds = %73
  %75 = load i64, ptr %5, align 8
  %76 = add i64 %75, 1
  store i64 %76, ptr %5, align 8
  br label %56, !llvm.loop !9

77:                                               ; preds = %56
  %78 = load i32, ptr %6, align 4
  store i32 %78, ptr %2, align 4
  br label %79

79:                                               ; preds = %77, %51
  %80 = load i32, ptr %2, align 4
  ret i32 %80
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @run_self_tests(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i64, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  %8 = alloca [16 x i8], align 16
  %9 = alloca [33 x i8], align 16
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i64 0, ptr %6, align 8
  store i64 7, ptr %7, align 8
  store i64 0, ptr %5, align 8
  br label %12

12:                                               ; preds = %54, %2
  %13 = load i64, ptr %5, align 8
  %14 = load i64, ptr %7, align 8
  %15 = icmp ult i64 %13, %14
  br i1 %15, label %16, label %57

16:                                               ; preds = %12
  %17 = load i64, ptr %5, align 8
  %18 = getelementptr inbounds nuw [7 x %struct.TestVector], ptr @SELF_TESTS, i64 0, i64 %17
  %19 = getelementptr inbounds nuw %struct.TestVector, ptr %18, i32 0, i32 0
  %20 = load ptr, ptr %19, align 16
  store ptr %20, ptr %10, align 8
  %21 = load i64, ptr %5, align 8
  %22 = getelementptr inbounds nuw [7 x %struct.TestVector], ptr @SELF_TESTS, i64 0, i64 %21
  %23 = getelementptr inbounds nuw %struct.TestVector, ptr %22, i32 0, i32 1
  %24 = load ptr, ptr %23, align 8
  store ptr %24, ptr %11, align 8
  %25 = load ptr, ptr %10, align 8
  %26 = load ptr, ptr %10, align 8
  %27 = call i64 @strlen(ptr noundef %26) #11
  %28 = getelementptr inbounds [16 x i8], ptr %8, i64 0, i64 0
  %29 = load i32, ptr %4, align 4
  call void @md5_hash_memory(ptr noundef %25, i64 noundef %27, ptr noundef %28, i32 noundef %29)
  %30 = getelementptr inbounds [16 x i8], ptr %8, i64 0, i64 0
  %31 = getelementptr inbounds [33 x i8], ptr %9, i64 0, i64 0
  call void @digest_to_hex(ptr noundef %30, ptr noundef %31, i32 noundef 0)
  %32 = getelementptr inbounds [33 x i8], ptr %9, i64 0, i64 0
  %33 = load ptr, ptr %11, align 8
  %34 = call i32 @strcmp(ptr noundef %32, ptr noundef %33) #11
  %35 = icmp eq i32 %34, 0
  br i1 %35, label %36, label %46

36:                                               ; preds = %16
  %37 = load i64, ptr %6, align 8
  %38 = add i64 %37, 1
  store i64 %38, ptr %6, align 8
  %39 = load i32, ptr %3, align 4
  %40 = icmp ne i32 %39, 0
  br i1 %40, label %45, label %41

41:                                               ; preds = %36
  %42 = load ptr, ptr %10, align 8
  %43 = getelementptr inbounds [33 x i8], ptr %9, i64 0, i64 0
  %44 = call i32 (ptr, ...) @printf(ptr noundef @.str.46, ptr noundef %42, ptr noundef %43)
  br label %45

45:                                               ; preds = %41, %36
  br label %53

46:                                               ; preds = %16
  %47 = load ptr, ptr %10, align 8
  %48 = call i32 (ptr, ...) @printf(ptr noundef @.str.47, ptr noundef %47)
  %49 = load ptr, ptr %11, align 8
  %50 = call i32 (ptr, ...) @printf(ptr noundef @.str.48, ptr noundef %49)
  %51 = getelementptr inbounds [33 x i8], ptr %9, i64 0, i64 0
  %52 = call i32 (ptr, ...) @printf(ptr noundef @.str.49, ptr noundef %51)
  br label %53

53:                                               ; preds = %46, %45
  br label %54

54:                                               ; preds = %53
  %55 = load i64, ptr %5, align 8
  %56 = add i64 %55, 1
  store i64 %56, ptr %5, align 8
  br label %12, !llvm.loop !10

57:                                               ; preds = %12
  %58 = load i32, ptr %3, align 4
  %59 = icmp ne i32 %58, 0
  br i1 %59, label %60, label %64

60:                                               ; preds = %57
  %61 = load i64, ptr %6, align 8
  %62 = load i64, ptr %7, align 8
  %63 = icmp ne i64 %61, %62
  br i1 %63, label %64, label %68

64:                                               ; preds = %60, %57
  %65 = load i64, ptr %6, align 8
  %66 = load i64, ptr %7, align 8
  %67 = call i32 (ptr, ...) @printf(ptr noundef @.str.50, i64 noundef %65, i64 noundef %66)
  br label %68

68:                                               ; preds = %64, %60
  %69 = load i64, ptr %6, align 8
  %70 = load i64, ptr %7, align 8
  %71 = icmp eq i64 %69, %70
  %72 = zext i1 %71 to i64
  %73 = select i1 %71, i32 0, i32 1
  ret i32 %73
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @make_input_job(ptr dead_on_unwind noalias writable sret(%struct.InputJob) align 8 %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store i32 %1, ptr %5, align 4
  store ptr %2, ptr %6, align 8
  store ptr %3, ptr %7, align 8
  %8 = load i32, ptr %5, align 4
  %9 = getelementptr inbounds nuw %struct.InputJob, ptr %0, i32 0, i32 0
  store i32 %8, ptr %9, align 8
  %10 = load ptr, ptr %6, align 8
  %11 = call ptr @duplicate_string(ptr noundef %10)
  %12 = getelementptr inbounds nuw %struct.InputJob, ptr %0, i32 0, i32 1
  store ptr %11, ptr %12, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = call ptr @duplicate_string(ptr noundef %13)
  %15 = getelementptr inbounds nuw %struct.InputJob, ptr %0, i32 0, i32 2
  store ptr %14, ptr %15, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @execute_job(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca [16 x i8], align 16
  %9 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store i32 0, ptr %9, align 4
  %10 = load ptr, ptr %5, align 8
  %11 = icmp eq ptr %10, null
  br i1 %11, label %12, label %15

12:                                               ; preds = %3
  %13 = load ptr, ptr @stderr, align 8
  %14 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %13, ptr noundef @.str.81) #9
  store i32 1, ptr %4, align 4
  br label %62

15:                                               ; preds = %3
  %16 = load ptr, ptr %5, align 8
  %17 = getelementptr inbounds nuw %struct.InputJob, ptr %16, i32 0, i32 0
  %18 = load i32, ptr %17, align 8
  switch i32 %18, label %47 [
    i32 1, label %19
    i32 2, label %26
    i32 3, label %38
  ]

19:                                               ; preds = %15
  %20 = load ptr, ptr @stdin, align 8
  %21 = getelementptr inbounds [16 x i8], ptr %8, i64 0, i64 0
  %22 = load ptr, ptr %6, align 8
  %23 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %22, i32 0, i32 0
  %24 = load i32, ptr %23, align 8
  %25 = call i32 @hash_stream(ptr noundef %20, ptr noundef @.str.10, ptr noundef %21, i32 noundef %24)
  store i32 %25, ptr %9, align 4
  br label %50

26:                                               ; preds = %15
  %27 = load ptr, ptr %5, align 8
  %28 = getelementptr inbounds nuw %struct.InputJob, ptr %27, i32 0, i32 1
  %29 = load ptr, ptr %28, align 8
  %30 = load ptr, ptr %5, align 8
  %31 = getelementptr inbounds nuw %struct.InputJob, ptr %30, i32 0, i32 1
  %32 = load ptr, ptr %31, align 8
  %33 = call i64 @strlen(ptr noundef %32) #11
  %34 = getelementptr inbounds [16 x i8], ptr %8, i64 0, i64 0
  %35 = load ptr, ptr %6, align 8
  %36 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %35, i32 0, i32 0
  %37 = load i32, ptr %36, align 8
  call void @md5_hash_memory(ptr noundef %29, i64 noundef %33, ptr noundef %34, i32 noundef %37)
  store i32 0, ptr %9, align 4
  br label %50

38:                                               ; preds = %15
  %39 = load ptr, ptr %5, align 8
  %40 = getelementptr inbounds nuw %struct.InputJob, ptr %39, i32 0, i32 1
  %41 = load ptr, ptr %40, align 8
  %42 = getelementptr inbounds [16 x i8], ptr %8, i64 0, i64 0
  %43 = load ptr, ptr %6, align 8
  %44 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %43, i32 0, i32 0
  %45 = load i32, ptr %44, align 8
  %46 = call i32 @hash_file_path(ptr noundef %41, ptr noundef %42, i32 noundef %45)
  store i32 %46, ptr %9, align 4
  br label %50

47:                                               ; preds = %15
  %48 = load ptr, ptr @stderr, align 8
  %49 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %48, ptr noundef @.str.82) #9
  store i32 1, ptr %4, align 4
  br label %62

50:                                               ; preds = %38, %26, %19
  %51 = load i32, ptr %9, align 4
  %52 = icmp ne i32 %51, 0
  br i1 %52, label %53, label %55

53:                                               ; preds = %50
  %54 = load i32, ptr %9, align 4
  store i32 %54, ptr %4, align 4
  br label %62

55:                                               ; preds = %50
  %56 = getelementptr inbounds [16 x i8], ptr %8, i64 0, i64 0
  %57 = load ptr, ptr %5, align 8
  %58 = getelementptr inbounds nuw %struct.InputJob, ptr %57, i32 0, i32 2
  %59 = load ptr, ptr %58, align 8
  %60 = load ptr, ptr %7, align 8
  call void @print_digest(ptr noundef %56, ptr noundef %59, ptr noundef %60)
  %61 = getelementptr inbounds [16 x i8], ptr %8, i64 0, i64 0
  call void @zero_memory(ptr noundef %61, i64 noundef 16)
  store i32 0, ptr %4, align 4
  br label %62

62:                                               ; preds = %55, %53, %47, %12
  %63 = load i32, ptr %4, align 4
  ret i32 %63
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @free_input_job(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %19

6:                                                ; preds = %1
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds nuw %struct.InputJob, ptr %7, i32 0, i32 1
  %9 = load ptr, ptr %8, align 8
  call void @free(ptr noundef %9) #9
  %10 = load ptr, ptr %2, align 8
  %11 = getelementptr inbounds nuw %struct.InputJob, ptr %10, i32 0, i32 2
  %12 = load ptr, ptr %11, align 8
  call void @free(ptr noundef %12) #9
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.InputJob, ptr %13, i32 0, i32 1
  store ptr null, ptr %14, align 8
  %15 = load ptr, ptr %2, align 8
  %16 = getelementptr inbounds nuw %struct.InputJob, ptr %15, i32 0, i32 2
  store ptr null, ptr %16, align 8
  %17 = load ptr, ptr %2, align 8
  %18 = getelementptr inbounds nuw %struct.InputJob, ptr %17, i32 0, i32 0
  store i32 0, ptr %18, align 8
  br label %19

19:                                               ; preds = %6, %5
  ret void
}

; Function Attrs: nounwind
declare void @free(ptr noundef) #1

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @hash_stream(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca %struct.MD5Context, align 8
  %11 = alloca [8192 x i8], align 16
  %12 = alloca i64, align 8
  store ptr %0, ptr %6, align 8
  store ptr %1, ptr %7, align 8
  store ptr %2, ptr %8, align 8
  store i32 %3, ptr %9, align 4
  %13 = load ptr, ptr %6, align 8
  %14 = icmp eq ptr %13, null
  br i1 %14, label %15, label %25

15:                                               ; preds = %4
  %16 = load ptr, ptr @stderr, align 8
  %17 = load ptr, ptr %7, align 8
  %18 = icmp ne ptr %17, null
  br i1 %18, label %19, label %21

19:                                               ; preds = %15
  %20 = load ptr, ptr %7, align 8
  br label %22

21:                                               ; preds = %15
  br label %22

22:                                               ; preds = %21, %19
  %23 = phi ptr [ %20, %19 ], [ @.str.84, %21 ]
  %24 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %16, ptr noundef @.str.83, ptr noundef %23) #9
  store i32 1, ptr %5, align 4
  br label %62

25:                                               ; preds = %4
  call void @md5_context_init(ptr noundef %10)
  %26 = load i32, ptr %9, align 4
  call void @md5_context_enable_trace(ptr noundef %10, i32 noundef %26)
  br label %27

27:                                               ; preds = %58, %25
  %28 = getelementptr inbounds [8192 x i8], ptr %11, i64 0, i64 0
  %29 = load ptr, ptr %6, align 8
  %30 = call i64 @fread(ptr noundef %28, i64 noundef 1, i64 noundef 8192, ptr noundef %29)
  store i64 %30, ptr %12, align 8
  %31 = load i64, ptr %12, align 8
  %32 = icmp ugt i64 %31, 0
  br i1 %32, label %33, label %36

33:                                               ; preds = %27
  %34 = getelementptr inbounds [8192 x i8], ptr %11, i64 0, i64 0
  %35 = load i64, ptr %12, align 8
  call void @md5_update_bytes(ptr noundef %10, ptr noundef %34, i64 noundef %35)
  br label %36

36:                                               ; preds = %33, %27
  %37 = load i64, ptr %12, align 8
  %38 = icmp ult i64 %37, 8192
  br i1 %38, label %39, label %58

39:                                               ; preds = %36
  %40 = load ptr, ptr %6, align 8
  %41 = call i32 @ferror(ptr noundef %40) #9
  %42 = icmp ne i32 %41, 0
  br i1 %42, label %43, label %57

43:                                               ; preds = %39
  %44 = load ptr, ptr @stderr, align 8
  %45 = load ptr, ptr %7, align 8
  %46 = icmp ne ptr %45, null
  br i1 %46, label %47, label %49

47:                                               ; preds = %43
  %48 = load ptr, ptr %7, align 8
  br label %50

49:                                               ; preds = %43
  br label %50

50:                                               ; preds = %49, %47
  %51 = phi ptr [ %48, %47 ], [ @.str.86, %49 ]
  %52 = call ptr @__errno_location() #12
  %53 = load i32, ptr %52, align 4
  %54 = call ptr @strerror(i32 noundef %53) #9
  %55 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %44, ptr noundef @.str.85, ptr noundef %51, ptr noundef %54) #9
  call void @zero_memory(ptr noundef %10, i64 noundef 112)
  %56 = getelementptr inbounds [8192 x i8], ptr %11, i64 0, i64 0
  call void @zero_memory(ptr noundef %56, i64 noundef 8192)
  store i32 1, ptr %5, align 4
  br label %62

57:                                               ; preds = %39
  br label %59

58:                                               ; preds = %36
  br label %27

59:                                               ; preds = %57
  %60 = load ptr, ptr %8, align 8
  call void @md5_finalize(ptr noundef %10, ptr noundef %60)
  call void @zero_memory(ptr noundef %10, i64 noundef 112)
  %61 = getelementptr inbounds [8192 x i8], ptr %11, i64 0, i64 0
  call void @zero_memory(ptr noundef %61, i64 noundef 8192)
  store i32 0, ptr %5, align 4
  br label %62

62:                                               ; preds = %59, %50, %22
  %63 = load i32, ptr %5, align 4
  ret i32 %63
}

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_hash_memory(ptr noundef %0, i64 noundef %1, ptr noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca %struct.MD5Context, align 8
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store i32 %3, ptr %8, align 4
  call void @md5_context_init(ptr noundef %9)
  %10 = load i32, ptr %8, align 4
  call void @md5_context_enable_trace(ptr noundef %9, i32 noundef %10)
  %11 = load ptr, ptr %5, align 8
  %12 = load i64, ptr %6, align 8
  call void @md5_update_bytes(ptr noundef %9, ptr noundef %11, i64 noundef %12)
  %13 = load ptr, ptr %7, align 8
  call void @md5_finalize(ptr noundef %9, ptr noundef %13)
  call void @zero_memory(ptr noundef %9, i64 noundef 112)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @hash_file_path(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store i32 %2, ptr %7, align 4
  %10 = load ptr, ptr %5, align 8
  %11 = icmp eq ptr %10, null
  br i1 %11, label %18, label %12

12:                                               ; preds = %3
  %13 = load ptr, ptr %5, align 8
  %14 = getelementptr inbounds i8, ptr %13, i64 0
  %15 = load i8, ptr %14, align 1
  %16 = sext i8 %15 to i32
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %21

18:                                               ; preds = %12, %3
  %19 = load ptr, ptr @stderr, align 8
  %20 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %19, ptr noundef @.str.87) #9
  store i32 1, ptr %4, align 4
  br label %51

21:                                               ; preds = %12
  %22 = load ptr, ptr %5, align 8
  %23 = call noalias ptr @fopen(ptr noundef %22, ptr noundef @.str.88)
  store ptr %23, ptr %8, align 8
  %24 = load ptr, ptr %8, align 8
  %25 = icmp eq ptr %24, null
  br i1 %25, label %26, label %33

26:                                               ; preds = %21
  %27 = load ptr, ptr @stderr, align 8
  %28 = load ptr, ptr %5, align 8
  %29 = call ptr @__errno_location() #12
  %30 = load i32, ptr %29, align 4
  %31 = call ptr @strerror(i32 noundef %30) #9
  %32 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %27, ptr noundef @.str.89, ptr noundef %28, ptr noundef %31) #9
  store i32 1, ptr %4, align 4
  br label %51

33:                                               ; preds = %21
  %34 = load ptr, ptr %8, align 8
  %35 = load ptr, ptr %5, align 8
  %36 = load ptr, ptr %6, align 8
  %37 = load i32, ptr %7, align 4
  %38 = call i32 @hash_stream(ptr noundef %34, ptr noundef %35, ptr noundef %36, i32 noundef %37)
  store i32 %38, ptr %9, align 4
  %39 = load ptr, ptr %8, align 8
  %40 = call i32 @fclose(ptr noundef %39)
  %41 = icmp ne i32 %40, 0
  br i1 %41, label %42, label %49

42:                                               ; preds = %33
  %43 = load ptr, ptr @stderr, align 8
  %44 = load ptr, ptr %5, align 8
  %45 = call ptr @__errno_location() #12
  %46 = load i32, ptr %45, align 4
  %47 = call ptr @strerror(i32 noundef %46) #9
  %48 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %43, ptr noundef @.str.90, ptr noundef %44, ptr noundef %47) #9
  store i32 1, ptr %4, align 4
  br label %51

49:                                               ; preds = %33
  %50 = load i32, ptr %9, align 4
  store i32 %50, ptr %4, align 4
  br label %51

51:                                               ; preds = %49, %42, %26, %18
  %52 = load i32, ptr %4, align 4
  ret i32 %52
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @print_digest(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca [33 x i8], align 16
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %8 = load ptr, ptr %6, align 8
  %9 = icmp ne ptr %8, null
  br i1 %9, label %10, label %19

10:                                               ; preds = %3
  %11 = load ptr, ptr %6, align 8
  %12 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %11, i32 0, i32 1
  %13 = load i32, ptr %12, align 4
  %14 = icmp ne i32 %13, 0
  br i1 %14, label %15, label %19

15:                                               ; preds = %10
  %16 = load ptr, ptr %4, align 8
  %17 = load ptr, ptr @stdout, align 8
  %18 = call i64 @fwrite(ptr noundef %16, i64 noundef 1, i64 noundef 16, ptr noundef %17)
  br label %46

19:                                               ; preds = %10, %3
  %20 = load ptr, ptr %4, align 8
  %21 = getelementptr inbounds [33 x i8], ptr %7, i64 0, i64 0
  %22 = load ptr, ptr %6, align 8
  %23 = icmp ne ptr %22, null
  br i1 %23, label %24, label %28

24:                                               ; preds = %19
  %25 = load ptr, ptr %6, align 8
  %26 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %25, i32 0, i32 0
  %27 = load i32, ptr %26, align 4
  br label %29

28:                                               ; preds = %19
  br label %29

29:                                               ; preds = %28, %24
  %30 = phi i32 [ %27, %24 ], [ 0, %28 ]
  call void @digest_to_hex(ptr noundef %20, ptr noundef %21, i32 noundef %30)
  %31 = load ptr, ptr %5, align 8
  %32 = icmp ne ptr %31, null
  br i1 %32, label %33, label %43

33:                                               ; preds = %29
  %34 = load ptr, ptr %5, align 8
  %35 = getelementptr inbounds i8, ptr %34, i64 0
  %36 = load i8, ptr %35, align 1
  %37 = sext i8 %36 to i32
  %38 = icmp ne i32 %37, 0
  br i1 %38, label %39, label %43

39:                                               ; preds = %33
  %40 = getelementptr inbounds [33 x i8], ptr %7, i64 0, i64 0
  %41 = load ptr, ptr %5, align 8
  %42 = call i32 (ptr, ...) @printf(ptr noundef @.str.91, ptr noundef %40, ptr noundef %41)
  br label %46

43:                                               ; preds = %33, %29
  %44 = getelementptr inbounds [33 x i8], ptr %7, i64 0, i64 0
  %45 = call i32 (ptr, ...) @printf(ptr noundef @.str.92, ptr noundef %44)
  br label %46

46:                                               ; preds = %15, %43, %39
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @zero_memory(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  %6 = load ptr, ptr %3, align 8
  store ptr %6, ptr %5, align 8
  br label %7

7:                                                ; preds = %10, %2
  %8 = load i64, ptr %4, align 8
  %9 = icmp ugt i64 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %7
  %11 = load ptr, ptr %5, align 8
  %12 = getelementptr inbounds nuw i8, ptr %11, i32 1
  store ptr %12, ptr %5, align 8
  store volatile i8 0, ptr %11, align 1
  %13 = load i64, ptr %4, align 8
  %14 = add i64 %13, -1
  store i64 %14, ptr %4, align 8
  br label %7, !llvm.loop !11

15:                                               ; preds = %7
  ret void
}

declare i64 @fwrite(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define internal void @digest_to_hex(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i8, align 1
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i32 %2, ptr %6, align 4
  %10 = load i32, ptr %6, align 4
  %11 = icmp ne i32 %10, 0
  %12 = zext i1 %11 to i64
  %13 = select i1 %11, ptr @digest_to_hex.upper_table, ptr @digest_to_hex.lower_table
  store ptr %13, ptr %7, align 8
  store i32 0, ptr %8, align 4
  br label %14

14:                                               ; preds = %50, %3
  %15 = load i32, ptr %8, align 4
  %16 = icmp slt i32 %15, 16
  br i1 %16, label %17, label %53

17:                                               ; preds = %14
  %18 = load ptr, ptr %4, align 8
  %19 = load i32, ptr %8, align 4
  %20 = sext i32 %19 to i64
  %21 = getelementptr inbounds i8, ptr %18, i64 %20
  %22 = load i8, ptr %21, align 1
  store i8 %22, ptr %9, align 1
  %23 = load ptr, ptr %7, align 8
  %24 = load i8, ptr %9, align 1
  %25 = zext i8 %24 to i32
  %26 = ashr i32 %25, 4
  %27 = and i32 %26, 15
  %28 = zext i32 %27 to i64
  %29 = getelementptr inbounds nuw i8, ptr %23, i64 %28
  %30 = load i8, ptr %29, align 1
  %31 = load ptr, ptr %5, align 8
  %32 = load i32, ptr %8, align 4
  %33 = mul nsw i32 %32, 2
  %34 = add nsw i32 %33, 0
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds i8, ptr %31, i64 %35
  store i8 %30, ptr %36, align 1
  %37 = load ptr, ptr %7, align 8
  %38 = load i8, ptr %9, align 1
  %39 = zext i8 %38 to i32
  %40 = and i32 %39, 15
  %41 = zext i32 %40 to i64
  %42 = getelementptr inbounds nuw i8, ptr %37, i64 %41
  %43 = load i8, ptr %42, align 1
  %44 = load ptr, ptr %5, align 8
  %45 = load i32, ptr %8, align 4
  %46 = mul nsw i32 %45, 2
  %47 = add nsw i32 %46, 1
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds i8, ptr %44, i64 %48
  store i8 %43, ptr %49, align 1
  br label %50

50:                                               ; preds = %17
  %51 = load i32, ptr %8, align 4
  %52 = add nsw i32 %51, 1
  store i32 %52, ptr %8, align 4
  br label %14, !llvm.loop !12

53:                                               ; preds = %14
  %54 = load ptr, ptr %5, align 8
  %55 = getelementptr inbounds i8, ptr %54, i64 32
  store i8 0, ptr %55, align 1
  ret void
}

declare i32 @printf(ptr noundef, ...) #3

declare noalias ptr @fopen(ptr noundef, ptr noundef) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__errno_location() #4

; Function Attrs: nounwind
declare ptr @strerror(i32 noundef) #1

declare i32 @fclose(ptr noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_context_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  call void @die_message(ptr noundef @.str.65)
  br label %6

6:                                                ; preds = %5, %1
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds nuw %struct.MD5Context, ptr %7, i32 0, i32 0
  %9 = getelementptr inbounds [4 x i32], ptr %8, i64 0, i64 0
  store i32 1732584193, ptr %9, align 8
  %10 = load ptr, ptr %2, align 8
  %11 = getelementptr inbounds nuw %struct.MD5Context, ptr %10, i32 0, i32 0
  %12 = getelementptr inbounds [4 x i32], ptr %11, i64 0, i64 1
  store i32 -271733879, ptr %12, align 4
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.MD5Context, ptr %13, i32 0, i32 0
  %15 = getelementptr inbounds [4 x i32], ptr %14, i64 0, i64 2
  store i32 -1732584194, ptr %15, align 8
  %16 = load ptr, ptr %2, align 8
  %17 = getelementptr inbounds nuw %struct.MD5Context, ptr %16, i32 0, i32 0
  %18 = getelementptr inbounds [4 x i32], ptr %17, i64 0, i64 3
  store i32 271733878, ptr %18, align 4
  %19 = load ptr, ptr %2, align 8
  %20 = getelementptr inbounds nuw %struct.MD5Context, ptr %19, i32 0, i32 1
  store i64 0, ptr %20, align 8
  %21 = load ptr, ptr %2, align 8
  %22 = getelementptr inbounds nuw %struct.MD5Context, ptr %21, i32 0, i32 3
  store i64 0, ptr %22, align 8
  %23 = load ptr, ptr %2, align 8
  %24 = getelementptr inbounds nuw %struct.MD5Context, ptr %23, i32 0, i32 4
  store i64 0, ptr %24, align 8
  %25 = load ptr, ptr %2, align 8
  %26 = getelementptr inbounds nuw %struct.MD5Context, ptr %25, i32 0, i32 5
  store i32 0, ptr %26, align 8
  %27 = load ptr, ptr %2, align 8
  %28 = getelementptr inbounds nuw %struct.MD5Context, ptr %27, i32 0, i32 6
  store i32 0, ptr %28, align 4
  %29 = load ptr, ptr %2, align 8
  %30 = getelementptr inbounds nuw %struct.MD5Context, ptr %29, i32 0, i32 2
  %31 = getelementptr inbounds [64 x i8], ptr %30, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 8 %31, i8 0, i64 64, i1 false)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_context_enable_trace(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load ptr, ptr %3, align 8
  %6 = icmp eq ptr %5, null
  br i1 %6, label %7, label %8

7:                                                ; preds = %2
  br label %15

8:                                                ; preds = %2
  %9 = load i32, ptr %4, align 4
  %10 = icmp ne i32 %9, 0
  %11 = zext i1 %10 to i64
  %12 = select i1 %10, i32 1, i32 0
  %13 = load ptr, ptr %3, align 8
  %14 = getelementptr inbounds nuw %struct.MD5Context, ptr %13, i32 0, i32 5
  store i32 %12, ptr %14, align 8
  br label %15

15:                                               ; preds = %8, %7
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_update_bytes(ptr noundef %0, ptr noundef %1, i64 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i64, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i64 %2, ptr %6, align 8
  store i64 0, ptr %7, align 8
  %10 = load ptr, ptr %4, align 8
  %11 = icmp eq ptr %10, null
  br i1 %11, label %12, label %13

12:                                               ; preds = %3
  call void @die_message(ptr noundef @.str.66)
  br label %13

13:                                               ; preds = %12, %3
  %14 = load ptr, ptr %5, align 8
  %15 = icmp eq ptr %14, null
  br i1 %15, label %16, label %20

16:                                               ; preds = %13
  %17 = load i64, ptr %6, align 8
  %18 = icmp ne i64 %17, 0
  br i1 %18, label %19, label %20

19:                                               ; preds = %16
  call void @die_message(ptr noundef @.str.67)
  br label %20

20:                                               ; preds = %19, %16, %13
  %21 = load ptr, ptr %4, align 8
  %22 = getelementptr inbounds nuw %struct.MD5Context, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 4
  %24 = icmp ne i32 %23, 0
  br i1 %24, label %25, label %26

25:                                               ; preds = %20
  call void @die_message(ptr noundef @.str.68)
  br label %26

26:                                               ; preds = %25, %20
  %27 = load i64, ptr %6, align 8
  %28 = load ptr, ptr %4, align 8
  %29 = getelementptr inbounds nuw %struct.MD5Context, ptr %28, i32 0, i32 1
  %30 = load i64, ptr %29, align 8
  %31 = add i64 %30, %27
  store i64 %31, ptr %29, align 8
  %32 = load ptr, ptr %4, align 8
  %33 = getelementptr inbounds nuw %struct.MD5Context, ptr %32, i32 0, i32 3
  %34 = load i64, ptr %33, align 8
  %35 = icmp ugt i64 %34, 0
  br i1 %35, label %36, label %89

36:                                               ; preds = %26
  %37 = load ptr, ptr %4, align 8
  %38 = getelementptr inbounds nuw %struct.MD5Context, ptr %37, i32 0, i32 3
  %39 = load i64, ptr %38, align 8
  %40 = sub i64 64, %39
  store i64 %40, ptr %8, align 8
  %41 = load i64, ptr %6, align 8
  %42 = load i64, ptr %8, align 8
  %43 = icmp ult i64 %41, %42
  br i1 %43, label %44, label %46

44:                                               ; preds = %36
  %45 = load i64, ptr %6, align 8
  br label %48

46:                                               ; preds = %36
  %47 = load i64, ptr %8, align 8
  br label %48

48:                                               ; preds = %46, %44
  %49 = phi i64 [ %45, %44 ], [ %47, %46 ]
  store i64 %49, ptr %9, align 8
  %50 = load i64, ptr %9, align 8
  %51 = icmp ugt i64 %50, 0
  br i1 %51, label %52, label %73

52:                                               ; preds = %48
  %53 = load ptr, ptr %4, align 8
  %54 = getelementptr inbounds nuw %struct.MD5Context, ptr %53, i32 0, i32 2
  %55 = getelementptr inbounds [64 x i8], ptr %54, i64 0, i64 0
  %56 = load ptr, ptr %4, align 8
  %57 = getelementptr inbounds nuw %struct.MD5Context, ptr %56, i32 0, i32 3
  %58 = load i64, ptr %57, align 8
  %59 = getelementptr inbounds nuw i8, ptr %55, i64 %58
  %60 = load ptr, ptr %5, align 8
  %61 = load i64, ptr %9, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %59, ptr align 1 %60, i64 %61, i1 false)
  %62 = load i64, ptr %9, align 8
  %63 = load ptr, ptr %4, align 8
  %64 = getelementptr inbounds nuw %struct.MD5Context, ptr %63, i32 0, i32 3
  %65 = load i64, ptr %64, align 8
  %66 = add i64 %65, %62
  store i64 %66, ptr %64, align 8
  %67 = load i64, ptr %9, align 8
  %68 = load i64, ptr %7, align 8
  %69 = add i64 %68, %67
  store i64 %69, ptr %7, align 8
  %70 = load i64, ptr %9, align 8
  %71 = load i64, ptr %6, align 8
  %72 = sub i64 %71, %70
  store i64 %72, ptr %6, align 8
  br label %73

73:                                               ; preds = %52, %48
  %74 = load ptr, ptr %4, align 8
  %75 = getelementptr inbounds nuw %struct.MD5Context, ptr %74, i32 0, i32 3
  %76 = load i64, ptr %75, align 8
  %77 = icmp eq i64 %76, 64
  br i1 %77, label %78, label %88

78:                                               ; preds = %73
  %79 = load ptr, ptr %4, align 8
  %80 = load ptr, ptr %4, align 8
  %81 = getelementptr inbounds nuw %struct.MD5Context, ptr %80, i32 0, i32 2
  %82 = getelementptr inbounds [64 x i8], ptr %81, i64 0, i64 0
  call void @md5_transform_block(ptr noundef %79, ptr noundef %82)
  %83 = load ptr, ptr %4, align 8
  %84 = getelementptr inbounds nuw %struct.MD5Context, ptr %83, i32 0, i32 3
  store i64 0, ptr %84, align 8
  %85 = load ptr, ptr %4, align 8
  %86 = getelementptr inbounds nuw %struct.MD5Context, ptr %85, i32 0, i32 2
  %87 = getelementptr inbounds [64 x i8], ptr %86, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 8 %87, i8 0, i64 64, i1 false)
  br label %88

88:                                               ; preds = %78, %73
  br label %89

89:                                               ; preds = %88, %26
  br label %90

90:                                               ; preds = %93, %89
  %91 = load i64, ptr %6, align 8
  %92 = icmp uge i64 %91, 64
  br i1 %92, label %93, label %102

93:                                               ; preds = %90
  %94 = load ptr, ptr %4, align 8
  %95 = load ptr, ptr %5, align 8
  %96 = load i64, ptr %7, align 8
  %97 = getelementptr inbounds nuw i8, ptr %95, i64 %96
  call void @md5_transform_block(ptr noundef %94, ptr noundef %97)
  %98 = load i64, ptr %7, align 8
  %99 = add i64 %98, 64
  store i64 %99, ptr %7, align 8
  %100 = load i64, ptr %6, align 8
  %101 = sub i64 %100, 64
  store i64 %101, ptr %6, align 8
  br label %90, !llvm.loop !13

102:                                              ; preds = %90
  %103 = load i64, ptr %6, align 8
  %104 = icmp ugt i64 %103, 0
  br i1 %104, label %105, label %116

105:                                              ; preds = %102
  %106 = load ptr, ptr %4, align 8
  %107 = getelementptr inbounds nuw %struct.MD5Context, ptr %106, i32 0, i32 2
  %108 = getelementptr inbounds [64 x i8], ptr %107, i64 0, i64 0
  %109 = load ptr, ptr %5, align 8
  %110 = load i64, ptr %7, align 8
  %111 = getelementptr inbounds nuw i8, ptr %109, i64 %110
  %112 = load i64, ptr %6, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %108, ptr align 1 %111, i64 %112, i1 false)
  %113 = load i64, ptr %6, align 8
  %114 = load ptr, ptr %4, align 8
  %115 = getelementptr inbounds nuw %struct.MD5Context, ptr %114, i32 0, i32 3
  store i64 %113, ptr %115, align 8
  br label %116

116:                                              ; preds = %105, %102
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_finalize(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca [64 x i8], align 16
  %6 = alloca [8 x i8], align 1
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %9 = load ptr, ptr %3, align 8
  %10 = icmp eq ptr %9, null
  br i1 %10, label %11, label %12

11:                                               ; preds = %2
  call void @die_message(ptr noundef @.str.78)
  br label %12

12:                                               ; preds = %11, %2
  %13 = load ptr, ptr %4, align 8
  %14 = icmp eq ptr %13, null
  br i1 %14, label %15, label %16

15:                                               ; preds = %12
  call void @die_message(ptr noundef @.str.79)
  br label %16

16:                                               ; preds = %15, %12
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds nuw %struct.MD5Context, ptr %17, i32 0, i32 6
  %19 = load i32, ptr %18, align 4
  %20 = icmp ne i32 %19, 0
  br i1 %20, label %21, label %22

21:                                               ; preds = %16
  call void @die_message(ptr noundef @.str.80)
  br label %22

22:                                               ; preds = %21, %16
  %23 = load ptr, ptr %3, align 8
  %24 = getelementptr inbounds nuw %struct.MD5Context, ptr %23, i32 0, i32 1
  %25 = load i64, ptr %24, align 8
  %26 = mul i64 %25, 8
  store i64 %26, ptr %7, align 8
  %27 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %27, i8 0, i64 64, i1 false)
  %28 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  store i8 -128, ptr %28, align 16
  %29 = load ptr, ptr %3, align 8
  %30 = getelementptr inbounds nuw %struct.MD5Context, ptr %29, i32 0, i32 3
  %31 = load i64, ptr %30, align 8
  %32 = icmp ult i64 %31, 56
  br i1 %32, label %33, label %38

33:                                               ; preds = %22
  %34 = load ptr, ptr %3, align 8
  %35 = getelementptr inbounds nuw %struct.MD5Context, ptr %34, i32 0, i32 3
  %36 = load i64, ptr %35, align 8
  %37 = sub i64 56, %36
  store i64 %37, ptr %8, align 8
  br label %43

38:                                               ; preds = %22
  %39 = load ptr, ptr %3, align 8
  %40 = getelementptr inbounds nuw %struct.MD5Context, ptr %39, i32 0, i32 3
  %41 = load i64, ptr %40, align 8
  %42 = sub i64 120, %41
  store i64 %42, ptr %8, align 8
  br label %43

43:                                               ; preds = %38, %33
  %44 = getelementptr inbounds [8 x i8], ptr %6, i64 0, i64 0
  %45 = load i64, ptr %7, align 8
  call void @store_u64_le(ptr noundef %44, i64 noundef %45)
  %46 = load ptr, ptr %3, align 8
  %47 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %48 = load i64, ptr %8, align 8
  call void @md5_update_bytes(ptr noundef %46, ptr noundef %47, i64 noundef %48)
  %49 = load ptr, ptr %3, align 8
  %50 = getelementptr inbounds [8 x i8], ptr %6, i64 0, i64 0
  call void @md5_update_bytes(ptr noundef %49, ptr noundef %50, i64 noundef 8)
  %51 = load ptr, ptr %4, align 8
  %52 = getelementptr inbounds i8, ptr %51, i64 0
  %53 = load ptr, ptr %3, align 8
  %54 = getelementptr inbounds nuw %struct.MD5Context, ptr %53, i32 0, i32 0
  %55 = getelementptr inbounds [4 x i32], ptr %54, i64 0, i64 0
  %56 = load i32, ptr %55, align 8
  call void @store_u32_le(ptr noundef %52, i32 noundef %56)
  %57 = load ptr, ptr %4, align 8
  %58 = getelementptr inbounds i8, ptr %57, i64 4
  %59 = load ptr, ptr %3, align 8
  %60 = getelementptr inbounds nuw %struct.MD5Context, ptr %59, i32 0, i32 0
  %61 = getelementptr inbounds [4 x i32], ptr %60, i64 0, i64 1
  %62 = load i32, ptr %61, align 4
  call void @store_u32_le(ptr noundef %58, i32 noundef %62)
  %63 = load ptr, ptr %4, align 8
  %64 = getelementptr inbounds i8, ptr %63, i64 8
  %65 = load ptr, ptr %3, align 8
  %66 = getelementptr inbounds nuw %struct.MD5Context, ptr %65, i32 0, i32 0
  %67 = getelementptr inbounds [4 x i32], ptr %66, i64 0, i64 2
  %68 = load i32, ptr %67, align 8
  call void @store_u32_le(ptr noundef %64, i32 noundef %68)
  %69 = load ptr, ptr %4, align 8
  %70 = getelementptr inbounds i8, ptr %69, i64 12
  %71 = load ptr, ptr %3, align 8
  %72 = getelementptr inbounds nuw %struct.MD5Context, ptr %71, i32 0, i32 0
  %73 = getelementptr inbounds [4 x i32], ptr %72, i64 0, i64 3
  %74 = load i32, ptr %73, align 4
  call void @store_u32_le(ptr noundef %70, i32 noundef %74)
  %75 = load ptr, ptr %3, align 8
  %76 = getelementptr inbounds nuw %struct.MD5Context, ptr %75, i32 0, i32 6
  store i32 1, ptr %76, align 4
  %77 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  call void @zero_memory(ptr noundef %77, i64 noundef 64)
  %78 = getelementptr inbounds [8 x i8], ptr %6, i64 0, i64 0
  call void @zero_memory(ptr noundef %78, i64 noundef 8)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @die_message(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr @stderr, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %3, ptr noundef @.str.18, ptr noundef %4) #9
  call void @exit(i32 noundef 1) #10
  unreachable
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #5

; Function Attrs: noinline nounwind optnone uwtable
define internal void @store_u64_le(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  store i32 0, ptr %5, align 4
  br label %6

6:                                                ; preds = %21, %2
  %7 = load i32, ptr %5, align 4
  %8 = icmp slt i32 %7, 8
  br i1 %8, label %9, label %24

9:                                                ; preds = %6
  %10 = load i64, ptr %4, align 8
  %11 = load i32, ptr %5, align 4
  %12 = mul nsw i32 8, %11
  %13 = zext i32 %12 to i64
  %14 = lshr i64 %10, %13
  %15 = and i64 %14, 255
  %16 = trunc i64 %15 to i8
  %17 = load ptr, ptr %3, align 8
  %18 = load i32, ptr %5, align 4
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds i8, ptr %17, i64 %19
  store i8 %16, ptr %20, align 1
  br label %21

21:                                               ; preds = %9
  %22 = load i32, ptr %5, align 4
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %5, align 4
  br label %6, !llvm.loop !14

24:                                               ; preds = %6
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @store_u32_le(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %4, align 4
  %6 = lshr i32 %5, 0
  %7 = and i32 %6, 255
  %8 = trunc i32 %7 to i8
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds i8, ptr %9, i64 0
  store i8 %8, ptr %10, align 1
  %11 = load i32, ptr %4, align 4
  %12 = lshr i32 %11, 8
  %13 = and i32 %12, 255
  %14 = trunc i32 %13 to i8
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds i8, ptr %15, i64 1
  store i8 %14, ptr %16, align 1
  %17 = load i32, ptr %4, align 4
  %18 = lshr i32 %17, 16
  %19 = and i32 %18, 255
  %20 = trunc i32 %19 to i8
  %21 = load ptr, ptr %3, align 8
  %22 = getelementptr inbounds i8, ptr %21, i64 2
  store i8 %20, ptr %22, align 1
  %23 = load i32, ptr %4, align 4
  %24 = lshr i32 %23, 24
  %25 = and i32 %24, 255
  %26 = trunc i32 %25 to i8
  %27 = load ptr, ptr %3, align 8
  %28 = getelementptr inbounds i8, ptr %27, i64 3
  store i8 %26, ptr %28, align 1
  ret void
}

; Function Attrs: noreturn nounwind
declare void @exit(i32 noundef) #6

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #7

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_transform_block(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca [16 x i32], align 16
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  %21 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %22 = getelementptr inbounds [16 x i32], ptr %5, i64 0, i64 0
  %23 = load ptr, ptr %4, align 8
  call void @md5_decode_block_words(ptr noundef %22, ptr noundef %23)
  %24 = load ptr, ptr %3, align 8
  %25 = load ptr, ptr %4, align 8
  %26 = getelementptr inbounds [16 x i32], ptr %5, i64 0, i64 0
  call void @md5_trace_block_header(ptr noundef %24, ptr noundef %25, ptr noundef %26)
  %27 = load ptr, ptr %3, align 8
  %28 = getelementptr inbounds nuw %struct.MD5Context, ptr %27, i32 0, i32 0
  %29 = getelementptr inbounds [4 x i32], ptr %28, i64 0, i64 0
  %30 = load i32, ptr %29, align 8
  store i32 %30, ptr %6, align 4
  %31 = load ptr, ptr %3, align 8
  %32 = getelementptr inbounds nuw %struct.MD5Context, ptr %31, i32 0, i32 0
  %33 = getelementptr inbounds [4 x i32], ptr %32, i64 0, i64 1
  %34 = load i32, ptr %33, align 4
  store i32 %34, ptr %7, align 4
  %35 = load ptr, ptr %3, align 8
  %36 = getelementptr inbounds nuw %struct.MD5Context, ptr %35, i32 0, i32 0
  %37 = getelementptr inbounds [4 x i32], ptr %36, i64 0, i64 2
  %38 = load i32, ptr %37, align 8
  store i32 %38, ptr %8, align 4
  %39 = load ptr, ptr %3, align 8
  %40 = getelementptr inbounds nuw %struct.MD5Context, ptr %39, i32 0, i32 0
  %41 = getelementptr inbounds [4 x i32], ptr %40, i64 0, i64 3
  %42 = load i32, ptr %41, align 4
  store i32 %42, ptr %9, align 4
  %43 = load i32, ptr %6, align 4
  store i32 %43, ptr %10, align 4
  %44 = load i32, ptr %7, align 4
  store i32 %44, ptr %11, align 4
  %45 = load i32, ptr %8, align 4
  store i32 %45, ptr %12, align 4
  %46 = load i32, ptr %9, align 4
  store i32 %46, ptr %13, align 4
  store i32 0, ptr %14, align 4
  br label %47

47:                                               ; preds = %101, %2
  %48 = load i32, ptr %14, align 4
  %49 = icmp ult i32 %48, 64
  br i1 %49, label %50, label %104

50:                                               ; preds = %47
  %51 = load i32, ptr %14, align 4
  %52 = load i32, ptr %7, align 4
  %53 = load i32, ptr %8, align 4
  %54 = load i32, ptr %9, align 4
  %55 = call i32 @md5_choose_round_function(i32 noundef %51, i32 noundef %52, i32 noundef %53, i32 noundef %54)
  store i32 %55, ptr %15, align 4
  %56 = load i32, ptr %14, align 4
  %57 = call i32 @md5_choose_message_index(i32 noundef %56)
  store i32 %57, ptr %16, align 4
  %58 = load i32, ptr %16, align 4
  %59 = zext i32 %58 to i64
  %60 = getelementptr inbounds nuw [16 x i32], ptr %5, i64 0, i64 %59
  %61 = load i32, ptr %60, align 4
  store i32 %61, ptr %17, align 4
  %62 = load i32, ptr %6, align 4
  %63 = load i32, ptr %15, align 4
  %64 = add i32 %62, %63
  %65 = load i32, ptr %14, align 4
  %66 = zext i32 %65 to i64
  %67 = getelementptr inbounds nuw [64 x i32], ptr @MD5_K, i64 0, i64 %66
  %68 = load i32, ptr %67, align 4
  %69 = add i32 %64, %68
  %70 = load i32, ptr %17, align 4
  %71 = add i32 %69, %70
  store i32 %71, ptr %18, align 4
  %72 = load i32, ptr %18, align 4
  %73 = load i32, ptr %14, align 4
  %74 = zext i32 %73 to i64
  %75 = getelementptr inbounds nuw [64 x i32], ptr @MD5_S, i64 0, i64 %74
  %76 = load i32, ptr %75, align 4
  %77 = call i32 @rotate_left32(i32 noundef %72, i32 noundef %76)
  store i32 %77, ptr %19, align 4
  %78 = load i32, ptr %7, align 4
  %79 = load i32, ptr %19, align 4
  %80 = add i32 %78, %79
  store i32 %80, ptr %20, align 4
  %81 = load ptr, ptr %3, align 8
  %82 = getelementptr inbounds nuw %struct.MD5Context, ptr %81, i32 0, i32 5
  %83 = load i32, ptr %82, align 8
  %84 = icmp ne i32 %83, 0
  br i1 %84, label %85, label %95

85:                                               ; preds = %50
  %86 = load i32, ptr %14, align 4
  %87 = load i32, ptr %6, align 4
  %88 = load i32, ptr %7, align 4
  %89 = load i32, ptr %8, align 4
  %90 = load i32, ptr %9, align 4
  %91 = load i32, ptr %15, align 4
  %92 = load i32, ptr %16, align 4
  %93 = load i32, ptr %17, align 4
  %94 = load i32, ptr %20, align 4
  call void @md5_trace_round(i32 noundef %86, i32 noundef %87, i32 noundef %88, i32 noundef %89, i32 noundef %90, i32 noundef %91, i32 noundef %92, i32 noundef %93, i32 noundef %94)
  br label %95

95:                                               ; preds = %85, %50
  %96 = load i32, ptr %9, align 4
  store i32 %96, ptr %21, align 4
  %97 = load i32, ptr %8, align 4
  store i32 %97, ptr %9, align 4
  %98 = load i32, ptr %7, align 4
  store i32 %98, ptr %8, align 4
  %99 = load i32, ptr %20, align 4
  store i32 %99, ptr %7, align 4
  %100 = load i32, ptr %21, align 4
  store i32 %100, ptr %6, align 4
  br label %101

101:                                              ; preds = %95
  %102 = load i32, ptr %14, align 4
  %103 = add i32 %102, 1
  store i32 %103, ptr %14, align 4
  br label %47, !llvm.loop !15

104:                                              ; preds = %47
  %105 = load ptr, ptr %3, align 8
  %106 = getelementptr inbounds nuw %struct.MD5Context, ptr %105, i32 0, i32 0
  %107 = getelementptr inbounds [4 x i32], ptr %106, i64 0, i64 0
  %108 = load i32, ptr %107, align 8
  %109 = load i32, ptr %6, align 4
  %110 = add i32 %108, %109
  %111 = load ptr, ptr %3, align 8
  %112 = getelementptr inbounds nuw %struct.MD5Context, ptr %111, i32 0, i32 0
  %113 = getelementptr inbounds [4 x i32], ptr %112, i64 0, i64 0
  store i32 %110, ptr %113, align 8
  %114 = load ptr, ptr %3, align 8
  %115 = getelementptr inbounds nuw %struct.MD5Context, ptr %114, i32 0, i32 0
  %116 = getelementptr inbounds [4 x i32], ptr %115, i64 0, i64 1
  %117 = load i32, ptr %116, align 4
  %118 = load i32, ptr %7, align 4
  %119 = add i32 %117, %118
  %120 = load ptr, ptr %3, align 8
  %121 = getelementptr inbounds nuw %struct.MD5Context, ptr %120, i32 0, i32 0
  %122 = getelementptr inbounds [4 x i32], ptr %121, i64 0, i64 1
  store i32 %119, ptr %122, align 4
  %123 = load ptr, ptr %3, align 8
  %124 = getelementptr inbounds nuw %struct.MD5Context, ptr %123, i32 0, i32 0
  %125 = getelementptr inbounds [4 x i32], ptr %124, i64 0, i64 2
  %126 = load i32, ptr %125, align 8
  %127 = load i32, ptr %8, align 4
  %128 = add i32 %126, %127
  %129 = load ptr, ptr %3, align 8
  %130 = getelementptr inbounds nuw %struct.MD5Context, ptr %129, i32 0, i32 0
  %131 = getelementptr inbounds [4 x i32], ptr %130, i64 0, i64 2
  store i32 %128, ptr %131, align 8
  %132 = load ptr, ptr %3, align 8
  %133 = getelementptr inbounds nuw %struct.MD5Context, ptr %132, i32 0, i32 0
  %134 = getelementptr inbounds [4 x i32], ptr %133, i64 0, i64 3
  %135 = load i32, ptr %134, align 4
  %136 = load i32, ptr %9, align 4
  %137 = add i32 %135, %136
  %138 = load ptr, ptr %3, align 8
  %139 = getelementptr inbounds nuw %struct.MD5Context, ptr %138, i32 0, i32 0
  %140 = getelementptr inbounds [4 x i32], ptr %139, i64 0, i64 3
  store i32 %137, ptr %140, align 4
  %141 = load ptr, ptr %3, align 8
  %142 = getelementptr inbounds nuw %struct.MD5Context, ptr %141, i32 0, i32 5
  %143 = load i32, ptr %142, align 8
  %144 = icmp ne i32 %143, 0
  br i1 %144, label %145, label %170

145:                                              ; preds = %104
  %146 = load ptr, ptr @stderr, align 8
  %147 = load i32, ptr %10, align 4
  %148 = load i32, ptr %11, align 4
  %149 = load i32, ptr %12, align 4
  %150 = load i32, ptr %13, align 4
  %151 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %146, ptr noundef @.str.69, i32 noundef %147, i32 noundef %148, i32 noundef %149, i32 noundef %150) #9
  %152 = load ptr, ptr @stderr, align 8
  %153 = load ptr, ptr %3, align 8
  %154 = getelementptr inbounds nuw %struct.MD5Context, ptr %153, i32 0, i32 0
  %155 = getelementptr inbounds [4 x i32], ptr %154, i64 0, i64 0
  %156 = load i32, ptr %155, align 8
  %157 = load ptr, ptr %3, align 8
  %158 = getelementptr inbounds nuw %struct.MD5Context, ptr %157, i32 0, i32 0
  %159 = getelementptr inbounds [4 x i32], ptr %158, i64 0, i64 1
  %160 = load i32, ptr %159, align 4
  %161 = load ptr, ptr %3, align 8
  %162 = getelementptr inbounds nuw %struct.MD5Context, ptr %161, i32 0, i32 0
  %163 = getelementptr inbounds [4 x i32], ptr %162, i64 0, i64 2
  %164 = load i32, ptr %163, align 8
  %165 = load ptr, ptr %3, align 8
  %166 = getelementptr inbounds nuw %struct.MD5Context, ptr %165, i32 0, i32 0
  %167 = getelementptr inbounds [4 x i32], ptr %166, i64 0, i64 3
  %168 = load i32, ptr %167, align 4
  %169 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %152, ptr noundef @.str.70, i32 noundef %156, i32 noundef %160, i32 noundef %164, i32 noundef %168) #9
  br label %170

170:                                              ; preds = %145, %104
  %171 = load ptr, ptr %3, align 8
  %172 = getelementptr inbounds nuw %struct.MD5Context, ptr %171, i32 0, i32 4
  %173 = load i64, ptr %172, align 8
  %174 = add i64 %173, 1
  store i64 %174, ptr %172, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_decode_block_words(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  store i32 0, ptr %5, align 4
  br label %6

6:                                                ; preds = %20, %2
  %7 = load i32, ptr %5, align 4
  %8 = icmp slt i32 %7, 16
  br i1 %8, label %9, label %23

9:                                                ; preds = %6
  %10 = load ptr, ptr %4, align 8
  %11 = load i32, ptr %5, align 4
  %12 = mul nsw i32 %11, 4
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds i8, ptr %10, i64 %13
  %15 = call i32 @load_u32_le(ptr noundef %14)
  %16 = load ptr, ptr %3, align 8
  %17 = load i32, ptr %5, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %16, i64 %18
  store i32 %15, ptr %19, align 4
  br label %20

20:                                               ; preds = %9
  %21 = load i32, ptr %5, align 4
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %5, align 4
  br label %6, !llvm.loop !16

23:                                               ; preds = %6
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_trace_block_header(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %9 = load ptr, ptr %4, align 8
  %10 = getelementptr inbounds nuw %struct.MD5Context, ptr %9, i32 0, i32 5
  %11 = load i32, ptr %10, align 8
  %12 = icmp ne i32 %11, 0
  br i1 %12, label %14, label %13

13:                                               ; preds = %3
  br label %100

14:                                               ; preds = %3
  %15 = load ptr, ptr @stderr, align 8
  %16 = load ptr, ptr %4, align 8
  %17 = getelementptr inbounds nuw %struct.MD5Context, ptr %16, i32 0, i32 4
  %18 = load i64, ptr %17, align 8
  %19 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %15, ptr noundef @.str.71, i64 noundef %18) #9
  %20 = load ptr, ptr @stderr, align 8
  %21 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %20, ptr noundef @.str.72) #9
  store i32 0, ptr %7, align 4
  br label %22

22:                                               ; preds = %55, %14
  %23 = load i32, ptr %7, align 4
  %24 = icmp slt i32 %23, 4
  br i1 %24, label %25, label %58

25:                                               ; preds = %22
  %26 = load ptr, ptr @stderr, align 8
  %27 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %26, ptr noundef @.str.73) #9
  store i32 0, ptr %8, align 4
  br label %28

28:                                               ; preds = %49, %25
  %29 = load i32, ptr %8, align 4
  %30 = icmp slt i32 %29, 16
  br i1 %30, label %31, label %52

31:                                               ; preds = %28
  %32 = load ptr, ptr @stderr, align 8
  %33 = load ptr, ptr %5, align 8
  %34 = load i32, ptr %7, align 4
  %35 = mul nsw i32 %34, 16
  %36 = load i32, ptr %8, align 4
  %37 = add nsw i32 %35, %36
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds i8, ptr %33, i64 %38
  %40 = load i8, ptr %39, align 1
  %41 = zext i8 %40 to i32
  %42 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %32, ptr noundef @.str.74, i32 noundef %41) #9
  %43 = load i32, ptr %8, align 4
  %44 = icmp ne i32 %43, 15
  br i1 %44, label %45, label %48

45:                                               ; preds = %31
  %46 = load ptr, ptr @stderr, align 8
  %47 = call i32 @fputc(i32 noundef 32, ptr noundef %46)
  br label %48

48:                                               ; preds = %45, %31
  br label %49

49:                                               ; preds = %48
  %50 = load i32, ptr %8, align 4
  %51 = add nsw i32 %50, 1
  store i32 %51, ptr %8, align 4
  br label %28, !llvm.loop !17

52:                                               ; preds = %28
  %53 = load ptr, ptr @stderr, align 8
  %54 = call i32 @fputc(i32 noundef 10, ptr noundef %53)
  br label %55

55:                                               ; preds = %52
  %56 = load i32, ptr %7, align 4
  %57 = add nsw i32 %56, 1
  store i32 %57, ptr %7, align 4
  br label %22, !llvm.loop !18

58:                                               ; preds = %22
  %59 = load ptr, ptr @stderr, align 8
  %60 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %59, ptr noundef @.str.75) #9
  store i32 0, ptr %7, align 4
  br label %61

61:                                               ; preds = %97, %58
  %62 = load i32, ptr %7, align 4
  %63 = icmp slt i32 %62, 4
  br i1 %63, label %64, label %100

64:                                               ; preds = %61
  %65 = load ptr, ptr @stderr, align 8
  %66 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %65, ptr noundef @.str.73) #9
  store i32 0, ptr %8, align 4
  br label %67

67:                                               ; preds = %91, %64
  %68 = load i32, ptr %8, align 4
  %69 = icmp slt i32 %68, 4
  br i1 %69, label %70, label %94

70:                                               ; preds = %67
  %71 = load ptr, ptr @stderr, align 8
  %72 = load i32, ptr %7, align 4
  %73 = mul nsw i32 %72, 4
  %74 = load i32, ptr %8, align 4
  %75 = add nsw i32 %73, %74
  %76 = load ptr, ptr %6, align 8
  %77 = load i32, ptr %7, align 4
  %78 = mul nsw i32 %77, 4
  %79 = load i32, ptr %8, align 4
  %80 = add nsw i32 %78, %79
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds i32, ptr %76, i64 %81
  %83 = load i32, ptr %82, align 4
  %84 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %71, ptr noundef @.str.76, i32 noundef %75, i32 noundef %83) #9
  %85 = load i32, ptr %8, align 4
  %86 = icmp ne i32 %85, 3
  br i1 %86, label %87, label %90

87:                                               ; preds = %70
  %88 = load ptr, ptr @stderr, align 8
  %89 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %88, ptr noundef @.str.73) #9
  br label %90

90:                                               ; preds = %87, %70
  br label %91

91:                                               ; preds = %90
  %92 = load i32, ptr %8, align 4
  %93 = add nsw i32 %92, 1
  store i32 %93, ptr %8, align 4
  br label %67, !llvm.loop !19

94:                                               ; preds = %67
  %95 = load ptr, ptr @stderr, align 8
  %96 = call i32 @fputc(i32 noundef 10, ptr noundef %95)
  br label %97

97:                                               ; preds = %94
  %98 = load i32, ptr %7, align 4
  %99 = add nsw i32 %98, 1
  store i32 %99, ptr %7, align 4
  br label %61, !llvm.loop !20

100:                                              ; preds = %13, %61
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_choose_round_function(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  store i32 %2, ptr %8, align 4
  store i32 %3, ptr %9, align 4
  %10 = load i32, ptr %6, align 4
  %11 = icmp ult i32 %10, 16
  br i1 %11, label %12, label %17

12:                                               ; preds = %4
  %13 = load i32, ptr %7, align 4
  %14 = load i32, ptr %8, align 4
  %15 = load i32, ptr %9, align 4
  %16 = call i32 @md5_f(i32 noundef %13, i32 noundef %14, i32 noundef %15)
  store i32 %16, ptr %5, align 4
  br label %38

17:                                               ; preds = %4
  %18 = load i32, ptr %6, align 4
  %19 = icmp ult i32 %18, 32
  br i1 %19, label %20, label %25

20:                                               ; preds = %17
  %21 = load i32, ptr %7, align 4
  %22 = load i32, ptr %8, align 4
  %23 = load i32, ptr %9, align 4
  %24 = call i32 @md5_g(i32 noundef %21, i32 noundef %22, i32 noundef %23)
  store i32 %24, ptr %5, align 4
  br label %38

25:                                               ; preds = %17
  %26 = load i32, ptr %6, align 4
  %27 = icmp ult i32 %26, 48
  br i1 %27, label %28, label %33

28:                                               ; preds = %25
  %29 = load i32, ptr %7, align 4
  %30 = load i32, ptr %8, align 4
  %31 = load i32, ptr %9, align 4
  %32 = call i32 @md5_h(i32 noundef %29, i32 noundef %30, i32 noundef %31)
  store i32 %32, ptr %5, align 4
  br label %38

33:                                               ; preds = %25
  %34 = load i32, ptr %7, align 4
  %35 = load i32, ptr %8, align 4
  %36 = load i32, ptr %9, align 4
  %37 = call i32 @md5_i(i32 noundef %34, i32 noundef %35, i32 noundef %36)
  store i32 %37, ptr %5, align 4
  br label %38

38:                                               ; preds = %33, %28, %20, %12
  %39 = load i32, ptr %5, align 4
  ret i32 %39
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_choose_message_index(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = load i32, ptr %3, align 4
  %5 = icmp ult i32 %4, 16
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = load i32, ptr %3, align 4
  store i32 %7, ptr %2, align 4
  br label %28

8:                                                ; preds = %1
  %9 = load i32, ptr %3, align 4
  %10 = icmp ult i32 %9, 32
  br i1 %10, label %11, label %16

11:                                               ; preds = %8
  %12 = load i32, ptr %3, align 4
  %13 = mul i32 5, %12
  %14 = add i32 %13, 1
  %15 = and i32 %14, 15
  store i32 %15, ptr %2, align 4
  br label %28

16:                                               ; preds = %8
  %17 = load i32, ptr %3, align 4
  %18 = icmp ult i32 %17, 48
  br i1 %18, label %19, label %24

19:                                               ; preds = %16
  %20 = load i32, ptr %3, align 4
  %21 = mul i32 3, %20
  %22 = add i32 %21, 5
  %23 = and i32 %22, 15
  store i32 %23, ptr %2, align 4
  br label %28

24:                                               ; preds = %16
  %25 = load i32, ptr %3, align 4
  %26 = mul i32 7, %25
  %27 = and i32 %26, 15
  store i32 %27, ptr %2, align 4
  br label %28

28:                                               ; preds = %24, %19, %11, %6
  %29 = load i32, ptr %2, align 4
  ret i32 %29
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @rotate_left32(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = shl i32 %5, %6
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 32, %9
  %11 = lshr i32 %8, %10
  %12 = or i32 %7, %11
  ret i32 %12
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_trace_round(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6, i32 noundef %7, i32 noundef %8) #0 {
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  store i32 %0, ptr %10, align 4
  store i32 %1, ptr %11, align 4
  store i32 %2, ptr %12, align 4
  store i32 %3, ptr %13, align 4
  store i32 %4, ptr %14, align 4
  store i32 %5, ptr %15, align 4
  store i32 %6, ptr %16, align 4
  store i32 %7, ptr %17, align 4
  store i32 %8, ptr %18, align 4
  %19 = load ptr, ptr @stderr, align 8
  %20 = load i32, ptr %10, align 4
  %21 = load i32, ptr %11, align 4
  %22 = load i32, ptr %12, align 4
  %23 = load i32, ptr %13, align 4
  %24 = load i32, ptr %14, align 4
  %25 = load i32, ptr %15, align 4
  %26 = load i32, ptr %16, align 4
  %27 = load i32, ptr %17, align 4
  %28 = load i32, ptr %18, align 4
  %29 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %19, ptr noundef @.str.77, i32 noundef %20, i32 noundef %21, i32 noundef %22, i32 noundef %23, i32 noundef %24, i32 noundef %25, i32 noundef %26, i32 noundef %27, i32 noundef %28) #9
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_f(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %7 = load i32, ptr %4, align 4
  %8 = load i32, ptr %5, align 4
  %9 = and i32 %7, %8
  %10 = load i32, ptr %4, align 4
  %11 = xor i32 %10, -1
  %12 = load i32, ptr %6, align 4
  %13 = and i32 %11, %12
  %14 = or i32 %9, %13
  ret i32 %14
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_g(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %7 = load i32, ptr %4, align 4
  %8 = load i32, ptr %6, align 4
  %9 = and i32 %7, %8
  %10 = load i32, ptr %5, align 4
  %11 = load i32, ptr %6, align 4
  %12 = xor i32 %11, -1
  %13 = and i32 %10, %12
  %14 = or i32 %9, %13
  ret i32 %14
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_h(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %7 = load i32, ptr %4, align 4
  %8 = load i32, ptr %5, align 4
  %9 = xor i32 %7, %8
  %10 = load i32, ptr %6, align 4
  %11 = xor i32 %9, %10
  ret i32 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_i(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %7 = load i32, ptr %5, align 4
  %8 = load i32, ptr %4, align 4
  %9 = load i32, ptr %6, align 4
  %10 = xor i32 %9, -1
  %11 = or i32 %8, %10
  %12 = xor i32 %7, %11
  ret i32 %12
}

declare i32 @fputc(i32 noundef, ptr noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @load_u32_le(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds i8, ptr %7, i64 0
  %9 = load i8, ptr %8, align 1
  %10 = zext i8 %9 to i32
  store i32 %10, ptr %3, align 4
  %11 = load ptr, ptr %2, align 8
  %12 = getelementptr inbounds i8, ptr %11, i64 1
  %13 = load i8, ptr %12, align 1
  %14 = zext i8 %13 to i32
  %15 = shl i32 %14, 8
  store i32 %15, ptr %4, align 4
  %16 = load ptr, ptr %2, align 8
  %17 = getelementptr inbounds i8, ptr %16, i64 2
  %18 = load i8, ptr %17, align 1
  %19 = zext i8 %18 to i32
  %20 = shl i32 %19, 16
  store i32 %20, ptr %5, align 4
  %21 = load ptr, ptr %2, align 8
  %22 = getelementptr inbounds i8, ptr %21, i64 3
  %23 = load i8, ptr %22, align 1
  %24 = zext i8 %23 to i32
  %25 = shl i32 %24, 24
  store i32 %25, ptr %6, align 4
  %26 = load i32, ptr %3, align 4
  %27 = load i32, ptr %4, align 4
  %28 = or i32 %26, %27
  %29 = load i32, ptr %5, align 4
  %30 = or i32 %28, %29
  %31 = load i32, ptr %6, align 4
  %32 = or i32 %30, %31
  ret i32 %32
}

declare i64 @fread(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #3

; Function Attrs: nounwind
declare i32 @ferror(ptr noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal ptr @duplicate_string(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = icmp eq ptr %6, null
  br i1 %7, label %8, label %9

8:                                                ; preds = %1
  store ptr null, ptr %2, align 8
  br label %24

9:                                                ; preds = %1
  %10 = load ptr, ptr %3, align 8
  %11 = call i64 @strlen(ptr noundef %10) #11
  store i64 %11, ptr %4, align 8
  %12 = load i64, ptr %4, align 8
  %13 = add i64 %12, 1
  %14 = call noalias ptr @malloc(i64 noundef %13) #13
  store ptr %14, ptr %5, align 8
  %15 = load ptr, ptr %5, align 8
  %16 = icmp eq ptr %15, null
  br i1 %16, label %17, label %18

17:                                               ; preds = %9
  call void @die_message(ptr noundef @.str.19)
  br label %18

18:                                               ; preds = %17, %9
  %19 = load ptr, ptr %5, align 8
  %20 = load ptr, ptr %3, align 8
  %21 = load i64, ptr %4, align 8
  %22 = add i64 %21, 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %19, ptr align 1 %20, i64 %22, i1 false)
  %23 = load ptr, ptr %5, align 8
  store ptr %23, ptr %2, align 8
  br label %24

24:                                               ; preds = %18, %8
  %25 = load ptr, ptr %2, align 8
  ret ptr %25
}

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #8

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define internal void @options_init(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i64, align 8
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = icmp eq ptr %4, null
  br i1 %5, label %6, label %7

6:                                                ; preds = %1
  br label %31

7:                                                ; preds = %1
  %8 = load ptr, ptr %2, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %8, i8 0, i64 3104, i1 false)
  store i64 0, ptr %3, align 8
  br label %9

9:                                                ; preds = %28, %7
  %10 = load i64, ptr %3, align 8
  %11 = icmp ult i64 %10, 128
  br i1 %11, label %12, label %31

12:                                               ; preds = %9
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %13, i32 0, i32 6
  %15 = load i64, ptr %3, align 8
  %16 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %14, i64 0, i64 %15
  %17 = getelementptr inbounds nuw %struct.InputJob, ptr %16, i32 0, i32 0
  store i32 0, ptr %17, align 8
  %18 = load ptr, ptr %2, align 8
  %19 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %18, i32 0, i32 6
  %20 = load i64, ptr %3, align 8
  %21 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %19, i64 0, i64 %20
  %22 = getelementptr inbounds nuw %struct.InputJob, ptr %21, i32 0, i32 1
  store ptr null, ptr %22, align 8
  %23 = load ptr, ptr %2, align 8
  %24 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %23, i32 0, i32 6
  %25 = load i64, ptr %3, align 8
  %26 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %24, i64 0, i64 %25
  %27 = getelementptr inbounds nuw %struct.InputJob, ptr %26, i32 0, i32 2
  store ptr null, ptr %27, align 8
  br label %28

28:                                               ; preds = %12
  %29 = load i64, ptr %3, align 8
  %30 = add i64 %29, 1
  store i64 %30, ptr %3, align 8
  br label %9, !llvm.loop !21

31:                                               ; preds = %6, %9
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @string_equals(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %6 = load ptr, ptr %4, align 8
  %7 = icmp eq ptr %6, null
  br i1 %7, label %11, label %8

8:                                                ; preds = %2
  %9 = load ptr, ptr %5, align 8
  %10 = icmp eq ptr %9, null
  br i1 %10, label %11, label %12

11:                                               ; preds = %8, %2
  store i32 0, ptr %3, align 4
  br label %18

12:                                               ; preds = %8
  %13 = load ptr, ptr %4, align 8
  %14 = load ptr, ptr %5, align 8
  %15 = call i32 @strcmp(ptr noundef %13, ptr noundef %14) #11
  %16 = icmp eq i32 %15, 0
  %17 = zext i1 %16 to i32
  store i32 %17, ptr %3, align 4
  br label %18

18:                                               ; preds = %12, %11
  %19 = load i32, ptr %3, align 4
  ret i32 %19
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @options_add_job(ptr noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca %struct.InputJob, align 8
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %10 = load ptr, ptr %5, align 8
  %11 = icmp eq ptr %10, null
  br i1 %11, label %12, label %13

12:                                               ; preds = %4
  call void @die_message(ptr noundef @.str.16)
  br label %13

13:                                               ; preds = %12, %4
  %14 = load ptr, ptr %5, align 8
  %15 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %14, i32 0, i32 7
  %16 = load i64, ptr %15, align 8
  %17 = icmp uge i64 %16, 128
  br i1 %17, label %18, label %19

18:                                               ; preds = %13
  call void @die_message(ptr noundef @.str.17)
  br label %19

19:                                               ; preds = %18, %13
  %20 = load ptr, ptr %5, align 8
  %21 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %20, i32 0, i32 6
  %22 = load ptr, ptr %5, align 8
  %23 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %22, i32 0, i32 7
  %24 = load i64, ptr %23, align 8
  %25 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %21, i64 0, i64 %24
  %26 = load i32, ptr %6, align 4
  %27 = load ptr, ptr %7, align 8
  %28 = load ptr, ptr %8, align 8
  call void @make_input_job(ptr dead_on_unwind writable sret(%struct.InputJob) align 8 %9, i32 noundef %26, ptr noundef %27, ptr noundef %28)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %25, ptr align 8 %9, i64 24, i1 false)
  %29 = load ptr, ptr %5, align 8
  %30 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %29, i32 0, i32 7
  %31 = load i64, ptr %30, align 8
  %32 = add i64 %31, 1
  store i64 %32, ptr %30, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @require_next_arg(i32 noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  store i32 %0, ptr %5, align 4
  store ptr %1, ptr %6, align 8
  store i32 %2, ptr %7, align 4
  store ptr %3, ptr %8, align 8
  %9 = load i32, ptr %7, align 4
  %10 = add nsw i32 %9, 1
  %11 = load i32, ptr %5, align 4
  %12 = icmp sge i32 %10, %11
  br i1 %12, label %13, label %17

13:                                               ; preds = %4
  %14 = load ptr, ptr @stderr, align 8
  %15 = load ptr, ptr %8, align 8
  %16 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %14, ptr noundef @.str.20, ptr noundef %15) #9
  call void @exit(i32 noundef 1) #10
  unreachable

17:                                               ; preds = %4
  %18 = load ptr, ptr %6, align 8
  %19 = load i32, ptr %7, align 4
  %20 = add nsw i32 %19, 1
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds ptr, ptr %18, i64 %21
  %23 = load ptr, ptr %22, align 8
  %24 = icmp eq ptr %23, null
  br i1 %24, label %25, label %29

25:                                               ; preds = %17
  %26 = load ptr, ptr @stderr, align 8
  %27 = load ptr, ptr %8, align 8
  %28 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %26, ptr noundef @.str.21, ptr noundef %27) #9
  call void @exit(i32 noundef 1) #10
  unreachable

29:                                               ; preds = %17
  %30 = load i32, ptr %7, align 4
  %31 = add nsw i32 %30, 1
  ret i32 %31
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @string_starts_with_dash(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp ne ptr %3, null
  br i1 %4, label %5, label %11

5:                                                ; preds = %1
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds i8, ptr %6, i64 0
  %8 = load i8, ptr %7, align 1
  %9 = sext i8 %8 to i32
  %10 = icmp eq i32 %9, 45
  br label %11

11:                                               ; preds = %5, %1
  %12 = phi i1 [ false, %1 ], [ %10, %5 ]
  %13 = zext i1 %12 to i32
  ret i32 %13
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #6 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #8 = { nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #9 = { nounwind }
attributes #10 = { noreturn nounwind }
attributes #11 = { nounwind willreturn memory(read) }
attributes #12 = { nounwind willreturn memory(none) }
attributes #13 = { nounwind allocsize(0) }

!llvm.ident = !{!0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Ubuntu clang version 21.1.8 (++20251221032922+2078da43e25a-1~exp1~20251221153059.70)"}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"PIE Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
!14 = distinct !{!14, !7}
!15 = distinct !{!15, !7}
!16 = distinct !{!16, !7}
!17 = distinct !{!17, !7}
!18 = distinct !{!18, !7}
!19 = distinct !{!19, !7}
!20 = distinct !{!20, !7}
!21 = distinct !{!21, !7}

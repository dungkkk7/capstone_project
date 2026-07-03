; ModuleID = 'data/obfuscated/md5/obfuscated.bc'
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
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca %struct.ProgramOptions, align 8
  %10 = alloca i32, align 4
  store i32 -1881035000, ptr %4, align 4
  br label %11

11:                                               ; preds = %324, %131, %130, %2
  %12 = load i32, ptr %4, align 4
  %13 = sub i32 %12, 78685330
  %14 = mul i32 %13, 1742041227
  switch i32 %14, label %131 [
    i32 912412178, label %15
    i32 1286153554, label %31
    i32 900267055, label %47
    i32 1778729903, label %61
    i32 1809140927, label %72
    i32 259153452, label %91
    i32 1715210011, label %105
    i32 1810943323, label %115
    i32 124550598, label %128
    i32 1407612714, label %142
    i32 1652340603, label %153
    i32 222617335, label %165
    i32 1591450685, label %187
    i32 1547031496, label %198
    i32 1018963107, label %211
    i32 180673332, label %224
    i32 755882493, label %235
  ]

15:                                               ; preds = %11
  store i32 0, ptr %6, align 4
  store i32 %0, ptr %7, align 4
  store ptr %1, ptr %8, align 8
  %16 = load i32, ptr %7, align 4
  %17 = load ptr, ptr %8, align 8
  call void @parse_arguments(i32 noundef %16, ptr noundef %17, ptr noundef %9)
  %18 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %9, i32 0, i32 5
  %19 = load i32, ptr %18, align 4
  %20 = icmp ne i32 %19, 0
  %21 = select i1 %20, i32 392158408, i32 -115476330
  store i32 %21, ptr %4, align 4
  %22 = xor i32 %0, -718502279
  %23 = and i32 %0, %22
  %24 = or i32 %0, %22
  %25 = xor i32 %0, %22
  %26 = add i32 %23, %24
  %27 = sub i32 %26, %0
  %28 = sub i32 %27, %22
  %29 = mul i32 %28, 144
  %30 = icmp sgt i32 %29, 0
  br i1 %30, label %257, label %130

31:                                               ; preds = %11
  %32 = load ptr, ptr %8, align 8
  %33 = getelementptr inbounds ptr, ptr %32, i64 0
  %34 = load ptr, ptr %33, align 8
  %35 = icmp ne ptr %34, null
  %36 = select i1 %35, i32 -806225921, i32 1682718335
  store i32 %36, ptr %4, align 4
  %37 = xor i32 %0, -2077917039
  %38 = and i32 %0, %37
  %39 = or i32 %0, %37
  %40 = xor i32 %0, %37
  %41 = mul i32 %39, 2
  %42 = sub i32 %41, %40
  %43 = sub i32 %42, %0
  %44 = sub i32 %43, %37
  %45 = mul i32 %44, 176
  %46 = icmp sle i32 %45, 0
  br i1 %46, label %130, label %266

47:                                               ; preds = %11
  %48 = load ptr, ptr %8, align 8
  %49 = getelementptr inbounds ptr, ptr %48, i64 0
  %50 = load ptr, ptr %49, align 8
  store ptr %50, ptr %5, align 8
  store i32 -1121719377, ptr %4, align 4
  %51 = xor i32 %0, 1358084659
  %52 = and i32 %0, %51
  %53 = or i32 %0, %51
  %54 = xor i32 %0, %51
  %55 = mul i32 %53, 2
  %56 = sub i32 %55, %54
  %57 = sub i32 %56, %0
  %58 = sub i32 %57, %51
  %59 = mul i32 %58, 201
  %60 = icmp slt i32 %59, 1
  br i1 %60, label %130, label %274

61:                                               ; preds = %11
  store ptr @.str, ptr %5, align 8
  store i32 -1121719377, ptr %4, align 4
  %62 = xor i32 %0, -100562379
  %63 = and i32 %0, %62
  %64 = or i32 %0, %62
  %65 = xor i32 %0, %62
  %66 = add i32 %0, %62
  %67 = sub i32 %66, %65
  %68 = mul i32 %63, 2
  %69 = sub i32 %67, %68
  %70 = mul i32 %69, 190
  %71 = icmp uge i32 %70, 0
  br i1 %71, label %130, label %283

72:                                               ; preds = %11
  %73 = load ptr, ptr %5, align 8
  call void @print_usage(ptr noundef %73)
  call void @options_free(ptr noundef %9)
  store i32 0, ptr %6, align 4
  store i32 1208934564, ptr %4, align 4
  %74 = xor i32 %0, -1199871327
  %75 = and i32 %0, %74
  %76 = or i32 %0, %74
  %77 = xor i32 %0, %74
  %78 = sub i32 %76, %77
  %79 = sub i32 %78, %75
  %80 = mul i32 %79, 103
  %81 = xor i32 %0, -1945988229
  %82 = and i32 %0, %81
  %83 = or i32 %0, %81
  %84 = xor i32 %0, %81
  %85 = mul i32 %83, 2
  %86 = sub i32 %85, %84
  %87 = sub i32 %86, %0
  %88 = sub i32 %87, %81
  %89 = mul i32 %88, 25
  %90 = icmp ne i32 %80, %89
  br i1 %90, label %293, label %130

91:                                               ; preds = %11
  %92 = call i32 @validate_options(ptr noundef %9)
  %93 = icmp ne i32 %92, 0
  %94 = select i1 %93, i32 -94098877, i32 -2063399677
  store i32 %94, ptr %4, align 4
  %95 = xor i32 %0, -363973027
  %96 = and i32 %0, %95
  %97 = or i32 %0, %95
  %98 = xor i32 %0, %95
  %99 = add i32 %0, %95
  %100 = sub i32 %99, %98
  %101 = mul i32 %96, 2
  %102 = sub i32 %100, %101
  %103 = mul i32 %102, 110
  %104 = icmp slt i32 %103, 0
  br i1 %104, label %300, label %130

105:                                              ; preds = %11
  call void @options_free(ptr noundef %9)
  store i32 1, ptr %6, align 4
  store i32 1208934564, ptr %4, align 4
  %106 = xor i32 %0, 487196023
  %107 = and i32 %0, %106
  %108 = or i32 %0, %106
  %109 = xor i32 %0, %106
  %110 = add i32 %107, %108
  %111 = sub i32 %110, %0
  %112 = sub i32 %111, %106
  %113 = mul i32 %112, 23
  %114 = icmp uge i32 %113, 0
  br i1 %114, label %130, label %308

115:                                              ; preds = %11
  %116 = call i32 @run_program(ptr noundef %9)
  store i32 %116, ptr %10, align 4
  call void @options_free(ptr noundef %9)
  %117 = load i32, ptr %10, align 4
  store i32 %117, ptr %6, align 4
  store i32 1208934564, ptr %4, align 4
  %118 = xor i32 %0, -13103899
  %119 = and i32 %0, %118
  %120 = or i32 %0, %118
  %121 = xor i32 %0, %118
  %122 = mul i32 %120, 2
  %123 = sub i32 %122, %121
  %124 = sub i32 %123, %0
  %125 = sub i32 %124, %118
  %126 = mul i32 %125, 79
  %127 = icmp ugt i32 %126, 0
  br i1 %127, label %317, label %130

128:                                              ; preds = %11
  %129 = load i32, ptr %6, align 4
  ret i32 %129

130:                                              ; preds = %393, %384, %377, %370, %360, %353, %343, %334, %317, %308, %300, %293, %283, %274, %266, %257, %235, %224, %211, %198, %187, %165, %153, %142, %115, %105, %91, %72, %61, %47, %31, %15
  br label %11

131:                                              ; preds = %11
  store i32 -1881035000, ptr %4, align 4
  call void asm sideeffect "", ""()
  %132 = xor i32 %0, -1027301235
  %133 = and i32 %0, %132
  %134 = or i32 %0, %132
  %135 = xor i32 %0, %132
  %136 = mul i32 %134, 2
  %137 = sub i32 %136, %135
  %138 = sub i32 %137, %0
  %139 = sub i32 %138, %132
  %140 = mul i32 %139, 126
  %141 = icmp ne i32 %140, 0
  br i1 %141, label %324, label %11

142:                                              ; preds = %11
  %143 = load i32, ptr %4, align 4
  %144 = xor i32 %143, 1370368122
  store i32 %144, ptr %4, align 4
  %145 = xor i32 %0, 474449689
  %146 = and i32 %0, %145
  %147 = or i32 %0, %145
  %148 = xor i32 %0, %145
  %149 = sub i32 %147, %148
  %150 = sub i32 %149, %146
  %151 = mul i32 %150, 10
  %152 = icmp slt i32 %151, 0
  br i1 %152, label %334, label %130

153:                                              ; preds = %11
  %154 = load i32, ptr %4, align 4
  %155 = xor i32 %154, 2069653639
  store i32 %155, ptr %4, align 4
  %156 = xor i32 %0, -190224369
  %157 = and i32 %0, %156
  %158 = or i32 %0, %156
  %159 = xor i32 %0, %156
  %160 = add i32 %157, %158
  %161 = sub i32 %160, %0
  %162 = sub i32 %161, %156
  %163 = mul i32 %162, 186
  %164 = icmp uge i32 %163, 0
  br i1 %164, label %130, label %343

165:                                              ; preds = %11
  %166 = load i32, ptr %4, align 4
  %167 = xor i32 %166, 22295004
  store i32 %167, ptr %4, align 4
  %168 = xor i32 %0, -1455275007
  %169 = and i32 %0, %168
  %170 = or i32 %0, %168
  %171 = xor i32 %0, %168
  %172 = add i32 %0, %168
  %173 = sub i32 %172, %171
  %174 = mul i32 %169, 2
  %175 = sub i32 %173, %174
  %176 = mul i32 %175, 245
  %177 = xor i32 %0, -396903761
  %178 = and i32 %0, %177
  %179 = or i32 %0, %177
  %180 = xor i32 %0, %177
  %181 = mul i32 %179, 2
  %182 = sub i32 %181, %180
  %183 = sub i32 %182, %0
  %184 = sub i32 %183, %177
  %185 = mul i32 %184, 136
  %186 = icmp eq i32 %176, %185
  br i1 %186, label %130, label %353

187:                                              ; preds = %11
  %188 = load i32, ptr %4, align 4
  %189 = xor i32 %188, -1216644731
  store i32 %189, ptr %4, align 4
  %190 = xor i32 %0, 1018538267
  %191 = and i32 %0, %190
  %192 = or i32 %0, %190
  %193 = xor i32 %0, %190
  %194 = sub i32 %192, %193
  %195 = sub i32 %194, %191
  %196 = mul i32 %195, 222
  %197 = icmp uge i32 %196, 0
  br i1 %197, label %130, label %360

198:                                              ; preds = %11
  %199 = load i32, ptr %4, align 4
  %200 = xor i32 %199, -1993691121
  store i32 %200, ptr %4, align 4
  %201 = xor i32 %0, 1772799587
  %202 = and i32 %0, %201
  %203 = or i32 %0, %201
  %204 = xor i32 %0, %201
  %205 = add i32 %0, %201
  %206 = sub i32 %205, %204
  %207 = mul i32 %202, 2
  %208 = sub i32 %206, %207
  %209 = mul i32 %208, 40
  %210 = icmp uge i32 %209, 0
  br i1 %210, label %130, label %370

211:                                              ; preds = %11
  %212 = load i32, ptr %4, align 4
  %213 = xor i32 %212, 1298048883
  store i32 %213, ptr %4, align 4
  %214 = xor i32 %0, 1477288721
  %215 = and i32 %0, %214
  %216 = or i32 %0, %214
  %217 = xor i32 %0, %214
  %218 = add i32 %0, %214
  %219 = sub i32 %218, %217
  %220 = mul i32 %215, 2
  %221 = sub i32 %219, %220
  %222 = mul i32 %221, 114
  %223 = icmp sle i32 %222, 0
  br i1 %223, label %130, label %377

224:                                              ; preds = %11
  %225 = load i32, ptr %4, align 4
  %226 = xor i32 %225, -1446807384
  store i32 %226, ptr %4, align 4
  %227 = xor i32 %0, 1297950363
  %228 = and i32 %0, %227
  %229 = or i32 %0, %227
  %230 = xor i32 %0, %227
  %231 = sub i32 %229, %230
  %232 = sub i32 %231, %228
  %233 = mul i32 %232, 187
  %234 = icmp ugt i32 %233, 0
  br i1 %234, label %384, label %130

235:                                              ; preds = %11
  %236 = load i32, ptr %4, align 4
  %237 = xor i32 %236, 1332164830
  store i32 %237, ptr %4, align 4
  %238 = xor i32 %0, -127359857
  %239 = and i32 %0, %238
  %240 = or i32 %0, %238
  %241 = xor i32 %0, %238
  %242 = add i32 %0, %238
  %243 = sub i32 %242, %241
  %244 = mul i32 %239, 2
  %245 = sub i32 %243, %244
  %246 = mul i32 %245, 170
  %247 = xor i32 %0, 794403615
  %248 = and i32 %0, %247
  %249 = or i32 %0, %247
  %250 = xor i32 %0, %247
  %251 = mul i32 %249, 2
  %252 = sub i32 %251, %250
  %253 = sub i32 %252, %0
  %254 = sub i32 %253, %247
  %255 = mul i32 %254, 78
  %256 = icmp eq i32 %246, %255
  br i1 %256, label %130, label %393

257:                                              ; preds = %15
  %258 = load i64, ptr %3, align 8
  %259 = zext i32 %0 to i64
  %260 = ptrtoint ptr %1 to i64
  %261 = mul i64 %259, %258
  %262 = mul i64 %261, %258
  %263 = mul i64 %262, %259
  %264 = xor i64 %263, %260
  %265 = add i64 %264, %259
  store i64 %265, ptr %3, align 8
  br label %130

266:                                              ; preds = %31
  %267 = load i64, ptr %3, align 8
  %268 = zext i32 %0 to i64
  %269 = ptrtoint ptr %1 to i64
  %270 = add i64 %268, %269
  %271 = add i64 %270, %268
  %272 = and i64 %271, %268
  %273 = sub i64 %272, %268
  store i64 %273, ptr %3, align 8
  br label %130

274:                                              ; preds = %47
  %275 = load i64, ptr %3, align 8
  %276 = zext i32 %0 to i64
  %277 = ptrtoint ptr %1 to i64
  %278 = and i64 %276, %276
  %279 = xor i64 %278, %277
  %280 = sub i64 %279, %277
  %281 = or i64 %280, %277
  %282 = or i64 %281, %276
  store i64 %282, ptr %3, align 8
  br label %130

283:                                              ; preds = %61
  %284 = load i64, ptr %3, align 8
  %285 = zext i32 %0 to i64
  %286 = ptrtoint ptr %1 to i64
  %287 = xor i64 %285, %286
  %288 = xor i64 %287, %286
  %289 = add i64 %288, %284
  %290 = and i64 %289, %285
  %291 = mul i64 %290, %285
  %292 = add i64 %291, %285
  store i64 %292, ptr %3, align 8
  br label %130

293:                                              ; preds = %72
  %294 = load i64, ptr %3, align 8
  %295 = zext i32 %0 to i64
  %296 = ptrtoint ptr %1 to i64
  %297 = add i64 %296, %294
  %298 = xor i64 %297, %294
  %299 = and i64 %298, %295
  store i64 %299, ptr %3, align 8
  br label %130

300:                                              ; preds = %91
  %301 = load i64, ptr %3, align 8
  %302 = zext i32 %0 to i64
  %303 = ptrtoint ptr %1 to i64
  %304 = or i64 %301, %303
  %305 = and i64 %304, %303
  %306 = mul i64 %305, %301
  %307 = mul i64 %306, %301
  store i64 %307, ptr %3, align 8
  br label %130

308:                                              ; preds = %105
  %309 = load i64, ptr %3, align 8
  %310 = zext i32 %0 to i64
  %311 = ptrtoint ptr %1 to i64
  %312 = sub i64 %309, %309
  %313 = or i64 %312, %309
  %314 = xor i64 %313, %310
  %315 = mul i64 %314, %311
  %316 = xor i64 %315, %309
  store i64 %316, ptr %3, align 8
  br label %130

317:                                              ; preds = %115
  %318 = load i64, ptr %3, align 8
  %319 = zext i32 %0 to i64
  %320 = ptrtoint ptr %1 to i64
  %321 = add i64 %318, %320
  %322 = sub i64 %321, %320
  %323 = xor i64 %322, %318
  store i64 %323, ptr %3, align 8
  br label %130

324:                                              ; preds = %131
  %325 = load i64, ptr %3, align 8
  %326 = zext i32 %0 to i64
  %327 = ptrtoint ptr %1 to i64
  %328 = or i64 %325, %326
  %329 = or i64 %328, %325
  %330 = and i64 %329, %327
  %331 = add i64 %330, %326
  %332 = xor i64 %331, %325
  %333 = mul i64 %332, %325
  store i64 %333, ptr %3, align 8
  br label %11

334:                                              ; preds = %142
  %335 = load i64, ptr %3, align 8
  %336 = zext i32 %0 to i64
  %337 = ptrtoint ptr %1 to i64
  %338 = mul i64 %335, %336
  %339 = or i64 %338, %337
  %340 = or i64 %339, %336
  %341 = or i64 %340, %337
  %342 = and i64 %341, %336
  store i64 %342, ptr %3, align 8
  br label %130

343:                                              ; preds = %153
  %344 = load i64, ptr %3, align 8
  %345 = zext i32 %0 to i64
  %346 = ptrtoint ptr %1 to i64
  %347 = and i64 %345, %346
  %348 = or i64 %347, %344
  %349 = and i64 %348, %345
  %350 = xor i64 %349, %345
  %351 = or i64 %350, %344
  %352 = add i64 %351, %345
  store i64 %352, ptr %3, align 8
  br label %130

353:                                              ; preds = %165
  %354 = load i64, ptr %3, align 8
  %355 = zext i32 %0 to i64
  %356 = ptrtoint ptr %1 to i64
  %357 = xor i64 %356, %354
  %358 = add i64 %357, %356
  %359 = xor i64 %358, %355
  store i64 %359, ptr %3, align 8
  br label %130

360:                                              ; preds = %187
  %361 = load i64, ptr %3, align 8
  %362 = zext i32 %0 to i64
  %363 = ptrtoint ptr %1 to i64
  %364 = mul i64 %362, %362
  %365 = sub i64 %364, %362
  %366 = or i64 %365, %363
  %367 = sub i64 %366, %362
  %368 = add i64 %367, %363
  %369 = or i64 %368, %363
  store i64 %369, ptr %3, align 8
  br label %130

370:                                              ; preds = %198
  %371 = load i64, ptr %3, align 8
  %372 = zext i32 %0 to i64
  %373 = ptrtoint ptr %1 to i64
  %374 = and i64 %373, %372
  %375 = and i64 %374, %372
  %376 = add i64 %375, %372
  store i64 %376, ptr %3, align 8
  br label %130

377:                                              ; preds = %211
  %378 = load i64, ptr %3, align 8
  %379 = zext i32 %0 to i64
  %380 = ptrtoint ptr %1 to i64
  %381 = mul i64 %379, %380
  %382 = and i64 %381, %379
  %383 = xor i64 %382, %378
  store i64 %383, ptr %3, align 8
  br label %130

384:                                              ; preds = %224
  %385 = load i64, ptr %3, align 8
  %386 = zext i32 %0 to i64
  %387 = ptrtoint ptr %1 to i64
  %388 = sub i64 %385, %385
  %389 = and i64 %388, %385
  %390 = sub i64 %389, %386
  %391 = sub i64 %390, %385
  %392 = or i64 %391, %386
  store i64 %392, ptr %3, align 8
  br label %130

393:                                              ; preds = %235
  %394 = load i64, ptr %3, align 8
  %395 = zext i32 %0 to i64
  %396 = ptrtoint ptr %1 to i64
  %397 = or i64 %394, %395
  %398 = sub i64 %397, %395
  %399 = mul i64 %398, %396
  %400 = or i64 %399, %394
  store i64 %400, ptr %3, align 8
  br label %130
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @parse_arguments(i32 noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca ptr, align 8
  %13 = alloca i32, align 4
  %14 = alloca ptr, align 8
  store i32 794618594, ptr %5, align 4
  br label %15

15:                                               ; preds = %1134, %546, %545, %3
  %16 = load i32, ptr %5, align 4
  %17 = sub i32 %16, 335244546
  %18 = mul i32 %17, -608629367
  %19 = icmp slt i32 %18, 964651727
  br i1 %19, label %664, label %666

20:                                               ; preds = %728
  store i32 %0, ptr %6, align 4
  store ptr %1, ptr %7, align 8
  store ptr %2, ptr %8, align 8
  %21 = load ptr, ptr %8, align 8
  call void @options_init(ptr noundef %21)
  store i32 1, ptr %9, align 4
  store i32 238112511, ptr %5, align 4
  %22 = xor i32 %0, 119956451
  %23 = and i32 %0, %22
  %24 = or i32 %0, %22
  %25 = xor i32 %0, %22
  %26 = mul i32 %24, 2
  %27 = sub i32 %26, %25
  %28 = sub i32 %27, %0
  %29 = sub i32 %28, %22
  %30 = mul i32 %29, 100
  %31 = icmp sle i32 %30, 0
  br i1 %31, label %545, label %808

32:                                               ; preds = %768
  %33 = load i32, ptr %9, align 4
  %34 = load i32, ptr %6, align 4
  %35 = icmp slt i32 %33, %34
  %36 = select i1 %35, i32 886064197, i32 996785039
  store i32 %36, ptr %5, align 4
  %37 = xor i32 %0, -117612133
  %38 = and i32 %0, %37
  %39 = or i32 %0, %37
  %40 = xor i32 %0, %37
  %41 = mul i32 %39, 2
  %42 = sub i32 %41, %40
  %43 = sub i32 %42, %0
  %44 = sub i32 %43, %37
  %45 = mul i32 %44, 225
  %46 = icmp slt i32 %45, 0
  br i1 %46, label %817, label %545

47:                                               ; preds = %750
  %48 = load ptr, ptr %7, align 8
  %49 = load i32, ptr %9, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds ptr, ptr %48, i64 %50
  %52 = load ptr, ptr %51, align 8
  store ptr %52, ptr %10, align 8
  %53 = load ptr, ptr %10, align 8
  %54 = call i32 @string_equals(ptr noundef %53, ptr noundef @.str.1)
  %55 = icmp ne i32 %54, 0
  %56 = select i1 %55, i32 1893735761, i32 1698446283
  store i32 %56, ptr %5, align 4
  %57 = xor i32 %0, 170799367
  %58 = and i32 %0, %57
  %59 = or i32 %0, %57
  %60 = xor i32 %0, %57
  %61 = add i32 %0, %57
  %62 = sub i32 %61, %60
  %63 = mul i32 %58, 2
  %64 = sub i32 %62, %63
  %65 = mul i32 %64, 33
  %66 = icmp sle i32 %65, 0
  br i1 %66, label %545, label %825

67:                                               ; preds = %714
  %68 = load ptr, ptr %10, align 8
  %69 = call i32 @string_equals(ptr noundef %68, ptr noundef @.str.2)
  %70 = icmp ne i32 %69, 0
  %71 = select i1 %70, i32 1893735761, i32 -1904486241
  store i32 %71, ptr %5, align 4
  %72 = xor i32 %0, -534434341
  %73 = and i32 %0, %72
  %74 = or i32 %0, %72
  %75 = xor i32 %0, %72
  %76 = add i32 %0, %72
  %77 = sub i32 %76, %75
  %78 = mul i32 %73, 2
  %79 = sub i32 %77, %78
  %80 = mul i32 %79, 184
  %81 = icmp ne i32 %80, 0
  br i1 %81, label %834, label %545

82:                                               ; preds = %762
  %83 = load ptr, ptr %8, align 8
  %84 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %83, i32 0, i32 5
  store i32 1, ptr %84, align 4
  store i32 629019165, ptr %5, align 4
  %85 = xor i32 %0, 64826991
  %86 = and i32 %0, %85
  %87 = or i32 %0, %85
  %88 = xor i32 %0, %85
  %89 = mul i32 %87, 2
  %90 = sub i32 %89, %88
  %91 = sub i32 %90, %0
  %92 = sub i32 %91, %85
  %93 = mul i32 %92, 24
  %94 = icmp ne i32 %93, 0
  br i1 %94, label %844, label %545

95:                                               ; preds = %708
  %96 = load ptr, ptr %10, align 8
  %97 = call i32 @string_equals(ptr noundef %96, ptr noundef @.str.3)
  %98 = icmp ne i32 %97, 0
  %99 = select i1 %98, i32 671365196, i32 -1296123077
  store i32 %99, ptr %5, align 4
  %100 = xor i32 %0, 1808015479
  %101 = and i32 %0, %100
  %102 = or i32 %0, %100
  %103 = xor i32 %0, %100
  %104 = sub i32 %102, %103
  %105 = sub i32 %104, %101
  %106 = mul i32 %105, 33
  %107 = icmp slt i32 %106, 1
  br i1 %107, label %545, label %854

108:                                              ; preds = %766
  %109 = load ptr, ptr %8, align 8
  %110 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %109, i32 0, i32 0
  store i32 1, ptr %110, align 8
  store i32 -1712610151, ptr %5, align 4
  %111 = xor i32 %0, 278663985
  %112 = and i32 %0, %111
  %113 = or i32 %0, %111
  %114 = xor i32 %0, %111
  %115 = add i32 %112, %113
  %116 = sub i32 %115, %0
  %117 = sub i32 %116, %111
  %118 = mul i32 %117, 126
  %119 = icmp eq i32 %118, 0
  br i1 %119, label %545, label %862

120:                                              ; preds = %718
  %121 = load ptr, ptr %10, align 8
  %122 = call i32 @string_equals(ptr noundef %121, ptr noundef @.str.4)
  %123 = icmp ne i32 %122, 0
  %124 = select i1 %123, i32 -1770892416, i32 -1487000039
  store i32 %124, ptr %5, align 4
  %125 = xor i32 %0, -442924341
  %126 = and i32 %0, %125
  %127 = or i32 %0, %125
  %128 = xor i32 %0, %125
  %129 = mul i32 %127, 2
  %130 = sub i32 %129, %128
  %131 = sub i32 %130, %0
  %132 = sub i32 %131, %125
  %133 = mul i32 %132, 9
  %134 = icmp ne i32 %133, 0
  br i1 %134, label %870, label %545

135:                                              ; preds = %734
  %136 = load ptr, ptr %8, align 8
  %137 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %136, i32 0, i32 1
  store i32 1, ptr %137, align 4
  store i32 -834819441, ptr %5, align 4
  %138 = xor i32 %0, 580798329
  %139 = and i32 %0, %138
  %140 = or i32 %0, %138
  %141 = xor i32 %0, %138
  %142 = mul i32 %140, 2
  %143 = sub i32 %142, %141
  %144 = sub i32 %143, %0
  %145 = sub i32 %144, %138
  %146 = mul i32 %145, 4
  %147 = icmp slt i32 %146, 1
  br i1 %147, label %545, label %881

148:                                              ; preds = %694
  %149 = load ptr, ptr %10, align 8
  %150 = call i32 @string_equals(ptr noundef %149, ptr noundef @.str.5)
  %151 = icmp ne i32 %150, 0
  %152 = select i1 %151, i32 298880320, i32 -638668335
  store i32 %152, ptr %5, align 4
  %153 = xor i32 %0, 241152555
  %154 = and i32 %0, %153
  %155 = or i32 %0, %153
  %156 = xor i32 %0, %153
  %157 = add i32 %154, %155
  %158 = sub i32 %157, %0
  %159 = sub i32 %158, %153
  %160 = mul i32 %159, 128
  %161 = xor i32 %0, 1530216953
  %162 = and i32 %0, %161
  %163 = or i32 %0, %161
  %164 = xor i32 %0, %161
  %165 = mul i32 %163, 2
  %166 = sub i32 %165, %164
  %167 = sub i32 %166, %0
  %168 = sub i32 %167, %161
  %169 = mul i32 %168, 141
  %170 = icmp eq i32 %160, %169
  br i1 %170, label %545, label %889

171:                                              ; preds = %676
  %172 = load ptr, ptr %8, align 8
  %173 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %172, i32 0, i32 2
  store i32 1, ptr %173, align 8
  store i32 -321907638, ptr %5, align 4
  %174 = xor i32 %0, -736644295
  %175 = and i32 %0, %174
  %176 = or i32 %0, %174
  %177 = xor i32 %0, %174
  %178 = add i32 %175, %176
  %179 = sub i32 %178, %0
  %180 = sub i32 %179, %174
  %181 = mul i32 %180, 208
  %182 = icmp sle i32 %181, 0
  br i1 %182, label %545, label %898

183:                                              ; preds = %692
  %184 = load ptr, ptr %10, align 8
  %185 = call i32 @string_equals(ptr noundef %184, ptr noundef @.str.6)
  %186 = icmp ne i32 %185, 0
  %187 = select i1 %186, i32 362993953, i32 -1332949889
  store i32 %187, ptr %5, align 4
  %188 = xor i32 %0, -1396794965
  %189 = and i32 %0, %188
  %190 = or i32 %0, %188
  %191 = xor i32 %0, %188
  %192 = add i32 %0, %188
  %193 = sub i32 %192, %191
  %194 = mul i32 %189, 2
  %195 = sub i32 %193, %194
  %196 = mul i32 %195, 58
  %197 = icmp sgt i32 %196, 0
  br i1 %197, label %908, label %545

198:                                              ; preds = %696
  %199 = load ptr, ptr %10, align 8
  %200 = call i32 @string_equals(ptr noundef %199, ptr noundef @.str.7)
  %201 = icmp ne i32 %200, 0
  %202 = select i1 %201, i32 362993953, i32 516878252
  store i32 %202, ptr %5, align 4
  %203 = xor i32 %0, 1561031969
  %204 = and i32 %0, %203
  %205 = or i32 %0, %203
  %206 = xor i32 %0, %203
  %207 = mul i32 %205, 2
  %208 = sub i32 %207, %206
  %209 = sub i32 %208, %0
  %210 = sub i32 %209, %203
  %211 = mul i32 %210, 53
  %212 = xor i32 %0, -18977049
  %213 = and i32 %0, %212
  %214 = or i32 %0, %212
  %215 = xor i32 %0, %212
  %216 = add i32 %0, %212
  %217 = sub i32 %216, %215
  %218 = mul i32 %213, 2
  %219 = sub i32 %217, %218
  %220 = mul i32 %219, 171
  %221 = icmp ne i32 %211, %220
  br i1 %221, label %918, label %545

222:                                              ; preds = %680
  %223 = load ptr, ptr %8, align 8
  %224 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %223, i32 0, i32 3
  store i32 1, ptr %224, align 4
  store i32 -1454918654, ptr %5, align 4
  %225 = xor i32 %0, 1140087759
  %226 = and i32 %0, %225
  %227 = or i32 %0, %225
  %228 = xor i32 %0, %225
  %229 = add i32 %0, %225
  %230 = sub i32 %229, %228
  %231 = mul i32 %226, 2
  %232 = sub i32 %230, %231
  %233 = mul i32 %232, 219
  %234 = icmp slt i32 %233, 0
  br i1 %234, label %926, label %545

235:                                              ; preds = %782
  %236 = load ptr, ptr %10, align 8
  %237 = call i32 @string_equals(ptr noundef %236, ptr noundef @.str.8)
  %238 = icmp ne i32 %237, 0
  %239 = select i1 %238, i32 -735394786, i32 133022839
  store i32 %239, ptr %5, align 4
  %240 = xor i32 %0, -2113215999
  %241 = and i32 %0, %240
  %242 = or i32 %0, %240
  %243 = xor i32 %0, %240
  %244 = add i32 %0, %240
  %245 = sub i32 %244, %243
  %246 = mul i32 %241, 2
  %247 = sub i32 %245, %246
  %248 = mul i32 %247, 12
  %249 = icmp sgt i32 %248, 0
  br i1 %249, label %935, label %545

250:                                              ; preds = %712
  %251 = load ptr, ptr %8, align 8
  %252 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %251, i32 0, i32 4
  store i32 1, ptr %252, align 8
  store i32 -747208558, ptr %5, align 4
  %253 = xor i32 %0, -388146869
  %254 = and i32 %0, %253
  %255 = or i32 %0, %253
  %256 = xor i32 %0, %253
  %257 = mul i32 %255, 2
  %258 = sub i32 %257, %256
  %259 = sub i32 %258, %0
  %260 = sub i32 %259, %253
  %261 = mul i32 %260, 122
  %262 = icmp sle i32 %261, 0
  br i1 %262, label %545, label %945

263:                                              ; preds = %700
  %264 = load ptr, ptr %10, align 8
  %265 = call i32 @string_equals(ptr noundef %264, ptr noundef @.str.9)
  %266 = icmp ne i32 %265, 0
  %267 = select i1 %266, i32 -791775143, i32 -135528580
  store i32 %267, ptr %5, align 4
  %268 = xor i32 %0, -568246481
  %269 = and i32 %0, %268
  %270 = or i32 %0, %268
  %271 = xor i32 %0, %268
  %272 = sub i32 %270, %271
  %273 = sub i32 %272, %269
  %274 = mul i32 %273, 112
  %275 = icmp eq i32 %274, 0
  br i1 %275, label %545, label %955

276:                                              ; preds = %770
  %277 = load ptr, ptr %8, align 8
  call void @options_add_job(ptr noundef %277, i32 noundef 1, ptr noundef null, ptr noundef @.str.10)
  store i32 842707160, ptr %5, align 4
  %278 = xor i32 %0, 734621681
  %279 = and i32 %0, %278
  %280 = or i32 %0, %278
  %281 = xor i32 %0, %278
  %282 = add i32 %279, %280
  %283 = sub i32 %282, %0
  %284 = sub i32 %283, %278
  %285 = mul i32 %284, 79
  %286 = icmp sle i32 %285, 0
  br i1 %286, label %545, label %966

287:                                              ; preds = %796
  %288 = load ptr, ptr %10, align 8
  %289 = call i32 @string_equals(ptr noundef %288, ptr noundef @.str.11)
  %290 = icmp ne i32 %289, 0
  %291 = select i1 %290, i32 -2024079523, i32 1712309909
  store i32 %291, ptr %5, align 4
  %292 = xor i32 %0, 1727830723
  %293 = and i32 %0, %292
  %294 = or i32 %0, %292
  %295 = xor i32 %0, %292
  %296 = sub i32 %294, %295
  %297 = sub i32 %296, %293
  %298 = mul i32 %297, 100
  %299 = icmp uge i32 %298, 0
  br i1 %299, label %545, label %974

300:                                              ; preds = %798
  %301 = load ptr, ptr %10, align 8
  %302 = call i32 @string_equals(ptr noundef %301, ptr noundef @.str.12)
  %303 = icmp ne i32 %302, 0
  %304 = select i1 %303, i32 -2024079523, i32 2083972427
  store i32 %304, ptr %5, align 4
  %305 = xor i32 %0, -1267570053
  %306 = and i32 %0, %305
  %307 = or i32 %0, %305
  %308 = xor i32 %0, %305
  %309 = add i32 %306, %307
  %310 = sub i32 %309, %0
  %311 = sub i32 %310, %305
  %312 = mul i32 %311, 197
  %313 = icmp uge i32 %312, 0
  br i1 %313, label %545, label %982

314:                                              ; preds = %732
  %315 = load i32, ptr %6, align 4
  %316 = load ptr, ptr %7, align 8
  %317 = load i32, ptr %9, align 4
  %318 = load ptr, ptr %10, align 8
  %319 = call i32 @require_next_arg(i32 noundef %315, ptr noundef %316, i32 noundef %317, ptr noundef %318)
  store i32 %319, ptr %11, align 4
  %320 = load ptr, ptr %7, align 8
  %321 = load i32, ptr %11, align 4
  %322 = sext i32 %321 to i64
  %323 = getelementptr inbounds ptr, ptr %320, i64 %322
  %324 = load ptr, ptr %323, align 8
  store ptr %324, ptr %12, align 8
  %325 = load ptr, ptr %8, align 8
  %326 = load ptr, ptr %12, align 8
  %327 = load ptr, ptr %12, align 8
  call void @options_add_job(ptr noundef %325, i32 noundef 2, ptr noundef %326, ptr noundef %327)
  %328 = load i32, ptr %11, align 4
  store i32 %328, ptr %9, align 4
  store i32 565872452, ptr %5, align 4
  %329 = xor i32 %0, 1029375319
  %330 = and i32 %0, %329
  %331 = or i32 %0, %329
  %332 = xor i32 %0, %329
  %333 = add i32 %330, %331
  %334 = sub i32 %333, %0
  %335 = sub i32 %334, %329
  %336 = mul i32 %335, 60
  %337 = xor i32 %0, -1622137095
  %338 = and i32 %0, %337
  %339 = or i32 %0, %337
  %340 = xor i32 %0, %337
  %341 = mul i32 %339, 2
  %342 = sub i32 %341, %340
  %343 = sub i32 %342, %0
  %344 = sub i32 %343, %337
  %345 = mul i32 %344, 123
  %346 = icmp ne i32 %336, %345
  br i1 %346, label %992, label %545

347:                                              ; preds = %724
  %348 = load ptr, ptr %10, align 8
  %349 = call i32 @string_equals(ptr noundef %348, ptr noundef @.str.13)
  %350 = icmp ne i32 %349, 0
  %351 = select i1 %350, i32 -1508967293, i32 620893219
  store i32 %351, ptr %5, align 4
  %352 = xor i32 %0, -307664833
  %353 = and i32 %0, %352
  %354 = or i32 %0, %352
  %355 = xor i32 %0, %352
  %356 = mul i32 %354, 2
  %357 = sub i32 %356, %355
  %358 = sub i32 %357, %0
  %359 = sub i32 %358, %352
  %360 = mul i32 %359, 168
  %361 = icmp slt i32 %360, 0
  br i1 %361, label %1001, label %545

362:                                              ; preds = %800
  %363 = load ptr, ptr %10, align 8
  %364 = call i32 @string_equals(ptr noundef %363, ptr noundef @.str.14)
  %365 = icmp ne i32 %364, 0
  %366 = select i1 %365, i32 -1508967293, i32 -1767779519
  store i32 %366, ptr %5, align 4
  %367 = xor i32 %0, -2113872575
  %368 = and i32 %0, %367
  %369 = or i32 %0, %367
  %370 = xor i32 %0, %367
  %371 = sub i32 %369, %370
  %372 = sub i32 %371, %368
  %373 = mul i32 %372, 43
  %374 = icmp sgt i32 %373, 0
  br i1 %374, label %1011, label %545

375:                                              ; preds = %748
  %376 = load i32, ptr %6, align 4
  %377 = load ptr, ptr %7, align 8
  %378 = load i32, ptr %9, align 4
  %379 = load ptr, ptr %10, align 8
  %380 = call i32 @require_next_arg(i32 noundef %376, ptr noundef %377, i32 noundef %378, ptr noundef %379)
  store i32 %380, ptr %13, align 4
  %381 = load ptr, ptr %7, align 8
  %382 = load i32, ptr %13, align 4
  %383 = sext i32 %382 to i64
  %384 = getelementptr inbounds ptr, ptr %381, i64 %383
  %385 = load ptr, ptr %384, align 8
  store ptr %385, ptr %14, align 8
  %386 = load ptr, ptr %8, align 8
  %387 = load ptr, ptr %14, align 8
  %388 = load ptr, ptr %14, align 8
  call void @options_add_job(ptr noundef %386, i32 noundef 3, ptr noundef %387, ptr noundef %388)
  %389 = load i32, ptr %13, align 4
  store i32 %389, ptr %9, align 4
  store i32 -338721370, ptr %5, align 4
  %390 = xor i32 %0, 439683909
  %391 = and i32 %0, %390
  %392 = or i32 %0, %390
  %393 = xor i32 %0, %390
  %394 = add i32 %391, %392
  %395 = sub i32 %394, %0
  %396 = sub i32 %395, %390
  %397 = mul i32 %396, 64
  %398 = xor i32 %0, 982363493
  %399 = and i32 %0, %398
  %400 = or i32 %0, %398
  %401 = xor i32 %0, %398
  %402 = add i32 %0, %398
  %403 = sub i32 %402, %401
  %404 = mul i32 %399, 2
  %405 = sub i32 %403, %404
  %406 = mul i32 %405, 103
  %407 = icmp eq i32 %397, %406
  br i1 %407, label %545, label %1020

408:                                              ; preds = %702
  %409 = load ptr, ptr %10, align 8
  %410 = call i32 @string_starts_with_dash(ptr noundef %409)
  %411 = icmp ne i32 %410, 0
  %412 = select i1 %411, i32 192611773, i32 788834725
  store i32 %412, ptr %5, align 4
  %413 = xor i32 %0, -2034450679
  %414 = and i32 %0, %413
  %415 = or i32 %0, %413
  %416 = xor i32 %0, %413
  %417 = add i32 %414, %415
  %418 = sub i32 %417, %0
  %419 = sub i32 %418, %413
  %420 = mul i32 %419, 143
  %421 = icmp sle i32 %420, 0
  br i1 %421, label %545, label %1029

422:                                              ; preds = %752
  %423 = load ptr, ptr @stderr, align 8
  %424 = load ptr, ptr %10, align 8
  %425 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %423, ptr noundef @.str.15, ptr noundef %424) #9
  call void @exit(i32 noundef 1) #10
  unreachable

426:                                              ; preds = %730
  %427 = load ptr, ptr %8, align 8
  %428 = load ptr, ptr %10, align 8
  %429 = load ptr, ptr %10, align 8
  call void @options_add_job(ptr noundef %427, i32 noundef 2, ptr noundef %428, ptr noundef %429)
  store i32 -338721370, ptr %5, align 4
  %430 = xor i32 %0, -747122363
  %431 = and i32 %0, %430
  %432 = or i32 %0, %430
  %433 = xor i32 %0, %430
  %434 = sub i32 %432, %433
  %435 = sub i32 %434, %431
  %436 = mul i32 %435, 184
  %437 = icmp slt i32 %436, 0
  br i1 %437, label %1037, label %545

438:                                              ; preds = %764
  store i32 565872452, ptr %5, align 4
  %439 = xor i32 %0, 1177145087
  %440 = and i32 %0, %439
  %441 = or i32 %0, %439
  %442 = xor i32 %0, %439
  %443 = sub i32 %441, %442
  %444 = sub i32 %443, %440
  %445 = mul i32 %444, 177
  %446 = icmp ugt i32 %445, 0
  br i1 %446, label %1048, label %545

447:                                              ; preds = %806
  store i32 842707160, ptr %5, align 4
  %448 = xor i32 %0, -1985814227
  %449 = and i32 %0, %448
  %450 = or i32 %0, %448
  %451 = xor i32 %0, %448
  %452 = add i32 %449, %450
  %453 = sub i32 %452, %0
  %454 = sub i32 %453, %448
  %455 = mul i32 %454, 20
  %456 = icmp slt i32 %455, 0
  br i1 %456, label %1057, label %545

457:                                              ; preds = %804
  store i32 -747208558, ptr %5, align 4
  %458 = xor i32 %0, 820354109
  %459 = and i32 %0, %458
  %460 = or i32 %0, %458
  %461 = xor i32 %0, %458
  %462 = add i32 %459, %460
  %463 = sub i32 %462, %0
  %464 = sub i32 %463, %458
  %465 = mul i32 %464, 66
  %466 = icmp slt i32 %465, 0
  br i1 %466, label %1066, label %545

467:                                              ; preds = %682
  store i32 -1454918654, ptr %5, align 4
  %468 = xor i32 %0, -1071294345
  %469 = and i32 %0, %468
  %470 = or i32 %0, %468
  %471 = xor i32 %0, %468
  %472 = sub i32 %470, %471
  %473 = sub i32 %472, %469
  %474 = mul i32 %473, 174
  %475 = icmp sgt i32 %474, 0
  br i1 %475, label %1074, label %545

476:                                              ; preds = %684
  store i32 -321907638, ptr %5, align 4
  %477 = xor i32 %0, -1203624051
  %478 = and i32 %0, %477
  %479 = or i32 %0, %477
  %480 = xor i32 %0, %477
  %481 = add i32 %478, %479
  %482 = sub i32 %481, %0
  %483 = sub i32 %482, %477
  %484 = mul i32 %483, 79
  %485 = xor i32 %0, 1146468539
  %486 = and i32 %0, %485
  %487 = or i32 %0, %485
  %488 = xor i32 %0, %485
  %489 = mul i32 %487, 2
  %490 = sub i32 %489, %488
  %491 = sub i32 %490, %0
  %492 = sub i32 %491, %485
  %493 = mul i32 %492, 7
  %494 = icmp ne i32 %484, %493
  br i1 %494, label %1085, label %545

495:                                              ; preds = %760
  store i32 -834819441, ptr %5, align 4
  %496 = xor i32 %0, -1446788601
  %497 = and i32 %0, %496
  %498 = or i32 %0, %496
  %499 = xor i32 %0, %496
  %500 = sub i32 %498, %499
  %501 = sub i32 %500, %497
  %502 = mul i32 %501, 78
  %503 = icmp ne i32 %502, 0
  br i1 %503, label %1094, label %545

504:                                              ; preds = %698
  store i32 -1712610151, ptr %5, align 4
  %505 = xor i32 %0, 2098975419
  %506 = and i32 %0, %505
  %507 = or i32 %0, %505
  %508 = xor i32 %0, %505
  %509 = sub i32 %507, %508
  %510 = sub i32 %509, %506
  %511 = mul i32 %510, 55
  %512 = icmp slt i32 %511, 0
  br i1 %512, label %1105, label %545

513:                                              ; preds = %744
  store i32 629019165, ptr %5, align 4
  %514 = xor i32 %0, -1262367563
  %515 = and i32 %0, %514
  %516 = or i32 %0, %514
  %517 = xor i32 %0, %514
  %518 = sub i32 %516, %517
  %519 = sub i32 %518, %515
  %520 = mul i32 %519, 200
  %521 = icmp slt i32 %520, 0
  br i1 %521, label %1114, label %545

522:                                              ; preds = %788
  %523 = load i32, ptr %9, align 4
  %524 = load i32, ptr %5, align 4
  %525 = xor i32 %524, 629019164
  %526 = sub i32 %523, %525
  %527 = load i32, ptr %5, align 4
  %528 = xor i32 %527, 629019167
  %529 = mul i32 %523, %528
  %530 = load i32, ptr %5, align 4
  %531 = xor i32 %530, 629019164
  %532 = mul i32 %531, %526
  %533 = sub i32 %529, %532
  store i32 %533, ptr %9, align 4
  store i32 238112511, ptr %5, align 4
  %534 = xor i32 %0, -2117493405
  %535 = and i32 %0, %534
  %536 = or i32 %0, %534
  %537 = xor i32 %0, %534
  %538 = mul i32 %536, 2
  %539 = sub i32 %538, %537
  %540 = sub i32 %539, %0
  %541 = sub i32 %540, %534
  %542 = mul i32 %541, 203
  %543 = icmp ne i32 %542, 0
  br i1 %543, label %1124, label %545

544:                                              ; preds = %686
  ret void

545:                                              ; preds = %1214, %1203, %1194, %1184, %1174, %1163, %1152, %1143, %1124, %1114, %1105, %1094, %1085, %1074, %1066, %1057, %1048, %1037, %1029, %1020, %1011, %1001, %992, %982, %974, %966, %955, %945, %935, %926, %918, %908, %898, %889, %881, %870, %862, %854, %844, %834, %825, %817, %808, %653, %641, %628, %615, %604, %592, %570, %557, %522, %513, %504, %495, %476, %467, %457, %447, %438, %426, %408, %375, %362, %347, %314, %300, %287, %276, %263, %250, %235, %222, %198, %183, %171, %148, %135, %120, %108, %95, %82, %67, %47, %32, %20
  br label %15

546:                                              ; preds = %806, %802, %800, %796, %790, %786, %784, %780, %770, %766, %764, %760, %754, %750, %748, %734, %730, %728, %724, %718, %714, %712, %702, %698, %696, %692, %686, %682, %680
  store i32 794618594, ptr %5, align 4
  call void asm sideeffect "", ""()
  %547 = xor i32 %0, -1360470705
  %548 = and i32 %0, %547
  %549 = or i32 %0, %547
  %550 = xor i32 %0, %547
  %551 = add i32 %0, %547
  %552 = sub i32 %551, %550
  %553 = mul i32 %548, 2
  %554 = sub i32 %552, %553
  %555 = mul i32 %554, 254
  %556 = icmp sgt i32 %555, 0
  br i1 %556, label %1134, label %15

557:                                              ; preds = %716
  %558 = load i32, ptr %5, align 4
  %559 = xor i32 %558, -771829224
  store i32 %559, ptr %5, align 4
  %560 = xor i32 %0, 332898821
  %561 = and i32 %0, %560
  %562 = or i32 %0, %560
  %563 = xor i32 %0, %560
  %564 = add i32 %0, %560
  %565 = sub i32 %564, %563
  %566 = mul i32 %561, 2
  %567 = sub i32 %565, %566
  %568 = mul i32 %567, 147
  %569 = icmp sle i32 %568, 0
  br i1 %569, label %545, label %1143

570:                                              ; preds = %780
  %571 = load i32, ptr %5, align 4
  %572 = xor i32 %571, 1922382826
  store i32 %572, ptr %5, align 4
  %573 = xor i32 %0, -584902647
  %574 = and i32 %0, %573
  %575 = or i32 %0, %573
  %576 = xor i32 %0, %573
  %577 = add i32 %0, %573
  %578 = sub i32 %577, %576
  %579 = mul i32 %574, 2
  %580 = sub i32 %578, %579
  %581 = mul i32 %580, 151
  %582 = xor i32 %0, 1699094235
  %583 = and i32 %0, %582
  %584 = or i32 %0, %582
  %585 = xor i32 %0, %582
  %586 = mul i32 %584, 2
  %587 = sub i32 %586, %585
  %588 = sub i32 %587, %0
  %589 = sub i32 %588, %582
  %590 = mul i32 %589, 192
  %591 = icmp ne i32 %581, %590
  br i1 %591, label %1152, label %545

592:                                              ; preds = %790
  %593 = load i32, ptr %5, align 4
  %594 = xor i32 %593, -266912977
  store i32 %594, ptr %5, align 4
  %595 = xor i32 %0, 2075317435
  %596 = and i32 %0, %595
  %597 = or i32 %0, %595
  %598 = xor i32 %0, %595
  %599 = add i32 %596, %597
  %600 = sub i32 %599, %0
  %601 = sub i32 %600, %595
  %602 = mul i32 %601, 58
  %603 = icmp eq i32 %602, 0
  br i1 %603, label %545, label %1163

604:                                              ; preds = %786
  %605 = load i32, ptr %5, align 4
  %606 = xor i32 %605, 721126268
  store i32 %606, ptr %5, align 4
  %607 = xor i32 %0, 1734960165
  %608 = and i32 %0, %607
  %609 = or i32 %0, %607
  %610 = xor i32 %0, %607
  %611 = sub i32 %609, %610
  %612 = sub i32 %611, %608
  %613 = mul i32 %612, 109
  %614 = icmp eq i32 %613, 0
  br i1 %614, label %545, label %1174

615:                                              ; preds = %784
  %616 = load i32, ptr %5, align 4
  %617 = xor i32 %616, -1861678523
  store i32 %617, ptr %5, align 4
  %618 = xor i32 %0, 2073870617
  %619 = and i32 %0, %618
  %620 = or i32 %0, %618
  %621 = xor i32 %0, %618
  %622 = mul i32 %620, 2
  %623 = sub i32 %622, %621
  %624 = sub i32 %623, %0
  %625 = sub i32 %624, %618
  %626 = mul i32 %625, 67
  %627 = icmp uge i32 %626, 0
  br i1 %627, label %545, label %1184

628:                                              ; preds = %802
  %629 = load i32, ptr %5, align 4
  %630 = xor i32 %629, 832931470
  store i32 %630, ptr %5, align 4
  %631 = xor i32 %0, -1012976433
  %632 = and i32 %0, %631
  %633 = or i32 %0, %631
  %634 = xor i32 %0, %631
  %635 = mul i32 %633, 2
  %636 = sub i32 %635, %634
  %637 = sub i32 %636, %0
  %638 = sub i32 %637, %631
  %639 = mul i32 %638, 116
  %640 = icmp slt i32 %639, 0
  br i1 %640, label %1194, label %545

641:                                              ; preds = %726
  %642 = load i32, ptr %5, align 4
  %643 = xor i32 %642, -41162483
  store i32 %643, ptr %5, align 4
  %644 = xor i32 %0, -93053997
  %645 = and i32 %0, %644
  %646 = or i32 %0, %644
  %647 = xor i32 %0, %644
  %648 = add i32 %645, %646
  %649 = sub i32 %648, %0
  %650 = sub i32 %649, %644
  %651 = mul i32 %650, 43
  %652 = icmp slt i32 %651, 0
  br i1 %652, label %1203, label %545

653:                                              ; preds = %754
  %654 = load i32, ptr %5, align 4
  %655 = xor i32 %654, 726329946
  store i32 %655, ptr %5, align 4
  %656 = xor i32 %0, 1596078371
  %657 = and i32 %0, %656
  %658 = or i32 %0, %656
  %659 = xor i32 %0, %656
  %660 = sub i32 %658, %659
  %661 = sub i32 %660, %657
  %662 = mul i32 %661, 120
  %663 = icmp sgt i32 %662, 0
  br i1 %663, label %1214, label %545

664:                                              ; preds = %15
  %665 = icmp slt i32 %18, 665161733
  br i1 %665, label %668, label %670

666:                                              ; preds = %15
  %667 = icmp slt i32 %18, 1669554867
  br i1 %667, label %736, label %738

668:                                              ; preds = %664
  %669 = icmp slt i32 %18, 407197127
  br i1 %669, label %672, label %674

670:                                              ; preds = %664
  %671 = icmp slt i32 %18, 749736977
  br i1 %671, label %704, label %706

672:                                              ; preds = %668
  %673 = icmp slt i32 %18, 200001552
  br i1 %673, label %676, label %678

674:                                              ; preds = %668
  %675 = icmp slt i32 %18, 611850613
  br i1 %675, label %688, label %690

676:                                              ; preds = %672
  %677 = icmp eq i32 %18, 8349486
  br i1 %677, label %171, label %680

678:                                              ; preds = %672
  %679 = icmp slt i32 %18, 342687488
  br i1 %679, label %682, label %684

680:                                              ; preds = %676
  %681 = icmp eq i32 %18, 175992727
  br i1 %681, label %222, label %546

682:                                              ; preds = %678
  %683 = icmp eq i32 %18, 200001552
  br i1 %683, label %467, label %546

684:                                              ; preds = %678
  %685 = icmp eq i32 %18, 342687488
  br i1 %685, label %476, label %686

686:                                              ; preds = %684
  %687 = icmp eq i32 %18, 384447093
  br i1 %687, label %544, label %546

688:                                              ; preds = %674
  %689 = icmp slt i32 %18, 440827983
  br i1 %689, label %692, label %694

690:                                              ; preds = %674
  %691 = icmp slt i32 %18, 632209053
  br i1 %691, label %698, label %700

692:                                              ; preds = %688
  %693 = icmp eq i32 %18, 407197127
  br i1 %693, label %183, label %546

694:                                              ; preds = %688
  %695 = icmp eq i32 %18, 440827983
  br i1 %695, label %148, label %696

696:                                              ; preds = %694
  %697 = icmp eq i32 %18, 469398245
  br i1 %697, label %198, label %546

698:                                              ; preds = %690
  %699 = icmp eq i32 %18, 611850613
  br i1 %699, label %504, label %546

700:                                              ; preds = %690
  %701 = icmp eq i32 %18, 632209053
  br i1 %701, label %263, label %702

702:                                              ; preds = %700
  %703 = icmp eq i32 %18, 650439351
  br i1 %703, label %408, label %546

704:                                              ; preds = %670
  %705 = icmp slt i32 %18, 678420113
  br i1 %705, label %708, label %710

706:                                              ; preds = %670
  %707 = icmp slt i32 %18, 852539963
  br i1 %707, label %720, label %722

708:                                              ; preds = %704
  %709 = icmp eq i32 %18, 665161733
  br i1 %709, label %95, label %712

710:                                              ; preds = %704
  %711 = icmp slt i32 %18, 679577690
  br i1 %711, label %714, label %716

712:                                              ; preds = %708
  %713 = icmp eq i32 %18, 670960124
  br i1 %713, label %250, label %546

714:                                              ; preds = %710
  %715 = icmp eq i32 %18, 678420113
  br i1 %715, label %67, label %546

716:                                              ; preds = %710
  %717 = icmp eq i32 %18, 679577690
  br i1 %717, label %557, label %718

718:                                              ; preds = %716
  %719 = icmp eq i32 %18, 732873089
  br i1 %719, label %120, label %546

720:                                              ; preds = %706
  %721 = icmp slt i32 %18, 820677742
  br i1 %721, label %724, label %726

722:                                              ; preds = %706
  %723 = icmp slt i32 %18, 894890419
  br i1 %723, label %730, label %732

724:                                              ; preds = %720
  %725 = icmp eq i32 %18, 749736977
  br i1 %725, label %347, label %546

726:                                              ; preds = %720
  %727 = icmp eq i32 %18, 820677742
  br i1 %727, label %641, label %728

728:                                              ; preds = %726
  %729 = icmp eq i32 %18, 829471968
  br i1 %729, label %20, label %546

730:                                              ; preds = %722
  %731 = icmp eq i32 %18, 852539963
  br i1 %731, label %426, label %546

732:                                              ; preds = %722
  %733 = icmp eq i32 %18, 894890419
  br i1 %733, label %314, label %734

734:                                              ; preds = %732
  %735 = icmp eq i32 %18, 912506734
  br i1 %735, label %135, label %546

736:                                              ; preds = %666
  %737 = icmp slt i32 %18, 1364471176
  br i1 %737, label %740, label %742

738:                                              ; preds = %666
  %739 = icmp slt i32 %18, 1800967498
  br i1 %739, label %772, label %774

740:                                              ; preds = %736
  %741 = icmp slt i32 %18, 1094752731
  br i1 %741, label %744, label %746

742:                                              ; preds = %736
  %743 = icmp slt i32 %18, 1635880090
  br i1 %743, label %756, label %758

744:                                              ; preds = %740
  %745 = icmp eq i32 %18, 964651727
  br i1 %745, label %513, label %748

746:                                              ; preds = %740
  %747 = icmp slt i32 %18, 1177369363
  br i1 %747, label %750, label %752

748:                                              ; preds = %744
  %749 = icmp eq i32 %18, 972708105
  br i1 %749, label %375, label %546

750:                                              ; preds = %746
  %751 = icmp eq i32 %18, 1094752731
  br i1 %751, label %47, label %546

752:                                              ; preds = %746
  %753 = icmp eq i32 %18, 1177369363
  br i1 %753, label %422, label %754

754:                                              ; preds = %752
  %755 = icmp eq i32 %18, 1243892919
  br i1 %755, label %653, label %546

756:                                              ; preds = %742
  %757 = icmp slt i32 %18, 1366121799
  br i1 %757, label %760, label %762

758:                                              ; preds = %742
  %759 = icmp slt i32 %18, 1646578021
  br i1 %759, label %766, label %768

760:                                              ; preds = %756
  %761 = icmp eq i32 %18, 1364471176
  br i1 %761, label %495, label %546

762:                                              ; preds = %756
  %763 = icmp eq i32 %18, 1366121799
  br i1 %763, label %82, label %764

764:                                              ; preds = %762
  %765 = icmp eq i32 %18, 1615168452
  br i1 %765, label %438, label %546

766:                                              ; preds = %758
  %767 = icmp eq i32 %18, 1635880090
  br i1 %767, label %108, label %546

768:                                              ; preds = %758
  %769 = icmp eq i32 %18, 1646578021
  br i1 %769, label %32, label %770

770:                                              ; preds = %768
  %771 = icmp eq i32 %18, 1667464335
  br i1 %771, label %276, label %546

772:                                              ; preds = %738
  %773 = icmp slt i32 %18, 1778597130
  br i1 %773, label %776, label %778

774:                                              ; preds = %738
  %775 = icmp slt i32 %18, 2077063222
  br i1 %775, label %792, label %794

776:                                              ; preds = %772
  %777 = icmp slt i32 %18, 1672318714
  br i1 %777, label %780, label %782

778:                                              ; preds = %772
  %779 = icmp slt i32 %18, 1791998579
  br i1 %779, label %786, label %788

780:                                              ; preds = %776
  %781 = icmp eq i32 %18, 1669554867
  br i1 %781, label %570, label %546

782:                                              ; preds = %776
  %783 = icmp eq i32 %18, 1672318714
  br i1 %783, label %235, label %784

784:                                              ; preds = %782
  %785 = icmp eq i32 %18, 1684073521
  br i1 %785, label %615, label %546

786:                                              ; preds = %778
  %787 = icmp eq i32 %18, 1778597130
  br i1 %787, label %604, label %546

788:                                              ; preds = %778
  %789 = icmp eq i32 %18, 1791998579
  br i1 %789, label %522, label %790

790:                                              ; preds = %788
  %791 = icmp eq i32 %18, 1798434106
  br i1 %791, label %592, label %546

792:                                              ; preds = %774
  %793 = icmp slt i32 %18, 1907058347
  br i1 %793, label %796, label %798

794:                                              ; preds = %774
  %795 = icmp slt i32 %18, 2113088390
  br i1 %795, label %802, label %804

796:                                              ; preds = %792
  %797 = icmp eq i32 %18, 1800967498
  br i1 %797, label %287, label %546

798:                                              ; preds = %792
  %799 = icmp eq i32 %18, 1907058347
  br i1 %799, label %300, label %800

800:                                              ; preds = %798
  %801 = icmp eq i32 %18, 1961172393
  br i1 %801, label %362, label %546

802:                                              ; preds = %794
  %803 = icmp eq i32 %18, 2077063222
  br i1 %803, label %628, label %546

804:                                              ; preds = %794
  %805 = icmp eq i32 %18, 2113088390
  br i1 %805, label %457, label %806

806:                                              ; preds = %804
  %807 = icmp eq i32 %18, 2135713618
  br i1 %807, label %447, label %546

808:                                              ; preds = %20
  %809 = load i64, ptr %4, align 8
  %810 = zext i32 %0 to i64
  %811 = ptrtoint ptr %1 to i64
  %812 = ptrtoint ptr %2 to i64
  %813 = or i64 %809, %812
  %814 = or i64 %813, %810
  %815 = and i64 %814, %809
  %816 = and i64 %815, %810
  store i64 %816, ptr %4, align 8
  br label %545

817:                                              ; preds = %32
  %818 = load i64, ptr %4, align 8
  %819 = zext i32 %0 to i64
  %820 = ptrtoint ptr %1 to i64
  %821 = ptrtoint ptr %2 to i64
  %822 = sub i64 %819, %818
  %823 = add i64 %822, %820
  %824 = or i64 %823, %820
  store i64 %824, ptr %4, align 8
  br label %545

825:                                              ; preds = %47
  %826 = load i64, ptr %4, align 8
  %827 = zext i32 %0 to i64
  %828 = ptrtoint ptr %1 to i64
  %829 = ptrtoint ptr %2 to i64
  %830 = mul i64 %829, %826
  %831 = or i64 %830, %827
  %832 = add i64 %831, %829
  %833 = mul i64 %832, %827
  store i64 %833, ptr %4, align 8
  br label %545

834:                                              ; preds = %67
  %835 = load i64, ptr %4, align 8
  %836 = zext i32 %0 to i64
  %837 = ptrtoint ptr %1 to i64
  %838 = ptrtoint ptr %2 to i64
  %839 = xor i64 %835, %838
  %840 = or i64 %839, %835
  %841 = sub i64 %840, %837
  %842 = mul i64 %841, %836
  %843 = or i64 %842, %837
  store i64 %843, ptr %4, align 8
  br label %545

844:                                              ; preds = %82
  %845 = load i64, ptr %4, align 8
  %846 = zext i32 %0 to i64
  %847 = ptrtoint ptr %1 to i64
  %848 = ptrtoint ptr %2 to i64
  %849 = or i64 %847, %846
  %850 = xor i64 %849, %846
  %851 = add i64 %850, %847
  %852 = and i64 %851, %845
  %853 = and i64 %852, %848
  store i64 %853, ptr %4, align 8
  br label %545

854:                                              ; preds = %95
  %855 = load i64, ptr %4, align 8
  %856 = zext i32 %0 to i64
  %857 = ptrtoint ptr %1 to i64
  %858 = ptrtoint ptr %2 to i64
  %859 = add i64 %857, %856
  %860 = or i64 %859, %857
  %861 = mul i64 %860, %858
  store i64 %861, ptr %4, align 8
  br label %545

862:                                              ; preds = %108
  %863 = load i64, ptr %4, align 8
  %864 = zext i32 %0 to i64
  %865 = ptrtoint ptr %1 to i64
  %866 = ptrtoint ptr %2 to i64
  %867 = and i64 %864, %865
  %868 = or i64 %867, %865
  %869 = xor i64 %868, %864
  store i64 %869, ptr %4, align 8
  br label %545

870:                                              ; preds = %120
  %871 = load i64, ptr %4, align 8
  %872 = zext i32 %0 to i64
  %873 = ptrtoint ptr %1 to i64
  %874 = ptrtoint ptr %2 to i64
  %875 = mul i64 %873, %872
  %876 = mul i64 %875, %873
  %877 = or i64 %876, %871
  %878 = mul i64 %877, %871
  %879 = xor i64 %878, %871
  %880 = sub i64 %879, %871
  store i64 %880, ptr %4, align 8
  br label %545

881:                                              ; preds = %135
  %882 = load i64, ptr %4, align 8
  %883 = zext i32 %0 to i64
  %884 = ptrtoint ptr %1 to i64
  %885 = ptrtoint ptr %2 to i64
  %886 = or i64 %882, %883
  %887 = and i64 %886, %885
  %888 = and i64 %887, %885
  store i64 %888, ptr %4, align 8
  br label %545

889:                                              ; preds = %148
  %890 = load i64, ptr %4, align 8
  %891 = zext i32 %0 to i64
  %892 = ptrtoint ptr %1 to i64
  %893 = ptrtoint ptr %2 to i64
  %894 = xor i64 %890, %890
  %895 = sub i64 %894, %893
  %896 = add i64 %895, %893
  %897 = sub i64 %896, %893
  store i64 %897, ptr %4, align 8
  br label %545

898:                                              ; preds = %171
  %899 = load i64, ptr %4, align 8
  %900 = zext i32 %0 to i64
  %901 = ptrtoint ptr %1 to i64
  %902 = ptrtoint ptr %2 to i64
  %903 = and i64 %902, %900
  %904 = or i64 %903, %902
  %905 = and i64 %904, %902
  %906 = or i64 %905, %899
  %907 = xor i64 %906, %901
  store i64 %907, ptr %4, align 8
  br label %545

908:                                              ; preds = %183
  %909 = load i64, ptr %4, align 8
  %910 = zext i32 %0 to i64
  %911 = ptrtoint ptr %1 to i64
  %912 = ptrtoint ptr %2 to i64
  %913 = mul i64 %912, %910
  %914 = sub i64 %913, %911
  %915 = and i64 %914, %911
  %916 = add i64 %915, %910
  %917 = sub i64 %916, %911
  store i64 %917, ptr %4, align 8
  br label %545

918:                                              ; preds = %198
  %919 = load i64, ptr %4, align 8
  %920 = zext i32 %0 to i64
  %921 = ptrtoint ptr %1 to i64
  %922 = ptrtoint ptr %2 to i64
  %923 = mul i64 %921, %921
  %924 = mul i64 %923, %919
  %925 = add i64 %924, %921
  store i64 %925, ptr %4, align 8
  br label %545

926:                                              ; preds = %222
  %927 = load i64, ptr %4, align 8
  %928 = zext i32 %0 to i64
  %929 = ptrtoint ptr %1 to i64
  %930 = ptrtoint ptr %2 to i64
  %931 = sub i64 %929, %930
  %932 = xor i64 %931, %930
  %933 = xor i64 %932, %929
  %934 = and i64 %933, %930
  store i64 %934, ptr %4, align 8
  br label %545

935:                                              ; preds = %235
  %936 = load i64, ptr %4, align 8
  %937 = zext i32 %0 to i64
  %938 = ptrtoint ptr %1 to i64
  %939 = ptrtoint ptr %2 to i64
  %940 = add i64 %936, %939
  %941 = mul i64 %940, %938
  %942 = and i64 %941, %939
  %943 = or i64 %942, %936
  %944 = sub i64 %943, %939
  store i64 %944, ptr %4, align 8
  br label %545

945:                                              ; preds = %250
  %946 = load i64, ptr %4, align 8
  %947 = zext i32 %0 to i64
  %948 = ptrtoint ptr %1 to i64
  %949 = ptrtoint ptr %2 to i64
  %950 = or i64 %948, %949
  %951 = sub i64 %950, %949
  %952 = add i64 %951, %946
  %953 = add i64 %952, %947
  %954 = sub i64 %953, %946
  store i64 %954, ptr %4, align 8
  br label %545

955:                                              ; preds = %263
  %956 = load i64, ptr %4, align 8
  %957 = zext i32 %0 to i64
  %958 = ptrtoint ptr %1 to i64
  %959 = ptrtoint ptr %2 to i64
  %960 = xor i64 %956, %958
  %961 = mul i64 %960, %956
  %962 = sub i64 %961, %959
  %963 = add i64 %962, %957
  %964 = add i64 %963, %956
  %965 = add i64 %964, %957
  store i64 %965, ptr %4, align 8
  br label %545

966:                                              ; preds = %276
  %967 = load i64, ptr %4, align 8
  %968 = zext i32 %0 to i64
  %969 = ptrtoint ptr %1 to i64
  %970 = ptrtoint ptr %2 to i64
  %971 = xor i64 %967, %967
  %972 = or i64 %971, %969
  %973 = and i64 %972, %970
  store i64 %973, ptr %4, align 8
  br label %545

974:                                              ; preds = %287
  %975 = load i64, ptr %4, align 8
  %976 = zext i32 %0 to i64
  %977 = ptrtoint ptr %1 to i64
  %978 = ptrtoint ptr %2 to i64
  %979 = sub i64 %978, %975
  %980 = sub i64 %979, %977
  %981 = sub i64 %980, %977
  store i64 %981, ptr %4, align 8
  br label %545

982:                                              ; preds = %300
  %983 = load i64, ptr %4, align 8
  %984 = zext i32 %0 to i64
  %985 = ptrtoint ptr %1 to i64
  %986 = ptrtoint ptr %2 to i64
  %987 = xor i64 %983, %983
  %988 = or i64 %987, %985
  %989 = mul i64 %988, %985
  %990 = add i64 %989, %984
  %991 = xor i64 %990, %985
  store i64 %991, ptr %4, align 8
  br label %545

992:                                              ; preds = %314
  %993 = load i64, ptr %4, align 8
  %994 = zext i32 %0 to i64
  %995 = ptrtoint ptr %1 to i64
  %996 = ptrtoint ptr %2 to i64
  %997 = or i64 %995, %993
  %998 = xor i64 %997, %996
  %999 = sub i64 %998, %996
  %1000 = or i64 %999, %994
  store i64 %1000, ptr %4, align 8
  br label %545

1001:                                             ; preds = %347
  %1002 = load i64, ptr %4, align 8
  %1003 = zext i32 %0 to i64
  %1004 = ptrtoint ptr %1 to i64
  %1005 = ptrtoint ptr %2 to i64
  %1006 = sub i64 %1003, %1002
  %1007 = mul i64 %1006, %1002
  %1008 = or i64 %1007, %1005
  %1009 = or i64 %1008, %1005
  %1010 = sub i64 %1009, %1004
  store i64 %1010, ptr %4, align 8
  br label %545

1011:                                             ; preds = %362
  %1012 = load i64, ptr %4, align 8
  %1013 = zext i32 %0 to i64
  %1014 = ptrtoint ptr %1 to i64
  %1015 = ptrtoint ptr %2 to i64
  %1016 = add i64 %1014, %1015
  %1017 = or i64 %1016, %1015
  %1018 = sub i64 %1017, %1013
  %1019 = mul i64 %1018, %1014
  store i64 %1019, ptr %4, align 8
  br label %545

1020:                                             ; preds = %375
  %1021 = load i64, ptr %4, align 8
  %1022 = zext i32 %0 to i64
  %1023 = ptrtoint ptr %1 to i64
  %1024 = ptrtoint ptr %2 to i64
  %1025 = or i64 %1022, %1021
  %1026 = or i64 %1025, %1022
  %1027 = xor i64 %1026, %1024
  %1028 = sub i64 %1027, %1021
  store i64 %1028, ptr %4, align 8
  br label %545

1029:                                             ; preds = %408
  %1030 = load i64, ptr %4, align 8
  %1031 = zext i32 %0 to i64
  %1032 = ptrtoint ptr %1 to i64
  %1033 = ptrtoint ptr %2 to i64
  %1034 = mul i64 %1032, %1032
  %1035 = add i64 %1034, %1033
  %1036 = and i64 %1035, %1031
  store i64 %1036, ptr %4, align 8
  br label %545

1037:                                             ; preds = %426
  %1038 = load i64, ptr %4, align 8
  %1039 = zext i32 %0 to i64
  %1040 = ptrtoint ptr %1 to i64
  %1041 = ptrtoint ptr %2 to i64
  %1042 = or i64 %1041, %1040
  %1043 = or i64 %1042, %1040
  %1044 = or i64 %1043, %1038
  %1045 = and i64 %1044, %1038
  %1046 = mul i64 %1045, %1038
  %1047 = sub i64 %1046, %1041
  store i64 %1047, ptr %4, align 8
  br label %545

1048:                                             ; preds = %438
  %1049 = load i64, ptr %4, align 8
  %1050 = zext i32 %0 to i64
  %1051 = ptrtoint ptr %1 to i64
  %1052 = ptrtoint ptr %2 to i64
  %1053 = and i64 %1051, %1049
  %1054 = and i64 %1053, %1052
  %1055 = mul i64 %1054, %1049
  %1056 = sub i64 %1055, %1051
  store i64 %1056, ptr %4, align 8
  br label %545

1057:                                             ; preds = %447
  %1058 = load i64, ptr %4, align 8
  %1059 = zext i32 %0 to i64
  %1060 = ptrtoint ptr %1 to i64
  %1061 = ptrtoint ptr %2 to i64
  %1062 = add i64 %1058, %1059
  %1063 = xor i64 %1062, %1058
  %1064 = mul i64 %1063, %1059
  %1065 = sub i64 %1064, %1061
  store i64 %1065, ptr %4, align 8
  br label %545

1066:                                             ; preds = %457
  %1067 = load i64, ptr %4, align 8
  %1068 = zext i32 %0 to i64
  %1069 = ptrtoint ptr %1 to i64
  %1070 = ptrtoint ptr %2 to i64
  %1071 = mul i64 %1067, %1070
  %1072 = add i64 %1071, %1069
  %1073 = sub i64 %1072, %1067
  store i64 %1073, ptr %4, align 8
  br label %545

1074:                                             ; preds = %467
  %1075 = load i64, ptr %4, align 8
  %1076 = zext i32 %0 to i64
  %1077 = ptrtoint ptr %1 to i64
  %1078 = ptrtoint ptr %2 to i64
  %1079 = xor i64 %1075, %1077
  %1080 = or i64 %1079, %1076
  %1081 = xor i64 %1080, %1077
  %1082 = add i64 %1081, %1076
  %1083 = mul i64 %1082, %1078
  %1084 = or i64 %1083, %1075
  store i64 %1084, ptr %4, align 8
  br label %545

1085:                                             ; preds = %476
  %1086 = load i64, ptr %4, align 8
  %1087 = zext i32 %0 to i64
  %1088 = ptrtoint ptr %1 to i64
  %1089 = ptrtoint ptr %2 to i64
  %1090 = sub i64 %1089, %1086
  %1091 = or i64 %1090, %1089
  %1092 = and i64 %1091, %1086
  %1093 = add i64 %1092, %1088
  store i64 %1093, ptr %4, align 8
  br label %545

1094:                                             ; preds = %495
  %1095 = load i64, ptr %4, align 8
  %1096 = zext i32 %0 to i64
  %1097 = ptrtoint ptr %1 to i64
  %1098 = ptrtoint ptr %2 to i64
  %1099 = sub i64 %1097, %1098
  %1100 = add i64 %1099, %1095
  %1101 = or i64 %1100, %1097
  %1102 = mul i64 %1101, %1098
  %1103 = mul i64 %1102, %1096
  %1104 = and i64 %1103, %1095
  store i64 %1104, ptr %4, align 8
  br label %545

1105:                                             ; preds = %504
  %1106 = load i64, ptr %4, align 8
  %1107 = zext i32 %0 to i64
  %1108 = ptrtoint ptr %1 to i64
  %1109 = ptrtoint ptr %2 to i64
  %1110 = xor i64 %1107, %1107
  %1111 = sub i64 %1110, %1107
  %1112 = sub i64 %1111, %1107
  %1113 = mul i64 %1112, %1108
  store i64 %1113, ptr %4, align 8
  br label %545

1114:                                             ; preds = %513
  %1115 = load i64, ptr %4, align 8
  %1116 = zext i32 %0 to i64
  %1117 = ptrtoint ptr %1 to i64
  %1118 = ptrtoint ptr %2 to i64
  %1119 = sub i64 %1115, %1118
  %1120 = or i64 %1119, %1115
  %1121 = sub i64 %1120, %1118
  %1122 = add i64 %1121, %1118
  %1123 = mul i64 %1122, %1116
  store i64 %1123, ptr %4, align 8
  br label %545

1124:                                             ; preds = %522
  %1125 = load i64, ptr %4, align 8
  %1126 = zext i32 %0 to i64
  %1127 = ptrtoint ptr %1 to i64
  %1128 = ptrtoint ptr %2 to i64
  %1129 = xor i64 %1125, %1125
  %1130 = and i64 %1129, %1126
  %1131 = mul i64 %1130, %1125
  %1132 = or i64 %1131, %1128
  %1133 = add i64 %1132, %1128
  store i64 %1133, ptr %4, align 8
  br label %545

1134:                                             ; preds = %546
  %1135 = load i64, ptr %4, align 8
  %1136 = zext i32 %0 to i64
  %1137 = ptrtoint ptr %1 to i64
  %1138 = ptrtoint ptr %2 to i64
  %1139 = and i64 %1137, %1138
  %1140 = xor i64 %1139, %1138
  %1141 = add i64 %1140, %1136
  %1142 = mul i64 %1141, %1135
  store i64 %1142, ptr %4, align 8
  br label %15

1143:                                             ; preds = %557
  %1144 = load i64, ptr %4, align 8
  %1145 = zext i32 %0 to i64
  %1146 = ptrtoint ptr %1 to i64
  %1147 = ptrtoint ptr %2 to i64
  %1148 = or i64 %1144, %1146
  %1149 = mul i64 %1148, %1147
  %1150 = xor i64 %1149, %1144
  %1151 = add i64 %1150, %1146
  store i64 %1151, ptr %4, align 8
  br label %545

1152:                                             ; preds = %570
  %1153 = load i64, ptr %4, align 8
  %1154 = zext i32 %0 to i64
  %1155 = ptrtoint ptr %1 to i64
  %1156 = ptrtoint ptr %2 to i64
  %1157 = add i64 %1156, %1154
  %1158 = or i64 %1157, %1156
  %1159 = add i64 %1158, %1156
  %1160 = sub i64 %1159, %1153
  %1161 = mul i64 %1160, %1154
  %1162 = or i64 %1161, %1156
  store i64 %1162, ptr %4, align 8
  br label %545

1163:                                             ; preds = %592
  %1164 = load i64, ptr %4, align 8
  %1165 = zext i32 %0 to i64
  %1166 = ptrtoint ptr %1 to i64
  %1167 = ptrtoint ptr %2 to i64
  %1168 = add i64 %1167, %1167
  %1169 = mul i64 %1168, %1166
  %1170 = add i64 %1169, %1164
  %1171 = mul i64 %1170, %1165
  %1172 = xor i64 %1171, %1166
  %1173 = or i64 %1172, %1166
  store i64 %1173, ptr %4, align 8
  br label %545

1174:                                             ; preds = %604
  %1175 = load i64, ptr %4, align 8
  %1176 = zext i32 %0 to i64
  %1177 = ptrtoint ptr %1 to i64
  %1178 = ptrtoint ptr %2 to i64
  %1179 = and i64 %1178, %1177
  %1180 = and i64 %1179, %1175
  %1181 = mul i64 %1180, %1175
  %1182 = sub i64 %1181, %1178
  %1183 = and i64 %1182, %1178
  store i64 %1183, ptr %4, align 8
  br label %545

1184:                                             ; preds = %615
  %1185 = load i64, ptr %4, align 8
  %1186 = zext i32 %0 to i64
  %1187 = ptrtoint ptr %1 to i64
  %1188 = ptrtoint ptr %2 to i64
  %1189 = mul i64 %1188, %1185
  %1190 = sub i64 %1189, %1188
  %1191 = sub i64 %1190, %1187
  %1192 = mul i64 %1191, %1188
  %1193 = and i64 %1192, %1185
  store i64 %1193, ptr %4, align 8
  br label %545

1194:                                             ; preds = %628
  %1195 = load i64, ptr %4, align 8
  %1196 = zext i32 %0 to i64
  %1197 = ptrtoint ptr %1 to i64
  %1198 = ptrtoint ptr %2 to i64
  %1199 = add i64 %1195, %1195
  %1200 = add i64 %1199, %1197
  %1201 = or i64 %1200, %1197
  %1202 = xor i64 %1201, %1198
  store i64 %1202, ptr %4, align 8
  br label %545

1203:                                             ; preds = %641
  %1204 = load i64, ptr %4, align 8
  %1205 = zext i32 %0 to i64
  %1206 = ptrtoint ptr %1 to i64
  %1207 = ptrtoint ptr %2 to i64
  %1208 = xor i64 %1206, %1204
  %1209 = mul i64 %1208, %1205
  %1210 = or i64 %1209, %1204
  %1211 = xor i64 %1210, %1207
  %1212 = or i64 %1211, %1204
  %1213 = or i64 %1212, %1207
  store i64 %1213, ptr %4, align 8
  br label %545

1214:                                             ; preds = %653
  %1215 = load i64, ptr %4, align 8
  %1216 = zext i32 %0 to i64
  %1217 = ptrtoint ptr %1 to i64
  %1218 = ptrtoint ptr %2 to i64
  %1219 = or i64 %1217, %1218
  %1220 = sub i64 %1219, %1215
  %1221 = or i64 %1220, %1216
  %1222 = add i64 %1221, %1217
  store i64 %1222, ptr %4, align 8
  br label %545
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
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  store i32 157798548, ptr %4, align 4
  br label %7

7:                                                ; preds = %273, %112, %111, %1
  %8 = load i32, ptr %4, align 4
  %9 = sub i32 %8, 468870988
  %10 = mul i32 %9, -313080715
  switch i32 %10, label %112 [
    i32 1903443432, label %11
    i32 127237265, label %33
    i32 1190193303, label %44
    i32 70557149, label %55
    i32 1817726718, label %79
    i32 1336938275, label %97
    i32 132533464, label %110
    i32 817180379, label %123
    i32 713617209, label %141
    i32 2110794420, label %154
    i32 1691023752, label %167
    i32 987610922, label %179
    i32 362526073, label %192
    i32 992818818, label %205
  ]

11:                                               ; preds = %7
  store ptr %0, ptr %5, align 8
  %12 = load ptr, ptr %5, align 8
  %13 = icmp eq ptr %12, null
  %14 = select i1 %13, i32 944049017, i32 34131623
  store i32 %14, ptr %4, align 4
  %15 = xor i32 %3, 296131899
  %16 = and i32 %3, %15
  %17 = or i32 %3, %15
  %18 = xor i32 %3, %15
  %19 = add i32 %16, %17
  %20 = sub i32 %19, %3
  %21 = sub i32 %20, %15
  %22 = mul i32 %21, 93
  %23 = xor i32 %3, 1266371437
  %24 = and i32 %3, %23
  %25 = or i32 %3, %23
  %26 = xor i32 %3, %23
  %27 = add i32 %3, %23
  %28 = sub i32 %27, %26
  %29 = mul i32 %24, 2
  %30 = sub i32 %28, %29
  %31 = mul i32 %30, 156
  %32 = icmp eq i32 %22, %31
  br i1 %32, label %111, label %227

33:                                               ; preds = %7
  store i32 -1497037372, ptr %4, align 4
  %34 = xor i32 %3, 1590414957
  %35 = and i32 %3, %34
  %36 = or i32 %3, %34
  %37 = xor i32 %3, %34
  %38 = add i32 %3, %34
  %39 = sub i32 %38, %37
  %40 = mul i32 %35, 2
  %41 = sub i32 %39, %40
  %42 = mul i32 %41, 24
  %43 = icmp sle i32 %42, 0
  br i1 %43, label %111, label %235

44:                                               ; preds = %7
  store i64 0, ptr %6, align 8
  store i32 617713173, ptr %4, align 4
  %45 = xor i32 %3, -1016806023
  %46 = and i32 %3, %45
  %47 = or i32 %3, %45
  %48 = xor i32 %3, %45
  %49 = add i32 %3, %45
  %50 = sub i32 %49, %48
  %51 = mul i32 %46, 2
  %52 = sub i32 %50, %51
  %53 = mul i32 %52, 84
  %54 = icmp slt i32 %53, 1
  br i1 %54, label %111, label %242

55:                                               ; preds = %7
  %56 = load i64, ptr %6, align 8
  %57 = load ptr, ptr %5, align 8
  %58 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %57, i32 0, i32 7
  %59 = load i64, ptr %58, align 8
  %60 = icmp ult i64 %56, %59
  %61 = select i1 %60, i32 -2106080622, i32 -2092197501
  store i32 %61, ptr %4, align 4
  %62 = xor i32 %3, -1571534381
  %63 = and i32 %3, %62
  %64 = or i32 %3, %62
  %65 = xor i32 %3, %62
  %66 = add i32 %3, %62
  %67 = sub i32 %66, %65
  %68 = mul i32 %63, 2
  %69 = sub i32 %67, %68
  %70 = mul i32 %69, 76
  %71 = xor i32 %3, -46485559
  %72 = and i32 %3, %71
  %73 = or i32 %3, %71
  %74 = xor i32 %3, %71
  %75 = sub i32 %73, %74
  %76 = sub i32 %75, %72
  %77 = mul i32 %76, 48
  %78 = icmp ne i32 %70, %77
  br i1 %78, label %250, label %111

79:                                               ; preds = %7
  %80 = load ptr, ptr %5, align 8
  %81 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %80, i32 0, i32 6
  %82 = load i64, ptr %6, align 8
  %83 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %81, i64 0, i64 %82
  call void @free_input_job(ptr noundef %83)
  %84 = load i64, ptr %6, align 8
  %85 = xor i64 %84, 1
  %86 = and i64 %84, 1
  %87 = add i64 %86, %86
  %88 = add i64 %85, %87
  store i64 %88, ptr %6, align 8
  store i32 617713173, ptr %4, align 4
  %89 = xor i32 %3, -195982495
  %90 = and i32 %3, %89
  %91 = or i32 %3, %89
  %92 = xor i32 %3, %89
  %93 = sub i32 %91, %92
  %94 = sub i32 %93, %90
  %95 = mul i32 %94, 3
  %96 = icmp sle i32 %95, 0
  br i1 %96, label %111, label %259

97:                                               ; preds = %7
  %98 = load ptr, ptr %5, align 8
  %99 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %98, i32 0, i32 7
  store i64 0, ptr %99, align 8
  store i32 -1497037372, ptr %4, align 4
  %100 = xor i32 %3, 682893347
  %101 = and i32 %3, %100
  %102 = or i32 %3, %100
  %103 = xor i32 %3, %100
  %104 = mul i32 %102, 2
  %105 = sub i32 %104, %103
  %106 = sub i32 %105, %3
  %107 = sub i32 %106, %100
  %108 = mul i32 %107, 119
  %109 = icmp sgt i32 %108, 0
  br i1 %109, label %265, label %111

110:                                              ; preds = %7
  ret void

111:                                              ; preds = %328, %320, %311, %302, %295, %287, %279, %265, %259, %250, %242, %235, %227, %205, %192, %179, %167, %154, %141, %123, %97, %79, %55, %44, %33, %11
  br label %7

112:                                              ; preds = %7
  store i32 157798548, ptr %4, align 4
  call void asm sideeffect "", ""()
  %113 = xor i32 %3, 1819536223
  %114 = and i32 %3, %113
  %115 = or i32 %3, %113
  %116 = xor i32 %3, %113
  %117 = mul i32 %115, 2
  %118 = sub i32 %117, %116
  %119 = sub i32 %118, %3
  %120 = sub i32 %119, %113
  %121 = mul i32 %120, 151
  %122 = icmp slt i32 %121, 1
  br i1 %122, label %7, label %273

123:                                              ; preds = %7
  %124 = load i32, ptr %4, align 4
  %125 = xor i32 %124, -2058620055
  store i32 %125, ptr %4, align 4
  %126 = xor i32 %3, 830623425
  %127 = and i32 %3, %126
  %128 = or i32 %3, %126
  %129 = xor i32 %3, %126
  %130 = sub i32 %128, %129
  %131 = sub i32 %130, %127
  %132 = mul i32 %131, 186
  %133 = xor i32 %3, 835004753
  %134 = and i32 %3, %133
  %135 = or i32 %3, %133
  %136 = xor i32 %3, %133
  %137 = sub i32 %135, %136
  %138 = sub i32 %137, %134
  %139 = mul i32 %138, 135
  %140 = icmp eq i32 %132, %139
  br i1 %140, label %111, label %279

141:                                              ; preds = %7
  %142 = load i32, ptr %4, align 4
  %143 = xor i32 %142, -46635787
  store i32 %143, ptr %4, align 4
  %144 = xor i32 %3, 539833731
  %145 = and i32 %3, %144
  %146 = or i32 %3, %144
  %147 = xor i32 %3, %144
  %148 = add i32 %3, %144
  %149 = sub i32 %148, %147
  %150 = mul i32 %145, 2
  %151 = sub i32 %149, %150
  %152 = mul i32 %151, 59
  %153 = icmp eq i32 %152, 0
  br i1 %153, label %111, label %287

154:                                              ; preds = %7
  %155 = load i32, ptr %4, align 4
  %156 = xor i32 %155, -149145371
  store i32 %156, ptr %4, align 4
  %157 = xor i32 %3, -1638386133
  %158 = and i32 %3, %157
  %159 = or i32 %3, %157
  %160 = xor i32 %3, %157
  %161 = add i32 %3, %157
  %162 = sub i32 %161, %160
  %163 = mul i32 %158, 2
  %164 = sub i32 %162, %163
  %165 = mul i32 %164, 76
  %166 = icmp slt i32 %165, 0
  br i1 %166, label %295, label %111

167:                                              ; preds = %7
  %168 = load i32, ptr %4, align 4
  %169 = xor i32 %168, 549096590
  store i32 %169, ptr %4, align 4
  %170 = xor i32 %3, -545799375
  %171 = and i32 %3, %170
  %172 = or i32 %3, %170
  %173 = xor i32 %3, %170
  %174 = add i32 %171, %172
  %175 = sub i32 %174, %3
  %176 = sub i32 %175, %170
  %177 = mul i32 %176, 10
  %178 = icmp ne i32 %177, 0
  br i1 %178, label %302, label %111

179:                                              ; preds = %7
  %180 = load i32, ptr %4, align 4
  %181 = xor i32 %180, -436223994
  store i32 %181, ptr %4, align 4
  %182 = xor i32 %3, 459253481
  %183 = and i32 %3, %182
  %184 = or i32 %3, %182
  %185 = xor i32 %3, %182
  %186 = mul i32 %184, 2
  %187 = sub i32 %186, %185
  %188 = sub i32 %187, %3
  %189 = sub i32 %188, %182
  %190 = mul i32 %189, 127
  %191 = icmp sle i32 %190, 0
  br i1 %191, label %111, label %311

192:                                              ; preds = %7
  %193 = load i32, ptr %4, align 4
  %194 = xor i32 %193, -1841381051
  store i32 %194, ptr %4, align 4
  %195 = xor i32 %3, 415980527
  %196 = and i32 %3, %195
  %197 = or i32 %3, %195
  %198 = xor i32 %3, %195
  %199 = mul i32 %197, 2
  %200 = sub i32 %199, %198
  %201 = sub i32 %200, %3
  %202 = sub i32 %201, %195
  %203 = mul i32 %202, 54
  %204 = icmp sgt i32 %203, 0
  br i1 %204, label %320, label %111

205:                                              ; preds = %7
  %206 = load i32, ptr %4, align 4
  %207 = xor i32 %206, 1507034266
  store i32 %207, ptr %4, align 4
  %208 = xor i32 %3, 733679319
  %209 = and i32 %3, %208
  %210 = or i32 %3, %208
  %211 = xor i32 %3, %208
  %212 = add i32 %3, %208
  %213 = sub i32 %212, %211
  %214 = mul i32 %209, 2
  %215 = sub i32 %213, %214
  %216 = mul i32 %215, 233
  %217 = xor i32 %3, -1283902589
  %218 = and i32 %3, %217
  %219 = or i32 %3, %217
  %220 = xor i32 %3, %217
  %221 = add i32 %3, %217
  %222 = sub i32 %221, %220
  %223 = mul i32 %218, 2
  %224 = sub i32 %222, %223
  %225 = mul i32 %224, 153
  %226 = icmp eq i32 %216, %225
  br i1 %226, label %111, label %328

227:                                              ; preds = %11
  %228 = load i64, ptr %2, align 8
  %229 = ptrtoint ptr %0 to i64
  %230 = add i64 %229, %228
  %231 = or i64 %230, %228
  %232 = xor i64 %231, %228
  %233 = sub i64 %232, %229
  %234 = add i64 %233, %228
  store i64 %234, ptr %2, align 8
  br label %111

235:                                              ; preds = %33
  %236 = load i64, ptr %2, align 8
  %237 = ptrtoint ptr %0 to i64
  %238 = and i64 %237, %236
  %239 = xor i64 %238, %236
  %240 = mul i64 %239, %236
  %241 = xor i64 %240, %237
  store i64 %241, ptr %2, align 8
  br label %111

242:                                              ; preds = %44
  %243 = load i64, ptr %2, align 8
  %244 = ptrtoint ptr %0 to i64
  %245 = add i64 %244, %244
  %246 = mul i64 %245, %244
  %247 = and i64 %246, %243
  %248 = and i64 %247, %244
  %249 = or i64 %248, %243
  store i64 %249, ptr %2, align 8
  br label %111

250:                                              ; preds = %55
  %251 = load i64, ptr %2, align 8
  %252 = ptrtoint ptr %0 to i64
  %253 = add i64 %251, %251
  %254 = add i64 %253, %251
  %255 = xor i64 %254, %251
  %256 = sub i64 %255, %251
  %257 = mul i64 %256, %251
  %258 = add i64 %257, %251
  store i64 %258, ptr %2, align 8
  br label %111

259:                                              ; preds = %79
  %260 = load i64, ptr %2, align 8
  %261 = ptrtoint ptr %0 to i64
  %262 = and i64 %261, %261
  %263 = mul i64 %262, %260
  %264 = add i64 %263, %261
  store i64 %264, ptr %2, align 8
  br label %111

265:                                              ; preds = %97
  %266 = load i64, ptr %2, align 8
  %267 = ptrtoint ptr %0 to i64
  %268 = mul i64 %267, %267
  %269 = sub i64 %268, %267
  %270 = sub i64 %269, %266
  %271 = and i64 %270, %267
  %272 = or i64 %271, %267
  store i64 %272, ptr %2, align 8
  br label %111

273:                                              ; preds = %112
  %274 = load i64, ptr %2, align 8
  %275 = ptrtoint ptr %0 to i64
  %276 = mul i64 %275, %275
  %277 = or i64 %276, %274
  %278 = and i64 %277, %275
  store i64 %278, ptr %2, align 8
  br label %7

279:                                              ; preds = %123
  %280 = load i64, ptr %2, align 8
  %281 = ptrtoint ptr %0 to i64
  %282 = add i64 %280, %281
  %283 = xor i64 %282, %280
  %284 = xor i64 %283, %280
  %285 = sub i64 %284, %281
  %286 = add i64 %285, %281
  store i64 %286, ptr %2, align 8
  br label %111

287:                                              ; preds = %141
  %288 = load i64, ptr %2, align 8
  %289 = ptrtoint ptr %0 to i64
  %290 = sub i64 %289, %288
  %291 = mul i64 %290, %288
  %292 = or i64 %291, %289
  %293 = sub i64 %292, %288
  %294 = xor i64 %293, %289
  store i64 %294, ptr %2, align 8
  br label %111

295:                                              ; preds = %154
  %296 = load i64, ptr %2, align 8
  %297 = ptrtoint ptr %0 to i64
  %298 = add i64 %296, %297
  %299 = sub i64 %298, %296
  %300 = and i64 %299, %297
  %301 = add i64 %300, %297
  store i64 %301, ptr %2, align 8
  br label %111

302:                                              ; preds = %167
  %303 = load i64, ptr %2, align 8
  %304 = ptrtoint ptr %0 to i64
  %305 = mul i64 %303, %304
  %306 = xor i64 %305, %303
  %307 = mul i64 %306, %304
  %308 = sub i64 %307, %304
  %309 = sub i64 %308, %303
  %310 = or i64 %309, %303
  store i64 %310, ptr %2, align 8
  br label %111

311:                                              ; preds = %179
  %312 = load i64, ptr %2, align 8
  %313 = ptrtoint ptr %0 to i64
  %314 = sub i64 %312, %313
  %315 = xor i64 %314, %312
  %316 = or i64 %315, %312
  %317 = sub i64 %316, %313
  %318 = and i64 %317, %312
  %319 = or i64 %318, %313
  store i64 %319, ptr %2, align 8
  br label %111

320:                                              ; preds = %192
  %321 = load i64, ptr %2, align 8
  %322 = ptrtoint ptr %0 to i64
  %323 = add i64 %321, %321
  %324 = xor i64 %323, %322
  %325 = and i64 %324, %321
  %326 = add i64 %325, %322
  %327 = add i64 %326, %322
  store i64 %327, ptr %2, align 8
  br label %111

328:                                              ; preds = %205
  %329 = load i64, ptr %2, align 8
  %330 = ptrtoint ptr %0 to i64
  %331 = add i64 %329, %330
  %332 = sub i64 %331, %330
  %333 = or i64 %332, %330
  %334 = sub i64 %333, %329
  store i64 %334, ptr %2, align 8
  br label %111
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @validate_options(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  store i32 -515532304, ptr %4, align 4
  br label %7

7:                                                ; preds = %391, %147, %146, %1
  %8 = load i32, ptr %4, align 4
  %9 = sub i32 %8, -1279150692
  %10 = mul i32 %9, 881973769
  %11 = icmp slt i32 %10, 1302761204
  br i1 %11, label %272, label %274

12:                                               ; preds = %304
  store ptr %0, ptr %6, align 8
  %13 = load ptr, ptr %6, align 8
  %14 = icmp eq ptr %13, null
  %15 = select i1 %14, i32 1682480159, i32 1231464208
  store i32 %15, ptr %4, align 4
  %16 = xor i32 %3, 651318381
  %17 = and i32 %3, %16
  %18 = or i32 %3, %16
  %19 = xor i32 %3, %16
  %20 = sub i32 %18, %19
  %21 = sub i32 %20, %17
  %22 = mul i32 %21, 160
  %23 = icmp sle i32 %22, 0
  br i1 %23, label %146, label %324

24:                                               ; preds = %296
  %25 = load ptr, ptr @stderr, align 8
  %26 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %25, ptr noundef @.str.43) #9
  store i32 1, ptr %5, align 4
  store i32 -1500356543, ptr %4, align 4
  %27 = xor i32 %3, -760304641
  %28 = and i32 %3, %27
  %29 = or i32 %3, %27
  %30 = xor i32 %3, %27
  %31 = add i32 %3, %27
  %32 = sub i32 %31, %30
  %33 = mul i32 %28, 2
  %34 = sub i32 %32, %33
  %35 = mul i32 %34, 104
  %36 = xor i32 %3, 1834318763
  %37 = and i32 %3, %36
  %38 = or i32 %3, %36
  %39 = xor i32 %3, %36
  %40 = add i32 %3, %36
  %41 = sub i32 %40, %39
  %42 = mul i32 %37, 2
  %43 = sub i32 %41, %42
  %44 = mul i32 %43, 41
  %45 = icmp eq i32 %35, %44
  br i1 %45, label %146, label %332

46:                                               ; preds = %282
  %47 = load ptr, ptr %6, align 8
  %48 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %47, i32 0, i32 2
  %49 = load i32, ptr %48, align 8
  %50 = icmp ne i32 %49, 0
  %51 = select i1 %50, i32 -221454296, i32 406425612
  store i32 %51, ptr %4, align 4
  %52 = xor i32 %3, -1804912239
  %53 = and i32 %3, %52
  %54 = or i32 %3, %52
  %55 = xor i32 %3, %52
  %56 = add i32 %3, %52
  %57 = sub i32 %56, %55
  %58 = mul i32 %53, 2
  %59 = sub i32 %57, %58
  %60 = mul i32 %59, 128
  %61 = icmp ugt i32 %60, 0
  br i1 %61, label %339, label %146

62:                                               ; preds = %298
  %63 = load ptr, ptr %6, align 8
  %64 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %63, i32 0, i32 7
  %65 = load i64, ptr %64, align 8
  %66 = icmp ugt i64 %65, 1
  %67 = select i1 %66, i32 131307392, i32 406425612
  store i32 %67, ptr %4, align 4
  %68 = xor i32 %3, -50389475
  %69 = and i32 %3, %68
  %70 = or i32 %3, %68
  %71 = xor i32 %3, %68
  %72 = add i32 %3, %68
  %73 = sub i32 %72, %71
  %74 = mul i32 %69, 2
  %75 = sub i32 %73, %74
  %76 = mul i32 %75, 224
  %77 = icmp eq i32 %76, 0
  br i1 %77, label %146, label %345

78:                                               ; preds = %316
  %79 = load ptr, ptr @stderr, align 8
  %80 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %79, ptr noundef @.str.44) #9
  store i32 1, ptr %5, align 4
  store i32 -1500356543, ptr %4, align 4
  %81 = xor i32 %3, 1249952181
  %82 = and i32 %3, %81
  %83 = or i32 %3, %81
  %84 = xor i32 %3, %81
  %85 = add i32 %82, %83
  %86 = sub i32 %85, %3
  %87 = sub i32 %86, %81
  %88 = mul i32 %87, 66
  %89 = icmp eq i32 %88, 0
  br i1 %89, label %146, label %351

90:                                               ; preds = %286
  %91 = load ptr, ptr %6, align 8
  %92 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %91, i32 0, i32 2
  %93 = load i32, ptr %92, align 8
  %94 = icmp ne i32 %93, 0
  %95 = select i1 %94, i32 -678573460, i32 2045178082
  store i32 %95, ptr %4, align 4
  %96 = xor i32 %3, -82039759
  %97 = and i32 %3, %96
  %98 = or i32 %3, %96
  %99 = xor i32 %3, %96
  %100 = add i32 %3, %96
  %101 = sub i32 %100, %99
  %102 = mul i32 %97, 2
  %103 = sub i32 %101, %102
  %104 = mul i32 %103, 209
  %105 = icmp sgt i32 %104, 0
  br i1 %105, label %360, label %146

106:                                              ; preds = %288
  %107 = load ptr, ptr %6, align 8
  %108 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %107, i32 0, i32 4
  %109 = load i32, ptr %108, align 8
  %110 = icmp ne i32 %109, 0
  %111 = select i1 %110, i32 1621703046, i32 2045178082
  store i32 %111, ptr %4, align 4
  %112 = xor i32 %3, -278484285
  %113 = and i32 %3, %112
  %114 = or i32 %3, %112
  %115 = xor i32 %3, %112
  %116 = sub i32 %114, %115
  %117 = sub i32 %116, %113
  %118 = mul i32 %117, 51
  %119 = icmp ne i32 %118, 0
  br i1 %119, label %366, label %146

120:                                              ; preds = %322
  %121 = load ptr, ptr @stderr, align 8
  %122 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %121, ptr noundef @.str.45) #9
  store i32 1, ptr %5, align 4
  store i32 -1500356543, ptr %4, align 4
  %123 = xor i32 %3, -1272117977
  %124 = and i32 %3, %123
  %125 = or i32 %3, %123
  %126 = xor i32 %3, %123
  %127 = mul i32 %125, 2
  %128 = sub i32 %127, %126
  %129 = sub i32 %128, %3
  %130 = sub i32 %129, %123
  %131 = mul i32 %130, 105
  %132 = icmp slt i32 %131, 0
  br i1 %132, label %373, label %146

133:                                              ; preds = %318
  store i32 0, ptr %5, align 4
  store i32 -1500356543, ptr %4, align 4
  %134 = xor i32 %3, 1608018167
  %135 = and i32 %3, %134
  %136 = or i32 %3, %134
  %137 = xor i32 %3, %134
  %138 = mul i32 %136, 2
  %139 = sub i32 %138, %137
  %140 = sub i32 %139, %3
  %141 = sub i32 %140, %134
  %142 = mul i32 %141, 124
  %143 = icmp sle i32 %142, 0
  br i1 %143, label %146, label %382

144:                                              ; preds = %306
  %145 = load i32, ptr %5, align 4
  ret i32 %145

146:                                              ; preds = %448, %442, %436, %429, %422, %415, %408, %400, %382, %373, %366, %360, %351, %345, %339, %332, %324, %259, %247, %227, %214, %203, %190, %177, %164, %133, %120, %106, %90, %78, %62, %46, %24, %12
  br label %7

147:                                              ; preds = %322, %318, %316, %310, %308, %298, %294, %292, %286, %284
  store i32 -515532304, ptr %4, align 4
  call void asm sideeffect "", ""()
  %148 = xor i32 %3, 1459677839
  %149 = and i32 %3, %148
  %150 = or i32 %3, %148
  %151 = xor i32 %3, %148
  %152 = sub i32 %150, %151
  %153 = sub i32 %152, %149
  %154 = mul i32 %153, 169
  %155 = xor i32 %3, 2110888043
  %156 = and i32 %3, %155
  %157 = or i32 %3, %155
  %158 = xor i32 %3, %155
  %159 = add i32 %156, %157
  %160 = sub i32 %159, %3
  %161 = sub i32 %160, %155
  %162 = mul i32 %161, 81
  %163 = icmp ne i32 %154, %162
  br i1 %163, label %391, label %7

164:                                              ; preds = %310
  %165 = load i32, ptr %4, align 4
  %166 = xor i32 %165, 1241260173
  store i32 %166, ptr %4, align 4
  %167 = xor i32 %3, 595107743
  %168 = and i32 %3, %167
  %169 = or i32 %3, %167
  %170 = xor i32 %3, %167
  %171 = mul i32 %169, 2
  %172 = sub i32 %171, %170
  %173 = sub i32 %172, %3
  %174 = sub i32 %173, %167
  %175 = mul i32 %174, 101
  %176 = icmp ugt i32 %175, 0
  br i1 %176, label %400, label %146

177:                                              ; preds = %280
  %178 = load i32, ptr %4, align 4
  %179 = xor i32 %178, 1760430395
  store i32 %179, ptr %4, align 4
  %180 = xor i32 %3, -867066643
  %181 = and i32 %3, %180
  %182 = or i32 %3, %180
  %183 = xor i32 %3, %180
  %184 = mul i32 %182, 2
  %185 = sub i32 %184, %183
  %186 = sub i32 %185, %3
  %187 = sub i32 %186, %180
  %188 = mul i32 %187, 85
  %189 = icmp slt i32 %188, 0
  br i1 %189, label %408, label %146

190:                                              ; preds = %312
  %191 = load i32, ptr %4, align 4
  %192 = xor i32 %191, 544113943
  store i32 %192, ptr %4, align 4
  %193 = xor i32 %3, 1322770417
  %194 = and i32 %3, %193
  %195 = or i32 %3, %193
  %196 = xor i32 %3, %193
  %197 = add i32 %3, %193
  %198 = sub i32 %197, %196
  %199 = mul i32 %194, 2
  %200 = sub i32 %198, %199
  %201 = mul i32 %200, 32
  %202 = icmp uge i32 %201, 0
  br i1 %202, label %146, label %415

203:                                              ; preds = %308
  %204 = load i32, ptr %4, align 4
  %205 = xor i32 %204, 1765565696
  store i32 %205, ptr %4, align 4
  %206 = xor i32 %3, 131048649
  %207 = and i32 %3, %206
  %208 = or i32 %3, %206
  %209 = xor i32 %3, %206
  %210 = sub i32 %208, %209
  %211 = sub i32 %210, %207
  %212 = mul i32 %211, 235
  %213 = icmp slt i32 %212, 0
  br i1 %213, label %422, label %146

214:                                              ; preds = %284
  %215 = load i32, ptr %4, align 4
  %216 = xor i32 %215, 1386921799
  store i32 %216, ptr %4, align 4
  %217 = xor i32 %3, 484059877
  %218 = and i32 %3, %217
  %219 = or i32 %3, %217
  %220 = xor i32 %3, %217
  %221 = mul i32 %219, 2
  %222 = sub i32 %221, %220
  %223 = sub i32 %222, %3
  %224 = sub i32 %223, %217
  %225 = mul i32 %224, 184
  %226 = icmp ugt i32 %225, 0
  br i1 %226, label %429, label %146

227:                                              ; preds = %294
  %228 = load i32, ptr %4, align 4
  %229 = xor i32 %228, 538964882
  store i32 %229, ptr %4, align 4
  %230 = xor i32 %3, -677416631
  %231 = and i32 %3, %230
  %232 = or i32 %3, %230
  %233 = xor i32 %3, %230
  %234 = add i32 %231, %232
  %235 = sub i32 %234, %3
  %236 = sub i32 %235, %230
  %237 = mul i32 %236, 251
  %238 = xor i32 %3, -1760399993
  %239 = and i32 %3, %238
  %240 = or i32 %3, %238
  %241 = xor i32 %3, %238
  %242 = add i32 %239, %240
  %243 = sub i32 %242, %3
  %244 = sub i32 %243, %238
  %245 = mul i32 %244, 237
  %246 = icmp eq i32 %237, %245
  br i1 %246, label %146, label %436

247:                                              ; preds = %292
  %248 = load i32, ptr %4, align 4
  %249 = xor i32 %248, -1351754514
  store i32 %249, ptr %4, align 4
  %250 = xor i32 %3, 1370292723
  %251 = and i32 %3, %250
  %252 = or i32 %3, %250
  %253 = xor i32 %3, %250
  %254 = add i32 %251, %252
  %255 = sub i32 %254, %3
  %256 = sub i32 %255, %250
  %257 = mul i32 %256, 100
  %258 = icmp slt i32 %257, 0
  br i1 %258, label %442, label %146

259:                                              ; preds = %320
  %260 = load i32, ptr %4, align 4
  %261 = xor i32 %260, -1522756623
  store i32 %261, ptr %4, align 4
  %262 = xor i32 %3, -1175521029
  %263 = and i32 %3, %262
  %264 = or i32 %3, %262
  %265 = xor i32 %3, %262
  %266 = mul i32 %264, 2
  %267 = sub i32 %266, %265
  %268 = sub i32 %267, %3
  %269 = sub i32 %268, %262
  %270 = mul i32 %269, 24
  %271 = icmp sgt i32 %270, 0
  br i1 %271, label %448, label %146

272:                                              ; preds = %7
  %273 = icmp slt i32 %10, 364239696
  br i1 %273, label %276, label %278

274:                                              ; preds = %7
  %275 = icmp slt i32 %10, 1860659222
  br i1 %275, label %300, label %302

276:                                              ; preds = %272
  %277 = icmp slt i32 %10, 186467604
  br i1 %277, label %280, label %282

278:                                              ; preds = %272
  %279 = icmp slt i32 %10, 1070285123
  br i1 %279, label %288, label %290

280:                                              ; preds = %276
  %281 = icmp eq i32 %10, 28270782
  br i1 %281, label %177, label %284

282:                                              ; preds = %276
  %283 = icmp eq i32 %10, 186467604
  br i1 %283, label %46, label %286

284:                                              ; preds = %280
  %285 = icmp eq i32 %10, 110447821
  br i1 %285, label %214, label %147

286:                                              ; preds = %282
  %287 = icmp eq i32 %10, 296357360
  br i1 %287, label %90, label %147

288:                                              ; preds = %278
  %289 = icmp eq i32 %10, 364239696
  br i1 %289, label %106, label %292

290:                                              ; preds = %278
  %291 = icmp slt i32 %10, 1094494363
  br i1 %291, label %294, label %296

292:                                              ; preds = %288
  %293 = icmp eq i32 %10, 802496040
  br i1 %293, label %247, label %147

294:                                              ; preds = %290
  %295 = icmp eq i32 %10, 1070285123
  br i1 %295, label %227, label %147

296:                                              ; preds = %290
  %297 = icmp eq i32 %10, 1094494363
  br i1 %297, label %24, label %298

298:                                              ; preds = %296
  %299 = icmp eq i32 %10, 1122744044
  br i1 %299, label %62, label %147

300:                                              ; preds = %274
  %301 = icmp slt i32 %10, 1713078733
  br i1 %301, label %304, label %306

302:                                              ; preds = %274
  %303 = icmp slt i32 %10, 1986965878
  br i1 %303, label %312, label %314

304:                                              ; preds = %300
  %305 = icmp eq i32 %10, 1302761204
  br i1 %305, label %12, label %308

306:                                              ; preds = %300
  %307 = icmp eq i32 %10, 1713078733
  br i1 %307, label %144, label %310

308:                                              ; preds = %304
  %309 = icmp eq i32 %10, 1419900384
  br i1 %309, label %203, label %147

310:                                              ; preds = %306
  %311 = icmp eq i32 %10, 1835251906
  br i1 %311, label %164, label %147

312:                                              ; preds = %302
  %313 = icmp eq i32 %10, 1860659222
  br i1 %313, label %190, label %316

314:                                              ; preds = %302
  %315 = icmp slt i32 %10, 2009899330
  br i1 %315, label %318, label %320

316:                                              ; preds = %312
  %317 = icmp eq i32 %10, 1897994500
  br i1 %317, label %78, label %147

318:                                              ; preds = %314
  %319 = icmp eq i32 %10, 1986965878
  br i1 %319, label %133, label %147

320:                                              ; preds = %314
  %321 = icmp eq i32 %10, 2009899330
  br i1 %321, label %259, label %322

322:                                              ; preds = %320
  %323 = icmp eq i32 %10, 2047010618
  br i1 %323, label %120, label %147

324:                                              ; preds = %12
  %325 = load i64, ptr %2, align 8
  %326 = ptrtoint ptr %0 to i64
  %327 = sub i64 %326, %325
  %328 = add i64 %327, %326
  %329 = add i64 %328, %325
  %330 = or i64 %329, %325
  %331 = or i64 %330, %326
  store i64 %331, ptr %2, align 8
  br label %146

332:                                              ; preds = %24
  %333 = load i64, ptr %2, align 8
  %334 = ptrtoint ptr %0 to i64
  %335 = add i64 %334, %333
  %336 = and i64 %335, %334
  %337 = add i64 %336, %333
  %338 = mul i64 %337, %333
  store i64 %338, ptr %2, align 8
  br label %146

339:                                              ; preds = %46
  %340 = load i64, ptr %2, align 8
  %341 = ptrtoint ptr %0 to i64
  %342 = sub i64 %341, %341
  %343 = or i64 %342, %341
  %344 = or i64 %343, %340
  store i64 %344, ptr %2, align 8
  br label %146

345:                                              ; preds = %62
  %346 = load i64, ptr %2, align 8
  %347 = ptrtoint ptr %0 to i64
  %348 = or i64 %346, %346
  %349 = or i64 %348, %346
  %350 = mul i64 %349, %347
  store i64 %350, ptr %2, align 8
  br label %146

351:                                              ; preds = %78
  %352 = load i64, ptr %2, align 8
  %353 = ptrtoint ptr %0 to i64
  %354 = add i64 %352, %353
  %355 = and i64 %354, %353
  %356 = and i64 %355, %352
  %357 = add i64 %356, %353
  %358 = xor i64 %357, %352
  %359 = add i64 %358, %352
  store i64 %359, ptr %2, align 8
  br label %146

360:                                              ; preds = %90
  %361 = load i64, ptr %2, align 8
  %362 = ptrtoint ptr %0 to i64
  %363 = or i64 %361, %362
  %364 = sub i64 %363, %362
  %365 = sub i64 %364, %362
  store i64 %365, ptr %2, align 8
  br label %146

366:                                              ; preds = %106
  %367 = load i64, ptr %2, align 8
  %368 = ptrtoint ptr %0 to i64
  %369 = xor i64 %368, %367
  %370 = or i64 %369, %367
  %371 = and i64 %370, %367
  %372 = and i64 %371, %368
  store i64 %372, ptr %2, align 8
  br label %146

373:                                              ; preds = %120
  %374 = load i64, ptr %2, align 8
  %375 = ptrtoint ptr %0 to i64
  %376 = mul i64 %374, %375
  %377 = mul i64 %376, %374
  %378 = or i64 %377, %375
  %379 = sub i64 %378, %375
  %380 = and i64 %379, %375
  %381 = and i64 %380, %374
  store i64 %381, ptr %2, align 8
  br label %146

382:                                              ; preds = %133
  %383 = load i64, ptr %2, align 8
  %384 = ptrtoint ptr %0 to i64
  %385 = xor i64 %383, %384
  %386 = mul i64 %385, %384
  %387 = and i64 %386, %383
  %388 = add i64 %387, %384
  %389 = add i64 %388, %384
  %390 = sub i64 %389, %383
  store i64 %390, ptr %2, align 8
  br label %146

391:                                              ; preds = %147
  %392 = load i64, ptr %2, align 8
  %393 = ptrtoint ptr %0 to i64
  %394 = xor i64 %393, %393
  %395 = and i64 %394, %392
  %396 = xor i64 %395, %392
  %397 = mul i64 %396, %393
  %398 = and i64 %397, %392
  %399 = sub i64 %398, %393
  store i64 %399, ptr %2, align 8
  br label %7

400:                                              ; preds = %164
  %401 = load i64, ptr %2, align 8
  %402 = ptrtoint ptr %0 to i64
  %403 = xor i64 %401, %401
  %404 = mul i64 %403, %402
  %405 = mul i64 %404, %402
  %406 = and i64 %405, %401
  %407 = or i64 %406, %402
  store i64 %407, ptr %2, align 8
  br label %146

408:                                              ; preds = %177
  %409 = load i64, ptr %2, align 8
  %410 = ptrtoint ptr %0 to i64
  %411 = or i64 %410, %409
  %412 = or i64 %411, %410
  %413 = sub i64 %412, %409
  %414 = add i64 %413, %410
  store i64 %414, ptr %2, align 8
  br label %146

415:                                              ; preds = %190
  %416 = load i64, ptr %2, align 8
  %417 = ptrtoint ptr %0 to i64
  %418 = add i64 %416, %416
  %419 = add i64 %418, %416
  %420 = sub i64 %419, %416
  %421 = xor i64 %420, %417
  store i64 %421, ptr %2, align 8
  br label %146

422:                                              ; preds = %203
  %423 = load i64, ptr %2, align 8
  %424 = ptrtoint ptr %0 to i64
  %425 = or i64 %423, %423
  %426 = sub i64 %425, %423
  %427 = sub i64 %426, %424
  %428 = mul i64 %427, %423
  store i64 %428, ptr %2, align 8
  br label %146

429:                                              ; preds = %214
  %430 = load i64, ptr %2, align 8
  %431 = ptrtoint ptr %0 to i64
  %432 = add i64 %430, %430
  %433 = add i64 %432, %431
  %434 = xor i64 %433, %430
  %435 = sub i64 %434, %430
  store i64 %435, ptr %2, align 8
  br label %146

436:                                              ; preds = %227
  %437 = load i64, ptr %2, align 8
  %438 = ptrtoint ptr %0 to i64
  %439 = and i64 %438, %438
  %440 = mul i64 %439, %438
  %441 = or i64 %440, %437
  store i64 %441, ptr %2, align 8
  br label %146

442:                                              ; preds = %247
  %443 = load i64, ptr %2, align 8
  %444 = ptrtoint ptr %0 to i64
  %445 = or i64 %444, %444
  %446 = add i64 %445, %444
  %447 = or i64 %446, %443
  store i64 %447, ptr %2, align 8
  br label %146

448:                                              ; preds = %259
  %449 = load i64, ptr %2, align 8
  %450 = ptrtoint ptr %0 to i64
  %451 = or i64 %450, %449
  %452 = or i64 %451, %450
  %453 = mul i64 %452, %449
  %454 = xor i64 %453, %449
  store i64 %454, ptr %2, align 8
  br label %146
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @run_program(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca %struct.DigestFormatter, align 4
  %8 = alloca i64, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca %struct.InputJob, align 8
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store i32 -2087553010, ptr %4, align 4
  br label %14

14:                                               ; preds = %544, %235, %234, %1
  %15 = load i32, ptr %4, align 4
  %16 = sub i32 %15, 1383136215
  %17 = mul i32 %16, -859819255
  %18 = icmp slt i32 %17, 776068018
  br i1 %18, label %369, label %371

19:                                               ; preds = %439
  store ptr %0, ptr %6, align 8
  store i32 0, ptr %9, align 4
  %20 = load ptr, ptr %6, align 8
  %21 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %20, i32 0, i32 1
  %22 = load i32, ptr %21, align 4
  %23 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %7, i32 0, i32 0
  store i32 %22, ptr %23, align 4
  %24 = load ptr, ptr %6, align 8
  %25 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %24, i32 0, i32 2
  %26 = load i32, ptr %25, align 8
  %27 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %7, i32 0, i32 1
  store i32 %26, ptr %27, align 4
  %28 = load ptr, ptr %6, align 8
  %29 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %28, i32 0, i32 4
  %30 = load i32, ptr %29, align 8
  %31 = icmp ne i32 %30, 0
  %32 = select i1 %31, i32 1509027264, i32 2098095081
  store i32 %32, ptr %4, align 4
  %33 = xor i32 %3, 11196857
  %34 = and i32 %3, %33
  %35 = or i32 %3, %33
  %36 = xor i32 %3, %33
  %37 = add i32 %3, %33
  %38 = sub i32 %37, %36
  %39 = mul i32 %34, 2
  %40 = sub i32 %38, %39
  %41 = mul i32 %40, 255
  %42 = icmp uge i32 %41, 0
  br i1 %42, label %234, label %441

43:                                               ; preds = %387
  %44 = load ptr, ptr %6, align 8
  %45 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %44, i32 0, i32 3
  %46 = load i32, ptr %45, align 4
  %47 = load ptr, ptr %6, align 8
  %48 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %47, i32 0, i32 0
  %49 = load i32, ptr %48, align 8
  %50 = call i32 @run_self_tests(i32 noundef %46, i32 noundef %49)
  store i32 %50, ptr %10, align 4
  %51 = load i32, ptr %10, align 4
  %52 = icmp ne i32 %51, 0
  %53 = select i1 %52, i32 -13977038, i32 -652540298
  store i32 %53, ptr %4, align 4
  %54 = xor i32 %3, -1264319857
  %55 = and i32 %3, %54
  %56 = or i32 %3, %54
  %57 = xor i32 %3, %54
  %58 = add i32 %3, %54
  %59 = sub i32 %58, %57
  %60 = mul i32 %55, 2
  %61 = sub i32 %59, %60
  %62 = mul i32 %61, 69
  %63 = icmp slt i32 %62, 1
  br i1 %63, label %234, label %449

64:                                               ; preds = %435
  %65 = load i32, ptr %10, align 4
  store i32 %65, ptr %9, align 4
  store i32 -652540298, ptr %4, align 4
  %66 = xor i32 %3, 1559837987
  %67 = and i32 %3, %66
  %68 = or i32 %3, %66
  %69 = xor i32 %3, %66
  %70 = add i32 %67, %68
  %71 = sub i32 %70, %3
  %72 = sub i32 %71, %66
  %73 = mul i32 %72, 109
  %74 = icmp sle i32 %73, 0
  br i1 %74, label %234, label %455

75:                                               ; preds = %423
  store i32 2098095081, ptr %4, align 4
  %76 = xor i32 %3, -1613512585
  %77 = and i32 %3, %76
  %78 = or i32 %3, %76
  %79 = xor i32 %3, %76
  %80 = mul i32 %78, 2
  %81 = sub i32 %80, %79
  %82 = sub i32 %81, %3
  %83 = sub i32 %82, %76
  %84 = mul i32 %83, 81
  %85 = icmp sgt i32 %84, 0
  br i1 %85, label %464, label %234

86:                                               ; preds = %417
  %87 = load ptr, ptr %6, align 8
  %88 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %87, i32 0, i32 7
  %89 = load i64, ptr %88, align 8
  %90 = icmp eq i64 %89, 0
  %91 = select i1 %90, i32 982669045, i32 1927446460
  store i32 %91, ptr %4, align 4
  %92 = xor i32 %3, 1168013683
  %93 = and i32 %3, %92
  %94 = or i32 %3, %92
  %95 = xor i32 %3, %92
  %96 = add i32 %3, %92
  %97 = sub i32 %96, %95
  %98 = mul i32 %93, 2
  %99 = sub i32 %97, %98
  %100 = mul i32 %99, 254
  %101 = icmp uge i32 %100, 0
  br i1 %101, label %234, label %470

102:                                              ; preds = %385
  %103 = load ptr, ptr %6, align 8
  %104 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %103, i32 0, i32 4
  %105 = load i32, ptr %104, align 8
  %106 = icmp ne i32 %105, 0
  %107 = select i1 %106, i32 1927446460, i32 -1751511943
  store i32 %107, ptr %4, align 4
  %108 = xor i32 %3, -1350886249
  %109 = and i32 %3, %108
  %110 = or i32 %3, %108
  %111 = xor i32 %3, %108
  %112 = add i32 %3, %108
  %113 = sub i32 %112, %111
  %114 = mul i32 %109, 2
  %115 = sub i32 %113, %114
  %116 = mul i32 %115, 16
  %117 = icmp sle i32 %116, 0
  br i1 %117, label %234, label %476

118:                                              ; preds = %413
  %119 = load ptr, ptr %6, align 8
  %120 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %119, i32 0, i32 5
  %121 = load i32, ptr %120, align 4
  %122 = icmp ne i32 %121, 0
  %123 = select i1 %122, i32 1927446460, i32 409262696
  store i32 %123, ptr %4, align 4
  %124 = xor i32 %3, 67664559
  %125 = and i32 %3, %124
  %126 = or i32 %3, %124
  %127 = xor i32 %3, %124
  %128 = mul i32 %126, 2
  %129 = sub i32 %128, %127
  %130 = sub i32 %129, %3
  %131 = sub i32 %130, %124
  %132 = mul i32 %131, 114
  %133 = icmp slt i32 %132, 1
  br i1 %133, label %234, label %485

134:                                              ; preds = %383
  call void @make_input_job(ptr dead_on_unwind writable sret(%struct.InputJob) align 8 %11, i32 noundef 1, ptr noundef null, ptr noundef null)
  %135 = load ptr, ptr %6, align 8
  %136 = call i32 @execute_job(ptr noundef %11, ptr noundef %135, ptr noundef %7)
  store i32 %136, ptr %12, align 4
  call void @free_input_job(ptr noundef %11)
  %137 = load i32, ptr %12, align 4
  store i32 %137, ptr %5, align 4
  store i32 2052700586, ptr %4, align 4
  %138 = xor i32 %3, 1558112741
  %139 = and i32 %3, %138
  %140 = or i32 %3, %138
  %141 = xor i32 %3, %138
  %142 = mul i32 %140, 2
  %143 = sub i32 %142, %141
  %144 = sub i32 %143, %3
  %145 = sub i32 %144, %138
  %146 = mul i32 %145, 15
  %147 = icmp eq i32 %146, 0
  br i1 %147, label %234, label %493

148:                                              ; preds = %401
  store i64 0, ptr %8, align 8
  store i32 -60175080, ptr %4, align 4
  %149 = xor i32 %3, -550153733
  %150 = and i32 %3, %149
  %151 = or i32 %3, %149
  %152 = xor i32 %3, %149
  %153 = add i32 %150, %151
  %154 = sub i32 %153, %3
  %155 = sub i32 %154, %149
  %156 = mul i32 %155, 214
  %157 = icmp ugt i32 %156, 0
  br i1 %157, label %500, label %234

158:                                              ; preds = %429
  %159 = load i64, ptr %8, align 8
  %160 = load ptr, ptr %6, align 8
  %161 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %160, i32 0, i32 7
  %162 = load i64, ptr %161, align 8
  %163 = icmp ult i64 %159, %162
  %164 = select i1 %163, i32 -636009380, i32 346441388
  store i32 %164, ptr %4, align 4
  %165 = xor i32 %3, 5453713
  %166 = and i32 %3, %165
  %167 = or i32 %3, %165
  %168 = xor i32 %3, %165
  %169 = mul i32 %167, 2
  %170 = sub i32 %169, %168
  %171 = sub i32 %170, %3
  %172 = sub i32 %171, %165
  %173 = mul i32 %172, 57
  %174 = icmp slt i32 %173, 0
  br i1 %174, label %507, label %234

175:                                              ; preds = %419
  %176 = load ptr, ptr %6, align 8
  %177 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %176, i32 0, i32 6
  %178 = load i64, ptr %8, align 8
  %179 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %177, i64 0, i64 %178
  %180 = load ptr, ptr %6, align 8
  %181 = call i32 @execute_job(ptr noundef %179, ptr noundef %180, ptr noundef %7)
  store i32 %181, ptr %13, align 4
  %182 = load i32, ptr %13, align 4
  %183 = icmp ne i32 %182, 0
  %184 = select i1 %183, i32 -717225127, i32 1555985485
  store i32 %184, ptr %4, align 4
  %185 = xor i32 %3, -267708245
  %186 = and i32 %3, %185
  %187 = or i32 %3, %185
  %188 = xor i32 %3, %185
  %189 = add i32 %186, %187
  %190 = sub i32 %189, %3
  %191 = sub i32 %190, %185
  %192 = mul i32 %191, 240
  %193 = icmp eq i32 %192, 0
  br i1 %193, label %234, label %513

194:                                              ; preds = %393
  %195 = load i32, ptr %13, align 4
  store i32 %195, ptr %9, align 4
  store i32 1555985485, ptr %4, align 4
  %196 = xor i32 %3, 1290940113
  %197 = and i32 %3, %196
  %198 = or i32 %3, %196
  %199 = xor i32 %3, %196
  %200 = sub i32 %198, %199
  %201 = sub i32 %200, %197
  %202 = mul i32 %201, 10
  %203 = icmp slt i32 %202, 0
  br i1 %203, label %520, label %234

204:                                              ; preds = %403
  %205 = load i64, ptr %8, align 8
  %206 = sub i64 %205, 1
  %207 = mul i64 %205, 2
  %208 = mul i64 1, %206
  %209 = sub i64 %207, %208
  store i64 %209, ptr %8, align 8
  store i32 -60175080, ptr %4, align 4
  %210 = xor i32 %3, -1531206533
  %211 = and i32 %3, %210
  %212 = or i32 %3, %210
  %213 = xor i32 %3, %210
  %214 = add i32 %3, %210
  %215 = sub i32 %214, %213
  %216 = mul i32 %211, 2
  %217 = sub i32 %215, %216
  %218 = mul i32 %217, 130
  %219 = icmp slt i32 %218, 1
  br i1 %219, label %234, label %528

220:                                              ; preds = %433
  %221 = load i32, ptr %9, align 4
  store i32 %221, ptr %5, align 4
  store i32 2052700586, ptr %4, align 4
  %222 = xor i32 %3, 158950621
  %223 = and i32 %3, %222
  %224 = or i32 %3, %222
  %225 = xor i32 %3, %222
  %226 = add i32 %3, %222
  %227 = sub i32 %226, %225
  %228 = mul i32 %223, 2
  %229 = sub i32 %227, %228
  %230 = mul i32 %229, 106
  %231 = icmp sle i32 %230, 0
  br i1 %231, label %234, label %535

232:                                              ; preds = %421
  %233 = load i32, ptr %5, align 4
  ret i32 %233

234:                                              ; preds = %603, %594, %588, %579, %573, %566, %557, %551, %535, %528, %520, %513, %507, %500, %493, %485, %476, %470, %464, %455, %449, %441, %356, %344, %322, %303, %290, %270, %259, %246, %220, %204, %194, %175, %158, %148, %134, %118, %102, %86, %75, %64, %43, %19
  br label %14

235:                                              ; preds = %439, %435, %433, %429, %423, %419, %417, %413, %403, %399, %397, %393, %387, %383, %381
  store i32 -2087553010, ptr %4, align 4
  call void asm sideeffect "", ""()
  %236 = xor i32 %3, -213632119
  %237 = and i32 %3, %236
  %238 = or i32 %3, %236
  %239 = xor i32 %3, %236
  %240 = add i32 %3, %236
  %241 = sub i32 %240, %239
  %242 = mul i32 %237, 2
  %243 = sub i32 %241, %242
  %244 = mul i32 %243, 114
  %245 = icmp uge i32 %244, 0
  br i1 %245, label %14, label %544

246:                                              ; preds = %431
  %247 = load i32, ptr %4, align 4
  %248 = xor i32 %247, 837350988
  store i32 %248, ptr %4, align 4
  %249 = xor i32 %3, 201984671
  %250 = and i32 %3, %249
  %251 = or i32 %3, %249
  %252 = xor i32 %3, %249
  %253 = mul i32 %251, 2
  %254 = sub i32 %253, %252
  %255 = sub i32 %254, %3
  %256 = sub i32 %255, %249
  %257 = mul i32 %256, 143
  %258 = icmp sgt i32 %257, 0
  br i1 %258, label %551, label %234

259:                                              ; preds = %437
  %260 = load i32, ptr %4, align 4
  %261 = xor i32 %260, -1393077033
  store i32 %261, ptr %4, align 4
  %262 = xor i32 %3, 923807397
  %263 = and i32 %3, %262
  %264 = or i32 %3, %262
  %265 = xor i32 %3, %262
  %266 = sub i32 %264, %265
  %267 = sub i32 %266, %263
  %268 = mul i32 %267, 228
  %269 = icmp uge i32 %268, 0
  br i1 %269, label %234, label %557

270:                                              ; preds = %397
  %271 = load i32, ptr %4, align 4
  %272 = xor i32 %271, -1660392373
  store i32 %272, ptr %4, align 4
  %273 = xor i32 %3, -2072634267
  %274 = and i32 %3, %273
  %275 = or i32 %3, %273
  %276 = xor i32 %3, %273
  %277 = add i32 %3, %273
  %278 = sub i32 %277, %276
  %279 = mul i32 %274, 2
  %280 = sub i32 %278, %279
  %281 = mul i32 %280, 237
  %282 = xor i32 %3, 1612963613
  %283 = and i32 %3, %282
  %284 = or i32 %3, %282
  %285 = xor i32 %3, %282
  %286 = sub i32 %284, %285
  %287 = sub i32 %286, %283
  %288 = mul i32 %287, 35
  %289 = icmp eq i32 %281, %288
  br i1 %289, label %234, label %566

290:                                              ; preds = %381
  %291 = load i32, ptr %4, align 4
  %292 = xor i32 %291, 1422641832
  store i32 %292, ptr %4, align 4
  %293 = xor i32 %3, -1648339525
  %294 = and i32 %3, %293
  %295 = or i32 %3, %293
  %296 = xor i32 %3, %293
  %297 = add i32 %3, %293
  %298 = sub i32 %297, %296
  %299 = mul i32 %294, 2
  %300 = sub i32 %298, %299
  %301 = mul i32 %300, 25
  %302 = icmp sgt i32 %301, 0
  br i1 %302, label %573, label %234

303:                                              ; preds = %395
  %304 = load i32, ptr %4, align 4
  %305 = xor i32 %304, 19772188
  store i32 %305, ptr %4, align 4
  %306 = xor i32 %3, -471908397
  %307 = and i32 %3, %306
  %308 = or i32 %3, %306
  %309 = xor i32 %3, %306
  %310 = sub i32 %308, %309
  %311 = sub i32 %310, %307
  %312 = mul i32 %311, 28
  %313 = xor i32 %3, -482857477
  %314 = and i32 %3, %313
  %315 = or i32 %3, %313
  %316 = xor i32 %3, %313
  %317 = add i32 %314, %315
  %318 = sub i32 %317, %3
  %319 = sub i32 %318, %313
  %320 = mul i32 %319, 52
  %321 = icmp ne i32 %312, %320
  br i1 %321, label %579, label %234

322:                                              ; preds = %399
  %323 = load i32, ptr %4, align 4
  %324 = xor i32 %323, -830090145
  store i32 %324, ptr %4, align 4
  %325 = xor i32 %3, 1605897535
  %326 = and i32 %3, %325
  %327 = or i32 %3, %325
  %328 = xor i32 %3, %325
  %329 = add i32 %3, %325
  %330 = sub i32 %329, %328
  %331 = mul i32 %326, 2
  %332 = sub i32 %330, %331
  %333 = mul i32 %332, 135
  %334 = xor i32 %3, 297366837
  %335 = and i32 %3, %334
  %336 = or i32 %3, %334
  %337 = xor i32 %3, %334
  %338 = mul i32 %336, 2
  %339 = sub i32 %338, %337
  %340 = sub i32 %339, %3
  %341 = sub i32 %340, %334
  %342 = mul i32 %341, 205
  %343 = icmp eq i32 %333, %342
  br i1 %343, label %234, label %588

344:                                              ; preds = %415
  %345 = load i32, ptr %4, align 4
  %346 = xor i32 %345, -1876614887
  store i32 %346, ptr %4, align 4
  %347 = xor i32 %3, 1896125757
  %348 = and i32 %3, %347
  %349 = or i32 %3, %347
  %350 = xor i32 %3, %347
  %351 = add i32 %348, %349
  %352 = sub i32 %351, %3
  %353 = sub i32 %352, %347
  %354 = mul i32 %353, 120
  %355 = icmp uge i32 %354, 0
  br i1 %355, label %234, label %594

356:                                              ; preds = %377
  %357 = load i32, ptr %4, align 4
  %358 = xor i32 %357, 898486324
  store i32 %358, ptr %4, align 4
  %359 = xor i32 %3, 1616799523
  %360 = and i32 %3, %359
  %361 = or i32 %3, %359
  %362 = xor i32 %3, %359
  %363 = add i32 %3, %359
  %364 = sub i32 %363, %362
  %365 = mul i32 %360, 2
  %366 = sub i32 %364, %365
  %367 = mul i32 %366, 156
  %368 = icmp slt i32 %367, 0
  br i1 %368, label %603, label %234

369:                                              ; preds = %14
  %370 = icmp slt i32 %17, 289810834
  br i1 %370, label %373, label %375

371:                                              ; preds = %14
  %372 = icmp slt i32 %17, 1211059785
  br i1 %372, label %405, label %407

373:                                              ; preds = %369
  %374 = icmp slt i32 %17, 61453849
  br i1 %374, label %377, label %379

375:                                              ; preds = %369
  %376 = icmp slt i32 %17, 597863322
  br i1 %376, label %389, label %391

377:                                              ; preds = %373
  %378 = icmp eq i32 %17, 47500426
  br i1 %378, label %356, label %381

379:                                              ; preds = %373
  %380 = icmp slt i32 %17, 215166478
  br i1 %380, label %383, label %385

381:                                              ; preds = %377
  %382 = icmp eq i32 %17, 53275918
  br i1 %382, label %290, label %235

383:                                              ; preds = %379
  %384 = icmp eq i32 %17, 61453849
  br i1 %384, label %134, label %235

385:                                              ; preds = %379
  %386 = icmp eq i32 %17, 215166478
  br i1 %386, label %102, label %387

387:                                              ; preds = %385
  %388 = icmp eq i32 %17, 242871345
  br i1 %388, label %43, label %235

389:                                              ; preds = %375
  %390 = icmp slt i32 %17, 315058484
  br i1 %390, label %393, label %395

391:                                              ; preds = %375
  %392 = icmp slt i32 %17, 688144909
  br i1 %392, label %399, label %401

393:                                              ; preds = %389
  %394 = icmp eq i32 %17, 289810834
  br i1 %394, label %194, label %235

395:                                              ; preds = %389
  %396 = icmp eq i32 %17, 315058484
  br i1 %396, label %303, label %397

397:                                              ; preds = %395
  %398 = icmp eq i32 %17, 391556913
  br i1 %398, label %270, label %235

399:                                              ; preds = %391
  %400 = icmp eq i32 %17, 597863322
  br i1 %400, label %322, label %235

401:                                              ; preds = %391
  %402 = icmp eq i32 %17, 688144909
  br i1 %402, label %148, label %403

403:                                              ; preds = %401
  %404 = icmp eq i32 %17, 741916198
  br i1 %404, label %204, label %235

405:                                              ; preds = %371
  %406 = icmp slt i32 %17, 1158351789
  br i1 %406, label %409, label %411

407:                                              ; preds = %371
  %408 = icmp slt i32 %17, 1538511411
  br i1 %408, label %425, label %427

409:                                              ; preds = %405
  %410 = icmp slt i32 %17, 1066910725
  br i1 %410, label %413, label %415

411:                                              ; preds = %405
  %412 = icmp slt i32 %17, 1195357547
  br i1 %412, label %419, label %421

413:                                              ; preds = %409
  %414 = icmp eq i32 %17, 776068018
  br i1 %414, label %118, label %235

415:                                              ; preds = %409
  %416 = icmp eq i32 %17, 1066910725
  br i1 %416, label %344, label %417

417:                                              ; preds = %415
  %418 = icmp eq i32 %17, 1086602914
  br i1 %418, label %86, label %235

419:                                              ; preds = %411
  %420 = icmp eq i32 %17, 1158351789
  br i1 %420, label %175, label %235

421:                                              ; preds = %411
  %422 = icmp eq i32 %17, 1195357547
  br i1 %422, label %232, label %423

423:                                              ; preds = %421
  %424 = icmp eq i32 %17, 1196952727
  br i1 %424, label %75, label %235

425:                                              ; preds = %407
  %426 = icmp slt i32 %17, 1261897444
  br i1 %426, label %429, label %431

427:                                              ; preds = %407
  %428 = icmp slt i32 %17, 1572666817
  br i1 %428, label %435, label %437

429:                                              ; preds = %425
  %430 = icmp eq i32 %17, 1211059785
  br i1 %430, label %158, label %235

431:                                              ; preds = %425
  %432 = icmp eq i32 %17, 1261897444
  br i1 %432, label %246, label %433

433:                                              ; preds = %431
  %434 = icmp eq i32 %17, 1300762749
  br i1 %434, label %220, label %235

435:                                              ; preds = %427
  %436 = icmp eq i32 %17, 1538511411
  br i1 %436, label %64, label %235

437:                                              ; preds = %427
  %438 = icmp eq i32 %17, 1572666817
  br i1 %438, label %259, label %439

439:                                              ; preds = %437
  %440 = icmp eq i32 %17, 1663849199
  br i1 %440, label %19, label %235

441:                                              ; preds = %19
  %442 = load i64, ptr %2, align 8
  %443 = ptrtoint ptr %0 to i64
  %444 = add i64 %443, %443
  %445 = and i64 %444, %443
  %446 = and i64 %445, %443
  %447 = sub i64 %446, %443
  %448 = mul i64 %447, %442
  store i64 %448, ptr %2, align 8
  br label %234

449:                                              ; preds = %43
  %450 = load i64, ptr %2, align 8
  %451 = ptrtoint ptr %0 to i64
  %452 = or i64 %451, %450
  %453 = sub i64 %452, %450
  %454 = add i64 %453, %451
  store i64 %454, ptr %2, align 8
  br label %234

455:                                              ; preds = %64
  %456 = load i64, ptr %2, align 8
  %457 = ptrtoint ptr %0 to i64
  %458 = xor i64 %457, %456
  %459 = sub i64 %458, %456
  %460 = sub i64 %459, %456
  %461 = and i64 %460, %456
  %462 = or i64 %461, %456
  %463 = xor i64 %462, %457
  store i64 %463, ptr %2, align 8
  br label %234

464:                                              ; preds = %75
  %465 = load i64, ptr %2, align 8
  %466 = ptrtoint ptr %0 to i64
  %467 = sub i64 %465, %465
  %468 = xor i64 %467, %465
  %469 = add i64 %468, %465
  store i64 %469, ptr %2, align 8
  br label %234

470:                                              ; preds = %86
  %471 = load i64, ptr %2, align 8
  %472 = ptrtoint ptr %0 to i64
  %473 = sub i64 %471, %472
  %474 = sub i64 %473, %472
  %475 = or i64 %474, %472
  store i64 %475, ptr %2, align 8
  br label %234

476:                                              ; preds = %102
  %477 = load i64, ptr %2, align 8
  %478 = ptrtoint ptr %0 to i64
  %479 = add i64 %477, %478
  %480 = mul i64 %479, %477
  %481 = or i64 %480, %477
  %482 = add i64 %481, %477
  %483 = or i64 %482, %477
  %484 = and i64 %483, %477
  store i64 %484, ptr %2, align 8
  br label %234

485:                                              ; preds = %118
  %486 = load i64, ptr %2, align 8
  %487 = ptrtoint ptr %0 to i64
  %488 = sub i64 %486, %487
  %489 = mul i64 %488, %486
  %490 = add i64 %489, %487
  %491 = add i64 %490, %487
  %492 = xor i64 %491, %487
  store i64 %492, ptr %2, align 8
  br label %234

493:                                              ; preds = %134
  %494 = load i64, ptr %2, align 8
  %495 = ptrtoint ptr %0 to i64
  %496 = or i64 %495, %494
  %497 = mul i64 %496, %494
  %498 = sub i64 %497, %494
  %499 = sub i64 %498, %495
  store i64 %499, ptr %2, align 8
  br label %234

500:                                              ; preds = %148
  %501 = load i64, ptr %2, align 8
  %502 = ptrtoint ptr %0 to i64
  %503 = and i64 %502, %502
  %504 = sub i64 %503, %502
  %505 = mul i64 %504, %502
  %506 = or i64 %505, %502
  store i64 %506, ptr %2, align 8
  br label %234

507:                                              ; preds = %158
  %508 = load i64, ptr %2, align 8
  %509 = ptrtoint ptr %0 to i64
  %510 = or i64 %508, %508
  %511 = xor i64 %510, %508
  %512 = or i64 %511, %509
  store i64 %512, ptr %2, align 8
  br label %234

513:                                              ; preds = %175
  %514 = load i64, ptr %2, align 8
  %515 = ptrtoint ptr %0 to i64
  %516 = or i64 %514, %514
  %517 = mul i64 %516, %514
  %518 = add i64 %517, %514
  %519 = add i64 %518, %515
  store i64 %519, ptr %2, align 8
  br label %234

520:                                              ; preds = %194
  %521 = load i64, ptr %2, align 8
  %522 = ptrtoint ptr %0 to i64
  %523 = mul i64 %522, %522
  %524 = add i64 %523, %522
  %525 = xor i64 %524, %522
  %526 = add i64 %525, %521
  %527 = mul i64 %526, %522
  store i64 %527, ptr %2, align 8
  br label %234

528:                                              ; preds = %204
  %529 = load i64, ptr %2, align 8
  %530 = ptrtoint ptr %0 to i64
  %531 = and i64 %530, %529
  %532 = sub i64 %531, %529
  %533 = add i64 %532, %530
  %534 = xor i64 %533, %530
  store i64 %534, ptr %2, align 8
  br label %234

535:                                              ; preds = %220
  %536 = load i64, ptr %2, align 8
  %537 = ptrtoint ptr %0 to i64
  %538 = and i64 %537, %536
  %539 = and i64 %538, %537
  %540 = xor i64 %539, %537
  %541 = sub i64 %540, %537
  %542 = mul i64 %541, %536
  %543 = and i64 %542, %537
  store i64 %543, ptr %2, align 8
  br label %234

544:                                              ; preds = %235
  %545 = load i64, ptr %2, align 8
  %546 = ptrtoint ptr %0 to i64
  %547 = sub i64 %545, %546
  %548 = and i64 %547, %545
  %549 = and i64 %548, %546
  %550 = mul i64 %549, %546
  store i64 %550, ptr %2, align 8
  br label %14

551:                                              ; preds = %246
  %552 = load i64, ptr %2, align 8
  %553 = ptrtoint ptr %0 to i64
  %554 = or i64 %552, %552
  %555 = sub i64 %554, %553
  %556 = xor i64 %555, %552
  store i64 %556, ptr %2, align 8
  br label %234

557:                                              ; preds = %259
  %558 = load i64, ptr %2, align 8
  %559 = ptrtoint ptr %0 to i64
  %560 = and i64 %559, %559
  %561 = and i64 %560, %559
  %562 = and i64 %561, %559
  %563 = xor i64 %562, %559
  %564 = and i64 %563, %558
  %565 = add i64 %564, %558
  store i64 %565, ptr %2, align 8
  br label %234

566:                                              ; preds = %270
  %567 = load i64, ptr %2, align 8
  %568 = ptrtoint ptr %0 to i64
  %569 = add i64 %567, %567
  %570 = mul i64 %569, %567
  %571 = add i64 %570, %568
  %572 = sub i64 %571, %568
  store i64 %572, ptr %2, align 8
  br label %234

573:                                              ; preds = %290
  %574 = load i64, ptr %2, align 8
  %575 = ptrtoint ptr %0 to i64
  %576 = xor i64 %575, %575
  %577 = mul i64 %576, %574
  %578 = or i64 %577, %575
  store i64 %578, ptr %2, align 8
  br label %234

579:                                              ; preds = %303
  %580 = load i64, ptr %2, align 8
  %581 = ptrtoint ptr %0 to i64
  %582 = mul i64 %580, %580
  %583 = or i64 %582, %580
  %584 = and i64 %583, %580
  %585 = mul i64 %584, %581
  %586 = and i64 %585, %581
  %587 = sub i64 %586, %580
  store i64 %587, ptr %2, align 8
  br label %234

588:                                              ; preds = %322
  %589 = load i64, ptr %2, align 8
  %590 = ptrtoint ptr %0 to i64
  %591 = or i64 %590, %590
  %592 = add i64 %591, %590
  %593 = xor i64 %592, %589
  store i64 %593, ptr %2, align 8
  br label %234

594:                                              ; preds = %344
  %595 = load i64, ptr %2, align 8
  %596 = ptrtoint ptr %0 to i64
  %597 = xor i64 %595, %595
  %598 = mul i64 %597, %596
  %599 = xor i64 %598, %596
  %600 = add i64 %599, %595
  %601 = xor i64 %600, %595
  %602 = xor i64 %601, %595
  store i64 %602, ptr %2, align 8
  br label %234

603:                                              ; preds = %356
  %604 = load i64, ptr %2, align 8
  %605 = ptrtoint ptr %0 to i64
  %606 = xor i64 %604, %605
  %607 = sub i64 %606, %604
  %608 = sub i64 %607, %605
  store i64 %608, ptr %2, align 8
  br label %234
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @run_self_tests(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i64, align 8
  %10 = alloca [16 x i8], align 16
  %11 = alloca [33 x i8], align 16
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  store i32 1522666578, ptr %4, align 4
  br label %14

14:                                               ; preds = %442, %198, %197, %2
  %15 = load i32, ptr %4, align 4
  %16 = sub i32 %15, -1005276417
  %17 = mul i32 %16, -256839173
  switch i32 %17, label %198 [
    i32 639481697, label %18
    i32 1755337465, label %27
    i32 1213064671, label %41
    i32 807243870, label %72
    i32 1485808113, label %90
    i32 1097341618, label %103
    i32 1717557164, label %112
    i32 561179167, label %136
    i32 567918777, label %151
    i32 1939783823, label %165
    i32 401986392, label %178
    i32 841340778, label %191
    i32 1287061819, label %208
    i32 153157012, label %227
    i32 820118998, label %247
    i32 1800577436, label %258
    i32 1116231792, label %278
    i32 1606875979, label %300
    i32 1255904129, label %313
    i32 590369433, label %335
  ]

18:                                               ; preds = %14
  store i32 %0, ptr %5, align 4
  store i32 %1, ptr %6, align 4
  store i64 0, ptr %8, align 8
  store i64 7, ptr %9, align 8
  store i64 0, ptr %7, align 8
  store i32 -587914342, ptr %4, align 4
  %19 = xor i32 %0, 952865169
  %20 = and i32 %0, %19
  %21 = or i32 %0, %19
  %22 = xor i32 %0, %19
  %23 = sub i32 %21, %22
  %24 = sub i32 %23, %20
  %25 = mul i32 %24, 191
  %26 = icmp slt i32 %25, 1
  br i1 %26, label %197, label %348

27:                                               ; preds = %14
  %28 = load i64, ptr %7, align 8
  %29 = load i64, ptr %9, align 8
  %30 = icmp ult i64 %28, %29
  %31 = select i1 %30, i32 -247403156, i32 -925384486
  store i32 %31, ptr %4, align 4
  %32 = xor i32 %0, 1867768103
  %33 = and i32 %0, %32
  %34 = or i32 %0, %32
  %35 = xor i32 %0, %32
  %36 = add i32 %33, %34
  %37 = sub i32 %36, %0
  %38 = sub i32 %37, %32
  %39 = mul i32 %38, 5
  %40 = icmp slt i32 %39, 0
  br i1 %40, label %356, label %197

41:                                               ; preds = %14
  %42 = load i64, ptr %7, align 8
  %43 = getelementptr inbounds nuw [7 x %struct.TestVector], ptr @SELF_TESTS, i64 0, i64 %42
  %44 = getelementptr inbounds nuw %struct.TestVector, ptr %43, i32 0, i32 0
  %45 = load ptr, ptr %44, align 16
  store ptr %45, ptr %12, align 8
  %46 = load i64, ptr %7, align 8
  %47 = getelementptr inbounds nuw [7 x %struct.TestVector], ptr @SELF_TESTS, i64 0, i64 %46
  %48 = getelementptr inbounds nuw %struct.TestVector, ptr %47, i32 0, i32 1
  %49 = load ptr, ptr %48, align 8
  store ptr %49, ptr %13, align 8
  %50 = load ptr, ptr %12, align 8
  %51 = load ptr, ptr %12, align 8
  %52 = call i64 @strlen(ptr noundef %51) #11
  %53 = getelementptr inbounds [16 x i8], ptr %10, i64 0, i64 0
  %54 = load i32, ptr %6, align 4
  call void @md5_hash_memory(ptr noundef %50, i64 noundef %52, ptr noundef %53, i32 noundef %54)
  %55 = getelementptr inbounds [16 x i8], ptr %10, i64 0, i64 0
  %56 = getelementptr inbounds [33 x i8], ptr %11, i64 0, i64 0
  call void @digest_to_hex(ptr noundef %55, ptr noundef %56, i32 noundef 0)
  %57 = getelementptr inbounds [33 x i8], ptr %11, i64 0, i64 0
  %58 = load ptr, ptr %13, align 8
  %59 = call i32 @strcmp(ptr noundef %57, ptr noundef %58) #11
  %60 = icmp eq i32 %59, 0
  %61 = select i1 %60, i32 789705657, i32 -1960864189
  store i32 %61, ptr %4, align 4
  %62 = xor i32 %0, 1266660043
  %63 = and i32 %0, %62
  %64 = or i32 %0, %62
  %65 = xor i32 %0, %62
  %66 = add i32 %0, %62
  %67 = sub i32 %66, %65
  %68 = mul i32 %63, 2
  %69 = sub i32 %67, %68
  %70 = mul i32 %69, 34
  %71 = icmp slt i32 %70, 0
  br i1 %71, label %366, label %197

72:                                               ; preds = %14
  %73 = load i64, ptr %8, align 8
  %74 = xor i64 %73, 1
  %75 = and i64 %73, 1
  %76 = add i64 %75, %75
  %77 = add i64 %74, %76
  store i64 %77, ptr %8, align 8
  %78 = load i32, ptr %5, align 4
  %79 = icmp ne i32 %78, 0
  %80 = select i1 %79, i32 339383925, i32 1694324482
  store i32 %80, ptr %4, align 4
  %81 = xor i32 %0, -1844114063
  %82 = and i32 %0, %81
  %83 = or i32 %0, %81
  %84 = xor i32 %0, %81
  %85 = add i32 %82, %83
  %86 = sub i32 %85, %0
  %87 = sub i32 %86, %81
  %88 = mul i32 %87, 34
  %89 = icmp uge i32 %88, 0
  br i1 %89, label %197, label %375

90:                                               ; preds = %14
  %91 = load ptr, ptr %12, align 8
  %92 = getelementptr inbounds [33 x i8], ptr %11, i64 0, i64 0
  %93 = call i32 (ptr, ...) @printf(ptr noundef @.str.46, ptr noundef %91, ptr noundef %92)
  store i32 339383925, ptr %4, align 4
  %94 = xor i32 %0, -1925198643
  %95 = and i32 %0, %94
  %96 = or i32 %0, %94
  %97 = xor i32 %0, %94
  %98 = add i32 %95, %96
  %99 = sub i32 %98, %0
  %100 = sub i32 %99, %94
  %101 = mul i32 %100, 153
  %102 = icmp uge i32 %101, 0
  br i1 %102, label %197, label %384

103:                                              ; preds = %14
  store i32 2122384940, ptr %4, align 4
  %104 = xor i32 %0, -1098971919
  %105 = and i32 %0, %104
  %106 = or i32 %0, %104
  %107 = xor i32 %0, %104
  %108 = sub i32 %106, %107
  %109 = sub i32 %108, %105
  %110 = mul i32 %109, 254
  %111 = icmp sgt i32 %110, 0
  br i1 %111, label %394, label %197

112:                                              ; preds = %14
  %113 = load ptr, ptr %12, align 8
  %114 = call i32 (ptr, ...) @printf(ptr noundef @.str.47, ptr noundef %113)
  %115 = load ptr, ptr %13, align 8
  %116 = call i32 (ptr, ...) @printf(ptr noundef @.str.48, ptr noundef %115)
  %117 = getelementptr inbounds [33 x i8], ptr %11, i64 0, i64 0
  %118 = call i32 (ptr, ...) @printf(ptr noundef @.str.49, ptr noundef %117)
  store i32 2122384940, ptr %4, align 4
  %119 = xor i32 %0, -597543597
  %120 = and i32 %0, %119
  %121 = or i32 %0, %119
  %122 = xor i32 %0, %119
  %123 = mul i32 %121, 2
  %124 = sub i32 %123, %122
  %125 = sub i32 %124, %0
  %126 = sub i32 %125, %119
  %127 = mul i32 %126, 145
  %128 = xor i32 %0, -133742585
  %129 = and i32 %0, %128
  %130 = or i32 %0, %128
  %131 = xor i32 %0, %128
  %132 = sub i32 %130, %131
  %133 = sub i32 %132, %129
  %134 = mul i32 %133, 114
  %135 = icmp ne i32 %127, %134
  br i1 %135, label %402, label %197

136:                                              ; preds = %14
  %137 = load i64, ptr %7, align 8
  %138 = or i64 %137, 1
  %139 = and i64 %137, 1
  %140 = add i64 %138, %139
  store i64 %140, ptr %7, align 8
  store i32 -587914342, ptr %4, align 4
  %141 = xor i32 %0, 1738461903
  %142 = and i32 %0, %141
  %143 = or i32 %0, %141
  %144 = xor i32 %0, %141
  %145 = add i32 %0, %141
  %146 = sub i32 %145, %144
  %147 = mul i32 %142, 2
  %148 = sub i32 %146, %147
  %149 = mul i32 %148, 95
  %150 = icmp ugt i32 %149, 0
  br i1 %150, label %409, label %197

151:                                              ; preds = %14
  %152 = load i32, ptr %5, align 4
  %153 = icmp ne i32 %152, 0
  %154 = select i1 %153, i32 1373908604, i32 1943512455
  store i32 %154, ptr %4, align 4
  %155 = xor i32 %0, -1158800209
  %156 = and i32 %0, %155
  %157 = or i32 %0, %155
  %158 = xor i32 %0, %155
  %159 = add i32 %0, %155
  %160 = sub i32 %159, %158
  %161 = mul i32 %156, 2
  %162 = sub i32 %160, %161
  %163 = mul i32 %162, 17
  %164 = icmp uge i32 %163, 0
  br i1 %164, label %197, label %416

165:                                              ; preds = %14
  %166 = load i64, ptr %8, align 8
  %167 = load i64, ptr %9, align 8
  %168 = icmp ne i64 %166, %167
  %169 = select i1 %168, i32 1943512455, i32 -1881905379
  store i32 %169, ptr %4, align 4
  %170 = xor i32 %0, -738325829
  %171 = and i32 %0, %170
  %172 = or i32 %0, %170
  %173 = xor i32 %0, %170
  %174 = sub i32 %172, %173
  %175 = sub i32 %174, %171
  %176 = mul i32 %175, 100
  %177 = icmp sle i32 %176, 0
  br i1 %177, label %197, label %423

178:                                              ; preds = %14
  %179 = load i64, ptr %8, align 8
  %180 = load i64, ptr %9, align 8
  %181 = call i32 (ptr, ...) @printf(ptr noundef @.str.50, i64 noundef %179, i64 noundef %180)
  store i32 -1881905379, ptr %4, align 4
  %182 = xor i32 %0, 178061963
  %183 = and i32 %0, %182
  %184 = or i32 %0, %182
  %185 = xor i32 %0, %182
  %186 = add i32 %183, %184
  %187 = sub i32 %186, %0
  %188 = sub i32 %187, %182
  %189 = mul i32 %188, 133
  %190 = icmp slt i32 %189, 0
  br i1 %190, label %432, label %197

191:                                              ; preds = %14
  %192 = load i64, ptr %8, align 8
  %193 = load i64, ptr %9, align 8
  %194 = icmp eq i64 %192, %193
  %195 = zext i1 %194 to i64
  %196 = select i1 %194, i32 0, i32 1
  ret i32 %196

197:                                              ; preds = %506, %499, %492, %484, %474, %467, %459, %452, %432, %423, %416, %409, %402, %394, %384, %375, %366, %356, %348, %335, %313, %300, %278, %258, %247, %227, %208, %178, %165, %151, %136, %112, %103, %90, %72, %41, %27, %18
  br label %14

198:                                              ; preds = %14
  store i32 1522666578, ptr %4, align 4
  call void asm sideeffect "", ""()
  %199 = xor i32 %0, -559850791
  %200 = and i32 %0, %199
  %201 = or i32 %0, %199
  %202 = xor i32 %0, %199
  %203 = add i32 %200, %201
  %204 = sub i32 %203, %0
  %205 = sub i32 %204, %199
  %206 = mul i32 %205, 52
  %207 = icmp eq i32 %206, 0
  br i1 %207, label %14, label %442

208:                                              ; preds = %14
  %209 = load i32, ptr %4, align 4
  %210 = xor i32 %209, 193854324
  store i32 %210, ptr %4, align 4
  %211 = xor i32 %0, -905930777
  %212 = and i32 %0, %211
  %213 = or i32 %0, %211
  %214 = xor i32 %0, %211
  %215 = add i32 %212, %213
  %216 = sub i32 %215, %0
  %217 = sub i32 %216, %211
  %218 = mul i32 %217, 165
  %219 = xor i32 %0, -892287465
  %220 = and i32 %0, %219
  %221 = or i32 %0, %219
  %222 = xor i32 %0, %219
  %223 = sub i32 %221, %222
  %224 = sub i32 %223, %220
  %225 = mul i32 %224, 21
  %226 = icmp ne i32 %218, %225
  br i1 %226, label %452, label %197

227:                                              ; preds = %14
  %228 = load i32, ptr %4, align 4
  %229 = xor i32 %228, -415531530
  store i32 %229, ptr %4, align 4
  %230 = xor i32 %0, 112694139
  %231 = and i32 %0, %230
  %232 = or i32 %0, %230
  %233 = xor i32 %0, %230
  %234 = mul i32 %232, 2
  %235 = sub i32 %234, %233
  %236 = sub i32 %235, %0
  %237 = sub i32 %236, %230
  %238 = mul i32 %237, 211
  %239 = xor i32 %0, -1603524987
  %240 = and i32 %0, %239
  %241 = or i32 %0, %239
  %242 = xor i32 %0, %239
  %243 = sub i32 %241, %242
  %244 = sub i32 %243, %240
  %245 = mul i32 %244, 10
  %246 = icmp eq i32 %238, %245
  br i1 %246, label %197, label %459

247:                                              ; preds = %14
  %248 = load i32, ptr %4, align 4
  %249 = xor i32 %248, 1231800632
  store i32 %249, ptr %4, align 4
  %250 = xor i32 %0, -1752337013
  %251 = and i32 %0, %250
  %252 = or i32 %0, %250
  %253 = xor i32 %0, %250
  %254 = sub i32 %252, %253
  %255 = sub i32 %254, %251
  %256 = mul i32 %255, 64
  %257 = icmp slt i32 %256, 0
  br i1 %257, label %467, label %197

258:                                              ; preds = %14
  %259 = load i32, ptr %4, align 4
  %260 = xor i32 %259, 6661596
  store i32 %260, ptr %4, align 4
  %261 = xor i32 %0, 1655349425
  %262 = and i32 %0, %261
  %263 = or i32 %0, %261
  %264 = xor i32 %0, %261
  %265 = add i32 %262, %263
  %266 = sub i32 %265, %0
  %267 = sub i32 %266, %261
  %268 = mul i32 %267, 57
  %269 = xor i32 %0, -1022220383
  %270 = and i32 %0, %269
  %271 = or i32 %0, %269
  %272 = xor i32 %0, %269
  %273 = add i32 %270, %271
  %274 = sub i32 %273, %0
  %275 = sub i32 %274, %269
  %276 = mul i32 %275, 117
  %277 = icmp ne i32 %268, %276
  br i1 %277, label %474, label %197

278:                                              ; preds = %14
  %279 = load i32, ptr %4, align 4
  %280 = xor i32 %279, -1380543750
  store i32 %280, ptr %4, align 4
  %281 = xor i32 %0, -1022623307
  %282 = and i32 %0, %281
  %283 = or i32 %0, %281
  %284 = xor i32 %0, %281
  %285 = add i32 %0, %281
  %286 = sub i32 %285, %284
  %287 = mul i32 %282, 2
  %288 = sub i32 %286, %287
  %289 = mul i32 %288, 116
  %290 = xor i32 %0, -188231661
  %291 = and i32 %0, %290
  %292 = or i32 %0, %290
  %293 = xor i32 %0, %290
  %294 = mul i32 %292, 2
  %295 = sub i32 %294, %293
  %296 = sub i32 %295, %0
  %297 = sub i32 %296, %290
  %298 = mul i32 %297, 6
  %299 = icmp eq i32 %289, %298
  br i1 %299, label %197, label %484

300:                                              ; preds = %14
  %301 = load i32, ptr %4, align 4
  %302 = xor i32 %301, 903987415
  store i32 %302, ptr %4, align 4
  %303 = xor i32 %0, 77753429
  %304 = and i32 %0, %303
  %305 = or i32 %0, %303
  %306 = xor i32 %0, %303
  %307 = mul i32 %305, 2
  %308 = sub i32 %307, %306
  %309 = sub i32 %308, %0
  %310 = sub i32 %309, %303
  %311 = mul i32 %310, 214
  %312 = icmp slt i32 %311, 0
  br i1 %312, label %492, label %197

313:                                              ; preds = %14
  %314 = load i32, ptr %4, align 4
  %315 = xor i32 %314, 862705917
  store i32 %315, ptr %4, align 4
  %316 = xor i32 %0, -25423407
  %317 = and i32 %0, %316
  %318 = or i32 %0, %316
  %319 = xor i32 %0, %316
  %320 = mul i32 %318, 2
  %321 = sub i32 %320, %319
  %322 = sub i32 %321, %0
  %323 = sub i32 %322, %316
  %324 = mul i32 %323, 125
  %325 = xor i32 %0, -1000351895
  %326 = and i32 %0, %325
  %327 = or i32 %0, %325
  %328 = xor i32 %0, %325
  %329 = mul i32 %327, 2
  %330 = sub i32 %329, %328
  %331 = sub i32 %330, %0
  %332 = sub i32 %331, %325
  %333 = mul i32 %332, 196
  %334 = icmp ne i32 %324, %333
  br i1 %334, label %499, label %197

335:                                              ; preds = %14
  %336 = load i32, ptr %4, align 4
  %337 = xor i32 %336, 472537339
  store i32 %337, ptr %4, align 4
  %338 = xor i32 %0, 635303283
  %339 = and i32 %0, %338
  %340 = or i32 %0, %338
  %341 = xor i32 %0, %338
  %342 = mul i32 %340, 2
  %343 = sub i32 %342, %341
  %344 = sub i32 %343, %0
  %345 = sub i32 %344, %338
  %346 = mul i32 %345, 69
  %347 = icmp ugt i32 %346, 0
  br i1 %347, label %506, label %197

348:                                              ; preds = %18
  %349 = load i64, ptr %3, align 8
  %350 = zext i32 %0 to i64
  %351 = zext i32 %1 to i64
  %352 = sub i64 %351, %350
  %353 = mul i64 %352, %351
  %354 = sub i64 %353, %350
  %355 = sub i64 %354, %350
  store i64 %355, ptr %3, align 8
  br label %197

356:                                              ; preds = %27
  %357 = load i64, ptr %3, align 8
  %358 = zext i32 %0 to i64
  %359 = zext i32 %1 to i64
  %360 = and i64 %357, %357
  %361 = mul i64 %360, %359
  %362 = and i64 %361, %359
  %363 = add i64 %362, %358
  %364 = or i64 %363, %359
  %365 = mul i64 %364, %358
  store i64 %365, ptr %3, align 8
  br label %197

366:                                              ; preds = %41
  %367 = load i64, ptr %3, align 8
  %368 = zext i32 %0 to i64
  %369 = zext i32 %1 to i64
  %370 = mul i64 %367, %369
  %371 = xor i64 %370, %367
  %372 = add i64 %371, %367
  %373 = sub i64 %372, %369
  %374 = mul i64 %373, %368
  store i64 %374, ptr %3, align 8
  br label %197

375:                                              ; preds = %72
  %376 = load i64, ptr %3, align 8
  %377 = zext i32 %0 to i64
  %378 = zext i32 %1 to i64
  %379 = xor i64 %378, %378
  %380 = sub i64 %379, %377
  %381 = mul i64 %380, %378
  %382 = sub i64 %381, %378
  %383 = xor i64 %382, %377
  store i64 %383, ptr %3, align 8
  br label %197

384:                                              ; preds = %90
  %385 = load i64, ptr %3, align 8
  %386 = zext i32 %0 to i64
  %387 = zext i32 %1 to i64
  %388 = add i64 %385, %387
  %389 = add i64 %388, %387
  %390 = mul i64 %389, %385
  %391 = or i64 %390, %386
  %392 = xor i64 %391, %386
  %393 = or i64 %392, %385
  store i64 %393, ptr %3, align 8
  br label %197

394:                                              ; preds = %103
  %395 = load i64, ptr %3, align 8
  %396 = zext i32 %0 to i64
  %397 = zext i32 %1 to i64
  %398 = mul i64 %395, %395
  %399 = add i64 %398, %397
  %400 = or i64 %399, %395
  %401 = and i64 %400, %397
  store i64 %401, ptr %3, align 8
  br label %197

402:                                              ; preds = %112
  %403 = load i64, ptr %3, align 8
  %404 = zext i32 %0 to i64
  %405 = zext i32 %1 to i64
  %406 = sub i64 %404, %405
  %407 = and i64 %406, %403
  %408 = and i64 %407, %405
  store i64 %408, ptr %3, align 8
  br label %197

409:                                              ; preds = %136
  %410 = load i64, ptr %3, align 8
  %411 = zext i32 %0 to i64
  %412 = zext i32 %1 to i64
  %413 = add i64 %411, %410
  %414 = add i64 %413, %411
  %415 = or i64 %414, %411
  store i64 %415, ptr %3, align 8
  br label %197

416:                                              ; preds = %151
  %417 = load i64, ptr %3, align 8
  %418 = zext i32 %0 to i64
  %419 = zext i32 %1 to i64
  %420 = mul i64 %417, %417
  %421 = or i64 %420, %419
  %422 = add i64 %421, %418
  store i64 %422, ptr %3, align 8
  br label %197

423:                                              ; preds = %165
  %424 = load i64, ptr %3, align 8
  %425 = zext i32 %0 to i64
  %426 = zext i32 %1 to i64
  %427 = mul i64 %425, %424
  %428 = mul i64 %427, %424
  %429 = and i64 %428, %424
  %430 = or i64 %429, %425
  %431 = xor i64 %430, %426
  store i64 %431, ptr %3, align 8
  br label %197

432:                                              ; preds = %178
  %433 = load i64, ptr %3, align 8
  %434 = zext i32 %0 to i64
  %435 = zext i32 %1 to i64
  %436 = add i64 %433, %434
  %437 = or i64 %436, %434
  %438 = and i64 %437, %433
  %439 = xor i64 %438, %434
  %440 = xor i64 %439, %433
  %441 = add i64 %440, %434
  store i64 %441, ptr %3, align 8
  br label %197

442:                                              ; preds = %198
  %443 = load i64, ptr %3, align 8
  %444 = zext i32 %0 to i64
  %445 = zext i32 %1 to i64
  %446 = add i64 %445, %444
  %447 = mul i64 %446, %444
  %448 = or i64 %447, %445
  %449 = sub i64 %448, %443
  %450 = and i64 %449, %444
  %451 = sub i64 %450, %445
  store i64 %451, ptr %3, align 8
  br label %14

452:                                              ; preds = %208
  %453 = load i64, ptr %3, align 8
  %454 = zext i32 %0 to i64
  %455 = zext i32 %1 to i64
  %456 = or i64 %454, %453
  %457 = or i64 %456, %454
  %458 = or i64 %457, %453
  store i64 %458, ptr %3, align 8
  br label %197

459:                                              ; preds = %227
  %460 = load i64, ptr %3, align 8
  %461 = zext i32 %0 to i64
  %462 = zext i32 %1 to i64
  %463 = or i64 %462, %460
  %464 = add i64 %463, %461
  %465 = or i64 %464, %460
  %466 = or i64 %465, %462
  store i64 %466, ptr %3, align 8
  br label %197

467:                                              ; preds = %247
  %468 = load i64, ptr %3, align 8
  %469 = zext i32 %0 to i64
  %470 = zext i32 %1 to i64
  %471 = mul i64 %468, %470
  %472 = or i64 %471, %470
  %473 = or i64 %472, %469
  store i64 %473, ptr %3, align 8
  br label %197

474:                                              ; preds = %258
  %475 = load i64, ptr %3, align 8
  %476 = zext i32 %0 to i64
  %477 = zext i32 %1 to i64
  %478 = add i64 %476, %475
  %479 = sub i64 %478, %476
  %480 = or i64 %479, %477
  %481 = sub i64 %480, %476
  %482 = xor i64 %481, %476
  %483 = add i64 %482, %475
  store i64 %483, ptr %3, align 8
  br label %197

484:                                              ; preds = %278
  %485 = load i64, ptr %3, align 8
  %486 = zext i32 %0 to i64
  %487 = zext i32 %1 to i64
  %488 = mul i64 %486, %485
  %489 = xor i64 %488, %486
  %490 = add i64 %489, %487
  %491 = xor i64 %490, %486
  store i64 %491, ptr %3, align 8
  br label %197

492:                                              ; preds = %300
  %493 = load i64, ptr %3, align 8
  %494 = zext i32 %0 to i64
  %495 = zext i32 %1 to i64
  %496 = and i64 %495, %494
  %497 = xor i64 %496, %495
  %498 = mul i64 %497, %495
  store i64 %498, ptr %3, align 8
  br label %197

499:                                              ; preds = %313
  %500 = load i64, ptr %3, align 8
  %501 = zext i32 %0 to i64
  %502 = zext i32 %1 to i64
  %503 = or i64 %500, %502
  %504 = xor i64 %503, %502
  %505 = add i64 %504, %500
  store i64 %505, ptr %3, align 8
  br label %197

506:                                              ; preds = %335
  %507 = load i64, ptr %3, align 8
  %508 = zext i32 %0 to i64
  %509 = zext i32 %1 to i64
  %510 = or i64 %509, %507
  %511 = and i64 %510, %507
  %512 = xor i64 %511, %507
  %513 = add i64 %512, %509
  %514 = or i64 %513, %508
  %515 = sub i64 %514, %509
  store i64 %515, ptr %3, align 8
  br label %197
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
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = ptrtoint ptr %0 to i32
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca [16 x i8], align 16
  %12 = alloca i32, align 4
  store i32 126645804, ptr %6, align 4
  br label %13

13:                                               ; preds = %391, %172, %171, %3
  %14 = load i32, ptr %6, align 4
  %15 = sub i32 %14, -1141393994
  %16 = mul i32 %15, 2040040841
  switch i32 %16, label %172 [
    i32 1823210790, label %17
    i32 219361516, label %31
    i32 1973155020, label %43
    i32 1387813348, label %63
    i32 358263713, label %78
    i32 1173900970, label %99
    i32 313112955, label %118
    i32 2010108127, label %130
    i32 762466732, label %143
    i32 1311187885, label %154
    i32 179256265, label %169
    i32 1791311710, label %181
    i32 2009548, label %193
    i32 769939222, label %214
    i32 718927068, label %226
    i32 1133345591, label %238
    i32 397115885, label %250
    i32 1034708932, label %263
    i32 197207116, label %283
  ]

17:                                               ; preds = %13
  store ptr %0, ptr %8, align 8
  store ptr %1, ptr %9, align 8
  store ptr %2, ptr %10, align 8
  store i32 0, ptr %12, align 4
  %18 = load ptr, ptr %8, align 8
  %19 = icmp eq ptr %18, null
  %20 = select i1 %19, i32 -696864702, i32 -882033374
  store i32 %20, ptr %6, align 4
  %21 = xor i32 %5, -421928545
  %22 = and i32 %5, %21
  %23 = or i32 %5, %21
  %24 = xor i32 %5, %21
  %25 = add i32 %5, %21
  %26 = sub i32 %25, %24
  %27 = mul i32 %22, 2
  %28 = sub i32 %26, %27
  %29 = mul i32 %28, 14
  %30 = icmp sle i32 %29, 0
  br i1 %30, label %171, label %303

31:                                               ; preds = %13
  %32 = load ptr, ptr @stderr, align 8
  %33 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %32, ptr noundef @.str.81) #9
  store i32 1, ptr %7, align 4
  store i32 -1821793801, ptr %6, align 4
  %34 = xor i32 %5, -1541883199
  %35 = and i32 %5, %34
  %36 = or i32 %5, %34
  %37 = xor i32 %5, %34
  %38 = add i32 %35, %36
  %39 = sub i32 %38, %5
  %40 = sub i32 %39, %34
  %41 = mul i32 %40, 109
  %42 = icmp sle i32 %41, 0
  br i1 %42, label %171, label %314

43:                                               ; preds = %13
  %44 = load ptr, ptr %8, align 8
  %45 = getelementptr inbounds nuw %struct.InputJob, ptr %44, i32 0, i32 0
  %46 = load i32, ptr %45, align 8
  %47 = icmp eq i32 %46, 1
  %48 = select i1 %47, i32 2107214714, i32 -258152551
  %49 = icmp eq i32 %46, 2
  %50 = select i1 %49, i32 -736185073, i32 %48
  %51 = icmp eq i32 %46, 3
  %52 = select i1 %51, i32 589250192, i32 %50
  store i32 %52, ptr %6, align 4
  %53 = xor i32 %5, 1481541161
  %54 = and i32 %5, %53
  %55 = or i32 %5, %53
  %56 = xor i32 %5, %53
  %57 = add i32 %5, %53
  %58 = sub i32 %57, %56
  %59 = mul i32 %54, 2
  %60 = sub i32 %58, %59
  %61 = mul i32 %60, 106
  %62 = icmp eq i32 %61, 0
  br i1 %62, label %171, label %323

63:                                               ; preds = %13
  %64 = load ptr, ptr @stdin, align 8
  %65 = getelementptr inbounds [16 x i8], ptr %11, i64 0, i64 0
  %66 = load ptr, ptr %9, align 8
  %67 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %66, i32 0, i32 0
  %68 = load i32, ptr %67, align 8
  %69 = call i32 @hash_stream(ptr noundef %64, ptr noundef @.str.10, ptr noundef %65, i32 noundef %68)
  store i32 %69, ptr %12, align 4
  store i32 2057350877, ptr %6, align 4
  %70 = xor i32 %5, 813978491
  %71 = and i32 %5, %70
  %72 = or i32 %5, %70
  %73 = xor i32 %5, %70
  %74 = sub i32 %72, %73
  %75 = sub i32 %74, %71
  %76 = mul i32 %75, 246
  %77 = icmp eq i32 %76, 0
  br i1 %77, label %171, label %331

78:                                               ; preds = %13
  %79 = load ptr, ptr %8, align 8
  %80 = getelementptr inbounds nuw %struct.InputJob, ptr %79, i32 0, i32 1
  %81 = load ptr, ptr %80, align 8
  %82 = load ptr, ptr %8, align 8
  %83 = getelementptr inbounds nuw %struct.InputJob, ptr %82, i32 0, i32 1
  %84 = load ptr, ptr %83, align 8
  %85 = call i64 @strlen(ptr noundef %84) #11
  %86 = getelementptr inbounds [16 x i8], ptr %11, i64 0, i64 0
  %87 = load ptr, ptr %9, align 8
  %88 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %87, i32 0, i32 0
  %89 = load i32, ptr %88, align 8
  call void @md5_hash_memory(ptr noundef %81, i64 noundef %85, ptr noundef %86, i32 noundef %89)
  store i32 0, ptr %12, align 4
  store i32 2057350877, ptr %6, align 4
  %90 = xor i32 %5, 1805275293
  %91 = and i32 %5, %90
  %92 = or i32 %5, %90
  %93 = xor i32 %5, %90
  %94 = add i32 %91, %92
  %95 = sub i32 %94, %5
  %96 = sub i32 %95, %90
  %97 = mul i32 %96, 54
  %98 = icmp ugt i32 %97, 0
  br i1 %98, label %339, label %171

99:                                               ; preds = %13
  %100 = load ptr, ptr %8, align 8
  %101 = getelementptr inbounds nuw %struct.InputJob, ptr %100, i32 0, i32 1
  %102 = load ptr, ptr %101, align 8
  %103 = getelementptr inbounds [16 x i8], ptr %11, i64 0, i64 0
  %104 = load ptr, ptr %9, align 8
  %105 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %104, i32 0, i32 0
  %106 = load i32, ptr %105, align 8
  %107 = call i32 @hash_file_path(ptr noundef %102, ptr noundef %103, i32 noundef %106)
  store i32 %107, ptr %12, align 4
  store i32 2057350877, ptr %6, align 4
  %108 = xor i32 %5, 786435805
  %109 = and i32 %5, %108
  %110 = or i32 %5, %108
  %111 = xor i32 %5, %108
  %112 = mul i32 %110, 2
  %113 = sub i32 %112, %111
  %114 = sub i32 %113, %5
  %115 = sub i32 %114, %108
  %116 = mul i32 %115, 189
  %117 = icmp ne i32 %116, 0
  br i1 %117, label %348, label %171

118:                                              ; preds = %13
  %119 = load ptr, ptr @stderr, align 8
  %120 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %119, ptr noundef @.str.82) #9
  store i32 1, ptr %7, align 4
  store i32 -1821793801, ptr %6, align 4
  %121 = xor i32 %5, 2060927321
  %122 = and i32 %5, %121
  %123 = or i32 %5, %121
  %124 = xor i32 %5, %121
  %125 = add i32 %122, %123
  %126 = sub i32 %125, %5
  %127 = sub i32 %126, %121
  %128 = mul i32 %127, 141
  %129 = icmp eq i32 %128, 0
  br i1 %129, label %171, label %357

130:                                              ; preds = %13
  %131 = load i32, ptr %12, align 4
  %132 = icmp ne i32 %131, 0
  %133 = select i1 %132, i32 -1330685182, i32 -1224141381
  store i32 %133, ptr %6, align 4
  %134 = xor i32 %5, 1527957097
  %135 = and i32 %5, %134
  %136 = or i32 %5, %134
  %137 = xor i32 %5, %134
  %138 = add i32 %135, %136
  %139 = sub i32 %138, %5
  %140 = sub i32 %139, %134
  %141 = mul i32 %140, 115
  %142 = icmp ugt i32 %141, 0
  br i1 %142, label %365, label %171

143:                                              ; preds = %13
  %144 = load i32, ptr %12, align 4
  store i32 %144, ptr %7, align 4
  store i32 -1821793801, ptr %6, align 4
  %145 = xor i32 %5, 1116526357
  %146 = and i32 %5, %145
  %147 = or i32 %5, %145
  %148 = xor i32 %5, %145
  %149 = add i32 %146, %147
  %150 = sub i32 %149, %5
  %151 = sub i32 %150, %145
  %152 = mul i32 %151, 215
  %153 = icmp uge i32 %152, 0
  br i1 %153, label %171, label %373

154:                                              ; preds = %13
  %155 = getelementptr inbounds [16 x i8], ptr %11, i64 0, i64 0
  %156 = load ptr, ptr %8, align 8
  %157 = getelementptr inbounds nuw %struct.InputJob, ptr %156, i32 0, i32 2
  %158 = load ptr, ptr %157, align 8
  %159 = load ptr, ptr %10, align 8
  call void @print_digest(ptr noundef %155, ptr noundef %158, ptr noundef %159)
  %160 = getelementptr inbounds [16 x i8], ptr %11, i64 0, i64 0
  call void @zero_memory(ptr noundef %160, i64 noundef 16)
  store i32 0, ptr %7, align 4
  store i32 -1821793801, ptr %6, align 4
  %161 = xor i32 %5, -1011582321
  %162 = and i32 %5, %161
  %163 = or i32 %5, %161
  %164 = xor i32 %5, %161
  %165 = sub i32 %163, %164
  %166 = sub i32 %165, %162
  %167 = mul i32 %166, 228
  %168 = icmp ne i32 %167, 0
  br i1 %168, label %383, label %171

169:                                              ; preds = %13
  %170 = load i32, ptr %7, align 4
  ret i32 %170

171:                                              ; preds = %469, %458, %447, %437, %429, %421, %413, %402, %383, %373, %365, %357, %348, %339, %331, %323, %314, %303, %283, %263, %250, %238, %226, %214, %193, %181, %154, %143, %130, %118, %99, %78, %63, %43, %31, %17
  br label %13

172:                                              ; preds = %13
  store i32 126645804, ptr %6, align 4
  call void asm sideeffect "", ""()
  %173 = xor i32 %5, -1009841279
  %174 = and i32 %5, %173
  %175 = or i32 %5, %173
  %176 = xor i32 %5, %173
  %177 = sub i32 %175, %176
  %178 = sub i32 %177, %174
  %179 = mul i32 %178, 209
  %180 = icmp ugt i32 %179, 0
  br i1 %180, label %391, label %13

181:                                              ; preds = %13
  %182 = load i32, ptr %6, align 4
  %183 = xor i32 %182, 1540874537
  store i32 %183, ptr %6, align 4
  %184 = xor i32 %5, 2072657273
  %185 = and i32 %5, %184
  %186 = or i32 %5, %184
  %187 = xor i32 %5, %184
  %188 = add i32 %185, %186
  %189 = sub i32 %188, %5
  %190 = sub i32 %189, %184
  %191 = mul i32 %190, 183
  %192 = icmp uge i32 %191, 0
  br i1 %192, label %171, label %402

193:                                              ; preds = %13
  %194 = load i32, ptr %6, align 4
  %195 = xor i32 %194, -1233380639
  store i32 %195, ptr %6, align 4
  %196 = xor i32 %5, -464402587
  %197 = and i32 %5, %196
  %198 = or i32 %5, %196
  %199 = xor i32 %5, %196
  %200 = add i32 %197, %198
  %201 = sub i32 %200, %5
  %202 = sub i32 %201, %196
  %203 = mul i32 %202, 38
  %204 = xor i32 %5, -1492265961
  %205 = and i32 %5, %204
  %206 = or i32 %5, %204
  %207 = xor i32 %5, %204
  %208 = add i32 %5, %204
  %209 = sub i32 %208, %207
  %210 = mul i32 %205, 2
  %211 = sub i32 %209, %210
  %212 = mul i32 %211, 71
  %213 = icmp ne i32 %203, %212
  br i1 %213, label %413, label %171

214:                                              ; preds = %13
  %215 = load i32, ptr %6, align 4
  %216 = xor i32 %215, 153743579
  store i32 %216, ptr %6, align 4
  %217 = xor i32 %5, -1689530559
  %218 = and i32 %5, %217
  %219 = or i32 %5, %217
  %220 = xor i32 %5, %217
  %221 = add i32 %218, %219
  %222 = sub i32 %221, %5
  %223 = sub i32 %222, %217
  %224 = mul i32 %223, 153
  %225 = icmp sle i32 %224, 0
  br i1 %225, label %171, label %421

226:                                              ; preds = %13
  %227 = load i32, ptr %6, align 4
  %228 = xor i32 %227, -984479123
  store i32 %228, ptr %6, align 4
  %229 = xor i32 %5, -2109109137
  %230 = and i32 %5, %229
  %231 = or i32 %5, %229
  %232 = xor i32 %5, %229
  %233 = add i32 %230, %231
  %234 = sub i32 %233, %5
  %235 = sub i32 %234, %229
  %236 = mul i32 %235, 218
  %237 = icmp slt i32 %236, 0
  br i1 %237, label %429, label %171

238:                                              ; preds = %13
  %239 = load i32, ptr %6, align 4
  %240 = xor i32 %239, -1781232015
  store i32 %240, ptr %6, align 4
  %241 = xor i32 %5, -1020305601
  %242 = and i32 %5, %241
  %243 = or i32 %5, %241
  %244 = xor i32 %5, %241
  %245 = add i32 %242, %243
  %246 = sub i32 %245, %5
  %247 = sub i32 %246, %241
  %248 = mul i32 %247, 120
  %249 = icmp ne i32 %248, 0
  br i1 %249, label %437, label %171

250:                                              ; preds = %13
  %251 = load i32, ptr %6, align 4
  %252 = xor i32 %251, 1441090318
  store i32 %252, ptr %6, align 4
  %253 = xor i32 %5, -643266769
  %254 = and i32 %5, %253
  %255 = or i32 %5, %253
  %256 = xor i32 %5, %253
  %257 = add i32 %5, %253
  %258 = sub i32 %257, %256
  %259 = mul i32 %254, 2
  %260 = sub i32 %258, %259
  %261 = mul i32 %260, 81
  %262 = icmp uge i32 %261, 0
  br i1 %262, label %171, label %447

263:                                              ; preds = %13
  %264 = load i32, ptr %6, align 4
  %265 = xor i32 %264, 517998071
  store i32 %265, ptr %6, align 4
  %266 = xor i32 %5, 1281079415
  %267 = and i32 %5, %266
  %268 = or i32 %5, %266
  %269 = xor i32 %5, %266
  %270 = add i32 %267, %268
  %271 = sub i32 %270, %5
  %272 = sub i32 %271, %266
  %273 = mul i32 %272, 174
  %274 = xor i32 %5, 1552401891
  %275 = and i32 %5, %274
  %276 = or i32 %5, %274
  %277 = xor i32 %5, %274
  %278 = add i32 %275, %276
  %279 = sub i32 %278, %5
  %280 = sub i32 %279, %274
  %281 = mul i32 %280, 213
  %282 = icmp eq i32 %273, %281
  br i1 %282, label %171, label %458

283:                                              ; preds = %13
  %284 = load i32, ptr %6, align 4
  %285 = xor i32 %284, 1892830545
  store i32 %285, ptr %6, align 4
  %286 = xor i32 %5, 1806290845
  %287 = and i32 %5, %286
  %288 = or i32 %5, %286
  %289 = xor i32 %5, %286
  %290 = sub i32 %288, %289
  %291 = sub i32 %290, %287
  %292 = mul i32 %291, 48
  %293 = xor i32 %5, -1487301413
  %294 = and i32 %5, %293
  %295 = or i32 %5, %293
  %296 = xor i32 %5, %293
  %297 = mul i32 %295, 2
  %298 = sub i32 %297, %296
  %299 = sub i32 %298, %5
  %300 = sub i32 %299, %293
  %301 = mul i32 %300, 20
  %302 = icmp eq i32 %292, %301
  br i1 %302, label %171, label %469

303:                                              ; preds = %17
  %304 = load i64, ptr %4, align 8
  %305 = ptrtoint ptr %0 to i64
  %306 = ptrtoint ptr %1 to i64
  %307 = ptrtoint ptr %2 to i64
  %308 = add i64 %305, %306
  %309 = or i64 %308, %304
  %310 = xor i64 %309, %305
  %311 = add i64 %310, %306
  %312 = add i64 %311, %305
  %313 = or i64 %312, %304
  store i64 %313, ptr %4, align 8
  br label %171

314:                                              ; preds = %31
  %315 = load i64, ptr %4, align 8
  %316 = ptrtoint ptr %0 to i64
  %317 = ptrtoint ptr %1 to i64
  %318 = ptrtoint ptr %2 to i64
  %319 = add i64 %316, %317
  %320 = add i64 %319, %316
  %321 = add i64 %320, %315
  %322 = xor i64 %321, %318
  store i64 %322, ptr %4, align 8
  br label %171

323:                                              ; preds = %43
  %324 = load i64, ptr %4, align 8
  %325 = ptrtoint ptr %0 to i64
  %326 = ptrtoint ptr %1 to i64
  %327 = ptrtoint ptr %2 to i64
  %328 = mul i64 %326, %325
  %329 = add i64 %328, %324
  %330 = and i64 %329, %324
  store i64 %330, ptr %4, align 8
  br label %171

331:                                              ; preds = %63
  %332 = load i64, ptr %4, align 8
  %333 = ptrtoint ptr %0 to i64
  %334 = ptrtoint ptr %1 to i64
  %335 = ptrtoint ptr %2 to i64
  %336 = xor i64 %333, %334
  %337 = xor i64 %336, %335
  %338 = add i64 %337, %334
  store i64 %338, ptr %4, align 8
  br label %171

339:                                              ; preds = %78
  %340 = load i64, ptr %4, align 8
  %341 = ptrtoint ptr %0 to i64
  %342 = ptrtoint ptr %1 to i64
  %343 = ptrtoint ptr %2 to i64
  %344 = xor i64 %342, %342
  %345 = or i64 %344, %342
  %346 = sub i64 %345, %343
  %347 = and i64 %346, %342
  store i64 %347, ptr %4, align 8
  br label %171

348:                                              ; preds = %99
  %349 = load i64, ptr %4, align 8
  %350 = ptrtoint ptr %0 to i64
  %351 = ptrtoint ptr %1 to i64
  %352 = ptrtoint ptr %2 to i64
  %353 = mul i64 %351, %350
  %354 = or i64 %353, %349
  %355 = or i64 %354, %349
  %356 = mul i64 %355, %351
  store i64 %356, ptr %4, align 8
  br label %171

357:                                              ; preds = %118
  %358 = load i64, ptr %4, align 8
  %359 = ptrtoint ptr %0 to i64
  %360 = ptrtoint ptr %1 to i64
  %361 = ptrtoint ptr %2 to i64
  %362 = mul i64 %359, %360
  %363 = mul i64 %362, %360
  %364 = or i64 %363, %358
  store i64 %364, ptr %4, align 8
  br label %171

365:                                              ; preds = %130
  %366 = load i64, ptr %4, align 8
  %367 = ptrtoint ptr %0 to i64
  %368 = ptrtoint ptr %1 to i64
  %369 = ptrtoint ptr %2 to i64
  %370 = add i64 %367, %369
  %371 = add i64 %370, %366
  %372 = sub i64 %371, %367
  store i64 %372, ptr %4, align 8
  br label %171

373:                                              ; preds = %143
  %374 = load i64, ptr %4, align 8
  %375 = ptrtoint ptr %0 to i64
  %376 = ptrtoint ptr %1 to i64
  %377 = ptrtoint ptr %2 to i64
  %378 = and i64 %375, %375
  %379 = mul i64 %378, %377
  %380 = xor i64 %379, %377
  %381 = mul i64 %380, %375
  %382 = add i64 %381, %376
  store i64 %382, ptr %4, align 8
  br label %171

383:                                              ; preds = %154
  %384 = load i64, ptr %4, align 8
  %385 = ptrtoint ptr %0 to i64
  %386 = ptrtoint ptr %1 to i64
  %387 = ptrtoint ptr %2 to i64
  %388 = xor i64 %384, %387
  %389 = and i64 %388, %386
  %390 = xor i64 %389, %385
  store i64 %390, ptr %4, align 8
  br label %171

391:                                              ; preds = %172
  %392 = load i64, ptr %4, align 8
  %393 = ptrtoint ptr %0 to i64
  %394 = ptrtoint ptr %1 to i64
  %395 = ptrtoint ptr %2 to i64
  %396 = xor i64 %395, %394
  %397 = and i64 %396, %392
  %398 = xor i64 %397, %393
  %399 = xor i64 %398, %392
  %400 = add i64 %399, %395
  %401 = sub i64 %400, %393
  store i64 %401, ptr %4, align 8
  br label %13

402:                                              ; preds = %181
  %403 = load i64, ptr %4, align 8
  %404 = ptrtoint ptr %0 to i64
  %405 = ptrtoint ptr %1 to i64
  %406 = ptrtoint ptr %2 to i64
  %407 = or i64 %404, %404
  %408 = or i64 %407, %405
  %409 = or i64 %408, %403
  %410 = xor i64 %409, %404
  %411 = mul i64 %410, %405
  %412 = and i64 %411, %406
  store i64 %412, ptr %4, align 8
  br label %171

413:                                              ; preds = %193
  %414 = load i64, ptr %4, align 8
  %415 = ptrtoint ptr %0 to i64
  %416 = ptrtoint ptr %1 to i64
  %417 = ptrtoint ptr %2 to i64
  %418 = and i64 %417, %416
  %419 = or i64 %418, %414
  %420 = and i64 %419, %414
  store i64 %420, ptr %4, align 8
  br label %171

421:                                              ; preds = %214
  %422 = load i64, ptr %4, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = ptrtoint ptr %1 to i64
  %425 = ptrtoint ptr %2 to i64
  %426 = sub i64 %425, %425
  %427 = mul i64 %426, %423
  %428 = or i64 %427, %422
  store i64 %428, ptr %4, align 8
  br label %171

429:                                              ; preds = %226
  %430 = load i64, ptr %4, align 8
  %431 = ptrtoint ptr %0 to i64
  %432 = ptrtoint ptr %1 to i64
  %433 = ptrtoint ptr %2 to i64
  %434 = add i64 %430, %430
  %435 = add i64 %434, %432
  %436 = add i64 %435, %433
  store i64 %436, ptr %4, align 8
  br label %171

437:                                              ; preds = %238
  %438 = load i64, ptr %4, align 8
  %439 = ptrtoint ptr %0 to i64
  %440 = ptrtoint ptr %1 to i64
  %441 = ptrtoint ptr %2 to i64
  %442 = sub i64 %441, %441
  %443 = and i64 %442, %438
  %444 = and i64 %443, %440
  %445 = sub i64 %444, %439
  %446 = sub i64 %445, %438
  store i64 %446, ptr %4, align 8
  br label %171

447:                                              ; preds = %250
  %448 = load i64, ptr %4, align 8
  %449 = ptrtoint ptr %0 to i64
  %450 = ptrtoint ptr %1 to i64
  %451 = ptrtoint ptr %2 to i64
  %452 = and i64 %450, %448
  %453 = xor i64 %452, %451
  %454 = or i64 %453, %449
  %455 = or i64 %454, %448
  %456 = add i64 %455, %449
  %457 = and i64 %456, %448
  store i64 %457, ptr %4, align 8
  br label %171

458:                                              ; preds = %263
  %459 = load i64, ptr %4, align 8
  %460 = ptrtoint ptr %0 to i64
  %461 = ptrtoint ptr %1 to i64
  %462 = ptrtoint ptr %2 to i64
  %463 = xor i64 %459, %460
  %464 = sub i64 %463, %459
  %465 = and i64 %464, %462
  %466 = sub i64 %465, %462
  %467 = or i64 %466, %460
  %468 = and i64 %467, %460
  store i64 %468, ptr %4, align 8
  br label %171

469:                                              ; preds = %283
  %470 = load i64, ptr %4, align 8
  %471 = ptrtoint ptr %0 to i64
  %472 = ptrtoint ptr %1 to i64
  %473 = ptrtoint ptr %2 to i64
  %474 = or i64 %472, %470
  %475 = and i64 %474, %472
  %476 = add i64 %475, %473
  %477 = and i64 %476, %471
  %478 = or i64 %477, %472
  %479 = sub i64 %478, %470
  store i64 %479, ptr %4, align 8
  br label %171
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @free_input_job(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  store i32 -468198539, ptr %4, align 4
  br label %6

6:                                                ; preds = %169, %58, %57, %1
  %7 = load i32, ptr %4, align 4
  %8 = sub i32 %7, 168679426
  %9 = mul i32 %8, -1663799127
  %10 = icmp slt i32 %9, 700072101
  br i1 %10, label %125, label %127

11:                                               ; preds = %143
  store ptr %0, ptr %5, align 8
  %12 = load ptr, ptr %5, align 8
  %13 = icmp eq ptr %12, null
  %14 = select i1 %13, i32 -1787503368, i32 1176420057
  store i32 %14, ptr %4, align 4
  %15 = xor i32 %3, 149199881
  %16 = and i32 %3, %15
  %17 = or i32 %3, %15
  %18 = xor i32 %3, %15
  %19 = sub i32 %17, %18
  %20 = sub i32 %19, %16
  %21 = mul i32 %20, 16
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %57, label %145

23:                                               ; preds = %135
  store i32 -321634551, ptr %4, align 4
  %24 = xor i32 %3, 1476488069
  %25 = and i32 %3, %24
  %26 = or i32 %3, %24
  %27 = xor i32 %3, %24
  %28 = add i32 %25, %26
  %29 = sub i32 %28, %3
  %30 = sub i32 %29, %24
  %31 = mul i32 %30, 253
  %32 = icmp slt i32 %31, 1
  br i1 %32, label %57, label %154

33:                                               ; preds = %139
  %34 = load ptr, ptr %5, align 8
  %35 = getelementptr inbounds nuw %struct.InputJob, ptr %34, i32 0, i32 1
  %36 = load ptr, ptr %35, align 8
  call void @free(ptr noundef %36) #9
  %37 = load ptr, ptr %5, align 8
  %38 = getelementptr inbounds nuw %struct.InputJob, ptr %37, i32 0, i32 2
  %39 = load ptr, ptr %38, align 8
  call void @free(ptr noundef %39) #9
  %40 = load ptr, ptr %5, align 8
  %41 = getelementptr inbounds nuw %struct.InputJob, ptr %40, i32 0, i32 1
  store ptr null, ptr %41, align 8
  %42 = load ptr, ptr %5, align 8
  %43 = getelementptr inbounds nuw %struct.InputJob, ptr %42, i32 0, i32 2
  store ptr null, ptr %43, align 8
  %44 = load ptr, ptr %5, align 8
  %45 = getelementptr inbounds nuw %struct.InputJob, ptr %44, i32 0, i32 0
  store i32 0, ptr %45, align 8
  store i32 -321634551, ptr %4, align 4
  %46 = xor i32 %3, -2004412955
  %47 = and i32 %3, %46
  %48 = or i32 %3, %46
  %49 = xor i32 %3, %46
  %50 = add i32 %3, %46
  %51 = sub i32 %50, %49
  %52 = mul i32 %47, 2
  %53 = sub i32 %51, %52
  %54 = mul i32 %53, 27
  %55 = icmp sle i32 %54, 0
  br i1 %55, label %57, label %163

56:                                               ; preds = %131
  ret void

57:                                               ; preds = %201, %194, %185, %177, %163, %154, %145, %112, %100, %88, %67, %33, %23, %11
  br label %6

58:                                               ; preds = %143, %141, %135, %133
  store i32 -468198539, ptr %4, align 4
  call void asm sideeffect "", ""()
  %59 = xor i32 %3, 1270786123
  %60 = and i32 %3, %59
  %61 = or i32 %3, %59
  %62 = xor i32 %3, %59
  %63 = sub i32 %61, %62
  %64 = sub i32 %63, %60
  %65 = mul i32 %64, 196
  %66 = icmp uge i32 %65, 0
  br i1 %66, label %6, label %169

67:                                               ; preds = %141
  %68 = load i32, ptr %4, align 4
  %69 = xor i32 %68, 1427855437
  store i32 %69, ptr %4, align 4
  %70 = xor i32 %3, -2008828411
  %71 = and i32 %3, %70
  %72 = or i32 %3, %70
  %73 = xor i32 %3, %70
  %74 = add i32 %3, %70
  %75 = sub i32 %74, %73
  %76 = mul i32 %71, 2
  %77 = sub i32 %75, %76
  %78 = mul i32 %77, 226
  %79 = xor i32 %3, -1247580179
  %80 = and i32 %3, %79
  %81 = or i32 %3, %79
  %82 = xor i32 %3, %79
  %83 = add i32 %80, %81
  %84 = sub i32 %83, %3
  %85 = sub i32 %84, %79
  %86 = mul i32 %85, 88
  %87 = icmp ne i32 %78, %86
  br i1 %87, label %177, label %57

88:                                               ; preds = %129
  %89 = load i32, ptr %4, align 4
  %90 = xor i32 %89, 1564069428
  store i32 %90, ptr %4, align 4
  %91 = xor i32 %3, -1743967431
  %92 = and i32 %3, %91
  %93 = or i32 %3, %91
  %94 = xor i32 %3, %91
  %95 = add i32 %92, %93
  %96 = sub i32 %95, %3
  %97 = sub i32 %96, %91
  %98 = mul i32 %97, 198
  %99 = icmp eq i32 %98, 0
  br i1 %99, label %57, label %185

100:                                              ; preds = %137
  %101 = load i32, ptr %4, align 4
  %102 = xor i32 %101, -2133355789
  store i32 %102, ptr %4, align 4
  %103 = xor i32 %3, 1886752887
  %104 = and i32 %3, %103
  %105 = or i32 %3, %103
  %106 = xor i32 %3, %103
  %107 = add i32 %104, %105
  %108 = sub i32 %107, %3
  %109 = sub i32 %108, %103
  %110 = mul i32 %109, 108
  %111 = icmp sle i32 %110, 0
  br i1 %111, label %57, label %194

112:                                              ; preds = %133
  %113 = load i32, ptr %4, align 4
  %114 = xor i32 %113, -219717474
  store i32 %114, ptr %4, align 4
  %115 = xor i32 %3, -783278357
  %116 = and i32 %3, %115
  %117 = or i32 %3, %115
  %118 = xor i32 %3, %115
  %119 = mul i32 %117, 2
  %120 = sub i32 %119, %118
  %121 = sub i32 %120, %3
  %122 = sub i32 %121, %115
  %123 = mul i32 %122, 126
  %124 = icmp slt i32 %123, 1
  br i1 %124, label %57, label %201

125:                                              ; preds = %6
  %126 = icmp slt i32 %9, 400102303
  br i1 %126, label %129, label %131

127:                                              ; preds = %6
  %128 = icmp slt i32 %9, 976385007
  br i1 %128, label %137, label %139

129:                                              ; preds = %125
  %130 = icmp eq i32 %9, 9730006
  br i1 %130, label %88, label %133

131:                                              ; preds = %125
  %132 = icmp eq i32 %9, 400102303
  br i1 %132, label %56, label %135

133:                                              ; preds = %129
  %134 = icmp eq i32 %9, 83081764
  br i1 %134, label %112, label %58

135:                                              ; preds = %131
  %136 = icmp eq i32 %9, 484828774
  br i1 %136, label %23, label %58

137:                                              ; preds = %127
  %138 = icmp eq i32 %9, 700072101
  br i1 %138, label %100, label %141

139:                                              ; preds = %127
  %140 = icmp eq i32 %9, 976385007
  br i1 %140, label %33, label %143

141:                                              ; preds = %137
  %142 = icmp eq i32 %9, 929672255
  br i1 %142, label %67, label %58

143:                                              ; preds = %139
  %144 = icmp eq i32 %9, 1096455915
  br i1 %144, label %11, label %58

145:                                              ; preds = %11
  %146 = load i64, ptr %2, align 8
  %147 = ptrtoint ptr %0 to i64
  %148 = mul i64 %146, %146
  %149 = sub i64 %148, %146
  %150 = sub i64 %149, %146
  %151 = and i64 %150, %147
  %152 = or i64 %151, %147
  %153 = add i64 %152, %147
  store i64 %153, ptr %2, align 8
  br label %57

154:                                              ; preds = %23
  %155 = load i64, ptr %2, align 8
  %156 = ptrtoint ptr %0 to i64
  %157 = mul i64 %155, %155
  %158 = xor i64 %157, %156
  %159 = or i64 %158, %156
  %160 = sub i64 %159, %156
  %161 = sub i64 %160, %155
  %162 = or i64 %161, %156
  store i64 %162, ptr %2, align 8
  br label %57

163:                                              ; preds = %33
  %164 = load i64, ptr %2, align 8
  %165 = ptrtoint ptr %0 to i64
  %166 = mul i64 %164, %164
  %167 = add i64 %166, %165
  %168 = mul i64 %167, %165
  store i64 %168, ptr %2, align 8
  br label %57

169:                                              ; preds = %58
  %170 = load i64, ptr %2, align 8
  %171 = ptrtoint ptr %0 to i64
  %172 = and i64 %170, %170
  %173 = add i64 %172, %170
  %174 = sub i64 %173, %170
  %175 = add i64 %174, %170
  %176 = and i64 %175, %170
  store i64 %176, ptr %2, align 8
  br label %6

177:                                              ; preds = %67
  %178 = load i64, ptr %2, align 8
  %179 = ptrtoint ptr %0 to i64
  %180 = or i64 %178, %179
  %181 = or i64 %180, %179
  %182 = mul i64 %181, %178
  %183 = xor i64 %182, %178
  %184 = or i64 %183, %178
  store i64 %184, ptr %2, align 8
  br label %57

185:                                              ; preds = %88
  %186 = load i64, ptr %2, align 8
  %187 = ptrtoint ptr %0 to i64
  %188 = xor i64 %187, %186
  %189 = or i64 %188, %187
  %190 = mul i64 %189, %187
  %191 = add i64 %190, %187
  %192 = sub i64 %191, %187
  %193 = or i64 %192, %187
  store i64 %193, ptr %2, align 8
  br label %57

194:                                              ; preds = %100
  %195 = load i64, ptr %2, align 8
  %196 = ptrtoint ptr %0 to i64
  %197 = and i64 %196, %195
  %198 = mul i64 %197, %196
  %199 = mul i64 %198, %196
  %200 = xor i64 %199, %196
  store i64 %200, ptr %2, align 8
  br label %57

201:                                              ; preds = %112
  %202 = load i64, ptr %2, align 8
  %203 = ptrtoint ptr %0 to i64
  %204 = mul i64 %202, %202
  %205 = xor i64 %204, %202
  %206 = or i64 %205, %203
  %207 = mul i64 %206, %202
  store i64 %207, ptr %2, align 8
  br label %57
}

; Function Attrs: nounwind
declare void @free(ptr noundef) #1

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @hash_stream(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3) #0 {
  %5 = alloca i64, align 8
  store i64 0, ptr %5, align 8
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca ptr, align 8
  %15 = alloca i32, align 4
  %16 = alloca %struct.MD5Context, align 8
  %17 = alloca [8192 x i8], align 16
  %18 = alloca i64, align 8
  store i32 -600766069, ptr %6, align 4
  br label %19

19:                                               ; preds = %639, %269, %268, %4
  %20 = load i32, ptr %6, align 4
  %21 = sub i32 %20, -1088726609
  %22 = mul i32 %21, 352139375
  %23 = icmp slt i32 %22, 1266775110
  br i1 %23, label %400, label %402

24:                                               ; preds = %452
  store ptr %0, ptr %12, align 8
  store ptr %1, ptr %13, align 8
  store ptr %2, ptr %14, align 8
  store i32 %3, ptr %15, align 4
  %25 = load ptr, ptr %12, align 8
  %26 = icmp eq ptr %25, null
  %27 = select i1 %26, i32 967813926, i32 -1228137401
  store i32 %27, ptr %6, align 4
  %28 = xor i32 %3, 1138715427
  %29 = and i32 %3, %28
  %30 = or i32 %3, %28
  %31 = xor i32 %3, %28
  %32 = add i32 %29, %30
  %33 = sub i32 %32, %3
  %34 = sub i32 %33, %28
  %35 = mul i32 %34, 41
  %36 = icmp sle i32 %35, 0
  br i1 %36, label %268, label %478

37:                                               ; preds = %466
  %38 = load ptr, ptr @stderr, align 8
  store ptr %38, ptr %7, align 8
  %39 = load ptr, ptr %13, align 8
  %40 = icmp ne ptr %39, null
  %41 = select i1 %40, i32 -792272155, i32 -178851353
  store i32 %41, ptr %6, align 4
  %42 = xor i32 %3, -894009809
  %43 = and i32 %3, %42
  %44 = or i32 %3, %42
  %45 = xor i32 %3, %42
  %46 = add i32 %43, %44
  %47 = sub i32 %46, %3
  %48 = sub i32 %47, %42
  %49 = mul i32 %48, 121
  %50 = icmp uge i32 %49, 0
  br i1 %50, label %268, label %487

51:                                               ; preds = %412
  %52 = load ptr, ptr %13, align 8
  store ptr %52, ptr %9, align 8
  store i32 467404899, ptr %6, align 4
  %53 = xor i32 %3, 1028907959
  %54 = and i32 %3, %53
  %55 = or i32 %3, %53
  %56 = xor i32 %3, %53
  %57 = add i32 %54, %55
  %58 = sub i32 %57, %3
  %59 = sub i32 %58, %53
  %60 = mul i32 %59, 40
  %61 = icmp slt i32 %60, 0
  br i1 %61, label %497, label %268

62:                                               ; preds = %456
  store ptr @.str.84, ptr %9, align 8
  store i32 467404899, ptr %6, align 4
  %63 = xor i32 %3, -1961407407
  %64 = and i32 %3, %63
  %65 = or i32 %3, %63
  %66 = xor i32 %3, %63
  %67 = add i32 %3, %63
  %68 = sub i32 %67, %66
  %69 = mul i32 %64, 2
  %70 = sub i32 %68, %69
  %71 = mul i32 %70, 229
  %72 = xor i32 %3, 896888265
  %73 = and i32 %3, %72
  %74 = or i32 %3, %72
  %75 = xor i32 %3, %72
  %76 = mul i32 %74, 2
  %77 = sub i32 %76, %75
  %78 = sub i32 %77, %3
  %79 = sub i32 %78, %72
  %80 = mul i32 %79, 218
  %81 = icmp eq i32 %71, %80
  br i1 %81, label %268, label %506

82:                                               ; preds = %422
  %83 = load ptr, ptr %9, align 8
  %84 = load ptr, ptr %7, align 8
  %85 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %84, ptr noundef @.str.83, ptr noundef %83) #9
  store i32 1, ptr %11, align 4
  store i32 -1435783216, ptr %6, align 4
  %86 = xor i32 %3, -789388825
  %87 = and i32 %3, %86
  %88 = or i32 %3, %86
  %89 = xor i32 %3, %86
  %90 = add i32 %87, %88
  %91 = sub i32 %90, %3
  %92 = sub i32 %91, %86
  %93 = mul i32 %92, 45
  %94 = icmp ne i32 %93, 0
  br i1 %94, label %516, label %268

95:                                               ; preds = %438
  call void @md5_context_init(ptr noundef %16)
  %96 = load i32, ptr %15, align 4
  call void @md5_context_enable_trace(ptr noundef %16, i32 noundef %96)
  store i32 1525625907, ptr %6, align 4
  %97 = xor i32 %3, -1940824497
  %98 = and i32 %3, %97
  %99 = or i32 %3, %97
  %100 = xor i32 %3, %97
  %101 = sub i32 %99, %100
  %102 = sub i32 %101, %98
  %103 = mul i32 %102, 45
  %104 = xor i32 %3, -525140913
  %105 = and i32 %3, %104
  %106 = or i32 %3, %104
  %107 = xor i32 %3, %104
  %108 = mul i32 %106, 2
  %109 = sub i32 %108, %107
  %110 = sub i32 %109, %3
  %111 = sub i32 %110, %104
  %112 = mul i32 %111, 244
  %113 = icmp eq i32 %103, %112
  br i1 %113, label %268, label %525

114:                                              ; preds = %434
  %115 = getelementptr inbounds [8192 x i8], ptr %17, i64 0, i64 0
  %116 = load ptr, ptr %12, align 8
  %117 = call i64 @fread(ptr noundef %115, i64 noundef 1, i64 noundef 8192, ptr noundef %116)
  store i64 %117, ptr %18, align 8
  %118 = load i64, ptr %18, align 8
  %119 = icmp ugt i64 %118, 0
  %120 = select i1 %119, i32 -2078551841, i32 1396682953
  store i32 %120, ptr %6, align 4
  %121 = xor i32 %3, -958693573
  %122 = and i32 %3, %121
  %123 = or i32 %3, %121
  %124 = xor i32 %3, %121
  %125 = add i32 %3, %121
  %126 = sub i32 %125, %124
  %127 = mul i32 %122, 2
  %128 = sub i32 %126, %127
  %129 = mul i32 %128, 246
  %130 = icmp ugt i32 %129, 0
  br i1 %130, label %534, label %268

131:                                              ; preds = %418
  %132 = getelementptr inbounds [8192 x i8], ptr %17, i64 0, i64 0
  %133 = load i64, ptr %18, align 8
  call void @md5_update_bytes(ptr noundef %16, ptr noundef %132, i64 noundef %133)
  store i32 1396682953, ptr %6, align 4
  %134 = xor i32 %3, -2141810155
  %135 = and i32 %3, %134
  %136 = or i32 %3, %134
  %137 = xor i32 %3, %134
  %138 = add i32 %135, %136
  %139 = sub i32 %138, %3
  %140 = sub i32 %139, %134
  %141 = mul i32 %140, 36
  %142 = icmp ne i32 %141, 0
  br i1 %142, label %546, label %268

143:                                              ; preds = %448
  %144 = load i64, ptr %18, align 8
  %145 = icmp ult i64 %144, 8192
  %146 = select i1 %145, i32 242680592, i32 566098492
  store i32 %146, ptr %6, align 4
  %147 = xor i32 %3, -2098891097
  %148 = and i32 %3, %147
  %149 = or i32 %3, %147
  %150 = xor i32 %3, %147
  %151 = add i32 %3, %147
  %152 = sub i32 %151, %150
  %153 = mul i32 %148, 2
  %154 = sub i32 %152, %153
  %155 = mul i32 %154, 142
  %156 = xor i32 %3, 1142457601
  %157 = and i32 %3, %156
  %158 = or i32 %3, %156
  %159 = xor i32 %3, %156
  %160 = add i32 %3, %156
  %161 = sub i32 %160, %159
  %162 = mul i32 %157, 2
  %163 = sub i32 %161, %162
  %164 = mul i32 %163, 29
  %165 = icmp eq i32 %155, %164
  br i1 %165, label %268, label %557

166:                                              ; preds = %474
  %167 = load ptr, ptr %12, align 8
  %168 = call i32 @ferror(ptr noundef %167) #9
  %169 = icmp ne i32 %168, 0
  %170 = select i1 %169, i32 -1810426032, i32 -637117651
  store i32 %170, ptr %6, align 4
  %171 = xor i32 %3, 517828041
  %172 = and i32 %3, %171
  %173 = or i32 %3, %171
  %174 = xor i32 %3, %171
  %175 = sub i32 %173, %174
  %176 = sub i32 %175, %172
  %177 = mul i32 %176, 101
  %178 = icmp eq i32 %177, 0
  br i1 %178, label %268, label %566

179:                                              ; preds = %468
  %180 = load ptr, ptr @stderr, align 8
  store ptr %180, ptr %8, align 8
  %181 = load ptr, ptr %13, align 8
  %182 = icmp ne ptr %181, null
  %183 = select i1 %182, i32 -292679652, i32 1405515923
  store i32 %183, ptr %6, align 4
  %184 = xor i32 %3, -1457638603
  %185 = and i32 %3, %184
  %186 = or i32 %3, %184
  %187 = xor i32 %3, %184
  %188 = add i32 %185, %186
  %189 = sub i32 %188, %3
  %190 = sub i32 %189, %184
  %191 = mul i32 %190, 88
  %192 = icmp ugt i32 %191, 0
  br i1 %192, label %576, label %268

193:                                              ; preds = %472
  %194 = load ptr, ptr %13, align 8
  store ptr %194, ptr %10, align 8
  store i32 162736283, ptr %6, align 4
  %195 = xor i32 %3, -708709537
  %196 = and i32 %3, %195
  %197 = or i32 %3, %195
  %198 = xor i32 %3, %195
  %199 = add i32 %3, %195
  %200 = sub i32 %199, %198
  %201 = mul i32 %196, 2
  %202 = sub i32 %200, %201
  %203 = mul i32 %202, 62
  %204 = icmp slt i32 %203, 1
  br i1 %204, label %268, label %587

205:                                              ; preds = %436
  store ptr @.str.86, ptr %10, align 8
  store i32 162736283, ptr %6, align 4
  %206 = xor i32 %3, 257359327
  %207 = and i32 %3, %206
  %208 = or i32 %3, %206
  %209 = xor i32 %3, %206
  %210 = add i32 %207, %208
  %211 = sub i32 %210, %3
  %212 = sub i32 %211, %206
  %213 = mul i32 %212, 85
  %214 = icmp sgt i32 %213, 0
  br i1 %214, label %597, label %268

215:                                              ; preds = %476
  %216 = load ptr, ptr %10, align 8
  %217 = call ptr @__errno_location() #12
  %218 = load i32, ptr %217, align 4
  %219 = call ptr @strerror(i32 noundef %218) #9
  %220 = load ptr, ptr %8, align 8
  %221 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %220, ptr noundef @.str.85, ptr noundef %216, ptr noundef %219) #9
  call void @zero_memory(ptr noundef %16, i64 noundef 112)
  %222 = getelementptr inbounds [8192 x i8], ptr %17, i64 0, i64 0
  call void @zero_memory(ptr noundef %222, i64 noundef 8192)
  store i32 1, ptr %11, align 4
  store i32 -1435783216, ptr %6, align 4
  %223 = xor i32 %3, -1883156093
  %224 = and i32 %3, %223
  %225 = or i32 %3, %223
  %226 = xor i32 %3, %223
  %227 = mul i32 %225, 2
  %228 = sub i32 %227, %226
  %229 = sub i32 %228, %3
  %230 = sub i32 %229, %223
  %231 = mul i32 %230, 195
  %232 = icmp uge i32 %231, 0
  br i1 %232, label %268, label %607

233:                                              ; preds = %464
  %234 = load ptr, ptr %14, align 8
  call void @md5_finalize(ptr noundef %16, ptr noundef %234)
  call void @zero_memory(ptr noundef %16, i64 noundef 112)
  %235 = getelementptr inbounds [8192 x i8], ptr %17, i64 0, i64 0
  call void @zero_memory(ptr noundef %235, i64 noundef 8192)
  store i32 0, ptr %11, align 4
  store i32 -1435783216, ptr %6, align 4
  %236 = xor i32 %3, -828020931
  %237 = and i32 %3, %236
  %238 = or i32 %3, %236
  %239 = xor i32 %3, %236
  %240 = add i32 %3, %236
  %241 = sub i32 %240, %239
  %242 = mul i32 %237, 2
  %243 = sub i32 %241, %242
  %244 = mul i32 %243, 2
  %245 = icmp eq i32 %244, 0
  br i1 %245, label %268, label %617

246:                                              ; preds = %416
  store i32 1525625907, ptr %6, align 4
  %247 = xor i32 %3, -1076513637
  %248 = and i32 %3, %247
  %249 = or i32 %3, %247
  %250 = xor i32 %3, %247
  %251 = mul i32 %249, 2
  %252 = sub i32 %251, %250
  %253 = sub i32 %252, %3
  %254 = sub i32 %253, %247
  %255 = mul i32 %254, 46
  %256 = xor i32 %3, 185452557
  %257 = and i32 %3, %256
  %258 = or i32 %3, %256
  %259 = xor i32 %3, %256
  %260 = mul i32 %258, 2
  %261 = sub i32 %260, %259
  %262 = sub i32 %261, %3
  %263 = sub i32 %262, %256
  %264 = mul i32 %263, 50
  %265 = icmp ne i32 %255, %264
  br i1 %265, label %629, label %268

266:                                              ; preds = %450
  %267 = load i32, ptr %11, align 4
  ret i32 %267

268:                                              ; preds = %724, %713, %703, %693, %681, %669, %659, %650, %629, %617, %607, %597, %587, %576, %566, %557, %546, %534, %525, %516, %506, %497, %487, %478, %387, %367, %354, %342, %320, %309, %291, %279, %246, %233, %215, %205, %193, %179, %166, %143, %131, %114, %95, %82, %62, %51, %37, %24
  br label %19

269:                                              ; preds = %476, %474, %468, %464, %458, %454, %452, %448, %438, %434, %432, %428, %422, %418, %416, %412
  store i32 -600766069, ptr %6, align 4
  call void asm sideeffect "", ""()
  %270 = xor i32 %3, -1286706609
  %271 = and i32 %3, %270
  %272 = or i32 %3, %270
  %273 = xor i32 %3, %270
  %274 = add i32 %271, %272
  %275 = sub i32 %274, %3
  %276 = sub i32 %275, %270
  %277 = mul i32 %276, 120
  %278 = icmp uge i32 %277, 0
  br i1 %278, label %19, label %639

279:                                              ; preds = %458
  %280 = load i32, ptr %6, align 4
  %281 = xor i32 %280, 176219027
  store i32 %281, ptr %6, align 4
  %282 = xor i32 %3, 732060401
  %283 = and i32 %3, %282
  %284 = or i32 %3, %282
  %285 = xor i32 %3, %282
  %286 = add i32 %283, %284
  %287 = sub i32 %286, %3
  %288 = sub i32 %287, %282
  %289 = mul i32 %288, 77
  %290 = icmp eq i32 %289, 0
  br i1 %290, label %268, label %650

291:                                              ; preds = %432
  %292 = load i32, ptr %6, align 4
  %293 = xor i32 %292, 1825727258
  store i32 %293, ptr %6, align 4
  %294 = xor i32 %3, 1275804929
  %295 = and i32 %3, %294
  %296 = or i32 %3, %294
  %297 = xor i32 %3, %294
  %298 = sub i32 %296, %297
  %299 = sub i32 %298, %295
  %300 = mul i32 %299, 127
  %301 = xor i32 %3, -1368068979
  %302 = and i32 %3, %301
  %303 = or i32 %3, %301
  %304 = xor i32 %3, %301
  %305 = sub i32 %303, %304
  %306 = sub i32 %305, %302
  %307 = mul i32 %306, 149
  %308 = icmp eq i32 %300, %307
  br i1 %308, label %268, label %659

309:                                              ; preds = %430
  %310 = load i32, ptr %6, align 4
  %311 = xor i32 %310, 724424367
  store i32 %311, ptr %6, align 4
  %312 = xor i32 %3, 1192058541
  %313 = and i32 %3, %312
  %314 = or i32 %3, %312
  %315 = xor i32 %3, %312
  %316 = sub i32 %314, %315
  %317 = sub i32 %316, %313
  %318 = mul i32 %317, 128
  %319 = icmp sgt i32 %318, 0
  br i1 %319, label %669, label %268

320:                                              ; preds = %454
  %321 = load i32, ptr %6, align 4
  %322 = xor i32 %321, 1892351987
  store i32 %322, ptr %6, align 4
  %323 = xor i32 %3, -1425316487
  %324 = and i32 %3, %323
  %325 = or i32 %3, %323
  %326 = xor i32 %3, %323
  %327 = add i32 %3, %323
  %328 = sub i32 %327, %326
  %329 = mul i32 %324, 2
  %330 = sub i32 %328, %329
  %331 = mul i32 %330, 243
  %332 = xor i32 %3, -1560237417
  %333 = and i32 %3, %332
  %334 = or i32 %3, %332
  %335 = xor i32 %3, %332
  %336 = add i32 %3, %332
  %337 = sub i32 %336, %335
  %338 = mul i32 %333, 2
  %339 = sub i32 %337, %338
  %340 = mul i32 %339, 132
  %341 = icmp eq i32 %331, %340
  br i1 %341, label %268, label %681

342:                                              ; preds = %428
  %343 = load i32, ptr %6, align 4
  %344 = xor i32 %343, 1407623991
  store i32 %344, ptr %6, align 4
  %345 = xor i32 %3, 211622763
  %346 = and i32 %3, %345
  %347 = or i32 %3, %345
  %348 = xor i32 %3, %345
  %349 = add i32 %346, %347
  %350 = sub i32 %349, %3
  %351 = sub i32 %350, %345
  %352 = mul i32 %351, 120
  %353 = icmp slt i32 %352, 1
  br i1 %353, label %268, label %693

354:                                              ; preds = %414
  %355 = load i32, ptr %6, align 4
  %356 = xor i32 %355, 1001536028
  store i32 %356, ptr %6, align 4
  %357 = xor i32 %3, 448559551
  %358 = and i32 %3, %357
  %359 = or i32 %3, %357
  %360 = xor i32 %3, %357
  %361 = mul i32 %359, 2
  %362 = sub i32 %361, %360
  %363 = sub i32 %362, %3
  %364 = sub i32 %363, %357
  %365 = mul i32 %364, 221
  %366 = icmp sgt i32 %365, 0
  br i1 %366, label %703, label %268

367:                                              ; preds = %420
  %368 = load i32, ptr %6, align 4
  %369 = xor i32 %368, -82535532
  store i32 %369, ptr %6, align 4
  %370 = xor i32 %3, 1499416505
  %371 = and i32 %3, %370
  %372 = or i32 %3, %370
  %373 = xor i32 %3, %370
  %374 = sub i32 %372, %373
  %375 = sub i32 %374, %371
  %376 = mul i32 %375, 33
  %377 = xor i32 %3, -872071459
  %378 = and i32 %3, %377
  %379 = or i32 %3, %377
  %380 = xor i32 %3, %377
  %381 = add i32 %3, %377
  %382 = sub i32 %381, %380
  %383 = mul i32 %378, 2
  %384 = sub i32 %382, %383
  %385 = mul i32 %384, 222
  %386 = icmp eq i32 %376, %385
  br i1 %386, label %268, label %713

387:                                              ; preds = %470
  %388 = load i32, ptr %6, align 4
  %389 = xor i32 %388, -368046967
  store i32 %389, ptr %6, align 4
  %390 = xor i32 %3, -1932424003
  %391 = and i32 %3, %390
  %392 = or i32 %3, %390
  %393 = xor i32 %3, %390
  %394 = add i32 %3, %390
  %395 = sub i32 %394, %393
  %396 = mul i32 %391, 2
  %397 = sub i32 %395, %396
  %398 = mul i32 %397, 241
  %399 = icmp slt i32 %398, 0
  br i1 %399, label %724, label %268

400:                                              ; preds = %19
  %401 = icmp slt i32 %22, 440797762
  br i1 %401, label %404, label %406

402:                                              ; preds = %19
  %403 = icmp slt i32 %22, 1707029922
  br i1 %403, label %440, label %442

404:                                              ; preds = %400
  %405 = icmp slt i32 %22, 263597520
  br i1 %405, label %408, label %410

406:                                              ; preds = %400
  %407 = icmp slt i32 %22, 756850492
  br i1 %407, label %424, label %426

408:                                              ; preds = %404
  %409 = icmp slt i32 %22, 104408781
  br i1 %409, label %412, label %414

410:                                              ; preds = %404
  %411 = icmp slt i32 %22, 277036692
  br i1 %411, label %418, label %420

412:                                              ; preds = %408
  %413 = icmp eq i32 %22, 29511274
  br i1 %413, label %51, label %269

414:                                              ; preds = %408
  %415 = icmp eq i32 %22, 104408781
  br i1 %415, label %354, label %416

416:                                              ; preds = %414
  %417 = icmp eq i32 %22, 117142819
  br i1 %417, label %246, label %269

418:                                              ; preds = %410
  %419 = icmp eq i32 %22, 263597520
  br i1 %419, label %131, label %269

420:                                              ; preds = %410
  %421 = icmp eq i32 %22, 277036692
  br i1 %421, label %367, label %422

422:                                              ; preds = %420
  %423 = icmp eq i32 %22, 363274252
  br i1 %423, label %82, label %269

424:                                              ; preds = %406
  %425 = icmp slt i32 %22, 644479188
  br i1 %425, label %428, label %430

426:                                              ; preds = %406
  %427 = icmp slt i32 %22, 1011369180
  br i1 %427, label %434, label %436

428:                                              ; preds = %424
  %429 = icmp eq i32 %22, 440797762
  br i1 %429, label %342, label %269

430:                                              ; preds = %424
  %431 = icmp eq i32 %22, 644479188
  br i1 %431, label %309, label %432

432:                                              ; preds = %430
  %433 = icmp eq i32 %22, 651104730
  br i1 %433, label %291, label %269

434:                                              ; preds = %426
  %435 = icmp eq i32 %22, 756850492
  br i1 %435, label %114, label %269

436:                                              ; preds = %426
  %437 = icmp eq i32 %22, 1011369180
  br i1 %437, label %205, label %438

438:                                              ; preds = %436
  %439 = icmp eq i32 %22, 1080926184
  br i1 %439, label %95, label %269

440:                                              ; preds = %402
  %441 = icmp slt i32 %22, 1507617483
  br i1 %441, label %444, label %446

442:                                              ; preds = %402
  %443 = icmp slt i32 %22, 1807894518
  br i1 %443, label %460, label %462

444:                                              ; preds = %440
  %445 = icmp slt i32 %22, 1296666703
  br i1 %445, label %448, label %450

446:                                              ; preds = %440
  %447 = icmp slt i32 %22, 1551581256
  br i1 %447, label %454, label %456

448:                                              ; preds = %444
  %449 = icmp eq i32 %22, 1266775110
  br i1 %449, label %143, label %269

450:                                              ; preds = %444
  %451 = icmp eq i32 %22, 1296666703
  br i1 %451, label %266, label %452

452:                                              ; preds = %450
  %453 = icmp eq i32 %22, 1464557668
  br i1 %453, label %24, label %269

454:                                              ; preds = %446
  %455 = icmp eq i32 %22, 1507617483
  br i1 %455, label %320, label %269

456:                                              ; preds = %446
  %457 = icmp eq i32 %22, 1551581256
  br i1 %457, label %62, label %458

458:                                              ; preds = %456
  %459 = icmp eq i32 %22, 1698879693
  br i1 %459, label %279, label %269

460:                                              ; preds = %442
  %461 = icmp slt i32 %22, 1723619993
  br i1 %461, label %464, label %466

462:                                              ; preds = %442
  %463 = icmp slt i32 %22, 2019422531
  br i1 %463, label %470, label %472

464:                                              ; preds = %460
  %465 = icmp eq i32 %22, 1707029922
  br i1 %465, label %233, label %269

466:                                              ; preds = %460
  %467 = icmp eq i32 %22, 1723619993
  br i1 %467, label %37, label %468

468:                                              ; preds = %466
  %469 = icmp eq i32 %22, 1723822287
  br i1 %469, label %179, label %269

470:                                              ; preds = %462
  %471 = icmp eq i32 %22, 1807894518
  br i1 %471, label %387, label %474

472:                                              ; preds = %462
  %473 = icmp eq i32 %22, 2019422531
  br i1 %473, label %193, label %476

474:                                              ; preds = %470
  %475 = icmp eq i32 %22, 1856547087
  br i1 %475, label %166, label %269

476:                                              ; preds = %472
  %477 = icmp eq i32 %22, 2085771348
  br i1 %477, label %215, label %269

478:                                              ; preds = %24
  %479 = load i64, ptr %5, align 8
  %480 = ptrtoint ptr %0 to i64
  %481 = ptrtoint ptr %1 to i64
  %482 = ptrtoint ptr %2 to i64
  %483 = zext i32 %3 to i64
  %484 = mul i64 %479, %482
  %485 = and i64 %484, %480
  %486 = mul i64 %485, %482
  store i64 %486, ptr %5, align 8
  br label %268

487:                                              ; preds = %37
  %488 = load i64, ptr %5, align 8
  %489 = ptrtoint ptr %0 to i64
  %490 = ptrtoint ptr %1 to i64
  %491 = ptrtoint ptr %2 to i64
  %492 = zext i32 %3 to i64
  %493 = and i64 %490, %489
  %494 = mul i64 %493, %489
  %495 = sub i64 %494, %489
  %496 = mul i64 %495, %492
  store i64 %496, ptr %5, align 8
  br label %268

497:                                              ; preds = %51
  %498 = load i64, ptr %5, align 8
  %499 = ptrtoint ptr %0 to i64
  %500 = ptrtoint ptr %1 to i64
  %501 = ptrtoint ptr %2 to i64
  %502 = zext i32 %3 to i64
  %503 = mul i64 %498, %500
  %504 = mul i64 %503, %498
  %505 = mul i64 %504, %498
  store i64 %505, ptr %5, align 8
  br label %268

506:                                              ; preds = %62
  %507 = load i64, ptr %5, align 8
  %508 = ptrtoint ptr %0 to i64
  %509 = ptrtoint ptr %1 to i64
  %510 = ptrtoint ptr %2 to i64
  %511 = zext i32 %3 to i64
  %512 = add i64 %507, %508
  %513 = mul i64 %512, %508
  %514 = add i64 %513, %507
  %515 = sub i64 %514, %509
  store i64 %515, ptr %5, align 8
  br label %268

516:                                              ; preds = %82
  %517 = load i64, ptr %5, align 8
  %518 = ptrtoint ptr %0 to i64
  %519 = ptrtoint ptr %1 to i64
  %520 = ptrtoint ptr %2 to i64
  %521 = zext i32 %3 to i64
  %522 = sub i64 %519, %520
  %523 = xor i64 %522, %521
  %524 = add i64 %523, %519
  store i64 %524, ptr %5, align 8
  br label %268

525:                                              ; preds = %95
  %526 = load i64, ptr %5, align 8
  %527 = ptrtoint ptr %0 to i64
  %528 = ptrtoint ptr %1 to i64
  %529 = ptrtoint ptr %2 to i64
  %530 = zext i32 %3 to i64
  %531 = add i64 %529, %529
  %532 = mul i64 %531, %526
  %533 = add i64 %532, %528
  store i64 %533, ptr %5, align 8
  br label %268

534:                                              ; preds = %114
  %535 = load i64, ptr %5, align 8
  %536 = ptrtoint ptr %0 to i64
  %537 = ptrtoint ptr %1 to i64
  %538 = ptrtoint ptr %2 to i64
  %539 = zext i32 %3 to i64
  %540 = sub i64 %536, %536
  %541 = xor i64 %540, %535
  %542 = sub i64 %541, %538
  %543 = add i64 %542, %535
  %544 = and i64 %543, %538
  %545 = xor i64 %544, %536
  store i64 %545, ptr %5, align 8
  br label %268

546:                                              ; preds = %131
  %547 = load i64, ptr %5, align 8
  %548 = ptrtoint ptr %0 to i64
  %549 = ptrtoint ptr %1 to i64
  %550 = ptrtoint ptr %2 to i64
  %551 = zext i32 %3 to i64
  %552 = sub i64 %549, %551
  %553 = sub i64 %552, %548
  %554 = or i64 %553, %547
  %555 = sub i64 %554, %548
  %556 = or i64 %555, %547
  store i64 %556, ptr %5, align 8
  br label %268

557:                                              ; preds = %143
  %558 = load i64, ptr %5, align 8
  %559 = ptrtoint ptr %0 to i64
  %560 = ptrtoint ptr %1 to i64
  %561 = ptrtoint ptr %2 to i64
  %562 = zext i32 %3 to i64
  %563 = and i64 %561, %560
  %564 = and i64 %563, %562
  %565 = mul i64 %564, %562
  store i64 %565, ptr %5, align 8
  br label %268

566:                                              ; preds = %166
  %567 = load i64, ptr %5, align 8
  %568 = ptrtoint ptr %0 to i64
  %569 = ptrtoint ptr %1 to i64
  %570 = ptrtoint ptr %2 to i64
  %571 = zext i32 %3 to i64
  %572 = sub i64 %571, %568
  %573 = mul i64 %572, %571
  %574 = add i64 %573, %570
  %575 = add i64 %574, %568
  store i64 %575, ptr %5, align 8
  br label %268

576:                                              ; preds = %179
  %577 = load i64, ptr %5, align 8
  %578 = ptrtoint ptr %0 to i64
  %579 = ptrtoint ptr %1 to i64
  %580 = ptrtoint ptr %2 to i64
  %581 = zext i32 %3 to i64
  %582 = sub i64 %578, %578
  %583 = sub i64 %582, %579
  %584 = mul i64 %583, %581
  %585 = mul i64 %584, %578
  %586 = or i64 %585, %577
  store i64 %586, ptr %5, align 8
  br label %268

587:                                              ; preds = %193
  %588 = load i64, ptr %5, align 8
  %589 = ptrtoint ptr %0 to i64
  %590 = ptrtoint ptr %1 to i64
  %591 = ptrtoint ptr %2 to i64
  %592 = zext i32 %3 to i64
  %593 = or i64 %592, %589
  %594 = add i64 %593, %591
  %595 = xor i64 %594, %591
  %596 = and i64 %595, %588
  store i64 %596, ptr %5, align 8
  br label %268

597:                                              ; preds = %205
  %598 = load i64, ptr %5, align 8
  %599 = ptrtoint ptr %0 to i64
  %600 = ptrtoint ptr %1 to i64
  %601 = ptrtoint ptr %2 to i64
  %602 = zext i32 %3 to i64
  %603 = xor i64 %600, %598
  %604 = sub i64 %603, %598
  %605 = xor i64 %604, %601
  %606 = xor i64 %605, %599
  store i64 %606, ptr %5, align 8
  br label %268

607:                                              ; preds = %215
  %608 = load i64, ptr %5, align 8
  %609 = ptrtoint ptr %0 to i64
  %610 = ptrtoint ptr %1 to i64
  %611 = ptrtoint ptr %2 to i64
  %612 = zext i32 %3 to i64
  %613 = mul i64 %609, %610
  %614 = sub i64 %613, %611
  %615 = sub i64 %614, %608
  %616 = add i64 %615, %609
  store i64 %616, ptr %5, align 8
  br label %268

617:                                              ; preds = %233
  %618 = load i64, ptr %5, align 8
  %619 = ptrtoint ptr %0 to i64
  %620 = ptrtoint ptr %1 to i64
  %621 = ptrtoint ptr %2 to i64
  %622 = zext i32 %3 to i64
  %623 = xor i64 %621, %618
  %624 = mul i64 %623, %622
  %625 = xor i64 %624, %619
  %626 = or i64 %625, %621
  %627 = or i64 %626, %619
  %628 = add i64 %627, %619
  store i64 %628, ptr %5, align 8
  br label %268

629:                                              ; preds = %246
  %630 = load i64, ptr %5, align 8
  %631 = ptrtoint ptr %0 to i64
  %632 = ptrtoint ptr %1 to i64
  %633 = ptrtoint ptr %2 to i64
  %634 = zext i32 %3 to i64
  %635 = sub i64 %633, %632
  %636 = add i64 %635, %633
  %637 = or i64 %636, %631
  %638 = sub i64 %637, %634
  store i64 %638, ptr %5, align 8
  br label %268

639:                                              ; preds = %269
  %640 = load i64, ptr %5, align 8
  %641 = ptrtoint ptr %0 to i64
  %642 = ptrtoint ptr %1 to i64
  %643 = ptrtoint ptr %2 to i64
  %644 = zext i32 %3 to i64
  %645 = mul i64 %644, %641
  %646 = xor i64 %645, %640
  %647 = xor i64 %646, %641
  %648 = and i64 %647, %643
  %649 = and i64 %648, %640
  store i64 %649, ptr %5, align 8
  br label %19

650:                                              ; preds = %279
  %651 = load i64, ptr %5, align 8
  %652 = ptrtoint ptr %0 to i64
  %653 = ptrtoint ptr %1 to i64
  %654 = ptrtoint ptr %2 to i64
  %655 = zext i32 %3 to i64
  %656 = mul i64 %654, %652
  %657 = add i64 %656, %652
  %658 = and i64 %657, %655
  store i64 %658, ptr %5, align 8
  br label %268

659:                                              ; preds = %291
  %660 = load i64, ptr %5, align 8
  %661 = ptrtoint ptr %0 to i64
  %662 = ptrtoint ptr %1 to i64
  %663 = ptrtoint ptr %2 to i64
  %664 = zext i32 %3 to i64
  %665 = and i64 %663, %661
  %666 = or i64 %665, %662
  %667 = mul i64 %666, %663
  %668 = xor i64 %667, %660
  store i64 %668, ptr %5, align 8
  br label %268

669:                                              ; preds = %309
  %670 = load i64, ptr %5, align 8
  %671 = ptrtoint ptr %0 to i64
  %672 = ptrtoint ptr %1 to i64
  %673 = ptrtoint ptr %2 to i64
  %674 = zext i32 %3 to i64
  %675 = mul i64 %672, %670
  %676 = add i64 %675, %670
  %677 = add i64 %676, %674
  %678 = and i64 %677, %673
  %679 = or i64 %678, %671
  %680 = sub i64 %679, %671
  store i64 %680, ptr %5, align 8
  br label %268

681:                                              ; preds = %320
  %682 = load i64, ptr %5, align 8
  %683 = ptrtoint ptr %0 to i64
  %684 = ptrtoint ptr %1 to i64
  %685 = ptrtoint ptr %2 to i64
  %686 = zext i32 %3 to i64
  %687 = sub i64 %686, %682
  %688 = sub i64 %687, %682
  %689 = or i64 %688, %683
  %690 = mul i64 %689, %684
  %691 = add i64 %690, %682
  %692 = add i64 %691, %685
  store i64 %692, ptr %5, align 8
  br label %268

693:                                              ; preds = %342
  %694 = load i64, ptr %5, align 8
  %695 = ptrtoint ptr %0 to i64
  %696 = ptrtoint ptr %1 to i64
  %697 = ptrtoint ptr %2 to i64
  %698 = zext i32 %3 to i64
  %699 = xor i64 %695, %698
  %700 = xor i64 %699, %696
  %701 = add i64 %700, %696
  %702 = add i64 %701, %697
  store i64 %702, ptr %5, align 8
  br label %268

703:                                              ; preds = %354
  %704 = load i64, ptr %5, align 8
  %705 = ptrtoint ptr %0 to i64
  %706 = ptrtoint ptr %1 to i64
  %707 = ptrtoint ptr %2 to i64
  %708 = zext i32 %3 to i64
  %709 = mul i64 %707, %704
  %710 = and i64 %709, %708
  %711 = sub i64 %710, %708
  %712 = add i64 %711, %704
  store i64 %712, ptr %5, align 8
  br label %268

713:                                              ; preds = %367
  %714 = load i64, ptr %5, align 8
  %715 = ptrtoint ptr %0 to i64
  %716 = ptrtoint ptr %1 to i64
  %717 = ptrtoint ptr %2 to i64
  %718 = zext i32 %3 to i64
  %719 = add i64 %714, %716
  %720 = or i64 %719, %717
  %721 = xor i64 %720, %718
  %722 = or i64 %721, %715
  %723 = mul i64 %722, %716
  store i64 %723, ptr %5, align 8
  br label %268

724:                                              ; preds = %387
  %725 = load i64, ptr %5, align 8
  %726 = ptrtoint ptr %0 to i64
  %727 = ptrtoint ptr %1 to i64
  %728 = ptrtoint ptr %2 to i64
  %729 = zext i32 %3 to i64
  %730 = add i64 %725, %728
  %731 = sub i64 %730, %729
  %732 = mul i64 %731, %725
  %733 = sub i64 %732, %728
  %734 = add i64 %733, %727
  %735 = xor i64 %734, %726
  store i64 %735, ptr %5, align 8
  br label %268
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
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  store i32 529265105, ptr %5, align 4
  br label %12

12:                                               ; preds = %379, %136, %135, %3
  %13 = load i32, ptr %5, align 4
  %14 = sub i32 %13, 38889530
  %15 = mul i32 %14, 1853932473
  %16 = icmp slt i32 %15, 942448328
  br i1 %16, label %255, label %257

17:                                               ; preds = %297
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  store i32 %2, ptr %9, align 4
  %18 = load ptr, ptr %7, align 8
  %19 = icmp eq ptr %18, null
  %20 = select i1 %19, i32 1099055679, i32 -1180551976
  store i32 %20, ptr %5, align 4
  %21 = xor i32 %2, 1345387777
  %22 = and i32 %2, %21
  %23 = or i32 %2, %21
  %24 = xor i32 %2, %21
  %25 = sub i32 %23, %24
  %26 = sub i32 %25, %22
  %27 = mul i32 %26, 244
  %28 = icmp sgt i32 %27, 0
  br i1 %28, label %303, label %135

29:                                               ; preds = %287
  %30 = load ptr, ptr %7, align 8
  %31 = getelementptr inbounds i8, ptr %30, i64 0
  %32 = load i8, ptr %31, align 1
  %33 = sext i8 %32 to i32
  %34 = icmp eq i32 %33, 0
  %35 = select i1 %34, i32 1099055679, i32 -2125638636
  store i32 %35, ptr %5, align 4
  %36 = xor i32 %2, -831969143
  %37 = and i32 %2, %36
  %38 = or i32 %2, %36
  %39 = xor i32 %2, %36
  %40 = add i32 %37, %38
  %41 = sub i32 %40, %2
  %42 = sub i32 %41, %36
  %43 = mul i32 %42, 225
  %44 = icmp slt i32 %43, 1
  br i1 %44, label %135, label %314

45:                                               ; preds = %267
  %46 = load ptr, ptr @stderr, align 8
  %47 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %46, ptr noundef @.str.87) #9
  store i32 1, ptr %6, align 4
  store i32 1731114746, ptr %5, align 4
  %48 = xor i32 %2, 909868785
  %49 = and i32 %2, %48
  %50 = or i32 %2, %48
  %51 = xor i32 %2, %48
  %52 = add i32 %49, %50
  %53 = sub i32 %52, %2
  %54 = sub i32 %53, %48
  %55 = mul i32 %54, 57
  %56 = icmp eq i32 %55, 0
  br i1 %56, label %135, label %324

57:                                               ; preds = %289
  %58 = load ptr, ptr %7, align 8
  %59 = call noalias ptr @fopen(ptr noundef %58, ptr noundef @.str.88)
  store ptr %59, ptr %10, align 8
  %60 = load ptr, ptr %10, align 8
  %61 = icmp eq ptr %60, null
  %62 = select i1 %61, i32 -235821959, i32 -416198368
  store i32 %62, ptr %5, align 4
  %63 = xor i32 %2, -1265618447
  %64 = and i32 %2, %63
  %65 = or i32 %2, %63
  %66 = xor i32 %2, %63
  %67 = add i32 %64, %65
  %68 = sub i32 %67, %2
  %69 = sub i32 %68, %63
  %70 = mul i32 %69, 147
  %71 = icmp slt i32 %70, 0
  br i1 %71, label %334, label %135

72:                                               ; preds = %301
  %73 = load ptr, ptr @stderr, align 8
  %74 = load ptr, ptr %7, align 8
  %75 = call ptr @__errno_location() #12
  %76 = load i32, ptr %75, align 4
  %77 = call ptr @strerror(i32 noundef %76) #9
  %78 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %73, ptr noundef @.str.89, ptr noundef %74, ptr noundef %77) #9
  store i32 1, ptr %6, align 4
  store i32 1731114746, ptr %5, align 4
  %79 = xor i32 %2, 644586461
  %80 = and i32 %2, %79
  %81 = or i32 %2, %79
  %82 = xor i32 %2, %79
  %83 = sub i32 %81, %82
  %84 = sub i32 %83, %80
  %85 = mul i32 %84, 178
  %86 = icmp eq i32 %85, 0
  br i1 %86, label %135, label %342

87:                                               ; preds = %285
  %88 = load ptr, ptr %10, align 8
  %89 = load ptr, ptr %7, align 8
  %90 = load ptr, ptr %8, align 8
  %91 = load i32, ptr %9, align 4
  %92 = call i32 @hash_stream(ptr noundef %88, ptr noundef %89, ptr noundef %90, i32 noundef %91)
  store i32 %92, ptr %11, align 4
  %93 = load ptr, ptr %10, align 8
  %94 = call i32 @fclose(ptr noundef %93)
  %95 = icmp ne i32 %94, 0
  %96 = select i1 %95, i32 1851553585, i32 1953037476
  store i32 %96, ptr %5, align 4
  %97 = xor i32 %2, -938121005
  %98 = and i32 %2, %97
  %99 = or i32 %2, %97
  %100 = xor i32 %2, %97
  %101 = sub i32 %99, %100
  %102 = sub i32 %101, %98
  %103 = mul i32 %102, 201
  %104 = icmp sle i32 %103, 0
  br i1 %104, label %135, label %351

105:                                              ; preds = %271
  %106 = load ptr, ptr @stderr, align 8
  %107 = load ptr, ptr %7, align 8
  %108 = call ptr @__errno_location() #12
  %109 = load i32, ptr %108, align 4
  %110 = call ptr @strerror(i32 noundef %109) #9
  %111 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %106, ptr noundef @.str.90, ptr noundef %107, ptr noundef %110) #9
  store i32 1, ptr %6, align 4
  store i32 1731114746, ptr %5, align 4
  %112 = xor i32 %2, 1361883253
  %113 = and i32 %2, %112
  %114 = or i32 %2, %112
  %115 = xor i32 %2, %112
  %116 = mul i32 %114, 2
  %117 = sub i32 %116, %115
  %118 = sub i32 %117, %2
  %119 = sub i32 %118, %112
  %120 = mul i32 %119, 154
  %121 = icmp slt i32 %120, 1
  br i1 %121, label %135, label %360

122:                                              ; preds = %277
  %123 = load i32, ptr %11, align 4
  store i32 %123, ptr %6, align 4
  store i32 1731114746, ptr %5, align 4
  %124 = xor i32 %2, 1660352093
  %125 = and i32 %2, %124
  %126 = or i32 %2, %124
  %127 = xor i32 %2, %124
  %128 = add i32 %125, %126
  %129 = sub i32 %128, %2
  %130 = sub i32 %129, %124
  %131 = mul i32 %130, 120
  %132 = icmp uge i32 %131, 0
  br i1 %132, label %135, label %368

133:                                              ; preds = %295
  %134 = load i32, ptr %6, align 4
  ret i32 %134

135:                                              ; preds = %455, %445, %434, %426, %418, %408, %399, %389, %368, %360, %351, %342, %334, %324, %314, %303, %242, %229, %216, %203, %192, %170, %158, %145, %122, %105, %87, %72, %57, %45, %29, %17
  br label %12

136:                                              ; preds = %301, %297, %295, %289, %287, %277, %275, %269, %267
  store i32 529265105, ptr %5, align 4
  call void asm sideeffect "", ""()
  %137 = xor i32 %2, -1023686993
  %138 = and i32 %2, %137
  %139 = or i32 %2, %137
  %140 = xor i32 %2, %137
  %141 = sub i32 %139, %140
  %142 = sub i32 %141, %138
  %143 = mul i32 %142, 14
  %144 = icmp slt i32 %143, 1
  br i1 %144, label %12, label %379

145:                                              ; preds = %273
  %146 = load i32, ptr %5, align 4
  %147 = xor i32 %146, 1321499117
  store i32 %147, ptr %5, align 4
  %148 = xor i32 %2, -2060195305
  %149 = and i32 %2, %148
  %150 = or i32 %2, %148
  %151 = xor i32 %2, %148
  %152 = mul i32 %150, 2
  %153 = sub i32 %152, %151
  %154 = sub i32 %153, %2
  %155 = sub i32 %154, %148
  %156 = mul i32 %155, 35
  %157 = icmp sgt i32 %156, 0
  br i1 %157, label %389, label %135

158:                                              ; preds = %263
  %159 = load i32, ptr %5, align 4
  %160 = xor i32 %159, 1619060747
  store i32 %160, ptr %5, align 4
  %161 = xor i32 %2, 1287372817
  %162 = and i32 %2, %161
  %163 = or i32 %2, %161
  %164 = xor i32 %2, %161
  %165 = add i32 %162, %163
  %166 = sub i32 %165, %2
  %167 = sub i32 %166, %161
  %168 = mul i32 %167, 178
  %169 = icmp sle i32 %168, 0
  br i1 %169, label %135, label %399

170:                                              ; preds = %269
  %171 = load i32, ptr %5, align 4
  %172 = xor i32 %171, -1636128980
  store i32 %172, ptr %5, align 4
  %173 = xor i32 %2, 642594445
  %174 = and i32 %2, %173
  %175 = or i32 %2, %173
  %176 = xor i32 %2, %173
  %177 = mul i32 %175, 2
  %178 = sub i32 %177, %176
  %179 = sub i32 %178, %2
  %180 = sub i32 %179, %173
  %181 = mul i32 %180, 6
  %182 = xor i32 %2, -546711483
  %183 = and i32 %2, %182
  %184 = or i32 %2, %182
  %185 = xor i32 %2, %182
  %186 = add i32 %2, %182
  %187 = sub i32 %186, %185
  %188 = mul i32 %183, 2
  %189 = sub i32 %187, %188
  %190 = mul i32 %189, 56
  %191 = icmp eq i32 %181, %190
  br i1 %191, label %135, label %408

192:                                              ; preds = %299
  %193 = load i32, ptr %5, align 4
  %194 = xor i32 %193, -1686837050
  store i32 %194, ptr %5, align 4
  %195 = xor i32 %2, -1343093361
  %196 = and i32 %2, %195
  %197 = or i32 %2, %195
  %198 = xor i32 %2, %195
  %199 = sub i32 %197, %198
  %200 = sub i32 %199, %196
  %201 = mul i32 %200, 92
  %202 = icmp ne i32 %201, 0
  br i1 %202, label %418, label %135

203:                                              ; preds = %283
  %204 = load i32, ptr %5, align 4
  %205 = xor i32 %204, -63765489
  store i32 %205, ptr %5, align 4
  %206 = xor i32 %2, -377697681
  %207 = and i32 %2, %206
  %208 = or i32 %2, %206
  %209 = xor i32 %2, %206
  %210 = add i32 %2, %206
  %211 = sub i32 %210, %209
  %212 = mul i32 %207, 2
  %213 = sub i32 %211, %212
  %214 = mul i32 %213, 224
  %215 = icmp ne i32 %214, 0
  br i1 %215, label %426, label %135

216:                                              ; preds = %265
  %217 = load i32, ptr %5, align 4
  %218 = xor i32 %217, -1562196341
  store i32 %218, ptr %5, align 4
  %219 = xor i32 %2, 606404651
  %220 = and i32 %2, %219
  %221 = or i32 %2, %219
  %222 = xor i32 %2, %219
  %223 = mul i32 %221, 2
  %224 = sub i32 %223, %222
  %225 = sub i32 %224, %2
  %226 = sub i32 %225, %219
  %227 = mul i32 %226, 14
  %228 = icmp sle i32 %227, 0
  br i1 %228, label %135, label %434

229:                                              ; preds = %275
  %230 = load i32, ptr %5, align 4
  %231 = xor i32 %230, 598149791
  store i32 %231, ptr %5, align 4
  %232 = xor i32 %2, -1296233055
  %233 = and i32 %2, %232
  %234 = or i32 %2, %232
  %235 = xor i32 %2, %232
  %236 = mul i32 %234, 2
  %237 = sub i32 %236, %235
  %238 = sub i32 %237, %2
  %239 = sub i32 %238, %232
  %240 = mul i32 %239, 245
  %241 = icmp eq i32 %240, 0
  br i1 %241, label %135, label %445

242:                                              ; preds = %291
  %243 = load i32, ptr %5, align 4
  %244 = xor i32 %243, -1610509940
  store i32 %244, ptr %5, align 4
  %245 = xor i32 %2, -1377393089
  %246 = and i32 %2, %245
  %247 = or i32 %2, %245
  %248 = xor i32 %2, %245
  %249 = mul i32 %247, 2
  %250 = sub i32 %249, %248
  %251 = sub i32 %250, %2
  %252 = sub i32 %251, %245
  %253 = mul i32 %252, 40
  %254 = icmp ugt i32 %253, 0
  br i1 %254, label %455, label %135

255:                                              ; preds = %12
  %256 = icmp slt i32 %15, 501478783
  br i1 %256, label %259, label %261

257:                                              ; preds = %12
  %258 = icmp slt i32 %15, 1334020805
  br i1 %258, label %279, label %281

259:                                              ; preds = %255
  %260 = icmp slt i32 %15, 250274737
  br i1 %260, label %263, label %265

261:                                              ; preds = %255
  %262 = icmp slt i32 %15, 667229131
  br i1 %262, label %271, label %273

263:                                              ; preds = %259
  %264 = icmp eq i32 %15, 128501891
  br i1 %264, label %158, label %267

265:                                              ; preds = %259
  %266 = icmp eq i32 %15, 250274737
  br i1 %266, label %216, label %269

267:                                              ; preds = %263
  %268 = icmp eq i32 %15, 148855965
  br i1 %268, label %45, label %136

269:                                              ; preds = %265
  %270 = icmp eq i32 %15, 411960812
  br i1 %270, label %170, label %136

271:                                              ; preds = %261
  %272 = icmp eq i32 %15, 501478783
  br i1 %272, label %105, label %275

273:                                              ; preds = %261
  %274 = icmp eq i32 %15, 667229131
  br i1 %274, label %145, label %277

275:                                              ; preds = %271
  %276 = icmp eq i32 %15, 537930390
  br i1 %276, label %229, label %136

277:                                              ; preds = %273
  %278 = icmp eq i32 %15, 706150042
  br i1 %278, label %122, label %136

279:                                              ; preds = %257
  %280 = icmp slt i32 %15, 993427510
  br i1 %280, label %283, label %285

281:                                              ; preds = %257
  %282 = icmp slt i32 %15, 1671131935
  br i1 %282, label %291, label %293

283:                                              ; preds = %279
  %284 = icmp eq i32 %15, 942448328
  br i1 %284, label %203, label %287

285:                                              ; preds = %279
  %286 = icmp eq i32 %15, 993427510
  br i1 %286, label %87, label %289

287:                                              ; preds = %283
  %288 = icmp eq i32 %15, 943732782
  br i1 %288, label %29, label %136

289:                                              ; preds = %285
  %290 = icmp eq i32 %15, 1102347914
  br i1 %290, label %57, label %136

291:                                              ; preds = %281
  %292 = icmp eq i32 %15, 1334020805
  br i1 %292, label %242, label %295

293:                                              ; preds = %281
  %294 = icmp slt i32 %15, 1745961983
  br i1 %294, label %297, label %299

295:                                              ; preds = %291
  %296 = icmp eq i32 %15, 1458186432
  br i1 %296, label %133, label %136

297:                                              ; preds = %293
  %298 = icmp eq i32 %15, 1671131935
  br i1 %298, label %17, label %136

299:                                              ; preds = %293
  %300 = icmp eq i32 %15, 1745961983
  br i1 %300, label %192, label %301

301:                                              ; preds = %299
  %302 = icmp eq i32 %15, 1781499527
  br i1 %302, label %72, label %136

303:                                              ; preds = %17
  %304 = load i64, ptr %4, align 8
  %305 = ptrtoint ptr %0 to i64
  %306 = ptrtoint ptr %1 to i64
  %307 = zext i32 %2 to i64
  %308 = sub i64 %307, %306
  %309 = mul i64 %308, %307
  %310 = mul i64 %309, %307
  %311 = and i64 %310, %304
  %312 = or i64 %311, %304
  %313 = mul i64 %312, %307
  store i64 %313, ptr %4, align 8
  br label %135

314:                                              ; preds = %29
  %315 = load i64, ptr %4, align 8
  %316 = ptrtoint ptr %0 to i64
  %317 = ptrtoint ptr %1 to i64
  %318 = zext i32 %2 to i64
  %319 = or i64 %318, %316
  %320 = and i64 %319, %318
  %321 = add i64 %320, %318
  %322 = sub i64 %321, %317
  %323 = sub i64 %322, %318
  store i64 %323, ptr %4, align 8
  br label %135

324:                                              ; preds = %45
  %325 = load i64, ptr %4, align 8
  %326 = ptrtoint ptr %0 to i64
  %327 = ptrtoint ptr %1 to i64
  %328 = zext i32 %2 to i64
  %329 = xor i64 %327, %326
  %330 = and i64 %329, %326
  %331 = and i64 %330, %326
  %332 = sub i64 %331, %328
  %333 = or i64 %332, %326
  store i64 %333, ptr %4, align 8
  br label %135

334:                                              ; preds = %57
  %335 = load i64, ptr %4, align 8
  %336 = ptrtoint ptr %0 to i64
  %337 = ptrtoint ptr %1 to i64
  %338 = zext i32 %2 to i64
  %339 = sub i64 %336, %336
  %340 = or i64 %339, %336
  %341 = or i64 %340, %338
  store i64 %341, ptr %4, align 8
  br label %135

342:                                              ; preds = %72
  %343 = load i64, ptr %4, align 8
  %344 = ptrtoint ptr %0 to i64
  %345 = ptrtoint ptr %1 to i64
  %346 = zext i32 %2 to i64
  %347 = and i64 %343, %346
  %348 = sub i64 %347, %344
  %349 = xor i64 %348, %344
  %350 = and i64 %349, %346
  store i64 %350, ptr %4, align 8
  br label %135

351:                                              ; preds = %87
  %352 = load i64, ptr %4, align 8
  %353 = ptrtoint ptr %0 to i64
  %354 = ptrtoint ptr %1 to i64
  %355 = zext i32 %2 to i64
  %356 = add i64 %353, %352
  %357 = and i64 %356, %354
  %358 = add i64 %357, %352
  %359 = sub i64 %358, %353
  store i64 %359, ptr %4, align 8
  br label %135

360:                                              ; preds = %105
  %361 = load i64, ptr %4, align 8
  %362 = ptrtoint ptr %0 to i64
  %363 = ptrtoint ptr %1 to i64
  %364 = zext i32 %2 to i64
  %365 = sub i64 %361, %361
  %366 = xor i64 %365, %362
  %367 = and i64 %366, %362
  store i64 %367, ptr %4, align 8
  br label %135

368:                                              ; preds = %122
  %369 = load i64, ptr %4, align 8
  %370 = ptrtoint ptr %0 to i64
  %371 = ptrtoint ptr %1 to i64
  %372 = zext i32 %2 to i64
  %373 = or i64 %370, %369
  %374 = or i64 %373, %372
  %375 = add i64 %374, %372
  %376 = mul i64 %375, %369
  %377 = add i64 %376, %371
  %378 = xor i64 %377, %369
  store i64 %378, ptr %4, align 8
  br label %135

379:                                              ; preds = %136
  %380 = load i64, ptr %4, align 8
  %381 = ptrtoint ptr %0 to i64
  %382 = ptrtoint ptr %1 to i64
  %383 = zext i32 %2 to i64
  %384 = xor i64 %382, %382
  %385 = sub i64 %384, %383
  %386 = or i64 %385, %382
  %387 = or i64 %386, %380
  %388 = sub i64 %387, %380
  store i64 %388, ptr %4, align 8
  br label %12

389:                                              ; preds = %145
  %390 = load i64, ptr %4, align 8
  %391 = ptrtoint ptr %0 to i64
  %392 = ptrtoint ptr %1 to i64
  %393 = zext i32 %2 to i64
  %394 = mul i64 %392, %391
  %395 = or i64 %394, %391
  %396 = mul i64 %395, %391
  %397 = mul i64 %396, %392
  %398 = mul i64 %397, %391
  store i64 %398, ptr %4, align 8
  br label %135

399:                                              ; preds = %158
  %400 = load i64, ptr %4, align 8
  %401 = ptrtoint ptr %0 to i64
  %402 = ptrtoint ptr %1 to i64
  %403 = zext i32 %2 to i64
  %404 = sub i64 %401, %402
  %405 = and i64 %404, %403
  %406 = xor i64 %405, %403
  %407 = xor i64 %406, %402
  store i64 %407, ptr %4, align 8
  br label %135

408:                                              ; preds = %170
  %409 = load i64, ptr %4, align 8
  %410 = ptrtoint ptr %0 to i64
  %411 = ptrtoint ptr %1 to i64
  %412 = zext i32 %2 to i64
  %413 = and i64 %412, %410
  %414 = sub i64 %413, %411
  %415 = xor i64 %414, %410
  %416 = mul i64 %415, %410
  %417 = xor i64 %416, %411
  store i64 %417, ptr %4, align 8
  br label %135

418:                                              ; preds = %192
  %419 = load i64, ptr %4, align 8
  %420 = ptrtoint ptr %0 to i64
  %421 = ptrtoint ptr %1 to i64
  %422 = zext i32 %2 to i64
  %423 = add i64 %419, %419
  %424 = or i64 %423, %421
  %425 = and i64 %424, %420
  store i64 %425, ptr %4, align 8
  br label %135

426:                                              ; preds = %203
  %427 = load i64, ptr %4, align 8
  %428 = ptrtoint ptr %0 to i64
  %429 = ptrtoint ptr %1 to i64
  %430 = zext i32 %2 to i64
  %431 = and i64 %430, %430
  %432 = or i64 %431, %430
  %433 = xor i64 %432, %430
  store i64 %433, ptr %4, align 8
  br label %135

434:                                              ; preds = %216
  %435 = load i64, ptr %4, align 8
  %436 = ptrtoint ptr %0 to i64
  %437 = ptrtoint ptr %1 to i64
  %438 = zext i32 %2 to i64
  %439 = add i64 %437, %435
  %440 = xor i64 %439, %438
  %441 = add i64 %440, %438
  %442 = xor i64 %441, %435
  %443 = mul i64 %442, %437
  %444 = mul i64 %443, %436
  store i64 %444, ptr %4, align 8
  br label %135

445:                                              ; preds = %229
  %446 = load i64, ptr %4, align 8
  %447 = ptrtoint ptr %0 to i64
  %448 = ptrtoint ptr %1 to i64
  %449 = zext i32 %2 to i64
  %450 = sub i64 %448, %446
  %451 = mul i64 %450, %446
  %452 = mul i64 %451, %446
  %453 = and i64 %452, %449
  %454 = or i64 %453, %446
  store i64 %454, ptr %4, align 8
  br label %135

455:                                              ; preds = %242
  %456 = load i64, ptr %4, align 8
  %457 = ptrtoint ptr %0 to i64
  %458 = ptrtoint ptr %1 to i64
  %459 = zext i32 %2 to i64
  %460 = add i64 %456, %458
  %461 = and i64 %460, %457
  %462 = add i64 %461, %458
  %463 = add i64 %462, %457
  %464 = or i64 %463, %456
  %465 = add i64 %464, %458
  store i64 %465, ptr %4, align 8
  br label %135
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @print_digest(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = ptrtoint ptr %0 to i32
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca [33 x i8], align 16
  store i32 -1132968595, ptr %6, align 4
  br label %14

14:                                               ; preds = %448, %158, %157, %3
  %15 = load i32, ptr %6, align 4
  %16 = sub i32 %15, 1146948681
  %17 = mul i32 %16, 467562577
  %18 = icmp slt i32 %17, 1192401047
  br i1 %18, label %292, label %294

19:                                               ; preds = %318
  store ptr %0, ptr %10, align 8
  store ptr %1, ptr %11, align 8
  store ptr %2, ptr %12, align 8
  %20 = load ptr, ptr %12, align 8
  %21 = icmp ne ptr %20, null
  %22 = select i1 %21, i32 1570357897, i32 61829000
  store i32 %22, ptr %6, align 4
  %23 = xor i32 %5, 412099271
  %24 = and i32 %5, %23
  %25 = or i32 %5, %23
  %26 = xor i32 %5, %23
  %27 = add i32 %24, %25
  %28 = sub i32 %27, %5
  %29 = sub i32 %28, %23
  %30 = mul i32 %29, 183
  %31 = icmp ne i32 %30, 0
  br i1 %31, label %348, label %157

32:                                               ; preds = %334
  %33 = load ptr, ptr %12, align 8
  %34 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %33, i32 0, i32 1
  %35 = load i32, ptr %34, align 4
  %36 = icmp ne i32 %35, 0
  %37 = select i1 %36, i32 -172169220, i32 61829000
  store i32 %37, ptr %6, align 4
  %38 = xor i32 %5, 520072569
  %39 = and i32 %5, %38
  %40 = or i32 %5, %38
  %41 = xor i32 %5, %38
  %42 = add i32 %5, %38
  %43 = sub i32 %42, %41
  %44 = mul i32 %39, 2
  %45 = sub i32 %43, %44
  %46 = mul i32 %45, 147
  %47 = icmp slt i32 %46, 1
  br i1 %47, label %157, label %358

48:                                               ; preds = %344
  %49 = load ptr, ptr %10, align 8
  %50 = load ptr, ptr @stdout, align 8
  %51 = call i64 @fwrite(ptr noundef %49, i64 noundef 1, i64 noundef 16, ptr noundef %50)
  store i32 105418020, ptr %6, align 4
  %52 = xor i32 %5, 1508241267
  %53 = and i32 %5, %52
  %54 = or i32 %5, %52
  %55 = xor i32 %5, %52
  %56 = mul i32 %54, 2
  %57 = sub i32 %56, %55
  %58 = sub i32 %57, %5
  %59 = sub i32 %58, %52
  %60 = mul i32 %59, 44
  %61 = icmp ugt i32 %60, 0
  br i1 %61, label %369, label %157

62:                                               ; preds = %328
  %63 = load ptr, ptr %10, align 8
  store ptr %63, ptr %7, align 8
  %64 = getelementptr inbounds [33 x i8], ptr %13, i64 0, i64 0
  store ptr %64, ptr %8, align 8
  %65 = load ptr, ptr %12, align 8
  %66 = icmp ne ptr %65, null
  %67 = select i1 %66, i32 -1329875288, i32 358390338
  store i32 %67, ptr %6, align 4
  %68 = xor i32 %5, -808352609
  %69 = and i32 %5, %68
  %70 = or i32 %5, %68
  %71 = xor i32 %5, %68
  %72 = mul i32 %70, 2
  %73 = sub i32 %72, %71
  %74 = sub i32 %73, %5
  %75 = sub i32 %74, %68
  %76 = mul i32 %75, 207
  %77 = icmp sle i32 %76, 0
  br i1 %77, label %157, label %378

78:                                               ; preds = %346
  %79 = load ptr, ptr %12, align 8
  %80 = getelementptr inbounds nuw %struct.DigestFormatter, ptr %79, i32 0, i32 0
  %81 = load i32, ptr %80, align 4
  store i32 %81, ptr %9, align 4
  store i32 -1347540062, ptr %6, align 4
  %82 = xor i32 %5, -1454934541
  %83 = and i32 %5, %82
  %84 = or i32 %5, %82
  %85 = xor i32 %5, %82
  %86 = add i32 %83, %84
  %87 = sub i32 %86, %5
  %88 = sub i32 %87, %82
  %89 = mul i32 %88, 163
  %90 = icmp eq i32 %89, 0
  br i1 %90, label %157, label %386

91:                                               ; preds = %332
  store i32 0, ptr %9, align 4
  store i32 -1347540062, ptr %6, align 4
  %92 = xor i32 %5, 1546211367
  %93 = and i32 %5, %92
  %94 = or i32 %5, %92
  %95 = xor i32 %5, %92
  %96 = sub i32 %94, %95
  %97 = sub i32 %96, %93
  %98 = mul i32 %97, 209
  %99 = icmp ugt i32 %98, 0
  br i1 %99, label %397, label %157

100:                                              ; preds = %304
  %101 = load i32, ptr %9, align 4
  %102 = load ptr, ptr %7, align 8
  %103 = load ptr, ptr %8, align 8
  call void @digest_to_hex(ptr noundef %102, ptr noundef %103, i32 noundef %101)
  %104 = load ptr, ptr %11, align 8
  %105 = icmp ne ptr %104, null
  %106 = select i1 %105, i32 1987875140, i32 -345644143
  store i32 %106, ptr %6, align 4
  %107 = xor i32 %5, 68474517
  %108 = and i32 %5, %107
  %109 = or i32 %5, %107
  %110 = xor i32 %5, %107
  %111 = sub i32 %109, %110
  %112 = sub i32 %111, %108
  %113 = mul i32 %112, 191
  %114 = icmp sgt i32 %113, 0
  br i1 %114, label %408, label %157

115:                                              ; preds = %342
  %116 = load ptr, ptr %11, align 8
  %117 = getelementptr inbounds i8, ptr %116, i64 0
  %118 = load i8, ptr %117, align 1
  %119 = sext i8 %118 to i32
  %120 = icmp ne i32 %119, 0
  %121 = select i1 %120, i32 -464189178, i32 -345644143
  store i32 %121, ptr %6, align 4
  %122 = xor i32 %5, -1539286845
  %123 = and i32 %5, %122
  %124 = or i32 %5, %122
  %125 = xor i32 %5, %122
  %126 = add i32 %5, %122
  %127 = sub i32 %126, %125
  %128 = mul i32 %123, 2
  %129 = sub i32 %127, %128
  %130 = mul i32 %129, 164
  %131 = icmp eq i32 %130, 0
  br i1 %131, label %157, label %416

132:                                              ; preds = %312
  %133 = getelementptr inbounds [33 x i8], ptr %13, i64 0, i64 0
  %134 = load ptr, ptr %11, align 8
  %135 = call i32 (ptr, ...) @printf(ptr noundef @.str.91, ptr noundef %133, ptr noundef %134)
  store i32 105418020, ptr %6, align 4
  %136 = xor i32 %5, 50877887
  %137 = and i32 %5, %136
  %138 = or i32 %5, %136
  %139 = xor i32 %5, %136
  %140 = sub i32 %138, %139
  %141 = sub i32 %140, %137
  %142 = mul i32 %141, 78
  %143 = icmp sgt i32 %142, 0
  br i1 %143, label %427, label %157

144:                                              ; preds = %300
  %145 = getelementptr inbounds [33 x i8], ptr %13, i64 0, i64 0
  %146 = call i32 (ptr, ...) @printf(ptr noundef @.str.92, ptr noundef %145)
  store i32 105418020, ptr %6, align 4
  %147 = xor i32 %5, 1268587845
  %148 = and i32 %5, %147
  %149 = or i32 %5, %147
  %150 = xor i32 %5, %147
  %151 = add i32 %148, %149
  %152 = sub i32 %151, %5
  %153 = sub i32 %152, %147
  %154 = mul i32 %153, 108
  %155 = icmp eq i32 %154, 0
  br i1 %155, label %157, label %438

156:                                              ; preds = %316
  ret void

157:                                              ; preds = %520, %512, %503, %494, %486, %476, %468, %459, %438, %427, %416, %408, %397, %386, %378, %369, %358, %348, %270, %257, %244, %231, %220, %201, %189, %178, %144, %132, %115, %100, %91, %78, %62, %48, %32, %19
  br label %14

158:                                              ; preds = %346, %342, %340, %334, %330, %328, %318, %314, %312, %306, %304
  store i32 -1132968595, ptr %6, align 4
  call void asm sideeffect "", ""()
  %159 = xor i32 %5, -566481887
  %160 = and i32 %5, %159
  %161 = or i32 %5, %159
  %162 = xor i32 %5, %159
  %163 = mul i32 %161, 2
  %164 = sub i32 %163, %162
  %165 = sub i32 %164, %5
  %166 = sub i32 %165, %159
  %167 = mul i32 %166, 39
  %168 = xor i32 %5, -1547642147
  %169 = and i32 %5, %168
  %170 = or i32 %5, %168
  %171 = xor i32 %5, %168
  %172 = add i32 %5, %168
  %173 = sub i32 %172, %171
  %174 = mul i32 %169, 2
  %175 = sub i32 %173, %174
  %176 = mul i32 %175, 131
  %177 = icmp ne i32 %167, %176
  br i1 %177, label %448, label %14

178:                                              ; preds = %314
  %179 = load i32, ptr %6, align 4
  %180 = xor i32 %179, -1493229217
  store i32 %180, ptr %6, align 4
  %181 = xor i32 %5, 98155607
  %182 = and i32 %5, %181
  %183 = or i32 %5, %181
  %184 = xor i32 %5, %181
  %185 = sub i32 %183, %184
  %186 = sub i32 %185, %182
  %187 = mul i32 %186, 56
  %188 = icmp ugt i32 %187, 0
  br i1 %188, label %459, label %157

189:                                              ; preds = %330
  %190 = load i32, ptr %6, align 4
  %191 = xor i32 %190, -308990047
  store i32 %191, ptr %6, align 4
  %192 = xor i32 %5, 1116408963
  %193 = and i32 %5, %192
  %194 = or i32 %5, %192
  %195 = xor i32 %5, %192
  %196 = add i32 %193, %194
  %197 = sub i32 %196, %5
  %198 = sub i32 %197, %192
  %199 = mul i32 %198, 191
  %200 = icmp uge i32 %199, 0
  br i1 %200, label %157, label %468

201:                                              ; preds = %340
  %202 = load i32, ptr %6, align 4
  %203 = xor i32 %202, 84004335
  store i32 %203, ptr %6, align 4
  %204 = xor i32 %5, 1813307359
  %205 = and i32 %5, %204
  %206 = or i32 %5, %204
  %207 = xor i32 %5, %204
  %208 = add i32 %205, %206
  %209 = sub i32 %208, %5
  %210 = sub i32 %209, %204
  %211 = mul i32 %210, 33
  %212 = xor i32 %5, 1902046799
  %213 = and i32 %5, %212
  %214 = or i32 %5, %212
  %215 = xor i32 %5, %212
  %216 = sub i32 %214, %215
  %217 = sub i32 %216, %213
  %218 = mul i32 %217, 100
  %219 = icmp eq i32 %211, %218
  br i1 %219, label %157, label %476

220:                                              ; preds = %336
  %221 = load i32, ptr %6, align 4
  %222 = xor i32 %221, -1924160527
  store i32 %222, ptr %6, align 4
  %223 = xor i32 %5, -1944577313
  %224 = and i32 %5, %223
  %225 = or i32 %5, %223
  %226 = xor i32 %5, %223
  %227 = sub i32 %225, %226
  %228 = sub i32 %227, %224
  %229 = mul i32 %228, 193
  %230 = icmp slt i32 %229, 1
  br i1 %230, label %157, label %486

231:                                              ; preds = %306
  %232 = load i32, ptr %6, align 4
  %233 = xor i32 %232, 49779876
  store i32 %233, ptr %6, align 4
  %234 = xor i32 %5, 1264269709
  %235 = and i32 %5, %234
  %236 = or i32 %5, %234
  %237 = xor i32 %5, %234
  %238 = mul i32 %236, 2
  %239 = sub i32 %238, %237
  %240 = sub i32 %239, %5
  %241 = sub i32 %240, %234
  %242 = mul i32 %241, 198
  %243 = icmp slt i32 %242, 0
  br i1 %243, label %494, label %157

244:                                              ; preds = %308
  %245 = load i32, ptr %6, align 4
  %246 = xor i32 %245, 1174433088
  store i32 %246, ptr %6, align 4
  %247 = xor i32 %5, 1993992501
  %248 = and i32 %5, %247
  %249 = or i32 %5, %247
  %250 = xor i32 %5, %247
  %251 = add i32 %5, %247
  %252 = sub i32 %251, %250
  %253 = mul i32 %248, 2
  %254 = sub i32 %252, %253
  %255 = mul i32 %254, 40
  %256 = icmp sgt i32 %255, 0
  br i1 %256, label %503, label %157

257:                                              ; preds = %302
  %258 = load i32, ptr %6, align 4
  %259 = xor i32 %258, 1188614926
  store i32 %259, ptr %6, align 4
  %260 = xor i32 %5, 19275739
  %261 = and i32 %5, %260
  %262 = or i32 %5, %260
  %263 = xor i32 %5, %260
  %264 = add i32 %5, %260
  %265 = sub i32 %264, %263
  %266 = mul i32 %261, 2
  %267 = sub i32 %265, %266
  %268 = mul i32 %267, 65
  %269 = icmp slt i32 %268, 1
  br i1 %269, label %157, label %512

270:                                              ; preds = %324
  %271 = load i32, ptr %6, align 4
  %272 = xor i32 %271, 708916367
  store i32 %272, ptr %6, align 4
  %273 = xor i32 %5, -1935758691
  %274 = and i32 %5, %273
  %275 = or i32 %5, %273
  %276 = xor i32 %5, %273
  %277 = mul i32 %275, 2
  %278 = sub i32 %277, %276
  %279 = sub i32 %278, %5
  %280 = sub i32 %279, %273
  %281 = mul i32 %280, 134
  %282 = xor i32 %5, -1862353141
  %283 = and i32 %5, %282
  %284 = or i32 %5, %282
  %285 = xor i32 %5, %282
  %286 = mul i32 %284, 2
  %287 = sub i32 %286, %285
  %288 = sub i32 %287, %5
  %289 = sub i32 %288, %282
  %290 = mul i32 %289, 191
  %291 = icmp ne i32 %281, %290
  br i1 %291, label %520, label %157

292:                                              ; preds = %14
  %293 = icmp slt i32 %17, 854236839
  br i1 %293, label %296, label %298

294:                                              ; preds = %14
  %295 = icmp slt i32 %17, 1486905980
  br i1 %295, label %320, label %322

296:                                              ; preds = %292
  %297 = icmp slt i32 %17, 508711401
  br i1 %297, label %300, label %302

298:                                              ; preds = %292
  %299 = icmp slt i32 %17, 964548059
  br i1 %299, label %308, label %310

300:                                              ; preds = %296
  %301 = icmp eq i32 %17, 7052744
  br i1 %301, label %144, label %304

302:                                              ; preds = %296
  %303 = icmp eq i32 %17, 508711401
  br i1 %303, label %257, label %306

304:                                              ; preds = %300
  %305 = icmp eq i32 %17, 76536617
  br i1 %305, label %100, label %158

306:                                              ; preds = %302
  %307 = icmp eq i32 %17, 811874466
  br i1 %307, label %231, label %158

308:                                              ; preds = %298
  %309 = icmp eq i32 %17, 854236839
  br i1 %309, label %244, label %312

310:                                              ; preds = %298
  %311 = icmp slt i32 %17, 986551627
  br i1 %311, label %314, label %316

312:                                              ; preds = %308
  %313 = icmp eq i32 %17, 921675725
  br i1 %313, label %132, label %158

314:                                              ; preds = %310
  %315 = icmp eq i32 %17, 964548059
  br i1 %315, label %178, label %158

316:                                              ; preds = %310
  %317 = icmp eq i32 %17, 986551627
  br i1 %317, label %156, label %318

318:                                              ; preds = %316
  %319 = icmp eq i32 %17, 1121244260
  br i1 %319, label %19, label %158

320:                                              ; preds = %294
  %321 = icmp slt i32 %17, 1300328785
  br i1 %321, label %324, label %326

322:                                              ; preds = %294
  %323 = icmp slt i32 %17, 1892737899
  br i1 %323, label %336, label %338

324:                                              ; preds = %320
  %325 = icmp eq i32 %17, 1192401047
  br i1 %325, label %270, label %328

326:                                              ; preds = %320
  %327 = icmp slt i32 %17, 1340529609
  br i1 %327, label %330, label %332

328:                                              ; preds = %324
  %329 = icmp eq i32 %17, 1243543279
  br i1 %329, label %62, label %158

330:                                              ; preds = %326
  %331 = icmp eq i32 %17, 1300328785
  br i1 %331, label %189, label %158

332:                                              ; preds = %326
  %333 = icmp eq i32 %17, 1340529609
  br i1 %333, label %91, label %334

334:                                              ; preds = %332
  %335 = icmp eq i32 %17, 1467066944
  br i1 %335, label %32, label %158

336:                                              ; preds = %322
  %337 = icmp eq i32 %17, 1486905980
  br i1 %337, label %220, label %340

338:                                              ; preds = %322
  %339 = icmp slt i32 %17, 1974260643
  br i1 %339, label %342, label %344

340:                                              ; preds = %336
  %341 = icmp eq i32 %17, 1802519197
  br i1 %341, label %201, label %158

342:                                              ; preds = %338
  %343 = icmp eq i32 %17, 1892737899
  br i1 %343, label %115, label %158

344:                                              ; preds = %338
  %345 = icmp eq i32 %17, 1974260643
  br i1 %345, label %48, label %346

346:                                              ; preds = %344
  %347 = icmp eq i32 %17, 2011133967
  br i1 %347, label %78, label %158

348:                                              ; preds = %19
  %349 = load i64, ptr %4, align 8
  %350 = ptrtoint ptr %0 to i64
  %351 = ptrtoint ptr %1 to i64
  %352 = ptrtoint ptr %2 to i64
  %353 = mul i64 %349, %351
  %354 = add i64 %353, %352
  %355 = or i64 %354, %351
  %356 = mul i64 %355, %349
  %357 = mul i64 %356, %350
  store i64 %357, ptr %4, align 8
  br label %157

358:                                              ; preds = %32
  %359 = load i64, ptr %4, align 8
  %360 = ptrtoint ptr %0 to i64
  %361 = ptrtoint ptr %1 to i64
  %362 = ptrtoint ptr %2 to i64
  %363 = mul i64 %362, %362
  %364 = or i64 %363, %360
  %365 = mul i64 %364, %361
  %366 = add i64 %365, %359
  %367 = xor i64 %366, %360
  %368 = add i64 %367, %362
  store i64 %368, ptr %4, align 8
  br label %157

369:                                              ; preds = %48
  %370 = load i64, ptr %4, align 8
  %371 = ptrtoint ptr %0 to i64
  %372 = ptrtoint ptr %1 to i64
  %373 = ptrtoint ptr %2 to i64
  %374 = sub i64 %373, %371
  %375 = xor i64 %374, %370
  %376 = add i64 %375, %371
  %377 = add i64 %376, %371
  store i64 %377, ptr %4, align 8
  br label %157

378:                                              ; preds = %62
  %379 = load i64, ptr %4, align 8
  %380 = ptrtoint ptr %0 to i64
  %381 = ptrtoint ptr %1 to i64
  %382 = ptrtoint ptr %2 to i64
  %383 = add i64 %380, %380
  %384 = add i64 %383, %380
  %385 = mul i64 %384, %380
  store i64 %385, ptr %4, align 8
  br label %157

386:                                              ; preds = %78
  %387 = load i64, ptr %4, align 8
  %388 = ptrtoint ptr %0 to i64
  %389 = ptrtoint ptr %1 to i64
  %390 = ptrtoint ptr %2 to i64
  %391 = mul i64 %388, %388
  %392 = mul i64 %391, %387
  %393 = add i64 %392, %390
  %394 = mul i64 %393, %389
  %395 = sub i64 %394, %390
  %396 = xor i64 %395, %390
  store i64 %396, ptr %4, align 8
  br label %157

397:                                              ; preds = %91
  %398 = load i64, ptr %4, align 8
  %399 = ptrtoint ptr %0 to i64
  %400 = ptrtoint ptr %1 to i64
  %401 = ptrtoint ptr %2 to i64
  %402 = or i64 %399, %401
  %403 = add i64 %402, %400
  %404 = xor i64 %403, %401
  %405 = or i64 %404, %401
  %406 = xor i64 %405, %399
  %407 = sub i64 %406, %401
  store i64 %407, ptr %4, align 8
  br label %157

408:                                              ; preds = %100
  %409 = load i64, ptr %4, align 8
  %410 = ptrtoint ptr %0 to i64
  %411 = ptrtoint ptr %1 to i64
  %412 = ptrtoint ptr %2 to i64
  %413 = and i64 %410, %409
  %414 = and i64 %413, %410
  %415 = or i64 %414, %410
  store i64 %415, ptr %4, align 8
  br label %157

416:                                              ; preds = %115
  %417 = load i64, ptr %4, align 8
  %418 = ptrtoint ptr %0 to i64
  %419 = ptrtoint ptr %1 to i64
  %420 = ptrtoint ptr %2 to i64
  %421 = add i64 %420, %417
  %422 = xor i64 %421, %420
  %423 = and i64 %422, %418
  %424 = xor i64 %423, %419
  %425 = or i64 %424, %417
  %426 = or i64 %425, %420
  store i64 %426, ptr %4, align 8
  br label %157

427:                                              ; preds = %132
  %428 = load i64, ptr %4, align 8
  %429 = ptrtoint ptr %0 to i64
  %430 = ptrtoint ptr %1 to i64
  %431 = ptrtoint ptr %2 to i64
  %432 = or i64 %429, %429
  %433 = or i64 %432, %430
  %434 = xor i64 %433, %429
  %435 = sub i64 %434, %428
  %436 = xor i64 %435, %429
  %437 = sub i64 %436, %431
  store i64 %437, ptr %4, align 8
  br label %157

438:                                              ; preds = %144
  %439 = load i64, ptr %4, align 8
  %440 = ptrtoint ptr %0 to i64
  %441 = ptrtoint ptr %1 to i64
  %442 = ptrtoint ptr %2 to i64
  %443 = mul i64 %439, %439
  %444 = mul i64 %443, %439
  %445 = mul i64 %444, %441
  %446 = or i64 %445, %439
  %447 = mul i64 %446, %440
  store i64 %447, ptr %4, align 8
  br label %157

448:                                              ; preds = %158
  %449 = load i64, ptr %4, align 8
  %450 = ptrtoint ptr %0 to i64
  %451 = ptrtoint ptr %1 to i64
  %452 = ptrtoint ptr %2 to i64
  %453 = and i64 %450, %450
  %454 = add i64 %453, %449
  %455 = sub i64 %454, %450
  %456 = sub i64 %455, %451
  %457 = and i64 %456, %449
  %458 = add i64 %457, %452
  store i64 %458, ptr %4, align 8
  br label %14

459:                                              ; preds = %178
  %460 = load i64, ptr %4, align 8
  %461 = ptrtoint ptr %0 to i64
  %462 = ptrtoint ptr %1 to i64
  %463 = ptrtoint ptr %2 to i64
  %464 = xor i64 %463, %463
  %465 = and i64 %464, %463
  %466 = add i64 %465, %460
  %467 = sub i64 %466, %463
  store i64 %467, ptr %4, align 8
  br label %157

468:                                              ; preds = %189
  %469 = load i64, ptr %4, align 8
  %470 = ptrtoint ptr %0 to i64
  %471 = ptrtoint ptr %1 to i64
  %472 = ptrtoint ptr %2 to i64
  %473 = add i64 %471, %471
  %474 = xor i64 %473, %469
  %475 = mul i64 %474, %470
  store i64 %475, ptr %4, align 8
  br label %157

476:                                              ; preds = %201
  %477 = load i64, ptr %4, align 8
  %478 = ptrtoint ptr %0 to i64
  %479 = ptrtoint ptr %1 to i64
  %480 = ptrtoint ptr %2 to i64
  %481 = and i64 %480, %479
  %482 = mul i64 %481, %477
  %483 = xor i64 %482, %478
  %484 = sub i64 %483, %477
  %485 = sub i64 %484, %477
  store i64 %485, ptr %4, align 8
  br label %157

486:                                              ; preds = %220
  %487 = load i64, ptr %4, align 8
  %488 = ptrtoint ptr %0 to i64
  %489 = ptrtoint ptr %1 to i64
  %490 = ptrtoint ptr %2 to i64
  %491 = add i64 %489, %488
  %492 = and i64 %491, %490
  %493 = add i64 %492, %487
  store i64 %493, ptr %4, align 8
  br label %157

494:                                              ; preds = %231
  %495 = load i64, ptr %4, align 8
  %496 = ptrtoint ptr %0 to i64
  %497 = ptrtoint ptr %1 to i64
  %498 = ptrtoint ptr %2 to i64
  %499 = add i64 %496, %498
  %500 = and i64 %499, %496
  %501 = mul i64 %500, %498
  %502 = add i64 %501, %495
  store i64 %502, ptr %4, align 8
  br label %157

503:                                              ; preds = %244
  %504 = load i64, ptr %4, align 8
  %505 = ptrtoint ptr %0 to i64
  %506 = ptrtoint ptr %1 to i64
  %507 = ptrtoint ptr %2 to i64
  %508 = xor i64 %505, %506
  %509 = sub i64 %508, %506
  %510 = mul i64 %509, %507
  %511 = and i64 %510, %505
  store i64 %511, ptr %4, align 8
  br label %157

512:                                              ; preds = %257
  %513 = load i64, ptr %4, align 8
  %514 = ptrtoint ptr %0 to i64
  %515 = ptrtoint ptr %1 to i64
  %516 = ptrtoint ptr %2 to i64
  %517 = mul i64 %513, %513
  %518 = add i64 %517, %513
  %519 = add i64 %518, %516
  store i64 %519, ptr %4, align 8
  br label %157

520:                                              ; preds = %270
  %521 = load i64, ptr %4, align 8
  %522 = ptrtoint ptr %0 to i64
  %523 = ptrtoint ptr %1 to i64
  %524 = ptrtoint ptr %2 to i64
  %525 = xor i64 %523, %524
  %526 = add i64 %525, %523
  %527 = mul i64 %526, %522
  %528 = mul i64 %527, %524
  store i64 %528, ptr %4, align 8
  br label %157
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @zero_memory(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca ptr, align 8
  store i32 1051890646, ptr %4, align 4
  br label %8

8:                                                ; preds = %170, %58, %57, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, 528728178
  %11 = mul i32 %10, 960246997
  %12 = icmp slt i32 %11, 1402980498
  br i1 %12, label %126, label %128

13:                                               ; preds = %132
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  %14 = load ptr, ptr %5, align 8
  store ptr %14, ptr %7, align 8
  store i32 -2106279759, ptr %4, align 4
  %15 = xor i64 %1, -5272095546423360639
  %16 = and i64 %1, %15
  %17 = or i64 %1, %15
  %18 = xor i64 %1, %15
  %19 = add i64 %1, %15
  %20 = sub i64 %19, %18
  %21 = mul i64 %16, 2
  %22 = sub i64 %20, %21
  %23 = mul i64 %22, 90
  %24 = icmp sle i64 %23, 0
  br i1 %24, label %57, label %146

25:                                               ; preds = %140
  %26 = load i64, ptr %6, align 8
  %27 = icmp ugt i64 %26, 0
  %28 = select i1 %27, i32 1195882428, i32 -920367653
  store i32 %28, ptr %4, align 4
  %29 = xor i64 %1, 806267215779638749
  %30 = and i64 %1, %29
  %31 = or i64 %1, %29
  %32 = xor i64 %1, %29
  %33 = mul i64 %31, 2
  %34 = sub i64 %33, %32
  %35 = sub i64 %34, %1
  %36 = sub i64 %35, %29
  %37 = mul i64 %36, 184
  %38 = icmp ne i64 %37, 0
  br i1 %38, label %155, label %57

39:                                               ; preds = %138
  %40 = load ptr, ptr %7, align 8
  %41 = getelementptr inbounds nuw i8, ptr %40, i32 1
  store ptr %41, ptr %7, align 8
  store volatile i8 0, ptr %40, align 1
  %42 = load i64, ptr %6, align 8
  %43 = or i64 %42, -1
  %44 = and i64 %42, -1
  %45 = add i64 %43, %44
  store i64 %45, ptr %6, align 8
  store i32 -2106279759, ptr %4, align 4
  %46 = xor i64 %1, 2368984067532315081
  %47 = and i64 %1, %46
  %48 = or i64 %1, %46
  %49 = xor i64 %1, %46
  %50 = mul i64 %48, 2
  %51 = sub i64 %50, %49
  %52 = sub i64 %51, %1
  %53 = sub i64 %52, %46
  %54 = mul i64 %53, 210
  %55 = icmp eq i64 %54, 0
  br i1 %55, label %57, label %164

56:                                               ; preds = %136
  ret void

57:                                               ; preds = %200, %194, %185, %176, %164, %155, %146, %113, %101, %88, %68, %39, %25, %13
  br label %8

58:                                               ; preds = %144, %142, %136, %134
  store i32 1051890646, ptr %4, align 4
  call void asm sideeffect "", ""()
  %59 = xor i64 %1, 3436402251522412087
  %60 = and i64 %1, %59
  %61 = or i64 %1, %59
  %62 = xor i64 %1, %59
  %63 = add i64 %60, %61
  %64 = sub i64 %63, %1
  %65 = sub i64 %64, %59
  %66 = mul i64 %65, 116
  %67 = icmp slt i64 %66, 1
  br i1 %67, label %8, label %170

68:                                               ; preds = %144
  %69 = load i32, ptr %4, align 4
  %70 = xor i32 %69, -1887366761
  store i32 %70, ptr %4, align 4
  %71 = xor i64 %1, 7675713655067081845
  %72 = and i64 %1, %71
  %73 = or i64 %1, %71
  %74 = xor i64 %1, %71
  %75 = mul i64 %73, 2
  %76 = sub i64 %75, %74
  %77 = sub i64 %76, %1
  %78 = sub i64 %77, %71
  %79 = mul i64 %78, 228
  %80 = xor i64 %1, -2496130321985321945
  %81 = and i64 %1, %80
  %82 = or i64 %1, %80
  %83 = xor i64 %1, %80
  %84 = sub i64 %82, %83
  %85 = sub i64 %84, %81
  %86 = mul i64 %85, 108
  %87 = icmp eq i64 %79, %86
  br i1 %87, label %57, label %176

88:                                               ; preds = %134
  %89 = load i32, ptr %4, align 4
  %90 = xor i32 %89, -2051124952
  store i32 %90, ptr %4, align 4
  %91 = xor i64 %1, 8431245867252636605
  %92 = and i64 %1, %91
  %93 = or i64 %1, %91
  %94 = xor i64 %1, %91
  %95 = mul i64 %93, 2
  %96 = sub i64 %95, %94
  %97 = sub i64 %96, %1
  %98 = sub i64 %97, %91
  %99 = mul i64 %98, 249
  %100 = icmp uge i64 %99, 0
  br i1 %100, label %57, label %185

101:                                              ; preds = %142
  %102 = load i32, ptr %4, align 4
  %103 = xor i32 %102, -1846502845
  store i32 %103, ptr %4, align 4
  %104 = xor i64 %1, -2838989161882879117
  %105 = and i64 %1, %104
  %106 = or i64 %1, %104
  %107 = xor i64 %1, %104
  %108 = add i64 %105, %106
  %109 = sub i64 %108, %1
  %110 = sub i64 %109, %104
  %111 = mul i64 %110, 62
  %112 = icmp sgt i64 %111, 0
  br i1 %112, label %194, label %57

113:                                              ; preds = %130
  %114 = load i32, ptr %4, align 4
  %115 = xor i32 %114, 590990079
  store i32 %115, ptr %4, align 4
  %116 = xor i64 %1, 6325344580607951197
  %117 = and i64 %1, %116
  %118 = or i64 %1, %116
  %119 = xor i64 %1, %116
  %120 = mul i64 %118, 2
  %121 = sub i64 %120, %119
  %122 = sub i64 %121, %1
  %123 = sub i64 %122, %116
  %124 = mul i64 %123, 171
  %125 = icmp sgt i64 %124, 0
  br i1 %125, label %200, label %57

126:                                              ; preds = %8
  %127 = icmp slt i32 %11, 1146499636
  br i1 %127, label %130, label %132

128:                                              ; preds = %8
  %129 = icmp slt i32 %11, 2058311787
  br i1 %129, label %138, label %140

130:                                              ; preds = %126
  %131 = icmp eq i32 %11, 470715774
  br i1 %131, label %113, label %134

132:                                              ; preds = %126
  %133 = icmp eq i32 %11, 1146499636
  br i1 %133, label %13, label %136

134:                                              ; preds = %130
  %135 = icmp eq i32 %11, 957990633
  br i1 %135, label %88, label %58

136:                                              ; preds = %132
  %137 = icmp eq i32 %11, 1156250717
  br i1 %137, label %56, label %58

138:                                              ; preds = %128
  %139 = icmp eq i32 %11, 1402980498
  br i1 %139, label %39, label %142

140:                                              ; preds = %128
  %141 = icmp eq i32 %11, 2058311787
  br i1 %141, label %25, label %144

142:                                              ; preds = %138
  %143 = icmp eq i32 %11, 1550416332
  br i1 %143, label %101, label %58

144:                                              ; preds = %140
  %145 = icmp eq i32 %11, 2145419299
  br i1 %145, label %68, label %58

146:                                              ; preds = %13
  %147 = load i64, ptr %3, align 8
  %148 = ptrtoint ptr %0 to i64
  %149 = mul i64 %147, %148
  %150 = xor i64 %149, %148
  %151 = sub i64 %150, %148
  %152 = sub i64 %151, %147
  %153 = add i64 %152, %1
  %154 = xor i64 %153, %1
  store i64 %154, ptr %3, align 8
  br label %57

155:                                              ; preds = %25
  %156 = load i64, ptr %3, align 8
  %157 = ptrtoint ptr %0 to i64
  %158 = sub i64 %157, %1
  %159 = or i64 %158, %1
  %160 = sub i64 %159, %1
  %161 = and i64 %160, %156
  %162 = add i64 %161, %156
  %163 = mul i64 %162, %1
  store i64 %163, ptr %3, align 8
  br label %57

164:                                              ; preds = %39
  %165 = load i64, ptr %3, align 8
  %166 = ptrtoint ptr %0 to i64
  %167 = add i64 %165, %166
  %168 = or i64 %167, %165
  %169 = or i64 %168, %165
  store i64 %169, ptr %3, align 8
  br label %57

170:                                              ; preds = %58
  %171 = load i64, ptr %3, align 8
  %172 = ptrtoint ptr %0 to i64
  %173 = mul i64 %172, %171
  %174 = mul i64 %173, %172
  %175 = mul i64 %174, %171
  store i64 %175, ptr %3, align 8
  br label %8

176:                                              ; preds = %68
  %177 = load i64, ptr %3, align 8
  %178 = ptrtoint ptr %0 to i64
  %179 = or i64 %177, %178
  %180 = xor i64 %179, %1
  %181 = or i64 %180, %178
  %182 = xor i64 %181, %177
  %183 = mul i64 %182, %178
  %184 = add i64 %183, %1
  store i64 %184, ptr %3, align 8
  br label %57

185:                                              ; preds = %88
  %186 = load i64, ptr %3, align 8
  %187 = ptrtoint ptr %0 to i64
  %188 = add i64 %186, %186
  %189 = and i64 %188, %186
  %190 = xor i64 %189, %1
  %191 = mul i64 %190, %1
  %192 = or i64 %191, %1
  %193 = add i64 %192, %187
  store i64 %193, ptr %3, align 8
  br label %57

194:                                              ; preds = %101
  %195 = load i64, ptr %3, align 8
  %196 = ptrtoint ptr %0 to i64
  %197 = or i64 %1, %195
  %198 = or i64 %197, %196
  %199 = or i64 %198, %196
  store i64 %199, ptr %3, align 8
  br label %57

200:                                              ; preds = %113
  %201 = load i64, ptr %3, align 8
  %202 = ptrtoint ptr %0 to i64
  %203 = and i64 %1, %1
  %204 = sub i64 %203, %201
  %205 = mul i64 %204, %1
  %206 = or i64 %205, %1
  store i64 %206, ptr %3, align 8
  br label %57
}

declare i64 @fwrite(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define internal void @digest_to_hex(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  %10 = alloca i32, align 4
  %11 = alloca i8, align 1
  store i32 -1172975879, ptr %5, align 4
  br label %12

12:                                               ; preds = %264, %157, %156, %3
  %13 = load i32, ptr %5, align 4
  %14 = sub i32 %13, -458682271
  %15 = mul i32 %14, 599946651
  %16 = icmp slt i32 %15, 1183570636
  br i1 %16, label %218, label %220

17:                                               ; preds = %224
  store ptr %0, ptr %6, align 8
  store ptr %1, ptr %7, align 8
  store i32 %2, ptr %8, align 4
  %18 = load i32, ptr %8, align 4
  %19 = icmp ne i32 %18, 0
  %20 = zext i1 %19 to i64
  %21 = select i1 %19, ptr @digest_to_hex.upper_table, ptr @digest_to_hex.lower_table
  store ptr %21, ptr %9, align 8
  store i32 0, ptr %10, align 4
  store i32 -1151242336, ptr %5, align 4
  %22 = xor i32 %2, 928171723
  %23 = and i32 %2, %22
  %24 = or i32 %2, %22
  %25 = xor i32 %2, %22
  %26 = mul i32 %24, 2
  %27 = sub i32 %26, %25
  %28 = sub i32 %27, %2
  %29 = sub i32 %28, %22
  %30 = mul i32 %29, 75
  %31 = icmp slt i32 %30, 1
  br i1 %31, label %156, label %238

32:                                               ; preds = %226
  %33 = load i32, ptr %10, align 4
  %34 = icmp slt i32 %33, 16
  %35 = select i1 %34, i32 -2009712476, i32 699094249
  store i32 %35, ptr %5, align 4
  %36 = xor i32 %2, 703336823
  %37 = and i32 %2, %36
  %38 = or i32 %2, %36
  %39 = xor i32 %2, %36
  %40 = mul i32 %38, 2
  %41 = sub i32 %40, %39
  %42 = sub i32 %41, %2
  %43 = sub i32 %42, %36
  %44 = mul i32 %43, 52
  %45 = icmp slt i32 %44, 0
  br i1 %45, label %246, label %156

46:                                               ; preds = %228
  %47 = load ptr, ptr %6, align 8
  %48 = load i32, ptr %10, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds i8, ptr %47, i64 %49
  %51 = load i8, ptr %50, align 1
  store i8 %51, ptr %11, align 1
  %52 = load ptr, ptr %9, align 8
  %53 = load i8, ptr %11, align 1
  %54 = zext i8 %53 to i32
  %55 = icmp slt i32 %54, 0
  %56 = udiv i32 %54, 16
  %57 = load i32, ptr %5, align 4
  %58 = xor i32 %57, 2009712475
  %59 = xor i32 %54, %58
  %60 = udiv i32 %59, 16
  %61 = load i32, ptr %5, align 4
  %62 = xor i32 %61, 2009712475
  %63 = xor i32 %60, %62
  %64 = select i1 %55, i32 %63, i32 %56
  %65 = load i32, ptr %5, align 4
  %66 = xor i32 %65, -2009712469
  %67 = add i32 %64, %66
  %68 = load i32, ptr %5, align 4
  %69 = xor i32 %68, -2009712469
  %70 = or i32 %64, %69
  %71 = load i32, ptr %5, align 4
  %72 = xor i32 %71, -1274793995
  %73 = mul i32 %67, %72
  %74 = load i32, ptr %5, align 4
  %75 = xor i32 %74, -1274793995
  %76 = mul i32 %70, %75
  %77 = sub i32 %73, %76
  %78 = load i32, ptr %5, align 4
  %79 = xor i32 %78, 1064282389
  %80 = mul i32 %77, %79
  %81 = zext i32 %80 to i64
  %82 = getelementptr inbounds nuw i8, ptr %52, i64 %81
  %83 = load i8, ptr %82, align 1
  %84 = load ptr, ptr %7, align 8
  %85 = load i32, ptr %10, align 4
  %86 = load i32, ptr %5, align 4
  %87 = xor i32 %86, -2009712474
  %88 = mul nsw i32 %85, %87
  %89 = load i32, ptr %5, align 4
  %90 = xor i32 %89, -2009712476
  %91 = xor i32 %88, %90
  %92 = load i32, ptr %5, align 4
  %93 = xor i32 %92, -2009712476
  %94 = and i32 %88, %93
  %95 = add i32 %94, %94
  %96 = add i32 %91, %95
  %97 = sext i32 %96 to i64
  %98 = getelementptr inbounds i8, ptr %84, i64 %97
  store i8 %83, ptr %98, align 1
  %99 = load ptr, ptr %9, align 8
  %100 = load i8, ptr %11, align 1
  %101 = zext i8 %100 to i32
  %102 = load i32, ptr %5, align 4
  %103 = xor i32 %102, -2009712469
  %104 = add i32 %101, %103
  %105 = load i32, ptr %5, align 4
  %106 = xor i32 %105, -2009712469
  %107 = or i32 %101, %106
  %108 = sub i32 %104, %107
  %109 = zext i32 %108 to i64
  %110 = getelementptr inbounds nuw i8, ptr %99, i64 %109
  %111 = load i8, ptr %110, align 1
  %112 = load ptr, ptr %7, align 8
  %113 = load i32, ptr %10, align 4
  %114 = load i32, ptr %5, align 4
  %115 = xor i32 %114, -2009712474
  %116 = mul nsw i32 %113, %115
  %117 = load i32, ptr %5, align 4
  %118 = xor i32 %117, -2009712475
  %119 = sub i32 %116, %118
  %120 = load i32, ptr %5, align 4
  %121 = xor i32 %120, -2009712474
  %122 = mul i32 %116, %121
  %123 = load i32, ptr %5, align 4
  %124 = xor i32 %123, -2009712475
  %125 = mul i32 %124, %119
  %126 = sub i32 %122, %125
  %127 = sext i32 %126 to i64
  %128 = getelementptr inbounds i8, ptr %112, i64 %127
  store i8 %111, ptr %128, align 1
  %129 = load i32, ptr %10, align 4
  %130 = load i32, ptr %5, align 4
  %131 = xor i32 %130, -2009712475
  %132 = or i32 %129, %131
  %133 = load i32, ptr %5, align 4
  %134 = xor i32 %133, -2009712475
  %135 = and i32 %129, %134
  %136 = add i32 %132, %135
  store i32 %136, ptr %10, align 4
  store i32 -1151242336, ptr %5, align 4
  %137 = xor i32 %2, 1922792599
  %138 = and i32 %2, %137
  %139 = or i32 %2, %137
  %140 = xor i32 %2, %137
  %141 = sub i32 %139, %140
  %142 = sub i32 %141, %138
  %143 = mul i32 %142, 179
  %144 = xor i32 %2, -1479545861
  %145 = and i32 %2, %144
  %146 = or i32 %2, %144
  %147 = xor i32 %2, %144
  %148 = add i32 %145, %146
  %149 = sub i32 %148, %2
  %150 = sub i32 %149, %144
  %151 = mul i32 %150, 124
  %152 = icmp eq i32 %143, %151
  br i1 %152, label %156, label %256

153:                                              ; preds = %234
  %154 = load ptr, ptr %7, align 8
  %155 = getelementptr inbounds i8, ptr %154, i64 32
  store i8 0, ptr %155, align 1
  ret void

156:                                              ; preds = %303, %294, %285, %275, %256, %246, %238, %205, %192, %180, %168, %46, %32, %17
  br label %12

157:                                              ; preds = %236, %234, %228, %226
  store i32 -1172975879, ptr %5, align 4
  call void asm sideeffect "", ""()
  %158 = xor i32 %2, 1491087127
  %159 = and i32 %2, %158
  %160 = or i32 %2, %158
  %161 = xor i32 %2, %158
  %162 = add i32 %2, %158
  %163 = sub i32 %162, %161
  %164 = mul i32 %159, 2
  %165 = sub i32 %163, %164
  %166 = mul i32 %165, 6
  %167 = icmp sgt i32 %166, 0
  br i1 %167, label %264, label %12

168:                                              ; preds = %222
  %169 = load i32, ptr %5, align 4
  %170 = xor i32 %169, -2002521307
  store i32 %170, ptr %5, align 4
  %171 = xor i32 %2, 682801505
  %172 = and i32 %2, %171
  %173 = or i32 %2, %171
  %174 = xor i32 %2, %171
  %175 = add i32 %172, %173
  %176 = sub i32 %175, %2
  %177 = sub i32 %176, %171
  %178 = mul i32 %177, 157
  %179 = icmp eq i32 %178, 0
  br i1 %179, label %156, label %275

180:                                              ; preds = %232
  %181 = load i32, ptr %5, align 4
  %182 = xor i32 %181, -1373999498
  store i32 %182, ptr %5, align 4
  %183 = xor i32 %2, 1982761749
  %184 = and i32 %2, %183
  %185 = or i32 %2, %183
  %186 = xor i32 %2, %183
  %187 = add i32 %184, %185
  %188 = sub i32 %187, %2
  %189 = sub i32 %188, %183
  %190 = mul i32 %189, 87
  %191 = icmp slt i32 %190, 1
  br i1 %191, label %156, label %285

192:                                              ; preds = %230
  %193 = load i32, ptr %5, align 4
  %194 = xor i32 %193, -1243459984
  store i32 %194, ptr %5, align 4
  %195 = xor i32 %2, -1105744733
  %196 = and i32 %2, %195
  %197 = or i32 %2, %195
  %198 = xor i32 %2, %195
  %199 = add i32 %2, %195
  %200 = sub i32 %199, %198
  %201 = mul i32 %196, 2
  %202 = sub i32 %200, %201
  %203 = mul i32 %202, 238
  %204 = icmp uge i32 %203, 0
  br i1 %204, label %156, label %294

205:                                              ; preds = %236
  %206 = load i32, ptr %5, align 4
  %207 = xor i32 %206, 990359215
  store i32 %207, ptr %5, align 4
  %208 = xor i32 %2, -823212305
  %209 = and i32 %2, %208
  %210 = or i32 %2, %208
  %211 = xor i32 %2, %208
  %212 = mul i32 %210, 2
  %213 = sub i32 %212, %211
  %214 = sub i32 %213, %2
  %215 = sub i32 %214, %208
  %216 = mul i32 %215, 138
  %217 = icmp eq i32 %216, 0
  br i1 %217, label %156, label %303

218:                                              ; preds = %12
  %219 = icmp slt i32 %15, 589487624
  br i1 %219, label %222, label %224

220:                                              ; preds = %12
  %221 = icmp slt i32 %15, 1543152282
  br i1 %221, label %230, label %232

222:                                              ; preds = %218
  %223 = icmp eq i32 %15, 16474698
  br i1 %223, label %168, label %226

224:                                              ; preds = %218
  %225 = icmp eq i32 %15, 589487624
  br i1 %225, label %17, label %228

226:                                              ; preds = %222
  %227 = icmp eq i32 %15, 266827301
  br i1 %227, label %32, label %157

228:                                              ; preds = %224
  %229 = icmp eq i32 %15, 899940241
  br i1 %229, label %46, label %157

230:                                              ; preds = %220
  %231 = icmp eq i32 %15, 1183570636
  br i1 %231, label %192, label %234

232:                                              ; preds = %220
  %233 = icmp eq i32 %15, 1543152282
  br i1 %233, label %180, label %236

234:                                              ; preds = %230
  %235 = icmp eq i32 %15, 1489086040
  br i1 %235, label %153, label %157

236:                                              ; preds = %232
  %237 = icmp eq i32 %15, 2141953739
  br i1 %237, label %205, label %157

238:                                              ; preds = %17
  %239 = load i64, ptr %4, align 8
  %240 = ptrtoint ptr %0 to i64
  %241 = ptrtoint ptr %1 to i64
  %242 = zext i32 %2 to i64
  %243 = or i64 %240, %242
  %244 = and i64 %243, %242
  %245 = or i64 %244, %242
  store i64 %245, ptr %4, align 8
  br label %156

246:                                              ; preds = %32
  %247 = load i64, ptr %4, align 8
  %248 = ptrtoint ptr %0 to i64
  %249 = ptrtoint ptr %1 to i64
  %250 = zext i32 %2 to i64
  %251 = or i64 %250, %250
  %252 = sub i64 %251, %247
  %253 = or i64 %252, %248
  %254 = sub i64 %253, %247
  %255 = mul i64 %254, %247
  store i64 %255, ptr %4, align 8
  br label %156

256:                                              ; preds = %46
  %257 = load i64, ptr %4, align 8
  %258 = ptrtoint ptr %0 to i64
  %259 = ptrtoint ptr %1 to i64
  %260 = zext i32 %2 to i64
  %261 = mul i64 %259, %257
  %262 = and i64 %261, %260
  %263 = add i64 %262, %259
  store i64 %263, ptr %4, align 8
  br label %156

264:                                              ; preds = %157
  %265 = load i64, ptr %4, align 8
  %266 = ptrtoint ptr %0 to i64
  %267 = ptrtoint ptr %1 to i64
  %268 = zext i32 %2 to i64
  %269 = or i64 %266, %268
  %270 = or i64 %269, %268
  %271 = add i64 %270, %266
  %272 = or i64 %271, %266
  %273 = sub i64 %272, %268
  %274 = sub i64 %273, %266
  store i64 %274, ptr %4, align 8
  br label %12

275:                                              ; preds = %168
  %276 = load i64, ptr %4, align 8
  %277 = ptrtoint ptr %0 to i64
  %278 = ptrtoint ptr %1 to i64
  %279 = zext i32 %2 to i64
  %280 = xor i64 %277, %278
  %281 = xor i64 %280, %278
  %282 = or i64 %281, %276
  %283 = xor i64 %282, %278
  %284 = sub i64 %283, %276
  store i64 %284, ptr %4, align 8
  br label %156

285:                                              ; preds = %180
  %286 = load i64, ptr %4, align 8
  %287 = ptrtoint ptr %0 to i64
  %288 = ptrtoint ptr %1 to i64
  %289 = zext i32 %2 to i64
  %290 = sub i64 %286, %289
  %291 = or i64 %290, %288
  %292 = sub i64 %291, %287
  %293 = xor i64 %292, %288
  store i64 %293, ptr %4, align 8
  br label %156

294:                                              ; preds = %192
  %295 = load i64, ptr %4, align 8
  %296 = ptrtoint ptr %0 to i64
  %297 = ptrtoint ptr %1 to i64
  %298 = zext i32 %2 to i64
  %299 = add i64 %295, %298
  %300 = sub i64 %299, %297
  %301 = sub i64 %300, %297
  %302 = or i64 %301, %297
  store i64 %302, ptr %4, align 8
  br label %156

303:                                              ; preds = %205
  %304 = load i64, ptr %4, align 8
  %305 = ptrtoint ptr %0 to i64
  %306 = ptrtoint ptr %1 to i64
  %307 = zext i32 %2 to i64
  %308 = add i64 %307, %304
  %309 = sub i64 %308, %304
  %310 = or i64 %309, %307
  %311 = and i64 %310, %305
  store i64 %311, ptr %4, align 8
  br label %156
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
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  store i32 199438311, ptr %4, align 4
  br label %6

6:                                                ; preds = %136, %61, %60, %1
  %7 = load i32, ptr %4, align 4
  %8 = sub i32 %7, -23134197
  %9 = mul i32 %8, 1894842403
  %10 = icmp slt i32 %9, 1312678045
  br i1 %10, label %106, label %108

11:                                               ; preds = %112
  store ptr %0, ptr %5, align 8
  %12 = load ptr, ptr %5, align 8
  %13 = icmp eq ptr %12, null
  %14 = select i1 %13, i32 695467024, i32 66472010
  store i32 %14, ptr %4, align 4
  %15 = xor i32 %3, -1204624283
  %16 = and i32 %3, %15
  %17 = or i32 %3, %15
  %18 = xor i32 %3, %15
  %19 = add i32 %3, %15
  %20 = sub i32 %19, %18
  %21 = mul i32 %16, 2
  %22 = sub i32 %20, %21
  %23 = mul i32 %22, 254
  %24 = icmp uge i32 %23, 0
  br i1 %24, label %60, label %122

25:                                               ; preds = %114
  call void @die_message(ptr noundef @.str.65)
  store i32 66472010, ptr %4, align 4
  %26 = xor i32 %3, -1245909009
  %27 = and i32 %3, %26
  %28 = or i32 %3, %26
  %29 = xor i32 %3, %26
  %30 = sub i32 %28, %29
  %31 = sub i32 %30, %27
  %32 = mul i32 %31, 99
  %33 = icmp sle i32 %32, 0
  br i1 %33, label %60, label %129

34:                                               ; preds = %116
  %35 = load ptr, ptr %5, align 8
  %36 = getelementptr inbounds nuw %struct.MD5Context, ptr %35, i32 0, i32 0
  %37 = getelementptr inbounds [4 x i32], ptr %36, i64 0, i64 0
  store i32 1732584193, ptr %37, align 8
  %38 = load ptr, ptr %5, align 8
  %39 = getelementptr inbounds nuw %struct.MD5Context, ptr %38, i32 0, i32 0
  %40 = getelementptr inbounds [4 x i32], ptr %39, i64 0, i64 1
  store i32 -271733879, ptr %40, align 4
  %41 = load ptr, ptr %5, align 8
  %42 = getelementptr inbounds nuw %struct.MD5Context, ptr %41, i32 0, i32 0
  %43 = getelementptr inbounds [4 x i32], ptr %42, i64 0, i64 2
  store i32 -1732584194, ptr %43, align 8
  %44 = load ptr, ptr %5, align 8
  %45 = getelementptr inbounds nuw %struct.MD5Context, ptr %44, i32 0, i32 0
  %46 = getelementptr inbounds [4 x i32], ptr %45, i64 0, i64 3
  store i32 271733878, ptr %46, align 4
  %47 = load ptr, ptr %5, align 8
  %48 = getelementptr inbounds nuw %struct.MD5Context, ptr %47, i32 0, i32 1
  store i64 0, ptr %48, align 8
  %49 = load ptr, ptr %5, align 8
  %50 = getelementptr inbounds nuw %struct.MD5Context, ptr %49, i32 0, i32 3
  store i64 0, ptr %50, align 8
  %51 = load ptr, ptr %5, align 8
  %52 = getelementptr inbounds nuw %struct.MD5Context, ptr %51, i32 0, i32 4
  store i64 0, ptr %52, align 8
  %53 = load ptr, ptr %5, align 8
  %54 = getelementptr inbounds nuw %struct.MD5Context, ptr %53, i32 0, i32 5
  store i32 0, ptr %54, align 8
  %55 = load ptr, ptr %5, align 8
  %56 = getelementptr inbounds nuw %struct.MD5Context, ptr %55, i32 0, i32 6
  store i32 0, ptr %56, align 4
  %57 = load ptr, ptr %5, align 8
  %58 = getelementptr inbounds nuw %struct.MD5Context, ptr %57, i32 0, i32 2
  %59 = getelementptr inbounds [64 x i8], ptr %58, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 8 %59, i8 0, i64 64, i1 false)
  ret void

60:                                               ; preds = %159, %150, %144, %129, %122, %93, %81, %70, %25, %11
  br label %6

61:                                               ; preds = %120, %116, %114, %110
  store i32 199438311, ptr %4, align 4
  call void asm sideeffect "", ""()
  %62 = xor i32 %3, 1688530437
  %63 = and i32 %3, %62
  %64 = or i32 %3, %62
  %65 = xor i32 %3, %62
  %66 = sub i32 %64, %65
  %67 = sub i32 %66, %63
  %68 = mul i32 %67, 109
  %69 = icmp sgt i32 %68, 0
  br i1 %69, label %136, label %6

70:                                               ; preds = %110
  %71 = load i32, ptr %4, align 4
  %72 = xor i32 %71, -1408046451
  store i32 %72, ptr %4, align 4
  %73 = xor i32 %3, -2128812235
  %74 = and i32 %3, %73
  %75 = or i32 %3, %73
  %76 = xor i32 %3, %73
  %77 = sub i32 %75, %76
  %78 = sub i32 %77, %74
  %79 = mul i32 %78, 37
  %80 = icmp sle i32 %79, 0
  br i1 %80, label %60, label %144

81:                                               ; preds = %120
  %82 = load i32, ptr %4, align 4
  %83 = xor i32 %82, -645301877
  store i32 %83, ptr %4, align 4
  %84 = xor i32 %3, 430876509
  %85 = and i32 %3, %84
  %86 = or i32 %3, %84
  %87 = xor i32 %3, %84
  %88 = add i32 %85, %86
  %89 = sub i32 %88, %3
  %90 = sub i32 %89, %84
  %91 = mul i32 %90, 235
  %92 = icmp slt i32 %91, 0
  br i1 %92, label %150, label %60

93:                                               ; preds = %118
  %94 = load i32, ptr %4, align 4
  %95 = xor i32 %94, 2084662404
  store i32 %95, ptr %4, align 4
  %96 = xor i32 %3, -412423113
  %97 = and i32 %3, %96
  %98 = or i32 %3, %96
  %99 = xor i32 %3, %96
  %100 = mul i32 %98, 2
  %101 = sub i32 %100, %99
  %102 = sub i32 %101, %3
  %103 = sub i32 %102, %96
  %104 = mul i32 %103, 171
  %105 = icmp ugt i32 %104, 0
  br i1 %105, label %159, label %60

106:                                              ; preds = %6
  %107 = icmp slt i32 %9, 510561044
  br i1 %107, label %110, label %112

108:                                              ; preds = %6
  %109 = icmp slt i32 %9, 1598183446
  br i1 %109, label %116, label %118

110:                                              ; preds = %106
  %111 = icmp eq i32 %9, 54681492
  br i1 %111, label %70, label %61

112:                                              ; preds = %106
  %113 = icmp eq i32 %9, 510561044
  br i1 %113, label %11, label %114

114:                                              ; preds = %112
  %115 = icmp eq i32 %9, 1272149167
  br i1 %115, label %25, label %61

116:                                              ; preds = %108
  %117 = icmp eq i32 %9, 1312678045
  br i1 %117, label %34, label %61

118:                                              ; preds = %108
  %119 = icmp eq i32 %9, 1598183446
  br i1 %119, label %93, label %120

120:                                              ; preds = %118
  %121 = icmp eq i32 %9, 1778137674
  br i1 %121, label %81, label %61

122:                                              ; preds = %11
  %123 = load i64, ptr %2, align 8
  %124 = ptrtoint ptr %0 to i64
  %125 = sub i64 %123, %123
  %126 = and i64 %125, %124
  %127 = mul i64 %126, %123
  %128 = xor i64 %127, %123
  store i64 %128, ptr %2, align 8
  br label %60

129:                                              ; preds = %25
  %130 = load i64, ptr %2, align 8
  %131 = ptrtoint ptr %0 to i64
  %132 = sub i64 %131, %131
  %133 = sub i64 %132, %130
  %134 = xor i64 %133, %131
  %135 = mul i64 %134, %130
  store i64 %135, ptr %2, align 8
  br label %60

136:                                              ; preds = %61
  %137 = load i64, ptr %2, align 8
  %138 = ptrtoint ptr %0 to i64
  %139 = or i64 %138, %138
  %140 = xor i64 %139, %138
  %141 = mul i64 %140, %137
  %142 = add i64 %141, %137
  %143 = mul i64 %142, %137
  store i64 %143, ptr %2, align 8
  br label %6

144:                                              ; preds = %70
  %145 = load i64, ptr %2, align 8
  %146 = ptrtoint ptr %0 to i64
  %147 = mul i64 %146, %145
  %148 = xor i64 %147, %145
  %149 = sub i64 %148, %146
  store i64 %149, ptr %2, align 8
  br label %60

150:                                              ; preds = %81
  %151 = load i64, ptr %2, align 8
  %152 = ptrtoint ptr %0 to i64
  %153 = xor i64 %151, %151
  %154 = sub i64 %153, %151
  %155 = add i64 %154, %151
  %156 = xor i64 %155, %152
  %157 = and i64 %156, %152
  %158 = sub i64 %157, %151
  store i64 %158, ptr %2, align 8
  br label %60

159:                                              ; preds = %93
  %160 = load i64, ptr %2, align 8
  %161 = ptrtoint ptr %0 to i64
  %162 = sub i64 %160, %161
  %163 = xor i64 %162, %161
  %164 = xor i64 %163, %161
  %165 = sub i64 %164, %160
  store i64 %165, ptr %2, align 8
  br label %60
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_context_enable_trace(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  store i32 -709849180, ptr %4, align 4
  br label %7

7:                                                ; preds = %160, %53, %52, %2
  %8 = load i32, ptr %4, align 4
  %9 = sub i32 %8, 1845550026
  %10 = mul i32 %9, 61856881
  switch i32 %10, label %53 [
    i32 1126415162, label %11
    i32 1256244593, label %23
    i32 194521383, label %34
    i32 1677421748, label %51
    i32 918216354, label %72
    i32 2104622120, label %93
    i32 1790857598, label %111
    i32 209215548, label %122
  ]

11:                                               ; preds = %7
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %12 = load ptr, ptr %5, align 8
  %13 = icmp eq ptr %12, null
  %14 = select i1 %13, i32 -474426165, i32 2126210785
  store i32 %14, ptr %4, align 4
  %15 = xor i32 %1, -1036375809
  %16 = and i32 %1, %15
  %17 = or i32 %1, %15
  %18 = xor i32 %1, %15
  %19 = sub i32 %17, %18
  %20 = sub i32 %19, %16
  %21 = mul i32 %20, 96
  %22 = icmp sle i32 %21, 0
  br i1 %22, label %52, label %134

23:                                               ; preds = %7
  store i32 1048559038, ptr %4, align 4
  %24 = xor i32 %1, -1613381953
  %25 = and i32 %1, %24
  %26 = or i32 %1, %24
  %27 = xor i32 %1, %24
  %28 = mul i32 %26, 2
  %29 = sub i32 %28, %27
  %30 = sub i32 %29, %1
  %31 = sub i32 %30, %24
  %32 = mul i32 %31, 121
  %33 = icmp slt i32 %32, 0
  br i1 %33, label %144, label %52

34:                                               ; preds = %7
  %35 = load i32, ptr %6, align 4
  %36 = icmp ne i32 %35, 0
  %37 = zext i1 %36 to i64
  %38 = select i1 %36, i32 1, i32 0
  %39 = load ptr, ptr %5, align 8
  %40 = getelementptr inbounds nuw %struct.MD5Context, ptr %39, i32 0, i32 5
  store i32 %38, ptr %40, align 8
  store i32 1048559038, ptr %4, align 4
  %41 = xor i32 %1, 1531880917
  %42 = and i32 %1, %41
  %43 = or i32 %1, %41
  %44 = xor i32 %1, %41
  %45 = add i32 %1, %41
  %46 = sub i32 %45, %44
  %47 = mul i32 %42, 2
  %48 = sub i32 %46, %47
  %49 = mul i32 %48, 252
  %50 = icmp sgt i32 %49, 0
  br i1 %50, label %152, label %52

51:                                               ; preds = %7
  ret void

52:                                               ; preds = %195, %187, %178, %169, %152, %144, %134, %122, %111, %93, %72, %34, %23, %11
  br label %7

53:                                               ; preds = %7
  store i32 -709849180, ptr %4, align 4
  call void asm sideeffect "", ""()
  %54 = xor i32 %1, 1775934275
  %55 = and i32 %1, %54
  %56 = or i32 %1, %54
  %57 = xor i32 %1, %54
  %58 = add i32 %55, %56
  %59 = sub i32 %58, %1
  %60 = sub i32 %59, %54
  %61 = mul i32 %60, 197
  %62 = xor i32 %1, -1264805893
  %63 = and i32 %1, %62
  %64 = or i32 %1, %62
  %65 = xor i32 %1, %62
  %66 = add i32 %1, %62
  %67 = sub i32 %66, %65
  %68 = mul i32 %63, 2
  %69 = sub i32 %67, %68
  %70 = mul i32 %69, 161
  %71 = icmp eq i32 %61, %70
  br i1 %71, label %7, label %160

72:                                               ; preds = %7
  %73 = load i32, ptr %4, align 4
  %74 = xor i32 %73, -2032376677
  store i32 %74, ptr %4, align 4
  %75 = xor i32 %1, 944577815
  %76 = and i32 %1, %75
  %77 = or i32 %1, %75
  %78 = xor i32 %1, %75
  %79 = add i32 %1, %75
  %80 = sub i32 %79, %78
  %81 = mul i32 %76, 2
  %82 = sub i32 %80, %81
  %83 = mul i32 %82, 2
  %84 = xor i32 %1, -1150298737
  %85 = and i32 %1, %84
  %86 = or i32 %1, %84
  %87 = xor i32 %1, %84
  %88 = add i32 %85, %86
  %89 = sub i32 %88, %1
  %90 = sub i32 %89, %84
  %91 = mul i32 %90, 50
  %92 = icmp ne i32 %83, %91
  br i1 %92, label %169, label %52

93:                                               ; preds = %7
  %94 = load i32, ptr %4, align 4
  %95 = xor i32 %94, -1812583266
  store i32 %95, ptr %4, align 4
  %96 = xor i32 %1, 1523050605
  %97 = and i32 %1, %96
  %98 = or i32 %1, %96
  %99 = xor i32 %1, %96
  %100 = sub i32 %98, %99
  %101 = sub i32 %100, %97
  %102 = mul i32 %101, 88
  %103 = xor i32 %1, -1139562145
  %104 = and i32 %1, %103
  %105 = or i32 %1, %103
  %106 = xor i32 %1, %103
  %107 = sub i32 %105, %106
  %108 = sub i32 %107, %104
  %109 = mul i32 %108, 214
  %110 = icmp ne i32 %102, %109
  br i1 %110, label %178, label %52

111:                                              ; preds = %7
  %112 = load i32, ptr %4, align 4
  %113 = xor i32 %112, 13075423
  store i32 %113, ptr %4, align 4
  %114 = xor i32 %1, -1669667005
  %115 = and i32 %1, %114
  %116 = or i32 %1, %114
  %117 = xor i32 %1, %114
  %118 = sub i32 %116, %117
  %119 = sub i32 %118, %115
  %120 = mul i32 %119, 124
  %121 = icmp sle i32 %120, 0
  br i1 %121, label %52, label %187

122:                                              ; preds = %7
  %123 = load i32, ptr %4, align 4
  %124 = xor i32 %123, -1142586267
  store i32 %124, ptr %4, align 4
  %125 = xor i32 %1, -1061838965
  %126 = and i32 %1, %125
  %127 = or i32 %1, %125
  %128 = xor i32 %1, %125
  %129 = add i32 %126, %127
  %130 = sub i32 %129, %1
  %131 = sub i32 %130, %125
  %132 = mul i32 %131, 64
  %133 = icmp sle i32 %132, 0
  br i1 %133, label %52, label %195

134:                                              ; preds = %11
  %135 = load i64, ptr %3, align 8
  %136 = ptrtoint ptr %0 to i64
  %137 = zext i32 %1 to i64
  %138 = xor i64 %137, %137
  %139 = sub i64 %138, %136
  %140 = or i64 %139, %137
  %141 = xor i64 %140, %136
  %142 = or i64 %141, %136
  %143 = mul i64 %142, %137
  store i64 %143, ptr %3, align 8
  br label %52

144:                                              ; preds = %23
  %145 = load i64, ptr %3, align 8
  %146 = ptrtoint ptr %0 to i64
  %147 = zext i32 %1 to i64
  %148 = and i64 %146, %147
  %149 = add i64 %148, %147
  %150 = and i64 %149, %147
  %151 = add i64 %150, %147
  store i64 %151, ptr %3, align 8
  br label %52

152:                                              ; preds = %34
  %153 = load i64, ptr %3, align 8
  %154 = ptrtoint ptr %0 to i64
  %155 = zext i32 %1 to i64
  %156 = xor i64 %155, %155
  %157 = sub i64 %156, %153
  %158 = xor i64 %157, %153
  %159 = sub i64 %158, %154
  store i64 %159, ptr %3, align 8
  br label %52

160:                                              ; preds = %53
  %161 = load i64, ptr %3, align 8
  %162 = ptrtoint ptr %0 to i64
  %163 = zext i32 %1 to i64
  %164 = or i64 %161, %161
  %165 = or i64 %164, %163
  %166 = xor i64 %165, %161
  %167 = and i64 %166, %163
  %168 = xor i64 %167, %162
  store i64 %168, ptr %3, align 8
  br label %7

169:                                              ; preds = %72
  %170 = load i64, ptr %3, align 8
  %171 = ptrtoint ptr %0 to i64
  %172 = zext i32 %1 to i64
  %173 = add i64 %171, %171
  %174 = sub i64 %173, %170
  %175 = and i64 %174, %170
  %176 = mul i64 %175, %171
  %177 = sub i64 %176, %171
  store i64 %177, ptr %3, align 8
  br label %52

178:                                              ; preds = %93
  %179 = load i64, ptr %3, align 8
  %180 = ptrtoint ptr %0 to i64
  %181 = zext i32 %1 to i64
  %182 = sub i64 %179, %180
  %183 = sub i64 %182, %180
  %184 = mul i64 %183, %179
  %185 = add i64 %184, %180
  %186 = add i64 %185, %179
  store i64 %186, ptr %3, align 8
  br label %52

187:                                              ; preds = %111
  %188 = load i64, ptr %3, align 8
  %189 = ptrtoint ptr %0 to i64
  %190 = zext i32 %1 to i64
  %191 = or i64 %189, %189
  %192 = add i64 %191, %188
  %193 = and i64 %192, %188
  %194 = sub i64 %193, %189
  store i64 %194, ptr %3, align 8
  br label %52

195:                                              ; preds = %122
  %196 = load i64, ptr %3, align 8
  %197 = ptrtoint ptr %0 to i64
  %198 = zext i32 %1 to i64
  %199 = or i64 %197, %198
  %200 = or i64 %199, %198
  %201 = sub i64 %200, %197
  %202 = mul i64 %201, %197
  %203 = and i64 %202, %197
  %204 = or i64 %203, %198
  store i64 %204, ptr %3, align 8
  br label %52
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_update_bytes(ptr noundef %0, ptr noundef %1, i64 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i64, align 8
  %10 = alloca i64, align 8
  %11 = alloca i64, align 8
  %12 = alloca i64, align 8
  store i32 72218855, ptr %5, align 4
  br label %13

13:                                               ; preds = %794, %390, %389, %3
  %14 = load i32, ptr %5, align 4
  %15 = sub i32 %14, 1698196854
  %16 = mul i32 %15, 2096829017
  %17 = icmp slt i32 %16, 1373186609
  br i1 %17, label %520, label %522

18:                                               ; preds = %560
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  store i64 %2, ptr %9, align 8
  store i64 0, ptr %10, align 8
  %19 = load ptr, ptr %7, align 8
  %20 = icmp eq ptr %19, null
  %21 = select i1 %20, i32 442668537, i32 -1514298908
  store i32 %21, ptr %5, align 4
  %22 = xor i64 %2, 7281209664105613895
  %23 = and i64 %2, %22
  %24 = or i64 %2, %22
  %25 = xor i64 %2, %22
  %26 = sub i64 %24, %25
  %27 = sub i64 %26, %23
  %28 = mul i64 %27, 124
  %29 = icmp slt i64 %28, 0
  br i1 %29, label %608, label %389

30:                                               ; preds = %550
  call void @die_message(ptr noundef @.str.66)
  store i32 -1514298908, ptr %5, align 4
  %31 = xor i64 %2, 2989068419918894491
  %32 = and i64 %2, %31
  %33 = or i64 %2, %31
  %34 = xor i64 %2, %31
  %35 = sub i64 %33, %34
  %36 = sub i64 %35, %32
  %37 = mul i64 %36, 133
  %38 = icmp sgt i64 %37, 0
  br i1 %38, label %618, label %389

39:                                               ; preds = %604
  %40 = load ptr, ptr %8, align 8
  %41 = icmp eq ptr %40, null
  %42 = select i1 %41, i32 741370622, i32 681128288
  store i32 %42, ptr %5, align 4
  %43 = xor i64 %2, 7508252342845456091
  %44 = and i64 %2, %43
  %45 = or i64 %2, %43
  %46 = xor i64 %2, %43
  %47 = add i64 %2, %43
  %48 = sub i64 %47, %46
  %49 = mul i64 %44, 2
  %50 = sub i64 %48, %49
  %51 = mul i64 %50, 9
  %52 = icmp ne i64 %51, 0
  br i1 %52, label %628, label %389

53:                                               ; preds = %538
  %54 = load i64, ptr %9, align 8
  %55 = icmp ne i64 %54, 0
  %56 = select i1 %55, i32 -1447765874, i32 681128288
  store i32 %56, ptr %5, align 4
  %57 = xor i64 %2, 6287052009071897925
  %58 = and i64 %2, %57
  %59 = or i64 %2, %57
  %60 = xor i64 %2, %57
  %61 = add i64 %2, %57
  %62 = sub i64 %61, %60
  %63 = mul i64 %58, 2
  %64 = sub i64 %62, %63
  %65 = mul i64 %64, 165
  %66 = xor i64 %2, -6802168483138967253
  %67 = and i64 %2, %66
  %68 = or i64 %2, %66
  %69 = xor i64 %2, %66
  %70 = add i64 %67, %68
  %71 = sub i64 %70, %2
  %72 = sub i64 %71, %66
  %73 = mul i64 %72, 236
  %74 = icmp ne i64 %65, %73
  br i1 %74, label %635, label %389

75:                                               ; preds = %558
  call void @die_message(ptr noundef @.str.67)
  store i32 681128288, ptr %5, align 4
  %76 = xor i64 %2, 4555491470308295573
  %77 = and i64 %2, %76
  %78 = or i64 %2, %76
  %79 = xor i64 %2, %76
  %80 = add i64 %2, %76
  %81 = sub i64 %80, %79
  %82 = mul i64 %77, 2
  %83 = sub i64 %81, %82
  %84 = mul i64 %83, 250
  %85 = icmp sgt i64 %84, 0
  br i1 %85, label %642, label %389

86:                                               ; preds = %552
  %87 = load ptr, ptr %7, align 8
  %88 = getelementptr inbounds nuw %struct.MD5Context, ptr %87, i32 0, i32 6
  %89 = load i32, ptr %88, align 4
  %90 = icmp ne i32 %89, 0
  %91 = select i1 %90, i32 1766669470, i32 252949727
  store i32 %91, ptr %5, align 4
  %92 = xor i64 %2, -7243977764148160121
  %93 = and i64 %2, %92
  %94 = or i64 %2, %92
  %95 = xor i64 %2, %92
  %96 = mul i64 %94, 2
  %97 = sub i64 %96, %95
  %98 = sub i64 %97, %2
  %99 = sub i64 %98, %92
  %100 = mul i64 %99, 112
  %101 = xor i64 %2, 2114099924219635973
  %102 = and i64 %2, %101
  %103 = or i64 %2, %101
  %104 = xor i64 %2, %101
  %105 = add i64 %102, %103
  %106 = sub i64 %105, %2
  %107 = sub i64 %106, %101
  %108 = mul i64 %107, 129
  %109 = icmp ne i64 %100, %108
  br i1 %109, label %650, label %389

110:                                              ; preds = %586
  call void @die_message(ptr noundef @.str.68)
  store i32 252949727, ptr %5, align 4
  %111 = xor i64 %2, -8232815102880925827
  %112 = and i64 %2, %111
  %113 = or i64 %2, %111
  %114 = xor i64 %2, %111
  %115 = sub i64 %113, %114
  %116 = sub i64 %115, %112
  %117 = mul i64 %116, 255
  %118 = icmp uge i64 %117, 0
  br i1 %118, label %389, label %658

119:                                              ; preds = %580
  %120 = load i64, ptr %9, align 8
  %121 = load ptr, ptr %7, align 8
  %122 = getelementptr inbounds nuw %struct.MD5Context, ptr %121, i32 0, i32 1
  %123 = load i64, ptr %122, align 8
  %124 = xor i64 %123, %120
  %125 = and i64 %123, %120
  %126 = add i64 %125, %125
  %127 = add i64 %124, %126
  store i64 %127, ptr %122, align 8
  %128 = load ptr, ptr %7, align 8
  %129 = getelementptr inbounds nuw %struct.MD5Context, ptr %128, i32 0, i32 3
  %130 = load i64, ptr %129, align 8
  %131 = icmp ugt i64 %130, 0
  %132 = select i1 %131, i32 63746367, i32 1050463855
  store i32 %132, ptr %5, align 4
  %133 = xor i64 %2, -5279288177537762561
  %134 = and i64 %2, %133
  %135 = or i64 %2, %133
  %136 = xor i64 %2, %133
  %137 = mul i64 %135, 2
  %138 = sub i64 %137, %136
  %139 = sub i64 %138, %2
  %140 = sub i64 %139, %133
  %141 = mul i64 %140, 13
  %142 = icmp slt i64 %141, 0
  br i1 %142, label %665, label %389

143:                                              ; preds = %592
  %144 = load ptr, ptr %7, align 8
  %145 = getelementptr inbounds nuw %struct.MD5Context, ptr %144, i32 0, i32 3
  %146 = load i64, ptr %145, align 8
  %147 = add i64 %146, 1
  %148 = mul i64 64, %147
  %149 = mul i64 %146, 65
  %150 = sub i64 %148, %149
  store i64 %150, ptr %11, align 8
  %151 = load i64, ptr %9, align 8
  %152 = load i64, ptr %11, align 8
  %153 = icmp ult i64 %151, %152
  %154 = select i1 %153, i32 -743612944, i32 -1636444357
  store i32 %154, ptr %5, align 4
  %155 = xor i64 %2, -2030548197936410767
  %156 = and i64 %2, %155
  %157 = or i64 %2, %155
  %158 = xor i64 %2, %155
  %159 = sub i64 %157, %158
  %160 = sub i64 %159, %156
  %161 = mul i64 %160, 192
  %162 = icmp sle i64 %161, 0
  br i1 %162, label %389, label %674

163:                                              ; preds = %606
  %164 = load i64, ptr %9, align 8
  store i64 %164, ptr %6, align 8
  store i32 -1665722722, ptr %5, align 4
  %165 = xor i64 %2, 1893054352195351689
  %166 = and i64 %2, %165
  %167 = or i64 %2, %165
  %168 = xor i64 %2, %165
  %169 = add i64 %2, %165
  %170 = sub i64 %169, %168
  %171 = mul i64 %166, 2
  %172 = sub i64 %170, %171
  %173 = mul i64 %172, 59
  %174 = icmp sgt i64 %173, 0
  br i1 %174, label %684, label %389

175:                                              ; preds = %578
  %176 = load i64, ptr %11, align 8
  store i64 %176, ptr %6, align 8
  store i32 -1665722722, ptr %5, align 4
  %177 = xor i64 %2, -9170052729289279165
  %178 = and i64 %2, %177
  %179 = or i64 %2, %177
  %180 = xor i64 %2, %177
  %181 = add i64 %178, %179
  %182 = sub i64 %181, %2
  %183 = sub i64 %182, %177
  %184 = mul i64 %183, 183
  %185 = icmp eq i64 %184, 0
  br i1 %185, label %389, label %694

186:                                              ; preds = %600
  %187 = load i64, ptr %6, align 8
  store i64 %187, ptr %12, align 8
  %188 = load i64, ptr %12, align 8
  %189 = icmp ugt i64 %188, 0
  %190 = select i1 %189, i32 -1271176376, i32 -952497654
  store i32 %190, ptr %5, align 4
  %191 = xor i64 %2, -665392419678597333
  %192 = and i64 %2, %191
  %193 = or i64 %2, %191
  %194 = xor i64 %2, %191
  %195 = sub i64 %193, %194
  %196 = sub i64 %195, %192
  %197 = mul i64 %196, 236
  %198 = icmp slt i64 %197, 0
  br i1 %198, label %704, label %389

199:                                              ; preds = %598
  %200 = load ptr, ptr %7, align 8
  %201 = getelementptr inbounds nuw %struct.MD5Context, ptr %200, i32 0, i32 2
  %202 = getelementptr inbounds [64 x i8], ptr %201, i64 0, i64 0
  %203 = load ptr, ptr %7, align 8
  %204 = getelementptr inbounds nuw %struct.MD5Context, ptr %203, i32 0, i32 3
  %205 = load i64, ptr %204, align 8
  %206 = getelementptr inbounds nuw i8, ptr %202, i64 %205
  %207 = load ptr, ptr %8, align 8
  %208 = load i64, ptr %12, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %206, ptr align 1 %207, i64 %208, i1 false)
  %209 = load i64, ptr %12, align 8
  %210 = load ptr, ptr %7, align 8
  %211 = getelementptr inbounds nuw %struct.MD5Context, ptr %210, i32 0, i32 3
  %212 = load i64, ptr %211, align 8
  %213 = or i64 %212, %209
  %214 = and i64 %212, %209
  %215 = add i64 %213, %214
  store i64 %215, ptr %211, align 8
  %216 = load i64, ptr %12, align 8
  %217 = load i64, ptr %10, align 8
  %218 = xor i64 %217, %216
  %219 = and i64 %217, %216
  %220 = add i64 %219, %219
  %221 = add i64 %218, %220
  store i64 %221, ptr %10, align 8
  %222 = load i64, ptr %12, align 8
  %223 = load i64, ptr %9, align 8
  %224 = xor i64 %223, %222
  %225 = xor i64 %223, -1
  %226 = and i64 %225, %222
  %227 = add i64 %226, %226
  %228 = sub i64 %224, %227
  store i64 %228, ptr %9, align 8
  store i32 -952497654, ptr %5, align 4
  %229 = xor i64 %2, 1358891214230655761
  %230 = and i64 %2, %229
  %231 = or i64 %2, %229
  %232 = xor i64 %2, %229
  %233 = add i64 %230, %231
  %234 = sub i64 %233, %2
  %235 = sub i64 %234, %229
  %236 = mul i64 %235, 85
  %237 = xor i64 %2, 5866298809708735381
  %238 = and i64 %2, %237
  %239 = or i64 %2, %237
  %240 = xor i64 %2, %237
  %241 = add i64 %238, %239
  %242 = sub i64 %241, %2
  %243 = sub i64 %242, %237
  %244 = mul i64 %243, 159
  %245 = icmp ne i64 %236, %244
  br i1 %245, label %712, label %389

246:                                              ; preds = %594
  %247 = load ptr, ptr %7, align 8
  %248 = getelementptr inbounds nuw %struct.MD5Context, ptr %247, i32 0, i32 3
  %249 = load i64, ptr %248, align 8
  %250 = icmp eq i64 %249, 64
  %251 = select i1 %250, i32 -746998202, i32 1581529853
  store i32 %251, ptr %5, align 4
  %252 = xor i64 %2, -8789768515910110223
  %253 = and i64 %2, %252
  %254 = or i64 %2, %252
  %255 = xor i64 %2, %252
  %256 = sub i64 %254, %255
  %257 = sub i64 %256, %253
  %258 = mul i64 %257, 46
  %259 = xor i64 %2, -4138211635962842323
  %260 = and i64 %2, %259
  %261 = or i64 %2, %259
  %262 = xor i64 %2, %259
  %263 = sub i64 %261, %262
  %264 = sub i64 %263, %260
  %265 = mul i64 %264, 10
  %266 = icmp eq i64 %258, %265
  br i1 %266, label %389, label %722

267:                                              ; preds = %536
  %268 = load ptr, ptr %7, align 8
  %269 = load ptr, ptr %7, align 8
  %270 = getelementptr inbounds nuw %struct.MD5Context, ptr %269, i32 0, i32 2
  %271 = getelementptr inbounds [64 x i8], ptr %270, i64 0, i64 0
  call void @md5_transform_block(ptr noundef %268, ptr noundef %271)
  %272 = load ptr, ptr %7, align 8
  %273 = getelementptr inbounds nuw %struct.MD5Context, ptr %272, i32 0, i32 3
  store i64 0, ptr %273, align 8
  %274 = load ptr, ptr %7, align 8
  %275 = getelementptr inbounds nuw %struct.MD5Context, ptr %274, i32 0, i32 2
  %276 = getelementptr inbounds [64 x i8], ptr %275, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 8 %276, i8 0, i64 64, i1 false)
  store i32 1581529853, ptr %5, align 4
  %277 = xor i64 %2, -4672587545182029273
  %278 = and i64 %2, %277
  %279 = or i64 %2, %277
  %280 = xor i64 %2, %277
  %281 = add i64 %2, %277
  %282 = sub i64 %281, %280
  %283 = mul i64 %278, 2
  %284 = sub i64 %282, %283
  %285 = mul i64 %284, 90
  %286 = icmp slt i64 %285, 1
  br i1 %286, label %389, label %731

287:                                              ; preds = %564
  store i32 1050463855, ptr %5, align 4
  %288 = xor i64 %2, -3916946361997121841
  %289 = and i64 %2, %288
  %290 = or i64 %2, %288
  %291 = xor i64 %2, %288
  %292 = sub i64 %290, %291
  %293 = sub i64 %292, %289
  %294 = mul i64 %293, 136
  %295 = icmp sle i64 %294, 0
  br i1 %295, label %389, label %740

296:                                              ; preds = %576
  store i32 279996247, ptr %5, align 4
  %297 = xor i64 %2, -831132347615077261
  %298 = and i64 %2, %297
  %299 = or i64 %2, %297
  %300 = xor i64 %2, %297
  %301 = add i64 %298, %299
  %302 = sub i64 %301, %2
  %303 = sub i64 %302, %297
  %304 = mul i64 %303, 20
  %305 = xor i64 %2, 4576705171744818427
  %306 = and i64 %2, %305
  %307 = or i64 %2, %305
  %308 = xor i64 %2, %305
  %309 = mul i64 %307, 2
  %310 = sub i64 %309, %308
  %311 = sub i64 %310, %2
  %312 = sub i64 %311, %305
  %313 = mul i64 %312, 63
  %314 = icmp eq i64 %304, %313
  br i1 %314, label %389, label %749

315:                                              ; preds = %534
  %316 = load i64, ptr %9, align 8
  %317 = icmp uge i64 %316, 64
  %318 = select i1 %317, i32 348472120, i32 351146353
  store i32 %318, ptr %5, align 4
  %319 = xor i64 %2, -5957059029052595327
  %320 = and i64 %2, %319
  %321 = or i64 %2, %319
  %322 = xor i64 %2, %319
  %323 = add i64 %320, %321
  %324 = sub i64 %323, %2
  %325 = sub i64 %324, %319
  %326 = mul i64 %325, 13
  %327 = icmp sle i64 %326, 0
  br i1 %327, label %389, label %759

328:                                              ; preds = %602
  %329 = load ptr, ptr %7, align 8
  %330 = load ptr, ptr %8, align 8
  %331 = load i64, ptr %10, align 8
  %332 = getelementptr inbounds nuw i8, ptr %330, i64 %331
  call void @md5_transform_block(ptr noundef %329, ptr noundef %332)
  %333 = load i64, ptr %10, align 8
  %334 = xor i64 %333, 64
  %335 = and i64 %333, 64
  %336 = add i64 %335, %335
  %337 = add i64 %334, %336
  store i64 %337, ptr %10, align 8
  %338 = load i64, ptr %9, align 8
  %339 = add i64 %338, 1
  %340 = mul i64 %338, 65
  %341 = mul i64 64, %339
  %342 = sub i64 %340, %341
  store i64 %342, ptr %9, align 8
  store i32 279996247, ptr %5, align 4
  %343 = xor i64 %2, 1189435294548816543
  %344 = and i64 %2, %343
  %345 = or i64 %2, %343
  %346 = xor i64 %2, %343
  %347 = add i64 %2, %343
  %348 = sub i64 %347, %346
  %349 = mul i64 %344, 2
  %350 = sub i64 %348, %349
  %351 = mul i64 %350, 20
  %352 = icmp uge i64 %351, 0
  br i1 %352, label %389, label %768

353:                                              ; preds = %562
  %354 = load i64, ptr %9, align 8
  %355 = icmp ugt i64 %354, 0
  %356 = select i1 %355, i32 2034455531, i32 -359148217
  store i32 %356, ptr %5, align 4
  %357 = xor i64 %2, -4685586021933565933
  %358 = and i64 %2, %357
  %359 = or i64 %2, %357
  %360 = xor i64 %2, %357
  %361 = mul i64 %359, 2
  %362 = sub i64 %361, %360
  %363 = sub i64 %362, %2
  %364 = sub i64 %363, %357
  %365 = mul i64 %364, 29
  %366 = icmp uge i64 %365, 0
  br i1 %366, label %389, label %777

367:                                              ; preds = %582
  %368 = load ptr, ptr %7, align 8
  %369 = getelementptr inbounds nuw %struct.MD5Context, ptr %368, i32 0, i32 2
  %370 = getelementptr inbounds [64 x i8], ptr %369, i64 0, i64 0
  %371 = load ptr, ptr %8, align 8
  %372 = load i64, ptr %10, align 8
  %373 = getelementptr inbounds nuw i8, ptr %371, i64 %372
  %374 = load i64, ptr %9, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %370, ptr align 1 %373, i64 %374, i1 false)
  %375 = load i64, ptr %9, align 8
  %376 = load ptr, ptr %7, align 8
  %377 = getelementptr inbounds nuw %struct.MD5Context, ptr %376, i32 0, i32 3
  store i64 %375, ptr %377, align 8
  store i32 -359148217, ptr %5, align 4
  %378 = xor i64 %2, 2840281700909460969
  %379 = and i64 %2, %378
  %380 = or i64 %2, %378
  %381 = xor i64 %2, %378
  %382 = add i64 %2, %378
  %383 = sub i64 %382, %381
  %384 = mul i64 %379, 2
  %385 = sub i64 %383, %384
  %386 = mul i64 %385, 153
  %387 = icmp slt i64 %386, 0
  br i1 %387, label %787, label %389

388:                                              ; preds = %544
  ret void

389:                                              ; preds = %859, %850, %843, %836, %826, %818, %809, %801, %787, %777, %768, %759, %749, %740, %731, %722, %712, %704, %694, %684, %674, %665, %658, %650, %642, %635, %628, %618, %608, %508, %497, %478, %466, %447, %426, %413, %401, %367, %353, %328, %315, %296, %287, %267, %246, %199, %186, %175, %163, %143, %119, %110, %86, %75, %53, %39, %30, %18
  br label %13

390:                                              ; preds = %606, %604, %598, %596, %586, %584, %578, %574, %564, %562, %556, %554, %544, %542, %536, %532
  store i32 72218855, ptr %5, align 4
  call void asm sideeffect "", ""()
  %391 = xor i64 %2, 5058601139146569409
  %392 = and i64 %2, %391
  %393 = or i64 %2, %391
  %394 = xor i64 %2, %391
  %395 = add i64 %2, %391
  %396 = sub i64 %395, %394
  %397 = mul i64 %392, 2
  %398 = sub i64 %396, %397
  %399 = mul i64 %398, 2
  %400 = icmp ne i64 %399, 0
  br i1 %400, label %794, label %13

401:                                              ; preds = %542
  %402 = load i32, ptr %5, align 4
  %403 = xor i32 %402, 346052291
  store i32 %403, ptr %5, align 4
  %404 = xor i64 %2, -6706745451176548651
  %405 = and i64 %2, %404
  %406 = or i64 %2, %404
  %407 = xor i64 %2, %404
  %408 = add i64 %405, %406
  %409 = sub i64 %408, %2
  %410 = sub i64 %409, %404
  %411 = mul i64 %410, 128
  %412 = icmp ne i64 %411, 0
  br i1 %412, label %801, label %389

413:                                              ; preds = %584
  %414 = load i32, ptr %5, align 4
  %415 = xor i32 %414, 239316686
  store i32 %415, ptr %5, align 4
  %416 = xor i64 %2, 8807498039243320579
  %417 = and i64 %2, %416
  %418 = or i64 %2, %416
  %419 = xor i64 %2, %416
  %420 = mul i64 %418, 2
  %421 = sub i64 %420, %419
  %422 = sub i64 %421, %2
  %423 = sub i64 %422, %416
  %424 = mul i64 %423, 207
  %425 = icmp sle i64 %424, 0
  br i1 %425, label %389, label %809

426:                                              ; preds = %596
  %427 = load i32, ptr %5, align 4
  %428 = xor i32 %427, -1512757557
  store i32 %428, ptr %5, align 4
  %429 = xor i64 %2, -5461648019248853539
  %430 = and i64 %2, %429
  %431 = or i64 %2, %429
  %432 = xor i64 %2, %429
  %433 = add i64 %430, %431
  %434 = sub i64 %433, %2
  %435 = sub i64 %434, %429
  %436 = mul i64 %435, 131
  %437 = xor i64 %2, -6791381368166395585
  %438 = and i64 %2, %437
  %439 = or i64 %2, %437
  %440 = xor i64 %2, %437
  %441 = mul i64 %439, 2
  %442 = sub i64 %441, %440
  %443 = sub i64 %442, %2
  %444 = sub i64 %443, %437
  %445 = mul i64 %444, 52
  %446 = icmp eq i64 %436, %445
  br i1 %446, label %389, label %818

447:                                              ; preds = %532
  %448 = load i32, ptr %5, align 4
  %449 = xor i32 %448, -485966798
  store i32 %449, ptr %5, align 4
  %450 = xor i64 %2, -3067348708976215781
  %451 = and i64 %2, %450
  %452 = or i64 %2, %450
  %453 = xor i64 %2, %450
  %454 = add i64 %451, %452
  %455 = sub i64 %454, %2
  %456 = sub i64 %455, %450
  %457 = mul i64 %456, 246
  %458 = xor i64 %2, -8287977401594866865
  %459 = and i64 %2, %458
  %460 = or i64 %2, %458
  %461 = xor i64 %2, %458
  %462 = sub i64 %460, %461
  %463 = sub i64 %462, %459
  %464 = mul i64 %463, 148
  %465 = icmp eq i64 %457, %464
  br i1 %465, label %389, label %826

466:                                              ; preds = %554
  %467 = load i32, ptr %5, align 4
  %468 = xor i32 %467, -2009356483
  store i32 %468, ptr %5, align 4
  %469 = xor i64 %2, 7985217381984517201
  %470 = and i64 %2, %469
  %471 = or i64 %2, %469
  %472 = xor i64 %2, %469
  %473 = add i64 %470, %471
  %474 = sub i64 %473, %2
  %475 = sub i64 %474, %469
  %476 = mul i64 %475, 161
  %477 = icmp slt i64 %476, 1
  br i1 %477, label %389, label %836

478:                                              ; preds = %556
  %479 = load i32, ptr %5, align 4
  %480 = xor i32 %479, -1260388329
  store i32 %480, ptr %5, align 4
  %481 = xor i64 %2, -1098878048889790975
  %482 = and i64 %2, %481
  %483 = or i64 %2, %481
  %484 = xor i64 %2, %481
  %485 = add i64 %482, %483
  %486 = sub i64 %485, %2
  %487 = sub i64 %486, %481
  %488 = mul i64 %487, 112
  %489 = xor i64 %2, -6547614630017642001
  %490 = and i64 %2, %489
  %491 = or i64 %2, %489
  %492 = xor i64 %2, %489
  %493 = sub i64 %491, %492
  %494 = sub i64 %493, %490
  %495 = mul i64 %494, 67
  %496 = icmp ne i64 %488, %495
  br i1 %496, label %843, label %389

497:                                              ; preds = %574
  %498 = load i32, ptr %5, align 4
  %499 = xor i32 %498, -1733512409
  store i32 %499, ptr %5, align 4
  %500 = xor i64 %2, -7902683441881525337
  %501 = and i64 %2, %500
  %502 = or i64 %2, %500
  %503 = xor i64 %2, %500
  %504 = sub i64 %502, %503
  %505 = sub i64 %504, %501
  %506 = mul i64 %505, 53
  %507 = icmp sgt i64 %506, 0
  br i1 %507, label %850, label %389

508:                                              ; preds = %540
  %509 = load i32, ptr %5, align 4
  %510 = xor i32 %509, 37445596
  store i32 %510, ptr %5, align 4
  %511 = xor i64 %2, -2760945131408558037
  %512 = and i64 %2, %511
  %513 = or i64 %2, %511
  %514 = xor i64 %2, %511
  %515 = add i64 %512, %513
  %516 = sub i64 %515, %2
  %517 = sub i64 %516, %511
  %518 = mul i64 %517, 225
  %519 = icmp ne i64 %518, 0
  br i1 %519, label %859, label %389

520:                                              ; preds = %13
  %521 = icmp slt i32 %16, 519195531
  br i1 %521, label %524, label %526

522:                                              ; preds = %13
  %523 = icmp slt i32 %16, 1617081057
  br i1 %523, label %566, label %568

524:                                              ; preds = %520
  %525 = icmp slt i32 %16, 274904136
  br i1 %525, label %528, label %530

526:                                              ; preds = %520
  %527 = icmp slt i32 %16, 793832280
  br i1 %527, label %546, label %548

528:                                              ; preds = %524
  %529 = icmp slt i32 %16, 132297017
  br i1 %529, label %532, label %534

530:                                              ; preds = %524
  %531 = icmp slt i32 %16, 421950753
  br i1 %531, label %538, label %540

532:                                              ; preds = %528
  %533 = icmp eq i32 %16, 65172999
  br i1 %533, label %447, label %390

534:                                              ; preds = %528
  %535 = icmp eq i32 %16, 132297017
  br i1 %535, label %315, label %536

536:                                              ; preds = %534
  %537 = icmp eq i32 %16, 264302672
  br i1 %537, label %267, label %390

538:                                              ; preds = %530
  %539 = icmp eq i32 %16, 274904136
  br i1 %539, label %53, label %542

540:                                              ; preds = %530
  %541 = icmp eq i32 %16, 421950753
  br i1 %541, label %508, label %544

542:                                              ; preds = %538
  %543 = icmp eq i32 %16, 324054775
  br i1 %543, label %401, label %390

544:                                              ; preds = %540
  %545 = icmp eq i32 %16, 425904553
  br i1 %545, label %388, label %390

546:                                              ; preds = %526
  %547 = icmp slt i32 %16, 685281370
  br i1 %547, label %550, label %552

548:                                              ; preds = %526
  %549 = icmp slt i32 %16, 1175874633
  br i1 %549, label %558, label %560

550:                                              ; preds = %546
  %551 = icmp eq i32 %16, 519195531
  br i1 %551, label %30, label %554

552:                                              ; preds = %546
  %553 = icmp eq i32 %16, 685281370
  br i1 %553, label %86, label %556

554:                                              ; preds = %550
  %555 = icmp eq i32 %16, 586865536
  br i1 %555, label %466, label %390

556:                                              ; preds = %552
  %557 = icmp eq i32 %16, 737529183
  br i1 %557, label %478, label %390

558:                                              ; preds = %548
  %559 = icmp eq i32 %16, 793832280
  br i1 %559, label %75, label %562

560:                                              ; preds = %548
  %561 = icmp eq i32 %16, 1175874633
  br i1 %561, label %18, label %564

562:                                              ; preds = %558
  %563 = icmp eq i32 %16, 918988867
  br i1 %563, label %353, label %390

564:                                              ; preds = %560
  %565 = icmp eq i32 %16, 1357574639
  br i1 %565, label %287, label %390

566:                                              ; preds = %522
  %567 = icmp slt i32 %16, 1479816577
  br i1 %567, label %570, label %572

568:                                              ; preds = %522
  %569 = icmp slt i32 %16, 1831182056
  br i1 %569, label %588, label %590

570:                                              ; preds = %566
  %571 = icmp slt i32 %16, 1390033041
  br i1 %571, label %574, label %576

572:                                              ; preds = %566
  %573 = icmp slt i32 %16, 1555388589
  br i1 %573, label %580, label %582

574:                                              ; preds = %570
  %575 = icmp eq i32 %16, 1373186609
  br i1 %575, label %497, label %390

576:                                              ; preds = %570
  %577 = icmp eq i32 %16, 1390033041
  br i1 %577, label %296, label %578

578:                                              ; preds = %576
  %579 = icmp eq i32 %16, 1475387261
  br i1 %579, label %175, label %390

580:                                              ; preds = %572
  %581 = icmp eq i32 %16, 1479816577
  br i1 %581, label %119, label %584

582:                                              ; preds = %572
  %583 = icmp eq i32 %16, 1555388589
  br i1 %583, label %367, label %586

584:                                              ; preds = %580
  %585 = icmp eq i32 %16, 1495028181
  br i1 %585, label %413, label %390

586:                                              ; preds = %582
  %587 = icmp eq i32 %16, 1577374952
  br i1 %587, label %110, label %390

588:                                              ; preds = %568
  %589 = icmp slt i32 %16, 1689114484
  br i1 %589, label %592, label %594

590:                                              ; preds = %568
  %591 = icmp slt i32 %16, 2083779698
  br i1 %591, label %600, label %602

592:                                              ; preds = %588
  %593 = icmp eq i32 %16, 1617081057
  br i1 %593, label %143, label %596

594:                                              ; preds = %588
  %595 = icmp eq i32 %16, 1689114484
  br i1 %595, label %246, label %598

596:                                              ; preds = %592
  %597 = icmp eq i32 %16, 1619268837
  br i1 %597, label %426, label %390

598:                                              ; preds = %594
  %599 = icmp eq i32 %16, 1781938690
  br i1 %599, label %199, label %390

600:                                              ; preds = %590
  %601 = icmp eq i32 %16, 1831182056
  br i1 %601, label %186, label %604

602:                                              ; preds = %590
  %603 = icmp eq i32 %16, 2083779698
  br i1 %603, label %328, label %606

604:                                              ; preds = %600
  %605 = icmp eq i32 %16, 2077816382
  br i1 %605, label %39, label %390

606:                                              ; preds = %602
  %607 = icmp eq i32 %16, 2133732970
  br i1 %607, label %163, label %390

608:                                              ; preds = %18
  %609 = load i64, ptr %4, align 8
  %610 = ptrtoint ptr %0 to i64
  %611 = ptrtoint ptr %1 to i64
  %612 = or i64 %2, %611
  %613 = mul i64 %612, %611
  %614 = or i64 %613, %609
  %615 = and i64 %614, %2
  %616 = sub i64 %615, %611
  %617 = xor i64 %616, %2
  store i64 %617, ptr %4, align 8
  br label %389

618:                                              ; preds = %30
  %619 = load i64, ptr %4, align 8
  %620 = ptrtoint ptr %0 to i64
  %621 = ptrtoint ptr %1 to i64
  %622 = or i64 %620, %2
  %623 = xor i64 %622, %621
  %624 = mul i64 %623, %2
  %625 = mul i64 %624, %619
  %626 = and i64 %625, %619
  %627 = sub i64 %626, %621
  store i64 %627, ptr %4, align 8
  br label %389

628:                                              ; preds = %39
  %629 = load i64, ptr %4, align 8
  %630 = ptrtoint ptr %0 to i64
  %631 = ptrtoint ptr %1 to i64
  %632 = and i64 %629, %630
  %633 = or i64 %632, %630
  %634 = and i64 %633, %630
  store i64 %634, ptr %4, align 8
  br label %389

635:                                              ; preds = %53
  %636 = load i64, ptr %4, align 8
  %637 = ptrtoint ptr %0 to i64
  %638 = ptrtoint ptr %1 to i64
  %639 = add i64 %636, %638
  %640 = sub i64 %639, %638
  %641 = sub i64 %640, %638
  store i64 %641, ptr %4, align 8
  br label %389

642:                                              ; preds = %75
  %643 = load i64, ptr %4, align 8
  %644 = ptrtoint ptr %0 to i64
  %645 = ptrtoint ptr %1 to i64
  %646 = xor i64 %2, %2
  %647 = or i64 %646, %2
  %648 = sub i64 %647, %2
  %649 = add i64 %648, %2
  store i64 %649, ptr %4, align 8
  br label %389

650:                                              ; preds = %86
  %651 = load i64, ptr %4, align 8
  %652 = ptrtoint ptr %0 to i64
  %653 = ptrtoint ptr %1 to i64
  %654 = or i64 %651, %652
  %655 = add i64 %654, %2
  %656 = sub i64 %655, %652
  %657 = and i64 %656, %653
  store i64 %657, ptr %4, align 8
  br label %389

658:                                              ; preds = %110
  %659 = load i64, ptr %4, align 8
  %660 = ptrtoint ptr %0 to i64
  %661 = ptrtoint ptr %1 to i64
  %662 = and i64 %661, %661
  %663 = xor i64 %662, %2
  %664 = or i64 %663, %659
  store i64 %664, ptr %4, align 8
  br label %389

665:                                              ; preds = %119
  %666 = load i64, ptr %4, align 8
  %667 = ptrtoint ptr %0 to i64
  %668 = ptrtoint ptr %1 to i64
  %669 = sub i64 %2, %666
  %670 = add i64 %669, %668
  %671 = xor i64 %670, %2
  %672 = sub i64 %671, %666
  %673 = xor i64 %672, %2
  store i64 %673, ptr %4, align 8
  br label %389

674:                                              ; preds = %143
  %675 = load i64, ptr %4, align 8
  %676 = ptrtoint ptr %0 to i64
  %677 = ptrtoint ptr %1 to i64
  %678 = add i64 %677, %676
  %679 = sub i64 %678, %2
  %680 = or i64 %679, %675
  %681 = add i64 %680, %675
  %682 = mul i64 %681, %677
  %683 = and i64 %682, %677
  store i64 %683, ptr %4, align 8
  br label %389

684:                                              ; preds = %163
  %685 = load i64, ptr %4, align 8
  %686 = ptrtoint ptr %0 to i64
  %687 = ptrtoint ptr %1 to i64
  %688 = add i64 %685, %687
  %689 = or i64 %688, %687
  %690 = or i64 %689, %2
  %691 = xor i64 %690, %2
  %692 = mul i64 %691, %686
  %693 = mul i64 %692, %686
  store i64 %693, ptr %4, align 8
  br label %389

694:                                              ; preds = %175
  %695 = load i64, ptr %4, align 8
  %696 = ptrtoint ptr %0 to i64
  %697 = ptrtoint ptr %1 to i64
  %698 = or i64 %696, %695
  %699 = xor i64 %698, %696
  %700 = add i64 %699, %695
  %701 = add i64 %700, %696
  %702 = mul i64 %701, %695
  %703 = mul i64 %702, %695
  store i64 %703, ptr %4, align 8
  br label %389

704:                                              ; preds = %186
  %705 = load i64, ptr %4, align 8
  %706 = ptrtoint ptr %0 to i64
  %707 = ptrtoint ptr %1 to i64
  %708 = sub i64 %706, %706
  %709 = add i64 %708, %705
  %710 = xor i64 %709, %707
  %711 = xor i64 %710, %2
  store i64 %711, ptr %4, align 8
  br label %389

712:                                              ; preds = %199
  %713 = load i64, ptr %4, align 8
  %714 = ptrtoint ptr %0 to i64
  %715 = ptrtoint ptr %1 to i64
  %716 = mul i64 %713, %714
  %717 = sub i64 %716, %714
  %718 = and i64 %717, %713
  %719 = and i64 %718, %715
  %720 = xor i64 %719, %714
  %721 = or i64 %720, %713
  store i64 %721, ptr %4, align 8
  br label %389

722:                                              ; preds = %246
  %723 = load i64, ptr %4, align 8
  %724 = ptrtoint ptr %0 to i64
  %725 = ptrtoint ptr %1 to i64
  %726 = xor i64 %2, %723
  %727 = add i64 %726, %723
  %728 = mul i64 %727, %2
  %729 = or i64 %728, %723
  %730 = or i64 %729, %2
  store i64 %730, ptr %4, align 8
  br label %389

731:                                              ; preds = %267
  %732 = load i64, ptr %4, align 8
  %733 = ptrtoint ptr %0 to i64
  %734 = ptrtoint ptr %1 to i64
  %735 = mul i64 %732, %732
  %736 = mul i64 %735, %732
  %737 = add i64 %736, %732
  %738 = and i64 %737, %2
  %739 = or i64 %738, %734
  store i64 %739, ptr %4, align 8
  br label %389

740:                                              ; preds = %287
  %741 = load i64, ptr %4, align 8
  %742 = ptrtoint ptr %0 to i64
  %743 = ptrtoint ptr %1 to i64
  %744 = xor i64 %2, %743
  %745 = add i64 %744, %742
  %746 = add i64 %745, %743
  %747 = add i64 %746, %741
  %748 = add i64 %747, %742
  store i64 %748, ptr %4, align 8
  br label %389

749:                                              ; preds = %296
  %750 = load i64, ptr %4, align 8
  %751 = ptrtoint ptr %0 to i64
  %752 = ptrtoint ptr %1 to i64
  %753 = sub i64 %752, %751
  %754 = and i64 %753, %751
  %755 = mul i64 %754, %750
  %756 = add i64 %755, %751
  %757 = add i64 %756, %2
  %758 = and i64 %757, %751
  store i64 %758, ptr %4, align 8
  br label %389

759:                                              ; preds = %315
  %760 = load i64, ptr %4, align 8
  %761 = ptrtoint ptr %0 to i64
  %762 = ptrtoint ptr %1 to i64
  %763 = add i64 %760, %760
  %764 = xor i64 %763, %761
  %765 = or i64 %764, %761
  %766 = sub i64 %765, %760
  %767 = mul i64 %766, %2
  store i64 %767, ptr %4, align 8
  br label %389

768:                                              ; preds = %328
  %769 = load i64, ptr %4, align 8
  %770 = ptrtoint ptr %0 to i64
  %771 = ptrtoint ptr %1 to i64
  %772 = and i64 %771, %770
  %773 = sub i64 %772, %770
  %774 = or i64 %773, %769
  %775 = sub i64 %774, %769
  %776 = mul i64 %775, %771
  store i64 %776, ptr %4, align 8
  br label %389

777:                                              ; preds = %353
  %778 = load i64, ptr %4, align 8
  %779 = ptrtoint ptr %0 to i64
  %780 = ptrtoint ptr %1 to i64
  %781 = sub i64 %780, %780
  %782 = sub i64 %781, %2
  %783 = sub i64 %782, %778
  %784 = xor i64 %783, %780
  %785 = and i64 %784, %778
  %786 = sub i64 %785, %779
  store i64 %786, ptr %4, align 8
  br label %389

787:                                              ; preds = %367
  %788 = load i64, ptr %4, align 8
  %789 = ptrtoint ptr %0 to i64
  %790 = ptrtoint ptr %1 to i64
  %791 = mul i64 %2, %788
  %792 = and i64 %791, %2
  %793 = add i64 %792, %2
  store i64 %793, ptr %4, align 8
  br label %389

794:                                              ; preds = %390
  %795 = load i64, ptr %4, align 8
  %796 = ptrtoint ptr %0 to i64
  %797 = ptrtoint ptr %1 to i64
  %798 = sub i64 %797, %796
  %799 = and i64 %798, %796
  %800 = or i64 %799, %797
  store i64 %800, ptr %4, align 8
  br label %13

801:                                              ; preds = %401
  %802 = load i64, ptr %4, align 8
  %803 = ptrtoint ptr %0 to i64
  %804 = ptrtoint ptr %1 to i64
  %805 = and i64 %803, %803
  %806 = mul i64 %805, %804
  %807 = add i64 %806, %803
  %808 = and i64 %807, %804
  store i64 %808, ptr %4, align 8
  br label %389

809:                                              ; preds = %413
  %810 = load i64, ptr %4, align 8
  %811 = ptrtoint ptr %0 to i64
  %812 = ptrtoint ptr %1 to i64
  %813 = or i64 %811, %2
  %814 = add i64 %813, %812
  %815 = or i64 %814, %812
  %816 = mul i64 %815, %2
  %817 = mul i64 %816, %810
  store i64 %817, ptr %4, align 8
  br label %389

818:                                              ; preds = %426
  %819 = load i64, ptr %4, align 8
  %820 = ptrtoint ptr %0 to i64
  %821 = ptrtoint ptr %1 to i64
  %822 = add i64 %821, %819
  %823 = or i64 %822, %819
  %824 = sub i64 %823, %2
  %825 = or i64 %824, %820
  store i64 %825, ptr %4, align 8
  br label %389

826:                                              ; preds = %447
  %827 = load i64, ptr %4, align 8
  %828 = ptrtoint ptr %0 to i64
  %829 = ptrtoint ptr %1 to i64
  %830 = or i64 %829, %827
  %831 = add i64 %830, %829
  %832 = or i64 %831, %828
  %833 = sub i64 %832, %829
  %834 = add i64 %833, %829
  %835 = sub i64 %834, %829
  store i64 %835, ptr %4, align 8
  br label %389

836:                                              ; preds = %466
  %837 = load i64, ptr %4, align 8
  %838 = ptrtoint ptr %0 to i64
  %839 = ptrtoint ptr %1 to i64
  %840 = xor i64 %838, %2
  %841 = mul i64 %840, %2
  %842 = or i64 %841, %838
  store i64 %842, ptr %4, align 8
  br label %389

843:                                              ; preds = %478
  %844 = load i64, ptr %4, align 8
  %845 = ptrtoint ptr %0 to i64
  %846 = ptrtoint ptr %1 to i64
  %847 = and i64 %846, %846
  %848 = and i64 %847, %846
  %849 = and i64 %848, %846
  store i64 %849, ptr %4, align 8
  br label %389

850:                                              ; preds = %497
  %851 = load i64, ptr %4, align 8
  %852 = ptrtoint ptr %0 to i64
  %853 = ptrtoint ptr %1 to i64
  %854 = or i64 %851, %851
  %855 = and i64 %854, %851
  %856 = sub i64 %855, %853
  %857 = and i64 %856, %851
  %858 = or i64 %857, %851
  store i64 %858, ptr %4, align 8
  br label %389

859:                                              ; preds = %508
  %860 = load i64, ptr %4, align 8
  %861 = ptrtoint ptr %0 to i64
  %862 = ptrtoint ptr %1 to i64
  %863 = or i64 %862, %861
  %864 = add i64 %863, %861
  %865 = add i64 %864, %861
  store i64 %865, ptr %4, align 8
  br label %389
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_finalize(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca [64 x i8], align 16
  %9 = alloca [8 x i8], align 1
  %10 = alloca i64, align 8
  %11 = alloca i64, align 8
  store i32 1977739996, ptr %5, align 4
  br label %12

12:                                               ; preds = %463, %199, %198, %2
  %13 = load i32, ptr %5, align 4
  %14 = sub i32 %13, 1227884214
  %15 = mul i32 %14, -1392787023
  %16 = icmp slt i32 %15, 1011811309
  br i1 %16, label %333, label %335

17:                                               ; preds = %369
  store ptr %0, ptr %6, align 8
  store ptr %1, ptr %7, align 8
  %18 = load ptr, ptr %6, align 8
  %19 = icmp eq ptr %18, null
  %20 = select i1 %19, i32 1468890596, i32 1488927524
  store i32 %20, ptr %5, align 4
  %21 = xor i32 %4, 1208084849
  %22 = and i32 %4, %21
  %23 = or i32 %4, %21
  %24 = xor i32 %4, %21
  %25 = sub i32 %23, %24
  %26 = sub i32 %25, %22
  %27 = mul i32 %26, 76
  %28 = icmp slt i32 %27, 1
  br i1 %28, label %198, label %385

29:                                               ; preds = %353
  call void @die_message(ptr noundef @.str.78)
  store i32 1488927524, ptr %5, align 4
  %30 = xor i32 %4, 1290202781
  %31 = and i32 %4, %30
  %32 = or i32 %4, %30
  %33 = xor i32 %4, %30
  %34 = mul i32 %32, 2
  %35 = sub i32 %34, %33
  %36 = sub i32 %35, %4
  %37 = sub i32 %36, %30
  %38 = mul i32 %37, 142
  %39 = icmp sle i32 %38, 0
  br i1 %39, label %198, label %394

40:                                               ; preds = %345
  %41 = load ptr, ptr %7, align 8
  %42 = icmp eq ptr %41, null
  %43 = select i1 %42, i32 760416348, i32 -2072350730
  store i32 %43, ptr %5, align 4
  %44 = xor i32 %4, -1924478353
  %45 = and i32 %4, %44
  %46 = or i32 %4, %44
  %47 = xor i32 %4, %44
  %48 = mul i32 %46, 2
  %49 = sub i32 %48, %47
  %50 = sub i32 %49, %4
  %51 = sub i32 %50, %44
  %52 = mul i32 %51, 36
  %53 = icmp slt i32 %52, 1
  br i1 %53, label %198, label %401

54:                                               ; preds = %367
  call void @die_message(ptr noundef @.str.79)
  store i32 -2072350730, ptr %5, align 4
  %55 = xor i32 %4, -33227567
  %56 = and i32 %4, %55
  %57 = or i32 %4, %55
  %58 = xor i32 %4, %55
  %59 = add i32 %56, %57
  %60 = sub i32 %59, %4
  %61 = sub i32 %60, %55
  %62 = mul i32 %61, 211
  %63 = icmp slt i32 %62, 0
  br i1 %63, label %411, label %198

64:                                               ; preds = %371
  %65 = load ptr, ptr %6, align 8
  %66 = getelementptr inbounds nuw %struct.MD5Context, ptr %65, i32 0, i32 6
  %67 = load i32, ptr %66, align 4
  %68 = icmp ne i32 %67, 0
  %69 = select i1 %68, i32 -621725995, i32 1634988177
  store i32 %69, ptr %5, align 4
  %70 = xor i32 %4, 119463299
  %71 = and i32 %4, %70
  %72 = or i32 %4, %70
  %73 = xor i32 %4, %70
  %74 = sub i32 %72, %73
  %75 = sub i32 %74, %71
  %76 = mul i32 %75, 202
  %77 = icmp slt i32 %76, 0
  br i1 %77, label %419, label %198

78:                                               ; preds = %383
  call void @die_message(ptr noundef @.str.80)
  store i32 1634988177, ptr %5, align 4
  %79 = xor i32 %4, 1628420495
  %80 = and i32 %4, %79
  %81 = or i32 %4, %79
  %82 = xor i32 %4, %79
  %83 = add i32 %80, %81
  %84 = sub i32 %83, %4
  %85 = sub i32 %84, %79
  %86 = mul i32 %85, 94
  %87 = xor i32 %4, 1441290665
  %88 = and i32 %4, %87
  %89 = or i32 %4, %87
  %90 = xor i32 %4, %87
  %91 = add i32 %4, %87
  %92 = sub i32 %91, %90
  %93 = mul i32 %88, 2
  %94 = sub i32 %92, %93
  %95 = mul i32 %94, 189
  %96 = icmp ne i32 %86, %95
  br i1 %96, label %427, label %198

97:                                               ; preds = %381
  %98 = load ptr, ptr %6, align 8
  %99 = getelementptr inbounds nuw %struct.MD5Context, ptr %98, i32 0, i32 1
  %100 = load i64, ptr %99, align 8
  %101 = mul i64 %100, 8
  store i64 %101, ptr %10, align 8
  %102 = getelementptr inbounds [64 x i8], ptr %8, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %102, i8 0, i64 64, i1 false)
  %103 = getelementptr inbounds [64 x i8], ptr %8, i64 0, i64 0
  store i8 -128, ptr %103, align 16
  %104 = load ptr, ptr %6, align 8
  %105 = getelementptr inbounds nuw %struct.MD5Context, ptr %104, i32 0, i32 3
  %106 = load i64, ptr %105, align 8
  %107 = icmp ult i64 %106, 56
  %108 = select i1 %107, i32 -118263766, i32 -833225053
  store i32 %108, ptr %5, align 4
  %109 = xor i32 %4, -1351584307
  %110 = and i32 %4, %109
  %111 = or i32 %4, %109
  %112 = xor i32 %4, %109
  %113 = add i32 %110, %111
  %114 = sub i32 %113, %4
  %115 = sub i32 %114, %109
  %116 = mul i32 %115, 111
  %117 = xor i32 %4, 95203123
  %118 = and i32 %4, %117
  %119 = or i32 %4, %117
  %120 = xor i32 %4, %117
  %121 = add i32 %4, %117
  %122 = sub i32 %121, %120
  %123 = mul i32 %118, 2
  %124 = sub i32 %122, %123
  %125 = mul i32 %124, 81
  %126 = icmp ne i32 %116, %125
  br i1 %126, label %434, label %198

127:                                              ; preds = %359
  %128 = load ptr, ptr %6, align 8
  %129 = getelementptr inbounds nuw %struct.MD5Context, ptr %128, i32 0, i32 3
  %130 = load i64, ptr %129, align 8
  %131 = xor i64 56, %130
  %132 = and i64 -57, %130
  %133 = add i64 %132, %132
  %134 = sub i64 %131, %133
  store i64 %134, ptr %11, align 8
  store i32 1169026174, ptr %5, align 4
  %135 = xor i32 %4, 172070601
  %136 = and i32 %4, %135
  %137 = or i32 %4, %135
  %138 = xor i32 %4, %135
  %139 = mul i32 %137, 2
  %140 = sub i32 %139, %138
  %141 = sub i32 %140, %4
  %142 = sub i32 %141, %135
  %143 = mul i32 %142, 44
  %144 = icmp eq i32 %143, 0
  br i1 %144, label %198, label %444

145:                                              ; preds = %341
  %146 = load ptr, ptr %6, align 8
  %147 = getelementptr inbounds nuw %struct.MD5Context, ptr %146, i32 0, i32 3
  %148 = load i64, ptr %147, align 8
  %149 = add i64 %148, 1
  %150 = mul i64 120, %149
  %151 = mul i64 %148, 121
  %152 = sub i64 %150, %151
  store i64 %152, ptr %11, align 8
  store i32 1169026174, ptr %5, align 4
  %153 = xor i32 %4, 1670680363
  %154 = and i32 %4, %153
  %155 = or i32 %4, %153
  %156 = xor i32 %4, %153
  %157 = add i32 %154, %155
  %158 = sub i32 %157, %4
  %159 = sub i32 %158, %153
  %160 = mul i32 %159, 62
  %161 = icmp slt i32 %160, 0
  br i1 %161, label %454, label %198

162:                                              ; preds = %355
  %163 = getelementptr inbounds [8 x i8], ptr %9, i64 0, i64 0
  %164 = load i64, ptr %10, align 8
  call void @store_u64_le(ptr noundef %163, i64 noundef %164)
  %165 = load ptr, ptr %6, align 8
  %166 = getelementptr inbounds [64 x i8], ptr %8, i64 0, i64 0
  %167 = load i64, ptr %11, align 8
  call void @md5_update_bytes(ptr noundef %165, ptr noundef %166, i64 noundef %167)
  %168 = load ptr, ptr %6, align 8
  %169 = getelementptr inbounds [8 x i8], ptr %9, i64 0, i64 0
  call void @md5_update_bytes(ptr noundef %168, ptr noundef %169, i64 noundef 8)
  %170 = load ptr, ptr %7, align 8
  %171 = getelementptr inbounds i8, ptr %170, i64 0
  %172 = load ptr, ptr %6, align 8
  %173 = getelementptr inbounds nuw %struct.MD5Context, ptr %172, i32 0, i32 0
  %174 = getelementptr inbounds [4 x i32], ptr %173, i64 0, i64 0
  %175 = load i32, ptr %174, align 8
  call void @store_u32_le(ptr noundef %171, i32 noundef %175)
  %176 = load ptr, ptr %7, align 8
  %177 = getelementptr inbounds i8, ptr %176, i64 4
  %178 = load ptr, ptr %6, align 8
  %179 = getelementptr inbounds nuw %struct.MD5Context, ptr %178, i32 0, i32 0
  %180 = getelementptr inbounds [4 x i32], ptr %179, i64 0, i64 1
  %181 = load i32, ptr %180, align 4
  call void @store_u32_le(ptr noundef %177, i32 noundef %181)
  %182 = load ptr, ptr %7, align 8
  %183 = getelementptr inbounds i8, ptr %182, i64 8
  %184 = load ptr, ptr %6, align 8
  %185 = getelementptr inbounds nuw %struct.MD5Context, ptr %184, i32 0, i32 0
  %186 = getelementptr inbounds [4 x i32], ptr %185, i64 0, i64 2
  %187 = load i32, ptr %186, align 8
  call void @store_u32_le(ptr noundef %183, i32 noundef %187)
  %188 = load ptr, ptr %7, align 8
  %189 = getelementptr inbounds i8, ptr %188, i64 12
  %190 = load ptr, ptr %6, align 8
  %191 = getelementptr inbounds nuw %struct.MD5Context, ptr %190, i32 0, i32 0
  %192 = getelementptr inbounds [4 x i32], ptr %191, i64 0, i64 3
  %193 = load i32, ptr %192, align 4
  call void @store_u32_le(ptr noundef %189, i32 noundef %193)
  %194 = load ptr, ptr %6, align 8
  %195 = getelementptr inbounds nuw %struct.MD5Context, ptr %194, i32 0, i32 6
  store i32 1, ptr %195, align 4
  %196 = getelementptr inbounds [64 x i8], ptr %8, i64 0, i64 0
  call void @zero_memory(ptr noundef %196, i64 noundef 64)
  %197 = getelementptr inbounds [8 x i8], ptr %9, i64 0, i64 0
  call void @zero_memory(ptr noundef %197, i64 noundef 8)
  ret void

198:                                              ; preds = %532, %525, %516, %507, %497, %489, %481, %471, %454, %444, %434, %427, %419, %411, %401, %394, %385, %320, %298, %278, %266, %255, %242, %229, %218, %145, %127, %97, %78, %64, %54, %40, %29, %17
  br label %12

199:                                              ; preds = %383, %379, %377, %371, %369, %359, %355, %353, %347, %345
  store i32 1977739996, ptr %5, align 4
  call void asm sideeffect "", ""()
  %200 = xor i32 %4, 1558856675
  %201 = and i32 %4, %200
  %202 = or i32 %4, %200
  %203 = xor i32 %4, %200
  %204 = add i32 %201, %202
  %205 = sub i32 %204, %4
  %206 = sub i32 %205, %200
  %207 = mul i32 %206, 135
  %208 = xor i32 %4, -2014059685
  %209 = and i32 %4, %208
  %210 = or i32 %4, %208
  %211 = xor i32 %4, %208
  %212 = mul i32 %210, 2
  %213 = sub i32 %212, %211
  %214 = sub i32 %213, %4
  %215 = sub i32 %214, %208
  %216 = mul i32 %215, 205
  %217 = icmp ne i32 %207, %216
  br i1 %217, label %463, label %12

218:                                              ; preds = %365
  %219 = load i32, ptr %5, align 4
  %220 = xor i32 %219, -51452687
  store i32 %220, ptr %5, align 4
  %221 = xor i32 %4, 1667155479
  %222 = and i32 %4, %221
  %223 = or i32 %4, %221
  %224 = xor i32 %4, %221
  %225 = sub i32 %223, %224
  %226 = sub i32 %225, %222
  %227 = mul i32 %226, 165
  %228 = icmp slt i32 %227, 1
  br i1 %228, label %198, label %471

229:                                              ; preds = %377
  %230 = load i32, ptr %5, align 4
  %231 = xor i32 %230, 147408157
  store i32 %231, ptr %5, align 4
  %232 = xor i32 %4, -182237275
  %233 = and i32 %4, %232
  %234 = or i32 %4, %232
  %235 = xor i32 %4, %232
  %236 = mul i32 %234, 2
  %237 = sub i32 %236, %235
  %238 = sub i32 %237, %4
  %239 = sub i32 %238, %232
  %240 = mul i32 %239, 168
  %241 = icmp ne i32 %240, 0
  br i1 %241, label %481, label %198

242:                                              ; preds = %357
  %243 = load i32, ptr %5, align 4
  %244 = xor i32 %243, 1800919100
  store i32 %244, ptr %5, align 4
  %245 = xor i32 %4, -1398324287
  %246 = and i32 %4, %245
  %247 = or i32 %4, %245
  %248 = xor i32 %4, %245
  %249 = mul i32 %247, 2
  %250 = sub i32 %249, %248
  %251 = sub i32 %250, %4
  %252 = sub i32 %251, %245
  %253 = mul i32 %252, 225
  %254 = icmp slt i32 %253, 1
  br i1 %254, label %198, label %489

255:                                              ; preds = %347
  %256 = load i32, ptr %5, align 4
  %257 = xor i32 %256, -1753838489
  store i32 %257, ptr %5, align 4
  %258 = xor i32 %4, -701365633
  %259 = and i32 %4, %258
  %260 = or i32 %4, %258
  %261 = xor i32 %4, %258
  %262 = sub i32 %260, %261
  %263 = sub i32 %262, %259
  %264 = mul i32 %263, 13
  %265 = icmp slt i32 %264, 0
  br i1 %265, label %497, label %198

266:                                              ; preds = %349
  %267 = load i32, ptr %5, align 4
  %268 = xor i32 %267, 644116472
  store i32 %268, ptr %5, align 4
  %269 = xor i32 %4, 1482204821
  %270 = and i32 %4, %269
  %271 = or i32 %4, %269
  %272 = xor i32 %4, %269
  %273 = add i32 %270, %271
  %274 = sub i32 %273, %4
  %275 = sub i32 %274, %269
  %276 = mul i32 %275, 2
  %277 = icmp sgt i32 %276, 0
  br i1 %277, label %507, label %198

278:                                              ; preds = %343
  %279 = load i32, ptr %5, align 4
  %280 = xor i32 %279, 445894368
  store i32 %280, ptr %5, align 4
  %281 = xor i32 %4, 641804249
  %282 = and i32 %4, %281
  %283 = or i32 %4, %281
  %284 = xor i32 %4, %281
  %285 = add i32 %4, %281
  %286 = sub i32 %285, %284
  %287 = mul i32 %282, 2
  %288 = sub i32 %286, %287
  %289 = mul i32 %288, 237
  %290 = xor i32 %4, -1399966397
  %291 = and i32 %4, %290
  %292 = or i32 %4, %290
  %293 = xor i32 %4, %290
  %294 = sub i32 %292, %293
  %295 = sub i32 %294, %291
  %296 = mul i32 %295, 112
  %297 = icmp eq i32 %289, %296
  br i1 %297, label %198, label %516

298:                                              ; preds = %379
  %299 = load i32, ptr %5, align 4
  %300 = xor i32 %299, -1388714360
  store i32 %300, ptr %5, align 4
  %301 = xor i32 %4, 1240233795
  %302 = and i32 %4, %301
  %303 = or i32 %4, %301
  %304 = xor i32 %4, %301
  %305 = mul i32 %303, 2
  %306 = sub i32 %305, %304
  %307 = sub i32 %306, %4
  %308 = sub i32 %307, %301
  %309 = mul i32 %308, 179
  %310 = xor i32 %4, 675938401
  %311 = and i32 %4, %310
  %312 = or i32 %4, %310
  %313 = xor i32 %4, %310
  %314 = mul i32 %312, 2
  %315 = sub i32 %314, %313
  %316 = sub i32 %315, %4
  %317 = sub i32 %316, %310
  %318 = mul i32 %317, 107
  %319 = icmp ne i32 %309, %318
  br i1 %319, label %525, label %198

320:                                              ; preds = %373
  %321 = load i32, ptr %5, align 4
  %322 = xor i32 %321, -209707236
  store i32 %322, ptr %5, align 4
  %323 = xor i32 %4, -1950404229
  %324 = and i32 %4, %323
  %325 = or i32 %4, %323
  %326 = xor i32 %4, %323
  %327 = mul i32 %325, 2
  %328 = sub i32 %327, %326
  %329 = sub i32 %328, %4
  %330 = sub i32 %329, %323
  %331 = mul i32 %330, 89
  %332 = icmp uge i32 %331, 0
  br i1 %332, label %198, label %532

333:                                              ; preds = %12
  %334 = icmp slt i32 %15, 639205468
  br i1 %334, label %337, label %339

335:                                              ; preds = %12
  %336 = icmp slt i32 %15, 1473739721
  br i1 %336, label %361, label %363

337:                                              ; preds = %333
  %338 = icmp slt i32 %15, 156540708
  br i1 %338, label %341, label %343

339:                                              ; preds = %333
  %340 = icmp slt i32 %15, 677357384
  br i1 %340, label %349, label %351

341:                                              ; preds = %337
  %342 = icmp eq i32 %15, 8984541
  br i1 %342, label %145, label %345

343:                                              ; preds = %337
  %344 = icmp eq i32 %15, 156540708
  br i1 %344, label %278, label %347

345:                                              ; preds = %341
  %346 = icmp eq i32 %15, 140783118
  br i1 %346, label %40, label %199

347:                                              ; preds = %343
  %348 = icmp eq i32 %15, 512100392
  br i1 %348, label %255, label %199

349:                                              ; preds = %339
  %350 = icmp eq i32 %15, 639205468
  br i1 %350, label %266, label %353

351:                                              ; preds = %339
  %352 = icmp slt i32 %15, 702103266
  br i1 %352, label %355, label %357

353:                                              ; preds = %349
  %354 = icmp eq i32 %15, 663950542
  br i1 %354, label %29, label %199

355:                                              ; preds = %351
  %356 = icmp eq i32 %15, 677357384
  br i1 %356, label %162, label %199

357:                                              ; preds = %351
  %358 = icmp eq i32 %15, 702103266
  br i1 %358, label %242, label %359

359:                                              ; preds = %357
  %360 = icmp eq i32 %15, 760765748
  br i1 %360, label %127, label %199

361:                                              ; preds = %335
  %362 = icmp slt i32 %15, 1177831878
  br i1 %362, label %365, label %367

363:                                              ; preds = %335
  %364 = icmp slt i32 %15, 1731170920
  br i1 %364, label %373, label %375

365:                                              ; preds = %361
  %366 = icmp eq i32 %15, 1011811309
  br i1 %366, label %218, label %369

367:                                              ; preds = %361
  %368 = icmp eq i32 %15, 1177831878
  br i1 %368, label %54, label %371

369:                                              ; preds = %365
  %370 = icmp eq i32 %15, 1027695686
  br i1 %370, label %17, label %199

371:                                              ; preds = %367
  %372 = icmp eq i32 %15, 1233913152
  br i1 %372, label %64, label %199

373:                                              ; preds = %363
  %374 = icmp eq i32 %15, 1473739721
  br i1 %374, label %320, label %377

375:                                              ; preds = %363
  %376 = icmp slt i32 %15, 1744554859
  br i1 %376, label %379, label %381

377:                                              ; preds = %373
  %378 = icmp eq i32 %15, 1637146336
  br i1 %378, label %229, label %199

379:                                              ; preds = %375
  %380 = icmp eq i32 %15, 1731170920
  br i1 %380, label %298, label %199

381:                                              ; preds = %375
  %382 = icmp eq i32 %15, 1744554859
  br i1 %382, label %97, label %383

383:                                              ; preds = %381
  %384 = icmp eq i32 %15, 1849599087
  br i1 %384, label %78, label %199

385:                                              ; preds = %17
  %386 = load i64, ptr %3, align 8
  %387 = ptrtoint ptr %0 to i64
  %388 = ptrtoint ptr %1 to i64
  %389 = add i64 %388, %388
  %390 = sub i64 %389, %387
  %391 = sub i64 %390, %387
  %392 = xor i64 %391, %388
  %393 = or i64 %392, %386
  store i64 %393, ptr %3, align 8
  br label %198

394:                                              ; preds = %29
  %395 = load i64, ptr %3, align 8
  %396 = ptrtoint ptr %0 to i64
  %397 = ptrtoint ptr %1 to i64
  %398 = xor i64 %396, %395
  %399 = or i64 %398, %397
  %400 = and i64 %399, %395
  store i64 %400, ptr %3, align 8
  br label %198

401:                                              ; preds = %40
  %402 = load i64, ptr %3, align 8
  %403 = ptrtoint ptr %0 to i64
  %404 = ptrtoint ptr %1 to i64
  %405 = xor i64 %403, %402
  %406 = or i64 %405, %404
  %407 = or i64 %406, %402
  %408 = add i64 %407, %403
  %409 = or i64 %408, %403
  %410 = and i64 %409, %403
  store i64 %410, ptr %3, align 8
  br label %198

411:                                              ; preds = %54
  %412 = load i64, ptr %3, align 8
  %413 = ptrtoint ptr %0 to i64
  %414 = ptrtoint ptr %1 to i64
  %415 = sub i64 %413, %412
  %416 = mul i64 %415, %412
  %417 = add i64 %416, %414
  %418 = or i64 %417, %414
  store i64 %418, ptr %3, align 8
  br label %198

419:                                              ; preds = %64
  %420 = load i64, ptr %3, align 8
  %421 = ptrtoint ptr %0 to i64
  %422 = ptrtoint ptr %1 to i64
  %423 = or i64 %420, %420
  %424 = or i64 %423, %422
  %425 = add i64 %424, %421
  %426 = xor i64 %425, %422
  store i64 %426, ptr %3, align 8
  br label %198

427:                                              ; preds = %78
  %428 = load i64, ptr %3, align 8
  %429 = ptrtoint ptr %0 to i64
  %430 = ptrtoint ptr %1 to i64
  %431 = sub i64 %429, %428
  %432 = sub i64 %431, %430
  %433 = or i64 %432, %430
  store i64 %433, ptr %3, align 8
  br label %198

434:                                              ; preds = %97
  %435 = load i64, ptr %3, align 8
  %436 = ptrtoint ptr %0 to i64
  %437 = ptrtoint ptr %1 to i64
  %438 = add i64 %436, %437
  %439 = and i64 %438, %437
  %440 = sub i64 %439, %435
  %441 = add i64 %440, %436
  %442 = and i64 %441, %435
  %443 = mul i64 %442, %437
  store i64 %443, ptr %3, align 8
  br label %198

444:                                              ; preds = %127
  %445 = load i64, ptr %3, align 8
  %446 = ptrtoint ptr %0 to i64
  %447 = ptrtoint ptr %1 to i64
  %448 = add i64 %445, %447
  %449 = mul i64 %448, %447
  %450 = mul i64 %449, %446
  %451 = and i64 %450, %445
  %452 = xor i64 %451, %447
  %453 = mul i64 %452, %446
  store i64 %453, ptr %3, align 8
  br label %198

454:                                              ; preds = %145
  %455 = load i64, ptr %3, align 8
  %456 = ptrtoint ptr %0 to i64
  %457 = ptrtoint ptr %1 to i64
  %458 = xor i64 %456, %457
  %459 = or i64 %458, %455
  %460 = or i64 %459, %457
  %461 = mul i64 %460, %457
  %462 = or i64 %461, %457
  store i64 %462, ptr %3, align 8
  br label %198

463:                                              ; preds = %199
  %464 = load i64, ptr %3, align 8
  %465 = ptrtoint ptr %0 to i64
  %466 = ptrtoint ptr %1 to i64
  %467 = sub i64 %466, %464
  %468 = add i64 %467, %465
  %469 = mul i64 %468, %465
  %470 = sub i64 %469, %466
  store i64 %470, ptr %3, align 8
  br label %12

471:                                              ; preds = %218
  %472 = load i64, ptr %3, align 8
  %473 = ptrtoint ptr %0 to i64
  %474 = ptrtoint ptr %1 to i64
  %475 = or i64 %473, %473
  %476 = add i64 %475, %474
  %477 = or i64 %476, %472
  %478 = or i64 %477, %473
  %479 = and i64 %478, %474
  %480 = xor i64 %479, %473
  store i64 %480, ptr %3, align 8
  br label %198

481:                                              ; preds = %229
  %482 = load i64, ptr %3, align 8
  %483 = ptrtoint ptr %0 to i64
  %484 = ptrtoint ptr %1 to i64
  %485 = add i64 %484, %484
  %486 = mul i64 %485, %482
  %487 = mul i64 %486, %483
  %488 = xor i64 %487, %482
  store i64 %488, ptr %3, align 8
  br label %198

489:                                              ; preds = %242
  %490 = load i64, ptr %3, align 8
  %491 = ptrtoint ptr %0 to i64
  %492 = ptrtoint ptr %1 to i64
  %493 = and i64 %491, %491
  %494 = add i64 %493, %492
  %495 = xor i64 %494, %491
  %496 = xor i64 %495, %490
  store i64 %496, ptr %3, align 8
  br label %198

497:                                              ; preds = %255
  %498 = load i64, ptr %3, align 8
  %499 = ptrtoint ptr %0 to i64
  %500 = ptrtoint ptr %1 to i64
  %501 = sub i64 %499, %499
  %502 = or i64 %501, %499
  %503 = and i64 %502, %500
  %504 = sub i64 %503, %499
  %505 = or i64 %504, %498
  %506 = xor i64 %505, %500
  store i64 %506, ptr %3, align 8
  br label %198

507:                                              ; preds = %266
  %508 = load i64, ptr %3, align 8
  %509 = ptrtoint ptr %0 to i64
  %510 = ptrtoint ptr %1 to i64
  %511 = mul i64 %509, %509
  %512 = mul i64 %511, %508
  %513 = sub i64 %512, %510
  %514 = or i64 %513, %508
  %515 = sub i64 %514, %508
  store i64 %515, ptr %3, align 8
  br label %198

516:                                              ; preds = %278
  %517 = load i64, ptr %3, align 8
  %518 = ptrtoint ptr %0 to i64
  %519 = ptrtoint ptr %1 to i64
  %520 = and i64 %517, %517
  %521 = add i64 %520, %519
  %522 = xor i64 %521, %517
  %523 = and i64 %522, %518
  %524 = or i64 %523, %518
  store i64 %524, ptr %3, align 8
  br label %198

525:                                              ; preds = %298
  %526 = load i64, ptr %3, align 8
  %527 = ptrtoint ptr %0 to i64
  %528 = ptrtoint ptr %1 to i64
  %529 = sub i64 %528, %527
  %530 = mul i64 %529, %527
  %531 = sub i64 %530, %527
  store i64 %531, ptr %3, align 8
  br label %198

532:                                              ; preds = %320
  %533 = load i64, ptr %3, align 8
  %534 = ptrtoint ptr %0 to i64
  %535 = ptrtoint ptr %1 to i64
  %536 = and i64 %535, %535
  %537 = xor i64 %536, %533
  %538 = mul i64 %537, %534
  store i64 %538, ptr %3, align 8
  br label %198
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
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  store i32 -279722628, ptr %4, align 4
  br label %8

8:                                                ; preds = %191, %84, %83, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -1863612259
  %11 = mul i32 %10, -311991663
  %12 = icmp slt i32 %11, 1360058447
  br i1 %12, label %152, label %154

13:                                               ; preds = %164
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  store i32 0, ptr %7, align 4
  store i32 -2113751537, ptr %4, align 4
  %14 = xor i64 %1, -194983514298933327
  %15 = and i64 %1, %14
  %16 = or i64 %1, %14
  %17 = xor i64 %1, %14
  %18 = add i64 %1, %14
  %19 = sub i64 %18, %17
  %20 = mul i64 %15, 2
  %21 = sub i64 %19, %20
  %22 = mul i64 %21, 96
  %23 = icmp sgt i64 %22, 0
  br i1 %23, label %172, label %83

24:                                               ; preds = %162
  %25 = load i32, ptr %7, align 4
  %26 = icmp slt i32 %25, 8
  %27 = select i1 %26, i32 1821725938, i32 1563582652
  store i32 %27, ptr %4, align 4
  %28 = xor i64 %1, -7450340944869880089
  %29 = and i64 %1, %28
  %30 = or i64 %1, %28
  %31 = xor i64 %1, %28
  %32 = sub i64 %30, %31
  %33 = sub i64 %32, %29
  %34 = mul i64 %33, 128
  %35 = icmp slt i64 %34, 0
  br i1 %35, label %178, label %83

36:                                               ; preds = %166
  %37 = load i64, ptr %6, align 8
  %38 = load i32, ptr %7, align 4
  %39 = load i32, ptr %4, align 4
  %40 = xor i32 %39, 1821725946
  %41 = mul nsw i32 %40, %38
  %42 = zext i32 %41 to i64
  %43 = lshr i64 %37, %42
  %44 = add i64 %43, 255
  %45 = or i64 %43, 255
  %46 = sub i64 %44, %45
  %47 = trunc i64 %46 to i8
  %48 = load ptr, ptr %5, align 8
  %49 = load i32, ptr %7, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds i8, ptr %48, i64 %50
  store i8 %47, ptr %51, align 1
  %52 = load i32, ptr %7, align 4
  %53 = load i32, ptr %4, align 4
  %54 = xor i32 %53, 1821725939
  %55 = sub i32 %52, %54
  %56 = load i32, ptr %4, align 4
  %57 = xor i32 %56, 1821725936
  %58 = mul i32 %52, %57
  %59 = load i32, ptr %4, align 4
  %60 = xor i32 %59, 1821725939
  %61 = mul i32 %60, %55
  %62 = sub i32 %58, %61
  store i32 %62, ptr %7, align 4
  store i32 -2113751537, ptr %4, align 4
  %63 = xor i64 %1, 6899467688310549441
  %64 = and i64 %1, %63
  %65 = or i64 %1, %63
  %66 = xor i64 %1, %63
  %67 = mul i64 %65, 2
  %68 = sub i64 %67, %66
  %69 = sub i64 %68, %1
  %70 = sub i64 %69, %63
  %71 = mul i64 %70, 162
  %72 = xor i64 %1, -4561355034760316491
  %73 = and i64 %1, %72
  %74 = or i64 %1, %72
  %75 = xor i64 %1, %72
  %76 = mul i64 %74, 2
  %77 = sub i64 %76, %75
  %78 = sub i64 %77, %1
  %79 = sub i64 %78, %72
  %80 = mul i64 %79, 121
  %81 = icmp ne i64 %71, %80
  br i1 %81, label %185, label %83

82:                                               ; preds = %170
  ret void

83:                                               ; preds = %220, %214, %206, %197, %185, %178, %172, %141, %128, %115, %102, %36, %24, %13
  br label %8

84:                                               ; preds = %170, %168, %162, %160
  store i32 -279722628, ptr %4, align 4
  call void asm sideeffect "", ""()
  %85 = xor i64 %1, -4957627887936458493
  %86 = and i64 %1, %85
  %87 = or i64 %1, %85
  %88 = xor i64 %1, %85
  %89 = sub i64 %87, %88
  %90 = sub i64 %89, %86
  %91 = mul i64 %90, 112
  %92 = xor i64 %1, -3509095308871721091
  %93 = and i64 %1, %92
  %94 = or i64 %1, %92
  %95 = xor i64 %1, %92
  %96 = mul i64 %94, 2
  %97 = sub i64 %96, %95
  %98 = sub i64 %97, %1
  %99 = sub i64 %98, %92
  %100 = mul i64 %99, 13
  %101 = icmp eq i64 %91, %100
  br i1 %101, label %8, label %191

102:                                              ; preds = %160
  %103 = load i32, ptr %4, align 4
  %104 = xor i32 %103, 995719313
  store i32 %104, ptr %4, align 4
  %105 = xor i64 %1, 2396837316966690363
  %106 = and i64 %1, %105
  %107 = or i64 %1, %105
  %108 = xor i64 %1, %105
  %109 = add i64 %1, %105
  %110 = sub i64 %109, %108
  %111 = mul i64 %106, 2
  %112 = sub i64 %110, %111
  %113 = mul i64 %112, 122
  %114 = icmp slt i64 %113, 0
  br i1 %114, label %197, label %83

115:                                              ; preds = %156
  %116 = load i32, ptr %4, align 4
  %117 = xor i32 %116, -1614991228
  store i32 %117, ptr %4, align 4
  %118 = xor i64 %1, -289584807155109265
  %119 = and i64 %1, %118
  %120 = or i64 %1, %118
  %121 = xor i64 %1, %118
  %122 = add i64 %1, %118
  %123 = sub i64 %122, %121
  %124 = mul i64 %119, 2
  %125 = sub i64 %123, %124
  %126 = mul i64 %125, 74
  %127 = icmp slt i64 %126, 0
  br i1 %127, label %206, label %83

128:                                              ; preds = %158
  %129 = load i32, ptr %4, align 4
  %130 = xor i32 %129, -1005692900
  store i32 %130, ptr %4, align 4
  %131 = xor i64 %1, -1317416320925315551
  %132 = and i64 %1, %131
  %133 = or i64 %1, %131
  %134 = xor i64 %1, %131
  %135 = mul i64 %133, 2
  %136 = sub i64 %135, %134
  %137 = sub i64 %136, %1
  %138 = sub i64 %137, %131
  %139 = mul i64 %138, 93
  %140 = icmp slt i64 %139, 1
  br i1 %140, label %83, label %214

141:                                              ; preds = %168
  %142 = load i32, ptr %4, align 4
  %143 = xor i32 %142, -1875802673
  store i32 %143, ptr %4, align 4
  %144 = xor i64 %1, 6019649860738530713
  %145 = and i64 %1, %144
  %146 = or i64 %1, %144
  %147 = xor i64 %1, %144
  %148 = sub i64 %146, %147
  %149 = sub i64 %148, %145
  %150 = mul i64 %149, 158
  %151 = icmp sgt i64 %150, 0
  br i1 %151, label %220, label %83

152:                                              ; preds = %8
  %153 = icmp slt i32 %11, 703130631
  br i1 %153, label %156, label %158

154:                                              ; preds = %8
  %155 = icmp slt i32 %11, 1385711141
  br i1 %155, label %164, label %166

156:                                              ; preds = %152
  %157 = icmp eq i32 %11, 354204663
  br i1 %157, label %115, label %160

158:                                              ; preds = %152
  %159 = icmp eq i32 %11, 703130631
  br i1 %159, label %128, label %162

160:                                              ; preds = %156
  %161 = icmp eq i32 %11, 518798047
  br i1 %161, label %102, label %84

162:                                              ; preds = %158
  %163 = icmp eq i32 %11, 1080320402
  br i1 %163, label %24, label %84

164:                                              ; preds = %154
  %165 = icmp eq i32 %11, 1360058447
  br i1 %165, label %13, label %168

166:                                              ; preds = %154
  %167 = icmp eq i32 %11, 1385711141
  br i1 %167, label %36, label %170

168:                                              ; preds = %164
  %169 = icmp eq i32 %11, 1370039720
  br i1 %169, label %141, label %84

170:                                              ; preds = %166
  %171 = icmp eq i32 %11, 2052409231
  br i1 %171, label %82, label %84

172:                                              ; preds = %13
  %173 = load i64, ptr %3, align 8
  %174 = ptrtoint ptr %0 to i64
  %175 = or i64 %1, %1
  %176 = and i64 %175, %174
  %177 = add i64 %176, %1
  store i64 %177, ptr %3, align 8
  br label %83

178:                                              ; preds = %24
  %179 = load i64, ptr %3, align 8
  %180 = ptrtoint ptr %0 to i64
  %181 = add i64 %180, %179
  %182 = mul i64 %181, %1
  %183 = sub i64 %182, %180
  %184 = or i64 %183, %179
  store i64 %184, ptr %3, align 8
  br label %83

185:                                              ; preds = %36
  %186 = load i64, ptr %3, align 8
  %187 = ptrtoint ptr %0 to i64
  %188 = xor i64 %187, %186
  %189 = mul i64 %188, %186
  %190 = add i64 %189, %186
  store i64 %190, ptr %3, align 8
  br label %83

191:                                              ; preds = %84
  %192 = load i64, ptr %3, align 8
  %193 = ptrtoint ptr %0 to i64
  %194 = mul i64 %192, %1
  %195 = add i64 %194, %1
  %196 = sub i64 %195, %1
  store i64 %196, ptr %3, align 8
  br label %8

197:                                              ; preds = %102
  %198 = load i64, ptr %3, align 8
  %199 = ptrtoint ptr %0 to i64
  %200 = or i64 %1, %199
  %201 = or i64 %200, %199
  %202 = or i64 %201, %1
  %203 = xor i64 %202, %1
  %204 = sub i64 %203, %1
  %205 = or i64 %204, %198
  store i64 %205, ptr %3, align 8
  br label %83

206:                                              ; preds = %115
  %207 = load i64, ptr %3, align 8
  %208 = ptrtoint ptr %0 to i64
  %209 = mul i64 %1, %1
  %210 = xor i64 %209, %1
  %211 = and i64 %210, %208
  %212 = mul i64 %211, %207
  %213 = add i64 %212, %208
  store i64 %213, ptr %3, align 8
  br label %83

214:                                              ; preds = %128
  %215 = load i64, ptr %3, align 8
  %216 = ptrtoint ptr %0 to i64
  %217 = and i64 %1, %215
  %218 = mul i64 %217, %215
  %219 = xor i64 %218, %1
  store i64 %219, ptr %3, align 8
  br label %83

220:                                              ; preds = %141
  %221 = load i64, ptr %3, align 8
  %222 = ptrtoint ptr %0 to i64
  %223 = or i64 %221, %221
  %224 = or i64 %223, %221
  %225 = mul i64 %224, %221
  %226 = and i64 %225, %222
  %227 = xor i64 %226, %222
  %228 = mul i64 %227, %1
  store i64 %228, ptr %3, align 8
  br label %83
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @store_u32_le(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %4, align 4
  %6 = udiv i32 %5, 1
  %7 = add i32 %6, 255
  %8 = or i32 %6, 255
  %9 = sub i32 %7, %8
  %10 = trunc i32 %9 to i8
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds i8, ptr %11, i64 0
  store i8 %10, ptr %12, align 1
  %13 = load i32, ptr %4, align 4
  %14 = udiv i32 %13, 256
  %15 = add i32 %14, 255
  %16 = or i32 %14, 255
  %17 = sub i32 %15, %16
  %18 = trunc i32 %17 to i8
  %19 = load ptr, ptr %3, align 8
  %20 = getelementptr inbounds i8, ptr %19, i64 1
  store i8 %18, ptr %20, align 1
  %21 = load i32, ptr %4, align 4
  %22 = udiv i32 %21, 65536
  %23 = add i32 %22, 255
  %24 = or i32 %22, 255
  %25 = sub i32 %23, %24
  %26 = trunc i32 %25 to i8
  %27 = load ptr, ptr %3, align 8
  %28 = getelementptr inbounds i8, ptr %27, i64 2
  store i8 %26, ptr %28, align 1
  %29 = load i32, ptr %4, align 4
  %30 = udiv i32 %29, 16777216
  %31 = add i32 %30, 255
  %32 = or i32 %30, 255
  %33 = sub i32 %31, %32
  %34 = trunc i32 %33 to i8
  %35 = load ptr, ptr %3, align 8
  %36 = getelementptr inbounds i8, ptr %35, i64 3
  store i8 %34, ptr %36, align 1
  ret void
}

; Function Attrs: noreturn nounwind
declare void @exit(i32 noundef) #6

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #7

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_transform_block(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca [16 x i32], align 16
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
  %22 = alloca i32, align 4
  %23 = alloca i32, align 4
  %24 = alloca i32, align 4
  store i32 -1124156836, ptr %5, align 4
  br label %25

25:                                               ; preds = %512, %291, %290, %2
  %26 = load i32, ptr %5, align 4
  %27 = sub i32 %26, 1700152788
  %28 = mul i32 %27, 928522117
  %29 = icmp slt i32 %28, 969064957
  br i1 %29, label %412, label %414

30:                                               ; preds = %434
  store ptr %0, ptr %6, align 8
  store ptr %1, ptr %7, align 8
  %31 = getelementptr inbounds [16 x i32], ptr %8, i64 0, i64 0
  %32 = load ptr, ptr %7, align 8
  call void @md5_decode_block_words(ptr noundef %31, ptr noundef %32)
  %33 = load ptr, ptr %6, align 8
  %34 = load ptr, ptr %7, align 8
  %35 = getelementptr inbounds [16 x i32], ptr %8, i64 0, i64 0
  call void @md5_trace_block_header(ptr noundef %33, ptr noundef %34, ptr noundef %35)
  %36 = load ptr, ptr %6, align 8
  %37 = getelementptr inbounds nuw %struct.MD5Context, ptr %36, i32 0, i32 0
  %38 = getelementptr inbounds [4 x i32], ptr %37, i64 0, i64 0
  %39 = load i32, ptr %38, align 8
  store i32 %39, ptr %9, align 4
  %40 = load ptr, ptr %6, align 8
  %41 = getelementptr inbounds nuw %struct.MD5Context, ptr %40, i32 0, i32 0
  %42 = getelementptr inbounds [4 x i32], ptr %41, i64 0, i64 1
  %43 = load i32, ptr %42, align 4
  store i32 %43, ptr %10, align 4
  %44 = load ptr, ptr %6, align 8
  %45 = getelementptr inbounds nuw %struct.MD5Context, ptr %44, i32 0, i32 0
  %46 = getelementptr inbounds [4 x i32], ptr %45, i64 0, i64 2
  %47 = load i32, ptr %46, align 8
  store i32 %47, ptr %11, align 4
  %48 = load ptr, ptr %6, align 8
  %49 = getelementptr inbounds nuw %struct.MD5Context, ptr %48, i32 0, i32 0
  %50 = getelementptr inbounds [4 x i32], ptr %49, i64 0, i64 3
  %51 = load i32, ptr %50, align 4
  store i32 %51, ptr %12, align 4
  %52 = load i32, ptr %9, align 4
  store i32 %52, ptr %13, align 4
  %53 = load i32, ptr %10, align 4
  store i32 %53, ptr %14, align 4
  %54 = load i32, ptr %11, align 4
  store i32 %54, ptr %15, align 4
  %55 = load i32, ptr %12, align 4
  store i32 %55, ptr %16, align 4
  store i32 0, ptr %17, align 4
  store i32 1000161487, ptr %5, align 4
  %56 = xor i32 %4, 943127315
  %57 = and i32 %4, %56
  %58 = or i32 %4, %56
  %59 = xor i32 %4, %56
  %60 = mul i32 %58, 2
  %61 = sub i32 %60, %59
  %62 = sub i32 %61, %4
  %63 = sub i32 %62, %56
  %64 = mul i32 %63, 161
  %65 = icmp ne i32 %64, 0
  br i1 %65, label %456, label %290

66:                                               ; preds = %422
  %67 = load i32, ptr %17, align 4
  %68 = icmp ult i32 %67, 64
  %69 = select i1 %68, i32 -1144860939, i32 81383862
  store i32 %69, ptr %5, align 4
  %70 = xor i32 %4, -782003861
  %71 = and i32 %4, %70
  %72 = or i32 %4, %70
  %73 = xor i32 %4, %70
  %74 = add i32 %71, %72
  %75 = sub i32 %74, %4
  %76 = sub i32 %75, %70
  %77 = mul i32 %76, 36
  %78 = icmp eq i32 %77, 0
  br i1 %78, label %290, label %463

79:                                               ; preds = %442
  %80 = load i32, ptr %17, align 4
  %81 = load i32, ptr %10, align 4
  %82 = load i32, ptr %11, align 4
  %83 = load i32, ptr %12, align 4
  %84 = call i32 @md5_choose_round_function(i32 noundef %80, i32 noundef %81, i32 noundef %82, i32 noundef %83)
  store i32 %84, ptr %18, align 4
  %85 = load i32, ptr %17, align 4
  %86 = call i32 @md5_choose_message_index(i32 noundef %85)
  store i32 %86, ptr %19, align 4
  %87 = load i32, ptr %19, align 4
  %88 = zext i32 %87 to i64
  %89 = getelementptr inbounds nuw [16 x i32], ptr %8, i64 0, i64 %88
  %90 = load i32, ptr %89, align 4
  store i32 %90, ptr %20, align 4
  %91 = load i32, ptr %9, align 4
  %92 = load i32, ptr %18, align 4
  %93 = or i32 %91, %92
  %94 = and i32 %91, %92
  %95 = add i32 %93, %94
  %96 = load i32, ptr %17, align 4
  %97 = zext i32 %96 to i64
  %98 = getelementptr inbounds nuw [64 x i32], ptr @MD5_K, i64 0, i64 %97
  %99 = load i32, ptr %98, align 4
  %100 = or i32 %95, %99
  %101 = and i32 %95, %99
  %102 = add i32 %100, %101
  %103 = load i32, ptr %20, align 4
  %104 = xor i32 %102, %103
  %105 = and i32 %102, %103
  %106 = add i32 %105, %105
  %107 = add i32 %104, %106
  store i32 %107, ptr %21, align 4
  %108 = load i32, ptr %21, align 4
  %109 = load i32, ptr %17, align 4
  %110 = zext i32 %109 to i64
  %111 = getelementptr inbounds nuw [64 x i32], ptr @MD5_S, i64 0, i64 %110
  %112 = load i32, ptr %111, align 4
  %113 = call i32 @rotate_left32(i32 noundef %108, i32 noundef %112)
  store i32 %113, ptr %22, align 4
  %114 = load i32, ptr %10, align 4
  %115 = load i32, ptr %22, align 4
  %116 = or i32 %114, %115
  %117 = and i32 %114, %115
  %118 = add i32 %116, %117
  store i32 %118, ptr %23, align 4
  %119 = load ptr, ptr %6, align 8
  %120 = getelementptr inbounds nuw %struct.MD5Context, ptr %119, i32 0, i32 5
  %121 = load i32, ptr %120, align 8
  %122 = icmp ne i32 %121, 0
  %123 = select i1 %122, i32 -1915243565, i32 -1486141392
  store i32 %123, ptr %5, align 4
  %124 = xor i32 %4, 393962335
  %125 = and i32 %4, %124
  %126 = or i32 %4, %124
  %127 = xor i32 %4, %124
  %128 = mul i32 %126, 2
  %129 = sub i32 %128, %127
  %130 = sub i32 %129, %4
  %131 = sub i32 %130, %124
  %132 = mul i32 %131, 76
  %133 = xor i32 %4, -97549163
  %134 = and i32 %4, %133
  %135 = or i32 %4, %133
  %136 = xor i32 %4, %133
  %137 = sub i32 %135, %136
  %138 = sub i32 %137, %134
  %139 = mul i32 %138, 80
  %140 = icmp ne i32 %132, %139
  br i1 %140, label %470, label %290

141:                                              ; preds = %446
  %142 = load i32, ptr %17, align 4
  %143 = load i32, ptr %9, align 4
  %144 = load i32, ptr %10, align 4
  %145 = load i32, ptr %11, align 4
  %146 = load i32, ptr %12, align 4
  %147 = load i32, ptr %18, align 4
  %148 = load i32, ptr %19, align 4
  %149 = load i32, ptr %20, align 4
  %150 = load i32, ptr %23, align 4
  call void @md5_trace_round(i32 noundef %142, i32 noundef %143, i32 noundef %144, i32 noundef %145, i32 noundef %146, i32 noundef %147, i32 noundef %148, i32 noundef %149, i32 noundef %150)
  store i32 -1486141392, ptr %5, align 4
  %151 = xor i32 %4, -1135050731
  %152 = and i32 %4, %151
  %153 = or i32 %4, %151
  %154 = xor i32 %4, %151
  %155 = add i32 %152, %153
  %156 = sub i32 %155, %4
  %157 = sub i32 %156, %151
  %158 = mul i32 %157, 4
  %159 = icmp eq i32 %158, 0
  br i1 %159, label %290, label %477

160:                                              ; preds = %450
  %161 = load i32, ptr %12, align 4
  store i32 %161, ptr %24, align 4
  %162 = load i32, ptr %11, align 4
  store i32 %162, ptr %12, align 4
  %163 = load i32, ptr %10, align 4
  store i32 %163, ptr %11, align 4
  %164 = load i32, ptr %23, align 4
  store i32 %164, ptr %10, align 4
  %165 = load i32, ptr %24, align 4
  store i32 %165, ptr %9, align 4
  %166 = load i32, ptr %17, align 4
  %167 = load i32, ptr %5, align 4
  %168 = xor i32 %167, -1486141391
  %169 = or i32 %166, %168
  %170 = load i32, ptr %5, align 4
  %171 = xor i32 %170, -1486141391
  %172 = and i32 %166, %171
  %173 = add i32 %169, %172
  store i32 %173, ptr %17, align 4
  store i32 1000161487, ptr %5, align 4
  %174 = xor i32 %4, -518079803
  %175 = and i32 %4, %174
  %176 = or i32 %4, %174
  %177 = xor i32 %4, %174
  %178 = mul i32 %176, 2
  %179 = sub i32 %178, %177
  %180 = sub i32 %179, %4
  %181 = sub i32 %180, %174
  %182 = mul i32 %181, 167
  %183 = icmp ugt i32 %182, 0
  br i1 %183, label %485, label %290

184:                                              ; preds = %452
  %185 = load ptr, ptr %6, align 8
  %186 = getelementptr inbounds nuw %struct.MD5Context, ptr %185, i32 0, i32 0
  %187 = getelementptr inbounds [4 x i32], ptr %186, i64 0, i64 0
  %188 = load i32, ptr %187, align 8
  %189 = load i32, ptr %9, align 4
  %190 = xor i32 %188, %189
  %191 = and i32 %188, %189
  %192 = add i32 %191, %191
  %193 = add i32 %190, %192
  %194 = load ptr, ptr %6, align 8
  %195 = getelementptr inbounds nuw %struct.MD5Context, ptr %194, i32 0, i32 0
  %196 = getelementptr inbounds [4 x i32], ptr %195, i64 0, i64 0
  store i32 %193, ptr %196, align 8
  %197 = load ptr, ptr %6, align 8
  %198 = getelementptr inbounds nuw %struct.MD5Context, ptr %197, i32 0, i32 0
  %199 = getelementptr inbounds [4 x i32], ptr %198, i64 0, i64 1
  %200 = load i32, ptr %199, align 4
  %201 = load i32, ptr %10, align 4
  %202 = or i32 %200, %201
  %203 = and i32 %200, %201
  %204 = add i32 %202, %203
  %205 = load ptr, ptr %6, align 8
  %206 = getelementptr inbounds nuw %struct.MD5Context, ptr %205, i32 0, i32 0
  %207 = getelementptr inbounds [4 x i32], ptr %206, i64 0, i64 1
  store i32 %204, ptr %207, align 4
  %208 = load ptr, ptr %6, align 8
  %209 = getelementptr inbounds nuw %struct.MD5Context, ptr %208, i32 0, i32 0
  %210 = getelementptr inbounds [4 x i32], ptr %209, i64 0, i64 2
  %211 = load i32, ptr %210, align 8
  %212 = load i32, ptr %11, align 4
  %213 = load i32, ptr %5, align 4
  %214 = xor i32 %213, 81383863
  %215 = add i32 %212, %214
  %216 = load i32, ptr %5, align 4
  %217 = xor i32 %216, 81383863
  %218 = sub i32 %211, %217
  %219 = mul i32 %211, %215
  %220 = mul i32 %212, %218
  %221 = sub i32 %219, %220
  %222 = load ptr, ptr %6, align 8
  %223 = getelementptr inbounds nuw %struct.MD5Context, ptr %222, i32 0, i32 0
  %224 = getelementptr inbounds [4 x i32], ptr %223, i64 0, i64 2
  store i32 %221, ptr %224, align 8
  %225 = load ptr, ptr %6, align 8
  %226 = getelementptr inbounds nuw %struct.MD5Context, ptr %225, i32 0, i32 0
  %227 = getelementptr inbounds [4 x i32], ptr %226, i64 0, i64 3
  %228 = load i32, ptr %227, align 4
  %229 = load i32, ptr %12, align 4
  %230 = or i32 %228, %229
  %231 = and i32 %228, %229
  %232 = add i32 %230, %231
  %233 = load ptr, ptr %6, align 8
  %234 = getelementptr inbounds nuw %struct.MD5Context, ptr %233, i32 0, i32 0
  %235 = getelementptr inbounds [4 x i32], ptr %234, i64 0, i64 3
  store i32 %232, ptr %235, align 4
  %236 = load ptr, ptr %6, align 8
  %237 = getelementptr inbounds nuw %struct.MD5Context, ptr %236, i32 0, i32 5
  %238 = load i32, ptr %237, align 8
  %239 = icmp ne i32 %238, 0
  %240 = select i1 %239, i32 1020402490, i32 -16979723
  store i32 %240, ptr %5, align 4
  %241 = xor i32 %4, 1176922029
  %242 = and i32 %4, %241
  %243 = or i32 %4, %241
  %244 = xor i32 %4, %241
  %245 = sub i32 %243, %244
  %246 = sub i32 %245, %242
  %247 = mul i32 %246, 79
  %248 = icmp slt i32 %247, 0
  br i1 %248, label %495, label %290

249:                                              ; preds = %430
  %250 = load ptr, ptr @stderr, align 8
  %251 = load i32, ptr %13, align 4
  %252 = load i32, ptr %14, align 4
  %253 = load i32, ptr %15, align 4
  %254 = load i32, ptr %16, align 4
  %255 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %250, ptr noundef @.str.69, i32 noundef %251, i32 noundef %252, i32 noundef %253, i32 noundef %254) #9
  %256 = load ptr, ptr @stderr, align 8
  %257 = load ptr, ptr %6, align 8
  %258 = getelementptr inbounds nuw %struct.MD5Context, ptr %257, i32 0, i32 0
  %259 = getelementptr inbounds [4 x i32], ptr %258, i64 0, i64 0
  %260 = load i32, ptr %259, align 8
  %261 = load ptr, ptr %6, align 8
  %262 = getelementptr inbounds nuw %struct.MD5Context, ptr %261, i32 0, i32 0
  %263 = getelementptr inbounds [4 x i32], ptr %262, i64 0, i64 1
  %264 = load i32, ptr %263, align 4
  %265 = load ptr, ptr %6, align 8
  %266 = getelementptr inbounds nuw %struct.MD5Context, ptr %265, i32 0, i32 0
  %267 = getelementptr inbounds [4 x i32], ptr %266, i64 0, i64 2
  %268 = load i32, ptr %267, align 8
  %269 = load ptr, ptr %6, align 8
  %270 = getelementptr inbounds nuw %struct.MD5Context, ptr %269, i32 0, i32 0
  %271 = getelementptr inbounds [4 x i32], ptr %270, i64 0, i64 3
  %272 = load i32, ptr %271, align 4
  %273 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %256, ptr noundef @.str.70, i32 noundef %260, i32 noundef %264, i32 noundef %268, i32 noundef %272) #9
  store i32 -16979723, ptr %5, align 4
  %274 = xor i32 %4, -1175274999
  %275 = and i32 %4, %274
  %276 = or i32 %4, %274
  %277 = xor i32 %4, %274
  %278 = sub i32 %276, %277
  %279 = sub i32 %278, %275
  %280 = mul i32 %279, 11
  %281 = icmp uge i32 %280, 0
  br i1 %281, label %290, label %503

282:                                              ; preds = %432
  %283 = load ptr, ptr %6, align 8
  %284 = getelementptr inbounds nuw %struct.MD5Context, ptr %283, i32 0, i32 4
  %285 = load i64, ptr %284, align 8
  %286 = xor i64 %285, 1
  %287 = and i64 %285, 1
  %288 = add i64 %287, %287
  %289 = add i64 %286, %288
  store i64 %289, ptr %284, align 8
  ret void

290:                                              ; preds = %582, %572, %565, %555, %545, %537, %530, %520, %503, %495, %485, %477, %470, %463, %456, %399, %379, %366, %353, %340, %327, %314, %302, %249, %184, %160, %141, %79, %66, %30
  br label %25

291:                                              ; preds = %454, %452, %446, %444, %434, %432, %426, %424
  store i32 -1124156836, ptr %5, align 4
  call void asm sideeffect "", ""()
  %292 = xor i32 %4, 508126987
  %293 = and i32 %4, %292
  %294 = or i32 %4, %292
  %295 = xor i32 %4, %292
  %296 = add i32 %4, %292
  %297 = sub i32 %296, %295
  %298 = mul i32 %293, 2
  %299 = sub i32 %297, %298
  %300 = mul i32 %299, 71
  %301 = icmp uge i32 %300, 0
  br i1 %301, label %25, label %512

302:                                              ; preds = %440
  %303 = load i32, ptr %5, align 4
  %304 = xor i32 %303, -1233938328
  store i32 %304, ptr %5, align 4
  %305 = xor i32 %4, 1169997711
  %306 = and i32 %4, %305
  %307 = or i32 %4, %305
  %308 = xor i32 %4, %305
  %309 = add i32 %306, %307
  %310 = sub i32 %309, %4
  %311 = sub i32 %310, %305
  %312 = mul i32 %311, 150
  %313 = icmp sle i32 %312, 0
  br i1 %313, label %290, label %520

314:                                              ; preds = %424
  %315 = load i32, ptr %5, align 4
  %316 = xor i32 %315, -882113433
  store i32 %316, ptr %5, align 4
  %317 = xor i32 %4, -1479574529
  %318 = and i32 %4, %317
  %319 = or i32 %4, %317
  %320 = xor i32 %4, %317
  %321 = add i32 %4, %317
  %322 = sub i32 %321, %320
  %323 = mul i32 %318, 2
  %324 = sub i32 %322, %323
  %325 = mul i32 %324, 74
  %326 = icmp uge i32 %325, 0
  br i1 %326, label %290, label %530

327:                                              ; preds = %426
  %328 = load i32, ptr %5, align 4
  %329 = xor i32 %328, -675689838
  store i32 %329, ptr %5, align 4
  %330 = xor i32 %4, 1181946607
  %331 = and i32 %4, %330
  %332 = or i32 %4, %330
  %333 = xor i32 %4, %330
  %334 = add i32 %4, %330
  %335 = sub i32 %334, %333
  %336 = mul i32 %331, 2
  %337 = sub i32 %335, %336
  %338 = mul i32 %337, 71
  %339 = icmp sgt i32 %338, 0
  br i1 %339, label %537, label %290

340:                                              ; preds = %454
  %341 = load i32, ptr %5, align 4
  %342 = xor i32 %341, 1173904034
  store i32 %342, ptr %5, align 4
  %343 = xor i32 %4, 675739087
  %344 = and i32 %4, %343
  %345 = or i32 %4, %343
  %346 = xor i32 %4, %343
  %347 = mul i32 %345, 2
  %348 = sub i32 %347, %346
  %349 = sub i32 %348, %4
  %350 = sub i32 %349, %343
  %351 = mul i32 %350, 55
  %352 = icmp sle i32 %351, 0
  br i1 %352, label %290, label %545

353:                                              ; preds = %444
  %354 = load i32, ptr %5, align 4
  %355 = xor i32 %354, 2007635181
  store i32 %355, ptr %5, align 4
  %356 = xor i32 %4, 1704677341
  %357 = and i32 %4, %356
  %358 = or i32 %4, %356
  %359 = xor i32 %4, %356
  %360 = mul i32 %358, 2
  %361 = sub i32 %360, %359
  %362 = sub i32 %361, %4
  %363 = sub i32 %362, %356
  %364 = mul i32 %363, 176
  %365 = icmp ne i32 %364, 0
  br i1 %365, label %555, label %290

366:                                              ; preds = %428
  %367 = load i32, ptr %5, align 4
  %368 = xor i32 %367, 1690360421
  store i32 %368, ptr %5, align 4
  %369 = xor i32 %4, 974540373
  %370 = and i32 %4, %369
  %371 = or i32 %4, %369
  %372 = xor i32 %4, %369
  %373 = add i32 %4, %369
  %374 = sub i32 %373, %372
  %375 = mul i32 %370, 2
  %376 = sub i32 %374, %375
  %377 = mul i32 %376, 153
  %378 = icmp slt i32 %377, 1
  br i1 %378, label %290, label %565

379:                                              ; preds = %420
  %380 = load i32, ptr %5, align 4
  %381 = xor i32 %380, 681323376
  store i32 %381, ptr %5, align 4
  %382 = xor i32 %4, 1017006919
  %383 = and i32 %4, %382
  %384 = or i32 %4, %382
  %385 = xor i32 %4, %382
  %386 = sub i32 %384, %385
  %387 = sub i32 %386, %383
  %388 = mul i32 %387, 27
  %389 = xor i32 %4, -1303972733
  %390 = and i32 %4, %389
  %391 = or i32 %4, %389
  %392 = xor i32 %4, %389
  %393 = add i32 %4, %389
  %394 = sub i32 %393, %392
  %395 = mul i32 %390, 2
  %396 = sub i32 %394, %395
  %397 = mul i32 %396, 142
  %398 = icmp eq i32 %388, %397
  br i1 %398, label %290, label %572

399:                                              ; preds = %448
  %400 = load i32, ptr %5, align 4
  %401 = xor i32 %400, -213032449
  store i32 %401, ptr %5, align 4
  %402 = xor i32 %4, 1246553251
  %403 = and i32 %4, %402
  %404 = or i32 %4, %402
  %405 = xor i32 %4, %402
  %406 = mul i32 %404, 2
  %407 = sub i32 %406, %405
  %408 = sub i32 %407, %4
  %409 = sub i32 %408, %402
  %410 = mul i32 %409, 75
  %411 = icmp ne i32 %410, 0
  br i1 %411, label %582, label %290

412:                                              ; preds = %25
  %413 = icmp slt i32 %28, 644293916
  br i1 %413, label %416, label %418

414:                                              ; preds = %25
  %415 = icmp slt i32 %28, 1862538918
  br i1 %415, label %436, label %438

416:                                              ; preds = %412
  %417 = icmp slt i32 %28, 512543079
  br i1 %417, label %420, label %422

418:                                              ; preds = %412
  %419 = icmp slt i32 %28, 926758910
  br i1 %419, label %428, label %430

420:                                              ; preds = %416
  %421 = icmp eq i32 %28, 246411600
  br i1 %421, label %379, label %424

422:                                              ; preds = %416
  %423 = icmp eq i32 %28, 512543079
  br i1 %423, label %66, label %426

424:                                              ; preds = %420
  %425 = icmp eq i32 %28, 500555260
  br i1 %425, label %314, label %291

426:                                              ; preds = %422
  %427 = icmp eq i32 %28, 622418454
  br i1 %427, label %327, label %291

428:                                              ; preds = %418
  %429 = icmp eq i32 %28, 644293916
  br i1 %429, label %366, label %432

430:                                              ; preds = %418
  %431 = icmp eq i32 %28, 926758910
  br i1 %431, label %249, label %434

432:                                              ; preds = %428
  %433 = icmp eq i32 %28, 732675877
  br i1 %433, label %282, label %291

434:                                              ; preds = %430
  %435 = icmp eq i32 %28, 929104552
  br i1 %435, label %30, label %291

436:                                              ; preds = %414
  %437 = icmp slt i32 %28, 1163279653
  br i1 %437, label %440, label %442

438:                                              ; preds = %414
  %439 = icmp slt i32 %28, 1943231948
  br i1 %439, label %448, label %450

440:                                              ; preds = %436
  %441 = icmp eq i32 %28, 969064957
  br i1 %441, label %302, label %444

442:                                              ; preds = %436
  %443 = icmp eq i32 %28, 1163279653
  br i1 %443, label %79, label %446

444:                                              ; preds = %440
  %445 = icmp eq i32 %28, 1051605419
  br i1 %445, label %353, label %291

446:                                              ; preds = %442
  %447 = icmp eq i32 %28, 1345848955
  br i1 %447, label %141, label %291

448:                                              ; preds = %438
  %449 = icmp eq i32 %28, 1862538918
  br i1 %449, label %399, label %452

450:                                              ; preds = %438
  %451 = icmp eq i32 %28, 1943231948
  br i1 %451, label %160, label %454

452:                                              ; preds = %448
  %453 = icmp eq i32 %28, 1895303786
  br i1 %453, label %184, label %291

454:                                              ; preds = %450
  %455 = icmp eq i32 %28, 1983897502
  br i1 %455, label %340, label %291

456:                                              ; preds = %30
  %457 = load i64, ptr %3, align 8
  %458 = ptrtoint ptr %0 to i64
  %459 = ptrtoint ptr %1 to i64
  %460 = add i64 %459, %459
  %461 = xor i64 %460, %459
  %462 = or i64 %461, %457
  store i64 %462, ptr %3, align 8
  br label %290

463:                                              ; preds = %66
  %464 = load i64, ptr %3, align 8
  %465 = ptrtoint ptr %0 to i64
  %466 = ptrtoint ptr %1 to i64
  %467 = or i64 %464, %466
  %468 = and i64 %467, %464
  %469 = or i64 %468, %465
  store i64 %469, ptr %3, align 8
  br label %290

470:                                              ; preds = %79
  %471 = load i64, ptr %3, align 8
  %472 = ptrtoint ptr %0 to i64
  %473 = ptrtoint ptr %1 to i64
  %474 = add i64 %473, %472
  %475 = sub i64 %474, %472
  %476 = add i64 %475, %472
  store i64 %476, ptr %3, align 8
  br label %290

477:                                              ; preds = %141
  %478 = load i64, ptr %3, align 8
  %479 = ptrtoint ptr %0 to i64
  %480 = ptrtoint ptr %1 to i64
  %481 = or i64 %480, %478
  %482 = or i64 %481, %480
  %483 = add i64 %482, %479
  %484 = sub i64 %483, %480
  store i64 %484, ptr %3, align 8
  br label %290

485:                                              ; preds = %160
  %486 = load i64, ptr %3, align 8
  %487 = ptrtoint ptr %0 to i64
  %488 = ptrtoint ptr %1 to i64
  %489 = add i64 %486, %486
  %490 = and i64 %489, %488
  %491 = xor i64 %490, %488
  %492 = mul i64 %491, %487
  %493 = add i64 %492, %488
  %494 = xor i64 %493, %488
  store i64 %494, ptr %3, align 8
  br label %290

495:                                              ; preds = %184
  %496 = load i64, ptr %3, align 8
  %497 = ptrtoint ptr %0 to i64
  %498 = ptrtoint ptr %1 to i64
  %499 = sub i64 %496, %498
  %500 = and i64 %499, %498
  %501 = or i64 %500, %496
  %502 = and i64 %501, %496
  store i64 %502, ptr %3, align 8
  br label %290

503:                                              ; preds = %249
  %504 = load i64, ptr %3, align 8
  %505 = ptrtoint ptr %0 to i64
  %506 = ptrtoint ptr %1 to i64
  %507 = mul i64 %505, %504
  %508 = mul i64 %507, %506
  %509 = add i64 %508, %505
  %510 = mul i64 %509, %506
  %511 = sub i64 %510, %504
  store i64 %511, ptr %3, align 8
  br label %290

512:                                              ; preds = %291
  %513 = load i64, ptr %3, align 8
  %514 = ptrtoint ptr %0 to i64
  %515 = ptrtoint ptr %1 to i64
  %516 = add i64 %513, %515
  %517 = add i64 %516, %513
  %518 = sub i64 %517, %515
  %519 = or i64 %518, %514
  store i64 %519, ptr %3, align 8
  br label %25

520:                                              ; preds = %302
  %521 = load i64, ptr %3, align 8
  %522 = ptrtoint ptr %0 to i64
  %523 = ptrtoint ptr %1 to i64
  %524 = sub i64 %523, %523
  %525 = or i64 %524, %523
  %526 = and i64 %525, %522
  %527 = mul i64 %526, %523
  %528 = sub i64 %527, %521
  %529 = add i64 %528, %521
  store i64 %529, ptr %3, align 8
  br label %290

530:                                              ; preds = %314
  %531 = load i64, ptr %3, align 8
  %532 = ptrtoint ptr %0 to i64
  %533 = ptrtoint ptr %1 to i64
  %534 = and i64 %531, %531
  %535 = mul i64 %534, %533
  %536 = sub i64 %535, %533
  store i64 %536, ptr %3, align 8
  br label %290

537:                                              ; preds = %327
  %538 = load i64, ptr %3, align 8
  %539 = ptrtoint ptr %0 to i64
  %540 = ptrtoint ptr %1 to i64
  %541 = and i64 %540, %538
  %542 = add i64 %541, %538
  %543 = mul i64 %542, %538
  %544 = sub i64 %543, %538
  store i64 %544, ptr %3, align 8
  br label %290

545:                                              ; preds = %340
  %546 = load i64, ptr %3, align 8
  %547 = ptrtoint ptr %0 to i64
  %548 = ptrtoint ptr %1 to i64
  %549 = sub i64 %546, %546
  %550 = or i64 %549, %546
  %551 = sub i64 %550, %548
  %552 = mul i64 %551, %546
  %553 = or i64 %552, %548
  %554 = and i64 %553, %546
  store i64 %554, ptr %3, align 8
  br label %290

555:                                              ; preds = %353
  %556 = load i64, ptr %3, align 8
  %557 = ptrtoint ptr %0 to i64
  %558 = ptrtoint ptr %1 to i64
  %559 = or i64 %558, %557
  %560 = or i64 %559, %556
  %561 = add i64 %560, %556
  %562 = mul i64 %561, %558
  %563 = sub i64 %562, %556
  %564 = add i64 %563, %557
  store i64 %564, ptr %3, align 8
  br label %290

565:                                              ; preds = %366
  %566 = load i64, ptr %3, align 8
  %567 = ptrtoint ptr %0 to i64
  %568 = ptrtoint ptr %1 to i64
  %569 = mul i64 %566, %566
  %570 = add i64 %569, %567
  %571 = xor i64 %570, %568
  store i64 %571, ptr %3, align 8
  br label %290

572:                                              ; preds = %379
  %573 = load i64, ptr %3, align 8
  %574 = ptrtoint ptr %0 to i64
  %575 = ptrtoint ptr %1 to i64
  %576 = or i64 %573, %573
  %577 = or i64 %576, %575
  %578 = sub i64 %577, %573
  %579 = or i64 %578, %573
  %580 = mul i64 %579, %575
  %581 = sub i64 %580, %573
  store i64 %581, ptr %3, align 8
  br label %290

582:                                              ; preds = %399
  %583 = load i64, ptr %3, align 8
  %584 = ptrtoint ptr %0 to i64
  %585 = ptrtoint ptr %1 to i64
  %586 = mul i64 %584, %583
  %587 = or i64 %586, %585
  %588 = add i64 %587, %583
  %589 = mul i64 %588, %584
  %590 = or i64 %589, %583
  %591 = xor i64 %590, %584
  store i64 %591, ptr %3, align 8
  br label %290
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_decode_block_words(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  store i32 1653616158, ptr %5, align 4
  br label %9

9:                                                ; preds = %199, %94, %93, %2
  %10 = load i32, ptr %5, align 4
  %11 = sub i32 %10, 1040184138
  %12 = mul i32 %11, 1885125229
  %13 = icmp slt i32 %12, 1079448644
  br i1 %13, label %153, label %155

14:                                               ; preds = %165
  store ptr %0, ptr %6, align 8
  store ptr %1, ptr %7, align 8
  store i32 0, ptr %8, align 4
  store i32 1259869250, ptr %5, align 4
  %15 = xor i32 %4, -455630537
  %16 = and i32 %4, %15
  %17 = or i32 %4, %15
  %18 = xor i32 %4, %15
  %19 = sub i32 %17, %18
  %20 = sub i32 %19, %16
  %21 = mul i32 %20, 232
  %22 = xor i32 %4, 1272979549
  %23 = and i32 %4, %22
  %24 = or i32 %4, %22
  %25 = xor i32 %4, %22
  %26 = add i32 %23, %24
  %27 = sub i32 %26, %4
  %28 = sub i32 %27, %22
  %29 = mul i32 %28, 212
  %30 = icmp eq i32 %21, %29
  br i1 %30, label %93, label %173

31:                                               ; preds = %171
  %32 = load i32, ptr %8, align 4
  %33 = icmp slt i32 %32, 16
  %34 = select i1 %33, i32 -143196649, i32 -1416607234
  store i32 %34, ptr %5, align 4
  %35 = xor i32 %4, -2123282201
  %36 = and i32 %4, %35
  %37 = or i32 %4, %35
  %38 = xor i32 %4, %35
  %39 = add i32 %36, %37
  %40 = sub i32 %39, %4
  %41 = sub i32 %40, %35
  %42 = mul i32 %41, 251
  %43 = xor i32 %4, 851617201
  %44 = and i32 %4, %43
  %45 = or i32 %4, %43
  %46 = xor i32 %4, %43
  %47 = mul i32 %45, 2
  %48 = sub i32 %47, %46
  %49 = sub i32 %48, %4
  %50 = sub i32 %49, %43
  %51 = mul i32 %50, 49
  %52 = icmp ne i32 %42, %51
  br i1 %52, label %183, label %93

53:                                               ; preds = %157
  %54 = load ptr, ptr %7, align 8
  %55 = load i32, ptr %8, align 4
  %56 = load i32, ptr %5, align 4
  %57 = xor i32 %56, -143196653
  %58 = mul nsw i32 %55, %57
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds i8, ptr %54, i64 %59
  %61 = call i32 @load_u32_le(ptr noundef %60)
  %62 = load ptr, ptr %6, align 8
  %63 = load i32, ptr %8, align 4
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds i32, ptr %62, i64 %64
  store i32 %61, ptr %65, align 4
  %66 = load i32, ptr %8, align 4
  %67 = load i32, ptr %5, align 4
  %68 = xor i32 %67, -143196650
  %69 = xor i32 %66, %68
  %70 = load i32, ptr %5, align 4
  %71 = xor i32 %70, -143196650
  %72 = and i32 %66, %71
  %73 = add i32 %72, %72
  %74 = add i32 %69, %73
  store i32 %74, ptr %8, align 4
  store i32 1259869250, ptr %5, align 4
  %75 = xor i32 %4, 590037779
  %76 = and i32 %4, %75
  %77 = or i32 %4, %75
  %78 = xor i32 %4, %75
  %79 = sub i32 %77, %78
  %80 = sub i32 %79, %76
  %81 = mul i32 %80, 141
  %82 = xor i32 %4, 2075768775
  %83 = and i32 %4, %82
  %84 = or i32 %4, %82
  %85 = xor i32 %4, %82
  %86 = mul i32 %84, 2
  %87 = sub i32 %86, %85
  %88 = sub i32 %87, %4
  %89 = sub i32 %88, %82
  %90 = mul i32 %89, 120
  %91 = icmp eq i32 %81, %90
  br i1 %91, label %93, label %191

92:                                               ; preds = %167
  ret void

93:                                               ; preds = %232, %225, %217, %209, %191, %183, %173, %141, %128, %117, %105, %53, %31, %14
  br label %9

94:                                               ; preds = %171, %169, %163, %161
  store i32 1653616158, ptr %5, align 4
  call void asm sideeffect "", ""()
  %95 = xor i32 %4, 1060253673
  %96 = and i32 %4, %95
  %97 = or i32 %4, %95
  %98 = xor i32 %4, %95
  %99 = add i32 %4, %95
  %100 = sub i32 %99, %98
  %101 = mul i32 %96, 2
  %102 = sub i32 %100, %101
  %103 = mul i32 %102, 155
  %104 = icmp ugt i32 %103, 0
  br i1 %104, label %199, label %9

105:                                              ; preds = %169
  %106 = load i32, ptr %5, align 4
  %107 = xor i32 %106, 2139826488
  store i32 %107, ptr %5, align 4
  %108 = xor i32 %4, 1454793469
  %109 = and i32 %4, %108
  %110 = or i32 %4, %108
  %111 = xor i32 %4, %108
  %112 = add i32 %109, %110
  %113 = sub i32 %112, %4
  %114 = sub i32 %113, %108
  %115 = mul i32 %114, 212
  %116 = icmp slt i32 %115, 0
  br i1 %116, label %209, label %93

117:                                              ; preds = %161
  %118 = load i32, ptr %5, align 4
  %119 = xor i32 %118, 884467275
  store i32 %119, ptr %5, align 4
  %120 = xor i32 %4, 1676769111
  %121 = and i32 %4, %120
  %122 = or i32 %4, %120
  %123 = xor i32 %4, %120
  %124 = sub i32 %122, %123
  %125 = sub i32 %124, %121
  %126 = mul i32 %125, 15
  %127 = icmp ne i32 %126, 0
  br i1 %127, label %217, label %93

128:                                              ; preds = %159
  %129 = load i32, ptr %5, align 4
  %130 = xor i32 %129, 1667255376
  store i32 %130, ptr %5, align 4
  %131 = xor i32 %4, -1128865717
  %132 = and i32 %4, %131
  %133 = or i32 %4, %131
  %134 = xor i32 %4, %131
  %135 = mul i32 %133, 2
  %136 = sub i32 %135, %134
  %137 = sub i32 %136, %4
  %138 = sub i32 %137, %131
  %139 = mul i32 %138, 76
  %140 = icmp slt i32 %139, 0
  br i1 %140, label %225, label %93

141:                                              ; preds = %163
  %142 = load i32, ptr %5, align 4
  %143 = xor i32 %142, 1747237679
  store i32 %143, ptr %5, align 4
  %144 = xor i32 %4, -1958460913
  %145 = and i32 %4, %144
  %146 = or i32 %4, %144
  %147 = xor i32 %4, %144
  %148 = add i32 %145, %146
  %149 = sub i32 %148, %4
  %150 = sub i32 %149, %144
  %151 = mul i32 %150, 251
  %152 = icmp slt i32 %151, 0
  br i1 %152, label %232, label %93

153:                                              ; preds = %9
  %154 = icmp slt i32 %12, 340481934
  br i1 %154, label %157, label %159

155:                                              ; preds = %9
  %156 = icmp slt i32 %12, 1847833252
  br i1 %156, label %165, label %167

157:                                              ; preds = %153
  %158 = icmp eq i32 %12, 120884041
  br i1 %158, label %53, label %161

159:                                              ; preds = %153
  %160 = icmp eq i32 %12, 340481934
  br i1 %160, label %128, label %163

161:                                              ; preds = %157
  %162 = icmp eq i32 %12, 307749469
  br i1 %162, label %117, label %94

163:                                              ; preds = %159
  %164 = icmp eq i32 %12, 842835857
  br i1 %164, label %141, label %94

165:                                              ; preds = %155
  %166 = icmp eq i32 %12, 1079448644
  br i1 %166, label %14, label %169

167:                                              ; preds = %155
  %168 = icmp eq i32 %12, 1847833252
  br i1 %168, label %92, label %171

169:                                              ; preds = %165
  %170 = icmp eq i32 %12, 1223416059
  br i1 %170, label %105, label %94

171:                                              ; preds = %167
  %172 = icmp eq i32 %12, 1952070040
  br i1 %172, label %31, label %94

173:                                              ; preds = %14
  %174 = load i64, ptr %3, align 8
  %175 = ptrtoint ptr %0 to i64
  %176 = ptrtoint ptr %1 to i64
  %177 = add i64 %176, %174
  %178 = or i64 %177, %174
  %179 = xor i64 %178, %174
  %180 = or i64 %179, %176
  %181 = xor i64 %180, %175
  %182 = xor i64 %181, %175
  store i64 %182, ptr %3, align 8
  br label %93

183:                                              ; preds = %31
  %184 = load i64, ptr %3, align 8
  %185 = ptrtoint ptr %0 to i64
  %186 = ptrtoint ptr %1 to i64
  %187 = sub i64 %185, %186
  %188 = add i64 %187, %186
  %189 = or i64 %188, %185
  %190 = or i64 %189, %185
  store i64 %190, ptr %3, align 8
  br label %93

191:                                              ; preds = %53
  %192 = load i64, ptr %3, align 8
  %193 = ptrtoint ptr %0 to i64
  %194 = ptrtoint ptr %1 to i64
  %195 = add i64 %193, %193
  %196 = or i64 %195, %193
  %197 = sub i64 %196, %193
  %198 = mul i64 %197, %192
  store i64 %198, ptr %3, align 8
  br label %93

199:                                              ; preds = %94
  %200 = load i64, ptr %3, align 8
  %201 = ptrtoint ptr %0 to i64
  %202 = ptrtoint ptr %1 to i64
  %203 = sub i64 %201, %200
  %204 = mul i64 %203, %202
  %205 = or i64 %204, %201
  %206 = sub i64 %205, %200
  %207 = add i64 %206, %202
  %208 = xor i64 %207, %202
  store i64 %208, ptr %3, align 8
  br label %9

209:                                              ; preds = %105
  %210 = load i64, ptr %3, align 8
  %211 = ptrtoint ptr %0 to i64
  %212 = ptrtoint ptr %1 to i64
  %213 = add i64 %210, %211
  %214 = xor i64 %213, %210
  %215 = sub i64 %214, %210
  %216 = and i64 %215, %211
  store i64 %216, ptr %3, align 8
  br label %93

217:                                              ; preds = %117
  %218 = load i64, ptr %3, align 8
  %219 = ptrtoint ptr %0 to i64
  %220 = ptrtoint ptr %1 to i64
  %221 = or i64 %218, %218
  %222 = xor i64 %221, %220
  %223 = or i64 %222, %218
  %224 = sub i64 %223, %220
  store i64 %224, ptr %3, align 8
  br label %93

225:                                              ; preds = %128
  %226 = load i64, ptr %3, align 8
  %227 = ptrtoint ptr %0 to i64
  %228 = ptrtoint ptr %1 to i64
  %229 = mul i64 %226, %227
  %230 = and i64 %229, %227
  %231 = add i64 %230, %227
  store i64 %231, ptr %3, align 8
  br label %93

232:                                              ; preds = %141
  %233 = load i64, ptr %3, align 8
  %234 = ptrtoint ptr %0 to i64
  %235 = ptrtoint ptr %1 to i64
  %236 = add i64 %234, %235
  %237 = xor i64 %236, %234
  %238 = and i64 %237, %235
  %239 = or i64 %238, %235
  %240 = and i64 %239, %233
  %241 = and i64 %240, %234
  store i64 %241, ptr %3, align 8
  br label %93
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @md5_trace_block_header(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = ptrtoint ptr %0 to i32
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store i32 1948098677, ptr %6, align 4
  br label %12

12:                                               ; preds = %727, %353, %352, %3
  %13 = load i32, ptr %6, align 4
  %14 = sub i32 %13, -1742736891
  %15 = mul i32 %14, 1901722529
  %16 = icmp slt i32 %15, 1195493774
  br i1 %16, label %477, label %479

17:                                               ; preds = %507
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  store ptr %2, ptr %9, align 8
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds nuw %struct.MD5Context, ptr %18, i32 0, i32 5
  %20 = load i32, ptr %19, align 8
  %21 = icmp ne i32 %20, 0
  %22 = select i1 %21, i32 702101262, i32 1371152927
  store i32 %22, ptr %6, align 4
  %23 = xor i32 %5, -775167353
  %24 = and i32 %5, %23
  %25 = or i32 %5, %23
  %26 = xor i32 %5, %23
  %27 = add i32 %24, %25
  %28 = sub i32 %27, %5
  %29 = sub i32 %28, %23
  %30 = mul i32 %29, 85
  %31 = icmp uge i32 %30, 0
  br i1 %31, label %352, label %559

32:                                               ; preds = %499
  store i32 1209176690, ptr %6, align 4
  %33 = xor i32 %5, 215863927
  %34 = and i32 %5, %33
  %35 = or i32 %5, %33
  %36 = xor i32 %5, %33
  %37 = add i32 %5, %33
  %38 = sub i32 %37, %36
  %39 = mul i32 %34, 2
  %40 = sub i32 %38, %39
  %41 = mul i32 %40, 210
  %42 = icmp sgt i32 %41, 0
  br i1 %42, label %568, label %352

43:                                               ; preds = %517
  %44 = load ptr, ptr @stderr, align 8
  %45 = load ptr, ptr %7, align 8
  %46 = getelementptr inbounds nuw %struct.MD5Context, ptr %45, i32 0, i32 4
  %47 = load i64, ptr %46, align 8
  %48 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %44, ptr noundef @.str.71, i64 noundef %47) #9
  %49 = load ptr, ptr @stderr, align 8
  %50 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %49, ptr noundef @.str.72) #9
  store i32 0, ptr %10, align 4
  store i32 1106348612, ptr %6, align 4
  %51 = xor i32 %5, -1615523633
  %52 = and i32 %5, %51
  %53 = or i32 %5, %51
  %54 = xor i32 %5, %51
  %55 = sub i32 %53, %54
  %56 = sub i32 %55, %52
  %57 = mul i32 %56, 149
  %58 = icmp slt i32 %57, 0
  br i1 %58, label %577, label %352

59:                                               ; preds = %491
  %60 = load i32, ptr %10, align 4
  %61 = icmp slt i32 %60, 4
  %62 = select i1 %61, i32 -1622675229, i32 1431546821
  store i32 %62, ptr %6, align 4
  %63 = xor i32 %5, 532284093
  %64 = and i32 %5, %63
  %65 = or i32 %5, %63
  %66 = xor i32 %5, %63
  %67 = add i32 %5, %63
  %68 = sub i32 %67, %66
  %69 = mul i32 %64, 2
  %70 = sub i32 %68, %69
  %71 = mul i32 %70, 234
  %72 = icmp slt i32 %71, 1
  br i1 %72, label %352, label %585

73:                                               ; preds = %531
  %74 = load ptr, ptr @stderr, align 8
  %75 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %74, ptr noundef @.str.73) #9
  store i32 0, ptr %11, align 4
  store i32 -1660867640, ptr %6, align 4
  %76 = xor i32 %5, -2137627231
  %77 = and i32 %5, %76
  %78 = or i32 %5, %76
  %79 = xor i32 %5, %76
  %80 = sub i32 %78, %79
  %81 = sub i32 %80, %77
  %82 = mul i32 %81, 212
  %83 = icmp eq i32 %82, 0
  br i1 %83, label %352, label %594

84:                                               ; preds = %493
  %85 = load i32, ptr %11, align 4
  %86 = icmp slt i32 %85, 16
  %87 = select i1 %86, i32 110559637, i32 2142899886
  store i32 %87, ptr %6, align 4
  %88 = xor i32 %5, -1448218581
  %89 = and i32 %5, %88
  %90 = or i32 %5, %88
  %91 = xor i32 %5, %88
  %92 = sub i32 %90, %91
  %93 = sub i32 %92, %89
  %94 = mul i32 %93, 132
  %95 = xor i32 %5, -1481885451
  %96 = and i32 %5, %95
  %97 = or i32 %5, %95
  %98 = xor i32 %5, %95
  %99 = add i32 %96, %97
  %100 = sub i32 %99, %5
  %101 = sub i32 %100, %95
  %102 = mul i32 %101, 108
  %103 = icmp ne i32 %94, %102
  br i1 %103, label %604, label %352

104:                                              ; preds = %509
  %105 = load ptr, ptr @stderr, align 8
  %106 = load ptr, ptr %8, align 8
  %107 = load i32, ptr %10, align 4
  %108 = load i32, ptr %6, align 4
  %109 = xor i32 %108, 110559621
  %110 = mul nsw i32 %107, %109
  %111 = load i32, ptr %11, align 4
  %112 = xor i32 %110, %111
  %113 = and i32 %110, %111
  %114 = add i32 %113, %113
  %115 = add i32 %112, %114
  %116 = sext i32 %115 to i64
  %117 = getelementptr inbounds i8, ptr %106, i64 %116
  %118 = load i8, ptr %117, align 1
  %119 = zext i8 %118 to i32
  %120 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %105, ptr noundef @.str.74, i32 noundef %119) #9
  %121 = load i32, ptr %11, align 4
  %122 = icmp ne i32 %121, 15
  %123 = select i1 %122, i32 -834097366, i32 708868164
  store i32 %123, ptr %6, align 4
  %124 = xor i32 %5, -814035809
  %125 = and i32 %5, %124
  %126 = or i32 %5, %124
  %127 = xor i32 %5, %124
  %128 = add i32 %125, %126
  %129 = sub i32 %128, %5
  %130 = sub i32 %129, %124
  %131 = mul i32 %130, 139
  %132 = icmp ugt i32 %131, 0
  br i1 %132, label %613, label %352

133:                                              ; preds = %497
  %134 = load ptr, ptr @stderr, align 8
  %135 = call i32 @fputc(i32 noundef 32, ptr noundef %134)
  store i32 708868164, ptr %6, align 4
  %136 = xor i32 %5, -2029297819
  %137 = and i32 %5, %136
  %138 = or i32 %5, %136
  %139 = xor i32 %5, %136
  %140 = mul i32 %138, 2
  %141 = sub i32 %140, %139
  %142 = sub i32 %141, %5
  %143 = sub i32 %142, %136
  %144 = mul i32 %143, 196
  %145 = icmp sle i32 %144, 0
  br i1 %145, label %352, label %624

146:                                              ; preds = %513
  %147 = load i32, ptr %11, align 4
  %148 = load i32, ptr %6, align 4
  %149 = xor i32 %148, 708868165
  %150 = or i32 %147, %149
  %151 = load i32, ptr %6, align 4
  %152 = xor i32 %151, 708868165
  %153 = and i32 %147, %152
  %154 = add i32 %150, %153
  store i32 %154, ptr %11, align 4
  store i32 -1660867640, ptr %6, align 4
  %155 = xor i32 %5, -180939639
  %156 = and i32 %5, %155
  %157 = or i32 %5, %155
  %158 = xor i32 %5, %155
  %159 = sub i32 %157, %158
  %160 = sub i32 %159, %156
  %161 = mul i32 %160, 42
  %162 = icmp uge i32 %161, 0
  br i1 %162, label %352, label %634

163:                                              ; preds = %533
  %164 = load ptr, ptr @stderr, align 8
  %165 = call i32 @fputc(i32 noundef 10, ptr noundef %164)
  %166 = load i32, ptr %10, align 4
  %167 = load i32, ptr %6, align 4
  %168 = xor i32 %167, 2142899887
  %169 = xor i32 %166, %168
  %170 = load i32, ptr %6, align 4
  %171 = xor i32 %170, 2142899887
  %172 = and i32 %166, %171
  %173 = add i32 %172, %172
  %174 = add i32 %169, %173
  store i32 %174, ptr %10, align 4
  store i32 1106348612, ptr %6, align 4
  %175 = xor i32 %5, -1886692327
  %176 = and i32 %5, %175
  %177 = or i32 %5, %175
  %178 = xor i32 %5, %175
  %179 = sub i32 %177, %178
  %180 = sub i32 %179, %176
  %181 = mul i32 %180, 171
  %182 = icmp slt i32 %181, 0
  br i1 %182, label %643, label %352

183:                                              ; preds = %489
  %184 = load ptr, ptr @stderr, align 8
  %185 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %184, ptr noundef @.str.75) #9
  store i32 0, ptr %10, align 4
  store i32 695257803, ptr %6, align 4
  %186 = xor i32 %5, -2044605379
  %187 = and i32 %5, %186
  %188 = or i32 %5, %186
  %189 = xor i32 %5, %186
  %190 = sub i32 %188, %189
  %191 = sub i32 %190, %187
  %192 = mul i32 %191, 71
  %193 = icmp sle i32 %192, 0
  br i1 %193, label %352, label %651

194:                                              ; preds = %547
  %195 = load i32, ptr %10, align 4
  %196 = icmp slt i32 %195, 4
  %197 = select i1 %196, i32 -757885005, i32 1209176690
  store i32 %197, ptr %6, align 4
  %198 = xor i32 %5, 398958035
  %199 = and i32 %5, %198
  %200 = or i32 %5, %198
  %201 = xor i32 %5, %198
  %202 = add i32 %199, %200
  %203 = sub i32 %202, %5
  %204 = sub i32 %203, %198
  %205 = mul i32 %204, 88
  %206 = xor i32 %5, 208342117
  %207 = and i32 %5, %206
  %208 = or i32 %5, %206
  %209 = xor i32 %5, %206
  %210 = add i32 %5, %206
  %211 = sub i32 %210, %209
  %212 = mul i32 %207, 2
  %213 = sub i32 %211, %212
  %214 = mul i32 %213, 227
  %215 = icmp eq i32 %205, %214
  br i1 %215, label %352, label %660

216:                                              ; preds = %555
  %217 = load ptr, ptr @stderr, align 8
  %218 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %217, ptr noundef @.str.73) #9
  store i32 0, ptr %11, align 4
  store i32 1134640052, ptr %6, align 4
  %219 = xor i32 %5, 604929681
  %220 = and i32 %5, %219
  %221 = or i32 %5, %219
  %222 = xor i32 %5, %219
  %223 = sub i32 %221, %222
  %224 = sub i32 %223, %220
  %225 = mul i32 %224, 185
  %226 = icmp sgt i32 %225, 0
  br i1 %226, label %670, label %352

227:                                              ; preds = %557
  %228 = load i32, ptr %11, align 4
  %229 = icmp slt i32 %228, 4
  %230 = select i1 %229, i32 1610683745, i32 1542394508
  store i32 %230, ptr %6, align 4
  %231 = xor i32 %5, 1576459357
  %232 = and i32 %5, %231
  %233 = or i32 %5, %231
  %234 = xor i32 %5, %231
  %235 = mul i32 %233, 2
  %236 = sub i32 %235, %234
  %237 = sub i32 %236, %5
  %238 = sub i32 %237, %231
  %239 = mul i32 %238, 210
  %240 = icmp ugt i32 %239, 0
  br i1 %240, label %680, label %352

241:                                              ; preds = %535
  %242 = load ptr, ptr @stderr, align 8
  %243 = load i32, ptr %10, align 4
  %244 = load i32, ptr %6, align 4
  %245 = xor i32 %244, 1610683749
  %246 = mul nsw i32 %243, %245
  %247 = load i32, ptr %11, align 4
  %248 = or i32 %246, %247
  %249 = and i32 %246, %247
  %250 = add i32 %248, %249
  %251 = load ptr, ptr %9, align 8
  %252 = load i32, ptr %10, align 4
  %253 = load i32, ptr %6, align 4
  %254 = xor i32 %253, 1610683749
  %255 = mul nsw i32 %252, %254
  %256 = load i32, ptr %11, align 4
  %257 = xor i32 %255, %256
  %258 = and i32 %255, %256
  %259 = add i32 %258, %258
  %260 = add i32 %257, %259
  %261 = sext i32 %260 to i64
  %262 = getelementptr inbounds i32, ptr %251, i64 %261
  %263 = load i32, ptr %262, align 4
  %264 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %242, ptr noundef @.str.76, i32 noundef %250, i32 noundef %263) #9
  %265 = load i32, ptr %11, align 4
  %266 = icmp ne i32 %265, 3
  %267 = select i1 %266, i32 -2092739243, i32 1806734694
  store i32 %267, ptr %6, align 4
  %268 = xor i32 %5, 260056647
  %269 = and i32 %5, %268
  %270 = or i32 %5, %268
  %271 = xor i32 %5, %268
  %272 = mul i32 %270, 2
  %273 = sub i32 %272, %271
  %274 = sub i32 %273, %5
  %275 = sub i32 %274, %268
  %276 = mul i32 %275, 229
  %277 = icmp ugt i32 %276, 0
  br i1 %277, label %691, label %352

278:                                              ; preds = %545
  %279 = load ptr, ptr @stderr, align 8
  %280 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %279, ptr noundef @.str.73) #9
  store i32 1806734694, ptr %6, align 4
  %281 = xor i32 %5, 1192421643
  %282 = and i32 %5, %281
  %283 = or i32 %5, %281
  %284 = xor i32 %5, %281
  %285 = sub i32 %283, %284
  %286 = sub i32 %285, %282
  %287 = mul i32 %286, 63
  %288 = icmp ugt i32 %287, 0
  br i1 %288, label %700, label %352

289:                                              ; preds = %553
  %290 = load i32, ptr %11, align 4
  %291 = load i32, ptr %6, align 4
  %292 = xor i32 %291, 1806734695
  %293 = sub i32 %290, %292
  %294 = load i32, ptr %6, align 4
  %295 = xor i32 %294, 1806734692
  %296 = mul i32 %290, %295
  %297 = load i32, ptr %6, align 4
  %298 = xor i32 %297, 1806734695
  %299 = mul i32 %298, %293
  %300 = sub i32 %296, %299
  store i32 %300, ptr %11, align 4
  store i32 1134640052, ptr %6, align 4
  %301 = xor i32 %5, -1489090497
  %302 = and i32 %5, %301
  %303 = or i32 %5, %301
  %304 = xor i32 %5, %301
  %305 = add i32 %302, %303
  %306 = sub i32 %305, %5
  %307 = sub i32 %306, %301
  %308 = mul i32 %307, 208
  %309 = xor i32 %5, 1270496713
  %310 = and i32 %5, %309
  %311 = or i32 %5, %309
  %312 = xor i32 %5, %309
  %313 = add i32 %310, %311
  %314 = sub i32 %313, %5
  %315 = sub i32 %314, %309
  %316 = mul i32 %315, 69
  %317 = icmp ne i32 %308, %316
  br i1 %317, label %709, label %352

318:                                              ; preds = %505
  %319 = load ptr, ptr @stderr, align 8
  %320 = call i32 @fputc(i32 noundef 10, ptr noundef %319)
  %321 = load i32, ptr %10, align 4
  %322 = load i32, ptr %6, align 4
  %323 = xor i32 %322, 1542394509
  %324 = sub i32 %321, %323
  %325 = load i32, ptr %6, align 4
  %326 = xor i32 %325, 1542394510
  %327 = mul i32 %321, %326
  %328 = load i32, ptr %6, align 4
  %329 = xor i32 %328, 1542394509
  %330 = mul i32 %329, %324
  %331 = sub i32 %327, %330
  store i32 %331, ptr %10, align 4
  store i32 695257803, ptr %6, align 4
  %332 = xor i32 %5, -143853517
  %333 = and i32 %5, %332
  %334 = or i32 %5, %332
  %335 = xor i32 %5, %332
  %336 = add i32 %5, %332
  %337 = sub i32 %336, %335
  %338 = mul i32 %333, 2
  %339 = sub i32 %337, %338
  %340 = mul i32 %339, 255
  %341 = xor i32 %5, -1719698233
  %342 = and i32 %5, %341
  %343 = or i32 %5, %341
  %344 = xor i32 %5, %341
  %345 = add i32 %5, %341
  %346 = sub i32 %345, %344
  %347 = mul i32 %342, 2
  %348 = sub i32 %346, %347
  %349 = mul i32 %348, 48
  %350 = icmp ne i32 %340, %349
  br i1 %350, label %717, label %352

351:                                              ; preds = %551
  ret void

352:                                              ; preds = %802, %794, %783, %774, %766, %757, %748, %737, %717, %709, %700, %691, %680, %670, %660, %651, %643, %634, %624, %613, %604, %594, %585, %577, %568, %559, %466, %454, %432, %414, %401, %388, %375, %364, %318, %289, %278, %241, %227, %216, %194, %183, %163, %146, %133, %104, %84, %73, %59, %43, %32, %17
  br label %12

353:                                              ; preds = %557, %555, %549, %545, %539, %537, %531, %527, %517, %515, %509, %505, %499, %495, %493, %489
  store i32 1948098677, ptr %6, align 4
  call void asm sideeffect "", ""()
  %354 = xor i32 %5, 1720356643
  %355 = and i32 %5, %354
  %356 = or i32 %5, %354
  %357 = xor i32 %5, %354
  %358 = add i32 %5, %354
  %359 = sub i32 %358, %357
  %360 = mul i32 %355, 2
  %361 = sub i32 %359, %360
  %362 = mul i32 %361, 23
  %363 = icmp slt i32 %362, 1
  br i1 %363, label %12, label %727

364:                                              ; preds = %495
  %365 = load i32, ptr %6, align 4
  %366 = xor i32 %365, -1013764474
  store i32 %366, ptr %6, align 4
  %367 = xor i32 %5, -40418035
  %368 = and i32 %5, %367
  %369 = or i32 %5, %367
  %370 = xor i32 %5, %367
  %371 = sub i32 %369, %370
  %372 = sub i32 %371, %368
  %373 = mul i32 %372, 44
  %374 = icmp eq i32 %373, 0
  br i1 %374, label %352, label %737

375:                                              ; preds = %529
  %376 = load i32, ptr %6, align 4
  %377 = xor i32 %376, -292334379
  store i32 %377, ptr %6, align 4
  %378 = xor i32 %5, -532736055
  %379 = and i32 %5, %378
  %380 = or i32 %5, %378
  %381 = xor i32 %5, %378
  %382 = mul i32 %380, 2
  %383 = sub i32 %382, %381
  %384 = sub i32 %383, %5
  %385 = sub i32 %384, %378
  %386 = mul i32 %385, 248
  %387 = icmp sgt i32 %386, 0
  br i1 %387, label %748, label %352

388:                                              ; preds = %511
  %389 = load i32, ptr %6, align 4
  %390 = xor i32 %389, -686860739
  store i32 %390, ptr %6, align 4
  %391 = xor i32 %5, -1669142977
  %392 = and i32 %5, %391
  %393 = or i32 %5, %391
  %394 = xor i32 %5, %391
  %395 = mul i32 %393, 2
  %396 = sub i32 %395, %394
  %397 = sub i32 %396, %5
  %398 = sub i32 %397, %391
  %399 = mul i32 %398, 197
  %400 = icmp slt i32 %399, 1
  br i1 %400, label %352, label %757

401:                                              ; preds = %539
  %402 = load i32, ptr %6, align 4
  %403 = xor i32 %402, -1769799022
  store i32 %403, ptr %6, align 4
  %404 = xor i32 %5, -941502811
  %405 = and i32 %5, %404
  %406 = or i32 %5, %404
  %407 = xor i32 %5, %404
  %408 = mul i32 %406, 2
  %409 = sub i32 %408, %407
  %410 = sub i32 %409, %5
  %411 = sub i32 %410, %404
  %412 = mul i32 %411, 227
  %413 = icmp ne i32 %412, 0
  br i1 %413, label %766, label %352

414:                                              ; preds = %537
  %415 = load i32, ptr %6, align 4
  %416 = xor i32 %415, -1070046264
  store i32 %416, ptr %6, align 4
  %417 = xor i32 %5, 66205535
  %418 = and i32 %5, %417
  %419 = or i32 %5, %417
  %420 = xor i32 %5, %417
  %421 = sub i32 %419, %420
  %422 = sub i32 %421, %418
  %423 = mul i32 %422, 66
  %424 = xor i32 %5, -641366915
  %425 = and i32 %5, %424
  %426 = or i32 %5, %424
  %427 = xor i32 %5, %424
  %428 = sub i32 %426, %427
  %429 = sub i32 %428, %425
  %430 = mul i32 %429, 7
  %431 = icmp ne i32 %423, %430
  br i1 %431, label %774, label %352

432:                                              ; preds = %527
  %433 = load i32, ptr %6, align 4
  %434 = xor i32 %433, 1830749463
  store i32 %434, ptr %6, align 4
  %435 = xor i32 %5, -2134651597
  %436 = and i32 %5, %435
  %437 = or i32 %5, %435
  %438 = xor i32 %5, %435
  %439 = mul i32 %437, 2
  %440 = sub i32 %439, %438
  %441 = sub i32 %440, %5
  %442 = sub i32 %441, %435
  %443 = mul i32 %442, 216
  %444 = xor i32 %5, -1273779495
  %445 = and i32 %5, %444
  %446 = or i32 %5, %444
  %447 = xor i32 %5, %444
  %448 = mul i32 %446, 2
  %449 = sub i32 %448, %447
  %450 = sub i32 %449, %5
  %451 = sub i32 %450, %444
  %452 = mul i32 %451, 157
  %453 = icmp ne i32 %443, %452
  br i1 %453, label %783, label %352

454:                                              ; preds = %515
  %455 = load i32, ptr %6, align 4
  %456 = xor i32 %455, 1682595918
  store i32 %456, ptr %6, align 4
  %457 = xor i32 %5, 1714225473
  %458 = and i32 %5, %457
  %459 = or i32 %5, %457
  %460 = xor i32 %5, %457
  %461 = add i32 %458, %459
  %462 = sub i32 %461, %5
  %463 = sub i32 %462, %457
  %464 = mul i32 %463, 164
  %465 = icmp slt i32 %464, 1
  br i1 %465, label %352, label %794

466:                                              ; preds = %549
  %467 = load i32, ptr %6, align 4
  %468 = xor i32 %467, -1606635358
  store i32 %468, ptr %6, align 4
  %469 = xor i32 %5, -1528733821
  %470 = and i32 %5, %469
  %471 = or i32 %5, %469
  %472 = xor i32 %5, %469
  %473 = sub i32 %471, %472
  %474 = sub i32 %473, %470
  %475 = mul i32 %474, 216
  %476 = icmp eq i32 %475, 0
  br i1 %476, label %352, label %802

477:                                              ; preds = %12
  %478 = icmp slt i32 %15, 538366439
  br i1 %478, label %481, label %483

479:                                              ; preds = %12
  %480 = icmp slt i32 %15, 1785783632
  br i1 %480, label %519, label %521

481:                                              ; preds = %477
  %482 = icmp slt i32 %15, 401391599
  br i1 %482, label %485, label %487

483:                                              ; preds = %477
  %484 = icmp slt i32 %15, 835189548
  br i1 %484, label %501, label %503

485:                                              ; preds = %481
  %486 = icmp slt i32 %15, 167609503
  br i1 %486, label %489, label %491

487:                                              ; preds = %481
  %488 = icmp slt i32 %15, 401554245
  br i1 %488, label %495, label %497

489:                                              ; preds = %485
  %490 = icmp eq i32 %15, 140972480
  br i1 %490, label %183, label %353

491:                                              ; preds = %485
  %492 = icmp eq i32 %15, 167609503
  br i1 %492, label %59, label %493

493:                                              ; preds = %491
  %494 = icmp eq i32 %15, 219317411
  br i1 %494, label %84, label %353

495:                                              ; preds = %487
  %496 = icmp eq i32 %15, 401391599
  br i1 %496, label %364, label %353

497:                                              ; preds = %487
  %498 = icmp eq i32 %15, 401554245
  br i1 %498, label %133, label %499

499:                                              ; preds = %497
  %500 = icmp eq i32 %15, 439074394
  br i1 %500, label %32, label %353

501:                                              ; preds = %483
  %502 = icmp slt i32 %15, 696419440
  br i1 %502, label %505, label %507

503:                                              ; preds = %483
  %504 = icmp slt i32 %15, 1157313183
  br i1 %504, label %511, label %513

505:                                              ; preds = %501
  %506 = icmp eq i32 %15, 538366439
  br i1 %506, label %318, label %353

507:                                              ; preds = %501
  %508 = icmp eq i32 %15, 696419440
  br i1 %508, label %17, label %509

509:                                              ; preds = %507
  %510 = icmp eq i32 %15, 775092624
  br i1 %510, label %104, label %353

511:                                              ; preds = %503
  %512 = icmp eq i32 %15, 835189548
  br i1 %512, label %388, label %515

513:                                              ; preds = %503
  %514 = icmp eq i32 %15, 1157313183
  br i1 %514, label %146, label %517

515:                                              ; preds = %511
  %516 = icmp eq i32 %15, 836925916
  br i1 %516, label %454, label %353

517:                                              ; preds = %513
  %518 = icmp eq i32 %15, 1163214249
  br i1 %518, label %43, label %353

519:                                              ; preds = %479
  %520 = icmp slt i32 %15, 1371978057
  br i1 %520, label %523, label %525

521:                                              ; preds = %479
  %522 = icmp slt i32 %15, 1841742733
  br i1 %522, label %541, label %543

523:                                              ; preds = %519
  %524 = icmp slt i32 %15, 1239280024
  br i1 %524, label %527, label %529

525:                                              ; preds = %519
  %526 = icmp slt i32 %15, 1497264348
  br i1 %526, label %533, label %535

527:                                              ; preds = %523
  %528 = icmp eq i32 %15, 1195493774
  br i1 %528, label %432, label %353

529:                                              ; preds = %523
  %530 = icmp eq i32 %15, 1239280024
  br i1 %530, label %375, label %531

531:                                              ; preds = %529
  %532 = icmp eq i32 %15, 1345909662
  br i1 %532, label %73, label %353

533:                                              ; preds = %525
  %534 = icmp eq i32 %15, 1371978057
  br i1 %534, label %163, label %537

535:                                              ; preds = %525
  %536 = icmp eq i32 %15, 1497264348
  br i1 %536, label %241, label %539

537:                                              ; preds = %533
  %538 = icmp eq i32 %15, 1495356693
  br i1 %538, label %414, label %353

539:                                              ; preds = %535
  %540 = icmp eq i32 %15, 1560524986
  br i1 %540, label %401, label %353

541:                                              ; preds = %521
  %542 = icmp slt i32 %15, 1798862470
  br i1 %542, label %545, label %547

543:                                              ; preds = %521
  %544 = icmp slt i32 %15, 2078268161
  br i1 %544, label %551, label %553

545:                                              ; preds = %541
  %546 = icmp eq i32 %15, 1785783632
  br i1 %546, label %278, label %353

547:                                              ; preds = %541
  %548 = icmp eq i32 %15, 1798862470
  br i1 %548, label %194, label %549

549:                                              ; preds = %547
  %550 = icmp eq i32 %15, 1836087613
  br i1 %550, label %466, label %353

551:                                              ; preds = %543
  %552 = icmp eq i32 %15, 1841742733
  br i1 %552, label %351, label %555

553:                                              ; preds = %543
  %554 = icmp eq i32 %15, 2078268161
  br i1 %554, label %289, label %557

555:                                              ; preds = %551
  %556 = icmp eq i32 %15, 1978322030
  br i1 %556, label %216, label %353

557:                                              ; preds = %553
  %558 = icmp eq i32 %15, 2086988815
  br i1 %558, label %227, label %353

559:                                              ; preds = %17
  %560 = load i64, ptr %4, align 8
  %561 = ptrtoint ptr %0 to i64
  %562 = ptrtoint ptr %1 to i64
  %563 = ptrtoint ptr %2 to i64
  %564 = add i64 %563, %560
  %565 = sub i64 %564, %562
  %566 = or i64 %565, %562
  %567 = sub i64 %566, %561
  store i64 %567, ptr %4, align 8
  br label %352

568:                                              ; preds = %32
  %569 = load i64, ptr %4, align 8
  %570 = ptrtoint ptr %0 to i64
  %571 = ptrtoint ptr %1 to i64
  %572 = ptrtoint ptr %2 to i64
  %573 = or i64 %570, %571
  %574 = mul i64 %573, %570
  %575 = sub i64 %574, %572
  %576 = mul i64 %575, %571
  store i64 %576, ptr %4, align 8
  br label %352

577:                                              ; preds = %43
  %578 = load i64, ptr %4, align 8
  %579 = ptrtoint ptr %0 to i64
  %580 = ptrtoint ptr %1 to i64
  %581 = ptrtoint ptr %2 to i64
  %582 = xor i64 %581, %581
  %583 = and i64 %582, %579
  %584 = and i64 %583, %579
  store i64 %584, ptr %4, align 8
  br label %352

585:                                              ; preds = %59
  %586 = load i64, ptr %4, align 8
  %587 = ptrtoint ptr %0 to i64
  %588 = ptrtoint ptr %1 to i64
  %589 = ptrtoint ptr %2 to i64
  %590 = xor i64 %588, %587
  %591 = mul i64 %590, %589
  %592 = sub i64 %591, %588
  %593 = sub i64 %592, %589
  store i64 %593, ptr %4, align 8
  br label %352

594:                                              ; preds = %73
  %595 = load i64, ptr %4, align 8
  %596 = ptrtoint ptr %0 to i64
  %597 = ptrtoint ptr %1 to i64
  %598 = ptrtoint ptr %2 to i64
  %599 = mul i64 %598, %597
  %600 = sub i64 %599, %597
  %601 = and i64 %600, %598
  %602 = xor i64 %601, %595
  %603 = xor i64 %602, %598
  store i64 %603, ptr %4, align 8
  br label %352

604:                                              ; preds = %84
  %605 = load i64, ptr %4, align 8
  %606 = ptrtoint ptr %0 to i64
  %607 = ptrtoint ptr %1 to i64
  %608 = ptrtoint ptr %2 to i64
  %609 = mul i64 %605, %606
  %610 = mul i64 %609, %606
  %611 = or i64 %610, %606
  %612 = and i64 %611, %608
  store i64 %612, ptr %4, align 8
  br label %352

613:                                              ; preds = %104
  %614 = load i64, ptr %4, align 8
  %615 = ptrtoint ptr %0 to i64
  %616 = ptrtoint ptr %1 to i64
  %617 = ptrtoint ptr %2 to i64
  %618 = mul i64 %616, %616
  %619 = xor i64 %618, %617
  %620 = or i64 %619, %615
  %621 = and i64 %620, %617
  %622 = or i64 %621, %616
  %623 = and i64 %622, %617
  store i64 %623, ptr %4, align 8
  br label %352

624:                                              ; preds = %133
  %625 = load i64, ptr %4, align 8
  %626 = ptrtoint ptr %0 to i64
  %627 = ptrtoint ptr %1 to i64
  %628 = ptrtoint ptr %2 to i64
  %629 = xor i64 %627, %625
  %630 = mul i64 %629, %627
  %631 = mul i64 %630, %625
  %632 = and i64 %631, %626
  %633 = xor i64 %632, %625
  store i64 %633, ptr %4, align 8
  br label %352

634:                                              ; preds = %146
  %635 = load i64, ptr %4, align 8
  %636 = ptrtoint ptr %0 to i64
  %637 = ptrtoint ptr %1 to i64
  %638 = ptrtoint ptr %2 to i64
  %639 = xor i64 %635, %635
  %640 = and i64 %639, %637
  %641 = sub i64 %640, %636
  %642 = or i64 %641, %638
  store i64 %642, ptr %4, align 8
  br label %352

643:                                              ; preds = %163
  %644 = load i64, ptr %4, align 8
  %645 = ptrtoint ptr %0 to i64
  %646 = ptrtoint ptr %1 to i64
  %647 = ptrtoint ptr %2 to i64
  %648 = xor i64 %646, %645
  %649 = and i64 %648, %644
  %650 = or i64 %649, %646
  store i64 %650, ptr %4, align 8
  br label %352

651:                                              ; preds = %183
  %652 = load i64, ptr %4, align 8
  %653 = ptrtoint ptr %0 to i64
  %654 = ptrtoint ptr %1 to i64
  %655 = ptrtoint ptr %2 to i64
  %656 = add i64 %655, %653
  %657 = mul i64 %656, %654
  %658 = add i64 %657, %652
  %659 = xor i64 %658, %652
  store i64 %659, ptr %4, align 8
  br label %352

660:                                              ; preds = %194
  %661 = load i64, ptr %4, align 8
  %662 = ptrtoint ptr %0 to i64
  %663 = ptrtoint ptr %1 to i64
  %664 = ptrtoint ptr %2 to i64
  %665 = sub i64 %662, %663
  %666 = mul i64 %665, %661
  %667 = add i64 %666, %663
  %668 = xor i64 %667, %664
  %669 = mul i64 %668, %663
  store i64 %669, ptr %4, align 8
  br label %352

670:                                              ; preds = %216
  %671 = load i64, ptr %4, align 8
  %672 = ptrtoint ptr %0 to i64
  %673 = ptrtoint ptr %1 to i64
  %674 = ptrtoint ptr %2 to i64
  %675 = add i64 %674, %671
  %676 = and i64 %675, %674
  %677 = sub i64 %676, %673
  %678 = add i64 %677, %673
  %679 = or i64 %678, %672
  store i64 %679, ptr %4, align 8
  br label %352

680:                                              ; preds = %227
  %681 = load i64, ptr %4, align 8
  %682 = ptrtoint ptr %0 to i64
  %683 = ptrtoint ptr %1 to i64
  %684 = ptrtoint ptr %2 to i64
  %685 = mul i64 %682, %682
  %686 = and i64 %685, %684
  %687 = add i64 %686, %683
  %688 = and i64 %687, %683
  %689 = sub i64 %688, %683
  %690 = or i64 %689, %682
  store i64 %690, ptr %4, align 8
  br label %352

691:                                              ; preds = %241
  %692 = load i64, ptr %4, align 8
  %693 = ptrtoint ptr %0 to i64
  %694 = ptrtoint ptr %1 to i64
  %695 = ptrtoint ptr %2 to i64
  %696 = and i64 %692, %694
  %697 = or i64 %696, %693
  %698 = or i64 %697, %693
  %699 = sub i64 %698, %695
  store i64 %699, ptr %4, align 8
  br label %352

700:                                              ; preds = %278
  %701 = load i64, ptr %4, align 8
  %702 = ptrtoint ptr %0 to i64
  %703 = ptrtoint ptr %1 to i64
  %704 = ptrtoint ptr %2 to i64
  %705 = and i64 %704, %703
  %706 = or i64 %705, %703
  %707 = sub i64 %706, %704
  %708 = and i64 %707, %703
  store i64 %708, ptr %4, align 8
  br label %352

709:                                              ; preds = %289
  %710 = load i64, ptr %4, align 8
  %711 = ptrtoint ptr %0 to i64
  %712 = ptrtoint ptr %1 to i64
  %713 = ptrtoint ptr %2 to i64
  %714 = mul i64 %713, %711
  %715 = sub i64 %714, %711
  %716 = xor i64 %715, %711
  store i64 %716, ptr %4, align 8
  br label %352

717:                                              ; preds = %318
  %718 = load i64, ptr %4, align 8
  %719 = ptrtoint ptr %0 to i64
  %720 = ptrtoint ptr %1 to i64
  %721 = ptrtoint ptr %2 to i64
  %722 = or i64 %719, %718
  %723 = mul i64 %722, %720
  %724 = mul i64 %723, %721
  %725 = xor i64 %724, %721
  %726 = and i64 %725, %721
  store i64 %726, ptr %4, align 8
  br label %352

727:                                              ; preds = %353
  %728 = load i64, ptr %4, align 8
  %729 = ptrtoint ptr %0 to i64
  %730 = ptrtoint ptr %1 to i64
  %731 = ptrtoint ptr %2 to i64
  %732 = sub i64 %731, %731
  %733 = or i64 %732, %729
  %734 = xor i64 %733, %731
  %735 = add i64 %734, %729
  %736 = or i64 %735, %728
  store i64 %736, ptr %4, align 8
  br label %12

737:                                              ; preds = %364
  %738 = load i64, ptr %4, align 8
  %739 = ptrtoint ptr %0 to i64
  %740 = ptrtoint ptr %1 to i64
  %741 = ptrtoint ptr %2 to i64
  %742 = mul i64 %738, %740
  %743 = xor i64 %742, %741
  %744 = add i64 %743, %741
  %745 = mul i64 %744, %740
  %746 = xor i64 %745, %740
  %747 = add i64 %746, %738
  store i64 %747, ptr %4, align 8
  br label %352

748:                                              ; preds = %375
  %749 = load i64, ptr %4, align 8
  %750 = ptrtoint ptr %0 to i64
  %751 = ptrtoint ptr %1 to i64
  %752 = ptrtoint ptr %2 to i64
  %753 = and i64 %749, %751
  %754 = xor i64 %753, %750
  %755 = sub i64 %754, %749
  %756 = mul i64 %755, %750
  store i64 %756, ptr %4, align 8
  br label %352

757:                                              ; preds = %388
  %758 = load i64, ptr %4, align 8
  %759 = ptrtoint ptr %0 to i64
  %760 = ptrtoint ptr %1 to i64
  %761 = ptrtoint ptr %2 to i64
  %762 = mul i64 %759, %760
  %763 = mul i64 %762, %761
  %764 = or i64 %763, %760
  %765 = and i64 %764, %760
  store i64 %765, ptr %4, align 8
  br label %352

766:                                              ; preds = %401
  %767 = load i64, ptr %4, align 8
  %768 = ptrtoint ptr %0 to i64
  %769 = ptrtoint ptr %1 to i64
  %770 = ptrtoint ptr %2 to i64
  %771 = add i64 %770, %767
  %772 = xor i64 %771, %769
  %773 = xor i64 %772, %769
  store i64 %773, ptr %4, align 8
  br label %352

774:                                              ; preds = %414
  %775 = load i64, ptr %4, align 8
  %776 = ptrtoint ptr %0 to i64
  %777 = ptrtoint ptr %1 to i64
  %778 = ptrtoint ptr %2 to i64
  %779 = mul i64 %778, %775
  %780 = and i64 %779, %778
  %781 = and i64 %780, %775
  %782 = sub i64 %781, %778
  store i64 %782, ptr %4, align 8
  br label %352

783:                                              ; preds = %432
  %784 = load i64, ptr %4, align 8
  %785 = ptrtoint ptr %0 to i64
  %786 = ptrtoint ptr %1 to i64
  %787 = ptrtoint ptr %2 to i64
  %788 = mul i64 %786, %785
  %789 = mul i64 %788, %787
  %790 = or i64 %789, %785
  %791 = sub i64 %790, %784
  %792 = add i64 %791, %787
  %793 = or i64 %792, %784
  store i64 %793, ptr %4, align 8
  br label %352

794:                                              ; preds = %454
  %795 = load i64, ptr %4, align 8
  %796 = ptrtoint ptr %0 to i64
  %797 = ptrtoint ptr %1 to i64
  %798 = ptrtoint ptr %2 to i64
  %799 = mul i64 %795, %798
  %800 = and i64 %799, %797
  %801 = add i64 %800, %796
  store i64 %801, ptr %4, align 8
  br label %352

802:                                              ; preds = %466
  %803 = load i64, ptr %4, align 8
  %804 = ptrtoint ptr %0 to i64
  %805 = ptrtoint ptr %1 to i64
  %806 = ptrtoint ptr %2 to i64
  %807 = add i64 %803, %806
  %808 = add i64 %807, %806
  %809 = or i64 %808, %804
  %810 = sub i64 %809, %806
  store i64 %810, ptr %4, align 8
  br label %352
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_choose_round_function(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca i64, align 8
  store i64 0, ptr %5, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store i32 663251477, ptr %6, align 4
  br label %12

12:                                               ; preds = %393, %138, %137, %4
  %13 = load i32, ptr %6, align 4
  %14 = sub i32 %13, -1726157575
  %15 = mul i32 %14, -1430885557
  %16 = icmp slt i32 %15, 864139810
  br i1 %16, label %279, label %281

17:                                               ; preds = %301
  store i32 %0, ptr %8, align 4
  store i32 %1, ptr %9, align 4
  store i32 %2, ptr %10, align 4
  store i32 %3, ptr %11, align 4
  %18 = load i32, ptr %8, align 4
  %19 = icmp ult i32 %18, 16
  %20 = select i1 %19, i32 -1798696302, i32 -119746941
  store i32 %20, ptr %6, align 4
  %21 = xor i32 %0, -1786295289
  %22 = and i32 %0, %21
  %23 = or i32 %0, %21
  %24 = xor i32 %0, %21
  %25 = mul i32 %23, 2
  %26 = sub i32 %25, %24
  %27 = sub i32 %26, %0
  %28 = sub i32 %27, %21
  %29 = mul i32 %28, 87
  %30 = icmp uge i32 %29, 0
  br i1 %30, label %137, label %323

31:                                               ; preds = %315
  %32 = load i32, ptr %9, align 4
  %33 = load i32, ptr %10, align 4
  %34 = load i32, ptr %11, align 4
  %35 = call i32 @md5_f(i32 noundef %32, i32 noundef %33, i32 noundef %34)
  store i32 %35, ptr %7, align 4
  store i32 -791326506, ptr %6, align 4
  %36 = xor i32 %0, 1428204447
  %37 = and i32 %0, %36
  %38 = or i32 %0, %36
  %39 = xor i32 %0, %36
  %40 = add i32 %0, %36
  %41 = sub i32 %40, %39
  %42 = mul i32 %37, 2
  %43 = sub i32 %41, %42
  %44 = mul i32 %43, 42
  %45 = icmp sgt i32 %44, 0
  br i1 %45, label %334, label %137

46:                                               ; preds = %311
  %47 = load i32, ptr %8, align 4
  %48 = icmp ult i32 %47, 32
  %49 = select i1 %48, i32 10872488, i32 -693909398
  store i32 %49, ptr %6, align 4
  %50 = xor i32 %0, 1620400011
  %51 = and i32 %0, %50
  %52 = or i32 %0, %50
  %53 = xor i32 %0, %50
  %54 = mul i32 %52, 2
  %55 = sub i32 %54, %53
  %56 = sub i32 %55, %0
  %57 = sub i32 %56, %50
  %58 = mul i32 %57, 230
  %59 = icmp ne i32 %58, 0
  br i1 %59, label %343, label %137

60:                                               ; preds = %309
  %61 = load i32, ptr %9, align 4
  %62 = load i32, ptr %10, align 4
  %63 = load i32, ptr %11, align 4
  %64 = call i32 @md5_g(i32 noundef %61, i32 noundef %62, i32 noundef %63)
  store i32 %64, ptr %7, align 4
  store i32 -791326506, ptr %6, align 4
  %65 = xor i32 %0, 1461272795
  %66 = and i32 %0, %65
  %67 = or i32 %0, %65
  %68 = xor i32 %0, %65
  %69 = mul i32 %67, 2
  %70 = sub i32 %69, %68
  %71 = sub i32 %70, %0
  %72 = sub i32 %71, %65
  %73 = mul i32 %72, 39
  %74 = xor i32 %0, -266418969
  %75 = and i32 %0, %74
  %76 = or i32 %0, %74
  %77 = xor i32 %0, %74
  %78 = mul i32 %76, 2
  %79 = sub i32 %78, %77
  %80 = sub i32 %79, %0
  %81 = sub i32 %80, %74
  %82 = mul i32 %81, 216
  %83 = icmp eq i32 %73, %82
  br i1 %83, label %137, label %354

84:                                               ; preds = %319
  %85 = load i32, ptr %8, align 4
  %86 = icmp ult i32 %85, 48
  %87 = select i1 %86, i32 -1048568081, i32 799093791
  store i32 %87, ptr %6, align 4
  %88 = xor i32 %0, 1255719723
  %89 = and i32 %0, %88
  %90 = or i32 %0, %88
  %91 = xor i32 %0, %88
  %92 = add i32 %0, %88
  %93 = sub i32 %92, %91
  %94 = mul i32 %89, 2
  %95 = sub i32 %93, %94
  %96 = mul i32 %95, 161
  %97 = icmp uge i32 %96, 0
  br i1 %97, label %137, label %363

98:                                               ; preds = %297
  %99 = load i32, ptr %9, align 4
  %100 = load i32, ptr %10, align 4
  %101 = load i32, ptr %11, align 4
  %102 = call i32 @md5_h(i32 noundef %99, i32 noundef %100, i32 noundef %101)
  store i32 %102, ptr %7, align 4
  store i32 -791326506, ptr %6, align 4
  %103 = xor i32 %0, 808877977
  %104 = and i32 %0, %103
  %105 = or i32 %0, %103
  %106 = xor i32 %0, %103
  %107 = add i32 %0, %103
  %108 = sub i32 %107, %106
  %109 = mul i32 %104, 2
  %110 = sub i32 %108, %109
  %111 = mul i32 %110, 234
  %112 = icmp sgt i32 %111, 0
  br i1 %112, label %372, label %137

113:                                              ; preds = %307
  %114 = load i32, ptr %9, align 4
  %115 = load i32, ptr %10, align 4
  %116 = load i32, ptr %11, align 4
  %117 = call i32 @md5_i(i32 noundef %114, i32 noundef %115, i32 noundef %116)
  store i32 %117, ptr %7, align 4
  store i32 -791326506, ptr %6, align 4
  %118 = xor i32 %0, -1884923507
  %119 = and i32 %0, %118
  %120 = or i32 %0, %118
  %121 = xor i32 %0, %118
  %122 = mul i32 %120, 2
  %123 = sub i32 %122, %121
  %124 = sub i32 %123, %0
  %125 = sub i32 %124, %118
  %126 = mul i32 %125, 117
  %127 = xor i32 %0, -1251941189
  %128 = and i32 %0, %127
  %129 = or i32 %0, %127
  %130 = xor i32 %0, %127
  %131 = sub i32 %129, %130
  %132 = sub i32 %131, %128
  %133 = mul i32 %132, 16
  %134 = icmp eq i32 %126, %133
  br i1 %134, label %137, label %381

135:                                              ; preds = %293
  %136 = load i32, ptr %7, align 4
  ret i32 %136

137:                                              ; preds = %479, %468, %457, %445, %435, %426, %415, %404, %381, %372, %363, %354, %343, %334, %323, %261, %248, %235, %215, %195, %182, %160, %147, %113, %98, %84, %60, %46, %31, %17
  br label %12

138:                                              ; preds = %321, %319, %313, %311, %301, %299, %293, %291
  store i32 663251477, ptr %6, align 4
  call void asm sideeffect "", ""()
  %139 = xor i32 %0, 465720915
  %140 = and i32 %0, %139
  %141 = or i32 %0, %139
  %142 = xor i32 %0, %139
  %143 = sub i32 %141, %142
  %144 = sub i32 %143, %140
  %145 = mul i32 %144, 220
  %146 = icmp eq i32 %145, 0
  br i1 %146, label %12, label %393

147:                                              ; preds = %291
  %148 = load i32, ptr %6, align 4
  %149 = xor i32 %148, 101913965
  store i32 %149, ptr %6, align 4
  %150 = xor i32 %0, -1997516559
  %151 = and i32 %0, %150
  %152 = or i32 %0, %150
  %153 = xor i32 %0, %150
  %154 = add i32 %0, %150
  %155 = sub i32 %154, %153
  %156 = mul i32 %151, 2
  %157 = sub i32 %155, %156
  %158 = mul i32 %157, 114
  %159 = icmp sle i32 %158, 0
  br i1 %159, label %137, label %404

160:                                              ; preds = %317
  %161 = load i32, ptr %6, align 4
  %162 = xor i32 %161, -761878380
  store i32 %162, ptr %6, align 4
  %163 = xor i32 %0, 472129205
  %164 = and i32 %0, %163
  %165 = or i32 %0, %163
  %166 = xor i32 %0, %163
  %167 = mul i32 %165, 2
  %168 = sub i32 %167, %166
  %169 = sub i32 %168, %0
  %170 = sub i32 %169, %163
  %171 = mul i32 %170, 230
  %172 = xor i32 %0, -570031837
  %173 = and i32 %0, %172
  %174 = or i32 %0, %172
  %175 = xor i32 %0, %172
  %176 = mul i32 %174, 2
  %177 = sub i32 %176, %175
  %178 = sub i32 %177, %0
  %179 = sub i32 %178, %172
  %180 = mul i32 %179, 4
  %181 = icmp ne i32 %171, %180
  br i1 %181, label %415, label %137

182:                                              ; preds = %313
  %183 = load i32, ptr %6, align 4
  %184 = xor i32 %183, 286593548
  store i32 %184, ptr %6, align 4
  %185 = xor i32 %0, -289518489
  %186 = and i32 %0, %185
  %187 = or i32 %0, %185
  %188 = xor i32 %0, %185
  %189 = add i32 %0, %185
  %190 = sub i32 %189, %188
  %191 = mul i32 %186, 2
  %192 = sub i32 %190, %191
  %193 = mul i32 %192, 236
  %194 = icmp ugt i32 %193, 0
  br i1 %194, label %426, label %137

195:                                              ; preds = %299
  %196 = load i32, ptr %6, align 4
  %197 = xor i32 %196, -1336812628
  store i32 %197, ptr %6, align 4
  %198 = xor i32 %0, 14085205
  %199 = and i32 %0, %198
  %200 = or i32 %0, %198
  %201 = xor i32 %0, %198
  %202 = sub i32 %200, %201
  %203 = sub i32 %202, %199
  %204 = mul i32 %203, 147
  %205 = xor i32 %0, 2001780371
  %206 = and i32 %0, %205
  %207 = or i32 %0, %205
  %208 = xor i32 %0, %205
  %209 = add i32 %0, %205
  %210 = sub i32 %209, %208
  %211 = mul i32 %206, 2
  %212 = sub i32 %210, %211
  %213 = mul i32 %212, 25
  %214 = icmp ne i32 %204, %213
  br i1 %214, label %435, label %137

215:                                              ; preds = %321
  %216 = load i32, ptr %6, align 4
  %217 = xor i32 %216, 1274075674
  store i32 %217, ptr %6, align 4
  %218 = xor i32 %0, 1552197119
  %219 = and i32 %0, %218
  %220 = or i32 %0, %218
  %221 = xor i32 %0, %218
  %222 = mul i32 %220, 2
  %223 = sub i32 %222, %221
  %224 = sub i32 %223, %0
  %225 = sub i32 %224, %218
  %226 = mul i32 %225, 155
  %227 = xor i32 %0, -996960173
  %228 = and i32 %0, %227
  %229 = or i32 %0, %227
  %230 = xor i32 %0, %227
  %231 = sub i32 %229, %230
  %232 = sub i32 %231, %228
  %233 = mul i32 %232, 232
  %234 = icmp eq i32 %226, %233
  br i1 %234, label %137, label %445

235:                                              ; preds = %295
  %236 = load i32, ptr %6, align 4
  %237 = xor i32 %236, -1148610618
  store i32 %237, ptr %6, align 4
  %238 = xor i32 %0, -748195563
  %239 = and i32 %0, %238
  %240 = or i32 %0, %238
  %241 = xor i32 %0, %238
  %242 = mul i32 %240, 2
  %243 = sub i32 %242, %241
  %244 = sub i32 %243, %0
  %245 = sub i32 %244, %238
  %246 = mul i32 %245, 57
  %247 = icmp slt i32 %246, 0
  br i1 %247, label %457, label %137

248:                                              ; preds = %289
  %249 = load i32, ptr %6, align 4
  %250 = xor i32 %249, -1320449376
  store i32 %250, ptr %6, align 4
  %251 = xor i32 %0, -1545645919
  %252 = and i32 %0, %251
  %253 = or i32 %0, %251
  %254 = xor i32 %0, %251
  %255 = mul i32 %253, 2
  %256 = sub i32 %255, %254
  %257 = sub i32 %256, %0
  %258 = sub i32 %257, %251
  %259 = mul i32 %258, 47
  %260 = icmp ugt i32 %259, 0
  br i1 %260, label %468, label %137

261:                                              ; preds = %287
  %262 = load i32, ptr %6, align 4
  %263 = xor i32 %262, 1366904579
  store i32 %263, ptr %6, align 4
  %264 = xor i32 %0, -757090507
  %265 = and i32 %0, %264
  %266 = or i32 %0, %264
  %267 = xor i32 %0, %264
  %268 = sub i32 %266, %267
  %269 = sub i32 %268, %265
  %270 = mul i32 %269, 194
  %271 = xor i32 %0, 1132594769
  %272 = and i32 %0, %271
  %273 = or i32 %0, %271
  %274 = xor i32 %0, %271
  %275 = sub i32 %273, %274
  %276 = sub i32 %275, %272
  %277 = mul i32 %276, 132
  %278 = icmp ne i32 %270, %277
  br i1 %278, label %479, label %137

279:                                              ; preds = %12
  %280 = icmp slt i32 %15, 667542334
  br i1 %280, label %283, label %285

281:                                              ; preds = %12
  %282 = icmp slt i32 %15, 1865873107
  br i1 %282, label %303, label %305

283:                                              ; preds = %279
  %284 = icmp slt i32 %15, 394211453
  br i1 %284, label %287, label %289

285:                                              ; preds = %279
  %286 = icmp slt i32 %15, 735409426
  br i1 %286, label %295, label %297

287:                                              ; preds = %283
  %288 = icmp eq i32 %15, 257947842
  br i1 %288, label %261, label %291

289:                                              ; preds = %283
  %290 = icmp eq i32 %15, 394211453
  br i1 %290, label %248, label %293

291:                                              ; preds = %287
  %292 = icmp eq i32 %15, 267599620
  br i1 %292, label %147, label %138

293:                                              ; preds = %289
  %294 = icmp eq i32 %15, 635478207
  br i1 %294, label %135, label %138

295:                                              ; preds = %285
  %296 = icmp eq i32 %15, 667542334
  br i1 %296, label %235, label %299

297:                                              ; preds = %285
  %298 = icmp eq i32 %15, 735409426
  br i1 %298, label %98, label %301

299:                                              ; preds = %295
  %300 = icmp eq i32 %15, 683011794
  br i1 %300, label %195, label %138

301:                                              ; preds = %297
  %302 = icmp eq i32 %15, 816864052
  br i1 %302, label %17, label %138

303:                                              ; preds = %281
  %304 = icmp slt i32 %15, 1307003717
  br i1 %304, label %307, label %309

305:                                              ; preds = %281
  %306 = icmp slt i32 %15, 1984964004
  br i1 %306, label %315, label %317

307:                                              ; preds = %303
  %308 = icmp eq i32 %15, 864139810
  br i1 %308, label %113, label %311

309:                                              ; preds = %303
  %310 = icmp eq i32 %15, 1307003717
  br i1 %310, label %60, label %313

311:                                              ; preds = %307
  %312 = icmp eq i32 %15, 1016578414
  br i1 %312, label %46, label %138

313:                                              ; preds = %309
  %314 = icmp eq i32 %15, 1419889189
  br i1 %314, label %182, label %138

315:                                              ; preds = %305
  %316 = icmp eq i32 %15, 1865873107
  br i1 %316, label %31, label %319

317:                                              ; preds = %305
  %318 = icmp eq i32 %15, 1984964004
  br i1 %318, label %160, label %321

319:                                              ; preds = %315
  %320 = icmp eq i32 %15, 1888519451
  br i1 %320, label %84, label %138

321:                                              ; preds = %317
  %322 = icmp eq i32 %15, 2061877497
  br i1 %322, label %215, label %138

323:                                              ; preds = %17
  %324 = load i64, ptr %5, align 8
  %325 = zext i32 %0 to i64
  %326 = zext i32 %1 to i64
  %327 = zext i32 %2 to i64
  %328 = zext i32 %3 to i64
  %329 = mul i64 %325, %325
  %330 = mul i64 %329, %328
  %331 = and i64 %330, %324
  %332 = mul i64 %331, %324
  %333 = and i64 %332, %326
  store i64 %333, ptr %5, align 8
  br label %137

334:                                              ; preds = %31
  %335 = load i64, ptr %5, align 8
  %336 = zext i32 %0 to i64
  %337 = zext i32 %1 to i64
  %338 = zext i32 %2 to i64
  %339 = zext i32 %3 to i64
  %340 = or i64 %337, %336
  %341 = sub i64 %340, %337
  %342 = and i64 %341, %335
  store i64 %342, ptr %5, align 8
  br label %137

343:                                              ; preds = %46
  %344 = load i64, ptr %5, align 8
  %345 = zext i32 %0 to i64
  %346 = zext i32 %1 to i64
  %347 = zext i32 %2 to i64
  %348 = zext i32 %3 to i64
  %349 = add i64 %347, %345
  %350 = or i64 %349, %348
  %351 = sub i64 %350, %347
  %352 = add i64 %351, %345
  %353 = sub i64 %352, %345
  store i64 %353, ptr %5, align 8
  br label %137

354:                                              ; preds = %60
  %355 = load i64, ptr %5, align 8
  %356 = zext i32 %0 to i64
  %357 = zext i32 %1 to i64
  %358 = zext i32 %2 to i64
  %359 = zext i32 %3 to i64
  %360 = xor i64 %358, %358
  %361 = sub i64 %360, %358
  %362 = xor i64 %361, %358
  store i64 %362, ptr %5, align 8
  br label %137

363:                                              ; preds = %84
  %364 = load i64, ptr %5, align 8
  %365 = zext i32 %0 to i64
  %366 = zext i32 %1 to i64
  %367 = zext i32 %2 to i64
  %368 = zext i32 %3 to i64
  %369 = and i64 %364, %366
  %370 = xor i64 %369, %364
  %371 = mul i64 %370, %366
  store i64 %371, ptr %5, align 8
  br label %137

372:                                              ; preds = %98
  %373 = load i64, ptr %5, align 8
  %374 = zext i32 %0 to i64
  %375 = zext i32 %1 to i64
  %376 = zext i32 %2 to i64
  %377 = zext i32 %3 to i64
  %378 = or i64 %374, %376
  %379 = or i64 %378, %374
  %380 = or i64 %379, %373
  store i64 %380, ptr %5, align 8
  br label %137

381:                                              ; preds = %113
  %382 = load i64, ptr %5, align 8
  %383 = zext i32 %0 to i64
  %384 = zext i32 %1 to i64
  %385 = zext i32 %2 to i64
  %386 = zext i32 %3 to i64
  %387 = mul i64 %382, %384
  %388 = mul i64 %387, %385
  %389 = mul i64 %388, %384
  %390 = add i64 %389, %383
  %391 = sub i64 %390, %384
  %392 = xor i64 %391, %382
  store i64 %392, ptr %5, align 8
  br label %137

393:                                              ; preds = %138
  %394 = load i64, ptr %5, align 8
  %395 = zext i32 %0 to i64
  %396 = zext i32 %1 to i64
  %397 = zext i32 %2 to i64
  %398 = zext i32 %3 to i64
  %399 = or i64 %398, %398
  %400 = add i64 %399, %397
  %401 = xor i64 %400, %394
  %402 = sub i64 %401, %394
  %403 = sub i64 %402, %395
  store i64 %403, ptr %5, align 8
  br label %12

404:                                              ; preds = %147
  %405 = load i64, ptr %5, align 8
  %406 = zext i32 %0 to i64
  %407 = zext i32 %1 to i64
  %408 = zext i32 %2 to i64
  %409 = zext i32 %3 to i64
  %410 = add i64 %407, %406
  %411 = add i64 %410, %406
  %412 = add i64 %411, %407
  %413 = mul i64 %412, %408
  %414 = xor i64 %413, %408
  store i64 %414, ptr %5, align 8
  br label %137

415:                                              ; preds = %160
  %416 = load i64, ptr %5, align 8
  %417 = zext i32 %0 to i64
  %418 = zext i32 %1 to i64
  %419 = zext i32 %2 to i64
  %420 = zext i32 %3 to i64
  %421 = and i64 %416, %418
  %422 = add i64 %421, %417
  %423 = and i64 %422, %416
  %424 = add i64 %423, %419
  %425 = add i64 %424, %418
  store i64 %425, ptr %5, align 8
  br label %137

426:                                              ; preds = %182
  %427 = load i64, ptr %5, align 8
  %428 = zext i32 %0 to i64
  %429 = zext i32 %1 to i64
  %430 = zext i32 %2 to i64
  %431 = zext i32 %3 to i64
  %432 = add i64 %428, %427
  %433 = and i64 %432, %429
  %434 = xor i64 %433, %427
  store i64 %434, ptr %5, align 8
  br label %137

435:                                              ; preds = %195
  %436 = load i64, ptr %5, align 8
  %437 = zext i32 %0 to i64
  %438 = zext i32 %1 to i64
  %439 = zext i32 %2 to i64
  %440 = zext i32 %3 to i64
  %441 = or i64 %438, %436
  %442 = and i64 %441, %438
  %443 = add i64 %442, %436
  %444 = and i64 %443, %440
  store i64 %444, ptr %5, align 8
  br label %137

445:                                              ; preds = %215
  %446 = load i64, ptr %5, align 8
  %447 = zext i32 %0 to i64
  %448 = zext i32 %1 to i64
  %449 = zext i32 %2 to i64
  %450 = zext i32 %3 to i64
  %451 = sub i64 %450, %447
  %452 = xor i64 %451, %447
  %453 = and i64 %452, %446
  %454 = and i64 %453, %449
  %455 = xor i64 %454, %447
  %456 = xor i64 %455, %449
  store i64 %456, ptr %5, align 8
  br label %137

457:                                              ; preds = %235
  %458 = load i64, ptr %5, align 8
  %459 = zext i32 %0 to i64
  %460 = zext i32 %1 to i64
  %461 = zext i32 %2 to i64
  %462 = zext i32 %3 to i64
  %463 = xor i64 %462, %460
  %464 = and i64 %463, %460
  %465 = sub i64 %464, %458
  %466 = add i64 %465, %458
  %467 = xor i64 %466, %458
  store i64 %467, ptr %5, align 8
  br label %137

468:                                              ; preds = %248
  %469 = load i64, ptr %5, align 8
  %470 = zext i32 %0 to i64
  %471 = zext i32 %1 to i64
  %472 = zext i32 %2 to i64
  %473 = zext i32 %3 to i64
  %474 = sub i64 %471, %469
  %475 = add i64 %474, %473
  %476 = or i64 %475, %469
  %477 = xor i64 %476, %473
  %478 = sub i64 %477, %472
  store i64 %478, ptr %5, align 8
  br label %137

479:                                              ; preds = %261
  %480 = load i64, ptr %5, align 8
  %481 = zext i32 %0 to i64
  %482 = zext i32 %1 to i64
  %483 = zext i32 %2 to i64
  %484 = zext i32 %3 to i64
  %485 = and i64 %483, %482
  %486 = xor i64 %485, %484
  %487 = or i64 %486, %483
  %488 = xor i64 %487, %482
  store i64 %488, ptr %5, align 8
  br label %137
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @md5_choose_message_index(i32 noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 -911019871, ptr %3, align 4
  br label %6

6:                                                ; preds = %373, %152, %151, %1
  %7 = load i32, ptr %3, align 4
  %8 = sub i32 %7, 1826171108
  %9 = mul i32 %8, -1128549887
  %10 = icmp slt i32 %9, 1019599930
  br i1 %10, label %278, label %280

11:                                               ; preds = %320
  store i32 %0, ptr %5, align 4
  %12 = load i32, ptr %5, align 4
  %13 = icmp ult i32 %12, 16
  %14 = select i1 %13, i32 627508245, i32 -1356177765
  store i32 %14, ptr %3, align 4
  %15 = xor i32 %0, 206010539
  %16 = and i32 %0, %15
  %17 = or i32 %0, %15
  %18 = xor i32 %0, %15
  %19 = mul i32 %17, 2
  %20 = sub i32 %19, %18
  %21 = sub i32 %20, %0
  %22 = sub i32 %21, %15
  %23 = mul i32 %22, 238
  %24 = icmp slt i32 %23, 0
  br i1 %24, label %322, label %151

25:                                               ; preds = %316
  %26 = load i32, ptr %5, align 4
  store i32 %26, ptr %4, align 4
  store i32 366297428, ptr %3, align 4
  %27 = xor i32 %0, -265141579
  %28 = and i32 %0, %27
  %29 = or i32 %0, %27
  %30 = xor i32 %0, %27
  %31 = add i32 %0, %27
  %32 = sub i32 %31, %30
  %33 = mul i32 %28, 2
  %34 = sub i32 %32, %33
  %35 = mul i32 %34, 51
  %36 = icmp uge i32 %35, 0
  br i1 %36, label %151, label %329

37:                                               ; preds = %312
  %38 = load i32, ptr %5, align 4
  %39 = icmp ult i32 %38, 32
  %40 = select i1 %39, i32 -801913783, i32 1692764306
  store i32 %40, ptr %3, align 4
  %41 = xor i32 %0, -761267101
  %42 = and i32 %0, %41
  %43 = or i32 %0, %41
  %44 = xor i32 %0, %41
  %45 = sub i32 %43, %44
  %46 = sub i32 %45, %42
  %47 = mul i32 %46, 243
  %48 = icmp ne i32 %47, 0
  br i1 %48, label %337, label %151

49:                                               ; preds = %294
  %50 = load i32, ptr %5, align 4
  %51 = load i32, ptr %3, align 4
  %52 = xor i32 %51, -801913780
  %53 = mul i32 %52, %50
  %54 = load i32, ptr %3, align 4
  %55 = xor i32 %54, -801913784
  %56 = xor i32 %53, %55
  %57 = load i32, ptr %3, align 4
  %58 = xor i32 %57, -801913784
  %59 = and i32 %53, %58
  %60 = add i32 %59, %59
  %61 = add i32 %56, %60
  %62 = load i32, ptr %3, align 4
  %63 = xor i32 %62, -801913786
  %64 = add i32 %61, %63
  %65 = load i32, ptr %3, align 4
  %66 = xor i32 %65, -801913786
  %67 = or i32 %61, %66
  %68 = sub i32 %64, %67
  store i32 %68, ptr %4, align 4
  store i32 366297428, ptr %3, align 4
  %69 = xor i32 %0, -1626328383
  %70 = and i32 %0, %69
  %71 = or i32 %0, %69
  %72 = xor i32 %0, %69
  %73 = add i32 %0, %69
  %74 = sub i32 %73, %72
  %75 = mul i32 %70, 2
  %76 = sub i32 %74, %75
  %77 = mul i32 %76, 226
  %78 = icmp uge i32 %77, 0
  br i1 %78, label %151, label %343

79:                                               ; preds = %310
  %80 = load i32, ptr %5, align 4
  %81 = icmp ult i32 %80, 48
  %82 = select i1 %81, i32 959476156, i32 -2104970978
  store i32 %82, ptr %3, align 4
  %83 = xor i32 %0, 464886147
  %84 = and i32 %0, %83
  %85 = or i32 %0, %83
  %86 = xor i32 %0, %83
  %87 = sub i32 %85, %86
  %88 = sub i32 %87, %84
  %89 = mul i32 %88, 17
  %90 = icmp uge i32 %89, 0
  br i1 %90, label %151, label %349

91:                                               ; preds = %308
  %92 = load i32, ptr %5, align 4
  %93 = load i32, ptr %3, align 4
  %94 = xor i32 %93, 959476159
  %95 = mul i32 %94, %92
  %96 = load i32, ptr %3, align 4
  %97 = xor i32 %96, 959476153
  %98 = or i32 %95, %97
  %99 = load i32, ptr %3, align 4
  %100 = xor i32 %99, 959476153
  %101 = and i32 %95, %100
  %102 = add i32 %98, %101
  %103 = load i32, ptr %3, align 4
  %104 = xor i32 %103, 959476147
  %105 = add i32 %102, %104
  %106 = load i32, ptr %3, align 4
  %107 = xor i32 %106, 959476147
  %108 = or i32 %102, %107
  %109 = sub i32 %105, %108
  store i32 %109, ptr %4, align 4
  store i32 366297428, ptr %3, align 4
  %110 = xor i32 %0, 1594012647
  %111 = and i32 %0, %110
  %112 = or i32 %0, %110
  %113 = xor i32 %0, %110
  %114 = add i32 %0, %110
  %115 = sub i32 %114, %113
  %116 = mul i32 %111, 2
  %117 = sub i32 %115, %116
  %118 = mul i32 %117, 20
  %119 = icmp sgt i32 %118, 0
  br i1 %119, label %356, label %151

120:                                              ; preds = %306
  %121 = load i32, ptr %5, align 4
  %122 = load i32, ptr %3, align 4
  %123 = xor i32 %122, -2104970983
  %124 = mul i32 %123, %121
  %125 = load i32, ptr %3, align 4
  %126 = xor i32 %125, -2104970991
  %127 = add i32 %124, %126
  %128 = load i32, ptr %3, align 4
  %129 = xor i32 %128, -2104970991
  %130 = or i32 %124, %129
  %131 = sub i32 %127, %130
  store i32 %131, ptr %4, align 4
  store i32 366297428, ptr %3, align 4
  %132 = xor i32 %0, -712483291
  %133 = and i32 %0, %132
  %134 = or i32 %0, %132
  %135 = xor i32 %0, %132
  %136 = add i32 %133, %134
  %137 = sub i32 %136, %0
  %138 = sub i32 %137, %132
  %139 = mul i32 %138, 15
  %140 = xor i32 %0, 1359971157
  %141 = and i32 %0, %140
  %142 = or i32 %0, %140
  %143 = xor i32 %0, %140
  %144 = add i32 %141, %142
  %145 = sub i32 %144, %0
  %146 = sub i32 %145, %140
  %147 = mul i32 %146, 6
  %148 = icmp eq i32 %139, %147
  br i1 %148, label %151, label %364

149:                                              ; preds = %286
  %150 = load i32, ptr %4, align 4
  ret i32 %150

151:                                              ; preds = %438, %429, %420, %412, %403, %397, %389, %382, %364, %356, %349, %343, %337, %329, %322, %267, %256, %243, %230, %209, %198, %185, %163, %120, %91, %79, %49, %37, %25, %11
  br label %6

152:                                              ; preds = %320, %318, %312, %310, %300, %298, %292, %290
  store i32 -911019871, ptr %3, align 4
  call void asm sideeffect "", ""()
  %153 = xor i32 %0, -897371503
  %154 = and i32 %0, %153
  %155 = or i32 %0, %153
  %156 = xor i32 %0, %153
  %157 = mul i32 %155, 2
  %158 = sub i32 %157, %156
  %159 = sub i32 %158, %0
  %160 = sub i32 %159, %153
  %161 = mul i32 %160, 45
  %162 = icmp slt i32 %161, 1
  br i1 %162, label %6, label %373

163:                                              ; preds = %314
  %164 = load i32, ptr %3, align 4
  %165 = xor i32 %164, 308330149
  store i32 %165, ptr %3, align 4
  %166 = xor i32 %0, -1883549831
  %167 = and i32 %0, %166
  %168 = or i32 %0, %166
  %169 = xor i32 %0, %166
  %170 = mul i32 %168, 2
  %171 = sub i32 %170, %169
  %172 = sub i32 %171, %0
  %173 = sub i32 %172, %166
  %174 = mul i32 %173, 49
  %175 = xor i32 %0, 696782283
  %176 = and i32 %0, %175
  %177 = or i32 %0, %175
  %178 = xor i32 %0, %175
  %179 = mul i32 %177, 2
  %180 = sub i32 %179, %178
  %181 = sub i32 %180, %0
  %182 = sub i32 %181, %175
  %183 = mul i32 %182, 86
  %184 = icmp eq i32 %174, %183
  br i1 %184, label %151, label %382

185:                                              ; preds = %318
  %186 = load i32, ptr %3, align 4
  %187 = xor i32 %186, 339749116
  store i32 %187, ptr %3, align 4
  %188 = xor i32 %0, 1804080975
  %189 = and i32 %0, %188
  %190 = or i32 %0, %188
  %191 = xor i32 %0, %188
  %192 = add i32 %0, %188
  %193 = sub i32 %192, %191
  %194 = mul i32 %189, 2
  %195 = sub i32 %193, %194
  %196 = mul i32 %195, 209
  %197 = icmp ne i32 %196, 0
  br i1 %197, label %389, label %151

198:                                              ; preds = %288
  %199 = load i32, ptr %3, align 4
  %200 = xor i32 %199, 1338353442
  store i32 %200, ptr %3, align 4
  %201 = xor i32 %0, -1363896519
  %202 = and i32 %0, %201
  %203 = or i32 %0, %201
  %204 = xor i32 %0, %201
  %205 = sub i32 %203, %204
  %206 = sub i32 %205, %202
  %207 = mul i32 %206, 47
  %208 = icmp ugt i32 %207, 0
  br i1 %208, label %397, label %151

209:                                              ; preds = %290
  %210 = load i32, ptr %3, align 4
  %211 = xor i32 %210, 1512104419
  store i32 %211, ptr %3, align 4
  %212 = xor i32 %0, -1196960887
  %213 = and i32 %0, %212
  %214 = or i32 %0, %212
  %215 = xor i32 %0, %212
  %216 = add i32 %213, %214
  %217 = sub i32 %216, %0
  %218 = sub i32 %217, %212
  %219 = mul i32 %218, 93
  %220 = xor i32 %0, 71878081
  %221 = and i32 %0, %220
  %222 = or i32 %0, %220
  %223 = xor i32 %0, %220
  %224 = mul i32 %222, 2
  %225 = sub i32 %224, %223
  %226 = sub i32 %225, %0
  %227 = sub i32 %226, %220
  %228 = mul i32 %227, 69
  %229 = icmp ne i32 %219, %228
  br i1 %229, label %403, label %151

230:                                              ; preds = %300
  %231 = load i32, ptr %3, align 4
  %232 = xor i32 %231, -139446615
  store i32 %232, ptr %3, align 4
  %233 = xor i32 %0, -256773101
  %234 = and i32 %0, %233
  %235 = or i32 %0, %233
  %236 = xor i32 %0, %233
  %237 = add i32 %0, %233
  %238 = sub i32 %237, %236
  %239 = mul i32 %234, 2
  %240 = sub i32 %238, %239
  %241 = mul i32 %240, 92
  %242 = icmp eq i32 %241, 0
  br i1 %242, label %151, label %412

243:                                              ; preds = %292
  %244 = load i32, ptr %3, align 4
  %245 = xor i32 %244, 26962090
  store i32 %245, ptr %3, align 4
  %246 = xor i32 %0, -1036787977
  %247 = and i32 %0, %246
  %248 = or i32 %0, %246
  %249 = xor i32 %0, %246
  %250 = mul i32 %248, 2
  %251 = sub i32 %250, %249
  %252 = sub i32 %251, %0
  %253 = sub i32 %252, %246
  %254 = mul i32 %253, 210
  %255 = icmp slt i32 %254, 1
  br i1 %255, label %151, label %420

256:                                              ; preds = %298
  %257 = load i32, ptr %3, align 4
  %258 = xor i32 %257, 62373288
  store i32 %258, ptr %3, align 4
  %259 = xor i32 %0, 1178810645
  %260 = and i32 %0, %259
  %261 = or i32 %0, %259
  %262 = xor i32 %0, %259
  %263 = sub i32 %261, %262
  %264 = sub i32 %263, %260
  %265 = mul i32 %264, 93
  %266 = icmp eq i32 %265, 0
  br i1 %266, label %151, label %429

267:                                              ; preds = %296
  %268 = load i32, ptr %3, align 4
  %269 = xor i32 %268, -62594252
  store i32 %269, ptr %3, align 4
  %270 = xor i32 %0, -1080855731
  %271 = and i32 %0, %270
  %272 = or i32 %0, %270
  %273 = xor i32 %0, %270
  %274 = sub i32 %272, %273
  %275 = sub i32 %274, %271
  %276 = mul i32 %275, 14
  %277 = icmp eq i32 %276, 0
  br i1 %277, label %151, label %438

278:                                              ; preds = %6
  %279 = icmp slt i32 %9, 304993637
  br i1 %279, label %282, label %284

280:                                              ; preds = %6
  %281 = icmp slt i32 %9, 1855590416
  br i1 %281, label %302, label %304

282:                                              ; preds = %278
  %283 = icmp slt i32 %9, 235742566
  br i1 %283, label %286, label %288

284:                                              ; preds = %278
  %285 = icmp slt i32 %9, 838269781
  br i1 %285, label %294, label %296

286:                                              ; preds = %282
  %287 = icmp eq i32 %9, 197785712
  br i1 %287, label %149, label %290

288:                                              ; preds = %282
  %289 = icmp eq i32 %9, 235742566
  br i1 %289, label %198, label %292

290:                                              ; preds = %286
  %291 = icmp eq i32 %9, 209394648
  br i1 %291, label %209, label %152

292:                                              ; preds = %288
  %293 = icmp eq i32 %9, 276397433
  br i1 %293, label %243, label %152

294:                                              ; preds = %284
  %295 = icmp eq i32 %9, 304993637
  br i1 %295, label %49, label %298

296:                                              ; preds = %284
  %297 = icmp eq i32 %9, 838269781
  br i1 %297, label %267, label %300

298:                                              ; preds = %294
  %299 = icmp eq i32 %9, 533876871
  br i1 %299, label %256, label %152

300:                                              ; preds = %296
  %301 = icmp eq i32 %9, 945019866
  br i1 %301, label %230, label %152

302:                                              ; preds = %280
  %303 = icmp slt i32 %9, 1388673240
  br i1 %303, label %306, label %308

304:                                              ; preds = %280
  %305 = icmp slt i32 %9, 1942023473
  br i1 %305, label %314, label %316

306:                                              ; preds = %302
  %307 = icmp eq i32 %9, 1019599930
  br i1 %307, label %120, label %310

308:                                              ; preds = %302
  %309 = icmp eq i32 %9, 1388673240
  br i1 %309, label %91, label %312

310:                                              ; preds = %306
  %311 = icmp eq i32 %9, 1051548590
  br i1 %311, label %79, label %152

312:                                              ; preds = %308
  %313 = icmp eq i32 %9, 1515680695
  br i1 %313, label %37, label %152

314:                                              ; preds = %304
  %315 = icmp eq i32 %9, 1855590416
  br i1 %315, label %163, label %318

316:                                              ; preds = %304
  %317 = icmp eq i32 %9, 1942023473
  br i1 %317, label %25, label %320

318:                                              ; preds = %314
  %319 = icmp eq i32 %9, 1859356751
  br i1 %319, label %185, label %152

320:                                              ; preds = %316
  %321 = icmp eq i32 %9, 2093625789
  br i1 %321, label %11, label %152

322:                                              ; preds = %11
  %323 = load i64, ptr %2, align 8
  %324 = zext i32 %0 to i64
  %325 = and i64 %323, %323
  %326 = add i64 %325, %324
  %327 = or i64 %326, %324
  %328 = or i64 %327, %323
  store i64 %328, ptr %2, align 8
  br label %151

329:                                              ; preds = %25
  %330 = load i64, ptr %2, align 8
  %331 = zext i32 %0 to i64
  %332 = xor i64 %330, %331
  %333 = add i64 %332, %331
  %334 = or i64 %333, %331
  %335 = add i64 %334, %331
  %336 = and i64 %335, %330
  store i64 %336, ptr %2, align 8
  br label %151

337:                                              ; preds = %37
  %338 = load i64, ptr %2, align 8
  %339 = zext i32 %0 to i64
  %340 = add i64 %338, %339
  %341 = or i64 %340, %338
  %342 = add i64 %341, %339
  store i64 %342, ptr %2, align 8
  br label %151

343:                                              ; preds = %49
  %344 = load i64, ptr %2, align 8
  %345 = zext i32 %0 to i64
  %346 = sub i64 %344, %345
  %347 = or i64 %346, %344
  %348 = and i64 %347, %345
  store i64 %348, ptr %2, align 8
  br label %151

349:                                              ; preds = %79
  %350 = load i64, ptr %2, align 8
  %351 = zext i32 %0 to i64
  %352 = add i64 %350, %351
  %353 = sub i64 %352, %351
  %354 = sub i64 %353, %350
  %355 = xor i64 %354, %351
  store i64 %355, ptr %2, align 8
  br label %151

356:                                              ; preds = %91
  %357 = load i64, ptr %2, align 8
  %358 = zext i32 %0 to i64
  %359 = add i64 %358, %357
  %360 = and i64 %359, %358
  %361 = add i64 %360, %358
  %362 = and i64 %361, %357
  %363 = mul i64 %362, %358
  store i64 %363, ptr %2, align 8
  br label %151

364:                                              ; preds = %120
  %365 = load i64, ptr %2, align 8
  %366 = zext i32 %0 to i64
  %367 = or i64 %365, %365
  %368 = and i64 %367, %365
  %369 = xor i64 %368, %366
  %370 = or i64 %369, %365
  %371 = sub i64 %370, %366
  %372 = mul i64 %371, %365
  store i64 %372, ptr %2, align 8
  br label %151

373:                                              ; preds = %152
  %374 = load i64, ptr %2, align 8
  %375 = zext i32 %0 to i64
  %376 = add i64 %374, %375
  %377 = add i64 %376, %375
  %378 = sub i64 %377, %375
  %379 = xor i64 %378, %375
  %380 = sub i64 %379, %374
  %381 = xor i64 %380, %375
  store i64 %381, ptr %2, align 8
  br label %6

382:                                              ; preds = %163
  %383 = load i64, ptr %2, align 8
  %384 = zext i32 %0 to i64
  %385 = sub i64 %384, %383
  %386 = xor i64 %385, %383
  %387 = mul i64 %386, %383
  %388 = xor i64 %387, %383
  store i64 %388, ptr %2, align 8
  br label %151

389:                                              ; preds = %185
  %390 = load i64, ptr %2, align 8
  %391 = zext i32 %0 to i64
  %392 = mul i64 %391, %391
  %393 = or i64 %392, %390
  %394 = add i64 %393, %391
  %395 = xor i64 %394, %390
  %396 = mul i64 %395, %390
  store i64 %396, ptr %2, align 8
  br label %151

397:                                              ; preds = %198
  %398 = load i64, ptr %2, align 8
  %399 = zext i32 %0 to i64
  %400 = add i64 %398, %398
  %401 = sub i64 %400, %399
  %402 = sub i64 %401, %398
  store i64 %402, ptr %2, align 8
  br label %151

403:                                              ; preds = %209
  %404 = load i64, ptr %2, align 8
  %405 = zext i32 %0 to i64
  %406 = add i64 %405, %405
  %407 = sub i64 %406, %404
  %408 = sub i64 %407, %404
  %409 = or i64 %408, %404
  %410 = xor i64 %409, %404
  %411 = mul i64 %410, %405
  store i64 %411, ptr %2, align 8
  br label %151

412:                                              ; preds = %230
  %413 = load i64, ptr %2, align 8
  %414 = zext i32 %0 to i64
  %415 = add i64 %414, %414
  %416 = or i64 %415, %414
  %417 = xor i64 %416, %413
  %418 = xor i64 %417, %414
  %419 = sub i64 %418, %413
  store i64 %419, ptr %2, align 8
  br label %151

420:                                              ; preds = %243
  %421 = load i64, ptr %2, align 8
  %422 = zext i32 %0 to i64
  %423 = add i64 %422, %422
  %424 = xor i64 %423, %421
  %425 = xor i64 %424, %421
  %426 = or i64 %425, %421
  %427 = and i64 %426, %422
  %428 = or i64 %427, %422
  store i64 %428, ptr %2, align 8
  br label %151

429:                                              ; preds = %256
  %430 = load i64, ptr %2, align 8
  %431 = zext i32 %0 to i64
  %432 = xor i64 %430, %430
  %433 = and i64 %432, %431
  %434 = add i64 %433, %431
  %435 = xor i64 %434, %430
  %436 = or i64 %435, %430
  %437 = and i64 %436, %431
  store i64 %437, ptr %2, align 8
  br label %151

438:                                              ; preds = %267
  %439 = load i64, ptr %2, align 8
  %440 = zext i32 %0 to i64
  %441 = xor i64 %439, %440
  %442 = mul i64 %441, %439
  %443 = and i64 %442, %440
  %444 = add i64 %443, %439
  store i64 %444, ptr %2, align 8
  br label %151
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @rotate_left32(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = shl i32 1, %6
  %8 = mul i32 %5, %7
  %9 = load i32, ptr %3, align 4
  %10 = load i32, ptr %4, align 4
  %11 = xor i32 %10, -1
  %12 = add i32 32, %11
  %13 = add i32 %12, 1
  %14 = lshr i32 %9, %13
  %15 = xor i32 %8, %14
  %16 = and i32 %8, %14
  %17 = mul i32 %15, -1380002315
  %18 = mul i32 %16, -1380002315
  %19 = add i32 %17, %18
  %20 = mul i32 %19, 933850717
  ret i32 %20
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
  %9 = add i32 %7, %8
  %10 = or i32 %7, %8
  %11 = mul i32 %9, 1082651115
  %12 = mul i32 %10, 1082651115
  %13 = sub i32 %11, %12
  %14 = mul i32 %13, 1070575299
  %15 = load i32, ptr %4, align 4
  %16 = or i32 %15, -1
  %17 = and i32 %15, -1
  %18 = sub i32 %16, %17
  %19 = load i32, ptr %6, align 4
  %20 = add i32 %18, %19
  %21 = or i32 %18, %19
  %22 = sub i32 %20, %21
  %23 = xor i32 %14, %22
  %24 = and i32 %14, %22
  %25 = add i32 %23, %24
  ret i32 %25
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
  %9 = add i32 %7, %8
  %10 = or i32 %7, %8
  %11 = mul i32 %9, -2125279977
  %12 = mul i32 %10, -2125279977
  %13 = sub i32 %11, %12
  %14 = mul i32 %13, 612916983
  %15 = mul i32 %14, -1662245423
  %16 = load i32, ptr %5, align 4
  %17 = load i32, ptr %6, align 4
  %18 = add i32 %17, -1
  %19 = and i32 %17, -1
  %20 = add i32 %19, %19
  %21 = sub i32 %18, %20
  %22 = add i32 %16, %21
  %23 = or i32 %16, %21
  %24 = mul i32 %22, -1661693467
  %25 = mul i32 %23, -1661693467
  %26 = sub i32 %24, %25
  %27 = mul i32 %26, 1139749563
  %28 = mul i32 %27, -1479303817
  %29 = xor i32 %15, %28
  %30 = and i32 %15, %28
  %31 = add i32 %29, %30
  ret i32 %31
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
  %9 = add i32 %7, %8
  %10 = and i32 %7, %8
  %11 = add i32 %10, %10
  %12 = sub i32 %9, %11
  %13 = load i32, ptr %6, align 4
  %14 = add i32 %12, %13
  %15 = and i32 %12, %13
  %16 = mul i32 %14, 1051582075
  %17 = mul i32 %15, 1051582075
  %18 = add i32 %17, %17
  %19 = sub i32 %16, %18
  %20 = mul i32 %19, 1461034031
  %21 = mul i32 %20, 697605821
  ret i32 %21
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
  %10 = add i32 %9, -1
  %11 = and i32 %9, -1
  %12 = mul i32 %10, -1058515267
  %13 = mul i32 %11, -1058515267
  %14 = add i32 %13, %13
  %15 = sub i32 %12, %14
  %16 = mul i32 %15, 316274945
  %17 = mul i32 %16, 263776149
  %18 = xor i32 %8, %17
  %19 = and i32 %8, %17
  %20 = mul i32 %18, 613125275
  %21 = mul i32 %19, 613125275
  %22 = add i32 %20, %21
  %23 = mul i32 %22, -1472864477
  %24 = mul i32 %23, -561358127
  %25 = add i32 %7, %24
  %26 = and i32 %7, %24
  %27 = add i32 %26, %26
  %28 = sub i32 %25, %27
  ret i32 %28
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
  %15 = mul i32 %14, 256
  store i32 %15, ptr %4, align 4
  %16 = load ptr, ptr %2, align 8
  %17 = getelementptr inbounds i8, ptr %16, i64 2
  %18 = load i8, ptr %17, align 1
  %19 = zext i8 %18 to i32
  %20 = mul i32 %19, 65536
  store i32 %20, ptr %5, align 4
  %21 = load ptr, ptr %2, align 8
  %22 = getelementptr inbounds i8, ptr %21, i64 3
  %23 = load i8, ptr %22, align 1
  %24 = zext i8 %23 to i32
  %25 = mul i32 %24, 16777216
  store i32 %25, ptr %6, align 4
  %26 = load i32, ptr %3, align 4
  %27 = load i32, ptr %4, align 4
  %28 = add i32 %26, %27
  %29 = and i32 %26, %27
  %30 = sub i32 %28, %29
  %31 = load i32, ptr %5, align 4
  %32 = xor i32 %30, %31
  %33 = and i32 %30, %31
  %34 = mul i32 %32, 294348053
  %35 = mul i32 %33, 294348053
  %36 = add i32 %34, %35
  %37 = mul i32 %36, -1735527127
  %38 = mul i32 %37, -429305099
  %39 = load i32, ptr %6, align 4
  %40 = xor i32 %38, %39
  %41 = and i32 %38, %39
  %42 = add i32 %40, %41
  ret i32 %42
}

declare i64 @fread(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #3

; Function Attrs: nounwind
declare i32 @ferror(ptr noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal ptr @duplicate_string(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  %8 = alloca ptr, align 8
  store i32 -1034416061, ptr %4, align 4
  br label %9

9:                                                ; preds = %241, %95, %94, %1
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, -1552715607
  %12 = mul i32 %11, -1939344541
  switch i32 %12, label %95 [
    i32 1692329614, label %13
    i32 657823307, label %26
    i32 1071815772, label %37
    i32 2144581313, label %57
    i32 901320538, label %67
    i32 846176652, label %92
    i32 2026720040, label %105
    i32 2120551051, label %125
    i32 1879567868, label %138
    i32 1868344997, label %151
    i32 1617825151, label %172
    i32 285496232, label %185
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %6, align 8
  %14 = load ptr, ptr %6, align 8
  %15 = icmp eq ptr %14, null
  %16 = select i1 %15, i32 -1769432414, i32 -2113345635
  store i32 %16, ptr %4, align 4
  %17 = xor i32 %3, 18915755
  %18 = and i32 %3, %17
  %19 = or i32 %3, %17
  %20 = xor i32 %3, %17
  %21 = add i32 %18, %19
  %22 = sub i32 %21, %3
  %23 = sub i32 %22, %17
  %24 = mul i32 %23, 73
  %25 = icmp ne i32 %24, 0
  br i1 %25, label %204, label %94

26:                                               ; preds = %9
  store ptr null, ptr %5, align 8
  store i32 1842252973, ptr %4, align 4
  %27 = xor i32 %3, 91768605
  %28 = and i32 %3, %27
  %29 = or i32 %3, %27
  %30 = xor i32 %3, %27
  %31 = mul i32 %29, 2
  %32 = sub i32 %31, %30
  %33 = sub i32 %32, %3
  %34 = sub i32 %33, %27
  %35 = mul i32 %34, 242
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %94, label %211

37:                                               ; preds = %9
  %38 = load ptr, ptr %6, align 8
  %39 = call i64 @strlen(ptr noundef %38) #11
  store i64 %39, ptr %7, align 8
  %40 = load i64, ptr %7, align 8
  %41 = xor i64 %40, 1
  %42 = and i64 %40, 1
  %43 = add i64 %42, %42
  %44 = add i64 %41, %43
  %45 = call noalias ptr @malloc(i64 noundef %44) #13
  store ptr %45, ptr %8, align 8
  %46 = load ptr, ptr %8, align 8
  %47 = icmp eq ptr %46, null
  %48 = select i1 %47, i32 313762100, i32 1262242823
  store i32 %48, ptr %4, align 4
  %49 = xor i32 %3, 1070487183
  %50 = and i32 %3, %49
  %51 = or i32 %3, %49
  %52 = xor i32 %3, %49
  %53 = sub i32 %51, %52
  %54 = sub i32 %53, %50
  %55 = mul i32 %54, 177
  %56 = icmp slt i32 %55, 1
  br i1 %56, label %94, label %220

57:                                               ; preds = %9
  call void @die_message(ptr noundef @.str.19)
  store i32 1262242823, ptr %4, align 4
  %58 = xor i32 %3, -1669953439
  %59 = and i32 %3, %58
  %60 = or i32 %3, %58
  %61 = xor i32 %3, %58
  %62 = add i32 %59, %60
  %63 = sub i32 %62, %3
  %64 = sub i32 %63, %58
  %65 = mul i32 %64, 247
  %66 = icmp sle i32 %65, 0
  br i1 %66, label %94, label %226

67:                                               ; preds = %9
  %68 = load ptr, ptr %8, align 8
  %69 = load ptr, ptr %6, align 8
  %70 = load i64, ptr %7, align 8
  %71 = or i64 %70, 1
  %72 = and i64 %70, 1
  %73 = add i64 %71, %72
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %68, ptr align 1 %69, i64 %73, i1 false)
  %74 = load ptr, ptr %8, align 8
  store ptr %74, ptr %5, align 8
  store i32 1842252973, ptr %4, align 4
  %75 = xor i32 %3, -326187841
  %76 = and i32 %3, %75
  %77 = or i32 %3, %75
  %78 = xor i32 %3, %75
  %79 = sub i32 %77, %78
  %80 = sub i32 %79, %76
  %81 = mul i32 %80, 26
  %82 = xor i32 %3, 534512349
  %83 = and i32 %3, %82
  %84 = or i32 %3, %82
  %85 = xor i32 %3, %82
  %86 = add i32 %3, %82
  %87 = sub i32 %86, %85
  %88 = mul i32 %83, 2
  %89 = sub i32 %87, %88
  %90 = mul i32 %89, 126
  %91 = icmp ne i32 %81, %90
  br i1 %91, label %235, label %94

92:                                               ; preds = %9
  %93 = load ptr, ptr %5, align 8
  ret ptr %93

94:                                               ; preds = %284, %277, %271, %263, %257, %249, %235, %226, %220, %211, %204, %185, %172, %151, %138, %125, %105, %67, %57, %37, %26, %13
  br label %9

95:                                               ; preds = %9
  store i32 -1034416061, ptr %4, align 4
  call void asm sideeffect "", ""()
  %96 = xor i32 %3, -47310321
  %97 = and i32 %3, %96
  %98 = or i32 %3, %96
  %99 = xor i32 %3, %96
  %100 = add i32 %97, %98
  %101 = sub i32 %100, %3
  %102 = sub i32 %101, %96
  %103 = mul i32 %102, 67
  %104 = icmp ne i32 %103, 0
  br i1 %104, label %241, label %9

105:                                              ; preds = %9
  %106 = load i32, ptr %4, align 4
  %107 = xor i32 %106, 118412453
  store i32 %107, ptr %4, align 4
  %108 = xor i32 %3, 1729539185
  %109 = and i32 %3, %108
  %110 = or i32 %3, %108
  %111 = xor i32 %3, %108
  %112 = mul i32 %110, 2
  %113 = sub i32 %112, %111
  %114 = sub i32 %113, %3
  %115 = sub i32 %114, %108
  %116 = mul i32 %115, 144
  %117 = xor i32 %3, 348909949
  %118 = and i32 %3, %117
  %119 = or i32 %3, %117
  %120 = xor i32 %3, %117
  %121 = sub i32 %119, %120
  %122 = sub i32 %121, %118
  %123 = mul i32 %122, 170
  %124 = icmp eq i32 %116, %123
  br i1 %124, label %94, label %249

125:                                              ; preds = %9
  %126 = load i32, ptr %4, align 4
  %127 = xor i32 %126, -799719832
  store i32 %127, ptr %4, align 4
  %128 = xor i32 %3, -1084014343
  %129 = and i32 %3, %128
  %130 = or i32 %3, %128
  %131 = xor i32 %3, %128
  %132 = add i32 %3, %128
  %133 = sub i32 %132, %131
  %134 = mul i32 %129, 2
  %135 = sub i32 %133, %134
  %136 = mul i32 %135, 200
  %137 = icmp ugt i32 %136, 0
  br i1 %137, label %257, label %94

138:                                              ; preds = %9
  %139 = load i32, ptr %4, align 4
  %140 = xor i32 %139, -2027232404
  store i32 %140, ptr %4, align 4
  %141 = xor i32 %3, -2067377761
  %142 = and i32 %3, %141
  %143 = or i32 %3, %141
  %144 = xor i32 %3, %141
  %145 = mul i32 %143, 2
  %146 = sub i32 %145, %144
  %147 = sub i32 %146, %3
  %148 = sub i32 %147, %141
  %149 = mul i32 %148, 90
  %150 = icmp ne i32 %149, 0
  br i1 %150, label %263, label %94

151:                                              ; preds = %9
  %152 = load i32, ptr %4, align 4
  %153 = xor i32 %152, 823223109
  store i32 %153, ptr %4, align 4
  %154 = xor i32 %3, -181761661
  %155 = and i32 %3, %154
  %156 = or i32 %3, %154
  %157 = xor i32 %3, %154
  %158 = add i32 %3, %154
  %159 = sub i32 %158, %157
  %160 = mul i32 %155, 2
  %161 = sub i32 %159, %160
  %162 = mul i32 %161, 103
  %163 = xor i32 %3, 1972810979
  %164 = and i32 %3, %163
  %165 = or i32 %3, %163
  %166 = xor i32 %3, %163
  %167 = add i32 %164, %165
  %168 = sub i32 %167, %3
  %169 = sub i32 %168, %163
  %170 = mul i32 %169, 95
  %171 = icmp ne i32 %162, %170
  br i1 %171, label %271, label %94

172:                                              ; preds = %9
  %173 = load i32, ptr %4, align 4
  %174 = xor i32 %173, 1173013009
  store i32 %174, ptr %4, align 4
  %175 = xor i32 %3, 772227933
  %176 = and i32 %3, %175
  %177 = or i32 %3, %175
  %178 = xor i32 %3, %175
  %179 = mul i32 %177, 2
  %180 = sub i32 %179, %178
  %181 = sub i32 %180, %3
  %182 = sub i32 %181, %175
  %183 = mul i32 %182, 235
  %184 = icmp ugt i32 %183, 0
  br i1 %184, label %277, label %94

185:                                              ; preds = %9
  %186 = load i32, ptr %4, align 4
  %187 = xor i32 %186, -1488607478
  store i32 %187, ptr %4, align 4
  %188 = xor i32 %3, -1259623881
  %189 = and i32 %3, %188
  %190 = or i32 %3, %188
  %191 = xor i32 %3, %188
  %192 = sub i32 %190, %191
  %193 = sub i32 %192, %189
  %194 = mul i32 %193, 73
  %195 = xor i32 %3, -603868837
  %196 = and i32 %3, %195
  %197 = or i32 %3, %195
  %198 = xor i32 %3, %195
  %199 = add i32 %196, %197
  %200 = sub i32 %199, %3
  %201 = sub i32 %200, %195
  %202 = mul i32 %201, 2
  %203 = icmp ne i32 %194, %202
  br i1 %203, label %284, label %94

204:                                              ; preds = %13
  %205 = load i64, ptr %2, align 8
  %206 = ptrtoint ptr %0 to i64
  %207 = xor i64 %205, %205
  %208 = or i64 %207, %205
  %209 = mul i64 %208, %205
  %210 = and i64 %209, %206
  store i64 %210, ptr %2, align 8
  br label %94

211:                                              ; preds = %26
  %212 = load i64, ptr %2, align 8
  %213 = ptrtoint ptr %0 to i64
  %214 = and i64 %212, %212
  %215 = mul i64 %214, %213
  %216 = or i64 %215, %213
  %217 = mul i64 %216, %213
  %218 = mul i64 %217, %213
  %219 = or i64 %218, %212
  store i64 %219, ptr %2, align 8
  br label %94

220:                                              ; preds = %37
  %221 = load i64, ptr %2, align 8
  %222 = ptrtoint ptr %0 to i64
  %223 = add i64 %221, %222
  %224 = sub i64 %223, %221
  %225 = sub i64 %224, %222
  store i64 %225, ptr %2, align 8
  br label %94

226:                                              ; preds = %57
  %227 = load i64, ptr %2, align 8
  %228 = ptrtoint ptr %0 to i64
  %229 = and i64 %228, %228
  %230 = and i64 %229, %228
  %231 = or i64 %230, %227
  %232 = xor i64 %231, %228
  %233 = sub i64 %232, %228
  %234 = xor i64 %233, %228
  store i64 %234, ptr %2, align 8
  br label %94

235:                                              ; preds = %67
  %236 = load i64, ptr %2, align 8
  %237 = ptrtoint ptr %0 to i64
  %238 = add i64 %237, %236
  %239 = or i64 %238, %236
  %240 = sub i64 %239, %236
  store i64 %240, ptr %2, align 8
  br label %94

241:                                              ; preds = %95
  %242 = load i64, ptr %2, align 8
  %243 = ptrtoint ptr %0 to i64
  %244 = sub i64 %242, %243
  %245 = mul i64 %244, %243
  %246 = mul i64 %245, %242
  %247 = mul i64 %246, %243
  %248 = sub i64 %247, %242
  store i64 %248, ptr %2, align 8
  br label %9

249:                                              ; preds = %105
  %250 = load i64, ptr %2, align 8
  %251 = ptrtoint ptr %0 to i64
  %252 = sub i64 %250, %251
  %253 = add i64 %252, %250
  %254 = and i64 %253, %251
  %255 = or i64 %254, %251
  %256 = or i64 %255, %250
  store i64 %256, ptr %2, align 8
  br label %94

257:                                              ; preds = %125
  %258 = load i64, ptr %2, align 8
  %259 = ptrtoint ptr %0 to i64
  %260 = mul i64 %259, %258
  %261 = and i64 %260, %258
  %262 = or i64 %261, %258
  store i64 %262, ptr %2, align 8
  br label %94

263:                                              ; preds = %138
  %264 = load i64, ptr %2, align 8
  %265 = ptrtoint ptr %0 to i64
  %266 = add i64 %265, %264
  %267 = and i64 %266, %264
  %268 = and i64 %267, %264
  %269 = xor i64 %268, %265
  %270 = or i64 %269, %265
  store i64 %270, ptr %2, align 8
  br label %94

271:                                              ; preds = %151
  %272 = load i64, ptr %2, align 8
  %273 = ptrtoint ptr %0 to i64
  %274 = or i64 %272, %273
  %275 = or i64 %274, %272
  %276 = mul i64 %275, %273
  store i64 %276, ptr %2, align 8
  br label %94

277:                                              ; preds = %172
  %278 = load i64, ptr %2, align 8
  %279 = ptrtoint ptr %0 to i64
  %280 = xor i64 %279, %279
  %281 = sub i64 %280, %279
  %282 = mul i64 %281, %279
  %283 = add i64 %282, %278
  store i64 %283, ptr %2, align 8
  br label %94

284:                                              ; preds = %185
  %285 = load i64, ptr %2, align 8
  %286 = ptrtoint ptr %0 to i64
  %287 = or i64 %286, %285
  %288 = add i64 %287, %286
  %289 = mul i64 %288, %285
  %290 = sub i64 %289, %285
  store i64 %290, ptr %2, align 8
  br label %94
}

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #8

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define internal void @options_init(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  store i32 131154363, ptr %4, align 4
  br label %7

7:                                                ; preds = %276, %105, %104, %1
  %8 = load i32, ptr %4, align 4
  %9 = sub i32 %8, 198934934
  %10 = mul i32 %9, 667722065
  %11 = icmp slt i32 %10, 1474979199
  br i1 %11, label %199, label %201

12:                                               ; preds = %207
  store ptr %0, ptr %5, align 8
  %13 = load ptr, ptr %5, align 8
  %14 = icmp eq ptr %13, null
  %15 = select i1 %14, i32 1471031031, i32 -1065479347
  store i32 %15, ptr %4, align 4
  %16 = xor i32 %3, -1370366503
  %17 = and i32 %3, %16
  %18 = or i32 %3, %16
  %19 = xor i32 %3, %16
  %20 = add i32 %3, %16
  %21 = sub i32 %20, %19
  %22 = mul i32 %17, 2
  %23 = sub i32 %21, %22
  %24 = mul i32 %23, 145
  %25 = icmp ugt i32 %24, 0
  br i1 %25, label %235, label %104

26:                                               ; preds = %209
  store i32 1627055973, ptr %4, align 4
  %27 = xor i32 %3, 129459953
  %28 = and i32 %3, %27
  %29 = or i32 %3, %27
  %30 = xor i32 %3, %27
  %31 = mul i32 %29, 2
  %32 = sub i32 %31, %30
  %33 = sub i32 %32, %3
  %34 = sub i32 %33, %27
  %35 = mul i32 %34, 190
  %36 = icmp slt i32 %35, 1
  br i1 %36, label %104, label %244

37:                                               ; preds = %231
  %38 = load ptr, ptr %5, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %38, i8 0, i64 3104, i1 false)
  store i64 0, ptr %6, align 8
  store i32 730014380, ptr %4, align 4
  %39 = xor i32 %3, -638708349
  %40 = and i32 %3, %39
  %41 = or i32 %3, %39
  %42 = xor i32 %3, %39
  %43 = mul i32 %41, 2
  %44 = sub i32 %43, %42
  %45 = sub i32 %44, %3
  %46 = sub i32 %45, %39
  %47 = mul i32 %46, 91
  %48 = icmp sle i32 %47, 0
  br i1 %48, label %104, label %252

49:                                               ; preds = %213
  %50 = load i64, ptr %6, align 8
  %51 = icmp ult i64 %50, 128
  %52 = select i1 %51, i32 -147395420, i32 1627055973
  store i32 %52, ptr %4, align 4
  %53 = xor i32 %3, -688918441
  %54 = and i32 %3, %53
  %55 = or i32 %3, %53
  %56 = xor i32 %3, %53
  %57 = mul i32 %55, 2
  %58 = sub i32 %57, %56
  %59 = sub i32 %58, %3
  %60 = sub i32 %59, %53
  %61 = mul i32 %60, 243
  %62 = xor i32 %3, -2025044847
  %63 = and i32 %3, %62
  %64 = or i32 %3, %62
  %65 = xor i32 %3, %62
  %66 = mul i32 %64, 2
  %67 = sub i32 %66, %65
  %68 = sub i32 %67, %3
  %69 = sub i32 %68, %62
  %70 = mul i32 %69, 38
  %71 = icmp ne i32 %61, %70
  br i1 %71, label %258, label %104

72:                                               ; preds = %233
  %73 = load ptr, ptr %5, align 8
  %74 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %73, i32 0, i32 6
  %75 = load i64, ptr %6, align 8
  %76 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %74, i64 0, i64 %75
  %77 = getelementptr inbounds nuw %struct.InputJob, ptr %76, i32 0, i32 0
  store i32 0, ptr %77, align 8
  %78 = load ptr, ptr %5, align 8
  %79 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %78, i32 0, i32 6
  %80 = load i64, ptr %6, align 8
  %81 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %79, i64 0, i64 %80
  %82 = getelementptr inbounds nuw %struct.InputJob, ptr %81, i32 0, i32 1
  store ptr null, ptr %82, align 8
  %83 = load ptr, ptr %5, align 8
  %84 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %83, i32 0, i32 6
  %85 = load i64, ptr %6, align 8
  %86 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %84, i64 0, i64 %85
  %87 = getelementptr inbounds nuw %struct.InputJob, ptr %86, i32 0, i32 2
  store ptr null, ptr %87, align 8
  %88 = load i64, ptr %6, align 8
  %89 = xor i64 %88, 1
  %90 = and i64 %88, 1
  %91 = add i64 %90, %90
  %92 = add i64 %89, %91
  store i64 %92, ptr %6, align 8
  store i32 730014380, ptr %4, align 4
  %93 = xor i32 %3, 443377115
  %94 = and i32 %3, %93
  %95 = or i32 %3, %93
  %96 = xor i32 %3, %93
  %97 = add i32 %3, %93
  %98 = sub i32 %97, %96
  %99 = mul i32 %94, 2
  %100 = sub i32 %98, %99
  %101 = mul i32 %100, 150
  %102 = icmp eq i32 %101, 0
  br i1 %102, label %104, label %267

103:                                              ; preds = %223
  ret void

104:                                              ; preds = %324, %316, %307, %300, %293, %284, %267, %258, %252, %244, %235, %186, %173, %161, %148, %135, %115, %72, %49, %37, %26, %12
  br label %7

105:                                              ; preds = %233, %229, %227, %223, %217, %213, %211, %207
  store i32 131154363, ptr %4, align 4
  call void asm sideeffect "", ""()
  %106 = xor i32 %3, -2090307213
  %107 = and i32 %3, %106
  %108 = or i32 %3, %106
  %109 = xor i32 %3, %106
  %110 = add i32 %107, %108
  %111 = sub i32 %110, %3
  %112 = sub i32 %111, %106
  %113 = mul i32 %112, 87
  %114 = icmp slt i32 %113, 0
  br i1 %114, label %276, label %7

115:                                              ; preds = %211
  %116 = load i32, ptr %4, align 4
  %117 = xor i32 %116, -2074045724
  store i32 %117, ptr %4, align 4
  %118 = xor i32 %3, 1941092859
  %119 = and i32 %3, %118
  %120 = or i32 %3, %118
  %121 = xor i32 %3, %118
  %122 = sub i32 %120, %121
  %123 = sub i32 %122, %119
  %124 = mul i32 %123, 50
  %125 = xor i32 %3, 121418455
  %126 = and i32 %3, %125
  %127 = or i32 %3, %125
  %128 = xor i32 %3, %125
  %129 = mul i32 %127, 2
  %130 = sub i32 %129, %128
  %131 = sub i32 %130, %3
  %132 = sub i32 %131, %125
  %133 = mul i32 %132, 144
  %134 = icmp ne i32 %124, %133
  br i1 %134, label %284, label %104

135:                                              ; preds = %227
  %136 = load i32, ptr %4, align 4
  %137 = xor i32 %136, 2106737942
  store i32 %137, ptr %4, align 4
  %138 = xor i32 %3, -1431597471
  %139 = and i32 %3, %138
  %140 = or i32 %3, %138
  %141 = xor i32 %3, %138
  %142 = mul i32 %140, 2
  %143 = sub i32 %142, %141
  %144 = sub i32 %143, %3
  %145 = sub i32 %144, %138
  %146 = mul i32 %145, 87
  %147 = icmp eq i32 %146, 0
  br i1 %147, label %104, label %293

148:                                              ; preds = %229
  %149 = load i32, ptr %4, align 4
  %150 = xor i32 %149, -204791084
  store i32 %150, ptr %4, align 4
  %151 = xor i32 %3, -1574178585
  %152 = and i32 %3, %151
  %153 = or i32 %3, %151
  %154 = xor i32 %3, %151
  %155 = add i32 %3, %151
  %156 = sub i32 %155, %154
  %157 = mul i32 %152, 2
  %158 = sub i32 %156, %157
  %159 = mul i32 %158, 215
  %160 = icmp eq i32 %159, 0
  br i1 %160, label %104, label %300

161:                                              ; preds = %215
  %162 = load i32, ptr %4, align 4
  %163 = xor i32 %162, 444090042
  store i32 %163, ptr %4, align 4
  %164 = xor i32 %3, 17816283
  %165 = and i32 %3, %164
  %166 = or i32 %3, %164
  %167 = xor i32 %3, %164
  %168 = add i32 %165, %166
  %169 = sub i32 %168, %3
  %170 = sub i32 %169, %164
  %171 = mul i32 %170, 31
  %172 = icmp ugt i32 %171, 0
  br i1 %172, label %307, label %104

173:                                              ; preds = %217
  %174 = load i32, ptr %4, align 4
  %175 = xor i32 %174, 1265375418
  store i32 %175, ptr %4, align 4
  %176 = xor i32 %3, -1417137683
  %177 = and i32 %3, %176
  %178 = or i32 %3, %176
  %179 = xor i32 %3, %176
  %180 = mul i32 %178, 2
  %181 = sub i32 %180, %179
  %182 = sub i32 %181, %3
  %183 = sub i32 %182, %176
  %184 = mul i32 %183, 190
  %185 = icmp uge i32 %184, 0
  br i1 %185, label %104, label %316

186:                                              ; preds = %225
  %187 = load i32, ptr %4, align 4
  %188 = xor i32 %187, -1447555562
  store i32 %188, ptr %4, align 4
  %189 = xor i32 %3, 281763441
  %190 = and i32 %3, %189
  %191 = or i32 %3, %189
  %192 = xor i32 %3, %189
  %193 = mul i32 %191, 2
  %194 = sub i32 %193, %192
  %195 = sub i32 %194, %3
  %196 = sub i32 %195, %189
  %197 = mul i32 %196, 151
  %198 = icmp sle i32 %197, 0
  br i1 %198, label %104, label %324

199:                                              ; preds = %7
  %200 = icmp slt i32 %10, 669044214
  br i1 %200, label %203, label %205

201:                                              ; preds = %7
  %202 = icmp slt i32 %10, 1663118603
  br i1 %202, label %219, label %221

203:                                              ; preds = %199
  %204 = icmp slt i32 %10, 133452977
  br i1 %204, label %207, label %209

205:                                              ; preds = %199
  %206 = icmp slt i32 %10, 903285995
  br i1 %206, label %213, label %215

207:                                              ; preds = %203
  %208 = icmp eq i32 %10, 118821045
  br i1 %208, label %12, label %105

209:                                              ; preds = %203
  %210 = icmp eq i32 %10, 133452977
  br i1 %210, label %26, label %211

211:                                              ; preds = %209
  %212 = icmp eq i32 %10, 576837103
  br i1 %212, label %115, label %105

213:                                              ; preds = %205
  %214 = icmp eq i32 %10, 669044214
  br i1 %214, label %49, label %105

215:                                              ; preds = %205
  %216 = icmp eq i32 %10, 903285995
  br i1 %216, label %161, label %217

217:                                              ; preds = %215
  %218 = icmp eq i32 %10, 1298984264
  br i1 %218, label %173, label %105

219:                                              ; preds = %201
  %220 = icmp slt i32 %10, 1479920061
  br i1 %220, label %223, label %225

221:                                              ; preds = %201
  %222 = icmp slt i32 %10, 1676161511
  br i1 %222, label %229, label %231

223:                                              ; preds = %219
  %224 = icmp eq i32 %10, 1474979199
  br i1 %224, label %103, label %105

225:                                              ; preds = %219
  %226 = icmp eq i32 %10, 1479920061
  br i1 %226, label %186, label %227

227:                                              ; preds = %225
  %228 = icmp eq i32 %10, 1487687722
  br i1 %228, label %135, label %105

229:                                              ; preds = %221
  %230 = icmp eq i32 %10, 1663118603
  br i1 %230, label %148, label %105

231:                                              ; preds = %221
  %232 = icmp eq i32 %10, 1676161511
  br i1 %232, label %37, label %233

233:                                              ; preds = %231
  %234 = icmp eq i32 %10, 1734913390
  br i1 %234, label %72, label %105

235:                                              ; preds = %12
  %236 = load i64, ptr %2, align 8
  %237 = ptrtoint ptr %0 to i64
  %238 = mul i64 %236, %237
  %239 = and i64 %238, %236
  %240 = mul i64 %239, %236
  %241 = xor i64 %240, %236
  %242 = mul i64 %241, %236
  %243 = or i64 %242, %236
  store i64 %243, ptr %2, align 8
  br label %104

244:                                              ; preds = %26
  %245 = load i64, ptr %2, align 8
  %246 = ptrtoint ptr %0 to i64
  %247 = or i64 %246, %245
  %248 = add i64 %247, %245
  %249 = xor i64 %248, %245
  %250 = mul i64 %249, %246
  %251 = mul i64 %250, %245
  store i64 %251, ptr %2, align 8
  br label %104

252:                                              ; preds = %37
  %253 = load i64, ptr %2, align 8
  %254 = ptrtoint ptr %0 to i64
  %255 = sub i64 %253, %254
  %256 = sub i64 %255, %254
  %257 = xor i64 %256, %253
  store i64 %257, ptr %2, align 8
  br label %104

258:                                              ; preds = %49
  %259 = load i64, ptr %2, align 8
  %260 = ptrtoint ptr %0 to i64
  %261 = and i64 %260, %260
  %262 = mul i64 %261, %259
  %263 = xor i64 %262, %259
  %264 = and i64 %263, %259
  %265 = and i64 %264, %259
  %266 = add i64 %265, %260
  store i64 %266, ptr %2, align 8
  br label %104

267:                                              ; preds = %72
  %268 = load i64, ptr %2, align 8
  %269 = ptrtoint ptr %0 to i64
  %270 = mul i64 %268, %269
  %271 = add i64 %270, %269
  %272 = mul i64 %271, %268
  %273 = sub i64 %272, %269
  %274 = or i64 %273, %269
  %275 = xor i64 %274, %268
  store i64 %275, ptr %2, align 8
  br label %104

276:                                              ; preds = %105
  %277 = load i64, ptr %2, align 8
  %278 = ptrtoint ptr %0 to i64
  %279 = xor i64 %278, %277
  %280 = sub i64 %279, %277
  %281 = or i64 %280, %277
  %282 = and i64 %281, %277
  %283 = sub i64 %282, %278
  store i64 %283, ptr %2, align 8
  br label %7

284:                                              ; preds = %115
  %285 = load i64, ptr %2, align 8
  %286 = ptrtoint ptr %0 to i64
  %287 = add i64 %285, %286
  %288 = mul i64 %287, %285
  %289 = xor i64 %288, %286
  %290 = or i64 %289, %285
  %291 = sub i64 %290, %285
  %292 = xor i64 %291, %286
  store i64 %292, ptr %2, align 8
  br label %104

293:                                              ; preds = %135
  %294 = load i64, ptr %2, align 8
  %295 = ptrtoint ptr %0 to i64
  %296 = add i64 %295, %294
  %297 = or i64 %296, %294
  %298 = xor i64 %297, %294
  %299 = or i64 %298, %294
  store i64 %299, ptr %2, align 8
  br label %104

300:                                              ; preds = %148
  %301 = load i64, ptr %2, align 8
  %302 = ptrtoint ptr %0 to i64
  %303 = and i64 %302, %301
  %304 = add i64 %303, %302
  %305 = and i64 %304, %302
  %306 = sub i64 %305, %302
  store i64 %306, ptr %2, align 8
  br label %104

307:                                              ; preds = %161
  %308 = load i64, ptr %2, align 8
  %309 = ptrtoint ptr %0 to i64
  %310 = sub i64 %308, %308
  %311 = mul i64 %310, %309
  %312 = xor i64 %311, %308
  %313 = sub i64 %312, %308
  %314 = and i64 %313, %308
  %315 = and i64 %314, %308
  store i64 %315, ptr %2, align 8
  br label %104

316:                                              ; preds = %173
  %317 = load i64, ptr %2, align 8
  %318 = ptrtoint ptr %0 to i64
  %319 = and i64 %318, %318
  %320 = and i64 %319, %318
  %321 = xor i64 %320, %317
  %322 = and i64 %321, %317
  %323 = xor i64 %322, %318
  store i64 %323, ptr %2, align 8
  br label %104

324:                                              ; preds = %186
  %325 = load i64, ptr %2, align 8
  %326 = ptrtoint ptr %0 to i64
  %327 = and i64 %325, %325
  %328 = add i64 %327, %326
  %329 = and i64 %328, %325
  store i64 %329, ptr %2, align 8
  br label %104
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @string_equals(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  store i32 -1970844024, ptr %5, align 4
  br label %9

9:                                                ; preds = %236, %88, %87, %2
  %10 = load i32, ptr %5, align 4
  %11 = sub i32 %10, -1843009321
  %12 = mul i32 %11, 1857214999
  %13 = icmp slt i32 %12, 1305021671
  br i1 %13, label %176, label %178

14:                                               ; preds = %180
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  %15 = load ptr, ptr %7, align 8
  %16 = icmp eq ptr %15, null
  %17 = select i1 %16, i32 1506058067, i32 1859457696
  store i32 %17, ptr %5, align 4
  %18 = xor i32 %4, -2059046611
  %19 = and i32 %4, %18
  %20 = or i32 %4, %18
  %21 = xor i32 %4, %18
  %22 = mul i32 %20, 2
  %23 = sub i32 %22, %21
  %24 = sub i32 %23, %4
  %25 = sub i32 %24, %18
  %26 = mul i32 %25, 220
  %27 = xor i32 %4, -1345184939
  %28 = and i32 %4, %27
  %29 = or i32 %4, %27
  %30 = xor i32 %4, %27
  %31 = mul i32 %29, 2
  %32 = sub i32 %31, %30
  %33 = sub i32 %32, %4
  %34 = sub i32 %33, %27
  %35 = mul i32 %34, 225
  %36 = icmp eq i32 %26, %35
  br i1 %36, label %87, label %204

37:                                               ; preds = %196
  %38 = load ptr, ptr %8, align 8
  %39 = icmp eq ptr %38, null
  %40 = select i1 %39, i32 1506058067, i32 -328687992
  store i32 %40, ptr %5, align 4
  %41 = xor i32 %4, 261626703
  %42 = and i32 %4, %41
  %43 = or i32 %4, %41
  %44 = xor i32 %4, %41
  %45 = sub i32 %43, %44
  %46 = sub i32 %45, %42
  %47 = mul i32 %46, 117
  %48 = icmp ugt i32 %47, 0
  br i1 %48, label %213, label %87

49:                                               ; preds = %190
  store i32 0, ptr %6, align 4
  store i32 -1502472293, ptr %5, align 4
  %50 = xor i32 %4, -240632143
  %51 = and i32 %4, %50
  %52 = or i32 %4, %50
  %53 = xor i32 %4, %50
  %54 = add i32 %4, %50
  %55 = sub i32 %54, %53
  %56 = mul i32 %51, 2
  %57 = sub i32 %55, %56
  %58 = mul i32 %57, 118
  %59 = icmp ugt i32 %58, 0
  br i1 %59, label %221, label %87

60:                                               ; preds = %192
  %61 = load ptr, ptr %7, align 8
  %62 = load ptr, ptr %8, align 8
  %63 = call i32 @strcmp(ptr noundef %61, ptr noundef %62) #11
  %64 = icmp eq i32 %63, 0
  %65 = zext i1 %64 to i32
  store i32 %65, ptr %6, align 4
  store i32 -1502472293, ptr %5, align 4
  %66 = xor i32 %4, -1569811147
  %67 = and i32 %4, %66
  %68 = or i32 %4, %66
  %69 = xor i32 %4, %66
  %70 = add i32 %4, %66
  %71 = sub i32 %70, %69
  %72 = mul i32 %67, 2
  %73 = sub i32 %71, %72
  %74 = mul i32 %73, 11
  %75 = xor i32 %4, -1136589773
  %76 = and i32 %4, %75
  %77 = or i32 %4, %75
  %78 = xor i32 %4, %75
  %79 = mul i32 %77, 2
  %80 = sub i32 %79, %78
  %81 = sub i32 %80, %4
  %82 = sub i32 %81, %75
  %83 = mul i32 %82, 141
  %84 = icmp ne i32 %74, %83
  br i1 %84, label %228, label %87

85:                                               ; preds = %198
  %86 = load i32, ptr %6, align 4
  ret i32 %86

87:                                               ; preds = %279, %272, %263, %253, %244, %228, %221, %213, %204, %156, %136, %123, %112, %99, %60, %49, %37, %14
  br label %9

88:                                               ; preds = %202, %198, %196, %190, %186, %184
  store i32 -1970844024, ptr %5, align 4
  call void asm sideeffect "", ""()
  %89 = xor i32 %4, 586529135
  %90 = and i32 %4, %89
  %91 = or i32 %4, %89
  %92 = xor i32 %4, %89
  %93 = add i32 %4, %89
  %94 = sub i32 %93, %92
  %95 = mul i32 %90, 2
  %96 = sub i32 %94, %95
  %97 = mul i32 %96, 30
  %98 = icmp ne i32 %97, 0
  br i1 %98, label %236, label %9

99:                                               ; preds = %200
  %100 = load i32, ptr %5, align 4
  %101 = xor i32 %100, 736650611
  store i32 %101, ptr %5, align 4
  %102 = xor i32 %4, -985586349
  %103 = and i32 %4, %102
  %104 = or i32 %4, %102
  %105 = xor i32 %4, %102
  %106 = add i32 %4, %102
  %107 = sub i32 %106, %105
  %108 = mul i32 %103, 2
  %109 = sub i32 %107, %108
  %110 = mul i32 %109, 214
  %111 = icmp sle i32 %110, 0
  br i1 %111, label %87, label %244

112:                                              ; preds = %188
  %113 = load i32, ptr %5, align 4
  %114 = xor i32 %113, -295922084
  store i32 %114, ptr %5, align 4
  %115 = xor i32 %4, -1976672611
  %116 = and i32 %4, %115
  %117 = or i32 %4, %115
  %118 = xor i32 %4, %115
  %119 = sub i32 %117, %118
  %120 = sub i32 %119, %116
  %121 = mul i32 %120, 135
  %122 = icmp eq i32 %121, 0
  br i1 %122, label %87, label %253

123:                                              ; preds = %186
  %124 = load i32, ptr %5, align 4
  %125 = xor i32 %124, 1021314284
  store i32 %125, ptr %5, align 4
  %126 = xor i32 %4, 567027539
  %127 = and i32 %4, %126
  %128 = or i32 %4, %126
  %129 = xor i32 %4, %126
  %130 = mul i32 %128, 2
  %131 = sub i32 %130, %129
  %132 = sub i32 %131, %4
  %133 = sub i32 %132, %126
  %134 = mul i32 %133, 227
  %135 = icmp slt i32 %134, 1
  br i1 %135, label %87, label %263

136:                                              ; preds = %184
  %137 = load i32, ptr %5, align 4
  %138 = xor i32 %137, -2064916105
  store i32 %138, ptr %5, align 4
  %139 = xor i32 %4, 920543745
  %140 = and i32 %4, %139
  %141 = or i32 %4, %139
  %142 = xor i32 %4, %139
  %143 = add i32 %140, %141
  %144 = sub i32 %143, %4
  %145 = sub i32 %144, %139
  %146 = mul i32 %145, 94
  %147 = xor i32 %4, -1340691389
  %148 = and i32 %4, %147
  %149 = or i32 %4, %147
  %150 = xor i32 %4, %147
  %151 = add i32 %148, %149
  %152 = sub i32 %151, %4
  %153 = sub i32 %152, %147
  %154 = mul i32 %153, 6
  %155 = icmp eq i32 %146, %154
  br i1 %155, label %87, label %272

156:                                              ; preds = %202
  %157 = load i32, ptr %5, align 4
  %158 = xor i32 %157, 600028718
  store i32 %158, ptr %5, align 4
  %159 = xor i32 %4, 914132279
  %160 = and i32 %4, %159
  %161 = or i32 %4, %159
  %162 = xor i32 %4, %159
  %163 = sub i32 %161, %162
  %164 = sub i32 %163, %160
  %165 = mul i32 %164, 205
  %166 = xor i32 %4, 544777813
  %167 = and i32 %4, %166
  %168 = or i32 %4, %166
  %169 = xor i32 %4, %166
  %170 = add i32 %4, %166
  %171 = sub i32 %170, %169
  %172 = mul i32 %167, 2
  %173 = sub i32 %171, %172
  %174 = mul i32 %173, 93
  %175 = icmp eq i32 %165, %174
  br i1 %175, label %87, label %279

176:                                              ; preds = %9
  %177 = icmp slt i32 %12, 444953983
  br i1 %177, label %180, label %182

178:                                              ; preds = %9
  %179 = icmp slt i32 %12, 1861426076
  br i1 %179, label %192, label %194

180:                                              ; preds = %176
  %181 = icmp eq i32 %12, 74112231
  br i1 %181, label %14, label %184

182:                                              ; preds = %176
  %183 = icmp slt i32 %12, 503407628
  br i1 %183, label %186, label %188

184:                                              ; preds = %180
  %185 = icmp eq i32 %12, 366153147
  br i1 %185, label %136, label %88

186:                                              ; preds = %182
  %187 = icmp eq i32 %12, 444953983
  br i1 %187, label %123, label %88

188:                                              ; preds = %182
  %189 = icmp eq i32 %12, 503407628
  br i1 %189, label %112, label %190

190:                                              ; preds = %188
  %191 = icmp eq i32 %12, 1088421156
  br i1 %191, label %49, label %88

192:                                              ; preds = %178
  %193 = icmp eq i32 %12, 1305021671
  br i1 %193, label %60, label %196

194:                                              ; preds = %178
  %195 = icmp slt i32 %12, 1908422543
  br i1 %195, label %198, label %200

196:                                              ; preds = %192
  %197 = icmp eq i32 %12, 1762913039
  br i1 %197, label %37, label %88

198:                                              ; preds = %194
  %199 = icmp eq i32 %12, 1861426076
  br i1 %199, label %85, label %88

200:                                              ; preds = %194
  %201 = icmp eq i32 %12, 1908422543
  br i1 %201, label %99, label %202

202:                                              ; preds = %200
  %203 = icmp eq i32 %12, 1976017039
  br i1 %203, label %156, label %88

204:                                              ; preds = %14
  %205 = load i64, ptr %3, align 8
  %206 = ptrtoint ptr %0 to i64
  %207 = ptrtoint ptr %1 to i64
  %208 = and i64 %207, %206
  %209 = or i64 %208, %205
  %210 = xor i64 %209, %206
  %211 = and i64 %210, %206
  %212 = sub i64 %211, %205
  store i64 %212, ptr %3, align 8
  br label %87

213:                                              ; preds = %37
  %214 = load i64, ptr %3, align 8
  %215 = ptrtoint ptr %0 to i64
  %216 = ptrtoint ptr %1 to i64
  %217 = add i64 %214, %216
  %218 = sub i64 %217, %216
  %219 = and i64 %218, %214
  %220 = xor i64 %219, %215
  store i64 %220, ptr %3, align 8
  br label %87

221:                                              ; preds = %49
  %222 = load i64, ptr %3, align 8
  %223 = ptrtoint ptr %0 to i64
  %224 = ptrtoint ptr %1 to i64
  %225 = and i64 %222, %224
  %226 = xor i64 %225, %223
  %227 = mul i64 %226, %222
  store i64 %227, ptr %3, align 8
  br label %87

228:                                              ; preds = %60
  %229 = load i64, ptr %3, align 8
  %230 = ptrtoint ptr %0 to i64
  %231 = ptrtoint ptr %1 to i64
  %232 = or i64 %229, %229
  %233 = xor i64 %232, %231
  %234 = add i64 %233, %230
  %235 = sub i64 %234, %230
  store i64 %235, ptr %3, align 8
  br label %87

236:                                              ; preds = %88
  %237 = load i64, ptr %3, align 8
  %238 = ptrtoint ptr %0 to i64
  %239 = ptrtoint ptr %1 to i64
  %240 = add i64 %238, %237
  %241 = add i64 %240, %239
  %242 = and i64 %241, %237
  %243 = mul i64 %242, %238
  store i64 %243, ptr %3, align 8
  br label %9

244:                                              ; preds = %99
  %245 = load i64, ptr %3, align 8
  %246 = ptrtoint ptr %0 to i64
  %247 = ptrtoint ptr %1 to i64
  %248 = mul i64 %247, %247
  %249 = mul i64 %248, %245
  %250 = sub i64 %249, %245
  %251 = sub i64 %250, %247
  %252 = sub i64 %251, %247
  store i64 %252, ptr %3, align 8
  br label %87

253:                                              ; preds = %112
  %254 = load i64, ptr %3, align 8
  %255 = ptrtoint ptr %0 to i64
  %256 = ptrtoint ptr %1 to i64
  %257 = sub i64 %254, %256
  %258 = and i64 %257, %256
  %259 = add i64 %258, %256
  %260 = mul i64 %259, %256
  %261 = xor i64 %260, %254
  %262 = mul i64 %261, %256
  store i64 %262, ptr %3, align 8
  br label %87

263:                                              ; preds = %123
  %264 = load i64, ptr %3, align 8
  %265 = ptrtoint ptr %0 to i64
  %266 = ptrtoint ptr %1 to i64
  %267 = xor i64 %264, %264
  %268 = sub i64 %267, %266
  %269 = or i64 %268, %264
  %270 = xor i64 %269, %265
  %271 = add i64 %270, %264
  store i64 %271, ptr %3, align 8
  br label %87

272:                                              ; preds = %136
  %273 = load i64, ptr %3, align 8
  %274 = ptrtoint ptr %0 to i64
  %275 = ptrtoint ptr %1 to i64
  %276 = sub i64 %275, %273
  %277 = sub i64 %276, %273
  %278 = or i64 %277, %275
  store i64 %278, ptr %3, align 8
  br label %87

279:                                              ; preds = %156
  %280 = load i64, ptr %3, align 8
  %281 = ptrtoint ptr %0 to i64
  %282 = ptrtoint ptr %1 to i64
  %283 = mul i64 %281, %280
  %284 = mul i64 %283, %281
  %285 = or i64 %284, %280
  %286 = and i64 %285, %281
  store i64 %286, ptr %3, align 8
  br label %87
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @options_add_job(ptr noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i64, align 8
  store i64 0, ptr %5, align 8
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca %struct.InputJob, align 8
  store i32 1999196399, ptr %6, align 4
  br label %12

12:                                               ; preds = %230, %82, %81, %4
  %13 = load i32, ptr %6, align 4
  %14 = sub i32 %13, 1246107549
  %15 = mul i32 %14, 552370591
  %16 = icmp slt i32 %15, 1244597242
  br i1 %16, label %160, label %162

17:                                               ; preds = %186
  store ptr %0, ptr %7, align 8
  store i32 %1, ptr %8, align 4
  store ptr %2, ptr %9, align 8
  store ptr %3, ptr %10, align 8
  %18 = load ptr, ptr %7, align 8
  %19 = icmp eq ptr %18, null
  %20 = select i1 %19, i32 -1241720074, i32 -1485141829
  store i32 %20, ptr %6, align 4
  %21 = xor i32 %1, -1830321177
  %22 = and i32 %1, %21
  %23 = or i32 %1, %21
  %24 = xor i32 %1, %21
  %25 = sub i32 %23, %24
  %26 = sub i32 %25, %22
  %27 = mul i32 %26, 95
  %28 = icmp slt i32 %27, 0
  br i1 %28, label %188, label %81

29:                                               ; preds = %170
  call void @die_message(ptr noundef @.str.16)
  store i32 -1485141829, ptr %6, align 4
  %30 = xor i32 %1, 152807223
  %31 = and i32 %1, %30
  %32 = or i32 %1, %30
  %33 = xor i32 %1, %30
  %34 = add i32 %1, %30
  %35 = sub i32 %34, %33
  %36 = mul i32 %31, 2
  %37 = sub i32 %35, %36
  %38 = mul i32 %37, 81
  %39 = icmp ugt i32 %38, 0
  br i1 %39, label %200, label %81

40:                                               ; preds = %180
  %41 = load ptr, ptr %7, align 8
  %42 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %41, i32 0, i32 7
  %43 = load i64, ptr %42, align 8
  %44 = icmp uge i64 %43, 128
  %45 = select i1 %44, i32 702516499, i32 371185494
  store i32 %45, ptr %6, align 4
  %46 = xor i32 %1, 2140415031
  %47 = and i32 %1, %46
  %48 = or i32 %1, %46
  %49 = xor i32 %1, %46
  %50 = add i32 %47, %48
  %51 = sub i32 %50, %1
  %52 = sub i32 %51, %46
  %53 = mul i32 %52, 126
  %54 = icmp sle i32 %53, 0
  br i1 %54, label %81, label %210

55:                                               ; preds = %174
  call void @die_message(ptr noundef @.str.17)
  store i32 371185494, ptr %6, align 4
  %56 = xor i32 %1, -1830494167
  %57 = and i32 %1, %56
  %58 = or i32 %1, %56
  %59 = xor i32 %1, %56
  %60 = sub i32 %58, %59
  %61 = sub i32 %60, %57
  %62 = mul i32 %61, 149
  %63 = icmp slt i32 %62, 1
  br i1 %63, label %81, label %220

64:                                               ; preds = %168
  %65 = load ptr, ptr %7, align 8
  %66 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %65, i32 0, i32 6
  %67 = load ptr, ptr %7, align 8
  %68 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %67, i32 0, i32 7
  %69 = load i64, ptr %68, align 8
  %70 = getelementptr inbounds nuw [128 x %struct.InputJob], ptr %66, i64 0, i64 %69
  %71 = load i32, ptr %8, align 4
  %72 = load ptr, ptr %9, align 8
  %73 = load ptr, ptr %10, align 8
  call void @make_input_job(ptr dead_on_unwind writable sret(%struct.InputJob) align 8 %11, i32 noundef %71, ptr noundef %72, ptr noundef %73)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %70, ptr align 8 %11, i64 24, i1 false)
  %74 = load ptr, ptr %7, align 8
  %75 = getelementptr inbounds nuw %struct.ProgramOptions, ptr %74, i32 0, i32 7
  %76 = load i64, ptr %75, align 8
  %77 = xor i64 %76, 1
  %78 = and i64 %76, 1
  %79 = add i64 %78, %78
  %80 = add i64 %77, %79
  store i64 %80, ptr %75, align 8
  ret void

81:                                               ; preds = %287, %275, %265, %253, %241, %220, %210, %200, %188, %149, %138, %118, %105, %92, %55, %40, %29, %17
  br label %12

82:                                               ; preds = %186, %182, %180, %174, %170, %168
  store i32 1999196399, ptr %6, align 4
  call void asm sideeffect "", ""()
  %83 = xor i32 %1, -2107985435
  %84 = and i32 %1, %83
  %85 = or i32 %1, %83
  %86 = xor i32 %1, %83
  %87 = add i32 %84, %85
  %88 = sub i32 %87, %1
  %89 = sub i32 %88, %83
  %90 = mul i32 %89, 109
  %91 = icmp ne i32 %90, 0
  br i1 %91, label %230, label %12

92:                                               ; preds = %176
  %93 = load i32, ptr %6, align 4
  %94 = xor i32 %93, 1838429737
  store i32 %94, ptr %6, align 4
  %95 = xor i32 %1, 2007374997
  %96 = and i32 %1, %95
  %97 = or i32 %1, %95
  %98 = xor i32 %1, %95
  %99 = add i32 %1, %95
  %100 = sub i32 %99, %98
  %101 = mul i32 %96, 2
  %102 = sub i32 %100, %101
  %103 = mul i32 %102, 154
  %104 = icmp sle i32 %103, 0
  br i1 %104, label %81, label %241

105:                                              ; preds = %164
  %106 = load i32, ptr %6, align 4
  %107 = xor i32 %106, 1645717570
  store i32 %107, ptr %6, align 4
  %108 = xor i32 %1, -1382127211
  %109 = and i32 %1, %108
  %110 = or i32 %1, %108
  %111 = xor i32 %1, %108
  %112 = add i32 %1, %108
  %113 = sub i32 %112, %111
  %114 = mul i32 %109, 2
  %115 = sub i32 %113, %114
  %116 = mul i32 %115, 22
  %117 = icmp eq i32 %116, 0
  br i1 %117, label %81, label %253

118:                                              ; preds = %172
  %119 = load i32, ptr %6, align 4
  %120 = xor i32 %119, -1061979680
  store i32 %120, ptr %6, align 4
  %121 = xor i32 %1, -1969000947
  %122 = and i32 %1, %121
  %123 = or i32 %1, %121
  %124 = xor i32 %1, %121
  %125 = add i32 %1, %121
  %126 = sub i32 %125, %124
  %127 = mul i32 %122, 2
  %128 = sub i32 %126, %127
  %129 = mul i32 %128, 143
  %130 = xor i32 %1, 551921573
  %131 = and i32 %1, %130
  %132 = or i32 %1, %130
  %133 = xor i32 %1, %130
  %134 = sub i32 %132, %133
  %135 = sub i32 %134, %131
  %136 = mul i32 %135, 160
  %137 = icmp ne i32 %129, %136
  br i1 %137, label %265, label %81

138:                                              ; preds = %184
  %139 = load i32, ptr %6, align 4
  %140 = xor i32 %139, -62356005
  store i32 %140, ptr %6, align 4
  %141 = xor i32 %1, -1760803939
  %142 = and i32 %1, %141
  %143 = or i32 %1, %141
  %144 = xor i32 %1, %141
  %145 = sub i32 %143, %144
  %146 = sub i32 %145, %142
  %147 = mul i32 %146, 124
  %148 = icmp ugt i32 %147, 0
  br i1 %148, label %275, label %81

149:                                              ; preds = %182
  %150 = load i32, ptr %6, align 4
  %151 = xor i32 %150, -1575679828
  store i32 %151, ptr %6, align 4
  %152 = xor i32 %1, 422047335
  %153 = and i32 %1, %152
  %154 = or i32 %1, %152
  %155 = xor i32 %1, %152
  %156 = sub i32 %154, %155
  %157 = sub i32 %156, %153
  %158 = mul i32 %157, 234
  %159 = icmp ne i32 %158, 0
  br i1 %159, label %287, label %81

160:                                              ; preds = %12
  %161 = icmp slt i32 %15, 889138503
  br i1 %161, label %164, label %166

162:                                              ; preds = %12
  %163 = icmp slt i32 %15, 1677529659
  br i1 %163, label %176, label %178

164:                                              ; preds = %160
  %165 = icmp eq i32 %15, 675310090
  br i1 %165, label %105, label %168

166:                                              ; preds = %160
  %167 = icmp slt i32 %15, 929278602
  br i1 %167, label %170, label %172

168:                                              ; preds = %164
  %169 = icmp eq i32 %15, 879119591
  br i1 %169, label %64, label %82

170:                                              ; preds = %166
  %171 = icmp eq i32 %15, 889138503
  br i1 %171, label %29, label %82

172:                                              ; preds = %166
  %173 = icmp eq i32 %15, 929278602
  br i1 %173, label %118, label %174

174:                                              ; preds = %172
  %175 = icmp eq i32 %15, 1028155978
  br i1 %175, label %55, label %82

176:                                              ; preds = %162
  %177 = icmp eq i32 %15, 1244597242
  br i1 %177, label %92, label %180

178:                                              ; preds = %162
  %179 = icmp slt i32 %15, 2022013565
  br i1 %179, label %182, label %184

180:                                              ; preds = %176
  %181 = icmp eq i32 %15, 1480220578
  br i1 %181, label %40, label %82

182:                                              ; preds = %178
  %183 = icmp eq i32 %15, 1677529659
  br i1 %183, label %149, label %82

184:                                              ; preds = %178
  %185 = icmp eq i32 %15, 2022013565
  br i1 %185, label %138, label %186

186:                                              ; preds = %184
  %187 = icmp eq i32 %15, 2023418862
  br i1 %187, label %17, label %82

188:                                              ; preds = %17
  %189 = load i64, ptr %5, align 8
  %190 = ptrtoint ptr %0 to i64
  %191 = zext i32 %1 to i64
  %192 = ptrtoint ptr %2 to i64
  %193 = ptrtoint ptr %3 to i64
  %194 = add i64 %190, %191
  %195 = add i64 %194, %192
  %196 = sub i64 %195, %193
  %197 = xor i64 %196, %192
  %198 = xor i64 %197, %192
  %199 = sub i64 %198, %191
  store i64 %199, ptr %5, align 8
  br label %81

200:                                              ; preds = %29
  %201 = load i64, ptr %5, align 8
  %202 = ptrtoint ptr %0 to i64
  %203 = zext i32 %1 to i64
  %204 = ptrtoint ptr %2 to i64
  %205 = ptrtoint ptr %3 to i64
  %206 = or i64 %201, %204
  %207 = add i64 %206, %202
  %208 = xor i64 %207, %205
  %209 = add i64 %208, %201
  store i64 %209, ptr %5, align 8
  br label %81

210:                                              ; preds = %40
  %211 = load i64, ptr %5, align 8
  %212 = ptrtoint ptr %0 to i64
  %213 = zext i32 %1 to i64
  %214 = ptrtoint ptr %2 to i64
  %215 = ptrtoint ptr %3 to i64
  %216 = xor i64 %213, %215
  %217 = mul i64 %216, %214
  %218 = sub i64 %217, %213
  %219 = and i64 %218, %213
  store i64 %219, ptr %5, align 8
  br label %81

220:                                              ; preds = %55
  %221 = load i64, ptr %5, align 8
  %222 = ptrtoint ptr %0 to i64
  %223 = zext i32 %1 to i64
  %224 = ptrtoint ptr %2 to i64
  %225 = ptrtoint ptr %3 to i64
  %226 = add i64 %223, %224
  %227 = mul i64 %226, %223
  %228 = add i64 %227, %225
  %229 = mul i64 %228, %223
  store i64 %229, ptr %5, align 8
  br label %81

230:                                              ; preds = %82
  %231 = load i64, ptr %5, align 8
  %232 = ptrtoint ptr %0 to i64
  %233 = zext i32 %1 to i64
  %234 = ptrtoint ptr %2 to i64
  %235 = ptrtoint ptr %3 to i64
  %236 = xor i64 %235, %234
  %237 = sub i64 %236, %233
  %238 = and i64 %237, %235
  %239 = and i64 %238, %233
  %240 = mul i64 %239, %231
  store i64 %240, ptr %5, align 8
  br label %12

241:                                              ; preds = %92
  %242 = load i64, ptr %5, align 8
  %243 = ptrtoint ptr %0 to i64
  %244 = zext i32 %1 to i64
  %245 = ptrtoint ptr %2 to i64
  %246 = ptrtoint ptr %3 to i64
  %247 = sub i64 %242, %244
  %248 = or i64 %247, %242
  %249 = and i64 %248, %243
  %250 = xor i64 %249, %243
  %251 = or i64 %250, %243
  %252 = sub i64 %251, %243
  store i64 %252, ptr %5, align 8
  br label %81

253:                                              ; preds = %105
  %254 = load i64, ptr %5, align 8
  %255 = ptrtoint ptr %0 to i64
  %256 = zext i32 %1 to i64
  %257 = ptrtoint ptr %2 to i64
  %258 = ptrtoint ptr %3 to i64
  %259 = sub i64 %256, %254
  %260 = xor i64 %259, %257
  %261 = and i64 %260, %254
  %262 = sub i64 %261, %258
  %263 = xor i64 %262, %255
  %264 = sub i64 %263, %256
  store i64 %264, ptr %5, align 8
  br label %81

265:                                              ; preds = %118
  %266 = load i64, ptr %5, align 8
  %267 = ptrtoint ptr %0 to i64
  %268 = zext i32 %1 to i64
  %269 = ptrtoint ptr %2 to i64
  %270 = ptrtoint ptr %3 to i64
  %271 = or i64 %270, %269
  %272 = add i64 %271, %268
  %273 = sub i64 %272, %266
  %274 = and i64 %273, %267
  store i64 %274, ptr %5, align 8
  br label %81

275:                                              ; preds = %138
  %276 = load i64, ptr %5, align 8
  %277 = ptrtoint ptr %0 to i64
  %278 = zext i32 %1 to i64
  %279 = ptrtoint ptr %2 to i64
  %280 = ptrtoint ptr %3 to i64
  %281 = xor i64 %276, %280
  %282 = mul i64 %281, %277
  %283 = add i64 %282, %277
  %284 = sub i64 %283, %276
  %285 = or i64 %284, %277
  %286 = and i64 %285, %276
  store i64 %286, ptr %5, align 8
  br label %81

287:                                              ; preds = %149
  %288 = load i64, ptr %5, align 8
  %289 = ptrtoint ptr %0 to i64
  %290 = zext i32 %1 to i64
  %291 = ptrtoint ptr %2 to i64
  %292 = ptrtoint ptr %3 to i64
  %293 = or i64 %291, %291
  %294 = sub i64 %293, %291
  %295 = and i64 %294, %290
  %296 = mul i64 %295, %292
  %297 = or i64 %296, %290
  %298 = xor i64 %297, %291
  store i64 %298, ptr %5, align 8
  br label %81
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @require_next_arg(i32 noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3) #0 {
  %5 = alloca i64, align 8
  store i64 0, ptr %5, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  store i32 1502763138, ptr %6, align 4
  br label %11

11:                                               ; preds = %181, %83, %82, %4
  %12 = load i32, ptr %6, align 4
  %13 = sub i32 %12, -1076904708
  %14 = mul i32 %13, -807825187
  switch i32 %14, label %83 [
    i32 1662100142, label %15
    i32 1209316905, label %36
    i32 886807021, label %40
    i32 1408315818, label %68
    i32 1418915351, label %72
    i32 1927069243, label %93
    i32 1937429688, label %106
    i32 995189917, label %119
    i32 1113280241, label %132
    i32 11012797, label %144
  ]

15:                                               ; preds = %11
  store i32 %0, ptr %7, align 4
  store ptr %1, ptr %8, align 8
  store i32 %2, ptr %9, align 4
  store ptr %3, ptr %10, align 8
  %16 = load i32, ptr %9, align 4
  %17 = load i32, ptr %6, align 4
  %18 = xor i32 %17, 1502763139
  %19 = or i32 %16, %18
  %20 = load i32, ptr %6, align 4
  %21 = xor i32 %20, 1502763139
  %22 = and i32 %16, %21
  %23 = add i32 %19, %22
  %24 = load i32, ptr %7, align 4
  %25 = icmp sge i32 %23, %24
  %26 = select i1 %25, i32 1203887289, i32 -1084665523
  store i32 %26, ptr %6, align 4
  %27 = xor i32 %0, -310970103
  %28 = and i32 %0, %27
  %29 = or i32 %0, %27
  %30 = xor i32 %0, %27
  %31 = add i32 %28, %29
  %32 = sub i32 %31, %0
  %33 = sub i32 %32, %27
  %34 = mul i32 %33, 30
  %35 = icmp slt i32 %34, 0
  br i1 %35, label %157, label %82

36:                                               ; preds = %11
  %37 = load ptr, ptr @stderr, align 8
  %38 = load ptr, ptr %10, align 8
  %39 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %37, ptr noundef @.str.20, ptr noundef %38) #9
  call void @exit(i32 noundef 1) #10
  unreachable

40:                                               ; preds = %11
  %41 = load ptr, ptr %8, align 8
  %42 = load i32, ptr %9, align 4
  %43 = load i32, ptr %6, align 4
  %44 = xor i32 %43, -1084665524
  %45 = sub i32 %42, %44
  %46 = load i32, ptr %6, align 4
  %47 = xor i32 %46, -1084665521
  %48 = mul i32 %42, %47
  %49 = load i32, ptr %6, align 4
  %50 = xor i32 %49, -1084665524
  %51 = mul i32 %50, %45
  %52 = sub i32 %48, %51
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds ptr, ptr %41, i64 %53
  %55 = load ptr, ptr %54, align 8
  %56 = icmp eq ptr %55, null
  %57 = select i1 %56, i32 1862309294, i32 -1553371521
  store i32 %57, ptr %6, align 4
  %58 = xor i32 %0, -1741487549
  %59 = and i32 %0, %58
  %60 = or i32 %0, %58
  %61 = xor i32 %0, %58
  %62 = mul i32 %60, 2
  %63 = sub i32 %62, %61
  %64 = sub i32 %63, %0
  %65 = sub i32 %64, %58
  %66 = mul i32 %65, 127
  %67 = icmp sgt i32 %66, 0
  br i1 %67, label %169, label %82

68:                                               ; preds = %11
  %69 = load ptr, ptr @stderr, align 8
  %70 = load ptr, ptr %10, align 8
  %71 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %69, ptr noundef @.str.21, ptr noundef %70) #9
  call void @exit(i32 noundef 1) #10
  unreachable

72:                                               ; preds = %11
  %73 = load i32, ptr %9, align 4
  %74 = load i32, ptr %6, align 4
  %75 = xor i32 %74, -1553371522
  %76 = xor i32 %73, %75
  %77 = load i32, ptr %6, align 4
  %78 = xor i32 %77, -1553371522
  %79 = and i32 %73, %78
  %80 = add i32 %79, %79
  %81 = add i32 %76, %80
  ret i32 %81

82:                                               ; preds = %236, %225, %214, %202, %193, %169, %157, %144, %132, %119, %106, %93, %40, %15
  br label %11

83:                                               ; preds = %11
  store i32 1502763138, ptr %6, align 4
  call void asm sideeffect "", ""()
  %84 = xor i32 %0, -725679837
  %85 = and i32 %0, %84
  %86 = or i32 %0, %84
  %87 = xor i32 %0, %84
  %88 = add i32 %85, %86
  %89 = sub i32 %88, %0
  %90 = sub i32 %89, %84
  %91 = mul i32 %90, 116
  %92 = icmp slt i32 %91, 0
  br i1 %92, label %181, label %11

93:                                               ; preds = %11
  %94 = load i32, ptr %6, align 4
  %95 = xor i32 %94, 248135298
  store i32 %95, ptr %6, align 4
  %96 = xor i32 %0, 411544271
  %97 = and i32 %0, %96
  %98 = or i32 %0, %96
  %99 = xor i32 %0, %96
  %100 = mul i32 %98, 2
  %101 = sub i32 %100, %99
  %102 = sub i32 %101, %0
  %103 = sub i32 %102, %96
  %104 = mul i32 %103, 9
  %105 = icmp sgt i32 %104, 0
  br i1 %105, label %193, label %82

106:                                              ; preds = %11
  %107 = load i32, ptr %6, align 4
  %108 = xor i32 %107, 1620824172
  store i32 %108, ptr %6, align 4
  %109 = xor i32 %0, 1434306733
  %110 = and i32 %0, %109
  %111 = or i32 %0, %109
  %112 = xor i32 %0, %109
  %113 = add i32 %0, %109
  %114 = sub i32 %113, %112
  %115 = mul i32 %110, 2
  %116 = sub i32 %114, %115
  %117 = mul i32 %116, 245
  %118 = icmp ugt i32 %117, 0
  br i1 %118, label %202, label %82

119:                                              ; preds = %11
  %120 = load i32, ptr %6, align 4
  %121 = xor i32 %120, 1820071018
  store i32 %121, ptr %6, align 4
  %122 = xor i32 %0, -1538424993
  %123 = and i32 %0, %122
  %124 = or i32 %0, %122
  %125 = xor i32 %0, %122
  %126 = mul i32 %124, 2
  %127 = sub i32 %126, %125
  %128 = sub i32 %127, %0
  %129 = sub i32 %128, %122
  %130 = mul i32 %129, 39
  %131 = icmp slt i32 %130, 1
  br i1 %131, label %82, label %214

132:                                              ; preds = %11
  %133 = load i32, ptr %6, align 4
  %134 = xor i32 %133, -1058166412
  store i32 %134, ptr %6, align 4
  %135 = xor i32 %0, -638606921
  %136 = and i32 %0, %135
  %137 = or i32 %0, %135
  %138 = xor i32 %0, %135
  %139 = add i32 %136, %137
  %140 = sub i32 %139, %0
  %141 = sub i32 %140, %135
  %142 = mul i32 %141, 27
  %143 = icmp ne i32 %142, 0
  br i1 %143, label %225, label %82

144:                                              ; preds = %11
  %145 = load i32, ptr %6, align 4
  %146 = xor i32 %145, 2002987251
  store i32 %146, ptr %6, align 4
  %147 = xor i32 %0, 1360204755
  %148 = and i32 %0, %147
  %149 = or i32 %0, %147
  %150 = xor i32 %0, %147
  %151 = add i32 %0, %147
  %152 = sub i32 %151, %150
  %153 = mul i32 %148, 2
  %154 = sub i32 %152, %153
  %155 = mul i32 %154, 249
  %156 = icmp eq i32 %155, 0
  br i1 %156, label %82, label %236

157:                                              ; preds = %15
  %158 = load i64, ptr %5, align 8
  %159 = zext i32 %0 to i64
  %160 = ptrtoint ptr %1 to i64
  %161 = zext i32 %2 to i64
  %162 = ptrtoint ptr %3 to i64
  %163 = or i64 %161, %160
  %164 = xor i64 %163, %162
  %165 = add i64 %164, %159
  %166 = mul i64 %165, %158
  %167 = sub i64 %166, %161
  %168 = add i64 %167, %158
  store i64 %168, ptr %5, align 8
  br label %82

169:                                              ; preds = %40
  %170 = load i64, ptr %5, align 8
  %171 = zext i32 %0 to i64
  %172 = ptrtoint ptr %1 to i64
  %173 = zext i32 %2 to i64
  %174 = ptrtoint ptr %3 to i64
  %175 = sub i64 %173, %171
  %176 = add i64 %175, %173
  %177 = mul i64 %176, %174
  %178 = and i64 %177, %172
  %179 = and i64 %178, %172
  %180 = and i64 %179, %174
  store i64 %180, ptr %5, align 8
  br label %82

181:                                              ; preds = %83
  %182 = load i64, ptr %5, align 8
  %183 = zext i32 %0 to i64
  %184 = ptrtoint ptr %1 to i64
  %185 = zext i32 %2 to i64
  %186 = ptrtoint ptr %3 to i64
  %187 = sub i64 %185, %185
  %188 = sub i64 %187, %183
  %189 = or i64 %188, %184
  %190 = sub i64 %189, %186
  %191 = sub i64 %190, %184
  %192 = add i64 %191, %183
  store i64 %192, ptr %5, align 8
  br label %11

193:                                              ; preds = %93
  %194 = load i64, ptr %5, align 8
  %195 = zext i32 %0 to i64
  %196 = ptrtoint ptr %1 to i64
  %197 = zext i32 %2 to i64
  %198 = ptrtoint ptr %3 to i64
  %199 = xor i64 %197, %197
  %200 = mul i64 %199, %198
  %201 = add i64 %200, %196
  store i64 %201, ptr %5, align 8
  br label %82

202:                                              ; preds = %106
  %203 = load i64, ptr %5, align 8
  %204 = zext i32 %0 to i64
  %205 = ptrtoint ptr %1 to i64
  %206 = zext i32 %2 to i64
  %207 = ptrtoint ptr %3 to i64
  %208 = xor i64 %206, %203
  %209 = or i64 %208, %205
  %210 = and i64 %209, %207
  %211 = or i64 %210, %204
  %212 = sub i64 %211, %207
  %213 = xor i64 %212, %206
  store i64 %213, ptr %5, align 8
  br label %82

214:                                              ; preds = %119
  %215 = load i64, ptr %5, align 8
  %216 = zext i32 %0 to i64
  %217 = ptrtoint ptr %1 to i64
  %218 = zext i32 %2 to i64
  %219 = ptrtoint ptr %3 to i64
  %220 = xor i64 %216, %218
  %221 = mul i64 %220, %219
  %222 = mul i64 %221, %215
  %223 = xor i64 %222, %219
  %224 = or i64 %223, %218
  store i64 %224, ptr %5, align 8
  br label %82

225:                                              ; preds = %132
  %226 = load i64, ptr %5, align 8
  %227 = zext i32 %0 to i64
  %228 = ptrtoint ptr %1 to i64
  %229 = zext i32 %2 to i64
  %230 = ptrtoint ptr %3 to i64
  %231 = and i64 %226, %226
  %232 = add i64 %231, %227
  %233 = or i64 %232, %227
  %234 = or i64 %233, %227
  %235 = sub i64 %234, %229
  store i64 %235, ptr %5, align 8
  br label %82

236:                                              ; preds = %144
  %237 = load i64, ptr %5, align 8
  %238 = zext i32 %0 to i64
  %239 = ptrtoint ptr %1 to i64
  %240 = zext i32 %2 to i64
  %241 = ptrtoint ptr %3 to i64
  %242 = add i64 %237, %237
  %243 = add i64 %242, %240
  %244 = xor i64 %243, %238
  %245 = and i64 %244, %241
  store i64 %245, ptr %5, align 8
  br label %82
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @string_starts_with_dash(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca i1, align 1
  %6 = alloca ptr, align 8
  store i32 -1126538118, ptr %4, align 4
  br label %7

7:                                                ; preds = %117, %53, %52, %1
  %8 = load i32, ptr %4, align 4
  %9 = sub i32 %8, 541418263
  %10 = mul i32 %9, 1147447263
  switch i32 %10, label %53 [
    i32 1885325885, label %11
    i32 696214339, label %24
    i32 819152057, label %49
    i32 1656643959, label %64
    i32 53435926, label %76
    i32 331876459, label %89
  ]

11:                                               ; preds = %7
  store ptr %0, ptr %6, align 8
  %12 = load ptr, ptr %6, align 8
  %13 = icmp ne ptr %12, null
  store i1 false, ptr %5, align 1
  %14 = select i1 %13, i32 1927603252, i32 -1770985090
  store i32 %14, ptr %4, align 4
  %15 = xor i32 %3, 2011879613
  %16 = and i32 %3, %15
  %17 = or i32 %3, %15
  %18 = xor i32 %3, %15
  %19 = add i32 %16, %17
  %20 = sub i32 %19, %3
  %21 = sub i32 %20, %15
  %22 = mul i32 %21, 20
  %23 = icmp slt i32 %22, 0
  br i1 %23, label %100, label %52

24:                                               ; preds = %7
  %25 = load ptr, ptr %6, align 8
  %26 = getelementptr inbounds i8, ptr %25, i64 0
  %27 = load i8, ptr %26, align 1
  %28 = sext i8 %27 to i32
  %29 = icmp eq i32 %28, 45
  store i1 %29, ptr %5, align 1
  store i32 -1770985090, ptr %4, align 4
  %30 = xor i32 %3, 2016367429
  %31 = and i32 %3, %30
  %32 = or i32 %3, %30
  %33 = xor i32 %3, %30
  %34 = mul i32 %32, 2
  %35 = sub i32 %34, %33
  %36 = sub i32 %35, %3
  %37 = sub i32 %36, %30
  %38 = mul i32 %37, 219
  %39 = xor i32 %3, -1734887887
  %40 = and i32 %3, %39
  %41 = or i32 %3, %39
  %42 = xor i32 %3, %39
  %43 = add i32 %3, %39
  %44 = sub i32 %43, %42
  %45 = mul i32 %40, 2
  %46 = sub i32 %44, %45
  %47 = mul i32 %46, 151
  %48 = icmp ne i32 %38, %47
  br i1 %48, label %109, label %52

49:                                               ; preds = %7
  %50 = load i1, ptr %5, align 1
  %51 = zext i1 %50 to i32
  ret i32 %51

52:                                               ; preds = %136, %129, %123, %109, %100, %89, %76, %64, %24, %11
  br label %7

53:                                               ; preds = %7
  store i32 -1126538118, ptr %4, align 4
  call void asm sideeffect "", ""()
  %54 = xor i32 %3, -1122677939
  %55 = and i32 %3, %54
  %56 = or i32 %3, %54
  %57 = xor i32 %3, %54
  %58 = mul i32 %56, 2
  %59 = sub i32 %58, %57
  %60 = sub i32 %59, %3
  %61 = sub i32 %60, %54
  %62 = mul i32 %61, 120
  %63 = icmp sgt i32 %62, 0
  br i1 %63, label %117, label %7

64:                                               ; preds = %7
  %65 = load i32, ptr %4, align 4
  %66 = xor i32 %65, 204590875
  store i32 %66, ptr %4, align 4
  %67 = xor i32 %3, -438279811
  %68 = and i32 %3, %67
  %69 = or i32 %3, %67
  %70 = xor i32 %3, %67
  %71 = add i32 %68, %69
  %72 = sub i32 %71, %3
  %73 = sub i32 %72, %67
  %74 = mul i32 %73, 35
  %75 = icmp ne i32 %74, 0
  br i1 %75, label %123, label %52

76:                                               ; preds = %7
  %77 = load i32, ptr %4, align 4
  %78 = xor i32 %77, -1677974845
  store i32 %78, ptr %4, align 4
  %79 = xor i32 %3, -1474725615
  %80 = and i32 %3, %79
  %81 = or i32 %3, %79
  %82 = xor i32 %3, %79
  %83 = add i32 %3, %79
  %84 = sub i32 %83, %82
  %85 = mul i32 %80, 2
  %86 = sub i32 %84, %85
  %87 = mul i32 %86, 20
  %88 = icmp ne i32 %87, 0
  br i1 %88, label %129, label %52

89:                                               ; preds = %7
  %90 = load i32, ptr %4, align 4
  %91 = xor i32 %90, -1497226255
  store i32 %91, ptr %4, align 4
  %92 = xor i32 %3, -594885261
  %93 = and i32 %3, %92
  %94 = or i32 %3, %92
  %95 = xor i32 %3, %92
  %96 = sub i32 %94, %95
  %97 = sub i32 %96, %93
  %98 = mul i32 %97, 222
  %99 = icmp eq i32 %98, 0
  br i1 %99, label %52, label %136

100:                                              ; preds = %11
  %101 = load i64, ptr %2, align 8
  %102 = ptrtoint ptr %0 to i64
  %103 = add i64 %102, %101
  %104 = and i64 %103, %101
  %105 = xor i64 %104, %102
  %106 = xor i64 %105, %102
  %107 = or i64 %106, %102
  %108 = sub i64 %107, %102
  store i64 %108, ptr %2, align 8
  br label %52

109:                                              ; preds = %24
  %110 = load i64, ptr %2, align 8
  %111 = ptrtoint ptr %0 to i64
  %112 = xor i64 %110, %110
  %113 = sub i64 %112, %110
  %114 = or i64 %113, %110
  %115 = add i64 %114, %110
  %116 = xor i64 %115, %110
  store i64 %116, ptr %2, align 8
  br label %52

117:                                              ; preds = %53
  %118 = load i64, ptr %2, align 8
  %119 = ptrtoint ptr %0 to i64
  %120 = sub i64 %119, %119
  %121 = mul i64 %120, %118
  %122 = add i64 %121, %119
  store i64 %122, ptr %2, align 8
  br label %7

123:                                              ; preds = %64
  %124 = load i64, ptr %2, align 8
  %125 = ptrtoint ptr %0 to i64
  %126 = mul i64 %124, %125
  %127 = mul i64 %126, %124
  %128 = and i64 %127, %124
  store i64 %128, ptr %2, align 8
  br label %52

129:                                              ; preds = %76
  %130 = load i64, ptr %2, align 8
  %131 = ptrtoint ptr %0 to i64
  %132 = add i64 %130, %131
  %133 = xor i64 %132, %130
  %134 = add i64 %133, %130
  %135 = add i64 %134, %130
  store i64 %135, ptr %2, align 8
  br label %52

136:                                              ; preds = %89
  %137 = load i64, ptr %2, align 8
  %138 = ptrtoint ptr %0 to i64
  %139 = and i64 %137, %138
  %140 = xor i64 %139, %138
  %141 = add i64 %140, %137
  %142 = or i64 %141, %138
  %143 = add i64 %142, %137
  %144 = or i64 %143, %138
  store i64 %144, ptr %2, align 8
  br label %52
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

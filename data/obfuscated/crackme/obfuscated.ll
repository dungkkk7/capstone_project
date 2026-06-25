; ModuleID = 'data/obfuscated/crackme/obfuscated.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Node = type { i32, i32, i32, i8, [16 x i8] }
%union.WordView = type { i32 }

@__const.big_edge_function.ops = private unnamed_addr constant [3 x ptr] [ptr @helper_muladd, ptr @helper_xor, ptr @helper_mix], align 16
@.str = private unnamed_addr constant [10 x i8] c"node_%02d\00", align 1
@.str.1 = private unnamed_addr constant [58 x i8] c"  [clean-debug] i=%zu ch='%c' acc=0x%08x checksum=0x%08x\0A\00", align 1
@.str.2 = private unnamed_addr constant [39 x i8] c"  [clean-debug] end of i=%zu score=%d\0A\00", align 1
@.str.3 = private unnamed_addr constant [23 x i8] c"[+] input length: %zu\0A\00", align 1
@.str.4 = private unnamed_addr constant [14 x i8] c"[+] mode: %d\0A\00", align 1
@.str.5 = private unnamed_addr constant [16 x i8] c"[+] result: %d\0A\00", align 1
@.str.6 = private unnamed_addr constant [23 x i8] c"rare_path: exact magic\00", align 1
@.str.7 = private unnamed_addr constant [23 x i8] c"rare_path: beef suffix\00", align 1
@.str.8 = private unnamed_addr constant [16 x i8] c"negative result\00", align 1
@.str.9 = private unnamed_addr constant [12 x i8] c"zero result\00", align 1
@.str.10 = private unnamed_addr constant [14 x i8] c"normal result\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @big_edge_function(ptr noundef %0, i64 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i64, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca [8 x %struct.Node], align 16
  %13 = alloca %union.WordView, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca [3 x ptr], align 16
  %20 = alloca i32, align 4
  %21 = alloca i64, align 8
  %22 = alloca i8, align 1
  %23 = alloca i32, align 4
  %24 = alloca i32, align 4
  %25 = alloca [4 x [4 x i32]], align 16
  %26 = alloca i32, align 4
  %27 = alloca i32, align 4
  %28 = alloca i32, align 4
  %29 = alloca i32, align 4
  %30 = alloca i32, align 4
  %31 = alloca i32, align 4
  store i32 1560964999, ptr %5, align 4
  br label %32

32:                                               ; preds = %4016, %2945, %2944, %3
  %33 = load i32, ptr %5, align 4
  %34 = sub i32 %33, -212200482
  %35 = mul i32 %34, -1343014907
  switch i32 %35, label %2945 [
    i32 753517133, label %36
    i32 1286153554, label %55
    i32 900267055, label %67
    i32 1778729903, label %114
    i32 1809140927, label %138
    i32 259153452, label %160
    i32 1715210011, label %208
    i32 1810943323, label %222
    i32 124550598, label %231
    i32 912412178, label %254
    i32 968520840, label %268
    i32 945987273, label %289
    i32 1162984337, label %311
    i32 39342665, label %322
    i32 1407612714, label %337
    i32 685184061, label %468
    i32 1652340603, label %499
    i32 1034826819, label %527
    i32 222617335, label %570
    i32 11147502, label %597
    i32 1591450685, label %637
    i32 1539161282, label %681
    i32 1547031496, label %721
    i32 1150638087, label %731
    i32 1018963107, label %746
    i32 649024441, label %774
    i32 180673332, label %824
    i32 1424079955, label %835
    i32 755882493, label %846
    i32 666082415, label %855
    i32 1299591106, label %914
    i32 1646578021, label %935
    i32 1094752731, label %957
    i32 678420113, label %992
    i32 1366121799, label %1022
    i32 665161733, label %1118
    i32 1635880090, label %1209
    i32 732873089, label %1239
    i32 912506734, label %1255
    i32 440827983, label %1283
    i32 8349486, label %1303
    i32 407197127, label %1322
    i32 469398245, label %1343
    i32 175992727, label %1362
    i32 1672318714, label %1410
    i32 670960124, label %1426
    i32 632209053, label %1487
    i32 1667464335, label %1518
    i32 1800967498, label %1542
    i32 1907058347, label %1558
    i32 894890419, label %1578
    i32 749736977, label %1588
    i32 1961172393, label %1600
    i32 972708105, label %1645
    i32 650439351, label %1656
    i32 1177369363, label %1670
    i32 852539963, label %1716
    i32 1615168452, label %1736
    i32 2135713618, label %1765
    i32 2113088390, label %1785
    i32 200001552, label %1817
    i32 342687488, label %1826
    i32 1364471176, label %1862
    i32 611850613, label %1873
    i32 964651727, label %1925
    i32 1791998579, label %1944
    i32 384447093, label %1961
    i32 829471968, label %1998
    i32 1034075228, label %2018
    i32 167622273, label %2032
    i32 679577690, label %2054
    i32 1761569035, label %2084
    i32 1669554867, label %2128
    i32 961191413, label %2137
    i32 1798434106, label %2151
    i32 2014027158, label %2171
    i32 1778597130, label %2185
    i32 360563134, label %2196
    i32 1684073521, label %2209
    i32 1216644386, label %2258
    i32 2077063222, label %2279
    i32 416465735, label %2301
    i32 820677742, label %2320
    i32 2126902405, label %2345
    i32 1243892919, label %2356
    i32 363164973, label %2370
    i32 9435145, label %2394
    i32 1141822257, label %2418
    i32 786092614, label %2438
    i32 1463475600, label %2464
    i32 579650819, label %2505
    i32 127237265, label %2516
    i32 1190193303, label %2536
    i32 70557149, label %2548
    i32 1817726718, label %2569
    i32 1336938275, label %2583
    i32 132533464, label %2603
    i32 1903443432, label %2627
    i32 1766782445, label %2646
    i32 234435494, label %2668
    i32 817180379, label %2714
    i32 1118173620, label %2736
    i32 713617209, label %2751
    i32 2124165753, label %2763
    i32 2110794420, label %2776
    i32 2072910961, label %2800
    i32 1691023752, label %2810
    i32 274548295, label %2829
    i32 987610922, label %2843
    i32 1929371650, label %2862
    i32 362526073, label %2893
    i32 1226793122, label %2902
    i32 992818818, label %2942
    i32 1867995967, label %2956
    i32 739015668, label %2969
    i32 186467604, label %2991
    i32 1897994500, label %3002
    i32 364239696, label %3013
    i32 1986965878, label %3026
    i32 1302761204, label %3039
    i32 1507908301, label %3052
  ]

36:                                               ; preds = %32
  store ptr %0, ptr %8, align 8
  store i64 %1, ptr %9, align 8
  store i32 %2, ptr %10, align 4
  store volatile i32 -1515870811, ptr %11, align 4
  store i32 322376503, ptr %14, align 4
  store i32 0, ptr %15, align 4
  store i32 0, ptr %16, align 4
  store i32 0, ptr %17, align 4
  store i32 0, ptr %18, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %19, ptr align 16 @__const.big_edge_function.ops, i64 24, i1 false)
  %37 = getelementptr inbounds [8 x %struct.Node], ptr %12, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %37, i8 0, i64 256, i1 false)
  store i32 0, ptr %20, align 4
  store i32 -1624973688, ptr %5, align 4
  %38 = xor i64 %1, -2904668449045812751
  %39 = and i64 %1, %38
  %40 = or i64 %1, %38
  %41 = xor i64 %1, %38
  %42 = add i64 %1, %38
  %43 = sub i64 %42, %41
  %44 = mul i64 %39, 2
  %45 = sub i64 %43, %44
  %46 = mul i64 %45, 33
  %47 = xor i64 %1, 1211711244891760165
  %48 = and i64 %1, %47
  %49 = or i64 %1, %47
  %50 = xor i64 %1, %47
  %51 = sub i64 %49, %50
  %52 = sub i64 %51, %48
  %53 = mul i64 %52, 244
  %54 = icmp eq i64 %46, %53
  br i1 %54, label %2944, label %3072

55:                                               ; preds = %32
  %56 = load i32, ptr %20, align 4
  %57 = icmp slt i32 %56, 8
  %58 = select i1 %57, i32 1259008385, i32 -562683779
  store i32 %58, ptr %5, align 4
  %59 = xor i64 %1, 8464363127562536729
  %60 = and i64 %1, %59
  %61 = or i64 %1, %59
  %62 = xor i64 %1, %59
  %63 = sub i64 %61, %62
  %64 = sub i64 %63, %60
  %65 = mul i64 %64, 10
  %66 = icmp slt i64 %65, 0
  br i1 %66, label %3080, label %2944

67:                                               ; preds = %32
  %68 = load i32, ptr %20, align 4
  %69 = load i32, ptr %5, align 4
  %70 = xor i32 %69, 1259073664
  %71 = mul i32 %68, %70
  %72 = load i32, ptr %5, align 4
  %73 = xor i32 %72, 1480450742
  %74 = or i32 %73, %71
  %75 = load i32, ptr %5, align 4
  %76 = xor i32 %75, 1480450742
  %77 = and i32 %76, %71
  %78 = add i32 %74, %77
  %79 = load i32, ptr %20, align 4
  %80 = sext i32 %79 to i64
  %81 = getelementptr inbounds [8 x %struct.Node], ptr %12, i64 0, i64 %80
  %82 = getelementptr inbounds nuw %struct.Node, ptr %81, i32 0, i32 0
  store i32 %78, ptr %82, align 16
  %83 = load i32, ptr %20, align 4
  %84 = load i32, ptr %5, align 4
  %85 = xor i32 %84, 1258877827
  %86 = mul i32 %83, %85
  %87 = load i32, ptr %5, align 4
  %88 = xor i32 %87, 1259008384
  %89 = add i32 %86, %88
  %90 = load i32, ptr %5, align 4
  %91 = xor i32 %90, -1784197266
  %92 = mul i32 %91, %89
  %93 = load i32, ptr %5, align 4
  %94 = xor i32 %93, -1784197263
  %95 = mul i32 %86, %94
  %96 = sub i32 %92, %95
  %97 = load i32, ptr %20, align 4
  %98 = sext i32 %97 to i64
  %99 = getelementptr inbounds [8 x %struct.Node], ptr %12, i64 0, i64 %98
  %100 = getelementptr inbounds nuw %struct.Node, ptr %99, i32 0, i32 1
  store i32 %96, ptr %100, align 4
  %101 = load i32, ptr %20, align 4
  %102 = srem i32 %101, 2
  %103 = icmp eq i32 %102, 0
  %104 = select i1 %103, i32 1747333889, i32 -625036079
  store i32 %104, ptr %5, align 4
  %105 = xor i64 %1, 3132232224723265551
  %106 = and i64 %1, %105
  %107 = or i64 %1, %105
  %108 = xor i64 %1, %105
  %109 = add i64 %106, %107
  %110 = sub i64 %109, %1
  %111 = sub i64 %110, %105
  %112 = mul i64 %111, 186
  %113 = icmp uge i64 %112, 0
  br i1 %113, label %2944, label %3090

114:                                              ; preds = %32
  %115 = load i32, ptr %20, align 4
  %116 = load i32, ptr %5, align 4
  %117 = xor i32 %116, 1747333989
  %118 = mul nsw i32 %115, %117
  store i32 %118, ptr %6, align 4
  store i32 1452010778, ptr %5, align 4
  %119 = xor i64 %1, -6185276026121993215
  %120 = and i64 %1, %119
  %121 = or i64 %1, %119
  %122 = xor i64 %1, %119
  %123 = add i64 %1, %119
  %124 = sub i64 %123, %122
  %125 = mul i64 %120, 2
  %126 = sub i64 %124, %125
  %127 = mul i64 %126, 245
  %128 = xor i64 %1, 6833141033071000239
  %129 = and i64 %1, %128
  %130 = or i64 %1, %128
  %131 = xor i64 %1, %128
  %132 = mul i64 %130, 2
  %133 = sub i64 %132, %131
  %134 = sub i64 %133, %1
  %135 = sub i64 %134, %128
  %136 = mul i64 %135, 136
  %137 = icmp eq i64 %127, %136
  br i1 %137, label %2944, label %3100

138:                                              ; preds = %32
  %139 = load i32, ptr %20, align 4
  %140 = load i32, ptr %5, align 4
  %141 = xor i32 %140, 625036078
  %142 = xor i32 %139, %141
  %143 = load i32, ptr %5, align 4
  %144 = xor i32 %143, -625036079
  %145 = add i32 %144, %142
  %146 = load i32, ptr %5, align 4
  %147 = xor i32 %146, -625036080
  %148 = add i32 %145, %147
  %149 = load i32, ptr %5, align 4
  %150 = xor i32 %149, -625036132
  %151 = mul nsw i32 %148, %150
  store i32 %151, ptr %6, align 4
  store i32 1452010778, ptr %5, align 4
  %152 = xor i64 %1, 717036042237356315
  %153 = and i64 %1, %152
  %154 = or i64 %1, %152
  %155 = xor i64 %1, %152
  %156 = sub i64 %154, %155
  %157 = sub i64 %156, %153
  %158 = mul i64 %157, 222
  %159 = icmp uge i64 %158, 0
  br i1 %159, label %2944, label %3107

160:                                              ; preds = %32
  %161 = load i32, ptr %6, align 4
  %162 = load i32, ptr %20, align 4
  %163 = sext i32 %162 to i64
  %164 = getelementptr inbounds [8 x %struct.Node], ptr %12, i64 0, i64 %163
  %165 = getelementptr inbounds nuw %struct.Node, ptr %164, i32 0, i32 2
  store i32 %161, ptr %165, align 8
  %166 = load i32, ptr %20, align 4
  %167 = load i32, ptr %5, align 4
  %168 = xor i32 %167, 1452010775
  %169 = mul nsw i32 %166, %168
  %170 = load i32, ptr %5, align 4
  %171 = xor i32 %170, 1452010781
  %172 = or i32 %169, %171
  %173 = load i32, ptr %5, align 4
  %174 = xor i32 %173, 1452010781
  %175 = and i32 %169, %174
  %176 = add i32 %172, %175
  %177 = trunc i32 %176 to i8
  %178 = load i32, ptr %20, align 4
  %179 = sext i32 %178 to i64
  %180 = getelementptr inbounds [8 x %struct.Node], ptr %12, i64 0, i64 %179
  %181 = getelementptr inbounds nuw %struct.Node, ptr %180, i32 0, i32 3
  store i8 %177, ptr %181, align 4
  %182 = load i32, ptr %20, align 4
  %183 = sext i32 %182 to i64
  %184 = getelementptr inbounds [8 x %struct.Node], ptr %12, i64 0, i64 %183
  %185 = getelementptr inbounds nuw %struct.Node, ptr %184, i32 0, i32 4
  %186 = getelementptr inbounds [16 x i8], ptr %185, i64 0, i64 0
  %187 = load i32, ptr %20, align 4
  %188 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef %186, i64 noundef 16, ptr noundef @.str, i32 noundef %187) #7
  %189 = load i32, ptr %20, align 4
  %190 = load i32, ptr %5, align 4
  %191 = xor i32 %190, 1452010779
  %192 = xor i32 %189, %191
  %193 = load i32, ptr %5, align 4
  %194 = xor i32 %193, 1452010779
  %195 = and i32 %189, %194
  %196 = add i32 %195, %195
  %197 = add i32 %192, %196
  store i32 %197, ptr %20, align 4
  store i32 -1624973688, ptr %5, align 4
  %198 = xor i64 %1, 9217841482254960227
  %199 = and i64 %1, %198
  %200 = or i64 %1, %198
  %201 = xor i64 %1, %198
  %202 = add i64 %1, %198
  %203 = sub i64 %202, %201
  %204 = mul i64 %199, 2
  %205 = sub i64 %203, %204
  %206 = mul i64 %205, 40
  %207 = icmp uge i64 %206, 0
  br i1 %207, label %2944, label %3117

208:                                              ; preds = %32
  %209 = load ptr, ptr %8, align 8
  %210 = icmp eq ptr %209, null
  %211 = select i1 %210, i32 -228204099, i32 -281885844
  store i32 %211, ptr %5, align 4
  %212 = xor i64 %1, -8793837724813647087
  %213 = and i64 %1, %212
  %214 = or i64 %1, %212
  %215 = xor i64 %1, %212
  %216 = add i64 %1, %212
  %217 = sub i64 %216, %215
  %218 = mul i64 %213, 2
  %219 = sub i64 %217, %218
  %220 = mul i64 %219, 114
  %221 = icmp sle i64 %220, 0
  br i1 %221, label %2944, label %3124

222:                                              ; preds = %32
  store i32 -9999, ptr %7, align 4
  store i32 1940021752, ptr %5, align 4
  %223 = xor i64 %1, -6565034673744042341
  %224 = and i64 %1, %223
  %225 = or i64 %1, %223
  %226 = xor i64 %1, %223
  %227 = sub i64 %225, %226
  %228 = sub i64 %227, %224
  %229 = mul i64 %228, 187
  %230 = icmp ugt i64 %229, 0
  br i1 %230, label %3131, label %2944

231:                                              ; preds = %32
  %232 = load i64, ptr %9, align 8
  %233 = icmp eq i64 %232, 0
  %234 = select i1 %233, i32 -668368824, i32 1911162054
  store i32 %234, ptr %5, align 4
  %235 = xor i64 %1, 4586445925725545615
  %236 = and i64 %1, %235
  %237 = or i64 %1, %235
  %238 = xor i64 %1, %235
  %239 = add i64 %1, %235
  %240 = sub i64 %239, %238
  %241 = mul i64 %236, 2
  %242 = sub i64 %240, %241
  %243 = mul i64 %242, 170
  %244 = xor i64 %1, -8366135493362343137
  %245 = and i64 %1, %244
  %246 = or i64 %1, %244
  %247 = xor i64 %1, %244
  %248 = mul i64 %246, 2
  %249 = sub i64 %248, %247
  %250 = sub i64 %249, %1
  %251 = sub i64 %250, %244
  %252 = mul i64 %251, 78
  %253 = icmp eq i64 %243, %252
  br i1 %253, label %2944, label %3140

254:                                              ; preds = %32
  %255 = load i32, ptr %10, align 4
  %256 = icmp eq i32 %255, 0
  %257 = zext i1 %256 to i64
  %258 = select i1 %256, i32 0, i32 -1
  store i32 %258, ptr %7, align 4
  store i32 1940021752, ptr %5, align 4
  %259 = xor i64 %1, -6194723999856962231
  %260 = and i64 %1, %259
  %261 = or i64 %1, %259
  %262 = xor i64 %1, %259
  %263 = add i64 %260, %261
  %264 = sub i64 %263, %1
  %265 = sub i64 %264, %259
  %266 = mul i64 %265, 121
  %267 = icmp eq i64 %266, 0
  br i1 %267, label %2944, label %3148

268:                                              ; preds = %32
  %269 = load i64, ptr %9, align 8
  %270 = icmp ugt i64 %269, 512
  %271 = select i1 %270, i32 -7754029, i32 -124167429
  store i32 %271, ptr %5, align 4
  %272 = xor i64 %1, -4984115061999871
  %273 = and i64 %1, %272
  %274 = or i64 %1, %272
  %275 = xor i64 %1, %272
  %276 = sub i64 %274, %275
  %277 = sub i64 %276, %273
  %278 = mul i64 %277, 10
  %279 = xor i64 %1, -6552375132267106329
  %280 = and i64 %1, %279
  %281 = or i64 %1, %279
  %282 = xor i64 %1, %279
  %283 = add i64 %1, %279
  %284 = sub i64 %283, %282
  %285 = mul i64 %280, 2
  %286 = sub i64 %284, %285
  %287 = mul i64 %286, 149
  %288 = icmp eq i64 %278, %287
  br i1 %288, label %2944, label %3158

289:                                              ; preds = %32
  store i64 512, ptr %9, align 8
  %290 = load i32, ptr %16, align 4
  %291 = load i32, ptr %5, align 4
  %292 = xor i32 %291, -7754030
  %293 = sub i32 %290, %292
  %294 = load i32, ptr %5, align 4
  %295 = xor i32 %294, -7754065
  %296 = mul i32 %290, %295
  %297 = load i32, ptr %5, align 4
  %298 = xor i32 %297, -7754072
  %299 = mul i32 %298, %293
  %300 = sub i32 %296, %299
  store i32 %300, ptr %16, align 4
  store i32 -124167429, ptr %5, align 4
  %301 = xor i64 %1, 1753542630816610043
  %302 = and i64 %1, %301
  %303 = or i64 %1, %301
  %304 = xor i64 %1, %301
  %305 = add i64 %1, %301
  %306 = sub i64 %305, %304
  %307 = mul i64 %302, 2
  %308 = sub i64 %306, %307
  %309 = mul i64 %308, 126
  %310 = icmp slt i64 %309, 0
  br i1 %310, label %3168, label %2944

311:                                              ; preds = %32
  store i64 0, ptr %21, align 8
  store i32 -1779405741, ptr %5, align 4
  %312 = xor i64 %1, -4355146105593895965
  %313 = and i64 %1, %312
  %314 = or i64 %1, %312
  %315 = xor i64 %1, %312
  %316 = mul i64 %314, 2
  %317 = sub i64 %316, %315
  %318 = sub i64 %317, %1
  %319 = sub i64 %318, %312
  %320 = mul i64 %319, 100
  %321 = icmp sle i64 %320, 0
  br i1 %321, label %2944, label %3175

322:                                              ; preds = %32
  %323 = load i64, ptr %21, align 8
  %324 = load i64, ptr %9, align 8
  %325 = icmp ult i64 %323, %324
  %326 = select i1 %325, i32 608585856, i32 -1728507056
  store i32 %326, ptr %5, align 4
  %327 = xor i64 %1, 770875187028386203
  %328 = and i64 %1, %327
  %329 = or i64 %1, %327
  %330 = xor i64 %1, %327
  %331 = mul i64 %329, 2
  %332 = sub i64 %331, %330
  %333 = sub i64 %332, %1
  %334 = sub i64 %333, %327
  %335 = mul i64 %334, 225
  %336 = icmp slt i64 %335, 0
  br i1 %336, label %3184, label %2944

337:                                              ; preds = %32
  %338 = load ptr, ptr %8, align 8
  %339 = load i64, ptr %21, align 8
  %340 = getelementptr inbounds nuw i8, ptr %338, i64 %339
  %341 = load i8, ptr %340, align 1
  store i8 %341, ptr %22, align 1
  %342 = load i8, ptr %22, align 1
  %343 = zext i8 %342 to i32
  %344 = load i32, ptr %15, align 4
  %345 = xor i32 %344, %343
  %346 = and i32 %344, %343
  %347 = add i32 %346, %346
  %348 = add i32 %345, %347
  store i32 %348, ptr %15, align 4
  %349 = load i32, ptr %15, align 4
  %350 = load i32, ptr %14, align 4
  %351 = or i32 %349, %350
  %352 = and i32 %349, %350
  %353 = sub i32 %351, %352
  %354 = load i8, ptr %22, align 1
  %355 = zext i8 %354 to i32
  %356 = load i32, ptr %5, align 4
  %357 = xor i32 %356, 608585863
  %358 = add i32 %355, %357
  %359 = load i32, ptr %5, align 4
  %360 = xor i32 %359, 608585863
  %361 = or i32 %355, %360
  %362 = sub i32 %358, %361
  %363 = load i32, ptr %5, align 4
  %364 = xor i32 %363, 608585887
  %365 = add i32 %362, %364
  %366 = load i32, ptr %5, align 4
  %367 = xor i32 %366, 608585887
  %368 = or i32 %362, %367
  %369 = sub i32 %365, %368
  %370 = load i32, ptr %5, align 4
  %371 = xor i32 %370, 608585857
  %372 = shl i32 %371, %369
  %373 = mul i32 %353, %372
  %374 = load i32, ptr %15, align 4
  %375 = load i32, ptr %14, align 4
  %376 = or i32 %374, %375
  %377 = and i32 %374, %375
  %378 = sub i32 %376, %377
  %379 = load i8, ptr %22, align 1
  %380 = zext i8 %379 to i32
  %381 = load i32, ptr %5, align 4
  %382 = xor i32 %381, 608585863
  %383 = add i32 %380, %382
  %384 = load i32, ptr %5, align 4
  %385 = xor i32 %384, 608585863
  %386 = or i32 %380, %385
  %387 = load i32, ptr %5, align 4
  %388 = xor i32 %387, -1497053699
  %389 = mul i32 %383, %388
  %390 = load i32, ptr %5, align 4
  %391 = xor i32 %390, -1497053699
  %392 = mul i32 %386, %391
  %393 = sub i32 %389, %392
  %394 = load i32, ptr %5, align 4
  %395 = xor i32 %394, -1122661017
  %396 = mul i32 %393, %395
  %397 = load i32, ptr %5, align 4
  %398 = xor i32 %397, -1471225757
  %399 = mul i32 %396, %398
  %400 = load i32, ptr %5, align 4
  %401 = xor i32 %400, 608585887
  %402 = add i32 %399, %401
  %403 = load i32, ptr %5, align 4
  %404 = xor i32 %403, 608585887
  %405 = or i32 %399, %404
  %406 = load i32, ptr %5, align 4
  %407 = xor i32 %406, 405173177
  %408 = mul i32 %402, %407
  %409 = load i32, ptr %5, align 4
  %410 = xor i32 %409, 405173177
  %411 = mul i32 %405, %410
  %412 = sub i32 %408, %411
  %413 = load i32, ptr %5, align 4
  %414 = xor i32 %413, 28796427
  %415 = mul i32 %412, %414
  %416 = load i32, ptr %5, align 4
  %417 = xor i32 %416, 768471995
  %418 = mul i32 %415, %417
  %419 = load i32, ptr %5, align 4
  %420 = xor i32 %419, 608585857
  %421 = add i32 %418, %420
  %422 = load i32, ptr %5, align 4
  %423 = xor i32 %422, 608585888
  %424 = mul i32 %423, %421
  %425 = load i32, ptr %5, align 4
  %426 = xor i32 %425, 608585889
  %427 = mul i32 %418, %426
  %428 = sub i32 %424, %427
  %429 = lshr i32 %378, %428
  %430 = xor i32 %373, %429
  %431 = and i32 %373, %429
  %432 = add i32 %430, %431
  store i32 %432, ptr %15, align 4
  %433 = load i8, ptr %22, align 1
  %434 = zext i8 %433 to i32
  %435 = load i64, ptr %21, align 8
  %436 = urem i64 %435, 4
  %437 = mul i64 %436, 8
  %438 = trunc i64 %437 to i32
  %439 = load i32, ptr %5, align 4
  %440 = xor i32 %439, 608585857
  %441 = shl i32 %440, %438
  %442 = mul i32 %434, %441
  %443 = load i32, ptr %14, align 4
  %444 = add i32 %443, %442
  %445 = and i32 %443, %442
  %446 = add i32 %445, %445
  %447 = sub i32 %444, %446
  store i32 %447, ptr %14, align 4
  %448 = load i64, ptr %21, align 8
  %449 = load i8, ptr %22, align 1
  %450 = zext i8 %449 to i32
  %451 = load i32, ptr %14, align 4
  %452 = load i32, ptr %15, align 4
  %453 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i64 noundef %448, i32 noundef %450, i32 noundef %451, i32 noundef %452)
  %454 = load i8, ptr %22, align 1
  %455 = zext i8 %454 to i32
  %456 = icmp eq i32 %455, 0
  %457 = select i1 %456, i32 309316791, i32 -313336483
  store i32 %457, ptr %5, align 4
  %458 = xor i64 %1, -3285618164151471865
  %459 = and i64 %1, %458
  %460 = or i64 %1, %458
  %461 = xor i64 %1, %458
  %462 = add i64 %1, %458
  %463 = sub i64 %462, %461
  %464 = mul i64 %459, 2
  %465 = sub i64 %463, %464
  %466 = mul i64 %465, 33
  %467 = icmp sle i64 %466, 0
  br i1 %467, label %2944, label %3191

468:                                              ; preds = %32
  %469 = load i32, ptr %17, align 4
  %470 = load i32, ptr %5, align 4
  %471 = xor i32 %470, 309316775
  %472 = add i32 %469, %471
  %473 = load i32, ptr %5, align 4
  %474 = xor i32 %473, 309316775
  %475 = and i32 %469, %474
  %476 = add i32 %475, %475
  %477 = sub i32 %472, %476
  store i32 %477, ptr %17, align 4
  %478 = load i32, ptr %16, align 4
  %479 = load i32, ptr %5, align 4
  %480 = xor i32 %479, 309316790
  %481 = add i32 %478, %480
  %482 = load i32, ptr %5, align 4
  %483 = xor i32 %482, 309316787
  %484 = mul i32 %478, %483
  %485 = load i32, ptr %5, align 4
  %486 = xor i32 %485, 309316788
  %487 = mul i32 %486, %481
  %488 = sub i32 %484, %487
  store i32 %488, ptr %16, align 4
  store i32 -398310207, ptr %5, align 4
  %489 = xor i64 %1, -2764181638741676581
  %490 = and i64 %1, %489
  %491 = or i64 %1, %489
  %492 = xor i64 %1, %489
  %493 = add i64 %1, %489
  %494 = sub i64 %493, %492
  %495 = mul i64 %490, 2
  %496 = sub i64 %494, %495
  %497 = mul i64 %496, 184
  %498 = icmp ne i64 %497, 0
  br i1 %498, label %3199, label %2944

499:                                              ; preds = %32
  %500 = call ptr @__ctype_b_loc() #8
  %501 = load ptr, ptr %500, align 8
  %502 = load i8, ptr %22, align 1
  %503 = zext i8 %502 to i32
  %504 = sext i32 %503 to i64
  %505 = getelementptr inbounds i16, ptr %501, i64 %504
  %506 = load i16, ptr %505, align 2
  %507 = zext i16 %506 to i32
  %508 = load i32, ptr %5, align 4
  %509 = xor i32 %508, -313338531
  %510 = add i32 %507, %509
  %511 = load i32, ptr %5, align 4
  %512 = xor i32 %511, -313338531
  %513 = or i32 %507, %512
  %514 = sub i32 %510, %513
  %515 = icmp ne i32 %514, 0
  %516 = select i1 %515, i32 151611781, i32 1953311657
  store i32 %516, ptr %5, align 4
  %517 = xor i64 %1, 7951193717297983087
  %518 = and i64 %1, %517
  %519 = or i64 %1, %517
  %520 = xor i64 %1, %517
  %521 = mul i64 %519, 2
  %522 = sub i64 %521, %520
  %523 = sub i64 %522, %1
  %524 = sub i64 %523, %517
  %525 = mul i64 %524, 24
  %526 = icmp ne i64 %525, 0
  br i1 %526, label %3208, label %2944

527:                                              ; preds = %32
  %528 = load i8, ptr %22, align 1
  %529 = zext i8 %528 to i32
  %530 = load i32, ptr %5, align 4
  %531 = xor i32 %530, -151611830
  %532 = add i32 %529, %531
  %533 = load i32, ptr %5, align 4
  %534 = xor i32 %533, 151611780
  %535 = add i32 %532, %534
  %536 = load i32, ptr %17, align 4
  %537 = xor i32 %536, %535
  %538 = and i32 %536, %535
  %539 = add i32 %538, %538
  %540 = add i32 %537, %539
  store i32 %540, ptr %17, align 4
  %541 = load i8, ptr %22, align 1
  %542 = zext i8 %541 to i32
  %543 = load i32, ptr %5, align 4
  %544 = xor i32 %543, 151611829
  %545 = xor i32 %542, %544
  %546 = load i32, ptr %5, align 4
  %547 = xor i32 %546, -151611782
  %548 = xor i32 %542, %547
  %549 = load i32, ptr %5, align 4
  %550 = xor i32 %549, 151611829
  %551 = and i32 %548, %550
  %552 = add i32 %551, %551
  %553 = sub i32 %545, %552
  %554 = load i32, ptr %5, align 4
  %555 = xor i32 %554, 151611783
  %556 = mul nsw i32 %553, %555
  %557 = load i32, ptr %16, align 4
  %558 = xor i32 %557, %556
  %559 = and i32 %557, %556
  %560 = add i32 %559, %559
  %561 = add i32 %558, %560
  store i32 %561, ptr %16, align 4
  store i32 -1609619593, ptr %5, align 4
  %562 = xor i64 %1, 7591314101457133687
  %563 = and i64 %1, %562
  %564 = or i64 %1, %562
  %565 = xor i64 %1, %562
  %566 = sub i64 %564, %565
  %567 = sub i64 %566, %563
  %568 = mul i64 %567, 33
  %569 = icmp slt i64 %568, 1
  br i1 %569, label %2944, label %3217

570:                                              ; preds = %32
  %571 = call ptr @__ctype_b_loc() #8
  %572 = load ptr, ptr %571, align 8
  %573 = load i8, ptr %22, align 1
  %574 = zext i8 %573 to i32
  %575 = sext i32 %574 to i64
  %576 = getelementptr inbounds i16, ptr %572, i64 %575
  %577 = load i16, ptr %576, align 2
  %578 = zext i16 %577 to i32
  %579 = load i32, ptr %5, align 4
  %580 = xor i32 %579, 1953312681
  %581 = add i32 %578, %580
  %582 = load i32, ptr %5, align 4
  %583 = xor i32 %582, 1953312681
  %584 = or i32 %578, %583
  %585 = sub i32 %581, %584
  %586 = icmp ne i32 %585, 0
  %587 = select i1 %586, i32 818225780, i32 -1684054663
  store i32 %587, ptr %5, align 4
  %588 = xor i64 %1, 7811660842928968497
  %589 = and i64 %1, %588
  %590 = or i64 %1, %588
  %591 = xor i64 %1, %588
  %592 = add i64 %589, %590
  %593 = sub i64 %592, %1
  %594 = sub i64 %593, %588
  %595 = mul i64 %594, 126
  %596 = icmp eq i64 %595, 0
  br i1 %596, label %2944, label %3224

597:                                              ; preds = %32
  %598 = call ptr @__ctype_b_loc() #8
  %599 = load ptr, ptr %598, align 8
  %600 = load i8, ptr %22, align 1
  %601 = zext i8 %600 to i32
  %602 = sext i32 %601 to i64
  %603 = getelementptr inbounds i16, ptr %599, i64 %602
  %604 = load i16, ptr %603, align 2
  %605 = zext i16 %604 to i32
  %606 = load i32, ptr %5, align 4
  %607 = xor i32 %606, 818226036
  %608 = add i32 %605, %607
  %609 = load i32, ptr %5, align 4
  %610 = xor i32 %609, 818226036
  %611 = or i32 %605, %610
  %612 = load i32, ptr %5, align 4
  %613 = xor i32 %612, -366725861
  %614 = mul i32 %608, %613
  %615 = load i32, ptr %5, align 4
  %616 = xor i32 %615, -366725861
  %617 = mul i32 %611, %616
  %618 = sub i32 %614, %617
  %619 = load i32, ptr %5, align 4
  %620 = xor i32 %619, -1908676453
  %621 = mul i32 %618, %620
  %622 = load i32, ptr %5, align 4
  %623 = xor i32 %622, 16371477
  %624 = mul i32 %621, %623
  %625 = icmp ne i32 %624, 0
  %626 = select i1 %625, i32 -726616905, i32 76211000
  store i32 %626, ptr %5, align 4
  %627 = xor i64 %1, -4817191339171413301
  %628 = and i64 %1, %627
  %629 = or i64 %1, %627
  %630 = xor i64 %1, %627
  %631 = mul i64 %629, 2
  %632 = sub i64 %631, %630
  %633 = sub i64 %632, %1
  %634 = sub i64 %633, %627
  %635 = mul i64 %634, 9
  %636 = icmp ne i64 %635, 0
  br i1 %636, label %3231, label %2944

637:                                              ; preds = %32
  %638 = load i8, ptr %22, align 1
  %639 = zext i8 %638 to i32
  %640 = load i32, ptr %16, align 4
  %641 = load i32, ptr %5, align 4
  %642 = xor i32 %641, -726616906
  %643 = add i32 %639, %642
  %644 = load i32, ptr %5, align 4
  %645 = xor i32 %644, -726616906
  %646 = sub i32 %640, %645
  %647 = mul i32 %640, %643
  %648 = mul i32 %639, %646
  %649 = sub i32 %647, %648
  store i32 %649, ptr %16, align 4
  %650 = load i32, ptr %17, align 4
  %651 = load i32, ptr %5, align 4
  %652 = xor i32 %651, -726616937
  %653 = add i32 %650, %652
  %654 = load i32, ptr %5, align 4
  %655 = xor i32 %654, -726616937
  %656 = and i32 %650, %655
  %657 = load i32, ptr %5, align 4
  %658 = xor i32 %657, -243267942
  %659 = mul i32 %653, %658
  %660 = load i32, ptr %5, align 4
  %661 = xor i32 %660, -243267942
  %662 = mul i32 %656, %661
  %663 = add i32 %662, %662
  %664 = sub i32 %659, %663
  %665 = load i32, ptr %5, align 4
  %666 = xor i32 %665, -1948100732
  %667 = mul i32 %664, %666
  %668 = load i32, ptr %5, align 4
  %669 = xor i32 %668, 1720082288
  %670 = mul i32 %667, %669
  store i32 %670, ptr %17, align 4
  store i32 1066814214, ptr %5, align 4
  %671 = xor i64 %1, 1952170689400031097
  %672 = and i64 %1, %671
  %673 = or i64 %1, %671
  %674 = xor i64 %1, %671
  %675 = mul i64 %673, 2
  %676 = sub i64 %675, %674
  %677 = sub i64 %676, %1
  %678 = sub i64 %677, %671
  %679 = mul i64 %678, 4
  %680 = icmp slt i64 %679, 1
  br i1 %680, label %2944, label %3241

681:                                              ; preds = %32
  %682 = load i8, ptr %22, align 1
  %683 = zext i8 %682 to i32
  %684 = load i32, ptr %16, align 4
  %685 = load i32, ptr %5, align 4
  %686 = xor i32 %685, 76211001
  %687 = add i32 %683, %686
  %688 = load i32, ptr %5, align 4
  %689 = xor i32 %688, 76211001
  %690 = add i32 %684, %689
  %691 = mul i32 %684, %687
  %692 = mul i32 %683, %690
  %693 = sub i32 %691, %692
  store i32 %693, ptr %16, align 4
  %694 = load i32, ptr %17, align 4
  %695 = load i32, ptr %5, align 4
  %696 = xor i32 %695, 76211064
  %697 = add i32 %694, %696
  %698 = load i32, ptr %5, align 4
  %699 = xor i32 %698, 76211064
  %700 = and i32 %694, %699
  %701 = add i32 %700, %700
  %702 = sub i32 %697, %701
  store i32 %702, ptr %17, align 4
  store i32 1066814214, ptr %5, align 4
  %703 = xor i64 %1, 2454557643648250411
  %704 = and i64 %1, %703
  %705 = or i64 %1, %703
  %706 = xor i64 %1, %703
  %707 = add i64 %704, %705
  %708 = sub i64 %707, %1
  %709 = sub i64 %708, %703
  %710 = mul i64 %709, 128
  %711 = xor i64 %1, -5417734499411344903
  %712 = and i64 %1, %711
  %713 = or i64 %1, %711
  %714 = xor i64 %1, %711
  %715 = mul i64 %713, 2
  %716 = sub i64 %715, %714
  %717 = sub i64 %716, %1
  %718 = sub i64 %717, %711
  %719 = mul i64 %718, 141
  %720 = icmp eq i64 %710, %719
  br i1 %720, label %2944, label %3248

721:                                              ; preds = %32
  store i32 159030869, ptr %5, align 4
  %722 = xor i64 %1, -3229340946586422471
  %723 = and i64 %1, %722
  %724 = or i64 %1, %722
  %725 = xor i64 %1, %722
  %726 = add i64 %723, %724
  %727 = sub i64 %726, %1
  %728 = sub i64 %727, %722
  %729 = mul i64 %728, 208
  %730 = icmp sle i64 %729, 0
  br i1 %730, label %2944, label %3256

731:                                              ; preds = %32
  %732 = load i8, ptr %22, align 1
  %733 = zext i8 %732 to i32
  %734 = icmp eq i32 %733, 255
  %735 = select i1 %734, i32 1329751653, i32 -1320332541
  store i32 %735, ptr %5, align 4
  %736 = xor i64 %1, -3507981949916505685
  %737 = and i64 %1, %736
  %738 = or i64 %1, %736
  %739 = xor i64 %1, %736
  %740 = add i64 %1, %736
  %741 = sub i64 %740, %739
  %742 = mul i64 %737, 2
  %743 = sub i64 %741, %742
  %744 = mul i64 %743, 58
  %745 = icmp sgt i64 %744, 0
  br i1 %745, label %3265, label %2944

746:                                              ; preds = %32
  store i32 1, ptr %18, align 4
  %747 = load i32, ptr %16, align 4
  %748 = load i32, ptr %5, align 4
  %749 = xor i32 %748, -1329751654
  %750 = or i32 %747, %749
  %751 = load i32, ptr %5, align 4
  %752 = xor i32 %751, -1329751654
  %753 = and i32 %747, %752
  %754 = sub i32 %750, %753
  store i32 %754, ptr %16, align 4
  store i32 2128915586, ptr %5, align 4
  %755 = xor i64 %1, -8618198537558330079
  %756 = and i64 %1, %755
  %757 = or i64 %1, %755
  %758 = xor i64 %1, %755
  %759 = mul i64 %757, 2
  %760 = sub i64 %759, %758
  %761 = sub i64 %760, %1
  %762 = sub i64 %761, %755
  %763 = mul i64 %762, 53
  %764 = xor i64 %1, 6122470292676570855
  %765 = and i64 %1, %764
  %766 = or i64 %1, %764
  %767 = xor i64 %1, %764
  %768 = add i64 %1, %764
  %769 = sub i64 %768, %767
  %770 = mul i64 %765, 2
  %771 = sub i64 %769, %770
  %772 = mul i64 %771, 171
  %773 = icmp ne i64 %763, %772
  br i1 %773, label %3274, label %2944

774:                                              ; preds = %32
  %775 = load i8, ptr %22, align 1
  %776 = zext i8 %775 to i32
  %777 = load i32, ptr %5, align 4
  %778 = xor i32 %777, -1320332455
  %779 = add i32 %776, %778
  %780 = load i32, ptr %5, align 4
  %781 = xor i32 %780, -1320332455
  %782 = and i32 %776, %781
  %783 = load i32, ptr %5, align 4
  %784 = xor i32 %783, -1628545584
  %785 = mul i32 %779, %784
  %786 = load i32, ptr %5, align 4
  %787 = xor i32 %786, -1628545584
  %788 = mul i32 %782, %787
  %789 = add i32 %788, %788
  %790 = sub i32 %785, %789
  %791 = load i32, ptr %5, align 4
  %792 = xor i32 %791, -1490190404
  %793 = mul i32 %790, %792
  %794 = load i32, ptr %5, align 4
  %795 = xor i32 %794, 1770978662
  %796 = mul i32 %793, %795
  %797 = load i32, ptr %5, align 4
  %798 = xor i32 %797, -1320332420
  %799 = add i32 %796, %798
  %800 = load i32, ptr %5, align 4
  %801 = xor i32 %800, -1320332420
  %802 = or i32 %796, %801
  %803 = sub i32 %799, %802
  %804 = load i32, ptr %16, align 4
  %805 = load i32, ptr %5, align 4
  %806 = xor i32 %805, -1320332542
  %807 = add i32 %803, %806
  %808 = load i32, ptr %5, align 4
  %809 = xor i32 %808, -1320332542
  %810 = sub i32 %804, %809
  %811 = mul i32 %804, %807
  %812 = mul i32 %803, %810
  %813 = sub i32 %811, %812
  store i32 %813, ptr %16, align 4
  store i32 2128915586, ptr %5, align 4
  %814 = xor i64 %1, -8434129631380743217
  %815 = and i64 %1, %814
  %816 = or i64 %1, %814
  %817 = xor i64 %1, %814
  %818 = add i64 %1, %814
  %819 = sub i64 %818, %817
  %820 = mul i64 %815, 2
  %821 = sub i64 %819, %820
  %822 = mul i64 %821, 219
  %823 = icmp slt i64 %822, 0
  br i1 %823, label %3281, label %2944

824:                                              ; preds = %32
  store i32 159030869, ptr %5, align 4
  %825 = xor i64 %1, -2787931877459435007
  %826 = and i64 %1, %825
  %827 = or i64 %1, %825
  %828 = xor i64 %1, %825
  %829 = add i64 %1, %825
  %830 = sub i64 %829, %828
  %831 = mul i64 %826, 2
  %832 = sub i64 %830, %831
  %833 = mul i64 %832, 12
  %834 = icmp sgt i64 %833, 0
  br i1 %834, label %3289, label %2944

835:                                              ; preds = %32
  store i32 -1609619593, ptr %5, align 4
  %836 = xor i64 %1, -6916405833951782581
  %837 = and i64 %1, %836
  %838 = or i64 %1, %836
  %839 = xor i64 %1, %836
  %840 = mul i64 %838, 2
  %841 = sub i64 %840, %839
  %842 = sub i64 %841, %1
  %843 = sub i64 %842, %836
  %844 = mul i64 %843, 122
  %845 = icmp sle i64 %844, 0
  br i1 %845, label %2944, label %3298

846:                                              ; preds = %32
  store i32 -398310207, ptr %5, align 4
  %847 = xor i64 %1, 5075371898316078895
  %848 = and i64 %1, %847
  %849 = or i64 %1, %847
  %850 = xor i64 %1, %847
  %851 = sub i64 %849, %850
  %852 = sub i64 %851, %848
  %853 = mul i64 %852, 112
  %854 = icmp eq i64 %853, 0
  br i1 %854, label %2944, label %3307

855:                                              ; preds = %32
  %856 = load i8, ptr %22, align 1
  %857 = zext i8 %856 to i32
  %858 = load i32, ptr %10, align 4
  %859 = or i32 %857, %858
  %860 = and i32 %857, %858
  %861 = add i32 %859, %860
  %862 = sext i32 %861 to i64
  %863 = load i64, ptr %21, align 8
  %864 = or i64 %862, %863
  %865 = and i64 %862, %863
  %866 = add i64 %864, %865
  %867 = add i64 %866, 15
  %868 = or i64 %866, 15
  %869 = mul i64 %867, 1138545903
  %870 = mul i64 %868, 1138545903
  %871 = sub i64 %869, %870
  %872 = mul i64 %871, -7224721934938482161
  %873 = icmp eq i64 %872, 0
  %874 = select i1 %873, i32 -1132791240, i32 1089690255
  %875 = icmp eq i64 %872, 1
  %876 = select i1 %875, i32 644808127, i32 %874
  %877 = icmp eq i64 %872, 2
  %878 = select i1 %877, i32 1957078077, i32 %876
  %879 = icmp eq i64 %872, 3
  %880 = select i1 %879, i32 -1263050245, i32 %878
  %881 = icmp eq i64 %872, 4
  %882 = select i1 %881, i32 -1628139079, i32 %880
  %883 = icmp eq i64 %872, 5
  %884 = select i1 %883, i32 -1106605089, i32 %882
  %885 = icmp eq i64 %872, 6
  %886 = select i1 %885, i32 -877186256, i32 %884
  %887 = icmp eq i64 %872, 7
  %888 = select i1 %887, i32 1250024491, i32 %886
  %889 = icmp eq i64 %872, 8
  %890 = select i1 %889, i32 -1068402956, i32 %888
  %891 = icmp eq i64 %872, 9
  %892 = select i1 %891, i32 -1921156151, i32 %890
  %893 = icmp eq i64 %872, 10
  %894 = select i1 %893, i32 -403924464, i32 %892
  %895 = icmp eq i64 %872, 11
  %896 = select i1 %895, i32 747232309, i32 %894
  %897 = icmp eq i64 %872, 12
  %898 = select i1 %897, i32 -1951296407, i32 %896
  %899 = icmp eq i64 %872, 13
  %900 = select i1 %899, i32 1040377810, i32 %898
  %901 = icmp eq i64 %872, 14
  %902 = select i1 %901, i32 -1714534690, i32 %900
  %903 = icmp eq i64 %872, 15
  %904 = select i1 %903, i32 -583587386, i32 %902
  store i32 %904, ptr %5, align 4
  %905 = xor i64 %1, -8265653290423193615
  %906 = and i64 %1, %905
  %907 = or i64 %1, %905
  %908 = xor i64 %1, %905
  %909 = add i64 %906, %907
  %910 = sub i64 %909, %1
  %911 = sub i64 %910, %905
  %912 = mul i64 %911, 79
  %913 = icmp sle i64 %912, 0
  br i1 %913, label %2944, label %3317

914:                                              ; preds = %32
  %915 = load i64, ptr %21, align 8
  %916 = add i64 %915, 7
  %917 = or i64 %915, 7
  %918 = sub i64 %916, %917
  %919 = getelementptr inbounds nuw [8 x %struct.Node], ptr %12, i64 0, i64 %918
  %920 = getelementptr inbounds nuw %struct.Node, ptr %919, i32 0, i32 0
  %921 = load i32, ptr %920, align 16
  %922 = load i32, ptr %14, align 4
  %923 = xor i32 %922, %921
  %924 = and i32 %922, %921
  %925 = add i32 %924, %924
  %926 = add i32 %923, %925
  store i32 %926, ptr %14, align 4
  store i32 2086537121, ptr %5, align 4
  %927 = xor i64 %1, 1539504460311337667
  %928 = and i64 %1, %927
  %929 = or i64 %1, %927
  %930 = xor i64 %1, %927
  %931 = sub i64 %929, %930
  %932 = sub i64 %931, %928
  %933 = mul i64 %932, 100
  %934 = icmp uge i64 %933, 0
  br i1 %934, label %2944, label %3324

935:                                              ; preds = %32
  %936 = load i64, ptr %21, align 8
  %937 = add i64 %936, 7
  %938 = or i64 %936, 7
  %939 = sub i64 %937, %938
  %940 = getelementptr inbounds nuw [8 x %struct.Node], ptr %12, i64 0, i64 %939
  %941 = getelementptr inbounds nuw %struct.Node, ptr %940, i32 0, i32 1
  %942 = load i32, ptr %941, align 4
  %943 = load i32, ptr %14, align 4
  %944 = add i32 %943, %942
  %945 = and i32 %943, %942
  %946 = add i32 %945, %945
  %947 = sub i32 %944, %946
  store i32 %947, ptr %14, align 4
  store i32 2086537121, ptr %5, align 4
  %948 = xor i64 %1, -5943475715131151749
  %949 = and i64 %1, %948
  %950 = or i64 %1, %948
  %951 = xor i64 %1, %948
  %952 = add i64 %949, %950
  %953 = sub i64 %952, %1
  %954 = sub i64 %953, %948
  %955 = mul i64 %954, 197
  %956 = icmp uge i64 %955, 0
  br i1 %956, label %2944, label %3331

957:                                              ; preds = %32
  %958 = load i64, ptr %21, align 8
  %959 = add i64 %958, 7
  %960 = or i64 %958, 7
  %961 = mul i64 %959, 2200306165
  %962 = mul i64 %960, 2200306165
  %963 = sub i64 %961, %962
  %964 = mul i64 %963, 425846915
  %965 = mul i64 %964, -4545705109728353
  %966 = getelementptr inbounds nuw [8 x %struct.Node], ptr %12, i64 0, i64 %965
  %967 = getelementptr inbounds nuw %struct.Node, ptr %966, i32 0, i32 2
  %968 = load i32, ptr %967, align 8
  %969 = load i32, ptr %16, align 4
  %970 = xor i32 %969, %968
  %971 = and i32 %969, %968
  %972 = add i32 %971, %971
  %973 = add i32 %970, %972
  store i32 %973, ptr %16, align 4
  store i32 2086537121, ptr %5, align 4
  %974 = xor i64 %1, 5033289277771547991
  %975 = and i64 %1, %974
  %976 = or i64 %1, %974
  %977 = xor i64 %1, %974
  %978 = add i64 %975, %976
  %979 = sub i64 %978, %1
  %980 = sub i64 %979, %974
  %981 = mul i64 %980, 60
  %982 = xor i64 %1, 6911517660942444281
  %983 = and i64 %1, %982
  %984 = or i64 %1, %982
  %985 = xor i64 %1, %982
  %986 = mul i64 %984, 2
  %987 = sub i64 %986, %985
  %988 = sub i64 %987, %1
  %989 = sub i64 %988, %982
  %990 = mul i64 %989, 123
  %991 = icmp ne i64 %981, %990
  br i1 %991, label %3340, label %2944

992:                                              ; preds = %32
  %993 = load i64, ptr %21, align 8
  %994 = add i64 %993, 7
  %995 = or i64 %993, 7
  %996 = mul i64 %994, 2113765401
  %997 = mul i64 %995, 2113765401
  %998 = sub i64 %996, %997
  %999 = mul i64 %998, -2373065211478680535
  %1000 = getelementptr inbounds nuw [8 x %struct.Node], ptr %12, i64 0, i64 %999
  %1001 = getelementptr inbounds nuw %struct.Node, ptr %1000, i32 0, i32 3
  %1002 = load i8, ptr %1001, align 4
  %1003 = zext i8 %1002 to i32
  %1004 = load i32, ptr %16, align 4
  %1005 = xor i32 %1004, %1003
  %1006 = load i32, ptr %5, align 4
  %1007 = xor i32 %1006, 1263050244
  %1008 = xor i32 %1004, %1007
  %1009 = and i32 %1008, %1003
  %1010 = add i32 %1009, %1009
  %1011 = sub i32 %1005, %1010
  store i32 %1011, ptr %16, align 4
  store i32 2086537121, ptr %5, align 4
  %1012 = xor i64 %1, 2583871712448309311
  %1013 = and i64 %1, %1012
  %1014 = or i64 %1, %1012
  %1015 = xor i64 %1, %1012
  %1016 = mul i64 %1014, 2
  %1017 = sub i64 %1016, %1015
  %1018 = sub i64 %1017, %1
  %1019 = sub i64 %1018, %1012
  %1020 = mul i64 %1019, 168
  %1021 = icmp slt i64 %1020, 0
  br i1 %1021, label %3348, label %2944

1022:                                             ; preds = %32
  %1023 = load i32, ptr %14, align 4
  %1024 = load i8, ptr %22, align 1
  %1025 = zext i8 %1024 to i32
  %1026 = load i32, ptr %5, align 4
  %1027 = xor i32 %1026, -1628139098
  %1028 = add i32 %1025, %1027
  %1029 = load i32, ptr %5, align 4
  %1030 = xor i32 %1029, -1628139098
  %1031 = or i32 %1025, %1030
  %1032 = load i32, ptr %5, align 4
  %1033 = xor i32 %1032, 1888203832
  %1034 = mul i32 %1028, %1033
  %1035 = load i32, ptr %5, align 4
  %1036 = xor i32 %1035, 1888203832
  %1037 = mul i32 %1031, %1036
  %1038 = sub i32 %1034, %1037
  %1039 = load i32, ptr %5, align 4
  %1040 = xor i32 %1039, 140720256
  %1041 = mul i32 %1038, %1040
  %1042 = load i32, ptr %5, align 4
  %1043 = xor i32 %1042, 1885106736
  %1044 = mul i32 %1041, %1043
  %1045 = load i32, ptr %5, align 4
  %1046 = xor i32 %1045, -1628139098
  %1047 = add i32 %1044, %1046
  %1048 = load i32, ptr %5, align 4
  %1049 = xor i32 %1048, -1628139098
  %1050 = or i32 %1044, %1049
  %1051 = load i32, ptr %5, align 4
  %1052 = xor i32 %1051, 2137147424
  %1053 = mul i32 %1047, %1052
  %1054 = load i32, ptr %5, align 4
  %1055 = xor i32 %1054, 2137147424
  %1056 = mul i32 %1050, %1055
  %1057 = sub i32 %1053, %1056
  %1058 = load i32, ptr %5, align 4
  %1059 = xor i32 %1058, -1806273924
  %1060 = mul i32 %1057, %1059
  %1061 = load i32, ptr %5, align 4
  %1062 = xor i32 %1061, 1965855788
  %1063 = mul i32 %1060, %1062
  %1064 = load i32, ptr %5, align 4
  %1065 = xor i32 %1064, -1628139080
  %1066 = shl i32 %1065, %1063
  %1067 = mul i32 %1023, %1066
  %1068 = load i32, ptr %14, align 4
  %1069 = load i8, ptr %22, align 1
  %1070 = zext i8 %1069 to i32
  %1071 = load i32, ptr %5, align 4
  %1072 = xor i32 %1071, -1628139098
  %1073 = add i32 %1070, %1072
  %1074 = load i32, ptr %5, align 4
  %1075 = xor i32 %1074, -1628139098
  %1076 = or i32 %1070, %1075
  %1077 = sub i32 %1073, %1076
  %1078 = load i32, ptr %5, align 4
  %1079 = xor i32 %1078, -1628139098
  %1080 = add i32 %1077, %1079
  %1081 = load i32, ptr %5, align 4
  %1082 = xor i32 %1081, -1628139098
  %1083 = or i32 %1077, %1082
  %1084 = load i32, ptr %5, align 4
  %1085 = xor i32 %1084, 530996398
  %1086 = mul i32 %1080, %1085
  %1087 = load i32, ptr %5, align 4
  %1088 = xor i32 %1087, 530996398
  %1089 = mul i32 %1083, %1088
  %1090 = sub i32 %1086, %1089
  %1091 = load i32, ptr %5, align 4
  %1092 = xor i32 %1091, -1166225586
  %1093 = mul i32 %1090, %1092
  %1094 = load i32, ptr %5, align 4
  %1095 = xor i32 %1094, 35173480
  %1096 = mul i32 %1093, %1095
  %1097 = load i32, ptr %5, align 4
  %1098 = xor i32 %1097, 1628139078
  %1099 = xor i32 %1096, %1098
  %1100 = load i32, ptr %5, align 4
  %1101 = xor i32 %1100, -1628139111
  %1102 = add i32 %1101, %1099
  %1103 = load i32, ptr %5, align 4
  %1104 = xor i32 %1103, -1628139080
  %1105 = add i32 %1102, %1104
  %1106 = lshr i32 %1068, %1105
  %1107 = add i32 %1067, %1106
  %1108 = and i32 %1067, %1106
  %1109 = sub i32 %1107, %1108
  store i32 %1109, ptr %14, align 4
  store i32 2086537121, ptr %5, align 4
  %1110 = xor i64 %1, 8699691710336261441
  %1111 = and i64 %1, %1110
  %1112 = or i64 %1, %1110
  %1113 = xor i64 %1, %1110
  %1114 = sub i64 %1112, %1113
  %1115 = sub i64 %1114, %1111
  %1116 = mul i64 %1115, 43
  %1117 = icmp sgt i64 %1116, 0
  br i1 %1117, label %3357, label %2944

1118:                                             ; preds = %32
  %1119 = load i32, ptr %14, align 4
  %1120 = load i8, ptr %22, align 1
  %1121 = zext i8 %1120 to i32
  %1122 = load i32, ptr %10, align 4
  %1123 = or i32 %1121, %1122
  %1124 = and i32 %1121, %1122
  %1125 = sub i32 %1123, %1124
  %1126 = load i32, ptr %5, align 4
  %1127 = xor i32 %1126, -1106605120
  %1128 = add i32 %1125, %1127
  %1129 = load i32, ptr %5, align 4
  %1130 = xor i32 %1129, -1106605120
  %1131 = or i32 %1125, %1130
  %1132 = sub i32 %1128, %1131
  %1133 = load i32, ptr %5, align 4
  %1134 = xor i32 %1133, -1106605120
  %1135 = add i32 %1132, %1134
  %1136 = load i32, ptr %5, align 4
  %1137 = xor i32 %1136, -1106605120
  %1138 = or i32 %1132, %1137
  %1139 = sub i32 %1135, %1138
  %1140 = lshr i32 %1119, %1139
  %1141 = load i32, ptr %14, align 4
  %1142 = load i8, ptr %22, align 1
  %1143 = zext i8 %1142 to i32
  %1144 = load i32, ptr %10, align 4
  %1145 = or i32 %1143, %1144
  %1146 = and i32 %1143, %1144
  %1147 = sub i32 %1145, %1146
  %1148 = load i32, ptr %5, align 4
  %1149 = xor i32 %1148, -1106605120
  %1150 = add i32 %1147, %1149
  %1151 = load i32, ptr %5, align 4
  %1152 = xor i32 %1151, -1106605120
  %1153 = or i32 %1147, %1152
  %1154 = sub i32 %1150, %1153
  %1155 = load i32, ptr %5, align 4
  %1156 = xor i32 %1155, -1106605120
  %1157 = add i32 %1154, %1156
  %1158 = load i32, ptr %5, align 4
  %1159 = xor i32 %1158, -1106605120
  %1160 = or i32 %1154, %1159
  %1161 = load i32, ptr %5, align 4
  %1162 = xor i32 %1161, 2128797026
  %1163 = mul i32 %1157, %1162
  %1164 = load i32, ptr %5, align 4
  %1165 = xor i32 %1164, 2128797026
  %1166 = mul i32 %1160, %1165
  %1167 = sub i32 %1163, %1166
  %1168 = load i32, ptr %5, align 4
  %1169 = xor i32 %1168, -1395428642
  %1170 = mul i32 %1167, %1169
  %1171 = load i32, ptr %5, align 4
  %1172 = xor i32 %1171, -1313706934
  %1173 = mul i32 %1170, %1172
  %1174 = load i32, ptr %5, align 4
  %1175 = xor i32 %1174, -1106605090
  %1176 = add i32 %1173, %1175
  %1177 = load i32, ptr %5, align 4
  %1178 = xor i32 %1177, -1106605057
  %1179 = mul i32 %1178, %1176
  %1180 = load i32, ptr %5, align 4
  %1181 = xor i32 %1180, -1106605058
  %1182 = mul i32 %1173, %1181
  %1183 = sub i32 %1179, %1182
  %1184 = load i32, ptr %5, align 4
  %1185 = xor i32 %1184, -1106605090
  %1186 = shl i32 %1185, %1183
  %1187 = mul i32 %1141, %1186
  %1188 = add i32 %1140, %1187
  %1189 = and i32 %1140, %1187
  %1190 = sub i32 %1188, %1189
  store i32 %1190, ptr %14, align 4
  store i32 2086537121, ptr %5, align 4
  %1191 = xor i64 %1, -7728145478017807547
  %1192 = and i64 %1, %1191
  %1193 = or i64 %1, %1191
  %1194 = xor i64 %1, %1191
  %1195 = add i64 %1192, %1193
  %1196 = sub i64 %1195, %1
  %1197 = sub i64 %1196, %1191
  %1198 = mul i64 %1197, 64
  %1199 = xor i64 %1, 3709546349546286437
  %1200 = and i64 %1, %1199
  %1201 = or i64 %1, %1199
  %1202 = xor i64 %1, %1199
  %1203 = add i64 %1, %1199
  %1204 = sub i64 %1203, %1202
  %1205 = mul i64 %1200, 2
  %1206 = sub i64 %1204, %1205
  %1207 = mul i64 %1206, 103
  %1208 = icmp eq i64 %1198, %1207
  br i1 %1208, label %2944, label %3365

1209:                                             ; preds = %32
  %1210 = load i8, ptr %22, align 1
  %1211 = zext i8 %1210 to i32
  %1212 = srem i32 %1211, 3
  %1213 = sext i32 %1212 to i64
  %1214 = getelementptr inbounds [3 x ptr], ptr %19, i64 0, i64 %1213
  %1215 = load ptr, ptr %1214, align 8
  %1216 = load i32, ptr %16, align 4
  %1217 = load i8, ptr %22, align 1
  %1218 = zext i8 %1217 to i32
  %1219 = call i32 %1215(i32 noundef %1216, i32 noundef %1218)
  %1220 = load i32, ptr %16, align 4
  %1221 = load i32, ptr %5, align 4
  %1222 = xor i32 %1221, -877186255
  %1223 = add i32 %1219, %1222
  %1224 = load i32, ptr %5, align 4
  %1225 = xor i32 %1224, -877186255
  %1226 = sub i32 %1220, %1225
  %1227 = mul i32 %1220, %1223
  %1228 = mul i32 %1219, %1226
  %1229 = sub i32 %1227, %1228
  store i32 %1229, ptr %16, align 4
  store i32 2086537121, ptr %5, align 4
  %1230 = xor i64 %1, -5985674400941424887
  %1231 = and i64 %1, %1230
  %1232 = or i64 %1, %1230
  %1233 = xor i64 %1, %1230
  %1234 = add i64 %1231, %1232
  %1235 = sub i64 %1234, %1
  %1236 = sub i64 %1235, %1230
  %1237 = mul i64 %1236, 143
  %1238 = icmp sle i64 %1237, 0
  br i1 %1238, label %2944, label %3373

1239:                                             ; preds = %32
  %1240 = load i32, ptr %14, align 4
  %1241 = load i32, ptr %15, align 4
  %1242 = call i32 @helper_mix(i32 noundef %1240, i32 noundef %1241)
  %1243 = load i32, ptr %16, align 4
  %1244 = or i32 %1243, %1242
  %1245 = and i32 %1243, %1242
  %1246 = sub i32 %1244, %1245
  store i32 %1246, ptr %16, align 4
  store i32 2086537121, ptr %5, align 4
  %1247 = xor i64 %1, 1422140413434122565
  %1248 = and i64 %1, %1247
  %1249 = or i64 %1, %1247
  %1250 = xor i64 %1, %1247
  %1251 = sub i64 %1249, %1250
  %1252 = sub i64 %1251, %1248
  %1253 = mul i64 %1252, 184
  %1254 = icmp slt i64 %1253, 0
  br i1 %1254, label %3380, label %2944

1255:                                             ; preds = %32
  %1256 = load i32, ptr %14, align 4
  %1257 = load i32, ptr %5, align 4
  %1258 = xor i32 %1257, -1068402955
  %1259 = add i32 %1256, %1258
  %1260 = load i32, ptr %5, align 4
  %1261 = xor i32 %1260, -1068402955
  %1262 = or i32 %1256, %1261
  %1263 = load i32, ptr %5, align 4
  %1264 = xor i32 %1263, -1155889527
  %1265 = mul i32 %1259, %1264
  %1266 = load i32, ptr %5, align 4
  %1267 = xor i32 %1266, -1155889527
  %1268 = mul i32 %1262, %1267
  %1269 = sub i32 %1265, %1268
  %1270 = load i32, ptr %5, align 4
  %1271 = xor i32 %1270, 977305121
  %1272 = mul i32 %1269, %1271
  %1273 = icmp ne i32 %1272, 0
  %1274 = select i1 %1273, i32 -1382531295, i32 -273641415
  store i32 %1274, ptr %5, align 4
  %1275 = xor i64 %1, 169180506723307263
  %1276 = and i64 %1, %1275
  %1277 = or i64 %1, %1275
  %1278 = xor i64 %1, %1275
  %1279 = sub i64 %1277, %1278
  %1280 = sub i64 %1279, %1276
  %1281 = mul i64 %1280, 177
  %1282 = icmp ugt i64 %1281, 0
  br i1 %1282, label %3390, label %2944

1283:                                             ; preds = %32
  %1284 = load i32, ptr %15, align 4
  %1285 = load i32, ptr %5, align 4
  %1286 = xor i32 %1285, -1382531293
  %1287 = add i32 %1284, %1286
  %1288 = load i32, ptr %5, align 4
  %1289 = xor i32 %1288, -1382531293
  %1290 = or i32 %1284, %1289
  %1291 = sub i32 %1287, %1290
  %1292 = icmp ne i32 %1291, 0
  %1293 = select i1 %1292, i32 1096928180, i32 -273641415
  store i32 %1293, ptr %5, align 4
  %1294 = xor i64 %1, -2859670557163331283
  %1295 = and i64 %1, %1294
  %1296 = or i64 %1, %1294
  %1297 = xor i64 %1, %1294
  %1298 = add i64 %1295, %1296
  %1299 = sub i64 %1298, %1
  %1300 = sub i64 %1299, %1294
  %1301 = mul i64 %1300, 20
  %1302 = icmp slt i64 %1301, 0
  br i1 %1302, label %3398, label %2944

1303:                                             ; preds = %32
  %1304 = load i32, ptr %16, align 4
  %1305 = load i32, ptr %5, align 4
  %1306 = xor i32 %1305, 1096928249
  %1307 = xor i32 %1304, %1306
  %1308 = load i32, ptr %5, align 4
  %1309 = xor i32 %1308, 1096928249
  %1310 = and i32 %1304, %1309
  %1311 = add i32 %1310, %1310
  %1312 = add i32 %1307, %1311
  store i32 %1312, ptr %16, align 4
  store i32 -1696220865, ptr %5, align 4
  %1313 = xor i64 %1, 2232129521419918397
  %1314 = and i64 %1, %1313
  %1315 = or i64 %1, %1313
  %1316 = xor i64 %1, %1313
  %1317 = add i64 %1314, %1315
  %1318 = sub i64 %1317, %1
  %1319 = sub i64 %1318, %1313
  %1320 = mul i64 %1319, 66
  %1321 = icmp slt i64 %1320, 0
  br i1 %1321, label %3406, label %2944

1322:                                             ; preds = %32
  %1323 = load i32, ptr %16, align 4
  %1324 = load i32, ptr %5, align 4
  %1325 = xor i32 %1324, -273641375
  %1326 = xor i32 %1323, %1325
  %1327 = load i32, ptr %5, align 4
  %1328 = xor i32 %1327, 273641414
  %1329 = xor i32 %1323, %1328
  %1330 = load i32, ptr %5, align 4
  %1331 = xor i32 %1330, -273641375
  %1332 = and i32 %1329, %1331
  %1333 = add i32 %1332, %1332
  %1334 = sub i32 %1326, %1333
  store i32 %1334, ptr %16, align 4
  store i32 -1696220865, ptr %5, align 4
  %1335 = xor i64 %1, 3169940473332979831
  %1336 = and i64 %1, %1335
  %1337 = or i64 %1, %1335
  %1338 = xor i64 %1, %1335
  %1339 = sub i64 %1337, %1338
  %1340 = sub i64 %1339, %1336
  %1341 = mul i64 %1340, 174
  %1342 = icmp sgt i64 %1341, 0
  br i1 %1342, label %3413, label %2944

1343:                                             ; preds = %32
  store i32 2086537121, ptr %5, align 4
  %1344 = xor i64 %1, -8075630328435038323
  %1345 = and i64 %1, %1344
  %1346 = or i64 %1, %1344
  %1347 = xor i64 %1, %1344
  %1348 = add i64 %1345, %1346
  %1349 = sub i64 %1348, %1
  %1350 = sub i64 %1349, %1344
  %1351 = mul i64 %1350, 79
  %1352 = xor i64 %1, -4163893994015311685
  %1353 = and i64 %1, %1352
  %1354 = or i64 %1, %1352
  %1355 = xor i64 %1, %1352
  %1356 = mul i64 %1354, 2
  %1357 = sub i64 %1356, %1355
  %1358 = sub i64 %1357, %1
  %1359 = sub i64 %1358, %1352
  %1360 = mul i64 %1359, 7
  %1361 = icmp ne i64 %1351, %1360
  br i1 %1361, label %3423, label %2944

1362:                                             ; preds = %32
  %1363 = load i32, ptr %15, align 4
  %1364 = load i64, ptr %21, align 8
  %1365 = add i64 %1364, 7
  %1366 = or i64 %1364, 7
  %1367 = sub i64 %1365, %1366
  %1368 = getelementptr inbounds nuw [8 x %struct.Node], ptr %12, i64 0, i64 %1367
  %1369 = getelementptr inbounds nuw %struct.Node, ptr %1368, i32 0, i32 0
  %1370 = load i32, ptr %1369, align 16
  %1371 = add i32 %1370, %1363
  %1372 = and i32 %1370, %1363
  %1373 = load i32, ptr %5, align 4
  %1374 = xor i32 %1373, -1243085774
  %1375 = mul i32 %1371, %1374
  %1376 = load i32, ptr %5, align 4
  %1377 = xor i32 %1376, -1243085774
  %1378 = mul i32 %1372, %1377
  %1379 = add i32 %1378, %1378
  %1380 = sub i32 %1375, %1379
  %1381 = load i32, ptr %5, align 4
  %1382 = xor i32 %1381, -1568076118
  %1383 = mul i32 %1380, %1382
  %1384 = load i32, ptr %5, align 4
  %1385 = xor i32 %1384, -420863944
  %1386 = mul i32 %1383, %1385
  store i32 %1386, ptr %1369, align 16
  %1387 = load i32, ptr %14, align 4
  %1388 = load i64, ptr %21, align 8
  %1389 = add i64 %1388, 7
  %1390 = or i64 %1388, 7
  %1391 = mul i64 %1389, 254217791
  %1392 = mul i64 %1390, 254217791
  %1393 = sub i64 %1391, %1392
  %1394 = mul i64 %1393, -9042038393702587969
  %1395 = getelementptr inbounds nuw [8 x %struct.Node], ptr %12, i64 0, i64 %1394
  %1396 = getelementptr inbounds nuw %struct.Node, ptr %1395, i32 0, i32 1
  %1397 = load i32, ptr %1396, align 4
  %1398 = xor i32 %1397, %1387
  %1399 = and i32 %1397, %1387
  %1400 = add i32 %1399, %1399
  %1401 = add i32 %1398, %1400
  store i32 %1401, ptr %1396, align 4
  store i32 2086537121, ptr %5, align 4
  %1402 = xor i64 %1, -5151534770139446777
  %1403 = and i64 %1, %1402
  %1404 = or i64 %1, %1402
  %1405 = xor i64 %1, %1402
  %1406 = sub i64 %1404, %1405
  %1407 = sub i64 %1406, %1403
  %1408 = mul i64 %1407, 78
  %1409 = icmp ne i64 %1408, 0
  br i1 %1409, label %3431, label %2944

1410:                                             ; preds = %32
  %1411 = load i64, ptr %21, align 8
  %1412 = or i64 %1411, 3
  %1413 = and i64 %1411, 3
  %1414 = add i64 %1412, %1413
  %1415 = load i64, ptr %9, align 8
  %1416 = icmp ult i64 %1414, %1415
  %1417 = select i1 %1416, i32 1244447402, i32 1162405581
  store i32 %1417, ptr %5, align 4
  %1418 = xor i64 %1, 1833959081964720827
  %1419 = and i64 %1, %1418
  %1420 = or i64 %1, %1418
  %1421 = xor i64 %1, %1418
  %1422 = sub i64 %1420, %1421
  %1423 = sub i64 %1422, %1419
  %1424 = mul i64 %1423, 55
  %1425 = icmp slt i64 %1424, 0
  br i1 %1425, label %3441, label %2944

1426:                                             ; preds = %32
  %1427 = load ptr, ptr %8, align 8
  %1428 = load i64, ptr %21, align 8
  %1429 = getelementptr inbounds nuw i8, ptr %1427, i64 %1428
  %1430 = load i8, ptr %1429, align 1
  %1431 = zext i8 %1430 to i32
  %1432 = load ptr, ptr %8, align 8
  %1433 = load i64, ptr %21, align 8
  %1434 = or i64 %1433, 1
  %1435 = and i64 %1433, 1
  %1436 = add i64 %1434, %1435
  %1437 = getelementptr inbounds nuw i8, ptr %1432, i64 %1436
  %1438 = load i8, ptr %1437, align 1
  %1439 = zext i8 %1438 to i32
  %1440 = load i32, ptr %5, align 4
  %1441 = xor i32 %1440, 1244447658
  %1442 = mul i32 %1439, %1441
  %1443 = xor i32 %1431, %1442
  %1444 = and i32 %1431, %1442
  %1445 = add i32 %1443, %1444
  %1446 = load ptr, ptr %8, align 8
  %1447 = load i64, ptr %21, align 8
  %1448 = xor i64 %1447, 2
  %1449 = and i64 %1447, 2
  %1450 = add i64 %1449, %1449
  %1451 = add i64 %1448, %1450
  %1452 = getelementptr inbounds nuw i8, ptr %1446, i64 %1451
  %1453 = load i8, ptr %1452, align 1
  %1454 = zext i8 %1453 to i32
  %1455 = load i32, ptr %5, align 4
  %1456 = xor i32 %1455, 1244512938
  %1457 = mul i32 %1454, %1456
  %1458 = add i32 %1445, %1457
  %1459 = and i32 %1445, %1457
  %1460 = sub i32 %1458, %1459
  %1461 = load ptr, ptr %8, align 8
  %1462 = load i64, ptr %21, align 8
  %1463 = or i64 %1462, 3
  %1464 = and i64 %1462, 3
  %1465 = add i64 %1463, %1464
  %1466 = getelementptr inbounds nuw i8, ptr %1461, i64 %1465
  %1467 = load i8, ptr %1466, align 1
  %1468 = zext i8 %1467 to i32
  %1469 = load i32, ptr %5, align 4
  %1470 = xor i32 %1469, 1261224618
  %1471 = mul i32 %1468, %1470
  %1472 = xor i32 %1460, %1471
  %1473 = and i32 %1460, %1471
  %1474 = add i32 %1472, %1473
  store i32 %1474, ptr %23, align 4
  %1475 = load i32, ptr %23, align 4
  store i32 %1475, ptr %13, align 4
  %1476 = load i32, ptr %13, align 4
  %1477 = icmp slt i32 %1476, 0
  %1478 = select i1 %1477, i32 -784680041, i32 1488141921
  store i32 %1478, ptr %5, align 4
  %1479 = xor i64 %1, 6917888381997403317
  %1480 = and i64 %1, %1479
  %1481 = or i64 %1, %1479
  %1482 = xor i64 %1, %1479
  %1483 = sub i64 %1481, %1482
  %1484 = sub i64 %1483, %1480
  %1485 = mul i64 %1484, 200
  %1486 = icmp slt i64 %1485, 0
  br i1 %1486, label %3449, label %2944

1487:                                             ; preds = %32
  %1488 = load i32, ptr %18, align 4
  %1489 = load i32, ptr %5, align 4
  %1490 = xor i32 %1489, -784680042
  %1491 = sub i32 %1488, %1490
  %1492 = load i32, ptr %5, align 4
  %1493 = xor i32 %1492, -784680043
  %1494 = mul i32 %1488, %1493
  %1495 = load i32, ptr %5, align 4
  %1496 = xor i32 %1495, -784680042
  %1497 = mul i32 %1496, %1491
  %1498 = sub i32 %1494, %1497
  store i32 %1498, ptr %18, align 4
  %1499 = load i32, ptr %13, align 4
  %1500 = load i32, ptr %16, align 4
  %1501 = xor i32 %1500, %1499
  %1502 = load i32, ptr %5, align 4
  %1503 = xor i32 %1502, 784680040
  %1504 = xor i32 %1500, %1503
  %1505 = and i32 %1504, %1499
  %1506 = add i32 %1505, %1505
  %1507 = sub i32 %1501, %1506
  store i32 %1507, ptr %16, align 4
  store i32 2056972320, ptr %5, align 4
  %1508 = xor i64 %1, -1654939016815338141
  %1509 = and i64 %1, %1508
  %1510 = or i64 %1, %1508
  %1511 = xor i64 %1, %1508
  %1512 = mul i64 %1510, 2
  %1513 = sub i64 %1512, %1511
  %1514 = sub i64 %1513, %1
  %1515 = sub i64 %1514, %1508
  %1516 = mul i64 %1515, 203
  %1517 = icmp ne i64 %1516, 0
  br i1 %1517, label %3458, label %2944

1518:                                             ; preds = %32
  %1519 = load i32, ptr %13, align 4
  %1520 = load i32, ptr %5, align 4
  %1521 = xor i32 %1520, 1488175518
  %1522 = add i32 %1519, %1521
  %1523 = load i32, ptr %5, align 4
  %1524 = xor i32 %1523, 1488175518
  %1525 = or i32 %1519, %1524
  %1526 = sub i32 %1522, %1525
  %1527 = load i32, ptr %16, align 4
  %1528 = xor i32 %1527, %1526
  %1529 = and i32 %1527, %1526
  %1530 = add i32 %1529, %1529
  %1531 = add i32 %1528, %1530
  store i32 %1531, ptr %16, align 4
  store i32 2056972320, ptr %5, align 4
  %1532 = xor i64 %1, -9222086571683422897
  %1533 = and i64 %1, %1532
  %1534 = or i64 %1, %1532
  %1535 = xor i64 %1, %1532
  %1536 = add i64 %1, %1532
  %1537 = sub i64 %1536, %1535
  %1538 = mul i64 %1533, 2
  %1539 = sub i64 %1537, %1538
  %1540 = mul i64 %1539, 254
  %1541 = icmp sgt i64 %1540, 0
  br i1 %1541, label %3467, label %2944

1542:                                             ; preds = %32
  %1543 = load i32, ptr %13, align 4
  %1544 = load i32, ptr %14, align 4
  %1545 = or i32 %1544, %1543
  %1546 = and i32 %1544, %1543
  %1547 = sub i32 %1545, %1546
  store i32 %1547, ptr %14, align 4
  store i32 1162405581, ptr %5, align 4
  %1548 = xor i64 %1, 7273187470095131141
  %1549 = and i64 %1, %1548
  %1550 = or i64 %1, %1548
  %1551 = xor i64 %1, %1548
  %1552 = add i64 %1, %1548
  %1553 = sub i64 %1552, %1551
  %1554 = mul i64 %1549, 2
  %1555 = sub i64 %1553, %1554
  %1556 = mul i64 %1555, 147
  %1557 = icmp sle i64 %1556, 0
  br i1 %1557, label %2944, label %3475

1558:                                             ; preds = %32
  store i32 2086537121, ptr %5, align 4
  %1559 = xor i64 %1, -1829272626885617655
  %1560 = and i64 %1, %1559
  %1561 = or i64 %1, %1559
  %1562 = xor i64 %1, %1559
  %1563 = add i64 %1, %1559
  %1564 = sub i64 %1563, %1562
  %1565 = mul i64 %1560, 2
  %1566 = sub i64 %1564, %1565
  %1567 = mul i64 %1566, 151
  %1568 = xor i64 %1, -3299968284014272805
  %1569 = and i64 %1, %1568
  %1570 = or i64 %1, %1568
  %1571 = xor i64 %1, %1568
  %1572 = mul i64 %1570, 2
  %1573 = sub i64 %1572, %1571
  %1574 = sub i64 %1573, %1
  %1575 = sub i64 %1574, %1568
  %1576 = mul i64 %1575, 192
  %1577 = icmp ne i64 %1567, %1576
  br i1 %1577, label %3483, label %2944

1578:                                             ; preds = %32
  store i32 0, ptr %24, align 4
  store i32 -1670366853, ptr %5, align 4
  %1579 = xor i64 %1, -6543159979326384965
  %1580 = and i64 %1, %1579
  %1581 = or i64 %1, %1579
  %1582 = xor i64 %1, %1579
  %1583 = add i64 %1580, %1581
  %1584 = sub i64 %1583, %1
  %1585 = sub i64 %1584, %1579
  %1586 = mul i64 %1585, 58
  %1587 = icmp eq i64 %1586, 0
  br i1 %1587, label %2944, label %3493

1588:                                             ; preds = %32
  %1589 = load i32, ptr %24, align 4
  %1590 = icmp slt i32 %1589, 4
  %1591 = select i1 %1590, i32 -1910847437, i32 440849427
  store i32 %1591, ptr %5, align 4
  %1592 = xor i64 %1, -8604265332763696091
  %1593 = and i64 %1, %1592
  %1594 = or i64 %1, %1592
  %1595 = xor i64 %1, %1592
  %1596 = sub i64 %1594, %1595
  %1597 = sub i64 %1596, %1593
  %1598 = mul i64 %1597, 109
  %1599 = icmp eq i64 %1598, 0
  br i1 %1599, label %2944, label %3503

1600:                                             ; preds = %32
  %1601 = load i8, ptr %22, align 1
  %1602 = zext i8 %1601 to i32
  %1603 = load i32, ptr %24, align 4
  %1604 = load i32, ptr %5, align 4
  %1605 = xor i32 %1604, -1910847438
  %1606 = or i32 %1603, %1605
  %1607 = load i32, ptr %5, align 4
  %1608 = xor i32 %1607, -1910847438
  %1609 = and i32 %1603, %1608
  %1610 = add i32 %1606, %1609
  %1611 = mul nsw i32 %1602, %1610
  %1612 = load i32, ptr %14, align 4
  %1613 = xor i32 %1612, %1611
  %1614 = and i32 %1612, %1611
  %1615 = add i32 %1614, %1614
  %1616 = add i32 %1613, %1615
  store i32 %1616, ptr %14, align 4
  %1617 = load i32, ptr %14, align 4
  %1618 = load i32, ptr %24, align 4
  %1619 = load i32, ptr %5, align 4
  %1620 = xor i32 %1619, -1910847440
  %1621 = mul nsw i32 %1618, %1620
  %1622 = lshr i32 %1617, %1621
  %1623 = load i32, ptr %16, align 4
  %1624 = or i32 %1623, %1622
  %1625 = and i32 %1623, %1622
  %1626 = sub i32 %1624, %1625
  store i32 %1626, ptr %16, align 4
  %1627 = load i32, ptr %24, align 4
  %1628 = load i32, ptr %5, align 4
  %1629 = xor i32 %1628, -1910847438
  %1630 = or i32 %1627, %1629
  %1631 = load i32, ptr %5, align 4
  %1632 = xor i32 %1631, -1910847438
  %1633 = and i32 %1627, %1632
  %1634 = add i32 %1630, %1633
  store i32 %1634, ptr %24, align 4
  store i32 -1670366853, ptr %5, align 4
  %1635 = xor i64 %1, 8036961398709600537
  %1636 = and i64 %1, %1635
  %1637 = or i64 %1, %1635
  %1638 = xor i64 %1, %1635
  %1639 = mul i64 %1637, 2
  %1640 = sub i64 %1639, %1638
  %1641 = sub i64 %1640, %1
  %1642 = sub i64 %1641, %1635
  %1643 = mul i64 %1642, 67
  %1644 = icmp uge i64 %1643, 0
  br i1 %1644, label %2944, label %3512

1645:                                             ; preds = %32
  store i32 2086537121, ptr %5, align 4
  %1646 = xor i64 %1, 6827879972395234511
  %1647 = and i64 %1, %1646
  %1648 = or i64 %1, %1646
  %1649 = xor i64 %1, %1646
  %1650 = mul i64 %1648, 2
  %1651 = sub i64 %1650, %1649
  %1652 = sub i64 %1651, %1
  %1653 = sub i64 %1652, %1646
  %1654 = mul i64 %1653, 116
  %1655 = icmp slt i64 %1654, 0
  br i1 %1655, label %3521, label %2944

1656:                                             ; preds = %32
  %1657 = load i8, ptr %22, align 1
  %1658 = zext i8 %1657 to i32
  %1659 = icmp eq i32 %1658, 88
  %1660 = select i1 %1659, i32 -773448171, i32 1021317405
  store i32 %1660, ptr %5, align 4
  %1661 = xor i64 %1, 3037918294938229715
  %1662 = and i64 %1, %1661
  %1663 = or i64 %1, %1661
  %1664 = xor i64 %1, %1661
  %1665 = add i64 %1662, %1663
  %1666 = sub i64 %1665, %1
  %1667 = sub i64 %1666, %1661
  %1668 = mul i64 %1667, 43
  %1669 = icmp slt i64 %1668, 0
  br i1 %1669, label %3529, label %2944

1670:                                             ; preds = %32
  %1671 = load i32, ptr %16, align 4
  %1672 = load i32, ptr %5, align 4
  %1673 = xor i32 %1672, -773448172
  %1674 = sub i32 %1671, %1673
  %1675 = load i32, ptr %5, align 4
  %1676 = xor i32 %1675, -773452154
  %1677 = mul i32 %1671, %1676
  %1678 = load i32, ptr %5, align 4
  %1679 = xor i32 %1678, -773452153
  %1680 = mul i32 %1679, %1674
  %1681 = sub i32 %1677, %1680
  store i32 %1681, ptr %16, align 4
  %1682 = load i32, ptr %14, align 4
  %1683 = load i32, ptr %5, align 4
  %1684 = xor i32 %1683, -1984018867
  %1685 = add i32 %1682, %1684
  %1686 = load i32, ptr %5, align 4
  %1687 = xor i32 %1686, -1984018867
  %1688 = and i32 %1682, %1687
  %1689 = load i32, ptr %5, align 4
  %1690 = xor i32 %1689, -2060265184
  %1691 = mul i32 %1685, %1690
  %1692 = load i32, ptr %5, align 4
  %1693 = xor i32 %1692, -2060265184
  %1694 = mul i32 %1688, %1693
  %1695 = add i32 %1694, %1694
  %1696 = sub i32 %1691, %1695
  %1697 = load i32, ptr %5, align 4
  %1698 = xor i32 %1697, 1683787016
  %1699 = mul i32 %1696, %1698
  store i32 %1699, ptr %14, align 4
  %1700 = load i64, ptr %21, align 8
  %1701 = xor i64 %1700, 1
  %1702 = and i64 %1700, 1
  %1703 = add i64 %1702, %1702
  %1704 = add i64 %1701, %1703
  %1705 = load i64, ptr %9, align 8
  %1706 = icmp ult i64 %1704, %1705
  %1707 = select i1 %1706, i32 178261291, i32 -762950227
  store i32 %1707, ptr %5, align 4
  %1708 = xor i64 %1, -9134665249605928669
  %1709 = and i64 %1, %1708
  %1710 = or i64 %1, %1708
  %1711 = xor i64 %1, %1708
  %1712 = sub i64 %1710, %1711
  %1713 = sub i64 %1712, %1709
  %1714 = mul i64 %1713, 120
  %1715 = icmp sgt i64 %1714, 0
  br i1 %1715, label %3539, label %2944

1716:                                             ; preds = %32
  %1717 = load i32, ptr %16, align 4
  %1718 = load i32, ptr %5, align 4
  %1719 = xor i32 %1718, 1021317404
  %1720 = sub i32 %1717, %1719
  %1721 = load i32, ptr %5, align 4
  %1722 = xor i32 %1721, 1021317392
  %1723 = mul i32 %1717, %1722
  %1724 = load i32, ptr %5, align 4
  %1725 = xor i32 %1724, 1021317393
  %1726 = mul i32 %1725, %1720
  %1727 = sub i32 %1723, %1726
  store i32 %1727, ptr %16, align 4
  store i32 2086537121, ptr %5, align 4
  %1728 = xor i64 %1, -8961352383674610997
  %1729 = and i64 %1, %1728
  %1730 = or i64 %1, %1728
  %1731 = xor i64 %1, %1728
  %1732 = sub i64 %1730, %1731
  %1733 = sub i64 %1732, %1729
  %1734 = mul i64 %1733, 37
  %1735 = icmp sgt i64 %1734, 0
  br i1 %1735, label %3547, label %2944

1736:                                             ; preds = %32
  %1737 = load i32, ptr %10, align 4
  %1738 = load i32, ptr %5, align 4
  %1739 = xor i32 %1738, 1040377811
  %1740 = add i32 %1737, %1739
  %1741 = load i32, ptr %5, align 4
  %1742 = xor i32 %1741, 1040377811
  %1743 = or i32 %1737, %1742
  %1744 = sub i32 %1740, %1743
  %1745 = icmp eq i32 %1744, 0
  %1746 = select i1 %1745, i32 1317582984, i32 -219224532
  store i32 %1746, ptr %5, align 4
  %1747 = xor i64 %1, -4021824864838022073
  %1748 = and i64 %1, %1747
  %1749 = or i64 %1, %1747
  %1750 = xor i64 %1, %1747
  %1751 = add i64 %1, %1747
  %1752 = sub i64 %1751, %1750
  %1753 = mul i64 %1748, 2
  %1754 = sub i64 %1752, %1753
  %1755 = mul i64 %1754, 125
  %1756 = xor i64 %1, -6741598076922254905
  %1757 = and i64 %1, %1756
  %1758 = or i64 %1, %1756
  %1759 = xor i64 %1, %1756
  %1760 = add i64 %1757, %1758
  %1761 = sub i64 %1760, %1
  %1762 = sub i64 %1761, %1756
  %1763 = mul i64 %1762, 80
  %1764 = icmp ne i64 %1755, %1763
  br i1 %1764, label %3554, label %2944

1765:                                             ; preds = %32
  %1766 = load i8, ptr %22, align 1
  %1767 = zext i8 %1766 to i32
  %1768 = load i32, ptr %10, align 4
  %1769 = call i32 @helper_muladd(i32 noundef %1767, i32 noundef %1768)
  %1770 = load i32, ptr %16, align 4
  %1771 = xor i32 %1770, %1769
  %1772 = and i32 %1770, %1769
  %1773 = add i32 %1772, %1772
  %1774 = add i32 %1771, %1773
  store i32 %1774, ptr %16, align 4
  store i32 -2141812562, ptr %5, align 4
  %1775 = xor i64 %1, 2436773900297508887
  %1776 = and i64 %1, %1775
  %1777 = or i64 %1, %1775
  %1778 = xor i64 %1, %1775
  %1779 = add i64 %1, %1775
  %1780 = sub i64 %1779, %1778
  %1781 = mul i64 %1776, 2
  %1782 = sub i64 %1780, %1781
  %1783 = mul i64 %1782, 217
  %1784 = icmp uge i64 %1783, 0
  br i1 %1784, label %2944, label %3563

1785:                                             ; preds = %32
  %1786 = load i8, ptr %22, align 1
  %1787 = zext i8 %1786 to i32
  %1788 = load i32, ptr %10, align 4
  %1789 = call i32 @helper_xor(i32 noundef %1787, i32 noundef %1788)
  %1790 = load i32, ptr %16, align 4
  %1791 = xor i32 %1790, %1789
  %1792 = load i32, ptr %5, align 4
  %1793 = xor i32 %1792, 219224531
  %1794 = xor i32 %1790, %1793
  %1795 = and i32 %1794, %1789
  %1796 = add i32 %1795, %1795
  %1797 = sub i32 %1791, %1796
  store i32 %1797, ptr %16, align 4
  store i32 -2141812562, ptr %5, align 4
  %1798 = xor i64 %1, 7213439863195341265
  %1799 = and i64 %1, %1798
  %1800 = or i64 %1, %1798
  %1801 = xor i64 %1, %1798
  %1802 = mul i64 %1800, 2
  %1803 = sub i64 %1802, %1801
  %1804 = sub i64 %1803, %1
  %1805 = sub i64 %1804, %1798
  %1806 = mul i64 %1805, 96
  %1807 = xor i64 %1, 2375092092776537747
  %1808 = and i64 %1, %1807
  %1809 = or i64 %1, %1807
  %1810 = xor i64 %1, %1807
  %1811 = mul i64 %1809, 2
  %1812 = sub i64 %1811, %1810
  %1813 = sub i64 %1812, %1
  %1814 = sub i64 %1813, %1807
  %1815 = mul i64 %1814, 230
  %1816 = icmp ne i64 %1806, %1815
  br i1 %1816, label %3571, label %2944

1817:                                             ; preds = %32
  store i32 2086537121, ptr %5, align 4
  %1818 = xor i64 %1, 1311808441940029487
  %1819 = and i64 %1, %1818
  %1820 = or i64 %1, %1818
  %1821 = xor i64 %1, %1818
  %1822 = sub i64 %1820, %1821
  %1823 = sub i64 %1822, %1819
  %1824 = mul i64 %1823, 133
  %1825 = icmp slt i64 %1824, 1
  br i1 %1825, label %2944, label %3580

1826:                                             ; preds = %32
  %1827 = load i32, ptr %14, align 4
  %1828 = load i32, ptr %5, align 4
  %1829 = xor i32 %1828, 1714534689
  %1830 = or i32 %1827, %1829
  %1831 = load i32, ptr %5, align 4
  %1832 = xor i32 %1831, 1714534689
  %1833 = and i32 %1827, %1832
  %1834 = sub i32 %1830, %1833
  store i32 %1834, ptr %14, align 4
  %1835 = load i32, ptr %14, align 4
  %1836 = load i32, ptr %5, align 4
  %1837 = xor i32 %1836, -1714534879
  %1838 = add i32 %1835, %1837
  %1839 = load i32, ptr %5, align 4
  %1840 = xor i32 %1839, -1714534879
  %1841 = or i32 %1835, %1840
  %1842 = sub i32 %1838, %1841
  %1843 = load i32, ptr %16, align 4
  %1844 = load i32, ptr %5, align 4
  %1845 = xor i32 %1844, -1714534689
  %1846 = add i32 %1842, %1845
  %1847 = load i32, ptr %5, align 4
  %1848 = xor i32 %1847, -1714534689
  %1849 = sub i32 %1843, %1848
  %1850 = mul i32 %1843, %1846
  %1851 = mul i32 %1842, %1849
  %1852 = sub i32 %1850, %1851
  store i32 %1852, ptr %16, align 4
  store i32 2086537121, ptr %5, align 4
  %1853 = xor i64 %1, 5819877677084142111
  %1854 = and i64 %1, %1853
  %1855 = or i64 %1, %1853
  %1856 = xor i64 %1, %1853
  %1857 = add i64 %1854, %1855
  %1858 = sub i64 %1857, %1
  %1859 = sub i64 %1858, %1853
  %1860 = mul i64 %1859, 192
  %1861 = icmp eq i64 %1860, 0
  br i1 %1861, label %2944, label %3587

1862:                                             ; preds = %32
  store i32 1089690255, ptr %5, align 4
  %1863 = xor i64 %1, 2074162605977360733
  %1864 = and i64 %1, %1863
  %1865 = or i64 %1, %1863
  %1866 = xor i64 %1, %1863
  %1867 = add i64 %1, %1863
  %1868 = sub i64 %1867, %1866
  %1869 = mul i64 %1864, 2
  %1870 = sub i64 %1868, %1869
  %1871 = mul i64 %1870, 35
  %1872 = icmp slt i64 %1871, 1
  br i1 %1872, label %2944, label %3595

1873:                                             ; preds = %32
  %1874 = load i32, ptr %15, align 4
  %1875 = load i32, ptr %14, align 4
  %1876 = xor i32 %1874, %1875
  %1877 = and i32 %1874, %1875
  %1878 = load i32, ptr %5, align 4
  %1879 = xor i32 %1878, -1683306366
  %1880 = mul i32 %1876, %1879
  %1881 = load i32, ptr %5, align 4
  %1882 = xor i32 %1881, -1683306366
  %1883 = mul i32 %1877, %1882
  %1884 = add i32 %1880, %1883
  %1885 = load i32, ptr %5, align 4
  %1886 = xor i32 %1885, -899058206
  %1887 = mul i32 %1884, %1886
  %1888 = load i32, ptr %5, align 4
  %1889 = xor i32 %1888, -1897473738
  %1890 = mul i32 %1887, %1889
  %1891 = load i32, ptr %16, align 4
  %1892 = add i32 %1891, %1890
  %1893 = and i32 %1891, %1890
  %1894 = load i32, ptr %5, align 4
  %1895 = xor i32 %1894, -2071805386
  %1896 = mul i32 %1892, %1895
  %1897 = load i32, ptr %5, align 4
  %1898 = xor i32 %1897, -2071805386
  %1899 = mul i32 %1893, %1898
  %1900 = add i32 %1899, %1899
  %1901 = sub i32 %1896, %1900
  %1902 = load i32, ptr %5, align 4
  %1903 = xor i32 %1902, -1226046886
  %1904 = mul i32 %1901, %1903
  %1905 = load i32, ptr %5, align 4
  %1906 = xor i32 %1905, 1541489002
  %1907 = mul i32 %1904, %1906
  store i32 %1907, ptr %16, align 4
  store i32 2086537121, ptr %5, align 4
  %1908 = xor i64 %1, -6533376133996792331
  %1909 = and i64 %1, %1908
  %1910 = or i64 %1, %1908
  %1911 = xor i64 %1, %1908
  %1912 = mul i64 %1910, 2
  %1913 = sub i64 %1912, %1911
  %1914 = sub i64 %1913, %1
  %1915 = sub i64 %1914, %1908
  %1916 = mul i64 %1915, 149
  %1917 = xor i64 %1, -5743318806362544081
  %1918 = and i64 %1, %1917
  %1919 = or i64 %1, %1917
  %1920 = xor i64 %1, %1917
  %1921 = sub i64 %1919, %1920
  %1922 = sub i64 %1921, %1918
  %1923 = mul i64 %1922, 245
  %1924 = icmp ne i64 %1916, %1923
  br i1 %1924, label %3605, label %2944

1925:                                             ; preds = %32
  %1926 = load i32, ptr %16, align 4
  %1927 = load i32, ptr %5, align 4
  %1928 = xor i32 %1927, 2086540693
  %1929 = add i32 %1926, %1928
  %1930 = load i32, ptr %5, align 4
  %1931 = xor i32 %1930, 2086540693
  %1932 = or i32 %1926, %1931
  %1933 = sub i32 %1929, %1932
  %1934 = icmp eq i32 %1933, 4608
  %1935 = select i1 %1934, i32 -1098801675, i32 453336975
  store i32 %1935, ptr %5, align 4
  %1936 = xor i64 %1, -1676249541514643229
  %1937 = and i64 %1, %1936
  %1938 = or i64 %1, %1936
  %1939 = xor i64 %1, %1936
  %1940 = sub i64 %1938, %1939
  %1941 = sub i64 %1940, %1937
  %1942 = mul i64 %1941, 2
  %1943 = icmp eq i64 %1942, 0
  br i1 %1943, label %2944, label %3614

1944:                                             ; preds = %32
  %1945 = load i32, ptr %10, align 4
  %1946 = load i32, ptr %5, align 4
  %1947 = xor i32 %1946, -1098801692
  %1948 = mul nsw i32 %1945, %1947
  %1949 = load i32, ptr %16, align 4
  %1950 = or i32 %1949, %1948
  %1951 = and i32 %1949, %1948
  %1952 = add i32 %1950, %1951
  store i32 %1952, ptr %16, align 4
  store i32 453336975, ptr %5, align 4
  %1953 = xor i64 %1, -5335585464656214601
  %1954 = and i64 %1, %1953
  %1955 = or i64 %1, %1953
  %1956 = xor i64 %1, %1953
  %1957 = sub i64 %1955, %1956
  %1958 = sub i64 %1957, %1954
  %1959 = mul i64 %1958, 72
  %1960 = icmp slt i64 %1959, 0
  br i1 %1960, label %3621, label %2944

1961:                                             ; preds = %32
  %1962 = load i32, ptr %14, align 4
  %1963 = load i32, ptr %15, align 4
  %1964 = add i32 %1962, %1963
  %1965 = and i32 %1962, %1963
  %1966 = load i32, ptr %5, align 4
  %1967 = xor i32 %1966, 340673184
  %1968 = mul i32 %1964, %1967
  %1969 = load i32, ptr %5, align 4
  %1970 = xor i32 %1969, 340673184
  %1971 = mul i32 %1965, %1970
  %1972 = add i32 %1971, %1971
  %1973 = sub i32 %1968, %1972
  %1974 = load i32, ptr %5, align 4
  %1975 = xor i32 %1974, 1443875016
  %1976 = mul i32 %1973, %1975
  %1977 = load i32, ptr %5, align 4
  %1978 = xor i32 %1977, 1107710646
  %1979 = mul i32 %1976, %1978
  %1980 = icmp eq i32 %1979, -889275714
  %1981 = select i1 %1980, i32 709438, i32 1875319178
  store i32 %1981, ptr %5, align 4
  %1982 = xor i64 %1, 8450787752490205085
  %1983 = and i64 %1, %1982
  %1984 = or i64 %1, %1982
  %1985 = xor i64 %1, %1982
  %1986 = add i64 %1983, %1984
  %1987 = sub i64 %1986, %1
  %1988 = sub i64 %1987, %1982
  %1989 = mul i64 %1988, 70
  %1990 = xor i64 %1, 6103482868516509315
  %1991 = and i64 %1, %1990
  %1992 = or i64 %1, %1990
  %1993 = xor i64 %1, %1990
  %1994 = sub i64 %1992, %1993
  %1995 = sub i64 %1994, %1991
  %1996 = mul i64 %1995, 207
  %1997 = icmp ne i64 %1989, %1996
  br i1 %1997, label %3630, label %2944

1998:                                             ; preds = %32
  %1999 = load i32, ptr %16, align 4
  %2000 = load i32, ptr %5, align 4
  %2001 = xor i32 %2000, 742814
  %2002 = xor i32 %1999, %2001
  %2003 = load i32, ptr %5, align 4
  %2004 = xor i32 %2003, 742814
  %2005 = and i32 %1999, %2004
  %2006 = add i32 %2005, %2005
  %2007 = add i32 %2002, %2006
  store i32 %2007, ptr %16, align 4
  store i32 1875319178, ptr %5, align 4
  %2008 = xor i64 %1, 2061129290930052967
  %2009 = and i64 %1, %2008
  %2010 = or i64 %1, %2008
  %2011 = xor i64 %1, %2008
  %2012 = add i64 %1, %2008
  %2013 = sub i64 %2012, %2011
  %2014 = mul i64 %2009, 2
  %2015 = sub i64 %2013, %2014
  %2016 = mul i64 %2015, 110
  %2017 = icmp slt i64 %2016, 0
  br i1 %2017, label %3637, label %2944

2018:                                             ; preds = %32
  %2019 = load i64, ptr %21, align 8
  %2020 = load i32, ptr %16, align 4
  %2021 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i64 noundef %2019, i32 noundef %2020)
  store i32 524383503, ptr %5, align 4
  %2022 = xor i64 %1, -9174358200562605547
  %2023 = and i64 %1, %2022
  %2024 = or i64 %1, %2022
  %2025 = xor i64 %1, %2022
  %2026 = add i64 %1, %2022
  %2027 = sub i64 %2026, %2025
  %2028 = mul i64 %2023, 2
  %2029 = sub i64 %2027, %2028
  %2030 = mul i64 %2029, 126
  %2031 = icmp slt i64 %2030, 0
  br i1 %2031, label %3644, label %2944

2032:                                             ; preds = %32
  %2033 = load ptr, ptr %8, align 8
  %2034 = load i64, ptr %21, align 8
  %2035 = sub i64 %2034, 1
  %2036 = mul i64 %2034, 2
  %2037 = mul i64 1, %2035
  %2038 = sub i64 %2036, %2037
  %2039 = getelementptr inbounds nuw i8, ptr %2033, i64 %2038
  %2040 = load i8, ptr %2039, align 1
  %2041 = zext i8 %2040 to i32
  %2042 = icmp eq i32 %2041, 89
  %2043 = select i1 %2042, i32 1160694768, i32 -762950227
  store i32 %2043, ptr %5, align 4
  %2044 = xor i64 %1, 3289693744699820145
  %2045 = and i64 %1, %2044
  %2046 = or i64 %1, %2044
  %2047 = xor i64 %1, %2044
  %2048 = mul i64 %2046, 2
  %2049 = sub i64 %2048, %2047
  %2050 = sub i64 %2049, %1
  %2051 = sub i64 %2050, %2044
  %2052 = mul i64 %2051, 167
  %2053 = icmp ugt i64 %2052, 0
  br i1 %2053, label %3654, label %2944

2054:                                             ; preds = %32
  %2055 = load i32, ptr %16, align 4
  %2056 = load i32, ptr %5, align 4
  %2057 = xor i32 %2056, 1160694769
  %2058 = sub i32 %2055, %2057
  %2059 = load i32, ptr %5, align 4
  %2060 = xor i32 %2059, 1160688026
  %2061 = mul i32 %2055, %2060
  %2062 = load i32, ptr %5, align 4
  %2063 = xor i32 %2062, 1160688025
  %2064 = mul i32 %2063, %2058
  %2065 = sub i32 %2061, %2064
  store i32 %2065, ptr %16, align 4
  %2066 = load i32, ptr %17, align 4
  %2067 = load i32, ptr %5, align 4
  %2068 = xor i32 %2067, 1160694512
  %2069 = xor i32 %2066, %2068
  %2070 = load i32, ptr %5, align 4
  %2071 = xor i32 %2070, 1160694512
  %2072 = and i32 %2066, %2071
  %2073 = add i32 %2069, %2072
  store i32 %2073, ptr %17, align 4
  store i32 1806981429, ptr %5, align 4
  %2074 = xor i64 %1, -6412176629647582225
  %2075 = and i64 %1, %2074
  %2076 = or i64 %1, %2074
  %2077 = xor i64 %1, %2074
  %2078 = mul i64 %2076, 2
  %2079 = sub i64 %2078, %2077
  %2080 = sub i64 %2079, %1
  %2081 = sub i64 %2080, %2074
  %2082 = mul i64 %2081, 54
  %2083 = icmp sgt i64 %2082, 0
  br i1 %2083, label %3664, label %2944

2084:                                             ; preds = %32
  %2085 = load i32, ptr %16, align 4
  %2086 = load i32, ptr %5, align 4
  %2087 = xor i32 %2086, 762951531
  %2088 = add i32 %2085, %2087
  %2089 = load i32, ptr %5, align 4
  %2090 = xor i32 %2089, -762950228
  %2091 = add i32 %2088, %2090
  store i32 %2091, ptr %16, align 4
  %2092 = load i32, ptr %17, align 4
  %2093 = load i32, ptr %5, align 4
  %2094 = xor i32 %2093, 762950482
  %2095 = add i32 %2092, %2094
  %2096 = load i32, ptr %5, align 4
  %2097 = xor i32 %2096, 762950482
  %2098 = or i32 %2092, %2097
  %2099 = load i32, ptr %5, align 4
  %2100 = xor i32 %2099, 911421212
  %2101 = mul i32 %2095, %2100
  %2102 = load i32, ptr %5, align 4
  %2103 = xor i32 %2102, 911421212
  %2104 = mul i32 %2098, %2103
  %2105 = sub i32 %2101, %2104
  %2106 = load i32, ptr %5, align 4
  %2107 = xor i32 %2106, 1561062396
  %2108 = mul i32 %2105, %2107
  store i32 %2108, ptr %17, align 4
  store i32 1806981429, ptr %5, align 4
  %2109 = xor i64 %1, -5120568758129455401
  %2110 = and i64 %1, %2109
  %2111 = or i64 %1, %2109
  %2112 = xor i64 %1, %2109
  %2113 = add i64 %1, %2109
  %2114 = sub i64 %2113, %2112
  %2115 = mul i64 %2110, 2
  %2116 = sub i64 %2114, %2115
  %2117 = mul i64 %2116, 233
  %2118 = xor i64 %1, -1345033773838158973
  %2119 = and i64 %1, %2118
  %2120 = or i64 %1, %2118
  %2121 = xor i64 %1, %2118
  %2122 = add i64 %1, %2118
  %2123 = sub i64 %2122, %2121
  %2124 = mul i64 %2119, 2
  %2125 = sub i64 %2123, %2124
  %2126 = mul i64 %2125, 153
  %2127 = icmp eq i64 %2117, %2126
  br i1 %2127, label %2944, label %3672

2128:                                             ; preds = %32
  store i32 524383503, ptr %5, align 4
  %2129 = xor i64 %1, -5620136542449455221
  %2130 = and i64 %1, %2129
  %2131 = or i64 %1, %2129
  %2132 = xor i64 %1, %2129
  %2133 = sub i64 %2131, %2132
  %2134 = sub i64 %2133, %2130
  %2135 = mul i64 %2134, 194
  %2136 = icmp slt i64 %2135, 0
  br i1 %2136, label %3680, label %2944

2137:                                             ; preds = %32
  %2138 = load i64, ptr %21, align 8
  %2139 = xor i64 %2138, 1
  %2140 = and i64 %2138, 1
  %2141 = add i64 %2140, %2140
  %2142 = add i64 %2139, %2141
  store i64 %2142, ptr %21, align 8
  store i32 -1779405741, ptr %5, align 4
  %2143 = xor i64 %1, 7698524007743357375
  %2144 = and i64 %1, %2143
  %2145 = or i64 %1, %2143
  %2146 = xor i64 %1, %2143
  %2147 = sub i64 %2145, %2146
  %2148 = sub i64 %2147, %2144
  %2149 = mul i64 %2148, 236
  %2150 = icmp eq i64 %2149, 0
  br i1 %2150, label %2944, label %3689

2151:                                             ; preds = %32
  store i32 0, ptr %26, align 4
  store i32 -428376836, ptr %5, align 4
  %2152 = xor i64 %1, 2361340509973031935
  %2153 = and i64 %1, %2152
  %2154 = or i64 %1, %2152
  %2155 = xor i64 %1, %2152
  %2156 = add i64 %1, %2152
  %2157 = sub i64 %2156, %2155
  %2158 = mul i64 %2153, 2
  %2159 = sub i64 %2157, %2158
  %2160 = mul i64 %2159, 104
  %2161 = xor i64 %1, -5666336899940910165
  %2162 = and i64 %1, %2161
  %2163 = or i64 %1, %2161
  %2164 = xor i64 %1, %2161
  %2165 = add i64 %1, %2161
  %2166 = sub i64 %2165, %2164
  %2167 = mul i64 %2162, 2
  %2168 = sub i64 %2166, %2167
  %2169 = mul i64 %2168, 41
  %2170 = icmp eq i64 %2160, %2169
  br i1 %2170, label %2944, label %3698

2171:                                             ; preds = %32
  %2172 = load i32, ptr %26, align 4
  %2173 = icmp slt i32 %2172, 4
  %2174 = select i1 %2173, i32 2116959456, i32 842335839
  store i32 %2174, ptr %5, align 4
  %2175 = xor i64 %1, 5200861499914664337
  %2176 = and i64 %1, %2175
  %2177 = or i64 %1, %2175
  %2178 = xor i64 %1, %2175
  %2179 = add i64 %1, %2175
  %2180 = sub i64 %2179, %2178
  %2181 = mul i64 %2176, 2
  %2182 = sub i64 %2180, %2181
  %2183 = mul i64 %2182, 128
  %2184 = icmp ugt i64 %2183, 0
  br i1 %2184, label %3708, label %2944

2185:                                             ; preds = %32
  store i32 0, ptr %27, align 4
  store i32 -544239356, ptr %5, align 4
  %2186 = xor i64 %1, -4121063095277773283
  %2187 = and i64 %1, %2186
  %2188 = or i64 %1, %2186
  %2189 = xor i64 %1, %2186
  %2190 = add i64 %1, %2186
  %2191 = sub i64 %2190, %2189
  %2192 = mul i64 %2187, 2
  %2193 = sub i64 %2191, %2192
  %2194 = mul i64 %2193, 224
  %2195 = icmp eq i64 %2194, 0
  br i1 %2195, label %2944, label %3715

2196:                                             ; preds = %32
  %2197 = load i32, ptr %27, align 4
  %2198 = icmp slt i32 %2197, 4
  %2199 = select i1 %2198, i32 -418919653, i32 -1744330764
  store i32 %2199, ptr %5, align 4
  %2200 = xor i64 %1, 2872396338367087029
  %2201 = and i64 %1, %2200
  %2202 = or i64 %1, %2200
  %2203 = xor i64 %1, %2200
  %2204 = add i64 %2201, %2202
  %2205 = sub i64 %2204, %1
  %2206 = sub i64 %2205, %2200
  %2207 = mul i64 %2206, 66
  %2208 = icmp eq i64 %2207, 0
  br i1 %2208, label %2944, label %3722

2209:                                             ; preds = %32
  %2210 = load i32, ptr %26, align 4
  %2211 = load i32, ptr %27, align 4
  %2212 = mul nsw i32 %2210, %2211
  %2213 = load i32, ptr %16, align 4
  %2214 = load i32, ptr %5, align 4
  %2215 = xor i32 %2214, -418919654
  %2216 = add i32 %2213, %2215
  %2217 = load i32, ptr %5, align 4
  %2218 = xor i32 %2217, -418919654
  %2219 = sub i32 %2212, %2218
  %2220 = mul i32 %2212, %2216
  %2221 = mul i32 %2213, %2219
  %2222 = sub i32 %2220, %2221
  %2223 = load i32, ptr %17, align 4
  %2224 = xor i32 %2222, %2223
  %2225 = and i32 %2222, %2223
  %2226 = add i32 %2225, %2225
  %2227 = add i32 %2224, %2226
  store i32 %2227, ptr %28, align 4
  %2228 = load i32, ptr %26, align 4
  %2229 = load i32, ptr %27, align 4
  %2230 = load i32, ptr %5, align 4
  %2231 = xor i32 %2230, -418919654
  %2232 = add i32 %2229, %2231
  %2233 = load i32, ptr %5, align 4
  %2234 = xor i32 %2233, -418919654
  %2235 = sub i32 %2228, %2234
  %2236 = mul i32 %2228, %2232
  %2237 = mul i32 %2229, %2235
  %2238 = sub i32 %2236, %2237
  %2239 = load i32, ptr %5, align 4
  %2240 = xor i32 %2239, -418919654
  %2241 = add i32 %2238, %2240
  %2242 = load i32, ptr %5, align 4
  %2243 = xor i32 %2242, -418919654
  %2244 = or i32 %2238, %2243
  %2245 = sub i32 %2241, %2244
  %2246 = icmp ne i32 %2245, 0
  %2247 = select i1 %2246, i32 -89597928, i32 -1665134820
  store i32 %2247, ptr %5, align 4
  %2248 = xor i64 %1, -5555999286512309199
  %2249 = and i64 %1, %2248
  %2250 = or i64 %1, %2248
  %2251 = xor i64 %1, %2248
  %2252 = add i64 %1, %2248
  %2253 = sub i64 %2252, %2251
  %2254 = mul i64 %2249, 2
  %2255 = sub i64 %2253, %2254
  %2256 = mul i64 %2255, 209
  %2257 = icmp sgt i64 %2256, 0
  br i1 %2257, label %3732, label %2944

2258:                                             ; preds = %32
  %2259 = load i32, ptr %28, align 4
  %2260 = load i32, ptr %14, align 4
  %2261 = add i32 %2259, %2260
  %2262 = and i32 %2259, %2260
  %2263 = add i32 %2262, %2262
  %2264 = sub i32 %2261, %2263
  %2265 = load i32, ptr %26, align 4
  %2266 = sext i32 %2265 to i64
  %2267 = getelementptr inbounds [4 x [4 x i32]], ptr %25, i64 0, i64 %2266
  %2268 = load i32, ptr %27, align 4
  %2269 = sext i32 %2268 to i64
  %2270 = getelementptr inbounds [4 x i32], ptr %2267, i64 0, i64 %2269
  store i32 %2264, ptr %2270, align 4
  store i32 329203641, ptr %5, align 4
  %2271 = xor i64 %1, -3114129891522073917
  %2272 = and i64 %1, %2271
  %2273 = or i64 %1, %2271
  %2274 = xor i64 %1, %2271
  %2275 = sub i64 %2273, %2274
  %2276 = sub i64 %2275, %2272
  %2277 = mul i64 %2276, 51
  %2278 = icmp ne i64 %2277, 0
  br i1 %2278, label %3739, label %2944

2279:                                             ; preds = %32
  %2280 = load i32, ptr %28, align 4
  %2281 = load i32, ptr %15, align 4
  %2282 = or i32 %2280, %2281
  %2283 = and i32 %2280, %2281
  %2284 = add i32 %2282, %2283
  %2285 = load i32, ptr %26, align 4
  %2286 = sext i32 %2285 to i64
  %2287 = getelementptr inbounds [4 x [4 x i32]], ptr %25, i64 0, i64 %2286
  %2288 = load i32, ptr %27, align 4
  %2289 = sext i32 %2288 to i64
  %2290 = getelementptr inbounds [4 x i32], ptr %2287, i64 0, i64 %2289
  store i32 %2284, ptr %2290, align 4
  store i32 329203641, ptr %5, align 4
  %2291 = xor i64 %1, 2308389777519215911
  %2292 = and i64 %1, %2291
  %2293 = or i64 %1, %2291
  %2294 = xor i64 %1, %2291
  %2295 = mul i64 %2293, 2
  %2296 = sub i64 %2295, %2294
  %2297 = sub i64 %2296, %1
  %2298 = sub i64 %2297, %2291
  %2299 = mul i64 %2298, 105
  %2300 = icmp slt i64 %2299, 0
  br i1 %2300, label %3747, label %2944

2301:                                             ; preds = %32
  %2302 = load i32, ptr %27, align 4
  %2303 = load i32, ptr %5, align 4
  %2304 = xor i32 %2303, 329203640
  %2305 = or i32 %2302, %2304
  %2306 = load i32, ptr %5, align 4
  %2307 = xor i32 %2306, 329203640
  %2308 = and i32 %2302, %2307
  %2309 = add i32 %2305, %2308
  store i32 %2309, ptr %27, align 4
  store i32 -544239356, ptr %5, align 4
  %2310 = xor i64 %1, -2594440337173223177
  %2311 = and i64 %1, %2310
  %2312 = or i64 %1, %2310
  %2313 = xor i64 %1, %2310
  %2314 = mul i64 %2312, 2
  %2315 = sub i64 %2314, %2313
  %2316 = sub i64 %2315, %1
  %2317 = sub i64 %2316, %2310
  %2318 = mul i64 %2317, 124
  %2319 = icmp sle i64 %2318, 0
  br i1 %2319, label %2944, label %3757

2320:                                             ; preds = %32
  %2321 = load i32, ptr %26, align 4
  %2322 = load i32, ptr %5, align 4
  %2323 = xor i32 %2322, -1744330763
  %2324 = or i32 %2321, %2323
  %2325 = load i32, ptr %5, align 4
  %2326 = xor i32 %2325, -1744330763
  %2327 = and i32 %2321, %2326
  %2328 = add i32 %2324, %2327
  store i32 %2328, ptr %26, align 4
  store i32 -428376836, ptr %5, align 4
  %2329 = xor i64 %1, 6748496678451473039
  %2330 = and i64 %1, %2329
  %2331 = or i64 %1, %2329
  %2332 = xor i64 %1, %2329
  %2333 = sub i64 %2331, %2332
  %2334 = sub i64 %2333, %2330
  %2335 = mul i64 %2334, 169
  %2336 = xor i64 %1, 2371377658141448299
  %2337 = and i64 %1, %2336
  %2338 = or i64 %1, %2336
  %2339 = xor i64 %1, %2336
  %2340 = add i64 %2337, %2338
  %2341 = sub i64 %2340, %1
  %2342 = sub i64 %2341, %2336
  %2343 = mul i64 %2342, 81
  %2344 = icmp ne i64 %2335, %2343
  br i1 %2344, label %3767, label %2944

2345:                                             ; preds = %32
  store i32 0, ptr %29, align 4
  store i32 -868544919, ptr %5, align 4
  %2346 = xor i64 %1, -746058685125976161
  %2347 = and i64 %1, %2346
  %2348 = or i64 %1, %2346
  %2349 = xor i64 %1, %2346
  %2350 = mul i64 %2348, 2
  %2351 = sub i64 %2350, %2349
  %2352 = sub i64 %2351, %1
  %2353 = sub i64 %2352, %2346
  %2354 = mul i64 %2353, 101
  %2355 = icmp ugt i64 %2354, 0
  br i1 %2355, label %3777, label %2944

2356:                                             ; preds = %32
  %2357 = load i32, ptr %29, align 4
  %2358 = icmp slt i32 %2357, 16
  %2359 = select i1 %2358, i32 -1803932441, i32 -836149047
  store i32 %2359, ptr %5, align 4
  %2360 = xor i64 %1, -6896315467773666067
  %2361 = and i64 %1, %2360
  %2362 = or i64 %1, %2360
  %2363 = xor i64 %1, %2360
  %2364 = mul i64 %2362, 2
  %2365 = sub i64 %2364, %2363
  %2366 = sub i64 %2365, %1
  %2367 = sub i64 %2366, %2360
  %2368 = mul i64 %2367, 85
  %2369 = icmp slt i64 %2368, 0
  br i1 %2369, label %3786, label %2944

2370:                                             ; preds = %32
  %2371 = load i32, ptr %29, align 4
  %2372 = sdiv i32 %2371, 4
  store i32 %2372, ptr %30, align 4
  %2373 = load i32, ptr %29, align 4
  %2374 = srem i32 %2373, 4
  store i32 %2374, ptr %31, align 4
  %2375 = load i32, ptr %30, align 4
  %2376 = sext i32 %2375 to i64
  %2377 = getelementptr inbounds [4 x [4 x i32]], ptr %25, i64 0, i64 %2376
  %2378 = load i32, ptr %31, align 4
  %2379 = sext i32 %2378 to i64
  %2380 = getelementptr inbounds [4 x i32], ptr %2377, i64 0, i64 %2379
  %2381 = load i32, ptr %2380, align 4
  %2382 = icmp slt i32 %2381, 0
  %2383 = select i1 %2382, i32 264447763, i32 -795490789
  store i32 %2383, ptr %5, align 4
  %2384 = xor i64 %1, 4085779454882209777
  %2385 = and i64 %1, %2384
  %2386 = or i64 %1, %2384
  %2387 = xor i64 %1, %2384
  %2388 = add i64 %1, %2384
  %2389 = sub i64 %2388, %2387
  %2390 = mul i64 %2385, 2
  %2391 = sub i64 %2389, %2390
  %2392 = mul i64 %2391, 32
  %2393 = icmp uge i64 %2392, 0
  br i1 %2393, label %2944, label %3794

2394:                                             ; preds = %32
  %2395 = load i32, ptr %30, align 4
  %2396 = sext i32 %2395 to i64
  %2397 = getelementptr inbounds [4 x [4 x i32]], ptr %25, i64 0, i64 %2396
  %2398 = load i32, ptr %31, align 4
  %2399 = sext i32 %2398 to i64
  %2400 = getelementptr inbounds [4 x i32], ptr %2397, i64 0, i64 %2399
  %2401 = load i32, ptr %2400, align 4
  %2402 = load i32, ptr %16, align 4
  %2403 = load i32, ptr %5, align 4
  %2404 = xor i32 %2403, -264447764
  %2405 = xor i32 %2401, %2404
  %2406 = add i32 %2402, %2405
  %2407 = load i32, ptr %5, align 4
  %2408 = xor i32 %2407, 264447762
  %2409 = add i32 %2406, %2408
  store i32 %2409, ptr %16, align 4
  store i32 -1666258949, ptr %5, align 4
  %2410 = xor i64 %1, 3088917363900261577
  %2411 = and i64 %1, %2410
  %2412 = or i64 %1, %2410
  %2413 = xor i64 %1, %2410
  %2414 = sub i64 %2412, %2413
  %2415 = sub i64 %2414, %2411
  %2416 = mul i64 %2415, 235
  %2417 = icmp slt i64 %2416, 0
  br i1 %2417, label %3802, label %2944

2418:                                             ; preds = %32
  %2419 = load i32, ptr %30, align 4
  %2420 = sext i32 %2419 to i64
  %2421 = getelementptr inbounds [4 x [4 x i32]], ptr %25, i64 0, i64 %2420
  %2422 = load i32, ptr %31, align 4
  %2423 = sext i32 %2422 to i64
  %2424 = getelementptr inbounds [4 x i32], ptr %2421, i64 0, i64 %2423
  %2425 = load i32, ptr %2424, align 4
  %2426 = icmp eq i32 %2425, 0
  %2427 = select i1 %2426, i32 1015442924, i32 -1602699218
  store i32 %2427, ptr %5, align 4
  %2428 = xor i64 %1, 4803680085063903973
  %2429 = and i64 %1, %2428
  %2430 = or i64 %1, %2428
  %2431 = xor i64 %1, %2428
  %2432 = mul i64 %2430, 2
  %2433 = sub i64 %2432, %2431
  %2434 = sub i64 %2433, %1
  %2435 = sub i64 %2434, %2428
  %2436 = mul i64 %2435, 184
  %2437 = icmp ugt i64 %2436, 0
  br i1 %2437, label %3810, label %2944

2438:                                             ; preds = %32
  %2439 = load i32, ptr %16, align 4
  %2440 = load i32, ptr %5, align 4
  %2441 = xor i32 %2440, 1015421595
  %2442 = or i32 %2439, %2441
  %2443 = load i32, ptr %5, align 4
  %2444 = xor i32 %2443, 1015421595
  %2445 = and i32 %2439, %2444
  %2446 = sub i32 %2442, %2445
  store i32 %2446, ptr %16, align 4
  store i32 421679941, ptr %5, align 4
  %2447 = xor i64 %1, -7415270855516655287
  %2448 = and i64 %1, %2447
  %2449 = or i64 %1, %2447
  %2450 = xor i64 %1, %2447
  %2451 = add i64 %2448, %2449
  %2452 = sub i64 %2451, %1
  %2453 = sub i64 %2452, %2447
  %2454 = mul i64 %2453, 251
  %2455 = xor i64 %1, 5080182097286688135
  %2456 = and i64 %1, %2455
  %2457 = or i64 %1, %2455
  %2458 = xor i64 %1, %2455
  %2459 = add i64 %2456, %2457
  %2460 = sub i64 %2459, %1
  %2461 = sub i64 %2460, %2455
  %2462 = mul i64 %2461, 237
  %2463 = icmp eq i64 %2454, %2462
  br i1 %2463, label %2944, label %3818

2464:                                             ; preds = %32
  %2465 = load i32, ptr %30, align 4
  %2466 = sext i32 %2465 to i64
  %2467 = getelementptr inbounds [4 x [4 x i32]], ptr %25, i64 0, i64 %2466
  %2468 = load i32, ptr %31, align 4
  %2469 = sext i32 %2468 to i64
  %2470 = getelementptr inbounds [4 x i32], ptr %2467, i64 0, i64 %2469
  %2471 = load i32, ptr %2470, align 4
  %2472 = load i32, ptr %5, align 4
  %2473 = xor i32 %2472, -1602698287
  %2474 = add i32 %2471, %2473
  %2475 = load i32, ptr %5, align 4
  %2476 = xor i32 %2475, -1602698287
  %2477 = or i32 %2471, %2476
  %2478 = load i32, ptr %5, align 4
  %2479 = xor i32 %2478, -1559985675
  %2480 = mul i32 %2474, %2479
  %2481 = load i32, ptr %5, align 4
  %2482 = xor i32 %2481, -1559985675
  %2483 = mul i32 %2477, %2482
  %2484 = sub i32 %2480, %2483
  %2485 = load i32, ptr %5, align 4
  %2486 = xor i32 %2485, 173581909
  %2487 = mul i32 %2484, %2486
  %2488 = load i32, ptr %5, align 4
  %2489 = xor i32 %2488, -2099255257
  %2490 = mul i32 %2487, %2489
  %2491 = load i32, ptr %16, align 4
  %2492 = xor i32 %2491, %2490
  %2493 = and i32 %2491, %2490
  %2494 = add i32 %2493, %2493
  %2495 = add i32 %2492, %2494
  store i32 %2495, ptr %16, align 4
  store i32 421679941, ptr %5, align 4
  %2496 = xor i64 %1, 1726109690769506803
  %2497 = and i64 %1, %2496
  %2498 = or i64 %1, %2496
  %2499 = xor i64 %1, %2496
  %2500 = add i64 %2497, %2498
  %2501 = sub i64 %2500, %1
  %2502 = sub i64 %2501, %2496
  %2503 = mul i64 %2502, 100
  %2504 = icmp slt i64 %2503, 0
  br i1 %2504, label %3825, label %2944

2505:                                             ; preds = %32
  store i32 -1666258949, ptr %5, align 4
  %2506 = xor i64 %1, 4184944333078591739
  %2507 = and i64 %1, %2506
  %2508 = or i64 %1, %2506
  %2509 = xor i64 %1, %2506
  %2510 = mul i64 %2508, 2
  %2511 = sub i64 %2510, %2509
  %2512 = sub i64 %2511, %1
  %2513 = sub i64 %2512, %2506
  %2514 = mul i64 %2513, 24
  %2515 = icmp sgt i64 %2514, 0
  br i1 %2515, label %3832, label %2944

2516:                                             ; preds = %32
  %2517 = load i32, ptr %29, align 4
  %2518 = load i32, ptr %5, align 4
  %2519 = xor i32 %2518, -1666258950
  %2520 = xor i32 %2517, %2519
  %2521 = load i32, ptr %5, align 4
  %2522 = xor i32 %2521, -1666258950
  %2523 = and i32 %2517, %2522
  %2524 = add i32 %2523, %2523
  %2525 = add i32 %2520, %2524
  store i32 %2525, ptr %29, align 4
  store i32 -868544919, ptr %5, align 4
  %2526 = xor i64 %1, 2024711411568827797
  %2527 = and i64 %1, %2526
  %2528 = or i64 %1, %2526
  %2529 = xor i64 %1, %2526
  %2530 = add i64 %1, %2526
  %2531 = sub i64 %2530, %2529
  %2532 = mul i64 %2527, 2
  %2533 = sub i64 %2531, %2532
  %2534 = mul i64 %2533, 76
  %2535 = icmp ne i64 %2534, 0
  br i1 %2535, label %3840, label %2944

2536:                                             ; preds = %32
  %2537 = load i32, ptr %10, align 4
  %2538 = icmp slt i32 %2537, -1000
  %2539 = select i1 %2538, i32 -447774249, i32 -7623356
  store i32 %2539, ptr %5, align 4
  %2540 = xor i64 %1, 1575207762993482629
  %2541 = and i64 %1, %2540
  %2542 = or i64 %1, %2540
  %2543 = xor i64 %1, %2540
  %2544 = sub i64 %2542, %2543
  %2545 = sub i64 %2544, %2541
  %2546 = mul i64 %2545, 18
  %2547 = icmp sle i64 %2546, 0
  br i1 %2547, label %2944, label %3850

2548:                                             ; preds = %32
  %2549 = load i32, ptr %10, align 4
  %2550 = load i32, ptr %5, align 4
  %2551 = xor i32 %2550, -447774250
  %2552 = add i32 %2549, %2551
  %2553 = load i32, ptr %5, align 4
  %2554 = xor i32 %2553, 1699709399
  %2555 = mul i32 %2554, %2552
  %2556 = load i32, ptr %5, align 4
  %2557 = xor i32 %2556, -1699709400
  %2558 = mul i32 %2549, %2557
  %2559 = sub i32 %2555, %2558
  store i32 %2559, ptr %16, align 4
  store i32 -368695623, ptr %5, align 4
  %2560 = xor i64 %1, 3383063301275187403
  %2561 = and i64 %1, %2560
  %2562 = or i64 %1, %2560
  %2563 = xor i64 %1, %2560
  %2564 = add i64 %2561, %2562
  %2565 = sub i64 %2564, %1
  %2566 = sub i64 %2565, %2560
  %2567 = mul i64 %2566, 114
  %2568 = icmp slt i64 %2567, 1
  br i1 %2568, label %2944, label %3858

2569:                                             ; preds = %32
  %2570 = load i32, ptr %10, align 4
  %2571 = icmp sgt i32 %2570, 1000
  %2572 = select i1 %2571, i32 650587877, i32 396917974
  store i32 %2572, ptr %5, align 4
  %2573 = xor i64 %1, 7272836496348034797
  %2574 = and i64 %1, %2573
  %2575 = or i64 %1, %2573
  %2576 = xor i64 %1, %2573
  %2577 = add i64 %1, %2573
  %2578 = sub i64 %2577, %2576
  %2579 = mul i64 %2574, 2
  %2580 = sub i64 %2578, %2579
  %2581 = mul i64 %2580, 101
  %2582 = icmp eq i64 %2581, 0
  br i1 %2582, label %2944, label %3868

2583:                                             ; preds = %32
  %2584 = load i32, ptr %10, align 4
  %2585 = load i32, ptr %5, align 4
  %2586 = xor i32 %2585, -650587878
  %2587 = xor i32 %2584, %2586
  %2588 = load i32, ptr %5, align 4
  %2589 = xor i32 %2588, 1496895770
  %2590 = add i32 %2589, %2587
  %2591 = load i32, ptr %5, align 4
  %2592 = xor i32 %2591, 650587876
  %2593 = add i32 %2590, %2592
  store i32 %2593, ptr %16, align 4
  store i32 1950909894, ptr %5, align 4
  %2594 = xor i64 %1, -1384901007243023187
  %2595 = and i64 %1, %2594
  %2596 = or i64 %1, %2594
  %2597 = xor i64 %1, %2594
  %2598 = add i64 %2595, %2596
  %2599 = sub i64 %2598, %1
  %2600 = sub i64 %2599, %2594
  %2601 = mul i64 %2600, 245
  %2602 = icmp sle i64 %2601, 0
  br i1 %2602, label %2944, label %3875

2603:                                             ; preds = %32
  %2604 = load i32, ptr %10, align 4
  %2605 = icmp eq i32 %2604, -3
  %2606 = select i1 %2605, i32 -1586248026, i32 -2134288894
  %2607 = icmp eq i32 %2604, -2
  %2608 = select i1 %2607, i32 -338344281, i32 %2606
  %2609 = icmp eq i32 %2604, -1
  %2610 = select i1 %2609, i32 92137420, i32 %2608
  %2611 = icmp eq i32 %2604, 0
  %2612 = select i1 %2611, i32 409335101, i32 %2610
  %2613 = icmp eq i32 %2604, 1
  %2614 = select i1 %2613, i32 -1217652478, i32 %2612
  %2615 = icmp eq i32 %2604, 2
  %2616 = select i1 %2615, i32 525654147, i32 %2614
  %2617 = icmp eq i32 %2604, 3
  %2618 = select i1 %2617, i32 1282585283, i32 %2616
  store i32 %2618, ptr %5, align 4
  %2619 = xor i64 %1, 2606645932693212597
  %2620 = and i64 %1, %2619
  %2621 = or i64 %1, %2619
  %2622 = xor i64 %1, %2619
  %2623 = sub i64 %2621, %2622
  %2624 = sub i64 %2623, %2620
  %2625 = mul i64 %2624, 190
  %2626 = icmp sgt i64 %2625, 0
  br i1 %2626, label %3882, label %2944

2627:                                             ; preds = %32
  %2628 = load i32, ptr %16, align 4
  %2629 = load i32, ptr %5, align 4
  %2630 = xor i32 %2629, -1841236587
  %2631 = or i32 %2628, %2630
  %2632 = load i32, ptr %5, align 4
  %2633 = xor i32 %2632, -1841236587
  %2634 = and i32 %2628, %2633
  %2635 = sub i32 %2631, %2634
  store i32 %2635, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2636 = xor i64 %1, 8061343647797654801
  %2637 = and i64 %1, %2636
  %2638 = or i64 %1, %2636
  %2639 = xor i64 %1, %2636
  %2640 = add i64 %1, %2636
  %2641 = sub i64 %2640, %2639
  %2642 = mul i64 %2637, 2
  %2643 = sub i64 %2641, %2642
  %2644 = mul i64 %2643, 80
  %2645 = icmp eq i64 %2644, 0
  br i1 %2645, label %2944, label %3889

2646:                                             ; preds = %32
  %2647 = load i32, ptr %14, align 4
  %2648 = udiv i32 %2647, 65536
  %2649 = load i32, ptr %16, align 4
  %2650 = load i32, ptr %5, align 4
  %2651 = xor i32 %2650, -338344282
  %2652 = add i32 %2648, %2651
  %2653 = load i32, ptr %5, align 4
  %2654 = xor i32 %2653, -338344282
  %2655 = sub i32 %2649, %2654
  %2656 = mul i32 %2649, %2652
  %2657 = mul i32 %2648, %2655
  %2658 = sub i32 %2656, %2657
  store i32 %2658, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2659 = xor i64 %1, -7292029516079174215
  %2660 = and i64 %1, %2659
  %2661 = or i64 %1, %2659
  %2662 = xor i64 %1, %2659
  %2663 = add i64 %2660, %2661
  %2664 = sub i64 %2663, %1
  %2665 = sub i64 %2664, %2659
  %2666 = mul i64 %2665, 96
  %2667 = icmp sgt i64 %2666, 0
  br i1 %2667, label %3897, label %2944

2668:                                             ; preds = %32
  %2669 = load i32, ptr %15, align 4
  %2670 = load i32, ptr %5, align 4
  %2671 = xor i32 %2670, 92084275
  %2672 = add i32 %2669, %2671
  %2673 = load i32, ptr %5, align 4
  %2674 = xor i32 %2673, 92084275
  %2675 = or i32 %2669, %2674
  %2676 = load i32, ptr %5, align 4
  %2677 = xor i32 %2676, 1693736169
  %2678 = mul i32 %2672, %2677
  %2679 = load i32, ptr %5, align 4
  %2680 = xor i32 %2679, 1693736169
  %2681 = mul i32 %2675, %2680
  %2682 = sub i32 %2678, %2681
  %2683 = load i32, ptr %5, align 4
  %2684 = xor i32 %2683, 1099808541
  %2685 = mul i32 %2682, %2684
  %2686 = load i32, ptr %5, align 4
  %2687 = xor i32 %2686, -267686191
  %2688 = mul i32 %2685, %2687
  %2689 = load i32, ptr %16, align 4
  %2690 = xor i32 %2689, %2688
  %2691 = load i32, ptr %5, align 4
  %2692 = xor i32 %2691, -92137421
  %2693 = xor i32 %2689, %2692
  %2694 = and i32 %2693, %2688
  %2695 = add i32 %2694, %2694
  %2696 = sub i32 %2690, %2695
  store i32 %2696, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2697 = xor i64 %1, -1059763916544511871
  %2698 = and i64 %1, %2697
  %2699 = or i64 %1, %2697
  %2700 = xor i64 %1, %2697
  %2701 = add i64 %2698, %2699
  %2702 = sub i64 %2701, %1
  %2703 = sub i64 %2702, %2697
  %2704 = mul i64 %2703, 167
  %2705 = xor i64 %1, 2302120362119693041
  %2706 = and i64 %1, %2705
  %2707 = or i64 %1, %2705
  %2708 = xor i64 %1, %2705
  %2709 = add i64 %2706, %2707
  %2710 = sub i64 %2709, %1
  %2711 = sub i64 %2710, %2705
  %2712 = mul i64 %2711, 140
  %2713 = icmp eq i64 %2704, %2712
  br i1 %2713, label %2944, label %3904

2714:                                             ; preds = %32
  %2715 = load i32, ptr %16, align 4
  %2716 = load i32, ptr %5, align 4
  %2717 = xor i32 %2716, 409335100
  %2718 = sub i32 %2715, %2717
  %2719 = load i32, ptr %5, align 4
  %2720 = xor i32 %2719, 409335103
  %2721 = mul i32 %2715, %2720
  %2722 = load i32, ptr %5, align 4
  %2723 = xor i32 %2722, 409335100
  %2724 = mul i32 %2723, %2718
  %2725 = sub i32 %2721, %2724
  store i32 %2725, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2726 = xor i64 %1, 6101060536659258891
  %2727 = and i64 %1, %2726
  %2728 = or i64 %1, %2726
  %2729 = xor i64 %1, %2726
  %2730 = mul i64 %2728, 2
  %2731 = sub i64 %2730, %2729
  %2732 = sub i64 %2731, %1
  %2733 = sub i64 %2732, %2726
  %2734 = mul i64 %2733, 119
  %2735 = icmp eq i64 %2734, 0
  br i1 %2735, label %2944, label %3913

2736:                                             ; preds = %32
  %2737 = load i32, ptr %16, align 4
  %2738 = load i32, ptr %5, align 4
  %2739 = xor i32 %2738, -1217652479
  %2740 = mul nsw i32 %2737, %2739
  store i32 %2740, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2741 = xor i64 %1, 7036596497636502333
  %2742 = and i64 %1, %2741
  %2743 = or i64 %1, %2741
  %2744 = xor i64 %1, %2741
  %2745 = add i64 %1, %2741
  %2746 = sub i64 %2745, %2744
  %2747 = mul i64 %2742, 2
  %2748 = sub i64 %2746, %2747
  %2749 = mul i64 %2748, 91
  %2750 = icmp ugt i64 %2749, 0
  br i1 %2750, label %3921, label %2944

2751:                                             ; preds = %32
  %2752 = load i32, ptr %16, align 4
  %2753 = sdiv i32 %2752, 2
  store i32 %2753, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2754 = xor i64 %1, 3153242233922010121
  %2755 = and i64 %1, %2754
  %2756 = or i64 %1, %2754
  %2757 = xor i64 %1, %2754
  %2758 = add i64 %2755, %2756
  %2759 = sub i64 %2758, %1
  %2760 = sub i64 %2759, %2754
  %2761 = mul i64 %2760, 121
  %2762 = icmp uge i64 %2761, 0
  br i1 %2762, label %2944, label %3929

2763:                                             ; preds = %32
  %2764 = load i32, ptr %16, align 4
  %2765 = srem i32 %2764, 9973
  store i32 %2765, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2766 = xor i64 %1, 9168010328256339217
  %2767 = and i64 %1, %2766
  %2768 = or i64 %1, %2766
  %2769 = xor i64 %1, %2766
  %2770 = mul i64 %2768, 2
  %2771 = sub i64 %2770, %2769
  %2772 = sub i64 %2771, %1
  %2773 = sub i64 %2772, %2766
  %2774 = mul i64 %2773, 19
  %2775 = icmp sle i64 %2774, 0
  br i1 %2775, label %2944, label %3939

2776:                                             ; preds = %32
  %2777 = load i32, ptr %10, align 4
  %2778 = load i32, ptr %10, align 4
  %2779 = mul nsw i32 %2777, %2778
  %2780 = load i32, ptr %16, align 4
  %2781 = load i32, ptr %5, align 4
  %2782 = xor i32 %2781, -2134288893
  %2783 = add i32 %2779, %2782
  %2784 = load i32, ptr %5, align 4
  %2785 = xor i32 %2784, -2134288893
  %2786 = sub i32 %2780, %2785
  %2787 = mul i32 %2780, %2783
  %2788 = mul i32 %2779, %2786
  %2789 = sub i32 %2787, %2788
  store i32 %2789, ptr %16, align 4
  store i32 1613524571, ptr %5, align 4
  %2790 = xor i64 %1, -5998221838124796863
  %2791 = and i64 %1, %2790
  %2792 = or i64 %1, %2790
  %2793 = xor i64 %1, %2790
  %2794 = mul i64 %2792, 2
  %2795 = sub i64 %2794, %2793
  %2796 = sub i64 %2795, %1
  %2797 = sub i64 %2796, %2790
  %2798 = mul i64 %2797, 107
  %2799 = icmp slt i64 %2798, 0
  br i1 %2799, label %3949, label %2944

2800:                                             ; preds = %32
  store i32 1950909894, ptr %5, align 4
  %2801 = xor i64 %1, 6112455644804708495
  %2802 = and i64 %1, %2801
  %2803 = or i64 %1, %2801
  %2804 = xor i64 %1, %2801
  %2805 = add i64 %2802, %2803
  %2806 = sub i64 %2805, %1
  %2807 = sub i64 %2806, %2801
  %2808 = mul i64 %2807, 146
  %2809 = icmp slt i64 %2808, 0
  br i1 %2809, label %3957, label %2944

2810:                                             ; preds = %32
  store i32 -368695623, ptr %5, align 4
  %2811 = xor i64 %1, -2369872463173612391
  %2812 = and i64 %1, %2811
  %2813 = or i64 %1, %2811
  %2814 = xor i64 %1, %2811
  %2815 = add i64 %1, %2811
  %2816 = sub i64 %2815, %2814
  %2817 = mul i64 %2812, 2
  %2818 = sub i64 %2816, %2817
  %2819 = mul i64 %2818, 134
  %2820 = xor i64 %1, 2530210927456896497
  %2821 = and i64 %1, %2820
  %2822 = or i64 %1, %2820
  %2823 = xor i64 %1, %2820
  %2824 = add i64 %2821, %2822
  %2825 = sub i64 %2824, %1
  %2826 = sub i64 %2825, %2820
  %2827 = mul i64 %2826, 235
  %2828 = icmp eq i64 %2819, %2827
  br i1 %2828, label %2944, label %3965

2829:                                             ; preds = %32
  %2830 = load i32, ptr %18, align 4
  %2831 = icmp ne i32 %2830, 0
  %2832 = select i1 %2831, i32 -1611992960, i32 1337073016
  store i32 %2832, ptr %5, align 4
  %2833 = xor i64 %1, -2323788969078896729
  %2834 = and i64 %1, %2833
  %2835 = or i64 %1, %2833
  %2836 = xor i64 %1, %2833
  %2837 = mul i64 %2835, 2
  %2838 = sub i64 %2837, %2836
  %2839 = sub i64 %2838, %1
  %2840 = sub i64 %2839, %2833
  %2841 = mul i64 %2840, 164
  %2842 = icmp slt i64 %2841, 0
  br i1 %2842, label %3974, label %2944

2843:                                             ; preds = %32
  %2844 = load i32, ptr %16, align 4
  %2845 = load i32, ptr %5, align 4
  %2846 = xor i32 %2845, -559173183
  %2847 = add i32 %2844, %2846
  %2848 = load i32, ptr %5, align 4
  %2849 = xor i32 %2848, -559173183
  %2850 = and i32 %2844, %2849
  %2851 = add i32 %2850, %2850
  %2852 = sub i32 %2847, %2851
  store i32 %2852, ptr %16, align 4
  store i32 1337073016, ptr %5, align 4
  %2853 = xor i64 %1, -6434589558426225797
  %2854 = and i64 %1, %2853
  %2855 = or i64 %1, %2853
  %2856 = xor i64 %1, %2853
  %2857 = add i64 %2854, %2855
  %2858 = sub i64 %2857, %1
  %2859 = sub i64 %2858, %2853
  %2860 = mul i64 %2859, 190
  %2861 = icmp ugt i64 %2860, 0
  br i1 %2861, label %3981, label %2944

2862:                                             ; preds = %32
  %2863 = load volatile i32, ptr %11, align 4
  %2864 = load i32, ptr %5, align 4
  %2865 = xor i32 %2864, -367544099
  %2866 = add i32 %2863, %2865
  %2867 = load i32, ptr %5, align 4
  %2868 = xor i32 %2867, -367544099
  %2869 = and i32 %2863, %2868
  %2870 = load i32, ptr %5, align 4
  %2871 = xor i32 %2870, -689360941
  %2872 = mul i32 %2866, %2871
  %2873 = load i32, ptr %5, align 4
  %2874 = xor i32 %2873, -689360941
  %2875 = mul i32 %2869, %2874
  %2876 = add i32 %2875, %2875
  %2877 = sub i32 %2872, %2876
  %2878 = load i32, ptr %5, align 4
  %2879 = xor i32 %2878, 1966679419
  %2880 = mul i32 %2877, %2879
  %2881 = icmp ne i32 %2880, 0
  %2882 = select i1 %2881, i32 -1215653437, i32 -663708264
  store i32 %2882, ptr %5, align 4
  %2883 = xor i64 %1, -696373647556576787
  %2884 = and i64 %1, %2883
  %2885 = or i64 %1, %2883
  %2886 = xor i64 %1, %2883
  %2887 = mul i64 %2885, 2
  %2888 = sub i64 %2887, %2886
  %2889 = sub i64 %2888, %1
  %2890 = sub i64 %2889, %2883
  %2891 = mul i64 %2890, 138
  %2892 = icmp slt i64 %2891, 0
  br i1 %2892, label %3989, label %2944

2893:                                             ; preds = %32
  store i32 -8888, ptr %7, align 4
  store i32 1940021752, ptr %5, align 4
  %2894 = xor i64 %1, 7523572832280438431
  %2895 = and i64 %1, %2894
  %2896 = or i64 %1, %2894
  %2897 = xor i64 %1, %2894
  %2898 = sub i64 %2896, %2897
  %2899 = sub i64 %2898, %2895
  %2900 = mul i64 %2899, 208
  %2901 = icmp eq i64 %2900, 0
  br i1 %2901, label %2944, label %3998

2902:                                             ; preds = %32
  %2903 = load i32, ptr %16, align 4
  %2904 = load i32, ptr %14, align 4
  %2905 = load i32, ptr %15, align 4
  %2906 = load i32, ptr %5, align 4
  %2907 = xor i32 %2906, -663708263
  %2908 = add i32 %2905, %2907
  %2909 = load i32, ptr %5, align 4
  %2910 = xor i32 %2909, -663708263
  %2911 = sub i32 %2904, %2910
  %2912 = mul i32 %2904, %2908
  %2913 = mul i32 %2905, %2911
  %2914 = sub i32 %2912, %2913
  %2915 = load i32, ptr %17, align 4
  %2916 = or i32 %2914, %2915
  %2917 = and i32 %2914, %2915
  %2918 = add i32 %2916, %2917
  %2919 = add i32 %2903, %2918
  %2920 = and i32 %2903, %2918
  %2921 = add i32 %2920, %2920
  %2922 = sub i32 %2919, %2921
  store i32 %2922, ptr %7, align 4
  store i32 1940021752, ptr %5, align 4
  %2923 = xor i64 %1, -2421679421430676209
  %2924 = and i64 %1, %2923
  %2925 = or i64 %1, %2923
  %2926 = xor i64 %1, %2923
  %2927 = add i64 %1, %2923
  %2928 = sub i64 %2927, %2926
  %2929 = mul i64 %2924, 2
  %2930 = sub i64 %2928, %2929
  %2931 = mul i64 %2930, 219
  %2932 = xor i64 %1, -4997682325756690437
  %2933 = and i64 %1, %2932
  %2934 = or i64 %1, %2932
  %2935 = xor i64 %1, %2932
  %2936 = mul i64 %2934, 2
  %2937 = sub i64 %2936, %2935
  %2938 = sub i64 %2937, %1
  %2939 = sub i64 %2938, %2932
  %2940 = mul i64 %2939, 200
  %2941 = icmp ne i64 %2931, %2940
  br i1 %2941, label %4006, label %2944

2942:                                             ; preds = %32
  %2943 = load i32, ptr %7, align 4
  ret i32 %2943

2944:                                             ; preds = %4081, %4072, %4065, %4057, %4049, %4041, %4032, %4025, %4006, %3998, %3989, %3981, %3974, %3965, %3957, %3949, %3939, %3929, %3921, %3913, %3904, %3897, %3889, %3882, %3875, %3868, %3858, %3850, %3840, %3832, %3825, %3818, %3810, %3802, %3794, %3786, %3777, %3767, %3757, %3747, %3739, %3732, %3722, %3715, %3708, %3698, %3689, %3680, %3672, %3664, %3654, %3644, %3637, %3630, %3621, %3614, %3605, %3595, %3587, %3580, %3571, %3563, %3554, %3547, %3539, %3529, %3521, %3512, %3503, %3493, %3483, %3475, %3467, %3458, %3449, %3441, %3431, %3423, %3413, %3406, %3398, %3390, %3380, %3373, %3365, %3357, %3348, %3340, %3331, %3324, %3317, %3307, %3298, %3289, %3281, %3274, %3265, %3256, %3248, %3241, %3231, %3224, %3217, %3208, %3199, %3191, %3184, %3175, %3168, %3158, %3148, %3140, %3131, %3124, %3117, %3107, %3100, %3090, %3080, %3072, %3052, %3039, %3026, %3013, %3002, %2991, %2969, %2956, %2902, %2893, %2862, %2843, %2829, %2810, %2800, %2776, %2763, %2751, %2736, %2714, %2668, %2646, %2627, %2603, %2583, %2569, %2548, %2536, %2516, %2505, %2464, %2438, %2418, %2394, %2370, %2356, %2345, %2320, %2301, %2279, %2258, %2209, %2196, %2185, %2171, %2151, %2137, %2128, %2084, %2054, %2032, %2018, %1998, %1961, %1944, %1925, %1873, %1862, %1826, %1817, %1785, %1765, %1736, %1716, %1670, %1656, %1645, %1600, %1588, %1578, %1558, %1542, %1518, %1487, %1426, %1410, %1362, %1343, %1322, %1303, %1283, %1255, %1239, %1209, %1118, %1022, %992, %957, %935, %914, %855, %846, %835, %824, %774, %746, %731, %721, %681, %637, %597, %570, %527, %499, %468, %337, %322, %311, %289, %268, %254, %231, %222, %208, %160, %138, %114, %67, %55, %36
  br label %32

2945:                                             ; preds = %32
  store i32 1560964999, ptr %5, align 4
  call void asm sideeffect "", ""()
  %2946 = xor i64 %1, -3260480744105952093
  %2947 = and i64 %1, %2946
  %2948 = or i64 %1, %2946
  %2949 = xor i64 %1, %2946
  %2950 = add i64 %1, %2946
  %2951 = sub i64 %2950, %2949
  %2952 = mul i64 %2947, 2
  %2953 = sub i64 %2951, %2952
  %2954 = mul i64 %2953, 7
  %2955 = icmp slt i64 %2954, 0
  br i1 %2955, label %4016, label %32

2956:                                             ; preds = %32
  %2957 = load i32, ptr %5, align 4
  %2958 = xor i32 %2957, -931906198
  store i32 %2958, ptr %5, align 4
  %2959 = xor i64 %1, 7370188763699963311
  %2960 = and i64 %1, %2959
  %2961 = or i64 %1, %2959
  %2962 = xor i64 %1, %2959
  %2963 = mul i64 %2961, 2
  %2964 = sub i64 %2963, %2962
  %2965 = sub i64 %2964, %1
  %2966 = sub i64 %2965, %2959
  %2967 = mul i64 %2966, 30
  %2968 = icmp uge i64 %2967, 0
  br i1 %2968, label %2944, label %4025

2969:                                             ; preds = %32
  %2970 = load i32, ptr %5, align 4
  %2971 = xor i32 %2970, -2105978569
  store i32 %2971, ptr %5, align 4
  %2972 = xor i64 %1, -7051383373158514485
  %2973 = and i64 %1, %2972
  %2974 = or i64 %1, %2972
  %2975 = xor i64 %1, %2972
  %2976 = add i64 %1, %2972
  %2977 = sub i64 %2976, %2975
  %2978 = mul i64 %2973, 2
  %2979 = sub i64 %2977, %2978
  %2980 = mul i64 %2979, 234
  %2981 = xor i64 %1, 7166900189630710887
  %2982 = and i64 %1, %2981
  %2983 = or i64 %1, %2981
  %2984 = xor i64 %1, %2981
  %2985 = add i64 %1, %2981
  %2986 = sub i64 %2985, %2984
  %2987 = mul i64 %2982, 2
  %2988 = sub i64 %2986, %2987
  %2989 = mul i64 %2988, 176
  %2990 = icmp eq i64 %2980, %2989
  br i1 %2990, label %2944, label %4032

2991:                                             ; preds = %32
  %2992 = load i32, ptr %5, align 4
  %2993 = xor i32 %2992, -2049479207
  store i32 %2993, ptr %5, align 4
  %2994 = xor i64 %1, 8170608579789913937
  %2995 = and i64 %1, %2994
  %2996 = or i64 %1, %2994
  %2997 = xor i64 %1, %2994
  %2998 = sub i64 %2996, %2997
  %2999 = sub i64 %2998, %2995
  %3000 = mul i64 %2999, 188
  %3001 = icmp slt i64 %3000, 0
  br i1 %3001, label %4041, label %2944

3002:                                             ; preds = %32
  %3003 = load i32, ptr %5, align 4
  %3004 = xor i32 %3003, 592714720
  store i32 %3004, ptr %5, align 4
  %3005 = xor i64 %1, 8423391388394837799
  %3006 = and i64 %1, %3005
  %3007 = or i64 %1, %3005
  %3008 = xor i64 %1, %3005
  %3009 = sub i64 %3007, %3008
  %3010 = sub i64 %3009, %3006
  %3011 = mul i64 %3010, 198
  %3012 = icmp sle i64 %3011, 0
  br i1 %3012, label %2944, label %4049

3013:                                             ; preds = %32
  %3014 = load i32, ptr %5, align 4
  %3015 = xor i32 %3014, -200946057
  store i32 %3015, ptr %5, align 4
  %3016 = xor i64 %1, 388056653158058073
  %3017 = and i64 %1, %3016
  %3018 = or i64 %1, %3016
  %3019 = xor i64 %1, %3016
  %3020 = mul i64 %3018, 2
  %3021 = sub i64 %3020, %3019
  %3022 = sub i64 %3021, %1
  %3023 = sub i64 %3022, %3016
  %3024 = mul i64 %3023, 89
  %3025 = icmp slt i64 %3024, 1
  br i1 %3025, label %2944, label %4057

3026:                                             ; preds = %32
  %3027 = load i32, ptr %5, align 4
  %3028 = xor i32 %3027, -868809828
  store i32 %3028, ptr %5, align 4
  %3029 = xor i64 %1, 5486830029999727977
  %3030 = and i64 %1, %3029
  %3031 = or i64 %1, %3029
  %3032 = xor i64 %1, %3029
  %3033 = mul i64 %3031, 2
  %3034 = sub i64 %3033, %3032
  %3035 = sub i64 %3034, %1
  %3036 = sub i64 %3035, %3029
  %3037 = mul i64 %3036, 204
  %3038 = icmp ne i64 %3037, 0
  br i1 %3038, label %4065, label %2944

3039:                                             ; preds = %32
  %3040 = load i32, ptr %5, align 4
  %3041 = xor i32 %3040, -1258302407
  store i32 %3041, ptr %5, align 4
  %3042 = xor i64 %1, -1859079356649126627
  %3043 = and i64 %1, %3042
  %3044 = or i64 %1, %3042
  %3045 = xor i64 %1, %3042
  %3046 = add i64 %1, %3042
  %3047 = sub i64 %3046, %3045
  %3048 = mul i64 %3043, 2
  %3049 = sub i64 %3047, %3048
  %3050 = mul i64 %3049, 209
  %3051 = icmp sgt i64 %3050, 0
  br i1 %3051, label %4072, label %2944

3052:                                             ; preds = %32
  %3053 = load i32, ptr %5, align 4
  %3054 = xor i32 %3053, -624463481
  store i32 %3054, ptr %5, align 4
  %3055 = xor i64 %1, -6886218350717844141
  %3056 = and i64 %1, %3055
  %3057 = or i64 %1, %3055
  %3058 = xor i64 %1, %3055
  %3059 = mul i64 %3057, 2
  %3060 = sub i64 %3059, %3058
  %3061 = sub i64 %3060, %1
  %3062 = sub i64 %3061, %3055
  %3063 = mul i64 %3062, 52
  %3064 = xor i64 %1, 6685091261123745557
  %3065 = and i64 %1, %3064
  %3066 = or i64 %1, %3064
  %3067 = xor i64 %1, %3064
  %3068 = sub i64 %3066, %3067
  %3069 = sub i64 %3068, %3065
  %3070 = mul i64 %3069, 169
  %3071 = icmp ne i64 %3063, %3070
  br i1 %3071, label %4081, label %2944

3072:                                             ; preds = %36
  %3073 = load i64, ptr %4, align 8
  %3074 = ptrtoint ptr %0 to i64
  %3075 = zext i32 %2 to i64
  %3076 = or i64 %3075, %3073
  %3077 = and i64 %3076, %3075
  %3078 = add i64 %3077, %3074
  %3079 = xor i64 %3078, %3073
  store i64 %3079, ptr %4, align 8
  br label %2944

3080:                                             ; preds = %55
  %3081 = load i64, ptr %4, align 8
  %3082 = ptrtoint ptr %0 to i64
  %3083 = zext i32 %2 to i64
  %3084 = add i64 %3081, %1
  %3085 = mul i64 %3084, %1
  %3086 = or i64 %3085, %3083
  %3087 = or i64 %3086, %1
  %3088 = or i64 %3087, %3083
  %3089 = and i64 %3088, %3082
  store i64 %3089, ptr %4, align 8
  br label %2944

3090:                                             ; preds = %67
  %3091 = load i64, ptr %4, align 8
  %3092 = ptrtoint ptr %0 to i64
  %3093 = zext i32 %2 to i64
  %3094 = and i64 %3092, %3093
  %3095 = or i64 %3094, %3091
  %3096 = and i64 %3095, %1
  %3097 = xor i64 %3096, %1
  %3098 = or i64 %3097, %3092
  %3099 = add i64 %3098, %3092
  store i64 %3099, ptr %4, align 8
  br label %2944

3100:                                             ; preds = %114
  %3101 = load i64, ptr %4, align 8
  %3102 = ptrtoint ptr %0 to i64
  %3103 = zext i32 %2 to i64
  %3104 = xor i64 %1, %3101
  %3105 = add i64 %3104, %1
  %3106 = xor i64 %3105, %1
  store i64 %3106, ptr %4, align 8
  br label %2944

3107:                                             ; preds = %138
  %3108 = load i64, ptr %4, align 8
  %3109 = ptrtoint ptr %0 to i64
  %3110 = zext i32 %2 to i64
  %3111 = mul i64 %3109, %1
  %3112 = sub i64 %3111, %3109
  %3113 = or i64 %3112, %1
  %3114 = sub i64 %3113, %1
  %3115 = add i64 %3114, %3110
  %3116 = or i64 %3115, %3110
  store i64 %3116, ptr %4, align 8
  br label %2944

3117:                                             ; preds = %160
  %3118 = load i64, ptr %4, align 8
  %3119 = ptrtoint ptr %0 to i64
  %3120 = zext i32 %2 to i64
  %3121 = and i64 %3120, %1
  %3122 = and i64 %3121, %3119
  %3123 = add i64 %3122, %1
  store i64 %3123, ptr %4, align 8
  br label %2944

3124:                                             ; preds = %208
  %3125 = load i64, ptr %4, align 8
  %3126 = ptrtoint ptr %0 to i64
  %3127 = zext i32 %2 to i64
  %3128 = mul i64 %1, %3127
  %3129 = and i64 %3128, %3126
  %3130 = xor i64 %3129, %3125
  store i64 %3130, ptr %4, align 8
  br label %2944

3131:                                             ; preds = %222
  %3132 = load i64, ptr %4, align 8
  %3133 = ptrtoint ptr %0 to i64
  %3134 = zext i32 %2 to i64
  %3135 = sub i64 %3133, %3132
  %3136 = and i64 %3135, %3132
  %3137 = sub i64 %3136, %3133
  %3138 = sub i64 %3137, %3132
  %3139 = or i64 %3138, %1
  store i64 %3139, ptr %4, align 8
  br label %2944

3140:                                             ; preds = %231
  %3141 = load i64, ptr %4, align 8
  %3142 = ptrtoint ptr %0 to i64
  %3143 = zext i32 %2 to i64
  %3144 = or i64 %3141, %3142
  %3145 = sub i64 %3144, %1
  %3146 = mul i64 %3145, %3143
  %3147 = or i64 %3146, %3141
  store i64 %3147, ptr %4, align 8
  br label %2944

3148:                                             ; preds = %254
  %3149 = load i64, ptr %4, align 8
  %3150 = ptrtoint ptr %0 to i64
  %3151 = zext i32 %2 to i64
  %3152 = mul i64 %3149, %3149
  %3153 = or i64 %3152, %3149
  %3154 = mul i64 %3153, %3149
  %3155 = or i64 %3154, %3149
  %3156 = xor i64 %3155, %1
  %3157 = and i64 %3156, %1
  store i64 %3157, ptr %4, align 8
  br label %2944

3158:                                             ; preds = %268
  %3159 = load i64, ptr %4, align 8
  %3160 = ptrtoint ptr %0 to i64
  %3161 = zext i32 %2 to i64
  %3162 = xor i64 %1, %3159
  %3163 = mul i64 %3162, %1
  %3164 = and i64 %3163, %1
  %3165 = xor i64 %3164, %3160
  %3166 = or i64 %3165, %3161
  %3167 = sub i64 %3166, %3160
  store i64 %3167, ptr %4, align 8
  br label %2944

3168:                                             ; preds = %289
  %3169 = load i64, ptr %4, align 8
  %3170 = ptrtoint ptr %0 to i64
  %3171 = zext i32 %2 to i64
  %3172 = or i64 %1, %3170
  %3173 = xor i64 %3172, %3170
  %3174 = and i64 %3173, %3169
  store i64 %3174, ptr %4, align 8
  br label %2944

3175:                                             ; preds = %311
  %3176 = load i64, ptr %4, align 8
  %3177 = ptrtoint ptr %0 to i64
  %3178 = zext i32 %2 to i64
  %3179 = add i64 %3176, %3177
  %3180 = or i64 %3179, %3178
  %3181 = or i64 %3180, %3177
  %3182 = and i64 %3181, %3176
  %3183 = and i64 %3182, %3177
  store i64 %3183, ptr %4, align 8
  br label %2944

3184:                                             ; preds = %322
  %3185 = load i64, ptr %4, align 8
  %3186 = ptrtoint ptr %0 to i64
  %3187 = zext i32 %2 to i64
  %3188 = sub i64 %3186, %3185
  %3189 = add i64 %3188, %1
  %3190 = or i64 %3189, %1
  store i64 %3190, ptr %4, align 8
  br label %2944

3191:                                             ; preds = %337
  %3192 = load i64, ptr %4, align 8
  %3193 = ptrtoint ptr %0 to i64
  %3194 = zext i32 %2 to i64
  %3195 = mul i64 %3194, %3192
  %3196 = or i64 %3195, %3193
  %3197 = add i64 %3196, %3194
  %3198 = mul i64 %3197, %3193
  store i64 %3198, ptr %4, align 8
  br label %2944

3199:                                             ; preds = %468
  %3200 = load i64, ptr %4, align 8
  %3201 = ptrtoint ptr %0 to i64
  %3202 = zext i32 %2 to i64
  %3203 = xor i64 %3200, %3202
  %3204 = or i64 %3203, %3200
  %3205 = sub i64 %3204, %1
  %3206 = mul i64 %3205, %3201
  %3207 = or i64 %3206, %1
  store i64 %3207, ptr %4, align 8
  br label %2944

3208:                                             ; preds = %499
  %3209 = load i64, ptr %4, align 8
  %3210 = ptrtoint ptr %0 to i64
  %3211 = zext i32 %2 to i64
  %3212 = or i64 %1, %3210
  %3213 = xor i64 %3212, %3210
  %3214 = add i64 %3213, %1
  %3215 = and i64 %3214, %3209
  %3216 = and i64 %3215, %3211
  store i64 %3216, ptr %4, align 8
  br label %2944

3217:                                             ; preds = %527
  %3218 = load i64, ptr %4, align 8
  %3219 = ptrtoint ptr %0 to i64
  %3220 = zext i32 %2 to i64
  %3221 = add i64 %1, %3219
  %3222 = or i64 %3221, %1
  %3223 = mul i64 %3222, %3220
  store i64 %3223, ptr %4, align 8
  br label %2944

3224:                                             ; preds = %570
  %3225 = load i64, ptr %4, align 8
  %3226 = ptrtoint ptr %0 to i64
  %3227 = zext i32 %2 to i64
  %3228 = and i64 %3226, %1
  %3229 = or i64 %3228, %1
  %3230 = xor i64 %3229, %3226
  store i64 %3230, ptr %4, align 8
  br label %2944

3231:                                             ; preds = %597
  %3232 = load i64, ptr %4, align 8
  %3233 = ptrtoint ptr %0 to i64
  %3234 = zext i32 %2 to i64
  %3235 = mul i64 %1, %3233
  %3236 = mul i64 %3235, %1
  %3237 = or i64 %3236, %3232
  %3238 = mul i64 %3237, %3232
  %3239 = xor i64 %3238, %3232
  %3240 = sub i64 %3239, %3232
  store i64 %3240, ptr %4, align 8
  br label %2944

3241:                                             ; preds = %637
  %3242 = load i64, ptr %4, align 8
  %3243 = ptrtoint ptr %0 to i64
  %3244 = zext i32 %2 to i64
  %3245 = or i64 %3242, %3243
  %3246 = and i64 %3245, %3244
  %3247 = and i64 %3246, %3244
  store i64 %3247, ptr %4, align 8
  br label %2944

3248:                                             ; preds = %681
  %3249 = load i64, ptr %4, align 8
  %3250 = ptrtoint ptr %0 to i64
  %3251 = zext i32 %2 to i64
  %3252 = xor i64 %3249, %3249
  %3253 = sub i64 %3252, %3251
  %3254 = add i64 %3253, %3251
  %3255 = sub i64 %3254, %3251
  store i64 %3255, ptr %4, align 8
  br label %2944

3256:                                             ; preds = %721
  %3257 = load i64, ptr %4, align 8
  %3258 = ptrtoint ptr %0 to i64
  %3259 = zext i32 %2 to i64
  %3260 = and i64 %3259, %3258
  %3261 = or i64 %3260, %3259
  %3262 = and i64 %3261, %3259
  %3263 = or i64 %3262, %3257
  %3264 = xor i64 %3263, %1
  store i64 %3264, ptr %4, align 8
  br label %2944

3265:                                             ; preds = %731
  %3266 = load i64, ptr %4, align 8
  %3267 = ptrtoint ptr %0 to i64
  %3268 = zext i32 %2 to i64
  %3269 = mul i64 %3268, %3267
  %3270 = sub i64 %3269, %1
  %3271 = and i64 %3270, %1
  %3272 = add i64 %3271, %3267
  %3273 = sub i64 %3272, %1
  store i64 %3273, ptr %4, align 8
  br label %2944

3274:                                             ; preds = %746
  %3275 = load i64, ptr %4, align 8
  %3276 = ptrtoint ptr %0 to i64
  %3277 = zext i32 %2 to i64
  %3278 = mul i64 %1, %1
  %3279 = mul i64 %3278, %3275
  %3280 = add i64 %3279, %1
  store i64 %3280, ptr %4, align 8
  br label %2944

3281:                                             ; preds = %774
  %3282 = load i64, ptr %4, align 8
  %3283 = ptrtoint ptr %0 to i64
  %3284 = zext i32 %2 to i64
  %3285 = sub i64 %1, %3284
  %3286 = xor i64 %3285, %3284
  %3287 = xor i64 %3286, %1
  %3288 = and i64 %3287, %3284
  store i64 %3288, ptr %4, align 8
  br label %2944

3289:                                             ; preds = %824
  %3290 = load i64, ptr %4, align 8
  %3291 = ptrtoint ptr %0 to i64
  %3292 = zext i32 %2 to i64
  %3293 = add i64 %3290, %3292
  %3294 = mul i64 %3293, %1
  %3295 = and i64 %3294, %3292
  %3296 = or i64 %3295, %3290
  %3297 = sub i64 %3296, %3292
  store i64 %3297, ptr %4, align 8
  br label %2944

3298:                                             ; preds = %835
  %3299 = load i64, ptr %4, align 8
  %3300 = ptrtoint ptr %0 to i64
  %3301 = zext i32 %2 to i64
  %3302 = or i64 %1, %3301
  %3303 = sub i64 %3302, %3301
  %3304 = add i64 %3303, %3299
  %3305 = add i64 %3304, %3300
  %3306 = sub i64 %3305, %3299
  store i64 %3306, ptr %4, align 8
  br label %2944

3307:                                             ; preds = %846
  %3308 = load i64, ptr %4, align 8
  %3309 = ptrtoint ptr %0 to i64
  %3310 = zext i32 %2 to i64
  %3311 = xor i64 %3308, %1
  %3312 = mul i64 %3311, %3308
  %3313 = sub i64 %3312, %3310
  %3314 = add i64 %3313, %3309
  %3315 = add i64 %3314, %3308
  %3316 = add i64 %3315, %3309
  store i64 %3316, ptr %4, align 8
  br label %2944

3317:                                             ; preds = %855
  %3318 = load i64, ptr %4, align 8
  %3319 = ptrtoint ptr %0 to i64
  %3320 = zext i32 %2 to i64
  %3321 = xor i64 %3318, %3318
  %3322 = or i64 %3321, %1
  %3323 = and i64 %3322, %3320
  store i64 %3323, ptr %4, align 8
  br label %2944

3324:                                             ; preds = %914
  %3325 = load i64, ptr %4, align 8
  %3326 = ptrtoint ptr %0 to i64
  %3327 = zext i32 %2 to i64
  %3328 = sub i64 %3327, %3325
  %3329 = sub i64 %3328, %1
  %3330 = sub i64 %3329, %1
  store i64 %3330, ptr %4, align 8
  br label %2944

3331:                                             ; preds = %935
  %3332 = load i64, ptr %4, align 8
  %3333 = ptrtoint ptr %0 to i64
  %3334 = zext i32 %2 to i64
  %3335 = xor i64 %3332, %3332
  %3336 = or i64 %3335, %1
  %3337 = mul i64 %3336, %1
  %3338 = add i64 %3337, %3333
  %3339 = xor i64 %3338, %1
  store i64 %3339, ptr %4, align 8
  br label %2944

3340:                                             ; preds = %957
  %3341 = load i64, ptr %4, align 8
  %3342 = ptrtoint ptr %0 to i64
  %3343 = zext i32 %2 to i64
  %3344 = or i64 %1, %3341
  %3345 = xor i64 %3344, %3343
  %3346 = sub i64 %3345, %3343
  %3347 = or i64 %3346, %3342
  store i64 %3347, ptr %4, align 8
  br label %2944

3348:                                             ; preds = %992
  %3349 = load i64, ptr %4, align 8
  %3350 = ptrtoint ptr %0 to i64
  %3351 = zext i32 %2 to i64
  %3352 = sub i64 %3350, %3349
  %3353 = mul i64 %3352, %3349
  %3354 = or i64 %3353, %3351
  %3355 = or i64 %3354, %3351
  %3356 = sub i64 %3355, %1
  store i64 %3356, ptr %4, align 8
  br label %2944

3357:                                             ; preds = %1022
  %3358 = load i64, ptr %4, align 8
  %3359 = ptrtoint ptr %0 to i64
  %3360 = zext i32 %2 to i64
  %3361 = add i64 %1, %3360
  %3362 = or i64 %3361, %3360
  %3363 = sub i64 %3362, %3359
  %3364 = mul i64 %3363, %1
  store i64 %3364, ptr %4, align 8
  br label %2944

3365:                                             ; preds = %1118
  %3366 = load i64, ptr %4, align 8
  %3367 = ptrtoint ptr %0 to i64
  %3368 = zext i32 %2 to i64
  %3369 = or i64 %3367, %3366
  %3370 = or i64 %3369, %3367
  %3371 = xor i64 %3370, %3368
  %3372 = sub i64 %3371, %3366
  store i64 %3372, ptr %4, align 8
  br label %2944

3373:                                             ; preds = %1209
  %3374 = load i64, ptr %4, align 8
  %3375 = ptrtoint ptr %0 to i64
  %3376 = zext i32 %2 to i64
  %3377 = mul i64 %1, %1
  %3378 = add i64 %3377, %3376
  %3379 = and i64 %3378, %3375
  store i64 %3379, ptr %4, align 8
  br label %2944

3380:                                             ; preds = %1239
  %3381 = load i64, ptr %4, align 8
  %3382 = ptrtoint ptr %0 to i64
  %3383 = zext i32 %2 to i64
  %3384 = or i64 %3383, %1
  %3385 = or i64 %3384, %1
  %3386 = or i64 %3385, %3381
  %3387 = and i64 %3386, %3381
  %3388 = mul i64 %3387, %3381
  %3389 = sub i64 %3388, %3383
  store i64 %3389, ptr %4, align 8
  br label %2944

3390:                                             ; preds = %1255
  %3391 = load i64, ptr %4, align 8
  %3392 = ptrtoint ptr %0 to i64
  %3393 = zext i32 %2 to i64
  %3394 = and i64 %1, %3391
  %3395 = and i64 %3394, %3393
  %3396 = mul i64 %3395, %3391
  %3397 = sub i64 %3396, %1
  store i64 %3397, ptr %4, align 8
  br label %2944

3398:                                             ; preds = %1283
  %3399 = load i64, ptr %4, align 8
  %3400 = ptrtoint ptr %0 to i64
  %3401 = zext i32 %2 to i64
  %3402 = add i64 %3399, %3400
  %3403 = xor i64 %3402, %3399
  %3404 = mul i64 %3403, %3400
  %3405 = sub i64 %3404, %3401
  store i64 %3405, ptr %4, align 8
  br label %2944

3406:                                             ; preds = %1303
  %3407 = load i64, ptr %4, align 8
  %3408 = ptrtoint ptr %0 to i64
  %3409 = zext i32 %2 to i64
  %3410 = mul i64 %3407, %3409
  %3411 = add i64 %3410, %1
  %3412 = sub i64 %3411, %3407
  store i64 %3412, ptr %4, align 8
  br label %2944

3413:                                             ; preds = %1322
  %3414 = load i64, ptr %4, align 8
  %3415 = ptrtoint ptr %0 to i64
  %3416 = zext i32 %2 to i64
  %3417 = xor i64 %3414, %1
  %3418 = or i64 %3417, %3415
  %3419 = xor i64 %3418, %1
  %3420 = add i64 %3419, %3415
  %3421 = mul i64 %3420, %3416
  %3422 = or i64 %3421, %3414
  store i64 %3422, ptr %4, align 8
  br label %2944

3423:                                             ; preds = %1343
  %3424 = load i64, ptr %4, align 8
  %3425 = ptrtoint ptr %0 to i64
  %3426 = zext i32 %2 to i64
  %3427 = sub i64 %3426, %3424
  %3428 = or i64 %3427, %3426
  %3429 = and i64 %3428, %3424
  %3430 = add i64 %3429, %1
  store i64 %3430, ptr %4, align 8
  br label %2944

3431:                                             ; preds = %1362
  %3432 = load i64, ptr %4, align 8
  %3433 = ptrtoint ptr %0 to i64
  %3434 = zext i32 %2 to i64
  %3435 = sub i64 %1, %3434
  %3436 = add i64 %3435, %3432
  %3437 = or i64 %3436, %1
  %3438 = mul i64 %3437, %3434
  %3439 = mul i64 %3438, %3433
  %3440 = and i64 %3439, %3432
  store i64 %3440, ptr %4, align 8
  br label %2944

3441:                                             ; preds = %1410
  %3442 = load i64, ptr %4, align 8
  %3443 = ptrtoint ptr %0 to i64
  %3444 = zext i32 %2 to i64
  %3445 = xor i64 %3443, %3443
  %3446 = sub i64 %3445, %3443
  %3447 = sub i64 %3446, %3443
  %3448 = mul i64 %3447, %1
  store i64 %3448, ptr %4, align 8
  br label %2944

3449:                                             ; preds = %1426
  %3450 = load i64, ptr %4, align 8
  %3451 = ptrtoint ptr %0 to i64
  %3452 = zext i32 %2 to i64
  %3453 = sub i64 %3450, %3452
  %3454 = or i64 %3453, %3450
  %3455 = sub i64 %3454, %3452
  %3456 = add i64 %3455, %3452
  %3457 = mul i64 %3456, %3451
  store i64 %3457, ptr %4, align 8
  br label %2944

3458:                                             ; preds = %1487
  %3459 = load i64, ptr %4, align 8
  %3460 = ptrtoint ptr %0 to i64
  %3461 = zext i32 %2 to i64
  %3462 = xor i64 %3459, %3459
  %3463 = and i64 %3462, %3460
  %3464 = mul i64 %3463, %3459
  %3465 = or i64 %3464, %3461
  %3466 = add i64 %3465, %3461
  store i64 %3466, ptr %4, align 8
  br label %2944

3467:                                             ; preds = %1518
  %3468 = load i64, ptr %4, align 8
  %3469 = ptrtoint ptr %0 to i64
  %3470 = zext i32 %2 to i64
  %3471 = and i64 %1, %3470
  %3472 = xor i64 %3471, %3470
  %3473 = add i64 %3472, %3469
  %3474 = mul i64 %3473, %3468
  store i64 %3474, ptr %4, align 8
  br label %2944

3475:                                             ; preds = %1542
  %3476 = load i64, ptr %4, align 8
  %3477 = ptrtoint ptr %0 to i64
  %3478 = zext i32 %2 to i64
  %3479 = or i64 %3476, %1
  %3480 = mul i64 %3479, %3478
  %3481 = xor i64 %3480, %3476
  %3482 = add i64 %3481, %1
  store i64 %3482, ptr %4, align 8
  br label %2944

3483:                                             ; preds = %1558
  %3484 = load i64, ptr %4, align 8
  %3485 = ptrtoint ptr %0 to i64
  %3486 = zext i32 %2 to i64
  %3487 = add i64 %3486, %3485
  %3488 = or i64 %3487, %3486
  %3489 = add i64 %3488, %3486
  %3490 = sub i64 %3489, %3484
  %3491 = mul i64 %3490, %3485
  %3492 = or i64 %3491, %3486
  store i64 %3492, ptr %4, align 8
  br label %2944

3493:                                             ; preds = %1578
  %3494 = load i64, ptr %4, align 8
  %3495 = ptrtoint ptr %0 to i64
  %3496 = zext i32 %2 to i64
  %3497 = add i64 %3496, %3496
  %3498 = mul i64 %3497, %1
  %3499 = add i64 %3498, %3494
  %3500 = mul i64 %3499, %3495
  %3501 = xor i64 %3500, %1
  %3502 = or i64 %3501, %1
  store i64 %3502, ptr %4, align 8
  br label %2944

3503:                                             ; preds = %1588
  %3504 = load i64, ptr %4, align 8
  %3505 = ptrtoint ptr %0 to i64
  %3506 = zext i32 %2 to i64
  %3507 = and i64 %3506, %1
  %3508 = and i64 %3507, %3504
  %3509 = mul i64 %3508, %3504
  %3510 = sub i64 %3509, %3506
  %3511 = and i64 %3510, %3506
  store i64 %3511, ptr %4, align 8
  br label %2944

3512:                                             ; preds = %1600
  %3513 = load i64, ptr %4, align 8
  %3514 = ptrtoint ptr %0 to i64
  %3515 = zext i32 %2 to i64
  %3516 = mul i64 %3515, %3513
  %3517 = sub i64 %3516, %3515
  %3518 = sub i64 %3517, %1
  %3519 = mul i64 %3518, %3515
  %3520 = and i64 %3519, %3513
  store i64 %3520, ptr %4, align 8
  br label %2944

3521:                                             ; preds = %1645
  %3522 = load i64, ptr %4, align 8
  %3523 = ptrtoint ptr %0 to i64
  %3524 = zext i32 %2 to i64
  %3525 = add i64 %3522, %3522
  %3526 = add i64 %3525, %1
  %3527 = or i64 %3526, %1
  %3528 = xor i64 %3527, %3524
  store i64 %3528, ptr %4, align 8
  br label %2944

3529:                                             ; preds = %1656
  %3530 = load i64, ptr %4, align 8
  %3531 = ptrtoint ptr %0 to i64
  %3532 = zext i32 %2 to i64
  %3533 = xor i64 %1, %3530
  %3534 = mul i64 %3533, %3531
  %3535 = or i64 %3534, %3530
  %3536 = xor i64 %3535, %3532
  %3537 = or i64 %3536, %3530
  %3538 = or i64 %3537, %3532
  store i64 %3538, ptr %4, align 8
  br label %2944

3539:                                             ; preds = %1670
  %3540 = load i64, ptr %4, align 8
  %3541 = ptrtoint ptr %0 to i64
  %3542 = zext i32 %2 to i64
  %3543 = or i64 %1, %3542
  %3544 = sub i64 %3543, %3540
  %3545 = or i64 %3544, %3541
  %3546 = add i64 %3545, %1
  store i64 %3546, ptr %4, align 8
  br label %2944

3547:                                             ; preds = %1716
  %3548 = load i64, ptr %4, align 8
  %3549 = ptrtoint ptr %0 to i64
  %3550 = zext i32 %2 to i64
  %3551 = add i64 %3549, %1
  %3552 = add i64 %3551, %3548
  %3553 = add i64 %3552, %3548
  store i64 %3553, ptr %4, align 8
  br label %2944

3554:                                             ; preds = %1736
  %3555 = load i64, ptr %4, align 8
  %3556 = ptrtoint ptr %0 to i64
  %3557 = zext i32 %2 to i64
  %3558 = and i64 %3556, %3556
  %3559 = or i64 %3558, %1
  %3560 = add i64 %3559, %3555
  %3561 = or i64 %3560, %3556
  %3562 = xor i64 %3561, %3556
  store i64 %3562, ptr %4, align 8
  br label %2944

3563:                                             ; preds = %1765
  %3564 = load i64, ptr %4, align 8
  %3565 = ptrtoint ptr %0 to i64
  %3566 = zext i32 %2 to i64
  %3567 = xor i64 %3564, %3564
  %3568 = and i64 %3567, %3565
  %3569 = and i64 %3568, %3565
  %3570 = xor i64 %3569, %3565
  store i64 %3570, ptr %4, align 8
  br label %2944

3571:                                             ; preds = %1785
  %3572 = load i64, ptr %4, align 8
  %3573 = ptrtoint ptr %0 to i64
  %3574 = zext i32 %2 to i64
  %3575 = sub i64 %3573, %3573
  %3576 = mul i64 %3575, %1
  %3577 = add i64 %3576, %1
  %3578 = mul i64 %3577, %3574
  %3579 = and i64 %3578, %3572
  store i64 %3579, ptr %4, align 8
  br label %2944

3580:                                             ; preds = %1817
  %3581 = load i64, ptr %4, align 8
  %3582 = ptrtoint ptr %0 to i64
  %3583 = zext i32 %2 to i64
  %3584 = mul i64 %3583, %3582
  %3585 = sub i64 %3584, %3583
  %3586 = add i64 %3585, %3582
  store i64 %3586, ptr %4, align 8
  br label %2944

3587:                                             ; preds = %1826
  %3588 = load i64, ptr %4, align 8
  %3589 = ptrtoint ptr %0 to i64
  %3590 = zext i32 %2 to i64
  %3591 = sub i64 %3589, %3588
  %3592 = mul i64 %3591, %3588
  %3593 = add i64 %3592, %3589
  %3594 = sub i64 %3593, %3590
  store i64 %3594, ptr %4, align 8
  br label %2944

3595:                                             ; preds = %1862
  %3596 = load i64, ptr %4, align 8
  %3597 = ptrtoint ptr %0 to i64
  %3598 = zext i32 %2 to i64
  %3599 = mul i64 %1, %3596
  %3600 = add i64 %3599, %1
  %3601 = mul i64 %3600, %3597
  %3602 = or i64 %3601, %1
  %3603 = mul i64 %3602, %3598
  %3604 = sub i64 %3603, %1
  store i64 %3604, ptr %4, align 8
  br label %2944

3605:                                             ; preds = %1873
  %3606 = load i64, ptr %4, align 8
  %3607 = ptrtoint ptr %0 to i64
  %3608 = zext i32 %2 to i64
  %3609 = or i64 %1, %1
  %3610 = mul i64 %3609, %3608
  %3611 = and i64 %3610, %3606
  %3612 = mul i64 %3611, %1
  %3613 = or i64 %3612, %3606
  store i64 %3613, ptr %4, align 8
  br label %2944

3614:                                             ; preds = %1925
  %3615 = load i64, ptr %4, align 8
  %3616 = ptrtoint ptr %0 to i64
  %3617 = zext i32 %2 to i64
  %3618 = sub i64 %1, %1
  %3619 = add i64 %3618, %3617
  %3620 = xor i64 %3619, %3616
  store i64 %3620, ptr %4, align 8
  br label %2944

3621:                                             ; preds = %1944
  %3622 = load i64, ptr %4, align 8
  %3623 = ptrtoint ptr %0 to i64
  %3624 = zext i32 %2 to i64
  %3625 = add i64 %3623, %1
  %3626 = add i64 %3625, %3622
  %3627 = mul i64 %3626, %1
  %3628 = sub i64 %3627, %3623
  %3629 = mul i64 %3628, %3622
  store i64 %3629, ptr %4, align 8
  br label %2944

3630:                                             ; preds = %1961
  %3631 = load i64, ptr %4, align 8
  %3632 = ptrtoint ptr %0 to i64
  %3633 = zext i32 %2 to i64
  %3634 = xor i64 %3632, %3633
  %3635 = or i64 %3634, %3632
  %3636 = sub i64 %3635, %3632
  store i64 %3636, ptr %4, align 8
  br label %2944

3637:                                             ; preds = %1998
  %3638 = load i64, ptr %4, align 8
  %3639 = ptrtoint ptr %0 to i64
  %3640 = zext i32 %2 to i64
  %3641 = and i64 %3639, %1
  %3642 = add i64 %3641, %1
  %3643 = xor i64 %3642, %3640
  store i64 %3643, ptr %4, align 8
  br label %2944

3644:                                             ; preds = %2018
  %3645 = load i64, ptr %4, align 8
  %3646 = ptrtoint ptr %0 to i64
  %3647 = zext i32 %2 to i64
  %3648 = xor i64 %1, %3646
  %3649 = mul i64 %3648, %3647
  %3650 = sub i64 %3649, %1
  %3651 = sub i64 %3650, %3645
  %3652 = or i64 %3651, %3646
  %3653 = and i64 %3652, %1
  store i64 %3653, ptr %4, align 8
  br label %2944

3654:                                             ; preds = %2032
  %3655 = load i64, ptr %4, align 8
  %3656 = ptrtoint ptr %0 to i64
  %3657 = zext i32 %2 to i64
  %3658 = xor i64 %3656, %3656
  %3659 = or i64 %3658, %3655
  %3660 = sub i64 %3659, %3657
  %3661 = and i64 %3660, %3655
  %3662 = or i64 %3661, %1
  %3663 = mul i64 %3662, %3656
  store i64 %3663, ptr %4, align 8
  br label %2944

3664:                                             ; preds = %2054
  %3665 = load i64, ptr %4, align 8
  %3666 = ptrtoint ptr %0 to i64
  %3667 = zext i32 %2 to i64
  %3668 = xor i64 %3665, %1
  %3669 = and i64 %3668, %3666
  %3670 = add i64 %3669, %3667
  %3671 = add i64 %3670, %1
  store i64 %3671, ptr %4, align 8
  br label %2944

3672:                                             ; preds = %2084
  %3673 = load i64, ptr %4, align 8
  %3674 = ptrtoint ptr %0 to i64
  %3675 = zext i32 %2 to i64
  %3676 = add i64 %3674, %1
  %3677 = sub i64 %3676, %3675
  %3678 = or i64 %3677, %3675
  %3679 = sub i64 %3678, %3674
  store i64 %3679, ptr %4, align 8
  br label %2944

3680:                                             ; preds = %2128
  %3681 = load i64, ptr %4, align 8
  %3682 = ptrtoint ptr %0 to i64
  %3683 = zext i32 %2 to i64
  %3684 = and i64 %1, %1
  %3685 = mul i64 %3684, %1
  %3686 = xor i64 %3685, %3683
  %3687 = or i64 %3686, %3683
  %3688 = add i64 %3687, %3681
  store i64 %3688, ptr %4, align 8
  br label %2944

3689:                                             ; preds = %2137
  %3690 = load i64, ptr %4, align 8
  %3691 = ptrtoint ptr %0 to i64
  %3692 = zext i32 %2 to i64
  %3693 = xor i64 %1, %3690
  %3694 = mul i64 %3693, %1
  %3695 = sub i64 %3694, %3691
  %3696 = add i64 %3695, %3692
  %3697 = add i64 %3696, %3691
  store i64 %3697, ptr %4, align 8
  br label %2944

3698:                                             ; preds = %2151
  %3699 = load i64, ptr %4, align 8
  %3700 = ptrtoint ptr %0 to i64
  %3701 = zext i32 %2 to i64
  %3702 = and i64 %3701, %3699
  %3703 = or i64 %3702, %3700
  %3704 = add i64 %3703, %3699
  %3705 = and i64 %3704, %3701
  %3706 = add i64 %3705, %3699
  %3707 = mul i64 %3706, %3700
  store i64 %3707, ptr %4, align 8
  br label %2944

3708:                                             ; preds = %2171
  %3709 = load i64, ptr %4, align 8
  %3710 = ptrtoint ptr %0 to i64
  %3711 = zext i32 %2 to i64
  %3712 = sub i64 %3711, %3711
  %3713 = or i64 %3712, %1
  %3714 = or i64 %3713, %3710
  store i64 %3714, ptr %4, align 8
  br label %2944

3715:                                             ; preds = %2185
  %3716 = load i64, ptr %4, align 8
  %3717 = ptrtoint ptr %0 to i64
  %3718 = zext i32 %2 to i64
  %3719 = or i64 %3717, %3716
  %3720 = or i64 %3719, %3717
  %3721 = mul i64 %3720, %3718
  store i64 %3721, ptr %4, align 8
  br label %2944

3722:                                             ; preds = %2196
  %3723 = load i64, ptr %4, align 8
  %3724 = ptrtoint ptr %0 to i64
  %3725 = zext i32 %2 to i64
  %3726 = add i64 %3723, %1
  %3727 = and i64 %3726, %3725
  %3728 = and i64 %3727, %3724
  %3729 = add i64 %3728, %3725
  %3730 = xor i64 %3729, %3724
  %3731 = add i64 %3730, %3723
  store i64 %3731, ptr %4, align 8
  br label %2944

3732:                                             ; preds = %2209
  %3733 = load i64, ptr %4, align 8
  %3734 = ptrtoint ptr %0 to i64
  %3735 = zext i32 %2 to i64
  %3736 = or i64 %3733, %3735
  %3737 = sub i64 %3736, %3735
  %3738 = sub i64 %3737, %1
  store i64 %3738, ptr %4, align 8
  br label %2944

3739:                                             ; preds = %2258
  %3740 = load i64, ptr %4, align 8
  %3741 = ptrtoint ptr %0 to i64
  %3742 = zext i32 %2 to i64
  %3743 = xor i64 %1, %3740
  %3744 = or i64 %3743, %3740
  %3745 = and i64 %3744, %3740
  %3746 = and i64 %3745, %3742
  store i64 %3746, ptr %4, align 8
  br label %2944

3747:                                             ; preds = %2279
  %3748 = load i64, ptr %4, align 8
  %3749 = ptrtoint ptr %0 to i64
  %3750 = zext i32 %2 to i64
  %3751 = mul i64 %3749, %1
  %3752 = mul i64 %3751, %3748
  %3753 = or i64 %3752, %1
  %3754 = sub i64 %3753, %1
  %3755 = and i64 %3754, %1
  %3756 = and i64 %3755, %3749
  store i64 %3756, ptr %4, align 8
  br label %2944

3757:                                             ; preds = %2301
  %3758 = load i64, ptr %4, align 8
  %3759 = ptrtoint ptr %0 to i64
  %3760 = zext i32 %2 to i64
  %3761 = xor i64 %3758, %1
  %3762 = mul i64 %3761, %1
  %3763 = and i64 %3762, %3758
  %3764 = add i64 %3763, %3760
  %3765 = add i64 %3764, %1
  %3766 = sub i64 %3765, %3759
  store i64 %3766, ptr %4, align 8
  br label %2944

3767:                                             ; preds = %2320
  %3768 = load i64, ptr %4, align 8
  %3769 = ptrtoint ptr %0 to i64
  %3770 = zext i32 %2 to i64
  %3771 = xor i64 %1, %3770
  %3772 = and i64 %3771, %3768
  %3773 = xor i64 %3772, %3769
  %3774 = mul i64 %3773, %1
  %3775 = and i64 %3774, %3769
  %3776 = sub i64 %3775, %1
  store i64 %3776, ptr %4, align 8
  br label %2944

3777:                                             ; preds = %2345
  %3778 = load i64, ptr %4, align 8
  %3779 = ptrtoint ptr %0 to i64
  %3780 = zext i32 %2 to i64
  %3781 = xor i64 %3779, %3779
  %3782 = mul i64 %3781, %3780
  %3783 = mul i64 %3782, %1
  %3784 = and i64 %3783, %3779
  %3785 = or i64 %3784, %3780
  store i64 %3785, ptr %4, align 8
  br label %2944

3786:                                             ; preds = %2356
  %3787 = load i64, ptr %4, align 8
  %3788 = ptrtoint ptr %0 to i64
  %3789 = zext i32 %2 to i64
  %3790 = or i64 %3789, %3787
  %3791 = or i64 %3790, %1
  %3792 = sub i64 %3791, %3787
  %3793 = add i64 %3792, %3789
  store i64 %3793, ptr %4, align 8
  br label %2944

3794:                                             ; preds = %2370
  %3795 = load i64, ptr %4, align 8
  %3796 = ptrtoint ptr %0 to i64
  %3797 = zext i32 %2 to i64
  %3798 = add i64 %3796, %3795
  %3799 = add i64 %3798, %3795
  %3800 = sub i64 %3799, %3795
  %3801 = xor i64 %3800, %3797
  store i64 %3801, ptr %4, align 8
  br label %2944

3802:                                             ; preds = %2394
  %3803 = load i64, ptr %4, align 8
  %3804 = ptrtoint ptr %0 to i64
  %3805 = zext i32 %2 to i64
  %3806 = or i64 %3803, %3803
  %3807 = sub i64 %3806, %3804
  %3808 = sub i64 %3807, %3805
  %3809 = mul i64 %3808, %3803
  store i64 %3809, ptr %4, align 8
  br label %2944

3810:                                             ; preds = %2418
  %3811 = load i64, ptr %4, align 8
  %3812 = ptrtoint ptr %0 to i64
  %3813 = zext i32 %2 to i64
  %3814 = add i64 %3812, %3811
  %3815 = add i64 %3814, %3813
  %3816 = xor i64 %3815, %3812
  %3817 = sub i64 %3816, %3811
  store i64 %3817, ptr %4, align 8
  br label %2944

3818:                                             ; preds = %2438
  %3819 = load i64, ptr %4, align 8
  %3820 = ptrtoint ptr %0 to i64
  %3821 = zext i32 %2 to i64
  %3822 = and i64 %3821, %1
  %3823 = mul i64 %3822, %3821
  %3824 = or i64 %3823, %3820
  store i64 %3824, ptr %4, align 8
  br label %2944

3825:                                             ; preds = %2464
  %3826 = load i64, ptr %4, align 8
  %3827 = ptrtoint ptr %0 to i64
  %3828 = zext i32 %2 to i64
  %3829 = or i64 %3828, %3828
  %3830 = add i64 %3829, %1
  %3831 = or i64 %3830, %3826
  store i64 %3831, ptr %4, align 8
  br label %2944

3832:                                             ; preds = %2505
  %3833 = load i64, ptr %4, align 8
  %3834 = ptrtoint ptr %0 to i64
  %3835 = zext i32 %2 to i64
  %3836 = or i64 %1, %3834
  %3837 = or i64 %3836, %3835
  %3838 = mul i64 %3837, %3833
  %3839 = xor i64 %3838, %3833
  store i64 %3839, ptr %4, align 8
  br label %2944

3840:                                             ; preds = %2516
  %3841 = load i64, ptr %4, align 8
  %3842 = ptrtoint ptr %0 to i64
  %3843 = zext i32 %2 to i64
  %3844 = and i64 %3843, %3842
  %3845 = add i64 %3844, %3843
  %3846 = mul i64 %3845, %3842
  %3847 = sub i64 %3846, %3843
  %3848 = add i64 %3847, %1
  %3849 = sub i64 %3848, %3842
  store i64 %3849, ptr %4, align 8
  br label %2944

3850:                                             ; preds = %2536
  %3851 = load i64, ptr %4, align 8
  %3852 = ptrtoint ptr %0 to i64
  %3853 = zext i32 %2 to i64
  %3854 = mul i64 %3852, %3852
  %3855 = add i64 %3854, %3851
  %3856 = mul i64 %3855, %1
  %3857 = or i64 %3856, %3853
  store i64 %3857, ptr %4, align 8
  br label %2944

3858:                                             ; preds = %2548
  %3859 = load i64, ptr %4, align 8
  %3860 = ptrtoint ptr %0 to i64
  %3861 = zext i32 %2 to i64
  %3862 = mul i64 %1, %3861
  %3863 = sub i64 %3862, %3860
  %3864 = xor i64 %3863, %1
  %3865 = add i64 %3864, %1
  %3866 = sub i64 %3865, %3861
  %3867 = xor i64 %3866, %3861
  store i64 %3867, ptr %4, align 8
  br label %2944

3868:                                             ; preds = %2569
  %3869 = load i64, ptr %4, align 8
  %3870 = ptrtoint ptr %0 to i64
  %3871 = zext i32 %2 to i64
  %3872 = or i64 %3869, %3871
  %3873 = sub i64 %3872, %1
  %3874 = sub i64 %3873, %3870
  store i64 %3874, ptr %4, align 8
  br label %2944

3875:                                             ; preds = %2583
  %3876 = load i64, ptr %4, align 8
  %3877 = ptrtoint ptr %0 to i64
  %3878 = zext i32 %2 to i64
  %3879 = add i64 %3877, %1
  %3880 = or i64 %3879, %3878
  %3881 = add i64 %3880, %3877
  store i64 %3881, ptr %4, align 8
  br label %2944

3882:                                             ; preds = %2603
  %3883 = load i64, ptr %4, align 8
  %3884 = ptrtoint ptr %0 to i64
  %3885 = zext i32 %2 to i64
  %3886 = add i64 %3883, %3883
  %3887 = add i64 %3886, %3884
  %3888 = and i64 %3887, %3883
  store i64 %3888, ptr %4, align 8
  br label %2944

3889:                                             ; preds = %2627
  %3890 = load i64, ptr %4, align 8
  %3891 = ptrtoint ptr %0 to i64
  %3892 = zext i32 %2 to i64
  %3893 = mul i64 %3892, %3891
  %3894 = and i64 %3893, %3891
  %3895 = add i64 %3894, %3892
  %3896 = or i64 %3895, %3890
  store i64 %3896, ptr %4, align 8
  br label %2944

3897:                                             ; preds = %2646
  %3898 = load i64, ptr %4, align 8
  %3899 = ptrtoint ptr %0 to i64
  %3900 = zext i32 %2 to i64
  %3901 = xor i64 %3898, %1
  %3902 = sub i64 %3901, %3900
  %3903 = xor i64 %3902, %3898
  store i64 %3903, ptr %4, align 8
  br label %2944

3904:                                             ; preds = %2668
  %3905 = load i64, ptr %4, align 8
  %3906 = ptrtoint ptr %0 to i64
  %3907 = zext i32 %2 to i64
  %3908 = and i64 %3906, %3907
  %3909 = or i64 %3908, %3906
  %3910 = xor i64 %3909, %3906
  %3911 = and i64 %3910, %1
  %3912 = mul i64 %3911, %3905
  store i64 %3912, ptr %4, align 8
  br label %2944

3913:                                             ; preds = %2714
  %3914 = load i64, ptr %4, align 8
  %3915 = ptrtoint ptr %0 to i64
  %3916 = zext i32 %2 to i64
  %3917 = xor i64 %3915, %3914
  %3918 = add i64 %3917, %3916
  %3919 = add i64 %3918, %3916
  %3920 = sub i64 %3919, %1
  store i64 %3920, ptr %4, align 8
  br label %2944

3921:                                             ; preds = %2736
  %3922 = load i64, ptr %4, align 8
  %3923 = ptrtoint ptr %0 to i64
  %3924 = zext i32 %2 to i64
  %3925 = sub i64 %3923, %3923
  %3926 = and i64 %3925, %1
  %3927 = and i64 %3926, %3924
  %3928 = or i64 %3927, %3922
  store i64 %3928, ptr %4, align 8
  br label %2944

3929:                                             ; preds = %2751
  %3930 = load i64, ptr %4, align 8
  %3931 = ptrtoint ptr %0 to i64
  %3932 = zext i32 %2 to i64
  %3933 = add i64 %1, %1
  %3934 = xor i64 %3933, %3931
  %3935 = xor i64 %3934, %3932
  %3936 = or i64 %3935, %3931
  %3937 = or i64 %3936, %3932
  %3938 = xor i64 %3937, %3932
  store i64 %3938, ptr %4, align 8
  br label %2944

3939:                                             ; preds = %2763
  %3940 = load i64, ptr %4, align 8
  %3941 = ptrtoint ptr %0 to i64
  %3942 = zext i32 %2 to i64
  %3943 = add i64 %3940, %1
  %3944 = or i64 %3943, %3940
  %3945 = add i64 %3944, %3940
  %3946 = and i64 %3945, %3942
  %3947 = or i64 %3946, %3942
  %3948 = or i64 %3947, %1
  store i64 %3948, ptr %4, align 8
  br label %2944

3949:                                             ; preds = %2776
  %3950 = load i64, ptr %4, align 8
  %3951 = ptrtoint ptr %0 to i64
  %3952 = zext i32 %2 to i64
  %3953 = mul i64 %3951, %3950
  %3954 = or i64 %3953, %1
  %3955 = sub i64 %3954, %3950
  %3956 = add i64 %3955, %1
  store i64 %3956, ptr %4, align 8
  br label %2944

3957:                                             ; preds = %2800
  %3958 = load i64, ptr %4, align 8
  %3959 = ptrtoint ptr %0 to i64
  %3960 = zext i32 %2 to i64
  %3961 = mul i64 %3960, %3958
  %3962 = xor i64 %3961, %3959
  %3963 = or i64 %3962, %3958
  %3964 = add i64 %3963, %3960
  store i64 %3964, ptr %4, align 8
  br label %2944

3965:                                             ; preds = %2810
  %3966 = load i64, ptr %4, align 8
  %3967 = ptrtoint ptr %0 to i64
  %3968 = zext i32 %2 to i64
  %3969 = and i64 %1, %3967
  %3970 = xor i64 %3969, %3966
  %3971 = mul i64 %3970, %1
  %3972 = sub i64 %3971, %3968
  %3973 = sub i64 %3972, %3968
  store i64 %3973, ptr %4, align 8
  br label %2944

3974:                                             ; preds = %2829
  %3975 = load i64, ptr %4, align 8
  %3976 = ptrtoint ptr %0 to i64
  %3977 = zext i32 %2 to i64
  %3978 = and i64 %3976, %3977
  %3979 = or i64 %3978, %3977
  %3980 = xor i64 %3979, %1
  store i64 %3980, ptr %4, align 8
  br label %2944

3981:                                             ; preds = %2843
  %3982 = load i64, ptr %4, align 8
  %3983 = ptrtoint ptr %0 to i64
  %3984 = zext i32 %2 to i64
  %3985 = and i64 %3983, %3984
  %3986 = xor i64 %3985, %3982
  %3987 = or i64 %3986, %3983
  %3988 = or i64 %3987, %1
  store i64 %3988, ptr %4, align 8
  br label %2944

3989:                                             ; preds = %2862
  %3990 = load i64, ptr %4, align 8
  %3991 = ptrtoint ptr %0 to i64
  %3992 = zext i32 %2 to i64
  %3993 = or i64 %1, %1
  %3994 = or i64 %3993, %1
  %3995 = xor i64 %3994, %3991
  %3996 = sub i64 %3995, %1
  %3997 = xor i64 %3996, %3990
  store i64 %3997, ptr %4, align 8
  br label %2944

3998:                                             ; preds = %2893
  %3999 = load i64, ptr %4, align 8
  %4000 = ptrtoint ptr %0 to i64
  %4001 = zext i32 %2 to i64
  %4002 = add i64 %3999, %3999
  %4003 = or i64 %4002, %1
  %4004 = or i64 %4003, %3999
  %4005 = add i64 %4004, %3999
  store i64 %4005, ptr %4, align 8
  br label %2944

4006:                                             ; preds = %2902
  %4007 = load i64, ptr %4, align 8
  %4008 = ptrtoint ptr %0 to i64
  %4009 = zext i32 %2 to i64
  %4010 = xor i64 %1, %4008
  %4011 = or i64 %4010, %1
  %4012 = and i64 %4011, %4009
  %4013 = or i64 %4012, %4007
  %4014 = sub i64 %4013, %4007
  %4015 = add i64 %4014, %1
  store i64 %4015, ptr %4, align 8
  br label %2944

4016:                                             ; preds = %2945
  %4017 = load i64, ptr %4, align 8
  %4018 = ptrtoint ptr %0 to i64
  %4019 = zext i32 %2 to i64
  %4020 = and i64 %1, %1
  %4021 = sub i64 %4020, %1
  %4022 = and i64 %4021, %4017
  %4023 = sub i64 %4022, %4017
  %4024 = or i64 %4023, %1
  store i64 %4024, ptr %4, align 8
  br label %32

4025:                                             ; preds = %2956
  %4026 = load i64, ptr %4, align 8
  %4027 = ptrtoint ptr %0 to i64
  %4028 = zext i32 %2 to i64
  %4029 = sub i64 %4026, %4027
  %4030 = or i64 %4029, %4027
  %4031 = sub i64 %4030, %4027
  store i64 %4031, ptr %4, align 8
  br label %2944

4032:                                             ; preds = %2969
  %4033 = load i64, ptr %4, align 8
  %4034 = ptrtoint ptr %0 to i64
  %4035 = zext i32 %2 to i64
  %4036 = xor i64 %4035, %4034
  %4037 = sub i64 %4036, %4033
  %4038 = sub i64 %4037, %4034
  %4039 = xor i64 %4038, %4034
  %4040 = add i64 %4039, %4033
  store i64 %4040, ptr %4, align 8
  br label %2944

4041:                                             ; preds = %2991
  %4042 = load i64, ptr %4, align 8
  %4043 = ptrtoint ptr %0 to i64
  %4044 = zext i32 %2 to i64
  %4045 = and i64 %4042, %4042
  %4046 = and i64 %4045, %4042
  %4047 = sub i64 %4046, %1
  %4048 = or i64 %4047, %1
  store i64 %4048, ptr %4, align 8
  br label %2944

4049:                                             ; preds = %3002
  %4050 = load i64, ptr %4, align 8
  %4051 = ptrtoint ptr %0 to i64
  %4052 = zext i32 %2 to i64
  %4053 = add i64 %4051, %1
  %4054 = add i64 %4053, %4050
  %4055 = sub i64 %4054, %1
  %4056 = xor i64 %4055, %1
  store i64 %4056, ptr %4, align 8
  br label %2944

4057:                                             ; preds = %3013
  %4058 = load i64, ptr %4, align 8
  %4059 = ptrtoint ptr %0 to i64
  %4060 = zext i32 %2 to i64
  %4061 = sub i64 %4059, %4060
  %4062 = xor i64 %4061, %4060
  %4063 = and i64 %4062, %4059
  %4064 = xor i64 %4063, %1
  store i64 %4064, ptr %4, align 8
  br label %2944

4065:                                             ; preds = %3026
  %4066 = load i64, ptr %4, align 8
  %4067 = ptrtoint ptr %0 to i64
  %4068 = zext i32 %2 to i64
  %4069 = and i64 %4067, %4067
  %4070 = add i64 %4069, %4066
  %4071 = or i64 %4070, %4068
  store i64 %4071, ptr %4, align 8
  br label %2944

4072:                                             ; preds = %3039
  %4073 = load i64, ptr %4, align 8
  %4074 = ptrtoint ptr %0 to i64
  %4075 = zext i32 %2 to i64
  %4076 = and i64 %4074, %4073
  %4077 = mul i64 %4076, %4075
  %4078 = mul i64 %4077, %1
  %4079 = mul i64 %4078, %4075
  %4080 = or i64 %4079, %4073
  store i64 %4080, ptr %4, align 8
  br label %2944

4081:                                             ; preds = %3052
  %4082 = load i64, ptr %4, align 8
  %4083 = ptrtoint ptr %0 to i64
  %4084 = zext i32 %2 to i64
  %4085 = and i64 %4082, %4082
  %4086 = xor i64 %4085, %4083
  %4087 = or i64 %4086, %1
  %4088 = and i64 %4087, %4082
  store i64 %4088, ptr %4, align 8
  br label %2944
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: nounwind
declare i32 @snprintf(ptr noundef, i64 noundef, ptr noundef, ...) #3

declare i32 @printf(ptr noundef, ...) #4

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #5

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @helper_mix(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 -513408172, ptr %4, align 4
  br label %9

9:                                                ; preds = %347, %151, %150, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, 1419086942
  %12 = mul i32 %11, 239435677
  %13 = icmp slt i32 %12, 1323610985
  br i1 %13, label %257, label %259

14:                                               ; preds = %277
  store i32 %0, ptr %5, align 4
  store i32 %1, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  store i32 804076511, ptr %4, align 4
  %15 = xor i32 %0, 1330694331
  %16 = and i32 %0, %15
  %17 = or i32 %0, %15
  %18 = xor i32 %0, %15
  %19 = add i32 %0, %15
  %20 = sub i32 %19, %18
  %21 = mul i32 %16, 2
  %22 = sub i32 %20, %21
  %23 = mul i32 %22, 87
  %24 = icmp sle i32 %23, 0
  br i1 %24, label %150, label %297

25:                                               ; preds = %287
  %26 = load i32, ptr %8, align 4
  %27 = icmp slt i32 %26, 8
  %28 = select i1 %27, i32 1826937800, i32 788558257
  store i32 %28, ptr %4, align 4
  %29 = xor i32 %0, 1948496405
  %30 = and i32 %0, %29
  %31 = or i32 %0, %29
  %32 = xor i32 %0, %29
  %33 = sub i32 %31, %32
  %34 = sub i32 %33, %30
  %35 = mul i32 %34, 251
  %36 = icmp ne i32 %35, 0
  br i1 %36, label %304, label %150

37:                                               ; preds = %293
  %38 = load i32, ptr %5, align 4
  %39 = load i32, ptr %8, align 4
  %40 = ashr i32 %38, %39
  %41 = load i32, ptr %4, align 4
  %42 = xor i32 %41, 1826937801
  %43 = add i32 %40, %42
  %44 = load i32, ptr %4, align 4
  %45 = xor i32 %44, 1826937801
  %46 = or i32 %40, %45
  %47 = sub i32 %43, %46
  %48 = icmp ne i32 %47, 0
  %49 = select i1 %48, i32 -1191538624, i32 -229796965
  store i32 %49, ptr %4, align 4
  %50 = xor i32 %0, -1447077383
  %51 = and i32 %0, %50
  %52 = or i32 %0, %50
  %53 = xor i32 %0, %50
  %54 = mul i32 %52, 2
  %55 = sub i32 %54, %53
  %56 = sub i32 %55, %0
  %57 = sub i32 %56, %50
  %58 = mul i32 %57, 106
  %59 = icmp slt i32 %58, 1
  br i1 %59, label %150, label %314

60:                                               ; preds = %269
  %61 = load i32, ptr %6, align 4
  %62 = load i32, ptr %8, align 4
  %63 = load i32, ptr %4, align 4
  %64 = xor i32 %63, -1191538607
  %65 = mul nsw i32 %62, %64
  %66 = add i32 %61, %65
  %67 = and i32 %61, %65
  %68 = load i32, ptr %4, align 4
  %69 = xor i32 %68, 1633175767
  %70 = mul i32 %66, %69
  %71 = load i32, ptr %4, align 4
  %72 = xor i32 %71, 1633175767
  %73 = mul i32 %67, %72
  %74 = add i32 %73, %73
  %75 = sub i32 %70, %74
  %76 = load i32, ptr %4, align 4
  %77 = xor i32 %76, -1134250137
  %78 = mul i32 %75, %77
  %79 = load i32, ptr %7, align 4
  %80 = or i32 %79, %78
  %81 = and i32 %79, %78
  %82 = add i32 %80, %81
  store i32 %82, ptr %7, align 4
  store i32 912573998, ptr %4, align 4
  %83 = xor i32 %0, -987429175
  %84 = and i32 %0, %83
  %85 = or i32 %0, %83
  %86 = xor i32 %0, %83
  %87 = add i32 %84, %85
  %88 = sub i32 %87, %0
  %89 = sub i32 %88, %83
  %90 = mul i32 %89, 105
  %91 = icmp eq i32 %90, 0
  br i1 %91, label %150, label %322

92:                                               ; preds = %283
  %93 = load i32, ptr %5, align 4
  %94 = load i32, ptr %8, align 4
  %95 = load i32, ptr %4, align 4
  %96 = xor i32 %95, -229796980
  %97 = mul nsw i32 %94, %96
  %98 = add i32 %93, %97
  %99 = and i32 %93, %97
  %100 = add i32 %99, %99
  %101 = sub i32 %98, %100
  %102 = load i32, ptr %7, align 4
  %103 = load i32, ptr %4, align 4
  %104 = xor i32 %103, 229796964
  %105 = xor i32 %101, %104
  %106 = add i32 %102, %105
  %107 = load i32, ptr %4, align 4
  %108 = xor i32 %107, -229796966
  %109 = add i32 %106, %108
  store i32 %109, ptr %7, align 4
  store i32 912573998, ptr %4, align 4
  %110 = xor i32 %0, -1348658311
  %111 = and i32 %0, %110
  %112 = or i32 %0, %110
  %113 = xor i32 %0, %110
  %114 = sub i32 %112, %113
  %115 = sub i32 %114, %111
  %116 = mul i32 %115, 12
  %117 = icmp ne i32 %116, 0
  br i1 %117, label %329, label %150

118:                                              ; preds = %273
  %119 = load i32, ptr %8, align 4
  %120 = load i32, ptr %4, align 4
  %121 = xor i32 %120, 912573999
  %122 = sub i32 %119, %121
  %123 = load i32, ptr %4, align 4
  %124 = xor i32 %123, 912573996
  %125 = mul i32 %119, %124
  %126 = load i32, ptr %4, align 4
  %127 = xor i32 %126, 912573999
  %128 = mul i32 %127, %122
  %129 = sub i32 %125, %128
  store i32 %129, ptr %8, align 4
  store i32 804076511, ptr %4, align 4
  %130 = xor i32 %0, 2126155509
  %131 = and i32 %0, %130
  %132 = or i32 %0, %130
  %133 = xor i32 %0, %130
  %134 = add i32 %131, %132
  %135 = sub i32 %134, %0
  %136 = sub i32 %135, %130
  %137 = mul i32 %136, 161
  %138 = xor i32 %0, 1190874435
  %139 = and i32 %0, %138
  %140 = or i32 %0, %138
  %141 = xor i32 %0, %138
  %142 = add i32 %0, %138
  %143 = sub i32 %142, %141
  %144 = mul i32 %139, 2
  %145 = sub i32 %143, %144
  %146 = mul i32 %145, 51
  %147 = icmp ne i32 %137, %146
  br i1 %147, label %338, label %150

148:                                              ; preds = %285
  %149 = load i32, ptr %7, align 4
  ret i32 %149

150:                                              ; preds = %406, %399, %392, %385, %377, %367, %357, %338, %329, %322, %314, %304, %297, %244, %231, %219, %199, %186, %174, %161, %118, %92, %60, %37, %25, %14
  br label %9

151:                                              ; preds = %295, %293, %287, %283, %277, %275, %269, %265
  store i32 -513408172, ptr %4, align 4
  call void asm sideeffect "", ""()
  %152 = xor i32 %0, -1347180747
  %153 = and i32 %0, %152
  %154 = or i32 %0, %152
  %155 = xor i32 %0, %152
  %156 = add i32 %153, %154
  %157 = sub i32 %156, %0
  %158 = sub i32 %157, %152
  %159 = mul i32 %158, 227
  %160 = icmp slt i32 %159, 0
  br i1 %160, label %347, label %9

161:                                              ; preds = %275
  %162 = load i32, ptr %4, align 4
  %163 = xor i32 %162, -1033179257
  store i32 %163, ptr %4, align 4
  %164 = xor i32 %0, 279006767
  %165 = and i32 %0, %164
  %166 = or i32 %0, %164
  %167 = xor i32 %0, %164
  %168 = mul i32 %166, 2
  %169 = sub i32 %168, %167
  %170 = sub i32 %169, %0
  %171 = sub i32 %170, %164
  %172 = mul i32 %171, 129
  %173 = icmp sgt i32 %172, 0
  br i1 %173, label %357, label %150

174:                                              ; preds = %267
  %175 = load i32, ptr %4, align 4
  %176 = xor i32 %175, -60170415
  store i32 %176, ptr %4, align 4
  %177 = xor i32 %0, 206542447
  %178 = and i32 %0, %177
  %179 = or i32 %0, %177
  %180 = xor i32 %0, %177
  %181 = add i32 %178, %179
  %182 = sub i32 %181, %0
  %183 = sub i32 %182, %177
  %184 = mul i32 %183, 23
  %185 = icmp ugt i32 %184, 0
  br i1 %185, label %367, label %150

186:                                              ; preds = %271
  %187 = load i32, ptr %4, align 4
  %188 = xor i32 %187, -1704191025
  store i32 %188, ptr %4, align 4
  %189 = xor i32 %0, 147122889
  %190 = and i32 %0, %189
  %191 = or i32 %0, %189
  %192 = xor i32 %0, %189
  %193 = add i32 %0, %189
  %194 = sub i32 %193, %192
  %195 = mul i32 %190, 2
  %196 = sub i32 %194, %195
  %197 = mul i32 %196, 227
  %198 = icmp slt i32 %197, 1
  br i1 %198, label %150, label %377

199:                                              ; preds = %289
  %200 = load i32, ptr %4, align 4
  %201 = xor i32 %200, 1383847273
  store i32 %201, ptr %4, align 4
  %202 = xor i32 %0, 2096077545
  %203 = and i32 %0, %202
  %204 = or i32 %0, %202
  %205 = xor i32 %0, %202
  %206 = mul i32 %204, 2
  %207 = sub i32 %206, %205
  %208 = sub i32 %207, %0
  %209 = sub i32 %208, %202
  %210 = mul i32 %209, 141
  %211 = xor i32 %0, 2024017799
  %212 = and i32 %0, %211
  %213 = or i32 %0, %211
  %214 = xor i32 %0, %211
  %215 = sub i32 %213, %214
  %216 = sub i32 %215, %212
  %217 = mul i32 %216, 186
  %218 = icmp eq i32 %210, %217
  br i1 %218, label %150, label %385

219:                                              ; preds = %265
  %220 = load i32, ptr %4, align 4
  %221 = xor i32 %220, 239376203
  store i32 %221, ptr %4, align 4
  %222 = xor i32 %0, 126005061
  %223 = and i32 %0, %222
  %224 = or i32 %0, %222
  %225 = xor i32 %0, %222
  %226 = add i32 %223, %224
  %227 = sub i32 %226, %0
  %228 = sub i32 %227, %222
  %229 = mul i32 %228, 64
  %230 = icmp eq i32 %229, 0
  br i1 %230, label %150, label %392

231:                                              ; preds = %291
  %232 = load i32, ptr %4, align 4
  %233 = xor i32 %232, -1698610305
  store i32 %233, ptr %4, align 4
  %234 = xor i32 %0, 1224412889
  %235 = and i32 %0, %234
  %236 = or i32 %0, %234
  %237 = xor i32 %0, %234
  %238 = mul i32 %236, 2
  %239 = sub i32 %238, %237
  %240 = sub i32 %239, %0
  %241 = sub i32 %240, %234
  %242 = mul i32 %241, 238
  %243 = icmp slt i32 %242, 0
  br i1 %243, label %399, label %150

244:                                              ; preds = %295
  %245 = load i32, ptr %4, align 4
  %246 = xor i32 %245, 1452391850
  store i32 %246, ptr %4, align 4
  %247 = xor i32 %0, -694826409
  %248 = and i32 %0, %247
  %249 = or i32 %0, %247
  %250 = xor i32 %0, %247
  %251 = mul i32 %249, 2
  %252 = sub i32 %251, %250
  %253 = sub i32 %252, %0
  %254 = sub i32 %253, %247
  %255 = mul i32 %254, 243
  %256 = icmp uge i32 %255, 0
  br i1 %256, label %150, label %406

257:                                              ; preds = %9
  %258 = icmp slt i32 %12, 413119667
  br i1 %258, label %261, label %263

259:                                              ; preds = %9
  %260 = icmp slt i32 %12, 1775155725
  br i1 %260, label %279, label %281

261:                                              ; preds = %257
  %262 = icmp slt i32 %12, 179983839
  br i1 %262, label %265, label %267

263:                                              ; preds = %257
  %264 = icmp slt i32 %12, 1054123152
  br i1 %264, label %271, label %273

265:                                              ; preds = %261
  %266 = icmp eq i32 %12, 46943074
  br i1 %266, label %219, label %151

267:                                              ; preds = %261
  %268 = icmp eq i32 %12, 179983839
  br i1 %268, label %174, label %269

269:                                              ; preds = %267
  %270 = icmp eq i32 %12, 382369690
  br i1 %270, label %60, label %151

271:                                              ; preds = %263
  %272 = icmp eq i32 %12, 413119667
  br i1 %272, label %186, label %275

273:                                              ; preds = %263
  %274 = icmp eq i32 %12, 1054123152
  br i1 %274, label %118, label %277

275:                                              ; preds = %271
  %276 = icmp eq i32 %12, 998513158
  br i1 %276, label %161, label %151

277:                                              ; preds = %273
  %278 = icmp eq i32 %12, 1261108958
  br i1 %278, label %14, label %151

279:                                              ; preds = %259
  %280 = icmp slt i32 %12, 1420939495
  br i1 %280, label %283, label %285

281:                                              ; preds = %259
  %282 = icmp slt i32 %12, 1976126482
  br i1 %282, label %289, label %291

283:                                              ; preds = %279
  %284 = icmp eq i32 %12, 1323610985
  br i1 %284, label %92, label %151

285:                                              ; preds = %279
  %286 = icmp eq i32 %12, 1420939495
  br i1 %286, label %148, label %287

287:                                              ; preds = %285
  %288 = icmp eq i32 %12, 1620877597
  br i1 %288, label %25, label %151

289:                                              ; preds = %281
  %290 = icmp eq i32 %12, 1775155725
  br i1 %290, label %199, label %293

291:                                              ; preds = %281
  %292 = icmp eq i32 %12, 1976126482
  br i1 %292, label %231, label %295

293:                                              ; preds = %289
  %294 = icmp eq i32 %12, 1956334082
  br i1 %294, label %37, label %151

295:                                              ; preds = %291
  %296 = icmp eq i32 %12, 2059301861
  br i1 %296, label %244, label %151

297:                                              ; preds = %14
  %298 = load i64, ptr %3, align 8
  %299 = zext i32 %0 to i64
  %300 = zext i32 %1 to i64
  %301 = sub i64 %300, %298
  %302 = mul i64 %301, %299
  %303 = mul i64 %302, %300
  store i64 %303, ptr %3, align 8
  br label %150

304:                                              ; preds = %25
  %305 = load i64, ptr %3, align 8
  %306 = zext i32 %0 to i64
  %307 = zext i32 %1 to i64
  %308 = sub i64 %305, %306
  %309 = add i64 %308, %305
  %310 = or i64 %309, %306
  %311 = sub i64 %310, %305
  %312 = and i64 %311, %307
  %313 = or i64 %312, %307
  store i64 %313, ptr %3, align 8
  br label %150

314:                                              ; preds = %37
  %315 = load i64, ptr %3, align 8
  %316 = zext i32 %0 to i64
  %317 = zext i32 %1 to i64
  %318 = sub i64 %317, %315
  %319 = and i64 %318, %317
  %320 = or i64 %319, %317
  %321 = sub i64 %320, %315
  store i64 %321, ptr %3, align 8
  br label %150

322:                                              ; preds = %60
  %323 = load i64, ptr %3, align 8
  %324 = zext i32 %0 to i64
  %325 = zext i32 %1 to i64
  %326 = xor i64 %324, %323
  %327 = or i64 %326, %325
  %328 = add i64 %327, %324
  store i64 %328, ptr %3, align 8
  br label %150

329:                                              ; preds = %92
  %330 = load i64, ptr %3, align 8
  %331 = zext i32 %0 to i64
  %332 = zext i32 %1 to i64
  %333 = mul i64 %332, %332
  %334 = add i64 %333, %330
  %335 = mul i64 %334, %330
  %336 = sub i64 %335, %331
  %337 = sub i64 %336, %331
  store i64 %337, ptr %3, align 8
  br label %150

338:                                              ; preds = %118
  %339 = load i64, ptr %3, align 8
  %340 = zext i32 %0 to i64
  %341 = zext i32 %1 to i64
  %342 = or i64 %340, %341
  %343 = sub i64 %342, %340
  %344 = or i64 %343, %341
  %345 = xor i64 %344, %339
  %346 = mul i64 %345, %339
  store i64 %346, ptr %3, align 8
  br label %150

347:                                              ; preds = %151
  %348 = load i64, ptr %3, align 8
  %349 = zext i32 %0 to i64
  %350 = zext i32 %1 to i64
  %351 = add i64 %349, %349
  %352 = mul i64 %351, %349
  %353 = mul i64 %352, %348
  %354 = or i64 %353, %349
  %355 = mul i64 %354, %350
  %356 = mul i64 %355, %348
  store i64 %356, ptr %3, align 8
  br label %9

357:                                              ; preds = %161
  %358 = load i64, ptr %3, align 8
  %359 = zext i32 %0 to i64
  %360 = zext i32 %1 to i64
  %361 = mul i64 %358, %358
  %362 = and i64 %361, %360
  %363 = add i64 %362, %358
  %364 = sub i64 %363, %358
  %365 = sub i64 %364, %359
  %366 = xor i64 %365, %360
  store i64 %366, ptr %3, align 8
  br label %150

367:                                              ; preds = %174
  %368 = load i64, ptr %3, align 8
  %369 = zext i32 %0 to i64
  %370 = zext i32 %1 to i64
  %371 = sub i64 %370, %370
  %372 = add i64 %371, %370
  %373 = mul i64 %372, %370
  %374 = add i64 %373, %368
  %375 = or i64 %374, %370
  %376 = sub i64 %375, %370
  store i64 %376, ptr %3, align 8
  br label %150

377:                                              ; preds = %186
  %378 = load i64, ptr %3, align 8
  %379 = zext i32 %0 to i64
  %380 = zext i32 %1 to i64
  %381 = or i64 %380, %379
  %382 = xor i64 %381, %380
  %383 = mul i64 %382, %380
  %384 = or i64 %383, %378
  store i64 %384, ptr %3, align 8
  br label %150

385:                                              ; preds = %199
  %386 = load i64, ptr %3, align 8
  %387 = zext i32 %0 to i64
  %388 = zext i32 %1 to i64
  %389 = or i64 %387, %386
  %390 = mul i64 %389, %388
  %391 = mul i64 %390, %386
  store i64 %391, ptr %3, align 8
  br label %150

392:                                              ; preds = %219
  %393 = load i64, ptr %3, align 8
  %394 = zext i32 %0 to i64
  %395 = zext i32 %1 to i64
  %396 = sub i64 %395, %393
  %397 = add i64 %396, %394
  %398 = mul i64 %397, %394
  store i64 %398, ptr %3, align 8
  br label %150

399:                                              ; preds = %231
  %400 = load i64, ptr %3, align 8
  %401 = zext i32 %0 to i64
  %402 = zext i32 %1 to i64
  %403 = xor i64 %401, %401
  %404 = add i64 %403, %401
  %405 = mul i64 %404, %402
  store i64 %405, ptr %3, align 8
  br label %150

406:                                              ; preds = %244
  %407 = load i64, ptr %3, align 8
  %408 = zext i32 %0 to i64
  %409 = zext i32 %1 to i64
  %410 = and i64 %409, %408
  %411 = add i64 %410, %409
  %412 = and i64 %411, %407
  %413 = or i64 %412, %409
  store i64 %413, ptr %3, align 8
  br label %150
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @helper_muladd(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = mul nsw i32 %5, 31
  %7 = load i32, ptr %4, align 4
  %8 = or i32 %7, 21930
  %9 = and i32 %7, 21930
  %10 = sub i32 %8, %9
  %11 = add i32 %10, 1
  %12 = sub i32 %6, 1
  %13 = mul i32 %6, %11
  %14 = mul i32 %10, %12
  %15 = sub i32 %13, %14
  ret i32 %15
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @helper_xor(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = add i32 %5, %6
  %8 = and i32 %5, %6
  %9 = add i32 %8, %8
  %10 = sub i32 %7, %9
  %11 = load i32, ptr %3, align 4
  %12 = load i32, ptr %4, align 4
  %13 = add i32 %11, %12
  %14 = or i32 %11, %12
  %15 = sub i32 %13, %14
  %16 = mul i32 %15, 2
  %17 = xor i32 %16, -1
  %18 = add i32 %10, %17
  %19 = add i32 %18, 1
  ret i32 %19
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i1, align 1
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca [512 x i8], align 16
  %10 = alloca i64, align 8
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca ptr, align 8
  %14 = alloca i32, align 4
  store i32 -2058330102, ptr %4, align 4
  br label %15

15:                                               ; preds = %704, %390, %389, %2
  %16 = load i32, ptr %4, align 4
  %17 = sub i32 %16, 552794865
  %18 = mul i32 %17, -790966887
  switch i32 %18, label %390 [
    i32 756052209, label %19
    i32 1487258959, label %39
    i32 257947842, label %56
    i32 683452289, label %65
    i32 64342087, label %77
    i32 1942023473, label %88
    i32 1515680695, label %102
    i32 304993637, label %115
    i32 1051548590, label %126
    i32 1388673240, label %152
    i32 1019599930, label %163
    i32 197785712, label %186
    i32 2093625789, label %199
    i32 1961063084, label %230
    i32 1099179776, label %254
    i32 913085554, label %265
    i32 1855590416, label %293
    i32 154165075, label %305
    i32 1859356751, label %328
    i32 169874558, label %340
    i32 235742566, label %354
    i32 669176721, label %366
    i32 209394648, label %387
    i32 13481045, label %401
    i32 31186644, label %414
    i32 2116186521, label %427
    i32 1339880039, label %447
    i32 1040104040, label %466
    i32 804814184, label %479
    i32 1324556270, label %492
    i32 1441657984, label %504
  ]

19:                                               ; preds = %15
  store i32 0, ptr %6, align 4
  store i32 %0, ptr %7, align 4
  store ptr %1, ptr %8, align 8
  store i64 0, ptr %10, align 8
  store i32 0, ptr %11, align 4
  store i32 0, ptr %12, align 4
  %20 = getelementptr inbounds [512 x i8], ptr %9, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %20, i8 0, i64 512, i1 false)
  %21 = load i32, ptr %7, align 4
  %22 = icmp sgt i32 %21, 1
  %23 = select i1 %22, i32 2102453784, i32 -215798832
  store i32 %23, ptr %4, align 4
  %24 = xor i32 %0, 697135345
  %25 = and i32 %0, %24
  %26 = or i32 %0, %24
  %27 = xor i32 %0, %24
  %28 = sub i32 %26, %27
  %29 = sub i32 %28, %25
  %30 = mul i32 %29, 29
  %31 = xor i32 %0, -1473818981
  %32 = and i32 %0, %31
  %33 = or i32 %0, %31
  %34 = xor i32 %0, %31
  %35 = sub i32 %33, %34
  %36 = sub i32 %35, %32
  %37 = mul i32 %36, 198
  %38 = icmp ne i32 %30, %37
  br i1 %38, label %516, label %389

39:                                               ; preds = %15
  %40 = load ptr, ptr %8, align 8
  %41 = getelementptr inbounds ptr, ptr %40, i64 1
  %42 = load ptr, ptr %41, align 8
  store ptr %42, ptr %13, align 8
  %43 = load ptr, ptr %13, align 8
  %44 = call i64 @strlen(ptr noundef %43) #9
  store i64 %44, ptr %10, align 8
  %45 = load i64, ptr %10, align 8
  %46 = icmp ugt i64 %45, 512
  %47 = select i1 %46, i32 -1188618493, i32 1887618330
  store i32 %47, ptr %4, align 4
  %48 = xor i32 %0, 1539152853
  %49 = and i32 %0, %48
  %50 = or i32 %0, %48
  %51 = xor i32 %0, %48
  %52 = sub i32 %50, %51
  %53 = sub i32 %52, %49
  %54 = mul i32 %53, 191
  %55 = icmp uge i32 %54, 0
  br i1 %55, label %389, label %525

56:                                               ; preds = %15
  store i64 512, ptr %10, align 8
  store i32 1887618330, ptr %4, align 4
  %57 = xor i32 %0, 1748714027
  %58 = and i32 %0, %57
  %59 = or i32 %0, %57
  %60 = xor i32 %0, %57
  %61 = sub i32 %59, %60
  %62 = sub i32 %61, %58
  %63 = mul i32 %62, 113
  %64 = icmp ugt i32 %63, 0
  br i1 %64, label %533, label %389

65:                                               ; preds = %15
  %66 = getelementptr inbounds [512 x i8], ptr %9, i64 0, i64 0
  %67 = load ptr, ptr %13, align 8
  %68 = load i64, ptr %10, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %66, ptr align 1 %67, i64 %68, i1 false)
  store i32 1508219195, ptr %4, align 4
  %69 = xor i32 %0, 2112660677
  %70 = and i32 %0, %69
  %71 = or i32 %0, %69
  %72 = xor i32 %0, %69
  %73 = sub i32 %71, %72
  %74 = sub i32 %73, %70
  %75 = mul i32 %74, 85
  %76 = icmp sle i32 %75, 0
  br i1 %76, label %389, label %540

77:                                               ; preds = %15
  store i32 -1777867190, ptr %4, align 4
  %78 = xor i32 %0, -1755066835
  %79 = and i32 %0, %78
  %80 = or i32 %0, %78
  %81 = xor i32 %0, %78
  %82 = add i32 %0, %78
  %83 = sub i32 %82, %81
  %84 = mul i32 %79, 2
  %85 = sub i32 %83, %84
  %86 = mul i32 %85, 114
  %87 = icmp sgt i32 %86, 0
  br i1 %87, label %549, label %389

88:                                               ; preds = %15
  %89 = call i32 @getchar()
  store i32 %89, ptr %14, align 4
  %90 = icmp ne i32 %89, -1
  store i1 false, ptr %5, align 1
  %91 = select i1 %90, i32 1441200320, i32 -190306146
  store i32 %91, ptr %4, align 4
  %92 = xor i32 %0, 330322323
  %93 = and i32 %0, %92
  %94 = or i32 %0, %92
  %95 = xor i32 %0, %92
  %96 = mul i32 %94, 2
  %97 = sub i32 %96, %95
  %98 = sub i32 %97, %0
  %99 = sub i32 %98, %92
  %100 = mul i32 %99, 205
  %101 = icmp slt i32 %100, 0
  br i1 %101, label %557, label %389

102:                                              ; preds = %15
  %103 = load i64, ptr %10, align 8
  %104 = icmp ult i64 %103, 512
  store i1 %104, ptr %5, align 1
  store i32 -190306146, ptr %4, align 4
  %105 = xor i32 %0, -650334125
  %106 = and i32 %0, %105
  %107 = or i32 %0, %105
  %108 = xor i32 %0, %105
  %109 = add i32 %0, %105
  %110 = sub i32 %109, %108
  %111 = mul i32 %106, 2
  %112 = sub i32 %110, %111
  %113 = mul i32 %112, 14
  %114 = icmp ne i32 %113, 0
  br i1 %114, label %564, label %389

115:                                              ; preds = %15
  %116 = load i1, ptr %5, align 1
  %117 = select i1 %116, i32 -61131569, i32 -380808823
  store i32 %117, ptr %4, align 4
  %118 = xor i32 %0, 1662529241
  %119 = and i32 %0, %118
  %120 = or i32 %0, %118
  %121 = xor i32 %0, %118
  %122 = sub i32 %120, %121
  %123 = sub i32 %122, %119
  %124 = mul i32 %123, 131
  %125 = icmp eq i32 %124, 0
  br i1 %125, label %389, label %574

126:                                              ; preds = %15
  %127 = load i32, ptr %14, align 4
  %128 = trunc i32 %127 to i8
  %129 = load i64, ptr %10, align 8
  %130 = sub i64 %129, 1
  %131 = mul i64 %129, 2
  %132 = mul i64 1, %130
  %133 = sub i64 %131, %132
  store i64 %133, ptr %10, align 8
  %134 = getelementptr inbounds nuw [512 x i8], ptr %9, i64 0, i64 %129
  store i8 %128, ptr %134, align 1
  store i32 -1777867190, ptr %4, align 4
  %135 = xor i32 %0, -1767977311
  %136 = and i32 %0, %135
  %137 = or i32 %0, %135
  %138 = xor i32 %0, %135
  %139 = add i32 %0, %135
  %140 = sub i32 %139, %138
  %141 = mul i32 %136, 2
  %142 = sub i32 %140, %141
  %143 = mul i32 %142, 64
  %144 = xor i32 %0, 78434833
  %145 = and i32 %0, %144
  %146 = or i32 %0, %144
  %147 = xor i32 %0, %144
  %148 = sub i32 %146, %147
  %149 = sub i32 %148, %145
  %150 = mul i32 %149, 112
  %151 = icmp eq i32 %143, %150
  br i1 %151, label %389, label %582

152:                                              ; preds = %15
  store i32 1508219195, ptr %4, align 4
  %153 = xor i32 %0, 2107439427
  %154 = and i32 %0, %153
  %155 = or i32 %0, %153
  %156 = xor i32 %0, %153
  %157 = add i32 %0, %153
  %158 = sub i32 %157, %156
  %159 = mul i32 %154, 2
  %160 = sub i32 %158, %159
  %161 = mul i32 %160, 192
  %162 = icmp uge i32 %161, 0
  br i1 %162, label %389, label %590

163:                                              ; preds = %15
  %164 = load i32, ptr %7, align 4
  %165 = icmp sgt i32 %164, 2
  %166 = select i1 %165, i32 1622121697, i32 -1243894090
  store i32 %166, ptr %4, align 4
  %167 = xor i32 %0, -1584847997
  %168 = and i32 %0, %167
  %169 = or i32 %0, %167
  %170 = xor i32 %0, %167
  %171 = add i32 %0, %167
  %172 = sub i32 %171, %170
  %173 = mul i32 %168, 2
  %174 = sub i32 %172, %173
  %175 = mul i32 %174, 178
  %176 = xor i32 %0, 1210617319
  %177 = and i32 %0, %176
  %178 = or i32 %0, %176
  %179 = xor i32 %0, %176
  %180 = add i32 %0, %176
  %181 = sub i32 %180, %179
  %182 = mul i32 %177, 2
  %183 = sub i32 %181, %182
  %184 = mul i32 %183, 86
  %185 = icmp ne i32 %175, %184
  br i1 %185, label %598, label %389

186:                                              ; preds = %15
  %187 = load ptr, ptr %8, align 8
  %188 = getelementptr inbounds ptr, ptr %187, i64 2
  %189 = load ptr, ptr %188, align 8
  %190 = call i32 @atoi(ptr noundef %189) #9
  store i32 %190, ptr %11, align 4
  store i32 260699773, ptr %4, align 4
  %191 = xor i32 %0, -1968467085
  %192 = and i32 %0, %191
  %193 = or i32 %0, %191
  %194 = xor i32 %0, %191
  %195 = sub i32 %193, %194
  %196 = sub i32 %195, %192
  %197 = mul i32 %196, 132
  %198 = icmp sgt i32 %197, 0
  br i1 %198, label %608, label %389

199:                                              ; preds = %15
  %200 = load i64, ptr %10, align 8
  %201 = urem i64 %200, 7
  %202 = trunc i64 %201 to i32
  %203 = load i32, ptr %4, align 4
  %204 = xor i32 %203, -1243894089
  %205 = add i32 %202, %204
  %206 = load i32, ptr %4, align 4
  %207 = xor i32 %206, -1243894094
  %208 = mul i32 %202, %207
  %209 = load i32, ptr %4, align 4
  %210 = xor i32 %209, -1243894091
  %211 = mul i32 %210, %205
  %212 = sub i32 %208, %211
  store i32 %212, ptr %11, align 4
  store i32 260699773, ptr %4, align 4
  %213 = xor i32 %0, 51296775
  %214 = and i32 %0, %213
  %215 = or i32 %0, %213
  %216 = xor i32 %0, %213
  %217 = sub i32 %215, %216
  %218 = sub i32 %217, %214
  %219 = mul i32 %218, 102
  %220 = xor i32 %0, -661333051
  %221 = and i32 %0, %220
  %222 = or i32 %0, %220
  %223 = xor i32 %0, %220
  %224 = mul i32 %222, 2
  %225 = sub i32 %224, %223
  %226 = sub i32 %225, %0
  %227 = sub i32 %226, %220
  %228 = mul i32 %227, 94
  %229 = icmp ne i32 %219, %228
  br i1 %229, label %616, label %389

230:                                              ; preds = %15
  %231 = load i64, ptr %10, align 8
  %232 = call i32 (ptr, ...) @printf(ptr noundef @.str.3, i64 noundef %231)
  %233 = load i32, ptr %11, align 4
  %234 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i32 noundef %233)
  %235 = getelementptr inbounds [512 x i8], ptr %9, i64 0, i64 0
  %236 = load i64, ptr %10, align 8
  %237 = load i32, ptr %11, align 4
  %238 = call i32 @big_edge_function(ptr noundef %235, i64 noundef %236, i32 noundef %237)
  store i32 %238, ptr %12, align 4
  %239 = load i32, ptr %12, align 4
  %240 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %239)
  %241 = load i32, ptr %12, align 4
  %242 = icmp eq i32 %241, 305419896
  %243 = select i1 %242, i32 292207089, i32 38864435
  store i32 %243, ptr %4, align 4
  %244 = xor i32 %0, -273612055
  %245 = and i32 %0, %244
  %246 = or i32 %0, %244
  %247 = xor i32 %0, %244
  %248 = add i32 %0, %244
  %249 = sub i32 %248, %247
  %250 = mul i32 %245, 2
  %251 = sub i32 %249, %250
  %252 = mul i32 %251, 207
  %253 = icmp eq i32 %252, 0
  br i1 %253, label %389, label %625

254:                                              ; preds = %15
  %255 = call i32 @puts(ptr noundef @.str.6)
  store i32 10, ptr %6, align 4
  store i32 -493359991, ptr %4, align 4
  %256 = xor i32 %0, -4357855
  %257 = and i32 %0, %256
  %258 = or i32 %0, %256
  %259 = xor i32 %0, %256
  %260 = add i32 %257, %258
  %261 = sub i32 %260, %0
  %262 = sub i32 %261, %256
  %263 = mul i32 %262, 180
  %264 = icmp ne i32 %263, 0
  br i1 %264, label %635, label %389

265:                                              ; preds = %15
  %266 = load i32, ptr %12, align 4
  %267 = load i32, ptr %4, align 4
  %268 = xor i32 %267, 38926796
  %269 = add i32 %266, %268
  %270 = load i32, ptr %4, align 4
  %271 = xor i32 %270, 38926796
  %272 = or i32 %266, %271
  %273 = sub i32 %269, %272
  %274 = icmp eq i32 %273, 48879
  %275 = select i1 %274, i32 520811905, i32 67988156
  store i32 %275, ptr %4, align 4
  %276 = xor i32 %0, -979503157
  %277 = and i32 %0, %276
  %278 = or i32 %0, %276
  %279 = xor i32 %0, %276
  %280 = sub i32 %278, %279
  %281 = sub i32 %280, %277
  %282 = mul i32 %281, 220
  %283 = xor i32 %0, -956319691
  %284 = and i32 %0, %283
  %285 = or i32 %0, %283
  %286 = xor i32 %0, %283
  %287 = mul i32 %285, 2
  %288 = sub i32 %287, %286
  %289 = sub i32 %288, %0
  %290 = sub i32 %289, %283
  %291 = mul i32 %290, 57
  %292 = icmp eq i32 %282, %291
  br i1 %292, label %389, label %642

293:                                              ; preds = %15
  %294 = call i32 @puts(ptr noundef @.str.7)
  store i32 20, ptr %6, align 4
  store i32 -493359991, ptr %4, align 4
  %295 = xor i32 %0, -1605153957
  %296 = and i32 %0, %295
  %297 = or i32 %0, %295
  %298 = xor i32 %0, %295
  %299 = add i32 %0, %295
  %300 = sub i32 %299, %298
  %301 = mul i32 %296, 2
  %302 = sub i32 %300, %301
  %303 = mul i32 %302, 31
  %304 = icmp slt i32 %303, 1
  br i1 %304, label %389, label %651

305:                                              ; preds = %15
  %306 = load i32, ptr %12, align 4
  %307 = icmp slt i32 %306, 0
  %308 = select i1 %307, i32 -660037352, i32 1024661023
  store i32 %308, ptr %4, align 4
  %309 = xor i32 %0, 1378056099
  %310 = and i32 %0, %309
  %311 = or i32 %0, %309
  %312 = xor i32 %0, %309
  %313 = add i32 %0, %309
  %314 = sub i32 %313, %312
  %315 = mul i32 %310, 2
  %316 = sub i32 %314, %315
  %317 = mul i32 %316, 249
  %318 = xor i32 %0, 1900474431
  %319 = and i32 %0, %318
  %320 = or i32 %0, %318
  %321 = xor i32 %0, %318
  %322 = mul i32 %320, 2
  %323 = sub i32 %322, %321
  %324 = sub i32 %323, %0
  %325 = sub i32 %324, %318
  %326 = mul i32 %325, 137
  %327 = icmp ne i32 %317, %326
  br i1 %327, label %661, label %389

328:                                              ; preds = %15
  %329 = call i32 @puts(ptr noundef @.str.8)
  store i32 1, ptr %6, align 4
  store i32 -493359991, ptr %4, align 4
  %330 = xor i32 %0, 670845157
  %331 = and i32 %0, %330
  %332 = or i32 %0, %330
  %333 = xor i32 %0, %330
  %334 = mul i32 %332, 2
  %335 = sub i32 %334, %333
  %336 = sub i32 %335, %0
  %337 = sub i32 %336, %330
  %338 = mul i32 %337, 4
  %339 = icmp sle i32 %338, 0
  br i1 %339, label %389, label %670

340:                                              ; preds = %15
  %341 = load i32, ptr %12, align 4
  %342 = icmp eq i32 %341, 0
  %343 = select i1 %342, i32 1302605639, i32 -1459536982
  store i32 %343, ptr %4, align 4
  %344 = xor i32 %0, -696057343
  %345 = and i32 %0, %344
  %346 = or i32 %0, %344
  %347 = xor i32 %0, %344
  %348 = add i32 %0, %344
  %349 = sub i32 %348, %347
  %350 = mul i32 %345, 2
  %351 = sub i32 %349, %350
  %352 = mul i32 %351, 41
  %353 = icmp uge i32 %352, 0
  br i1 %353, label %389, label %679

354:                                              ; preds = %15
  %355 = call i32 @puts(ptr noundef @.str.9)
  store i32 2, ptr %6, align 4
  store i32 -493359991, ptr %4, align 4
  %356 = xor i32 %0, -729782557
  %357 = and i32 %0, %356
  %358 = or i32 %0, %356
  %359 = xor i32 %0, %356
  %360 = add i32 %0, %356
  %361 = sub i32 %360, %359
  %362 = mul i32 %357, 2
  %363 = sub i32 %361, %362
  %364 = mul i32 %363, 65
  %365 = icmp slt i32 %364, 1
  br i1 %365, label %389, label %687

366:                                              ; preds = %15
  %367 = call i32 @puts(ptr noundef @.str.10)
  store i32 0, ptr %6, align 4
  store i32 -493359991, ptr %4, align 4
  %368 = xor i32 %0, -191903537
  %369 = and i32 %0, %368
  %370 = or i32 %0, %368
  %371 = xor i32 %0, %368
  %372 = mul i32 %370, 2
  %373 = sub i32 %372, %371
  %374 = sub i32 %373, %0
  %375 = sub i32 %374, %368
  %376 = mul i32 %375, 78
  %377 = xor i32 %0, 751452201
  %378 = and i32 %0, %377
  %379 = or i32 %0, %377
  %380 = xor i32 %0, %377
  %381 = add i32 %0, %377
  %382 = sub i32 %381, %380
  %383 = mul i32 %378, 2
  %384 = sub i32 %382, %383
  %385 = mul i32 %384, 24
  %386 = icmp eq i32 %376, %385
  br i1 %386, label %389, label %695

387:                                              ; preds = %15
  %388 = load i32, ptr %6, align 4
  ret i32 %388

389:                                              ; preds = %771, %762, %752, %743, %734, %726, %719, %711, %695, %687, %679, %670, %661, %651, %642, %635, %625, %616, %608, %598, %590, %582, %574, %564, %557, %549, %540, %533, %525, %516, %504, %492, %479, %466, %447, %427, %414, %401, %366, %354, %340, %328, %305, %293, %265, %254, %230, %199, %186, %163, %152, %126, %115, %102, %88, %77, %65, %56, %39, %19
  br label %15

390:                                              ; preds = %15
  store i32 -2058330102, ptr %4, align 4
  call void asm sideeffect "", ""()
  %391 = xor i32 %0, 1133145087
  %392 = and i32 %0, %391
  %393 = or i32 %0, %391
  %394 = xor i32 %0, %391
  %395 = add i32 %0, %391
  %396 = sub i32 %395, %394
  %397 = mul i32 %392, 2
  %398 = sub i32 %396, %397
  %399 = mul i32 %398, 239
  %400 = icmp sle i32 %399, 0
  br i1 %400, label %15, label %704

401:                                              ; preds = %15
  %402 = load i32, ptr %4, align 4
  %403 = xor i32 %402, 1067753742
  store i32 %403, ptr %4, align 4
  %404 = xor i32 %0, -925159069
  %405 = and i32 %0, %404
  %406 = or i32 %0, %404
  %407 = xor i32 %0, %404
  %408 = mul i32 %406, 2
  %409 = sub i32 %408, %407
  %410 = sub i32 %409, %0
  %411 = sub i32 %410, %404
  %412 = mul i32 %411, 228
  %413 = icmp ugt i32 %412, 0
  br i1 %413, label %711, label %389

414:                                              ; preds = %15
  %415 = load i32, ptr %4, align 4
  %416 = xor i32 %415, 1676539562
  store i32 %416, ptr %4, align 4
  %417 = xor i32 %0, 1426446331
  %418 = and i32 %0, %417
  %419 = or i32 %0, %417
  %420 = xor i32 %0, %417
  %421 = add i32 %0, %417
  %422 = sub i32 %421, %420
  %423 = mul i32 %418, 2
  %424 = sub i32 %422, %423
  %425 = mul i32 %424, 185
  %426 = icmp ne i32 %425, 0
  br i1 %426, label %719, label %389

427:                                              ; preds = %15
  %428 = load i32, ptr %4, align 4
  %429 = xor i32 %428, -156311334
  store i32 %429, ptr %4, align 4
  %430 = xor i32 %0, -1472118087
  %431 = and i32 %0, %430
  %432 = or i32 %0, %430
  %433 = xor i32 %0, %430
  %434 = add i32 %431, %432
  %435 = sub i32 %434, %0
  %436 = sub i32 %435, %430
  %437 = mul i32 %436, 150
  %438 = xor i32 %0, 697989241
  %439 = and i32 %0, %438
  %440 = or i32 %0, %438
  %441 = xor i32 %0, %438
  %442 = add i32 %439, %440
  %443 = sub i32 %442, %0
  %444 = sub i32 %443, %438
  %445 = mul i32 %444, 6
  %446 = icmp ne i32 %437, %445
  br i1 %446, label %726, label %389

447:                                              ; preds = %15
  %448 = load i32, ptr %4, align 4
  %449 = xor i32 %448, -199281580
  store i32 %449, ptr %4, align 4
  %450 = xor i32 %0, 1595049195
  %451 = and i32 %0, %450
  %452 = or i32 %0, %450
  %453 = xor i32 %0, %450
  %454 = sub i32 %452, %453
  %455 = sub i32 %454, %451
  %456 = mul i32 %455, 107
  %457 = xor i32 %0, -22175233
  %458 = and i32 %0, %457
  %459 = or i32 %0, %457
  %460 = xor i32 %0, %457
  %461 = add i32 %458, %459
  %462 = sub i32 %461, %0
  %463 = sub i32 %462, %457
  %464 = mul i32 %463, 207
  %465 = icmp ne i32 %456, %464
  br i1 %465, label %734, label %389

466:                                              ; preds = %15
  %467 = load i32, ptr %4, align 4
  %468 = xor i32 %467, 1933219450
  store i32 %468, ptr %4, align 4
  %469 = xor i32 %0, 605205387
  %470 = and i32 %0, %469
  %471 = or i32 %0, %469
  %472 = xor i32 %0, %469
  %473 = mul i32 %471, 2
  %474 = sub i32 %473, %472
  %475 = sub i32 %474, %0
  %476 = sub i32 %475, %469
  %477 = mul i32 %476, 137
  %478 = icmp uge i32 %477, 0
  br i1 %478, label %389, label %743

479:                                              ; preds = %15
  %480 = load i32, ptr %4, align 4
  %481 = xor i32 %480, -275686431
  store i32 %481, ptr %4, align 4
  %482 = xor i32 %0, 705559129
  %483 = and i32 %0, %482
  %484 = or i32 %0, %482
  %485 = xor i32 %0, %482
  %486 = mul i32 %484, 2
  %487 = sub i32 %486, %485
  %488 = sub i32 %487, %0
  %489 = sub i32 %488, %482
  %490 = mul i32 %489, 66
  %491 = icmp slt i32 %490, 0
  br i1 %491, label %752, label %389

492:                                              ; preds = %15
  %493 = load i32, ptr %4, align 4
  %494 = xor i32 %493, -596006758
  store i32 %494, ptr %4, align 4
  %495 = xor i32 %0, -1967520239
  %496 = and i32 %0, %495
  %497 = or i32 %0, %495
  %498 = xor i32 %0, %495
  %499 = add i32 %496, %497
  %500 = sub i32 %499, %0
  %501 = sub i32 %500, %495
  %502 = mul i32 %501, 160
  %503 = icmp uge i32 %502, 0
  br i1 %503, label %389, label %762

504:                                              ; preds = %15
  %505 = load i32, ptr %4, align 4
  %506 = xor i32 %505, 1363365311
  store i32 %506, ptr %4, align 4
  %507 = xor i32 %0, 1138715427
  %508 = and i32 %0, %507
  %509 = or i32 %0, %507
  %510 = xor i32 %0, %507
  %511 = add i32 %508, %509
  %512 = sub i32 %511, %0
  %513 = sub i32 %512, %507
  %514 = mul i32 %513, 41
  %515 = icmp sle i32 %514, 0
  br i1 %515, label %389, label %771

516:                                              ; preds = %19
  %517 = load i64, ptr %3, align 8
  %518 = zext i32 %0 to i64
  %519 = ptrtoint ptr %1 to i64
  %520 = or i64 %518, %518
  %521 = or i64 %520, %519
  %522 = and i64 %521, %518
  %523 = mul i64 %522, %517
  %524 = add i64 %523, %517
  store i64 %524, ptr %3, align 8
  br label %389

525:                                              ; preds = %39
  %526 = load i64, ptr %3, align 8
  %527 = zext i32 %0 to i64
  %528 = ptrtoint ptr %1 to i64
  %529 = sub i64 %527, %526
  %530 = sub i64 %529, %526
  %531 = sub i64 %530, %528
  %532 = xor i64 %531, %527
  store i64 %532, ptr %3, align 8
  br label %389

533:                                              ; preds = %56
  %534 = load i64, ptr %3, align 8
  %535 = zext i32 %0 to i64
  %536 = ptrtoint ptr %1 to i64
  %537 = add i64 %535, %534
  %538 = or i64 %537, %534
  %539 = add i64 %538, %535
  store i64 %539, ptr %3, align 8
  br label %389

540:                                              ; preds = %65
  %541 = load i64, ptr %3, align 8
  %542 = zext i32 %0 to i64
  %543 = ptrtoint ptr %1 to i64
  %544 = add i64 %541, %542
  %545 = add i64 %544, %541
  %546 = sub i64 %545, %543
  %547 = add i64 %546, %541
  %548 = mul i64 %547, %542
  store i64 %548, ptr %3, align 8
  br label %389

549:                                              ; preds = %77
  %550 = load i64, ptr %3, align 8
  %551 = zext i32 %0 to i64
  %552 = ptrtoint ptr %1 to i64
  %553 = sub i64 %552, %550
  %554 = sub i64 %553, %550
  %555 = mul i64 %554, %551
  %556 = mul i64 %555, %551
  store i64 %556, ptr %3, align 8
  br label %389

557:                                              ; preds = %88
  %558 = load i64, ptr %3, align 8
  %559 = zext i32 %0 to i64
  %560 = ptrtoint ptr %1 to i64
  %561 = or i64 %559, %560
  %562 = xor i64 %561, %560
  %563 = xor i64 %562, %559
  store i64 %563, ptr %3, align 8
  br label %389

564:                                              ; preds = %102
  %565 = load i64, ptr %3, align 8
  %566 = zext i32 %0 to i64
  %567 = ptrtoint ptr %1 to i64
  %568 = mul i64 %565, %567
  %569 = mul i64 %568, %566
  %570 = add i64 %569, %565
  %571 = and i64 %570, %566
  %572 = and i64 %571, %566
  %573 = sub i64 %572, %566
  store i64 %573, ptr %3, align 8
  br label %389

574:                                              ; preds = %115
  %575 = load i64, ptr %3, align 8
  %576 = zext i32 %0 to i64
  %577 = ptrtoint ptr %1 to i64
  %578 = or i64 %575, %576
  %579 = add i64 %578, %575
  %580 = sub i64 %579, %575
  %581 = and i64 %580, %575
  store i64 %581, ptr %3, align 8
  br label %389

582:                                              ; preds = %126
  %583 = load i64, ptr %3, align 8
  %584 = zext i32 %0 to i64
  %585 = ptrtoint ptr %1 to i64
  %586 = or i64 %584, %585
  %587 = or i64 %586, %584
  %588 = xor i64 %587, %584
  %589 = and i64 %588, %584
  store i64 %589, ptr %3, align 8
  br label %389

590:                                              ; preds = %152
  %591 = load i64, ptr %3, align 8
  %592 = zext i32 %0 to i64
  %593 = ptrtoint ptr %1 to i64
  %594 = or i64 %591, %591
  %595 = and i64 %594, %592
  %596 = sub i64 %595, %593
  %597 = or i64 %596, %592
  store i64 %597, ptr %3, align 8
  br label %389

598:                                              ; preds = %163
  %599 = load i64, ptr %3, align 8
  %600 = zext i32 %0 to i64
  %601 = ptrtoint ptr %1 to i64
  %602 = add i64 %600, %600
  %603 = xor i64 %602, %601
  %604 = sub i64 %603, %600
  %605 = and i64 %604, %600
  %606 = xor i64 %605, %599
  %607 = and i64 %606, %599
  store i64 %607, ptr %3, align 8
  br label %389

608:                                              ; preds = %186
  %609 = load i64, ptr %3, align 8
  %610 = zext i32 %0 to i64
  %611 = ptrtoint ptr %1 to i64
  %612 = and i64 %610, %611
  %613 = add i64 %612, %611
  %614 = sub i64 %613, %611
  %615 = and i64 %614, %610
  store i64 %615, ptr %3, align 8
  br label %389

616:                                              ; preds = %199
  %617 = load i64, ptr %3, align 8
  %618 = zext i32 %0 to i64
  %619 = ptrtoint ptr %1 to i64
  %620 = add i64 %617, %617
  %621 = mul i64 %620, %619
  %622 = add i64 %621, %619
  %623 = add i64 %622, %619
  %624 = mul i64 %623, %619
  store i64 %624, ptr %3, align 8
  br label %389

625:                                              ; preds = %230
  %626 = load i64, ptr %3, align 8
  %627 = zext i32 %0 to i64
  %628 = ptrtoint ptr %1 to i64
  %629 = xor i64 %628, %626
  %630 = add i64 %629, %627
  %631 = add i64 %630, %628
  %632 = sub i64 %631, %627
  %633 = add i64 %632, %626
  %634 = and i64 %633, %626
  store i64 %634, ptr %3, align 8
  br label %389

635:                                              ; preds = %254
  %636 = load i64, ptr %3, align 8
  %637 = zext i32 %0 to i64
  %638 = ptrtoint ptr %1 to i64
  %639 = and i64 %638, %638
  %640 = and i64 %639, %638
  %641 = add i64 %640, %636
  store i64 %641, ptr %3, align 8
  br label %389

642:                                              ; preds = %265
  %643 = load i64, ptr %3, align 8
  %644 = zext i32 %0 to i64
  %645 = ptrtoint ptr %1 to i64
  %646 = add i64 %644, %643
  %647 = and i64 %646, %643
  %648 = and i64 %647, %643
  %649 = sub i64 %648, %644
  %650 = or i64 %649, %645
  store i64 %650, ptr %3, align 8
  br label %389

651:                                              ; preds = %293
  %652 = load i64, ptr %3, align 8
  %653 = zext i32 %0 to i64
  %654 = ptrtoint ptr %1 to i64
  %655 = sub i64 %652, %654
  %656 = sub i64 %655, %652
  %657 = xor i64 %656, %654
  %658 = or i64 %657, %653
  %659 = sub i64 %658, %652
  %660 = add i64 %659, %653
  store i64 %660, ptr %3, align 8
  br label %389

661:                                              ; preds = %305
  %662 = load i64, ptr %3, align 8
  %663 = zext i32 %0 to i64
  %664 = ptrtoint ptr %1 to i64
  %665 = xor i64 %664, %662
  %666 = xor i64 %665, %664
  %667 = xor i64 %666, %664
  %668 = or i64 %667, %662
  %669 = add i64 %668, %663
  store i64 %669, ptr %3, align 8
  br label %389

670:                                              ; preds = %328
  %671 = load i64, ptr %3, align 8
  %672 = zext i32 %0 to i64
  %673 = ptrtoint ptr %1 to i64
  %674 = sub i64 %673, %671
  %675 = and i64 %674, %673
  %676 = add i64 %675, %673
  %677 = add i64 %676, %671
  %678 = mul i64 %677, %673
  store i64 %678, ptr %3, align 8
  br label %389

679:                                              ; preds = %340
  %680 = load i64, ptr %3, align 8
  %681 = zext i32 %0 to i64
  %682 = ptrtoint ptr %1 to i64
  %683 = xor i64 %682, %680
  %684 = or i64 %683, %680
  %685 = sub i64 %684, %680
  %686 = xor i64 %685, %681
  store i64 %686, ptr %3, align 8
  br label %389

687:                                              ; preds = %354
  %688 = load i64, ptr %3, align 8
  %689 = zext i32 %0 to i64
  %690 = ptrtoint ptr %1 to i64
  %691 = or i64 %690, %690
  %692 = or i64 %691, %690
  %693 = add i64 %692, %688
  %694 = or i64 %693, %690
  store i64 %694, ptr %3, align 8
  br label %389

695:                                              ; preds = %366
  %696 = load i64, ptr %3, align 8
  %697 = zext i32 %0 to i64
  %698 = ptrtoint ptr %1 to i64
  %699 = mul i64 %698, %697
  %700 = and i64 %699, %698
  %701 = sub i64 %700, %696
  %702 = and i64 %701, %696
  %703 = sub i64 %702, %698
  store i64 %703, ptr %3, align 8
  br label %389

704:                                              ; preds = %390
  %705 = load i64, ptr %3, align 8
  %706 = zext i32 %0 to i64
  %707 = ptrtoint ptr %1 to i64
  %708 = and i64 %706, %706
  %709 = mul i64 %708, %705
  %710 = add i64 %709, %706
  store i64 %710, ptr %3, align 8
  br label %15

711:                                              ; preds = %401
  %712 = load i64, ptr %3, align 8
  %713 = zext i32 %0 to i64
  %714 = ptrtoint ptr %1 to i64
  %715 = sub i64 %712, %714
  %716 = xor i64 %715, %712
  %717 = xor i64 %716, %712
  %718 = xor i64 %717, %712
  store i64 %718, ptr %3, align 8
  br label %389

719:                                              ; preds = %414
  %720 = load i64, ptr %3, align 8
  %721 = zext i32 %0 to i64
  %722 = ptrtoint ptr %1 to i64
  %723 = or i64 %721, %720
  %724 = mul i64 %723, %722
  %725 = xor i64 %724, %722
  store i64 %725, ptr %3, align 8
  br label %389

726:                                              ; preds = %427
  %727 = load i64, ptr %3, align 8
  %728 = zext i32 %0 to i64
  %729 = ptrtoint ptr %1 to i64
  %730 = mul i64 %727, %729
  %731 = or i64 %730, %729
  %732 = add i64 %731, %728
  %733 = mul i64 %732, %728
  store i64 %733, ptr %3, align 8
  br label %389

734:                                              ; preds = %447
  %735 = load i64, ptr %3, align 8
  %736 = zext i32 %0 to i64
  %737 = ptrtoint ptr %1 to i64
  %738 = mul i64 %737, %735
  %739 = or i64 %738, %735
  %740 = sub i64 %739, %737
  %741 = sub i64 %740, %736
  %742 = add i64 %741, %737
  store i64 %742, ptr %3, align 8
  br label %389

743:                                              ; preds = %466
  %744 = load i64, ptr %3, align 8
  %745 = zext i32 %0 to i64
  %746 = ptrtoint ptr %1 to i64
  %747 = or i64 %746, %745
  %748 = xor i64 %747, %745
  %749 = xor i64 %748, %745
  %750 = sub i64 %749, %744
  %751 = xor i64 %750, %745
  store i64 %751, ptr %3, align 8
  br label %389

752:                                              ; preds = %479
  %753 = load i64, ptr %3, align 8
  %754 = zext i32 %0 to i64
  %755 = ptrtoint ptr %1 to i64
  %756 = xor i64 %754, %754
  %757 = sub i64 %756, %755
  %758 = or i64 %757, %754
  %759 = and i64 %758, %754
  %760 = or i64 %759, %753
  %761 = sub i64 %760, %755
  store i64 %761, ptr %3, align 8
  br label %389

762:                                              ; preds = %492
  %763 = load i64, ptr %3, align 8
  %764 = zext i32 %0 to i64
  %765 = ptrtoint ptr %1 to i64
  %766 = mul i64 %763, %763
  %767 = and i64 %766, %764
  %768 = mul i64 %767, %763
  %769 = xor i64 %768, %763
  %770 = or i64 %769, %763
  store i64 %770, ptr %3, align 8
  br label %389

771:                                              ; preds = %504
  %772 = load i64, ptr %3, align 8
  %773 = zext i32 %0 to i64
  %774 = ptrtoint ptr %1 to i64
  %775 = mul i64 %772, %773
  %776 = and i64 %775, %772
  %777 = mul i64 %776, %773
  store i64 %777, ptr %3, align 8
  br label %389
}

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #6

declare i32 @getchar() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @atoi(ptr noundef) #6

declare i32 @puts(ptr noundef) #4

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { nounwind }
attributes #8 = { nounwind willreturn memory(none) }
attributes #9 = { nounwind willreturn memory(read) }

!llvm.ident = !{!0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Ubuntu clang version 21.1.8 (++20251221032922+2078da43e25a-1~exp1~20251221153059.70)"}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"PIE Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}

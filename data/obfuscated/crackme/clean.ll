; ModuleID = 'data/obfuscated/crackme/clean.bc'
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
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca [8 x %struct.Node], align 16
  %10 = alloca %union.WordView, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca [3 x ptr], align 16
  %17 = alloca i32, align 4
  %18 = alloca i64, align 8
  %19 = alloca i8, align 1
  %20 = alloca i32, align 4
  %21 = alloca i32, align 4
  %22 = alloca [4 x [4 x i32]], align 16
  %23 = alloca i32, align 4
  %24 = alloca i32, align 4
  %25 = alloca i32, align 4
  %26 = alloca i32, align 4
  %27 = alloca i32, align 4
  %28 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  store i32 %2, ptr %7, align 4
  store volatile i32 -1515870811, ptr %8, align 4
  store i32 322376503, ptr %11, align 4
  store i32 0, ptr %12, align 4
  store i32 0, ptr %13, align 4
  store i32 0, ptr %14, align 4
  store i32 0, ptr %15, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %16, ptr align 16 @__const.big_edge_function.ops, i64 24, i1 false)
  %29 = getelementptr inbounds [8 x %struct.Node], ptr %9, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %29, i8 0, i64 256, i1 false)
  store i32 0, ptr %17, align 4
  br label %30

30:                                               ; preds = %79, %3
  %31 = load i32, ptr %17, align 4
  %32 = icmp slt i32 %31, 8
  br i1 %32, label %33, label %82

33:                                               ; preds = %30
  %34 = load i32, ptr %17, align 4
  %35 = mul i32 %34, 65793
  %36 = add i32 322376503, %35
  %37 = load i32, ptr %17, align 4
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds [8 x %struct.Node], ptr %9, i64 0, i64 %38
  %40 = getelementptr inbounds nuw %struct.Node, ptr %39, i32 0, i32 0
  store i32 %36, ptr %40, align 16
  %41 = load i32, ptr %17, align 4
  %42 = mul i32 %41, 131586
  %43 = sub i32 -559038737, %42
  %44 = load i32, ptr %17, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds [8 x %struct.Node], ptr %9, i64 0, i64 %45
  %47 = getelementptr inbounds nuw %struct.Node, ptr %46, i32 0, i32 1
  store i32 %43, ptr %47, align 4
  %48 = load i32, ptr %17, align 4
  %49 = srem i32 %48, 2
  %50 = icmp eq i32 %49, 0
  br i1 %50, label %51, label %54

51:                                               ; preds = %33
  %52 = load i32, ptr %17, align 4
  %53 = mul nsw i32 %52, 100
  br label %58

54:                                               ; preds = %33
  %55 = load i32, ptr %17, align 4
  %56 = sub nsw i32 0, %55
  %57 = mul nsw i32 %56, 77
  br label %58

58:                                               ; preds = %54, %51
  %59 = phi i32 [ %53, %51 ], [ %57, %54 ]
  %60 = load i32, ptr %17, align 4
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds [8 x %struct.Node], ptr %9, i64 0, i64 %61
  %63 = getelementptr inbounds nuw %struct.Node, ptr %62, i32 0, i32 2
  store i32 %59, ptr %63, align 8
  %64 = load i32, ptr %17, align 4
  %65 = mul nsw i32 %64, 13
  %66 = add nsw i32 %65, 7
  %67 = trunc i32 %66 to i8
  %68 = load i32, ptr %17, align 4
  %69 = sext i32 %68 to i64
  %70 = getelementptr inbounds [8 x %struct.Node], ptr %9, i64 0, i64 %69
  %71 = getelementptr inbounds nuw %struct.Node, ptr %70, i32 0, i32 3
  store i8 %67, ptr %71, align 4
  %72 = load i32, ptr %17, align 4
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds [8 x %struct.Node], ptr %9, i64 0, i64 %73
  %75 = getelementptr inbounds nuw %struct.Node, ptr %74, i32 0, i32 4
  %76 = getelementptr inbounds [16 x i8], ptr %75, i64 0, i64 0
  %77 = load i32, ptr %17, align 4
  %78 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef %76, i64 noundef 16, ptr noundef @.str, i32 noundef %77) #7
  br label %79

79:                                               ; preds = %58
  %80 = load i32, ptr %17, align 4
  %81 = add nsw i32 %80, 1
  store i32 %81, ptr %17, align 4
  br label %30, !llvm.loop !6

82:                                               ; preds = %30
  %83 = load ptr, ptr %5, align 8
  %84 = icmp eq ptr %83, null
  br i1 %84, label %85, label %86

85:                                               ; preds = %82
  store i32 -9999, ptr %4, align 4
  br label %696

86:                                               ; preds = %82
  %87 = load i64, ptr %6, align 8
  %88 = icmp eq i64 %87, 0
  br i1 %88, label %89, label %94

89:                                               ; preds = %86
  %90 = load i32, ptr %7, align 4
  %91 = icmp eq i32 %90, 0
  %92 = zext i1 %91 to i64
  %93 = select i1 %91, i32 0, i32 -1
  store i32 %93, ptr %4, align 4
  br label %696

94:                                               ; preds = %86
  %95 = load i64, ptr %6, align 8
  %96 = icmp ugt i64 %95, 512
  br i1 %96, label %97, label %100

97:                                               ; preds = %94
  store i64 512, ptr %6, align 8
  %98 = load i32, ptr %13, align 4
  %99 = add nsw i32 %98, 123
  store i32 %99, ptr %13, align 4
  br label %100

100:                                              ; preds = %97, %94
  store i64 0, ptr %18, align 8
  br label %101

101:                                              ; preds = %523, %100
  %102 = load i64, ptr %18, align 8
  %103 = load i64, ptr %6, align 8
  %104 = icmp ult i64 %102, %103
  br i1 %104, label %105, label %526

105:                                              ; preds = %101
  %106 = load ptr, ptr %5, align 8
  %107 = load i64, ptr %18, align 8
  %108 = getelementptr inbounds nuw i8, ptr %106, i64 %107
  %109 = load i8, ptr %108, align 1
  store i8 %109, ptr %19, align 1
  %110 = load i8, ptr %19, align 1
  %111 = zext i8 %110 to i32
  %112 = load i32, ptr %12, align 4
  %113 = add i32 %112, %111
  store i32 %113, ptr %12, align 4
  %114 = load i32, ptr %12, align 4
  %115 = load i32, ptr %11, align 4
  %116 = xor i32 %114, %115
  %117 = load i8, ptr %19, align 1
  %118 = zext i8 %117 to i32
  %119 = and i32 %118, 7
  %120 = and i32 %119, 31
  %121 = shl i32 %116, %120
  %122 = load i32, ptr %12, align 4
  %123 = load i32, ptr %11, align 4
  %124 = xor i32 %122, %123
  %125 = load i8, ptr %19, align 1
  %126 = zext i8 %125 to i32
  %127 = and i32 %126, 7
  %128 = and i32 %127, 31
  %129 = sub nsw i32 32, %128
  %130 = lshr i32 %124, %129
  %131 = or i32 %121, %130
  store i32 %131, ptr %12, align 4
  %132 = load i8, ptr %19, align 1
  %133 = zext i8 %132 to i32
  %134 = load i64, ptr %18, align 8
  %135 = urem i64 %134, 4
  %136 = mul i64 %135, 8
  %137 = trunc i64 %136 to i32
  %138 = shl i32 %133, %137
  %139 = load i32, ptr %11, align 4
  %140 = xor i32 %139, %138
  store i32 %140, ptr %11, align 4
  %141 = load i64, ptr %18, align 8
  %142 = load i8, ptr %19, align 1
  %143 = zext i8 %142 to i32
  %144 = load i32, ptr %11, align 4
  %145 = load i32, ptr %12, align 4
  %146 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i64 noundef %141, i32 noundef %143, i32 noundef %144, i32 noundef %145)
  %147 = load i8, ptr %19, align 1
  %148 = zext i8 %147 to i32
  %149 = icmp eq i32 %148, 0
  br i1 %149, label %150, label %155

150:                                              ; preds = %105
  %151 = load i32, ptr %14, align 4
  %152 = xor i32 %151, 16
  store i32 %152, ptr %14, align 4
  %153 = load i32, ptr %13, align 4
  %154 = sub nsw i32 %153, 3
  store i32 %154, ptr %13, align 4
  br label %232

155:                                              ; preds = %105
  %156 = call ptr @__ctype_b_loc() #8
  %157 = load ptr, ptr %156, align 8
  %158 = load i8, ptr %19, align 1
  %159 = zext i8 %158 to i32
  %160 = sext i32 %159 to i64
  %161 = getelementptr inbounds i16, ptr %157, i64 %160
  %162 = load i16, ptr %161, align 2
  %163 = zext i16 %162 to i32
  %164 = and i32 %163, 2048
  %165 = icmp ne i32 %164, 0
  br i1 %165, label %166, label %178

166:                                              ; preds = %155
  %167 = load i8, ptr %19, align 1
  %168 = zext i8 %167 to i32
  %169 = sub nsw i32 %168, 48
  %170 = load i32, ptr %14, align 4
  %171 = add nsw i32 %170, %169
  store i32 %171, ptr %14, align 4
  %172 = load i8, ptr %19, align 1
  %173 = zext i8 %172 to i32
  %174 = sub nsw i32 %173, 48
  %175 = mul nsw i32 %174, 2
  %176 = load i32, ptr %13, align 4
  %177 = add nsw i32 %176, %175
  store i32 %177, ptr %13, align 4
  br label %231

178:                                              ; preds = %155
  %179 = call ptr @__ctype_b_loc() #8
  %180 = load ptr, ptr %179, align 8
  %181 = load i8, ptr %19, align 1
  %182 = zext i8 %181 to i32
  %183 = sext i32 %182 to i64
  %184 = getelementptr inbounds i16, ptr %180, i64 %183
  %185 = load i16, ptr %184, align 2
  %186 = zext i16 %185 to i32
  %187 = and i32 %186, 1024
  %188 = icmp ne i32 %187, 0
  br i1 %188, label %189, label %215

189:                                              ; preds = %178
  %190 = call ptr @__ctype_b_loc() #8
  %191 = load ptr, ptr %190, align 8
  %192 = load i8, ptr %19, align 1
  %193 = zext i8 %192 to i32
  %194 = sext i32 %193 to i64
  %195 = getelementptr inbounds i16, ptr %191, i64 %194
  %196 = load i16, ptr %195, align 2
  %197 = zext i16 %196 to i32
  %198 = and i32 %197, 256
  %199 = icmp ne i32 %198, 0
  br i1 %199, label %200, label %207

200:                                              ; preds = %189
  %201 = load i8, ptr %19, align 1
  %202 = zext i8 %201 to i32
  %203 = load i32, ptr %13, align 4
  %204 = add nsw i32 %203, %202
  store i32 %204, ptr %13, align 4
  %205 = load i32, ptr %14, align 4
  %206 = xor i32 %205, 32
  store i32 %206, ptr %14, align 4
  br label %214

207:                                              ; preds = %189
  %208 = load i8, ptr %19, align 1
  %209 = zext i8 %208 to i32
  %210 = load i32, ptr %13, align 4
  %211 = sub nsw i32 %210, %209
  store i32 %211, ptr %13, align 4
  %212 = load i32, ptr %14, align 4
  %213 = xor i32 %212, 64
  store i32 %213, ptr %14, align 4
  br label %214

214:                                              ; preds = %207, %200
  br label %230

215:                                              ; preds = %178
  %216 = load i8, ptr %19, align 1
  %217 = zext i8 %216 to i32
  %218 = icmp eq i32 %217, 255
  br i1 %218, label %219, label %222

219:                                              ; preds = %215
  store i32 1, ptr %15, align 4
  %220 = load i32, ptr %13, align 4
  %221 = xor i32 %220, -1
  store i32 %221, ptr %13, align 4
  br label %229

222:                                              ; preds = %215
  %223 = load i8, ptr %19, align 1
  %224 = zext i8 %223 to i32
  %225 = xor i32 %224, 90
  %226 = and i32 %225, 127
  %227 = load i32, ptr %13, align 4
  %228 = add nsw i32 %227, %226
  store i32 %228, ptr %13, align 4
  br label %229

229:                                              ; preds = %222, %219
  br label %230

230:                                              ; preds = %229, %214
  br label %231

231:                                              ; preds = %230, %166
  br label %232

232:                                              ; preds = %231, %150
  %233 = load i8, ptr %19, align 1
  %234 = zext i8 %233 to i32
  %235 = load i32, ptr %7, align 4
  %236 = add nsw i32 %234, %235
  %237 = sext i32 %236 to i64
  %238 = load i64, ptr %18, align 8
  %239 = add i64 %237, %238
  %240 = and i64 %239, 15
  switch i64 %240, label %468 [
    i64 0, label %241
    i64 1, label %249
    i64 2, label %257
    i64 3, label %265
    i64 4, label %274
    i64 5, label %289
    i64 6, label %308
    i64 7, label %321
    i64 8, label %327
    i64 9, label %342
    i64 10, label %357
    i64 11, label %411
    i64 12, label %433
    i64 13, label %441
    i64 14, label %460
    i64 15, label %467
  ]

241:                                              ; preds = %232
  %242 = load i64, ptr %18, align 8
  %243 = and i64 %242, 7
  %244 = getelementptr inbounds nuw [8 x %struct.Node], ptr %9, i64 0, i64 %243
  %245 = getelementptr inbounds nuw %struct.Node, ptr %244, i32 0, i32 0
  %246 = load i32, ptr %245, align 16
  %247 = load i32, ptr %11, align 4
  %248 = add i32 %247, %246
  store i32 %248, ptr %11, align 4
  br label %474

249:                                              ; preds = %232
  %250 = load i64, ptr %18, align 8
  %251 = and i64 %250, 7
  %252 = getelementptr inbounds nuw [8 x %struct.Node], ptr %9, i64 0, i64 %251
  %253 = getelementptr inbounds nuw %struct.Node, ptr %252, i32 0, i32 1
  %254 = load i32, ptr %253, align 4
  %255 = load i32, ptr %11, align 4
  %256 = xor i32 %255, %254
  store i32 %256, ptr %11, align 4
  br label %474

257:                                              ; preds = %232
  %258 = load i64, ptr %18, align 8
  %259 = and i64 %258, 7
  %260 = getelementptr inbounds nuw [8 x %struct.Node], ptr %9, i64 0, i64 %259
  %261 = getelementptr inbounds nuw %struct.Node, ptr %260, i32 0, i32 2
  %262 = load i32, ptr %261, align 8
  %263 = load i32, ptr %13, align 4
  %264 = add nsw i32 %263, %262
  store i32 %264, ptr %13, align 4
  br label %474

265:                                              ; preds = %232
  %266 = load i64, ptr %18, align 8
  %267 = and i64 %266, 7
  %268 = getelementptr inbounds nuw [8 x %struct.Node], ptr %9, i64 0, i64 %267
  %269 = getelementptr inbounds nuw %struct.Node, ptr %268, i32 0, i32 3
  %270 = load i8, ptr %269, align 4
  %271 = zext i8 %270 to i32
  %272 = load i32, ptr %13, align 4
  %273 = sub nsw i32 %272, %271
  store i32 %273, ptr %13, align 4
  br label %474

274:                                              ; preds = %232
  %275 = load i32, ptr %11, align 4
  %276 = load i8, ptr %19, align 1
  %277 = zext i8 %276 to i32
  %278 = and i32 %277, 31
  %279 = and i32 %278, 31
  %280 = shl i32 %275, %279
  %281 = load i32, ptr %11, align 4
  %282 = load i8, ptr %19, align 1
  %283 = zext i8 %282 to i32
  %284 = and i32 %283, 31
  %285 = and i32 %284, 31
  %286 = sub nsw i32 32, %285
  %287 = lshr i32 %281, %286
  %288 = or i32 %280, %287
  store i32 %288, ptr %11, align 4
  br label %474

289:                                              ; preds = %232
  %290 = load i32, ptr %11, align 4
  %291 = load i8, ptr %19, align 1
  %292 = zext i8 %291 to i32
  %293 = load i32, ptr %7, align 4
  %294 = xor i32 %292, %293
  %295 = and i32 %294, 31
  %296 = and i32 %295, 31
  %297 = lshr i32 %290, %296
  %298 = load i32, ptr %11, align 4
  %299 = load i8, ptr %19, align 1
  %300 = zext i8 %299 to i32
  %301 = load i32, ptr %7, align 4
  %302 = xor i32 %300, %301
  %303 = and i32 %302, 31
  %304 = and i32 %303, 31
  %305 = sub nsw i32 32, %304
  %306 = shl i32 %298, %305
  %307 = or i32 %297, %306
  store i32 %307, ptr %11, align 4
  br label %474

308:                                              ; preds = %232
  %309 = load i8, ptr %19, align 1
  %310 = zext i8 %309 to i32
  %311 = srem i32 %310, 3
  %312 = sext i32 %311 to i64
  %313 = getelementptr inbounds [3 x ptr], ptr %16, i64 0, i64 %312
  %314 = load ptr, ptr %313, align 8
  %315 = load i32, ptr %13, align 4
  %316 = load i8, ptr %19, align 1
  %317 = zext i8 %316 to i32
  %318 = call i32 %314(i32 noundef %315, i32 noundef %317)
  %319 = load i32, ptr %13, align 4
  %320 = add nsw i32 %319, %318
  store i32 %320, ptr %13, align 4
  br label %474

321:                                              ; preds = %232
  %322 = load i32, ptr %11, align 4
  %323 = load i32, ptr %12, align 4
  %324 = call i32 @helper_mix(i32 noundef %322, i32 noundef %323)
  %325 = load i32, ptr %13, align 4
  %326 = xor i32 %325, %324
  store i32 %326, ptr %13, align 4
  br label %474

327:                                              ; preds = %232
  %328 = load i32, ptr %11, align 4
  %329 = and i32 %328, 1
  %330 = icmp ne i32 %329, 0
  br i1 %330, label %331, label %338

331:                                              ; preds = %327
  %332 = load i32, ptr %12, align 4
  %333 = and i32 %332, 2
  %334 = icmp ne i32 %333, 0
  br i1 %334, label %335, label %338

335:                                              ; preds = %331
  %336 = load i32, ptr %13, align 4
  %337 = add nsw i32 %336, 77
  store i32 %337, ptr %13, align 4
  br label %341

338:                                              ; preds = %331, %327
  %339 = load i32, ptr %13, align 4
  %340 = sub nsw i32 %339, 88
  store i32 %340, ptr %13, align 4
  br label %341

341:                                              ; preds = %338, %335
  br label %474

342:                                              ; preds = %232
  %343 = load i32, ptr %12, align 4
  %344 = load i64, ptr %18, align 8
  %345 = and i64 %344, 7
  %346 = getelementptr inbounds nuw [8 x %struct.Node], ptr %9, i64 0, i64 %345
  %347 = getelementptr inbounds nuw %struct.Node, ptr %346, i32 0, i32 0
  %348 = load i32, ptr %347, align 16
  %349 = xor i32 %348, %343
  store i32 %349, ptr %347, align 16
  %350 = load i32, ptr %11, align 4
  %351 = load i64, ptr %18, align 8
  %352 = and i64 %351, 7
  %353 = getelementptr inbounds nuw [8 x %struct.Node], ptr %9, i64 0, i64 %352
  %354 = getelementptr inbounds nuw %struct.Node, ptr %353, i32 0, i32 1
  %355 = load i32, ptr %354, align 4
  %356 = add i32 %355, %350
  store i32 %356, ptr %354, align 4
  br label %474

357:                                              ; preds = %232
  %358 = load i64, ptr %18, align 8
  %359 = add i64 %358, 3
  %360 = load i64, ptr %6, align 8
  %361 = icmp ult i64 %359, %360
  br i1 %361, label %362, label %410

362:                                              ; preds = %357
  %363 = load ptr, ptr %5, align 8
  %364 = load i64, ptr %18, align 8
  %365 = getelementptr inbounds nuw i8, ptr %363, i64 %364
  %366 = load i8, ptr %365, align 1
  %367 = zext i8 %366 to i32
  %368 = load ptr, ptr %5, align 8
  %369 = load i64, ptr %18, align 8
  %370 = add i64 %369, 1
  %371 = getelementptr inbounds nuw i8, ptr %368, i64 %370
  %372 = load i8, ptr %371, align 1
  %373 = zext i8 %372 to i32
  %374 = shl i32 %373, 8
  %375 = or i32 %367, %374
  %376 = load ptr, ptr %5, align 8
  %377 = load i64, ptr %18, align 8
  %378 = add i64 %377, 2
  %379 = getelementptr inbounds nuw i8, ptr %376, i64 %378
  %380 = load i8, ptr %379, align 1
  %381 = zext i8 %380 to i32
  %382 = shl i32 %381, 16
  %383 = or i32 %375, %382
  %384 = load ptr, ptr %5, align 8
  %385 = load i64, ptr %18, align 8
  %386 = add i64 %385, 3
  %387 = getelementptr inbounds nuw i8, ptr %384, i64 %386
  %388 = load i8, ptr %387, align 1
  %389 = zext i8 %388 to i32
  %390 = shl i32 %389, 24
  %391 = or i32 %383, %390
  store i32 %391, ptr %20, align 4
  %392 = load i32, ptr %20, align 4
  store i32 %392, ptr %10, align 4
  %393 = load i32, ptr %10, align 4
  %394 = icmp slt i32 %393, 0
  br i1 %394, label %395, label %401

395:                                              ; preds = %362
  %396 = load i32, ptr %15, align 4
  %397 = add nsw i32 %396, 1
  store i32 %397, ptr %15, align 4
  %398 = load i32, ptr %10, align 4
  %399 = load i32, ptr %13, align 4
  %400 = sub nsw i32 %399, %398
  store i32 %400, ptr %13, align 4
  br label %406

401:                                              ; preds = %362
  %402 = load i32, ptr %10, align 4
  %403 = and i32 %402, 65535
  %404 = load i32, ptr %13, align 4
  %405 = add nsw i32 %404, %403
  store i32 %405, ptr %13, align 4
  br label %406

406:                                              ; preds = %401, %395
  %407 = load i32, ptr %10, align 4
  %408 = load i32, ptr %11, align 4
  %409 = xor i32 %408, %407
  store i32 %409, ptr %11, align 4
  br label %410

410:                                              ; preds = %406, %357
  br label %474

411:                                              ; preds = %232
  store i32 0, ptr %21, align 4
  br label %412

412:                                              ; preds = %429, %411
  %413 = load i32, ptr %21, align 4
  %414 = icmp slt i32 %413, 4
  br i1 %414, label %415, label %432

415:                                              ; preds = %412
  %416 = load i8, ptr %19, align 1
  %417 = zext i8 %416 to i32
  %418 = load i32, ptr %21, align 4
  %419 = add nsw i32 %418, 1
  %420 = mul nsw i32 %417, %419
  %421 = load i32, ptr %11, align 4
  %422 = add i32 %421, %420
  store i32 %422, ptr %11, align 4
  %423 = load i32, ptr %11, align 4
  %424 = load i32, ptr %21, align 4
  %425 = mul nsw i32 %424, 3
  %426 = lshr i32 %423, %425
  %427 = load i32, ptr %13, align 4
  %428 = xor i32 %427, %426
  store i32 %428, ptr %13, align 4
  br label %429

429:                                              ; preds = %415
  %430 = load i32, ptr %21, align 4
  %431 = add nsw i32 %430, 1
  store i32 %431, ptr %21, align 4
  br label %412, !llvm.loop !8

432:                                              ; preds = %412
  br label %474

433:                                              ; preds = %232
  %434 = load i8, ptr %19, align 1
  %435 = zext i8 %434 to i32
  %436 = icmp eq i32 %435, 88
  br i1 %436, label %437, label %438

437:                                              ; preds = %433
  br label %495

438:                                              ; preds = %433
  %439 = load i32, ptr %13, align 4
  %440 = add nsw i32 %439, 12
  store i32 %440, ptr %13, align 4
  br label %474

441:                                              ; preds = %232
  %442 = load i32, ptr %7, align 4
  %443 = and i32 %442, 1
  %444 = icmp eq i32 %443, 0
  br i1 %444, label %445, label %452

445:                                              ; preds = %441
  %446 = load i8, ptr %19, align 1
  %447 = zext i8 %446 to i32
  %448 = load i32, ptr %7, align 4
  %449 = call i32 @helper_muladd(i32 noundef %447, i32 noundef %448)
  %450 = load i32, ptr %13, align 4
  %451 = add nsw i32 %450, %449
  store i32 %451, ptr %13, align 4
  br label %459

452:                                              ; preds = %441
  %453 = load i8, ptr %19, align 1
  %454 = zext i8 %453 to i32
  %455 = load i32, ptr %7, align 4
  %456 = call i32 @helper_xor(i32 noundef %454, i32 noundef %455)
  %457 = load i32, ptr %13, align 4
  %458 = sub nsw i32 %457, %456
  store i32 %458, ptr %13, align 4
  br label %459

459:                                              ; preds = %452, %445
  br label %474

460:                                              ; preds = %232
  %461 = load i32, ptr %11, align 4
  %462 = xor i32 %461, -1
  store i32 %462, ptr %11, align 4
  %463 = load i32, ptr %11, align 4
  %464 = and i32 %463, 255
  %465 = load i32, ptr %13, align 4
  %466 = add nsw i32 %465, %464
  store i32 %466, ptr %13, align 4
  br label %474

467:                                              ; preds = %232
  br label %468

468:                                              ; preds = %232, %467
  %469 = load i32, ptr %12, align 4
  %470 = load i32, ptr %11, align 4
  %471 = or i32 %469, %470
  %472 = load i32, ptr %13, align 4
  %473 = xor i32 %472, %471
  store i32 %473, ptr %13, align 4
  br label %474

474:                                              ; preds = %468, %460, %459, %438, %432, %410, %342, %341, %321, %308, %289, %274, %265, %257, %249, %241
  %475 = load i32, ptr %13, align 4
  %476 = and i32 %475, 4660
  %477 = icmp eq i32 %476, 4608
  br i1 %477, label %478, label %483

478:                                              ; preds = %474
  %479 = load i32, ptr %7, align 4
  %480 = mul nsw i32 %479, 17
  %481 = load i32, ptr %13, align 4
  %482 = add nsw i32 %481, %480
  store i32 %482, ptr %13, align 4
  br label %483

483:                                              ; preds = %478, %474
  %484 = load i32, ptr %11, align 4
  %485 = load i32, ptr %12, align 4
  %486 = xor i32 %484, %485
  %487 = icmp eq i32 %486, -889275714
  br i1 %487, label %488, label %491

488:                                              ; preds = %483
  %489 = load i32, ptr %13, align 4
  %490 = add nsw i32 %489, 100000
  store i32 %490, ptr %13, align 4
  br label %491

491:                                              ; preds = %488, %483
  %492 = load i64, ptr %18, align 8
  %493 = load i32, ptr %13, align 4
  %494 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i64 noundef %492, i32 noundef %493)
  br label %523

495:                                              ; preds = %437
  %496 = load i32, ptr %13, align 4
  %497 = add nsw i32 %496, 4242
  store i32 %497, ptr %13, align 4
  %498 = load i32, ptr %11, align 4
  %499 = xor i32 %498, 1482184792
  store i32 %499, ptr %11, align 4
  %500 = load i64, ptr %18, align 8
  %501 = add i64 %500, 1
  %502 = load i64, ptr %6, align 8
  %503 = icmp ult i64 %501, %502
  br i1 %503, label %504, label %517

504:                                              ; preds = %495
  %505 = load ptr, ptr %5, align 8
  %506 = load i64, ptr %18, align 8
  %507 = add i64 %506, 1
  %508 = getelementptr inbounds nuw i8, ptr %505, i64 %507
  %509 = load i8, ptr %508, align 1
  %510 = zext i8 %509 to i32
  %511 = icmp eq i32 %510, 89
  br i1 %511, label %512, label %517

512:                                              ; preds = %504
  %513 = load i32, ptr %13, align 4
  %514 = add nsw i32 %513, 31337
  store i32 %514, ptr %13, align 4
  %515 = load i32, ptr %14, align 4
  %516 = or i32 %515, 256
  store i32 %516, ptr %14, align 4
  br label %522

517:                                              ; preds = %504, %495
  %518 = load i32, ptr %13, align 4
  %519 = sub nsw i32 %518, 1337
  store i32 %519, ptr %13, align 4
  %520 = load i32, ptr %14, align 4
  %521 = and i32 %520, -257
  store i32 %521, ptr %14, align 4
  br label %522

522:                                              ; preds = %517, %512
  br label %523

523:                                              ; preds = %522, %491
  %524 = load i64, ptr %18, align 8
  %525 = add i64 %524, 1
  store i64 %525, ptr %18, align 8
  br label %101, !llvm.loop !9

526:                                              ; preds = %101
  store i32 0, ptr %23, align 4
  br label %527

527:                                              ; preds = %572, %526
  %528 = load i32, ptr %23, align 4
  %529 = icmp slt i32 %528, 4
  br i1 %529, label %530, label %575

530:                                              ; preds = %527
  store i32 0, ptr %24, align 4
  br label %531

531:                                              ; preds = %568, %530
  %532 = load i32, ptr %24, align 4
  %533 = icmp slt i32 %532, 4
  br i1 %533, label %534, label %571

534:                                              ; preds = %531
  %535 = load i32, ptr %23, align 4
  %536 = load i32, ptr %24, align 4
  %537 = mul nsw i32 %535, %536
  %538 = load i32, ptr %13, align 4
  %539 = add nsw i32 %537, %538
  %540 = load i32, ptr %14, align 4
  %541 = add nsw i32 %539, %540
  store i32 %541, ptr %25, align 4
  %542 = load i32, ptr %23, align 4
  %543 = load i32, ptr %24, align 4
  %544 = add nsw i32 %542, %543
  %545 = and i32 %544, 1
  %546 = icmp ne i32 %545, 0
  br i1 %546, label %547, label %557

547:                                              ; preds = %534
  %548 = load i32, ptr %25, align 4
  %549 = load i32, ptr %11, align 4
  %550 = xor i32 %548, %549
  %551 = load i32, ptr %23, align 4
  %552 = sext i32 %551 to i64
  %553 = getelementptr inbounds [4 x [4 x i32]], ptr %22, i64 0, i64 %552
  %554 = load i32, ptr %24, align 4
  %555 = sext i32 %554 to i64
  %556 = getelementptr inbounds [4 x i32], ptr %553, i64 0, i64 %555
  store i32 %550, ptr %556, align 4
  br label %567

557:                                              ; preds = %534
  %558 = load i32, ptr %25, align 4
  %559 = load i32, ptr %12, align 4
  %560 = add nsw i32 %558, %559
  %561 = load i32, ptr %23, align 4
  %562 = sext i32 %561 to i64
  %563 = getelementptr inbounds [4 x [4 x i32]], ptr %22, i64 0, i64 %562
  %564 = load i32, ptr %24, align 4
  %565 = sext i32 %564 to i64
  %566 = getelementptr inbounds [4 x i32], ptr %563, i64 0, i64 %565
  store i32 %560, ptr %566, align 4
  br label %567

567:                                              ; preds = %557, %547
  br label %568

568:                                              ; preds = %567
  %569 = load i32, ptr %24, align 4
  %570 = add nsw i32 %569, 1
  store i32 %570, ptr %24, align 4
  br label %531, !llvm.loop !10

571:                                              ; preds = %531
  br label %572

572:                                              ; preds = %571
  %573 = load i32, ptr %23, align 4
  %574 = add nsw i32 %573, 1
  store i32 %574, ptr %23, align 4
  br label %527, !llvm.loop !11

575:                                              ; preds = %527
  store i32 0, ptr %26, align 4
  br label %576

576:                                              ; preds = %627, %575
  %577 = load i32, ptr %26, align 4
  %578 = icmp slt i32 %577, 16
  br i1 %578, label %579, label %630

579:                                              ; preds = %576
  %580 = load i32, ptr %26, align 4
  %581 = sdiv i32 %580, 4
  store i32 %581, ptr %27, align 4
  %582 = load i32, ptr %26, align 4
  %583 = srem i32 %582, 4
  store i32 %583, ptr %28, align 4
  %584 = load i32, ptr %27, align 4
  %585 = sext i32 %584 to i64
  %586 = getelementptr inbounds [4 x [4 x i32]], ptr %22, i64 0, i64 %585
  %587 = load i32, ptr %28, align 4
  %588 = sext i32 %587 to i64
  %589 = getelementptr inbounds [4 x i32], ptr %586, i64 0, i64 %588
  %590 = load i32, ptr %589, align 4
  %591 = icmp slt i32 %590, 0
  br i1 %591, label %592, label %602

592:                                              ; preds = %579
  %593 = load i32, ptr %27, align 4
  %594 = sext i32 %593 to i64
  %595 = getelementptr inbounds [4 x [4 x i32]], ptr %22, i64 0, i64 %594
  %596 = load i32, ptr %28, align 4
  %597 = sext i32 %596 to i64
  %598 = getelementptr inbounds [4 x i32], ptr %595, i64 0, i64 %597
  %599 = load i32, ptr %598, align 4
  %600 = load i32, ptr %13, align 4
  %601 = sub nsw i32 %600, %599
  store i32 %601, ptr %13, align 4
  br label %626

602:                                              ; preds = %579
  %603 = load i32, ptr %27, align 4
  %604 = sext i32 %603 to i64
  %605 = getelementptr inbounds [4 x [4 x i32]], ptr %22, i64 0, i64 %604
  %606 = load i32, ptr %28, align 4
  %607 = sext i32 %606 to i64
  %608 = getelementptr inbounds [4 x i32], ptr %605, i64 0, i64 %607
  %609 = load i32, ptr %608, align 4
  %610 = icmp eq i32 %609, 0
  br i1 %610, label %611, label %614

611:                                              ; preds = %602
  %612 = load i32, ptr %13, align 4
  %613 = xor i32 %612, 30583
  store i32 %613, ptr %13, align 4
  br label %625

614:                                              ; preds = %602
  %615 = load i32, ptr %27, align 4
  %616 = sext i32 %615 to i64
  %617 = getelementptr inbounds [4 x [4 x i32]], ptr %22, i64 0, i64 %616
  %618 = load i32, ptr %28, align 4
  %619 = sext i32 %618 to i64
  %620 = getelementptr inbounds [4 x i32], ptr %617, i64 0, i64 %619
  %621 = load i32, ptr %620, align 4
  %622 = and i32 %621, 1023
  %623 = load i32, ptr %13, align 4
  %624 = add nsw i32 %623, %622
  store i32 %624, ptr %13, align 4
  br label %625

625:                                              ; preds = %614, %611
  br label %626

626:                                              ; preds = %625, %592
  br label %627

627:                                              ; preds = %626
  %628 = load i32, ptr %26, align 4
  %629 = add nsw i32 %628, 1
  store i32 %629, ptr %26, align 4
  br label %576, !llvm.loop !12

630:                                              ; preds = %576
  %631 = load i32, ptr %7, align 4
  %632 = icmp slt i32 %631, -1000
  br i1 %632, label %633, label %636

633:                                              ; preds = %630
  %634 = load i32, ptr %7, align 4
  %635 = add nsw i32 -2147483648, %634
  store i32 %635, ptr %13, align 4
  br label %677

636:                                              ; preds = %630
  %637 = load i32, ptr %7, align 4
  %638 = icmp sgt i32 %637, 1000
  br i1 %638, label %639, label %642

639:                                              ; preds = %636
  %640 = load i32, ptr %7, align 4
  %641 = sub nsw i32 2147483647, %640
  store i32 %641, ptr %13, align 4
  br label %676

642:                                              ; preds = %636
  %643 = load i32, ptr %7, align 4
  switch i32 %643, label %669 [
    i32 -3, label %644
    i32 -2, label %647
    i32 -1, label %652
    i32 0, label %657
    i32 1, label %660
    i32 2, label %663
    i32 3, label %666
  ]

644:                                              ; preds = %642
  %645 = load i32, ptr %13, align 4
  %646 = xor i32 %645, 858993459
  store i32 %646, ptr %13, align 4
  br label %675

647:                                              ; preds = %642
  %648 = load i32, ptr %11, align 4
  %649 = lshr i32 %648, 16
  %650 = load i32, ptr %13, align 4
  %651 = add nsw i32 %650, %649
  store i32 %651, ptr %13, align 4
  br label %675

652:                                              ; preds = %642
  %653 = load i32, ptr %12, align 4
  %654 = and i32 %653, 65535
  %655 = load i32, ptr %13, align 4
  %656 = sub nsw i32 %655, %654
  store i32 %656, ptr %13, align 4
  br label %675

657:                                              ; preds = %642
  %658 = load i32, ptr %13, align 4
  %659 = add nsw i32 %658, 1
  store i32 %659, ptr %13, align 4
  br label %675

660:                                              ; preds = %642
  %661 = load i32, ptr %13, align 4
  %662 = mul nsw i32 %661, 3
  store i32 %662, ptr %13, align 4
  br label %675

663:                                              ; preds = %642
  %664 = load i32, ptr %13, align 4
  %665 = sdiv i32 %664, 2
  store i32 %665, ptr %13, align 4
  br label %675

666:                                              ; preds = %642
  %667 = load i32, ptr %13, align 4
  %668 = srem i32 %667, 9973
  store i32 %668, ptr %13, align 4
  br label %675

669:                                              ; preds = %642
  %670 = load i32, ptr %7, align 4
  %671 = load i32, ptr %7, align 4
  %672 = mul nsw i32 %670, %671
  %673 = load i32, ptr %13, align 4
  %674 = add nsw i32 %673, %672
  store i32 %674, ptr %13, align 4
  br label %675

675:                                              ; preds = %669, %666, %663, %660, %657, %652, %647, %644
  br label %676

676:                                              ; preds = %675, %639
  br label %677

677:                                              ; preds = %676, %633
  %678 = load i32, ptr %15, align 4
  %679 = icmp ne i32 %678, 0
  br i1 %679, label %680, label %683

680:                                              ; preds = %677
  %681 = load i32, ptr %13, align 4
  %682 = xor i32 %681, 1094795585
  store i32 %682, ptr %13, align 4
  br label %683

683:                                              ; preds = %680, %677
  %684 = load volatile i32, ptr %8, align 4
  %685 = xor i32 %684, -1515870811
  %686 = icmp ne i32 %685, 0
  br i1 %686, label %687, label %688

687:                                              ; preds = %683
  store i32 -8888, ptr %4, align 4
  br label %696

688:                                              ; preds = %683
  %689 = load i32, ptr %13, align 4
  %690 = load i32, ptr %11, align 4
  %691 = load i32, ptr %12, align 4
  %692 = add i32 %690, %691
  %693 = load i32, ptr %14, align 4
  %694 = add i32 %692, %693
  %695 = xor i32 %689, %694
  store i32 %695, ptr %4, align 4
  br label %696

696:                                              ; preds = %688, %687, %89, %85
  %697 = load i32, ptr %4, align 4
  ret i32 %697
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
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %7

7:                                                ; preds = %31, %2
  %8 = load i32, ptr %6, align 4
  %9 = icmp slt i32 %8, 8
  br i1 %9, label %10, label %34

10:                                               ; preds = %7
  %11 = load i32, ptr %3, align 4
  %12 = load i32, ptr %6, align 4
  %13 = ashr i32 %11, %12
  %14 = and i32 %13, 1
  %15 = icmp ne i32 %14, 0
  br i1 %15, label %16, label %23

16:                                               ; preds = %10
  %17 = load i32, ptr %4, align 4
  %18 = load i32, ptr %6, align 4
  %19 = mul nsw i32 %18, 17
  %20 = xor i32 %17, %19
  %21 = load i32, ptr %5, align 4
  %22 = add nsw i32 %21, %20
  store i32 %22, ptr %5, align 4
  br label %30

23:                                               ; preds = %10
  %24 = load i32, ptr %3, align 4
  %25 = load i32, ptr %6, align 4
  %26 = mul nsw i32 %25, 23
  %27 = xor i32 %24, %26
  %28 = load i32, ptr %5, align 4
  %29 = sub nsw i32 %28, %27
  store i32 %29, ptr %5, align 4
  br label %30

30:                                               ; preds = %23, %16
  br label %31

31:                                               ; preds = %30
  %32 = load i32, ptr %6, align 4
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %6, align 4
  br label %7, !llvm.loop !13

34:                                               ; preds = %7
  %35 = load i32, ptr %5, align 4
  ret i32 %35
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
  %8 = xor i32 %7, 21930
  %9 = add nsw i32 %6, %8
  ret i32 %9
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @helper_xor(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = xor i32 %5, %6
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr %4, align 4
  %10 = and i32 %8, %9
  %11 = shl i32 %10, 1
  %12 = sub nsw i32 %7, %11
  ret i32 %12
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca [512 x i8], align 16
  %7 = alloca i64, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  store i32 0, ptr %3, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  store i64 0, ptr %7, align 8
  store i32 0, ptr %8, align 4
  store i32 0, ptr %9, align 4
  %12 = getelementptr inbounds [512 x i8], ptr %6, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %12, i8 0, i64 512, i1 false)
  %13 = load i32, ptr %4, align 4
  %14 = icmp sgt i32 %13, 1
  br i1 %14, label %15, label %28

15:                                               ; preds = %2
  %16 = load ptr, ptr %5, align 8
  %17 = getelementptr inbounds ptr, ptr %16, i64 1
  %18 = load ptr, ptr %17, align 8
  store ptr %18, ptr %10, align 8
  %19 = load ptr, ptr %10, align 8
  %20 = call i64 @strlen(ptr noundef %19) #9
  store i64 %20, ptr %7, align 8
  %21 = load i64, ptr %7, align 8
  %22 = icmp ugt i64 %21, 512
  br i1 %22, label %23, label %24

23:                                               ; preds = %15
  store i64 512, ptr %7, align 8
  br label %24

24:                                               ; preds = %23, %15
  %25 = getelementptr inbounds [512 x i8], ptr %6, i64 0, i64 0
  %26 = load ptr, ptr %10, align 8
  %27 = load i64, ptr %7, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %25, ptr align 1 %26, i64 %27, i1 false)
  br label %44

28:                                               ; preds = %2
  br label %29

29:                                               ; preds = %37, %28
  %30 = call i32 @getchar()
  store i32 %30, ptr %11, align 4
  %31 = icmp ne i32 %30, -1
  br i1 %31, label %32, label %35

32:                                               ; preds = %29
  %33 = load i64, ptr %7, align 8
  %34 = icmp ult i64 %33, 512
  br label %35

35:                                               ; preds = %32, %29
  %36 = phi i1 [ false, %29 ], [ %34, %32 ]
  br i1 %36, label %37, label %43

37:                                               ; preds = %35
  %38 = load i32, ptr %11, align 4
  %39 = trunc i32 %38 to i8
  %40 = load i64, ptr %7, align 8
  %41 = add i64 %40, 1
  store i64 %41, ptr %7, align 8
  %42 = getelementptr inbounds nuw [512 x i8], ptr %6, i64 0, i64 %40
  store i8 %39, ptr %42, align 1
  br label %29, !llvm.loop !14

43:                                               ; preds = %35
  br label %44

44:                                               ; preds = %43, %24
  %45 = load i32, ptr %4, align 4
  %46 = icmp sgt i32 %45, 2
  br i1 %46, label %47, label %52

47:                                               ; preds = %44
  %48 = load ptr, ptr %5, align 8
  %49 = getelementptr inbounds ptr, ptr %48, i64 2
  %50 = load ptr, ptr %49, align 8
  %51 = call i32 @atoi(ptr noundef %50) #9
  store i32 %51, ptr %8, align 4
  br label %57

52:                                               ; preds = %44
  %53 = load i64, ptr %7, align 8
  %54 = urem i64 %53, 7
  %55 = trunc i64 %54 to i32
  %56 = sub nsw i32 %55, 3
  store i32 %56, ptr %8, align 4
  br label %57

57:                                               ; preds = %52, %47
  %58 = load i64, ptr %7, align 8
  %59 = call i32 (ptr, ...) @printf(ptr noundef @.str.3, i64 noundef %58)
  %60 = load i32, ptr %8, align 4
  %61 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i32 noundef %60)
  %62 = getelementptr inbounds [512 x i8], ptr %6, i64 0, i64 0
  %63 = load i64, ptr %7, align 8
  %64 = load i32, ptr %8, align 4
  %65 = call i32 @big_edge_function(ptr noundef %62, i64 noundef %63, i32 noundef %64)
  store i32 %65, ptr %9, align 4
  %66 = load i32, ptr %9, align 4
  %67 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %66)
  %68 = load i32, ptr %9, align 4
  %69 = icmp eq i32 %68, 305419896
  br i1 %69, label %70, label %72

70:                                               ; preds = %57
  %71 = call i32 @puts(ptr noundef @.str.6)
  store i32 10, ptr %3, align 4
  br label %90

72:                                               ; preds = %57
  %73 = load i32, ptr %9, align 4
  %74 = and i32 %73, 65535
  %75 = icmp eq i32 %74, 48879
  br i1 %75, label %76, label %78

76:                                               ; preds = %72
  %77 = call i32 @puts(ptr noundef @.str.7)
  store i32 20, ptr %3, align 4
  br label %90

78:                                               ; preds = %72
  %79 = load i32, ptr %9, align 4
  %80 = icmp slt i32 %79, 0
  br i1 %80, label %81, label %83

81:                                               ; preds = %78
  %82 = call i32 @puts(ptr noundef @.str.8)
  store i32 1, ptr %3, align 4
  br label %90

83:                                               ; preds = %78
  %84 = load i32, ptr %9, align 4
  %85 = icmp eq i32 %84, 0
  br i1 %85, label %86, label %88

86:                                               ; preds = %83
  %87 = call i32 @puts(ptr noundef @.str.9)
  store i32 2, ptr %3, align 4
  br label %90

88:                                               ; preds = %83
  %89 = call i32 @puts(ptr noundef @.str.10)
  store i32 0, ptr %3, align 4
  br label %90

90:                                               ; preds = %88, %86, %81, %76, %70
  %91 = load i32, ptr %3, align 4
  ret i32 %91
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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
!14 = distinct !{!14, !7}

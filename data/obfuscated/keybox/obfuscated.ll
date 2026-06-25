; ModuleID = 'data/obfuscated/keybox/obfuscated.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@stderr = external global ptr, align 8
@.str = private unnamed_addr constant [17 x i8] c"usage: %s <key>\0A\00", align 1
@.str.1 = private unnamed_addr constant [13 x i8] c"OK: accepted\00", align 1
@.str.2 = private unnamed_addr constant [13 x i8] c"NO: rejected\00", align 1
@print_banner.enc = internal constant [16 x i8] c"\09\04\00F\12\07\14\01\03\12F\14\03\07\02\1F", align 16
@validate_key.stages = internal global [4 x ptr] [ptr @check_shape, ptr @check_table, ptr @check_hash, ptr @check_heap_stack], align 16
@g_box = internal constant [64 x i8] c"c|w{\F2ko\C50\01g+\FE\D7\ABv\CA\82\C9}\FAYG\F0\AD\D4\A2\AF\9C\A4r\C0\B7\FD\93&6?\F7\CC4\A5\E5\F1q\D81\15\04\C7#\C3\18\96\05\9A\07\12\80\E2\EB'\B2u", align 16
@check_table.k = internal constant [7 x i8] c"#q\C4\19\88Z\E1", align 1
@check_table.target = internal constant [14 x i8] c"M\1D\CA\972\80\1A\A5k^\ADG\04\80", align 1
@0 = private global i32 0

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  store i32 -1558027273, ptr %4, align 4
  br label %8

8:                                                ; preds = %258, %105, %104, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, 1937041680
  %11 = mul i32 %10, 489824173
  switch i32 %11, label %105 [
    i32 1715210011, label %12
    i32 1286153554, label %26
    i32 900267055, label %50
    i32 1778729903, label %74
    i32 1809140927, label %92
    i32 259153452, label %102
    i32 945987273, label %115
    i32 39342665, label %134
    i32 685184061, label %155
    i32 1034826819, label %168
    i32 11147502, label %189
    i32 1539161282, label %200
  ]

12:                                               ; preds = %8
  store i32 0, ptr %5, align 4
  store i32 %0, ptr %6, align 4
  store ptr %1, ptr %7, align 8
  call void @print_banner()
  %13 = load i32, ptr %6, align 4
  %14 = icmp ne i32 %13, 2
  %15 = select i1 %14, i32 -982694422, i32 378142683
  store i32 %15, ptr %4, align 4
  %16 = xor i32 %0, -1606660251
  %17 = and i32 %0, %16
  %18 = or i32 %0, %16
  %19 = xor i32 %0, %16
  %20 = mul i32 %18, 2
  %21 = sub i32 %20, %19
  %22 = sub i32 %21, %0
  %23 = sub i32 %22, %16
  %24 = mul i32 %23, 137
  %25 = icmp ne i32 %24, 0
  br i1 %25, label %213, label %104

26:                                               ; preds = %8
  %27 = load ptr, ptr @stderr, align 8
  %28 = load ptr, ptr %7, align 8
  %29 = getelementptr inbounds ptr, ptr %28, i64 0
  %30 = load ptr, ptr %29, align 8
  %31 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %27, ptr noundef @.str, ptr noundef %30) #6
  store i32 2, ptr %5, align 4
  store i32 168777068, ptr %4, align 4
  %32 = xor i32 %0, -87247621
  %33 = and i32 %0, %32
  %34 = or i32 %0, %32
  %35 = xor i32 %0, %32
  %36 = mul i32 %34, 2
  %37 = sub i32 %36, %35
  %38 = sub i32 %37, %0
  %39 = sub i32 %38, %32
  %40 = mul i32 %39, 217
  %41 = xor i32 %0, -1667865885
  %42 = and i32 %0, %41
  %43 = or i32 %0, %41
  %44 = xor i32 %0, %41
  %45 = add i32 %42, %43
  %46 = sub i32 %45, %0
  %47 = sub i32 %46, %41
  %48 = mul i32 %47, 192
  %49 = icmp eq i32 %40, %48
  br i1 %49, label %104, label %221

50:                                               ; preds = %8
  %51 = load ptr, ptr %7, align 8
  %52 = getelementptr inbounds ptr, ptr %51, i64 1
  %53 = load ptr, ptr %52, align 8
  %54 = call i32 @validate_key(ptr noundef %53)
  %55 = icmp ne i32 %54, 0
  %56 = select i1 %55, i32 -1586342565, i32 1514759339
  store i32 %56, ptr %4, align 4
  %57 = xor i32 %0, -1976819177
  %58 = and i32 %0, %57
  %59 = or i32 %0, %57
  %60 = xor i32 %0, %57
  %61 = mul i32 %59, 2
  %62 = sub i32 %61, %60
  %63 = sub i32 %62, %0
  %64 = sub i32 %63, %57
  %65 = mul i32 %64, 27
  %66 = xor i32 %0, 8722531
  %67 = and i32 %0, %66
  %68 = or i32 %0, %66
  %69 = xor i32 %0, %66
  %70 = sub i32 %68, %69
  %71 = sub i32 %70, %67
  %72 = mul i32 %71, 171
  %73 = icmp eq i32 %65, %72
  br i1 %73, label %104, label %230

74:                                               ; preds = %8
  %75 = call i32 @puts(ptr noundef @.str.1)
  store i32 0, ptr %5, align 4
  store i32 168777068, ptr %4, align 4
  %76 = xor i32 %0, 1180118889
  %77 = and i32 %0, %76
  %78 = or i32 %0, %76
  %79 = xor i32 %0, %76
  %80 = add i32 %77, %78
  %81 = sub i32 %80, %0
  %82 = sub i32 %81, %76
  %83 = mul i32 %82, 76
  %84 = xor i32 %0, 299274331
  %85 = and i32 %0, %84
  %86 = or i32 %0, %84
  %87 = xor i32 %0, %84
  %88 = sub i32 %86, %87
  %89 = sub i32 %88, %85
  %90 = mul i32 %89, 141
  %91 = icmp ne i32 %83, %90
  br i1 %91, label %239, label %104

92:                                               ; preds = %8
  %93 = call i32 @puts(ptr noundef @.str.2)
  store i32 1, ptr %5, align 4
  store i32 168777068, ptr %4, align 4
  %94 = xor i32 %0, -420756149
  %95 = and i32 %0, %94
  %96 = or i32 %0, %94
  %97 = xor i32 %0, %94
  %98 = sub i32 %96, %97
  %99 = sub i32 %98, %95
  %100 = mul i32 %99, 106
  %101 = icmp ugt i32 %100, 0
  br i1 %101, label %249, label %104

102:                                              ; preds = %8
  %103 = load i32, ptr %5, align 4
  ret i32 %103

104:                                              ; preds = %309, %300, %291, %282, %274, %267, %249, %239, %230, %221, %213, %200, %189, %168, %155, %134, %115, %92, %74, %50, %26, %12
  br label %8

105:                                              ; preds = %8
  store i32 -1558027273, ptr %4, align 4
  call void asm sideeffect "", ""()
  %106 = xor i32 %0, 1639411133
  %107 = and i32 %0, %106
  %108 = or i32 %0, %106
  %109 = xor i32 %0, %106
  %110 = add i32 %107, %108
  %111 = sub i32 %110, %0
  %112 = sub i32 %111, %106
  %113 = mul i32 %112, 118
  %114 = icmp uge i32 %113, 0
  br i1 %114, label %8, label %258

115:                                              ; preds = %8
  %116 = load i32, ptr %4, align 4
  %117 = xor i32 %116, -1968998621
  store i32 %117, ptr %4, align 4
  %118 = xor i32 %0, -85930887
  %119 = and i32 %0, %118
  %120 = or i32 %0, %118
  %121 = xor i32 %0, %118
  %122 = add i32 %119, %120
  %123 = sub i32 %122, %0
  %124 = sub i32 %123, %118
  %125 = mul i32 %124, 119
  %126 = xor i32 %0, -340415041
  %127 = and i32 %0, %126
  %128 = or i32 %0, %126
  %129 = xor i32 %0, %126
  %130 = sub i32 %128, %129
  %131 = sub i32 %130, %127
  %132 = mul i32 %131, 42
  %133 = icmp ne i32 %125, %132
  br i1 %133, label %267, label %104

134:                                              ; preds = %8
  %135 = load i32, ptr %4, align 4
  %136 = xor i32 %135, -1479741867
  store i32 %136, ptr %4, align 4
  %137 = xor i32 %0, 557366839
  %138 = and i32 %0, %137
  %139 = or i32 %0, %137
  %140 = xor i32 %0, %137
  %141 = mul i32 %139, 2
  %142 = sub i32 %141, %140
  %143 = sub i32 %142, %0
  %144 = sub i32 %143, %137
  %145 = mul i32 %144, 142
  %146 = xor i32 %0, -1048464703
  %147 = and i32 %0, %146
  %148 = or i32 %0, %146
  %149 = xor i32 %0, %146
  %150 = add i32 %147, %148
  %151 = sub i32 %150, %0
  %152 = sub i32 %151, %146
  %153 = mul i32 %152, 161
  %154 = icmp eq i32 %145, %153
  br i1 %154, label %104, label %274

155:                                              ; preds = %8
  %156 = load i32, ptr %4, align 4
  %157 = xor i32 %156, -990286088
  store i32 %157, ptr %4, align 4
  %158 = xor i32 %0, 1786403003
  %159 = and i32 %0, %158
  %160 = or i32 %0, %158
  %161 = xor i32 %0, %158
  %162 = add i32 %0, %158
  %163 = sub i32 %162, %161
  %164 = mul i32 %159, 2
  %165 = sub i32 %163, %164
  %166 = mul i32 %165, 10
  %167 = icmp slt i32 %166, 1
  br i1 %167, label %104, label %282

168:                                              ; preds = %8
  %169 = load i32, ptr %4, align 4
  %170 = xor i32 %169, 445234670
  store i32 %170, ptr %4, align 4
  %171 = xor i32 %0, -314542931
  %172 = and i32 %0, %171
  %173 = or i32 %0, %171
  %174 = xor i32 %0, %171
  %175 = mul i32 %173, 2
  %176 = sub i32 %175, %174
  %177 = sub i32 %176, %0
  %178 = sub i32 %177, %171
  %179 = mul i32 %178, 243
  %180 = xor i32 %0, -1931231015
  %181 = and i32 %0, %180
  %182 = or i32 %0, %180
  %183 = xor i32 %0, %180
  %184 = add i32 %181, %182
  %185 = sub i32 %184, %0
  %186 = sub i32 %185, %180
  %187 = mul i32 %186, 248
  %188 = icmp ne i32 %179, %187
  br i1 %188, label %291, label %104

189:                                              ; preds = %8
  %190 = load i32, ptr %4, align 4
  %191 = xor i32 %190, -1112065925
  store i32 %191, ptr %4, align 4
  %192 = xor i32 %0, -1372147579
  %193 = and i32 %0, %192
  %194 = or i32 %0, %192
  %195 = xor i32 %0, %192
  %196 = sub i32 %194, %195
  %197 = sub i32 %196, %193
  %198 = mul i32 %197, 77
  %199 = icmp uge i32 %198, 0
  br i1 %199, label %104, label %300

200:                                              ; preds = %8
  %201 = load i32, ptr %4, align 4
  %202 = xor i32 %201, -1200904302
  store i32 %202, ptr %4, align 4
  %203 = xor i32 %0, -229855499
  %204 = and i32 %0, %203
  %205 = or i32 %0, %203
  %206 = xor i32 %0, %203
  %207 = mul i32 %205, 2
  %208 = sub i32 %207, %206
  %209 = sub i32 %208, %0
  %210 = sub i32 %209, %203
  %211 = mul i32 %210, 96
  %212 = icmp ugt i32 %211, 0
  br i1 %212, label %309, label %104

213:                                              ; preds = %12
  %214 = load i64, ptr %3, align 8
  %215 = zext i32 %0 to i64
  %216 = ptrtoint ptr %1 to i64
  %217 = add i64 %214, %215
  %218 = and i64 %217, %216
  %219 = sub i64 %218, %215
  %220 = sub i64 %219, %215
  store i64 %220, ptr %3, align 8
  br label %104

221:                                              ; preds = %26
  %222 = load i64, ptr %3, align 8
  %223 = zext i32 %0 to i64
  %224 = ptrtoint ptr %1 to i64
  %225 = mul i64 %224, %223
  %226 = or i64 %225, %222
  %227 = xor i64 %226, %223
  %228 = and i64 %227, %223
  %229 = mul i64 %228, %222
  store i64 %229, ptr %3, align 8
  br label %104

230:                                              ; preds = %50
  %231 = load i64, ptr %3, align 8
  %232 = zext i32 %0 to i64
  %233 = ptrtoint ptr %1 to i64
  %234 = xor i64 %232, %231
  %235 = mul i64 %234, %231
  %236 = mul i64 %235, %232
  %237 = and i64 %236, %233
  %238 = and i64 %237, %232
  store i64 %238, ptr %3, align 8
  br label %104

239:                                              ; preds = %74
  %240 = load i64, ptr %3, align 8
  %241 = zext i32 %0 to i64
  %242 = ptrtoint ptr %1 to i64
  %243 = xor i64 %241, %242
  %244 = or i64 %243, %241
  %245 = and i64 %244, %241
  %246 = and i64 %245, %241
  %247 = sub i64 %246, %241
  %248 = xor i64 %247, %240
  store i64 %248, ptr %3, align 8
  br label %104

249:                                              ; preds = %92
  %250 = load i64, ptr %3, align 8
  %251 = zext i32 %0 to i64
  %252 = ptrtoint ptr %1 to i64
  %253 = xor i64 %251, %250
  %254 = add i64 %253, %252
  %255 = add i64 %254, %252
  %256 = add i64 %255, %250
  %257 = mul i64 %256, %251
  store i64 %257, ptr %3, align 8
  br label %104

258:                                              ; preds = %105
  %259 = load i64, ptr %3, align 8
  %260 = zext i32 %0 to i64
  %261 = ptrtoint ptr %1 to i64
  %262 = and i64 %260, %259
  %263 = and i64 %262, %261
  %264 = sub i64 %263, %261
  %265 = sub i64 %264, %260
  %266 = and i64 %265, %260
  store i64 %266, ptr %3, align 8
  br label %8

267:                                              ; preds = %115
  %268 = load i64, ptr %3, align 8
  %269 = zext i32 %0 to i64
  %270 = ptrtoint ptr %1 to i64
  %271 = add i64 %268, %268
  %272 = xor i64 %271, %270
  %273 = and i64 %272, %269
  store i64 %273, ptr %3, align 8
  br label %104

274:                                              ; preds = %134
  %275 = load i64, ptr %3, align 8
  %276 = zext i32 %0 to i64
  %277 = ptrtoint ptr %1 to i64
  %278 = add i64 %276, %276
  %279 = or i64 %278, %275
  %280 = or i64 %279, %275
  %281 = add i64 %280, %275
  store i64 %281, ptr %3, align 8
  br label %104

282:                                              ; preds = %155
  %283 = load i64, ptr %3, align 8
  %284 = zext i32 %0 to i64
  %285 = ptrtoint ptr %1 to i64
  %286 = xor i64 %285, %283
  %287 = add i64 %286, %285
  %288 = or i64 %287, %285
  %289 = xor i64 %288, %285
  %290 = add i64 %289, %283
  store i64 %290, ptr %3, align 8
  br label %104

291:                                              ; preds = %168
  %292 = load i64, ptr %3, align 8
  %293 = zext i32 %0 to i64
  %294 = ptrtoint ptr %1 to i64
  %295 = and i64 %294, %292
  %296 = mul i64 %295, %292
  %297 = or i64 %296, %293
  %298 = mul i64 %297, %294
  %299 = or i64 %298, %294
  store i64 %299, ptr %3, align 8
  br label %104

300:                                              ; preds = %189
  %301 = load i64, ptr %3, align 8
  %302 = zext i32 %0 to i64
  %303 = ptrtoint ptr %1 to i64
  %304 = or i64 %303, %303
  %305 = and i64 %304, %302
  %306 = add i64 %305, %303
  %307 = mul i64 %306, %303
  %308 = mul i64 %307, %303
  store i64 %308, ptr %3, align 8
  br label %104

309:                                              ; preds = %200
  %310 = load i64, ptr %3, align 8
  %311 = zext i32 %0 to i64
  %312 = ptrtoint ptr %1 to i64
  %313 = add i64 %311, %310
  %314 = add i64 %313, %310
  %315 = sub i64 %314, %312
  %316 = and i64 %315, %311
  %317 = mul i64 %316, %310
  %318 = xor i64 %317, %311
  store i64 %318, ptr %3, align 8
  br label %104
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @print_banner() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @0, align 4
  %3 = alloca i32, align 4
  %4 = alloca [17 x i8], align 16
  %5 = alloca i64, align 8
  store i32 754398956, ptr %3, align 4
  br label %6

6:                                                ; preds = %180, %88, %87, %0
  %7 = load i32, ptr %3, align 4
  %8 = sub i32 %7, -1001811251
  %9 = mul i32 %8, 848609613
  %10 = icmp slt i32 %9, 1094752731
  br i1 %10, label %146, label %148

11:                                               ; preds = %160
  store i64 0, ptr %5, align 8
  store i32 -135980932, ptr %3, align 4
  %12 = xor i32 %2, -2096684495
  %13 = and i32 %2, %12
  %14 = or i32 %2, %12
  %15 = xor i32 %2, %12
  %16 = add i32 %13, %14
  %17 = sub i32 %16, %2
  %18 = sub i32 %17, %12
  %19 = mul i32 %18, 220
  %20 = icmp ne i32 %19, 0
  br i1 %20, label %166, label %87

21:                                               ; preds = %156
  %22 = load i64, ptr %5, align 8
  %23 = icmp ult i64 %22, 16
  %24 = select i1 %23, i32 1711126762, i32 -975716143
  store i32 %24, ptr %3, align 4
  %25 = xor i32 %2, 824051785
  %26 = and i32 %2, %25
  %27 = or i32 %2, %25
  %28 = xor i32 %2, %25
  %29 = mul i32 %27, 2
  %30 = sub i32 %29, %28
  %31 = sub i32 %30, %2
  %32 = sub i32 %31, %25
  %33 = mul i32 %32, 198
  %34 = xor i32 %2, -1717120729
  %35 = and i32 %2, %34
  %36 = or i32 %2, %34
  %37 = xor i32 %2, %34
  %38 = add i32 %35, %36
  %39 = sub i32 %38, %2
  %40 = sub i32 %39, %34
  %41 = mul i32 %40, 214
  %42 = icmp ne i32 %33, %41
  br i1 %42, label %168, label %87

43:                                               ; preds = %154
  %44 = load i64, ptr %5, align 8
  %45 = getelementptr inbounds nuw [16 x i8], ptr @print_banner.enc, i64 0, i64 %44
  %46 = load i8, ptr %45, align 1
  %47 = zext i8 %46 to i32
  %48 = load i32, ptr %3, align 4
  %49 = xor i32 %48, 1711126668
  %50 = add i32 %47, %49
  %51 = load i32, ptr %3, align 4
  %52 = xor i32 %51, 1711126668
  %53 = and i32 %47, %52
  %54 = load i32, ptr %3, align 4
  %55 = xor i32 %54, 489445933
  %56 = mul i32 %50, %55
  %57 = load i32, ptr %3, align 4
  %58 = xor i32 %57, 489445933
  %59 = mul i32 %53, %58
  %60 = add i32 %59, %59
  %61 = sub i32 %56, %60
  %62 = load i32, ptr %3, align 4
  %63 = xor i32 %62, -1801752759
  %64 = mul i32 %61, %63
  %65 = load i32, ptr %3, align 4
  %66 = xor i32 %65, -1053181833
  %67 = mul i32 %64, %66
  %68 = trunc i32 %67 to i8
  %69 = load i64, ptr %5, align 8
  %70 = getelementptr inbounds nuw [17 x i8], ptr %4, i64 0, i64 %69
  store i8 %68, ptr %70, align 1
  %71 = load i64, ptr %5, align 8
  %72 = or i64 %71, 1
  %73 = and i64 %71, 1
  %74 = add i64 %72, %73
  store i64 %74, ptr %5, align 8
  store i32 -135980932, ptr %3, align 4
  %75 = xor i32 %2, 478989345
  %76 = and i32 %2, %75
  %77 = or i32 %2, %75
  %78 = xor i32 %2, %75
  %79 = sub i32 %77, %78
  %80 = sub i32 %79, %76
  %81 = mul i32 %80, 169
  %82 = icmp ne i32 %81, 0
  br i1 %82, label %173, label %87

83:                                               ; preds = %150
  %84 = getelementptr inbounds nuw [17 x i8], ptr %4, i64 0, i64 16
  store i8 0, ptr %84, align 16
  %85 = getelementptr inbounds [17 x i8], ptr %4, i64 0, i64 0
  %86 = call i32 @puts(ptr noundef %85)
  ret void

87:                                               ; preds = %202, %196, %189, %184, %173, %168, %166, %133, %121, %108, %97, %43, %21, %11
  br label %6

88:                                               ; preds = %164, %162, %156, %154
  store i32 754398956, ptr %3, align 4
  call void asm sideeffect "", ""()
  %89 = xor i32 %2, 955917077
  %90 = and i32 %2, %89
  %91 = or i32 %2, %89
  %92 = xor i32 %2, %89
  %93 = sub i32 %91, %92
  %94 = sub i32 %93, %90
  %95 = mul i32 %94, 109
  %96 = icmp sgt i32 %95, 0
  br i1 %96, label %180, label %6

97:                                               ; preds = %158
  %98 = load i32, ptr %3, align 4
  %99 = xor i32 %98, 1356840227
  store i32 %99, ptr %3, align 4
  %100 = xor i32 %2, -240152933
  %101 = and i32 %2, %100
  %102 = or i32 %2, %100
  %103 = xor i32 %2, %100
  %104 = sub i32 %102, %103
  %105 = sub i32 %104, %101
  %106 = mul i32 %105, 35
  %107 = icmp ugt i32 %106, 0
  br i1 %107, label %184, label %87

108:                                              ; preds = %162
  %109 = load i32, ptr %3, align 4
  %110 = xor i32 %109, 1330323466
  store i32 %110, ptr %3, align 4
  %111 = xor i32 %2, 1330036257
  %112 = and i32 %2, %111
  %113 = or i32 %2, %111
  %114 = xor i32 %2, %111
  %115 = add i32 %2, %111
  %116 = sub i32 %115, %114
  %117 = mul i32 %112, 2
  %118 = sub i32 %116, %117
  %119 = mul i32 %118, 245
  %120 = icmp sle i32 %119, 0
  br i1 %120, label %87, label %189

121:                                              ; preds = %164
  %122 = load i32, ptr %3, align 4
  %123 = xor i32 %122, 1465746178
  store i32 %123, ptr %3, align 4
  %124 = xor i32 %2, -940275877
  %125 = and i32 %2, %124
  %126 = or i32 %2, %124
  %127 = xor i32 %2, %124
  %128 = add i32 %125, %126
  %129 = sub i32 %128, %2
  %130 = sub i32 %129, %124
  %131 = mul i32 %130, 53
  %132 = icmp slt i32 %131, 0
  br i1 %132, label %196, label %87

133:                                              ; preds = %152
  %134 = load i32, ptr %3, align 4
  %135 = xor i32 %134, 881655966
  store i32 %135, ptr %3, align 4
  %136 = xor i32 %2, -1948951495
  %137 = and i32 %2, %136
  %138 = or i32 %2, %136
  %139 = xor i32 %2, %136
  %140 = add i32 %2, %136
  %141 = sub i32 %140, %139
  %142 = mul i32 %137, 2
  %143 = sub i32 %141, %142
  %144 = mul i32 %143, 149
  %145 = icmp sgt i32 %144, 0
  br i1 %145, label %202, label %87

146:                                              ; preds = %6
  %147 = icmp slt i32 %9, 912506734
  br i1 %147, label %150, label %152

148:                                              ; preds = %6
  %149 = icmp slt i32 %9, 1424079955
  br i1 %149, label %158, label %160

150:                                              ; preds = %146
  %151 = icmp eq i32 %9, 180673332
  br i1 %151, label %83, label %154

152:                                              ; preds = %146
  %153 = icmp eq i32 %9, 912506734
  br i1 %153, label %133, label %156

154:                                              ; preds = %150
  %155 = icmp eq i32 %9, 649024441
  br i1 %155, label %43, label %88

156:                                              ; preds = %152
  %157 = icmp eq i32 %9, 1018963107
  br i1 %157, label %21, label %88

158:                                              ; preds = %148
  %159 = icmp eq i32 %9, 1094752731
  br i1 %159, label %97, label %162

160:                                              ; preds = %148
  %161 = icmp eq i32 %9, 1424079955
  br i1 %161, label %11, label %164

162:                                              ; preds = %158
  %163 = icmp eq i32 %9, 1366121799
  br i1 %163, label %108, label %88

164:                                              ; preds = %160
  %165 = icmp eq i32 %9, 1635880090
  br i1 %165, label %121, label %88

166:                                              ; preds = %11
  %167 = load i64, ptr %1, align 8
  store i64 -375864805140546492, ptr %1, align 8
  br label %87

168:                                              ; preds = %21
  %169 = load i64, ptr %1, align 8
  %170 = add i64 %169, 3479519676
  %171 = or i64 %170, 3479519676
  %172 = xor i64 %171, 3479519676
  store i64 %172, ptr %1, align 8
  br label %87

173:                                              ; preds = %43
  %174 = load i64, ptr %1, align 8
  %175 = add i64 1881098831, %174
  %176 = add i64 %175, %174
  %177 = xor i64 %176, 464587259
  %178 = sub i64 %177, %174
  %179 = mul i64 %178, %174
  store i64 %179, ptr %1, align 8
  br label %87

180:                                              ; preds = %88
  %181 = load i64, ptr %1, align 8
  %182 = or i64 6593190646398189051, %181
  %183 = sub i64 %182, 4181352999
  store i64 %183, ptr %1, align 8
  br label %6

184:                                              ; preds = %97
  %185 = load i64, ptr %1, align 8
  %186 = add i64 %185, 4153067749
  %187 = sub i64 %186, 3354794375
  %188 = add i64 %187, 4153067749
  store i64 %188, ptr %1, align 8
  br label %87

189:                                              ; preds = %108
  %190 = load i64, ptr %1, align 8
  %191 = or i64 1907373401, %190
  %192 = sub i64 %191, 1907373401
  %193 = mul i64 %192, 1907373401
  %194 = mul i64 %193, 1907373401
  %195 = xor i64 %194, 3096366881
  store i64 %195, ptr %1, align 8
  br label %87

196:                                              ; preds = %121
  %197 = load i64, ptr %1, align 8
  %198 = add i64 %197, 1216974274
  %199 = sub i64 %198, 3800432004
  %200 = sub i64 %199, 1216974274
  %201 = add i64 %200, 3800432004
  store i64 %201, ptr %1, align 8
  br label %87

202:                                              ; preds = %133
  %203 = load i64, ptr %1, align 8
  %204 = or i64 %203, %203
  %205 = xor i64 %204, 2188221031
  %206 = add i64 %205, 2188221031
  store i64 %206, ptr %1, align 8
  br label %87
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @validate_key(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca [14 x i8], align 1
  %8 = alloca i32, align 4
  %9 = alloca i64, align 8
  %10 = alloca i32, align 4
  store i32 372845171, ptr %4, align 4
  br label %11

11:                                               ; preds = %156, %74, %73, %1
  %12 = load i32, ptr %4, align 4
  %13 = sub i32 %12, -68790514
  %14 = mul i32 %13, -1942750953
  switch i32 %14, label %74 [
    i32 1177369363, label %15
    i32 1961172393, label %29
    i32 972708105, label %43
    i32 650439351, label %71
    i32 200001552, label %84
    i32 1364471176, label %95
    i32 964651727, label %108
    i32 384447093, label %120
  ]

15:                                               ; preds = %11
  store ptr %0, ptr %5, align 8
  %16 = load ptr, ptr %5, align 8
  %17 = call i64 @strlen(ptr noundef %16) #7
  store i64 %17, ptr %6, align 8
  %18 = getelementptr inbounds [14 x i8], ptr %7, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 1 %18, i8 0, i64 14, i1 false)
  store i32 1, ptr %8, align 4
  store i64 0, ptr %9, align 8
  store i32 -443371955, ptr %4, align 4
  %19 = xor i32 %3, -789791253
  %20 = and i32 %3, %19
  %21 = or i32 %3, %19
  %22 = xor i32 %3, %19
  %23 = add i32 %3, %19
  %24 = sub i32 %23, %22
  %25 = mul i32 %20, 2
  %26 = sub i32 %24, %25
  %27 = mul i32 %26, 147
  %28 = icmp ugt i32 %27, 0
  br i1 %28, label %133, label %73

29:                                               ; preds = %11
  %30 = load i64, ptr %9, align 8
  %31 = icmp ult i64 %30, 4
  %32 = select i1 %31, i32 221489645, i32 -1444759953
  store i32 %32, ptr %4, align 4
  %33 = xor i32 %3, -1863410967
  %34 = and i32 %3, %33
  %35 = or i32 %3, %33
  %36 = xor i32 %3, %33
  %37 = add i32 %3, %33
  %38 = sub i32 %37, %36
  %39 = mul i32 %34, 2
  %40 = sub i32 %38, %39
  %41 = mul i32 %40, 38
  %42 = icmp slt i32 %41, 1
  br i1 %42, label %73, label %139

43:                                               ; preds = %11
  %44 = load i64, ptr %9, align 8
  %45 = getelementptr inbounds nuw [4 x ptr], ptr @validate_key.stages, i64 0, i64 %44
  %46 = load ptr, ptr %45, align 8
  %47 = load ptr, ptr %5, align 8
  %48 = load i64, ptr %6, align 8
  %49 = getelementptr inbounds [14 x i8], ptr %7, i64 0, i64 0
  %50 = call i32 %46(ptr noundef %47, i64 noundef %48, ptr noundef %49)
  store i32 %50, ptr %10, align 4
  %51 = load i32, ptr %10, align 4
  %52 = load i32, ptr %8, align 4
  %53 = add i32 %52, %51
  %54 = or i32 %52, %51
  %55 = sub i32 %53, %54
  store i32 %55, ptr %8, align 4
  %56 = load i64, ptr %9, align 8
  %57 = sub i64 %56, 1
  %58 = mul i64 %56, 2
  %59 = mul i64 1, %57
  %60 = sub i64 %58, %59
  store i64 %60, ptr %9, align 8
  store i32 -443371955, ptr %4, align 4
  %61 = xor i32 %3, 749865557
  %62 = and i32 %3, %61
  %63 = or i32 %3, %61
  %64 = xor i32 %3, %61
  %65 = mul i32 %63, 2
  %66 = sub i32 %65, %64
  %67 = sub i32 %66, %3
  %68 = sub i32 %67, %61
  %69 = mul i32 %68, 227
  %70 = icmp uge i32 %69, 0
  br i1 %70, label %73, label %148

71:                                               ; preds = %11
  %72 = load i32, ptr %8, align 4
  ret i32 %72

73:                                               ; preds = %186, %180, %172, %164, %148, %139, %133, %120, %108, %95, %84, %43, %29, %15
  br label %11

74:                                               ; preds = %11
  store i32 372845171, ptr %4, align 4
  call void asm sideeffect "", ""()
  %75 = xor i32 %3, 72974177
  %76 = and i32 %3, %75
  %77 = or i32 %3, %75
  %78 = xor i32 %3, %75
  %79 = add i32 %76, %77
  %80 = sub i32 %79, %3
  %81 = sub i32 %80, %75
  %82 = mul i32 %81, 76
  %83 = icmp ugt i32 %82, 0
  br i1 %83, label %156, label %11

84:                                               ; preds = %11
  %85 = load i32, ptr %4, align 4
  %86 = xor i32 %85, 685374976
  store i32 %86, ptr %4, align 4
  %87 = xor i32 %3, 2122683703
  %88 = and i32 %3, %87
  %89 = or i32 %3, %87
  %90 = xor i32 %3, %87
  %91 = sub i32 %89, %90
  %92 = sub i32 %91, %88
  %93 = mul i32 %92, 159
  %94 = icmp ugt i32 %93, 0
  br i1 %94, label %164, label %73

95:                                               ; preds = %11
  %96 = load i32, ptr %4, align 4
  %97 = xor i32 %96, 1223701227
  store i32 %97, ptr %4, align 4
  %98 = xor i32 %3, 914229627
  %99 = and i32 %3, %98
  %100 = or i32 %3, %98
  %101 = xor i32 %3, %98
  %102 = mul i32 %100, 2
  %103 = sub i32 %102, %101
  %104 = sub i32 %103, %3
  %105 = sub i32 %104, %98
  %106 = mul i32 %105, 15
  %107 = icmp sle i32 %106, 0
  br i1 %107, label %73, label %172

108:                                              ; preds = %11
  %109 = load i32, ptr %4, align 4
  %110 = xor i32 %109, -710970136
  store i32 %110, ptr %4, align 4
  %111 = xor i32 %3, -1750608213
  %112 = and i32 %3, %111
  %113 = or i32 %3, %111
  %114 = xor i32 %3, %111
  %115 = add i32 %112, %113
  %116 = sub i32 %115, %3
  %117 = sub i32 %116, %111
  %118 = mul i32 %117, 32
  %119 = icmp slt i32 %118, 0
  br i1 %119, label %180, label %73

120:                                              ; preds = %11
  %121 = load i32, ptr %4, align 4
  %122 = xor i32 %121, 1658943937
  store i32 %122, ptr %4, align 4
  %123 = xor i32 %3, 57869557
  %124 = and i32 %3, %123
  %125 = or i32 %3, %123
  %126 = xor i32 %3, %123
  %127 = add i32 %3, %123
  %128 = sub i32 %127, %126
  %129 = mul i32 %124, 2
  %130 = sub i32 %128, %129
  %131 = mul i32 %130, 24
  %132 = icmp sle i32 %131, 0
  br i1 %132, label %73, label %186

133:                                              ; preds = %15
  %134 = load i64, ptr %2, align 8
  %135 = ptrtoint ptr %0 to i64
  %136 = mul i64 %135, %135
  %137 = xor i64 %136, %134
  %138 = add i64 %137, %135
  store i64 %138, ptr %2, align 8
  br label %73

139:                                              ; preds = %29
  %140 = load i64, ptr %2, align 8
  %141 = ptrtoint ptr %0 to i64
  %142 = xor i64 %141, %140
  %143 = add i64 %142, %141
  %144 = mul i64 %143, %141
  %145 = or i64 %144, %140
  %146 = add i64 %145, %140
  %147 = mul i64 %146, %141
  store i64 %147, ptr %2, align 8
  br label %73

148:                                              ; preds = %43
  %149 = load i64, ptr %2, align 8
  %150 = ptrtoint ptr %0 to i64
  %151 = or i64 %150, %150
  %152 = and i64 %151, %150
  %153 = xor i64 %152, %150
  %154 = sub i64 %153, %150
  %155 = mul i64 %154, %149
  store i64 %155, ptr %2, align 8
  br label %73

156:                                              ; preds = %74
  %157 = load i64, ptr %2, align 8
  %158 = ptrtoint ptr %0 to i64
  %159 = mul i64 %158, %158
  %160 = add i64 %159, %157
  %161 = xor i64 %160, %158
  %162 = mul i64 %161, %157
  %163 = and i64 %162, %158
  store i64 %163, ptr %2, align 8
  br label %11

164:                                              ; preds = %84
  %165 = load i64, ptr %2, align 8
  %166 = ptrtoint ptr %0 to i64
  %167 = and i64 %165, %165
  %168 = mul i64 %167, %166
  %169 = sub i64 %168, %166
  %170 = sub i64 %169, %165
  %171 = or i64 %170, %166
  store i64 %171, ptr %2, align 8
  br label %73

172:                                              ; preds = %95
  %173 = load i64, ptr %2, align 8
  %174 = ptrtoint ptr %0 to i64
  %175 = add i64 %174, %174
  %176 = add i64 %175, %174
  %177 = sub i64 %176, %174
  %178 = add i64 %177, %173
  %179 = and i64 %178, %173
  store i64 %179, ptr %2, align 8
  br label %73

180:                                              ; preds = %108
  %181 = load i64, ptr %2, align 8
  %182 = ptrtoint ptr %0 to i64
  %183 = and i64 %181, %182
  %184 = and i64 %183, %182
  %185 = sub i64 %184, %182
  store i64 %185, ptr %2, align 8
  br label %73

186:                                              ; preds = %120
  %187 = load i64, ptr %2, align 8
  %188 = ptrtoint ptr %0 to i64
  %189 = and i64 %187, %187
  %190 = or i64 %189, %187
  %191 = or i64 %190, %187
  store i64 %191, ptr %2, align 8
  br label %73
}

declare i32 @puts(ptr noundef) #2

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #3

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #4

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @check_shape(ptr noundef %0, i64 noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i1, align 1
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i64, align 8
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca i64, align 8
  %13 = alloca i8, align 1
  %14 = alloca i32, align 4
  store i32 1145025408, ptr %5, align 4
  br label %15

15:                                               ; preds = %492, %222, %221, %3
  %16 = load i32, ptr %5, align 4
  %17 = sub i32 %16, -1914580689
  %18 = mul i32 %17, -624440607
  %19 = icmp slt i32 %18, 1216644386
  br i1 %19, label %338, label %340

20:                                               ; preds = %368
  store ptr %0, ptr %8, align 8
  store i64 %1, ptr %9, align 8
  store ptr %2, ptr %10, align 8
  %21 = load i64, ptr %9, align 8
  %22 = icmp ne i64 %21, 14
  %23 = select i1 %22, i32 -129013383, i32 -1883924307
  store i32 %23, ptr %5, align 4
  %24 = xor i64 %1, 5155937764927086453
  %25 = and i64 %1, %24
  %26 = or i64 %1, %24
  %27 = xor i64 %1, %24
  %28 = add i64 %1, %24
  %29 = sub i64 %28, %27
  %30 = mul i64 %25, 2
  %31 = sub i64 %29, %30
  %32 = mul i64 %31, 47
  %33 = icmp ne i64 %32, 0
  br i1 %33, label %398, label %221

34:                                               ; preds = %384
  store i32 0, ptr %7, align 4
  store i32 -517239976, ptr %5, align 4
  %35 = xor i64 %1, -234094615114916559
  %36 = and i64 %1, %35
  %37 = or i64 %1, %35
  %38 = xor i64 %1, %35
  %39 = add i64 %1, %35
  %40 = sub i64 %39, %38
  %41 = mul i64 %36, 2
  %42 = sub i64 %40, %41
  %43 = mul i64 %42, 83
  %44 = icmp eq i64 %43, 0
  br i1 %44, label %221, label %406

45:                                               ; preds = %356
  store i32 0, ptr %11, align 4
  store i64 0, ptr %12, align 8
  store i32 1663429760, ptr %5, align 4
  %46 = xor i64 %1, -2890160366483697171
  %47 = and i64 %1, %46
  %48 = or i64 %1, %46
  %49 = xor i64 %1, %46
  %50 = mul i64 %48, 2
  %51 = sub i64 %50, %49
  %52 = sub i64 %51, %1
  %53 = sub i64 %52, %46
  %54 = mul i64 %53, 136
  %55 = icmp slt i64 %54, 0
  br i1 %55, label %415, label %221

56:                                               ; preds = %382
  %57 = load i64, ptr %12, align 8
  %58 = load i64, ptr %9, align 8
  %59 = icmp ult i64 %57, %58
  %60 = select i1 %59, i32 -1576465263, i32 596685052
  store i32 %60, ptr %5, align 4
  %61 = xor i64 %1, -855008793811807567
  %62 = and i64 %1, %61
  %63 = or i64 %1, %61
  %64 = xor i64 %1, %61
  %65 = mul i64 %63, 2
  %66 = sub i64 %65, %64
  %67 = sub i64 %66, %1
  %68 = sub i64 %67, %61
  %69 = mul i64 %68, 212
  %70 = icmp eq i64 %69, 0
  br i1 %70, label %221, label %423

71:                                               ; preds = %374
  %72 = load ptr, ptr %8, align 8
  %73 = load i64, ptr %12, align 8
  %74 = getelementptr inbounds nuw i8, ptr %72, i64 %73
  %75 = load i8, ptr %74, align 1
  store i8 %75, ptr %13, align 1
  %76 = load i8, ptr %13, align 1
  %77 = zext i8 %76 to i32
  %78 = icmp sge i32 %77, 97
  %79 = select i1 %78, i32 1076287013, i32 -207418282
  store i32 %79, ptr %5, align 4
  %80 = xor i64 %1, 5015655259690278659
  %81 = and i64 %1, %80
  %82 = or i64 %1, %80
  %83 = xor i64 %1, %80
  %84 = add i64 %81, %82
  %85 = sub i64 %84, %1
  %86 = sub i64 %85, %80
  %87 = mul i64 %86, 238
  %88 = icmp uge i64 %87, 0
  br i1 %88, label %221, label %433

89:                                               ; preds = %392
  %90 = load i8, ptr %13, align 1
  %91 = zext i8 %90 to i32
  %92 = icmp sle i32 %91, 122
  store i1 true, ptr %6, align 1
  %93 = select i1 %92, i32 -1171016762, i32 -207418282
  store i32 %93, ptr %5, align 4
  %94 = xor i64 %1, 4356979514658153045
  %95 = and i64 %1, %94
  %96 = or i64 %1, %94
  %97 = xor i64 %1, %94
  %98 = add i64 %1, %94
  %99 = sub i64 %98, %97
  %100 = mul i64 %95, 2
  %101 = sub i64 %99, %100
  %102 = mul i64 %101, 119
  %103 = icmp sle i64 %102, 0
  br i1 %103, label %221, label %440

104:                                              ; preds = %362
  %105 = load i8, ptr %13, align 1
  %106 = zext i8 %105 to i32
  %107 = icmp sge i32 %106, 48
  %108 = select i1 %107, i32 2059463005, i32 1494070100
  store i32 %108, ptr %5, align 4
  %109 = xor i64 %1, 1226228012238429799
  %110 = and i64 %1, %109
  %111 = or i64 %1, %109
  %112 = xor i64 %1, %109
  %113 = sub i64 %111, %112
  %114 = sub i64 %113, %110
  %115 = mul i64 %114, 69
  %116 = icmp uge i64 %115, 0
  br i1 %116, label %221, label %449

117:                                              ; preds = %364
  %118 = load i8, ptr %13, align 1
  %119 = zext i8 %118 to i32
  %120 = icmp sle i32 %119, 57
  store i1 true, ptr %6, align 1
  %121 = select i1 %120, i32 -1171016762, i32 1494070100
  store i32 %121, ptr %5, align 4
  %122 = xor i64 %1, 858684318201734723
  %123 = and i64 %1, %122
  %124 = or i64 %1, %122
  %125 = xor i64 %1, %122
  %126 = add i64 %123, %124
  %127 = sub i64 %126, %1
  %128 = sub i64 %127, %122
  %129 = mul i64 %128, 137
  %130 = icmp eq i64 %129, 0
  br i1 %130, label %221, label %457

131:                                              ; preds = %396
  %132 = load i8, ptr %13, align 1
  %133 = zext i8 %132 to i32
  %134 = icmp eq i32 %133, 45
  store i1 %134, ptr %6, align 1
  store i32 -1171016762, ptr %5, align 4
  %135 = xor i64 %1, 967844495310494919
  %136 = and i64 %1, %135
  %137 = or i64 %1, %135
  %138 = xor i64 %1, %135
  %139 = add i64 %136, %137
  %140 = sub i64 %139, %1
  %141 = sub i64 %140, %135
  %142 = mul i64 %141, 107
  %143 = icmp slt i64 %142, 1
  br i1 %143, label %221, label %464

144:                                              ; preds = %378
  %145 = load i1, ptr %6, align 1
  %146 = zext i1 %145 to i32
  store i32 %146, ptr %14, align 4
  %147 = load i32, ptr %14, align 4
  %148 = load i32, ptr %5, align 4
  %149 = xor i32 %148, -1171016761
  %150 = add i32 %147, %149
  %151 = load i32, ptr %5, align 4
  %152 = xor i32 %151, -1171016761
  %153 = and i32 %147, %152
  %154 = add i32 %153, %153
  %155 = sub i32 %150, %154
  %156 = load i32, ptr %11, align 4
  %157 = xor i32 %156, %155
  %158 = and i32 %156, %155
  %159 = load i32, ptr %5, align 4
  %160 = xor i32 %159, -2046712681
  %161 = mul i32 %157, %160
  %162 = load i32, ptr %5, align 4
  %163 = xor i32 %162, -2046712681
  %164 = mul i32 %158, %163
  %165 = add i32 %161, %164
  %166 = load i32, ptr %5, align 4
  %167 = xor i32 %166, 225059447
  %168 = mul i32 %165, %167
  store i32 %168, ptr %11, align 4
  %169 = load i8, ptr %13, align 1
  %170 = zext i8 %169 to i32
  %171 = load i64, ptr %12, align 8
  %172 = mul i64 %171, 7
  %173 = xor i64 %172, 3
  %174 = and i64 %172, 3
  %175 = add i64 %174, %174
  %176 = add i64 %173, %175
  %177 = add i64 %176, 63
  %178 = or i64 %176, 63
  %179 = sub i64 %177, %178
  %180 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %179
  %181 = load i8, ptr %180, align 1
  %182 = zext i8 %181 to i32
  %183 = or i32 %170, %182
  %184 = and i32 %170, %182
  %185 = sub i32 %183, %184
  %186 = trunc i32 %185 to i8
  %187 = load ptr, ptr %10, align 8
  %188 = load i64, ptr %12, align 8
  %189 = getelementptr inbounds nuw i8, ptr %187, i64 %188
  store i8 %186, ptr %189, align 1
  %190 = load i64, ptr %12, align 8
  %191 = xor i64 %190, 1
  %192 = and i64 %190, 1
  %193 = add i64 %192, %192
  %194 = add i64 %191, %193
  store i64 %194, ptr %12, align 8
  store i32 1663429760, ptr %5, align 4
  %195 = xor i64 %1, 1325366563799847481
  %196 = and i64 %1, %195
  %197 = or i64 %1, %195
  %198 = xor i64 %1, %195
  %199 = add i64 %1, %195
  %200 = sub i64 %199, %198
  %201 = mul i64 %196, 2
  %202 = sub i64 %200, %201
  %203 = mul i64 %202, 151
  %204 = icmp ne i64 %203, 0
  br i1 %204, label %474, label %221

205:                                              ; preds = %358
  %206 = load i32, ptr %11, align 4
  %207 = icmp eq i32 %206, 0
  %208 = zext i1 %207 to i32
  store i32 %208, ptr %7, align 4
  store i32 -517239976, ptr %5, align 4
  %209 = xor i64 %1, 4341681661902096343
  %210 = and i64 %1, %209
  %211 = or i64 %1, %209
  %212 = xor i64 %1, %209
  %213 = add i64 %1, %209
  %214 = sub i64 %213, %212
  %215 = mul i64 %210, 2
  %216 = sub i64 %214, %215
  %217 = mul i64 %216, 35
  %218 = icmp slt i64 %217, 1
  br i1 %218, label %221, label %482

219:                                              ; preds = %346
  %220 = load i32, ptr %7, align 4
  ret i32 %220

221:                                              ; preds = %558, %549, %542, %535, %528, %519, %509, %501, %482, %474, %464, %457, %449, %440, %433, %423, %415, %406, %398, %326, %313, %300, %287, %275, %262, %244, %231, %205, %144, %131, %117, %104, %89, %71, %56, %45, %34, %20
  br label %15

222:                                              ; preds = %396, %392, %390, %384, %380, %378, %368, %364, %362, %356, %352, %350
  store i32 1145025408, ptr %5, align 4
  call void asm sideeffect "", ""()
  %223 = xor i64 %1, -356488436614324791
  %224 = and i64 %1, %223
  %225 = or i64 %1, %223
  %226 = xor i64 %1, %223
  %227 = sub i64 %225, %226
  %228 = sub i64 %227, %224
  %229 = mul i64 %228, 231
  %230 = icmp uge i64 %229, 0
  br i1 %230, label %15, label %492

231:                                              ; preds = %350
  %232 = load i32, ptr %5, align 4
  %233 = xor i32 %232, -659513858
  store i32 %233, ptr %5, align 4
  %234 = xor i64 %1, 9034103308554619503
  %235 = and i64 %1, %234
  %236 = or i64 %1, %234
  %237 = xor i64 %1, %234
  %238 = mul i64 %236, 2
  %239 = sub i64 %238, %237
  %240 = sub i64 %239, %1
  %241 = sub i64 %240, %234
  %242 = mul i64 %241, 149
  %243 = icmp eq i64 %242, 0
  br i1 %243, label %221, label %501

244:                                              ; preds = %380
  %245 = load i32, ptr %5, align 4
  %246 = xor i32 %245, 265066927
  store i32 %246, ptr %5, align 4
  %247 = xor i64 %1, -9144478600040277329
  %248 = and i64 %1, %247
  %249 = or i64 %1, %247
  %250 = xor i64 %1, %247
  %251 = sub i64 %249, %250
  %252 = sub i64 %251, %248
  %253 = mul i64 %252, 33
  %254 = xor i64 %1, 551623223759509429
  %255 = and i64 %1, %254
  %256 = or i64 %1, %254
  %257 = xor i64 %1, %254
  %258 = sub i64 %256, %257
  %259 = sub i64 %258, %255
  %260 = mul i64 %259, 42
  %261 = icmp ne i64 %253, %260
  br i1 %261, label %509, label %221

262:                                              ; preds = %386
  %263 = load i32, ptr %5, align 4
  %264 = xor i32 %263, -761402403
  store i32 %264, ptr %5, align 4
  %265 = xor i64 %1, 6473530359144229595
  %266 = and i64 %1, %265
  %267 = or i64 %1, %265
  %268 = xor i64 %1, %265
  %269 = add i64 %1, %265
  %270 = sub i64 %269, %268
  %271 = mul i64 %266, 2
  %272 = sub i64 %270, %271
  %273 = mul i64 %272, 148
  %274 = icmp eq i64 %273, 0
  br i1 %274, label %221, label %519

275:                                              ; preds = %352
  %276 = load i32, ptr %5, align 4
  %277 = xor i32 %276, 1634360759
  store i32 %277, ptr %5, align 4
  %278 = xor i64 %1, -608158781953303473
  %279 = and i64 %1, %278
  %280 = or i64 %1, %278
  %281 = xor i64 %1, %278
  %282 = add i64 %279, %280
  %283 = sub i64 %282, %1
  %284 = sub i64 %283, %278
  %285 = mul i64 %284, 135
  %286 = icmp uge i64 %285, 0
  br i1 %286, label %221, label %528

287:                                              ; preds = %366
  %288 = load i32, ptr %5, align 4
  %289 = xor i32 %288, 1427234418
  store i32 %289, ptr %5, align 4
  %290 = xor i64 %1, -8454807880482224057
  %291 = and i64 %1, %290
  %292 = or i64 %1, %290
  %293 = xor i64 %1, %290
  %294 = mul i64 %292, 2
  %295 = sub i64 %294, %293
  %296 = sub i64 %295, %1
  %297 = sub i64 %296, %290
  %298 = mul i64 %297, 121
  %299 = icmp slt i64 %298, 0
  br i1 %299, label %535, label %221

300:                                              ; preds = %394
  %301 = load i32, ptr %5, align 4
  %302 = xor i32 %301, -73378454
  store i32 %302, ptr %5, align 4
  %303 = xor i64 %1, 8560938192594447047
  %304 = and i64 %1, %303
  %305 = or i64 %1, %303
  %306 = xor i64 %1, %303
  %307 = add i64 %1, %303
  %308 = sub i64 %307, %306
  %309 = mul i64 %304, 2
  %310 = sub i64 %308, %309
  %311 = mul i64 %310, 105
  %312 = icmp uge i64 %311, 0
  br i1 %312, label %221, label %542

313:                                              ; preds = %390
  %314 = load i32, ptr %5, align 4
  %315 = xor i32 %314, -912919790
  store i32 %315, ptr %5, align 4
  %316 = xor i64 %1, -7690755780734001791
  %317 = and i64 %1, %316
  %318 = or i64 %1, %316
  %319 = xor i64 %1, %316
  %320 = add i64 %1, %316
  %321 = sub i64 %320, %319
  %322 = mul i64 %317, 2
  %323 = sub i64 %321, %322
  %324 = mul i64 %323, 104
  %325 = icmp slt i64 %324, 0
  br i1 %325, label %549, label %221

326:                                              ; preds = %354
  %327 = load i32, ptr %5, align 4
  %328 = xor i32 %327, 1975221844
  store i32 %328, ptr %5, align 4
  %329 = xor i64 %1, 2124652954525329891
  %330 = and i64 %1, %329
  %331 = or i64 %1, %329
  %332 = xor i64 %1, %329
  %333 = add i64 %330, %331
  %334 = sub i64 %333, %1
  %335 = sub i64 %334, %329
  %336 = mul i64 %335, 71
  %337 = icmp sle i64 %336, 0
  br i1 %337, label %221, label %558

338:                                              ; preds = %15
  %339 = icmp slt i32 %18, 363164973
  br i1 %339, label %342, label %344

340:                                              ; preds = %15
  %341 = icmp slt i32 %18, 1903443432
  br i1 %341, label %370, label %372

342:                                              ; preds = %338
  %343 = icmp slt i32 %18, 234435494
  br i1 %343, label %346, label %348

344:                                              ; preds = %338
  %345 = icmp slt i32 %18, 820677742
  br i1 %345, label %358, label %360

346:                                              ; preds = %342
  %347 = icmp eq i32 %18, 9435145
  br i1 %347, label %219, label %350

348:                                              ; preds = %342
  %349 = icmp slt i32 %18, 274548295
  br i1 %349, label %352, label %354

350:                                              ; preds = %346
  %351 = icmp eq i32 %18, 70557149
  br i1 %351, label %231, label %222

352:                                              ; preds = %348
  %353 = icmp eq i32 %18, 234435494
  br i1 %353, label %275, label %222

354:                                              ; preds = %348
  %355 = icmp eq i32 %18, 274548295
  br i1 %355, label %326, label %356

356:                                              ; preds = %354
  %357 = icmp eq i32 %18, 360563134
  br i1 %357, label %45, label %222

358:                                              ; preds = %344
  %359 = icmp eq i32 %18, 363164973
  br i1 %359, label %205, label %362

360:                                              ; preds = %344
  %361 = icmp slt i32 %18, 1118173620
  br i1 %361, label %364, label %366

362:                                              ; preds = %358
  %363 = icmp eq i32 %18, 416465735
  br i1 %363, label %104, label %222

364:                                              ; preds = %360
  %365 = icmp eq i32 %18, 820677742
  br i1 %365, label %117, label %222

366:                                              ; preds = %360
  %367 = icmp eq i32 %18, 1118173620
  br i1 %367, label %287, label %368

368:                                              ; preds = %366
  %369 = icmp eq i32 %18, 1141822257
  br i1 %369, label %20, label %222

370:                                              ; preds = %340
  %371 = icmp slt i32 %18, 1336938275
  br i1 %371, label %374, label %376

372:                                              ; preds = %340
  %373 = icmp slt i32 %18, 2077063222
  br i1 %373, label %386, label %388

374:                                              ; preds = %370
  %375 = icmp eq i32 %18, 1216644386
  br i1 %375, label %71, label %378

376:                                              ; preds = %370
  %377 = icmp slt i32 %18, 1684073521
  br i1 %377, label %380, label %382

378:                                              ; preds = %374
  %379 = icmp eq i32 %18, 1243892919
  br i1 %379, label %144, label %222

380:                                              ; preds = %376
  %381 = icmp eq i32 %18, 1336938275
  br i1 %381, label %244, label %222

382:                                              ; preds = %376
  %383 = icmp eq i32 %18, 1684073521
  br i1 %383, label %56, label %384

384:                                              ; preds = %382
  %385 = icmp eq i32 %18, 1778597130
  br i1 %385, label %34, label %222

386:                                              ; preds = %372
  %387 = icmp eq i32 %18, 1903443432
  br i1 %387, label %262, label %390

388:                                              ; preds = %372
  %389 = icmp slt i32 %18, 2124165753
  br i1 %389, label %392, label %394

390:                                              ; preds = %386
  %391 = icmp eq i32 %18, 2072910961
  br i1 %391, label %313, label %222

392:                                              ; preds = %388
  %393 = icmp eq i32 %18, 2077063222
  br i1 %393, label %89, label %222

394:                                              ; preds = %388
  %395 = icmp eq i32 %18, 2124165753
  br i1 %395, label %300, label %396

396:                                              ; preds = %394
  %397 = icmp eq i32 %18, 2126902405
  br i1 %397, label %131, label %222

398:                                              ; preds = %20
  %399 = load i64, ptr %4, align 8
  %400 = ptrtoint ptr %0 to i64
  %401 = ptrtoint ptr %2 to i64
  %402 = xor i64 %1, %401
  %403 = mul i64 %402, %399
  %404 = or i64 %403, %400
  %405 = add i64 %404, %400
  store i64 %405, ptr %4, align 8
  br label %221

406:                                              ; preds = %34
  %407 = load i64, ptr %4, align 8
  %408 = ptrtoint ptr %0 to i64
  %409 = ptrtoint ptr %2 to i64
  %410 = and i64 %407, %1
  %411 = and i64 %410, %407
  %412 = xor i64 %411, %408
  %413 = or i64 %412, %1
  %414 = and i64 %413, %408
  store i64 %414, ptr %4, align 8
  br label %221

415:                                              ; preds = %45
  %416 = load i64, ptr %4, align 8
  %417 = ptrtoint ptr %0 to i64
  %418 = ptrtoint ptr %2 to i64
  %419 = or i64 %418, %1
  %420 = mul i64 %419, %418
  %421 = or i64 %420, %416
  %422 = mul i64 %421, %416
  store i64 %422, ptr %4, align 8
  br label %221

423:                                              ; preds = %56
  %424 = load i64, ptr %4, align 8
  %425 = ptrtoint ptr %0 to i64
  %426 = ptrtoint ptr %2 to i64
  %427 = or i64 %424, %426
  %428 = or i64 %427, %425
  %429 = and i64 %428, %424
  %430 = or i64 %429, %1
  %431 = or i64 %430, %426
  %432 = add i64 %431, %424
  store i64 %432, ptr %4, align 8
  br label %221

433:                                              ; preds = %71
  %434 = load i64, ptr %4, align 8
  %435 = ptrtoint ptr %0 to i64
  %436 = ptrtoint ptr %2 to i64
  %437 = sub i64 %434, %434
  %438 = or i64 %437, %436
  %439 = mul i64 %438, %434
  store i64 %439, ptr %4, align 8
  br label %221

440:                                              ; preds = %89
  %441 = load i64, ptr %4, align 8
  %442 = ptrtoint ptr %0 to i64
  %443 = ptrtoint ptr %2 to i64
  %444 = xor i64 %443, %442
  %445 = sub i64 %444, %441
  %446 = xor i64 %445, %441
  %447 = xor i64 %446, %441
  %448 = sub i64 %447, %441
  store i64 %448, ptr %4, align 8
  br label %221

449:                                              ; preds = %104
  %450 = load i64, ptr %4, align 8
  %451 = ptrtoint ptr %0 to i64
  %452 = ptrtoint ptr %2 to i64
  %453 = and i64 %1, %452
  %454 = xor i64 %453, %452
  %455 = add i64 %454, %451
  %456 = sub i64 %455, %452
  store i64 %456, ptr %4, align 8
  br label %221

457:                                              ; preds = %117
  %458 = load i64, ptr %4, align 8
  %459 = ptrtoint ptr %0 to i64
  %460 = ptrtoint ptr %2 to i64
  %461 = sub i64 %1, %458
  %462 = and i64 %461, %458
  %463 = sub i64 %462, %458
  store i64 %463, ptr %4, align 8
  br label %221

464:                                              ; preds = %131
  %465 = load i64, ptr %4, align 8
  %466 = ptrtoint ptr %0 to i64
  %467 = ptrtoint ptr %2 to i64
  %468 = sub i64 %1, %1
  %469 = and i64 %468, %465
  %470 = sub i64 %469, %466
  %471 = xor i64 %470, %467
  %472 = sub i64 %471, %1
  %473 = or i64 %472, %467
  store i64 %473, ptr %4, align 8
  br label %221

474:                                              ; preds = %144
  %475 = load i64, ptr %4, align 8
  %476 = ptrtoint ptr %0 to i64
  %477 = ptrtoint ptr %2 to i64
  %478 = mul i64 %476, %477
  %479 = mul i64 %478, %476
  %480 = add i64 %479, %476
  %481 = add i64 %480, %476
  store i64 %481, ptr %4, align 8
  br label %221

482:                                              ; preds = %205
  %483 = load i64, ptr %4, align 8
  %484 = ptrtoint ptr %0 to i64
  %485 = ptrtoint ptr %2 to i64
  %486 = and i64 %485, %485
  %487 = or i64 %486, %484
  %488 = sub i64 %487, %485
  %489 = and i64 %488, %1
  %490 = or i64 %489, %483
  %491 = sub i64 %490, %485
  store i64 %491, ptr %4, align 8
  br label %221

492:                                              ; preds = %222
  %493 = load i64, ptr %4, align 8
  %494 = ptrtoint ptr %0 to i64
  %495 = ptrtoint ptr %2 to i64
  %496 = sub i64 %495, %1
  %497 = add i64 %496, %494
  %498 = sub i64 %497, %495
  %499 = or i64 %498, %495
  %500 = add i64 %499, %494
  store i64 %500, ptr %4, align 8
  br label %15

501:                                              ; preds = %231
  %502 = load i64, ptr %4, align 8
  %503 = ptrtoint ptr %0 to i64
  %504 = ptrtoint ptr %2 to i64
  %505 = and i64 %502, %1
  %506 = or i64 %505, %1
  %507 = sub i64 %506, %502
  %508 = sub i64 %507, %1
  store i64 %508, ptr %4, align 8
  br label %221

509:                                              ; preds = %244
  %510 = load i64, ptr %4, align 8
  %511 = ptrtoint ptr %0 to i64
  %512 = ptrtoint ptr %2 to i64
  %513 = mul i64 %1, %512
  %514 = add i64 %513, %512
  %515 = add i64 %514, %512
  %516 = add i64 %515, %1
  %517 = or i64 %516, %1
  %518 = or i64 %517, %510
  store i64 %518, ptr %4, align 8
  br label %221

519:                                              ; preds = %262
  %520 = load i64, ptr %4, align 8
  %521 = ptrtoint ptr %0 to i64
  %522 = ptrtoint ptr %2 to i64
  %523 = or i64 %520, %522
  %524 = sub i64 %523, %522
  %525 = and i64 %524, %1
  %526 = or i64 %525, %521
  %527 = xor i64 %526, %522
  store i64 %527, ptr %4, align 8
  br label %221

528:                                              ; preds = %275
  %529 = load i64, ptr %4, align 8
  %530 = ptrtoint ptr %0 to i64
  %531 = ptrtoint ptr %2 to i64
  %532 = xor i64 %529, %530
  %533 = and i64 %532, %1
  %534 = and i64 %533, %530
  store i64 %534, ptr %4, align 8
  br label %221

535:                                              ; preds = %287
  %536 = load i64, ptr %4, align 8
  %537 = ptrtoint ptr %0 to i64
  %538 = ptrtoint ptr %2 to i64
  %539 = mul i64 %538, %1
  %540 = sub i64 %539, %536
  %541 = mul i64 %540, %536
  store i64 %541, ptr %4, align 8
  br label %221

542:                                              ; preds = %300
  %543 = load i64, ptr %4, align 8
  %544 = ptrtoint ptr %0 to i64
  %545 = ptrtoint ptr %2 to i64
  %546 = xor i64 %1, %544
  %547 = and i64 %546, %545
  %548 = sub i64 %547, %544
  store i64 %548, ptr %4, align 8
  br label %221

549:                                              ; preds = %313
  %550 = load i64, ptr %4, align 8
  %551 = ptrtoint ptr %0 to i64
  %552 = ptrtoint ptr %2 to i64
  %553 = and i64 %550, %552
  %554 = xor i64 %553, %1
  %555 = sub i64 %554, %552
  %556 = and i64 %555, %550
  %557 = add i64 %556, %552
  store i64 %557, ptr %4, align 8
  br label %221

558:                                              ; preds = %326
  %559 = load i64, ptr %4, align 8
  %560 = ptrtoint ptr %0 to i64
  %561 = ptrtoint ptr %2 to i64
  %562 = or i64 %561, %559
  %563 = or i64 %562, %1
  %564 = add i64 %563, %559
  store i64 %564, ptr %4, align 8
  br label %221
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @check_table(ptr noundef %0, i64 noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i8, align 1
  %10 = alloca i64, align 8
  %11 = alloca i8, align 1
  %12 = alloca i8, align 1
  store i32 -1474034681, ptr %5, align 4
  br label %13

13:                                               ; preds = %301, %199, %198, %3
  %14 = load i32, ptr %5, align 4
  %15 = sub i32 %14, 2140570247
  %16 = mul i32 %15, -1512228233
  %17 = icmp slt i32 %16, 1386105336
  br i1 %17, label %256, label %258

18:                                               ; preds = %266
  store ptr %0, ptr %6, align 8
  store i64 %1, ptr %7, align 8
  store ptr %2, ptr %8, align 8
  store i8 0, ptr %9, align 1
  store i64 0, ptr %10, align 8
  store i32 319343265, ptr %5, align 4
  %19 = xor i64 %1, 1314671966557238339
  %20 = and i64 %1, %19
  %21 = or i64 %1, %19
  %22 = xor i64 %1, %19
  %23 = mul i64 %21, 2
  %24 = sub i64 %23, %22
  %25 = sub i64 %24, %1
  %26 = sub i64 %25, %19
  %27 = mul i64 %26, 249
  %28 = xor i64 %1, -7305152281728675891
  %29 = and i64 %1, %28
  %30 = or i64 %1, %28
  %31 = xor i64 %1, %28
  %32 = add i64 %1, %28
  %33 = sub i64 %32, %31
  %34 = mul i64 %29, 2
  %35 = sub i64 %33, %34
  %36 = mul i64 %35, 194
  %37 = icmp eq i64 %27, %36
  br i1 %37, label %198, label %276

38:                                               ; preds = %274
  %39 = load i64, ptr %10, align 8
  %40 = load i64, ptr %7, align 8
  %41 = icmp ult i64 %39, %40
  %42 = select i1 %41, i32 1116236635, i32 -709635161
  store i32 %42, ptr %5, align 4
  %43 = xor i64 %1, -1377715994340277603
  %44 = and i64 %1, %43
  %45 = or i64 %1, %43
  %46 = xor i64 %1, %43
  %47 = sub i64 %45, %46
  %48 = sub i64 %47, %44
  %49 = mul i64 %48, 190
  %50 = xor i64 %1, 611922831445057459
  %51 = and i64 %1, %50
  %52 = or i64 %1, %50
  %53 = xor i64 %1, %50
  %54 = mul i64 %52, 2
  %55 = sub i64 %54, %53
  %56 = sub i64 %55, %1
  %57 = sub i64 %56, %50
  %58 = mul i64 %57, 91
  %59 = icmp eq i64 %49, %58
  br i1 %59, label %198, label %283

60:                                               ; preds = %262
  %61 = load ptr, ptr %6, align 8
  %62 = load i64, ptr %10, align 8
  %63 = getelementptr inbounds nuw i8, ptr %61, i64 %62
  %64 = load i8, ptr %63, align 1
  store i8 %64, ptr %11, align 1
  %65 = load i8, ptr %11, align 1
  %66 = zext i8 %65 to i32
  %67 = load i64, ptr %10, align 8
  %68 = urem i64 %67, 7
  %69 = getelementptr inbounds nuw [7 x i8], ptr @check_table.k, i64 0, i64 %68
  %70 = load i8, ptr %69, align 1
  %71 = zext i8 %70 to i32
  %72 = or i32 %66, %71
  %73 = and i32 %66, %71
  %74 = sub i32 %72, %73
  %75 = load i64, ptr %10, align 8
  %76 = mul i64 %75, 13
  %77 = trunc i64 %76 to i8
  %78 = zext i8 %77 to i32
  %79 = or i32 %74, %78
  %80 = and i32 %74, %78
  %81 = add i32 %79, %80
  %82 = trunc i32 %81 to i8
  store i8 %82, ptr %12, align 1
  %83 = load i8, ptr %12, align 1
  %84 = zext i8 %83 to i32
  %85 = load i64, ptr %10, align 8
  %86 = getelementptr inbounds nuw [14 x i8], ptr @check_table.target, i64 0, i64 %85
  %87 = load i8, ptr %86, align 1
  %88 = zext i8 %87 to i32
  %89 = add i32 %84, %88
  %90 = and i32 %84, %88
  %91 = add i32 %90, %90
  %92 = sub i32 %89, %91
  %93 = trunc i32 %92 to i8
  %94 = zext i8 %93 to i32
  %95 = load i8, ptr %9, align 1
  %96 = zext i8 %95 to i32
  %97 = xor i32 %96, %94
  %98 = and i32 %96, %94
  %99 = load i32, ptr %5, align 4
  %100 = xor i32 %99, 2129154146
  %101 = mul i32 %97, %100
  %102 = load i32, ptr %5, align 4
  %103 = xor i32 %102, 2129154146
  %104 = mul i32 %98, %103
  %105 = add i32 %101, %104
  %106 = load i32, ptr %5, align 4
  %107 = xor i32 %106, 1736000976
  %108 = mul i32 %105, %107
  %109 = load i32, ptr %5, align 4
  %110 = xor i32 %109, 1258541152
  %111 = mul i32 %108, %110
  %112 = trunc i32 %111 to i8
  store i8 %112, ptr %9, align 1
  %113 = load i8, ptr %11, align 1
  %114 = zext i8 %113 to i32
  %115 = load i64, ptr %10, align 8
  %116 = mul i64 %115, 5
  %117 = add i64 %116, 63
  %118 = or i64 %116, 63
  %119 = sub i64 %117, %118
  %120 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %119
  %121 = load i8, ptr %120, align 1
  %122 = zext i8 %121 to i32
  %123 = xor i32 %114, %122
  %124 = and i32 %114, %122
  %125 = add i32 %124, %124
  %126 = add i32 %123, %125
  %127 = load i32, ptr %5, align 4
  %128 = xor i32 %127, 1116236708
  %129 = add i32 %126, %128
  %130 = load i32, ptr %5, align 4
  %131 = xor i32 %130, 1116236708
  %132 = or i32 %126, %131
  %133 = load i32, ptr %5, align 4
  %134 = xor i32 %133, 959199558
  %135 = mul i32 %129, %134
  %136 = load i32, ptr %5, align 4
  %137 = xor i32 %136, 959199558
  %138 = mul i32 %132, %137
  %139 = sub i32 %135, %138
  %140 = load i32, ptr %5, align 4
  %141 = xor i32 %140, 327117678
  %142 = mul i32 %139, %141
  %143 = load i64, ptr %10, align 8
  %144 = mul i64 %143, 11
  %145 = or i64 165, %144
  %146 = and i64 165, %144
  %147 = add i64 %145, %146
  %148 = trunc i64 %147 to i8
  %149 = zext i8 %148 to i32
  %150 = add i32 %142, %149
  %151 = and i32 %142, %149
  %152 = load i32, ptr %5, align 4
  %153 = xor i32 %152, -1749695656
  %154 = mul i32 %150, %153
  %155 = load i32, ptr %5, align 4
  %156 = xor i32 %155, -1749695656
  %157 = mul i32 %151, %156
  %158 = add i32 %157, %157
  %159 = sub i32 %154, %158
  %160 = load i32, ptr %5, align 4
  %161 = xor i32 %160, 647747590
  %162 = mul i32 %159, %161
  %163 = load i32, ptr %5, align 4
  %164 = xor i32 %163, -555983108
  %165 = mul i32 %162, %164
  %166 = trunc i32 %165 to i8
  %167 = load ptr, ptr %8, align 8
  %168 = load i64, ptr %10, align 8
  %169 = getelementptr inbounds nuw i8, ptr %167, i64 %168
  store i8 %166, ptr %169, align 1
  %170 = load i64, ptr %10, align 8
  %171 = or i64 %170, 1
  %172 = and i64 %170, 1
  %173 = add i64 %171, %172
  store i64 %173, ptr %10, align 8
  store i32 319343265, ptr %5, align 4
  %174 = xor i64 %1, -3843486001649476691
  %175 = and i64 %1, %174
  %176 = or i64 %1, %174
  %177 = xor i64 %1, %174
  %178 = add i64 %1, %174
  %179 = sub i64 %178, %177
  %180 = mul i64 %175, 2
  %181 = sub i64 %179, %180
  %182 = mul i64 %181, 3
  %183 = xor i64 %1, -8993763113104628957
  %184 = and i64 %1, %183
  %185 = or i64 %1, %183
  %186 = xor i64 %1, %183
  %187 = mul i64 %185, 2
  %188 = sub i64 %187, %186
  %189 = sub i64 %188, %1
  %190 = sub i64 %189, %183
  %191 = mul i64 %190, 207
  %192 = icmp ne i64 %182, %191
  br i1 %192, label %292, label %198

193:                                              ; preds = %272
  %194 = load i8, ptr %9, align 1
  %195 = zext i8 %194 to i32
  %196 = icmp eq i32 %195, 0
  %197 = zext i1 %196 to i32
  ret i32 %197

198:                                              ; preds = %331, %324, %315, %308, %292, %283, %276, %244, %232, %220, %209, %60, %38, %18
  br label %13

199:                                              ; preds = %274, %272, %266, %264
  store i32 -1474034681, ptr %5, align 4
  call void asm sideeffect "", ""()
  %200 = xor i64 %1, 3540017865170112239
  %201 = and i64 %1, %200
  %202 = or i64 %1, %200
  %203 = xor i64 %1, %200
  %204 = add i64 %201, %202
  %205 = sub i64 %204, %1
  %206 = sub i64 %205, %200
  %207 = mul i64 %206, 164
  %208 = icmp sle i64 %207, 0
  br i1 %208, label %13, label %301

209:                                              ; preds = %264
  %210 = load i32, ptr %5, align 4
  %211 = xor i32 %210, 1604992080
  store i32 %211, ptr %5, align 4
  %212 = xor i64 %1, 2551280510160212203
  %213 = and i64 %1, %212
  %214 = or i64 %1, %212
  %215 = xor i64 %1, %212
  %216 = sub i64 %214, %215
  %217 = sub i64 %216, %213
  %218 = mul i64 %217, 180
  %219 = icmp ne i64 %218, 0
  br i1 %219, label %308, label %198

220:                                              ; preds = %270
  %221 = load i32, ptr %5, align 4
  %222 = xor i32 %221, -275168634
  store i32 %222, ptr %5, align 4
  %223 = xor i64 %1, 6715895571918150137
  %224 = and i64 %1, %223
  %225 = or i64 %1, %223
  %226 = xor i64 %1, %223
  %227 = add i64 %224, %225
  %228 = sub i64 %227, %1
  %229 = sub i64 %228, %223
  %230 = mul i64 %229, 144
  %231 = icmp slt i64 %230, 0
  br i1 %231, label %315, label %198

232:                                              ; preds = %268
  %233 = load i32, ptr %5, align 4
  %234 = xor i32 %233, 1879617928
  store i32 %234, ptr %5, align 4
  %235 = xor i64 %1, 8660548416049043001
  %236 = and i64 %1, %235
  %237 = or i64 %1, %235
  %238 = xor i64 %1, %235
  %239 = add i64 %236, %237
  %240 = sub i64 %239, %1
  %241 = sub i64 %240, %235
  %242 = mul i64 %241, 54
  %243 = icmp slt i64 %242, 1
  br i1 %243, label %198, label %324

244:                                              ; preds = %260
  %245 = load i32, ptr %5, align 4
  %246 = xor i32 %245, -1217944472
  store i32 %246, ptr %5, align 4
  %247 = xor i64 %1, -7692427169651835185
  %248 = and i64 %1, %247
  %249 = or i64 %1, %247
  %250 = xor i64 %1, %247
  %251 = add i64 %248, %249
  %252 = sub i64 %251, %1
  %253 = sub i64 %252, %247
  %254 = mul i64 %253, 219
  %255 = icmp eq i64 %254, 0
  br i1 %255, label %198, label %331

256:                                              ; preds = %13
  %257 = icmp slt i32 %16, 272056972
  br i1 %257, label %260, label %262

258:                                              ; preds = %13
  %259 = icmp slt i32 %16, 1471606390
  br i1 %259, label %268, label %270

260:                                              ; preds = %256
  %261 = icmp eq i32 %16, 242871345
  br i1 %261, label %244, label %264

262:                                              ; preds = %256
  %263 = icmp eq i32 %16, 272056972
  br i1 %263, label %60, label %266

264:                                              ; preds = %260
  %265 = icmp eq i32 %16, 269482441
  br i1 %265, label %209, label %199

266:                                              ; preds = %262
  %267 = icmp eq i32 %16, 882782848
  br i1 %267, label %18, label %199

268:                                              ; preds = %258
  %269 = icmp eq i32 %16, 1386105336
  br i1 %269, label %232, label %272

270:                                              ; preds = %258
  %271 = icmp eq i32 %16, 1471606390
  br i1 %271, label %220, label %274

272:                                              ; preds = %268
  %273 = icmp eq i32 %16, 1419900384
  br i1 %273, label %193, label %199

274:                                              ; preds = %270
  %275 = icmp eq i32 %16, 1860659222
  br i1 %275, label %38, label %199

276:                                              ; preds = %18
  %277 = load i64, ptr %4, align 8
  %278 = ptrtoint ptr %0 to i64
  %279 = ptrtoint ptr %2 to i64
  %280 = xor i64 %278, %278
  %281 = xor i64 %280, %278
  %282 = xor i64 %281, %277
  store i64 %282, ptr %4, align 8
  br label %198

283:                                              ; preds = %38
  %284 = load i64, ptr %4, align 8
  %285 = ptrtoint ptr %0 to i64
  %286 = ptrtoint ptr %2 to i64
  %287 = mul i64 %286, %284
  %288 = or i64 %287, %284
  %289 = sub i64 %288, %284
  %290 = and i64 %289, %286
  %291 = and i64 %290, %285
  store i64 %291, ptr %4, align 8
  br label %198

292:                                              ; preds = %60
  %293 = load i64, ptr %4, align 8
  %294 = ptrtoint ptr %0 to i64
  %295 = ptrtoint ptr %2 to i64
  %296 = mul i64 %1, %295
  %297 = add i64 %296, %293
  %298 = xor i64 %297, %294
  %299 = sub i64 %298, %1
  %300 = or i64 %299, %1
  store i64 %300, ptr %4, align 8
  br label %198

301:                                              ; preds = %199
  %302 = load i64, ptr %4, align 8
  %303 = ptrtoint ptr %0 to i64
  %304 = ptrtoint ptr %2 to i64
  %305 = xor i64 %1, %304
  %306 = or i64 %305, %1
  %307 = and i64 %306, %304
  store i64 %307, ptr %4, align 8
  br label %13

308:                                              ; preds = %209
  %309 = load i64, ptr %4, align 8
  %310 = ptrtoint ptr %0 to i64
  %311 = ptrtoint ptr %2 to i64
  %312 = mul i64 %309, %1
  %313 = xor i64 %312, %1
  %314 = mul i64 %313, %309
  store i64 %314, ptr %4, align 8
  br label %198

315:                                              ; preds = %220
  %316 = load i64, ptr %4, align 8
  %317 = ptrtoint ptr %0 to i64
  %318 = ptrtoint ptr %2 to i64
  %319 = mul i64 %316, %317
  %320 = xor i64 %319, %316
  %321 = or i64 %320, %1
  %322 = sub i64 %321, %318
  %323 = or i64 %322, %316
  store i64 %323, ptr %4, align 8
  br label %198

324:                                              ; preds = %232
  %325 = load i64, ptr %4, align 8
  %326 = ptrtoint ptr %0 to i64
  %327 = ptrtoint ptr %2 to i64
  %328 = sub i64 %325, %325
  %329 = or i64 %328, %1
  %330 = mul i64 %329, %327
  store i64 %330, ptr %4, align 8
  br label %198

331:                                              ; preds = %244
  %332 = load i64, ptr %4, align 8
  %333 = ptrtoint ptr %0 to i64
  %334 = ptrtoint ptr %2 to i64
  %335 = and i64 %334, %332
  %336 = add i64 %335, %1
  %337 = xor i64 %336, %332
  %338 = mul i64 %337, %1
  %339 = mul i64 %338, %333
  %340 = sub i64 %339, %334
  store i64 %340, ptr %4, align 8
  br label %198
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @check_hash(ptr noundef %0, i64 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i64, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i64 %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %10 = load ptr, ptr %4, align 8
  %11 = load i64, ptr %5, align 8
  %12 = call i32 @checksum32(ptr noundef %10, i64 noundef %11)
  store i32 %12, ptr %7, align 4
  %13 = load ptr, ptr %6, align 8
  %14 = load i64, ptr %5, align 8
  %15 = call i32 @checksum32(ptr noundef %13, i64 noundef %14)
  store i32 %15, ptr %8, align 4
  %16 = load ptr, ptr %4, align 8
  %17 = load i64, ptr %5, align 8
  %18 = call i32 @graph_mix(ptr noundef %16, i64 noundef %17)
  store i32 %18, ptr %9, align 4
  %19 = load i32, ptr %7, align 4
  %20 = add i32 %19, -1577194447
  %21 = and i32 %19, -1577194447
  %22 = add i32 %21, %21
  %23 = sub i32 %20, %22
  %24 = load i32, ptr %8, align 4
  %25 = add i32 %24, -296954887
  %26 = and i32 %24, -296954887
  %27 = mul i32 %25, 1548445105
  %28 = mul i32 %26, 1548445105
  %29 = add i32 %28, %28
  %30 = sub i32 %27, %29
  %31 = mul i32 %30, -1420747601
  %32 = mul i32 %31, -44752897
  %33 = add i32 %23, %32
  %34 = and i32 %23, %32
  %35 = sub i32 %33, %34
  %36 = load i32, ptr %9, align 4
  %37 = add i32 %36, 1896214013
  %38 = and i32 %36, 1896214013
  %39 = mul i32 %37, 724356461
  %40 = mul i32 %38, 724356461
  %41 = add i32 %40, %40
  %42 = sub i32 %39, %41
  %43 = mul i32 %42, 613041253
  %44 = xor i32 %35, %43
  %45 = and i32 %35, %43
  %46 = mul i32 %44, -1699903491
  %47 = mul i32 %45, -1699903491
  %48 = add i32 %46, %47
  %49 = mul i32 %48, -1098773163
  %50 = icmp eq i32 %49, 0
  %51 = zext i1 %50 to i32
  ret i32 %51
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @check_heap_stack(ptr noundef %0, i64 noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i64, align 8
  %9 = alloca ptr, align 8
  %10 = alloca [14 x i8], align 1
  %11 = alloca ptr, align 8
  %12 = alloca i64, align 8
  %13 = alloca i32, align 4
  %14 = alloca i64, align 8
  store i32 -1708651783, ptr %5, align 4
  br label %15

15:                                               ; preds = %509, %251, %250, %3
  %16 = load i32, ptr %5, align 4
  %17 = sub i32 %16, -1783159037
  %18 = mul i32 %17, -498650393
  %19 = icmp slt i32 %18, 841340778
  br i1 %19, label %378, label %380

20:                                               ; preds = %422
  store ptr %0, ptr %7, align 8
  store i64 %1, ptr %8, align 8
  store ptr %2, ptr %9, align 8
  %21 = load ptr, ptr %7, align 8
  %22 = load i64, ptr %8, align 8
  %23 = or i64 %22, 1
  %24 = and i64 %22, 1
  %25 = add i64 %23, %24
  %26 = call noalias ptr @malloc(i64 noundef %25) #8
  store ptr %26, ptr %11, align 8
  %27 = load ptr, ptr %11, align 8
  %28 = icmp ne ptr %27, null
  %29 = select i1 %28, i32 594930042, i32 1530433801
  store i32 %29, ptr %5, align 4
  %30 = xor i64 %1, -6775507819671740357
  %31 = and i64 %1, %30
  %32 = or i64 %1, %30
  %33 = xor i64 %1, %30
  %34 = mul i64 %32, 2
  %35 = sub i64 %34, %33
  %36 = sub i64 %35, %1
  %37 = sub i64 %36, %30
  %38 = mul i64 %37, 84
  %39 = icmp ne i64 %38, 0
  br i1 %39, label %430, label %250

40:                                               ; preds = %410
  store i32 0, ptr %6, align 4
  store i32 -2119229873, ptr %5, align 4
  %41 = xor i64 %1, 4524514296223678263
  %42 = and i64 %1, %41
  %43 = or i64 %1, %41
  %44 = xor i64 %1, %41
  %45 = add i64 %1, %41
  %46 = sub i64 %45, %44
  %47 = mul i64 %42, 2
  %48 = sub i64 %46, %47
  %49 = mul i64 %48, 149
  %50 = icmp uge i64 %49, 0
  br i1 %50, label %250, label %437

51:                                               ; preds = %404
  store i64 0, ptr %12, align 8
  store i32 703272362, ptr %5, align 4
  %52 = xor i64 %1, -2151285180163743837
  %53 = and i64 %1, %52
  %54 = or i64 %1, %52
  %55 = xor i64 %1, %52
  %56 = mul i64 %54, 2
  %57 = sub i64 %56, %55
  %58 = sub i64 %57, %1
  %59 = sub i64 %58, %52
  %60 = mul i64 %59, 97
  %61 = icmp sle i64 %60, 0
  br i1 %61, label %250, label %444

62:                                               ; preds = %428
  %63 = load i64, ptr %12, align 8
  %64 = load i64, ptr %8, align 8
  %65 = icmp ult i64 %63, %64
  %66 = select i1 %65, i32 -2132846424, i32 798809
  store i32 %66, ptr %5, align 4
  %67 = xor i64 %1, -6884356077545192609
  %68 = and i64 %1, %67
  %69 = or i64 %1, %67
  %70 = xor i64 %1, %67
  %71 = sub i64 %69, %70
  %72 = sub i64 %71, %68
  %73 = mul i64 %72, 127
  %74 = icmp slt i64 %73, 1
  br i1 %74, label %250, label %452

75:                                               ; preds = %426
  %76 = load ptr, ptr %9, align 8
  %77 = load i64, ptr %8, align 8
  %78 = add i64 %77, -2
  %79 = add i64 %78, 1
  %80 = load i64, ptr %12, align 8
  %81 = xor i64 %80, -1
  %82 = add i64 %79, %81
  %83 = add i64 %82, 1
  %84 = getelementptr inbounds nuw i8, ptr %76, i64 %83
  %85 = load i8, ptr %84, align 1
  %86 = zext i8 %85 to i32
  %87 = load i64, ptr %12, align 8
  %88 = mul i64 %87, 9
  %89 = xor i64 61, %88
  %90 = and i64 61, %88
  %91 = add i64 %90, %90
  %92 = add i64 %89, %91
  %93 = trunc i64 %92 to i8
  %94 = zext i8 %93 to i32
  %95 = add i32 %86, %94
  %96 = and i32 %86, %94
  %97 = load i32, ptr %5, align 4
  %98 = xor i32 %97, -1350805893
  %99 = mul i32 %95, %98
  %100 = load i32, ptr %5, align 4
  %101 = xor i32 %100, -1350805893
  %102 = mul i32 %96, %101
  %103 = add i32 %102, %102
  %104 = sub i32 %99, %103
  %105 = load i32, ptr %5, align 4
  %106 = xor i32 %105, -1765837801
  %107 = mul i32 %104, %106
  %108 = load i32, ptr %5, align 4
  %109 = xor i32 %108, 1478293197
  %110 = mul i32 %107, %109
  %111 = trunc i32 %110 to i8
  %112 = load i64, ptr %12, align 8
  %113 = getelementptr inbounds nuw [14 x i8], ptr %10, i64 0, i64 %112
  store i8 %111, ptr %113, align 1
  %114 = load i64, ptr %12, align 8
  %115 = getelementptr inbounds nuw [14 x i8], ptr %10, i64 0, i64 %114
  %116 = load i8, ptr %115, align 1
  %117 = zext i8 %116 to i32
  %118 = load i64, ptr %12, align 8
  %119 = mul i64 %118, 11
  %120 = or i64 %119, 5
  %121 = and i64 %119, 5
  %122 = add i64 %120, %121
  %123 = add i64 %122, 63
  %124 = or i64 %122, 63
  %125 = sub i64 %123, %124
  %126 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %125
  %127 = load i8, ptr %126, align 1
  %128 = zext i8 %127 to i32
  %129 = xor i32 %117, %128
  %130 = and i32 %117, %128
  %131 = add i32 %130, %130
  %132 = add i32 %129, %131
  %133 = trunc i32 %132 to i8
  %134 = load ptr, ptr %11, align 8
  %135 = load i64, ptr %12, align 8
  %136 = getelementptr inbounds nuw i8, ptr %134, i64 %135
  store i8 %133, ptr %136, align 1
  %137 = load i64, ptr %12, align 8
  %138 = xor i64 %137, 1
  %139 = and i64 %137, 1
  %140 = add i64 %139, %139
  %141 = add i64 %138, %140
  store i64 %141, ptr %12, align 8
  store i32 703272362, ptr %5, align 4
  %142 = xor i64 %1, -2547592779834382449
  %143 = and i64 %1, %142
  %144 = or i64 %1, %142
  %145 = xor i64 %1, %142
  %146 = mul i64 %144, 2
  %147 = sub i64 %146, %145
  %148 = sub i64 %147, %1
  %149 = sub i64 %148, %142
  %150 = mul i64 %149, 146
  %151 = icmp ugt i64 %150, 0
  br i1 %151, label %462, label %250

152:                                              ; preds = %394
  %153 = load ptr, ptr %11, align 8
  %154 = load i64, ptr %8, align 8
  %155 = getelementptr inbounds nuw i8, ptr %153, i64 %154
  store i8 0, ptr %155, align 1
  store i32 826366246, ptr %13, align 4
  store i64 0, ptr %14, align 8
  store i32 1833226197, ptr %5, align 4
  %156 = xor i64 %1, -359750889398242079
  %157 = and i64 %1, %156
  %158 = or i64 %1, %156
  %159 = xor i64 %1, %156
  %160 = sub i64 %158, %159
  %161 = sub i64 %160, %157
  %162 = mul i64 %161, 52
  %163 = icmp slt i64 %162, 0
  br i1 %163, label %472, label %250

164:                                              ; preds = %418
  %165 = load i64, ptr %14, align 8
  %166 = load i64, ptr %8, align 8
  %167 = icmp ult i64 %165, %166
  %168 = select i1 %167, i32 -1875873904, i32 815513145
  store i32 %168, ptr %5, align 4
  %169 = xor i64 %1, 347181835268364803
  %170 = and i64 %1, %169
  %171 = or i64 %1, %169
  %172 = xor i64 %1, %169
  %173 = sub i64 %171, %172
  %174 = sub i64 %173, %170
  %175 = mul i64 %174, 104
  %176 = icmp ugt i64 %175, 0
  br i1 %176, label %482, label %250

177:                                              ; preds = %416
  %178 = load i32, ptr %13, align 4
  %179 = load ptr, ptr %11, align 8
  %180 = load i64, ptr %14, align 8
  %181 = getelementptr inbounds nuw i8, ptr %179, i64 %180
  %182 = load i8, ptr %181, align 1
  %183 = zext i8 %182 to i32
  %184 = xor i32 %178, %183
  %185 = and i32 %178, %183
  %186 = add i32 %185, %185
  %187 = add i32 %184, %186
  %188 = load i64, ptr %14, align 8
  %189 = mul i64 %188, 17
  %190 = trunc i64 %189 to i32
  %191 = xor i32 %187, %190
  %192 = and i32 %187, %190
  %193 = add i32 %192, %192
  %194 = add i32 %191, %193
  %195 = call i32 @rol32(i32 noundef %194, i32 noundef 4)
  store i32 %195, ptr %13, align 4
  %196 = load i64, ptr %14, align 8
  %197 = getelementptr inbounds nuw [14 x i8], ptr %10, i64 0, i64 %196
  %198 = load i8, ptr %197, align 1
  %199 = zext i8 %198 to i32
  %200 = load i32, ptr %5, align 4
  %201 = xor i32 %200, -1859031407
  %202 = mul i32 %199, %201
  %203 = load i32, ptr %13, align 4
  %204 = add i32 %203, %202
  %205 = and i32 %203, %202
  %206 = load i32, ptr %5, align 4
  %207 = xor i32 %206, -1743372899
  %208 = mul i32 %204, %207
  %209 = load i32, ptr %5, align 4
  %210 = xor i32 %209, -1743372899
  %211 = mul i32 %205, %210
  %212 = add i32 %211, %211
  %213 = sub i32 %208, %212
  %214 = load i32, ptr %5, align 4
  %215 = xor i32 %214, 1681072981
  %216 = mul i32 %213, %215
  store i32 %216, ptr %13, align 4
  %217 = load i32, ptr %13, align 4
  %218 = call i32 @mix32(i32 noundef %217)
  store i32 %218, ptr %13, align 4
  %219 = load i64, ptr %14, align 8
  %220 = sub i64 %219, 1
  %221 = mul i64 %219, 2
  %222 = mul i64 1, %220
  %223 = sub i64 %221, %222
  store i64 %223, ptr %14, align 8
  store i32 1833226197, ptr %5, align 4
  %224 = xor i64 %1, 1216535023259697119
  %225 = and i64 %1, %224
  %226 = or i64 %1, %224
  %227 = xor i64 %1, %224
  %228 = add i64 %1, %224
  %229 = sub i64 %228, %227
  %230 = mul i64 %225, 2
  %231 = sub i64 %229, %230
  %232 = mul i64 %231, 223
  %233 = icmp uge i64 %232, 0
  br i1 %233, label %250, label %492

234:                                              ; preds = %386
  %235 = load ptr, ptr %11, align 8
  call void @free(ptr noundef %235) #6
  %236 = load i32, ptr %13, align 4
  %237 = icmp eq i32 %236, 783815019
  %238 = zext i1 %237 to i32
  store i32 %238, ptr %6, align 4
  store i32 -2119229873, ptr %5, align 4
  %239 = xor i64 %1, 6645205589130630127
  %240 = and i64 %1, %239
  %241 = or i64 %1, %239
  %242 = xor i64 %1, %239
  %243 = add i64 %240, %241
  %244 = sub i64 %243, %1
  %245 = sub i64 %244, %239
  %246 = mul i64 %245, 168
  %247 = icmp ugt i64 %246, 0
  br i1 %247, label %501, label %250

248:                                              ; preds = %390
  %249 = load i32, ptr %6, align 4
  ret i32 %249

250:                                              ; preds = %577, %569, %560, %553, %543, %536, %526, %518, %501, %492, %482, %472, %462, %452, %444, %437, %430, %360, %348, %336, %318, %305, %293, %274, %261, %234, %177, %164, %152, %75, %62, %51, %40, %20
  br label %15

251:                                              ; preds = %428, %424, %422, %416, %414, %404, %400, %398, %392, %390
  store i32 -1708651783, ptr %5, align 4
  call void asm sideeffect "", ""()
  %252 = xor i64 %1, 3843083846294714797
  %253 = and i64 %1, %252
  %254 = or i64 %1, %252
  %255 = xor i64 %1, %252
  %256 = add i64 %253, %254
  %257 = sub i64 %256, %1
  %258 = sub i64 %257, %252
  %259 = mul i64 %258, 161
  %260 = icmp uge i64 %259, 0
  br i1 %260, label %15, label %509

261:                                              ; preds = %400
  %262 = load i32, ptr %5, align 4
  %263 = xor i32 %262, 1180738867
  store i32 %263, ptr %5, align 4
  %264 = xor i64 %1, 7915316668114341557
  %265 = and i64 %1, %264
  %266 = or i64 %1, %264
  %267 = xor i64 %1, %264
  %268 = mul i64 %266, 2
  %269 = sub i64 %268, %267
  %270 = sub i64 %269, %1
  %271 = sub i64 %270, %264
  %272 = mul i64 %271, 98
  %273 = icmp slt i64 %272, 0
  br i1 %273, label %518, label %250

274:                                              ; preds = %388
  %275 = load i32, ptr %5, align 4
  %276 = xor i32 %275, 1138060943
  store i32 %276, ptr %5, align 4
  %277 = xor i64 %1, -1997280642260994253
  %278 = and i64 %1, %277
  %279 = or i64 %1, %277
  %280 = xor i64 %1, %277
  %281 = sub i64 %279, %280
  %282 = sub i64 %281, %278
  %283 = mul i64 %282, 195
  %284 = xor i64 %1, -4150170110672400773
  %285 = and i64 %1, %284
  %286 = or i64 %1, %284
  %287 = xor i64 %1, %284
  %288 = add i64 %285, %286
  %289 = sub i64 %288, %1
  %290 = sub i64 %289, %284
  %291 = mul i64 %290, 75
  %292 = icmp eq i64 %283, %291
  br i1 %292, label %250, label %526

293:                                              ; preds = %402
  %294 = load i32, ptr %5, align 4
  %295 = xor i32 %294, 1740607995
  store i32 %295, ptr %5, align 4
  %296 = xor i64 %1, -8310865443805404371
  %297 = and i64 %1, %296
  %298 = or i64 %1, %296
  %299 = xor i64 %1, %296
  %300 = add i64 %297, %298
  %301 = sub i64 %300, %1
  %302 = sub i64 %301, %296
  %303 = mul i64 %302, 27
  %304 = icmp ne i64 %303, 0
  br i1 %304, label %536, label %250

305:                                              ; preds = %412
  %306 = load i32, ptr %5, align 4
  %307 = xor i32 %306, -712396501
  store i32 %307, ptr %5, align 4
  %308 = xor i64 %1, -1307950082911206809
  %309 = and i64 %1, %308
  %310 = or i64 %1, %308
  %311 = xor i64 %1, %308
  %312 = mul i64 %310, 2
  %313 = sub i64 %312, %311
  %314 = sub i64 %313, %1
  %315 = sub i64 %314, %308
  %316 = mul i64 %315, 239
  %317 = icmp ne i64 %316, 0
  br i1 %317, label %543, label %250

318:                                              ; preds = %414
  %319 = load i32, ptr %5, align 4
  %320 = xor i32 %319, 1253782112
  store i32 %320, ptr %5, align 4
  %321 = xor i64 %1, -675006459332936139
  %322 = and i64 %1, %321
  %323 = or i64 %1, %321
  %324 = xor i64 %1, %321
  %325 = sub i64 %323, %324
  %326 = sub i64 %325, %322
  %327 = mul i64 %326, 59
  %328 = xor i64 %1, 8825380029527545107
  %329 = and i64 %1, %328
  %330 = or i64 %1, %328
  %331 = xor i64 %1, %328
  %332 = sub i64 %330, %331
  %333 = sub i64 %332, %329
  %334 = mul i64 %333, 161
  %335 = icmp eq i64 %327, %334
  br i1 %335, label %250, label %553

336:                                              ; preds = %392
  %337 = load i32, ptr %5, align 4
  %338 = xor i32 %337, 438723031
  store i32 %338, ptr %5, align 4
  %339 = xor i64 %1, 8184144277360186593
  %340 = and i64 %1, %339
  %341 = or i64 %1, %339
  %342 = xor i64 %1, %339
  %343 = add i64 %340, %341
  %344 = sub i64 %343, %1
  %345 = sub i64 %344, %339
  %346 = mul i64 %345, 49
  %347 = icmp slt i64 %346, 1
  br i1 %347, label %250, label %560

348:                                              ; preds = %424
  %349 = load i32, ptr %5, align 4
  %350 = xor i32 %349, -1519340599
  store i32 %350, ptr %5, align 4
  %351 = xor i64 %1, -4583320772651430069
  %352 = and i64 %1, %351
  %353 = or i64 %1, %351
  %354 = xor i64 %1, %351
  %355 = add i64 %352, %353
  %356 = sub i64 %355, %1
  %357 = sub i64 %356, %351
  %358 = mul i64 %357, 113
  %359 = icmp ugt i64 %358, 0
  br i1 %359, label %569, label %250

360:                                              ; preds = %398
  %361 = load i32, ptr %5, align 4
  %362 = xor i32 %361, -1947165355
  store i32 %362, ptr %5, align 4
  %363 = xor i64 %1, -5235893091623589429
  %364 = and i64 %1, %363
  %365 = or i64 %1, %363
  %366 = xor i64 %1, %363
  %367 = sub i64 %365, %366
  %368 = sub i64 %367, %364
  %369 = mul i64 %368, 43
  %370 = xor i64 %1, -7703440802829685405
  %371 = and i64 %1, %370
  %372 = or i64 %1, %370
  %373 = xor i64 %1, %370
  %374 = sub i64 %372, %373
  %375 = sub i64 %374, %371
  %376 = mul i64 %375, 221
  %377 = icmp eq i64 %369, %376
  br i1 %377, label %250, label %577

378:                                              ; preds = %15
  %379 = icmp slt i32 %18, 292042906
  br i1 %379, label %382, label %384

380:                                              ; preds = %15
  %381 = icmp slt i32 %18, 1644845438
  br i1 %381, label %406, label %408

382:                                              ; preds = %378
  %383 = icmp slt i32 %18, 236268670
  br i1 %383, label %386, label %388

384:                                              ; preds = %378
  %385 = icmp slt i32 %18, 431352959
  br i1 %385, label %394, label %396

386:                                              ; preds = %382
  %387 = icmp eq i32 %18, 96927162
  br i1 %387, label %234, label %390

388:                                              ; preds = %382
  %389 = icmp eq i32 %18, 236268670
  br i1 %389, label %274, label %392

390:                                              ; preds = %386
  %391 = icmp eq i32 %18, 153157012
  br i1 %391, label %248, label %251

392:                                              ; preds = %388
  %393 = icmp eq i32 %18, 281851214
  br i1 %393, label %336, label %251

394:                                              ; preds = %384
  %395 = icmp eq i32 %18, 292042906
  br i1 %395, label %152, label %398

396:                                              ; preds = %384
  %397 = icmp slt i32 %18, 506286466
  br i1 %397, label %400, label %402

398:                                              ; preds = %394
  %399 = icmp eq i32 %18, 358263713
  br i1 %399, label %360, label %251

400:                                              ; preds = %396
  %401 = icmp eq i32 %18, 431352959
  br i1 %401, label %261, label %251

402:                                              ; preds = %396
  %403 = icmp eq i32 %18, 506286466
  br i1 %403, label %293, label %404

404:                                              ; preds = %402
  %405 = icmp eq i32 %18, 639481697
  br i1 %405, label %51, label %251

406:                                              ; preds = %380
  %407 = icmp slt i32 %18, 1132665959
  br i1 %407, label %410, label %412

408:                                              ; preds = %380
  %409 = icmp slt i32 %18, 1973155020
  br i1 %409, label %418, label %420

410:                                              ; preds = %406
  %411 = icmp eq i32 %18, 841340778
  br i1 %411, label %40, label %414

412:                                              ; preds = %406
  %413 = icmp eq i32 %18, 1132665959
  br i1 %413, label %305, label %416

414:                                              ; preds = %410
  %415 = icmp eq i32 %18, 857626387
  br i1 %415, label %318, label %251

416:                                              ; preds = %412
  %417 = icmp eq i32 %18, 1287061819
  br i1 %417, label %177, label %251

418:                                              ; preds = %408
  %419 = icmp eq i32 %18, 1644845438
  br i1 %419, label %164, label %422

420:                                              ; preds = %408
  %421 = icmp slt i32 %18, 2042234339
  br i1 %421, label %424, label %426

422:                                              ; preds = %418
  %423 = icmp eq i32 %18, 1939717882
  br i1 %423, label %20, label %251

424:                                              ; preds = %420
  %425 = icmp eq i32 %18, 1973155020
  br i1 %425, label %348, label %251

426:                                              ; preds = %420
  %427 = icmp eq i32 %18, 2042234339
  br i1 %427, label %75, label %428

428:                                              ; preds = %426
  %429 = icmp eq i32 %18, 2110387889
  br i1 %429, label %62, label %251

430:                                              ; preds = %20
  %431 = load i64, ptr %4, align 8
  %432 = ptrtoint ptr %0 to i64
  %433 = ptrtoint ptr %2 to i64
  %434 = or i64 %1, %431
  %435 = sub i64 %434, %1
  %436 = add i64 %435, %1
  store i64 %436, ptr %4, align 8
  br label %250

437:                                              ; preds = %40
  %438 = load i64, ptr %4, align 8
  %439 = ptrtoint ptr %0 to i64
  %440 = ptrtoint ptr %2 to i64
  %441 = and i64 %438, %438
  %442 = mul i64 %441, %438
  %443 = or i64 %442, %440
  store i64 %443, ptr %4, align 8
  br label %250

444:                                              ; preds = %51
  %445 = load i64, ptr %4, align 8
  %446 = ptrtoint ptr %0 to i64
  %447 = ptrtoint ptr %2 to i64
  %448 = sub i64 %447, %1
  %449 = xor i64 %448, %446
  %450 = add i64 %449, %1
  %451 = or i64 %450, %447
  store i64 %451, ptr %4, align 8
  br label %250

452:                                              ; preds = %62
  %453 = load i64, ptr %4, align 8
  %454 = ptrtoint ptr %0 to i64
  %455 = ptrtoint ptr %2 to i64
  %456 = and i64 %455, %455
  %457 = sub i64 %456, %455
  %458 = or i64 %457, %1
  %459 = add i64 %458, %455
  %460 = xor i64 %459, %453
  %461 = mul i64 %460, %455
  store i64 %461, ptr %4, align 8
  br label %250

462:                                              ; preds = %75
  %463 = load i64, ptr %4, align 8
  %464 = ptrtoint ptr %0 to i64
  %465 = ptrtoint ptr %2 to i64
  %466 = and i64 %463, %464
  %467 = add i64 %466, %463
  %468 = sub i64 %467, %463
  %469 = mul i64 %468, %463
  %470 = and i64 %469, %464
  %471 = xor i64 %470, %464
  store i64 %471, ptr %4, align 8
  br label %250

472:                                              ; preds = %152
  %473 = load i64, ptr %4, align 8
  %474 = ptrtoint ptr %0 to i64
  %475 = ptrtoint ptr %2 to i64
  %476 = sub i64 %473, %473
  %477 = xor i64 %476, %475
  %478 = or i64 %477, %474
  %479 = xor i64 %478, %473
  %480 = add i64 %479, %473
  %481 = xor i64 %480, %474
  store i64 %481, ptr %4, align 8
  br label %250

482:                                              ; preds = %164
  %483 = load i64, ptr %4, align 8
  %484 = ptrtoint ptr %0 to i64
  %485 = ptrtoint ptr %2 to i64
  %486 = add i64 %484, %484
  %487 = mul i64 %486, %1
  %488 = xor i64 %487, %484
  %489 = mul i64 %488, %483
  %490 = mul i64 %489, %1
  %491 = or i64 %490, %483
  store i64 %491, ptr %4, align 8
  br label %250

492:                                              ; preds = %177
  %493 = load i64, ptr %4, align 8
  %494 = ptrtoint ptr %0 to i64
  %495 = ptrtoint ptr %2 to i64
  %496 = sub i64 %1, %1
  %497 = sub i64 %496, %495
  %498 = or i64 %497, %1
  %499 = xor i64 %498, %494
  %500 = sub i64 %499, %493
  store i64 %500, ptr %4, align 8
  br label %250

501:                                              ; preds = %234
  %502 = load i64, ptr %4, align 8
  %503 = ptrtoint ptr %0 to i64
  %504 = ptrtoint ptr %2 to i64
  %505 = add i64 %502, %502
  %506 = xor i64 %505, %1
  %507 = or i64 %506, %502
  %508 = sub i64 %507, %502
  store i64 %508, ptr %4, align 8
  br label %250

509:                                              ; preds = %251
  %510 = load i64, ptr %4, align 8
  %511 = ptrtoint ptr %0 to i64
  %512 = ptrtoint ptr %2 to i64
  %513 = and i64 %510, %1
  %514 = xor i64 %513, %510
  %515 = and i64 %514, %1
  %516 = or i64 %515, %512
  %517 = mul i64 %516, %1
  store i64 %517, ptr %4, align 8
  br label %15

518:                                              ; preds = %261
  %519 = load i64, ptr %4, align 8
  %520 = ptrtoint ptr %0 to i64
  %521 = ptrtoint ptr %2 to i64
  %522 = mul i64 %1, %1
  %523 = or i64 %522, %521
  %524 = add i64 %523, %1
  %525 = and i64 %524, %1
  store i64 %525, ptr %4, align 8
  br label %250

526:                                              ; preds = %274
  %527 = load i64, ptr %4, align 8
  %528 = ptrtoint ptr %0 to i64
  %529 = ptrtoint ptr %2 to i64
  %530 = sub i64 %529, %1
  %531 = mul i64 %530, %1
  %532 = and i64 %531, %528
  %533 = xor i64 %532, %527
  %534 = sub i64 %533, %528
  %535 = mul i64 %534, %528
  store i64 %535, ptr %4, align 8
  br label %250

536:                                              ; preds = %293
  %537 = load i64, ptr %4, align 8
  %538 = ptrtoint ptr %0 to i64
  %539 = ptrtoint ptr %2 to i64
  %540 = mul i64 %537, %537
  %541 = sub i64 %540, %1
  %542 = add i64 %541, %538
  store i64 %542, ptr %4, align 8
  br label %250

543:                                              ; preds = %305
  %544 = load i64, ptr %4, align 8
  %545 = ptrtoint ptr %0 to i64
  %546 = ptrtoint ptr %2 to i64
  %547 = and i64 %544, %545
  %548 = sub i64 %547, %545
  %549 = xor i64 %548, %546
  %550 = or i64 %549, %544
  %551 = add i64 %550, %544
  %552 = and i64 %551, %545
  store i64 %552, ptr %4, align 8
  br label %250

553:                                              ; preds = %318
  %554 = load i64, ptr %4, align 8
  %555 = ptrtoint ptr %0 to i64
  %556 = ptrtoint ptr %2 to i64
  %557 = or i64 %556, %555
  %558 = or i64 %557, %554
  %559 = xor i64 %558, %1
  store i64 %559, ptr %4, align 8
  br label %250

560:                                              ; preds = %336
  %561 = load i64, ptr %4, align 8
  %562 = ptrtoint ptr %0 to i64
  %563 = ptrtoint ptr %2 to i64
  %564 = add i64 %1, %561
  %565 = xor i64 %564, %561
  %566 = mul i64 %565, %563
  %567 = or i64 %566, %563
  %568 = or i64 %567, %562
  store i64 %568, ptr %4, align 8
  br label %250

569:                                              ; preds = %348
  %570 = load i64, ptr %4, align 8
  %571 = ptrtoint ptr %0 to i64
  %572 = ptrtoint ptr %2 to i64
  %573 = and i64 %570, %572
  %574 = add i64 %573, %570
  %575 = mul i64 %574, %1
  %576 = xor i64 %575, %572
  store i64 %576, ptr %4, align 8
  br label %250

577:                                              ; preds = %360
  %578 = load i64, ptr %4, align 8
  %579 = ptrtoint ptr %0 to i64
  %580 = ptrtoint ptr %2 to i64
  %581 = and i64 %579, %578
  %582 = xor i64 %581, %579
  %583 = and i64 %582, %1
  store i64 %583, ptr %4, align 8
  br label %250
}

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @rol32(i32 noundef %0, i32 noundef %1) #0 {
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
  %11 = xor i32 32, %10
  %12 = and i32 -33, %10
  %13 = add i32 %12, %12
  %14 = sub i32 %11, %13
  %15 = lshr i32 %9, %14
  %16 = xor i32 %8, %15
  %17 = and i32 %8, %15
  %18 = add i32 %16, %17
  ret i32 %18
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @mix32(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = udiv i32 %3, 65536
  %5 = load i32, ptr %2, align 4
  %6 = add i32 %5, %4
  %7 = and i32 %5, %4
  %8 = add i32 %7, %7
  %9 = sub i32 %6, %8
  store i32 %9, ptr %2, align 4
  %10 = load i32, ptr %2, align 4
  %11 = mul i32 %10, 2146121005
  store i32 %11, ptr %2, align 4
  %12 = load i32, ptr %2, align 4
  %13 = udiv i32 %12, 32768
  %14 = load i32, ptr %2, align 4
  %15 = add i32 %14, %13
  %16 = and i32 %14, %13
  %17 = mul i32 %15, -1380002315
  %18 = mul i32 %16, -1380002315
  %19 = add i32 %18, %18
  %20 = sub i32 %17, %19
  %21 = mul i32 %20, 933850717
  store i32 %21, ptr %2, align 4
  %22 = load i32, ptr %2, align 4
  %23 = mul i32 %22, -2073254261
  store i32 %23, ptr %2, align 4
  %24 = load i32, ptr %2, align 4
  %25 = udiv i32 %24, 65536
  %26 = load i32, ptr %2, align 4
  %27 = add i32 %26, %25
  %28 = and i32 %26, %25
  %29 = add i32 %28, %28
  %30 = sub i32 %27, %29
  store i32 %30, ptr %2, align 4
  %31 = load i32, ptr %2, align 4
  ret i32 %31
}

; Function Attrs: nounwind
declare void @free(ptr noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @checksum32(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  %8 = alloca i64, align 8
  store i32 845853846, ptr %4, align 4
  br label %9

9:                                                ; preds = %193, %114, %113, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, 388179599
  %12 = mul i32 %11, -1317971591
  switch i32 %12, label %114 [
    i32 1296666703, label %13
    i32 2085771348, label %23
    i32 1707029922, label %36
    i32 117142819, label %103
    i32 1603120343, label %123
    i32 88109514, label %135
    i32 912863629, label %148
    i32 362212184, label %161
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  store i32 -2128831035, ptr %7, align 4
  store i64 0, ptr %8, align 8
  store i32 1329692803, ptr %4, align 4
  %14 = xor i64 %1, 2364451737575304765
  %15 = and i64 %1, %14
  %16 = or i64 %1, %14
  %17 = xor i64 %1, %14
  %18 = add i64 %15, %16
  %19 = sub i64 %18, %1
  %20 = sub i64 %19, %14
  %21 = mul i64 %20, 225
  %22 = icmp sgt i64 %21, 0
  br i1 %22, label %172, label %113

23:                                               ; preds = %9
  %24 = load i64, ptr %8, align 8
  %25 = load i64, ptr %6, align 8
  %26 = icmp ult i64 %24, %25
  %27 = select i1 %26, i32 -345390399, i32 -1762762998
  store i32 %27, ptr %4, align 4
  %28 = xor i64 %1, 8555099446808523755
  %29 = and i64 %1, %28
  %30 = or i64 %1, %28
  %31 = xor i64 %1, %28
  %32 = sub i64 %30, %31
  %33 = sub i64 %32, %29
  %34 = mul i64 %33, 23
  %35 = icmp ne i64 %34, 0
  br i1 %35, label %178, label %113

36:                                               ; preds = %9
  %37 = load ptr, ptr %5, align 8
  %38 = load i64, ptr %8, align 8
  %39 = getelementptr inbounds nuw i8, ptr %37, i64 %38
  %40 = load i8, ptr %39, align 1
  %41 = zext i8 %40 to i32
  %42 = load i64, ptr %8, align 8
  %43 = mul i64 %42, 40503
  %44 = trunc i64 %43 to i32
  %45 = xor i32 %41, %44
  %46 = and i32 %41, %44
  %47 = add i32 %46, %46
  %48 = add i32 %45, %47
  %49 = load i32, ptr %7, align 4
  %50 = add i32 %49, %48
  %51 = and i32 %49, %48
  %52 = load i32, ptr %4, align 4
  %53 = xor i32 %52, -898675944
  %54 = mul i32 %50, %53
  %55 = load i32, ptr %4, align 4
  %56 = xor i32 %55, -898675944
  %57 = mul i32 %51, %56
  %58 = add i32 %57, %57
  %59 = sub i32 %54, %58
  %60 = load i32, ptr %4, align 4
  %61 = xor i32 %60, -2096847704
  %62 = mul i32 %59, %61
  store i32 %62, ptr %7, align 4
  %63 = load i32, ptr %7, align 4
  %64 = load i32, ptr %4, align 4
  %65 = xor i32 %64, -362167470
  %66 = mul i32 %63, %65
  store i32 %66, ptr %7, align 4
  %67 = load i32, ptr %7, align 4
  %68 = load i64, ptr %8, align 8
  %69 = urem i64 %68, 7
  %70 = xor i64 %69, 1
  %71 = and i64 %69, 1
  %72 = add i64 %71, %71
  %73 = add i64 %70, %72
  %74 = trunc i64 %73 to i32
  %75 = call i32 @rol32(i32 noundef %67, i32 noundef %74)
  %76 = load i64, ptr %8, align 8
  %77 = add i64 %76, 63
  %78 = or i64 %76, 63
  %79 = mul i64 %77, 1719295895
  %80 = mul i64 %78, 1719295895
  %81 = sub i64 %79, %80
  %82 = mul i64 %81, 1925274302134751271
  %83 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %82
  %84 = load i8, ptr %83, align 1
  %85 = zext i8 %84 to i32
  %86 = or i32 %75, %85
  %87 = and i32 %75, %85
  %88 = sub i32 %86, %87
  store i32 %88, ptr %7, align 4
  %89 = load i64, ptr %8, align 8
  %90 = xor i64 %89, 1
  %91 = and i64 %89, 1
  %92 = add i64 %91, %91
  %93 = add i64 %90, %92
  store i64 %93, ptr %8, align 8
  store i32 1329692803, ptr %4, align 4
  %94 = xor i64 %1, -5359687364995427903
  %95 = and i64 %1, %94
  %96 = or i64 %1, %94
  %97 = xor i64 %1, %94
  %98 = add i64 %95, %96
  %99 = sub i64 %98, %1
  %100 = sub i64 %99, %94
  %101 = mul i64 %100, 74
  %102 = icmp ne i64 %101, 0
  br i1 %102, label %186, label %113

103:                                              ; preds = %9
  %104 = load i32, ptr %7, align 4
  %105 = load i64, ptr %6, align 8
  %106 = mul i64 %105, 73244475
  %107 = trunc i64 %106 to i32
  %108 = add i32 %104, %107
  %109 = and i32 %104, %107
  %110 = add i32 %109, %109
  %111 = sub i32 %108, %110
  %112 = call i32 @mix32(i32 noundef %111)
  ret i32 %112

113:                                              ; preds = %226, %219, %211, %202, %186, %178, %172, %161, %148, %135, %123, %36, %23, %13
  br label %9

114:                                              ; preds = %9
  store i32 845853846, ptr %4, align 4
  call void asm sideeffect "", ""()
  %115 = xor i64 %1, -1943248380396139021
  %116 = and i64 %1, %115
  %117 = or i64 %1, %115
  %118 = xor i64 %1, %115
  %119 = sub i64 %117, %118
  %120 = sub i64 %119, %116
  %121 = mul i64 %120, 157
  %122 = icmp eq i64 %121, 0
  br i1 %122, label %9, label %193

123:                                              ; preds = %9
  %124 = load i32, ptr %4, align 4
  %125 = xor i32 %124, -897207907
  store i32 %125, ptr %4, align 4
  %126 = xor i64 %1, 4036915716006007897
  %127 = and i64 %1, %126
  %128 = or i64 %1, %126
  %129 = xor i64 %1, %126
  %130 = add i64 %127, %128
  %131 = sub i64 %130, %1
  %132 = sub i64 %131, %126
  %133 = mul i64 %132, 56
  %134 = icmp slt i64 %133, 0
  br i1 %134, label %202, label %113

135:                                              ; preds = %9
  %136 = load i32, ptr %4, align 4
  %137 = xor i32 %136, 1302209461
  store i32 %137, ptr %4, align 4
  %138 = xor i64 %1, 2484453582258645557
  %139 = and i64 %1, %138
  %140 = or i64 %1, %138
  %141 = xor i64 %1, %138
  %142 = add i64 %1, %138
  %143 = sub i64 %142, %141
  %144 = mul i64 %139, 2
  %145 = sub i64 %143, %144
  %146 = mul i64 %145, 118
  %147 = icmp sle i64 %146, 0
  br i1 %147, label %113, label %211

148:                                              ; preds = %9
  %149 = load i32, ptr %4, align 4
  %150 = xor i32 %149, 1288958376
  store i32 %150, ptr %4, align 4
  %151 = xor i64 %1, -2421623334935907947
  %152 = and i64 %1, %151
  %153 = or i64 %1, %151
  %154 = xor i64 %1, %151
  %155 = mul i64 %153, 2
  %156 = sub i64 %155, %154
  %157 = sub i64 %156, %1
  %158 = sub i64 %157, %151
  %159 = mul i64 %158, 104
  %160 = icmp slt i64 %159, 1
  br i1 %160, label %113, label %219

161:                                              ; preds = %9
  %162 = load i32, ptr %4, align 4
  %163 = xor i32 %162, -1279732329
  store i32 %163, ptr %4, align 4
  %164 = xor i64 %1, 7977328485462633375
  %165 = and i64 %1, %164
  %166 = or i64 %1, %164
  %167 = xor i64 %1, %164
  %168 = sub i64 %166, %167
  %169 = sub i64 %168, %165
  %170 = mul i64 %169, 242
  %171 = icmp ne i64 %170, 0
  br i1 %171, label %226, label %113

172:                                              ; preds = %13
  %173 = load i64, ptr %3, align 8
  %174 = ptrtoint ptr %0 to i64
  %175 = sub i64 %1, %1
  %176 = add i64 %175, %173
  %177 = and i64 %176, %174
  store i64 %177, ptr %3, align 8
  br label %113

178:                                              ; preds = %23
  %179 = load i64, ptr %3, align 8
  %180 = ptrtoint ptr %0 to i64
  %181 = or i64 %180, %180
  %182 = and i64 %181, %180
  %183 = sub i64 %182, %1
  %184 = mul i64 %183, %179
  %185 = and i64 %184, %179
  store i64 %185, ptr %3, align 8
  br label %113

186:                                              ; preds = %36
  %187 = load i64, ptr %3, align 8
  %188 = ptrtoint ptr %0 to i64
  %189 = xor i64 %188, %188
  %190 = and i64 %189, %187
  %191 = sub i64 %190, %187
  %192 = xor i64 %191, %187
  store i64 %192, ptr %3, align 8
  br label %113

193:                                              ; preds = %114
  %194 = load i64, ptr %3, align 8
  %195 = ptrtoint ptr %0 to i64
  %196 = xor i64 %194, %1
  %197 = add i64 %196, %1
  %198 = or i64 %197, %194
  %199 = sub i64 %198, %1
  %200 = sub i64 %199, %194
  %201 = add i64 %200, %195
  store i64 %201, ptr %3, align 8
  br label %9

202:                                              ; preds = %123
  %203 = load i64, ptr %3, align 8
  %204 = ptrtoint ptr %0 to i64
  %205 = and i64 %1, %203
  %206 = xor i64 %205, %1
  %207 = mul i64 %206, %1
  %208 = add i64 %207, %203
  %209 = sub i64 %208, %204
  %210 = xor i64 %209, %1
  store i64 %210, ptr %3, align 8
  br label %113

211:                                              ; preds = %135
  %212 = load i64, ptr %3, align 8
  %213 = ptrtoint ptr %0 to i64
  %214 = or i64 %212, %212
  %215 = and i64 %214, %212
  %216 = or i64 %215, %212
  %217 = xor i64 %216, %1
  %218 = and i64 %217, %1
  store i64 %218, ptr %3, align 8
  br label %113

219:                                              ; preds = %148
  %220 = load i64, ptr %3, align 8
  %221 = ptrtoint ptr %0 to i64
  %222 = add i64 %220, %220
  %223 = sub i64 %222, %220
  %224 = and i64 %223, %220
  %225 = or i64 %224, %1
  store i64 %225, ptr %3, align 8
  br label %113

226:                                              ; preds = %161
  %227 = load i64, ptr %3, align 8
  %228 = ptrtoint ptr %0 to i64
  %229 = xor i64 %1, %227
  %230 = add i64 %229, %1
  %231 = sub i64 %230, %228
  %232 = sub i64 %231, %1
  store i64 %232, ptr %3, align 8
  br label %113
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @graph_mix(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  %8 = alloca i64, align 8
  %9 = alloca i32, align 4
  store i32 1562282434, ptr %4, align 4
  br label %10

10:                                               ; preds = %631, %362, %361, %2
  %11 = load i32, ptr %4, align 4
  %12 = sub i32 %11, -2052478774
  %13 = mul i32 %12, 745993511
  %14 = icmp slt i32 %13, 1243543279
  br i1 %14, label %479, label %481

15:                                               ; preds = %487
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  store i32 -1073623027, ptr %7, align 4
  store i64 0, ptr %8, align 8
  store i32 79457018, ptr %4, align 4
  %16 = xor i64 %1, -2594440337173223177
  %17 = and i64 %1, %16
  %18 = or i64 %1, %16
  %19 = xor i64 %1, %16
  %20 = mul i64 %18, 2
  %21 = sub i64 %20, %19
  %22 = sub i64 %21, %1
  %23 = sub i64 %22, %16
  %24 = mul i64 %23, 124
  %25 = icmp sle i64 %24, 0
  br i1 %25, label %361, label %543

26:                                               ; preds = %497
  %27 = load i64, ptr %8, align 8
  %28 = load i64, ptr %6, align 8
  %29 = icmp ult i64 %27, %28
  %30 = select i1 %29, i32 256627965, i32 -2001976139
  store i32 %30, ptr %4, align 4
  %31 = xor i64 %1, 6748496678451473039
  %32 = and i64 %1, %31
  %33 = or i64 %1, %31
  %34 = xor i64 %1, %31
  %35 = sub i64 %33, %34
  %36 = sub i64 %35, %32
  %37 = mul i64 %36, 169
  %38 = xor i64 %1, 2371377658141448299
  %39 = and i64 %1, %38
  %40 = or i64 %1, %38
  %41 = xor i64 %1, %38
  %42 = add i64 %39, %40
  %43 = sub i64 %42, %1
  %44 = sub i64 %43, %38
  %45 = mul i64 %44, 81
  %46 = icmp ne i64 %37, %45
  br i1 %46, label %551, label %361

47:                                               ; preds = %521
  %48 = load ptr, ptr %5, align 8
  %49 = load i64, ptr %8, align 8
  %50 = getelementptr inbounds nuw i8, ptr %48, i64 %49
  %51 = load i8, ptr %50, align 1
  %52 = zext i8 %51 to i32
  store i32 %52, ptr %9, align 4
  %53 = load i32, ptr %9, align 4
  %54 = load i64, ptr %8, align 8
  %55 = trunc i64 %54 to i32
  %56 = load i32, ptr %4, align 4
  %57 = xor i32 %56, 256627964
  %58 = add i32 %55, %57
  %59 = load i32, ptr %4, align 4
  %60 = xor i32 %59, 256627964
  %61 = sub i32 %53, %60
  %62 = mul i32 %53, %58
  %63 = mul i32 %55, %61
  %64 = sub i32 %62, %63
  %65 = load i32, ptr %4, align 4
  %66 = xor i32 %65, 256627962
  %67 = add i32 %64, %66
  %68 = load i32, ptr %4, align 4
  %69 = xor i32 %68, 256627962
  %70 = or i32 %64, %69
  %71 = sub i32 %67, %70
  %72 = icmp eq i32 %71, 0
  %73 = select i1 %72, i32 1867998973, i32 1061922809
  %74 = icmp eq i32 %71, 1
  %75 = select i1 %74, i32 412468023, i32 %73
  %76 = icmp eq i32 %71, 2
  %77 = select i1 %76, i32 342070410, i32 %75
  %78 = icmp eq i32 %71, 3
  %79 = select i1 %78, i32 -335266833, i32 %77
  %80 = icmp eq i32 %71, 4
  %81 = select i1 %80, i32 270894531, i32 %79
  %82 = icmp eq i32 %71, 5
  %83 = select i1 %82, i32 1883303843, i32 %81
  %84 = icmp eq i32 %71, 6
  %85 = select i1 %84, i32 1989625433, i32 %83
  store i32 %85, ptr %4, align 4
  %86 = xor i64 %1, -746058685125976161
  %87 = and i64 %1, %86
  %88 = or i64 %1, %86
  %89 = xor i64 %1, %86
  %90 = mul i64 %88, 2
  %91 = sub i64 %90, %89
  %92 = sub i64 %91, %1
  %93 = sub i64 %92, %86
  %94 = mul i64 %93, 101
  %95 = icmp ugt i64 %94, 0
  br i1 %95, label %560, label %361

96:                                               ; preds = %525
  %97 = load i32, ptr %7, align 4
  %98 = load i32, ptr %9, align 4
  %99 = or i32 %97, %98
  %100 = and i32 %97, %98
  %101 = sub i32 %99, %100
  %102 = call i32 @rol32(i32 noundef %101, i32 noundef 3)
  %103 = load i32, ptr %4, align 4
  %104 = xor i32 %103, 1867998972
  %105 = sub i32 %102, %104
  %106 = load i32, ptr %4, align 4
  %107 = xor i32 %106, 2080439581
  %108 = mul i32 %102, %107
  %109 = load i32, ptr %4, align 4
  %110 = xor i32 %109, 2080439586
  %111 = mul i32 %110, %105
  %112 = sub i32 %108, %111
  store i32 %112, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %113 = xor i64 %1, -6896315467773666067
  %114 = and i64 %1, %113
  %115 = or i64 %1, %113
  %116 = xor i64 %1, %113
  %117 = mul i64 %115, 2
  %118 = sub i64 %117, %116
  %119 = sub i64 %118, %1
  %120 = sub i64 %119, %113
  %121 = mul i64 %120, 85
  %122 = icmp slt i64 %121, 0
  br i1 %122, label %568, label %361

123:                                              ; preds = %507
  %124 = load i32, ptr %7, align 4
  %125 = load i32, ptr %9, align 4
  %126 = load i32, ptr %4, align 4
  %127 = xor i32 %126, 482892812
  %128 = mul i32 %125, %127
  %129 = load i32, ptr %4, align 4
  %130 = xor i32 %129, 412468022
  %131 = add i32 %128, %130
  %132 = load i32, ptr %4, align 4
  %133 = xor i32 %132, 412468022
  %134 = sub i32 %124, %133
  %135 = mul i32 %124, %131
  %136 = mul i32 %128, %134
  %137 = sub i32 %135, %136
  %138 = call i32 @mix32(i32 noundef %137)
  store i32 %138, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %139 = xor i64 %1, 4085779454882209777
  %140 = and i64 %1, %139
  %141 = or i64 %1, %139
  %142 = xor i64 %1, %139
  %143 = add i64 %1, %139
  %144 = sub i64 %143, %142
  %145 = mul i64 %140, 2
  %146 = sub i64 %144, %145
  %147 = mul i64 %146, 32
  %148 = icmp uge i64 %147, 0
  br i1 %148, label %361, label %575

149:                                              ; preds = %533
  %150 = load i32, ptr %7, align 4
  %151 = load i32, ptr %9, align 4
  %152 = load i64, ptr %8, align 8
  %153 = add i64 %152, 7
  %154 = or i64 %152, 7
  %155 = sub i64 %153, %154
  %156 = trunc i64 %155 to i32
  %157 = load i32, ptr %4, align 4
  %158 = xor i32 %157, 342070411
  %159 = shl i32 %158, %156
  %160 = mul i32 %151, %159
  %161 = add i32 %150, %160
  %162 = and i32 %150, %160
  %163 = add i32 %162, %162
  %164 = sub i32 %161, %163
  %165 = load i32, ptr %4, align 4
  %166 = xor i32 %165, 867663783
  %167 = mul i32 %164, %166
  store i32 %167, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %168 = xor i64 %1, 3088917363900261577
  %169 = and i64 %1, %168
  %170 = or i64 %1, %168
  %171 = xor i64 %1, %168
  %172 = sub i64 %170, %171
  %173 = sub i64 %172, %169
  %174 = mul i64 %173, 235
  %175 = icmp slt i64 %174, 0
  br i1 %175, label %582, label %361

176:                                              ; preds = %537
  %177 = load i32, ptr %7, align 4
  %178 = load i32, ptr %9, align 4
  %179 = or i32 %177, %178
  %180 = and i32 %177, %178
  %181 = add i32 %179, %180
  %182 = load i64, ptr %8, align 8
  %183 = trunc i64 %182 to i32
  %184 = load i32, ptr %4, align 4
  %185 = xor i32 %184, -335266834
  %186 = add i32 %183, %185
  %187 = load i32, ptr %4, align 4
  %188 = xor i32 %187, -335266834
  %189 = sub i32 %181, %188
  %190 = mul i32 %181, %186
  %191 = mul i32 %183, %189
  %192 = sub i32 %190, %191
  %193 = call i32 @rol32(i32 noundef %192, i32 noundef 5)
  %194 = load i32, ptr %4, align 4
  %195 = xor i32 %194, 1235328586
  %196 = add i32 %193, %195
  %197 = load i32, ptr %4, align 4
  %198 = xor i32 %197, 1235328586
  %199 = and i32 %193, %198
  %200 = add i32 %199, %199
  %201 = sub i32 %196, %200
  store i32 %201, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %202 = xor i64 %1, 4803680085063903973
  %203 = and i64 %1, %202
  %204 = or i64 %1, %202
  %205 = xor i64 %1, %202
  %206 = mul i64 %204, 2
  %207 = sub i64 %206, %205
  %208 = sub i64 %207, %1
  %209 = sub i64 %208, %202
  %210 = mul i64 %209, 184
  %211 = icmp ugt i64 %210, 0
  br i1 %211, label %589, label %361

212:                                              ; preds = %515
  %213 = load i32, ptr %7, align 4
  %214 = load i32, ptr %9, align 4
  %215 = load i32, ptr %4, align 4
  %216 = xor i32 %215, 270894489
  %217 = or i32 %214, %216
  %218 = load i32, ptr %4, align 4
  %219 = xor i32 %218, 270894489
  %220 = and i32 %214, %219
  %221 = sub i32 %217, %220
  %222 = load i32, ptr %4, align 4
  %223 = xor i32 %222, -270894532
  %224 = xor i32 %221, %223
  %225 = add i32 %213, %224
  %226 = load i32, ptr %4, align 4
  %227 = xor i32 %226, 270894530
  %228 = add i32 %225, %227
  %229 = load i32, ptr %4, align 4
  %230 = xor i32 %229, -1911358342
  %231 = xor i32 %228, %230
  %232 = load i32, ptr %4, align 4
  %233 = xor i32 %232, -1911358342
  %234 = and i32 %228, %233
  %235 = add i32 %234, %234
  %236 = add i32 %231, %235
  store i32 %236, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %237 = xor i64 %1, -7415270855516655287
  %238 = and i64 %1, %237
  %239 = or i64 %1, %237
  %240 = xor i64 %1, %237
  %241 = add i64 %238, %239
  %242 = sub i64 %241, %1
  %243 = sub i64 %242, %237
  %244 = mul i64 %243, 251
  %245 = xor i64 %1, 5080182097286688135
  %246 = and i64 %1, %245
  %247 = or i64 %1, %245
  %248 = xor i64 %1, %245
  %249 = add i64 %246, %247
  %250 = sub i64 %249, %1
  %251 = sub i64 %250, %245
  %252 = mul i64 %251, 237
  %253 = icmp eq i64 %244, %252
  br i1 %253, label %361, label %596

254:                                              ; preds = %541
  %255 = load i32, ptr %7, align 4
  %256 = udiv i32 %255, 128
  %257 = load i32, ptr %9, align 4
  %258 = load i32, ptr %4, align 4
  %259 = xor i32 %258, 1883303586
  %260 = mul i32 %257, %259
  %261 = or i32 %256, %260
  %262 = and i32 %256, %260
  %263 = add i32 %261, %262
  %264 = load i32, ptr %7, align 4
  %265 = or i32 %264, %263
  %266 = and i32 %264, %263
  %267 = sub i32 %265, %266
  store i32 %267, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %268 = xor i64 %1, 1726109690769506803
  %269 = and i64 %1, %268
  %270 = or i64 %1, %268
  %271 = xor i64 %1, %268
  %272 = add i64 %269, %270
  %273 = sub i64 %272, %1
  %274 = sub i64 %273, %268
  %275 = mul i64 %274, 100
  %276 = icmp slt i64 %275, 0
  br i1 %276, label %602, label %361

277:                                              ; preds = %523
  %278 = load i32, ptr %7, align 4
  %279 = call i32 @rol32(i32 noundef %278, i32 noundef 11)
  %280 = load i32, ptr %9, align 4
  %281 = load i64, ptr %8, align 8
  %282 = trunc i64 %281 to i32
  %283 = or i32 %280, %282
  %284 = and i32 %280, %282
  %285 = sub i32 %283, %284
  %286 = load i32, ptr %4, align 4
  %287 = xor i32 %286, 1989559896
  %288 = mul i32 %285, %287
  %289 = xor i32 %279, %288
  %290 = and i32 %279, %288
  %291 = add i32 %290, %290
  %292 = add i32 %289, %291
  store i32 %292, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %293 = xor i64 %1, 4184944333078591739
  %294 = and i64 %1, %293
  %295 = or i64 %1, %293
  %296 = xor i64 %1, %293
  %297 = mul i64 %295, 2
  %298 = sub i64 %297, %296
  %299 = sub i64 %298, %1
  %300 = sub i64 %299, %293
  %301 = mul i64 %300, 24
  %302 = icmp sgt i64 %301, 0
  br i1 %302, label %608, label %361

303:                                              ; preds = %495
  %304 = load i32, ptr %7, align 4
  %305 = load i32, ptr %9, align 4
  %306 = add i32 %304, %305
  %307 = and i32 %304, %305
  %308 = load i32, ptr %4, align 4
  %309 = xor i32 %308, 200215092
  %310 = mul i32 %306, %309
  %311 = load i32, ptr %4, align 4
  %312 = xor i32 %311, 200215092
  %313 = mul i32 %307, %312
  %314 = add i32 %313, %313
  %315 = sub i32 %310, %314
  %316 = load i32, ptr %4, align 4
  %317 = xor i32 %316, -1352425220
  %318 = mul i32 %315, %317
  %319 = load i64, ptr %8, align 8
  %320 = mul i64 %319, 31337
  %321 = trunc i64 %320 to i32
  %322 = add i32 %318, %321
  %323 = and i32 %318, %321
  %324 = add i32 %323, %323
  %325 = sub i32 %322, %324
  %326 = call i32 @mix32(i32 noundef %325)
  store i32 %326, ptr %7, align 4
  store i32 -285713689, ptr %4, align 4
  %327 = xor i64 %1, 2024711411568827797
  %328 = and i64 %1, %327
  %329 = or i64 %1, %327
  %330 = xor i64 %1, %327
  %331 = add i64 %1, %327
  %332 = sub i64 %331, %330
  %333 = mul i64 %328, 2
  %334 = sub i64 %332, %333
  %335 = mul i64 %334, 76
  %336 = icmp ne i64 %335, 0
  br i1 %336, label %615, label %361

337:                                              ; preds = %535
  %338 = load i64, ptr %8, align 8
  %339 = or i64 %338, 1
  %340 = and i64 %338, 1
  %341 = add i64 %339, %340
  store i64 %341, ptr %8, align 8
  store i32 79457018, ptr %4, align 4
  %342 = xor i64 %1, 1575207762993482629
  %343 = and i64 %1, %342
  %344 = or i64 %1, %342
  %345 = xor i64 %1, %342
  %346 = sub i64 %344, %345
  %347 = sub i64 %346, %343
  %348 = mul i64 %347, 18
  %349 = icmp sle i64 %348, 0
  br i1 %349, label %361, label %624

350:                                              ; preds = %505
  %351 = load i32, ptr %7, align 4
  %352 = load i32, ptr %4, align 4
  %353 = xor i32 %352, 1442970202
  %354 = add i32 %351, %353
  %355 = load i32, ptr %4, align 4
  %356 = xor i32 %355, 1442970202
  %357 = and i32 %351, %356
  %358 = add i32 %357, %357
  %359 = sub i32 %354, %358
  %360 = call i32 @mix32(i32 noundef %359)
  ret i32 %360

361:                                              ; preds = %686, %679, %671, %665, %658, %652, %646, %640, %624, %615, %608, %602, %596, %589, %582, %575, %568, %560, %551, %543, %466, %453, %433, %421, %408, %397, %385, %372, %337, %303, %277, %254, %212, %176, %149, %123, %96, %47, %26, %15
  br label %10

362:                                              ; preds = %541, %537, %535, %531, %525, %521, %519, %509, %505, %503, %497, %493, %491
  store i32 1562282434, ptr %4, align 4
  call void asm sideeffect "", ""()
  %363 = xor i64 %1, 3383063301275187403
  %364 = and i64 %1, %363
  %365 = or i64 %1, %363
  %366 = xor i64 %1, %363
  %367 = add i64 %364, %365
  %368 = sub i64 %367, %1
  %369 = sub i64 %368, %363
  %370 = mul i64 %369, 114
  %371 = icmp slt i64 %370, 1
  br i1 %371, label %10, label %631

372:                                              ; preds = %519
  %373 = load i32, ptr %4, align 4
  %374 = xor i32 %373, 426825905
  store i32 %374, ptr %4, align 4
  %375 = xor i64 %1, 7272836496348034797
  %376 = and i64 %1, %375
  %377 = or i64 %1, %375
  %378 = xor i64 %1, %375
  %379 = add i64 %1, %375
  %380 = sub i64 %379, %378
  %381 = mul i64 %376, 2
  %382 = sub i64 %380, %381
  %383 = mul i64 %382, 101
  %384 = icmp eq i64 %383, 0
  br i1 %384, label %361, label %640

385:                                              ; preds = %499
  %386 = load i32, ptr %4, align 4
  %387 = xor i32 %386, 1929096118
  store i32 %387, ptr %4, align 4
  %388 = xor i64 %1, -1384901007243023187
  %389 = and i64 %1, %388
  %390 = or i64 %1, %388
  %391 = xor i64 %1, %388
  %392 = add i64 %389, %390
  %393 = sub i64 %392, %1
  %394 = sub i64 %393, %388
  %395 = mul i64 %394, 245
  %396 = icmp sle i64 %395, 0
  br i1 %396, label %361, label %646

397:                                              ; preds = %531
  %398 = load i32, ptr %4, align 4
  %399 = xor i32 %398, -1694309725
  store i32 %399, ptr %4, align 4
  %400 = xor i64 %1, 2606645932693212597
  %401 = and i64 %1, %400
  %402 = or i64 %1, %400
  %403 = xor i64 %1, %400
  %404 = sub i64 %402, %403
  %405 = sub i64 %404, %401
  %406 = mul i64 %405, 190
  %407 = icmp sgt i64 %406, 0
  br i1 %407, label %652, label %361

408:                                              ; preds = %539
  %409 = load i32, ptr %4, align 4
  %410 = xor i32 %409, -689928900
  store i32 %410, ptr %4, align 4
  %411 = xor i64 %1, 8061343647797654801
  %412 = and i64 %1, %411
  %413 = or i64 %1, %411
  %414 = xor i64 %1, %411
  %415 = add i64 %1, %411
  %416 = sub i64 %415, %414
  %417 = mul i64 %412, 2
  %418 = sub i64 %416, %417
  %419 = mul i64 %418, 80
  %420 = icmp eq i64 %419, 0
  br i1 %420, label %361, label %658

421:                                              ; preds = %493
  %422 = load i32, ptr %4, align 4
  %423 = xor i32 %422, -1321155334
  store i32 %423, ptr %4, align 4
  %424 = xor i64 %1, -7292029516079174215
  %425 = and i64 %1, %424
  %426 = or i64 %1, %424
  %427 = xor i64 %1, %424
  %428 = add i64 %425, %426
  %429 = sub i64 %428, %1
  %430 = sub i64 %429, %424
  %431 = mul i64 %430, 96
  %432 = icmp sgt i64 %431, 0
  br i1 %432, label %665, label %361

433:                                              ; preds = %509
  %434 = load i32, ptr %4, align 4
  %435 = xor i32 %434, 1623748933
  store i32 %435, ptr %4, align 4
  %436 = xor i64 %1, -1059763916544511871
  %437 = and i64 %1, %436
  %438 = or i64 %1, %436
  %439 = xor i64 %1, %436
  %440 = add i64 %437, %438
  %441 = sub i64 %440, %1
  %442 = sub i64 %441, %436
  %443 = mul i64 %442, 167
  %444 = xor i64 %1, 2302120362119693041
  %445 = and i64 %1, %444
  %446 = or i64 %1, %444
  %447 = xor i64 %1, %444
  %448 = add i64 %445, %446
  %449 = sub i64 %448, %1
  %450 = sub i64 %449, %444
  %451 = mul i64 %450, 140
  %452 = icmp eq i64 %443, %451
  br i1 %452, label %361, label %671

453:                                              ; preds = %491
  %454 = load i32, ptr %4, align 4
  %455 = xor i32 %454, 1708473679
  store i32 %455, ptr %4, align 4
  %456 = xor i64 %1, 6101060536659258891
  %457 = and i64 %1, %456
  %458 = or i64 %1, %456
  %459 = xor i64 %1, %456
  %460 = mul i64 %458, 2
  %461 = sub i64 %460, %459
  %462 = sub i64 %461, %1
  %463 = sub i64 %462, %456
  %464 = mul i64 %463, 119
  %465 = icmp eq i64 %464, 0
  br i1 %465, label %361, label %679

466:                                              ; preds = %503
  %467 = load i32, ptr %4, align 4
  %468 = xor i32 %467, 1017422802
  store i32 %468, ptr %4, align 4
  %469 = xor i64 %1, 7036596497636502333
  %470 = and i64 %1, %469
  %471 = or i64 %1, %469
  %472 = xor i64 %1, %469
  %473 = add i64 %1, %469
  %474 = sub i64 %473, %472
  %475 = mul i64 %470, 2
  %476 = sub i64 %474, %475
  %477 = mul i64 %476, 91
  %478 = icmp ugt i64 %477, 0
  br i1 %478, label %686, label %361

479:                                              ; preds = %10
  %480 = icmp slt i32 %13, 573474340
  br i1 %480, label %483, label %485

481:                                              ; preds = %10
  %482 = icmp slt i32 %13, 1400869039
  br i1 %482, label %511, label %513

483:                                              ; preds = %479
  %484 = icmp slt i32 %13, 42002168
  br i1 %484, label %487, label %489

485:                                              ; preds = %479
  %486 = icmp slt i32 %13, 921675725
  br i1 %486, label %499, label %501

487:                                              ; preds = %483
  %488 = icmp eq i32 %13, 7052744
  br i1 %488, label %15, label %491

489:                                              ; preds = %483
  %490 = icmp slt i32 %13, 76536617
  br i1 %490, label %493, label %495

491:                                              ; preds = %487
  %492 = icmp eq i32 %13, 24889938
  br i1 %492, label %453, label %362

493:                                              ; preds = %489
  %494 = icmp eq i32 %13, 42002168
  br i1 %494, label %421, label %362

495:                                              ; preds = %489
  %496 = icmp eq i32 %13, 76536617
  br i1 %496, label %303, label %497

497:                                              ; preds = %495
  %498 = icmp eq i32 %13, 299074896
  br i1 %498, label %26, label %362

499:                                              ; preds = %485
  %500 = icmp eq i32 %13, 573474340
  br i1 %500, label %385, label %503

501:                                              ; preds = %485
  %502 = icmp slt i32 %13, 1098930075
  br i1 %502, label %505, label %507

503:                                              ; preds = %499
  %504 = icmp eq i32 %13, 587216544
  br i1 %504, label %466, label %362

505:                                              ; preds = %501
  %506 = icmp eq i32 %13, 921675725
  br i1 %506, label %350, label %362

507:                                              ; preds = %501
  %508 = icmp eq i32 %13, 1098930075
  br i1 %508, label %123, label %509

509:                                              ; preds = %507
  %510 = icmp eq i32 %13, 1185403384
  br i1 %510, label %433, label %362

511:                                              ; preds = %481
  %512 = icmp slt i32 %13, 1334020805
  br i1 %512, label %515, label %517

513:                                              ; preds = %481
  %514 = icmp slt i32 %13, 1974260643
  br i1 %514, label %527, label %529

515:                                              ; preds = %511
  %516 = icmp eq i32 %13, 1243543279
  br i1 %516, label %212, label %519

517:                                              ; preds = %511
  %518 = icmp slt i32 %13, 1340529609
  br i1 %518, label %521, label %523

519:                                              ; preds = %515
  %520 = icmp eq i32 %13, 1245871144
  br i1 %520, label %372, label %362

521:                                              ; preds = %517
  %522 = icmp eq i32 %13, 1334020805
  br i1 %522, label %47, label %362

523:                                              ; preds = %517
  %524 = icmp eq i32 %13, 1340529609
  br i1 %524, label %277, label %525

525:                                              ; preds = %523
  %526 = icmp eq i32 %13, 1342228677
  br i1 %526, label %96, label %362

527:                                              ; preds = %513
  %528 = icmp slt i32 %13, 1467066944
  br i1 %528, label %531, label %533

529:                                              ; preds = %513
  %530 = icmp slt i32 %13, 1992988623
  br i1 %530, label %537, label %539

531:                                              ; preds = %527
  %532 = icmp eq i32 %13, 1400869039
  br i1 %532, label %397, label %362

533:                                              ; preds = %527
  %534 = icmp eq i32 %13, 1467066944
  br i1 %534, label %149, label %535

535:                                              ; preds = %533
  %536 = icmp eq i32 %13, 1892737899
  br i1 %536, label %337, label %362

537:                                              ; preds = %529
  %538 = icmp eq i32 %13, 1974260643
  br i1 %538, label %176, label %362

539:                                              ; preds = %529
  %540 = icmp eq i32 %13, 1992988623
  br i1 %540, label %408, label %541

541:                                              ; preds = %539
  %542 = icmp eq i32 %13, 2011133967
  br i1 %542, label %254, label %362

543:                                              ; preds = %15
  %544 = load i64, ptr %3, align 8
  %545 = ptrtoint ptr %0 to i64
  %546 = mul i64 %545, %1
  %547 = and i64 %546, %544
  %548 = add i64 %547, %1
  %549 = add i64 %548, %545
  %550 = sub i64 %549, %545
  store i64 %550, ptr %3, align 8
  br label %361

551:                                              ; preds = %26
  %552 = load i64, ptr %3, align 8
  %553 = ptrtoint ptr %0 to i64
  %554 = xor i64 %1, %1
  %555 = and i64 %554, %552
  %556 = xor i64 %555, %553
  %557 = mul i64 %556, %1
  %558 = and i64 %557, %553
  %559 = sub i64 %558, %1
  store i64 %559, ptr %3, align 8
  br label %361

560:                                              ; preds = %47
  %561 = load i64, ptr %3, align 8
  %562 = ptrtoint ptr %0 to i64
  %563 = xor i64 %562, %562
  %564 = mul i64 %563, %1
  %565 = mul i64 %564, %562
  %566 = and i64 %565, %561
  %567 = or i64 %566, %1
  store i64 %567, ptr %3, align 8
  br label %361

568:                                              ; preds = %96
  %569 = load i64, ptr %3, align 8
  %570 = ptrtoint ptr %0 to i64
  %571 = or i64 %1, %569
  %572 = or i64 %571, %570
  %573 = sub i64 %572, %569
  %574 = add i64 %573, %1
  store i64 %574, ptr %3, align 8
  br label %361

575:                                              ; preds = %123
  %576 = load i64, ptr %3, align 8
  %577 = ptrtoint ptr %0 to i64
  %578 = add i64 %577, %576
  %579 = add i64 %578, %576
  %580 = sub i64 %579, %576
  %581 = xor i64 %580, %1
  store i64 %581, ptr %3, align 8
  br label %361

582:                                              ; preds = %149
  %583 = load i64, ptr %3, align 8
  %584 = ptrtoint ptr %0 to i64
  %585 = or i64 %583, %583
  %586 = sub i64 %585, %584
  %587 = sub i64 %586, %1
  %588 = mul i64 %587, %583
  store i64 %588, ptr %3, align 8
  br label %361

589:                                              ; preds = %176
  %590 = load i64, ptr %3, align 8
  %591 = ptrtoint ptr %0 to i64
  %592 = add i64 %590, %590
  %593 = add i64 %592, %1
  %594 = xor i64 %593, %591
  %595 = sub i64 %594, %590
  store i64 %595, ptr %3, align 8
  br label %361

596:                                              ; preds = %212
  %597 = load i64, ptr %3, align 8
  %598 = ptrtoint ptr %0 to i64
  %599 = and i64 %1, %598
  %600 = mul i64 %599, %1
  %601 = or i64 %600, %597
  store i64 %601, ptr %3, align 8
  br label %361

602:                                              ; preds = %254
  %603 = load i64, ptr %3, align 8
  %604 = ptrtoint ptr %0 to i64
  %605 = or i64 %1, %1
  %606 = add i64 %605, %1
  %607 = or i64 %606, %603
  store i64 %607, ptr %3, align 8
  br label %361

608:                                              ; preds = %277
  %609 = load i64, ptr %3, align 8
  %610 = ptrtoint ptr %0 to i64
  %611 = or i64 %610, %609
  %612 = or i64 %611, %1
  %613 = mul i64 %612, %609
  %614 = xor i64 %613, %609
  store i64 %614, ptr %3, align 8
  br label %361

615:                                              ; preds = %303
  %616 = load i64, ptr %3, align 8
  %617 = ptrtoint ptr %0 to i64
  %618 = and i64 %1, %617
  %619 = add i64 %618, %1
  %620 = mul i64 %619, %617
  %621 = sub i64 %620, %1
  %622 = add i64 %621, %617
  %623 = sub i64 %622, %617
  store i64 %623, ptr %3, align 8
  br label %361

624:                                              ; preds = %337
  %625 = load i64, ptr %3, align 8
  %626 = ptrtoint ptr %0 to i64
  %627 = mul i64 %626, %626
  %628 = add i64 %627, %625
  %629 = mul i64 %628, %1
  %630 = or i64 %629, %1
  store i64 %630, ptr %3, align 8
  br label %361

631:                                              ; preds = %362
  %632 = load i64, ptr %3, align 8
  %633 = ptrtoint ptr %0 to i64
  %634 = mul i64 %1, %1
  %635 = sub i64 %634, %632
  %636 = xor i64 %635, %633
  %637 = add i64 %636, %1
  %638 = sub i64 %637, %1
  %639 = xor i64 %638, %1
  store i64 %639, ptr %3, align 8
  br label %10

640:                                              ; preds = %372
  %641 = load i64, ptr %3, align 8
  %642 = ptrtoint ptr %0 to i64
  %643 = or i64 %641, %1
  %644 = sub i64 %643, %642
  %645 = sub i64 %644, %642
  store i64 %645, ptr %3, align 8
  br label %361

646:                                              ; preds = %385
  %647 = load i64, ptr %3, align 8
  %648 = ptrtoint ptr %0 to i64
  %649 = add i64 %647, %1
  %650 = or i64 %649, %1
  %651 = add i64 %650, %648
  store i64 %651, ptr %3, align 8
  br label %361

652:                                              ; preds = %397
  %653 = load i64, ptr %3, align 8
  %654 = ptrtoint ptr %0 to i64
  %655 = add i64 %653, %653
  %656 = add i64 %655, %654
  %657 = and i64 %656, %653
  store i64 %657, ptr %3, align 8
  br label %361

658:                                              ; preds = %408
  %659 = load i64, ptr %3, align 8
  %660 = ptrtoint ptr %0 to i64
  %661 = mul i64 %1, %659
  %662 = and i64 %661, %659
  %663 = add i64 %662, %1
  %664 = or i64 %663, %659
  store i64 %664, ptr %3, align 8
  br label %361

665:                                              ; preds = %421
  %666 = load i64, ptr %3, align 8
  %667 = ptrtoint ptr %0 to i64
  %668 = xor i64 %666, %667
  %669 = sub i64 %668, %1
  %670 = xor i64 %669, %666
  store i64 %670, ptr %3, align 8
  br label %361

671:                                              ; preds = %433
  %672 = load i64, ptr %3, align 8
  %673 = ptrtoint ptr %0 to i64
  %674 = and i64 %672, %1
  %675 = or i64 %674, %673
  %676 = xor i64 %675, %672
  %677 = and i64 %676, %673
  %678 = mul i64 %677, %672
  store i64 %678, ptr %3, align 8
  br label %361

679:                                              ; preds = %453
  %680 = load i64, ptr %3, align 8
  %681 = ptrtoint ptr %0 to i64
  %682 = xor i64 %680, %680
  %683 = add i64 %682, %1
  %684 = add i64 %683, %1
  %685 = sub i64 %684, %681
  store i64 %685, ptr %3, align 8
  br label %361

686:                                              ; preds = %466
  %687 = load i64, ptr %3, align 8
  %688 = ptrtoint ptr %0 to i64
  %689 = sub i64 %688, %688
  %690 = and i64 %689, %1
  %691 = and i64 %690, %1
  %692 = or i64 %691, %687
  store i64 %692, ptr %3, align 8
  br label %361
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #5 = { nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nounwind willreturn memory(read) }
attributes #8 = { nounwind allocsize(0) }

!llvm.ident = !{!0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Ubuntu clang version 21.1.8 (++20251221032922+2078da43e25a-1~exp1~20251221153059.70)"}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"PIE Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}

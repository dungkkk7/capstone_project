; ModuleID = 'data/obfuscated/maze/obfuscated.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Point = type { i32, i32 }
%struct.MinHeap = type { ptr, i32, i32 }

@dr = dso_local global [4 x i32] [i32 -1, i32 1, i32 0, i32 0], align 16
@dc = dso_local global [4 x i32] [i32 0, i32 0, i32 -1, i32 1], align 16
@N = dso_local global i32 0, align 4
@grid = dso_local global ptr null, align 8
@.str = private unnamed_addr constant [24 x i8] c"Generated dungeon map:\0A\00", align 1
@.str.1 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@.str.2 = private unnamed_addr constant [13 x i8] c"\0ATreasures:\0A\00", align 1
@.str.3 = private unnamed_addr constant [15 x i8] c"T%d = (%d,%d)\0A\00", align 1
@.str.4 = private unnamed_addr constant [25 x i8] c"Full route coordinates:\0A\00", align 1
@.str.5 = private unnamed_addr constant [8 x i8] c"(%d,%d)\00", align 1
@.str.6 = private unnamed_addr constant [5 x i8] c" -> \00", align 1
@.str.7 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.8 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@.str.9 = private unnamed_addr constant [15 x i8] c"Invalid input\0A\00", align 1
@.str.10 = private unnamed_addr constant [28 x i8] c"N must be in range [4, 30]\0A\00", align 1
@.str.11 = private unnamed_addr constant [25 x i8] c"Dungeon Treasure Solver\0A\00", align 1
@.str.12 = private unnamed_addr constant [15 x i8] c"Input N = %d\0A\0A\00", align 1
@.str.13 = private unnamed_addr constant [94 x i8] c"Legend: S=start, E=exit, *=treasure, #=wall, ^=trap cost 5, ~=water cost 3, .=normal cost 1\0A\0A\00", align 1
@.str.14 = private unnamed_addr constant [27 x i8] c"\0ANo possible route found.\0A\00", align 1
@.str.15 = private unnamed_addr constant [29 x i8] c"\0ABest total energy cost: %d\0A\00", align 1
@.str.16 = private unnamed_addr constant [17 x i8] c"Treasure order: \00", align 1
@.str.17 = private unnamed_addr constant [4 x i8] c"T%d\00", align 1
@.str.18 = private unnamed_addr constant [27 x i8] c"Route length in cells: %d\0A\00", align 1
@0 = private global i32 0
@1 = private global i32 0
@2 = private global i32 0

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @inside(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i1, align 1
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 -1105266044, ptr %4, align 4
  br label %8

8:                                                ; preds = %255, %95, %94, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -673080648
  %11 = mul i32 %10, -1912373239
  %12 = icmp slt i32 %11, 1286153554
  br i1 %12, label %190, label %192

13:                                               ; preds = %198
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  %14 = load i32, ptr %6, align 4
  %15 = icmp sge i32 %14, 0
  store i1 false, ptr %5, align 1
  %16 = select i1 %15, i32 353786, i32 -1306909889
  store i32 %16, ptr %4, align 4
  %17 = xor i32 %0, 1895197281
  %18 = and i32 %0, %17
  %19 = or i32 %0, %17
  %20 = xor i32 %0, %17
  %21 = add i32 %0, %17
  %22 = sub i32 %21, %20
  %23 = mul i32 %18, 2
  %24 = sub i32 %22, %23
  %25 = mul i32 %24, 197
  %26 = icmp sgt i32 %25, 0
  br i1 %26, label %218, label %94

27:                                               ; preds = %206
  %28 = load i32, ptr %6, align 4
  %29 = load i32, ptr @N, align 4
  %30 = icmp slt i32 %28, %29
  store i1 false, ptr %5, align 1
  %31 = select i1 %30, i32 -1303096529, i32 -1306909889
  store i32 %31, ptr %4, align 4
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
  br i1 %49, label %94, label %228

50:                                               ; preds = %200
  %51 = load i32, ptr %7, align 4
  %52 = icmp sge i32 %51, 0
  store i1 false, ptr %5, align 1
  %53 = select i1 %52, i32 -355909969, i32 -1306909889
  store i32 %53, ptr %4, align 4
  %54 = xor i32 %0, -1976819177
  %55 = and i32 %0, %54
  %56 = or i32 %0, %54
  %57 = xor i32 %0, %54
  %58 = mul i32 %56, 2
  %59 = sub i32 %58, %57
  %60 = sub i32 %59, %0
  %61 = sub i32 %60, %54
  %62 = mul i32 %61, 27
  %63 = xor i32 %0, 8722531
  %64 = and i32 %0, %63
  %65 = or i32 %0, %63
  %66 = xor i32 %0, %63
  %67 = sub i32 %65, %66
  %68 = sub i32 %67, %64
  %69 = mul i32 %68, 171
  %70 = icmp eq i32 %62, %69
  br i1 %70, label %94, label %236

71:                                               ; preds = %214
  %72 = load i32, ptr %7, align 4
  %73 = load i32, ptr @N, align 4
  %74 = icmp slt i32 %72, %73
  store i1 %74, ptr %5, align 1
  store i32 -1306909889, ptr %4, align 4
  %75 = xor i32 %0, 1180118889
  %76 = and i32 %0, %75
  %77 = or i32 %0, %75
  %78 = xor i32 %0, %75
  %79 = add i32 %76, %77
  %80 = sub i32 %79, %0
  %81 = sub i32 %80, %75
  %82 = mul i32 %81, 76
  %83 = xor i32 %0, 299274331
  %84 = and i32 %0, %83
  %85 = or i32 %0, %83
  %86 = xor i32 %0, %83
  %87 = sub i32 %85, %86
  %88 = sub i32 %87, %84
  %89 = mul i32 %88, 141
  %90 = icmp ne i32 %82, %89
  br i1 %90, label %245, label %94

91:                                               ; preds = %216
  %92 = load i1, ptr %5, align 1
  %93 = zext i1 %92 to i32
  ret i32 %93

94:                                               ; preds = %297, %288, %280, %273, %264, %245, %236, %228, %218, %169, %156, %135, %116, %104, %71, %50, %27, %13
  br label %8

95:                                               ; preds = %216, %212, %210, %204, %200, %198
  store i32 -1105266044, ptr %4, align 4
  call void asm sideeffect "", ""()
  %96 = xor i32 %0, -420756149
  %97 = and i32 %0, %96
  %98 = or i32 %0, %96
  %99 = xor i32 %0, %96
  %100 = sub i32 %98, %99
  %101 = sub i32 %100, %97
  %102 = mul i32 %101, 106
  %103 = icmp ugt i32 %102, 0
  br i1 %103, label %255, label %8

104:                                              ; preds = %194
  %105 = load i32, ptr %4, align 4
  %106 = xor i32 %105, 1824824357
  store i32 %106, ptr %4, align 4
  %107 = xor i32 %0, 1639411133
  %108 = and i32 %0, %107
  %109 = or i32 %0, %107
  %110 = xor i32 %0, %107
  %111 = add i32 %108, %109
  %112 = sub i32 %111, %0
  %113 = sub i32 %112, %107
  %114 = mul i32 %113, 118
  %115 = icmp uge i32 %114, 0
  br i1 %115, label %94, label %264

116:                                              ; preds = %202
  %117 = load i32, ptr %4, align 4
  %118 = xor i32 %117, 1891974546
  store i32 %118, ptr %4, align 4
  %119 = xor i32 %0, -85930887
  %120 = and i32 %0, %119
  %121 = or i32 %0, %119
  %122 = xor i32 %0, %119
  %123 = add i32 %120, %121
  %124 = sub i32 %123, %0
  %125 = sub i32 %124, %119
  %126 = mul i32 %125, 119
  %127 = xor i32 %0, -340415041
  %128 = and i32 %0, %127
  %129 = or i32 %0, %127
  %130 = xor i32 %0, %127
  %131 = sub i32 %129, %130
  %132 = sub i32 %131, %128
  %133 = mul i32 %132, 42
  %134 = icmp ne i32 %126, %133
  br i1 %134, label %273, label %94

135:                                              ; preds = %204
  %136 = load i32, ptr %4, align 4
  %137 = xor i32 %136, 78685330
  store i32 %137, ptr %4, align 4
  %138 = xor i32 %0, 557366839
  %139 = and i32 %0, %138
  %140 = or i32 %0, %138
  %141 = xor i32 %0, %138
  %142 = mul i32 %140, 2
  %143 = sub i32 %142, %141
  %144 = sub i32 %143, %0
  %145 = sub i32 %144, %138
  %146 = mul i32 %145, 142
  %147 = xor i32 %0, -1048464703
  %148 = and i32 %0, %147
  %149 = or i32 %0, %147
  %150 = xor i32 %0, %147
  %151 = add i32 %148, %149
  %152 = sub i32 %151, %0
  %153 = sub i32 %152, %147
  %154 = mul i32 %153, 161
  %155 = icmp eq i32 %146, %154
  br i1 %155, label %94, label %280

156:                                              ; preds = %210
  %157 = load i32, ptr %4, align 4
  %158 = xor i32 %157, 1370368122
  store i32 %158, ptr %4, align 4
  %159 = xor i32 %0, 1786403003
  %160 = and i32 %0, %159
  %161 = or i32 %0, %159
  %162 = xor i32 %0, %159
  %163 = add i32 %0, %159
  %164 = sub i32 %163, %162
  %165 = mul i32 %160, 2
  %166 = sub i32 %164, %165
  %167 = mul i32 %166, 10
  %168 = icmp slt i32 %167, 1
  br i1 %168, label %94, label %288

169:                                              ; preds = %212
  %170 = load i32, ptr %4, align 4
  %171 = xor i32 %170, 2069653639
  store i32 %171, ptr %4, align 4
  %172 = xor i32 %0, -314542931
  %173 = and i32 %0, %172
  %174 = or i32 %0, %172
  %175 = xor i32 %0, %172
  %176 = mul i32 %174, 2
  %177 = sub i32 %176, %175
  %178 = sub i32 %177, %0
  %179 = sub i32 %178, %172
  %180 = mul i32 %179, 243
  %181 = xor i32 %0, -1931231015
  %182 = and i32 %0, %181
  %183 = or i32 %0, %181
  %184 = xor i32 %0, %181
  %185 = add i32 %182, %183
  %186 = sub i32 %185, %0
  %187 = sub i32 %186, %181
  %188 = mul i32 %187, 248
  %189 = icmp ne i32 %180, %188
  br i1 %189, label %297, label %94

190:                                              ; preds = %8
  %191 = icmp slt i32 %11, 900267055
  br i1 %191, label %194, label %196

192:                                              ; preds = %8
  %193 = icmp slt i32 %11, 1652340603
  br i1 %193, label %206, label %208

194:                                              ; preds = %190
  %195 = icmp eq i32 %11, 124550598
  br i1 %195, label %104, label %198

196:                                              ; preds = %190
  %197 = icmp slt i32 %11, 968520840
  br i1 %197, label %200, label %202

198:                                              ; preds = %194
  %199 = icmp eq i32 %11, 259153452
  br i1 %199, label %13, label %95

200:                                              ; preds = %196
  %201 = icmp eq i32 %11, 900267055
  br i1 %201, label %50, label %95

202:                                              ; preds = %196
  %203 = icmp eq i32 %11, 968520840
  br i1 %203, label %116, label %204

204:                                              ; preds = %202
  %205 = icmp eq i32 %11, 1162984337
  br i1 %205, label %135, label %95

206:                                              ; preds = %192
  %207 = icmp eq i32 %11, 1286153554
  br i1 %207, label %27, label %210

208:                                              ; preds = %192
  %209 = icmp slt i32 %11, 1778729903
  br i1 %209, label %212, label %214

210:                                              ; preds = %206
  %211 = icmp eq i32 %11, 1407612714
  br i1 %211, label %156, label %95

212:                                              ; preds = %208
  %213 = icmp eq i32 %11, 1652340603
  br i1 %213, label %169, label %95

214:                                              ; preds = %208
  %215 = icmp eq i32 %11, 1778729903
  br i1 %215, label %71, label %216

216:                                              ; preds = %214
  %217 = icmp eq i32 %11, 1809140927
  br i1 %217, label %91, label %95

218:                                              ; preds = %13
  %219 = load i64, ptr %3, align 8
  %220 = zext i32 %0 to i64
  %221 = zext i32 %1 to i64
  %222 = add i64 %219, %220
  %223 = add i64 %222, %220
  %224 = and i64 %223, %221
  %225 = sub i64 %224, %220
  %226 = sub i64 %225, %220
  %227 = xor i64 %226, %220
  store i64 %227, ptr %3, align 8
  br label %94

228:                                              ; preds = %27
  %229 = load i64, ptr %3, align 8
  %230 = zext i32 %0 to i64
  %231 = zext i32 %1 to i64
  %232 = or i64 %230, %229
  %233 = xor i64 %232, %230
  %234 = and i64 %233, %230
  %235 = mul i64 %234, %229
  store i64 %235, ptr %3, align 8
  br label %94

236:                                              ; preds = %50
  %237 = load i64, ptr %3, align 8
  %238 = zext i32 %0 to i64
  %239 = zext i32 %1 to i64
  %240 = xor i64 %238, %237
  %241 = mul i64 %240, %237
  %242 = mul i64 %241, %238
  %243 = and i64 %242, %239
  %244 = and i64 %243, %238
  store i64 %244, ptr %3, align 8
  br label %94

245:                                              ; preds = %71
  %246 = load i64, ptr %3, align 8
  %247 = zext i32 %0 to i64
  %248 = zext i32 %1 to i64
  %249 = xor i64 %247, %248
  %250 = or i64 %249, %247
  %251 = and i64 %250, %247
  %252 = and i64 %251, %247
  %253 = sub i64 %252, %247
  %254 = xor i64 %253, %246
  store i64 %254, ptr %3, align 8
  br label %94

255:                                              ; preds = %95
  %256 = load i64, ptr %3, align 8
  %257 = zext i32 %0 to i64
  %258 = zext i32 %1 to i64
  %259 = xor i64 %257, %256
  %260 = add i64 %259, %258
  %261 = add i64 %260, %258
  %262 = add i64 %261, %256
  %263 = mul i64 %262, %257
  store i64 %263, ptr %3, align 8
  br label %8

264:                                              ; preds = %104
  %265 = load i64, ptr %3, align 8
  %266 = zext i32 %0 to i64
  %267 = zext i32 %1 to i64
  %268 = and i64 %266, %265
  %269 = and i64 %268, %267
  %270 = sub i64 %269, %267
  %271 = sub i64 %270, %266
  %272 = and i64 %271, %266
  store i64 %272, ptr %3, align 8
  br label %94

273:                                              ; preds = %116
  %274 = load i64, ptr %3, align 8
  %275 = zext i32 %0 to i64
  %276 = zext i32 %1 to i64
  %277 = add i64 %274, %274
  %278 = xor i64 %277, %276
  %279 = and i64 %278, %275
  store i64 %279, ptr %3, align 8
  br label %94

280:                                              ; preds = %135
  %281 = load i64, ptr %3, align 8
  %282 = zext i32 %0 to i64
  %283 = zext i32 %1 to i64
  %284 = add i64 %282, %282
  %285 = or i64 %284, %281
  %286 = or i64 %285, %281
  %287 = add i64 %286, %281
  store i64 %287, ptr %3, align 8
  br label %94

288:                                              ; preds = %156
  %289 = load i64, ptr %3, align 8
  %290 = zext i32 %0 to i64
  %291 = zext i32 %1 to i64
  %292 = xor i64 %291, %289
  %293 = add i64 %292, %291
  %294 = or i64 %293, %291
  %295 = xor i64 %294, %291
  %296 = add i64 %295, %289
  store i64 %296, ptr %3, align 8
  br label %94

297:                                              ; preds = %169
  %298 = load i64, ptr %3, align 8
  %299 = zext i32 %0 to i64
  %300 = zext i32 %1 to i64
  %301 = and i64 %300, %298
  %302 = mul i64 %301, %298
  %303 = or i64 %302, %299
  %304 = mul i64 %303, %300
  %305 = or i64 %304, %300
  store i64 %305, ptr %3, align 8
  br label %94
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @idOf(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr @N, align 4
  %7 = mul nsw i32 %5, %6
  %8 = load i32, ptr %4, align 4
  %9 = or i32 %7, %8
  %10 = and i32 %7, %8
  %11 = add i32 %9, %10
  ret i32 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i64 @pointOf(i32 noundef %0) #0 {
  %2 = alloca %struct.Point, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = load i32, ptr %3, align 4
  %5 = load i32, ptr @N, align 4
  %6 = sdiv i32 %4, %5
  %7 = getelementptr inbounds nuw %struct.Point, ptr %2, i32 0, i32 0
  store i32 %6, ptr %7, align 4
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr @N, align 4
  %10 = srem i32 %8, %9
  %11 = getelementptr inbounds nuw %struct.Point, ptr %2, i32 0, i32 1
  store i32 %10, ptr %11, align 4
  %12 = load i64, ptr %2, align 4
  ret i64 %12
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @terrainCost(i8 noundef signext %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8, align 1
  store i32 -975716143, ptr %3, align 4
  br label %6

6:                                                ; preds = %324, %111, %110, %1
  %7 = load i32, ptr %3, align 4
  %8 = sub i32 %7, -1001811251
  %9 = mul i32 %8, 848609613
  %10 = icmp slt i32 %9, 1094752731
  br i1 %10, label %227, label %229

11:                                               ; preds = %237
  store i8 %0, ptr %5, align 1
  %12 = load i8, ptr %5, align 1
  %13 = sext i8 %12 to i32
  %14 = icmp eq i32 %13, 35
  %15 = select i1 %14, i32 1666242675, i32 1167614334
  store i32 %15, ptr %3, align 4
  %16 = xor i8 %0, 75
  %17 = and i8 %0, %16
  %18 = or i8 %0, %16
  %19 = xor i8 %0, %16
  %20 = mul i8 %18, 2
  %21 = sub i8 %20, %19
  %22 = sub i8 %21, %0
  %23 = sub i8 %22, %16
  %24 = mul i8 %23, 18
  %25 = icmp eq i8 %24, 0
  br i1 %25, label %110, label %271

26:                                               ; preds = %239
  store i32 1000000000, ptr %4, align 4
  store i32 1711126762, ptr %3, align 4
  %27 = xor i8 %0, 25
  %28 = and i8 %0, %27
  %29 = or i8 %0, %27
  %30 = xor i8 %0, %27
  %31 = mul i8 %29, 2
  %32 = sub i8 %31, %30
  %33 = sub i8 %32, %0
  %34 = sub i8 %33, %27
  %35 = mul i8 %34, -18
  %36 = xor i8 %0, -41
  %37 = and i8 %0, %36
  %38 = or i8 %0, %36
  %39 = xor i8 %0, %36
  %40 = sub i8 %38, %39
  %41 = sub i8 %40, %37
  %42 = mul i8 %41, -125
  %43 = icmp ne i8 %35, %42
  br i1 %43, label %277, label %110

44:                                               ; preds = %267
  %45 = load i8, ptr %5, align 1
  %46 = sext i8 %45 to i32
  %47 = icmp eq i32 %46, 94
  %48 = select i1 %47, i32 -1916755561, i32 842518965
  store i32 %48, ptr %3, align 4
  %49 = xor i8 %0, 49
  %50 = and i8 %0, %49
  %51 = or i8 %0, %49
  %52 = xor i8 %0, %49
  %53 = add i8 %50, %51
  %54 = sub i8 %53, %0
  %55 = sub i8 %54, %49
  %56 = mul i8 %55, -36
  %57 = icmp ne i8 %56, 0
  br i1 %57, label %284, label %110

58:                                               ; preds = %261
  store i32 5, ptr %4, align 4
  store i32 1711126762, ptr %3, align 4
  %59 = xor i8 %0, 75
  %60 = and i8 %0, %59
  %61 = or i8 %0, %59
  %62 = xor i8 %0, %59
  %63 = mul i8 %61, 2
  %64 = sub i8 %63, %62
  %65 = sub i8 %64, %0
  %66 = sub i8 %65, %59
  %67 = mul i8 %66, 43
  %68 = icmp slt i8 %67, 0
  br i1 %68, label %291, label %110

69:                                               ; preds = %263
  %70 = load i8, ptr %5, align 1
  %71 = sext i8 %70 to i32
  %72 = icmp eq i32 %71, 126
  %73 = select i1 %72, i32 771680112, i32 -135980932
  store i32 %73, ptr %3, align 4
  %74 = xor i8 %0, 33
  %75 = and i8 %0, %74
  %76 = or i8 %0, %74
  %77 = xor i8 %0, %74
  %78 = sub i8 %76, %77
  %79 = sub i8 %78, %75
  %80 = mul i8 %79, -87
  %81 = icmp ne i8 %80, 0
  br i1 %81, label %300, label %110

82:                                               ; preds = %259
  store i32 3, ptr %4, align 4
  store i32 1711126762, ptr %3, align 4
  %83 = xor i8 %0, 115
  %84 = and i8 %0, %83
  %85 = or i8 %0, %83
  %86 = xor i8 %0, %83
  %87 = sub i8 %85, %86
  %88 = sub i8 %87, %84
  %89 = mul i8 %88, -48
  %90 = icmp eq i8 %89, 0
  br i1 %90, label %110, label %307

91:                                               ; preds = %249
  store i32 1, ptr %4, align 4
  store i32 1711126762, ptr %3, align 4
  %92 = xor i8 %0, 125
  %93 = and i8 %0, %92
  %94 = or i8 %0, %92
  %95 = xor i8 %0, %92
  %96 = sub i8 %94, %95
  %97 = sub i8 %96, %93
  %98 = mul i8 %97, -122
  %99 = xor i8 %0, 123
  %100 = and i8 %0, %99
  %101 = or i8 %0, %99
  %102 = xor i8 %0, %99
  %103 = add i8 %100, %101
  %104 = sub i8 %103, %0
  %105 = sub i8 %104, %99
  %106 = mul i8 %105, 102
  %107 = icmp eq i8 %98, %106
  br i1 %107, label %110, label %316

108:                                              ; preds = %247
  %109 = load i32, ptr %4, align 4
  ret i32 %109

110:                                              ; preds = %388, %381, %374, %365, %359, %350, %341, %332, %316, %307, %300, %291, %284, %277, %271, %214, %203, %190, %179, %167, %146, %133, %122, %91, %82, %69, %58, %44, %26, %11
  br label %6

111:                                              ; preds = %269, %267, %261, %259, %249, %247, %241, %239
  store i32 -975716143, ptr %3, align 4
  call void asm sideeffect "", ""()
  %112 = xor i8 %0, 127
  %113 = and i8 %0, %112
  %114 = or i8 %0, %112
  %115 = xor i8 %0, %112
  %116 = add i8 %0, %112
  %117 = sub i8 %116, %115
  %118 = mul i8 %113, 2
  %119 = sub i8 %117, %118
  %120 = mul i8 %119, -94
  %121 = icmp slt i8 %120, 1
  br i1 %121, label %6, label %324

122:                                              ; preds = %255
  %123 = load i32, ptr %3, align 4
  %124 = xor i32 %123, 1356840227
  store i32 %124, ptr %3, align 4
  %125 = xor i8 %0, 59
  %126 = and i8 %0, %125
  %127 = or i8 %0, %125
  %128 = xor i8 %0, %125
  %129 = sub i8 %127, %128
  %130 = sub i8 %129, %126
  %131 = mul i8 %130, -33
  %132 = icmp uge i8 %131, 0
  br i1 %132, label %110, label %332

133:                                              ; preds = %257
  %134 = load i32, ptr %3, align 4
  %135 = xor i32 %134, 1330323466
  store i32 %135, ptr %3, align 4
  %136 = xor i8 %0, 1
  %137 = and i8 %0, %136
  %138 = or i8 %0, %136
  %139 = xor i8 %0, %136
  %140 = add i8 %0, %136
  %141 = sub i8 %140, %139
  %142 = mul i8 %137, 2
  %143 = sub i8 %141, %142
  %144 = mul i8 %143, -12
  %145 = icmp slt i8 %144, 1
  br i1 %145, label %110, label %341

146:                                              ; preds = %265
  %147 = load i32, ptr %3, align 4
  %148 = xor i32 %147, 1465746178
  store i32 %148, ptr %3, align 4
  %149 = xor i8 %0, 93
  %150 = and i8 %0, %149
  %151 = or i8 %0, %149
  %152 = xor i8 %0, %149
  %153 = add i8 %0, %149
  %154 = sub i8 %153, %152
  %155 = mul i8 %150, 2
  %156 = sub i8 %154, %155
  %157 = mul i8 %156, 80
  %158 = xor i8 %0, 111
  %159 = and i8 %0, %158
  %160 = or i8 %0, %158
  %161 = xor i8 %0, %158
  %162 = add i8 %159, %160
  %163 = sub i8 %162, %0
  %164 = sub i8 %163, %158
  %165 = mul i8 %164, 8
  %166 = icmp ne i8 %157, %165
  br i1 %166, label %350, label %110

167:                                              ; preds = %245
  %168 = load i32, ptr %3, align 4
  %169 = xor i32 %168, 881655966
  store i32 %169, ptr %3, align 4
  %170 = xor i8 %0, 77
  %171 = and i8 %0, %170
  %172 = or i8 %0, %170
  %173 = xor i8 %0, %170
  %174 = add i8 %171, %172
  %175 = sub i8 %174, %0
  %176 = sub i8 %175, %170
  %177 = mul i8 %176, -102
  %178 = icmp slt i8 %177, 0
  br i1 %178, label %359, label %110

179:                                              ; preds = %235
  %180 = load i32, ptr %3, align 4
  %181 = xor i32 %180, 814394253
  store i32 %181, ptr %3, align 4
  %182 = xor i8 %0, 65
  %183 = and i8 %0, %182
  %184 = or i8 %0, %182
  %185 = xor i8 %0, %182
  %186 = sub i8 %184, %185
  %187 = sub i8 %186, %183
  %188 = mul i8 %187, -78
  %189 = icmp ugt i8 %188, 0
  br i1 %189, label %365, label %110

190:                                              ; preds = %241
  %191 = load i32, ptr %3, align 4
  %192 = xor i32 %191, 351985454
  store i32 %192, ptr %3, align 4
  %193 = xor i8 %0, 103
  %194 = and i8 %0, %193
  %195 = or i8 %0, %193
  %196 = xor i8 %0, %193
  %197 = add i8 %0, %193
  %198 = sub i8 %197, %196
  %199 = mul i8 %194, 2
  %200 = sub i8 %198, %199
  %201 = mul i8 %200, -2
  %202 = icmp slt i8 %201, 0
  br i1 %202, label %374, label %110

203:                                              ; preds = %269
  %204 = load i32, ptr %3, align 4
  %205 = xor i32 %204, 1341920249
  store i32 %205, ptr %3, align 4
  %206 = xor i8 %0, 55
  %207 = and i8 %0, %206
  %208 = or i8 %0, %206
  %209 = xor i8 %0, %206
  %210 = sub i8 %208, %209
  %211 = sub i8 %210, %207
  %212 = mul i8 %211, -97
  %213 = icmp ugt i8 %212, 0
  br i1 %213, label %381, label %110

214:                                              ; preds = %243
  %215 = load i32, ptr %3, align 4
  %216 = xor i32 %215, -960038623
  store i32 %216, ptr %3, align 4
  %217 = xor i8 %0, 123
  %218 = and i8 %0, %217
  %219 = or i8 %0, %217
  %220 = xor i8 %0, %217
  %221 = mul i8 %219, 2
  %222 = sub i8 %221, %220
  %223 = sub i8 %222, %0
  %224 = sub i8 %223, %217
  %225 = mul i8 %224, 15
  %226 = icmp sle i8 %225, 0
  br i1 %226, label %110, label %388

227:                                              ; preds = %6
  %228 = icmp slt i32 %9, 632209053
  br i1 %228, label %231, label %233

229:                                              ; preds = %6
  %230 = icmp slt i32 %9, 1547031496
  br i1 %230, label %251, label %253

231:                                              ; preds = %227
  %232 = icmp slt i32 %9, 180673332
  br i1 %232, label %235, label %237

233:                                              ; preds = %227
  %234 = icmp slt i32 %9, 912506734
  br i1 %234, label %243, label %245

235:                                              ; preds = %231
  %236 = icmp eq i32 %9, 8349486
  br i1 %236, label %179, label %239

237:                                              ; preds = %231
  %238 = icmp eq i32 %9, 180673332
  br i1 %238, label %11, label %241

239:                                              ; preds = %235
  %240 = icmp eq i32 %9, 11147502
  br i1 %240, label %26, label %111

241:                                              ; preds = %237
  %242 = icmp eq i32 %9, 469398245
  br i1 %242, label %190, label %111

243:                                              ; preds = %233
  %244 = icmp eq i32 %9, 632209053
  br i1 %244, label %214, label %247

245:                                              ; preds = %233
  %246 = icmp eq i32 %9, 912506734
  br i1 %246, label %167, label %249

247:                                              ; preds = %243
  %248 = icmp eq i32 %9, 649024441
  br i1 %248, label %108, label %111

249:                                              ; preds = %245
  %250 = icmp eq i32 %9, 1018963107
  br i1 %250, label %91, label %111

251:                                              ; preds = %229
  %252 = icmp slt i32 %9, 1366121799
  br i1 %252, label %255, label %257

253:                                              ; preds = %229
  %254 = icmp slt i32 %9, 1635880090
  br i1 %254, label %263, label %265

255:                                              ; preds = %251
  %256 = icmp eq i32 %9, 1094752731
  br i1 %256, label %122, label %259

257:                                              ; preds = %251
  %258 = icmp eq i32 %9, 1366121799
  br i1 %258, label %133, label %261

259:                                              ; preds = %255
  %260 = icmp eq i32 %9, 1150638087
  br i1 %260, label %82, label %111

261:                                              ; preds = %257
  %262 = icmp eq i32 %9, 1539161282
  br i1 %262, label %58, label %111

263:                                              ; preds = %253
  %264 = icmp eq i32 %9, 1547031496
  br i1 %264, label %69, label %267

265:                                              ; preds = %253
  %266 = icmp eq i32 %9, 1635880090
  br i1 %266, label %146, label %269

267:                                              ; preds = %263
  %268 = icmp eq i32 %9, 1591450685
  br i1 %268, label %44, label %111

269:                                              ; preds = %265
  %270 = icmp eq i32 %9, 1672318714
  br i1 %270, label %203, label %111

271:                                              ; preds = %11
  %272 = load i64, ptr %2, align 8
  %273 = zext i8 %0 to i64
  %274 = add i64 %272, %272
  %275 = sub i64 %274, %273
  %276 = and i64 %275, %272
  store i64 %276, ptr %2, align 8
  br label %110

277:                                              ; preds = %26
  %278 = load i64, ptr %2, align 8
  %279 = zext i8 %0 to i64
  %280 = or i64 %278, %279
  %281 = mul i64 %280, %278
  %282 = xor i64 %281, %279
  %283 = and i64 %282, %278
  store i64 %283, ptr %2, align 8
  br label %110

284:                                              ; preds = %44
  %285 = load i64, ptr %2, align 8
  %286 = zext i8 %0 to i64
  %287 = or i64 %286, %285
  %288 = sub i64 %287, %286
  %289 = add i64 %288, %286
  %290 = mul i64 %289, %286
  store i64 %290, ptr %2, align 8
  br label %110

291:                                              ; preds = %58
  %292 = load i64, ptr %2, align 8
  %293 = zext i8 %0 to i64
  %294 = sub i64 %293, %292
  %295 = add i64 %294, %293
  %296 = or i64 %295, %293
  %297 = xor i64 %296, %293
  %298 = add i64 %297, %293
  %299 = add i64 %298, %292
  store i64 %299, ptr %2, align 8
  br label %110

300:                                              ; preds = %69
  %301 = load i64, ptr %2, align 8
  %302 = zext i8 %0 to i64
  %303 = add i64 %301, %301
  %304 = xor i64 %303, %302
  %305 = sub i64 %304, %301
  %306 = mul i64 %305, %301
  store i64 %306, ptr %2, align 8
  br label %110

307:                                              ; preds = %82
  %308 = load i64, ptr %2, align 8
  %309 = zext i8 %0 to i64
  %310 = xor i64 %308, %308
  %311 = mul i64 %310, %309
  %312 = or i64 %311, %308
  %313 = sub i64 %312, %309
  %314 = sub i64 %313, %309
  %315 = and i64 %314, %309
  store i64 %315, ptr %2, align 8
  br label %110

316:                                              ; preds = %91
  %317 = load i64, ptr %2, align 8
  %318 = zext i8 %0 to i64
  %319 = sub i64 %317, %318
  %320 = add i64 %319, %318
  %321 = mul i64 %320, %318
  %322 = and i64 %321, %317
  %323 = xor i64 %322, %318
  store i64 %323, ptr %2, align 8
  br label %110

324:                                              ; preds = %111
  %325 = load i64, ptr %2, align 8
  %326 = zext i8 %0 to i64
  %327 = mul i64 %325, %325
  %328 = mul i64 %327, %326
  %329 = xor i64 %328, %326
  %330 = or i64 %329, %325
  %331 = sub i64 %330, %326
  store i64 %331, ptr %2, align 8
  br label %6

332:                                              ; preds = %122
  %333 = load i64, ptr %2, align 8
  %334 = zext i8 %0 to i64
  %335 = sub i64 %333, %334
  %336 = sub i64 %335, %334
  %337 = add i64 %336, %333
  %338 = or i64 %337, %334
  %339 = mul i64 %338, %334
  %340 = sub i64 %339, %333
  store i64 %340, ptr %2, align 8
  br label %110

341:                                              ; preds = %133
  %342 = load i64, ptr %2, align 8
  %343 = zext i8 %0 to i64
  %344 = add i64 %342, %343
  %345 = sub i64 %344, %343
  %346 = add i64 %345, %343
  %347 = add i64 %346, %342
  %348 = add i64 %347, %342
  %349 = and i64 %348, %342
  store i64 %349, ptr %2, align 8
  br label %110

350:                                              ; preds = %146
  %351 = load i64, ptr %2, align 8
  %352 = zext i8 %0 to i64
  %353 = xor i64 %352, %351
  %354 = add i64 %353, %352
  %355 = sub i64 %354, %352
  %356 = and i64 %355, %352
  %357 = xor i64 %356, %351
  %358 = add i64 %357, %352
  store i64 %358, ptr %2, align 8
  br label %110

359:                                              ; preds = %167
  %360 = load i64, ptr %2, align 8
  %361 = zext i8 %0 to i64
  %362 = add i64 %361, %360
  %363 = mul i64 %362, %361
  %364 = sub i64 %363, %360
  store i64 %364, ptr %2, align 8
  br label %110

365:                                              ; preds = %179
  %366 = load i64, ptr %2, align 8
  %367 = zext i8 %0 to i64
  %368 = and i64 %367, %367
  %369 = xor i64 %368, %367
  %370 = sub i64 %369, %367
  %371 = mul i64 %370, %366
  %372 = add i64 %371, %366
  %373 = and i64 %372, %367
  store i64 %373, ptr %2, align 8
  br label %110

374:                                              ; preds = %190
  %375 = load i64, ptr %2, align 8
  %376 = zext i8 %0 to i64
  %377 = xor i64 %375, %376
  %378 = mul i64 %377, %375
  %379 = and i64 %378, %376
  %380 = add i64 %379, %376
  store i64 %380, ptr %2, align 8
  br label %110

381:                                              ; preds = %203
  %382 = load i64, ptr %2, align 8
  %383 = zext i8 %0 to i64
  %384 = mul i64 %383, %383
  %385 = sub i64 %384, %383
  %386 = sub i64 %385, %382
  %387 = or i64 %386, %383
  store i64 %387, ptr %2, align 8
  br label %110

388:                                              ; preds = %214
  %389 = load i64, ptr %2, align 8
  %390 = zext i8 %0 to i64
  %391 = add i64 %390, %390
  %392 = add i64 %391, %390
  %393 = sub i64 %392, %390
  %394 = add i64 %393, %389
  %395 = and i64 %394, %389
  store i64 %395, ptr %2, align 8
  br label %110
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local ptr @createHeap(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  store i32 %0, ptr %2, align 4
  %4 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %4, ptr %3, align 8
  %5 = load i32, ptr %2, align 4
  %6 = or i32 %5, 5
  %7 = and i32 %5, 5
  %8 = add i32 %6, %7
  %9 = sext i32 %8 to i64
  %10 = mul i64 8, %9
  %11 = call noalias ptr @malloc(i64 noundef %10) #6
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.MinHeap, ptr %12, i32 0, i32 0
  store ptr %11, ptr %13, align 8
  %14 = load ptr, ptr %3, align 8
  %15 = getelementptr inbounds nuw %struct.MinHeap, ptr %14, i32 0, i32 1
  store i32 0, ptr %15, align 8
  %16 = load i32, ptr %2, align 4
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds nuw %struct.MinHeap, ptr %17, i32 0, i32 2
  store i32 %16, ptr %18, align 4
  %19 = load ptr, ptr %3, align 8
  ret ptr %19
}

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @swapNode(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca %struct.Point, align 4
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %6 = load ptr, ptr %3, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %5, ptr align 4 %6, i64 8, i1 false)
  %7 = load ptr, ptr %3, align 8
  %8 = load ptr, ptr %4, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %7, ptr align 4 %8, i64 8, i1 false)
  %9 = load ptr, ptr %4, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %9, ptr align 4 %5, i64 8, i1 false)
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @pushHeap(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 1920907473, ptr %5, align 4
  br label %11

11:                                               ; preds = %485, %268, %267, %3
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 1223701227
  %14 = mul i32 %13, 749467121
  switch i32 %14, label %268 [
    i32 2113088390, label %15
    i32 1907058347, label %39
    i32 894890419, label %73
    i32 749736977, label %123
    i32 1961172393, label %137
    i32 972708105, label %168
    i32 650439351, label %179
    i32 1177369363, label %206
    i32 852539963, label %234
    i32 1615168452, label %243
    i32 2135713618, label %266
    i32 964651727, label %287
    i32 384447093, label %300
    i32 1034075228, label %311
    i32 679577690, label %332
    i32 1669554867, label %344
    i32 1798434106, label %355
    i32 1778597130, label %366
    i32 1684073521, label %378
  ]

15:                                               ; preds = %11
  store ptr %0, ptr %6, align 8
  store i32 %1, ptr %7, align 4
  store i32 %2, ptr %8, align 4
  %16 = load ptr, ptr %6, align 8
  %17 = getelementptr inbounds nuw %struct.MinHeap, ptr %16, i32 0, i32 1
  %18 = load i32, ptr %17, align 8
  %19 = load i32, ptr %5, align 4
  %20 = xor i32 %19, 1920907475
  %21 = or i32 %18, %20
  %22 = load i32, ptr %5, align 4
  %23 = xor i32 %22, 1920907475
  %24 = and i32 %18, %23
  %25 = add i32 %21, %24
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.MinHeap, ptr %26, i32 0, i32 2
  %28 = load i32, ptr %27, align 4
  %29 = icmp sge i32 %25, %28
  %30 = select i1 %29, i32 1493749062, i32 -1625759538
  store i32 %30, ptr %5, align 4
  %31 = xor i32 %1, 2011155501
  %32 = and i32 %1, %31
  %33 = or i32 %1, %31
  %34 = xor i32 %1, %31
  %35 = sub i32 %33, %34
  %36 = sub i32 %35, %32
  %37 = mul i32 %36, 100
  %38 = icmp sle i32 %37, 0
  br i1 %38, label %267, label %390

39:                                               ; preds = %11
  %40 = load ptr, ptr %6, align 8
  %41 = getelementptr inbounds nuw %struct.MinHeap, ptr %40, i32 0, i32 2
  %42 = load i32, ptr %41, align 4
  %43 = load i32, ptr %5, align 4
  %44 = xor i32 %43, 1493749060
  %45 = mul nsw i32 %42, %44
  store i32 %45, ptr %41, align 4
  %46 = load ptr, ptr %6, align 8
  %47 = getelementptr inbounds nuw %struct.MinHeap, ptr %46, i32 0, i32 0
  %48 = load ptr, ptr %47, align 8
  %49 = load ptr, ptr %6, align 8
  %50 = getelementptr inbounds nuw %struct.MinHeap, ptr %49, i32 0, i32 2
  %51 = load i32, ptr %50, align 4
  %52 = load i32, ptr %5, align 4
  %53 = xor i32 %52, 1493749059
  %54 = or i32 %51, %53
  %55 = load i32, ptr %5, align 4
  %56 = xor i32 %55, 1493749059
  %57 = and i32 %51, %56
  %58 = add i32 %54, %57
  %59 = sext i32 %58 to i64
  %60 = mul i64 8, %59
  %61 = call ptr @realloc(ptr noundef %48, i64 noundef %60) #7
  %62 = load ptr, ptr %6, align 8
  %63 = getelementptr inbounds nuw %struct.MinHeap, ptr %62, i32 0, i32 0
  store ptr %61, ptr %63, align 8
  store i32 -1625759538, ptr %5, align 4
  %64 = xor i32 %1, -486317455
  %65 = and i32 %1, %64
  %66 = or i32 %1, %64
  %67 = xor i32 %1, %64
  %68 = add i32 %65, %66
  %69 = sub i32 %68, %1
  %70 = sub i32 %69, %64
  %71 = mul i32 %70, 244
  %72 = icmp eq i32 %71, 0
  br i1 %72, label %267, label %399

73:                                               ; preds = %11
  %74 = load ptr, ptr %6, align 8
  %75 = getelementptr inbounds nuw %struct.MinHeap, ptr %74, i32 0, i32 1
  %76 = load i32, ptr %75, align 8
  %77 = load i32, ptr %5, align 4
  %78 = xor i32 %77, -1625759537
  %79 = xor i32 %76, %78
  %80 = load i32, ptr %5, align 4
  %81 = xor i32 %80, -1625759537
  %82 = and i32 %76, %81
  %83 = add i32 %82, %82
  %84 = add i32 %79, %83
  store i32 %84, ptr %75, align 8
  %85 = load ptr, ptr %6, align 8
  %86 = getelementptr inbounds nuw %struct.MinHeap, ptr %85, i32 0, i32 1
  %87 = load i32, ptr %86, align 8
  store i32 %87, ptr %9, align 4
  %88 = load i32, ptr %7, align 4
  %89 = load ptr, ptr %6, align 8
  %90 = getelementptr inbounds nuw %struct.MinHeap, ptr %89, i32 0, i32 0
  %91 = load ptr, ptr %90, align 8
  %92 = load i32, ptr %9, align 4
  %93 = sext i32 %92 to i64
  %94 = getelementptr inbounds %struct.Point, ptr %91, i64 %93
  %95 = getelementptr inbounds nuw %struct.Point, ptr %94, i32 0, i32 0
  store i32 %88, ptr %95, align 4
  %96 = load i32, ptr %8, align 4
  %97 = load ptr, ptr %6, align 8
  %98 = getelementptr inbounds nuw %struct.MinHeap, ptr %97, i32 0, i32 0
  %99 = load ptr, ptr %98, align 8
  %100 = load i32, ptr %9, align 4
  %101 = sext i32 %100 to i64
  %102 = getelementptr inbounds %struct.Point, ptr %99, i64 %101
  %103 = getelementptr inbounds nuw %struct.Point, ptr %102, i32 0, i32 1
  store i32 %96, ptr %103, align 4
  store i32 -991194356, ptr %5, align 4
  %104 = xor i32 %1, 1561031969
  %105 = and i32 %1, %104
  %106 = or i32 %1, %104
  %107 = xor i32 %1, %104
  %108 = mul i32 %106, 2
  %109 = sub i32 %108, %107
  %110 = sub i32 %109, %1
  %111 = sub i32 %110, %104
  %112 = mul i32 %111, 53
  %113 = xor i32 %1, -18977049
  %114 = and i32 %1, %113
  %115 = or i32 %1, %113
  %116 = xor i32 %1, %113
  %117 = add i32 %1, %113
  %118 = sub i32 %117, %116
  %119 = mul i32 %114, 2
  %120 = sub i32 %118, %119
  %121 = mul i32 %120, 171
  %122 = icmp ne i32 %112, %121
  br i1 %122, label %409, label %267

123:                                              ; preds = %11
  %124 = load i32, ptr %9, align 4
  %125 = icmp sgt i32 %124, 1
  %126 = select i1 %125, i32 -426099164, i32 -1752353443
  store i32 %126, ptr %5, align 4
  %127 = xor i32 %1, 1140087759
  %128 = and i32 %1, %127
  %129 = or i32 %1, %127
  %130 = xor i32 %1, %127
  %131 = add i32 %1, %127
  %132 = sub i32 %131, %130
  %133 = mul i32 %128, 2
  %134 = sub i32 %132, %133
  %135 = mul i32 %134, 219
  %136 = icmp slt i32 %135, 0
  br i1 %136, label %419, label %267

137:                                              ; preds = %11
  %138 = load i32, ptr %9, align 4
  %139 = sdiv i32 %138, 2
  store i32 %139, ptr %10, align 4
  %140 = load ptr, ptr %6, align 8
  %141 = getelementptr inbounds nuw %struct.MinHeap, ptr %140, i32 0, i32 0
  %142 = load ptr, ptr %141, align 8
  %143 = load i32, ptr %10, align 4
  %144 = sext i32 %143 to i64
  %145 = getelementptr inbounds %struct.Point, ptr %142, i64 %144
  %146 = getelementptr inbounds nuw %struct.Point, ptr %145, i32 0, i32 1
  %147 = load i32, ptr %146, align 4
  %148 = load ptr, ptr %6, align 8
  %149 = getelementptr inbounds nuw %struct.MinHeap, ptr %148, i32 0, i32 0
  %150 = load ptr, ptr %149, align 8
  %151 = load i32, ptr %9, align 4
  %152 = sext i32 %151 to i64
  %153 = getelementptr inbounds %struct.Point, ptr %150, i64 %152
  %154 = getelementptr inbounds nuw %struct.Point, ptr %153, i32 0, i32 1
  %155 = load i32, ptr %154, align 4
  %156 = icmp slt i32 %147, %155
  %157 = select i1 %156, i32 1075728260, i32 -1316301294
  store i32 %157, ptr %5, align 4
  %158 = xor i32 %1, -2113215999
  %159 = and i32 %1, %158
  %160 = or i32 %1, %158
  %161 = xor i32 %1, %158
  %162 = add i32 %1, %158
  %163 = sub i32 %162, %161
  %164 = mul i32 %159, 2
  %165 = sub i32 %163, %164
  %166 = mul i32 %165, 12
  %167 = icmp sgt i32 %166, 0
  br i1 %167, label %428, label %267

168:                                              ; preds = %11
  store i32 -1752353443, ptr %5, align 4
  %169 = xor i32 %1, -388146869
  %170 = and i32 %1, %169
  %171 = or i32 %1, %169
  %172 = xor i32 %1, %169
  %173 = mul i32 %171, 2
  %174 = sub i32 %173, %172
  %175 = sub i32 %174, %1
  %176 = sub i32 %175, %169
  %177 = mul i32 %176, 122
  %178 = icmp sle i32 %177, 0
  br i1 %178, label %267, label %438

179:                                              ; preds = %11
  %180 = load ptr, ptr %6, align 8
  %181 = getelementptr inbounds nuw %struct.MinHeap, ptr %180, i32 0, i32 0
  %182 = load ptr, ptr %181, align 8
  %183 = load i32, ptr %10, align 4
  %184 = sext i32 %183 to i64
  %185 = getelementptr inbounds %struct.Point, ptr %182, i64 %184
  %186 = getelementptr inbounds nuw %struct.Point, ptr %185, i32 0, i32 1
  %187 = load i32, ptr %186, align 4
  %188 = load ptr, ptr %6, align 8
  %189 = getelementptr inbounds nuw %struct.MinHeap, ptr %188, i32 0, i32 0
  %190 = load ptr, ptr %189, align 8
  %191 = load i32, ptr %9, align 4
  %192 = sext i32 %191 to i64
  %193 = getelementptr inbounds %struct.Point, ptr %190, i64 %192
  %194 = getelementptr inbounds nuw %struct.Point, ptr %193, i32 0, i32 1
  %195 = load i32, ptr %194, align 4
  %196 = icmp eq i32 %187, %195
  %197 = select i1 %196, i32 -798433234, i32 -469459217
  store i32 %197, ptr %5, align 4
  %198 = xor i32 %1, -568246481
  %199 = and i32 %1, %198
  %200 = or i32 %1, %198
  %201 = xor i32 %1, %198
  %202 = sub i32 %200, %201
  %203 = sub i32 %202, %199
  %204 = mul i32 %203, 112
  %205 = icmp eq i32 %204, 0
  br i1 %205, label %267, label %448

206:                                              ; preds = %11
  %207 = load ptr, ptr %6, align 8
  %208 = getelementptr inbounds nuw %struct.MinHeap, ptr %207, i32 0, i32 0
  %209 = load ptr, ptr %208, align 8
  %210 = load i32, ptr %10, align 4
  %211 = sext i32 %210 to i64
  %212 = getelementptr inbounds %struct.Point, ptr %209, i64 %211
  %213 = getelementptr inbounds nuw %struct.Point, ptr %212, i32 0, i32 0
  %214 = load i32, ptr %213, align 4
  %215 = load ptr, ptr %6, align 8
  %216 = getelementptr inbounds nuw %struct.MinHeap, ptr %215, i32 0, i32 0
  %217 = load ptr, ptr %216, align 8
  %218 = load i32, ptr %9, align 4
  %219 = sext i32 %218 to i64
  %220 = getelementptr inbounds %struct.Point, ptr %217, i64 %219
  %221 = getelementptr inbounds nuw %struct.Point, ptr %220, i32 0, i32 0
  %222 = load i32, ptr %221, align 4
  %223 = icmp slt i32 %214, %222
  %224 = select i1 %223, i32 1740081622, i32 -469459217
  store i32 %224, ptr %5, align 4
  %225 = xor i32 %1, 734621681
  %226 = and i32 %1, %225
  %227 = or i32 %1, %225
  %228 = xor i32 %1, %225
  %229 = add i32 %226, %227
  %230 = sub i32 %229, %1
  %231 = sub i32 %230, %225
  %232 = mul i32 %231, 79
  %233 = icmp sle i32 %232, 0
  br i1 %233, label %267, label %459

234:                                              ; preds = %11
  store i32 -1752353443, ptr %5, align 4
  %235 = xor i32 %1, 1727830723
  %236 = and i32 %1, %235
  %237 = or i32 %1, %235
  %238 = xor i32 %1, %235
  %239 = sub i32 %237, %238
  %240 = sub i32 %239, %236
  %241 = mul i32 %240, 100
  %242 = icmp uge i32 %241, 0
  br i1 %242, label %267, label %467

243:                                              ; preds = %11
  %244 = load ptr, ptr %6, align 8
  %245 = getelementptr inbounds nuw %struct.MinHeap, ptr %244, i32 0, i32 0
  %246 = load ptr, ptr %245, align 8
  %247 = load i32, ptr %10, align 4
  %248 = sext i32 %247 to i64
  %249 = getelementptr inbounds %struct.Point, ptr %246, i64 %248
  %250 = load ptr, ptr %6, align 8
  %251 = getelementptr inbounds nuw %struct.MinHeap, ptr %250, i32 0, i32 0
  %252 = load ptr, ptr %251, align 8
  %253 = load i32, ptr %9, align 4
  %254 = sext i32 %253 to i64
  %255 = getelementptr inbounds %struct.Point, ptr %252, i64 %254
  call void @swapNode(ptr noundef %249, ptr noundef %255)
  %256 = load i32, ptr %10, align 4
  store i32 %256, ptr %9, align 4
  store i32 -991194356, ptr %5, align 4
  %257 = xor i32 %1, -1267570053
  %258 = and i32 %1, %257
  %259 = or i32 %1, %257
  %260 = xor i32 %1, %257
  %261 = add i32 %258, %259
  %262 = sub i32 %261, %1
  %263 = sub i32 %262, %257
  %264 = mul i32 %263, 197
  %265 = icmp uge i32 %264, 0
  br i1 %265, label %267, label %475

266:                                              ; preds = %11
  ret void

267:                                              ; preds = %559, %550, %541, %530, %522, %513, %504, %494, %475, %467, %459, %448, %438, %428, %419, %409, %399, %390, %378, %366, %355, %344, %332, %311, %300, %287, %243, %234, %206, %179, %168, %137, %123, %73, %39, %15
  br label %11

268:                                              ; preds = %11
  store i32 1920907473, ptr %5, align 4
  call void asm sideeffect "", ""()
  %269 = xor i32 %1, 1029375319
  %270 = and i32 %1, %269
  %271 = or i32 %1, %269
  %272 = xor i32 %1, %269
  %273 = add i32 %270, %271
  %274 = sub i32 %273, %1
  %275 = sub i32 %274, %269
  %276 = mul i32 %275, 60
  %277 = xor i32 %1, -1622137095
  %278 = and i32 %1, %277
  %279 = or i32 %1, %277
  %280 = xor i32 %1, %277
  %281 = mul i32 %279, 2
  %282 = sub i32 %281, %280
  %283 = sub i32 %282, %1
  %284 = sub i32 %283, %277
  %285 = mul i32 %284, 123
  %286 = icmp ne i32 %276, %285
  br i1 %286, label %485, label %11

287:                                              ; preds = %11
  %288 = load i32, ptr %5, align 4
  %289 = xor i32 %288, -710970136
  store i32 %289, ptr %5, align 4
  %290 = xor i32 %1, -307664833
  %291 = and i32 %1, %290
  %292 = or i32 %1, %290
  %293 = xor i32 %1, %290
  %294 = mul i32 %292, 2
  %295 = sub i32 %294, %293
  %296 = sub i32 %295, %1
  %297 = sub i32 %296, %290
  %298 = mul i32 %297, 168
  %299 = icmp slt i32 %298, 0
  br i1 %299, label %494, label %267

300:                                              ; preds = %11
  %301 = load i32, ptr %5, align 4
  %302 = xor i32 %301, 1658943937
  store i32 %302, ptr %5, align 4
  %303 = xor i32 %1, -2113872575
  %304 = and i32 %1, %303
  %305 = or i32 %1, %303
  %306 = xor i32 %1, %303
  %307 = sub i32 %305, %306
  %308 = sub i32 %307, %304
  %309 = mul i32 %308, 43
  %310 = icmp sgt i32 %309, 0
  br i1 %310, label %504, label %267

311:                                              ; preds = %11
  %312 = load i32, ptr %5, align 4
  %313 = xor i32 %312, 335244546
  store i32 %313, ptr %5, align 4
  %314 = xor i32 %1, 439683909
  %315 = and i32 %1, %314
  %316 = or i32 %1, %314
  %317 = xor i32 %1, %314
  %318 = add i32 %315, %316
  %319 = sub i32 %318, %1
  %320 = sub i32 %319, %314
  %321 = mul i32 %320, 64
  %322 = xor i32 %1, 982363493
  %323 = and i32 %1, %322
  %324 = or i32 %1, %322
  %325 = xor i32 %1, %322
  %326 = add i32 %1, %322
  %327 = sub i32 %326, %325
  %328 = mul i32 %323, 2
  %329 = sub i32 %327, %328
  %330 = mul i32 %329, 103
  %331 = icmp eq i32 %321, %330
  br i1 %331, label %267, label %513

332:                                              ; preds = %11
  %333 = load i32, ptr %5, align 4
  %334 = xor i32 %333, -771829224
  store i32 %334, ptr %5, align 4
  %335 = xor i32 %1, -2034450679
  %336 = and i32 %1, %335
  %337 = or i32 %1, %335
  %338 = xor i32 %1, %335
  %339 = add i32 %336, %337
  %340 = sub i32 %339, %1
  %341 = sub i32 %340, %335
  %342 = mul i32 %341, 143
  %343 = icmp sle i32 %342, 0
  br i1 %343, label %267, label %522

344:                                              ; preds = %11
  %345 = load i32, ptr %5, align 4
  %346 = xor i32 %345, 1922382826
  store i32 %346, ptr %5, align 4
  %347 = xor i32 %1, -747122363
  %348 = and i32 %1, %347
  %349 = or i32 %1, %347
  %350 = xor i32 %1, %347
  %351 = sub i32 %349, %350
  %352 = sub i32 %351, %348
  %353 = mul i32 %352, 184
  %354 = icmp slt i32 %353, 0
  br i1 %354, label %530, label %267

355:                                              ; preds = %11
  %356 = load i32, ptr %5, align 4
  %357 = xor i32 %356, -266912977
  store i32 %357, ptr %5, align 4
  %358 = xor i32 %1, 1177145087
  %359 = and i32 %1, %358
  %360 = or i32 %1, %358
  %361 = xor i32 %1, %358
  %362 = sub i32 %360, %361
  %363 = sub i32 %362, %359
  %364 = mul i32 %363, 177
  %365 = icmp ugt i32 %364, 0
  br i1 %365, label %541, label %267

366:                                              ; preds = %11
  %367 = load i32, ptr %5, align 4
  %368 = xor i32 %367, 721126268
  store i32 %368, ptr %5, align 4
  %369 = xor i32 %1, -1985814227
  %370 = and i32 %1, %369
  %371 = or i32 %1, %369
  %372 = xor i32 %1, %369
  %373 = add i32 %370, %371
  %374 = sub i32 %373, %1
  %375 = sub i32 %374, %369
  %376 = mul i32 %375, 20
  %377 = icmp slt i32 %376, 0
  br i1 %377, label %550, label %267

378:                                              ; preds = %11
  %379 = load i32, ptr %5, align 4
  %380 = xor i32 %379, -1861678523
  store i32 %380, ptr %5, align 4
  %381 = xor i32 %1, 820354109
  %382 = and i32 %1, %381
  %383 = or i32 %1, %381
  %384 = xor i32 %1, %381
  %385 = add i32 %382, %383
  %386 = sub i32 %385, %1
  %387 = sub i32 %386, %381
  %388 = mul i32 %387, 66
  %389 = icmp slt i32 %388, 0
  br i1 %389, label %559, label %267

390:                                              ; preds = %15
  %391 = load i64, ptr %4, align 8
  %392 = ptrtoint ptr %0 to i64
  %393 = zext i32 %1 to i64
  %394 = zext i32 %2 to i64
  %395 = or i64 %392, %393
  %396 = and i64 %395, %392
  %397 = or i64 %396, %394
  %398 = and i64 %397, %394
  store i64 %398, ptr %4, align 8
  br label %267

399:                                              ; preds = %39
  %400 = load i64, ptr %4, align 8
  %401 = ptrtoint ptr %0 to i64
  %402 = zext i32 %1 to i64
  %403 = zext i32 %2 to i64
  %404 = xor i64 %401, %401
  %405 = and i64 %404, %402
  %406 = mul i64 %405, %401
  %407 = sub i64 %406, %402
  %408 = and i64 %407, %402
  store i64 %408, ptr %4, align 8
  br label %267

409:                                              ; preds = %73
  %410 = load i64, ptr %4, align 8
  %411 = ptrtoint ptr %0 to i64
  %412 = zext i32 %1 to i64
  %413 = zext i32 %2 to i64
  %414 = xor i64 %411, %413
  %415 = mul i64 %414, %410
  %416 = mul i64 %415, %412
  %417 = mul i64 %416, %410
  %418 = add i64 %417, %412
  store i64 %418, ptr %4, align 8
  br label %267

419:                                              ; preds = %123
  %420 = load i64, ptr %4, align 8
  %421 = ptrtoint ptr %0 to i64
  %422 = zext i32 %1 to i64
  %423 = zext i32 %2 to i64
  %424 = sub i64 %422, %423
  %425 = xor i64 %424, %423
  %426 = xor i64 %425, %422
  %427 = and i64 %426, %423
  store i64 %427, ptr %4, align 8
  br label %267

428:                                              ; preds = %137
  %429 = load i64, ptr %4, align 8
  %430 = ptrtoint ptr %0 to i64
  %431 = zext i32 %1 to i64
  %432 = zext i32 %2 to i64
  %433 = add i64 %429, %432
  %434 = mul i64 %433, %431
  %435 = and i64 %434, %432
  %436 = or i64 %435, %429
  %437 = sub i64 %436, %432
  store i64 %437, ptr %4, align 8
  br label %267

438:                                              ; preds = %168
  %439 = load i64, ptr %4, align 8
  %440 = ptrtoint ptr %0 to i64
  %441 = zext i32 %1 to i64
  %442 = zext i32 %2 to i64
  %443 = or i64 %441, %442
  %444 = sub i64 %443, %442
  %445 = add i64 %444, %439
  %446 = add i64 %445, %440
  %447 = sub i64 %446, %439
  store i64 %447, ptr %4, align 8
  br label %267

448:                                              ; preds = %179
  %449 = load i64, ptr %4, align 8
  %450 = ptrtoint ptr %0 to i64
  %451 = zext i32 %1 to i64
  %452 = zext i32 %2 to i64
  %453 = xor i64 %449, %451
  %454 = mul i64 %453, %449
  %455 = sub i64 %454, %452
  %456 = add i64 %455, %450
  %457 = add i64 %456, %449
  %458 = add i64 %457, %450
  store i64 %458, ptr %4, align 8
  br label %267

459:                                              ; preds = %206
  %460 = load i64, ptr %4, align 8
  %461 = ptrtoint ptr %0 to i64
  %462 = zext i32 %1 to i64
  %463 = zext i32 %2 to i64
  %464 = xor i64 %460, %460
  %465 = or i64 %464, %462
  %466 = and i64 %465, %463
  store i64 %466, ptr %4, align 8
  br label %267

467:                                              ; preds = %234
  %468 = load i64, ptr %4, align 8
  %469 = ptrtoint ptr %0 to i64
  %470 = zext i32 %1 to i64
  %471 = zext i32 %2 to i64
  %472 = sub i64 %471, %468
  %473 = sub i64 %472, %470
  %474 = sub i64 %473, %470
  store i64 %474, ptr %4, align 8
  br label %267

475:                                              ; preds = %243
  %476 = load i64, ptr %4, align 8
  %477 = ptrtoint ptr %0 to i64
  %478 = zext i32 %1 to i64
  %479 = zext i32 %2 to i64
  %480 = xor i64 %476, %476
  %481 = or i64 %480, %478
  %482 = mul i64 %481, %478
  %483 = add i64 %482, %477
  %484 = xor i64 %483, %478
  store i64 %484, ptr %4, align 8
  br label %267

485:                                              ; preds = %268
  %486 = load i64, ptr %4, align 8
  %487 = ptrtoint ptr %0 to i64
  %488 = zext i32 %1 to i64
  %489 = zext i32 %2 to i64
  %490 = or i64 %488, %486
  %491 = xor i64 %490, %489
  %492 = sub i64 %491, %489
  %493 = or i64 %492, %487
  store i64 %493, ptr %4, align 8
  br label %11

494:                                              ; preds = %287
  %495 = load i64, ptr %4, align 8
  %496 = ptrtoint ptr %0 to i64
  %497 = zext i32 %1 to i64
  %498 = zext i32 %2 to i64
  %499 = sub i64 %496, %495
  %500 = mul i64 %499, %495
  %501 = or i64 %500, %498
  %502 = or i64 %501, %498
  %503 = sub i64 %502, %497
  store i64 %503, ptr %4, align 8
  br label %267

504:                                              ; preds = %300
  %505 = load i64, ptr %4, align 8
  %506 = ptrtoint ptr %0 to i64
  %507 = zext i32 %1 to i64
  %508 = zext i32 %2 to i64
  %509 = add i64 %507, %508
  %510 = or i64 %509, %508
  %511 = sub i64 %510, %506
  %512 = mul i64 %511, %507
  store i64 %512, ptr %4, align 8
  br label %267

513:                                              ; preds = %311
  %514 = load i64, ptr %4, align 8
  %515 = ptrtoint ptr %0 to i64
  %516 = zext i32 %1 to i64
  %517 = zext i32 %2 to i64
  %518 = or i64 %515, %514
  %519 = or i64 %518, %515
  %520 = xor i64 %519, %517
  %521 = sub i64 %520, %514
  store i64 %521, ptr %4, align 8
  br label %267

522:                                              ; preds = %332
  %523 = load i64, ptr %4, align 8
  %524 = ptrtoint ptr %0 to i64
  %525 = zext i32 %1 to i64
  %526 = zext i32 %2 to i64
  %527 = mul i64 %525, %525
  %528 = add i64 %527, %526
  %529 = and i64 %528, %524
  store i64 %529, ptr %4, align 8
  br label %267

530:                                              ; preds = %344
  %531 = load i64, ptr %4, align 8
  %532 = ptrtoint ptr %0 to i64
  %533 = zext i32 %1 to i64
  %534 = zext i32 %2 to i64
  %535 = or i64 %534, %533
  %536 = or i64 %535, %533
  %537 = or i64 %536, %531
  %538 = and i64 %537, %531
  %539 = mul i64 %538, %531
  %540 = sub i64 %539, %534
  store i64 %540, ptr %4, align 8
  br label %267

541:                                              ; preds = %355
  %542 = load i64, ptr %4, align 8
  %543 = ptrtoint ptr %0 to i64
  %544 = zext i32 %1 to i64
  %545 = zext i32 %2 to i64
  %546 = and i64 %544, %542
  %547 = and i64 %546, %545
  %548 = mul i64 %547, %542
  %549 = sub i64 %548, %544
  store i64 %549, ptr %4, align 8
  br label %267

550:                                              ; preds = %366
  %551 = load i64, ptr %4, align 8
  %552 = ptrtoint ptr %0 to i64
  %553 = zext i32 %1 to i64
  %554 = zext i32 %2 to i64
  %555 = add i64 %551, %552
  %556 = xor i64 %555, %551
  %557 = mul i64 %556, %552
  %558 = sub i64 %557, %554
  store i64 %558, ptr %4, align 8
  br label %267

559:                                              ; preds = %378
  %560 = load i64, ptr %4, align 8
  %561 = ptrtoint ptr %0 to i64
  %562 = zext i32 %1 to i64
  %563 = zext i32 %2 to i64
  %564 = mul i64 %560, %563
  %565 = add i64 %564, %562
  %566 = sub i64 %565, %560
  store i64 %566, ptr %4, align 8
  br label %267
}

; Function Attrs: nounwind allocsize(1)
declare ptr @realloc(ptr noundef, i64 noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i64 @popHeap(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca %struct.Point, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 -1050043049, ptr %4, align 4
  br label %11

11:                                               ; preds = %631, %382, %381, %1
  %12 = load i32, ptr %4, align 4
  %13 = sub i32 %12, 1985637637
  %14 = mul i32 %13, 2038802829
  switch i32 %14, label %382 [
    i32 987610922, label %15
    i32 70557149, label %52
    i32 1817726718, label %87
    i32 1336938275, label %114
    i32 132533464, label %152
    i32 1903443432, label %181
    i32 1766782445, label %193
    i32 234435494, label %213
    i32 817180379, label %229
    i32 1118173620, label %256
    i32 713617209, label %285
    i32 2124165753, label %314
    i32 2110794420, label %325
    i32 2072910961, label %334
    i32 1691023752, label %347
    i32 274548295, label %349
    i32 753517133, label %393
    i32 2041383406, label %415
    i32 1681530548, label %426
    i32 1094494363, label %438
    i32 1122744044, label %451
    i32 296357360, label %471
    i32 2047010618, label %482
    i32 1713078733, label %493
  ]

15:                                               ; preds = %11
  store ptr %0, ptr %6, align 8
  %16 = load ptr, ptr %6, align 8
  %17 = getelementptr inbounds nuw %struct.MinHeap, ptr %16, i32 0, i32 0
  %18 = load ptr, ptr %17, align 8
  %19 = getelementptr inbounds %struct.Point, ptr %18, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %5, ptr align 4 %19, i64 8, i1 false)
  %20 = load ptr, ptr %6, align 8
  %21 = getelementptr inbounds nuw %struct.MinHeap, ptr %20, i32 0, i32 0
  %22 = load ptr, ptr %21, align 8
  %23 = getelementptr inbounds %struct.Point, ptr %22, i64 1
  %24 = load ptr, ptr %6, align 8
  %25 = getelementptr inbounds nuw %struct.MinHeap, ptr %24, i32 0, i32 0
  %26 = load ptr, ptr %25, align 8
  %27 = load ptr, ptr %6, align 8
  %28 = getelementptr inbounds nuw %struct.MinHeap, ptr %27, i32 0, i32 1
  %29 = load i32, ptr %28, align 8
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds %struct.Point, ptr %26, i64 %30
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %23, ptr align 4 %31, i64 8, i1 false)
  %32 = load ptr, ptr %6, align 8
  %33 = getelementptr inbounds nuw %struct.MinHeap, ptr %32, i32 0, i32 1
  %34 = load i32, ptr %33, align 8
  %35 = load i32, ptr %4, align 4
  %36 = xor i32 %35, 1050043048
  %37 = or i32 %34, %36
  %38 = load i32, ptr %4, align 4
  %39 = xor i32 %38, 1050043048
  %40 = and i32 %34, %39
  %41 = add i32 %37, %40
  store i32 %41, ptr %33, align 8
  store i32 1, ptr %7, align 4
  store i32 -1995270506, ptr %4, align 4
  %42 = xor i32 %3, -1668890687
  %43 = and i32 %3, %42
  %44 = or i32 %3, %42
  %45 = xor i32 %3, %42
  %46 = mul i32 %44, 2
  %47 = sub i32 %46, %45
  %48 = sub i32 %47, %3
  %49 = sub i32 %48, %42
  %50 = mul i32 %49, 173
  %51 = icmp slt i32 %50, 0
  br i1 %51, label %512, label %381

52:                                               ; preds = %11
  %53 = load i32, ptr %7, align 4
  %54 = load i32, ptr %4, align 4
  %55 = xor i32 %54, -1995270508
  %56 = mul nsw i32 %53, %55
  store i32 %56, ptr %8, align 4
  %57 = load i32, ptr %7, align 4
  %58 = load i32, ptr %4, align 4
  %59 = xor i32 %58, -1995270508
  %60 = mul nsw i32 %57, %59
  %61 = load i32, ptr %4, align 4
  %62 = xor i32 %61, -1995270505
  %63 = sub i32 %60, %62
  %64 = load i32, ptr %4, align 4
  %65 = xor i32 %64, -1995270508
  %66 = mul i32 %60, %65
  %67 = load i32, ptr %4, align 4
  %68 = xor i32 %67, -1995270505
  %69 = mul i32 %68, %63
  %70 = sub i32 %66, %69
  store i32 %70, ptr %9, align 4
  %71 = load i32, ptr %7, align 4
  store i32 %71, ptr %10, align 4
  %72 = load i32, ptr %8, align 4
  %73 = load ptr, ptr %6, align 8
  %74 = getelementptr inbounds nuw %struct.MinHeap, ptr %73, i32 0, i32 1
  %75 = load i32, ptr %74, align 8
  %76 = icmp sle i32 %72, %75
  %77 = select i1 %76, i32 993604987, i32 1219067587
  store i32 %77, ptr %4, align 4
  %78 = xor i32 %3, -526384525
  %79 = and i32 %3, %78
  %80 = or i32 %3, %78
  %81 = xor i32 %3, %78
  %82 = add i32 %79, %80
  %83 = sub i32 %82, %3
  %84 = sub i32 %83, %78
  %85 = mul i32 %84, 86
  %86 = icmp sle i32 %85, 0
  br i1 %86, label %381, label %520

87:                                               ; preds = %11
  %88 = load ptr, ptr %6, align 8
  %89 = getelementptr inbounds nuw %struct.MinHeap, ptr %88, i32 0, i32 0
  %90 = load ptr, ptr %89, align 8
  %91 = load i32, ptr %8, align 4
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds %struct.Point, ptr %90, i64 %92
  %94 = getelementptr inbounds nuw %struct.Point, ptr %93, i32 0, i32 1
  %95 = load i32, ptr %94, align 4
  %96 = load ptr, ptr %6, align 8
  %97 = getelementptr inbounds nuw %struct.MinHeap, ptr %96, i32 0, i32 0
  %98 = load ptr, ptr %97, align 8
  %99 = load i32, ptr %10, align 4
  %100 = sext i32 %99 to i64
  %101 = getelementptr inbounds %struct.Point, ptr %98, i64 %100
  %102 = getelementptr inbounds nuw %struct.Point, ptr %101, i32 0, i32 1
  %103 = load i32, ptr %102, align 4
  %104 = icmp slt i32 %95, %103
  %105 = select i1 %104, i32 -74775411, i32 1286726772
  store i32 %105, ptr %4, align 4
  %106 = xor i32 %3, 2121765329
  %107 = and i32 %3, %106
  %108 = or i32 %3, %106
  %109 = xor i32 %3, %106
  %110 = sub i32 %108, %109
  %111 = sub i32 %110, %107
  %112 = mul i32 %111, 254
  %113 = icmp slt i32 %112, 1
  br i1 %113, label %381, label %527

114:                                              ; preds = %11
  %115 = load ptr, ptr %6, align 8
  %116 = getelementptr inbounds nuw %struct.MinHeap, ptr %115, i32 0, i32 0
  %117 = load ptr, ptr %116, align 8
  %118 = load i32, ptr %8, align 4
  %119 = sext i32 %118 to i64
  %120 = getelementptr inbounds %struct.Point, ptr %117, i64 %119
  %121 = getelementptr inbounds nuw %struct.Point, ptr %120, i32 0, i32 1
  %122 = load i32, ptr %121, align 4
  %123 = load ptr, ptr %6, align 8
  %124 = getelementptr inbounds nuw %struct.MinHeap, ptr %123, i32 0, i32 0
  %125 = load ptr, ptr %124, align 8
  %126 = load i32, ptr %10, align 4
  %127 = sext i32 %126 to i64
  %128 = getelementptr inbounds %struct.Point, ptr %125, i64 %127
  %129 = getelementptr inbounds nuw %struct.Point, ptr %128, i32 0, i32 1
  %130 = load i32, ptr %129, align 4
  %131 = icmp eq i32 %122, %130
  %132 = select i1 %131, i32 61602621, i32 426795750
  store i32 %132, ptr %4, align 4
  %133 = xor i32 %3, -277445441
  %134 = and i32 %3, %133
  %135 = or i32 %3, %133
  %136 = xor i32 %3, %133
  %137 = add i32 %3, %133
  %138 = sub i32 %137, %136
  %139 = mul i32 %134, 2
  %140 = sub i32 %138, %139
  %141 = mul i32 %140, 186
  %142 = xor i32 %3, -1049870667
  %143 = and i32 %3, %142
  %144 = or i32 %3, %142
  %145 = xor i32 %3, %142
  %146 = mul i32 %144, 2
  %147 = sub i32 %146, %145
  %148 = sub i32 %147, %3
  %149 = sub i32 %148, %142
  %150 = mul i32 %149, 52
  %151 = icmp eq i32 %141, %150
  br i1 %151, label %381, label %534

152:                                              ; preds = %11
  %153 = load ptr, ptr %6, align 8
  %154 = getelementptr inbounds nuw %struct.MinHeap, ptr %153, i32 0, i32 0
  %155 = load ptr, ptr %154, align 8
  %156 = load i32, ptr %8, align 4
  %157 = sext i32 %156 to i64
  %158 = getelementptr inbounds %struct.Point, ptr %155, i64 %157
  %159 = getelementptr inbounds nuw %struct.Point, ptr %158, i32 0, i32 0
  %160 = load i32, ptr %159, align 4
  %161 = load ptr, ptr %6, align 8
  %162 = getelementptr inbounds nuw %struct.MinHeap, ptr %161, i32 0, i32 0
  %163 = load ptr, ptr %162, align 8
  %164 = load i32, ptr %10, align 4
  %165 = sext i32 %164 to i64
  %166 = getelementptr inbounds %struct.Point, ptr %163, i64 %165
  %167 = getelementptr inbounds nuw %struct.Point, ptr %166, i32 0, i32 0
  %168 = load i32, ptr %167, align 4
  %169 = icmp slt i32 %160, %168
  %170 = select i1 %169, i32 -74775411, i32 426795750
  store i32 %170, ptr %4, align 4
  %171 = xor i32 %3, -1486238543
  %172 = and i32 %3, %171
  %173 = or i32 %3, %171
  %174 = xor i32 %3, %171
  %175 = add i32 %3, %171
  %176 = sub i32 %175, %174
  %177 = mul i32 %172, 2
  %178 = sub i32 %176, %177
  %179 = mul i32 %178, 29
  %180 = icmp slt i32 %179, 1
  br i1 %180, label %381, label %543

181:                                              ; preds = %11
  %182 = load i32, ptr %8, align 4
  store i32 %182, ptr %10, align 4
  store i32 426795750, ptr %4, align 4
  %183 = xor i32 %3, 332898821
  %184 = and i32 %3, %183
  %185 = or i32 %3, %183
  %186 = xor i32 %3, %183
  %187 = add i32 %3, %183
  %188 = sub i32 %187, %186
  %189 = mul i32 %184, 2
  %190 = sub i32 %188, %189
  %191 = mul i32 %190, 147
  %192 = icmp sle i32 %191, 0
  br i1 %192, label %381, label %552

193:                                              ; preds = %11
  store i32 1219067587, ptr %4, align 4
  %194 = xor i32 %3, -584902647
  %195 = and i32 %3, %194
  %196 = or i32 %3, %194
  %197 = xor i32 %3, %194
  %198 = add i32 %3, %194
  %199 = sub i32 %198, %197
  %200 = mul i32 %195, 2
  %201 = sub i32 %199, %200
  %202 = mul i32 %201, 151
  %203 = xor i32 %3, 1699094235
  %204 = and i32 %3, %203
  %205 = or i32 %3, %203
  %206 = xor i32 %3, %203
  %207 = mul i32 %205, 2
  %208 = sub i32 %207, %206
  %209 = sub i32 %208, %3
  %210 = sub i32 %209, %203
  %211 = mul i32 %210, 192
  %212 = icmp ne i32 %202, %211
  br i1 %212, label %560, label %381

213:                                              ; preds = %11
  %214 = load i32, ptr %9, align 4
  %215 = load ptr, ptr %6, align 8
  %216 = getelementptr inbounds nuw %struct.MinHeap, ptr %215, i32 0, i32 1
  %217 = load i32, ptr %216, align 8
  %218 = icmp sle i32 %214, %217
  %219 = select i1 %218, i32 1854744844, i32 1014450298
  store i32 %219, ptr %4, align 4
  %220 = xor i32 %3, 2075317435
  %221 = and i32 %3, %220
  %222 = or i32 %3, %220
  %223 = xor i32 %3, %220
  %224 = add i32 %221, %222
  %225 = sub i32 %224, %3
  %226 = sub i32 %225, %220
  %227 = mul i32 %226, 58
  %228 = icmp eq i32 %227, 0
  br i1 %228, label %381, label %569

229:                                              ; preds = %11
  %230 = load ptr, ptr %6, align 8
  %231 = getelementptr inbounds nuw %struct.MinHeap, ptr %230, i32 0, i32 0
  %232 = load ptr, ptr %231, align 8
  %233 = load i32, ptr %9, align 4
  %234 = sext i32 %233 to i64
  %235 = getelementptr inbounds %struct.Point, ptr %232, i64 %234
  %236 = getelementptr inbounds nuw %struct.Point, ptr %235, i32 0, i32 1
  %237 = load i32, ptr %236, align 4
  %238 = load ptr, ptr %6, align 8
  %239 = getelementptr inbounds nuw %struct.MinHeap, ptr %238, i32 0, i32 0
  %240 = load ptr, ptr %239, align 8
  %241 = load i32, ptr %10, align 4
  %242 = sext i32 %241 to i64
  %243 = getelementptr inbounds %struct.Point, ptr %240, i64 %242
  %244 = getelementptr inbounds nuw %struct.Point, ptr %243, i32 0, i32 1
  %245 = load i32, ptr %244, align 4
  %246 = icmp slt i32 %237, %245
  %247 = select i1 %246, i32 -1815134046, i32 -1343263095
  store i32 %247, ptr %4, align 4
  %248 = xor i32 %3, 1734960165
  %249 = and i32 %3, %248
  %250 = or i32 %3, %248
  %251 = xor i32 %3, %248
  %252 = sub i32 %250, %251
  %253 = sub i32 %252, %249
  %254 = mul i32 %253, 109
  %255 = icmp eq i32 %254, 0
  br i1 %255, label %381, label %578

256:                                              ; preds = %11
  %257 = load ptr, ptr %6, align 8
  %258 = getelementptr inbounds nuw %struct.MinHeap, ptr %257, i32 0, i32 0
  %259 = load ptr, ptr %258, align 8
  %260 = load i32, ptr %9, align 4
  %261 = sext i32 %260 to i64
  %262 = getelementptr inbounds %struct.Point, ptr %259, i64 %261
  %263 = getelementptr inbounds nuw %struct.Point, ptr %262, i32 0, i32 1
  %264 = load i32, ptr %263, align 4
  %265 = load ptr, ptr %6, align 8
  %266 = getelementptr inbounds nuw %struct.MinHeap, ptr %265, i32 0, i32 0
  %267 = load ptr, ptr %266, align 8
  %268 = load i32, ptr %10, align 4
  %269 = sext i32 %268 to i64
  %270 = getelementptr inbounds %struct.Point, ptr %267, i64 %269
  %271 = getelementptr inbounds nuw %struct.Point, ptr %270, i32 0, i32 1
  %272 = load i32, ptr %271, align 4
  %273 = icmp eq i32 %264, %272
  %274 = select i1 %273, i32 -1687494558, i32 1329570697
  store i32 %274, ptr %4, align 4
  %275 = xor i32 %3, 2073870617
  %276 = and i32 %3, %275
  %277 = or i32 %3, %275
  %278 = xor i32 %3, %275
  %279 = mul i32 %277, 2
  %280 = sub i32 %279, %278
  %281 = sub i32 %280, %3
  %282 = sub i32 %281, %275
  %283 = mul i32 %282, 67
  %284 = icmp uge i32 %283, 0
  br i1 %284, label %381, label %586

285:                                              ; preds = %11
  %286 = load ptr, ptr %6, align 8
  %287 = getelementptr inbounds nuw %struct.MinHeap, ptr %286, i32 0, i32 0
  %288 = load ptr, ptr %287, align 8
  %289 = load i32, ptr %9, align 4
  %290 = sext i32 %289 to i64
  %291 = getelementptr inbounds %struct.Point, ptr %288, i64 %290
  %292 = getelementptr inbounds nuw %struct.Point, ptr %291, i32 0, i32 0
  %293 = load i32, ptr %292, align 4
  %294 = load ptr, ptr %6, align 8
  %295 = getelementptr inbounds nuw %struct.MinHeap, ptr %294, i32 0, i32 0
  %296 = load ptr, ptr %295, align 8
  %297 = load i32, ptr %10, align 4
  %298 = sext i32 %297 to i64
  %299 = getelementptr inbounds %struct.Point, ptr %296, i64 %298
  %300 = getelementptr inbounds nuw %struct.Point, ptr %299, i32 0, i32 0
  %301 = load i32, ptr %300, align 4
  %302 = icmp slt i32 %293, %301
  %303 = select i1 %302, i32 -1815134046, i32 1329570697
  store i32 %303, ptr %4, align 4
  %304 = xor i32 %3, -1012976433
  %305 = and i32 %3, %304
  %306 = or i32 %3, %304
  %307 = xor i32 %3, %304
  %308 = mul i32 %306, 2
  %309 = sub i32 %308, %307
  %310 = sub i32 %309, %3
  %311 = sub i32 %310, %304
  %312 = mul i32 %311, 116
  %313 = icmp slt i32 %312, 0
  br i1 %313, label %594, label %381

314:                                              ; preds = %11
  %315 = load i32, ptr %9, align 4
  store i32 %315, ptr %10, align 4
  store i32 1329570697, ptr %4, align 4
  %316 = xor i32 %3, -93053997
  %317 = and i32 %3, %316
  %318 = or i32 %3, %316
  %319 = xor i32 %3, %316
  %320 = add i32 %317, %318
  %321 = sub i32 %320, %3
  %322 = sub i32 %321, %316
  %323 = mul i32 %322, 43
  %324 = icmp slt i32 %323, 0
  br i1 %324, label %601, label %381

325:                                              ; preds = %11
  store i32 1014450298, ptr %4, align 4
  %326 = xor i32 %3, 1596078371
  %327 = and i32 %3, %326
  %328 = or i32 %3, %326
  %329 = xor i32 %3, %326
  %330 = sub i32 %328, %329
  %331 = sub i32 %330, %327
  %332 = mul i32 %331, 120
  %333 = icmp sgt i32 %332, 0
  br i1 %333, label %610, label %381

334:                                              ; preds = %11
  %335 = load i32, ptr %10, align 4
  %336 = load i32, ptr %7, align 4
  %337 = icmp eq i32 %335, %336
  %338 = select i1 %337, i32 -1507903827, i32 -1263803096
  store i32 %338, ptr %4, align 4
  %339 = xor i32 %3, 2147060427
  %340 = and i32 %3, %339
  %341 = or i32 %3, %339
  %342 = xor i32 %3, %339
  %343 = sub i32 %341, %342
  %344 = sub i32 %343, %340
  %345 = mul i32 %344, 37
  %346 = icmp sgt i32 %345, 0
  br i1 %346, label %617, label %381

347:                                              ; preds = %11
  %348 = load i64, ptr %5, align 4
  ret i64 %348

349:                                              ; preds = %11
  %350 = load ptr, ptr %6, align 8
  %351 = getelementptr inbounds nuw %struct.MinHeap, ptr %350, i32 0, i32 0
  %352 = load ptr, ptr %351, align 8
  %353 = load i32, ptr %7, align 4
  %354 = sext i32 %353 to i64
  %355 = getelementptr inbounds %struct.Point, ptr %352, i64 %354
  %356 = load ptr, ptr %6, align 8
  %357 = getelementptr inbounds nuw %struct.MinHeap, ptr %356, i32 0, i32 0
  %358 = load ptr, ptr %357, align 8
  %359 = load i32, ptr %10, align 4
  %360 = sext i32 %359 to i64
  %361 = getelementptr inbounds %struct.Point, ptr %358, i64 %360
  call void @swapNode(ptr noundef %355, ptr noundef %361)
  %362 = load i32, ptr %10, align 4
  store i32 %362, ptr %7, align 4
  store i32 -1995270506, ptr %4, align 4
  %363 = xor i32 %3, 243207239
  %364 = and i32 %3, %363
  %365 = or i32 %3, %363
  %366 = xor i32 %3, %363
  %367 = add i32 %3, %363
  %368 = sub i32 %367, %366
  %369 = mul i32 %364, 2
  %370 = sub i32 %368, %369
  %371 = mul i32 %370, 125
  %372 = xor i32 %3, 2123868615
  %373 = and i32 %3, %372
  %374 = or i32 %3, %372
  %375 = xor i32 %3, %372
  %376 = add i32 %373, %374
  %377 = sub i32 %376, %3
  %378 = sub i32 %377, %372
  %379 = mul i32 %378, 80
  %380 = icmp ne i32 %371, %379
  br i1 %380, label %623, label %381

381:                                              ; preds = %690, %682, %676, %668, %659, %652, %646, %638, %623, %617, %610, %601, %594, %586, %578, %569, %560, %552, %543, %534, %527, %520, %512, %493, %482, %471, %451, %438, %426, %415, %393, %349, %334, %325, %314, %285, %256, %229, %213, %193, %181, %152, %114, %87, %52, %15
  br label %11

382:                                              ; preds = %11
  store i32 -1050043049, ptr %4, align 4
  call void asm sideeffect "", ""()
  %383 = xor i32 %3, -1523771369
  %384 = and i32 %3, %383
  %385 = or i32 %3, %383
  %386 = xor i32 %3, %383
  %387 = add i32 %3, %383
  %388 = sub i32 %387, %386
  %389 = mul i32 %384, 2
  %390 = sub i32 %388, %389
  %391 = mul i32 %390, 217
  %392 = icmp uge i32 %391, 0
  br i1 %392, label %11, label %631

393:                                              ; preds = %11
  %394 = load i32, ptr %4, align 4
  %395 = xor i32 %394, -1342647091
  store i32 %395, ptr %4, align 4
  %396 = xor i32 %3, 1315344849
  %397 = and i32 %3, %396
  %398 = or i32 %3, %396
  %399 = xor i32 %3, %396
  %400 = mul i32 %398, 2
  %401 = sub i32 %400, %399
  %402 = sub i32 %401, %3
  %403 = sub i32 %402, %396
  %404 = mul i32 %403, 96
  %405 = xor i32 %3, -1295458669
  %406 = and i32 %3, %405
  %407 = or i32 %3, %405
  %408 = xor i32 %3, %405
  %409 = mul i32 %407, 2
  %410 = sub i32 %409, %408
  %411 = sub i32 %410, %3
  %412 = sub i32 %411, %405
  %413 = mul i32 %412, 230
  %414 = icmp ne i32 %404, %413
  br i1 %414, label %638, label %381

415:                                              ; preds = %11
  %416 = load i32, ptr %4, align 4
  %417 = xor i32 %416, -558975359
  store i32 %417, ptr %4, align 4
  %418 = xor i32 %3, -483282897
  %419 = and i32 %3, %418
  %420 = or i32 %3, %418
  %421 = xor i32 %3, %418
  %422 = sub i32 %420, %421
  %423 = sub i32 %422, %419
  %424 = mul i32 %423, 133
  %425 = icmp slt i32 %424, 1
  br i1 %425, label %381, label %646

426:                                              ; preds = %11
  %427 = load i32, ptr %4, align 4
  %428 = xor i32 %427, 1478031337
  store i32 %428, ptr %4, align 4
  %429 = xor i32 %3, -1965856225
  %430 = and i32 %3, %429
  %431 = or i32 %3, %429
  %432 = xor i32 %3, %429
  %433 = add i32 %430, %431
  %434 = sub i32 %433, %3
  %435 = sub i32 %434, %429
  %436 = mul i32 %435, 192
  %437 = icmp eq i32 %436, 0
  br i1 %437, label %381, label %652

438:                                              ; preds = %11
  %439 = load i32, ptr %4, align 4
  %440 = xor i32 %439, 372935208
  store i32 %440, ptr %4, align 4
  %441 = xor i32 %3, -1750214307
  %442 = and i32 %3, %441
  %443 = or i32 %3, %441
  %444 = xor i32 %3, %441
  %445 = add i32 %3, %441
  %446 = sub i32 %445, %444
  %447 = mul i32 %442, 2
  %448 = sub i32 %446, %447
  %449 = mul i32 %448, 35
  %450 = icmp slt i32 %449, 1
  br i1 %450, label %381, label %659

451:                                              ; preds = %11
  %452 = load i32, ptr %4, align 4
  %453 = xor i32 %452, -498978294
  store i32 %453, ptr %4, align 4
  %454 = xor i32 %3, 2098935285
  %455 = and i32 %3, %454
  %456 = or i32 %3, %454
  %457 = xor i32 %3, %454
  %458 = mul i32 %456, 2
  %459 = sub i32 %458, %457
  %460 = sub i32 %459, %3
  %461 = sub i32 %460, %454
  %462 = mul i32 %461, 149
  %463 = xor i32 %3, -1695504337
  %464 = and i32 %3, %463
  %465 = or i32 %3, %463
  %466 = xor i32 %3, %463
  %467 = sub i32 %465, %466
  %468 = sub i32 %467, %464
  %469 = mul i32 %468, 245
  %470 = icmp ne i32 %462, %469
  br i1 %470, label %668, label %381

471:                                              ; preds = %11
  %472 = load i32, ptr %4, align 4
  %473 = xor i32 %472, 728479392
  store i32 %473, ptr %4, align 4
  %474 = xor i32 %3, 1394325731
  %475 = and i32 %3, %474
  %476 = or i32 %3, %474
  %477 = xor i32 %3, %474
  %478 = sub i32 %476, %477
  %479 = sub i32 %478, %475
  %480 = mul i32 %479, 2
  %481 = icmp eq i32 %480, 0
  br i1 %481, label %381, label %676

482:                                              ; preds = %11
  %483 = load i32, ptr %4, align 4
  %484 = xor i32 %483, -321035538
  store i32 %484, ptr %4, align 4
  %485 = xor i32 %3, -26360393
  %486 = and i32 %3, %485
  %487 = or i32 %3, %485
  %488 = xor i32 %3, %485
  %489 = sub i32 %487, %488
  %490 = sub i32 %489, %486
  %491 = mul i32 %490, 72
  %492 = icmp slt i32 %491, 0
  br i1 %492, label %682, label %381

493:                                              ; preds = %11
  %494 = load i32, ptr %4, align 4
  %495 = xor i32 %494, -1689444887
  store i32 %495, ptr %4, align 4
  %496 = xor i32 %3, -882475107
  %497 = and i32 %3, %496
  %498 = or i32 %3, %496
  %499 = xor i32 %3, %496
  %500 = add i32 %497, %498
  %501 = sub i32 %500, %3
  %502 = sub i32 %501, %496
  %503 = mul i32 %502, 70
  %504 = xor i32 %3, -828647805
  %505 = and i32 %3, %504
  %506 = or i32 %3, %504
  %507 = xor i32 %3, %504
  %508 = sub i32 %506, %507
  %509 = sub i32 %508, %505
  %510 = mul i32 %509, 207
  %511 = icmp ne i32 %503, %510
  br i1 %511, label %690, label %381

512:                                              ; preds = %15
  %513 = load i64, ptr %2, align 8
  %514 = ptrtoint ptr %0 to i64
  %515 = add i64 %513, %514
  %516 = mul i64 %515, %514
  %517 = sub i64 %516, %514
  %518 = add i64 %517, %513
  %519 = or i64 %518, %514
  store i64 %519, ptr %2, align 8
  br label %381

520:                                              ; preds = %52
  %521 = load i64, ptr %2, align 8
  %522 = ptrtoint ptr %0 to i64
  %523 = and i64 %522, %521
  %524 = sub i64 %523, %522
  %525 = xor i64 %524, %521
  %526 = xor i64 %525, %521
  store i64 %526, ptr %2, align 8
  br label %381

527:                                              ; preds = %87
  %528 = load i64, ptr %2, align 8
  %529 = ptrtoint ptr %0 to i64
  %530 = mul i64 %528, %529
  %531 = add i64 %530, %529
  %532 = add i64 %531, %529
  %533 = sub i64 %532, %529
  store i64 %533, ptr %2, align 8
  br label %381

534:                                              ; preds = %114
  %535 = load i64, ptr %2, align 8
  %536 = ptrtoint ptr %0 to i64
  %537 = add i64 %535, %536
  %538 = mul i64 %537, %535
  %539 = or i64 %538, %536
  %540 = add i64 %539, %536
  %541 = xor i64 %540, %535
  %542 = and i64 %541, %535
  store i64 %542, ptr %2, align 8
  br label %381

543:                                              ; preds = %152
  %544 = load i64, ptr %2, align 8
  %545 = ptrtoint ptr %0 to i64
  %546 = add i64 %545, %545
  %547 = or i64 %546, %545
  %548 = mul i64 %547, %544
  %549 = and i64 %548, %545
  %550 = xor i64 %549, %545
  %551 = add i64 %550, %544
  store i64 %551, ptr %2, align 8
  br label %381

552:                                              ; preds = %181
  %553 = load i64, ptr %2, align 8
  %554 = ptrtoint ptr %0 to i64
  %555 = add i64 %554, %553
  %556 = or i64 %555, %554
  %557 = mul i64 %556, %554
  %558 = xor i64 %557, %553
  %559 = add i64 %558, %554
  store i64 %559, ptr %2, align 8
  br label %381

560:                                              ; preds = %193
  %561 = load i64, ptr %2, align 8
  %562 = ptrtoint ptr %0 to i64
  %563 = add i64 %562, %561
  %564 = or i64 %563, %562
  %565 = add i64 %564, %562
  %566 = sub i64 %565, %561
  %567 = mul i64 %566, %561
  %568 = or i64 %567, %562
  store i64 %568, ptr %2, align 8
  br label %381

569:                                              ; preds = %213
  %570 = load i64, ptr %2, align 8
  %571 = ptrtoint ptr %0 to i64
  %572 = add i64 %571, %571
  %573 = mul i64 %572, %571
  %574 = add i64 %573, %570
  %575 = mul i64 %574, %570
  %576 = xor i64 %575, %571
  %577 = or i64 %576, %571
  store i64 %577, ptr %2, align 8
  br label %381

578:                                              ; preds = %229
  %579 = load i64, ptr %2, align 8
  %580 = ptrtoint ptr %0 to i64
  %581 = and i64 %580, %580
  %582 = and i64 %581, %579
  %583 = mul i64 %582, %579
  %584 = sub i64 %583, %580
  %585 = and i64 %584, %580
  store i64 %585, ptr %2, align 8
  br label %381

586:                                              ; preds = %256
  %587 = load i64, ptr %2, align 8
  %588 = ptrtoint ptr %0 to i64
  %589 = mul i64 %588, %587
  %590 = sub i64 %589, %588
  %591 = sub i64 %590, %588
  %592 = mul i64 %591, %588
  %593 = and i64 %592, %587
  store i64 %593, ptr %2, align 8
  br label %381

594:                                              ; preds = %285
  %595 = load i64, ptr %2, align 8
  %596 = ptrtoint ptr %0 to i64
  %597 = add i64 %595, %595
  %598 = add i64 %597, %596
  %599 = or i64 %598, %596
  %600 = xor i64 %599, %596
  store i64 %600, ptr %2, align 8
  br label %381

601:                                              ; preds = %314
  %602 = load i64, ptr %2, align 8
  %603 = ptrtoint ptr %0 to i64
  %604 = xor i64 %603, %602
  %605 = mul i64 %604, %602
  %606 = or i64 %605, %602
  %607 = xor i64 %606, %603
  %608 = or i64 %607, %602
  %609 = or i64 %608, %603
  store i64 %609, ptr %2, align 8
  br label %381

610:                                              ; preds = %325
  %611 = load i64, ptr %2, align 8
  %612 = ptrtoint ptr %0 to i64
  %613 = or i64 %612, %612
  %614 = sub i64 %613, %611
  %615 = or i64 %614, %611
  %616 = add i64 %615, %612
  store i64 %616, ptr %2, align 8
  br label %381

617:                                              ; preds = %334
  %618 = load i64, ptr %2, align 8
  %619 = ptrtoint ptr %0 to i64
  %620 = add i64 %618, %619
  %621 = add i64 %620, %618
  %622 = add i64 %621, %618
  store i64 %622, ptr %2, align 8
  br label %381

623:                                              ; preds = %349
  %624 = load i64, ptr %2, align 8
  %625 = ptrtoint ptr %0 to i64
  %626 = and i64 %624, %624
  %627 = or i64 %626, %625
  %628 = add i64 %627, %624
  %629 = or i64 %628, %624
  %630 = xor i64 %629, %624
  store i64 %630, ptr %2, align 8
  br label %381

631:                                              ; preds = %382
  %632 = load i64, ptr %2, align 8
  %633 = ptrtoint ptr %0 to i64
  %634 = xor i64 %632, %632
  %635 = and i64 %634, %632
  %636 = and i64 %635, %632
  %637 = xor i64 %636, %632
  store i64 %637, ptr %2, align 8
  br label %11

638:                                              ; preds = %393
  %639 = load i64, ptr %2, align 8
  %640 = ptrtoint ptr %0 to i64
  %641 = sub i64 %639, %639
  %642 = mul i64 %641, %640
  %643 = add i64 %642, %640
  %644 = mul i64 %643, %640
  %645 = and i64 %644, %639
  store i64 %645, ptr %2, align 8
  br label %381

646:                                              ; preds = %415
  %647 = load i64, ptr %2, align 8
  %648 = ptrtoint ptr %0 to i64
  %649 = mul i64 %648, %647
  %650 = sub i64 %649, %648
  %651 = add i64 %650, %647
  store i64 %651, ptr %2, align 8
  br label %381

652:                                              ; preds = %426
  %653 = load i64, ptr %2, align 8
  %654 = ptrtoint ptr %0 to i64
  %655 = sub i64 %653, %653
  %656 = mul i64 %655, %653
  %657 = add i64 %656, %653
  %658 = sub i64 %657, %654
  store i64 %658, ptr %2, align 8
  br label %381

659:                                              ; preds = %438
  %660 = load i64, ptr %2, align 8
  %661 = ptrtoint ptr %0 to i64
  %662 = mul i64 %661, %660
  %663 = add i64 %662, %661
  %664 = mul i64 %663, %660
  %665 = or i64 %664, %661
  %666 = mul i64 %665, %661
  %667 = sub i64 %666, %661
  store i64 %667, ptr %2, align 8
  br label %381

668:                                              ; preds = %451
  %669 = load i64, ptr %2, align 8
  %670 = ptrtoint ptr %0 to i64
  %671 = or i64 %670, %670
  %672 = mul i64 %671, %670
  %673 = and i64 %672, %669
  %674 = mul i64 %673, %670
  %675 = or i64 %674, %669
  store i64 %675, ptr %2, align 8
  br label %381

676:                                              ; preds = %471
  %677 = load i64, ptr %2, align 8
  %678 = ptrtoint ptr %0 to i64
  %679 = sub i64 %678, %678
  %680 = add i64 %679, %678
  %681 = xor i64 %680, %677
  store i64 %681, ptr %2, align 8
  br label %381

682:                                              ; preds = %482
  %683 = load i64, ptr %2, align 8
  %684 = ptrtoint ptr %0 to i64
  %685 = add i64 %683, %684
  %686 = add i64 %685, %683
  %687 = mul i64 %686, %684
  %688 = sub i64 %687, %683
  %689 = mul i64 %688, %683
  store i64 %689, ptr %2, align 8
  br label %381

690:                                              ; preds = %493
  %691 = load i64, ptr %2, align 8
  %692 = ptrtoint ptr %0 to i64
  %693 = xor i64 %691, %692
  %694 = or i64 %693, %691
  %695 = sub i64 %694, %691
  store i64 %695, ptr %2, align 8
  br label %381
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @emptyHeap(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.MinHeap, ptr %3, i32 0, i32 1
  %5 = load i32, ptr %4, align 8
  %6 = icmp eq i32 %5, 0
  %7 = zext i1 %6 to i32
  ret i32 %7
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @freeHeap(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.MinHeap, ptr %3, i32 0, i32 0
  %5 = load ptr, ptr %4, align 8
  call void @free(ptr noundef %5) #8
  %6 = load ptr, ptr %2, align 8
  call void @free(ptr noundef %6) #8
  ret void
}

; Function Attrs: nounwind
declare void @free(ptr noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @allocateGrid() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @0, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 -744668479, ptr %3, align 4
  br label %5

5:                                                ; preds = %199, %86, %85, %0
  %6 = load i32, ptr %3, align 4
  %7 = sub i32 %6, 1879617928
  %8 = mul i32 %7, 1712717073
  %9 = icmp slt i32 %8, 269482441
  br i1 %9, label %162, label %164

10:                                               ; preds = %174
  %11 = load i32, ptr @N, align 4
  %12 = sext i32 %11 to i64
  %13 = mul i64 8, %12
  %14 = call noalias ptr @malloc(i64 noundef %13) #6
  store ptr %14, ptr @grid, align 8
  store i32 0, ptr %4, align 4
  store i32 2126230917, ptr %3, align 4
  %15 = xor i32 %2, 222700053
  %16 = and i32 %2, %15
  %17 = or i32 %2, %15
  %18 = xor i32 %2, %15
  %19 = add i32 %2, %15
  %20 = sub i32 %19, %18
  %21 = mul i32 %16, 2
  %22 = sub i32 %20, %21
  %23 = mul i32 %22, 126
  %24 = icmp slt i32 %23, 0
  br i1 %24, label %182, label %85

25:                                               ; preds = %170
  %26 = load i32, ptr %4, align 4
  %27 = load i32, ptr @N, align 4
  %28 = icmp slt i32 %26, %27
  %29 = select i1 %28, i32 -662285573, i32 -1349608805
  store i32 %29, ptr %3, align 4
  %30 = xor i32 %2, 459253481
  %31 = and i32 %2, %30
  %32 = or i32 %2, %30
  %33 = xor i32 %2, %30
  %34 = mul i32 %32, 2
  %35 = sub i32 %34, %33
  %36 = sub i32 %35, %2
  %37 = sub i32 %36, %30
  %38 = mul i32 %37, 127
  %39 = icmp sle i32 %38, 0
  br i1 %39, label %85, label %187

40:                                               ; preds = %178
  %41 = load i32, ptr @N, align 4
  %42 = load i32, ptr %3, align 4
  %43 = xor i32 %42, -662285574
  %44 = xor i32 %41, %43
  %45 = load i32, ptr %3, align 4
  %46 = xor i32 %45, -662285574
  %47 = and i32 %41, %46
  %48 = add i32 %47, %47
  %49 = add i32 %44, %48
  %50 = sext i32 %49 to i64
  %51 = mul i64 1, %50
  %52 = call noalias ptr @malloc(i64 noundef %51) #6
  %53 = load ptr, ptr @grid, align 8
  %54 = load i32, ptr %4, align 4
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds ptr, ptr %53, i64 %55
  store ptr %52, ptr %56, align 8
  %57 = load ptr, ptr @grid, align 8
  %58 = load i32, ptr %4, align 4
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds ptr, ptr %57, i64 %59
  %61 = load ptr, ptr %60, align 8
  %62 = load i32, ptr @N, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds i8, ptr %61, i64 %63
  store i8 0, ptr %64, align 1
  %65 = load i32, ptr %4, align 4
  %66 = load i32, ptr %3, align 4
  %67 = xor i32 %66, -662285574
  %68 = xor i32 %65, %67
  %69 = load i32, ptr %3, align 4
  %70 = xor i32 %69, -662285574
  %71 = and i32 %65, %70
  %72 = add i32 %71, %71
  %73 = add i32 %68, %72
  store i32 %73, ptr %4, align 4
  store i32 2126230917, ptr %3, align 4
  %74 = xor i32 %2, 415980527
  %75 = and i32 %2, %74
  %76 = or i32 %2, %74
  %77 = xor i32 %2, %74
  %78 = mul i32 %76, 2
  %79 = sub i32 %78, %77
  %80 = sub i32 %79, %2
  %81 = sub i32 %80, %74
  %82 = mul i32 %81, 54
  %83 = icmp sgt i32 %82, 0
  br i1 %83, label %193, label %85

84:                                               ; preds = %176
  ret void

85:                                               ; preds = %224, %219, %213, %206, %193, %187, %182, %150, %137, %117, %97, %40, %25, %10
  br label %5

86:                                               ; preds = %180, %178, %172, %170
  store i32 -744668479, ptr %3, align 4
  call void asm sideeffect "", ""()
  %87 = xor i32 %2, -1587232343
  %88 = and i32 %2, %87
  %89 = or i32 %2, %87
  %90 = xor i32 %2, %87
  %91 = add i32 %2, %87
  %92 = sub i32 %91, %90
  %93 = mul i32 %88, 2
  %94 = sub i32 %92, %93
  %95 = mul i32 %94, 80
  %96 = icmp ugt i32 %95, 0
  br i1 %96, label %199, label %5

97:                                               ; preds = %172
  %98 = load i32, ptr %3, align 4
  %99 = xor i32 %98, -1217944472
  store i32 %99, ptr %3, align 4
  %100 = xor i32 %2, -866832137
  %101 = and i32 %2, %100
  %102 = or i32 %2, %100
  %103 = xor i32 %2, %100
  %104 = sub i32 %102, %103
  %105 = sub i32 %104, %101
  %106 = mul i32 %105, 141
  %107 = xor i32 %2, -1097156029
  %108 = and i32 %2, %107
  %109 = or i32 %2, %107
  %110 = xor i32 %2, %107
  %111 = mul i32 %109, 2
  %112 = sub i32 %111, %110
  %113 = sub i32 %112, %2
  %114 = sub i32 %113, %107
  %115 = mul i32 %114, 4
  %116 = icmp eq i32 %106, %115
  br i1 %116, label %85, label %206

117:                                              ; preds = %180
  %118 = load i32, ptr %3, align 4
  %119 = xor i32 %118, -2121761467
  store i32 %119, ptr %3, align 4
  %120 = xor i32 %2, 841233655
  %121 = and i32 %2, %120
  %122 = or i32 %2, %120
  %123 = xor i32 %2, %120
  %124 = sub i32 %122, %123
  %125 = sub i32 %124, %121
  %126 = mul i32 %125, 184
  %127 = xor i32 %2, 1270725593
  %128 = and i32 %2, %127
  %129 = or i32 %2, %127
  %130 = xor i32 %2, %127
  %131 = add i32 %2, %127
  %132 = sub i32 %131, %130
  %133 = mul i32 %128, 2
  %134 = sub i32 %132, %133
  %135 = mul i32 %134, 92
  %136 = icmp eq i32 %126, %135
  br i1 %136, label %85, label %213

137:                                              ; preds = %168
  %138 = load i32, ptr %3, align 4
  %139 = xor i32 %138, 1552136036
  store i32 %139, ptr %3, align 4
  %140 = xor i32 %2, -682825457
  %141 = and i32 %2, %140
  %142 = or i32 %2, %140
  %143 = xor i32 %2, %140
  %144 = mul i32 %142, 2
  %145 = sub i32 %144, %143
  %146 = sub i32 %145, %2
  %147 = sub i32 %146, %140
  %148 = mul i32 %147, 245
  %149 = icmp slt i32 %148, 0
  br i1 %149, label %219, label %85

150:                                              ; preds = %166
  %151 = load i32, ptr %3, align 4
  %152 = xor i32 %151, 1376289818
  store i32 %152, ptr %3, align 4
  %153 = xor i32 %2, -935118593
  %154 = and i32 %2, %153
  %155 = or i32 %2, %153
  %156 = xor i32 %2, %153
  %157 = add i32 %154, %155
  %158 = sub i32 %157, %2
  %159 = sub i32 %158, %153
  %160 = mul i32 %159, 213
  %161 = icmp slt i32 %160, 0
  br i1 %161, label %224, label %85

162:                                              ; preds = %5
  %163 = icmp slt i32 %8, 215166478
  br i1 %163, label %166, label %168

164:                                              ; preds = %5
  %165 = icmp slt i32 %8, 1070285123
  br i1 %165, label %174, label %176

166:                                              ; preds = %162
  %167 = icmp eq i32 %8, 61453849
  br i1 %167, label %150, label %170

168:                                              ; preds = %162
  %169 = icmp eq i32 %8, 215166478
  br i1 %169, label %137, label %172

170:                                              ; preds = %166
  %171 = icmp eq i32 %8, 110447821
  br i1 %171, label %25, label %86

172:                                              ; preds = %168
  %173 = icmp eq i32 %8, 242871345
  br i1 %173, label %97, label %86

174:                                              ; preds = %164
  %175 = icmp eq i32 %8, 269482441
  br i1 %175, label %10, label %178

176:                                              ; preds = %164
  %177 = icmp eq i32 %8, 1070285123
  br i1 %177, label %84, label %180

178:                                              ; preds = %174
  %179 = icmp eq i32 %8, 693460899
  br i1 %179, label %40, label %86

180:                                              ; preds = %176
  %181 = icmp eq i32 %8, 1196952727
  br i1 %181, label %117, label %86

182:                                              ; preds = %10
  %183 = load i64, ptr %1, align 8
  %184 = sub i64 -290967490, %183
  %185 = or i64 %184, 3795389494
  %186 = and i64 %185, 3795389494
  store i64 %186, ptr %1, align 8
  br label %85

187:                                              ; preds = %25
  %188 = load i64, ptr %1, align 8
  %189 = or i64 4097882224, %188
  %190 = sub i64 %189, 1388679782
  %191 = and i64 %190, %188
  %192 = or i64 %191, 4097882224
  store i64 %192, ptr %1, align 8
  br label %85

193:                                              ; preds = %40
  %194 = load i64, ptr %1, align 8
  %195 = xor i64 %194, 433342517
  %196 = and i64 %195, 2499835433
  %197 = add i64 %196, 433342517
  %198 = add i64 %197, 433342517
  store i64 %198, ptr %1, align 8
  br label %85

199:                                              ; preds = %86
  %200 = load i64, ptr %1, align 8
  %201 = sub i64 %200, 1233061969
  %202 = or i64 %201, 1233061969
  %203 = sub i64 %202, %200
  %204 = xor i64 %203, %200
  %205 = and i64 %204, 1233061969
  store i64 %205, ptr %1, align 8
  br label %5

206:                                              ; preds = %97
  %207 = load i64, ptr %1, align 8
  %208 = add i64 3221155601, %207
  %209 = sub i64 %208, 2712465153
  %210 = mul i64 %209, 2675320848
  %211 = xor i64 %210, %207
  %212 = mul i64 %211, 2712465153
  store i64 %212, ptr %1, align 8
  br label %85

213:                                              ; preds = %117
  %214 = load i64, ptr %1, align 8
  %215 = or i64 %214, 3575700842
  %216 = or i64 %215, 257950646
  %217 = and i64 %216, %214
  %218 = or i64 %217, 3575700842
  store i64 %218, ptr %1, align 8
  br label %85

219:                                              ; preds = %137
  %220 = load i64, ptr %1, align 8
  %221 = mul i64 %220, %220
  %222 = add i64 %221, %220
  %223 = or i64 %222, %220
  store i64 %223, ptr %1, align 8
  br label %85

224:                                              ; preds = %150
  %225 = load i64, ptr %1, align 8
  %226 = xor i64 6943864396, %225
  %227 = or i64 %226, %225
  %228 = or i64 %227, 3213753253
  store i64 %228, ptr %1, align 8
  br label %85
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @freeGrid() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @1, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 2060577652, ptr %3, align 4
  br label %5

5:                                                ; preds = %164, %64, %63, %0
  %6 = load i32, ptr %3, align 4
  %7 = sub i32 %6, 106551835
  %8 = mul i32 %7, -1255604893
  %9 = icmp slt i32 %8, 1261897444
  br i1 %9, label %123, label %125

10:                                               ; preds = %139
  store i32 0, ptr %4, align 4
  store i32 1367412455, ptr %3, align 4
  %11 = xor i32 %2, 1925082035
  %12 = and i32 %2, %11
  %13 = or i32 %2, %11
  %14 = xor i32 %2, %11
  %15 = mul i32 %13, 2
  %16 = sub i32 %15, %14
  %17 = sub i32 %16, %2
  %18 = sub i32 %17, %11
  %19 = mul i32 %18, 57
  %20 = icmp ne i32 %19, 0
  br i1 %20, label %143, label %63

21:                                               ; preds = %135
  %22 = load i32, ptr %4, align 4
  %23 = load i32, ptr @N, align 4
  %24 = icmp slt i32 %22, %23
  %25 = select i1 %24, i32 -1591871939, i32 -2100453978
  store i32 %25, ptr %3, align 4
  %26 = xor i32 %2, -278484285
  %27 = and i32 %2, %26
  %28 = or i32 %2, %26
  %29 = xor i32 %2, %26
  %30 = sub i32 %28, %29
  %31 = sub i32 %30, %27
  %32 = mul i32 %31, 51
  %33 = icmp ne i32 %32, 0
  br i1 %33, label %151, label %63

34:                                               ; preds = %131
  %35 = load ptr, ptr @grid, align 8
  %36 = load i32, ptr %4, align 4
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds ptr, ptr %35, i64 %37
  %39 = load ptr, ptr %38, align 8
  call void @free(ptr noundef %39) #8
  %40 = load i32, ptr %4, align 4
  %41 = load i32, ptr %3, align 4
  %42 = xor i32 %41, -1591871940
  %43 = sub i32 %40, %42
  %44 = load i32, ptr %3, align 4
  %45 = xor i32 %44, -1591871937
  %46 = mul i32 %40, %45
  %47 = load i32, ptr %3, align 4
  %48 = xor i32 %47, -1591871940
  %49 = mul i32 %48, %43
  %50 = sub i32 %46, %49
  store i32 %50, ptr %4, align 4
  store i32 1367412455, ptr %3, align 4
  %51 = xor i32 %2, -1272117977
  %52 = and i32 %2, %51
  %53 = or i32 %2, %51
  %54 = xor i32 %2, %51
  %55 = mul i32 %53, 2
  %56 = sub i32 %55, %54
  %57 = sub i32 %56, %2
  %58 = sub i32 %57, %51
  %59 = mul i32 %58, 105
  %60 = icmp slt i32 %59, 0
  br i1 %60, label %157, label %63

61:                                               ; preds = %137
  %62 = load ptr, ptr @grid, align 8
  call void @free(ptr noundef %62) #8
  ret void

63:                                               ; preds = %193, %185, %178, %170, %157, %151, %143, %112, %99, %87, %75, %34, %21, %10
  br label %5

64:                                               ; preds = %141, %139, %133, %131
  store i32 2060577652, ptr %3, align 4
  call void asm sideeffect "", ""()
  %65 = xor i32 %2, 1608018167
  %66 = and i32 %2, %65
  %67 = or i32 %2, %65
  %68 = xor i32 %2, %65
  %69 = mul i32 %67, 2
  %70 = sub i32 %69, %68
  %71 = sub i32 %70, %2
  %72 = sub i32 %71, %65
  %73 = mul i32 %72, 124
  %74 = icmp sle i32 %73, 0
  br i1 %74, label %5, label %164

75:                                               ; preds = %129
  %76 = load i32, ptr %3, align 4
  %77 = xor i32 %76, 630116968
  store i32 %77, ptr %3, align 4
  %78 = xor i32 %2, -5033913
  %79 = and i32 %2, %78
  %80 = or i32 %2, %78
  %81 = xor i32 %2, %78
  %82 = add i32 %79, %80
  %83 = sub i32 %82, %2
  %84 = sub i32 %83, %78
  %85 = mul i32 %84, 133
  %86 = icmp slt i32 %85, 0
  br i1 %86, label %170, label %63

87:                                               ; preds = %127
  %88 = load i32, ptr %3, align 4
  %89 = xor i32 %88, 1195726644
  store i32 %89, ptr %3, align 4
  %90 = xor i32 %2, -1647870781
  %91 = and i32 %2, %90
  %92 = or i32 %2, %90
  %93 = xor i32 %2, %90
  %94 = add i32 %91, %92
  %95 = sub i32 %94, %2
  %96 = sub i32 %95, %90
  %97 = mul i32 %96, 201
  %98 = icmp ne i32 %97, 0
  br i1 %98, label %178, label %63

99:                                               ; preds = %141
  %100 = load i32, ptr %3, align 4
  %101 = xor i32 %100, 2133821450
  store i32 %101, ptr %3, align 4
  %102 = xor i32 %2, 1322770417
  %103 = and i32 %2, %102
  %104 = or i32 %2, %102
  %105 = xor i32 %2, %102
  %106 = add i32 %2, %102
  %107 = sub i32 %106, %105
  %108 = mul i32 %103, 2
  %109 = sub i32 %107, %108
  %110 = mul i32 %109, 32
  %111 = icmp uge i32 %110, 0
  br i1 %111, label %63, label %185

112:                                              ; preds = %133
  %113 = load i32, ptr %3, align 4
  %114 = xor i32 %113, 95000851
  store i32 %114, ptr %3, align 4
  %115 = xor i32 %2, 131048649
  %116 = and i32 %2, %115
  %117 = or i32 %2, %115
  %118 = xor i32 %2, %115
  %119 = sub i32 %117, %118
  %120 = sub i32 %119, %116
  %121 = mul i32 %120, 235
  %122 = icmp slt i32 %121, 0
  br i1 %122, label %193, label %63

123:                                              ; preds = %5
  %124 = icmp slt i32 %8, 711320916
  br i1 %124, label %127, label %129

125:                                              ; preds = %5
  %126 = icmp slt i32 %8, 1572666817
  br i1 %126, label %135, label %137

127:                                              ; preds = %123
  %128 = icmp eq i32 %8, 9886094
  br i1 %128, label %87, label %131

129:                                              ; preds = %123
  %130 = icmp eq i32 %8, 711320916
  br i1 %130, label %75, label %133

131:                                              ; preds = %127
  %132 = icmp eq i32 %8, 418675494
  br i1 %132, label %34, label %64

133:                                              ; preds = %129
  %134 = icmp eq i32 %8, 1209176204
  br i1 %134, label %112, label %64

135:                                              ; preds = %125
  %136 = icmp eq i32 %8, 1261897444
  br i1 %136, label %21, label %139

137:                                              ; preds = %125
  %138 = icmp eq i32 %8, 1572666817
  br i1 %138, label %61, label %141

139:                                              ; preds = %135
  %140 = icmp eq i32 %8, 1450945131
  br i1 %140, label %10, label %64

141:                                              ; preds = %137
  %142 = icmp eq i32 %8, 1732438574
  br i1 %142, label %99, label %64

143:                                              ; preds = %10
  %144 = load i64, ptr %1, align 8
  %145 = xor i64 %144, 2060873075
  %146 = add i64 %145, %144
  %147 = sub i64 %146, %144
  %148 = add i64 %147, %144
  %149 = or i64 %148, 3106838881
  %150 = sub i64 %149, 3106838881
  store i64 %150, ptr %1, align 8
  br label %63

151:                                              ; preds = %21
  %152 = load i64, ptr %1, align 8
  %153 = xor i64 169136977, %152
  %154 = or i64 %153, %152
  %155 = and i64 %154, %152
  %156 = and i64 %155, 169136977
  store i64 %156, ptr %1, align 8
  br label %63

157:                                              ; preds = %34
  %158 = load i64, ptr %1, align 8
  %159 = mul i64 3727750514, %158
  %160 = or i64 %159, 3727750514
  %161 = sub i64 %160, 3727750514
  %162 = and i64 %161, 3727750514
  %163 = and i64 %162, %158
  store i64 %163, ptr %1, align 8
  br label %63

164:                                              ; preds = %64
  %165 = load i64, ptr %1, align 8
  %166 = and i64 1898502000480170460, %165
  %167 = add i64 %166, 449809860
  %168 = add i64 %167, 4220676711
  %169 = sub i64 %168, 4220676711
  store i64 %169, ptr %1, align 8
  br label %5

170:                                              ; preds = %75
  %171 = load i64, ptr %1, align 8
  %172 = and i64 3283977478, %171
  %173 = xor i64 %172, 3283977478
  %174 = mul i64 %173, 2946133981
  %175 = and i64 %174, 3283977478
  %176 = sub i64 %175, 2946133981
  %177 = xor i64 %176, 3283977478
  store i64 %177, ptr %1, align 8
  br label %63

178:                                              ; preds = %87
  %179 = load i64, ptr %1, align 8
  %180 = and i64 3127306413876064225, %179
  %181 = or i64 %180, 2028100962
  %182 = xor i64 %181, 1768419185
  %183 = or i64 %182, 1768419185
  %184 = or i64 %183, %179
  store i64 %184, ptr %1, align 8
  br label %63

185:                                              ; preds = %99
  %186 = load i64, ptr %1, align 8
  %187 = or i64 %186, 867298003
  %188 = xor i64 %187, 720602223
  %189 = add i64 %188, %186
  %190 = add i64 %189, %186
  %191 = sub i64 %190, %186
  %192 = xor i64 %191, 867298003
  store i64 %192, ptr %1, align 8
  br label %63

193:                                              ; preds = %112
  %194 = load i64, ptr %1, align 8
  %195 = mul i64 -1843404598, %194
  store i64 %195, ptr %1, align 8
  br label %63
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @carveRow(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 1878327172, ptr %5, align 4
  br label %11

11:                                               ; preds = %277, %105, %104, %3
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 1122358334
  %14 = mul i32 %13, 415819987
  %15 = icmp slt i32 %14, 1213064671
  br i1 %15, label %196, label %198

16:                                               ; preds = %214
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  store i32 %2, ptr %8, align 4
  %17 = load i32, ptr %7, align 4
  %18 = load i32, ptr %8, align 4
  %19 = icmp sgt i32 %17, %18
  %20 = select i1 %19, i32 1076397653, i32 1617070529
  store i32 %20, ptr %5, align 4
  %21 = xor i32 %0, -677416631
  %22 = and i32 %0, %21
  %23 = or i32 %0, %21
  %24 = xor i32 %0, %21
  %25 = add i32 %22, %23
  %26 = sub i32 %25, %0
  %27 = sub i32 %26, %21
  %28 = mul i32 %27, 251
  %29 = xor i32 %0, -1760399993
  %30 = and i32 %0, %29
  %31 = or i32 %0, %29
  %32 = xor i32 %0, %29
  %33 = add i32 %30, %31
  %34 = sub i32 %33, %0
  %35 = sub i32 %34, %29
  %36 = mul i32 %35, 237
  %37 = icmp eq i32 %28, %36
  br i1 %37, label %104, label %232

38:                                               ; preds = %228
  %39 = load i32, ptr %7, align 4
  store i32 %39, ptr %9, align 4
  %40 = load i32, ptr %8, align 4
  store i32 %40, ptr %7, align 4
  %41 = load i32, ptr %9, align 4
  store i32 %41, ptr %8, align 4
  store i32 1617070529, ptr %5, align 4
  %42 = xor i32 %0, 1370292723
  %43 = and i32 %0, %42
  %44 = or i32 %0, %42
  %45 = xor i32 %0, %42
  %46 = add i32 %43, %44
  %47 = sub i32 %46, %0
  %48 = sub i32 %47, %42
  %49 = mul i32 %48, 100
  %50 = icmp slt i32 %49, 0
  br i1 %50, label %240, label %104

51:                                               ; preds = %226
  %52 = load i32, ptr %7, align 4
  store i32 %52, ptr %10, align 4
  store i32 1813707651, ptr %5, align 4
  %53 = xor i32 %0, -1175521029
  %54 = and i32 %0, %53
  %55 = or i32 %0, %53
  %56 = xor i32 %0, %53
  %57 = mul i32 %55, 2
  %58 = sub i32 %57, %56
  %59 = sub i32 %58, %0
  %60 = sub i32 %59, %53
  %61 = mul i32 %60, 24
  %62 = icmp sgt i32 %61, 0
  br i1 %62, label %248, label %104

63:                                               ; preds = %220
  %64 = load i32, ptr %10, align 4
  %65 = load i32, ptr %8, align 4
  %66 = icmp sle i32 %64, %65
  %67 = select i1 %66, i32 825911208, i32 -864607255
  store i32 %67, ptr %5, align 4
  %68 = xor i32 %0, 725441941
  %69 = and i32 %0, %68
  %70 = or i32 %0, %68
  %71 = xor i32 %0, %68
  %72 = add i32 %0, %68
  %73 = sub i32 %72, %71
  %74 = mul i32 %69, 2
  %75 = sub i32 %73, %74
  %76 = mul i32 %75, 76
  %77 = icmp ne i32 %76, 0
  br i1 %77, label %257, label %104

78:                                               ; preds = %212
  %79 = load ptr, ptr @grid, align 8
  %80 = load i32, ptr %6, align 4
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds ptr, ptr %79, i64 %81
  %83 = load ptr, ptr %82, align 8
  %84 = load i32, ptr %10, align 4
  %85 = sext i32 %84 to i64
  %86 = getelementptr inbounds i8, ptr %83, i64 %85
  store i8 46, ptr %86, align 1
  %87 = load i32, ptr %10, align 4
  %88 = load i32, ptr %5, align 4
  %89 = xor i32 %88, 825911209
  %90 = or i32 %87, %89
  %91 = load i32, ptr %5, align 4
  %92 = xor i32 %91, 825911209
  %93 = and i32 %87, %92
  %94 = add i32 %90, %93
  store i32 %94, ptr %10, align 4
  store i32 1813707651, ptr %5, align 4
  %95 = xor i32 %0, 1487539077
  %96 = and i32 %0, %95
  %97 = or i32 %0, %95
  %98 = xor i32 %0, %95
  %99 = sub i32 %97, %98
  %100 = sub i32 %99, %96
  %101 = mul i32 %100, 18
  %102 = icmp sle i32 %101, 0
  br i1 %102, label %104, label %268

103:                                              ; preds = %222
  ret void

104:                                              ; preds = %329, %321, %312, %304, %296, %288, %268, %257, %248, %240, %232, %176, %164, %151, %140, %128, %115, %78, %63, %51, %38, %16
  br label %11

105:                                              ; preds = %230, %226, %224, %220, %214, %210, %208, %204
  store i32 1878327172, ptr %5, align 4
  call void asm sideeffect "", ""()
  %106 = xor i32 %0, -181733173
  %107 = and i32 %0, %106
  %108 = or i32 %0, %106
  %109 = xor i32 %0, %106
  %110 = add i32 %107, %108
  %111 = sub i32 %110, %0
  %112 = sub i32 %111, %106
  %113 = mul i32 %112, 114
  %114 = icmp slt i32 %113, 1
  br i1 %114, label %11, label %277

115:                                              ; preds = %208
  %116 = load i32, ptr %5, align 4
  %117 = xor i32 %116, -415399648
  store i32 %117, ptr %5, align 4
  %118 = xor i32 %0, -1571670291
  %119 = and i32 %0, %118
  %120 = or i32 %0, %118
  %121 = xor i32 %0, %118
  %122 = add i32 %0, %118
  %123 = sub i32 %122, %121
  %124 = mul i32 %119, 2
  %125 = sub i32 %123, %124
  %126 = mul i32 %125, 101
  %127 = icmp eq i32 %126, 0
  br i1 %127, label %104, label %288

128:                                              ; preds = %206
  %129 = load i32, ptr %5, align 4
  %130 = xor i32 %129, 1682681556
  store i32 %130, ptr %5, align 4
  %131 = xor i32 %0, 372436141
  %132 = and i32 %0, %131
  %133 = or i32 %0, %131
  %134 = xor i32 %0, %131
  %135 = add i32 %132, %133
  %136 = sub i32 %135, %0
  %137 = sub i32 %136, %131
  %138 = mul i32 %137, 245
  %139 = icmp sle i32 %138, 0
  br i1 %139, label %104, label %296

140:                                              ; preds = %210
  %141 = load i32, ptr %5, align 4
  %142 = xor i32 %141, -74191516
  store i32 %142, ptr %5, align 4
  %143 = xor i32 %0, 1231375797
  %144 = and i32 %0, %143
  %145 = or i32 %0, %143
  %146 = xor i32 %0, %143
  %147 = sub i32 %145, %146
  %148 = sub i32 %147, %144
  %149 = mul i32 %148, 190
  %150 = icmp sgt i32 %149, 0
  br i1 %150, label %304, label %104

151:                                              ; preds = %230
  %152 = load i32, ptr %5, align 4
  %153 = xor i32 %152, 584085811
  store i32 %153, ptr %5, align 4
  %154 = xor i32 %0, 995407121
  %155 = and i32 %0, %154
  %156 = or i32 %0, %154
  %157 = xor i32 %0, %154
  %158 = add i32 %0, %154
  %159 = sub i32 %158, %157
  %160 = mul i32 %155, 2
  %161 = sub i32 %159, %160
  %162 = mul i32 %161, 80
  %163 = icmp eq i32 %162, 0
  br i1 %163, label %104, label %312

164:                                              ; preds = %224
  %165 = load i32, ptr %5, align 4
  %166 = xor i32 %165, -1720843656
  store i32 %166, ptr %5, align 4
  %167 = xor i32 %0, 980413881
  %168 = and i32 %0, %167
  %169 = or i32 %0, %167
  %170 = xor i32 %0, %167
  %171 = add i32 %168, %169
  %172 = sub i32 %171, %0
  %173 = sub i32 %172, %167
  %174 = mul i32 %173, 96
  %175 = icmp sgt i32 %174, 0
  br i1 %175, label %321, label %104

176:                                              ; preds = %204
  %177 = load i32, ptr %5, align 4
  %178 = xor i32 %177, 306314024
  store i32 %178, ptr %5, align 4
  %179 = xor i32 %0, 815165569
  %180 = and i32 %0, %179
  %181 = or i32 %0, %179
  %182 = xor i32 %0, %179
  %183 = add i32 %180, %181
  %184 = sub i32 %183, %0
  %185 = sub i32 %184, %179
  %186 = mul i32 %185, 167
  %187 = xor i32 %0, -1370062095
  %188 = and i32 %0, %187
  %189 = or i32 %0, %187
  %190 = xor i32 %0, %187
  %191 = add i32 %188, %189
  %192 = sub i32 %191, %0
  %193 = sub i32 %192, %187
  %194 = mul i32 %193, 140
  %195 = icmp eq i32 %186, %194
  br i1 %195, label %104, label %329

196:                                              ; preds = %11
  %197 = icmp slt i32 %14, 639481697
  br i1 %197, label %200, label %202

198:                                              ; preds = %11
  %199 = icmp slt i32 %14, 1755337465
  br i1 %199, label %216, label %218

200:                                              ; preds = %196
  %201 = icmp slt i32 %14, 401986392
  br i1 %201, label %204, label %206

202:                                              ; preds = %196
  %203 = icmp slt i32 %14, 807243870
  br i1 %203, label %210, label %212

204:                                              ; preds = %200
  %205 = icmp eq i32 %14, 96927162
  br i1 %205, label %176, label %105

206:                                              ; preds = %200
  %207 = icmp eq i32 %14, 401986392
  br i1 %207, label %128, label %208

208:                                              ; preds = %206
  %209 = icmp eq i32 %14, 567918777
  br i1 %209, label %115, label %105

210:                                              ; preds = %202
  %211 = icmp eq i32 %14, 639481697
  br i1 %211, label %140, label %105

212:                                              ; preds = %202
  %213 = icmp eq i32 %14, 807243870
  br i1 %213, label %78, label %214

214:                                              ; preds = %212
  %215 = icmp eq i32 %14, 1097341618
  br i1 %215, label %16, label %105

216:                                              ; preds = %198
  %217 = icmp slt i32 %14, 1485808113
  br i1 %217, label %220, label %222

218:                                              ; preds = %198
  %219 = icmp slt i32 %14, 2035654901
  br i1 %219, label %226, label %228

220:                                              ; preds = %216
  %221 = icmp eq i32 %14, 1213064671
  br i1 %221, label %63, label %105

222:                                              ; preds = %216
  %223 = icmp eq i32 %14, 1485808113
  br i1 %223, label %103, label %224

224:                                              ; preds = %222
  %225 = icmp eq i32 %14, 1644845438
  br i1 %225, label %164, label %105

226:                                              ; preds = %218
  %227 = icmp eq i32 %14, 1755337465
  br i1 %227, label %51, label %105

228:                                              ; preds = %218
  %229 = icmp eq i32 %14, 2035654901
  br i1 %229, label %38, label %230

230:                                              ; preds = %228
  %231 = icmp eq i32 %14, 2042234339
  br i1 %231, label %151, label %105

232:                                              ; preds = %16
  %233 = load i64, ptr %4, align 8
  %234 = zext i32 %0 to i64
  %235 = zext i32 %1 to i64
  %236 = zext i32 %2 to i64
  %237 = and i64 %236, %235
  %238 = mul i64 %237, %236
  %239 = or i64 %238, %234
  store i64 %239, ptr %4, align 8
  br label %104

240:                                              ; preds = %38
  %241 = load i64, ptr %4, align 8
  %242 = zext i32 %0 to i64
  %243 = zext i32 %1 to i64
  %244 = zext i32 %2 to i64
  %245 = or i64 %244, %244
  %246 = add i64 %245, %243
  %247 = or i64 %246, %241
  store i64 %247, ptr %4, align 8
  br label %104

248:                                              ; preds = %51
  %249 = load i64, ptr %4, align 8
  %250 = zext i32 %0 to i64
  %251 = zext i32 %1 to i64
  %252 = zext i32 %2 to i64
  %253 = or i64 %251, %250
  %254 = or i64 %253, %252
  %255 = mul i64 %254, %249
  %256 = xor i64 %255, %249
  store i64 %256, ptr %4, align 8
  br label %104

257:                                              ; preds = %63
  %258 = load i64, ptr %4, align 8
  %259 = zext i32 %0 to i64
  %260 = zext i32 %1 to i64
  %261 = zext i32 %2 to i64
  %262 = and i64 %261, %259
  %263 = add i64 %262, %261
  %264 = mul i64 %263, %259
  %265 = sub i64 %264, %261
  %266 = add i64 %265, %260
  %267 = sub i64 %266, %259
  store i64 %267, ptr %4, align 8
  br label %104

268:                                              ; preds = %78
  %269 = load i64, ptr %4, align 8
  %270 = zext i32 %0 to i64
  %271 = zext i32 %1 to i64
  %272 = zext i32 %2 to i64
  %273 = mul i64 %270, %270
  %274 = add i64 %273, %269
  %275 = mul i64 %274, %271
  %276 = or i64 %275, %272
  store i64 %276, ptr %4, align 8
  br label %104

277:                                              ; preds = %105
  %278 = load i64, ptr %4, align 8
  %279 = zext i32 %0 to i64
  %280 = zext i32 %1 to i64
  %281 = zext i32 %2 to i64
  %282 = mul i64 %280, %281
  %283 = sub i64 %282, %279
  %284 = xor i64 %283, %280
  %285 = add i64 %284, %280
  %286 = sub i64 %285, %281
  %287 = xor i64 %286, %281
  store i64 %287, ptr %4, align 8
  br label %11

288:                                              ; preds = %115
  %289 = load i64, ptr %4, align 8
  %290 = zext i32 %0 to i64
  %291 = zext i32 %1 to i64
  %292 = zext i32 %2 to i64
  %293 = or i64 %289, %292
  %294 = sub i64 %293, %291
  %295 = sub i64 %294, %290
  store i64 %295, ptr %4, align 8
  br label %104

296:                                              ; preds = %128
  %297 = load i64, ptr %4, align 8
  %298 = zext i32 %0 to i64
  %299 = zext i32 %1 to i64
  %300 = zext i32 %2 to i64
  %301 = add i64 %298, %299
  %302 = or i64 %301, %300
  %303 = add i64 %302, %298
  store i64 %303, ptr %4, align 8
  br label %104

304:                                              ; preds = %140
  %305 = load i64, ptr %4, align 8
  %306 = zext i32 %0 to i64
  %307 = zext i32 %1 to i64
  %308 = zext i32 %2 to i64
  %309 = add i64 %305, %305
  %310 = add i64 %309, %306
  %311 = and i64 %310, %305
  store i64 %311, ptr %4, align 8
  br label %104

312:                                              ; preds = %151
  %313 = load i64, ptr %4, align 8
  %314 = zext i32 %0 to i64
  %315 = zext i32 %1 to i64
  %316 = zext i32 %2 to i64
  %317 = mul i64 %316, %314
  %318 = and i64 %317, %314
  %319 = add i64 %318, %316
  %320 = or i64 %319, %313
  store i64 %320, ptr %4, align 8
  br label %104

321:                                              ; preds = %164
  %322 = load i64, ptr %4, align 8
  %323 = zext i32 %0 to i64
  %324 = zext i32 %1 to i64
  %325 = zext i32 %2 to i64
  %326 = xor i64 %322, %324
  %327 = sub i64 %326, %325
  %328 = xor i64 %327, %322
  store i64 %328, ptr %4, align 8
  br label %104

329:                                              ; preds = %176
  %330 = load i64, ptr %4, align 8
  %331 = zext i32 %0 to i64
  %332 = zext i32 %1 to i64
  %333 = zext i32 %2 to i64
  %334 = and i64 %331, %333
  %335 = or i64 %334, %331
  %336 = xor i64 %335, %331
  %337 = and i64 %336, %332
  %338 = mul i64 %337, %330
  store i64 %338, ptr %4, align 8
  br label %104
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @carveCol(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 -540982352, ptr %5, align 4
  br label %11

11:                                               ; preds = %288, %100, %99, %3
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 1180738867
  %14 = mul i32 %13, -1190067115
  %15 = icmp slt i32 %14, 1116231792
  br i1 %15, label %203, label %205

16:                                               ; preds = %231
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  store i32 %2, ptr %8, align 4
  %17 = load i32, ptr %7, align 4
  %18 = load i32, ptr %8, align 4
  %19 = icmp sgt i32 %17, %18
  %20 = select i1 %19, i32 -301077911, i32 1485736931
  store i32 %20, ptr %5, align 4
  %21 = xor i32 %0, -1386108099
  %22 = and i32 %0, %21
  %23 = or i32 %0, %21
  %24 = xor i32 %0, %21
  %25 = add i32 %0, %21
  %26 = sub i32 %25, %24
  %27 = mul i32 %22, 2
  %28 = sub i32 %26, %27
  %29 = mul i32 %28, 91
  %30 = icmp ugt i32 %29, 0
  br i1 %30, label %239, label %99

31:                                               ; preds = %211
  %32 = load i32, ptr %7, align 4
  store i32 %32, ptr %9, align 4
  %33 = load i32, ptr %8, align 4
  store i32 %33, ptr %7, align 4
  %34 = load i32, ptr %9, align 4
  store i32 %34, ptr %8, align 4
  store i32 1485736931, ptr %5, align 4
  %35 = xor i32 %0, -340902903
  %36 = and i32 %0, %35
  %37 = or i32 %0, %35
  %38 = xor i32 %0, %35
  %39 = add i32 %36, %37
  %40 = sub i32 %39, %0
  %41 = sub i32 %40, %35
  %42 = mul i32 %41, 121
  %43 = icmp uge i32 %42, 0
  br i1 %43, label %99, label %248

44:                                               ; preds = %227
  %45 = load i32, ptr %7, align 4
  store i32 %45, ptr %10, align 4
  store i32 -1913854785, ptr %5, align 4
  %46 = xor i32 %0, -1059791599
  %47 = and i32 %0, %46
  %48 = or i32 %0, %46
  %49 = xor i32 %0, %46
  %50 = mul i32 %48, 2
  %51 = sub i32 %50, %49
  %52 = sub i32 %51, %0
  %53 = sub i32 %52, %46
  %54 = mul i32 %53, 19
  %55 = icmp sle i32 %54, 0
  br i1 %55, label %99, label %259

56:                                               ; preds = %233
  %57 = load i32, ptr %10, align 4
  %58 = load i32, ptr %8, align 4
  %59 = icmp sle i32 %57, %58
  %60 = select i1 %59, i32 -882424238, i32 1961725935
  store i32 %60, ptr %5, align 4
  %61 = xor i32 %0, -1500203967
  %62 = and i32 %0, %61
  %63 = or i32 %0, %61
  %64 = xor i32 %0, %61
  %65 = mul i32 %63, 2
  %66 = sub i32 %65, %64
  %67 = sub i32 %66, %0
  %68 = sub i32 %67, %61
  %69 = mul i32 %68, 107
  %70 = icmp slt i32 %69, 0
  br i1 %70, label %270, label %99

71:                                               ; preds = %235
  %72 = load ptr, ptr @grid, align 8
  %73 = load i32, ptr %10, align 4
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds ptr, ptr %72, i64 %74
  %76 = load ptr, ptr %75, align 8
  %77 = load i32, ptr %6, align 4
  %78 = sext i32 %77 to i64
  %79 = getelementptr inbounds i8, ptr %76, i64 %78
  store i8 46, ptr %79, align 1
  %80 = load i32, ptr %10, align 4
  %81 = load i32, ptr %5, align 4
  %82 = xor i32 %81, -882424237
  %83 = xor i32 %80, %82
  %84 = load i32, ptr %5, align 4
  %85 = xor i32 %84, -882424237
  %86 = and i32 %80, %85
  %87 = add i32 %86, %86
  %88 = add i32 %83, %87
  store i32 %88, ptr %10, align 4
  store i32 -1913854785, ptr %5, align 4
  %89 = xor i32 %0, 367687823
  %90 = and i32 %0, %89
  %91 = or i32 %0, %89
  %92 = xor i32 %0, %89
  %93 = add i32 %90, %91
  %94 = sub i32 %93, %0
  %95 = sub i32 %94, %89
  %96 = mul i32 %95, 146
  %97 = icmp slt i32 %96, 0
  br i1 %97, label %279, label %99

98:                                               ; preds = %217
  ret void

99:                                               ; preds = %345, %334, %325, %315, %306, %298, %279, %270, %259, %248, %239, %190, %168, %157, %144, %132, %119, %71, %56, %44, %31, %16
  br label %11

100:                                              ; preds = %237, %233, %231, %227, %221, %217, %215, %211
  store i32 -540982352, ptr %5, align 4
  call void asm sideeffect "", ""()
  %101 = xor i32 %0, 93228185
  %102 = and i32 %0, %101
  %103 = or i32 %0, %101
  %104 = xor i32 %0, %101
  %105 = add i32 %0, %101
  %106 = sub i32 %105, %104
  %107 = mul i32 %102, 2
  %108 = sub i32 %106, %107
  %109 = mul i32 %108, 134
  %110 = xor i32 %0, -773765647
  %111 = and i32 %0, %110
  %112 = or i32 %0, %110
  %113 = xor i32 %0, %110
  %114 = add i32 %111, %112
  %115 = sub i32 %114, %0
  %116 = sub i32 %115, %110
  %117 = mul i32 %116, 235
  %118 = icmp eq i32 %109, %117
  br i1 %118, label %11, label %288

119:                                              ; preds = %213
  %120 = load i32, ptr %5, align 4
  %121 = xor i32 %120, 1138060943
  store i32 %121, ptr %5, align 4
  %122 = xor i32 %0, -1659582553
  %123 = and i32 %0, %122
  %124 = or i32 %0, %122
  %125 = xor i32 %0, %122
  %126 = mul i32 %124, 2
  %127 = sub i32 %126, %125
  %128 = sub i32 %127, %0
  %129 = sub i32 %128, %122
  %130 = mul i32 %129, 164
  %131 = icmp slt i32 %130, 0
  br i1 %131, label %298, label %99

132:                                              ; preds = %219
  %133 = load i32, ptr %5, align 4
  %134 = xor i32 %133, 1740607995
  store i32 %134, ptr %5, align 4
  %135 = xor i32 %0, 1989227387
  %136 = and i32 %0, %135
  %137 = or i32 %0, %135
  %138 = xor i32 %0, %135
  %139 = add i32 %136, %137
  %140 = sub i32 %139, %0
  %141 = sub i32 %140, %135
  %142 = mul i32 %141, 190
  %143 = icmp ugt i32 %142, 0
  br i1 %143, label %306, label %99

144:                                              ; preds = %229
  %145 = load i32, ptr %5, align 4
  %146 = xor i32 %145, -712396501
  store i32 %146, ptr %5, align 4
  %147 = xor i32 %0, 1785887213
  %148 = and i32 %0, %147
  %149 = or i32 %0, %147
  %150 = xor i32 %0, %147
  %151 = mul i32 %149, 2
  %152 = sub i32 %151, %150
  %153 = sub i32 %152, %0
  %154 = sub i32 %153, %147
  %155 = mul i32 %154, 138
  %156 = icmp slt i32 %155, 0
  br i1 %156, label %315, label %99

157:                                              ; preds = %221
  %158 = load i32, ptr %5, align 4
  %159 = xor i32 %158, 1253782112
  store i32 %159, ptr %5, align 4
  %160 = xor i32 %0, 500885151
  %161 = and i32 %0, %160
  %162 = or i32 %0, %160
  %163 = xor i32 %0, %160
  %164 = sub i32 %162, %163
  %165 = sub i32 %164, %161
  %166 = mul i32 %165, 208
  %167 = icmp eq i32 %166, 0
  br i1 %167, label %99, label %325

168:                                              ; preds = %215
  %169 = load i32, ptr %5, align 4
  %170 = xor i32 %169, 438723031
  store i32 %170, ptr %5, align 4
  %171 = xor i32 %0, -1782561521
  %172 = and i32 %0, %171
  %173 = or i32 %0, %171
  %174 = xor i32 %0, %171
  %175 = add i32 %0, %171
  %176 = sub i32 %175, %174
  %177 = mul i32 %172, 2
  %178 = sub i32 %176, %177
  %179 = mul i32 %178, 219
  %180 = xor i32 %0, 1359364091
  %181 = and i32 %0, %180
  %182 = or i32 %0, %180
  %183 = xor i32 %0, %180
  %184 = mul i32 %182, 2
  %185 = sub i32 %184, %183
  %186 = sub i32 %185, %0
  %187 = sub i32 %186, %180
  %188 = mul i32 %187, 200
  %189 = icmp ne i32 %179, %188
  br i1 %189, label %334, label %99

190:                                              ; preds = %237
  %191 = load i32, ptr %5, align 4
  %192 = xor i32 %191, -1519340599
  store i32 %192, ptr %5, align 4
  %193 = xor i32 %0, -1164952413
  %194 = and i32 %0, %193
  %195 = or i32 %0, %193
  %196 = xor i32 %0, %193
  %197 = add i32 %0, %193
  %198 = sub i32 %197, %196
  %199 = mul i32 %194, 2
  %200 = sub i32 %198, %199
  %201 = mul i32 %200, 7
  %202 = icmp slt i32 %201, 0
  br i1 %202, label %345, label %99

203:                                              ; preds = %11
  %204 = icmp slt i32 %14, 451993708
  br i1 %204, label %207, label %209

205:                                              ; preds = %11
  %206 = icmp slt i32 %14, 1457211772
  br i1 %206, label %223, label %225

207:                                              ; preds = %203
  %208 = icmp slt i32 %14, 236268670
  br i1 %208, label %211, label %213

209:                                              ; preds = %203
  %210 = icmp slt i32 %14, 506286466
  br i1 %210, label %217, label %219

211:                                              ; preds = %207
  %212 = icmp eq i32 %14, 3330798
  br i1 %212, label %31, label %100

213:                                              ; preds = %207
  %214 = icmp eq i32 %14, 236268670
  br i1 %214, label %119, label %215

215:                                              ; preds = %213
  %216 = icmp eq i32 %14, 281851214
  br i1 %216, label %168, label %100

217:                                              ; preds = %209
  %218 = icmp eq i32 %14, 451993708
  br i1 %218, label %98, label %100

219:                                              ; preds = %209
  %220 = icmp eq i32 %14, 506286466
  br i1 %220, label %132, label %221

221:                                              ; preds = %219
  %222 = icmp eq i32 %14, 857626387
  br i1 %222, label %157, label %100

223:                                              ; preds = %205
  %224 = icmp slt i32 %14, 1132665959
  br i1 %224, label %227, label %229

225:                                              ; preds = %205
  %226 = icmp slt i32 %14, 1606875979
  br i1 %226, label %233, label %235

227:                                              ; preds = %223
  %228 = icmp eq i32 %14, 1116231792
  br i1 %228, label %44, label %100

229:                                              ; preds = %223
  %230 = icmp eq i32 %14, 1132665959
  br i1 %230, label %144, label %231

231:                                              ; preds = %229
  %232 = icmp eq i32 %14, 1255904129
  br i1 %232, label %16, label %100

233:                                              ; preds = %225
  %234 = icmp eq i32 %14, 1457211772
  br i1 %234, label %56, label %100

235:                                              ; preds = %225
  %236 = icmp eq i32 %14, 1606875979
  br i1 %236, label %71, label %237

237:                                              ; preds = %235
  %238 = icmp eq i32 %14, 1973155020
  br i1 %238, label %190, label %100

239:                                              ; preds = %16
  %240 = load i64, ptr %4, align 8
  %241 = zext i32 %0 to i64
  %242 = zext i32 %1 to i64
  %243 = zext i32 %2 to i64
  %244 = sub i64 %241, %241
  %245 = and i64 %244, %242
  %246 = and i64 %245, %243
  %247 = or i64 %246, %240
  store i64 %247, ptr %4, align 8
  br label %99

248:                                              ; preds = %31
  %249 = load i64, ptr %4, align 8
  %250 = zext i32 %0 to i64
  %251 = zext i32 %1 to i64
  %252 = zext i32 %2 to i64
  %253 = add i64 %251, %251
  %254 = xor i64 %253, %250
  %255 = xor i64 %254, %252
  %256 = or i64 %255, %250
  %257 = or i64 %256, %252
  %258 = xor i64 %257, %252
  store i64 %258, ptr %4, align 8
  br label %99

259:                                              ; preds = %44
  %260 = load i64, ptr %4, align 8
  %261 = zext i32 %0 to i64
  %262 = zext i32 %1 to i64
  %263 = zext i32 %2 to i64
  %264 = add i64 %260, %262
  %265 = or i64 %264, %260
  %266 = add i64 %265, %260
  %267 = and i64 %266, %263
  %268 = or i64 %267, %263
  %269 = or i64 %268, %262
  store i64 %269, ptr %4, align 8
  br label %99

270:                                              ; preds = %56
  %271 = load i64, ptr %4, align 8
  %272 = zext i32 %0 to i64
  %273 = zext i32 %1 to i64
  %274 = zext i32 %2 to i64
  %275 = mul i64 %272, %271
  %276 = or i64 %275, %273
  %277 = sub i64 %276, %271
  %278 = add i64 %277, %273
  store i64 %278, ptr %4, align 8
  br label %99

279:                                              ; preds = %71
  %280 = load i64, ptr %4, align 8
  %281 = zext i32 %0 to i64
  %282 = zext i32 %1 to i64
  %283 = zext i32 %2 to i64
  %284 = mul i64 %283, %280
  %285 = xor i64 %284, %281
  %286 = or i64 %285, %280
  %287 = add i64 %286, %283
  store i64 %287, ptr %4, align 8
  br label %99

288:                                              ; preds = %100
  %289 = load i64, ptr %4, align 8
  %290 = zext i32 %0 to i64
  %291 = zext i32 %1 to i64
  %292 = zext i32 %2 to i64
  %293 = and i64 %291, %290
  %294 = xor i64 %293, %289
  %295 = mul i64 %294, %291
  %296 = sub i64 %295, %292
  %297 = sub i64 %296, %292
  store i64 %297, ptr %4, align 8
  br label %11

298:                                              ; preds = %119
  %299 = load i64, ptr %4, align 8
  %300 = zext i32 %0 to i64
  %301 = zext i32 %1 to i64
  %302 = zext i32 %2 to i64
  %303 = and i64 %300, %302
  %304 = or i64 %303, %302
  %305 = xor i64 %304, %301
  store i64 %305, ptr %4, align 8
  br label %99

306:                                              ; preds = %132
  %307 = load i64, ptr %4, align 8
  %308 = zext i32 %0 to i64
  %309 = zext i32 %1 to i64
  %310 = zext i32 %2 to i64
  %311 = and i64 %308, %310
  %312 = xor i64 %311, %307
  %313 = or i64 %312, %308
  %314 = or i64 %313, %309
  store i64 %314, ptr %4, align 8
  br label %99

315:                                              ; preds = %144
  %316 = load i64, ptr %4, align 8
  %317 = zext i32 %0 to i64
  %318 = zext i32 %1 to i64
  %319 = zext i32 %2 to i64
  %320 = or i64 %318, %318
  %321 = or i64 %320, %318
  %322 = xor i64 %321, %317
  %323 = sub i64 %322, %318
  %324 = xor i64 %323, %316
  store i64 %324, ptr %4, align 8
  br label %99

325:                                              ; preds = %157
  %326 = load i64, ptr %4, align 8
  %327 = zext i32 %0 to i64
  %328 = zext i32 %1 to i64
  %329 = zext i32 %2 to i64
  %330 = add i64 %326, %326
  %331 = or i64 %330, %328
  %332 = or i64 %331, %326
  %333 = add i64 %332, %326
  store i64 %333, ptr %4, align 8
  br label %99

334:                                              ; preds = %168
  %335 = load i64, ptr %4, align 8
  %336 = zext i32 %0 to i64
  %337 = zext i32 %1 to i64
  %338 = zext i32 %2 to i64
  %339 = xor i64 %337, %336
  %340 = or i64 %339, %337
  %341 = and i64 %340, %338
  %342 = or i64 %341, %335
  %343 = sub i64 %342, %335
  %344 = add i64 %343, %337
  store i64 %344, ptr %4, align 8
  br label %99

345:                                              ; preds = %190
  %346 = load i64, ptr %4, align 8
  %347 = zext i32 %0 to i64
  %348 = zext i32 %1 to i64
  %349 = zext i32 %2 to i64
  %350 = and i64 %348, %348
  %351 = sub i64 %350, %348
  %352 = and i64 %351, %346
  %353 = sub i64 %352, %346
  %354 = or i64 %353, %348
  store i64 %354, ptr %4, align 8
  br label %99
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @samePoint(i64 %0, i64 %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i1, align 1
  %6 = alloca %struct.Point, align 4
  %7 = alloca %struct.Point, align 4
  store i32 126645804, ptr %4, align 4
  br label %8

8:                                                ; preds = %144, %58, %57, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -1141393994
  %11 = mul i32 %10, 2040040841
  %12 = icmp slt i32 %11, 1311187885
  br i1 %12, label %116, label %118

13:                                               ; preds = %130
  store i64 %0, ptr %6, align 4
  store i64 %1, ptr %7, align 4
  %14 = getelementptr inbounds nuw %struct.Point, ptr %6, i32 0, i32 0
  %15 = load i32, ptr %14, align 4
  %16 = getelementptr inbounds nuw %struct.Point, ptr %7, i32 0, i32 0
  %17 = load i32, ptr %16, align 4
  %18 = icmp eq i32 %15, %17
  store i1 false, ptr %5, align 1
  %19 = select i1 %18, i32 -1224141381, i32 -1821793801
  store i32 %19, ptr %4, align 4
  %20 = xor i64 %0, 7070237423946774149
  %21 = and i64 %0, %20
  %22 = or i64 %0, %20
  %23 = xor i64 %0, %20
  %24 = add i64 %0, %20
  %25 = sub i64 %24, %23
  %26 = mul i64 %21, 2
  %27 = sub i64 %25, %26
  %28 = mul i64 %27, 77
  %29 = icmp slt i64 %28, 1
  br i1 %29, label %57, label %132

30:                                               ; preds = %126
  %31 = getelementptr inbounds nuw %struct.Point, ptr %6, i32 0, i32 1
  %32 = load i32, ptr %31, align 4
  %33 = getelementptr inbounds nuw %struct.Point, ptr %7, i32 0, i32 1
  %34 = load i32, ptr %33, align 4
  %35 = icmp eq i32 %32, %34
  store i1 %35, ptr %5, align 1
  store i32 -1821793801, ptr %4, align 4
  %36 = xor i64 %0, 578736021580967635
  %37 = and i64 %0, %36
  %38 = or i64 %0, %36
  %39 = xor i64 %0, %36
  %40 = add i64 %0, %36
  %41 = sub i64 %40, %39
  %42 = mul i64 %37, 2
  %43 = sub i64 %41, %42
  %44 = mul i64 %43, 12
  %45 = xor i64 %0, 5506553774073106865
  %46 = and i64 %0, %45
  %47 = or i64 %0, %45
  %48 = xor i64 %0, %45
  %49 = add i64 %46, %47
  %50 = sub i64 %49, %0
  %51 = sub i64 %50, %45
  %52 = mul i64 %51, 152
  %53 = icmp eq i64 %44, %52
  br i1 %53, label %57, label %138

54:                                               ; preds = %122
  %55 = load i1, ptr %5, align 1
  %56 = zext i1 %55 to i32
  ret i32 %56

57:                                               ; preds = %163, %158, %151, %138, %132, %103, %91, %78, %30, %13
  br label %8

58:                                               ; preds = %130, %126, %124, %120
  store i32 126645804, ptr %4, align 4
  call void asm sideeffect "", ""()
  %59 = xor i64 %0, -8620433919425555139
  %60 = and i64 %0, %59
  %61 = or i64 %0, %59
  %62 = xor i64 %0, %59
  %63 = add i64 %0, %59
  %64 = sub i64 %63, %62
  %65 = mul i64 %60, 2
  %66 = sub i64 %64, %65
  %67 = mul i64 %66, 202
  %68 = xor i64 %0, -5441550126568162375
  %69 = and i64 %0, %68
  %70 = or i64 %0, %68
  %71 = xor i64 %0, %68
  %72 = add i64 %0, %68
  %73 = sub i64 %72, %71
  %74 = mul i64 %69, 2
  %75 = sub i64 %73, %74
  %76 = mul i64 %75, 232
  %77 = icmp ne i64 %67, %76
  br i1 %77, label %144, label %8

78:                                               ; preds = %128
  %79 = load i32, ptr %4, align 4
  %80 = xor i32 %79, 1540874537
  store i32 %80, ptr %4, align 4
  %81 = xor i64 %0, -253297415779004863
  %82 = and i64 %0, %81
  %83 = or i64 %0, %81
  %84 = xor i64 %0, %81
  %85 = add i64 %0, %81
  %86 = sub i64 %85, %84
  %87 = mul i64 %82, 2
  %88 = sub i64 %86, %87
  %89 = mul i64 %88, 16
  %90 = icmp ugt i64 %89, 0
  br i1 %90, label %151, label %57

91:                                               ; preds = %120
  %92 = load i32, ptr %4, align 4
  %93 = xor i32 %92, -1233380639
  store i32 %93, ptr %4, align 4
  %94 = xor i64 %0, 1547681824357794243
  %95 = and i64 %0, %94
  %96 = or i64 %0, %94
  %97 = xor i64 %0, %94
  %98 = add i64 %95, %96
  %99 = sub i64 %98, %0
  %100 = sub i64 %99, %94
  %101 = mul i64 %100, 148
  %102 = icmp slt i64 %101, 0
  br i1 %102, label %158, label %57

103:                                              ; preds = %124
  %104 = load i32, ptr %4, align 4
  %105 = xor i32 %104, 153743579
  store i32 %105, ptr %4, align 4
  %106 = xor i64 %0, -6505109141877952607
  %107 = and i64 %0, %106
  %108 = or i64 %0, %106
  %109 = xor i64 %0, %106
  %110 = add i64 %0, %106
  %111 = sub i64 %110, %109
  %112 = mul i64 %107, 2
  %113 = sub i64 %111, %112
  %114 = mul i64 %113, 81
  %115 = icmp sle i64 %114, 0
  br i1 %115, label %57, label %163

116:                                              ; preds = %8
  %117 = icmp slt i32 %11, 179256265
  br i1 %117, label %120, label %122

118:                                              ; preds = %8
  %119 = icmp slt i32 %11, 1791311710
  br i1 %119, label %126, label %128

120:                                              ; preds = %116
  %121 = icmp eq i32 %11, 2009548
  br i1 %121, label %91, label %58

122:                                              ; preds = %116
  %123 = icmp eq i32 %11, 179256265
  br i1 %123, label %54, label %124

124:                                              ; preds = %122
  %125 = icmp eq i32 %11, 769939222
  br i1 %125, label %103, label %58

126:                                              ; preds = %118
  %127 = icmp eq i32 %11, 1311187885
  br i1 %127, label %30, label %58

128:                                              ; preds = %118
  %129 = icmp eq i32 %11, 1791311710
  br i1 %129, label %78, label %130

130:                                              ; preds = %128
  %131 = icmp eq i32 %11, 1823210790
  br i1 %131, label %13, label %58

132:                                              ; preds = %13
  %133 = load i64, ptr %3, align 8
  %134 = mul i64 %133, %0
  %135 = or i64 %134, %0
  %136 = xor i64 %135, %0
  %137 = sub i64 %136, %133
  store i64 %137, ptr %3, align 8
  br label %57

138:                                              ; preds = %30
  %139 = load i64, ptr %3, align 8
  %140 = add i64 %0, %139
  %141 = and i64 %140, %139
  %142 = add i64 %141, %0
  %143 = and i64 %142, %139
  store i64 %143, ptr %3, align 8
  br label %57

144:                                              ; preds = %58
  %145 = load i64, ptr %3, align 8
  %146 = or i64 %145, %0
  %147 = mul i64 %146, %0
  %148 = xor i64 %147, %145
  %149 = add i64 %148, %1
  %150 = add i64 %149, %145
  store i64 %150, ptr %3, align 8
  br label %8

151:                                              ; preds = %78
  %152 = load i64, ptr %3, align 8
  %153 = sub i64 %0, %152
  %154 = sub i64 %153, %0
  %155 = sub i64 %154, %1
  %156 = xor i64 %155, %1
  %157 = and i64 %156, %152
  store i64 %157, ptr %3, align 8
  br label %57

158:                                              ; preds = %91
  %159 = load i64, ptr %3, align 8
  %160 = xor i64 %0, %159
  %161 = and i64 %160, %0
  %162 = add i64 %161, %159
  store i64 %162, ptr %3, align 8
  br label %57

163:                                              ; preds = %103
  %164 = load i64, ptr %3, align 8
  %165 = xor i64 %1, %1
  %166 = and i64 %165, %164
  %167 = mul i64 %166, %1
  %168 = mul i64 %167, %0
  %169 = mul i64 %168, %1
  store i64 %169, ptr %3, align 8
  br label %57
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @usedPoint(ptr noundef %0, i32 noundef %1, i64 %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca %struct.Point, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 -1265840757, ptr %5, align 4
  br label %11

11:                                               ; preds = %260, %96, %95, %3
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 1853755343
  %14 = mul i32 %13, 153164721
  switch i32 %14, label %96 [
    i32 258999036, label %15
    i32 1655244085, label %24
    i32 1133345591, label %38
    i32 1256867640, label %56
    i32 397115885, label %65
    i32 720545159, label %84
    i32 1034708932, label %93
    i32 484828774, label %115
    i32 400102303, label %127
    i32 1807711863, label %140
    i32 1873657220, label %152
    i32 144677325, label %165
    i32 929672255, label %185
    i32 9730006, label %197
  ]

15:                                               ; preds = %11
  store i64 %2, ptr %7, align 4
  store ptr %0, ptr %8, align 8
  store i32 %1, ptr %9, align 4
  store i32 0, ptr %10, align 4
  store i32 -234641772, ptr %5, align 4
  %16 = xor i32 %1, 1712670657
  %17 = and i32 %1, %16
  %18 = or i32 %1, %16
  %19 = xor i32 %1, %16
  %20 = sub i32 %18, %19
  %21 = sub i32 %20, %17
  %22 = mul i32 %21, 153
  %23 = icmp uge i32 %22, 0
  br i1 %23, label %95, label %210

24:                                               ; preds = %11
  %25 = load i32, ptr %10, align 4
  %26 = load i32, ptr %9, align 4
  %27 = icmp slt i32 %25, %26
  %28 = select i1 %27, i32 2138019638, i32 -640939386
  store i32 %28, ptr %5, align 4
  %29 = xor i32 %1, -1118574675
  %30 = and i32 %1, %29
  %31 = or i32 %1, %29
  %32 = xor i32 %1, %29
  %33 = add i32 %30, %31
  %34 = sub i32 %33, %1
  %35 = sub i32 %34, %29
  %36 = mul i32 %35, 77
  %37 = icmp ne i32 %36, 0
  br i1 %37, label %218, label %95

38:                                               ; preds = %11
  %39 = load ptr, ptr %8, align 8
  %40 = load i32, ptr %10, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds %struct.Point, ptr %39, i64 %41
  %43 = load i64, ptr %42, align 4
  %44 = load i64, ptr %7, align 4
  %45 = call i32 @samePoint(i64 %43, i64 %44)
  %46 = icmp ne i32 %45, 0
  %47 = select i1 %46, i32 -2047184761, i32 -968854324
  store i32 %47, ptr %5, align 4
  %48 = xor i32 %1, 2066734001
  %49 = and i32 %1, %48
  %50 = or i32 %1, %48
  %51 = xor i32 %1, %48
  %52 = sub i32 %50, %51
  %53 = sub i32 %52, %49
  %54 = mul i32 %53, 24
  %55 = icmp sle i32 %54, 0
  br i1 %55, label %95, label %225

56:                                               ; preds = %11
  store i32 1, ptr %6, align 4
  store i32 -1408706349, ptr %5, align 4
  %57 = xor i32 %1, -1923470779
  %58 = and i32 %1, %57
  %59 = or i32 %1, %57
  %60 = xor i32 %1, %57
  %61 = sub i32 %59, %60
  %62 = sub i32 %61, %58
  %63 = mul i32 %62, 143
  %64 = icmp uge i32 %63, 0
  br i1 %64, label %95, label %233

65:                                               ; preds = %11
  %66 = load i32, ptr %10, align 4
  %67 = load i32, ptr %5, align 4
  %68 = xor i32 %67, -968854323
  %69 = xor i32 %66, %68
  %70 = load i32, ptr %5, align 4
  %71 = xor i32 %70, -968854323
  %72 = and i32 %66, %71
  %73 = add i32 %72, %72
  %74 = add i32 %69, %73
  store i32 %74, ptr %10, align 4
  store i32 -234641772, ptr %5, align 4
  %75 = xor i32 %1, -987429175
  %76 = and i32 %1, %75
  %77 = or i32 %1, %75
  %78 = xor i32 %1, %75
  %79 = add i32 %76, %77
  %80 = sub i32 %79, %1
  %81 = sub i32 %80, %75
  %82 = mul i32 %81, 105
  %83 = icmp eq i32 %82, 0
  br i1 %83, label %95, label %243

84:                                               ; preds = %11
  store i32 0, ptr %6, align 4
  store i32 -1408706349, ptr %5, align 4
  %85 = xor i32 %1, -1348658311
  %86 = and i32 %1, %85
  %87 = or i32 %1, %85
  %88 = xor i32 %1, %85
  %89 = sub i32 %87, %88
  %90 = sub i32 %89, %86
  %91 = mul i32 %90, 12
  %92 = icmp ne i32 %91, 0
  br i1 %92, label %251, label %95

93:                                               ; preds = %11
  %94 = load i32, ptr %6, align 4
  ret i32 %94

95:                                               ; preds = %321, %314, %307, %299, %289, %279, %269, %251, %243, %233, %225, %218, %210, %197, %185, %165, %152, %140, %127, %115, %84, %65, %56, %38, %24, %15
  br label %11

96:                                               ; preds = %11
  store i32 -1265840757, ptr %5, align 4
  call void asm sideeffect "", ""()
  %97 = xor i32 %1, 2126155509
  %98 = and i32 %1, %97
  %99 = or i32 %1, %97
  %100 = xor i32 %1, %97
  %101 = add i32 %98, %99
  %102 = sub i32 %101, %1
  %103 = sub i32 %102, %97
  %104 = mul i32 %103, 161
  %105 = xor i32 %1, 1190874435
  %106 = and i32 %1, %105
  %107 = or i32 %1, %105
  %108 = xor i32 %1, %105
  %109 = add i32 %1, %105
  %110 = sub i32 %109, %108
  %111 = mul i32 %106, 2
  %112 = sub i32 %110, %111
  %113 = mul i32 %112, 51
  %114 = icmp ne i32 %104, %113
  br i1 %114, label %260, label %11

115:                                              ; preds = %11
  %116 = load i32, ptr %5, align 4
  %117 = xor i32 %116, 1952770014
  store i32 %117, ptr %5, align 4
  %118 = xor i32 %1, -1347180747
  %119 = and i32 %1, %118
  %120 = or i32 %1, %118
  %121 = xor i32 %1, %118
  %122 = add i32 %119, %120
  %123 = sub i32 %122, %1
  %124 = sub i32 %123, %118
  %125 = mul i32 %124, 227
  %126 = icmp slt i32 %125, 0
  br i1 %126, label %269, label %95

127:                                              ; preds = %11
  %128 = load i32, ptr %5, align 4
  %129 = xor i32 %128, -2102055464
  store i32 %129, ptr %5, align 4
  %130 = xor i32 %1, 279006767
  %131 = and i32 %1, %130
  %132 = or i32 %1, %130
  %133 = xor i32 %1, %130
  %134 = mul i32 %132, 2
  %135 = sub i32 %134, %133
  %136 = sub i32 %135, %1
  %137 = sub i32 %136, %130
  %138 = mul i32 %137, 129
  %139 = icmp sgt i32 %138, 0
  br i1 %139, label %279, label %95

140:                                              ; preds = %11
  %141 = load i32, ptr %5, align 4
  %142 = xor i32 %141, 2082607888
  store i32 %142, ptr %5, align 4
  %143 = xor i32 %1, 206542447
  %144 = and i32 %1, %143
  %145 = or i32 %1, %143
  %146 = xor i32 %1, %143
  %147 = add i32 %144, %145
  %148 = sub i32 %147, %1
  %149 = sub i32 %148, %143
  %150 = mul i32 %149, 23
  %151 = icmp ugt i32 %150, 0
  br i1 %151, label %289, label %95

152:                                              ; preds = %11
  %153 = load i32, ptr %5, align 4
  %154 = xor i32 %153, 1032666238
  store i32 %154, ptr %5, align 4
  %155 = xor i32 %1, 147122889
  %156 = and i32 %1, %155
  %157 = or i32 %1, %155
  %158 = xor i32 %1, %155
  %159 = add i32 %1, %155
  %160 = sub i32 %159, %158
  %161 = mul i32 %156, 2
  %162 = sub i32 %160, %161
  %163 = mul i32 %162, 227
  %164 = icmp slt i32 %163, 1
  br i1 %164, label %95, label %299

165:                                              ; preds = %11
  %166 = load i32, ptr %5, align 4
  %167 = xor i32 %166, 168679426
  store i32 %167, ptr %5, align 4
  %168 = xor i32 %1, 2096077545
  %169 = and i32 %1, %168
  %170 = or i32 %1, %168
  %171 = xor i32 %1, %168
  %172 = mul i32 %170, 2
  %173 = sub i32 %172, %171
  %174 = sub i32 %173, %1
  %175 = sub i32 %174, %168
  %176 = mul i32 %175, 141
  %177 = xor i32 %1, 2024017799
  %178 = and i32 %1, %177
  %179 = or i32 %1, %177
  %180 = xor i32 %1, %177
  %181 = sub i32 %179, %180
  %182 = sub i32 %181, %178
  %183 = mul i32 %182, 186
  %184 = icmp eq i32 %176, %183
  br i1 %184, label %95, label %307

185:                                              ; preds = %11
  %186 = load i32, ptr %5, align 4
  %187 = xor i32 %186, 1427855437
  store i32 %187, ptr %5, align 4
  %188 = xor i32 %1, 126005061
  %189 = and i32 %1, %188
  %190 = or i32 %1, %188
  %191 = xor i32 %1, %188
  %192 = add i32 %189, %190
  %193 = sub i32 %192, %1
  %194 = sub i32 %193, %188
  %195 = mul i32 %194, 64
  %196 = icmp eq i32 %195, 0
  br i1 %196, label %95, label %314

197:                                              ; preds = %11
  %198 = load i32, ptr %5, align 4
  %199 = xor i32 %198, 1564069428
  store i32 %199, ptr %5, align 4
  %200 = xor i32 %1, 1224412889
  %201 = and i32 %1, %200
  %202 = or i32 %1, %200
  %203 = xor i32 %1, %200
  %204 = mul i32 %202, 2
  %205 = sub i32 %204, %203
  %206 = sub i32 %205, %1
  %207 = sub i32 %206, %200
  %208 = mul i32 %207, 238
  %209 = icmp slt i32 %208, 0
  br i1 %209, label %321, label %95

210:                                              ; preds = %15
  %211 = load i64, ptr %4, align 8
  %212 = ptrtoint ptr %0 to i64
  %213 = zext i32 %1 to i64
  %214 = and i64 %212, %211
  %215 = and i64 %214, %213
  %216 = xor i64 %215, %212
  %217 = xor i64 %216, %212
  store i64 %217, ptr %4, align 8
  br label %95

218:                                              ; preds = %24
  %219 = load i64, ptr %4, align 8
  %220 = ptrtoint ptr %0 to i64
  %221 = zext i32 %1 to i64
  %222 = and i64 %221, %219
  %223 = sub i64 %222, %219
  %224 = mul i64 %223, %221
  store i64 %224, ptr %4, align 8
  br label %95

225:                                              ; preds = %38
  %226 = load i64, ptr %4, align 8
  %227 = ptrtoint ptr %0 to i64
  %228 = zext i32 %1 to i64
  %229 = sub i64 %227, %2
  %230 = sub i64 %229, %228
  %231 = add i64 %230, %226
  %232 = or i64 %231, %228
  store i64 %232, ptr %4, align 8
  br label %95

233:                                              ; preds = %56
  %234 = load i64, ptr %4, align 8
  %235 = ptrtoint ptr %0 to i64
  %236 = zext i32 %1 to i64
  %237 = or i64 %236, %2
  %238 = sub i64 %237, %236
  %239 = or i64 %238, %235
  %240 = sub i64 %239, %234
  %241 = and i64 %240, %236
  %242 = or i64 %241, %2
  store i64 %242, ptr %4, align 8
  br label %95

243:                                              ; preds = %65
  %244 = load i64, ptr %4, align 8
  %245 = ptrtoint ptr %0 to i64
  %246 = zext i32 %1 to i64
  %247 = mul i64 %244, %244
  %248 = xor i64 %247, %244
  %249 = or i64 %248, %2
  %250 = add i64 %249, %245
  store i64 %250, ptr %4, align 8
  br label %95

251:                                              ; preds = %84
  %252 = load i64, ptr %4, align 8
  %253 = ptrtoint ptr %0 to i64
  %254 = zext i32 %1 to i64
  %255 = mul i64 %2, %2
  %256 = add i64 %255, %252
  %257 = mul i64 %256, %253
  %258 = sub i64 %257, %253
  %259 = sub i64 %258, %254
  store i64 %259, ptr %4, align 8
  br label %95

260:                                              ; preds = %96
  %261 = load i64, ptr %4, align 8
  %262 = ptrtoint ptr %0 to i64
  %263 = zext i32 %1 to i64
  %264 = or i64 %262, %2
  %265 = sub i64 %264, %262
  %266 = or i64 %265, %2
  %267 = xor i64 %266, %262
  %268 = mul i64 %267, %261
  store i64 %268, ptr %4, align 8
  br label %11

269:                                              ; preds = %115
  %270 = load i64, ptr %4, align 8
  %271 = ptrtoint ptr %0 to i64
  %272 = zext i32 %1 to i64
  %273 = add i64 %272, %271
  %274 = mul i64 %273, %271
  %275 = mul i64 %274, %270
  %276 = or i64 %275, %271
  %277 = mul i64 %276, %2
  %278 = mul i64 %277, %270
  store i64 %278, ptr %4, align 8
  br label %95

279:                                              ; preds = %127
  %280 = load i64, ptr %4, align 8
  %281 = ptrtoint ptr %0 to i64
  %282 = zext i32 %1 to i64
  %283 = mul i64 %281, %280
  %284 = and i64 %283, %2
  %285 = add i64 %284, %281
  %286 = sub i64 %285, %280
  %287 = sub i64 %286, %282
  %288 = xor i64 %287, %2
  store i64 %288, ptr %4, align 8
  br label %95

289:                                              ; preds = %140
  %290 = load i64, ptr %4, align 8
  %291 = ptrtoint ptr %0 to i64
  %292 = zext i32 %1 to i64
  %293 = sub i64 %2, %2
  %294 = add i64 %293, %292
  %295 = mul i64 %294, %2
  %296 = add i64 %295, %290
  %297 = or i64 %296, %2
  %298 = sub i64 %297, %2
  store i64 %298, ptr %4, align 8
  br label %95

299:                                              ; preds = %152
  %300 = load i64, ptr %4, align 8
  %301 = ptrtoint ptr %0 to i64
  %302 = zext i32 %1 to i64
  %303 = or i64 %2, %302
  %304 = xor i64 %303, %2
  %305 = mul i64 %304, %2
  %306 = or i64 %305, %300
  store i64 %306, ptr %4, align 8
  br label %95

307:                                              ; preds = %165
  %308 = load i64, ptr %4, align 8
  %309 = ptrtoint ptr %0 to i64
  %310 = zext i32 %1 to i64
  %311 = or i64 %309, %308
  %312 = mul i64 %311, %2
  %313 = mul i64 %312, %308
  store i64 %313, ptr %4, align 8
  br label %95

314:                                              ; preds = %185
  %315 = load i64, ptr %4, align 8
  %316 = ptrtoint ptr %0 to i64
  %317 = zext i32 %1 to i64
  %318 = sub i64 %2, %315
  %319 = add i64 %318, %316
  %320 = mul i64 %319, %317
  store i64 %320, ptr %4, align 8
  br label %95

321:                                              ; preds = %197
  %322 = load i64, ptr %4, align 8
  %323 = ptrtoint ptr %0 to i64
  %324 = zext i32 %1 to i64
  %325 = xor i64 %324, %323
  %326 = add i64 %325, %324
  %327 = mul i64 %326, %2
  store i64 %327, ptr %4, align 8
  br label %95
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @generateDungeon(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca i64, align 8
  store i64 0, ptr %5, align 8
  %6 = ptrtoint ptr %0 to i32
  %7 = alloca i32, align 4
  %8 = alloca i1, align 1
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  %18 = alloca %struct.Point, align 4
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  store i32 -1981395056, ptr %7, align 4
  br label %21

21:                                               ; preds = %1470, %856, %855, %4
  %22 = load i32, ptr %7, align 4
  %23 = sub i32 %22, 297711929
  %24 = mul i32 %23, -1474632715
  %25 = icmp slt i32 %24, 946175993
  br i1 %25, label %981, label %983

26:                                               ; preds = %1109
  store ptr %0, ptr %9, align 8
  store ptr %1, ptr %10, align 8
  store ptr %2, ptr %11, align 8
  store ptr %3, ptr %12, align 8
  %27 = load ptr, ptr %9, align 8
  %28 = getelementptr inbounds nuw %struct.Point, ptr %27, i32 0, i32 0
  store i32 0, ptr %28, align 4
  %29 = load ptr, ptr %9, align 8
  %30 = getelementptr inbounds nuw %struct.Point, ptr %29, i32 0, i32 1
  store i32 0, ptr %30, align 4
  %31 = load i32, ptr @N, align 4
  %32 = load i32, ptr %7, align 4
  %33 = xor i32 %32, -1981395055
  %34 = xor i32 %31, %33
  %35 = load i32, ptr %7, align 4
  %36 = xor i32 %35, 1981395055
  %37 = xor i32 %31, %36
  %38 = load i32, ptr %7, align 4
  %39 = xor i32 %38, -1981395055
  %40 = and i32 %37, %39
  %41 = add i32 %40, %40
  %42 = sub i32 %34, %41
  %43 = load ptr, ptr %10, align 8
  %44 = getelementptr inbounds nuw %struct.Point, ptr %43, i32 0, i32 0
  store i32 %42, ptr %44, align 4
  %45 = load i32, ptr @N, align 4
  %46 = load i32, ptr %7, align 4
  %47 = xor i32 %46, -1981395055
  %48 = add i32 %45, %47
  %49 = load i32, ptr %7, align 4
  %50 = xor i32 %49, -1981395054
  %51 = mul i32 %45, %50
  %52 = load i32, ptr %7, align 4
  %53 = xor i32 %52, -1981395055
  %54 = mul i32 %53, %48
  %55 = sub i32 %51, %54
  %56 = load ptr, ptr %10, align 8
  %57 = getelementptr inbounds nuw %struct.Point, ptr %56, i32 0, i32 1
  store i32 %55, ptr %57, align 4
  store i32 0, ptr %13, align 4
  store i32 139367118, ptr %7, align 4
  %58 = xor i32 %6, 697135345
  %59 = and i32 %6, %58
  %60 = or i32 %6, %58
  %61 = xor i32 %6, %58
  %62 = sub i32 %60, %61
  %63 = sub i32 %62, %59
  %64 = mul i32 %63, 29
  %65 = xor i32 %6, -1473818981
  %66 = and i32 %6, %65
  %67 = or i32 %6, %65
  %68 = xor i32 %6, %65
  %69 = sub i32 %67, %68
  %70 = sub i32 %69, %66
  %71 = mul i32 %70, 198
  %72 = icmp ne i32 %64, %71
  br i1 %72, label %1117, label %855

73:                                               ; preds = %1097
  %74 = load i32, ptr %13, align 4
  %75 = load i32, ptr @N, align 4
  %76 = icmp slt i32 %74, %75
  %77 = select i1 %76, i32 1285789115, i32 2144835312
  store i32 %77, ptr %7, align 4
  %78 = xor i32 %6, 1539152853
  %79 = and i32 %6, %78
  %80 = or i32 %6, %78
  %81 = xor i32 %6, %78
  %82 = sub i32 %80, %81
  %83 = sub i32 %82, %79
  %84 = mul i32 %83, 191
  %85 = icmp uge i32 %84, 0
  br i1 %85, label %855, label %1128

86:                                               ; preds = %997
  store i32 0, ptr %14, align 4
  store i32 983864161, ptr %7, align 4
  %87 = xor i32 %6, 1748714027
  %88 = and i32 %6, %87
  %89 = or i32 %6, %87
  %90 = xor i32 %6, %87
  %91 = sub i32 %89, %90
  %92 = sub i32 %91, %88
  %93 = mul i32 %92, 113
  %94 = icmp ugt i32 %93, 0
  br i1 %94, label %1138, label %855

95:                                               ; preds = %1081
  %96 = load i32, ptr %14, align 4
  %97 = load i32, ptr @N, align 4
  %98 = icmp slt i32 %96, %97
  %99 = select i1 %98, i32 1400544661, i32 1621890323
  store i32 %99, ptr %7, align 4
  %100 = xor i32 %6, 2112660677
  %101 = and i32 %6, %100
  %102 = or i32 %6, %100
  %103 = xor i32 %6, %100
  %104 = sub i32 %102, %103
  %105 = sub i32 %104, %101
  %106 = mul i32 %105, 85
  %107 = icmp sle i32 %106, 0
  br i1 %107, label %855, label %1147

108:                                              ; preds = %1015
  %109 = load i32, ptr %13, align 4
  %110 = load i32, ptr %7, align 4
  %111 = xor i32 %110, 1400544688
  %112 = mul nsw i32 %109, %111
  %113 = load i32, ptr %14, align 4
  %114 = load i32, ptr %7, align 4
  %115 = xor i32 %114, 1400544646
  %116 = mul nsw i32 %113, %115
  %117 = xor i32 %112, %116
  %118 = and i32 %112, %116
  %119 = add i32 %118, %118
  %120 = add i32 %117, %119
  %121 = load i32, ptr @N, align 4
  %122 = load i32, ptr %7, align 4
  %123 = xor i32 %122, 1400544670
  %124 = mul nsw i32 %121, %123
  %125 = load i32, ptr %7, align 4
  %126 = xor i32 %125, 1400544660
  %127 = add i32 %124, %126
  %128 = load i32, ptr %7, align 4
  %129 = xor i32 %128, 1400544660
  %130 = sub i32 %120, %129
  %131 = mul i32 %120, %127
  %132 = mul i32 %124, %130
  %133 = sub i32 %131, %132
  %134 = load i32, ptr %13, align 4
  %135 = load i32, ptr %14, align 4
  %136 = mul nsw i32 %134, %135
  %137 = load i32, ptr %7, align 4
  %138 = xor i32 %137, 1400544658
  %139 = mul nsw i32 %136, %138
  %140 = load i32, ptr %7, align 4
  %141 = xor i32 %140, 1400544660
  %142 = add i32 %139, %141
  %143 = load i32, ptr %7, align 4
  %144 = xor i32 %143, 1400544660
  %145 = sub i32 %133, %144
  %146 = mul i32 %133, %142
  %147 = mul i32 %139, %145
  %148 = sub i32 %146, %147
  %149 = srem i32 %148, 17
  store i32 %149, ptr %15, align 4
  %150 = load i32, ptr %15, align 4
  %151 = icmp slt i32 %150, 3
  %152 = select i1 %151, i32 -477671295, i32 -657534459
  store i32 %152, ptr %7, align 4
  %153 = xor i32 %6, -1755066835
  %154 = and i32 %6, %153
  %155 = or i32 %6, %153
  %156 = xor i32 %6, %153
  %157 = add i32 %6, %153
  %158 = sub i32 %157, %156
  %159 = mul i32 %154, 2
  %160 = sub i32 %158, %159
  %161 = mul i32 %160, 114
  %162 = icmp sgt i32 %161, 0
  br i1 %162, label %1158, label %855

163:                                              ; preds = %1065
  %164 = load ptr, ptr @grid, align 8
  %165 = load i32, ptr %13, align 4
  %166 = sext i32 %165 to i64
  %167 = getelementptr inbounds ptr, ptr %164, i64 %166
  %168 = load ptr, ptr %167, align 8
  %169 = load i32, ptr %14, align 4
  %170 = sext i32 %169 to i64
  %171 = getelementptr inbounds i8, ptr %168, i64 %170
  store i8 35, ptr %171, align 1
  store i32 743280573, ptr %7, align 4
  %172 = xor i32 %6, 330322323
  %173 = and i32 %6, %172
  %174 = or i32 %6, %172
  %175 = xor i32 %6, %172
  %176 = mul i32 %174, 2
  %177 = sub i32 %176, %175
  %178 = sub i32 %177, %6
  %179 = sub i32 %178, %172
  %180 = mul i32 %179, 205
  %181 = icmp slt i32 %180, 0
  br i1 %181, label %1168, label %855

182:                                              ; preds = %1043
  %183 = load i32, ptr %15, align 4
  %184 = icmp slt i32 %183, 5
  %185 = select i1 %184, i32 1660444105, i32 -442198361
  store i32 %185, ptr %7, align 4
  %186 = xor i32 %6, -650334125
  %187 = and i32 %6, %186
  %188 = or i32 %6, %186
  %189 = xor i32 %6, %186
  %190 = add i32 %6, %186
  %191 = sub i32 %190, %189
  %192 = mul i32 %187, 2
  %193 = sub i32 %191, %192
  %194 = mul i32 %193, 14
  %195 = icmp ne i32 %194, 0
  br i1 %195, label %1177, label %855

196:                                              ; preds = %1009
  %197 = load ptr, ptr @grid, align 8
  %198 = load i32, ptr %13, align 4
  %199 = sext i32 %198 to i64
  %200 = getelementptr inbounds ptr, ptr %197, i64 %199
  %201 = load ptr, ptr %200, align 8
  %202 = load i32, ptr %14, align 4
  %203 = sext i32 %202 to i64
  %204 = getelementptr inbounds i8, ptr %201, i64 %203
  store i8 94, ptr %204, align 1
  store i32 1142947109, ptr %7, align 4
  %205 = xor i32 %6, 1662529241
  %206 = and i32 %6, %205
  %207 = or i32 %6, %205
  %208 = xor i32 %6, %205
  %209 = sub i32 %207, %208
  %210 = sub i32 %209, %206
  %211 = mul i32 %210, 131
  %212 = icmp eq i32 %211, 0
  br i1 %212, label %855, label %1189

213:                                              ; preds = %1073
  %214 = load i32, ptr %15, align 4
  %215 = icmp slt i32 %214, 7
  %216 = select i1 %215, i32 645575596, i32 505758828
  store i32 %216, ptr %7, align 4
  %217 = xor i32 %6, -1767977311
  %218 = and i32 %6, %217
  %219 = or i32 %6, %217
  %220 = xor i32 %6, %217
  %221 = add i32 %6, %217
  %222 = sub i32 %221, %220
  %223 = mul i32 %218, 2
  %224 = sub i32 %222, %223
  %225 = mul i32 %224, 64
  %226 = xor i32 %6, 78434833
  %227 = and i32 %6, %226
  %228 = or i32 %6, %226
  %229 = xor i32 %6, %226
  %230 = sub i32 %228, %229
  %231 = sub i32 %230, %227
  %232 = mul i32 %231, 112
  %233 = icmp eq i32 %225, %232
  br i1 %233, label %855, label %1199

234:                                              ; preds = %1107
  %235 = load ptr, ptr @grid, align 8
  %236 = load i32, ptr %13, align 4
  %237 = sext i32 %236 to i64
  %238 = getelementptr inbounds ptr, ptr %235, i64 %237
  %239 = load ptr, ptr %238, align 8
  %240 = load i32, ptr %14, align 4
  %241 = sext i32 %240 to i64
  %242 = getelementptr inbounds i8, ptr %239, i64 %241
  store i8 126, ptr %242, align 1
  store i32 -689131888, ptr %7, align 4
  %243 = xor i32 %6, 2107439427
  %244 = and i32 %6, %243
  %245 = or i32 %6, %243
  %246 = xor i32 %6, %243
  %247 = add i32 %6, %243
  %248 = sub i32 %247, %246
  %249 = mul i32 %244, 2
  %250 = sub i32 %248, %249
  %251 = mul i32 %250, 192
  %252 = icmp uge i32 %251, 0
  br i1 %252, label %855, label %1209

253:                                              ; preds = %1099
  %254 = load ptr, ptr @grid, align 8
  %255 = load i32, ptr %13, align 4
  %256 = sext i32 %255 to i64
  %257 = getelementptr inbounds ptr, ptr %254, i64 %256
  %258 = load ptr, ptr %257, align 8
  %259 = load i32, ptr %14, align 4
  %260 = sext i32 %259 to i64
  %261 = getelementptr inbounds i8, ptr %258, i64 %260
  store i8 46, ptr %261, align 1
  store i32 -689131888, ptr %7, align 4
  %262 = xor i32 %6, -1584847997
  %263 = and i32 %6, %262
  %264 = or i32 %6, %262
  %265 = xor i32 %6, %262
  %266 = add i32 %6, %262
  %267 = sub i32 %266, %265
  %268 = mul i32 %263, 2
  %269 = sub i32 %267, %268
  %270 = mul i32 %269, 178
  %271 = xor i32 %6, 1210617319
  %272 = and i32 %6, %271
  %273 = or i32 %6, %271
  %274 = xor i32 %6, %271
  %275 = add i32 %6, %271
  %276 = sub i32 %275, %274
  %277 = mul i32 %272, 2
  %278 = sub i32 %276, %277
  %279 = mul i32 %278, 86
  %280 = icmp ne i32 %270, %279
  br i1 %280, label %1219, label %855

281:                                              ; preds = %1111
  store i32 1142947109, ptr %7, align 4
  %282 = xor i32 %6, -1968467085
  %283 = and i32 %6, %282
  %284 = or i32 %6, %282
  %285 = xor i32 %6, %282
  %286 = sub i32 %284, %285
  %287 = sub i32 %286, %283
  %288 = mul i32 %287, 132
  %289 = icmp sgt i32 %288, 0
  br i1 %289, label %1231, label %855

290:                                              ; preds = %1063
  store i32 743280573, ptr %7, align 4
  %291 = xor i32 %6, 51296775
  %292 = and i32 %6, %291
  %293 = or i32 %6, %291
  %294 = xor i32 %6, %291
  %295 = sub i32 %293, %294
  %296 = sub i32 %295, %292
  %297 = mul i32 %296, 102
  %298 = xor i32 %6, -661333051
  %299 = and i32 %6, %298
  %300 = or i32 %6, %298
  %301 = xor i32 %6, %298
  %302 = mul i32 %300, 2
  %303 = sub i32 %302, %301
  %304 = sub i32 %303, %6
  %305 = sub i32 %304, %298
  %306 = mul i32 %305, 94
  %307 = icmp ne i32 %297, %306
  br i1 %307, label %1241, label %855

308:                                              ; preds = %1113
  %309 = load i32, ptr %14, align 4
  %310 = load i32, ptr %7, align 4
  %311 = xor i32 %310, 743280572
  %312 = xor i32 %309, %311
  %313 = load i32, ptr %7, align 4
  %314 = xor i32 %313, 743280572
  %315 = and i32 %309, %314
  %316 = add i32 %315, %315
  %317 = add i32 %312, %316
  store i32 %317, ptr %14, align 4
  store i32 983864161, ptr %7, align 4
  %318 = xor i32 %6, -273612055
  %319 = and i32 %6, %318
  %320 = or i32 %6, %318
  %321 = xor i32 %6, %318
  %322 = add i32 %6, %318
  %323 = sub i32 %322, %321
  %324 = mul i32 %319, 2
  %325 = sub i32 %323, %324
  %326 = mul i32 %325, 207
  %327 = icmp eq i32 %326, 0
  br i1 %327, label %855, label %1252

328:                                              ; preds = %1095
  %329 = load i32, ptr %13, align 4
  %330 = load i32, ptr %7, align 4
  %331 = xor i32 %330, 1621890322
  %332 = or i32 %329, %331
  %333 = load i32, ptr %7, align 4
  %334 = xor i32 %333, 1621890322
  %335 = and i32 %329, %334
  %336 = add i32 %332, %335
  store i32 %336, ptr %13, align 4
  store i32 139367118, ptr %7, align 4
  %337 = xor i32 %6, -4357855
  %338 = and i32 %6, %337
  %339 = or i32 %6, %337
  %340 = xor i32 %6, %337
  %341 = add i32 %338, %339
  %342 = sub i32 %341, %6
  %343 = sub i32 %342, %337
  %344 = mul i32 %343, 180
  %345 = icmp ne i32 %344, 0
  br i1 %345, label %1264, label %855

346:                                              ; preds = %1003
  %347 = load i32, ptr @N, align 4
  %348 = load i32, ptr %7, align 4
  %349 = xor i32 %348, 2144835313
  %350 = xor i32 %347, %349
  %351 = load i32, ptr %7, align 4
  %352 = xor i32 %351, -2144835313
  %353 = xor i32 %347, %352
  %354 = load i32, ptr %7, align 4
  %355 = xor i32 %354, 2144835313
  %356 = and i32 %353, %355
  %357 = add i32 %356, %356
  %358 = sub i32 %350, %357
  call void @carveRow(i32 noundef 0, i32 noundef 0, i32 noundef %358)
  %359 = load i32, ptr @N, align 4
  %360 = load i32, ptr %7, align 4
  %361 = xor i32 %360, 2144835313
  %362 = xor i32 %359, %361
  %363 = load i32, ptr %7, align 4
  %364 = xor i32 %363, -2144835313
  %365 = xor i32 %359, %364
  %366 = load i32, ptr %7, align 4
  %367 = xor i32 %366, 2144835313
  %368 = and i32 %365, %367
  %369 = add i32 %368, %368
  %370 = sub i32 %362, %369
  %371 = load i32, ptr @N, align 4
  %372 = load i32, ptr %7, align 4
  %373 = xor i32 %372, -2144835314
  %374 = add i32 %371, %373
  %375 = load i32, ptr %7, align 4
  %376 = xor i32 %375, 2144835313
  %377 = add i32 %374, %376
  call void @carveCol(i32 noundef %370, i32 noundef 0, i32 noundef %377)
  %378 = load i32, ptr @N, align 4
  %379 = sdiv i32 %378, 3
  store i32 %379, ptr %16, align 4
  %380 = load i32, ptr %16, align 4
  %381 = icmp slt i32 %380, 1
  %382 = select i1 %381, i32 203077100, i32 -1270055539
  store i32 %382, ptr %7, align 4
  %383 = xor i32 %6, -979503157
  %384 = and i32 %6, %383
  %385 = or i32 %6, %383
  %386 = xor i32 %6, %383
  %387 = sub i32 %385, %386
  %388 = sub i32 %387, %384
  %389 = mul i32 %388, 220
  %390 = xor i32 %6, -956319691
  %391 = and i32 %6, %390
  %392 = or i32 %6, %390
  %393 = xor i32 %6, %390
  %394 = mul i32 %392, 2
  %395 = sub i32 %394, %393
  %396 = sub i32 %395, %6
  %397 = sub i32 %396, %390
  %398 = mul i32 %397, 57
  %399 = icmp eq i32 %389, %398
  br i1 %399, label %855, label %1273

400:                                              ; preds = %1075
  store i32 1, ptr %16, align 4
  store i32 -1270055539, ptr %7, align 4
  %401 = xor i32 %6, -1605153957
  %402 = and i32 %6, %401
  %403 = or i32 %6, %401
  %404 = xor i32 %6, %401
  %405 = add i32 %6, %401
  %406 = sub i32 %405, %404
  %407 = mul i32 %402, 2
  %408 = sub i32 %406, %407
  %409 = mul i32 %408, 31
  %410 = icmp slt i32 %409, 1
  br i1 %410, label %855, label %1284

411:                                              ; preds = %1077
  %412 = load i32, ptr %16, align 4
  %413 = icmp sgt i32 %412, 8
  %414 = select i1 %413, i32 437303905, i32 1062507348
  store i32 %414, ptr %7, align 4
  %415 = xor i32 %6, 1378056099
  %416 = and i32 %6, %415
  %417 = or i32 %6, %415
  %418 = xor i32 %6, %415
  %419 = add i32 %6, %415
  %420 = sub i32 %419, %418
  %421 = mul i32 %416, 2
  %422 = sub i32 %420, %421
  %423 = mul i32 %422, 249
  %424 = xor i32 %6, 1900474431
  %425 = and i32 %6, %424
  %426 = or i32 %6, %424
  %427 = xor i32 %6, %424
  %428 = mul i32 %426, 2
  %429 = sub i32 %428, %427
  %430 = sub i32 %429, %6
  %431 = sub i32 %430, %424
  %432 = mul i32 %431, 137
  %433 = icmp ne i32 %423, %432
  br i1 %433, label %1296, label %855

434:                                              ; preds = %1005
  store i32 8, ptr %16, align 4
  store i32 1062507348, ptr %7, align 4
  %435 = xor i32 %6, 670845157
  %436 = and i32 %6, %435
  %437 = or i32 %6, %435
  %438 = xor i32 %6, %435
  %439 = mul i32 %437, 2
  %440 = sub i32 %439, %438
  %441 = sub i32 %440, %6
  %442 = sub i32 %441, %435
  %443 = mul i32 %442, 4
  %444 = icmp sle i32 %443, 0
  br i1 %444, label %855, label %1307

445:                                              ; preds = %1083
  %446 = load ptr, ptr %12, align 8
  store i32 0, ptr %446, align 4
  store i32 0, ptr %17, align 4
  store i32 811674546, ptr %7, align 4
  %447 = xor i32 %6, -696057343
  %448 = and i32 %6, %447
  %449 = or i32 %6, %447
  %450 = xor i32 %6, %447
  %451 = add i32 %6, %447
  %452 = sub i32 %451, %450
  %453 = mul i32 %448, 2
  %454 = sub i32 %452, %453
  %455 = mul i32 %454, 41
  %456 = icmp uge i32 %455, 0
  br i1 %456, label %855, label %1318

457:                                              ; preds = %1093
  %458 = load i32, ptr %17, align 4
  %459 = load i32, ptr %16, align 4
  %460 = icmp slt i32 %458, %459
  %461 = select i1 %460, i32 1894805403, i32 -1923848369
  store i32 %461, ptr %7, align 4
  %462 = xor i32 %6, -729782557
  %463 = and i32 %6, %462
  %464 = or i32 %6, %462
  %465 = xor i32 %6, %462
  %466 = add i32 %6, %462
  %467 = sub i32 %466, %465
  %468 = mul i32 %463, 2
  %469 = sub i32 %467, %468
  %470 = mul i32 %469, 65
  %471 = icmp slt i32 %470, 1
  br i1 %471, label %855, label %1328

472:                                              ; preds = %999
  %473 = load i32, ptr %17, align 4
  %474 = load i32, ptr %7, align 4
  %475 = xor i32 %474, 1894805401
  %476 = mul nsw i32 %473, %475
  %477 = load i32, ptr @N, align 4
  %478 = sdiv i32 %477, 2
  %479 = or i32 %476, %478
  %480 = and i32 %476, %478
  %481 = add i32 %479, %480
  %482 = load i32, ptr @N, align 4
  %483 = srem i32 %481, %482
  %484 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 0
  store i32 %483, ptr %484, align 4
  %485 = load i32, ptr %17, align 4
  %486 = load i32, ptr %7, align 4
  %487 = xor i32 %486, 1894805400
  %488 = mul nsw i32 %485, %487
  %489 = load i32, ptr %7, align 4
  %490 = xor i32 %489, 1894805402
  %491 = or i32 %488, %490
  %492 = load i32, ptr %7, align 4
  %493 = xor i32 %492, 1894805402
  %494 = and i32 %488, %493
  %495 = add i32 %491, %494
  %496 = load i32, ptr @N, align 4
  %497 = srem i32 %495, %496
  %498 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 1
  store i32 %497, ptr %498, align 4
  store i32 0, ptr %19, align 4
  store i32 264738155, ptr %7, align 4
  %499 = xor i32 %6, -191903537
  %500 = and i32 %6, %499
  %501 = or i32 %6, %499
  %502 = xor i32 %6, %499
  %503 = mul i32 %501, 2
  %504 = sub i32 %503, %502
  %505 = sub i32 %504, %6
  %506 = sub i32 %505, %499
  %507 = mul i32 %506, 78
  %508 = xor i32 %6, 751452201
  %509 = and i32 %6, %508
  %510 = or i32 %6, %508
  %511 = xor i32 %6, %508
  %512 = add i32 %6, %508
  %513 = sub i32 %512, %511
  %514 = mul i32 %509, 2
  %515 = sub i32 %513, %514
  %516 = mul i32 %515, 24
  %517 = icmp eq i32 %507, %516
  br i1 %517, label %855, label %1338

518:                                              ; preds = %1029
  %519 = load ptr, ptr %9, align 8
  %520 = load i64, ptr %18, align 4
  %521 = load i64, ptr %519, align 4
  %522 = call i32 @samePoint(i64 %520, i64 %521)
  %523 = icmp ne i32 %522, 0
  %524 = select i1 %523, i32 478722097, i32 1378052466
  store i32 %524, ptr %7, align 4
  %525 = xor i32 %6, 1133145087
  %526 = and i32 %6, %525
  %527 = or i32 %6, %525
  %528 = xor i32 %6, %525
  %529 = add i32 %6, %525
  %530 = sub i32 %529, %528
  %531 = mul i32 %526, 2
  %532 = sub i32 %530, %531
  %533 = mul i32 %532, 239
  %534 = icmp sle i32 %533, 0
  br i1 %534, label %855, label %1349

535:                                              ; preds = %1047
  %536 = load ptr, ptr %10, align 8
  %537 = load i64, ptr %18, align 4
  %538 = load i64, ptr %536, align 4
  %539 = call i32 @samePoint(i64 %537, i64 %538)
  %540 = icmp ne i32 %539, 0
  %541 = select i1 %540, i32 478722097, i32 -1927619011
  store i32 %541, ptr %7, align 4
  %542 = xor i32 %6, -925159069
  %543 = and i32 %6, %542
  %544 = or i32 %6, %542
  %545 = xor i32 %6, %542
  %546 = mul i32 %544, 2
  %547 = sub i32 %546, %545
  %548 = sub i32 %547, %6
  %549 = sub i32 %548, %542
  %550 = mul i32 %549, 228
  %551 = icmp ugt i32 %550, 0
  br i1 %551, label %1358, label %855

552:                                              ; preds = %1027
  %553 = load ptr, ptr %11, align 8
  %554 = load ptr, ptr %12, align 8
  %555 = load i32, ptr %554, align 4
  %556 = load i64, ptr %18, align 4
  %557 = call i32 @usedPoint(ptr noundef %553, i32 noundef %555, i64 %556)
  %558 = icmp ne i32 %557, 0
  store i1 false, ptr %8, align 1
  %559 = select i1 %558, i32 478722097, i32 1527403768
  store i32 %559, ptr %7, align 4
  %560 = xor i32 %6, 1426446331
  %561 = and i32 %6, %560
  %562 = or i32 %6, %560
  %563 = xor i32 %6, %560
  %564 = add i32 %6, %560
  %565 = sub i32 %564, %563
  %566 = mul i32 %561, 2
  %567 = sub i32 %565, %566
  %568 = mul i32 %567, 185
  %569 = icmp ne i32 %568, 0
  br i1 %569, label %1368, label %855

570:                                              ; preds = %1013
  %571 = load i32, ptr %19, align 4
  %572 = load i32, ptr @N, align 4
  %573 = load i32, ptr @N, align 4
  %574 = mul nsw i32 %572, %573
  %575 = icmp slt i32 %571, %574
  store i1 %575, ptr %8, align 1
  store i32 1527403768, ptr %7, align 4
  %576 = xor i32 %6, -1472118087
  %577 = and i32 %6, %576
  %578 = or i32 %6, %576
  %579 = xor i32 %6, %576
  %580 = add i32 %577, %578
  %581 = sub i32 %580, %6
  %582 = sub i32 %581, %576
  %583 = mul i32 %582, 150
  %584 = xor i32 %6, 697989241
  %585 = and i32 %6, %584
  %586 = or i32 %6, %584
  %587 = xor i32 %6, %584
  %588 = add i32 %585, %586
  %589 = sub i32 %588, %6
  %590 = sub i32 %589, %584
  %591 = mul i32 %590, 6
  %592 = icmp ne i32 %583, %591
  br i1 %592, label %1377, label %855

593:                                              ; preds = %1079
  %594 = load i1, ptr %8, align 1
  %595 = select i1 %594, i32 -484759890, i32 1811644850
  store i32 %595, ptr %7, align 4
  %596 = xor i32 %6, 1595049195
  %597 = and i32 %6, %596
  %598 = or i32 %6, %596
  %599 = xor i32 %6, %596
  %600 = sub i32 %598, %599
  %601 = sub i32 %600, %597
  %602 = mul i32 %601, 107
  %603 = xor i32 %6, -22175233
  %604 = and i32 %6, %603
  %605 = or i32 %6, %603
  %606 = xor i32 %6, %603
  %607 = add i32 %604, %605
  %608 = sub i32 %607, %6
  %609 = sub i32 %608, %603
  %610 = mul i32 %609, 207
  %611 = icmp ne i32 %602, %610
  br i1 %611, label %1387, label %855

612:                                              ; preds = %1057
  %613 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 1
  %614 = load i32, ptr %613, align 4
  %615 = load i32, ptr %7, align 4
  %616 = xor i32 %615, -484759889
  %617 = xor i32 %614, %616
  %618 = load i32, ptr %7, align 4
  %619 = xor i32 %618, -484759889
  %620 = and i32 %614, %619
  %621 = add i32 %620, %620
  %622 = add i32 %617, %621
  store i32 %622, ptr %613, align 4
  %623 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 1
  %624 = load i32, ptr %623, align 4
  %625 = load i32, ptr @N, align 4
  %626 = icmp eq i32 %624, %625
  %627 = select i1 %626, i32 1118655283, i32 1616326280
  store i32 %627, ptr %7, align 4
  %628 = xor i32 %6, 605205387
  %629 = and i32 %6, %628
  %630 = or i32 %6, %628
  %631 = xor i32 %6, %628
  %632 = mul i32 %630, 2
  %633 = sub i32 %632, %631
  %634 = sub i32 %633, %6
  %635 = sub i32 %634, %628
  %636 = mul i32 %635, 137
  %637 = icmp uge i32 %636, 0
  br i1 %637, label %855, label %1398

638:                                              ; preds = %1021
  %639 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 1
  store i32 0, ptr %639, align 4
  %640 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 0
  %641 = load i32, ptr %640, align 4
  %642 = load i32, ptr %7, align 4
  %643 = xor i32 %642, 1118655282
  %644 = or i32 %641, %643
  %645 = load i32, ptr %7, align 4
  %646 = xor i32 %645, 1118655282
  %647 = and i32 %641, %646
  %648 = add i32 %644, %647
  %649 = load i32, ptr @N, align 4
  %650 = srem i32 %648, %649
  %651 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 0
  store i32 %650, ptr %651, align 4
  store i32 1616326280, ptr %7, align 4
  %652 = xor i32 %6, 705559129
  %653 = and i32 %6, %652
  %654 = or i32 %6, %652
  %655 = xor i32 %6, %652
  %656 = mul i32 %654, 2
  %657 = sub i32 %656, %655
  %658 = sub i32 %657, %6
  %659 = sub i32 %658, %652
  %660 = mul i32 %659, 66
  %661 = icmp slt i32 %660, 0
  br i1 %661, label %1409, label %855

662:                                              ; preds = %1039
  %663 = load i32, ptr %19, align 4
  %664 = load i32, ptr %7, align 4
  %665 = xor i32 %664, 1616326281
  %666 = or i32 %663, %665
  %667 = load i32, ptr %7, align 4
  %668 = xor i32 %667, 1616326281
  %669 = and i32 %663, %668
  %670 = add i32 %666, %669
  store i32 %670, ptr %19, align 4
  store i32 264738155, ptr %7, align 4
  %671 = xor i32 %6, -1967520239
  %672 = and i32 %6, %671
  %673 = or i32 %6, %671
  %674 = xor i32 %6, %671
  %675 = add i32 %672, %673
  %676 = sub i32 %675, %6
  %677 = sub i32 %676, %671
  %678 = mul i32 %677, 160
  %679 = icmp uge i32 %678, 0
  br i1 %679, label %855, label %1421

680:                                              ; preds = %1001
  %681 = load ptr, ptr %11, align 8
  %682 = load ptr, ptr %12, align 8
  %683 = load i32, ptr %682, align 4
  %684 = sext i32 %683 to i64
  %685 = getelementptr inbounds %struct.Point, ptr %681, i64 %684
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %685, ptr align 4 %18, i64 8, i1 false)
  %686 = load ptr, ptr %12, align 8
  %687 = load i32, ptr %686, align 4
  %688 = load i32, ptr %7, align 4
  %689 = xor i32 %688, 1811644851
  %690 = sub i32 %687, %689
  %691 = load i32, ptr %7, align 4
  %692 = xor i32 %691, 1811644848
  %693 = mul i32 %687, %692
  %694 = load i32, ptr %7, align 4
  %695 = xor i32 %694, 1811644851
  %696 = mul i32 %695, %690
  %697 = sub i32 %693, %696
  store i32 %697, ptr %686, align 4
  %698 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 0
  %699 = load i32, ptr %698, align 4
  %700 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 1
  %701 = load i32, ptr %700, align 4
  %702 = load i32, ptr @N, align 4
  %703 = load i32, ptr %7, align 4
  %704 = xor i32 %703, 1811644851
  %705 = add i32 %702, %704
  %706 = load i32, ptr %7, align 4
  %707 = xor i32 %706, 1811644848
  %708 = mul i32 %702, %707
  %709 = load i32, ptr %7, align 4
  %710 = xor i32 %709, 1811644851
  %711 = mul i32 %710, %705
  %712 = sub i32 %708, %711
  call void @carveRow(i32 noundef %699, i32 noundef %701, i32 noundef %712)
  %713 = load i32, ptr @N, align 4
  %714 = load i32, ptr %7, align 4
  %715 = xor i32 %714, 1811644851
  %716 = xor i32 %713, %715
  %717 = load i32, ptr %7, align 4
  %718 = xor i32 %717, -1811644851
  %719 = xor i32 %713, %718
  %720 = load i32, ptr %7, align 4
  %721 = xor i32 %720, 1811644851
  %722 = and i32 %719, %721
  %723 = add i32 %722, %722
  %724 = sub i32 %716, %723
  %725 = getelementptr inbounds nuw %struct.Point, ptr %18, i32 0, i32 0
  %726 = load i32, ptr %725, align 4
  %727 = load i32, ptr @N, align 4
  %728 = load i32, ptr %7, align 4
  %729 = xor i32 %728, 1811644851
  %730 = xor i32 %727, %729
  %731 = load i32, ptr %7, align 4
  %732 = xor i32 %731, -1811644851
  %733 = xor i32 %727, %732
  %734 = load i32, ptr %7, align 4
  %735 = xor i32 %734, 1811644851
  %736 = and i32 %733, %735
  %737 = add i32 %736, %736
  %738 = sub i32 %730, %737
  call void @carveCol(i32 noundef %724, i32 noundef %726, i32 noundef %738)
  %739 = load i32, ptr %17, align 4
  %740 = load i32, ptr %7, align 4
  %741 = xor i32 %740, 1811644851
  %742 = or i32 %739, %741
  %743 = load i32, ptr %7, align 4
  %744 = xor i32 %743, 1811644851
  %745 = and i32 %739, %744
  %746 = add i32 %742, %745
  store i32 %746, ptr %17, align 4
  store i32 811674546, ptr %7, align 4
  %747 = xor i32 %6, 1138715427
  %748 = and i32 %6, %747
  %749 = or i32 %6, %747
  %750 = xor i32 %6, %747
  %751 = add i32 %748, %749
  %752 = sub i32 %751, %6
  %753 = sub i32 %752, %747
  %754 = mul i32 %753, 41
  %755 = icmp sle i32 %754, 0
  br i1 %755, label %855, label %1432

756:                                              ; preds = %1025
  %757 = load ptr, ptr @grid, align 8
  %758 = load ptr, ptr %9, align 8
  %759 = getelementptr inbounds nuw %struct.Point, ptr %758, i32 0, i32 0
  %760 = load i32, ptr %759, align 4
  %761 = sext i32 %760 to i64
  %762 = getelementptr inbounds ptr, ptr %757, i64 %761
  %763 = load ptr, ptr %762, align 8
  %764 = load ptr, ptr %9, align 8
  %765 = getelementptr inbounds nuw %struct.Point, ptr %764, i32 0, i32 1
  %766 = load i32, ptr %765, align 4
  %767 = sext i32 %766 to i64
  %768 = getelementptr inbounds i8, ptr %763, i64 %767
  store i8 83, ptr %768, align 1
  %769 = load ptr, ptr @grid, align 8
  %770 = load ptr, ptr %10, align 8
  %771 = getelementptr inbounds nuw %struct.Point, ptr %770, i32 0, i32 0
  %772 = load i32, ptr %771, align 4
  %773 = sext i32 %772 to i64
  %774 = getelementptr inbounds ptr, ptr %769, i64 %773
  %775 = load ptr, ptr %774, align 8
  %776 = load ptr, ptr %10, align 8
  %777 = getelementptr inbounds nuw %struct.Point, ptr %776, i32 0, i32 1
  %778 = load i32, ptr %777, align 4
  %779 = sext i32 %778 to i64
  %780 = getelementptr inbounds i8, ptr %775, i64 %779
  store i8 69, ptr %780, align 1
  store i32 0, ptr %20, align 4
  store i32 -2033371907, ptr %7, align 4
  %781 = xor i32 %6, -894009809
  %782 = and i32 %6, %781
  %783 = or i32 %6, %781
  %784 = xor i32 %6, %781
  %785 = add i32 %782, %783
  %786 = sub i32 %785, %6
  %787 = sub i32 %786, %781
  %788 = mul i32 %787, 121
  %789 = icmp uge i32 %788, 0
  br i1 %789, label %855, label %1441

790:                                              ; preds = %1011
  %791 = load i32, ptr %20, align 4
  %792 = load ptr, ptr %12, align 8
  %793 = load i32, ptr %792, align 4
  %794 = icmp slt i32 %791, %793
  %795 = select i1 %794, i32 59042622, i32 -774996585
  store i32 %795, ptr %7, align 4
  %796 = xor i32 %6, 1028907959
  %797 = and i32 %6, %796
  %798 = or i32 %6, %796
  %799 = xor i32 %6, %796
  %800 = add i32 %797, %798
  %801 = sub i32 %800, %6
  %802 = sub i32 %801, %796
  %803 = mul i32 %802, 40
  %804 = icmp slt i32 %803, 0
  br i1 %804, label %1451, label %855

805:                                              ; preds = %1115
  %806 = load ptr, ptr @grid, align 8
  %807 = load ptr, ptr %11, align 8
  %808 = load i32, ptr %20, align 4
  %809 = sext i32 %808 to i64
  %810 = getelementptr inbounds %struct.Point, ptr %807, i64 %809
  %811 = getelementptr inbounds nuw %struct.Point, ptr %810, i32 0, i32 0
  %812 = load i32, ptr %811, align 4
  %813 = sext i32 %812 to i64
  %814 = getelementptr inbounds ptr, ptr %806, i64 %813
  %815 = load ptr, ptr %814, align 8
  %816 = load ptr, ptr %11, align 8
  %817 = load i32, ptr %20, align 4
  %818 = sext i32 %817 to i64
  %819 = getelementptr inbounds %struct.Point, ptr %816, i64 %818
  %820 = getelementptr inbounds nuw %struct.Point, ptr %819, i32 0, i32 1
  %821 = load i32, ptr %820, align 4
  %822 = sext i32 %821 to i64
  %823 = getelementptr inbounds i8, ptr %815, i64 %822
  store i8 42, ptr %823, align 1
  %824 = load i32, ptr %20, align 4
  %825 = load i32, ptr %7, align 4
  %826 = xor i32 %825, 59042623
  %827 = sub i32 %824, %826
  %828 = load i32, ptr %7, align 4
  %829 = xor i32 %828, 59042620
  %830 = mul i32 %824, %829
  %831 = load i32, ptr %7, align 4
  %832 = xor i32 %831, 59042623
  %833 = mul i32 %832, %827
  %834 = sub i32 %830, %833
  store i32 %834, ptr %20, align 4
  store i32 -2033371907, ptr %7, align 4
  %835 = xor i32 %6, -1961407407
  %836 = and i32 %6, %835
  %837 = or i32 %6, %835
  %838 = xor i32 %6, %835
  %839 = add i32 %6, %835
  %840 = sub i32 %839, %838
  %841 = mul i32 %836, 2
  %842 = sub i32 %840, %841
  %843 = mul i32 %842, 229
  %844 = xor i32 %6, 896888265
  %845 = and i32 %6, %844
  %846 = or i32 %6, %844
  %847 = xor i32 %6, %844
  %848 = mul i32 %846, 2
  %849 = sub i32 %848, %847
  %850 = sub i32 %849, %6
  %851 = sub i32 %850, %844
  %852 = mul i32 %851, 218
  %853 = icmp eq i32 %843, %852
  br i1 %853, label %855, label %1460

854:                                              ; preds = %1105
  ret void

855:                                              ; preds = %1551, %1541, %1530, %1520, %1511, %1500, %1488, %1479, %1460, %1451, %1441, %1432, %1421, %1409, %1398, %1387, %1377, %1368, %1358, %1349, %1338, %1328, %1318, %1307, %1296, %1284, %1273, %1264, %1252, %1241, %1231, %1219, %1209, %1199, %1189, %1177, %1168, %1158, %1147, %1138, %1128, %1117, %969, %956, %944, %933, %911, %899, %886, %866, %805, %790, %756, %680, %662, %638, %612, %593, %570, %552, %535, %518, %472, %457, %445, %434, %411, %400, %346, %328, %308, %290, %281, %253, %234, %213, %196, %182, %163, %108, %95, %86, %73, %26
  br label %21

856:                                              ; preds = %1115, %1111, %1109, %1105, %1099, %1095, %1093, %1083, %1079, %1077, %1073, %1067, %1063, %1061, %1047, %1043, %1041, %1037, %1031, %1027, %1025, %1015, %1011, %1009, %1003, %999, %997
  store i32 -1981395056, ptr %7, align 4
  call void asm sideeffect "", ""()
  %857 = xor i32 %6, -789388825
  %858 = and i32 %6, %857
  %859 = or i32 %6, %857
  %860 = xor i32 %6, %857
  %861 = add i32 %858, %859
  %862 = sub i32 %861, %6
  %863 = sub i32 %862, %857
  %864 = mul i32 %863, 45
  %865 = icmp ne i32 %864, 0
  br i1 %865, label %1470, label %21

866:                                              ; preds = %1067
  %867 = load i32, ptr %7, align 4
  %868 = xor i32 %867, -731968240
  store i32 %868, ptr %7, align 4
  %869 = xor i32 %6, -1940824497
  %870 = and i32 %6, %869
  %871 = or i32 %6, %869
  %872 = xor i32 %6, %869
  %873 = sub i32 %871, %872
  %874 = sub i32 %873, %870
  %875 = mul i32 %874, 45
  %876 = xor i32 %6, -525140913
  %877 = and i32 %6, %876
  %878 = or i32 %6, %876
  %879 = xor i32 %6, %876
  %880 = mul i32 %878, 2
  %881 = sub i32 %880, %879
  %882 = sub i32 %881, %6
  %883 = sub i32 %882, %876
  %884 = mul i32 %883, 244
  %885 = icmp eq i32 %875, %884
  br i1 %885, label %855, label %1479

886:                                              ; preds = %1061
  %887 = load i32, ptr %7, align 4
  %888 = xor i32 %887, 1002957565
  store i32 %888, ptr %7, align 4
  %889 = xor i32 %6, -958693573
  %890 = and i32 %6, %889
  %891 = or i32 %6, %889
  %892 = xor i32 %6, %889
  %893 = add i32 %6, %889
  %894 = sub i32 %893, %892
  %895 = mul i32 %890, 2
  %896 = sub i32 %894, %895
  %897 = mul i32 %896, 246
  %898 = icmp ugt i32 %897, 0
  br i1 %898, label %1488, label %855

899:                                              ; preds = %1041
  %900 = load i32, ptr %7, align 4
  %901 = xor i32 %900, -1378594430
  store i32 %901, ptr %7, align 4
  %902 = xor i32 %6, -2141810155
  %903 = and i32 %6, %902
  %904 = or i32 %6, %902
  %905 = xor i32 %6, %902
  %906 = add i32 %903, %904
  %907 = sub i32 %906, %6
  %908 = sub i32 %907, %902
  %909 = mul i32 %908, 36
  %910 = icmp ne i32 %909, 0
  br i1 %910, label %1500, label %855

911:                                              ; preds = %1089
  %912 = load i32, ptr %7, align 4
  %913 = xor i32 %912, 723376542
  store i32 %913, ptr %7, align 4
  %914 = xor i32 %6, -2098891097
  %915 = and i32 %6, %914
  %916 = or i32 %6, %914
  %917 = xor i32 %6, %914
  %918 = add i32 %6, %914
  %919 = sub i32 %918, %917
  %920 = mul i32 %915, 2
  %921 = sub i32 %919, %920
  %922 = mul i32 %921, 142
  %923 = xor i32 %6, 1142457601
  %924 = and i32 %6, %923
  %925 = or i32 %6, %923
  %926 = xor i32 %6, %923
  %927 = add i32 %6, %923
  %928 = sub i32 %927, %926
  %929 = mul i32 %924, 2
  %930 = sub i32 %928, %929
  %931 = mul i32 %930, 29
  %932 = icmp eq i32 %922, %931
  br i1 %932, label %855, label %1511

933:                                              ; preds = %1037
  %934 = load i32, ptr %7, align 4
  %935 = xor i32 %934, 1888899721
  store i32 %935, ptr %7, align 4
  %936 = xor i32 %6, 517828041
  %937 = and i32 %6, %936
  %938 = or i32 %6, %936
  %939 = xor i32 %6, %936
  %940 = sub i32 %938, %939
  %941 = sub i32 %940, %937
  %942 = mul i32 %941, 101
  %943 = icmp eq i32 %942, 0
  br i1 %943, label %855, label %1520

944:                                              ; preds = %993
  %945 = load i32, ptr %7, align 4
  %946 = xor i32 %945, 1334458263
  store i32 %946, ptr %7, align 4
  %947 = xor i32 %6, -1457638603
  %948 = and i32 %6, %947
  %949 = or i32 %6, %947
  %950 = xor i32 %6, %947
  %951 = add i32 %948, %949
  %952 = sub i32 %951, %6
  %953 = sub i32 %952, %947
  %954 = mul i32 %953, 88
  %955 = icmp ugt i32 %954, 0
  br i1 %955, label %1530, label %855

956:                                              ; preds = %1031
  %957 = load i32, ptr %7, align 4
  %958 = xor i32 %957, 257003781
  store i32 %958, ptr %7, align 4
  %959 = xor i32 %6, -708709537
  %960 = and i32 %6, %959
  %961 = or i32 %6, %959
  %962 = xor i32 %6, %959
  %963 = add i32 %6, %959
  %964 = sub i32 %963, %962
  %965 = mul i32 %960, 2
  %966 = sub i32 %964, %965
  %967 = mul i32 %966, 62
  %968 = icmp slt i32 %967, 1
  br i1 %968, label %855, label %1541

969:                                              ; preds = %1045
  %970 = load i32, ptr %7, align 4
  %971 = xor i32 %970, 823921624
  store i32 %971, ptr %7, align 4
  %972 = xor i32 %6, 257359327
  %973 = and i32 %6, %972
  %974 = or i32 %6, %972
  %975 = xor i32 %6, %972
  %976 = add i32 %973, %974
  %977 = sub i32 %976, %6
  %978 = sub i32 %977, %972
  %979 = mul i32 %978, 85
  %980 = icmp sgt i32 %979, 0
  br i1 %980, label %1551, label %855

981:                                              ; preds = %21
  %982 = icmp slt i32 %24, 440797762
  br i1 %982, label %985, label %987

983:                                              ; preds = %21
  %984 = icmp slt i32 %24, 1671131935
  br i1 %984, label %1049, label %1051

985:                                              ; preds = %981
  %986 = icmp slt i32 %24, 194089800
  br i1 %986, label %989, label %991

987:                                              ; preds = %981
  %988 = icmp slt i32 %24, 673007876
  br i1 %988, label %1017, label %1019

989:                                              ; preds = %985
  %990 = icmp slt i32 %24, 88109514
  br i1 %990, label %993, label %995

991:                                              ; preds = %985
  %992 = icmp slt i32 %24, 277036692
  br i1 %992, label %1005, label %1007

993:                                              ; preds = %989
  %994 = icmp eq i32 %24, 19444765
  br i1 %994, label %944, label %997

995:                                              ; preds = %989
  %996 = icmp slt i32 %24, 104408781
  br i1 %996, label %999, label %1001

997:                                              ; preds = %993
  %998 = icmp eq i32 %24, 29511274
  br i1 %998, label %86, label %856

999:                                              ; preds = %995
  %1000 = icmp eq i32 %24, 88109514
  br i1 %1000, label %472, label %856

1001:                                             ; preds = %995
  %1002 = icmp eq i32 %24, 104408781
  br i1 %1002, label %680, label %1003

1003:                                             ; preds = %1001
  %1004 = icmp eq i32 %24, 117142819
  br i1 %1004, label %346, label %856

1005:                                             ; preds = %991
  %1006 = icmp eq i32 %24, 194089800
  br i1 %1006, label %434, label %1009

1007:                                             ; preds = %991
  %1008 = icmp slt i32 %24, 362212184
  br i1 %1008, label %1011, label %1013

1009:                                             ; preds = %1005
  %1010 = icmp eq i32 %24, 263597520
  br i1 %1010, label %196, label %856

1011:                                             ; preds = %1007
  %1012 = icmp eq i32 %24, 277036692
  br i1 %1012, label %790, label %856

1013:                                             ; preds = %1007
  %1014 = icmp eq i32 %24, 362212184
  br i1 %1014, label %570, label %1015

1015:                                             ; preds = %1013
  %1016 = icmp eq i32 %24, 363274252
  br i1 %1016, label %108, label %856

1017:                                             ; preds = %987
  %1018 = icmp slt i32 %24, 644479188
  br i1 %1018, label %1021, label %1023

1019:                                             ; preds = %987
  %1020 = icmp slt i32 %24, 756850492
  br i1 %1020, label %1033, label %1035

1021:                                             ; preds = %1017
  %1022 = icmp eq i32 %24, 440797762
  br i1 %1022, label %638, label %1025

1023:                                             ; preds = %1017
  %1024 = icmp slt i32 %24, 651104730
  br i1 %1024, label %1027, label %1029

1025:                                             ; preds = %1021
  %1026 = icmp eq i32 %24, 500768014
  br i1 %1026, label %756, label %856

1027:                                             ; preds = %1023
  %1028 = icmp eq i32 %24, 644479188
  br i1 %1028, label %552, label %856

1029:                                             ; preds = %1023
  %1030 = icmp eq i32 %24, 651104730
  br i1 %1030, label %518, label %1031

1031:                                             ; preds = %1029
  %1032 = icmp eq i32 %24, 660749558
  br i1 %1032, label %956, label %856

1033:                                             ; preds = %1019
  %1034 = icmp slt i32 %24, 703811995
  br i1 %1034, label %1037, label %1039

1035:                                             ; preds = %1019
  %1036 = icmp slt i32 %24, 809530373
  br i1 %1036, label %1043, label %1045

1037:                                             ; preds = %1033
  %1038 = icmp eq i32 %24, 673007876
  br i1 %1038, label %933, label %856

1039:                                             ; preds = %1033
  %1040 = icmp eq i32 %24, 703811995
  br i1 %1040, label %662, label %1041

1041:                                             ; preds = %1039
  %1042 = icmp eq i32 %24, 706150042
  br i1 %1042, label %899, label %856

1043:                                             ; preds = %1035
  %1044 = icmp eq i32 %24, 756850492
  br i1 %1044, label %182, label %856

1045:                                             ; preds = %1035
  %1046 = icmp eq i32 %24, 809530373
  br i1 %1046, label %969, label %1047

1047:                                             ; preds = %1045
  %1048 = icmp eq i32 %24, 912863629
  br i1 %1048, label %535, label %856

1049:                                             ; preds = %983
  %1050 = icmp slt i32 %24, 1266775110
  br i1 %1050, label %1053, label %1055

1051:                                             ; preds = %983
  %1052 = icmp slt i32 %24, 1807894518
  br i1 %1052, label %1085, label %1087

1053:                                             ; preds = %1049
  %1054 = icmp slt i32 %24, 1011369180
  br i1 %1054, label %1057, label %1059

1055:                                             ; preds = %1049
  %1056 = icmp slt i32 %24, 1507617483
  br i1 %1056, label %1069, label %1071

1057:                                             ; preds = %1053
  %1058 = icmp eq i32 %24, 946175993
  br i1 %1058, label %612, label %1061

1059:                                             ; preds = %1053
  %1060 = icmp slt i32 %24, 1080926184
  br i1 %1060, label %1063, label %1065

1061:                                             ; preds = %1057
  %1062 = icmp eq i32 %24, 993427510
  br i1 %1062, label %886, label %856

1063:                                             ; preds = %1059
  %1064 = icmp eq i32 %24, 1011369180
  br i1 %1064, label %290, label %856

1065:                                             ; preds = %1059
  %1066 = icmp eq i32 %24, 1080926184
  br i1 %1066, label %163, label %1067

1067:                                             ; preds = %1065
  %1068 = icmp eq i32 %24, 1102347914
  br i1 %1068, label %866, label %856

1069:                                             ; preds = %1055
  %1070 = icmp slt i32 %24, 1296666703
  br i1 %1070, label %1073, label %1075

1071:                                             ; preds = %1055
  %1072 = icmp slt i32 %24, 1551581256
  br i1 %1072, label %1079, label %1081

1073:                                             ; preds = %1069
  %1074 = icmp eq i32 %24, 1266775110
  br i1 %1074, label %213, label %856

1075:                                             ; preds = %1069
  %1076 = icmp eq i32 %24, 1296666703
  br i1 %1076, label %400, label %1077

1077:                                             ; preds = %1075
  %1078 = icmp eq i32 %24, 1464557668
  br i1 %1078, label %411, label %856

1079:                                             ; preds = %1071
  %1080 = icmp eq i32 %24, 1507617483
  br i1 %1080, label %593, label %856

1081:                                             ; preds = %1071
  %1082 = icmp eq i32 %24, 1551581256
  br i1 %1082, label %95, label %1083

1083:                                             ; preds = %1081
  %1084 = icmp eq i32 %24, 1603120343
  br i1 %1084, label %445, label %856

1085:                                             ; preds = %1051
  %1086 = icmp slt i32 %24, 1707029922
  br i1 %1086, label %1089, label %1091

1087:                                             ; preds = %1051
  %1088 = icmp slt i32 %24, 2019422531
  br i1 %1088, label %1101, label %1103

1089:                                             ; preds = %1085
  %1090 = icmp eq i32 %24, 1671131935
  br i1 %1090, label %911, label %1093

1091:                                             ; preds = %1085
  %1092 = icmp slt i32 %24, 1723619993
  br i1 %1092, label %1095, label %1097

1093:                                             ; preds = %1089
  %1094 = icmp eq i32 %24, 1698879693
  br i1 %1094, label %457, label %856

1095:                                             ; preds = %1091
  %1096 = icmp eq i32 %24, 1707029922
  br i1 %1096, label %328, label %856

1097:                                             ; preds = %1091
  %1098 = icmp eq i32 %24, 1723619993
  br i1 %1098, label %73, label %1099

1099:                                             ; preds = %1097
  %1100 = icmp eq i32 %24, 1723822287
  br i1 %1100, label %253, label %856

1101:                                             ; preds = %1087
  %1102 = icmp slt i32 %24, 1856547087
  br i1 %1102, label %1105, label %1107

1103:                                             ; preds = %1087
  %1104 = icmp slt i32 %24, 2085771348
  br i1 %1104, label %1111, label %1113

1105:                                             ; preds = %1101
  %1106 = icmp eq i32 %24, 1807894518
  br i1 %1106, label %854, label %856

1107:                                             ; preds = %1101
  %1108 = icmp eq i32 %24, 1856547087
  br i1 %1108, label %234, label %1109

1109:                                             ; preds = %1107
  %1110 = icmp eq i32 %24, 1963460163
  br i1 %1110, label %26, label %856

1111:                                             ; preds = %1103
  %1112 = icmp eq i32 %24, 2019422531
  br i1 %1112, label %281, label %856

1113:                                             ; preds = %1103
  %1114 = icmp eq i32 %24, 2085771348
  br i1 %1114, label %308, label %1115

1115:                                             ; preds = %1113
  %1116 = icmp eq i32 %24, 2106215881
  br i1 %1116, label %805, label %856

1117:                                             ; preds = %26
  %1118 = load i64, ptr %5, align 8
  %1119 = ptrtoint ptr %0 to i64
  %1120 = ptrtoint ptr %1 to i64
  %1121 = ptrtoint ptr %2 to i64
  %1122 = ptrtoint ptr %3 to i64
  %1123 = or i64 %1120, %1120
  %1124 = or i64 %1123, %1121
  %1125 = and i64 %1124, %1121
  %1126 = mul i64 %1125, %1119
  %1127 = add i64 %1126, %1118
  store i64 %1127, ptr %5, align 8
  br label %855

1128:                                             ; preds = %73
  %1129 = load i64, ptr %5, align 8
  %1130 = ptrtoint ptr %0 to i64
  %1131 = ptrtoint ptr %1 to i64
  %1132 = ptrtoint ptr %2 to i64
  %1133 = ptrtoint ptr %3 to i64
  %1134 = sub i64 %1131, %1129
  %1135 = sub i64 %1134, %1129
  %1136 = sub i64 %1135, %1133
  %1137 = xor i64 %1136, %1131
  store i64 %1137, ptr %5, align 8
  br label %855

1138:                                             ; preds = %86
  %1139 = load i64, ptr %5, align 8
  %1140 = ptrtoint ptr %0 to i64
  %1141 = ptrtoint ptr %1 to i64
  %1142 = ptrtoint ptr %2 to i64
  %1143 = ptrtoint ptr %3 to i64
  %1144 = add i64 %1140, %1139
  %1145 = or i64 %1144, %1139
  %1146 = add i64 %1145, %1141
  store i64 %1146, ptr %5, align 8
  br label %855

1147:                                             ; preds = %95
  %1148 = load i64, ptr %5, align 8
  %1149 = ptrtoint ptr %0 to i64
  %1150 = ptrtoint ptr %1 to i64
  %1151 = ptrtoint ptr %2 to i64
  %1152 = ptrtoint ptr %3 to i64
  %1153 = add i64 %1149, %1151
  %1154 = add i64 %1153, %1148
  %1155 = sub i64 %1154, %1151
  %1156 = add i64 %1155, %1149
  %1157 = mul i64 %1156, %1150
  store i64 %1157, ptr %5, align 8
  br label %855

1158:                                             ; preds = %108
  %1159 = load i64, ptr %5, align 8
  %1160 = ptrtoint ptr %0 to i64
  %1161 = ptrtoint ptr %1 to i64
  %1162 = ptrtoint ptr %2 to i64
  %1163 = ptrtoint ptr %3 to i64
  %1164 = sub i64 %1162, %1159
  %1165 = sub i64 %1164, %1160
  %1166 = mul i64 %1165, %1161
  %1167 = mul i64 %1166, %1161
  store i64 %1167, ptr %5, align 8
  br label %855

1168:                                             ; preds = %163
  %1169 = load i64, ptr %5, align 8
  %1170 = ptrtoint ptr %0 to i64
  %1171 = ptrtoint ptr %1 to i64
  %1172 = ptrtoint ptr %2 to i64
  %1173 = ptrtoint ptr %3 to i64
  %1174 = or i64 %1172, %1173
  %1175 = xor i64 %1174, %1173
  %1176 = xor i64 %1175, %1171
  store i64 %1176, ptr %5, align 8
  br label %855

1177:                                             ; preds = %182
  %1178 = load i64, ptr %5, align 8
  %1179 = ptrtoint ptr %0 to i64
  %1180 = ptrtoint ptr %1 to i64
  %1181 = ptrtoint ptr %2 to i64
  %1182 = ptrtoint ptr %3 to i64
  %1183 = mul i64 %1178, %1182
  %1184 = mul i64 %1183, %1181
  %1185 = add i64 %1184, %1178
  %1186 = and i64 %1185, %1179
  %1187 = and i64 %1186, %1181
  %1188 = sub i64 %1187, %1180
  store i64 %1188, ptr %5, align 8
  br label %855

1189:                                             ; preds = %196
  %1190 = load i64, ptr %5, align 8
  %1191 = ptrtoint ptr %0 to i64
  %1192 = ptrtoint ptr %1 to i64
  %1193 = ptrtoint ptr %2 to i64
  %1194 = ptrtoint ptr %3 to i64
  %1195 = or i64 %1191, %1192
  %1196 = add i64 %1195, %1190
  %1197 = sub i64 %1196, %1190
  %1198 = and i64 %1197, %1191
  store i64 %1198, ptr %5, align 8
  br label %855

1199:                                             ; preds = %213
  %1200 = load i64, ptr %5, align 8
  %1201 = ptrtoint ptr %0 to i64
  %1202 = ptrtoint ptr %1 to i64
  %1203 = ptrtoint ptr %2 to i64
  %1204 = ptrtoint ptr %3 to i64
  %1205 = or i64 %1202, %1203
  %1206 = or i64 %1205, %1203
  %1207 = xor i64 %1206, %1202
  %1208 = and i64 %1207, %1203
  store i64 %1208, ptr %5, align 8
  br label %855

1209:                                             ; preds = %234
  %1210 = load i64, ptr %5, align 8
  %1211 = ptrtoint ptr %0 to i64
  %1212 = ptrtoint ptr %1 to i64
  %1213 = ptrtoint ptr %2 to i64
  %1214 = ptrtoint ptr %3 to i64
  %1215 = or i64 %1210, %1210
  %1216 = and i64 %1215, %1212
  %1217 = sub i64 %1216, %1213
  %1218 = or i64 %1217, %1211
  store i64 %1218, ptr %5, align 8
  br label %855

1219:                                             ; preds = %253
  %1220 = load i64, ptr %5, align 8
  %1221 = ptrtoint ptr %0 to i64
  %1222 = ptrtoint ptr %1 to i64
  %1223 = ptrtoint ptr %2 to i64
  %1224 = ptrtoint ptr %3 to i64
  %1225 = add i64 %1222, %1221
  %1226 = xor i64 %1225, %1223
  %1227 = sub i64 %1226, %1222
  %1228 = and i64 %1227, %1221
  %1229 = xor i64 %1228, %1220
  %1230 = and i64 %1229, %1220
  store i64 %1230, ptr %5, align 8
  br label %855

1231:                                             ; preds = %281
  %1232 = load i64, ptr %5, align 8
  %1233 = ptrtoint ptr %0 to i64
  %1234 = ptrtoint ptr %1 to i64
  %1235 = ptrtoint ptr %2 to i64
  %1236 = ptrtoint ptr %3 to i64
  %1237 = and i64 %1234, %1236
  %1238 = add i64 %1237, %1236
  %1239 = sub i64 %1238, %1236
  %1240 = and i64 %1239, %1234
  store i64 %1240, ptr %5, align 8
  br label %855

1241:                                             ; preds = %290
  %1242 = load i64, ptr %5, align 8
  %1243 = ptrtoint ptr %0 to i64
  %1244 = ptrtoint ptr %1 to i64
  %1245 = ptrtoint ptr %2 to i64
  %1246 = ptrtoint ptr %3 to i64
  %1247 = add i64 %1242, %1243
  %1248 = mul i64 %1247, %1246
  %1249 = add i64 %1248, %1245
  %1250 = add i64 %1249, %1246
  %1251 = mul i64 %1250, %1245
  store i64 %1251, ptr %5, align 8
  br label %855

1252:                                             ; preds = %308
  %1253 = load i64, ptr %5, align 8
  %1254 = ptrtoint ptr %0 to i64
  %1255 = ptrtoint ptr %1 to i64
  %1256 = ptrtoint ptr %2 to i64
  %1257 = ptrtoint ptr %3 to i64
  %1258 = xor i64 %1256, %1253
  %1259 = add i64 %1258, %1255
  %1260 = add i64 %1259, %1257
  %1261 = sub i64 %1260, %1255
  %1262 = add i64 %1261, %1253
  %1263 = and i64 %1262, %1253
  store i64 %1263, ptr %5, align 8
  br label %855

1264:                                             ; preds = %328
  %1265 = load i64, ptr %5, align 8
  %1266 = ptrtoint ptr %0 to i64
  %1267 = ptrtoint ptr %1 to i64
  %1268 = ptrtoint ptr %2 to i64
  %1269 = ptrtoint ptr %3 to i64
  %1270 = and i64 %1269, %1268
  %1271 = and i64 %1270, %1269
  %1272 = add i64 %1271, %1265
  store i64 %1272, ptr %5, align 8
  br label %855

1273:                                             ; preds = %346
  %1274 = load i64, ptr %5, align 8
  %1275 = ptrtoint ptr %0 to i64
  %1276 = ptrtoint ptr %1 to i64
  %1277 = ptrtoint ptr %2 to i64
  %1278 = ptrtoint ptr %3 to i64
  %1279 = add i64 %1275, %1275
  %1280 = and i64 %1279, %1274
  %1281 = and i64 %1280, %1275
  %1282 = sub i64 %1281, %1276
  %1283 = or i64 %1282, %1277
  store i64 %1283, ptr %5, align 8
  br label %855

1284:                                             ; preds = %400
  %1285 = load i64, ptr %5, align 8
  %1286 = ptrtoint ptr %0 to i64
  %1287 = ptrtoint ptr %1 to i64
  %1288 = ptrtoint ptr %2 to i64
  %1289 = ptrtoint ptr %3 to i64
  %1290 = sub i64 %1285, %1289
  %1291 = sub i64 %1290, %1285
  %1292 = xor i64 %1291, %1288
  %1293 = or i64 %1292, %1286
  %1294 = sub i64 %1293, %1285
  %1295 = add i64 %1294, %1287
  store i64 %1295, ptr %5, align 8
  br label %855

1296:                                             ; preds = %411
  %1297 = load i64, ptr %5, align 8
  %1298 = ptrtoint ptr %0 to i64
  %1299 = ptrtoint ptr %1 to i64
  %1300 = ptrtoint ptr %2 to i64
  %1301 = ptrtoint ptr %3 to i64
  %1302 = xor i64 %1300, %1298
  %1303 = xor i64 %1302, %1301
  %1304 = xor i64 %1303, %1300
  %1305 = or i64 %1304, %1297
  %1306 = add i64 %1305, %1299
  store i64 %1306, ptr %5, align 8
  br label %855

1307:                                             ; preds = %434
  %1308 = load i64, ptr %5, align 8
  %1309 = ptrtoint ptr %0 to i64
  %1310 = ptrtoint ptr %1 to i64
  %1311 = ptrtoint ptr %2 to i64
  %1312 = ptrtoint ptr %3 to i64
  %1313 = sub i64 %1311, %1308
  %1314 = and i64 %1313, %1312
  %1315 = add i64 %1314, %1312
  %1316 = add i64 %1315, %1309
  %1317 = mul i64 %1316, %1312
  store i64 %1317, ptr %5, align 8
  br label %855

1318:                                             ; preds = %445
  %1319 = load i64, ptr %5, align 8
  %1320 = ptrtoint ptr %0 to i64
  %1321 = ptrtoint ptr %1 to i64
  %1322 = ptrtoint ptr %2 to i64
  %1323 = ptrtoint ptr %3 to i64
  %1324 = xor i64 %1323, %1319
  %1325 = or i64 %1324, %1319
  %1326 = sub i64 %1325, %1319
  %1327 = xor i64 %1326, %1321
  store i64 %1327, ptr %5, align 8
  br label %855

1328:                                             ; preds = %457
  %1329 = load i64, ptr %5, align 8
  %1330 = ptrtoint ptr %0 to i64
  %1331 = ptrtoint ptr %1 to i64
  %1332 = ptrtoint ptr %2 to i64
  %1333 = ptrtoint ptr %3 to i64
  %1334 = or i64 %1333, %1332
  %1335 = or i64 %1334, %1333
  %1336 = add i64 %1335, %1329
  %1337 = or i64 %1336, %1333
  store i64 %1337, ptr %5, align 8
  br label %855

1338:                                             ; preds = %472
  %1339 = load i64, ptr %5, align 8
  %1340 = ptrtoint ptr %0 to i64
  %1341 = ptrtoint ptr %1 to i64
  %1342 = ptrtoint ptr %2 to i64
  %1343 = ptrtoint ptr %3 to i64
  %1344 = mul i64 %1343, %1341
  %1345 = and i64 %1344, %1343
  %1346 = sub i64 %1345, %1340
  %1347 = and i64 %1346, %1339
  %1348 = sub i64 %1347, %1343
  store i64 %1348, ptr %5, align 8
  br label %855

1349:                                             ; preds = %518
  %1350 = load i64, ptr %5, align 8
  %1351 = ptrtoint ptr %0 to i64
  %1352 = ptrtoint ptr %1 to i64
  %1353 = ptrtoint ptr %2 to i64
  %1354 = ptrtoint ptr %3 to i64
  %1355 = and i64 %1352, %1353
  %1356 = mul i64 %1355, %1350
  %1357 = add i64 %1356, %1353
  store i64 %1357, ptr %5, align 8
  br label %855

1358:                                             ; preds = %535
  %1359 = load i64, ptr %5, align 8
  %1360 = ptrtoint ptr %0 to i64
  %1361 = ptrtoint ptr %1 to i64
  %1362 = ptrtoint ptr %2 to i64
  %1363 = ptrtoint ptr %3 to i64
  %1364 = sub i64 %1359, %1362
  %1365 = xor i64 %1364, %1359
  %1366 = xor i64 %1365, %1360
  %1367 = xor i64 %1366, %1359
  store i64 %1367, ptr %5, align 8
  br label %855

1368:                                             ; preds = %552
  %1369 = load i64, ptr %5, align 8
  %1370 = ptrtoint ptr %0 to i64
  %1371 = ptrtoint ptr %1 to i64
  %1372 = ptrtoint ptr %2 to i64
  %1373 = ptrtoint ptr %3 to i64
  %1374 = or i64 %1372, %1369
  %1375 = mul i64 %1374, %1373
  %1376 = xor i64 %1375, %1373
  store i64 %1376, ptr %5, align 8
  br label %855

1377:                                             ; preds = %570
  %1378 = load i64, ptr %5, align 8
  %1379 = ptrtoint ptr %0 to i64
  %1380 = ptrtoint ptr %1 to i64
  %1381 = ptrtoint ptr %2 to i64
  %1382 = ptrtoint ptr %3 to i64
  %1383 = mul i64 %1379, %1382
  %1384 = or i64 %1383, %1382
  %1385 = add i64 %1384, %1381
  %1386 = mul i64 %1385, %1380
  store i64 %1386, ptr %5, align 8
  br label %855

1387:                                             ; preds = %593
  %1388 = load i64, ptr %5, align 8
  %1389 = ptrtoint ptr %0 to i64
  %1390 = ptrtoint ptr %1 to i64
  %1391 = ptrtoint ptr %2 to i64
  %1392 = ptrtoint ptr %3 to i64
  %1393 = mul i64 %1392, %1388
  %1394 = or i64 %1393, %1388
  %1395 = sub i64 %1394, %1392
  %1396 = sub i64 %1395, %1390
  %1397 = add i64 %1396, %1392
  store i64 %1397, ptr %5, align 8
  br label %855

1398:                                             ; preds = %612
  %1399 = load i64, ptr %5, align 8
  %1400 = ptrtoint ptr %0 to i64
  %1401 = ptrtoint ptr %1 to i64
  %1402 = ptrtoint ptr %2 to i64
  %1403 = ptrtoint ptr %3 to i64
  %1404 = or i64 %1402, %1402
  %1405 = xor i64 %1404, %1400
  %1406 = xor i64 %1405, %1401
  %1407 = sub i64 %1406, %1399
  %1408 = xor i64 %1407, %1402
  store i64 %1408, ptr %5, align 8
  br label %855

1409:                                             ; preds = %638
  %1410 = load i64, ptr %5, align 8
  %1411 = ptrtoint ptr %0 to i64
  %1412 = ptrtoint ptr %1 to i64
  %1413 = ptrtoint ptr %2 to i64
  %1414 = ptrtoint ptr %3 to i64
  %1415 = xor i64 %1411, %1412
  %1416 = sub i64 %1415, %1414
  %1417 = or i64 %1416, %1411
  %1418 = and i64 %1417, %1413
  %1419 = or i64 %1418, %1410
  %1420 = sub i64 %1419, %1413
  store i64 %1420, ptr %5, align 8
  br label %855

1421:                                             ; preds = %662
  %1422 = load i64, ptr %5, align 8
  %1423 = ptrtoint ptr %0 to i64
  %1424 = ptrtoint ptr %1 to i64
  %1425 = ptrtoint ptr %2 to i64
  %1426 = ptrtoint ptr %3 to i64
  %1427 = mul i64 %1422, %1422
  %1428 = and i64 %1427, %1424
  %1429 = mul i64 %1428, %1422
  %1430 = xor i64 %1429, %1422
  %1431 = or i64 %1430, %1422
  store i64 %1431, ptr %5, align 8
  br label %855

1432:                                             ; preds = %680
  %1433 = load i64, ptr %5, align 8
  %1434 = ptrtoint ptr %0 to i64
  %1435 = ptrtoint ptr %1 to i64
  %1436 = ptrtoint ptr %2 to i64
  %1437 = ptrtoint ptr %3 to i64
  %1438 = mul i64 %1433, %1436
  %1439 = and i64 %1438, %1434
  %1440 = mul i64 %1439, %1436
  store i64 %1440, ptr %5, align 8
  br label %855

1441:                                             ; preds = %756
  %1442 = load i64, ptr %5, align 8
  %1443 = ptrtoint ptr %0 to i64
  %1444 = ptrtoint ptr %1 to i64
  %1445 = ptrtoint ptr %2 to i64
  %1446 = ptrtoint ptr %3 to i64
  %1447 = and i64 %1444, %1443
  %1448 = mul i64 %1447, %1443
  %1449 = sub i64 %1448, %1443
  %1450 = mul i64 %1449, %1446
  store i64 %1450, ptr %5, align 8
  br label %855

1451:                                             ; preds = %790
  %1452 = load i64, ptr %5, align 8
  %1453 = ptrtoint ptr %0 to i64
  %1454 = ptrtoint ptr %1 to i64
  %1455 = ptrtoint ptr %2 to i64
  %1456 = ptrtoint ptr %3 to i64
  %1457 = mul i64 %1452, %1454
  %1458 = mul i64 %1457, %1452
  %1459 = mul i64 %1458, %1452
  store i64 %1459, ptr %5, align 8
  br label %855

1460:                                             ; preds = %805
  %1461 = load i64, ptr %5, align 8
  %1462 = ptrtoint ptr %0 to i64
  %1463 = ptrtoint ptr %1 to i64
  %1464 = ptrtoint ptr %2 to i64
  %1465 = ptrtoint ptr %3 to i64
  %1466 = add i64 %1461, %1462
  %1467 = mul i64 %1466, %1462
  %1468 = add i64 %1467, %1461
  %1469 = sub i64 %1468, %1463
  store i64 %1469, ptr %5, align 8
  br label %855

1470:                                             ; preds = %856
  %1471 = load i64, ptr %5, align 8
  %1472 = ptrtoint ptr %0 to i64
  %1473 = ptrtoint ptr %1 to i64
  %1474 = ptrtoint ptr %2 to i64
  %1475 = ptrtoint ptr %3 to i64
  %1476 = sub i64 %1473, %1474
  %1477 = xor i64 %1476, %1475
  %1478 = add i64 %1477, %1473
  store i64 %1478, ptr %5, align 8
  br label %21

1479:                                             ; preds = %866
  %1480 = load i64, ptr %5, align 8
  %1481 = ptrtoint ptr %0 to i64
  %1482 = ptrtoint ptr %1 to i64
  %1483 = ptrtoint ptr %2 to i64
  %1484 = ptrtoint ptr %3 to i64
  %1485 = add i64 %1483, %1483
  %1486 = mul i64 %1485, %1480
  %1487 = add i64 %1486, %1482
  store i64 %1487, ptr %5, align 8
  br label %855

1488:                                             ; preds = %886
  %1489 = load i64, ptr %5, align 8
  %1490 = ptrtoint ptr %0 to i64
  %1491 = ptrtoint ptr %1 to i64
  %1492 = ptrtoint ptr %2 to i64
  %1493 = ptrtoint ptr %3 to i64
  %1494 = sub i64 %1490, %1490
  %1495 = xor i64 %1494, %1489
  %1496 = sub i64 %1495, %1492
  %1497 = add i64 %1496, %1489
  %1498 = and i64 %1497, %1492
  %1499 = xor i64 %1498, %1490
  store i64 %1499, ptr %5, align 8
  br label %855

1500:                                             ; preds = %899
  %1501 = load i64, ptr %5, align 8
  %1502 = ptrtoint ptr %0 to i64
  %1503 = ptrtoint ptr %1 to i64
  %1504 = ptrtoint ptr %2 to i64
  %1505 = ptrtoint ptr %3 to i64
  %1506 = sub i64 %1503, %1505
  %1507 = sub i64 %1506, %1502
  %1508 = or i64 %1507, %1501
  %1509 = sub i64 %1508, %1502
  %1510 = or i64 %1509, %1501
  store i64 %1510, ptr %5, align 8
  br label %855

1511:                                             ; preds = %911
  %1512 = load i64, ptr %5, align 8
  %1513 = ptrtoint ptr %0 to i64
  %1514 = ptrtoint ptr %1 to i64
  %1515 = ptrtoint ptr %2 to i64
  %1516 = ptrtoint ptr %3 to i64
  %1517 = and i64 %1515, %1514
  %1518 = and i64 %1517, %1516
  %1519 = mul i64 %1518, %1516
  store i64 %1519, ptr %5, align 8
  br label %855

1520:                                             ; preds = %933
  %1521 = load i64, ptr %5, align 8
  %1522 = ptrtoint ptr %0 to i64
  %1523 = ptrtoint ptr %1 to i64
  %1524 = ptrtoint ptr %2 to i64
  %1525 = ptrtoint ptr %3 to i64
  %1526 = sub i64 %1525, %1522
  %1527 = mul i64 %1526, %1525
  %1528 = add i64 %1527, %1524
  %1529 = add i64 %1528, %1522
  store i64 %1529, ptr %5, align 8
  br label %855

1530:                                             ; preds = %944
  %1531 = load i64, ptr %5, align 8
  %1532 = ptrtoint ptr %0 to i64
  %1533 = ptrtoint ptr %1 to i64
  %1534 = ptrtoint ptr %2 to i64
  %1535 = ptrtoint ptr %3 to i64
  %1536 = sub i64 %1532, %1532
  %1537 = sub i64 %1536, %1533
  %1538 = mul i64 %1537, %1535
  %1539 = mul i64 %1538, %1532
  %1540 = or i64 %1539, %1531
  store i64 %1540, ptr %5, align 8
  br label %855

1541:                                             ; preds = %956
  %1542 = load i64, ptr %5, align 8
  %1543 = ptrtoint ptr %0 to i64
  %1544 = ptrtoint ptr %1 to i64
  %1545 = ptrtoint ptr %2 to i64
  %1546 = ptrtoint ptr %3 to i64
  %1547 = or i64 %1546, %1543
  %1548 = add i64 %1547, %1545
  %1549 = xor i64 %1548, %1545
  %1550 = and i64 %1549, %1542
  store i64 %1550, ptr %5, align 8
  br label %855

1551:                                             ; preds = %969
  %1552 = load i64, ptr %5, align 8
  %1553 = ptrtoint ptr %0 to i64
  %1554 = ptrtoint ptr %1 to i64
  %1555 = ptrtoint ptr %2 to i64
  %1556 = ptrtoint ptr %3 to i64
  %1557 = xor i64 %1554, %1552
  %1558 = sub i64 %1557, %1552
  %1559 = xor i64 %1558, %1555
  %1560 = xor i64 %1559, %1553
  store i64 %1560, ptr %5, align 8
  br label %855
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @dijkstra(i64 %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca %struct.Point, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca ptr, align 8
  %13 = alloca %struct.Point, align 4
  %14 = alloca %struct.Point, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  store i32 -1448256776, ptr %5, align 4
  br label %20

20:                                               ; preds = %802, %416, %415, %3
  %21 = load i32, ptr %5, align 4
  %22 = sub i32 %21, 2084662404
  %23 = mul i32 %22, 567877541
  %24 = icmp slt i32 %23, 1272149167
  br i1 %24, label %542, label %544

25:                                               ; preds = %618
  store i64 %0, ptr %6, align 4
  store ptr %1, ptr %7, align 8
  store ptr %2, ptr %8, align 8
  %26 = load i32, ptr @N, align 4
  %27 = load i32, ptr @N, align 4
  %28 = mul nsw i32 %26, %27
  store i32 %28, ptr %9, align 4
  store i32 0, ptr %10, align 4
  store i32 641789607, ptr %5, align 4
  %29 = xor i64 %0, 1403707850281782497
  %30 = and i64 %0, %29
  %31 = or i64 %0, %29
  %32 = xor i64 %0, %29
  %33 = mul i64 %31, 2
  %34 = sub i64 %33, %32
  %35 = sub i64 %34, %0
  %36 = sub i64 %35, %29
  %37 = mul i64 %36, 236
  %38 = icmp ne i64 %37, 0
  br i1 %38, label %628, label %415

39:                                               ; preds = %598
  %40 = load i32, ptr %10, align 4
  %41 = load i32, ptr %9, align 4
  %42 = icmp slt i32 %40, %41
  %43 = select i1 %42, i32 -631991654, i32 2112845813
  store i32 %43, ptr %5, align 4
  %44 = xor i64 %0, -2787960304603077265
  %45 = and i64 %0, %44
  %46 = or i64 %0, %44
  %47 = xor i64 %0, %44
  %48 = mul i64 %46, 2
  %49 = sub i64 %48, %47
  %50 = sub i64 %49, %0
  %51 = sub i64 %50, %44
  %52 = mul i64 %51, 111
  %53 = icmp ugt i64 %52, 0
  br i1 %53, label %638, label %415

54:                                               ; preds = %572
  %55 = load ptr, ptr %7, align 8
  %56 = load i32, ptr %10, align 4
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds i32, ptr %55, i64 %57
  store i32 1000000000, ptr %58, align 4
  %59 = load ptr, ptr %8, align 8
  %60 = load i32, ptr %10, align 4
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds i32, ptr %59, i64 %61
  store i32 -1, ptr %62, align 4
  %63 = load i32, ptr %10, align 4
  %64 = load i32, ptr %5, align 4
  %65 = xor i32 %64, -631991653
  %66 = xor i32 %63, %65
  %67 = load i32, ptr %5, align 4
  %68 = xor i32 %67, -631991653
  %69 = and i32 %63, %68
  %70 = add i32 %69, %69
  %71 = add i32 %66, %70
  store i32 %71, ptr %10, align 4
  store i32 641789607, ptr %5, align 4
  %72 = xor i64 %0, 3420482022440370765
  %73 = and i64 %0, %72
  %74 = or i64 %0, %72
  %75 = xor i64 %0, %72
  %76 = sub i64 %74, %75
  %77 = sub i64 %76, %73
  %78 = mul i64 %77, 202
  %79 = xor i64 %0, 5611861972648978489
  %80 = and i64 %0, %79
  %81 = or i64 %0, %79
  %82 = xor i64 %0, %79
  %83 = mul i64 %81, 2
  %84 = sub i64 %83, %82
  %85 = sub i64 %84, %0
  %86 = sub i64 %85, %79
  %87 = mul i64 %86, 210
  %88 = icmp ne i64 %78, %87
  br i1 %88, label %646, label %415

89:                                               ; preds = %614
  %90 = getelementptr inbounds nuw %struct.Point, ptr %6, i32 0, i32 0
  %91 = load i32, ptr %90, align 4
  %92 = getelementptr inbounds nuw %struct.Point, ptr %6, i32 0, i32 1
  %93 = load i32, ptr %92, align 4
  %94 = call i32 @idOf(i32 noundef %91, i32 noundef %93)
  store i32 %94, ptr %11, align 4
  %95 = load ptr, ptr %7, align 8
  %96 = load i32, ptr %11, align 4
  %97 = sext i32 %96 to i64
  %98 = getelementptr inbounds i32, ptr %95, i64 %97
  store i32 0, ptr %98, align 4
  %99 = load i32, ptr %9, align 4
  %100 = load i32, ptr %5, align 4
  %101 = xor i32 %100, 2112845809
  %102 = mul nsw i32 %99, %101
  %103 = load i32, ptr %5, align 4
  %104 = xor i32 %103, 2112845713
  %105 = or i32 %102, %104
  %106 = load i32, ptr %5, align 4
  %107 = xor i32 %106, 2112845713
  %108 = and i32 %102, %107
  %109 = add i32 %105, %108
  %110 = call ptr @createHeap(i32 noundef %109)
  store ptr %110, ptr %12, align 8
  %111 = load ptr, ptr %12, align 8
  %112 = load i32, ptr %11, align 4
  call void @pushHeap(ptr noundef %111, i32 noundef %112, i32 noundef 0)
  store i32 -2056834105, ptr %5, align 4
  %113 = xor i64 %0, -3926270446076609709
  %114 = and i64 %0, %113
  %115 = or i64 %0, %113
  %116 = xor i64 %0, %113
  %117 = sub i64 %115, %116
  %118 = sub i64 %117, %114
  %119 = mul i64 %118, 235
  %120 = icmp uge i64 %119, 0
  br i1 %120, label %415, label %655

121:                                              ; preds = %558
  %122 = load ptr, ptr %12, align 8
  %123 = call i32 @emptyHeap(ptr noundef %122)
  %124 = icmp ne i32 %123, 0
  %125 = xor i1 %124, true
  %126 = select i1 %125, i32 98116811, i32 2144504710
  store i32 %126, ptr %5, align 4
  %127 = xor i64 %0, 4260735709495949497
  %128 = and i64 %0, %127
  %129 = or i64 %0, %127
  %130 = xor i64 %0, %127
  %131 = add i64 %128, %129
  %132 = sub i64 %131, %0
  %133 = sub i64 %132, %127
  %134 = mul i64 %133, 176
  %135 = icmp eq i64 %134, 0
  br i1 %135, label %415, label %664

136:                                              ; preds = %612
  %137 = load ptr, ptr %12, align 8
  %138 = call i64 @popHeap(ptr noundef %137)
  store i64 %138, ptr %13, align 4
  %139 = getelementptr inbounds nuw %struct.Point, ptr %13, i32 0, i32 1
  %140 = load i32, ptr %139, align 4
  %141 = load ptr, ptr %7, align 8
  %142 = getelementptr inbounds nuw %struct.Point, ptr %13, i32 0, i32 0
  %143 = load i32, ptr %142, align 4
  %144 = sext i32 %143 to i64
  %145 = getelementptr inbounds i32, ptr %141, i64 %144
  %146 = load i32, ptr %145, align 4
  %147 = icmp ne i32 %140, %146
  %148 = select i1 %147, i32 -1425223232, i32 1942582973
  store i32 %148, ptr %5, align 4
  %149 = xor i64 %0, -1639023140408388867
  %150 = and i64 %0, %149
  %151 = or i64 %0, %149
  %152 = xor i64 %0, %149
  %153 = add i64 %150, %151
  %154 = sub i64 %153, %0
  %155 = sub i64 %154, %149
  %156 = mul i64 %155, 121
  %157 = icmp eq i64 %156, 0
  br i1 %157, label %415, label %673

158:                                              ; preds = %604
  store i32 -2056834105, ptr %5, align 4
  %159 = xor i64 %0, 2157536041495593197
  %160 = and i64 %0, %159
  %161 = or i64 %0, %159
  %162 = xor i64 %0, %159
  %163 = sub i64 %161, %162
  %164 = sub i64 %163, %160
  %165 = mul i64 %164, 219
  %166 = icmp ugt i64 %165, 0
  br i1 %166, label %683, label %415

167:                                              ; preds = %564
  %168 = getelementptr inbounds nuw %struct.Point, ptr %13, i32 0, i32 0
  %169 = load i32, ptr %168, align 4
  %170 = call i64 @pointOf(i32 noundef %169)
  store i64 %170, ptr %14, align 4
  store i32 0, ptr %15, align 4
  store i32 869002383, ptr %5, align 4
  %171 = xor i64 %0, 4397806686019995659
  %172 = and i64 %0, %171
  %173 = or i64 %0, %171
  %174 = xor i64 %0, %171
  %175 = mul i64 %173, 2
  %176 = sub i64 %175, %174
  %177 = sub i64 %176, %0
  %178 = sub i64 %177, %171
  %179 = mul i64 %178, 153
  %180 = icmp slt i64 %179, 1
  br i1 %180, label %415, label %690

181:                                              ; preds = %560
  %182 = load i32, ptr %15, align 4
  %183 = icmp slt i32 %182, 4
  %184 = select i1 %183, i32 -1796112946, i32 -2002572846
  store i32 %184, ptr %5, align 4
  %185 = xor i64 %0, 6940680896185733183
  %186 = and i64 %0, %185
  %187 = or i64 %0, %185
  %188 = xor i64 %0, %185
  %189 = add i64 %0, %185
  %190 = sub i64 %189, %188
  %191 = mul i64 %186, 2
  %192 = sub i64 %190, %191
  %193 = mul i64 %192, 116
  %194 = icmp slt i64 %193, 1
  br i1 %194, label %415, label %700

195:                                              ; preds = %620
  %196 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 0
  %197 = load i32, ptr %196, align 4
  %198 = load i32, ptr %15, align 4
  %199 = sext i32 %198 to i64
  %200 = getelementptr inbounds [4 x i32], ptr @dr, i64 0, i64 %199
  %201 = load i32, ptr %200, align 4
  %202 = load i32, ptr %5, align 4
  %203 = xor i32 %202, -1796112945
  %204 = add i32 %201, %203
  %205 = load i32, ptr %5, align 4
  %206 = xor i32 %205, -1796112945
  %207 = sub i32 %197, %206
  %208 = mul i32 %197, %204
  %209 = mul i32 %201, %207
  %210 = sub i32 %208, %209
  store i32 %210, ptr %16, align 4
  %211 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 1
  %212 = load i32, ptr %211, align 4
  %213 = load i32, ptr %15, align 4
  %214 = sext i32 %213 to i64
  %215 = getelementptr inbounds [4 x i32], ptr @dc, i64 0, i64 %214
  %216 = load i32, ptr %215, align 4
  %217 = xor i32 %212, %216
  %218 = and i32 %212, %216
  %219 = add i32 %218, %218
  %220 = add i32 %217, %219
  store i32 %220, ptr %17, align 4
  %221 = load i32, ptr %16, align 4
  %222 = load i32, ptr %17, align 4
  %223 = call i32 @inside(i32 noundef %221, i32 noundef %222)
  %224 = icmp ne i32 %223, 0
  %225 = select i1 %224, i32 1365064363, i32 -2144775898
  store i32 %225, ptr %5, align 4
  %226 = xor i64 %0, -4487560909365273307
  %227 = and i64 %0, %226
  %228 = or i64 %0, %226
  %229 = xor i64 %0, %226
  %230 = sub i64 %228, %229
  %231 = sub i64 %230, %227
  %232 = mul i64 %231, 134
  %233 = icmp slt i64 %232, 1
  br i1 %233, label %415, label %710

234:                                              ; preds = %580
  store i32 -789448312, ptr %5, align 4
  %235 = xor i64 %0, 4367657247753004115
  %236 = and i64 %0, %235
  %237 = or i64 %0, %235
  %238 = xor i64 %0, %235
  %239 = sub i64 %237, %238
  %240 = sub i64 %239, %236
  %241 = mul i64 %240, 112
  %242 = icmp sgt i64 %241, 0
  br i1 %242, label %717, label %415

243:                                              ; preds = %622
  %244 = load ptr, ptr @grid, align 8
  %245 = load i32, ptr %16, align 4
  %246 = sext i32 %245 to i64
  %247 = getelementptr inbounds ptr, ptr %244, i64 %246
  %248 = load ptr, ptr %247, align 8
  %249 = load i32, ptr %17, align 4
  %250 = sext i32 %249 to i64
  %251 = getelementptr inbounds i8, ptr %248, i64 %250
  %252 = load i8, ptr %251, align 1
  %253 = sext i8 %252 to i32
  %254 = icmp eq i32 %253, 35
  %255 = select i1 %254, i32 1021394759, i32 511825949
  store i32 %255, ptr %5, align 4
  %256 = xor i64 %0, 730312812973325569
  %257 = and i64 %0, %256
  %258 = or i64 %0, %256
  %259 = xor i64 %0, %256
  %260 = sub i64 %258, %259
  %261 = sub i64 %260, %257
  %262 = mul i64 %261, 244
  %263 = icmp sgt i64 %262, 0
  br i1 %263, label %725, label %415

264:                                              ; preds = %594
  store i32 -789448312, ptr %5, align 4
  %265 = xor i64 %0, -3508291032378169207
  %266 = and i64 %0, %265
  %267 = or i64 %0, %265
  %268 = xor i64 %0, %265
  %269 = add i64 %266, %267
  %270 = sub i64 %269, %0
  %271 = sub i64 %270, %265
  %272 = mul i64 %271, 225
  %273 = icmp slt i64 %272, 1
  br i1 %273, label %415, label %735

274:                                              ; preds = %596
  %275 = load i32, ptr %16, align 4
  %276 = load i32, ptr %17, align 4
  %277 = call i32 @idOf(i32 noundef %275, i32 noundef %276)
  store i32 %277, ptr %18, align 4
  %278 = load ptr, ptr %7, align 8
  %279 = getelementptr inbounds nuw %struct.Point, ptr %13, i32 0, i32 0
  %280 = load i32, ptr %279, align 4
  %281 = sext i32 %280 to i64
  %282 = getelementptr inbounds i32, ptr %278, i64 %281
  %283 = load i32, ptr %282, align 4
  %284 = load ptr, ptr @grid, align 8
  %285 = load i32, ptr %16, align 4
  %286 = sext i32 %285 to i64
  %287 = getelementptr inbounds ptr, ptr %284, i64 %286
  %288 = load ptr, ptr %287, align 8
  %289 = load i32, ptr %17, align 4
  %290 = sext i32 %289 to i64
  %291 = getelementptr inbounds i8, ptr %288, i64 %290
  %292 = load i8, ptr %291, align 1
  %293 = call i32 @terrainCost(i8 noundef signext %292)
  %294 = xor i32 %283, %293
  %295 = and i32 %283, %293
  %296 = add i32 %295, %295
  %297 = add i32 %294, %296
  store i32 %297, ptr %19, align 4
  %298 = load i32, ptr %19, align 4
  %299 = load ptr, ptr %7, align 8
  %300 = load i32, ptr %18, align 4
  %301 = sext i32 %300 to i64
  %302 = getelementptr inbounds i32, ptr %299, i64 %301
  %303 = load i32, ptr %302, align 4
  %304 = icmp slt i32 %298, %303
  %305 = select i1 %304, i32 1108507218, i32 1671274248
  store i32 %305, ptr %5, align 4
  %306 = xor i64 %0, 4790381930438426353
  %307 = and i64 %0, %306
  %308 = or i64 %0, %306
  %309 = xor i64 %0, %306
  %310 = add i64 %307, %308
  %311 = sub i64 %310, %0
  %312 = sub i64 %311, %306
  %313 = mul i64 %312, 57
  %314 = icmp eq i64 %313, 0
  br i1 %314, label %415, label %744

315:                                              ; preds = %574
  %316 = load i32, ptr %19, align 4
  %317 = load ptr, ptr %7, align 8
  %318 = load i32, ptr %18, align 4
  %319 = sext i32 %318 to i64
  %320 = getelementptr inbounds i32, ptr %317, i64 %319
  %321 = load i32, ptr %320, align 4
  %322 = icmp eq i32 %316, %321
  %323 = select i1 %322, i32 1462767396, i32 2135797048
  store i32 %323, ptr %5, align 4
  %324 = xor i64 %0, -923722173849259535
  %325 = and i64 %0, %324
  %326 = or i64 %0, %324
  %327 = xor i64 %0, %324
  %328 = add i64 %325, %326
  %329 = sub i64 %328, %0
  %330 = sub i64 %329, %324
  %331 = mul i64 %330, 147
  %332 = icmp slt i64 %331, 0
  br i1 %332, label %753, label %415

333:                                              ; preds = %624
  %334 = getelementptr inbounds nuw %struct.Point, ptr %13, i32 0, i32 0
  %335 = load i32, ptr %334, align 4
  %336 = load ptr, ptr %8, align 8
  %337 = load i32, ptr %18, align 4
  %338 = sext i32 %337 to i64
  %339 = getelementptr inbounds i32, ptr %336, i64 %338
  %340 = load i32, ptr %339, align 4
  %341 = icmp slt i32 %335, %340
  %342 = select i1 %341, i32 1108507218, i32 2135797048
  store i32 %342, ptr %5, align 4
  %343 = xor i64 %0, -3619871180285305891
  %344 = and i64 %0, %343
  %345 = or i64 %0, %343
  %346 = xor i64 %0, %343
  %347 = sub i64 %345, %346
  %348 = sub i64 %347, %344
  %349 = mul i64 %348, 178
  %350 = icmp eq i64 %349, 0
  br i1 %350, label %415, label %760

351:                                              ; preds = %566
  %352 = load i32, ptr %19, align 4
  %353 = load ptr, ptr %7, align 8
  %354 = load i32, ptr %18, align 4
  %355 = sext i32 %354 to i64
  %356 = getelementptr inbounds i32, ptr %353, i64 %355
  store i32 %352, ptr %356, align 4
  %357 = getelementptr inbounds nuw %struct.Point, ptr %13, i32 0, i32 0
  %358 = load i32, ptr %357, align 4
  %359 = load ptr, ptr %8, align 8
  %360 = load i32, ptr %18, align 4
  %361 = sext i32 %360 to i64
  %362 = getelementptr inbounds i32, ptr %359, i64 %361
  store i32 %358, ptr %362, align 4
  %363 = load ptr, ptr %12, align 8
  %364 = load i32, ptr %18, align 4
  %365 = load i32, ptr %19, align 4
  call void @pushHeap(ptr noundef %363, i32 noundef %364, i32 noundef %365)
  store i32 2135797048, ptr %5, align 4
  %366 = xor i64 %0, 690253238403164371
  %367 = and i64 %0, %366
  %368 = or i64 %0, %366
  %369 = xor i64 %0, %366
  %370 = sub i64 %368, %369
  %371 = sub i64 %370, %367
  %372 = mul i64 %371, 201
  %373 = icmp sle i64 %372, 0
  br i1 %373, label %415, label %768

374:                                              ; preds = %626
  store i32 -789448312, ptr %5, align 4
  %375 = xor i64 %0, 479125529038729333
  %376 = and i64 %0, %375
  %377 = or i64 %0, %375
  %378 = xor i64 %0, %375
  %379 = mul i64 %377, 2
  %380 = sub i64 %379, %378
  %381 = sub i64 %380, %0
  %382 = sub i64 %381, %375
  %383 = mul i64 %382, 154
  %384 = icmp slt i64 %383, 1
  br i1 %384, label %415, label %776

385:                                              ; preds = %556
  %386 = load i32, ptr %15, align 4
  %387 = load i32, ptr %5, align 4
  %388 = xor i32 %387, -789448311
  %389 = xor i32 %386, %388
  %390 = load i32, ptr %5, align 4
  %391 = xor i32 %390, -789448311
  %392 = and i32 %386, %391
  %393 = add i32 %392, %392
  %394 = add i32 %389, %393
  store i32 %394, ptr %15, align 4
  store i32 869002383, ptr %5, align 4
  %395 = xor i64 %0, 1624022716480157277
  %396 = and i64 %0, %395
  %397 = or i64 %0, %395
  %398 = xor i64 %0, %395
  %399 = add i64 %396, %397
  %400 = sub i64 %399, %0
  %401 = sub i64 %400, %395
  %402 = mul i64 %401, 120
  %403 = icmp uge i64 %402, 0
  br i1 %403, label %415, label %783

404:                                              ; preds = %600
  store i32 -2056834105, ptr %5, align 4
  %405 = xor i64 %0, -6254160085573187921
  %406 = and i64 %0, %405
  %407 = or i64 %0, %405
  %408 = xor i64 %0, %405
  %409 = sub i64 %407, %408
  %410 = sub i64 %409, %406
  %411 = mul i64 %410, 14
  %412 = icmp slt i64 %411, 1
  br i1 %412, label %415, label %793

413:                                              ; preds = %616
  %414 = load ptr, ptr %12, align 8
  call void @freeHeap(ptr noundef %414)
  ret void

415:                                              ; preds = %871, %861, %852, %842, %835, %828, %819, %811, %793, %783, %776, %768, %760, %753, %744, %735, %725, %717, %710, %700, %690, %683, %673, %664, %655, %646, %638, %628, %524, %511, %498, %485, %472, %461, %439, %427, %404, %385, %374, %351, %333, %315, %274, %264, %243, %234, %195, %181, %167, %158, %136, %121, %89, %54, %39, %25
  br label %20

416:                                              ; preds = %626, %624, %618, %616, %606, %604, %598, %594, %584, %582, %576, %572, %566, %564, %558, %554
  store i32 -1448256776, ptr %5, align 4
  call void asm sideeffect "", ""()
  %417 = xor i64 %0, 9021159657329388055
  %418 = and i64 %0, %417
  %419 = or i64 %0, %417
  %420 = xor i64 %0, %417
  %421 = mul i64 %419, 2
  %422 = sub i64 %421, %420
  %423 = sub i64 %422, %0
  %424 = sub i64 %423, %417
  %425 = mul i64 %424, 35
  %426 = icmp sgt i64 %425, 0
  br i1 %426, label %802, label %20

427:                                              ; preds = %606
  %428 = load i32, ptr %5, align 4
  %429 = xor i32 %428, -1782478109
  store i32 %429, ptr %5, align 4
  %430 = xor i64 %0, 8469456590221328401
  %431 = and i64 %0, %430
  %432 = or i64 %0, %430
  %433 = xor i64 %0, %430
  %434 = add i64 %431, %432
  %435 = sub i64 %434, %0
  %436 = sub i64 %435, %430
  %437 = mul i64 %436, 178
  %438 = icmp sle i64 %437, 0
  br i1 %438, label %415, label %811

439:                                              ; preds = %562
  %440 = load i32, ptr %5, align 4
  %441 = xor i32 %440, -940123797
  store i32 %441, ptr %5, align 4
  %442 = xor i64 %0, 3040923144988472973
  %443 = and i64 %0, %442
  %444 = or i64 %0, %442
  %445 = xor i64 %0, %442
  %446 = mul i64 %444, 2
  %447 = sub i64 %446, %445
  %448 = sub i64 %447, %0
  %449 = sub i64 %448, %442
  %450 = mul i64 %449, 6
  %451 = xor i64 %0, -4555259322754803643
  %452 = and i64 %0, %451
  %453 = or i64 %0, %451
  %454 = xor i64 %0, %451
  %455 = add i64 %0, %451
  %456 = sub i64 %455, %454
  %457 = mul i64 %452, 2
  %458 = sub i64 %456, %457
  %459 = mul i64 %458, 56
  %460 = icmp eq i64 %450, %459
  br i1 %460, label %415, label %819

461:                                              ; preds = %578
  %462 = load i32, ptr %5, align 4
  %463 = xor i32 %462, 1875403921
  store i32 %463, ptr %5, align 4
  %464 = xor i64 %0, -8374395885841152625
  %465 = and i64 %0, %464
  %466 = or i64 %0, %464
  %467 = xor i64 %0, %464
  %468 = sub i64 %466, %467
  %469 = sub i64 %468, %465
  %470 = mul i64 %469, 92
  %471 = icmp ne i64 %470, 0
  br i1 %471, label %828, label %415

472:                                              ; preds = %576
  %473 = load i32, ptr %5, align 4
  %474 = xor i32 %473, 1836432708
  store i32 %474, ptr %5, align 4
  %475 = xor i64 %0, 6361658313817246319
  %476 = and i64 %0, %475
  %477 = or i64 %0, %475
  %478 = xor i64 %0, %475
  %479 = add i64 %0, %475
  %480 = sub i64 %479, %478
  %481 = mul i64 %476, 2
  %482 = sub i64 %480, %481
  %483 = mul i64 %482, 224
  %484 = icmp ne i64 %483, 0
  br i1 %484, label %835, label %415

485:                                              ; preds = %582
  %486 = load i32, ptr %5, align 4
  %487 = xor i32 %486, -85723054
  store i32 %487, ptr %5, align 4
  %488 = xor i64 %0, 6100284974741913643
  %489 = and i64 %0, %488
  %490 = or i64 %0, %488
  %491 = xor i64 %0, %488
  %492 = mul i64 %490, 2
  %493 = sub i64 %492, %491
  %494 = sub i64 %493, %0
  %495 = sub i64 %494, %488
  %496 = mul i64 %495, 14
  %497 = icmp sle i64 %496, 0
  br i1 %497, label %415, label %842

498:                                              ; preds = %584
  %499 = load i32, ptr %5, align 4
  %500 = xor i32 %499, -713252097
  store i32 %500, ptr %5, align 4
  %501 = xor i64 %0, -7921981077558850143
  %502 = and i64 %0, %501
  %503 = or i64 %0, %501
  %504 = xor i64 %0, %501
  %505 = mul i64 %503, 2
  %506 = sub i64 %505, %504
  %507 = sub i64 %506, %0
  %508 = sub i64 %507, %501
  %509 = mul i64 %508, 245
  %510 = icmp eq i64 %509, 0
  br i1 %510, label %415, label %852

511:                                              ; preds = %554
  %512 = load i32, ptr %5, align 4
  %513 = xor i32 %512, 418431095
  store i32 %513, ptr %5, align 4
  %514 = xor i64 %0, -2708834784042899905
  %515 = and i64 %0, %514
  %516 = or i64 %0, %514
  %517 = xor i64 %0, %514
  %518 = mul i64 %516, 2
  %519 = sub i64 %518, %517
  %520 = sub i64 %519, %0
  %521 = sub i64 %520, %514
  %522 = mul i64 %521, 40
  %523 = icmp ugt i64 %522, 0
  br i1 %523, label %861, label %415

524:                                              ; preds = %602
  %525 = load i32, ptr %5, align 4
  %526 = xor i32 %525, 2141811005
  store i32 %526, ptr %5, align 4
  %527 = xor i64 %0, 8140004047129275675
  %528 = and i64 %0, %527
  %529 = or i64 %0, %527
  %530 = xor i64 %0, %527
  %531 = sub i64 %529, %530
  %532 = sub i64 %531, %528
  %533 = mul i64 %532, 59
  %534 = xor i64 %0, -4594891590419509387
  %535 = and i64 %0, %534
  %536 = or i64 %0, %534
  %537 = xor i64 %0, %534
  %538 = sub i64 %536, %537
  %539 = sub i64 %538, %535
  %540 = mul i64 %539, 127
  %541 = icmp eq i64 %533, %540
  br i1 %541, label %415, label %871

542:                                              ; preds = %20
  %543 = icmp slt i32 %23, 312096302
  br i1 %543, label %546, label %548

544:                                              ; preds = %20
  %545 = icmp slt i32 %23, 1766416067
  br i1 %545, label %586, label %588

546:                                              ; preds = %542
  %547 = icmp slt i32 %23, 102292503
  br i1 %547, label %550, label %552

548:                                              ; preds = %542
  %549 = icmp slt i32 %23, 1126415162
  br i1 %549, label %568, label %570

550:                                              ; preds = %546
  %551 = icmp slt i32 %23, 54681492
  br i1 %551, label %554, label %556

552:                                              ; preds = %546
  %553 = icmp slt i32 %23, 194521383
  br i1 %553, label %560, label %562

554:                                              ; preds = %550
  %555 = icmp eq i32 %23, 6537712
  br i1 %555, label %511, label %416

556:                                              ; preds = %550
  %557 = icmp eq i32 %23, 54681492
  br i1 %557, label %385, label %558

558:                                              ; preds = %556
  %559 = icmp eq i32 %23, 54889263
  br i1 %559, label %121, label %416

560:                                              ; preds = %552
  %561 = icmp eq i32 %23, 102292503
  br i1 %561, label %181, label %564

562:                                              ; preds = %552
  %563 = icmp eq i32 %23, 194521383
  br i1 %563, label %439, label %566

564:                                              ; preds = %560
  %565 = icmp eq i32 %23, 121404861
  br i1 %565, label %167, label %416

566:                                              ; preds = %562
  %567 = icmp eq i32 %23, 302503878
  br i1 %567, label %351, label %416

568:                                              ; preds = %548
  %569 = icmp slt i32 %23, 510561044
  br i1 %569, label %572, label %574

570:                                              ; preds = %548
  %571 = icmp slt i32 %23, 1215822442
  br i1 %571, label %578, label %580

572:                                              ; preds = %568
  %573 = icmp eq i32 %23, 312096302
  br i1 %573, label %54, label %416

574:                                              ; preds = %568
  %575 = icmp eq i32 %23, 510561044
  br i1 %575, label %315, label %576

576:                                              ; preds = %574
  %577 = icmp eq i32 %23, 922775013
  br i1 %577, label %472, label %416

578:                                              ; preds = %570
  %579 = icmp eq i32 %23, 1126415162
  br i1 %579, label %461, label %582

580:                                              ; preds = %570
  %581 = icmp eq i32 %23, 1215822442
  br i1 %581, label %234, label %584

582:                                              ; preds = %578
  %583 = icmp eq i32 %23, 1131295309
  br i1 %583, label %485, label %416

584:                                              ; preds = %580
  %585 = icmp eq i32 %23, 1241192014
  br i1 %585, label %498, label %416

586:                                              ; preds = %544
  %587 = icmp slt i32 %23, 1443460422
  br i1 %587, label %590, label %592

588:                                              ; preds = %544
  %589 = icmp slt i32 %23, 1833769650
  br i1 %589, label %608, label %610

590:                                              ; preds = %586
  %591 = icmp slt i32 %23, 1312678045
  br i1 %591, label %594, label %596

592:                                              ; preds = %586
  %593 = icmp slt i32 %23, 1576190514
  br i1 %593, label %600, label %602

594:                                              ; preds = %590
  %595 = icmp eq i32 %23, 1272149167
  br i1 %595, label %264, label %416

596:                                              ; preds = %590
  %597 = icmp eq i32 %23, 1312678045
  br i1 %597, label %274, label %598

598:                                              ; preds = %596
  %599 = icmp eq i32 %23, 1427905935
  br i1 %599, label %39, label %416

600:                                              ; preds = %592
  %601 = icmp eq i32 %23, 1443460422
  br i1 %601, label %404, label %604

602:                                              ; preds = %592
  %603 = icmp eq i32 %23, 1576190514
  br i1 %603, label %524, label %606

604:                                              ; preds = %600
  %605 = icmp eq i32 %23, 1446413228
  br i1 %605, label %158, label %416

606:                                              ; preds = %602
  %607 = icmp eq i32 %23, 1655731430
  br i1 %607, label %427, label %416

608:                                              ; preds = %588
  %609 = icmp slt i32 %23, 1817775829
  br i1 %609, label %612, label %614

610:                                              ; preds = %588
  %611 = icmp slt i32 %23, 2129762339
  br i1 %611, label %620, label %622

612:                                              ; preds = %608
  %613 = icmp eq i32 %23, 1766416067
  br i1 %613, label %136, label %616

614:                                              ; preds = %608
  %615 = icmp eq i32 %23, 1817775829
  br i1 %615, label %89, label %618

616:                                              ; preds = %612
  %617 = icmp eq i32 %23, 1778137674
  br i1 %617, label %413, label %416

618:                                              ; preds = %614
  %619 = icmp eq i32 %23, 1824832708
  br i1 %619, label %25, label %416

620:                                              ; preds = %610
  %621 = icmp eq i32 %23, 1833769650
  br i1 %621, label %195, label %624

622:                                              ; preds = %610
  %623 = icmp eq i32 %23, 2129762339
  br i1 %623, label %243, label %626

624:                                              ; preds = %620
  %625 = icmp eq i32 %23, 2065707296
  br i1 %625, label %333, label %416

626:                                              ; preds = %622
  %627 = icmp eq i32 %23, 2135916548
  br i1 %627, label %374, label %416

628:                                              ; preds = %25
  %629 = load i64, ptr %4, align 8
  %630 = ptrtoint ptr %1 to i64
  %631 = ptrtoint ptr %2 to i64
  %632 = and i64 %0, %629
  %633 = sub i64 %632, %629
  %634 = or i64 %633, %631
  %635 = or i64 %634, %0
  %636 = mul i64 %635, %630
  %637 = xor i64 %636, %631
  store i64 %637, ptr %4, align 8
  br label %415

638:                                              ; preds = %39
  %639 = load i64, ptr %4, align 8
  %640 = ptrtoint ptr %1 to i64
  %641 = ptrtoint ptr %2 to i64
  %642 = mul i64 %0, %0
  %643 = sub i64 %642, %640
  %644 = sub i64 %643, %641
  %645 = add i64 %644, %0
  store i64 %645, ptr %4, align 8
  br label %415

646:                                              ; preds = %54
  %647 = load i64, ptr %4, align 8
  %648 = ptrtoint ptr %1 to i64
  %649 = ptrtoint ptr %2 to i64
  %650 = or i64 %0, %647
  %651 = sub i64 %650, %648
  %652 = sub i64 %651, %0
  %653 = sub i64 %652, %649
  %654 = xor i64 %653, %648
  store i64 %654, ptr %4, align 8
  br label %415

655:                                              ; preds = %89
  %656 = load i64, ptr %4, align 8
  %657 = ptrtoint ptr %1 to i64
  %658 = ptrtoint ptr %2 to i64
  %659 = sub i64 %656, %0
  %660 = or i64 %659, %0
  %661 = add i64 %660, %657
  %662 = add i64 %661, %657
  %663 = and i64 %662, %656
  store i64 %663, ptr %4, align 8
  br label %415

664:                                              ; preds = %121
  %665 = load i64, ptr %4, align 8
  %666 = ptrtoint ptr %1 to i64
  %667 = ptrtoint ptr %2 to i64
  %668 = xor i64 %0, %667
  %669 = and i64 %668, %0
  %670 = and i64 %669, %666
  %671 = add i64 %670, %667
  %672 = add i64 %671, %0
  store i64 %672, ptr %4, align 8
  br label %415

673:                                              ; preds = %136
  %674 = load i64, ptr %4, align 8
  %675 = ptrtoint ptr %1 to i64
  %676 = ptrtoint ptr %2 to i64
  %677 = add i64 %675, %675
  %678 = mul i64 %677, %674
  %679 = add i64 %678, %674
  %680 = sub i64 %679, %676
  %681 = or i64 %680, %674
  %682 = mul i64 %681, %0
  store i64 %682, ptr %4, align 8
  br label %415

683:                                              ; preds = %158
  %684 = load i64, ptr %4, align 8
  %685 = ptrtoint ptr %1 to i64
  %686 = ptrtoint ptr %2 to i64
  %687 = sub i64 %685, %684
  %688 = xor i64 %687, %0
  %689 = add i64 %688, %685
  store i64 %689, ptr %4, align 8
  br label %415

690:                                              ; preds = %167
  %691 = load i64, ptr %4, align 8
  %692 = ptrtoint ptr %1 to i64
  %693 = ptrtoint ptr %2 to i64
  %694 = add i64 %693, %691
  %695 = and i64 %694, %691
  %696 = and i64 %695, %693
  %697 = mul i64 %696, %691
  %698 = and i64 %697, %691
  %699 = or i64 %698, %693
  store i64 %699, ptr %4, align 8
  br label %415

700:                                              ; preds = %181
  %701 = load i64, ptr %4, align 8
  %702 = ptrtoint ptr %1 to i64
  %703 = ptrtoint ptr %2 to i64
  %704 = add i64 %702, %702
  %705 = or i64 %704, %703
  %706 = and i64 %705, %701
  %707 = or i64 %706, %701
  %708 = add i64 %707, %0
  %709 = mul i64 %708, %702
  store i64 %709, ptr %4, align 8
  br label %415

710:                                              ; preds = %195
  %711 = load i64, ptr %4, align 8
  %712 = ptrtoint ptr %1 to i64
  %713 = ptrtoint ptr %2 to i64
  %714 = and i64 %711, %0
  %715 = mul i64 %714, %711
  %716 = sub i64 %715, %712
  store i64 %716, ptr %4, align 8
  br label %415

717:                                              ; preds = %234
  %718 = load i64, ptr %4, align 8
  %719 = ptrtoint ptr %1 to i64
  %720 = ptrtoint ptr %2 to i64
  %721 = sub i64 %720, %720
  %722 = sub i64 %721, %718
  %723 = add i64 %722, %719
  %724 = mul i64 %723, %718
  store i64 %724, ptr %4, align 8
  br label %415

725:                                              ; preds = %243
  %726 = load i64, ptr %4, align 8
  %727 = ptrtoint ptr %1 to i64
  %728 = ptrtoint ptr %2 to i64
  %729 = sub i64 %728, %727
  %730 = mul i64 %729, %728
  %731 = mul i64 %730, %728
  %732 = and i64 %731, %726
  %733 = or i64 %732, %726
  %734 = mul i64 %733, %728
  store i64 %734, ptr %4, align 8
  br label %415

735:                                              ; preds = %264
  %736 = load i64, ptr %4, align 8
  %737 = ptrtoint ptr %1 to i64
  %738 = ptrtoint ptr %2 to i64
  %739 = or i64 %738, %0
  %740 = and i64 %739, %738
  %741 = add i64 %740, %738
  %742 = sub i64 %741, %737
  %743 = sub i64 %742, %738
  store i64 %743, ptr %4, align 8
  br label %415

744:                                              ; preds = %274
  %745 = load i64, ptr %4, align 8
  %746 = ptrtoint ptr %1 to i64
  %747 = ptrtoint ptr %2 to i64
  %748 = xor i64 %746, %0
  %749 = and i64 %748, %0
  %750 = and i64 %749, %0
  %751 = sub i64 %750, %747
  %752 = or i64 %751, %0
  store i64 %752, ptr %4, align 8
  br label %415

753:                                              ; preds = %315
  %754 = load i64, ptr %4, align 8
  %755 = ptrtoint ptr %1 to i64
  %756 = ptrtoint ptr %2 to i64
  %757 = sub i64 %0, %0
  %758 = or i64 %757, %0
  %759 = or i64 %758, %756
  store i64 %759, ptr %4, align 8
  br label %415

760:                                              ; preds = %333
  %761 = load i64, ptr %4, align 8
  %762 = ptrtoint ptr %1 to i64
  %763 = ptrtoint ptr %2 to i64
  %764 = and i64 %761, %763
  %765 = sub i64 %764, %0
  %766 = xor i64 %765, %0
  %767 = and i64 %766, %763
  store i64 %767, ptr %4, align 8
  br label %415

768:                                              ; preds = %351
  %769 = load i64, ptr %4, align 8
  %770 = ptrtoint ptr %1 to i64
  %771 = ptrtoint ptr %2 to i64
  %772 = add i64 %0, %769
  %773 = and i64 %772, %770
  %774 = add i64 %773, %769
  %775 = sub i64 %774, %0
  store i64 %775, ptr %4, align 8
  br label %415

776:                                              ; preds = %374
  %777 = load i64, ptr %4, align 8
  %778 = ptrtoint ptr %1 to i64
  %779 = ptrtoint ptr %2 to i64
  %780 = sub i64 %777, %777
  %781 = xor i64 %780, %0
  %782 = and i64 %781, %0
  store i64 %782, ptr %4, align 8
  br label %415

783:                                              ; preds = %385
  %784 = load i64, ptr %4, align 8
  %785 = ptrtoint ptr %1 to i64
  %786 = ptrtoint ptr %2 to i64
  %787 = or i64 %0, %784
  %788 = or i64 %787, %786
  %789 = add i64 %788, %786
  %790 = mul i64 %789, %784
  %791 = add i64 %790, %785
  %792 = xor i64 %791, %784
  store i64 %792, ptr %4, align 8
  br label %415

793:                                              ; preds = %404
  %794 = load i64, ptr %4, align 8
  %795 = ptrtoint ptr %1 to i64
  %796 = ptrtoint ptr %2 to i64
  %797 = xor i64 %795, %795
  %798 = sub i64 %797, %796
  %799 = or i64 %798, %795
  %800 = or i64 %799, %794
  %801 = sub i64 %800, %794
  store i64 %801, ptr %4, align 8
  br label %415

802:                                              ; preds = %416
  %803 = load i64, ptr %4, align 8
  %804 = ptrtoint ptr %1 to i64
  %805 = ptrtoint ptr %2 to i64
  %806 = mul i64 %804, %0
  %807 = or i64 %806, %0
  %808 = mul i64 %807, %0
  %809 = mul i64 %808, %804
  %810 = mul i64 %809, %0
  store i64 %810, ptr %4, align 8
  br label %20

811:                                              ; preds = %427
  %812 = load i64, ptr %4, align 8
  %813 = ptrtoint ptr %1 to i64
  %814 = ptrtoint ptr %2 to i64
  %815 = sub i64 %0, %813
  %816 = and i64 %815, %814
  %817 = xor i64 %816, %814
  %818 = xor i64 %817, %813
  store i64 %818, ptr %4, align 8
  br label %415

819:                                              ; preds = %439
  %820 = load i64, ptr %4, align 8
  %821 = ptrtoint ptr %1 to i64
  %822 = ptrtoint ptr %2 to i64
  %823 = and i64 %822, %0
  %824 = sub i64 %823, %821
  %825 = xor i64 %824, %0
  %826 = mul i64 %825, %0
  %827 = xor i64 %826, %821
  store i64 %827, ptr %4, align 8
  br label %415

828:                                              ; preds = %461
  %829 = load i64, ptr %4, align 8
  %830 = ptrtoint ptr %1 to i64
  %831 = ptrtoint ptr %2 to i64
  %832 = add i64 %829, %829
  %833 = or i64 %832, %830
  %834 = and i64 %833, %0
  store i64 %834, ptr %4, align 8
  br label %415

835:                                              ; preds = %472
  %836 = load i64, ptr %4, align 8
  %837 = ptrtoint ptr %1 to i64
  %838 = ptrtoint ptr %2 to i64
  %839 = and i64 %838, %838
  %840 = or i64 %839, %838
  %841 = xor i64 %840, %838
  store i64 %841, ptr %4, align 8
  br label %415

842:                                              ; preds = %485
  %843 = load i64, ptr %4, align 8
  %844 = ptrtoint ptr %1 to i64
  %845 = ptrtoint ptr %2 to i64
  %846 = add i64 %844, %843
  %847 = xor i64 %846, %845
  %848 = add i64 %847, %845
  %849 = xor i64 %848, %843
  %850 = mul i64 %849, %844
  %851 = mul i64 %850, %0
  store i64 %851, ptr %4, align 8
  br label %415

852:                                              ; preds = %498
  %853 = load i64, ptr %4, align 8
  %854 = ptrtoint ptr %1 to i64
  %855 = ptrtoint ptr %2 to i64
  %856 = sub i64 %854, %853
  %857 = mul i64 %856, %853
  %858 = mul i64 %857, %853
  %859 = and i64 %858, %855
  %860 = or i64 %859, %853
  store i64 %860, ptr %4, align 8
  br label %415

861:                                              ; preds = %511
  %862 = load i64, ptr %4, align 8
  %863 = ptrtoint ptr %1 to i64
  %864 = ptrtoint ptr %2 to i64
  %865 = add i64 %862, %863
  %866 = and i64 %865, %0
  %867 = add i64 %866, %863
  %868 = add i64 %867, %0
  %869 = or i64 %868, %862
  %870 = add i64 %869, %863
  store i64 %870, ptr %4, align 8
  br label %415

871:                                              ; preds = %524
  %872 = load i64, ptr %4, align 8
  %873 = ptrtoint ptr %1 to i64
  %874 = ptrtoint ptr %2 to i64
  %875 = and i64 %872, %872
  %876 = sub i64 %875, %873
  %877 = xor i64 %876, %872
  %878 = sub i64 %877, %872
  store i64 %878, ptr %4, align 8
  br label %415
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @appendPathSegment(i64 %0, i64 %1, ptr noundef %2, ptr noundef %3, ptr noundef %4) #0 {
  %6 = alloca i64, align 8
  store i64 0, ptr %6, align 8
  %7 = alloca i32, align 4
  %8 = alloca %struct.Point, align 4
  %9 = alloca %struct.Point, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  %18 = alloca %struct.Point, align 4
  store i32 1749840022, ptr %7, align 4
  br label %19

19:                                               ; preds = %699, %340, %339, %5
  %20 = load i32, ptr %7, align 4
  %21 = sub i32 %20, -1268569564
  %22 = mul i32 %21, 141475101
  %23 = icmp slt i32 %22, 1391104869
  br i1 %23, label %469, label %471

24:                                               ; preds = %537
  store i64 %0, ptr %8, align 4
  store i64 %1, ptr %9, align 4
  store ptr %2, ptr %10, align 8
  store ptr %3, ptr %11, align 8
  store ptr %4, ptr %12, align 8
  %25 = load i32, ptr @N, align 4
  %26 = load i32, ptr @N, align 4
  %27 = mul nsw i32 %25, %26
  %28 = load i32, ptr %7, align 4
  %29 = xor i32 %28, 1749840023
  %30 = sub i32 %27, %29
  %31 = load i32, ptr %7, align 4
  %32 = xor i32 %31, 1749840016
  %33 = mul i32 %27, %32
  %34 = load i32, ptr %7, align 4
  %35 = xor i32 %34, 1749840019
  %36 = mul i32 %35, %30
  %37 = sub i32 %33, %36
  %38 = sext i32 %37 to i64
  %39 = mul i64 4, %38
  %40 = call noalias ptr @malloc(i64 noundef %39) #6
  store ptr %40, ptr %13, align 8
  store i32 0, ptr %14, align 4
  %41 = getelementptr inbounds nuw %struct.Point, ptr %8, i32 0, i32 0
  %42 = load i32, ptr %41, align 4
  %43 = getelementptr inbounds nuw %struct.Point, ptr %8, i32 0, i32 1
  %44 = load i32, ptr %43, align 4
  %45 = call i32 @idOf(i32 noundef %42, i32 noundef %44)
  store i32 %45, ptr %15, align 4
  %46 = getelementptr inbounds nuw %struct.Point, ptr %9, i32 0, i32 0
  %47 = load i32, ptr %46, align 4
  %48 = getelementptr inbounds nuw %struct.Point, ptr %9, i32 0, i32 1
  %49 = load i32, ptr %48, align 4
  %50 = call i32 @idOf(i32 noundef %47, i32 noundef %49)
  store i32 %50, ptr %16, align 4
  store i32 -1096122739, ptr %7, align 4
  %51 = xor i64 %0, -5727373514722267783
  %52 = and i64 %0, %51
  %53 = or i64 %0, %51
  %54 = xor i64 %0, %51
  %55 = add i64 %0, %51
  %56 = sub i64 %55, %54
  %57 = mul i64 %52, 2
  %58 = sub i64 %56, %57
  %59 = mul i64 %58, 147
  %60 = icmp slt i64 %59, 1
  br i1 %60, label %339, label %547

61:                                               ; preds = %527
  %62 = load i32, ptr %16, align 4
  %63 = icmp ne i32 %62, -1
  %64 = select i1 %63, i32 545206029, i32 1040718756
  store i32 %64, ptr %7, align 4
  %65 = xor i64 %0, -4823076365833736333
  %66 = and i64 %0, %65
  %67 = or i64 %0, %65
  %68 = xor i64 %0, %65
  %69 = mul i64 %67, 2
  %70 = sub i64 %69, %68
  %71 = sub i64 %70, %0
  %72 = sub i64 %71, %65
  %73 = mul i64 %72, 44
  %74 = icmp ugt i64 %73, 0
  br i1 %74, label %556, label %339

75:                                               ; preds = %517
  %76 = load i32, ptr %16, align 4
  %77 = load ptr, ptr %13, align 8
  %78 = load i32, ptr %14, align 4
  %79 = load i32, ptr %7, align 4
  %80 = xor i32 %79, 545206028
  %81 = xor i32 %78, %80
  %82 = load i32, ptr %7, align 4
  %83 = xor i32 %82, 545206028
  %84 = and i32 %78, %83
  %85 = add i32 %84, %84
  %86 = add i32 %81, %85
  store i32 %86, ptr %14, align 4
  %87 = sext i32 %78 to i64
  %88 = getelementptr inbounds i32, ptr %77, i64 %87
  store i32 %76, ptr %88, align 4
  %89 = load i32, ptr %16, align 4
  %90 = load i32, ptr %15, align 4
  %91 = icmp eq i32 %89, %90
  %92 = select i1 %91, i32 -1290333033, i32 753851676
  store i32 %92, ptr %7, align 4
  %93 = xor i64 %0, 1384789754269238431
  %94 = and i64 %0, %93
  %95 = or i64 %0, %93
  %96 = xor i64 %0, %93
  %97 = mul i64 %95, 2
  %98 = sub i64 %97, %96
  %99 = sub i64 %98, %0
  %100 = sub i64 %99, %93
  %101 = mul i64 %100, 207
  %102 = icmp sle i64 %101, 0
  br i1 %102, label %339, label %565

103:                                              ; preds = %487
  store i32 1040718756, ptr %7, align 4
  %104 = xor i64 %0, -1315595041665223181
  %105 = and i64 %0, %104
  %106 = or i64 %0, %104
  %107 = xor i64 %0, %104
  %108 = add i64 %105, %106
  %109 = sub i64 %108, %0
  %110 = sub i64 %109, %104
  %111 = mul i64 %110, 163
  %112 = icmp eq i64 %111, 0
  br i1 %112, label %339, label %573

113:                                              ; preds = %539
  %114 = load ptr, ptr %10, align 8
  %115 = load i32, ptr %16, align 4
  %116 = sext i32 %115 to i64
  %117 = getelementptr inbounds i32, ptr %114, i64 %116
  %118 = load i32, ptr %117, align 4
  store i32 %118, ptr %16, align 4
  store i32 -1096122739, ptr %7, align 4
  %119 = xor i64 %0, -2754883320227999705
  %120 = and i64 %0, %119
  %121 = or i64 %0, %119
  %122 = xor i64 %0, %119
  %123 = sub i64 %121, %122
  %124 = sub i64 %123, %120
  %125 = mul i64 %124, 209
  %126 = icmp ugt i64 %125, 0
  br i1 %126, label %584, label %339

127:                                              ; preds = %497
  %128 = load i32, ptr %14, align 4
  %129 = icmp eq i32 %128, 0
  %130 = select i1 %129, i32 2042405327, i32 -37535782
  store i32 %130, ptr %7, align 4
  %131 = xor i64 %0, -6260569567256062315
  %132 = and i64 %0, %131
  %133 = or i64 %0, %131
  %134 = xor i64 %0, %131
  %135 = sub i64 %133, %134
  %136 = sub i64 %135, %132
  %137 = mul i64 %136, 191
  %138 = icmp sgt i64 %137, 0
  br i1 %138, label %595, label %339

139:                                              ; preds = %501
  %140 = load ptr, ptr %13, align 8
  %141 = load i32, ptr %14, align 4
  %142 = load i32, ptr %7, align 4
  %143 = xor i32 %142, -37535781
  %144 = add i32 %141, %143
  %145 = load i32, ptr %7, align 4
  %146 = xor i32 %145, -37535784
  %147 = mul i32 %141, %146
  %148 = load i32, ptr %7, align 4
  %149 = xor i32 %148, -37535781
  %150 = mul i32 %149, %144
  %151 = sub i32 %147, %150
  %152 = sext i32 %151 to i64
  %153 = getelementptr inbounds i32, ptr %140, i64 %152
  %154 = load i32, ptr %153, align 4
  %155 = load i32, ptr %15, align 4
  %156 = icmp ne i32 %154, %155
  %157 = select i1 %156, i32 2042405327, i32 274094955
  store i32 %157, ptr %7, align 4
  %158 = xor i64 %0, 6476005954281298115
  %159 = and i64 %0, %158
  %160 = or i64 %0, %158
  %161 = xor i64 %0, %158
  %162 = add i64 %0, %158
  %163 = sub i64 %162, %161
  %164 = mul i64 %159, 2
  %165 = sub i64 %163, %164
  %166 = mul i64 %165, 164
  %167 = icmp eq i64 %166, 0
  br i1 %167, label %339, label %603

168:                                              ; preds = %499
  %169 = load ptr, ptr %13, align 8
  call void @free(ptr noundef %169) #8
  store i32 -546718485, ptr %7, align 4
  %170 = xor i64 %0, -485570555550345793
  %171 = and i64 %0, %170
  %172 = or i64 %0, %170
  %173 = xor i64 %0, %170
  %174 = sub i64 %172, %173
  %175 = sub i64 %174, %171
  %176 = mul i64 %175, 78
  %177 = icmp sgt i64 %176, 0
  br i1 %177, label %614, label %339

178:                                              ; preds = %525
  %179 = load i32, ptr %14, align 4
  %180 = load i32, ptr %7, align 4
  %181 = xor i32 %180, -274094955
  %182 = add i32 %179, %181
  %183 = load i32, ptr %7, align 4
  %184 = xor i32 %183, 274094954
  %185 = add i32 %182, %184
  store i32 %185, ptr %17, align 4
  store i32 -985447607, ptr %7, align 4
  %186 = xor i64 %0, 2537045455122799941
  %187 = and i64 %0, %186
  %188 = or i64 %0, %186
  %189 = xor i64 %0, %186
  %190 = add i64 %187, %188
  %191 = sub i64 %190, %0
  %192 = sub i64 %191, %186
  %193 = mul i64 %192, 108
  %194 = icmp eq i64 %193, 0
  br i1 %194, label %339, label %625

195:                                              ; preds = %505
  %196 = load i32, ptr %17, align 4
  %197 = icmp sge i32 %196, 0
  %198 = select i1 %197, i32 1421986963, i32 703091984
  store i32 %198, ptr %7, align 4
  %199 = xor i64 %0, 3058457674182831137
  %200 = and i64 %0, %199
  %201 = or i64 %0, %199
  %202 = xor i64 %0, %199
  %203 = mul i64 %201, 2
  %204 = sub i64 %203, %202
  %205 = sub i64 %204, %0
  %206 = sub i64 %205, %199
  %207 = mul i64 %206, 39
  %208 = xor i64 %0, -3510872420107887907
  %209 = and i64 %0, %208
  %210 = or i64 %0, %208
  %211 = xor i64 %0, %208
  %212 = add i64 %0, %208
  %213 = sub i64 %212, %211
  %214 = mul i64 %209, 2
  %215 = sub i64 %213, %214
  %216 = mul i64 %215, 131
  %217 = icmp ne i64 %207, %216
  br i1 %217, label %635, label %339

218:                                              ; preds = %503
  %219 = load ptr, ptr %13, align 8
  %220 = load i32, ptr %17, align 4
  %221 = sext i32 %220 to i64
  %222 = getelementptr inbounds i32, ptr %219, i64 %221
  %223 = load i32, ptr %222, align 4
  %224 = call i64 @pointOf(i32 noundef %223)
  store i64 %224, ptr %18, align 4
  %225 = load ptr, ptr %12, align 8
  %226 = load i32, ptr %225, align 4
  %227 = icmp sgt i32 %226, 0
  %228 = select i1 %227, i32 586413817, i32 -2136162832
  store i32 %228, ptr %7, align 4
  %229 = xor i64 %0, 4846076248022694999
  %230 = and i64 %0, %229
  %231 = or i64 %0, %229
  %232 = xor i64 %0, %229
  %233 = sub i64 %231, %232
  %234 = sub i64 %233, %230
  %235 = mul i64 %234, 56
  %236 = icmp ugt i64 %235, 0
  br i1 %236, label %646, label %339

237:                                              ; preds = %491
  %238 = load ptr, ptr %11, align 8
  %239 = load ptr, ptr %12, align 8
  %240 = load i32, ptr %239, align 4
  %241 = load i32, ptr %7, align 4
  %242 = xor i32 %241, -586413817
  %243 = add i32 %240, %242
  %244 = load i32, ptr %7, align 4
  %245 = xor i32 %244, 586413816
  %246 = add i32 %243, %245
  %247 = sext i32 %246 to i64
  %248 = getelementptr inbounds %struct.Point, ptr %238, i64 %247
  %249 = load i64, ptr %248, align 4
  %250 = load i64, ptr %18, align 4
  %251 = call i32 @samePoint(i64 %249, i64 %250)
  %252 = icmp ne i32 %251, 0
  %253 = select i1 %252, i32 287435882, i32 -2136162832
  store i32 %253, ptr %7, align 4
  %254 = xor i64 %0, -4345158312769418109
  %255 = and i64 %0, %254
  %256 = or i64 %0, %254
  %257 = xor i64 %0, %254
  %258 = add i64 %255, %256
  %259 = sub i64 %258, %0
  %260 = sub i64 %259, %254
  %261 = mul i64 %260, 191
  %262 = icmp uge i64 %261, 0
  br i1 %262, label %339, label %655

263:                                              ; preds = %481
  store i32 -1913072083, ptr %7, align 4
  %264 = xor i64 %0, -5391060304088735777
  %265 = and i64 %0, %264
  %266 = or i64 %0, %264
  %267 = xor i64 %0, %264
  %268 = add i64 %265, %266
  %269 = sub i64 %268, %0
  %270 = sub i64 %269, %264
  %271 = mul i64 %270, 33
  %272 = xor i64 %0, 7274163335478570575
  %273 = and i64 %0, %272
  %274 = or i64 %0, %272
  %275 = xor i64 %0, %272
  %276 = sub i64 %274, %275
  %277 = sub i64 %276, %273
  %278 = mul i64 %277, 100
  %279 = icmp eq i64 %271, %278
  br i1 %279, label %339, label %663

280:                                              ; preds = %521
  %281 = load ptr, ptr %11, align 8
  %282 = load ptr, ptr %12, align 8
  %283 = load i32, ptr %282, align 4
  %284 = sext i32 %283 to i64
  %285 = getelementptr inbounds %struct.Point, ptr %281, i64 %284
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %285, ptr align 4 %18, i64 8, i1 false)
  %286 = load ptr, ptr %12, align 8
  %287 = load i32, ptr %286, align 4
  %288 = load i32, ptr %7, align 4
  %289 = xor i32 %288, -2136162831
  %290 = xor i32 %287, %289
  %291 = load i32, ptr %7, align 4
  %292 = xor i32 %291, -2136162831
  %293 = and i32 %287, %292
  %294 = add i32 %293, %293
  %295 = add i32 %290, %294
  store i32 %295, ptr %286, align 4
  store i32 -1913072083, ptr %7, align 4
  %296 = xor i64 %0, 3687383056946567903
  %297 = and i64 %0, %296
  %298 = or i64 %0, %296
  %299 = xor i64 %0, %296
  %300 = sub i64 %298, %299
  %301 = sub i64 %300, %297
  %302 = mul i64 %301, 193
  %303 = icmp slt i64 %302, 1
  br i1 %303, label %339, label %673

304:                                              ; preds = %523
  %305 = load i32, ptr %17, align 4
  %306 = load i32, ptr %7, align 4
  %307 = xor i32 %306, -1913072084
  %308 = sub i32 %305, %307
  %309 = load i32, ptr %7, align 4
  %310 = xor i32 %309, -1913072083
  %311 = mul i32 %305, %310
  %312 = load i32, ptr %7, align 4
  %313 = xor i32 %312, 1913072082
  %314 = mul i32 %313, %308
  %315 = sub i32 %311, %314
  store i32 %315, ptr %17, align 4
  store i32 -985447607, ptr %7, align 4
  %316 = xor i64 %0, 8894899274397727117
  %317 = and i64 %0, %316
  %318 = or i64 %0, %316
  %319 = xor i64 %0, %316
  %320 = mul i64 %318, 2
  %321 = sub i64 %320, %319
  %322 = sub i64 %321, %0
  %323 = sub i64 %322, %316
  %324 = mul i64 %323, 198
  %325 = icmp slt i64 %324, 0
  br i1 %325, label %681, label %339

326:                                              ; preds = %543
  %327 = load ptr, ptr %13, align 8
  call void @free(ptr noundef %327) #8
  store i32 -546718485, ptr %7, align 4
  %328 = xor i64 %0, 2841679115262224693
  %329 = and i64 %0, %328
  %330 = or i64 %0, %328
  %331 = xor i64 %0, %328
  %332 = add i64 %0, %328
  %333 = sub i64 %332, %331
  %334 = mul i64 %329, 2
  %335 = sub i64 %333, %334
  %336 = mul i64 %335, 40
  %337 = icmp sgt i64 %336, 0
  br i1 %337, label %690, label %339

338:                                              ; preds = %485
  ret void

339:                                              ; preds = %774, %764, %756, %746, %735, %727, %716, %707, %690, %681, %673, %663, %655, %646, %635, %625, %614, %603, %595, %584, %573, %565, %556, %547, %456, %443, %430, %418, %397, %386, %373, %351, %326, %304, %280, %263, %237, %218, %195, %178, %168, %139, %127, %113, %103, %75, %61, %24
  br label %19

340:                                              ; preds = %545, %543, %537, %533, %527, %523, %521, %517, %507, %503, %501, %497, %491, %487, %485, %481
  store i32 1749840022, ptr %7, align 4
  call void asm sideeffect "", ""()
  %341 = xor i64 %0, -947272483270680613
  %342 = and i64 %0, %341
  %343 = or i64 %0, %341
  %344 = xor i64 %0, %341
  %345 = add i64 %0, %341
  %346 = sub i64 %345, %344
  %347 = mul i64 %342, 2
  %348 = sub i64 %346, %347
  %349 = mul i64 %348, 65
  %350 = icmp slt i64 %349, 1
  br i1 %350, label %19, label %699

351:                                              ; preds = %533
  %352 = load i32, ptr %7, align 4
  %353 = xor i32 %352, -1236326082
  store i32 %353, ptr %7, align 4
  %354 = xor i64 %0, -6694199302939563363
  %355 = and i64 %0, %354
  %356 = or i64 %0, %354
  %357 = xor i64 %0, %354
  %358 = mul i64 %356, 2
  %359 = sub i64 %358, %357
  %360 = sub i64 %359, %0
  %361 = sub i64 %360, %354
  %362 = mul i64 %361, 134
  %363 = xor i64 %0, -6123492114522259701
  %364 = and i64 %0, %363
  %365 = or i64 %0, %363
  %366 = xor i64 %0, %363
  %367 = mul i64 %365, 2
  %368 = sub i64 %367, %366
  %369 = sub i64 %368, %0
  %370 = sub i64 %369, %363
  %371 = mul i64 %370, 191
  %372 = icmp ne i64 %362, %371
  br i1 %372, label %707, label %339

373:                                              ; preds = %507
  %374 = load i32, ptr %7, align 4
  %375 = xor i32 %374, -1574237597
  store i32 %375, ptr %7, align 4
  %376 = xor i64 %0, 1143009195939304587
  %377 = and i64 %0, %376
  %378 = or i64 %0, %376
  %379 = xor i64 %0, %376
  %380 = add i64 %0, %376
  %381 = sub i64 %380, %379
  %382 = mul i64 %377, 2
  %383 = sub i64 %381, %382
  %384 = mul i64 %383, 21
  %385 = icmp ne i64 %384, 0
  br i1 %385, label %716, label %339

386:                                              ; preds = %489
  %387 = load i32, ptr %7, align 4
  %388 = xor i32 %387, -1194159908
  store i32 %388, ptr %7, align 4
  %389 = xor i64 %0, 9017835967040027169
  %390 = and i64 %0, %389
  %391 = or i64 %0, %389
  %392 = xor i64 %0, %389
  %393 = sub i64 %391, %392
  %394 = sub i64 %393, %390
  %395 = mul i64 %394, 169
  %396 = icmp sgt i64 %395, 0
  br i1 %396, label %727, label %339

397:                                              ; preds = %541
  %398 = load i32, ptr %7, align 4
  %399 = xor i32 %398, 314118381
  store i32 %399, ptr %7, align 4
  %400 = xor i64 %0, -1030059233304282211
  %401 = and i64 %0, %400
  %402 = or i64 %0, %400
  %403 = xor i64 %0, %400
  %404 = add i64 %0, %400
  %405 = sub i64 %404, %403
  %406 = mul i64 %401, 2
  %407 = sub i64 %405, %406
  %408 = mul i64 %407, 204
  %409 = xor i64 %0, 6117390347487693701
  %410 = and i64 %0, %409
  %411 = or i64 %0, %409
  %412 = xor i64 %0, %409
  %413 = add i64 %410, %411
  %414 = sub i64 %413, %0
  %415 = sub i64 %414, %409
  %416 = mul i64 %415, 195
  %417 = icmp eq i64 %408, %416
  br i1 %417, label %339, label %735

418:                                              ; preds = %519
  %419 = load i32, ptr %7, align 4
  %420 = xor i32 %419, -1407891261
  store i32 %420, ptr %7, align 4
  %421 = xor i64 %0, -6815688638605262325
  %422 = and i64 %0, %421
  %423 = or i64 %0, %421
  %424 = xor i64 %0, %421
  %425 = add i64 %422, %423
  %426 = sub i64 %425, %0
  %427 = sub i64 %426, %421
  %428 = mul i64 %427, 13
  %429 = icmp slt i64 %428, 0
  br i1 %429, label %746, label %339

430:                                              ; preds = %535
  %431 = load i32, ptr %7, align 4
  %432 = xor i32 %431, 960880861
  store i32 %432, ptr %7, align 4
  %433 = xor i64 %0, -5423313942084368893
  %434 = and i64 %0, %433
  %435 = or i64 %0, %433
  %436 = xor i64 %0, %433
  %437 = add i64 %0, %433
  %438 = sub i64 %437, %436
  %439 = mul i64 %434, 2
  %440 = sub i64 %438, %439
  %441 = mul i64 %440, 44
  %442 = icmp ugt i64 %441, 0
  br i1 %442, label %756, label %339

443:                                              ; preds = %483
  %444 = load i32, ptr %7, align 4
  %445 = xor i32 %444, -5025349
  store i32 %445, ptr %7, align 4
  %446 = xor i64 %0, 4290471654534116093
  %447 = and i64 %0, %446
  %448 = or i64 %0, %446
  %449 = xor i64 %0, %446
  %450 = add i64 %0, %446
  %451 = sub i64 %450, %449
  %452 = mul i64 %447, 2
  %453 = sub i64 %451, %452
  %454 = mul i64 %453, 60
  %455 = icmp sle i64 %454, 0
  br i1 %455, label %339, label %764

456:                                              ; preds = %545
  %457 = load i32, ptr %7, align 4
  %458 = xor i32 %457, -1363125352
  store i32 %458, ptr %7, align 4
  %459 = xor i64 %0, -4984183040701083715
  %460 = and i64 %0, %459
  %461 = or i64 %0, %459
  %462 = xor i64 %0, %459
  %463 = mul i64 %461, 2
  %464 = sub i64 %463, %462
  %465 = sub i64 %464, %0
  %466 = sub i64 %465, %459
  %467 = mul i64 %466, 131
  %468 = icmp sle i64 %467, 0
  br i1 %468, label %339, label %774

469:                                              ; preds = %19
  %470 = icmp slt i32 %22, 586865536
  br i1 %470, label %473, label %475

471:                                              ; preds = %19
  %472 = icmp slt i32 %22, 1718999919
  br i1 %472, label %509, label %511

473:                                              ; preds = %469
  %474 = icmp slt i32 %22, 65172999
  br i1 %474, label %477, label %479

475:                                              ; preds = %469
  %476 = icmp slt i32 %22, 1280727443
  br i1 %476, label %493, label %495

477:                                              ; preds = %473
  %478 = icmp slt i32 %22, 38903127
  br i1 %478, label %481, label %483

479:                                              ; preds = %473
  %480 = icmp slt i32 %22, 410839959
  br i1 %480, label %487, label %489

481:                                              ; preds = %477
  %482 = icmp eq i32 %22, 18722798
  br i1 %482, label %263, label %340

483:                                              ; preds = %477
  %484 = icmp eq i32 %22, 38903127
  br i1 %484, label %443, label %485

485:                                              ; preds = %483
  %486 = icmp eq i32 %22, 60656523
  br i1 %486, label %338, label %340

487:                                              ; preds = %479
  %488 = icmp eq i32 %22, 65172999
  br i1 %488, label %103, label %340

489:                                              ; preds = %479
  %490 = icmp eq i32 %22, 410839959
  br i1 %490, label %386, label %491

491:                                              ; preds = %489
  %492 = icmp eq i32 %22, 421950753
  br i1 %492, label %237, label %340

493:                                              ; preds = %475
  %494 = icmp slt i32 %22, 737529183
  br i1 %494, label %497, label %499

495:                                              ; preds = %475
  %496 = icmp slt i32 %22, 1373186609
  br i1 %496, label %503, label %505

497:                                              ; preds = %493
  %498 = icmp eq i32 %22, 586865536
  br i1 %498, label %127, label %340

499:                                              ; preds = %493
  %500 = icmp eq i32 %22, 737529183
  br i1 %500, label %168, label %501

501:                                              ; preds = %499
  %502 = icmp eq i32 %22, 1142805406
  br i1 %502, label %139, label %340

503:                                              ; preds = %495
  %504 = icmp eq i32 %22, 1280727443
  br i1 %504, label %218, label %340

505:                                              ; preds = %495
  %506 = icmp eq i32 %22, 1373186609
  br i1 %506, label %195, label %507

507:                                              ; preds = %505
  %508 = icmp eq i32 %22, 1386015453
  br i1 %508, label %373, label %340

509:                                              ; preds = %471
  %510 = icmp slt i32 %22, 1507140101
  br i1 %510, label %513, label %515

511:                                              ; preds = %471
  %512 = icmp slt i32 %22, 1904500248
  br i1 %512, label %529, label %531

513:                                              ; preds = %509
  %514 = icmp slt i32 %22, 1446834400
  br i1 %514, label %517, label %519

515:                                              ; preds = %509
  %516 = icmp slt i32 %22, 1517289483
  br i1 %516, label %523, label %525

517:                                              ; preds = %513
  %518 = icmp eq i32 %22, 1391104869
  br i1 %518, label %75, label %340

519:                                              ; preds = %513
  %520 = icmp eq i32 %22, 1446834400
  br i1 %520, label %418, label %521

521:                                              ; preds = %519
  %522 = icmp eq i32 %22, 1478187548
  br i1 %522, label %280, label %340

523:                                              ; preds = %515
  %524 = icmp eq i32 %22, 1507140101
  br i1 %524, label %304, label %340

525:                                              ; preds = %515
  %526 = icmp eq i32 %22, 1517289483
  br i1 %526, label %178, label %527

527:                                              ; preds = %525
  %528 = icmp eq i32 %22, 1619268837
  br i1 %528, label %61, label %340

529:                                              ; preds = %511
  %530 = icmp slt i32 %22, 1777452079
  br i1 %530, label %533, label %535

531:                                              ; preds = %511
  %532 = icmp slt i32 %22, 2084188186
  br i1 %532, label %539, label %541

533:                                              ; preds = %529
  %534 = icmp eq i32 %22, 1718999919
  br i1 %534, label %351, label %340

535:                                              ; preds = %529
  %536 = icmp eq i32 %22, 1777452079
  br i1 %536, label %430, label %537

537:                                              ; preds = %535
  %538 = icmp eq i32 %22, 1869292778
  br i1 %538, label %24, label %340

539:                                              ; preds = %531
  %540 = icmp eq i32 %22, 1904500248
  br i1 %540, label %113, label %543

541:                                              ; preds = %531
  %542 = icmp eq i32 %22, 2084188186
  br i1 %542, label %397, label %545

543:                                              ; preds = %539
  %544 = icmp eq i32 %22, 1915623612
  br i1 %544, label %326, label %340

545:                                              ; preds = %541
  %546 = icmp eq i32 %22, 2118871088
  br i1 %546, label %456, label %340

547:                                              ; preds = %24
  %548 = load i64, ptr %6, align 8
  %549 = ptrtoint ptr %2 to i64
  %550 = ptrtoint ptr %3 to i64
  %551 = ptrtoint ptr %4 to i64
  %552 = mul i64 %551, %549
  %553 = add i64 %552, %0
  %554 = xor i64 %553, %1
  %555 = add i64 %554, %551
  store i64 %555, ptr %6, align 8
  br label %339

556:                                              ; preds = %61
  %557 = load i64, ptr %6, align 8
  %558 = ptrtoint ptr %2 to i64
  %559 = ptrtoint ptr %3 to i64
  %560 = ptrtoint ptr %4 to i64
  %561 = sub i64 %559, %1
  %562 = xor i64 %561, %0
  %563 = add i64 %562, %1
  %564 = add i64 %563, %1
  store i64 %564, ptr %6, align 8
  br label %339

565:                                              ; preds = %75
  %566 = load i64, ptr %6, align 8
  %567 = ptrtoint ptr %2 to i64
  %568 = ptrtoint ptr %3 to i64
  %569 = ptrtoint ptr %4 to i64
  %570 = add i64 %1, %0
  %571 = add i64 %570, %1
  %572 = mul i64 %571, %1
  store i64 %572, ptr %6, align 8
  br label %339

573:                                              ; preds = %103
  %574 = load i64, ptr %6, align 8
  %575 = ptrtoint ptr %2 to i64
  %576 = ptrtoint ptr %3 to i64
  %577 = ptrtoint ptr %4 to i64
  %578 = mul i64 %1, %1
  %579 = mul i64 %578, %574
  %580 = add i64 %579, %576
  %581 = mul i64 %580, %576
  %582 = sub i64 %581, %576
  %583 = xor i64 %582, %577
  store i64 %583, ptr %6, align 8
  br label %339

584:                                              ; preds = %113
  %585 = load i64, ptr %6, align 8
  %586 = ptrtoint ptr %2 to i64
  %587 = ptrtoint ptr %3 to i64
  %588 = ptrtoint ptr %4 to i64
  %589 = or i64 %1, %588
  %590 = add i64 %589, %587
  %591 = xor i64 %590, %588
  %592 = or i64 %591, %588
  %593 = xor i64 %592, %0
  %594 = sub i64 %593, %588
  store i64 %594, ptr %6, align 8
  br label %339

595:                                              ; preds = %127
  %596 = load i64, ptr %6, align 8
  %597 = ptrtoint ptr %2 to i64
  %598 = ptrtoint ptr %3 to i64
  %599 = ptrtoint ptr %4 to i64
  %600 = and i64 %1, %596
  %601 = and i64 %600, %0
  %602 = or i64 %601, %0
  store i64 %602, ptr %6, align 8
  br label %339

603:                                              ; preds = %139
  %604 = load i64, ptr %6, align 8
  %605 = ptrtoint ptr %2 to i64
  %606 = ptrtoint ptr %3 to i64
  %607 = ptrtoint ptr %4 to i64
  %608 = add i64 %606, %0
  %609 = xor i64 %608, %607
  %610 = and i64 %609, %1
  %611 = xor i64 %610, %605
  %612 = or i64 %611, %604
  %613 = or i64 %612, %607
  store i64 %613, ptr %6, align 8
  br label %339

614:                                              ; preds = %168
  %615 = load i64, ptr %6, align 8
  %616 = ptrtoint ptr %2 to i64
  %617 = ptrtoint ptr %3 to i64
  %618 = ptrtoint ptr %4 to i64
  %619 = or i64 %1, %1
  %620 = or i64 %619, %616
  %621 = xor i64 %620, %1
  %622 = sub i64 %621, %0
  %623 = xor i64 %622, %0
  %624 = sub i64 %623, %618
  store i64 %624, ptr %6, align 8
  br label %339

625:                                              ; preds = %178
  %626 = load i64, ptr %6, align 8
  %627 = ptrtoint ptr %2 to i64
  %628 = ptrtoint ptr %3 to i64
  %629 = ptrtoint ptr %4 to i64
  %630 = mul i64 %626, %626
  %631 = mul i64 %630, %626
  %632 = mul i64 %631, %627
  %633 = or i64 %632, %0
  %634 = mul i64 %633, %1
  store i64 %634, ptr %6, align 8
  br label %339

635:                                              ; preds = %195
  %636 = load i64, ptr %6, align 8
  %637 = ptrtoint ptr %2 to i64
  %638 = ptrtoint ptr %3 to i64
  %639 = ptrtoint ptr %4 to i64
  %640 = and i64 %0, %1
  %641 = add i64 %640, %0
  %642 = sub i64 %641, %0
  %643 = sub i64 %642, %637
  %644 = and i64 %643, %636
  %645 = add i64 %644, %639
  store i64 %645, ptr %6, align 8
  br label %339

646:                                              ; preds = %218
  %647 = load i64, ptr %6, align 8
  %648 = ptrtoint ptr %2 to i64
  %649 = ptrtoint ptr %3 to i64
  %650 = ptrtoint ptr %4 to i64
  %651 = xor i64 %649, %649
  %652 = and i64 %651, %650
  %653 = add i64 %652, %0
  %654 = sub i64 %653, %650
  store i64 %654, ptr %6, align 8
  br label %339

655:                                              ; preds = %237
  %656 = load i64, ptr %6, align 8
  %657 = ptrtoint ptr %2 to i64
  %658 = ptrtoint ptr %3 to i64
  %659 = ptrtoint ptr %4 to i64
  %660 = add i64 %657, %657
  %661 = xor i64 %660, %0
  %662 = mul i64 %661, %1
  store i64 %662, ptr %6, align 8
  br label %339

663:                                              ; preds = %263
  %664 = load i64, ptr %6, align 8
  %665 = ptrtoint ptr %2 to i64
  %666 = ptrtoint ptr %3 to i64
  %667 = ptrtoint ptr %4 to i64
  %668 = and i64 %667, %665
  %669 = mul i64 %668, %0
  %670 = xor i64 %669, %1
  %671 = sub i64 %670, %664
  %672 = sub i64 %671, %0
  store i64 %672, ptr %6, align 8
  br label %339

673:                                              ; preds = %280
  %674 = load i64, ptr %6, align 8
  %675 = ptrtoint ptr %2 to i64
  %676 = ptrtoint ptr %3 to i64
  %677 = ptrtoint ptr %4 to i64
  %678 = add i64 %675, %1
  %679 = and i64 %678, %677
  %680 = add i64 %679, %0
  store i64 %680, ptr %6, align 8
  br label %339

681:                                              ; preds = %304
  %682 = load i64, ptr %6, align 8
  %683 = ptrtoint ptr %2 to i64
  %684 = ptrtoint ptr %3 to i64
  %685 = ptrtoint ptr %4 to i64
  %686 = add i64 %1, %684
  %687 = and i64 %686, %1
  %688 = mul i64 %687, %684
  %689 = add i64 %688, %0
  store i64 %689, ptr %6, align 8
  br label %339

690:                                              ; preds = %326
  %691 = load i64, ptr %6, align 8
  %692 = ptrtoint ptr %2 to i64
  %693 = ptrtoint ptr %3 to i64
  %694 = ptrtoint ptr %4 to i64
  %695 = xor i64 %1, %692
  %696 = sub i64 %695, %692
  %697 = mul i64 %696, %694
  %698 = and i64 %697, %1
  store i64 %698, ptr %6, align 8
  br label %339

699:                                              ; preds = %340
  %700 = load i64, ptr %6, align 8
  %701 = ptrtoint ptr %2 to i64
  %702 = ptrtoint ptr %3 to i64
  %703 = ptrtoint ptr %4 to i64
  %704 = mul i64 %700, %700
  %705 = add i64 %704, %0
  %706 = add i64 %705, %703
  store i64 %706, ptr %6, align 8
  br label %19

707:                                              ; preds = %351
  %708 = load i64, ptr %6, align 8
  %709 = ptrtoint ptr %2 to i64
  %710 = ptrtoint ptr %3 to i64
  %711 = ptrtoint ptr %4 to i64
  %712 = xor i64 %710, %710
  %713 = add i64 %712, %710
  %714 = mul i64 %713, %0
  %715 = mul i64 %714, %710
  store i64 %715, ptr %6, align 8
  br label %339

716:                                              ; preds = %373
  %717 = load i64, ptr %6, align 8
  %718 = ptrtoint ptr %2 to i64
  %719 = ptrtoint ptr %3 to i64
  %720 = ptrtoint ptr %4 to i64
  %721 = add i64 %719, %719
  %722 = add i64 %721, %717
  %723 = add i64 %722, %717
  %724 = sub i64 %723, %720
  %725 = mul i64 %724, %1
  %726 = xor i64 %725, %718
  store i64 %726, ptr %6, align 8
  br label %339

727:                                              ; preds = %386
  %728 = load i64, ptr %6, align 8
  %729 = ptrtoint ptr %2 to i64
  %730 = ptrtoint ptr %3 to i64
  %731 = ptrtoint ptr %4 to i64
  %732 = add i64 %0, %731
  %733 = xor i64 %732, %731
  %734 = xor i64 %733, %728
  store i64 %734, ptr %6, align 8
  br label %339

735:                                              ; preds = %397
  %736 = load i64, ptr %6, align 8
  %737 = ptrtoint ptr %2 to i64
  %738 = ptrtoint ptr %3 to i64
  %739 = ptrtoint ptr %4 to i64
  %740 = or i64 %0, %739
  %741 = sub i64 %740, %739
  %742 = and i64 %741, %0
  %743 = add i64 %742, %0
  %744 = mul i64 %743, %738
  %745 = or i64 %744, %739
  store i64 %745, ptr %6, align 8
  br label %339

746:                                              ; preds = %418
  %747 = load i64, ptr %6, align 8
  %748 = ptrtoint ptr %2 to i64
  %749 = ptrtoint ptr %3 to i64
  %750 = ptrtoint ptr %4 to i64
  %751 = or i64 %747, %0
  %752 = or i64 %751, %747
  %753 = and i64 %752, %747
  %754 = xor i64 %753, %0
  %755 = mul i64 %754, %747
  store i64 %755, ptr %6, align 8
  br label %339

756:                                              ; preds = %430
  %757 = load i64, ptr %6, align 8
  %758 = ptrtoint ptr %2 to i64
  %759 = ptrtoint ptr %3 to i64
  %760 = ptrtoint ptr %4 to i64
  %761 = sub i64 %758, %1
  %762 = add i64 %761, %759
  %763 = or i64 %762, %1
  store i64 %763, ptr %6, align 8
  br label %339

764:                                              ; preds = %443
  %765 = load i64, ptr %6, align 8
  %766 = ptrtoint ptr %2 to i64
  %767 = ptrtoint ptr %3 to i64
  %768 = ptrtoint ptr %4 to i64
  %769 = xor i64 %768, %765
  %770 = mul i64 %769, %1
  %771 = add i64 %770, %768
  %772 = or i64 %771, %0
  %773 = add i64 %772, %768
  store i64 %773, ptr %6, align 8
  br label %339

774:                                              ; preds = %456
  %775 = load i64, ptr %6, align 8
  %776 = ptrtoint ptr %2 to i64
  %777 = ptrtoint ptr %3 to i64
  %778 = ptrtoint ptr %4 to i64
  %779 = xor i64 %777, %777
  %780 = mul i64 %779, %778
  %781 = or i64 %780, %778
  store i64 %781, ptr %6, align 8
  br label %339
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printDungeon(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 902376502, ptr %4, align 4
  br label %9

9:                                                ; preds = %290, %146, %145, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, 211484999
  %12 = mul i32 %11, -902781777
  switch i32 %12, label %146 [
    i32 1558213985, label %13
    i32 1731170920, label %24
    i32 1453126467, label %45
    i32 1473739721, label %73
    i32 2042630029, label %85
    i32 1352673391, label %98
    i32 2080386174, label %144
    i32 1925311759, label %157
    i32 1385711141, label %168
    i32 1360058447, label %180
    i32 1215677518, label %193
    i32 497859657, label %205
    i32 1339988033, label %216
    i32 1644637197, label %227
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str)
  store i32 0, ptr %7, align 4
  store i32 -1935048865, ptr %4, align 4
  %15 = xor i32 %1, -1517873223
  %16 = and i32 %1, %15
  %17 = or i32 %1, %15
  %18 = xor i32 %1, %15
  %19 = add i32 %16, %17
  %20 = sub i32 %19, %1
  %21 = sub i32 %20, %15
  %22 = mul i32 %21, 173
  %23 = icmp ugt i32 %22, 0
  br i1 %23, label %239, label %145

24:                                               ; preds = %9
  %25 = load i32, ptr %7, align 4
  %26 = load i32, ptr @N, align 4
  %27 = icmp slt i32 %25, %26
  %28 = select i1 %27, i32 -1272698636, i32 1762424398
  store i32 %28, ptr %4, align 4
  %29 = xor i32 %1, 1011065319
  %30 = and i32 %1, %29
  %31 = or i32 %1, %29
  %32 = xor i32 %1, %29
  %33 = sub i32 %31, %32
  %34 = sub i32 %33, %30
  %35 = mul i32 %34, 93
  %36 = xor i32 %1, 808999165
  %37 = and i32 %1, %36
  %38 = or i32 %1, %36
  %39 = xor i32 %1, %36
  %40 = add i32 %37, %38
  %41 = sub i32 %40, %1
  %42 = sub i32 %41, %36
  %43 = mul i32 %42, 19
  %44 = icmp ne i32 %35, %43
  br i1 %44, label %249, label %145

45:                                               ; preds = %9
  %46 = load ptr, ptr @grid, align 8
  %47 = load i32, ptr %7, align 4
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds ptr, ptr %46, i64 %48
  %50 = load ptr, ptr %49, align 8
  %51 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, ptr noundef %50)
  %52 = load i32, ptr %7, align 4
  %53 = load i32, ptr %4, align 4
  %54 = xor i32 %53, -1272698635
  %55 = sub i32 %52, %54
  %56 = load i32, ptr %4, align 4
  %57 = xor i32 %56, -1272698634
  %58 = mul i32 %52, %57
  %59 = load i32, ptr %4, align 4
  %60 = xor i32 %59, -1272698635
  %61 = mul i32 %60, %55
  %62 = sub i32 %58, %61
  store i32 %62, ptr %7, align 4
  store i32 -1935048865, ptr %4, align 4
  %63 = xor i32 %1, 1099530563
  %64 = and i32 %1, %63
  %65 = or i32 %1, %63
  %66 = xor i32 %1, %63
  %67 = add i32 %1, %63
  %68 = sub i32 %67, %66
  %69 = mul i32 %64, 2
  %70 = sub i32 %68, %69
  %71 = mul i32 %70, 96
  %72 = icmp uge i32 %71, 0
  br i1 %72, label %145, label %256

73:                                               ; preds = %9
  %74 = call i32 (ptr, ...) @printf(ptr noundef @.str.2)
  store i32 0, ptr %8, align 4
  store i32 -1109239862, ptr %4, align 4
  %75 = xor i32 %1, 1115321177
  %76 = and i32 %1, %75
  %77 = or i32 %1, %75
  %78 = xor i32 %1, %75
  %79 = add i32 %1, %75
  %80 = sub i32 %79, %78
  %81 = mul i32 %76, 2
  %82 = sub i32 %80, %81
  %83 = mul i32 %82, 211
  %84 = icmp ugt i32 %83, 0
  br i1 %84, label %264, label %145

85:                                               ; preds = %9
  %86 = load i32, ptr %8, align 4
  %87 = load i32, ptr %6, align 4
  %88 = icmp slt i32 %86, %87
  %89 = select i1 %88, i32 -41932408, i32 -375433175
  store i32 %89, ptr %4, align 4
  %90 = xor i32 %1, -1210682297
  %91 = and i32 %1, %90
  %92 = or i32 %1, %90
  %93 = xor i32 %1, %90
  %94 = sub i32 %92, %93
  %95 = sub i32 %94, %91
  %96 = mul i32 %95, 122
  %97 = icmp slt i32 %96, 1
  br i1 %97, label %145, label %271

98:                                               ; preds = %9
  %99 = load i32, ptr %8, align 4
  %100 = load i32, ptr %4, align 4
  %101 = xor i32 %100, -41932407
  %102 = or i32 %99, %101
  %103 = load i32, ptr %4, align 4
  %104 = xor i32 %103, -41932407
  %105 = and i32 %99, %104
  %106 = add i32 %102, %105
  %107 = load ptr, ptr %5, align 8
  %108 = load i32, ptr %8, align 4
  %109 = sext i32 %108 to i64
  %110 = getelementptr inbounds %struct.Point, ptr %107, i64 %109
  %111 = getelementptr inbounds nuw %struct.Point, ptr %110, i32 0, i32 0
  %112 = load i32, ptr %111, align 4
  %113 = load ptr, ptr %5, align 8
  %114 = load i32, ptr %8, align 4
  %115 = sext i32 %114 to i64
  %116 = getelementptr inbounds %struct.Point, ptr %113, i64 %115
  %117 = getelementptr inbounds nuw %struct.Point, ptr %116, i32 0, i32 1
  %118 = load i32, ptr %117, align 4
  %119 = call i32 (ptr, ...) @printf(ptr noundef @.str.3, i32 noundef %106, i32 noundef %112, i32 noundef %118)
  %120 = load i32, ptr %8, align 4
  %121 = load i32, ptr %4, align 4
  %122 = xor i32 %121, -41932407
  %123 = or i32 %120, %122
  %124 = load i32, ptr %4, align 4
  %125 = xor i32 %124, -41932407
  %126 = and i32 %120, %125
  %127 = add i32 %123, %126
  store i32 %127, ptr %8, align 4
  store i32 -1109239862, ptr %4, align 4
  %128 = xor i32 %1, 163599429
  %129 = and i32 %1, %128
  %130 = or i32 %1, %128
  %131 = xor i32 %1, %128
  %132 = add i32 %129, %130
  %133 = sub i32 %132, %1
  %134 = sub i32 %133, %128
  %135 = mul i32 %134, 233
  %136 = xor i32 %1, -1412316167
  %137 = and i32 %1, %136
  %138 = or i32 %1, %136
  %139 = xor i32 %1, %136
  %140 = sub i32 %138, %139
  %141 = sub i32 %140, %137
  %142 = mul i32 %141, 140
  %143 = icmp ne i32 %135, %142
  br i1 %143, label %280, label %145

144:                                              ; preds = %9
  ret void

145:                                              ; preds = %349, %339, %330, %322, %314, %305, %297, %280, %271, %264, %256, %249, %239, %227, %216, %205, %193, %180, %168, %157, %98, %85, %73, %45, %24, %13
  br label %9

146:                                              ; preds = %9
  store i32 902376502, ptr %4, align 4
  call void asm sideeffect "", ""()
  %147 = xor i32 %1, 1503206641
  %148 = and i32 %1, %147
  %149 = or i32 %1, %147
  %150 = xor i32 %1, %147
  %151 = add i32 %1, %147
  %152 = sub i32 %151, %150
  %153 = mul i32 %148, 2
  %154 = sub i32 %152, %153
  %155 = mul i32 %154, 212
  %156 = icmp sgt i32 %155, 0
  br i1 %156, label %290, label %9

157:                                              ; preds = %9
  %158 = load i32, ptr %4, align 4
  %159 = xor i32 %158, -2134326490
  store i32 %159, ptr %4, align 4
  %160 = xor i32 %1, 782049507
  %161 = and i32 %1, %160
  %162 = or i32 %1, %160
  %163 = xor i32 %1, %160
  %164 = sub i32 %162, %163
  %165 = sub i32 %164, %161
  %166 = mul i32 %165, 203
  %167 = icmp ugt i32 %166, 0
  br i1 %167, label %297, label %145

168:                                              ; preds = %9
  %169 = load i32, ptr %4, align 4
  %170 = xor i32 %169, -190148832
  store i32 %170, ptr %4, align 4
  %171 = xor i32 %1, 1969210991
  %172 = and i32 %1, %171
  %173 = or i32 %1, %171
  %174 = xor i32 %1, %171
  %175 = add i32 %172, %173
  %176 = sub i32 %175, %1
  %177 = sub i32 %176, %171
  %178 = mul i32 %177, 195
  %179 = icmp ne i32 %178, 0
  br i1 %179, label %305, label %145

180:                                              ; preds = %9
  %181 = load i32, ptr %4, align 4
  %182 = xor i32 %181, 839425649
  store i32 %182, ptr %4, align 4
  %183 = xor i32 %1, -358923573
  %184 = and i32 %1, %183
  %185 = or i32 %1, %183
  %186 = xor i32 %1, %183
  %187 = add i32 %1, %183
  %188 = sub i32 %187, %186
  %189 = mul i32 %184, 2
  %190 = sub i32 %188, %189
  %191 = mul i32 %190, 49
  %192 = icmp slt i32 %191, 1
  br i1 %192, label %145, label %314

193:                                              ; preds = %9
  %194 = load i32, ptr %4, align 4
  %195 = xor i32 %194, 1037596094
  store i32 %195, ptr %4, align 4
  %196 = xor i32 %1, -566142009
  %197 = and i32 %1, %196
  %198 = or i32 %1, %196
  %199 = xor i32 %1, %196
  %200 = add i32 %197, %198
  %201 = sub i32 %200, %1
  %202 = sub i32 %201, %196
  %203 = mul i32 %202, 85
  %204 = icmp sle i32 %203, 0
  br i1 %204, label %145, label %322

205:                                              ; preds = %9
  %206 = load i32, ptr %4, align 4
  %207 = xor i32 %206, 708409326
  store i32 %207, ptr %4, align 4
  %208 = xor i32 %1, -190487543
  %209 = and i32 %1, %208
  %210 = or i32 %1, %208
  %211 = xor i32 %1, %208
  %212 = sub i32 %210, %211
  %213 = sub i32 %212, %209
  %214 = mul i32 %213, 232
  %215 = icmp slt i32 %214, 0
  br i1 %215, label %330, label %145

216:                                              ; preds = %9
  %217 = load i32, ptr %4, align 4
  %218 = xor i32 %217, 1406261262
  store i32 %218, ptr %4, align 4
  %219 = xor i32 %1, -202075163
  %220 = and i32 %1, %219
  %221 = or i32 %1, %219
  %222 = xor i32 %1, %219
  %223 = sub i32 %221, %222
  %224 = sub i32 %223, %220
  %225 = mul i32 %224, 129
  %226 = icmp slt i32 %225, 1
  br i1 %226, label %145, label %339

227:                                              ; preds = %9
  %228 = load i32, ptr %4, align 4
  %229 = xor i32 %228, -1554887855
  store i32 %229, ptr %4, align 4
  %230 = xor i32 %1, 1382006543
  %231 = and i32 %1, %230
  %232 = or i32 %1, %230
  %233 = xor i32 %1, %230
  %234 = add i32 %231, %232
  %235 = sub i32 %234, %1
  %236 = sub i32 %235, %230
  %237 = mul i32 %236, 72
  %238 = icmp slt i32 %237, 0
  br i1 %238, label %349, label %145

239:                                              ; preds = %13
  %240 = load i64, ptr %3, align 8
  %241 = ptrtoint ptr %0 to i64
  %242 = zext i32 %1 to i64
  %243 = sub i64 %242, %240
  %244 = mul i64 %243, %242
  %245 = or i64 %244, %242
  %246 = or i64 %245, %242
  %247 = xor i64 %246, %241
  %248 = sub i64 %247, %240
  store i64 %248, ptr %3, align 8
  br label %145

249:                                              ; preds = %24
  %250 = load i64, ptr %3, align 8
  %251 = ptrtoint ptr %0 to i64
  %252 = zext i32 %1 to i64
  %253 = xor i64 %252, %250
  %254 = or i64 %253, %252
  %255 = and i64 %254, %252
  store i64 %255, ptr %3, align 8
  br label %145

256:                                              ; preds = %45
  %257 = load i64, ptr %3, align 8
  %258 = ptrtoint ptr %0 to i64
  %259 = zext i32 %1 to i64
  %260 = and i64 %259, %258
  %261 = or i64 %260, %259
  %262 = sub i64 %261, %257
  %263 = or i64 %262, %258
  store i64 %263, ptr %3, align 8
  br label %145

264:                                              ; preds = %73
  %265 = load i64, ptr %3, align 8
  %266 = ptrtoint ptr %0 to i64
  %267 = zext i32 %1 to i64
  %268 = or i64 %266, %266
  %269 = and i64 %268, %265
  %270 = mul i64 %269, %265
  store i64 %270, ptr %3, align 8
  br label %145

271:                                              ; preds = %85
  %272 = load i64, ptr %3, align 8
  %273 = ptrtoint ptr %0 to i64
  %274 = zext i32 %1 to i64
  %275 = mul i64 %272, %273
  %276 = xor i64 %275, %274
  %277 = or i64 %276, %274
  %278 = or i64 %277, %274
  %279 = add i64 %278, %273
  store i64 %279, ptr %3, align 8
  br label %145

280:                                              ; preds = %98
  %281 = load i64, ptr %3, align 8
  %282 = ptrtoint ptr %0 to i64
  %283 = zext i32 %1 to i64
  %284 = sub i64 %281, %282
  %285 = add i64 %284, %283
  %286 = sub i64 %285, %282
  %287 = xor i64 %286, %282
  %288 = xor i64 %287, %282
  %289 = or i64 %288, %281
  store i64 %289, ptr %3, align 8
  br label %145

290:                                              ; preds = %146
  %291 = load i64, ptr %3, align 8
  %292 = ptrtoint ptr %0 to i64
  %293 = zext i32 %1 to i64
  %294 = mul i64 %291, %292
  %295 = add i64 %294, %292
  %296 = sub i64 %295, %293
  store i64 %296, ptr %3, align 8
  br label %9

297:                                              ; preds = %157
  %298 = load i64, ptr %3, align 8
  %299 = ptrtoint ptr %0 to i64
  %300 = zext i32 %1 to i64
  %301 = xor i64 %298, %299
  %302 = xor i64 %301, %299
  %303 = add i64 %302, %299
  %304 = add i64 %303, %300
  store i64 %304, ptr %3, align 8
  br label %145

305:                                              ; preds = %168
  %306 = load i64, ptr %3, align 8
  %307 = ptrtoint ptr %0 to i64
  %308 = zext i32 %1 to i64
  %309 = or i64 %306, %307
  %310 = sub i64 %309, %306
  %311 = or i64 %310, %307
  %312 = add i64 %311, %306
  %313 = sub i64 %312, %306
  store i64 %313, ptr %3, align 8
  br label %145

314:                                              ; preds = %180
  %315 = load i64, ptr %3, align 8
  %316 = ptrtoint ptr %0 to i64
  %317 = zext i32 %1 to i64
  %318 = mul i64 %317, %315
  %319 = mul i64 %318, %316
  %320 = or i64 %319, %317
  %321 = add i64 %320, %315
  store i64 %321, ptr %3, align 8
  br label %145

322:                                              ; preds = %193
  %323 = load i64, ptr %3, align 8
  %324 = ptrtoint ptr %0 to i64
  %325 = zext i32 %1 to i64
  %326 = and i64 %323, %324
  %327 = mul i64 %326, %324
  %328 = xor i64 %327, %324
  %329 = add i64 %328, %324
  store i64 %329, ptr %3, align 8
  br label %145

330:                                              ; preds = %205
  %331 = load i64, ptr %3, align 8
  %332 = ptrtoint ptr %0 to i64
  %333 = zext i32 %1 to i64
  %334 = sub i64 %331, %332
  %335 = xor i64 %334, %333
  %336 = mul i64 %335, %332
  %337 = sub i64 %336, %331
  %338 = or i64 %337, %333
  store i64 %338, ptr %3, align 8
  br label %145

339:                                              ; preds = %216
  %340 = load i64, ptr %3, align 8
  %341 = ptrtoint ptr %0 to i64
  %342 = zext i32 %1 to i64
  %343 = mul i64 %341, %340
  %344 = add i64 %343, %340
  %345 = mul i64 %344, %340
  %346 = mul i64 %345, %341
  %347 = and i64 %346, %340
  %348 = mul i64 %347, %340
  store i64 %348, ptr %3, align 8
  br label %145

349:                                              ; preds = %227
  %350 = load i64, ptr %3, align 8
  %351 = ptrtoint ptr %0 to i64
  %352 = zext i32 %1 to i64
  %353 = or i64 %350, %351
  %354 = add i64 %353, %352
  %355 = xor i64 %354, %350
  %356 = sub i64 %355, %350
  %357 = add i64 %356, %350
  %358 = xor i64 %357, %352
  store i64 %358, ptr %3, align 8
  br label %145
}

declare i32 @printf(ptr noundef, ...) #5

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printRoute(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 1117597989, ptr %4, align 4
  br label %8

8:                                                ; preds = %357, %168, %167, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -1233938328
  %11 = mul i32 %10, 1376849715
  switch i32 %11, label %168 [
    i32 180977831, label %12
    i32 512543079, label %24
    i32 1163279653, label %39
    i32 1345848955, label %74
    i32 1943231948, label %84
    i32 1895303786, label %107
    i32 926758910, label %127
    i32 732675877, label %139
    i32 929104552, label %165
    i32 500555260, label %184
    i32 622418454, label %195
    i32 1983897502, label %208
    i32 1051605419, label %219
    i32 644293916, label %232
    i32 246411600, label %244
    i32 1862538918, label %257
    i32 151704937, label %278
  ]

12:                                               ; preds = %8
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %13 = call i32 (ptr, ...) @printf(ptr noundef @.str.4)
  store i32 0, ptr %7, align 4
  store i32 -1659910811, ptr %4, align 4
  %14 = xor i32 %1, 861390599
  %15 = and i32 %1, %14
  %16 = or i32 %1, %14
  %17 = xor i32 %1, %14
  %18 = mul i32 %16, 2
  %19 = sub i32 %18, %17
  %20 = sub i32 %19, %1
  %21 = sub i32 %20, %14
  %22 = mul i32 %21, 39
  %23 = icmp slt i32 %22, 0
  br i1 %23, label %289, label %167

24:                                               ; preds = %8
  %25 = load i32, ptr %7, align 4
  %26 = load i32, ptr %6, align 4
  %27 = icmp slt i32 %25, %26
  %28 = select i1 %27, i32 914651823, i32 -2143999200
  store i32 %28, ptr %4, align 4
  %29 = xor i32 %1, -1776558735
  %30 = and i32 %1, %29
  %31 = or i32 %1, %29
  %32 = xor i32 %1, %29
  %33 = add i32 %1, %29
  %34 = sub i32 %33, %32
  %35 = mul i32 %30, 2
  %36 = sub i32 %34, %35
  %37 = mul i32 %36, 175
  %38 = icmp sgt i32 %37, 0
  br i1 %38, label %299, label %167

39:                                               ; preds = %8
  %40 = load ptr, ptr %5, align 8
  %41 = load i32, ptr %7, align 4
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds %struct.Point, ptr %40, i64 %42
  %44 = getelementptr inbounds nuw %struct.Point, ptr %43, i32 0, i32 0
  %45 = load i32, ptr %44, align 4
  %46 = load ptr, ptr %5, align 8
  %47 = load i32, ptr %7, align 4
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds %struct.Point, ptr %46, i64 %48
  %50 = getelementptr inbounds nuw %struct.Point, ptr %49, i32 0, i32 1
  %51 = load i32, ptr %50, align 4
  %52 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %45, i32 noundef %51)
  %53 = load i32, ptr %7, align 4
  %54 = load i32, ptr %4, align 4
  %55 = xor i32 %54, 914651822
  %56 = xor i32 %53, %55
  %57 = load i32, ptr %4, align 4
  %58 = xor i32 %57, 914651822
  %59 = and i32 %53, %58
  %60 = add i32 %59, %59
  %61 = add i32 %56, %60
  %62 = load i32, ptr %6, align 4
  %63 = icmp slt i32 %61, %62
  %64 = select i1 %63, i32 -1483086847, i32 -827591828
  store i32 %64, ptr %4, align 4
  %65 = xor i32 %1, 1790829631
  %66 = and i32 %1, %65
  %67 = or i32 %1, %65
  %68 = xor i32 %1, %65
  %69 = add i32 %66, %67
  %70 = sub i32 %69, %1
  %71 = sub i32 %70, %65
  %72 = mul i32 %71, 6
  %73 = icmp ne i32 %72, 0
  br i1 %73, label %307, label %167

74:                                               ; preds = %8
  %75 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  store i32 -827591828, ptr %4, align 4
  %76 = xor i32 %1, 1759454225
  %77 = and i32 %1, %76
  %78 = or i32 %1, %76
  %79 = xor i32 %1, %76
  %80 = sub i32 %78, %79
  %81 = sub i32 %80, %77
  %82 = mul i32 %81, 91
  %83 = icmp eq i32 %82, 0
  br i1 %83, label %167, label %314

84:                                               ; preds = %8
  %85 = load i32, ptr %7, align 4
  %86 = load i32, ptr %4, align 4
  %87 = xor i32 %86, -827591827
  %88 = xor i32 %85, %87
  %89 = load i32, ptr %4, align 4
  %90 = xor i32 %89, -827591827
  %91 = and i32 %85, %90
  %92 = add i32 %91, %91
  %93 = add i32 %88, %92
  %94 = srem i32 %93, 8
  %95 = icmp eq i32 %94, 0
  %96 = select i1 %95, i32 1846283350, i32 1474359471
  store i32 %96, ptr %4, align 4
  %97 = xor i32 %1, 466706709
  %98 = and i32 %1, %97
  %99 = or i32 %1, %97
  %100 = xor i32 %1, %97
  %101 = mul i32 %99, 2
  %102 = sub i32 %101, %100
  %103 = sub i32 %102, %1
  %104 = sub i32 %103, %97
  %105 = mul i32 %104, 150
  %106 = icmp slt i32 %105, 1
  br i1 %106, label %167, label %322

107:                                              ; preds = %8
  %108 = load i32, ptr %7, align 4
  %109 = load i32, ptr %4, align 4
  %110 = xor i32 %109, 1846283351
  %111 = or i32 %108, %110
  %112 = load i32, ptr %4, align 4
  %113 = xor i32 %112, 1846283351
  %114 = and i32 %108, %113
  %115 = add i32 %111, %114
  %116 = load i32, ptr %6, align 4
  %117 = icmp slt i32 %115, %116
  %118 = select i1 %117, i32 1679194226, i32 1474359471
  store i32 %118, ptr %4, align 4
  %119 = xor i32 %1, -1915655363
  %120 = and i32 %1, %119
  %121 = or i32 %1, %119
  %122 = xor i32 %1, %119
  %123 = sub i32 %121, %122
  %124 = sub i32 %123, %120
  %125 = mul i32 %124, 89
  %126 = icmp slt i32 %125, 1
  br i1 %126, label %167, label %332

127:                                              ; preds = %8
  %128 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  store i32 1474359471, ptr %4, align 4
  %129 = xor i32 %1, 1076118965
  %130 = and i32 %1, %129
  %131 = or i32 %1, %129
  %132 = xor i32 %1, %129
  %133 = add i32 %1, %129
  %134 = sub i32 %133, %132
  %135 = mul i32 %130, 2
  %136 = sub i32 %134, %135
  %137 = mul i32 %136, 12
  %138 = icmp ne i32 %137, 0
  br i1 %138, label %340, label %167

139:                                              ; preds = %8
  %140 = load i32, ptr %7, align 4
  %141 = load i32, ptr %4, align 4
  %142 = xor i32 %141, 1474359470
  %143 = or i32 %140, %142
  %144 = load i32, ptr %4, align 4
  %145 = xor i32 %144, 1474359470
  %146 = and i32 %140, %145
  %147 = add i32 %143, %146
  store i32 %147, ptr %7, align 4
  store i32 -1659910811, ptr %4, align 4
  %148 = xor i32 %1, 1999832719
  %149 = and i32 %1, %148
  %150 = or i32 %1, %148
  %151 = xor i32 %1, %148
  %152 = sub i32 %150, %151
  %153 = sub i32 %152, %149
  %154 = mul i32 %153, 215
  %155 = xor i32 %1, 1430745825
  %156 = and i32 %1, %155
  %157 = or i32 %1, %155
  %158 = xor i32 %1, %155
  %159 = mul i32 %157, 2
  %160 = sub i32 %159, %158
  %161 = sub i32 %160, %1
  %162 = sub i32 %161, %155
  %163 = mul i32 %162, 57
  %164 = icmp ne i32 %154, %163
  br i1 %164, label %348, label %167

165:                                              ; preds = %8
  %166 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  ret void

167:                                              ; preds = %421, %414, %407, %399, %392, %383, %375, %367, %348, %340, %332, %322, %314, %307, %299, %289, %278, %257, %244, %232, %219, %208, %195, %184, %139, %127, %107, %84, %74, %39, %24, %12
  br label %8

168:                                              ; preds = %8
  store i32 1117597989, ptr %4, align 4
  call void asm sideeffect "", ""()
  %169 = xor i32 %1, 408783489
  %170 = and i32 %1, %169
  %171 = or i32 %1, %169
  %172 = xor i32 %1, %169
  %173 = sub i32 %171, %172
  %174 = sub i32 %173, %170
  %175 = mul i32 %174, 105
  %176 = xor i32 %1, -1840800127
  %177 = and i32 %1, %176
  %178 = or i32 %1, %176
  %179 = xor i32 %1, %176
  %180 = sub i32 %178, %179
  %181 = sub i32 %180, %177
  %182 = mul i32 %181, 67
  %183 = icmp eq i32 %175, %182
  br i1 %183, label %8, label %357

184:                                              ; preds = %8
  %185 = load i32, ptr %4, align 4
  %186 = xor i32 %185, -882113433
  store i32 %186, ptr %4, align 4
  %187 = xor i32 %1, -121985419
  %188 = and i32 %1, %187
  %189 = or i32 %1, %187
  %190 = xor i32 %1, %187
  %191 = sub i32 %189, %190
  %192 = sub i32 %191, %188
  %193 = mul i32 %192, 7
  %194 = icmp sgt i32 %193, 0
  br i1 %194, label %367, label %167

195:                                              ; preds = %8
  %196 = load i32, ptr %4, align 4
  %197 = xor i32 %196, -675689838
  store i32 %197, ptr %4, align 4
  %198 = xor i32 %1, 1218080717
  %199 = and i32 %1, %198
  %200 = or i32 %1, %198
  %201 = xor i32 %1, %198
  %202 = mul i32 %200, 2
  %203 = sub i32 %202, %201
  %204 = sub i32 %203, %1
  %205 = sub i32 %204, %198
  %206 = mul i32 %205, 8
  %207 = icmp sgt i32 %206, 0
  br i1 %207, label %375, label %167

208:                                              ; preds = %8
  %209 = load i32, ptr %4, align 4
  %210 = xor i32 %209, 1173904034
  store i32 %210, ptr %4, align 4
  %211 = xor i32 %1, 743228191
  %212 = and i32 %1, %211
  %213 = or i32 %1, %211
  %214 = xor i32 %1, %211
  %215 = sub i32 %213, %214
  %216 = sub i32 %215, %212
  %217 = mul i32 %216, 195
  %218 = icmp sgt i32 %217, 0
  br i1 %218, label %383, label %167

219:                                              ; preds = %8
  %220 = load i32, ptr %4, align 4
  %221 = xor i32 %220, 2007635181
  store i32 %221, ptr %4, align 4
  %222 = xor i32 %1, -1659282329
  %223 = and i32 %1, %222
  %224 = or i32 %1, %222
  %225 = xor i32 %1, %222
  %226 = add i32 %1, %222
  %227 = sub i32 %226, %225
  %228 = mul i32 %223, 2
  %229 = sub i32 %227, %228
  %230 = mul i32 %229, 137
  %231 = icmp ugt i32 %230, 0
  br i1 %231, label %392, label %167

232:                                              ; preds = %8
  %233 = load i32, ptr %4, align 4
  %234 = xor i32 %233, 1690360421
  store i32 %234, ptr %4, align 4
  %235 = xor i32 %1, 340248723
  %236 = and i32 %1, %235
  %237 = or i32 %1, %235
  %238 = xor i32 %1, %235
  %239 = add i32 %236, %237
  %240 = sub i32 %239, %1
  %241 = sub i32 %240, %235
  %242 = mul i32 %241, 54
  %243 = icmp uge i32 %242, 0
  br i1 %243, label %167, label %399

244:                                              ; preds = %8
  %245 = load i32, ptr %4, align 4
  %246 = xor i32 %245, 681323376
  store i32 %246, ptr %4, align 4
  %247 = xor i32 %1, 1070494613
  %248 = and i32 %1, %247
  %249 = or i32 %1, %247
  %250 = xor i32 %1, %247
  %251 = mul i32 %249, 2
  %252 = sub i32 %251, %250
  %253 = sub i32 %252, %1
  %254 = sub i32 %253, %247
  %255 = mul i32 %254, 229
  %256 = icmp uge i32 %255, 0
  br i1 %256, label %167, label %407

257:                                              ; preds = %8
  %258 = load i32, ptr %4, align 4
  %259 = xor i32 %258, -213032449
  store i32 %259, ptr %4, align 4
  %260 = xor i32 %1, 63320099
  %261 = and i32 %1, %260
  %262 = or i32 %1, %260
  %263 = xor i32 %1, %260
  %264 = mul i32 %262, 2
  %265 = sub i32 %264, %263
  %266 = sub i32 %265, %1
  %267 = sub i32 %266, %260
  %268 = mul i32 %267, 68
  %269 = xor i32 %1, 1529782761
  %270 = and i32 %1, %269
  %271 = or i32 %1, %269
  %272 = xor i32 %1, %269
  %273 = add i32 %270, %271
  %274 = sub i32 %273, %1
  %275 = sub i32 %274, %269
  %276 = mul i32 %275, 207
  %277 = icmp ne i32 %268, %276
  br i1 %277, label %414, label %167

278:                                              ; preds = %8
  %279 = load i32, ptr %4, align 4
  %280 = xor i32 %279, -719342286
  store i32 %280, ptr %4, align 4
  %281 = xor i32 %1, -1603255793
  %282 = and i32 %1, %281
  %283 = or i32 %1, %281
  %284 = xor i32 %1, %281
  %285 = sub i32 %283, %284
  %286 = sub i32 %285, %282
  %287 = mul i32 %286, 9
  %288 = icmp ugt i32 %287, 0
  br i1 %288, label %421, label %167

289:                                              ; preds = %12
  %290 = load i64, ptr %3, align 8
  %291 = ptrtoint ptr %0 to i64
  %292 = zext i32 %1 to i64
  %293 = add i64 %291, %290
  %294 = xor i64 %293, %291
  %295 = or i64 %294, %292
  %296 = and i64 %295, %292
  %297 = mul i64 %296, %291
  %298 = or i64 %297, %290
  store i64 %298, ptr %3, align 8
  br label %167

299:                                              ; preds = %24
  %300 = load i64, ptr %3, align 8
  %301 = ptrtoint ptr %0 to i64
  %302 = zext i32 %1 to i64
  %303 = or i64 %301, %302
  %304 = xor i64 %303, %301
  %305 = xor i64 %304, %300
  %306 = or i64 %305, %301
  store i64 %306, ptr %3, align 8
  br label %167

307:                                              ; preds = %39
  %308 = load i64, ptr %3, align 8
  %309 = ptrtoint ptr %0 to i64
  %310 = zext i32 %1 to i64
  %311 = or i64 %310, %310
  %312 = mul i64 %311, %308
  %313 = xor i64 %312, %309
  store i64 %313, ptr %3, align 8
  br label %167

314:                                              ; preds = %74
  %315 = load i64, ptr %3, align 8
  %316 = ptrtoint ptr %0 to i64
  %317 = zext i32 %1 to i64
  %318 = add i64 %315, %315
  %319 = xor i64 %318, %316
  %320 = or i64 %319, %315
  %321 = mul i64 %320, %315
  store i64 %321, ptr %3, align 8
  br label %167

322:                                              ; preds = %84
  %323 = load i64, ptr %3, align 8
  %324 = ptrtoint ptr %0 to i64
  %325 = zext i32 %1 to i64
  %326 = add i64 %325, %325
  %327 = or i64 %326, %324
  %328 = mul i64 %327, %325
  %329 = xor i64 %328, %324
  %330 = mul i64 %329, %323
  %331 = xor i64 %330, %324
  store i64 %331, ptr %3, align 8
  br label %167

332:                                              ; preds = %107
  %333 = load i64, ptr %3, align 8
  %334 = ptrtoint ptr %0 to i64
  %335 = zext i32 %1 to i64
  %336 = mul i64 %333, %335
  %337 = xor i64 %336, %334
  %338 = or i64 %337, %333
  %339 = mul i64 %338, %335
  store i64 %339, ptr %3, align 8
  br label %167

340:                                              ; preds = %127
  %341 = load i64, ptr %3, align 8
  %342 = ptrtoint ptr %0 to i64
  %343 = zext i32 %1 to i64
  %344 = add i64 %342, %341
  %345 = mul i64 %344, %342
  %346 = add i64 %345, %341
  %347 = and i64 %346, %341
  store i64 %347, ptr %3, align 8
  br label %167

348:                                              ; preds = %139
  %349 = load i64, ptr %3, align 8
  %350 = ptrtoint ptr %0 to i64
  %351 = zext i32 %1 to i64
  %352 = sub i64 %350, %351
  %353 = add i64 %352, %349
  %354 = mul i64 %353, %351
  %355 = add i64 %354, %349
  %356 = or i64 %355, %351
  store i64 %356, ptr %3, align 8
  br label %167

357:                                              ; preds = %168
  %358 = load i64, ptr %3, align 8
  %359 = ptrtoint ptr %0 to i64
  %360 = zext i32 %1 to i64
  %361 = xor i64 %360, %360
  %362 = xor i64 %361, %358
  %363 = xor i64 %362, %359
  %364 = and i64 %363, %360
  %365 = xor i64 %364, %360
  %366 = and i64 %365, %358
  store i64 %366, ptr %3, align 8
  br label %8

367:                                              ; preds = %184
  %368 = load i64, ptr %3, align 8
  %369 = ptrtoint ptr %0 to i64
  %370 = zext i32 %1 to i64
  %371 = mul i64 %369, %368
  %372 = sub i64 %371, %370
  %373 = and i64 %372, %370
  %374 = and i64 %373, %370
  store i64 %374, ptr %3, align 8
  br label %167

375:                                              ; preds = %195
  %376 = load i64, ptr %3, align 8
  %377 = ptrtoint ptr %0 to i64
  %378 = zext i32 %1 to i64
  %379 = mul i64 %376, %376
  %380 = add i64 %379, %378
  %381 = mul i64 %380, %376
  %382 = sub i64 %381, %378
  store i64 %382, ptr %3, align 8
  br label %167

383:                                              ; preds = %208
  %384 = load i64, ptr %3, align 8
  %385 = ptrtoint ptr %0 to i64
  %386 = zext i32 %1 to i64
  %387 = and i64 %386, %384
  %388 = mul i64 %387, %386
  %389 = mul i64 %388, %386
  %390 = add i64 %389, %385
  %391 = or i64 %390, %386
  store i64 %391, ptr %3, align 8
  br label %167

392:                                              ; preds = %219
  %393 = load i64, ptr %3, align 8
  %394 = ptrtoint ptr %0 to i64
  %395 = zext i32 %1 to i64
  %396 = mul i64 %395, %394
  %397 = or i64 %396, %393
  %398 = or i64 %397, %394
  store i64 %398, ptr %3, align 8
  br label %167

399:                                              ; preds = %232
  %400 = load i64, ptr %3, align 8
  %401 = ptrtoint ptr %0 to i64
  %402 = zext i32 %1 to i64
  %403 = add i64 %402, %401
  %404 = sub i64 %403, %401
  %405 = mul i64 %404, %402
  %406 = and i64 %405, %400
  store i64 %406, ptr %3, align 8
  br label %167

407:                                              ; preds = %244
  %408 = load i64, ptr %3, align 8
  %409 = ptrtoint ptr %0 to i64
  %410 = zext i32 %1 to i64
  %411 = xor i64 %409, %410
  %412 = xor i64 %411, %410
  %413 = mul i64 %412, %410
  store i64 %413, ptr %3, align 8
  br label %167

414:                                              ; preds = %257
  %415 = load i64, ptr %3, align 8
  %416 = ptrtoint ptr %0 to i64
  %417 = zext i32 %1 to i64
  %418 = and i64 %416, %415
  %419 = mul i64 %418, %415
  %420 = mul i64 %419, %415
  store i64 %420, ptr %3, align 8
  br label %167

421:                                              ; preds = %278
  %422 = load i64, ptr %3, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = zext i32 %1 to i64
  %425 = or i64 %424, %423
  %426 = or i64 %425, %424
  %427 = or i64 %426, %422
  %428 = or i64 %427, %422
  %429 = xor i64 %428, %423
  %430 = xor i64 %429, %422
  store i64 %430, ptr %3, align 8
  br label %167
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @2, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %struct.Point, align 4
  %6 = alloca %struct.Point, align 4
  %7 = alloca [8 x %struct.Point], align 16
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca ptr, align 8
  %14 = alloca ptr, align 8
  %15 = alloca i32, align 4
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  %20 = alloca ptr, align 8
  %21 = alloca ptr, align 8
  %22 = alloca i32, align 4
  %23 = alloca i32, align 4
  %24 = alloca i32, align 4
  %25 = alloca i32, align 4
  %26 = alloca i32, align 4
  %27 = alloca i32, align 4
  %28 = alloca i32, align 4
  %29 = alloca i32, align 4
  %30 = alloca i32, align 4
  %31 = alloca i32, align 4
  %32 = alloca i32, align 4
  %33 = alloca i32, align 4
  %34 = alloca i32, align 4
  %35 = alloca i32, align 4
  %36 = alloca i32, align 4
  %37 = alloca i32, align 4
  %38 = alloca i32, align 4
  %39 = alloca ptr, align 8
  %40 = alloca i32, align 4
  %41 = alloca i32, align 4
  %42 = alloca i32, align 4
  %43 = alloca i32, align 4
  %44 = alloca i32, align 4
  %45 = alloca i32, align 4
  %46 = alloca ptr, align 8
  %47 = alloca i32, align 4
  %48 = alloca i32, align 4
  %49 = alloca i32, align 4
  %50 = alloca i32, align 4
  %51 = alloca i32, align 4
  %52 = alloca i32, align 4
  store i32 78377744, ptr %3, align 4
  br label %53

53:                                               ; preds = %2358, %1788, %1787, %0
  %54 = load i32, ptr %3, align 4
  %55 = sub i32 %54, 2108246304
  %56 = mul i32 %55, -1372331685
  switch i32 %56, label %1788 [
    i32 1344165968, label %57
    i32 1503142893, label %71
    i32 1397679665, label %83
    i32 1138731410, label %106
    i32 1239718666, label %125
    i32 1925417655, label %135
    i32 1628286631, label %161
    i32 2054687154, label %175
    i32 1098756999, label %208
    i32 814328903, label %241
    i32 1416191988, label %254
    i32 499936267, label %305
    i32 1969509449, label %319
    i32 231656890, label %334
    i32 1185775752, label %353
    i32 1709408553, label %367
    i32 545948197, label %416
    i32 1923490265, label %435
    i32 1283753053, label %466
    i32 1127029912, label %480
    i32 1952070040, label %499
    i32 120884041, label %512
    i32 1847833252, label %561
    i32 1079448644, label %581
    i32 706119432, label %601
    i32 353275312, label %625
    i32 852897714, label %661
    i32 520092069, label %690
    i32 1223416059, label %709
    i32 1069913244, label %720
    i32 307749469, label %735
    i32 442233638, label %744
    i32 340481934, label %757
    i32 833627688, label %782
    i32 842835857, label %793
    i32 873618839, label %804
    i32 1970050157, label %819
    i32 471614871, label %841
    i32 501851420, label %850
    i32 1761579048, label %890
    i32 1814379342, label %901
    i32 1924123531, label %943
    i32 439074394, label %982
    i32 1163214249, label %993
    i32 167609503, label %1010
    i32 1345909662, label %1021
    i32 219317411, label %1039
    i32 775092624, label %1061
    i32 401554245, label %1091
    i32 1157313183, label %1104
    i32 1371978057, label %1157
    i32 140972480, label %1171
    i32 1798862470, label %1181
    i32 1978322030, label %1200
    i32 2086988815, label %1218
    i32 1497264348, label %1238
    i32 1785783632, label %1258
    i32 2078268161, label %1277
    i32 538366439, label %1288
    i32 1841742733, label %1313
    i32 696419440, label %1327
    i32 1828934703, label %1378
    i32 1276115202, label %1389
    i32 401391599, label %1404
    i32 1640601410, label %1485
    i32 1239280024, label %1511
    i32 2001316457, label %1526
    i32 835189548, label %1581
    i32 1804053277, label %1606
    i32 1560524986, label %1619
    i32 1262584136, label %1631
    i32 1495356693, label %1642
    i32 1612460515, label %1675
    i32 1195493774, label %1692
    i32 915374731, label %1711
    i32 836925916, label %1731
    i32 841297959, label %1768
    i32 1836087613, label %1785
    i32 1420939495, label %1808
    i32 423035404, label %1821
    i32 424017755, label %1832
    i32 998513158, label %1845
    i32 179983839, label %1865
    i32 413119667, label %1878
    i32 1775155725, label %1890
    i32 46943074, label %1903
  ]

57:                                               ; preds = %53
  store i32 0, ptr %4, align 4
  %58 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str.8, ptr noundef @N)
  %59 = icmp ne i32 %58, 1
  %60 = select i1 %59, i32 -2106305673, i32 1625393539
  store i32 %60, ptr %3, align 4
  %61 = xor i32 %2, 849064815
  %62 = and i32 %2, %61
  %63 = or i32 %2, %61
  %64 = xor i32 %2, %61
  %65 = add i32 %2, %61
  %66 = sub i32 %65, %64
  %67 = mul i32 %62, 2
  %68 = sub i32 %66, %67
  %69 = mul i32 %68, 25
  %70 = icmp ne i32 %69, 0
  br i1 %70, label %1914, label %1787

71:                                               ; preds = %53
  %72 = call i32 (ptr, ...) @printf(ptr noundef @.str.9)
  store i32 0, ptr %4, align 4
  store i32 462455911, ptr %3, align 4
  %73 = xor i32 %2, -1686083833
  %74 = and i32 %2, %73
  %75 = or i32 %2, %73
  %76 = xor i32 %2, %73
  %77 = add i32 %2, %73
  %78 = sub i32 %77, %76
  %79 = mul i32 %74, 2
  %80 = sub i32 %78, %79
  %81 = mul i32 %80, 97
  %82 = icmp uge i32 %81, 0
  br i1 %82, label %1787, label %1920

83:                                               ; preds = %53
  %84 = load i32, ptr @N, align 4
  %85 = icmp slt i32 %84, 4
  %86 = select i1 %85, i32 1471483486, i32 976500854
  store i32 %86, ptr %3, align 4
  %87 = xor i32 %2, -671635741
  %88 = and i32 %2, %87
  %89 = or i32 %2, %87
  %90 = xor i32 %2, %87
  %91 = mul i32 %89, 2
  %92 = sub i32 %91, %90
  %93 = sub i32 %92, %2
  %94 = sub i32 %93, %87
  %95 = mul i32 %94, 150
  %96 = xor i32 %2, 832843167
  %97 = and i32 %2, %96
  %98 = or i32 %2, %96
  %99 = xor i32 %2, %96
  %100 = add i32 %2, %96
  %101 = sub i32 %100, %99
  %102 = mul i32 %97, 2
  %103 = sub i32 %101, %102
  %104 = mul i32 %103, 169
  %105 = icmp ne i32 %95, %104
  br i1 %105, label %1926, label %1787

106:                                              ; preds = %53
  %107 = load i32, ptr @N, align 4
  %108 = icmp sgt i32 %107, 30
  %109 = select i1 %108, i32 1471483486, i32 583567349
  store i32 %109, ptr %3, align 4
  %110 = xor i32 %2, 1798485389
  %111 = and i32 %2, %110
  %112 = or i32 %2, %110
  %113 = xor i32 %2, %110
  %114 = sub i32 %112, %113
  %115 = sub i32 %114, %111
  %116 = mul i32 %115, 125
  %117 = xor i32 %2, 514721329
  %118 = and i32 %2, %117
  %119 = or i32 %2, %117
  %120 = xor i32 %2, %117
  %121 = sub i32 %119, %120
  %122 = sub i32 %121, %118
  %123 = mul i32 %122, 235
  %124 = icmp eq i32 %116, %123
  br i1 %124, label %1787, label %1932

125:                                              ; preds = %53
  %126 = call i32 (ptr, ...) @printf(ptr noundef @.str.10)
  store i32 0, ptr %4, align 4
  store i32 462455911, ptr %3, align 4
  %127 = xor i32 %2, -745337415
  %128 = and i32 %2, %127
  %129 = or i32 %2, %127
  %130 = xor i32 %2, %127
  %131 = sub i32 %129, %130
  %132 = sub i32 %131, %128
  %133 = mul i32 %132, 172
  %134 = icmp eq i32 %133, 0
  br i1 %134, label %1787, label %1938

135:                                              ; preds = %53
  call void @allocateGrid()
  %136 = getelementptr inbounds [8 x %struct.Point], ptr %7, i64 0, i64 0
  call void @generateDungeon(ptr noundef %5, ptr noundef %6, ptr noundef %136, ptr noundef %8)
  %137 = load i32, ptr %8, align 4
  %138 = load i32, ptr %3, align 4
  %139 = xor i32 %138, 583567351
  %140 = xor i32 %137, %139
  %141 = load i32, ptr %3, align 4
  %142 = xor i32 %141, 583567351
  %143 = and i32 %137, %142
  %144 = add i32 %143, %143
  %145 = add i32 %140, %144
  store i32 %145, ptr %9, align 4
  %146 = load i32, ptr %9, align 4
  %147 = sext i32 %146 to i64
  %148 = mul i64 8, %147
  %149 = call noalias ptr @malloc(i64 noundef %148) #6
  store ptr %149, ptr %10, align 8
  %150 = load ptr, ptr %10, align 8
  %151 = getelementptr inbounds %struct.Point, ptr %150, i64 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %151, ptr align 4 %5, i64 8, i1 false)
  store i32 0, ptr %11, align 4
  store i32 2074461893, ptr %3, align 4
  %152 = xor i32 %2, -2134983639
  %153 = and i32 %2, %152
  %154 = or i32 %2, %152
  %155 = xor i32 %2, %152
  %156 = add i32 %153, %154
  %157 = sub i32 %156, %2
  %158 = sub i32 %157, %152
  %159 = mul i32 %158, 63
  %160 = icmp ugt i32 %159, 0
  br i1 %160, label %1943, label %1787

161:                                              ; preds = %53
  %162 = load i32, ptr %11, align 4
  %163 = load i32, ptr %8, align 4
  %164 = icmp slt i32 %162, %163
  %165 = select i1 %164, i32 154677974, i32 1305152357
  store i32 %165, ptr %3, align 4
  %166 = xor i32 %2, 1648727297
  %167 = and i32 %2, %166
  %168 = or i32 %2, %166
  %169 = xor i32 %2, %166
  %170 = add i32 %167, %168
  %171 = sub i32 %170, %2
  %172 = sub i32 %171, %166
  %173 = mul i32 %172, 27
  %174 = icmp ugt i32 %173, 0
  br i1 %174, label %1950, label %1787

175:                                              ; preds = %53
  %176 = load ptr, ptr %10, align 8
  %177 = load i32, ptr %11, align 4
  %178 = load i32, ptr %3, align 4
  %179 = xor i32 %178, 154677975
  %180 = or i32 %177, %179
  %181 = load i32, ptr %3, align 4
  %182 = xor i32 %181, 154677975
  %183 = and i32 %177, %182
  %184 = add i32 %180, %183
  %185 = sext i32 %184 to i64
  %186 = getelementptr inbounds %struct.Point, ptr %176, i64 %185
  %187 = load i32, ptr %11, align 4
  %188 = sext i32 %187 to i64
  %189 = getelementptr inbounds [8 x %struct.Point], ptr %7, i64 0, i64 %188
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %186, ptr align 8 %189, i64 8, i1 false)
  %190 = load i32, ptr %11, align 4
  %191 = load i32, ptr %3, align 4
  %192 = xor i32 %191, 154677975
  %193 = or i32 %190, %192
  %194 = load i32, ptr %3, align 4
  %195 = xor i32 %194, 154677975
  %196 = and i32 %190, %195
  %197 = add i32 %193, %196
  store i32 %197, ptr %11, align 4
  store i32 2074461893, ptr %3, align 4
  %198 = xor i32 %2, 619050691
  %199 = and i32 %2, %198
  %200 = or i32 %2, %198
  %201 = xor i32 %2, %198
  %202 = add i32 %2, %198
  %203 = sub i32 %202, %201
  %204 = mul i32 %199, 2
  %205 = sub i32 %203, %204
  %206 = mul i32 %205, 112
  %207 = icmp sle i32 %206, 0
  br i1 %207, label %1787, label %1957

208:                                              ; preds = %53
  %209 = load ptr, ptr %10, align 8
  %210 = load i32, ptr %8, align 4
  %211 = load i32, ptr %3, align 4
  %212 = xor i32 %211, 1305152356
  %213 = xor i32 %210, %212
  %214 = load i32, ptr %3, align 4
  %215 = xor i32 %214, 1305152356
  %216 = and i32 %210, %215
  %217 = add i32 %216, %216
  %218 = add i32 %213, %217
  %219 = sext i32 %218 to i64
  %220 = getelementptr inbounds %struct.Point, ptr %209, i64 %219
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %220, ptr align 4 %6, i64 8, i1 false)
  %221 = load i32, ptr @N, align 4
  %222 = load i32, ptr @N, align 4
  %223 = mul nsw i32 %221, %222
  store i32 %223, ptr %12, align 4
  %224 = load i32, ptr %9, align 4
  %225 = sext i32 %224 to i64
  %226 = mul i64 8, %225
  %227 = call noalias ptr @malloc(i64 noundef %226) #6
  store ptr %227, ptr %13, align 8
  %228 = load i32, ptr %9, align 4
  %229 = sext i32 %228 to i64
  %230 = mul i64 8, %229
  %231 = call noalias ptr @malloc(i64 noundef %230) #6
  store ptr %231, ptr %14, align 8
  store i32 0, ptr %15, align 4
  store i32 679842213, ptr %3, align 4
  %232 = xor i32 %2, 1837288217
  %233 = and i32 %2, %232
  %234 = or i32 %2, %232
  %235 = xor i32 %2, %232
  %236 = add i32 %233, %234
  %237 = sub i32 %236, %2
  %238 = sub i32 %237, %232
  %239 = mul i32 %238, 99
  %240 = icmp sgt i32 %239, 0
  br i1 %240, label %1963, label %1787

241:                                              ; preds = %53
  %242 = load i32, ptr %15, align 4
  %243 = load i32, ptr %9, align 4
  %244 = icmp slt i32 %242, %243
  %245 = select i1 %244, i32 122853180, i32 332773425
  store i32 %245, ptr %3, align 4
  %246 = xor i32 %2, 917374555
  %247 = and i32 %2, %246
  %248 = or i32 %2, %246
  %249 = xor i32 %2, %246
  %250 = sub i32 %248, %249
  %251 = sub i32 %250, %247
  %252 = mul i32 %251, 54
  %253 = icmp eq i32 %252, 0
  br i1 %253, label %1787, label %1971

254:                                              ; preds = %53
  %255 = load i32, ptr %12, align 4
  %256 = sext i32 %255 to i64
  %257 = mul i64 4, %256
  %258 = call noalias ptr @malloc(i64 noundef %257) #6
  %259 = load ptr, ptr %13, align 8
  %260 = load i32, ptr %15, align 4
  %261 = sext i32 %260 to i64
  %262 = getelementptr inbounds ptr, ptr %259, i64 %261
  store ptr %258, ptr %262, align 8
  %263 = load i32, ptr %12, align 4
  %264 = sext i32 %263 to i64
  %265 = mul i64 4, %264
  %266 = call noalias ptr @malloc(i64 noundef %265) #6
  %267 = load ptr, ptr %14, align 8
  %268 = load i32, ptr %15, align 4
  %269 = sext i32 %268 to i64
  %270 = getelementptr inbounds ptr, ptr %267, i64 %269
  store ptr %266, ptr %270, align 8
  %271 = load ptr, ptr %10, align 8
  %272 = load i32, ptr %15, align 4
  %273 = sext i32 %272 to i64
  %274 = getelementptr inbounds %struct.Point, ptr %271, i64 %273
  %275 = load ptr, ptr %13, align 8
  %276 = load i32, ptr %15, align 4
  %277 = sext i32 %276 to i64
  %278 = getelementptr inbounds ptr, ptr %275, i64 %277
  %279 = load ptr, ptr %278, align 8
  %280 = load ptr, ptr %14, align 8
  %281 = load i32, ptr %15, align 4
  %282 = sext i32 %281 to i64
  %283 = getelementptr inbounds ptr, ptr %280, i64 %282
  %284 = load ptr, ptr %283, align 8
  %285 = load i64, ptr %274, align 4
  call void @dijkstra(i64 %285, ptr noundef %279, ptr noundef %284)
  %286 = load i32, ptr %15, align 4
  %287 = load i32, ptr %3, align 4
  %288 = xor i32 %287, 122853181
  %289 = xor i32 %286, %288
  %290 = load i32, ptr %3, align 4
  %291 = xor i32 %290, 122853181
  %292 = and i32 %286, %291
  %293 = add i32 %292, %292
  %294 = add i32 %289, %293
  store i32 %294, ptr %15, align 4
  store i32 679842213, ptr %3, align 4
  %295 = xor i32 %2, 1086742707
  %296 = and i32 %2, %295
  %297 = or i32 %2, %295
  %298 = xor i32 %2, %295
  %299 = mul i32 %297, 2
  %300 = sub i32 %299, %298
  %301 = sub i32 %300, %2
  %302 = sub i32 %301, %295
  %303 = mul i32 %302, 141
  %304 = icmp uge i32 %303, 0
  br i1 %304, label %1787, label %1978

305:                                              ; preds = %53
  %306 = load i32, ptr %9, align 4
  %307 = sext i32 %306 to i64
  %308 = mul i64 8, %307
  %309 = call noalias ptr @malloc(i64 noundef %308) #6
  store ptr %309, ptr %16, align 8
  store i32 0, ptr %17, align 4
  store i32 725669707, ptr %3, align 4
  %310 = xor i32 %2, 981886923
  %311 = and i32 %2, %310
  %312 = or i32 %2, %310
  %313 = xor i32 %2, %310
  %314 = add i32 %311, %312
  %315 = sub i32 %314, %2
  %316 = sub i32 %315, %310
  %317 = mul i32 %316, 200
  %318 = icmp uge i32 %317, 0
  br i1 %318, label %1787, label %1986

319:                                              ; preds = %53
  %320 = load i32, ptr %17, align 4
  %321 = load i32, ptr %9, align 4
  %322 = icmp slt i32 %320, %321
  %323 = select i1 %322, i32 -568396434, i32 -696998661
  store i32 %323, ptr %3, align 4
  %324 = xor i32 %2, 1477120163
  %325 = and i32 %2, %324
  %326 = or i32 %2, %324
  %327 = xor i32 %2, %324
  %328 = add i32 %2, %324
  %329 = sub i32 %328, %327
  %330 = mul i32 %325, 2
  %331 = sub i32 %329, %330
  %332 = mul i32 %331, 252
  %333 = icmp slt i32 %332, 1
  br i1 %333, label %1787, label %1991

334:                                              ; preds = %53
  %335 = load i32, ptr %9, align 4
  %336 = sext i32 %335 to i64
  %337 = mul i64 4, %336
  %338 = call noalias ptr @malloc(i64 noundef %337) #6
  %339 = load ptr, ptr %16, align 8
  %340 = load i32, ptr %17, align 4
  %341 = sext i32 %340 to i64
  %342 = getelementptr inbounds ptr, ptr %339, i64 %341
  store ptr %338, ptr %342, align 8
  store i32 0, ptr %18, align 4
  store i32 849897784, ptr %3, align 4
  %343 = xor i32 %2, -1639185223
  %344 = and i32 %2, %343
  %345 = or i32 %2, %343
  %346 = xor i32 %2, %343
  %347 = add i32 %2, %343
  %348 = sub i32 %347, %346
  %349 = mul i32 %344, 2
  %350 = sub i32 %348, %349
  %351 = mul i32 %350, 225
  %352 = icmp slt i32 %351, 1
  br i1 %352, label %1787, label %1997

353:                                              ; preds = %53
  %354 = load i32, ptr %18, align 4
  %355 = load i32, ptr %9, align 4
  %356 = icmp slt i32 %354, %355
  %357 = select i1 %356, i32 -1412164629, i32 1606044575
  store i32 %357, ptr %3, align 4
  %358 = xor i32 %2, 476337261
  %359 = and i32 %2, %358
  %360 = or i32 %2, %358
  %361 = xor i32 %2, %358
  %362 = add i32 %359, %360
  %363 = sub i32 %362, %2
  %364 = sub i32 %363, %358
  %365 = mul i32 %364, 159
  %366 = icmp eq i32 %365, 0
  br i1 %366, label %1787, label %2005

367:                                              ; preds = %53
  %368 = load ptr, ptr %13, align 8
  %369 = load i32, ptr %17, align 4
  %370 = sext i32 %369 to i64
  %371 = getelementptr inbounds ptr, ptr %368, i64 %370
  %372 = load ptr, ptr %371, align 8
  %373 = load ptr, ptr %10, align 8
  %374 = load i32, ptr %18, align 4
  %375 = sext i32 %374 to i64
  %376 = getelementptr inbounds %struct.Point, ptr %373, i64 %375
  %377 = getelementptr inbounds nuw %struct.Point, ptr %376, i32 0, i32 0
  %378 = load i32, ptr %377, align 4
  %379 = load ptr, ptr %10, align 8
  %380 = load i32, ptr %18, align 4
  %381 = sext i32 %380 to i64
  %382 = getelementptr inbounds %struct.Point, ptr %379, i64 %381
  %383 = getelementptr inbounds nuw %struct.Point, ptr %382, i32 0, i32 1
  %384 = load i32, ptr %383, align 4
  %385 = call i32 @idOf(i32 noundef %378, i32 noundef %384)
  %386 = sext i32 %385 to i64
  %387 = getelementptr inbounds i32, ptr %372, i64 %386
  %388 = load i32, ptr %387, align 4
  %389 = load ptr, ptr %16, align 8
  %390 = load i32, ptr %17, align 4
  %391 = sext i32 %390 to i64
  %392 = getelementptr inbounds ptr, ptr %389, i64 %391
  %393 = load ptr, ptr %392, align 8
  %394 = load i32, ptr %18, align 4
  %395 = sext i32 %394 to i64
  %396 = getelementptr inbounds i32, ptr %393, i64 %395
  store i32 %388, ptr %396, align 4
  %397 = load i32, ptr %18, align 4
  %398 = load i32, ptr %3, align 4
  %399 = xor i32 %398, -1412164630
  %400 = sub i32 %397, %399
  %401 = load i32, ptr %3, align 4
  %402 = xor i32 %401, -1412164631
  %403 = mul i32 %397, %402
  %404 = load i32, ptr %3, align 4
  %405 = xor i32 %404, -1412164630
  %406 = mul i32 %405, %400
  %407 = sub i32 %403, %406
  store i32 %407, ptr %18, align 4
  store i32 849897784, ptr %3, align 4
  %408 = xor i32 %2, -1081511183
  %409 = and i32 %2, %408
  %410 = or i32 %2, %408
  %411 = xor i32 %2, %408
  %412 = sub i32 %410, %411
  %413 = sub i32 %412, %409
  %414 = mul i32 %413, 218
  %415 = icmp ugt i32 %414, 0
  br i1 %415, label %2013, label %1787

416:                                              ; preds = %53
  %417 = load i32, ptr %17, align 4
  %418 = load i32, ptr %3, align 4
  %419 = xor i32 %418, 1606044574
  %420 = or i32 %417, %419
  %421 = load i32, ptr %3, align 4
  %422 = xor i32 %421, 1606044574
  %423 = and i32 %417, %422
  %424 = add i32 %420, %423
  store i32 %424, ptr %17, align 4
  store i32 725669707, ptr %3, align 4
  %425 = xor i32 %2, -1294557343
  %426 = and i32 %2, %425
  %427 = or i32 %2, %425
  %428 = xor i32 %2, %425
  %429 = mul i32 %427, 2
  %430 = sub i32 %429, %428
  %431 = sub i32 %430, %2
  %432 = sub i32 %431, %425
  %433 = mul i32 %432, 156
  %434 = icmp slt i32 %433, 1
  br i1 %434, label %1787, label %2016

435:                                              ; preds = %53
  %436 = load i32, ptr %8, align 4
  %437 = load i32, ptr %3, align 4
  %438 = xor i32 %437, -696998662
  %439 = shl i32 %438, %436
  %440 = load i32, ptr %3, align 4
  %441 = xor i32 %440, -696998662
  %442 = mul i32 %441, %439
  store i32 %442, ptr %19, align 4
  %443 = load i32, ptr %19, align 4
  %444 = sext i32 %443 to i64
  %445 = mul i64 4, %444
  %446 = load i32, ptr %8, align 4
  %447 = sext i32 %446 to i64
  %448 = mul i64 %445, %447
  %449 = call noalias ptr @malloc(i64 noundef %448) #6
  store ptr %449, ptr %20, align 8
  %450 = load i32, ptr %19, align 4
  %451 = sext i32 %450 to i64
  %452 = mul i64 4, %451
  %453 = load i32, ptr %8, align 4
  %454 = sext i32 %453 to i64
  %455 = mul i64 %452, %454
  %456 = call noalias ptr @malloc(i64 noundef %455) #6
  store ptr %456, ptr %21, align 8
  store i32 0, ptr %22, align 4
  store i32 1369731015, ptr %3, align 4
  %457 = xor i32 %2, -1341594005
  %458 = and i32 %2, %457
  %459 = or i32 %2, %457
  %460 = xor i32 %2, %457
  %461 = add i32 %458, %459
  %462 = sub i32 %461, %2
  %463 = sub i32 %462, %457
  %464 = mul i32 %463, 217
  %465 = icmp eq i32 %464, 0
  br i1 %465, label %1787, label %2022

466:                                              ; preds = %53
  %467 = load i32, ptr %22, align 4
  %468 = load i32, ptr %19, align 4
  %469 = icmp slt i32 %467, %468
  %470 = select i1 %469, i32 -2137757080, i32 -723118804
  store i32 %470, ptr %3, align 4
  %471 = xor i32 %2, -704672995
  %472 = and i32 %2, %471
  %473 = or i32 %2, %471
  %474 = xor i32 %2, %471
  %475 = add i32 %472, %473
  %476 = sub i32 %475, %2
  %477 = sub i32 %476, %471
  %478 = mul i32 %477, 177
  %479 = icmp sle i32 %478, 0
  br i1 %479, label %1787, label %2025

480:                                              ; preds = %53
  store i32 0, ptr %23, align 4
  store i32 -950972056, ptr %3, align 4
  %481 = xor i32 %2, -825608211
  %482 = and i32 %2, %481
  %483 = or i32 %2, %481
  %484 = xor i32 %2, %481
  %485 = add i32 %482, %483
  %486 = sub i32 %485, %2
  %487 = sub i32 %486, %481
  %488 = mul i32 %487, 13
  %489 = xor i32 %2, -131252483
  %490 = and i32 %2, %489
  %491 = or i32 %2, %489
  %492 = xor i32 %2, %489
  %493 = mul i32 %491, 2
  %494 = sub i32 %493, %492
  %495 = sub i32 %494, %2
  %496 = sub i32 %495, %489
  %497 = mul i32 %496, 114
  %498 = icmp ne i32 %488, %497
  br i1 %498, label %2033, label %1787

499:                                              ; preds = %53
  %500 = load i32, ptr %23, align 4
  %501 = load i32, ptr %8, align 4
  %502 = icmp slt i32 %500, %501
  %503 = select i1 %502, i32 2127047755, i32 1426513484
  store i32 %503, ptr %3, align 4
  %504 = xor i32 %2, -1714991559
  %505 = and i32 %2, %504
  %506 = or i32 %2, %504
  %507 = xor i32 %2, %504
  %508 = sub i32 %506, %507
  %509 = sub i32 %508, %505
  %510 = mul i32 %509, 61
  %511 = icmp sle i32 %510, 0
  br i1 %511, label %1787, label %2037

512:                                              ; preds = %53
  %513 = load ptr, ptr %20, align 8
  %514 = load i32, ptr %22, align 4
  %515 = load i32, ptr %8, align 4
  %516 = mul nsw i32 %514, %515
  %517 = load i32, ptr %23, align 4
  %518 = or i32 %516, %517
  %519 = and i32 %516, %517
  %520 = add i32 %518, %519
  %521 = sext i32 %520 to i64
  %522 = getelementptr inbounds i32, ptr %513, i64 %521
  store i32 1000000000, ptr %522, align 4
  %523 = load ptr, ptr %21, align 8
  %524 = load i32, ptr %22, align 4
  %525 = load i32, ptr %8, align 4
  %526 = mul nsw i32 %524, %525
  %527 = load i32, ptr %23, align 4
  %528 = xor i32 %526, %527
  %529 = and i32 %526, %527
  %530 = add i32 %529, %529
  %531 = add i32 %528, %530
  %532 = sext i32 %531 to i64
  %533 = getelementptr inbounds i32, ptr %523, i64 %532
  store i32 -1, ptr %533, align 4
  %534 = load i32, ptr %23, align 4
  %535 = load i32, ptr %3, align 4
  %536 = xor i32 %535, 2127047754
  %537 = or i32 %534, %536
  %538 = load i32, ptr %3, align 4
  %539 = xor i32 %538, 2127047754
  %540 = and i32 %534, %539
  %541 = add i32 %537, %540
  store i32 %541, ptr %23, align 4
  store i32 -950972056, ptr %3, align 4
  %542 = xor i32 %2, -1233699137
  %543 = and i32 %2, %542
  %544 = or i32 %2, %542
  %545 = xor i32 %2, %542
  %546 = add i32 %2, %542
  %547 = sub i32 %546, %545
  %548 = mul i32 %543, 2
  %549 = sub i32 %547, %548
  %550 = mul i32 %549, 165
  %551 = xor i32 %2, -644669425
  %552 = and i32 %2, %551
  %553 = or i32 %2, %551
  %554 = xor i32 %2, %551
  %555 = add i32 %2, %551
  %556 = sub i32 %555, %554
  %557 = mul i32 %552, 2
  %558 = sub i32 %556, %557
  %559 = mul i32 %558, 39
  %560 = icmp ne i32 %550, %559
  br i1 %560, label %2039, label %1787

561:                                              ; preds = %53
  %562 = load i32, ptr %22, align 4
  %563 = load i32, ptr %3, align 4
  %564 = xor i32 %563, 1426513485
  %565 = sub i32 %562, %564
  %566 = load i32, ptr %3, align 4
  %567 = xor i32 %566, 1426513486
  %568 = mul i32 %562, %567
  %569 = load i32, ptr %3, align 4
  %570 = xor i32 %569, 1426513485
  %571 = mul i32 %570, %565
  %572 = sub i32 %568, %571
  store i32 %572, ptr %22, align 4
  store i32 1369731015, ptr %3, align 4
  %573 = xor i32 %2, 1698937577
  %574 = and i32 %2, %573
  %575 = or i32 %2, %573
  %576 = xor i32 %2, %573
  %577 = sub i32 %575, %576
  %578 = sub i32 %577, %574
  %579 = mul i32 %578, 92
  %580 = icmp uge i32 %579, 0
  br i1 %580, label %1787, label %2047

581:                                              ; preds = %53
  store i32 0, ptr %24, align 4
  store i32 357549240, ptr %3, align 4
  %582 = xor i32 %2, -1113176227
  %583 = and i32 %2, %582
  %584 = or i32 %2, %582
  %585 = xor i32 %2, %582
  %586 = add i32 %2, %582
  %587 = sub i32 %586, %585
  %588 = mul i32 %583, 2
  %589 = sub i32 %587, %588
  %590 = mul i32 %589, 33
  %591 = xor i32 %2, 1842032417
  %592 = and i32 %2, %591
  %593 = or i32 %2, %591
  %594 = xor i32 %2, %591
  %595 = mul i32 %593, 2
  %596 = sub i32 %595, %594
  %597 = sub i32 %596, %2
  %598 = sub i32 %597, %591
  %599 = mul i32 %598, 182
  %600 = icmp ne i32 %590, %599
  br i1 %600, label %2054, label %1787

601:                                              ; preds = %53
  %602 = load i32, ptr %24, align 4
  %603 = load i32, ptr %8, align 4
  %604 = icmp slt i32 %602, %603
  %605 = select i1 %604, i32 -733204176, i32 -594271743
  store i32 %605, ptr %3, align 4
  %606 = xor i32 %2, 1848744019
  %607 = and i32 %2, %606
  %608 = or i32 %2, %606
  %609 = xor i32 %2, %606
  %610 = add i32 %2, %606
  %611 = sub i32 %610, %609
  %612 = mul i32 %607, 2
  %613 = sub i32 %611, %612
  %614 = mul i32 %613, 116
  %615 = xor i32 %2, -766166893
  %616 = and i32 %2, %615
  %617 = or i32 %2, %615
  %618 = xor i32 %2, %615
  %619 = mul i32 %617, 2
  %620 = sub i32 %619, %618
  %621 = sub i32 %620, %2
  %622 = sub i32 %621, %615
  %623 = mul i32 %622, 121
  %624 = icmp ne i32 %614, %623
  br i1 %624, label %2056, label %1787

625:                                              ; preds = %53
  %626 = load ptr, ptr %16, align 8
  %627 = getelementptr inbounds ptr, ptr %626, i64 0
  %628 = load ptr, ptr %627, align 8
  %629 = load i32, ptr %24, align 4
  %630 = load i32, ptr %3, align 4
  %631 = xor i32 %630, -733204175
  %632 = xor i32 %629, %631
  %633 = load i32, ptr %3, align 4
  %634 = xor i32 %633, -733204175
  %635 = and i32 %629, %634
  %636 = add i32 %635, %635
  %637 = add i32 %632, %636
  %638 = sext i32 %637 to i64
  %639 = getelementptr inbounds i32, ptr %628, i64 %638
  %640 = load i32, ptr %639, align 4
  store i32 %640, ptr %25, align 4
  %641 = load i32, ptr %25, align 4
  %642 = icmp slt i32 %641, 1000000000
  %643 = select i1 %642, i32 1475708118, i32 1000917535
  store i32 %643, ptr %3, align 4
  %644 = xor i32 %2, 675612529
  %645 = and i32 %2, %644
  %646 = or i32 %2, %644
  %647 = xor i32 %2, %644
  %648 = add i32 %645, %646
  %649 = sub i32 %648, %2
  %650 = sub i32 %649, %644
  %651 = mul i32 %650, 107
  %652 = xor i32 %2, 1531692681
  %653 = and i32 %2, %652
  %654 = or i32 %2, %652
  %655 = xor i32 %2, %652
  %656 = add i32 %653, %654
  %657 = sub i32 %656, %2
  %658 = sub i32 %657, %652
  %659 = mul i32 %658, 192
  %660 = icmp ne i32 %651, %659
  br i1 %660, label %2064, label %1787

661:                                              ; preds = %53
  %662 = load i32, ptr %25, align 4
  %663 = load ptr, ptr %20, align 8
  %664 = load i32, ptr %24, align 4
  %665 = load i32, ptr %3, align 4
  %666 = xor i32 %665, 1475708119
  %667 = shl i32 %666, %664
  %668 = load i32, ptr %3, align 4
  %669 = xor i32 %668, 1475708119
  %670 = mul i32 %669, %667
  %671 = load i32, ptr %8, align 4
  %672 = mul nsw i32 %670, %671
  %673 = load i32, ptr %24, align 4
  %674 = xor i32 %672, %673
  %675 = and i32 %672, %673
  %676 = add i32 %675, %675
  %677 = add i32 %674, %676
  %678 = sext i32 %677 to i64
  %679 = getelementptr inbounds i32, ptr %663, i64 %678
  store i32 %662, ptr %679, align 4
  store i32 1000917535, ptr %3, align 4
  %680 = xor i32 %2, 1697117227
  %681 = and i32 %2, %680
  %682 = or i32 %2, %680
  %683 = xor i32 %2, %680
  %684 = mul i32 %682, 2
  %685 = sub i32 %684, %683
  %686 = sub i32 %685, %2
  %687 = sub i32 %686, %680
  %688 = mul i32 %687, 134
  %689 = icmp uge i32 %688, 0
  br i1 %689, label %1787, label %2072

690:                                              ; preds = %53
  %691 = load i32, ptr %24, align 4
  %692 = load i32, ptr %3, align 4
  %693 = xor i32 %692, 1000917534
  %694 = or i32 %691, %693
  %695 = load i32, ptr %3, align 4
  %696 = xor i32 %695, 1000917534
  %697 = and i32 %691, %696
  %698 = add i32 %694, %697
  store i32 %698, ptr %24, align 4
  store i32 357549240, ptr %3, align 4
  %699 = xor i32 %2, 1944496461
  %700 = and i32 %2, %699
  %701 = or i32 %2, %699
  %702 = xor i32 %2, %699
  %703 = mul i32 %701, 2
  %704 = sub i32 %703, %702
  %705 = sub i32 %704, %2
  %706 = sub i32 %705, %699
  %707 = mul i32 %706, 2
  %708 = icmp sgt i32 %707, 0
  br i1 %708, label %2074, label %1787

709:                                              ; preds = %53
  store i32 0, ptr %26, align 4
  store i32 557116852, ptr %3, align 4
  %710 = xor i32 %2, -1638303983
  %711 = and i32 %2, %710
  %712 = or i32 %2, %710
  %713 = xor i32 %2, %710
  %714 = add i32 %2, %710
  %715 = sub i32 %714, %713
  %716 = mul i32 %711, 2
  %717 = sub i32 %715, %716
  %718 = mul i32 %717, 139
  %719 = icmp ugt i32 %718, 0
  br i1 %719, label %2078, label %1787

720:                                              ; preds = %53
  %721 = load i32, ptr %26, align 4
  %722 = load i32, ptr %19, align 4
  %723 = icmp slt i32 %721, %722
  %724 = select i1 %723, i32 1682893255, i32 590109392
  store i32 %724, ptr %3, align 4
  %725 = xor i32 %2, -794993373
  %726 = and i32 %2, %725
  %727 = or i32 %2, %725
  %728 = xor i32 %2, %725
  %729 = mul i32 %727, 2
  %730 = sub i32 %729, %728
  %731 = sub i32 %730, %2
  %732 = sub i32 %731, %725
  %733 = mul i32 %732, 233
  %734 = icmp slt i32 %733, 0
  br i1 %734, label %2081, label %1787

735:                                              ; preds = %53
  store i32 0, ptr %27, align 4
  store i32 287954290, ptr %3, align 4
  %736 = xor i32 %2, -947722517
  %737 = and i32 %2, %736
  %738 = or i32 %2, %736
  %739 = xor i32 %2, %736
  %740 = sub i32 %738, %739
  %741 = sub i32 %740, %737
  %742 = mul i32 %741, 247
  %743 = icmp slt i32 %742, 0
  br i1 %743, label %2087, label %1787

744:                                              ; preds = %53
  %745 = load i32, ptr %27, align 4
  %746 = load i32, ptr %8, align 4
  %747 = icmp slt i32 %745, %746
  %748 = select i1 %747, i32 287508266, i32 -1077899911
  store i32 %748, ptr %3, align 4
  %749 = xor i32 %2, 746552381
  %750 = and i32 %2, %749
  %751 = or i32 %2, %749
  %752 = xor i32 %2, %749
  %753 = sub i32 %751, %752
  %754 = sub i32 %753, %750
  %755 = mul i32 %754, 253
  %756 = icmp ne i32 %755, 0
  br i1 %756, label %2095, label %1787

757:                                              ; preds = %53
  %758 = load ptr, ptr %20, align 8
  %759 = load i32, ptr %26, align 4
  %760 = load i32, ptr %8, align 4
  %761 = mul nsw i32 %759, %760
  %762 = load i32, ptr %27, align 4
  %763 = xor i32 %761, %762
  %764 = and i32 %761, %762
  %765 = add i32 %764, %764
  %766 = add i32 %763, %765
  %767 = sext i32 %766 to i64
  %768 = getelementptr inbounds i32, ptr %758, i64 %767
  %769 = load i32, ptr %768, align 4
  store i32 %769, ptr %28, align 4
  %770 = load i32, ptr %28, align 4
  %771 = icmp sge i32 %770, 1000000000
  %772 = select i1 %771, i32 510962712, i32 -1908135005
  store i32 %772, ptr %3, align 4
  %773 = xor i32 %2, 634616089
  %774 = and i32 %2, %773
  %775 = or i32 %2, %773
  %776 = xor i32 %2, %773
  %777 = add i32 %774, %775
  %778 = sub i32 %777, %2
  %779 = sub i32 %778, %773
  %780 = mul i32 %779, 163
  %781 = icmp slt i32 %780, 1
  br i1 %781, label %1787, label %2102

782:                                              ; preds = %53
  store i32 2058946650, ptr %3, align 4
  %783 = xor i32 %2, -317979195
  %784 = and i32 %2, %783
  %785 = or i32 %2, %783
  %786 = xor i32 %2, %783
  %787 = mul i32 %785, 2
  %788 = sub i32 %787, %786
  %789 = sub i32 %788, %2
  %790 = sub i32 %789, %783
  %791 = mul i32 %790, 35
  %792 = icmp eq i32 %791, 0
  br i1 %792, label %1787, label %2109

793:                                              ; preds = %53
  store i32 0, ptr %29, align 4
  store i32 -794454379, ptr %3, align 4
  %794 = xor i32 %2, -906174659
  %795 = and i32 %2, %794
  %796 = or i32 %2, %794
  %797 = xor i32 %2, %794
  %798 = add i32 %2, %794
  %799 = sub i32 %798, %797
  %800 = mul i32 %795, 2
  %801 = sub i32 %799, %800
  %802 = mul i32 %801, 145
  %803 = icmp sgt i32 %802, 0
  br i1 %803, label %2115, label %1787

804:                                              ; preds = %53
  %805 = load i32, ptr %29, align 4
  %806 = load i32, ptr %8, align 4
  %807 = icmp slt i32 %805, %806
  %808 = select i1 %807, i32 -337638153, i32 1615589933
  store i32 %808, ptr %3, align 4
  %809 = xor i32 %2, 389978881
  %810 = and i32 %2, %809
  %811 = or i32 %2, %809
  %812 = xor i32 %2, %809
  %813 = add i32 %2, %809
  %814 = sub i32 %813, %812
  %815 = mul i32 %810, 2
  %816 = sub i32 %814, %815
  %817 = mul i32 %816, 20
  %818 = icmp ne i32 %817, 0
  br i1 %818, label %2122, label %1787

819:                                              ; preds = %53
  %820 = load i32, ptr %26, align 4
  %821 = load i32, ptr %29, align 4
  %822 = load i32, ptr %3, align 4
  %823 = xor i32 %822, -337638154
  %824 = shl i32 %823, %821
  %825 = load i32, ptr %3, align 4
  %826 = xor i32 %825, -337638154
  %827 = mul i32 %826, %824
  %828 = add i32 %820, %827
  %829 = or i32 %820, %827
  %830 = sub i32 %828, %829
  %831 = icmp ne i32 %830, 0
  %832 = select i1 %831, i32 725601941, i32 201426740
  store i32 %832, ptr %3, align 4
  %833 = xor i32 %2, -1484313297
  %834 = and i32 %2, %833
  %835 = or i32 %2, %833
  %836 = xor i32 %2, %833
  %837 = sub i32 %835, %836
  %838 = sub i32 %837, %834
  %839 = mul i32 %838, 138
  %840 = icmp slt i32 %839, 1
  br i1 %840, label %1787, label %2128

841:                                              ; preds = %53
  store i32 -1473416853, ptr %3, align 4
  %842 = xor i32 %2, 2135606455
  %843 = and i32 %2, %842
  %844 = or i32 %2, %842
  %845 = xor i32 %2, %842
  %846 = sub i32 %844, %845
  %847 = sub i32 %846, %843
  %848 = mul i32 %847, 255
  %849 = icmp ne i32 %848, 0
  br i1 %849, label %2136, label %1787

850:                                              ; preds = %53
  %851 = load ptr, ptr %16, align 8
  %852 = load i32, ptr %27, align 4
  %853 = load i32, ptr %3, align 4
  %854 = xor i32 %853, 201426741
  %855 = xor i32 %852, %854
  %856 = load i32, ptr %3, align 4
  %857 = xor i32 %856, 201426741
  %858 = and i32 %852, %857
  %859 = add i32 %858, %858
  %860 = add i32 %855, %859
  %861 = sext i32 %860 to i64
  %862 = getelementptr inbounds ptr, ptr %851, i64 %861
  %863 = load ptr, ptr %862, align 8
  %864 = load i32, ptr %29, align 4
  %865 = load i32, ptr %3, align 4
  %866 = xor i32 %865, 201426741
  %867 = sub i32 %864, %866
  %868 = load i32, ptr %3, align 4
  %869 = xor i32 %868, 201426742
  %870 = mul i32 %864, %869
  %871 = load i32, ptr %3, align 4
  %872 = xor i32 %871, 201426741
  %873 = mul i32 %872, %867
  %874 = sub i32 %870, %873
  %875 = sext i32 %874 to i64
  %876 = getelementptr inbounds i32, ptr %863, i64 %875
  %877 = load i32, ptr %876, align 4
  store i32 %877, ptr %30, align 4
  %878 = load i32, ptr %30, align 4
  %879 = icmp sge i32 %878, 1000000000
  %880 = select i1 %879, i32 -1826289128, i32 -600293782
  store i32 %880, ptr %3, align 4
  %881 = xor i32 %2, 973347083
  %882 = and i32 %2, %881
  %883 = or i32 %2, %881
  %884 = xor i32 %2, %881
  %885 = add i32 %882, %883
  %886 = sub i32 %885, %2
  %887 = sub i32 %886, %881
  %888 = mul i32 %887, 74
  %889 = icmp slt i32 %888, 1
  br i1 %889, label %1787, label %2141

890:                                              ; preds = %53
  store i32 -1473416853, ptr %3, align 4
  %891 = xor i32 %2, -1978085731
  %892 = and i32 %2, %891
  %893 = or i32 %2, %891
  %894 = xor i32 %2, %891
  %895 = mul i32 %893, 2
  %896 = sub i32 %895, %894
  %897 = sub i32 %896, %2
  %898 = sub i32 %897, %891
  %899 = mul i32 %898, 49
  %900 = icmp ne i32 %899, 0
  br i1 %900, label %2148, label %1787

901:                                              ; preds = %53
  %902 = load i32, ptr %26, align 4
  %903 = load i32, ptr %29, align 4
  %904 = load i32, ptr %3, align 4
  %905 = xor i32 %904, -600293781
  %906 = shl i32 %905, %903
  %907 = load i32, ptr %3, align 4
  %908 = xor i32 %907, -600293781
  %909 = mul i32 %908, %906
  %910 = add i32 %902, %909
  %911 = and i32 %902, %909
  %912 = sub i32 %910, %911
  store i32 %912, ptr %31, align 4
  %913 = load i32, ptr %28, align 4
  %914 = load i32, ptr %30, align 4
  %915 = or i32 %913, %914
  %916 = and i32 %913, %914
  %917 = add i32 %915, %916
  store i32 %917, ptr %32, align 4
  %918 = load i32, ptr %32, align 4
  %919 = load ptr, ptr %20, align 8
  %920 = load i32, ptr %31, align 4
  %921 = load i32, ptr %8, align 4
  %922 = mul nsw i32 %920, %921
  %923 = load i32, ptr %29, align 4
  %924 = xor i32 %922, %923
  %925 = and i32 %922, %923
  %926 = add i32 %925, %925
  %927 = add i32 %924, %926
  %928 = sext i32 %927 to i64
  %929 = getelementptr inbounds i32, ptr %919, i64 %928
  %930 = load i32, ptr %929, align 4
  %931 = icmp slt i32 %918, %930
  %932 = select i1 %931, i32 516583089, i32 607717710
  store i32 %932, ptr %3, align 4
  %933 = xor i32 %2, -1885997317
  %934 = and i32 %2, %933
  %935 = or i32 %2, %933
  %936 = xor i32 %2, %933
  %937 = add i32 %2, %933
  %938 = sub i32 %937, %936
  %939 = mul i32 %934, 2
  %940 = sub i32 %938, %939
  %941 = mul i32 %940, 180
  %942 = icmp slt i32 %941, 0
  br i1 %942, label %2154, label %1787

943:                                              ; preds = %53
  %944 = load i32, ptr %32, align 4
  %945 = load ptr, ptr %20, align 8
  %946 = load i32, ptr %31, align 4
  %947 = load i32, ptr %8, align 4
  %948 = mul nsw i32 %946, %947
  %949 = load i32, ptr %29, align 4
  %950 = load i32, ptr %3, align 4
  %951 = xor i32 %950, 516583088
  %952 = add i32 %949, %951
  %953 = load i32, ptr %3, align 4
  %954 = xor i32 %953, 516583088
  %955 = sub i32 %948, %954
  %956 = mul i32 %948, %952
  %957 = mul i32 %949, %955
  %958 = sub i32 %956, %957
  %959 = sext i32 %958 to i64
  %960 = getelementptr inbounds i32, ptr %945, i64 %959
  store i32 %944, ptr %960, align 4
  %961 = load i32, ptr %27, align 4
  %962 = load ptr, ptr %21, align 8
  %963 = load i32, ptr %31, align 4
  %964 = load i32, ptr %8, align 4
  %965 = mul nsw i32 %963, %964
  %966 = load i32, ptr %29, align 4
  %967 = or i32 %965, %966
  %968 = and i32 %965, %966
  %969 = add i32 %967, %968
  %970 = sext i32 %969 to i64
  %971 = getelementptr inbounds i32, ptr %962, i64 %970
  store i32 %961, ptr %971, align 4
  store i32 607717710, ptr %3, align 4
  %972 = xor i32 %2, -1056441453
  %973 = and i32 %2, %972
  %974 = or i32 %2, %972
  %975 = xor i32 %2, %972
  %976 = mul i32 %974, 2
  %977 = sub i32 %976, %975
  %978 = sub i32 %977, %2
  %979 = sub i32 %978, %972
  %980 = mul i32 %979, 192
  %981 = icmp ugt i32 %980, 0
  br i1 %981, label %2156, label %1787

982:                                              ; preds = %53
  store i32 -1473416853, ptr %3, align 4
  %983 = xor i32 %2, 1313961403
  %984 = and i32 %2, %983
  %985 = or i32 %2, %983
  %986 = xor i32 %2, %983
  %987 = mul i32 %985, 2
  %988 = sub i32 %987, %986
  %989 = sub i32 %988, %2
  %990 = sub i32 %989, %983
  %991 = mul i32 %990, 180
  %992 = icmp slt i32 %991, 1
  br i1 %992, label %1787, label %2161

993:                                              ; preds = %53
  %994 = load i32, ptr %29, align 4
  %995 = load i32, ptr %3, align 4
  %996 = xor i32 %995, -1473416854
  %997 = or i32 %994, %996
  %998 = load i32, ptr %3, align 4
  %999 = xor i32 %998, -1473416854
  %1000 = and i32 %994, %999
  %1001 = add i32 %997, %1000
  store i32 %1001, ptr %29, align 4
  store i32 -794454379, ptr %3, align 4
  %1002 = xor i32 %2, -1264526493
  %1003 = and i32 %2, %1002
  %1004 = or i32 %2, %1002
  %1005 = xor i32 %2, %1002
  %1006 = sub i32 %1004, %1005
  %1007 = sub i32 %1006, %1003
  %1008 = mul i32 %1007, 213
  %1009 = icmp slt i32 %1008, 1
  br i1 %1009, label %1787, label %2169

1010:                                             ; preds = %53
  store i32 2058946650, ptr %3, align 4
  %1011 = xor i32 %2, -908423649
  %1012 = and i32 %2, %1011
  %1013 = or i32 %2, %1011
  %1014 = xor i32 %2, %1011
  %1015 = mul i32 %1013, 2
  %1016 = sub i32 %1015, %1014
  %1017 = sub i32 %1016, %2
  %1018 = sub i32 %1017, %1011
  %1019 = mul i32 %1018, 248
  %1020 = icmp ugt i32 %1019, 0
  br i1 %1020, label %2172, label %1787

1021:                                             ; preds = %53
  %1022 = load i32, ptr %27, align 4
  %1023 = load i32, ptr %3, align 4
  %1024 = xor i32 %1023, 2058946651
  %1025 = xor i32 %1022, %1024
  %1026 = load i32, ptr %3, align 4
  %1027 = xor i32 %1026, 2058946651
  %1028 = and i32 %1022, %1027
  %1029 = add i32 %1028, %1028
  %1030 = add i32 %1025, %1029
  store i32 %1030, ptr %27, align 4
  store i32 287954290, ptr %3, align 4
  %1031 = xor i32 %2, -916030361
  %1032 = and i32 %2, %1031
  %1033 = or i32 %2, %1031
  %1034 = xor i32 %2, %1031
  %1035 = sub i32 %1033, %1034
  %1036 = sub i32 %1035, %1032
  %1037 = mul i32 %1036, 176
  %1038 = icmp ne i32 %1037, 0
  br i1 %1038, label %2180, label %1787

1039:                                             ; preds = %53
  %1040 = load i32, ptr %26, align 4
  %1041 = load i32, ptr %3, align 4
  %1042 = xor i32 %1041, -1077899912
  %1043 = sub i32 %1040, %1042
  %1044 = load i32, ptr %3, align 4
  %1045 = xor i32 %1044, -1077899909
  %1046 = mul i32 %1040, %1045
  %1047 = load i32, ptr %3, align 4
  %1048 = xor i32 %1047, -1077899912
  %1049 = mul i32 %1048, %1043
  %1050 = sub i32 %1046, %1049
  store i32 %1050, ptr %26, align 4
  store i32 557116852, ptr %3, align 4
  %1051 = xor i32 %2, 660578763
  %1052 = and i32 %2, %1051
  %1053 = or i32 %2, %1051
  %1054 = xor i32 %2, %1051
  %1055 = mul i32 %1053, 2
  %1056 = sub i32 %1055, %1054
  %1057 = sub i32 %1056, %2
  %1058 = sub i32 %1057, %1051
  %1059 = mul i32 %1058, 57
  %1060 = icmp slt i32 %1059, 1
  br i1 %1060, label %1787, label %2186

1061:                                             ; preds = %53
  store i32 1000000000, ptr %33, align 4
  store i32 -1, ptr %34, align 4
  %1062 = load i32, ptr %19, align 4
  %1063 = load i32, ptr %3, align 4
  %1064 = xor i32 %1063, 590109393
  %1065 = xor i32 %1062, %1064
  %1066 = load i32, ptr %3, align 4
  %1067 = xor i32 %1066, -590109393
  %1068 = xor i32 %1062, %1067
  %1069 = load i32, ptr %3, align 4
  %1070 = xor i32 %1069, 590109393
  %1071 = and i32 %1068, %1070
  %1072 = add i32 %1071, %1071
  %1073 = sub i32 %1065, %1072
  store i32 %1073, ptr %35, align 4
  store i32 0, ptr %36, align 4
  store i32 1671536895, ptr %3, align 4
  %1074 = xor i32 %2, 350650275
  %1075 = and i32 %2, %1074
  %1076 = or i32 %2, %1074
  %1077 = xor i32 %2, %1074
  %1078 = add i32 %1075, %1076
  %1079 = sub i32 %1078, %2
  %1080 = sub i32 %1079, %1074
  %1081 = mul i32 %1080, 151
  %1082 = xor i32 %2, 1922066779
  %1083 = and i32 %2, %1082
  %1084 = or i32 %2, %1082
  %1085 = xor i32 %2, %1082
  %1086 = add i32 %1083, %1084
  %1087 = sub i32 %1086, %2
  %1088 = sub i32 %1087, %1082
  %1089 = mul i32 %1088, 44
  %1090 = icmp ne i32 %1081, %1089
  br i1 %1090, label %2194, label %1787

1091:                                             ; preds = %53
  %1092 = load i32, ptr %36, align 4
  %1093 = load i32, ptr %8, align 4
  %1094 = icmp slt i32 %1092, %1093
  %1095 = select i1 %1094, i32 -1330226131, i32 1340353040
  store i32 %1095, ptr %3, align 4
  %1096 = xor i32 %2, 1721550341
  %1097 = and i32 %2, %1096
  %1098 = or i32 %2, %1096
  %1099 = xor i32 %2, %1096
  %1100 = sub i32 %1098, %1099
  %1101 = sub i32 %1100, %1097
  %1102 = mul i32 %1101, 130
  %1103 = icmp ne i32 %1102, 0
  br i1 %1103, label %2201, label %1787

1104:                                             ; preds = %53
  %1105 = load ptr, ptr %20, align 8
  %1106 = load i32, ptr %35, align 4
  %1107 = load i32, ptr %8, align 4
  %1108 = mul nsw i32 %1106, %1107
  %1109 = load i32, ptr %36, align 4
  %1110 = or i32 %1108, %1109
  %1111 = and i32 %1108, %1109
  %1112 = add i32 %1110, %1111
  %1113 = sext i32 %1112 to i64
  %1114 = getelementptr inbounds i32, ptr %1105, i64 %1113
  %1115 = load i32, ptr %1114, align 4
  store i32 %1115, ptr %37, align 4
  %1116 = load ptr, ptr %16, align 8
  %1117 = load i32, ptr %36, align 4
  %1118 = load i32, ptr %3, align 4
  %1119 = xor i32 %1118, -1330226132
  %1120 = sub i32 %1117, %1119
  %1121 = load i32, ptr %3, align 4
  %1122 = xor i32 %1121, -1330226129
  %1123 = mul i32 %1117, %1122
  %1124 = load i32, ptr %3, align 4
  %1125 = xor i32 %1124, -1330226132
  %1126 = mul i32 %1125, %1120
  %1127 = sub i32 %1123, %1126
  %1128 = sext i32 %1127 to i64
  %1129 = getelementptr inbounds ptr, ptr %1116, i64 %1128
  %1130 = load ptr, ptr %1129, align 8
  %1131 = load i32, ptr %8, align 4
  %1132 = load i32, ptr %3, align 4
  %1133 = xor i32 %1132, -1330226132
  %1134 = sub i32 %1131, %1133
  %1135 = load i32, ptr %3, align 4
  %1136 = xor i32 %1135, -1330226129
  %1137 = mul i32 %1131, %1136
  %1138 = load i32, ptr %3, align 4
  %1139 = xor i32 %1138, -1330226132
  %1140 = mul i32 %1139, %1134
  %1141 = sub i32 %1137, %1140
  %1142 = sext i32 %1141 to i64
  %1143 = getelementptr inbounds i32, ptr %1130, i64 %1142
  %1144 = load i32, ptr %1143, align 4
  store i32 %1144, ptr %38, align 4
  %1145 = load i32, ptr %37, align 4
  %1146 = icmp sge i32 %1145, 1000000000
  %1147 = select i1 %1146, i32 728722016, i32 1368921675
  store i32 %1147, ptr %3, align 4
  %1148 = xor i32 %2, 1220195583
  %1149 = and i32 %2, %1148
  %1150 = or i32 %2, %1148
  %1151 = xor i32 %2, %1148
  %1152 = add i32 %1149, %1150
  %1153 = sub i32 %1152, %2
  %1154 = sub i32 %1153, %1148
  %1155 = mul i32 %1154, 223
  %1156 = icmp slt i32 %1155, 0
  br i1 %1156, label %2207, label %1787

1157:                                             ; preds = %53
  %1158 = load i32, ptr %38, align 4
  %1159 = icmp sge i32 %1158, 1000000000
  %1160 = select i1 %1159, i32 728722016, i32 -1717412462
  store i32 %1160, ptr %3, align 4
  %1161 = xor i32 %2, -1573050871
  %1162 = and i32 %2, %1161
  %1163 = or i32 %2, %1161
  %1164 = xor i32 %2, %1161
  %1165 = add i32 %2, %1161
  %1166 = sub i32 %1165, %1164
  %1167 = mul i32 %1162, 2
  %1168 = sub i32 %1166, %1167
  %1169 = mul i32 %1168, 111
  %1170 = icmp eq i32 %1169, 0
  br i1 %1170, label %1787, label %2210

1171:                                             ; preds = %53
  store i32 1976825460, ptr %3, align 4
  %1172 = xor i32 %2, 403729609
  %1173 = and i32 %2, %1172
  %1174 = or i32 %2, %1172
  %1175 = xor i32 %2, %1172
  %1176 = add i32 %1173, %1174
  %1177 = sub i32 %1176, %2
  %1178 = sub i32 %1177, %1172
  %1179 = mul i32 %1178, 235
  %1180 = icmp slt i32 %1179, 0
  br i1 %1180, label %2215, label %1787

1181:                                             ; preds = %53
  %1182 = load i32, ptr %37, align 4
  %1183 = load i32, ptr %38, align 4
  %1184 = or i32 %1182, %1183
  %1185 = and i32 %1182, %1183
  %1186 = add i32 %1184, %1185
  %1187 = load i32, ptr %33, align 4
  %1188 = icmp slt i32 %1186, %1187
  %1189 = select i1 %1188, i32 872520650, i32 -978529411
  store i32 %1189, ptr %3, align 4
  %1190 = xor i32 %2, -1829486357
  %1191 = and i32 %2, %1190
  %1192 = or i32 %2, %1190
  %1193 = xor i32 %2, %1190
  %1194 = mul i32 %1192, 2
  %1195 = sub i32 %1194, %1193
  %1196 = sub i32 %1195, %2
  %1197 = sub i32 %1196, %1190
  %1198 = mul i32 %1197, 249
  %1199 = icmp slt i32 %1198, 1
  br i1 %1199, label %1787, label %2222

1200:                                             ; preds = %53
  %1201 = load i32, ptr %37, align 4
  %1202 = load i32, ptr %38, align 4
  %1203 = xor i32 %1201, %1202
  %1204 = and i32 %1201, %1202
  %1205 = add i32 %1204, %1204
  %1206 = add i32 %1203, %1205
  store i32 %1206, ptr %33, align 4
  %1207 = load i32, ptr %36, align 4
  store i32 %1207, ptr %34, align 4
  store i32 -978529411, ptr %3, align 4
  %1208 = xor i32 %2, -149198105
  %1209 = and i32 %2, %1208
  %1210 = or i32 %2, %1208
  %1211 = xor i32 %2, %1208
  %1212 = mul i32 %1210, 2
  %1213 = sub i32 %1212, %1211
  %1214 = sub i32 %1213, %2
  %1215 = sub i32 %1214, %1208
  %1216 = mul i32 %1215, 103
  %1217 = icmp sgt i32 %1216, 0
  br i1 %1217, label %2224, label %1787

1218:                                             ; preds = %53
  store i32 1976825460, ptr %3, align 4
  %1219 = xor i32 %2, 1777906359
  %1220 = and i32 %2, %1219
  %1221 = or i32 %2, %1219
  %1222 = xor i32 %2, %1219
  %1223 = add i32 %2, %1219
  %1224 = sub i32 %1223, %1222
  %1225 = mul i32 %1220, 2
  %1226 = sub i32 %1224, %1225
  %1227 = mul i32 %1226, 172
  %1228 = xor i32 %2, -1443086371
  %1229 = and i32 %2, %1228
  %1230 = or i32 %2, %1228
  %1231 = xor i32 %2, %1228
  %1232 = mul i32 %1230, 2
  %1233 = sub i32 %1232, %1231
  %1234 = sub i32 %1233, %2
  %1235 = sub i32 %1234, %1228
  %1236 = mul i32 %1235, 229
  %1237 = icmp eq i32 %1227, %1236
  br i1 %1237, label %1787, label %2226

1238:                                             ; preds = %53
  %1239 = load i32, ptr %36, align 4
  %1240 = load i32, ptr %3, align 4
  %1241 = xor i32 %1240, 1976825461
  %1242 = xor i32 %1239, %1241
  %1243 = load i32, ptr %3, align 4
  %1244 = xor i32 %1243, 1976825461
  %1245 = and i32 %1239, %1244
  %1246 = add i32 %1245, %1245
  %1247 = add i32 %1242, %1246
  store i32 %1247, ptr %36, align 4
  store i32 1671536895, ptr %3, align 4
  %1248 = xor i32 %2, 425145671
  %1249 = and i32 %2, %1248
  %1250 = or i32 %2, %1248
  %1251 = xor i32 %2, %1248
  %1252 = mul i32 %1250, 2
  %1253 = sub i32 %1252, %1251
  %1254 = sub i32 %1253, %2
  %1255 = sub i32 %1254, %1248
  %1256 = mul i32 %1255, 190
  %1257 = icmp sgt i32 %1256, 0
  br i1 %1257, label %2234, label %1787

1258:                                             ; preds = %53
  %1259 = call i32 (ptr, ...) @printf(ptr noundef @.str.11)
  %1260 = load i32, ptr @N, align 4
  %1261 = call i32 (ptr, ...) @printf(ptr noundef @.str.12, i32 noundef %1260)
  %1262 = call i32 (ptr, ...) @printf(ptr noundef @.str.13)
  %1263 = getelementptr inbounds [8 x %struct.Point], ptr %7, i64 0, i64 0
  %1264 = load i32, ptr %8, align 4
  call void @printDungeon(ptr noundef %1263, i32 noundef %1264)
  %1265 = load i32, ptr %34, align 4
  %1266 = icmp eq i32 %1265, -1
  %1267 = select i1 %1266, i32 1496723699, i32 -2122754939
  store i32 %1267, ptr %3, align 4
  %1268 = xor i32 %2, 1114035823
  %1269 = and i32 %2, %1268
  %1270 = or i32 %2, %1268
  %1271 = xor i32 %2, %1268
  %1272 = add i32 %1269, %1270
  %1273 = sub i32 %1272, %2
  %1274 = sub i32 %1273, %1268
  %1275 = mul i32 %1274, 124
  %1276 = icmp slt i32 %1275, 1
  br i1 %1276, label %1787, label %2239

1277:                                             ; preds = %53
  %1278 = call i32 (ptr, ...) @printf(ptr noundef @.str.14)
  store i32 -978387670, ptr %3, align 4
  %1279 = xor i32 %2, 1160725443
  %1280 = and i32 %2, %1279
  %1281 = or i32 %2, %1279
  %1282 = xor i32 %2, %1279
  %1283 = add i32 %1280, %1281
  %1284 = sub i32 %1283, %2
  %1285 = sub i32 %1284, %1279
  %1286 = mul i32 %1285, 159
  %1287 = icmp ugt i32 %1286, 0
  br i1 %1287, label %2245, label %1787

1288:                                             ; preds = %53
  %1289 = load i32, ptr %8, align 4
  %1290 = sext i32 %1289 to i64
  %1291 = mul i64 4, %1290
  %1292 = call noalias ptr @malloc(i64 noundef %1291) #6
  store ptr %1292, ptr %39, align 8
  store i32 0, ptr %40, align 4
  %1293 = load i32, ptr %35, align 4
  store i32 %1293, ptr %41, align 4
  %1294 = load i32, ptr %34, align 4
  store i32 %1294, ptr %42, align 4
  store i32 756786263, ptr %3, align 4
  %1295 = xor i32 %2, 1172173105
  %1296 = and i32 %2, %1295
  %1297 = or i32 %2, %1295
  %1298 = xor i32 %2, %1295
  %1299 = mul i32 %1297, 2
  %1300 = sub i32 %1299, %1298
  %1301 = sub i32 %1300, %2
  %1302 = sub i32 %1301, %1295
  %1303 = mul i32 %1302, 208
  %1304 = xor i32 %2, 42731277
  %1305 = and i32 %2, %1304
  %1306 = or i32 %2, %1304
  %1307 = xor i32 %2, %1304
  %1308 = add i32 %1305, %1306
  %1309 = sub i32 %1308, %2
  %1310 = sub i32 %1309, %1304
  %1311 = mul i32 %1310, 86
  %1312 = icmp ne i32 %1303, %1311
  br i1 %1312, label %2251, label %1787

1313:                                             ; preds = %53
  %1314 = load i32, ptr %42, align 4
  %1315 = icmp ne i32 %1314, -1
  %1316 = select i1 %1315, i32 1626411376, i32 -1764137507
  store i32 %1316, ptr %3, align 4
  %1317 = xor i32 %2, -283800315
  %1318 = and i32 %2, %1317
  %1319 = or i32 %2, %1317
  %1320 = xor i32 %2, %1317
  %1321 = add i32 %2, %1317
  %1322 = sub i32 %1321, %1320
  %1323 = mul i32 %1318, 2
  %1324 = sub i32 %1322, %1323
  %1325 = mul i32 %1324, 222
  %1326 = icmp sle i32 %1325, 0
  br i1 %1326, label %1787, label %2257

1327:                                             ; preds = %53
  %1328 = load i32, ptr %42, align 4
  %1329 = load ptr, ptr %39, align 8
  %1330 = load i32, ptr %40, align 4
  %1331 = load i32, ptr %3, align 4
  %1332 = xor i32 %1331, 1626411377
  %1333 = or i32 %1330, %1332
  %1334 = load i32, ptr %3, align 4
  %1335 = xor i32 %1334, 1626411377
  %1336 = and i32 %1330, %1335
  %1337 = add i32 %1333, %1336
  store i32 %1337, ptr %40, align 4
  %1338 = sext i32 %1330 to i64
  %1339 = getelementptr inbounds i32, ptr %1329, i64 %1338
  store i32 %1328, ptr %1339, align 4
  %1340 = load ptr, ptr %21, align 8
  %1341 = load i32, ptr %41, align 4
  %1342 = load i32, ptr %8, align 4
  %1343 = mul nsw i32 %1341, %1342
  %1344 = load i32, ptr %42, align 4
  %1345 = load i32, ptr %3, align 4
  %1346 = xor i32 %1345, 1626411377
  %1347 = add i32 %1344, %1346
  %1348 = load i32, ptr %3, align 4
  %1349 = xor i32 %1348, 1626411377
  %1350 = sub i32 %1343, %1349
  %1351 = mul i32 %1343, %1347
  %1352 = mul i32 %1344, %1350
  %1353 = sub i32 %1351, %1352
  %1354 = sext i32 %1353 to i64
  %1355 = getelementptr inbounds i32, ptr %1340, i64 %1354
  %1356 = load i32, ptr %1355, align 4
  store i32 %1356, ptr %43, align 4
  %1357 = load i32, ptr %42, align 4
  %1358 = load i32, ptr %3, align 4
  %1359 = xor i32 %1358, 1626411377
  %1360 = shl i32 %1359, %1357
  %1361 = load i32, ptr %3, align 4
  %1362 = xor i32 %1361, 1626411377
  %1363 = mul i32 %1362, %1360
  %1364 = load i32, ptr %41, align 4
  %1365 = add i32 %1364, %1363
  %1366 = and i32 %1364, %1363
  %1367 = add i32 %1366, %1366
  %1368 = sub i32 %1365, %1367
  store i32 %1368, ptr %41, align 4
  %1369 = load i32, ptr %43, align 4
  store i32 %1369, ptr %42, align 4
  store i32 756786263, ptr %3, align 4
  %1370 = xor i32 %2, -1319767
  %1371 = and i32 %2, %1370
  %1372 = or i32 %2, %1370
  %1373 = xor i32 %2, %1370
  %1374 = sub i32 %1372, %1373
  %1375 = sub i32 %1374, %1371
  %1376 = mul i32 %1375, 207
  %1377 = icmp slt i32 %1376, 0
  br i1 %1377, label %2263, label %1787

1378:                                             ; preds = %53
  store i32 0, ptr %44, align 4
  store i32 1218204102, ptr %3, align 4
  %1379 = xor i32 %2, 1427029573
  %1380 = and i32 %2, %1379
  %1381 = or i32 %2, %1379
  %1382 = xor i32 %2, %1379
  %1383 = mul i32 %1381, 2
  %1384 = sub i32 %1383, %1382
  %1385 = sub i32 %1384, %2
  %1386 = sub i32 %1385, %1379
  %1387 = mul i32 %1386, 116
  %1388 = icmp slt i32 %1387, 0
  br i1 %1388, label %2271, label %1787

1389:                                             ; preds = %53
  %1390 = load i32, ptr %44, align 4
  %1391 = load i32, ptr %40, align 4
  %1392 = sdiv i32 %1391, 2
  %1393 = icmp slt i32 %1390, %1392
  %1394 = select i1 %1393, i32 -806636259, i32 -1511571322
  store i32 %1394, ptr %3, align 4
  %1395 = xor i32 %2, -775167353
  %1396 = and i32 %2, %1395
  %1397 = or i32 %2, %1395
  %1398 = xor i32 %2, %1395
  %1399 = add i32 %1396, %1397
  %1400 = sub i32 %1399, %2
  %1401 = sub i32 %1400, %1395
  %1402 = mul i32 %1401, 85
  %1403 = icmp uge i32 %1402, 0
  br i1 %1403, label %1787, label %2275

1404:                                             ; preds = %53
  %1405 = load ptr, ptr %39, align 8
  %1406 = load i32, ptr %44, align 4
  %1407 = sext i32 %1406 to i64
  %1408 = getelementptr inbounds i32, ptr %1405, i64 %1407
  %1409 = load i32, ptr %1408, align 4
  store i32 %1409, ptr %45, align 4
  %1410 = load ptr, ptr %39, align 8
  %1411 = load i32, ptr %40, align 4
  %1412 = load i32, ptr %3, align 4
  %1413 = xor i32 %1412, -806636260
  %1414 = xor i32 %1411, %1413
  %1415 = load i32, ptr %3, align 4
  %1416 = xor i32 %1415, 806636258
  %1417 = xor i32 %1411, %1416
  %1418 = load i32, ptr %3, align 4
  %1419 = xor i32 %1418, -806636260
  %1420 = and i32 %1417, %1419
  %1421 = add i32 %1420, %1420
  %1422 = sub i32 %1414, %1421
  %1423 = load i32, ptr %44, align 4
  %1424 = xor i32 %1422, %1423
  %1425 = load i32, ptr %3, align 4
  %1426 = xor i32 %1425, 806636258
  %1427 = xor i32 %1422, %1426
  %1428 = and i32 %1427, %1423
  %1429 = add i32 %1428, %1428
  %1430 = sub i32 %1424, %1429
  %1431 = sext i32 %1430 to i64
  %1432 = getelementptr inbounds i32, ptr %1410, i64 %1431
  %1433 = load i32, ptr %1432, align 4
  %1434 = load ptr, ptr %39, align 8
  %1435 = load i32, ptr %44, align 4
  %1436 = sext i32 %1435 to i64
  %1437 = getelementptr inbounds i32, ptr %1434, i64 %1436
  store i32 %1433, ptr %1437, align 4
  %1438 = load i32, ptr %45, align 4
  %1439 = load ptr, ptr %39, align 8
  %1440 = load i32, ptr %40, align 4
  %1441 = load i32, ptr %3, align 4
  %1442 = xor i32 %1441, -806636260
  %1443 = xor i32 %1440, %1442
  %1444 = load i32, ptr %3, align 4
  %1445 = xor i32 %1444, 806636258
  %1446 = xor i32 %1440, %1445
  %1447 = load i32, ptr %3, align 4
  %1448 = xor i32 %1447, -806636260
  %1449 = and i32 %1446, %1448
  %1450 = add i32 %1449, %1449
  %1451 = sub i32 %1443, %1450
  %1452 = load i32, ptr %44, align 4
  %1453 = load i32, ptr %3, align 4
  %1454 = xor i32 %1453, -806636260
  %1455 = add i32 %1452, %1454
  %1456 = load i32, ptr %3, align 4
  %1457 = xor i32 %1456, -806636260
  %1458 = add i32 %1451, %1457
  %1459 = mul i32 %1451, %1455
  %1460 = mul i32 %1452, %1458
  %1461 = sub i32 %1459, %1460
  %1462 = sext i32 %1461 to i64
  %1463 = getelementptr inbounds i32, ptr %1439, i64 %1462
  store i32 %1438, ptr %1463, align 4
  %1464 = load i32, ptr %44, align 4
  %1465 = load i32, ptr %3, align 4
  %1466 = xor i32 %1465, -806636260
  %1467 = sub i32 %1464, %1466
  %1468 = load i32, ptr %3, align 4
  %1469 = xor i32 %1468, -806636257
  %1470 = mul i32 %1464, %1469
  %1471 = load i32, ptr %3, align 4
  %1472 = xor i32 %1471, -806636260
  %1473 = mul i32 %1472, %1467
  %1474 = sub i32 %1470, %1473
  store i32 %1474, ptr %44, align 4
  store i32 1218204102, ptr %3, align 4
  %1475 = xor i32 %2, -1967588105
  %1476 = and i32 %2, %1475
  %1477 = or i32 %2, %1475
  %1478 = xor i32 %2, %1475
  %1479 = mul i32 %1477, 2
  %1480 = sub i32 %1479, %1478
  %1481 = sub i32 %1480, %2
  %1482 = sub i32 %1481, %1475
  %1483 = mul i32 %1482, 38
  %1484 = icmp ne i32 %1483, 0
  br i1 %1484, label %2281, label %1787

1485:                                             ; preds = %53
  %1486 = load i32, ptr @N, align 4
  %1487 = load i32, ptr @N, align 4
  %1488 = mul nsw i32 %1486, %1487
  %1489 = load i32, ptr %8, align 4
  %1490 = load i32, ptr %3, align 4
  %1491 = xor i32 %1490, -1511571324
  %1492 = or i32 %1489, %1491
  %1493 = load i32, ptr %3, align 4
  %1494 = xor i32 %1493, -1511571324
  %1495 = and i32 %1489, %1494
  %1496 = add i32 %1492, %1495
  %1497 = mul nsw i32 %1488, %1496
  %1498 = sext i32 %1497 to i64
  %1499 = mul i64 8, %1498
  %1500 = call noalias ptr @malloc(i64 noundef %1499) #6
  store ptr %1500, ptr %46, align 8
  store i32 0, ptr %47, align 4
  store i32 0, ptr %48, align 4
  store i32 0, ptr %49, align 4
  store i32 1794859368, ptr %3, align 4
  %1501 = xor i32 %2, 1163137893
  %1502 = and i32 %2, %1501
  %1503 = or i32 %2, %1501
  %1504 = xor i32 %2, %1501
  %1505 = add i32 %2, %1501
  %1506 = sub i32 %1505, %1504
  %1507 = mul i32 %1502, 2
  %1508 = sub i32 %1506, %1507
  %1509 = mul i32 %1508, 225
  %1510 = icmp slt i32 %1509, 0
  br i1 %1510, label %2288, label %1787

1511:                                             ; preds = %53
  %1512 = load i32, ptr %49, align 4
  %1513 = load i32, ptr %40, align 4
  %1514 = icmp slt i32 %1512, %1513
  %1515 = select i1 %1514, i32 1521980331, i32 1696388708
  store i32 %1515, ptr %3, align 4
  %1516 = xor i32 %2, -826653509
  %1517 = and i32 %2, %1516
  %1518 = or i32 %2, %1516
  %1519 = xor i32 %2, %1516
  %1520 = mul i32 %1518, 2
  %1521 = sub i32 %1520, %1519
  %1522 = sub i32 %1521, %2
  %1523 = sub i32 %1522, %1516
  %1524 = mul i32 %1523, 160
  %1525 = icmp ugt i32 %1524, 0
  br i1 %1525, label %2290, label %1787

1526:                                             ; preds = %53
  %1527 = load ptr, ptr %39, align 8
  %1528 = load i32, ptr %49, align 4
  %1529 = sext i32 %1528 to i64
  %1530 = getelementptr inbounds i32, ptr %1527, i64 %1529
  %1531 = load i32, ptr %1530, align 4
  %1532 = load i32, ptr %3, align 4
  %1533 = xor i32 %1532, 1521980330
  %1534 = xor i32 %1531, %1533
  %1535 = load i32, ptr %3, align 4
  %1536 = xor i32 %1535, 1521980330
  %1537 = and i32 %1531, %1536
  %1538 = add i32 %1537, %1537
  %1539 = add i32 %1534, %1538
  store i32 %1539, ptr %50, align 4
  %1540 = load ptr, ptr %10, align 8
  %1541 = load i32, ptr %48, align 4
  %1542 = sext i32 %1541 to i64
  %1543 = getelementptr inbounds %struct.Point, ptr %1540, i64 %1542
  %1544 = load ptr, ptr %10, align 8
  %1545 = load i32, ptr %50, align 4
  %1546 = sext i32 %1545 to i64
  %1547 = getelementptr inbounds %struct.Point, ptr %1544, i64 %1546
  %1548 = load ptr, ptr %14, align 8
  %1549 = load i32, ptr %48, align 4
  %1550 = sext i32 %1549 to i64
  %1551 = getelementptr inbounds ptr, ptr %1548, i64 %1550
  %1552 = load ptr, ptr %1551, align 8
  %1553 = load ptr, ptr %46, align 8
  %1554 = load i64, ptr %1543, align 4
  %1555 = load i64, ptr %1547, align 4
  call void @appendPathSegment(i64 %1554, i64 %1555, ptr noundef %1552, ptr noundef %1553, ptr noundef %47)
  %1556 = load i32, ptr %50, align 4
  store i32 %1556, ptr %48, align 4
  %1557 = load i32, ptr %49, align 4
  %1558 = load i32, ptr %3, align 4
  %1559 = xor i32 %1558, 1521980330
  %1560 = or i32 %1557, %1559
  %1561 = load i32, ptr %3, align 4
  %1562 = xor i32 %1561, 1521980330
  %1563 = and i32 %1557, %1562
  %1564 = add i32 %1560, %1563
  store i32 %1564, ptr %49, align 4
  store i32 1794859368, ptr %3, align 4
  %1565 = xor i32 %2, -1448218581
  %1566 = and i32 %2, %1565
  %1567 = or i32 %2, %1565
  %1568 = xor i32 %2, %1565
  %1569 = sub i32 %1567, %1568
  %1570 = sub i32 %1569, %1566
  %1571 = mul i32 %1570, 132
  %1572 = xor i32 %2, -1481885451
  %1573 = and i32 %2, %1572
  %1574 = or i32 %2, %1572
  %1575 = xor i32 %2, %1572
  %1576 = add i32 %1573, %1574
  %1577 = sub i32 %1576, %2
  %1578 = sub i32 %1577, %1572
  %1579 = mul i32 %1578, 108
  %1580 = icmp ne i32 %1571, %1579
  br i1 %1580, label %2292, label %1787

1581:                                             ; preds = %53
  %1582 = load ptr, ptr %10, align 8
  %1583 = load i32, ptr %48, align 4
  %1584 = sext i32 %1583 to i64
  %1585 = getelementptr inbounds %struct.Point, ptr %1582, i64 %1584
  %1586 = load ptr, ptr %14, align 8
  %1587 = load i32, ptr %48, align 4
  %1588 = sext i32 %1587 to i64
  %1589 = getelementptr inbounds ptr, ptr %1586, i64 %1588
  %1590 = load ptr, ptr %1589, align 8
  %1591 = load ptr, ptr %46, align 8
  %1592 = load i64, ptr %1585, align 4
  %1593 = load i64, ptr %6, align 4
  call void @appendPathSegment(i64 %1592, i64 %1593, ptr noundef %1590, ptr noundef %1591, ptr noundef %47)
  %1594 = load i32, ptr %33, align 4
  %1595 = call i32 (ptr, ...) @printf(ptr noundef @.str.15, i32 noundef %1594)
  %1596 = call i32 (ptr, ...) @printf(ptr noundef @.str.16)
  store i32 0, ptr %51, align 4
  store i32 1332600839, ptr %3, align 4
  %1597 = xor i32 %2, -814035809
  %1598 = and i32 %2, %1597
  %1599 = or i32 %2, %1597
  %1600 = xor i32 %2, %1597
  %1601 = add i32 %1598, %1599
  %1602 = sub i32 %1601, %2
  %1603 = sub i32 %1602, %1597
  %1604 = mul i32 %1603, 139
  %1605 = icmp ugt i32 %1604, 0
  br i1 %1605, label %2300, label %1787

1606:                                             ; preds = %53
  %1607 = load i32, ptr %51, align 4
  %1608 = load i32, ptr %40, align 4
  %1609 = icmp slt i32 %1607, %1608
  %1610 = select i1 %1609, i32 -1084316050, i32 1392630073
  store i32 %1610, ptr %3, align 4
  %1611 = xor i32 %2, 537221141
  %1612 = and i32 %2, %1611
  %1613 = or i32 %2, %1611
  %1614 = xor i32 %2, %1611
  %1615 = sub i32 %1613, %1614
  %1616 = sub i32 %1615, %1612
  %1617 = mul i32 %1616, 129
  %1618 = icmp eq i32 %1617, 0
  br i1 %1618, label %1787, label %2302

1619:                                             ; preds = %53
  %1620 = load i32, ptr %51, align 4
  %1621 = icmp ne i32 %1620, 0
  %1622 = select i1 %1621, i32 1202816888, i32 -360331409
  store i32 %1622, ptr %3, align 4
  %1623 = xor i32 %2, -180939639
  %1624 = and i32 %2, %1623
  %1625 = or i32 %2, %1623
  %1626 = xor i32 %2, %1623
  %1627 = sub i32 %1625, %1626
  %1628 = sub i32 %1627, %1624
  %1629 = mul i32 %1628, 42
  %1630 = icmp uge i32 %1629, 0
  br i1 %1630, label %1787, label %2306

1631:                                             ; preds = %53
  %1632 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  store i32 -360331409, ptr %3, align 4
  %1633 = xor i32 %2, -957259529
  %1634 = and i32 %2, %1633
  %1635 = or i32 %2, %1633
  %1636 = xor i32 %2, %1633
  %1637 = add i32 %1634, %1635
  %1638 = sub i32 %1637, %2
  %1639 = sub i32 %1638, %1633
  %1640 = mul i32 %1639, 144
  %1641 = icmp uge i32 %1640, 0
  br i1 %1641, label %1787, label %2312

1642:                                             ; preds = %53
  %1643 = load ptr, ptr %39, align 8
  %1644 = load i32, ptr %51, align 4
  %1645 = sext i32 %1644 to i64
  %1646 = getelementptr inbounds i32, ptr %1643, i64 %1645
  %1647 = load i32, ptr %1646, align 4
  %1648 = load i32, ptr %3, align 4
  %1649 = xor i32 %1648, -360331410
  %1650 = sub i32 %1647, %1649
  %1651 = load i32, ptr %3, align 4
  %1652 = xor i32 %1651, -360331411
  %1653 = mul i32 %1647, %1652
  %1654 = load i32, ptr %3, align 4
  %1655 = xor i32 %1654, -360331410
  %1656 = mul i32 %1655, %1650
  %1657 = sub i32 %1653, %1656
  %1658 = call i32 (ptr, ...) @printf(ptr noundef @.str.17, i32 noundef %1657)
  %1659 = load i32, ptr %51, align 4
  %1660 = load i32, ptr %3, align 4
  %1661 = xor i32 %1660, -360331410
  %1662 = or i32 %1659, %1661
  %1663 = load i32, ptr %3, align 4
  %1664 = xor i32 %1663, -360331410
  %1665 = and i32 %1659, %1664
  %1666 = add i32 %1662, %1665
  store i32 %1666, ptr %51, align 4
  store i32 1332600839, ptr %3, align 4
  %1667 = xor i32 %2, 1217422347
  %1668 = and i32 %2, %1667
  %1669 = or i32 %2, %1667
  %1670 = xor i32 %2, %1667
  %1671 = sub i32 %1669, %1670
  %1672 = sub i32 %1671, %1668
  %1673 = mul i32 %1672, 52
  %1674 = icmp sgt i32 %1673, 0
  br i1 %1674, label %2318, label %1787

1675:                                             ; preds = %53
  %1676 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  %1677 = load i32, ptr %47, align 4
  %1678 = call i32 (ptr, ...) @printf(ptr noundef @.str.18, i32 noundef %1677)
  %1679 = load ptr, ptr %46, align 8
  %1680 = load i32, ptr %47, align 4
  call void @printRoute(ptr noundef %1679, i32 noundef %1680)
  %1681 = load ptr, ptr %46, align 8
  call void @free(ptr noundef %1681) #8
  %1682 = load ptr, ptr %39, align 8
  call void @free(ptr noundef %1682) #8
  store i32 -978387670, ptr %3, align 4
  %1683 = xor i32 %2, 967932165
  %1684 = and i32 %2, %1683
  %1685 = or i32 %2, %1683
  %1686 = xor i32 %2, %1683
  %1687 = add i32 %1684, %1685
  %1688 = sub i32 %1687, %2
  %1689 = sub i32 %1688, %1683
  %1690 = mul i32 %1689, 216
  %1691 = icmp ne i32 %1690, 0
  br i1 %1691, label %2323, label %1787

1692:                                             ; preds = %53
  store i32 0, ptr %52, align 4
  store i32 1645757361, ptr %3, align 4
  %1693 = xor i32 %2, 1618849625
  %1694 = and i32 %2, %1693
  %1695 = or i32 %2, %1693
  %1696 = xor i32 %2, %1693
  %1697 = add i32 %1694, %1695
  %1698 = sub i32 %1697, %2
  %1699 = sub i32 %1698, %1693
  %1700 = mul i32 %1699, 94
  %1701 = xor i32 %2, -1095431259
  %1702 = and i32 %2, %1701
  %1703 = or i32 %2, %1701
  %1704 = xor i32 %2, %1701
  %1705 = mul i32 %1703, 2
  %1706 = sub i32 %1705, %1704
  %1707 = sub i32 %1706, %2
  %1708 = sub i32 %1707, %1701
  %1709 = mul i32 %1708, 157
  %1710 = icmp ne i32 %1700, %1709
  br i1 %1710, label %2330, label %1787

1711:                                             ; preds = %53
  %1712 = load i32, ptr %52, align 4
  %1713 = load i32, ptr %9, align 4
  %1714 = icmp slt i32 %1712, %1713
  %1715 = select i1 %1714, i32 1906139508, i32 1562280773
  store i32 %1715, ptr %3, align 4
  %1716 = xor i32 %2, -668356657
  %1717 = and i32 %2, %1716
  %1718 = or i32 %2, %1716
  %1719 = xor i32 %2, %1716
  %1720 = sub i32 %1718, %1719
  %1721 = sub i32 %1720, %1717
  %1722 = mul i32 %1721, 123
  %1723 = xor i32 %2, -647641931
  %1724 = and i32 %2, %1723
  %1725 = or i32 %2, %1723
  %1726 = xor i32 %2, %1723
  %1727 = sub i32 %1725, %1726
  %1728 = sub i32 %1727, %1724
  %1729 = mul i32 %1728, 11
  %1730 = icmp eq i32 %1722, %1729
  br i1 %1730, label %1787, label %2337

1731:                                             ; preds = %53
  %1732 = load ptr, ptr %13, align 8
  %1733 = load i32, ptr %52, align 4
  %1734 = sext i32 %1733 to i64
  %1735 = getelementptr inbounds ptr, ptr %1732, i64 %1734
  %1736 = load ptr, ptr %1735, align 8
  call void @free(ptr noundef %1736) #8
  %1737 = load ptr, ptr %14, align 8
  %1738 = load i32, ptr %52, align 4
  %1739 = sext i32 %1738 to i64
  %1740 = getelementptr inbounds ptr, ptr %1737, i64 %1739
  %1741 = load ptr, ptr %1740, align 8
  call void @free(ptr noundef %1741) #8
  %1742 = load ptr, ptr %16, align 8
  %1743 = load i32, ptr %52, align 4
  %1744 = sext i32 %1743 to i64
  %1745 = getelementptr inbounds ptr, ptr %1742, i64 %1744
  %1746 = load ptr, ptr %1745, align 8
  call void @free(ptr noundef %1746) #8
  %1747 = load i32, ptr %52, align 4
  %1748 = load i32, ptr %3, align 4
  %1749 = xor i32 %1748, 1906139509
  %1750 = sub i32 %1747, %1749
  %1751 = load i32, ptr %3, align 4
  %1752 = xor i32 %1751, 1906139510
  %1753 = mul i32 %1747, %1752
  %1754 = load i32, ptr %3, align 4
  %1755 = xor i32 %1754, 1906139509
  %1756 = mul i32 %1755, %1750
  %1757 = sub i32 %1753, %1756
  store i32 %1757, ptr %52, align 4
  store i32 1645757361, ptr %3, align 4
  %1758 = xor i32 %2, -1117520873
  %1759 = and i32 %2, %1758
  %1760 = or i32 %2, %1758
  %1761 = xor i32 %2, %1758
  %1762 = add i32 %2, %1758
  %1763 = sub i32 %1762, %1761
  %1764 = mul i32 %1759, 2
  %1765 = sub i32 %1763, %1764
  %1766 = mul i32 %1765, 236
  %1767 = icmp uge i32 %1766, 0
  br i1 %1767, label %1787, label %2344

1768:                                             ; preds = %53
  %1769 = load ptr, ptr %13, align 8
  call void @free(ptr noundef %1769) #8
  %1770 = load ptr, ptr %14, align 8
  call void @free(ptr noundef %1770) #8
  %1771 = load ptr, ptr %16, align 8
  call void @free(ptr noundef %1771) #8
  %1772 = load ptr, ptr %20, align 8
  call void @free(ptr noundef %1772) #8
  %1773 = load ptr, ptr %21, align 8
  call void @free(ptr noundef %1773) #8
  %1774 = load ptr, ptr %10, align 8
  call void @free(ptr noundef %1774) #8
  call void @freeGrid()
  store i32 0, ptr %4, align 4
  store i32 462455911, ptr %3, align 4
  %1775 = xor i32 %2, -2034897017
  %1776 = and i32 %2, %1775
  %1777 = or i32 %2, %1775
  %1778 = xor i32 %2, %1775
  %1779 = mul i32 %1777, 2
  %1780 = sub i32 %1779, %1778
  %1781 = sub i32 %1780, %2
  %1782 = sub i32 %1781, %1775
  %1783 = mul i32 %1782, 190
  %1784 = icmp slt i32 %1783, 0
  br i1 %1784, label %2352, label %1787

1785:                                             ; preds = %53
  %1786 = load i32, ptr %4, align 4
  ret i32 %1786

1787:                                             ; preds = %2402, %2394, %2386, %2378, %2373, %2371, %2364, %2362, %2352, %2344, %2337, %2330, %2323, %2318, %2312, %2306, %2302, %2300, %2292, %2290, %2288, %2281, %2275, %2271, %2263, %2257, %2251, %2245, %2239, %2234, %2226, %2224, %2222, %2215, %2210, %2207, %2201, %2194, %2186, %2180, %2172, %2169, %2161, %2156, %2154, %2148, %2141, %2136, %2128, %2122, %2115, %2109, %2102, %2095, %2087, %2081, %2078, %2074, %2072, %2064, %2056, %2054, %2047, %2039, %2037, %2033, %2025, %2022, %2016, %2013, %2005, %1997, %1991, %1986, %1978, %1971, %1963, %1957, %1950, %1943, %1938, %1932, %1926, %1920, %1914, %1903, %1890, %1878, %1865, %1845, %1832, %1821, %1808, %1768, %1731, %1711, %1692, %1675, %1642, %1631, %1619, %1606, %1581, %1526, %1511, %1485, %1404, %1389, %1378, %1327, %1313, %1288, %1277, %1258, %1238, %1218, %1200, %1181, %1171, %1157, %1104, %1091, %1061, %1039, %1021, %1010, %993, %982, %943, %901, %890, %850, %841, %819, %804, %793, %782, %757, %744, %735, %720, %709, %690, %661, %625, %601, %581, %561, %512, %499, %480, %466, %435, %416, %367, %353, %334, %319, %305, %254, %241, %208, %175, %161, %135, %125, %106, %83, %71, %57
  br label %53

1788:                                             ; preds = %53
  store i32 78377744, ptr %3, align 4
  call void asm sideeffect "", ""()
  %1789 = xor i32 %2, 906699859
  %1790 = and i32 %2, %1789
  %1791 = or i32 %2, %1789
  %1792 = xor i32 %2, %1789
  %1793 = add i32 %2, %1789
  %1794 = sub i32 %1793, %1792
  %1795 = mul i32 %1790, 2
  %1796 = sub i32 %1794, %1795
  %1797 = mul i32 %1796, 194
  %1798 = xor i32 %2, -1992421539
  %1799 = and i32 %2, %1798
  %1800 = or i32 %2, %1798
  %1801 = xor i32 %2, %1798
  %1802 = mul i32 %1800, 2
  %1803 = sub i32 %1802, %1801
  %1804 = sub i32 %1803, %2
  %1805 = sub i32 %1804, %1798
  %1806 = mul i32 %1805, 138
  %1807 = icmp eq i32 %1797, %1806
  br i1 %1807, label %53, label %2358

1808:                                             ; preds = %53
  %1809 = load i32, ptr %3, align 4
  %1810 = xor i32 %1809, -1772749379
  store i32 %1810, ptr %3, align 4
  %1811 = xor i32 %2, -1314037951
  %1812 = and i32 %2, %1811
  %1813 = or i32 %2, %1811
  %1814 = xor i32 %2, %1811
  %1815 = mul i32 %1813, 2
  %1816 = sub i32 %1815, %1814
  %1817 = sub i32 %1816, %2
  %1818 = sub i32 %1817, %1811
  %1819 = mul i32 %1818, 252
  %1820 = icmp ne i32 %1819, 0
  br i1 %1820, label %2362, label %1787

1821:                                             ; preds = %53
  %1822 = load i32, ptr %3, align 4
  %1823 = xor i32 %1822, 259670832
  store i32 %1823, ptr %3, align 4
  %1824 = xor i32 %2, -734799849
  %1825 = and i32 %2, %1824
  %1826 = or i32 %2, %1824
  %1827 = xor i32 %2, %1824
  %1828 = sub i32 %1826, %1827
  %1829 = sub i32 %1828, %1825
  %1830 = mul i32 %1829, 155
  %1831 = icmp sle i32 %1830, 0
  br i1 %1831, label %1787, label %2364

1832:                                             ; preds = %53
  %1833 = load i32, ptr %3, align 4
  %1834 = xor i32 %1833, 1419086942
  store i32 %1834, ptr %3, align 4
  %1835 = xor i32 %2, -1669142977
  %1836 = and i32 %2, %1835
  %1837 = or i32 %2, %1835
  %1838 = xor i32 %2, %1835
  %1839 = mul i32 %1837, 2
  %1840 = sub i32 %1839, %1838
  %1841 = sub i32 %1840, %2
  %1842 = sub i32 %1841, %1835
  %1843 = mul i32 %1842, 197
  %1844 = icmp slt i32 %1843, 1
  br i1 %1844, label %1787, label %2371

1845:                                             ; preds = %53
  %1846 = load i32, ptr %3, align 4
  %1847 = xor i32 %1846, -1033179257
  store i32 %1847, ptr %3, align 4
  %1848 = xor i32 %2, 1220784169
  %1849 = and i32 %2, %1848
  %1850 = or i32 %2, %1848
  %1851 = xor i32 %2, %1848
  %1852 = add i32 %2, %1848
  %1853 = sub i32 %1852, %1851
  %1854 = mul i32 %1849, 2
  %1855 = sub i32 %1853, %1854
  %1856 = mul i32 %1855, 218
  %1857 = xor i32 %2, 1028292165
  %1858 = and i32 %2, %1857
  %1859 = or i32 %2, %1857
  %1860 = xor i32 %2, %1857
  %1861 = sub i32 %1859, %1860
  %1862 = sub i32 %1861, %1858
  %1863 = mul i32 %1862, 128
  %1864 = icmp eq i32 %1856, %1863
  br i1 %1864, label %1787, label %2373

1865:                                             ; preds = %53
  %1866 = load i32, ptr %3, align 4
  %1867 = xor i32 %1866, -60170415
  store i32 %1867, ptr %3, align 4
  %1868 = xor i32 %2, 220587217
  %1869 = and i32 %2, %1868
  %1870 = or i32 %2, %1868
  %1871 = xor i32 %2, %1868
  %1872 = add i32 %2, %1868
  %1873 = sub i32 %1872, %1871
  %1874 = mul i32 %1869, 2
  %1875 = sub i32 %1873, %1874
  %1876 = mul i32 %1875, 192
  %1877 = icmp sle i32 %1876, 0
  br i1 %1877, label %1787, label %2378

1878:                                             ; preds = %53
  %1879 = load i32, ptr %3, align 4
  %1880 = xor i32 %1879, -1704191025
  store i32 %1880, ptr %3, align 4
  %1881 = xor i32 %2, 1714225473
  %1882 = and i32 %2, %1881
  %1883 = or i32 %2, %1881
  %1884 = xor i32 %2, %1881
  %1885 = add i32 %1882, %1883
  %1886 = sub i32 %1885, %2
  %1887 = sub i32 %1886, %1881
  %1888 = mul i32 %1887, 164
  %1889 = icmp slt i32 %1888, 1
  br i1 %1889, label %1787, label %2386

1890:                                             ; preds = %53
  %1891 = load i32, ptr %3, align 4
  %1892 = xor i32 %1891, 1383847273
  store i32 %1892, ptr %3, align 4
  %1893 = xor i32 %2, 1747409911
  %1894 = and i32 %2, %1893
  %1895 = or i32 %2, %1893
  %1896 = xor i32 %2, %1893
  %1897 = add i32 %2, %1893
  %1898 = sub i32 %1897, %1896
  %1899 = mul i32 %1894, 2
  %1900 = sub i32 %1898, %1899
  %1901 = mul i32 %1900, 182
  %1902 = icmp sgt i32 %1901, 0
  br i1 %1902, label %2394, label %1787

1903:                                             ; preds = %53
  %1904 = load i32, ptr %3, align 4
  %1905 = xor i32 %1904, 239376203
  store i32 %1905, ptr %3, align 4
  %1906 = xor i32 %2, -843777183
  %1907 = and i32 %2, %1906
  %1908 = or i32 %2, %1906
  %1909 = xor i32 %2, %1906
  %1910 = sub i32 %1908, %1909
  %1911 = sub i32 %1910, %1907
  %1912 = mul i32 %1911, 216
  %1913 = icmp uge i32 %1912, 0
  br i1 %1913, label %1787, label %2402

1914:                                             ; preds = %57
  %1915 = load i64, ptr %1, align 8
  %1916 = and i64 3667755164, %1915
  %1917 = xor i64 %1916, %1915
  %1918 = xor i64 %1917, 2046526778
  %1919 = sub i64 %1918, %1915
  store i64 %1919, ptr %1, align 8
  br label %1787

1920:                                             ; preds = %71
  %1921 = load i64, ptr %1, align 8
  %1922 = mul i64 %1921, 1628922096
  %1923 = mul i64 %1922, %1921
  %1924 = add i64 %1923, 1628922096
  %1925 = sub i64 %1924, 3092781010
  store i64 %1925, ptr %1, align 8
  br label %1787

1926:                                             ; preds = %83
  %1927 = load i64, ptr %1, align 8
  %1928 = sub i64 0, %1927
  %1929 = add i64 %1928, 2234485063
  %1930 = add i64 %1929, 2234485063
  %1931 = and i64 %1930, %1927
  store i64 %1931, ptr %1, align 8
  br label %1787

1932:                                             ; preds = %106
  %1933 = load i64, ptr %1, align 8
  %1934 = mul i64 4929723211660973650, %1933
  %1935 = add i64 %1934, %1933
  %1936 = xor i64 %1935, %1933
  %1937 = add i64 %1936, %1933
  store i64 %1937, ptr %1, align 8
  br label %1787

1938:                                             ; preds = %125
  %1939 = load i64, ptr %1, align 8
  %1940 = add i64 %1939, 1083641635
  %1941 = xor i64 %1940, 2733041891
  %1942 = and i64 %1941, %1939
  store i64 %1942, ptr %1, align 8
  br label %1787

1943:                                             ; preds = %135
  %1944 = load i64, ptr %1, align 8
  %1945 = add i64 2879695135, %1944
  %1946 = xor i64 %1945, %1944
  %1947 = sub i64 %1946, 2879695135
  %1948 = add i64 %1947, 84667939
  %1949 = or i64 %1948, %1944
  store i64 %1949, ptr %1, align 8
  br label %1787

1950:                                             ; preds = %161
  %1951 = load i64, ptr %1, align 8
  %1952 = sub i64 %1951, 3203267482
  %1953 = add i64 %1952, %1951
  %1954 = add i64 %1953, 3203267482
  %1955 = mul i64 %1954, %1951
  %1956 = sub i64 %1955, 202949484
  store i64 %1956, ptr %1, align 8
  br label %1787

1957:                                             ; preds = %175
  %1958 = load i64, ptr %1, align 8
  %1959 = sub i64 3038238644, %1958
  %1960 = mul i64 %1959, %1958
  %1961 = add i64 %1960, 2469613252
  %1962 = xor i64 %1961, 3038238644
  store i64 %1962, ptr %1, align 8
  br label %1787

1963:                                             ; preds = %208
  %1964 = load i64, ptr %1, align 8
  %1965 = or i64 %1964, 2570863429
  %1966 = and i64 %1965, 512918096
  %1967 = or i64 %1966, %1964
  %1968 = add i64 %1967, 2570863429
  %1969 = xor i64 %1968, 512918096
  %1970 = sub i64 %1969, %1964
  store i64 %1970, ptr %1, align 8
  br label %1787

1971:                                             ; preds = %241
  %1972 = load i64, ptr %1, align 8
  %1973 = xor i64 %1972, %1972
  %1974 = mul i64 %1973, 3527539335
  %1975 = xor i64 %1974, 4224443905
  %1976 = mul i64 %1975, %1972
  %1977 = and i64 %1976, 3527539335
  store i64 %1977, ptr %1, align 8
  br label %1787

1978:                                             ; preds = %254
  %1979 = load i64, ptr %1, align 8
  %1980 = mul i64 4070681633, %1979
  %1981 = or i64 %1980, 4070681633
  %1982 = add i64 %1981, 1229292331
  %1983 = add i64 %1982, 1229292331
  %1984 = xor i64 %1983, %1979
  %1985 = add i64 %1984, 1229292331
  store i64 %1985, ptr %1, align 8
  br label %1787

1986:                                             ; preds = %305
  %1987 = load i64, ptr %1, align 8
  %1988 = or i64 170459067, %1987
  %1989 = add i64 %1988, 4114397780
  %1990 = and i64 %1989, 3943938713
  store i64 %1990, ptr %1, align 8
  br label %1787

1991:                                             ; preds = %319
  %1992 = load i64, ptr %1, align 8
  %1993 = mul i64 4098458268, %1992
  %1994 = xor i64 %1993, %1992
  %1995 = add i64 %1994, %1992
  %1996 = or i64 %1995, 4098458268
  store i64 %1996, ptr %1, align 8
  br label %1787

1997:                                             ; preds = %334
  %1998 = load i64, ptr %1, align 8
  %1999 = add i64 %1998, %1998
  %2000 = mul i64 %1999, 2761023240
  %2001 = mul i64 %2000, 1367505130
  %2002 = mul i64 %2001, 1367505130
  %2003 = mul i64 %2002, 1367505130
  %2004 = mul i64 %2003, 1367505130
  store i64 %2004, ptr %1, align 8
  br label %1787

2005:                                             ; preds = %353
  %2006 = load i64, ptr %1, align 8
  %2007 = add i64 4069052453, %2006
  %2008 = add i64 %2007, 433575355
  %2009 = and i64 %2008, 433575355
  %2010 = add i64 %2009, %2006
  %2011 = xor i64 %2010, 4069052453
  %2012 = sub i64 %2011, 433575355
  store i64 %2012, ptr %1, align 8
  br label %1787

2013:                                             ; preds = %367
  %2014 = load i64, ptr %1, align 8
  %2015 = and i64 0, %2014
  store i64 %2015, ptr %1, align 8
  br label %1787

2016:                                             ; preds = %416
  %2017 = load i64, ptr %1, align 8
  %2018 = mul i64 %2017, 3251938787
  %2019 = and i64 %2018, 1543956295
  %2020 = mul i64 %2019, %2017
  %2021 = xor i64 %2020, %2017
  store i64 %2021, ptr %1, align 8
  br label %1787

2022:                                             ; preds = %435
  %2023 = load i64, ptr %1, align 8
  %2024 = and i64 1071645569, %2023
  store i64 %2024, ptr %1, align 8
  br label %1787

2025:                                             ; preds = %466
  %2026 = load i64, ptr %1, align 8
  %2027 = mul i64 %2026, 4237232554
  %2028 = xor i64 %2027, %2026
  %2029 = xor i64 %2028, 4237232554
  %2030 = xor i64 %2029, 4237232554
  %2031 = sub i64 %2030, 1538435763
  %2032 = sub i64 %2031, 1538435763
  store i64 %2032, ptr %1, align 8
  br label %1787

2033:                                             ; preds = %480
  %2034 = load i64, ptr %1, align 8
  %2035 = xor i64 3427666701, %2034
  %2036 = add i64 %2035, %2034
  store i64 %2036, ptr %1, align 8
  br label %1787

2037:                                             ; preds = %499
  %2038 = load i64, ptr %1, align 8
  store i64 -4021809049, ptr %1, align 8
  br label %1787

2039:                                             ; preds = %512
  %2040 = load i64, ptr %1, align 8
  %2041 = and i64 3768612964, %2040
  %2042 = and i64 %2041, 1054676895
  %2043 = and i64 %2042, %2040
  %2044 = sub i64 %2043, 3768612964
  %2045 = mul i64 %2044, %2040
  %2046 = sub i64 %2045, %2040
  store i64 %2046, ptr %1, align 8
  br label %1787

2047:                                             ; preds = %561
  %2048 = load i64, ptr %1, align 8
  %2049 = or i64 3394386699, %2048
  %2050 = and i64 %2049, %2048
  %2051 = mul i64 %2050, 2256702109
  %2052 = sub i64 %2051, 2256702109
  %2053 = or i64 %2052, 3394386699
  store i64 %2053, ptr %1, align 8
  br label %1787

2054:                                             ; preds = %581
  %2055 = load i64, ptr %1, align 8
  store i64 6172311421, ptr %1, align 8
  br label %1787

2056:                                             ; preds = %601
  %2057 = load i64, ptr %1, align 8
  %2058 = xor i64 3128118020, %2057
  %2059 = sub i64 %2058, 3128118020
  %2060 = xor i64 %2059, %2057
  %2061 = xor i64 %2060, %2057
  %2062 = or i64 %2061, 2750752389
  %2063 = and i64 %2062, %2057
  store i64 %2063, ptr %1, align 8
  br label %1787

2064:                                             ; preds = %625
  %2065 = load i64, ptr %1, align 8
  %2066 = sub i64 2771944355, %2065
  %2067 = mul i64 %2066, 2771944355
  %2068 = and i64 %2067, 2771944355
  %2069 = xor i64 %2068, 2771944355
  %2070 = sub i64 %2069, 1610685852
  %2071 = sub i64 %2070, 2771944355
  store i64 %2071, ptr %1, align 8
  br label %1787

2072:                                             ; preds = %661
  %2073 = load i64, ptr %1, align 8
  store i64 -399337963884020388, ptr %1, align 8
  br label %1787

2074:                                             ; preds = %690
  %2075 = load i64, ptr %1, align 8
  %2076 = xor i64 3387069403081361001, %2075
  %2077 = and i64 %2076, 543019974
  store i64 %2077, ptr %1, align 8
  br label %1787

2078:                                             ; preds = %709
  %2079 = load i64, ptr %1, align 8
  %2080 = add i64 812650513, %2079
  store i64 %2080, ptr %1, align 8
  br label %1787

2081:                                             ; preds = %720
  %2082 = load i64, ptr %1, align 8
  %2083 = add i64 3838818116, %2082
  %2084 = and i64 %2083, 3838818116
  %2085 = add i64 %2084, %2082
  %2086 = xor i64 %2085, 1095060624
  store i64 %2086, ptr %1, align 8
  br label %1787

2087:                                             ; preds = %735
  %2088 = load i64, ptr %1, align 8
  %2089 = mul i64 %2088, 482338843
  %2090 = mul i64 %2089, %2088
  %2091 = mul i64 %2090, 3742200187
  %2092 = mul i64 %2091, %2088
  %2093 = sub i64 %2092, 482338843
  %2094 = or i64 %2093, 482338843
  store i64 %2094, ptr %1, align 8
  br label %1787

2095:                                             ; preds = %744
  %2096 = load i64, ptr %1, align 8
  %2097 = mul i64 %2096, %2096
  %2098 = mul i64 %2097, 1623240785
  %2099 = sub i64 %2098, %2096
  %2100 = or i64 %2099, %2096
  %2101 = add i64 %2100, 1540186355
  store i64 %2101, ptr %1, align 8
  br label %1787

2102:                                             ; preds = %757
  %2103 = load i64, ptr %1, align 8
  %2104 = and i64 2586707510, %2103
  %2105 = xor i64 %2104, %2103
  %2106 = sub i64 %2105, 3668154447
  %2107 = or i64 %2106, %2103
  %2108 = xor i64 %2107, 3668154447
  store i64 %2108, ptr %1, align 8
  br label %1787

2109:                                             ; preds = %782
  %2110 = load i64, ptr %1, align 8
  %2111 = sub i64 %2110, 3762104824
  %2112 = sub i64 %2111, 3762104824
  %2113 = sub i64 %2112, 3762104824
  %2114 = or i64 %2113, %2110
  store i64 %2114, ptr %1, align 8
  br label %1787

2115:                                             ; preds = %793
  %2116 = load i64, ptr %1, align 8
  %2117 = or i64 3103647078, %2116
  %2118 = sub i64 %2117, %2116
  %2119 = or i64 %2118, %2116
  %2120 = mul i64 %2119, 3103647078
  %2121 = xor i64 %2120, 3103647078
  store i64 %2121, ptr %1, align 8
  br label %1787

2122:                                             ; preds = %804
  %2123 = load i64, ptr %1, align 8
  %2124 = sub i64 3975616607, %2123
  %2125 = mul i64 %2124, 3975616607
  %2126 = mul i64 %2125, 3975616607
  %2127 = and i64 %2126, 3975616607
  store i64 %2127, ptr %1, align 8
  br label %1787

2128:                                             ; preds = %819
  %2129 = load i64, ptr %1, align 8
  %2130 = mul i64 %2129, 1584165758
  %2131 = or i64 %2130, %2129
  %2132 = add i64 %2131, 1442014780
  %2133 = sub i64 %2132, 1442014780
  %2134 = sub i64 %2133, 1442014780
  %2135 = and i64 %2134, 1584165758
  store i64 %2135, ptr %1, align 8
  br label %1787

2136:                                             ; preds = %841
  %2137 = load i64, ptr %1, align 8
  %2138 = sub i64 %2137, 3504173739
  %2139 = sub i64 %2138, 3504173739
  %2140 = xor i64 %2139, 3371443250
  store i64 %2140, ptr %1, align 8
  br label %1787

2141:                                             ; preds = %850
  %2142 = load i64, ptr %1, align 8
  %2143 = add i64 3512880607, %2142
  %2144 = and i64 %2143, %2142
  %2145 = add i64 %2144, %2142
  %2146 = mul i64 %2145, %2142
  %2147 = and i64 %2146, 2071444140
  store i64 %2147, ptr %1, align 8
  br label %1787

2148:                                             ; preds = %890
  %2149 = load i64, ptr %1, align 8
  %2150 = add i64 %2149, %2149
  %2151 = and i64 %2150, 3956532302
  %2152 = and i64 %2151, %2149
  %2153 = sub i64 %2152, 3279864809
  store i64 %2153, ptr %1, align 8
  br label %1787

2154:                                             ; preds = %901
  %2155 = load i64, ptr %1, align 8
  store i64 81378010942505721, ptr %1, align 8
  br label %1787

2156:                                             ; preds = %943
  %2157 = load i64, ptr %1, align 8
  %2158 = xor i64 3518181683, %2157
  %2159 = mul i64 %2158, %2157
  %2160 = xor i64 %2159, 2642820091
  store i64 %2160, ptr %1, align 8
  br label %1787

2161:                                             ; preds = %982
  %2162 = load i64, ptr %1, align 8
  %2163 = or i64 4113589662, %2162
  %2164 = xor i64 %2163, %2162
  %2165 = and i64 %2164, 3500932817
  %2166 = add i64 %2165, %2162
  %2167 = and i64 %2166, %2162
  %2168 = and i64 %2167, 3500932817
  store i64 %2168, ptr %1, align 8
  br label %1787

2169:                                             ; preds = %993
  %2170 = load i64, ptr %1, align 8
  %2171 = and i64 67125459, %2170
  store i64 %2171, ptr %1, align 8
  br label %1787

2172:                                             ; preds = %1010
  %2173 = load i64, ptr %1, align 8
  %2174 = or i64 %2173, 581056633
  %2175 = mul i64 %2174, 3438346217
  %2176 = add i64 %2175, 3438346217
  %2177 = or i64 %2176, 3438346217
  %2178 = mul i64 %2177, 3438346217
  %2179 = or i64 %2178, %2173
  store i64 %2179, ptr %1, align 8
  br label %1787

2180:                                             ; preds = %1021
  %2181 = load i64, ptr %1, align 8
  %2182 = and i64 %2181, %2181
  %2183 = add i64 %2182, %2181
  %2184 = and i64 %2183, %2181
  %2185 = xor i64 %2184, %2181
  store i64 %2185, ptr %1, align 8
  br label %1787

2186:                                             ; preds = %1039
  %2187 = load i64, ptr %1, align 8
  %2188 = or i64 3674744795, %2187
  %2189 = mul i64 %2188, 3674744795
  %2190 = and i64 %2189, 3674744795
  %2191 = sub i64 %2190, 1520858216
  %2192 = add i64 %2191, %2187
  %2193 = xor i64 %2192, %2187
  store i64 %2193, ptr %1, align 8
  br label %1787

2194:                                             ; preds = %1061
  %2195 = load i64, ptr %1, align 8
  %2196 = xor i64 9738273, %2195
  %2197 = xor i64 %2196, %2195
  %2198 = add i64 %2197, 278198847
  %2199 = sub i64 %2198, 278198847
  %2200 = add i64 %2199, %2195
  store i64 %2200, ptr %1, align 8
  br label %1787

2201:                                             ; preds = %1091
  %2202 = load i64, ptr %1, align 8
  %2203 = sub i64 2599564414, %2202
  %2204 = sub i64 %2203, %2202
  %2205 = and i64 %2204, 2599564414
  %2206 = add i64 %2205, %2202
  store i64 %2206, ptr %1, align 8
  br label %1787

2207:                                             ; preds = %1104
  %2208 = load i64, ptr %1, align 8
  %2209 = or i64 3561504777, %2208
  store i64 %2209, ptr %1, align 8
  br label %1787

2210:                                             ; preds = %1157
  %2211 = load i64, ptr %1, align 8
  %2212 = sub i64 1604299143, %2211
  %2213 = sub i64 %2212, %2211
  %2214 = mul i64 %2213, 1404490742
  store i64 %2214, ptr %1, align 8
  br label %1787

2215:                                             ; preds = %1171
  %2216 = load i64, ptr %1, align 8
  %2217 = sub i64 2118271830, %2216
  %2218 = and i64 %2217, 2118271830
  %2219 = sub i64 %2218, 2118271830
  %2220 = add i64 %2219, %2216
  %2221 = and i64 %2220, 2118271830
  store i64 %2221, ptr %1, align 8
  br label %1787

2222:                                             ; preds = %1181
  %2223 = load i64, ptr %1, align 8
  store i64 1981917286, ptr %1, align 8
  br label %1787

2224:                                             ; preds = %1200
  %2225 = load i64, ptr %1, align 8
  store i64 3070164303, ptr %1, align 8
  br label %1787

2226:                                             ; preds = %1218
  %2227 = load i64, ptr %1, align 8
  %2228 = and i64 %2227, 221053694
  %2229 = xor i64 %2228, 115958928
  %2230 = mul i64 %2229, 221053694
  %2231 = xor i64 %2230, 221053694
  %2232 = sub i64 %2231, 221053694
  %2233 = and i64 %2232, 221053694
  store i64 %2233, ptr %1, align 8
  br label %1787

2234:                                             ; preds = %1238
  %2235 = load i64, ptr %1, align 8
  %2236 = mul i64 2028423274563576872, %2235
  %2237 = xor i64 %2236, 1811086113
  %2238 = add i64 %2237, %2235
  store i64 %2238, ptr %1, align 8
  br label %1787

2239:                                             ; preds = %1258
  %2240 = load i64, ptr %1, align 8
  %2241 = and i64 %2240, %2240
  %2242 = xor i64 %2241, 1815570544
  %2243 = add i64 %2242, 4273576368
  %2244 = or i64 %2243, %2240
  store i64 %2244, ptr %1, align 8
  br label %1787

2245:                                             ; preds = %1277
  %2246 = load i64, ptr %1, align 8
  %2247 = mul i64 %2246, %2246
  %2248 = add i64 %2247, %2246
  %2249 = sub i64 %2248, 2096990159
  %2250 = xor i64 %2249, %2246
  store i64 %2250, ptr %1, align 8
  br label %1787

2251:                                             ; preds = %1288
  %2252 = load i64, ptr %1, align 8
  %2253 = and i64 %2252, 1230859286
  %2254 = add i64 %2253, 1124180252
  %2255 = or i64 %2254, 1230859286
  %2256 = or i64 %2255, %2252
  store i64 %2256, ptr %1, align 8
  br label %1787

2257:                                             ; preds = %1313
  %2258 = load i64, ptr %1, align 8
  %2259 = and i64 3080880927, %2258
  %2260 = and i64 %2259, 915652525
  %2261 = and i64 %2260, 915652525
  %2262 = xor i64 %2261, %2258
  store i64 %2262, ptr %1, align 8
  br label %1787

2263:                                             ; preds = %1327
  %2264 = load i64, ptr %1, align 8
  %2265 = xor i64 %2264, 3091564590
  %2266 = mul i64 %2265, 3091564590
  %2267 = sub i64 %2266, 3091564590
  %2268 = xor i64 %2267, 2969922753
  %2269 = xor i64 %2268, 3091564590
  %2270 = and i64 %2269, 3091564590
  store i64 %2270, ptr %1, align 8
  br label %1787

2271:                                             ; preds = %1378
  %2272 = load i64, ptr %1, align 8
  %2273 = sub i64 900457352608575481, %2272
  %2274 = xor i64 %2273, 948924313
  store i64 %2274, ptr %1, align 8
  br label %1787

2275:                                             ; preds = %1389
  %2276 = load i64, ptr %1, align 8
  %2277 = add i64 1611495237, %2276
  %2278 = sub i64 %2277, 1611495237
  %2279 = or i64 %2278, 1611495237
  %2280 = sub i64 %2279, 1611495237
  store i64 %2280, ptr %1, align 8
  br label %1787

2281:                                             ; preds = %1404
  %2282 = load i64, ptr %1, align 8
  %2283 = mul i64 1464784274, %2282
  %2284 = sub i64 %2283, 1464784274
  %2285 = mul i64 %2284, 2053633744
  %2286 = xor i64 %2285, 1464784274
  %2287 = and i64 %2286, %2282
  store i64 %2287, ptr %1, align 8
  br label %1787

2288:                                             ; preds = %1485
  %2289 = load i64, ptr %1, align 8
  store i64 256860779793907711, ptr %1, align 8
  br label %1787

2290:                                             ; preds = %1511
  %2291 = load i64, ptr %1, align 8
  store i64 -1023641099272430116, ptr %1, align 8
  br label %1787

2292:                                             ; preds = %1526
  %2293 = load i64, ptr %1, align 8
  %2294 = and i64 751318496, %2293
  %2295 = add i64 %2294, 751318496
  %2296 = mul i64 %2295, %2293
  %2297 = mul i64 %2296, 751318496
  %2298 = or i64 %2297, 751318496
  %2299 = and i64 %2298, 1976313621
  store i64 %2299, ptr %1, align 8
  br label %1787

2300:                                             ; preds = %1581
  %2301 = load i64, ptr %1, align 8
  store i64 2973525639, ptr %1, align 8
  br label %1787

2302:                                             ; preds = %1606
  %2303 = load i64, ptr %1, align 8
  %2304 = mul i64 8136361765441445904, %2303
  %2305 = and i64 %2304, 2852430852
  store i64 %2305, ptr %1, align 8
  br label %1787

2306:                                             ; preds = %1619
  %2307 = load i64, ptr %1, align 8
  %2308 = xor i64 %2307, %2307
  %2309 = and i64 %2308, 1127503767
  %2310 = sub i64 %2309, %2307
  %2311 = or i64 %2310, 1753129845
  store i64 %2311, ptr %1, align 8
  br label %1787

2312:                                             ; preds = %1631
  %2313 = load i64, ptr %1, align 8
  %2314 = and i64 430778985, %2313
  %2315 = or i64 %2314, 2672766830
  %2316 = sub i64 %2315, 2672766830
  %2317 = or i64 %2316, 430778985
  store i64 %2317, ptr %1, align 8
  br label %1787

2318:                                             ; preds = %1642
  %2319 = load i64, ptr %1, align 8
  %2320 = xor i64 %2319, %2319
  %2321 = add i64 %2320, %2319
  %2322 = sub i64 %2321, 2885174067
  store i64 %2322, ptr %1, align 8
  br label %1787

2323:                                             ; preds = %1675
  %2324 = load i64, ptr %1, align 8
  %2325 = xor i64 %2324, 2322213426
  %2326 = mul i64 %2325, 742430800
  %2327 = sub i64 %2326, 742430800
  %2328 = or i64 %2327, 2322213426
  %2329 = add i64 %2328, %2324
  store i64 %2329, ptr %1, align 8
  br label %1787

2330:                                             ; preds = %1692
  %2331 = load i64, ptr %1, align 8
  %2332 = or i64 %2331, %2331
  %2333 = mul i64 %2332, 2394910944
  %2334 = sub i64 %2333, 1039750822
  %2335 = mul i64 %2334, 2394910944
  %2336 = and i64 %2335, 1039750822
  store i64 %2336, ptr %1, align 8
  br label %1787

2337:                                             ; preds = %1711
  %2338 = load i64, ptr %1, align 8
  %2339 = or i64 %2338, %2338
  %2340 = sub i64 %2339, 3075032425
  %2341 = sub i64 %2340, 3075032425
  %2342 = and i64 %2341, 3140900646
  %2343 = or i64 %2342, 3075032425
  store i64 %2343, ptr %1, align 8
  br label %1787

2344:                                             ; preds = %1731
  %2345 = load i64, ptr %1, align 8
  %2346 = or i64 %2345, %2345
  %2347 = and i64 %2346, 4054147955
  %2348 = or i64 %2347, 4054147955
  %2349 = sub i64 %2348, 1398152788
  %2350 = and i64 %2349, 1398152788
  %2351 = or i64 %2350, 1398152788
  store i64 %2351, ptr %1, align 8
  br label %1787

2352:                                             ; preds = %1768
  %2353 = load i64, ptr %1, align 8
  %2354 = xor i64 %2353, %2353
  %2355 = add i64 %2354, 2305453548
  %2356 = sub i64 %2355, 2305453548
  %2357 = or i64 %2356, %2353
  store i64 %2357, ptr %1, align 8
  br label %1787

2358:                                             ; preds = %1788
  %2359 = load i64, ptr %1, align 8
  %2360 = or i64 5805610528, %2359
  %2361 = xor i64 %2360, 2179754180
  store i64 %2361, ptr %1, align 8
  br label %53

2362:                                             ; preds = %1808
  %2363 = load i64, ptr %1, align 8
  store i64 6514441822123642335, ptr %1, align 8
  br label %1787

2364:                                             ; preds = %1821
  %2365 = load i64, ptr %1, align 8
  %2366 = add i64 2395064120, %2365
  %2367 = xor i64 %2366, %2365
  %2368 = add i64 %2367, %2365
  %2369 = and i64 %2368, 2395064120
  %2370 = xor i64 %2369, 2395064120
  store i64 %2370, ptr %1, align 8
  br label %1787

2371:                                             ; preds = %1832
  %2372 = load i64, ptr %1, align 8
  store i64 1078273005, ptr %1, align 8
  br label %1787

2373:                                             ; preds = %1845
  %2374 = load i64, ptr %1, align 8
  %2375 = xor i64 %2374, 259359605
  %2376 = xor i64 %2375, 3549047252
  %2377 = and i64 %2376, 3549047252
  store i64 %2377, ptr %1, align 8
  br label %1787

2378:                                             ; preds = %1865
  %2379 = load i64, ptr %1, align 8
  %2380 = and i64 2782893859, %2379
  %2381 = sub i64 %2380, 2782893859
  %2382 = and i64 %2381, 2782893859
  %2383 = mul i64 %2382, 2782893859
  %2384 = mul i64 %2383, 418918271
  %2385 = mul i64 %2384, 2782893859
  store i64 %2385, ptr %1, align 8
  br label %1787

2386:                                             ; preds = %1878
  %2387 = load i64, ptr %1, align 8
  %2388 = or i64 %2387, %2387
  %2389 = sub i64 %2388, 994215411
  %2390 = sub i64 %2389, %2387
  %2391 = mul i64 %2390, 994215411
  %2392 = and i64 %2391, 994215411
  %2393 = add i64 %2392, 154136777
  store i64 %2393, ptr %1, align 8
  br label %1787

2394:                                             ; preds = %1890
  %2395 = load i64, ptr %1, align 8
  %2396 = add i64 %2395, 758293458
  %2397 = or i64 %2396, 1080047501
  %2398 = sub i64 %2397, 758293458
  %2399 = xor i64 %2398, 1080047501
  %2400 = or i64 %2399, %2395
  %2401 = and i64 %2400, 758293458
  store i64 %2401, ptr %1, align 8
  br label %1787

2402:                                             ; preds = %1903
  %2403 = load i64, ptr %1, align 8
  %2404 = sub i64 429969742, %2403
  %2405 = mul i64 %2404, 3932515293
  %2406 = sub i64 %2405, 3932515293
  %2407 = mul i64 %2406, %2403
  %2408 = mul i64 %2407, 214984871
  store i64 %2408, ptr %1, align 8
  br label %1787
}

declare i32 @__isoc99_scanf(ptr noundef, ...) #5

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nounwind allocsize(1) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind allocsize(0) }
attributes #7 = { nounwind allocsize(1) }
attributes #8 = { nounwind }

!llvm.ident = !{!0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Ubuntu clang version 21.1.8 (++20251221032922+2078da43e25a-1~exp1~20251221153059.70)"}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"PIE Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}

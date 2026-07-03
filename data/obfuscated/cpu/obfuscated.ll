; ModuleID = 'data/obfuscated/cpu/obfuscated.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.SegmentList = type { ptr, i32, i32 }
%struct.Segment = type { i32, i32, i32 }
%struct.Process = type { i32, i32, i32, i32, i32, i32, i32, i32, i32 }

@.str = private unnamed_addr constant [22 x i8] c"Generated processes:\0A\00", align 1
@.str.1 = private unnamed_addr constant [37 x i8] c"PID  Arr  Burst  Priority  Deadline\0A\00", align 1
@.str.2 = private unnamed_addr constant [25 x i8] c"P%-3d %-4d %-6d %-9d %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [15 x i8] c"\0AGantt chart:\0A\00", align 1
@.str.4 = private unnamed_addr constant [14 x i8] c"[%d-%d: IDLE]\00", align 1
@.str.5 = private unnamed_addr constant [13 x i8] c"[%d-%d: P%d]\00", align 1
@.str.6 = private unnamed_addr constant [5 x i8] c" -> \00", align 1
@.str.7 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.8 = private unnamed_addr constant [16 x i8] c"\0AResult table:\0A\00", align 1
@.str.9 = private unnamed_addr constant [57 x i8] c"PID  Start  Finish  Waiting  Turnaround  Response  Late\0A\00", align 1
@.str.10 = private unnamed_addr constant [36 x i8] c"P%-3d %-6d %-7d %-8d %-11d %-9d %d\0A\00", align 1
@.str.11 = private unnamed_addr constant [11 x i8] c"\0ASummary:\0A\00", align 1
@.str.12 = private unnamed_addr constant [28 x i8] c"Average waiting time: %.2f\0A\00", align 1
@.str.13 = private unnamed_addr constant [31 x i8] c"Average turnaround time: %.2f\0A\00", align 1
@.str.14 = private unnamed_addr constant [29 x i8] c"Average response time: %.2f\0A\00", align 1
@.str.15 = private unnamed_addr constant [24 x i8] c"Total late penalty: %d\0A\00", align 1
@.str.16 = private unnamed_addr constant [59 x i8] c"Worst process: P%d, finish = %d, deadline = %d, late = %d\0A\00", align 1
@.str.17 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@.str.18 = private unnamed_addr constant [15 x i8] c"Invalid input\0A\00", align 1
@.str.19 = private unnamed_addr constant [28 x i8] c"N must be in range [1, %d]\0A\00", align 1
@.str.20 = private unnamed_addr constant [27 x i8] c"CPU Scheduling Simulation\0A\00", align 1
@.str.21 = private unnamed_addr constant [15 x i8] c"Input N = %d\0A\0A\00", align 1
@.str.22 = private unnamed_addr constant [93 x i8] c"Rule: lower effective priority runs first; aging improves priority every %d waiting units.\0A\0A\00", align 1
@0 = private global i32 0

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @maxInt(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 -764582110, ptr %4, align 4
  br label %8

8:                                                ; preds = %178, %62, %61, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -864547271
  %11 = mul i32 %10, 622194535
  %12 = icmp slt i32 %11, 1286153554
  br i1 %12, label %134, label %136

13:                                               ; preds = %148
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  %14 = load i32, ptr %6, align 4
  %15 = load i32, ptr %7, align 4
  %16 = icmp sgt i32 %14, %15
  %17 = select i1 %16, i32 -362547945, i32 1039418930
  store i32 %17, ptr %4, align 4
  %18 = xor i32 %0, 72618057
  %19 = and i32 %0, %18
  %20 = or i32 %0, %18
  %21 = xor i32 %0, %18
  %22 = sub i32 %20, %21
  %23 = sub i32 %22, %19
  %24 = mul i32 %23, 198
  %25 = icmp sgt i32 %24, 0
  br i1 %25, label %154, label %61

26:                                               ; preds = %146
  %27 = load i32, ptr %6, align 4
  store i32 %27, ptr %5, align 4
  store i32 2077397682, ptr %4, align 4
  %28 = xor i32 %0, 106305085
  %29 = and i32 %0, %28
  %30 = or i32 %0, %28
  %31 = xor i32 %0, %28
  %32 = mul i32 %30, 2
  %33 = sub i32 %32, %31
  %34 = sub i32 %33, %0
  %35 = sub i32 %34, %28
  %36 = mul i32 %35, 183
  %37 = xor i32 %0, -305443809
  %38 = and i32 %0, %37
  %39 = or i32 %0, %37
  %40 = xor i32 %0, %37
  %41 = mul i32 %39, 2
  %42 = sub i32 %41, %40
  %43 = sub i32 %42, %0
  %44 = sub i32 %43, %37
  %45 = mul i32 %44, 9
  %46 = icmp eq i32 %36, %45
  br i1 %46, label %61, label %161

47:                                               ; preds = %142
  %48 = load i32, ptr %7, align 4
  store i32 %48, ptr %5, align 4
  store i32 2077397682, ptr %4, align 4
  %49 = xor i32 %0, 1161395191
  %50 = and i32 %0, %49
  %51 = or i32 %0, %49
  %52 = xor i32 %0, %49
  %53 = mul i32 %51, 2
  %54 = sub i32 %53, %52
  %55 = sub i32 %54, %0
  %56 = sub i32 %55, %49
  %57 = mul i32 %56, 67
  %58 = icmp sle i32 %57, 0
  br i1 %58, label %61, label %170

59:                                               ; preds = %150
  %60 = load i32, ptr %5, align 4
  ret i32 %60

61:                                               ; preds = %212, %203, %194, %186, %170, %161, %154, %115, %103, %92, %73, %47, %26, %13
  br label %8

62:                                               ; preds = %152, %150, %144, %142
  store i32 -764582110, ptr %4, align 4
  call void asm sideeffect "", ""()
  %63 = xor i32 %0, -2147149701
  %64 = and i32 %0, %63
  %65 = or i32 %0, %63
  %66 = xor i32 %0, %63
  %67 = add i32 %0, %63
  %68 = sub i32 %67, %66
  %69 = mul i32 %64, 2
  %70 = sub i32 %68, %69
  %71 = mul i32 %70, 195
  %72 = icmp ne i32 %71, 0
  br i1 %72, label %178, label %8

73:                                               ; preds = %152
  %74 = load i32, ptr %4, align 4
  %75 = xor i32 %74, 249101196
  store i32 %75, ptr %4, align 4
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
  br i1 %91, label %186, label %61

92:                                               ; preds = %140
  %93 = load i32, ptr %4, align 4
  %94 = xor i32 %93, 1937041680
  store i32 %94, ptr %4, align 4
  %95 = xor i32 %0, -420756149
  %96 = and i32 %0, %95
  %97 = or i32 %0, %95
  %98 = xor i32 %0, %95
  %99 = sub i32 %97, %98
  %100 = sub i32 %99, %96
  %101 = mul i32 %100, 106
  %102 = icmp ugt i32 %101, 0
  br i1 %102, label %194, label %61

103:                                              ; preds = %144
  %104 = load i32, ptr %4, align 4
  %105 = xor i32 %104, -1968998621
  store i32 %105, ptr %4, align 4
  %106 = xor i32 %0, 1639411133
  %107 = and i32 %0, %106
  %108 = or i32 %0, %106
  %109 = xor i32 %0, %106
  %110 = add i32 %107, %108
  %111 = sub i32 %110, %0
  %112 = sub i32 %111, %106
  %113 = mul i32 %112, 118
  %114 = icmp uge i32 %113, 0
  br i1 %114, label %61, label %203

115:                                              ; preds = %138
  %116 = load i32, ptr %4, align 4
  %117 = xor i32 %116, -1479741867
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
  br i1 %133, label %212, label %61

134:                                              ; preds = %8
  %135 = icmp slt i32 %11, 912412178
  br i1 %135, label %138, label %140

136:                                              ; preds = %8
  %137 = icmp slt i32 %11, 1809140927
  br i1 %137, label %146, label %148

138:                                              ; preds = %134
  %139 = icmp eq i32 %11, 39342665
  br i1 %139, label %115, label %142

140:                                              ; preds = %134
  %141 = icmp eq i32 %11, 912412178
  br i1 %141, label %92, label %144

142:                                              ; preds = %138
  %143 = icmp eq i32 %11, 900267055
  br i1 %143, label %47, label %62

144:                                              ; preds = %140
  %145 = icmp eq i32 %11, 945987273
  br i1 %145, label %103, label %62

146:                                              ; preds = %136
  %147 = icmp eq i32 %11, 1286153554
  br i1 %147, label %26, label %150

148:                                              ; preds = %136
  %149 = icmp eq i32 %11, 1809140927
  br i1 %149, label %13, label %152

150:                                              ; preds = %146
  %151 = icmp eq i32 %11, 1778729903
  br i1 %151, label %59, label %62

152:                                              ; preds = %148
  %153 = icmp eq i32 %11, 1810943323
  br i1 %153, label %73, label %62

154:                                              ; preds = %13
  %155 = load i64, ptr %3, align 8
  %156 = zext i32 %0 to i64
  %157 = zext i32 %1 to i64
  %158 = sub i64 %155, %157
  %159 = add i64 %158, %156
  %160 = add i64 %159, %156
  store i64 %160, ptr %3, align 8
  br label %61

161:                                              ; preds = %26
  %162 = load i64, ptr %3, align 8
  %163 = zext i32 %0 to i64
  %164 = zext i32 %1 to i64
  %165 = sub i64 %162, %163
  %166 = xor i64 %165, %163
  %167 = and i64 %166, %163
  %168 = mul i64 %167, %163
  %169 = or i64 %168, %162
  store i64 %169, ptr %3, align 8
  br label %61

170:                                              ; preds = %47
  %171 = load i64, ptr %3, align 8
  %172 = zext i32 %0 to i64
  %173 = zext i32 %1 to i64
  %174 = mul i64 %173, %171
  %175 = xor i64 %174, %171
  %176 = mul i64 %175, %173
  %177 = xor i64 %176, %171
  store i64 %177, ptr %3, align 8
  br label %61

178:                                              ; preds = %62
  %179 = load i64, ptr %3, align 8
  %180 = zext i32 %0 to i64
  %181 = zext i32 %1 to i64
  %182 = and i64 %180, %181
  %183 = and i64 %182, %180
  %184 = or i64 %183, %179
  %185 = xor i64 %184, %181
  store i64 %185, ptr %3, align 8
  br label %8

186:                                              ; preds = %73
  %187 = load i64, ptr %3, align 8
  %188 = zext i32 %0 to i64
  %189 = zext i32 %1 to i64
  %190 = and i64 %189, %188
  %191 = and i64 %190, %188
  %192 = sub i64 %191, %188
  %193 = xor i64 %192, %187
  store i64 %193, ptr %3, align 8
  br label %61

194:                                              ; preds = %92
  %195 = load i64, ptr %3, align 8
  %196 = zext i32 %0 to i64
  %197 = zext i32 %1 to i64
  %198 = xor i64 %196, %195
  %199 = add i64 %198, %197
  %200 = add i64 %199, %197
  %201 = add i64 %200, %195
  %202 = mul i64 %201, %196
  store i64 %202, ptr %3, align 8
  br label %61

203:                                              ; preds = %103
  %204 = load i64, ptr %3, align 8
  %205 = zext i32 %0 to i64
  %206 = zext i32 %1 to i64
  %207 = and i64 %205, %204
  %208 = and i64 %207, %206
  %209 = sub i64 %208, %206
  %210 = sub i64 %209, %205
  %211 = and i64 %210, %205
  store i64 %211, ptr %3, align 8
  br label %61

212:                                              ; preds = %115
  %213 = load i64, ptr %3, align 8
  %214 = zext i32 %0 to i64
  %215 = zext i32 %1 to i64
  %216 = add i64 %213, %213
  %217 = xor i64 %216, %215
  %218 = and i64 %217, %214
  store i64 %218, ptr %3, align 8
  br label %61
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @initSegments(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.SegmentList, ptr %3, i32 0, i32 1
  store i32 0, ptr %4, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds nuw %struct.SegmentList, ptr %5, i32 0, i32 2
  store i32 64, ptr %6, align 4
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds nuw %struct.SegmentList, ptr %7, i32 0, i32 2
  %9 = load i32, ptr %8, align 4
  %10 = sext i32 %9 to i64
  %11 = mul i64 12, %10
  %12 = call noalias ptr @malloc(i64 noundef %11) #6
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.SegmentList, ptr %13, i32 0, i32 0
  store ptr %12, ptr %14, align 8
  ret void
}

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @addSegment(ptr noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca i64, align 8
  store i64 0, ptr %5, align 8
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca ptr, align 8
  store i32 -975716143, ptr %6, align 4
  br label %12

12:                                               ; preds = %527, %247, %246, %4
  %13 = load i32, ptr %6, align 4
  %14 = sub i32 %13, -1001811251
  %15 = mul i32 %14, 848609613
  %16 = icmp slt i32 %15, 1034826819
  br i1 %16, label %359, label %361

17:                                               ; preds = %369
  store ptr %0, ptr %7, align 8
  store i32 %1, ptr %8, align 4
  store i32 %2, ptr %9, align 4
  store i32 %3, ptr %10, align 4
  %18 = load i32, ptr %10, align 4
  %19 = load i32, ptr %9, align 4
  %20 = icmp sle i32 %18, %19
  %21 = select i1 %20, i32 1519356596, i32 -252471652
  store i32 %21, ptr %6, align 4
  %22 = xor i32 %1, 772148447
  %23 = and i32 %1, %22
  %24 = or i32 %1, %22
  %25 = xor i32 %1, %22
  %26 = add i32 %1, %22
  %27 = sub i32 %26, %25
  %28 = mul i32 %23, 2
  %29 = sub i32 %27, %28
  %30 = mul i32 %29, 233
  %31 = icmp sgt i32 %30, 0
  br i1 %31, label %415, label %246

32:                                               ; preds = %411
  store i32 1711126762, ptr %6, align 4
  %33 = xor i32 %1, 1640193655
  %34 = and i32 %1, %33
  %35 = or i32 %1, %33
  %36 = xor i32 %1, %33
  %37 = sub i32 %35, %36
  %38 = sub i32 %37, %34
  %39 = mul i32 %38, 48
  %40 = xor i32 %1, -1902838265
  %41 = and i32 %1, %40
  %42 = or i32 %1, %40
  %43 = xor i32 %1, %40
  %44 = sub i32 %42, %43
  %45 = sub i32 %44, %41
  %46 = mul i32 %45, 175
  %47 = icmp eq i32 %39, %46
  br i1 %47, label %246, label %427

48:                                               ; preds = %391
  %49 = load ptr, ptr %7, align 8
  %50 = getelementptr inbounds nuw %struct.SegmentList, ptr %49, i32 0, i32 1
  %51 = load i32, ptr %50, align 8
  %52 = icmp sgt i32 %51, 0
  %53 = select i1 %52, i32 1501762080, i32 842518965
  store i32 %53, ptr %6, align 4
  %54 = xor i32 %1, -1243908525
  %55 = and i32 %1, %54
  %56 = or i32 %1, %54
  %57 = xor i32 %1, %54
  %58 = add i32 %55, %56
  %59 = sub i32 %58, %1
  %60 = sub i32 %59, %54
  %61 = mul i32 %60, 174
  %62 = icmp sle i32 %61, 0
  br i1 %62, label %246, label %438

63:                                               ; preds = %373
  %64 = load ptr, ptr %7, align 8
  %65 = getelementptr inbounds nuw %struct.SegmentList, ptr %64, i32 0, i32 0
  %66 = load ptr, ptr %65, align 8
  %67 = load ptr, ptr %7, align 8
  %68 = getelementptr inbounds nuw %struct.SegmentList, ptr %67, i32 0, i32 1
  %69 = load i32, ptr %68, align 8
  %70 = load i32, ptr %6, align 4
  %71 = xor i32 %70, -1501762082
  %72 = add i32 %69, %71
  %73 = load i32, ptr %6, align 4
  %74 = xor i32 %73, 1501762081
  %75 = add i32 %72, %74
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds %struct.Segment, ptr %66, i64 %76
  store ptr %77, ptr %11, align 8
  %78 = load ptr, ptr %11, align 8
  %79 = getelementptr inbounds nuw %struct.Segment, ptr %78, i32 0, i32 0
  %80 = load i32, ptr %79, align 4
  %81 = load i32, ptr %8, align 4
  %82 = icmp eq i32 %80, %81
  %83 = select i1 %82, i32 1666242675, i32 -1916755561
  store i32 %83, ptr %6, align 4
  %84 = xor i32 %1, 1924218039
  %85 = and i32 %1, %84
  %86 = or i32 %1, %84
  %87 = xor i32 %1, %84
  %88 = sub i32 %86, %87
  %89 = sub i32 %88, %85
  %90 = mul i32 %89, 88
  %91 = icmp slt i32 %90, 0
  br i1 %91, label %449, label %246

92:                                               ; preds = %371
  %93 = load ptr, ptr %11, align 8
  %94 = getelementptr inbounds nuw %struct.Segment, ptr %93, i32 0, i32 2
  %95 = load i32, ptr %94, align 4
  %96 = load i32, ptr %9, align 4
  %97 = icmp eq i32 %95, %96
  %98 = select i1 %97, i32 1167614334, i32 -1916755561
  store i32 %98, ptr %6, align 4
  %99 = xor i32 %1, -1274200381
  %100 = and i32 %1, %99
  %101 = or i32 %1, %99
  %102 = xor i32 %1, %99
  %103 = add i32 %1, %99
  %104 = sub i32 %103, %102
  %105 = mul i32 %100, 2
  %106 = sub i32 %104, %105
  %107 = mul i32 %106, 114
  %108 = icmp eq i32 %107, 0
  br i1 %108, label %246, label %460

109:                                              ; preds = %407
  %110 = load i32, ptr %10, align 4
  %111 = load ptr, ptr %11, align 8
  %112 = getelementptr inbounds nuw %struct.Segment, ptr %111, i32 0, i32 2
  store i32 %110, ptr %112, align 4
  store i32 1711126762, ptr %6, align 4
  %113 = xor i32 %1, 1477288721
  %114 = and i32 %1, %113
  %115 = or i32 %1, %113
  %116 = xor i32 %1, %113
  %117 = add i32 %1, %113
  %118 = sub i32 %117, %116
  %119 = mul i32 %114, 2
  %120 = sub i32 %118, %119
  %121 = mul i32 %120, 114
  %122 = icmp sle i32 %121, 0
  br i1 %122, label %246, label %471

123:                                              ; preds = %401
  store i32 842518965, ptr %6, align 4
  %124 = xor i32 %1, 1297950363
  %125 = and i32 %1, %124
  %126 = or i32 %1, %124
  %127 = xor i32 %1, %124
  %128 = sub i32 %126, %127
  %129 = sub i32 %128, %125
  %130 = mul i32 %129, 187
  %131 = icmp ugt i32 %130, 0
  br i1 %131, label %482, label %246

132:                                              ; preds = %403
  %133 = load ptr, ptr %7, align 8
  %134 = getelementptr inbounds nuw %struct.SegmentList, ptr %133, i32 0, i32 1
  %135 = load i32, ptr %134, align 8
  %136 = load ptr, ptr %7, align 8
  %137 = getelementptr inbounds nuw %struct.SegmentList, ptr %136, i32 0, i32 2
  %138 = load i32, ptr %137, align 4
  %139 = icmp sge i32 %135, %138
  %140 = select i1 %139, i32 771680112, i32 -135980932
  store i32 %140, ptr %6, align 4
  %141 = xor i32 %1, -127359857
  %142 = and i32 %1, %141
  %143 = or i32 %1, %141
  %144 = xor i32 %1, %141
  %145 = add i32 %1, %141
  %146 = sub i32 %145, %144
  %147 = mul i32 %142, 2
  %148 = sub i32 %146, %147
  %149 = mul i32 %148, 170
  %150 = xor i32 %1, 794403615
  %151 = and i32 %1, %150
  %152 = or i32 %1, %150
  %153 = xor i32 %1, %150
  %154 = mul i32 %152, 2
  %155 = sub i32 %154, %153
  %156 = sub i32 %155, %1
  %157 = sub i32 %156, %150
  %158 = mul i32 %157, 78
  %159 = icmp eq i32 %149, %158
  br i1 %159, label %246, label %493

160:                                              ; preds = %397
  %161 = load ptr, ptr %7, align 8
  %162 = getelementptr inbounds nuw %struct.SegmentList, ptr %161, i32 0, i32 2
  %163 = load i32, ptr %162, align 4
  %164 = load i32, ptr %6, align 4
  %165 = xor i32 %164, 771680114
  %166 = mul nsw i32 %163, %165
  store i32 %166, ptr %162, align 4
  %167 = load ptr, ptr %7, align 8
  %168 = getelementptr inbounds nuw %struct.SegmentList, ptr %167, i32 0, i32 0
  %169 = load ptr, ptr %168, align 8
  %170 = load ptr, ptr %7, align 8
  %171 = getelementptr inbounds nuw %struct.SegmentList, ptr %170, i32 0, i32 2
  %172 = load i32, ptr %171, align 4
  %173 = sext i32 %172 to i64
  %174 = mul i64 12, %173
  %175 = call ptr @realloc(ptr noundef %169, i64 noundef %174) #7
  %176 = load ptr, ptr %7, align 8
  %177 = getelementptr inbounds nuw %struct.SegmentList, ptr %176, i32 0, i32 0
  store ptr %175, ptr %177, align 8
  store i32 -135980932, ptr %6, align 4
  %178 = xor i32 %1, -621783735
  %179 = and i32 %1, %178
  %180 = or i32 %1, %178
  %181 = xor i32 %1, %178
  %182 = add i32 %179, %180
  %183 = sub i32 %182, %1
  %184 = sub i32 %183, %178
  %185 = mul i32 %184, 121
  %186 = icmp eq i32 %185, 0
  br i1 %186, label %246, label %503

187:                                              ; preds = %385
  %188 = load i32, ptr %8, align 4
  %189 = load ptr, ptr %7, align 8
  %190 = getelementptr inbounds nuw %struct.SegmentList, ptr %189, i32 0, i32 0
  %191 = load ptr, ptr %190, align 8
  %192 = load ptr, ptr %7, align 8
  %193 = getelementptr inbounds nuw %struct.SegmentList, ptr %192, i32 0, i32 1
  %194 = load i32, ptr %193, align 8
  %195 = sext i32 %194 to i64
  %196 = getelementptr inbounds %struct.Segment, ptr %191, i64 %195
  %197 = getelementptr inbounds nuw %struct.Segment, ptr %196, i32 0, i32 0
  store i32 %188, ptr %197, align 4
  %198 = load i32, ptr %9, align 4
  %199 = load ptr, ptr %7, align 8
  %200 = getelementptr inbounds nuw %struct.SegmentList, ptr %199, i32 0, i32 0
  %201 = load ptr, ptr %200, align 8
  %202 = load ptr, ptr %7, align 8
  %203 = getelementptr inbounds nuw %struct.SegmentList, ptr %202, i32 0, i32 1
  %204 = load i32, ptr %203, align 8
  %205 = sext i32 %204 to i64
  %206 = getelementptr inbounds %struct.Segment, ptr %201, i64 %205
  %207 = getelementptr inbounds nuw %struct.Segment, ptr %206, i32 0, i32 1
  store i32 %198, ptr %207, align 4
  %208 = load i32, ptr %10, align 4
  %209 = load ptr, ptr %7, align 8
  %210 = getelementptr inbounds nuw %struct.SegmentList, ptr %209, i32 0, i32 0
  %211 = load ptr, ptr %210, align 8
  %212 = load ptr, ptr %7, align 8
  %213 = getelementptr inbounds nuw %struct.SegmentList, ptr %212, i32 0, i32 1
  %214 = load i32, ptr %213, align 8
  %215 = sext i32 %214 to i64
  %216 = getelementptr inbounds %struct.Segment, ptr %211, i64 %215
  %217 = getelementptr inbounds nuw %struct.Segment, ptr %216, i32 0, i32 2
  store i32 %208, ptr %217, align 4
  %218 = load ptr, ptr %7, align 8
  %219 = getelementptr inbounds nuw %struct.SegmentList, ptr %218, i32 0, i32 1
  %220 = load i32, ptr %219, align 8
  %221 = load i32, ptr %6, align 4
  %222 = xor i32 %221, -135980931
  %223 = or i32 %220, %222
  %224 = load i32, ptr %6, align 4
  %225 = xor i32 %224, -135980931
  %226 = and i32 %220, %225
  %227 = add i32 %223, %226
  store i32 %227, ptr %219, align 8
  store i32 1711126762, ptr %6, align 4
  %228 = xor i32 %1, 1211479809
  %229 = and i32 %1, %228
  %230 = or i32 %1, %228
  %231 = xor i32 %1, %228
  %232 = sub i32 %230, %231
  %233 = sub i32 %232, %229
  %234 = mul i32 %233, 10
  %235 = xor i32 %1, 2115874791
  %236 = and i32 %1, %235
  %237 = or i32 %1, %235
  %238 = xor i32 %1, %235
  %239 = add i32 %1, %235
  %240 = sub i32 %239, %238
  %241 = mul i32 %236, 2
  %242 = sub i32 %240, %241
  %243 = mul i32 %242, 149
  %244 = icmp eq i32 %234, %243
  br i1 %244, label %246, label %515

245:                                              ; preds = %381
  ret void

246:                                              ; preds = %606, %597, %588, %577, %566, %556, %547, %536, %515, %503, %493, %482, %471, %460, %449, %438, %427, %415, %346, %334, %323, %310, %297, %284, %271, %258, %187, %160, %132, %123, %109, %92, %63, %48, %32, %17
  br label %12

247:                                              ; preds = %413, %409, %407, %401, %397, %395, %385, %381, %379, %373, %371
  store i32 -975716143, ptr %6, align 4
  call void asm sideeffect "", ""()
  %248 = xor i32 %1, 1750333179
  %249 = and i32 %1, %248
  %250 = or i32 %1, %248
  %251 = xor i32 %1, %248
  %252 = add i32 %1, %248
  %253 = sub i32 %252, %251
  %254 = mul i32 %249, 2
  %255 = sub i32 %253, %254
  %256 = mul i32 %255, 126
  %257 = icmp slt i32 %256, 0
  br i1 %257, label %527, label %12

258:                                              ; preds = %395
  %259 = load i32, ptr %6, align 4
  %260 = xor i32 %259, 1356840227
  store i32 %260, ptr %6, align 4
  %261 = xor i32 %1, 119956451
  %262 = and i32 %1, %261
  %263 = or i32 %1, %261
  %264 = xor i32 %1, %261
  %265 = mul i32 %263, 2
  %266 = sub i32 %265, %264
  %267 = sub i32 %266, %1
  %268 = sub i32 %267, %261
  %269 = mul i32 %268, 100
  %270 = icmp sle i32 %269, 0
  br i1 %270, label %246, label %536

271:                                              ; preds = %399
  %272 = load i32, ptr %6, align 4
  %273 = xor i32 %272, 1330323466
  store i32 %273, ptr %6, align 4
  %274 = xor i32 %1, -117612133
  %275 = and i32 %1, %274
  %276 = or i32 %1, %274
  %277 = xor i32 %1, %274
  %278 = mul i32 %276, 2
  %279 = sub i32 %278, %277
  %280 = sub i32 %279, %1
  %281 = sub i32 %280, %274
  %282 = mul i32 %281, 225
  %283 = icmp slt i32 %282, 0
  br i1 %283, label %547, label %246

284:                                              ; preds = %409
  %285 = load i32, ptr %6, align 4
  %286 = xor i32 %285, 1465746178
  store i32 %286, ptr %6, align 4
  %287 = xor i32 %1, 170799367
  %288 = and i32 %1, %287
  %289 = or i32 %1, %287
  %290 = xor i32 %1, %287
  %291 = add i32 %1, %287
  %292 = sub i32 %291, %290
  %293 = mul i32 %288, 2
  %294 = sub i32 %292, %293
  %295 = mul i32 %294, 33
  %296 = icmp sle i32 %295, 0
  br i1 %296, label %246, label %556

297:                                              ; preds = %383
  %298 = load i32, ptr %6, align 4
  %299 = xor i32 %298, 881655966
  store i32 %299, ptr %6, align 4
  %300 = xor i32 %1, -534434341
  %301 = and i32 %1, %300
  %302 = or i32 %1, %300
  %303 = xor i32 %1, %300
  %304 = add i32 %1, %300
  %305 = sub i32 %304, %303
  %306 = mul i32 %301, 2
  %307 = sub i32 %305, %306
  %308 = mul i32 %307, 184
  %309 = icmp ne i32 %308, 0
  br i1 %309, label %566, label %246

310:                                              ; preds = %367
  %311 = load i32, ptr %6, align 4
  %312 = xor i32 %311, 814394253
  store i32 %312, ptr %6, align 4
  %313 = xor i32 %1, 64826991
  %314 = and i32 %1, %313
  %315 = or i32 %1, %313
  %316 = xor i32 %1, %313
  %317 = mul i32 %315, 2
  %318 = sub i32 %317, %316
  %319 = sub i32 %318, %1
  %320 = sub i32 %319, %313
  %321 = mul i32 %320, 24
  %322 = icmp ne i32 %321, 0
  br i1 %322, label %577, label %246

323:                                              ; preds = %375
  %324 = load i32, ptr %6, align 4
  %325 = xor i32 %324, 351985454
  store i32 %325, ptr %6, align 4
  %326 = xor i32 %1, 1808015479
  %327 = and i32 %1, %326
  %328 = or i32 %1, %326
  %329 = xor i32 %1, %326
  %330 = sub i32 %328, %329
  %331 = sub i32 %330, %327
  %332 = mul i32 %331, 33
  %333 = icmp slt i32 %332, 1
  br i1 %333, label %246, label %588

334:                                              ; preds = %413
  %335 = load i32, ptr %6, align 4
  %336 = xor i32 %335, 1341920249
  store i32 %336, ptr %6, align 4
  %337 = xor i32 %1, 278663985
  %338 = and i32 %1, %337
  %339 = or i32 %1, %337
  %340 = xor i32 %1, %337
  %341 = add i32 %338, %339
  %342 = sub i32 %341, %1
  %343 = sub i32 %342, %337
  %344 = mul i32 %343, 126
  %345 = icmp eq i32 %344, 0
  br i1 %345, label %246, label %597

346:                                              ; preds = %379
  %347 = load i32, ptr %6, align 4
  %348 = xor i32 %347, -960038623
  store i32 %348, ptr %6, align 4
  %349 = xor i32 %1, -442924341
  %350 = and i32 %1, %349
  %351 = or i32 %1, %349
  %352 = xor i32 %1, %349
  %353 = mul i32 %351, 2
  %354 = sub i32 %353, %352
  %355 = sub i32 %354, %1
  %356 = sub i32 %355, %349
  %357 = mul i32 %356, 9
  %358 = icmp ne i32 %357, 0
  br i1 %358, label %606, label %246

359:                                              ; preds = %12
  %360 = icmp slt i32 %15, 469398245
  br i1 %360, label %363, label %365

361:                                              ; preds = %12
  %362 = icmp slt i32 %15, 1547031496
  br i1 %362, label %387, label %389

363:                                              ; preds = %359
  %364 = icmp slt i32 %15, 180673332
  br i1 %364, label %367, label %369

365:                                              ; preds = %359
  %366 = icmp slt i32 %15, 649024441
  br i1 %366, label %375, label %377

367:                                              ; preds = %363
  %368 = icmp eq i32 %15, 8349486
  br i1 %368, label %310, label %371

369:                                              ; preds = %363
  %370 = icmp eq i32 %15, 180673332
  br i1 %370, label %17, label %373

371:                                              ; preds = %367
  %372 = icmp eq i32 %15, 11147502
  br i1 %372, label %92, label %247

373:                                              ; preds = %369
  %374 = icmp eq i32 %15, 222617335
  br i1 %374, label %63, label %247

375:                                              ; preds = %365
  %376 = icmp eq i32 %15, 469398245
  br i1 %376, label %323, label %379

377:                                              ; preds = %365
  %378 = icmp slt i32 %15, 912506734
  br i1 %378, label %381, label %383

379:                                              ; preds = %375
  %380 = icmp eq i32 %15, 632209053
  br i1 %380, label %346, label %247

381:                                              ; preds = %377
  %382 = icmp eq i32 %15, 649024441
  br i1 %382, label %245, label %247

383:                                              ; preds = %377
  %384 = icmp eq i32 %15, 912506734
  br i1 %384, label %297, label %385

385:                                              ; preds = %383
  %386 = icmp eq i32 %15, 1018963107
  br i1 %386, label %187, label %247

387:                                              ; preds = %361
  %388 = icmp slt i32 %15, 1150638087
  br i1 %388, label %391, label %393

389:                                              ; preds = %361
  %390 = icmp slt i32 %15, 1635880090
  br i1 %390, label %403, label %405

391:                                              ; preds = %387
  %392 = icmp eq i32 %15, 1034826819
  br i1 %392, label %48, label %395

393:                                              ; preds = %387
  %394 = icmp slt i32 %15, 1366121799
  br i1 %394, label %397, label %399

395:                                              ; preds = %391
  %396 = icmp eq i32 %15, 1094752731
  br i1 %396, label %258, label %247

397:                                              ; preds = %393
  %398 = icmp eq i32 %15, 1150638087
  br i1 %398, label %160, label %247

399:                                              ; preds = %393
  %400 = icmp eq i32 %15, 1366121799
  br i1 %400, label %271, label %401

401:                                              ; preds = %399
  %402 = icmp eq i32 %15, 1539161282
  br i1 %402, label %123, label %247

403:                                              ; preds = %389
  %404 = icmp eq i32 %15, 1547031496
  br i1 %404, label %132, label %407

405:                                              ; preds = %389
  %406 = icmp slt i32 %15, 1652340603
  br i1 %406, label %409, label %411

407:                                              ; preds = %403
  %408 = icmp eq i32 %15, 1591450685
  br i1 %408, label %109, label %247

409:                                              ; preds = %405
  %410 = icmp eq i32 %15, 1635880090
  br i1 %410, label %284, label %247

411:                                              ; preds = %405
  %412 = icmp eq i32 %15, 1652340603
  br i1 %412, label %32, label %413

413:                                              ; preds = %411
  %414 = icmp eq i32 %15, 1672318714
  br i1 %414, label %334, label %247

415:                                              ; preds = %17
  %416 = load i64, ptr %5, align 8
  %417 = ptrtoint ptr %0 to i64
  %418 = zext i32 %1 to i64
  %419 = zext i32 %2 to i64
  %420 = zext i32 %3 to i64
  %421 = add i64 %419, %418
  %422 = xor i64 %421, %416
  %423 = mul i64 %422, %417
  %424 = add i64 %423, %420
  %425 = add i64 %424, %419
  %426 = mul i64 %425, %419
  store i64 %426, ptr %5, align 8
  br label %246

427:                                              ; preds = %32
  %428 = load i64, ptr %5, align 8
  %429 = ptrtoint ptr %0 to i64
  %430 = zext i32 %1 to i64
  %431 = zext i32 %2 to i64
  %432 = zext i32 %3 to i64
  %433 = or i64 %432, %432
  %434 = and i64 %433, %430
  %435 = and i64 %434, %432
  %436 = xor i64 %435, %432
  %437 = and i64 %436, %431
  store i64 %437, ptr %5, align 8
  br label %246

438:                                              ; preds = %48
  %439 = load i64, ptr %5, align 8
  %440 = ptrtoint ptr %0 to i64
  %441 = zext i32 %1 to i64
  %442 = zext i32 %2 to i64
  %443 = zext i32 %3 to i64
  %444 = xor i64 %442, %441
  %445 = or i64 %444, %440
  %446 = add i64 %445, %441
  %447 = sub i64 %446, %439
  %448 = and i64 %447, %439
  store i64 %448, ptr %5, align 8
  br label %246

449:                                              ; preds = %63
  %450 = load i64, ptr %5, align 8
  %451 = ptrtoint ptr %0 to i64
  %452 = zext i32 %1 to i64
  %453 = zext i32 %2 to i64
  %454 = zext i32 %3 to i64
  %455 = xor i64 %450, %453
  %456 = or i64 %455, %451
  %457 = xor i64 %456, %454
  %458 = mul i64 %457, %452
  %459 = sub i64 %458, %452
  store i64 %459, ptr %5, align 8
  br label %246

460:                                              ; preds = %92
  %461 = load i64, ptr %5, align 8
  %462 = ptrtoint ptr %0 to i64
  %463 = zext i32 %1 to i64
  %464 = zext i32 %2 to i64
  %465 = zext i32 %3 to i64
  %466 = add i64 %462, %465
  %467 = or i64 %466, %465
  %468 = and i64 %467, %461
  %469 = and i64 %468, %461
  %470 = and i64 %469, %464
  store i64 %470, ptr %5, align 8
  br label %246

471:                                              ; preds = %109
  %472 = load i64, ptr %5, align 8
  %473 = ptrtoint ptr %0 to i64
  %474 = zext i32 %1 to i64
  %475 = zext i32 %2 to i64
  %476 = zext i32 %3 to i64
  %477 = mul i64 %472, %473
  %478 = mul i64 %477, %472
  %479 = mul i64 %478, %476
  %480 = and i64 %479, %474
  %481 = xor i64 %480, %472
  store i64 %481, ptr %5, align 8
  br label %246

482:                                              ; preds = %123
  %483 = load i64, ptr %5, align 8
  %484 = ptrtoint ptr %0 to i64
  %485 = zext i32 %1 to i64
  %486 = zext i32 %2 to i64
  %487 = zext i32 %3 to i64
  %488 = sub i64 %484, %483
  %489 = and i64 %488, %483
  %490 = sub i64 %489, %485
  %491 = sub i64 %490, %483
  %492 = or i64 %491, %485
  store i64 %492, ptr %5, align 8
  br label %246

493:                                              ; preds = %132
  %494 = load i64, ptr %5, align 8
  %495 = ptrtoint ptr %0 to i64
  %496 = zext i32 %1 to i64
  %497 = zext i32 %2 to i64
  %498 = zext i32 %3 to i64
  %499 = or i64 %494, %495
  %500 = sub i64 %499, %496
  %501 = mul i64 %500, %498
  %502 = or i64 %501, %494
  store i64 %502, ptr %5, align 8
  br label %246

503:                                              ; preds = %160
  %504 = load i64, ptr %5, align 8
  %505 = ptrtoint ptr %0 to i64
  %506 = zext i32 %1 to i64
  %507 = zext i32 %2 to i64
  %508 = zext i32 %3 to i64
  %509 = mul i64 %504, %505
  %510 = or i64 %509, %504
  %511 = mul i64 %510, %505
  %512 = or i64 %511, %504
  %513 = xor i64 %512, %507
  %514 = and i64 %513, %507
  store i64 %514, ptr %5, align 8
  br label %246

515:                                              ; preds = %187
  %516 = load i64, ptr %5, align 8
  %517 = ptrtoint ptr %0 to i64
  %518 = zext i32 %1 to i64
  %519 = zext i32 %2 to i64
  %520 = zext i32 %3 to i64
  %521 = xor i64 %519, %516
  %522 = mul i64 %521, %518
  %523 = and i64 %522, %518
  %524 = xor i64 %523, %518
  %525 = or i64 %524, %520
  %526 = sub i64 %525, %517
  store i64 %526, ptr %5, align 8
  br label %246

527:                                              ; preds = %247
  %528 = load i64, ptr %5, align 8
  %529 = ptrtoint ptr %0 to i64
  %530 = zext i32 %1 to i64
  %531 = zext i32 %2 to i64
  %532 = zext i32 %3 to i64
  %533 = or i64 %530, %529
  %534 = xor i64 %533, %529
  %535 = and i64 %534, %528
  store i64 %535, ptr %5, align 8
  br label %12

536:                                              ; preds = %258
  %537 = load i64, ptr %5, align 8
  %538 = ptrtoint ptr %0 to i64
  %539 = zext i32 %1 to i64
  %540 = zext i32 %2 to i64
  %541 = zext i32 %3 to i64
  %542 = add i64 %537, %538
  %543 = or i64 %542, %541
  %544 = or i64 %543, %539
  %545 = and i64 %544, %537
  %546 = and i64 %545, %538
  store i64 %546, ptr %5, align 8
  br label %246

547:                                              ; preds = %271
  %548 = load i64, ptr %5, align 8
  %549 = ptrtoint ptr %0 to i64
  %550 = zext i32 %1 to i64
  %551 = zext i32 %2 to i64
  %552 = zext i32 %3 to i64
  %553 = sub i64 %550, %548
  %554 = add i64 %553, %551
  %555 = or i64 %554, %550
  store i64 %555, ptr %5, align 8
  br label %246

556:                                              ; preds = %284
  %557 = load i64, ptr %5, align 8
  %558 = ptrtoint ptr %0 to i64
  %559 = zext i32 %1 to i64
  %560 = zext i32 %2 to i64
  %561 = zext i32 %3 to i64
  %562 = mul i64 %561, %557
  %563 = or i64 %562, %558
  %564 = add i64 %563, %560
  %565 = mul i64 %564, %558
  store i64 %565, ptr %5, align 8
  br label %246

566:                                              ; preds = %297
  %567 = load i64, ptr %5, align 8
  %568 = ptrtoint ptr %0 to i64
  %569 = zext i32 %1 to i64
  %570 = zext i32 %2 to i64
  %571 = zext i32 %3 to i64
  %572 = xor i64 %567, %571
  %573 = or i64 %572, %567
  %574 = sub i64 %573, %569
  %575 = mul i64 %574, %568
  %576 = or i64 %575, %570
  store i64 %576, ptr %5, align 8
  br label %246

577:                                              ; preds = %310
  %578 = load i64, ptr %5, align 8
  %579 = ptrtoint ptr %0 to i64
  %580 = zext i32 %1 to i64
  %581 = zext i32 %2 to i64
  %582 = zext i32 %3 to i64
  %583 = or i64 %580, %580
  %584 = xor i64 %583, %579
  %585 = add i64 %584, %580
  %586 = and i64 %585, %578
  %587 = and i64 %586, %581
  store i64 %587, ptr %5, align 8
  br label %246

588:                                              ; preds = %323
  %589 = load i64, ptr %5, align 8
  %590 = ptrtoint ptr %0 to i64
  %591 = zext i32 %1 to i64
  %592 = zext i32 %2 to i64
  %593 = zext i32 %3 to i64
  %594 = add i64 %592, %590
  %595 = or i64 %594, %591
  %596 = mul i64 %595, %592
  store i64 %596, ptr %5, align 8
  br label %246

597:                                              ; preds = %334
  %598 = load i64, ptr %5, align 8
  %599 = ptrtoint ptr %0 to i64
  %600 = zext i32 %1 to i64
  %601 = zext i32 %2 to i64
  %602 = zext i32 %3 to i64
  %603 = and i64 %600, %601
  %604 = or i64 %603, %600
  %605 = xor i64 %604, %599
  store i64 %605, ptr %5, align 8
  br label %246

606:                                              ; preds = %346
  %607 = load i64, ptr %5, align 8
  %608 = ptrtoint ptr %0 to i64
  %609 = zext i32 %1 to i64
  %610 = zext i32 %2 to i64
  %611 = zext i32 %3 to i64
  %612 = mul i64 %609, %609
  %613 = mul i64 %612, %609
  %614 = or i64 %613, %607
  %615 = mul i64 %614, %607
  %616 = xor i64 %615, %608
  %617 = sub i64 %616, %607
  store i64 %617, ptr %5, align 8
  br label %246
}

; Function Attrs: nounwind allocsize(1)
declare ptr @realloc(ptr noundef, i64 noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @generateProcesses(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store i32 1920907473, ptr %4, align 4
  br label %12

12:                                               ; preds = %325, %230, %229, %2
  %13 = load i32, ptr %4, align 4
  %14 = sub i32 %13, 1223701227
  %15 = mul i32 %14, 749467121
  switch i32 %15, label %230 [
    i32 2113088390, label %16
    i32 852539963, label %25
    i32 1615168452, label %47
    i32 2135713618, label %228
    i32 964651727, label %250
    i32 384447093, label %263
    i32 1034075228, label %276
    i32 679577690, label %289
  ]

16:                                               ; preds = %12
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 1740081622, ptr %4, align 4
  %17 = xor i32 %1, -2052544089
  %18 = and i32 %1, %17
  %19 = or i32 %1, %17
  %20 = xor i32 %1, %17
  %21 = sub i32 %19, %20
  %22 = sub i32 %21, %18
  %23 = mul i32 %22, 84
  %24 = icmp sgt i32 %23, 0
  br i1 %24, label %300, label %229

25:                                               ; preds = %12
  %26 = load i32, ptr %7, align 4
  %27 = load i32, ptr %6, align 4
  %28 = icmp slt i32 %26, %27
  %29 = select i1 %28, i32 -469459217, i32 -1752353443
  store i32 %29, ptr %4, align 4
  %30 = xor i32 %1, 1438237645
  %31 = and i32 %1, %30
  %32 = or i32 %1, %30
  %33 = xor i32 %1, %30
  %34 = add i32 %31, %32
  %35 = sub i32 %34, %1
  %36 = sub i32 %35, %30
  %37 = mul i32 %36, 124
  %38 = xor i32 %1, -1320348353
  %39 = and i32 %1, %38
  %40 = or i32 %1, %38
  %41 = xor i32 %1, %38
  %42 = add i32 %39, %40
  %43 = sub i32 %42, %1
  %44 = sub i32 %43, %38
  %45 = mul i32 %44, 52
  %46 = icmp ne i32 %37, %45
  br i1 %46, label %307, label %229

47:                                               ; preds = %12
  %48 = load i32, ptr %7, align 4
  %49 = load i32, ptr %7, align 4
  %50 = mul nsw i32 %48, %49
  %51 = load i32, ptr %7, align 4
  %52 = load i32, ptr %4, align 4
  %53 = xor i32 %52, -469459220
  %54 = mul nsw i32 %53, %51
  %55 = load i32, ptr %4, align 4
  %56 = xor i32 %55, -469459218
  %57 = add i32 %54, %56
  %58 = load i32, ptr %4, align 4
  %59 = xor i32 %58, -469459218
  %60 = sub i32 %50, %59
  %61 = mul i32 %50, %57
  %62 = mul i32 %54, %60
  %63 = sub i32 %61, %62
  %64 = load i32, ptr %6, align 4
  %65 = load i32, ptr %4, align 4
  %66 = xor i32 %65, -469459221
  %67 = or i32 %64, %66
  %68 = load i32, ptr %4, align 4
  %69 = xor i32 %68, -469459221
  %70 = and i32 %64, %69
  %71 = add i32 %67, %70
  %72 = srem i32 %63, %71
  store i32 %72, ptr %8, align 4
  %73 = load i32, ptr %7, align 4
  %74 = load i32, ptr %4, align 4
  %75 = xor i32 %74, -469459219
  %76 = xor i32 %73, %75
  %77 = load i32, ptr %4, align 4
  %78 = xor i32 %77, -469459219
  %79 = and i32 %73, %78
  %80 = add i32 %79, %79
  %81 = add i32 %76, %80
  %82 = load i32, ptr %4, align 4
  %83 = xor i32 %82, -469459224
  %84 = mul nsw i32 %81, %83
  %85 = srem i32 %84, 9
  %86 = load i32, ptr %4, align 4
  %87 = xor i32 %86, -469459219
  %88 = xor i32 %85, %87
  %89 = load i32, ptr %4, align 4
  %90 = xor i32 %89, -469459219
  %91 = and i32 %85, %90
  %92 = add i32 %91, %91
  %93 = add i32 %88, %92
  store i32 %93, ptr %9, align 4
  %94 = load i32, ptr %7, align 4
  %95 = load i32, ptr %4, align 4
  %96 = xor i32 %95, -469459220
  %97 = mul nsw i32 %94, %96
  %98 = load i32, ptr %6, align 4
  %99 = load i32, ptr %4, align 4
  %100 = xor i32 %99, -469459218
  %101 = add i32 %98, %100
  %102 = load i32, ptr %4, align 4
  %103 = xor i32 %102, -469459218
  %104 = sub i32 %97, %103
  %105 = mul i32 %97, %101
  %106 = mul i32 %98, %104
  %107 = sub i32 %105, %106
  %108 = srem i32 %107, 5
  %109 = load i32, ptr %4, align 4
  %110 = xor i32 %109, -469459218
  %111 = xor i32 %108, %110
  %112 = load i32, ptr %4, align 4
  %113 = xor i32 %112, -469459218
  %114 = and i32 %108, %113
  %115 = add i32 %114, %114
  %116 = add i32 %111, %115
  store i32 %116, ptr %10, align 4
  %117 = load i32, ptr %8, align 4
  %118 = load i32, ptr %9, align 4
  %119 = or i32 %117, %118
  %120 = and i32 %117, %118
  %121 = add i32 %119, %120
  %122 = load i32, ptr %7, align 4
  %123 = load i32, ptr %4, align 4
  %124 = xor i32 %123, -469459221
  %125 = mul nsw i32 %122, %124
  %126 = load i32, ptr %6, align 4
  %127 = load i32, ptr %4, align 4
  %128 = xor i32 %127, -469459218
  %129 = add i32 %126, %128
  %130 = load i32, ptr %4, align 4
  %131 = xor i32 %130, -469459218
  %132 = sub i32 %125, %131
  %133 = mul i32 %125, %129
  %134 = mul i32 %126, %132
  %135 = sub i32 %133, %134
  %136 = srem i32 %135, 7
  %137 = or i32 %121, %136
  %138 = and i32 %121, %136
  %139 = add i32 %137, %138
  %140 = load i32, ptr %4, align 4
  %141 = xor i32 %140, -469459218
  %142 = sub i32 %139, %141
  %143 = load i32, ptr %4, align 4
  %144 = xor i32 %143, -469459221
  %145 = mul i32 %139, %144
  %146 = load i32, ptr %4, align 4
  %147 = xor i32 %146, -469459220
  %148 = mul i32 %147, %142
  %149 = sub i32 %145, %148
  store i32 %149, ptr %11, align 4
  %150 = load i32, ptr %7, align 4
  %151 = load i32, ptr %4, align 4
  %152 = xor i32 %151, -469459218
  %153 = or i32 %150, %152
  %154 = load i32, ptr %4, align 4
  %155 = xor i32 %154, -469459218
  %156 = and i32 %150, %155
  %157 = add i32 %153, %156
  %158 = load ptr, ptr %5, align 8
  %159 = load i32, ptr %7, align 4
  %160 = sext i32 %159 to i64
  %161 = getelementptr inbounds %struct.Process, ptr %158, i64 %160
  %162 = getelementptr inbounds nuw %struct.Process, ptr %161, i32 0, i32 0
  store i32 %157, ptr %162, align 4
  %163 = load i32, ptr %8, align 4
  %164 = load ptr, ptr %5, align 8
  %165 = load i32, ptr %7, align 4
  %166 = sext i32 %165 to i64
  %167 = getelementptr inbounds %struct.Process, ptr %164, i64 %166
  %168 = getelementptr inbounds nuw %struct.Process, ptr %167, i32 0, i32 1
  store i32 %163, ptr %168, align 4
  %169 = load i32, ptr %9, align 4
  %170 = load ptr, ptr %5, align 8
  %171 = load i32, ptr %7, align 4
  %172 = sext i32 %171 to i64
  %173 = getelementptr inbounds %struct.Process, ptr %170, i64 %172
  %174 = getelementptr inbounds nuw %struct.Process, ptr %173, i32 0, i32 2
  store i32 %169, ptr %174, align 4
  %175 = load i32, ptr %9, align 4
  %176 = load ptr, ptr %5, align 8
  %177 = load i32, ptr %7, align 4
  %178 = sext i32 %177 to i64
  %179 = getelementptr inbounds %struct.Process, ptr %176, i64 %178
  %180 = getelementptr inbounds nuw %struct.Process, ptr %179, i32 0, i32 3
  store i32 %175, ptr %180, align 4
  %181 = load ptr, ptr %5, align 8
  %182 = load i32, ptr %7, align 4
  %183 = sext i32 %182 to i64
  %184 = getelementptr inbounds %struct.Process, ptr %181, i64 %183
  %185 = getelementptr inbounds nuw %struct.Process, ptr %184, i32 0, i32 4
  store i32 0, ptr %185, align 4
  %186 = load i32, ptr %10, align 4
  %187 = load ptr, ptr %5, align 8
  %188 = load i32, ptr %7, align 4
  %189 = sext i32 %188 to i64
  %190 = getelementptr inbounds %struct.Process, ptr %187, i64 %189
  %191 = getelementptr inbounds nuw %struct.Process, ptr %190, i32 0, i32 5
  store i32 %186, ptr %191, align 4
  %192 = load i32, ptr %11, align 4
  %193 = load ptr, ptr %5, align 8
  %194 = load i32, ptr %7, align 4
  %195 = sext i32 %194 to i64
  %196 = getelementptr inbounds %struct.Process, ptr %193, i64 %195
  %197 = getelementptr inbounds nuw %struct.Process, ptr %196, i32 0, i32 6
  store i32 %192, ptr %197, align 4
  %198 = load ptr, ptr %5, align 8
  %199 = load i32, ptr %7, align 4
  %200 = sext i32 %199 to i64
  %201 = getelementptr inbounds %struct.Process, ptr %198, i64 %200
  %202 = getelementptr inbounds nuw %struct.Process, ptr %201, i32 0, i32 7
  store i32 -1, ptr %202, align 4
  %203 = load ptr, ptr %5, align 8
  %204 = load i32, ptr %7, align 4
  %205 = sext i32 %204 to i64
  %206 = getelementptr inbounds %struct.Process, ptr %203, i64 %205
  %207 = getelementptr inbounds nuw %struct.Process, ptr %206, i32 0, i32 8
  store i32 -1, ptr %207, align 4
  %208 = load i32, ptr %7, align 4
  %209 = load i32, ptr %4, align 4
  %210 = xor i32 %209, -469459218
  %211 = sub i32 %208, %210
  %212 = load i32, ptr %4, align 4
  %213 = xor i32 %212, -469459219
  %214 = mul i32 %208, %213
  %215 = load i32, ptr %4, align 4
  %216 = xor i32 %215, -469459218
  %217 = mul i32 %216, %211
  %218 = sub i32 %214, %217
  store i32 %218, ptr %7, align 4
  store i32 1740081622, ptr %4, align 4
  %219 = xor i32 %1, -486317455
  %220 = and i32 %1, %219
  %221 = or i32 %1, %219
  %222 = xor i32 %1, %219
  %223 = add i32 %220, %221
  %224 = sub i32 %223, %1
  %225 = sub i32 %224, %219
  %226 = mul i32 %225, 244
  %227 = icmp eq i32 %226, 0
  br i1 %227, label %229, label %317

228:                                              ; preds = %12
  ret void

229:                                              ; preds = %360, %351, %342, %334, %317, %307, %300, %289, %276, %263, %250, %47, %25, %16
  br label %12

230:                                              ; preds = %12
  store i32 1920907473, ptr %4, align 4
  call void asm sideeffect "", ""()
  %231 = xor i32 %1, 1561031969
  %232 = and i32 %1, %231
  %233 = or i32 %1, %231
  %234 = xor i32 %1, %231
  %235 = mul i32 %233, 2
  %236 = sub i32 %235, %234
  %237 = sub i32 %236, %1
  %238 = sub i32 %237, %231
  %239 = mul i32 %238, 53
  %240 = xor i32 %1, -18977049
  %241 = and i32 %1, %240
  %242 = or i32 %1, %240
  %243 = xor i32 %1, %240
  %244 = add i32 %1, %240
  %245 = sub i32 %244, %243
  %246 = mul i32 %241, 2
  %247 = sub i32 %245, %246
  %248 = mul i32 %247, 171
  %249 = icmp ne i32 %239, %248
  br i1 %249, label %325, label %12

250:                                              ; preds = %12
  %251 = load i32, ptr %4, align 4
  %252 = xor i32 %251, -710970136
  store i32 %252, ptr %4, align 4
  %253 = xor i32 %1, 1140087759
  %254 = and i32 %1, %253
  %255 = or i32 %1, %253
  %256 = xor i32 %1, %253
  %257 = add i32 %1, %253
  %258 = sub i32 %257, %256
  %259 = mul i32 %254, 2
  %260 = sub i32 %258, %259
  %261 = mul i32 %260, 219
  %262 = icmp slt i32 %261, 0
  br i1 %262, label %334, label %229

263:                                              ; preds = %12
  %264 = load i32, ptr %4, align 4
  %265 = xor i32 %264, 1658943937
  store i32 %265, ptr %4, align 4
  %266 = xor i32 %1, -2113215999
  %267 = and i32 %1, %266
  %268 = or i32 %1, %266
  %269 = xor i32 %1, %266
  %270 = add i32 %1, %266
  %271 = sub i32 %270, %269
  %272 = mul i32 %267, 2
  %273 = sub i32 %271, %272
  %274 = mul i32 %273, 12
  %275 = icmp sgt i32 %274, 0
  br i1 %275, label %342, label %229

276:                                              ; preds = %12
  %277 = load i32, ptr %4, align 4
  %278 = xor i32 %277, 335244546
  store i32 %278, ptr %4, align 4
  %279 = xor i32 %1, -388146869
  %280 = and i32 %1, %279
  %281 = or i32 %1, %279
  %282 = xor i32 %1, %279
  %283 = mul i32 %281, 2
  %284 = sub i32 %283, %282
  %285 = sub i32 %284, %1
  %286 = sub i32 %285, %279
  %287 = mul i32 %286, 122
  %288 = icmp sle i32 %287, 0
  br i1 %288, label %229, label %351

289:                                              ; preds = %12
  %290 = load i32, ptr %4, align 4
  %291 = xor i32 %290, -771829224
  store i32 %291, ptr %4, align 4
  %292 = xor i32 %1, -568246481
  %293 = and i32 %1, %292
  %294 = or i32 %1, %292
  %295 = xor i32 %1, %292
  %296 = sub i32 %294, %295
  %297 = sub i32 %296, %293
  %298 = mul i32 %297, 112
  %299 = icmp eq i32 %298, 0
  br i1 %299, label %229, label %360

300:                                              ; preds = %16
  %301 = load i64, ptr %3, align 8
  %302 = ptrtoint ptr %0 to i64
  %303 = zext i32 %1 to i64
  %304 = sub i64 %303, %301
  %305 = xor i64 %304, %301
  %306 = sub i64 %305, %303
  store i64 %306, ptr %3, align 8
  br label %229

307:                                              ; preds = %25
  %308 = load i64, ptr %3, align 8
  %309 = ptrtoint ptr %0 to i64
  %310 = zext i32 %1 to i64
  %311 = sub i64 %308, %309
  %312 = or i64 %311, %309
  %313 = and i64 %312, %308
  %314 = or i64 %313, %310
  %315 = and i64 %314, %310
  %316 = or i64 %315, %308
  store i64 %316, ptr %3, align 8
  br label %229

317:                                              ; preds = %47
  %318 = load i64, ptr %3, align 8
  %319 = ptrtoint ptr %0 to i64
  %320 = zext i32 %1 to i64
  %321 = and i64 %319, %320
  %322 = mul i64 %321, %318
  %323 = sub i64 %322, %320
  %324 = and i64 %323, %319
  store i64 %324, ptr %3, align 8
  br label %229

325:                                              ; preds = %230
  %326 = load i64, ptr %3, align 8
  %327 = ptrtoint ptr %0 to i64
  %328 = zext i32 %1 to i64
  %329 = xor i64 %326, %328
  %330 = mul i64 %329, %326
  %331 = mul i64 %330, %327
  %332 = mul i64 %331, %326
  %333 = add i64 %332, %328
  store i64 %333, ptr %3, align 8
  br label %12

334:                                              ; preds = %250
  %335 = load i64, ptr %3, align 8
  %336 = ptrtoint ptr %0 to i64
  %337 = zext i32 %1 to i64
  %338 = sub i64 %337, %337
  %339 = xor i64 %338, %337
  %340 = xor i64 %339, %336
  %341 = and i64 %340, %337
  store i64 %341, ptr %3, align 8
  br label %229

342:                                              ; preds = %263
  %343 = load i64, ptr %3, align 8
  %344 = ptrtoint ptr %0 to i64
  %345 = zext i32 %1 to i64
  %346 = add i64 %343, %345
  %347 = mul i64 %346, %344
  %348 = and i64 %347, %345
  %349 = or i64 %348, %343
  %350 = sub i64 %349, %345
  store i64 %350, ptr %3, align 8
  br label %229

351:                                              ; preds = %276
  %352 = load i64, ptr %3, align 8
  %353 = ptrtoint ptr %0 to i64
  %354 = zext i32 %1 to i64
  %355 = or i64 %354, %354
  %356 = sub i64 %355, %354
  %357 = add i64 %356, %352
  %358 = add i64 %357, %353
  %359 = sub i64 %358, %352
  store i64 %359, ptr %3, align 8
  br label %229

360:                                              ; preds = %289
  %361 = load i64, ptr %3, align 8
  %362 = ptrtoint ptr %0 to i64
  %363 = zext i32 %1 to i64
  %364 = xor i64 %361, %362
  %365 = mul i64 %364, %361
  %366 = sub i64 %365, %363
  %367 = add i64 %366, %362
  %368 = add i64 %367, %361
  %369 = add i64 %368, %362
  store i64 %369, ptr %3, align 8
  br label %229
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @effectivePriority(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 -345624370, ptr %4, align 4
  br label %9

9:                                                ; preds = %162, %72, %71, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, -1258302407
  %12 = mul i32 %11, 535399001
  switch i32 %12, label %72 [
    i32 1713078733, label %13
    i32 2047010618, label %60
    i32 1986965878, label %69
    i32 1507908301, label %83
    i32 620630086, label %104
    i32 880215197, label %124
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %14 = load i32, ptr %6, align 4
  %15 = load ptr, ptr %5, align 8
  %16 = getelementptr inbounds nuw %struct.Process, ptr %15, i32 0, i32 1
  %17 = load i32, ptr %16, align 4
  %18 = xor i32 %14, %17
  %19 = load i32, ptr %4, align 4
  %20 = xor i32 %19, 345624369
  %21 = xor i32 %14, %20
  %22 = and i32 %21, %17
  %23 = add i32 %22, %22
  %24 = sub i32 %18, %23
  %25 = load ptr, ptr %5, align 8
  %26 = getelementptr inbounds nuw %struct.Process, ptr %25, i32 0, i32 4
  %27 = load i32, ptr %26, align 4
  %28 = xor i32 %24, %27
  %29 = load i32, ptr %4, align 4
  %30 = xor i32 %29, 345624369
  %31 = xor i32 %24, %30
  %32 = and i32 %31, %27
  %33 = add i32 %32, %32
  %34 = sub i32 %28, %33
  store i32 %34, ptr %7, align 4
  %35 = load ptr, ptr %5, align 8
  %36 = getelementptr inbounds nuw %struct.Process, ptr %35, i32 0, i32 5
  %37 = load i32, ptr %36, align 4
  %38 = load i32, ptr %7, align 4
  %39 = sdiv i32 %38, 4
  %40 = load i32, ptr %4, align 4
  %41 = xor i32 %40, 345624369
  %42 = xor i32 %39, %41
  %43 = add i32 %37, %42
  %44 = load i32, ptr %4, align 4
  %45 = xor i32 %44, -345624369
  %46 = add i32 %43, %45
  store i32 %46, ptr %8, align 4
  %47 = load i32, ptr %8, align 4
  %48 = icmp slt i32 %47, 0
  %49 = select i1 %48, i32 -1069032957, i32 -598231393
  store i32 %49, ptr %4, align 4
  %50 = xor i32 %1, 976191325
  %51 = and i32 %1, %50
  %52 = or i32 %1, %50
  %53 = xor i32 %1, %50
  %54 = add i32 %1, %50
  %55 = sub i32 %54, %53
  %56 = mul i32 %51, 2
  %57 = sub i32 %55, %56
  %58 = mul i32 %57, 200
  %59 = icmp ne i32 %58, 0
  br i1 %59, label %145, label %71

60:                                               ; preds = %9
  store i32 0, ptr %8, align 4
  store i32 -598231393, ptr %4, align 4
  %61 = xor i32 %1, 1695864553
  %62 = and i32 %1, %61
  %63 = or i32 %1, %61
  %64 = xor i32 %1, %61
  %65 = sub i32 %63, %64
  %66 = sub i32 %65, %62
  %67 = mul i32 %66, 198
  %68 = icmp ugt i32 %67, 0
  br i1 %68, label %155, label %71

69:                                               ; preds = %9
  %70 = load i32, ptr %8, align 4
  ret i32 %70

71:                                               ; preds = %189, %179, %170, %155, %145, %124, %104, %83, %60, %13
  br label %9

72:                                               ; preds = %9
  store i32 -345624370, ptr %4, align 4
  call void asm sideeffect "", ""()
  %73 = xor i32 %1, 1996229737
  %74 = and i32 %1, %73
  %75 = or i32 %1, %73
  %76 = xor i32 %1, %73
  %77 = add i32 %1, %73
  %78 = sub i32 %77, %76
  %79 = mul i32 %74, 2
  %80 = sub i32 %78, %79
  %81 = mul i32 %80, 176
  %82 = icmp uge i32 %81, 0
  br i1 %82, label %9, label %162

83:                                               ; preds = %9
  %84 = load i32, ptr %4, align 4
  %85 = xor i32 %84, -624463481
  store i32 %85, ptr %4, align 4
  %86 = xor i32 %1, 1027858085
  %87 = and i32 %1, %86
  %88 = or i32 %1, %86
  %89 = xor i32 %1, %86
  %90 = add i32 %87, %88
  %91 = sub i32 %90, %1
  %92 = sub i32 %91, %86
  %93 = mul i32 %92, 162
  %94 = xor i32 %1, 1381226127
  %95 = and i32 %1, %94
  %96 = or i32 %1, %94
  %97 = xor i32 %1, %94
  %98 = add i32 %1, %94
  %99 = sub i32 %98, %97
  %100 = mul i32 %95, 2
  %101 = sub i32 %99, %100
  %102 = mul i32 %101, 38
  %103 = icmp ne i32 %93, %102
  br i1 %103, label %170, label %71

104:                                              ; preds = %9
  %105 = load i32, ptr %4, align 4
  %106 = xor i32 %105, 56541563
  store i32 %106, ptr %4, align 4
  %107 = xor i32 %1, -732385261
  %108 = and i32 %1, %107
  %109 = or i32 %1, %107
  %110 = xor i32 %1, %107
  %111 = sub i32 %109, %110
  %112 = sub i32 %111, %108
  %113 = mul i32 %112, 246
  %114 = xor i32 %1, 1392823893
  %115 = and i32 %1, %114
  %116 = or i32 %1, %114
  %117 = xor i32 %1, %114
  %118 = mul i32 %116, 2
  %119 = sub i32 %118, %117
  %120 = sub i32 %119, %1
  %121 = sub i32 %120, %114
  %122 = mul i32 %121, 39
  %123 = icmp eq i32 %113, %122
  br i1 %123, label %71, label %179

124:                                              ; preds = %9
  %125 = load i32, ptr %4, align 4
  %126 = xor i32 %125, -573648849
  store i32 %126, ptr %4, align 4
  %127 = xor i32 %1, 439683909
  %128 = and i32 %1, %127
  %129 = or i32 %1, %127
  %130 = xor i32 %1, %127
  %131 = add i32 %128, %129
  %132 = sub i32 %131, %1
  %133 = sub i32 %132, %127
  %134 = mul i32 %133, 64
  %135 = xor i32 %1, 982363493
  %136 = and i32 %1, %135
  %137 = or i32 %1, %135
  %138 = xor i32 %1, %135
  %139 = add i32 %1, %135
  %140 = sub i32 %139, %138
  %141 = mul i32 %136, 2
  %142 = sub i32 %140, %141
  %143 = mul i32 %142, 103
  %144 = icmp eq i32 %134, %143
  br i1 %144, label %71, label %189

145:                                              ; preds = %13
  %146 = load i64, ptr %3, align 8
  %147 = ptrtoint ptr %0 to i64
  %148 = zext i32 %1 to i64
  %149 = sub i64 %148, %147
  %150 = or i64 %149, %146
  %151 = sub i64 %150, %146
  %152 = sub i64 %151, %148
  %153 = sub i64 %152, %148
  %154 = add i64 %153, %146
  store i64 %154, ptr %3, align 8
  br label %71

155:                                              ; preds = %60
  %156 = load i64, ptr %3, align 8
  %157 = ptrtoint ptr %0 to i64
  %158 = zext i32 %1 to i64
  %159 = or i64 %157, %157
  %160 = mul i64 %159, %158
  %161 = add i64 %160, %156
  store i64 %161, ptr %3, align 8
  br label %71

162:                                              ; preds = %72
  %163 = load i64, ptr %3, align 8
  %164 = ptrtoint ptr %0 to i64
  %165 = zext i32 %1 to i64
  %166 = mul i64 %165, %164
  %167 = or i64 %166, %163
  %168 = xor i64 %167, %165
  %169 = sub i64 %168, %165
  store i64 %169, ptr %3, align 8
  br label %9

170:                                              ; preds = %83
  %171 = load i64, ptr %3, align 8
  %172 = ptrtoint ptr %0 to i64
  %173 = zext i32 %1 to i64
  %174 = xor i64 %172, %172
  %175 = sub i64 %174, %171
  %176 = mul i64 %175, %171
  %177 = or i64 %176, %173
  %178 = or i64 %177, %173
  store i64 %178, ptr %3, align 8
  br label %71

179:                                              ; preds = %104
  %180 = load i64, ptr %3, align 8
  %181 = ptrtoint ptr %0 to i64
  %182 = zext i32 %1 to i64
  %183 = and i64 %182, %180
  %184 = add i64 %183, %182
  %185 = or i64 %184, %182
  %186 = sub i64 %185, %180
  %187 = mul i64 %186, %182
  %188 = mul i64 %187, %182
  store i64 %188, ptr %3, align 8
  br label %71

189:                                              ; preds = %124
  %190 = load i64, ptr %3, align 8
  %191 = ptrtoint ptr %0 to i64
  %192 = zext i32 %1 to i64
  %193 = or i64 %192, %190
  %194 = xor i64 %193, %192
  %195 = sub i64 %194, %190
  store i64 %195, ptr %3, align 8
  br label %71
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @slackTime(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load ptr, ptr %3, align 8
  %6 = getelementptr inbounds nuw %struct.Process, ptr %5, i32 0, i32 6
  %7 = load i32, ptr %6, align 4
  %8 = load i32, ptr %4, align 4
  %9 = xor i32 %8, -1
  %10 = add i32 %7, %9
  %11 = add i32 %10, 1
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.Process, ptr %12, i32 0, i32 3
  %14 = load i32, ptr %13, align 4
  %15 = xor i32 %14, -1
  %16 = add i32 %11, %15
  %17 = add i32 %16, 1
  ret i32 %17
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @isBetter(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store i32 -431580646, ptr %5, align 4
  br label %14

14:                                               ; preds = %387, %184, %183, %3
  %15 = load i32, ptr %5, align 4
  %16 = sub i32 %15, -1904252200
  %17 = mul i32 %16, -1884493261
  switch i32 %17, label %184 [
    i32 741916198, label %18
    i32 1196952727, label %39
    i32 1086602914, label %52
    i32 215166478, label %72
    i32 776068018, label %86
    i32 61453849, label %103
    i32 688144909, label %130
    i32 1211059785, label %147
    i32 1158351789, label %164
    i32 289810834, label %181
    i32 1663849199, label %195
    i32 548519925, label %208
    i32 691568107, label %221
    i32 418675494, label %243
    i32 1450945131, label %255
    i32 1317287461, label %266
    i32 711320916, label %279
    i32 9886094, label %292
  ]

18:                                               ; preds = %14
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  store i32 %2, ptr %9, align 4
  %19 = load ptr, ptr %7, align 8
  %20 = load i32, ptr %9, align 4
  %21 = call i32 @effectivePriority(ptr noundef %19, i32 noundef %20)
  store i32 %21, ptr %10, align 4
  %22 = load ptr, ptr %8, align 8
  %23 = load i32, ptr %9, align 4
  %24 = call i32 @effectivePriority(ptr noundef %22, i32 noundef %23)
  store i32 %24, ptr %11, align 4
  %25 = load i32, ptr %10, align 4
  %26 = load i32, ptr %11, align 4
  %27 = icmp ne i32 %25, %26
  %28 = select i1 %27, i32 -1177115931, i32 -1763896402
  store i32 %28, ptr %5, align 4
  %29 = xor i32 %2, 326478381
  %30 = and i32 %2, %29
  %31 = or i32 %2, %29
  %32 = xor i32 %2, %29
  %33 = mul i32 %31, 2
  %34 = sub i32 %33, %32
  %35 = sub i32 %34, %2
  %36 = sub i32 %35, %29
  %37 = mul i32 %36, 193
  %38 = icmp sle i32 %37, 0
  br i1 %38, label %183, label %304

39:                                               ; preds = %14
  %40 = load i32, ptr %10, align 4
  %41 = load i32, ptr %11, align 4
  %42 = icmp slt i32 %40, %41
  %43 = zext i1 %42 to i32
  store i32 %43, ptr %6, align 4
  store i32 1117547774, ptr %5, align 4
  %44 = xor i32 %2, 1177145087
  %45 = and i32 %2, %44
  %46 = or i32 %2, %44
  %47 = xor i32 %2, %44
  %48 = sub i32 %46, %47
  %49 = sub i32 %48, %45
  %50 = mul i32 %49, 177
  %51 = icmp ugt i32 %50, 0
  br i1 %51, label %312, label %183

52:                                               ; preds = %14
  %53 = load ptr, ptr %7, align 8
  %54 = load i32, ptr %9, align 4
  %55 = call i32 @slackTime(ptr noundef %53, i32 noundef %54)
  store i32 %55, ptr %12, align 4
  %56 = load ptr, ptr %8, align 8
  %57 = load i32, ptr %9, align 4
  %58 = call i32 @slackTime(ptr noundef %56, i32 noundef %57)
  store i32 %58, ptr %13, align 4
  %59 = load i32, ptr %12, align 4
  %60 = load i32, ptr %13, align 4
  %61 = icmp ne i32 %59, %60
  %62 = select i1 %61, i32 -500215150, i32 -1515711906
  store i32 %62, ptr %5, align 4
  %63 = xor i32 %2, -1985814227
  %64 = and i32 %2, %63
  %65 = or i32 %2, %63
  %66 = xor i32 %2, %63
  %67 = add i32 %64, %65
  %68 = sub i32 %67, %2
  %69 = sub i32 %68, %63
  %70 = mul i32 %69, 20
  %71 = icmp slt i32 %70, 0
  br i1 %71, label %320, label %183

72:                                               ; preds = %14
  %73 = load i32, ptr %12, align 4
  %74 = load i32, ptr %13, align 4
  %75 = icmp slt i32 %73, %74
  %76 = zext i1 %75 to i32
  store i32 %76, ptr %6, align 4
  store i32 1117547774, ptr %5, align 4
  %77 = xor i32 %2, 820354109
  %78 = and i32 %2, %77
  %79 = or i32 %2, %77
  %80 = xor i32 %2, %77
  %81 = add i32 %78, %79
  %82 = sub i32 %81, %2
  %83 = sub i32 %82, %77
  %84 = mul i32 %83, 66
  %85 = icmp slt i32 %84, 0
  br i1 %85, label %329, label %183

86:                                               ; preds = %14
  %87 = load ptr, ptr %7, align 8
  %88 = getelementptr inbounds nuw %struct.Process, ptr %87, i32 0, i32 3
  %89 = load i32, ptr %88, align 4
  %90 = load ptr, ptr %8, align 8
  %91 = getelementptr inbounds nuw %struct.Process, ptr %90, i32 0, i32 3
  %92 = load i32, ptr %91, align 4
  %93 = icmp ne i32 %89, %92
  %94 = select i1 %93, i32 -516418213, i32 1304284567
  store i32 %94, ptr %5, align 4
  %95 = xor i32 %2, -1071294345
  %96 = and i32 %2, %95
  %97 = or i32 %2, %95
  %98 = xor i32 %2, %95
  %99 = sub i32 %97, %98
  %100 = sub i32 %99, %96
  %101 = mul i32 %100, 174
  %102 = icmp sgt i32 %101, 0
  br i1 %102, label %337, label %183

103:                                              ; preds = %14
  %104 = load ptr, ptr %7, align 8
  %105 = getelementptr inbounds nuw %struct.Process, ptr %104, i32 0, i32 3
  %106 = load i32, ptr %105, align 4
  %107 = load ptr, ptr %8, align 8
  %108 = getelementptr inbounds nuw %struct.Process, ptr %107, i32 0, i32 3
  %109 = load i32, ptr %108, align 4
  %110 = icmp slt i32 %106, %109
  %111 = zext i1 %110 to i32
  store i32 %111, ptr %6, align 4
  store i32 1117547774, ptr %5, align 4
  %112 = xor i32 %2, -1203624051
  %113 = and i32 %2, %112
  %114 = or i32 %2, %112
  %115 = xor i32 %2, %112
  %116 = add i32 %113, %114
  %117 = sub i32 %116, %2
  %118 = sub i32 %117, %112
  %119 = mul i32 %118, 79
  %120 = xor i32 %2, 1146468539
  %121 = and i32 %2, %120
  %122 = or i32 %2, %120
  %123 = xor i32 %2, %120
  %124 = mul i32 %122, 2
  %125 = sub i32 %124, %123
  %126 = sub i32 %125, %2
  %127 = sub i32 %126, %120
  %128 = mul i32 %127, 7
  %129 = icmp ne i32 %119, %128
  br i1 %129, label %348, label %183

130:                                              ; preds = %14
  %131 = load ptr, ptr %7, align 8
  %132 = getelementptr inbounds nuw %struct.Process, ptr %131, i32 0, i32 1
  %133 = load i32, ptr %132, align 4
  %134 = load ptr, ptr %8, align 8
  %135 = getelementptr inbounds nuw %struct.Process, ptr %134, i32 0, i32 1
  %136 = load i32, ptr %135, align 4
  %137 = icmp ne i32 %133, %136
  %138 = select i1 %137, i32 1446661227, i32 463043959
  store i32 %138, ptr %5, align 4
  %139 = xor i32 %2, -1446788601
  %140 = and i32 %2, %139
  %141 = or i32 %2, %139
  %142 = xor i32 %2, %139
  %143 = sub i32 %141, %142
  %144 = sub i32 %143, %140
  %145 = mul i32 %144, 78
  %146 = icmp ne i32 %145, 0
  br i1 %146, label %357, label %183

147:                                              ; preds = %14
  %148 = load ptr, ptr %7, align 8
  %149 = getelementptr inbounds nuw %struct.Process, ptr %148, i32 0, i32 1
  %150 = load i32, ptr %149, align 4
  %151 = load ptr, ptr %8, align 8
  %152 = getelementptr inbounds nuw %struct.Process, ptr %151, i32 0, i32 1
  %153 = load i32, ptr %152, align 4
  %154 = icmp slt i32 %150, %153
  %155 = zext i1 %154 to i32
  store i32 %155, ptr %6, align 4
  store i32 1117547774, ptr %5, align 4
  %156 = xor i32 %2, 2098975419
  %157 = and i32 %2, %156
  %158 = or i32 %2, %156
  %159 = xor i32 %2, %156
  %160 = sub i32 %158, %159
  %161 = sub i32 %160, %157
  %162 = mul i32 %161, 55
  %163 = icmp slt i32 %162, 0
  br i1 %163, label %368, label %183

164:                                              ; preds = %14
  %165 = load ptr, ptr %7, align 8
  %166 = getelementptr inbounds nuw %struct.Process, ptr %165, i32 0, i32 0
  %167 = load i32, ptr %166, align 4
  %168 = load ptr, ptr %8, align 8
  %169 = getelementptr inbounds nuw %struct.Process, ptr %168, i32 0, i32 0
  %170 = load i32, ptr %169, align 4
  %171 = icmp slt i32 %167, %170
  %172 = zext i1 %171 to i32
  store i32 %172, ptr %6, align 4
  store i32 1117547774, ptr %5, align 4
  %173 = xor i32 %2, -1262367563
  %174 = and i32 %2, %173
  %175 = or i32 %2, %173
  %176 = xor i32 %2, %173
  %177 = sub i32 %175, %176
  %178 = sub i32 %177, %174
  %179 = mul i32 %178, 200
  %180 = icmp slt i32 %179, 0
  br i1 %180, label %377, label %183

181:                                              ; preds = %14
  %182 = load i32, ptr %6, align 4
  ret i32 %182

183:                                              ; preds = %466, %457, %447, %437, %426, %415, %406, %397, %377, %368, %357, %348, %337, %329, %320, %312, %304, %292, %279, %266, %255, %243, %221, %208, %195, %164, %147, %130, %103, %86, %72, %52, %39, %18
  br label %14

184:                                              ; preds = %14
  store i32 -431580646, ptr %5, align 4
  call void asm sideeffect "", ""()
  %185 = xor i32 %2, -2117493405
  %186 = and i32 %2, %185
  %187 = or i32 %2, %185
  %188 = xor i32 %2, %185
  %189 = mul i32 %187, 2
  %190 = sub i32 %189, %188
  %191 = sub i32 %190, %2
  %192 = sub i32 %191, %185
  %193 = mul i32 %192, 203
  %194 = icmp ne i32 %193, 0
  br i1 %194, label %387, label %14

195:                                              ; preds = %14
  %196 = load i32, ptr %5, align 4
  %197 = xor i32 %196, 412491866
  store i32 %197, ptr %5, align 4
  %198 = xor i32 %2, -1360470705
  %199 = and i32 %2, %198
  %200 = or i32 %2, %198
  %201 = xor i32 %2, %198
  %202 = add i32 %2, %198
  %203 = sub i32 %202, %201
  %204 = mul i32 %199, 2
  %205 = sub i32 %203, %204
  %206 = mul i32 %205, 254
  %207 = icmp sgt i32 %206, 0
  br i1 %207, label %397, label %183

208:                                              ; preds = %14
  %209 = load i32, ptr %5, align 4
  %210 = xor i32 %209, -478590151
  store i32 %210, ptr %5, align 4
  %211 = xor i32 %2, 332898821
  %212 = and i32 %2, %211
  %213 = or i32 %2, %211
  %214 = xor i32 %2, %211
  %215 = add i32 %2, %211
  %216 = sub i32 %215, %214
  %217 = mul i32 %212, 2
  %218 = sub i32 %216, %217
  %219 = mul i32 %218, 147
  %220 = icmp sle i32 %219, 0
  br i1 %220, label %183, label %406

221:                                              ; preds = %14
  %222 = load i32, ptr %5, align 4
  %223 = xor i32 %222, -1771172406
  store i32 %223, ptr %5, align 4
  %224 = xor i32 %2, -584902647
  %225 = and i32 %2, %224
  %226 = or i32 %2, %224
  %227 = xor i32 %2, %224
  %228 = add i32 %2, %224
  %229 = sub i32 %228, %227
  %230 = mul i32 %225, 2
  %231 = sub i32 %229, %230
  %232 = mul i32 %231, 151
  %233 = xor i32 %2, 1699094235
  %234 = and i32 %2, %233
  %235 = or i32 %2, %233
  %236 = xor i32 %2, %233
  %237 = mul i32 %235, 2
  %238 = sub i32 %237, %236
  %239 = sub i32 %238, %2
  %240 = sub i32 %239, %233
  %241 = mul i32 %240, 192
  %242 = icmp ne i32 %232, %241
  br i1 %242, label %415, label %183

243:                                              ; preds = %14
  %244 = load i32, ptr %5, align 4
  %245 = xor i32 %244, -1149633661
  store i32 %245, ptr %5, align 4
  %246 = xor i32 %2, 2075317435
  %247 = and i32 %2, %246
  %248 = or i32 %2, %246
  %249 = xor i32 %2, %246
  %250 = add i32 %247, %248
  %251 = sub i32 %250, %2
  %252 = sub i32 %251, %246
  %253 = mul i32 %252, 58
  %254 = icmp eq i32 %253, 0
  br i1 %254, label %183, label %426

255:                                              ; preds = %14
  %256 = load i32, ptr %5, align 4
  %257 = xor i32 %256, 783113826
  store i32 %257, ptr %5, align 4
  %258 = xor i32 %2, 1734960165
  %259 = and i32 %2, %258
  %260 = or i32 %2, %258
  %261 = xor i32 %2, %258
  %262 = sub i32 %260, %261
  %263 = sub i32 %262, %259
  %264 = mul i32 %263, 109
  %265 = icmp eq i32 %264, 0
  br i1 %265, label %183, label %437

266:                                              ; preds = %14
  %267 = load i32, ptr %5, align 4
  %268 = xor i32 %267, 106551835
  store i32 %268, ptr %5, align 4
  %269 = xor i32 %2, 2073870617
  %270 = and i32 %2, %269
  %271 = or i32 %2, %269
  %272 = xor i32 %2, %269
  %273 = mul i32 %271, 2
  %274 = sub i32 %273, %272
  %275 = sub i32 %274, %2
  %276 = sub i32 %275, %269
  %277 = mul i32 %276, 67
  %278 = icmp uge i32 %277, 0
  br i1 %278, label %183, label %447

279:                                              ; preds = %14
  %280 = load i32, ptr %5, align 4
  %281 = xor i32 %280, 630116968
  store i32 %281, ptr %5, align 4
  %282 = xor i32 %2, -1012976433
  %283 = and i32 %2, %282
  %284 = or i32 %2, %282
  %285 = xor i32 %2, %282
  %286 = mul i32 %284, 2
  %287 = sub i32 %286, %285
  %288 = sub i32 %287, %2
  %289 = sub i32 %288, %282
  %290 = mul i32 %289, 116
  %291 = icmp slt i32 %290, 0
  br i1 %291, label %457, label %183

292:                                              ; preds = %14
  %293 = load i32, ptr %5, align 4
  %294 = xor i32 %293, 1195726644
  store i32 %294, ptr %5, align 4
  %295 = xor i32 %2, -93053997
  %296 = and i32 %2, %295
  %297 = or i32 %2, %295
  %298 = xor i32 %2, %295
  %299 = add i32 %296, %297
  %300 = sub i32 %299, %2
  %301 = sub i32 %300, %295
  %302 = mul i32 %301, 43
  %303 = icmp slt i32 %302, 0
  br i1 %303, label %466, label %183

304:                                              ; preds = %18
  %305 = load i64, ptr %4, align 8
  %306 = ptrtoint ptr %0 to i64
  %307 = ptrtoint ptr %1 to i64
  %308 = zext i32 %2 to i64
  %309 = mul i64 %307, %305
  %310 = sub i64 %309, %308
  %311 = and i64 %310, %308
  store i64 %311, ptr %4, align 8
  br label %183

312:                                              ; preds = %39
  %313 = load i64, ptr %4, align 8
  %314 = ptrtoint ptr %0 to i64
  %315 = ptrtoint ptr %1 to i64
  %316 = zext i32 %2 to i64
  %317 = and i64 %316, %316
  %318 = mul i64 %317, %313
  %319 = sub i64 %318, %315
  store i64 %319, ptr %4, align 8
  br label %183

320:                                              ; preds = %52
  %321 = load i64, ptr %4, align 8
  %322 = ptrtoint ptr %0 to i64
  %323 = ptrtoint ptr %1 to i64
  %324 = zext i32 %2 to i64
  %325 = add i64 %321, %322
  %326 = xor i64 %325, %321
  %327 = mul i64 %326, %322
  %328 = sub i64 %327, %324
  store i64 %328, ptr %4, align 8
  br label %183

329:                                              ; preds = %72
  %330 = load i64, ptr %4, align 8
  %331 = ptrtoint ptr %0 to i64
  %332 = ptrtoint ptr %1 to i64
  %333 = zext i32 %2 to i64
  %334 = mul i64 %330, %333
  %335 = add i64 %334, %332
  %336 = sub i64 %335, %330
  store i64 %336, ptr %4, align 8
  br label %183

337:                                              ; preds = %86
  %338 = load i64, ptr %4, align 8
  %339 = ptrtoint ptr %0 to i64
  %340 = ptrtoint ptr %1 to i64
  %341 = zext i32 %2 to i64
  %342 = xor i64 %338, %340
  %343 = or i64 %342, %339
  %344 = xor i64 %343, %340
  %345 = add i64 %344, %339
  %346 = mul i64 %345, %341
  %347 = or i64 %346, %338
  store i64 %347, ptr %4, align 8
  br label %183

348:                                              ; preds = %103
  %349 = load i64, ptr %4, align 8
  %350 = ptrtoint ptr %0 to i64
  %351 = ptrtoint ptr %1 to i64
  %352 = zext i32 %2 to i64
  %353 = sub i64 %352, %349
  %354 = or i64 %353, %352
  %355 = and i64 %354, %349
  %356 = add i64 %355, %351
  store i64 %356, ptr %4, align 8
  br label %183

357:                                              ; preds = %130
  %358 = load i64, ptr %4, align 8
  %359 = ptrtoint ptr %0 to i64
  %360 = ptrtoint ptr %1 to i64
  %361 = zext i32 %2 to i64
  %362 = sub i64 %360, %361
  %363 = add i64 %362, %358
  %364 = or i64 %363, %360
  %365 = mul i64 %364, %361
  %366 = mul i64 %365, %359
  %367 = and i64 %366, %358
  store i64 %367, ptr %4, align 8
  br label %183

368:                                              ; preds = %147
  %369 = load i64, ptr %4, align 8
  %370 = ptrtoint ptr %0 to i64
  %371 = ptrtoint ptr %1 to i64
  %372 = zext i32 %2 to i64
  %373 = xor i64 %370, %370
  %374 = sub i64 %373, %370
  %375 = sub i64 %374, %370
  %376 = mul i64 %375, %371
  store i64 %376, ptr %4, align 8
  br label %183

377:                                              ; preds = %164
  %378 = load i64, ptr %4, align 8
  %379 = ptrtoint ptr %0 to i64
  %380 = ptrtoint ptr %1 to i64
  %381 = zext i32 %2 to i64
  %382 = sub i64 %378, %381
  %383 = or i64 %382, %378
  %384 = sub i64 %383, %381
  %385 = add i64 %384, %381
  %386 = mul i64 %385, %379
  store i64 %386, ptr %4, align 8
  br label %183

387:                                              ; preds = %184
  %388 = load i64, ptr %4, align 8
  %389 = ptrtoint ptr %0 to i64
  %390 = ptrtoint ptr %1 to i64
  %391 = zext i32 %2 to i64
  %392 = xor i64 %388, %388
  %393 = and i64 %392, %389
  %394 = mul i64 %393, %388
  %395 = or i64 %394, %391
  %396 = add i64 %395, %391
  store i64 %396, ptr %4, align 8
  br label %14

397:                                              ; preds = %195
  %398 = load i64, ptr %4, align 8
  %399 = ptrtoint ptr %0 to i64
  %400 = ptrtoint ptr %1 to i64
  %401 = zext i32 %2 to i64
  %402 = and i64 %400, %401
  %403 = xor i64 %402, %401
  %404 = add i64 %403, %399
  %405 = mul i64 %404, %398
  store i64 %405, ptr %4, align 8
  br label %183

406:                                              ; preds = %208
  %407 = load i64, ptr %4, align 8
  %408 = ptrtoint ptr %0 to i64
  %409 = ptrtoint ptr %1 to i64
  %410 = zext i32 %2 to i64
  %411 = or i64 %407, %409
  %412 = mul i64 %411, %410
  %413 = xor i64 %412, %407
  %414 = add i64 %413, %409
  store i64 %414, ptr %4, align 8
  br label %183

415:                                              ; preds = %221
  %416 = load i64, ptr %4, align 8
  %417 = ptrtoint ptr %0 to i64
  %418 = ptrtoint ptr %1 to i64
  %419 = zext i32 %2 to i64
  %420 = add i64 %419, %417
  %421 = or i64 %420, %419
  %422 = add i64 %421, %419
  %423 = sub i64 %422, %416
  %424 = mul i64 %423, %417
  %425 = or i64 %424, %419
  store i64 %425, ptr %4, align 8
  br label %183

426:                                              ; preds = %243
  %427 = load i64, ptr %4, align 8
  %428 = ptrtoint ptr %0 to i64
  %429 = ptrtoint ptr %1 to i64
  %430 = zext i32 %2 to i64
  %431 = add i64 %430, %430
  %432 = mul i64 %431, %429
  %433 = add i64 %432, %427
  %434 = mul i64 %433, %428
  %435 = xor i64 %434, %429
  %436 = or i64 %435, %429
  store i64 %436, ptr %4, align 8
  br label %183

437:                                              ; preds = %255
  %438 = load i64, ptr %4, align 8
  %439 = ptrtoint ptr %0 to i64
  %440 = ptrtoint ptr %1 to i64
  %441 = zext i32 %2 to i64
  %442 = and i64 %441, %440
  %443 = and i64 %442, %438
  %444 = mul i64 %443, %438
  %445 = sub i64 %444, %441
  %446 = and i64 %445, %441
  store i64 %446, ptr %4, align 8
  br label %183

447:                                              ; preds = %266
  %448 = load i64, ptr %4, align 8
  %449 = ptrtoint ptr %0 to i64
  %450 = ptrtoint ptr %1 to i64
  %451 = zext i32 %2 to i64
  %452 = mul i64 %451, %448
  %453 = sub i64 %452, %451
  %454 = sub i64 %453, %450
  %455 = mul i64 %454, %451
  %456 = and i64 %455, %448
  store i64 %456, ptr %4, align 8
  br label %183

457:                                              ; preds = %279
  %458 = load i64, ptr %4, align 8
  %459 = ptrtoint ptr %0 to i64
  %460 = ptrtoint ptr %1 to i64
  %461 = zext i32 %2 to i64
  %462 = add i64 %458, %458
  %463 = add i64 %462, %460
  %464 = or i64 %463, %460
  %465 = xor i64 %464, %461
  store i64 %465, ptr %4, align 8
  br label %183

466:                                              ; preds = %292
  %467 = load i64, ptr %4, align 8
  %468 = ptrtoint ptr %0 to i64
  %469 = ptrtoint ptr %1 to i64
  %470 = zext i32 %2 to i64
  %471 = xor i64 %469, %467
  %472 = mul i64 %471, %468
  %473 = or i64 %472, %467
  %474 = xor i64 %473, %470
  %475 = or i64 %474, %467
  %476 = or i64 %475, %470
  store i64 %476, ptr %4, align 8
  br label %183
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @chooseProcess(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 2034148792, ptr %5, align 4
  br label %11

11:                                               ; preds = %439, %183, %182, %3
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, -1323351069
  %14 = mul i32 %13, 1784273557
  %15 = icmp slt i32 %14, 1097341618
  br i1 %15, label %307, label %309

16:                                               ; preds = %347
  store ptr %0, ptr %6, align 8
  store i32 %1, ptr %7, align 4
  store i32 %2, ptr %8, align 4
  store i32 -1, ptr %9, align 4
  store i32 0, ptr %10, align 4
  store i32 -1445815404, ptr %5, align 4
  %17 = xor i32 %1, 481091017
  %18 = and i32 %1, %17
  %19 = or i32 %1, %17
  %20 = xor i32 %1, %17
  %21 = sub i32 %19, %20
  %22 = sub i32 %21, %18
  %23 = mul i32 %22, 189
  %24 = icmp ugt i32 %23, 0
  br i1 %24, label %359, label %182

25:                                               ; preds = %333
  %26 = load i32, ptr %10, align 4
  %27 = load i32, ptr %7, align 4
  %28 = icmp slt i32 %26, %27
  %29 = select i1 %28, i32 153713471, i32 -236144444
  store i32 %29, ptr %5, align 4
  %30 = xor i32 %1, -951794197
  %31 = and i32 %1, %30
  %32 = or i32 %1, %30
  %33 = xor i32 %1, %30
  %34 = add i32 %1, %30
  %35 = sub i32 %34, %33
  %36 = mul i32 %31, 2
  %37 = sub i32 %35, %36
  %38 = mul i32 %37, 72
  %39 = xor i32 %1, -1107360427
  %40 = and i32 %1, %39
  %41 = or i32 %1, %39
  %42 = xor i32 %1, %39
  %43 = add i32 %40, %41
  %44 = sub i32 %43, %1
  %45 = sub i32 %44, %39
  %46 = mul i32 %45, 209
  %47 = icmp eq i32 %38, %46
  br i1 %47, label %182, label %367

48:                                               ; preds = %343
  %49 = load ptr, ptr %6, align 8
  %50 = load i32, ptr %10, align 4
  %51 = sext i32 %50 to i64
  %52 = getelementptr inbounds %struct.Process, ptr %49, i64 %51
  %53 = getelementptr inbounds nuw %struct.Process, ptr %52, i32 0, i32 1
  %54 = load i32, ptr %53, align 4
  %55 = load i32, ptr %8, align 4
  %56 = icmp sle i32 %54, %55
  %57 = select i1 %56, i32 1167689157, i32 2007901095
  store i32 %57, ptr %5, align 4
  %58 = xor i32 %1, -1523771369
  %59 = and i32 %1, %58
  %60 = or i32 %1, %58
  %61 = xor i32 %1, %58
  %62 = add i32 %1, %58
  %63 = sub i32 %62, %61
  %64 = mul i32 %59, 2
  %65 = sub i32 %63, %64
  %66 = mul i32 %65, 217
  %67 = icmp uge i32 %66, 0
  br i1 %67, label %182, label %375

68:                                               ; preds = %315
  %69 = load ptr, ptr %6, align 8
  %70 = load i32, ptr %10, align 4
  %71 = sext i32 %70 to i64
  %72 = getelementptr inbounds %struct.Process, ptr %69, i64 %71
  %73 = getelementptr inbounds nuw %struct.Process, ptr %72, i32 0, i32 3
  %74 = load i32, ptr %73, align 4
  %75 = icmp sgt i32 %74, 0
  %76 = select i1 %75, i32 -1862672619, i32 2007901095
  store i32 %76, ptr %5, align 4
  %77 = xor i32 %1, 1315344849
  %78 = and i32 %1, %77
  %79 = or i32 %1, %77
  %80 = xor i32 %1, %77
  %81 = mul i32 %79, 2
  %82 = sub i32 %81, %80
  %83 = sub i32 %82, %1
  %84 = sub i32 %83, %77
  %85 = mul i32 %84, 96
  %86 = xor i32 %1, -1295458669
  %87 = and i32 %1, %86
  %88 = or i32 %1, %86
  %89 = xor i32 %1, %86
  %90 = mul i32 %88, 2
  %91 = sub i32 %90, %89
  %92 = sub i32 %91, %1
  %93 = sub i32 %92, %86
  %94 = mul i32 %93, 230
  %95 = icmp ne i32 %85, %94
  br i1 %95, label %383, label %182

96:                                               ; preds = %323
  %97 = load i32, ptr %9, align 4
  %98 = icmp eq i32 %97, -1
  %99 = select i1 %98, i32 -1506546099, i32 -1653543096
  store i32 %99, ptr %5, align 4
  %100 = xor i32 %1, -483282897
  %101 = and i32 %1, %100
  %102 = or i32 %1, %100
  %103 = xor i32 %1, %100
  %104 = sub i32 %102, %103
  %105 = sub i32 %104, %101
  %106 = mul i32 %105, 133
  %107 = icmp slt i32 %106, 1
  br i1 %107, label %182, label %393

108:                                              ; preds = %357
  %109 = load ptr, ptr %6, align 8
  %110 = load i32, ptr %10, align 4
  %111 = sext i32 %110 to i64
  %112 = getelementptr inbounds %struct.Process, ptr %109, i64 %111
  %113 = load ptr, ptr %6, align 8
  %114 = load i32, ptr %9, align 4
  %115 = sext i32 %114 to i64
  %116 = getelementptr inbounds %struct.Process, ptr %113, i64 %115
  %117 = load i32, ptr %8, align 4
  %118 = call i32 @isBetter(ptr noundef %112, ptr noundef %116, i32 noundef %117)
  %119 = icmp ne i32 %118, 0
  %120 = select i1 %119, i32 -1506546099, i32 1835512172
  store i32 %120, ptr %5, align 4
  %121 = xor i32 %1, -1965856225
  %122 = and i32 %1, %121
  %123 = or i32 %1, %121
  %124 = xor i32 %1, %121
  %125 = add i32 %122, %123
  %126 = sub i32 %125, %1
  %127 = sub i32 %126, %121
  %128 = mul i32 %127, 192
  %129 = icmp eq i32 %128, 0
  br i1 %129, label %182, label %401

130:                                              ; preds = %345
  %131 = load i32, ptr %10, align 4
  store i32 %131, ptr %9, align 4
  store i32 1835512172, ptr %5, align 4
  %132 = xor i32 %1, -1750214307
  %133 = and i32 %1, %132
  %134 = or i32 %1, %132
  %135 = xor i32 %1, %132
  %136 = add i32 %1, %132
  %137 = sub i32 %136, %135
  %138 = mul i32 %133, 2
  %139 = sub i32 %137, %138
  %140 = mul i32 %139, 35
  %141 = icmp slt i32 %140, 1
  br i1 %141, label %182, label %410

142:                                              ; preds = %321
  store i32 2007901095, ptr %5, align 4
  %143 = xor i32 %1, 2098935285
  %144 = and i32 %1, %143
  %145 = or i32 %1, %143
  %146 = xor i32 %1, %143
  %147 = mul i32 %145, 2
  %148 = sub i32 %147, %146
  %149 = sub i32 %148, %1
  %150 = sub i32 %149, %143
  %151 = mul i32 %150, 149
  %152 = xor i32 %1, -1695504337
  %153 = and i32 %1, %152
  %154 = or i32 %1, %152
  %155 = xor i32 %1, %152
  %156 = sub i32 %154, %155
  %157 = sub i32 %156, %153
  %158 = mul i32 %157, 245
  %159 = icmp ne i32 %151, %158
  br i1 %159, label %421, label %182

160:                                              ; preds = %329
  %161 = load i32, ptr %10, align 4
  %162 = load i32, ptr %5, align 4
  %163 = xor i32 %162, 2007901094
  %164 = sub i32 %161, %163
  %165 = load i32, ptr %5, align 4
  %166 = xor i32 %165, 2007901093
  %167 = mul i32 %161, %166
  %168 = load i32, ptr %5, align 4
  %169 = xor i32 %168, 2007901094
  %170 = mul i32 %169, %164
  %171 = sub i32 %167, %170
  store i32 %171, ptr %10, align 4
  store i32 -1445815404, ptr %5, align 4
  %172 = xor i32 %1, 1394325731
  %173 = and i32 %1, %172
  %174 = or i32 %1, %172
  %175 = xor i32 %1, %172
  %176 = sub i32 %174, %175
  %177 = sub i32 %176, %173
  %178 = mul i32 %177, 2
  %179 = icmp eq i32 %178, 0
  br i1 %179, label %182, label %431

180:                                              ; preds = %353
  %181 = load i32, ptr %9, align 4
  ret i32 %181

182:                                              ; preds = %515, %505, %496, %487, %476, %465, %457, %449, %431, %421, %410, %401, %393, %383, %375, %367, %359, %296, %285, %263, %250, %237, %224, %211, %192, %160, %142, %130, %108, %96, %68, %48, %25, %16
  br label %11

183:                                              ; preds = %357, %353, %351, %345, %343, %333, %329, %327, %321, %319
  store i32 2034148792, ptr %5, align 4
  call void asm sideeffect "", ""()
  %184 = xor i32 %1, -26360393
  %185 = and i32 %1, %184
  %186 = or i32 %1, %184
  %187 = xor i32 %1, %184
  %188 = sub i32 %186, %187
  %189 = sub i32 %188, %185
  %190 = mul i32 %189, 72
  %191 = icmp slt i32 %190, 0
  br i1 %191, label %439, label %11

192:                                              ; preds = %339
  %193 = load i32, ptr %5, align 4
  %194 = xor i32 %193, -859852965
  store i32 %194, ptr %5, align 4
  %195 = xor i32 %1, -882475107
  %196 = and i32 %1, %195
  %197 = or i32 %1, %195
  %198 = xor i32 %1, %195
  %199 = add i32 %196, %197
  %200 = sub i32 %199, %1
  %201 = sub i32 %200, %195
  %202 = mul i32 %201, 70
  %203 = xor i32 %1, -828647805
  %204 = and i32 %1, %203
  %205 = or i32 %1, %203
  %206 = xor i32 %1, %203
  %207 = sub i32 %205, %206
  %208 = sub i32 %207, %204
  %209 = mul i32 %208, 207
  %210 = icmp ne i32 %202, %209
  br i1 %210, label %449, label %182

211:                                              ; preds = %327
  %212 = load i32, ptr %5, align 4
  %213 = xor i32 %212, 1135837554
  store i32 %213, ptr %5, align 4
  %214 = xor i32 %1, 1980358503
  %215 = and i32 %1, %214
  %216 = or i32 %1, %214
  %217 = xor i32 %1, %214
  %218 = add i32 %1, %214
  %219 = sub i32 %218, %217
  %220 = mul i32 %215, 2
  %221 = sub i32 %219, %220
  %222 = mul i32 %221, 110
  %223 = icmp slt i32 %222, 0
  br i1 %223, label %457, label %182

224:                                              ; preds = %351
  %225 = load i32, ptr %5, align 4
  %226 = xor i32 %225, 803972783
  store i32 %226, ptr %5, align 4
  %227 = xor i32 %1, 222700053
  %228 = and i32 %1, %227
  %229 = or i32 %1, %227
  %230 = xor i32 %1, %227
  %231 = add i32 %1, %227
  %232 = sub i32 %231, %230
  %233 = mul i32 %228, 2
  %234 = sub i32 %232, %233
  %235 = mul i32 %234, 126
  %236 = icmp slt i32 %235, 0
  br i1 %236, label %465, label %182

237:                                              ; preds = %331
  %238 = load i32, ptr %5, align 4
  %239 = xor i32 %238, 1278963394
  store i32 %239, ptr %5, align 4
  %240 = xor i32 %1, 11028593
  %241 = and i32 %1, %240
  %242 = or i32 %1, %240
  %243 = xor i32 %1, %240
  %244 = mul i32 %242, 2
  %245 = sub i32 %244, %243
  %246 = sub i32 %245, %1
  %247 = sub i32 %246, %240
  %248 = mul i32 %247, 167
  %249 = icmp ugt i32 %248, 0
  br i1 %249, label %476, label %182

250:                                              ; preds = %355
  %251 = load i32, ptr %5, align 4
  %252 = xor i32 %251, -210498616
  store i32 %252, ptr %5, align 4
  %253 = xor i32 %1, 415980527
  %254 = and i32 %1, %253
  %255 = or i32 %1, %253
  %256 = xor i32 %1, %253
  %257 = mul i32 %255, 2
  %258 = sub i32 %257, %256
  %259 = sub i32 %258, %1
  %260 = sub i32 %259, %253
  %261 = mul i32 %260, 54
  %262 = icmp sgt i32 %261, 0
  br i1 %262, label %487, label %182

263:                                              ; preds = %317
  %264 = load i32, ptr %5, align 4
  %265 = xor i32 %264, -1005276417
  store i32 %265, ptr %5, align 4
  %266 = xor i32 %1, 733679319
  %267 = and i32 %1, %266
  %268 = or i32 %1, %266
  %269 = xor i32 %1, %266
  %270 = add i32 %1, %266
  %271 = sub i32 %270, %269
  %272 = mul i32 %267, 2
  %273 = sub i32 %271, %272
  %274 = mul i32 %273, 233
  %275 = xor i32 %1, -1283902589
  %276 = and i32 %1, %275
  %277 = or i32 %1, %275
  %278 = xor i32 %1, %275
  %279 = add i32 %1, %275
  %280 = sub i32 %279, %278
  %281 = mul i32 %276, 2
  %282 = sub i32 %280, %281
  %283 = mul i32 %282, 153
  %284 = icmp eq i32 %274, %283
  br i1 %284, label %182, label %496

285:                                              ; preds = %341
  %286 = load i32, ptr %5, align 4
  %287 = xor i32 %286, 193854324
  store i32 %287, ptr %5, align 4
  %288 = xor i32 %1, 1713090443
  %289 = and i32 %1, %288
  %290 = or i32 %1, %288
  %291 = xor i32 %1, %288
  %292 = sub i32 %290, %291
  %293 = sub i32 %292, %289
  %294 = mul i32 %293, 194
  %295 = icmp slt i32 %294, 0
  br i1 %295, label %505, label %182

296:                                              ; preds = %319
  %297 = load i32, ptr %5, align 4
  %298 = xor i32 %297, -415531530
  store i32 %298, ptr %5, align 4
  %299 = xor i32 %1, -396623425
  %300 = and i32 %1, %299
  %301 = or i32 %1, %299
  %302 = xor i32 %1, %299
  %303 = sub i32 %301, %302
  %304 = sub i32 %303, %300
  %305 = mul i32 %304, 236
  %306 = icmp eq i32 %305, 0
  br i1 %306, label %182, label %515

307:                                              ; preds = %11
  %308 = icmp slt i32 %14, 449243162
  br i1 %308, label %311, label %313

309:                                              ; preds = %11
  %310 = icmp slt i32 %14, 1755337465
  br i1 %310, label %335, label %337

311:                                              ; preds = %307
  %312 = icmp slt i32 %14, 292042906
  br i1 %312, label %315, label %317

313:                                              ; preds = %307
  %314 = icmp slt i32 %14, 785982740
  br i1 %314, label %323, label %325

315:                                              ; preds = %311
  %316 = icmp eq i32 %14, 47500426
  br i1 %316, label %68, label %319

317:                                              ; preds = %311
  %318 = icmp eq i32 %14, 292042906
  br i1 %318, label %263, label %321

319:                                              ; preds = %315
  %320 = icmp eq i32 %14, 153157012
  br i1 %320, label %296, label %183

321:                                              ; preds = %317
  %322 = icmp eq i32 %14, 303000253
  br i1 %322, label %142, label %183

323:                                              ; preds = %313
  %324 = icmp eq i32 %14, 449243162
  br i1 %324, label %96, label %327

325:                                              ; preds = %313
  %326 = icmp slt i32 %14, 841340778
  br i1 %326, label %329, label %331

327:                                              ; preds = %323
  %328 = icmp eq i32 %14, 561179167
  br i1 %328, label %211, label %183

329:                                              ; preds = %325
  %330 = icmp eq i32 %14, 785982740
  br i1 %330, label %160, label %183

331:                                              ; preds = %325
  %332 = icmp eq i32 %14, 841340778
  br i1 %332, label %237, label %333

333:                                              ; preds = %331
  %334 = icmp eq i32 %14, 1066910725
  br i1 %334, label %25, label %183

335:                                              ; preds = %309
  %336 = icmp slt i32 %14, 1287061819
  br i1 %336, label %339, label %341

337:                                              ; preds = %309
  %338 = icmp slt i32 %14, 2035654901
  br i1 %338, label %347, label %349

339:                                              ; preds = %335
  %340 = icmp eq i32 %14, 1097341618
  br i1 %340, label %192, label %343

341:                                              ; preds = %335
  %342 = icmp eq i32 %14, 1287061819
  br i1 %342, label %285, label %345

343:                                              ; preds = %339
  %344 = icmp eq i32 %14, 1209176204
  br i1 %344, label %48, label %183

345:                                              ; preds = %341
  %346 = icmp eq i32 %14, 1627354034
  br i1 %346, label %130, label %183

347:                                              ; preds = %337
  %348 = icmp eq i32 %14, 1755337465
  br i1 %348, label %16, label %351

349:                                              ; preds = %337
  %350 = icmp slt i32 %14, 2110387889
  br i1 %350, label %353, label %355

351:                                              ; preds = %347
  %352 = icmp eq i32 %14, 1939783823
  br i1 %352, label %224, label %183

353:                                              ; preds = %349
  %354 = icmp eq i32 %14, 2035654901
  br i1 %354, label %180, label %183

355:                                              ; preds = %349
  %356 = icmp eq i32 %14, 2110387889
  br i1 %356, label %250, label %357

357:                                              ; preds = %355
  %358 = icmp eq i32 %14, 2140783561
  br i1 %358, label %108, label %183

359:                                              ; preds = %16
  %360 = load i64, ptr %4, align 8
  %361 = ptrtoint ptr %0 to i64
  %362 = zext i32 %1 to i64
  %363 = zext i32 %2 to i64
  %364 = sub i64 %360, %362
  %365 = sub i64 %364, %362
  %366 = and i64 %365, %361
  store i64 %366, ptr %4, align 8
  br label %182

367:                                              ; preds = %25
  %368 = load i64, ptr %4, align 8
  %369 = ptrtoint ptr %0 to i64
  %370 = zext i32 %1 to i64
  %371 = zext i32 %2 to i64
  %372 = or i64 %368, %369
  %373 = xor i64 %372, %369
  %374 = sub i64 %373, %371
  store i64 %374, ptr %4, align 8
  br label %182

375:                                              ; preds = %48
  %376 = load i64, ptr %4, align 8
  %377 = ptrtoint ptr %0 to i64
  %378 = zext i32 %1 to i64
  %379 = zext i32 %2 to i64
  %380 = and i64 %377, %377
  %381 = and i64 %380, %377
  %382 = xor i64 %381, %377
  store i64 %382, ptr %4, align 8
  br label %182

383:                                              ; preds = %68
  %384 = load i64, ptr %4, align 8
  %385 = ptrtoint ptr %0 to i64
  %386 = zext i32 %1 to i64
  %387 = zext i32 %2 to i64
  %388 = sub i64 %385, %385
  %389 = mul i64 %388, %386
  %390 = add i64 %389, %386
  %391 = mul i64 %390, %387
  %392 = and i64 %391, %384
  store i64 %392, ptr %4, align 8
  br label %182

393:                                              ; preds = %96
  %394 = load i64, ptr %4, align 8
  %395 = ptrtoint ptr %0 to i64
  %396 = zext i32 %1 to i64
  %397 = zext i32 %2 to i64
  %398 = mul i64 %397, %395
  %399 = sub i64 %398, %397
  %400 = add i64 %399, %395
  store i64 %400, ptr %4, align 8
  br label %182

401:                                              ; preds = %108
  %402 = load i64, ptr %4, align 8
  %403 = ptrtoint ptr %0 to i64
  %404 = zext i32 %1 to i64
  %405 = zext i32 %2 to i64
  %406 = sub i64 %403, %402
  %407 = mul i64 %406, %402
  %408 = add i64 %407, %403
  %409 = sub i64 %408, %405
  store i64 %409, ptr %4, align 8
  br label %182

410:                                              ; preds = %130
  %411 = load i64, ptr %4, align 8
  %412 = ptrtoint ptr %0 to i64
  %413 = zext i32 %1 to i64
  %414 = zext i32 %2 to i64
  %415 = mul i64 %413, %411
  %416 = add i64 %415, %413
  %417 = mul i64 %416, %412
  %418 = or i64 %417, %413
  %419 = mul i64 %418, %414
  %420 = sub i64 %419, %413
  store i64 %420, ptr %4, align 8
  br label %182

421:                                              ; preds = %142
  %422 = load i64, ptr %4, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = zext i32 %1 to i64
  %425 = zext i32 %2 to i64
  %426 = or i64 %424, %424
  %427 = mul i64 %426, %425
  %428 = and i64 %427, %422
  %429 = mul i64 %428, %424
  %430 = or i64 %429, %422
  store i64 %430, ptr %4, align 8
  br label %182

431:                                              ; preds = %160
  %432 = load i64, ptr %4, align 8
  %433 = ptrtoint ptr %0 to i64
  %434 = zext i32 %1 to i64
  %435 = zext i32 %2 to i64
  %436 = sub i64 %434, %434
  %437 = add i64 %436, %435
  %438 = xor i64 %437, %433
  store i64 %438, ptr %4, align 8
  br label %182

439:                                              ; preds = %183
  %440 = load i64, ptr %4, align 8
  %441 = ptrtoint ptr %0 to i64
  %442 = zext i32 %1 to i64
  %443 = zext i32 %2 to i64
  %444 = add i64 %441, %442
  %445 = add i64 %444, %440
  %446 = mul i64 %445, %442
  %447 = sub i64 %446, %441
  %448 = mul i64 %447, %440
  store i64 %448, ptr %4, align 8
  br label %11

449:                                              ; preds = %192
  %450 = load i64, ptr %4, align 8
  %451 = ptrtoint ptr %0 to i64
  %452 = zext i32 %1 to i64
  %453 = zext i32 %2 to i64
  %454 = xor i64 %451, %453
  %455 = or i64 %454, %451
  %456 = sub i64 %455, %451
  store i64 %456, ptr %4, align 8
  br label %182

457:                                              ; preds = %211
  %458 = load i64, ptr %4, align 8
  %459 = ptrtoint ptr %0 to i64
  %460 = zext i32 %1 to i64
  %461 = zext i32 %2 to i64
  %462 = and i64 %459, %460
  %463 = add i64 %462, %460
  %464 = xor i64 %463, %461
  store i64 %464, ptr %4, align 8
  br label %182

465:                                              ; preds = %224
  %466 = load i64, ptr %4, align 8
  %467 = ptrtoint ptr %0 to i64
  %468 = zext i32 %1 to i64
  %469 = zext i32 %2 to i64
  %470 = xor i64 %468, %467
  %471 = mul i64 %470, %469
  %472 = sub i64 %471, %468
  %473 = sub i64 %472, %466
  %474 = or i64 %473, %467
  %475 = and i64 %474, %468
  store i64 %475, ptr %4, align 8
  br label %182

476:                                              ; preds = %237
  %477 = load i64, ptr %4, align 8
  %478 = ptrtoint ptr %0 to i64
  %479 = zext i32 %1 to i64
  %480 = zext i32 %2 to i64
  %481 = xor i64 %478, %478
  %482 = or i64 %481, %477
  %483 = sub i64 %482, %480
  %484 = and i64 %483, %477
  %485 = or i64 %484, %479
  %486 = mul i64 %485, %478
  store i64 %486, ptr %4, align 8
  br label %182

487:                                              ; preds = %250
  %488 = load i64, ptr %4, align 8
  %489 = ptrtoint ptr %0 to i64
  %490 = zext i32 %1 to i64
  %491 = zext i32 %2 to i64
  %492 = xor i64 %488, %490
  %493 = and i64 %492, %489
  %494 = add i64 %493, %491
  %495 = add i64 %494, %490
  store i64 %495, ptr %4, align 8
  br label %182

496:                                              ; preds = %263
  %497 = load i64, ptr %4, align 8
  %498 = ptrtoint ptr %0 to i64
  %499 = zext i32 %1 to i64
  %500 = zext i32 %2 to i64
  %501 = add i64 %498, %499
  %502 = sub i64 %501, %500
  %503 = or i64 %502, %500
  %504 = sub i64 %503, %498
  store i64 %504, ptr %4, align 8
  br label %182

505:                                              ; preds = %285
  %506 = load i64, ptr %4, align 8
  %507 = ptrtoint ptr %0 to i64
  %508 = zext i32 %1 to i64
  %509 = zext i32 %2 to i64
  %510 = and i64 %508, %508
  %511 = mul i64 %510, %508
  %512 = xor i64 %511, %509
  %513 = or i64 %512, %509
  %514 = add i64 %513, %506
  store i64 %514, ptr %4, align 8
  br label %182

515:                                              ; preds = %296
  %516 = load i64, ptr %4, align 8
  %517 = ptrtoint ptr %0 to i64
  %518 = zext i32 %1 to i64
  %519 = zext i32 %2 to i64
  %520 = xor i64 %518, %516
  %521 = mul i64 %520, %518
  %522 = sub i64 %521, %517
  %523 = add i64 %522, %519
  %524 = add i64 %523, %517
  store i64 %524, ptr %4, align 8
  br label %182
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @nextArrival(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 1395125456, ptr %5, align 4
  br label %11

11:                                               ; preds = %373, %138, %137, %3
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 1740607995
  %14 = mul i32 %13, 1375559595
  %15 = icmp slt i32 %14, 590369433
  br i1 %15, label %263, label %265

16:                                               ; preds = %285
  store ptr %0, ptr %6, align 8
  store i32 %1, ptr %7, align 4
  store i32 %2, ptr %8, align 4
  store i32 1000000000, ptr %9, align 4
  store i32 0, ptr %10, align 4
  store i32 -239902097, ptr %5, align 4
  %17 = xor i32 %1, -1804912239
  %18 = and i32 %1, %17
  %19 = or i32 %1, %17
  %20 = xor i32 %1, %17
  %21 = add i32 %1, %17
  %22 = sub i32 %21, %20
  %23 = mul i32 %18, 2
  %24 = sub i32 %22, %23
  %25 = mul i32 %24, 128
  %26 = icmp ugt i32 %25, 0
  br i1 %26, label %307, label %137

27:                                               ; preds = %303
  %28 = load i32, ptr %10, align 4
  %29 = load i32, ptr %7, align 4
  %30 = icmp slt i32 %28, %29
  %31 = select i1 %30, i32 628311260, i32 966742389
  store i32 %31, ptr %5, align 4
  %32 = xor i32 %1, -50389475
  %33 = and i32 %1, %32
  %34 = or i32 %1, %32
  %35 = xor i32 %1, %32
  %36 = add i32 %1, %32
  %37 = sub i32 %36, %35
  %38 = mul i32 %33, 2
  %39 = sub i32 %37, %38
  %40 = mul i32 %39, 224
  %41 = icmp eq i32 %40, 0
  br i1 %41, label %137, label %315

42:                                               ; preds = %301
  %43 = load ptr, ptr %6, align 8
  %44 = load i32, ptr %10, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds %struct.Process, ptr %43, i64 %45
  %47 = getelementptr inbounds nuw %struct.Process, ptr %46, i32 0, i32 3
  %48 = load i32, ptr %47, align 4
  %49 = icmp sgt i32 %48, 0
  %50 = select i1 %49, i32 1299117887, i32 2075260102
  store i32 %50, ptr %5, align 4
  %51 = xor i32 %1, 1249952181
  %52 = and i32 %1, %51
  %53 = or i32 %1, %51
  %54 = xor i32 %1, %51
  %55 = add i32 %52, %53
  %56 = sub i32 %55, %1
  %57 = sub i32 %56, %51
  %58 = mul i32 %57, 66
  %59 = icmp eq i32 %58, 0
  br i1 %59, label %137, label %323

60:                                               ; preds = %281
  %61 = load ptr, ptr %6, align 8
  %62 = load i32, ptr %10, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds %struct.Process, ptr %61, i64 %63
  %65 = getelementptr inbounds nuw %struct.Process, ptr %64, i32 0, i32 1
  %66 = load i32, ptr %65, align 4
  %67 = load i32, ptr %8, align 4
  %68 = icmp sgt i32 %66, %67
  %69 = select i1 %68, i32 781676414, i32 2075260102
  store i32 %69, ptr %5, align 4
  %70 = xor i32 %1, -82039759
  %71 = and i32 %1, %70
  %72 = or i32 %1, %70
  %73 = xor i32 %1, %70
  %74 = add i32 %1, %70
  %75 = sub i32 %74, %73
  %76 = mul i32 %71, 2
  %77 = sub i32 %75, %76
  %78 = mul i32 %77, 209
  %79 = icmp sgt i32 %78, 0
  br i1 %79, label %334, label %137

80:                                               ; preds = %299
  %81 = load ptr, ptr %6, align 8
  %82 = load i32, ptr %10, align 4
  %83 = sext i32 %82 to i64
  %84 = getelementptr inbounds %struct.Process, ptr %81, i64 %83
  %85 = getelementptr inbounds nuw %struct.Process, ptr %84, i32 0, i32 1
  %86 = load i32, ptr %85, align 4
  %87 = load i32, ptr %9, align 4
  %88 = icmp slt i32 %86, %87
  %89 = select i1 %88, i32 1931228280, i32 2075260102
  store i32 %89, ptr %5, align 4
  %90 = xor i32 %1, -278484285
  %91 = and i32 %1, %90
  %92 = or i32 %1, %90
  %93 = xor i32 %1, %90
  %94 = sub i32 %92, %93
  %95 = sub i32 %94, %91
  %96 = mul i32 %95, 51
  %97 = icmp ne i32 %96, 0
  br i1 %97, label %342, label %137

98:                                               ; preds = %283
  %99 = load ptr, ptr %6, align 8
  %100 = load i32, ptr %10, align 4
  %101 = sext i32 %100 to i64
  %102 = getelementptr inbounds %struct.Process, ptr %99, i64 %101
  %103 = getelementptr inbounds nuw %struct.Process, ptr %102, i32 0, i32 1
  %104 = load i32, ptr %103, align 4
  store i32 %104, ptr %9, align 4
  store i32 2075260102, ptr %5, align 4
  %105 = xor i32 %1, -1272117977
  %106 = and i32 %1, %105
  %107 = or i32 %1, %105
  %108 = xor i32 %1, %105
  %109 = mul i32 %107, 2
  %110 = sub i32 %109, %108
  %111 = sub i32 %110, %1
  %112 = sub i32 %111, %105
  %113 = mul i32 %112, 105
  %114 = icmp slt i32 %113, 0
  br i1 %114, label %351, label %137

115:                                              ; preds = %291
  %116 = load i32, ptr %10, align 4
  %117 = load i32, ptr %5, align 4
  %118 = xor i32 %117, 2075260103
  %119 = xor i32 %116, %118
  %120 = load i32, ptr %5, align 4
  %121 = xor i32 %120, 2075260103
  %122 = and i32 %116, %121
  %123 = add i32 %122, %122
  %124 = add i32 %119, %123
  store i32 %124, ptr %10, align 4
  store i32 -239902097, ptr %5, align 4
  %125 = xor i32 %1, 1608018167
  %126 = and i32 %1, %125
  %127 = or i32 %1, %125
  %128 = xor i32 %1, %125
  %129 = mul i32 %127, 2
  %130 = sub i32 %129, %128
  %131 = sub i32 %130, %1
  %132 = sub i32 %131, %125
  %133 = mul i32 %132, 124
  %134 = icmp sle i32 %133, 0
  br i1 %134, label %137, label %362

135:                                              ; preds = %275
  %136 = load i32, ptr %9, align 4
  ret i32 %136

137:                                              ; preds = %446, %438, %430, %421, %412, %403, %394, %384, %362, %351, %342, %334, %323, %315, %307, %250, %238, %218, %205, %194, %181, %168, %155, %115, %98, %80, %60, %42, %27, %16
  br label %11

138:                                              ; preds = %305, %303, %297, %295, %285, %283, %277, %275
  store i32 1395125456, ptr %5, align 4
  call void asm sideeffect "", ""()
  %139 = xor i32 %1, 1459677839
  %140 = and i32 %1, %139
  %141 = or i32 %1, %139
  %142 = xor i32 %1, %139
  %143 = sub i32 %141, %142
  %144 = sub i32 %143, %140
  %145 = mul i32 %144, 169
  %146 = xor i32 %1, 2110888043
  %147 = and i32 %1, %146
  %148 = or i32 %1, %146
  %149 = xor i32 %1, %146
  %150 = add i32 %147, %148
  %151 = sub i32 %150, %1
  %152 = sub i32 %151, %146
  %153 = mul i32 %152, 81
  %154 = icmp ne i32 %145, %153
  br i1 %154, label %373, label %11

155:                                              ; preds = %297
  %156 = load i32, ptr %5, align 4
  %157 = xor i32 %156, -712396501
  store i32 %157, ptr %5, align 4
  %158 = xor i32 %1, 595107743
  %159 = and i32 %1, %158
  %160 = or i32 %1, %158
  %161 = xor i32 %1, %158
  %162 = mul i32 %160, 2
  %163 = sub i32 %162, %161
  %164 = sub i32 %163, %1
  %165 = sub i32 %164, %158
  %166 = mul i32 %165, 101
  %167 = icmp ugt i32 %166, 0
  br i1 %167, label %384, label %137

168:                                              ; preds = %293
  %169 = load i32, ptr %5, align 4
  %170 = xor i32 %169, 1253782112
  store i32 %170, ptr %5, align 4
  %171 = xor i32 %1, -867066643
  %172 = and i32 %1, %171
  %173 = or i32 %1, %171
  %174 = xor i32 %1, %171
  %175 = mul i32 %173, 2
  %176 = sub i32 %175, %174
  %177 = sub i32 %176, %1
  %178 = sub i32 %177, %171
  %179 = mul i32 %178, 85
  %180 = icmp slt i32 %179, 0
  br i1 %180, label %394, label %137

181:                                              ; preds = %273
  %182 = load i32, ptr %5, align 4
  %183 = xor i32 %182, 438723031
  store i32 %183, ptr %5, align 4
  %184 = xor i32 %1, 1322770417
  %185 = and i32 %1, %184
  %186 = or i32 %1, %184
  %187 = xor i32 %1, %184
  %188 = add i32 %1, %184
  %189 = sub i32 %188, %187
  %190 = mul i32 %185, 2
  %191 = sub i32 %189, %190
  %192 = mul i32 %191, 32
  %193 = icmp uge i32 %192, 0
  br i1 %193, label %137, label %403

194:                                              ; preds = %305
  %195 = load i32, ptr %5, align 4
  %196 = xor i32 %195, -1519340599
  store i32 %196, ptr %5, align 4
  %197 = xor i32 %1, 131048649
  %198 = and i32 %1, %197
  %199 = or i32 %1, %197
  %200 = xor i32 %1, %197
  %201 = sub i32 %199, %200
  %202 = sub i32 %201, %198
  %203 = mul i32 %202, 235
  %204 = icmp slt i32 %203, 0
  br i1 %204, label %412, label %137

205:                                              ; preds = %279
  %206 = load i32, ptr %5, align 4
  %207 = xor i32 %206, -1947165355
  store i32 %207, ptr %5, align 4
  %208 = xor i32 %1, 484059877
  %209 = and i32 %1, %208
  %210 = or i32 %1, %208
  %211 = xor i32 %1, %208
  %212 = mul i32 %210, 2
  %213 = sub i32 %212, %211
  %214 = sub i32 %213, %1
  %215 = sub i32 %214, %208
  %216 = mul i32 %215, 184
  %217 = icmp ugt i32 %216, 0
  br i1 %217, label %421, label %137

218:                                              ; preds = %277
  %219 = load i32, ptr %5, align 4
  %220 = xor i32 %219, -274751039
  store i32 %220, ptr %5, align 4
  %221 = xor i32 %1, -677416631
  %222 = and i32 %1, %221
  %223 = or i32 %1, %221
  %224 = xor i32 %1, %221
  %225 = add i32 %222, %223
  %226 = sub i32 %225, %1
  %227 = sub i32 %226, %221
  %228 = mul i32 %227, 251
  %229 = xor i32 %1, -1760399993
  %230 = and i32 %1, %229
  %231 = or i32 %1, %229
  %232 = xor i32 %1, %229
  %233 = add i32 %230, %231
  %234 = sub i32 %233, %1
  %235 = sub i32 %234, %229
  %236 = mul i32 %235, 237
  %237 = icmp eq i32 %228, %236
  br i1 %237, label %137, label %430

238:                                              ; preds = %295
  %239 = load i32, ptr %5, align 4
  %240 = xor i32 %239, -1672591524
  store i32 %240, ptr %5, align 4
  %241 = xor i32 %1, 1370292723
  %242 = and i32 %1, %241
  %243 = or i32 %1, %241
  %244 = xor i32 %1, %241
  %245 = add i32 %242, %243
  %246 = sub i32 %245, %1
  %247 = sub i32 %246, %241
  %248 = mul i32 %247, 100
  %249 = icmp slt i32 %248, 0
  br i1 %249, label %438, label %137

250:                                              ; preds = %271
  %251 = load i32, ptr %5, align 4
  %252 = xor i32 %251, -648545714
  store i32 %252, ptr %5, align 4
  %253 = xor i32 %1, -1175521029
  %254 = and i32 %1, %253
  %255 = or i32 %1, %253
  %256 = xor i32 %1, %253
  %257 = mul i32 %255, 2
  %258 = sub i32 %257, %256
  %259 = sub i32 %258, %1
  %260 = sub i32 %259, %253
  %261 = mul i32 %260, 24
  %262 = icmp sgt i32 %261, 0
  br i1 %262, label %446, label %137

263:                                              ; preds = %11
  %264 = icmp slt i32 %14, 358263713
  br i1 %264, label %267, label %269

265:                                              ; preds = %11
  %266 = icmp slt i32 %14, 1255904129
  br i1 %266, label %287, label %289

267:                                              ; preds = %263
  %268 = icmp slt i32 %14, 281851214
  br i1 %268, label %271, label %273

269:                                              ; preds = %263
  %270 = icmp slt i32 %14, 451993708
  br i1 %270, label %279, label %281

271:                                              ; preds = %267
  %272 = icmp eq i32 %14, 179256265
  br i1 %272, label %250, label %275

273:                                              ; preds = %267
  %274 = icmp eq i32 %14, 281851214
  br i1 %274, label %181, label %277

275:                                              ; preds = %271
  %276 = icmp eq i32 %14, 236268670
  br i1 %276, label %135, label %138

277:                                              ; preds = %273
  %278 = icmp eq i32 %14, 313112955
  br i1 %278, label %218, label %138

279:                                              ; preds = %269
  %280 = icmp eq i32 %14, 358263713
  br i1 %280, label %205, label %283

281:                                              ; preds = %269
  %282 = icmp eq i32 %14, 451993708
  br i1 %282, label %60, label %285

283:                                              ; preds = %279
  %284 = icmp eq i32 %14, 431352959
  br i1 %284, label %98, label %138

285:                                              ; preds = %281
  %286 = icmp eq i32 %14, 569030471
  br i1 %286, label %16, label %138

287:                                              ; preds = %265
  %288 = icmp slt i32 %14, 857626387
  br i1 %288, label %291, label %293

289:                                              ; preds = %265
  %290 = icmp slt i32 %14, 1606875979
  br i1 %290, label %299, label %301

291:                                              ; preds = %287
  %292 = icmp eq i32 %14, 590369433
  br i1 %292, label %115, label %295

293:                                              ; preds = %287
  %294 = icmp eq i32 %14, 857626387
  br i1 %294, label %168, label %297

295:                                              ; preds = %291
  %296 = icmp eq i32 %14, 762466732
  br i1 %296, label %238, label %138

297:                                              ; preds = %293
  %298 = icmp eq i32 %14, 1132665959
  br i1 %298, label %155, label %138

299:                                              ; preds = %289
  %300 = icmp eq i32 %14, 1255904129
  br i1 %300, label %80, label %303

301:                                              ; preds = %289
  %302 = icmp eq i32 %14, 1606875979
  br i1 %302, label %42, label %305

303:                                              ; preds = %299
  %304 = icmp eq i32 %14, 1457211772
  br i1 %304, label %27, label %138

305:                                              ; preds = %301
  %306 = icmp eq i32 %14, 1973155020
  br i1 %306, label %194, label %138

307:                                              ; preds = %16
  %308 = load i64, ptr %4, align 8
  %309 = ptrtoint ptr %0 to i64
  %310 = zext i32 %1 to i64
  %311 = zext i32 %2 to i64
  %312 = sub i64 %311, %311
  %313 = or i64 %312, %310
  %314 = or i64 %313, %309
  store i64 %314, ptr %4, align 8
  br label %137

315:                                              ; preds = %27
  %316 = load i64, ptr %4, align 8
  %317 = ptrtoint ptr %0 to i64
  %318 = zext i32 %1 to i64
  %319 = zext i32 %2 to i64
  %320 = or i64 %317, %316
  %321 = or i64 %320, %317
  %322 = mul i64 %321, %319
  store i64 %322, ptr %4, align 8
  br label %137

323:                                              ; preds = %42
  %324 = load i64, ptr %4, align 8
  %325 = ptrtoint ptr %0 to i64
  %326 = zext i32 %1 to i64
  %327 = zext i32 %2 to i64
  %328 = add i64 %324, %326
  %329 = and i64 %328, %327
  %330 = and i64 %329, %325
  %331 = add i64 %330, %327
  %332 = xor i64 %331, %325
  %333 = add i64 %332, %324
  store i64 %333, ptr %4, align 8
  br label %137

334:                                              ; preds = %60
  %335 = load i64, ptr %4, align 8
  %336 = ptrtoint ptr %0 to i64
  %337 = zext i32 %1 to i64
  %338 = zext i32 %2 to i64
  %339 = or i64 %335, %338
  %340 = sub i64 %339, %338
  %341 = sub i64 %340, %337
  store i64 %341, ptr %4, align 8
  br label %137

342:                                              ; preds = %80
  %343 = load i64, ptr %4, align 8
  %344 = ptrtoint ptr %0 to i64
  %345 = zext i32 %1 to i64
  %346 = zext i32 %2 to i64
  %347 = xor i64 %345, %343
  %348 = or i64 %347, %343
  %349 = and i64 %348, %343
  %350 = and i64 %349, %346
  store i64 %350, ptr %4, align 8
  br label %137

351:                                              ; preds = %98
  %352 = load i64, ptr %4, align 8
  %353 = ptrtoint ptr %0 to i64
  %354 = zext i32 %1 to i64
  %355 = zext i32 %2 to i64
  %356 = mul i64 %353, %354
  %357 = mul i64 %356, %352
  %358 = or i64 %357, %354
  %359 = sub i64 %358, %354
  %360 = and i64 %359, %354
  %361 = and i64 %360, %353
  store i64 %361, ptr %4, align 8
  br label %137

362:                                              ; preds = %115
  %363 = load i64, ptr %4, align 8
  %364 = ptrtoint ptr %0 to i64
  %365 = zext i32 %1 to i64
  %366 = zext i32 %2 to i64
  %367 = xor i64 %363, %365
  %368 = mul i64 %367, %365
  %369 = and i64 %368, %363
  %370 = add i64 %369, %366
  %371 = add i64 %370, %365
  %372 = sub i64 %371, %364
  store i64 %372, ptr %4, align 8
  br label %137

373:                                              ; preds = %138
  %374 = load i64, ptr %4, align 8
  %375 = ptrtoint ptr %0 to i64
  %376 = zext i32 %1 to i64
  %377 = zext i32 %2 to i64
  %378 = xor i64 %376, %377
  %379 = and i64 %378, %374
  %380 = xor i64 %379, %375
  %381 = mul i64 %380, %376
  %382 = and i64 %381, %375
  %383 = sub i64 %382, %376
  store i64 %383, ptr %4, align 8
  br label %11

384:                                              ; preds = %155
  %385 = load i64, ptr %4, align 8
  %386 = ptrtoint ptr %0 to i64
  %387 = zext i32 %1 to i64
  %388 = zext i32 %2 to i64
  %389 = xor i64 %386, %386
  %390 = mul i64 %389, %388
  %391 = mul i64 %390, %387
  %392 = and i64 %391, %386
  %393 = or i64 %392, %388
  store i64 %393, ptr %4, align 8
  br label %137

394:                                              ; preds = %168
  %395 = load i64, ptr %4, align 8
  %396 = ptrtoint ptr %0 to i64
  %397 = zext i32 %1 to i64
  %398 = zext i32 %2 to i64
  %399 = or i64 %398, %395
  %400 = or i64 %399, %397
  %401 = sub i64 %400, %395
  %402 = add i64 %401, %398
  store i64 %402, ptr %4, align 8
  br label %137

403:                                              ; preds = %181
  %404 = load i64, ptr %4, align 8
  %405 = ptrtoint ptr %0 to i64
  %406 = zext i32 %1 to i64
  %407 = zext i32 %2 to i64
  %408 = add i64 %405, %404
  %409 = add i64 %408, %404
  %410 = sub i64 %409, %404
  %411 = xor i64 %410, %407
  store i64 %411, ptr %4, align 8
  br label %137

412:                                              ; preds = %194
  %413 = load i64, ptr %4, align 8
  %414 = ptrtoint ptr %0 to i64
  %415 = zext i32 %1 to i64
  %416 = zext i32 %2 to i64
  %417 = or i64 %413, %413
  %418 = sub i64 %417, %414
  %419 = sub i64 %418, %416
  %420 = mul i64 %419, %413
  store i64 %420, ptr %4, align 8
  br label %137

421:                                              ; preds = %205
  %422 = load i64, ptr %4, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = zext i32 %1 to i64
  %425 = zext i32 %2 to i64
  %426 = add i64 %423, %422
  %427 = add i64 %426, %425
  %428 = xor i64 %427, %423
  %429 = sub i64 %428, %422
  store i64 %429, ptr %4, align 8
  br label %137

430:                                              ; preds = %218
  %431 = load i64, ptr %4, align 8
  %432 = ptrtoint ptr %0 to i64
  %433 = zext i32 %1 to i64
  %434 = zext i32 %2 to i64
  %435 = and i64 %434, %433
  %436 = mul i64 %435, %434
  %437 = or i64 %436, %432
  store i64 %437, ptr %4, align 8
  br label %137

438:                                              ; preds = %238
  %439 = load i64, ptr %4, align 8
  %440 = ptrtoint ptr %0 to i64
  %441 = zext i32 %1 to i64
  %442 = zext i32 %2 to i64
  %443 = or i64 %442, %442
  %444 = add i64 %443, %441
  %445 = or i64 %444, %439
  store i64 %445, ptr %4, align 8
  br label %137

446:                                              ; preds = %250
  %447 = load i64, ptr %4, align 8
  %448 = ptrtoint ptr %0 to i64
  %449 = zext i32 %1 to i64
  %450 = zext i32 %2 to i64
  %451 = or i64 %449, %448
  %452 = or i64 %451, %450
  %453 = mul i64 %452, %447
  %454 = xor i64 %453, %447
  store i64 %454, ptr %4, align 8
  br label %137
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @simulate(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  store i32 3092684, ptr %5, align 4
  br label %13

13:                                               ; preds = %497, %242, %241, %3
  %14 = load i32, ptr %5, align 4
  %15 = sub i32 %14, 517998071
  %16 = mul i32 %15, -573942087
  %17 = icmp slt i32 %16, 770437268
  br i1 %17, label %360, label %362

18:                                               ; preds = %376
  store ptr %0, ptr %6, align 8
  store i32 %1, ptr %7, align 4
  store ptr %2, ptr %8, align 8
  store i32 0, ptr %9, align 4
  store i32 0, ptr %10, align 4
  store i32 1217098027, ptr %5, align 4
  %19 = xor i32 %1, 392720147
  %20 = and i32 %1, %19
  %21 = or i32 %1, %19
  %22 = xor i32 %1, %19
  %23 = mul i32 %21, 2
  %24 = sub i32 %23, %22
  %25 = sub i32 %24, %1
  %26 = sub i32 %25, %19
  %27 = mul i32 %26, 154
  %28 = icmp sgt i32 %27, 0
  br i1 %28, label %412, label %241

29:                                               ; preds = %392
  %30 = load i32, ptr %9, align 4
  %31 = load i32, ptr %7, align 4
  %32 = icmp slt i32 %30, %31
  %33 = select i1 %32, i32 1555355683, i32 152464111
  store i32 %33, ptr %5, align 4
  %34 = xor i32 %1, -1502398055
  %35 = and i32 %1, %34
  %36 = or i32 %1, %34
  %37 = xor i32 %1, %34
  %38 = mul i32 %36, 2
  %39 = sub i32 %38, %37
  %40 = sub i32 %39, %1
  %41 = sub i32 %40, %34
  %42 = mul i32 %41, 227
  %43 = icmp sle i32 %42, 0
  br i1 %43, label %241, label %421

44:                                               ; preds = %368
  %45 = load ptr, ptr %6, align 8
  %46 = load i32, ptr %7, align 4
  %47 = load i32, ptr %10, align 4
  %48 = call i32 @chooseProcess(ptr noundef %45, i32 noundef %46, i32 noundef %47)
  store i32 %48, ptr %11, align 4
  %49 = load i32, ptr %11, align 4
  %50 = icmp eq i32 %49, -1
  %51 = select i1 %50, i32 -1905080601, i32 -770872643
  store i32 %51, ptr %5, align 4
  %52 = xor i32 %1, 1542731135
  %53 = and i32 %1, %52
  %54 = or i32 %1, %52
  %55 = xor i32 %1, %52
  %56 = sub i32 %54, %55
  %57 = sub i32 %56, %53
  %58 = mul i32 %57, 147
  %59 = xor i32 %1, -413078109
  %60 = and i32 %1, %59
  %61 = or i32 %1, %59
  %62 = xor i32 %1, %59
  %63 = mul i32 %61, 2
  %64 = sub i32 %63, %62
  %65 = sub i32 %64, %1
  %66 = sub i32 %65, %59
  %67 = mul i32 %66, 171
  %68 = icmp eq i32 %58, %67
  br i1 %68, label %241, label %432

69:                                               ; preds = %408
  %70 = load ptr, ptr %6, align 8
  %71 = load i32, ptr %7, align 4
  %72 = load i32, ptr %10, align 4
  %73 = call i32 @nextArrival(ptr noundef %70, i32 noundef %71, i32 noundef %72)
  store i32 %73, ptr %12, align 4
  %74 = load ptr, ptr %8, align 8
  %75 = load i32, ptr %10, align 4
  %76 = load i32, ptr %12, align 4
  call void @addSegment(ptr noundef %74, i32 noundef 0, i32 noundef %75, i32 noundef %76)
  %77 = load i32, ptr %12, align 4
  store i32 %77, ptr %10, align 4
  store i32 1217098027, ptr %5, align 4
  %78 = xor i32 %1, -1835158459
  %79 = and i32 %1, %78
  %80 = or i32 %1, %78
  %81 = xor i32 %1, %78
  %82 = mul i32 %80, 2
  %83 = sub i32 %82, %81
  %84 = sub i32 %83, %1
  %85 = sub i32 %84, %78
  %86 = mul i32 %85, 172
  %87 = icmp sle i32 %86, 0
  br i1 %87, label %241, label %443

88:                                               ; preds = %386
  %89 = load ptr, ptr %6, align 8
  %90 = load i32, ptr %11, align 4
  %91 = sext i32 %90 to i64
  %92 = getelementptr inbounds %struct.Process, ptr %89, i64 %91
  %93 = getelementptr inbounds nuw %struct.Process, ptr %92, i32 0, i32 7
  %94 = load i32, ptr %93, align 4
  %95 = icmp eq i32 %94, -1
  %96 = select i1 %95, i32 1196026581, i32 706868147
  store i32 %96, ptr %5, align 4
  %97 = xor i32 %1, 995407121
  %98 = and i32 %1, %97
  %99 = or i32 %1, %97
  %100 = xor i32 %1, %97
  %101 = add i32 %1, %97
  %102 = sub i32 %101, %100
  %103 = mul i32 %98, 2
  %104 = sub i32 %102, %103
  %105 = mul i32 %104, 80
  %106 = icmp eq i32 %105, 0
  br i1 %106, label %241, label %451

107:                                              ; preds = %372
  %108 = load i32, ptr %10, align 4
  %109 = load ptr, ptr %6, align 8
  %110 = load i32, ptr %11, align 4
  %111 = sext i32 %110 to i64
  %112 = getelementptr inbounds %struct.Process, ptr %109, i64 %111
  %113 = getelementptr inbounds nuw %struct.Process, ptr %112, i32 0, i32 7
  store i32 %108, ptr %113, align 4
  store i32 706868147, ptr %5, align 4
  %114 = xor i32 %1, 980413881
  %115 = and i32 %1, %114
  %116 = or i32 %1, %114
  %117 = xor i32 %1, %114
  %118 = add i32 %115, %116
  %119 = sub i32 %118, %1
  %120 = sub i32 %119, %114
  %121 = mul i32 %120, 96
  %122 = icmp sgt i32 %121, 0
  br i1 %122, label %461, label %241

123:                                              ; preds = %384
  %124 = load ptr, ptr %8, align 8
  %125 = load ptr, ptr %6, align 8
  %126 = load i32, ptr %11, align 4
  %127 = sext i32 %126 to i64
  %128 = getelementptr inbounds %struct.Process, ptr %125, i64 %127
  %129 = getelementptr inbounds nuw %struct.Process, ptr %128, i32 0, i32 0
  %130 = load i32, ptr %129, align 4
  %131 = load i32, ptr %10, align 4
  %132 = load i32, ptr %10, align 4
  %133 = load i32, ptr %5, align 4
  %134 = xor i32 %133, 706868146
  %135 = or i32 %132, %134
  %136 = load i32, ptr %5, align 4
  %137 = xor i32 %136, 706868146
  %138 = and i32 %132, %137
  %139 = add i32 %135, %138
  call void @addSegment(ptr noundef %124, i32 noundef %130, i32 noundef %131, i32 noundef %139)
  %140 = load ptr, ptr %6, align 8
  %141 = load i32, ptr %11, align 4
  %142 = sext i32 %141 to i64
  %143 = getelementptr inbounds %struct.Process, ptr %140, i64 %142
  %144 = getelementptr inbounds nuw %struct.Process, ptr %143, i32 0, i32 3
  %145 = load i32, ptr %144, align 4
  %146 = load i32, ptr %5, align 4
  %147 = xor i32 %146, -706868148
  %148 = xor i32 %145, %147
  %149 = load i32, ptr %5, align 4
  %150 = xor i32 %149, -706868148
  %151 = and i32 %145, %150
  %152 = add i32 %151, %151
  %153 = add i32 %148, %152
  store i32 %153, ptr %144, align 4
  %154 = load ptr, ptr %6, align 8
  %155 = load i32, ptr %11, align 4
  %156 = sext i32 %155 to i64
  %157 = getelementptr inbounds %struct.Process, ptr %154, i64 %156
  %158 = getelementptr inbounds nuw %struct.Process, ptr %157, i32 0, i32 4
  %159 = load i32, ptr %158, align 4
  %160 = load i32, ptr %5, align 4
  %161 = xor i32 %160, 706868146
  %162 = xor i32 %159, %161
  %163 = load i32, ptr %5, align 4
  %164 = xor i32 %163, 706868146
  %165 = and i32 %159, %164
  %166 = add i32 %165, %165
  %167 = add i32 %162, %166
  store i32 %167, ptr %158, align 4
  %168 = load i32, ptr %10, align 4
  %169 = load i32, ptr %5, align 4
  %170 = xor i32 %169, 706868146
  %171 = or i32 %168, %170
  %172 = load i32, ptr %5, align 4
  %173 = xor i32 %172, 706868146
  %174 = and i32 %168, %173
  %175 = add i32 %171, %174
  store i32 %175, ptr %10, align 4
  %176 = load ptr, ptr %6, align 8
  %177 = load i32, ptr %11, align 4
  %178 = sext i32 %177 to i64
  %179 = getelementptr inbounds %struct.Process, ptr %176, i64 %178
  %180 = getelementptr inbounds nuw %struct.Process, ptr %179, i32 0, i32 3
  %181 = load i32, ptr %180, align 4
  %182 = icmp eq i32 %181, 0
  %183 = select i1 %182, i32 -675173804, i32 1948282726
  store i32 %183, ptr %5, align 4
  %184 = xor i32 %1, 815165569
  %185 = and i32 %1, %184
  %186 = or i32 %1, %184
  %187 = xor i32 %1, %184
  %188 = add i32 %185, %186
  %189 = sub i32 %188, %1
  %190 = sub i32 %189, %184
  %191 = mul i32 %190, 167
  %192 = xor i32 %1, -1370062095
  %193 = and i32 %1, %192
  %194 = or i32 %1, %192
  %195 = xor i32 %1, %192
  %196 = add i32 %193, %194
  %197 = sub i32 %196, %1
  %198 = sub i32 %197, %192
  %199 = mul i32 %198, 140
  %200 = icmp eq i32 %191, %199
  br i1 %200, label %241, label %469

201:                                              ; preds = %410
  %202 = load i32, ptr %10, align 4
  %203 = load ptr, ptr %6, align 8
  %204 = load i32, ptr %11, align 4
  %205 = sext i32 %204 to i64
  %206 = getelementptr inbounds %struct.Process, ptr %203, i64 %205
  %207 = getelementptr inbounds nuw %struct.Process, ptr %206, i32 0, i32 8
  store i32 %202, ptr %207, align 4
  %208 = load i32, ptr %9, align 4
  %209 = load i32, ptr %5, align 4
  %210 = xor i32 %209, -675173803
  %211 = sub i32 %208, %210
  %212 = load i32, ptr %5, align 4
  %213 = xor i32 %212, -675173802
  %214 = mul i32 %208, %213
  %215 = load i32, ptr %5, align 4
  %216 = xor i32 %215, -675173803
  %217 = mul i32 %216, %211
  %218 = sub i32 %214, %217
  store i32 %218, ptr %9, align 4
  store i32 1948282726, ptr %5, align 4
  %219 = xor i32 %1, -1195725301
  %220 = and i32 %1, %219
  %221 = or i32 %1, %219
  %222 = xor i32 %1, %219
  %223 = mul i32 %221, 2
  %224 = sub i32 %223, %222
  %225 = sub i32 %224, %1
  %226 = sub i32 %225, %219
  %227 = mul i32 %226, 119
  %228 = icmp eq i32 %227, 0
  br i1 %228, label %241, label %479

229:                                              ; preds = %404
  store i32 1217098027, ptr %5, align 4
  %230 = xor i32 %1, -1386108099
  %231 = and i32 %1, %230
  %232 = or i32 %1, %230
  %233 = xor i32 %1, %230
  %234 = add i32 %1, %230
  %235 = sub i32 %234, %233
  %236 = mul i32 %231, 2
  %237 = sub i32 %235, %236
  %238 = mul i32 %237, 91
  %239 = icmp ugt i32 %238, 0
  br i1 %239, label %488, label %241

240:                                              ; preds = %406
  ret void

241:                                              ; preds = %574, %564, %555, %547, %537, %528, %519, %508, %488, %479, %469, %461, %451, %443, %432, %421, %412, %349, %336, %324, %311, %290, %278, %265, %252, %229, %201, %123, %107, %88, %69, %44, %29, %18
  br label %13

242:                                              ; preds = %410, %406, %404, %398, %396, %386, %382, %380, %374, %372
  store i32 3092684, ptr %5, align 4
  call void asm sideeffect "", ""()
  %243 = xor i32 %1, -340902903
  %244 = and i32 %1, %243
  %245 = or i32 %1, %243
  %246 = xor i32 %1, %243
  %247 = add i32 %244, %245
  %248 = sub i32 %247, %1
  %249 = sub i32 %248, %243
  %250 = mul i32 %249, 121
  %251 = icmp uge i32 %250, 0
  br i1 %251, label %13, label %497

252:                                              ; preds = %374
  %253 = load i32, ptr %5, align 4
  %254 = xor i32 %253, 1892830545
  store i32 %254, ptr %5, align 4
  %255 = xor i32 %1, -1059791599
  %256 = and i32 %1, %255
  %257 = or i32 %1, %255
  %258 = xor i32 %1, %255
  %259 = mul i32 %257, 2
  %260 = sub i32 %259, %258
  %261 = sub i32 %260, %1
  %262 = sub i32 %261, %255
  %263 = mul i32 %262, 19
  %264 = icmp sle i32 %263, 0
  br i1 %264, label %241, label %508

265:                                              ; preds = %396
  %266 = load i32, ptr %5, align 4
  %267 = xor i32 %266, 969657548
  store i32 %267, ptr %5, align 4
  %268 = xor i32 %1, -1500203967
  %269 = and i32 %1, %268
  %270 = or i32 %1, %268
  %271 = xor i32 %1, %268
  %272 = mul i32 %270, 2
  %273 = sub i32 %272, %271
  %274 = sub i32 %273, %1
  %275 = sub i32 %274, %268
  %276 = mul i32 %275, 107
  %277 = icmp slt i32 %276, 0
  br i1 %277, label %519, label %241

278:                                              ; preds = %394
  %279 = load i32, ptr %5, align 4
  %280 = xor i32 %279, 800204605
  store i32 %280, ptr %5, align 4
  %281 = xor i32 %1, 367687823
  %282 = and i32 %1, %281
  %283 = or i32 %1, %281
  %284 = xor i32 %1, %281
  %285 = add i32 %282, %283
  %286 = sub i32 %285, %1
  %287 = sub i32 %286, %281
  %288 = mul i32 %287, 146
  %289 = icmp slt i32 %288, 0
  br i1 %289, label %528, label %241

290:                                              ; preds = %400
  %291 = load i32, ptr %5, align 4
  %292 = xor i32 %291, -679543568
  store i32 %292, ptr %5, align 4
  %293 = xor i32 %1, 93228185
  %294 = and i32 %1, %293
  %295 = or i32 %1, %293
  %296 = xor i32 %1, %293
  %297 = add i32 %1, %293
  %298 = sub i32 %297, %296
  %299 = mul i32 %294, 2
  %300 = sub i32 %298, %299
  %301 = mul i32 %300, 134
  %302 = xor i32 %1, -773765647
  %303 = and i32 %1, %302
  %304 = or i32 %1, %302
  %305 = xor i32 %1, %302
  %306 = add i32 %303, %304
  %307 = sub i32 %306, %1
  %308 = sub i32 %307, %302
  %309 = mul i32 %308, 235
  %310 = icmp eq i32 %301, %309
  br i1 %310, label %241, label %537

311:                                              ; preds = %398
  %312 = load i32, ptr %5, align 4
  %313 = xor i32 %312, -547652854
  store i32 %313, ptr %5, align 4
  %314 = xor i32 %1, -1659582553
  %315 = and i32 %1, %314
  %316 = or i32 %1, %314
  %317 = xor i32 %1, %314
  %318 = mul i32 %316, 2
  %319 = sub i32 %318, %317
  %320 = sub i32 %319, %1
  %321 = sub i32 %320, %314
  %322 = mul i32 %321, 164
  %323 = icmp slt i32 %322, 0
  br i1 %323, label %547, label %241

324:                                              ; preds = %380
  %325 = load i32, ptr %5, align 4
  %326 = xor i32 %325, 289354649
  store i32 %326, ptr %5, align 4
  %327 = xor i32 %1, 1989227387
  %328 = and i32 %1, %327
  %329 = or i32 %1, %327
  %330 = xor i32 %1, %327
  %331 = add i32 %328, %329
  %332 = sub i32 %331, %1
  %333 = sub i32 %332, %327
  %334 = mul i32 %333, 190
  %335 = icmp ugt i32 %334, 0
  br i1 %335, label %555, label %241

336:                                              ; preds = %370
  %337 = load i32, ptr %5, align 4
  %338 = xor i32 %337, 1859344510
  store i32 %338, ptr %5, align 4
  %339 = xor i32 %1, 1785887213
  %340 = and i32 %1, %339
  %341 = or i32 %1, %339
  %342 = xor i32 %1, %339
  %343 = mul i32 %341, 2
  %344 = sub i32 %343, %342
  %345 = sub i32 %344, %1
  %346 = sub i32 %345, %339
  %347 = mul i32 %346, 138
  %348 = icmp slt i32 %347, 0
  br i1 %348, label %564, label %241

349:                                              ; preds = %382
  %350 = load i32, ptr %5, align 4
  %351 = xor i32 %350, 19460011
  store i32 %351, ptr %5, align 4
  %352 = xor i32 %1, 500885151
  %353 = and i32 %1, %352
  %354 = or i32 %1, %352
  %355 = xor i32 %1, %352
  %356 = sub i32 %354, %355
  %357 = sub i32 %356, %353
  %358 = mul i32 %357, 208
  %359 = icmp eq i32 %358, 0
  br i1 %359, label %241, label %574

360:                                              ; preds = %13
  %361 = icmp slt i32 %16, 397115885
  br i1 %361, label %364, label %366

362:                                              ; preds = %13
  %363 = icmp slt i32 %16, 1096455915
  br i1 %363, label %388, label %390

364:                                              ; preds = %360
  %365 = icmp slt i32 %16, 84339713
  br i1 %365, label %368, label %370

366:                                              ; preds = %360
  %367 = icmp slt i32 %16, 713927718
  br i1 %367, label %376, label %378

368:                                              ; preds = %364
  %369 = icmp eq i32 %16, 2009548
  br i1 %369, label %44, label %372

370:                                              ; preds = %364
  %371 = icmp eq i32 %16, 84339713
  br i1 %371, label %336, label %374

372:                                              ; preds = %368
  %373 = icmp eq i32 %16, 76871790
  br i1 %373, label %107, label %242

374:                                              ; preds = %370
  %375 = icmp eq i32 %16, 197207116
  br i1 %375, label %252, label %242

376:                                              ; preds = %366
  %377 = icmp eq i32 %16, 397115885
  br i1 %377, label %18, label %380

378:                                              ; preds = %366
  %379 = icmp slt i32 %16, 718927068
  br i1 %379, label %382, label %384

380:                                              ; preds = %376
  %381 = icmp eq i32 %16, 516333119
  br i1 %381, label %324, label %242

382:                                              ; preds = %378
  %383 = icmp eq i32 %16, 713927718
  br i1 %383, label %349, label %242

384:                                              ; preds = %378
  %385 = icmp eq i32 %16, 718927068
  br i1 %385, label %123, label %386

386:                                              ; preds = %384
  %387 = icmp eq i32 %16, 769939222
  br i1 %387, label %88, label %242

388:                                              ; preds = %362
  %389 = icmp slt i32 %16, 976385007
  br i1 %389, label %392, label %394

390:                                              ; preds = %362
  %391 = icmp slt i32 %16, 1256867640
  br i1 %391, label %400, label %402

392:                                              ; preds = %388
  %393 = icmp eq i32 %16, 770437268
  br i1 %393, label %29, label %396

394:                                              ; preds = %388
  %395 = icmp eq i32 %16, 976385007
  br i1 %395, label %278, label %398

396:                                              ; preds = %392
  %397 = icmp eq i32 %16, 926877671
  br i1 %397, label %265, label %242

398:                                              ; preds = %394
  %399 = icmp eq i32 %16, 1041303944
  br i1 %399, label %311, label %242

400:                                              ; preds = %390
  %401 = icmp eq i32 %16, 1096455915
  br i1 %401, label %290, label %404

402:                                              ; preds = %390
  %403 = icmp slt i32 %16, 1530793328
  br i1 %403, label %406, label %408

404:                                              ; preds = %400
  %405 = icmp eq i32 %16, 1133345591
  br i1 %405, label %229, label %242

406:                                              ; preds = %402
  %407 = icmp eq i32 %16, 1256867640
  br i1 %407, label %240, label %242

408:                                              ; preds = %402
  %409 = icmp eq i32 %16, 1530793328
  br i1 %409, label %69, label %410

410:                                              ; preds = %408
  %411 = icmp eq i32 %16, 1655244085
  br i1 %411, label %201, label %242

412:                                              ; preds = %18
  %413 = load i64, ptr %4, align 8
  %414 = ptrtoint ptr %0 to i64
  %415 = zext i32 %1 to i64
  %416 = ptrtoint ptr %2 to i64
  %417 = add i64 %415, %413
  %418 = mul i64 %417, %415
  %419 = or i64 %418, %416
  %420 = and i64 %419, %413
  store i64 %420, ptr %4, align 8
  br label %241

421:                                              ; preds = %29
  %422 = load i64, ptr %4, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = zext i32 %1 to i64
  %425 = ptrtoint ptr %2 to i64
  %426 = sub i64 %424, %423
  %427 = xor i64 %426, %424
  %428 = add i64 %427, %424
  %429 = sub i64 %428, %425
  %430 = xor i64 %429, %425
  %431 = mul i64 %430, %423
  store i64 %431, ptr %4, align 8
  br label %241

432:                                              ; preds = %44
  %433 = load i64, ptr %4, align 8
  %434 = ptrtoint ptr %0 to i64
  %435 = zext i32 %1 to i64
  %436 = ptrtoint ptr %2 to i64
  %437 = sub i64 %436, %435
  %438 = sub i64 %437, %434
  %439 = xor i64 %438, %434
  %440 = sub i64 %439, %433
  %441 = add i64 %440, %435
  %442 = or i64 %441, %436
  store i64 %442, ptr %4, align 8
  br label %241

443:                                              ; preds = %69
  %444 = load i64, ptr %4, align 8
  %445 = ptrtoint ptr %0 to i64
  %446 = zext i32 %1 to i64
  %447 = ptrtoint ptr %2 to i64
  %448 = sub i64 %444, %444
  %449 = add i64 %448, %444
  %450 = add i64 %449, %445
  store i64 %450, ptr %4, align 8
  br label %241

451:                                              ; preds = %88
  %452 = load i64, ptr %4, align 8
  %453 = ptrtoint ptr %0 to i64
  %454 = zext i32 %1 to i64
  %455 = ptrtoint ptr %2 to i64
  %456 = or i64 %452, %453
  %457 = mul i64 %456, %453
  %458 = and i64 %457, %453
  %459 = add i64 %458, %455
  %460 = or i64 %459, %452
  store i64 %460, ptr %4, align 8
  br label %241

461:                                              ; preds = %107
  %462 = load i64, ptr %4, align 8
  %463 = ptrtoint ptr %0 to i64
  %464 = zext i32 %1 to i64
  %465 = ptrtoint ptr %2 to i64
  %466 = xor i64 %462, %464
  %467 = sub i64 %466, %465
  %468 = xor i64 %467, %462
  store i64 %468, ptr %4, align 8
  br label %241

469:                                              ; preds = %123
  %470 = load i64, ptr %4, align 8
  %471 = ptrtoint ptr %0 to i64
  %472 = zext i32 %1 to i64
  %473 = ptrtoint ptr %2 to i64
  %474 = and i64 %471, %473
  %475 = or i64 %474, %471
  %476 = xor i64 %475, %471
  %477 = and i64 %476, %472
  %478 = mul i64 %477, %470
  store i64 %478, ptr %4, align 8
  br label %241

479:                                              ; preds = %201
  %480 = load i64, ptr %4, align 8
  %481 = ptrtoint ptr %0 to i64
  %482 = zext i32 %1 to i64
  %483 = ptrtoint ptr %2 to i64
  %484 = xor i64 %481, %480
  %485 = add i64 %484, %483
  %486 = add i64 %485, %483
  %487 = sub i64 %486, %482
  store i64 %487, ptr %4, align 8
  br label %241

488:                                              ; preds = %229
  %489 = load i64, ptr %4, align 8
  %490 = ptrtoint ptr %0 to i64
  %491 = zext i32 %1 to i64
  %492 = ptrtoint ptr %2 to i64
  %493 = sub i64 %490, %490
  %494 = and i64 %493, %491
  %495 = and i64 %494, %492
  %496 = or i64 %495, %489
  store i64 %496, ptr %4, align 8
  br label %241

497:                                              ; preds = %242
  %498 = load i64, ptr %4, align 8
  %499 = ptrtoint ptr %0 to i64
  %500 = zext i32 %1 to i64
  %501 = ptrtoint ptr %2 to i64
  %502 = add i64 %500, %500
  %503 = xor i64 %502, %499
  %504 = xor i64 %503, %501
  %505 = or i64 %504, %499
  %506 = or i64 %505, %501
  %507 = xor i64 %506, %501
  store i64 %507, ptr %4, align 8
  br label %13

508:                                              ; preds = %252
  %509 = load i64, ptr %4, align 8
  %510 = ptrtoint ptr %0 to i64
  %511 = zext i32 %1 to i64
  %512 = ptrtoint ptr %2 to i64
  %513 = add i64 %509, %511
  %514 = or i64 %513, %509
  %515 = add i64 %514, %509
  %516 = and i64 %515, %512
  %517 = or i64 %516, %512
  %518 = or i64 %517, %511
  store i64 %518, ptr %4, align 8
  br label %241

519:                                              ; preds = %265
  %520 = load i64, ptr %4, align 8
  %521 = ptrtoint ptr %0 to i64
  %522 = zext i32 %1 to i64
  %523 = ptrtoint ptr %2 to i64
  %524 = mul i64 %521, %520
  %525 = or i64 %524, %522
  %526 = sub i64 %525, %520
  %527 = add i64 %526, %522
  store i64 %527, ptr %4, align 8
  br label %241

528:                                              ; preds = %278
  %529 = load i64, ptr %4, align 8
  %530 = ptrtoint ptr %0 to i64
  %531 = zext i32 %1 to i64
  %532 = ptrtoint ptr %2 to i64
  %533 = mul i64 %532, %529
  %534 = xor i64 %533, %530
  %535 = or i64 %534, %529
  %536 = add i64 %535, %532
  store i64 %536, ptr %4, align 8
  br label %241

537:                                              ; preds = %290
  %538 = load i64, ptr %4, align 8
  %539 = ptrtoint ptr %0 to i64
  %540 = zext i32 %1 to i64
  %541 = ptrtoint ptr %2 to i64
  %542 = and i64 %540, %539
  %543 = xor i64 %542, %538
  %544 = mul i64 %543, %540
  %545 = sub i64 %544, %541
  %546 = sub i64 %545, %541
  store i64 %546, ptr %4, align 8
  br label %241

547:                                              ; preds = %311
  %548 = load i64, ptr %4, align 8
  %549 = ptrtoint ptr %0 to i64
  %550 = zext i32 %1 to i64
  %551 = ptrtoint ptr %2 to i64
  %552 = and i64 %549, %551
  %553 = or i64 %552, %551
  %554 = xor i64 %553, %550
  store i64 %554, ptr %4, align 8
  br label %241

555:                                              ; preds = %324
  %556 = load i64, ptr %4, align 8
  %557 = ptrtoint ptr %0 to i64
  %558 = zext i32 %1 to i64
  %559 = ptrtoint ptr %2 to i64
  %560 = and i64 %557, %559
  %561 = xor i64 %560, %556
  %562 = or i64 %561, %557
  %563 = or i64 %562, %558
  store i64 %563, ptr %4, align 8
  br label %241

564:                                              ; preds = %336
  %565 = load i64, ptr %4, align 8
  %566 = ptrtoint ptr %0 to i64
  %567 = zext i32 %1 to i64
  %568 = ptrtoint ptr %2 to i64
  %569 = or i64 %567, %567
  %570 = or i64 %569, %567
  %571 = xor i64 %570, %566
  %572 = sub i64 %571, %567
  %573 = xor i64 %572, %565
  store i64 %573, ptr %4, align 8
  br label %241

574:                                              ; preds = %349
  %575 = load i64, ptr %4, align 8
  %576 = ptrtoint ptr %0 to i64
  %577 = zext i32 %1 to i64
  %578 = ptrtoint ptr %2 to i64
  %579 = add i64 %575, %575
  %580 = or i64 %579, %577
  %581 = or i64 %580, %575
  %582 = add i64 %581, %575
  store i64 %582, ptr %4, align 8
  br label %241
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printProcessTable(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 -600766069, ptr %4, align 4
  br label %8

8:                                                ; preds = %189, %97, %96, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -1088726609
  %11 = mul i32 %10, 352139375
  switch i32 %11, label %97 [
    i32 1464557668, label %12
    i32 1707029922, label %25
    i32 117142819, label %38
    i32 1296666703, label %95
    i32 1698879693, label %117
    i32 651104730, label %128
    i32 644479188, label %139
    i32 1507617483, label %152
  ]

12:                                               ; preds = %8
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %13 = call i32 (ptr, ...) @printf(ptr noundef @.str)
  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str.1)
  store i32 0, ptr %7, align 4
  store i32 -637117651, ptr %4, align 4
  %15 = xor i32 %1, 261860783
  %16 = and i32 %1, %15
  %17 = or i32 %1, %15
  %18 = xor i32 %1, %15
  %19 = add i32 %1, %15
  %20 = sub i32 %19, %18
  %21 = mul i32 %16, 2
  %22 = sub i32 %20, %21
  %23 = mul i32 %22, 185
  %24 = icmp ugt i32 %23, 0
  br i1 %24, label %165, label %96

25:                                               ; preds = %8
  %26 = load i32, ptr %7, align 4
  %27 = load i32, ptr %6, align 4
  %28 = icmp slt i32 %26, %27
  %29 = select i1 %28, i32 566098492, i32 -1435783216
  store i32 %29, ptr %4, align 4
  %30 = xor i32 %1, -1129385189
  %31 = and i32 %1, %30
  %32 = or i32 %1, %30
  %33 = xor i32 %1, %30
  %34 = sub i32 %32, %33
  %35 = sub i32 %34, %31
  %36 = mul i32 %35, 121
  %37 = icmp sle i32 %36, 0
  br i1 %37, label %96, label %172

38:                                               ; preds = %8
  %39 = load ptr, ptr %5, align 8
  %40 = load i32, ptr %7, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds %struct.Process, ptr %39, i64 %41
  %43 = getelementptr inbounds nuw %struct.Process, ptr %42, i32 0, i32 0
  %44 = load i32, ptr %43, align 4
  %45 = load ptr, ptr %5, align 8
  %46 = load i32, ptr %7, align 4
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds %struct.Process, ptr %45, i64 %47
  %49 = getelementptr inbounds nuw %struct.Process, ptr %48, i32 0, i32 1
  %50 = load i32, ptr %49, align 4
  %51 = load ptr, ptr %5, align 8
  %52 = load i32, ptr %7, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds %struct.Process, ptr %51, i64 %53
  %55 = getelementptr inbounds nuw %struct.Process, ptr %54, i32 0, i32 2
  %56 = load i32, ptr %55, align 4
  %57 = load ptr, ptr %5, align 8
  %58 = load i32, ptr %7, align 4
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds %struct.Process, ptr %57, i64 %59
  %61 = getelementptr inbounds nuw %struct.Process, ptr %60, i32 0, i32 5
  %62 = load i32, ptr %61, align 4
  %63 = load ptr, ptr %5, align 8
  %64 = load i32, ptr %7, align 4
  %65 = sext i32 %64 to i64
  %66 = getelementptr inbounds %struct.Process, ptr %63, i64 %65
  %67 = getelementptr inbounds nuw %struct.Process, ptr %66, i32 0, i32 6
  %68 = load i32, ptr %67, align 4
  %69 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %44, i32 noundef %50, i32 noundef %56, i32 noundef %62, i32 noundef %68)
  %70 = load i32, ptr %7, align 4
  %71 = load i32, ptr %4, align 4
  %72 = xor i32 %71, 566098493
  %73 = or i32 %70, %72
  %74 = load i32, ptr %4, align 4
  %75 = xor i32 %74, 566098493
  %76 = and i32 %70, %75
  %77 = add i32 %73, %76
  store i32 %77, ptr %7, align 4
  store i32 -637117651, ptr %4, align 4
  %78 = xor i32 %1, 568450845
  %79 = and i32 %1, %78
  %80 = or i32 %1, %78
  %81 = xor i32 %1, %78
  %82 = sub i32 %80, %81
  %83 = sub i32 %82, %79
  %84 = mul i32 %83, 18
  %85 = xor i32 %1, 701135375
  %86 = and i32 %1, %85
  %87 = or i32 %1, %85
  %88 = xor i32 %1, %85
  %89 = mul i32 %87, 2
  %90 = sub i32 %89, %88
  %91 = sub i32 %90, %1
  %92 = sub i32 %91, %85
  %93 = mul i32 %92, 130
  %94 = icmp eq i32 %84, %93
  br i1 %94, label %96, label %181

95:                                               ; preds = %8
  ret void

96:                                               ; preds = %220, %212, %204, %196, %181, %172, %165, %152, %139, %128, %117, %38, %25, %12
  br label %8

97:                                               ; preds = %8
  store i32 -600766069, ptr %4, align 4
  call void asm sideeffect "", ""()
  %98 = xor i32 %1, -1815445301
  %99 = and i32 %1, %98
  %100 = or i32 %1, %98
  %101 = xor i32 %1, %98
  %102 = add i32 %1, %98
  %103 = sub i32 %102, %101
  %104 = mul i32 %99, 2
  %105 = sub i32 %103, %104
  %106 = mul i32 %105, 234
  %107 = xor i32 %1, 664683623
  %108 = and i32 %1, %107
  %109 = or i32 %1, %107
  %110 = xor i32 %1, %107
  %111 = add i32 %1, %107
  %112 = sub i32 %111, %110
  %113 = mul i32 %108, 2
  %114 = sub i32 %112, %113
  %115 = mul i32 %114, 176
  %116 = icmp eq i32 %106, %115
  br i1 %116, label %8, label %189

117:                                              ; preds = %8
  %118 = load i32, ptr %4, align 4
  %119 = xor i32 %118, 176219027
  store i32 %119, ptr %4, align 4
  %120 = xor i32 %1, -1390215343
  %121 = and i32 %1, %120
  %122 = or i32 %1, %120
  %123 = xor i32 %1, %120
  %124 = sub i32 %122, %123
  %125 = sub i32 %124, %121
  %126 = mul i32 %125, 188
  %127 = icmp slt i32 %126, 0
  br i1 %127, label %196, label %96

128:                                              ; preds = %8
  %129 = load i32, ptr %4, align 4
  %130 = xor i32 %129, 1825727258
  store i32 %130, ptr %4, align 4
  %131 = xor i32 %1, -1252272345
  %132 = and i32 %1, %131
  %133 = or i32 %1, %131
  %134 = xor i32 %1, %131
  %135 = sub i32 %133, %134
  %136 = sub i32 %135, %132
  %137 = mul i32 %136, 198
  %138 = icmp sle i32 %137, 0
  br i1 %138, label %96, label %204

139:                                              ; preds = %8
  %140 = load i32, ptr %4, align 4
  %141 = xor i32 %140, 724424367
  store i32 %141, ptr %4, align 4
  %142 = xor i32 %1, 1412859993
  %143 = and i32 %1, %142
  %144 = or i32 %1, %142
  %145 = xor i32 %1, %142
  %146 = mul i32 %144, 2
  %147 = sub i32 %146, %145
  %148 = sub i32 %147, %1
  %149 = sub i32 %148, %142
  %150 = mul i32 %149, 89
  %151 = icmp slt i32 %150, 1
  br i1 %151, label %96, label %212

152:                                              ; preds = %8
  %153 = load i32, ptr %4, align 4
  %154 = xor i32 %153, 1892351987
  store i32 %154, ptr %4, align 4
  %155 = xor i32 %1, -2129369751
  %156 = and i32 %1, %155
  %157 = or i32 %1, %155
  %158 = xor i32 %1, %155
  %159 = mul i32 %157, 2
  %160 = sub i32 %159, %158
  %161 = sub i32 %160, %1
  %162 = sub i32 %161, %155
  %163 = mul i32 %162, 204
  %164 = icmp ne i32 %163, 0
  br i1 %164, label %220, label %96

165:                                              ; preds = %12
  %166 = load i64, ptr %3, align 8
  %167 = ptrtoint ptr %0 to i64
  %168 = zext i32 %1 to i64
  %169 = sub i64 %168, %166
  %170 = add i64 %169, %167
  %171 = xor i64 %170, %168
  store i64 %171, ptr %3, align 8
  br label %96

172:                                              ; preds = %25
  %173 = load i64, ptr %3, align 8
  %174 = ptrtoint ptr %0 to i64
  %175 = zext i32 %1 to i64
  %176 = sub i64 %175, %175
  %177 = and i64 %176, %173
  %178 = sub i64 %177, %173
  %179 = or i64 %178, %175
  %180 = mul i64 %179, %175
  store i64 %180, ptr %3, align 8
  br label %96

181:                                              ; preds = %38
  %182 = load i64, ptr %3, align 8
  %183 = ptrtoint ptr %0 to i64
  %184 = zext i32 %1 to i64
  %185 = or i64 %182, %183
  %186 = sub i64 %185, %182
  %187 = mul i64 %186, %183
  %188 = or i64 %187, %183
  store i64 %188, ptr %3, align 8
  br label %96

189:                                              ; preds = %97
  %190 = load i64, ptr %3, align 8
  %191 = ptrtoint ptr %0 to i64
  %192 = zext i32 %1 to i64
  %193 = sub i64 %190, %191
  %194 = xor i64 %193, %191
  %195 = add i64 %194, %190
  store i64 %195, ptr %3, align 8
  br label %8

196:                                              ; preds = %117
  %197 = load i64, ptr %3, align 8
  %198 = ptrtoint ptr %0 to i64
  %199 = zext i32 %1 to i64
  %200 = and i64 %197, %197
  %201 = and i64 %200, %197
  %202 = sub i64 %201, %198
  %203 = or i64 %202, %198
  store i64 %203, ptr %3, align 8
  br label %96

204:                                              ; preds = %128
  %205 = load i64, ptr %3, align 8
  %206 = ptrtoint ptr %0 to i64
  %207 = zext i32 %1 to i64
  %208 = add i64 %206, %207
  %209 = add i64 %208, %205
  %210 = sub i64 %209, %207
  %211 = xor i64 %210, %206
  store i64 %211, ptr %3, align 8
  br label %96

212:                                              ; preds = %139
  %213 = load i64, ptr %3, align 8
  %214 = ptrtoint ptr %0 to i64
  %215 = zext i32 %1 to i64
  %216 = sub i64 %213, %215
  %217 = xor i64 %216, %215
  %218 = and i64 %217, %213
  %219 = xor i64 %218, %214
  store i64 %219, ptr %3, align 8
  br label %96

220:                                              ; preds = %152
  %221 = load i64, ptr %3, align 8
  %222 = ptrtoint ptr %0 to i64
  %223 = zext i32 %1 to i64
  %224 = and i64 %222, %222
  %225 = add i64 %224, %221
  %226 = or i64 %225, %223
  store i64 %226, ptr %3, align 8
  br label %96
}

declare i32 @printf(ptr noundef, ...) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printGanttChart(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca %struct.Segment, align 4
  store i32 -209767816, ptr %4, align 4
  br label %8

8:                                                ; preds = %378, %165, %164, %1
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, 1002957565
  %11 = mul i32 %10, -888731291
  switch i32 %11, label %165 [
    i32 1781499527, label %12
    i32 277036692, label %23
    i32 2106215881, label %40
    i32 1807894518, label %60
    i32 1963460163, label %84
    i32 1584248610, label %102
    i32 943732782, label %129
    i32 148855965, label %140
    i32 1102347914, label %162
    i32 706150042, label %182
    i32 1671131935, label %194
    i32 673007876, label %213
    i32 19444765, label %233
    i32 660749558, label %244
    i32 809530373, label %264
    i32 1329419157, label %286
    i32 1304065122, label %299
  ]

12:                                               ; preds = %8
  store ptr %0, ptr %5, align 8
  %13 = call i32 (ptr, ...) @printf(ptr noundef @.str.3)
  store i32 0, ptr %6, align 4
  store i32 548245505, ptr %4, align 4
  %14 = xor i32 %3, 2120875241
  %15 = and i32 %3, %14
  %16 = or i32 %3, %14
  %17 = xor i32 %3, %14
  %18 = add i32 %15, %16
  %19 = sub i32 %18, %3
  %20 = sub i32 %19, %14
  %21 = mul i32 %20, 224
  %22 = icmp sgt i32 %21, 0
  br i1 %22, label %321, label %164

23:                                               ; preds = %8
  %24 = load i32, ptr %6, align 4
  %25 = load ptr, ptr %5, align 8
  %26 = getelementptr inbounds nuw %struct.SegmentList, ptr %25, i32 0, i32 1
  %27 = load i32, ptr %26, align 8
  %28 = icmp slt i32 %24, %27
  %29 = select i1 %28, i32 1950353810, i32 -1302082625
  store i32 %29, ptr %4, align 4
  %30 = xor i32 %3, 1755311093
  %31 = and i32 %3, %30
  %32 = or i32 %3, %30
  %33 = xor i32 %3, %30
  %34 = add i32 %3, %30
  %35 = sub i32 %34, %33
  %36 = mul i32 %31, 2
  %37 = sub i32 %35, %36
  %38 = mul i32 %37, 104
  %39 = icmp slt i32 %38, 1
  br i1 %39, label %164, label %330

40:                                               ; preds = %8
  %41 = load ptr, ptr %5, align 8
  %42 = getelementptr inbounds nuw %struct.SegmentList, ptr %41, i32 0, i32 0
  %43 = load ptr, ptr %42, align 8
  %44 = load i32, ptr %6, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds %struct.Segment, ptr %43, i64 %45
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %7, ptr align 4 %46, i64 12, i1 false)
  %47 = getelementptr inbounds nuw %struct.Segment, ptr %7, i32 0, i32 0
  %48 = load i32, ptr %47, align 4
  %49 = icmp eq i32 %48, 0
  %50 = select i1 %49, i32 624856763, i32 -1665559164
  store i32 %50, ptr %4, align 4
  %51 = xor i32 %3, -287251979
  %52 = and i32 %3, %51
  %53 = or i32 %3, %51
  %54 = xor i32 %3, %51
  %55 = add i32 %52, %53
  %56 = sub i32 %55, %3
  %57 = sub i32 %56, %51
  %58 = mul i32 %57, 176
  %59 = icmp sgt i32 %58, 0
  br i1 %59, label %337, label %164

60:                                               ; preds = %8
  %61 = getelementptr inbounds nuw %struct.Segment, ptr %7, i32 0, i32 1
  %62 = load i32, ptr %61, align 4
  %63 = getelementptr inbounds nuw %struct.Segment, ptr %7, i32 0, i32 2
  %64 = load i32, ptr %63, align 4
  %65 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i32 noundef %62, i32 noundef %64)
  store i32 368632951, ptr %4, align 4
  %66 = xor i32 %3, 1257516005
  %67 = and i32 %3, %66
  %68 = or i32 %3, %66
  %69 = xor i32 %3, %66
  %70 = mul i32 %68, 2
  %71 = sub i32 %70, %69
  %72 = sub i32 %71, %3
  %73 = sub i32 %72, %66
  %74 = mul i32 %73, 140
  %75 = xor i32 %3, 1143533101
  %76 = and i32 %3, %75
  %77 = or i32 %3, %75
  %78 = xor i32 %3, %75
  %79 = add i32 %76, %77
  %80 = sub i32 %79, %3
  %81 = sub i32 %80, %75
  %82 = mul i32 %81, 142
  %83 = icmp ne i32 %74, %82
  br i1 %83, label %345, label %164

84:                                               ; preds = %8
  %85 = getelementptr inbounds nuw %struct.Segment, ptr %7, i32 0, i32 1
  %86 = load i32, ptr %85, align 4
  %87 = getelementptr inbounds nuw %struct.Segment, ptr %7, i32 0, i32 2
  %88 = load i32, ptr %87, align 4
  %89 = getelementptr inbounds nuw %struct.Segment, ptr %7, i32 0, i32 0
  %90 = load i32, ptr %89, align 4
  %91 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %86, i32 noundef %88, i32 noundef %90)
  store i32 368632951, ptr %4, align 4
  %92 = xor i32 %3, 2061736537
  %93 = and i32 %3, %92
  %94 = or i32 %3, %92
  %95 = xor i32 %3, %92
  %96 = add i32 %3, %92
  %97 = sub i32 %96, %95
  %98 = mul i32 %93, 2
  %99 = sub i32 %97, %98
  %100 = mul i32 %99, 206
  %101 = icmp sle i32 %100, 0
  br i1 %101, label %164, label %351

102:                                              ; preds = %8
  %103 = load i32, ptr %6, align 4
  %104 = load i32, ptr %4, align 4
  %105 = xor i32 %104, 368632950
  %106 = sub i32 %103, %105
  %107 = load i32, ptr %4, align 4
  %108 = xor i32 %107, 368632949
  %109 = mul i32 %103, %108
  %110 = load i32, ptr %4, align 4
  %111 = xor i32 %110, 368632950
  %112 = mul i32 %111, %106
  %113 = sub i32 %109, %112
  %114 = load ptr, ptr %5, align 8
  %115 = getelementptr inbounds nuw %struct.SegmentList, ptr %114, i32 0, i32 1
  %116 = load i32, ptr %115, align 8
  %117 = icmp slt i32 %113, %116
  %118 = select i1 %117, i32 1320539795, i32 -809805354
  store i32 %118, ptr %4, align 4
  %119 = xor i32 %3, -67408197
  %120 = and i32 %3, %119
  %121 = or i32 %3, %119
  %122 = xor i32 %3, %119
  %123 = add i32 %3, %119
  %124 = sub i32 %123, %122
  %125 = mul i32 %120, 2
  %126 = sub i32 %124, %125
  %127 = mul i32 %126, 177
  %128 = icmp slt i32 %127, 0
  br i1 %128, label %357, label %164

129:                                              ; preds = %8
  %130 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  store i32 -809805354, ptr %4, align 4
  %131 = xor i32 %3, -984731393
  %132 = and i32 %3, %131
  %133 = or i32 %3, %131
  %134 = xor i32 %3, %131
  %135 = add i32 %132, %133
  %136 = sub i32 %135, %3
  %137 = sub i32 %136, %131
  %138 = mul i32 %137, 56
  %139 = icmp uge i32 %138, 0
  br i1 %139, label %164, label %365

140:                                              ; preds = %8
  %141 = load i32, ptr %6, align 4
  %142 = load i32, ptr %4, align 4
  %143 = xor i32 %142, -809805353
  %144 = sub i32 %141, %143
  %145 = load i32, ptr %4, align 4
  %146 = xor i32 %145, -809805356
  %147 = mul i32 %141, %146
  %148 = load i32, ptr %4, align 4
  %149 = xor i32 %148, -809805353
  %150 = mul i32 %149, %144
  %151 = sub i32 %147, %150
  store i32 %151, ptr %6, align 4
  store i32 548245505, ptr %4, align 4
  %152 = xor i32 %3, 1836849991
  %153 = and i32 %3, %152
  %154 = or i32 %3, %152
  %155 = xor i32 %3, %152
  %156 = add i32 %3, %152
  %157 = sub i32 %156, %155
  %158 = mul i32 %153, 2
  %159 = sub i32 %157, %158
  %160 = mul i32 %159, 252
  %161 = icmp sgt i32 %160, 0
  br i1 %161, label %371, label %164

162:                                              ; preds = %8
  %163 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  ret void

164:                                              ; preds = %434, %428, %421, %412, %406, %399, %393, %385, %371, %365, %357, %351, %345, %337, %330, %321, %299, %286, %264, %244, %233, %213, %194, %182, %140, %129, %102, %84, %60, %40, %23, %12
  br label %8

165:                                              ; preds = %8
  store i32 -209767816, ptr %4, align 4
  call void asm sideeffect "", ""()
  %166 = xor i32 %3, 47462599
  %167 = and i32 %3, %166
  %168 = or i32 %3, %166
  %169 = xor i32 %3, %166
  %170 = add i32 %167, %168
  %171 = sub i32 %170, %3
  %172 = sub i32 %171, %166
  %173 = mul i32 %172, 255
  %174 = xor i32 %3, -665135541
  %175 = and i32 %3, %174
  %176 = or i32 %3, %174
  %177 = xor i32 %3, %174
  %178 = sub i32 %176, %177
  %179 = sub i32 %178, %175
  %180 = mul i32 %179, 107
  %181 = icmp ne i32 %173, %180
  br i1 %181, label %378, label %8

182:                                              ; preds = %8
  %183 = load i32, ptr %4, align 4
  %184 = xor i32 %183, -1378594430
  store i32 %184, ptr %4, align 4
  %185 = xor i32 %3, -559850791
  %186 = and i32 %3, %185
  %187 = or i32 %3, %185
  %188 = xor i32 %3, %185
  %189 = add i32 %186, %187
  %190 = sub i32 %189, %3
  %191 = sub i32 %190, %185
  %192 = mul i32 %191, 52
  %193 = icmp eq i32 %192, 0
  br i1 %193, label %164, label %385

194:                                              ; preds = %8
  %195 = load i32, ptr %4, align 4
  %196 = xor i32 %195, 723376542
  store i32 %196, ptr %4, align 4
  %197 = xor i32 %3, -905930777
  %198 = and i32 %3, %197
  %199 = or i32 %3, %197
  %200 = xor i32 %3, %197
  %201 = add i32 %198, %199
  %202 = sub i32 %201, %3
  %203 = sub i32 %202, %197
  %204 = mul i32 %203, 165
  %205 = xor i32 %3, -892287465
  %206 = and i32 %3, %205
  %207 = or i32 %3, %205
  %208 = xor i32 %3, %205
  %209 = sub i32 %207, %208
  %210 = sub i32 %209, %206
  %211 = mul i32 %210, 21
  %212 = icmp ne i32 %204, %211
  br i1 %212, label %393, label %164

213:                                              ; preds = %8
  %214 = load i32, ptr %4, align 4
  %215 = xor i32 %214, 1888899721
  store i32 %215, ptr %4, align 4
  %216 = xor i32 %3, 112694139
  %217 = and i32 %3, %216
  %218 = or i32 %3, %216
  %219 = xor i32 %3, %216
  %220 = mul i32 %218, 2
  %221 = sub i32 %220, %219
  %222 = sub i32 %221, %3
  %223 = sub i32 %222, %216
  %224 = mul i32 %223, 211
  %225 = xor i32 %3, -1603524987
  %226 = and i32 %3, %225
  %227 = or i32 %3, %225
  %228 = xor i32 %3, %225
  %229 = sub i32 %227, %228
  %230 = sub i32 %229, %226
  %231 = mul i32 %230, 10
  %232 = icmp eq i32 %224, %231
  br i1 %232, label %164, label %399

233:                                              ; preds = %8
  %234 = load i32, ptr %4, align 4
  %235 = xor i32 %234, 1334458263
  store i32 %235, ptr %4, align 4
  %236 = xor i32 %3, -1752337013
  %237 = and i32 %3, %236
  %238 = or i32 %3, %236
  %239 = xor i32 %3, %236
  %240 = sub i32 %238, %239
  %241 = sub i32 %240, %237
  %242 = mul i32 %241, 64
  %243 = icmp slt i32 %242, 0
  br i1 %243, label %406, label %164

244:                                              ; preds = %8
  %245 = load i32, ptr %4, align 4
  %246 = xor i32 %245, 257003781
  store i32 %246, ptr %4, align 4
  %247 = xor i32 %3, 1655349425
  %248 = and i32 %3, %247
  %249 = or i32 %3, %247
  %250 = xor i32 %3, %247
  %251 = add i32 %248, %249
  %252 = sub i32 %251, %3
  %253 = sub i32 %252, %247
  %254 = mul i32 %253, 57
  %255 = xor i32 %3, -1022220383
  %256 = and i32 %3, %255
  %257 = or i32 %3, %255
  %258 = xor i32 %3, %255
  %259 = add i32 %256, %257
  %260 = sub i32 %259, %3
  %261 = sub i32 %260, %255
  %262 = mul i32 %261, 117
  %263 = icmp ne i32 %254, %262
  br i1 %263, label %412, label %164

264:                                              ; preds = %8
  %265 = load i32, ptr %4, align 4
  %266 = xor i32 %265, 823921624
  store i32 %266, ptr %4, align 4
  %267 = xor i32 %3, -1022623307
  %268 = and i32 %3, %267
  %269 = or i32 %3, %267
  %270 = xor i32 %3, %267
  %271 = add i32 %3, %267
  %272 = sub i32 %271, %270
  %273 = mul i32 %268, 2
  %274 = sub i32 %272, %273
  %275 = mul i32 %274, 116
  %276 = xor i32 %3, -188231661
  %277 = and i32 %3, %276
  %278 = or i32 %3, %276
  %279 = xor i32 %3, %276
  %280 = mul i32 %278, 2
  %281 = sub i32 %280, %279
  %282 = sub i32 %281, %3
  %283 = sub i32 %282, %276
  %284 = mul i32 %283, 6
  %285 = icmp eq i32 %275, %284
  br i1 %285, label %164, label %421

286:                                              ; preds = %8
  %287 = load i32, ptr %4, align 4
  %288 = xor i32 %287, -803043328
  store i32 %288, ptr %4, align 4
  %289 = xor i32 %3, 77753429
  %290 = and i32 %3, %289
  %291 = or i32 %3, %289
  %292 = xor i32 %3, %289
  %293 = mul i32 %291, 2
  %294 = sub i32 %293, %292
  %295 = sub i32 %294, %3
  %296 = sub i32 %295, %289
  %297 = mul i32 %296, 214
  %298 = icmp slt i32 %297, 0
  br i1 %298, label %428, label %164

299:                                              ; preds = %8
  %300 = load i32, ptr %4, align 4
  %301 = xor i32 %300, 1884896656
  store i32 %301, ptr %4, align 4
  %302 = xor i32 %3, -25423407
  %303 = and i32 %3, %302
  %304 = or i32 %3, %302
  %305 = xor i32 %3, %302
  %306 = mul i32 %304, 2
  %307 = sub i32 %306, %305
  %308 = sub i32 %307, %3
  %309 = sub i32 %308, %302
  %310 = mul i32 %309, 125
  %311 = xor i32 %3, -1000351895
  %312 = and i32 %3, %311
  %313 = or i32 %3, %311
  %314 = xor i32 %3, %311
  %315 = mul i32 %313, 2
  %316 = sub i32 %315, %314
  %317 = sub i32 %316, %3
  %318 = sub i32 %317, %311
  %319 = mul i32 %318, 196
  %320 = icmp ne i32 %310, %319
  br i1 %320, label %434, label %164

321:                                              ; preds = %12
  %322 = load i64, ptr %2, align 8
  %323 = ptrtoint ptr %0 to i64
  %324 = mul i64 %322, %322
  %325 = add i64 %324, %323
  %326 = or i64 %325, %323
  %327 = xor i64 %326, %323
  %328 = sub i64 %327, %322
  %329 = mul i64 %328, %323
  store i64 %329, ptr %2, align 8
  br label %164

330:                                              ; preds = %23
  %331 = load i64, ptr %2, align 8
  %332 = ptrtoint ptr %0 to i64
  %333 = sub i64 %331, %331
  %334 = add i64 %333, %332
  %335 = add i64 %334, %332
  %336 = add i64 %335, %332
  store i64 %336, ptr %2, align 8
  br label %164

337:                                              ; preds = %40
  %338 = load i64, ptr %2, align 8
  %339 = ptrtoint ptr %0 to i64
  %340 = xor i64 %339, %339
  %341 = or i64 %340, %338
  %342 = mul i64 %341, %338
  %343 = sub i64 %342, %338
  %344 = mul i64 %343, %338
  store i64 %344, ptr %2, align 8
  br label %164

345:                                              ; preds = %60
  %346 = load i64, ptr %2, align 8
  %347 = ptrtoint ptr %0 to i64
  %348 = and i64 %347, %347
  %349 = and i64 %348, %347
  %350 = xor i64 %349, %346
  store i64 %350, ptr %2, align 8
  br label %164

351:                                              ; preds = %84
  %352 = load i64, ptr %2, align 8
  %353 = ptrtoint ptr %0 to i64
  %354 = and i64 %353, %353
  %355 = sub i64 %354, %353
  %356 = xor i64 %355, %352
  store i64 %356, ptr %2, align 8
  br label %164

357:                                              ; preds = %102
  %358 = load i64, ptr %2, align 8
  %359 = ptrtoint ptr %0 to i64
  %360 = or i64 %358, %358
  %361 = xor i64 %360, %359
  %362 = add i64 %361, %358
  %363 = mul i64 %362, %358
  %364 = or i64 %363, %359
  store i64 %364, ptr %2, align 8
  br label %164

365:                                              ; preds = %129
  %366 = load i64, ptr %2, align 8
  %367 = ptrtoint ptr %0 to i64
  %368 = xor i64 %366, %367
  %369 = mul i64 %368, %366
  %370 = mul i64 %369, %366
  store i64 %370, ptr %2, align 8
  br label %164

371:                                              ; preds = %140
  %372 = load i64, ptr %2, align 8
  %373 = ptrtoint ptr %0 to i64
  %374 = xor i64 %373, %373
  %375 = and i64 %374, %372
  %376 = sub i64 %375, %373
  %377 = add i64 %376, %372
  store i64 %377, ptr %2, align 8
  br label %164

378:                                              ; preds = %165
  %379 = load i64, ptr %2, align 8
  %380 = ptrtoint ptr %0 to i64
  %381 = xor i64 %380, %380
  %382 = xor i64 %381, %379
  %383 = add i64 %382, %380
  %384 = xor i64 %383, %380
  store i64 %384, ptr %2, align 8
  br label %8

385:                                              ; preds = %182
  %386 = load i64, ptr %2, align 8
  %387 = ptrtoint ptr %0 to i64
  %388 = mul i64 %386, %387
  %389 = or i64 %388, %387
  %390 = sub i64 %389, %386
  %391 = and i64 %390, %387
  %392 = sub i64 %391, %387
  store i64 %392, ptr %2, align 8
  br label %164

393:                                              ; preds = %194
  %394 = load i64, ptr %2, align 8
  %395 = ptrtoint ptr %0 to i64
  %396 = or i64 %395, %394
  %397 = or i64 %396, %394
  %398 = or i64 %397, %394
  store i64 %398, ptr %2, align 8
  br label %164

399:                                              ; preds = %213
  %400 = load i64, ptr %2, align 8
  %401 = ptrtoint ptr %0 to i64
  %402 = or i64 %401, %400
  %403 = add i64 %402, %401
  %404 = or i64 %403, %400
  %405 = or i64 %404, %401
  store i64 %405, ptr %2, align 8
  br label %164

406:                                              ; preds = %233
  %407 = load i64, ptr %2, align 8
  %408 = ptrtoint ptr %0 to i64
  %409 = mul i64 %407, %408
  %410 = or i64 %409, %408
  %411 = or i64 %410, %407
  store i64 %411, ptr %2, align 8
  br label %164

412:                                              ; preds = %244
  %413 = load i64, ptr %2, align 8
  %414 = ptrtoint ptr %0 to i64
  %415 = add i64 %413, %413
  %416 = sub i64 %415, %413
  %417 = or i64 %416, %414
  %418 = sub i64 %417, %414
  %419 = xor i64 %418, %414
  %420 = add i64 %419, %413
  store i64 %420, ptr %2, align 8
  br label %164

421:                                              ; preds = %264
  %422 = load i64, ptr %2, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = mul i64 %422, %422
  %425 = xor i64 %424, %423
  %426 = add i64 %425, %423
  %427 = xor i64 %426, %423
  store i64 %427, ptr %2, align 8
  br label %164

428:                                              ; preds = %286
  %429 = load i64, ptr %2, align 8
  %430 = ptrtoint ptr %0 to i64
  %431 = and i64 %430, %430
  %432 = xor i64 %431, %430
  %433 = mul i64 %432, %430
  store i64 %433, ptr %2, align 8
  br label %164

434:                                              ; preds = %299
  %435 = load i64, ptr %2, align 8
  %436 = ptrtoint ptr %0 to i64
  %437 = or i64 %435, %436
  %438 = xor i64 %437, %436
  %439 = add i64 %438, %435
  store i64 %439, ptr %2, align 8
  br label %164
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printResultTable(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca double, align 8
  %8 = alloca double, align 8
  %9 = alloca double, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  store i32 -1728703749, ptr %4, align 4
  br label %16

16:                                               ; preds = %289, %204, %203, %2
  %17 = load i32, ptr %4, align 4
  %18 = sub i32 %17, 1843351450
  %19 = mul i32 %18, 1076124009
  switch i32 %19, label %204 [
    i32 1340529609, label %20
    i32 1974260643, label %33
    i32 1243543279, label %46
    i32 2011133967, label %184
    i32 7052744, label %213
    i32 1121244260, label %224
    i32 213412953, label %237
    i32 964548059, label %250
  ]

20:                                               ; preds = %16
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store double 0.000000e+00, ptr %7, align 8
  store double 0.000000e+00, ptr %8, align 8
  store double 0.000000e+00, ptr %9, align 8
  store i32 0, ptr %10, align 4
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.8)
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.9)
  store i32 0, ptr %11, align 4
  store i32 898746053, ptr %4, align 4
  %23 = xor i32 %1, 797843677
  %24 = and i32 %1, %23
  %25 = or i32 %1, %23
  %26 = xor i32 %1, %23
  %27 = add i32 %1, %23
  %28 = sub i32 %27, %26
  %29 = mul i32 %24, 2
  %30 = sub i32 %28, %29
  %31 = mul i32 %30, 166
  %32 = icmp sle i32 %31, 0
  br i1 %32, label %203, label %263

33:                                               ; preds = %16
  %34 = load i32, ptr %11, align 4
  %35 = load i32, ptr %6, align 4
  %36 = icmp slt i32 %34, %35
  %37 = select i1 %36, i32 -1872070095, i32 -1852395951
  store i32 %37, ptr %4, align 4
  %38 = xor i32 %1, 2045409215
  %39 = and i32 %1, %38
  %40 = or i32 %1, %38
  %41 = xor i32 %1, %38
  %42 = sub i32 %40, %41
  %43 = sub i32 %42, %39
  %44 = mul i32 %43, 126
  %45 = icmp ne i32 %44, 0
  br i1 %45, label %273, label %203

46:                                               ; preds = %16
  %47 = load ptr, ptr %5, align 8
  %48 = load i32, ptr %11, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds %struct.Process, ptr %47, i64 %49
  %51 = getelementptr inbounds nuw %struct.Process, ptr %50, i32 0, i32 8
  %52 = load i32, ptr %51, align 4
  %53 = load ptr, ptr %5, align 8
  %54 = load i32, ptr %11, align 4
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds %struct.Process, ptr %53, i64 %55
  %57 = getelementptr inbounds nuw %struct.Process, ptr %56, i32 0, i32 1
  %58 = load i32, ptr %57, align 4
  %59 = load i32, ptr %4, align 4
  %60 = xor i32 %59, -1872070096
  %61 = add i32 %58, %60
  %62 = load i32, ptr %4, align 4
  %63 = xor i32 %62, -1872070096
  %64 = add i32 %52, %63
  %65 = mul i32 %52, %61
  %66 = mul i32 %58, %64
  %67 = sub i32 %65, %66
  store i32 %67, ptr %12, align 4
  %68 = load i32, ptr %12, align 4
  %69 = load ptr, ptr %5, align 8
  %70 = load i32, ptr %11, align 4
  %71 = sext i32 %70 to i64
  %72 = getelementptr inbounds %struct.Process, ptr %69, i64 %71
  %73 = getelementptr inbounds nuw %struct.Process, ptr %72, i32 0, i32 2
  %74 = load i32, ptr %73, align 4
  %75 = load i32, ptr %4, align 4
  %76 = xor i32 %75, -1872070096
  %77 = add i32 %74, %76
  %78 = load i32, ptr %4, align 4
  %79 = xor i32 %78, -1872070096
  %80 = add i32 %68, %79
  %81 = mul i32 %68, %77
  %82 = mul i32 %74, %80
  %83 = sub i32 %81, %82
  store i32 %83, ptr %13, align 4
  %84 = load ptr, ptr %5, align 8
  %85 = load i32, ptr %11, align 4
  %86 = sext i32 %85 to i64
  %87 = getelementptr inbounds %struct.Process, ptr %84, i64 %86
  %88 = getelementptr inbounds nuw %struct.Process, ptr %87, i32 0, i32 7
  %89 = load i32, ptr %88, align 4
  %90 = load ptr, ptr %5, align 8
  %91 = load i32, ptr %11, align 4
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds %struct.Process, ptr %90, i64 %92
  %94 = getelementptr inbounds nuw %struct.Process, ptr %93, i32 0, i32 1
  %95 = load i32, ptr %94, align 4
  %96 = load i32, ptr %4, align 4
  %97 = xor i32 %96, 1872070094
  %98 = xor i32 %95, %97
  %99 = add i32 %89, %98
  %100 = load i32, ptr %4, align 4
  %101 = xor i32 %100, -1872070096
  %102 = add i32 %99, %101
  store i32 %102, ptr %14, align 4
  %103 = load ptr, ptr %5, align 8
  %104 = load i32, ptr %11, align 4
  %105 = sext i32 %104 to i64
  %106 = getelementptr inbounds %struct.Process, ptr %103, i64 %105
  %107 = getelementptr inbounds nuw %struct.Process, ptr %106, i32 0, i32 8
  %108 = load i32, ptr %107, align 4
  %109 = load ptr, ptr %5, align 8
  %110 = load i32, ptr %11, align 4
  %111 = sext i32 %110 to i64
  %112 = getelementptr inbounds %struct.Process, ptr %109, i64 %111
  %113 = getelementptr inbounds nuw %struct.Process, ptr %112, i32 0, i32 6
  %114 = load i32, ptr %113, align 4
  %115 = load i32, ptr %4, align 4
  %116 = xor i32 %115, 1872070094
  %117 = xor i32 %114, %116
  %118 = add i32 %108, %117
  %119 = load i32, ptr %4, align 4
  %120 = xor i32 %119, -1872070096
  %121 = add i32 %118, %120
  %122 = call i32 @maxInt(i32 noundef 0, i32 noundef %121)
  store i32 %122, ptr %15, align 4
  %123 = load i32, ptr %13, align 4
  %124 = sitofp i32 %123 to double
  %125 = load double, ptr %7, align 8
  %126 = fadd double %125, %124
  store double %126, ptr %7, align 8
  %127 = load i32, ptr %12, align 4
  %128 = sitofp i32 %127 to double
  %129 = load double, ptr %8, align 8
  %130 = fadd double %129, %128
  store double %130, ptr %8, align 8
  %131 = load i32, ptr %14, align 4
  %132 = sitofp i32 %131 to double
  %133 = load double, ptr %9, align 8
  %134 = fadd double %133, %132
  store double %134, ptr %9, align 8
  %135 = load i32, ptr %15, align 4
  %136 = load i32, ptr %10, align 4
  %137 = or i32 %136, %135
  %138 = and i32 %136, %135
  %139 = add i32 %137, %138
  store i32 %139, ptr %10, align 4
  %140 = load ptr, ptr %5, align 8
  %141 = load i32, ptr %11, align 4
  %142 = sext i32 %141 to i64
  %143 = getelementptr inbounds %struct.Process, ptr %140, i64 %142
  %144 = getelementptr inbounds nuw %struct.Process, ptr %143, i32 0, i32 0
  %145 = load i32, ptr %144, align 4
  %146 = load ptr, ptr %5, align 8
  %147 = load i32, ptr %11, align 4
  %148 = sext i32 %147 to i64
  %149 = getelementptr inbounds %struct.Process, ptr %146, i64 %148
  %150 = getelementptr inbounds nuw %struct.Process, ptr %149, i32 0, i32 7
  %151 = load i32, ptr %150, align 4
  %152 = load ptr, ptr %5, align 8
  %153 = load i32, ptr %11, align 4
  %154 = sext i32 %153 to i64
  %155 = getelementptr inbounds %struct.Process, ptr %152, i64 %154
  %156 = getelementptr inbounds nuw %struct.Process, ptr %155, i32 0, i32 8
  %157 = load i32, ptr %156, align 4
  %158 = load i32, ptr %13, align 4
  %159 = load i32, ptr %12, align 4
  %160 = load i32, ptr %14, align 4
  %161 = load i32, ptr %15, align 4
  %162 = call i32 (ptr, ...) @printf(ptr noundef @.str.10, i32 noundef %145, i32 noundef %151, i32 noundef %157, i32 noundef %158, i32 noundef %159, i32 noundef %160, i32 noundef %161)
  %163 = load i32, ptr %11, align 4
  %164 = load i32, ptr %4, align 4
  %165 = xor i32 %164, -1872070096
  %166 = sub i32 %163, %165
  %167 = load i32, ptr %4, align 4
  %168 = xor i32 %167, -1872070093
  %169 = mul i32 %163, %168
  %170 = load i32, ptr %4, align 4
  %171 = xor i32 %170, -1872070096
  %172 = mul i32 %171, %166
  %173 = sub i32 %169, %172
  store i32 %173, ptr %11, align 4
  store i32 898746053, ptr %4, align 4
  %174 = xor i32 %1, 835251529
  %175 = and i32 %1, %174
  %176 = or i32 %1, %174
  %177 = xor i32 %1, %174
  %178 = add i32 %1, %174
  %179 = sub i32 %178, %177
  %180 = mul i32 %175, 2
  %181 = sub i32 %179, %180
  %182 = mul i32 %181, 24
  %183 = icmp slt i32 %182, 1
  br i1 %183, label %203, label %280

184:                                              ; preds = %16
  %185 = call i32 (ptr, ...) @printf(ptr noundef @.str.11)
  %186 = load double, ptr %7, align 8
  %187 = load i32, ptr %6, align 4
  %188 = sitofp i32 %187 to double
  %189 = fdiv double %186, %188
  %190 = call i32 (ptr, ...) @printf(ptr noundef @.str.12, double noundef %189)
  %191 = load double, ptr %8, align 8
  %192 = load i32, ptr %6, align 4
  %193 = sitofp i32 %192 to double
  %194 = fdiv double %191, %193
  %195 = call i32 (ptr, ...) @printf(ptr noundef @.str.13, double noundef %194)
  %196 = load double, ptr %9, align 8
  %197 = load i32, ptr %6, align 4
  %198 = sitofp i32 %197 to double
  %199 = fdiv double %196, %198
  %200 = call i32 (ptr, ...) @printf(ptr noundef @.str.14, double noundef %199)
  %201 = load i32, ptr %10, align 4
  %202 = call i32 (ptr, ...) @printf(ptr noundef @.str.15, i32 noundef %201)
  ret void

203:                                              ; preds = %323, %316, %308, %299, %280, %273, %263, %250, %237, %224, %213, %46, %33, %20
  br label %16

204:                                              ; preds = %16
  store i32 -1728703749, ptr %4, align 4
  call void asm sideeffect "", ""()
  %205 = xor i32 %1, 1748714027
  %206 = and i32 %1, %205
  %207 = or i32 %1, %205
  %208 = xor i32 %1, %205
  %209 = sub i32 %207, %208
  %210 = sub i32 %209, %206
  %211 = mul i32 %210, 113
  %212 = icmp ugt i32 %211, 0
  br i1 %212, label %289, label %16

213:                                              ; preds = %16
  %214 = load i32, ptr %4, align 4
  %215 = xor i32 %214, 1973103255
  store i32 %215, ptr %4, align 4
  %216 = xor i32 %1, 2112660677
  %217 = and i32 %1, %216
  %218 = or i32 %1, %216
  %219 = xor i32 %1, %216
  %220 = sub i32 %218, %219
  %221 = sub i32 %220, %217
  %222 = mul i32 %221, 85
  %223 = icmp sle i32 %222, 0
  br i1 %223, label %203, label %299

224:                                              ; preds = %16
  %225 = load i32, ptr %4, align 4
  %226 = xor i32 %225, -1803225006
  store i32 %226, ptr %4, align 4
  %227 = xor i32 %1, -1755066835
  %228 = and i32 %1, %227
  %229 = or i32 %1, %227
  %230 = xor i32 %1, %227
  %231 = add i32 %1, %227
  %232 = sub i32 %231, %230
  %233 = mul i32 %228, 2
  %234 = sub i32 %232, %233
  %235 = mul i32 %234, 114
  %236 = icmp sgt i32 %235, 0
  br i1 %236, label %308, label %203

237:                                              ; preds = %16
  %238 = load i32, ptr %4, align 4
  %239 = xor i32 %238, 1146948681
  store i32 %239, ptr %4, align 4
  %240 = xor i32 %1, 330322323
  %241 = and i32 %1, %240
  %242 = or i32 %1, %240
  %243 = xor i32 %1, %240
  %244 = mul i32 %242, 2
  %245 = sub i32 %244, %243
  %246 = sub i32 %245, %1
  %247 = sub i32 %246, %240
  %248 = mul i32 %247, 205
  %249 = icmp slt i32 %248, 0
  br i1 %249, label %316, label %203

250:                                              ; preds = %16
  %251 = load i32, ptr %4, align 4
  %252 = xor i32 %251, -1493229217
  store i32 %252, ptr %4, align 4
  %253 = xor i32 %1, -650334125
  %254 = and i32 %1, %253
  %255 = or i32 %1, %253
  %256 = xor i32 %1, %253
  %257 = add i32 %1, %253
  %258 = sub i32 %257, %256
  %259 = mul i32 %254, 2
  %260 = sub i32 %258, %259
  %261 = mul i32 %260, 14
  %262 = icmp ne i32 %261, 0
  br i1 %262, label %323, label %203

263:                                              ; preds = %20
  %264 = load i64, ptr %3, align 8
  %265 = ptrtoint ptr %0 to i64
  %266 = zext i32 %1 to i64
  %267 = or i64 %264, %265
  %268 = sub i64 %267, %266
  %269 = xor i64 %268, %266
  %270 = and i64 %269, %266
  %271 = or i64 %270, %264
  %272 = add i64 %271, %264
  store i64 %272, ptr %3, align 8
  br label %203

273:                                              ; preds = %33
  %274 = load i64, ptr %3, align 8
  %275 = ptrtoint ptr %0 to i64
  %276 = zext i32 %1 to i64
  %277 = xor i64 %276, %276
  %278 = mul i64 %277, %275
  %279 = or i64 %278, %275
  store i64 %279, ptr %3, align 8
  br label %203

280:                                              ; preds = %46
  %281 = load i64, ptr %3, align 8
  %282 = ptrtoint ptr %0 to i64
  %283 = zext i32 %1 to i64
  %284 = mul i64 %283, %281
  %285 = add i64 %284, %281
  %286 = sub i64 %285, %283
  %287 = mul i64 %286, %282
  %288 = sub i64 %287, %281
  store i64 %288, ptr %3, align 8
  br label %203

289:                                              ; preds = %204
  %290 = load i64, ptr %3, align 8
  %291 = ptrtoint ptr %0 to i64
  %292 = zext i32 %1 to i64
  %293 = xor i64 %290, %291
  %294 = mul i64 %293, %291
  %295 = xor i64 %294, %290
  %296 = add i64 %295, %290
  %297 = or i64 %296, %290
  %298 = add i64 %297, %291
  store i64 %298, ptr %3, align 8
  br label %16

299:                                              ; preds = %213
  %300 = load i64, ptr %3, align 8
  %301 = ptrtoint ptr %0 to i64
  %302 = zext i32 %1 to i64
  %303 = add i64 %300, %301
  %304 = add i64 %303, %300
  %305 = sub i64 %304, %302
  %306 = add i64 %305, %300
  %307 = mul i64 %306, %301
  store i64 %307, ptr %3, align 8
  br label %203

308:                                              ; preds = %224
  %309 = load i64, ptr %3, align 8
  %310 = ptrtoint ptr %0 to i64
  %311 = zext i32 %1 to i64
  %312 = sub i64 %311, %309
  %313 = sub i64 %312, %309
  %314 = mul i64 %313, %310
  %315 = mul i64 %314, %310
  store i64 %315, ptr %3, align 8
  br label %203

316:                                              ; preds = %237
  %317 = load i64, ptr %3, align 8
  %318 = ptrtoint ptr %0 to i64
  %319 = zext i32 %1 to i64
  %320 = or i64 %318, %319
  %321 = xor i64 %320, %319
  %322 = xor i64 %321, %318
  store i64 %322, ptr %3, align 8
  br label %203

323:                                              ; preds = %250
  %324 = load i64, ptr %3, align 8
  %325 = ptrtoint ptr %0 to i64
  %326 = zext i32 %1 to i64
  %327 = mul i64 %324, %326
  %328 = mul i64 %327, %325
  %329 = add i64 %328, %324
  %330 = and i64 %329, %325
  %331 = and i64 %330, %325
  %332 = sub i64 %331, %325
  store i64 %332, ptr %3, align 8
  br label %203
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printWorstProcess(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  store i32 1610561347, ptr %4, align 4
  br label %13

13:                                               ; preds = %502, %305, %304, %2
  %14 = load i32, ptr %4, align 4
  %15 = sub i32 %14, 1799880483
  %16 = mul i32 %15, -1532443143
  switch i32 %16, label %305 [
    i32 1499871008, label %17
    i32 2145419299, label %35
    i32 1203800267, label %50
    i32 957990633, label %105
    i32 1121921171, label %117
    i32 1550416332, label %132
    i32 1224232225, label %213
    i32 470715774, label %223
    i32 295495040, label %234
    i32 1020065984, label %245
    i32 2041619843, label %264
    i32 1489086040, label %316
    i32 1504932937, label %329
    i32 16474698, label %340
    i32 1543152282, label %352
    i32 1183570636, label %365
    i32 2141953739, label %376
    i32 1220328066, label %397
    i32 600657062, label %409
  ]

17:                                               ; preds = %13
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 1, ptr %8, align 4
  store i32 831966494, ptr %4, align 4
  %18 = xor i32 %1, 1925913829
  %19 = and i32 %1, %18
  %20 = or i32 %1, %18
  %21 = xor i32 %1, %18
  %22 = add i32 %1, %18
  %23 = sub i32 %22, %21
  %24 = mul i32 %19, 2
  %25 = sub i32 %23, %24
  %26 = mul i32 %25, 220
  %27 = xor i32 %1, 984213319
  %28 = and i32 %1, %27
  %29 = or i32 %1, %27
  %30 = xor i32 %1, %27
  %31 = sub i32 %29, %30
  %32 = sub i32 %31, %28
  %33 = mul i32 %32, 159
  %34 = icmp ne i32 %26, %33
  br i1 %34, label %421, label %304

35:                                               ; preds = %13
  %36 = load i32, ptr %8, align 4
  %37 = load i32, ptr %6, align 4
  %38 = icmp slt i32 %36, %37
  %39 = select i1 %38, i32 128197894, i32 61207934
  store i32 %39, ptr %4, align 4
  %40 = xor i32 %1, -369128473
  %41 = and i32 %1, %40
  %42 = or i32 %1, %40
  %43 = xor i32 %1, %40
  %44 = mul i32 %42, 2
  %45 = sub i32 %44, %43
  %46 = sub i32 %45, %1
  %47 = sub i32 %46, %40
  %48 = mul i32 %47, 170
  %49 = icmp uge i32 %48, 0
  br i1 %49, label %304, label %429

50:                                               ; preds = %13
  %51 = load ptr, ptr %5, align 8
  %52 = load i32, ptr %8, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds %struct.Process, ptr %51, i64 %53
  %55 = getelementptr inbounds nuw %struct.Process, ptr %54, i32 0, i32 8
  %56 = load i32, ptr %55, align 4
  %57 = load ptr, ptr %5, align 8
  %58 = load i32, ptr %8, align 4
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds %struct.Process, ptr %57, i64 %59
  %61 = getelementptr inbounds nuw %struct.Process, ptr %60, i32 0, i32 6
  %62 = load i32, ptr %61, align 4
  %63 = load i32, ptr %4, align 4
  %64 = xor i32 %63, 128197895
  %65 = add i32 %62, %64
  %66 = load i32, ptr %4, align 4
  %67 = xor i32 %66, 128197895
  %68 = add i32 %56, %67
  %69 = mul i32 %56, %65
  %70 = mul i32 %62, %68
  %71 = sub i32 %69, %70
  %72 = call i32 @maxInt(i32 noundef 0, i32 noundef %71)
  store i32 %72, ptr %9, align 4
  %73 = load ptr, ptr %5, align 8
  %74 = load i32, ptr %7, align 4
  %75 = sext i32 %74 to i64
  %76 = getelementptr inbounds %struct.Process, ptr %73, i64 %75
  %77 = getelementptr inbounds nuw %struct.Process, ptr %76, i32 0, i32 8
  %78 = load i32, ptr %77, align 4
  %79 = load ptr, ptr %5, align 8
  %80 = load i32, ptr %7, align 4
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds %struct.Process, ptr %79, i64 %81
  %83 = getelementptr inbounds nuw %struct.Process, ptr %82, i32 0, i32 6
  %84 = load i32, ptr %83, align 4
  %85 = xor i32 %78, %84
  %86 = load i32, ptr %4, align 4
  %87 = xor i32 %86, -128197895
  %88 = xor i32 %78, %87
  %89 = and i32 %88, %84
  %90 = add i32 %89, %89
  %91 = sub i32 %85, %90
  %92 = call i32 @maxInt(i32 noundef 0, i32 noundef %91)
  store i32 %92, ptr %10, align 4
  %93 = load i32, ptr %9, align 4
  %94 = load i32, ptr %10, align 4
  %95 = icmp sgt i32 %93, %94
  %96 = select i1 %95, i32 -1115782252, i32 -1449388786
  store i32 %96, ptr %4, align 4
  %97 = xor i32 %1, -1851701395
  %98 = and i32 %1, %97
  %99 = or i32 %1, %97
  %100 = xor i32 %1, %97
  %101 = sub i32 %99, %100
  %102 = sub i32 %101, %98
  %103 = mul i32 %102, 95
  %104 = icmp sgt i32 %103, 0
  br i1 %104, label %437, label %304

105:                                              ; preds = %13
  %106 = load i32, ptr %8, align 4
  store i32 %106, ptr %7, align 4
  store i32 562818531, ptr %4, align 4
  %107 = xor i32 %1, 2101059869
  %108 = and i32 %1, %107
  %109 = or i32 %1, %107
  %110 = xor i32 %1, %107
  %111 = add i32 %1, %107
  %112 = sub i32 %111, %110
  %113 = mul i32 %108, 2
  %114 = sub i32 %112, %113
  %115 = mul i32 %114, 204
  %116 = icmp slt i32 %115, 0
  br i1 %116, label %444, label %304

117:                                              ; preds = %13
  %118 = load i32, ptr %9, align 4
  %119 = load i32, ptr %10, align 4
  %120 = icmp eq i32 %118, %119
  %121 = select i1 %120, i32 -1211381169, i32 1100443811
  store i32 %121, ptr %4, align 4
  %122 = xor i32 %1, -509996475
  %123 = and i32 %1, %122
  %124 = or i32 %1, %122
  %125 = xor i32 %1, %122
  %126 = add i32 %1, %122
  %127 = sub i32 %126, %125
  %128 = mul i32 %123, 2
  %129 = sub i32 %127, %128
  %130 = mul i32 %129, 246
  %131 = icmp eq i32 %130, 0
  br i1 %131, label %304, label %452

132:                                              ; preds = %13
  %133 = load ptr, ptr %5, align 8
  %134 = load i32, ptr %8, align 4
  %135 = sext i32 %134 to i64
  %136 = getelementptr inbounds %struct.Process, ptr %133, i64 %135
  %137 = getelementptr inbounds nuw %struct.Process, ptr %136, i32 0, i32 8
  %138 = load i32, ptr %137, align 4
  %139 = load ptr, ptr %5, align 8
  %140 = load i32, ptr %8, align 4
  %141 = sext i32 %140 to i64
  %142 = getelementptr inbounds %struct.Process, ptr %139, i64 %141
  %143 = getelementptr inbounds nuw %struct.Process, ptr %142, i32 0, i32 1
  %144 = load i32, ptr %143, align 4
  %145 = xor i32 %138, %144
  %146 = load i32, ptr %4, align 4
  %147 = xor i32 %146, 1211381168
  %148 = xor i32 %138, %147
  %149 = and i32 %148, %144
  %150 = add i32 %149, %149
  %151 = sub i32 %145, %150
  %152 = load ptr, ptr %5, align 8
  %153 = load i32, ptr %8, align 4
  %154 = sext i32 %153 to i64
  %155 = getelementptr inbounds %struct.Process, ptr %152, i64 %154
  %156 = getelementptr inbounds nuw %struct.Process, ptr %155, i32 0, i32 2
  %157 = load i32, ptr %156, align 4
  %158 = load i32, ptr %4, align 4
  %159 = xor i32 %158, 1211381168
  %160 = xor i32 %157, %159
  %161 = add i32 %151, %160
  %162 = load i32, ptr %4, align 4
  %163 = xor i32 %162, -1211381170
  %164 = add i32 %161, %163
  store i32 %164, ptr %11, align 4
  %165 = load ptr, ptr %5, align 8
  %166 = load i32, ptr %7, align 4
  %167 = sext i32 %166 to i64
  %168 = getelementptr inbounds %struct.Process, ptr %165, i64 %167
  %169 = getelementptr inbounds nuw %struct.Process, ptr %168, i32 0, i32 8
  %170 = load i32, ptr %169, align 4
  %171 = load ptr, ptr %5, align 8
  %172 = load i32, ptr %7, align 4
  %173 = sext i32 %172 to i64
  %174 = getelementptr inbounds %struct.Process, ptr %171, i64 %173
  %175 = getelementptr inbounds nuw %struct.Process, ptr %174, i32 0, i32 1
  %176 = load i32, ptr %175, align 4
  %177 = load i32, ptr %4, align 4
  %178 = xor i32 %177, -1211381170
  %179 = add i32 %176, %178
  %180 = load i32, ptr %4, align 4
  %181 = xor i32 %180, -1211381170
  %182 = add i32 %170, %181
  %183 = mul i32 %170, %179
  %184 = mul i32 %176, %182
  %185 = sub i32 %183, %184
  %186 = load ptr, ptr %5, align 8
  %187 = load i32, ptr %7, align 4
  %188 = sext i32 %187 to i64
  %189 = getelementptr inbounds %struct.Process, ptr %186, i64 %188
  %190 = getelementptr inbounds nuw %struct.Process, ptr %189, i32 0, i32 2
  %191 = load i32, ptr %190, align 4
  %192 = load i32, ptr %4, align 4
  %193 = xor i32 %192, 1211381168
  %194 = xor i32 %191, %193
  %195 = add i32 %185, %194
  %196 = load i32, ptr %4, align 4
  %197 = xor i32 %196, -1211381170
  %198 = add i32 %195, %197
  store i32 %198, ptr %12, align 4
  %199 = load i32, ptr %11, align 4
  %200 = load i32, ptr %12, align 4
  %201 = icmp sgt i32 %199, %200
  %202 = select i1 %201, i32 817785228, i32 -213745647
  store i32 %202, ptr %4, align 4
  %203 = xor i32 %1, 1277434511
  %204 = and i32 %1, %203
  %205 = or i32 %1, %203
  %206 = xor i32 %1, %203
  %207 = mul i32 %205, 2
  %208 = sub i32 %207, %206
  %209 = sub i32 %208, %1
  %210 = sub i32 %209, %203
  %211 = mul i32 %210, 251
  %212 = icmp sle i32 %211, 0
  br i1 %212, label %304, label %459

213:                                              ; preds = %13
  %214 = load i32, ptr %8, align 4
  store i32 %214, ptr %7, align 4
  store i32 -213745647, ptr %4, align 4
  %215 = xor i32 %1, 276445373
  %216 = and i32 %1, %215
  %217 = or i32 %1, %215
  %218 = xor i32 %1, %215
  %219 = sub i32 %217, %218
  %220 = sub i32 %219, %216
  %221 = mul i32 %220, 118
  %222 = icmp slt i32 %221, 0
  br i1 %222, label %468, label %304

223:                                              ; preds = %13
  store i32 1100443811, ptr %4, align 4
  %224 = xor i32 %1, -1324717143
  %225 = and i32 %1, %224
  %226 = or i32 %1, %224
  %227 = xor i32 %1, %224
  %228 = mul i32 %226, 2
  %229 = sub i32 %228, %227
  %230 = sub i32 %229, %1
  %231 = sub i32 %230, %224
  %232 = mul i32 %231, 89
  %233 = icmp slt i32 %232, 1
  br i1 %233, label %304, label %475

234:                                              ; preds = %13
  store i32 562818531, ptr %4, align 4
  %235 = xor i32 %1, -1704379853
  %236 = and i32 %1, %235
  %237 = or i32 %1, %235
  %238 = xor i32 %1, %235
  %239 = add i32 %1, %235
  %240 = sub i32 %239, %238
  %241 = mul i32 %236, 2
  %242 = sub i32 %240, %241
  %243 = mul i32 %242, 61
  %244 = icmp uge i32 %243, 0
  br i1 %244, label %304, label %485

245:                                              ; preds = %13
  %246 = load i32, ptr %8, align 4
  %247 = load i32, ptr %4, align 4
  %248 = xor i32 %247, 562818530
  %249 = or i32 %246, %248
  %250 = load i32, ptr %4, align 4
  %251 = xor i32 %250, 562818530
  %252 = and i32 %246, %251
  %253 = add i32 %249, %252
  store i32 %253, ptr %8, align 4
  store i32 831966494, ptr %4, align 4
  %254 = xor i32 %1, 519150599
  %255 = and i32 %1, %254
  %256 = or i32 %1, %254
  %257 = xor i32 %1, %254
  %258 = add i32 %1, %254
  %259 = sub i32 %258, %257
  %260 = mul i32 %255, 2
  %261 = sub i32 %259, %260
  %262 = mul i32 %261, 168
  %263 = icmp slt i32 %262, 1
  br i1 %263, label %304, label %495

264:                                              ; preds = %13
  %265 = load ptr, ptr %5, align 8
  %266 = load i32, ptr %7, align 4
  %267 = sext i32 %266 to i64
  %268 = getelementptr inbounds %struct.Process, ptr %265, i64 %267
  %269 = getelementptr inbounds nuw %struct.Process, ptr %268, i32 0, i32 0
  %270 = load i32, ptr %269, align 4
  %271 = load ptr, ptr %5, align 8
  %272 = load i32, ptr %7, align 4
  %273 = sext i32 %272 to i64
  %274 = getelementptr inbounds %struct.Process, ptr %271, i64 %273
  %275 = getelementptr inbounds nuw %struct.Process, ptr %274, i32 0, i32 8
  %276 = load i32, ptr %275, align 4
  %277 = load ptr, ptr %5, align 8
  %278 = load i32, ptr %7, align 4
  %279 = sext i32 %278 to i64
  %280 = getelementptr inbounds %struct.Process, ptr %277, i64 %279
  %281 = getelementptr inbounds nuw %struct.Process, ptr %280, i32 0, i32 6
  %282 = load i32, ptr %281, align 4
  %283 = load ptr, ptr %5, align 8
  %284 = load i32, ptr %7, align 4
  %285 = sext i32 %284 to i64
  %286 = getelementptr inbounds %struct.Process, ptr %283, i64 %285
  %287 = getelementptr inbounds nuw %struct.Process, ptr %286, i32 0, i32 8
  %288 = load i32, ptr %287, align 4
  %289 = load ptr, ptr %5, align 8
  %290 = load i32, ptr %7, align 4
  %291 = sext i32 %290 to i64
  %292 = getelementptr inbounds %struct.Process, ptr %289, i64 %291
  %293 = getelementptr inbounds nuw %struct.Process, ptr %292, i32 0, i32 6
  %294 = load i32, ptr %293, align 4
  %295 = load i32, ptr %4, align 4
  %296 = xor i32 %295, -61207935
  %297 = xor i32 %294, %296
  %298 = add i32 %288, %297
  %299 = load i32, ptr %4, align 4
  %300 = xor i32 %299, 61207935
  %301 = add i32 %298, %300
  %302 = call i32 @maxInt(i32 noundef 0, i32 noundef %301)
  %303 = call i32 (ptr, ...) @printf(ptr noundef @.str.16, i32 noundef %270, i32 noundef %276, i32 noundef %282, i32 noundef %302)
  ret void

304:                                              ; preds = %574, %564, %555, %546, %539, %529, %519, %510, %495, %485, %475, %468, %459, %452, %444, %437, %429, %421, %409, %397, %376, %365, %352, %340, %329, %316, %245, %234, %223, %213, %132, %117, %105, %50, %35, %17
  br label %13

305:                                              ; preds = %13
  store i32 1610561347, ptr %4, align 4
  call void asm sideeffect "", ""()
  %306 = xor i32 %1, 1730828061
  %307 = and i32 %1, %306
  %308 = or i32 %1, %306
  %309 = xor i32 %1, %306
  %310 = mul i32 %308, 2
  %311 = sub i32 %310, %309
  %312 = sub i32 %311, %1
  %313 = sub i32 %312, %306
  %314 = mul i32 %313, 98
  %315 = icmp sle i32 %314, 0
  br i1 %315, label %13, label %502

316:                                              ; preds = %13
  %317 = load i32, ptr %4, align 4
  %318 = xor i32 %317, 1178975248
  store i32 %318, ptr %4, align 4
  %319 = xor i32 %1, 2043487381
  %320 = and i32 %1, %319
  %321 = or i32 %1, %319
  %322 = xor i32 %1, %319
  %323 = mul i32 %321, 2
  %324 = sub i32 %323, %322
  %325 = sub i32 %324, %1
  %326 = sub i32 %325, %319
  %327 = mul i32 %326, 72
  %328 = icmp sle i32 %327, 0
  br i1 %328, label %304, label %510

329:                                              ; preds = %13
  %330 = load i32, ptr %4, align 4
  %331 = xor i32 %330, -458682271
  store i32 %331, ptr %4, align 4
  %332 = xor i32 %1, 149199881
  %333 = and i32 %1, %332
  %334 = or i32 %1, %332
  %335 = xor i32 %1, %332
  %336 = sub i32 %334, %335
  %337 = sub i32 %336, %333
  %338 = mul i32 %337, 16
  %339 = icmp eq i32 %338, 0
  br i1 %339, label %304, label %519

340:                                              ; preds = %13
  %341 = load i32, ptr %4, align 4
  %342 = xor i32 %341, -2002521307
  store i32 %342, ptr %4, align 4
  %343 = xor i32 %1, 1476488069
  %344 = and i32 %1, %343
  %345 = or i32 %1, %343
  %346 = xor i32 %1, %343
  %347 = add i32 %344, %345
  %348 = sub i32 %347, %1
  %349 = sub i32 %348, %343
  %350 = mul i32 %349, 253
  %351 = icmp slt i32 %350, 1
  br i1 %351, label %304, label %529

352:                                              ; preds = %13
  %353 = load i32, ptr %4, align 4
  %354 = xor i32 %353, -1373999498
  store i32 %354, ptr %4, align 4
  %355 = xor i32 %1, -2004412955
  %356 = and i32 %1, %355
  %357 = or i32 %1, %355
  %358 = xor i32 %1, %355
  %359 = add i32 %1, %355
  %360 = sub i32 %359, %358
  %361 = mul i32 %356, 2
  %362 = sub i32 %360, %361
  %363 = mul i32 %362, 27
  %364 = icmp sle i32 %363, 0
  br i1 %364, label %304, label %539

365:                                              ; preds = %13
  %366 = load i32, ptr %4, align 4
  %367 = xor i32 %366, -1243459984
  store i32 %367, ptr %4, align 4
  %368 = xor i32 %1, 1270786123
  %369 = and i32 %1, %368
  %370 = or i32 %1, %368
  %371 = xor i32 %1, %368
  %372 = sub i32 %370, %371
  %373 = sub i32 %372, %369
  %374 = mul i32 %373, 196
  %375 = icmp uge i32 %374, 0
  br i1 %375, label %304, label %546

376:                                              ; preds = %13
  %377 = load i32, ptr %4, align 4
  %378 = xor i32 %377, 990359215
  store i32 %378, ptr %4, align 4
  %379 = xor i32 %1, -2008828411
  %380 = and i32 %1, %379
  %381 = or i32 %1, %379
  %382 = xor i32 %1, %379
  %383 = add i32 %1, %379
  %384 = sub i32 %383, %382
  %385 = mul i32 %380, 2
  %386 = sub i32 %384, %385
  %387 = mul i32 %386, 226
  %388 = xor i32 %1, -1247580179
  %389 = and i32 %1, %388
  %390 = or i32 %1, %388
  %391 = xor i32 %1, %388
  %392 = add i32 %389, %390
  %393 = sub i32 %392, %1
  %394 = sub i32 %393, %388
  %395 = mul i32 %394, 88
  %396 = icmp ne i32 %387, %395
  br i1 %396, label %555, label %304

397:                                              ; preds = %13
  %398 = load i32, ptr %4, align 4
  %399 = xor i32 %398, 51768876
  store i32 %399, ptr %4, align 4
  %400 = xor i32 %1, -1743967431
  %401 = and i32 %1, %400
  %402 = or i32 %1, %400
  %403 = xor i32 %1, %400
  %404 = add i32 %401, %402
  %405 = sub i32 %404, %1
  %406 = sub i32 %405, %400
  %407 = mul i32 %406, 198
  %408 = icmp eq i32 %407, 0
  br i1 %408, label %304, label %564

409:                                              ; preds = %13
  %410 = load i32, ptr %4, align 4
  %411 = xor i32 %410, 70863365
  store i32 %411, ptr %4, align 4
  %412 = xor i32 %1, 1886752887
  %413 = and i32 %1, %412
  %414 = or i32 %1, %412
  %415 = xor i32 %1, %412
  %416 = add i32 %413, %414
  %417 = sub i32 %416, %1
  %418 = sub i32 %417, %412
  %419 = mul i32 %418, 108
  %420 = icmp sle i32 %419, 0
  br i1 %420, label %304, label %574

421:                                              ; preds = %17
  %422 = load i64, ptr %3, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = zext i32 %1 to i64
  %425 = add i64 %423, %424
  %426 = xor i64 %425, %423
  %427 = add i64 %426, %422
  %428 = xor i64 %427, %424
  store i64 %428, ptr %3, align 8
  br label %304

429:                                              ; preds = %35
  %430 = load i64, ptr %3, align 8
  %431 = ptrtoint ptr %0 to i64
  %432 = zext i32 %1 to i64
  %433 = sub i64 %431, %432
  %434 = or i64 %433, %432
  %435 = xor i64 %434, %431
  %436 = and i64 %435, %430
  store i64 %436, ptr %3, align 8
  br label %304

437:                                              ; preds = %50
  %438 = load i64, ptr %3, align 8
  %439 = ptrtoint ptr %0 to i64
  %440 = zext i32 %1 to i64
  %441 = add i64 %439, %440
  %442 = sub i64 %441, %439
  %443 = or i64 %442, %440
  store i64 %443, ptr %3, align 8
  br label %304

444:                                              ; preds = %105
  %445 = load i64, ptr %3, align 8
  %446 = ptrtoint ptr %0 to i64
  %447 = zext i32 %1 to i64
  %448 = or i64 %447, %447
  %449 = or i64 %448, %445
  %450 = xor i64 %449, %445
  %451 = mul i64 %450, %447
  store i64 %451, ptr %3, align 8
  br label %304

452:                                              ; preds = %117
  %453 = load i64, ptr %3, align 8
  %454 = ptrtoint ptr %0 to i64
  %455 = zext i32 %1 to i64
  %456 = and i64 %453, %453
  %457 = and i64 %456, %454
  %458 = or i64 %457, %453
  store i64 %458, ptr %3, align 8
  br label %304

459:                                              ; preds = %132
  %460 = load i64, ptr %3, align 8
  %461 = ptrtoint ptr %0 to i64
  %462 = zext i32 %1 to i64
  %463 = or i64 %462, %460
  %464 = sub i64 %463, %462
  %465 = mul i64 %464, %461
  %466 = or i64 %465, %460
  %467 = xor i64 %466, %460
  store i64 %467, ptr %3, align 8
  br label %304

468:                                              ; preds = %213
  %469 = load i64, ptr %3, align 8
  %470 = ptrtoint ptr %0 to i64
  %471 = zext i32 %1 to i64
  %472 = add i64 %469, %471
  %473 = add i64 %472, %471
  %474 = and i64 %473, %471
  store i64 %474, ptr %3, align 8
  br label %304

475:                                              ; preds = %223
  %476 = load i64, ptr %3, align 8
  %477 = ptrtoint ptr %0 to i64
  %478 = zext i32 %1 to i64
  %479 = and i64 %476, %476
  %480 = and i64 %479, %477
  %481 = sub i64 %480, %477
  %482 = sub i64 %481, %476
  %483 = sub i64 %482, %478
  %484 = mul i64 %483, %478
  store i64 %484, ptr %3, align 8
  br label %304

485:                                              ; preds = %234
  %486 = load i64, ptr %3, align 8
  %487 = ptrtoint ptr %0 to i64
  %488 = zext i32 %1 to i64
  %489 = or i64 %487, %486
  %490 = or i64 %489, %486
  %491 = add i64 %490, %486
  %492 = and i64 %491, %486
  %493 = xor i64 %492, %487
  %494 = add i64 %493, %488
  store i64 %494, ptr %3, align 8
  br label %304

495:                                              ; preds = %245
  %496 = load i64, ptr %3, align 8
  %497 = ptrtoint ptr %0 to i64
  %498 = zext i32 %1 to i64
  %499 = and i64 %496, %498
  %500 = sub i64 %499, %498
  %501 = or i64 %500, %497
  store i64 %501, ptr %3, align 8
  br label %304

502:                                              ; preds = %305
  %503 = load i64, ptr %3, align 8
  %504 = ptrtoint ptr %0 to i64
  %505 = zext i32 %1 to i64
  %506 = mul i64 %503, %505
  %507 = or i64 %506, %503
  %508 = and i64 %507, %504
  %509 = add i64 %508, %505
  store i64 %509, ptr %3, align 8
  br label %13

510:                                              ; preds = %316
  %511 = load i64, ptr %3, align 8
  %512 = ptrtoint ptr %0 to i64
  %513 = zext i32 %1 to i64
  %514 = sub i64 %513, %511
  %515 = or i64 %514, %511
  %516 = sub i64 %515, %512
  %517 = xor i64 %516, %511
  %518 = add i64 %517, %513
  store i64 %518, ptr %3, align 8
  br label %304

519:                                              ; preds = %329
  %520 = load i64, ptr %3, align 8
  %521 = ptrtoint ptr %0 to i64
  %522 = zext i32 %1 to i64
  %523 = mul i64 %520, %520
  %524 = sub i64 %523, %521
  %525 = sub i64 %524, %520
  %526 = and i64 %525, %522
  %527 = or i64 %526, %522
  %528 = add i64 %527, %522
  store i64 %528, ptr %3, align 8
  br label %304

529:                                              ; preds = %340
  %530 = load i64, ptr %3, align 8
  %531 = ptrtoint ptr %0 to i64
  %532 = zext i32 %1 to i64
  %533 = mul i64 %531, %530
  %534 = xor i64 %533, %532
  %535 = or i64 %534, %531
  %536 = sub i64 %535, %532
  %537 = sub i64 %536, %530
  %538 = or i64 %537, %532
  store i64 %538, ptr %3, align 8
  br label %304

539:                                              ; preds = %352
  %540 = load i64, ptr %3, align 8
  %541 = ptrtoint ptr %0 to i64
  %542 = zext i32 %1 to i64
  %543 = mul i64 %540, %541
  %544 = add i64 %543, %542
  %545 = mul i64 %544, %541
  store i64 %545, ptr %3, align 8
  br label %304

546:                                              ; preds = %365
  %547 = load i64, ptr %3, align 8
  %548 = ptrtoint ptr %0 to i64
  %549 = zext i32 %1 to i64
  %550 = and i64 %548, %547
  %551 = add i64 %550, %547
  %552 = sub i64 %551, %548
  %553 = add i64 %552, %548
  %554 = and i64 %553, %548
  store i64 %554, ptr %3, align 8
  br label %304

555:                                              ; preds = %376
  %556 = load i64, ptr %3, align 8
  %557 = ptrtoint ptr %0 to i64
  %558 = zext i32 %1 to i64
  %559 = or i64 %556, %558
  %560 = or i64 %559, %557
  %561 = mul i64 %560, %557
  %562 = xor i64 %561, %557
  %563 = or i64 %562, %556
  store i64 %563, ptr %3, align 8
  br label %304

564:                                              ; preds = %397
  %565 = load i64, ptr %3, align 8
  %566 = ptrtoint ptr %0 to i64
  %567 = zext i32 %1 to i64
  %568 = xor i64 %566, %565
  %569 = or i64 %568, %566
  %570 = mul i64 %569, %566
  %571 = add i64 %570, %567
  %572 = sub i64 %571, %566
  %573 = or i64 %572, %567
  store i64 %573, ptr %3, align 8
  br label %304

574:                                              ; preds = %409
  %575 = load i64, ptr %3, align 8
  %576 = ptrtoint ptr %0 to i64
  %577 = zext i32 %1 to i64
  %578 = and i64 %577, %575
  %579 = mul i64 %578, %577
  %580 = mul i64 %579, %577
  %581 = xor i64 %580, %577
  store i64 %581, ptr %3, align 8
  br label %304
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @0, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca %struct.SegmentList, align 8
  store i32 -1042287111, ptr %3, align 4
  br label %8

8:                                                ; preds = %273, %124, %123, %0
  %9 = load i32, ptr %3, align 4
  %10 = sub i32 %9, -85723054
  %11 = mul i32 %10, 175301011
  switch i32 %11, label %124 [
    i32 922775013, label %12
    i32 1655731430, label %35
    i32 1256244593, label %46
    i32 194521383, label %60
    i32 1677421748, label %74
    i32 1126415162, label %84
    i32 937701960, label %121
    i32 1241192014, label %135
    i32 6537712, label %146
    i32 1576190514, label %159
    i32 519195531, label %180
    i32 274904136, label %193
    i32 685281370, label %206
    i32 1479816577, label %219
  ]

12:                                               ; preds = %8
  store i32 0, ptr %4, align 4
  %13 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str.17, ptr noundef %5)
  %14 = icmp ne i32 %13, 1
  %15 = select i1 %14, i32 -2096326764, i32 -248010819
  store i32 %15, ptr %3, align 4
  %16 = xor i32 %2, 1171740579
  %17 = and i32 %2, %16
  %18 = or i32 %2, %16
  %19 = xor i32 %2, %16
  %20 = add i32 %2, %16
  %21 = sub i32 %20, %19
  %22 = mul i32 %17, 2
  %23 = sub i32 %21, %22
  %24 = mul i32 %23, 50
  %25 = xor i32 %2, 422920491
  %26 = and i32 %2, %25
  %27 = or i32 %2, %25
  %28 = xor i32 %2, %25
  %29 = mul i32 %27, 2
  %30 = sub i32 %29, %28
  %31 = sub i32 %30, %2
  %32 = sub i32 %31, %25
  %33 = mul i32 %32, 94
  %34 = icmp ne i32 %24, %33
  br i1 %34, label %232, label %123

35:                                               ; preds = %8
  %36 = call i32 (ptr, ...) @printf(ptr noundef @.str.18)
  store i32 0, ptr %4, align 4
  store i32 -611153430, ptr %3, align 4
  %37 = xor i32 %2, 369446389
  %38 = and i32 %2, %37
  %39 = or i32 %2, %37
  %40 = xor i32 %2, %37
  %41 = add i32 %38, %39
  %42 = sub i32 %41, %2
  %43 = sub i32 %42, %37
  %44 = mul i32 %43, 245
  %45 = icmp slt i32 %44, 1
  br i1 %45, label %123, label %240

46:                                               ; preds = %8
  %47 = load i32, ptr %5, align 4
  %48 = icmp slt i32 %47, 1
  %49 = select i1 %48, i32 1564809550, i32 932978415
  store i32 %49, ptr %3, align 4
  %50 = xor i32 %2, 1488290801
  %51 = and i32 %2, %50
  %52 = or i32 %2, %50
  %53 = xor i32 %2, %50
  %54 = mul i32 %52, 2
  %55 = sub i32 %54, %53
  %56 = sub i32 %55, %2
  %57 = sub i32 %56, %50
  %58 = mul i32 %57, 65
  %59 = icmp sgt i32 %58, 0
  br i1 %59, label %248, label %123

60:                                               ; preds = %8
  %61 = load i32, ptr %5, align 4
  %62 = icmp sgt i32 %61, 100
  %63 = select i1 %62, i32 1564809550, i32 -662635408
  store i32 %63, ptr %3, align 4
  %64 = xor i32 %2, 855786237
  %65 = and i32 %2, %64
  %66 = or i32 %2, %64
  %67 = xor i32 %2, %64
  %68 = add i32 %2, %64
  %69 = sub i32 %68, %67
  %70 = mul i32 %65, 2
  %71 = sub i32 %69, %70
  %72 = mul i32 %71, 168
  %73 = icmp ugt i32 %72, 0
  br i1 %73, label %255, label %123

74:                                               ; preds = %8
  %75 = call i32 (ptr, ...) @printf(ptr noundef @.str.19, i32 noundef 100)
  store i32 0, ptr %4, align 4
  store i32 -611153430, ptr %3, align 4
  %76 = xor i32 %2, -1764973675
  %77 = and i32 %2, %76
  %78 = or i32 %2, %76
  %79 = xor i32 %2, %76
  %80 = sub i32 %78, %79
  %81 = sub i32 %80, %77
  %82 = mul i32 %81, 36
  %83 = icmp sgt i32 %82, 0
  br i1 %83, label %262, label %123

84:                                               ; preds = %8
  %85 = load i32, ptr %5, align 4
  %86 = sext i32 %85 to i64
  %87 = mul i64 36, %86
  %88 = call noalias ptr @malloc(i64 noundef %87) #6
  store ptr %88, ptr %6, align 8
  call void @initSegments(ptr noundef %7)
  %89 = load ptr, ptr %6, align 8
  %90 = load i32, ptr %5, align 4
  call void @generateProcesses(ptr noundef %89, i32 noundef %90)
  %91 = call i32 (ptr, ...) @printf(ptr noundef @.str.20)
  %92 = load i32, ptr %5, align 4
  %93 = call i32 (ptr, ...) @printf(ptr noundef @.str.21, i32 noundef %92)
  %94 = call i32 (ptr, ...) @printf(ptr noundef @.str.22, i32 noundef 4)
  %95 = load ptr, ptr %6, align 8
  %96 = load i32, ptr %5, align 4
  call void @printProcessTable(ptr noundef %95, i32 noundef %96)
  %97 = load ptr, ptr %6, align 8
  %98 = load i32, ptr %5, align 4
  call void @simulate(ptr noundef %97, i32 noundef %98, ptr noundef %7)
  call void @printGanttChart(ptr noundef %7)
  %99 = load ptr, ptr %6, align 8
  %100 = load i32, ptr %5, align 4
  call void @printResultTable(ptr noundef %99, i32 noundef %100)
  %101 = load ptr, ptr %6, align 8
  %102 = load i32, ptr %5, align 4
  call void @printWorstProcess(ptr noundef %101, i32 noundef %102)
  %103 = getelementptr inbounds nuw %struct.SegmentList, ptr %7, i32 0, i32 0
  %104 = load ptr, ptr %103, align 8
  call void @free(ptr noundef %104) #8
  %105 = load ptr, ptr %6, align 8
  call void @free(ptr noundef %105) #8
  store i32 0, ptr %4, align 4
  store i32 -611153430, ptr %3, align 4
  %106 = xor i32 %2, -425163297
  %107 = and i32 %2, %106
  %108 = or i32 %2, %106
  %109 = xor i32 %2, %106
  %110 = sub i32 %108, %109
  %111 = sub i32 %110, %107
  %112 = mul i32 %111, 196
  %113 = xor i32 %2, 709884177
  %114 = and i32 %2, %113
  %115 = or i32 %2, %113
  %116 = xor i32 %2, %113
  %117 = sub i32 %115, %116
  %118 = sub i32 %117, %114
  %119 = mul i32 %118, 89
  %120 = icmp eq i32 %112, %119
  br i1 %120, label %123, label %266

121:                                              ; preds = %8
  %122 = load i32, ptr %4, align 4
  ret i32 %122

123:                                              ; preds = %316, %309, %305, %301, %294, %289, %281, %266, %262, %255, %248, %240, %232, %219, %206, %193, %180, %159, %146, %135, %84, %74, %60, %46, %35, %12
  br label %8

124:                                              ; preds = %8
  store i32 -1042287111, ptr %3, align 4
  call void asm sideeffect "", ""()
  %125 = xor i32 %2, 1883552513
  %126 = and i32 %2, %125
  %127 = or i32 %2, %125
  %128 = xor i32 %2, %125
  %129 = mul i32 %127, 2
  %130 = sub i32 %129, %128
  %131 = sub i32 %130, %2
  %132 = sub i32 %131, %125
  %133 = mul i32 %132, 80
  %134 = icmp slt i32 %133, 1
  br i1 %134, label %8, label %273

135:                                              ; preds = %8
  %136 = load i32, ptr %3, align 4
  %137 = xor i32 %136, -713252097
  store i32 %137, ptr %3, align 4
  %138 = xor i32 %2, 127281701
  %139 = and i32 %2, %138
  %140 = or i32 %2, %138
  %141 = xor i32 %2, %138
  %142 = sub i32 %140, %141
  %143 = sub i32 %142, %139
  %144 = mul i32 %143, 158
  %145 = icmp eq i32 %144, 0
  br i1 %145, label %123, label %281

146:                                              ; preds = %8
  %147 = load i32, ptr %3, align 4
  %148 = xor i32 %147, 418431095
  store i32 %148, ptr %3, align 4
  %149 = xor i32 %2, 1480346503
  %150 = and i32 %2, %149
  %151 = or i32 %2, %149
  %152 = xor i32 %2, %149
  %153 = mul i32 %151, 2
  %154 = sub i32 %153, %152
  %155 = sub i32 %154, %2
  %156 = sub i32 %155, %149
  %157 = mul i32 %156, 101
  %158 = icmp slt i32 %157, 1
  br i1 %158, label %123, label %289

159:                                              ; preds = %8
  %160 = load i32, ptr %3, align 4
  %161 = xor i32 %160, 2141811005
  store i32 %161, ptr %3, align 4
  %162 = xor i32 %2, -1035512891
  %163 = and i32 %2, %162
  %164 = or i32 %2, %162
  %165 = xor i32 %2, %162
  %166 = mul i32 %164, 2
  %167 = sub i32 %166, %165
  %168 = sub i32 %167, %2
  %169 = sub i32 %168, %162
  %170 = mul i32 %169, 214
  %171 = xor i32 %2, -1050926771
  %172 = and i32 %2, %171
  %173 = or i32 %2, %171
  %174 = xor i32 %2, %171
  %175 = add i32 %172, %173
  %176 = sub i32 %175, %2
  %177 = sub i32 %176, %171
  %178 = mul i32 %177, 91
  %179 = icmp eq i32 %170, %178
  br i1 %179, label %123, label %294

180:                                              ; preds = %8
  %181 = load i32, ptr %3, align 4
  %182 = xor i32 %181, -139334530
  store i32 %182, ptr %3, align 4
  %183 = xor i32 %2, -880675023
  %184 = and i32 %2, %183
  %185 = or i32 %2, %183
  %186 = xor i32 %2, %183
  %187 = add i32 %2, %183
  %188 = sub i32 %187, %186
  %189 = mul i32 %184, 2
  %190 = sub i32 %188, %189
  %191 = mul i32 %190, 114
  %192 = icmp slt i32 %191, 1
  br i1 %192, label %123, label %301

193:                                              ; preds = %8
  %194 = load i32, ptr %3, align 4
  %195 = xor i32 %194, 1587664561
  store i32 %195, ptr %3, align 4
  %196 = xor i32 %2, 1485548545
  %197 = and i32 %2, %196
  %198 = or i32 %2, %196
  %199 = xor i32 %2, %196
  %200 = mul i32 %198, 2
  %201 = sub i32 %200, %199
  %202 = sub i32 %201, %2
  %203 = sub i32 %202, %196
  %204 = mul i32 %203, 235
  %205 = icmp eq i32 %204, 0
  br i1 %205, label %123, label %305

206:                                              ; preds = %8
  %207 = load i32, ptr %3, align 4
  %208 = xor i32 %207, -1140217390
  store i32 %208, ptr %3, align 4
  %209 = xor i32 %2, -551007539
  %210 = and i32 %2, %209
  %211 = or i32 %2, %209
  %212 = xor i32 %2, %209
  %213 = add i32 %2, %209
  %214 = sub i32 %213, %212
  %215 = mul i32 %210, 2
  %216 = sub i32 %214, %215
  %217 = mul i32 %216, 6
  %218 = icmp uge i32 %217, 0
  br i1 %218, label %123, label %309

219:                                              ; preds = %8
  %220 = load i32, ptr %3, align 4
  %221 = xor i32 %220, -1060805180
  store i32 %221, ptr %3, align 4
  %222 = xor i32 %2, 1215892705
  %223 = and i32 %2, %222
  %224 = or i32 %2, %222
  %225 = xor i32 %2, %222
  %226 = mul i32 %224, 2
  %227 = sub i32 %226, %225
  %228 = sub i32 %227, %2
  %229 = sub i32 %228, %222
  %230 = mul i32 %229, 236
  %231 = icmp ne i32 %230, 0
  br i1 %231, label %316, label %123

232:                                              ; preds = %12
  %233 = load i64, ptr %1, align 8
  %234 = and i64 %233, 2585872320
  %235 = and i64 %234, %233
  %236 = and i64 %235, 3673205398
  %237 = add i64 %236, %233
  %238 = mul i64 %237, 3673205398
  %239 = add i64 %238, 2585872320
  store i64 %239, ptr %1, align 8
  br label %123

240:                                              ; preds = %35
  %241 = load i64, ptr %1, align 8
  %242 = sub i64 %241, 275715285
  %243 = mul i64 %242, %241
  %244 = sub i64 %243, 1703286623
  %245 = mul i64 %244, 275715285
  %246 = xor i64 %245, 1703286623
  %247 = xor i64 %246, %241
  store i64 %247, ptr %1, align 8
  br label %123

248:                                              ; preds = %46
  %249 = load i64, ptr %1, align 8
  %250 = or i64 3365809112, %249
  %251 = sub i64 %250, 3365809112
  %252 = add i64 %251, 1204694513
  %253 = mul i64 %252, %249
  %254 = sub i64 %253, 3365809112
  store i64 %254, ptr %1, align 8
  br label %123

255:                                              ; preds = %60
  %256 = load i64, ptr %1, align 8
  %257 = sub i64 %256, %256
  %258 = sub i64 %257, %256
  %259 = add i64 %258, 2776710041
  %260 = mul i64 %259, %256
  %261 = add i64 %260, %256
  store i64 %261, ptr %1, align 8
  br label %123

262:                                              ; preds = %74
  %263 = load i64, ptr %1, align 8
  %264 = or i64 3673657943, %263
  %265 = add i64 %264, %263
  store i64 %265, ptr %1, align 8
  br label %123

266:                                              ; preds = %84
  %267 = load i64, ptr %1, align 8
  %268 = xor i64 341502825, %267
  %269 = and i64 %268, 341502825
  %270 = sub i64 %269, 341502825
  %271 = add i64 %270, %267
  %272 = and i64 %271, 341502825
  store i64 %272, ptr %1, align 8
  br label %123

273:                                              ; preds = %124
  %274 = load i64, ptr %1, align 8
  %275 = mul i64 %274, 527129024
  %276 = mul i64 %275, %274
  %277 = and i64 %276, 527129024
  %278 = xor i64 %277, %274
  %279 = add i64 %278, %274
  %280 = sub i64 %279, 2980414040
  store i64 %280, ptr %1, align 8
  br label %8

281:                                              ; preds = %135
  %282 = load i64, ptr %1, align 8
  %283 = mul i64 %282, 3174626438
  %284 = or i64 %283, 3174626438
  %285 = or i64 %284, 3174626438
  %286 = sub i64 %285, 4289011821
  %287 = sub i64 %286, 4289011821
  %288 = xor i64 %287, 3174626438
  store i64 %288, ptr %1, align 8
  br label %123

289:                                              ; preds = %146
  %290 = load i64, ptr %1, align 8
  %291 = xor i64 2502559657, %290
  %292 = and i64 %291, %290
  %293 = xor i64 %292, 2502559657
  store i64 %293, ptr %1, align 8
  br label %123

294:                                              ; preds = %159
  %295 = load i64, ptr %1, align 8
  %296 = add i64 %295, 1393662457
  %297 = and i64 %296, 3556593597
  %298 = xor i64 %297, 3556593597
  %299 = xor i64 %298, 3556593597
  %300 = and i64 %299, 3556593597
  store i64 %300, ptr %1, align 8
  br label %123

301:                                              ; preds = %180
  %302 = load i64, ptr %1, align 8
  %303 = and i64 3984972868, %302
  %304 = sub i64 %303, 1992486434
  store i64 %304, ptr %1, align 8
  br label %123

305:                                              ; preds = %193
  %306 = load i64, ptr %1, align 8
  %307 = add i64 535454104, %306
  %308 = sub i64 %307, %306
  store i64 %308, ptr %1, align 8
  br label %123

309:                                              ; preds = %206
  %310 = load i64, ptr %1, align 8
  %311 = or i64 %310, 2637083032
  %312 = sub i64 %311, 2637083032
  %313 = and i64 %312, 2637083032
  %314 = sub i64 %313, 3724494363
  %315 = sub i64 %314, 3724494363
  store i64 %315, ptr %1, align 8
  br label %123

316:                                              ; preds = %219
  %317 = load i64, ptr %1, align 8
  %318 = and i64 3661182703, %317
  %319 = sub i64 %318, %317
  %320 = or i64 %319, 1333359729
  %321 = or i64 %320, %317
  %322 = mul i64 %321, 3661182703
  %323 = xor i64 %322, 1333359729
  store i64 %323, ptr %1, align 8
  br label %123
}

declare i32 @__isoc99_scanf(ptr noundef, ...) #3

; Function Attrs: nounwind
declare void @free(ptr noundef) #5

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind allocsize(0) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind allocsize(1) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
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

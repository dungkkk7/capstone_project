; ModuleID = 'data/obfuscated/maze/clean.bc'
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

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @inside(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = icmp sge i32 %5, 0
  br i1 %6, label %7, label %18

7:                                                ; preds = %2
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr @N, align 4
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %11, label %18

11:                                               ; preds = %7
  %12 = load i32, ptr %4, align 4
  %13 = icmp sge i32 %12, 0
  br i1 %13, label %14, label %18

14:                                               ; preds = %11
  %15 = load i32, ptr %4, align 4
  %16 = load i32, ptr @N, align 4
  %17 = icmp slt i32 %15, %16
  br label %18

18:                                               ; preds = %14, %11, %7, %2
  %19 = phi i1 [ false, %11 ], [ false, %7 ], [ false, %2 ], [ %17, %14 ]
  %20 = zext i1 %19 to i32
  ret i32 %20
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
  %9 = add nsw i32 %7, %8
  ret i32 %9
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
  %2 = alloca i32, align 4
  %3 = alloca i8, align 1
  store i8 %0, ptr %3, align 1
  %4 = load i8, ptr %3, align 1
  %5 = sext i8 %4 to i32
  %6 = icmp eq i32 %5, 35
  br i1 %6, label %7, label %8

7:                                                ; preds = %1
  store i32 1000000000, ptr %2, align 4
  br label %19

8:                                                ; preds = %1
  %9 = load i8, ptr %3, align 1
  %10 = sext i8 %9 to i32
  %11 = icmp eq i32 %10, 94
  br i1 %11, label %12, label %13

12:                                               ; preds = %8
  store i32 5, ptr %2, align 4
  br label %19

13:                                               ; preds = %8
  %14 = load i8, ptr %3, align 1
  %15 = sext i8 %14 to i32
  %16 = icmp eq i32 %15, 126
  br i1 %16, label %17, label %18

17:                                               ; preds = %13
  store i32 3, ptr %2, align 4
  br label %19

18:                                               ; preds = %13
  store i32 1, ptr %2, align 4
  br label %19

19:                                               ; preds = %18, %17, %12, %7
  %20 = load i32, ptr %2, align 4
  ret i32 %20
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local ptr @createHeap(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  store i32 %0, ptr %2, align 4
  %4 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %4, ptr %3, align 8
  %5 = load i32, ptr %2, align 4
  %6 = add nsw i32 %5, 5
  %7 = sext i32 %6 to i64
  %8 = mul i64 8, %7
  %9 = call noalias ptr @malloc(i64 noundef %8) #6
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds nuw %struct.MinHeap, ptr %10, i32 0, i32 0
  store ptr %9, ptr %11, align 8
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.MinHeap, ptr %12, i32 0, i32 1
  store i32 0, ptr %13, align 8
  %14 = load i32, ptr %2, align 4
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds nuw %struct.MinHeap, ptr %15, i32 0, i32 2
  store i32 %14, ptr %16, align 4
  %17 = load ptr, ptr %3, align 8
  ret ptr %17
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
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %9 = load ptr, ptr %4, align 8
  %10 = getelementptr inbounds nuw %struct.MinHeap, ptr %9, i32 0, i32 1
  %11 = load i32, ptr %10, align 8
  %12 = add nsw i32 %11, 2
  %13 = load ptr, ptr %4, align 8
  %14 = getelementptr inbounds nuw %struct.MinHeap, ptr %13, i32 0, i32 2
  %15 = load i32, ptr %14, align 4
  %16 = icmp sge i32 %12, %15
  br i1 %16, label %17, label %34

17:                                               ; preds = %3
  %18 = load ptr, ptr %4, align 8
  %19 = getelementptr inbounds nuw %struct.MinHeap, ptr %18, i32 0, i32 2
  %20 = load i32, ptr %19, align 4
  %21 = mul nsw i32 %20, 2
  store i32 %21, ptr %19, align 4
  %22 = load ptr, ptr %4, align 8
  %23 = getelementptr inbounds nuw %struct.MinHeap, ptr %22, i32 0, i32 0
  %24 = load ptr, ptr %23, align 8
  %25 = load ptr, ptr %4, align 8
  %26 = getelementptr inbounds nuw %struct.MinHeap, ptr %25, i32 0, i32 2
  %27 = load i32, ptr %26, align 4
  %28 = add nsw i32 %27, 5
  %29 = sext i32 %28 to i64
  %30 = mul i64 8, %29
  %31 = call ptr @realloc(ptr noundef %24, i64 noundef %30) #7
  %32 = load ptr, ptr %4, align 8
  %33 = getelementptr inbounds nuw %struct.MinHeap, ptr %32, i32 0, i32 0
  store ptr %31, ptr %33, align 8
  br label %34

34:                                               ; preds = %17, %3
  %35 = load ptr, ptr %4, align 8
  %36 = getelementptr inbounds nuw %struct.MinHeap, ptr %35, i32 0, i32 1
  %37 = load i32, ptr %36, align 8
  %38 = add nsw i32 %37, 1
  store i32 %38, ptr %36, align 8
  %39 = load ptr, ptr %4, align 8
  %40 = getelementptr inbounds nuw %struct.MinHeap, ptr %39, i32 0, i32 1
  %41 = load i32, ptr %40, align 8
  store i32 %41, ptr %7, align 4
  %42 = load i32, ptr %5, align 4
  %43 = load ptr, ptr %4, align 8
  %44 = getelementptr inbounds nuw %struct.MinHeap, ptr %43, i32 0, i32 0
  %45 = load ptr, ptr %44, align 8
  %46 = load i32, ptr %7, align 4
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds %struct.Point, ptr %45, i64 %47
  %49 = getelementptr inbounds nuw %struct.Point, ptr %48, i32 0, i32 0
  store i32 %42, ptr %49, align 4
  %50 = load i32, ptr %6, align 4
  %51 = load ptr, ptr %4, align 8
  %52 = getelementptr inbounds nuw %struct.MinHeap, ptr %51, i32 0, i32 0
  %53 = load ptr, ptr %52, align 8
  %54 = load i32, ptr %7, align 4
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds %struct.Point, ptr %53, i64 %55
  %57 = getelementptr inbounds nuw %struct.Point, ptr %56, i32 0, i32 1
  store i32 %50, ptr %57, align 4
  br label %58

58:                                               ; preds = %119, %34
  %59 = load i32, ptr %7, align 4
  %60 = icmp sgt i32 %59, 1
  br i1 %60, label %61, label %133

61:                                               ; preds = %58
  %62 = load i32, ptr %7, align 4
  %63 = sdiv i32 %62, 2
  store i32 %63, ptr %8, align 4
  %64 = load ptr, ptr %4, align 8
  %65 = getelementptr inbounds nuw %struct.MinHeap, ptr %64, i32 0, i32 0
  %66 = load ptr, ptr %65, align 8
  %67 = load i32, ptr %8, align 4
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds %struct.Point, ptr %66, i64 %68
  %70 = getelementptr inbounds nuw %struct.Point, ptr %69, i32 0, i32 1
  %71 = load i32, ptr %70, align 4
  %72 = load ptr, ptr %4, align 8
  %73 = getelementptr inbounds nuw %struct.MinHeap, ptr %72, i32 0, i32 0
  %74 = load ptr, ptr %73, align 8
  %75 = load i32, ptr %7, align 4
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds %struct.Point, ptr %74, i64 %76
  %78 = getelementptr inbounds nuw %struct.Point, ptr %77, i32 0, i32 1
  %79 = load i32, ptr %78, align 4
  %80 = icmp slt i32 %71, %79
  br i1 %80, label %81, label %82

81:                                               ; preds = %61
  br label %133

82:                                               ; preds = %61
  %83 = load ptr, ptr %4, align 8
  %84 = getelementptr inbounds nuw %struct.MinHeap, ptr %83, i32 0, i32 0
  %85 = load ptr, ptr %84, align 8
  %86 = load i32, ptr %8, align 4
  %87 = sext i32 %86 to i64
  %88 = getelementptr inbounds %struct.Point, ptr %85, i64 %87
  %89 = getelementptr inbounds nuw %struct.Point, ptr %88, i32 0, i32 1
  %90 = load i32, ptr %89, align 4
  %91 = load ptr, ptr %4, align 8
  %92 = getelementptr inbounds nuw %struct.MinHeap, ptr %91, i32 0, i32 0
  %93 = load ptr, ptr %92, align 8
  %94 = load i32, ptr %7, align 4
  %95 = sext i32 %94 to i64
  %96 = getelementptr inbounds %struct.Point, ptr %93, i64 %95
  %97 = getelementptr inbounds nuw %struct.Point, ptr %96, i32 0, i32 1
  %98 = load i32, ptr %97, align 4
  %99 = icmp eq i32 %90, %98
  br i1 %99, label %100, label %119

100:                                              ; preds = %82
  %101 = load ptr, ptr %4, align 8
  %102 = getelementptr inbounds nuw %struct.MinHeap, ptr %101, i32 0, i32 0
  %103 = load ptr, ptr %102, align 8
  %104 = load i32, ptr %8, align 4
  %105 = sext i32 %104 to i64
  %106 = getelementptr inbounds %struct.Point, ptr %103, i64 %105
  %107 = getelementptr inbounds nuw %struct.Point, ptr %106, i32 0, i32 0
  %108 = load i32, ptr %107, align 4
  %109 = load ptr, ptr %4, align 8
  %110 = getelementptr inbounds nuw %struct.MinHeap, ptr %109, i32 0, i32 0
  %111 = load ptr, ptr %110, align 8
  %112 = load i32, ptr %7, align 4
  %113 = sext i32 %112 to i64
  %114 = getelementptr inbounds %struct.Point, ptr %111, i64 %113
  %115 = getelementptr inbounds nuw %struct.Point, ptr %114, i32 0, i32 0
  %116 = load i32, ptr %115, align 4
  %117 = icmp slt i32 %108, %116
  br i1 %117, label %118, label %119

118:                                              ; preds = %100
  br label %133

119:                                              ; preds = %100, %82
  %120 = load ptr, ptr %4, align 8
  %121 = getelementptr inbounds nuw %struct.MinHeap, ptr %120, i32 0, i32 0
  %122 = load ptr, ptr %121, align 8
  %123 = load i32, ptr %8, align 4
  %124 = sext i32 %123 to i64
  %125 = getelementptr inbounds %struct.Point, ptr %122, i64 %124
  %126 = load ptr, ptr %4, align 8
  %127 = getelementptr inbounds nuw %struct.MinHeap, ptr %126, i32 0, i32 0
  %128 = load ptr, ptr %127, align 8
  %129 = load i32, ptr %7, align 4
  %130 = sext i32 %129 to i64
  %131 = getelementptr inbounds %struct.Point, ptr %128, i64 %130
  call void @swapNode(ptr noundef %125, ptr noundef %131)
  %132 = load i32, ptr %8, align 4
  store i32 %132, ptr %7, align 4
  br label %58, !llvm.loop !6

133:                                              ; preds = %118, %81, %58
  ret void
}

; Function Attrs: nounwind allocsize(1)
declare ptr @realloc(ptr noundef, i64 noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i64 @popHeap(ptr noundef %0) #0 {
  %2 = alloca %struct.Point, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %8 = load ptr, ptr %3, align 8
  %9 = getelementptr inbounds nuw %struct.MinHeap, ptr %8, i32 0, i32 0
  %10 = load ptr, ptr %9, align 8
  %11 = getelementptr inbounds %struct.Point, ptr %10, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %2, ptr align 4 %11, i64 8, i1 false)
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.MinHeap, ptr %12, i32 0, i32 0
  %14 = load ptr, ptr %13, align 8
  %15 = getelementptr inbounds %struct.Point, ptr %14, i64 1
  %16 = load ptr, ptr %3, align 8
  %17 = getelementptr inbounds nuw %struct.MinHeap, ptr %16, i32 0, i32 0
  %18 = load ptr, ptr %17, align 8
  %19 = load ptr, ptr %3, align 8
  %20 = getelementptr inbounds nuw %struct.MinHeap, ptr %19, i32 0, i32 1
  %21 = load i32, ptr %20, align 8
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds %struct.Point, ptr %18, i64 %22
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %15, ptr align 4 %23, i64 8, i1 false)
  %24 = load ptr, ptr %3, align 8
  %25 = getelementptr inbounds nuw %struct.MinHeap, ptr %24, i32 0, i32 1
  %26 = load i32, ptr %25, align 8
  %27 = add nsw i32 %26, -1
  store i32 %27, ptr %25, align 8
  store i32 1, ptr %4, align 4
  br label %28

28:                                               ; preds = %1, %165
  %29 = load i32, ptr %4, align 4
  %30 = mul nsw i32 %29, 2
  store i32 %30, ptr %5, align 4
  %31 = load i32, ptr %4, align 4
  %32 = mul nsw i32 %31, 2
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %6, align 4
  %34 = load i32, ptr %4, align 4
  store i32 %34, ptr %7, align 4
  %35 = load i32, ptr %5, align 4
  %36 = load ptr, ptr %3, align 8
  %37 = getelementptr inbounds nuw %struct.MinHeap, ptr %36, i32 0, i32 1
  %38 = load i32, ptr %37, align 8
  %39 = icmp sle i32 %35, %38
  br i1 %39, label %40, label %97

40:                                               ; preds = %28
  %41 = load ptr, ptr %3, align 8
  %42 = getelementptr inbounds nuw %struct.MinHeap, ptr %41, i32 0, i32 0
  %43 = load ptr, ptr %42, align 8
  %44 = load i32, ptr %5, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds %struct.Point, ptr %43, i64 %45
  %47 = getelementptr inbounds nuw %struct.Point, ptr %46, i32 0, i32 1
  %48 = load i32, ptr %47, align 4
  %49 = load ptr, ptr %3, align 8
  %50 = getelementptr inbounds nuw %struct.MinHeap, ptr %49, i32 0, i32 0
  %51 = load ptr, ptr %50, align 8
  %52 = load i32, ptr %7, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds %struct.Point, ptr %51, i64 %53
  %55 = getelementptr inbounds nuw %struct.Point, ptr %54, i32 0, i32 1
  %56 = load i32, ptr %55, align 4
  %57 = icmp slt i32 %48, %56
  br i1 %57, label %94, label %58

58:                                               ; preds = %40
  %59 = load ptr, ptr %3, align 8
  %60 = getelementptr inbounds nuw %struct.MinHeap, ptr %59, i32 0, i32 0
  %61 = load ptr, ptr %60, align 8
  %62 = load i32, ptr %5, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds %struct.Point, ptr %61, i64 %63
  %65 = getelementptr inbounds nuw %struct.Point, ptr %64, i32 0, i32 1
  %66 = load i32, ptr %65, align 4
  %67 = load ptr, ptr %3, align 8
  %68 = getelementptr inbounds nuw %struct.MinHeap, ptr %67, i32 0, i32 0
  %69 = load ptr, ptr %68, align 8
  %70 = load i32, ptr %7, align 4
  %71 = sext i32 %70 to i64
  %72 = getelementptr inbounds %struct.Point, ptr %69, i64 %71
  %73 = getelementptr inbounds nuw %struct.Point, ptr %72, i32 0, i32 1
  %74 = load i32, ptr %73, align 4
  %75 = icmp eq i32 %66, %74
  br i1 %75, label %76, label %96

76:                                               ; preds = %58
  %77 = load ptr, ptr %3, align 8
  %78 = getelementptr inbounds nuw %struct.MinHeap, ptr %77, i32 0, i32 0
  %79 = load ptr, ptr %78, align 8
  %80 = load i32, ptr %5, align 4
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds %struct.Point, ptr %79, i64 %81
  %83 = getelementptr inbounds nuw %struct.Point, ptr %82, i32 0, i32 0
  %84 = load i32, ptr %83, align 4
  %85 = load ptr, ptr %3, align 8
  %86 = getelementptr inbounds nuw %struct.MinHeap, ptr %85, i32 0, i32 0
  %87 = load ptr, ptr %86, align 8
  %88 = load i32, ptr %7, align 4
  %89 = sext i32 %88 to i64
  %90 = getelementptr inbounds %struct.Point, ptr %87, i64 %89
  %91 = getelementptr inbounds nuw %struct.Point, ptr %90, i32 0, i32 0
  %92 = load i32, ptr %91, align 4
  %93 = icmp slt i32 %84, %92
  br i1 %93, label %94, label %96

94:                                               ; preds = %76, %40
  %95 = load i32, ptr %5, align 4
  store i32 %95, ptr %7, align 4
  br label %96

96:                                               ; preds = %94, %76, %58
  br label %97

97:                                               ; preds = %96, %28
  %98 = load i32, ptr %6, align 4
  %99 = load ptr, ptr %3, align 8
  %100 = getelementptr inbounds nuw %struct.MinHeap, ptr %99, i32 0, i32 1
  %101 = load i32, ptr %100, align 8
  %102 = icmp sle i32 %98, %101
  br i1 %102, label %103, label %160

103:                                              ; preds = %97
  %104 = load ptr, ptr %3, align 8
  %105 = getelementptr inbounds nuw %struct.MinHeap, ptr %104, i32 0, i32 0
  %106 = load ptr, ptr %105, align 8
  %107 = load i32, ptr %6, align 4
  %108 = sext i32 %107 to i64
  %109 = getelementptr inbounds %struct.Point, ptr %106, i64 %108
  %110 = getelementptr inbounds nuw %struct.Point, ptr %109, i32 0, i32 1
  %111 = load i32, ptr %110, align 4
  %112 = load ptr, ptr %3, align 8
  %113 = getelementptr inbounds nuw %struct.MinHeap, ptr %112, i32 0, i32 0
  %114 = load ptr, ptr %113, align 8
  %115 = load i32, ptr %7, align 4
  %116 = sext i32 %115 to i64
  %117 = getelementptr inbounds %struct.Point, ptr %114, i64 %116
  %118 = getelementptr inbounds nuw %struct.Point, ptr %117, i32 0, i32 1
  %119 = load i32, ptr %118, align 4
  %120 = icmp slt i32 %111, %119
  br i1 %120, label %157, label %121

121:                                              ; preds = %103
  %122 = load ptr, ptr %3, align 8
  %123 = getelementptr inbounds nuw %struct.MinHeap, ptr %122, i32 0, i32 0
  %124 = load ptr, ptr %123, align 8
  %125 = load i32, ptr %6, align 4
  %126 = sext i32 %125 to i64
  %127 = getelementptr inbounds %struct.Point, ptr %124, i64 %126
  %128 = getelementptr inbounds nuw %struct.Point, ptr %127, i32 0, i32 1
  %129 = load i32, ptr %128, align 4
  %130 = load ptr, ptr %3, align 8
  %131 = getelementptr inbounds nuw %struct.MinHeap, ptr %130, i32 0, i32 0
  %132 = load ptr, ptr %131, align 8
  %133 = load i32, ptr %7, align 4
  %134 = sext i32 %133 to i64
  %135 = getelementptr inbounds %struct.Point, ptr %132, i64 %134
  %136 = getelementptr inbounds nuw %struct.Point, ptr %135, i32 0, i32 1
  %137 = load i32, ptr %136, align 4
  %138 = icmp eq i32 %129, %137
  br i1 %138, label %139, label %159

139:                                              ; preds = %121
  %140 = load ptr, ptr %3, align 8
  %141 = getelementptr inbounds nuw %struct.MinHeap, ptr %140, i32 0, i32 0
  %142 = load ptr, ptr %141, align 8
  %143 = load i32, ptr %6, align 4
  %144 = sext i32 %143 to i64
  %145 = getelementptr inbounds %struct.Point, ptr %142, i64 %144
  %146 = getelementptr inbounds nuw %struct.Point, ptr %145, i32 0, i32 0
  %147 = load i32, ptr %146, align 4
  %148 = load ptr, ptr %3, align 8
  %149 = getelementptr inbounds nuw %struct.MinHeap, ptr %148, i32 0, i32 0
  %150 = load ptr, ptr %149, align 8
  %151 = load i32, ptr %7, align 4
  %152 = sext i32 %151 to i64
  %153 = getelementptr inbounds %struct.Point, ptr %150, i64 %152
  %154 = getelementptr inbounds nuw %struct.Point, ptr %153, i32 0, i32 0
  %155 = load i32, ptr %154, align 4
  %156 = icmp slt i32 %147, %155
  br i1 %156, label %157, label %159

157:                                              ; preds = %139, %103
  %158 = load i32, ptr %6, align 4
  store i32 %158, ptr %7, align 4
  br label %159

159:                                              ; preds = %157, %139, %121
  br label %160

160:                                              ; preds = %159, %97
  %161 = load i32, ptr %7, align 4
  %162 = load i32, ptr %4, align 4
  %163 = icmp eq i32 %161, %162
  br i1 %163, label %164, label %165

164:                                              ; preds = %160
  br label %179

165:                                              ; preds = %160
  %166 = load ptr, ptr %3, align 8
  %167 = getelementptr inbounds nuw %struct.MinHeap, ptr %166, i32 0, i32 0
  %168 = load ptr, ptr %167, align 8
  %169 = load i32, ptr %4, align 4
  %170 = sext i32 %169 to i64
  %171 = getelementptr inbounds %struct.Point, ptr %168, i64 %170
  %172 = load ptr, ptr %3, align 8
  %173 = getelementptr inbounds nuw %struct.MinHeap, ptr %172, i32 0, i32 0
  %174 = load ptr, ptr %173, align 8
  %175 = load i32, ptr %7, align 4
  %176 = sext i32 %175 to i64
  %177 = getelementptr inbounds %struct.Point, ptr %174, i64 %176
  call void @swapNode(ptr noundef %171, ptr noundef %177)
  %178 = load i32, ptr %7, align 4
  store i32 %178, ptr %4, align 4
  br label %28

179:                                              ; preds = %164
  %180 = load i64, ptr %2, align 4
  ret i64 %180
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
  %1 = alloca i32, align 4
  %2 = load i32, ptr @N, align 4
  %3 = sext i32 %2 to i64
  %4 = mul i64 8, %3
  %5 = call noalias ptr @malloc(i64 noundef %4) #6
  store ptr %5, ptr @grid, align 8
  store i32 0, ptr %1, align 4
  br label %6

6:                                                ; preds = %28, %0
  %7 = load i32, ptr %1, align 4
  %8 = load i32, ptr @N, align 4
  %9 = icmp slt i32 %7, %8
  br i1 %9, label %10, label %31

10:                                               ; preds = %6
  %11 = load i32, ptr @N, align 4
  %12 = add nsw i32 %11, 1
  %13 = sext i32 %12 to i64
  %14 = mul i64 1, %13
  %15 = call noalias ptr @malloc(i64 noundef %14) #6
  %16 = load ptr, ptr @grid, align 8
  %17 = load i32, ptr %1, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds ptr, ptr %16, i64 %18
  store ptr %15, ptr %19, align 8
  %20 = load ptr, ptr @grid, align 8
  %21 = load i32, ptr %1, align 4
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds ptr, ptr %20, i64 %22
  %24 = load ptr, ptr %23, align 8
  %25 = load i32, ptr @N, align 4
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds i8, ptr %24, i64 %26
  store i8 0, ptr %27, align 1
  br label %28

28:                                               ; preds = %10
  %29 = load i32, ptr %1, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %1, align 4
  br label %6, !llvm.loop !8

31:                                               ; preds = %6
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @freeGrid() #0 {
  %1 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %12, %0
  %3 = load i32, ptr %1, align 4
  %4 = load i32, ptr @N, align 4
  %5 = icmp slt i32 %3, %4
  br i1 %5, label %6, label %15

6:                                                ; preds = %2
  %7 = load ptr, ptr @grid, align 8
  %8 = load i32, ptr %1, align 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds ptr, ptr %7, i64 %9
  %11 = load ptr, ptr %10, align 8
  call void @free(ptr noundef %11) #8
  br label %12

12:                                               ; preds = %6
  %13 = load i32, ptr %1, align 4
  %14 = add nsw i32 %13, 1
  store i32 %14, ptr %1, align 4
  br label %2, !llvm.loop !9

15:                                               ; preds = %2
  %16 = load ptr, ptr @grid, align 8
  call void @free(ptr noundef %16) #8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @carveRow(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %9 = load i32, ptr %5, align 4
  %10 = load i32, ptr %6, align 4
  %11 = icmp sgt i32 %9, %10
  br i1 %11, label %12, label %16

12:                                               ; preds = %3
  %13 = load i32, ptr %5, align 4
  store i32 %13, ptr %7, align 4
  %14 = load i32, ptr %6, align 4
  store i32 %14, ptr %5, align 4
  %15 = load i32, ptr %7, align 4
  store i32 %15, ptr %6, align 4
  br label %16

16:                                               ; preds = %12, %3
  %17 = load i32, ptr %5, align 4
  store i32 %17, ptr %8, align 4
  br label %18

18:                                               ; preds = %31, %16
  %19 = load i32, ptr %8, align 4
  %20 = load i32, ptr %6, align 4
  %21 = icmp sle i32 %19, %20
  br i1 %21, label %22, label %34

22:                                               ; preds = %18
  %23 = load ptr, ptr @grid, align 8
  %24 = load i32, ptr %4, align 4
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds ptr, ptr %23, i64 %25
  %27 = load ptr, ptr %26, align 8
  %28 = load i32, ptr %8, align 4
  %29 = sext i32 %28 to i64
  %30 = getelementptr inbounds i8, ptr %27, i64 %29
  store i8 46, ptr %30, align 1
  br label %31

31:                                               ; preds = %22
  %32 = load i32, ptr %8, align 4
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %8, align 4
  br label %18, !llvm.loop !10

34:                                               ; preds = %18
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @carveCol(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %9 = load i32, ptr %5, align 4
  %10 = load i32, ptr %6, align 4
  %11 = icmp sgt i32 %9, %10
  br i1 %11, label %12, label %16

12:                                               ; preds = %3
  %13 = load i32, ptr %5, align 4
  store i32 %13, ptr %7, align 4
  %14 = load i32, ptr %6, align 4
  store i32 %14, ptr %5, align 4
  %15 = load i32, ptr %7, align 4
  store i32 %15, ptr %6, align 4
  br label %16

16:                                               ; preds = %12, %3
  %17 = load i32, ptr %5, align 4
  store i32 %17, ptr %8, align 4
  br label %18

18:                                               ; preds = %31, %16
  %19 = load i32, ptr %8, align 4
  %20 = load i32, ptr %6, align 4
  %21 = icmp sle i32 %19, %20
  br i1 %21, label %22, label %34

22:                                               ; preds = %18
  %23 = load ptr, ptr @grid, align 8
  %24 = load i32, ptr %8, align 4
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds ptr, ptr %23, i64 %25
  %27 = load ptr, ptr %26, align 8
  %28 = load i32, ptr %4, align 4
  %29 = sext i32 %28 to i64
  %30 = getelementptr inbounds i8, ptr %27, i64 %29
  store i8 46, ptr %30, align 1
  br label %31

31:                                               ; preds = %22
  %32 = load i32, ptr %8, align 4
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %8, align 4
  br label %18, !llvm.loop !11

34:                                               ; preds = %18
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @samePoint(i64 %0, i64 %1) #0 {
  %3 = alloca %struct.Point, align 4
  %4 = alloca %struct.Point, align 4
  store i64 %0, ptr %3, align 4
  store i64 %1, ptr %4, align 4
  %5 = getelementptr inbounds nuw %struct.Point, ptr %3, i32 0, i32 0
  %6 = load i32, ptr %5, align 4
  %7 = getelementptr inbounds nuw %struct.Point, ptr %4, i32 0, i32 0
  %8 = load i32, ptr %7, align 4
  %9 = icmp eq i32 %6, %8
  br i1 %9, label %10, label %16

10:                                               ; preds = %2
  %11 = getelementptr inbounds nuw %struct.Point, ptr %3, i32 0, i32 1
  %12 = load i32, ptr %11, align 4
  %13 = getelementptr inbounds nuw %struct.Point, ptr %4, i32 0, i32 1
  %14 = load i32, ptr %13, align 4
  %15 = icmp eq i32 %12, %14
  br label %16

16:                                               ; preds = %10, %2
  %17 = phi i1 [ false, %2 ], [ %15, %10 ]
  %18 = zext i1 %17 to i32
  ret i32 %18
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @usedPoint(ptr noundef %0, i32 noundef %1, i64 %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca %struct.Point, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i64 %2, ptr %5, align 4
  store ptr %0, ptr %6, align 8
  store i32 %1, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %24, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %7, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %27

13:                                               ; preds = %9
  %14 = load ptr, ptr %6, align 8
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds %struct.Point, ptr %14, i64 %16
  %18 = load i64, ptr %17, align 4
  %19 = load i64, ptr %5, align 4
  %20 = call i32 @samePoint(i64 %18, i64 %19)
  %21 = icmp ne i32 %20, 0
  br i1 %21, label %22, label %23

22:                                               ; preds = %13
  store i32 1, ptr %4, align 4
  br label %28

23:                                               ; preds = %13
  br label %24

24:                                               ; preds = %23
  %25 = load i32, ptr %8, align 4
  %26 = add nsw i32 %25, 1
  store i32 %26, ptr %8, align 4
  br label %9, !llvm.loop !12

27:                                               ; preds = %9
  store i32 0, ptr %4, align 4
  br label %28

28:                                               ; preds = %27, %22
  %29 = load i32, ptr %4, align 4
  ret i32 %29
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @generateDungeon(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca %struct.Point, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store ptr %3, ptr %8, align 8
  %17 = load ptr, ptr %5, align 8
  %18 = getelementptr inbounds nuw %struct.Point, ptr %17, i32 0, i32 0
  store i32 0, ptr %18, align 4
  %19 = load ptr, ptr %5, align 8
  %20 = getelementptr inbounds nuw %struct.Point, ptr %19, i32 0, i32 1
  store i32 0, ptr %20, align 4
  %21 = load i32, ptr @N, align 4
  %22 = sub nsw i32 %21, 1
  %23 = load ptr, ptr %6, align 8
  %24 = getelementptr inbounds nuw %struct.Point, ptr %23, i32 0, i32 0
  store i32 %22, ptr %24, align 4
  %25 = load i32, ptr @N, align 4
  %26 = sub nsw i32 %25, 1
  %27 = load ptr, ptr %6, align 8
  %28 = getelementptr inbounds nuw %struct.Point, ptr %27, i32 0, i32 1
  store i32 %26, ptr %28, align 4
  store i32 0, ptr %9, align 4
  br label %29

29:                                               ; preds = %104, %4
  %30 = load i32, ptr %9, align 4
  %31 = load i32, ptr @N, align 4
  %32 = icmp slt i32 %30, %31
  br i1 %32, label %33, label %107

33:                                               ; preds = %29
  store i32 0, ptr %10, align 4
  br label %34

34:                                               ; preds = %100, %33
  %35 = load i32, ptr %10, align 4
  %36 = load i32, ptr @N, align 4
  %37 = icmp slt i32 %35, %36
  br i1 %37, label %38, label %103

38:                                               ; preds = %34
  %39 = load i32, ptr %9, align 4
  %40 = mul nsw i32 %39, 37
  %41 = load i32, ptr %10, align 4
  %42 = mul nsw i32 %41, 19
  %43 = add nsw i32 %40, %42
  %44 = load i32, ptr @N, align 4
  %45 = mul nsw i32 %44, 11
  %46 = add nsw i32 %43, %45
  %47 = load i32, ptr %9, align 4
  %48 = load i32, ptr %10, align 4
  %49 = mul nsw i32 %47, %48
  %50 = mul nsw i32 %49, 7
  %51 = add nsw i32 %46, %50
  %52 = srem i32 %51, 17
  store i32 %52, ptr %11, align 4
  %53 = load i32, ptr %11, align 4
  %54 = icmp slt i32 %53, 3
  br i1 %54, label %55, label %64

55:                                               ; preds = %38
  %56 = load ptr, ptr @grid, align 8
  %57 = load i32, ptr %9, align 4
  %58 = sext i32 %57 to i64
  %59 = getelementptr inbounds ptr, ptr %56, i64 %58
  %60 = load ptr, ptr %59, align 8
  %61 = load i32, ptr %10, align 4
  %62 = sext i32 %61 to i64
  %63 = getelementptr inbounds i8, ptr %60, i64 %62
  store i8 35, ptr %63, align 1
  br label %99

64:                                               ; preds = %38
  %65 = load i32, ptr %11, align 4
  %66 = icmp slt i32 %65, 5
  br i1 %66, label %67, label %76

67:                                               ; preds = %64
  %68 = load ptr, ptr @grid, align 8
  %69 = load i32, ptr %9, align 4
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds ptr, ptr %68, i64 %70
  %72 = load ptr, ptr %71, align 8
  %73 = load i32, ptr %10, align 4
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds i8, ptr %72, i64 %74
  store i8 94, ptr %75, align 1
  br label %98

76:                                               ; preds = %64
  %77 = load i32, ptr %11, align 4
  %78 = icmp slt i32 %77, 7
  br i1 %78, label %79, label %88

79:                                               ; preds = %76
  %80 = load ptr, ptr @grid, align 8
  %81 = load i32, ptr %9, align 4
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds ptr, ptr %80, i64 %82
  %84 = load ptr, ptr %83, align 8
  %85 = load i32, ptr %10, align 4
  %86 = sext i32 %85 to i64
  %87 = getelementptr inbounds i8, ptr %84, i64 %86
  store i8 126, ptr %87, align 1
  br label %97

88:                                               ; preds = %76
  %89 = load ptr, ptr @grid, align 8
  %90 = load i32, ptr %9, align 4
  %91 = sext i32 %90 to i64
  %92 = getelementptr inbounds ptr, ptr %89, i64 %91
  %93 = load ptr, ptr %92, align 8
  %94 = load i32, ptr %10, align 4
  %95 = sext i32 %94 to i64
  %96 = getelementptr inbounds i8, ptr %93, i64 %95
  store i8 46, ptr %96, align 1
  br label %97

97:                                               ; preds = %88, %79
  br label %98

98:                                               ; preds = %97, %67
  br label %99

99:                                               ; preds = %98, %55
  br label %100

100:                                              ; preds = %99
  %101 = load i32, ptr %10, align 4
  %102 = add nsw i32 %101, 1
  store i32 %102, ptr %10, align 4
  br label %34, !llvm.loop !13

103:                                              ; preds = %34
  br label %104

104:                                              ; preds = %103
  %105 = load i32, ptr %9, align 4
  %106 = add nsw i32 %105, 1
  store i32 %106, ptr %9, align 4
  br label %29, !llvm.loop !14

107:                                              ; preds = %29
  %108 = load i32, ptr @N, align 4
  %109 = sub nsw i32 %108, 1
  call void @carveRow(i32 noundef 0, i32 noundef 0, i32 noundef %109)
  %110 = load i32, ptr @N, align 4
  %111 = sub nsw i32 %110, 1
  %112 = load i32, ptr @N, align 4
  %113 = sub nsw i32 %112, 1
  call void @carveCol(i32 noundef %111, i32 noundef 0, i32 noundef %113)
  %114 = load i32, ptr @N, align 4
  %115 = sdiv i32 %114, 3
  store i32 %115, ptr %12, align 4
  %116 = load i32, ptr %12, align 4
  %117 = icmp slt i32 %116, 1
  br i1 %117, label %118, label %119

118:                                              ; preds = %107
  store i32 1, ptr %12, align 4
  br label %119

119:                                              ; preds = %118, %107
  %120 = load i32, ptr %12, align 4
  %121 = icmp sgt i32 %120, 8
  br i1 %121, label %122, label %123

122:                                              ; preds = %119
  store i32 8, ptr %12, align 4
  br label %123

123:                                              ; preds = %122, %119
  %124 = load ptr, ptr %8, align 8
  store i32 0, ptr %124, align 4
  store i32 0, ptr %13, align 4
  br label %125

125:                                              ; preds = %211, %123
  %126 = load i32, ptr %13, align 4
  %127 = load i32, ptr %12, align 4
  %128 = icmp slt i32 %126, %127
  br i1 %128, label %129, label %214

129:                                              ; preds = %125
  %130 = load i32, ptr %13, align 4
  %131 = mul nsw i32 %130, 2
  %132 = load i32, ptr @N, align 4
  %133 = sdiv i32 %132, 2
  %134 = add nsw i32 %131, %133
  %135 = load i32, ptr @N, align 4
  %136 = srem i32 %134, %135
  %137 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 0
  store i32 %136, ptr %137, align 4
  %138 = load i32, ptr %13, align 4
  %139 = mul nsw i32 %138, 3
  %140 = add nsw i32 %139, 1
  %141 = load i32, ptr @N, align 4
  %142 = srem i32 %140, %141
  %143 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 1
  store i32 %142, ptr %143, align 4
  store i32 0, ptr %15, align 4
  br label %144

144:                                              ; preds = %187, %129
  %145 = load ptr, ptr %5, align 8
  %146 = load i64, ptr %14, align 4
  %147 = load i64, ptr %145, align 4
  %148 = call i32 @samePoint(i64 %146, i64 %147)
  %149 = icmp ne i32 %148, 0
  br i1 %149, label %163, label %150

150:                                              ; preds = %144
  %151 = load ptr, ptr %6, align 8
  %152 = load i64, ptr %14, align 4
  %153 = load i64, ptr %151, align 4
  %154 = call i32 @samePoint(i64 %152, i64 %153)
  %155 = icmp ne i32 %154, 0
  br i1 %155, label %163, label %156

156:                                              ; preds = %150
  %157 = load ptr, ptr %7, align 8
  %158 = load ptr, ptr %8, align 8
  %159 = load i32, ptr %158, align 4
  %160 = load i64, ptr %14, align 4
  %161 = call i32 @usedPoint(ptr noundef %157, i32 noundef %159, i64 %160)
  %162 = icmp ne i32 %161, 0
  br i1 %162, label %163, label %169

163:                                              ; preds = %156, %150, %144
  %164 = load i32, ptr %15, align 4
  %165 = load i32, ptr @N, align 4
  %166 = load i32, ptr @N, align 4
  %167 = mul nsw i32 %165, %166
  %168 = icmp slt i32 %164, %167
  br label %169

169:                                              ; preds = %163, %156
  %170 = phi i1 [ false, %156 ], [ %168, %163 ]
  br i1 %170, label %171, label %190

171:                                              ; preds = %169
  %172 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 1
  %173 = load i32, ptr %172, align 4
  %174 = add nsw i32 %173, 1
  store i32 %174, ptr %172, align 4
  %175 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 1
  %176 = load i32, ptr %175, align 4
  %177 = load i32, ptr @N, align 4
  %178 = icmp eq i32 %176, %177
  br i1 %178, label %179, label %187

179:                                              ; preds = %171
  %180 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 1
  store i32 0, ptr %180, align 4
  %181 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 0
  %182 = load i32, ptr %181, align 4
  %183 = add nsw i32 %182, 1
  %184 = load i32, ptr @N, align 4
  %185 = srem i32 %183, %184
  %186 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 0
  store i32 %185, ptr %186, align 4
  br label %187

187:                                              ; preds = %179, %171
  %188 = load i32, ptr %15, align 4
  %189 = add nsw i32 %188, 1
  store i32 %189, ptr %15, align 4
  br label %144, !llvm.loop !15

190:                                              ; preds = %169
  %191 = load ptr, ptr %7, align 8
  %192 = load ptr, ptr %8, align 8
  %193 = load i32, ptr %192, align 4
  %194 = sext i32 %193 to i64
  %195 = getelementptr inbounds %struct.Point, ptr %191, i64 %194
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %195, ptr align 4 %14, i64 8, i1 false)
  %196 = load ptr, ptr %8, align 8
  %197 = load i32, ptr %196, align 4
  %198 = add nsw i32 %197, 1
  store i32 %198, ptr %196, align 4
  %199 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 0
  %200 = load i32, ptr %199, align 4
  %201 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 1
  %202 = load i32, ptr %201, align 4
  %203 = load i32, ptr @N, align 4
  %204 = sub nsw i32 %203, 1
  call void @carveRow(i32 noundef %200, i32 noundef %202, i32 noundef %204)
  %205 = load i32, ptr @N, align 4
  %206 = sub nsw i32 %205, 1
  %207 = getelementptr inbounds nuw %struct.Point, ptr %14, i32 0, i32 0
  %208 = load i32, ptr %207, align 4
  %209 = load i32, ptr @N, align 4
  %210 = sub nsw i32 %209, 1
  call void @carveCol(i32 noundef %206, i32 noundef %208, i32 noundef %210)
  br label %211

211:                                              ; preds = %190
  %212 = load i32, ptr %13, align 4
  %213 = add nsw i32 %212, 1
  store i32 %213, ptr %13, align 4
  br label %125, !llvm.loop !16

214:                                              ; preds = %125
  %215 = load ptr, ptr @grid, align 8
  %216 = load ptr, ptr %5, align 8
  %217 = getelementptr inbounds nuw %struct.Point, ptr %216, i32 0, i32 0
  %218 = load i32, ptr %217, align 4
  %219 = sext i32 %218 to i64
  %220 = getelementptr inbounds ptr, ptr %215, i64 %219
  %221 = load ptr, ptr %220, align 8
  %222 = load ptr, ptr %5, align 8
  %223 = getelementptr inbounds nuw %struct.Point, ptr %222, i32 0, i32 1
  %224 = load i32, ptr %223, align 4
  %225 = sext i32 %224 to i64
  %226 = getelementptr inbounds i8, ptr %221, i64 %225
  store i8 83, ptr %226, align 1
  %227 = load ptr, ptr @grid, align 8
  %228 = load ptr, ptr %6, align 8
  %229 = getelementptr inbounds nuw %struct.Point, ptr %228, i32 0, i32 0
  %230 = load i32, ptr %229, align 4
  %231 = sext i32 %230 to i64
  %232 = getelementptr inbounds ptr, ptr %227, i64 %231
  %233 = load ptr, ptr %232, align 8
  %234 = load ptr, ptr %6, align 8
  %235 = getelementptr inbounds nuw %struct.Point, ptr %234, i32 0, i32 1
  %236 = load i32, ptr %235, align 4
  %237 = sext i32 %236 to i64
  %238 = getelementptr inbounds i8, ptr %233, i64 %237
  store i8 69, ptr %238, align 1
  store i32 0, ptr %16, align 4
  br label %239

239:                                              ; preds = %263, %214
  %240 = load i32, ptr %16, align 4
  %241 = load ptr, ptr %8, align 8
  %242 = load i32, ptr %241, align 4
  %243 = icmp slt i32 %240, %242
  br i1 %243, label %244, label %266

244:                                              ; preds = %239
  %245 = load ptr, ptr @grid, align 8
  %246 = load ptr, ptr %7, align 8
  %247 = load i32, ptr %16, align 4
  %248 = sext i32 %247 to i64
  %249 = getelementptr inbounds %struct.Point, ptr %246, i64 %248
  %250 = getelementptr inbounds nuw %struct.Point, ptr %249, i32 0, i32 0
  %251 = load i32, ptr %250, align 4
  %252 = sext i32 %251 to i64
  %253 = getelementptr inbounds ptr, ptr %245, i64 %252
  %254 = load ptr, ptr %253, align 8
  %255 = load ptr, ptr %7, align 8
  %256 = load i32, ptr %16, align 4
  %257 = sext i32 %256 to i64
  %258 = getelementptr inbounds %struct.Point, ptr %255, i64 %257
  %259 = getelementptr inbounds nuw %struct.Point, ptr %258, i32 0, i32 1
  %260 = load i32, ptr %259, align 4
  %261 = sext i32 %260 to i64
  %262 = getelementptr inbounds i8, ptr %254, i64 %261
  store i8 42, ptr %262, align 1
  br label %263

263:                                              ; preds = %244
  %264 = load i32, ptr %16, align 4
  %265 = add nsw i32 %264, 1
  store i32 %265, ptr %16, align 4
  br label %239, !llvm.loop !17

266:                                              ; preds = %239
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @dijkstra(i64 %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca %struct.Point, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca %struct.Point, align 4
  %12 = alloca %struct.Point, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  store i64 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %18 = load i32, ptr @N, align 4
  %19 = load i32, ptr @N, align 4
  %20 = mul nsw i32 %18, %19
  store i32 %20, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %21

21:                                               ; preds = %34, %3
  %22 = load i32, ptr %8, align 4
  %23 = load i32, ptr %7, align 4
  %24 = icmp slt i32 %22, %23
  br i1 %24, label %25, label %37

25:                                               ; preds = %21
  %26 = load ptr, ptr %5, align 8
  %27 = load i32, ptr %8, align 4
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds i32, ptr %26, i64 %28
  store i32 1000000000, ptr %29, align 4
  %30 = load ptr, ptr %6, align 8
  %31 = load i32, ptr %8, align 4
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds i32, ptr %30, i64 %32
  store i32 -1, ptr %33, align 4
  br label %34

34:                                               ; preds = %25
  %35 = load i32, ptr %8, align 4
  %36 = add nsw i32 %35, 1
  store i32 %36, ptr %8, align 4
  br label %21, !llvm.loop !18

37:                                               ; preds = %21
  %38 = getelementptr inbounds nuw %struct.Point, ptr %4, i32 0, i32 0
  %39 = load i32, ptr %38, align 4
  %40 = getelementptr inbounds nuw %struct.Point, ptr %4, i32 0, i32 1
  %41 = load i32, ptr %40, align 4
  %42 = call i32 @idOf(i32 noundef %39, i32 noundef %41)
  store i32 %42, ptr %9, align 4
  %43 = load ptr, ptr %5, align 8
  %44 = load i32, ptr %9, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds i32, ptr %43, i64 %45
  store i32 0, ptr %46, align 4
  %47 = load i32, ptr %7, align 4
  %48 = mul nsw i32 %47, 4
  %49 = add nsw i32 %48, 100
  %50 = call ptr @createHeap(i32 noundef %49)
  store ptr %50, ptr %10, align 8
  %51 = load ptr, ptr %10, align 8
  %52 = load i32, ptr %9, align 4
  call void @pushHeap(ptr noundef %51, i32 noundef %52, i32 noundef 0)
  br label %53

53:                                               ; preds = %175, %70, %37
  %54 = load ptr, ptr %10, align 8
  %55 = call i32 @emptyHeap(ptr noundef %54)
  %56 = icmp ne i32 %55, 0
  %57 = xor i1 %56, true
  br i1 %57, label %58, label %176

58:                                               ; preds = %53
  %59 = load ptr, ptr %10, align 8
  %60 = call i64 @popHeap(ptr noundef %59)
  store i64 %60, ptr %11, align 4
  %61 = getelementptr inbounds nuw %struct.Point, ptr %11, i32 0, i32 1
  %62 = load i32, ptr %61, align 4
  %63 = load ptr, ptr %5, align 8
  %64 = getelementptr inbounds nuw %struct.Point, ptr %11, i32 0, i32 0
  %65 = load i32, ptr %64, align 4
  %66 = sext i32 %65 to i64
  %67 = getelementptr inbounds i32, ptr %63, i64 %66
  %68 = load i32, ptr %67, align 4
  %69 = icmp ne i32 %62, %68
  br i1 %69, label %70, label %71

70:                                               ; preds = %58
  br label %53, !llvm.loop !19

71:                                               ; preds = %58
  %72 = getelementptr inbounds nuw %struct.Point, ptr %11, i32 0, i32 0
  %73 = load i32, ptr %72, align 4
  %74 = call i64 @pointOf(i32 noundef %73)
  store i64 %74, ptr %12, align 4
  store i32 0, ptr %13, align 4
  br label %75

75:                                               ; preds = %172, %71
  %76 = load i32, ptr %13, align 4
  %77 = icmp slt i32 %76, 4
  br i1 %77, label %78, label %175

78:                                               ; preds = %75
  %79 = getelementptr inbounds nuw %struct.Point, ptr %12, i32 0, i32 0
  %80 = load i32, ptr %79, align 4
  %81 = load i32, ptr %13, align 4
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds [4 x i32], ptr @dr, i64 0, i64 %82
  %84 = load i32, ptr %83, align 4
  %85 = add nsw i32 %80, %84
  store i32 %85, ptr %14, align 4
  %86 = getelementptr inbounds nuw %struct.Point, ptr %12, i32 0, i32 1
  %87 = load i32, ptr %86, align 4
  %88 = load i32, ptr %13, align 4
  %89 = sext i32 %88 to i64
  %90 = getelementptr inbounds [4 x i32], ptr @dc, i64 0, i64 %89
  %91 = load i32, ptr %90, align 4
  %92 = add nsw i32 %87, %91
  store i32 %92, ptr %15, align 4
  %93 = load i32, ptr %14, align 4
  %94 = load i32, ptr %15, align 4
  %95 = call i32 @inside(i32 noundef %93, i32 noundef %94)
  %96 = icmp ne i32 %95, 0
  br i1 %96, label %98, label %97

97:                                               ; preds = %78
  br label %172

98:                                               ; preds = %78
  %99 = load ptr, ptr @grid, align 8
  %100 = load i32, ptr %14, align 4
  %101 = sext i32 %100 to i64
  %102 = getelementptr inbounds ptr, ptr %99, i64 %101
  %103 = load ptr, ptr %102, align 8
  %104 = load i32, ptr %15, align 4
  %105 = sext i32 %104 to i64
  %106 = getelementptr inbounds i8, ptr %103, i64 %105
  %107 = load i8, ptr %106, align 1
  %108 = sext i8 %107 to i32
  %109 = icmp eq i32 %108, 35
  br i1 %109, label %110, label %111

110:                                              ; preds = %98
  br label %172

111:                                              ; preds = %98
  %112 = load i32, ptr %14, align 4
  %113 = load i32, ptr %15, align 4
  %114 = call i32 @idOf(i32 noundef %112, i32 noundef %113)
  store i32 %114, ptr %16, align 4
  %115 = load ptr, ptr %5, align 8
  %116 = getelementptr inbounds nuw %struct.Point, ptr %11, i32 0, i32 0
  %117 = load i32, ptr %116, align 4
  %118 = sext i32 %117 to i64
  %119 = getelementptr inbounds i32, ptr %115, i64 %118
  %120 = load i32, ptr %119, align 4
  %121 = load ptr, ptr @grid, align 8
  %122 = load i32, ptr %14, align 4
  %123 = sext i32 %122 to i64
  %124 = getelementptr inbounds ptr, ptr %121, i64 %123
  %125 = load ptr, ptr %124, align 8
  %126 = load i32, ptr %15, align 4
  %127 = sext i32 %126 to i64
  %128 = getelementptr inbounds i8, ptr %125, i64 %127
  %129 = load i8, ptr %128, align 1
  %130 = call i32 @terrainCost(i8 noundef signext %129)
  %131 = add nsw i32 %120, %130
  store i32 %131, ptr %17, align 4
  %132 = load i32, ptr %17, align 4
  %133 = load ptr, ptr %5, align 8
  %134 = load i32, ptr %16, align 4
  %135 = sext i32 %134 to i64
  %136 = getelementptr inbounds i32, ptr %133, i64 %135
  %137 = load i32, ptr %136, align 4
  %138 = icmp slt i32 %132, %137
  br i1 %138, label %156, label %139

139:                                              ; preds = %111
  %140 = load i32, ptr %17, align 4
  %141 = load ptr, ptr %5, align 8
  %142 = load i32, ptr %16, align 4
  %143 = sext i32 %142 to i64
  %144 = getelementptr inbounds i32, ptr %141, i64 %143
  %145 = load i32, ptr %144, align 4
  %146 = icmp eq i32 %140, %145
  br i1 %146, label %147, label %171

147:                                              ; preds = %139
  %148 = getelementptr inbounds nuw %struct.Point, ptr %11, i32 0, i32 0
  %149 = load i32, ptr %148, align 4
  %150 = load ptr, ptr %6, align 8
  %151 = load i32, ptr %16, align 4
  %152 = sext i32 %151 to i64
  %153 = getelementptr inbounds i32, ptr %150, i64 %152
  %154 = load i32, ptr %153, align 4
  %155 = icmp slt i32 %149, %154
  br i1 %155, label %156, label %171

156:                                              ; preds = %147, %111
  %157 = load i32, ptr %17, align 4
  %158 = load ptr, ptr %5, align 8
  %159 = load i32, ptr %16, align 4
  %160 = sext i32 %159 to i64
  %161 = getelementptr inbounds i32, ptr %158, i64 %160
  store i32 %157, ptr %161, align 4
  %162 = getelementptr inbounds nuw %struct.Point, ptr %11, i32 0, i32 0
  %163 = load i32, ptr %162, align 4
  %164 = load ptr, ptr %6, align 8
  %165 = load i32, ptr %16, align 4
  %166 = sext i32 %165 to i64
  %167 = getelementptr inbounds i32, ptr %164, i64 %166
  store i32 %163, ptr %167, align 4
  %168 = load ptr, ptr %10, align 8
  %169 = load i32, ptr %16, align 4
  %170 = load i32, ptr %17, align 4
  call void @pushHeap(ptr noundef %168, i32 noundef %169, i32 noundef %170)
  br label %171

171:                                              ; preds = %156, %147, %139
  br label %172

172:                                              ; preds = %171, %110, %97
  %173 = load i32, ptr %13, align 4
  %174 = add nsw i32 %173, 1
  store i32 %174, ptr %13, align 4
  br label %75, !llvm.loop !20

175:                                              ; preds = %75
  br label %53, !llvm.loop !19

176:                                              ; preds = %53
  %177 = load ptr, ptr %10, align 8
  call void @freeHeap(ptr noundef %177)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @appendPathSegment(i64 %0, i64 %1, ptr noundef %2, ptr noundef %3, ptr noundef %4) #0 {
  %6 = alloca %struct.Point, align 4
  %7 = alloca %struct.Point, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca %struct.Point, align 4
  store i64 %0, ptr %6, align 4
  store i64 %1, ptr %7, align 4
  store ptr %2, ptr %8, align 8
  store ptr %3, ptr %9, align 8
  store ptr %4, ptr %10, align 8
  %17 = load i32, ptr @N, align 4
  %18 = load i32, ptr @N, align 4
  %19 = mul nsw i32 %17, %18
  %20 = add nsw i32 %19, 5
  %21 = sext i32 %20 to i64
  %22 = mul i64 4, %21
  %23 = call noalias ptr @malloc(i64 noundef %22) #6
  store ptr %23, ptr %11, align 8
  store i32 0, ptr %12, align 4
  %24 = getelementptr inbounds nuw %struct.Point, ptr %6, i32 0, i32 0
  %25 = load i32, ptr %24, align 4
  %26 = getelementptr inbounds nuw %struct.Point, ptr %6, i32 0, i32 1
  %27 = load i32, ptr %26, align 4
  %28 = call i32 @idOf(i32 noundef %25, i32 noundef %27)
  store i32 %28, ptr %13, align 4
  %29 = getelementptr inbounds nuw %struct.Point, ptr %7, i32 0, i32 0
  %30 = load i32, ptr %29, align 4
  %31 = getelementptr inbounds nuw %struct.Point, ptr %7, i32 0, i32 1
  %32 = load i32, ptr %31, align 4
  %33 = call i32 @idOf(i32 noundef %30, i32 noundef %32)
  store i32 %33, ptr %14, align 4
  br label %34

34:                                               ; preds = %48, %5
  %35 = load i32, ptr %14, align 4
  %36 = icmp ne i32 %35, -1
  br i1 %36, label %37, label %54

37:                                               ; preds = %34
  %38 = load i32, ptr %14, align 4
  %39 = load ptr, ptr %11, align 8
  %40 = load i32, ptr %12, align 4
  %41 = add nsw i32 %40, 1
  store i32 %41, ptr %12, align 4
  %42 = sext i32 %40 to i64
  %43 = getelementptr inbounds i32, ptr %39, i64 %42
  store i32 %38, ptr %43, align 4
  %44 = load i32, ptr %14, align 4
  %45 = load i32, ptr %13, align 4
  %46 = icmp eq i32 %44, %45
  br i1 %46, label %47, label %48

47:                                               ; preds = %37
  br label %54

48:                                               ; preds = %37
  %49 = load ptr, ptr %8, align 8
  %50 = load i32, ptr %14, align 4
  %51 = sext i32 %50 to i64
  %52 = getelementptr inbounds i32, ptr %49, i64 %51
  %53 = load i32, ptr %52, align 4
  store i32 %53, ptr %14, align 4
  br label %34, !llvm.loop !21

54:                                               ; preds = %47, %34
  %55 = load i32, ptr %12, align 4
  %56 = icmp eq i32 %55, 0
  br i1 %56, label %66, label %57

57:                                               ; preds = %54
  %58 = load ptr, ptr %11, align 8
  %59 = load i32, ptr %12, align 4
  %60 = sub nsw i32 %59, 1
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds i32, ptr %58, i64 %61
  %63 = load i32, ptr %62, align 4
  %64 = load i32, ptr %13, align 4
  %65 = icmp ne i32 %63, %64
  br i1 %65, label %66, label %68

66:                                               ; preds = %57, %54
  %67 = load ptr, ptr %11, align 8
  call void @free(ptr noundef %67) #8
  br label %110

68:                                               ; preds = %57
  %69 = load i32, ptr %12, align 4
  %70 = sub nsw i32 %69, 1
  store i32 %70, ptr %15, align 4
  br label %71

71:                                               ; preds = %105, %68
  %72 = load i32, ptr %15, align 4
  %73 = icmp sge i32 %72, 0
  br i1 %73, label %74, label %108

74:                                               ; preds = %71
  %75 = load ptr, ptr %11, align 8
  %76 = load i32, ptr %15, align 4
  %77 = sext i32 %76 to i64
  %78 = getelementptr inbounds i32, ptr %75, i64 %77
  %79 = load i32, ptr %78, align 4
  %80 = call i64 @pointOf(i32 noundef %79)
  store i64 %80, ptr %16, align 4
  %81 = load ptr, ptr %10, align 8
  %82 = load i32, ptr %81, align 4
  %83 = icmp sgt i32 %82, 0
  br i1 %83, label %84, label %96

84:                                               ; preds = %74
  %85 = load ptr, ptr %9, align 8
  %86 = load ptr, ptr %10, align 8
  %87 = load i32, ptr %86, align 4
  %88 = sub nsw i32 %87, 1
  %89 = sext i32 %88 to i64
  %90 = getelementptr inbounds %struct.Point, ptr %85, i64 %89
  %91 = load i64, ptr %90, align 4
  %92 = load i64, ptr %16, align 4
  %93 = call i32 @samePoint(i64 %91, i64 %92)
  %94 = icmp ne i32 %93, 0
  br i1 %94, label %95, label %96

95:                                               ; preds = %84
  br label %105

96:                                               ; preds = %84, %74
  %97 = load ptr, ptr %9, align 8
  %98 = load ptr, ptr %10, align 8
  %99 = load i32, ptr %98, align 4
  %100 = sext i32 %99 to i64
  %101 = getelementptr inbounds %struct.Point, ptr %97, i64 %100
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %101, ptr align 4 %16, i64 8, i1 false)
  %102 = load ptr, ptr %10, align 8
  %103 = load i32, ptr %102, align 4
  %104 = add nsw i32 %103, 1
  store i32 %104, ptr %102, align 4
  br label %105

105:                                              ; preds = %96, %95
  %106 = load i32, ptr %15, align 4
  %107 = add nsw i32 %106, -1
  store i32 %107, ptr %15, align 4
  br label %71, !llvm.loop !22

108:                                              ; preds = %71
  %109 = load ptr, ptr %11, align 8
  call void @free(ptr noundef %109) #8
  br label %110

110:                                              ; preds = %108, %66
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printDungeon(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str)
  store i32 0, ptr %5, align 4
  br label %8

8:                                                ; preds = %19, %2
  %9 = load i32, ptr %5, align 4
  %10 = load i32, ptr @N, align 4
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %12, label %22

12:                                               ; preds = %8
  %13 = load ptr, ptr @grid, align 8
  %14 = load i32, ptr %5, align 4
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds ptr, ptr %13, i64 %15
  %17 = load ptr, ptr %16, align 8
  %18 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, ptr noundef %17)
  br label %19

19:                                               ; preds = %12
  %20 = load i32, ptr %5, align 4
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %5, align 4
  br label %8, !llvm.loop !23

22:                                               ; preds = %8
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.2)
  store i32 0, ptr %6, align 4
  br label %24

24:                                               ; preds = %44, %22
  %25 = load i32, ptr %6, align 4
  %26 = load i32, ptr %4, align 4
  %27 = icmp slt i32 %25, %26
  br i1 %27, label %28, label %47

28:                                               ; preds = %24
  %29 = load i32, ptr %6, align 4
  %30 = add nsw i32 %29, 1
  %31 = load ptr, ptr %3, align 8
  %32 = load i32, ptr %6, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds %struct.Point, ptr %31, i64 %33
  %35 = getelementptr inbounds nuw %struct.Point, ptr %34, i32 0, i32 0
  %36 = load i32, ptr %35, align 4
  %37 = load ptr, ptr %3, align 8
  %38 = load i32, ptr %6, align 4
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds %struct.Point, ptr %37, i64 %39
  %41 = getelementptr inbounds nuw %struct.Point, ptr %40, i32 0, i32 1
  %42 = load i32, ptr %41, align 4
  %43 = call i32 (ptr, ...) @printf(ptr noundef @.str.3, i32 noundef %30, i32 noundef %36, i32 noundef %42)
  br label %44

44:                                               ; preds = %28
  %45 = load i32, ptr %6, align 4
  %46 = add nsw i32 %45, 1
  store i32 %46, ptr %6, align 4
  br label %24, !llvm.loop !24

47:                                               ; preds = %24
  ret void
}

declare i32 @printf(ptr noundef, ...) #5

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printRoute(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str.4)
  store i32 0, ptr %5, align 4
  br label %7

7:                                                ; preds = %44, %2
  %8 = load i32, ptr %5, align 4
  %9 = load i32, ptr %4, align 4
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %11, label %47

11:                                               ; preds = %7
  %12 = load ptr, ptr %3, align 8
  %13 = load i32, ptr %5, align 4
  %14 = sext i32 %13 to i64
  %15 = getelementptr inbounds %struct.Point, ptr %12, i64 %14
  %16 = getelementptr inbounds nuw %struct.Point, ptr %15, i32 0, i32 0
  %17 = load i32, ptr %16, align 4
  %18 = load ptr, ptr %3, align 8
  %19 = load i32, ptr %5, align 4
  %20 = sext i32 %19 to i64
  %21 = getelementptr inbounds %struct.Point, ptr %18, i64 %20
  %22 = getelementptr inbounds nuw %struct.Point, ptr %21, i32 0, i32 1
  %23 = load i32, ptr %22, align 4
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %17, i32 noundef %23)
  %25 = load i32, ptr %5, align 4
  %26 = add nsw i32 %25, 1
  %27 = load i32, ptr %4, align 4
  %28 = icmp slt i32 %26, %27
  br i1 %28, label %29, label %31

29:                                               ; preds = %11
  %30 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  br label %31

31:                                               ; preds = %29, %11
  %32 = load i32, ptr %5, align 4
  %33 = add nsw i32 %32, 1
  %34 = srem i32 %33, 8
  %35 = icmp eq i32 %34, 0
  br i1 %35, label %36, label %43

36:                                               ; preds = %31
  %37 = load i32, ptr %5, align 4
  %38 = add nsw i32 %37, 1
  %39 = load i32, ptr %4, align 4
  %40 = icmp slt i32 %38, %39
  br i1 %40, label %41, label %43

41:                                               ; preds = %36
  %42 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  br label %43

43:                                               ; preds = %41, %36, %31
  br label %44

44:                                               ; preds = %43
  %45 = load i32, ptr %5, align 4
  %46 = add nsw i32 %45, 1
  store i32 %46, ptr %5, align 4
  br label %7, !llvm.loop !25

47:                                               ; preds = %7
  %48 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca %struct.Point, align 4
  %3 = alloca %struct.Point, align 4
  %4 = alloca [8 x %struct.Point], align 16
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca i32, align 4
  %13 = alloca ptr, align 8
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca ptr, align 8
  %18 = alloca ptr, align 8
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  %21 = alloca i32, align 4
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
  %36 = alloca ptr, align 8
  %37 = alloca i32, align 4
  %38 = alloca i32, align 4
  %39 = alloca i32, align 4
  %40 = alloca i32, align 4
  %41 = alloca i32, align 4
  %42 = alloca i32, align 4
  %43 = alloca ptr, align 8
  %44 = alloca i32, align 4
  %45 = alloca i32, align 4
  %46 = alloca i32, align 4
  %47 = alloca i32, align 4
  %48 = alloca i32, align 4
  %49 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  %50 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str.8, ptr noundef @N)
  %51 = icmp ne i32 %50, 1
  br i1 %51, label %52, label %54

52:                                               ; preds = %0
  %53 = call i32 (ptr, ...) @printf(ptr noundef @.str.9)
  store i32 0, ptr %1, align 4
  br label %626

54:                                               ; preds = %0
  %55 = load i32, ptr @N, align 4
  %56 = icmp slt i32 %55, 4
  br i1 %56, label %60, label %57

57:                                               ; preds = %54
  %58 = load i32, ptr @N, align 4
  %59 = icmp sgt i32 %58, 30
  br i1 %59, label %60, label %62

60:                                               ; preds = %57, %54
  %61 = call i32 (ptr, ...) @printf(ptr noundef @.str.10)
  store i32 0, ptr %1, align 4
  br label %626

62:                                               ; preds = %57
  call void @allocateGrid()
  %63 = getelementptr inbounds [8 x %struct.Point], ptr %4, i64 0, i64 0
  call void @generateDungeon(ptr noundef %2, ptr noundef %3, ptr noundef %63, ptr noundef %5)
  %64 = load i32, ptr %5, align 4
  %65 = add nsw i32 %64, 2
  store i32 %65, ptr %6, align 4
  %66 = load i32, ptr %6, align 4
  %67 = sext i32 %66 to i64
  %68 = mul i64 8, %67
  %69 = call noalias ptr @malloc(i64 noundef %68) #6
  store ptr %69, ptr %7, align 8
  %70 = load ptr, ptr %7, align 8
  %71 = getelementptr inbounds %struct.Point, ptr %70, i64 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %71, ptr align 4 %2, i64 8, i1 false)
  store i32 0, ptr %8, align 4
  br label %72

72:                                               ; preds = %85, %62
  %73 = load i32, ptr %8, align 4
  %74 = load i32, ptr %5, align 4
  %75 = icmp slt i32 %73, %74
  br i1 %75, label %76, label %88

76:                                               ; preds = %72
  %77 = load ptr, ptr %7, align 8
  %78 = load i32, ptr %8, align 4
  %79 = add nsw i32 %78, 1
  %80 = sext i32 %79 to i64
  %81 = getelementptr inbounds %struct.Point, ptr %77, i64 %80
  %82 = load i32, ptr %8, align 4
  %83 = sext i32 %82 to i64
  %84 = getelementptr inbounds [8 x %struct.Point], ptr %4, i64 0, i64 %83
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %81, ptr align 8 %84, i64 8, i1 false)
  br label %85

85:                                               ; preds = %76
  %86 = load i32, ptr %8, align 4
  %87 = add nsw i32 %86, 1
  store i32 %87, ptr %8, align 4
  br label %72, !llvm.loop !26

88:                                               ; preds = %72
  %89 = load ptr, ptr %7, align 8
  %90 = load i32, ptr %5, align 4
  %91 = add nsw i32 %90, 1
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds %struct.Point, ptr %89, i64 %92
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %93, ptr align 4 %3, i64 8, i1 false)
  %94 = load i32, ptr @N, align 4
  %95 = load i32, ptr @N, align 4
  %96 = mul nsw i32 %94, %95
  store i32 %96, ptr %9, align 4
  %97 = load i32, ptr %6, align 4
  %98 = sext i32 %97 to i64
  %99 = mul i64 8, %98
  %100 = call noalias ptr @malloc(i64 noundef %99) #6
  store ptr %100, ptr %10, align 8
  %101 = load i32, ptr %6, align 4
  %102 = sext i32 %101 to i64
  %103 = mul i64 8, %102
  %104 = call noalias ptr @malloc(i64 noundef %103) #6
  store ptr %104, ptr %11, align 8
  store i32 0, ptr %12, align 4
  br label %105

105:                                              ; preds = %141, %88
  %106 = load i32, ptr %12, align 4
  %107 = load i32, ptr %6, align 4
  %108 = icmp slt i32 %106, %107
  br i1 %108, label %109, label %144

109:                                              ; preds = %105
  %110 = load i32, ptr %9, align 4
  %111 = sext i32 %110 to i64
  %112 = mul i64 4, %111
  %113 = call noalias ptr @malloc(i64 noundef %112) #6
  %114 = load ptr, ptr %10, align 8
  %115 = load i32, ptr %12, align 4
  %116 = sext i32 %115 to i64
  %117 = getelementptr inbounds ptr, ptr %114, i64 %116
  store ptr %113, ptr %117, align 8
  %118 = load i32, ptr %9, align 4
  %119 = sext i32 %118 to i64
  %120 = mul i64 4, %119
  %121 = call noalias ptr @malloc(i64 noundef %120) #6
  %122 = load ptr, ptr %11, align 8
  %123 = load i32, ptr %12, align 4
  %124 = sext i32 %123 to i64
  %125 = getelementptr inbounds ptr, ptr %122, i64 %124
  store ptr %121, ptr %125, align 8
  %126 = load ptr, ptr %7, align 8
  %127 = load i32, ptr %12, align 4
  %128 = sext i32 %127 to i64
  %129 = getelementptr inbounds %struct.Point, ptr %126, i64 %128
  %130 = load ptr, ptr %10, align 8
  %131 = load i32, ptr %12, align 4
  %132 = sext i32 %131 to i64
  %133 = getelementptr inbounds ptr, ptr %130, i64 %132
  %134 = load ptr, ptr %133, align 8
  %135 = load ptr, ptr %11, align 8
  %136 = load i32, ptr %12, align 4
  %137 = sext i32 %136 to i64
  %138 = getelementptr inbounds ptr, ptr %135, i64 %137
  %139 = load ptr, ptr %138, align 8
  %140 = load i64, ptr %129, align 4
  call void @dijkstra(i64 %140, ptr noundef %134, ptr noundef %139)
  br label %141

141:                                              ; preds = %109
  %142 = load i32, ptr %12, align 4
  %143 = add nsw i32 %142, 1
  store i32 %143, ptr %12, align 4
  br label %105, !llvm.loop !27

144:                                              ; preds = %105
  %145 = load i32, ptr %6, align 4
  %146 = sext i32 %145 to i64
  %147 = mul i64 8, %146
  %148 = call noalias ptr @malloc(i64 noundef %147) #6
  store ptr %148, ptr %13, align 8
  store i32 0, ptr %14, align 4
  br label %149

149:                                              ; preds = %200, %144
  %150 = load i32, ptr %14, align 4
  %151 = load i32, ptr %6, align 4
  %152 = icmp slt i32 %150, %151
  br i1 %152, label %153, label %203

153:                                              ; preds = %149
  %154 = load i32, ptr %6, align 4
  %155 = sext i32 %154 to i64
  %156 = mul i64 4, %155
  %157 = call noalias ptr @malloc(i64 noundef %156) #6
  %158 = load ptr, ptr %13, align 8
  %159 = load i32, ptr %14, align 4
  %160 = sext i32 %159 to i64
  %161 = getelementptr inbounds ptr, ptr %158, i64 %160
  store ptr %157, ptr %161, align 8
  store i32 0, ptr %15, align 4
  br label %162

162:                                              ; preds = %196, %153
  %163 = load i32, ptr %15, align 4
  %164 = load i32, ptr %6, align 4
  %165 = icmp slt i32 %163, %164
  br i1 %165, label %166, label %199

166:                                              ; preds = %162
  %167 = load ptr, ptr %10, align 8
  %168 = load i32, ptr %14, align 4
  %169 = sext i32 %168 to i64
  %170 = getelementptr inbounds ptr, ptr %167, i64 %169
  %171 = load ptr, ptr %170, align 8
  %172 = load ptr, ptr %7, align 8
  %173 = load i32, ptr %15, align 4
  %174 = sext i32 %173 to i64
  %175 = getelementptr inbounds %struct.Point, ptr %172, i64 %174
  %176 = getelementptr inbounds nuw %struct.Point, ptr %175, i32 0, i32 0
  %177 = load i32, ptr %176, align 4
  %178 = load ptr, ptr %7, align 8
  %179 = load i32, ptr %15, align 4
  %180 = sext i32 %179 to i64
  %181 = getelementptr inbounds %struct.Point, ptr %178, i64 %180
  %182 = getelementptr inbounds nuw %struct.Point, ptr %181, i32 0, i32 1
  %183 = load i32, ptr %182, align 4
  %184 = call i32 @idOf(i32 noundef %177, i32 noundef %183)
  %185 = sext i32 %184 to i64
  %186 = getelementptr inbounds i32, ptr %171, i64 %185
  %187 = load i32, ptr %186, align 4
  %188 = load ptr, ptr %13, align 8
  %189 = load i32, ptr %14, align 4
  %190 = sext i32 %189 to i64
  %191 = getelementptr inbounds ptr, ptr %188, i64 %190
  %192 = load ptr, ptr %191, align 8
  %193 = load i32, ptr %15, align 4
  %194 = sext i32 %193 to i64
  %195 = getelementptr inbounds i32, ptr %192, i64 %194
  store i32 %187, ptr %195, align 4
  br label %196

196:                                              ; preds = %166
  %197 = load i32, ptr %15, align 4
  %198 = add nsw i32 %197, 1
  store i32 %198, ptr %15, align 4
  br label %162, !llvm.loop !28

199:                                              ; preds = %162
  br label %200

200:                                              ; preds = %199
  %201 = load i32, ptr %14, align 4
  %202 = add nsw i32 %201, 1
  store i32 %202, ptr %14, align 4
  br label %149, !llvm.loop !29

203:                                              ; preds = %149
  %204 = load i32, ptr %5, align 4
  %205 = shl i32 1, %204
  store i32 %205, ptr %16, align 4
  %206 = load i32, ptr %16, align 4
  %207 = sext i32 %206 to i64
  %208 = mul i64 4, %207
  %209 = load i32, ptr %5, align 4
  %210 = sext i32 %209 to i64
  %211 = mul i64 %208, %210
  %212 = call noalias ptr @malloc(i64 noundef %211) #6
  store ptr %212, ptr %17, align 8
  %213 = load i32, ptr %16, align 4
  %214 = sext i32 %213 to i64
  %215 = mul i64 4, %214
  %216 = load i32, ptr %5, align 4
  %217 = sext i32 %216 to i64
  %218 = mul i64 %215, %217
  %219 = call noalias ptr @malloc(i64 noundef %218) #6
  store ptr %219, ptr %18, align 8
  store i32 0, ptr %19, align 4
  br label %220

220:                                              ; preds = %250, %203
  %221 = load i32, ptr %19, align 4
  %222 = load i32, ptr %16, align 4
  %223 = icmp slt i32 %221, %222
  br i1 %223, label %224, label %253

224:                                              ; preds = %220
  store i32 0, ptr %20, align 4
  br label %225

225:                                              ; preds = %246, %224
  %226 = load i32, ptr %20, align 4
  %227 = load i32, ptr %5, align 4
  %228 = icmp slt i32 %226, %227
  br i1 %228, label %229, label %249

229:                                              ; preds = %225
  %230 = load ptr, ptr %17, align 8
  %231 = load i32, ptr %19, align 4
  %232 = load i32, ptr %5, align 4
  %233 = mul nsw i32 %231, %232
  %234 = load i32, ptr %20, align 4
  %235 = add nsw i32 %233, %234
  %236 = sext i32 %235 to i64
  %237 = getelementptr inbounds i32, ptr %230, i64 %236
  store i32 1000000000, ptr %237, align 4
  %238 = load ptr, ptr %18, align 8
  %239 = load i32, ptr %19, align 4
  %240 = load i32, ptr %5, align 4
  %241 = mul nsw i32 %239, %240
  %242 = load i32, ptr %20, align 4
  %243 = add nsw i32 %241, %242
  %244 = sext i32 %243 to i64
  %245 = getelementptr inbounds i32, ptr %238, i64 %244
  store i32 -1, ptr %245, align 4
  br label %246

246:                                              ; preds = %229
  %247 = load i32, ptr %20, align 4
  %248 = add nsw i32 %247, 1
  store i32 %248, ptr %20, align 4
  br label %225, !llvm.loop !30

249:                                              ; preds = %225
  br label %250

250:                                              ; preds = %249
  %251 = load i32, ptr %19, align 4
  %252 = add nsw i32 %251, 1
  store i32 %252, ptr %19, align 4
  br label %220, !llvm.loop !31

253:                                              ; preds = %220
  store i32 0, ptr %21, align 4
  br label %254

254:                                              ; preds = %281, %253
  %255 = load i32, ptr %21, align 4
  %256 = load i32, ptr %5, align 4
  %257 = icmp slt i32 %255, %256
  br i1 %257, label %258, label %284

258:                                              ; preds = %254
  %259 = load ptr, ptr %13, align 8
  %260 = getelementptr inbounds ptr, ptr %259, i64 0
  %261 = load ptr, ptr %260, align 8
  %262 = load i32, ptr %21, align 4
  %263 = add nsw i32 %262, 1
  %264 = sext i32 %263 to i64
  %265 = getelementptr inbounds i32, ptr %261, i64 %264
  %266 = load i32, ptr %265, align 4
  store i32 %266, ptr %22, align 4
  %267 = load i32, ptr %22, align 4
  %268 = icmp slt i32 %267, 1000000000
  br i1 %268, label %269, label %280

269:                                              ; preds = %258
  %270 = load i32, ptr %22, align 4
  %271 = load ptr, ptr %17, align 8
  %272 = load i32, ptr %21, align 4
  %273 = shl i32 1, %272
  %274 = load i32, ptr %5, align 4
  %275 = mul nsw i32 %273, %274
  %276 = load i32, ptr %21, align 4
  %277 = add nsw i32 %275, %276
  %278 = sext i32 %277 to i64
  %279 = getelementptr inbounds i32, ptr %271, i64 %278
  store i32 %270, ptr %279, align 4
  br label %280

280:                                              ; preds = %269, %258
  br label %281

281:                                              ; preds = %280
  %282 = load i32, ptr %21, align 4
  %283 = add nsw i32 %282, 1
  store i32 %283, ptr %21, align 4
  br label %254, !llvm.loop !32

284:                                              ; preds = %254
  store i32 0, ptr %23, align 4
  br label %285

285:                                              ; preds = %381, %284
  %286 = load i32, ptr %23, align 4
  %287 = load i32, ptr %16, align 4
  %288 = icmp slt i32 %286, %287
  br i1 %288, label %289, label %384

289:                                              ; preds = %285
  store i32 0, ptr %24, align 4
  br label %290

290:                                              ; preds = %377, %289
  %291 = load i32, ptr %24, align 4
  %292 = load i32, ptr %5, align 4
  %293 = icmp slt i32 %291, %292
  br i1 %293, label %294, label %380

294:                                              ; preds = %290
  %295 = load ptr, ptr %17, align 8
  %296 = load i32, ptr %23, align 4
  %297 = load i32, ptr %5, align 4
  %298 = mul nsw i32 %296, %297
  %299 = load i32, ptr %24, align 4
  %300 = add nsw i32 %298, %299
  %301 = sext i32 %300 to i64
  %302 = getelementptr inbounds i32, ptr %295, i64 %301
  %303 = load i32, ptr %302, align 4
  store i32 %303, ptr %25, align 4
  %304 = load i32, ptr %25, align 4
  %305 = icmp sge i32 %304, 1000000000
  br i1 %305, label %306, label %307

306:                                              ; preds = %294
  br label %377

307:                                              ; preds = %294
  store i32 0, ptr %26, align 4
  br label %308

308:                                              ; preds = %373, %307
  %309 = load i32, ptr %26, align 4
  %310 = load i32, ptr %5, align 4
  %311 = icmp slt i32 %309, %310
  br i1 %311, label %312, label %376

312:                                              ; preds = %308
  %313 = load i32, ptr %23, align 4
  %314 = load i32, ptr %26, align 4
  %315 = shl i32 1, %314
  %316 = and i32 %313, %315
  %317 = icmp ne i32 %316, 0
  br i1 %317, label %318, label %319

318:                                              ; preds = %312
  br label %373

319:                                              ; preds = %312
  %320 = load ptr, ptr %13, align 8
  %321 = load i32, ptr %24, align 4
  %322 = add nsw i32 %321, 1
  %323 = sext i32 %322 to i64
  %324 = getelementptr inbounds ptr, ptr %320, i64 %323
  %325 = load ptr, ptr %324, align 8
  %326 = load i32, ptr %26, align 4
  %327 = add nsw i32 %326, 1
  %328 = sext i32 %327 to i64
  %329 = getelementptr inbounds i32, ptr %325, i64 %328
  %330 = load i32, ptr %329, align 4
  store i32 %330, ptr %27, align 4
  %331 = load i32, ptr %27, align 4
  %332 = icmp sge i32 %331, 1000000000
  br i1 %332, label %333, label %334

333:                                              ; preds = %319
  br label %373

334:                                              ; preds = %319
  %335 = load i32, ptr %23, align 4
  %336 = load i32, ptr %26, align 4
  %337 = shl i32 1, %336
  %338 = or i32 %335, %337
  store i32 %338, ptr %28, align 4
  %339 = load i32, ptr %25, align 4
  %340 = load i32, ptr %27, align 4
  %341 = add nsw i32 %339, %340
  store i32 %341, ptr %29, align 4
  %342 = load i32, ptr %29, align 4
  %343 = load ptr, ptr %17, align 8
  %344 = load i32, ptr %28, align 4
  %345 = load i32, ptr %5, align 4
  %346 = mul nsw i32 %344, %345
  %347 = load i32, ptr %26, align 4
  %348 = add nsw i32 %346, %347
  %349 = sext i32 %348 to i64
  %350 = getelementptr inbounds i32, ptr %343, i64 %349
  %351 = load i32, ptr %350, align 4
  %352 = icmp slt i32 %342, %351
  br i1 %352, label %353, label %372

353:                                              ; preds = %334
  %354 = load i32, ptr %29, align 4
  %355 = load ptr, ptr %17, align 8
  %356 = load i32, ptr %28, align 4
  %357 = load i32, ptr %5, align 4
  %358 = mul nsw i32 %356, %357
  %359 = load i32, ptr %26, align 4
  %360 = add nsw i32 %358, %359
  %361 = sext i32 %360 to i64
  %362 = getelementptr inbounds i32, ptr %355, i64 %361
  store i32 %354, ptr %362, align 4
  %363 = load i32, ptr %24, align 4
  %364 = load ptr, ptr %18, align 8
  %365 = load i32, ptr %28, align 4
  %366 = load i32, ptr %5, align 4
  %367 = mul nsw i32 %365, %366
  %368 = load i32, ptr %26, align 4
  %369 = add nsw i32 %367, %368
  %370 = sext i32 %369 to i64
  %371 = getelementptr inbounds i32, ptr %364, i64 %370
  store i32 %363, ptr %371, align 4
  br label %372

372:                                              ; preds = %353, %334
  br label %373

373:                                              ; preds = %372, %333, %318
  %374 = load i32, ptr %26, align 4
  %375 = add nsw i32 %374, 1
  store i32 %375, ptr %26, align 4
  br label %308, !llvm.loop !33

376:                                              ; preds = %308
  br label %377

377:                                              ; preds = %376, %306
  %378 = load i32, ptr %24, align 4
  %379 = add nsw i32 %378, 1
  store i32 %379, ptr %24, align 4
  br label %290, !llvm.loop !34

380:                                              ; preds = %290
  br label %381

381:                                              ; preds = %380
  %382 = load i32, ptr %23, align 4
  %383 = add nsw i32 %382, 1
  store i32 %383, ptr %23, align 4
  br label %285, !llvm.loop !35

384:                                              ; preds = %285
  store i32 1000000000, ptr %30, align 4
  store i32 -1, ptr %31, align 4
  %385 = load i32, ptr %16, align 4
  %386 = sub nsw i32 %385, 1
  store i32 %386, ptr %32, align 4
  store i32 0, ptr %33, align 4
  br label %387

387:                                              ; preds = %430, %384
  %388 = load i32, ptr %33, align 4
  %389 = load i32, ptr %5, align 4
  %390 = icmp slt i32 %388, %389
  br i1 %390, label %391, label %433

391:                                              ; preds = %387
  %392 = load ptr, ptr %17, align 8
  %393 = load i32, ptr %32, align 4
  %394 = load i32, ptr %5, align 4
  %395 = mul nsw i32 %393, %394
  %396 = load i32, ptr %33, align 4
  %397 = add nsw i32 %395, %396
  %398 = sext i32 %397 to i64
  %399 = getelementptr inbounds i32, ptr %392, i64 %398
  %400 = load i32, ptr %399, align 4
  store i32 %400, ptr %34, align 4
  %401 = load ptr, ptr %13, align 8
  %402 = load i32, ptr %33, align 4
  %403 = add nsw i32 %402, 1
  %404 = sext i32 %403 to i64
  %405 = getelementptr inbounds ptr, ptr %401, i64 %404
  %406 = load ptr, ptr %405, align 8
  %407 = load i32, ptr %5, align 4
  %408 = add nsw i32 %407, 1
  %409 = sext i32 %408 to i64
  %410 = getelementptr inbounds i32, ptr %406, i64 %409
  %411 = load i32, ptr %410, align 4
  store i32 %411, ptr %35, align 4
  %412 = load i32, ptr %34, align 4
  %413 = icmp sge i32 %412, 1000000000
  br i1 %413, label %417, label %414

414:                                              ; preds = %391
  %415 = load i32, ptr %35, align 4
  %416 = icmp sge i32 %415, 1000000000
  br i1 %416, label %417, label %418

417:                                              ; preds = %414, %391
  br label %430

418:                                              ; preds = %414
  %419 = load i32, ptr %34, align 4
  %420 = load i32, ptr %35, align 4
  %421 = add nsw i32 %419, %420
  %422 = load i32, ptr %30, align 4
  %423 = icmp slt i32 %421, %422
  br i1 %423, label %424, label %429

424:                                              ; preds = %418
  %425 = load i32, ptr %34, align 4
  %426 = load i32, ptr %35, align 4
  %427 = add nsw i32 %425, %426
  store i32 %427, ptr %30, align 4
  %428 = load i32, ptr %33, align 4
  store i32 %428, ptr %31, align 4
  br label %429

429:                                              ; preds = %424, %418
  br label %430

430:                                              ; preds = %429, %417
  %431 = load i32, ptr %33, align 4
  %432 = add nsw i32 %431, 1
  store i32 %432, ptr %33, align 4
  br label %387, !llvm.loop !36

433:                                              ; preds = %387
  %434 = call i32 (ptr, ...) @printf(ptr noundef @.str.11)
  %435 = load i32, ptr @N, align 4
  %436 = call i32 (ptr, ...) @printf(ptr noundef @.str.12, i32 noundef %435)
  %437 = call i32 (ptr, ...) @printf(ptr noundef @.str.13)
  %438 = getelementptr inbounds [8 x %struct.Point], ptr %4, i64 0, i64 0
  %439 = load i32, ptr %5, align 4
  call void @printDungeon(ptr noundef %438, i32 noundef %439)
  %440 = load i32, ptr %31, align 4
  %441 = icmp eq i32 %440, -1
  br i1 %441, label %442, label %444

442:                                              ; preds = %433
  %443 = call i32 (ptr, ...) @printf(ptr noundef @.str.14)
  br label %595

444:                                              ; preds = %433
  %445 = load i32, ptr %5, align 4
  %446 = sext i32 %445 to i64
  %447 = mul i64 4, %446
  %448 = call noalias ptr @malloc(i64 noundef %447) #6
  store ptr %448, ptr %36, align 8
  store i32 0, ptr %37, align 4
  %449 = load i32, ptr %32, align 4
  store i32 %449, ptr %38, align 4
  %450 = load i32, ptr %31, align 4
  store i32 %450, ptr %39, align 4
  br label %451

451:                                              ; preds = %454, %444
  %452 = load i32, ptr %39, align 4
  %453 = icmp ne i32 %452, -1
  br i1 %453, label %454, label %475

454:                                              ; preds = %451
  %455 = load i32, ptr %39, align 4
  %456 = load ptr, ptr %36, align 8
  %457 = load i32, ptr %37, align 4
  %458 = add nsw i32 %457, 1
  store i32 %458, ptr %37, align 4
  %459 = sext i32 %457 to i64
  %460 = getelementptr inbounds i32, ptr %456, i64 %459
  store i32 %455, ptr %460, align 4
  %461 = load ptr, ptr %18, align 8
  %462 = load i32, ptr %38, align 4
  %463 = load i32, ptr %5, align 4
  %464 = mul nsw i32 %462, %463
  %465 = load i32, ptr %39, align 4
  %466 = add nsw i32 %464, %465
  %467 = sext i32 %466 to i64
  %468 = getelementptr inbounds i32, ptr %461, i64 %467
  %469 = load i32, ptr %468, align 4
  store i32 %469, ptr %40, align 4
  %470 = load i32, ptr %39, align 4
  %471 = shl i32 1, %470
  %472 = load i32, ptr %38, align 4
  %473 = xor i32 %472, %471
  store i32 %473, ptr %38, align 4
  %474 = load i32, ptr %40, align 4
  store i32 %474, ptr %39, align 4
  br label %451, !llvm.loop !37

475:                                              ; preds = %451
  store i32 0, ptr %41, align 4
  br label %476

476:                                              ; preds = %507, %475
  %477 = load i32, ptr %41, align 4
  %478 = load i32, ptr %37, align 4
  %479 = sdiv i32 %478, 2
  %480 = icmp slt i32 %477, %479
  br i1 %480, label %481, label %510

481:                                              ; preds = %476
  %482 = load ptr, ptr %36, align 8
  %483 = load i32, ptr %41, align 4
  %484 = sext i32 %483 to i64
  %485 = getelementptr inbounds i32, ptr %482, i64 %484
  %486 = load i32, ptr %485, align 4
  store i32 %486, ptr %42, align 4
  %487 = load ptr, ptr %36, align 8
  %488 = load i32, ptr %37, align 4
  %489 = sub nsw i32 %488, 1
  %490 = load i32, ptr %41, align 4
  %491 = sub nsw i32 %489, %490
  %492 = sext i32 %491 to i64
  %493 = getelementptr inbounds i32, ptr %487, i64 %492
  %494 = load i32, ptr %493, align 4
  %495 = load ptr, ptr %36, align 8
  %496 = load i32, ptr %41, align 4
  %497 = sext i32 %496 to i64
  %498 = getelementptr inbounds i32, ptr %495, i64 %497
  store i32 %494, ptr %498, align 4
  %499 = load i32, ptr %42, align 4
  %500 = load ptr, ptr %36, align 8
  %501 = load i32, ptr %37, align 4
  %502 = sub nsw i32 %501, 1
  %503 = load i32, ptr %41, align 4
  %504 = sub nsw i32 %502, %503
  %505 = sext i32 %504 to i64
  %506 = getelementptr inbounds i32, ptr %500, i64 %505
  store i32 %499, ptr %506, align 4
  br label %507

507:                                              ; preds = %481
  %508 = load i32, ptr %41, align 4
  %509 = add nsw i32 %508, 1
  store i32 %509, ptr %41, align 4
  br label %476, !llvm.loop !38

510:                                              ; preds = %476
  %511 = load i32, ptr @N, align 4
  %512 = load i32, ptr @N, align 4
  %513 = mul nsw i32 %511, %512
  %514 = load i32, ptr %5, align 4
  %515 = add nsw i32 %514, 2
  %516 = mul nsw i32 %513, %515
  %517 = sext i32 %516 to i64
  %518 = mul i64 8, %517
  %519 = call noalias ptr @malloc(i64 noundef %518) #6
  store ptr %519, ptr %43, align 8
  store i32 0, ptr %44, align 4
  store i32 0, ptr %45, align 4
  store i32 0, ptr %46, align 4
  br label %520

520:                                              ; preds = %548, %510
  %521 = load i32, ptr %46, align 4
  %522 = load i32, ptr %37, align 4
  %523 = icmp slt i32 %521, %522
  br i1 %523, label %524, label %551

524:                                              ; preds = %520
  %525 = load ptr, ptr %36, align 8
  %526 = load i32, ptr %46, align 4
  %527 = sext i32 %526 to i64
  %528 = getelementptr inbounds i32, ptr %525, i64 %527
  %529 = load i32, ptr %528, align 4
  %530 = add nsw i32 %529, 1
  store i32 %530, ptr %47, align 4
  %531 = load ptr, ptr %7, align 8
  %532 = load i32, ptr %45, align 4
  %533 = sext i32 %532 to i64
  %534 = getelementptr inbounds %struct.Point, ptr %531, i64 %533
  %535 = load ptr, ptr %7, align 8
  %536 = load i32, ptr %47, align 4
  %537 = sext i32 %536 to i64
  %538 = getelementptr inbounds %struct.Point, ptr %535, i64 %537
  %539 = load ptr, ptr %11, align 8
  %540 = load i32, ptr %45, align 4
  %541 = sext i32 %540 to i64
  %542 = getelementptr inbounds ptr, ptr %539, i64 %541
  %543 = load ptr, ptr %542, align 8
  %544 = load ptr, ptr %43, align 8
  %545 = load i64, ptr %534, align 4
  %546 = load i64, ptr %538, align 4
  call void @appendPathSegment(i64 %545, i64 %546, ptr noundef %543, ptr noundef %544, ptr noundef %44)
  %547 = load i32, ptr %47, align 4
  store i32 %547, ptr %45, align 4
  br label %548

548:                                              ; preds = %524
  %549 = load i32, ptr %46, align 4
  %550 = add nsw i32 %549, 1
  store i32 %550, ptr %46, align 4
  br label %520, !llvm.loop !39

551:                                              ; preds = %520
  %552 = load ptr, ptr %7, align 8
  %553 = load i32, ptr %45, align 4
  %554 = sext i32 %553 to i64
  %555 = getelementptr inbounds %struct.Point, ptr %552, i64 %554
  %556 = load ptr, ptr %11, align 8
  %557 = load i32, ptr %45, align 4
  %558 = sext i32 %557 to i64
  %559 = getelementptr inbounds ptr, ptr %556, i64 %558
  %560 = load ptr, ptr %559, align 8
  %561 = load ptr, ptr %43, align 8
  %562 = load i64, ptr %555, align 4
  %563 = load i64, ptr %3, align 4
  call void @appendPathSegment(i64 %562, i64 %563, ptr noundef %560, ptr noundef %561, ptr noundef %44)
  %564 = load i32, ptr %30, align 4
  %565 = call i32 (ptr, ...) @printf(ptr noundef @.str.15, i32 noundef %564)
  %566 = call i32 (ptr, ...) @printf(ptr noundef @.str.16)
  store i32 0, ptr %48, align 4
  br label %567

567:                                              ; preds = %584, %551
  %568 = load i32, ptr %48, align 4
  %569 = load i32, ptr %37, align 4
  %570 = icmp slt i32 %568, %569
  br i1 %570, label %571, label %587

571:                                              ; preds = %567
  %572 = load i32, ptr %48, align 4
  %573 = icmp ne i32 %572, 0
  br i1 %573, label %574, label %576

574:                                              ; preds = %571
  %575 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  br label %576

576:                                              ; preds = %574, %571
  %577 = load ptr, ptr %36, align 8
  %578 = load i32, ptr %48, align 4
  %579 = sext i32 %578 to i64
  %580 = getelementptr inbounds i32, ptr %577, i64 %579
  %581 = load i32, ptr %580, align 4
  %582 = add nsw i32 %581, 1
  %583 = call i32 (ptr, ...) @printf(ptr noundef @.str.17, i32 noundef %582)
  br label %584

584:                                              ; preds = %576
  %585 = load i32, ptr %48, align 4
  %586 = add nsw i32 %585, 1
  store i32 %586, ptr %48, align 4
  br label %567, !llvm.loop !40

587:                                              ; preds = %567
  %588 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  %589 = load i32, ptr %44, align 4
  %590 = call i32 (ptr, ...) @printf(ptr noundef @.str.18, i32 noundef %589)
  %591 = load ptr, ptr %43, align 8
  %592 = load i32, ptr %44, align 4
  call void @printRoute(ptr noundef %591, i32 noundef %592)
  %593 = load ptr, ptr %43, align 8
  call void @free(ptr noundef %593) #8
  %594 = load ptr, ptr %36, align 8
  call void @free(ptr noundef %594) #8
  br label %595

595:                                              ; preds = %587, %442
  store i32 0, ptr %49, align 4
  br label %596

596:                                              ; preds = %616, %595
  %597 = load i32, ptr %49, align 4
  %598 = load i32, ptr %6, align 4
  %599 = icmp slt i32 %597, %598
  br i1 %599, label %600, label %619

600:                                              ; preds = %596
  %601 = load ptr, ptr %10, align 8
  %602 = load i32, ptr %49, align 4
  %603 = sext i32 %602 to i64
  %604 = getelementptr inbounds ptr, ptr %601, i64 %603
  %605 = load ptr, ptr %604, align 8
  call void @free(ptr noundef %605) #8
  %606 = load ptr, ptr %11, align 8
  %607 = load i32, ptr %49, align 4
  %608 = sext i32 %607 to i64
  %609 = getelementptr inbounds ptr, ptr %606, i64 %608
  %610 = load ptr, ptr %609, align 8
  call void @free(ptr noundef %610) #8
  %611 = load ptr, ptr %13, align 8
  %612 = load i32, ptr %49, align 4
  %613 = sext i32 %612 to i64
  %614 = getelementptr inbounds ptr, ptr %611, i64 %613
  %615 = load ptr, ptr %614, align 8
  call void @free(ptr noundef %615) #8
  br label %616

616:                                              ; preds = %600
  %617 = load i32, ptr %49, align 4
  %618 = add nsw i32 %617, 1
  store i32 %618, ptr %49, align 4
  br label %596, !llvm.loop !41

619:                                              ; preds = %596
  %620 = load ptr, ptr %10, align 8
  call void @free(ptr noundef %620) #8
  %621 = load ptr, ptr %11, align 8
  call void @free(ptr noundef %621) #8
  %622 = load ptr, ptr %13, align 8
  call void @free(ptr noundef %622) #8
  %623 = load ptr, ptr %17, align 8
  call void @free(ptr noundef %623) #8
  %624 = load ptr, ptr %18, align 8
  call void @free(ptr noundef %624) #8
  %625 = load ptr, ptr %7, align 8
  call void @free(ptr noundef %625) #8
  call void @freeGrid()
  store i32 0, ptr %1, align 4
  br label %626

626:                                              ; preds = %619, %60, %52
  %627 = load i32, ptr %1, align 4
  ret i32 %627
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
!22 = distinct !{!22, !7}
!23 = distinct !{!23, !7}
!24 = distinct !{!24, !7}
!25 = distinct !{!25, !7}
!26 = distinct !{!26, !7}
!27 = distinct !{!27, !7}
!28 = distinct !{!28, !7}
!29 = distinct !{!29, !7}
!30 = distinct !{!30, !7}
!31 = distinct !{!31, !7}
!32 = distinct !{!32, !7}
!33 = distinct !{!33, !7}
!34 = distinct !{!34, !7}
!35 = distinct !{!35, !7}
!36 = distinct !{!36, !7}
!37 = distinct !{!37, !7}
!38 = distinct !{!38, !7}
!39 = distinct !{!39, !7}
!40 = distinct !{!40, !7}
!41 = distinct !{!41, !7}

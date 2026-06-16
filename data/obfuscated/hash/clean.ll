; ModuleID = 'data/obfuscated/hash/clean.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Edge = type { i32, i32, i32 }
%struct.MinHeap = type { ptr, i32, i32 }
%struct.HeapNode = type { i32, i64 }

@edgeCount = dso_local global i32 0, align 4
@edges = dso_local global ptr null, align 8
@head = dso_local global ptr null, align 8
@N = dso_local global i32 0, align 4
@M = dso_local global i32 0, align 4
@.str = private unnamed_addr constant [6 x i8] c"%d %d\00", align 1
@.str.1 = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@.str.2 = private unnamed_addr constant [9 x i8] c"%d %d %d\00", align 1
@.str.3 = private unnamed_addr constant [4 x i8] c"-1\0A\00", align 1
@.str.4 = private unnamed_addr constant [20 x i8] c"Minimum cost: %lld\0A\00", align 1
@.str.5 = private unnamed_addr constant [22 x i8] c"Delivery order: None\0A\00", align 1
@.str.6 = private unnamed_addr constant [12 x i8] c"Full path: \00", align 1
@.str.7 = private unnamed_addr constant [2 x i8] c" \00", align 1
@.str.8 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.9 = private unnamed_addr constant [17 x i8] c"Delivery order: \00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @addEdge(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %7 = load i32, ptr %5, align 4
  %8 = load ptr, ptr @edges, align 8
  %9 = load i32, ptr @edgeCount, align 4
  %10 = sext i32 %9 to i64
  %11 = getelementptr inbounds %struct.Edge, ptr %8, i64 %10
  %12 = getelementptr inbounds nuw %struct.Edge, ptr %11, i32 0, i32 0
  store i32 %7, ptr %12, align 4
  %13 = load i32, ptr %6, align 4
  %14 = load ptr, ptr @edges, align 8
  %15 = load i32, ptr @edgeCount, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds %struct.Edge, ptr %14, i64 %16
  %18 = getelementptr inbounds nuw %struct.Edge, ptr %17, i32 0, i32 1
  store i32 %13, ptr %18, align 4
  %19 = load ptr, ptr @head, align 8
  %20 = load i32, ptr %4, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds i32, ptr %19, i64 %21
  %23 = load i32, ptr %22, align 4
  %24 = load ptr, ptr @edges, align 8
  %25 = load i32, ptr @edgeCount, align 4
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds %struct.Edge, ptr %24, i64 %26
  %28 = getelementptr inbounds nuw %struct.Edge, ptr %27, i32 0, i32 2
  store i32 %23, ptr %28, align 4
  %29 = load i32, ptr @edgeCount, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr @edgeCount, align 4
  %31 = load ptr, ptr @head, align 8
  %32 = load i32, ptr %4, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds i32, ptr %31, i64 %33
  store i32 %29, ptr %34, align 4
  ret void
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
  %8 = mul i64 16, %7
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
define dso_local void @swapHeapNode(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca %struct.HeapNode, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %6 = load ptr, ptr %3, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 %6, i64 16, i1 false)
  %7 = load ptr, ptr %3, align 8
  %8 = load ptr, ptr %4, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %7, ptr align 8 %8, i64 16, i1 false)
  %9 = load ptr, ptr %4, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %9, ptr align 8 %5, i64 16, i1 false)
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @heapPush(ptr noundef %0, i32 noundef %1, i64 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i64 %2, ptr %6, align 8
  %9 = load ptr, ptr %4, align 8
  %10 = getelementptr inbounds nuw %struct.MinHeap, ptr %9, i32 0, i32 1
  %11 = load i32, ptr %10, align 8
  %12 = add nsw i32 %11, 1
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
  %30 = mul i64 16, %29
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
  %48 = getelementptr inbounds %struct.HeapNode, ptr %45, i64 %47
  %49 = getelementptr inbounds nuw %struct.HeapNode, ptr %48, i32 0, i32 0
  store i32 %42, ptr %49, align 8
  %50 = load i64, ptr %6, align 8
  %51 = load ptr, ptr %4, align 8
  %52 = getelementptr inbounds nuw %struct.MinHeap, ptr %51, i32 0, i32 0
  %53 = load ptr, ptr %52, align 8
  %54 = load i32, ptr %7, align 4
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds %struct.HeapNode, ptr %53, i64 %55
  %57 = getelementptr inbounds nuw %struct.HeapNode, ptr %56, i32 0, i32 1
  store i64 %50, ptr %57, align 8
  br label %58

58:                                               ; preds = %82, %34
  %59 = load i32, ptr %7, align 4
  %60 = icmp sgt i32 %59, 1
  br i1 %60, label %61, label %96

61:                                               ; preds = %58
  %62 = load i32, ptr %7, align 4
  %63 = sdiv i32 %62, 2
  store i32 %63, ptr %8, align 4
  %64 = load ptr, ptr %4, align 8
  %65 = getelementptr inbounds nuw %struct.MinHeap, ptr %64, i32 0, i32 0
  %66 = load ptr, ptr %65, align 8
  %67 = load i32, ptr %8, align 4
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds %struct.HeapNode, ptr %66, i64 %68
  %70 = getelementptr inbounds nuw %struct.HeapNode, ptr %69, i32 0, i32 1
  %71 = load i64, ptr %70, align 8
  %72 = load ptr, ptr %4, align 8
  %73 = getelementptr inbounds nuw %struct.MinHeap, ptr %72, i32 0, i32 0
  %74 = load ptr, ptr %73, align 8
  %75 = load i32, ptr %7, align 4
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds %struct.HeapNode, ptr %74, i64 %76
  %78 = getelementptr inbounds nuw %struct.HeapNode, ptr %77, i32 0, i32 1
  %79 = load i64, ptr %78, align 8
  %80 = icmp sle i64 %71, %79
  br i1 %80, label %81, label %82

81:                                               ; preds = %61
  br label %96

82:                                               ; preds = %61
  %83 = load ptr, ptr %4, align 8
  %84 = getelementptr inbounds nuw %struct.MinHeap, ptr %83, i32 0, i32 0
  %85 = load ptr, ptr %84, align 8
  %86 = load i32, ptr %8, align 4
  %87 = sext i32 %86 to i64
  %88 = getelementptr inbounds %struct.HeapNode, ptr %85, i64 %87
  %89 = load ptr, ptr %4, align 8
  %90 = getelementptr inbounds nuw %struct.MinHeap, ptr %89, i32 0, i32 0
  %91 = load ptr, ptr %90, align 8
  %92 = load i32, ptr %7, align 4
  %93 = sext i32 %92 to i64
  %94 = getelementptr inbounds %struct.HeapNode, ptr %91, i64 %93
  call void @swapHeapNode(ptr noundef %88, ptr noundef %94)
  %95 = load i32, ptr %8, align 4
  store i32 %95, ptr %7, align 4
  br label %58, !llvm.loop !6

96:                                               ; preds = %81, %58
  ret void
}

; Function Attrs: nounwind allocsize(1)
declare ptr @realloc(ptr noundef, i64 noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local { i32, i64 } @heapPop(ptr noundef %0) #0 {
  %2 = alloca %struct.HeapNode, align 8
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  %8 = load ptr, ptr %3, align 8
  %9 = getelementptr inbounds nuw %struct.MinHeap, ptr %8, i32 0, i32 0
  %10 = load ptr, ptr %9, align 8
  %11 = getelementptr inbounds %struct.HeapNode, ptr %10, i64 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %11, i64 16, i1 false)
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.MinHeap, ptr %12, i32 0, i32 0
  %14 = load ptr, ptr %13, align 8
  %15 = getelementptr inbounds %struct.HeapNode, ptr %14, i64 1
  %16 = load ptr, ptr %3, align 8
  %17 = getelementptr inbounds nuw %struct.MinHeap, ptr %16, i32 0, i32 0
  %18 = load ptr, ptr %17, align 8
  %19 = load ptr, ptr %3, align 8
  %20 = getelementptr inbounds nuw %struct.MinHeap, ptr %19, i32 0, i32 1
  %21 = load i32, ptr %20, align 8
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds %struct.HeapNode, ptr %18, i64 %22
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %15, ptr align 8 %23, i64 16, i1 false)
  %24 = load ptr, ptr %3, align 8
  %25 = getelementptr inbounds nuw %struct.MinHeap, ptr %24, i32 0, i32 1
  %26 = load i32, ptr %25, align 8
  %27 = add nsw i32 %26, -1
  store i32 %27, ptr %25, align 8
  store i32 1, ptr %4, align 4
  br label %28

28:                                               ; preds = %1, %91
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
  br i1 %39, label %40, label %60

40:                                               ; preds = %28
  %41 = load ptr, ptr %3, align 8
  %42 = getelementptr inbounds nuw %struct.MinHeap, ptr %41, i32 0, i32 0
  %43 = load ptr, ptr %42, align 8
  %44 = load i32, ptr %5, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds %struct.HeapNode, ptr %43, i64 %45
  %47 = getelementptr inbounds nuw %struct.HeapNode, ptr %46, i32 0, i32 1
  %48 = load i64, ptr %47, align 8
  %49 = load ptr, ptr %3, align 8
  %50 = getelementptr inbounds nuw %struct.MinHeap, ptr %49, i32 0, i32 0
  %51 = load ptr, ptr %50, align 8
  %52 = load i32, ptr %7, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds %struct.HeapNode, ptr %51, i64 %53
  %55 = getelementptr inbounds nuw %struct.HeapNode, ptr %54, i32 0, i32 1
  %56 = load i64, ptr %55, align 8
  %57 = icmp slt i64 %48, %56
  br i1 %57, label %58, label %60

58:                                               ; preds = %40
  %59 = load i32, ptr %5, align 4
  store i32 %59, ptr %7, align 4
  br label %60

60:                                               ; preds = %58, %40, %28
  %61 = load i32, ptr %6, align 4
  %62 = load ptr, ptr %3, align 8
  %63 = getelementptr inbounds nuw %struct.MinHeap, ptr %62, i32 0, i32 1
  %64 = load i32, ptr %63, align 8
  %65 = icmp sle i32 %61, %64
  br i1 %65, label %66, label %86

66:                                               ; preds = %60
  %67 = load ptr, ptr %3, align 8
  %68 = getelementptr inbounds nuw %struct.MinHeap, ptr %67, i32 0, i32 0
  %69 = load ptr, ptr %68, align 8
  %70 = load i32, ptr %6, align 4
  %71 = sext i32 %70 to i64
  %72 = getelementptr inbounds %struct.HeapNode, ptr %69, i64 %71
  %73 = getelementptr inbounds nuw %struct.HeapNode, ptr %72, i32 0, i32 1
  %74 = load i64, ptr %73, align 8
  %75 = load ptr, ptr %3, align 8
  %76 = getelementptr inbounds nuw %struct.MinHeap, ptr %75, i32 0, i32 0
  %77 = load ptr, ptr %76, align 8
  %78 = load i32, ptr %7, align 4
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds %struct.HeapNode, ptr %77, i64 %79
  %81 = getelementptr inbounds nuw %struct.HeapNode, ptr %80, i32 0, i32 1
  %82 = load i64, ptr %81, align 8
  %83 = icmp slt i64 %74, %82
  br i1 %83, label %84, label %86

84:                                               ; preds = %66
  %85 = load i32, ptr %6, align 4
  store i32 %85, ptr %7, align 4
  br label %86

86:                                               ; preds = %84, %66, %60
  %87 = load i32, ptr %7, align 4
  %88 = load i32, ptr %4, align 4
  %89 = icmp eq i32 %87, %88
  br i1 %89, label %90, label %91

90:                                               ; preds = %86
  br label %105

91:                                               ; preds = %86
  %92 = load ptr, ptr %3, align 8
  %93 = getelementptr inbounds nuw %struct.MinHeap, ptr %92, i32 0, i32 0
  %94 = load ptr, ptr %93, align 8
  %95 = load i32, ptr %4, align 4
  %96 = sext i32 %95 to i64
  %97 = getelementptr inbounds %struct.HeapNode, ptr %94, i64 %96
  %98 = load ptr, ptr %3, align 8
  %99 = getelementptr inbounds nuw %struct.MinHeap, ptr %98, i32 0, i32 0
  %100 = load ptr, ptr %99, align 8
  %101 = load i32, ptr %7, align 4
  %102 = sext i32 %101 to i64
  %103 = getelementptr inbounds %struct.HeapNode, ptr %100, i64 %102
  call void @swapHeapNode(ptr noundef %97, ptr noundef %103)
  %104 = load i32, ptr %7, align 4
  store i32 %104, ptr %4, align 4
  br label %28

105:                                              ; preds = %90
  %106 = load { i32, i64 }, ptr %2, align 8
  ret { i32, i64 } %106
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @heapEmpty(ptr noundef %0) #0 {
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
define dso_local void @dijkstra(i32 noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca %struct.HeapNode, align 8
  %10 = alloca i32, align 4
  %11 = alloca i64, align 8
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  store i32 1, ptr %7, align 4
  br label %15

15:                                               ; preds = %28, %3
  %16 = load i32, ptr %7, align 4
  %17 = load i32, ptr @N, align 4
  %18 = icmp sle i32 %16, %17
  br i1 %18, label %19, label %31

19:                                               ; preds = %15
  %20 = load ptr, ptr %5, align 8
  %21 = load i32, ptr %7, align 4
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i64, ptr %20, i64 %22
  store i64 4000000000000000000, ptr %23, align 8
  %24 = load ptr, ptr %6, align 8
  %25 = load i32, ptr %7, align 4
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds i32, ptr %24, i64 %26
  store i32 -1, ptr %27, align 4
  br label %28

28:                                               ; preds = %19
  %29 = load i32, ptr %7, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %7, align 4
  br label %15, !llvm.loop !8

31:                                               ; preds = %15
  %32 = load i32, ptr @M, align 4
  %33 = mul nsw i32 %32, 4
  %34 = load i32, ptr @N, align 4
  %35 = add nsw i32 %33, %34
  %36 = add nsw i32 %35, 100
  %37 = call ptr @createHeap(i32 noundef %36)
  store ptr %37, ptr %8, align 8
  %38 = load ptr, ptr %5, align 8
  %39 = load i32, ptr %4, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds i64, ptr %38, i64 %40
  store i64 0, ptr %41, align 8
  %42 = load ptr, ptr %8, align 8
  %43 = load i32, ptr %4, align 4
  call void @heapPush(ptr noundef %42, i32 noundef %43, i64 noundef 0)
  br label %44

44:                                               ; preds = %137, %67, %31
  %45 = load ptr, ptr %8, align 8
  %46 = call i32 @heapEmpty(ptr noundef %45)
  %47 = icmp ne i32 %46, 0
  %48 = xor i1 %47, true
  br i1 %48, label %49, label %138

49:                                               ; preds = %44
  %50 = load ptr, ptr %8, align 8
  %51 = call { i32, i64 } @heapPop(ptr noundef %50)
  %52 = getelementptr inbounds nuw { i32, i64 }, ptr %9, i32 0, i32 0
  %53 = extractvalue { i32, i64 } %51, 0
  store i32 %53, ptr %52, align 8
  %54 = getelementptr inbounds nuw { i32, i64 }, ptr %9, i32 0, i32 1
  %55 = extractvalue { i32, i64 } %51, 1
  store i64 %55, ptr %54, align 8
  %56 = getelementptr inbounds nuw %struct.HeapNode, ptr %9, i32 0, i32 0
  %57 = load i32, ptr %56, align 8
  store i32 %57, ptr %10, align 4
  %58 = getelementptr inbounds nuw %struct.HeapNode, ptr %9, i32 0, i32 1
  %59 = load i64, ptr %58, align 8
  store i64 %59, ptr %11, align 8
  %60 = load i64, ptr %11, align 8
  %61 = load ptr, ptr %5, align 8
  %62 = load i32, ptr %10, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds i64, ptr %61, i64 %63
  %65 = load i64, ptr %64, align 8
  %66 = icmp ne i64 %60, %65
  br i1 %66, label %67, label %68

67:                                               ; preds = %49
  br label %44, !llvm.loop !9

68:                                               ; preds = %49
  %69 = load ptr, ptr @head, align 8
  %70 = load i32, ptr %10, align 4
  %71 = sext i32 %70 to i64
  %72 = getelementptr inbounds i32, ptr %69, i64 %71
  %73 = load i32, ptr %72, align 4
  store i32 %73, ptr %12, align 4
  br label %74

74:                                               ; preds = %130, %68
  %75 = load i32, ptr %12, align 4
  %76 = icmp ne i32 %75, -1
  br i1 %76, label %77, label %137

77:                                               ; preds = %74
  %78 = load ptr, ptr @edges, align 8
  %79 = load i32, ptr %12, align 4
  %80 = sext i32 %79 to i64
  %81 = getelementptr inbounds %struct.Edge, ptr %78, i64 %80
  %82 = getelementptr inbounds nuw %struct.Edge, ptr %81, i32 0, i32 0
  %83 = load i32, ptr %82, align 4
  store i32 %83, ptr %13, align 4
  %84 = load ptr, ptr @edges, align 8
  %85 = load i32, ptr %12, align 4
  %86 = sext i32 %85 to i64
  %87 = getelementptr inbounds %struct.Edge, ptr %84, i64 %86
  %88 = getelementptr inbounds nuw %struct.Edge, ptr %87, i32 0, i32 1
  %89 = load i32, ptr %88, align 4
  store i32 %89, ptr %14, align 4
  %90 = load ptr, ptr %5, align 8
  %91 = load i32, ptr %10, align 4
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds i64, ptr %90, i64 %92
  %94 = load i64, ptr %93, align 8
  %95 = load i32, ptr %14, align 4
  %96 = sext i32 %95 to i64
  %97 = add nsw i64 %94, %96
  %98 = load ptr, ptr %5, align 8
  %99 = load i32, ptr %13, align 4
  %100 = sext i32 %99 to i64
  %101 = getelementptr inbounds i64, ptr %98, i64 %100
  %102 = load i64, ptr %101, align 8
  %103 = icmp slt i64 %97, %102
  br i1 %103, label %104, label %129

104:                                              ; preds = %77
  %105 = load ptr, ptr %5, align 8
  %106 = load i32, ptr %10, align 4
  %107 = sext i32 %106 to i64
  %108 = getelementptr inbounds i64, ptr %105, i64 %107
  %109 = load i64, ptr %108, align 8
  %110 = load i32, ptr %14, align 4
  %111 = sext i32 %110 to i64
  %112 = add nsw i64 %109, %111
  %113 = load ptr, ptr %5, align 8
  %114 = load i32, ptr %13, align 4
  %115 = sext i32 %114 to i64
  %116 = getelementptr inbounds i64, ptr %113, i64 %115
  store i64 %112, ptr %116, align 8
  %117 = load i32, ptr %10, align 4
  %118 = load ptr, ptr %6, align 8
  %119 = load i32, ptr %13, align 4
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds i32, ptr %118, i64 %120
  store i32 %117, ptr %121, align 4
  %122 = load ptr, ptr %8, align 8
  %123 = load i32, ptr %13, align 4
  %124 = load ptr, ptr %5, align 8
  %125 = load i32, ptr %13, align 4
  %126 = sext i32 %125 to i64
  %127 = getelementptr inbounds i64, ptr %124, i64 %126
  %128 = load i64, ptr %127, align 8
  call void @heapPush(ptr noundef %122, i32 noundef %123, i64 noundef %128)
  br label %129

129:                                              ; preds = %104, %77
  br label %130

130:                                              ; preds = %129
  %131 = load ptr, ptr @edges, align 8
  %132 = load i32, ptr %12, align 4
  %133 = sext i32 %132 to i64
  %134 = getelementptr inbounds %struct.Edge, ptr %131, i64 %133
  %135 = getelementptr inbounds nuw %struct.Edge, ptr %134, i32 0, i32 2
  %136 = load i32, ptr %135, align 4
  store i32 %136, ptr %12, align 4
  br label %74, !llvm.loop !10

137:                                              ; preds = %74
  br label %44, !llvm.loop !9

138:                                              ; preds = %44
  %139 = load ptr, ptr %8, align 8
  call void @freeHeap(ptr noundef %139)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @appendSegment(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4) #0 {
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  store i32 %0, ptr %6, align 4
  store i32 %1, ptr %7, align 4
  store ptr %2, ptr %8, align 8
  store ptr %3, ptr %9, align 8
  store ptr %4, ptr %10, align 8
  %16 = load i32, ptr @N, align 4
  %17 = add nsw i32 %16, 5
  %18 = sext i32 %17 to i64
  %19 = mul i64 4, %18
  %20 = call noalias ptr @malloc(i64 noundef %19) #6
  store ptr %20, ptr %11, align 8
  store i32 0, ptr %12, align 4
  %21 = load i32, ptr %7, align 4
  store i32 %21, ptr %13, align 4
  br label %22

22:                                               ; preds = %36, %5
  %23 = load i32, ptr %13, align 4
  %24 = icmp ne i32 %23, -1
  br i1 %24, label %25, label %42

25:                                               ; preds = %22
  %26 = load i32, ptr %13, align 4
  %27 = load ptr, ptr %11, align 8
  %28 = load i32, ptr %12, align 4
  %29 = add nsw i32 %28, 1
  store i32 %29, ptr %12, align 4
  %30 = sext i32 %28 to i64
  %31 = getelementptr inbounds i32, ptr %27, i64 %30
  store i32 %26, ptr %31, align 4
  %32 = load i32, ptr %13, align 4
  %33 = load i32, ptr %6, align 4
  %34 = icmp eq i32 %32, %33
  br i1 %34, label %35, label %36

35:                                               ; preds = %25
  br label %42

36:                                               ; preds = %25
  %37 = load ptr, ptr %8, align 8
  %38 = load i32, ptr %13, align 4
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds i32, ptr %37, i64 %39
  %41 = load i32, ptr %40, align 4
  store i32 %41, ptr %13, align 4
  br label %22, !llvm.loop !11

42:                                               ; preds = %35, %22
  %43 = load i32, ptr %12, align 4
  %44 = icmp eq i32 %43, 0
  br i1 %44, label %54, label %45

45:                                               ; preds = %42
  %46 = load ptr, ptr %11, align 8
  %47 = load i32, ptr %12, align 4
  %48 = sub nsw i32 %47, 1
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds i32, ptr %46, i64 %49
  %51 = load i32, ptr %50, align 4
  %52 = load i32, ptr %6, align 4
  %53 = icmp ne i32 %51, %52
  br i1 %53, label %54, label %56

54:                                               ; preds = %45, %42
  %55 = load ptr, ptr %11, align 8
  call void @free(ptr noundef %55) #8
  br label %97

56:                                               ; preds = %45
  %57 = load i32, ptr %12, align 4
  %58 = sub nsw i32 %57, 1
  store i32 %58, ptr %14, align 4
  br label %59

59:                                               ; preds = %92, %56
  %60 = load i32, ptr %14, align 4
  %61 = icmp sge i32 %60, 0
  br i1 %61, label %62, label %95

62:                                               ; preds = %59
  %63 = load ptr, ptr %11, align 8
  %64 = load i32, ptr %14, align 4
  %65 = sext i32 %64 to i64
  %66 = getelementptr inbounds i32, ptr %63, i64 %65
  %67 = load i32, ptr %66, align 4
  store i32 %67, ptr %15, align 4
  %68 = load ptr, ptr %10, align 8
  %69 = load i32, ptr %68, align 4
  %70 = icmp sgt i32 %69, 0
  br i1 %70, label %71, label %82

71:                                               ; preds = %62
  %72 = load ptr, ptr %9, align 8
  %73 = load ptr, ptr %10, align 8
  %74 = load i32, ptr %73, align 4
  %75 = sub nsw i32 %74, 1
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds i32, ptr %72, i64 %76
  %78 = load i32, ptr %77, align 4
  %79 = load i32, ptr %15, align 4
  %80 = icmp eq i32 %78, %79
  br i1 %80, label %81, label %82

81:                                               ; preds = %71
  br label %92

82:                                               ; preds = %71, %62
  %83 = load i32, ptr %15, align 4
  %84 = load ptr, ptr %9, align 8
  %85 = load ptr, ptr %10, align 8
  %86 = load i32, ptr %85, align 4
  %87 = sext i32 %86 to i64
  %88 = getelementptr inbounds i32, ptr %84, i64 %87
  store i32 %83, ptr %88, align 4
  %89 = load ptr, ptr %10, align 8
  %90 = load i32, ptr %89, align 4
  %91 = add nsw i32 %90, 1
  store i32 %91, ptr %89, align 4
  br label %92

92:                                               ; preds = %82, %81
  %93 = load i32, ptr %14, align 4
  %94 = add nsw i32 %93, -1
  store i32 %94, ptr %14, align 4
  br label %59, !llvm.loop !12

95:                                               ; preds = %59
  %96 = load ptr, ptr %11, align 8
  call void @free(ptr noundef %96) #8
  br label %97

97:                                               ; preds = %95, %54
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca ptr, align 8
  %14 = alloca i32, align 4
  %15 = alloca ptr, align 8
  %16 = alloca ptr, align 8
  %17 = alloca i32, align 4
  %18 = alloca ptr, align 8
  %19 = alloca i32, align 4
  %20 = alloca i32, align 4
  %21 = alloca ptr, align 8
  %22 = alloca i32, align 4
  %23 = alloca i32, align 4
  %24 = alloca i32, align 4
  %25 = alloca ptr, align 8
  %26 = alloca ptr, align 8
  %27 = alloca i32, align 4
  %28 = alloca i32, align 4
  %29 = alloca i32, align 4
  %30 = alloca i32, align 4
  %31 = alloca i32, align 4
  %32 = alloca i32, align 4
  %33 = alloca i64, align 8
  %34 = alloca i32, align 4
  %35 = alloca i64, align 8
  %36 = alloca i32, align 4
  %37 = alloca i64, align 8
  %38 = alloca i32, align 4
  %39 = alloca i64, align 8
  %40 = alloca i32, align 4
  %41 = alloca i32, align 4
  %42 = alloca i64, align 8
  %43 = alloca i64, align 8
  %44 = alloca ptr, align 8
  %45 = alloca i32, align 4
  %46 = alloca i32, align 4
  %47 = alloca i32, align 4
  %48 = alloca i32, align 4
  %49 = alloca i32, align 4
  %50 = alloca i32, align 4
  %51 = alloca i32, align 4
  %52 = alloca ptr, align 8
  %53 = alloca i32, align 4
  %54 = alloca i32, align 4
  %55 = alloca i32, align 4
  %56 = alloca i32, align 4
  %57 = alloca i32, align 4
  %58 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  %59 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str, ptr noundef @N, ptr noundef @M)
  %60 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str, ptr noundef %2, ptr noundef %3)
  %61 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str.1, ptr noundef %4)
  %62 = load i32, ptr %4, align 4
  %63 = sext i32 %62 to i64
  %64 = mul i64 4, %63
  %65 = call noalias ptr @malloc(i64 noundef %64) #6
  store ptr %65, ptr %5, align 8
  store i32 0, ptr %6, align 4
  br label %66

66:                                               ; preds = %76, %0
  %67 = load i32, ptr %6, align 4
  %68 = load i32, ptr %4, align 4
  %69 = icmp slt i32 %67, %68
  br i1 %69, label %70, label %79

70:                                               ; preds = %66
  %71 = load ptr, ptr %5, align 8
  %72 = load i32, ptr %6, align 4
  %73 = sext i32 %72 to i64
  %74 = getelementptr inbounds i32, ptr %71, i64 %73
  %75 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str.1, ptr noundef %74)
  br label %76

76:                                               ; preds = %70
  %77 = load i32, ptr %6, align 4
  %78 = add nsw i32 %77, 1
  store i32 %78, ptr %6, align 4
  br label %66, !llvm.loop !13

79:                                               ; preds = %66
  %80 = load i32, ptr @N, align 4
  %81 = add nsw i32 %80, 1
  %82 = sext i32 %81 to i64
  %83 = mul i64 4, %82
  %84 = call noalias ptr @malloc(i64 noundef %83) #6
  store ptr %84, ptr @head, align 8
  %85 = load i32, ptr @M, align 4
  %86 = mul nsw i32 2, %85
  %87 = add nsw i32 %86, 5
  %88 = sext i32 %87 to i64
  %89 = mul i64 12, %88
  %90 = call noalias ptr @malloc(i64 noundef %89) #6
  store ptr %90, ptr @edges, align 8
  store i32 1, ptr %7, align 4
  br label %91

91:                                               ; preds = %100, %79
  %92 = load i32, ptr %7, align 4
  %93 = load i32, ptr @N, align 4
  %94 = icmp sle i32 %92, %93
  br i1 %94, label %95, label %103

95:                                               ; preds = %91
  %96 = load ptr, ptr @head, align 8
  %97 = load i32, ptr %7, align 4
  %98 = sext i32 %97 to i64
  %99 = getelementptr inbounds i32, ptr %96, i64 %98
  store i32 -1, ptr %99, align 4
  br label %100

100:                                              ; preds = %95
  %101 = load i32, ptr %7, align 4
  %102 = add nsw i32 %101, 1
  store i32 %102, ptr %7, align 4
  br label %91, !llvm.loop !14

103:                                              ; preds = %91
  store i32 0, ptr %8, align 4
  br label %104

104:                                              ; preds = %116, %103
  %105 = load i32, ptr %8, align 4
  %106 = load i32, ptr @M, align 4
  %107 = icmp slt i32 %105, %106
  br i1 %107, label %108, label %119

108:                                              ; preds = %104
  %109 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str.2, ptr noundef %9, ptr noundef %10, ptr noundef %11)
  %110 = load i32, ptr %9, align 4
  %111 = load i32, ptr %10, align 4
  %112 = load i32, ptr %11, align 4
  call void @addEdge(i32 noundef %110, i32 noundef %111, i32 noundef %112)
  %113 = load i32, ptr %10, align 4
  %114 = load i32, ptr %9, align 4
  %115 = load i32, ptr %11, align 4
  call void @addEdge(i32 noundef %113, i32 noundef %114, i32 noundef %115)
  br label %116

116:                                              ; preds = %108
  %117 = load i32, ptr %8, align 4
  %118 = add nsw i32 %117, 1
  store i32 %118, ptr %8, align 4
  br label %104, !llvm.loop !15

119:                                              ; preds = %104
  %120 = load i32, ptr %4, align 4
  %121 = add nsw i32 %120, 2
  store i32 %121, ptr %12, align 4
  %122 = load i32, ptr %12, align 4
  %123 = sext i32 %122 to i64
  %124 = mul i64 4, %123
  %125 = call noalias ptr @malloc(i64 noundef %124) #6
  store ptr %125, ptr %13, align 8
  %126 = load i32, ptr %2, align 4
  %127 = load ptr, ptr %13, align 8
  %128 = getelementptr inbounds i32, ptr %127, i64 0
  store i32 %126, ptr %128, align 4
  store i32 0, ptr %14, align 4
  br label %129

129:                                              ; preds = %144, %119
  %130 = load i32, ptr %14, align 4
  %131 = load i32, ptr %4, align 4
  %132 = icmp slt i32 %130, %131
  br i1 %132, label %133, label %147

133:                                              ; preds = %129
  %134 = load ptr, ptr %5, align 8
  %135 = load i32, ptr %14, align 4
  %136 = sext i32 %135 to i64
  %137 = getelementptr inbounds i32, ptr %134, i64 %136
  %138 = load i32, ptr %137, align 4
  %139 = load ptr, ptr %13, align 8
  %140 = load i32, ptr %14, align 4
  %141 = add nsw i32 %140, 1
  %142 = sext i32 %141 to i64
  %143 = getelementptr inbounds i32, ptr %139, i64 %142
  store i32 %138, ptr %143, align 4
  br label %144

144:                                              ; preds = %133
  %145 = load i32, ptr %14, align 4
  %146 = add nsw i32 %145, 1
  store i32 %146, ptr %14, align 4
  br label %129, !llvm.loop !16

147:                                              ; preds = %129
  %148 = load i32, ptr %3, align 4
  %149 = load ptr, ptr %13, align 8
  %150 = load i32, ptr %4, align 4
  %151 = add nsw i32 %150, 1
  %152 = sext i32 %151 to i64
  %153 = getelementptr inbounds i32, ptr %149, i64 %152
  store i32 %148, ptr %153, align 4
  %154 = load i32, ptr %12, align 4
  %155 = sext i32 %154 to i64
  %156 = mul i64 8, %155
  %157 = call noalias ptr @malloc(i64 noundef %156) #6
  store ptr %157, ptr %15, align 8
  %158 = load i32, ptr %12, align 4
  %159 = sext i32 %158 to i64
  %160 = mul i64 8, %159
  %161 = call noalias ptr @malloc(i64 noundef %160) #6
  store ptr %161, ptr %16, align 8
  store i32 0, ptr %17, align 4
  br label %162

162:                                              ; preds = %200, %147
  %163 = load i32, ptr %17, align 4
  %164 = load i32, ptr %12, align 4
  %165 = icmp slt i32 %163, %164
  br i1 %165, label %166, label %203

166:                                              ; preds = %162
  %167 = load i32, ptr @N, align 4
  %168 = add nsw i32 %167, 1
  %169 = sext i32 %168 to i64
  %170 = mul i64 8, %169
  %171 = call noalias ptr @malloc(i64 noundef %170) #6
  %172 = load ptr, ptr %15, align 8
  %173 = load i32, ptr %17, align 4
  %174 = sext i32 %173 to i64
  %175 = getelementptr inbounds ptr, ptr %172, i64 %174
  store ptr %171, ptr %175, align 8
  %176 = load i32, ptr @N, align 4
  %177 = add nsw i32 %176, 1
  %178 = sext i32 %177 to i64
  %179 = mul i64 4, %178
  %180 = call noalias ptr @malloc(i64 noundef %179) #6
  %181 = load ptr, ptr %16, align 8
  %182 = load i32, ptr %17, align 4
  %183 = sext i32 %182 to i64
  %184 = getelementptr inbounds ptr, ptr %181, i64 %183
  store ptr %180, ptr %184, align 8
  %185 = load ptr, ptr %13, align 8
  %186 = load i32, ptr %17, align 4
  %187 = sext i32 %186 to i64
  %188 = getelementptr inbounds i32, ptr %185, i64 %187
  %189 = load i32, ptr %188, align 4
  %190 = load ptr, ptr %15, align 8
  %191 = load i32, ptr %17, align 4
  %192 = sext i32 %191 to i64
  %193 = getelementptr inbounds ptr, ptr %190, i64 %192
  %194 = load ptr, ptr %193, align 8
  %195 = load ptr, ptr %16, align 8
  %196 = load i32, ptr %17, align 4
  %197 = sext i32 %196 to i64
  %198 = getelementptr inbounds ptr, ptr %195, i64 %197
  %199 = load ptr, ptr %198, align 8
  call void @dijkstra(i32 noundef %189, ptr noundef %194, ptr noundef %199)
  br label %200

200:                                              ; preds = %166
  %201 = load i32, ptr %17, align 4
  %202 = add nsw i32 %201, 1
  store i32 %202, ptr %17, align 4
  br label %162, !llvm.loop !17

203:                                              ; preds = %162
  %204 = load i32, ptr %12, align 4
  %205 = sext i32 %204 to i64
  %206 = mul i64 8, %205
  %207 = call noalias ptr @malloc(i64 noundef %206) #6
  store ptr %207, ptr %18, align 8
  store i32 0, ptr %19, align 4
  br label %208

208:                                              ; preds = %251, %203
  %209 = load i32, ptr %19, align 4
  %210 = load i32, ptr %12, align 4
  %211 = icmp slt i32 %209, %210
  br i1 %211, label %212, label %254

212:                                              ; preds = %208
  %213 = load i32, ptr %12, align 4
  %214 = sext i32 %213 to i64
  %215 = mul i64 8, %214
  %216 = call noalias ptr @malloc(i64 noundef %215) #6
  %217 = load ptr, ptr %18, align 8
  %218 = load i32, ptr %19, align 4
  %219 = sext i32 %218 to i64
  %220 = getelementptr inbounds ptr, ptr %217, i64 %219
  store ptr %216, ptr %220, align 8
  store i32 0, ptr %20, align 4
  br label %221

221:                                              ; preds = %247, %212
  %222 = load i32, ptr %20, align 4
  %223 = load i32, ptr %12, align 4
  %224 = icmp slt i32 %222, %223
  br i1 %224, label %225, label %250

225:                                              ; preds = %221
  %226 = load ptr, ptr %15, align 8
  %227 = load i32, ptr %19, align 4
  %228 = sext i32 %227 to i64
  %229 = getelementptr inbounds ptr, ptr %226, i64 %228
  %230 = load ptr, ptr %229, align 8
  %231 = load ptr, ptr %13, align 8
  %232 = load i32, ptr %20, align 4
  %233 = sext i32 %232 to i64
  %234 = getelementptr inbounds i32, ptr %231, i64 %233
  %235 = load i32, ptr %234, align 4
  %236 = sext i32 %235 to i64
  %237 = getelementptr inbounds i64, ptr %230, i64 %236
  %238 = load i64, ptr %237, align 8
  %239 = load ptr, ptr %18, align 8
  %240 = load i32, ptr %19, align 4
  %241 = sext i32 %240 to i64
  %242 = getelementptr inbounds ptr, ptr %239, i64 %241
  %243 = load ptr, ptr %242, align 8
  %244 = load i32, ptr %20, align 4
  %245 = sext i32 %244 to i64
  %246 = getelementptr inbounds i64, ptr %243, i64 %245
  store i64 %238, ptr %246, align 8
  br label %247

247:                                              ; preds = %225
  %248 = load i32, ptr %20, align 4
  %249 = add nsw i32 %248, 1
  store i32 %249, ptr %20, align 4
  br label %221, !llvm.loop !18

250:                                              ; preds = %221
  br label %251

251:                                              ; preds = %250
  %252 = load i32, ptr %19, align 4
  %253 = add nsw i32 %252, 1
  store i32 %253, ptr %19, align 4
  br label %208, !llvm.loop !19

254:                                              ; preds = %208
  %255 = load i32, ptr %4, align 4
  %256 = icmp eq i32 %255, 0
  br i1 %256, label %257, label %310

257:                                              ; preds = %254
  %258 = load ptr, ptr %18, align 8
  %259 = getelementptr inbounds ptr, ptr %258, i64 0
  %260 = load ptr, ptr %259, align 8
  %261 = getelementptr inbounds i64, ptr %260, i64 1
  %262 = load i64, ptr %261, align 8
  %263 = icmp sge i64 %262, 4000000000000000000
  br i1 %263, label %264, label %266

264:                                              ; preds = %257
  %265 = call i32 (ptr, ...) @printf(ptr noundef @.str.3)
  br label %309

266:                                              ; preds = %257
  %267 = load ptr, ptr %18, align 8
  %268 = getelementptr inbounds ptr, ptr %267, i64 0
  %269 = load ptr, ptr %268, align 8
  %270 = getelementptr inbounds i64, ptr %269, i64 1
  %271 = load i64, ptr %270, align 8
  %272 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i64 noundef %271)
  %273 = call i32 (ptr, ...) @printf(ptr noundef @.str.5)
  %274 = load i32, ptr @N, align 4
  %275 = mul nsw i32 %274, 2
  %276 = add nsw i32 %275, 10
  %277 = sext i32 %276 to i64
  %278 = mul i64 4, %277
  %279 = call noalias ptr @malloc(i64 noundef %278) #6
  store ptr %279, ptr %21, align 8
  store i32 0, ptr %22, align 4
  %280 = load i32, ptr %2, align 4
  %281 = load i32, ptr %3, align 4
  %282 = load ptr, ptr %16, align 8
  %283 = getelementptr inbounds ptr, ptr %282, i64 0
  %284 = load ptr, ptr %283, align 8
  %285 = load ptr, ptr %21, align 8
  call void @appendSegment(i32 noundef %280, i32 noundef %281, ptr noundef %284, ptr noundef %285, ptr noundef %22)
  %286 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  store i32 0, ptr %23, align 4
  br label %287

287:                                              ; preds = %303, %266
  %288 = load i32, ptr %23, align 4
  %289 = load i32, ptr %22, align 4
  %290 = icmp slt i32 %288, %289
  br i1 %290, label %291, label %306

291:                                              ; preds = %287
  %292 = load i32, ptr %23, align 4
  %293 = icmp ne i32 %292, 0
  br i1 %293, label %294, label %296

294:                                              ; preds = %291
  %295 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  br label %296

296:                                              ; preds = %294, %291
  %297 = load ptr, ptr %21, align 8
  %298 = load i32, ptr %23, align 4
  %299 = sext i32 %298 to i64
  %300 = getelementptr inbounds i32, ptr %297, i64 %299
  %301 = load i32, ptr %300, align 4
  %302 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %301)
  br label %303

303:                                              ; preds = %296
  %304 = load i32, ptr %23, align 4
  %305 = add nsw i32 %304, 1
  store i32 %305, ptr %23, align 4
  br label %287, !llvm.loop !20

306:                                              ; preds = %287
  %307 = call i32 (ptr, ...) @printf(ptr noundef @.str.8)
  %308 = load ptr, ptr %21, align 8
  call void @free(ptr noundef %308) #8
  br label %309

309:                                              ; preds = %306, %264
  store i32 0, ptr %1, align 4
  br label %767

310:                                              ; preds = %254
  %311 = load i32, ptr %4, align 4
  %312 = shl i32 1, %311
  store i32 %312, ptr %24, align 4
  %313 = load i32, ptr %24, align 4
  %314 = sext i32 %313 to i64
  %315 = mul i64 8, %314
  %316 = load i32, ptr %4, align 4
  %317 = sext i32 %316 to i64
  %318 = mul i64 %315, %317
  %319 = call noalias ptr @malloc(i64 noundef %318) #6
  store ptr %319, ptr %25, align 8
  %320 = load i32, ptr %24, align 4
  %321 = sext i32 %320 to i64
  %322 = mul i64 4, %321
  %323 = load i32, ptr %4, align 4
  %324 = sext i32 %323 to i64
  %325 = mul i64 %322, %324
  %326 = call noalias ptr @malloc(i64 noundef %325) #6
  store ptr %326, ptr %26, align 8
  store i32 0, ptr %27, align 4
  br label %327

327:                                              ; preds = %357, %310
  %328 = load i32, ptr %27, align 4
  %329 = load i32, ptr %24, align 4
  %330 = icmp slt i32 %328, %329
  br i1 %330, label %331, label %360

331:                                              ; preds = %327
  store i32 0, ptr %28, align 4
  br label %332

332:                                              ; preds = %353, %331
  %333 = load i32, ptr %28, align 4
  %334 = load i32, ptr %4, align 4
  %335 = icmp slt i32 %333, %334
  br i1 %335, label %336, label %356

336:                                              ; preds = %332
  %337 = load ptr, ptr %25, align 8
  %338 = load i32, ptr %27, align 4
  %339 = load i32, ptr %4, align 4
  %340 = mul nsw i32 %338, %339
  %341 = load i32, ptr %28, align 4
  %342 = add nsw i32 %340, %341
  %343 = sext i32 %342 to i64
  %344 = getelementptr inbounds i64, ptr %337, i64 %343
  store i64 4000000000000000000, ptr %344, align 8
  %345 = load ptr, ptr %26, align 8
  %346 = load i32, ptr %27, align 4
  %347 = load i32, ptr %4, align 4
  %348 = mul nsw i32 %346, %347
  %349 = load i32, ptr %28, align 4
  %350 = add nsw i32 %348, %349
  %351 = sext i32 %350 to i64
  %352 = getelementptr inbounds i32, ptr %345, i64 %351
  store i32 -1, ptr %352, align 4
  br label %353

353:                                              ; preds = %336
  %354 = load i32, ptr %28, align 4
  %355 = add nsw i32 %354, 1
  store i32 %355, ptr %28, align 4
  br label %332, !llvm.loop !21

356:                                              ; preds = %332
  br label %357

357:                                              ; preds = %356
  %358 = load i32, ptr %27, align 4
  %359 = add nsw i32 %358, 1
  store i32 %359, ptr %27, align 4
  br label %327, !llvm.loop !22

360:                                              ; preds = %327
  store i32 0, ptr %29, align 4
  br label %361

361:                                              ; preds = %395, %360
  %362 = load i32, ptr %29, align 4
  %363 = load i32, ptr %4, align 4
  %364 = icmp slt i32 %362, %363
  br i1 %364, label %365, label %398

365:                                              ; preds = %361
  %366 = load ptr, ptr %18, align 8
  %367 = getelementptr inbounds ptr, ptr %366, i64 0
  %368 = load ptr, ptr %367, align 8
  %369 = load i32, ptr %29, align 4
  %370 = add nsw i32 %369, 1
  %371 = sext i32 %370 to i64
  %372 = getelementptr inbounds i64, ptr %368, i64 %371
  %373 = load i64, ptr %372, align 8
  %374 = icmp slt i64 %373, 4000000000000000000
  br i1 %374, label %375, label %394

375:                                              ; preds = %365
  %376 = load i32, ptr %29, align 4
  %377 = shl i32 1, %376
  store i32 %377, ptr %30, align 4
  %378 = load ptr, ptr %18, align 8
  %379 = getelementptr inbounds ptr, ptr %378, i64 0
  %380 = load ptr, ptr %379, align 8
  %381 = load i32, ptr %29, align 4
  %382 = add nsw i32 %381, 1
  %383 = sext i32 %382 to i64
  %384 = getelementptr inbounds i64, ptr %380, i64 %383
  %385 = load i64, ptr %384, align 8
  %386 = load ptr, ptr %25, align 8
  %387 = load i32, ptr %30, align 4
  %388 = load i32, ptr %4, align 4
  %389 = mul nsw i32 %387, %388
  %390 = load i32, ptr %29, align 4
  %391 = add nsw i32 %389, %390
  %392 = sext i32 %391 to i64
  %393 = getelementptr inbounds i64, ptr %386, i64 %392
  store i64 %385, ptr %393, align 8
  br label %394

394:                                              ; preds = %375, %365
  br label %395

395:                                              ; preds = %394
  %396 = load i32, ptr %29, align 4
  %397 = add nsw i32 %396, 1
  store i32 %397, ptr %29, align 4
  br label %361, !llvm.loop !23

398:                                              ; preds = %361
  store i32 0, ptr %31, align 4
  br label %399

399:                                              ; preds = %495, %398
  %400 = load i32, ptr %31, align 4
  %401 = load i32, ptr %24, align 4
  %402 = icmp slt i32 %400, %401
  br i1 %402, label %403, label %498

403:                                              ; preds = %399
  store i32 0, ptr %32, align 4
  br label %404

404:                                              ; preds = %491, %403
  %405 = load i32, ptr %32, align 4
  %406 = load i32, ptr %4, align 4
  %407 = icmp slt i32 %405, %406
  br i1 %407, label %408, label %494

408:                                              ; preds = %404
  %409 = load ptr, ptr %25, align 8
  %410 = load i32, ptr %31, align 4
  %411 = load i32, ptr %4, align 4
  %412 = mul nsw i32 %410, %411
  %413 = load i32, ptr %32, align 4
  %414 = add nsw i32 %412, %413
  %415 = sext i32 %414 to i64
  %416 = getelementptr inbounds i64, ptr %409, i64 %415
  %417 = load i64, ptr %416, align 8
  store i64 %417, ptr %33, align 8
  %418 = load i64, ptr %33, align 8
  %419 = icmp sge i64 %418, 4000000000000000000
  br i1 %419, label %420, label %421

420:                                              ; preds = %408
  br label %491

421:                                              ; preds = %408
  store i32 0, ptr %34, align 4
  br label %422

422:                                              ; preds = %487, %421
  %423 = load i32, ptr %34, align 4
  %424 = load i32, ptr %4, align 4
  %425 = icmp slt i32 %423, %424
  br i1 %425, label %426, label %490

426:                                              ; preds = %422
  %427 = load i32, ptr %31, align 4
  %428 = load i32, ptr %34, align 4
  %429 = shl i32 1, %428
  %430 = and i32 %427, %429
  %431 = icmp ne i32 %430, 0
  br i1 %431, label %432, label %433

432:                                              ; preds = %426
  br label %487

433:                                              ; preds = %426
  %434 = load ptr, ptr %18, align 8
  %435 = load i32, ptr %32, align 4
  %436 = add nsw i32 %435, 1
  %437 = sext i32 %436 to i64
  %438 = getelementptr inbounds ptr, ptr %434, i64 %437
  %439 = load ptr, ptr %438, align 8
  %440 = load i32, ptr %34, align 4
  %441 = add nsw i32 %440, 1
  %442 = sext i32 %441 to i64
  %443 = getelementptr inbounds i64, ptr %439, i64 %442
  %444 = load i64, ptr %443, align 8
  store i64 %444, ptr %35, align 8
  %445 = load i64, ptr %35, align 8
  %446 = icmp sge i64 %445, 4000000000000000000
  br i1 %446, label %447, label %448

447:                                              ; preds = %433
  br label %487

448:                                              ; preds = %433
  %449 = load i32, ptr %31, align 4
  %450 = load i32, ptr %34, align 4
  %451 = shl i32 1, %450
  %452 = or i32 %449, %451
  store i32 %452, ptr %36, align 4
  %453 = load i64, ptr %33, align 8
  %454 = load i64, ptr %35, align 8
  %455 = add nsw i64 %453, %454
  store i64 %455, ptr %37, align 8
  %456 = load i64, ptr %37, align 8
  %457 = load ptr, ptr %25, align 8
  %458 = load i32, ptr %36, align 4
  %459 = load i32, ptr %4, align 4
  %460 = mul nsw i32 %458, %459
  %461 = load i32, ptr %34, align 4
  %462 = add nsw i32 %460, %461
  %463 = sext i32 %462 to i64
  %464 = getelementptr inbounds i64, ptr %457, i64 %463
  %465 = load i64, ptr %464, align 8
  %466 = icmp slt i64 %456, %465
  br i1 %466, label %467, label %486

467:                                              ; preds = %448
  %468 = load i64, ptr %37, align 8
  %469 = load ptr, ptr %25, align 8
  %470 = load i32, ptr %36, align 4
  %471 = load i32, ptr %4, align 4
  %472 = mul nsw i32 %470, %471
  %473 = load i32, ptr %34, align 4
  %474 = add nsw i32 %472, %473
  %475 = sext i32 %474 to i64
  %476 = getelementptr inbounds i64, ptr %469, i64 %475
  store i64 %468, ptr %476, align 8
  %477 = load i32, ptr %32, align 4
  %478 = load ptr, ptr %26, align 8
  %479 = load i32, ptr %36, align 4
  %480 = load i32, ptr %4, align 4
  %481 = mul nsw i32 %479, %480
  %482 = load i32, ptr %34, align 4
  %483 = add nsw i32 %481, %482
  %484 = sext i32 %483 to i64
  %485 = getelementptr inbounds i32, ptr %478, i64 %484
  store i32 %477, ptr %485, align 4
  br label %486

486:                                              ; preds = %467, %448
  br label %487

487:                                              ; preds = %486, %447, %432
  %488 = load i32, ptr %34, align 4
  %489 = add nsw i32 %488, 1
  store i32 %489, ptr %34, align 4
  br label %422, !llvm.loop !24

490:                                              ; preds = %422
  br label %491

491:                                              ; preds = %490, %420
  %492 = load i32, ptr %32, align 4
  %493 = add nsw i32 %492, 1
  store i32 %493, ptr %32, align 4
  br label %404, !llvm.loop !25

494:                                              ; preds = %404
  br label %495

495:                                              ; preds = %494
  %496 = load i32, ptr %31, align 4
  %497 = add nsw i32 %496, 1
  store i32 %497, ptr %31, align 4
  br label %399, !llvm.loop !26

498:                                              ; preds = %399
  %499 = load i32, ptr %24, align 4
  %500 = sub nsw i32 %499, 1
  store i32 %500, ptr %38, align 4
  store i64 4000000000000000000, ptr %39, align 8
  store i32 -1, ptr %40, align 4
  store i32 0, ptr %41, align 4
  br label %501

501:                                              ; preds = %551, %498
  %502 = load i32, ptr %41, align 4
  %503 = load i32, ptr %4, align 4
  %504 = icmp slt i32 %502, %503
  br i1 %504, label %505, label %554

505:                                              ; preds = %501
  %506 = load ptr, ptr %25, align 8
  %507 = load i32, ptr %38, align 4
  %508 = load i32, ptr %4, align 4
  %509 = mul nsw i32 %507, %508
  %510 = load i32, ptr %41, align 4
  %511 = add nsw i32 %509, %510
  %512 = sext i32 %511 to i64
  %513 = getelementptr inbounds i64, ptr %506, i64 %512
  %514 = load i64, ptr %513, align 8
  %515 = icmp sge i64 %514, 4000000000000000000
  br i1 %515, label %516, label %517

516:                                              ; preds = %505
  br label %551

517:                                              ; preds = %505
  %518 = load ptr, ptr %18, align 8
  %519 = load i32, ptr %41, align 4
  %520 = add nsw i32 %519, 1
  %521 = sext i32 %520 to i64
  %522 = getelementptr inbounds ptr, ptr %518, i64 %521
  %523 = load ptr, ptr %522, align 8
  %524 = load i32, ptr %4, align 4
  %525 = add nsw i32 %524, 1
  %526 = sext i32 %525 to i64
  %527 = getelementptr inbounds i64, ptr %523, i64 %526
  %528 = load i64, ptr %527, align 8
  store i64 %528, ptr %42, align 8
  %529 = load i64, ptr %42, align 8
  %530 = icmp sge i64 %529, 4000000000000000000
  br i1 %530, label %531, label %532

531:                                              ; preds = %517
  br label %551

532:                                              ; preds = %517
  %533 = load ptr, ptr %25, align 8
  %534 = load i32, ptr %38, align 4
  %535 = load i32, ptr %4, align 4
  %536 = mul nsw i32 %534, %535
  %537 = load i32, ptr %41, align 4
  %538 = add nsw i32 %536, %537
  %539 = sext i32 %538 to i64
  %540 = getelementptr inbounds i64, ptr %533, i64 %539
  %541 = load i64, ptr %540, align 8
  %542 = load i64, ptr %42, align 8
  %543 = add nsw i64 %541, %542
  store i64 %543, ptr %43, align 8
  %544 = load i64, ptr %43, align 8
  %545 = load i64, ptr %39, align 8
  %546 = icmp slt i64 %544, %545
  br i1 %546, label %547, label %550

547:                                              ; preds = %532
  %548 = load i64, ptr %43, align 8
  store i64 %548, ptr %39, align 8
  %549 = load i32, ptr %41, align 4
  store i32 %549, ptr %40, align 4
  br label %550

550:                                              ; preds = %547, %532
  br label %551

551:                                              ; preds = %550, %531, %516
  %552 = load i32, ptr %41, align 4
  %553 = add nsw i32 %552, 1
  store i32 %553, ptr %41, align 4
  br label %501, !llvm.loop !27

554:                                              ; preds = %501
  %555 = load i64, ptr %39, align 8
  %556 = icmp sge i64 %555, 4000000000000000000
  br i1 %556, label %560, label %557

557:                                              ; preds = %554
  %558 = load i32, ptr %40, align 4
  %559 = icmp eq i32 %558, -1
  br i1 %559, label %560, label %562

560:                                              ; preds = %557, %554
  %561 = call i32 (ptr, ...) @printf(ptr noundef @.str.3)
  br label %733

562:                                              ; preds = %557
  %563 = load i32, ptr %4, align 4
  %564 = sext i32 %563 to i64
  %565 = mul i64 4, %564
  %566 = call noalias ptr @malloc(i64 noundef %565) #6
  store ptr %566, ptr %44, align 8
  store i32 0, ptr %45, align 4
  %567 = load i32, ptr %38, align 4
  store i32 %567, ptr %46, align 4
  %568 = load i32, ptr %40, align 4
  store i32 %568, ptr %47, align 4
  br label %569

569:                                              ; preds = %572, %562
  %570 = load i32, ptr %47, align 4
  %571 = icmp ne i32 %570, -1
  br i1 %571, label %572, label %593

572:                                              ; preds = %569
  %573 = load i32, ptr %47, align 4
  %574 = load ptr, ptr %44, align 8
  %575 = load i32, ptr %45, align 4
  %576 = add nsw i32 %575, 1
  store i32 %576, ptr %45, align 4
  %577 = sext i32 %575 to i64
  %578 = getelementptr inbounds i32, ptr %574, i64 %577
  store i32 %573, ptr %578, align 4
  %579 = load ptr, ptr %26, align 8
  %580 = load i32, ptr %46, align 4
  %581 = load i32, ptr %4, align 4
  %582 = mul nsw i32 %580, %581
  %583 = load i32, ptr %47, align 4
  %584 = add nsw i32 %582, %583
  %585 = sext i32 %584 to i64
  %586 = getelementptr inbounds i32, ptr %579, i64 %585
  %587 = load i32, ptr %586, align 4
  store i32 %587, ptr %48, align 4
  %588 = load i32, ptr %47, align 4
  %589 = shl i32 1, %588
  %590 = load i32, ptr %46, align 4
  %591 = xor i32 %590, %589
  store i32 %591, ptr %46, align 4
  %592 = load i32, ptr %48, align 4
  store i32 %592, ptr %47, align 4
  br label %569, !llvm.loop !28

593:                                              ; preds = %569
  store i32 0, ptr %49, align 4
  br label %594

594:                                              ; preds = %625, %593
  %595 = load i32, ptr %49, align 4
  %596 = load i32, ptr %45, align 4
  %597 = sdiv i32 %596, 2
  %598 = icmp slt i32 %595, %597
  br i1 %598, label %599, label %628

599:                                              ; preds = %594
  %600 = load ptr, ptr %44, align 8
  %601 = load i32, ptr %49, align 4
  %602 = sext i32 %601 to i64
  %603 = getelementptr inbounds i32, ptr %600, i64 %602
  %604 = load i32, ptr %603, align 4
  store i32 %604, ptr %50, align 4
  %605 = load ptr, ptr %44, align 8
  %606 = load i32, ptr %45, align 4
  %607 = sub nsw i32 %606, 1
  %608 = load i32, ptr %49, align 4
  %609 = sub nsw i32 %607, %608
  %610 = sext i32 %609 to i64
  %611 = getelementptr inbounds i32, ptr %605, i64 %610
  %612 = load i32, ptr %611, align 4
  %613 = load ptr, ptr %44, align 8
  %614 = load i32, ptr %49, align 4
  %615 = sext i32 %614 to i64
  %616 = getelementptr inbounds i32, ptr %613, i64 %615
  store i32 %612, ptr %616, align 4
  %617 = load i32, ptr %50, align 4
  %618 = load ptr, ptr %44, align 8
  %619 = load i32, ptr %45, align 4
  %620 = sub nsw i32 %619, 1
  %621 = load i32, ptr %49, align 4
  %622 = sub nsw i32 %620, %621
  %623 = sext i32 %622 to i64
  %624 = getelementptr inbounds i32, ptr %618, i64 %623
  store i32 %617, ptr %624, align 4
  br label %625

625:                                              ; preds = %599
  %626 = load i32, ptr %49, align 4
  %627 = add nsw i32 %626, 1
  store i32 %627, ptr %49, align 4
  br label %594, !llvm.loop !29

628:                                              ; preds = %594
  %629 = load i64, ptr %39, align 8
  %630 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i64 noundef %629)
  %631 = call i32 (ptr, ...) @printf(ptr noundef @.str.9)
  store i32 0, ptr %51, align 4
  br label %632

632:                                              ; preds = %652, %628
  %633 = load i32, ptr %51, align 4
  %634 = load i32, ptr %45, align 4
  %635 = icmp slt i32 %633, %634
  br i1 %635, label %636, label %655

636:                                              ; preds = %632
  %637 = load i32, ptr %51, align 4
  %638 = icmp ne i32 %637, 0
  br i1 %638, label %639, label %641

639:                                              ; preds = %636
  %640 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  br label %641

641:                                              ; preds = %639, %636
  %642 = load ptr, ptr %5, align 8
  %643 = load ptr, ptr %44, align 8
  %644 = load i32, ptr %51, align 4
  %645 = sext i32 %644 to i64
  %646 = getelementptr inbounds i32, ptr %643, i64 %645
  %647 = load i32, ptr %646, align 4
  %648 = sext i32 %647 to i64
  %649 = getelementptr inbounds i32, ptr %642, i64 %648
  %650 = load i32, ptr %649, align 4
  %651 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %650)
  br label %652

652:                                              ; preds = %641
  %653 = load i32, ptr %51, align 4
  %654 = add nsw i32 %653, 1
  store i32 %654, ptr %51, align 4
  br label %632, !llvm.loop !30

655:                                              ; preds = %632
  %656 = call i32 (ptr, ...) @printf(ptr noundef @.str.8)
  %657 = load i32, ptr @N, align 4
  %658 = load i32, ptr %4, align 4
  %659 = add nsw i32 %658, 2
  %660 = mul nsw i32 %657, %659
  %661 = add nsw i32 %660, 10
  %662 = sext i32 %661 to i64
  %663 = mul i64 4, %662
  %664 = call noalias ptr @malloc(i64 noundef %663) #6
  store ptr %664, ptr %52, align 8
  store i32 0, ptr %53, align 4
  store i32 0, ptr %54, align 4
  store i32 0, ptr %55, align 4
  br label %665

665:                                              ; preds = %693, %655
  %666 = load i32, ptr %55, align 4
  %667 = load i32, ptr %45, align 4
  %668 = icmp slt i32 %666, %667
  br i1 %668, label %669, label %696

669:                                              ; preds = %665
  %670 = load ptr, ptr %44, align 8
  %671 = load i32, ptr %55, align 4
  %672 = sext i32 %671 to i64
  %673 = getelementptr inbounds i32, ptr %670, i64 %672
  %674 = load i32, ptr %673, align 4
  %675 = add nsw i32 %674, 1
  store i32 %675, ptr %56, align 4
  %676 = load ptr, ptr %13, align 8
  %677 = load i32, ptr %54, align 4
  %678 = sext i32 %677 to i64
  %679 = getelementptr inbounds i32, ptr %676, i64 %678
  %680 = load i32, ptr %679, align 4
  %681 = load ptr, ptr %13, align 8
  %682 = load i32, ptr %56, align 4
  %683 = sext i32 %682 to i64
  %684 = getelementptr inbounds i32, ptr %681, i64 %683
  %685 = load i32, ptr %684, align 4
  %686 = load ptr, ptr %16, align 8
  %687 = load i32, ptr %54, align 4
  %688 = sext i32 %687 to i64
  %689 = getelementptr inbounds ptr, ptr %686, i64 %688
  %690 = load ptr, ptr %689, align 8
  %691 = load ptr, ptr %52, align 8
  call void @appendSegment(i32 noundef %680, i32 noundef %685, ptr noundef %690, ptr noundef %691, ptr noundef %53)
  %692 = load i32, ptr %56, align 4
  store i32 %692, ptr %54, align 4
  br label %693

693:                                              ; preds = %669
  %694 = load i32, ptr %55, align 4
  %695 = add nsw i32 %694, 1
  store i32 %695, ptr %55, align 4
  br label %665, !llvm.loop !31

696:                                              ; preds = %665
  %697 = load ptr, ptr %13, align 8
  %698 = load i32, ptr %54, align 4
  %699 = sext i32 %698 to i64
  %700 = getelementptr inbounds i32, ptr %697, i64 %699
  %701 = load i32, ptr %700, align 4
  %702 = load i32, ptr %3, align 4
  %703 = load ptr, ptr %16, align 8
  %704 = load i32, ptr %54, align 4
  %705 = sext i32 %704 to i64
  %706 = getelementptr inbounds ptr, ptr %703, i64 %705
  %707 = load ptr, ptr %706, align 8
  %708 = load ptr, ptr %52, align 8
  call void @appendSegment(i32 noundef %701, i32 noundef %702, ptr noundef %707, ptr noundef %708, ptr noundef %53)
  %709 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  store i32 0, ptr %57, align 4
  br label %710

710:                                              ; preds = %726, %696
  %711 = load i32, ptr %57, align 4
  %712 = load i32, ptr %53, align 4
  %713 = icmp slt i32 %711, %712
  br i1 %713, label %714, label %729

714:                                              ; preds = %710
  %715 = load i32, ptr %57, align 4
  %716 = icmp ne i32 %715, 0
  br i1 %716, label %717, label %719

717:                                              ; preds = %714
  %718 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  br label %719

719:                                              ; preds = %717, %714
  %720 = load ptr, ptr %52, align 8
  %721 = load i32, ptr %57, align 4
  %722 = sext i32 %721 to i64
  %723 = getelementptr inbounds i32, ptr %720, i64 %722
  %724 = load i32, ptr %723, align 4
  %725 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef %724)
  br label %726

726:                                              ; preds = %719
  %727 = load i32, ptr %57, align 4
  %728 = add nsw i32 %727, 1
  store i32 %728, ptr %57, align 4
  br label %710, !llvm.loop !32

729:                                              ; preds = %710
  %730 = call i32 (ptr, ...) @printf(ptr noundef @.str.8)
  %731 = load ptr, ptr %44, align 8
  call void @free(ptr noundef %731) #8
  %732 = load ptr, ptr %52, align 8
  call void @free(ptr noundef %732) #8
  br label %733

733:                                              ; preds = %729, %560
  store i32 0, ptr %58, align 4
  br label %734

734:                                              ; preds = %754, %733
  %735 = load i32, ptr %58, align 4
  %736 = load i32, ptr %12, align 4
  %737 = icmp slt i32 %735, %736
  br i1 %737, label %738, label %757

738:                                              ; preds = %734
  %739 = load ptr, ptr %15, align 8
  %740 = load i32, ptr %58, align 4
  %741 = sext i32 %740 to i64
  %742 = getelementptr inbounds ptr, ptr %739, i64 %741
  %743 = load ptr, ptr %742, align 8
  call void @free(ptr noundef %743) #8
  %744 = load ptr, ptr %16, align 8
  %745 = load i32, ptr %58, align 4
  %746 = sext i32 %745 to i64
  %747 = getelementptr inbounds ptr, ptr %744, i64 %746
  %748 = load ptr, ptr %747, align 8
  call void @free(ptr noundef %748) #8
  %749 = load ptr, ptr %18, align 8
  %750 = load i32, ptr %58, align 4
  %751 = sext i32 %750 to i64
  %752 = getelementptr inbounds ptr, ptr %749, i64 %751
  %753 = load ptr, ptr %752, align 8
  call void @free(ptr noundef %753) #8
  br label %754

754:                                              ; preds = %738
  %755 = load i32, ptr %58, align 4
  %756 = add nsw i32 %755, 1
  store i32 %756, ptr %58, align 4
  br label %734, !llvm.loop !33

757:                                              ; preds = %734
  %758 = load ptr, ptr %15, align 8
  call void @free(ptr noundef %758) #8
  %759 = load ptr, ptr %16, align 8
  call void @free(ptr noundef %759) #8
  %760 = load ptr, ptr %18, align 8
  call void @free(ptr noundef %760) #8
  %761 = load ptr, ptr %25, align 8
  call void @free(ptr noundef %761) #8
  %762 = load ptr, ptr %26, align 8
  call void @free(ptr noundef %762) #8
  %763 = load ptr, ptr %13, align 8
  call void @free(ptr noundef %763) #8
  %764 = load ptr, ptr %5, align 8
  call void @free(ptr noundef %764) #8
  %765 = load ptr, ptr @head, align 8
  call void @free(ptr noundef %765) #8
  %766 = load ptr, ptr @edges, align 8
  call void @free(ptr noundef %766) #8
  store i32 0, ptr %1, align 4
  br label %767

767:                                              ; preds = %757, %309
  %768 = load i32, ptr %1, align 4
  ret i32 %768
}

declare i32 @__isoc99_scanf(ptr noundef, ...) #5

declare i32 @printf(ptr noundef, ...) #5

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

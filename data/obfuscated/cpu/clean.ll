; ModuleID = 'data/obfuscated/cpu/clean.bc'
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

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @maxInt(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = icmp sgt i32 %5, %6
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = load i32, ptr %3, align 4
  br label %12

10:                                               ; preds = %2
  %11 = load i32, ptr %4, align 4
  br label %12

12:                                               ; preds = %10, %8
  %13 = phi i32 [ %9, %8 ], [ %11, %10 ]
  ret i32 %13
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
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 %2, ptr %7, align 4
  store i32 %3, ptr %8, align 4
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %7, align 4
  %12 = icmp sle i32 %10, %11
  br i1 %12, label %13, label %14

13:                                               ; preds = %4
  br label %104

14:                                               ; preds = %4
  %15 = load ptr, ptr %5, align 8
  %16 = getelementptr inbounds nuw %struct.SegmentList, ptr %15, i32 0, i32 1
  %17 = load i32, ptr %16, align 8
  %18 = icmp sgt i32 %17, 0
  br i1 %18, label %19, label %45

19:                                               ; preds = %14
  %20 = load ptr, ptr %5, align 8
  %21 = getelementptr inbounds nuw %struct.SegmentList, ptr %20, i32 0, i32 0
  %22 = load ptr, ptr %21, align 8
  %23 = load ptr, ptr %5, align 8
  %24 = getelementptr inbounds nuw %struct.SegmentList, ptr %23, i32 0, i32 1
  %25 = load i32, ptr %24, align 8
  %26 = sub nsw i32 %25, 1
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds %struct.Segment, ptr %22, i64 %27
  store ptr %28, ptr %9, align 8
  %29 = load ptr, ptr %9, align 8
  %30 = getelementptr inbounds nuw %struct.Segment, ptr %29, i32 0, i32 0
  %31 = load i32, ptr %30, align 4
  %32 = load i32, ptr %6, align 4
  %33 = icmp eq i32 %31, %32
  br i1 %33, label %34, label %44

34:                                               ; preds = %19
  %35 = load ptr, ptr %9, align 8
  %36 = getelementptr inbounds nuw %struct.Segment, ptr %35, i32 0, i32 2
  %37 = load i32, ptr %36, align 4
  %38 = load i32, ptr %7, align 4
  %39 = icmp eq i32 %37, %38
  br i1 %39, label %40, label %44

40:                                               ; preds = %34
  %41 = load i32, ptr %8, align 4
  %42 = load ptr, ptr %9, align 8
  %43 = getelementptr inbounds nuw %struct.Segment, ptr %42, i32 0, i32 2
  store i32 %41, ptr %43, align 4
  br label %104

44:                                               ; preds = %34, %19
  br label %45

45:                                               ; preds = %44, %14
  %46 = load ptr, ptr %5, align 8
  %47 = getelementptr inbounds nuw %struct.SegmentList, ptr %46, i32 0, i32 1
  %48 = load i32, ptr %47, align 8
  %49 = load ptr, ptr %5, align 8
  %50 = getelementptr inbounds nuw %struct.SegmentList, ptr %49, i32 0, i32 2
  %51 = load i32, ptr %50, align 4
  %52 = icmp sge i32 %48, %51
  br i1 %52, label %53, label %69

53:                                               ; preds = %45
  %54 = load ptr, ptr %5, align 8
  %55 = getelementptr inbounds nuw %struct.SegmentList, ptr %54, i32 0, i32 2
  %56 = load i32, ptr %55, align 4
  %57 = mul nsw i32 %56, 2
  store i32 %57, ptr %55, align 4
  %58 = load ptr, ptr %5, align 8
  %59 = getelementptr inbounds nuw %struct.SegmentList, ptr %58, i32 0, i32 0
  %60 = load ptr, ptr %59, align 8
  %61 = load ptr, ptr %5, align 8
  %62 = getelementptr inbounds nuw %struct.SegmentList, ptr %61, i32 0, i32 2
  %63 = load i32, ptr %62, align 4
  %64 = sext i32 %63 to i64
  %65 = mul i64 12, %64
  %66 = call ptr @realloc(ptr noundef %60, i64 noundef %65) #7
  %67 = load ptr, ptr %5, align 8
  %68 = getelementptr inbounds nuw %struct.SegmentList, ptr %67, i32 0, i32 0
  store ptr %66, ptr %68, align 8
  br label %69

69:                                               ; preds = %53, %45
  %70 = load i32, ptr %6, align 4
  %71 = load ptr, ptr %5, align 8
  %72 = getelementptr inbounds nuw %struct.SegmentList, ptr %71, i32 0, i32 0
  %73 = load ptr, ptr %72, align 8
  %74 = load ptr, ptr %5, align 8
  %75 = getelementptr inbounds nuw %struct.SegmentList, ptr %74, i32 0, i32 1
  %76 = load i32, ptr %75, align 8
  %77 = sext i32 %76 to i64
  %78 = getelementptr inbounds %struct.Segment, ptr %73, i64 %77
  %79 = getelementptr inbounds nuw %struct.Segment, ptr %78, i32 0, i32 0
  store i32 %70, ptr %79, align 4
  %80 = load i32, ptr %7, align 4
  %81 = load ptr, ptr %5, align 8
  %82 = getelementptr inbounds nuw %struct.SegmentList, ptr %81, i32 0, i32 0
  %83 = load ptr, ptr %82, align 8
  %84 = load ptr, ptr %5, align 8
  %85 = getelementptr inbounds nuw %struct.SegmentList, ptr %84, i32 0, i32 1
  %86 = load i32, ptr %85, align 8
  %87 = sext i32 %86 to i64
  %88 = getelementptr inbounds %struct.Segment, ptr %83, i64 %87
  %89 = getelementptr inbounds nuw %struct.Segment, ptr %88, i32 0, i32 1
  store i32 %80, ptr %89, align 4
  %90 = load i32, ptr %8, align 4
  %91 = load ptr, ptr %5, align 8
  %92 = getelementptr inbounds nuw %struct.SegmentList, ptr %91, i32 0, i32 0
  %93 = load ptr, ptr %92, align 8
  %94 = load ptr, ptr %5, align 8
  %95 = getelementptr inbounds nuw %struct.SegmentList, ptr %94, i32 0, i32 1
  %96 = load i32, ptr %95, align 8
  %97 = sext i32 %96 to i64
  %98 = getelementptr inbounds %struct.Segment, ptr %93, i64 %97
  %99 = getelementptr inbounds nuw %struct.Segment, ptr %98, i32 0, i32 2
  store i32 %90, ptr %99, align 4
  %100 = load ptr, ptr %5, align 8
  %101 = getelementptr inbounds nuw %struct.SegmentList, ptr %100, i32 0, i32 1
  %102 = load i32, ptr %101, align 8
  %103 = add nsw i32 %102, 1
  store i32 %103, ptr %101, align 8
  br label %104

104:                                              ; preds = %69, %40, %13
  ret void
}

; Function Attrs: nounwind allocsize(1)
declare ptr @realloc(ptr noundef, i64 noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @generateProcesses(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  br label %10

10:                                               ; preds = %97, %2
  %11 = load i32, ptr %5, align 4
  %12 = load i32, ptr %4, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %100

14:                                               ; preds = %10
  %15 = load i32, ptr %5, align 4
  %16 = load i32, ptr %5, align 4
  %17 = mul nsw i32 %15, %16
  %18 = load i32, ptr %5, align 4
  %19 = mul nsw i32 3, %18
  %20 = add nsw i32 %17, %19
  %21 = load i32, ptr %4, align 4
  %22 = add nsw i32 %21, 4
  %23 = srem i32 %20, %22
  store i32 %23, ptr %6, align 4
  %24 = load i32, ptr %5, align 4
  %25 = add nsw i32 %24, 2
  %26 = mul nsw i32 %25, 7
  %27 = srem i32 %26, 9
  %28 = add nsw i32 %27, 2
  store i32 %28, ptr %7, align 4
  %29 = load i32, ptr %5, align 4
  %30 = mul nsw i32 %29, 3
  %31 = load i32, ptr %4, align 4
  %32 = add nsw i32 %30, %31
  %33 = srem i32 %32, 5
  %34 = add nsw i32 %33, 1
  store i32 %34, ptr %8, align 4
  %35 = load i32, ptr %6, align 4
  %36 = load i32, ptr %7, align 4
  %37 = add nsw i32 %35, %36
  %38 = load i32, ptr %5, align 4
  %39 = mul nsw i32 %38, 4
  %40 = load i32, ptr %4, align 4
  %41 = add nsw i32 %39, %40
  %42 = srem i32 %41, 7
  %43 = add nsw i32 %37, %42
  %44 = add nsw i32 %43, 3
  store i32 %44, ptr %9, align 4
  %45 = load i32, ptr %5, align 4
  %46 = add nsw i32 %45, 1
  %47 = load ptr, ptr %3, align 8
  %48 = load i32, ptr %5, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds %struct.Process, ptr %47, i64 %49
  %51 = getelementptr inbounds nuw %struct.Process, ptr %50, i32 0, i32 0
  store i32 %46, ptr %51, align 4
  %52 = load i32, ptr %6, align 4
  %53 = load ptr, ptr %3, align 8
  %54 = load i32, ptr %5, align 4
  %55 = sext i32 %54 to i64
  %56 = getelementptr inbounds %struct.Process, ptr %53, i64 %55
  %57 = getelementptr inbounds nuw %struct.Process, ptr %56, i32 0, i32 1
  store i32 %52, ptr %57, align 4
  %58 = load i32, ptr %7, align 4
  %59 = load ptr, ptr %3, align 8
  %60 = load i32, ptr %5, align 4
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds %struct.Process, ptr %59, i64 %61
  %63 = getelementptr inbounds nuw %struct.Process, ptr %62, i32 0, i32 2
  store i32 %58, ptr %63, align 4
  %64 = load i32, ptr %7, align 4
  %65 = load ptr, ptr %3, align 8
  %66 = load i32, ptr %5, align 4
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds %struct.Process, ptr %65, i64 %67
  %69 = getelementptr inbounds nuw %struct.Process, ptr %68, i32 0, i32 3
  store i32 %64, ptr %69, align 4
  %70 = load ptr, ptr %3, align 8
  %71 = load i32, ptr %5, align 4
  %72 = sext i32 %71 to i64
  %73 = getelementptr inbounds %struct.Process, ptr %70, i64 %72
  %74 = getelementptr inbounds nuw %struct.Process, ptr %73, i32 0, i32 4
  store i32 0, ptr %74, align 4
  %75 = load i32, ptr %8, align 4
  %76 = load ptr, ptr %3, align 8
  %77 = load i32, ptr %5, align 4
  %78 = sext i32 %77 to i64
  %79 = getelementptr inbounds %struct.Process, ptr %76, i64 %78
  %80 = getelementptr inbounds nuw %struct.Process, ptr %79, i32 0, i32 5
  store i32 %75, ptr %80, align 4
  %81 = load i32, ptr %9, align 4
  %82 = load ptr, ptr %3, align 8
  %83 = load i32, ptr %5, align 4
  %84 = sext i32 %83 to i64
  %85 = getelementptr inbounds %struct.Process, ptr %82, i64 %84
  %86 = getelementptr inbounds nuw %struct.Process, ptr %85, i32 0, i32 6
  store i32 %81, ptr %86, align 4
  %87 = load ptr, ptr %3, align 8
  %88 = load i32, ptr %5, align 4
  %89 = sext i32 %88 to i64
  %90 = getelementptr inbounds %struct.Process, ptr %87, i64 %89
  %91 = getelementptr inbounds nuw %struct.Process, ptr %90, i32 0, i32 7
  store i32 -1, ptr %91, align 4
  %92 = load ptr, ptr %3, align 8
  %93 = load i32, ptr %5, align 4
  %94 = sext i32 %93 to i64
  %95 = getelementptr inbounds %struct.Process, ptr %92, i64 %94
  %96 = getelementptr inbounds nuw %struct.Process, ptr %95, i32 0, i32 8
  store i32 -1, ptr %96, align 4
  br label %97

97:                                               ; preds = %14
  %98 = load i32, ptr %5, align 4
  %99 = add nsw i32 %98, 1
  store i32 %99, ptr %5, align 4
  br label %10, !llvm.loop !6

100:                                              ; preds = %10
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @effectivePriority(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %7 = load i32, ptr %4, align 4
  %8 = load ptr, ptr %3, align 8
  %9 = getelementptr inbounds nuw %struct.Process, ptr %8, i32 0, i32 1
  %10 = load i32, ptr %9, align 4
  %11 = sub nsw i32 %7, %10
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.Process, ptr %12, i32 0, i32 4
  %14 = load i32, ptr %13, align 4
  %15 = sub nsw i32 %11, %14
  store i32 %15, ptr %5, align 4
  %16 = load ptr, ptr %3, align 8
  %17 = getelementptr inbounds nuw %struct.Process, ptr %16, i32 0, i32 5
  %18 = load i32, ptr %17, align 4
  %19 = load i32, ptr %5, align 4
  %20 = sdiv i32 %19, 4
  %21 = sub nsw i32 %18, %20
  store i32 %21, ptr %6, align 4
  %22 = load i32, ptr %6, align 4
  %23 = icmp slt i32 %22, 0
  br i1 %23, label %24, label %25

24:                                               ; preds = %2
  store i32 0, ptr %6, align 4
  br label %25

25:                                               ; preds = %24, %2
  %26 = load i32, ptr %6, align 4
  ret i32 %26
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
  %9 = sub nsw i32 %7, %8
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds nuw %struct.Process, ptr %10, i32 0, i32 3
  %12 = load i32, ptr %11, align 4
  %13 = sub nsw i32 %9, %12
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @isBetter(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store i32 %2, ptr %7, align 4
  %12 = load ptr, ptr %5, align 8
  %13 = load i32, ptr %7, align 4
  %14 = call i32 @effectivePriority(ptr noundef %12, i32 noundef %13)
  store i32 %14, ptr %8, align 4
  %15 = load ptr, ptr %6, align 8
  %16 = load i32, ptr %7, align 4
  %17 = call i32 @effectivePriority(ptr noundef %15, i32 noundef %16)
  store i32 %17, ptr %9, align 4
  %18 = load i32, ptr %8, align 4
  %19 = load i32, ptr %9, align 4
  %20 = icmp ne i32 %18, %19
  br i1 %20, label %21, label %26

21:                                               ; preds = %3
  %22 = load i32, ptr %8, align 4
  %23 = load i32, ptr %9, align 4
  %24 = icmp slt i32 %22, %23
  %25 = zext i1 %24 to i32
  store i32 %25, ptr %4, align 4
  br label %84

26:                                               ; preds = %3
  %27 = load ptr, ptr %5, align 8
  %28 = load i32, ptr %7, align 4
  %29 = call i32 @slackTime(ptr noundef %27, i32 noundef %28)
  store i32 %29, ptr %10, align 4
  %30 = load ptr, ptr %6, align 8
  %31 = load i32, ptr %7, align 4
  %32 = call i32 @slackTime(ptr noundef %30, i32 noundef %31)
  store i32 %32, ptr %11, align 4
  %33 = load i32, ptr %10, align 4
  %34 = load i32, ptr %11, align 4
  %35 = icmp ne i32 %33, %34
  br i1 %35, label %36, label %41

36:                                               ; preds = %26
  %37 = load i32, ptr %10, align 4
  %38 = load i32, ptr %11, align 4
  %39 = icmp slt i32 %37, %38
  %40 = zext i1 %39 to i32
  store i32 %40, ptr %4, align 4
  br label %84

41:                                               ; preds = %26
  %42 = load ptr, ptr %5, align 8
  %43 = getelementptr inbounds nuw %struct.Process, ptr %42, i32 0, i32 3
  %44 = load i32, ptr %43, align 4
  %45 = load ptr, ptr %6, align 8
  %46 = getelementptr inbounds nuw %struct.Process, ptr %45, i32 0, i32 3
  %47 = load i32, ptr %46, align 4
  %48 = icmp ne i32 %44, %47
  br i1 %48, label %49, label %58

49:                                               ; preds = %41
  %50 = load ptr, ptr %5, align 8
  %51 = getelementptr inbounds nuw %struct.Process, ptr %50, i32 0, i32 3
  %52 = load i32, ptr %51, align 4
  %53 = load ptr, ptr %6, align 8
  %54 = getelementptr inbounds nuw %struct.Process, ptr %53, i32 0, i32 3
  %55 = load i32, ptr %54, align 4
  %56 = icmp slt i32 %52, %55
  %57 = zext i1 %56 to i32
  store i32 %57, ptr %4, align 4
  br label %84

58:                                               ; preds = %41
  %59 = load ptr, ptr %5, align 8
  %60 = getelementptr inbounds nuw %struct.Process, ptr %59, i32 0, i32 1
  %61 = load i32, ptr %60, align 4
  %62 = load ptr, ptr %6, align 8
  %63 = getelementptr inbounds nuw %struct.Process, ptr %62, i32 0, i32 1
  %64 = load i32, ptr %63, align 4
  %65 = icmp ne i32 %61, %64
  br i1 %65, label %66, label %75

66:                                               ; preds = %58
  %67 = load ptr, ptr %5, align 8
  %68 = getelementptr inbounds nuw %struct.Process, ptr %67, i32 0, i32 1
  %69 = load i32, ptr %68, align 4
  %70 = load ptr, ptr %6, align 8
  %71 = getelementptr inbounds nuw %struct.Process, ptr %70, i32 0, i32 1
  %72 = load i32, ptr %71, align 4
  %73 = icmp slt i32 %69, %72
  %74 = zext i1 %73 to i32
  store i32 %74, ptr %4, align 4
  br label %84

75:                                               ; preds = %58
  %76 = load ptr, ptr %5, align 8
  %77 = getelementptr inbounds nuw %struct.Process, ptr %76, i32 0, i32 0
  %78 = load i32, ptr %77, align 4
  %79 = load ptr, ptr %6, align 8
  %80 = getelementptr inbounds nuw %struct.Process, ptr %79, i32 0, i32 0
  %81 = load i32, ptr %80, align 4
  %82 = icmp slt i32 %78, %81
  %83 = zext i1 %82 to i32
  store i32 %83, ptr %4, align 4
  br label %84

84:                                               ; preds = %75, %66, %49, %36, %21
  %85 = load i32, ptr %4, align 4
  ret i32 %85
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @chooseProcess(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  store i32 -1, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %49, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %5, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %52

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds %struct.Process, ptr %14, i64 %16
  %18 = getelementptr inbounds nuw %struct.Process, ptr %17, i32 0, i32 1
  %19 = load i32, ptr %18, align 4
  %20 = load i32, ptr %6, align 4
  %21 = icmp sle i32 %19, %20
  br i1 %21, label %22, label %48

22:                                               ; preds = %13
  %23 = load ptr, ptr %4, align 8
  %24 = load i32, ptr %8, align 4
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds %struct.Process, ptr %23, i64 %25
  %27 = getelementptr inbounds nuw %struct.Process, ptr %26, i32 0, i32 3
  %28 = load i32, ptr %27, align 4
  %29 = icmp sgt i32 %28, 0
  br i1 %29, label %30, label %48

30:                                               ; preds = %22
  %31 = load i32, ptr %7, align 4
  %32 = icmp eq i32 %31, -1
  br i1 %32, label %45, label %33

33:                                               ; preds = %30
  %34 = load ptr, ptr %4, align 8
  %35 = load i32, ptr %8, align 4
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds %struct.Process, ptr %34, i64 %36
  %38 = load ptr, ptr %4, align 8
  %39 = load i32, ptr %7, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds %struct.Process, ptr %38, i64 %40
  %42 = load i32, ptr %6, align 4
  %43 = call i32 @isBetter(ptr noundef %37, ptr noundef %41, i32 noundef %42)
  %44 = icmp ne i32 %43, 0
  br i1 %44, label %45, label %47

45:                                               ; preds = %33, %30
  %46 = load i32, ptr %8, align 4
  store i32 %46, ptr %7, align 4
  br label %47

47:                                               ; preds = %45, %33
  br label %48

48:                                               ; preds = %47, %22, %13
  br label %49

49:                                               ; preds = %48
  %50 = load i32, ptr %8, align 4
  %51 = add nsw i32 %50, 1
  store i32 %51, ptr %8, align 4
  br label %9, !llvm.loop !8

52:                                               ; preds = %9
  %53 = load i32, ptr %7, align 4
  ret i32 %53
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @nextArrival(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  store i32 1000000000, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %47, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %5, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %50

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds %struct.Process, ptr %14, i64 %16
  %18 = getelementptr inbounds nuw %struct.Process, ptr %17, i32 0, i32 3
  %19 = load i32, ptr %18, align 4
  %20 = icmp sgt i32 %19, 0
  br i1 %20, label %21, label %46

21:                                               ; preds = %13
  %22 = load ptr, ptr %4, align 8
  %23 = load i32, ptr %8, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds %struct.Process, ptr %22, i64 %24
  %26 = getelementptr inbounds nuw %struct.Process, ptr %25, i32 0, i32 1
  %27 = load i32, ptr %26, align 4
  %28 = load i32, ptr %6, align 4
  %29 = icmp sgt i32 %27, %28
  br i1 %29, label %30, label %46

30:                                               ; preds = %21
  %31 = load ptr, ptr %4, align 8
  %32 = load i32, ptr %8, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds %struct.Process, ptr %31, i64 %33
  %35 = getelementptr inbounds nuw %struct.Process, ptr %34, i32 0, i32 1
  %36 = load i32, ptr %35, align 4
  %37 = load i32, ptr %7, align 4
  %38 = icmp slt i32 %36, %37
  br i1 %38, label %39, label %46

39:                                               ; preds = %30
  %40 = load ptr, ptr %4, align 8
  %41 = load i32, ptr %8, align 4
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds %struct.Process, ptr %40, i64 %42
  %44 = getelementptr inbounds nuw %struct.Process, ptr %43, i32 0, i32 1
  %45 = load i32, ptr %44, align 4
  store i32 %45, ptr %7, align 4
  br label %46

46:                                               ; preds = %39, %30, %21, %13
  br label %47

47:                                               ; preds = %46
  %48 = load i32, ptr %8, align 4
  %49 = add nsw i32 %48, 1
  store i32 %49, ptr %8, align 4
  br label %9, !llvm.loop !9

50:                                               ; preds = %9
  %51 = load i32, ptr %7, align 4
  ret i32 %51
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @simulate(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store ptr %2, ptr %6, align 8
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %11

11:                                               ; preds = %89, %22, %3
  %12 = load i32, ptr %7, align 4
  %13 = load i32, ptr %5, align 4
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %15, label %90

15:                                               ; preds = %11
  %16 = load ptr, ptr %4, align 8
  %17 = load i32, ptr %5, align 4
  %18 = load i32, ptr %8, align 4
  %19 = call i32 @chooseProcess(ptr noundef %16, i32 noundef %17, i32 noundef %18)
  store i32 %19, ptr %9, align 4
  %20 = load i32, ptr %9, align 4
  %21 = icmp eq i32 %20, -1
  br i1 %21, label %22, label %31

22:                                               ; preds = %15
  %23 = load ptr, ptr %4, align 8
  %24 = load i32, ptr %5, align 4
  %25 = load i32, ptr %8, align 4
  %26 = call i32 @nextArrival(ptr noundef %23, i32 noundef %24, i32 noundef %25)
  store i32 %26, ptr %10, align 4
  %27 = load ptr, ptr %6, align 8
  %28 = load i32, ptr %8, align 4
  %29 = load i32, ptr %10, align 4
  call void @addSegment(ptr noundef %27, i32 noundef 0, i32 noundef %28, i32 noundef %29)
  %30 = load i32, ptr %10, align 4
  store i32 %30, ptr %8, align 4
  br label %11, !llvm.loop !10

31:                                               ; preds = %15
  %32 = load ptr, ptr %4, align 8
  %33 = load i32, ptr %9, align 4
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds %struct.Process, ptr %32, i64 %34
  %36 = getelementptr inbounds nuw %struct.Process, ptr %35, i32 0, i32 7
  %37 = load i32, ptr %36, align 4
  %38 = icmp eq i32 %37, -1
  br i1 %38, label %39, label %46

39:                                               ; preds = %31
  %40 = load i32, ptr %8, align 4
  %41 = load ptr, ptr %4, align 8
  %42 = load i32, ptr %9, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds %struct.Process, ptr %41, i64 %43
  %45 = getelementptr inbounds nuw %struct.Process, ptr %44, i32 0, i32 7
  store i32 %40, ptr %45, align 4
  br label %46

46:                                               ; preds = %39, %31
  %47 = load ptr, ptr %6, align 8
  %48 = load ptr, ptr %4, align 8
  %49 = load i32, ptr %9, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds %struct.Process, ptr %48, i64 %50
  %52 = getelementptr inbounds nuw %struct.Process, ptr %51, i32 0, i32 0
  %53 = load i32, ptr %52, align 4
  %54 = load i32, ptr %8, align 4
  %55 = load i32, ptr %8, align 4
  %56 = add nsw i32 %55, 1
  call void @addSegment(ptr noundef %47, i32 noundef %53, i32 noundef %54, i32 noundef %56)
  %57 = load ptr, ptr %4, align 8
  %58 = load i32, ptr %9, align 4
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds %struct.Process, ptr %57, i64 %59
  %61 = getelementptr inbounds nuw %struct.Process, ptr %60, i32 0, i32 3
  %62 = load i32, ptr %61, align 4
  %63 = add nsw i32 %62, -1
  store i32 %63, ptr %61, align 4
  %64 = load ptr, ptr %4, align 8
  %65 = load i32, ptr %9, align 4
  %66 = sext i32 %65 to i64
  %67 = getelementptr inbounds %struct.Process, ptr %64, i64 %66
  %68 = getelementptr inbounds nuw %struct.Process, ptr %67, i32 0, i32 4
  %69 = load i32, ptr %68, align 4
  %70 = add nsw i32 %69, 1
  store i32 %70, ptr %68, align 4
  %71 = load i32, ptr %8, align 4
  %72 = add nsw i32 %71, 1
  store i32 %72, ptr %8, align 4
  %73 = load ptr, ptr %4, align 8
  %74 = load i32, ptr %9, align 4
  %75 = sext i32 %74 to i64
  %76 = getelementptr inbounds %struct.Process, ptr %73, i64 %75
  %77 = getelementptr inbounds nuw %struct.Process, ptr %76, i32 0, i32 3
  %78 = load i32, ptr %77, align 4
  %79 = icmp eq i32 %78, 0
  br i1 %79, label %80, label %89

80:                                               ; preds = %46
  %81 = load i32, ptr %8, align 4
  %82 = load ptr, ptr %4, align 8
  %83 = load i32, ptr %9, align 4
  %84 = sext i32 %83 to i64
  %85 = getelementptr inbounds %struct.Process, ptr %82, i64 %84
  %86 = getelementptr inbounds nuw %struct.Process, ptr %85, i32 0, i32 8
  store i32 %81, ptr %86, align 4
  %87 = load i32, ptr %7, align 4
  %88 = add nsw i32 %87, 1
  store i32 %88, ptr %7, align 4
  br label %89

89:                                               ; preds = %80, %46
  br label %11, !llvm.loop !10

90:                                               ; preds = %11
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printProcessTable(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str)
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.1)
  store i32 0, ptr %5, align 4
  br label %8

8:                                                ; preds = %44, %2
  %9 = load i32, ptr %5, align 4
  %10 = load i32, ptr %4, align 4
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %12, label %47

12:                                               ; preds = %8
  %13 = load ptr, ptr %3, align 8
  %14 = load i32, ptr %5, align 4
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds %struct.Process, ptr %13, i64 %15
  %17 = getelementptr inbounds nuw %struct.Process, ptr %16, i32 0, i32 0
  %18 = load i32, ptr %17, align 4
  %19 = load ptr, ptr %3, align 8
  %20 = load i32, ptr %5, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds %struct.Process, ptr %19, i64 %21
  %23 = getelementptr inbounds nuw %struct.Process, ptr %22, i32 0, i32 1
  %24 = load i32, ptr %23, align 4
  %25 = load ptr, ptr %3, align 8
  %26 = load i32, ptr %5, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds %struct.Process, ptr %25, i64 %27
  %29 = getelementptr inbounds nuw %struct.Process, ptr %28, i32 0, i32 2
  %30 = load i32, ptr %29, align 4
  %31 = load ptr, ptr %3, align 8
  %32 = load i32, ptr %5, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds %struct.Process, ptr %31, i64 %33
  %35 = getelementptr inbounds nuw %struct.Process, ptr %34, i32 0, i32 5
  %36 = load i32, ptr %35, align 4
  %37 = load ptr, ptr %3, align 8
  %38 = load i32, ptr %5, align 4
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds %struct.Process, ptr %37, i64 %39
  %41 = getelementptr inbounds nuw %struct.Process, ptr %40, i32 0, i32 6
  %42 = load i32, ptr %41, align 4
  %43 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %18, i32 noundef %24, i32 noundef %30, i32 noundef %36, i32 noundef %42)
  br label %44

44:                                               ; preds = %12
  %45 = load i32, ptr %5, align 4
  %46 = add nsw i32 %45, 1
  store i32 %46, ptr %5, align 4
  br label %8, !llvm.loop !11

47:                                               ; preds = %8
  ret void
}

declare i32 @printf(ptr noundef, ...) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printGanttChart(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca %struct.Segment, align 4
  store ptr %0, ptr %2, align 8
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.3)
  store i32 0, ptr %3, align 4
  br label %6

6:                                                ; preds = %46, %1
  %7 = load i32, ptr %3, align 4
  %8 = load ptr, ptr %2, align 8
  %9 = getelementptr inbounds nuw %struct.SegmentList, ptr %8, i32 0, i32 1
  %10 = load i32, ptr %9, align 8
  %11 = icmp slt i32 %7, %10
  br i1 %11, label %12, label %49

12:                                               ; preds = %6
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.SegmentList, ptr %13, i32 0, i32 0
  %15 = load ptr, ptr %14, align 8
  %16 = load i32, ptr %3, align 4
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds %struct.Segment, ptr %15, i64 %17
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %4, ptr align 4 %18, i64 12, i1 false)
  %19 = getelementptr inbounds nuw %struct.Segment, ptr %4, i32 0, i32 0
  %20 = load i32, ptr %19, align 4
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %22, label %28

22:                                               ; preds = %12
  %23 = getelementptr inbounds nuw %struct.Segment, ptr %4, i32 0, i32 1
  %24 = load i32, ptr %23, align 4
  %25 = getelementptr inbounds nuw %struct.Segment, ptr %4, i32 0, i32 2
  %26 = load i32, ptr %25, align 4
  %27 = call i32 (ptr, ...) @printf(ptr noundef @.str.4, i32 noundef %24, i32 noundef %26)
  br label %36

28:                                               ; preds = %12
  %29 = getelementptr inbounds nuw %struct.Segment, ptr %4, i32 0, i32 1
  %30 = load i32, ptr %29, align 4
  %31 = getelementptr inbounds nuw %struct.Segment, ptr %4, i32 0, i32 2
  %32 = load i32, ptr %31, align 4
  %33 = getelementptr inbounds nuw %struct.Segment, ptr %4, i32 0, i32 0
  %34 = load i32, ptr %33, align 4
  %35 = call i32 (ptr, ...) @printf(ptr noundef @.str.5, i32 noundef %30, i32 noundef %32, i32 noundef %34)
  br label %36

36:                                               ; preds = %28, %22
  %37 = load i32, ptr %3, align 4
  %38 = add nsw i32 %37, 1
  %39 = load ptr, ptr %2, align 8
  %40 = getelementptr inbounds nuw %struct.SegmentList, ptr %39, i32 0, i32 1
  %41 = load i32, ptr %40, align 8
  %42 = icmp slt i32 %38, %41
  br i1 %42, label %43, label %45

43:                                               ; preds = %36
  %44 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  br label %45

45:                                               ; preds = %43, %36
  br label %46

46:                                               ; preds = %45
  %47 = load i32, ptr %3, align 4
  %48 = add nsw i32 %47, 1
  store i32 %48, ptr %3, align 4
  br label %6, !llvm.loop !12

49:                                               ; preds = %6
  %50 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printResultTable(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca double, align 8
  %6 = alloca double, align 8
  %7 = alloca double, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store double 0.000000e+00, ptr %5, align 8
  store double 0.000000e+00, ptr %6, align 8
  store double 0.000000e+00, ptr %7, align 8
  store i32 0, ptr %8, align 4
  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str.8)
  %15 = call i32 (ptr, ...) @printf(ptr noundef @.str.9)
  store i32 0, ptr %9, align 4
  br label %16

16:                                               ; preds = %107, %2
  %17 = load i32, ptr %9, align 4
  %18 = load i32, ptr %4, align 4
  %19 = icmp slt i32 %17, %18
  br i1 %19, label %20, label %110

20:                                               ; preds = %16
  %21 = load ptr, ptr %3, align 8
  %22 = load i32, ptr %9, align 4
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds %struct.Process, ptr %21, i64 %23
  %25 = getelementptr inbounds nuw %struct.Process, ptr %24, i32 0, i32 8
  %26 = load i32, ptr %25, align 4
  %27 = load ptr, ptr %3, align 8
  %28 = load i32, ptr %9, align 4
  %29 = sext i32 %28 to i64
  %30 = getelementptr inbounds %struct.Process, ptr %27, i64 %29
  %31 = getelementptr inbounds nuw %struct.Process, ptr %30, i32 0, i32 1
  %32 = load i32, ptr %31, align 4
  %33 = sub nsw i32 %26, %32
  store i32 %33, ptr %10, align 4
  %34 = load i32, ptr %10, align 4
  %35 = load ptr, ptr %3, align 8
  %36 = load i32, ptr %9, align 4
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds %struct.Process, ptr %35, i64 %37
  %39 = getelementptr inbounds nuw %struct.Process, ptr %38, i32 0, i32 2
  %40 = load i32, ptr %39, align 4
  %41 = sub nsw i32 %34, %40
  store i32 %41, ptr %11, align 4
  %42 = load ptr, ptr %3, align 8
  %43 = load i32, ptr %9, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds %struct.Process, ptr %42, i64 %44
  %46 = getelementptr inbounds nuw %struct.Process, ptr %45, i32 0, i32 7
  %47 = load i32, ptr %46, align 4
  %48 = load ptr, ptr %3, align 8
  %49 = load i32, ptr %9, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds %struct.Process, ptr %48, i64 %50
  %52 = getelementptr inbounds nuw %struct.Process, ptr %51, i32 0, i32 1
  %53 = load i32, ptr %52, align 4
  %54 = sub nsw i32 %47, %53
  store i32 %54, ptr %12, align 4
  %55 = load ptr, ptr %3, align 8
  %56 = load i32, ptr %9, align 4
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds %struct.Process, ptr %55, i64 %57
  %59 = getelementptr inbounds nuw %struct.Process, ptr %58, i32 0, i32 8
  %60 = load i32, ptr %59, align 4
  %61 = load ptr, ptr %3, align 8
  %62 = load i32, ptr %9, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds %struct.Process, ptr %61, i64 %63
  %65 = getelementptr inbounds nuw %struct.Process, ptr %64, i32 0, i32 6
  %66 = load i32, ptr %65, align 4
  %67 = sub nsw i32 %60, %66
  %68 = call i32 @maxInt(i32 noundef 0, i32 noundef %67)
  store i32 %68, ptr %13, align 4
  %69 = load i32, ptr %11, align 4
  %70 = sitofp i32 %69 to double
  %71 = load double, ptr %5, align 8
  %72 = fadd double %71, %70
  store double %72, ptr %5, align 8
  %73 = load i32, ptr %10, align 4
  %74 = sitofp i32 %73 to double
  %75 = load double, ptr %6, align 8
  %76 = fadd double %75, %74
  store double %76, ptr %6, align 8
  %77 = load i32, ptr %12, align 4
  %78 = sitofp i32 %77 to double
  %79 = load double, ptr %7, align 8
  %80 = fadd double %79, %78
  store double %80, ptr %7, align 8
  %81 = load i32, ptr %13, align 4
  %82 = load i32, ptr %8, align 4
  %83 = add nsw i32 %82, %81
  store i32 %83, ptr %8, align 4
  %84 = load ptr, ptr %3, align 8
  %85 = load i32, ptr %9, align 4
  %86 = sext i32 %85 to i64
  %87 = getelementptr inbounds %struct.Process, ptr %84, i64 %86
  %88 = getelementptr inbounds nuw %struct.Process, ptr %87, i32 0, i32 0
  %89 = load i32, ptr %88, align 4
  %90 = load ptr, ptr %3, align 8
  %91 = load i32, ptr %9, align 4
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds %struct.Process, ptr %90, i64 %92
  %94 = getelementptr inbounds nuw %struct.Process, ptr %93, i32 0, i32 7
  %95 = load i32, ptr %94, align 4
  %96 = load ptr, ptr %3, align 8
  %97 = load i32, ptr %9, align 4
  %98 = sext i32 %97 to i64
  %99 = getelementptr inbounds %struct.Process, ptr %96, i64 %98
  %100 = getelementptr inbounds nuw %struct.Process, ptr %99, i32 0, i32 8
  %101 = load i32, ptr %100, align 4
  %102 = load i32, ptr %11, align 4
  %103 = load i32, ptr %10, align 4
  %104 = load i32, ptr %12, align 4
  %105 = load i32, ptr %13, align 4
  %106 = call i32 (ptr, ...) @printf(ptr noundef @.str.10, i32 noundef %89, i32 noundef %95, i32 noundef %101, i32 noundef %102, i32 noundef %103, i32 noundef %104, i32 noundef %105)
  br label %107

107:                                              ; preds = %20
  %108 = load i32, ptr %9, align 4
  %109 = add nsw i32 %108, 1
  store i32 %109, ptr %9, align 4
  br label %16, !llvm.loop !13

110:                                              ; preds = %16
  %111 = call i32 (ptr, ...) @printf(ptr noundef @.str.11)
  %112 = load double, ptr %5, align 8
  %113 = load i32, ptr %4, align 4
  %114 = sitofp i32 %113 to double
  %115 = fdiv double %112, %114
  %116 = call i32 (ptr, ...) @printf(ptr noundef @.str.12, double noundef %115)
  %117 = load double, ptr %6, align 8
  %118 = load i32, ptr %4, align 4
  %119 = sitofp i32 %118 to double
  %120 = fdiv double %117, %119
  %121 = call i32 (ptr, ...) @printf(ptr noundef @.str.13, double noundef %120)
  %122 = load double, ptr %7, align 8
  %123 = load i32, ptr %4, align 4
  %124 = sitofp i32 %123 to double
  %125 = fdiv double %122, %124
  %126 = call i32 (ptr, ...) @printf(ptr noundef @.str.14, double noundef %125)
  %127 = load i32, ptr %8, align 4
  %128 = call i32 (ptr, ...) @printf(ptr noundef @.str.15, i32 noundef %127)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printWorstProcess(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 1, ptr %6, align 4
  br label %11

11:                                               ; preds = %102, %2
  %12 = load i32, ptr %6, align 4
  %13 = load i32, ptr %4, align 4
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %15, label %105

15:                                               ; preds = %11
  %16 = load ptr, ptr %3, align 8
  %17 = load i32, ptr %6, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds %struct.Process, ptr %16, i64 %18
  %20 = getelementptr inbounds nuw %struct.Process, ptr %19, i32 0, i32 8
  %21 = load i32, ptr %20, align 4
  %22 = load ptr, ptr %3, align 8
  %23 = load i32, ptr %6, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds %struct.Process, ptr %22, i64 %24
  %26 = getelementptr inbounds nuw %struct.Process, ptr %25, i32 0, i32 6
  %27 = load i32, ptr %26, align 4
  %28 = sub nsw i32 %21, %27
  %29 = call i32 @maxInt(i32 noundef 0, i32 noundef %28)
  store i32 %29, ptr %7, align 4
  %30 = load ptr, ptr %3, align 8
  %31 = load i32, ptr %5, align 4
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds %struct.Process, ptr %30, i64 %32
  %34 = getelementptr inbounds nuw %struct.Process, ptr %33, i32 0, i32 8
  %35 = load i32, ptr %34, align 4
  %36 = load ptr, ptr %3, align 8
  %37 = load i32, ptr %5, align 4
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds %struct.Process, ptr %36, i64 %38
  %40 = getelementptr inbounds nuw %struct.Process, ptr %39, i32 0, i32 6
  %41 = load i32, ptr %40, align 4
  %42 = sub nsw i32 %35, %41
  %43 = call i32 @maxInt(i32 noundef 0, i32 noundef %42)
  store i32 %43, ptr %8, align 4
  %44 = load i32, ptr %7, align 4
  %45 = load i32, ptr %8, align 4
  %46 = icmp sgt i32 %44, %45
  br i1 %46, label %47, label %49

47:                                               ; preds = %15
  %48 = load i32, ptr %6, align 4
  store i32 %48, ptr %5, align 4
  br label %101

49:                                               ; preds = %15
  %50 = load i32, ptr %7, align 4
  %51 = load i32, ptr %8, align 4
  %52 = icmp eq i32 %50, %51
  br i1 %52, label %53, label %100

53:                                               ; preds = %49
  %54 = load ptr, ptr %3, align 8
  %55 = load i32, ptr %6, align 4
  %56 = sext i32 %55 to i64
  %57 = getelementptr inbounds %struct.Process, ptr %54, i64 %56
  %58 = getelementptr inbounds nuw %struct.Process, ptr %57, i32 0, i32 8
  %59 = load i32, ptr %58, align 4
  %60 = load ptr, ptr %3, align 8
  %61 = load i32, ptr %6, align 4
  %62 = sext i32 %61 to i64
  %63 = getelementptr inbounds %struct.Process, ptr %60, i64 %62
  %64 = getelementptr inbounds nuw %struct.Process, ptr %63, i32 0, i32 1
  %65 = load i32, ptr %64, align 4
  %66 = sub nsw i32 %59, %65
  %67 = load ptr, ptr %3, align 8
  %68 = load i32, ptr %6, align 4
  %69 = sext i32 %68 to i64
  %70 = getelementptr inbounds %struct.Process, ptr %67, i64 %69
  %71 = getelementptr inbounds nuw %struct.Process, ptr %70, i32 0, i32 2
  %72 = load i32, ptr %71, align 4
  %73 = sub nsw i32 %66, %72
  store i32 %73, ptr %9, align 4
  %74 = load ptr, ptr %3, align 8
  %75 = load i32, ptr %5, align 4
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds %struct.Process, ptr %74, i64 %76
  %78 = getelementptr inbounds nuw %struct.Process, ptr %77, i32 0, i32 8
  %79 = load i32, ptr %78, align 4
  %80 = load ptr, ptr %3, align 8
  %81 = load i32, ptr %5, align 4
  %82 = sext i32 %81 to i64
  %83 = getelementptr inbounds %struct.Process, ptr %80, i64 %82
  %84 = getelementptr inbounds nuw %struct.Process, ptr %83, i32 0, i32 1
  %85 = load i32, ptr %84, align 4
  %86 = sub nsw i32 %79, %85
  %87 = load ptr, ptr %3, align 8
  %88 = load i32, ptr %5, align 4
  %89 = sext i32 %88 to i64
  %90 = getelementptr inbounds %struct.Process, ptr %87, i64 %89
  %91 = getelementptr inbounds nuw %struct.Process, ptr %90, i32 0, i32 2
  %92 = load i32, ptr %91, align 4
  %93 = sub nsw i32 %86, %92
  store i32 %93, ptr %10, align 4
  %94 = load i32, ptr %9, align 4
  %95 = load i32, ptr %10, align 4
  %96 = icmp sgt i32 %94, %95
  br i1 %96, label %97, label %99

97:                                               ; preds = %53
  %98 = load i32, ptr %6, align 4
  store i32 %98, ptr %5, align 4
  br label %99

99:                                               ; preds = %97, %53
  br label %100

100:                                              ; preds = %99, %49
  br label %101

101:                                              ; preds = %100, %47
  br label %102

102:                                              ; preds = %101
  %103 = load i32, ptr %6, align 4
  %104 = add nsw i32 %103, 1
  store i32 %104, ptr %6, align 4
  br label %11, !llvm.loop !14

105:                                              ; preds = %11
  %106 = load ptr, ptr %3, align 8
  %107 = load i32, ptr %5, align 4
  %108 = sext i32 %107 to i64
  %109 = getelementptr inbounds %struct.Process, ptr %106, i64 %108
  %110 = getelementptr inbounds nuw %struct.Process, ptr %109, i32 0, i32 0
  %111 = load i32, ptr %110, align 4
  %112 = load ptr, ptr %3, align 8
  %113 = load i32, ptr %5, align 4
  %114 = sext i32 %113 to i64
  %115 = getelementptr inbounds %struct.Process, ptr %112, i64 %114
  %116 = getelementptr inbounds nuw %struct.Process, ptr %115, i32 0, i32 8
  %117 = load i32, ptr %116, align 4
  %118 = load ptr, ptr %3, align 8
  %119 = load i32, ptr %5, align 4
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds %struct.Process, ptr %118, i64 %120
  %122 = getelementptr inbounds nuw %struct.Process, ptr %121, i32 0, i32 6
  %123 = load i32, ptr %122, align 4
  %124 = load ptr, ptr %3, align 8
  %125 = load i32, ptr %5, align 4
  %126 = sext i32 %125 to i64
  %127 = getelementptr inbounds %struct.Process, ptr %124, i64 %126
  %128 = getelementptr inbounds nuw %struct.Process, ptr %127, i32 0, i32 8
  %129 = load i32, ptr %128, align 4
  %130 = load ptr, ptr %3, align 8
  %131 = load i32, ptr %5, align 4
  %132 = sext i32 %131 to i64
  %133 = getelementptr inbounds %struct.Process, ptr %130, i64 %132
  %134 = getelementptr inbounds nuw %struct.Process, ptr %133, i32 0, i32 6
  %135 = load i32, ptr %134, align 4
  %136 = sub nsw i32 %129, %135
  %137 = call i32 @maxInt(i32 noundef 0, i32 noundef %136)
  %138 = call i32 (ptr, ...) @printf(ptr noundef @.str.16, i32 noundef %111, i32 noundef %117, i32 noundef %123, i32 noundef %137)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca %struct.SegmentList, align 8
  store i32 0, ptr %1, align 4
  %5 = call i32 (ptr, ...) @__isoc99_scanf(ptr noundef @.str.17, ptr noundef %2)
  %6 = icmp ne i32 %5, 1
  br i1 %6, label %7, label %9

7:                                                ; preds = %0
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.18)
  store i32 0, ptr %1, align 4
  br label %39

9:                                                ; preds = %0
  %10 = load i32, ptr %2, align 4
  %11 = icmp slt i32 %10, 1
  br i1 %11, label %15, label %12

12:                                               ; preds = %9
  %13 = load i32, ptr %2, align 4
  %14 = icmp sgt i32 %13, 100
  br i1 %14, label %15, label %17

15:                                               ; preds = %12, %9
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.19, i32 noundef 100)
  store i32 0, ptr %1, align 4
  br label %39

17:                                               ; preds = %12
  %18 = load i32, ptr %2, align 4
  %19 = sext i32 %18 to i64
  %20 = mul i64 36, %19
  %21 = call noalias ptr @malloc(i64 noundef %20) #6
  store ptr %21, ptr %3, align 8
  call void @initSegments(ptr noundef %4)
  %22 = load ptr, ptr %3, align 8
  %23 = load i32, ptr %2, align 4
  call void @generateProcesses(ptr noundef %22, i32 noundef %23)
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.20)
  %25 = load i32, ptr %2, align 4
  %26 = call i32 (ptr, ...) @printf(ptr noundef @.str.21, i32 noundef %25)
  %27 = call i32 (ptr, ...) @printf(ptr noundef @.str.22, i32 noundef 4)
  %28 = load ptr, ptr %3, align 8
  %29 = load i32, ptr %2, align 4
  call void @printProcessTable(ptr noundef %28, i32 noundef %29)
  %30 = load ptr, ptr %3, align 8
  %31 = load i32, ptr %2, align 4
  call void @simulate(ptr noundef %30, i32 noundef %31, ptr noundef %4)
  call void @printGanttChart(ptr noundef %4)
  %32 = load ptr, ptr %3, align 8
  %33 = load i32, ptr %2, align 4
  call void @printResultTable(ptr noundef %32, i32 noundef %33)
  %34 = load ptr, ptr %3, align 8
  %35 = load i32, ptr %2, align 4
  call void @printWorstProcess(ptr noundef %34, i32 noundef %35)
  %36 = getelementptr inbounds nuw %struct.SegmentList, ptr %4, i32 0, i32 0
  %37 = load ptr, ptr %36, align 8
  call void @free(ptr noundef %37) #8
  %38 = load ptr, ptr %3, align 8
  call void @free(ptr noundef %38) #8
  store i32 0, ptr %1, align 4
  br label %39

39:                                               ; preds = %17, %15, %7
  %40 = load i32, ptr %1, align 4
  ret i32 %40
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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
!14 = distinct !{!14, !7}

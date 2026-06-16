; ModuleID = 'data/obfuscated/keybox/clean.bc'
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

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  store i32 0, ptr %3, align 4
  store i32 %0, ptr %4, align 4
  store ptr %1, ptr %5, align 8
  call void @print_banner()
  %6 = load i32, ptr %4, align 4
  %7 = icmp ne i32 %6, 2
  br i1 %7, label %8, label %14

8:                                                ; preds = %2
  %9 = load ptr, ptr @stderr, align 8
  %10 = load ptr, ptr %5, align 8
  %11 = getelementptr inbounds ptr, ptr %10, i64 0
  %12 = load ptr, ptr %11, align 8
  %13 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %9, ptr noundef @.str, ptr noundef %12) #6
  store i32 2, ptr %3, align 4
  br label %24

14:                                               ; preds = %2
  %15 = load ptr, ptr %5, align 8
  %16 = getelementptr inbounds ptr, ptr %15, i64 1
  %17 = load ptr, ptr %16, align 8
  %18 = call i32 @validate_key(ptr noundef %17)
  %19 = icmp ne i32 %18, 0
  br i1 %19, label %20, label %22

20:                                               ; preds = %14
  %21 = call i32 @puts(ptr noundef @.str.1)
  store i32 0, ptr %3, align 4
  br label %24

22:                                               ; preds = %14
  %23 = call i32 @puts(ptr noundef @.str.2)
  store i32 1, ptr %3, align 4
  br label %24

24:                                               ; preds = %22, %20, %8
  %25 = load i32, ptr %3, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @print_banner() #0 {
  %1 = alloca [17 x i8], align 16
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  br label %3

3:                                                ; preds = %15, %0
  %4 = load i64, ptr %2, align 8
  %5 = icmp ult i64 %4, 16
  br i1 %5, label %6, label %18

6:                                                ; preds = %3
  %7 = load i64, ptr %2, align 8
  %8 = getelementptr inbounds nuw [16 x i8], ptr @print_banner.enc, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1
  %10 = zext i8 %9 to i32
  %11 = xor i32 %10, 102
  %12 = trunc i32 %11 to i8
  %13 = load i64, ptr %2, align 8
  %14 = getelementptr inbounds nuw [17 x i8], ptr %1, i64 0, i64 %13
  store i8 %12, ptr %14, align 1
  br label %15

15:                                               ; preds = %6
  %16 = load i64, ptr %2, align 8
  %17 = add i64 %16, 1
  store i64 %17, ptr %2, align 8
  br label %3, !llvm.loop !6

18:                                               ; preds = %3
  %19 = getelementptr inbounds nuw [17 x i8], ptr %1, i64 0, i64 16
  store i8 0, ptr %19, align 16
  %20 = getelementptr inbounds [17 x i8], ptr %1, i64 0, i64 0
  %21 = call i32 @puts(ptr noundef %20)
  ret void
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @validate_key(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i64, align 8
  %4 = alloca [14 x i8], align 1
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %8 = load ptr, ptr %2, align 8
  %9 = call i64 @strlen(ptr noundef %8) #7
  store i64 %9, ptr %3, align 8
  %10 = getelementptr inbounds [14 x i8], ptr %4, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 1 %10, i8 0, i64 14, i1 false)
  store i32 1, ptr %5, align 4
  store i64 0, ptr %6, align 8
  br label %11

11:                                               ; preds = %25, %1
  %12 = load i64, ptr %6, align 8
  %13 = icmp ult i64 %12, 4
  br i1 %13, label %14, label %28

14:                                               ; preds = %11
  %15 = load i64, ptr %6, align 8
  %16 = getelementptr inbounds nuw [4 x ptr], ptr @validate_key.stages, i64 0, i64 %15
  %17 = load ptr, ptr %16, align 8
  %18 = load ptr, ptr %2, align 8
  %19 = load i64, ptr %3, align 8
  %20 = getelementptr inbounds [14 x i8], ptr %4, i64 0, i64 0
  %21 = call i32 %17(ptr noundef %18, i64 noundef %19, ptr noundef %20)
  store i32 %21, ptr %7, align 4
  %22 = load i32, ptr %7, align 4
  %23 = load i32, ptr %5, align 4
  %24 = and i32 %23, %22
  store i32 %24, ptr %5, align 4
  br label %25

25:                                               ; preds = %14
  %26 = load i64, ptr %6, align 8
  %27 = add i64 %26, 1
  store i64 %27, ptr %6, align 8
  br label %11, !llvm.loop !8

28:                                               ; preds = %11
  %29 = load i32, ptr %5, align 4
  ret i32 %29
}

declare i32 @puts(ptr noundef) #2

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #3

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #4

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @check_shape(ptr noundef %0, i64 noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i64, align 8
  %10 = alloca i8, align 1
  %11 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  %12 = load i64, ptr %6, align 8
  %13 = icmp ne i64 %12, 14
  br i1 %13, label %14, label %15

14:                                               ; preds = %3
  store i32 0, ptr %4, align 4
  br label %72

15:                                               ; preds = %3
  store i32 0, ptr %8, align 4
  store i64 0, ptr %9, align 8
  br label %16

16:                                               ; preds = %65, %15
  %17 = load i64, ptr %9, align 8
  %18 = load i64, ptr %6, align 8
  %19 = icmp ult i64 %17, %18
  br i1 %19, label %20, label %68

20:                                               ; preds = %16
  %21 = load ptr, ptr %5, align 8
  %22 = load i64, ptr %9, align 8
  %23 = getelementptr inbounds nuw i8, ptr %21, i64 %22
  %24 = load i8, ptr %23, align 1
  store i8 %24, ptr %10, align 1
  %25 = load i8, ptr %10, align 1
  %26 = zext i8 %25 to i32
  %27 = icmp sge i32 %26, 97
  br i1 %27, label %28, label %32

28:                                               ; preds = %20
  %29 = load i8, ptr %10, align 1
  %30 = zext i8 %29 to i32
  %31 = icmp sle i32 %30, 122
  br i1 %31, label %44, label %32

32:                                               ; preds = %28, %20
  %33 = load i8, ptr %10, align 1
  %34 = zext i8 %33 to i32
  %35 = icmp sge i32 %34, 48
  br i1 %35, label %36, label %40

36:                                               ; preds = %32
  %37 = load i8, ptr %10, align 1
  %38 = zext i8 %37 to i32
  %39 = icmp sle i32 %38, 57
  br i1 %39, label %44, label %40

40:                                               ; preds = %36, %32
  %41 = load i8, ptr %10, align 1
  %42 = zext i8 %41 to i32
  %43 = icmp eq i32 %42, 45
  br label %44

44:                                               ; preds = %40, %36, %28
  %45 = phi i1 [ true, %36 ], [ true, %28 ], [ %43, %40 ]
  %46 = zext i1 %45 to i32
  store i32 %46, ptr %11, align 4
  %47 = load i32, ptr %11, align 4
  %48 = xor i32 %47, 1
  %49 = load i32, ptr %8, align 4
  %50 = or i32 %49, %48
  store i32 %50, ptr %8, align 4
  %51 = load i8, ptr %10, align 1
  %52 = zext i8 %51 to i32
  %53 = load i64, ptr %9, align 8
  %54 = mul i64 %53, 7
  %55 = add i64 %54, 3
  %56 = and i64 %55, 63
  %57 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %56
  %58 = load i8, ptr %57, align 1
  %59 = zext i8 %58 to i32
  %60 = xor i32 %52, %59
  %61 = trunc i32 %60 to i8
  %62 = load ptr, ptr %7, align 8
  %63 = load i64, ptr %9, align 8
  %64 = getelementptr inbounds nuw i8, ptr %62, i64 %63
  store i8 %61, ptr %64, align 1
  br label %65

65:                                               ; preds = %44
  %66 = load i64, ptr %9, align 8
  %67 = add i64 %66, 1
  store i64 %67, ptr %9, align 8
  br label %16, !llvm.loop !9

68:                                               ; preds = %16
  %69 = load i32, ptr %8, align 4
  %70 = icmp eq i32 %69, 0
  %71 = zext i1 %70 to i32
  store i32 %71, ptr %4, align 4
  br label %72

72:                                               ; preds = %68, %14
  %73 = load i32, ptr %4, align 4
  ret i32 %73
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @check_table(ptr noundef %0, i64 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i64, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i8, align 1
  %8 = alloca i64, align 8
  %9 = alloca i8, align 1
  %10 = alloca i8, align 1
  store ptr %0, ptr %4, align 8
  store i64 %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  store i8 0, ptr %7, align 1
  store i64 0, ptr %8, align 8
  br label %11

11:                                               ; preds = %67, %3
  %12 = load i64, ptr %8, align 8
  %13 = load i64, ptr %5, align 8
  %14 = icmp ult i64 %12, %13
  br i1 %14, label %15, label %70

15:                                               ; preds = %11
  %16 = load ptr, ptr %4, align 8
  %17 = load i64, ptr %8, align 8
  %18 = getelementptr inbounds nuw i8, ptr %16, i64 %17
  %19 = load i8, ptr %18, align 1
  store i8 %19, ptr %9, align 1
  %20 = load i8, ptr %9, align 1
  %21 = zext i8 %20 to i32
  %22 = load i64, ptr %8, align 8
  %23 = urem i64 %22, 7
  %24 = getelementptr inbounds nuw [7 x i8], ptr @check_table.k, i64 0, i64 %23
  %25 = load i8, ptr %24, align 1
  %26 = zext i8 %25 to i32
  %27 = xor i32 %21, %26
  %28 = load i64, ptr %8, align 8
  %29 = mul i64 %28, 13
  %30 = trunc i64 %29 to i8
  %31 = zext i8 %30 to i32
  %32 = add nsw i32 %27, %31
  %33 = trunc i32 %32 to i8
  store i8 %33, ptr %10, align 1
  %34 = load i8, ptr %10, align 1
  %35 = zext i8 %34 to i32
  %36 = load i64, ptr %8, align 8
  %37 = getelementptr inbounds nuw [14 x i8], ptr @check_table.target, i64 0, i64 %36
  %38 = load i8, ptr %37, align 1
  %39 = zext i8 %38 to i32
  %40 = xor i32 %35, %39
  %41 = trunc i32 %40 to i8
  %42 = zext i8 %41 to i32
  %43 = load i8, ptr %7, align 1
  %44 = zext i8 %43 to i32
  %45 = or i32 %44, %42
  %46 = trunc i32 %45 to i8
  store i8 %46, ptr %7, align 1
  %47 = load i8, ptr %9, align 1
  %48 = zext i8 %47 to i32
  %49 = load i64, ptr %8, align 8
  %50 = mul i64 %49, 5
  %51 = and i64 %50, 63
  %52 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %51
  %53 = load i8, ptr %52, align 1
  %54 = zext i8 %53 to i32
  %55 = add nsw i32 %48, %54
  %56 = and i32 %55, 255
  %57 = load i64, ptr %8, align 8
  %58 = mul i64 %57, 11
  %59 = add i64 165, %58
  %60 = trunc i64 %59 to i8
  %61 = zext i8 %60 to i32
  %62 = xor i32 %56, %61
  %63 = trunc i32 %62 to i8
  %64 = load ptr, ptr %6, align 8
  %65 = load i64, ptr %8, align 8
  %66 = getelementptr inbounds nuw i8, ptr %64, i64 %65
  store i8 %63, ptr %66, align 1
  br label %67

67:                                               ; preds = %15
  %68 = load i64, ptr %8, align 8
  %69 = add i64 %68, 1
  store i64 %69, ptr %8, align 8
  br label %11, !llvm.loop !10

70:                                               ; preds = %11
  %71 = load i8, ptr %7, align 1
  %72 = zext i8 %71 to i32
  %73 = icmp eq i32 %72, 0
  %74 = zext i1 %73 to i32
  ret i32 %74
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
  %20 = xor i32 %19, -1577194447
  %21 = load i32, ptr %8, align 4
  %22 = xor i32 %21, -296954887
  %23 = or i32 %20, %22
  %24 = load i32, ptr %9, align 4
  %25 = xor i32 %24, 1896214013
  %26 = or i32 %23, %25
  %27 = icmp eq i32 %26, 0
  %28 = zext i1 %27 to i32
  ret i32 %28
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @check_heap_stack(ptr noundef %0, i64 noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca ptr, align 8
  %8 = alloca [14 x i8], align 1
  %9 = alloca ptr, align 8
  %10 = alloca i64, align 8
  %11 = alloca i32, align 4
  %12 = alloca i64, align 8
  store ptr %0, ptr %5, align 8
  store i64 %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  %13 = load ptr, ptr %5, align 8
  %14 = load i64, ptr %6, align 8
  %15 = add i64 %14, 1
  %16 = call noalias ptr @malloc(i64 noundef %15) #8
  store ptr %16, ptr %9, align 8
  %17 = load ptr, ptr %9, align 8
  %18 = icmp ne ptr %17, null
  br i1 %18, label %20, label %19

19:                                               ; preds = %3
  store i32 0, ptr %4, align 4
  br label %100

20:                                               ; preds = %3
  store i64 0, ptr %10, align 8
  br label %21

21:                                               ; preds = %59, %20
  %22 = load i64, ptr %10, align 8
  %23 = load i64, ptr %6, align 8
  %24 = icmp ult i64 %22, %23
  br i1 %24, label %25, label %62

25:                                               ; preds = %21
  %26 = load ptr, ptr %7, align 8
  %27 = load i64, ptr %6, align 8
  %28 = sub i64 %27, 1
  %29 = load i64, ptr %10, align 8
  %30 = sub i64 %28, %29
  %31 = getelementptr inbounds nuw i8, ptr %26, i64 %30
  %32 = load i8, ptr %31, align 1
  %33 = zext i8 %32 to i32
  %34 = load i64, ptr %10, align 8
  %35 = mul i64 %34, 9
  %36 = add i64 61, %35
  %37 = trunc i64 %36 to i8
  %38 = zext i8 %37 to i32
  %39 = xor i32 %33, %38
  %40 = trunc i32 %39 to i8
  %41 = load i64, ptr %10, align 8
  %42 = getelementptr inbounds nuw [14 x i8], ptr %8, i64 0, i64 %41
  store i8 %40, ptr %42, align 1
  %43 = load i64, ptr %10, align 8
  %44 = getelementptr inbounds nuw [14 x i8], ptr %8, i64 0, i64 %43
  %45 = load i8, ptr %44, align 1
  %46 = zext i8 %45 to i32
  %47 = load i64, ptr %10, align 8
  %48 = mul i64 %47, 11
  %49 = add i64 %48, 5
  %50 = and i64 %49, 63
  %51 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %50
  %52 = load i8, ptr %51, align 1
  %53 = zext i8 %52 to i32
  %54 = add nsw i32 %46, %53
  %55 = trunc i32 %54 to i8
  %56 = load ptr, ptr %9, align 8
  %57 = load i64, ptr %10, align 8
  %58 = getelementptr inbounds nuw i8, ptr %56, i64 %57
  store i8 %55, ptr %58, align 1
  br label %59

59:                                               ; preds = %25
  %60 = load i64, ptr %10, align 8
  %61 = add i64 %60, 1
  store i64 %61, ptr %10, align 8
  br label %21, !llvm.loop !11

62:                                               ; preds = %21
  %63 = load ptr, ptr %9, align 8
  %64 = load i64, ptr %6, align 8
  %65 = getelementptr inbounds nuw i8, ptr %63, i64 %64
  store i8 0, ptr %65, align 1
  store i32 826366246, ptr %11, align 4
  store i64 0, ptr %12, align 8
  br label %66

66:                                               ; preds = %92, %62
  %67 = load i64, ptr %12, align 8
  %68 = load i64, ptr %6, align 8
  %69 = icmp ult i64 %67, %68
  br i1 %69, label %70, label %95

70:                                               ; preds = %66
  %71 = load i32, ptr %11, align 4
  %72 = load ptr, ptr %9, align 8
  %73 = load i64, ptr %12, align 8
  %74 = getelementptr inbounds nuw i8, ptr %72, i64 %73
  %75 = load i8, ptr %74, align 1
  %76 = zext i8 %75 to i32
  %77 = add i32 %71, %76
  %78 = load i64, ptr %12, align 8
  %79 = mul i64 %78, 17
  %80 = trunc i64 %79 to i32
  %81 = add i32 %77, %80
  %82 = call i32 @rol32(i32 noundef %81, i32 noundef 4)
  store i32 %82, ptr %11, align 4
  %83 = load i64, ptr %12, align 8
  %84 = getelementptr inbounds nuw [14 x i8], ptr %8, i64 0, i64 %83
  %85 = load i8, ptr %84, align 1
  %86 = zext i8 %85 to i32
  %87 = mul i32 %86, 16843009
  %88 = load i32, ptr %11, align 4
  %89 = xor i32 %88, %87
  store i32 %89, ptr %11, align 4
  %90 = load i32, ptr %11, align 4
  %91 = call i32 @mix32(i32 noundef %90)
  store i32 %91, ptr %11, align 4
  br label %92

92:                                               ; preds = %70
  %93 = load i64, ptr %12, align 8
  %94 = add i64 %93, 1
  store i64 %94, ptr %12, align 8
  br label %66, !llvm.loop !12

95:                                               ; preds = %66
  %96 = load ptr, ptr %9, align 8
  call void @free(ptr noundef %96) #6
  %97 = load i32, ptr %11, align 4
  %98 = icmp eq i32 %97, 783815019
  %99 = zext i1 %98 to i32
  store i32 %99, ptr %4, align 4
  br label %100

100:                                              ; preds = %95, %19
  %101 = load i32, ptr %4, align 4
  ret i32 %101
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
  %7 = shl i32 %5, %6
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 32, %9
  %11 = lshr i32 %8, %10
  %12 = or i32 %7, %11
  ret i32 %12
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @mix32(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = lshr i32 %3, 16
  %5 = load i32, ptr %2, align 4
  %6 = xor i32 %5, %4
  store i32 %6, ptr %2, align 4
  %7 = load i32, ptr %2, align 4
  %8 = mul i32 %7, 2146121005
  store i32 %8, ptr %2, align 4
  %9 = load i32, ptr %2, align 4
  %10 = lshr i32 %9, 15
  %11 = load i32, ptr %2, align 4
  %12 = xor i32 %11, %10
  store i32 %12, ptr %2, align 4
  %13 = load i32, ptr %2, align 4
  %14 = mul i32 %13, -2073254261
  store i32 %14, ptr %2, align 4
  %15 = load i32, ptr %2, align 4
  %16 = lshr i32 %15, 16
  %17 = load i32, ptr %2, align 4
  %18 = xor i32 %17, %16
  store i32 %18, ptr %2, align 4
  %19 = load i32, ptr %2, align 4
  ret i32 %19
}

; Function Attrs: nounwind
declare void @free(ptr noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @checksum32(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  store i32 -2128831035, ptr %5, align 4
  store i64 0, ptr %6, align 8
  br label %7

7:                                                ; preds = %37, %2
  %8 = load i64, ptr %6, align 8
  %9 = load i64, ptr %4, align 8
  %10 = icmp ult i64 %8, %9
  br i1 %10, label %11, label %40

11:                                               ; preds = %7
  %12 = load ptr, ptr %3, align 8
  %13 = load i64, ptr %6, align 8
  %14 = getelementptr inbounds nuw i8, ptr %12, i64 %13
  %15 = load i8, ptr %14, align 1
  %16 = zext i8 %15 to i32
  %17 = load i64, ptr %6, align 8
  %18 = mul i64 %17, 40503
  %19 = trunc i64 %18 to i32
  %20 = add i32 %16, %19
  %21 = load i32, ptr %5, align 4
  %22 = xor i32 %21, %20
  store i32 %22, ptr %5, align 4
  %23 = load i32, ptr %5, align 4
  %24 = mul i32 %23, 16777619
  store i32 %24, ptr %5, align 4
  %25 = load i32, ptr %5, align 4
  %26 = load i64, ptr %6, align 8
  %27 = urem i64 %26, 7
  %28 = add i64 %27, 1
  %29 = trunc i64 %28 to i32
  %30 = call i32 @rol32(i32 noundef %25, i32 noundef %29)
  %31 = load i64, ptr %6, align 8
  %32 = and i64 %31, 63
  %33 = getelementptr inbounds nuw [64 x i8], ptr @g_box, i64 0, i64 %32
  %34 = load i8, ptr %33, align 1
  %35 = zext i8 %34 to i32
  %36 = xor i32 %30, %35
  store i32 %36, ptr %5, align 4
  br label %37

37:                                               ; preds = %11
  %38 = load i64, ptr %6, align 8
  %39 = add i64 %38, 1
  store i64 %39, ptr %6, align 8
  br label %7, !llvm.loop !13

40:                                               ; preds = %7
  %41 = load i32, ptr %5, align 4
  %42 = load i64, ptr %4, align 8
  %43 = mul i64 %42, 73244475
  %44 = trunc i64 %43 to i32
  %45 = xor i32 %41, %44
  %46 = call i32 @mix32(i32 noundef %45)
  ret i32 %46
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @graph_mix(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  store i32 -1073623027, ptr %5, align 4
  store i64 0, ptr %6, align 8
  br label %8

8:                                                ; preds = %86, %2
  %9 = load i64, ptr %6, align 8
  %10 = load i64, ptr %4, align 8
  %11 = icmp ult i64 %9, %10
  br i1 %11, label %12, label %89

12:                                               ; preds = %8
  %13 = load ptr, ptr %3, align 8
  %14 = load i64, ptr %6, align 8
  %15 = getelementptr inbounds nuw i8, ptr %13, i64 %14
  %16 = load i8, ptr %15, align 1
  %17 = zext i8 %16 to i32
  store i32 %17, ptr %7, align 4
  %18 = load i32, ptr %7, align 4
  %19 = load i64, ptr %6, align 8
  %20 = trunc i64 %19 to i32
  %21 = add i32 %18, %20
  %22 = and i32 %21, 7
  switch i32 %22, label %76 [
    i32 0, label %23
    i32 1, label %29
    i32 2, label %35
    i32 3, label %44
    i32 4, label %53
    i32 5, label %59
    i32 6, label %67
  ]

23:                                               ; preds = %12
  %24 = load i32, ptr %5, align 4
  %25 = load i32, ptr %7, align 4
  %26 = xor i32 %24, %25
  %27 = call i32 @rol32(i32 noundef %26, i32 noundef 3)
  %28 = add i32 %27, 324508639
  store i32 %28, ptr %5, align 4
  br label %85

29:                                               ; preds = %12
  %30 = load i32, ptr %5, align 4
  %31 = load i32, ptr %7, align 4
  %32 = mul i32 %31, 73244475
  %33 = add i32 %30, %32
  %34 = call i32 @mix32(i32 noundef %33)
  store i32 %34, ptr %5, align 4
  br label %85

35:                                               ; preds = %12
  %36 = load i32, ptr %5, align 4
  %37 = load i32, ptr %7, align 4
  %38 = load i64, ptr %6, align 8
  %39 = and i64 %38, 7
  %40 = trunc i64 %39 to i32
  %41 = shl i32 %37, %40
  %42 = xor i32 %36, %41
  %43 = mul i32 %42, 668265261
  store i32 %43, ptr %5, align 4
  br label %85

44:                                               ; preds = %12
  %45 = load i32, ptr %5, align 4
  %46 = load i32, ptr %7, align 4
  %47 = add i32 %45, %46
  %48 = load i64, ptr %6, align 8
  %49 = trunc i64 %48 to i32
  %50 = add i32 %47, %49
  %51 = call i32 @rol32(i32 noundef %50, i32 noundef 5)
  %52 = xor i32 %51, -1515870811
  store i32 %52, ptr %5, align 4
  br label %85

53:                                               ; preds = %12
  %54 = load i32, ptr %5, align 4
  %55 = load i32, ptr %7, align 4
  %56 = xor i32 %55, 90
  %57 = sub i32 %54, %56
  %58 = add i32 %57, -1640531527
  store i32 %58, ptr %5, align 4
  br label %85

59:                                               ; preds = %12
  %60 = load i32, ptr %5, align 4
  %61 = lshr i32 %60, 7
  %62 = load i32, ptr %7, align 4
  %63 = mul i32 %62, 257
  %64 = add i32 %61, %63
  %65 = load i32, ptr %5, align 4
  %66 = xor i32 %65, %64
  store i32 %66, ptr %5, align 4
  br label %85

67:                                               ; preds = %12
  %68 = load i32, ptr %5, align 4
  %69 = call i32 @rol32(i32 noundef %68, i32 noundef 11)
  %70 = load i32, ptr %7, align 4
  %71 = load i64, ptr %6, align 8
  %72 = trunc i64 %71 to i32
  %73 = xor i32 %70, %72
  %74 = mul i32 %73, 65537
  %75 = add i32 %69, %74
  store i32 %75, ptr %5, align 4
  br label %85

76:                                               ; preds = %12
  %77 = load i32, ptr %5, align 4
  %78 = load i32, ptr %7, align 4
  %79 = xor i32 %77, %78
  %80 = load i64, ptr %6, align 8
  %81 = mul i64 %80, 31337
  %82 = trunc i64 %81 to i32
  %83 = xor i32 %79, %82
  %84 = call i32 @mix32(i32 noundef %83)
  store i32 %84, ptr %5, align 4
  br label %85

85:                                               ; preds = %76, %67, %59, %53, %44, %35, %29, %23
  br label %86

86:                                               ; preds = %85
  %87 = load i64, ptr %6, align 8
  %88 = add i64 %87, 1
  store i64 %88, ptr %6, align 8
  br label %8, !llvm.loop !14

89:                                               ; preds = %8
  %90 = load i32, ptr %5, align 4
  %91 = xor i32 %90, -559038737
  %92 = call i32 @mix32(i32 noundef %91)
  ret i32 %92
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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
!14 = distinct !{!14, !7}

; ModuleID = 'data/obfuscated/command_io/clean.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Product = type { i32, [80 x i8], [50 x i8], i64, i32, i32, i32 }
%struct.Order = type { i32, [80 x i8], [30 x i8], [64 x %struct.OrderItem], i32, i64, i64, i64, i64, i64, i32 }
%struct.OrderItem = type { i32, [80 x i8], i32, i64, i64 }

@productCount = dso_local global i32 0, align 4
@orderCount = dso_local global i32 0, align 4
@nextOrderId = dso_local global i32 1, align 4
@.str = private unnamed_addr constant [12 x i8] c"%lld.%02lld\00", align 1
@products = dso_local global [1000 x %struct.Product] zeroinitializer, align 16
@orders = dso_local global [1000 x %struct.Order] zeroinitializer, align 16
@.str.1 = private unnamed_addr constant [54 x i8] c"ID | NAME | CATEGORY | PRICE | STOCK | SOLD | STATUS\0A\00", align 1
@.str.2 = private unnamed_addr constant [16 x i8] c"%d | %s | %s | \00", align 1
@.str.3 = private unnamed_addr constant [17 x i8] c" | %d | %d | %s\0A\00", align 1
@.str.4 = private unnamed_addr constant [7 x i8] c"ACTIVE\00", align 1
@.str.5 = private unnamed_addr constant [8 x i8] c"REMOVED\00", align 1
@.str.6 = private unnamed_addr constant [58 x i8] c"ERR ADD needs 5 fields: ADD|id|name|category|price|stock\0A\00", align 1
@.str.7 = private unnamed_addr constant [20 x i8] c"ERR ADD invalid id\0A\00", align 1
@.str.8 = private unnamed_addr constant [25 x i8] c"ERR ADD duplicate id %d\0A\00", align 1
@.str.9 = private unnamed_addr constant [22 x i8] c"ERR ADD invalid name\0A\00", align 1
@.str.10 = private unnamed_addr constant [26 x i8] c"ERR ADD invalid category\0A\00", align 1
@.str.11 = private unnamed_addr constant [23 x i8] c"ERR ADD invalid price\0A\00", align 1
@.str.12 = private unnamed_addr constant [23 x i8] c"ERR ADD invalid stock\0A\00", align 1
@.str.13 = private unnamed_addr constant [30 x i8] c"ERR ADD product storage full\0A\00", align 1
@.str.14 = private unnamed_addr constant [14 x i8] c"OK ADD %d %s\0A\00", align 1
@.str.15 = private unnamed_addr constant [27 x i8] c"ERR REMOVE invalid format\0A\00", align 1
@.str.16 = private unnamed_addr constant [33 x i8] c"ERR REMOVE product %d not found\0A\00", align 1
@.str.17 = private unnamed_addr constant [39 x i8] c"ERR REMOVE product %d already removed\0A\00", align 1
@.str.18 = private unnamed_addr constant [14 x i8] c"OK REMOVE %d\0A\00", align 1
@.str.19 = private unnamed_addr constant [28 x i8] c"ERR RESTOCK invalid format\0A\00", align 1
@.str.20 = private unnamed_addr constant [34 x i8] c"ERR RESTOCK qty must be positive\0A\00", align 1
@.str.21 = private unnamed_addr constant [45 x i8] c"ERR RESTOCK product %d not found or removed\0A\00", align 1
@.str.22 = private unnamed_addr constant [28 x i8] c"ERR RESTOCK stock overflow\0A\00", align 1
@.str.23 = private unnamed_addr constant [24 x i8] c"OK RESTOCK %d STOCK=%d\0A\00", align 1
@.str.24 = private unnamed_addr constant [33 x i8] c"ERR UPDATE_PRICE invalid format\0A\00", align 1
@.str.25 = private unnamed_addr constant [50 x i8] c"ERR UPDATE_PRICE product %d not found or removed\0A\00", align 1
@.str.26 = private unnamed_addr constant [26 x i8] c"OK UPDATE_PRICE %d PRICE=\00", align 1
@.str.27 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.28 = private unnamed_addr constant [20 x i8] c"EMPTY PRODUCT_LIST\0A\00", align 1
@.str.29 = private unnamed_addr constant [32 x i8] c"ERR SEARCH_NAME invalid format\0A\00", align 1
@.str.30 = private unnamed_addr constant [18 x i8] c"NO_MATCH NAME %s\0A\00", align 1
@.str.31 = private unnamed_addr constant [36 x i8] c"ERR SEARCH_CATEGORY invalid format\0A\00", align 1
@.str.32 = private unnamed_addr constant [22 x i8] c"NO_MATCH CATEGORY %s\0A\00", align 1
@.str.33 = private unnamed_addr constant [30 x i8] c"ERR LOW_STOCK invalid format\0A\00", align 1
@.str.34 = private unnamed_addr constant [20 x i8] c"NO_LOW_STOCK <= %d\0A\00", align 1
@.str.35 = private unnamed_addr constant [25 x i8] c"ERR SORT invalid format\0A\00", align 1
@.str.36 = private unnamed_addr constant [10 x i8] c"PRICE_ASC\00", align 1
@.str.37 = private unnamed_addr constant [11 x i8] c"PRICE_DESC\00", align 1
@.str.38 = private unnamed_addr constant [10 x i8] c"STOCK_ASC\00", align 1
@.str.39 = private unnamed_addr constant [10 x i8] c"SOLD_DESC\00", align 1
@.str.40 = private unnamed_addr constant [9 x i8] c"NAME_ASC\00", align 1
@.str.41 = private unnamed_addr constant [26 x i8] c"ERR SORT unknown mode %s\0A\00", align 1
@.str.42 = private unnamed_addr constant [12 x i8] c"OK SORT %s\0A\00", align 1
@.str.43 = private unnamed_addr constant [5 x i8] c"NONE\00", align 1
@.str.44 = private unnamed_addr constant [6 x i8] c"VIP10\00", align 1
@.str.45 = private unnamed_addr constant [7 x i8] c"BULK15\00", align 1
@.str.46 = private unnamed_addr constant [9 x i8] c"FREESHIP\00", align 1
@.str.47 = private unnamed_addr constant [46 x i8] c"ORDER %d | CUSTOMER=%s | ITEMS=%d | SUBTOTAL=\00", align 1
@.str.48 = private unnamed_addr constant [13 x i8] c" | DISCOUNT=\00", align 1
@.str.49 = private unnamed_addr constant [13 x i8] c" | SHIPPING=\00", align 1
@.str.50 = private unnamed_addr constant [8 x i8] c" | TAX=\00", align 1
@.str.51 = private unnamed_addr constant [10 x i8] c" | TOTAL=\00", align 1
@.str.52 = private unnamed_addr constant [14 x i8] c" | STATUS=%s\0A\00", align 1
@.str.53 = private unnamed_addr constant [10 x i8] c"CANCELLED\00", align 1
@.str.54 = private unnamed_addr constant [5 x i8] c"PAID\00", align 1
@.str.55 = private unnamed_addr constant [17 x i8] c"ORDER_DETAIL %d\0A\00", align 1
@.str.56 = private unnamed_addr constant [13 x i8] c"CUSTOMER %s\0A\00", align 1
@.str.57 = private unnamed_addr constant [18 x i8] c"DISCOUNT_CODE %s\0A\00", align 1
@.str.58 = private unnamed_addr constant [11 x i8] c"STATUS %s\0A\00", align 1
@.str.59 = private unnamed_addr constant [7 x i8] c"ITEMS\0A\00", align 1
@.str.60 = private unnamed_addr constant [25 x i8] c"%d | %s | QTY=%d | UNIT=\00", align 1
@.str.61 = private unnamed_addr constant [9 x i8] c" | LINE=\00", align 1
@.str.62 = private unnamed_addr constant [10 x i8] c"SUBTOTAL \00", align 1
@.str.63 = private unnamed_addr constant [10 x i8] c"DISCOUNT \00", align 1
@.str.64 = private unnamed_addr constant [10 x i8] c"SHIPPING \00", align 1
@.str.65 = private unnamed_addr constant [5 x i8] c"TAX \00", align 1
@.str.66 = private unnamed_addr constant [7 x i8] c"TOTAL \00", align 1
@.str.67 = private unnamed_addr constant [61 x i8] c"ERR BUY needs 3 fields: BUY|customer|discount|id:qty,id:qty\0A\00", align 1
@.str.68 = private unnamed_addr constant [26 x i8] c"ERR BUY invalid customer\0A\00", align 1
@.str.69 = private unnamed_addr constant [31 x i8] c"ERR BUY invalid discount code\0A\00", align 1
@.str.70 = private unnamed_addr constant [20 x i8] c"ERR BUY empty cart\0A\00", align 1
@.str.71 = private unnamed_addr constant [28 x i8] c"ERR BUY order storage full\0A\00", align 1
@.str.72 = private unnamed_addr constant [34 x i8] c"ERR BUY unknown discount code %s\0A\00", align 1
@.str.73 = private unnamed_addr constant [2 x i8] c",\00", align 1
@.str.74 = private unnamed_addr constant [23 x i8] c"ERR BUY bad cart item\0A\00", align 1
@.str.75 = private unnamed_addr constant [41 x i8] c"ERR BUY product %d not found or removed\0A\00", align 1
@.str.76 = private unnamed_addr constant [65 x i8] c"ERR BUY product %d insufficient stock requested=%d available=%d\0A\00", align 1
@.str.77 = private unnamed_addr constant [33 x i8] c"ERR BUY too many distinct items\0A\00", align 1
@.str.78 = private unnamed_addr constant [8 x i8] c"OK BUY \00", align 1
@.str.79 = private unnamed_addr constant [43 x i8] c"NOTICE BULK15 requires subtotal >= 500.00\0A\00", align 1
@.str.80 = private unnamed_addr constant [27 x i8] c"ERR CANCEL invalid format\0A\00", align 1
@.str.81 = private unnamed_addr constant [31 x i8] c"ERR CANCEL order %d not found\0A\00", align 1
@.str.82 = private unnamed_addr constant [39 x i8] c"ERR CANCEL order %d already cancelled\0A\00", align 1
@.str.83 = private unnamed_addr constant [29 x i8] c"OK CANCEL %d REFUNDED_STOCK\0A\00", align 1
@.str.84 = private unnamed_addr constant [26 x i8] c"ERR ORDER invalid format\0A\00", align 1
@.str.85 = private unnamed_addr constant [24 x i8] c"ERR ORDER %d not found\0A\00", align 1
@.str.86 = private unnamed_addr constant [18 x i8] c"EMPTY ORDER_LIST\0A\00", align 1
@.str.87 = private unnamed_addr constant [8 x i8] c"REPORT\0A\00", align 1
@.str.88 = private unnamed_addr constant [16 x i8] c"PAID_ORDERS %d\0A\00", align 1
@.str.89 = private unnamed_addr constant [21 x i8] c"CANCELLED_ORDERS %d\0A\00", align 1
@.str.90 = private unnamed_addr constant [15 x i8] c"UNITS_SOLD %d\0A\00", align 1
@.str.91 = private unnamed_addr constant [7 x i8] c"GROSS \00", align 1
@.str.92 = private unnamed_addr constant [13 x i8] c"NET_REVENUE \00", align 1
@.str.93 = private unnamed_addr constant [17 x i8] c"INVENTORY_VALUE \00", align 1
@.str.94 = private unnamed_addr constant [18 x i8] c"TOP_PRODUCT NONE\0A\00", align 1
@.str.95 = private unnamed_addr constant [24 x i8] c"TOP_PRODUCT %d SOLD=%d\0A\00", align 1
@.str.96 = private unnamed_addr constant [40 x i8] c"ERR SAVE invalid format: SAVE|filename\0A\00", align 1
@.str.97 = private unnamed_addr constant [2 x i8] c"w\00", align 1
@.str.98 = private unnamed_addr constant [25 x i8] c"ERR SAVE cannot open %s\0A\00", align 1
@.str.99 = private unnamed_addr constant [13 x i8] c"PRODUCTS %d\0A\00", align 1
@.str.100 = private unnamed_addr constant [24 x i8] c"%d|%s|%s|%lld|%d|%d|%d\0A\00", align 1
@.str.101 = private unnamed_addr constant [11 x i8] c"ORDERS %d\0A\00", align 1
@.str.102 = private unnamed_addr constant [41 x i8] c"%d|%s|%s|%d|%lld|%lld|%lld|%lld|%lld|%d\0A\00", align 1
@.str.103 = private unnamed_addr constant [20 x i8] c"%d|%s|%d|%lld|%lld\0A\00", align 1
@.str.104 = private unnamed_addr constant [12 x i8] c"OK SAVE %s\0A\00", align 1
@.str.105 = private unnamed_addr constant [27 x i8] c"ERR LINE %d empty command\0A\00", align 1
@.str.106 = private unnamed_addr constant [8 x i8] c">>> %s\0A\00", align 1
@.str.107 = private unnamed_addr constant [4 x i8] c"ADD\00", align 1
@.str.108 = private unnamed_addr constant [7 x i8] c"REMOVE\00", align 1
@.str.109 = private unnamed_addr constant [8 x i8] c"RESTOCK\00", align 1
@.str.110 = private unnamed_addr constant [13 x i8] c"UPDATE_PRICE\00", align 1
@.str.111 = private unnamed_addr constant [5 x i8] c"LIST\00", align 1
@.str.112 = private unnamed_addr constant [12 x i8] c"SEARCH_NAME\00", align 1
@.str.113 = private unnamed_addr constant [16 x i8] c"SEARCH_CATEGORY\00", align 1
@.str.114 = private unnamed_addr constant [10 x i8] c"LOW_STOCK\00", align 1
@.str.115 = private unnamed_addr constant [5 x i8] c"SORT\00", align 1
@.str.116 = private unnamed_addr constant [4 x i8] c"BUY\00", align 1
@.str.117 = private unnamed_addr constant [7 x i8] c"CANCEL\00", align 1
@.str.118 = private unnamed_addr constant [6 x i8] c"ORDER\00", align 1
@.str.119 = private unnamed_addr constant [7 x i8] c"ORDERS\00", align 1
@.str.120 = private unnamed_addr constant [7 x i8] c"REPORT\00", align 1
@.str.121 = private unnamed_addr constant [5 x i8] c"SAVE\00", align 1
@.str.122 = private unnamed_addr constant [24 x i8] c"ERR UNKNOWN_COMMAND %s\0A\00", align 1
@stdin = external global ptr, align 8
@.str.123 = private unnamed_addr constant [27 x i8] c"ERR missing command count\0A\00", align 1
@.str.124 = private unnamed_addr constant [27 x i8] c"ERR invalid command count\0A\00", align 1
@.str.125 = private unnamed_addr constant [28 x i8] c"SHOP_COMMAND_IO_START Q=%d\0A\00", align 1
@.str.126 = private unnamed_addr constant [32 x i8] c"ERR missing command at line %d\0A\00", align 1
@.str.127 = private unnamed_addr constant [43 x i8] c"SHOP_COMMAND_IO_END PRODUCTS=%d ORDERS=%d\0A\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @trim(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  store i32 0, ptr %4, align 4
  br label %5

5:                                                ; preds = %30, %1
  %6 = load ptr, ptr %2, align 8
  %7 = load i32, ptr %4, align 4
  %8 = sext i32 %7 to i64
  %9 = getelementptr inbounds i8, ptr %6, i64 %8
  %10 = load i8, ptr %9, align 1
  %11 = sext i8 %10 to i32
  %12 = icmp ne i32 %11, 0
  br i1 %12, label %13, label %28

13:                                               ; preds = %5
  %14 = call ptr @__ctype_b_loc() #7
  %15 = load ptr, ptr %14, align 8
  %16 = load ptr, ptr %2, align 8
  %17 = load i32, ptr %4, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i8, ptr %16, i64 %18
  %20 = load i8, ptr %19, align 1
  %21 = zext i8 %20 to i32
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i16, ptr %15, i64 %22
  %24 = load i16, ptr %23, align 2
  %25 = zext i16 %24 to i32
  %26 = and i32 %25, 8192
  %27 = icmp ne i32 %26, 0
  br label %28

28:                                               ; preds = %13, %5
  %29 = phi i1 [ false, %5 ], [ %27, %13 ]
  br i1 %29, label %30, label %33

30:                                               ; preds = %28
  %31 = load i32, ptr %4, align 4
  %32 = add nsw i32 %31, 1
  store i32 %32, ptr %4, align 4
  br label %5, !llvm.loop !6

33:                                               ; preds = %28
  %34 = load i32, ptr %4, align 4
  %35 = icmp sgt i32 %34, 0
  br i1 %35, label %36, label %48

36:                                               ; preds = %33
  %37 = load ptr, ptr %2, align 8
  %38 = load ptr, ptr %2, align 8
  %39 = load i32, ptr %4, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds i8, ptr %38, i64 %40
  %42 = load ptr, ptr %2, align 8
  %43 = load i32, ptr %4, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds i8, ptr %42, i64 %44
  %46 = call i64 @strlen(ptr noundef %45) #8
  %47 = add i64 %46, 1
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %37, ptr align 1 %41, i64 %47, i1 false)
  br label %48

48:                                               ; preds = %36, %33
  %49 = load ptr, ptr %2, align 8
  %50 = call i64 @strlen(ptr noundef %49) #8
  %51 = trunc i64 %50 to i32
  store i32 %51, ptr %3, align 4
  br label %52

52:                                               ; preds = %73, %48
  %53 = load i32, ptr %3, align 4
  %54 = icmp sgt i32 %53, 0
  br i1 %54, label %55, label %71

55:                                               ; preds = %52
  %56 = call ptr @__ctype_b_loc() #7
  %57 = load ptr, ptr %56, align 8
  %58 = load ptr, ptr %2, align 8
  %59 = load i32, ptr %3, align 4
  %60 = sub nsw i32 %59, 1
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds i8, ptr %58, i64 %61
  %63 = load i8, ptr %62, align 1
  %64 = zext i8 %63 to i32
  %65 = sext i32 %64 to i64
  %66 = getelementptr inbounds i16, ptr %57, i64 %65
  %67 = load i16, ptr %66, align 2
  %68 = zext i16 %67 to i32
  %69 = and i32 %68, 8192
  %70 = icmp ne i32 %69, 0
  br label %71

71:                                               ; preds = %55, %52
  %72 = phi i1 [ false, %52 ], [ %70, %55 ]
  br i1 %72, label %73, label %81

73:                                               ; preds = %71
  %74 = load ptr, ptr %2, align 8
  %75 = load i32, ptr %3, align 4
  %76 = sub nsw i32 %75, 1
  %77 = sext i32 %76 to i64
  %78 = getelementptr inbounds i8, ptr %74, i64 %77
  store i8 0, ptr %78, align 1
  %79 = load i32, ptr %3, align 4
  %80 = add nsw i32 %79, -1
  store i32 %80, ptr %3, align 4
  br label %52, !llvm.loop !8

81:                                               ; preds = %71
  ret void
}

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #1

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr writeonly captures(none), ptr readonly captures(none), i64, i1 immarg) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @upperString(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %24, %1
  %5 = load ptr, ptr %2, align 8
  %6 = load i32, ptr %3, align 4
  %7 = sext i32 %6 to i64
  %8 = getelementptr inbounds i8, ptr %5, i64 %7
  %9 = load i8, ptr %8, align 1
  %10 = icmp ne i8 %9, 0
  br i1 %10, label %11, label %27

11:                                               ; preds = %4
  %12 = load ptr, ptr %2, align 8
  %13 = load i32, ptr %3, align 4
  %14 = sext i32 %13 to i64
  %15 = getelementptr inbounds i8, ptr %12, i64 %14
  %16 = load i8, ptr %15, align 1
  %17 = zext i8 %16 to i32
  %18 = call i32 @toupper(i32 noundef %17) #8
  %19 = trunc i32 %18 to i8
  %20 = load ptr, ptr %2, align 8
  %21 = load i32, ptr %3, align 4
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i8, ptr %20, i64 %22
  store i8 %19, ptr %23, align 1
  br label %24

24:                                               ; preds = %11
  %25 = load i32, ptr %3, align 4
  %26 = add nsw i32 %25, 1
  store i32 %26, ptr %3, align 4
  br label %4, !llvm.loop !9

27:                                               ; preds = %4
  ret void
}

; Function Attrs: nounwind willreturn memory(read)
declare i32 @toupper(i32 noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @equalsIgnoreCase(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  br label %6

6:                                                ; preds = %29, %2
  %7 = load ptr, ptr %4, align 8
  %8 = load i8, ptr %7, align 1
  %9 = sext i8 %8 to i32
  %10 = icmp ne i32 %9, 0
  br i1 %10, label %11, label %16

11:                                               ; preds = %6
  %12 = load ptr, ptr %5, align 8
  %13 = load i8, ptr %12, align 1
  %14 = sext i8 %13 to i32
  %15 = icmp ne i32 %14, 0
  br label %16

16:                                               ; preds = %11, %6
  %17 = phi i1 [ false, %6 ], [ %15, %11 ]
  br i1 %17, label %18, label %34

18:                                               ; preds = %16
  %19 = load ptr, ptr %4, align 8
  %20 = load i8, ptr %19, align 1
  %21 = zext i8 %20 to i32
  %22 = call i32 @toupper(i32 noundef %21) #8
  %23 = load ptr, ptr %5, align 8
  %24 = load i8, ptr %23, align 1
  %25 = zext i8 %24 to i32
  %26 = call i32 @toupper(i32 noundef %25) #8
  %27 = icmp ne i32 %22, %26
  br i1 %27, label %28, label %29

28:                                               ; preds = %18
  store i32 0, ptr %3, align 4
  br label %47

29:                                               ; preds = %18
  %30 = load ptr, ptr %4, align 8
  %31 = getelementptr inbounds nuw i8, ptr %30, i32 1
  store ptr %31, ptr %4, align 8
  %32 = load ptr, ptr %5, align 8
  %33 = getelementptr inbounds nuw i8, ptr %32, i32 1
  store ptr %33, ptr %5, align 8
  br label %6, !llvm.loop !10

34:                                               ; preds = %16
  %35 = load ptr, ptr %4, align 8
  %36 = load i8, ptr %35, align 1
  %37 = sext i8 %36 to i32
  %38 = icmp eq i32 %37, 0
  br i1 %38, label %39, label %44

39:                                               ; preds = %34
  %40 = load ptr, ptr %5, align 8
  %41 = load i8, ptr %40, align 1
  %42 = sext i8 %41 to i32
  %43 = icmp eq i32 %42, 0
  br label %44

44:                                               ; preds = %39, %34
  %45 = phi i1 [ false, %34 ], [ %43, %39 ]
  %46 = zext i1 %45 to i32
  store i32 %46, ptr %3, align 4
  br label %47

47:                                               ; preds = %44, %28
  %48 = load i32, ptr %3, align 4
  ret i32 %48
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @containsIgnoreCase(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %11 = load ptr, ptr %4, align 8
  %12 = call i64 @strlen(ptr noundef %11) #8
  %13 = trunc i64 %12 to i32
  store i32 %13, ptr %6, align 4
  %14 = load ptr, ptr %5, align 8
  %15 = call i64 @strlen(ptr noundef %14) #8
  %16 = trunc i64 %15 to i32
  store i32 %16, ptr %7, align 4
  %17 = load i32, ptr %7, align 4
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %19, label %20

19:                                               ; preds = %2
  store i32 1, ptr %3, align 4
  br label %69

20:                                               ; preds = %2
  %21 = load i32, ptr %7, align 4
  %22 = load i32, ptr %6, align 4
  %23 = icmp sgt i32 %21, %22
  br i1 %23, label %24, label %25

24:                                               ; preds = %20
  store i32 0, ptr %3, align 4
  br label %69

25:                                               ; preds = %20
  store i32 0, ptr %8, align 4
  br label %26

26:                                               ; preds = %65, %25
  %27 = load i32, ptr %8, align 4
  %28 = load i32, ptr %6, align 4
  %29 = load i32, ptr %7, align 4
  %30 = sub nsw i32 %28, %29
  %31 = icmp sle i32 %27, %30
  br i1 %31, label %32, label %68

32:                                               ; preds = %26
  store i32 1, ptr %10, align 4
  store i32 0, ptr %9, align 4
  br label %33

33:                                               ; preds = %57, %32
  %34 = load i32, ptr %9, align 4
  %35 = load i32, ptr %7, align 4
  %36 = icmp slt i32 %34, %35
  br i1 %36, label %37, label %60

37:                                               ; preds = %33
  %38 = load ptr, ptr %4, align 8
  %39 = load i32, ptr %8, align 4
  %40 = load i32, ptr %9, align 4
  %41 = add nsw i32 %39, %40
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds i8, ptr %38, i64 %42
  %44 = load i8, ptr %43, align 1
  %45 = zext i8 %44 to i32
  %46 = call i32 @toupper(i32 noundef %45) #8
  %47 = load ptr, ptr %5, align 8
  %48 = load i32, ptr %9, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds i8, ptr %47, i64 %49
  %51 = load i8, ptr %50, align 1
  %52 = zext i8 %51 to i32
  %53 = call i32 @toupper(i32 noundef %52) #8
  %54 = icmp ne i32 %46, %53
  br i1 %54, label %55, label %56

55:                                               ; preds = %37
  store i32 0, ptr %10, align 4
  br label %60

56:                                               ; preds = %37
  br label %57

57:                                               ; preds = %56
  %58 = load i32, ptr %9, align 4
  %59 = add nsw i32 %58, 1
  store i32 %59, ptr %9, align 4
  br label %33, !llvm.loop !11

60:                                               ; preds = %55, %33
  %61 = load i32, ptr %10, align 4
  %62 = icmp ne i32 %61, 0
  br i1 %62, label %63, label %64

63:                                               ; preds = %60
  store i32 1, ptr %3, align 4
  br label %69

64:                                               ; preds = %60
  br label %65

65:                                               ; preds = %64
  %66 = load i32, ptr %8, align 4
  %67 = add nsw i32 %66, 1
  store i32 %67, ptr %8, align 4
  br label %26, !llvm.loop !12

68:                                               ; preds = %26
  store i32 0, ptr %3, align 4
  br label %69

69:                                               ; preds = %68, %63, %24, %19
  %70 = load i32, ptr %3, align 4
  ret i32 %70
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printMoney(i64 noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 %0, ptr %2, align 8
  %3 = load i64, ptr %2, align 8
  %4 = icmp slt i64 %3, 0
  br i1 %4, label %5, label %9

5:                                                ; preds = %1
  %6 = call i32 @putchar(i32 noundef 45)
  %7 = load i64, ptr %2, align 8
  %8 = sub nsw i64 0, %7
  store i64 %8, ptr %2, align 8
  br label %9

9:                                                ; preds = %5, %1
  %10 = load i64, ptr %2, align 8
  %11 = sdiv i64 %10, 100
  %12 = load i64, ptr %2, align 8
  %13 = srem i64 %12, 100
  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str, i64 noundef %11, i64 noundef %13)
  ret void
}

declare i32 @putchar(i32 noundef) #4

declare i32 @printf(ptr noundef, ...) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @parseIntStrict(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i64 0, ptr %6, align 8
  store i32 1, ptr %7, align 4
  store i32 0, ptr %8, align 4
  %9 = load ptr, ptr %4, align 8
  %10 = icmp eq ptr %9, null
  br i1 %10, label %17, label %11

11:                                               ; preds = %2
  %12 = load ptr, ptr %4, align 8
  %13 = getelementptr inbounds i8, ptr %12, i64 0
  %14 = load i8, ptr %13, align 1
  %15 = sext i8 %14 to i32
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %18

17:                                               ; preds = %11, %2
  store i32 0, ptr %3, align 4
  br label %97

18:                                               ; preds = %11
  %19 = load ptr, ptr %4, align 8
  %20 = load i32, ptr %8, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds i8, ptr %19, i64 %21
  %23 = load i8, ptr %22, align 1
  %24 = sext i8 %23 to i32
  %25 = icmp eq i32 %24, 45
  br i1 %25, label %26, label %37

26:                                               ; preds = %18
  store i32 -1, ptr %7, align 4
  %27 = load i32, ptr %8, align 4
  %28 = add nsw i32 %27, 1
  store i32 %28, ptr %8, align 4
  %29 = load ptr, ptr %4, align 8
  %30 = load i32, ptr %8, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds i8, ptr %29, i64 %31
  %33 = load i8, ptr %32, align 1
  %34 = icmp ne i8 %33, 0
  br i1 %34, label %36, label %35

35:                                               ; preds = %26
  store i32 0, ptr %3, align 4
  br label %97

36:                                               ; preds = %26
  br label %37

37:                                               ; preds = %36, %18
  br label %38

38:                                               ; preds = %87, %37
  %39 = load ptr, ptr %4, align 8
  %40 = load i32, ptr %8, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds i8, ptr %39, i64 %41
  %43 = load i8, ptr %42, align 1
  %44 = icmp ne i8 %43, 0
  br i1 %44, label %45, label %90

45:                                               ; preds = %38
  %46 = call ptr @__ctype_b_loc() #7
  %47 = load ptr, ptr %46, align 8
  %48 = load ptr, ptr %4, align 8
  %49 = load i32, ptr %8, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds i8, ptr %48, i64 %50
  %52 = load i8, ptr %51, align 1
  %53 = zext i8 %52 to i32
  %54 = sext i32 %53 to i64
  %55 = getelementptr inbounds i16, ptr %47, i64 %54
  %56 = load i16, ptr %55, align 2
  %57 = zext i16 %56 to i32
  %58 = and i32 %57, 2048
  %59 = icmp ne i32 %58, 0
  br i1 %59, label %61, label %60

60:                                               ; preds = %45
  store i32 0, ptr %3, align 4
  br label %97

61:                                               ; preds = %45
  %62 = load i64, ptr %6, align 8
  %63 = mul nsw i64 %62, 10
  %64 = load ptr, ptr %4, align 8
  %65 = load i32, ptr %8, align 4
  %66 = sext i32 %65 to i64
  %67 = getelementptr inbounds i8, ptr %64, i64 %66
  %68 = load i8, ptr %67, align 1
  %69 = sext i8 %68 to i32
  %70 = sub nsw i32 %69, 48
  %71 = sext i32 %70 to i64
  %72 = add nsw i64 %63, %71
  store i64 %72, ptr %6, align 8
  %73 = load i32, ptr %7, align 4
  %74 = icmp eq i32 %73, 1
  br i1 %74, label %75, label %79

75:                                               ; preds = %61
  %76 = load i64, ptr %6, align 8
  %77 = icmp sgt i64 %76, 2147483647
  br i1 %77, label %78, label %79

78:                                               ; preds = %75
  store i32 0, ptr %3, align 4
  br label %97

79:                                               ; preds = %75, %61
  %80 = load i32, ptr %7, align 4
  %81 = icmp eq i32 %80, -1
  br i1 %81, label %82, label %87

82:                                               ; preds = %79
  %83 = load i64, ptr %6, align 8
  %84 = sub nsw i64 0, %83
  %85 = icmp slt i64 %84, -2147483648
  br i1 %85, label %86, label %87

86:                                               ; preds = %82
  store i32 0, ptr %3, align 4
  br label %97

87:                                               ; preds = %82, %79
  %88 = load i32, ptr %8, align 4
  %89 = add nsw i32 %88, 1
  store i32 %89, ptr %8, align 4
  br label %38, !llvm.loop !13

90:                                               ; preds = %38
  %91 = load i64, ptr %6, align 8
  %92 = load i32, ptr %7, align 4
  %93 = sext i32 %92 to i64
  %94 = mul nsw i64 %91, %93
  %95 = trunc i64 %94 to i32
  %96 = load ptr, ptr %5, align 8
  store i32 %95, ptr %96, align 4
  store i32 1, ptr %3, align 4
  br label %97

97:                                               ; preds = %90, %86, %78, %60, %35, %17
  %98 = load i32, ptr %3, align 4
  ret i32 %98
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @parseMoneyStrict(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i64 0, ptr %6, align 8
  store i64 0, ptr %7, align 8
  store i32 0, ptr %8, align 4
  store i32 0, ptr %9, align 4
  store i32 0, ptr %10, align 4
  %11 = load ptr, ptr %4, align 8
  %12 = icmp eq ptr %11, null
  br i1 %12, label %19, label %13

13:                                               ; preds = %2
  %14 = load ptr, ptr %4, align 8
  %15 = getelementptr inbounds i8, ptr %14, i64 0
  %16 = load i8, ptr %15, align 1
  %17 = sext i8 %16 to i32
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %19, label %20

19:                                               ; preds = %13, %2
  store i32 0, ptr %3, align 4
  br label %128

20:                                               ; preds = %13
  %21 = load ptr, ptr %4, align 8
  %22 = getelementptr inbounds i8, ptr %21, i64 0
  %23 = load i8, ptr %22, align 1
  %24 = sext i8 %23 to i32
  %25 = icmp eq i32 %24, 45
  br i1 %25, label %26, label %27

26:                                               ; preds = %20
  store i32 0, ptr %3, align 4
  br label %128

27:                                               ; preds = %20
  br label %28

28:                                               ; preds = %103, %27
  %29 = load ptr, ptr %4, align 8
  %30 = load i32, ptr %8, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds i8, ptr %29, i64 %31
  %33 = load i8, ptr %32, align 1
  %34 = icmp ne i8 %33, 0
  br i1 %34, label %35, label %106

35:                                               ; preds = %28
  %36 = load ptr, ptr %4, align 8
  %37 = load i32, ptr %8, align 4
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds i8, ptr %36, i64 %38
  %40 = load i8, ptr %39, align 1
  %41 = sext i8 %40 to i32
  %42 = icmp eq i32 %41, 46
  br i1 %42, label %43, label %48

43:                                               ; preds = %35
  %44 = load i32, ptr %9, align 4
  %45 = icmp ne i32 %44, 0
  br i1 %45, label %46, label %47

46:                                               ; preds = %43
  store i32 0, ptr %3, align 4
  br label %128

47:                                               ; preds = %43
  store i32 1, ptr %9, align 4
  br label %103

48:                                               ; preds = %35
  %49 = call ptr @__ctype_b_loc() #7
  %50 = load ptr, ptr %49, align 8
  %51 = load ptr, ptr %4, align 8
  %52 = load i32, ptr %8, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds i8, ptr %51, i64 %53
  %55 = load i8, ptr %54, align 1
  %56 = zext i8 %55 to i32
  %57 = sext i32 %56 to i64
  %58 = getelementptr inbounds i16, ptr %50, i64 %57
  %59 = load i16, ptr %58, align 2
  %60 = zext i16 %59 to i32
  %61 = and i32 %60, 2048
  %62 = icmp ne i32 %61, 0
  br i1 %62, label %63, label %101

63:                                               ; preds = %48
  %64 = load i32, ptr %9, align 4
  %65 = icmp ne i32 %64, 0
  br i1 %65, label %82, label %66

66:                                               ; preds = %63
  %67 = load i64, ptr %6, align 8
  %68 = mul nsw i64 %67, 10
  %69 = load ptr, ptr %4, align 8
  %70 = load i32, ptr %8, align 4
  %71 = sext i32 %70 to i64
  %72 = getelementptr inbounds i8, ptr %69, i64 %71
  %73 = load i8, ptr %72, align 1
  %74 = sext i8 %73 to i32
  %75 = sub nsw i32 %74, 48
  %76 = sext i32 %75 to i64
  %77 = add nsw i64 %68, %76
  store i64 %77, ptr %6, align 8
  %78 = load i64, ptr %6, align 8
  %79 = icmp sgt i64 %78, 9000000000000
  br i1 %79, label %80, label %81

80:                                               ; preds = %66
  store i32 0, ptr %3, align 4
  br label %128

81:                                               ; preds = %66
  br label %100

82:                                               ; preds = %63
  %83 = load i32, ptr %10, align 4
  %84 = icmp sge i32 %83, 2
  br i1 %84, label %85, label %86

85:                                               ; preds = %82
  store i32 0, ptr %3, align 4
  br label %128

86:                                               ; preds = %82
  %87 = load i64, ptr %7, align 8
  %88 = mul nsw i64 %87, 10
  %89 = load ptr, ptr %4, align 8
  %90 = load i32, ptr %8, align 4
  %91 = sext i32 %90 to i64
  %92 = getelementptr inbounds i8, ptr %89, i64 %91
  %93 = load i8, ptr %92, align 1
  %94 = sext i8 %93 to i32
  %95 = sub nsw i32 %94, 48
  %96 = sext i32 %95 to i64
  %97 = add nsw i64 %88, %96
  store i64 %97, ptr %7, align 8
  %98 = load i32, ptr %10, align 4
  %99 = add nsw i32 %98, 1
  store i32 %99, ptr %10, align 4
  br label %100

100:                                              ; preds = %86, %81
  br label %102

101:                                              ; preds = %48
  store i32 0, ptr %3, align 4
  br label %128

102:                                              ; preds = %100
  br label %103

103:                                              ; preds = %102, %47
  %104 = load i32, ptr %8, align 4
  %105 = add nsw i32 %104, 1
  store i32 %105, ptr %8, align 4
  br label %28, !llvm.loop !14

106:                                              ; preds = %28
  %107 = load i32, ptr %9, align 4
  %108 = icmp ne i32 %107, 0
  br i1 %108, label %109, label %115

109:                                              ; preds = %106
  %110 = load i32, ptr %10, align 4
  %111 = icmp eq i32 %110, 1
  br i1 %111, label %112, label %115

112:                                              ; preds = %109
  %113 = load i64, ptr %7, align 8
  %114 = mul nsw i64 %113, 10
  store i64 %114, ptr %7, align 8
  br label %115

115:                                              ; preds = %112, %109, %106
  %116 = load i32, ptr %9, align 4
  %117 = icmp ne i32 %116, 0
  br i1 %117, label %118, label %122

118:                                              ; preds = %115
  %119 = load i32, ptr %10, align 4
  %120 = icmp eq i32 %119, 0
  br i1 %120, label %121, label %122

121:                                              ; preds = %118
  store i64 0, ptr %7, align 8
  br label %122

122:                                              ; preds = %121, %118, %115
  %123 = load i64, ptr %6, align 8
  %124 = mul nsw i64 %123, 100
  %125 = load i64, ptr %7, align 8
  %126 = add nsw i64 %124, %125
  %127 = load ptr, ptr %5, align 8
  store i64 %126, ptr %127, align 8
  store i32 1, ptr %3, align 4
  br label %128

128:                                              ; preds = %122, %101, %85, %80, %46, %26, %19
  %129 = load i32, ptr %3, align 4
  ret i32 %129
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @splitPipe(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  %10 = load ptr, ptr %4, align 8
  store ptr %10, ptr %8, align 8
  %11 = load ptr, ptr %8, align 8
  %12 = load ptr, ptr %5, align 8
  %13 = load i32, ptr %7, align 4
  %14 = add nsw i32 %13, 1
  store i32 %14, ptr %7, align 4
  %15 = sext i32 %13 to i64
  %16 = getelementptr inbounds ptr, ptr %12, i64 %15
  store ptr %11, ptr %16, align 8
  br label %17

17:                                               ; preds = %42, %3
  %18 = load ptr, ptr %8, align 8
  %19 = load i8, ptr %18, align 1
  %20 = sext i8 %19 to i32
  %21 = icmp ne i32 %20, 0
  br i1 %21, label %22, label %26

22:                                               ; preds = %17
  %23 = load i32, ptr %7, align 4
  %24 = load i32, ptr %6, align 4
  %25 = icmp slt i32 %23, %24
  br label %26

26:                                               ; preds = %22, %17
  %27 = phi i1 [ false, %17 ], [ %25, %22 ]
  br i1 %27, label %28, label %45

28:                                               ; preds = %26
  %29 = load ptr, ptr %8, align 8
  %30 = load i8, ptr %29, align 1
  %31 = sext i8 %30 to i32
  %32 = icmp eq i32 %31, 124
  br i1 %32, label %33, label %42

33:                                               ; preds = %28
  %34 = load ptr, ptr %8, align 8
  store i8 0, ptr %34, align 1
  %35 = load ptr, ptr %8, align 8
  %36 = getelementptr inbounds i8, ptr %35, i64 1
  %37 = load ptr, ptr %5, align 8
  %38 = load i32, ptr %7, align 4
  %39 = add nsw i32 %38, 1
  store i32 %39, ptr %7, align 4
  %40 = sext i32 %38 to i64
  %41 = getelementptr inbounds ptr, ptr %37, i64 %40
  store ptr %36, ptr %41, align 8
  br label %42

42:                                               ; preds = %33, %28
  %43 = load ptr, ptr %8, align 8
  %44 = getelementptr inbounds nuw i8, ptr %43, i32 1
  store ptr %44, ptr %8, align 8
  br label %17, !llvm.loop !15

45:                                               ; preds = %26
  store i32 0, ptr %9, align 4
  br label %46

46:                                               ; preds = %56, %45
  %47 = load i32, ptr %9, align 4
  %48 = load i32, ptr %7, align 4
  %49 = icmp slt i32 %47, %48
  br i1 %49, label %50, label %59

50:                                               ; preds = %46
  %51 = load ptr, ptr %5, align 8
  %52 = load i32, ptr %9, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds ptr, ptr %51, i64 %53
  %55 = load ptr, ptr %54, align 8
  call void @trim(ptr noundef %55)
  br label %56

56:                                               ; preds = %50
  %57 = load i32, ptr %9, align 4
  %58 = add nsw i32 %57, 1
  store i32 %58, ptr %9, align 4
  br label %46, !llvm.loop !16

59:                                               ; preds = %46
  %60 = load i32, ptr %7, align 4
  ret i32 %60
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @findProductIndexById(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 0, ptr %4, align 4
  br label %5

5:                                                ; preds = %20, %1
  %6 = load i32, ptr %4, align 4
  %7 = load i32, ptr @productCount, align 4
  %8 = icmp slt i32 %6, %7
  br i1 %8, label %9, label %23

9:                                                ; preds = %5
  %10 = load i32, ptr %4, align 4
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %11
  %13 = getelementptr inbounds nuw %struct.Product, ptr %12, i32 0, i32 0
  %14 = load i32, ptr %13, align 16
  %15 = load i32, ptr %3, align 4
  %16 = icmp eq i32 %14, %15
  br i1 %16, label %17, label %19

17:                                               ; preds = %9
  %18 = load i32, ptr %4, align 4
  store i32 %18, ptr %2, align 4
  br label %24

19:                                               ; preds = %9
  br label %20

20:                                               ; preds = %19
  %21 = load i32, ptr %4, align 4
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %4, align 4
  br label %5, !llvm.loop !17

23:                                               ; preds = %5
  store i32 -1, ptr %2, align 4
  br label %24

24:                                               ; preds = %23, %17
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @findOrderIndexById(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 0, ptr %4, align 4
  br label %5

5:                                                ; preds = %20, %1
  %6 = load i32, ptr %4, align 4
  %7 = load i32, ptr @orderCount, align 4
  %8 = icmp slt i32 %6, %7
  br i1 %8, label %9, label %23

9:                                                ; preds = %5
  %10 = load i32, ptr %4, align 4
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %11
  %13 = getelementptr inbounds nuw %struct.Order, ptr %12, i32 0, i32 0
  %14 = load i32, ptr %13, align 16
  %15 = load i32, ptr %3, align 4
  %16 = icmp eq i32 %14, %15
  br i1 %16, label %17, label %19

17:                                               ; preds = %9
  %18 = load i32, ptr %4, align 4
  store i32 %18, ptr %2, align 4
  br label %24

19:                                               ; preds = %9
  br label %20

20:                                               ; preds = %19
  %21 = load i32, ptr %4, align 4
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %4, align 4
  br label %5, !llvm.loop !18

23:                                               ; preds = %5
  store i32 -1, ptr %2, align 4
  br label %24

24:                                               ; preds = %23, %17
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printProductHeader() #0 {
  %1 = call i32 (ptr, ...) @printf(ptr noundef @.str.1)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printProduct(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.Product, ptr %3, i32 0, i32 0
  %5 = load i32, ptr %4, align 8
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds nuw %struct.Product, ptr %6, i32 0, i32 1
  %8 = getelementptr inbounds [80 x i8], ptr %7, i64 0, i64 0
  %9 = load ptr, ptr %2, align 8
  %10 = getelementptr inbounds nuw %struct.Product, ptr %9, i32 0, i32 2
  %11 = getelementptr inbounds [50 x i8], ptr %10, i64 0, i64 0
  %12 = call i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef %5, ptr noundef %8, ptr noundef %11)
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 3
  %15 = load i64, ptr %14, align 8
  call void @printMoney(i64 noundef %15)
  %16 = load ptr, ptr %2, align 8
  %17 = getelementptr inbounds nuw %struct.Product, ptr %16, i32 0, i32 4
  %18 = load i32, ptr %17, align 8
  %19 = load ptr, ptr %2, align 8
  %20 = getelementptr inbounds nuw %struct.Product, ptr %19, i32 0, i32 5
  %21 = load i32, ptr %20, align 4
  %22 = load ptr, ptr %2, align 8
  %23 = getelementptr inbounds nuw %struct.Product, ptr %22, i32 0, i32 6
  %24 = load i32, ptr %23, align 8
  %25 = icmp ne i32 %24, 0
  %26 = zext i1 %25 to i64
  %27 = select i1 %25, ptr @.str.4, ptr @.str.5
  %28 = call i32 (ptr, ...) @printf(ptr noundef @.str.3, i32 noundef %18, i32 noundef %21, ptr noundef %27)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdAdd(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %8 = load i32, ptr %4, align 4
  %9 = icmp ne i32 %8, 6
  br i1 %9, label %10, label %12

10:                                               ; preds = %2
  %11 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  br label %134

12:                                               ; preds = %2
  %13 = load ptr, ptr %3, align 8
  %14 = getelementptr inbounds ptr, ptr %13, i64 1
  %15 = load ptr, ptr %14, align 8
  %16 = call i32 @parseIntStrict(ptr noundef %15, ptr noundef %5)
  %17 = icmp ne i32 %16, 0
  br i1 %17, label %18, label %21

18:                                               ; preds = %12
  %19 = load i32, ptr %5, align 4
  %20 = icmp sle i32 %19, 0
  br i1 %20, label %21, label %23

21:                                               ; preds = %18, %12
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  br label %134

23:                                               ; preds = %18
  %24 = load i32, ptr %5, align 4
  %25 = call i32 @findProductIndexById(i32 noundef %24)
  %26 = icmp ne i32 %25, -1
  br i1 %26, label %27, label %30

27:                                               ; preds = %23
  %28 = load i32, ptr %5, align 4
  %29 = call i32 (ptr, ...) @printf(ptr noundef @.str.8, i32 noundef %28)
  br label %134

30:                                               ; preds = %23
  %31 = load ptr, ptr %3, align 8
  %32 = getelementptr inbounds ptr, ptr %31, i64 2
  %33 = load ptr, ptr %32, align 8
  %34 = call i64 @strlen(ptr noundef %33) #8
  %35 = icmp eq i64 %34, 0
  br i1 %35, label %42, label %36

36:                                               ; preds = %30
  %37 = load ptr, ptr %3, align 8
  %38 = getelementptr inbounds ptr, ptr %37, i64 2
  %39 = load ptr, ptr %38, align 8
  %40 = call i64 @strlen(ptr noundef %39) #8
  %41 = icmp uge i64 %40, 80
  br i1 %41, label %42, label %44

42:                                               ; preds = %36, %30
  %43 = call i32 (ptr, ...) @printf(ptr noundef @.str.9)
  br label %134

44:                                               ; preds = %36
  %45 = load ptr, ptr %3, align 8
  %46 = getelementptr inbounds ptr, ptr %45, i64 3
  %47 = load ptr, ptr %46, align 8
  %48 = call i64 @strlen(ptr noundef %47) #8
  %49 = icmp eq i64 %48, 0
  br i1 %49, label %56, label %50

50:                                               ; preds = %44
  %51 = load ptr, ptr %3, align 8
  %52 = getelementptr inbounds ptr, ptr %51, i64 3
  %53 = load ptr, ptr %52, align 8
  %54 = call i64 @strlen(ptr noundef %53) #8
  %55 = icmp uge i64 %54, 50
  br i1 %55, label %56, label %58

56:                                               ; preds = %50, %44
  %57 = call i32 (ptr, ...) @printf(ptr noundef @.str.10)
  br label %134

58:                                               ; preds = %50
  %59 = load ptr, ptr %3, align 8
  %60 = getelementptr inbounds ptr, ptr %59, i64 4
  %61 = load ptr, ptr %60, align 8
  %62 = call i32 @parseMoneyStrict(ptr noundef %61, ptr noundef %7)
  %63 = icmp ne i32 %62, 0
  br i1 %63, label %64, label %67

64:                                               ; preds = %58
  %65 = load i64, ptr %7, align 8
  %66 = icmp sle i64 %65, 0
  br i1 %66, label %67, label %69

67:                                               ; preds = %64, %58
  %68 = call i32 (ptr, ...) @printf(ptr noundef @.str.11)
  br label %134

69:                                               ; preds = %64
  %70 = load ptr, ptr %3, align 8
  %71 = getelementptr inbounds ptr, ptr %70, i64 5
  %72 = load ptr, ptr %71, align 8
  %73 = call i32 @parseIntStrict(ptr noundef %72, ptr noundef %6)
  %74 = icmp ne i32 %73, 0
  br i1 %74, label %75, label %78

75:                                               ; preds = %69
  %76 = load i32, ptr %6, align 4
  %77 = icmp slt i32 %76, 0
  br i1 %77, label %78, label %80

78:                                               ; preds = %75, %69
  %79 = call i32 (ptr, ...) @printf(ptr noundef @.str.12)
  br label %134

80:                                               ; preds = %75
  %81 = load i32, ptr @productCount, align 4
  %82 = icmp sge i32 %81, 1000
  br i1 %82, label %83, label %85

83:                                               ; preds = %80
  %84 = call i32 (ptr, ...) @printf(ptr noundef @.str.13)
  br label %134

85:                                               ; preds = %80
  %86 = load i32, ptr %5, align 4
  %87 = load i32, ptr @productCount, align 4
  %88 = sext i32 %87 to i64
  %89 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %88
  %90 = getelementptr inbounds nuw %struct.Product, ptr %89, i32 0, i32 0
  store i32 %86, ptr %90, align 16
  %91 = load i32, ptr @productCount, align 4
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %92
  %94 = getelementptr inbounds nuw %struct.Product, ptr %93, i32 0, i32 1
  %95 = getelementptr inbounds [80 x i8], ptr %94, i64 0, i64 0
  %96 = load ptr, ptr %3, align 8
  %97 = getelementptr inbounds ptr, ptr %96, i64 2
  %98 = load ptr, ptr %97, align 8
  %99 = call ptr @strcpy(ptr noundef %95, ptr noundef %98) #9
  %100 = load i32, ptr @productCount, align 4
  %101 = sext i32 %100 to i64
  %102 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %101
  %103 = getelementptr inbounds nuw %struct.Product, ptr %102, i32 0, i32 2
  %104 = getelementptr inbounds [50 x i8], ptr %103, i64 0, i64 0
  %105 = load ptr, ptr %3, align 8
  %106 = getelementptr inbounds ptr, ptr %105, i64 3
  %107 = load ptr, ptr %106, align 8
  %108 = call ptr @strcpy(ptr noundef %104, ptr noundef %107) #9
  %109 = load i64, ptr %7, align 8
  %110 = load i32, ptr @productCount, align 4
  %111 = sext i32 %110 to i64
  %112 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %111
  %113 = getelementptr inbounds nuw %struct.Product, ptr %112, i32 0, i32 3
  store i64 %109, ptr %113, align 8
  %114 = load i32, ptr %6, align 4
  %115 = load i32, ptr @productCount, align 4
  %116 = sext i32 %115 to i64
  %117 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %116
  %118 = getelementptr inbounds nuw %struct.Product, ptr %117, i32 0, i32 4
  store i32 %114, ptr %118, align 16
  %119 = load i32, ptr @productCount, align 4
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %120
  %122 = getelementptr inbounds nuw %struct.Product, ptr %121, i32 0, i32 5
  store i32 0, ptr %122, align 4
  %123 = load i32, ptr @productCount, align 4
  %124 = sext i32 %123 to i64
  %125 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %124
  %126 = getelementptr inbounds nuw %struct.Product, ptr %125, i32 0, i32 6
  store i32 1, ptr %126, align 8
  %127 = load i32, ptr @productCount, align 4
  %128 = add nsw i32 %127, 1
  store i32 %128, ptr @productCount, align 4
  %129 = load i32, ptr %5, align 4
  %130 = load ptr, ptr %3, align 8
  %131 = getelementptr inbounds ptr, ptr %130, i64 2
  %132 = load ptr, ptr %131, align 8
  %133 = call i32 (ptr, ...) @printf(ptr noundef @.str.14, i32 noundef %129, ptr noundef %132)
  br label %134

134:                                              ; preds = %85, %83, %78, %67, %56, %42, %27, %21, %10
  ret void
}

; Function Attrs: nounwind
declare ptr @strcpy(ptr noundef, ptr noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdRemove(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %7 = load i32, ptr %4, align 4
  %8 = icmp ne i32 %7, 2
  br i1 %8, label %15, label %9

9:                                                ; preds = %2
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds ptr, ptr %10, i64 1
  %12 = load ptr, ptr %11, align 8
  %13 = call i32 @parseIntStrict(ptr noundef %12, ptr noundef %5)
  %14 = icmp ne i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %9, %2
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.15)
  br label %42

17:                                               ; preds = %9
  %18 = load i32, ptr %5, align 4
  %19 = call i32 @findProductIndexById(i32 noundef %18)
  store i32 %19, ptr %6, align 4
  %20 = load i32, ptr %6, align 4
  %21 = icmp eq i32 %20, -1
  br i1 %21, label %22, label %25

22:                                               ; preds = %17
  %23 = load i32, ptr %5, align 4
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.16, i32 noundef %23)
  br label %42

25:                                               ; preds = %17
  %26 = load i32, ptr %6, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %27
  %29 = getelementptr inbounds nuw %struct.Product, ptr %28, i32 0, i32 6
  %30 = load i32, ptr %29, align 8
  %31 = icmp ne i32 %30, 0
  br i1 %31, label %35, label %32

32:                                               ; preds = %25
  %33 = load i32, ptr %5, align 4
  %34 = call i32 (ptr, ...) @printf(ptr noundef @.str.17, i32 noundef %33)
  br label %42

35:                                               ; preds = %25
  %36 = load i32, ptr %6, align 4
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %37
  %39 = getelementptr inbounds nuw %struct.Product, ptr %38, i32 0, i32 6
  store i32 0, ptr %39, align 8
  %40 = load i32, ptr %5, align 4
  %41 = call i32 (ptr, ...) @printf(ptr noundef @.str.18, i32 noundef %40)
  br label %42

42:                                               ; preds = %35, %32, %22, %15
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdRestock(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %8 = load i32, ptr %4, align 4
  %9 = icmp ne i32 %8, 3
  br i1 %9, label %22, label %10

10:                                               ; preds = %2
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds ptr, ptr %11, i64 1
  %13 = load ptr, ptr %12, align 8
  %14 = call i32 @parseIntStrict(ptr noundef %13, ptr noundef %5)
  %15 = icmp ne i32 %14, 0
  br i1 %15, label %16, label %22

16:                                               ; preds = %10
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds ptr, ptr %17, i64 2
  %19 = load ptr, ptr %18, align 8
  %20 = call i32 @parseIntStrict(ptr noundef %19, ptr noundef %6)
  %21 = icmp ne i32 %20, 0
  br i1 %21, label %24, label %22

22:                                               ; preds = %16, %10, %2
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.19)
  br label %70

24:                                               ; preds = %16
  %25 = load i32, ptr %6, align 4
  %26 = icmp sle i32 %25, 0
  br i1 %26, label %27, label %29

27:                                               ; preds = %24
  %28 = call i32 (ptr, ...) @printf(ptr noundef @.str.20)
  br label %70

29:                                               ; preds = %24
  %30 = load i32, ptr %5, align 4
  %31 = call i32 @findProductIndexById(i32 noundef %30)
  store i32 %31, ptr %7, align 4
  %32 = load i32, ptr %7, align 4
  %33 = icmp eq i32 %32, -1
  br i1 %33, label %41, label %34

34:                                               ; preds = %29
  %35 = load i32, ptr %7, align 4
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %36
  %38 = getelementptr inbounds nuw %struct.Product, ptr %37, i32 0, i32 6
  %39 = load i32, ptr %38, align 8
  %40 = icmp ne i32 %39, 0
  br i1 %40, label %44, label %41

41:                                               ; preds = %34, %29
  %42 = load i32, ptr %5, align 4
  %43 = call i32 (ptr, ...) @printf(ptr noundef @.str.21, i32 noundef %42)
  br label %70

44:                                               ; preds = %34
  %45 = load i32, ptr %7, align 4
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %46
  %48 = getelementptr inbounds nuw %struct.Product, ptr %47, i32 0, i32 4
  %49 = load i32, ptr %48, align 16
  %50 = load i32, ptr %6, align 4
  %51 = sub nsw i32 2147483647, %50
  %52 = icmp sgt i32 %49, %51
  br i1 %52, label %53, label %55

53:                                               ; preds = %44
  %54 = call i32 (ptr, ...) @printf(ptr noundef @.str.22)
  br label %70

55:                                               ; preds = %44
  %56 = load i32, ptr %6, align 4
  %57 = load i32, ptr %7, align 4
  %58 = sext i32 %57 to i64
  %59 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %58
  %60 = getelementptr inbounds nuw %struct.Product, ptr %59, i32 0, i32 4
  %61 = load i32, ptr %60, align 16
  %62 = add nsw i32 %61, %56
  store i32 %62, ptr %60, align 16
  %63 = load i32, ptr %5, align 4
  %64 = load i32, ptr %7, align 4
  %65 = sext i32 %64 to i64
  %66 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %65
  %67 = getelementptr inbounds nuw %struct.Product, ptr %66, i32 0, i32 4
  %68 = load i32, ptr %67, align 16
  %69 = call i32 (ptr, ...) @printf(ptr noundef @.str.23, i32 noundef %63, i32 noundef %68)
  br label %70

70:                                               ; preds = %55, %53, %41, %27, %22
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdUpdatePrice(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i64, align 8
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %8 = load i32, ptr %4, align 4
  %9 = icmp ne i32 %8, 3
  br i1 %9, label %25, label %10

10:                                               ; preds = %2
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds ptr, ptr %11, i64 1
  %13 = load ptr, ptr %12, align 8
  %14 = call i32 @parseIntStrict(ptr noundef %13, ptr noundef %5)
  %15 = icmp ne i32 %14, 0
  br i1 %15, label %16, label %25

16:                                               ; preds = %10
  %17 = load ptr, ptr %3, align 8
  %18 = getelementptr inbounds ptr, ptr %17, i64 2
  %19 = load ptr, ptr %18, align 8
  %20 = call i32 @parseMoneyStrict(ptr noundef %19, ptr noundef %7)
  %21 = icmp ne i32 %20, 0
  br i1 %21, label %22, label %25

22:                                               ; preds = %16
  %23 = load i64, ptr %7, align 8
  %24 = icmp sle i64 %23, 0
  br i1 %24, label %25, label %27

25:                                               ; preds = %22, %16, %10, %2
  %26 = call i32 (ptr, ...) @printf(ptr noundef @.str.24)
  br label %52

27:                                               ; preds = %22
  %28 = load i32, ptr %5, align 4
  %29 = call i32 @findProductIndexById(i32 noundef %28)
  store i32 %29, ptr %6, align 4
  %30 = load i32, ptr %6, align 4
  %31 = icmp eq i32 %30, -1
  br i1 %31, label %39, label %32

32:                                               ; preds = %27
  %33 = load i32, ptr %6, align 4
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %34
  %36 = getelementptr inbounds nuw %struct.Product, ptr %35, i32 0, i32 6
  %37 = load i32, ptr %36, align 8
  %38 = icmp ne i32 %37, 0
  br i1 %38, label %42, label %39

39:                                               ; preds = %32, %27
  %40 = load i32, ptr %5, align 4
  %41 = call i32 (ptr, ...) @printf(ptr noundef @.str.25, i32 noundef %40)
  br label %52

42:                                               ; preds = %32
  %43 = load i64, ptr %7, align 8
  %44 = load i32, ptr %6, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %45
  %47 = getelementptr inbounds nuw %struct.Product, ptr %46, i32 0, i32 3
  store i64 %43, ptr %47, align 8
  %48 = load i32, ptr %5, align 4
  %49 = call i32 (ptr, ...) @printf(ptr noundef @.str.26, i32 noundef %48)
  %50 = load i64, ptr %7, align 8
  call void @printMoney(i64 noundef %50)
  %51 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  br label %52

52:                                               ; preds = %42, %39, %25
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdList() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  call void @printProductHeader()
  store i32 0, ptr %2, align 4
  br label %3

3:                                                ; preds = %19, %0
  %4 = load i32, ptr %2, align 4
  %5 = load i32, ptr @productCount, align 4
  %6 = icmp slt i32 %4, %5
  br i1 %6, label %7, label %22

7:                                                ; preds = %3
  %8 = load i32, ptr %2, align 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %9
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %14, label %18

14:                                               ; preds = %7
  %15 = load i32, ptr %2, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %16
  call void @printProduct(ptr noundef %17)
  store i32 1, ptr %1, align 4
  br label %18

18:                                               ; preds = %14, %7
  br label %19

19:                                               ; preds = %18
  %20 = load i32, ptr %2, align 4
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %2, align 4
  br label %3, !llvm.loop !19

22:                                               ; preds = %3
  %23 = load i32, ptr %1, align 4
  %24 = icmp ne i32 %23, 0
  br i1 %24, label %27, label %25

25:                                               ; preds = %22
  %26 = call i32 (ptr, ...) @printf(ptr noundef @.str.28)
  br label %27

27:                                               ; preds = %25, %22
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSearchName(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  %7 = load i32, ptr %4, align 4
  %8 = icmp ne i32 %7, 2
  br i1 %8, label %15, label %9

9:                                                ; preds = %2
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds ptr, ptr %10, i64 1
  %12 = load ptr, ptr %11, align 8
  %13 = call i64 @strlen(ptr noundef %12) #8
  %14 = icmp eq i64 %13, 0
  br i1 %14, label %15, label %17

15:                                               ; preds = %9, %2
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.29)
  br label %56

17:                                               ; preds = %9
  call void @printProductHeader()
  store i32 0, ptr %6, align 4
  br label %18

18:                                               ; preds = %45, %17
  %19 = load i32, ptr %6, align 4
  %20 = load i32, ptr @productCount, align 4
  %21 = icmp slt i32 %19, %20
  br i1 %21, label %22, label %48

22:                                               ; preds = %18
  %23 = load i32, ptr %6, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %24
  %26 = getelementptr inbounds nuw %struct.Product, ptr %25, i32 0, i32 6
  %27 = load i32, ptr %26, align 8
  %28 = icmp ne i32 %27, 0
  br i1 %28, label %29, label %44

29:                                               ; preds = %22
  %30 = load i32, ptr %6, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %31
  %33 = getelementptr inbounds nuw %struct.Product, ptr %32, i32 0, i32 1
  %34 = getelementptr inbounds [80 x i8], ptr %33, i64 0, i64 0
  %35 = load ptr, ptr %3, align 8
  %36 = getelementptr inbounds ptr, ptr %35, i64 1
  %37 = load ptr, ptr %36, align 8
  %38 = call i32 @containsIgnoreCase(ptr noundef %34, ptr noundef %37)
  %39 = icmp ne i32 %38, 0
  br i1 %39, label %40, label %44

40:                                               ; preds = %29
  %41 = load i32, ptr %6, align 4
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %42
  call void @printProduct(ptr noundef %43)
  store i32 1, ptr %5, align 4
  br label %44

44:                                               ; preds = %40, %29, %22
  br label %45

45:                                               ; preds = %44
  %46 = load i32, ptr %6, align 4
  %47 = add nsw i32 %46, 1
  store i32 %47, ptr %6, align 4
  br label %18, !llvm.loop !20

48:                                               ; preds = %18
  %49 = load i32, ptr %5, align 4
  %50 = icmp ne i32 %49, 0
  br i1 %50, label %56, label %51

51:                                               ; preds = %48
  %52 = load ptr, ptr %3, align 8
  %53 = getelementptr inbounds ptr, ptr %52, i64 1
  %54 = load ptr, ptr %53, align 8
  %55 = call i32 (ptr, ...) @printf(ptr noundef @.str.30, ptr noundef %54)
  br label %56

56:                                               ; preds = %15, %51, %48
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSearchCategory(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  %7 = load i32, ptr %4, align 4
  %8 = icmp ne i32 %7, 2
  br i1 %8, label %15, label %9

9:                                                ; preds = %2
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds ptr, ptr %10, i64 1
  %12 = load ptr, ptr %11, align 8
  %13 = call i64 @strlen(ptr noundef %12) #8
  %14 = icmp eq i64 %13, 0
  br i1 %14, label %15, label %17

15:                                               ; preds = %9, %2
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.31)
  br label %56

17:                                               ; preds = %9
  call void @printProductHeader()
  store i32 0, ptr %6, align 4
  br label %18

18:                                               ; preds = %45, %17
  %19 = load i32, ptr %6, align 4
  %20 = load i32, ptr @productCount, align 4
  %21 = icmp slt i32 %19, %20
  br i1 %21, label %22, label %48

22:                                               ; preds = %18
  %23 = load i32, ptr %6, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %24
  %26 = getelementptr inbounds nuw %struct.Product, ptr %25, i32 0, i32 6
  %27 = load i32, ptr %26, align 8
  %28 = icmp ne i32 %27, 0
  br i1 %28, label %29, label %44

29:                                               ; preds = %22
  %30 = load i32, ptr %6, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %31
  %33 = getelementptr inbounds nuw %struct.Product, ptr %32, i32 0, i32 2
  %34 = getelementptr inbounds [50 x i8], ptr %33, i64 0, i64 0
  %35 = load ptr, ptr %3, align 8
  %36 = getelementptr inbounds ptr, ptr %35, i64 1
  %37 = load ptr, ptr %36, align 8
  %38 = call i32 @containsIgnoreCase(ptr noundef %34, ptr noundef %37)
  %39 = icmp ne i32 %38, 0
  br i1 %39, label %40, label %44

40:                                               ; preds = %29
  %41 = load i32, ptr %6, align 4
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %42
  call void @printProduct(ptr noundef %43)
  store i32 1, ptr %5, align 4
  br label %44

44:                                               ; preds = %40, %29, %22
  br label %45

45:                                               ; preds = %44
  %46 = load i32, ptr %6, align 4
  %47 = add nsw i32 %46, 1
  store i32 %47, ptr %6, align 4
  br label %18, !llvm.loop !21

48:                                               ; preds = %18
  %49 = load i32, ptr %5, align 4
  %50 = icmp ne i32 %49, 0
  br i1 %50, label %56, label %51

51:                                               ; preds = %48
  %52 = load ptr, ptr %3, align 8
  %53 = getelementptr inbounds ptr, ptr %52, i64 1
  %54 = load ptr, ptr %53, align 8
  %55 = call i32 (ptr, ...) @printf(ptr noundef @.str.32, ptr noundef %54)
  br label %56

56:                                               ; preds = %15, %51, %48
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdLowStock(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %6, align 4
  %8 = load i32, ptr %4, align 4
  %9 = icmp ne i32 %8, 2
  br i1 %9, label %19, label %10

10:                                               ; preds = %2
  %11 = load ptr, ptr %3, align 8
  %12 = getelementptr inbounds ptr, ptr %11, i64 1
  %13 = load ptr, ptr %12, align 8
  %14 = call i32 @parseIntStrict(ptr noundef %13, ptr noundef %5)
  %15 = icmp ne i32 %14, 0
  br i1 %15, label %16, label %19

16:                                               ; preds = %10
  %17 = load i32, ptr %5, align 4
  %18 = icmp slt i32 %17, 0
  br i1 %18, label %19, label %21

19:                                               ; preds = %16, %10, %2
  %20 = call i32 (ptr, ...) @printf(ptr noundef @.str.33)
  br label %55

21:                                               ; preds = %16
  call void @printProductHeader()
  store i32 0, ptr %7, align 4
  br label %22

22:                                               ; preds = %46, %21
  %23 = load i32, ptr %7, align 4
  %24 = load i32, ptr @productCount, align 4
  %25 = icmp slt i32 %23, %24
  br i1 %25, label %26, label %49

26:                                               ; preds = %22
  %27 = load i32, ptr %7, align 4
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %28
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 6
  %31 = load i32, ptr %30, align 8
  %32 = icmp ne i32 %31, 0
  br i1 %32, label %33, label %45

33:                                               ; preds = %26
  %34 = load i32, ptr %7, align 4
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %35
  %37 = getelementptr inbounds nuw %struct.Product, ptr %36, i32 0, i32 4
  %38 = load i32, ptr %37, align 16
  %39 = load i32, ptr %5, align 4
  %40 = icmp sle i32 %38, %39
  br i1 %40, label %41, label %45

41:                                               ; preds = %33
  %42 = load i32, ptr %7, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %43
  call void @printProduct(ptr noundef %44)
  store i32 1, ptr %6, align 4
  br label %45

45:                                               ; preds = %41, %33, %26
  br label %46

46:                                               ; preds = %45
  %47 = load i32, ptr %7, align 4
  %48 = add nsw i32 %47, 1
  store i32 %48, ptr %7, align 4
  br label %22, !llvm.loop !22

49:                                               ; preds = %22
  %50 = load i32, ptr %6, align 4
  %51 = icmp ne i32 %50, 0
  br i1 %51, label %55, label %52

52:                                               ; preds = %49
  %53 = load i32, ptr %5, align 4
  %54 = call i32 (ptr, ...) @printf(ptr noundef @.str.34, i32 noundef %53)
  br label %55

55:                                               ; preds = %19, %52, %49
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpPriceAsc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %8 = load ptr, ptr %4, align 8
  store ptr %8, ptr %6, align 8
  %9 = load ptr, ptr %5, align 8
  store ptr %9, ptr %7, align 8
  %10 = load ptr, ptr %6, align 8
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 6
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %12, %15
  br i1 %16, label %17, label %25

17:                                               ; preds = %2
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 6
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %6, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 8
  %24 = sub nsw i32 %20, %23
  store i32 %24, ptr %3, align 4
  br label %51

25:                                               ; preds = %2
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 3
  %28 = load i64, ptr %27, align 8
  %29 = load ptr, ptr %7, align 8
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 3
  %31 = load i64, ptr %30, align 8
  %32 = icmp slt i64 %28, %31
  br i1 %32, label %33, label %34

33:                                               ; preds = %25
  store i32 -1, ptr %3, align 4
  br label %51

34:                                               ; preds = %25
  %35 = load ptr, ptr %6, align 8
  %36 = getelementptr inbounds nuw %struct.Product, ptr %35, i32 0, i32 3
  %37 = load i64, ptr %36, align 8
  %38 = load ptr, ptr %7, align 8
  %39 = getelementptr inbounds nuw %struct.Product, ptr %38, i32 0, i32 3
  %40 = load i64, ptr %39, align 8
  %41 = icmp sgt i64 %37, %40
  br i1 %41, label %42, label %43

42:                                               ; preds = %34
  store i32 1, ptr %3, align 4
  br label %51

43:                                               ; preds = %34
  %44 = load ptr, ptr %6, align 8
  %45 = getelementptr inbounds nuw %struct.Product, ptr %44, i32 0, i32 0
  %46 = load i32, ptr %45, align 8
  %47 = load ptr, ptr %7, align 8
  %48 = getelementptr inbounds nuw %struct.Product, ptr %47, i32 0, i32 0
  %49 = load i32, ptr %48, align 8
  %50 = sub nsw i32 %46, %49
  store i32 %50, ptr %3, align 4
  br label %51

51:                                               ; preds = %43, %42, %33, %17
  %52 = load i32, ptr %3, align 4
  ret i32 %52
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpPriceDesc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %8 = load ptr, ptr %4, align 8
  store ptr %8, ptr %6, align 8
  %9 = load ptr, ptr %5, align 8
  store ptr %9, ptr %7, align 8
  %10 = load ptr, ptr %6, align 8
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 6
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %12, %15
  br i1 %16, label %17, label %25

17:                                               ; preds = %2
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 6
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %6, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 8
  %24 = sub nsw i32 %20, %23
  store i32 %24, ptr %3, align 4
  br label %51

25:                                               ; preds = %2
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 3
  %28 = load i64, ptr %27, align 8
  %29 = load ptr, ptr %7, align 8
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 3
  %31 = load i64, ptr %30, align 8
  %32 = icmp sgt i64 %28, %31
  br i1 %32, label %33, label %34

33:                                               ; preds = %25
  store i32 -1, ptr %3, align 4
  br label %51

34:                                               ; preds = %25
  %35 = load ptr, ptr %6, align 8
  %36 = getelementptr inbounds nuw %struct.Product, ptr %35, i32 0, i32 3
  %37 = load i64, ptr %36, align 8
  %38 = load ptr, ptr %7, align 8
  %39 = getelementptr inbounds nuw %struct.Product, ptr %38, i32 0, i32 3
  %40 = load i64, ptr %39, align 8
  %41 = icmp slt i64 %37, %40
  br i1 %41, label %42, label %43

42:                                               ; preds = %34
  store i32 1, ptr %3, align 4
  br label %51

43:                                               ; preds = %34
  %44 = load ptr, ptr %6, align 8
  %45 = getelementptr inbounds nuw %struct.Product, ptr %44, i32 0, i32 0
  %46 = load i32, ptr %45, align 8
  %47 = load ptr, ptr %7, align 8
  %48 = getelementptr inbounds nuw %struct.Product, ptr %47, i32 0, i32 0
  %49 = load i32, ptr %48, align 8
  %50 = sub nsw i32 %46, %49
  store i32 %50, ptr %3, align 4
  br label %51

51:                                               ; preds = %43, %42, %33, %17
  %52 = load i32, ptr %3, align 4
  ret i32 %52
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpStockAsc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %8 = load ptr, ptr %4, align 8
  store ptr %8, ptr %6, align 8
  %9 = load ptr, ptr %5, align 8
  store ptr %9, ptr %7, align 8
  %10 = load ptr, ptr %6, align 8
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 6
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %12, %15
  br i1 %16, label %17, label %25

17:                                               ; preds = %2
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 6
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %6, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 8
  %24 = sub nsw i32 %20, %23
  store i32 %24, ptr %3, align 4
  br label %49

25:                                               ; preds = %2
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 4
  %28 = load i32, ptr %27, align 8
  %29 = load ptr, ptr %7, align 8
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 4
  %31 = load i32, ptr %30, align 8
  %32 = icmp ne i32 %28, %31
  br i1 %32, label %33, label %41

33:                                               ; preds = %25
  %34 = load ptr, ptr %6, align 8
  %35 = getelementptr inbounds nuw %struct.Product, ptr %34, i32 0, i32 4
  %36 = load i32, ptr %35, align 8
  %37 = load ptr, ptr %7, align 8
  %38 = getelementptr inbounds nuw %struct.Product, ptr %37, i32 0, i32 4
  %39 = load i32, ptr %38, align 8
  %40 = sub nsw i32 %36, %39
  store i32 %40, ptr %3, align 4
  br label %49

41:                                               ; preds = %25
  %42 = load ptr, ptr %6, align 8
  %43 = getelementptr inbounds nuw %struct.Product, ptr %42, i32 0, i32 0
  %44 = load i32, ptr %43, align 8
  %45 = load ptr, ptr %7, align 8
  %46 = getelementptr inbounds nuw %struct.Product, ptr %45, i32 0, i32 0
  %47 = load i32, ptr %46, align 8
  %48 = sub nsw i32 %44, %47
  store i32 %48, ptr %3, align 4
  br label %49

49:                                               ; preds = %41, %33, %17
  %50 = load i32, ptr %3, align 4
  ret i32 %50
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpSoldDesc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %8 = load ptr, ptr %4, align 8
  store ptr %8, ptr %6, align 8
  %9 = load ptr, ptr %5, align 8
  store ptr %9, ptr %7, align 8
  %10 = load ptr, ptr %6, align 8
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 6
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %12, %15
  br i1 %16, label %17, label %25

17:                                               ; preds = %2
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 6
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %6, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 8
  %24 = sub nsw i32 %20, %23
  store i32 %24, ptr %3, align 4
  br label %49

25:                                               ; preds = %2
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 5
  %28 = load i32, ptr %27, align 4
  %29 = load ptr, ptr %7, align 8
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 5
  %31 = load i32, ptr %30, align 4
  %32 = icmp ne i32 %28, %31
  br i1 %32, label %33, label %41

33:                                               ; preds = %25
  %34 = load ptr, ptr %7, align 8
  %35 = getelementptr inbounds nuw %struct.Product, ptr %34, i32 0, i32 5
  %36 = load i32, ptr %35, align 4
  %37 = load ptr, ptr %6, align 8
  %38 = getelementptr inbounds nuw %struct.Product, ptr %37, i32 0, i32 5
  %39 = load i32, ptr %38, align 4
  %40 = sub nsw i32 %36, %39
  store i32 %40, ptr %3, align 4
  br label %49

41:                                               ; preds = %25
  %42 = load ptr, ptr %6, align 8
  %43 = getelementptr inbounds nuw %struct.Product, ptr %42, i32 0, i32 0
  %44 = load i32, ptr %43, align 8
  %45 = load ptr, ptr %7, align 8
  %46 = getelementptr inbounds nuw %struct.Product, ptr %45, i32 0, i32 0
  %47 = load i32, ptr %46, align 8
  %48 = sub nsw i32 %44, %47
  store i32 %48, ptr %3, align 4
  br label %49

49:                                               ; preds = %41, %33, %17
  %50 = load i32, ptr %3, align 4
  ret i32 %50
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpNameAsc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %8 = load ptr, ptr %4, align 8
  store ptr %8, ptr %6, align 8
  %9 = load ptr, ptr %5, align 8
  store ptr %9, ptr %7, align 8
  %10 = load ptr, ptr %6, align 8
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 6
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %12, %15
  br i1 %16, label %17, label %25

17:                                               ; preds = %2
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 6
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %6, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 8
  %24 = sub nsw i32 %20, %23
  store i32 %24, ptr %3, align 4
  br label %33

25:                                               ; preds = %2
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 1
  %28 = getelementptr inbounds [80 x i8], ptr %27, i64 0, i64 0
  %29 = load ptr, ptr %7, align 8
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 1
  %31 = getelementptr inbounds [80 x i8], ptr %30, i64 0, i64 0
  %32 = call i32 @strcmp(ptr noundef %28, ptr noundef %31) #8
  store i32 %32, ptr %3, align 4
  br label %33

33:                                               ; preds = %25, %17
  %34 = load i32, ptr %3, align 4
  ret i32 %34
}

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSort(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca [64 x i8], align 16
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %6 = load i32, ptr %4, align 4
  %7 = icmp ne i32 %6, 2
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.35)
  br label %63

10:                                               ; preds = %2
  %11 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds ptr, ptr %12, i64 1
  %14 = load ptr, ptr %13, align 8
  %15 = call ptr @strcpy(ptr noundef %11, ptr noundef %14) #9
  %16 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  call void @upperString(ptr noundef %16)
  %17 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %18 = call i32 @equalsIgnoreCase(ptr noundef %17, ptr noundef @.str.36)
  %19 = icmp ne i32 %18, 0
  br i1 %19, label %20, label %23

20:                                               ; preds = %10
  %21 = load i32, ptr @productCount, align 4
  %22 = sext i32 %21 to i64
  call void @qsort(ptr noundef @products, i64 noundef %22, i64 noundef 160, ptr noundef @cmpPriceAsc)
  br label %60

23:                                               ; preds = %10
  %24 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %25 = call i32 @equalsIgnoreCase(ptr noundef %24, ptr noundef @.str.37)
  %26 = icmp ne i32 %25, 0
  br i1 %26, label %27, label %30

27:                                               ; preds = %23
  %28 = load i32, ptr @productCount, align 4
  %29 = sext i32 %28 to i64
  call void @qsort(ptr noundef @products, i64 noundef %29, i64 noundef 160, ptr noundef @cmpPriceDesc)
  br label %59

30:                                               ; preds = %23
  %31 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %32 = call i32 @equalsIgnoreCase(ptr noundef %31, ptr noundef @.str.38)
  %33 = icmp ne i32 %32, 0
  br i1 %33, label %34, label %37

34:                                               ; preds = %30
  %35 = load i32, ptr @productCount, align 4
  %36 = sext i32 %35 to i64
  call void @qsort(ptr noundef @products, i64 noundef %36, i64 noundef 160, ptr noundef @cmpStockAsc)
  br label %58

37:                                               ; preds = %30
  %38 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %39 = call i32 @equalsIgnoreCase(ptr noundef %38, ptr noundef @.str.39)
  %40 = icmp ne i32 %39, 0
  br i1 %40, label %41, label %44

41:                                               ; preds = %37
  %42 = load i32, ptr @productCount, align 4
  %43 = sext i32 %42 to i64
  call void @qsort(ptr noundef @products, i64 noundef %43, i64 noundef 160, ptr noundef @cmpSoldDesc)
  br label %57

44:                                               ; preds = %37
  %45 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %46 = call i32 @equalsIgnoreCase(ptr noundef %45, ptr noundef @.str.40)
  %47 = icmp ne i32 %46, 0
  br i1 %47, label %48, label %51

48:                                               ; preds = %44
  %49 = load i32, ptr @productCount, align 4
  %50 = sext i32 %49 to i64
  call void @qsort(ptr noundef @products, i64 noundef %50, i64 noundef 160, ptr noundef @cmpNameAsc)
  br label %56

51:                                               ; preds = %44
  %52 = load ptr, ptr %3, align 8
  %53 = getelementptr inbounds ptr, ptr %52, i64 1
  %54 = load ptr, ptr %53, align 8
  %55 = call i32 (ptr, ...) @printf(ptr noundef @.str.41, ptr noundef %54)
  br label %63

56:                                               ; preds = %48
  br label %57

57:                                               ; preds = %56, %41
  br label %58

58:                                               ; preds = %57, %34
  br label %59

59:                                               ; preds = %58, %27
  br label %60

60:                                               ; preds = %59, %20
  %61 = getelementptr inbounds [64 x i8], ptr %5, i64 0, i64 0
  %62 = call i32 (ptr, ...) @printf(ptr noundef @.str.42, ptr noundef %61)
  call void @cmdList()
  br label %63

63:                                               ; preds = %60, %51, %8
  ret void
}

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i64 @calculateDiscount(i64 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = alloca ptr, align 8
  store i64 %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %6 = load ptr, ptr %5, align 8
  %7 = call i32 @equalsIgnoreCase(ptr noundef %6, ptr noundef @.str.43)
  %8 = icmp ne i32 %7, 0
  br i1 %8, label %9, label %10

9:                                                ; preds = %2
  store i64 0, ptr %3, align 8
  br label %36

10:                                               ; preds = %2
  %11 = load ptr, ptr %5, align 8
  %12 = call i32 @equalsIgnoreCase(ptr noundef %11, ptr noundef @.str.44)
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %14, label %18

14:                                               ; preds = %10
  %15 = load i64, ptr %4, align 8
  %16 = mul nsw i64 %15, 10
  %17 = sdiv i64 %16, 100
  store i64 %17, ptr %3, align 8
  br label %36

18:                                               ; preds = %10
  %19 = load ptr, ptr %5, align 8
  %20 = call i32 @equalsIgnoreCase(ptr noundef %19, ptr noundef @.str.45)
  %21 = icmp ne i32 %20, 0
  br i1 %21, label %22, label %30

22:                                               ; preds = %18
  %23 = load i64, ptr %4, align 8
  %24 = icmp sge i64 %23, 50000
  br i1 %24, label %25, label %29

25:                                               ; preds = %22
  %26 = load i64, ptr %4, align 8
  %27 = mul nsw i64 %26, 15
  %28 = sdiv i64 %27, 100
  store i64 %28, ptr %3, align 8
  br label %36

29:                                               ; preds = %22
  store i64 0, ptr %3, align 8
  br label %36

30:                                               ; preds = %18
  %31 = load ptr, ptr %5, align 8
  %32 = call i32 @equalsIgnoreCase(ptr noundef %31, ptr noundef @.str.46)
  %33 = icmp ne i32 %32, 0
  br i1 %33, label %34, label %35

34:                                               ; preds = %30
  store i64 0, ptr %3, align 8
  br label %36

35:                                               ; preds = %30
  store i64 -1, ptr %3, align 8
  br label %36

36:                                               ; preds = %35, %34, %29, %25, %14, %9
  %37 = load i64, ptr %3, align 8
  ret i64 %37
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printOrderShort(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 0
  %5 = load i32, ptr %4, align 8
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds nuw %struct.Order, ptr %6, i32 0, i32 1
  %8 = getelementptr inbounds [80 x i8], ptr %7, i64 0, i64 0
  %9 = load ptr, ptr %2, align 8
  %10 = getelementptr inbounds nuw %struct.Order, ptr %9, i32 0, i32 4
  %11 = load i32, ptr %10, align 8
  %12 = call i32 (ptr, ...) @printf(ptr noundef @.str.47, i32 noundef %5, ptr noundef %8, i32 noundef %11)
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.Order, ptr %13, i32 0, i32 5
  %15 = load i64, ptr %14, align 8
  call void @printMoney(i64 noundef %15)
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.48)
  %17 = load ptr, ptr %2, align 8
  %18 = getelementptr inbounds nuw %struct.Order, ptr %17, i32 0, i32 6
  %19 = load i64, ptr %18, align 8
  call void @printMoney(i64 noundef %19)
  %20 = call i32 (ptr, ...) @printf(ptr noundef @.str.49)
  %21 = load ptr, ptr %2, align 8
  %22 = getelementptr inbounds nuw %struct.Order, ptr %21, i32 0, i32 7
  %23 = load i64, ptr %22, align 8
  call void @printMoney(i64 noundef %23)
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.50)
  %25 = load ptr, ptr %2, align 8
  %26 = getelementptr inbounds nuw %struct.Order, ptr %25, i32 0, i32 8
  %27 = load i64, ptr %26, align 8
  call void @printMoney(i64 noundef %27)
  %28 = call i32 (ptr, ...) @printf(ptr noundef @.str.51)
  %29 = load ptr, ptr %2, align 8
  %30 = getelementptr inbounds nuw %struct.Order, ptr %29, i32 0, i32 9
  %31 = load i64, ptr %30, align 8
  call void @printMoney(i64 noundef %31)
  %32 = load ptr, ptr %2, align 8
  %33 = getelementptr inbounds nuw %struct.Order, ptr %32, i32 0, i32 10
  %34 = load i32, ptr %33, align 8
  %35 = icmp ne i32 %34, 0
  %36 = zext i1 %35 to i64
  %37 = select i1 %35, ptr @.str.53, ptr @.str.54
  %38 = call i32 (ptr, ...) @printf(ptr noundef @.str.52, ptr noundef %37)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printOrderDetail(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = getelementptr inbounds nuw %struct.Order, ptr %4, i32 0, i32 0
  %6 = load i32, ptr %5, align 8
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.55, i32 noundef %6)
  %8 = load ptr, ptr %2, align 8
  %9 = getelementptr inbounds nuw %struct.Order, ptr %8, i32 0, i32 1
  %10 = getelementptr inbounds [80 x i8], ptr %9, i64 0, i64 0
  %11 = call i32 (ptr, ...) @printf(ptr noundef @.str.56, ptr noundef %10)
  %12 = load ptr, ptr %2, align 8
  %13 = getelementptr inbounds nuw %struct.Order, ptr %12, i32 0, i32 2
  %14 = getelementptr inbounds [30 x i8], ptr %13, i64 0, i64 0
  %15 = call i32 (ptr, ...) @printf(ptr noundef @.str.57, ptr noundef %14)
  %16 = load ptr, ptr %2, align 8
  %17 = getelementptr inbounds nuw %struct.Order, ptr %16, i32 0, i32 10
  %18 = load i32, ptr %17, align 8
  %19 = icmp ne i32 %18, 0
  %20 = zext i1 %19 to i64
  %21 = select i1 %19, ptr @.str.53, ptr @.str.54
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.58, ptr noundef %21)
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.59)
  store i32 0, ptr %3, align 4
  br label %24

24:                                               ; preds = %69, %1
  %25 = load i32, ptr %3, align 4
  %26 = load ptr, ptr %2, align 8
  %27 = getelementptr inbounds nuw %struct.Order, ptr %26, i32 0, i32 4
  %28 = load i32, ptr %27, align 8
  %29 = icmp slt i32 %25, %28
  br i1 %29, label %30, label %72

30:                                               ; preds = %24
  %31 = load ptr, ptr %2, align 8
  %32 = getelementptr inbounds nuw %struct.Order, ptr %31, i32 0, i32 3
  %33 = load i32, ptr %3, align 4
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds [64 x %struct.OrderItem], ptr %32, i64 0, i64 %34
  %36 = getelementptr inbounds nuw %struct.OrderItem, ptr %35, i32 0, i32 0
  %37 = load i32, ptr %36, align 8
  %38 = load ptr, ptr %2, align 8
  %39 = getelementptr inbounds nuw %struct.Order, ptr %38, i32 0, i32 3
  %40 = load i32, ptr %3, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds [64 x %struct.OrderItem], ptr %39, i64 0, i64 %41
  %43 = getelementptr inbounds nuw %struct.OrderItem, ptr %42, i32 0, i32 1
  %44 = getelementptr inbounds [80 x i8], ptr %43, i64 0, i64 0
  %45 = load ptr, ptr %2, align 8
  %46 = getelementptr inbounds nuw %struct.Order, ptr %45, i32 0, i32 3
  %47 = load i32, ptr %3, align 4
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds [64 x %struct.OrderItem], ptr %46, i64 0, i64 %48
  %50 = getelementptr inbounds nuw %struct.OrderItem, ptr %49, i32 0, i32 2
  %51 = load i32, ptr %50, align 4
  %52 = call i32 (ptr, ...) @printf(ptr noundef @.str.60, i32 noundef %37, ptr noundef %44, i32 noundef %51)
  %53 = load ptr, ptr %2, align 8
  %54 = getelementptr inbounds nuw %struct.Order, ptr %53, i32 0, i32 3
  %55 = load i32, ptr %3, align 4
  %56 = sext i32 %55 to i64
  %57 = getelementptr inbounds [64 x %struct.OrderItem], ptr %54, i64 0, i64 %56
  %58 = getelementptr inbounds nuw %struct.OrderItem, ptr %57, i32 0, i32 3
  %59 = load i64, ptr %58, align 8
  call void @printMoney(i64 noundef %59)
  %60 = call i32 (ptr, ...) @printf(ptr noundef @.str.61)
  %61 = load ptr, ptr %2, align 8
  %62 = getelementptr inbounds nuw %struct.Order, ptr %61, i32 0, i32 3
  %63 = load i32, ptr %3, align 4
  %64 = sext i32 %63 to i64
  %65 = getelementptr inbounds [64 x %struct.OrderItem], ptr %62, i64 0, i64 %64
  %66 = getelementptr inbounds nuw %struct.OrderItem, ptr %65, i32 0, i32 4
  %67 = load i64, ptr %66, align 8
  call void @printMoney(i64 noundef %67)
  %68 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  br label %69

69:                                               ; preds = %30
  %70 = load i32, ptr %3, align 4
  %71 = add nsw i32 %70, 1
  store i32 %71, ptr %3, align 4
  br label %24, !llvm.loop !23

72:                                               ; preds = %24
  %73 = call i32 (ptr, ...) @printf(ptr noundef @.str.62)
  %74 = load ptr, ptr %2, align 8
  %75 = getelementptr inbounds nuw %struct.Order, ptr %74, i32 0, i32 5
  %76 = load i64, ptr %75, align 8
  call void @printMoney(i64 noundef %76)
  %77 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %78 = call i32 (ptr, ...) @printf(ptr noundef @.str.63)
  %79 = load ptr, ptr %2, align 8
  %80 = getelementptr inbounds nuw %struct.Order, ptr %79, i32 0, i32 6
  %81 = load i64, ptr %80, align 8
  call void @printMoney(i64 noundef %81)
  %82 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %83 = call i32 (ptr, ...) @printf(ptr noundef @.str.64)
  %84 = load ptr, ptr %2, align 8
  %85 = getelementptr inbounds nuw %struct.Order, ptr %84, i32 0, i32 7
  %86 = load i64, ptr %85, align 8
  call void @printMoney(i64 noundef %86)
  %87 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %88 = call i32 (ptr, ...) @printf(ptr noundef @.str.65)
  %89 = load ptr, ptr %2, align 8
  %90 = getelementptr inbounds nuw %struct.Order, ptr %89, i32 0, i32 8
  %91 = load i64, ptr %90, align 8
  call void @printMoney(i64 noundef %91)
  %92 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %93 = call i32 (ptr, ...) @printf(ptr noundef @.str.66)
  %94 = load ptr, ptr %2, align 8
  %95 = getelementptr inbounds nuw %struct.Order, ptr %94, i32 0, i32 9
  %96 = load i64, ptr %95, align 8
  call void @printMoney(i64 noundef %96)
  %97 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @parseCartItem(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  %9 = load ptr, ptr %5, align 8
  %10 = call ptr @strchr(ptr noundef %9, i32 noundef 58) #8
  store ptr %10, ptr %8, align 8
  %11 = load ptr, ptr %8, align 8
  %12 = icmp eq ptr %11, null
  br i1 %12, label %13, label %14

13:                                               ; preds = %3
  store i32 0, ptr %4, align 4
  br label %41

14:                                               ; preds = %3
  %15 = load ptr, ptr %8, align 8
  store i8 0, ptr %15, align 1
  %16 = load ptr, ptr %5, align 8
  call void @trim(ptr noundef %16)
  %17 = load ptr, ptr %8, align 8
  %18 = getelementptr inbounds i8, ptr %17, i64 1
  call void @trim(ptr noundef %18)
  %19 = load ptr, ptr %5, align 8
  %20 = load ptr, ptr %6, align 8
  %21 = call i32 @parseIntStrict(ptr noundef %19, ptr noundef %20)
  %22 = icmp ne i32 %21, 0
  br i1 %22, label %24, label %23

23:                                               ; preds = %14
  store i32 0, ptr %4, align 4
  br label %41

24:                                               ; preds = %14
  %25 = load ptr, ptr %8, align 8
  %26 = getelementptr inbounds i8, ptr %25, i64 1
  %27 = load ptr, ptr %7, align 8
  %28 = call i32 @parseIntStrict(ptr noundef %26, ptr noundef %27)
  %29 = icmp ne i32 %28, 0
  br i1 %29, label %31, label %30

30:                                               ; preds = %24
  store i32 0, ptr %4, align 4
  br label %41

31:                                               ; preds = %24
  %32 = load ptr, ptr %6, align 8
  %33 = load i32, ptr %32, align 4
  %34 = icmp sle i32 %33, 0
  br i1 %34, label %39, label %35

35:                                               ; preds = %31
  %36 = load ptr, ptr %7, align 8
  %37 = load i32, ptr %36, align 4
  %38 = icmp sle i32 %37, 0
  br i1 %38, label %39, label %40

39:                                               ; preds = %35, %31
  store i32 0, ptr %4, align 4
  br label %41

40:                                               ; preds = %35
  store i32 1, ptr %4, align 4
  br label %41

41:                                               ; preds = %40, %39, %30, %23, %13
  %42 = load i32, ptr %4, align 4
  ret i32 %42
}

; Function Attrs: nounwind willreturn memory(read)
declare ptr @strchr(ptr noundef, i32 noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cartAlreadyHas(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %7

7:                                                ; preds = %26, %2
  %8 = load i32, ptr %6, align 4
  %9 = load ptr, ptr %4, align 8
  %10 = getelementptr inbounds nuw %struct.Order, ptr %9, i32 0, i32 4
  %11 = load i32, ptr %10, align 8
  %12 = icmp slt i32 %8, %11
  br i1 %12, label %13, label %29

13:                                               ; preds = %7
  %14 = load ptr, ptr %4, align 8
  %15 = getelementptr inbounds nuw %struct.Order, ptr %14, i32 0, i32 3
  %16 = load i32, ptr %6, align 4
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds [64 x %struct.OrderItem], ptr %15, i64 0, i64 %17
  %19 = getelementptr inbounds nuw %struct.OrderItem, ptr %18, i32 0, i32 0
  %20 = load i32, ptr %19, align 8
  %21 = load i32, ptr %5, align 4
  %22 = icmp eq i32 %20, %21
  br i1 %22, label %23, label %25

23:                                               ; preds = %13
  %24 = load i32, ptr %6, align 4
  store i32 %24, ptr %3, align 4
  br label %30

25:                                               ; preds = %13
  br label %26

26:                                               ; preds = %25
  %27 = load i32, ptr %6, align 4
  %28 = add nsw i32 %27, 1
  store i32 %28, ptr %6, align 4
  br label %7, !llvm.loop !24

29:                                               ; preds = %7
  store i32 -1, ptr %3, align 4
  br label %30

30:                                               ; preds = %29, %23
  %31 = load i32, ptr %3, align 4
  ret i32 %31
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdBuy(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca %struct.Order, align 8
  %6 = alloca [2048 x i8], align 16
  %7 = alloca ptr, align 8
  %8 = alloca i64, align 8
  %9 = alloca i64, align 8
  %10 = alloca i64, align 8
  %11 = alloca i64, align 8
  %12 = alloca [1000 x i32], align 16
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i64 0, ptr %8, align 8
  %18 = load i32, ptr %4, align 4
  %19 = icmp ne i32 %18, 4
  br i1 %19, label %20, label %22

20:                                               ; preds = %2
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.67)
  br label %353

22:                                               ; preds = %2
  %23 = load ptr, ptr %3, align 8
  %24 = getelementptr inbounds ptr, ptr %23, i64 1
  %25 = load ptr, ptr %24, align 8
  %26 = call i64 @strlen(ptr noundef %25) #8
  %27 = icmp eq i64 %26, 0
  br i1 %27, label %34, label %28

28:                                               ; preds = %22
  %29 = load ptr, ptr %3, align 8
  %30 = getelementptr inbounds ptr, ptr %29, i64 1
  %31 = load ptr, ptr %30, align 8
  %32 = call i64 @strlen(ptr noundef %31) #8
  %33 = icmp uge i64 %32, 80
  br i1 %33, label %34, label %36

34:                                               ; preds = %28, %22
  %35 = call i32 (ptr, ...) @printf(ptr noundef @.str.68)
  br label %353

36:                                               ; preds = %28
  %37 = load ptr, ptr %3, align 8
  %38 = getelementptr inbounds ptr, ptr %37, i64 2
  %39 = load ptr, ptr %38, align 8
  %40 = call i64 @strlen(ptr noundef %39) #8
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %48, label %42

42:                                               ; preds = %36
  %43 = load ptr, ptr %3, align 8
  %44 = getelementptr inbounds ptr, ptr %43, i64 2
  %45 = load ptr, ptr %44, align 8
  %46 = call i64 @strlen(ptr noundef %45) #8
  %47 = icmp uge i64 %46, 30
  br i1 %47, label %48, label %50

48:                                               ; preds = %42, %36
  %49 = call i32 (ptr, ...) @printf(ptr noundef @.str.69)
  br label %353

50:                                               ; preds = %42
  %51 = load ptr, ptr %3, align 8
  %52 = getelementptr inbounds ptr, ptr %51, i64 3
  %53 = load ptr, ptr %52, align 8
  %54 = call i64 @strlen(ptr noundef %53) #8
  %55 = icmp eq i64 %54, 0
  br i1 %55, label %56, label %58

56:                                               ; preds = %50
  %57 = call i32 (ptr, ...) @printf(ptr noundef @.str.70)
  br label %353

58:                                               ; preds = %50
  %59 = load i32, ptr @orderCount, align 4
  %60 = icmp sge i32 %59, 1000
  br i1 %60, label %61, label %63

61:                                               ; preds = %58
  %62 = call i32 (ptr, ...) @printf(ptr noundef @.str.71)
  br label %353

63:                                               ; preds = %58
  %64 = load ptr, ptr %3, align 8
  %65 = getelementptr inbounds ptr, ptr %64, i64 2
  %66 = load ptr, ptr %65, align 8
  %67 = call i64 @calculateDiscount(i64 noundef 1000, ptr noundef %66)
  store i64 %67, ptr %9, align 8
  %68 = load i64, ptr %9, align 8
  %69 = icmp slt i64 %68, 0
  br i1 %69, label %70, label %75

70:                                               ; preds = %63
  %71 = load ptr, ptr %3, align 8
  %72 = getelementptr inbounds ptr, ptr %71, i64 2
  %73 = load ptr, ptr %72, align 8
  %74 = call i32 (ptr, ...) @printf(ptr noundef @.str.72, ptr noundef %73)
  br label %353

75:                                               ; preds = %63
  call void @llvm.memset.p0.i64(ptr align 8 %5, i8 0, i64 6832, i1 false)
  %76 = getelementptr inbounds [1000 x i32], ptr %12, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %76, i8 0, i64 4000, i1 false)
  %77 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 1
  %78 = getelementptr inbounds [80 x i8], ptr %77, i64 0, i64 0
  %79 = load ptr, ptr %3, align 8
  %80 = getelementptr inbounds ptr, ptr %79, i64 1
  %81 = load ptr, ptr %80, align 8
  %82 = call ptr @strcpy(ptr noundef %78, ptr noundef %81) #9
  %83 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 2
  %84 = getelementptr inbounds [30 x i8], ptr %83, i64 0, i64 0
  %85 = load ptr, ptr %3, align 8
  %86 = getelementptr inbounds ptr, ptr %85, i64 2
  %87 = load ptr, ptr %86, align 8
  %88 = call ptr @strcpy(ptr noundef %84, ptr noundef %87) #9
  %89 = getelementptr inbounds [2048 x i8], ptr %6, i64 0, i64 0
  %90 = load ptr, ptr %3, align 8
  %91 = getelementptr inbounds ptr, ptr %90, i64 3
  %92 = load ptr, ptr %91, align 8
  %93 = call ptr @strcpy(ptr noundef %89, ptr noundef %92) #9
  %94 = getelementptr inbounds [2048 x i8], ptr %6, i64 0, i64 0
  %95 = call ptr @strtok(ptr noundef %94, ptr noundef @.str.73) #9
  store ptr %95, ptr %7, align 8
  br label %96

96:                                               ; preds = %239, %75
  %97 = load ptr, ptr %7, align 8
  %98 = icmp ne ptr %97, null
  br i1 %98, label %99, label %257

99:                                               ; preds = %96
  %100 = load ptr, ptr %7, align 8
  call void @trim(ptr noundef %100)
  %101 = load ptr, ptr %7, align 8
  %102 = call i32 @parseCartItem(ptr noundef %101, ptr noundef %13, ptr noundef %14)
  %103 = icmp ne i32 %102, 0
  br i1 %103, label %106, label %104

104:                                              ; preds = %99
  %105 = call i32 (ptr, ...) @printf(ptr noundef @.str.74)
  br label %353

106:                                              ; preds = %99
  %107 = load i32, ptr %13, align 4
  %108 = call i32 @findProductIndexById(i32 noundef %107)
  store i32 %108, ptr %15, align 4
  %109 = load i32, ptr %15, align 4
  %110 = icmp eq i32 %109, -1
  br i1 %110, label %118, label %111

111:                                              ; preds = %106
  %112 = load i32, ptr %15, align 4
  %113 = sext i32 %112 to i64
  %114 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %113
  %115 = getelementptr inbounds nuw %struct.Product, ptr %114, i32 0, i32 6
  %116 = load i32, ptr %115, align 8
  %117 = icmp ne i32 %116, 0
  br i1 %117, label %121, label %118

118:                                              ; preds = %111, %106
  %119 = load i32, ptr %13, align 4
  %120 = call i32 (ptr, ...) @printf(ptr noundef @.str.75, i32 noundef %119)
  br label %353

121:                                              ; preds = %111
  %122 = load i32, ptr %14, align 4
  %123 = load i32, ptr %15, align 4
  %124 = sext i32 %123 to i64
  %125 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %124
  %126 = getelementptr inbounds nuw %struct.Product, ptr %125, i32 0, i32 4
  %127 = load i32, ptr %126, align 16
  %128 = load i32, ptr %15, align 4
  %129 = sext i32 %128 to i64
  %130 = getelementptr inbounds [1000 x i32], ptr %12, i64 0, i64 %129
  %131 = load i32, ptr %130, align 4
  %132 = sub nsw i32 %127, %131
  %133 = icmp sgt i32 %122, %132
  br i1 %133, label %134, label %148

134:                                              ; preds = %121
  %135 = load i32, ptr %13, align 4
  %136 = load i32, ptr %14, align 4
  %137 = load i32, ptr %15, align 4
  %138 = sext i32 %137 to i64
  %139 = getelementptr inbounds [1000 x i32], ptr %12, i64 0, i64 %138
  %140 = load i32, ptr %139, align 4
  %141 = add nsw i32 %136, %140
  %142 = load i32, ptr %15, align 4
  %143 = sext i32 %142 to i64
  %144 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %143
  %145 = getelementptr inbounds nuw %struct.Product, ptr %144, i32 0, i32 4
  %146 = load i32, ptr %145, align 16
  %147 = call i32 (ptr, ...) @printf(ptr noundef @.str.76, i32 noundef %135, i32 noundef %141, i32 noundef %146)
  br label %353

148:                                              ; preds = %121
  %149 = load i32, ptr %13, align 4
  %150 = call i32 @cartAlreadyHas(ptr noundef %5, i32 noundef %149)
  store i32 %150, ptr %16, align 4
  %151 = load i32, ptr %16, align 4
  %152 = icmp ne i32 %151, -1
  br i1 %152, label %153, label %177

153:                                              ; preds = %148
  %154 = load i32, ptr %14, align 4
  %155 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 3
  %156 = load i32, ptr %16, align 4
  %157 = sext i32 %156 to i64
  %158 = getelementptr inbounds [64 x %struct.OrderItem], ptr %155, i64 0, i64 %157
  %159 = getelementptr inbounds nuw %struct.OrderItem, ptr %158, i32 0, i32 2
  %160 = load i32, ptr %159, align 4
  %161 = add nsw i32 %160, %154
  store i32 %161, ptr %159, align 4
  %162 = load i32, ptr %15, align 4
  %163 = sext i32 %162 to i64
  %164 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %163
  %165 = getelementptr inbounds nuw %struct.Product, ptr %164, i32 0, i32 3
  %166 = load i64, ptr %165, align 8
  %167 = load i32, ptr %14, align 4
  %168 = sext i32 %167 to i64
  %169 = mul nsw i64 %166, %168
  %170 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 3
  %171 = load i32, ptr %16, align 4
  %172 = sext i32 %171 to i64
  %173 = getelementptr inbounds [64 x %struct.OrderItem], ptr %170, i64 0, i64 %172
  %174 = getelementptr inbounds nuw %struct.OrderItem, ptr %173, i32 0, i32 4
  %175 = load i64, ptr %174, align 8
  %176 = add nsw i64 %175, %169
  store i64 %176, ptr %174, align 8
  br label %239

177:                                              ; preds = %148
  %178 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %179 = load i32, ptr %178, align 8
  %180 = icmp sge i32 %179, 64
  br i1 %180, label %181, label %183

181:                                              ; preds = %177
  %182 = call i32 (ptr, ...) @printf(ptr noundef @.str.77)
  br label %353

183:                                              ; preds = %177
  %184 = load i32, ptr %13, align 4
  %185 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 3
  %186 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %187 = load i32, ptr %186, align 8
  %188 = sext i32 %187 to i64
  %189 = getelementptr inbounds [64 x %struct.OrderItem], ptr %185, i64 0, i64 %188
  %190 = getelementptr inbounds nuw %struct.OrderItem, ptr %189, i32 0, i32 0
  store i32 %184, ptr %190, align 8
  %191 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 3
  %192 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %193 = load i32, ptr %192, align 8
  %194 = sext i32 %193 to i64
  %195 = getelementptr inbounds [64 x %struct.OrderItem], ptr %191, i64 0, i64 %194
  %196 = getelementptr inbounds nuw %struct.OrderItem, ptr %195, i32 0, i32 1
  %197 = getelementptr inbounds [80 x i8], ptr %196, i64 0, i64 0
  %198 = load i32, ptr %15, align 4
  %199 = sext i32 %198 to i64
  %200 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %199
  %201 = getelementptr inbounds nuw %struct.Product, ptr %200, i32 0, i32 1
  %202 = getelementptr inbounds [80 x i8], ptr %201, i64 0, i64 0
  %203 = call ptr @strcpy(ptr noundef %197, ptr noundef %202) #9
  %204 = load i32, ptr %14, align 4
  %205 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 3
  %206 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %207 = load i32, ptr %206, align 8
  %208 = sext i32 %207 to i64
  %209 = getelementptr inbounds [64 x %struct.OrderItem], ptr %205, i64 0, i64 %208
  %210 = getelementptr inbounds nuw %struct.OrderItem, ptr %209, i32 0, i32 2
  store i32 %204, ptr %210, align 4
  %211 = load i32, ptr %15, align 4
  %212 = sext i32 %211 to i64
  %213 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %212
  %214 = getelementptr inbounds nuw %struct.Product, ptr %213, i32 0, i32 3
  %215 = load i64, ptr %214, align 8
  %216 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 3
  %217 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %218 = load i32, ptr %217, align 8
  %219 = sext i32 %218 to i64
  %220 = getelementptr inbounds [64 x %struct.OrderItem], ptr %216, i64 0, i64 %219
  %221 = getelementptr inbounds nuw %struct.OrderItem, ptr %220, i32 0, i32 3
  store i64 %215, ptr %221, align 8
  %222 = load i32, ptr %15, align 4
  %223 = sext i32 %222 to i64
  %224 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %223
  %225 = getelementptr inbounds nuw %struct.Product, ptr %224, i32 0, i32 3
  %226 = load i64, ptr %225, align 8
  %227 = load i32, ptr %14, align 4
  %228 = sext i32 %227 to i64
  %229 = mul nsw i64 %226, %228
  %230 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 3
  %231 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %232 = load i32, ptr %231, align 8
  %233 = sext i32 %232 to i64
  %234 = getelementptr inbounds [64 x %struct.OrderItem], ptr %230, i64 0, i64 %233
  %235 = getelementptr inbounds nuw %struct.OrderItem, ptr %234, i32 0, i32 4
  store i64 %229, ptr %235, align 8
  %236 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %237 = load i32, ptr %236, align 8
  %238 = add nsw i32 %237, 1
  store i32 %238, ptr %236, align 8
  br label %239

239:                                              ; preds = %183, %153
  %240 = load i32, ptr %14, align 4
  %241 = load i32, ptr %15, align 4
  %242 = sext i32 %241 to i64
  %243 = getelementptr inbounds [1000 x i32], ptr %12, i64 0, i64 %242
  %244 = load i32, ptr %243, align 4
  %245 = add nsw i32 %244, %240
  store i32 %245, ptr %243, align 4
  %246 = load i32, ptr %15, align 4
  %247 = sext i32 %246 to i64
  %248 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %247
  %249 = getelementptr inbounds nuw %struct.Product, ptr %248, i32 0, i32 3
  %250 = load i64, ptr %249, align 8
  %251 = load i32, ptr %14, align 4
  %252 = sext i32 %251 to i64
  %253 = mul nsw i64 %250, %252
  %254 = load i64, ptr %8, align 8
  %255 = add nsw i64 %254, %253
  store i64 %255, ptr %8, align 8
  %256 = call ptr @strtok(ptr noundef null, ptr noundef @.str.73) #9
  store ptr %256, ptr %7, align 8
  br label %96, !llvm.loop !25

257:                                              ; preds = %96
  %258 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 4
  %259 = load i32, ptr %258, align 8
  %260 = icmp eq i32 %259, 0
  br i1 %260, label %261, label %263

261:                                              ; preds = %257
  %262 = call i32 (ptr, ...) @printf(ptr noundef @.str.70)
  br label %353

263:                                              ; preds = %257
  %264 = load i64, ptr %8, align 8
  %265 = load ptr, ptr %3, align 8
  %266 = getelementptr inbounds ptr, ptr %265, i64 2
  %267 = load ptr, ptr %266, align 8
  %268 = call i64 @calculateDiscount(i64 noundef %264, ptr noundef %267)
  store i64 %268, ptr %9, align 8
  %269 = load ptr, ptr %3, align 8
  %270 = getelementptr inbounds ptr, ptr %269, i64 2
  %271 = load ptr, ptr %270, align 8
  %272 = call i32 @equalsIgnoreCase(ptr noundef %271, ptr noundef @.str.46)
  %273 = icmp ne i32 %272, 0
  %274 = zext i1 %273 to i64
  %275 = select i1 %273, i32 0, i32 300
  %276 = sext i32 %275 to i64
  store i64 %276, ptr %10, align 8
  %277 = load i64, ptr %8, align 8
  %278 = load i64, ptr %9, align 8
  %279 = sub nsw i64 %277, %278
  %280 = mul nsw i64 %279, 8
  %281 = sdiv i64 %280, 100
  store i64 %281, ptr %11, align 8
  %282 = load i32, ptr @nextOrderId, align 4
  %283 = add nsw i32 %282, 1
  store i32 %283, ptr @nextOrderId, align 4
  %284 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 0
  store i32 %282, ptr %284, align 8
  %285 = load i64, ptr %8, align 8
  %286 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 5
  store i64 %285, ptr %286, align 8
  %287 = load i64, ptr %9, align 8
  %288 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 6
  store i64 %287, ptr %288, align 8
  %289 = load i64, ptr %10, align 8
  %290 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 7
  store i64 %289, ptr %290, align 8
  %291 = load i64, ptr %11, align 8
  %292 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 8
  store i64 %291, ptr %292, align 8
  %293 = load i64, ptr %8, align 8
  %294 = load i64, ptr %9, align 8
  %295 = sub nsw i64 %293, %294
  %296 = load i64, ptr %10, align 8
  %297 = add nsw i64 %295, %296
  %298 = load i64, ptr %11, align 8
  %299 = add nsw i64 %297, %298
  %300 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 9
  store i64 %299, ptr %300, align 8
  %301 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 10
  store i32 0, ptr %301, align 8
  store i32 0, ptr %17, align 4
  br label %302

302:                                              ; preds = %334, %263
  %303 = load i32, ptr %17, align 4
  %304 = load i32, ptr @productCount, align 4
  %305 = icmp slt i32 %303, %304
  br i1 %305, label %306, label %337

306:                                              ; preds = %302
  %307 = load i32, ptr %17, align 4
  %308 = sext i32 %307 to i64
  %309 = getelementptr inbounds [1000 x i32], ptr %12, i64 0, i64 %308
  %310 = load i32, ptr %309, align 4
  %311 = icmp sgt i32 %310, 0
  br i1 %311, label %312, label %333

312:                                              ; preds = %306
  %313 = load i32, ptr %17, align 4
  %314 = sext i32 %313 to i64
  %315 = getelementptr inbounds [1000 x i32], ptr %12, i64 0, i64 %314
  %316 = load i32, ptr %315, align 4
  %317 = load i32, ptr %17, align 4
  %318 = sext i32 %317 to i64
  %319 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %318
  %320 = getelementptr inbounds nuw %struct.Product, ptr %319, i32 0, i32 4
  %321 = load i32, ptr %320, align 16
  %322 = sub nsw i32 %321, %316
  store i32 %322, ptr %320, align 16
  %323 = load i32, ptr %17, align 4
  %324 = sext i32 %323 to i64
  %325 = getelementptr inbounds [1000 x i32], ptr %12, i64 0, i64 %324
  %326 = load i32, ptr %325, align 4
  %327 = load i32, ptr %17, align 4
  %328 = sext i32 %327 to i64
  %329 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %328
  %330 = getelementptr inbounds nuw %struct.Product, ptr %329, i32 0, i32 5
  %331 = load i32, ptr %330, align 4
  %332 = add nsw i32 %331, %326
  store i32 %332, ptr %330, align 4
  br label %333

333:                                              ; preds = %312, %306
  br label %334

334:                                              ; preds = %333
  %335 = load i32, ptr %17, align 4
  %336 = add nsw i32 %335, 1
  store i32 %336, ptr %17, align 4
  br label %302, !llvm.loop !26

337:                                              ; preds = %302
  %338 = load i32, ptr @orderCount, align 4
  %339 = add nsw i32 %338, 1
  store i32 %339, ptr @orderCount, align 4
  %340 = sext i32 %338 to i64
  %341 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %340
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %341, ptr align 8 %5, i64 6832, i1 false)
  %342 = call i32 (ptr, ...) @printf(ptr noundef @.str.78)
  call void @printOrderShort(ptr noundef %5)
  %343 = load ptr, ptr %3, align 8
  %344 = getelementptr inbounds ptr, ptr %343, i64 2
  %345 = load ptr, ptr %344, align 8
  %346 = call i32 @equalsIgnoreCase(ptr noundef %345, ptr noundef @.str.45)
  %347 = icmp ne i32 %346, 0
  br i1 %347, label %348, label %353

348:                                              ; preds = %337
  %349 = load i64, ptr %9, align 8
  %350 = icmp eq i64 %349, 0
  br i1 %350, label %351, label %353

351:                                              ; preds = %348
  %352 = call i32 (ptr, ...) @printf(ptr noundef @.str.79)
  br label %353

353:                                              ; preds = %20, %34, %48, %56, %61, %70, %104, %118, %134, %181, %261, %351, %348, %337
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #6

; Function Attrs: nounwind
declare ptr @strtok(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdCancel(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %9 = load i32, ptr %4, align 4
  %10 = icmp ne i32 %9, 2
  br i1 %10, label %17, label %11

11:                                               ; preds = %2
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds ptr, ptr %12, i64 1
  %14 = load ptr, ptr %13, align 8
  %15 = call i32 @parseIntStrict(ptr noundef %14, ptr noundef %5)
  %16 = icmp ne i32 %15, 0
  br i1 %16, label %19, label %17

17:                                               ; preds = %11, %2
  %18 = call i32 (ptr, ...) @printf(ptr noundef @.str.80)
  br label %123

19:                                               ; preds = %11
  %20 = load i32, ptr %5, align 4
  %21 = call i32 @findOrderIndexById(i32 noundef %20)
  store i32 %21, ptr %6, align 4
  %22 = load i32, ptr %6, align 4
  %23 = icmp eq i32 %22, -1
  br i1 %23, label %24, label %27

24:                                               ; preds = %19
  %25 = load i32, ptr %5, align 4
  %26 = call i32 (ptr, ...) @printf(ptr noundef @.str.81, i32 noundef %25)
  br label %123

27:                                               ; preds = %19
  %28 = load i32, ptr %6, align 4
  %29 = sext i32 %28 to i64
  %30 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %29
  %31 = getelementptr inbounds nuw %struct.Order, ptr %30, i32 0, i32 10
  %32 = load i32, ptr %31, align 8
  %33 = icmp ne i32 %32, 0
  br i1 %33, label %34, label %37

34:                                               ; preds = %27
  %35 = load i32, ptr %5, align 4
  %36 = call i32 (ptr, ...) @printf(ptr noundef @.str.82, i32 noundef %35)
  br label %123

37:                                               ; preds = %27
  store i32 0, ptr %7, align 4
  br label %38

38:                                               ; preds = %113, %37
  %39 = load i32, ptr %7, align 4
  %40 = load i32, ptr %6, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %41
  %43 = getelementptr inbounds nuw %struct.Order, ptr %42, i32 0, i32 4
  %44 = load i32, ptr %43, align 8
  %45 = icmp slt i32 %39, %44
  br i1 %45, label %46, label %116

46:                                               ; preds = %38
  %47 = load i32, ptr %6, align 4
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %48
  %50 = getelementptr inbounds nuw %struct.Order, ptr %49, i32 0, i32 3
  %51 = load i32, ptr %7, align 4
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds [64 x %struct.OrderItem], ptr %50, i64 0, i64 %52
  %54 = getelementptr inbounds nuw %struct.OrderItem, ptr %53, i32 0, i32 0
  %55 = load i32, ptr %54, align 8
  %56 = call i32 @findProductIndexById(i32 noundef %55)
  store i32 %56, ptr %8, align 4
  %57 = load i32, ptr %8, align 4
  %58 = icmp ne i32 %57, -1
  br i1 %58, label %59, label %112

59:                                               ; preds = %46
  %60 = load i32, ptr %6, align 4
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %61
  %63 = getelementptr inbounds nuw %struct.Order, ptr %62, i32 0, i32 3
  %64 = load i32, ptr %7, align 4
  %65 = sext i32 %64 to i64
  %66 = getelementptr inbounds [64 x %struct.OrderItem], ptr %63, i64 0, i64 %65
  %67 = getelementptr inbounds nuw %struct.OrderItem, ptr %66, i32 0, i32 2
  %68 = load i32, ptr %67, align 4
  %69 = load i32, ptr %8, align 4
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %70
  %72 = getelementptr inbounds nuw %struct.Product, ptr %71, i32 0, i32 4
  %73 = load i32, ptr %72, align 16
  %74 = add nsw i32 %73, %68
  store i32 %74, ptr %72, align 16
  %75 = load i32, ptr %8, align 4
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %76
  %78 = getelementptr inbounds nuw %struct.Product, ptr %77, i32 0, i32 5
  %79 = load i32, ptr %78, align 4
  %80 = load i32, ptr %6, align 4
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %81
  %83 = getelementptr inbounds nuw %struct.Order, ptr %82, i32 0, i32 3
  %84 = load i32, ptr %7, align 4
  %85 = sext i32 %84 to i64
  %86 = getelementptr inbounds [64 x %struct.OrderItem], ptr %83, i64 0, i64 %85
  %87 = getelementptr inbounds nuw %struct.OrderItem, ptr %86, i32 0, i32 2
  %88 = load i32, ptr %87, align 4
  %89 = icmp sge i32 %79, %88
  br i1 %89, label %90, label %106

90:                                               ; preds = %59
  %91 = load i32, ptr %6, align 4
  %92 = sext i32 %91 to i64
  %93 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %92
  %94 = getelementptr inbounds nuw %struct.Order, ptr %93, i32 0, i32 3
  %95 = load i32, ptr %7, align 4
  %96 = sext i32 %95 to i64
  %97 = getelementptr inbounds [64 x %struct.OrderItem], ptr %94, i64 0, i64 %96
  %98 = getelementptr inbounds nuw %struct.OrderItem, ptr %97, i32 0, i32 2
  %99 = load i32, ptr %98, align 4
  %100 = load i32, ptr %8, align 4
  %101 = sext i32 %100 to i64
  %102 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %101
  %103 = getelementptr inbounds nuw %struct.Product, ptr %102, i32 0, i32 5
  %104 = load i32, ptr %103, align 4
  %105 = sub nsw i32 %104, %99
  store i32 %105, ptr %103, align 4
  br label %111

106:                                              ; preds = %59
  %107 = load i32, ptr %8, align 4
  %108 = sext i32 %107 to i64
  %109 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %108
  %110 = getelementptr inbounds nuw %struct.Product, ptr %109, i32 0, i32 5
  store i32 0, ptr %110, align 4
  br label %111

111:                                              ; preds = %106, %90
  br label %112

112:                                              ; preds = %111, %46
  br label %113

113:                                              ; preds = %112
  %114 = load i32, ptr %7, align 4
  %115 = add nsw i32 %114, 1
  store i32 %115, ptr %7, align 4
  br label %38, !llvm.loop !27

116:                                              ; preds = %38
  %117 = load i32, ptr %6, align 4
  %118 = sext i32 %117 to i64
  %119 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %118
  %120 = getelementptr inbounds nuw %struct.Order, ptr %119, i32 0, i32 10
  store i32 1, ptr %120, align 8
  %121 = load i32, ptr %5, align 4
  %122 = call i32 (ptr, ...) @printf(ptr noundef @.str.83, i32 noundef %121)
  br label %123

123:                                              ; preds = %116, %34, %24, %17
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdOrder(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %7 = load i32, ptr %4, align 4
  %8 = icmp ne i32 %7, 2
  br i1 %8, label %15, label %9

9:                                                ; preds = %2
  %10 = load ptr, ptr %3, align 8
  %11 = getelementptr inbounds ptr, ptr %10, i64 1
  %12 = load ptr, ptr %11, align 8
  %13 = call i32 @parseIntStrict(ptr noundef %12, ptr noundef %5)
  %14 = icmp ne i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %9, %2
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.84)
  br label %29

17:                                               ; preds = %9
  %18 = load i32, ptr %5, align 4
  %19 = call i32 @findOrderIndexById(i32 noundef %18)
  store i32 %19, ptr %6, align 4
  %20 = load i32, ptr %6, align 4
  %21 = icmp eq i32 %20, -1
  br i1 %21, label %22, label %25

22:                                               ; preds = %17
  %23 = load i32, ptr %5, align 4
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.85, i32 noundef %23)
  br label %29

25:                                               ; preds = %17
  %26 = load i32, ptr %6, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %27
  call void @printOrderDetail(ptr noundef %28)
  br label %29

29:                                               ; preds = %25, %22, %15
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdOrders() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  store i32 0, ptr %2, align 4
  br label %3

3:                                                ; preds = %11, %0
  %4 = load i32, ptr %2, align 4
  %5 = load i32, ptr @orderCount, align 4
  %6 = icmp slt i32 %4, %5
  br i1 %6, label %7, label %14

7:                                                ; preds = %3
  %8 = load i32, ptr %2, align 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %9
  call void @printOrderShort(ptr noundef %10)
  store i32 1, ptr %1, align 4
  br label %11

11:                                               ; preds = %7
  %12 = load i32, ptr %2, align 4
  %13 = add nsw i32 %12, 1
  store i32 %13, ptr %2, align 4
  br label %3, !llvm.loop !28

14:                                               ; preds = %3
  %15 = load i32, ptr %1, align 4
  %16 = icmp ne i32 %15, 0
  br i1 %16, label %19, label %17

17:                                               ; preds = %14
  %18 = call i32 (ptr, ...) @printf(ptr noundef @.str.86)
  br label %19

19:                                               ; preds = %17, %14
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdReport() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i64, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  store i32 0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  store i64 0, ptr %4, align 8
  store i64 0, ptr %5, align 8
  store i64 0, ptr %6, align 8
  store i64 0, ptr %7, align 8
  store i64 0, ptr %8, align 8
  store i64 0, ptr %9, align 8
  store i32 -1, ptr %10, align 4
  store i32 -1, ptr %11, align 4
  store i32 0, ptr %12, align 4
  br label %15

15:                                               ; preds = %92, %0
  %16 = load i32, ptr %12, align 4
  %17 = load i32, ptr @orderCount, align 4
  %18 = icmp slt i32 %16, %17
  br i1 %18, label %19, label %95

19:                                               ; preds = %15
  %20 = load i32, ptr %12, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %21
  %23 = getelementptr inbounds nuw %struct.Order, ptr %22, i32 0, i32 10
  %24 = load i32, ptr %23, align 8
  %25 = icmp ne i32 %24, 0
  br i1 %25, label %26, label %29

26:                                               ; preds = %19
  %27 = load i32, ptr %2, align 4
  %28 = add nsw i32 %27, 1
  store i32 %28, ptr %2, align 4
  br label %91

29:                                               ; preds = %19
  %30 = load i32, ptr %1, align 4
  %31 = add nsw i32 %30, 1
  store i32 %31, ptr %1, align 4
  %32 = load i32, ptr %12, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %33
  %35 = getelementptr inbounds nuw %struct.Order, ptr %34, i32 0, i32 5
  %36 = load i64, ptr %35, align 16
  %37 = load i64, ptr %4, align 8
  %38 = add nsw i64 %37, %36
  store i64 %38, ptr %4, align 8
  %39 = load i32, ptr %12, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %40
  %42 = getelementptr inbounds nuw %struct.Order, ptr %41, i32 0, i32 6
  %43 = load i64, ptr %42, align 8
  %44 = load i64, ptr %5, align 8
  %45 = add nsw i64 %44, %43
  store i64 %45, ptr %5, align 8
  %46 = load i32, ptr %12, align 4
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %47
  %49 = getelementptr inbounds nuw %struct.Order, ptr %48, i32 0, i32 7
  %50 = load i64, ptr %49, align 16
  %51 = load i64, ptr %6, align 8
  %52 = add nsw i64 %51, %50
  store i64 %52, ptr %6, align 8
  %53 = load i32, ptr %12, align 4
  %54 = sext i32 %53 to i64
  %55 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %54
  %56 = getelementptr inbounds nuw %struct.Order, ptr %55, i32 0, i32 8
  %57 = load i64, ptr %56, align 8
  %58 = load i64, ptr %7, align 8
  %59 = add nsw i64 %58, %57
  store i64 %59, ptr %7, align 8
  %60 = load i32, ptr %12, align 4
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %61
  %63 = getelementptr inbounds nuw %struct.Order, ptr %62, i32 0, i32 9
  %64 = load i64, ptr %63, align 16
  %65 = load i64, ptr %8, align 8
  %66 = add nsw i64 %65, %64
  store i64 %66, ptr %8, align 8
  store i32 0, ptr %13, align 4
  br label %67

67:                                               ; preds = %87, %29
  %68 = load i32, ptr %13, align 4
  %69 = load i32, ptr %12, align 4
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %70
  %72 = getelementptr inbounds nuw %struct.Order, ptr %71, i32 0, i32 4
  %73 = load i32, ptr %72, align 8
  %74 = icmp slt i32 %68, %73
  br i1 %74, label %75, label %90

75:                                               ; preds = %67
  %76 = load i32, ptr %12, align 4
  %77 = sext i32 %76 to i64
  %78 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %77
  %79 = getelementptr inbounds nuw %struct.Order, ptr %78, i32 0, i32 3
  %80 = load i32, ptr %13, align 4
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds [64 x %struct.OrderItem], ptr %79, i64 0, i64 %81
  %83 = getelementptr inbounds nuw %struct.OrderItem, ptr %82, i32 0, i32 2
  %84 = load i32, ptr %83, align 4
  %85 = load i32, ptr %3, align 4
  %86 = add nsw i32 %85, %84
  store i32 %86, ptr %3, align 4
  br label %87

87:                                               ; preds = %75
  %88 = load i32, ptr %13, align 4
  %89 = add nsw i32 %88, 1
  store i32 %89, ptr %13, align 4
  br label %67, !llvm.loop !29

90:                                               ; preds = %67
  br label %91

91:                                               ; preds = %90, %26
  br label %92

92:                                               ; preds = %91
  %93 = load i32, ptr %12, align 4
  %94 = add nsw i32 %93, 1
  store i32 %94, ptr %12, align 4
  br label %15, !llvm.loop !30

95:                                               ; preds = %15
  store i32 0, ptr %14, align 4
  br label %96

96:                                               ; preds = %142, %95
  %97 = load i32, ptr %14, align 4
  %98 = load i32, ptr @productCount, align 4
  %99 = icmp slt i32 %97, %98
  br i1 %99, label %100, label %145

100:                                              ; preds = %96
  %101 = load i32, ptr %14, align 4
  %102 = sext i32 %101 to i64
  %103 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %102
  %104 = getelementptr inbounds nuw %struct.Product, ptr %103, i32 0, i32 6
  %105 = load i32, ptr %104, align 8
  %106 = icmp ne i32 %105, 0
  br i1 %106, label %107, label %141

107:                                              ; preds = %100
  %108 = load i32, ptr %14, align 4
  %109 = sext i32 %108 to i64
  %110 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %109
  %111 = getelementptr inbounds nuw %struct.Product, ptr %110, i32 0, i32 3
  %112 = load i64, ptr %111, align 8
  %113 = load i32, ptr %14, align 4
  %114 = sext i32 %113 to i64
  %115 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %114
  %116 = getelementptr inbounds nuw %struct.Product, ptr %115, i32 0, i32 4
  %117 = load i32, ptr %116, align 16
  %118 = sext i32 %117 to i64
  %119 = mul nsw i64 %112, %118
  %120 = load i64, ptr %9, align 8
  %121 = add nsw i64 %120, %119
  store i64 %121, ptr %9, align 8
  %122 = load i32, ptr %14, align 4
  %123 = sext i32 %122 to i64
  %124 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %123
  %125 = getelementptr inbounds nuw %struct.Product, ptr %124, i32 0, i32 5
  %126 = load i32, ptr %125, align 4
  %127 = load i32, ptr %11, align 4
  %128 = icmp sgt i32 %126, %127
  br i1 %128, label %129, label %140

129:                                              ; preds = %107
  %130 = load i32, ptr %14, align 4
  %131 = sext i32 %130 to i64
  %132 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %131
  %133 = getelementptr inbounds nuw %struct.Product, ptr %132, i32 0, i32 5
  %134 = load i32, ptr %133, align 4
  store i32 %134, ptr %11, align 4
  %135 = load i32, ptr %14, align 4
  %136 = sext i32 %135 to i64
  %137 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %136
  %138 = getelementptr inbounds nuw %struct.Product, ptr %137, i32 0, i32 0
  %139 = load i32, ptr %138, align 16
  store i32 %139, ptr %10, align 4
  br label %140

140:                                              ; preds = %129, %107
  br label %141

141:                                              ; preds = %140, %100
  br label %142

142:                                              ; preds = %141
  %143 = load i32, ptr %14, align 4
  %144 = add nsw i32 %143, 1
  store i32 %144, ptr %14, align 4
  br label %96, !llvm.loop !31

145:                                              ; preds = %96
  %146 = call i32 (ptr, ...) @printf(ptr noundef @.str.87)
  %147 = load i32, ptr %1, align 4
  %148 = call i32 (ptr, ...) @printf(ptr noundef @.str.88, i32 noundef %147)
  %149 = load i32, ptr %2, align 4
  %150 = call i32 (ptr, ...) @printf(ptr noundef @.str.89, i32 noundef %149)
  %151 = load i32, ptr %3, align 4
  %152 = call i32 (ptr, ...) @printf(ptr noundef @.str.90, i32 noundef %151)
  %153 = call i32 (ptr, ...) @printf(ptr noundef @.str.91)
  %154 = load i64, ptr %4, align 8
  call void @printMoney(i64 noundef %154)
  %155 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %156 = call i32 (ptr, ...) @printf(ptr noundef @.str.63)
  %157 = load i64, ptr %5, align 8
  call void @printMoney(i64 noundef %157)
  %158 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %159 = call i32 (ptr, ...) @printf(ptr noundef @.str.64)
  %160 = load i64, ptr %6, align 8
  call void @printMoney(i64 noundef %160)
  %161 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %162 = call i32 (ptr, ...) @printf(ptr noundef @.str.65)
  %163 = load i64, ptr %7, align 8
  call void @printMoney(i64 noundef %163)
  %164 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %165 = call i32 (ptr, ...) @printf(ptr noundef @.str.92)
  %166 = load i64, ptr %8, align 8
  call void @printMoney(i64 noundef %166)
  %167 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %168 = call i32 (ptr, ...) @printf(ptr noundef @.str.93)
  %169 = load i64, ptr %9, align 8
  call void @printMoney(i64 noundef %169)
  %170 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %171 = load i32, ptr %10, align 4
  %172 = icmp eq i32 %171, -1
  br i1 %172, label %176, label %173

173:                                              ; preds = %145
  %174 = load i32, ptr %11, align 4
  %175 = icmp sle i32 %174, 0
  br i1 %175, label %176, label %178

176:                                              ; preds = %173, %145
  %177 = call i32 (ptr, ...) @printf(ptr noundef @.str.94)
  br label %182

178:                                              ; preds = %173
  %179 = load i32, ptr %10, align 4
  %180 = load i32, ptr %11, align 4
  %181 = call i32 (ptr, ...) @printf(ptr noundef @.str.95, i32 noundef %179, i32 noundef %180)
  br label %182

182:                                              ; preds = %178, %176
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSave(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %9 = load i32, ptr %4, align 4
  %10 = icmp ne i32 %9, 2
  br i1 %10, label %11, label %13

11:                                               ; preds = %2
  %12 = call i32 (ptr, ...) @printf(ptr noundef @.str.96)
  br label %205

13:                                               ; preds = %2
  %14 = load ptr, ptr %3, align 8
  %15 = getelementptr inbounds ptr, ptr %14, i64 1
  %16 = load ptr, ptr %15, align 8
  %17 = call noalias ptr @fopen(ptr noundef %16, ptr noundef @.str.97)
  store ptr %17, ptr %5, align 8
  %18 = load ptr, ptr %5, align 8
  %19 = icmp ne ptr %18, null
  br i1 %19, label %25, label %20

20:                                               ; preds = %13
  %21 = load ptr, ptr %3, align 8
  %22 = getelementptr inbounds ptr, ptr %21, i64 1
  %23 = load ptr, ptr %22, align 8
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.98, ptr noundef %23)
  br label %205

25:                                               ; preds = %13
  %26 = load ptr, ptr %5, align 8
  %27 = load i32, ptr @productCount, align 4
  %28 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %26, ptr noundef @.str.99, i32 noundef %27) #9
  store i32 0, ptr %6, align 4
  br label %29

29:                                               ; preds = %71, %25
  %30 = load i32, ptr %6, align 4
  %31 = load i32, ptr @productCount, align 4
  %32 = icmp slt i32 %30, %31
  br i1 %32, label %33, label %74

33:                                               ; preds = %29
  %34 = load ptr, ptr %5, align 8
  %35 = load i32, ptr %6, align 4
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %36
  %38 = getelementptr inbounds nuw %struct.Product, ptr %37, i32 0, i32 0
  %39 = load i32, ptr %38, align 16
  %40 = load i32, ptr %6, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %41
  %43 = getelementptr inbounds nuw %struct.Product, ptr %42, i32 0, i32 1
  %44 = getelementptr inbounds [80 x i8], ptr %43, i64 0, i64 0
  %45 = load i32, ptr %6, align 4
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %46
  %48 = getelementptr inbounds nuw %struct.Product, ptr %47, i32 0, i32 2
  %49 = getelementptr inbounds [50 x i8], ptr %48, i64 0, i64 0
  %50 = load i32, ptr %6, align 4
  %51 = sext i32 %50 to i64
  %52 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %51
  %53 = getelementptr inbounds nuw %struct.Product, ptr %52, i32 0, i32 3
  %54 = load i64, ptr %53, align 8
  %55 = load i32, ptr %6, align 4
  %56 = sext i32 %55 to i64
  %57 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %56
  %58 = getelementptr inbounds nuw %struct.Product, ptr %57, i32 0, i32 4
  %59 = load i32, ptr %58, align 16
  %60 = load i32, ptr %6, align 4
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %61
  %63 = getelementptr inbounds nuw %struct.Product, ptr %62, i32 0, i32 5
  %64 = load i32, ptr %63, align 4
  %65 = load i32, ptr %6, align 4
  %66 = sext i32 %65 to i64
  %67 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %66
  %68 = getelementptr inbounds nuw %struct.Product, ptr %67, i32 0, i32 6
  %69 = load i32, ptr %68, align 8
  %70 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %34, ptr noundef @.str.100, i32 noundef %39, ptr noundef %44, ptr noundef %49, i64 noundef %54, i32 noundef %59, i32 noundef %64, i32 noundef %69) #9
  br label %71

71:                                               ; preds = %33
  %72 = load i32, ptr %6, align 4
  %73 = add nsw i32 %72, 1
  store i32 %73, ptr %6, align 4
  br label %29, !llvm.loop !32

74:                                               ; preds = %29
  %75 = load ptr, ptr %5, align 8
  %76 = load i32, ptr @orderCount, align 4
  %77 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %75, ptr noundef @.str.101, i32 noundef %76) #9
  store i32 0, ptr %7, align 4
  br label %78

78:                                               ; preds = %195, %74
  %79 = load i32, ptr %7, align 4
  %80 = load i32, ptr @orderCount, align 4
  %81 = icmp slt i32 %79, %80
  br i1 %81, label %82, label %198

82:                                               ; preds = %78
  %83 = load ptr, ptr %5, align 8
  %84 = load i32, ptr %7, align 4
  %85 = sext i32 %84 to i64
  %86 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %85
  %87 = getelementptr inbounds nuw %struct.Order, ptr %86, i32 0, i32 0
  %88 = load i32, ptr %87, align 16
  %89 = load i32, ptr %7, align 4
  %90 = sext i32 %89 to i64
  %91 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %90
  %92 = getelementptr inbounds nuw %struct.Order, ptr %91, i32 0, i32 1
  %93 = getelementptr inbounds [80 x i8], ptr %92, i64 0, i64 0
  %94 = load i32, ptr %7, align 4
  %95 = sext i32 %94 to i64
  %96 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %95
  %97 = getelementptr inbounds nuw %struct.Order, ptr %96, i32 0, i32 2
  %98 = getelementptr inbounds [30 x i8], ptr %97, i64 0, i64 0
  %99 = load i32, ptr %7, align 4
  %100 = sext i32 %99 to i64
  %101 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %100
  %102 = getelementptr inbounds nuw %struct.Order, ptr %101, i32 0, i32 4
  %103 = load i32, ptr %102, align 8
  %104 = load i32, ptr %7, align 4
  %105 = sext i32 %104 to i64
  %106 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %105
  %107 = getelementptr inbounds nuw %struct.Order, ptr %106, i32 0, i32 5
  %108 = load i64, ptr %107, align 16
  %109 = load i32, ptr %7, align 4
  %110 = sext i32 %109 to i64
  %111 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %110
  %112 = getelementptr inbounds nuw %struct.Order, ptr %111, i32 0, i32 6
  %113 = load i64, ptr %112, align 8
  %114 = load i32, ptr %7, align 4
  %115 = sext i32 %114 to i64
  %116 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %115
  %117 = getelementptr inbounds nuw %struct.Order, ptr %116, i32 0, i32 7
  %118 = load i64, ptr %117, align 16
  %119 = load i32, ptr %7, align 4
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %120
  %122 = getelementptr inbounds nuw %struct.Order, ptr %121, i32 0, i32 8
  %123 = load i64, ptr %122, align 8
  %124 = load i32, ptr %7, align 4
  %125 = sext i32 %124 to i64
  %126 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %125
  %127 = getelementptr inbounds nuw %struct.Order, ptr %126, i32 0, i32 9
  %128 = load i64, ptr %127, align 16
  %129 = load i32, ptr %7, align 4
  %130 = sext i32 %129 to i64
  %131 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %130
  %132 = getelementptr inbounds nuw %struct.Order, ptr %131, i32 0, i32 10
  %133 = load i32, ptr %132, align 8
  %134 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %83, ptr noundef @.str.102, i32 noundef %88, ptr noundef %93, ptr noundef %98, i32 noundef %103, i64 noundef %108, i64 noundef %113, i64 noundef %118, i64 noundef %123, i64 noundef %128, i32 noundef %133) #9
  store i32 0, ptr %8, align 4
  br label %135

135:                                              ; preds = %191, %82
  %136 = load i32, ptr %8, align 4
  %137 = load i32, ptr %7, align 4
  %138 = sext i32 %137 to i64
  %139 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %138
  %140 = getelementptr inbounds nuw %struct.Order, ptr %139, i32 0, i32 4
  %141 = load i32, ptr %140, align 8
  %142 = icmp slt i32 %136, %141
  br i1 %142, label %143, label %194

143:                                              ; preds = %135
  %144 = load ptr, ptr %5, align 8
  %145 = load i32, ptr %7, align 4
  %146 = sext i32 %145 to i64
  %147 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %146
  %148 = getelementptr inbounds nuw %struct.Order, ptr %147, i32 0, i32 3
  %149 = load i32, ptr %8, align 4
  %150 = sext i32 %149 to i64
  %151 = getelementptr inbounds [64 x %struct.OrderItem], ptr %148, i64 0, i64 %150
  %152 = getelementptr inbounds nuw %struct.OrderItem, ptr %151, i32 0, i32 0
  %153 = load i32, ptr %152, align 8
  %154 = load i32, ptr %7, align 4
  %155 = sext i32 %154 to i64
  %156 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %155
  %157 = getelementptr inbounds nuw %struct.Order, ptr %156, i32 0, i32 3
  %158 = load i32, ptr %8, align 4
  %159 = sext i32 %158 to i64
  %160 = getelementptr inbounds [64 x %struct.OrderItem], ptr %157, i64 0, i64 %159
  %161 = getelementptr inbounds nuw %struct.OrderItem, ptr %160, i32 0, i32 1
  %162 = getelementptr inbounds [80 x i8], ptr %161, i64 0, i64 0
  %163 = load i32, ptr %7, align 4
  %164 = sext i32 %163 to i64
  %165 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %164
  %166 = getelementptr inbounds nuw %struct.Order, ptr %165, i32 0, i32 3
  %167 = load i32, ptr %8, align 4
  %168 = sext i32 %167 to i64
  %169 = getelementptr inbounds [64 x %struct.OrderItem], ptr %166, i64 0, i64 %168
  %170 = getelementptr inbounds nuw %struct.OrderItem, ptr %169, i32 0, i32 2
  %171 = load i32, ptr %170, align 4
  %172 = load i32, ptr %7, align 4
  %173 = sext i32 %172 to i64
  %174 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %173
  %175 = getelementptr inbounds nuw %struct.Order, ptr %174, i32 0, i32 3
  %176 = load i32, ptr %8, align 4
  %177 = sext i32 %176 to i64
  %178 = getelementptr inbounds [64 x %struct.OrderItem], ptr %175, i64 0, i64 %177
  %179 = getelementptr inbounds nuw %struct.OrderItem, ptr %178, i32 0, i32 3
  %180 = load i64, ptr %179, align 8
  %181 = load i32, ptr %7, align 4
  %182 = sext i32 %181 to i64
  %183 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %182
  %184 = getelementptr inbounds nuw %struct.Order, ptr %183, i32 0, i32 3
  %185 = load i32, ptr %8, align 4
  %186 = sext i32 %185 to i64
  %187 = getelementptr inbounds [64 x %struct.OrderItem], ptr %184, i64 0, i64 %186
  %188 = getelementptr inbounds nuw %struct.OrderItem, ptr %187, i32 0, i32 4
  %189 = load i64, ptr %188, align 8
  %190 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %144, ptr noundef @.str.103, i32 noundef %153, ptr noundef %162, i32 noundef %171, i64 noundef %180, i64 noundef %189) #9
  br label %191

191:                                              ; preds = %143
  %192 = load i32, ptr %8, align 4
  %193 = add nsw i32 %192, 1
  store i32 %193, ptr %8, align 4
  br label %135, !llvm.loop !33

194:                                              ; preds = %135
  br label %195

195:                                              ; preds = %194
  %196 = load i32, ptr %7, align 4
  %197 = add nsw i32 %196, 1
  store i32 %197, ptr %7, align 4
  br label %78, !llvm.loop !34

198:                                              ; preds = %78
  %199 = load ptr, ptr %5, align 8
  %200 = call i32 @fclose(ptr noundef %199)
  %201 = load ptr, ptr %3, align 8
  %202 = getelementptr inbounds ptr, ptr %201, i64 1
  %203 = load ptr, ptr %202, align 8
  %204 = call i32 (ptr, ...) @printf(ptr noundef @.str.104, ptr noundef %203)
  br label %205

205:                                              ; preds = %198, %20, %11
  ret void
}

declare noalias ptr @fopen(ptr noundef, ptr noundef) #4

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #5

declare i32 @fclose(ptr noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @handleCommand(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca [16 x ptr], align 16
  %6 = alloca i32, align 4
  %7 = alloca [64 x i8], align 16
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %8 = load ptr, ptr %3, align 8
  call void @trim(ptr noundef %8)
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds i8, ptr %9, i64 0
  %11 = load i8, ptr %10, align 1
  %12 = sext i8 %11 to i32
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %17

14:                                               ; preds = %2
  %15 = load i32, ptr %4, align 4
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.105, i32 noundef %15)
  br label %144

17:                                               ; preds = %2
  %18 = load ptr, ptr %3, align 8
  %19 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %20 = call i32 @splitPipe(ptr noundef %18, ptr noundef %19, i32 noundef 16)
  store i32 %20, ptr %6, align 4
  %21 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %22 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %23 = load ptr, ptr %22, align 16
  %24 = call ptr @strcpy(ptr noundef %21, ptr noundef %23) #9
  %25 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  call void @upperString(ptr noundef %25)
  %26 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %27 = call i32 (ptr, ...) @printf(ptr noundef @.str.106, ptr noundef %26)
  %28 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %29 = call i32 @strcmp(ptr noundef %28, ptr noundef @.str.107) #8
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %31, label %34

31:                                               ; preds = %17
  %32 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %33 = load i32, ptr %6, align 4
  call void @cmdAdd(ptr noundef %32, i32 noundef %33)
  br label %144

34:                                               ; preds = %17
  %35 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %36 = call i32 @strcmp(ptr noundef %35, ptr noundef @.str.108) #8
  %37 = icmp eq i32 %36, 0
  br i1 %37, label %38, label %41

38:                                               ; preds = %34
  %39 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %40 = load i32, ptr %6, align 4
  call void @cmdRemove(ptr noundef %39, i32 noundef %40)
  br label %143

41:                                               ; preds = %34
  %42 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %43 = call i32 @strcmp(ptr noundef %42, ptr noundef @.str.109) #8
  %44 = icmp eq i32 %43, 0
  br i1 %44, label %45, label %48

45:                                               ; preds = %41
  %46 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %47 = load i32, ptr %6, align 4
  call void @cmdRestock(ptr noundef %46, i32 noundef %47)
  br label %142

48:                                               ; preds = %41
  %49 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %50 = call i32 @strcmp(ptr noundef %49, ptr noundef @.str.110) #8
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %52, label %55

52:                                               ; preds = %48
  %53 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %54 = load i32, ptr %6, align 4
  call void @cmdUpdatePrice(ptr noundef %53, i32 noundef %54)
  br label %141

55:                                               ; preds = %48
  %56 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %57 = call i32 @strcmp(ptr noundef %56, ptr noundef @.str.111) #8
  %58 = icmp eq i32 %57, 0
  br i1 %58, label %59, label %60

59:                                               ; preds = %55
  call void @cmdList()
  br label %140

60:                                               ; preds = %55
  %61 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %62 = call i32 @strcmp(ptr noundef %61, ptr noundef @.str.112) #8
  %63 = icmp eq i32 %62, 0
  br i1 %63, label %64, label %67

64:                                               ; preds = %60
  %65 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %66 = load i32, ptr %6, align 4
  call void @cmdSearchName(ptr noundef %65, i32 noundef %66)
  br label %139

67:                                               ; preds = %60
  %68 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %69 = call i32 @strcmp(ptr noundef %68, ptr noundef @.str.113) #8
  %70 = icmp eq i32 %69, 0
  br i1 %70, label %71, label %74

71:                                               ; preds = %67
  %72 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %73 = load i32, ptr %6, align 4
  call void @cmdSearchCategory(ptr noundef %72, i32 noundef %73)
  br label %138

74:                                               ; preds = %67
  %75 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %76 = call i32 @strcmp(ptr noundef %75, ptr noundef @.str.114) #8
  %77 = icmp eq i32 %76, 0
  br i1 %77, label %78, label %81

78:                                               ; preds = %74
  %79 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %80 = load i32, ptr %6, align 4
  call void @cmdLowStock(ptr noundef %79, i32 noundef %80)
  br label %137

81:                                               ; preds = %74
  %82 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %83 = call i32 @strcmp(ptr noundef %82, ptr noundef @.str.115) #8
  %84 = icmp eq i32 %83, 0
  br i1 %84, label %85, label %88

85:                                               ; preds = %81
  %86 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %87 = load i32, ptr %6, align 4
  call void @cmdSort(ptr noundef %86, i32 noundef %87)
  br label %136

88:                                               ; preds = %81
  %89 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %90 = call i32 @strcmp(ptr noundef %89, ptr noundef @.str.116) #8
  %91 = icmp eq i32 %90, 0
  br i1 %91, label %92, label %95

92:                                               ; preds = %88
  %93 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %94 = load i32, ptr %6, align 4
  call void @cmdBuy(ptr noundef %93, i32 noundef %94)
  br label %135

95:                                               ; preds = %88
  %96 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %97 = call i32 @strcmp(ptr noundef %96, ptr noundef @.str.117) #8
  %98 = icmp eq i32 %97, 0
  br i1 %98, label %99, label %102

99:                                               ; preds = %95
  %100 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %101 = load i32, ptr %6, align 4
  call void @cmdCancel(ptr noundef %100, i32 noundef %101)
  br label %134

102:                                              ; preds = %95
  %103 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %104 = call i32 @strcmp(ptr noundef %103, ptr noundef @.str.118) #8
  %105 = icmp eq i32 %104, 0
  br i1 %105, label %106, label %109

106:                                              ; preds = %102
  %107 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %108 = load i32, ptr %6, align 4
  call void @cmdOrder(ptr noundef %107, i32 noundef %108)
  br label %133

109:                                              ; preds = %102
  %110 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %111 = call i32 @strcmp(ptr noundef %110, ptr noundef @.str.119) #8
  %112 = icmp eq i32 %111, 0
  br i1 %112, label %113, label %114

113:                                              ; preds = %109
  call void @cmdOrders()
  br label %132

114:                                              ; preds = %109
  %115 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %116 = call i32 @strcmp(ptr noundef %115, ptr noundef @.str.120) #8
  %117 = icmp eq i32 %116, 0
  br i1 %117, label %118, label %119

118:                                              ; preds = %114
  call void @cmdReport()
  br label %131

119:                                              ; preds = %114
  %120 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %121 = call i32 @strcmp(ptr noundef %120, ptr noundef @.str.121) #8
  %122 = icmp eq i32 %121, 0
  br i1 %122, label %123, label %126

123:                                              ; preds = %119
  %124 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %125 = load i32, ptr %6, align 4
  call void @cmdSave(ptr noundef %124, i32 noundef %125)
  br label %130

126:                                              ; preds = %119
  %127 = getelementptr inbounds [16 x ptr], ptr %5, i64 0, i64 0
  %128 = load ptr, ptr %127, align 16
  %129 = call i32 (ptr, ...) @printf(ptr noundef @.str.122, ptr noundef %128)
  br label %130

130:                                              ; preds = %126, %123
  br label %131

131:                                              ; preds = %130, %118
  br label %132

132:                                              ; preds = %131, %113
  br label %133

133:                                              ; preds = %132, %106
  br label %134

134:                                              ; preds = %133, %99
  br label %135

135:                                              ; preds = %134, %92
  br label %136

136:                                              ; preds = %135, %85
  br label %137

137:                                              ; preds = %136, %78
  br label %138

138:                                              ; preds = %137, %71
  br label %139

139:                                              ; preds = %138, %64
  br label %140

140:                                              ; preds = %139, %59
  br label %141

141:                                              ; preds = %140, %52
  br label %142

142:                                              ; preds = %141, %45
  br label %143

143:                                              ; preds = %142, %38
  br label %144

144:                                              ; preds = %14, %143, %31
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca [2048 x i8], align 16
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  %5 = getelementptr inbounds [2048 x i8], ptr %2, i64 0, i64 0
  %6 = load ptr, ptr @stdin, align 8
  %7 = call ptr @fgets(ptr noundef %5, i32 noundef 2048, ptr noundef %6)
  %8 = icmp ne ptr %7, null
  br i1 %8, label %11, label %9

9:                                                ; preds = %0
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.123)
  store i32 0, ptr %1, align 4
  br label %46

11:                                               ; preds = %0
  %12 = getelementptr inbounds [2048 x i8], ptr %2, i64 0, i64 0
  call void @trim(ptr noundef %12)
  %13 = getelementptr inbounds [2048 x i8], ptr %2, i64 0, i64 0
  %14 = call i32 @parseIntStrict(ptr noundef %13, ptr noundef %3)
  %15 = icmp ne i32 %14, 0
  br i1 %15, label %16, label %19

16:                                               ; preds = %11
  %17 = load i32, ptr %3, align 4
  %18 = icmp slt i32 %17, 0
  br i1 %18, label %19, label %21

19:                                               ; preds = %16, %11
  %20 = call i32 (ptr, ...) @printf(ptr noundef @.str.124)
  store i32 0, ptr %1, align 4
  br label %46

21:                                               ; preds = %16
  %22 = load i32, ptr %3, align 4
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.125, i32 noundef %22)
  store i32 1, ptr %4, align 4
  br label %24

24:                                               ; preds = %39, %21
  %25 = load i32, ptr %4, align 4
  %26 = load i32, ptr %3, align 4
  %27 = icmp sle i32 %25, %26
  br i1 %27, label %28, label %42

28:                                               ; preds = %24
  %29 = getelementptr inbounds [2048 x i8], ptr %2, i64 0, i64 0
  %30 = load ptr, ptr @stdin, align 8
  %31 = call ptr @fgets(ptr noundef %29, i32 noundef 2048, ptr noundef %30)
  %32 = icmp ne ptr %31, null
  br i1 %32, label %36, label %33

33:                                               ; preds = %28
  %34 = load i32, ptr %4, align 4
  %35 = call i32 (ptr, ...) @printf(ptr noundef @.str.126, i32 noundef %34)
  br label %42

36:                                               ; preds = %28
  %37 = getelementptr inbounds [2048 x i8], ptr %2, i64 0, i64 0
  %38 = load i32, ptr %4, align 4
  call void @handleCommand(ptr noundef %37, i32 noundef %38)
  br label %39

39:                                               ; preds = %36
  %40 = load i32, ptr %4, align 4
  %41 = add nsw i32 %40, 1
  store i32 %41, ptr %4, align 4
  br label %24, !llvm.loop !35

42:                                               ; preds = %33, %24
  %43 = load i32, ptr @productCount, align 4
  %44 = load i32, ptr @orderCount, align 4
  %45 = call i32 (ptr, ...) @printf(ptr noundef @.str.127, i32 noundef %43, i32 noundef %44)
  store i32 0, ptr %1, align 4
  br label %46

46:                                               ; preds = %42, %19, %9
  %47 = load i32, ptr %1, align 4
  ret i32 %47
}

declare ptr @fgets(ptr noundef, i32 noundef, ptr noundef) #4

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #7 = { nounwind willreturn memory(none) }
attributes #8 = { nounwind willreturn memory(read) }
attributes #9 = { nounwind }

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

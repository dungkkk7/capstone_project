; ModuleID = 'data/obfuscated/command_io/obfuscated.bc'
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
@0 = private global i32 0
@1 = private global i32 0
@2 = private global i32 0
@3 = private global i32 0

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @trim(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca i1, align 1
  %6 = alloca i1, align 1
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 1722636471, ptr %4, align 4
  br label %10

10:                                               ; preds = %510, %295, %294, %1
  %11 = load i32, ptr %4, align 4
  %12 = sub i32 %11, 1370368122
  %13 = mul i32 %12, -1847550211
  switch i32 %13, label %295 [
    i32 39342665, label %14
    i32 1286153554, label %24
    i32 900267055, label %43
    i32 1778729903, label %86
    i32 1809140927, label %99
    i32 259153452, label %125
    i32 1715210011, label %139
    i32 1810943323, label %163
    i32 124550598, label %177
    i32 912412178, label %191
    i32 968520840, label %239
    i32 945987273, label %251
    i32 1162984337, label %293
    i32 1652340603, label %304
    i32 222617335, label %317
    i32 1591450685, label %330
    i32 1547031496, label %341
    i32 1018963107, label %363
    i32 180673332, label %375
    i32 755882493, label %395
    i32 1299591106, label %408
  ]

14:                                               ; preds = %10
  store ptr %0, ptr %7, align 8
  store i32 0, ptr %9, align 4
  store i32 1105316020, ptr %4, align 4
  %15 = xor i32 %3, -718502279
  %16 = and i32 %3, %15
  %17 = or i32 %3, %15
  %18 = xor i32 %3, %15
  %19 = add i32 %16, %17
  %20 = sub i32 %19, %3
  %21 = sub i32 %20, %15
  %22 = mul i32 %21, 144
  %23 = icmp sgt i32 %22, 0
  br i1 %23, label %421, label %294

24:                                               ; preds = %10
  %25 = load ptr, ptr %7, align 8
  %26 = load i32, ptr %9, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds i8, ptr %25, i64 %27
  %29 = load i8, ptr %28, align 1
  %30 = sext i8 %29 to i32
  %31 = icmp ne i32 %30, 0
  store i1 false, ptr %5, align 1
  %32 = select i1 %31, i32 -609118699, i32 -2100407403
  store i32 %32, ptr %4, align 4
  %33 = xor i32 %3, -2077917039
  %34 = and i32 %3, %33
  %35 = or i32 %3, %33
  %36 = xor i32 %3, %33
  %37 = mul i32 %35, 2
  %38 = sub i32 %37, %36
  %39 = sub i32 %38, %3
  %40 = sub i32 %39, %33
  %41 = mul i32 %40, 176
  %42 = icmp sle i32 %41, 0
  br i1 %42, label %294, label %427

43:                                               ; preds = %10
  %44 = call ptr @__ctype_b_loc() #7
  %45 = load ptr, ptr %44, align 8
  %46 = load ptr, ptr %7, align 8
  %47 = load i32, ptr %9, align 4
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds i8, ptr %46, i64 %48
  %50 = load i8, ptr %49, align 1
  %51 = zext i8 %50 to i32
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds i16, ptr %45, i64 %52
  %54 = load i16, ptr %53, align 2
  %55 = zext i16 %54 to i32
  %56 = load i32, ptr %4, align 4
  %57 = xor i32 %56, -609110507
  %58 = add i32 %55, %57
  %59 = load i32, ptr %4, align 4
  %60 = xor i32 %59, -609110507
  %61 = or i32 %55, %60
  %62 = load i32, ptr %4, align 4
  %63 = xor i32 %62, -1553959726
  %64 = mul i32 %58, %63
  %65 = load i32, ptr %4, align 4
  %66 = xor i32 %65, -1553959726
  %67 = mul i32 %61, %66
  %68 = sub i32 %64, %67
  %69 = load i32, ptr %4, align 4
  %70 = xor i32 %69, 718750134
  %71 = mul i32 %68, %70
  %72 = load i32, ptr %4, align 4
  %73 = xor i32 %72, 2138412680
  %74 = mul i32 %71, %73
  %75 = icmp ne i32 %74, 0
  store i1 %75, ptr %5, align 1
  store i32 -2100407403, ptr %4, align 4
  %76 = xor i32 %3, 1358084659
  %77 = and i32 %3, %76
  %78 = or i32 %3, %76
  %79 = xor i32 %3, %76
  %80 = mul i32 %78, 2
  %81 = sub i32 %80, %79
  %82 = sub i32 %81, %3
  %83 = sub i32 %82, %76
  %84 = mul i32 %83, 201
  %85 = icmp slt i32 %84, 1
  br i1 %85, label %294, label %434

86:                                               ; preds = %10
  %87 = load i1, ptr %5, align 1
  %88 = select i1 %87, i32 772683237, i32 -2059119338
  store i32 %88, ptr %4, align 4
  %89 = xor i32 %3, -100562379
  %90 = and i32 %3, %89
  %91 = or i32 %3, %89
  %92 = xor i32 %3, %89
  %93 = add i32 %3, %89
  %94 = sub i32 %93, %92
  %95 = mul i32 %90, 2
  %96 = sub i32 %94, %95
  %97 = mul i32 %96, 190
  %98 = icmp uge i32 %97, 0
  br i1 %98, label %294, label %442

99:                                               ; preds = %10
  %100 = load i32, ptr %9, align 4
  %101 = load i32, ptr %4, align 4
  %102 = xor i32 %101, 772683236
  %103 = or i32 %100, %102
  %104 = load i32, ptr %4, align 4
  %105 = xor i32 %104, 772683236
  %106 = and i32 %100, %105
  %107 = add i32 %103, %106
  store i32 %107, ptr %9, align 4
  store i32 1105316020, ptr %4, align 4
  %108 = xor i32 %3, -1199871327
  %109 = and i32 %3, %108
  %110 = or i32 %3, %108
  %111 = xor i32 %3, %108
  %112 = sub i32 %110, %111
  %113 = sub i32 %112, %109
  %114 = mul i32 %113, 103
  %115 = xor i32 %3, -1945988229
  %116 = and i32 %3, %115
  %117 = or i32 %3, %115
  %118 = xor i32 %3, %115
  %119 = mul i32 %117, 2
  %120 = sub i32 %119, %118
  %121 = sub i32 %120, %3
  %122 = sub i32 %121, %115
  %123 = mul i32 %122, 25
  %124 = icmp ne i32 %114, %123
  br i1 %124, label %451, label %294

125:                                              ; preds = %10
  %126 = load i32, ptr %9, align 4
  %127 = icmp sgt i32 %126, 0
  %128 = select i1 %127, i32 1488690801, i32 152105393
  store i32 %128, ptr %4, align 4
  %129 = xor i32 %3, -363973027
  %130 = and i32 %3, %129
  %131 = or i32 %3, %129
  %132 = xor i32 %3, %129
  %133 = add i32 %3, %129
  %134 = sub i32 %133, %132
  %135 = mul i32 %130, 2
  %136 = sub i32 %134, %135
  %137 = mul i32 %136, 110
  %138 = icmp slt i32 %137, 0
  br i1 %138, label %457, label %294

139:                                              ; preds = %10
  %140 = load ptr, ptr %7, align 8
  %141 = load ptr, ptr %7, align 8
  %142 = load i32, ptr %9, align 4
  %143 = sext i32 %142 to i64
  %144 = getelementptr inbounds i8, ptr %141, i64 %143
  %145 = load ptr, ptr %7, align 8
  %146 = load i32, ptr %9, align 4
  %147 = sext i32 %146 to i64
  %148 = getelementptr inbounds i8, ptr %145, i64 %147
  %149 = call i64 @strlen(ptr noundef %148) #8
  %150 = xor i64 %149, 1
  %151 = and i64 %149, 1
  %152 = add i64 %151, %151
  %153 = add i64 %150, %152
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %140, ptr align 1 %144, i64 %153, i1 false)
  store i32 152105393, ptr %4, align 4
  %154 = xor i32 %3, 487196023
  %155 = and i32 %3, %154
  %156 = or i32 %3, %154
  %157 = xor i32 %3, %154
  %158 = add i32 %155, %156
  %159 = sub i32 %158, %3
  %160 = sub i32 %159, %154
  %161 = mul i32 %160, 23
  %162 = icmp uge i32 %161, 0
  br i1 %162, label %294, label %464

163:                                              ; preds = %10
  %164 = load ptr, ptr %7, align 8
  %165 = call i64 @strlen(ptr noundef %164) #8
  %166 = trunc i64 %165 to i32
  store i32 %166, ptr %8, align 4
  store i32 157941560, ptr %4, align 4
  %167 = xor i32 %3, -13103899
  %168 = and i32 %3, %167
  %169 = or i32 %3, %167
  %170 = xor i32 %3, %167
  %171 = mul i32 %169, 2
  %172 = sub i32 %171, %170
  %173 = sub i32 %172, %3
  %174 = sub i32 %173, %167
  %175 = mul i32 %174, 79
  %176 = icmp ugt i32 %175, 0
  br i1 %176, label %472, label %294

177:                                              ; preds = %10
  %178 = load i32, ptr %8, align 4
  %179 = icmp sgt i32 %178, 0
  store i1 false, ptr %6, align 1
  %180 = select i1 %179, i32 -1187065740, i32 1766672802
  store i32 %180, ptr %4, align 4
  %181 = xor i32 %3, -1027301235
  %182 = and i32 %3, %181
  %183 = or i32 %3, %181
  %184 = xor i32 %3, %181
  %185 = mul i32 %183, 2
  %186 = sub i32 %185, %184
  %187 = sub i32 %186, %3
  %188 = sub i32 %187, %181
  %189 = mul i32 %188, 126
  %190 = icmp ne i32 %189, 0
  br i1 %190, label %478, label %294

191:                                              ; preds = %10
  %192 = call ptr @__ctype_b_loc() #7
  %193 = load ptr, ptr %192, align 8
  %194 = load ptr, ptr %7, align 8
  %195 = load i32, ptr %8, align 4
  %196 = load i32, ptr %4, align 4
  %197 = xor i32 %196, -1187065739
  %198 = add i32 %195, %197
  %199 = load i32, ptr %4, align 4
  %200 = xor i32 %199, -1187065738
  %201 = mul i32 %195, %200
  %202 = load i32, ptr %4, align 4
  %203 = xor i32 %202, -1187065739
  %204 = mul i32 %203, %198
  %205 = sub i32 %201, %204
  %206 = sext i32 %205 to i64
  %207 = getelementptr inbounds i8, ptr %194, i64 %206
  %208 = load i8, ptr %207, align 1
  %209 = zext i8 %208 to i32
  %210 = sext i32 %209 to i64
  %211 = getelementptr inbounds i16, ptr %193, i64 %210
  %212 = load i16, ptr %211, align 2
  %213 = zext i16 %212 to i32
  %214 = load i32, ptr %4, align 4
  %215 = xor i32 %214, -1187057548
  %216 = add i32 %213, %215
  %217 = load i32, ptr %4, align 4
  %218 = xor i32 %217, -1187057548
  %219 = or i32 %213, %218
  %220 = load i32, ptr %4, align 4
  %221 = xor i32 %220, -481696971
  %222 = mul i32 %216, %221
  %223 = load i32, ptr %4, align 4
  %224 = xor i32 %223, -481696971
  %225 = mul i32 %219, %224
  %226 = sub i32 %222, %225
  %227 = load i32, ptr %4, align 4
  %228 = xor i32 %227, -1144419147
  %229 = mul i32 %226, %228
  %230 = icmp ne i32 %229, 0
  store i1 %230, ptr %6, align 1
  store i32 1766672802, ptr %4, align 4
  %231 = xor i32 %3, 474449689
  %232 = and i32 %3, %231
  %233 = or i32 %3, %231
  %234 = xor i32 %3, %231
  %235 = sub i32 %233, %234
  %236 = sub i32 %235, %232
  %237 = mul i32 %236, 10
  %238 = icmp slt i32 %237, 0
  br i1 %238, label %487, label %294

239:                                              ; preds = %10
  %240 = load i1, ptr %6, align 1
  %241 = select i1 %240, i32 1631043383, i32 1623080351
  store i32 %241, ptr %4, align 4
  %242 = xor i32 %3, -190224369
  %243 = and i32 %3, %242
  %244 = or i32 %3, %242
  %245 = xor i32 %3, %242
  %246 = add i32 %243, %244
  %247 = sub i32 %246, %3
  %248 = sub i32 %247, %242
  %249 = mul i32 %248, 186
  %250 = icmp uge i32 %249, 0
  br i1 %250, label %294, label %495

251:                                              ; preds = %10
  %252 = load ptr, ptr %7, align 8
  %253 = load i32, ptr %8, align 4
  %254 = load i32, ptr %4, align 4
  %255 = xor i32 %254, 1631043382
  %256 = add i32 %253, %255
  %257 = load i32, ptr %4, align 4
  %258 = xor i32 %257, 1631043381
  %259 = mul i32 %253, %258
  %260 = load i32, ptr %4, align 4
  %261 = xor i32 %260, 1631043382
  %262 = mul i32 %261, %256
  %263 = sub i32 %259, %262
  %264 = sext i32 %263 to i64
  %265 = getelementptr inbounds i8, ptr %252, i64 %264
  store i8 0, ptr %265, align 1
  %266 = load i32, ptr %8, align 4
  %267 = load i32, ptr %4, align 4
  %268 = xor i32 %267, -1631043384
  %269 = or i32 %266, %268
  %270 = load i32, ptr %4, align 4
  %271 = xor i32 %270, -1631043384
  %272 = and i32 %266, %271
  %273 = add i32 %269, %272
  store i32 %273, ptr %8, align 4
  store i32 157941560, ptr %4, align 4
  %274 = xor i32 %3, -1455275007
  %275 = and i32 %3, %274
  %276 = or i32 %3, %274
  %277 = xor i32 %3, %274
  %278 = add i32 %3, %274
  %279 = sub i32 %278, %277
  %280 = mul i32 %275, 2
  %281 = sub i32 %279, %280
  %282 = mul i32 %281, 245
  %283 = xor i32 %3, -396903761
  %284 = and i32 %3, %283
  %285 = or i32 %3, %283
  %286 = xor i32 %3, %283
  %287 = mul i32 %285, 2
  %288 = sub i32 %287, %286
  %289 = sub i32 %288, %3
  %290 = sub i32 %289, %283
  %291 = mul i32 %290, 136
  %292 = icmp eq i32 %282, %291
  br i1 %292, label %294, label %504

293:                                              ; preds = %10
  ret void

294:                                              ; preds = %570, %564, %555, %546, %539, %531, %525, %519, %504, %495, %487, %478, %472, %464, %457, %451, %442, %434, %427, %421, %408, %395, %375, %363, %341, %330, %317, %304, %251, %239, %191, %177, %163, %139, %125, %99, %86, %43, %24, %14
  br label %10

295:                                              ; preds = %10
  store i32 1722636471, ptr %4, align 4
  call void asm sideeffect "", ""()
  %296 = xor i32 %3, 1018538267
  %297 = and i32 %3, %296
  %298 = or i32 %3, %296
  %299 = xor i32 %3, %296
  %300 = sub i32 %298, %299
  %301 = sub i32 %300, %297
  %302 = mul i32 %301, 222
  %303 = icmp uge i32 %302, 0
  br i1 %303, label %10, label %510

304:                                              ; preds = %10
  %305 = load i32, ptr %4, align 4
  %306 = xor i32 %305, 2069653639
  store i32 %306, ptr %4, align 4
  %307 = xor i32 %3, 1772799587
  %308 = and i32 %3, %307
  %309 = or i32 %3, %307
  %310 = xor i32 %3, %307
  %311 = add i32 %3, %307
  %312 = sub i32 %311, %310
  %313 = mul i32 %308, 2
  %314 = sub i32 %312, %313
  %315 = mul i32 %314, 40
  %316 = icmp uge i32 %315, 0
  br i1 %316, label %294, label %519

317:                                              ; preds = %10
  %318 = load i32, ptr %4, align 4
  %319 = xor i32 %318, 22295004
  store i32 %319, ptr %4, align 4
  %320 = xor i32 %3, 1477288721
  %321 = and i32 %3, %320
  %322 = or i32 %3, %320
  %323 = xor i32 %3, %320
  %324 = add i32 %3, %320
  %325 = sub i32 %324, %323
  %326 = mul i32 %321, 2
  %327 = sub i32 %325, %326
  %328 = mul i32 %327, 114
  %329 = icmp sle i32 %328, 0
  br i1 %329, label %294, label %525

330:                                              ; preds = %10
  %331 = load i32, ptr %4, align 4
  %332 = xor i32 %331, -1216644731
  store i32 %332, ptr %4, align 4
  %333 = xor i32 %3, 1297950363
  %334 = and i32 %3, %333
  %335 = or i32 %3, %333
  %336 = xor i32 %3, %333
  %337 = sub i32 %335, %336
  %338 = sub i32 %337, %334
  %339 = mul i32 %338, 187
  %340 = icmp ugt i32 %339, 0
  br i1 %340, label %531, label %294

341:                                              ; preds = %10
  %342 = load i32, ptr %4, align 4
  %343 = xor i32 %342, -1993691121
  store i32 %343, ptr %4, align 4
  %344 = xor i32 %3, -127359857
  %345 = and i32 %3, %344
  %346 = or i32 %3, %344
  %347 = xor i32 %3, %344
  %348 = add i32 %3, %344
  %349 = sub i32 %348, %347
  %350 = mul i32 %345, 2
  %351 = sub i32 %349, %350
  %352 = mul i32 %351, 170
  %353 = xor i32 %3, 794403615
  %354 = and i32 %3, %353
  %355 = or i32 %3, %353
  %356 = xor i32 %3, %353
  %357 = mul i32 %355, 2
  %358 = sub i32 %357, %356
  %359 = sub i32 %358, %3
  %360 = sub i32 %359, %353
  %361 = mul i32 %360, 78
  %362 = icmp eq i32 %352, %361
  br i1 %362, label %294, label %539

363:                                              ; preds = %10
  %364 = load i32, ptr %4, align 4
  %365 = xor i32 %364, 1298048883
  store i32 %365, ptr %4, align 4
  %366 = xor i32 %3, -621783735
  %367 = and i32 %3, %366
  %368 = or i32 %3, %366
  %369 = xor i32 %3, %366
  %370 = add i32 %367, %368
  %371 = sub i32 %370, %3
  %372 = sub i32 %371, %366
  %373 = mul i32 %372, 121
  %374 = icmp eq i32 %373, 0
  br i1 %374, label %294, label %546

375:                                              ; preds = %10
  %376 = load i32, ptr %4, align 4
  %377 = xor i32 %376, -1446807384
  store i32 %377, ptr %4, align 4
  %378 = xor i32 %3, 1211479809
  %379 = and i32 %3, %378
  %380 = or i32 %3, %378
  %381 = xor i32 %3, %378
  %382 = sub i32 %380, %381
  %383 = sub i32 %382, %379
  %384 = mul i32 %383, 10
  %385 = xor i32 %3, 2115874791
  %386 = and i32 %3, %385
  %387 = or i32 %3, %385
  %388 = xor i32 %3, %385
  %389 = add i32 %3, %385
  %390 = sub i32 %389, %388
  %391 = mul i32 %386, 2
  %392 = sub i32 %390, %391
  %393 = mul i32 %392, 149
  %394 = icmp eq i32 %384, %393
  br i1 %394, label %294, label %555

395:                                              ; preds = %10
  %396 = load i32, ptr %4, align 4
  %397 = xor i32 %396, 1332164830
  store i32 %397, ptr %4, align 4
  %398 = xor i32 %3, 1750333179
  %399 = and i32 %3, %398
  %400 = or i32 %3, %398
  %401 = xor i32 %3, %398
  %402 = add i32 %3, %398
  %403 = sub i32 %402, %401
  %404 = mul i32 %399, 2
  %405 = sub i32 %403, %404
  %406 = mul i32 %405, 126
  %407 = icmp slt i32 %406, 0
  br i1 %407, label %564, label %294

408:                                              ; preds = %10
  %409 = load i32, ptr %4, align 4
  %410 = xor i32 %409, -1001811251
  store i32 %410, ptr %4, align 4
  %411 = xor i32 %3, 119956451
  %412 = and i32 %3, %411
  %413 = or i32 %3, %411
  %414 = xor i32 %3, %411
  %415 = mul i32 %413, 2
  %416 = sub i32 %415, %414
  %417 = sub i32 %416, %3
  %418 = sub i32 %417, %411
  %419 = mul i32 %418, 100
  %420 = icmp sle i32 %419, 0
  br i1 %420, label %294, label %570

421:                                              ; preds = %14
  %422 = load i64, ptr %2, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = mul i64 %423, %422
  %425 = xor i64 %424, %423
  %426 = add i64 %425, %423
  store i64 %426, ptr %2, align 8
  br label %294

427:                                              ; preds = %24
  %428 = load i64, ptr %2, align 8
  %429 = ptrtoint ptr %0 to i64
  %430 = add i64 %428, %429
  %431 = add i64 %430, %429
  %432 = and i64 %431, %428
  %433 = sub i64 %432, %429
  store i64 %433, ptr %2, align 8
  br label %294

434:                                              ; preds = %43
  %435 = load i64, ptr %2, align 8
  %436 = ptrtoint ptr %0 to i64
  %437 = and i64 %435, %436
  %438 = xor i64 %437, %436
  %439 = sub i64 %438, %436
  %440 = or i64 %439, %436
  %441 = or i64 %440, %435
  store i64 %441, ptr %2, align 8
  br label %294

442:                                              ; preds = %86
  %443 = load i64, ptr %2, align 8
  %444 = ptrtoint ptr %0 to i64
  %445 = xor i64 %444, %444
  %446 = xor i64 %445, %444
  %447 = add i64 %446, %443
  %448 = and i64 %447, %443
  %449 = mul i64 %448, %443
  %450 = add i64 %449, %444
  store i64 %450, ptr %2, align 8
  br label %294

451:                                              ; preds = %99
  %452 = load i64, ptr %2, align 8
  %453 = ptrtoint ptr %0 to i64
  %454 = add i64 %453, %452
  %455 = xor i64 %454, %452
  %456 = and i64 %455, %453
  store i64 %456, ptr %2, align 8
  br label %294

457:                                              ; preds = %125
  %458 = load i64, ptr %2, align 8
  %459 = ptrtoint ptr %0 to i64
  %460 = or i64 %458, %459
  %461 = and i64 %460, %459
  %462 = mul i64 %461, %458
  %463 = mul i64 %462, %458
  store i64 %463, ptr %2, align 8
  br label %294

464:                                              ; preds = %139
  %465 = load i64, ptr %2, align 8
  %466 = ptrtoint ptr %0 to i64
  %467 = sub i64 %465, %465
  %468 = or i64 %467, %465
  %469 = xor i64 %468, %465
  %470 = mul i64 %469, %466
  %471 = xor i64 %470, %465
  store i64 %471, ptr %2, align 8
  br label %294

472:                                              ; preds = %163
  %473 = load i64, ptr %2, align 8
  %474 = ptrtoint ptr %0 to i64
  %475 = add i64 %473, %474
  %476 = sub i64 %475, %474
  %477 = xor i64 %476, %473
  store i64 %477, ptr %2, align 8
  br label %294

478:                                              ; preds = %177
  %479 = load i64, ptr %2, align 8
  %480 = ptrtoint ptr %0 to i64
  %481 = or i64 %479, %479
  %482 = or i64 %481, %479
  %483 = and i64 %482, %480
  %484 = add i64 %483, %479
  %485 = xor i64 %484, %479
  %486 = mul i64 %485, %479
  store i64 %486, ptr %2, align 8
  br label %294

487:                                              ; preds = %191
  %488 = load i64, ptr %2, align 8
  %489 = ptrtoint ptr %0 to i64
  %490 = mul i64 %488, %489
  %491 = or i64 %490, %489
  %492 = or i64 %491, %489
  %493 = or i64 %492, %489
  %494 = and i64 %493, %488
  store i64 %494, ptr %2, align 8
  br label %294

495:                                              ; preds = %239
  %496 = load i64, ptr %2, align 8
  %497 = ptrtoint ptr %0 to i64
  %498 = and i64 %496, %497
  %499 = or i64 %498, %496
  %500 = and i64 %499, %497
  %501 = xor i64 %500, %497
  %502 = or i64 %501, %496
  %503 = add i64 %502, %496
  store i64 %503, ptr %2, align 8
  br label %294

504:                                              ; preds = %251
  %505 = load i64, ptr %2, align 8
  %506 = ptrtoint ptr %0 to i64
  %507 = xor i64 %506, %505
  %508 = add i64 %507, %506
  %509 = xor i64 %508, %506
  store i64 %509, ptr %2, align 8
  br label %294

510:                                              ; preds = %295
  %511 = load i64, ptr %2, align 8
  %512 = ptrtoint ptr %0 to i64
  %513 = mul i64 %511, %512
  %514 = sub i64 %513, %511
  %515 = or i64 %514, %512
  %516 = sub i64 %515, %512
  %517 = add i64 %516, %512
  %518 = or i64 %517, %512
  store i64 %518, ptr %2, align 8
  br label %10

519:                                              ; preds = %304
  %520 = load i64, ptr %2, align 8
  %521 = ptrtoint ptr %0 to i64
  %522 = and i64 %521, %521
  %523 = and i64 %522, %520
  %524 = add i64 %523, %521
  store i64 %524, ptr %2, align 8
  br label %294

525:                                              ; preds = %317
  %526 = load i64, ptr %2, align 8
  %527 = ptrtoint ptr %0 to i64
  %528 = mul i64 %527, %527
  %529 = and i64 %528, %526
  %530 = xor i64 %529, %526
  store i64 %530, ptr %2, align 8
  br label %294

531:                                              ; preds = %330
  %532 = load i64, ptr %2, align 8
  %533 = ptrtoint ptr %0 to i64
  %534 = sub i64 %532, %532
  %535 = and i64 %534, %532
  %536 = sub i64 %535, %532
  %537 = sub i64 %536, %532
  %538 = or i64 %537, %533
  store i64 %538, ptr %2, align 8
  br label %294

539:                                              ; preds = %341
  %540 = load i64, ptr %2, align 8
  %541 = ptrtoint ptr %0 to i64
  %542 = or i64 %540, %540
  %543 = sub i64 %542, %541
  %544 = mul i64 %543, %541
  %545 = or i64 %544, %540
  store i64 %545, ptr %2, align 8
  br label %294

546:                                              ; preds = %363
  %547 = load i64, ptr %2, align 8
  %548 = ptrtoint ptr %0 to i64
  %549 = mul i64 %547, %547
  %550 = or i64 %549, %547
  %551 = mul i64 %550, %547
  %552 = or i64 %551, %547
  %553 = xor i64 %552, %548
  %554 = and i64 %553, %548
  store i64 %554, ptr %2, align 8
  br label %294

555:                                              ; preds = %375
  %556 = load i64, ptr %2, align 8
  %557 = ptrtoint ptr %0 to i64
  %558 = xor i64 %557, %556
  %559 = mul i64 %558, %557
  %560 = and i64 %559, %557
  %561 = xor i64 %560, %556
  %562 = or i64 %561, %557
  %563 = sub i64 %562, %556
  store i64 %563, ptr %2, align 8
  br label %294

564:                                              ; preds = %395
  %565 = load i64, ptr %2, align 8
  %566 = ptrtoint ptr %0 to i64
  %567 = or i64 %566, %565
  %568 = xor i64 %567, %565
  %569 = and i64 %568, %565
  store i64 %569, ptr %2, align 8
  br label %294

570:                                              ; preds = %408
  %571 = load i64, ptr %2, align 8
  %572 = ptrtoint ptr %0 to i64
  %573 = add i64 %571, %571
  %574 = or i64 %573, %572
  %575 = or i64 %574, %571
  %576 = and i64 %575, %571
  %577 = and i64 %576, %571
  store i64 %577, ptr %2, align 8
  br label %294
}

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #1

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr writeonly captures(none), ptr readonly captures(none), i64, i1 immarg) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @upperString(ptr noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  store i32 794618594, ptr %4, align 4
  br label %7

7:                                                ; preds = %165, %73, %72, %1
  %8 = load i32, ptr %4, align 4
  %9 = sub i32 %8, 335244546
  %10 = mul i32 %9, -608629367
  switch i32 %10, label %73 [
    i32 829471968, label %11
    i32 964651727, label %22
    i32 1791998579, label %40
    i32 384447093, label %71
    i32 679577690, label %82
    i32 1669554867, label %94
    i32 1798434106, label %107
    i32 1778597130, label %120
  ]

11:                                               ; preds = %7
  store ptr %0, ptr %5, align 8
  store i32 0, ptr %6, align 4
  store i32 -1712610151, ptr %4, align 4
  %12 = xor i32 %3, 170799367
  %13 = and i32 %3, %12
  %14 = or i32 %3, %12
  %15 = xor i32 %3, %12
  %16 = add i32 %3, %12
  %17 = sub i32 %16, %15
  %18 = mul i32 %13, 2
  %19 = sub i32 %17, %18
  %20 = mul i32 %19, 33
  %21 = icmp sle i32 %20, 0
  br i1 %21, label %72, label %141

22:                                               ; preds = %7
  %23 = load ptr, ptr %5, align 8
  %24 = load i32, ptr %6, align 4
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds i8, ptr %23, i64 %25
  %27 = load i8, ptr %26, align 1
  %28 = icmp ne i8 %27, 0
  %29 = select i1 %28, i32 629019165, i32 996785039
  store i32 %29, ptr %4, align 4
  %30 = xor i32 %3, -534434341
  %31 = and i32 %3, %30
  %32 = or i32 %3, %30
  %33 = xor i32 %3, %30
  %34 = add i32 %3, %30
  %35 = sub i32 %34, %33
  %36 = mul i32 %31, 2
  %37 = sub i32 %35, %36
  %38 = mul i32 %37, 184
  %39 = icmp ne i32 %38, 0
  br i1 %39, label %149, label %72

40:                                               ; preds = %7
  %41 = load ptr, ptr %5, align 8
  %42 = load i32, ptr %6, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds i8, ptr %41, i64 %43
  %45 = load i8, ptr %44, align 1
  %46 = zext i8 %45 to i32
  %47 = call i32 @toupper(i32 noundef %46) #8
  %48 = trunc i32 %47 to i8
  %49 = load ptr, ptr %5, align 8
  %50 = load i32, ptr %6, align 4
  %51 = sext i32 %50 to i64
  %52 = getelementptr inbounds i8, ptr %49, i64 %51
  store i8 %48, ptr %52, align 1
  %53 = load i32, ptr %6, align 4
  %54 = load i32, ptr %4, align 4
  %55 = xor i32 %54, 629019164
  %56 = or i32 %53, %55
  %57 = load i32, ptr %4, align 4
  %58 = xor i32 %57, 629019164
  %59 = and i32 %53, %58
  %60 = add i32 %56, %59
  store i32 %60, ptr %6, align 4
  store i32 -1712610151, ptr %4, align 4
  %61 = xor i32 %3, 64826991
  %62 = and i32 %3, %61
  %63 = or i32 %3, %61
  %64 = xor i32 %3, %61
  %65 = mul i32 %63, 2
  %66 = sub i32 %65, %64
  %67 = sub i32 %66, %3
  %68 = sub i32 %67, %61
  %69 = mul i32 %68, 24
  %70 = icmp ne i32 %69, 0
  br i1 %70, label %157, label %72

71:                                               ; preds = %7
  ret void

72:                                               ; preds = %192, %186, %177, %171, %157, %149, %141, %120, %107, %94, %82, %40, %22, %11
  br label %7

73:                                               ; preds = %7
  store i32 794618594, ptr %4, align 4
  call void asm sideeffect "", ""()
  %74 = xor i32 %3, 1808015479
  %75 = and i32 %3, %74
  %76 = or i32 %3, %74
  %77 = xor i32 %3, %74
  %78 = sub i32 %76, %77
  %79 = sub i32 %78, %75
  %80 = mul i32 %79, 33
  %81 = icmp slt i32 %80, 1
  br i1 %81, label %7, label %165

82:                                               ; preds = %7
  %83 = load i32, ptr %4, align 4
  %84 = xor i32 %83, -771829224
  store i32 %84, ptr %4, align 4
  %85 = xor i32 %3, 278663985
  %86 = and i32 %3, %85
  %87 = or i32 %3, %85
  %88 = xor i32 %3, %85
  %89 = add i32 %86, %87
  %90 = sub i32 %89, %3
  %91 = sub i32 %90, %85
  %92 = mul i32 %91, 126
  %93 = icmp eq i32 %92, 0
  br i1 %93, label %72, label %171

94:                                               ; preds = %7
  %95 = load i32, ptr %4, align 4
  %96 = xor i32 %95, 1922382826
  store i32 %96, ptr %4, align 4
  %97 = xor i32 %3, -442924341
  %98 = and i32 %3, %97
  %99 = or i32 %3, %97
  %100 = xor i32 %3, %97
  %101 = mul i32 %99, 2
  %102 = sub i32 %101, %100
  %103 = sub i32 %102, %3
  %104 = sub i32 %103, %97
  %105 = mul i32 %104, 9
  %106 = icmp ne i32 %105, 0
  br i1 %106, label %177, label %72

107:                                              ; preds = %7
  %108 = load i32, ptr %4, align 4
  %109 = xor i32 %108, -266912977
  store i32 %109, ptr %4, align 4
  %110 = xor i32 %3, 580798329
  %111 = and i32 %3, %110
  %112 = or i32 %3, %110
  %113 = xor i32 %3, %110
  %114 = mul i32 %112, 2
  %115 = sub i32 %114, %113
  %116 = sub i32 %115, %3
  %117 = sub i32 %116, %110
  %118 = mul i32 %117, 4
  %119 = icmp slt i32 %118, 1
  br i1 %119, label %72, label %186

120:                                              ; preds = %7
  %121 = load i32, ptr %4, align 4
  %122 = xor i32 %121, 721126268
  store i32 %122, ptr %4, align 4
  %123 = xor i32 %3, 241152555
  %124 = and i32 %3, %123
  %125 = or i32 %3, %123
  %126 = xor i32 %3, %123
  %127 = add i32 %124, %125
  %128 = sub i32 %127, %3
  %129 = sub i32 %128, %123
  %130 = mul i32 %129, 128
  %131 = xor i32 %3, 1530216953
  %132 = and i32 %3, %131
  %133 = or i32 %3, %131
  %134 = xor i32 %3, %131
  %135 = mul i32 %133, 2
  %136 = sub i32 %135, %134
  %137 = sub i32 %136, %3
  %138 = sub i32 %137, %131
  %139 = mul i32 %138, 141
  %140 = icmp eq i32 %130, %139
  br i1 %140, label %72, label %192

141:                                              ; preds = %11
  %142 = load i64, ptr %2, align 8
  %143 = ptrtoint ptr %0 to i64
  %144 = or i64 %142, %142
  %145 = mul i64 %144, %142
  %146 = or i64 %145, %142
  %147 = add i64 %146, %143
  %148 = mul i64 %147, %142
  store i64 %148, ptr %2, align 8
  br label %72

149:                                              ; preds = %22
  %150 = load i64, ptr %2, align 8
  %151 = ptrtoint ptr %0 to i64
  %152 = xor i64 %150, %151
  %153 = or i64 %152, %150
  %154 = sub i64 %153, %151
  %155 = mul i64 %154, %150
  %156 = or i64 %155, %151
  store i64 %156, ptr %2, align 8
  br label %72

157:                                              ; preds = %40
  %158 = load i64, ptr %2, align 8
  %159 = ptrtoint ptr %0 to i64
  %160 = or i64 %159, %158
  %161 = xor i64 %160, %158
  %162 = add i64 %161, %159
  %163 = and i64 %162, %158
  %164 = and i64 %163, %159
  store i64 %164, ptr %2, align 8
  br label %72

165:                                              ; preds = %73
  %166 = load i64, ptr %2, align 8
  %167 = ptrtoint ptr %0 to i64
  %168 = add i64 %167, %166
  %169 = or i64 %168, %167
  %170 = mul i64 %169, %167
  store i64 %170, ptr %2, align 8
  br label %7

171:                                              ; preds = %82
  %172 = load i64, ptr %2, align 8
  %173 = ptrtoint ptr %0 to i64
  %174 = and i64 %172, %173
  %175 = or i64 %174, %173
  %176 = xor i64 %175, %172
  store i64 %176, ptr %2, align 8
  br label %72

177:                                              ; preds = %94
  %178 = load i64, ptr %2, align 8
  %179 = ptrtoint ptr %0 to i64
  %180 = mul i64 %179, %178
  %181 = mul i64 %180, %179
  %182 = or i64 %181, %178
  %183 = mul i64 %182, %178
  %184 = xor i64 %183, %178
  %185 = sub i64 %184, %178
  store i64 %185, ptr %2, align 8
  br label %72

186:                                              ; preds = %107
  %187 = load i64, ptr %2, align 8
  %188 = ptrtoint ptr %0 to i64
  %189 = or i64 %187, %187
  %190 = and i64 %189, %188
  %191 = and i64 %190, %188
  store i64 %191, ptr %2, align 8
  br label %72

192:                                              ; preds = %120
  %193 = load i64, ptr %2, align 8
  %194 = ptrtoint ptr %0 to i64
  %195 = xor i64 %193, %193
  %196 = sub i64 %195, %194
  %197 = add i64 %196, %194
  %198 = sub i64 %197, %194
  store i64 %198, ptr %2, align 8
  br label %72
}

; Function Attrs: nounwind willreturn memory(read)
declare i32 @toupper(i32 noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @equalsIgnoreCase(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i1, align 1
  %7 = alloca i1, align 1
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  store i32 -109130352, ptr %5, align 4
  br label %11

11:                                               ; preds = %417, %160, %159, %2
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 265066927
  %14 = mul i32 %13, -1025234057
  %15 = icmp slt i32 %14, 1141822257
  br i1 %15, label %277, label %279

16:                                               ; preds = %313
  store ptr %0, ptr %9, align 8
  store ptr %1, ptr %10, align 8
  store i32 411988017, ptr %5, align 4
  %17 = xor i32 %4, 1920999285
  %18 = and i32 %4, %17
  %19 = or i32 %4, %17
  %20 = xor i32 %4, %17
  %21 = add i32 %4, %17
  %22 = sub i32 %21, %20
  %23 = mul i32 %18, 2
  %24 = sub i32 %22, %23
  %25 = mul i32 %24, 47
  %26 = icmp ne i32 %25, 0
  br i1 %26, label %333, label %159

27:                                               ; preds = %301
  %28 = load ptr, ptr %9, align 8
  %29 = load i8, ptr %28, align 1
  %30 = sext i8 %29 to i32
  %31 = icmp ne i32 %30, 0
  store i1 false, ptr %6, align 1
  %32 = select i1 %31, i32 -1204092782, i32 1316704880
  store i32 %32, ptr %5, align 4
  %33 = xor i32 %4, 373185841
  %34 = and i32 %4, %33
  %35 = or i32 %4, %33
  %36 = xor i32 %4, %33
  %37 = add i32 %4, %33
  %38 = sub i32 %37, %36
  %39 = mul i32 %34, 2
  %40 = sub i32 %38, %39
  %41 = mul i32 %40, 83
  %42 = icmp eq i32 %41, 0
  br i1 %42, label %159, label %341

43:                                               ; preds = %331
  %44 = load ptr, ptr %10, align 8
  %45 = load i8, ptr %44, align 1
  %46 = sext i8 %45 to i32
  %47 = icmp ne i32 %46, 0
  store i1 %47, ptr %6, align 1
  store i32 1316704880, ptr %5, align 4
  %48 = xor i32 %4, -1680633363
  %49 = and i32 %4, %48
  %50 = or i32 %4, %48
  %51 = xor i32 %4, %48
  %52 = mul i32 %50, 2
  %53 = sub i32 %52, %51
  %54 = sub i32 %53, %4
  %55 = sub i32 %54, %48
  %56 = mul i32 %55, 136
  %57 = icmp slt i32 %56, 0
  br i1 %57, label %350, label %159

58:                                               ; preds = %317
  %59 = load i1, ptr %6, align 1
  %60 = select i1 %59, i32 1481334570, i32 123805465
  store i32 %60, ptr %5, align 4
  %61 = xor i32 %4, 889393841
  %62 = and i32 %4, %61
  %63 = or i32 %4, %61
  %64 = xor i32 %4, %61
  %65 = mul i32 %63, 2
  %66 = sub i32 %65, %64
  %67 = sub i32 %66, %4
  %68 = sub i32 %67, %61
  %69 = mul i32 %68, 212
  %70 = icmp eq i32 %69, 0
  br i1 %70, label %159, label %358

71:                                               ; preds = %293
  %72 = load ptr, ptr %9, align 8
  %73 = load i8, ptr %72, align 1
  %74 = zext i8 %73 to i32
  %75 = call i32 @toupper(i32 noundef %74) #8
  %76 = load ptr, ptr %10, align 8
  %77 = load i8, ptr %76, align 1
  %78 = zext i8 %77 to i32
  %79 = call i32 @toupper(i32 noundef %78) #8
  %80 = icmp ne i32 %75, %79
  %81 = select i1 %80, i32 -1322552786, i32 1309207110
  store i32 %81, ptr %5, align 4
  %82 = xor i32 %4, 1973985027
  %83 = and i32 %4, %82
  %84 = or i32 %4, %82
  %85 = xor i32 %4, %82
  %86 = add i32 %83, %84
  %87 = sub i32 %86, %4
  %88 = sub i32 %87, %82
  %89 = mul i32 %88, 238
  %90 = icmp uge i32 %89, 0
  br i1 %90, label %159, label %368

91:                                               ; preds = %285
  store i32 0, ptr %8, align 4
  store i32 1950032870, ptr %5, align 4
  %92 = xor i32 %4, -925212075
  %93 = and i32 %4, %92
  %94 = or i32 %4, %92
  %95 = xor i32 %4, %92
  %96 = add i32 %4, %92
  %97 = sub i32 %96, %95
  %98 = mul i32 %93, 2
  %99 = sub i32 %97, %98
  %100 = mul i32 %99, 119
  %101 = icmp sle i32 %100, 0
  br i1 %101, label %159, label %375

102:                                              ; preds = %309
  %103 = load ptr, ptr %9, align 8
  %104 = getelementptr inbounds nuw i8, ptr %103, i32 1
  store ptr %104, ptr %9, align 8
  %105 = load ptr, ptr %10, align 8
  %106 = getelementptr inbounds nuw i8, ptr %105, i32 1
  store ptr %106, ptr %10, align 8
  store i32 411988017, ptr %5, align 4
  %107 = xor i32 %4, 1528487527
  %108 = and i32 %4, %107
  %109 = or i32 %4, %107
  %110 = xor i32 %4, %107
  %111 = sub i32 %109, %110
  %112 = sub i32 %111, %108
  %113 = mul i32 %112, 69
  %114 = icmp uge i32 %113, 0
  br i1 %114, label %159, label %384

115:                                              ; preds = %299
  %116 = load ptr, ptr %9, align 8
  %117 = load i8, ptr %116, align 1
  %118 = sext i8 %117 to i32
  %119 = icmp eq i32 %118, 0
  store i1 false, ptr %7, align 1
  %120 = select i1 %119, i32 -1391006561, i32 -502425724
  store i32 %120, ptr %5, align 4
  %121 = xor i32 %4, -2137201085
  %122 = and i32 %4, %121
  %123 = or i32 %4, %121
  %124 = xor i32 %4, %121
  %125 = add i32 %122, %123
  %126 = sub i32 %125, %4
  %127 = sub i32 %126, %121
  %128 = mul i32 %127, 137
  %129 = icmp eq i32 %128, 0
  br i1 %129, label %159, label %392

130:                                              ; preds = %319
  %131 = load ptr, ptr %10, align 8
  %132 = load i8, ptr %131, align 1
  %133 = sext i8 %132 to i32
  %134 = icmp eq i32 %133, 0
  store i1 %134, ptr %7, align 1
  store i32 -502425724, ptr %5, align 4
  %135 = xor i32 %4, -859005753
  %136 = and i32 %4, %135
  %137 = or i32 %4, %135
  %138 = xor i32 %4, %135
  %139 = add i32 %136, %137
  %140 = sub i32 %139, %4
  %141 = sub i32 %140, %135
  %142 = mul i32 %141, 107
  %143 = icmp slt i32 %142, 1
  br i1 %143, label %159, label %399

144:                                              ; preds = %297
  %145 = load i1, ptr %7, align 1
  %146 = zext i1 %145 to i32
  store i32 %146, ptr %8, align 4
  store i32 1950032870, ptr %5, align 4
  %147 = xor i32 %4, 544756281
  %148 = and i32 %4, %147
  %149 = or i32 %4, %147
  %150 = xor i32 %4, %147
  %151 = add i32 %4, %147
  %152 = sub i32 %151, %150
  %153 = mul i32 %148, 2
  %154 = sub i32 %152, %153
  %155 = mul i32 %154, 151
  %156 = icmp ne i32 %155, 0
  br i1 %156, label %409, label %159

157:                                              ; preds = %289
  %158 = load i32, ptr %8, align 4
  ret i32 %158

159:                                              ; preds = %484, %477, %470, %463, %454, %444, %436, %427, %409, %399, %392, %384, %375, %368, %358, %350, %341, %333, %264, %251, %238, %226, %213, %195, %182, %171, %144, %130, %115, %102, %91, %71, %58, %43, %27, %16
  br label %11

160:                                              ; preds = %331, %327, %325, %319, %315, %313, %303, %299, %297, %291, %289
  store i32 -109130352, ptr %5, align 4
  call void asm sideeffect "", ""()
  %161 = xor i32 %4, -511670313
  %162 = and i32 %4, %161
  %163 = or i32 %4, %161
  %164 = xor i32 %4, %161
  %165 = add i32 %4, %161
  %166 = sub i32 %165, %164
  %167 = mul i32 %162, 2
  %168 = sub i32 %166, %167
  %169 = mul i32 %168, 35
  %170 = icmp slt i32 %169, 1
  br i1 %170, label %11, label %417

171:                                              ; preds = %321
  %172 = load i32, ptr %5, align 4
  %173 = xor i32 %172, -761402403
  store i32 %173, ptr %5, align 4
  %174 = xor i32 %4, -653156919
  %175 = and i32 %4, %174
  %176 = or i32 %4, %174
  %177 = xor i32 %4, %174
  %178 = sub i32 %176, %177
  %179 = sub i32 %178, %175
  %180 = mul i32 %179, 231
  %181 = icmp uge i32 %180, 0
  br i1 %181, label %159, label %427

182:                                              ; preds = %287
  %183 = load i32, ptr %5, align 4
  %184 = xor i32 %183, 1634360759
  store i32 %184, ptr %5, align 4
  %185 = xor i32 %4, 714361455
  %186 = and i32 %4, %185
  %187 = or i32 %4, %185
  %188 = xor i32 %4, %185
  %189 = mul i32 %187, 2
  %190 = sub i32 %189, %188
  %191 = sub i32 %190, %4
  %192 = sub i32 %191, %185
  %193 = mul i32 %192, 149
  %194 = icmp eq i32 %193, 0
  br i1 %194, label %159, label %436

195:                                              ; preds = %303
  %196 = load i32, ptr %5, align 4
  %197 = xor i32 %196, 1427234418
  store i32 %197, ptr %5, align 4
  %198 = xor i32 %4, -1401939281
  %199 = and i32 %4, %198
  %200 = or i32 %4, %198
  %201 = xor i32 %4, %198
  %202 = sub i32 %200, %201
  %203 = sub i32 %202, %199
  %204 = mul i32 %203, 33
  %205 = xor i32 %4, 1040881589
  %206 = and i32 %4, %205
  %207 = or i32 %4, %205
  %208 = xor i32 %4, %205
  %209 = sub i32 %207, %208
  %210 = sub i32 %209, %206
  %211 = mul i32 %210, 42
  %212 = icmp ne i32 %204, %211
  br i1 %212, label %444, label %159

213:                                              ; preds = %329
  %214 = load i32, ptr %5, align 4
  %215 = xor i32 %214, -73378454
  store i32 %215, ptr %5, align 4
  %216 = xor i32 %4, 998222555
  %217 = and i32 %4, %216
  %218 = or i32 %4, %216
  %219 = xor i32 %4, %216
  %220 = add i32 %4, %216
  %221 = sub i32 %220, %219
  %222 = mul i32 %217, 2
  %223 = sub i32 %221, %222
  %224 = mul i32 %223, 148
  %225 = icmp eq i32 %224, 0
  br i1 %225, label %159, label %454

226:                                              ; preds = %327
  %227 = load i32, ptr %5, align 4
  %228 = xor i32 %227, -912919790
  store i32 %228, ptr %5, align 4
  %229 = xor i32 %4, 1520671823
  %230 = and i32 %4, %229
  %231 = or i32 %4, %229
  %232 = xor i32 %4, %229
  %233 = add i32 %230, %231
  %234 = sub i32 %233, %4
  %235 = sub i32 %234, %229
  %236 = mul i32 %235, 135
  %237 = icmp uge i32 %236, 0
  br i1 %237, label %159, label %463

238:                                              ; preds = %291
  %239 = load i32, ptr %5, align 4
  %240 = xor i32 %239, 1975221844
  store i32 %240, ptr %5, align 4
  %241 = xor i32 %4, 934217799
  %242 = and i32 %4, %241
  %243 = or i32 %4, %241
  %244 = xor i32 %4, %241
  %245 = mul i32 %243, 2
  %246 = sub i32 %245, %244
  %247 = sub i32 %246, %4
  %248 = sub i32 %247, %241
  %249 = mul i32 %248, 121
  %250 = icmp slt i32 %249, 0
  br i1 %250, label %470, label %159

251:                                              ; preds = %325
  %252 = load i32, ptr %5, align 4
  %253 = xor i32 %252, 725052146
  store i32 %253, ptr %5, align 4
  %254 = xor i32 %4, -1448432953
  %255 = and i32 %4, %254
  %256 = or i32 %4, %254
  %257 = xor i32 %4, %254
  %258 = add i32 %4, %254
  %259 = sub i32 %258, %257
  %260 = mul i32 %255, 2
  %261 = sub i32 %259, %260
  %262 = mul i32 %261, 105
  %263 = icmp uge i32 %262, 0
  br i1 %263, label %159, label %477

264:                                              ; preds = %315
  %265 = load i32, ptr %5, align 4
  %266 = xor i32 %265, 1985637637
  store i32 %266, ptr %5, align 4
  %267 = xor i32 %4, 1662082433
  %268 = and i32 %4, %267
  %269 = or i32 %4, %267
  %270 = xor i32 %4, %267
  %271 = add i32 %4, %267
  %272 = sub i32 %271, %270
  %273 = mul i32 %268, 2
  %274 = sub i32 %272, %273
  %275 = mul i32 %274, 104
  %276 = icmp slt i32 %275, 0
  br i1 %276, label %484, label %159

277:                                              ; preds = %11
  %278 = icmp slt i32 %14, 363164973
  br i1 %278, label %281, label %283

279:                                              ; preds = %11
  %280 = icmp slt i32 %14, 1903443432
  br i1 %280, label %305, label %307

281:                                              ; preds = %277
  %282 = icmp slt i32 %14, 234435494
  br i1 %282, label %285, label %287

283:                                              ; preds = %277
  %284 = icmp slt i32 %14, 786092614
  br i1 %284, label %293, label %295

285:                                              ; preds = %281
  %286 = icmp eq i32 %14, 9435145
  br i1 %286, label %91, label %289

287:                                              ; preds = %281
  %288 = icmp eq i32 %14, 234435494
  br i1 %288, label %182, label %291

289:                                              ; preds = %285
  %290 = icmp eq i32 %14, 127237265
  br i1 %290, label %157, label %160

291:                                              ; preds = %287
  %292 = icmp eq i32 %14, 274548295
  br i1 %292, label %238, label %160

293:                                              ; preds = %283
  %294 = icmp eq i32 %14, 363164973
  br i1 %294, label %71, label %297

295:                                              ; preds = %283
  %296 = icmp slt i32 %14, 820677742
  br i1 %296, label %299, label %301

297:                                              ; preds = %293
  %298 = icmp eq i32 %14, 579650819
  br i1 %298, label %144, label %160

299:                                              ; preds = %295
  %300 = icmp eq i32 %14, 786092614
  br i1 %300, label %115, label %160

301:                                              ; preds = %295
  %302 = icmp eq i32 %14, 820677742
  br i1 %302, label %27, label %303

303:                                              ; preds = %301
  %304 = icmp eq i32 %14, 1118173620
  br i1 %304, label %195, label %160

305:                                              ; preds = %279
  %306 = icmp slt i32 %14, 1226793122
  br i1 %306, label %309, label %311

307:                                              ; preds = %279
  %308 = icmp slt i32 %14, 2072910961
  br i1 %308, label %321, label %323

309:                                              ; preds = %305
  %310 = icmp eq i32 %14, 1141822257
  br i1 %310, label %102, label %313

311:                                              ; preds = %305
  %312 = icmp slt i32 %14, 1243892919
  br i1 %312, label %315, label %317

313:                                              ; preds = %309
  %314 = icmp eq i32 %14, 1190193303
  br i1 %314, label %16, label %160

315:                                              ; preds = %311
  %316 = icmp eq i32 %14, 1226793122
  br i1 %316, label %264, label %160

317:                                              ; preds = %311
  %318 = icmp eq i32 %14, 1243892919
  br i1 %318, label %58, label %319

319:                                              ; preds = %317
  %320 = icmp eq i32 %14, 1463475600
  br i1 %320, label %130, label %160

321:                                              ; preds = %307
  %322 = icmp eq i32 %14, 1903443432
  br i1 %322, label %171, label %325

323:                                              ; preds = %307
  %324 = icmp slt i32 %14, 2124165753
  br i1 %324, label %327, label %329

325:                                              ; preds = %321
  %326 = icmp eq i32 %14, 1929371650
  br i1 %326, label %251, label %160

327:                                              ; preds = %323
  %328 = icmp eq i32 %14, 2072910961
  br i1 %328, label %226, label %160

329:                                              ; preds = %323
  %330 = icmp eq i32 %14, 2124165753
  br i1 %330, label %213, label %331

331:                                              ; preds = %329
  %332 = icmp eq i32 %14, 2126902405
  br i1 %332, label %43, label %160

333:                                              ; preds = %16
  %334 = load i64, ptr %3, align 8
  %335 = ptrtoint ptr %0 to i64
  %336 = ptrtoint ptr %1 to i64
  %337 = xor i64 %335, %336
  %338 = mul i64 %337, %334
  %339 = or i64 %338, %334
  %340 = add i64 %339, %335
  store i64 %340, ptr %3, align 8
  br label %159

341:                                              ; preds = %27
  %342 = load i64, ptr %3, align 8
  %343 = ptrtoint ptr %0 to i64
  %344 = ptrtoint ptr %1 to i64
  %345 = and i64 %342, %343
  %346 = and i64 %345, %342
  %347 = xor i64 %346, %343
  %348 = or i64 %347, %344
  %349 = and i64 %348, %342
  store i64 %349, ptr %3, align 8
  br label %159

350:                                              ; preds = %43
  %351 = load i64, ptr %3, align 8
  %352 = ptrtoint ptr %0 to i64
  %353 = ptrtoint ptr %1 to i64
  %354 = or i64 %353, %353
  %355 = mul i64 %354, %353
  %356 = or i64 %355, %351
  %357 = mul i64 %356, %351
  store i64 %357, ptr %3, align 8
  br label %159

358:                                              ; preds = %58
  %359 = load i64, ptr %3, align 8
  %360 = ptrtoint ptr %0 to i64
  %361 = ptrtoint ptr %1 to i64
  %362 = or i64 %359, %361
  %363 = or i64 %362, %359
  %364 = and i64 %363, %359
  %365 = or i64 %364, %361
  %366 = or i64 %365, %361
  %367 = add i64 %366, %359
  store i64 %367, ptr %3, align 8
  br label %159

368:                                              ; preds = %71
  %369 = load i64, ptr %3, align 8
  %370 = ptrtoint ptr %0 to i64
  %371 = ptrtoint ptr %1 to i64
  %372 = sub i64 %369, %369
  %373 = or i64 %372, %371
  %374 = mul i64 %373, %369
  store i64 %374, ptr %3, align 8
  br label %159

375:                                              ; preds = %91
  %376 = load i64, ptr %3, align 8
  %377 = ptrtoint ptr %0 to i64
  %378 = ptrtoint ptr %1 to i64
  %379 = xor i64 %378, %376
  %380 = sub i64 %379, %376
  %381 = xor i64 %380, %376
  %382 = xor i64 %381, %376
  %383 = sub i64 %382, %376
  store i64 %383, ptr %3, align 8
  br label %159

384:                                              ; preds = %102
  %385 = load i64, ptr %3, align 8
  %386 = ptrtoint ptr %0 to i64
  %387 = ptrtoint ptr %1 to i64
  %388 = and i64 %386, %387
  %389 = xor i64 %388, %387
  %390 = add i64 %389, %385
  %391 = sub i64 %390, %387
  store i64 %391, ptr %3, align 8
  br label %159

392:                                              ; preds = %115
  %393 = load i64, ptr %3, align 8
  %394 = ptrtoint ptr %0 to i64
  %395 = ptrtoint ptr %1 to i64
  %396 = sub i64 %395, %393
  %397 = and i64 %396, %393
  %398 = sub i64 %397, %393
  store i64 %398, ptr %3, align 8
  br label %159

399:                                              ; preds = %130
  %400 = load i64, ptr %3, align 8
  %401 = ptrtoint ptr %0 to i64
  %402 = ptrtoint ptr %1 to i64
  %403 = sub i64 %402, %401
  %404 = and i64 %403, %400
  %405 = sub i64 %404, %401
  %406 = xor i64 %405, %402
  %407 = sub i64 %406, %401
  %408 = or i64 %407, %402
  store i64 %408, ptr %3, align 8
  br label %159

409:                                              ; preds = %144
  %410 = load i64, ptr %3, align 8
  %411 = ptrtoint ptr %0 to i64
  %412 = ptrtoint ptr %1 to i64
  %413 = mul i64 %410, %412
  %414 = mul i64 %413, %411
  %415 = add i64 %414, %411
  %416 = add i64 %415, %410
  store i64 %416, ptr %3, align 8
  br label %159

417:                                              ; preds = %160
  %418 = load i64, ptr %3, align 8
  %419 = ptrtoint ptr %0 to i64
  %420 = ptrtoint ptr %1 to i64
  %421 = and i64 %420, %420
  %422 = or i64 %421, %418
  %423 = sub i64 %422, %420
  %424 = and i64 %423, %420
  %425 = or i64 %424, %418
  %426 = sub i64 %425, %420
  store i64 %426, ptr %3, align 8
  br label %11

427:                                              ; preds = %171
  %428 = load i64, ptr %3, align 8
  %429 = ptrtoint ptr %0 to i64
  %430 = ptrtoint ptr %1 to i64
  %431 = sub i64 %430, %429
  %432 = add i64 %431, %429
  %433 = sub i64 %432, %430
  %434 = or i64 %433, %430
  %435 = add i64 %434, %429
  store i64 %435, ptr %3, align 8
  br label %159

436:                                              ; preds = %182
  %437 = load i64, ptr %3, align 8
  %438 = ptrtoint ptr %0 to i64
  %439 = ptrtoint ptr %1 to i64
  %440 = and i64 %437, %439
  %441 = or i64 %440, %438
  %442 = sub i64 %441, %437
  %443 = sub i64 %442, %439
  store i64 %443, ptr %3, align 8
  br label %159

444:                                              ; preds = %195
  %445 = load i64, ptr %3, align 8
  %446 = ptrtoint ptr %0 to i64
  %447 = ptrtoint ptr %1 to i64
  %448 = mul i64 %447, %447
  %449 = add i64 %448, %447
  %450 = add i64 %449, %447
  %451 = add i64 %450, %447
  %452 = or i64 %451, %446
  %453 = or i64 %452, %445
  store i64 %453, ptr %3, align 8
  br label %159

454:                                              ; preds = %213
  %455 = load i64, ptr %3, align 8
  %456 = ptrtoint ptr %0 to i64
  %457 = ptrtoint ptr %1 to i64
  %458 = or i64 %455, %457
  %459 = sub i64 %458, %457
  %460 = and i64 %459, %456
  %461 = or i64 %460, %455
  %462 = xor i64 %461, %457
  store i64 %462, ptr %3, align 8
  br label %159

463:                                              ; preds = %226
  %464 = load i64, ptr %3, align 8
  %465 = ptrtoint ptr %0 to i64
  %466 = ptrtoint ptr %1 to i64
  %467 = xor i64 %464, %465
  %468 = and i64 %467, %465
  %469 = and i64 %468, %464
  store i64 %469, ptr %3, align 8
  br label %159

470:                                              ; preds = %238
  %471 = load i64, ptr %3, align 8
  %472 = ptrtoint ptr %0 to i64
  %473 = ptrtoint ptr %1 to i64
  %474 = mul i64 %473, %472
  %475 = sub i64 %474, %471
  %476 = mul i64 %475, %471
  store i64 %476, ptr %3, align 8
  br label %159

477:                                              ; preds = %251
  %478 = load i64, ptr %3, align 8
  %479 = ptrtoint ptr %0 to i64
  %480 = ptrtoint ptr %1 to i64
  %481 = xor i64 %480, %479
  %482 = and i64 %481, %480
  %483 = sub i64 %482, %479
  store i64 %483, ptr %3, align 8
  br label %159

484:                                              ; preds = %264
  %485 = load i64, ptr %3, align 8
  %486 = ptrtoint ptr %0 to i64
  %487 = ptrtoint ptr %1 to i64
  %488 = and i64 %485, %487
  %489 = xor i64 %488, %486
  %490 = sub i64 %489, %487
  %491 = and i64 %490, %485
  %492 = add i64 %491, %487
  store i64 %492, ptr %3, align 8
  br label %159
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @containsIgnoreCase(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store i32 1300951377, ptr %5, align 4
  br label %14

14:                                               ; preds = %608, %271, %270, %2
  %15 = load i32, ptr %5, align 4
  %16 = sub i32 %15, 1241260173
  %17 = mul i32 %16, -1380219849
  %18 = icmp slt i32 %17, 1419900384
  br i1 %18, label %403, label %405

19:                                               ; preds = %455
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  %20 = load ptr, ptr %7, align 8
  %21 = call i64 @strlen(ptr noundef %20) #8
  %22 = trunc i64 %21 to i32
  store i32 %22, ptr %9, align 4
  %23 = load ptr, ptr %8, align 8
  %24 = call i64 @strlen(ptr noundef %23) #8
  %25 = trunc i64 %24 to i32
  store i32 %25, ptr %10, align 4
  %26 = load i32, ptr %10, align 4
  %27 = icmp eq i32 %26, 0
  %28 = select i1 %27, i32 -1403436457, i32 966814479
  store i32 %28, ptr %5, align 4
  %29 = xor i32 %4, -1847958077
  %30 = and i32 %4, %29
  %31 = or i32 %4, %29
  %32 = xor i32 %4, %29
  %33 = add i32 %4, %29
  %34 = sub i32 %33, %32
  %35 = mul i32 %30, 2
  %36 = sub i32 %34, %35
  %37 = mul i32 %36, 4
  %38 = icmp slt i32 %37, 1
  br i1 %38, label %270, label %479

39:                                               ; preds = %453
  store i32 1, ptr %6, align 4
  store i32 -1449707719, ptr %5, align 4
  %40 = xor i32 %4, 149476235
  %41 = and i32 %4, %40
  %42 = or i32 %4, %40
  %43 = xor i32 %4, %40
  %44 = mul i32 %42, 2
  %45 = sub i32 %44, %43
  %46 = sub i32 %45, %4
  %47 = sub i32 %46, %40
  %48 = mul i32 %47, 157
  %49 = icmp ne i32 %48, 0
  br i1 %49, label %486, label %270

50:                                               ; preds = %475
  %51 = load i32, ptr %10, align 4
  %52 = load i32, ptr %9, align 4
  %53 = icmp sgt i32 %51, %52
  %54 = select i1 %53, i32 609029574, i32 -233060999
  store i32 %54, ptr %5, align 4
  %55 = xor i32 %4, -1097642737
  %56 = and i32 %4, %55
  %57 = or i32 %4, %55
  %58 = xor i32 %4, %55
  %59 = sub i32 %57, %58
  %60 = sub i32 %59, %56
  %61 = mul i32 %60, 127
  %62 = icmp slt i32 %61, 0
  br i1 %62, label %493, label %270

63:                                               ; preds = %467
  store i32 0, ptr %6, align 4
  store i32 -1449707719, ptr %5, align 4
  %64 = xor i32 %4, -1262871893
  %65 = and i32 %4, %64
  %66 = or i32 %4, %64
  %67 = xor i32 %4, %64
  %68 = add i32 %4, %64
  %69 = sub i32 %68, %67
  %70 = mul i32 %65, 2
  %71 = sub i32 %69, %70
  %72 = mul i32 %71, 166
  %73 = icmp slt i32 %72, 1
  br i1 %73, label %270, label %503

74:                                               ; preds = %457
  store i32 0, ptr %11, align 4
  store i32 703869497, ptr %5, align 4
  %75 = xor i32 %4, -1194534407
  %76 = and i32 %4, %75
  %77 = or i32 %4, %75
  %78 = xor i32 %4, %75
  %79 = add i32 %76, %77
  %80 = sub i32 %79, %4
  %81 = sub i32 %80, %75
  %82 = mul i32 %81, 144
  %83 = icmp slt i32 %82, 0
  br i1 %83, label %512, label %270

84:                                               ; preds = %425
  %85 = load i32, ptr %11, align 4
  %86 = load i32, ptr %9, align 4
  %87 = load i32, ptr %10, align 4
  %88 = load i32, ptr %5, align 4
  %89 = xor i32 %88, 703869496
  %90 = add i32 %87, %89
  %91 = load i32, ptr %5, align 4
  %92 = xor i32 %91, 703869496
  %93 = add i32 %86, %92
  %94 = mul i32 %86, %90
  %95 = mul i32 %87, %93
  %96 = sub i32 %94, %95
  %97 = icmp sle i32 %85, %96
  %98 = select i1 %97, i32 -2048756406, i32 -1088155480
  store i32 %98, ptr %5, align 4
  %99 = xor i32 %4, 447534649
  %100 = and i32 %4, %99
  %101 = or i32 %4, %99
  %102 = xor i32 %4, %99
  %103 = add i32 %100, %101
  %104 = sub i32 %103, %4
  %105 = sub i32 %104, %99
  %106 = mul i32 %105, 54
  %107 = icmp slt i32 %106, 1
  br i1 %107, label %270, label %522

108:                                              ; preds = %437
  store i32 1, ptr %13, align 4
  store i32 0, ptr %12, align 4
  store i32 -864722407, ptr %5, align 4
  %109 = xor i32 %4, -732512561
  %110 = and i32 %4, %109
  %111 = or i32 %4, %109
  %112 = xor i32 %4, %109
  %113 = add i32 %110, %111
  %114 = sub i32 %113, %4
  %115 = sub i32 %114, %109
  %116 = mul i32 %115, 219
  %117 = icmp eq i32 %116, 0
  br i1 %117, label %270, label %529

118:                                              ; preds = %419
  %119 = load i32, ptr %12, align 4
  %120 = load i32, ptr %10, align 4
  %121 = icmp slt i32 %119, %120
  %122 = select i1 %121, i32 -914636031, i32 -1646192707
  store i32 %122, ptr %5, align 4
  %123 = xor i32 %4, -619589783
  %124 = and i32 %4, %123
  %125 = or i32 %4, %123
  %126 = xor i32 %4, %123
  %127 = add i32 %4, %123
  %128 = sub i32 %127, %126
  %129 = mul i32 %124, 2
  %130 = sub i32 %128, %129
  %131 = mul i32 %130, 22
  %132 = icmp slt i32 %131, 0
  br i1 %132, label %539, label %270

133:                                              ; preds = %439
  %134 = load ptr, ptr %7, align 8
  %135 = load i32, ptr %11, align 4
  %136 = load i32, ptr %12, align 4
  %137 = load i32, ptr %5, align 4
  %138 = xor i32 %137, -914636032
  %139 = add i32 %136, %138
  %140 = load i32, ptr %5, align 4
  %141 = xor i32 %140, -914636032
  %142 = sub i32 %135, %141
  %143 = mul i32 %135, %139
  %144 = mul i32 %136, %142
  %145 = sub i32 %143, %144
  %146 = sext i32 %145 to i64
  %147 = getelementptr inbounds i8, ptr %134, i64 %146
  %148 = load i8, ptr %147, align 1
  %149 = zext i8 %148 to i32
  %150 = call i32 @toupper(i32 noundef %149) #8
  %151 = load ptr, ptr %8, align 8
  %152 = load i32, ptr %12, align 4
  %153 = sext i32 %152 to i64
  %154 = getelementptr inbounds i8, ptr %151, i64 %153
  %155 = load i8, ptr %154, align 1
  %156 = zext i8 %155 to i32
  %157 = call i32 @toupper(i32 noundef %156) #8
  %158 = icmp ne i32 %150, %157
  %159 = select i1 %158, i32 1754731945, i32 -530552291
  store i32 %159, ptr %5, align 4
  %160 = xor i32 %4, 1301032589
  %161 = and i32 %4, %160
  %162 = or i32 %4, %160
  %163 = xor i32 %4, %160
  %164 = add i32 %4, %160
  %165 = sub i32 %164, %163
  %166 = mul i32 %161, 2
  %167 = sub i32 %165, %166
  %168 = mul i32 %167, 194
  %169 = icmp slt i32 %168, 1
  br i1 %169, label %270, label %549

170:                                              ; preds = %469
  store i32 0, ptr %13, align 4
  store i32 -1646192707, ptr %5, align 4
  %171 = xor i32 %4, 1724793525
  %172 = and i32 %4, %171
  %173 = or i32 %4, %171
  %174 = xor i32 %4, %171
  %175 = add i32 %172, %173
  %176 = sub i32 %175, %4
  %177 = sub i32 %176, %171
  %178 = mul i32 %177, 227
  %179 = xor i32 %4, 751326945
  %180 = and i32 %4, %179
  %181 = or i32 %4, %179
  %182 = xor i32 %4, %179
  %183 = add i32 %180, %181
  %184 = sub i32 %183, %4
  %185 = sub i32 %184, %179
  %186 = mul i32 %185, 196
  %187 = icmp eq i32 %178, %186
  br i1 %187, label %270, label %558

188:                                              ; preds = %421
  %189 = load i32, ptr %12, align 4
  %190 = load i32, ptr %5, align 4
  %191 = xor i32 %190, -530552292
  %192 = or i32 %189, %191
  %193 = load i32, ptr %5, align 4
  %194 = xor i32 %193, -530552292
  %195 = and i32 %189, %194
  %196 = add i32 %192, %195
  store i32 %196, ptr %12, align 4
  store i32 -864722407, ptr %5, align 4
  %197 = xor i32 %4, -1704993001
  %198 = and i32 %4, %197
  %199 = or i32 %4, %197
  %200 = xor i32 %4, %197
  %201 = sub i32 %199, %200
  %202 = sub i32 %201, %198
  %203 = mul i32 %202, 95
  %204 = icmp ne i32 %203, 0
  br i1 %204, label %565, label %270

205:                                              ; preds = %423
  %206 = load i32, ptr %13, align 4
  %207 = icmp ne i32 %206, 0
  %208 = select i1 %207, i32 195734051, i32 157993927
  store i32 %208, ptr %5, align 4
  %209 = xor i32 %4, 610792341
  %210 = and i32 %4, %209
  %211 = or i32 %4, %209
  %212 = xor i32 %4, %209
  %213 = add i32 %4, %209
  %214 = sub i32 %213, %212
  %215 = mul i32 %210, 2
  %216 = sub i32 %214, %215
  %217 = mul i32 %216, 78
  %218 = icmp sle i32 %217, 0
  br i1 %218, label %270, label %574

219:                                              ; preds = %477
  store i32 1, ptr %6, align 4
  store i32 -1449707719, ptr %5, align 4
  %220 = xor i32 %4, 605336967
  %221 = and i32 %4, %220
  %222 = or i32 %4, %220
  %223 = xor i32 %4, %220
  %224 = add i32 %4, %220
  %225 = sub i32 %224, %223
  %226 = mul i32 %221, 2
  %227 = sub i32 %225, %226
  %228 = mul i32 %227, 110
  %229 = icmp sle i32 %228, 0
  br i1 %229, label %270, label %584

230:                                              ; preds = %471
  %231 = load i32, ptr %11, align 4
  %232 = load i32, ptr %5, align 4
  %233 = xor i32 %232, 157993926
  %234 = xor i32 %231, %233
  %235 = load i32, ptr %5, align 4
  %236 = xor i32 %235, 157993926
  %237 = and i32 %231, %236
  %238 = add i32 %237, %237
  %239 = add i32 %234, %238
  store i32 %239, ptr %11, align 4
  store i32 703869497, ptr %5, align 4
  %240 = xor i32 %4, -1809970733
  %241 = and i32 %4, %240
  %242 = or i32 %4, %240
  %243 = xor i32 %4, %240
  %244 = add i32 %241, %242
  %245 = sub i32 %244, %4
  %246 = sub i32 %245, %240
  %247 = mul i32 %246, 181
  %248 = icmp uge i32 %247, 0
  br i1 %248, label %270, label %591

249:                                              ; preds = %459
  store i32 0, ptr %6, align 4
  store i32 -1449707719, ptr %5, align 4
  %250 = xor i32 %4, 1506203859
  %251 = and i32 %4, %250
  %252 = or i32 %4, %250
  %253 = xor i32 %4, %250
  %254 = add i32 %251, %252
  %255 = sub i32 %254, %4
  %256 = sub i32 %255, %250
  %257 = mul i32 %256, 120
  %258 = xor i32 %4, -1618246349
  %259 = and i32 %4, %258
  %260 = or i32 %4, %258
  %261 = xor i32 %4, %258
  %262 = add i32 %4, %258
  %263 = sub i32 %262, %261
  %264 = mul i32 %259, 2
  %265 = sub i32 %263, %264
  %266 = mul i32 %265, 158
  %267 = icmp eq i32 %257, %266
  br i1 %267, label %270, label %600

268:                                              ; preds = %441
  %269 = load i32, ptr %6, align 4
  ret i32 %269

270:                                              ; preds = %675, %665, %658, %648, %640, %631, %624, %615, %600, %591, %584, %574, %565, %558, %549, %539, %529, %522, %512, %503, %493, %486, %479, %385, %372, %360, %341, %328, %316, %304, %291, %249, %230, %219, %205, %188, %170, %133, %118, %108, %84, %74, %63, %50, %39, %19
  br label %14

271:                                              ; preds = %477, %473, %471, %467, %461, %457, %455, %451, %441, %437, %435, %431, %425, %421, %419, %415
  store i32 1300951377, ptr %5, align 4
  call void asm sideeffect "", ""()
  %272 = xor i32 %4, 1153625049
  %273 = and i32 %4, %272
  %274 = or i32 %4, %272
  %275 = xor i32 %4, %272
  %276 = mul i32 %274, 2
  %277 = sub i32 %276, %275
  %278 = sub i32 %277, %4
  %279 = sub i32 %278, %272
  %280 = mul i32 %279, 230
  %281 = xor i32 %4, -1285696741
  %282 = and i32 %4, %281
  %283 = or i32 %4, %281
  %284 = xor i32 %4, %281
  %285 = mul i32 %283, 2
  %286 = sub i32 %285, %284
  %287 = sub i32 %286, %4
  %288 = sub i32 %287, %281
  %289 = mul i32 %288, 57
  %290 = icmp ne i32 %280, %289
  br i1 %290, label %608, label %14

291:                                              ; preds = %415
  %292 = load i32, ptr %5, align 4
  %293 = xor i32 %292, 1760430395
  store i32 %293, ptr %5, align 4
  %294 = xor i32 %4, -544273259
  %295 = and i32 %4, %294
  %296 = or i32 %4, %294
  %297 = xor i32 %4, %294
  %298 = add i32 %4, %294
  %299 = sub i32 %298, %297
  %300 = mul i32 %295, 2
  %301 = sub i32 %299, %300
  %302 = mul i32 %301, 157
  %303 = icmp sle i32 %302, 0
  br i1 %303, label %270, label %615

304:                                              ; preds = %461
  %305 = load i32, ptr %5, align 4
  %306 = xor i32 %305, 544113943
  store i32 %306, ptr %5, align 4
  %307 = xor i32 %4, -2020453393
  %308 = and i32 %4, %307
  %309 = or i32 %4, %307
  %310 = xor i32 %4, %307
  %311 = add i32 %308, %309
  %312 = sub i32 %311, %4
  %313 = sub i32 %312, %307
  %314 = mul i32 %313, 168
  %315 = icmp ugt i32 %314, 0
  br i1 %315, label %624, label %270

316:                                              ; preds = %451
  %317 = load i32, ptr %5, align 4
  %318 = xor i32 %317, 1765565696
  store i32 %318, ptr %5, align 4
  %319 = xor i32 %4, -1938802259
  %320 = and i32 %4, %319
  %321 = or i32 %4, %319
  %322 = xor i32 %4, %319
  %323 = add i32 %320, %321
  %324 = sub i32 %323, %4
  %325 = sub i32 %324, %319
  %326 = mul i32 %325, 161
  %327 = icmp uge i32 %326, 0
  br i1 %327, label %270, label %631

328:                                              ; preds = %417
  %329 = load i32, ptr %5, align 4
  %330 = xor i32 %329, 1386921799
  store i32 %330, ptr %5, align 4
  %331 = xor i32 %4, -1884352843
  %332 = and i32 %4, %331
  %333 = or i32 %4, %331
  %334 = xor i32 %4, %331
  %335 = mul i32 %333, 2
  %336 = sub i32 %335, %334
  %337 = sub i32 %336, %4
  %338 = sub i32 %337, %331
  %339 = mul i32 %338, 98
  %340 = icmp slt i32 %339, 0
  br i1 %340, label %640, label %270

341:                                              ; preds = %435
  %342 = load i32, ptr %5, align 4
  %343 = xor i32 %342, 538964882
  store i32 %343, ptr %5, align 4
  %344 = xor i32 %4, -2126186701
  %345 = and i32 %4, %344
  %346 = or i32 %4, %344
  %347 = xor i32 %4, %344
  %348 = sub i32 %346, %347
  %349 = sub i32 %348, %345
  %350 = mul i32 %349, 195
  %351 = xor i32 %4, -605188485
  %352 = and i32 %4, %351
  %353 = or i32 %4, %351
  %354 = xor i32 %4, %351
  %355 = add i32 %352, %353
  %356 = sub i32 %355, %4
  %357 = sub i32 %356, %351
  %358 = mul i32 %357, 75
  %359 = icmp eq i32 %350, %358
  br i1 %359, label %270, label %648

360:                                              ; preds = %431
  %361 = load i32, ptr %5, align 4
  %362 = xor i32 %361, -1351754514
  store i32 %362, ptr %5, align 4
  %363 = xor i32 %4, 1709761325
  %364 = and i32 %4, %363
  %365 = or i32 %4, %363
  %366 = xor i32 %4, %363
  %367 = add i32 %364, %365
  %368 = sub i32 %367, %4
  %369 = sub i32 %368, %363
  %370 = mul i32 %369, 27
  %371 = icmp ne i32 %370, 0
  br i1 %371, label %658, label %270

372:                                              ; preds = %473
  %373 = load i32, ptr %5, align 4
  %374 = xor i32 %373, -1522756623
  store i32 %374, ptr %5, align 4
  %375 = xor i32 %4, 1411547751
  %376 = and i32 %4, %375
  %377 = or i32 %4, %375
  %378 = xor i32 %4, %375
  %379 = mul i32 %377, 2
  %380 = sub i32 %379, %378
  %381 = sub i32 %380, %4
  %382 = sub i32 %381, %375
  %383 = mul i32 %382, 239
  %384 = icmp ne i32 %383, 0
  br i1 %384, label %665, label %270

385:                                              ; preds = %433
  %386 = load i32, ptr %5, align 4
  %387 = xor i32 %386, 485742689
  store i32 %387, ptr %5, align 4
  %388 = xor i32 %4, -1705132491
  %389 = and i32 %4, %388
  %390 = or i32 %4, %388
  %391 = xor i32 %4, %388
  %392 = sub i32 %390, %391
  %393 = sub i32 %392, %389
  %394 = mul i32 %393, 59
  %395 = xor i32 %4, -1009724141
  %396 = and i32 %4, %395
  %397 = or i32 %4, %395
  %398 = xor i32 %4, %395
  %399 = sub i32 %397, %398
  %400 = sub i32 %399, %396
  %401 = mul i32 %400, 161
  %402 = icmp eq i32 %394, %401
  br i1 %402, label %270, label %675

403:                                              ; preds = %14
  %404 = icmp slt i32 %17, 802496040
  br i1 %404, label %407, label %409

405:                                              ; preds = %14
  %406 = icmp slt i32 %17, 1867995967
  br i1 %406, label %443, label %445

407:                                              ; preds = %403
  %408 = icmp slt i32 %17, 296357360
  br i1 %408, label %411, label %413

409:                                              ; preds = %403
  %410 = icmp slt i32 %17, 1094494363
  br i1 %410, label %427, label %429

411:                                              ; preds = %407
  %412 = icmp slt i32 %17, 110447821
  br i1 %412, label %415, label %417

413:                                              ; preds = %407
  %414 = icmp slt i32 %17, 364239696
  br i1 %414, label %421, label %423

415:                                              ; preds = %411
  %416 = icmp eq i32 %17, 28270782
  br i1 %416, label %291, label %271

417:                                              ; preds = %411
  %418 = icmp eq i32 %17, 110447821
  br i1 %418, label %328, label %419

419:                                              ; preds = %417
  %420 = icmp eq i32 %17, 186467604
  br i1 %420, label %118, label %271

421:                                              ; preds = %413
  %422 = icmp eq i32 %17, 296357360
  br i1 %422, label %188, label %271

423:                                              ; preds = %413
  %424 = icmp eq i32 %17, 364239696
  br i1 %424, label %205, label %425

425:                                              ; preds = %423
  %426 = icmp eq i32 %17, 739015668
  br i1 %426, label %84, label %271

427:                                              ; preds = %409
  %428 = icmp slt i32 %17, 939808964
  br i1 %428, label %431, label %433

429:                                              ; preds = %409
  %430 = icmp slt i32 %17, 1122744044
  br i1 %430, label %437, label %439

431:                                              ; preds = %427
  %432 = icmp eq i32 %17, 802496040
  br i1 %432, label %360, label %271

433:                                              ; preds = %427
  %434 = icmp eq i32 %17, 939808964
  br i1 %434, label %385, label %435

435:                                              ; preds = %433
  %436 = icmp eq i32 %17, 1070285123
  br i1 %436, label %341, label %271

437:                                              ; preds = %429
  %438 = icmp eq i32 %17, 1094494363
  br i1 %438, label %108, label %271

439:                                              ; preds = %429
  %440 = icmp eq i32 %17, 1122744044
  br i1 %440, label %133, label %441

441:                                              ; preds = %439
  %442 = icmp eq i32 %17, 1302761204
  br i1 %442, label %268, label %271

443:                                              ; preds = %405
  %444 = icmp slt i32 %17, 1681530548
  br i1 %444, label %447, label %449

445:                                              ; preds = %405
  %446 = icmp slt i32 %17, 2009899330
  br i1 %446, label %463, label %465

447:                                              ; preds = %443
  %448 = icmp slt i32 %17, 1476160102
  br i1 %448, label %451, label %453

449:                                              ; preds = %443
  %450 = icmp slt i32 %17, 1713078733
  br i1 %450, label %457, label %459

451:                                              ; preds = %447
  %452 = icmp eq i32 %17, 1419900384
  br i1 %452, label %316, label %271

453:                                              ; preds = %447
  %454 = icmp eq i32 %17, 1476160102
  br i1 %454, label %39, label %455

455:                                              ; preds = %453
  %456 = icmp eq i32 %17, 1518332444
  br i1 %456, label %19, label %271

457:                                              ; preds = %449
  %458 = icmp eq i32 %17, 1681530548
  br i1 %458, label %74, label %271

459:                                              ; preds = %449
  %460 = icmp eq i32 %17, 1713078733
  br i1 %460, label %249, label %461

461:                                              ; preds = %459
  %462 = icmp eq i32 %17, 1860659222
  br i1 %462, label %304, label %271

463:                                              ; preds = %445
  %464 = icmp slt i32 %17, 1897994500
  br i1 %464, label %467, label %469

465:                                              ; preds = %445
  %466 = icmp slt i32 %17, 2041383406
  br i1 %466, label %473, label %475

467:                                              ; preds = %463
  %468 = icmp eq i32 %17, 1867995967
  br i1 %468, label %63, label %271

469:                                              ; preds = %463
  %470 = icmp eq i32 %17, 1897994500
  br i1 %470, label %170, label %471

471:                                              ; preds = %469
  %472 = icmp eq i32 %17, 1986965878
  br i1 %472, label %230, label %271

473:                                              ; preds = %465
  %474 = icmp eq i32 %17, 2009899330
  br i1 %474, label %372, label %271

475:                                              ; preds = %465
  %476 = icmp eq i32 %17, 2041383406
  br i1 %476, label %50, label %477

477:                                              ; preds = %475
  %478 = icmp eq i32 %17, 2047010618
  br i1 %478, label %219, label %271

479:                                              ; preds = %19
  %480 = load i64, ptr %3, align 8
  %481 = ptrtoint ptr %0 to i64
  %482 = ptrtoint ptr %1 to i64
  %483 = and i64 %481, %480
  %484 = and i64 %483, %481
  %485 = mul i64 %484, %480
  store i64 %485, ptr %3, align 8
  br label %270

486:                                              ; preds = %39
  %487 = load i64, ptr %3, align 8
  %488 = ptrtoint ptr %0 to i64
  %489 = ptrtoint ptr %1 to i64
  %490 = and i64 %487, %489
  %491 = and i64 %490, %487
  %492 = xor i64 %491, %487
  store i64 %492, ptr %3, align 8
  br label %270

493:                                              ; preds = %50
  %494 = load i64, ptr %3, align 8
  %495 = ptrtoint ptr %0 to i64
  %496 = ptrtoint ptr %1 to i64
  %497 = add i64 %495, %494
  %498 = xor i64 %497, %495
  %499 = sub i64 %498, %496
  %500 = or i64 %499, %495
  %501 = and i64 %500, %496
  %502 = mul i64 %501, %494
  store i64 %502, ptr %3, align 8
  br label %270

503:                                              ; preds = %63
  %504 = load i64, ptr %3, align 8
  %505 = ptrtoint ptr %0 to i64
  %506 = ptrtoint ptr %1 to i64
  %507 = and i64 %506, %506
  %508 = sub i64 %507, %505
  %509 = add i64 %508, %504
  %510 = mul i64 %509, %505
  %511 = xor i64 %510, %505
  store i64 %511, ptr %3, align 8
  br label %270

512:                                              ; preds = %74
  %513 = load i64, ptr %3, align 8
  %514 = ptrtoint ptr %0 to i64
  %515 = ptrtoint ptr %1 to i64
  %516 = add i64 %515, %514
  %517 = mul i64 %516, %514
  %518 = xor i64 %517, %513
  %519 = or i64 %518, %514
  %520 = sub i64 %519, %515
  %521 = or i64 %520, %513
  store i64 %521, ptr %3, align 8
  br label %270

522:                                              ; preds = %84
  %523 = load i64, ptr %3, align 8
  %524 = ptrtoint ptr %0 to i64
  %525 = ptrtoint ptr %1 to i64
  %526 = sub i64 %523, %523
  %527 = or i64 %526, %524
  %528 = mul i64 %527, %525
  store i64 %528, ptr %3, align 8
  br label %270

529:                                              ; preds = %108
  %530 = load i64, ptr %3, align 8
  %531 = ptrtoint ptr %0 to i64
  %532 = ptrtoint ptr %1 to i64
  %533 = and i64 %532, %530
  %534 = add i64 %533, %531
  %535 = xor i64 %534, %530
  %536 = mul i64 %535, %531
  %537 = mul i64 %536, %531
  %538 = sub i64 %537, %532
  store i64 %538, ptr %3, align 8
  br label %270

539:                                              ; preds = %118
  %540 = load i64, ptr %3, align 8
  %541 = ptrtoint ptr %0 to i64
  %542 = ptrtoint ptr %1 to i64
  %543 = add i64 %541, %542
  %544 = sub i64 %543, %542
  %545 = or i64 %544, %541
  %546 = or i64 %545, %540
  %547 = sub i64 %546, %542
  %548 = mul i64 %547, %542
  store i64 %548, ptr %3, align 8
  br label %270

549:                                              ; preds = %133
  %550 = load i64, ptr %3, align 8
  %551 = ptrtoint ptr %0 to i64
  %552 = ptrtoint ptr %1 to i64
  %553 = mul i64 %552, %550
  %554 = or i64 %553, %550
  %555 = sub i64 %554, %551
  %556 = add i64 %555, %552
  %557 = xor i64 %556, %551
  store i64 %557, ptr %3, align 8
  br label %270

558:                                              ; preds = %170
  %559 = load i64, ptr %3, align 8
  %560 = ptrtoint ptr %0 to i64
  %561 = ptrtoint ptr %1 to i64
  %562 = mul i64 %561, %559
  %563 = or i64 %562, %561
  %564 = or i64 %563, %560
  store i64 %564, ptr %3, align 8
  br label %270

565:                                              ; preds = %188
  %566 = load i64, ptr %3, align 8
  %567 = ptrtoint ptr %0 to i64
  %568 = ptrtoint ptr %1 to i64
  %569 = xor i64 %566, %567
  %570 = add i64 %569, %567
  %571 = or i64 %570, %568
  %572 = add i64 %571, %567
  %573 = or i64 %572, %568
  store i64 %573, ptr %3, align 8
  br label %270

574:                                              ; preds = %205
  %575 = load i64, ptr %3, align 8
  %576 = ptrtoint ptr %0 to i64
  %577 = ptrtoint ptr %1 to i64
  %578 = or i64 %575, %576
  %579 = add i64 %578, %577
  %580 = xor i64 %579, %575
  %581 = mul i64 %580, %577
  %582 = mul i64 %581, %575
  %583 = sub i64 %582, %577
  store i64 %583, ptr %3, align 8
  br label %270

584:                                              ; preds = %219
  %585 = load i64, ptr %3, align 8
  %586 = ptrtoint ptr %0 to i64
  %587 = ptrtoint ptr %1 to i64
  %588 = sub i64 %585, %585
  %589 = mul i64 %588, %585
  %590 = and i64 %589, %585
  store i64 %590, ptr %3, align 8
  br label %270

591:                                              ; preds = %230
  %592 = load i64, ptr %3, align 8
  %593 = ptrtoint ptr %0 to i64
  %594 = ptrtoint ptr %1 to i64
  %595 = add i64 %594, %594
  %596 = sub i64 %595, %592
  %597 = xor i64 %596, %594
  %598 = or i64 %597, %593
  %599 = xor i64 %598, %592
  store i64 %599, ptr %3, align 8
  br label %270

600:                                              ; preds = %249
  %601 = load i64, ptr %3, align 8
  %602 = ptrtoint ptr %0 to i64
  %603 = ptrtoint ptr %1 to i64
  %604 = sub i64 %602, %603
  %605 = xor i64 %604, %603
  %606 = add i64 %605, %602
  %607 = mul i64 %606, %602
  store i64 %607, ptr %3, align 8
  br label %270

608:                                              ; preds = %271
  %609 = load i64, ptr %3, align 8
  %610 = ptrtoint ptr %0 to i64
  %611 = ptrtoint ptr %1 to i64
  %612 = mul i64 %610, %610
  %613 = or i64 %612, %609
  %614 = add i64 %613, %610
  store i64 %614, ptr %3, align 8
  br label %14

615:                                              ; preds = %291
  %616 = load i64, ptr %3, align 8
  %617 = ptrtoint ptr %0 to i64
  %618 = ptrtoint ptr %1 to i64
  %619 = sub i64 %616, %618
  %620 = or i64 %619, %617
  %621 = xor i64 %620, %616
  %622 = sub i64 %621, %616
  %623 = xor i64 %622, %616
  store i64 %623, ptr %3, align 8
  br label %270

624:                                              ; preds = %304
  %625 = load i64, ptr %3, align 8
  %626 = ptrtoint ptr %0 to i64
  %627 = ptrtoint ptr %1 to i64
  %628 = xor i64 %625, %626
  %629 = or i64 %628, %625
  %630 = sub i64 %629, %625
  store i64 %630, ptr %3, align 8
  br label %270

631:                                              ; preds = %316
  %632 = load i64, ptr %3, align 8
  %633 = ptrtoint ptr %0 to i64
  %634 = ptrtoint ptr %1 to i64
  %635 = and i64 %632, %633
  %636 = xor i64 %635, %632
  %637 = and i64 %636, %633
  %638 = or i64 %637, %634
  %639 = mul i64 %638, %633
  store i64 %639, ptr %3, align 8
  br label %270

640:                                              ; preds = %328
  %641 = load i64, ptr %3, align 8
  %642 = ptrtoint ptr %0 to i64
  %643 = ptrtoint ptr %1 to i64
  %644 = mul i64 %643, %643
  %645 = or i64 %644, %643
  %646 = add i64 %645, %642
  %647 = and i64 %646, %643
  store i64 %647, ptr %3, align 8
  br label %270

648:                                              ; preds = %341
  %649 = load i64, ptr %3, align 8
  %650 = ptrtoint ptr %0 to i64
  %651 = ptrtoint ptr %1 to i64
  %652 = sub i64 %651, %651
  %653 = mul i64 %652, %650
  %654 = and i64 %653, %649
  %655 = xor i64 %654, %649
  %656 = sub i64 %655, %650
  %657 = mul i64 %656, %650
  store i64 %657, ptr %3, align 8
  br label %270

658:                                              ; preds = %360
  %659 = load i64, ptr %3, align 8
  %660 = ptrtoint ptr %0 to i64
  %661 = ptrtoint ptr %1 to i64
  %662 = mul i64 %659, %659
  %663 = sub i64 %662, %660
  %664 = add i64 %663, %659
  store i64 %664, ptr %3, align 8
  br label %270

665:                                              ; preds = %372
  %666 = load i64, ptr %3, align 8
  %667 = ptrtoint ptr %0 to i64
  %668 = ptrtoint ptr %1 to i64
  %669 = and i64 %666, %666
  %670 = sub i64 %669, %667
  %671 = xor i64 %670, %668
  %672 = or i64 %671, %666
  %673 = add i64 %672, %666
  %674 = and i64 %673, %666
  store i64 %674, ptr %3, align 8
  br label %270

675:                                              ; preds = %385
  %676 = load i64, ptr %3, align 8
  %677 = ptrtoint ptr %0 to i64
  %678 = ptrtoint ptr %1 to i64
  %679 = or i64 %678, %677
  %680 = or i64 %679, %676
  %681 = xor i64 %680, %677
  store i64 %681, ptr %3, align 8
  br label %270
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @printMoney(i64 noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = alloca i32, align 4
  %4 = alloca i64, align 8
  store i32 1826672505, ptr %3, align 4
  br label %5

5:                                                ; preds = %114, %54, %53, %1
  %6 = load i32, ptr %3, align 4
  %7 = sub i32 %6, 783113826
  %8 = mul i32 %7, -1329537305
  switch i32 %8, label %54 [
    i32 1572666817, label %9
    i32 1261897444, label %31
    i32 418675494, label %47
    i32 1317287461, label %64
    i32 711320916, label %75
    i32 9886094, label %87
  ]

9:                                                ; preds = %5
  store i64 %0, ptr %4, align 8
  %10 = load i64, ptr %4, align 8
  %11 = icmp slt i64 %10, 0
  %12 = select i1 %11, i32 1042479070, i32 -1240251572
  store i32 %12, ptr %3, align 4
  %13 = xor i64 %0, -7788533182835375511
  %14 = and i64 %0, %13
  %15 = or i64 %0, %13
  %16 = xor i64 %0, %13
  %17 = add i64 %0, %13
  %18 = sub i64 %17, %16
  %19 = mul i64 %14, 2
  %20 = sub i64 %18, %19
  %21 = mul i64 %20, 73
  %22 = xor i64 %0, -939585206603421357
  %23 = and i64 %0, %22
  %24 = or i64 %0, %22
  %25 = xor i64 %0, %22
  %26 = add i64 %23, %24
  %27 = sub i64 %26, %0
  %28 = sub i64 %27, %22
  %29 = mul i64 %28, 145
  %30 = icmp ne i64 %21, %29
  br i1 %30, label %98, label %53

31:                                               ; preds = %5
  %32 = call i32 @putchar(i32 noundef 45)
  %33 = load i64, ptr %4, align 8
  %34 = add i64 %33, 1
  %35 = mul i64 0, %34
  %36 = mul i64 %33, 1
  %37 = sub i64 %35, %36
  store i64 %37, ptr %4, align 8
  store i32 -1240251572, ptr %3, align 4
  %38 = xor i64 %0, -2173006715245663013
  %39 = and i64 %0, %38
  %40 = or i64 %0, %38
  %41 = xor i64 %0, %38
  %42 = add i64 %39, %40
  %43 = sub i64 %42, %0
  %44 = sub i64 %43, %38
  %45 = mul i64 %44, 24
  %46 = icmp eq i64 %45, 0
  br i1 %46, label %53, label %106

47:                                               ; preds = %5
  %48 = load i64, ptr %4, align 8
  %49 = sdiv i64 %48, 100
  %50 = load i64, ptr %4, align 8
  %51 = srem i64 %50, 100
  %52 = call i32 (ptr, ...) @printf(ptr noundef @.str, i64 noundef %49, i64 noundef %51)
  ret void

53:                                               ; preds = %135, %129, %122, %106, %98, %87, %75, %64, %31, %9
  br label %5

54:                                               ; preds = %5
  store i32 1826672505, ptr %3, align 4
  call void asm sideeffect "", ""()
  %55 = xor i64 %0, 2364451737575304765
  %56 = and i64 %0, %55
  %57 = or i64 %0, %55
  %58 = xor i64 %0, %55
  %59 = add i64 %56, %57
  %60 = sub i64 %59, %0
  %61 = sub i64 %60, %55
  %62 = mul i64 %61, 225
  %63 = icmp sgt i64 %62, 0
  br i1 %63, label %114, label %5

64:                                               ; preds = %5
  %65 = load i32, ptr %3, align 4
  %66 = xor i32 %65, 106551835
  store i32 %66, ptr %3, align 4
  %67 = xor i64 %0, 8555099446808523755
  %68 = and i64 %0, %67
  %69 = or i64 %0, %67
  %70 = xor i64 %0, %67
  %71 = sub i64 %69, %70
  %72 = sub i64 %71, %68
  %73 = mul i64 %72, 23
  %74 = icmp ne i64 %73, 0
  br i1 %74, label %122, label %53

75:                                               ; preds = %5
  %76 = load i32, ptr %3, align 4
  %77 = xor i32 %76, 630116968
  store i32 %77, ptr %3, align 4
  %78 = xor i64 %0, -5359687364995427903
  %79 = and i64 %0, %78
  %80 = or i64 %0, %78
  %81 = xor i64 %0, %78
  %82 = add i64 %79, %80
  %83 = sub i64 %82, %0
  %84 = sub i64 %83, %78
  %85 = mul i64 %84, 74
  %86 = icmp ne i64 %85, 0
  br i1 %86, label %129, label %53

87:                                               ; preds = %5
  %88 = load i32, ptr %3, align 4
  %89 = xor i32 %88, 1195726644
  store i32 %89, ptr %3, align 4
  %90 = xor i64 %0, -1943248380396139021
  %91 = and i64 %0, %90
  %92 = or i64 %0, %90
  %93 = xor i64 %0, %90
  %94 = sub i64 %92, %93
  %95 = sub i64 %94, %91
  %96 = mul i64 %95, 157
  %97 = icmp eq i64 %96, 0
  br i1 %97, label %53, label %135

98:                                               ; preds = %9
  %99 = load i64, ptr %2, align 8
  %100 = or i64 %0, %0
  %101 = or i64 %100, %99
  %102 = xor i64 %101, %99
  %103 = add i64 %102, %99
  %104 = and i64 %103, %0
  %105 = add i64 %104, %99
  store i64 %105, ptr %2, align 8
  br label %53

106:                                              ; preds = %31
  %107 = load i64, ptr %2, align 8
  %108 = mul i64 %107, %0
  %109 = xor i64 %108, %107
  %110 = and i64 %109, %107
  %111 = xor i64 %110, %107
  %112 = and i64 %111, %0
  %113 = and i64 %112, %107
  store i64 %113, ptr %2, align 8
  br label %53

114:                                              ; preds = %54
  %115 = load i64, ptr %2, align 8
  %116 = and i64 %115, %115
  %117 = or i64 %116, %115
  %118 = or i64 %117, %115
  %119 = sub i64 %118, %0
  %120 = add i64 %119, %115
  %121 = and i64 %120, %115
  store i64 %121, ptr %2, align 8
  br label %5

122:                                              ; preds = %64
  %123 = load i64, ptr %2, align 8
  %124 = or i64 %0, %0
  %125 = and i64 %124, %123
  %126 = sub i64 %125, %0
  %127 = mul i64 %126, %123
  %128 = and i64 %127, %123
  store i64 %128, ptr %2, align 8
  br label %53

129:                                              ; preds = %75
  %130 = load i64, ptr %2, align 8
  %131 = xor i64 %0, %0
  %132 = and i64 %131, %130
  %133 = sub i64 %132, %130
  %134 = xor i64 %133, %130
  store i64 %134, ptr %2, align 8
  br label %53

135:                                              ; preds = %87
  %136 = load i64, ptr %2, align 8
  %137 = xor i64 %136, %0
  %138 = add i64 %137, %0
  %139 = or i64 %138, %136
  %140 = sub i64 %139, %0
  %141 = sub i64 %140, %136
  %142 = add i64 %141, %0
  store i64 %142, ptr %2, align 8
  br label %53
}

declare i32 @putchar(i32 noundef) #4

declare i32 @printf(ptr noundef, ...) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @parseIntStrict(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i64, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store i32 -1147045922, ptr %5, align 4
  br label %12

12:                                               ; preds = %629, %357, %356, %2
  %13 = load i32, ptr %5, align 4
  %14 = sub i32 %13, -1720843656
  %15 = mul i32 %14, 465718527
  switch i32 %15, label %357 [
    i32 292042906, label %16
    i32 2140783561, label %30
    i32 1627354034, label %45
    i32 303000253, label %65
    i32 785982740, label %84
    i32 2035654901, label %110
    i32 1755337465, label %121
    i32 1213064671, label %131
    i32 807243870, label %140
    i32 1485808113, label %157
    i32 1097341618, label %197
    i32 1717557164, label %208
    i32 561179167, label %245
    i32 567918777, label %258
    i32 1939783823, label %275
    i32 401986392, label %289
    i32 841340778, label %307
    i32 639481697, label %316
    i32 2110387889, label %337
    i32 2042234339, label %354
    i32 96927162, label %368
    i32 1939717882, label %380
    i32 615900316, label %393
    i32 3330798, label %405
    i32 1457211772, label %418
    i32 451993708, label %430
    i32 431352959, label %441
    i32 236268670, label %454
  ]

16:                                               ; preds = %12
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  store i64 0, ptr %9, align 8
  store i32 1, ptr %10, align 4
  store i32 0, ptr %11, align 4
  %17 = load ptr, ptr %7, align 8
  %18 = icmp eq ptr %17, null
  %19 = select i1 %18, i32 675022022, i32 -848442961
  store i32 %19, ptr %5, align 4
  %20 = xor i32 %4, 1765065993
  %21 = and i32 %4, %20
  %22 = or i32 %4, %20
  %23 = xor i32 %4, %20
  %24 = mul i32 %22, 2
  %25 = sub i32 %24, %23
  %26 = sub i32 %25, %4
  %27 = sub i32 %26, %20
  %28 = mul i32 %27, 201
  %29 = icmp slt i32 %28, 1
  br i1 %29, label %356, label %467

30:                                               ; preds = %12
  %31 = load ptr, ptr %7, align 8
  %32 = getelementptr inbounds i8, ptr %31, i64 0
  %33 = load i8, ptr %32, align 1
  %34 = sext i8 %33 to i32
  %35 = icmp eq i32 %34, 0
  %36 = select i1 %35, i32 675022022, i32 1506066107
  store i32 %36, ptr %5, align 4
  %37 = xor i32 %4, -392500321
  %38 = and i32 %4, %37
  %39 = or i32 %4, %37
  %40 = xor i32 %4, %37
  %41 = sub i32 %39, %40
  %42 = sub i32 %41, %38
  %43 = mul i32 %42, 242
  %44 = icmp ne i32 %43, 0
  br i1 %44, label %474, label %356

45:                                               ; preds = %12
  store i32 0, ptr %6, align 4
  store i32 1938666901, ptr %5, align 4
  %46 = xor i32 %4, 677913129
  %47 = and i32 %4, %46
  %48 = or i32 %4, %46
  %49 = xor i32 %4, %46
  %50 = add i32 %4, %46
  %51 = sub i32 %50, %49
  %52 = mul i32 %47, 2
  %53 = sub i32 %51, %52
  %54 = mul i32 %53, 72
  %55 = xor i32 %4, -1837758253
  %56 = and i32 %4, %55
  %57 = or i32 %4, %55
  %58 = xor i32 %4, %55
  %59 = add i32 %4, %55
  %60 = sub i32 %59, %58
  %61 = mul i32 %56, 2
  %62 = sub i32 %60, %61
  %63 = mul i32 %62, 12
  %64 = icmp ne i32 %54, %63
  br i1 %64, label %484, label %356

65:                                               ; preds = %12
  %66 = load ptr, ptr %7, align 8
  %67 = load i32, ptr %11, align 4
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds i8, ptr %66, i64 %68
  %70 = load i8, ptr %69, align 1
  %71 = sext i8 %70 to i32
  %72 = icmp eq i32 %71, 45
  %73 = select i1 %72, i32 1964104036, i32 2051475865
  store i32 %73, ptr %5, align 4
  %74 = xor i32 %4, 1815653547
  %75 = and i32 %4, %74
  %76 = or i32 %4, %74
  %77 = xor i32 %4, %74
  %78 = mul i32 %76, 2
  %79 = sub i32 %78, %77
  %80 = sub i32 %79, %4
  %81 = sub i32 %80, %74
  %82 = mul i32 %81, 194
  %83 = icmp sle i32 %82, 0
  br i1 %83, label %356, label %494

84:                                               ; preds = %12
  store i32 -1, ptr %10, align 4
  %85 = load i32, ptr %11, align 4
  %86 = load i32, ptr %5, align 4
  %87 = xor i32 %86, 1964104037
  %88 = xor i32 %85, %87
  %89 = load i32, ptr %5, align 4
  %90 = xor i32 %89, 1964104037
  %91 = and i32 %85, %90
  %92 = add i32 %91, %91
  %93 = add i32 %88, %92
  store i32 %93, ptr %11, align 4
  %94 = load ptr, ptr %7, align 8
  %95 = load i32, ptr %11, align 4
  %96 = sext i32 %95 to i64
  %97 = getelementptr inbounds i8, ptr %94, i64 %96
  %98 = load i8, ptr %97, align 1
  %99 = icmp ne i8 %98, 0
  %100 = select i1 %99, i32 1782958719, i32 650621059
  store i32 %100, ptr %5, align 4
  %101 = xor i32 %4, -740105743
  %102 = and i32 %4, %101
  %103 = or i32 %4, %101
  %104 = xor i32 %4, %101
  %105 = add i32 %102, %103
  %106 = sub i32 %105, %4
  %107 = sub i32 %106, %101
  %108 = mul i32 %107, 84
  %109 = icmp slt i32 %108, 1
  br i1 %109, label %356, label %504

110:                                              ; preds = %12
  store i32 0, ptr %6, align 4
  store i32 1938666901, ptr %5, align 4
  %111 = xor i32 %4, 1136103403
  %112 = and i32 %4, %111
  %113 = or i32 %4, %111
  %114 = xor i32 %4, %111
  %115 = mul i32 %113, 2
  %116 = sub i32 %115, %114
  %117 = sub i32 %116, %4
  %118 = sub i32 %117, %111
  %119 = mul i32 %118, 196
  %120 = icmp slt i32 %119, 0
  br i1 %120, label %512, label %356

121:                                              ; preds = %12
  store i32 2051475865, ptr %5, align 4
  %122 = xor i32 %4, -806707799
  %123 = and i32 %4, %122
  %124 = or i32 %4, %122
  %125 = xor i32 %4, %122
  %126 = add i32 %123, %124
  %127 = sub i32 %126, %4
  %128 = sub i32 %127, %122
  %129 = mul i32 %128, 162
  %130 = icmp ugt i32 %129, 0
  br i1 %130, label %521, label %356

131:                                              ; preds = %12
  store i32 1419389978, ptr %5, align 4
  %132 = xor i32 %4, -1079462061
  %133 = and i32 %4, %132
  %134 = or i32 %4, %132
  %135 = xor i32 %4, %132
  %136 = sub i32 %134, %135
  %137 = sub i32 %136, %133
  %138 = mul i32 %137, 50
  %139 = icmp eq i32 %138, 0
  br i1 %139, label %356, label %530

140:                                              ; preds = %12
  %141 = load ptr, ptr %7, align 8
  %142 = load i32, ptr %11, align 4
  %143 = sext i32 %142 to i64
  %144 = getelementptr inbounds i8, ptr %141, i64 %143
  %145 = load i8, ptr %144, align 1
  %146 = icmp ne i8 %145, 0
  %147 = select i1 %146, i32 -638721145, i32 485871303
  store i32 %147, ptr %5, align 4
  %148 = xor i32 %4, -774426899
  %149 = and i32 %4, %148
  %150 = or i32 %4, %148
  %151 = xor i32 %4, %148
  %152 = add i32 %149, %150
  %153 = sub i32 %152, %4
  %154 = sub i32 %153, %148
  %155 = mul i32 %154, 192
  %156 = icmp uge i32 %155, 0
  br i1 %156, label %356, label %537

157:                                              ; preds = %12
  %158 = call ptr @__ctype_b_loc() #7
  %159 = load ptr, ptr %158, align 8
  %160 = load ptr, ptr %7, align 8
  %161 = load i32, ptr %11, align 4
  %162 = sext i32 %161 to i64
  %163 = getelementptr inbounds i8, ptr %160, i64 %162
  %164 = load i8, ptr %163, align 1
  %165 = zext i8 %164 to i32
  %166 = sext i32 %165 to i64
  %167 = getelementptr inbounds i16, ptr %159, i64 %166
  %168 = load i16, ptr %167, align 2
  %169 = zext i16 %168 to i32
  %170 = load i32, ptr %5, align 4
  %171 = xor i32 %170, -638719097
  %172 = add i32 %169, %171
  %173 = load i32, ptr %5, align 4
  %174 = xor i32 %173, -638719097
  %175 = or i32 %169, %174
  %176 = sub i32 %172, %175
  %177 = icmp ne i32 %176, 0
  %178 = select i1 %177, i32 -1068798260, i32 -2137498170
  store i32 %178, ptr %5, align 4
  %179 = xor i32 %4, -693710641
  %180 = and i32 %4, %179
  %181 = or i32 %4, %179
  %182 = xor i32 %4, %179
  %183 = add i32 %180, %181
  %184 = sub i32 %183, %4
  %185 = sub i32 %184, %179
  %186 = mul i32 %185, 126
  %187 = xor i32 %4, -792489707
  %188 = and i32 %4, %187
  %189 = or i32 %4, %187
  %190 = xor i32 %4, %187
  %191 = add i32 %4, %187
  %192 = sub i32 %191, %190
  %193 = mul i32 %188, 2
  %194 = sub i32 %192, %193
  %195 = mul i32 %194, 214
  %196 = icmp eq i32 %186, %195
  br i1 %196, label %356, label %544

197:                                              ; preds = %12
  store i32 0, ptr %6, align 4
  store i32 1938666901, ptr %5, align 4
  %198 = xor i32 %4, 1863445587
  %199 = and i32 %4, %198
  %200 = or i32 %4, %198
  %201 = xor i32 %4, %198
  %202 = mul i32 %200, 2
  %203 = sub i32 %202, %201
  %204 = sub i32 %203, %4
  %205 = sub i32 %204, %198
  %206 = mul i32 %205, 39
  %207 = icmp ugt i32 %206, 0
  br i1 %207, label %554, label %356

208:                                              ; preds = %12
  %209 = load i64, ptr %9, align 8
  %210 = mul nsw i64 %209, 10
  %211 = load ptr, ptr %7, align 8
  %212 = load i32, ptr %11, align 4
  %213 = sext i32 %212 to i64
  %214 = getelementptr inbounds i8, ptr %211, i64 %213
  %215 = load i8, ptr %214, align 1
  %216 = sext i8 %215 to i32
  %217 = load i32, ptr %5, align 4
  %218 = xor i32 %217, -1068798259
  %219 = add i32 %216, %218
  %220 = load i32, ptr %5, align 4
  %221 = xor i32 %220, -1068798211
  %222 = mul i32 %216, %221
  %223 = load i32, ptr %5, align 4
  %224 = xor i32 %223, -1068798212
  %225 = mul i32 %224, %219
  %226 = sub i32 %222, %225
  %227 = sext i32 %226 to i64
  %228 = xor i64 %210, %227
  %229 = and i64 %210, %227
  %230 = add i64 %229, %229
  %231 = add i64 %228, %230
  store i64 %231, ptr %9, align 8
  %232 = load i32, ptr %10, align 4
  %233 = icmp eq i32 %232, 1
  %234 = select i1 %233, i32 -669334183, i32 -1382072599
  store i32 %234, ptr %5, align 4
  %235 = xor i32 %4, 1463322071
  %236 = and i32 %4, %235
  %237 = or i32 %4, %235
  %238 = xor i32 %4, %235
  %239 = mul i32 %237, 2
  %240 = sub i32 %239, %238
  %241 = sub i32 %240, %4
  %242 = sub i32 %241, %235
  %243 = mul i32 %242, 113
  %244 = icmp sgt i32 %243, 0
  br i1 %244, label %562, label %356

245:                                              ; preds = %12
  %246 = load i64, ptr %9, align 8
  %247 = icmp sgt i64 %246, 2147483647
  %248 = select i1 %247, i32 1808374975, i32 -1382072599
  store i32 %248, ptr %5, align 4
  %249 = xor i32 %4, 637028991
  %250 = and i32 %4, %249
  %251 = or i32 %4, %249
  %252 = xor i32 %4, %249
  %253 = add i32 %250, %251
  %254 = sub i32 %253, %4
  %255 = sub i32 %254, %249
  %256 = mul i32 %255, 98
  %257 = icmp sle i32 %256, 0
  br i1 %257, label %356, label %572

258:                                              ; preds = %12
  store i32 0, ptr %6, align 4
  store i32 1938666901, ptr %5, align 4
  %259 = xor i32 %4, -445232607
  %260 = and i32 %4, %259
  %261 = or i32 %4, %259
  %262 = xor i32 %4, %259
  %263 = add i32 %260, %261
  %264 = sub i32 %263, %4
  %265 = sub i32 %264, %259
  %266 = mul i32 %265, 226
  %267 = xor i32 %4, 927838669
  %268 = and i32 %4, %267
  %269 = or i32 %4, %267
  %270 = xor i32 %4, %267
  %271 = sub i32 %269, %270
  %272 = sub i32 %271, %268
  %273 = mul i32 %272, 107
  %274 = icmp ne i32 %266, %273
  br i1 %274, label %582, label %356

275:                                              ; preds = %12
  %276 = load i32, ptr %10, align 4
  %277 = icmp eq i32 %276, -1
  %278 = select i1 %277, i32 1193195296, i32 -769843689
  store i32 %278, ptr %5, align 4
  %279 = xor i32 %4, 632113001
  %280 = and i32 %4, %279
  %281 = or i32 %4, %279
  %282 = xor i32 %4, %279
  %283 = add i32 %4, %279
  %284 = sub i32 %283, %282
  %285 = mul i32 %280, 2
  %286 = sub i32 %284, %285
  %287 = mul i32 %286, 52
  %288 = icmp sgt i32 %287, 0
  br i1 %288, label %591, label %356

289:                                              ; preds = %12
  %290 = load i64, ptr %9, align 8
  %291 = xor i64 0, %290
  %292 = and i64 -1, %290
  %293 = add i64 %292, %292
  %294 = sub i64 %291, %293
  %295 = icmp slt i64 %294, -2147483648
  %296 = select i1 %295, i32 -651212530, i32 -769843689
  store i32 %296, ptr %5, align 4
  %297 = xor i32 %4, 731495007
  %298 = and i32 %4, %297
  %299 = or i32 %4, %297
  %300 = xor i32 %4, %297
  %301 = add i32 %4, %297
  %302 = sub i32 %301, %300
  %303 = mul i32 %298, 2
  %304 = sub i32 %302, %303
  %305 = mul i32 %304, 75
  %306 = icmp ugt i32 %305, 0
  br i1 %306, label %598, label %356

307:                                              ; preds = %12
  store i32 0, ptr %6, align 4
  store i32 1938666901, ptr %5, align 4
  %308 = xor i32 %4, 1282355185
  %309 = and i32 %4, %308
  %310 = or i32 %4, %308
  %311 = xor i32 %4, %308
  %312 = sub i32 %310, %311
  %313 = sub i32 %312, %309
  %314 = mul i32 %313, 223
  %315 = icmp eq i32 %314, 0
  br i1 %315, label %356, label %607

316:                                              ; preds = %12
  %317 = load i32, ptr %11, align 4
  %318 = load i32, ptr %5, align 4
  %319 = xor i32 %318, -769843690
  %320 = sub i32 %317, %319
  %321 = load i32, ptr %5, align 4
  %322 = xor i32 %321, -769843691
  %323 = mul i32 %317, %322
  %324 = load i32, ptr %5, align 4
  %325 = xor i32 %324, -769843690
  %326 = mul i32 %325, %320
  %327 = sub i32 %323, %326
  store i32 %327, ptr %11, align 4
  store i32 1419389978, ptr %5, align 4
  %328 = xor i32 %4, -635677493
  %329 = and i32 %4, %328
  %330 = or i32 %4, %328
  %331 = xor i32 %4, %328
  %332 = add i32 %329, %330
  %333 = sub i32 %332, %4
  %334 = sub i32 %333, %328
  %335 = mul i32 %334, 217
  %336 = icmp slt i32 %335, 1
  br i1 %336, label %356, label %614

337:                                              ; preds = %12
  %338 = load i64, ptr %9, align 8
  %339 = load i32, ptr %10, align 4
  %340 = sext i32 %339 to i64
  %341 = mul nsw i64 %338, %340
  %342 = trunc i64 %341 to i32
  %343 = load ptr, ptr %8, align 8
  store i32 %342, ptr %343, align 4
  store i32 1, ptr %6, align 4
  store i32 1938666901, ptr %5, align 4
  %344 = xor i32 %4, -1492601265
  %345 = and i32 %4, %344
  %346 = or i32 %4, %344
  %347 = xor i32 %4, %344
  %348 = add i32 %4, %344
  %349 = sub i32 %348, %347
  %350 = mul i32 %345, 2
  %351 = sub i32 %349, %350
  %352 = mul i32 %351, 9
  %353 = icmp sgt i32 %352, 0
  br i1 %353, label %622, label %356

354:                                              ; preds = %12
  %355 = load i32, ptr %6, align 4
  ret i32 %355

356:                                              ; preds = %699, %691, %682, %672, %662, %655, %645, %638, %622, %614, %607, %598, %591, %582, %572, %562, %554, %544, %537, %530, %521, %512, %504, %494, %484, %474, %467, %454, %441, %430, %418, %405, %393, %380, %368, %337, %316, %307, %289, %275, %258, %245, %208, %197, %157, %140, %131, %121, %110, %84, %65, %45, %30, %16
  br label %12

357:                                              ; preds = %12
  store i32 -1147045922, ptr %5, align 4
  call void asm sideeffect "", ""()
  %358 = xor i32 %4, -1361801017
  %359 = and i32 %4, %358
  %360 = or i32 %4, %358
  %361 = xor i32 %4, %358
  %362 = add i32 %4, %358
  %363 = sub i32 %362, %361
  %364 = mul i32 %359, 2
  %365 = sub i32 %363, %364
  %366 = mul i32 %365, 204
  %367 = icmp slt i32 %366, 1
  br i1 %367, label %12, label %629

368:                                              ; preds = %12
  %369 = load i32, ptr %5, align 4
  %370 = xor i32 %369, 306314024
  store i32 %370, ptr %5, align 4
  %371 = xor i32 %4, 479926005
  %372 = and i32 %4, %371
  %373 = or i32 %4, %371
  %374 = xor i32 %4, %371
  %375 = add i32 %372, %373
  %376 = sub i32 %375, %4
  %377 = sub i32 %376, %371
  %378 = mul i32 %377, 89
  %379 = icmp ne i32 %378, 0
  br i1 %379, label %638, label %356

380:                                              ; preds = %12
  %381 = load i32, ptr %5, align 4
  %382 = xor i32 %381, 1640237996
  store i32 %382, ptr %5, align 4
  %383 = xor i32 %4, -2044175539
  %384 = and i32 %4, %383
  %385 = or i32 %4, %383
  %386 = xor i32 %4, %383
  %387 = mul i32 %385, 2
  %388 = sub i32 %387, %386
  %389 = sub i32 %388, %4
  %390 = sub i32 %389, %383
  %391 = mul i32 %390, 97
  %392 = icmp uge i32 %391, 0
  br i1 %392, label %356, label %645

393:                                              ; preds = %12
  %394 = load i32, ptr %5, align 4
  %395 = xor i32 %394, -693812422
  store i32 %395, ptr %5, align 4
  %396 = xor i32 %4, 1427336171
  %397 = and i32 %4, %396
  %398 = or i32 %4, %396
  %399 = xor i32 %4, %396
  %400 = add i32 %397, %398
  %401 = sub i32 %400, %4
  %402 = sub i32 %401, %396
  %403 = mul i32 %402, 17
  %404 = icmp eq i32 %403, 0
  br i1 %404, label %356, label %655

405:                                              ; preds = %12
  %406 = load i32, ptr %5, align 4
  %407 = xor i32 %406, -2062503710
  store i32 %407, ptr %5, align 4
  %408 = xor i32 %4, 1332404069
  %409 = and i32 %4, %408
  %410 = or i32 %4, %408
  %411 = xor i32 %4, %408
  %412 = add i32 %4, %408
  %413 = sub i32 %412, %411
  %414 = mul i32 %409, 2
  %415 = sub i32 %413, %414
  %416 = mul i32 %415, 247
  %417 = icmp slt i32 %416, 1
  br i1 %417, label %356, label %662

418:                                              ; preds = %12
  %419 = load i32, ptr %5, align 4
  %420 = xor i32 %419, -1081215336
  store i32 %420, ptr %5, align 4
  %421 = xor i32 %4, -267708245
  %422 = and i32 %4, %421
  %423 = or i32 %4, %421
  %424 = xor i32 %4, %421
  %425 = add i32 %422, %423
  %426 = sub i32 %425, %4
  %427 = sub i32 %426, %421
  %428 = mul i32 %427, 240
  %429 = icmp eq i32 %428, 0
  br i1 %429, label %356, label %672

430:                                              ; preds = %12
  %431 = load i32, ptr %5, align 4
  %432 = xor i32 %431, -1783159037
  store i32 %432, ptr %5, align 4
  %433 = xor i32 %4, 1290940113
  %434 = and i32 %4, %433
  %435 = or i32 %4, %433
  %436 = xor i32 %4, %433
  %437 = sub i32 %435, %436
  %438 = sub i32 %437, %434
  %439 = mul i32 %438, 10
  %440 = icmp slt i32 %439, 0
  br i1 %440, label %682, label %356

441:                                              ; preds = %12
  %442 = load i32, ptr %5, align 4
  %443 = xor i32 %442, 1180738867
  store i32 %443, ptr %5, align 4
  %444 = xor i32 %4, -1531206533
  %445 = and i32 %4, %444
  %446 = or i32 %4, %444
  %447 = xor i32 %4, %444
  %448 = add i32 %4, %444
  %449 = sub i32 %448, %447
  %450 = mul i32 %445, 2
  %451 = sub i32 %449, %450
  %452 = mul i32 %451, 130
  %453 = icmp slt i32 %452, 1
  br i1 %453, label %356, label %691

454:                                              ; preds = %12
  %455 = load i32, ptr %5, align 4
  %456 = xor i32 %455, 1138060943
  store i32 %456, ptr %5, align 4
  %457 = xor i32 %4, 158950621
  %458 = and i32 %4, %457
  %459 = or i32 %4, %457
  %460 = xor i32 %4, %457
  %461 = add i32 %4, %457
  %462 = sub i32 %461, %460
  %463 = mul i32 %458, 2
  %464 = sub i32 %462, %463
  %465 = mul i32 %464, 106
  %466 = icmp sle i32 %465, 0
  br i1 %466, label %356, label %699

467:                                              ; preds = %16
  %468 = load i64, ptr %3, align 8
  %469 = ptrtoint ptr %0 to i64
  %470 = ptrtoint ptr %1 to i64
  %471 = add i64 %469, %469
  %472 = add i64 %471, %468
  %473 = sub i64 %472, %468
  store i64 %473, ptr %3, align 8
  br label %356

474:                                              ; preds = %30
  %475 = load i64, ptr %3, align 8
  %476 = ptrtoint ptr %0 to i64
  %477 = ptrtoint ptr %1 to i64
  %478 = mul i64 %477, %475
  %479 = or i64 %478, %475
  %480 = xor i64 %479, %475
  %481 = add i64 %480, %477
  %482 = sub i64 %481, %476
  %483 = sub i64 %482, %477
  store i64 %483, ptr %3, align 8
  br label %356

484:                                              ; preds = %45
  %485 = load i64, ptr %3, align 8
  %486 = ptrtoint ptr %0 to i64
  %487 = ptrtoint ptr %1 to i64
  %488 = or i64 %487, %486
  %489 = mul i64 %488, %486
  %490 = add i64 %489, %486
  %491 = mul i64 %490, %486
  %492 = mul i64 %491, %487
  %493 = mul i64 %492, %485
  store i64 %493, ptr %3, align 8
  br label %356

494:                                              ; preds = %65
  %495 = load i64, ptr %3, align 8
  %496 = ptrtoint ptr %0 to i64
  %497 = ptrtoint ptr %1 to i64
  %498 = or i64 %497, %495
  %499 = mul i64 %498, %495
  %500 = and i64 %499, %496
  %501 = add i64 %500, %496
  %502 = or i64 %501, %497
  %503 = mul i64 %502, %495
  store i64 %503, ptr %3, align 8
  br label %356

504:                                              ; preds = %84
  %505 = load i64, ptr %3, align 8
  %506 = ptrtoint ptr %0 to i64
  %507 = ptrtoint ptr %1 to i64
  %508 = and i64 %505, %506
  %509 = or i64 %508, %507
  %510 = add i64 %509, %506
  %511 = xor i64 %510, %507
  store i64 %511, ptr %3, align 8
  br label %356

512:                                              ; preds = %110
  %513 = load i64, ptr %3, align 8
  %514 = ptrtoint ptr %0 to i64
  %515 = ptrtoint ptr %1 to i64
  %516 = and i64 %514, %515
  %517 = mul i64 %516, %513
  %518 = mul i64 %517, %514
  %519 = xor i64 %518, %514
  %520 = or i64 %519, %514
  store i64 %520, ptr %3, align 8
  br label %356

521:                                              ; preds = %121
  %522 = load i64, ptr %3, align 8
  %523 = ptrtoint ptr %0 to i64
  %524 = ptrtoint ptr %1 to i64
  %525 = and i64 %522, %524
  %526 = mul i64 %525, %524
  %527 = xor i64 %526, %523
  %528 = add i64 %527, %524
  %529 = mul i64 %528, %524
  store i64 %529, ptr %3, align 8
  br label %356

530:                                              ; preds = %131
  %531 = load i64, ptr %3, align 8
  %532 = ptrtoint ptr %0 to i64
  %533 = ptrtoint ptr %1 to i64
  %534 = or i64 %533, %531
  %535 = xor i64 %534, %533
  %536 = add i64 %535, %532
  store i64 %536, ptr %3, align 8
  br label %356

537:                                              ; preds = %140
  %538 = load i64, ptr %3, align 8
  %539 = ptrtoint ptr %0 to i64
  %540 = ptrtoint ptr %1 to i64
  %541 = or i64 %538, %538
  %542 = add i64 %541, %539
  %543 = xor i64 %542, %540
  store i64 %543, ptr %3, align 8
  br label %356

544:                                              ; preds = %157
  %545 = load i64, ptr %3, align 8
  %546 = ptrtoint ptr %0 to i64
  %547 = ptrtoint ptr %1 to i64
  %548 = and i64 %546, %545
  %549 = sub i64 %548, %545
  %550 = and i64 %549, %546
  %551 = xor i64 %550, %545
  %552 = add i64 %551, %545
  %553 = or i64 %552, %545
  store i64 %553, ptr %3, align 8
  br label %356

554:                                              ; preds = %197
  %555 = load i64, ptr %3, align 8
  %556 = ptrtoint ptr %0 to i64
  %557 = ptrtoint ptr %1 to i64
  %558 = mul i64 %555, %555
  %559 = add i64 %558, %557
  %560 = mul i64 %559, %557
  %561 = or i64 %560, %557
  store i64 %561, ptr %3, align 8
  br label %356

562:                                              ; preds = %208
  %563 = load i64, ptr %3, align 8
  %564 = ptrtoint ptr %0 to i64
  %565 = ptrtoint ptr %1 to i64
  %566 = sub i64 %563, %565
  %567 = or i64 %566, %565
  %568 = and i64 %567, %565
  %569 = add i64 %568, %563
  %570 = mul i64 %569, %565
  %571 = xor i64 %570, %564
  store i64 %571, ptr %3, align 8
  br label %356

572:                                              ; preds = %245
  %573 = load i64, ptr %3, align 8
  %574 = ptrtoint ptr %0 to i64
  %575 = ptrtoint ptr %1 to i64
  %576 = sub i64 %575, %575
  %577 = add i64 %576, %574
  %578 = or i64 %577, %574
  %579 = or i64 %578, %575
  %580 = xor i64 %579, %575
  %581 = or i64 %580, %575
  store i64 %581, ptr %3, align 8
  br label %356

582:                                              ; preds = %258
  %583 = load i64, ptr %3, align 8
  %584 = ptrtoint ptr %0 to i64
  %585 = ptrtoint ptr %1 to i64
  %586 = mul i64 %585, %583
  %587 = xor i64 %586, %583
  %588 = and i64 %587, %583
  %589 = sub i64 %588, %584
  %590 = xor i64 %589, %584
  store i64 %590, ptr %3, align 8
  br label %356

591:                                              ; preds = %275
  %592 = load i64, ptr %3, align 8
  %593 = ptrtoint ptr %0 to i64
  %594 = ptrtoint ptr %1 to i64
  %595 = or i64 %594, %593
  %596 = add i64 %595, %594
  %597 = and i64 %596, %594
  store i64 %597, ptr %3, align 8
  br label %356

598:                                              ; preds = %289
  %599 = load i64, ptr %3, align 8
  %600 = ptrtoint ptr %0 to i64
  %601 = ptrtoint ptr %1 to i64
  %602 = mul i64 %599, %599
  %603 = and i64 %602, %600
  %604 = and i64 %603, %599
  %605 = or i64 %604, %599
  %606 = sub i64 %605, %600
  store i64 %606, ptr %3, align 8
  br label %356

607:                                              ; preds = %307
  %608 = load i64, ptr %3, align 8
  %609 = ptrtoint ptr %0 to i64
  %610 = ptrtoint ptr %1 to i64
  %611 = mul i64 %610, %610
  %612 = xor i64 %611, %608
  %613 = sub i64 %612, %608
  store i64 %613, ptr %3, align 8
  br label %356

614:                                              ; preds = %316
  %615 = load i64, ptr %3, align 8
  %616 = ptrtoint ptr %0 to i64
  %617 = ptrtoint ptr %1 to i64
  %618 = or i64 %617, %615
  %619 = xor i64 %618, %617
  %620 = add i64 %619, %615
  %621 = add i64 %620, %615
  store i64 %621, ptr %3, align 8
  br label %356

622:                                              ; preds = %337
  %623 = load i64, ptr %3, align 8
  %624 = ptrtoint ptr %0 to i64
  %625 = ptrtoint ptr %1 to i64
  %626 = add i64 %624, %623
  %627 = mul i64 %626, %625
  %628 = xor i64 %627, %623
  store i64 %628, ptr %3, align 8
  br label %356

629:                                              ; preds = %357
  %630 = load i64, ptr %3, align 8
  %631 = ptrtoint ptr %0 to i64
  %632 = ptrtoint ptr %1 to i64
  %633 = or i64 %630, %632
  %634 = sub i64 %633, %630
  %635 = sub i64 %634, %632
  %636 = add i64 %635, %632
  %637 = mul i64 %636, %630
  store i64 %637, ptr %3, align 8
  br label %12

638:                                              ; preds = %368
  %639 = load i64, ptr %3, align 8
  %640 = ptrtoint ptr %0 to i64
  %641 = ptrtoint ptr %1 to i64
  %642 = or i64 %639, %640
  %643 = and i64 %642, %640
  %644 = or i64 %643, %639
  store i64 %644, ptr %3, align 8
  br label %356

645:                                              ; preds = %380
  %646 = load i64, ptr %3, align 8
  %647 = ptrtoint ptr %0 to i64
  %648 = ptrtoint ptr %1 to i64
  %649 = mul i64 %646, %647
  %650 = add i64 %649, %648
  %651 = add i64 %650, %647
  %652 = xor i64 %651, %647
  %653 = add i64 %652, %646
  %654 = and i64 %653, %647
  store i64 %654, ptr %3, align 8
  br label %356

655:                                              ; preds = %393
  %656 = load i64, ptr %3, align 8
  %657 = ptrtoint ptr %0 to i64
  %658 = ptrtoint ptr %1 to i64
  %659 = sub i64 %657, %656
  %660 = sub i64 %659, %658
  %661 = xor i64 %660, %657
  store i64 %661, ptr %3, align 8
  br label %356

662:                                              ; preds = %405
  %663 = load i64, ptr %3, align 8
  %664 = ptrtoint ptr %0 to i64
  %665 = ptrtoint ptr %1 to i64
  %666 = sub i64 %665, %665
  %667 = mul i64 %666, %665
  %668 = or i64 %667, %664
  %669 = mul i64 %668, %664
  %670 = xor i64 %669, %663
  %671 = or i64 %670, %664
  store i64 %671, ptr %3, align 8
  br label %356

672:                                              ; preds = %418
  %673 = load i64, ptr %3, align 8
  %674 = ptrtoint ptr %0 to i64
  %675 = ptrtoint ptr %1 to i64
  %676 = or i64 %675, %675
  %677 = sub i64 %676, %674
  %678 = or i64 %677, %673
  %679 = mul i64 %678, %673
  %680 = add i64 %679, %673
  %681 = add i64 %680, %675
  store i64 %681, ptr %3, align 8
  br label %356

682:                                              ; preds = %430
  %683 = load i64, ptr %3, align 8
  %684 = ptrtoint ptr %0 to i64
  %685 = ptrtoint ptr %1 to i64
  %686 = mul i64 %685, %685
  %687 = add i64 %686, %685
  %688 = xor i64 %687, %684
  %689 = add i64 %688, %684
  %690 = mul i64 %689, %684
  store i64 %690, ptr %3, align 8
  br label %356

691:                                              ; preds = %441
  %692 = load i64, ptr %3, align 8
  %693 = ptrtoint ptr %0 to i64
  %694 = ptrtoint ptr %1 to i64
  %695 = and i64 %693, %692
  %696 = sub i64 %695, %692
  %697 = add i64 %696, %694
  %698 = xor i64 %697, %693
  store i64 %698, ptr %3, align 8
  br label %356

699:                                              ; preds = %454
  %700 = load i64, ptr %3, align 8
  %701 = ptrtoint ptr %0 to i64
  %702 = ptrtoint ptr %1 to i64
  %703 = and i64 %702, %700
  %704 = and i64 %703, %702
  %705 = xor i64 %704, %701
  %706 = sub i64 %705, %702
  %707 = mul i64 %706, %701
  %708 = and i64 %707, %701
  store i64 %708, ptr %3, align 8
  br label %356
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @parseMoneyStrict(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i64, align 8
  %10 = alloca i64, align 8
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store i32 -1177101251, ptr %5, align 4
  br label %14

14:                                               ; preds = %928, %530, %529, %2
  %15 = load i32, ptr %5, align 4
  %16 = sub i32 %15, -1191804783
  %17 = mul i32 %16, 338041691
  switch i32 %17, label %530 [
    i32 83081764, label %18
    i32 769939222, label %39
    i32 76871790, label %56
    i32 718927068, label %73
    i32 1655244085, label %99
    i32 1133345591, label %109
    i32 1256867640, label %120
    i32 397115885, label %138
    i32 720545159, label %165
    i32 1034708932, label %178
    i32 258999036, label %187
    i32 197207116, label %196
    i32 946415272, label %227
    i32 926877671, label %241
    i32 484828774, label %279
    i32 976385007, label %289
    i32 400102303, label %309
    i32 1096455915, label %330
    i32 1807711863, label %341
    i32 1041303944, label %378
    i32 1873657220, label %396
    i32 516333119, label %407
    i32 144677325, label %426
    i32 84339713, label %440
    i32 929672255, label %463
    i32 713927718, label %476
    i32 9730006, label %488
    i32 782034714, label %502
    i32 700072101, label %511
    i32 1080805753, label %527
    i32 363274252, label %541
    i32 756850492, label %554
    i32 1266775110, label %567
    i32 1723822287, label %578
    i32 1011369180, label %598
    i32 1707029922, label %611
    i32 1296666703, label %633
    i32 194089800, label %644
  ]

18:                                               ; preds = %14
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  store i64 0, ptr %9, align 8
  store i64 0, ptr %10, align 8
  store i32 0, ptr %11, align 4
  store i32 0, ptr %12, align 4
  store i32 0, ptr %13, align 4
  %19 = load ptr, ptr %7, align 8
  %20 = icmp eq ptr %19, null
  %21 = select i1 %20, i32 -1445311685, i32 -627855437
  store i32 %21, ptr %5, align 4
  %22 = xor i32 %4, -2072634267
  %23 = and i32 %4, %22
  %24 = or i32 %4, %22
  %25 = xor i32 %4, %22
  %26 = add i32 %4, %22
  %27 = sub i32 %26, %25
  %28 = mul i32 %23, 2
  %29 = sub i32 %27, %28
  %30 = mul i32 %29, 237
  %31 = xor i32 %4, 1612963613
  %32 = and i32 %4, %31
  %33 = or i32 %4, %31
  %34 = xor i32 %4, %31
  %35 = sub i32 %33, %34
  %36 = sub i32 %35, %32
  %37 = mul i32 %36, 35
  %38 = icmp eq i32 %30, %37
  br i1 %38, label %529, label %664

39:                                               ; preds = %14
  %40 = load ptr, ptr %7, align 8
  %41 = getelementptr inbounds i8, ptr %40, i64 0
  %42 = load i8, ptr %41, align 1
  %43 = sext i8 %42 to i32
  %44 = icmp eq i32 %43, 0
  %45 = select i1 %44, i32 -1445311685, i32 -1321115163
  store i32 %45, ptr %5, align 4
  %46 = xor i32 %4, -1648339525
  %47 = and i32 %4, %46
  %48 = or i32 %4, %46
  %49 = xor i32 %4, %46
  %50 = add i32 %4, %46
  %51 = sub i32 %50, %49
  %52 = mul i32 %47, 2
  %53 = sub i32 %51, %52
  %54 = mul i32 %53, 25
  %55 = icmp sgt i32 %54, 0
  br i1 %55, label %672, label %529

56:                                               ; preds = %14
  store i32 0, ptr %6, align 4
  store i32 -839431348, ptr %5, align 4
  %57 = xor i32 %4, -471908397
  %58 = and i32 %4, %57
  %59 = or i32 %4, %57
  %60 = xor i32 %4, %57
  %61 = sub i32 %59, %60
  %62 = sub i32 %61, %58
  %63 = mul i32 %62, 28
  %64 = xor i32 %4, -482857477
  %65 = and i32 %4, %64
  %66 = or i32 %4, %64
  %67 = xor i32 %4, %64
  %68 = add i32 %65, %66
  %69 = sub i32 %68, %4
  %70 = sub i32 %69, %64
  %71 = mul i32 %70, 52
  %72 = icmp ne i32 %63, %71
  br i1 %72, label %679, label %529

73:                                               ; preds = %14
  %74 = load ptr, ptr %7, align 8
  %75 = getelementptr inbounds i8, ptr %74, i64 0
  %76 = load i8, ptr %75, align 1
  %77 = sext i8 %76 to i32
  %78 = icmp eq i32 %77, 45
  %79 = select i1 %78, i32 1472599872, i32 -888892698
  store i32 %79, ptr %5, align 4
  %80 = xor i32 %4, 1605897535
  %81 = and i32 %4, %80
  %82 = or i32 %4, %80
  %83 = xor i32 %4, %80
  %84 = add i32 %4, %80
  %85 = sub i32 %84, %83
  %86 = mul i32 %81, 2
  %87 = sub i32 %85, %86
  %88 = mul i32 %87, 135
  %89 = xor i32 %4, 297366837
  %90 = and i32 %4, %89
  %91 = or i32 %4, %89
  %92 = xor i32 %4, %89
  %93 = mul i32 %91, 2
  %94 = sub i32 %93, %92
  %95 = sub i32 %94, %4
  %96 = sub i32 %95, %89
  %97 = mul i32 %96, 205
  %98 = icmp eq i32 %88, %97
  br i1 %98, label %529, label %689

99:                                               ; preds = %14
  store i32 0, ptr %6, align 4
  store i32 -839431348, ptr %5, align 4
  %100 = xor i32 %4, 1896125757
  %101 = and i32 %4, %100
  %102 = or i32 %4, %100
  %103 = xor i32 %4, %100
  %104 = add i32 %101, %102
  %105 = sub i32 %104, %4
  %106 = sub i32 %105, %100
  %107 = mul i32 %106, 120
  %108 = icmp uge i32 %107, 0
  br i1 %108, label %529, label %696

109:                                              ; preds = %14
  store i32 -1672129607, ptr %5, align 4
  %110 = xor i32 %4, 1616799523
  %111 = and i32 %4, %110
  %112 = or i32 %4, %110
  %113 = xor i32 %4, %110
  %114 = add i32 %4, %110
  %115 = sub i32 %114, %113
  %116 = mul i32 %111, 2
  %117 = sub i32 %115, %116
  %118 = mul i32 %117, 156
  %119 = icmp slt i32 %118, 0
  br i1 %119, label %706, label %529

120:                                              ; preds = %14
  %121 = load ptr, ptr %7, align 8
  %122 = load i32, ptr %11, align 4
  %123 = sext i32 %122 to i64
  %124 = getelementptr inbounds i8, ptr %121, i64 %123
  %125 = load i8, ptr %124, align 1
  %126 = icmp ne i8 %125, 0
  %127 = select i1 %126, i32 -2085420312, i32 -890294136
  store i32 %127, ptr %5, align 4
  %128 = xor i32 %4, -1274626899
  %129 = and i32 %4, %128
  %130 = or i32 %4, %128
  %131 = xor i32 %4, %128
  %132 = add i32 %4, %128
  %133 = sub i32 %132, %131
  %134 = mul i32 %129, 2
  %135 = sub i32 %133, %134
  %136 = mul i32 %135, 212
  %137 = icmp uge i32 %136, 0
  br i1 %137, label %529, label %713

138:                                              ; preds = %14
  %139 = load ptr, ptr %7, align 8
  %140 = load i32, ptr %11, align 4
  %141 = sext i32 %140 to i64
  %142 = getelementptr inbounds i8, ptr %139, i64 %141
  %143 = load i8, ptr %142, align 1
  %144 = sext i8 %143 to i32
  %145 = icmp eq i32 %144, 46
  %146 = select i1 %145, i32 -361811242, i32 -1233798347
  store i32 %146, ptr %5, align 4
  %147 = xor i32 %4, -1230019707
  %148 = and i32 %4, %147
  %149 = or i32 %4, %147
  %150 = xor i32 %4, %147
  %151 = add i32 %4, %147
  %152 = sub i32 %151, %150
  %153 = mul i32 %148, 2
  %154 = sub i32 %152, %153
  %155 = mul i32 %154, 195
  %156 = xor i32 %4, 2063527625
  %157 = and i32 %4, %156
  %158 = or i32 %4, %156
  %159 = xor i32 %4, %156
  %160 = add i32 %157, %158
  %161 = sub i32 %160, %4
  %162 = sub i32 %161, %156
  %163 = mul i32 %162, 157
  %164 = icmp eq i32 %155, %163
  br i1 %164, label %529, label %721

165:                                              ; preds = %14
  %166 = load i32, ptr %12, align 4
  %167 = icmp ne i32 %166, 0
  %168 = select i1 %167, i32 1784379165, i32 839550533
  store i32 %168, ptr %5, align 4
  %169 = xor i32 %4, 2058413067
  %170 = and i32 %4, %169
  %171 = or i32 %4, %169
  %172 = xor i32 %4, %169
  %173 = add i32 %170, %171
  %174 = sub i32 %173, %4
  %175 = sub i32 %174, %169
  %176 = mul i32 %175, 195
  %177 = icmp ugt i32 %176, 0
  br i1 %177, label %729, label %529

178:                                              ; preds = %14
  store i32 0, ptr %6, align 4
  store i32 -839431348, ptr %5, align 4
  %179 = xor i32 %4, 156504839
  %180 = and i32 %4, %179
  %181 = or i32 %4, %179
  %182 = xor i32 %4, %179
  %183 = sub i32 %181, %182
  %184 = sub i32 %183, %180
  %185 = mul i32 %184, 19
  %186 = icmp slt i32 %185, 1
  br i1 %186, label %529, label %738

187:                                              ; preds = %14
  store i32 1, ptr %12, align 4
  store i32 1955943038, ptr %5, align 4
  %188 = xor i32 %4, 724773221
  %189 = and i32 %4, %188
  %190 = or i32 %4, %188
  %191 = xor i32 %4, %188
  %192 = sub i32 %190, %191
  %193 = sub i32 %192, %189
  %194 = mul i32 %193, 30
  %195 = icmp sgt i32 %194, 0
  br i1 %195, label %748, label %529

196:                                              ; preds = %14
  %197 = call ptr @__ctype_b_loc() #7
  %198 = load ptr, ptr %197, align 8
  %199 = load ptr, ptr %7, align 8
  %200 = load i32, ptr %11, align 4
  %201 = sext i32 %200 to i64
  %202 = getelementptr inbounds i8, ptr %199, i64 %201
  %203 = load i8, ptr %202, align 1
  %204 = zext i8 %203 to i32
  %205 = sext i32 %204 to i64
  %206 = getelementptr inbounds i16, ptr %198, i64 %205
  %207 = load i16, ptr %206, align 2
  %208 = zext i16 %207 to i32
  %209 = load i32, ptr %5, align 4
  %210 = xor i32 %209, -1233800395
  %211 = add i32 %208, %210
  %212 = load i32, ptr %5, align 4
  %213 = xor i32 %212, -1233800395
  %214 = or i32 %208, %213
  %215 = sub i32 %211, %214
  %216 = icmp ne i32 %215, 0
  %217 = select i1 %216, i32 835697929, i32 -390716323
  store i32 %217, ptr %5, align 4
  %218 = xor i32 %4, 1590147903
  %219 = and i32 %4, %218
  %220 = or i32 %4, %218
  %221 = xor i32 %4, %218
  %222 = add i32 %219, %220
  %223 = sub i32 %222, %4
  %224 = sub i32 %223, %218
  %225 = mul i32 %224, 37
  %226 = icmp slt i32 %225, 0
  br i1 %226, label %755, label %529

227:                                              ; preds = %14
  %228 = load i32, ptr %12, align 4
  %229 = icmp ne i32 %228, 0
  %230 = select i1 %229, i32 -1546481506, i32 1926678518
  store i32 %230, ptr %5, align 4
  %231 = xor i32 %4, -2108188159
  %232 = and i32 %4, %231
  %233 = or i32 %4, %231
  %234 = xor i32 %4, %231
  %235 = mul i32 %233, 2
  %236 = sub i32 %235, %234
  %237 = sub i32 %236, %4
  %238 = sub i32 %237, %231
  %239 = mul i32 %238, 76
  %240 = icmp uge i32 %239, 0
  br i1 %240, label %529, label %765

241:                                              ; preds = %14
  %242 = load i64, ptr %9, align 8
  %243 = mul nsw i64 %242, 10
  %244 = load ptr, ptr %7, align 8
  %245 = load i32, ptr %11, align 4
  %246 = sext i32 %245 to i64
  %247 = getelementptr inbounds i8, ptr %244, i64 %246
  %248 = load i8, ptr %247, align 1
  %249 = sext i8 %248 to i32
  %250 = load i32, ptr %5, align 4
  %251 = xor i32 %250, 1926678519
  %252 = add i32 %249, %251
  %253 = load i32, ptr %5, align 4
  %254 = xor i32 %253, 1926678471
  %255 = mul i32 %249, %254
  %256 = load i32, ptr %5, align 4
  %257 = xor i32 %256, 1926678470
  %258 = mul i32 %257, %252
  %259 = sub i32 %255, %258
  %260 = sext i32 %259 to i64
  %261 = add i64 %260, 1
  %262 = sub i64 %243, 1
  %263 = mul i64 %243, %261
  %264 = mul i64 %260, %262
  %265 = sub i64 %263, %264
  store i64 %265, ptr %9, align 8
  %266 = load i64, ptr %9, align 8
  %267 = icmp sgt i64 %266, 9000000000000
  %268 = select i1 %267, i32 -1586393437, i32 57520782
  store i32 %268, ptr %5, align 4
  %269 = xor i32 %4, 1218957939
  %270 = and i32 %4, %269
  %271 = or i32 %4, %269
  %272 = xor i32 %4, %269
  %273 = add i32 %4, %269
  %274 = sub i32 %273, %272
  %275 = mul i32 %270, 2
  %276 = sub i32 %274, %275
  %277 = mul i32 %276, 12
  %278 = icmp slt i32 %277, 0
  br i1 %278, label %775, label %529

279:                                              ; preds = %14
  store i32 0, ptr %6, align 4
  store i32 -839431348, ptr %5, align 4
  %280 = xor i32 %4, -1610912383
  %281 = and i32 %4, %280
  %282 = or i32 %4, %280
  %283 = xor i32 %4, %280
  %284 = add i32 %281, %282
  %285 = sub i32 %284, %4
  %286 = sub i32 %285, %280
  %287 = mul i32 %286, 190
  %288 = icmp slt i32 %287, 1
  br i1 %288, label %529, label %785

289:                                              ; preds = %14
  store i32 -990889047, ptr %5, align 4
  %290 = xor i32 %4, -227624557
  %291 = and i32 %4, %290
  %292 = or i32 %4, %290
  %293 = xor i32 %4, %290
  %294 = mul i32 %292, 2
  %295 = sub i32 %294, %293
  %296 = sub i32 %295, %4
  %297 = sub i32 %296, %290
  %298 = mul i32 %297, 231
  %299 = xor i32 %4, -156942275
  %300 = and i32 %4, %299
  %301 = or i32 %4, %299
  %302 = xor i32 %4, %299
  %303 = mul i32 %301, 2
  %304 = sub i32 %303, %302
  %305 = sub i32 %304, %4
  %306 = sub i32 %305, %299
  %307 = mul i32 %306, 207
  %308 = icmp eq i32 %298, %307
  br i1 %308, label %529, label %795

309:                                              ; preds = %14
  %310 = load i32, ptr %13, align 4
  %311 = icmp sge i32 %310, 2
  %312 = select i1 %311, i32 1556355138, i32 -751288154
  store i32 %312, ptr %5, align 4
  %313 = xor i32 %4, -143750451
  %314 = and i32 %4, %313
  %315 = or i32 %4, %313
  %316 = xor i32 %4, %313
  %317 = sub i32 %315, %316
  %318 = sub i32 %317, %314
  %319 = mul i32 %318, 110
  %320 = xor i32 %4, 1915822989
  %321 = and i32 %4, %320
  %322 = or i32 %4, %320
  %323 = xor i32 %4, %320
  %324 = add i32 %4, %320
  %325 = sub i32 %324, %323
  %326 = mul i32 %321, 2
  %327 = sub i32 %325, %326
  %328 = mul i32 %327, 210
  %329 = icmp eq i32 %319, %328
  br i1 %329, label %529, label %805

330:                                              ; preds = %14
  store i32 0, ptr %6, align 4
  store i32 -839431348, ptr %5, align 4
  %331 = xor i32 %4, -901950219
  %332 = and i32 %4, %331
  %333 = or i32 %4, %331
  %334 = xor i32 %4, %331
  %335 = mul i32 %333, 2
  %336 = sub i32 %335, %334
  %337 = sub i32 %336, %4
  %338 = sub i32 %337, %331
  %339 = mul i32 %338, 175
  %340 = icmp sle i32 %339, 0
  br i1 %340, label %529, label %815

341:                                              ; preds = %14
  %342 = load i64, ptr %10, align 8
  %343 = mul nsw i64 %342, 10
  %344 = load ptr, ptr %7, align 8
  %345 = load i32, ptr %11, align 4
  %346 = sext i32 %345 to i64
  %347 = getelementptr inbounds i8, ptr %344, i64 %346
  %348 = load i8, ptr %347, align 1
  %349 = sext i8 %348 to i32
  %350 = load i32, ptr %5, align 4
  %351 = xor i32 %350, 751288169
  %352 = add i32 %349, %351
  %353 = load i32, ptr %5, align 4
  %354 = xor i32 %353, -751288153
  %355 = add i32 %352, %354
  %356 = sext i32 %355 to i64
  %357 = xor i64 %343, %356
  %358 = and i64 %343, %356
  %359 = add i64 %358, %358
  %360 = add i64 %357, %359
  store i64 %360, ptr %10, align 8
  %361 = load i32, ptr %13, align 4
  %362 = load i32, ptr %5, align 4
  %363 = xor i32 %362, -751288153
  %364 = xor i32 %361, %363
  %365 = load i32, ptr %5, align 4
  %366 = xor i32 %365, -751288153
  %367 = and i32 %361, %366
  %368 = add i32 %367, %367
  %369 = add i32 %364, %368
  store i32 %369, ptr %13, align 4
  store i32 -990889047, ptr %5, align 4
  %370 = xor i32 %4, -1786138033
  %371 = and i32 %4, %370
  %372 = or i32 %4, %370
  %373 = xor i32 %4, %370
  %374 = sub i32 %372, %373
  %375 = sub i32 %374, %371
  %376 = mul i32 %375, 181
  %377 = icmp slt i32 %376, 1
  br i1 %377, label %529, label %824

378:                                              ; preds = %14
  store i32 1955943038, ptr %5, align 4
  %379 = xor i32 %4, 1878457479
  %380 = and i32 %4, %379
  %381 = or i32 %4, %379
  %382 = xor i32 %4, %379
  %383 = sub i32 %381, %382
  %384 = sub i32 %383, %380
  %385 = mul i32 %384, 136
  %386 = xor i32 %4, 400596373
  %387 = and i32 %4, %386
  %388 = or i32 %4, %386
  %389 = xor i32 %4, %386
  %390 = add i32 %4, %386
  %391 = sub i32 %390, %389
  %392 = mul i32 %387, 2
  %393 = sub i32 %391, %392
  %394 = mul i32 %393, 70
  %395 = icmp eq i32 %385, %394
  br i1 %395, label %529, label %833

396:                                              ; preds = %14
  store i32 0, ptr %6, align 4
  store i32 -839431348, ptr %5, align 4
  %397 = xor i32 %4, 678300733
  %398 = and i32 %4, %397
  %399 = or i32 %4, %397
  %400 = xor i32 %4, %397
  %401 = mul i32 %399, 2
  %402 = sub i32 %401, %400
  %403 = sub i32 %402, %4
  %404 = sub i32 %403, %397
  %405 = mul i32 %404, 173
  %406 = icmp ugt i32 %405, 0
  br i1 %406, label %843, label %529

407:                                              ; preds = %14
  %408 = load i32, ptr %11, align 4
  %409 = load i32, ptr %5, align 4
  %410 = xor i32 %409, 1955943039
  %411 = or i32 %408, %410
  %412 = load i32, ptr %5, align 4
  %413 = xor i32 %412, 1955943039
  %414 = and i32 %408, %413
  %415 = add i32 %411, %414
  store i32 %415, ptr %11, align 4
  store i32 -1672129607, ptr %5, align 4
  %416 = xor i32 %4, -2011839959
  %417 = and i32 %4, %416
  %418 = or i32 %4, %416
  %419 = xor i32 %4, %416
  %420 = mul i32 %418, 2
  %421 = sub i32 %420, %419
  %422 = sub i32 %421, %4
  %423 = sub i32 %422, %416
  %424 = mul i32 %423, 128
  %425 = icmp ugt i32 %424, 0
  br i1 %425, label %853, label %529

426:                                              ; preds = %14
  %427 = load i32, ptr %12, align 4
  %428 = icmp ne i32 %427, 0
  %429 = select i1 %428, i32 -922771100, i32 1446677475
  store i32 %429, ptr %5, align 4
  %430 = xor i32 %4, 77753429
  %431 = and i32 %4, %430
  %432 = or i32 %4, %430
  %433 = xor i32 %4, %430
  %434 = mul i32 %432, 2
  %435 = sub i32 %434, %433
  %436 = sub i32 %435, %4
  %437 = sub i32 %436, %430
  %438 = mul i32 %437, 214
  %439 = icmp slt i32 %438, 0
  br i1 %439, label %862, label %529

440:                                              ; preds = %14
  %441 = load i32, ptr %13, align 4
  %442 = icmp eq i32 %441, 1
  %443 = select i1 %442, i32 1468128382, i32 1446677475
  store i32 %443, ptr %5, align 4
  %444 = xor i32 %4, -25423407
  %445 = and i32 %4, %444
  %446 = or i32 %4, %444
  %447 = xor i32 %4, %444
  %448 = mul i32 %446, 2
  %449 = sub i32 %448, %447
  %450 = sub i32 %449, %4
  %451 = sub i32 %450, %444
  %452 = mul i32 %451, 125
  %453 = xor i32 %4, -1000351895
  %454 = and i32 %4, %453
  %455 = or i32 %4, %453
  %456 = xor i32 %4, %453
  %457 = mul i32 %455, 2
  %458 = sub i32 %457, %456
  %459 = sub i32 %458, %4
  %460 = sub i32 %459, %453
  %461 = mul i32 %460, 196
  %462 = icmp ne i32 %452, %461
  br i1 %462, label %872, label %529

463:                                              ; preds = %14
  %464 = load i64, ptr %10, align 8
  %465 = mul nsw i64 %464, 10
  store i64 %465, ptr %10, align 8
  store i32 1446677475, ptr %5, align 4
  %466 = xor i32 %4, 635303283
  %467 = and i32 %4, %466
  %468 = or i32 %4, %466
  %469 = xor i32 %4, %466
  %470 = mul i32 %468, 2
  %471 = sub i32 %470, %469
  %472 = sub i32 %471, %4
  %473 = sub i32 %472, %466
  %474 = mul i32 %473, 69
  %475 = icmp ugt i32 %474, 0
  br i1 %475, label %879, label %529

476:                                              ; preds = %14
  %477 = load i32, ptr %12, align 4
  %478 = icmp ne i32 %477, 0
  %479 = select i1 %478, i32 -122442253, i32 -520989552
  store i32 %479, ptr %5, align 4
  %480 = xor i32 %4, 664660565
  %481 = and i32 %4, %480
  %482 = or i32 %4, %480
  %483 = xor i32 %4, %480
  %484 = sub i32 %482, %483
  %485 = sub i32 %484, %481
  %486 = mul i32 %485, 67
  %487 = icmp ne i32 %486, 0
  br i1 %487, label %889, label %529

488:                                              ; preds = %14
  %489 = load i32, ptr %13, align 4
  %490 = icmp eq i32 %489, 0
  %491 = select i1 %490, i32 948228863, i32 -520989552
  store i32 %491, ptr %5, align 4
  %492 = xor i32 %4, 835251529
  %493 = and i32 %4, %492
  %494 = or i32 %4, %492
  %495 = xor i32 %4, %492
  %496 = add i32 %4, %492
  %497 = sub i32 %496, %495
  %498 = mul i32 %493, 2
  %499 = sub i32 %497, %498
  %500 = mul i32 %499, 24
  %501 = icmp slt i32 %500, 1
  br i1 %501, label %529, label %899

502:                                              ; preds = %14
  store i64 0, ptr %10, align 8
  store i32 -520989552, ptr %5, align 4
  %503 = xor i32 %4, 1748714027
  %504 = and i32 %4, %503
  %505 = or i32 %4, %503
  %506 = xor i32 %4, %503
  %507 = sub i32 %505, %506
  %508 = sub i32 %507, %504
  %509 = mul i32 %508, 113
  %510 = icmp ugt i32 %509, 0
  br i1 %510, label %909, label %529

511:                                              ; preds = %14
  %512 = load i64, ptr %9, align 8
  %513 = mul nsw i64 %512, 100
  %514 = load i64, ptr %10, align 8
  %515 = or i64 %513, %514
  %516 = and i64 %513, %514
  %517 = add i64 %515, %516
  %518 = load ptr, ptr %8, align 8
  store i64 %517, ptr %518, align 8
  store i32 1, ptr %6, align 4
  store i32 -839431348, ptr %5, align 4
  %519 = xor i32 %4, 2112660677
  %520 = and i32 %4, %519
  %521 = or i32 %4, %519
  %522 = xor i32 %4, %519
  %523 = sub i32 %521, %522
  %524 = sub i32 %523, %520
  %525 = mul i32 %524, 85
  %526 = icmp sle i32 %525, 0
  br i1 %526, label %529, label %919

527:                                              ; preds = %14
  %528 = load i32, ptr %6, align 4
  ret i32 %528

529:                                              ; preds = %995, %987, %977, %969, %961, %953, %943, %936, %919, %909, %899, %889, %879, %872, %862, %853, %843, %833, %824, %815, %805, %795, %785, %775, %765, %755, %748, %738, %729, %721, %713, %706, %696, %689, %679, %672, %664, %644, %633, %611, %598, %578, %567, %554, %541, %511, %502, %488, %476, %463, %440, %426, %407, %396, %378, %341, %330, %309, %289, %279, %241, %227, %196, %187, %178, %165, %138, %120, %109, %99, %73, %56, %39, %18
  br label %14

530:                                              ; preds = %14
  store i32 -1177101251, ptr %5, align 4
  call void asm sideeffect "", ""()
  %531 = xor i32 %4, -1755066835
  %532 = and i32 %4, %531
  %533 = or i32 %4, %531
  %534 = xor i32 %4, %531
  %535 = add i32 %4, %531
  %536 = sub i32 %535, %534
  %537 = mul i32 %532, 2
  %538 = sub i32 %536, %537
  %539 = mul i32 %538, 114
  %540 = icmp sgt i32 %539, 0
  br i1 %540, label %928, label %14

541:                                              ; preds = %14
  %542 = load i32, ptr %5, align 4
  %543 = xor i32 %542, -2133114926
  store i32 %543, ptr %5, align 4
  %544 = xor i32 %4, 330322323
  %545 = and i32 %4, %544
  %546 = or i32 %4, %544
  %547 = xor i32 %4, %544
  %548 = mul i32 %546, 2
  %549 = sub i32 %548, %547
  %550 = sub i32 %549, %4
  %551 = sub i32 %550, %544
  %552 = mul i32 %551, 205
  %553 = icmp slt i32 %552, 0
  br i1 %553, label %936, label %529

554:                                              ; preds = %14
  %555 = load i32, ptr %5, align 4
  %556 = xor i32 %555, 527195039
  store i32 %556, ptr %5, align 4
  %557 = xor i32 %4, -650334125
  %558 = and i32 %4, %557
  %559 = or i32 %4, %557
  %560 = xor i32 %4, %557
  %561 = add i32 %4, %557
  %562 = sub i32 %561, %560
  %563 = mul i32 %558, 2
  %564 = sub i32 %562, %563
  %565 = mul i32 %564, 14
  %566 = icmp ne i32 %565, 0
  br i1 %566, label %943, label %529

567:                                              ; preds = %14
  %568 = load i32, ptr %5, align 4
  %569 = xor i32 %568, -581873119
  store i32 %569, ptr %5, align 4
  %570 = xor i32 %4, 1662529241
  %571 = and i32 %4, %570
  %572 = or i32 %4, %570
  %573 = xor i32 %4, %570
  %574 = sub i32 %572, %573
  %575 = sub i32 %574, %571
  %576 = mul i32 %575, 131
  %577 = icmp eq i32 %576, 0
  br i1 %577, label %529, label %953

578:                                              ; preds = %14
  %579 = load i32, ptr %5, align 4
  %580 = xor i32 %579, -256122231
  store i32 %580, ptr %5, align 4
  %581 = xor i32 %4, -1767977311
  %582 = and i32 %4, %581
  %583 = or i32 %4, %581
  %584 = xor i32 %4, %581
  %585 = add i32 %4, %581
  %586 = sub i32 %585, %584
  %587 = mul i32 %582, 2
  %588 = sub i32 %586, %587
  %589 = mul i32 %588, 64
  %590 = xor i32 %4, 78434833
  %591 = and i32 %4, %590
  %592 = or i32 %4, %590
  %593 = xor i32 %4, %590
  %594 = sub i32 %592, %593
  %595 = sub i32 %594, %591
  %596 = mul i32 %595, 112
  %597 = icmp eq i32 %589, %596
  br i1 %597, label %529, label %961

598:                                              ; preds = %14
  %599 = load i32, ptr %5, align 4
  %600 = xor i32 %599, -123424598
  store i32 %600, ptr %5, align 4
  %601 = xor i32 %4, 2107439427
  %602 = and i32 %4, %601
  %603 = or i32 %4, %601
  %604 = xor i32 %4, %601
  %605 = add i32 %4, %601
  %606 = sub i32 %605, %604
  %607 = mul i32 %602, 2
  %608 = sub i32 %606, %607
  %609 = mul i32 %608, 192
  %610 = icmp uge i32 %609, 0
  br i1 %610, label %529, label %969

611:                                              ; preds = %14
  %612 = load i32, ptr %5, align 4
  %613 = xor i32 %612, 234285638
  store i32 %613, ptr %5, align 4
  %614 = xor i32 %4, -1584847997
  %615 = and i32 %4, %614
  %616 = or i32 %4, %614
  %617 = xor i32 %4, %614
  %618 = add i32 %4, %614
  %619 = sub i32 %618, %617
  %620 = mul i32 %615, 2
  %621 = sub i32 %619, %620
  %622 = mul i32 %621, 178
  %623 = xor i32 %4, 1210617319
  %624 = and i32 %4, %623
  %625 = or i32 %4, %623
  %626 = xor i32 %4, %623
  %627 = add i32 %4, %623
  %628 = sub i32 %627, %626
  %629 = mul i32 %624, 2
  %630 = sub i32 %628, %629
  %631 = mul i32 %630, 86
  %632 = icmp ne i32 %622, %631
  br i1 %632, label %977, label %529

633:                                              ; preds = %14
  %634 = load i32, ptr %5, align 4
  %635 = xor i32 %634, -1365851959
  store i32 %635, ptr %5, align 4
  %636 = xor i32 %4, -1968467085
  %637 = and i32 %4, %636
  %638 = or i32 %4, %636
  %639 = xor i32 %4, %636
  %640 = sub i32 %638, %639
  %641 = sub i32 %640, %637
  %642 = mul i32 %641, 132
  %643 = icmp sgt i32 %642, 0
  br i1 %643, label %987, label %529

644:                                              ; preds = %14
  %645 = load i32, ptr %5, align 4
  %646 = xor i32 %645, -1088726609
  store i32 %646, ptr %5, align 4
  %647 = xor i32 %4, 51296775
  %648 = and i32 %4, %647
  %649 = or i32 %4, %647
  %650 = xor i32 %4, %647
  %651 = sub i32 %649, %650
  %652 = sub i32 %651, %648
  %653 = mul i32 %652, 102
  %654 = xor i32 %4, -661333051
  %655 = and i32 %4, %654
  %656 = or i32 %4, %654
  %657 = xor i32 %4, %654
  %658 = mul i32 %656, 2
  %659 = sub i32 %658, %657
  %660 = sub i32 %659, %4
  %661 = sub i32 %660, %654
  %662 = mul i32 %661, 94
  %663 = icmp ne i32 %653, %662
  br i1 %663, label %995, label %529

664:                                              ; preds = %18
  %665 = load i64, ptr %3, align 8
  %666 = ptrtoint ptr %0 to i64
  %667 = ptrtoint ptr %1 to i64
  %668 = add i64 %665, %665
  %669 = mul i64 %668, %665
  %670 = add i64 %669, %667
  %671 = sub i64 %670, %667
  store i64 %671, ptr %3, align 8
  br label %529

672:                                              ; preds = %39
  %673 = load i64, ptr %3, align 8
  %674 = ptrtoint ptr %0 to i64
  %675 = ptrtoint ptr %1 to i64
  %676 = xor i64 %675, %674
  %677 = mul i64 %676, %674
  %678 = or i64 %677, %675
  store i64 %678, ptr %3, align 8
  br label %529

679:                                              ; preds = %56
  %680 = load i64, ptr %3, align 8
  %681 = ptrtoint ptr %0 to i64
  %682 = ptrtoint ptr %1 to i64
  %683 = mul i64 %680, %680
  %684 = or i64 %683, %680
  %685 = and i64 %684, %681
  %686 = mul i64 %685, %681
  %687 = and i64 %686, %682
  %688 = sub i64 %687, %680
  store i64 %688, ptr %3, align 8
  br label %529

689:                                              ; preds = %73
  %690 = load i64, ptr %3, align 8
  %691 = ptrtoint ptr %0 to i64
  %692 = ptrtoint ptr %1 to i64
  %693 = or i64 %692, %692
  %694 = add i64 %693, %691
  %695 = xor i64 %694, %690
  store i64 %695, ptr %3, align 8
  br label %529

696:                                              ; preds = %99
  %697 = load i64, ptr %3, align 8
  %698 = ptrtoint ptr %0 to i64
  %699 = ptrtoint ptr %1 to i64
  %700 = xor i64 %697, %697
  %701 = mul i64 %700, %698
  %702 = xor i64 %701, %699
  %703 = add i64 %702, %698
  %704 = xor i64 %703, %697
  %705 = xor i64 %704, %697
  store i64 %705, ptr %3, align 8
  br label %529

706:                                              ; preds = %109
  %707 = load i64, ptr %3, align 8
  %708 = ptrtoint ptr %0 to i64
  %709 = ptrtoint ptr %1 to i64
  %710 = xor i64 %707, %709
  %711 = sub i64 %710, %707
  %712 = sub i64 %711, %709
  store i64 %712, ptr %3, align 8
  br label %529

713:                                              ; preds = %120
  %714 = load i64, ptr %3, align 8
  %715 = ptrtoint ptr %0 to i64
  %716 = ptrtoint ptr %1 to i64
  %717 = mul i64 %715, %716
  %718 = sub i64 %717, %715
  %719 = and i64 %718, %715
  %720 = add i64 %719, %714
  store i64 %720, ptr %3, align 8
  br label %529

721:                                              ; preds = %138
  %722 = load i64, ptr %3, align 8
  %723 = ptrtoint ptr %0 to i64
  %724 = ptrtoint ptr %1 to i64
  %725 = add i64 %723, %723
  %726 = xor i64 %725, %722
  %727 = or i64 %726, %722
  %728 = or i64 %727, %722
  store i64 %728, ptr %3, align 8
  br label %529

729:                                              ; preds = %165
  %730 = load i64, ptr %3, align 8
  %731 = ptrtoint ptr %0 to i64
  %732 = ptrtoint ptr %1 to i64
  %733 = sub i64 %731, %731
  %734 = sub i64 %733, %731
  %735 = xor i64 %734, %731
  %736 = add i64 %735, %732
  %737 = and i64 %736, %730
  store i64 %737, ptr %3, align 8
  br label %529

738:                                              ; preds = %178
  %739 = load i64, ptr %3, align 8
  %740 = ptrtoint ptr %0 to i64
  %741 = ptrtoint ptr %1 to i64
  %742 = add i64 %741, %740
  %743 = or i64 %742, %741
  %744 = mul i64 %743, %740
  %745 = and i64 %744, %740
  %746 = add i64 %745, %740
  %747 = mul i64 %746, %741
  store i64 %747, ptr %3, align 8
  br label %529

748:                                              ; preds = %187
  %749 = load i64, ptr %3, align 8
  %750 = ptrtoint ptr %0 to i64
  %751 = ptrtoint ptr %1 to i64
  %752 = sub i64 %749, %751
  %753 = mul i64 %752, %750
  %754 = add i64 %753, %751
  store i64 %754, ptr %3, align 8
  br label %529

755:                                              ; preds = %196
  %756 = load i64, ptr %3, align 8
  %757 = ptrtoint ptr %0 to i64
  %758 = ptrtoint ptr %1 to i64
  %759 = sub i64 %757, %757
  %760 = mul i64 %759, %758
  %761 = sub i64 %760, %758
  %762 = xor i64 %761, %757
  %763 = sub i64 %762, %757
  %764 = add i64 %763, %758
  store i64 %764, ptr %3, align 8
  br label %529

765:                                              ; preds = %227
  %766 = load i64, ptr %3, align 8
  %767 = ptrtoint ptr %0 to i64
  %768 = ptrtoint ptr %1 to i64
  %769 = mul i64 %766, %766
  %770 = or i64 %769, %767
  %771 = xor i64 %770, %767
  %772 = or i64 %771, %766
  %773 = mul i64 %772, %766
  %774 = sub i64 %773, %766
  store i64 %774, ptr %3, align 8
  br label %529

775:                                              ; preds = %241
  %776 = load i64, ptr %3, align 8
  %777 = ptrtoint ptr %0 to i64
  %778 = ptrtoint ptr %1 to i64
  %779 = or i64 %776, %776
  %780 = and i64 %779, %778
  %781 = and i64 %780, %778
  %782 = xor i64 %781, %776
  %783 = sub i64 %782, %778
  %784 = and i64 %783, %776
  store i64 %784, ptr %3, align 8
  br label %529

785:                                              ; preds = %279
  %786 = load i64, ptr %3, align 8
  %787 = ptrtoint ptr %0 to i64
  %788 = ptrtoint ptr %1 to i64
  %789 = xor i64 %786, %786
  %790 = add i64 %789, %786
  %791 = add i64 %790, %787
  %792 = or i64 %791, %787
  %793 = xor i64 %792, %788
  %794 = add i64 %793, %786
  store i64 %794, ptr %3, align 8
  br label %529

795:                                              ; preds = %289
  %796 = load i64, ptr %3, align 8
  %797 = ptrtoint ptr %0 to i64
  %798 = ptrtoint ptr %1 to i64
  %799 = add i64 %798, %797
  %800 = sub i64 %799, %796
  %801 = xor i64 %800, %797
  %802 = mul i64 %801, %796
  %803 = mul i64 %802, %796
  %804 = and i64 %803, %796
  store i64 %804, ptr %3, align 8
  br label %529

805:                                              ; preds = %309
  %806 = load i64, ptr %3, align 8
  %807 = ptrtoint ptr %0 to i64
  %808 = ptrtoint ptr %1 to i64
  %809 = and i64 %807, %806
  %810 = sub i64 %809, %808
  %811 = add i64 %810, %807
  %812 = or i64 %811, %807
  %813 = and i64 %812, %806
  %814 = xor i64 %813, %807
  store i64 %814, ptr %3, align 8
  br label %529

815:                                              ; preds = %330
  %816 = load i64, ptr %3, align 8
  %817 = ptrtoint ptr %0 to i64
  %818 = ptrtoint ptr %1 to i64
  %819 = xor i64 %816, %817
  %820 = and i64 %819, %818
  %821 = add i64 %820, %817
  %822 = mul i64 %821, %817
  %823 = or i64 %822, %818
  store i64 %823, ptr %3, align 8
  br label %529

824:                                              ; preds = %341
  %825 = load i64, ptr %3, align 8
  %826 = ptrtoint ptr %0 to i64
  %827 = ptrtoint ptr %1 to i64
  %828 = sub i64 %827, %827
  %829 = sub i64 %828, %825
  %830 = mul i64 %829, %825
  %831 = or i64 %830, %825
  %832 = or i64 %831, %826
  store i64 %832, ptr %3, align 8
  br label %529

833:                                              ; preds = %378
  %834 = load i64, ptr %3, align 8
  %835 = ptrtoint ptr %0 to i64
  %836 = ptrtoint ptr %1 to i64
  %837 = and i64 %836, %834
  %838 = or i64 %837, %834
  %839 = add i64 %838, %835
  %840 = or i64 %839, %834
  %841 = or i64 %840, %836
  %842 = or i64 %841, %834
  store i64 %842, ptr %3, align 8
  br label %529

843:                                              ; preds = %396
  %844 = load i64, ptr %3, align 8
  %845 = ptrtoint ptr %0 to i64
  %846 = ptrtoint ptr %1 to i64
  %847 = or i64 %845, %846
  %848 = or i64 %847, %845
  %849 = sub i64 %848, %845
  %850 = xor i64 %849, %846
  %851 = add i64 %850, %844
  %852 = sub i64 %851, %845
  store i64 %852, ptr %3, align 8
  br label %529

853:                                              ; preds = %407
  %854 = load i64, ptr %3, align 8
  %855 = ptrtoint ptr %0 to i64
  %856 = ptrtoint ptr %1 to i64
  %857 = xor i64 %854, %855
  %858 = add i64 %857, %854
  %859 = add i64 %858, %856
  %860 = xor i64 %859, %854
  %861 = mul i64 %860, %854
  store i64 %861, ptr %3, align 8
  br label %529

862:                                              ; preds = %426
  %863 = load i64, ptr %3, align 8
  %864 = ptrtoint ptr %0 to i64
  %865 = ptrtoint ptr %1 to i64
  %866 = xor i64 %863, %864
  %867 = mul i64 %866, %864
  %868 = or i64 %867, %863
  %869 = and i64 %868, %864
  %870 = xor i64 %869, %865
  %871 = mul i64 %870, %865
  store i64 %871, ptr %3, align 8
  br label %529

872:                                              ; preds = %440
  %873 = load i64, ptr %3, align 8
  %874 = ptrtoint ptr %0 to i64
  %875 = ptrtoint ptr %1 to i64
  %876 = or i64 %873, %875
  %877 = xor i64 %876, %875
  %878 = add i64 %877, %873
  store i64 %878, ptr %3, align 8
  br label %529

879:                                              ; preds = %463
  %880 = load i64, ptr %3, align 8
  %881 = ptrtoint ptr %0 to i64
  %882 = ptrtoint ptr %1 to i64
  %883 = or i64 %882, %880
  %884 = and i64 %883, %880
  %885 = xor i64 %884, %880
  %886 = add i64 %885, %882
  %887 = or i64 %886, %881
  %888 = sub i64 %887, %882
  store i64 %888, ptr %3, align 8
  br label %529

889:                                              ; preds = %476
  %890 = load i64, ptr %3, align 8
  %891 = ptrtoint ptr %0 to i64
  %892 = ptrtoint ptr %1 to i64
  %893 = or i64 %892, %890
  %894 = add i64 %893, %890
  %895 = add i64 %894, %891
  %896 = and i64 %895, %890
  %897 = xor i64 %896, %892
  %898 = mul i64 %897, %891
  store i64 %898, ptr %3, align 8
  br label %529

899:                                              ; preds = %488
  %900 = load i64, ptr %3, align 8
  %901 = ptrtoint ptr %0 to i64
  %902 = ptrtoint ptr %1 to i64
  %903 = and i64 %902, %901
  %904 = mul i64 %903, %900
  %905 = add i64 %904, %900
  %906 = sub i64 %905, %902
  %907 = mul i64 %906, %901
  %908 = sub i64 %907, %900
  store i64 %908, ptr %3, align 8
  br label %529

909:                                              ; preds = %502
  %910 = load i64, ptr %3, align 8
  %911 = ptrtoint ptr %0 to i64
  %912 = ptrtoint ptr %1 to i64
  %913 = xor i64 %910, %911
  %914 = mul i64 %913, %911
  %915 = xor i64 %914, %910
  %916 = add i64 %915, %910
  %917 = or i64 %916, %910
  %918 = add i64 %917, %911
  store i64 %918, ptr %3, align 8
  br label %529

919:                                              ; preds = %511
  %920 = load i64, ptr %3, align 8
  %921 = ptrtoint ptr %0 to i64
  %922 = ptrtoint ptr %1 to i64
  %923 = add i64 %920, %921
  %924 = add i64 %923, %920
  %925 = sub i64 %924, %922
  %926 = add i64 %925, %920
  %927 = mul i64 %926, %921
  store i64 %927, ptr %3, align 8
  br label %529

928:                                              ; preds = %530
  %929 = load i64, ptr %3, align 8
  %930 = ptrtoint ptr %0 to i64
  %931 = ptrtoint ptr %1 to i64
  %932 = sub i64 %931, %929
  %933 = sub i64 %932, %929
  %934 = mul i64 %933, %930
  %935 = mul i64 %934, %930
  store i64 %935, ptr %3, align 8
  br label %14

936:                                              ; preds = %541
  %937 = load i64, ptr %3, align 8
  %938 = ptrtoint ptr %0 to i64
  %939 = ptrtoint ptr %1 to i64
  %940 = or i64 %938, %939
  %941 = xor i64 %940, %939
  %942 = xor i64 %941, %938
  store i64 %942, ptr %3, align 8
  br label %529

943:                                              ; preds = %554
  %944 = load i64, ptr %3, align 8
  %945 = ptrtoint ptr %0 to i64
  %946 = ptrtoint ptr %1 to i64
  %947 = mul i64 %944, %946
  %948 = mul i64 %947, %945
  %949 = add i64 %948, %944
  %950 = and i64 %949, %945
  %951 = and i64 %950, %945
  %952 = sub i64 %951, %945
  store i64 %952, ptr %3, align 8
  br label %529

953:                                              ; preds = %567
  %954 = load i64, ptr %3, align 8
  %955 = ptrtoint ptr %0 to i64
  %956 = ptrtoint ptr %1 to i64
  %957 = or i64 %954, %955
  %958 = add i64 %957, %954
  %959 = sub i64 %958, %954
  %960 = and i64 %959, %954
  store i64 %960, ptr %3, align 8
  br label %529

961:                                              ; preds = %578
  %962 = load i64, ptr %3, align 8
  %963 = ptrtoint ptr %0 to i64
  %964 = ptrtoint ptr %1 to i64
  %965 = or i64 %963, %964
  %966 = or i64 %965, %963
  %967 = xor i64 %966, %963
  %968 = and i64 %967, %963
  store i64 %968, ptr %3, align 8
  br label %529

969:                                              ; preds = %598
  %970 = load i64, ptr %3, align 8
  %971 = ptrtoint ptr %0 to i64
  %972 = ptrtoint ptr %1 to i64
  %973 = or i64 %970, %970
  %974 = and i64 %973, %971
  %975 = sub i64 %974, %972
  %976 = or i64 %975, %971
  store i64 %976, ptr %3, align 8
  br label %529

977:                                              ; preds = %611
  %978 = load i64, ptr %3, align 8
  %979 = ptrtoint ptr %0 to i64
  %980 = ptrtoint ptr %1 to i64
  %981 = add i64 %979, %979
  %982 = xor i64 %981, %980
  %983 = sub i64 %982, %979
  %984 = and i64 %983, %979
  %985 = xor i64 %984, %978
  %986 = and i64 %985, %978
  store i64 %986, ptr %3, align 8
  br label %529

987:                                              ; preds = %633
  %988 = load i64, ptr %3, align 8
  %989 = ptrtoint ptr %0 to i64
  %990 = ptrtoint ptr %1 to i64
  %991 = and i64 %989, %990
  %992 = add i64 %991, %990
  %993 = sub i64 %992, %990
  %994 = and i64 %993, %989
  store i64 %994, ptr %3, align 8
  br label %529

995:                                              ; preds = %644
  %996 = load i64, ptr %3, align 8
  %997 = ptrtoint ptr %0 to i64
  %998 = ptrtoint ptr %1 to i64
  %999 = add i64 %996, %996
  %1000 = mul i64 %999, %998
  %1001 = add i64 %1000, %998
  %1002 = add i64 %1001, %998
  %1003 = mul i64 %1002, %998
  store i64 %1003, ptr %3, align 8
  br label %529
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @splitPipe(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = alloca i32, align 4
  %6 = alloca i1, align 1
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca ptr, align 8
  %12 = alloca i32, align 4
  store i32 -50691076, ptr %5, align 4
  br label %13

13:                                               ; preds = %423, %216, %215, %3
  %14 = load i32, ptr %5, align 4
  %15 = sub i32 %14, -1610509940
  %16 = mul i32 %15, -370808285
  switch i32 %16, label %216 [
    i32 299074896, label %17
    i32 809530373, label %43
    i32 411960812, label %59
    i32 1329419157, label %80
    i32 1745961983, label %100
    i32 1304065122, label %116
    i32 942448328, label %142
    i32 2115600902, label %154
    i32 250274737, label %165
    i32 1366385477, label %178
    i32 537930390, label %213
    i32 1098930075, label %226
    i32 1974260643, label %238
    i32 2011133967, label %251
    i32 76536617, label %263
    i32 921675725, label %276
    i32 986551627, label %288
    i32 1245871144, label %301
    i32 573474340, label %312
  ]

17:                                               ; preds = %13
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  store i32 %2, ptr %9, align 4
  store i32 0, ptr %10, align 4
  %18 = load ptr, ptr %7, align 8
  store ptr %18, ptr %11, align 8
  %19 = load ptr, ptr %11, align 8
  %20 = load ptr, ptr %8, align 8
  %21 = load i32, ptr %10, align 4
  %22 = load i32, ptr %5, align 4
  %23 = xor i32 %22, -50691075
  %24 = sub i32 %21, %23
  %25 = load i32, ptr %5, align 4
  %26 = xor i32 %25, -50691074
  %27 = mul i32 %21, %26
  %28 = load i32, ptr %5, align 4
  %29 = xor i32 %28, -50691075
  %30 = mul i32 %29, %24
  %31 = sub i32 %27, %30
  store i32 %31, ptr %10, align 4
  %32 = sext i32 %21 to i64
  %33 = getelementptr inbounds ptr, ptr %20, i64 %32
  store ptr %19, ptr %33, align 8
  store i32 1671952707, ptr %5, align 4
  %34 = xor i32 %2, -1020305601
  %35 = and i32 %2, %34
  %36 = or i32 %2, %34
  %37 = xor i32 %2, %34
  %38 = add i32 %35, %36
  %39 = sub i32 %38, %2
  %40 = sub i32 %39, %34
  %41 = mul i32 %40, 120
  %42 = icmp ne i32 %41, 0
  br i1 %42, label %323, label %215

43:                                               ; preds = %13
  %44 = load ptr, ptr %11, align 8
  %45 = load i8, ptr %44, align 1
  %46 = sext i8 %45 to i32
  %47 = icmp ne i32 %46, 0
  store i1 false, ptr %6, align 1
  %48 = select i1 %47, i32 1494164656, i32 -2109985677
  store i32 %48, ptr %5, align 4
  %49 = xor i32 %2, -643266769
  %50 = and i32 %2, %49
  %51 = or i32 %2, %49
  %52 = xor i32 %2, %49
  %53 = add i32 %2, %49
  %54 = sub i32 %53, %52
  %55 = mul i32 %50, 2
  %56 = sub i32 %54, %55
  %57 = mul i32 %56, 81
  %58 = icmp uge i32 %57, 0
  br i1 %58, label %215, label %333

59:                                               ; preds = %13
  %60 = load i32, ptr %10, align 4
  %61 = load i32, ptr %9, align 4
  %62 = icmp slt i32 %60, %61
  store i1 %62, ptr %6, align 1
  store i32 -2109985677, ptr %5, align 4
  %63 = xor i32 %2, 1281079415
  %64 = and i32 %2, %63
  %65 = or i32 %2, %63
  %66 = xor i32 %2, %63
  %67 = add i32 %64, %65
  %68 = sub i32 %67, %2
  %69 = sub i32 %68, %63
  %70 = mul i32 %69, 174
  %71 = xor i32 %2, 1552401891
  %72 = and i32 %2, %71
  %73 = or i32 %2, %71
  %74 = xor i32 %2, %71
  %75 = add i32 %72, %73
  %76 = sub i32 %75, %2
  %77 = sub i32 %76, %71
  %78 = mul i32 %77, 213
  %79 = icmp eq i32 %70, %78
  br i1 %79, label %215, label %344

80:                                               ; preds = %13
  %81 = load i1, ptr %6, align 1
  %82 = select i1 %81, i32 -923899903, i32 2008000718
  store i32 %82, ptr %5, align 4
  %83 = xor i32 %2, 1806290845
  %84 = and i32 %2, %83
  %85 = or i32 %2, %83
  %86 = xor i32 %2, %83
  %87 = sub i32 %85, %86
  %88 = sub i32 %87, %84
  %89 = mul i32 %88, 48
  %90 = xor i32 %2, -1487301413
  %91 = and i32 %2, %90
  %92 = or i32 %2, %90
  %93 = xor i32 %2, %90
  %94 = mul i32 %92, 2
  %95 = sub i32 %94, %93
  %96 = sub i32 %95, %2
  %97 = sub i32 %96, %90
  %98 = mul i32 %97, 20
  %99 = icmp eq i32 %89, %98
  br i1 %99, label %215, label %355

100:                                              ; preds = %13
  %101 = load ptr, ptr %11, align 8
  %102 = load i8, ptr %101, align 1
  %103 = sext i8 %102 to i32
  %104 = icmp eq i32 %103, 124
  %105 = select i1 %104, i32 746114242, i32 1488597028
  store i32 %105, ptr %5, align 4
  %106 = xor i32 %2, -1856518403
  %107 = and i32 %2, %106
  %108 = or i32 %2, %106
  %109 = xor i32 %2, %106
  %110 = mul i32 %108, 2
  %111 = sub i32 %110, %109
  %112 = sub i32 %111, %2
  %113 = sub i32 %112, %106
  %114 = mul i32 %113, 23
  %115 = icmp uge i32 %114, 0
  br i1 %115, label %215, label %366

116:                                              ; preds = %13
  %117 = load ptr, ptr %11, align 8
  store i8 0, ptr %117, align 1
  %118 = load ptr, ptr %11, align 8
  %119 = getelementptr inbounds i8, ptr %118, i64 1
  %120 = load ptr, ptr %8, align 8
  %121 = load i32, ptr %10, align 4
  %122 = load i32, ptr %5, align 4
  %123 = xor i32 %122, 746114243
  %124 = sub i32 %121, %123
  %125 = load i32, ptr %5, align 4
  %126 = xor i32 %125, 746114240
  %127 = mul i32 %121, %126
  %128 = load i32, ptr %5, align 4
  %129 = xor i32 %128, 746114243
  %130 = mul i32 %129, %124
  %131 = sub i32 %127, %130
  store i32 %131, ptr %10, align 4
  %132 = sext i32 %121 to i64
  %133 = getelementptr inbounds ptr, ptr %120, i64 %132
  store ptr %119, ptr %133, align 8
  store i32 1488597028, ptr %5, align 4
  %134 = xor i32 %2, 149199881
  %135 = and i32 %2, %134
  %136 = or i32 %2, %134
  %137 = xor i32 %2, %134
  %138 = sub i32 %136, %137
  %139 = sub i32 %138, %135
  %140 = mul i32 %139, 16
  %141 = icmp eq i32 %140, 0
  br i1 %141, label %215, label %376

142:                                              ; preds = %13
  %143 = load ptr, ptr %11, align 8
  %144 = getelementptr inbounds nuw i8, ptr %143, i32 1
  store ptr %144, ptr %11, align 8
  store i32 1671952707, ptr %5, align 4
  %145 = xor i32 %2, 1476488069
  %146 = and i32 %2, %145
  %147 = or i32 %2, %145
  %148 = xor i32 %2, %145
  %149 = add i32 %146, %147
  %150 = sub i32 %149, %2
  %151 = sub i32 %150, %145
  %152 = mul i32 %151, 253
  %153 = icmp slt i32 %152, 1
  br i1 %153, label %215, label %384

154:                                              ; preds = %13
  store i32 0, ptr %12, align 4
  store i32 655341479, ptr %5, align 4
  %155 = xor i32 %2, -2004412955
  %156 = and i32 %2, %155
  %157 = or i32 %2, %155
  %158 = xor i32 %2, %155
  %159 = add i32 %2, %155
  %160 = sub i32 %159, %158
  %161 = mul i32 %156, 2
  %162 = sub i32 %160, %161
  %163 = mul i32 %162, 27
  %164 = icmp sle i32 %163, 0
  br i1 %164, label %215, label %395

165:                                              ; preds = %13
  %166 = load i32, ptr %12, align 4
  %167 = load i32, ptr %10, align 4
  %168 = icmp slt i32 %166, %167
  %169 = select i1 %168, i32 -1214635773, i32 -1335820546
  store i32 %169, ptr %5, align 4
  %170 = xor i32 %2, 1270786123
  %171 = and i32 %2, %170
  %172 = or i32 %2, %170
  %173 = xor i32 %2, %170
  %174 = sub i32 %172, %173
  %175 = sub i32 %174, %171
  %176 = mul i32 %175, 196
  %177 = icmp uge i32 %176, 0
  br i1 %177, label %215, label %403

178:                                              ; preds = %13
  %179 = load ptr, ptr %8, align 8
  %180 = load i32, ptr %12, align 4
  %181 = sext i32 %180 to i64
  %182 = getelementptr inbounds ptr, ptr %179, i64 %181
  %183 = load ptr, ptr %182, align 8
  call void @trim(ptr noundef %183)
  %184 = load i32, ptr %12, align 4
  %185 = load i32, ptr %5, align 4
  %186 = xor i32 %185, -1214635774
  %187 = sub i32 %184, %186
  %188 = load i32, ptr %5, align 4
  %189 = xor i32 %188, -1214635775
  %190 = mul i32 %184, %189
  %191 = load i32, ptr %5, align 4
  %192 = xor i32 %191, -1214635774
  %193 = mul i32 %192, %187
  %194 = sub i32 %190, %193
  store i32 %194, ptr %12, align 4
  store i32 655341479, ptr %5, align 4
  %195 = xor i32 %2, -2008828411
  %196 = and i32 %2, %195
  %197 = or i32 %2, %195
  %198 = xor i32 %2, %195
  %199 = add i32 %2, %195
  %200 = sub i32 %199, %198
  %201 = mul i32 %196, 2
  %202 = sub i32 %200, %201
  %203 = mul i32 %202, 226
  %204 = xor i32 %2, -1247580179
  %205 = and i32 %2, %204
  %206 = or i32 %2, %204
  %207 = xor i32 %2, %204
  %208 = add i32 %205, %206
  %209 = sub i32 %208, %2
  %210 = sub i32 %209, %204
  %211 = mul i32 %210, 88
  %212 = icmp ne i32 %203, %211
  br i1 %212, label %413, label %215

213:                                              ; preds = %13
  %214 = load i32, ptr %10, align 4
  ret i32 %214

215:                                              ; preds = %501, %491, %480, %469, %460, %452, %443, %434, %413, %403, %395, %384, %376, %366, %355, %344, %333, %323, %312, %301, %288, %276, %263, %251, %238, %226, %178, %165, %154, %142, %116, %100, %80, %59, %43, %17
  br label %13

216:                                              ; preds = %13
  store i32 -50691076, ptr %5, align 4
  call void asm sideeffect "", ""()
  %217 = xor i32 %2, -1743967431
  %218 = and i32 %2, %217
  %219 = or i32 %2, %217
  %220 = xor i32 %2, %217
  %221 = add i32 %218, %219
  %222 = sub i32 %221, %2
  %223 = sub i32 %222, %217
  %224 = mul i32 %223, 198
  %225 = icmp eq i32 %224, 0
  br i1 %225, label %13, label %423

226:                                              ; preds = %13
  %227 = load i32, ptr %5, align 4
  %228 = xor i32 %227, -1360833406
  store i32 %228, ptr %5, align 4
  %229 = xor i32 %2, 1886752887
  %230 = and i32 %2, %229
  %231 = or i32 %2, %229
  %232 = xor i32 %2, %229
  %233 = add i32 %230, %231
  %234 = sub i32 %233, %2
  %235 = sub i32 %234, %229
  %236 = mul i32 %235, 108
  %237 = icmp sle i32 %236, 0
  br i1 %237, label %215, label %434

238:                                              ; preds = %13
  %239 = load i32, ptr %5, align 4
  %240 = xor i32 %239, -1807880737
  store i32 %240, ptr %5, align 4
  %241 = xor i32 %2, -783278357
  %242 = and i32 %2, %241
  %243 = or i32 %2, %241
  %244 = xor i32 %2, %241
  %245 = mul i32 %243, 2
  %246 = sub i32 %245, %244
  %247 = sub i32 %246, %2
  %248 = sub i32 %247, %241
  %249 = mul i32 %248, 126
  %250 = icmp slt i32 %249, 1
  br i1 %250, label %215, label %443

251:                                              ; preds = %13
  %252 = load i32, ptr %5, align 4
  %253 = xor i32 %252, -1613908077
  store i32 %253, ptr %5, align 4
  %254 = xor i32 %2, 1034969473
  %255 = and i32 %2, %254
  %256 = or i32 %2, %254
  %257 = xor i32 %2, %254
  %258 = add i32 %255, %256
  %259 = sub i32 %258, %2
  %260 = sub i32 %259, %254
  %261 = mul i32 %260, 198
  %262 = icmp slt i32 %261, 1
  br i1 %262, label %215, label %452

263:                                              ; preds = %13
  %264 = load i32, ptr %5, align 4
  %265 = xor i32 %264, -509491495
  store i32 %265, ptr %5, align 4
  %266 = xor i32 %2, 1290544181
  %267 = and i32 %2, %266
  %268 = or i32 %2, %266
  %269 = xor i32 %2, %266
  %270 = add i32 %2, %266
  %271 = sub i32 %270, %269
  %272 = mul i32 %267, 2
  %273 = sub i32 %271, %272
  %274 = mul i32 %273, 183
  %275 = icmp sle i32 %274, 0
  br i1 %275, label %215, label %460

276:                                              ; preds = %13
  %277 = load i32, ptr %5, align 4
  %278 = xor i32 %277, 14105487
  store i32 %278, ptr %5, align 4
  %279 = xor i32 %2, 369446389
  %280 = and i32 %2, %279
  %281 = or i32 %2, %279
  %282 = xor i32 %2, %279
  %283 = add i32 %280, %281
  %284 = sub i32 %283, %2
  %285 = sub i32 %284, %279
  %286 = mul i32 %285, 245
  %287 = icmp slt i32 %286, 1
  br i1 %287, label %215, label %469

288:                                              ; preds = %13
  %289 = load i32, ptr %5, align 4
  %290 = xor i32 %289, -2052478774
  store i32 %290, ptr %5, align 4
  %291 = xor i32 %2, 1488290801
  %292 = and i32 %2, %291
  %293 = or i32 %2, %291
  %294 = xor i32 %2, %291
  %295 = mul i32 %293, 2
  %296 = sub i32 %295, %294
  %297 = sub i32 %296, %2
  %298 = sub i32 %297, %291
  %299 = mul i32 %298, 65
  %300 = icmp sgt i32 %299, 0
  br i1 %300, label %480, label %215

301:                                              ; preds = %13
  %302 = load i32, ptr %5, align 4
  %303 = xor i32 %302, 426825905
  store i32 %303, ptr %5, align 4
  %304 = xor i32 %2, -2111740023
  %305 = and i32 %2, %304
  %306 = or i32 %2, %304
  %307 = xor i32 %2, %304
  %308 = sub i32 %306, %307
  %309 = sub i32 %308, %305
  %310 = mul i32 %309, 68
  %311 = icmp uge i32 %310, 0
  br i1 %311, label %215, label %491

312:                                              ; preds = %13
  %313 = load i32, ptr %5, align 4
  %314 = xor i32 %313, 1929096118
  store i32 %314, ptr %5, align 4
  %315 = xor i32 %2, -1764973675
  %316 = and i32 %2, %315
  %317 = or i32 %2, %315
  %318 = xor i32 %2, %315
  %319 = sub i32 %317, %318
  %320 = sub i32 %319, %316
  %321 = mul i32 %320, 36
  %322 = icmp sgt i32 %321, 0
  br i1 %322, label %501, label %215

323:                                              ; preds = %17
  %324 = load i64, ptr %4, align 8
  %325 = ptrtoint ptr %0 to i64
  %326 = ptrtoint ptr %1 to i64
  %327 = zext i32 %2 to i64
  %328 = sub i64 %327, %327
  %329 = and i64 %328, %324
  %330 = and i64 %329, %326
  %331 = sub i64 %330, %325
  %332 = sub i64 %331, %324
  store i64 %332, ptr %4, align 8
  br label %215

333:                                              ; preds = %43
  %334 = load i64, ptr %4, align 8
  %335 = ptrtoint ptr %0 to i64
  %336 = ptrtoint ptr %1 to i64
  %337 = zext i32 %2 to i64
  %338 = and i64 %336, %334
  %339 = xor i64 %338, %337
  %340 = or i64 %339, %335
  %341 = or i64 %340, %334
  %342 = add i64 %341, %335
  %343 = and i64 %342, %334
  store i64 %343, ptr %4, align 8
  br label %215

344:                                              ; preds = %59
  %345 = load i64, ptr %4, align 8
  %346 = ptrtoint ptr %0 to i64
  %347 = ptrtoint ptr %1 to i64
  %348 = zext i32 %2 to i64
  %349 = xor i64 %345, %346
  %350 = sub i64 %349, %345
  %351 = and i64 %350, %348
  %352 = sub i64 %351, %348
  %353 = or i64 %352, %346
  %354 = and i64 %353, %346
  store i64 %354, ptr %4, align 8
  br label %215

355:                                              ; preds = %80
  %356 = load i64, ptr %4, align 8
  %357 = ptrtoint ptr %0 to i64
  %358 = ptrtoint ptr %1 to i64
  %359 = zext i32 %2 to i64
  %360 = or i64 %358, %356
  %361 = and i64 %360, %358
  %362 = add i64 %361, %359
  %363 = and i64 %362, %357
  %364 = or i64 %363, %358
  %365 = sub i64 %364, %356
  store i64 %365, ptr %4, align 8
  br label %215

366:                                              ; preds = %100
  %367 = load i64, ptr %4, align 8
  %368 = ptrtoint ptr %0 to i64
  %369 = ptrtoint ptr %1 to i64
  %370 = zext i32 %2 to i64
  %371 = xor i64 %367, %367
  %372 = add i64 %371, %370
  %373 = add i64 %372, %368
  %374 = add i64 %373, %370
  %375 = mul i64 %374, %367
  store i64 %375, ptr %4, align 8
  br label %215

376:                                              ; preds = %116
  %377 = load i64, ptr %4, align 8
  %378 = ptrtoint ptr %0 to i64
  %379 = ptrtoint ptr %1 to i64
  %380 = zext i32 %2 to i64
  %381 = and i64 %378, %380
  %382 = or i64 %381, %380
  %383 = add i64 %382, %380
  store i64 %383, ptr %4, align 8
  br label %215

384:                                              ; preds = %142
  %385 = load i64, ptr %4, align 8
  %386 = ptrtoint ptr %0 to i64
  %387 = ptrtoint ptr %1 to i64
  %388 = zext i32 %2 to i64
  %389 = mul i64 %386, %386
  %390 = xor i64 %389, %388
  %391 = or i64 %390, %387
  %392 = sub i64 %391, %387
  %393 = sub i64 %392, %385
  %394 = or i64 %393, %388
  store i64 %394, ptr %4, align 8
  br label %215

395:                                              ; preds = %154
  %396 = load i64, ptr %4, align 8
  %397 = ptrtoint ptr %0 to i64
  %398 = ptrtoint ptr %1 to i64
  %399 = zext i32 %2 to i64
  %400 = mul i64 %396, %397
  %401 = add i64 %400, %399
  %402 = mul i64 %401, %398
  store i64 %402, ptr %4, align 8
  br label %215

403:                                              ; preds = %165
  %404 = load i64, ptr %4, align 8
  %405 = ptrtoint ptr %0 to i64
  %406 = ptrtoint ptr %1 to i64
  %407 = zext i32 %2 to i64
  %408 = and i64 %405, %404
  %409 = add i64 %408, %405
  %410 = sub i64 %409, %405
  %411 = add i64 %410, %405
  %412 = and i64 %411, %405
  store i64 %412, ptr %4, align 8
  br label %215

413:                                              ; preds = %178
  %414 = load i64, ptr %4, align 8
  %415 = ptrtoint ptr %0 to i64
  %416 = ptrtoint ptr %1 to i64
  %417 = zext i32 %2 to i64
  %418 = or i64 %414, %417
  %419 = or i64 %418, %416
  %420 = mul i64 %419, %415
  %421 = xor i64 %420, %415
  %422 = or i64 %421, %414
  store i64 %422, ptr %4, align 8
  br label %215

423:                                              ; preds = %216
  %424 = load i64, ptr %4, align 8
  %425 = ptrtoint ptr %0 to i64
  %426 = ptrtoint ptr %1 to i64
  %427 = zext i32 %2 to i64
  %428 = xor i64 %426, %424
  %429 = or i64 %428, %426
  %430 = mul i64 %429, %426
  %431 = add i64 %430, %427
  %432 = sub i64 %431, %426
  %433 = or i64 %432, %427
  store i64 %433, ptr %4, align 8
  br label %13

434:                                              ; preds = %226
  %435 = load i64, ptr %4, align 8
  %436 = ptrtoint ptr %0 to i64
  %437 = ptrtoint ptr %1 to i64
  %438 = zext i32 %2 to i64
  %439 = and i64 %438, %435
  %440 = mul i64 %439, %438
  %441 = mul i64 %440, %437
  %442 = xor i64 %441, %438
  store i64 %442, ptr %4, align 8
  br label %215

443:                                              ; preds = %238
  %444 = load i64, ptr %4, align 8
  %445 = ptrtoint ptr %0 to i64
  %446 = ptrtoint ptr %1 to i64
  %447 = zext i32 %2 to i64
  %448 = mul i64 %444, %445
  %449 = xor i64 %448, %445
  %450 = or i64 %449, %447
  %451 = mul i64 %450, %445
  store i64 %451, ptr %4, align 8
  br label %215

452:                                              ; preds = %251
  %453 = load i64, ptr %4, align 8
  %454 = ptrtoint ptr %0 to i64
  %455 = ptrtoint ptr %1 to i64
  %456 = zext i32 %2 to i64
  %457 = mul i64 %454, %456
  %458 = add i64 %457, %456
  %459 = and i64 %458, %456
  store i64 %459, ptr %4, align 8
  br label %215

460:                                              ; preds = %263
  %461 = load i64, ptr %4, align 8
  %462 = ptrtoint ptr %0 to i64
  %463 = ptrtoint ptr %1 to i64
  %464 = zext i32 %2 to i64
  %465 = add i64 %463, %461
  %466 = mul i64 %465, %463
  %467 = add i64 %466, %463
  %468 = add i64 %467, %463
  store i64 %468, ptr %4, align 8
  br label %215

469:                                              ; preds = %276
  %470 = load i64, ptr %4, align 8
  %471 = ptrtoint ptr %0 to i64
  %472 = ptrtoint ptr %1 to i64
  %473 = zext i32 %2 to i64
  %474 = sub i64 %470, %473
  %475 = mul i64 %474, %470
  %476 = sub i64 %475, %472
  %477 = mul i64 %476, %472
  %478 = xor i64 %477, %472
  %479 = xor i64 %478, %470
  store i64 %479, ptr %4, align 8
  br label %215

480:                                              ; preds = %288
  %481 = load i64, ptr %4, align 8
  %482 = ptrtoint ptr %0 to i64
  %483 = ptrtoint ptr %1 to i64
  %484 = zext i32 %2 to i64
  %485 = xor i64 %482, %483
  %486 = or i64 %485, %481
  %487 = sub i64 %486, %483
  %488 = add i64 %487, %483
  %489 = mul i64 %488, %481
  %490 = sub i64 %489, %483
  store i64 %490, ptr %4, align 8
  br label %215

491:                                              ; preds = %301
  %492 = load i64, ptr %4, align 8
  %493 = ptrtoint ptr %0 to i64
  %494 = ptrtoint ptr %1 to i64
  %495 = zext i32 %2 to i64
  %496 = sub i64 %495, %494
  %497 = sub i64 %496, %492
  %498 = sub i64 %497, %492
  %499 = add i64 %498, %494
  %500 = mul i64 %499, %492
  store i64 %500, ptr %4, align 8
  br label %215

501:                                              ; preds = %312
  %502 = load i64, ptr %4, align 8
  %503 = ptrtoint ptr %0 to i64
  %504 = ptrtoint ptr %1 to i64
  %505 = zext i32 %2 to i64
  %506 = mul i64 %502, %503
  %507 = or i64 %506, %502
  %508 = xor i64 %507, %503
  %509 = or i64 %508, %502
  %510 = add i64 %509, %502
  store i64 %510, ptr %4, align 8
  br label %215
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @findProductIndexById(i32 noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 1051890646, ptr %3, align 4
  br label %7

7:                                                ; preds = %269, %123, %122, %1
  %8 = load i32, ptr %3, align 4
  %9 = sub i32 %8, 528728178
  %10 = mul i32 %9, 960246997
  switch i32 %10, label %123 [
    i32 1146499636, label %11
    i32 1192401047, label %29
    i32 354458184, label %44
    i32 1084178214, label %61
    i32 2058311787, label %73
    i32 1402980498, label %103
    i32 1156250717, label %120
    i32 2145419299, label %132
    i32 957990633, label %144
    i32 1550416332, label %155
    i32 470715774, label %168
    i32 1020065984, label %181
    i32 1499871008, label %201
    i32 266827301, label %212
  ]

11:                                               ; preds = %7
  store i32 %0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  store i32 -1096794579, ptr %3, align 4
  %12 = xor i32 %0, 285611985
  %13 = and i32 %0, %12
  %14 = or i32 %0, %12
  %15 = xor i32 %0, %12
  %16 = add i32 %0, %12
  %17 = sub i32 %16, %15
  %18 = mul i32 %13, 2
  %19 = sub i32 %17, %18
  %20 = mul i32 %19, 244
  %21 = xor i32 %0, 1737124075
  %22 = and i32 %0, %21
  %23 = or i32 %0, %21
  %24 = xor i32 %0, %21
  %25 = sub i32 %23, %24
  %26 = sub i32 %25, %22
  %27 = mul i32 %26, 234
  %28 = icmp eq i32 %20, %27
  br i1 %28, label %122, label %224

29:                                               ; preds = %7
  %30 = load i32, ptr %6, align 4
  %31 = load i32, ptr @productCount, align 4
  %32 = icmp slt i32 %30, %31
  %33 = select i1 %32, i32 1984640410, i32 1195882428
  store i32 %33, ptr %3, align 4
  %34 = xor i32 %0, 72276513
  %35 = and i32 %0, %34
  %36 = or i32 %0, %34
  %37 = xor i32 %0, %34
  %38 = mul i32 %36, 2
  %39 = sub i32 %38, %37
  %40 = sub i32 %39, %0
  %41 = sub i32 %40, %34
  %42 = mul i32 %41, 105
  %43 = icmp slt i32 %42, 0
  br i1 %43, label %230, label %122

44:                                               ; preds = %7
  %45 = load i32, ptr %6, align 4
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %46
  %48 = getelementptr inbounds nuw %struct.Product, ptr %47, i32 0, i32 0
  %49 = load i32, ptr %48, align 16
  %50 = load i32, ptr %5, align 4
  %51 = icmp eq i32 %49, %50
  %52 = select i1 %51, i32 -973967872, i32 -2106279759
  store i32 %52, ptr %3, align 4
  %53 = xor i32 %0, 127281701
  %54 = and i32 %0, %53
  %55 = or i32 %0, %53
  %56 = xor i32 %0, %53
  %57 = sub i32 %55, %56
  %58 = sub i32 %57, %54
  %59 = mul i32 %58, 158
  %60 = icmp eq i32 %59, 0
  br i1 %60, label %122, label %237

61:                                               ; preds = %7
  %62 = load i32, ptr %6, align 4
  store i32 %62, ptr %4, align 4
  store i32 -920367653, ptr %3, align 4
  %63 = xor i32 %0, -1297933903
  %64 = and i32 %0, %63
  %65 = or i32 %0, %63
  %66 = xor i32 %0, %63
  %67 = mul i32 %65, 2
  %68 = sub i32 %67, %66
  %69 = sub i32 %68, %0
  %70 = sub i32 %69, %63
  %71 = mul i32 %70, 26
  %72 = icmp uge i32 %71, 0
  br i1 %72, label %122, label %246

73:                                               ; preds = %7
  %74 = load i32, ptr %6, align 4
  %75 = load i32, ptr %3, align 4
  %76 = xor i32 %75, -2106279760
  %77 = sub i32 %74, %76
  %78 = load i32, ptr %3, align 4
  %79 = xor i32 %78, -2106279757
  %80 = mul i32 %74, %79
  %81 = load i32, ptr %3, align 4
  %82 = xor i32 %81, -2106279760
  %83 = mul i32 %82, %77
  %84 = sub i32 %80, %83
  store i32 %84, ptr %6, align 4
  store i32 -1096794579, ptr %3, align 4
  %85 = xor i32 %0, -1035512891
  %86 = and i32 %0, %85
  %87 = or i32 %0, %85
  %88 = xor i32 %0, %85
  %89 = mul i32 %87, 2
  %90 = sub i32 %89, %88
  %91 = sub i32 %90, %0
  %92 = sub i32 %91, %85
  %93 = mul i32 %92, 214
  %94 = xor i32 %0, -1050926771
  %95 = and i32 %0, %94
  %96 = or i32 %0, %94
  %97 = xor i32 %0, %94
  %98 = add i32 %95, %96
  %99 = sub i32 %98, %0
  %100 = sub i32 %99, %94
  %101 = mul i32 %100, 91
  %102 = icmp eq i32 %93, %101
  br i1 %102, label %122, label %254

103:                                              ; preds = %7
  store i32 -1, ptr %4, align 4
  store i32 -920367653, ptr %3, align 4
  %104 = xor i32 %0, -557263357
  %105 = and i32 %0, %104
  %106 = or i32 %0, %104
  %107 = xor i32 %0, %104
  %108 = add i32 %105, %106
  %109 = sub i32 %108, %0
  %110 = sub i32 %109, %104
  %111 = mul i32 %110, 139
  %112 = xor i32 %0, -1654543617
  %113 = and i32 %0, %112
  %114 = or i32 %0, %112
  %115 = xor i32 %0, %112
  %116 = sub i32 %114, %115
  %117 = sub i32 %116, %113
  %118 = mul i32 %117, 208
  %119 = icmp eq i32 %111, %118
  br i1 %119, label %122, label %262

120:                                              ; preds = %7
  %121 = load i32, ptr %4, align 4
  ret i32 %121

122:                                              ; preds = %321, %313, %305, %296, %290, %283, %276, %262, %254, %246, %237, %230, %224, %212, %201, %181, %168, %155, %144, %132, %103, %73, %61, %44, %29, %11
  br label %7

123:                                              ; preds = %7
  store i32 1051890646, ptr %3, align 4
  call void asm sideeffect "", ""()
  %124 = xor i32 %0, 382441539
  %125 = and i32 %0, %124
  %126 = or i32 %0, %124
  %127 = xor i32 %0, %124
  %128 = sub i32 %126, %127
  %129 = sub i32 %128, %125
  %130 = mul i32 %129, 4
  %131 = icmp slt i32 %130, 1
  br i1 %131, label %7, label %269

132:                                              ; preds = %7
  %133 = load i32, ptr %3, align 4
  %134 = xor i32 %133, -1887366761
  store i32 %134, ptr %3, align 4
  %135 = xor i32 %0, 2030337007
  %136 = and i32 %0, %135
  %137 = or i32 %0, %135
  %138 = xor i32 %0, %135
  %139 = add i32 %136, %137
  %140 = sub i32 %139, %0
  %141 = sub i32 %140, %135
  %142 = mul i32 %141, 241
  %143 = icmp sgt i32 %142, 0
  br i1 %143, label %276, label %122

144:                                              ; preds = %7
  %145 = load i32, ptr %3, align 4
  %146 = xor i32 %145, -2051124952
  store i32 %146, ptr %3, align 4
  %147 = xor i32 %0, -206533453
  %148 = and i32 %0, %147
  %149 = or i32 %0, %147
  %150 = xor i32 %0, %147
  %151 = sub i32 %149, %150
  %152 = sub i32 %151, %148
  %153 = mul i32 %152, 64
  %154 = icmp slt i32 %153, 0
  br i1 %154, label %283, label %122

155:                                              ; preds = %7
  %156 = load i32, ptr %3, align 4
  %157 = xor i32 %156, -1846502845
  store i32 %157, ptr %3, align 4
  %158 = xor i32 %0, -1171268203
  %159 = and i32 %0, %158
  %160 = or i32 %0, %158
  %161 = xor i32 %0, %158
  %162 = mul i32 %160, 2
  %163 = sub i32 %162, %161
  %164 = sub i32 %163, %0
  %165 = sub i32 %164, %158
  %166 = mul i32 %165, 111
  %167 = icmp slt i32 %166, 0
  br i1 %167, label %290, label %122

168:                                              ; preds = %7
  %169 = load i32, ptr %3, align 4
  %170 = xor i32 %169, 590990079
  store i32 %170, ptr %3, align 4
  %171 = xor i32 %0, -868326033
  %172 = and i32 %0, %171
  %173 = or i32 %0, %171
  %174 = xor i32 %0, %171
  %175 = mul i32 %173, 2
  %176 = sub i32 %175, %174
  %177 = sub i32 %176, %0
  %178 = sub i32 %177, %171
  %179 = mul i32 %178, 111
  %180 = icmp ugt i32 %179, 0
  br i1 %180, label %296, label %122

181:                                              ; preds = %7
  %182 = load i32, ptr %3, align 4
  %183 = xor i32 %182, -211727607
  store i32 %183, ptr %3, align 4
  %184 = xor i32 %0, -466943411
  %185 = and i32 %0, %184
  %186 = or i32 %0, %184
  %187 = xor i32 %0, %184
  %188 = sub i32 %186, %187
  %189 = sub i32 %188, %185
  %190 = mul i32 %189, 202
  %191 = xor i32 %0, 809756729
  %192 = and i32 %0, %191
  %193 = or i32 %0, %191
  %194 = xor i32 %0, %191
  %195 = mul i32 %193, 2
  %196 = sub i32 %195, %194
  %197 = sub i32 %196, %0
  %198 = sub i32 %197, %191
  %199 = mul i32 %198, 210
  %200 = icmp ne i32 %190, %199
  br i1 %200, label %305, label %122

201:                                              ; preds = %7
  %202 = load i32, ptr %3, align 4
  %203 = xor i32 %202, -1247761956
  store i32 %203, ptr %3, align 4
  %204 = xor i32 %0, -511886509
  %205 = and i32 %0, %204
  %206 = or i32 %0, %204
  %207 = xor i32 %0, %204
  %208 = sub i32 %206, %207
  %209 = sub i32 %208, %205
  %210 = mul i32 %209, 235
  %211 = icmp uge i32 %210, 0
  br i1 %211, label %122, label %313

212:                                              ; preds = %7
  %213 = load i32, ptr %3, align 4
  %214 = xor i32 %213, 1799880483
  store i32 %214, ptr %3, align 4
  %215 = xor i32 %0, -1370228551
  %216 = and i32 %0, %215
  %217 = or i32 %0, %215
  %218 = xor i32 %0, %215
  %219 = add i32 %216, %217
  %220 = sub i32 %219, %0
  %221 = sub i32 %220, %215
  %222 = mul i32 %221, 176
  %223 = icmp eq i32 %222, 0
  br i1 %223, label %122, label %321

224:                                              ; preds = %11
  %225 = load i64, ptr %2, align 8
  %226 = zext i32 %0 to i64
  %227 = and i64 %225, %225
  %228 = sub i64 %227, %226
  %229 = mul i64 %228, %225
  store i64 %229, ptr %2, align 8
  br label %122

230:                                              ; preds = %29
  %231 = load i64, ptr %2, align 8
  %232 = zext i32 %0 to i64
  %233 = xor i64 %232, %231
  %234 = add i64 %233, %231
  %235 = sub i64 %234, %232
  %236 = add i64 %235, %231
  store i64 %236, ptr %2, align 8
  br label %122

237:                                              ; preds = %44
  %238 = load i64, ptr %2, align 8
  %239 = zext i32 %0 to i64
  %240 = mul i64 %238, %239
  %241 = or i64 %240, %239
  %242 = or i64 %241, %239
  %243 = sub i64 %242, %239
  %244 = sub i64 %243, %238
  %245 = xor i64 %244, %239
  store i64 %245, ptr %2, align 8
  br label %122

246:                                              ; preds = %61
  %247 = load i64, ptr %2, align 8
  %248 = zext i32 %0 to i64
  %249 = xor i64 %248, %247
  %250 = xor i64 %249, %247
  %251 = and i64 %250, %247
  %252 = xor i64 %251, %247
  %253 = mul i64 %252, %247
  store i64 %253, ptr %2, align 8
  br label %122

254:                                              ; preds = %73
  %255 = load i64, ptr %2, align 8
  %256 = zext i32 %0 to i64
  %257 = add i64 %255, %256
  %258 = and i64 %257, %256
  %259 = xor i64 %258, %256
  %260 = xor i64 %259, %256
  %261 = and i64 %260, %256
  store i64 %261, ptr %2, align 8
  br label %122

262:                                              ; preds = %103
  %263 = load i64, ptr %2, align 8
  %264 = zext i32 %0 to i64
  %265 = xor i64 %263, %264
  %266 = xor i64 %265, %263
  %267 = add i64 %266, %263
  %268 = add i64 %267, %263
  store i64 %268, ptr %2, align 8
  br label %122

269:                                              ; preds = %123
  %270 = load i64, ptr %2, align 8
  %271 = zext i32 %0 to i64
  %272 = mul i64 %270, %270
  %273 = xor i64 %272, %270
  %274 = mul i64 %273, %270
  %275 = and i64 %274, %271
  store i64 %275, ptr %2, align 8
  br label %7

276:                                              ; preds = %132
  %277 = load i64, ptr %2, align 8
  %278 = zext i32 %0 to i64
  %279 = add i64 %277, %277
  %280 = or i64 %279, %278
  %281 = add i64 %280, %278
  %282 = or i64 %281, %277
  store i64 %282, ptr %2, align 8
  br label %122

283:                                              ; preds = %144
  %284 = load i64, ptr %2, align 8
  %285 = zext i32 %0 to i64
  %286 = sub i64 %285, %285
  %287 = sub i64 %286, %285
  %288 = sub i64 %287, %284
  %289 = sub i64 %288, %285
  store i64 %289, ptr %2, align 8
  br label %122

290:                                              ; preds = %155
  %291 = load i64, ptr %2, align 8
  %292 = zext i32 %0 to i64
  %293 = sub i64 %292, %291
  %294 = or i64 %293, %292
  %295 = or i64 %294, %291
  store i64 %295, ptr %2, align 8
  br label %122

296:                                              ; preds = %168
  %297 = load i64, ptr %2, align 8
  %298 = zext i32 %0 to i64
  %299 = add i64 %297, %298
  %300 = xor i64 %299, %297
  %301 = mul i64 %300, %297
  %302 = sub i64 %301, %298
  %303 = sub i64 %302, %298
  %304 = add i64 %303, %297
  store i64 %304, ptr %2, align 8
  br label %122

305:                                              ; preds = %181
  %306 = load i64, ptr %2, align 8
  %307 = zext i32 %0 to i64
  %308 = or i64 %306, %306
  %309 = sub i64 %308, %307
  %310 = sub i64 %309, %306
  %311 = sub i64 %310, %307
  %312 = xor i64 %311, %307
  store i64 %312, ptr %2, align 8
  br label %122

313:                                              ; preds = %201
  %314 = load i64, ptr %2, align 8
  %315 = zext i32 %0 to i64
  %316 = sub i64 %314, %314
  %317 = or i64 %316, %314
  %318 = add i64 %317, %315
  %319 = add i64 %318, %315
  %320 = and i64 %319, %314
  store i64 %320, ptr %2, align 8
  br label %122

321:                                              ; preds = %212
  %322 = load i64, ptr %2, align 8
  %323 = zext i32 %0 to i64
  %324 = xor i64 %322, %323
  %325 = and i64 %324, %322
  %326 = and i64 %325, %323
  %327 = add i64 %326, %323
  %328 = add i64 %327, %322
  store i64 %328, ptr %2, align 8
  br label %122
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @findOrderIndexById(i32 noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 -1551587459, ptr %3, align 4
  br label %7

7:                                                ; preds = %232, %93, %92, %1
  %8 = load i32, ptr %3, align 4
  %9 = sub i32 %8, 70863365
  %10 = mul i32 %9, 1473398661
  switch i32 %10, label %93 [
    i32 495179608, label %11
    i32 1146222994, label %20
    i32 1543152282, label %35
    i32 1460483898, label %54
    i32 1183570636, label %64
    i32 1525753655, label %81
    i32 2141953739, label %90
    i32 952721116, label %103
    i32 306502859, label %115
    i32 1775266947, label %127
    i32 1006675797, label %138
    i32 1768430117, label %149
    i32 1427905935, label %162
    i32 1817775829, label %174
  ]

11:                                               ; preds = %7
  store i32 %0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  store i32 786275567, ptr %3, align 4
  %12 = xor i32 %0, 1064468717
  %13 = and i32 %0, %12
  %14 = or i32 %0, %12
  %15 = xor i32 %0, %12
  %16 = sub i32 %14, %15
  %17 = sub i32 %16, %13
  %18 = mul i32 %17, 219
  %19 = icmp ugt i32 %18, 0
  br i1 %19, label %185, label %92

20:                                               ; preds = %7
  %21 = load i32, ptr %6, align 4
  %22 = load i32, ptr @orderCount, align 4
  %23 = icmp slt i32 %21, %22
  %24 = select i1 %23, i32 7224407, i32 1464333456
  store i32 %24, ptr %3, align 4
  %25 = xor i32 %0, 1594837003
  %26 = and i32 %0, %25
  %27 = or i32 %0, %25
  %28 = xor i32 %0, %25
  %29 = mul i32 %27, 2
  %30 = sub i32 %29, %28
  %31 = sub i32 %30, %0
  %32 = sub i32 %31, %25
  %33 = mul i32 %32, 153
  %34 = icmp slt i32 %33, 1
  br i1 %34, label %92, label %192

35:                                               ; preds = %7
  %36 = load i32, ptr %6, align 4
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %37
  %39 = getelementptr inbounds nuw %struct.Order, ptr %38, i32 0, i32 0
  %40 = load i32, ptr %39, align 16
  %41 = load i32, ptr %5, align 4
  %42 = icmp eq i32 %40, %41
  %43 = select i1 %42, i32 1746440311, i32 80086369
  store i32 %43, ptr %3, align 4
  %44 = xor i32 %0, 1954385983
  %45 = and i32 %0, %44
  %46 = or i32 %0, %44
  %47 = xor i32 %0, %44
  %48 = add i32 %0, %44
  %49 = sub i32 %48, %47
  %50 = mul i32 %45, 2
  %51 = sub i32 %49, %50
  %52 = mul i32 %51, 116
  %53 = icmp slt i32 %52, 1
  br i1 %53, label %92, label %201

54:                                               ; preds = %7
  %55 = load i32, ptr %6, align 4
  store i32 %55, ptr %4, align 4
  store i32 -807575532, ptr %3, align 4
  %56 = xor i32 %0, 156933413
  %57 = and i32 %0, %56
  %58 = or i32 %0, %56
  %59 = xor i32 %0, %56
  %60 = sub i32 %58, %59
  %61 = sub i32 %60, %57
  %62 = mul i32 %61, 134
  %63 = icmp slt i32 %62, 1
  br i1 %63, label %92, label %210

64:                                               ; preds = %7
  %65 = load i32, ptr %6, align 4
  %66 = load i32, ptr %3, align 4
  %67 = xor i32 %66, 80086368
  %68 = or i32 %65, %67
  %69 = load i32, ptr %3, align 4
  %70 = xor i32 %69, 80086368
  %71 = and i32 %65, %70
  %72 = add i32 %68, %71
  store i32 %72, ptr %6, align 4
  store i32 786275567, ptr %3, align 4
  %73 = xor i32 %0, 1090151507
  %74 = and i32 %0, %73
  %75 = or i32 %0, %73
  %76 = xor i32 %0, %73
  %77 = sub i32 %75, %76
  %78 = sub i32 %77, %74
  %79 = mul i32 %78, 112
  %80 = icmp sgt i32 %79, 0
  br i1 %80, label %216, label %92

81:                                               ; preds = %7
  store i32 -1, ptr %4, align 4
  store i32 -807575532, ptr %3, align 4
  %82 = xor i32 %0, 1345387777
  %83 = and i32 %0, %82
  %84 = or i32 %0, %82
  %85 = xor i32 %0, %82
  %86 = sub i32 %84, %85
  %87 = sub i32 %86, %83
  %88 = mul i32 %87, 244
  %89 = icmp sgt i32 %88, 0
  br i1 %89, label %223, label %92

90:                                               ; preds = %7
  %91 = load i32, ptr %4, align 4
  ret i32 %91

92:                                               ; preds = %283, %274, %268, %261, %254, %248, %240, %223, %216, %210, %201, %192, %185, %174, %162, %149, %138, %127, %115, %103, %81, %64, %54, %35, %20, %11
  br label %7

93:                                               ; preds = %7
  store i32 -1551587459, ptr %3, align 4
  call void asm sideeffect "", ""()
  %94 = xor i32 %0, -831969143
  %95 = and i32 %0, %94
  %96 = or i32 %0, %94
  %97 = xor i32 %0, %94
  %98 = add i32 %95, %96
  %99 = sub i32 %98, %0
  %100 = sub i32 %99, %94
  %101 = mul i32 %100, 225
  %102 = icmp slt i32 %101, 1
  br i1 %102, label %7, label %232

103:                                              ; preds = %7
  %104 = load i32, ptr %3, align 4
  %105 = xor i32 %104, 2030943647
  store i32 %105, ptr %3, align 4
  %106 = xor i32 %0, 909868785
  %107 = and i32 %0, %106
  %108 = or i32 %0, %106
  %109 = xor i32 %0, %106
  %110 = add i32 %107, %108
  %111 = sub i32 %110, %0
  %112 = sub i32 %111, %106
  %113 = mul i32 %112, 57
  %114 = icmp eq i32 %113, 0
  br i1 %114, label %92, label %240

115:                                              ; preds = %7
  %116 = load i32, ptr %3, align 4
  %117 = xor i32 %116, -2034034797
  store i32 %117, ptr %3, align 4
  %118 = xor i32 %0, -1265618447
  %119 = and i32 %0, %118
  %120 = or i32 %0, %118
  %121 = xor i32 %0, %118
  %122 = add i32 %119, %120
  %123 = sub i32 %122, %0
  %124 = sub i32 %123, %118
  %125 = mul i32 %124, 147
  %126 = icmp slt i32 %125, 0
  br i1 %126, label %248, label %92

127:                                              ; preds = %7
  %128 = load i32, ptr %3, align 4
  %129 = xor i32 %128, -1914368927
  store i32 %129, ptr %3, align 4
  %130 = xor i32 %0, 644586461
  %131 = and i32 %0, %130
  %132 = or i32 %0, %130
  %133 = xor i32 %0, %130
  %134 = sub i32 %132, %133
  %135 = sub i32 %134, %131
  %136 = mul i32 %135, 178
  %137 = icmp eq i32 %136, 0
  br i1 %137, label %92, label %254

138:                                              ; preds = %7
  %139 = load i32, ptr %3, align 4
  %140 = xor i32 %139, -1297427705
  store i32 %140, ptr %3, align 4
  %141 = xor i32 %0, -938121005
  %142 = and i32 %0, %141
  %143 = or i32 %0, %141
  %144 = xor i32 %0, %141
  %145 = sub i32 %143, %144
  %146 = sub i32 %145, %142
  %147 = mul i32 %146, 201
  %148 = icmp sle i32 %147, 0
  br i1 %148, label %92, label %261

149:                                              ; preds = %7
  %150 = load i32, ptr %3, align 4
  %151 = xor i32 %150, -2013557756
  store i32 %151, ptr %3, align 4
  %152 = xor i32 %0, 1361883253
  %153 = and i32 %0, %152
  %154 = or i32 %0, %152
  %155 = xor i32 %0, %152
  %156 = mul i32 %154, 2
  %157 = sub i32 %156, %155
  %158 = sub i32 %157, %0
  %159 = sub i32 %158, %152
  %160 = mul i32 %159, 154
  %161 = icmp slt i32 %160, 1
  br i1 %161, label %92, label %268

162:                                              ; preds = %7
  %163 = load i32, ptr %3, align 4
  %164 = xor i32 %163, 624192604
  store i32 %164, ptr %3, align 4
  %165 = xor i32 %0, 1660352093
  %166 = and i32 %0, %165
  %167 = or i32 %0, %165
  %168 = xor i32 %0, %165
  %169 = add i32 %166, %167
  %170 = sub i32 %169, %0
  %171 = sub i32 %170, %165
  %172 = mul i32 %171, 120
  %173 = icmp uge i32 %172, 0
  br i1 %173, label %92, label %274

174:                                              ; preds = %7
  %175 = load i32, ptr %3, align 4
  %176 = xor i32 %175, 109778526
  store i32 %176, ptr %3, align 4
  %177 = xor i32 %0, -1023686993
  %178 = and i32 %0, %177
  %179 = or i32 %0, %177
  %180 = xor i32 %0, %177
  %181 = sub i32 %179, %180
  %182 = sub i32 %181, %178
  %183 = mul i32 %182, 14
  %184 = icmp slt i32 %183, 1
  br i1 %184, label %92, label %283

185:                                              ; preds = %11
  %186 = load i64, ptr %2, align 8
  %187 = zext i32 %0 to i64
  %188 = and i64 %186, %186
  %189 = sub i64 %188, %186
  %190 = xor i64 %189, %186
  %191 = add i64 %190, %187
  store i64 %191, ptr %2, align 8
  br label %92

192:                                              ; preds = %20
  %193 = load i64, ptr %2, align 8
  %194 = zext i32 %0 to i64
  %195 = add i64 %194, %193
  %196 = and i64 %195, %193
  %197 = and i64 %196, %194
  %198 = mul i64 %197, %193
  %199 = and i64 %198, %193
  %200 = or i64 %199, %194
  store i64 %200, ptr %2, align 8
  br label %92

201:                                              ; preds = %35
  %202 = load i64, ptr %2, align 8
  %203 = zext i32 %0 to i64
  %204 = add i64 %203, %203
  %205 = or i64 %204, %203
  %206 = and i64 %205, %202
  %207 = or i64 %206, %202
  %208 = add i64 %207, %202
  %209 = mul i64 %208, %203
  store i64 %209, ptr %2, align 8
  br label %92

210:                                              ; preds = %54
  %211 = load i64, ptr %2, align 8
  %212 = zext i32 %0 to i64
  %213 = and i64 %211, %211
  %214 = mul i64 %213, %211
  %215 = sub i64 %214, %212
  store i64 %215, ptr %2, align 8
  br label %92

216:                                              ; preds = %64
  %217 = load i64, ptr %2, align 8
  %218 = zext i32 %0 to i64
  %219 = sub i64 %218, %218
  %220 = sub i64 %219, %217
  %221 = add i64 %220, %218
  %222 = mul i64 %221, %217
  store i64 %222, ptr %2, align 8
  br label %92

223:                                              ; preds = %81
  %224 = load i64, ptr %2, align 8
  %225 = zext i32 %0 to i64
  %226 = sub i64 %225, %225
  %227 = mul i64 %226, %225
  %228 = mul i64 %227, %225
  %229 = and i64 %228, %224
  %230 = or i64 %229, %224
  %231 = mul i64 %230, %225
  store i64 %231, ptr %2, align 8
  br label %92

232:                                              ; preds = %93
  %233 = load i64, ptr %2, align 8
  %234 = zext i32 %0 to i64
  %235 = or i64 %234, %233
  %236 = and i64 %235, %234
  %237 = add i64 %236, %234
  %238 = sub i64 %237, %234
  %239 = sub i64 %238, %234
  store i64 %239, ptr %2, align 8
  br label %7

240:                                              ; preds = %103
  %241 = load i64, ptr %2, align 8
  %242 = zext i32 %0 to i64
  %243 = xor i64 %242, %241
  %244 = and i64 %243, %241
  %245 = and i64 %244, %241
  %246 = sub i64 %245, %242
  %247 = or i64 %246, %241
  store i64 %247, ptr %2, align 8
  br label %92

248:                                              ; preds = %115
  %249 = load i64, ptr %2, align 8
  %250 = zext i32 %0 to i64
  %251 = sub i64 %249, %249
  %252 = or i64 %251, %249
  %253 = or i64 %252, %250
  store i64 %253, ptr %2, align 8
  br label %92

254:                                              ; preds = %127
  %255 = load i64, ptr %2, align 8
  %256 = zext i32 %0 to i64
  %257 = and i64 %255, %256
  %258 = sub i64 %257, %255
  %259 = xor i64 %258, %255
  %260 = and i64 %259, %256
  store i64 %260, ptr %2, align 8
  br label %92

261:                                              ; preds = %138
  %262 = load i64, ptr %2, align 8
  %263 = zext i32 %0 to i64
  %264 = add i64 %262, %262
  %265 = and i64 %264, %263
  %266 = add i64 %265, %262
  %267 = sub i64 %266, %262
  store i64 %267, ptr %2, align 8
  br label %92

268:                                              ; preds = %149
  %269 = load i64, ptr %2, align 8
  %270 = zext i32 %0 to i64
  %271 = sub i64 %269, %269
  %272 = xor i64 %271, %269
  %273 = and i64 %272, %269
  store i64 %273, ptr %2, align 8
  br label %92

274:                                              ; preds = %162
  %275 = load i64, ptr %2, align 8
  %276 = zext i32 %0 to i64
  %277 = or i64 %275, %275
  %278 = or i64 %277, %276
  %279 = add i64 %278, %276
  %280 = mul i64 %279, %275
  %281 = add i64 %280, %276
  %282 = xor i64 %281, %275
  store i64 %282, ptr %2, align 8
  br label %92

283:                                              ; preds = %174
  %284 = load i64, ptr %2, align 8
  %285 = zext i32 %0 to i64
  %286 = xor i64 %285, %285
  %287 = sub i64 %286, %285
  %288 = or i64 %287, %285
  %289 = or i64 %288, %284
  %290 = sub i64 %289, %284
  store i64 %290, ptr %2, align 8
  br label %92
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
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i64, align 8
  store i32 1010306152, ptr %4, align 4
  br label %10

10:                                               ; preds = %729, %413, %412, %2
  %11 = load i32, ptr %4, align 4
  %12 = sub i32 %11, -85723054
  %13 = mul i32 %12, 175301011
  switch i32 %13, label %413 [
    i32 918216354, label %14
    i32 1833769650, label %28
    i32 1215822442, label %49
    i32 2129762339, label %66
    i32 1272149167, label %88
    i32 1312678045, label %98
    i32 510561044, label %112
    i32 2065707296, label %125
    i32 302503878, label %147
    i32 2135916548, label %164
    i32 54681492, label %174
    i32 1443460422, label %189
    i32 1778137674, label %213
    i32 1824832708, label %224
    i32 1598183446, label %248
    i32 1042331202, label %261
    i32 1655731430, label %271
    i32 1256244593, label %288
    i32 194521383, label %302
    i32 1677421748, label %321
    i32 1126415162, label %335
    i32 937701960, label %347
    i32 922775013, label %411
    i32 1241192014, label %430
    i32 6537712, label %441
    i32 1576190514, label %454
    i32 519195531, label %467
    i32 274904136, label %480
    i32 685281370, label %502
    i32 1479816577, label %515
    i32 2133732970, label %526
  ]

14:                                               ; preds = %10
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %15 = load i32, ptr %6, align 4
  %16 = icmp ne i32 %15, 6
  %17 = select i1 %16, i32 1677240856, i32 1752301184
  store i32 %17, ptr %4, align 4
  %18 = xor i32 %1, 1853533495
  %19 = and i32 %1, %18
  %20 = or i32 %1, %18
  %21 = xor i32 %1, %18
  %22 = mul i32 %20, 2
  %23 = sub i32 %22, %21
  %24 = sub i32 %23, %1
  %25 = sub i32 %24, %18
  %26 = mul i32 %25, 239
  %27 = icmp eq i32 %26, 0
  br i1 %27, label %412, label %547

28:                                               ; preds = %10
  %29 = call i32 (ptr, ...) @printf(ptr noundef @.str.6)
  store i32 -1042287111, ptr %4, align 4
  %30 = xor i32 %1, -2116874057
  %31 = and i32 %1, %30
  %32 = or i32 %1, %30
  %33 = xor i32 %1, %30
  %34 = add i32 %1, %30
  %35 = sub i32 %34, %33
  %36 = mul i32 %31, 2
  %37 = sub i32 %35, %36
  %38 = mul i32 %37, 252
  %39 = xor i32 %1, 315820213
  %40 = and i32 %1, %39
  %41 = or i32 %1, %39
  %42 = xor i32 %1, %39
  %43 = mul i32 %41, 2
  %44 = sub i32 %43, %42
  %45 = sub i32 %44, %1
  %46 = sub i32 %45, %39
  %47 = mul i32 %46, 86
  %48 = icmp ne i32 %38, %47
  br i1 %48, label %554, label %412

49:                                               ; preds = %10
  %50 = load ptr, ptr %5, align 8
  %51 = getelementptr inbounds ptr, ptr %50, i64 1
  %52 = load ptr, ptr %51, align 8
  %53 = call i32 @parseIntStrict(ptr noundef %52, ptr noundef %7)
  %54 = icmp ne i32 %53, 0
  %55 = select i1 %54, i32 1185726851, i32 1575221831
  store i32 %55, ptr %4, align 4
  %56 = xor i32 %1, 418300763
  %57 = and i32 %1, %56
  %58 = or i32 %1, %56
  %59 = xor i32 %1, %56
  %60 = add i32 %1, %56
  %61 = sub i32 %60, %59
  %62 = mul i32 %57, 2
  %63 = sub i32 %61, %62
  %64 = mul i32 %63, 91
  %65 = icmp slt i32 %64, 1
  br i1 %65, label %412, label %561

66:                                               ; preds = %10
  %67 = load i32, ptr %7, align 4
  %68 = icmp sle i32 %67, 0
  %69 = select i1 %68, i32 1575221831, i32 -1157346463
  store i32 %69, ptr %4, align 4
  %70 = xor i32 %1, 1651914815
  %71 = and i32 %1, %70
  %72 = or i32 %1, %70
  %73 = xor i32 %1, %70
  %74 = add i32 %71, %72
  %75 = sub i32 %74, %1
  %76 = sub i32 %75, %70
  %77 = mul i32 %76, 55
  %78 = xor i32 %1, 956925337
  %79 = and i32 %1, %78
  %80 = or i32 %1, %78
  %81 = xor i32 %1, %78
  %82 = mul i32 %80, 2
  %83 = sub i32 %82, %81
  %84 = sub i32 %83, %1
  %85 = sub i32 %84, %78
  %86 = mul i32 %85, 117
  %87 = icmp ne i32 %77, %86
  br i1 %87, label %571, label %412

88:                                               ; preds = %10
  %89 = call i32 (ptr, ...) @printf(ptr noundef @.str.7)
  store i32 -1042287111, ptr %4, align 4
  %90 = xor i32 %1, -1316556915
  %91 = and i32 %1, %90
  %92 = or i32 %1, %90
  %93 = xor i32 %1, %90
  %94 = sub i32 %92, %93
  %95 = sub i32 %94, %91
  %96 = mul i32 %95, 68
  %97 = icmp sle i32 %96, 0
  br i1 %97, label %412, label %578

98:                                               ; preds = %10
  %99 = load i32, ptr %7, align 4
  %100 = call i32 @findProductIndexById(i32 noundef %99)
  %101 = icmp ne i32 %100, -1
  %102 = select i1 %101, i32 -1823081106, i32 303183538
  store i32 %102, ptr %4, align 4
  %103 = xor i32 %1, 1836001579
  %104 = and i32 %1, %103
  %105 = or i32 %1, %103
  %106 = xor i32 %1, %103
  %107 = add i32 %104, %105
  %108 = sub i32 %107, %1
  %109 = sub i32 %108, %103
  %110 = mul i32 %109, 245
  %111 = icmp slt i32 %110, 1
  br i1 %111, label %412, label %587

112:                                              ; preds = %10
  %113 = load i32, ptr %7, align 4
  %114 = call i32 (ptr, ...) @printf(ptr noundef @.str.8, i32 noundef %113)
  store i32 -1042287111, ptr %4, align 4
  %115 = xor i32 %1, -1863397473
  %116 = and i32 %1, %115
  %117 = or i32 %1, %115
  %118 = xor i32 %1, %115
  %119 = mul i32 %117, 2
  %120 = sub i32 %119, %118
  %121 = sub i32 %120, %1
  %122 = sub i32 %121, %115
  %123 = mul i32 %122, 74
  %124 = icmp slt i32 %123, 1
  br i1 %124, label %412, label %594

125:                                              ; preds = %10
  %126 = load ptr, ptr %5, align 8
  %127 = getelementptr inbounds ptr, ptr %126, i64 2
  %128 = load ptr, ptr %127, align 8
  %129 = call i64 @strlen(ptr noundef %128) #8
  %130 = icmp eq i64 %129, 0
  %131 = select i1 %130, i32 964168382, i32 135591220
  store i32 %131, ptr %4, align 4
  %132 = xor i32 %1, -129258191
  %133 = and i32 %1, %132
  %134 = or i32 %1, %132
  %135 = xor i32 %1, %132
  %136 = sub i32 %134, %135
  %137 = sub i32 %136, %133
  %138 = mul i32 %137, 100
  %139 = xor i32 %1, 2136080313
  %140 = and i32 %1, %139
  %141 = or i32 %1, %139
  %142 = xor i32 %1, %139
  %143 = sub i32 %141, %142
  %144 = sub i32 %143, %140
  %145 = mul i32 %144, 2
  %146 = icmp ne i32 %138, %145
  br i1 %146, label %604, label %412

147:                                              ; preds = %10
  %148 = load ptr, ptr %5, align 8
  %149 = getelementptr inbounds ptr, ptr %148, i64 2
  %150 = load ptr, ptr %149, align 8
  %151 = call i64 @strlen(ptr noundef %150) #8
  %152 = icmp uge i64 %151, 80
  %153 = select i1 %152, i32 964168382, i32 2090444526
  store i32 %153, ptr %4, align 4
  %154 = xor i32 %1, -1685595799
  %155 = and i32 %1, %154
  %156 = or i32 %1, %154
  %157 = xor i32 %1, %154
  %158 = mul i32 %156, 2
  %159 = sub i32 %158, %157
  %160 = sub i32 %159, %1
  %161 = sub i32 %160, %154
  %162 = mul i32 %161, 121
  %163 = icmp uge i32 %162, 0
  br i1 %163, label %412, label %613

164:                                              ; preds = %10
  %165 = call i32 (ptr, ...) @printf(ptr noundef @.str.9)
  store i32 -1042287111, ptr %4, align 4
  %166 = xor i32 %1, -366382329
  %167 = and i32 %1, %166
  %168 = or i32 %1, %166
  %169 = xor i32 %1, %166
  %170 = sub i32 %168, %169
  %171 = sub i32 %170, %167
  %172 = mul i32 %171, 161
  %173 = icmp sle i32 %172, 0
  br i1 %173, label %412, label %622

174:                                              ; preds = %10
  %175 = load ptr, ptr %5, align 8
  %176 = getelementptr inbounds ptr, ptr %175, i64 3
  %177 = load ptr, ptr %176, align 8
  %178 = call i64 @strlen(ptr noundef %177) #8
  %179 = icmp eq i64 %178, 0
  %180 = select i1 %179, i32 -2131219680, i32 815092148
  store i32 %180, ptr %4, align 4
  %181 = xor i32 %1, -1560781435
  %182 = and i32 %1, %181
  %183 = or i32 %1, %181
  %184 = xor i32 %1, %181
  %185 = sub i32 %183, %184
  %186 = sub i32 %185, %182
  %187 = mul i32 %186, 127
  %188 = icmp eq i32 %187, 0
  br i1 %188, label %412, label %631

189:                                              ; preds = %10
  %190 = load ptr, ptr %5, align 8
  %191 = getelementptr inbounds ptr, ptr %190, i64 3
  %192 = load ptr, ptr %191, align 8
  %193 = call i64 @strlen(ptr noundef %192) #8
  %194 = icmp uge i64 %193, 50
  %195 = select i1 %194, i32 -2131219680, i32 -2144414978
  store i32 %195, ptr %4, align 4
  %196 = xor i32 %1, 789607609
  %197 = and i32 %1, %196
  %198 = or i32 %1, %196
  %199 = xor i32 %1, %196
  %200 = add i32 %197, %198
  %201 = sub i32 %200, %1
  %202 = sub i32 %201, %196
  %203 = mul i32 %202, 27
  %204 = xor i32 %1, 88994501
  %205 = and i32 %1, %204
  %206 = or i32 %1, %204
  %207 = xor i32 %1, %204
  %208 = add i32 %205, %206
  %209 = sub i32 %208, %1
  %210 = sub i32 %209, %204
  %211 = mul i32 %210, 245
  %212 = icmp eq i32 %203, %211
  br i1 %212, label %412, label %638

213:                                              ; preds = %10
  %214 = call i32 (ptr, ...) @printf(ptr noundef @.str.10)
  store i32 -1042287111, ptr %4, align 4
  %215 = xor i32 %1, -82783993
  %216 = and i32 %1, %215
  %217 = or i32 %1, %215
  %218 = xor i32 %1, %215
  %219 = add i32 %216, %217
  %220 = sub i32 %219, %1
  %221 = sub i32 %220, %215
  %222 = mul i32 %221, 252
  %223 = icmp slt i32 %222, 0
  br i1 %223, label %646, label %412

224:                                              ; preds = %10
  %225 = load ptr, ptr %5, align 8
  %226 = getelementptr inbounds ptr, ptr %225, i64 4
  %227 = load ptr, ptr %226, align 8
  %228 = call i32 @parseMoneyStrict(ptr noundef %227, ptr noundef %9)
  %229 = icmp ne i32 %228, 0
  %230 = select i1 %229, i32 -916462172, i32 -1935926712
  store i32 %230, ptr %4, align 4
  %231 = xor i32 %1, 1228902779
  %232 = and i32 %1, %231
  %233 = or i32 %1, %231
  %234 = xor i32 %1, %231
  %235 = mul i32 %233, 2
  %236 = sub i32 %235, %234
  %237 = sub i32 %236, %1
  %238 = sub i32 %237, %231
  %239 = mul i32 %238, 219
  %240 = xor i32 %1, 726985113
  %241 = and i32 %1, %240
  %242 = or i32 %1, %240
  %243 = xor i32 %1, %240
  %244 = sub i32 %242, %243
  %245 = sub i32 %244, %241
  %246 = mul i32 %245, 116
  %247 = icmp ne i32 %239, %246
  br i1 %247, label %653, label %412

248:                                              ; preds = %10
  %249 = load i64, ptr %9, align 8
  %250 = icmp sle i64 %249, 0
  %251 = select i1 %250, i32 -1935926712, i32 -2096326764
  store i32 %251, ptr %4, align 4
  %252 = xor i32 %1, 1847698671
  %253 = and i32 %1, %252
  %254 = or i32 %1, %252
  %255 = xor i32 %1, %252
  %256 = add i32 %253, %254
  %257 = sub i32 %256, %1
  %258 = sub i32 %257, %252
  %259 = mul i32 %258, 10
  %260 = icmp sle i32 %259, 0
  br i1 %260, label %412, label %660

261:                                              ; preds = %10
  %262 = call i32 (ptr, ...) @printf(ptr noundef @.str.11)
  store i32 -1042287111, ptr %4, align 4
  %263 = xor i32 %1, -1562943139
  %264 = and i32 %1, %263
  %265 = or i32 %1, %263
  %266 = xor i32 %1, %263
  %267 = sub i32 %265, %266
  %268 = sub i32 %267, %264
  %269 = mul i32 %268, 187
  %270 = icmp uge i32 %269, 0
  br i1 %270, label %412, label %670

271:                                              ; preds = %10
  %272 = load ptr, ptr %5, align 8
  %273 = getelementptr inbounds ptr, ptr %272, i64 5
  %274 = load ptr, ptr %273, align 8
  %275 = call i32 @parseIntStrict(ptr noundef %274, ptr noundef %8)
  %276 = icmp ne i32 %275, 0
  %277 = select i1 %276, i32 -248010819, i32 932978415
  store i32 %277, ptr %4, align 4
  %278 = xor i32 %1, 1386204971
  %279 = and i32 %1, %278
  %280 = or i32 %1, %278
  %281 = xor i32 %1, %278
  %282 = add i32 %1, %278
  %283 = sub i32 %282, %281
  %284 = mul i32 %279, 2
  %285 = sub i32 %283, %284
  %286 = mul i32 %285, 48
  %287 = icmp sle i32 %286, 0
  br i1 %287, label %412, label %679

288:                                              ; preds = %10
  %289 = load i32, ptr %8, align 4
  %290 = icmp slt i32 %289, 0
  %291 = select i1 %290, i32 932978415, i32 1564809550
  store i32 %291, ptr %4, align 4
  %292 = xor i32 %1, -1462080577
  %293 = and i32 %1, %292
  %294 = or i32 %1, %292
  %295 = xor i32 %1, %292
  %296 = add i32 %1, %292
  %297 = sub i32 %296, %295
  %298 = mul i32 %293, 2
  %299 = sub i32 %297, %298
  %300 = mul i32 %299, 98
  %301 = icmp slt i32 %300, 1
  br i1 %301, label %412, label %689

302:                                              ; preds = %10
  %303 = call i32 (ptr, ...) @printf(ptr noundef @.str.12)
  store i32 -1042287111, ptr %4, align 4
  %304 = xor i32 %1, 1385752695
  %305 = and i32 %1, %304
  %306 = or i32 %1, %304
  %307 = xor i32 %1, %304
  %308 = sub i32 %306, %307
  %309 = sub i32 %308, %305
  %310 = mul i32 %309, 86
  %311 = xor i32 %1, -1887172743
  %312 = and i32 %1, %311
  %313 = or i32 %1, %311
  %314 = xor i32 %1, %311
  %315 = add i32 %1, %311
  %316 = sub i32 %315, %314
  %317 = mul i32 %312, 2
  %318 = sub i32 %316, %317
  %319 = mul i32 %318, 16
  %320 = icmp eq i32 %310, %319
  br i1 %320, label %412, label %699

321:                                              ; preds = %10
  %322 = load i32, ptr @productCount, align 4
  %323 = icmp sge i32 %322, 1000
  %324 = select i1 %323, i32 -662635408, i32 -611153430
  store i32 %324, ptr %4, align 4
  %325 = xor i32 %1, -1343969201
  %326 = and i32 %1, %325
  %327 = or i32 %1, %325
  %328 = xor i32 %1, %325
  %329 = add i32 %1, %325
  %330 = sub i32 %329, %328
  %331 = mul i32 %326, 2
  %332 = sub i32 %330, %331
  %333 = mul i32 %332, 69
  %334 = icmp ne i32 %333, 0
  br i1 %334, label %706, label %412

335:                                              ; preds = %10
  %336 = call i32 (ptr, ...) @printf(ptr noundef @.str.13)
  store i32 -1042287111, ptr %4, align 4
  %337 = xor i32 %1, 225224385
  %338 = and i32 %1, %337
  %339 = or i32 %1, %337
  %340 = xor i32 %1, %337
  %341 = mul i32 %339, 2
  %342 = sub i32 %341, %340
  %343 = sub i32 %342, %1
  %344 = sub i32 %343, %337
  %345 = mul i32 %344, 136
  %346 = icmp ne i32 %345, 0
  br i1 %346, label %715, label %412

347:                                              ; preds = %10
  %348 = load i32, ptr %7, align 4
  %349 = load i32, ptr @productCount, align 4
  %350 = sext i32 %349 to i64
  %351 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %350
  %352 = getelementptr inbounds nuw %struct.Product, ptr %351, i32 0, i32 0
  store i32 %348, ptr %352, align 16
  %353 = load i32, ptr @productCount, align 4
  %354 = sext i32 %353 to i64
  %355 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %354
  %356 = getelementptr inbounds nuw %struct.Product, ptr %355, i32 0, i32 1
  %357 = getelementptr inbounds [80 x i8], ptr %356, i64 0, i64 0
  %358 = load ptr, ptr %5, align 8
  %359 = getelementptr inbounds ptr, ptr %358, i64 2
  %360 = load ptr, ptr %359, align 8
  %361 = call ptr @strcpy(ptr noundef %357, ptr noundef %360) #9
  %362 = load i32, ptr @productCount, align 4
  %363 = sext i32 %362 to i64
  %364 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %363
  %365 = getelementptr inbounds nuw %struct.Product, ptr %364, i32 0, i32 2
  %366 = getelementptr inbounds [50 x i8], ptr %365, i64 0, i64 0
  %367 = load ptr, ptr %5, align 8
  %368 = getelementptr inbounds ptr, ptr %367, i64 3
  %369 = load ptr, ptr %368, align 8
  %370 = call ptr @strcpy(ptr noundef %366, ptr noundef %369) #9
  %371 = load i64, ptr %9, align 8
  %372 = load i32, ptr @productCount, align 4
  %373 = sext i32 %372 to i64
  %374 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %373
  %375 = getelementptr inbounds nuw %struct.Product, ptr %374, i32 0, i32 3
  store i64 %371, ptr %375, align 8
  %376 = load i32, ptr %8, align 4
  %377 = load i32, ptr @productCount, align 4
  %378 = sext i32 %377 to i64
  %379 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %378
  %380 = getelementptr inbounds nuw %struct.Product, ptr %379, i32 0, i32 4
  store i32 %376, ptr %380, align 16
  %381 = load i32, ptr @productCount, align 4
  %382 = sext i32 %381 to i64
  %383 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %382
  %384 = getelementptr inbounds nuw %struct.Product, ptr %383, i32 0, i32 5
  store i32 0, ptr %384, align 4
  %385 = load i32, ptr @productCount, align 4
  %386 = sext i32 %385 to i64
  %387 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %386
  %388 = getelementptr inbounds nuw %struct.Product, ptr %387, i32 0, i32 6
  store i32 1, ptr %388, align 8
  %389 = load i32, ptr @productCount, align 4
  %390 = load i32, ptr %4, align 4
  %391 = xor i32 %390, -611153429
  %392 = or i32 %389, %391
  %393 = load i32, ptr %4, align 4
  %394 = xor i32 %393, -611153429
  %395 = and i32 %389, %394
  %396 = add i32 %392, %395
  store i32 %396, ptr @productCount, align 4
  %397 = load i32, ptr %7, align 4
  %398 = load ptr, ptr %5, align 8
  %399 = getelementptr inbounds ptr, ptr %398, i64 2
  %400 = load ptr, ptr %399, align 8
  %401 = call i32 (ptr, ...) @printf(ptr noundef @.str.14, i32 noundef %397, ptr noundef %400)
  store i32 -1042287111, ptr %4, align 4
  %402 = xor i32 %1, 879450891
  %403 = and i32 %1, %402
  %404 = or i32 %1, %402
  %405 = xor i32 %1, %402
  %406 = add i32 %403, %404
  %407 = sub i32 %406, %1
  %408 = sub i32 %407, %402
  %409 = mul i32 %408, 156
  %410 = icmp ne i32 %409, 0
  br i1 %410, label %722, label %412

411:                                              ; preds = %10
  ret void

412:                                              ; preds = %791, %784, %774, %766, %759, %751, %743, %736, %722, %715, %706, %699, %689, %679, %670, %660, %653, %646, %638, %631, %622, %613, %604, %594, %587, %578, %571, %561, %554, %547, %526, %515, %502, %480, %467, %454, %441, %430, %347, %335, %321, %302, %288, %271, %261, %248, %224, %213, %189, %174, %164, %147, %125, %112, %98, %88, %66, %49, %28, %14
  br label %10

413:                                              ; preds = %10
  store i32 1010306152, ptr %4, align 4
  call void asm sideeffect "", ""()
  %414 = xor i32 %1, 1813307359
  %415 = and i32 %1, %414
  %416 = or i32 %1, %414
  %417 = xor i32 %1, %414
  %418 = add i32 %415, %416
  %419 = sub i32 %418, %1
  %420 = sub i32 %419, %414
  %421 = mul i32 %420, 33
  %422 = xor i32 %1, 1902046799
  %423 = and i32 %1, %422
  %424 = or i32 %1, %422
  %425 = xor i32 %1, %422
  %426 = sub i32 %424, %425
  %427 = sub i32 %426, %423
  %428 = mul i32 %427, 100
  %429 = icmp eq i32 %421, %428
  br i1 %429, label %10, label %729

430:                                              ; preds = %10
  %431 = load i32, ptr %4, align 4
  %432 = xor i32 %431, -713252097
  store i32 %432, ptr %4, align 4
  %433 = xor i32 %1, -1944577313
  %434 = and i32 %1, %433
  %435 = or i32 %1, %433
  %436 = xor i32 %1, %433
  %437 = sub i32 %435, %436
  %438 = sub i32 %437, %434
  %439 = mul i32 %438, 193
  %440 = icmp slt i32 %439, 1
  br i1 %440, label %412, label %736

441:                                              ; preds = %10
  %442 = load i32, ptr %4, align 4
  %443 = xor i32 %442, 418431095
  store i32 %443, ptr %4, align 4
  %444 = xor i32 %1, 1264269709
  %445 = and i32 %1, %444
  %446 = or i32 %1, %444
  %447 = xor i32 %1, %444
  %448 = mul i32 %446, 2
  %449 = sub i32 %448, %447
  %450 = sub i32 %449, %1
  %451 = sub i32 %450, %444
  %452 = mul i32 %451, 198
  %453 = icmp slt i32 %452, 0
  br i1 %453, label %743, label %412

454:                                              ; preds = %10
  %455 = load i32, ptr %4, align 4
  %456 = xor i32 %455, 2141811005
  store i32 %456, ptr %4, align 4
  %457 = xor i32 %1, 1993992501
  %458 = and i32 %1, %457
  %459 = or i32 %1, %457
  %460 = xor i32 %1, %457
  %461 = add i32 %1, %457
  %462 = sub i32 %461, %460
  %463 = mul i32 %458, 2
  %464 = sub i32 %462, %463
  %465 = mul i32 %464, 40
  %466 = icmp sgt i32 %465, 0
  br i1 %466, label %751, label %412

467:                                              ; preds = %10
  %468 = load i32, ptr %4, align 4
  %469 = xor i32 %468, -139334530
  store i32 %469, ptr %4, align 4
  %470 = xor i32 %1, 19275739
  %471 = and i32 %1, %470
  %472 = or i32 %1, %470
  %473 = xor i32 %1, %470
  %474 = add i32 %1, %470
  %475 = sub i32 %474, %473
  %476 = mul i32 %471, 2
  %477 = sub i32 %475, %476
  %478 = mul i32 %477, 65
  %479 = icmp slt i32 %478, 1
  br i1 %479, label %412, label %759

480:                                              ; preds = %10
  %481 = load i32, ptr %4, align 4
  %482 = xor i32 %481, 1587664561
  store i32 %482, ptr %4, align 4
  %483 = xor i32 %1, -1935758691
  %484 = and i32 %1, %483
  %485 = or i32 %1, %483
  %486 = xor i32 %1, %483
  %487 = mul i32 %485, 2
  %488 = sub i32 %487, %486
  %489 = sub i32 %488, %1
  %490 = sub i32 %489, %483
  %491 = mul i32 %490, 134
  %492 = xor i32 %1, -1862353141
  %493 = and i32 %1, %492
  %494 = or i32 %1, %492
  %495 = xor i32 %1, %492
  %496 = mul i32 %494, 2
  %497 = sub i32 %496, %495
  %498 = sub i32 %497, %1
  %499 = sub i32 %498, %492
  %500 = mul i32 %499, 191
  %501 = icmp ne i32 %491, %500
  br i1 %501, label %766, label %412

502:                                              ; preds = %10
  %503 = load i32, ptr %4, align 4
  %504 = xor i32 %503, -1140217390
  store i32 %504, ptr %4, align 4
  %505 = xor i32 %1, -889744245
  %506 = and i32 %1, %505
  %507 = or i32 %1, %505
  %508 = xor i32 %1, %505
  %509 = add i32 %1, %505
  %510 = sub i32 %509, %508
  %511 = mul i32 %506, 2
  %512 = sub i32 %510, %511
  %513 = mul i32 %512, 21
  %514 = icmp ne i32 %513, 0
  br i1 %514, label %774, label %412

515:                                              ; preds = %10
  %516 = load i32, ptr %4, align 4
  %517 = xor i32 %516, -1060805180
  store i32 %517, ptr %4, align 4
  %518 = xor i32 %1, -1842775519
  %519 = and i32 %1, %518
  %520 = or i32 %1, %518
  %521 = xor i32 %1, %518
  %522 = sub i32 %520, %521
  %523 = sub i32 %522, %519
  %524 = mul i32 %523, 169
  %525 = icmp sgt i32 %524, 0
  br i1 %525, label %784, label %412

526:                                              ; preds = %10
  %527 = load i32, ptr %4, align 4
  %528 = xor i32 %527, -1344192773
  store i32 %528, ptr %4, align 4
  %529 = xor i32 %1, -1253475427
  %530 = and i32 %1, %529
  %531 = or i32 %1, %529
  %532 = xor i32 %1, %529
  %533 = add i32 %1, %529
  %534 = sub i32 %533, %532
  %535 = mul i32 %530, 2
  %536 = sub i32 %534, %535
  %537 = mul i32 %536, 204
  %538 = xor i32 %1, 375933829
  %539 = and i32 %1, %538
  %540 = or i32 %1, %538
  %541 = xor i32 %1, %538
  %542 = add i32 %539, %540
  %543 = sub i32 %542, %1
  %544 = sub i32 %543, %538
  %545 = mul i32 %544, 195
  %546 = icmp eq i32 %537, %545
  br i1 %546, label %412, label %791

547:                                              ; preds = %14
  %548 = load i64, ptr %3, align 8
  %549 = ptrtoint ptr %0 to i64
  %550 = zext i32 %1 to i64
  %551 = xor i64 %548, %549
  %552 = mul i64 %551, %549
  %553 = xor i64 %552, %549
  store i64 %553, ptr %3, align 8
  br label %412

554:                                              ; preds = %28
  %555 = load i64, ptr %3, align 8
  %556 = ptrtoint ptr %0 to i64
  %557 = zext i32 %1 to i64
  %558 = mul i64 %555, %555
  %559 = xor i64 %558, %557
  %560 = or i64 %559, %557
  store i64 %560, ptr %3, align 8
  br label %412

561:                                              ; preds = %49
  %562 = load i64, ptr %3, align 8
  %563 = ptrtoint ptr %0 to i64
  %564 = zext i32 %1 to i64
  %565 = or i64 %564, %564
  %566 = or i64 %565, %564
  %567 = mul i64 %566, %563
  %568 = or i64 %567, %562
  %569 = add i64 %568, %564
  %570 = and i64 %569, %562
  store i64 %570, ptr %3, align 8
  br label %412

571:                                              ; preds = %66
  %572 = load i64, ptr %3, align 8
  %573 = ptrtoint ptr %0 to i64
  %574 = zext i32 %1 to i64
  %575 = mul i64 %572, %573
  %576 = xor i64 %575, %573
  %577 = sub i64 %576, %573
  store i64 %577, ptr %3, align 8
  br label %412

578:                                              ; preds = %88
  %579 = load i64, ptr %3, align 8
  %580 = ptrtoint ptr %0 to i64
  %581 = zext i32 %1 to i64
  %582 = add i64 %579, %579
  %583 = add i64 %582, %580
  %584 = or i64 %583, %580
  %585 = add i64 %584, %581
  %586 = sub i64 %585, %581
  store i64 %586, ptr %3, align 8
  br label %412

587:                                              ; preds = %98
  %588 = load i64, ptr %3, align 8
  %589 = ptrtoint ptr %0 to i64
  %590 = zext i32 %1 to i64
  %591 = xor i64 %589, %588
  %592 = mul i64 %591, %590
  %593 = sub i64 %592, %588
  store i64 %593, ptr %3, align 8
  br label %412

594:                                              ; preds = %112
  %595 = load i64, ptr %3, align 8
  %596 = ptrtoint ptr %0 to i64
  %597 = zext i32 %1 to i64
  %598 = and i64 %596, %595
  %599 = xor i64 %598, %597
  %600 = add i64 %599, %595
  %601 = mul i64 %600, %597
  %602 = add i64 %601, %595
  %603 = add i64 %602, %596
  store i64 %603, ptr %3, align 8
  br label %412

604:                                              ; preds = %125
  %605 = load i64, ptr %3, align 8
  %606 = ptrtoint ptr %0 to i64
  %607 = zext i32 %1 to i64
  %608 = add i64 %607, %607
  %609 = or i64 %608, %607
  %610 = and i64 %609, %606
  %611 = add i64 %610, %606
  %612 = mul i64 %611, %607
  store i64 %612, ptr %3, align 8
  br label %412

613:                                              ; preds = %147
  %614 = load i64, ptr %3, align 8
  %615 = ptrtoint ptr %0 to i64
  %616 = zext i32 %1 to i64
  %617 = mul i64 %616, %614
  %618 = mul i64 %617, %615
  %619 = sub i64 %618, %616
  %620 = and i64 %619, %616
  %621 = mul i64 %620, %616
  store i64 %621, ptr %3, align 8
  br label %412

622:                                              ; preds = %164
  %623 = load i64, ptr %3, align 8
  %624 = ptrtoint ptr %0 to i64
  %625 = zext i32 %1 to i64
  %626 = add i64 %624, %623
  %627 = xor i64 %626, %624
  %628 = add i64 %627, %625
  %629 = sub i64 %628, %624
  %630 = and i64 %629, %624
  store i64 %630, ptr %3, align 8
  br label %412

631:                                              ; preds = %174
  %632 = load i64, ptr %3, align 8
  %633 = ptrtoint ptr %0 to i64
  %634 = zext i32 %1 to i64
  %635 = add i64 %633, %633
  %636 = add i64 %635, %633
  %637 = or i64 %636, %634
  store i64 %637, ptr %3, align 8
  br label %412

638:                                              ; preds = %189
  %639 = load i64, ptr %3, align 8
  %640 = ptrtoint ptr %0 to i64
  %641 = zext i32 %1 to i64
  %642 = add i64 %639, %640
  %643 = mul i64 %642, %640
  %644 = mul i64 %643, %640
  %645 = xor i64 %644, %641
  store i64 %645, ptr %3, align 8
  br label %412

646:                                              ; preds = %213
  %647 = load i64, ptr %3, align 8
  %648 = ptrtoint ptr %0 to i64
  %649 = zext i32 %1 to i64
  %650 = add i64 %648, %649
  %651 = mul i64 %650, %649
  %652 = sub i64 %651, %649
  store i64 %652, ptr %3, align 8
  br label %412

653:                                              ; preds = %224
  %654 = load i64, ptr %3, align 8
  %655 = ptrtoint ptr %0 to i64
  %656 = zext i32 %1 to i64
  %657 = xor i64 %656, %656
  %658 = or i64 %657, %656
  %659 = add i64 %658, %656
  store i64 %659, ptr %3, align 8
  br label %412

660:                                              ; preds = %248
  %661 = load i64, ptr %3, align 8
  %662 = ptrtoint ptr %0 to i64
  %663 = zext i32 %1 to i64
  %664 = xor i64 %663, %661
  %665 = sub i64 %664, %663
  %666 = and i64 %665, %663
  %667 = xor i64 %666, %661
  %668 = and i64 %667, %661
  %669 = and i64 %668, %661
  store i64 %669, ptr %3, align 8
  br label %412

670:                                              ; preds = %261
  %671 = load i64, ptr %3, align 8
  %672 = ptrtoint ptr %0 to i64
  %673 = zext i32 %1 to i64
  %674 = and i64 %673, %673
  %675 = add i64 %674, %671
  %676 = xor i64 %675, %673
  %677 = and i64 %676, %672
  %678 = xor i64 %677, %672
  store i64 %678, ptr %3, align 8
  br label %412

679:                                              ; preds = %271
  %680 = load i64, ptr %3, align 8
  %681 = ptrtoint ptr %0 to i64
  %682 = zext i32 %1 to i64
  %683 = sub i64 %682, %681
  %684 = xor i64 %683, %682
  %685 = or i64 %684, %681
  %686 = or i64 %685, %681
  %687 = xor i64 %686, %681
  %688 = sub i64 %687, %680
  store i64 %688, ptr %3, align 8
  br label %412

689:                                              ; preds = %288
  %690 = load i64, ptr %3, align 8
  %691 = ptrtoint ptr %0 to i64
  %692 = zext i32 %1 to i64
  %693 = and i64 %690, %691
  %694 = add i64 %693, %691
  %695 = mul i64 %694, %690
  %696 = mul i64 %695, %690
  %697 = mul i64 %696, %691
  %698 = or i64 %697, %690
  store i64 %698, ptr %3, align 8
  br label %412

699:                                              ; preds = %302
  %700 = load i64, ptr %3, align 8
  %701 = ptrtoint ptr %0 to i64
  %702 = zext i32 %1 to i64
  %703 = sub i64 %700, %702
  %704 = and i64 %703, %701
  %705 = add i64 %704, %700
  store i64 %705, ptr %3, align 8
  br label %412

706:                                              ; preds = %321
  %707 = load i64, ptr %3, align 8
  %708 = ptrtoint ptr %0 to i64
  %709 = zext i32 %1 to i64
  %710 = and i64 %707, %707
  %711 = add i64 %710, %709
  %712 = sub i64 %711, %709
  %713 = and i64 %712, %708
  %714 = xor i64 %713, %709
  store i64 %714, ptr %3, align 8
  br label %412

715:                                              ; preds = %335
  %716 = load i64, ptr %3, align 8
  %717 = ptrtoint ptr %0 to i64
  %718 = zext i32 %1 to i64
  %719 = sub i64 %716, %718
  %720 = xor i64 %719, %718
  %721 = mul i64 %720, %716
  store i64 %721, ptr %3, align 8
  br label %412

722:                                              ; preds = %347
  %723 = load i64, ptr %3, align 8
  %724 = ptrtoint ptr %0 to i64
  %725 = zext i32 %1 to i64
  %726 = mul i64 %724, %724
  %727 = xor i64 %726, %723
  %728 = or i64 %727, %724
  store i64 %728, ptr %3, align 8
  br label %412

729:                                              ; preds = %413
  %730 = load i64, ptr %3, align 8
  %731 = ptrtoint ptr %0 to i64
  %732 = zext i32 %1 to i64
  %733 = xor i64 %731, %731
  %734 = sub i64 %733, %730
  %735 = sub i64 %734, %730
  store i64 %735, ptr %3, align 8
  br label %10

736:                                              ; preds = %430
  %737 = load i64, ptr %3, align 8
  %738 = ptrtoint ptr %0 to i64
  %739 = zext i32 %1 to i64
  %740 = add i64 %738, %738
  %741 = and i64 %740, %739
  %742 = add i64 %741, %737
  store i64 %742, ptr %3, align 8
  br label %412

743:                                              ; preds = %441
  %744 = load i64, ptr %3, align 8
  %745 = ptrtoint ptr %0 to i64
  %746 = zext i32 %1 to i64
  %747 = add i64 %745, %746
  %748 = and i64 %747, %745
  %749 = mul i64 %748, %746
  %750 = add i64 %749, %744
  store i64 %750, ptr %3, align 8
  br label %412

751:                                              ; preds = %454
  %752 = load i64, ptr %3, align 8
  %753 = ptrtoint ptr %0 to i64
  %754 = zext i32 %1 to i64
  %755 = xor i64 %753, %753
  %756 = sub i64 %755, %753
  %757 = mul i64 %756, %754
  %758 = and i64 %757, %753
  store i64 %758, ptr %3, align 8
  br label %412

759:                                              ; preds = %467
  %760 = load i64, ptr %3, align 8
  %761 = ptrtoint ptr %0 to i64
  %762 = zext i32 %1 to i64
  %763 = mul i64 %760, %760
  %764 = add i64 %763, %760
  %765 = add i64 %764, %762
  store i64 %765, ptr %3, align 8
  br label %412

766:                                              ; preds = %480
  %767 = load i64, ptr %3, align 8
  %768 = ptrtoint ptr %0 to i64
  %769 = zext i32 %1 to i64
  %770 = xor i64 %769, %769
  %771 = add i64 %770, %769
  %772 = mul i64 %771, %767
  %773 = mul i64 %772, %769
  store i64 %773, ptr %3, align 8
  br label %412

774:                                              ; preds = %502
  %775 = load i64, ptr %3, align 8
  %776 = ptrtoint ptr %0 to i64
  %777 = zext i32 %1 to i64
  %778 = add i64 %777, %777
  %779 = add i64 %778, %775
  %780 = add i64 %779, %775
  %781 = sub i64 %780, %777
  %782 = mul i64 %781, %776
  %783 = xor i64 %782, %776
  store i64 %783, ptr %3, align 8
  br label %412

784:                                              ; preds = %515
  %785 = load i64, ptr %3, align 8
  %786 = ptrtoint ptr %0 to i64
  %787 = zext i32 %1 to i64
  %788 = add i64 %785, %787
  %789 = xor i64 %788, %787
  %790 = xor i64 %789, %785
  store i64 %790, ptr %3, align 8
  br label %412

791:                                              ; preds = %526
  %792 = load i64, ptr %3, align 8
  %793 = ptrtoint ptr %0 to i64
  %794 = zext i32 %1 to i64
  %795 = or i64 %792, %794
  %796 = sub i64 %795, %794
  %797 = and i64 %796, %792
  %798 = add i64 %797, %792
  %799 = mul i64 %798, %794
  %800 = or i64 %799, %794
  store i64 %800, ptr %3, align 8
  br label %412
}

; Function Attrs: nounwind
declare ptr @strcpy(ptr noundef, ptr noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdRemove(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 1421570952, ptr %4, align 4
  br label %9

9:                                                ; preds = %342, %141, %140, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, -1304910932
  %12 = mul i32 %11, 1643547115
  switch i32 %12, label %141 [
    i32 1220119284, label %13
    i32 1357574639, label %27
    i32 1390033041, label %44
    i32 132297017, label %65
    i32 2083779698, label %81
    i32 918988867, label %94
    i32 1555388589, label %111
    i32 425904553, label %124
    i32 1175874633, label %139
    i32 119658343, label %151
    i32 1391104869, label %163
    i32 1904500248, label %176
    i32 1142805406, label %189
    i32 1517289483, label %202
    i32 1280727443, label %224
    i32 18722798, label %237
    i32 1507140101, label %249
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %14 = load i32, ptr %6, align 4
  %15 = icmp ne i32 %14, 2
  %16 = select i1 %15, i32 -871206881, i32 601175737
  store i32 %16, ptr %4, align 4
  %17 = xor i32 %1, 125904581
  %18 = and i32 %1, %17
  %19 = or i32 %1, %17
  %20 = xor i32 %1, %17
  %21 = add i32 %1, %17
  %22 = sub i32 %21, %20
  %23 = mul i32 %18, 2
  %24 = sub i32 %22, %23
  %25 = mul i32 %24, 109
  %26 = icmp ne i32 %25, 0
  br i1 %26, label %271, label %140

27:                                               ; preds = %9
  %28 = load ptr, ptr %5, align 8
  %29 = getelementptr inbounds ptr, ptr %28, i64 1
  %30 = load ptr, ptr %29, align 8
  %31 = call i32 @parseIntStrict(ptr noundef %30, ptr noundef %7)
  %32 = icmp ne i32 %31, 0
  %33 = select i1 %32, i32 319735831, i32 -871206881
  store i32 %33, ptr %4, align 4
  %34 = xor i32 %1, -2141922069
  %35 = and i32 %1, %34
  %36 = or i32 %1, %34
  %37 = xor i32 %1, %34
  %38 = mul i32 %36, 2
  %39 = sub i32 %38, %37
  %40 = sub i32 %39, %1
  %41 = sub i32 %40, %34
  %42 = mul i32 %41, 130
  %43 = icmp sle i32 %42, 0
  br i1 %43, label %140, label %278

44:                                               ; preds = %9
  %45 = call i32 (ptr, ...) @printf(ptr noundef @.str.15)
  store i32 -11688633, ptr %4, align 4
  %46 = xor i32 %1, 732031579
  %47 = and i32 %1, %46
  %48 = or i32 %1, %46
  %49 = xor i32 %1, %46
  %50 = add i32 %1, %46
  %51 = sub i32 %50, %49
  %52 = mul i32 %47, 2
  %53 = sub i32 %51, %52
  %54 = mul i32 %53, 211
  %55 = xor i32 %1, -224324897
  %56 = and i32 %1, %55
  %57 = or i32 %1, %55
  %58 = xor i32 %1, %55
  %59 = mul i32 %57, 2
  %60 = sub i32 %59, %58
  %61 = sub i32 %60, %1
  %62 = sub i32 %61, %55
  %63 = mul i32 %62, 134
  %64 = icmp ne i32 %54, %63
  br i1 %64, label %286, label %140

65:                                               ; preds = %9
  %66 = load i32, ptr %7, align 4
  %67 = call i32 @findProductIndexById(i32 noundef %66)
  store i32 %67, ptr %8, align 4
  %68 = load i32, ptr %8, align 4
  %69 = icmp eq i32 %68, -1
  %70 = select i1 %69, i32 1898586754, i32 -1913565003
  store i32 %70, ptr %4, align 4
  %71 = xor i32 %1, -1347373601
  %72 = and i32 %1, %71
  %73 = or i32 %1, %71
  %74 = xor i32 %1, %71
  %75 = mul i32 %73, 2
  %76 = sub i32 %75, %74
  %77 = sub i32 %76, %1
  %78 = sub i32 %77, %71
  %79 = mul i32 %78, 69
  %80 = icmp ne i32 %79, 0
  br i1 %80, label %295, label %140

81:                                               ; preds = %9
  %82 = load i32, ptr %7, align 4
  %83 = call i32 (ptr, ...) @printf(ptr noundef @.str.16, i32 noundef %82)
  store i32 -11688633, ptr %4, align 4
  %84 = xor i32 %1, -1107888779
  %85 = and i32 %1, %84
  %86 = or i32 %1, %84
  %87 = xor i32 %1, %84
  %88 = add i32 %1, %84
  %89 = sub i32 %88, %87
  %90 = mul i32 %85, 2
  %91 = sub i32 %89, %90
  %92 = mul i32 %91, 68
  %93 = icmp ugt i32 %92, 0
  br i1 %93, label %305, label %140

94:                                               ; preds = %9
  %95 = load i32, ptr %8, align 4
  %96 = sext i32 %95 to i64
  %97 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %96
  %98 = getelementptr inbounds nuw %struct.Product, ptr %97, i32 0, i32 6
  %99 = load i32, ptr %98, align 8
  %100 = icmp ne i32 %99, 0
  %101 = select i1 %100, i32 1977025895, i32 742739315
  store i32 %101, ptr %4, align 4
  %102 = xor i32 %1, -1848456671
  %103 = and i32 %1, %102
  %104 = or i32 %1, %102
  %105 = xor i32 %1, %102
  %106 = add i32 %103, %104
  %107 = sub i32 %106, %1
  %108 = sub i32 %107, %102
  %109 = mul i32 %108, 219
  %110 = icmp eq i32 %109, 0
  br i1 %110, label %140, label %315

111:                                              ; preds = %9
  %112 = load i32, ptr %7, align 4
  %113 = call i32 (ptr, ...) @printf(ptr noundef @.str.17, i32 noundef %112)
  store i32 -11688633, ptr %4, align 4
  %114 = xor i32 %1, -652623515
  %115 = and i32 %1, %114
  %116 = or i32 %1, %114
  %117 = xor i32 %1, %114
  %118 = add i32 %1, %114
  %119 = sub i32 %118, %117
  %120 = mul i32 %115, 2
  %121 = sub i32 %119, %120
  %122 = mul i32 %121, 134
  %123 = icmp ne i32 %122, 0
  br i1 %123, label %325, label %140

124:                                              ; preds = %9
  %125 = load i32, ptr %8, align 4
  %126 = sext i32 %125 to i64
  %127 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %126
  %128 = getelementptr inbounds nuw %struct.Product, ptr %127, i32 0, i32 6
  store i32 0, ptr %128, align 8
  %129 = load i32, ptr %7, align 4
  %130 = call i32 (ptr, ...) @printf(ptr noundef @.str.18, i32 noundef %129)
  store i32 -11688633, ptr %4, align 4
  %131 = xor i32 %1, -128828487
  %132 = and i32 %1, %131
  %133 = or i32 %1, %131
  %134 = xor i32 %1, %131
  %135 = sub i32 %133, %134
  %136 = sub i32 %135, %132
  %137 = mul i32 %136, 222
  %138 = icmp slt i32 %137, 1
  br i1 %138, label %140, label %334

139:                                              ; preds = %9
  ret void

140:                                              ; preds = %412, %403, %394, %386, %377, %367, %359, %349, %334, %325, %315, %305, %295, %286, %278, %271, %249, %237, %224, %202, %189, %176, %163, %151, %124, %111, %94, %81, %65, %44, %27, %13
  br label %9

141:                                              ; preds = %9
  store i32 1421570952, ptr %4, align 4
  call void asm sideeffect "", ""()
  %142 = xor i32 %1, 368690837
  %143 = and i32 %1, %142
  %144 = or i32 %1, %142
  %145 = xor i32 %1, %142
  %146 = add i32 %143, %144
  %147 = sub i32 %146, %1
  %148 = sub i32 %147, %142
  %149 = mul i32 %148, 226
  %150 = icmp sle i32 %149, 0
  br i1 %150, label %9, label %342

151:                                              ; preds = %9
  %152 = load i32, ptr %4, align 4
  %153 = xor i32 %152, -1056429619
  store i32 %153, ptr %4, align 4
  %154 = xor i32 %1, -1907057683
  %155 = and i32 %1, %154
  %156 = or i32 %1, %154
  %157 = xor i32 %1, %154
  %158 = add i32 %155, %156
  %159 = sub i32 %158, %1
  %160 = sub i32 %159, %154
  %161 = mul i32 %160, 254
  %162 = icmp uge i32 %161, 0
  br i1 %162, label %140, label %349

163:                                              ; preds = %9
  %164 = load i32, ptr %4, align 4
  %165 = xor i32 %164, 130345997
  store i32 %165, ptr %4, align 4
  %166 = xor i32 %1, 2145213003
  %167 = and i32 %1, %166
  %168 = or i32 %1, %166
  %169 = xor i32 %1, %166
  %170 = mul i32 %168, 2
  %171 = sub i32 %170, %169
  %172 = sub i32 %171, %1
  %173 = sub i32 %172, %166
  %174 = mul i32 %173, 162
  %175 = icmp slt i32 %174, 1
  br i1 %175, label %140, label %359

176:                                              ; preds = %9
  %177 = load i32, ptr %4, align 4
  %178 = xor i32 %177, 1173731073
  store i32 %178, ptr %4, align 4
  %179 = xor i32 %1, -1609400763
  %180 = and i32 %1, %179
  %181 = or i32 %1, %179
  %182 = xor i32 %1, %179
  %183 = add i32 %1, %179
  %184 = sub i32 %183, %182
  %185 = mul i32 %180, 2
  %186 = sub i32 %184, %185
  %187 = mul i32 %186, 212
  %188 = icmp ugt i32 %187, 0
  br i1 %188, label %367, label %140

189:                                              ; preds = %9
  %190 = load i32, ptr %4, align 4
  %191 = xor i32 %190, 1475058367
  store i32 %191, ptr %4, align 4
  %192 = xor i32 %1, -1711114243
  %193 = and i32 %1, %192
  %194 = or i32 %1, %192
  %195 = xor i32 %1, %192
  %196 = mul i32 %194, 2
  %197 = sub i32 %196, %195
  %198 = sub i32 %197, %1
  %199 = sub i32 %198, %192
  %200 = mul i32 %199, 182
  %201 = icmp ugt i32 %200, 0
  br i1 %201, label %377, label %140

202:                                              ; preds = %9
  %203 = load i32, ptr %4, align 4
  %204 = xor i32 %203, -1548594077
  store i32 %204, ptr %4, align 4
  %205 = xor i32 %1, 2133513619
  %206 = and i32 %1, %205
  %207 = or i32 %1, %205
  %208 = xor i32 %1, %205
  %209 = add i32 %1, %205
  %210 = sub i32 %209, %208
  %211 = mul i32 %206, 2
  %212 = sub i32 %210, %211
  %213 = mul i32 %212, 193
  %214 = xor i32 %1, 1213314799
  %215 = and i32 %1, %214
  %216 = or i32 %1, %214
  %217 = xor i32 %1, %214
  %218 = mul i32 %216, 2
  %219 = sub i32 %218, %217
  %220 = sub i32 %219, %1
  %221 = sub i32 %220, %214
  %222 = mul i32 %221, 48
  %223 = icmp eq i32 %213, %222
  br i1 %223, label %140, label %386

224:                                              ; preds = %9
  %225 = load i32, ptr %4, align 4
  %226 = xor i32 %225, 843901506
  store i32 %226, ptr %4, align 4
  %227 = xor i32 %1, -2026556227
  %228 = and i32 %1, %227
  %229 = or i32 %1, %227
  %230 = xor i32 %1, %227
  %231 = mul i32 %229, 2
  %232 = sub i32 %231, %230
  %233 = sub i32 %232, %1
  %234 = sub i32 %233, %227
  %235 = mul i32 %234, 15
  %236 = icmp slt i32 %235, 1
  br i1 %236, label %140, label %394

237:                                              ; preds = %9
  %238 = load i32, ptr %4, align 4
  %239 = xor i32 %238, -1338592198
  store i32 %239, ptr %4, align 4
  %240 = xor i32 %1, 358853455
  %241 = and i32 %1, %240
  %242 = or i32 %1, %240
  %243 = xor i32 %1, %240
  %244 = add i32 %241, %242
  %245 = sub i32 %244, %1
  %246 = sub i32 %245, %240
  %247 = mul i32 %246, 41
  %248 = icmp ne i32 %247, 0
  br i1 %248, label %403, label %140

249:                                              ; preds = %9
  %250 = load i32, ptr %4, align 4
  %251 = xor i32 %250, -463720069
  store i32 %251, ptr %4, align 4
  %252 = xor i32 %1, 224861505
  %253 = and i32 %1, %252
  %254 = or i32 %1, %252
  %255 = xor i32 %1, %252
  %256 = add i32 %1, %252
  %257 = sub i32 %256, %255
  %258 = mul i32 %253, 2
  %259 = sub i32 %257, %258
  %260 = mul i32 %259, 134
  %261 = xor i32 %1, -360407753
  %262 = and i32 %1, %261
  %263 = or i32 %1, %261
  %264 = xor i32 %1, %261
  %265 = mul i32 %263, 2
  %266 = sub i32 %265, %264
  %267 = sub i32 %266, %1
  %268 = sub i32 %267, %261
  %269 = mul i32 %268, 35
  %270 = icmp eq i32 %260, %269
  br i1 %270, label %140, label %412

271:                                              ; preds = %13
  %272 = load i64, ptr %3, align 8
  %273 = ptrtoint ptr %0 to i64
  %274 = zext i32 %1 to i64
  %275 = xor i64 %274, %272
  %276 = or i64 %275, %274
  %277 = mul i64 %276, %273
  store i64 %277, ptr %3, align 8
  br label %140

278:                                              ; preds = %27
  %279 = load i64, ptr %3, align 8
  %280 = ptrtoint ptr %0 to i64
  %281 = zext i32 %1 to i64
  %282 = or i64 %280, %280
  %283 = sub i64 %282, %279
  %284 = or i64 %283, %281
  %285 = sub i64 %284, %279
  store i64 %285, ptr %3, align 8
  br label %140

286:                                              ; preds = %44
  %287 = load i64, ptr %3, align 8
  %288 = ptrtoint ptr %0 to i64
  %289 = zext i32 %1 to i64
  %290 = or i64 %289, %288
  %291 = or i64 %290, %288
  %292 = xor i64 %291, %289
  %293 = xor i64 %292, %287
  %294 = add i64 %293, %288
  store i64 %294, ptr %3, align 8
  br label %140

295:                                              ; preds = %65
  %296 = load i64, ptr %3, align 8
  %297 = ptrtoint ptr %0 to i64
  %298 = zext i32 %1 to i64
  %299 = xor i64 %297, %298
  %300 = and i64 %299, %298
  %301 = sub i64 %300, %298
  %302 = or i64 %301, %298
  %303 = sub i64 %302, %298
  %304 = and i64 %303, %296
  store i64 %304, ptr %3, align 8
  br label %140

305:                                              ; preds = %81
  %306 = load i64, ptr %3, align 8
  %307 = ptrtoint ptr %0 to i64
  %308 = zext i32 %1 to i64
  %309 = xor i64 %308, %308
  %310 = sub i64 %309, %307
  %311 = or i64 %310, %306
  %312 = sub i64 %311, %306
  %313 = add i64 %312, %308
  %314 = and i64 %313, %307
  store i64 %314, ptr %3, align 8
  br label %140

315:                                              ; preds = %94
  %316 = load i64, ptr %3, align 8
  %317 = ptrtoint ptr %0 to i64
  %318 = zext i32 %1 to i64
  %319 = sub i64 %318, %318
  %320 = mul i64 %319, %318
  %321 = or i64 %320, %318
  %322 = add i64 %321, %318
  %323 = xor i64 %322, %316
  %324 = sub i64 %323, %318
  store i64 %324, ptr %3, align 8
  br label %140

325:                                              ; preds = %111
  %326 = load i64, ptr %3, align 8
  %327 = ptrtoint ptr %0 to i64
  %328 = zext i32 %1 to i64
  %329 = sub i64 %327, %328
  %330 = sub i64 %329, %328
  %331 = and i64 %330, %327
  %332 = mul i64 %331, %328
  %333 = xor i64 %332, %326
  store i64 %333, ptr %3, align 8
  br label %140

334:                                              ; preds = %124
  %335 = load i64, ptr %3, align 8
  %336 = ptrtoint ptr %0 to i64
  %337 = zext i32 %1 to i64
  %338 = and i64 %337, %337
  %339 = xor i64 %338, %337
  %340 = xor i64 %339, %335
  %341 = or i64 %340, %337
  store i64 %341, ptr %3, align 8
  br label %140

342:                                              ; preds = %141
  %343 = load i64, ptr %3, align 8
  %344 = ptrtoint ptr %0 to i64
  %345 = zext i32 %1 to i64
  %346 = mul i64 %345, %343
  %347 = mul i64 %346, %343
  %348 = mul i64 %347, %344
  store i64 %348, ptr %3, align 8
  br label %9

349:                                              ; preds = %151
  %350 = load i64, ptr %3, align 8
  %351 = ptrtoint ptr %0 to i64
  %352 = zext i32 %1 to i64
  %353 = sub i64 %351, %351
  %354 = xor i64 %353, %350
  %355 = xor i64 %354, %351
  %356 = or i64 %355, %350
  %357 = mul i64 %356, %350
  %358 = xor i64 %357, %352
  store i64 %358, ptr %3, align 8
  br label %140

359:                                              ; preds = %163
  %360 = load i64, ptr %3, align 8
  %361 = ptrtoint ptr %0 to i64
  %362 = zext i32 %1 to i64
  %363 = xor i64 %361, %361
  %364 = or i64 %363, %360
  %365 = mul i64 %364, %360
  %366 = mul i64 %365, %360
  store i64 %366, ptr %3, align 8
  br label %140

367:                                              ; preds = %176
  %368 = load i64, ptr %3, align 8
  %369 = ptrtoint ptr %0 to i64
  %370 = zext i32 %1 to i64
  %371 = xor i64 %368, %368
  %372 = add i64 %371, %370
  %373 = sub i64 %372, %368
  %374 = or i64 %373, %368
  %375 = xor i64 %374, %370
  %376 = sub i64 %375, %370
  store i64 %376, ptr %3, align 8
  br label %140

377:                                              ; preds = %189
  %378 = load i64, ptr %3, align 8
  %379 = ptrtoint ptr %0 to i64
  %380 = zext i32 %1 to i64
  %381 = add i64 %380, %380
  %382 = xor i64 %381, %378
  %383 = xor i64 %382, %378
  %384 = mul i64 %383, %378
  %385 = xor i64 %384, %380
  store i64 %385, ptr %3, align 8
  br label %140

386:                                              ; preds = %202
  %387 = load i64, ptr %3, align 8
  %388 = ptrtoint ptr %0 to i64
  %389 = zext i32 %1 to i64
  %390 = sub i64 %388, %387
  %391 = mul i64 %390, %389
  %392 = xor i64 %391, %387
  %393 = and i64 %392, %387
  store i64 %393, ptr %3, align 8
  br label %140

394:                                              ; preds = %224
  %395 = load i64, ptr %3, align 8
  %396 = ptrtoint ptr %0 to i64
  %397 = zext i32 %1 to i64
  %398 = and i64 %395, %395
  %399 = mul i64 %398, %397
  %400 = or i64 %399, %397
  %401 = add i64 %400, %396
  %402 = add i64 %401, %396
  store i64 %402, ptr %3, align 8
  br label %140

403:                                              ; preds = %237
  %404 = load i64, ptr %3, align 8
  %405 = ptrtoint ptr %0 to i64
  %406 = zext i32 %1 to i64
  %407 = add i64 %405, %405
  %408 = sub i64 %407, %406
  %409 = add i64 %408, %405
  %410 = or i64 %409, %405
  %411 = xor i64 %410, %404
  store i64 %411, ptr %3, align 8
  br label %140

412:                                              ; preds = %249
  %413 = load i64, ptr %3, align 8
  %414 = ptrtoint ptr %0 to i64
  %415 = zext i32 %1 to i64
  %416 = add i64 %413, %414
  %417 = sub i64 %416, %413
  %418 = and i64 %417, %413
  store i64 %418, ptr %3, align 8
  br label %140
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdRestock(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 -400291372, ptr %4, align 4
  br label %10

10:                                               ; preds = %485, %249, %248, %2
  %11 = load i32, ptr %4, align 4
  %12 = sub i32 %11, -1401298494
  %13 = mul i32 %12, -822883099
  switch i32 %13, label %249 [
    i32 2084188186, label %14
    i32 1869292778, label %28
    i32 398342137, label %45
    i32 936099739, label %61
    i32 787944088, label %81
    i32 2137388697, label %103
    i32 1513198865, label %120
    i32 1718999919, label %134
    i32 1529320606, label %151
    i32 1386015453, label %162
    i32 1360364849, label %197
    i32 410839959, label %216
    i32 1550403693, label %247
    i32 1443538017, label %260
    i32 480440431, label %281
    i32 2144970972, label %294
    i32 1465920971, label %315
    i32 1278399181, label %326
    i32 663950542, label %339
    i32 1177831878, label %350
    i32 1849599087, label %363
  ]

14:                                               ; preds = %10
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %15 = load i32, ptr %6, align 4
  %16 = icmp ne i32 %15, 3
  %17 = select i1 %16, i32 1830220865, i32 -1508659612
  store i32 %17, ptr %4, align 4
  %18 = xor i32 %1, -393760431
  %19 = and i32 %1, %18
  %20 = or i32 %1, %18
  %21 = xor i32 %1, %18
  %22 = add i32 %1, %18
  %23 = sub i32 %22, %21
  %24 = mul i32 %19, 2
  %25 = sub i32 %23, %24
  %26 = mul i32 %25, 137
  %27 = icmp ne i32 %26, 0
  br i1 %27, label %375, label %248

28:                                               ; preds = %10
  %29 = load ptr, ptr %5, align 8
  %30 = getelementptr inbounds ptr, ptr %29, i64 1
  %31 = load ptr, ptr %30, align 8
  %32 = call i32 @parseIntStrict(ptr noundef %31, ptr noundef %7)
  %33 = icmp ne i32 %32, 0
  %34 = select i1 %33, i32 -2147204281, i32 1830220865
  store i32 %34, ptr %4, align 4
  %35 = xor i32 %1, 1416670493
  %36 = and i32 %1, %35
  %37 = or i32 %1, %35
  %38 = xor i32 %1, %35
  %39 = mul i32 %37, 2
  %40 = sub i32 %39, %38
  %41 = sub i32 %40, %1
  %42 = sub i32 %41, %35
  %43 = mul i32 %42, 208
  %44 = icmp slt i32 %43, 0
  br i1 %44, label %382, label %248

45:                                               ; preds = %10
  %46 = load ptr, ptr %5, align 8
  %47 = getelementptr inbounds ptr, ptr %46, i64 2
  %48 = load ptr, ptr %47, align 8
  %49 = call i32 @parseIntStrict(ptr noundef %48, ptr noundef %8)
  %50 = icmp ne i32 %49, 0
  %51 = select i1 %50, i32 -1204316038, i32 1830220865
  store i32 %51, ptr %4, align 4
  %52 = xor i32 %1, -1441888673
  %53 = and i32 %1, %52
  %54 = or i32 %1, %52
  %55 = xor i32 %1, %52
  %56 = add i32 %53, %54
  %57 = sub i32 %56, %1
  %58 = sub i32 %57, %52
  %59 = mul i32 %58, 229
  %60 = icmp uge i32 %59, 0
  br i1 %60, label %248, label %392

61:                                               ; preds = %10
  %62 = call i32 (ptr, ...) @printf(ptr noundef @.str.19)
  store i32 -818037077, ptr %4, align 4
  %63 = xor i32 %1, 1775934275
  %64 = and i32 %1, %63
  %65 = or i32 %1, %63
  %66 = xor i32 %1, %63
  %67 = add i32 %64, %65
  %68 = sub i32 %67, %1
  %69 = sub i32 %68, %63
  %70 = mul i32 %69, 197
  %71 = xor i32 %1, -1264805893
  %72 = and i32 %1, %71
  %73 = or i32 %1, %71
  %74 = xor i32 %1, %71
  %75 = add i32 %1, %71
  %76 = sub i32 %75, %74
  %77 = mul i32 %72, 2
  %78 = sub i32 %76, %77
  %79 = mul i32 %78, 161
  %80 = icmp eq i32 %70, %79
  br i1 %80, label %248, label %402

81:                                               ; preds = %10
  %82 = load i32, ptr %8, align 4
  %83 = icmp sle i32 %82, 0
  %84 = select i1 %83, i32 -203834009, i32 821752447
  store i32 %84, ptr %4, align 4
  %85 = xor i32 %1, 944577815
  %86 = and i32 %1, %85
  %87 = or i32 %1, %85
  %88 = xor i32 %1, %85
  %89 = add i32 %1, %85
  %90 = sub i32 %89, %88
  %91 = mul i32 %86, 2
  %92 = sub i32 %90, %91
  %93 = mul i32 %92, 2
  %94 = xor i32 %1, -1150298737
  %95 = and i32 %1, %94
  %96 = or i32 %1, %94
  %97 = xor i32 %1, %94
  %98 = add i32 %95, %96
  %99 = sub i32 %98, %1
  %100 = sub i32 %99, %94
  %101 = mul i32 %100, 50
  %102 = icmp ne i32 %93, %101
  br i1 %102, label %412, label %248

103:                                              ; preds = %10
  %104 = call i32 (ptr, ...) @printf(ptr noundef @.str.20)
  store i32 -818037077, ptr %4, align 4
  %105 = xor i32 %1, 1523050605
  %106 = and i32 %1, %105
  %107 = or i32 %1, %105
  %108 = xor i32 %1, %105
  %109 = sub i32 %107, %108
  %110 = sub i32 %109, %106
  %111 = mul i32 %110, 88
  %112 = xor i32 %1, -1139562145
  %113 = and i32 %1, %112
  %114 = or i32 %1, %112
  %115 = xor i32 %1, %112
  %116 = sub i32 %114, %115
  %117 = sub i32 %116, %113
  %118 = mul i32 %117, 214
  %119 = icmp ne i32 %111, %118
  br i1 %119, label %421, label %248

120:                                              ; preds = %10
  %121 = load i32, ptr %7, align 4
  %122 = call i32 @findProductIndexById(i32 noundef %121)
  store i32 %122, ptr %9, align 4
  %123 = load i32, ptr %9, align 4
  %124 = icmp eq i32 %123, -1
  %125 = select i1 %124, i32 194402312, i32 1183053701
  store i32 %125, ptr %4, align 4
  %126 = xor i32 %1, -1669667005
  %127 = and i32 %1, %126
  %128 = or i32 %1, %126
  %129 = xor i32 %1, %126
  %130 = sub i32 %128, %129
  %131 = sub i32 %130, %127
  %132 = mul i32 %131, 124
  %133 = icmp sle i32 %132, 0
  br i1 %133, label %248, label %430

134:                                              ; preds = %10
  %135 = load i32, ptr %9, align 4
  %136 = sext i32 %135 to i64
  %137 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %136
  %138 = getelementptr inbounds nuw %struct.Product, ptr %137, i32 0, i32 6
  %139 = load i32, ptr %138, align 8
  %140 = icmp ne i32 %139, 0
  %141 = select i1 %140, i32 975315035, i32 194402312
  store i32 %141, ptr %4, align 4
  %142 = xor i32 %1, -1061838965
  %143 = and i32 %1, %142
  %144 = or i32 %1, %142
  %145 = xor i32 %1, %142
  %146 = add i32 %143, %144
  %147 = sub i32 %146, %1
  %148 = sub i32 %147, %142
  %149 = mul i32 %148, 64
  %150 = icmp sle i32 %149, 0
  br i1 %150, label %248, label %438

151:                                              ; preds = %10
  %152 = load i32, ptr %7, align 4
  %153 = call i32 (ptr, ...) @printf(ptr noundef @.str.21, i32 noundef %152)
  store i32 -818037077, ptr %4, align 4
  %154 = xor i32 %1, 121501713
  %155 = and i32 %1, %154
  %156 = or i32 %1, %154
  %157 = xor i32 %1, %154
  %158 = sub i32 %156, %157
  %159 = sub i32 %158, %155
  %160 = mul i32 %159, 206
  %161 = icmp slt i32 %160, 0
  br i1 %161, label %448, label %248

162:                                              ; preds = %10
  %163 = load i32, ptr %9, align 4
  %164 = sext i32 %163 to i64
  %165 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %164
  %166 = getelementptr inbounds nuw %struct.Product, ptr %165, i32 0, i32 4
  %167 = load i32, ptr %166, align 16
  %168 = load i32, ptr %8, align 4
  %169 = load i32, ptr %4, align 4
  %170 = xor i32 %169, -975315036
  %171 = xor i32 %168, %170
  %172 = load i32, ptr %4, align 4
  %173 = xor i32 %172, 1172168612
  %174 = add i32 %173, %171
  %175 = load i32, ptr %4, align 4
  %176 = xor i32 %175, 975315034
  %177 = add i32 %174, %176
  %178 = icmp sgt i32 %167, %177
  %179 = select i1 %178, i32 -937279457, i32 83389581
  store i32 %179, ptr %4, align 4
  %180 = xor i32 %1, 184846939
  %181 = and i32 %1, %180
  %182 = or i32 %1, %180
  %183 = xor i32 %1, %180
  %184 = mul i32 %182, 2
  %185 = sub i32 %184, %183
  %186 = sub i32 %185, %1
  %187 = sub i32 %186, %180
  %188 = mul i32 %187, 192
  %189 = xor i32 %1, 2106030031
  %190 = and i32 %1, %189
  %191 = or i32 %1, %189
  %192 = xor i32 %1, %189
  %193 = sub i32 %191, %192
  %194 = sub i32 %193, %190
  %195 = mul i32 %194, 183
  %196 = icmp eq i32 %188, %195
  br i1 %196, label %248, label %458

197:                                              ; preds = %10
  %198 = call i32 (ptr, ...) @printf(ptr noundef @.str.22)
  store i32 -818037077, ptr %4, align 4
  %199 = xor i32 %1, 1981438625
  %200 = and i32 %1, %199
  %201 = or i32 %1, %199
  %202 = xor i32 %1, %199
  %203 = sub i32 %201, %202
  %204 = sub i32 %203, %200
  %205 = mul i32 %204, 168
  %206 = xor i32 %1, 902252113
  %207 = and i32 %1, %206
  %208 = or i32 %1, %206
  %209 = xor i32 %1, %206
  %210 = mul i32 %208, 2
  %211 = sub i32 %210, %209
  %212 = sub i32 %211, %1
  %213 = sub i32 %212, %206
  %214 = mul i32 %213, 190
  %215 = icmp ne i32 %205, %214
  br i1 %215, label %466, label %248

216:                                              ; preds = %10
  %217 = load i32, ptr %8, align 4
  %218 = load i32, ptr %9, align 4
  %219 = sext i32 %218 to i64
  %220 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %219
  %221 = getelementptr inbounds nuw %struct.Product, ptr %220, i32 0, i32 4
  %222 = load i32, ptr %221, align 16
  %223 = load i32, ptr %4, align 4
  %224 = xor i32 %223, 83389580
  %225 = add i32 %217, %224
  %226 = load i32, ptr %4, align 4
  %227 = xor i32 %226, 83389580
  %228 = sub i32 %222, %227
  %229 = mul i32 %222, %225
  %230 = mul i32 %217, %228
  %231 = sub i32 %229, %230
  store i32 %231, ptr %221, align 16
  %232 = load i32, ptr %7, align 4
  %233 = load i32, ptr %9, align 4
  %234 = sext i32 %233 to i64
  %235 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %234
  %236 = getelementptr inbounds nuw %struct.Product, ptr %235, i32 0, i32 4
  %237 = load i32, ptr %236, align 16
  %238 = call i32 (ptr, ...) @printf(ptr noundef @.str.23, i32 noundef %232, i32 noundef %237)
  store i32 -818037077, ptr %4, align 4
  %239 = xor i32 %1, -1961123381
  %240 = and i32 %1, %239
  %241 = or i32 %1, %239
  %242 = xor i32 %1, %239
  %243 = sub i32 %241, %242
  %244 = sub i32 %243, %240
  %245 = mul i32 %244, 133
  %246 = icmp eq i32 %245, 0
  br i1 %246, label %248, label %476

247:                                              ; preds = %10
  ret void

248:                                              ; preds = %553, %543, %533, %524, %517, %509, %501, %494, %476, %466, %458, %448, %438, %430, %421, %412, %402, %392, %382, %375, %363, %350, %339, %326, %315, %294, %281, %260, %216, %197, %162, %151, %134, %120, %103, %81, %61, %45, %28, %14
  br label %10

249:                                              ; preds = %10
  store i32 -400291372, ptr %4, align 4
  call void asm sideeffect "", ""()
  %250 = xor i32 %1, -1286848805
  %251 = and i32 %1, %250
  %252 = or i32 %1, %250
  %253 = xor i32 %1, %250
  %254 = add i32 %1, %250
  %255 = sub i32 %254, %253
  %256 = mul i32 %251, 2
  %257 = sub i32 %255, %256
  %258 = mul i32 %257, 9
  %259 = icmp ne i32 %258, 0
  br i1 %259, label %485, label %10

260:                                              ; preds = %10
  %261 = load i32, ptr %4, align 4
  %262 = xor i32 %261, -740063136
  store i32 %262, ptr %4, align 4
  %263 = xor i32 %1, -182260411
  %264 = and i32 %1, %263
  %265 = or i32 %1, %263
  %266 = xor i32 %1, %263
  %267 = add i32 %1, %263
  %268 = sub i32 %267, %266
  %269 = mul i32 %264, 2
  %270 = sub i32 %268, %269
  %271 = mul i32 %270, 165
  %272 = xor i32 %1, -735778517
  %273 = and i32 %1, %272
  %274 = or i32 %1, %272
  %275 = xor i32 %1, %272
  %276 = add i32 %273, %274
  %277 = sub i32 %276, %1
  %278 = sub i32 %277, %272
  %279 = mul i32 %278, 236
  %280 = icmp ne i32 %271, %279
  br i1 %280, label %494, label %248

281:                                              ; preds = %10
  %282 = load i32, ptr %4, align 4
  %283 = xor i32 %282, 77806254
  store i32 %283, ptr %4, align 4
  %284 = xor i32 %1, 822887317
  %285 = and i32 %1, %284
  %286 = or i32 %1, %284
  %287 = xor i32 %1, %284
  %288 = add i32 %1, %284
  %289 = sub i32 %288, %287
  %290 = mul i32 %285, 2
  %291 = sub i32 %289, %290
  %292 = mul i32 %291, 250
  %293 = icmp sgt i32 %292, 0
  br i1 %293, label %501, label %248

294:                                              ; preds = %10
  %295 = load i32, ptr %4, align 4
  %296 = xor i32 %295, -57225118
  store i32 %296, ptr %4, align 4
  %297 = xor i32 %1, -1893803641
  %298 = and i32 %1, %297
  %299 = or i32 %1, %297
  %300 = xor i32 %1, %297
  %301 = mul i32 %299, 2
  %302 = sub i32 %301, %300
  %303 = sub i32 %302, %1
  %304 = sub i32 %303, %297
  %305 = mul i32 %304, 112
  %306 = xor i32 %1, 449489157
  %307 = and i32 %1, %306
  %308 = or i32 %1, %306
  %309 = xor i32 %1, %306
  %310 = add i32 %307, %308
  %311 = sub i32 %310, %1
  %312 = sub i32 %311, %306
  %313 = mul i32 %312, 129
  %314 = icmp ne i32 %305, %313
  br i1 %314, label %509, label %248

315:                                              ; preds = %10
  %316 = load i32, ptr %4, align 4
  %317 = xor i32 %316, 964396670
  store i32 %317, ptr %4, align 4
  %318 = xor i32 %1, -2091927683
  %319 = and i32 %1, %318
  %320 = or i32 %1, %318
  %321 = xor i32 %1, %318
  %322 = sub i32 %320, %321
  %323 = sub i32 %322, %319
  %324 = mul i32 %323, 255
  %325 = icmp uge i32 %324, 0
  br i1 %325, label %248, label %517

326:                                              ; preds = %10
  %327 = load i32, ptr %4, align 4
  %328 = xor i32 %327, 889886453
  store i32 %328, ptr %4, align 4
  %329 = xor i32 %1, -1762575617
  %330 = and i32 %1, %329
  %331 = or i32 %1, %329
  %332 = xor i32 %1, %329
  %333 = mul i32 %331, 2
  %334 = sub i32 %333, %332
  %335 = sub i32 %334, %1
  %336 = sub i32 %335, %329
  %337 = mul i32 %336, 13
  %338 = icmp slt i32 %337, 0
  br i1 %338, label %524, label %248

339:                                              ; preds = %10
  %340 = load i32, ptr %4, align 4
  %341 = xor i32 %340, 281566236
  store i32 %341, ptr %4, align 4
  %342 = xor i32 %1, 447795057
  %343 = and i32 %1, %342
  %344 = or i32 %1, %342
  %345 = xor i32 %1, %342
  %346 = sub i32 %344, %345
  %347 = sub i32 %346, %343
  %348 = mul i32 %347, 192
  %349 = icmp sle i32 %348, 0
  br i1 %349, label %248, label %533

350:                                              ; preds = %10
  %351 = load i32, ptr %4, align 4
  %352 = xor i32 %351, -1827140991
  store i32 %352, ptr %4, align 4
  %353 = xor i32 %1, 1260156041
  %354 = and i32 %1, %353
  %355 = or i32 %1, %353
  %356 = xor i32 %1, %353
  %357 = add i32 %1, %353
  %358 = sub i32 %357, %356
  %359 = mul i32 %354, 2
  %360 = sub i32 %358, %359
  %361 = mul i32 %360, 59
  %362 = icmp sgt i32 %361, 0
  br i1 %362, label %543, label %248

363:                                              ; preds = %10
  %364 = load i32, ptr %4, align 4
  %365 = xor i32 %364, -805857576
  store i32 %365, ptr %4, align 4
  %366 = xor i32 %1, -1289979581
  %367 = and i32 %1, %366
  %368 = or i32 %1, %366
  %369 = xor i32 %1, %366
  %370 = add i32 %367, %368
  %371 = sub i32 %370, %1
  %372 = sub i32 %371, %366
  %373 = mul i32 %372, 183
  %374 = icmp eq i32 %373, 0
  br i1 %374, label %248, label %553

375:                                              ; preds = %14
  %376 = load i64, ptr %3, align 8
  %377 = ptrtoint ptr %0 to i64
  %378 = zext i32 %1 to i64
  %379 = or i64 %377, %377
  %380 = or i64 %379, %378
  %381 = xor i64 %380, %378
  store i64 %381, ptr %3, align 8
  br label %248

382:                                              ; preds = %28
  %383 = load i64, ptr %3, align 8
  %384 = ptrtoint ptr %0 to i64
  %385 = zext i32 %1 to i64
  %386 = xor i64 %385, %384
  %387 = or i64 %386, %384
  %388 = mul i64 %387, %385
  %389 = add i64 %388, %384
  %390 = mul i64 %389, %384
  %391 = and i64 %390, %385
  store i64 %391, ptr %3, align 8
  br label %248

392:                                              ; preds = %45
  %393 = load i64, ptr %3, align 8
  %394 = ptrtoint ptr %0 to i64
  %395 = zext i32 %1 to i64
  %396 = add i64 %395, %395
  %397 = xor i64 %396, %394
  %398 = or i64 %397, %394
  %399 = xor i64 %398, %395
  %400 = sub i64 %399, %393
  %401 = xor i64 %400, %393
  store i64 %401, ptr %3, align 8
  br label %248

402:                                              ; preds = %61
  %403 = load i64, ptr %3, align 8
  %404 = ptrtoint ptr %0 to i64
  %405 = zext i32 %1 to i64
  %406 = add i64 %403, %404
  %407 = or i64 %406, %403
  %408 = or i64 %407, %405
  %409 = xor i64 %408, %403
  %410 = and i64 %409, %405
  %411 = xor i64 %410, %404
  store i64 %411, ptr %3, align 8
  br label %248

412:                                              ; preds = %81
  %413 = load i64, ptr %3, align 8
  %414 = ptrtoint ptr %0 to i64
  %415 = zext i32 %1 to i64
  %416 = add i64 %414, %414
  %417 = sub i64 %416, %413
  %418 = and i64 %417, %413
  %419 = mul i64 %418, %414
  %420 = sub i64 %419, %414
  store i64 %420, ptr %3, align 8
  br label %248

421:                                              ; preds = %103
  %422 = load i64, ptr %3, align 8
  %423 = ptrtoint ptr %0 to i64
  %424 = zext i32 %1 to i64
  %425 = sub i64 %422, %423
  %426 = sub i64 %425, %423
  %427 = mul i64 %426, %422
  %428 = add i64 %427, %423
  %429 = add i64 %428, %422
  store i64 %429, ptr %3, align 8
  br label %248

430:                                              ; preds = %120
  %431 = load i64, ptr %3, align 8
  %432 = ptrtoint ptr %0 to i64
  %433 = zext i32 %1 to i64
  %434 = or i64 %432, %432
  %435 = add i64 %434, %431
  %436 = and i64 %435, %431
  %437 = sub i64 %436, %432
  store i64 %437, ptr %3, align 8
  br label %248

438:                                              ; preds = %134
  %439 = load i64, ptr %3, align 8
  %440 = ptrtoint ptr %0 to i64
  %441 = zext i32 %1 to i64
  %442 = or i64 %440, %441
  %443 = or i64 %442, %441
  %444 = sub i64 %443, %440
  %445 = mul i64 %444, %440
  %446 = and i64 %445, %440
  %447 = or i64 %446, %441
  store i64 %447, ptr %3, align 8
  br label %248

448:                                              ; preds = %151
  %449 = load i64, ptr %3, align 8
  %450 = ptrtoint ptr %0 to i64
  %451 = zext i32 %1 to i64
  %452 = xor i64 %450, %450
  %453 = add i64 %452, %450
  %454 = and i64 %453, %450
  %455 = or i64 %454, %449
  %456 = and i64 %455, %451
  %457 = mul i64 %456, %451
  store i64 %457, ptr %3, align 8
  br label %248

458:                                              ; preds = %162
  %459 = load i64, ptr %3, align 8
  %460 = ptrtoint ptr %0 to i64
  %461 = zext i32 %1 to i64
  %462 = and i64 %459, %460
  %463 = add i64 %462, %459
  %464 = or i64 %463, %460
  %465 = or i64 %464, %459
  store i64 %465, ptr %3, align 8
  br label %248

466:                                              ; preds = %197
  %467 = load i64, ptr %3, align 8
  %468 = ptrtoint ptr %0 to i64
  %469 = zext i32 %1 to i64
  %470 = or i64 %467, %469
  %471 = or i64 %470, %468
  %472 = mul i64 %471, %468
  %473 = or i64 %472, %467
  %474 = and i64 %473, %469
  %475 = sub i64 %474, %468
  store i64 %475, ptr %3, align 8
  br label %248

476:                                              ; preds = %216
  %477 = load i64, ptr %3, align 8
  %478 = ptrtoint ptr %0 to i64
  %479 = zext i32 %1 to i64
  %480 = xor i64 %477, %479
  %481 = or i64 %480, %479
  %482 = xor i64 %481, %479
  %483 = mul i64 %482, %479
  %484 = mul i64 %483, %477
  store i64 %484, ptr %3, align 8
  br label %248

485:                                              ; preds = %249
  %486 = load i64, ptr %3, align 8
  %487 = ptrtoint ptr %0 to i64
  %488 = zext i32 %1 to i64
  %489 = xor i64 %486, %488
  %490 = add i64 %489, %486
  %491 = and i64 %490, %487
  %492 = or i64 %491, %487
  %493 = and i64 %492, %487
  store i64 %493, ptr %3, align 8
  br label %10

494:                                              ; preds = %260
  %495 = load i64, ptr %3, align 8
  %496 = ptrtoint ptr %0 to i64
  %497 = zext i32 %1 to i64
  %498 = add i64 %495, %496
  %499 = sub i64 %498, %497
  %500 = sub i64 %499, %496
  store i64 %500, ptr %3, align 8
  br label %248

501:                                              ; preds = %281
  %502 = load i64, ptr %3, align 8
  %503 = ptrtoint ptr %0 to i64
  %504 = zext i32 %1 to i64
  %505 = xor i64 %504, %504
  %506 = or i64 %505, %504
  %507 = sub i64 %506, %504
  %508 = add i64 %507, %504
  store i64 %508, ptr %3, align 8
  br label %248

509:                                              ; preds = %294
  %510 = load i64, ptr %3, align 8
  %511 = ptrtoint ptr %0 to i64
  %512 = zext i32 %1 to i64
  %513 = or i64 %510, %511
  %514 = add i64 %513, %512
  %515 = sub i64 %514, %511
  %516 = and i64 %515, %511
  store i64 %516, ptr %3, align 8
  br label %248

517:                                              ; preds = %315
  %518 = load i64, ptr %3, align 8
  %519 = ptrtoint ptr %0 to i64
  %520 = zext i32 %1 to i64
  %521 = and i64 %519, %519
  %522 = xor i64 %521, %520
  %523 = or i64 %522, %518
  store i64 %523, ptr %3, align 8
  br label %248

524:                                              ; preds = %326
  %525 = load i64, ptr %3, align 8
  %526 = ptrtoint ptr %0 to i64
  %527 = zext i32 %1 to i64
  %528 = sub i64 %527, %525
  %529 = add i64 %528, %526
  %530 = xor i64 %529, %527
  %531 = sub i64 %530, %525
  %532 = xor i64 %531, %527
  store i64 %532, ptr %3, align 8
  br label %248

533:                                              ; preds = %339
  %534 = load i64, ptr %3, align 8
  %535 = ptrtoint ptr %0 to i64
  %536 = zext i32 %1 to i64
  %537 = add i64 %535, %535
  %538 = sub i64 %537, %536
  %539 = or i64 %538, %534
  %540 = add i64 %539, %534
  %541 = mul i64 %540, %535
  %542 = and i64 %541, %535
  store i64 %542, ptr %3, align 8
  br label %248

543:                                              ; preds = %350
  %544 = load i64, ptr %3, align 8
  %545 = ptrtoint ptr %0 to i64
  %546 = zext i32 %1 to i64
  %547 = add i64 %544, %545
  %548 = or i64 %547, %546
  %549 = or i64 %548, %546
  %550 = xor i64 %549, %546
  %551 = mul i64 %550, %545
  %552 = mul i64 %551, %544
  store i64 %552, ptr %3, align 8
  br label %248

553:                                              ; preds = %363
  %554 = load i64, ptr %3, align 8
  %555 = ptrtoint ptr %0 to i64
  %556 = zext i32 %1 to i64
  %557 = or i64 %555, %554
  %558 = xor i64 %557, %555
  %559 = add i64 %558, %554
  %560 = add i64 %559, %554
  %561 = mul i64 %560, %554
  %562 = mul i64 %561, %554
  store i64 %562, ptr %3, align 8
  br label %248
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdUpdatePrice(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i64, align 8
  store i32 -1669889957, ptr %4, align 4
  br label %10

10:                                               ; preds = %436, %175, %174, %2
  %11 = load i32, ptr %4, align 4
  %12 = sub i32 %11, -1178539325
  %13 = mul i32 %12, 537831167
  %14 = icmp slt i32 %13, 900459550
  br i1 %14, label %305, label %307

15:                                               ; preds = %353
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %16 = load i32, ptr %6, align 4
  %17 = icmp ne i32 %16, 3
  %18 = select i1 %17, i32 -200226149, i32 970981172
  store i32 %18, ptr %4, align 4
  %19 = xor i32 %1, 278795025
  %20 = and i32 %1, %19
  %21 = or i32 %1, %19
  %22 = xor i32 %1, %19
  %23 = add i32 %20, %21
  %24 = sub i32 %23, %1
  %25 = sub i32 %24, %19
  %26 = mul i32 %25, 85
  %27 = xor i32 %1, -1157862507
  %28 = and i32 %1, %27
  %29 = or i32 %1, %27
  %30 = xor i32 %1, %27
  %31 = add i32 %28, %29
  %32 = sub i32 %31, %1
  %33 = sub i32 %32, %27
  %34 = mul i32 %33, 159
  %35 = icmp ne i32 %26, %34
  br i1 %35, label %357, label %174

36:                                               ; preds = %313
  %37 = load ptr, ptr %5, align 8
  %38 = getelementptr inbounds ptr, ptr %37, i64 1
  %39 = load ptr, ptr %38, align 8
  %40 = call i32 @parseIntStrict(ptr noundef %39, ptr noundef %7)
  %41 = icmp ne i32 %40, 0
  %42 = select i1 %41, i32 113524193, i32 -200226149
  store i32 %42, ptr %4, align 4
  %43 = xor i32 %1, -549194767
  %44 = and i32 %1, %43
  %45 = or i32 %1, %43
  %46 = xor i32 %1, %43
  %47 = sub i32 %45, %46
  %48 = sub i32 %47, %44
  %49 = mul i32 %48, 46
  %50 = xor i32 %1, 957084461
  %51 = and i32 %1, %50
  %52 = or i32 %1, %50
  %53 = xor i32 %1, %50
  %54 = sub i32 %52, %53
  %55 = sub i32 %54, %51
  %56 = mul i32 %55, 10
  %57 = icmp eq i32 %49, %56
  br i1 %57, label %174, label %364

58:                                               ; preds = %329
  %59 = load ptr, ptr %5, align 8
  %60 = getelementptr inbounds ptr, ptr %59, i64 2
  %61 = load ptr, ptr %60, align 8
  %62 = call i32 @parseMoneyStrict(ptr noundef %61, ptr noundef %9)
  %63 = icmp ne i32 %62, 0
  %64 = select i1 %63, i32 1496018085, i32 -200226149
  store i32 %64, ptr %4, align 4
  %65 = xor i32 %1, 1401076263
  %66 = and i32 %1, %65
  %67 = or i32 %1, %65
  %68 = xor i32 %1, %65
  %69 = add i32 %1, %65
  %70 = sub i32 %69, %68
  %71 = mul i32 %66, 2
  %72 = sub i32 %70, %71
  %73 = mul i32 %72, 90
  %74 = icmp slt i32 %73, 1
  br i1 %74, label %174, label %373

75:                                               ; preds = %337
  %76 = load i64, ptr %9, align 8
  %77 = icmp sle i64 %76, 0
  %78 = select i1 %77, i32 -200226149, i32 -244490352
  store i32 %78, ptr %4, align 4
  %79 = xor i32 %1, 1625761487
  %80 = and i32 %1, %79
  %81 = or i32 %1, %79
  %82 = xor i32 %1, %79
  %83 = sub i32 %81, %82
  %84 = sub i32 %83, %80
  %85 = mul i32 %84, 136
  %86 = icmp sle i32 %85, 0
  br i1 %86, label %174, label %382

87:                                               ; preds = %325
  %88 = call i32 (ptr, ...) @printf(ptr noundef @.str.24)
  store i32 -571673773, ptr %4, align 4
  %89 = xor i32 %1, -1961812877
  %90 = and i32 %1, %89
  %91 = or i32 %1, %89
  %92 = xor i32 %1, %89
  %93 = add i32 %90, %91
  %94 = sub i32 %93, %1
  %95 = sub i32 %94, %89
  %96 = mul i32 %95, 20
  %97 = xor i32 %1, -208993029
  %98 = and i32 %1, %97
  %99 = or i32 %1, %97
  %100 = xor i32 %1, %97
  %101 = mul i32 %99, 2
  %102 = sub i32 %101, %100
  %103 = sub i32 %102, %1
  %104 = sub i32 %103, %97
  %105 = mul i32 %104, 63
  %106 = icmp eq i32 %96, %105
  br i1 %106, label %174, label %391

107:                                              ; preds = %343
  %108 = load i32, ptr %7, align 4
  %109 = call i32 @findProductIndexById(i32 noundef %108)
  store i32 %109, ptr %8, align 4
  %110 = load i32, ptr %8, align 4
  %111 = icmp eq i32 %110, -1
  %112 = select i1 %111, i32 1006980807, i32 -1857591705
  store i32 %112, ptr %4, align 4
  %113 = xor i32 %1, -79076479
  %114 = and i32 %1, %113
  %115 = or i32 %1, %113
  %116 = xor i32 %1, %113
  %117 = add i32 %114, %115
  %118 = sub i32 %117, %1
  %119 = sub i32 %118, %113
  %120 = mul i32 %119, 13
  %121 = icmp sle i32 %120, 0
  br i1 %121, label %174, label %401

122:                                              ; preds = %327
  %123 = load i32, ptr %8, align 4
  %124 = sext i32 %123 to i64
  %125 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %124
  %126 = getelementptr inbounds nuw %struct.Product, ptr %125, i32 0, i32 6
  %127 = load i32, ptr %126, align 8
  %128 = icmp ne i32 %127, 0
  %129 = select i1 %128, i32 -71315553, i32 1006980807
  store i32 %129, ptr %4, align 4
  %130 = xor i32 %1, 920973983
  %131 = and i32 %1, %130
  %132 = or i32 %1, %130
  %133 = xor i32 %1, %130
  %134 = add i32 %1, %130
  %135 = sub i32 %134, %133
  %136 = mul i32 %131, 2
  %137 = sub i32 %135, %136
  %138 = mul i32 %137, 20
  %139 = icmp uge i32 %138, 0
  br i1 %139, label %174, label %410

140:                                              ; preds = %319
  %141 = load i32, ptr %7, align 4
  %142 = call i32 (ptr, ...) @printf(ptr noundef @.str.25, i32 noundef %141)
  store i32 -571673773, ptr %4, align 4
  %143 = xor i32 %1, -1642252269
  %144 = and i32 %1, %143
  %145 = or i32 %1, %143
  %146 = xor i32 %1, %143
  %147 = mul i32 %145, 2
  %148 = sub i32 %147, %146
  %149 = sub i32 %148, %1
  %150 = sub i32 %149, %143
  %151 = mul i32 %150, 29
  %152 = icmp uge i32 %151, 0
  br i1 %152, label %174, label %419

153:                                              ; preds = %317
  %154 = load i64, ptr %9, align 8
  %155 = load i32, ptr %8, align 4
  %156 = sext i32 %155 to i64
  %157 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %156
  %158 = getelementptr inbounds nuw %struct.Product, ptr %157, i32 0, i32 3
  store i64 %154, ptr %158, align 8
  %159 = load i32, ptr %7, align 4
  %160 = call i32 (ptr, ...) @printf(ptr noundef @.str.26, i32 noundef %159)
  %161 = load i64, ptr %9, align 8
  call void @printMoney(i64 noundef %161)
  %162 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  store i32 -571673773, ptr %4, align 4
  %163 = xor i32 %1, -1799344663
  %164 = and i32 %1, %163
  %165 = or i32 %1, %163
  %166 = xor i32 %1, %163
  %167 = add i32 %1, %163
  %168 = sub i32 %167, %166
  %169 = mul i32 %164, 2
  %170 = sub i32 %168, %169
  %171 = mul i32 %170, 153
  %172 = icmp slt i32 %171, 0
  br i1 %172, label %429, label %174

173:                                              ; preds = %315
  ret void

174:                                              ; preds = %501, %492, %485, %478, %468, %460, %451, %443, %429, %419, %410, %401, %391, %382, %373, %364, %357, %293, %282, %263, %251, %232, %211, %198, %186, %153, %140, %122, %107, %87, %75, %58, %36, %15
  br label %10

175:                                              ; preds = %355, %351, %349, %343, %341, %331, %327, %325, %319, %317
  store i32 -1669889957, ptr %4, align 4
  call void asm sideeffect "", ""()
  %176 = xor i32 %1, 926398145
  %177 = and i32 %1, %176
  %178 = or i32 %1, %176
  %179 = xor i32 %1, %176
  %180 = add i32 %1, %176
  %181 = sub i32 %180, %179
  %182 = mul i32 %177, 2
  %183 = sub i32 %181, %182
  %184 = mul i32 %183, 2
  %185 = icmp ne i32 %184, 0
  br i1 %185, label %436, label %10

186:                                              ; preds = %351
  %187 = load i32, ptr %4, align 4
  %188 = xor i32 %187, -1036647170
  store i32 %188, ptr %4, align 4
  %189 = xor i32 %1, -945314091
  %190 = and i32 %1, %189
  %191 = or i32 %1, %189
  %192 = xor i32 %1, %189
  %193 = add i32 %190, %191
  %194 = sub i32 %193, %1
  %195 = sub i32 %194, %189
  %196 = mul i32 %195, 128
  %197 = icmp ne i32 %196, 0
  br i1 %197, label %443, label %174

198:                                              ; preds = %331
  %199 = load i32, ptr %4, align 4
  %200 = xor i32 %199, 1536958094
  store i32 %200, ptr %4, align 4
  %201 = xor i32 %1, 1963732227
  %202 = and i32 %1, %201
  %203 = or i32 %1, %201
  %204 = xor i32 %1, %201
  %205 = mul i32 %203, 2
  %206 = sub i32 %205, %204
  %207 = sub i32 %206, %1
  %208 = sub i32 %207, %201
  %209 = mul i32 %208, 207
  %210 = icmp sle i32 %209, 0
  br i1 %210, label %174, label %451

211:                                              ; preds = %341
  %212 = load i32, ptr %4, align 4
  %213 = xor i32 %212, 211484999
  store i32 %213, ptr %4, align 4
  %214 = xor i32 %1, 1148505565
  %215 = and i32 %1, %214
  %216 = or i32 %1, %214
  %217 = xor i32 %1, %214
  %218 = add i32 %215, %216
  %219 = sub i32 %218, %1
  %220 = sub i32 %219, %214
  %221 = mul i32 %220, 131
  %222 = xor i32 %1, -1069788865
  %223 = and i32 %1, %222
  %224 = or i32 %1, %222
  %225 = xor i32 %1, %222
  %226 = mul i32 %224, 2
  %227 = sub i32 %226, %225
  %228 = sub i32 %227, %1
  %229 = sub i32 %228, %222
  %230 = mul i32 %229, 52
  %231 = icmp eq i32 %221, %230
  br i1 %231, label %174, label %460

232:                                              ; preds = %355
  %233 = load i32, ptr %4, align 4
  %234 = xor i32 %233, -2134326490
  store i32 %234, ptr %4, align 4
  %235 = xor i32 %1, -952616677
  %236 = and i32 %1, %235
  %237 = or i32 %1, %235
  %238 = xor i32 %1, %235
  %239 = add i32 %236, %237
  %240 = sub i32 %239, %1
  %241 = sub i32 %240, %235
  %242 = mul i32 %241, 246
  %243 = xor i32 %1, -8842417
  %244 = and i32 %1, %243
  %245 = or i32 %1, %243
  %246 = xor i32 %1, %243
  %247 = sub i32 %245, %246
  %248 = sub i32 %247, %244
  %249 = mul i32 %248, 148
  %250 = icmp eq i32 %242, %249
  br i1 %250, label %174, label %468

251:                                              ; preds = %349
  %252 = load i32, ptr %4, align 4
  %253 = xor i32 %252, -190148832
  store i32 %253, ptr %4, align 4
  %254 = xor i32 %1, -1015661487
  %255 = and i32 %1, %254
  %256 = or i32 %1, %254
  %257 = xor i32 %1, %254
  %258 = add i32 %255, %256
  %259 = sub i32 %258, %1
  %260 = sub i32 %259, %254
  %261 = mul i32 %260, 161
  %262 = icmp slt i32 %261, 1
  br i1 %262, label %174, label %478

263:                                              ; preds = %345
  %264 = load i32, ptr %4, align 4
  %265 = xor i32 %264, 839425649
  store i32 %265, ptr %4, align 4
  %266 = xor i32 %1, -1804395007
  %267 = and i32 %1, %266
  %268 = or i32 %1, %266
  %269 = xor i32 %1, %266
  %270 = add i32 %267, %268
  %271 = sub i32 %270, %1
  %272 = sub i32 %271, %266
  %273 = mul i32 %272, 112
  %274 = xor i32 %1, 1269158383
  %275 = and i32 %1, %274
  %276 = or i32 %1, %274
  %277 = xor i32 %1, %274
  %278 = sub i32 %276, %277
  %279 = sub i32 %278, %275
  %280 = mul i32 %279, 67
  %281 = icmp ne i32 %273, %280
  br i1 %281, label %485, label %174

282:                                              ; preds = %339
  %283 = load i32, ptr %4, align 4
  %284 = xor i32 %283, 1037596094
  store i32 %284, ptr %4, align 4
  %285 = xor i32 %1, -1572187225
  %286 = and i32 %1, %285
  %287 = or i32 %1, %285
  %288 = xor i32 %1, %285
  %289 = sub i32 %287, %288
  %290 = sub i32 %289, %286
  %291 = mul i32 %290, 53
  %292 = icmp sgt i32 %291, 0
  br i1 %292, label %492, label %174

293:                                              ; preds = %321
  %294 = load i32, ptr %4, align 4
  %295 = xor i32 %294, 708409326
  store i32 %295, ptr %4, align 4
  %296 = xor i32 %1, -166954965
  %297 = and i32 %1, %296
  %298 = or i32 %1, %296
  %299 = xor i32 %1, %296
  %300 = add i32 %297, %298
  %301 = sub i32 %300, %1
  %302 = sub i32 %301, %296
  %303 = mul i32 %302, 225
  %304 = icmp ne i32 %303, 0
  br i1 %304, label %501, label %174

305:                                              ; preds = %10
  %306 = icmp slt i32 %13, 497859657
  br i1 %306, label %309, label %311

307:                                              ; preds = %10
  %308 = icmp slt i32 %13, 1360058447
  br i1 %308, label %333, label %335

309:                                              ; preds = %305
  %310 = icmp slt i32 %13, 222947184
  br i1 %310, label %313, label %315

311:                                              ; preds = %305
  %312 = icmp slt i32 %13, 639205468
  br i1 %312, label %321, label %323

313:                                              ; preds = %309
  %314 = icmp eq i32 %13, 73704079
  br i1 %314, label %36, label %317

315:                                              ; preds = %309
  %316 = icmp eq i32 %13, 222947184
  br i1 %316, label %173, label %319

317:                                              ; preds = %313
  %318 = icmp eq i32 %13, 156540708
  br i1 %318, label %153, label %175

319:                                              ; preds = %315
  %320 = icmp eq i32 %13, 322058236
  br i1 %320, label %140, label %175

321:                                              ; preds = %311
  %322 = icmp eq i32 %13, 497859657
  br i1 %322, label %293, label %325

323:                                              ; preds = %311
  %324 = icmp slt i32 %13, 702103266
  br i1 %324, label %327, label %329

325:                                              ; preds = %321
  %326 = icmp eq i32 %13, 512100392
  br i1 %326, label %87, label %175

327:                                              ; preds = %323
  %328 = icmp eq i32 %13, 639205468
  br i1 %328, label %122, label %175

329:                                              ; preds = %323
  %330 = icmp eq i32 %13, 702103266
  br i1 %330, label %58, label %331

331:                                              ; preds = %329
  %332 = icmp eq i32 %13, 895156714
  br i1 %332, label %198, label %175

333:                                              ; preds = %307
  %334 = icmp slt i32 %13, 1215677518
  br i1 %334, label %337, label %339

335:                                              ; preds = %307
  %336 = icmp slt i32 %13, 1708251787
  br i1 %336, label %345, label %347

337:                                              ; preds = %333
  %338 = icmp eq i32 %13, 900459550
  br i1 %338, label %75, label %341

339:                                              ; preds = %333
  %340 = icmp eq i32 %13, 1215677518
  br i1 %340, label %282, label %343

341:                                              ; preds = %337
  %342 = icmp eq i32 %13, 1049532711
  br i1 %342, label %211, label %175

343:                                              ; preds = %339
  %344 = icmp eq i32 %13, 1270564403
  br i1 %344, label %107, label %175

345:                                              ; preds = %335
  %346 = icmp eq i32 %13, 1360058447
  br i1 %346, label %263, label %349

347:                                              ; preds = %335
  %348 = icmp slt i32 %13, 1731170920
  br i1 %348, label %351, label %353

349:                                              ; preds = %345
  %350 = icmp eq i32 %13, 1385711141
  br i1 %350, label %251, label %175

351:                                              ; preds = %347
  %352 = icmp eq i32 %13, 1708251787
  br i1 %352, label %186, label %175

353:                                              ; preds = %347
  %354 = icmp eq i32 %13, 1731170920
  br i1 %354, label %15, label %355

355:                                              ; preds = %353
  %356 = icmp eq i32 %13, 1925311759
  br i1 %356, label %232, label %175

357:                                              ; preds = %15
  %358 = load i64, ptr %3, align 8
  %359 = ptrtoint ptr %0 to i64
  %360 = zext i32 %1 to i64
  %361 = and i64 %360, %359
  %362 = xor i64 %361, %359
  %363 = or i64 %362, %358
  store i64 %363, ptr %3, align 8
  br label %174

364:                                              ; preds = %36
  %365 = load i64, ptr %3, align 8
  %366 = ptrtoint ptr %0 to i64
  %367 = zext i32 %1 to i64
  %368 = xor i64 %367, %365
  %369 = add i64 %368, %365
  %370 = mul i64 %369, %367
  %371 = or i64 %370, %365
  %372 = or i64 %371, %367
  store i64 %372, ptr %3, align 8
  br label %174

373:                                              ; preds = %58
  %374 = load i64, ptr %3, align 8
  %375 = ptrtoint ptr %0 to i64
  %376 = zext i32 %1 to i64
  %377 = mul i64 %374, %374
  %378 = mul i64 %377, %374
  %379 = add i64 %378, %374
  %380 = and i64 %379, %376
  %381 = or i64 %380, %376
  store i64 %381, ptr %3, align 8
  br label %174

382:                                              ; preds = %75
  %383 = load i64, ptr %3, align 8
  %384 = ptrtoint ptr %0 to i64
  %385 = zext i32 %1 to i64
  %386 = xor i64 %385, %384
  %387 = add i64 %386, %384
  %388 = add i64 %387, %384
  %389 = add i64 %388, %383
  %390 = add i64 %389, %384
  store i64 %390, ptr %3, align 8
  br label %174

391:                                              ; preds = %87
  %392 = load i64, ptr %3, align 8
  %393 = ptrtoint ptr %0 to i64
  %394 = zext i32 %1 to i64
  %395 = sub i64 %393, %392
  %396 = and i64 %395, %392
  %397 = mul i64 %396, %392
  %398 = add i64 %397, %393
  %399 = add i64 %398, %394
  %400 = and i64 %399, %393
  store i64 %400, ptr %3, align 8
  br label %174

401:                                              ; preds = %107
  %402 = load i64, ptr %3, align 8
  %403 = ptrtoint ptr %0 to i64
  %404 = zext i32 %1 to i64
  %405 = add i64 %402, %402
  %406 = xor i64 %405, %403
  %407 = or i64 %406, %402
  %408 = sub i64 %407, %402
  %409 = mul i64 %408, %404
  store i64 %409, ptr %3, align 8
  br label %174

410:                                              ; preds = %122
  %411 = load i64, ptr %3, align 8
  %412 = ptrtoint ptr %0 to i64
  %413 = zext i32 %1 to i64
  %414 = and i64 %412, %411
  %415 = sub i64 %414, %411
  %416 = or i64 %415, %411
  %417 = sub i64 %416, %411
  %418 = mul i64 %417, %412
  store i64 %418, ptr %3, align 8
  br label %174

419:                                              ; preds = %140
  %420 = load i64, ptr %3, align 8
  %421 = ptrtoint ptr %0 to i64
  %422 = zext i32 %1 to i64
  %423 = sub i64 %421, %422
  %424 = sub i64 %423, %422
  %425 = sub i64 %424, %420
  %426 = xor i64 %425, %421
  %427 = and i64 %426, %420
  %428 = sub i64 %427, %421
  store i64 %428, ptr %3, align 8
  br label %174

429:                                              ; preds = %153
  %430 = load i64, ptr %3, align 8
  %431 = ptrtoint ptr %0 to i64
  %432 = zext i32 %1 to i64
  %433 = mul i64 %432, %430
  %434 = and i64 %433, %432
  %435 = add i64 %434, %432
  store i64 %435, ptr %3, align 8
  br label %174

436:                                              ; preds = %175
  %437 = load i64, ptr %3, align 8
  %438 = ptrtoint ptr %0 to i64
  %439 = zext i32 %1 to i64
  %440 = sub i64 %439, %438
  %441 = and i64 %440, %437
  %442 = or i64 %441, %439
  store i64 %442, ptr %3, align 8
  br label %10

443:                                              ; preds = %186
  %444 = load i64, ptr %3, align 8
  %445 = ptrtoint ptr %0 to i64
  %446 = zext i32 %1 to i64
  %447 = and i64 %444, %445
  %448 = mul i64 %447, %445
  %449 = add i64 %448, %445
  %450 = and i64 %449, %445
  store i64 %450, ptr %3, align 8
  br label %174

451:                                              ; preds = %198
  %452 = load i64, ptr %3, align 8
  %453 = ptrtoint ptr %0 to i64
  %454 = zext i32 %1 to i64
  %455 = or i64 %452, %454
  %456 = add i64 %455, %454
  %457 = or i64 %456, %453
  %458 = mul i64 %457, %454
  %459 = mul i64 %458, %452
  store i64 %459, ptr %3, align 8
  br label %174

460:                                              ; preds = %211
  %461 = load i64, ptr %3, align 8
  %462 = ptrtoint ptr %0 to i64
  %463 = zext i32 %1 to i64
  %464 = add i64 %462, %461
  %465 = or i64 %464, %461
  %466 = sub i64 %465, %463
  %467 = or i64 %466, %462
  store i64 %467, ptr %3, align 8
  br label %174

468:                                              ; preds = %232
  %469 = load i64, ptr %3, align 8
  %470 = ptrtoint ptr %0 to i64
  %471 = zext i32 %1 to i64
  %472 = or i64 %470, %469
  %473 = add i64 %472, %471
  %474 = or i64 %473, %469
  %475 = sub i64 %474, %471
  %476 = add i64 %475, %470
  %477 = sub i64 %476, %470
  store i64 %477, ptr %3, align 8
  br label %174

478:                                              ; preds = %251
  %479 = load i64, ptr %3, align 8
  %480 = ptrtoint ptr %0 to i64
  %481 = zext i32 %1 to i64
  %482 = xor i64 %480, %481
  %483 = mul i64 %482, %481
  %484 = or i64 %483, %479
  store i64 %484, ptr %3, align 8
  br label %174

485:                                              ; preds = %263
  %486 = load i64, ptr %3, align 8
  %487 = ptrtoint ptr %0 to i64
  %488 = zext i32 %1 to i64
  %489 = and i64 %487, %487
  %490 = and i64 %489, %487
  %491 = and i64 %490, %487
  store i64 %491, ptr %3, align 8
  br label %174

492:                                              ; preds = %282
  %493 = load i64, ptr %3, align 8
  %494 = ptrtoint ptr %0 to i64
  %495 = zext i32 %1 to i64
  %496 = or i64 %493, %493
  %497 = and i64 %496, %493
  %498 = sub i64 %497, %494
  %499 = and i64 %498, %493
  %500 = or i64 %499, %493
  store i64 %500, ptr %3, align 8
  br label %174

501:                                              ; preds = %293
  %502 = load i64, ptr %3, align 8
  %503 = ptrtoint ptr %0 to i64
  %504 = zext i32 %1 to i64
  %505 = or i64 %503, %503
  %506 = add i64 %505, %502
  %507 = add i64 %506, %503
  store i64 %507, ptr %3, align 8
  br label %174
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdList() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @0, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 -2097825024, ptr %3, align 4
  br label %6

6:                                                ; preds = %331, %126, %125, %0
  %7 = load i32, ptr %3, align 4
  %8 = sub i32 %7, -659086194
  %9 = mul i32 %8, 1486100915
  %10 = icmp slt i32 %9, 1209582311
  br i1 %10, label %244, label %246

11:                                               ; preds = %278
  store i32 0, ptr %4, align 4
  call void @printProductHeader()
  store i32 0, ptr %5, align 4
  store i32 2092316395, ptr %3, align 4
  %12 = xor i32 %2, 1208084849
  %13 = and i32 %2, %12
  %14 = or i32 %2, %12
  %15 = xor i32 %2, %12
  %16 = sub i32 %14, %15
  %17 = sub i32 %16, %13
  %18 = mul i32 %17, 76
  %19 = icmp slt i32 %18, 1
  br i1 %19, label %125, label %288

20:                                               ; preds = %264
  %21 = load i32, ptr %5, align 4
  %22 = load i32, ptr @productCount, align 4
  %23 = icmp slt i32 %21, %22
  %24 = select i1 %23, i32 1458595789, i32 -1115654349
  store i32 %24, ptr %3, align 4
  %25 = xor i32 %2, -1310949169
  %26 = and i32 %2, %25
  %27 = or i32 %2, %25
  %28 = xor i32 %2, %25
  %29 = sub i32 %27, %28
  %30 = sub i32 %29, %26
  %31 = mul i32 %30, 164
  %32 = icmp sgt i32 %31, 0
  br i1 %32, label %291, label %125

33:                                               ; preds = %284
  %34 = load i32, ptr %5, align 4
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %35
  %37 = getelementptr inbounds nuw %struct.Product, ptr %36, i32 0, i32 6
  %38 = load i32, ptr %37, align 8
  %39 = icmp ne i32 %38, 0
  %40 = select i1 %39, i32 2134197318, i32 1860555915
  store i32 %40, ptr %3, align 4
  %41 = xor i32 %2, 263793525
  %42 = and i32 %2, %41
  %43 = or i32 %2, %41
  %44 = xor i32 %2, %41
  %45 = mul i32 %43, 2
  %46 = sub i32 %45, %44
  %47 = sub i32 %46, %2
  %48 = sub i32 %47, %41
  %49 = mul i32 %48, 63
  %50 = icmp eq i32 %49, 0
  br i1 %50, label %125, label %295

51:                                               ; preds = %280
  %52 = load i32, ptr %5, align 4
  %53 = sext i32 %52 to i64
  %54 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %53
  call void @printProduct(ptr noundef %54)
  store i32 1, ptr %4, align 4
  store i32 1860555915, ptr %3, align 4
  %55 = xor i32 %2, 1599235087
  %56 = and i32 %2, %55
  %57 = or i32 %2, %55
  %58 = xor i32 %2, %55
  %59 = sub i32 %57, %58
  %60 = sub i32 %59, %56
  %61 = mul i32 %60, 77
  %62 = icmp ugt i32 %61, 0
  br i1 %62, label %303, label %125

63:                                               ; preds = %272
  %64 = load i32, ptr %5, align 4
  %65 = load i32, ptr %3, align 4
  %66 = xor i32 %65, 1860555914
  %67 = sub i32 %64, %66
  %68 = load i32, ptr %3, align 4
  %69 = xor i32 %68, 1860555913
  %70 = mul i32 %64, %69
  %71 = load i32, ptr %3, align 4
  %72 = xor i32 %71, 1860555914
  %73 = mul i32 %72, %67
  %74 = sub i32 %70, %73
  store i32 %74, ptr %5, align 4
  store i32 2092316395, ptr %3, align 4
  %75 = xor i32 %2, 1628420495
  %76 = and i32 %2, %75
  %77 = or i32 %2, %75
  %78 = xor i32 %2, %75
  %79 = add i32 %76, %77
  %80 = sub i32 %79, %2
  %81 = sub i32 %80, %75
  %82 = mul i32 %81, 94
  %83 = xor i32 %2, 1441290665
  %84 = and i32 %2, %83
  %85 = or i32 %2, %83
  %86 = xor i32 %2, %83
  %87 = add i32 %2, %83
  %88 = sub i32 %87, %86
  %89 = mul i32 %84, 2
  %90 = sub i32 %88, %89
  %91 = mul i32 %90, 189
  %92 = icmp ne i32 %82, %91
  br i1 %92, label %311, label %125

93:                                               ; preds = %254
  %94 = load i32, ptr %4, align 4
  %95 = icmp ne i32 %94, 0
  %96 = select i1 %95, i32 810959739, i32 580757223
  store i32 %96, ptr %3, align 4
  %97 = xor i32 %2, -1588089987
  %98 = and i32 %2, %97
  %99 = or i32 %2, %97
  %100 = xor i32 %2, %97
  %101 = sub i32 %99, %100
  %102 = sub i32 %101, %98
  %103 = mul i32 %102, 80
  %104 = xor i32 %2, -986591399
  %105 = and i32 %2, %104
  %106 = or i32 %2, %104
  %107 = xor i32 %2, %104
  %108 = sub i32 %106, %107
  %109 = sub i32 %108, %105
  %110 = mul i32 %109, 40
  %111 = icmp ne i32 %103, %110
  br i1 %111, label %316, label %125

112:                                              ; preds = %258
  %113 = call i32 (ptr, ...) @printf(ptr noundef @.str.28)
  store i32 810959739, ptr %3, align 4
  %114 = xor i32 %2, -1790284345
  %115 = and i32 %2, %114
  %116 = or i32 %2, %114
  %117 = xor i32 %2, %114
  %118 = mul i32 %116, 2
  %119 = sub i32 %118, %117
  %120 = sub i32 %119, %2
  %121 = sub i32 %120, %114
  %122 = mul i32 %121, 246
  %123 = icmp sgt i32 %122, 0
  br i1 %123, label %324, label %125

124:                                              ; preds = %260
  ret void

125:                                              ; preds = %367, %365, %361, %355, %348, %345, %339, %335, %324, %316, %311, %303, %295, %291, %288, %231, %209, %196, %184, %173, %160, %147, %135, %112, %93, %63, %51, %33, %20, %11
  br label %6

126:                                              ; preds = %286, %284, %278, %276, %266, %264, %258, %256
  store i32 -2097825024, ptr %3, align 4
  call void asm sideeffect "", ""()
  %127 = xor i32 %2, -362704113
  %128 = and i32 %2, %127
  %129 = or i32 %2, %127
  %130 = xor i32 %2, %127
  %131 = sub i32 %129, %130
  %132 = sub i32 %131, %128
  %133 = mul i32 %132, 141
  %134 = icmp uge i32 %133, 0
  br i1 %134, label %6, label %331

135:                                              ; preds = %276
  %136 = load i32, ptr %3, align 4
  %137 = xor i32 %136, -1533259171
  store i32 %137, ptr %3, align 4
  %138 = xor i32 %2, -281201769
  %139 = and i32 %2, %138
  %140 = or i32 %2, %138
  %141 = xor i32 %2, %138
  %142 = add i32 %139, %140
  %143 = sub i32 %142, %2
  %144 = sub i32 %143, %138
  %145 = mul i32 %144, 84
  %146 = icmp sgt i32 %145, 0
  br i1 %146, label %335, label %125

147:                                              ; preds = %282
  %148 = load i32, ptr %3, align 4
  %149 = xor i32 %148, -1388730779
  store i32 %149, ptr %3, align 4
  %150 = xor i32 %2, -704354263
  %151 = and i32 %2, %150
  %152 = or i32 %2, %150
  %153 = xor i32 %2, %150
  %154 = mul i32 %152, 2
  %155 = sub i32 %154, %153
  %156 = sub i32 %155, %2
  %157 = sub i32 %156, %150
  %158 = mul i32 %157, 155
  %159 = icmp uge i32 %158, 0
  br i1 %159, label %125, label %339

160:                                              ; preds = %256
  %161 = load i32, ptr %3, align 4
  %162 = xor i32 %161, -1968407989
  store i32 %162, ptr %3, align 4
  %163 = xor i32 %2, -1398324287
  %164 = and i32 %2, %163
  %165 = or i32 %2, %163
  %166 = xor i32 %2, %163
  %167 = mul i32 %165, 2
  %168 = sub i32 %167, %166
  %169 = sub i32 %168, %2
  %170 = sub i32 %169, %163
  %171 = mul i32 %170, 225
  %172 = icmp slt i32 %171, 1
  br i1 %172, label %125, label %345

173:                                              ; preds = %274
  %174 = load i32, ptr %3, align 4
  %175 = xor i32 %174, -408503398
  store i32 %175, ptr %3, align 4
  %176 = xor i32 %2, -701365633
  %177 = and i32 %2, %176
  %178 = or i32 %2, %176
  %179 = xor i32 %2, %176
  %180 = sub i32 %178, %179
  %181 = sub i32 %180, %177
  %182 = mul i32 %181, 13
  %183 = icmp slt i32 %182, 0
  br i1 %183, label %348, label %125

184:                                              ; preds = %286
  %185 = load i32, ptr %3, align 4
  %186 = xor i32 %185, 1853517820
  store i32 %186, ptr %3, align 4
  %187 = xor i32 %2, 1482204821
  %188 = and i32 %2, %187
  %189 = or i32 %2, %187
  %190 = xor i32 %2, %187
  %191 = add i32 %188, %189
  %192 = sub i32 %191, %2
  %193 = sub i32 %192, %187
  %194 = mul i32 %193, 2
  %195 = icmp sgt i32 %194, 0
  br i1 %195, label %355, label %125

196:                                              ; preds = %262
  %197 = load i32, ptr %3, align 4
  %198 = xor i32 %197, 1858209104
  store i32 %198, ptr %3, align 4
  %199 = xor i32 %2, -1353948049
  %200 = and i32 %2, %199
  %201 = or i32 %2, %199
  %202 = xor i32 %2, %199
  %203 = mul i32 %201, 2
  %204 = sub i32 %203, %202
  %205 = sub i32 %204, %2
  %206 = sub i32 %205, %199
  %207 = mul i32 %206, 63
  %208 = icmp sgt i32 %207, 0
  br i1 %208, label %361, label %125

209:                                              ; preds = %252
  %210 = load i32, ptr %3, align 4
  %211 = xor i32 %210, 1700152788
  store i32 %211, ptr %3, align 4
  %212 = xor i32 %2, 1240233795
  %213 = and i32 %2, %212
  %214 = or i32 %2, %212
  %215 = xor i32 %2, %212
  %216 = mul i32 %214, 2
  %217 = sub i32 %216, %215
  %218 = sub i32 %217, %2
  %219 = sub i32 %218, %212
  %220 = mul i32 %219, 179
  %221 = xor i32 %2, 675938401
  %222 = and i32 %2, %221
  %223 = or i32 %2, %221
  %224 = xor i32 %2, %221
  %225 = mul i32 %223, 2
  %226 = sub i32 %225, %224
  %227 = sub i32 %226, %2
  %228 = sub i32 %227, %221
  %229 = mul i32 %228, 107
  %230 = icmp ne i32 %220, %229
  br i1 %230, label %365, label %125

231:                                              ; preds = %266
  %232 = load i32, ptr %3, align 4
  %233 = xor i32 %232, -1233938328
  store i32 %233, ptr %3, align 4
  %234 = xor i32 %2, 1040438953
  %235 = and i32 %2, %234
  %236 = or i32 %2, %234
  %237 = xor i32 %2, %234
  %238 = mul i32 %236, 2
  %239 = sub i32 %238, %237
  %240 = sub i32 %239, %2
  %241 = sub i32 %240, %234
  %242 = mul i32 %241, 212
  %243 = icmp ugt i32 %242, 0
  br i1 %243, label %367, label %125

244:                                              ; preds = %6
  %245 = icmp slt i32 %9, 659276983
  br i1 %245, label %248, label %250

246:                                              ; preds = %6
  %247 = icmp slt i32 %9, 1370039720
  br i1 %247, label %268, label %270

248:                                              ; preds = %244
  %249 = icmp slt i32 %9, 557508191
  br i1 %249, label %252, label %254

250:                                              ; preds = %244
  %251 = icmp slt i32 %9, 732675877
  br i1 %251, label %260, label %262

252:                                              ; preds = %248
  %253 = icmp eq i32 %9, 180977831
  br i1 %253, label %209, label %256

254:                                              ; preds = %248
  %255 = icmp eq i32 %9, 557508191
  br i1 %255, label %93, label %258

256:                                              ; preds = %252
  %257 = icmp eq i32 %9, 512543079
  br i1 %257, label %160, label %126

258:                                              ; preds = %254
  %259 = icmp eq i32 %9, 576443707
  br i1 %259, label %112, label %126

260:                                              ; preds = %250
  %261 = icmp eq i32 %9, 659276983
  br i1 %261, label %124, label %264

262:                                              ; preds = %250
  %263 = icmp eq i32 %9, 732675877
  br i1 %263, label %196, label %266

264:                                              ; preds = %260
  %265 = icmp eq i32 %9, 703130631
  br i1 %265, label %20, label %126

266:                                              ; preds = %262
  %267 = icmp eq i32 %9, 969064957
  br i1 %267, label %231, label %126

268:                                              ; preds = %246
  %269 = icmp slt i32 %9, 1345848955
  br i1 %269, label %272, label %274

270:                                              ; preds = %246
  %271 = icmp slt i32 %9, 1801141760
  br i1 %271, label %280, label %282

272:                                              ; preds = %268
  %273 = icmp eq i32 %9, 1209582311
  br i1 %273, label %63, label %276

274:                                              ; preds = %268
  %275 = icmp eq i32 %9, 1345848955
  br i1 %275, label %173, label %278

276:                                              ; preds = %272
  %277 = icmp eq i32 %9, 1243040469
  br i1 %277, label %135, label %126

278:                                              ; preds = %274
  %279 = icmp eq i32 %9, 1348228022
  br i1 %279, label %11, label %126

280:                                              ; preds = %270
  %281 = icmp eq i32 %9, 1370039720
  br i1 %281, label %51, label %284

282:                                              ; preds = %270
  %283 = icmp eq i32 %9, 1801141760
  br i1 %283, label %147, label %286

284:                                              ; preds = %280
  %285 = icmp eq i32 %9, 1644637197
  br i1 %285, label %33, label %126

286:                                              ; preds = %282
  %287 = icmp eq i32 %9, 1895303786
  br i1 %287, label %184, label %126

288:                                              ; preds = %11
  %289 = load i64, ptr %1, align 8
  %290 = or i64 284057661, %289
  store i64 %290, ptr %1, align 8
  br label %125

291:                                              ; preds = %20
  %292 = load i64, ptr %1, align 8
  %293 = and i64 1571651487, %292
  %294 = add i64 %293, 69565851
  store i64 %294, ptr %1, align 8
  br label %125

295:                                              ; preds = %33
  %296 = load i64, ptr %1, align 8
  %297 = or i64 1538435763, %296
  %298 = add i64 %297, 353915839
  %299 = or i64 %298, 353915839
  %300 = and i64 %299, 353915839
  %301 = mul i64 %300, 353915839
  %302 = mul i64 %301, %296
  store i64 %302, ptr %1, align 8
  br label %125

303:                                              ; preds = %51
  %304 = load i64, ptr %1, align 8
  %305 = or i64 %304, 2701009383
  %306 = sub i64 %305, 2701009383
  %307 = add i64 %306, 1301024450
  %308 = or i64 %307, %304
  %309 = or i64 %308, 2701009383
  %310 = add i64 %309, 1301024450
  store i64 %310, ptr %1, align 8
  br label %125

311:                                              ; preds = %63
  %312 = load i64, ptr %1, align 8
  %313 = sub i64 2888840063, %312
  %314 = sub i64 %313, 3111998275
  %315 = or i64 %314, 3111998275
  store i64 %315, ptr %1, align 8
  br label %125

316:                                              ; preds = %93
  %317 = load i64, ptr %1, align 8
  %318 = and i64 %317, 1927722974
  %319 = sub i64 %318, %317
  %320 = add i64 %319, 3573549531
  %321 = and i64 %320, %317
  %322 = mul i64 %321, 1927722974
  %323 = and i64 %322, 1927722974
  store i64 %323, ptr %1, align 8
  br label %125

324:                                              ; preds = %112
  %325 = load i64, ptr %1, align 8
  %326 = and i64 -4019022955898799420, %325
  %327 = xor i64 %326, 378110405
  %328 = mul i64 %327, 3798384014
  %329 = sub i64 %328, 3798384014
  %330 = mul i64 %329, 378110405
  store i64 %330, ptr %1, align 8
  br label %125

331:                                              ; preds = %126
  %332 = load i64, ptr %1, align 8
  %333 = sub i64 32768, %332
  %334 = add i64 %333, 541372469
  store i64 %334, ptr %1, align 8
  br label %6

335:                                              ; preds = %135
  %336 = load i64, ptr %1, align 8
  %337 = or i64 5175304859, %336
  %338 = or i64 %337, 4047077236
  store i64 %338, ptr %1, align 8
  br label %125

339:                                              ; preds = %147
  %340 = load i64, ptr %1, align 8
  %341 = or i64 1751682338, %340
  %342 = add i64 %341, 1751682338
  %343 = mul i64 %342, %340
  %344 = mul i64 %343, 2021292341
  store i64 %344, ptr %1, align 8
  br label %125

345:                                              ; preds = %160
  %346 = load i64, ptr %1, align 8
  %347 = xor i64 8467035114, %346
  store i64 %347, ptr %1, align 8
  br label %125

348:                                              ; preds = %173
  %349 = load i64, ptr %1, align 8
  %350 = or i64 %349, 4096137786
  %351 = and i64 %350, 1525260919
  %352 = sub i64 %351, 4096137786
  %353 = or i64 %352, %349
  %354 = xor i64 %353, 1525260919
  store i64 %354, ptr %1, align 8
  br label %125

355:                                              ; preds = %184
  %356 = load i64, ptr %1, align 8
  %357 = mul i64 3200656000, %356
  %358 = sub i64 %357, 1832419951
  %359 = or i64 %358, %356
  %360 = sub i64 %359, %356
  store i64 %360, ptr %1, align 8
  br label %125

361:                                              ; preds = %196
  %362 = load i64, ptr %1, align 8
  %363 = xor i64 680650050, %362
  %364 = and i64 %363, 3133828478
  store i64 %364, ptr %1, align 8
  br label %125

365:                                              ; preds = %209
  %366 = load i64, ptr %1, align 8
  store i64 1523126357590713883, ptr %1, align 8
  br label %125

367:                                              ; preds = %231
  %368 = load i64, ptr %1, align 8
  %369 = xor i64 3449510578, %368
  %370 = mul i64 %369, 884419274
  %371 = sub i64 %370, %368
  %372 = xor i64 %371, 884419274
  %373 = add i64 %372, 884419274
  %374 = sub i64 %373, %368
  store i64 %374, ptr %1, align 8
  br label %125
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSearchName(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 17707730, ptr %4, align 4
  br label %9

9:                                                ; preds = %410, %202, %201, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, 958451574
  %12 = mul i32 %11, -1821063995
  switch i32 %12, label %202 [
    i32 1936713164, label %13
    i32 586952017, label %25
    i32 1051605419, label %42
    i32 1003817590, label %52
    i32 644293916, label %63
    i32 845180210, label %77
    i32 246411600, label %102
    i32 340661688, label %131
    i32 1862538918, label %144
    i32 2040967422, label %172
    i32 151704937, label %185
    i32 1787812504, label %200
    i32 783751965, label %211
    i32 300424896, label %222
    i32 764816066, label %235
    i32 638768128, label %247
    i32 272714196, label %260
    i32 1063451637, label %273
    i32 1503142893, label %286
    i32 1138731410, label %299
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 0, ptr %7, align 4
  %14 = load i32, ptr %6, align 4
  %15 = icmp ne i32 %14, 2
  %16 = select i1 %15, i32 -1008788699, i32 604460691
  store i32 %16, ptr %4, align 4
  %17 = xor i32 %1, -83090593
  %18 = and i32 %1, %17
  %19 = or i32 %1, %17
  %20 = xor i32 %1, %17
  %21 = sub i32 %19, %20
  %22 = sub i32 %21, %18
  %23 = mul i32 %22, 34
  %24 = icmp uge i32 %23, 0
  br i1 %24, label %201, label %312

25:                                               ; preds = %9
  %26 = load ptr, ptr %5, align 8
  %27 = getelementptr inbounds ptr, ptr %26, i64 1
  %28 = load ptr, ptr %27, align 8
  %29 = call i64 @strlen(ptr noundef %28) #8
  %30 = icmp eq i64 %29, 0
  %31 = select i1 %30, i32 -1008788699, i32 -271166604
  store i32 %31, ptr %4, align 4
  %32 = xor i32 %1, -407287533
  %33 = and i32 %1, %32
  %34 = or i32 %1, %32
  %35 = xor i32 %1, %32
  %36 = mul i32 %34, 2
  %37 = sub i32 %36, %35
  %38 = sub i32 %37, %1
  %39 = sub i32 %38, %32
  %40 = mul i32 %39, 71
  %41 = icmp slt i32 %40, 1
  br i1 %41, label %201, label %321

42:                                               ; preds = %9
  %43 = call i32 (ptr, ...) @printf(ptr noundef @.str.29)
  store i32 477255982, ptr %4, align 4
  %44 = xor i32 %1, -430227755
  %45 = and i32 %1, %44
  %46 = or i32 %1, %44
  %47 = xor i32 %1, %44
  %48 = sub i32 %46, %47
  %49 = sub i32 %48, %45
  %50 = mul i32 %49, 200
  %51 = icmp ne i32 %50, 0
  br i1 %51, label %330, label %201

52:                                               ; preds = %9
  call void @printProductHeader()
  store i32 0, ptr %8, align 4
  store i32 527075810, ptr %4, align 4
  %53 = xor i32 %1, 1064944631
  %54 = and i32 %1, %53
  %55 = or i32 %1, %53
  %56 = xor i32 %1, %53
  %57 = mul i32 %55, 2
  %58 = sub i32 %57, %56
  %59 = sub i32 %58, %1
  %60 = sub i32 %59, %53
  %61 = mul i32 %60, 220
  %62 = icmp eq i32 %61, 0
  br i1 %62, label %201, label %340

63:                                               ; preds = %9
  %64 = load i32, ptr %8, align 4
  %65 = load i32, ptr @productCount, align 4
  %66 = icmp slt i32 %64, %65
  %67 = select i1 %66, i32 1324969728, i32 -1571448740
  store i32 %67, ptr %4, align 4
  %68 = xor i32 %1, 1487020317
  %69 = and i32 %1, %68
  %70 = or i32 %1, %68
  %71 = xor i32 %1, %68
  %72 = add i32 %69, %70
  %73 = sub i32 %72, %1
  %74 = sub i32 %73, %68
  %75 = mul i32 %74, 215
  %76 = icmp sle i32 %75, 0
  br i1 %76, label %201, label %348

77:                                               ; preds = %9
  %78 = load i32, ptr %8, align 4
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %79
  %81 = getelementptr inbounds nuw %struct.Product, ptr %80, i32 0, i32 6
  %82 = load i32, ptr %81, align 8
  %83 = icmp ne i32 %82, 0
  %84 = select i1 %83, i32 -1645072250, i32 1041682916
  store i32 %84, ptr %4, align 4
  %85 = xor i32 %1, -1774024287
  %86 = and i32 %1, %85
  %87 = or i32 %1, %85
  %88 = xor i32 %1, %85
  %89 = sub i32 %87, %88
  %90 = sub i32 %89, %86
  %91 = mul i32 %90, 71
  %92 = xor i32 %1, -1589369291
  %93 = and i32 %1, %92
  %94 = or i32 %1, %92
  %95 = xor i32 %1, %92
  %96 = mul i32 %94, 2
  %97 = sub i32 %96, %95
  %98 = sub i32 %97, %1
  %99 = sub i32 %98, %92
  %100 = mul i32 %99, 130
  %101 = icmp eq i32 %91, %100
  br i1 %101, label %201, label %356

102:                                              ; preds = %9
  %103 = load i32, ptr %8, align 4
  %104 = sext i32 %103 to i64
  %105 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %104
  %106 = getelementptr inbounds nuw %struct.Product, ptr %105, i32 0, i32 1
  %107 = getelementptr inbounds [80 x i8], ptr %106, i64 0, i64 0
  %108 = load ptr, ptr %5, align 8
  %109 = getelementptr inbounds ptr, ptr %108, i64 1
  %110 = load ptr, ptr %109, align 8
  %111 = call i32 @containsIgnoreCase(ptr noundef %107, ptr noundef %110)
  %112 = icmp ne i32 %111, 0
  %113 = select i1 %112, i32 -86206002, i32 1041682916
  store i32 %113, ptr %4, align 4
  %114 = xor i32 %1, -233479347
  %115 = and i32 %1, %114
  %116 = or i32 %1, %114
  %117 = xor i32 %1, %114
  %118 = add i32 %1, %114
  %119 = sub i32 %118, %117
  %120 = mul i32 %115, 2
  %121 = sub i32 %119, %120
  %122 = mul i32 %121, 65
  %123 = xor i32 %1, 1029277103
  %124 = and i32 %1, %123
  %125 = or i32 %1, %123
  %126 = xor i32 %1, %123
  %127 = sub i32 %125, %126
  %128 = sub i32 %127, %124
  %129 = mul i32 %128, 133
  %130 = icmp eq i32 %122, %129
  br i1 %130, label %201, label %364

131:                                              ; preds = %9
  %132 = load i32, ptr %8, align 4
  %133 = sext i32 %132 to i64
  %134 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %133
  call void @printProduct(ptr noundef %134)
  store i32 1, ptr %7, align 4
  store i32 1041682916, ptr %4, align 4
  %135 = xor i32 %1, 1877329099
  %136 = and i32 %1, %135
  %137 = or i32 %1, %135
  %138 = xor i32 %1, %135
  %139 = add i32 %136, %137
  %140 = sub i32 %139, %1
  %141 = sub i32 %140, %135
  %142 = mul i32 %141, 140
  %143 = icmp slt i32 %142, 0
  br i1 %143, label %374, label %201

144:                                              ; preds = %9
  %145 = load i32, ptr %8, align 4
  %146 = load i32, ptr %4, align 4
  %147 = xor i32 %146, 1041682917
  %148 = xor i32 %145, %147
  %149 = load i32, ptr %4, align 4
  %150 = xor i32 %149, 1041682917
  %151 = and i32 %145, %150
  %152 = add i32 %151, %151
  %153 = add i32 %148, %152
  store i32 %153, ptr %8, align 4
  store i32 527075810, ptr %4, align 4
  %154 = xor i32 %1, -1276128687
  %155 = and i32 %1, %154
  %156 = or i32 %1, %154
  %157 = xor i32 %1, %154
  %158 = add i32 %155, %156
  %159 = sub i32 %158, %1
  %160 = sub i32 %159, %154
  %161 = mul i32 %160, 187
  %162 = xor i32 %1, 1704899067
  %163 = and i32 %1, %162
  %164 = or i32 %1, %162
  %165 = xor i32 %1, %162
  %166 = mul i32 %164, 2
  %167 = sub i32 %166, %165
  %168 = sub i32 %167, %1
  %169 = sub i32 %168, %162
  %170 = mul i32 %169, 105
  %171 = icmp eq i32 %161, %170
  br i1 %171, label %201, label %384

172:                                              ; preds = %9
  %173 = load i32, ptr %7, align 4
  %174 = icmp ne i32 %173, 0
  %175 = select i1 %174, i32 477255982, i32 1118326731
  store i32 %175, ptr %4, align 4
  %176 = xor i32 %1, -1135050731
  %177 = and i32 %1, %176
  %178 = or i32 %1, %176
  %179 = xor i32 %1, %176
  %180 = add i32 %177, %178
  %181 = sub i32 %180, %1
  %182 = sub i32 %181, %176
  %183 = mul i32 %182, 4
  %184 = icmp eq i32 %183, 0
  br i1 %184, label %201, label %391

185:                                              ; preds = %9
  %186 = load ptr, ptr %5, align 8
  %187 = getelementptr inbounds ptr, ptr %186, i64 1
  %188 = load ptr, ptr %187, align 8
  %189 = call i32 (ptr, ...) @printf(ptr noundef @.str.30, ptr noundef %188)
  store i32 477255982, ptr %4, align 4
  %190 = xor i32 %1, -518079803
  %191 = and i32 %1, %190
  %192 = or i32 %1, %190
  %193 = xor i32 %1, %190
  %194 = mul i32 %192, 2
  %195 = sub i32 %194, %193
  %196 = sub i32 %195, %1
  %197 = sub i32 %196, %190
  %198 = mul i32 %197, 167
  %199 = icmp ugt i32 %198, 0
  br i1 %199, label %400, label %201

200:                                              ; preds = %9
  ret void

201:                                              ; preds = %480, %470, %460, %452, %445, %435, %427, %418, %400, %391, %384, %374, %364, %356, %348, %340, %330, %321, %312, %299, %286, %273, %260, %247, %235, %222, %211, %185, %172, %144, %131, %102, %77, %63, %52, %42, %25, %13
  br label %9

202:                                              ; preds = %9
  store i32 17707730, ptr %4, align 4
  call void asm sideeffect "", ""()
  %203 = xor i32 %1, 1176922029
  %204 = and i32 %1, %203
  %205 = or i32 %1, %203
  %206 = xor i32 %1, %203
  %207 = sub i32 %205, %206
  %208 = sub i32 %207, %204
  %209 = mul i32 %208, 79
  %210 = icmp slt i32 %209, 0
  br i1 %210, label %410, label %9

211:                                              ; preds = %9
  %212 = load i32, ptr %4, align 4
  %213 = xor i32 %212, -1452611282
  store i32 %213, ptr %4, align 4
  %214 = xor i32 %1, -1175274999
  %215 = and i32 %1, %214
  %216 = or i32 %1, %214
  %217 = xor i32 %1, %214
  %218 = sub i32 %216, %217
  %219 = sub i32 %218, %215
  %220 = mul i32 %219, 11
  %221 = icmp uge i32 %220, 0
  br i1 %221, label %201, label %418

222:                                              ; preds = %9
  %223 = load i32, ptr %4, align 4
  %224 = xor i32 %223, 56200071
  store i32 %224, ptr %4, align 4
  %225 = xor i32 %1, 508126987
  %226 = and i32 %1, %225
  %227 = or i32 %1, %225
  %228 = xor i32 %1, %225
  %229 = add i32 %1, %225
  %230 = sub i32 %229, %228
  %231 = mul i32 %226, 2
  %232 = sub i32 %230, %231
  %233 = mul i32 %232, 71
  %234 = icmp uge i32 %233, 0
  br i1 %234, label %201, label %427

235:                                              ; preds = %9
  %236 = load i32, ptr %4, align 4
  %237 = xor i32 %236, 61972860
  store i32 %237, ptr %4, align 4
  %238 = xor i32 %1, 1169997711
  %239 = and i32 %1, %238
  %240 = or i32 %1, %238
  %241 = xor i32 %1, %238
  %242 = add i32 %239, %240
  %243 = sub i32 %242, %1
  %244 = sub i32 %243, %238
  %245 = mul i32 %244, 150
  %246 = icmp sle i32 %245, 0
  br i1 %246, label %201, label %435

247:                                              ; preds = %9
  %248 = load i32, ptr %4, align 4
  %249 = xor i32 %248, -617706028
  store i32 %249, ptr %4, align 4
  %250 = xor i32 %1, -1479574529
  %251 = and i32 %1, %250
  %252 = or i32 %1, %250
  %253 = xor i32 %1, %250
  %254 = add i32 %1, %250
  %255 = sub i32 %254, %253
  %256 = mul i32 %251, 2
  %257 = sub i32 %255, %256
  %258 = mul i32 %257, 74
  %259 = icmp uge i32 %258, 0
  br i1 %259, label %201, label %445

260:                                              ; preds = %9
  %261 = load i32, ptr %4, align 4
  %262 = xor i32 %261, 323194333
  store i32 %262, ptr %4, align 4
  %263 = xor i32 %1, 1181946607
  %264 = and i32 %1, %263
  %265 = or i32 %1, %263
  %266 = xor i32 %1, %263
  %267 = add i32 %1, %263
  %268 = sub i32 %267, %266
  %269 = mul i32 %264, 2
  %270 = sub i32 %268, %269
  %271 = mul i32 %270, 71
  %272 = icmp sgt i32 %271, 0
  br i1 %272, label %452, label %201

273:                                              ; preds = %9
  %274 = load i32, ptr %4, align 4
  %275 = xor i32 %274, -643261353
  store i32 %275, ptr %4, align 4
  %276 = xor i32 %1, 675739087
  %277 = and i32 %1, %276
  %278 = or i32 %1, %276
  %279 = xor i32 %1, %276
  %280 = mul i32 %278, 2
  %281 = sub i32 %280, %279
  %282 = sub i32 %281, %1
  %283 = sub i32 %282, %276
  %284 = mul i32 %283, 55
  %285 = icmp sle i32 %284, 0
  br i1 %285, label %201, label %460

286:                                              ; preds = %9
  %287 = load i32, ptr %4, align 4
  %288 = xor i32 %287, -1499607964
  store i32 %288, ptr %4, align 4
  %289 = xor i32 %1, 1704677341
  %290 = and i32 %1, %289
  %291 = or i32 %1, %289
  %292 = xor i32 %1, %289
  %293 = mul i32 %291, 2
  %294 = sub i32 %293, %292
  %295 = sub i32 %294, %1
  %296 = sub i32 %295, %289
  %297 = mul i32 %296, 176
  %298 = icmp ne i32 %297, 0
  br i1 %298, label %470, label %201

299:                                              ; preds = %9
  %300 = load i32, ptr %4, align 4
  %301 = xor i32 %300, -1815529962
  store i32 %301, ptr %4, align 4
  %302 = xor i32 %1, 974540373
  %303 = and i32 %1, %302
  %304 = or i32 %1, %302
  %305 = xor i32 %1, %302
  %306 = add i32 %1, %302
  %307 = sub i32 %306, %305
  %308 = mul i32 %303, 2
  %309 = sub i32 %307, %308
  %310 = mul i32 %309, 153
  %311 = icmp slt i32 %310, 1
  br i1 %311, label %201, label %480

312:                                              ; preds = %13
  %313 = load i64, ptr %3, align 8
  %314 = ptrtoint ptr %0 to i64
  %315 = zext i32 %1 to i64
  %316 = xor i64 %314, %313
  %317 = xor i64 %316, %313
  %318 = mul i64 %317, %313
  %319 = add i64 %318, %313
  %320 = add i64 %319, %315
  store i64 %320, ptr %3, align 8
  br label %201

321:                                              ; preds = %25
  %322 = load i64, ptr %3, align 8
  %323 = ptrtoint ptr %0 to i64
  %324 = zext i32 %1 to i64
  %325 = add i64 %323, %324
  %326 = sub i64 %325, %324
  %327 = add i64 %326, %322
  %328 = and i64 %327, %324
  %329 = or i64 %328, %323
  store i64 %329, ptr %3, align 8
  br label %201

330:                                              ; preds = %42
  %331 = load i64, ptr %3, align 8
  %332 = ptrtoint ptr %0 to i64
  %333 = zext i32 %1 to i64
  %334 = xor i64 %333, %333
  %335 = sub i64 %334, %333
  %336 = or i64 %335, %331
  %337 = or i64 %336, %332
  %338 = or i64 %337, %332
  %339 = mul i64 %338, %333
  store i64 %339, ptr %3, align 8
  br label %201

340:                                              ; preds = %52
  %341 = load i64, ptr %3, align 8
  %342 = ptrtoint ptr %0 to i64
  %343 = zext i32 %1 to i64
  %344 = mul i64 %343, %341
  %345 = add i64 %344, %342
  %346 = or i64 %345, %343
  %347 = or i64 %346, %341
  store i64 %347, ptr %3, align 8
  br label %201

348:                                              ; preds = %63
  %349 = load i64, ptr %3, align 8
  %350 = ptrtoint ptr %0 to i64
  %351 = zext i32 %1 to i64
  %352 = xor i64 %350, %351
  %353 = and i64 %352, %350
  %354 = add i64 %353, %351
  %355 = or i64 %354, %349
  store i64 %355, ptr %3, align 8
  br label %201

356:                                              ; preds = %77
  %357 = load i64, ptr %3, align 8
  %358 = ptrtoint ptr %0 to i64
  %359 = zext i32 %1 to i64
  %360 = and i64 %358, %358
  %361 = xor i64 %360, %358
  %362 = mul i64 %361, %359
  %363 = add i64 %362, %359
  store i64 %363, ptr %3, align 8
  br label %201

364:                                              ; preds = %102
  %365 = load i64, ptr %3, align 8
  %366 = ptrtoint ptr %0 to i64
  %367 = zext i32 %1 to i64
  %368 = add i64 %365, %365
  %369 = mul i64 %368, %366
  %370 = add i64 %369, %367
  %371 = and i64 %370, %367
  %372 = xor i64 %371, %367
  %373 = sub i64 %372, %365
  store i64 %373, ptr %3, align 8
  br label %201

374:                                              ; preds = %131
  %375 = load i64, ptr %3, align 8
  %376 = ptrtoint ptr %0 to i64
  %377 = zext i32 %1 to i64
  %378 = xor i64 %375, %377
  %379 = or i64 %378, %375
  %380 = add i64 %379, %376
  %381 = add i64 %380, %375
  %382 = or i64 %381, %377
  %383 = and i64 %382, %375
  store i64 %383, ptr %3, align 8
  br label %201

384:                                              ; preds = %144
  %385 = load i64, ptr %3, align 8
  %386 = ptrtoint ptr %0 to i64
  %387 = zext i32 %1 to i64
  %388 = and i64 %387, %385
  %389 = add i64 %388, %386
  %390 = sub i64 %389, %386
  store i64 %390, ptr %3, align 8
  br label %201

391:                                              ; preds = %172
  %392 = load i64, ptr %3, align 8
  %393 = ptrtoint ptr %0 to i64
  %394 = zext i32 %1 to i64
  %395 = or i64 %394, %393
  %396 = or i64 %395, %392
  %397 = or i64 %396, %394
  %398 = add i64 %397, %393
  %399 = sub i64 %398, %394
  store i64 %399, ptr %3, align 8
  br label %201

400:                                              ; preds = %185
  %401 = load i64, ptr %3, align 8
  %402 = ptrtoint ptr %0 to i64
  %403 = zext i32 %1 to i64
  %404 = add i64 %401, %401
  %405 = and i64 %404, %403
  %406 = xor i64 %405, %403
  %407 = mul i64 %406, %402
  %408 = add i64 %407, %403
  %409 = xor i64 %408, %403
  store i64 %409, ptr %3, align 8
  br label %201

410:                                              ; preds = %202
  %411 = load i64, ptr %3, align 8
  %412 = ptrtoint ptr %0 to i64
  %413 = zext i32 %1 to i64
  %414 = sub i64 %411, %413
  %415 = and i64 %414, %413
  %416 = or i64 %415, %411
  %417 = and i64 %416, %411
  store i64 %417, ptr %3, align 8
  br label %9

418:                                              ; preds = %211
  %419 = load i64, ptr %3, align 8
  %420 = ptrtoint ptr %0 to i64
  %421 = zext i32 %1 to i64
  %422 = mul i64 %420, %419
  %423 = mul i64 %422, %421
  %424 = add i64 %423, %420
  %425 = mul i64 %424, %421
  %426 = sub i64 %425, %419
  store i64 %426, ptr %3, align 8
  br label %201

427:                                              ; preds = %222
  %428 = load i64, ptr %3, align 8
  %429 = ptrtoint ptr %0 to i64
  %430 = zext i32 %1 to i64
  %431 = add i64 %428, %430
  %432 = add i64 %431, %428
  %433 = sub i64 %432, %430
  %434 = or i64 %433, %429
  store i64 %434, ptr %3, align 8
  br label %201

435:                                              ; preds = %235
  %436 = load i64, ptr %3, align 8
  %437 = ptrtoint ptr %0 to i64
  %438 = zext i32 %1 to i64
  %439 = sub i64 %438, %438
  %440 = or i64 %439, %438
  %441 = and i64 %440, %437
  %442 = mul i64 %441, %438
  %443 = sub i64 %442, %436
  %444 = add i64 %443, %436
  store i64 %444, ptr %3, align 8
  br label %201

445:                                              ; preds = %247
  %446 = load i64, ptr %3, align 8
  %447 = ptrtoint ptr %0 to i64
  %448 = zext i32 %1 to i64
  %449 = and i64 %446, %446
  %450 = mul i64 %449, %448
  %451 = sub i64 %450, %448
  store i64 %451, ptr %3, align 8
  br label %201

452:                                              ; preds = %260
  %453 = load i64, ptr %3, align 8
  %454 = ptrtoint ptr %0 to i64
  %455 = zext i32 %1 to i64
  %456 = and i64 %455, %453
  %457 = add i64 %456, %453
  %458 = mul i64 %457, %453
  %459 = sub i64 %458, %453
  store i64 %459, ptr %3, align 8
  br label %201

460:                                              ; preds = %273
  %461 = load i64, ptr %3, align 8
  %462 = ptrtoint ptr %0 to i64
  %463 = zext i32 %1 to i64
  %464 = sub i64 %461, %461
  %465 = or i64 %464, %461
  %466 = sub i64 %465, %463
  %467 = mul i64 %466, %461
  %468 = or i64 %467, %463
  %469 = and i64 %468, %461
  store i64 %469, ptr %3, align 8
  br label %201

470:                                              ; preds = %286
  %471 = load i64, ptr %3, align 8
  %472 = ptrtoint ptr %0 to i64
  %473 = zext i32 %1 to i64
  %474 = or i64 %473, %472
  %475 = or i64 %474, %471
  %476 = add i64 %475, %471
  %477 = mul i64 %476, %473
  %478 = sub i64 %477, %471
  %479 = add i64 %478, %472
  store i64 %479, ptr %3, align 8
  br label %201

480:                                              ; preds = %299
  %481 = load i64, ptr %3, align 8
  %482 = ptrtoint ptr %0 to i64
  %483 = zext i32 %1 to i64
  %484 = mul i64 %481, %481
  %485 = add i64 %484, %482
  %486 = xor i64 %485, %483
  store i64 %486, ptr %3, align 8
  br label %201
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSearchCategory(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 -1253719060, ptr %4, align 4
  br label %9

9:                                                ; preds = %400, %198, %197, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, -2136070007
  %12 = mul i32 %11, 592116835
  switch i32 %12, label %198 [
    i32 120884041, label %13
    i32 1416191988, label %27
    i32 499936267, label %44
    i32 1969509449, label %55
    i32 231656890, label %73
    i32 1185775752, label %88
    i32 1709408553, label %105
    i32 545948197, label %125
    i32 1923490265, label %139
    i32 1283753053, label %158
    i32 1127029912, label %172
    i32 1952070040, label %196
    i32 706119432, label %209
    i32 852897714, label %220
    i32 1223416059, label %233
    i32 307749469, label %245
    i32 340481934, label %257
    i32 842835857, label %269
    i32 1970050157, label %282
    i32 501851420, label %293
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 0, ptr %7, align 4
  %14 = load i32, ptr %6, align 4
  %15 = icmp ne i32 %14, 2
  %16 = select i1 %15, i32 1295984322, i32 454330629
  store i32 %16, ptr %4, align 4
  %17 = xor i32 %1, -1673672731
  %18 = and i32 %1, %17
  %19 = or i32 %1, %17
  %20 = xor i32 %1, %17
  %21 = add i32 %1, %17
  %22 = sub i32 %21, %20
  %23 = mul i32 %18, 2
  %24 = sub i32 %22, %23
  %25 = mul i32 %24, 188
  %26 = icmp eq i32 %25, 0
  br i1 %26, label %197, label %305

27:                                               ; preds = %9
  %28 = load ptr, ptr %5, align 8
  %29 = getelementptr inbounds ptr, ptr %28, i64 1
  %30 = load ptr, ptr %29, align 8
  %31 = call i64 @strlen(ptr noundef %30) #8
  %32 = icmp eq i64 %31, 0
  %33 = select i1 %32, i32 1295984322, i32 -1768773908
  store i32 %33, ptr %4, align 4
  %34 = xor i32 %1, 2035896647
  %35 = and i32 %1, %34
  %36 = or i32 %1, %34
  %37 = xor i32 %1, %34
  %38 = add i32 %1, %34
  %39 = sub i32 %38, %37
  %40 = mul i32 %35, 2
  %41 = sub i32 %39, %40
  %42 = mul i32 %41, 211
  %43 = icmp sle i32 %42, 0
  br i1 %43, label %197, label %315

44:                                               ; preds = %9
  %45 = call i32 (ptr, ...) @printf(ptr noundef @.str.31)
  store i32 -922877935, ptr %4, align 4
  %46 = xor i32 %1, -1584312293
  %47 = and i32 %1, %46
  %48 = or i32 %1, %46
  %49 = xor i32 %1, %46
  %50 = add i32 %47, %48
  %51 = sub i32 %50, %1
  %52 = sub i32 %51, %46
  %53 = mul i32 %52, 89
  %54 = icmp ugt i32 %53, 0
  br i1 %54, label %325, label %197

55:                                               ; preds = %9
  call void @printProductHeader()
  store i32 0, ptr %8, align 4
  store i32 168087559, ptr %4, align 4
  %56 = xor i32 %1, 590037779
  %57 = and i32 %1, %56
  %58 = or i32 %1, %56
  %59 = xor i32 %1, %56
  %60 = sub i32 %58, %59
  %61 = sub i32 %60, %57
  %62 = mul i32 %61, 141
  %63 = xor i32 %1, 2075768775
  %64 = and i32 %1, %63
  %65 = or i32 %1, %63
  %66 = xor i32 %1, %63
  %67 = mul i32 %65, 2
  %68 = sub i32 %67, %66
  %69 = sub i32 %68, %1
  %70 = sub i32 %69, %63
  %71 = mul i32 %70, 120
  %72 = icmp eq i32 %62, %71
  br i1 %72, label %197, label %334

73:                                               ; preds = %9
  %74 = load i32, ptr %8, align 4
  %75 = load i32, ptr @productCount, align 4
  %76 = icmp slt i32 %74, %75
  %77 = select i1 %76, i32 787511393, i32 -712728376
  store i32 %77, ptr %4, align 4
  %78 = xor i32 %1, 1060253673
  %79 = and i32 %1, %78
  %80 = or i32 %1, %78
  %81 = xor i32 %1, %78
  %82 = add i32 %1, %78
  %83 = sub i32 %82, %81
  %84 = mul i32 %79, 2
  %85 = sub i32 %83, %84
  %86 = mul i32 %85, 155
  %87 = icmp ugt i32 %86, 0
  br i1 %87, label %343, label %197

88:                                               ; preds = %9
  %89 = load i32, ptr %8, align 4
  %90 = sext i32 %89 to i64
  %91 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %90
  %92 = getelementptr inbounds nuw %struct.Product, ptr %91, i32 0, i32 6
  %93 = load i32, ptr %92, align 8
  %94 = icmp ne i32 %93, 0
  %95 = select i1 %94, i32 715730060, i32 -2115784676
  store i32 %95, ptr %4, align 4
  %96 = xor i32 %1, 1454793469
  %97 = and i32 %1, %96
  %98 = or i32 %1, %96
  %99 = xor i32 %1, %96
  %100 = add i32 %97, %98
  %101 = sub i32 %100, %1
  %102 = sub i32 %101, %96
  %103 = mul i32 %102, 212
  %104 = icmp slt i32 %103, 0
  br i1 %104, label %353, label %197

105:                                              ; preds = %9
  %106 = load i32, ptr %8, align 4
  %107 = sext i32 %106 to i64
  %108 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %107
  %109 = getelementptr inbounds nuw %struct.Product, ptr %108, i32 0, i32 2
  %110 = getelementptr inbounds [50 x i8], ptr %109, i64 0, i64 0
  %111 = load ptr, ptr %5, align 8
  %112 = getelementptr inbounds ptr, ptr %111, i64 1
  %113 = load ptr, ptr %112, align 8
  %114 = call i32 @containsIgnoreCase(ptr noundef %110, ptr noundef %113)
  %115 = icmp ne i32 %114, 0
  %116 = select i1 %115, i32 -1830952352, i32 -2115784676
  store i32 %116, ptr %4, align 4
  %117 = xor i32 %1, 1676769111
  %118 = and i32 %1, %117
  %119 = or i32 %1, %117
  %120 = xor i32 %1, %117
  %121 = sub i32 %119, %120
  %122 = sub i32 %121, %118
  %123 = mul i32 %122, 15
  %124 = icmp ne i32 %123, 0
  br i1 %124, label %361, label %197

125:                                              ; preds = %9
  %126 = load i32, ptr %8, align 4
  %127 = sext i32 %126 to i64
  %128 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %127
  call void @printProduct(ptr noundef %128)
  store i32 1, ptr %7, align 4
  store i32 -2115784676, ptr %4, align 4
  %129 = xor i32 %1, -1128865717
  %130 = and i32 %1, %129
  %131 = or i32 %1, %129
  %132 = xor i32 %1, %129
  %133 = mul i32 %131, 2
  %134 = sub i32 %133, %132
  %135 = sub i32 %134, %1
  %136 = sub i32 %135, %129
  %137 = mul i32 %136, 76
  %138 = icmp slt i32 %137, 0
  br i1 %138, label %369, label %197

139:                                              ; preds = %9
  %140 = load i32, ptr %8, align 4
  %141 = load i32, ptr %4, align 4
  %142 = xor i32 %141, -2115784675
  %143 = xor i32 %140, %142
  %144 = load i32, ptr %4, align 4
  %145 = xor i32 %144, -2115784675
  %146 = and i32 %140, %145
  %147 = add i32 %146, %146
  %148 = add i32 %143, %147
  store i32 %148, ptr %8, align 4
  store i32 168087559, ptr %4, align 4
  %149 = xor i32 %1, -1958460913
  %150 = and i32 %1, %149
  %151 = or i32 %1, %149
  %152 = xor i32 %1, %149
  %153 = add i32 %150, %151
  %154 = sub i32 %153, %1
  %155 = sub i32 %154, %149
  %156 = mul i32 %155, 251
  %157 = icmp slt i32 %156, 0
  br i1 %157, label %376, label %197

158:                                              ; preds = %9
  %159 = load i32, ptr %7, align 4
  %160 = icmp ne i32 %159, 0
  %161 = select i1 %160, i32 -922877935, i32 -1990885103
  store i32 %161, ptr %4, align 4
  %162 = xor i32 %1, -433704825
  %163 = and i32 %1, %162
  %164 = or i32 %1, %162
  %165 = xor i32 %1, %162
  %166 = add i32 %1, %162
  %167 = sub i32 %166, %165
  %168 = mul i32 %163, 2
  %169 = sub i32 %167, %168
  %170 = mul i32 %169, 131
  %171 = icmp ne i32 %170, 0
  br i1 %171, label %386, label %197

172:                                              ; preds = %9
  %173 = load ptr, ptr %5, align 8
  %174 = getelementptr inbounds ptr, ptr %173, i64 1
  %175 = load ptr, ptr %174, align 8
  %176 = call i32 (ptr, ...) @printf(ptr noundef @.str.32, ptr noundef %175)
  store i32 -922877935, ptr %4, align 4
  %177 = xor i32 %1, -215664987
  %178 = and i32 %1, %177
  %179 = or i32 %1, %177
  %180 = xor i32 %1, %177
  %181 = mul i32 %179, 2
  %182 = sub i32 %181, %180
  %183 = sub i32 %182, %1
  %184 = sub i32 %183, %177
  %185 = mul i32 %184, 76
  %186 = xor i32 %1, 173357413
  %187 = and i32 %1, %186
  %188 = or i32 %1, %186
  %189 = xor i32 %1, %186
  %190 = mul i32 %188, 2
  %191 = sub i32 %190, %189
  %192 = sub i32 %191, %1
  %193 = sub i32 %192, %186
  %194 = mul i32 %193, 80
  %195 = icmp eq i32 %185, %194
  br i1 %195, label %197, label %393

196:                                              ; preds = %9
  ret void

197:                                              ; preds = %471, %462, %453, %443, %434, %425, %415, %408, %393, %386, %376, %369, %361, %353, %343, %334, %325, %315, %305, %293, %282, %269, %257, %245, %233, %220, %209, %172, %158, %139, %125, %105, %88, %73, %55, %44, %27, %13
  br label %9

198:                                              ; preds = %9
  store i32 -1253719060, ptr %4, align 4
  call void asm sideeffect "", ""()
  %199 = xor i32 %1, 2010325941
  %200 = and i32 %1, %199
  %201 = or i32 %1, %199
  %202 = xor i32 %1, %199
  %203 = add i32 %1, %199
  %204 = sub i32 %203, %202
  %205 = mul i32 %200, 2
  %206 = sub i32 %204, %205
  %207 = mul i32 %206, 161
  %208 = icmp eq i32 %207, 0
  br i1 %208, label %9, label %400

209:                                              ; preds = %9
  %210 = load i32, ptr %4, align 4
  %211 = xor i32 %210, 706550624
  store i32 %211, ptr %4, align 4
  %212 = xor i32 %1, -583798189
  %213 = and i32 %1, %212
  %214 = or i32 %1, %212
  %215 = xor i32 %1, %212
  %216 = sub i32 %214, %215
  %217 = sub i32 %216, %213
  %218 = mul i32 %217, 250
  %219 = icmp uge i32 %218, 0
  br i1 %219, label %197, label %408

220:                                              ; preds = %9
  %221 = load i32, ptr %4, align 4
  %222 = xor i32 %221, 1040184138
  store i32 %222, ptr %4, align 4
  %223 = xor i32 %1, 1662776501
  %224 = and i32 %1, %223
  %225 = or i32 %1, %223
  %226 = xor i32 %1, %223
  %227 = mul i32 %225, 2
  %228 = sub i32 %227, %226
  %229 = sub i32 %228, %1
  %230 = sub i32 %229, %223
  %231 = mul i32 %230, 193
  %232 = icmp ne i32 %231, 0
  br i1 %232, label %415, label %197

233:                                              ; preds = %9
  %234 = load i32, ptr %4, align 4
  %235 = xor i32 %234, 2139826488
  store i32 %235, ptr %4, align 4
  %236 = xor i32 %1, 112388203
  %237 = and i32 %1, %236
  %238 = or i32 %1, %236
  %239 = xor i32 %1, %236
  %240 = add i32 %237, %238
  %241 = sub i32 %240, %1
  %242 = sub i32 %241, %236
  %243 = mul i32 %242, 146
  %244 = icmp uge i32 %243, 0
  br i1 %244, label %197, label %425

245:                                              ; preds = %9
  %246 = load i32, ptr %4, align 4
  %247 = xor i32 %246, 884467275
  store i32 %247, ptr %4, align 4
  %248 = xor i32 %1, 788865487
  %249 = and i32 %1, %248
  %250 = or i32 %1, %248
  %251 = xor i32 %1, %248
  %252 = add i32 %249, %250
  %253 = sub i32 %252, %1
  %254 = sub i32 %253, %248
  %255 = mul i32 %254, 94
  %256 = icmp sle i32 %255, 0
  br i1 %256, label %197, label %434

257:                                              ; preds = %9
  %258 = load i32, ptr %4, align 4
  %259 = xor i32 %258, 1667255376
  store i32 %259, ptr %4, align 4
  %260 = xor i32 %1, 252403083
  %261 = and i32 %1, %260
  %262 = or i32 %1, %260
  %263 = xor i32 %1, %260
  %264 = add i32 %261, %262
  %265 = sub i32 %264, %1
  %266 = sub i32 %265, %260
  %267 = mul i32 %266, 25
  %268 = icmp ugt i32 %267, 0
  br i1 %268, label %443, label %197

269:                                              ; preds = %9
  %270 = load i32, ptr %4, align 4
  %271 = xor i32 %270, 1747237679
  store i32 %271, ptr %4, align 4
  %272 = xor i32 %1, 1077910481
  %273 = and i32 %1, %272
  %274 = or i32 %1, %272
  %275 = xor i32 %1, %272
  %276 = mul i32 %274, 2
  %277 = sub i32 %276, %275
  %278 = sub i32 %277, %1
  %279 = sub i32 %278, %272
  %280 = mul i32 %279, 82
  %281 = icmp sgt i32 %280, 0
  br i1 %281, label %453, label %197

282:                                              ; preds = %9
  %283 = load i32, ptr %4, align 4
  %284 = xor i32 %283, 943229742
  store i32 %284, ptr %4, align 4
  %285 = xor i32 %1, -1741879329
  %286 = and i32 %1, %285
  %287 = or i32 %1, %285
  %288 = xor i32 %1, %285
  %289 = sub i32 %287, %288
  %290 = sub i32 %289, %286
  %291 = mul i32 %290, 233
  %292 = icmp uge i32 %291, 0
  br i1 %292, label %197, label %462

293:                                              ; preds = %9
  %294 = load i32, ptr %4, align 4
  %295 = xor i32 %294, -771809198
  store i32 %295, ptr %4, align 4
  %296 = xor i32 %1, 149509137
  %297 = and i32 %1, %296
  %298 = or i32 %1, %296
  %299 = xor i32 %1, %296
  %300 = add i32 %297, %298
  %301 = sub i32 %300, %1
  %302 = sub i32 %301, %296
  %303 = mul i32 %302, 255
  %304 = icmp sgt i32 %303, 0
  br i1 %304, label %471, label %197

305:                                              ; preds = %13
  %306 = load i64, ptr %3, align 8
  %307 = ptrtoint ptr %0 to i64
  %308 = zext i32 %1 to i64
  %309 = add i64 %308, %306
  %310 = mul i64 %309, %307
  %311 = or i64 %310, %306
  %312 = xor i64 %311, %307
  %313 = xor i64 %312, %308
  %314 = or i64 %313, %307
  store i64 %314, ptr %3, align 8
  br label %197

315:                                              ; preds = %27
  %316 = load i64, ptr %3, align 8
  %317 = ptrtoint ptr %0 to i64
  %318 = zext i32 %1 to i64
  %319 = mul i64 %317, %316
  %320 = and i64 %319, %318
  %321 = add i64 %320, %316
  %322 = or i64 %321, %316
  %323 = xor i64 %322, %316
  %324 = or i64 %323, %318
  store i64 %324, ptr %3, align 8
  br label %197

325:                                              ; preds = %44
  %326 = load i64, ptr %3, align 8
  %327 = ptrtoint ptr %0 to i64
  %328 = zext i32 %1 to i64
  %329 = mul i64 %327, %327
  %330 = xor i64 %329, %326
  %331 = sub i64 %330, %328
  %332 = add i64 %331, %328
  %333 = or i64 %332, %327
  store i64 %333, ptr %3, align 8
  br label %197

334:                                              ; preds = %55
  %335 = load i64, ptr %3, align 8
  %336 = ptrtoint ptr %0 to i64
  %337 = zext i32 %1 to i64
  %338 = mul i64 %337, %336
  %339 = add i64 %338, %336
  %340 = or i64 %339, %336
  %341 = sub i64 %340, %336
  %342 = mul i64 %341, %335
  store i64 %342, ptr %3, align 8
  br label %197

343:                                              ; preds = %73
  %344 = load i64, ptr %3, align 8
  %345 = ptrtoint ptr %0 to i64
  %346 = zext i32 %1 to i64
  %347 = sub i64 %345, %344
  %348 = mul i64 %347, %346
  %349 = or i64 %348, %345
  %350 = sub i64 %349, %344
  %351 = add i64 %350, %346
  %352 = xor i64 %351, %346
  store i64 %352, ptr %3, align 8
  br label %197

353:                                              ; preds = %88
  %354 = load i64, ptr %3, align 8
  %355 = ptrtoint ptr %0 to i64
  %356 = zext i32 %1 to i64
  %357 = add i64 %354, %355
  %358 = xor i64 %357, %354
  %359 = sub i64 %358, %354
  %360 = and i64 %359, %355
  store i64 %360, ptr %3, align 8
  br label %197

361:                                              ; preds = %105
  %362 = load i64, ptr %3, align 8
  %363 = ptrtoint ptr %0 to i64
  %364 = zext i32 %1 to i64
  %365 = or i64 %362, %362
  %366 = xor i64 %365, %364
  %367 = or i64 %366, %362
  %368 = sub i64 %367, %364
  store i64 %368, ptr %3, align 8
  br label %197

369:                                              ; preds = %125
  %370 = load i64, ptr %3, align 8
  %371 = ptrtoint ptr %0 to i64
  %372 = zext i32 %1 to i64
  %373 = mul i64 %370, %371
  %374 = and i64 %373, %371
  %375 = add i64 %374, %371
  store i64 %375, ptr %3, align 8
  br label %197

376:                                              ; preds = %139
  %377 = load i64, ptr %3, align 8
  %378 = ptrtoint ptr %0 to i64
  %379 = zext i32 %1 to i64
  %380 = add i64 %378, %379
  %381 = xor i64 %380, %378
  %382 = and i64 %381, %379
  %383 = or i64 %382, %379
  %384 = and i64 %383, %377
  %385 = and i64 %384, %378
  store i64 %385, ptr %3, align 8
  br label %197

386:                                              ; preds = %158
  %387 = load i64, ptr %3, align 8
  %388 = ptrtoint ptr %0 to i64
  %389 = zext i32 %1 to i64
  %390 = or i64 %388, %388
  %391 = and i64 %390, %388
  %392 = and i64 %391, %389
  store i64 %392, ptr %3, align 8
  br label %197

393:                                              ; preds = %172
  %394 = load i64, ptr %3, align 8
  %395 = ptrtoint ptr %0 to i64
  %396 = zext i32 %1 to i64
  %397 = or i64 %394, %396
  %398 = and i64 %397, %395
  %399 = add i64 %398, %396
  store i64 %399, ptr %3, align 8
  br label %197

400:                                              ; preds = %198
  %401 = load i64, ptr %3, align 8
  %402 = ptrtoint ptr %0 to i64
  %403 = zext i32 %1 to i64
  %404 = xor i64 %403, %401
  %405 = mul i64 %404, %402
  %406 = xor i64 %405, %402
  %407 = sub i64 %406, %403
  store i64 %407, ptr %3, align 8
  br label %9

408:                                              ; preds = %209
  %409 = load i64, ptr %3, align 8
  %410 = ptrtoint ptr %0 to i64
  %411 = zext i32 %1 to i64
  %412 = xor i64 %410, %411
  %413 = add i64 %412, %409
  %414 = xor i64 %413, %410
  store i64 %414, ptr %3, align 8
  br label %197

415:                                              ; preds = %220
  %416 = load i64, ptr %3, align 8
  %417 = ptrtoint ptr %0 to i64
  %418 = zext i32 %1 to i64
  %419 = or i64 %416, %417
  %420 = mul i64 %419, %416
  %421 = and i64 %420, %417
  %422 = add i64 %421, %417
  %423 = or i64 %422, %418
  %424 = xor i64 %423, %417
  store i64 %424, ptr %3, align 8
  br label %197

425:                                              ; preds = %233
  %426 = load i64, ptr %3, align 8
  %427 = ptrtoint ptr %0 to i64
  %428 = zext i32 %1 to i64
  %429 = xor i64 %428, %426
  %430 = xor i64 %429, %428
  %431 = or i64 %430, %427
  %432 = mul i64 %431, %427
  %433 = or i64 %432, %426
  store i64 %433, ptr %3, align 8
  br label %197

434:                                              ; preds = %245
  %435 = load i64, ptr %3, align 8
  %436 = ptrtoint ptr %0 to i64
  %437 = zext i32 %1 to i64
  %438 = mul i64 %436, %437
  %439 = mul i64 %438, %436
  %440 = or i64 %439, %435
  %441 = sub i64 %440, %437
  %442 = or i64 %441, %436
  store i64 %442, ptr %3, align 8
  br label %197

443:                                              ; preds = %257
  %444 = load i64, ptr %3, align 8
  %445 = ptrtoint ptr %0 to i64
  %446 = zext i32 %1 to i64
  %447 = sub i64 %445, %444
  %448 = xor i64 %447, %445
  %449 = xor i64 %448, %445
  %450 = or i64 %449, %446
  %451 = mul i64 %450, %446
  %452 = or i64 %451, %444
  store i64 %452, ptr %3, align 8
  br label %197

453:                                              ; preds = %269
  %454 = load i64, ptr %3, align 8
  %455 = ptrtoint ptr %0 to i64
  %456 = zext i32 %1 to i64
  %457 = xor i64 %456, %455
  %458 = or i64 %457, %456
  %459 = and i64 %458, %456
  %460 = or i64 %459, %456
  %461 = mul i64 %460, %456
  store i64 %461, ptr %3, align 8
  br label %197

462:                                              ; preds = %282
  %463 = load i64, ptr %3, align 8
  %464 = ptrtoint ptr %0 to i64
  %465 = zext i32 %1 to i64
  %466 = mul i64 %463, %464
  %467 = add i64 %466, %464
  %468 = xor i64 %467, %464
  %469 = add i64 %468, %465
  %470 = sub i64 %469, %464
  store i64 %470, ptr %3, align 8
  br label %197

471:                                              ; preds = %293
  %472 = load i64, ptr %3, align 8
  %473 = ptrtoint ptr %0 to i64
  %474 = zext i32 %1 to i64
  %475 = mul i64 %472, %473
  %476 = sub i64 %475, %474
  %477 = or i64 %476, %472
  store i64 %477, ptr %3, align 8
  br label %197
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdLowStock(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 1294876652, ptr %4, align 4
  br label %10

10:                                               ; preds = %526, %216, %215, %2
  %11 = load i32, ptr %4, align 4
  %12 = sub i32 %11, -611481827
  %13 = mul i32 %12, -311131345
  %14 = icmp slt i32 %13, 1371978057
  br i1 %14, label %359, label %361

15:                                               ; preds = %419
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 0, ptr %8, align 4
  %16 = load i32, ptr %6, align 4
  %17 = icmp ne i32 %16, 2
  %18 = select i1 %17, i32 -1979972979, i32 1333665247
  store i32 %18, ptr %4, align 4
  %19 = xor i32 %1, 130536313
  %20 = and i32 %1, %19
  %21 = or i32 %1, %19
  %22 = xor i32 %1, %19
  %23 = add i32 %20, %21
  %24 = sub i32 %23, %1
  %25 = sub i32 %24, %19
  %26 = mul i32 %25, 244
  %27 = icmp ugt i32 %26, 0
  br i1 %27, label %423, label %215

28:                                               ; preds = %389
  %29 = load ptr, ptr %5, align 8
  %30 = getelementptr inbounds ptr, ptr %29, i64 1
  %31 = load ptr, ptr %30, align 8
  %32 = call i32 @parseIntStrict(ptr noundef %31, ptr noundef %7)
  %33 = icmp ne i32 %32, 0
  %34 = select i1 %33, i32 1218547690, i32 -1979972979
  store i32 %34, ptr %4, align 4
  %35 = xor i32 %1, 477876751
  %36 = and i32 %1, %35
  %37 = or i32 %1, %35
  %38 = xor i32 %1, %35
  %39 = add i32 %36, %37
  %40 = sub i32 %39, %1
  %41 = sub i32 %40, %35
  %42 = mul i32 %41, 75
  %43 = icmp ne i32 %42, 0
  br i1 %43, label %430, label %215

44:                                               ; preds = %371
  %45 = load i32, ptr %7, align 4
  %46 = icmp slt i32 %45, 0
  %47 = select i1 %46, i32 -1979972979, i32 870081256
  store i32 %47, ptr %4, align 4
  %48 = xor i32 %1, 1618849625
  %49 = and i32 %1, %48
  %50 = or i32 %1, %48
  %51 = xor i32 %1, %48
  %52 = add i32 %49, %50
  %53 = sub i32 %52, %1
  %54 = sub i32 %53, %48
  %55 = mul i32 %54, 94
  %56 = xor i32 %1, -1095431259
  %57 = and i32 %1, %56
  %58 = or i32 %1, %56
  %59 = xor i32 %1, %56
  %60 = mul i32 %58, 2
  %61 = sub i32 %60, %59
  %62 = sub i32 %61, %1
  %63 = sub i32 %62, %56
  %64 = mul i32 %63, 157
  %65 = icmp ne i32 %55, %64
  br i1 %65, label %440, label %215

66:                                               ; preds = %377
  %67 = call i32 (ptr, ...) @printf(ptr noundef @.str.33)
  store i32 501801677, ptr %4, align 4
  %68 = xor i32 %1, -1301994033
  %69 = and i32 %1, %68
  %70 = or i32 %1, %68
  %71 = xor i32 %1, %68
  %72 = add i32 %1, %68
  %73 = sub i32 %72, %71
  %74 = mul i32 %69, 2
  %75 = sub i32 %73, %74
  %76 = mul i32 %75, 227
  %77 = icmp slt i32 %76, 1
  br i1 %77, label %215, label %448

78:                                               ; preds = %373
  call void @printProductHeader()
  store i32 0, ptr %9, align 4
  store i32 970568366, ptr %4, align 4
  %79 = xor i32 %1, -206263817
  %80 = and i32 %1, %79
  %81 = or i32 %1, %79
  %82 = xor i32 %1, %79
  %83 = add i32 %80, %81
  %84 = sub i32 %83, %1
  %85 = sub i32 %84, %79
  %86 = mul i32 %85, 104
  %87 = icmp slt i32 %86, 0
  br i1 %87, label %457, label %215

88:                                               ; preds = %383
  %89 = load i32, ptr %9, align 4
  %90 = load i32, ptr @productCount, align 4
  %91 = icmp slt i32 %89, %90
  %92 = select i1 %91, i32 1426838564, i32 -233245634
  store i32 %92, ptr %4, align 4
  %93 = xor i32 %1, -1489090497
  %94 = and i32 %1, %93
  %95 = or i32 %1, %93
  %96 = xor i32 %1, %93
  %97 = add i32 %94, %95
  %98 = sub i32 %97, %1
  %99 = sub i32 %98, %93
  %100 = mul i32 %99, 208
  %101 = xor i32 %1, 1270496713
  %102 = and i32 %1, %101
  %103 = or i32 %1, %101
  %104 = xor i32 %1, %101
  %105 = add i32 %102, %103
  %106 = sub i32 %105, %1
  %107 = sub i32 %106, %101
  %108 = mul i32 %107, 69
  %109 = icmp ne i32 %100, %108
  br i1 %109, label %465, label %215

110:                                              ; preds = %395
  %111 = load i32, ptr %9, align 4
  %112 = sext i32 %111 to i64
  %113 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %112
  %114 = getelementptr inbounds nuw %struct.Product, ptr %113, i32 0, i32 6
  %115 = load i32, ptr %114, align 8
  %116 = icmp ne i32 %115, 0
  %117 = select i1 %116, i32 1710367069, i32 602463759
  store i32 %117, ptr %4, align 4
  %118 = xor i32 %1, -143853517
  %119 = and i32 %1, %118
  %120 = or i32 %1, %118
  %121 = xor i32 %1, %118
  %122 = add i32 %1, %118
  %123 = sub i32 %122, %121
  %124 = mul i32 %119, 2
  %125 = sub i32 %123, %124
  %126 = mul i32 %125, 255
  %127 = xor i32 %1, -1719698233
  %128 = and i32 %1, %127
  %129 = or i32 %1, %127
  %130 = xor i32 %1, %127
  %131 = add i32 %1, %127
  %132 = sub i32 %131, %130
  %133 = mul i32 %128, 2
  %134 = sub i32 %132, %133
  %135 = mul i32 %134, 48
  %136 = icmp ne i32 %126, %135
  br i1 %136, label %475, label %215

137:                                              ; preds = %367
  %138 = load i32, ptr %9, align 4
  %139 = sext i32 %138 to i64
  %140 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %139
  %141 = getelementptr inbounds nuw %struct.Product, ptr %140, i32 0, i32 4
  %142 = load i32, ptr %141, align 16
  %143 = load i32, ptr %7, align 4
  %144 = icmp sle i32 %142, %143
  %145 = select i1 %144, i32 -684019849, i32 602463759
  store i32 %145, ptr %4, align 4
  %146 = xor i32 %1, 1720356643
  %147 = and i32 %1, %146
  %148 = or i32 %1, %146
  %149 = xor i32 %1, %146
  %150 = add i32 %1, %146
  %151 = sub i32 %150, %149
  %152 = mul i32 %147, 2
  %153 = sub i32 %151, %152
  %154 = mul i32 %153, 23
  %155 = icmp slt i32 %154, 1
  br i1 %155, label %215, label %484

156:                                              ; preds = %411
  %157 = load i32, ptr %9, align 4
  %158 = sext i32 %157 to i64
  %159 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %158
  call void @printProduct(ptr noundef %159)
  store i32 1, ptr %8, align 4
  store i32 602463759, ptr %4, align 4
  %160 = xor i32 %1, -40418035
  %161 = and i32 %1, %160
  %162 = or i32 %1, %160
  %163 = xor i32 %1, %160
  %164 = sub i32 %162, %163
  %165 = sub i32 %164, %161
  %166 = mul i32 %165, 44
  %167 = icmp eq i32 %166, 0
  br i1 %167, label %215, label %493

168:                                              ; preds = %415
  %169 = load i32, ptr %9, align 4
  %170 = load i32, ptr %4, align 4
  %171 = xor i32 %170, 602463758
  %172 = or i32 %169, %171
  %173 = load i32, ptr %4, align 4
  %174 = xor i32 %173, 602463758
  %175 = and i32 %169, %174
  %176 = add i32 %172, %175
  store i32 %176, ptr %9, align 4
  store i32 970568366, ptr %4, align 4
  %177 = xor i32 %1, -532736055
  %178 = and i32 %1, %177
  %179 = or i32 %1, %177
  %180 = xor i32 %1, %177
  %181 = mul i32 %179, 2
  %182 = sub i32 %181, %180
  %183 = sub i32 %182, %1
  %184 = sub i32 %183, %177
  %185 = mul i32 %184, 248
  %186 = icmp sgt i32 %185, 0
  br i1 %186, label %503, label %215

187:                                              ; preds = %421
  %188 = load i32, ptr %8, align 4
  %189 = icmp ne i32 %188, 0
  %190 = select i1 %189, i32 501801677, i32 -1651319551
  store i32 %190, ptr %4, align 4
  %191 = xor i32 %1, -1669142977
  %192 = and i32 %1, %191
  %193 = or i32 %1, %191
  %194 = xor i32 %1, %191
  %195 = mul i32 %193, 2
  %196 = sub i32 %195, %194
  %197 = sub i32 %196, %1
  %198 = sub i32 %197, %191
  %199 = mul i32 %198, 197
  %200 = icmp slt i32 %199, 1
  br i1 %200, label %215, label %511

201:                                              ; preds = %399
  %202 = load i32, ptr %7, align 4
  %203 = call i32 (ptr, ...) @printf(ptr noundef @.str.34, i32 noundef %202)
  store i32 501801677, ptr %4, align 4
  %204 = xor i32 %1, -941502811
  %205 = and i32 %1, %204
  %206 = or i32 %1, %204
  %207 = xor i32 %1, %204
  %208 = mul i32 %206, 2
  %209 = sub i32 %208, %207
  %210 = sub i32 %209, %1
  %211 = sub i32 %210, %204
  %212 = mul i32 %211, 227
  %213 = icmp ne i32 %212, 0
  br i1 %213, label %519, label %215

214:                                              ; preds = %405
  ret void

215:                                              ; preds = %594, %584, %576, %566, %559, %551, %544, %534, %519, %511, %503, %493, %484, %475, %465, %457, %448, %440, %430, %423, %337, %324, %311, %289, %277, %266, %254, %232, %201, %187, %168, %156, %137, %110, %88, %78, %66, %44, %28, %15
  br label %10

216:                                              ; preds = %421, %417, %415, %411, %405, %401, %399, %389, %385, %383, %377, %373, %371
  store i32 1294876652, ptr %4, align 4
  call void asm sideeffect "", ""()
  %217 = xor i32 %1, 66205535
  %218 = and i32 %1, %217
  %219 = or i32 %1, %217
  %220 = xor i32 %1, %217
  %221 = sub i32 %219, %220
  %222 = sub i32 %221, %218
  %223 = mul i32 %222, 66
  %224 = xor i32 %1, -641366915
  %225 = and i32 %1, %224
  %226 = or i32 %1, %224
  %227 = xor i32 %1, %224
  %228 = sub i32 %226, %227
  %229 = sub i32 %228, %225
  %230 = mul i32 %229, 7
  %231 = icmp ne i32 %223, %230
  br i1 %231, label %526, label %10

232:                                              ; preds = %375
  %233 = load i32, ptr %4, align 4
  %234 = xor i32 %233, -637097887
  store i32 %234, ptr %4, align 4
  %235 = xor i32 %1, -2134651597
  %236 = and i32 %1, %235
  %237 = or i32 %1, %235
  %238 = xor i32 %1, %235
  %239 = mul i32 %237, 2
  %240 = sub i32 %239, %238
  %241 = sub i32 %240, %1
  %242 = sub i32 %241, %235
  %243 = mul i32 %242, 216
  %244 = xor i32 %1, -1273779495
  %245 = and i32 %1, %244
  %246 = or i32 %1, %244
  %247 = xor i32 %1, %244
  %248 = mul i32 %246, 2
  %249 = sub i32 %248, %247
  %250 = sub i32 %249, %1
  %251 = sub i32 %250, %244
  %252 = mul i32 %251, 157
  %253 = icmp ne i32 %243, %252
  br i1 %253, label %534, label %215

254:                                              ; preds = %387
  %255 = load i32, ptr %4, align 4
  %256 = xor i32 %255, 802783197
  store i32 %256, ptr %4, align 4
  %257 = xor i32 %1, 1714225473
  %258 = and i32 %1, %257
  %259 = or i32 %1, %257
  %260 = xor i32 %1, %257
  %261 = add i32 %258, %259
  %262 = sub i32 %261, %1
  %263 = sub i32 %262, %257
  %264 = mul i32 %263, 164
  %265 = icmp slt i32 %264, 1
  br i1 %265, label %215, label %544

266:                                              ; preds = %403
  %267 = load i32, ptr %4, align 4
  %268 = xor i32 %267, -1816407247
  store i32 %268, ptr %4, align 4
  %269 = xor i32 %1, -1528733821
  %270 = and i32 %1, %269
  %271 = or i32 %1, %269
  %272 = xor i32 %1, %269
  %273 = sub i32 %271, %272
  %274 = sub i32 %273, %270
  %275 = mul i32 %274, 216
  %276 = icmp eq i32 %275, 0
  br i1 %276, label %215, label %551

277:                                              ; preds = %417
  %278 = load i32, ptr %4, align 4
  %279 = xor i32 %278, 1670379097
  store i32 %279, ptr %4, align 4
  %280 = xor i32 %1, 1231708959
  %281 = and i32 %1, %280
  %282 = or i32 %1, %280
  %283 = xor i32 %1, %280
  %284 = add i32 %281, %282
  %285 = sub i32 %284, %1
  %286 = sub i32 %285, %280
  %287 = mul i32 %286, 99
  %288 = icmp slt i32 %287, 0
  br i1 %288, label %559, label %215

289:                                              ; preds = %413
  %290 = load i32, ptr %4, align 4
  %291 = xor i32 %290, -1173917322
  store i32 %291, ptr %4, align 4
  %292 = xor i32 %1, -2012905221
  %293 = and i32 %1, %292
  %294 = or i32 %1, %292
  %295 = xor i32 %1, %292
  %296 = add i32 %1, %292
  %297 = sub i32 %296, %295
  %298 = mul i32 %293, 2
  %299 = sub i32 %297, %298
  %300 = mul i32 %299, 37
  %301 = xor i32 %1, -1518337355
  %302 = and i32 %1, %301
  %303 = or i32 %1, %301
  %304 = xor i32 %1, %301
  %305 = add i32 %1, %301
  %306 = sub i32 %305, %304
  %307 = mul i32 %302, 2
  %308 = sub i32 %306, %307
  %309 = mul i32 %308, 218
  %310 = icmp eq i32 %300, %309
  br i1 %310, label %215, label %566

311:                                              ; preds = %385
  %312 = load i32, ptr %4, align 4
  %313 = xor i32 %312, -1304253909
  store i32 %313, ptr %4, align 4
  %314 = xor i32 %1, 1986598777
  %315 = and i32 %1, %314
  %316 = or i32 %1, %314
  %317 = xor i32 %1, %314
  %318 = mul i32 %316, 2
  %319 = sub i32 %318, %317
  %320 = sub i32 %319, %1
  %321 = sub i32 %320, %314
  %322 = mul i32 %321, 158
  %323 = icmp uge i32 %322, 0
  br i1 %323, label %215, label %576

324:                                              ; preds = %401
  %325 = load i32, ptr %4, align 4
  %326 = xor i32 %325, -1903979746
  store i32 %326, ptr %4, align 4
  %327 = xor i32 %1, 1620400011
  %328 = and i32 %1, %327
  %329 = or i32 %1, %327
  %330 = xor i32 %1, %327
  %331 = mul i32 %329, 2
  %332 = sub i32 %331, %330
  %333 = sub i32 %332, %1
  %334 = sub i32 %333, %327
  %335 = mul i32 %334, 230
  %336 = icmp ne i32 %335, 0
  br i1 %336, label %584, label %215

337:                                              ; preds = %379
  %338 = load i32, ptr %4, align 4
  %339 = xor i32 %338, 1673851832
  store i32 %339, ptr %4, align 4
  %340 = xor i32 %1, 1461272795
  %341 = and i32 %1, %340
  %342 = or i32 %1, %340
  %343 = xor i32 %1, %340
  %344 = mul i32 %342, 2
  %345 = sub i32 %344, %343
  %346 = sub i32 %345, %1
  %347 = sub i32 %346, %340
  %348 = mul i32 %347, 39
  %349 = xor i32 %1, -266418969
  %350 = and i32 %1, %349
  %351 = or i32 %1, %349
  %352 = xor i32 %1, %349
  %353 = mul i32 %351, 2
  %354 = sub i32 %353, %352
  %355 = sub i32 %354, %1
  %356 = sub i32 %355, %349
  %357 = mul i32 %356, 216
  %358 = icmp eq i32 %348, %357
  br i1 %358, label %215, label %594

359:                                              ; preds = %10
  %360 = icmp slt i32 %13, 915374731
  br i1 %360, label %363, label %365

361:                                              ; preds = %10
  %362 = icmp slt i32 %13, 1798862470
  br i1 %362, label %391, label %393

363:                                              ; preds = %359
  %364 = icmp slt i32 %13, 401554245
  br i1 %364, label %367, label %369

365:                                              ; preds = %359
  %366 = icmp slt i32 %13, 1262584136
  br i1 %366, label %379, label %381

367:                                              ; preds = %363
  %368 = icmp eq i32 %13, 140972480
  br i1 %368, label %137, label %371

369:                                              ; preds = %363
  %370 = icmp slt i32 %13, 696419440
  br i1 %370, label %373, label %375

371:                                              ; preds = %367
  %372 = icmp eq i32 %13, 219317411
  br i1 %372, label %44, label %216

373:                                              ; preds = %369
  %374 = icmp eq i32 %13, 401554245
  br i1 %374, label %78, label %216

375:                                              ; preds = %369
  %376 = icmp eq i32 %13, 696419440
  br i1 %376, label %232, label %377

377:                                              ; preds = %375
  %378 = icmp eq i32 %13, 775092624
  br i1 %378, label %66, label %216

379:                                              ; preds = %365
  %380 = icmp eq i32 %13, 915374731
  br i1 %380, label %337, label %383

381:                                              ; preds = %365
  %382 = icmp slt i32 %13, 1276115202
  br i1 %382, label %385, label %387

383:                                              ; preds = %379
  %384 = icmp eq i32 %13, 1157313183
  br i1 %384, label %88, label %216

385:                                              ; preds = %381
  %386 = icmp eq i32 %13, 1262584136
  br i1 %386, label %311, label %216

387:                                              ; preds = %381
  %388 = icmp eq i32 %13, 1276115202
  br i1 %388, label %254, label %389

389:                                              ; preds = %387
  %390 = icmp eq i32 %13, 1345909662
  br i1 %390, label %28, label %216

391:                                              ; preds = %361
  %392 = icmp slt i32 %13, 1612460515
  br i1 %392, label %395, label %397

393:                                              ; preds = %361
  %394 = icmp slt i32 %13, 2001316457
  br i1 %394, label %407, label %409

395:                                              ; preds = %391
  %396 = icmp eq i32 %13, 1371978057
  br i1 %396, label %110, label %399

397:                                              ; preds = %391
  %398 = icmp slt i32 %13, 1640601410
  br i1 %398, label %401, label %403

399:                                              ; preds = %395
  %400 = icmp eq i32 %13, 1497264348
  br i1 %400, label %201, label %216

401:                                              ; preds = %397
  %402 = icmp eq i32 %13, 1612460515
  br i1 %402, label %324, label %216

403:                                              ; preds = %397
  %404 = icmp eq i32 %13, 1640601410
  br i1 %404, label %266, label %405

405:                                              ; preds = %403
  %406 = icmp eq i32 %13, 1785783632
  br i1 %406, label %214, label %216

407:                                              ; preds = %393
  %408 = icmp slt i32 %13, 1804053277
  br i1 %408, label %411, label %413

409:                                              ; preds = %393
  %410 = icmp slt i32 %13, 2078268161
  br i1 %410, label %417, label %419

411:                                              ; preds = %407
  %412 = icmp eq i32 %13, 1798862470
  br i1 %412, label %156, label %216

413:                                              ; preds = %407
  %414 = icmp eq i32 %13, 1804053277
  br i1 %414, label %289, label %415

415:                                              ; preds = %413
  %416 = icmp eq i32 %13, 1978322030
  br i1 %416, label %168, label %216

417:                                              ; preds = %409
  %418 = icmp eq i32 %13, 2001316457
  br i1 %418, label %277, label %216

419:                                              ; preds = %409
  %420 = icmp eq i32 %13, 2078268161
  br i1 %420, label %15, label %421

421:                                              ; preds = %419
  %422 = icmp eq i32 %13, 2086988815
  br i1 %422, label %187, label %216

423:                                              ; preds = %15
  %424 = load i64, ptr %3, align 8
  %425 = ptrtoint ptr %0 to i64
  %426 = zext i32 %1 to i64
  %427 = sub i64 %424, %425
  %428 = sub i64 %427, %426
  %429 = mul i64 %428, %424
  store i64 %429, ptr %3, align 8
  br label %215

430:                                              ; preds = %28
  %431 = load i64, ptr %3, align 8
  %432 = ptrtoint ptr %0 to i64
  %433 = zext i32 %1 to i64
  %434 = mul i64 %432, %432
  %435 = sub i64 %434, %432
  %436 = or i64 %435, %433
  %437 = add i64 %436, %431
  %438 = and i64 %437, %433
  %439 = sub i64 %438, %432
  store i64 %439, ptr %3, align 8
  br label %215

440:                                              ; preds = %44
  %441 = load i64, ptr %3, align 8
  %442 = ptrtoint ptr %0 to i64
  %443 = zext i32 %1 to i64
  %444 = mul i64 %443, %442
  %445 = sub i64 %444, %443
  %446 = mul i64 %445, %442
  %447 = and i64 %446, %443
  store i64 %447, ptr %3, align 8
  br label %215

448:                                              ; preds = %66
  %449 = load i64, ptr %3, align 8
  %450 = ptrtoint ptr %0 to i64
  %451 = zext i32 %1 to i64
  %452 = sub i64 %451, %450
  %453 = or i64 %452, %449
  %454 = sub i64 %453, %450
  %455 = sub i64 %454, %450
  %456 = and i64 %455, %451
  store i64 %456, ptr %3, align 8
  br label %215

457:                                              ; preds = %78
  %458 = load i64, ptr %3, align 8
  %459 = ptrtoint ptr %0 to i64
  %460 = zext i32 %1 to i64
  %461 = sub i64 %460, %460
  %462 = sub i64 %461, %460
  %463 = or i64 %462, %458
  %464 = and i64 %463, %459
  store i64 %464, ptr %3, align 8
  br label %215

465:                                              ; preds = %88
  %466 = load i64, ptr %3, align 8
  %467 = ptrtoint ptr %0 to i64
  %468 = zext i32 %1 to i64
  %469 = and i64 %466, %468
  %470 = or i64 %469, %468
  %471 = and i64 %470, %466
  %472 = mul i64 %471, %467
  %473 = sub i64 %472, %467
  %474 = xor i64 %473, %466
  store i64 %474, ptr %3, align 8
  br label %215

475:                                              ; preds = %110
  %476 = load i64, ptr %3, align 8
  %477 = ptrtoint ptr %0 to i64
  %478 = zext i32 %1 to i64
  %479 = or i64 %476, %476
  %480 = mul i64 %479, %477
  %481 = mul i64 %480, %478
  %482 = xor i64 %481, %478
  %483 = and i64 %482, %478
  store i64 %483, ptr %3, align 8
  br label %215

484:                                              ; preds = %137
  %485 = load i64, ptr %3, align 8
  %486 = ptrtoint ptr %0 to i64
  %487 = zext i32 %1 to i64
  %488 = sub i64 %487, %487
  %489 = or i64 %488, %485
  %490 = xor i64 %489, %487
  %491 = add i64 %490, %485
  %492 = or i64 %491, %485
  store i64 %492, ptr %3, align 8
  br label %215

493:                                              ; preds = %156
  %494 = load i64, ptr %3, align 8
  %495 = ptrtoint ptr %0 to i64
  %496 = zext i32 %1 to i64
  %497 = mul i64 %494, %495
  %498 = xor i64 %497, %496
  %499 = add i64 %498, %496
  %500 = mul i64 %499, %495
  %501 = xor i64 %500, %495
  %502 = add i64 %501, %494
  store i64 %502, ptr %3, align 8
  br label %215

503:                                              ; preds = %168
  %504 = load i64, ptr %3, align 8
  %505 = ptrtoint ptr %0 to i64
  %506 = zext i32 %1 to i64
  %507 = and i64 %504, %505
  %508 = xor i64 %507, %505
  %509 = sub i64 %508, %504
  %510 = mul i64 %509, %504
  store i64 %510, ptr %3, align 8
  br label %215

511:                                              ; preds = %187
  %512 = load i64, ptr %3, align 8
  %513 = ptrtoint ptr %0 to i64
  %514 = zext i32 %1 to i64
  %515 = mul i64 %513, %513
  %516 = mul i64 %515, %514
  %517 = or i64 %516, %514
  %518 = and i64 %517, %513
  store i64 %518, ptr %3, align 8
  br label %215

519:                                              ; preds = %201
  %520 = load i64, ptr %3, align 8
  %521 = ptrtoint ptr %0 to i64
  %522 = zext i32 %1 to i64
  %523 = add i64 %522, %520
  %524 = xor i64 %523, %521
  %525 = xor i64 %524, %522
  store i64 %525, ptr %3, align 8
  br label %215

526:                                              ; preds = %216
  %527 = load i64, ptr %3, align 8
  %528 = ptrtoint ptr %0 to i64
  %529 = zext i32 %1 to i64
  %530 = mul i64 %529, %527
  %531 = and i64 %530, %529
  %532 = and i64 %531, %527
  %533 = sub i64 %532, %529
  store i64 %533, ptr %3, align 8
  br label %10

534:                                              ; preds = %232
  %535 = load i64, ptr %3, align 8
  %536 = ptrtoint ptr %0 to i64
  %537 = zext i32 %1 to i64
  %538 = mul i64 %536, %536
  %539 = mul i64 %538, %537
  %540 = or i64 %539, %536
  %541 = sub i64 %540, %535
  %542 = add i64 %541, %537
  %543 = or i64 %542, %535
  store i64 %543, ptr %3, align 8
  br label %215

544:                                              ; preds = %254
  %545 = load i64, ptr %3, align 8
  %546 = ptrtoint ptr %0 to i64
  %547 = zext i32 %1 to i64
  %548 = mul i64 %545, %547
  %549 = and i64 %548, %547
  %550 = add i64 %549, %546
  store i64 %550, ptr %3, align 8
  br label %215

551:                                              ; preds = %266
  %552 = load i64, ptr %3, align 8
  %553 = ptrtoint ptr %0 to i64
  %554 = zext i32 %1 to i64
  %555 = add i64 %552, %554
  %556 = add i64 %555, %554
  %557 = or i64 %556, %553
  %558 = sub i64 %557, %554
  store i64 %558, ptr %3, align 8
  br label %215

559:                                              ; preds = %277
  %560 = load i64, ptr %3, align 8
  %561 = ptrtoint ptr %0 to i64
  %562 = zext i32 %1 to i64
  %563 = and i64 %562, %562
  %564 = and i64 %563, %562
  %565 = add i64 %564, %562
  store i64 %565, ptr %3, align 8
  br label %215

566:                                              ; preds = %289
  %567 = load i64, ptr %3, align 8
  %568 = ptrtoint ptr %0 to i64
  %569 = zext i32 %1 to i64
  %570 = sub i64 %567, %567
  %571 = mul i64 %570, %568
  %572 = sub i64 %571, %568
  %573 = mul i64 %572, %567
  %574 = mul i64 %573, %569
  %575 = and i64 %574, %567
  store i64 %575, ptr %3, align 8
  br label %215

576:                                              ; preds = %311
  %577 = load i64, ptr %3, align 8
  %578 = ptrtoint ptr %0 to i64
  %579 = zext i32 %1 to i64
  %580 = add i64 %579, %578
  %581 = mul i64 %580, %577
  %582 = or i64 %581, %577
  %583 = sub i64 %582, %578
  store i64 %583, ptr %3, align 8
  br label %215

584:                                              ; preds = %324
  %585 = load i64, ptr %3, align 8
  %586 = ptrtoint ptr %0 to i64
  %587 = zext i32 %1 to i64
  %588 = and i64 %585, %587
  %589 = add i64 %588, %585
  %590 = or i64 %589, %587
  %591 = sub i64 %590, %587
  %592 = add i64 %591, %586
  %593 = sub i64 %592, %586
  store i64 %593, ptr %3, align 8
  br label %215

594:                                              ; preds = %337
  %595 = load i64, ptr %3, align 8
  %596 = ptrtoint ptr %0 to i64
  %597 = zext i32 %1 to i64
  %598 = xor i64 %597, %596
  %599 = sub i64 %598, %597
  %600 = xor i64 %599, %596
  store i64 %600, ptr %3, align 8
  br label %215
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpPriceAsc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  store i32 1646992598, ptr %5, align 4
  br label %11

11:                                               ; preds = %343, %162, %161, %2
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 1419086942
  %14 = mul i32 %13, 239435677
  switch i32 %14, label %162 [
    i32 129835416, label %15
    i32 1956334082, label %35
    i32 382369690, label %59
    i32 1323610985, label %78
    i32 1054123152, label %89
    i32 1420939495, label %117
    i32 1261108958, label %128
    i32 423035404, label %159
    i32 998513158, label %180
    i32 179983839, label %193
    i32 413119667, label %206
    i32 1775155725, label %224
    i32 46943074, label %237
    i32 1976126482, label %250
    i32 2059301861, label %263
    i32 48191169, label %274
  ]

15:                                               ; preds = %11
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  %16 = load ptr, ptr %7, align 8
  store ptr %16, ptr %9, align 8
  %17 = load ptr, ptr %8, align 8
  store ptr %17, ptr %10, align 8
  %18 = load ptr, ptr %9, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 6
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %10, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 8
  %24 = icmp ne i32 %20, %23
  %25 = select i1 %24, i32 1826937800, i32 -1191538624
  store i32 %25, ptr %5, align 4
  %26 = xor i32 %4, -833505895
  %27 = and i32 %4, %26
  %28 = or i32 %4, %26
  %29 = xor i32 %4, %26
  %30 = add i32 %27, %28
  %31 = sub i32 %30, %4
  %32 = sub i32 %31, %26
  %33 = mul i32 %32, 69
  %34 = icmp ne i32 %33, 0
  br i1 %34, label %287, label %161

35:                                               ; preds = %11
  %36 = load ptr, ptr %10, align 8
  %37 = getelementptr inbounds nuw %struct.Product, ptr %36, i32 0, i32 6
  %38 = load i32, ptr %37, align 8
  %39 = load ptr, ptr %9, align 8
  %40 = getelementptr inbounds nuw %struct.Product, ptr %39, i32 0, i32 6
  %41 = load i32, ptr %40, align 8
  %42 = load i32, ptr %5, align 4
  %43 = xor i32 %42, 1826937801
  %44 = add i32 %41, %43
  %45 = load i32, ptr %5, align 4
  %46 = xor i32 %45, 1826937801
  %47 = add i32 %38, %46
  %48 = mul i32 %38, %44
  %49 = mul i32 %41, %47
  %50 = sub i32 %48, %49
  store i32 %50, ptr %6, align 4
  store i32 822470362, ptr %5, align 4
  %51 = xor i32 %4, 245329569
  %52 = and i32 %4, %51
  %53 = or i32 %4, %51
  %54 = xor i32 %4, %51
  %55 = sub i32 %53, %54
  %56 = sub i32 %55, %52
  %57 = mul i32 %56, 142
  %58 = icmp slt i32 %57, 0
  br i1 %58, label %294, label %161

59:                                               ; preds = %11
  %60 = load ptr, ptr %9, align 8
  %61 = getelementptr inbounds nuw %struct.Product, ptr %60, i32 0, i32 3
  %62 = load i64, ptr %61, align 8
  %63 = load ptr, ptr %10, align 8
  %64 = getelementptr inbounds nuw %struct.Product, ptr %63, i32 0, i32 3
  %65 = load i64, ptr %64, align 8
  %66 = icmp slt i64 %62, %65
  %67 = select i1 %66, i32 -229796965, i32 912573998
  store i32 %67, ptr %5, align 4
  %68 = xor i32 %4, 640190779
  %69 = and i32 %4, %68
  %70 = or i32 %4, %68
  %71 = xor i32 %4, %68
  %72 = mul i32 %70, 2
  %73 = sub i32 %72, %71
  %74 = sub i32 %73, %4
  %75 = sub i32 %74, %68
  %76 = mul i32 %75, 53
  %77 = icmp slt i32 %76, 1
  br i1 %77, label %161, label %302

78:                                               ; preds = %11
  store i32 -1, ptr %6, align 4
  store i32 822470362, ptr %5, align 4
  %79 = xor i32 %4, -1997516559
  %80 = and i32 %4, %79
  %81 = or i32 %4, %79
  %82 = xor i32 %4, %79
  %83 = add i32 %4, %79
  %84 = sub i32 %83, %82
  %85 = mul i32 %80, 2
  %86 = sub i32 %84, %85
  %87 = mul i32 %86, 114
  %88 = icmp sle i32 %87, 0
  br i1 %88, label %161, label %312

89:                                               ; preds = %11
  %90 = load ptr, ptr %9, align 8
  %91 = getelementptr inbounds nuw %struct.Product, ptr %90, i32 0, i32 3
  %92 = load i64, ptr %91, align 8
  %93 = load ptr, ptr %10, align 8
  %94 = getelementptr inbounds nuw %struct.Product, ptr %93, i32 0, i32 3
  %95 = load i64, ptr %94, align 8
  %96 = icmp sgt i64 %92, %95
  %97 = select i1 %96, i32 788558257, i32 -513408172
  store i32 %97, ptr %5, align 4
  %98 = xor i32 %4, 472129205
  %99 = and i32 %4, %98
  %100 = or i32 %4, %98
  %101 = xor i32 %4, %98
  %102 = mul i32 %100, 2
  %103 = sub i32 %102, %101
  %104 = sub i32 %103, %4
  %105 = sub i32 %104, %98
  %106 = mul i32 %105, 230
  %107 = xor i32 %4, -570031837
  %108 = and i32 %4, %107
  %109 = or i32 %4, %107
  %110 = xor i32 %4, %107
  %111 = mul i32 %109, 2
  %112 = sub i32 %111, %110
  %113 = sub i32 %112, %4
  %114 = sub i32 %113, %107
  %115 = mul i32 %114, 4
  %116 = icmp ne i32 %106, %115
  br i1 %116, label %319, label %161

117:                                              ; preds = %11
  store i32 1, ptr %6, align 4
  store i32 822470362, ptr %5, align 4
  %118 = xor i32 %4, -289518489
  %119 = and i32 %4, %118
  %120 = or i32 %4, %118
  %121 = xor i32 %4, %118
  %122 = add i32 %4, %118
  %123 = sub i32 %122, %121
  %124 = mul i32 %119, 2
  %125 = sub i32 %123, %124
  %126 = mul i32 %125, 236
  %127 = icmp ugt i32 %126, 0
  br i1 %127, label %328, label %161

128:                                              ; preds = %11
  %129 = load ptr, ptr %9, align 8
  %130 = getelementptr inbounds nuw %struct.Product, ptr %129, i32 0, i32 0
  %131 = load i32, ptr %130, align 8
  %132 = load ptr, ptr %10, align 8
  %133 = getelementptr inbounds nuw %struct.Product, ptr %132, i32 0, i32 0
  %134 = load i32, ptr %133, align 8
  %135 = load i32, ptr %5, align 4
  %136 = xor i32 %135, 513408171
  %137 = xor i32 %134, %136
  %138 = add i32 %131, %137
  %139 = load i32, ptr %5, align 4
  %140 = xor i32 %139, -513408171
  %141 = add i32 %138, %140
  store i32 %141, ptr %6, align 4
  store i32 822470362, ptr %5, align 4
  %142 = xor i32 %4, 14085205
  %143 = and i32 %4, %142
  %144 = or i32 %4, %142
  %145 = xor i32 %4, %142
  %146 = sub i32 %144, %145
  %147 = sub i32 %146, %143
  %148 = mul i32 %147, 147
  %149 = xor i32 %4, 2001780371
  %150 = and i32 %4, %149
  %151 = or i32 %4, %149
  %152 = xor i32 %4, %149
  %153 = add i32 %4, %149
  %154 = sub i32 %153, %152
  %155 = mul i32 %150, 2
  %156 = sub i32 %154, %155
  %157 = mul i32 %156, 25
  %158 = icmp ne i32 %148, %157
  br i1 %158, label %335, label %161

159:                                              ; preds = %11
  %160 = load i32, ptr %6, align 4
  ret i32 %160

161:                                              ; preds = %413, %406, %397, %389, %379, %371, %362, %353, %335, %328, %319, %312, %302, %294, %287, %274, %263, %250, %237, %224, %206, %193, %180, %128, %117, %89, %78, %59, %35, %15
  br label %11

162:                                              ; preds = %11
  store i32 1646992598, ptr %5, align 4
  call void asm sideeffect "", ""()
  %163 = xor i32 %4, 1552197119
  %164 = and i32 %4, %163
  %165 = or i32 %4, %163
  %166 = xor i32 %4, %163
  %167 = mul i32 %165, 2
  %168 = sub i32 %167, %166
  %169 = sub i32 %168, %4
  %170 = sub i32 %169, %163
  %171 = mul i32 %170, 155
  %172 = xor i32 %4, -996960173
  %173 = and i32 %4, %172
  %174 = or i32 %4, %172
  %175 = xor i32 %4, %172
  %176 = sub i32 %174, %175
  %177 = sub i32 %176, %173
  %178 = mul i32 %177, 232
  %179 = icmp eq i32 %171, %178
  br i1 %179, label %11, label %343

180:                                              ; preds = %11
  %181 = load i32, ptr %5, align 4
  %182 = xor i32 %181, -1033179257
  store i32 %182, ptr %5, align 4
  %183 = xor i32 %4, -748195563
  %184 = and i32 %4, %183
  %185 = or i32 %4, %183
  %186 = xor i32 %4, %183
  %187 = mul i32 %185, 2
  %188 = sub i32 %187, %186
  %189 = sub i32 %188, %4
  %190 = sub i32 %189, %183
  %191 = mul i32 %190, 57
  %192 = icmp slt i32 %191, 0
  br i1 %192, label %353, label %161

193:                                              ; preds = %11
  %194 = load i32, ptr %5, align 4
  %195 = xor i32 %194, -60170415
  store i32 %195, ptr %5, align 4
  %196 = xor i32 %4, -1545645919
  %197 = and i32 %4, %196
  %198 = or i32 %4, %196
  %199 = xor i32 %4, %196
  %200 = mul i32 %198, 2
  %201 = sub i32 %200, %199
  %202 = sub i32 %201, %4
  %203 = sub i32 %202, %196
  %204 = mul i32 %203, 47
  %205 = icmp ugt i32 %204, 0
  br i1 %205, label %362, label %161

206:                                              ; preds = %11
  %207 = load i32, ptr %5, align 4
  %208 = xor i32 %207, -1704191025
  store i32 %208, ptr %5, align 4
  %209 = xor i32 %4, -757090507
  %210 = and i32 %4, %209
  %211 = or i32 %4, %209
  %212 = xor i32 %4, %209
  %213 = sub i32 %211, %212
  %214 = sub i32 %213, %210
  %215 = mul i32 %214, 194
  %216 = xor i32 %4, 1132594769
  %217 = and i32 %4, %216
  %218 = or i32 %4, %216
  %219 = xor i32 %4, %216
  %220 = sub i32 %218, %219
  %221 = sub i32 %220, %217
  %222 = mul i32 %221, 132
  %223 = icmp ne i32 %215, %222
  br i1 %223, label %371, label %161

224:                                              ; preds = %11
  %225 = load i32, ptr %5, align 4
  %226 = xor i32 %225, 1383847273
  store i32 %226, ptr %5, align 4
  %227 = xor i32 %4, 1115379923
  %228 = and i32 %4, %227
  %229 = or i32 %4, %227
  %230 = xor i32 %4, %227
  %231 = add i32 %4, %227
  %232 = sub i32 %231, %230
  %233 = mul i32 %228, 2
  %234 = sub i32 %232, %233
  %235 = mul i32 %234, 27
  %236 = icmp slt i32 %235, 0
  br i1 %236, label %379, label %161

237:                                              ; preds = %11
  %238 = load i32, ptr %5, align 4
  %239 = xor i32 %238, 239376203
  store i32 %239, ptr %5, align 4
  %240 = xor i32 %4, 206010539
  %241 = and i32 %4, %240
  %242 = or i32 %4, %240
  %243 = xor i32 %4, %240
  %244 = mul i32 %242, 2
  %245 = sub i32 %244, %243
  %246 = sub i32 %245, %4
  %247 = sub i32 %246, %240
  %248 = mul i32 %247, 238
  %249 = icmp slt i32 %248, 0
  br i1 %249, label %389, label %161

250:                                              ; preds = %11
  %251 = load i32, ptr %5, align 4
  %252 = xor i32 %251, -1698610305
  store i32 %252, ptr %5, align 4
  %253 = xor i32 %4, -265141579
  %254 = and i32 %4, %253
  %255 = or i32 %4, %253
  %256 = xor i32 %4, %253
  %257 = add i32 %4, %253
  %258 = sub i32 %257, %256
  %259 = mul i32 %254, 2
  %260 = sub i32 %258, %259
  %261 = mul i32 %260, 51
  %262 = icmp uge i32 %261, 0
  br i1 %262, label %161, label %397

263:                                              ; preds = %11
  %264 = load i32, ptr %5, align 4
  %265 = xor i32 %264, 1452391850
  store i32 %265, ptr %5, align 4
  %266 = xor i32 %4, -761267101
  %267 = and i32 %4, %266
  %268 = or i32 %4, %266
  %269 = xor i32 %4, %266
  %270 = sub i32 %268, %269
  %271 = sub i32 %270, %267
  %272 = mul i32 %271, 243
  %273 = icmp ne i32 %272, 0
  br i1 %273, label %406, label %161

274:                                              ; preds = %11
  %275 = load i32, ptr %5, align 4
  %276 = xor i32 %275, -220979771
  store i32 %276, ptr %5, align 4
  %277 = xor i32 %4, -1626328383
  %278 = and i32 %4, %277
  %279 = or i32 %4, %277
  %280 = xor i32 %4, %277
  %281 = add i32 %4, %277
  %282 = sub i32 %281, %280
  %283 = mul i32 %278, 2
  %284 = sub i32 %282, %283
  %285 = mul i32 %284, 226
  %286 = icmp uge i32 %285, 0
  br i1 %286, label %161, label %413

287:                                              ; preds = %15
  %288 = load i64, ptr %3, align 8
  %289 = ptrtoint ptr %0 to i64
  %290 = ptrtoint ptr %1 to i64
  %291 = add i64 %290, %289
  %292 = add i64 %291, %290
  %293 = mul i64 %292, %289
  store i64 %293, ptr %3, align 8
  br label %161

294:                                              ; preds = %35
  %295 = load i64, ptr %3, align 8
  %296 = ptrtoint ptr %0 to i64
  %297 = ptrtoint ptr %1 to i64
  %298 = add i64 %296, %295
  %299 = sub i64 %298, %296
  %300 = xor i64 %299, %295
  %301 = sub i64 %300, %295
  store i64 %301, ptr %3, align 8
  br label %161

302:                                              ; preds = %59
  %303 = load i64, ptr %3, align 8
  %304 = ptrtoint ptr %0 to i64
  %305 = ptrtoint ptr %1 to i64
  %306 = add i64 %305, %305
  %307 = xor i64 %306, %303
  %308 = sub i64 %307, %303
  %309 = sub i64 %308, %303
  %310 = sub i64 %309, %303
  %311 = mul i64 %310, %305
  store i64 %311, ptr %3, align 8
  br label %161

312:                                              ; preds = %78
  %313 = load i64, ptr %3, align 8
  %314 = ptrtoint ptr %0 to i64
  %315 = ptrtoint ptr %1 to i64
  %316 = add i64 %313, %314
  %317 = mul i64 %316, %315
  %318 = xor i64 %317, %315
  store i64 %318, ptr %3, align 8
  br label %161

319:                                              ; preds = %89
  %320 = load i64, ptr %3, align 8
  %321 = ptrtoint ptr %0 to i64
  %322 = ptrtoint ptr %1 to i64
  %323 = and i64 %320, %321
  %324 = add i64 %323, %321
  %325 = and i64 %324, %320
  %326 = add i64 %325, %322
  %327 = add i64 %326, %321
  store i64 %327, ptr %3, align 8
  br label %161

328:                                              ; preds = %117
  %329 = load i64, ptr %3, align 8
  %330 = ptrtoint ptr %0 to i64
  %331 = ptrtoint ptr %1 to i64
  %332 = add i64 %330, %329
  %333 = and i64 %332, %330
  %334 = xor i64 %333, %329
  store i64 %334, ptr %3, align 8
  br label %161

335:                                              ; preds = %128
  %336 = load i64, ptr %3, align 8
  %337 = ptrtoint ptr %0 to i64
  %338 = ptrtoint ptr %1 to i64
  %339 = or i64 %337, %336
  %340 = and i64 %339, %337
  %341 = add i64 %340, %336
  %342 = and i64 %341, %338
  store i64 %342, ptr %3, align 8
  br label %161

343:                                              ; preds = %162
  %344 = load i64, ptr %3, align 8
  %345 = ptrtoint ptr %0 to i64
  %346 = ptrtoint ptr %1 to i64
  %347 = sub i64 %346, %344
  %348 = xor i64 %347, %345
  %349 = and i64 %348, %344
  %350 = and i64 %349, %346
  %351 = xor i64 %350, %345
  %352 = xor i64 %351, %346
  store i64 %352, ptr %3, align 8
  br label %11

353:                                              ; preds = %180
  %354 = load i64, ptr %3, align 8
  %355 = ptrtoint ptr %0 to i64
  %356 = ptrtoint ptr %1 to i64
  %357 = xor i64 %356, %355
  %358 = and i64 %357, %355
  %359 = sub i64 %358, %354
  %360 = add i64 %359, %354
  %361 = xor i64 %360, %354
  store i64 %361, ptr %3, align 8
  br label %161

362:                                              ; preds = %193
  %363 = load i64, ptr %3, align 8
  %364 = ptrtoint ptr %0 to i64
  %365 = ptrtoint ptr %1 to i64
  %366 = sub i64 %364, %363
  %367 = add i64 %366, %365
  %368 = or i64 %367, %363
  %369 = xor i64 %368, %365
  %370 = sub i64 %369, %364
  store i64 %370, ptr %3, align 8
  br label %161

371:                                              ; preds = %206
  %372 = load i64, ptr %3, align 8
  %373 = ptrtoint ptr %0 to i64
  %374 = ptrtoint ptr %1 to i64
  %375 = and i64 %373, %373
  %376 = xor i64 %375, %374
  %377 = or i64 %376, %374
  %378 = xor i64 %377, %373
  store i64 %378, ptr %3, align 8
  br label %161

379:                                              ; preds = %224
  %380 = load i64, ptr %3, align 8
  %381 = ptrtoint ptr %0 to i64
  %382 = ptrtoint ptr %1 to i64
  %383 = add i64 %382, %381
  %384 = sub i64 %383, %382
  %385 = mul i64 %384, %380
  %386 = xor i64 %385, %382
  %387 = or i64 %386, %382
  %388 = mul i64 %387, %380
  store i64 %388, ptr %3, align 8
  br label %161

389:                                              ; preds = %237
  %390 = load i64, ptr %3, align 8
  %391 = ptrtoint ptr %0 to i64
  %392 = ptrtoint ptr %1 to i64
  %393 = and i64 %390, %390
  %394 = add i64 %393, %391
  %395 = or i64 %394, %391
  %396 = or i64 %395, %390
  store i64 %396, ptr %3, align 8
  br label %161

397:                                              ; preds = %250
  %398 = load i64, ptr %3, align 8
  %399 = ptrtoint ptr %0 to i64
  %400 = ptrtoint ptr %1 to i64
  %401 = xor i64 %398, %399
  %402 = add i64 %401, %399
  %403 = or i64 %402, %400
  %404 = add i64 %403, %400
  %405 = and i64 %404, %398
  store i64 %405, ptr %3, align 8
  br label %161

406:                                              ; preds = %263
  %407 = load i64, ptr %3, align 8
  %408 = ptrtoint ptr %0 to i64
  %409 = ptrtoint ptr %1 to i64
  %410 = add i64 %407, %409
  %411 = or i64 %410, %407
  %412 = add i64 %411, %409
  store i64 %412, ptr %3, align 8
  br label %161

413:                                              ; preds = %274
  %414 = load i64, ptr %3, align 8
  %415 = ptrtoint ptr %0 to i64
  %416 = ptrtoint ptr %1 to i64
  %417 = sub i64 %414, %415
  %418 = or i64 %417, %414
  %419 = and i64 %418, %415
  store i64 %419, ptr %3, align 8
  br label %161
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpPriceDesc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  store i32 -383437895, ptr %5, align 4
  br label %11

11:                                               ; preds = %375, %162, %161, %2
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, -1336812628
  %14 = mul i32 %13, -212352467
  %15 = icmp slt i32 %14, 816864052
  br i1 %15, label %278, label %280

16:                                               ; preds = %318
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  %17 = load ptr, ptr %7, align 8
  store ptr %17, ptr %9, align 8
  %18 = load ptr, ptr %8, align 8
  store ptr %18, ptr %10, align 8
  %19 = load ptr, ptr %9, align 8
  %20 = getelementptr inbounds nuw %struct.Product, ptr %19, i32 0, i32 6
  %21 = load i32, ptr %20, align 8
  %22 = load ptr, ptr %10, align 8
  %23 = getelementptr inbounds nuw %struct.Product, ptr %22, i32 0, i32 6
  %24 = load i32, ptr %23, align 8
  %25 = icmp ne i32 %21, %24
  %26 = select i1 %25, i32 -1548527161, i32 -478902224
  store i32 %26, ptr %5, align 4
  %27 = xor i32 %4, 1522446395
  %28 = and i32 %4, %27
  %29 = or i32 %4, %27
  %30 = xor i32 %4, %27
  %31 = add i32 %4, %27
  %32 = sub i32 %31, %30
  %33 = mul i32 %28, 2
  %34 = sub i32 %32, %33
  %35 = mul i32 %34, 224
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %161, label %322

37:                                               ; preds = %298
  %38 = load ptr, ptr %10, align 8
  %39 = getelementptr inbounds nuw %struct.Product, ptr %38, i32 0, i32 6
  %40 = load i32, ptr %39, align 8
  %41 = load ptr, ptr %9, align 8
  %42 = getelementptr inbounds nuw %struct.Product, ptr %41, i32 0, i32 6
  %43 = load i32, ptr %42, align 8
  %44 = load i32, ptr %5, align 4
  %45 = xor i32 %44, 1548527160
  %46 = xor i32 %43, %45
  %47 = add i32 %40, %46
  %48 = load i32, ptr %5, align 4
  %49 = xor i32 %48, -1548527162
  %50 = add i32 %47, %49
  store i32 %50, ptr %6, align 4
  store i32 -1039879584, ptr %5, align 4
  %51 = xor i32 %4, -783036345
  %52 = and i32 %4, %51
  %53 = or i32 %4, %51
  %54 = xor i32 %4, %51
  %55 = add i32 %52, %53
  %56 = sub i32 %55, %4
  %57 = sub i32 %56, %51
  %58 = mul i32 %57, 232
  %59 = icmp eq i32 %58, 0
  br i1 %59, label %161, label %331

60:                                               ; preds = %306
  %61 = load ptr, ptr %9, align 8
  %62 = getelementptr inbounds nuw %struct.Product, ptr %61, i32 0, i32 3
  %63 = load i64, ptr %62, align 8
  %64 = load ptr, ptr %10, align 8
  %65 = getelementptr inbounds nuw %struct.Product, ptr %64, i32 0, i32 3
  %66 = load i64, ptr %65, align 8
  %67 = icmp sgt i64 %63, %66
  %68 = select i1 %67, i32 6674241, i32 -968800872
  store i32 %68, ptr %5, align 4
  %69 = xor i32 %4, -908986973
  %70 = and i32 %4, %69
  %71 = or i32 %4, %69
  %72 = xor i32 %4, %69
  %73 = add i32 %4, %69
  %74 = sub i32 %73, %72
  %75 = mul i32 %70, 2
  %76 = sub i32 %74, %75
  %77 = mul i32 %76, 6
  %78 = icmp ugt i32 %77, 0
  br i1 %78, label %338, label %161

79:                                               ; preds = %296
  store i32 -1, ptr %6, align 4
  store i32 -1039879584, ptr %5, align 4
  %80 = xor i32 %4, -2017085587
  %81 = and i32 %4, %80
  %82 = or i32 %4, %80
  %83 = xor i32 %4, %80
  %84 = mul i32 %82, 2
  %85 = sub i32 %84, %83
  %86 = sub i32 %85, %4
  %87 = sub i32 %86, %80
  %88 = mul i32 %87, 78
  %89 = xor i32 %4, 398838149
  %90 = and i32 %4, %89
  %91 = or i32 %4, %89
  %92 = xor i32 %4, %89
  %93 = add i32 %4, %89
  %94 = sub i32 %93, %92
  %95 = mul i32 %90, 2
  %96 = sub i32 %94, %95
  %97 = mul i32 %96, 89
  %98 = icmp eq i32 %88, %97
  br i1 %98, label %161, label %346

99:                                               ; preds = %312
  %100 = load ptr, ptr %9, align 8
  %101 = getelementptr inbounds nuw %struct.Product, ptr %100, i32 0, i32 3
  %102 = load i64, ptr %101, align 8
  %103 = load ptr, ptr %10, align 8
  %104 = getelementptr inbounds nuw %struct.Product, ptr %103, i32 0, i32 3
  %105 = load i64, ptr %104, align 8
  %106 = icmp slt i64 %102, %105
  %107 = select i1 %106, i32 -1876169408, i32 -1011532129
  store i32 %107, ptr %5, align 4
  %108 = xor i32 %4, -1298650781
  %109 = and i32 %4, %108
  %110 = or i32 %4, %108
  %111 = xor i32 %4, %108
  %112 = add i32 %109, %110
  %113 = sub i32 %112, %4
  %114 = sub i32 %113, %108
  %115 = mul i32 %114, 225
  %116 = xor i32 %4, -936047921
  %117 = and i32 %4, %116
  %118 = or i32 %4, %116
  %119 = xor i32 %4, %116
  %120 = add i32 %4, %116
  %121 = sub i32 %120, %119
  %122 = mul i32 %117, 2
  %123 = sub i32 %121, %122
  %124 = mul i32 %123, 129
  %125 = icmp ne i32 %115, %124
  br i1 %125, label %353, label %161

126:                                              ; preds = %292
  store i32 1, ptr %6, align 4
  store i32 -1039879584, ptr %5, align 4
  %127 = xor i32 %4, 1804080975
  %128 = and i32 %4, %127
  %129 = or i32 %4, %127
  %130 = xor i32 %4, %127
  %131 = add i32 %4, %127
  %132 = sub i32 %131, %130
  %133 = mul i32 %128, 2
  %134 = sub i32 %132, %133
  %135 = mul i32 %134, 209
  %136 = icmp ne i32 %135, 0
  br i1 %136, label %361, label %161

137:                                              ; preds = %286
  %138 = load ptr, ptr %9, align 8
  %139 = getelementptr inbounds nuw %struct.Product, ptr %138, i32 0, i32 0
  %140 = load i32, ptr %139, align 8
  %141 = load ptr, ptr %10, align 8
  %142 = getelementptr inbounds nuw %struct.Product, ptr %141, i32 0, i32 0
  %143 = load i32, ptr %142, align 8
  %144 = load i32, ptr %5, align 4
  %145 = xor i32 %144, 1011532128
  %146 = xor i32 %143, %145
  %147 = add i32 %140, %146
  %148 = load i32, ptr %5, align 4
  %149 = xor i32 %148, -1011532130
  %150 = add i32 %147, %149
  store i32 %150, ptr %6, align 4
  store i32 -1039879584, ptr %5, align 4
  %151 = xor i32 %4, -1363896519
  %152 = and i32 %4, %151
  %153 = or i32 %4, %151
  %154 = xor i32 %4, %151
  %155 = sub i32 %153, %154
  %156 = sub i32 %155, %152
  %157 = mul i32 %156, 47
  %158 = icmp ugt i32 %157, 0
  br i1 %158, label %368, label %161

159:                                              ; preds = %316
  %160 = load i32, ptr %6, align 4
  ret i32 %160

161:                                              ; preds = %448, %438, %430, %422, %414, %404, %394, %385, %368, %361, %353, %346, %338, %331, %322, %267, %254, %242, %229, %218, %207, %194, %181, %137, %126, %99, %79, %60, %37, %16
  br label %11

162:                                              ; preds = %320, %318, %312, %310, %300, %298, %292, %290
  store i32 -383437895, ptr %5, align 4
  call void asm sideeffect "", ""()
  %163 = xor i32 %4, -1196960887
  %164 = and i32 %4, %163
  %165 = or i32 %4, %163
  %166 = xor i32 %4, %163
  %167 = add i32 %164, %165
  %168 = sub i32 %167, %4
  %169 = sub i32 %168, %163
  %170 = mul i32 %169, 93
  %171 = xor i32 %4, 71878081
  %172 = and i32 %4, %171
  %173 = or i32 %4, %171
  %174 = xor i32 %4, %171
  %175 = mul i32 %173, 2
  %176 = sub i32 %175, %174
  %177 = sub i32 %176, %4
  %178 = sub i32 %177, %171
  %179 = mul i32 %178, 69
  %180 = icmp ne i32 %170, %179
  br i1 %180, label %375, label %11

181:                                              ; preds = %320
  %182 = load i32, ptr %5, align 4
  %183 = xor i32 %182, 1274075674
  store i32 %183, ptr %5, align 4
  %184 = xor i32 %4, -256773101
  %185 = and i32 %4, %184
  %186 = or i32 %4, %184
  %187 = xor i32 %4, %184
  %188 = add i32 %4, %184
  %189 = sub i32 %188, %187
  %190 = mul i32 %185, 2
  %191 = sub i32 %189, %190
  %192 = mul i32 %191, 92
  %193 = icmp eq i32 %192, 0
  br i1 %193, label %161, label %385

194:                                              ; preds = %300
  %195 = load i32, ptr %5, align 4
  %196 = xor i32 %195, -1148610618
  store i32 %196, ptr %5, align 4
  %197 = xor i32 %4, -1036787977
  %198 = and i32 %4, %197
  %199 = or i32 %4, %197
  %200 = xor i32 %4, %197
  %201 = mul i32 %199, 2
  %202 = sub i32 %201, %200
  %203 = sub i32 %202, %4
  %204 = sub i32 %203, %197
  %205 = mul i32 %204, 210
  %206 = icmp slt i32 %205, 1
  br i1 %206, label %161, label %394

207:                                              ; preds = %294
  %208 = load i32, ptr %5, align 4
  %209 = xor i32 %208, -1320449376
  store i32 %209, ptr %5, align 4
  %210 = xor i32 %4, 1178810645
  %211 = and i32 %4, %210
  %212 = or i32 %4, %210
  %213 = xor i32 %4, %210
  %214 = sub i32 %212, %213
  %215 = sub i32 %214, %211
  %216 = mul i32 %215, 93
  %217 = icmp eq i32 %216, 0
  br i1 %217, label %161, label %404

218:                                              ; preds = %288
  %219 = load i32, ptr %5, align 4
  %220 = xor i32 %219, 1366904579
  store i32 %220, ptr %5, align 4
  %221 = xor i32 %4, -1080855731
  %222 = and i32 %4, %221
  %223 = or i32 %4, %221
  %224 = xor i32 %4, %221
  %225 = sub i32 %223, %224
  %226 = sub i32 %225, %222
  %227 = mul i32 %226, 14
  %228 = icmp eq i32 %227, 0
  br i1 %228, label %161, label %414

229:                                              ; preds = %290
  %230 = load i32, ptr %5, align 4
  %231 = xor i32 %230, -410920348
  store i32 %231, ptr %5, align 4
  %232 = xor i32 %4, 782099549
  %233 = and i32 %4, %232
  %234 = or i32 %4, %232
  %235 = xor i32 %4, %232
  %236 = mul i32 %234, 2
  %237 = sub i32 %236, %235
  %238 = sub i32 %237, %4
  %239 = sub i32 %238, %232
  %240 = mul i32 %239, 101
  %241 = icmp slt i32 %240, 0
  br i1 %241, label %422, label %161

242:                                              ; preds = %314
  %243 = load i32, ptr %5, align 4
  %244 = xor i32 %243, 609987273
  store i32 %244, ptr %5, align 4
  %245 = xor i32 %4, 18915755
  %246 = and i32 %4, %245
  %247 = or i32 %4, %245
  %248 = xor i32 %4, %245
  %249 = add i32 %246, %247
  %250 = sub i32 %249, %4
  %251 = sub i32 %250, %245
  %252 = mul i32 %251, 73
  %253 = icmp ne i32 %252, 0
  br i1 %253, label %430, label %161

254:                                              ; preds = %308
  %255 = load i32, ptr %5, align 4
  %256 = xor i32 %255, -1517620815
  store i32 %256, ptr %5, align 4
  %257 = xor i32 %4, 91768605
  %258 = and i32 %4, %257
  %259 = or i32 %4, %257
  %260 = xor i32 %4, %257
  %261 = mul i32 %259, 2
  %262 = sub i32 %261, %260
  %263 = sub i32 %262, %4
  %264 = sub i32 %263, %257
  %265 = mul i32 %264, 242
  %266 = icmp eq i32 %265, 0
  br i1 %266, label %161, label %438

267:                                              ; preds = %310
  %268 = load i32, ptr %5, align 4
  %269 = xor i32 %268, 395571423
  store i32 %269, ptr %5, align 4
  %270 = xor i32 %4, 1070487183
  %271 = and i32 %4, %270
  %272 = or i32 %4, %270
  %273 = xor i32 %4, %270
  %274 = sub i32 %272, %273
  %275 = sub i32 %274, %271
  %276 = mul i32 %275, 177
  %277 = icmp slt i32 %276, 1
  br i1 %277, label %161, label %448

278:                                              ; preds = %11
  %279 = icmp slt i32 %14, 394211453
  br i1 %279, label %282, label %284

280:                                              ; preds = %11
  %281 = icmp slt i32 %14, 1515680695
  br i1 %281, label %302, label %304

282:                                              ; preds = %278
  %283 = icmp slt i32 %14, 257947842
  br i1 %283, label %286, label %288

284:                                              ; preds = %278
  %285 = icmp slt i32 %14, 650978097
  br i1 %285, label %294, label %296

286:                                              ; preds = %282
  %287 = icmp eq i32 %14, 50956983
  br i1 %287, label %137, label %290

288:                                              ; preds = %282
  %289 = icmp eq i32 %14, 257947842
  br i1 %289, label %218, label %292

290:                                              ; preds = %286
  %291 = icmp eq i32 %14, 64342087
  br i1 %291, label %229, label %162

292:                                              ; preds = %288
  %293 = icmp eq i32 %14, 267599620
  br i1 %293, label %126, label %162

294:                                              ; preds = %284
  %295 = icmp eq i32 %14, 394211453
  br i1 %295, label %207, label %298

296:                                              ; preds = %284
  %297 = icmp eq i32 %14, 650978097
  br i1 %297, label %79, label %300

298:                                              ; preds = %294
  %299 = icmp eq i32 %14, 635478207
  br i1 %299, label %37, label %162

300:                                              ; preds = %296
  %301 = icmp eq i32 %14, 667542334
  br i1 %301, label %194, label %162

302:                                              ; preds = %280
  %303 = icmp slt i32 %14, 1051548590
  br i1 %303, label %306, label %308

304:                                              ; preds = %280
  %305 = icmp slt i32 %14, 1984964004
  br i1 %305, label %314, label %316

306:                                              ; preds = %302
  %307 = icmp eq i32 %14, 816864052
  br i1 %307, label %60, label %310

308:                                              ; preds = %302
  %309 = icmp eq i32 %14, 1051548590
  br i1 %309, label %254, label %312

310:                                              ; preds = %306
  %311 = icmp eq i32 %14, 1019599930
  br i1 %311, label %267, label %162

312:                                              ; preds = %308
  %313 = icmp eq i32 %14, 1284404860
  br i1 %313, label %99, label %162

314:                                              ; preds = %304
  %315 = icmp eq i32 %14, 1515680695
  br i1 %315, label %242, label %318

316:                                              ; preds = %304
  %317 = icmp eq i32 %14, 1984964004
  br i1 %317, label %159, label %320

318:                                              ; preds = %314
  %319 = icmp eq i32 %14, 1766544457
  br i1 %319, label %16, label %162

320:                                              ; preds = %316
  %321 = icmp eq i32 %14, 2061877497
  br i1 %321, label %181, label %162

322:                                              ; preds = %16
  %323 = load i64, ptr %3, align 8
  %324 = ptrtoint ptr %0 to i64
  %325 = ptrtoint ptr %1 to i64
  %326 = add i64 %325, %325
  %327 = and i64 %326, %323
  %328 = mul i64 %327, %324
  %329 = xor i64 %328, %324
  %330 = xor i64 %329, %325
  store i64 %330, ptr %3, align 8
  br label %161

331:                                              ; preds = %37
  %332 = load i64, ptr %3, align 8
  %333 = ptrtoint ptr %0 to i64
  %334 = ptrtoint ptr %1 to i64
  %335 = xor i64 %334, %334
  %336 = or i64 %335, %332
  %337 = sub i64 %336, %333
  store i64 %337, ptr %3, align 8
  br label %161

338:                                              ; preds = %60
  %339 = load i64, ptr %3, align 8
  %340 = ptrtoint ptr %0 to i64
  %341 = ptrtoint ptr %1 to i64
  %342 = xor i64 %341, %341
  %343 = add i64 %342, %340
  %344 = add i64 %343, %340
  %345 = sub i64 %344, %340
  store i64 %345, ptr %3, align 8
  br label %161

346:                                              ; preds = %79
  %347 = load i64, ptr %3, align 8
  %348 = ptrtoint ptr %0 to i64
  %349 = ptrtoint ptr %1 to i64
  %350 = xor i64 %347, %348
  %351 = add i64 %350, %347
  %352 = mul i64 %351, %348
  store i64 %352, ptr %3, align 8
  br label %161

353:                                              ; preds = %99
  %354 = load i64, ptr %3, align 8
  %355 = ptrtoint ptr %0 to i64
  %356 = ptrtoint ptr %1 to i64
  %357 = mul i64 %355, %355
  %358 = xor i64 %357, %354
  %359 = sub i64 %358, %355
  %360 = and i64 %359, %356
  store i64 %360, ptr %3, align 8
  br label %161

361:                                              ; preds = %126
  %362 = load i64, ptr %3, align 8
  %363 = ptrtoint ptr %0 to i64
  %364 = ptrtoint ptr %1 to i64
  %365 = add i64 %364, %363
  %366 = xor i64 %365, %362
  %367 = mul i64 %366, %362
  store i64 %367, ptr %3, align 8
  br label %161

368:                                              ; preds = %137
  %369 = load i64, ptr %3, align 8
  %370 = ptrtoint ptr %0 to i64
  %371 = ptrtoint ptr %1 to i64
  %372 = add i64 %370, %370
  %373 = sub i64 %372, %371
  %374 = sub i64 %373, %369
  store i64 %374, ptr %3, align 8
  br label %161

375:                                              ; preds = %162
  %376 = load i64, ptr %3, align 8
  %377 = ptrtoint ptr %0 to i64
  %378 = ptrtoint ptr %1 to i64
  %379 = add i64 %377, %377
  %380 = sub i64 %379, %376
  %381 = sub i64 %380, %377
  %382 = or i64 %381, %377
  %383 = xor i64 %382, %377
  %384 = mul i64 %383, %377
  store i64 %384, ptr %3, align 8
  br label %11

385:                                              ; preds = %181
  %386 = load i64, ptr %3, align 8
  %387 = ptrtoint ptr %0 to i64
  %388 = ptrtoint ptr %1 to i64
  %389 = add i64 %388, %388
  %390 = or i64 %389, %388
  %391 = xor i64 %390, %386
  %392 = xor i64 %391, %388
  %393 = sub i64 %392, %386
  store i64 %393, ptr %3, align 8
  br label %161

394:                                              ; preds = %194
  %395 = load i64, ptr %3, align 8
  %396 = ptrtoint ptr %0 to i64
  %397 = ptrtoint ptr %1 to i64
  %398 = add i64 %397, %396
  %399 = xor i64 %398, %395
  %400 = xor i64 %399, %395
  %401 = or i64 %400, %395
  %402 = and i64 %401, %397
  %403 = or i64 %402, %396
  store i64 %403, ptr %3, align 8
  br label %161

404:                                              ; preds = %207
  %405 = load i64, ptr %3, align 8
  %406 = ptrtoint ptr %0 to i64
  %407 = ptrtoint ptr %1 to i64
  %408 = xor i64 %405, %405
  %409 = and i64 %408, %406
  %410 = add i64 %409, %407
  %411 = xor i64 %410, %406
  %412 = or i64 %411, %405
  %413 = and i64 %412, %407
  store i64 %413, ptr %3, align 8
  br label %161

414:                                              ; preds = %218
  %415 = load i64, ptr %3, align 8
  %416 = ptrtoint ptr %0 to i64
  %417 = ptrtoint ptr %1 to i64
  %418 = xor i64 %415, %416
  %419 = mul i64 %418, %415
  %420 = and i64 %419, %417
  %421 = add i64 %420, %416
  store i64 %421, ptr %3, align 8
  br label %161

422:                                              ; preds = %229
  %423 = load i64, ptr %3, align 8
  %424 = ptrtoint ptr %0 to i64
  %425 = ptrtoint ptr %1 to i64
  %426 = mul i64 %424, %424
  %427 = or i64 %426, %423
  %428 = add i64 %427, %425
  %429 = mul i64 %428, %423
  store i64 %429, ptr %3, align 8
  br label %161

430:                                              ; preds = %242
  %431 = load i64, ptr %3, align 8
  %432 = ptrtoint ptr %0 to i64
  %433 = ptrtoint ptr %1 to i64
  %434 = xor i64 %431, %431
  %435 = or i64 %434, %431
  %436 = mul i64 %435, %431
  %437 = and i64 %436, %433
  store i64 %437, ptr %3, align 8
  br label %161

438:                                              ; preds = %254
  %439 = load i64, ptr %3, align 8
  %440 = ptrtoint ptr %0 to i64
  %441 = ptrtoint ptr %1 to i64
  %442 = and i64 %439, %439
  %443 = mul i64 %442, %440
  %444 = or i64 %443, %440
  %445 = mul i64 %444, %441
  %446 = mul i64 %445, %440
  %447 = or i64 %446, %439
  store i64 %447, ptr %3, align 8
  br label %161

448:                                              ; preds = %267
  %449 = load i64, ptr %3, align 8
  %450 = ptrtoint ptr %0 to i64
  %451 = ptrtoint ptr %1 to i64
  %452 = add i64 %450, %451
  %453 = sub i64 %452, %449
  %454 = sub i64 %453, %450
  store i64 %454, ptr %3, align 8
  br label %161
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpStockAsc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  store i32 2089753051, ptr %5, align 4
  br label %11

11:                                               ; preds = %299, %127, %126, %2
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 552794865
  %14 = mul i32 %13, -790966887
  %15 = icmp slt i32 %14, 756052209
  br i1 %15, label %221, label %223

16:                                               ; preds = %249
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  %17 = load ptr, ptr %7, align 8
  store ptr %17, ptr %9, align 8
  %18 = load ptr, ptr %8, align 8
  store ptr %18, ptr %10, align 8
  %19 = load ptr, ptr %9, align 8
  %20 = getelementptr inbounds nuw %struct.Product, ptr %19, i32 0, i32 6
  %21 = load i32, ptr %20, align 8
  %22 = load ptr, ptr %10, align 8
  %23 = getelementptr inbounds nuw %struct.Product, ptr %22, i32 0, i32 6
  %24 = load i32, ptr %23, align 8
  %25 = icmp ne i32 %21, %24
  %26 = select i1 %25, i32 1024661023, i32 1302605639
  store i32 %26, ptr %5, align 4
  %27 = xor i32 %4, -1971098809
  %28 = and i32 %4, %27
  %29 = or i32 %4, %27
  %30 = xor i32 %4, %27
  %31 = add i32 %28, %29
  %32 = sub i32 %31, %4
  %33 = sub i32 %32, %27
  %34 = mul i32 %33, 172
  %35 = icmp sgt i32 %34, 0
  br i1 %35, label %257, label %126

36:                                               ; preds = %233
  %37 = load ptr, ptr %10, align 8
  %38 = getelementptr inbounds nuw %struct.Product, ptr %37, i32 0, i32 6
  %39 = load i32, ptr %38, align 8
  %40 = load ptr, ptr %9, align 8
  %41 = getelementptr inbounds nuw %struct.Product, ptr %40, i32 0, i32 6
  %42 = load i32, ptr %41, align 8
  %43 = load i32, ptr %5, align 4
  %44 = xor i32 %43, 1024661022
  %45 = add i32 %42, %44
  %46 = load i32, ptr %5, align 4
  %47 = xor i32 %46, 1024661022
  %48 = add i32 %39, %47
  %49 = mul i32 %39, %45
  %50 = mul i32 %42, %48
  %51 = sub i32 %49, %50
  store i32 %51, ptr %6, align 4
  store i32 -2058330102, ptr %5, align 4
  %52 = xor i32 %4, -915695783
  %53 = and i32 %4, %52
  %54 = or i32 %4, %52
  %55 = xor i32 %4, %52
  %56 = add i32 %53, %54
  %57 = sub i32 %56, %4
  %58 = sub i32 %57, %52
  %59 = mul i32 %58, 75
  %60 = icmp slt i32 %59, 0
  br i1 %60, label %267, label %126

61:                                               ; preds = %237
  %62 = load ptr, ptr %9, align 8
  %63 = getelementptr inbounds nuw %struct.Product, ptr %62, i32 0, i32 4
  %64 = load i32, ptr %63, align 8
  %65 = load ptr, ptr %10, align 8
  %66 = getelementptr inbounds nuw %struct.Product, ptr %65, i32 0, i32 4
  %67 = load i32, ptr %66, align 8
  %68 = icmp ne i32 %64, %67
  %69 = select i1 %68, i32 -1459536982, i32 -493359991
  store i32 %69, ptr %5, align 4
  %70 = xor i32 %4, 563859307
  %71 = and i32 %4, %70
  %72 = or i32 %4, %70
  %73 = xor i32 %4, %70
  %74 = add i32 %4, %70
  %75 = sub i32 %74, %73
  %76 = mul i32 %71, 2
  %77 = sub i32 %75, %76
  %78 = mul i32 %77, 9
  %79 = icmp uge i32 %78, 0
  br i1 %79, label %126, label %276

80:                                               ; preds = %239
  %81 = load ptr, ptr %9, align 8
  %82 = getelementptr inbounds nuw %struct.Product, ptr %81, i32 0, i32 4
  %83 = load i32, ptr %82, align 8
  %84 = load ptr, ptr %10, align 8
  %85 = getelementptr inbounds nuw %struct.Product, ptr %84, i32 0, i32 4
  %86 = load i32, ptr %85, align 8
  %87 = xor i32 %83, %86
  %88 = load i32, ptr %5, align 4
  %89 = xor i32 %88, 1459536981
  %90 = xor i32 %83, %89
  %91 = and i32 %90, %86
  %92 = add i32 %91, %91
  %93 = sub i32 %87, %92
  store i32 %93, ptr %6, align 4
  store i32 -2058330102, ptr %5, align 4
  %94 = xor i32 %4, 659410833
  %95 = and i32 %4, %94
  %96 = or i32 %4, %94
  %97 = xor i32 %4, %94
  %98 = sub i32 %96, %97
  %99 = sub i32 %98, %95
  %100 = mul i32 %99, 244
  %101 = icmp slt i32 %100, 0
  br i1 %101, label %285, label %126

102:                                              ; preds = %235
  %103 = load ptr, ptr %9, align 8
  %104 = getelementptr inbounds nuw %struct.Product, ptr %103, i32 0, i32 0
  %105 = load i32, ptr %104, align 8
  %106 = load ptr, ptr %10, align 8
  %107 = getelementptr inbounds nuw %struct.Product, ptr %106, i32 0, i32 0
  %108 = load i32, ptr %107, align 8
  %109 = xor i32 %105, %108
  %110 = load i32, ptr %5, align 4
  %111 = xor i32 %110, 493359990
  %112 = xor i32 %105, %111
  %113 = and i32 %112, %108
  %114 = add i32 %113, %113
  %115 = sub i32 %109, %114
  store i32 %115, ptr %6, align 4
  store i32 -2058330102, ptr %5, align 4
  %116 = xor i32 %4, -59100029
  %117 = and i32 %4, %116
  %118 = or i32 %4, %116
  %119 = xor i32 %4, %116
  %120 = sub i32 %118, %119
  %121 = sub i32 %120, %117
  %122 = mul i32 %121, 173
  %123 = icmp ugt i32 %122, 0
  br i1 %123, label %292, label %126

124:                                              ; preds = %245
  %125 = load i32, ptr %6, align 4
  ret i32 %125

126:                                              ; preds = %354, %345, %337, %327, %317, %308, %292, %285, %276, %267, %257, %210, %190, %177, %164, %151, %138, %102, %80, %61, %36, %16
  br label %11

127:                                              ; preds = %255, %251, %249, %245, %239, %235, %233, %229
  store i32 2089753051, ptr %5, align 4
  call void asm sideeffect "", ""()
  %128 = xor i32 %4, -1051304207
  %129 = and i32 %4, %128
  %130 = or i32 %4, %128
  %131 = xor i32 %4, %128
  %132 = add i32 %4, %128
  %133 = sub i32 %132, %131
  %134 = mul i32 %129, 2
  %135 = sub i32 %133, %134
  %136 = mul i32 %135, 184
  %137 = icmp slt i32 %136, 1
  br i1 %137, label %11, label %299

138:                                              ; preds = %229
  %139 = load i32, ptr %5, align 4
  %140 = xor i32 %139, 1067753742
  store i32 %140, ptr %5, align 4
  %141 = xor i32 %4, -886821023
  %142 = and i32 %4, %141
  %143 = or i32 %4, %141
  %144 = xor i32 %4, %141
  %145 = mul i32 %143, 2
  %146 = sub i32 %145, %144
  %147 = sub i32 %146, %4
  %148 = sub i32 %147, %141
  %149 = mul i32 %148, 180
  %150 = icmp slt i32 %149, 1
  br i1 %150, label %126, label %308

151:                                              ; preds = %231
  %152 = load i32, ptr %5, align 4
  %153 = xor i32 %152, 1676539562
  store i32 %153, ptr %5, align 4
  %154 = xor i32 %4, -862605319
  %155 = and i32 %4, %154
  %156 = or i32 %4, %154
  %157 = xor i32 %4, %154
  %158 = add i32 %4, %154
  %159 = sub i32 %158, %157
  %160 = mul i32 %155, 2
  %161 = sub i32 %159, %160
  %162 = mul i32 %161, 97
  %163 = icmp sgt i32 %162, 0
  br i1 %163, label %317, label %126

164:                                              ; preds = %255
  %165 = load i32, ptr %5, align 4
  %166 = xor i32 %165, -156311334
  store i32 %166, ptr %5, align 4
  %167 = xor i32 %4, -1798115207
  %168 = and i32 %4, %167
  %169 = or i32 %4, %167
  %170 = xor i32 %4, %167
  %171 = mul i32 %169, 2
  %172 = sub i32 %171, %170
  %173 = sub i32 %172, %4
  %174 = sub i32 %173, %167
  %175 = mul i32 %174, 47
  %176 = icmp slt i32 %175, 1
  br i1 %176, label %126, label %327

177:                                              ; preds = %253
  %178 = load i32, ptr %5, align 4
  %179 = xor i32 %178, -199281580
  store i32 %179, ptr %5, align 4
  %180 = xor i32 %4, 892587383
  %181 = and i32 %4, %180
  %182 = or i32 %4, %180
  %183 = xor i32 %4, %180
  %184 = add i32 %4, %180
  %185 = sub i32 %184, %183
  %186 = mul i32 %181, 2
  %187 = sub i32 %185, %186
  %188 = mul i32 %187, 133
  %189 = icmp slt i32 %188, 1
  br i1 %189, label %126, label %337

190:                                              ; preds = %251
  %191 = load i32, ptr %5, align 4
  %192 = xor i32 %191, 1933219450
  store i32 %192, ptr %5, align 4
  %193 = xor i32 %4, -1157039951
  %194 = and i32 %4, %193
  %195 = or i32 %4, %193
  %196 = xor i32 %4, %193
  %197 = sub i32 %195, %196
  %198 = sub i32 %197, %194
  %199 = mul i32 %198, 50
  %200 = xor i32 %4, 274555357
  %201 = and i32 %4, %200
  %202 = or i32 %4, %200
  %203 = xor i32 %4, %200
  %204 = add i32 %4, %200
  %205 = sub i32 %204, %203
  %206 = mul i32 %201, 2
  %207 = sub i32 %205, %206
  %208 = mul i32 %207, 109
  %209 = icmp eq i32 %199, %208
  br i1 %209, label %126, label %345

210:                                              ; preds = %247
  %211 = load i32, ptr %5, align 4
  %212 = xor i32 %211, -275686431
  store i32 %212, ptr %5, align 4
  %213 = xor i32 %4, 174754089
  %214 = and i32 %4, %213
  %215 = or i32 %4, %213
  %216 = xor i32 %4, %213
  %217 = sub i32 %215, %216
  %218 = sub i32 %217, %214
  %219 = mul i32 %218, 138
  %220 = icmp slt i32 %219, 1
  br i1 %220, label %126, label %354

221:                                              ; preds = %11
  %222 = icmp slt i32 %14, 209394648
  br i1 %222, label %225, label %227

223:                                              ; preds = %11
  %224 = icmp slt i32 %14, 1040104040
  br i1 %224, label %241, label %243

225:                                              ; preds = %221
  %226 = icmp slt i32 %14, 31186644
  br i1 %226, label %229, label %231

227:                                              ; preds = %221
  %228 = icmp slt i32 %14, 235742566
  br i1 %228, label %235, label %237

229:                                              ; preds = %225
  %230 = icmp eq i32 %14, 13481045
  br i1 %230, label %138, label %127

231:                                              ; preds = %225
  %232 = icmp eq i32 %14, 31186644
  br i1 %232, label %151, label %233

233:                                              ; preds = %231
  %234 = icmp eq i32 %14, 169874558
  br i1 %234, label %36, label %127

235:                                              ; preds = %227
  %236 = icmp eq i32 %14, 209394648
  br i1 %236, label %102, label %127

237:                                              ; preds = %227
  %238 = icmp eq i32 %14, 235742566
  br i1 %238, label %61, label %239

239:                                              ; preds = %237
  %240 = icmp eq i32 %14, 669176721
  br i1 %240, label %80, label %127

241:                                              ; preds = %223
  %242 = icmp slt i32 %14, 804814184
  br i1 %242, label %245, label %247

243:                                              ; preds = %223
  %244 = icmp slt i32 %14, 1339880039
  br i1 %244, label %251, label %253

245:                                              ; preds = %241
  %246 = icmp eq i32 %14, 756052209
  br i1 %246, label %124, label %127

247:                                              ; preds = %241
  %248 = icmp eq i32 %14, 804814184
  br i1 %248, label %210, label %249

249:                                              ; preds = %247
  %250 = icmp eq i32 %14, 945019866
  br i1 %250, label %16, label %127

251:                                              ; preds = %243
  %252 = icmp eq i32 %14, 1040104040
  br i1 %252, label %190, label %127

253:                                              ; preds = %243
  %254 = icmp eq i32 %14, 1339880039
  br i1 %254, label %177, label %255

255:                                              ; preds = %253
  %256 = icmp eq i32 %14, 2116186521
  br i1 %256, label %164, label %127

257:                                              ; preds = %16
  %258 = load i64, ptr %3, align 8
  %259 = ptrtoint ptr %0 to i64
  %260 = ptrtoint ptr %1 to i64
  %261 = sub i64 %259, %259
  %262 = or i64 %261, %258
  %263 = add i64 %262, %258
  %264 = or i64 %263, %258
  %265 = sub i64 %264, %258
  %266 = and i64 %265, %260
  store i64 %266, ptr %3, align 8
  br label %126

267:                                              ; preds = %36
  %268 = load i64, ptr %3, align 8
  %269 = ptrtoint ptr %0 to i64
  %270 = ptrtoint ptr %1 to i64
  %271 = mul i64 %268, %269
  %272 = mul i64 %271, %268
  %273 = mul i64 %272, %269
  %274 = sub i64 %273, %269
  %275 = or i64 %274, %270
  store i64 %275, ptr %3, align 8
  br label %126

276:                                              ; preds = %61
  %277 = load i64, ptr %3, align 8
  %278 = ptrtoint ptr %0 to i64
  %279 = ptrtoint ptr %1 to i64
  %280 = add i64 %277, %277
  %281 = and i64 %280, %279
  %282 = or i64 %281, %279
  %283 = or i64 %282, %278
  %284 = add i64 %283, %277
  store i64 %284, ptr %3, align 8
  br label %126

285:                                              ; preds = %80
  %286 = load i64, ptr %3, align 8
  %287 = ptrtoint ptr %0 to i64
  %288 = ptrtoint ptr %1 to i64
  %289 = and i64 %287, %286
  %290 = or i64 %289, %286
  %291 = sub i64 %290, %288
  store i64 %291, ptr %3, align 8
  br label %126

292:                                              ; preds = %102
  %293 = load i64, ptr %3, align 8
  %294 = ptrtoint ptr %0 to i64
  %295 = ptrtoint ptr %1 to i64
  %296 = and i64 %293, %293
  %297 = and i64 %296, %293
  %298 = xor i64 %297, %294
  store i64 %298, ptr %3, align 8
  br label %126

299:                                              ; preds = %127
  %300 = load i64, ptr %3, align 8
  %301 = ptrtoint ptr %0 to i64
  %302 = ptrtoint ptr %1 to i64
  %303 = sub i64 %301, %300
  %304 = or i64 %303, %302
  %305 = or i64 %304, %300
  %306 = mul i64 %305, %301
  %307 = or i64 %306, %301
  store i64 %307, ptr %3, align 8
  br label %11

308:                                              ; preds = %138
  %309 = load i64, ptr %3, align 8
  %310 = ptrtoint ptr %0 to i64
  %311 = ptrtoint ptr %1 to i64
  %312 = sub i64 %310, %311
  %313 = mul i64 %312, %310
  %314 = add i64 %313, %310
  %315 = and i64 %314, %310
  %316 = or i64 %315, %310
  store i64 %316, ptr %3, align 8
  br label %126

317:                                              ; preds = %151
  %318 = load i64, ptr %3, align 8
  %319 = ptrtoint ptr %0 to i64
  %320 = ptrtoint ptr %1 to i64
  %321 = mul i64 %318, %319
  %322 = sub i64 %321, %318
  %323 = and i64 %322, %319
  %324 = mul i64 %323, %320
  %325 = mul i64 %324, %320
  %326 = and i64 %325, %320
  store i64 %326, ptr %3, align 8
  br label %126

327:                                              ; preds = %164
  %328 = load i64, ptr %3, align 8
  %329 = ptrtoint ptr %0 to i64
  %330 = ptrtoint ptr %1 to i64
  %331 = mul i64 %328, %330
  %332 = xor i64 %331, %330
  %333 = mul i64 %332, %330
  %334 = and i64 %333, %328
  %335 = mul i64 %334, %328
  %336 = xor i64 %335, %328
  store i64 %336, ptr %3, align 8
  br label %126

337:                                              ; preds = %177
  %338 = load i64, ptr %3, align 8
  %339 = ptrtoint ptr %0 to i64
  %340 = ptrtoint ptr %1 to i64
  %341 = mul i64 %340, %340
  %342 = and i64 %341, %339
  %343 = or i64 %342, %338
  %344 = add i64 %343, %339
  store i64 %344, ptr %3, align 8
  br label %126

345:                                              ; preds = %190
  %346 = load i64, ptr %3, align 8
  %347 = ptrtoint ptr %0 to i64
  %348 = ptrtoint ptr %1 to i64
  %349 = mul i64 %347, %347
  %350 = sub i64 %349, %346
  %351 = sub i64 %350, %346
  %352 = sub i64 %351, %348
  %353 = sub i64 %352, %348
  store i64 %353, ptr %3, align 8
  br label %126

354:                                              ; preds = %210
  %355 = load i64, ptr %3, align 8
  %356 = ptrtoint ptr %0 to i64
  %357 = ptrtoint ptr %1 to i64
  %358 = mul i64 %355, %357
  %359 = and i64 %358, %356
  %360 = mul i64 %359, %355
  store i64 %360, ptr %3, align 8
  br label %126
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpSoldDesc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  store i32 1929832896, ptr %5, align 4
  br label %11

11:                                               ; preds = %268, %138, %137, %2
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, -241527213
  %14 = mul i32 %13, -703581287
  switch i32 %14, label %138 [
    i32 1126994725, label %15
    i32 901320538, label %36
    i32 846176652, label %59
    i32 1692329614, label %85
    i32 580446953, label %109
    i32 1032759354, label %135
    i32 59206227, label %148
    i32 1747623731, label %161
    i32 1133867445, label %174
    i32 411611555, label %187
    i32 586506504, label %200
    i32 1403179908, label %213
  ]

15:                                               ; preds = %11
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  %16 = load ptr, ptr %7, align 8
  store ptr %16, ptr %9, align 8
  %17 = load ptr, ptr %8, align 8
  store ptr %17, ptr %10, align 8
  %18 = load ptr, ptr %9, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 6
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %10, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 6
  %23 = load i32, ptr %22, align 8
  %24 = icmp ne i32 %20, %23
  %25 = select i1 %24, i32 -1830086467, i32 -908231745
  store i32 %25, ptr %5, align 4
  %26 = xor i32 %4, -1547199917
  %27 = and i32 %4, %26
  %28 = or i32 %4, %26
  %29 = xor i32 %4, %26
  %30 = mul i32 %28, 2
  %31 = sub i32 %30, %29
  %32 = sub i32 %31, %4
  %33 = sub i32 %32, %26
  %34 = mul i32 %33, 17
  %35 = icmp slt i32 %34, 1
  br i1 %35, label %137, label %225

36:                                               ; preds = %11
  %37 = load ptr, ptr %10, align 8
  %38 = getelementptr inbounds nuw %struct.Product, ptr %37, i32 0, i32 6
  %39 = load i32, ptr %38, align 8
  %40 = load ptr, ptr %9, align 8
  %41 = getelementptr inbounds nuw %struct.Product, ptr %40, i32 0, i32 6
  %42 = load i32, ptr %41, align 8
  %43 = xor i32 %39, %42
  %44 = load i32, ptr %5, align 4
  %45 = xor i32 %44, 1830086466
  %46 = xor i32 %39, %45
  %47 = and i32 %46, %42
  %48 = add i32 %47, %47
  %49 = sub i32 %43, %48
  store i32 %49, ptr %6, align 4
  store i32 2121204893, ptr %5, align 4
  %50 = xor i32 %4, -2090307213
  %51 = and i32 %4, %50
  %52 = or i32 %4, %50
  %53 = xor i32 %4, %50
  %54 = add i32 %51, %52
  %55 = sub i32 %54, %4
  %56 = sub i32 %55, %50
  %57 = mul i32 %56, 87
  %58 = icmp slt i32 %57, 0
  br i1 %58, label %235, label %137

59:                                               ; preds = %11
  %60 = load ptr, ptr %9, align 8
  %61 = getelementptr inbounds nuw %struct.Product, ptr %60, i32 0, i32 5
  %62 = load i32, ptr %61, align 4
  %63 = load ptr, ptr %10, align 8
  %64 = getelementptr inbounds nuw %struct.Product, ptr %63, i32 0, i32 5
  %65 = load i32, ptr %64, align 4
  %66 = icmp ne i32 %62, %65
  %67 = select i1 %66, i32 157870609, i32 -1862362588
  store i32 %67, ptr %5, align 4
  %68 = xor i32 %4, 1941092859
  %69 = and i32 %4, %68
  %70 = or i32 %4, %68
  %71 = xor i32 %4, %68
  %72 = sub i32 %70, %71
  %73 = sub i32 %72, %69
  %74 = mul i32 %73, 50
  %75 = xor i32 %4, 121418455
  %76 = and i32 %4, %75
  %77 = or i32 %4, %75
  %78 = xor i32 %4, %75
  %79 = mul i32 %77, 2
  %80 = sub i32 %79, %78
  %81 = sub i32 %80, %4
  %82 = sub i32 %81, %75
  %83 = mul i32 %82, 144
  %84 = icmp ne i32 %74, %83
  br i1 %84, label %242, label %137

85:                                               ; preds = %11
  %86 = load ptr, ptr %10, align 8
  %87 = getelementptr inbounds nuw %struct.Product, ptr %86, i32 0, i32 5
  %88 = load i32, ptr %87, align 4
  %89 = load ptr, ptr %9, align 8
  %90 = getelementptr inbounds nuw %struct.Product, ptr %89, i32 0, i32 5
  %91 = load i32, ptr %90, align 4
  %92 = load i32, ptr %5, align 4
  %93 = xor i32 %92, -157870610
  %94 = xor i32 %91, %93
  %95 = add i32 %88, %94
  %96 = load i32, ptr %5, align 4
  %97 = xor i32 %96, 157870608
  %98 = add i32 %95, %97
  store i32 %98, ptr %6, align 4
  store i32 2121204893, ptr %5, align 4
  %99 = xor i32 %4, -1431597471
  %100 = and i32 %4, %99
  %101 = or i32 %4, %99
  %102 = xor i32 %4, %99
  %103 = mul i32 %101, 2
  %104 = sub i32 %103, %102
  %105 = sub i32 %104, %4
  %106 = sub i32 %105, %99
  %107 = mul i32 %106, 87
  %108 = icmp eq i32 %107, 0
  br i1 %108, label %137, label %252

109:                                              ; preds = %11
  %110 = load ptr, ptr %9, align 8
  %111 = getelementptr inbounds nuw %struct.Product, ptr %110, i32 0, i32 0
  %112 = load i32, ptr %111, align 8
  %113 = load ptr, ptr %10, align 8
  %114 = getelementptr inbounds nuw %struct.Product, ptr %113, i32 0, i32 0
  %115 = load i32, ptr %114, align 8
  %116 = load i32, ptr %5, align 4
  %117 = xor i32 %116, -1862362587
  %118 = add i32 %115, %117
  %119 = load i32, ptr %5, align 4
  %120 = xor i32 %119, -1862362587
  %121 = add i32 %112, %120
  %122 = mul i32 %112, %118
  %123 = mul i32 %115, %121
  %124 = sub i32 %122, %123
  store i32 %124, ptr %6, align 4
  store i32 2121204893, ptr %5, align 4
  %125 = xor i32 %4, -1574178585
  %126 = and i32 %4, %125
  %127 = or i32 %4, %125
  %128 = xor i32 %4, %125
  %129 = add i32 %4, %125
  %130 = sub i32 %129, %128
  %131 = mul i32 %126, 2
  %132 = sub i32 %130, %131
  %133 = mul i32 %132, 215
  %134 = icmp eq i32 %133, 0
  br i1 %134, label %137, label %260

135:                                              ; preds = %11
  %136 = load i32, ptr %6, align 4
  ret i32 %136

137:                                              ; preds = %321, %312, %304, %294, %287, %278, %260, %252, %242, %235, %225, %213, %200, %187, %174, %161, %148, %109, %85, %59, %36, %15
  br label %11

138:                                              ; preds = %11
  store i32 1929832896, ptr %5, align 4
  call void asm sideeffect "", ""()
  %139 = xor i32 %4, 17816283
  %140 = and i32 %4, %139
  %141 = or i32 %4, %139
  %142 = xor i32 %4, %139
  %143 = add i32 %140, %141
  %144 = sub i32 %143, %4
  %145 = sub i32 %144, %139
  %146 = mul i32 %145, 31
  %147 = icmp ugt i32 %146, 0
  br i1 %147, label %268, label %11

148:                                              ; preds = %11
  %149 = load i32, ptr %5, align 4
  %150 = xor i32 %149, -53865191
  store i32 %150, ptr %5, align 4
  %151 = xor i32 %4, -1417137683
  %152 = and i32 %4, %151
  %153 = or i32 %4, %151
  %154 = xor i32 %4, %151
  %155 = mul i32 %153, 2
  %156 = sub i32 %155, %154
  %157 = sub i32 %156, %4
  %158 = sub i32 %157, %151
  %159 = mul i32 %158, 190
  %160 = icmp uge i32 %159, 0
  br i1 %160, label %137, label %278

161:                                              ; preds = %11
  %162 = load i32, ptr %5, align 4
  %163 = xor i32 %162, -535831558
  store i32 %163, ptr %5, align 4
  %164 = xor i32 %4, 281763441
  %165 = and i32 %4, %164
  %166 = or i32 %4, %164
  %167 = xor i32 %4, %164
  %168 = mul i32 %166, 2
  %169 = sub i32 %168, %167
  %170 = sub i32 %169, %4
  %171 = sub i32 %170, %164
  %172 = mul i32 %171, 151
  %173 = icmp sle i32 %172, 0
  br i1 %173, label %137, label %287

174:                                              ; preds = %11
  %175 = load i32, ptr %5, align 4
  %176 = xor i32 %175, -558277299
  store i32 %176, ptr %5, align 4
  %177 = xor i32 %4, -1362315553
  %178 = and i32 %4, %177
  %179 = or i32 %4, %177
  %180 = xor i32 %4, %177
  %181 = add i32 %4, %177
  %182 = sub i32 %181, %180
  %183 = mul i32 %178, 2
  %184 = sub i32 %182, %183
  %185 = mul i32 %184, 97
  %186 = icmp slt i32 %185, 1
  br i1 %186, label %137, label %294

187:                                              ; preds = %11
  %188 = load i32, ptr %5, align 4
  %189 = xor i32 %188, -1059316991
  store i32 %189, ptr %5, align 4
  %190 = xor i32 %4, 1269849853
  %191 = and i32 %4, %190
  %192 = or i32 %4, %190
  %193 = xor i32 %4, %190
  %194 = add i32 %4, %190
  %195 = sub i32 %194, %193
  %196 = mul i32 %191, 2
  %197 = sub i32 %195, %196
  %198 = mul i32 %197, 249
  %199 = icmp slt i32 %198, 0
  br i1 %199, label %304, label %137

200:                                              ; preds = %11
  %201 = load i32, ptr %5, align 4
  %202 = xor i32 %201, 570992464
  store i32 %202, ptr %5, align 4
  %203 = xor i32 %4, 1722738601
  %204 = and i32 %4, %203
  %205 = or i32 %4, %203
  %206 = xor i32 %4, %203
  %207 = add i32 %4, %203
  %208 = sub i32 %207, %206
  %209 = mul i32 %204, 2
  %210 = sub i32 %208, %209
  %211 = mul i32 %210, 194
  %212 = icmp sle i32 %211, 0
  br i1 %212, label %137, label %312

213:                                              ; preds = %11
  %214 = load i32, ptr %5, align 4
  %215 = xor i32 %214, -1845830779
  store i32 %215, ptr %5, align 4
  %216 = xor i32 %4, -165357985
  %217 = and i32 %4, %216
  %218 = or i32 %4, %216
  %219 = xor i32 %4, %216
  %220 = add i32 %217, %218
  %221 = sub i32 %220, %4
  %222 = sub i32 %221, %216
  %223 = mul i32 %222, 93
  %224 = icmp sgt i32 %223, 0
  br i1 %224, label %321, label %137

225:                                              ; preds = %15
  %226 = load i64, ptr %3, align 8
  %227 = ptrtoint ptr %0 to i64
  %228 = ptrtoint ptr %1 to i64
  %229 = mul i64 %226, %227
  %230 = sub i64 %229, %228
  %231 = or i64 %230, %228
  %232 = xor i64 %231, %226
  %233 = xor i64 %232, %227
  %234 = and i64 %233, %227
  store i64 %234, ptr %3, align 8
  br label %137

235:                                              ; preds = %36
  %236 = load i64, ptr %3, align 8
  %237 = ptrtoint ptr %0 to i64
  %238 = ptrtoint ptr %1 to i64
  %239 = or i64 %236, %236
  %240 = and i64 %239, %237
  %241 = sub i64 %240, %237
  store i64 %241, ptr %3, align 8
  br label %137

242:                                              ; preds = %59
  %243 = load i64, ptr %3, align 8
  %244 = ptrtoint ptr %0 to i64
  %245 = ptrtoint ptr %1 to i64
  %246 = add i64 %243, %245
  %247 = mul i64 %246, %243
  %248 = xor i64 %247, %245
  %249 = or i64 %248, %244
  %250 = sub i64 %249, %244
  %251 = xor i64 %250, %245
  store i64 %251, ptr %3, align 8
  br label %137

252:                                              ; preds = %85
  %253 = load i64, ptr %3, align 8
  %254 = ptrtoint ptr %0 to i64
  %255 = ptrtoint ptr %1 to i64
  %256 = add i64 %255, %254
  %257 = or i64 %256, %254
  %258 = xor i64 %257, %253
  %259 = or i64 %258, %254
  store i64 %259, ptr %3, align 8
  br label %137

260:                                              ; preds = %109
  %261 = load i64, ptr %3, align 8
  %262 = ptrtoint ptr %0 to i64
  %263 = ptrtoint ptr %1 to i64
  %264 = and i64 %262, %262
  %265 = add i64 %264, %263
  %266 = and i64 %265, %262
  %267 = sub i64 %266, %263
  store i64 %267, ptr %3, align 8
  br label %137

268:                                              ; preds = %138
  %269 = load i64, ptr %3, align 8
  %270 = ptrtoint ptr %0 to i64
  %271 = ptrtoint ptr %1 to i64
  %272 = sub i64 %269, %270
  %273 = mul i64 %272, %271
  %274 = xor i64 %273, %269
  %275 = sub i64 %274, %270
  %276 = and i64 %275, %269
  %277 = and i64 %276, %269
  store i64 %277, ptr %3, align 8
  br label %11

278:                                              ; preds = %148
  %279 = load i64, ptr %3, align 8
  %280 = ptrtoint ptr %0 to i64
  %281 = ptrtoint ptr %1 to i64
  %282 = and i64 %281, %281
  %283 = and i64 %282, %281
  %284 = xor i64 %283, %279
  %285 = and i64 %284, %280
  %286 = xor i64 %285, %281
  store i64 %286, ptr %3, align 8
  br label %137

287:                                              ; preds = %161
  %288 = load i64, ptr %3, align 8
  %289 = ptrtoint ptr %0 to i64
  %290 = ptrtoint ptr %1 to i64
  %291 = and i64 %288, %289
  %292 = add i64 %291, %290
  %293 = and i64 %292, %289
  store i64 %293, ptr %3, align 8
  br label %137

294:                                              ; preds = %174
  %295 = load i64, ptr %3, align 8
  %296 = ptrtoint ptr %0 to i64
  %297 = ptrtoint ptr %1 to i64
  %298 = or i64 %297, %296
  %299 = xor i64 %298, %296
  %300 = sub i64 %299, %296
  %301 = mul i64 %300, %295
  %302 = and i64 %301, %296
  %303 = and i64 %302, %296
  store i64 %303, ptr %3, align 8
  br label %137

304:                                              ; preds = %187
  %305 = load i64, ptr %3, align 8
  %306 = ptrtoint ptr %0 to i64
  %307 = ptrtoint ptr %1 to i64
  %308 = and i64 %306, %306
  %309 = sub i64 %308, %305
  %310 = or i64 %309, %305
  %311 = add i64 %310, %306
  store i64 %311, ptr %3, align 8
  br label %137

312:                                              ; preds = %200
  %313 = load i64, ptr %3, align 8
  %314 = ptrtoint ptr %0 to i64
  %315 = ptrtoint ptr %1 to i64
  %316 = and i64 %313, %313
  %317 = xor i64 %316, %314
  %318 = and i64 %317, %315
  %319 = add i64 %318, %313
  %320 = and i64 %319, %315
  store i64 %320, ptr %3, align 8
  br label %137

321:                                              ; preds = %213
  %322 = load i64, ptr %3, align 8
  %323 = ptrtoint ptr %0 to i64
  %324 = ptrtoint ptr %1 to i64
  %325 = mul i64 %323, %324
  %326 = sub i64 %325, %323
  %327 = or i64 %326, %322
  store i64 %327, ptr %3, align 8
  br label %137
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cmpNameAsc(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = ptrtoint ptr %0 to i32
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  store i32 89737115, ptr %5, align 4
  br label %11

11:                                               ; preds = %202, %80, %79, %2
  %12 = load i32, ptr %5, align 4
  %13 = sub i32 %12, 2106737942
  %14 = mul i32 %13, 429874429
  %15 = icmp slt i32 %14, 1110460785
  br i1 %15, label %155, label %157

16:                                               ; preds = %167
  store ptr %0, ptr %7, align 8
  store ptr %1, ptr %8, align 8
  %17 = load ptr, ptr %7, align 8
  store ptr %17, ptr %9, align 8
  %18 = load ptr, ptr %8, align 8
  store ptr %18, ptr %10, align 8
  %19 = load ptr, ptr %9, align 8
  %20 = getelementptr inbounds nuw %struct.Product, ptr %19, i32 0, i32 6
  %21 = load i32, ptr %20, align 8
  %22 = load ptr, ptr %10, align 8
  %23 = getelementptr inbounds nuw %struct.Product, ptr %22, i32 0, i32 6
  %24 = load i32, ptr %23, align 8
  %25 = icmp ne i32 %21, %24
  %26 = select i1 %25, i32 2035723214, i32 -1362483075
  store i32 %26, ptr %5, align 4
  %27 = xor i32 %4, 1396981309
  %28 = and i32 %4, %27
  %29 = or i32 %4, %27
  %30 = xor i32 %4, %27
  %31 = add i32 %4, %27
  %32 = sub i32 %31, %30
  %33 = mul i32 %28, 2
  %34 = sub i32 %32, %33
  %35 = mul i32 %34, 80
  %36 = icmp slt i32 %35, 0
  br i1 %36, label %175, label %79

37:                                               ; preds = %161
  %38 = load ptr, ptr %10, align 8
  %39 = getelementptr inbounds nuw %struct.Product, ptr %38, i32 0, i32 6
  %40 = load i32, ptr %39, align 8
  %41 = load ptr, ptr %9, align 8
  %42 = getelementptr inbounds nuw %struct.Product, ptr %41, i32 0, i32 6
  %43 = load i32, ptr %42, align 8
  %44 = xor i32 %40, %43
  %45 = load i32, ptr %5, align 4
  %46 = xor i32 %45, -2035723215
  %47 = xor i32 %40, %46
  %48 = and i32 %47, %43
  %49 = add i32 %48, %48
  %50 = sub i32 %44, %49
  store i32 %50, ptr %6, align 4
  store i32 -689197711, ptr %5, align 4
  %51 = xor i32 %4, 36241599
  %52 = and i32 %4, %51
  %53 = or i32 %4, %51
  %54 = xor i32 %4, %51
  %55 = add i32 %4, %51
  %56 = sub i32 %55, %54
  %57 = mul i32 %52, 2
  %58 = sub i32 %56, %57
  %59 = mul i32 %58, 221
  %60 = icmp slt i32 %59, 0
  br i1 %60, label %183, label %79

61:                                               ; preds = %159
  %62 = load ptr, ptr %9, align 8
  %63 = getelementptr inbounds nuw %struct.Product, ptr %62, i32 0, i32 1
  %64 = getelementptr inbounds [80 x i8], ptr %63, i64 0, i64 0
  %65 = load ptr, ptr %10, align 8
  %66 = getelementptr inbounds nuw %struct.Product, ptr %65, i32 0, i32 1
  %67 = getelementptr inbounds [80 x i8], ptr %66, i64 0, i64 0
  %68 = call i32 @strcmp(ptr noundef %64, ptr noundef %67) #8
  store i32 %68, ptr %6, align 4
  store i32 -689197711, ptr %5, align 4
  %69 = xor i32 %4, 504846887
  %70 = and i32 %4, %69
  %71 = or i32 %4, %69
  %72 = xor i32 %4, %69
  %73 = sub i32 %71, %72
  %74 = sub i32 %73, %70
  %75 = mul i32 %74, 45
  %76 = icmp sgt i32 %75, 0
  br i1 %76, label %193, label %79

77:                                               ; preds = %163
  %78 = load i32, ptr %6, align 4
  ret i32 %78

79:                                               ; preds = %234, %225, %217, %210, %193, %183, %175, %142, %131, %111, %91, %61, %37, %16
  br label %11

80:                                               ; preds = %173, %171, %165, %163
  store i32 89737115, ptr %5, align 4
  call void asm sideeffect "", ""()
  %81 = xor i32 %4, 567027539
  %82 = and i32 %4, %81
  %83 = or i32 %4, %81
  %84 = xor i32 %4, %81
  %85 = mul i32 %83, 2
  %86 = sub i32 %85, %84
  %87 = sub i32 %86, %4
  %88 = sub i32 %87, %81
  %89 = mul i32 %88, 227
  %90 = icmp slt i32 %89, 1
  br i1 %90, label %11, label %202

91:                                               ; preds = %173
  %92 = load i32, ptr %5, align 4
  %93 = xor i32 %92, -204791084
  store i32 %93, ptr %5, align 4
  %94 = xor i32 %4, 920543745
  %95 = and i32 %4, %94
  %96 = or i32 %4, %94
  %97 = xor i32 %4, %94
  %98 = add i32 %95, %96
  %99 = sub i32 %98, %4
  %100 = sub i32 %99, %94
  %101 = mul i32 %100, 94
  %102 = xor i32 %4, -1340691389
  %103 = and i32 %4, %102
  %104 = or i32 %4, %102
  %105 = xor i32 %4, %102
  %106 = add i32 %103, %104
  %107 = sub i32 %106, %4
  %108 = sub i32 %107, %102
  %109 = mul i32 %108, 6
  %110 = icmp eq i32 %101, %109
  br i1 %110, label %79, label %210

111:                                              ; preds = %165
  %112 = load i32, ptr %5, align 4
  %113 = xor i32 %112, 444090042
  store i32 %113, ptr %5, align 4
  %114 = xor i32 %4, 914132279
  %115 = and i32 %4, %114
  %116 = or i32 %4, %114
  %117 = xor i32 %4, %114
  %118 = sub i32 %116, %117
  %119 = sub i32 %118, %115
  %120 = mul i32 %119, 205
  %121 = xor i32 %4, 544777813
  %122 = and i32 %4, %121
  %123 = or i32 %4, %121
  %124 = xor i32 %4, %121
  %125 = add i32 %4, %121
  %126 = sub i32 %125, %124
  %127 = mul i32 %122, 2
  %128 = sub i32 %126, %127
  %129 = mul i32 %128, 93
  %130 = icmp eq i32 %120, %129
  br i1 %130, label %79, label %217

131:                                              ; preds = %171
  %132 = load i32, ptr %5, align 4
  %133 = xor i32 %132, 1265375418
  store i32 %133, ptr %5, align 4
  %134 = xor i32 %4, -248455085
  %135 = and i32 %4, %134
  %136 = or i32 %4, %134
  %137 = xor i32 %4, %134
  %138 = sub i32 %136, %137
  %139 = sub i32 %138, %135
  %140 = mul i32 %139, 25
  %141 = icmp eq i32 %140, 0
  br i1 %141, label %79, label %225

142:                                              ; preds = %169
  %143 = load i32, ptr %5, align 4
  %144 = xor i32 %143, -1447555562
  store i32 %144, ptr %5, align 4
  %145 = xor i32 %4, -983354035
  %146 = and i32 %4, %145
  %147 = or i32 %4, %145
  %148 = xor i32 %4, %145
  %149 = add i32 %4, %145
  %150 = sub i32 %149, %148
  %151 = mul i32 %146, 2
  %152 = sub i32 %150, %151
  %153 = mul i32 %152, 106
  %154 = icmp eq i32 %153, 0
  br i1 %154, label %79, label %234

155:                                              ; preds = %11
  %156 = icmp slt i32 %14, 709600216
  br i1 %156, label %159, label %161

157:                                              ; preds = %11
  %158 = icmp slt i32 %14, 1479920061
  br i1 %158, label %167, label %169

159:                                              ; preds = %155
  %160 = icmp eq i32 %14, 99467467
  br i1 %160, label %61, label %163

161:                                              ; preds = %155
  %162 = icmp eq i32 %14, 709600216
  br i1 %162, label %37, label %165

163:                                              ; preds = %159
  %164 = icmp eq i32 %14, 576837103
  br i1 %164, label %77, label %80

165:                                              ; preds = %161
  %166 = icmp eq i32 %14, 903285995
  br i1 %166, label %111, label %80

167:                                              ; preds = %157
  %168 = icmp eq i32 %14, 1110460785
  br i1 %168, label %16, label %171

169:                                              ; preds = %157
  %170 = icmp eq i32 %14, 1479920061
  br i1 %170, label %142, label %173

171:                                              ; preds = %167
  %172 = icmp eq i32 %14, 1298984264
  br i1 %172, label %131, label %80

173:                                              ; preds = %169
  %174 = icmp eq i32 %14, 1663118603
  br i1 %174, label %91, label %80

175:                                              ; preds = %16
  %176 = load i64, ptr %3, align 8
  %177 = ptrtoint ptr %0 to i64
  %178 = ptrtoint ptr %1 to i64
  %179 = add i64 %176, %178
  %180 = and i64 %179, %176
  %181 = mul i64 %180, %177
  %182 = add i64 %181, %178
  store i64 %182, ptr %3, align 8
  br label %79

183:                                              ; preds = %37
  %184 = load i64, ptr %3, align 8
  %185 = ptrtoint ptr %0 to i64
  %186 = ptrtoint ptr %1 to i64
  %187 = mul i64 %185, %184
  %188 = sub i64 %187, %184
  %189 = sub i64 %188, %186
  %190 = sub i64 %189, %186
  %191 = sub i64 %190, %184
  %192 = sub i64 %191, %186
  store i64 %192, ptr %3, align 8
  br label %79

193:                                              ; preds = %61
  %194 = load i64, ptr %3, align 8
  %195 = ptrtoint ptr %0 to i64
  %196 = ptrtoint ptr %1 to i64
  %197 = add i64 %196, %196
  %198 = mul i64 %197, %196
  %199 = xor i64 %198, %194
  %200 = mul i64 %199, %196
  %201 = or i64 %200, %194
  store i64 %201, ptr %3, align 8
  br label %79

202:                                              ; preds = %80
  %203 = load i64, ptr %3, align 8
  %204 = ptrtoint ptr %0 to i64
  %205 = ptrtoint ptr %1 to i64
  %206 = sub i64 %204, %205
  %207 = or i64 %206, %203
  %208 = xor i64 %207, %204
  %209 = add i64 %208, %203
  store i64 %209, ptr %3, align 8
  br label %11

210:                                              ; preds = %91
  %211 = load i64, ptr %3, align 8
  %212 = ptrtoint ptr %0 to i64
  %213 = ptrtoint ptr %1 to i64
  %214 = sub i64 %213, %211
  %215 = sub i64 %214, %211
  %216 = or i64 %215, %213
  store i64 %216, ptr %3, align 8
  br label %79

217:                                              ; preds = %111
  %218 = load i64, ptr %3, align 8
  %219 = ptrtoint ptr %0 to i64
  %220 = ptrtoint ptr %1 to i64
  %221 = mul i64 %219, %218
  %222 = mul i64 %221, %219
  %223 = or i64 %222, %218
  %224 = and i64 %223, %219
  store i64 %224, ptr %3, align 8
  br label %79

225:                                              ; preds = %131
  %226 = load i64, ptr %3, align 8
  %227 = ptrtoint ptr %0 to i64
  %228 = ptrtoint ptr %1 to i64
  %229 = and i64 %227, %227
  %230 = mul i64 %229, %228
  %231 = and i64 %230, %228
  %232 = mul i64 %231, %228
  %233 = sub i64 %232, %228
  store i64 %233, ptr %3, align 8
  br label %79

234:                                              ; preds = %142
  %235 = load i64, ptr %3, align 8
  %236 = ptrtoint ptr %0 to i64
  %237 = ptrtoint ptr %1 to i64
  %238 = sub i64 %235, %237
  %239 = xor i64 %238, %237
  %240 = xor i64 %239, %237
  %241 = sub i64 %240, %236
  %242 = xor i64 %241, %236
  store i64 %242, ptr %3, align 8
  br label %79
}

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSort(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca [64 x i8], align 16
  store i32 -1642324998, ptr %4, align 4
  br label %8

8:                                                ; preds = %522, %237, %236, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -342933216
  %11 = mul i32 %10, 1894598727
  switch i32 %11, label %237 [
    i32 510657142, label %12
    i32 1088421156, label %24
    i32 1305021671, label %36
    i32 1861426076, label %56
    i32 74112231, label %69
    i32 2027031485, label %84
    i32 1737943849, label %95
    i32 1186823058, label %108
    i32 40538692, label %119
    i32 977596324, label %134
    i32 444682864, label %147
    i32 1513553619, label %162
    i32 1225978987, label %175
    i32 1908422543, label %189
    i32 368325306, label %205
    i32 503407628, label %214
    i32 1999522605, label %224
    i32 444953983, label %235
    i32 300014359, label %257
    i32 889138503, label %279
    i32 1028155978, label %292
    i32 2023418862, label %304
    i32 277556528, label %317
    i32 1244597242, label %328
    i32 675310090, label %340
    i32 929278602, label %353
  ]

12:                                               ; preds = %8
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %13 = load i32, ptr %6, align 4
  %14 = icmp ne i32 %13, 2
  %15 = select i1 %14, i32 -516517668, i32 -1134016639
  store i32 %15, ptr %4, align 4
  %16 = xor i32 %1, -721171463
  %17 = and i32 %1, %16
  %18 = or i32 %1, %16
  %19 = xor i32 %1, %16
  %20 = sub i32 %18, %19
  %21 = sub i32 %20, %17
  %22 = mul i32 %21, 225
  %23 = icmp slt i32 %22, 1
  br i1 %23, label %236, label %373

24:                                               ; preds = %8
  %25 = call i32 (ptr, ...) @printf(ptr noundef @.str.35)
  store i32 -479035863, ptr %4, align 4
  %26 = xor i32 %1, -43801379
  %27 = and i32 %1, %26
  %28 = or i32 %1, %26
  %29 = xor i32 %1, %26
  %30 = add i32 %1, %26
  %31 = sub i32 %30, %29
  %32 = mul i32 %27, 2
  %33 = sub i32 %31, %32
  %34 = mul i32 %33, 151
  %35 = icmp uge i32 %34, 0
  br i1 %35, label %236, label %382

36:                                               ; preds = %8
  %37 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %38 = load ptr, ptr %5, align 8
  %39 = getelementptr inbounds ptr, ptr %38, i64 1
  %40 = load ptr, ptr %39, align 8
  %41 = call ptr @strcpy(ptr noundef %37, ptr noundef %40) #9
  %42 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  call void @upperString(ptr noundef %42)
  %43 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %44 = call i32 @equalsIgnoreCase(ptr noundef %43, ptr noundef @.str.36)
  %45 = icmp ne i32 %44, 0
  %46 = select i1 %45, i32 -234278236, i32 -915409023
  store i32 %46, ptr %4, align 4
  %47 = xor i32 %1, 1305081891
  %48 = and i32 %1, %47
  %49 = or i32 %1, %47
  %50 = xor i32 %1, %47
  %51 = add i32 %48, %49
  %52 = sub i32 %51, %1
  %53 = sub i32 %52, %47
  %54 = mul i32 %53, 248
  %55 = icmp sle i32 %54, 0
  br i1 %55, label %236, label %392

56:                                               ; preds = %8
  %57 = load i32, ptr @productCount, align 4
  %58 = sext i32 %57 to i64
  call void @qsort(ptr noundef @products, i64 noundef %58, i64 noundef 160, ptr noundef @cmpPriceAsc)
  store i32 947240971, ptr %4, align 4
  %59 = xor i32 %1, -93575769
  %60 = and i32 %1, %59
  %61 = or i32 %1, %59
  %62 = xor i32 %1, %59
  %63 = add i32 %1, %59
  %64 = sub i32 %63, %62
  %65 = mul i32 %60, 2
  %66 = sub i32 %64, %65
  %67 = mul i32 %66, 24
  %68 = icmp sle i32 %67, 0
  br i1 %68, label %236, label %400

69:                                               ; preds = %8
  %70 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %71 = call i32 @equalsIgnoreCase(ptr noundef %70, ptr noundef @.str.37)
  %72 = icmp ne i32 %71, 0
  %73 = select i1 %72, i32 -335359237, i32 -1173841361
  store i32 %73, ptr %4, align 4
  %74 = xor i32 %1, -951288495
  %75 = and i32 %1, %74
  %76 = or i32 %1, %74
  %77 = xor i32 %1, %74
  %78 = add i32 %1, %74
  %79 = sub i32 %78, %77
  %80 = mul i32 %75, 2
  %81 = sub i32 %79, %80
  %82 = mul i32 %81, 81
  %83 = icmp sgt i32 %82, 0
  br i1 %83, label %409, label %236

84:                                               ; preds = %8
  %85 = load i32, ptr @productCount, align 4
  %86 = sext i32 %85 to i64
  call void @qsort(ptr noundef @products, i64 noundef %86, i64 noundef 160, ptr noundef @cmpPriceDesc)
  store i32 505892532, ptr %4, align 4
  %87 = xor i32 %1, -1760803939
  %88 = and i32 %1, %87
  %89 = or i32 %1, %87
  %90 = xor i32 %1, %87
  %91 = sub i32 %89, %90
  %92 = sub i32 %91, %88
  %93 = mul i32 %92, 124
  %94 = icmp ugt i32 %93, 0
  br i1 %94, label %418, label %236

95:                                               ; preds = %8
  %96 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %97 = call i32 @equalsIgnoreCase(ptr noundef %96, ptr noundef @.str.38)
  %98 = icmp ne i32 %97, 0
  %99 = select i1 %98, i32 239404030, i32 169018044
  store i32 %99, ptr %4, align 4
  %100 = xor i32 %1, 422047335
  %101 = and i32 %1, %100
  %102 = or i32 %1, %100
  %103 = xor i32 %1, %100
  %104 = sub i32 %102, %103
  %105 = sub i32 %104, %101
  %106 = mul i32 %105, 234
  %107 = icmp ne i32 %106, 0
  br i1 %107, label %426, label %236

108:                                              ; preds = %8
  %109 = load i32, ptr @productCount, align 4
  %110 = sext i32 %109 to i64
  call void @qsort(ptr noundef @products, i64 noundef %110, i64 noundef 160, ptr noundef @cmpStockAsc)
  store i32 963006358, ptr %4, align 4
  %111 = xor i32 %1, 1187039957
  %112 = and i32 %1, %111
  %113 = or i32 %1, %111
  %114 = xor i32 %1, %111
  %115 = sub i32 %113, %114
  %116 = sub i32 %115, %112
  %117 = mul i32 %116, 132
  %118 = icmp uge i32 %117, 0
  br i1 %118, label %236, label %436

119:                                              ; preds = %8
  %120 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %121 = call i32 @equalsIgnoreCase(ptr noundef %120, ptr noundef @.str.39)
  %122 = icmp ne i32 %121, 0
  %123 = select i1 %122, i32 600164956, i32 1408303920
  store i32 %123, ptr %4, align 4
  %124 = xor i32 %1, -1024096617
  %125 = and i32 %1, %124
  %126 = or i32 %1, %124
  %127 = xor i32 %1, %124
  %128 = add i32 %1, %124
  %129 = sub i32 %128, %127
  %130 = mul i32 %125, 2
  %131 = sub i32 %129, %130
  %132 = mul i32 %131, 19
  %133 = icmp slt i32 %132, 0
  br i1 %133, label %446, label %236

134:                                              ; preds = %8
  %135 = load i32, ptr @productCount, align 4
  %136 = sext i32 %135 to i64
  call void @qsort(ptr noundef @products, i64 noundef %136, i64 noundef 160, ptr noundef @cmpSoldDesc)
  store i32 2030224281, ptr %4, align 4
  %137 = xor i32 %1, -10960735
  %138 = and i32 %1, %137
  %139 = or i32 %1, %137
  %140 = xor i32 %1, %137
  %141 = add i32 %1, %137
  %142 = sub i32 %141, %140
  %143 = mul i32 %138, 2
  %144 = sub i32 %142, %143
  %145 = mul i32 %144, 189
  %146 = icmp eq i32 %145, 0
  br i1 %146, label %236, label %453

147:                                              ; preds = %8
  %148 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %149 = call i32 @equalsIgnoreCase(ptr noundef %148, ptr noundef @.str.40)
  %150 = icmp ne i32 %149, 0
  %151 = select i1 %150, i32 -389535691, i32 376039901
  store i32 %151, ptr %4, align 4
  %152 = xor i32 %1, 298969487
  %153 = and i32 %1, %152
  %154 = or i32 %1, %152
  %155 = xor i32 %1, %152
  %156 = add i32 %1, %152
  %157 = sub i32 %156, %155
  %158 = mul i32 %153, 2
  %159 = sub i32 %157, %158
  %160 = mul i32 %159, 99
  %161 = icmp uge i32 %160, 0
  br i1 %161, label %236, label %460

162:                                              ; preds = %8
  %163 = load i32, ptr @productCount, align 4
  %164 = sext i32 %163 to i64
  call void @qsort(ptr noundef @products, i64 noundef %164, i64 noundef 160, ptr noundef @cmpNameAsc)
  store i32 2030224281, ptr %4, align 4
  %165 = xor i32 %1, -116974985
  %166 = and i32 %1, %165
  %167 = or i32 %1, %165
  %168 = xor i32 %1, %165
  %169 = mul i32 %167, 2
  %170 = sub i32 %169, %168
  %171 = sub i32 %170, %1
  %172 = sub i32 %171, %165
  %173 = mul i32 %172, 72
  %174 = icmp ne i32 %173, 0
  br i1 %174, label %470, label %236

175:                                              ; preds = %8
  %176 = load ptr, ptr %5, align 8
  %177 = getelementptr inbounds ptr, ptr %176, i64 1
  %178 = load ptr, ptr %177, align 8
  %179 = call i32 (ptr, ...) @printf(ptr noundef @.str.41, ptr noundef %178)
  store i32 -479035863, ptr %4, align 4
  %180 = xor i32 %1, -1866803543
  %181 = and i32 %1, %180
  %182 = or i32 %1, %180
  %183 = xor i32 %1, %180
  %184 = add i32 %181, %182
  %185 = sub i32 %184, %1
  %186 = sub i32 %185, %180
  %187 = mul i32 %186, 50
  %188 = icmp slt i32 %187, 1
  br i1 %188, label %236, label %477

189:                                              ; preds = %8
  store i32 963006358, ptr %4, align 4
  %190 = xor i32 %1, -1999845041
  %191 = and i32 %1, %190
  %192 = or i32 %1, %190
  %193 = xor i32 %1, %190
  %194 = sub i32 %192, %193
  %195 = sub i32 %194, %191
  %196 = mul i32 %195, 61
  %197 = xor i32 %1, 1046952199
  %198 = and i32 %1, %197
  %199 = or i32 %1, %197
  %200 = xor i32 %1, %197
  %201 = sub i32 %199, %200
  %202 = sub i32 %201, %198
  %203 = mul i32 %202, 238
  %204 = icmp ne i32 %196, %203
  br i1 %204, label %486, label %236

205:                                              ; preds = %8
  store i32 505892532, ptr %4, align 4
  %206 = xor i32 %1, -1681255165
  %207 = and i32 %1, %206
  %208 = or i32 %1, %206
  %209 = xor i32 %1, %206
  %210 = sub i32 %208, %209
  %211 = sub i32 %210, %207
  %212 = mul i32 %211, 247
  %213 = icmp eq i32 %212, 0
  br i1 %213, label %236, label %496

214:                                              ; preds = %8
  store i32 947240971, ptr %4, align 4
  %215 = xor i32 %1, 1908315235
  %216 = and i32 %1, %215
  %217 = or i32 %1, %215
  %218 = xor i32 %1, %215
  %219 = add i32 %216, %217
  %220 = sub i32 %219, %1
  %221 = sub i32 %220, %215
  %222 = mul i32 %221, 117
  %223 = icmp ne i32 %222, 0
  br i1 %223, label %505, label %236

224:                                              ; preds = %8
  %225 = getelementptr inbounds [64 x i8], ptr %7, i64 0, i64 0
  %226 = call i32 (ptr, ...) @printf(ptr noundef @.str.42, ptr noundef %225)
  call void @cmdList()
  store i32 -479035863, ptr %4, align 4
  %227 = xor i32 %1, 1425591983
  %228 = and i32 %1, %227
  %229 = or i32 %1, %227
  %230 = xor i32 %1, %227
  %231 = sub i32 %229, %230
  %232 = sub i32 %231, %228
  %233 = mul i32 %232, 91
  %234 = icmp slt i32 %233, 1
  br i1 %234, label %236, label %514

235:                                              ; preds = %8
  ret void

236:                                              ; preds = %590, %580, %571, %561, %553, %546, %539, %529, %514, %505, %496, %486, %477, %470, %460, %453, %446, %436, %426, %418, %409, %400, %392, %382, %373, %353, %340, %328, %317, %304, %292, %279, %257, %224, %214, %205, %189, %175, %162, %147, %134, %119, %108, %95, %84, %69, %56, %36, %24, %12
  br label %8

237:                                              ; preds = %8
  store i32 -1642324998, ptr %4, align 4
  call void asm sideeffect "", ""()
  %238 = xor i32 %1, -1498632877
  %239 = and i32 %1, %238
  %240 = or i32 %1, %238
  %241 = xor i32 %1, %238
  %242 = mul i32 %240, 2
  %243 = sub i32 %242, %241
  %244 = sub i32 %243, %1
  %245 = sub i32 %244, %238
  %246 = mul i32 %245, 140
  %247 = xor i32 %1, 645086317
  %248 = and i32 %1, %247
  %249 = or i32 %1, %247
  %250 = xor i32 %1, %247
  %251 = mul i32 %249, 2
  %252 = sub i32 %251, %250
  %253 = sub i32 %252, %1
  %254 = sub i32 %253, %247
  %255 = mul i32 %254, 251
  %256 = icmp ne i32 %246, %255
  br i1 %256, label %522, label %8

257:                                              ; preds = %8
  %258 = load i32, ptr %4, align 4
  %259 = xor i32 %258, 1733504938
  store i32 %259, ptr %4, align 4
  %260 = xor i32 %1, 2016367429
  %261 = and i32 %1, %260
  %262 = or i32 %1, %260
  %263 = xor i32 %1, %260
  %264 = mul i32 %262, 2
  %265 = sub i32 %264, %263
  %266 = sub i32 %265, %1
  %267 = sub i32 %266, %260
  %268 = mul i32 %267, 219
  %269 = xor i32 %1, -1734887887
  %270 = and i32 %1, %269
  %271 = or i32 %1, %269
  %272 = xor i32 %1, %269
  %273 = add i32 %1, %269
  %274 = sub i32 %273, %272
  %275 = mul i32 %270, 2
  %276 = sub i32 %274, %275
  %277 = mul i32 %276, 151
  %278 = icmp ne i32 %268, %277
  br i1 %278, label %529, label %236

279:                                              ; preds = %8
  %280 = load i32, ptr %4, align 4
  %281 = xor i32 %280, -1334526139
  store i32 %281, ptr %4, align 4
  %282 = xor i32 %1, -1122677939
  %283 = and i32 %1, %282
  %284 = or i32 %1, %282
  %285 = xor i32 %1, %282
  %286 = mul i32 %284, 2
  %287 = sub i32 %286, %285
  %288 = sub i32 %287, %1
  %289 = sub i32 %288, %282
  %290 = mul i32 %289, 120
  %291 = icmp sgt i32 %290, 0
  br i1 %291, label %539, label %236

292:                                              ; preds = %8
  %293 = load i32, ptr %4, align 4
  %294 = xor i32 %293, 1758239182
  store i32 %294, ptr %4, align 4
  %295 = xor i32 %1, -438279811
  %296 = and i32 %1, %295
  %297 = or i32 %1, %295
  %298 = xor i32 %1, %295
  %299 = add i32 %296, %297
  %300 = sub i32 %299, %1
  %301 = sub i32 %300, %295
  %302 = mul i32 %301, 35
  %303 = icmp ne i32 %302, 0
  br i1 %303, label %546, label %236

304:                                              ; preds = %8
  %305 = load i32, ptr %4, align 4
  %306 = xor i32 %305, -1798550954
  store i32 %306, ptr %4, align 4
  %307 = xor i32 %1, -1474725615
  %308 = and i32 %1, %307
  %309 = or i32 %1, %307
  %310 = xor i32 %1, %307
  %311 = add i32 %1, %307
  %312 = sub i32 %311, %310
  %313 = mul i32 %308, 2
  %314 = sub i32 %312, %313
  %315 = mul i32 %314, 20
  %316 = icmp ne i32 %315, 0
  br i1 %316, label %553, label %236

317:                                              ; preds = %8
  %318 = load i32, ptr %4, align 4
  %319 = xor i32 %318, 1246107549
  store i32 %319, ptr %4, align 4
  %320 = xor i32 %1, -594885261
  %321 = and i32 %1, %320
  %322 = or i32 %1, %320
  %323 = xor i32 %1, %320
  %324 = sub i32 %322, %323
  %325 = sub i32 %324, %321
  %326 = mul i32 %325, 222
  %327 = icmp eq i32 %326, 0
  br i1 %327, label %236, label %561

328:                                              ; preds = %8
  %329 = load i32, ptr %4, align 4
  %330 = xor i32 %329, 1838429737
  store i32 %330, ptr %4, align 4
  %331 = xor i32 %1, -409890419
  %332 = and i32 %1, %331
  %333 = or i32 %1, %331
  %334 = xor i32 %1, %331
  %335 = add i32 %332, %333
  %336 = sub i32 %335, %1
  %337 = sub i32 %336, %331
  %338 = mul i32 %337, 131
  %339 = icmp sle i32 %338, 0
  br i1 %339, label %236, label %571

340:                                              ; preds = %8
  %341 = load i32, ptr %4, align 4
  %342 = xor i32 %341, 1645717570
  store i32 %342, ptr %4, align 4
  %343 = xor i32 %1, 1631775017
  %344 = and i32 %1, %343
  %345 = or i32 %1, %343
  %346 = xor i32 %1, %343
  %347 = add i32 %1, %343
  %348 = sub i32 %347, %346
  %349 = mul i32 %344, 2
  %350 = sub i32 %348, %349
  %351 = mul i32 %350, 56
  %352 = icmp sgt i32 %351, 0
  br i1 %352, label %580, label %236

353:                                              ; preds = %8
  %354 = load i32, ptr %4, align 4
  %355 = xor i32 %354, -1061979680
  store i32 %355, ptr %4, align 4
  %356 = xor i32 %1, -506425257
  %357 = and i32 %1, %356
  %358 = or i32 %1, %356
  %359 = xor i32 %1, %356
  %360 = add i32 %357, %358
  %361 = sub i32 %360, %1
  %362 = sub i32 %361, %356
  %363 = mul i32 %362, 55
  %364 = xor i32 %1, 1342157609
  %365 = and i32 %1, %364
  %366 = or i32 %1, %364
  %367 = xor i32 %1, %364
  %368 = add i32 %365, %366
  %369 = sub i32 %368, %1
  %370 = sub i32 %369, %364
  %371 = mul i32 %370, 46
  %372 = icmp ne i32 %363, %371
  br i1 %372, label %590, label %236

373:                                              ; preds = %12
  %374 = load i64, ptr %3, align 8
  %375 = ptrtoint ptr %0 to i64
  %376 = zext i32 %1 to i64
  %377 = add i64 %375, %376
  %378 = mul i64 %377, %375
  %379 = xor i64 %378, %374
  %380 = and i64 %379, %376
  %381 = xor i64 %380, %376
  store i64 %381, ptr %3, align 8
  br label %236

382:                                              ; preds = %24
  %383 = load i64, ptr %3, align 8
  %384 = ptrtoint ptr %0 to i64
  %385 = zext i32 %1 to i64
  %386 = and i64 %385, %384
  %387 = mul i64 %386, %383
  %388 = and i64 %387, %385
  %389 = add i64 %388, %385
  %390 = sub i64 %389, %384
  %391 = or i64 %390, %383
  store i64 %391, ptr %3, align 8
  br label %236

392:                                              ; preds = %36
  %393 = load i64, ptr %3, align 8
  %394 = ptrtoint ptr %0 to i64
  %395 = zext i32 %1 to i64
  %396 = or i64 %394, %394
  %397 = sub i64 %396, %393
  %398 = xor i64 %397, %393
  %399 = mul i64 %398, %395
  store i64 %399, ptr %3, align 8
  br label %236

400:                                              ; preds = %56
  %401 = load i64, ptr %3, align 8
  %402 = ptrtoint ptr %0 to i64
  %403 = zext i32 %1 to i64
  %404 = and i64 %402, %401
  %405 = sub i64 %404, %403
  %406 = xor i64 %405, %402
  %407 = sub i64 %406, %402
  %408 = and i64 %407, %401
  store i64 %408, ptr %3, align 8
  br label %236

409:                                              ; preds = %69
  %410 = load i64, ptr %3, align 8
  %411 = ptrtoint ptr %0 to i64
  %412 = zext i32 %1 to i64
  %413 = add i64 %412, %411
  %414 = sub i64 %413, %410
  %415 = and i64 %414, %410
  %416 = sub i64 %415, %412
  %417 = add i64 %416, %412
  store i64 %417, ptr %3, align 8
  br label %236

418:                                              ; preds = %84
  %419 = load i64, ptr %3, align 8
  %420 = ptrtoint ptr %0 to i64
  %421 = zext i32 %1 to i64
  %422 = add i64 %420, %419
  %423 = sub i64 %422, %419
  %424 = or i64 %423, %419
  %425 = and i64 %424, %419
  store i64 %425, ptr %3, align 8
  br label %236

426:                                              ; preds = %95
  %427 = load i64, ptr %3, align 8
  %428 = ptrtoint ptr %0 to i64
  %429 = zext i32 %1 to i64
  %430 = or i64 %428, %428
  %431 = sub i64 %430, %428
  %432 = and i64 %431, %428
  %433 = mul i64 %432, %429
  %434 = or i64 %433, %428
  %435 = xor i64 %434, %428
  store i64 %435, ptr %3, align 8
  br label %236

436:                                              ; preds = %108
  %437 = load i64, ptr %3, align 8
  %438 = ptrtoint ptr %0 to i64
  %439 = zext i32 %1 to i64
  %440 = sub i64 %437, %439
  %441 = sub i64 %440, %437
  %442 = xor i64 %441, %438
  %443 = mul i64 %442, %439
  %444 = or i64 %443, %438
  %445 = xor i64 %444, %439
  store i64 %445, ptr %3, align 8
  br label %236

446:                                              ; preds = %119
  %447 = load i64, ptr %3, align 8
  %448 = ptrtoint ptr %0 to i64
  %449 = zext i32 %1 to i64
  %450 = sub i64 %448, %449
  %451 = add i64 %450, %447
  %452 = add i64 %451, %449
  store i64 %452, ptr %3, align 8
  br label %236

453:                                              ; preds = %134
  %454 = load i64, ptr %3, align 8
  %455 = ptrtoint ptr %0 to i64
  %456 = zext i32 %1 to i64
  %457 = add i64 %454, %456
  %458 = mul i64 %457, %456
  %459 = and i64 %458, %455
  store i64 %459, ptr %3, align 8
  br label %236

460:                                              ; preds = %147
  %461 = load i64, ptr %3, align 8
  %462 = ptrtoint ptr %0 to i64
  %463 = zext i32 %1 to i64
  %464 = mul i64 %463, %463
  %465 = and i64 %464, %463
  %466 = sub i64 %465, %463
  %467 = sub i64 %466, %462
  %468 = or i64 %467, %462
  %469 = sub i64 %468, %463
  store i64 %469, ptr %3, align 8
  br label %236

470:                                              ; preds = %162
  %471 = load i64, ptr %3, align 8
  %472 = ptrtoint ptr %0 to i64
  %473 = zext i32 %1 to i64
  %474 = xor i64 %471, %473
  %475 = and i64 %474, %471
  %476 = xor i64 %475, %473
  store i64 %476, ptr %3, align 8
  br label %236

477:                                              ; preds = %175
  %478 = load i64, ptr %3, align 8
  %479 = ptrtoint ptr %0 to i64
  %480 = zext i32 %1 to i64
  %481 = and i64 %478, %480
  %482 = and i64 %481, %480
  %483 = xor i64 %482, %478
  %484 = or i64 %483, %479
  %485 = and i64 %484, %480
  store i64 %485, ptr %3, align 8
  br label %236

486:                                              ; preds = %189
  %487 = load i64, ptr %3, align 8
  %488 = ptrtoint ptr %0 to i64
  %489 = zext i32 %1 to i64
  %490 = xor i64 %487, %489
  %491 = xor i64 %490, %488
  %492 = sub i64 %491, %489
  %493 = xor i64 %492, %489
  %494 = mul i64 %493, %489
  %495 = mul i64 %494, %487
  store i64 %495, ptr %3, align 8
  br label %236

496:                                              ; preds = %205
  %497 = load i64, ptr %3, align 8
  %498 = ptrtoint ptr %0 to i64
  %499 = zext i32 %1 to i64
  %500 = or i64 %499, %497
  %501 = sub i64 %500, %499
  %502 = and i64 %501, %497
  %503 = add i64 %502, %498
  %504 = or i64 %503, %498
  store i64 %504, ptr %3, align 8
  br label %236

505:                                              ; preds = %214
  %506 = load i64, ptr %3, align 8
  %507 = ptrtoint ptr %0 to i64
  %508 = zext i32 %1 to i64
  %509 = add i64 %506, %508
  %510 = add i64 %509, %507
  %511 = add i64 %510, %506
  %512 = add i64 %511, %508
  %513 = xor i64 %512, %507
  store i64 %513, ptr %3, align 8
  br label %236

514:                                              ; preds = %224
  %515 = load i64, ptr %3, align 8
  %516 = ptrtoint ptr %0 to i64
  %517 = zext i32 %1 to i64
  %518 = and i64 %517, %517
  %519 = add i64 %518, %516
  %520 = and i64 %519, %515
  %521 = and i64 %520, %517
  store i64 %521, ptr %3, align 8
  br label %236

522:                                              ; preds = %237
  %523 = load i64, ptr %3, align 8
  %524 = ptrtoint ptr %0 to i64
  %525 = zext i32 %1 to i64
  %526 = xor i64 %525, %525
  %527 = xor i64 %526, %525
  %528 = or i64 %527, %524
  store i64 %528, ptr %3, align 8
  br label %8

529:                                              ; preds = %257
  %530 = load i64, ptr %3, align 8
  %531 = ptrtoint ptr %0 to i64
  %532 = zext i32 %1 to i64
  %533 = sub i64 %532, %532
  %534 = xor i64 %533, %530
  %535 = sub i64 %534, %530
  %536 = or i64 %535, %531
  %537 = add i64 %536, %530
  %538 = xor i64 %537, %530
  store i64 %538, ptr %3, align 8
  br label %236

539:                                              ; preds = %279
  %540 = load i64, ptr %3, align 8
  %541 = ptrtoint ptr %0 to i64
  %542 = zext i32 %1 to i64
  %543 = sub i64 %542, %542
  %544 = mul i64 %543, %540
  %545 = add i64 %544, %542
  store i64 %545, ptr %3, align 8
  br label %236

546:                                              ; preds = %292
  %547 = load i64, ptr %3, align 8
  %548 = ptrtoint ptr %0 to i64
  %549 = zext i32 %1 to i64
  %550 = mul i64 %547, %549
  %551 = mul i64 %550, %547
  %552 = and i64 %551, %547
  store i64 %552, ptr %3, align 8
  br label %236

553:                                              ; preds = %304
  %554 = load i64, ptr %3, align 8
  %555 = ptrtoint ptr %0 to i64
  %556 = zext i32 %1 to i64
  %557 = add i64 %554, %555
  %558 = xor i64 %557, %554
  %559 = add i64 %558, %555
  %560 = add i64 %559, %555
  store i64 %560, ptr %3, align 8
  br label %236

561:                                              ; preds = %317
  %562 = load i64, ptr %3, align 8
  %563 = ptrtoint ptr %0 to i64
  %564 = zext i32 %1 to i64
  %565 = and i64 %563, %564
  %566 = xor i64 %565, %564
  %567 = add i64 %566, %562
  %568 = or i64 %567, %564
  %569 = add i64 %568, %562
  %570 = or i64 %569, %564
  store i64 %570, ptr %3, align 8
  br label %236

571:                                              ; preds = %328
  %572 = load i64, ptr %3, align 8
  %573 = ptrtoint ptr %0 to i64
  %574 = zext i32 %1 to i64
  %575 = xor i64 %572, %574
  %576 = add i64 %575, %574
  %577 = xor i64 %576, %572
  %578 = and i64 %577, %572
  %579 = xor i64 %578, %574
  store i64 %579, ptr %3, align 8
  br label %236

580:                                              ; preds = %340
  %581 = load i64, ptr %3, align 8
  %582 = ptrtoint ptr %0 to i64
  %583 = zext i32 %1 to i64
  %584 = xor i64 %582, %583
  %585 = sub i64 %584, %583
  %586 = sub i64 %585, %582
  %587 = and i64 %586, %583
  %588 = xor i64 %587, %582
  %589 = sub i64 %588, %583
  store i64 %589, ptr %3, align 8
  br label %236

590:                                              ; preds = %353
  %591 = load i64, ptr %3, align 8
  %592 = ptrtoint ptr %0 to i64
  %593 = zext i32 %1 to i64
  %594 = add i64 %593, %592
  %595 = or i64 %594, %593
  %596 = mul i64 %595, %593
  store i64 %596, ptr %3, align 8
  br label %236
}

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i64 @calculateDiscount(i64 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i64, align 8
  %6 = alloca i64, align 8
  %7 = alloca ptr, align 8
  store i32 198268158, ptr %4, align 4
  br label %8

8:                                                ; preds = %421, %179, %178, %2
  %9 = load i32, ptr %4, align 4
  %10 = sub i32 %9, -1208367243
  %11 = mul i32 %10, 58087071
  %12 = icmp slt i32 %11, 1362739356
  br i1 %12, label %286, label %288

13:                                               ; preds = %330
  store i64 %0, ptr %6, align 8
  store ptr %1, ptr %7, align 8
  %14 = load ptr, ptr %7, align 8
  %15 = call i32 @equalsIgnoreCase(ptr noundef %14, ptr noundef @.str.43)
  %16 = icmp ne i32 %15, 0
  %17 = select i1 %16, i32 -71550711, i32 685666906
  store i32 %17, ptr %4, align 4
  %18 = xor i64 %0, 1954382943383477877
  %19 = and i64 %0, %18
  %20 = or i64 %0, %18
  %21 = xor i64 %0, %18
  %22 = add i64 %19, %20
  %23 = sub i64 %22, %0
  %24 = sub i64 %23, %18
  %25 = mul i64 %24, 48
  %26 = xor i64 %0, 2065596204135897409
  %27 = and i64 %0, %26
  %28 = or i64 %0, %26
  %29 = xor i64 %0, %26
  %30 = mul i64 %28, 2
  %31 = sub i64 %30, %29
  %32 = sub i64 %31, %0
  %33 = sub i64 %32, %26
  %34 = mul i64 %33, 199
  %35 = icmp ne i64 %25, %34
  br i1 %35, label %346, label %178

36:                                               ; preds = %344
  store i64 0, ptr %5, align 8
  store i32 656148363, ptr %4, align 4
  %37 = xor i64 %0, 3926830814926444955
  %38 = and i64 %0, %37
  %39 = or i64 %0, %37
  %40 = xor i64 %0, %37
  %41 = add i64 %0, %37
  %42 = sub i64 %41, %40
  %43 = mul i64 %38, 2
  %44 = sub i64 %42, %43
  %45 = mul i64 %44, 239
  %46 = icmp slt i64 %45, 0
  br i1 %46, label %352, label %178

47:                                               ; preds = %338
  %48 = load ptr, ptr %7, align 8
  %49 = call i32 @equalsIgnoreCase(ptr noundef %48, ptr noundef @.str.44)
  %50 = icmp ne i32 %49, 0
  %51 = select i1 %50, i32 1982516224, i32 1595634996
  store i32 %51, ptr %4, align 4
  %52 = xor i64 %0, -6790257215730238489
  %53 = and i64 %0, %52
  %54 = or i64 %0, %52
  %55 = xor i64 %0, %52
  %56 = sub i64 %54, %55
  %57 = sub i64 %56, %53
  %58 = mul i64 %57, 57
  %59 = xor i64 %0, 2690636178249239821
  %60 = and i64 %0, %59
  %61 = or i64 %0, %59
  %62 = xor i64 %0, %59
  %63 = sub i64 %61, %62
  %64 = sub i64 %63, %60
  %65 = mul i64 %64, 10
  %66 = icmp eq i64 %58, %65
  br i1 %66, label %178, label %358

67:                                               ; preds = %316
  %68 = load i64, ptr %6, align 8
  %69 = mul nsw i64 %68, 10
  %70 = sdiv i64 %69, 100
  store i64 %70, ptr %5, align 8
  store i32 656148363, ptr %4, align 4
  %71 = xor i64 %0, -5627509875273682649
  %72 = and i64 %0, %71
  %73 = or i64 %0, %71
  %74 = xor i64 %0, %71
  %75 = add i64 %0, %71
  %76 = sub i64 %75, %74
  %77 = mul i64 %72, 2
  %78 = sub i64 %76, %77
  %79 = mul i64 %78, 7
  %80 = icmp slt i64 %79, 1
  br i1 %80, label %178, label %365

81:                                               ; preds = %340
  %82 = load ptr, ptr %7, align 8
  %83 = call i32 @equalsIgnoreCase(ptr noundef %82, ptr noundef @.str.45)
  %84 = icmp ne i32 %83, 0
  %85 = select i1 %84, i32 -1315454013, i32 -1444224964
  store i32 %85, ptr %4, align 4
  %86 = xor i64 %0, -1697865903624311787
  %87 = and i64 %0, %86
  %88 = or i64 %0, %86
  %89 = xor i64 %0, %86
  %90 = add i64 %0, %86
  %91 = sub i64 %90, %89
  %92 = mul i64 %87, 2
  %93 = sub i64 %91, %92
  %94 = mul i64 %93, 220
  %95 = icmp eq i64 %94, 0
  br i1 %95, label %178, label %374

96:                                               ; preds = %326
  %97 = load i64, ptr %6, align 8
  %98 = icmp sge i64 %97, 50000
  %99 = select i1 %98, i32 1789283673, i32 1697052726
  store i32 %99, ptr %4, align 4
  %100 = xor i64 %0, -6898964657760150891
  %101 = and i64 %0, %100
  %102 = or i64 %0, %100
  %103 = xor i64 %0, %100
  %104 = mul i64 %102, 2
  %105 = sub i64 %104, %103
  %106 = sub i64 %105, %0
  %107 = sub i64 %106, %100
  %108 = mul i64 %107, 152
  %109 = icmp eq i64 %108, 0
  br i1 %109, label %178, label %381

110:                                              ; preds = %322
  %111 = load i64, ptr %6, align 8
  %112 = mul nsw i64 %111, 15
  %113 = sdiv i64 %112, 100
  store i64 %113, ptr %5, align 8
  store i32 656148363, ptr %4, align 4
  %114 = xor i64 %0, -8567342888459772259
  %115 = and i64 %0, %114
  %116 = or i64 %0, %114
  %117 = xor i64 %0, %114
  %118 = sub i64 %116, %117
  %119 = sub i64 %118, %115
  %120 = mul i64 %119, 62
  %121 = icmp sle i64 %120, 0
  br i1 %121, label %178, label %389

122:                                              ; preds = %342
  store i64 0, ptr %5, align 8
  store i32 656148363, ptr %4, align 4
  %123 = xor i64 %0, 6980119457687939897
  %124 = and i64 %0, %123
  %125 = or i64 %0, %123
  %126 = xor i64 %0, %123
  %127 = add i64 %0, %123
  %128 = sub i64 %127, %126
  %129 = mul i64 %124, 2
  %130 = sub i64 %128, %129
  %131 = mul i64 %130, 125
  %132 = icmp ne i64 %131, 0
  br i1 %132, label %395, label %178

133:                                              ; preds = %294
  %134 = load ptr, ptr %7, align 8
  %135 = call i32 @equalsIgnoreCase(ptr noundef %134, ptr noundef @.str.46)
  %136 = icmp ne i32 %135, 0
  %137 = select i1 %136, i32 -1436717652, i32 -547633304
  store i32 %137, ptr %4, align 4
  %138 = xor i64 %0, 6891753475767658653
  %139 = and i64 %0, %138
  %140 = or i64 %0, %138
  %141 = xor i64 %0, %138
  %142 = add i64 %139, %140
  %143 = sub i64 %142, %0
  %144 = sub i64 %143, %138
  %145 = mul i64 %144, 40
  %146 = icmp sle i64 %145, 0
  br i1 %146, label %178, label %402

147:                                              ; preds = %314
  store i64 0, ptr %5, align 8
  store i32 656148363, ptr %4, align 4
  %148 = xor i64 %0, 5456593207884779087
  %149 = and i64 %0, %148
  %150 = or i64 %0, %148
  %151 = xor i64 %0, %148
  %152 = add i64 %0, %148
  %153 = sub i64 %152, %151
  %154 = mul i64 %149, 2
  %155 = sub i64 %153, %154
  %156 = mul i64 %155, 213
  %157 = icmp slt i64 %156, 1
  br i1 %157, label %178, label %408

158:                                              ; preds = %304
  store i64 -1, ptr %5, align 8
  store i32 656148363, ptr %4, align 4
  %159 = xor i64 %0, 4069719030662615241
  %160 = and i64 %0, %159
  %161 = or i64 %0, %159
  %162 = xor i64 %0, %159
  %163 = sub i64 %161, %162
  %164 = sub i64 %163, %160
  %165 = mul i64 %164, 21
  %166 = xor i64 %0, 6626843109356909571
  %167 = and i64 %0, %166
  %168 = or i64 %0, %166
  %169 = xor i64 %0, %166
  %170 = add i64 %0, %166
  %171 = sub i64 %170, %169
  %172 = mul i64 %167, 2
  %173 = sub i64 %171, %172
  %174 = mul i64 %173, 181
  %175 = icmp ne i64 %165, %174
  br i1 %175, label %415, label %178

176:                                              ; preds = %328
  %177 = load i64, ptr %5, align 8
  ret i64 %177

178:                                              ; preds = %480, %471, %464, %456, %449, %441, %434, %427, %415, %408, %402, %395, %389, %381, %374, %365, %358, %352, %346, %273, %261, %250, %238, %225, %214, %201, %188, %158, %147, %133, %122, %110, %96, %81, %67, %47, %36, %13
  br label %8

179:                                              ; preds = %344, %340, %338, %332, %328, %326, %316, %312, %310, %304, %300, %298
  store i32 198268158, ptr %4, align 4
  call void asm sideeffect "", ""()
  %180 = xor i64 %0, 785882351155011333
  %181 = and i64 %0, %180
  %182 = or i64 %0, %180
  %183 = xor i64 %0, %180
  %184 = sub i64 %182, %183
  %185 = sub i64 %184, %181
  %186 = mul i64 %185, 125
  %187 = icmp eq i64 %186, 0
  br i1 %187, label %8, label %421

188:                                              ; preds = %332
  %189 = load i32, ptr %4, align 4
  %190 = xor i32 %189, -440828808
  store i32 %190, ptr %4, align 4
  %191 = xor i64 %0, 4642400202141917979
  %192 = and i64 %0, %191
  %193 = or i64 %0, %191
  %194 = xor i64 %0, %191
  %195 = mul i64 %193, 2
  %196 = sub i64 %195, %194
  %197 = sub i64 %196, %0
  %198 = sub i64 %197, %191
  %199 = mul i64 %198, 5
  %200 = icmp ugt i64 %199, 0
  br i1 %200, label %427, label %178

201:                                              ; preds = %298
  %202 = load i32, ptr %4, align 4
  %203 = xor i32 %202, -420107918
  store i32 %203, ptr %4, align 4
  %204 = xor i64 %0, 8228945588697930215
  %205 = and i64 %0, %204
  %206 = or i64 %0, %204
  %207 = xor i64 %0, %204
  %208 = add i64 %0, %204
  %209 = sub i64 %208, %207
  %210 = mul i64 %205, 2
  %211 = sub i64 %209, %210
  %212 = mul i64 %211, 154
  %213 = icmp sle i64 %212, 0
  br i1 %213, label %178, label %434

214:                                              ; preds = %302
  %215 = load i32, ptr %4, align 4
  %216 = xor i32 %215, 1990379835
  store i32 %216, ptr %4, align 4
  %217 = xor i64 %0, -8812234093281030329
  %218 = and i64 %0, %217
  %219 = or i64 %0, %217
  %220 = xor i64 %0, %217
  %221 = sub i64 %219, %220
  %222 = sub i64 %221, %218
  %223 = mul i64 %222, 203
  %224 = icmp sgt i64 %223, 0
  br i1 %224, label %441, label %178

225:                                              ; preds = %310
  %226 = load i32, ptr %4, align 4
  %227 = xor i32 %226, -2068406812
  store i32 %227, ptr %4, align 4
  %228 = xor i64 %0, 1081047285840772461
  %229 = and i64 %0, %228
  %230 = or i64 %0, %228
  %231 = xor i64 %0, %228
  %232 = mul i64 %230, 2
  %233 = sub i64 %232, %231
  %234 = sub i64 %233, %0
  %235 = sub i64 %234, %228
  %236 = mul i64 %235, 95
  %237 = icmp eq i64 %236, 0
  br i1 %237, label %178, label %449

238:                                              ; preds = %334
  %239 = load i32, ptr %4, align 4
  %240 = xor i32 %239, 22025594
  store i32 %240, ptr %4, align 4
  %241 = xor i64 %0, -1663796812403478537
  %242 = and i64 %0, %241
  %243 = or i64 %0, %241
  %244 = xor i64 %0, %241
  %245 = add i64 %242, %243
  %246 = sub i64 %245, %0
  %247 = sub i64 %246, %241
  %248 = mul i64 %247, 43
  %249 = icmp sle i64 %248, 0
  br i1 %249, label %178, label %456

250:                                              ; preds = %312
  %251 = load i32, ptr %4, align 4
  %252 = xor i32 %251, 1667935017
  store i32 %252, ptr %4, align 4
  %253 = xor i64 %0, 3630242158495325667
  %254 = and i64 %0, %253
  %255 = or i64 %0, %253
  %256 = xor i64 %0, %253
  %257 = sub i64 %255, %256
  %258 = sub i64 %257, %254
  %259 = mul i64 %258, 252
  %260 = icmp slt i64 %259, 0
  br i1 %260, label %464, label %178

261:                                              ; preds = %300
  %262 = load i32, ptr %4, align 4
  %263 = xor i32 %262, -1981113115
  store i32 %263, ptr %4, align 4
  %264 = xor i64 %0, 1906044101618557583
  %265 = and i64 %0, %264
  %266 = or i64 %0, %264
  %267 = xor i64 %0, %264
  %268 = add i64 %265, %266
  %269 = sub i64 %268, %0
  %270 = sub i64 %269, %264
  %271 = mul i64 %270, 163
  %272 = icmp uge i64 %271, 0
  br i1 %272, label %178, label %471

273:                                              ; preds = %306
  %274 = load i32, ptr %4, align 4
  %275 = xor i32 %274, 474968199
  store i32 %275, ptr %4, align 4
  %276 = xor i64 %0, 5724416192680473647
  %277 = and i64 %0, %276
  %278 = or i64 %0, %276
  %279 = xor i64 %0, %276
  %280 = mul i64 %278, 2
  %281 = sub i64 %280, %279
  %282 = sub i64 %281, %0
  %283 = sub i64 %282, %276
  %284 = mul i64 %283, 138
  %285 = icmp sle i64 %284, 0
  br i1 %285, label %178, label %480

286:                                              ; preds = %8
  %287 = icmp slt i32 %11, 897197888
  br i1 %287, label %290, label %292

288:                                              ; preds = %8
  %289 = icmp slt i32 %11, 1618400441
  br i1 %289, label %318, label %320

290:                                              ; preds = %286
  %291 = icmp slt i32 %11, 155571318
  br i1 %291, label %294, label %296

292:                                              ; preds = %286
  %293 = icmp slt i32 %11, 1001493625
  br i1 %293, label %306, label %308

294:                                              ; preds = %290
  %295 = icmp eq i32 %11, 63651225
  br i1 %295, label %133, label %298

296:                                              ; preds = %290
  %297 = icmp slt i32 %11, 810412086
  br i1 %297, label %300, label %302

298:                                              ; preds = %294
  %299 = icmp eq i32 %11, 124067649
  br i1 %299, label %201, label %179

300:                                              ; preds = %296
  %301 = icmp eq i32 %11, 155571318
  br i1 %301, label %261, label %179

302:                                              ; preds = %296
  %303 = icmp eq i32 %11, 810412086
  br i1 %303, label %214, label %304

304:                                              ; preds = %302
  %305 = icmp eq i32 %11, 886807021
  br i1 %305, label %158, label %179

306:                                              ; preds = %292
  %307 = icmp eq i32 %11, 897197888
  br i1 %307, label %273, label %310

308:                                              ; preds = %292
  %309 = icmp slt i32 %11, 1209316905
  br i1 %309, label %312, label %314

310:                                              ; preds = %306
  %311 = icmp eq i32 %11, 910035509
  br i1 %311, label %225, label %179

312:                                              ; preds = %308
  %313 = icmp eq i32 %11, 1001493625
  br i1 %313, label %250, label %179

314:                                              ; preds = %308
  %315 = icmp eq i32 %11, 1209316905
  br i1 %315, label %147, label %316

316:                                              ; preds = %314
  %317 = icmp eq i32 %11, 1359643733
  br i1 %317, label %67, label %179

318:                                              ; preds = %288
  %319 = icmp slt i32 %11, 1408315818
  br i1 %319, label %322, label %324

320:                                              ; preds = %288
  %321 = icmp slt i32 %11, 1901269921
  br i1 %321, label %334, label %336

322:                                              ; preds = %318
  %323 = icmp eq i32 %11, 1362739356
  br i1 %323, label %110, label %326

324:                                              ; preds = %318
  %325 = icmp slt i32 %11, 1418915351
  br i1 %325, label %328, label %330

326:                                              ; preds = %322
  %327 = icmp eq i32 %11, 1372973170
  br i1 %327, label %96, label %179

328:                                              ; preds = %324
  %329 = icmp eq i32 %11, 1408315818
  br i1 %329, label %176, label %179

330:                                              ; preds = %324
  %331 = icmp eq i32 %11, 1418915351
  br i1 %331, label %13, label %332

332:                                              ; preds = %330
  %333 = icmp eq i32 %11, 1609031293
  br i1 %333, label %188, label %179

334:                                              ; preds = %320
  %335 = icmp eq i32 %11, 1618400441
  br i1 %335, label %238, label %338

336:                                              ; preds = %320
  %337 = icmp slt i32 %11, 2036866527
  br i1 %337, label %340, label %342

338:                                              ; preds = %334
  %339 = icmp eq i32 %11, 1677529659
  br i1 %339, label %47, label %179

340:                                              ; preds = %336
  %341 = icmp eq i32 %11, 1901269921
  br i1 %341, label %81, label %179

342:                                              ; preds = %336
  %343 = icmp eq i32 %11, 2036866527
  br i1 %343, label %122, label %344

344:                                              ; preds = %342
  %345 = icmp eq i32 %11, 2116305644
  br i1 %345, label %36, label %179

346:                                              ; preds = %13
  %347 = load i64, ptr %3, align 8
  %348 = ptrtoint ptr %1 to i64
  %349 = mul i64 %348, %0
  %350 = sub i64 %349, %348
  %351 = add i64 %350, %348
  store i64 %351, ptr %3, align 8
  br label %178

352:                                              ; preds = %36
  %353 = load i64, ptr %3, align 8
  %354 = ptrtoint ptr %1 to i64
  %355 = sub i64 %0, %354
  %356 = sub i64 %355, %353
  %357 = and i64 %356, %0
  store i64 %357, ptr %3, align 8
  br label %178

358:                                              ; preds = %47
  %359 = load i64, ptr %3, align 8
  %360 = ptrtoint ptr %1 to i64
  %361 = xor i64 %360, %360
  %362 = or i64 %361, %360
  %363 = sub i64 %362, %0
  %364 = or i64 %363, %0
  store i64 %364, ptr %3, align 8
  br label %178

365:                                              ; preds = %67
  %366 = load i64, ptr %3, align 8
  %367 = ptrtoint ptr %1 to i64
  %368 = sub i64 %367, %0
  %369 = xor i64 %368, %367
  %370 = and i64 %369, %0
  %371 = or i64 %370, %366
  %372 = xor i64 %371, %366
  %373 = add i64 %372, %366
  store i64 %373, ptr %3, align 8
  br label %178

374:                                              ; preds = %81
  %375 = load i64, ptr %3, align 8
  %376 = ptrtoint ptr %1 to i64
  %377 = add i64 %376, %0
  %378 = xor i64 %377, %376
  %379 = xor i64 %378, %375
  %380 = and i64 %379, %376
  store i64 %380, ptr %3, align 8
  br label %178

381:                                              ; preds = %96
  %382 = load i64, ptr %3, align 8
  %383 = ptrtoint ptr %1 to i64
  %384 = add i64 %382, %0
  %385 = or i64 %384, %382
  %386 = sub i64 %385, %383
  %387 = and i64 %386, %382
  %388 = sub i64 %387, %382
  store i64 %388, ptr %3, align 8
  br label %178

389:                                              ; preds = %110
  %390 = load i64, ptr %3, align 8
  %391 = ptrtoint ptr %1 to i64
  %392 = add i64 %391, %391
  %393 = or i64 %392, %0
  %394 = and i64 %393, %390
  store i64 %394, ptr %3, align 8
  br label %178

395:                                              ; preds = %122
  %396 = load i64, ptr %3, align 8
  %397 = ptrtoint ptr %1 to i64
  %398 = add i64 %397, %396
  %399 = xor i64 %398, %0
  %400 = sub i64 %399, %397
  %401 = xor i64 %400, %397
  store i64 %401, ptr %3, align 8
  br label %178

402:                                              ; preds = %133
  %403 = load i64, ptr %3, align 8
  %404 = ptrtoint ptr %1 to i64
  %405 = and i64 %403, %404
  %406 = or i64 %405, %0
  %407 = and i64 %406, %404
  store i64 %407, ptr %3, align 8
  br label %178

408:                                              ; preds = %147
  %409 = load i64, ptr %3, align 8
  %410 = ptrtoint ptr %1 to i64
  %411 = or i64 %0, %0
  %412 = or i64 %411, %409
  %413 = mul i64 %412, %410
  %414 = add i64 %413, %410
  store i64 %414, ptr %3, align 8
  br label %178

415:                                              ; preds = %158
  %416 = load i64, ptr %3, align 8
  %417 = ptrtoint ptr %1 to i64
  %418 = and i64 %416, %416
  %419 = mul i64 %418, %417
  %420 = xor i64 %419, %416
  store i64 %420, ptr %3, align 8
  br label %178

421:                                              ; preds = %179
  %422 = load i64, ptr %3, align 8
  %423 = ptrtoint ptr %1 to i64
  %424 = xor i64 %423, %422
  %425 = xor i64 %424, %423
  %426 = sub i64 %425, %0
  store i64 %426, ptr %3, align 8
  br label %8

427:                                              ; preds = %188
  %428 = load i64, ptr %3, align 8
  %429 = ptrtoint ptr %1 to i64
  %430 = mul i64 %0, %429
  %431 = xor i64 %430, %428
  %432 = or i64 %431, %0
  %433 = or i64 %432, %429
  store i64 %433, ptr %3, align 8
  br label %178

434:                                              ; preds = %201
  %435 = load i64, ptr %3, align 8
  %436 = ptrtoint ptr %1 to i64
  %437 = xor i64 %0, %0
  %438 = sub i64 %437, %436
  %439 = xor i64 %438, %435
  %440 = and i64 %439, %0
  store i64 %440, ptr %3, align 8
  br label %178

441:                                              ; preds = %214
  %442 = load i64, ptr %3, align 8
  %443 = ptrtoint ptr %1 to i64
  %444 = or i64 %442, %443
  %445 = sub i64 %444, %443
  %446 = xor i64 %445, %443
  %447 = and i64 %446, %0
  %448 = add i64 %447, %0
  store i64 %448, ptr %3, align 8
  br label %178

449:                                              ; preds = %225
  %450 = load i64, ptr %3, align 8
  %451 = ptrtoint ptr %1 to i64
  %452 = mul i64 %0, %450
  %453 = xor i64 %452, %0
  %454 = sub i64 %453, %450
  %455 = mul i64 %454, %450
  store i64 %455, ptr %3, align 8
  br label %178

456:                                              ; preds = %238
  %457 = load i64, ptr %3, align 8
  %458 = ptrtoint ptr %1 to i64
  %459 = or i64 %0, %457
  %460 = and i64 %459, %458
  %461 = sub i64 %460, %458
  %462 = or i64 %461, %457
  %463 = or i64 %462, %0
  store i64 %463, ptr %3, align 8
  br label %178

464:                                              ; preds = %250
  %465 = load i64, ptr %3, align 8
  %466 = ptrtoint ptr %1 to i64
  %467 = xor i64 %466, %0
  %468 = or i64 %467, %465
  %469 = mul i64 %468, %465
  %470 = xor i64 %469, %0
  store i64 %470, ptr %3, align 8
  br label %178

471:                                              ; preds = %261
  %472 = load i64, ptr %3, align 8
  %473 = ptrtoint ptr %1 to i64
  %474 = or i64 %473, %472
  %475 = add i64 %474, %472
  %476 = sub i64 %475, %0
  %477 = and i64 %476, %0
  %478 = xor i64 %477, %0
  %479 = add i64 %478, %472
  store i64 %479, ptr %3, align 8
  br label %178

480:                                              ; preds = %273
  %481 = load i64, ptr %3, align 8
  %482 = ptrtoint ptr %1 to i64
  %483 = and i64 %482, %482
  %484 = mul i64 %483, %481
  %485 = mul i64 %484, %481
  store i64 %485, ptr %3, align 8
  br label %178
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
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = ptrtoint ptr %0 to i32
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  store i32 86450405, ptr %4, align 4
  br label %7

7:                                                ; preds = %241, %141, %140, %1
  %8 = load i32, ptr %4, align 4
  %9 = sub i32 %8, -524315523
  %10 = mul i32 %9, -1627536453
  switch i32 %10, label %141 [
    i32 1784596472, label %11
    i32 567274742, label %42
    i32 887023112, label %57
    i32 1809398519, label %114
    i32 2000998743, label %152
    i32 270709132, label %171
    i32 102295438, label %193
    i32 1308496225, label %205
  ]

11:                                               ; preds = %7
  store ptr %0, ptr %5, align 8
  %12 = load ptr, ptr %5, align 8
  %13 = getelementptr inbounds nuw %struct.Order, ptr %12, i32 0, i32 0
  %14 = load i32, ptr %13, align 8
  %15 = call i32 (ptr, ...) @printf(ptr noundef @.str.55, i32 noundef %14)
  %16 = load ptr, ptr %5, align 8
  %17 = getelementptr inbounds nuw %struct.Order, ptr %16, i32 0, i32 1
  %18 = getelementptr inbounds [80 x i8], ptr %17, i64 0, i64 0
  %19 = call i32 (ptr, ...) @printf(ptr noundef @.str.56, ptr noundef %18)
  %20 = load ptr, ptr %5, align 8
  %21 = getelementptr inbounds nuw %struct.Order, ptr %20, i32 0, i32 2
  %22 = getelementptr inbounds [30 x i8], ptr %21, i64 0, i64 0
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.57, ptr noundef %22)
  %24 = load ptr, ptr %5, align 8
  %25 = getelementptr inbounds nuw %struct.Order, ptr %24, i32 0, i32 10
  %26 = load i32, ptr %25, align 8
  %27 = icmp ne i32 %26, 0
  %28 = zext i1 %27 to i64
  %29 = select i1 %27, ptr @.str.53, ptr @.str.54
  %30 = call i32 (ptr, ...) @printf(ptr noundef @.str.58, ptr noundef %29)
  %31 = call i32 (ptr, ...) @printf(ptr noundef @.str.59)
  store i32 0, ptr %6, align 4
  store i32 880454911, ptr %4, align 4
  %32 = xor i32 %3, -388965303
  %33 = and i32 %3, %32
  %34 = or i32 %3, %32
  %35 = xor i32 %3, %32
  %36 = add i32 %3, %32
  %37 = sub i32 %36, %35
  %38 = mul i32 %33, 2
  %39 = sub i32 %37, %38
  %40 = mul i32 %39, 172
  %41 = icmp slt i32 %40, 1
  br i1 %41, label %140, label %218

42:                                               ; preds = %7
  %43 = load i32, ptr %6, align 4
  %44 = load ptr, ptr %5, align 8
  %45 = getelementptr inbounds nuw %struct.Order, ptr %44, i32 0, i32 4
  %46 = load i32, ptr %45, align 8
  %47 = icmp slt i32 %43, %46
  %48 = select i1 %47, i32 455815701, i32 1728921714
  store i32 %48, ptr %4, align 4
  %49 = xor i32 %3, 1144126303
  %50 = and i32 %3, %49
  %51 = or i32 %3, %49
  %52 = xor i32 %3, %49
  %53 = sub i32 %51, %52
  %54 = sub i32 %53, %50
  %55 = mul i32 %54, 70
  %56 = icmp ugt i32 %55, 0
  br i1 %56, label %226, label %140

57:                                               ; preds = %7
  %58 = load ptr, ptr %5, align 8
  %59 = getelementptr inbounds nuw %struct.Order, ptr %58, i32 0, i32 3
  %60 = load i32, ptr %6, align 4
  %61 = sext i32 %60 to i64
  %62 = getelementptr inbounds [64 x %struct.OrderItem], ptr %59, i64 0, i64 %61
  %63 = getelementptr inbounds nuw %struct.OrderItem, ptr %62, i32 0, i32 0
  %64 = load i32, ptr %63, align 8
  %65 = load ptr, ptr %5, align 8
  %66 = getelementptr inbounds nuw %struct.Order, ptr %65, i32 0, i32 3
  %67 = load i32, ptr %6, align 4
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds [64 x %struct.OrderItem], ptr %66, i64 0, i64 %68
  %70 = getelementptr inbounds nuw %struct.OrderItem, ptr %69, i32 0, i32 1
  %71 = getelementptr inbounds [80 x i8], ptr %70, i64 0, i64 0
  %72 = load ptr, ptr %5, align 8
  %73 = getelementptr inbounds nuw %struct.Order, ptr %72, i32 0, i32 3
  %74 = load i32, ptr %6, align 4
  %75 = sext i32 %74 to i64
  %76 = getelementptr inbounds [64 x %struct.OrderItem], ptr %73, i64 0, i64 %75
  %77 = getelementptr inbounds nuw %struct.OrderItem, ptr %76, i32 0, i32 2
  %78 = load i32, ptr %77, align 4
  %79 = call i32 (ptr, ...) @printf(ptr noundef @.str.60, i32 noundef %64, ptr noundef %71, i32 noundef %78)
  %80 = load ptr, ptr %5, align 8
  %81 = getelementptr inbounds nuw %struct.Order, ptr %80, i32 0, i32 3
  %82 = load i32, ptr %6, align 4
  %83 = sext i32 %82 to i64
  %84 = getelementptr inbounds [64 x %struct.OrderItem], ptr %81, i64 0, i64 %83
  %85 = getelementptr inbounds nuw %struct.OrderItem, ptr %84, i32 0, i32 3
  %86 = load i64, ptr %85, align 8
  call void @printMoney(i64 noundef %86)
  %87 = call i32 (ptr, ...) @printf(ptr noundef @.str.61)
  %88 = load ptr, ptr %5, align 8
  %89 = getelementptr inbounds nuw %struct.Order, ptr %88, i32 0, i32 3
  %90 = load i32, ptr %6, align 4
  %91 = sext i32 %90 to i64
  %92 = getelementptr inbounds [64 x %struct.OrderItem], ptr %89, i64 0, i64 %91
  %93 = getelementptr inbounds nuw %struct.OrderItem, ptr %92, i32 0, i32 4
  %94 = load i64, ptr %93, align 8
  call void @printMoney(i64 noundef %94)
  %95 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %96 = load i32, ptr %6, align 4
  %97 = load i32, ptr %4, align 4
  %98 = xor i32 %97, 455815700
  %99 = or i32 %96, %98
  %100 = load i32, ptr %4, align 4
  %101 = xor i32 %100, 455815700
  %102 = and i32 %96, %101
  %103 = add i32 %99, %102
  store i32 %103, ptr %6, align 4
  store i32 880454911, ptr %4, align 4
  %104 = xor i32 %3, -491637157
  %105 = and i32 %3, %104
  %106 = or i32 %3, %104
  %107 = xor i32 %3, %104
  %108 = add i32 %3, %104
  %109 = sub i32 %108, %107
  %110 = mul i32 %105, 2
  %111 = sub i32 %109, %110
  %112 = mul i32 %111, 223
  %113 = icmp slt i32 %112, 0
  br i1 %113, label %235, label %140

114:                                              ; preds = %7
  %115 = call i32 (ptr, ...) @printf(ptr noundef @.str.62)
  %116 = load ptr, ptr %5, align 8
  %117 = getelementptr inbounds nuw %struct.Order, ptr %116, i32 0, i32 5
  %118 = load i64, ptr %117, align 8
  call void @printMoney(i64 noundef %118)
  %119 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %120 = call i32 (ptr, ...) @printf(ptr noundef @.str.63)
  %121 = load ptr, ptr %5, align 8
  %122 = getelementptr inbounds nuw %struct.Order, ptr %121, i32 0, i32 6
  %123 = load i64, ptr %122, align 8
  call void @printMoney(i64 noundef %123)
  %124 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %125 = call i32 (ptr, ...) @printf(ptr noundef @.str.64)
  %126 = load ptr, ptr %5, align 8
  %127 = getelementptr inbounds nuw %struct.Order, ptr %126, i32 0, i32 7
  %128 = load i64, ptr %127, align 8
  call void @printMoney(i64 noundef %128)
  %129 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %130 = call i32 (ptr, ...) @printf(ptr noundef @.str.65)
  %131 = load ptr, ptr %5, align 8
  %132 = getelementptr inbounds nuw %struct.Order, ptr %131, i32 0, i32 8
  %133 = load i64, ptr %132, align 8
  call void @printMoney(i64 noundef %133)
  %134 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %135 = call i32 (ptr, ...) @printf(ptr noundef @.str.66)
  %136 = load ptr, ptr %5, align 8
  %137 = getelementptr inbounds nuw %struct.Order, ptr %136, i32 0, i32 9
  %138 = load i64, ptr %137, align 8
  call void @printMoney(i64 noundef %138)
  %139 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  ret void

140:                                              ; preds = %275, %267, %259, %250, %235, %226, %218, %205, %193, %171, %152, %57, %42, %11
  br label %7

141:                                              ; preds = %7
  store i32 86450405, ptr %4, align 4
  call void asm sideeffect "", ""()
  %142 = xor i32 %3, -1585069393
  %143 = and i32 %3, %142
  %144 = or i32 %3, %142
  %145 = xor i32 %3, %142
  %146 = mul i32 %144, 2
  %147 = sub i32 %146, %145
  %148 = sub i32 %147, %3
  %149 = sub i32 %148, %142
  %150 = mul i32 %149, 177
  %151 = icmp slt i32 %150, 0
  br i1 %151, label %241, label %7

152:                                              ; preds = %7
  %153 = load i32, ptr %4, align 4
  %154 = xor i32 %153, 1486214175
  store i32 %154, ptr %4, align 4
  %155 = xor i32 %3, 87255809
  %156 = and i32 %3, %155
  %157 = or i32 %3, %155
  %158 = xor i32 %3, %155
  %159 = sub i32 %157, %158
  %160 = sub i32 %159, %156
  %161 = mul i32 %160, 199
  %162 = xor i32 %3, -527626241
  %163 = and i32 %3, %162
  %164 = or i32 %3, %162
  %165 = xor i32 %3, %162
  %166 = add i32 %163, %164
  %167 = sub i32 %166, %3
  %168 = sub i32 %167, %162
  %169 = mul i32 %168, 67
  %170 = icmp ne i32 %161, %169
  br i1 %170, label %250, label %140

171:                                              ; preds = %7
  %172 = load i32, ptr %4, align 4
  %173 = xor i32 %172, -981679375
  store i32 %173, ptr %4, align 4
  %174 = xor i32 %3, -2123272551
  %175 = and i32 %3, %174
  %176 = or i32 %3, %174
  %177 = xor i32 %3, %174
  %178 = add i32 %3, %174
  %179 = sub i32 %178, %177
  %180 = mul i32 %175, 2
  %181 = sub i32 %179, %180
  %182 = mul i32 %181, 11
  %183 = xor i32 %3, -1134656255
  %184 = and i32 %3, %183
  %185 = or i32 %3, %183
  %186 = xor i32 %3, %183
  %187 = add i32 %3, %183
  %188 = sub i32 %187, %186
  %189 = mul i32 %184, 2
  %190 = sub i32 %188, %189
  %191 = mul i32 %190, 103
  %192 = icmp ne i32 %182, %191
  br i1 %192, label %259, label %140

193:                                              ; preds = %7
  %194 = load i32, ptr %4, align 4
  %195 = xor i32 %194, 106871852
  store i32 %195, ptr %4, align 4
  %196 = xor i32 %3, 305155167
  %197 = and i32 %3, %196
  %198 = or i32 %3, %196
  %199 = xor i32 %3, %196
  %200 = add i32 %197, %198
  %201 = sub i32 %200, %3
  %202 = sub i32 %201, %196
  %203 = mul i32 %202, 26
  %204 = icmp ugt i32 %203, 0
  br i1 %204, label %267, label %140

205:                                              ; preds = %7
  %206 = load i32, ptr %4, align 4
  %207 = xor i32 %206, 663752918
  store i32 %207, ptr %4, align 4
  %208 = xor i32 %3, 628895299
  %209 = and i32 %3, %208
  %210 = or i32 %3, %208
  %211 = xor i32 %3, %208
  %212 = mul i32 %210, 2
  %213 = sub i32 %212, %211
  %214 = sub i32 %213, %3
  %215 = sub i32 %214, %208
  %216 = mul i32 %215, 138
  %217 = icmp slt i32 %216, 1
  br i1 %217, label %140, label %275

218:                                              ; preds = %11
  %219 = load i64, ptr %2, align 8
  %220 = ptrtoint ptr %0 to i64
  %221 = or i64 %220, %220
  %222 = and i64 %221, %220
  %223 = add i64 %222, %220
  %224 = mul i64 %223, %219
  %225 = mul i64 %224, %220
  store i64 %225, ptr %2, align 8
  br label %140

226:                                              ; preds = %42
  %227 = load i64, ptr %2, align 8
  %228 = ptrtoint ptr %0 to i64
  %229 = and i64 %227, %228
  %230 = and i64 %229, %228
  %231 = or i64 %230, %227
  %232 = sub i64 %231, %227
  %233 = sub i64 %232, %228
  %234 = mul i64 %233, %227
  store i64 %234, ptr %2, align 8
  br label %140

235:                                              ; preds = %57
  %236 = load i64, ptr %2, align 8
  %237 = ptrtoint ptr %0 to i64
  %238 = or i64 %236, %236
  %239 = xor i64 %238, %237
  %240 = and i64 %239, %236
  store i64 %240, ptr %2, align 8
  br label %140

241:                                              ; preds = %141
  %242 = load i64, ptr %2, align 8
  %243 = ptrtoint ptr %0 to i64
  %244 = and i64 %243, %243
  %245 = xor i64 %244, %243
  %246 = sub i64 %245, %242
  %247 = and i64 %246, %242
  %248 = add i64 %247, %243
  %249 = and i64 %248, %242
  store i64 %249, ptr %2, align 8
  br label %7

250:                                              ; preds = %152
  %251 = load i64, ptr %2, align 8
  %252 = ptrtoint ptr %0 to i64
  %253 = sub i64 %252, %251
  %254 = or i64 %253, %251
  %255 = sub i64 %254, %251
  %256 = add i64 %255, %252
  %257 = add i64 %256, %251
  %258 = and i64 %257, %252
  store i64 %258, ptr %2, align 8
  br label %140

259:                                              ; preds = %171
  %260 = load i64, ptr %2, align 8
  %261 = ptrtoint ptr %0 to i64
  %262 = and i64 %261, %260
  %263 = sub i64 %262, %260
  %264 = xor i64 %263, %260
  %265 = sub i64 %264, %260
  %266 = and i64 %265, %261
  store i64 %266, ptr %2, align 8
  br label %140

267:                                              ; preds = %193
  %268 = load i64, ptr %2, align 8
  %269 = ptrtoint ptr %0 to i64
  %270 = mul i64 %268, %269
  %271 = and i64 %270, %269
  %272 = add i64 %271, %268
  %273 = sub i64 %272, %269
  %274 = or i64 %273, %269
  store i64 %274, ptr %2, align 8
  br label %140

275:                                              ; preds = %205
  %276 = load i64, ptr %2, align 8
  %277 = ptrtoint ptr %0 to i64
  %278 = sub i64 %276, %277
  %279 = add i64 %278, %276
  %280 = and i64 %279, %277
  %281 = xor i64 %280, %277
  %282 = and i64 %281, %277
  store i64 %282, ptr %2, align 8
  br label %140
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @parseCartItem(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  store i64 0, ptr %4, align 8
  %5 = ptrtoint ptr %0 to i32
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  store i32 625803041, ptr %6, align 4
  br label %12

12:                                               ; preds = %368, %158, %157, %3
  %13 = load i32, ptr %6, align 4
  %14 = sub i32 %13, 835441780
  %15 = mul i32 %14, 1485684975
  switch i32 %15, label %158 [
    i32 786536323, label %16
    i32 360959130, label %32
    i32 1544337658, label %52
    i32 1843147979, label %71
    i32 1861458650, label %80
    i32 686832756, label %97
    i32 1777602313, label %108
    i32 1440771424, label %123
    i32 1010520685, label %137
    i32 1183054498, label %146
    i32 2048234934, label %155
    i32 679333130, label %168
    i32 2136872883, label %179
    i32 501352540, label %192
    i32 193446017, label %204
    i32 1225654996, label %216
    i32 805709156, label %229
    i32 937222155, label %241
    i32 1330577630, label %263
  ]

16:                                               ; preds = %12
  store ptr %0, ptr %8, align 8
  store ptr %1, ptr %9, align 8
  store ptr %2, ptr %10, align 8
  %17 = load ptr, ptr %8, align 8
  %18 = call ptr @strchr(ptr noundef %17, i32 noundef 58) #8
  store ptr %18, ptr %11, align 8
  %19 = load ptr, ptr %11, align 8
  %20 = icmp eq ptr %19, null
  %21 = select i1 %20, i32 36765050, i32 195565338
  store i32 %21, ptr %6, align 4
  %22 = xor i32 %5, 1700926763
  %23 = and i32 %5, %22
  %24 = or i32 %5, %22
  %25 = xor i32 %5, %22
  %26 = mul i32 %24, 2
  %27 = sub i32 %26, %25
  %28 = sub i32 %27, %5
  %29 = sub i32 %28, %22
  %30 = mul i32 %29, 222
  %31 = icmp slt i32 %30, 1
  br i1 %31, label %157, label %276

32:                                               ; preds = %12
  store i32 0, ptr %7, align 4
  store i32 1429327390, ptr %6, align 4
  %33 = xor i32 %5, 1952170069
  %34 = and i32 %5, %33
  %35 = or i32 %5, %33
  %36 = xor i32 %5, %33
  %37 = mul i32 %35, 2
  %38 = sub i32 %37, %36
  %39 = sub i32 %38, %5
  %40 = sub i32 %39, %33
  %41 = mul i32 %40, 247
  %42 = xor i32 %5, -687735145
  %43 = and i32 %5, %42
  %44 = or i32 %5, %42
  %45 = xor i32 %5, %42
  %46 = mul i32 %44, 2
  %47 = sub i32 %46, %45
  %48 = sub i32 %47, %5
  %49 = sub i32 %48, %42
  %50 = mul i32 %49, 195
  %51 = icmp ne i32 %41, %50
  br i1 %51, label %286, label %157

52:                                               ; preds = %12
  %53 = load ptr, ptr %11, align 8
  store i8 0, ptr %53, align 1
  %54 = load ptr, ptr %8, align 8
  call void @trim(ptr noundef %54)
  %55 = load ptr, ptr %11, align 8
  %56 = getelementptr inbounds i8, ptr %55, i64 1
  call void @trim(ptr noundef %56)
  %57 = load ptr, ptr %8, align 8
  %58 = load ptr, ptr %9, align 8
  %59 = call i32 @parseIntStrict(ptr noundef %57, ptr noundef %58)
  %60 = icmp ne i32 %59, 0
  %61 = select i1 %60, i32 -1986161862, i32 -285661607
  store i32 %61, ptr %6, align 4
  %62 = xor i32 %5, 657378445
  %63 = and i32 %5, %62
  %64 = or i32 %5, %62
  %65 = xor i32 %5, %62
  %66 = add i32 %63, %64
  %67 = sub i32 %66, %5
  %68 = sub i32 %67, %62
  %69 = mul i32 %68, 155
  %70 = icmp ne i32 %69, 0
  br i1 %70, label %294, label %157

71:                                               ; preds = %12
  store i32 0, ptr %7, align 4
  store i32 1429327390, ptr %6, align 4
  %72 = xor i32 %5, -786090237
  %73 = and i32 %5, %72
  %74 = or i32 %5, %72
  %75 = xor i32 %5, %72
  %76 = sub i32 %74, %75
  %77 = sub i32 %76, %73
  %78 = mul i32 %77, 12
  %79 = icmp slt i32 %78, 0
  br i1 %79, label %302, label %157

80:                                               ; preds = %12
  %81 = load ptr, ptr %11, align 8
  %82 = getelementptr inbounds i8, ptr %81, i64 1
  %83 = load ptr, ptr %10, align 8
  %84 = call i32 @parseIntStrict(ptr noundef %82, ptr noundef %83)
  %85 = icmp ne i32 %84, 0
  %86 = select i1 %85, i32 1872466939, i32 1906128704
  store i32 %86, ptr %6, align 4
  %87 = xor i32 %5, 857736345
  %88 = and i32 %5, %87
  %89 = or i32 %5, %87
  %90 = xor i32 %5, %87
  %91 = add i32 %5, %87
  %92 = sub i32 %91, %90
  %93 = mul i32 %88, 2
  %94 = sub i32 %92, %93
  %95 = mul i32 %94, 203
  %96 = icmp ne i32 %95, 0
  br i1 %96, label %311, label %157

97:                                               ; preds = %12
  store i32 0, ptr %7, align 4
  store i32 1429327390, ptr %6, align 4
  %98 = xor i32 %5, -1622488167
  %99 = and i32 %5, %98
  %100 = or i32 %5, %98
  %101 = xor i32 %5, %98
  %102 = add i32 %5, %98
  %103 = sub i32 %102, %101
  %104 = mul i32 %99, 2
  %105 = sub i32 %103, %104
  %106 = mul i32 %105, 55
  %107 = icmp slt i32 %106, 0
  br i1 %107, label %321, label %157

108:                                              ; preds = %12
  %109 = load ptr, ptr %9, align 8
  %110 = load i32, ptr %109, align 4
  %111 = icmp sle i32 %110, 0
  %112 = select i1 %111, i32 1160871639, i32 533822740
  store i32 %112, ptr %6, align 4
  %113 = xor i32 %5, -1140831015
  %114 = and i32 %5, %113
  %115 = or i32 %5, %113
  %116 = xor i32 %5, %113
  %117 = mul i32 %115, 2
  %118 = sub i32 %117, %116
  %119 = sub i32 %118, %5
  %120 = sub i32 %119, %113
  %121 = mul i32 %120, 71
  %122 = icmp sgt i32 %121, 0
  br i1 %122, label %332, label %157

123:                                              ; preds = %12
  %124 = load ptr, ptr %10, align 8
  %125 = load i32, ptr %124, align 4
  %126 = icmp sle i32 %125, 0
  %127 = select i1 %126, i32 1160871639, i32 438509554
  store i32 %127, ptr %6, align 4
  %128 = xor i32 %5, 1567770529
  %129 = and i32 %5, %128
  %130 = or i32 %5, %128
  %131 = xor i32 %5, %128
  %132 = add i32 %129, %130
  %133 = sub i32 %132, %5
  %134 = sub i32 %133, %128
  %135 = mul i32 %134, 100
  %136 = icmp slt i32 %135, 0
  br i1 %136, label %340, label %157

137:                                              ; preds = %12
  store i32 0, ptr %7, align 4
  store i32 1429327390, ptr %6, align 4
  %138 = xor i32 %5, -1467712539
  %139 = and i32 %5, %138
  %140 = or i32 %5, %138
  %141 = xor i32 %5, %138
  %142 = sub i32 %140, %141
  %143 = sub i32 %142, %139
  %144 = mul i32 %143, 123
  %145 = icmp sle i32 %144, 0
  br i1 %145, label %157, label %350

146:                                              ; preds = %12
  store i32 1, ptr %7, align 4
  store i32 1429327390, ptr %6, align 4
  %147 = xor i32 %5, -757210195
  %148 = and i32 %5, %147
  %149 = or i32 %5, %147
  %150 = xor i32 %5, %147
  %151 = sub i32 %149, %150
  %152 = sub i32 %151, %148
  %153 = mul i32 %152, 197
  %154 = icmp eq i32 %153, 0
  br i1 %154, label %157, label %358

155:                                              ; preds = %12
  %156 = load i32, ptr %7, align 4
  ret i32 %156

157:                                              ; preds = %448, %437, %429, %420, %410, %401, %390, %379, %358, %350, %340, %332, %321, %311, %302, %294, %286, %276, %263, %241, %229, %216, %204, %192, %179, %168, %146, %137, %123, %108, %97, %80, %71, %52, %32, %16
  br label %12

158:                                              ; preds = %12
  store i32 625803041, ptr %6, align 4
  call void asm sideeffect "", ""()
  %159 = xor i32 %5, 2044669851
  %160 = and i32 %5, %159
  %161 = or i32 %5, %159
  %162 = xor i32 %5, %159
  %163 = add i32 %160, %161
  %164 = sub i32 %163, %5
  %165 = sub i32 %164, %159
  %166 = mul i32 %165, 42
  %167 = icmp sle i32 %166, 0
  br i1 %167, label %12, label %368

168:                                              ; preds = %12
  %169 = load i32, ptr %6, align 4
  %170 = xor i32 %169, -1554600794
  store i32 %170, ptr %6, align 4
  %171 = xor i32 %5, 684788445
  %172 = and i32 %5, %171
  %173 = or i32 %5, %171
  %174 = xor i32 %5, %171
  %175 = sub i32 %173, %174
  %176 = sub i32 %175, %172
  %177 = mul i32 %176, 223
  %178 = icmp eq i32 %177, 0
  br i1 %178, label %157, label %379

179:                                              ; preds = %12
  %180 = load i32, ptr %6, align 4
  %181 = xor i32 %180, 736465320
  store i32 %181, ptr %6, align 4
  %182 = xor i32 %5, 982371299
  %183 = and i32 %5, %182
  %184 = or i32 %5, %182
  %185 = xor i32 %5, %182
  %186 = mul i32 %184, 2
  %187 = sub i32 %186, %185
  %188 = sub i32 %187, %5
  %189 = sub i32 %188, %182
  %190 = mul i32 %189, 83
  %191 = icmp slt i32 %190, 1
  br i1 %191, label %157, label %390

192:                                              ; preds = %12
  %193 = load i32, ptr %6, align 4
  %194 = xor i32 %193, -201336436
  store i32 %194, ptr %6, align 4
  %195 = xor i32 %5, -273480029
  %196 = and i32 %5, %195
  %197 = or i32 %5, %195
  %198 = xor i32 %5, %195
  %199 = add i32 %196, %197
  %200 = sub i32 %199, %5
  %201 = sub i32 %200, %195
  %202 = mul i32 %201, 78
  %203 = icmp ugt i32 %202, 0
  br i1 %203, label %401, label %157

204:                                              ; preds = %12
  %205 = load i32, ptr %6, align 4
  %206 = xor i32 %205, -1386171251
  store i32 %206, ptr %6, align 4
  %207 = xor i32 %5, 950192031
  %208 = and i32 %5, %207
  %209 = or i32 %5, %207
  %210 = xor i32 %5, %207
  %211 = add i32 %208, %209
  %212 = sub i32 %211, %5
  %213 = sub i32 %212, %207
  %214 = mul i32 %213, 193
  %215 = icmp eq i32 %214, 0
  br i1 %215, label %157, label %410

216:                                              ; preds = %12
  %217 = load i32, ptr %6, align 4
  %218 = xor i32 %217, -572171021
  store i32 %218, ptr %6, align 4
  %219 = xor i32 %5, -1722375329
  %220 = and i32 %5, %219
  %221 = or i32 %5, %219
  %222 = xor i32 %5, %219
  %223 = mul i32 %221, 2
  %224 = sub i32 %223, %222
  %225 = sub i32 %224, %5
  %226 = sub i32 %225, %219
  %227 = mul i32 %226, 225
  %228 = icmp uge i32 %227, 0
  br i1 %228, label %157, label %420

229:                                              ; preds = %12
  %230 = load i32, ptr %6, align 4
  %231 = xor i32 %230, 1539413442
  store i32 %231, ptr %6, align 4
  %232 = xor i32 %5, -1245889335
  %233 = and i32 %5, %232
  %234 = or i32 %5, %232
  %235 = xor i32 %5, %232
  %236 = add i32 %233, %234
  %237 = sub i32 %236, %5
  %238 = sub i32 %237, %232
  %239 = mul i32 %238, 43
  %240 = icmp eq i32 %239, 0
  br i1 %240, label %157, label %429

241:                                              ; preds = %12
  %242 = load i32, ptr %6, align 4
  %243 = xor i32 %242, -838724272
  store i32 %243, ptr %6, align 4
  %244 = xor i32 %5, 1922644849
  %245 = and i32 %5, %244
  %246 = or i32 %5, %244
  %247 = xor i32 %5, %244
  %248 = mul i32 %246, 2
  %249 = sub i32 %248, %247
  %250 = sub i32 %249, %5
  %251 = sub i32 %250, %244
  %252 = mul i32 %251, 59
  %253 = xor i32 %5, -1674664401
  %254 = and i32 %5, %253
  %255 = or i32 %5, %253
  %256 = xor i32 %5, %253
  %257 = mul i32 %255, 2
  %258 = sub i32 %257, %256
  %259 = sub i32 %258, %5
  %260 = sub i32 %259, %253
  %261 = mul i32 %260, 146
  %262 = icmp ne i32 %252, %261
  br i1 %262, label %437, label %157

263:                                              ; preds = %12
  %264 = load i32, ptr %6, align 4
  %265 = xor i32 %264, 1505215749
  store i32 %265, ptr %6, align 4
  %266 = xor i32 %5, -481034827
  %267 = and i32 %5, %266
  %268 = or i32 %5, %266
  %269 = xor i32 %5, %266
  %270 = add i32 %5, %266
  %271 = sub i32 %270, %269
  %272 = mul i32 %267, 2
  %273 = sub i32 %271, %272
  %274 = mul i32 %273, 233
  %275 = icmp slt i32 %274, 1
  br i1 %275, label %157, label %448

276:                                              ; preds = %16
  %277 = load i64, ptr %4, align 8
  %278 = ptrtoint ptr %0 to i64
  %279 = ptrtoint ptr %1 to i64
  %280 = ptrtoint ptr %2 to i64
  %281 = add i64 %279, %280
  %282 = sub i64 %281, %280
  %283 = xor i64 %282, %277
  %284 = sub i64 %283, %277
  %285 = or i64 %284, %280
  store i64 %285, ptr %4, align 8
  br label %157

286:                                              ; preds = %32
  %287 = load i64, ptr %4, align 8
  %288 = ptrtoint ptr %0 to i64
  %289 = ptrtoint ptr %1 to i64
  %290 = ptrtoint ptr %2 to i64
  %291 = sub i64 %290, %289
  %292 = xor i64 %291, %287
  %293 = and i64 %292, %287
  store i64 %293, ptr %4, align 8
  br label %157

294:                                              ; preds = %52
  %295 = load i64, ptr %4, align 8
  %296 = ptrtoint ptr %0 to i64
  %297 = ptrtoint ptr %1 to i64
  %298 = ptrtoint ptr %2 to i64
  %299 = or i64 %298, %298
  %300 = or i64 %299, %296
  %301 = and i64 %300, %295
  store i64 %301, ptr %4, align 8
  br label %157

302:                                              ; preds = %71
  %303 = load i64, ptr %4, align 8
  %304 = ptrtoint ptr %0 to i64
  %305 = ptrtoint ptr %1 to i64
  %306 = ptrtoint ptr %2 to i64
  %307 = sub i64 %305, %306
  %308 = add i64 %307, %305
  %309 = add i64 %308, %305
  %310 = sub i64 %309, %303
  store i64 %310, ptr %4, align 8
  br label %157

311:                                              ; preds = %80
  %312 = load i64, ptr %4, align 8
  %313 = ptrtoint ptr %0 to i64
  %314 = ptrtoint ptr %1 to i64
  %315 = ptrtoint ptr %2 to i64
  %316 = mul i64 %314, %315
  %317 = or i64 %316, %314
  %318 = xor i64 %317, %313
  %319 = add i64 %318, %312
  %320 = add i64 %319, %312
  store i64 %320, ptr %4, align 8
  br label %157

321:                                              ; preds = %97
  %322 = load i64, ptr %4, align 8
  %323 = ptrtoint ptr %0 to i64
  %324 = ptrtoint ptr %1 to i64
  %325 = ptrtoint ptr %2 to i64
  %326 = mul i64 %325, %322
  %327 = sub i64 %326, %322
  %328 = mul i64 %327, %322
  %329 = or i64 %328, %325
  %330 = mul i64 %329, %324
  %331 = sub i64 %330, %325
  store i64 %331, ptr %4, align 8
  br label %157

332:                                              ; preds = %108
  %333 = load i64, ptr %4, align 8
  %334 = ptrtoint ptr %0 to i64
  %335 = ptrtoint ptr %1 to i64
  %336 = ptrtoint ptr %2 to i64
  %337 = or i64 %336, %334
  %338 = xor i64 %337, %336
  %339 = and i64 %338, %334
  store i64 %339, ptr %4, align 8
  br label %157

340:                                              ; preds = %123
  %341 = load i64, ptr %4, align 8
  %342 = ptrtoint ptr %0 to i64
  %343 = ptrtoint ptr %1 to i64
  %344 = ptrtoint ptr %2 to i64
  %345 = sub i64 %342, %341
  %346 = or i64 %345, %341
  %347 = add i64 %346, %343
  %348 = sub i64 %347, %341
  %349 = sub i64 %348, %344
  store i64 %349, ptr %4, align 8
  br label %157

350:                                              ; preds = %137
  %351 = load i64, ptr %4, align 8
  %352 = ptrtoint ptr %0 to i64
  %353 = ptrtoint ptr %1 to i64
  %354 = ptrtoint ptr %2 to i64
  %355 = mul i64 %352, %353
  %356 = mul i64 %355, %354
  %357 = xor i64 %356, %353
  store i64 %357, ptr %4, align 8
  br label %157

358:                                              ; preds = %146
  %359 = load i64, ptr %4, align 8
  %360 = ptrtoint ptr %0 to i64
  %361 = ptrtoint ptr %1 to i64
  %362 = ptrtoint ptr %2 to i64
  %363 = and i64 %359, %361
  %364 = mul i64 %363, %362
  %365 = add i64 %364, %360
  %366 = sub i64 %365, %361
  %367 = xor i64 %366, %360
  store i64 %367, ptr %4, align 8
  br label %157

368:                                              ; preds = %158
  %369 = load i64, ptr %4, align 8
  %370 = ptrtoint ptr %0 to i64
  %371 = ptrtoint ptr %1 to i64
  %372 = ptrtoint ptr %2 to i64
  %373 = mul i64 %370, %372
  %374 = sub i64 %373, %370
  %375 = sub i64 %374, %370
  %376 = and i64 %375, %372
  %377 = and i64 %376, %372
  %378 = add i64 %377, %370
  store i64 %378, ptr %4, align 8
  br label %12

379:                                              ; preds = %168
  %380 = load i64, ptr %4, align 8
  %381 = ptrtoint ptr %0 to i64
  %382 = ptrtoint ptr %1 to i64
  %383 = ptrtoint ptr %2 to i64
  %384 = sub i64 %380, %381
  %385 = or i64 %384, %380
  %386 = mul i64 %385, %381
  %387 = or i64 %386, %381
  %388 = sub i64 %387, %382
  %389 = add i64 %388, %382
  store i64 %389, ptr %4, align 8
  br label %157

390:                                              ; preds = %179
  %391 = load i64, ptr %4, align 8
  %392 = ptrtoint ptr %0 to i64
  %393 = ptrtoint ptr %1 to i64
  %394 = ptrtoint ptr %2 to i64
  %395 = add i64 %394, %394
  %396 = xor i64 %395, %392
  %397 = xor i64 %396, %392
  %398 = add i64 %397, %391
  %399 = and i64 %398, %394
  %400 = sub i64 %399, %394
  store i64 %400, ptr %4, align 8
  br label %157

401:                                              ; preds = %192
  %402 = load i64, ptr %4, align 8
  %403 = ptrtoint ptr %0 to i64
  %404 = ptrtoint ptr %1 to i64
  %405 = ptrtoint ptr %2 to i64
  %406 = or i64 %405, %404
  %407 = xor i64 %406, %404
  %408 = sub i64 %407, %405
  %409 = or i64 %408, %403
  store i64 %409, ptr %4, align 8
  br label %157

410:                                              ; preds = %204
  %411 = load i64, ptr %4, align 8
  %412 = ptrtoint ptr %0 to i64
  %413 = ptrtoint ptr %1 to i64
  %414 = ptrtoint ptr %2 to i64
  %415 = xor i64 %414, %412
  %416 = mul i64 %415, %412
  %417 = sub i64 %416, %413
  %418 = sub i64 %417, %412
  %419 = sub i64 %418, %413
  store i64 %419, ptr %4, align 8
  br label %157

420:                                              ; preds = %216
  %421 = load i64, ptr %4, align 8
  %422 = ptrtoint ptr %0 to i64
  %423 = ptrtoint ptr %1 to i64
  %424 = ptrtoint ptr %2 to i64
  %425 = mul i64 %421, %424
  %426 = mul i64 %425, %424
  %427 = or i64 %426, %424
  %428 = xor i64 %427, %421
  store i64 %428, ptr %4, align 8
  br label %157

429:                                              ; preds = %229
  %430 = load i64, ptr %4, align 8
  %431 = ptrtoint ptr %0 to i64
  %432 = ptrtoint ptr %1 to i64
  %433 = ptrtoint ptr %2 to i64
  %434 = and i64 %432, %430
  %435 = mul i64 %434, %431
  %436 = and i64 %435, %431
  store i64 %436, ptr %4, align 8
  br label %157

437:                                              ; preds = %241
  %438 = load i64, ptr %4, align 8
  %439 = ptrtoint ptr %0 to i64
  %440 = ptrtoint ptr %1 to i64
  %441 = ptrtoint ptr %2 to i64
  %442 = xor i64 %441, %439
  %443 = sub i64 %442, %438
  %444 = mul i64 %443, %440
  %445 = sub i64 %444, %439
  %446 = and i64 %445, %440
  %447 = add i64 %446, %441
  store i64 %447, ptr %4, align 8
  br label %157

448:                                              ; preds = %263
  %449 = load i64, ptr %4, align 8
  %450 = ptrtoint ptr %0 to i64
  %451 = ptrtoint ptr %1 to i64
  %452 = ptrtoint ptr %2 to i64
  %453 = add i64 %450, %450
  %454 = add i64 %453, %452
  %455 = mul i64 %454, %451
  %456 = and i64 %455, %450
  store i64 %456, ptr %4, align 8
  br label %157
}

; Function Attrs: nounwind willreturn memory(read)
declare ptr @strchr(ptr noundef, i32 noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @cartAlreadyHas(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 167715004, ptr %4, align 4
  br label %9

9:                                                ; preds = %263, %103, %102, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, 940183923
  %12 = mul i32 %11, -908641379
  switch i32 %12, label %103 [
    i32 1696543429, label %13
    i32 45492899, label %24
    i32 1331943656, label %41
    i32 1373771711, label %60
    i32 1221358537, label %72
    i32 2141902804, label %91
    i32 1403330855, label %100
    i32 2115160313, label %114
    i32 1598642439, label %126
    i32 1433809583, label %137
    i32 690296601, label %156
    i32 292719570, label %168
    i32 1015508105, label %179
    i32 1341617551, label %192
  ]

13:                                               ; preds = %9
  store ptr %0, ptr %6, align 8
  store i32 %1, ptr %7, align 4
  store i32 0, ptr %8, align 4
  store i32 -778576718, ptr %4, align 4
  %14 = xor i32 %1, 460551431
  %15 = and i32 %1, %14
  %16 = or i32 %1, %14
  %17 = xor i32 %1, %14
  %18 = mul i32 %16, 2
  %19 = sub i32 %18, %17
  %20 = sub i32 %19, %1
  %21 = sub i32 %20, %14
  %22 = mul i32 %21, 253
  %23 = icmp sgt i32 %22, 0
  br i1 %23, label %212, label %102

24:                                               ; preds = %9
  %25 = load i32, ptr %8, align 4
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Order, ptr %26, i32 0, i32 4
  %28 = load i32, ptr %27, align 8
  %29 = icmp slt i32 %25, %28
  %30 = select i1 %29, i32 598818171, i32 1260311127
  store i32 %30, ptr %4, align 4
  %31 = xor i32 %1, -1451222825
  %32 = and i32 %1, %31
  %33 = or i32 %1, %31
  %34 = xor i32 %1, %31
  %35 = add i32 %1, %31
  %36 = sub i32 %35, %34
  %37 = mul i32 %32, 2
  %38 = sub i32 %36, %37
  %39 = mul i32 %38, 220
  %40 = icmp ne i32 %39, 0
  br i1 %40, label %219, label %102

41:                                               ; preds = %9
  %42 = load ptr, ptr %6, align 8
  %43 = getelementptr inbounds nuw %struct.Order, ptr %42, i32 0, i32 3
  %44 = load i32, ptr %8, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds [64 x %struct.OrderItem], ptr %43, i64 0, i64 %45
  %47 = getelementptr inbounds nuw %struct.OrderItem, ptr %46, i32 0, i32 0
  %48 = load i32, ptr %47, align 8
  %49 = load i32, ptr %7, align 4
  %50 = icmp eq i32 %48, %49
  %51 = select i1 %50, i32 704919934, i32 -297754480
  store i32 %51, ptr %4, align 4
  %52 = xor i32 %1, 892842007
  %53 = and i32 %1, %52
  %54 = or i32 %1, %52
  %55 = xor i32 %1, %52
  %56 = sub i32 %54, %55
  %57 = sub i32 %56, %53
  %58 = mul i32 %57, 223
  %59 = icmp sle i32 %58, 0
  br i1 %59, label %102, label %228

60:                                               ; preds = %9
  %61 = load i32, ptr %8, align 4
  store i32 %61, ptr %5, align 4
  store i32 1533652998, ptr %4, align 4
  %62 = xor i32 %1, 878212641
  %63 = and i32 %1, %62
  %64 = or i32 %1, %62
  %65 = xor i32 %1, %62
  %66 = mul i32 %64, 2
  %67 = sub i32 %66, %65
  %68 = sub i32 %67, %1
  %69 = sub i32 %68, %62
  %70 = mul i32 %69, 126
  %71 = icmp sgt i32 %70, 0
  br i1 %71, label %235, label %102

72:                                               ; preds = %9
  %73 = load i32, ptr %8, align 4
  %74 = load i32, ptr %4, align 4
  %75 = xor i32 %74, -297754479
  %76 = xor i32 %73, %75
  %77 = load i32, ptr %4, align 4
  %78 = xor i32 %77, -297754479
  %79 = and i32 %73, %78
  %80 = add i32 %79, %79
  %81 = add i32 %76, %80
  store i32 %81, ptr %8, align 4
  store i32 -778576718, ptr %4, align 4
  %82 = xor i32 %1, -926320697
  %83 = and i32 %1, %82
  %84 = or i32 %1, %82
  %85 = xor i32 %1, %82
  %86 = add i32 %83, %84
  %87 = sub i32 %86, %1
  %88 = sub i32 %87, %82
  %89 = mul i32 %88, 31
  %90 = icmp slt i32 %89, 0
  br i1 %90, label %244, label %102

91:                                               ; preds = %9
  store i32 -1, ptr %5, align 4
  store i32 1533652998, ptr %4, align 4
  %92 = xor i32 %1, 189039931
  %93 = and i32 %1, %92
  %94 = or i32 %1, %92
  %95 = xor i32 %1, %92
  %96 = sub i32 %94, %95
  %97 = sub i32 %96, %93
  %98 = mul i32 %97, 61
  %99 = icmp ne i32 %98, 0
  br i1 %99, label %253, label %102

100:                                              ; preds = %9
  %101 = load i32, ptr %5, align 4
  ret i32 %101

102:                                              ; preds = %320, %313, %305, %298, %288, %279, %271, %253, %244, %235, %228, %219, %212, %192, %179, %168, %156, %137, %126, %114, %91, %72, %60, %41, %24, %13
  br label %9

103:                                              ; preds = %9
  store i32 167715004, ptr %4, align 4
  call void asm sideeffect "", ""()
  %104 = xor i32 %1, -257182263
  %105 = and i32 %1, %104
  %106 = or i32 %1, %104
  %107 = xor i32 %1, %104
  %108 = add i32 %1, %104
  %109 = sub i32 %108, %107
  %110 = mul i32 %105, 2
  %111 = sub i32 %109, %110
  %112 = mul i32 %111, 232
  %113 = icmp slt i32 %112, 1
  br i1 %113, label %9, label %263

114:                                              ; preds = %9
  %115 = load i32, ptr %4, align 4
  %116 = xor i32 %115, 1958598378
  store i32 %116, ptr %4, align 4
  %117 = xor i32 %1, 837063365
  %118 = and i32 %1, %117
  %119 = or i32 %1, %117
  %120 = xor i32 %1, %117
  %121 = add i32 %118, %119
  %122 = sub i32 %121, %1
  %123 = sub i32 %122, %117
  %124 = mul i32 %123, 28
  %125 = icmp eq i32 %124, 0
  br i1 %125, label %102, label %271

126:                                              ; preds = %9
  %127 = load i32, ptr %4, align 4
  %128 = xor i32 %127, 1908382768
  store i32 %128, ptr %4, align 4
  %129 = xor i32 %1, -2084342579
  %130 = and i32 %1, %129
  %131 = or i32 %1, %129
  %132 = xor i32 %1, %129
  %133 = sub i32 %131, %132
  %134 = sub i32 %133, %130
  %135 = mul i32 %134, 146
  %136 = icmp sle i32 %135, 0
  br i1 %136, label %102, label %279

137:                                              ; preds = %9
  %138 = load i32, ptr %4, align 4
  %139 = xor i32 %138, 557669780
  store i32 %139, ptr %4, align 4
  %140 = xor i32 %1, 614519729
  %141 = and i32 %1, %140
  %142 = or i32 %1, %140
  %143 = xor i32 %1, %140
  %144 = add i32 %141, %142
  %145 = sub i32 %144, %1
  %146 = sub i32 %145, %140
  %147 = mul i32 %146, 164
  %148 = xor i32 %1, -2020202705
  %149 = and i32 %1, %148
  %150 = or i32 %1, %148
  %151 = xor i32 %1, %148
  %152 = sub i32 %150, %151
  %153 = sub i32 %152, %149
  %154 = mul i32 %153, 69
  %155 = icmp ne i32 %147, %154
  br i1 %155, label %288, label %102

156:                                              ; preds = %9
  %157 = load i32, ptr %4, align 4
  %158 = xor i32 %157, -1343414136
  store i32 %158, ptr %4, align 4
  %159 = xor i32 %1, -2077546599
  %160 = and i32 %1, %159
  %161 = or i32 %1, %159
  %162 = xor i32 %1, %159
  %163 = add i32 %160, %161
  %164 = sub i32 %163, %1
  %165 = sub i32 %164, %159
  %166 = mul i32 %165, 200
  %167 = icmp ugt i32 %166, 0
  br i1 %167, label %298, label %102

168:                                              ; preds = %9
  %169 = load i32, ptr %4, align 4
  %170 = xor i32 %169, -2063781711
  store i32 %170, ptr %4, align 4
  %171 = xor i32 %1, -257080925
  %172 = and i32 %1, %171
  %173 = or i32 %1, %171
  %174 = xor i32 %1, %171
  %175 = sub i32 %173, %174
  %176 = sub i32 %175, %172
  %177 = mul i32 %176, 35
  %178 = icmp sle i32 %177, 0
  br i1 %178, label %102, label %305

179:                                              ; preds = %9
  %180 = load i32, ptr %4, align 4
  %181 = xor i32 %180, -1600301933
  store i32 %181, ptr %4, align 4
  %182 = xor i32 %1, -675550685
  %183 = and i32 %1, %182
  %184 = or i32 %1, %182
  %185 = xor i32 %1, %182
  %186 = mul i32 %184, 2
  %187 = sub i32 %186, %185
  %188 = sub i32 %187, %1
  %189 = sub i32 %188, %182
  %190 = mul i32 %189, 55
  %191 = icmp sgt i32 %190, 0
  br i1 %191, label %313, label %102

192:                                              ; preds = %9
  %193 = load i32, ptr %4, align 4
  %194 = xor i32 %193, 1887708230
  store i32 %194, ptr %4, align 4
  %195 = xor i32 %1, 735919305
  %196 = and i32 %1, %195
  %197 = or i32 %1, %195
  %198 = xor i32 %1, %195
  %199 = sub i32 %197, %198
  %200 = sub i32 %199, %196
  %201 = mul i32 %200, 54
  %202 = xor i32 %1, -1602818039
  %203 = and i32 %1, %202
  %204 = or i32 %1, %202
  %205 = xor i32 %1, %202
  %206 = add i32 %1, %202
  %207 = sub i32 %206, %205
  %208 = mul i32 %203, 2
  %209 = sub i32 %207, %208
  %210 = mul i32 %209, 166
  %211 = icmp ne i32 %201, %210
  br i1 %211, label %320, label %102

212:                                              ; preds = %13
  %213 = load i64, ptr %3, align 8
  %214 = ptrtoint ptr %0 to i64
  %215 = zext i32 %1 to i64
  %216 = sub i64 %215, %214
  %217 = add i64 %216, %215
  %218 = add i64 %217, %214
  store i64 %218, ptr %3, align 8
  br label %102

219:                                              ; preds = %24
  %220 = load i64, ptr %3, align 8
  %221 = ptrtoint ptr %0 to i64
  %222 = zext i32 %1 to i64
  %223 = and i64 %222, %221
  %224 = and i64 %223, %222
  %225 = sub i64 %224, %222
  %226 = mul i64 %225, %221
  %227 = xor i64 %226, %220
  store i64 %227, ptr %3, align 8
  br label %102

228:                                              ; preds = %41
  %229 = load i64, ptr %3, align 8
  %230 = ptrtoint ptr %0 to i64
  %231 = zext i32 %1 to i64
  %232 = or i64 %231, %229
  %233 = and i64 %232, %230
  %234 = or i64 %233, %229
  store i64 %234, ptr %3, align 8
  br label %102

235:                                              ; preds = %60
  %236 = load i64, ptr %3, align 8
  %237 = ptrtoint ptr %0 to i64
  %238 = zext i32 %1 to i64
  %239 = add i64 %237, %236
  %240 = sub i64 %239, %236
  %241 = sub i64 %240, %237
  %242 = and i64 %241, %238
  %243 = mul i64 %242, %236
  store i64 %243, ptr %3, align 8
  br label %102

244:                                              ; preds = %72
  %245 = load i64, ptr %3, align 8
  %246 = ptrtoint ptr %0 to i64
  %247 = zext i32 %1 to i64
  %248 = and i64 %247, %247
  %249 = or i64 %248, %245
  %250 = xor i64 %249, %247
  %251 = add i64 %250, %247
  %252 = and i64 %251, %247
  store i64 %252, ptr %3, align 8
  br label %102

253:                                              ; preds = %91
  %254 = load i64, ptr %3, align 8
  %255 = ptrtoint ptr %0 to i64
  %256 = zext i32 %1 to i64
  %257 = sub i64 %254, %254
  %258 = and i64 %257, %256
  %259 = and i64 %258, %256
  %260 = mul i64 %259, %256
  %261 = or i64 %260, %254
  %262 = add i64 %261, %255
  store i64 %262, ptr %3, align 8
  br label %102

263:                                              ; preds = %103
  %264 = load i64, ptr %3, align 8
  %265 = ptrtoint ptr %0 to i64
  %266 = zext i32 %1 to i64
  %267 = add i64 %264, %264
  %268 = mul i64 %267, %264
  %269 = and i64 %268, %266
  %270 = add i64 %269, %264
  store i64 %270, ptr %3, align 8
  br label %9

271:                                              ; preds = %114
  %272 = load i64, ptr %3, align 8
  %273 = ptrtoint ptr %0 to i64
  %274 = zext i32 %1 to i64
  %275 = sub i64 %273, %274
  %276 = mul i64 %275, %272
  %277 = or i64 %276, %272
  %278 = mul i64 %277, %272
  store i64 %278, ptr %3, align 8
  br label %102

279:                                              ; preds = %126
  %280 = load i64, ptr %3, align 8
  %281 = ptrtoint ptr %0 to i64
  %282 = zext i32 %1 to i64
  %283 = add i64 %281, %280
  %284 = sub i64 %283, %280
  %285 = sub i64 %284, %281
  %286 = or i64 %285, %281
  %287 = or i64 %286, %280
  store i64 %287, ptr %3, align 8
  br label %102

288:                                              ; preds = %137
  %289 = load i64, ptr %3, align 8
  %290 = ptrtoint ptr %0 to i64
  %291 = zext i32 %1 to i64
  %292 = add i64 %289, %289
  %293 = add i64 %292, %290
  %294 = and i64 %293, %289
  %295 = or i64 %294, %291
  %296 = or i64 %295, %291
  %297 = or i64 %296, %290
  store i64 %297, ptr %3, align 8
  br label %102

298:                                              ; preds = %156
  %299 = load i64, ptr %3, align 8
  %300 = ptrtoint ptr %0 to i64
  %301 = zext i32 %1 to i64
  %302 = mul i64 %299, %301
  %303 = sub i64 %302, %299
  %304 = and i64 %303, %300
  store i64 %304, ptr %3, align 8
  br label %102

305:                                              ; preds = %168
  %306 = load i64, ptr %3, align 8
  %307 = ptrtoint ptr %0 to i64
  %308 = zext i32 %1 to i64
  %309 = sub i64 %306, %308
  %310 = or i64 %309, %307
  %311 = add i64 %310, %307
  %312 = sub i64 %311, %307
  store i64 %312, ptr %3, align 8
  br label %102

313:                                              ; preds = %179
  %314 = load i64, ptr %3, align 8
  %315 = ptrtoint ptr %0 to i64
  %316 = zext i32 %1 to i64
  %317 = and i64 %314, %316
  %318 = and i64 %317, %315
  %319 = xor i64 %318, %314
  store i64 %319, ptr %3, align 8
  br label %102

320:                                              ; preds = %192
  %321 = load i64, ptr %3, align 8
  %322 = ptrtoint ptr %0 to i64
  %323 = zext i32 %1 to i64
  %324 = and i64 %321, %322
  %325 = sub i64 %324, %322
  %326 = and i64 %325, %322
  store i64 %326, ptr %3, align 8
  br label %102
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdBuy(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca %struct.Order, align 8
  %8 = alloca [2048 x i8], align 16
  %9 = alloca ptr, align 8
  %10 = alloca i64, align 8
  %11 = alloca i64, align 8
  %12 = alloca i64, align 8
  %13 = alloca i64, align 8
  %14 = alloca [1000 x i32], align 16
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  %18 = alloca i32, align 4
  %19 = alloca i32, align 4
  store i32 416623745, ptr %4, align 4
  br label %20

20:                                               ; preds = %1392, %922, %921, %2
  %21 = load i32, ptr %4, align 4
  %22 = sub i32 %21, -2140038082
  %23 = mul i32 %22, 816915965
  switch i32 %23, label %922 [
    i32 1284653367, label %24
    i32 2073354131, label %36
    i32 1390006005, label %48
    i32 526520548, label %64
    i32 1550137787, label %80
    i32 444453446, label %90
    i32 40409147, label %106
    i32 306140787, label %132
    i32 321235421, label %143
    i32 277793399, label %169
    i32 1956750706, label %180
    i32 1291551428, label %203
    i32 1860767281, label %215
    i32 847607621, label %233
    i32 1102802817, label %248
    i32 1878647280, label %278
    i32 1438504720, label %300
    i32 468849472, label %316
    i32 1329936428, label %334
    i32 149660199, label %348
    i32 1369431500, label %371
    i32 1448574307, label %392
    i32 537610834, label %422
    i32 1347954906, label %462
    i32 556261658, label %477
    i32 1654831542, label %517
    i32 934877294, label %540
    i32 1421462568, label %550
    i32 1481315063, label %623
    i32 250725529, label %656
    i32 607684209, label %670
    i32 1542137346, label %691
    i32 906207186, label %767
    i32 1144489140, label %781
    i32 536453565, label %797
    i32 912042976, label %839
    i32 418564823, label %857
    i32 249997635, label %888
    i32 2033838008, label %901
    i32 1132088077, label %920
    i32 379152925, label %941
    i32 389903305, label %953
    i32 1839683124, label %974
    i32 1355577645, label %987
    i32 688951589, label %1000
    i32 556862485, label %1011
    i32 1042257432, label %1022
    i32 1909509958, label %1044
  ]

24:                                               ; preds = %20
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i64 0, ptr %10, align 8
  %25 = load i32, ptr %6, align 4
  %26 = icmp ne i32 %25, 4
  %27 = select i1 %26, i32 1295639821, i32 285851287
  store i32 %27, ptr %4, align 4
  %28 = xor i32 %1, 388577033
  %29 = and i32 %1, %28
  %30 = or i32 %1, %28
  %31 = xor i32 %1, %28
  %32 = sub i32 %30, %31
  %33 = sub i32 %32, %29
  %34 = mul i32 %33, 28
  %35 = icmp ugt i32 %34, 0
  br i1 %35, label %1057, label %921

36:                                               ; preds = %20
  %37 = call i32 (ptr, ...) @printf(ptr noundef @.str.67)
  store i32 498326159, ptr %4, align 4
  %38 = xor i32 %1, -1025465715
  %39 = and i32 %1, %38
  %40 = or i32 %1, %38
  %41 = xor i32 %1, %38
  %42 = mul i32 %40, 2
  %43 = sub i32 %42, %41
  %44 = sub i32 %43, %1
  %45 = sub i32 %44, %38
  %46 = mul i32 %45, 184
  %47 = icmp sgt i32 %46, 0
  br i1 %47, label %1065, label %921

48:                                               ; preds = %20
  %49 = load ptr, ptr %5, align 8
  %50 = getelementptr inbounds ptr, ptr %49, i64 1
  %51 = load ptr, ptr %50, align 8
  %52 = call i64 @strlen(ptr noundef %51) #8
  %53 = icmp eq i64 %52, 0
  %54 = select i1 %53, i32 -1066881963, i32 -572271630
  store i32 %54, ptr %4, align 4
  %55 = xor i32 %1, -387293889
  %56 = and i32 %1, %55
  %57 = or i32 %1, %55
  %58 = xor i32 %1, %55
  %59 = add i32 %56, %57
  %60 = sub i32 %59, %1
  %61 = sub i32 %60, %55
  %62 = mul i32 %61, 202
  %63 = icmp sle i32 %62, 0
  br i1 %63, label %921, label %1074

64:                                               ; preds = %20
  %65 = load ptr, ptr %5, align 8
  %66 = getelementptr inbounds ptr, ptr %65, i64 1
  %67 = load ptr, ptr %66, align 8
  %68 = call i64 @strlen(ptr noundef %67) #8
  %69 = icmp uge i64 %68, 80
  %70 = select i1 %69, i32 -1066881963, i32 1593141116
  store i32 %70, ptr %4, align 4
  %71 = xor i32 %1, 1398999997
  %72 = and i32 %1, %71
  %73 = or i32 %1, %71
  %74 = xor i32 %1, %71
  %75 = add i32 %72, %73
  %76 = sub i32 %75, %1
  %77 = sub i32 %76, %71
  %78 = mul i32 %77, 138
  %79 = icmp sle i32 %78, 0
  br i1 %79, label %921, label %1082

80:                                               ; preds = %20
  %81 = call i32 (ptr, ...) @printf(ptr noundef @.str.68)
  store i32 498326159, ptr %4, align 4
  %82 = xor i32 %1, -1456494467
  %83 = and i32 %1, %82
  %84 = or i32 %1, %82
  %85 = xor i32 %1, %82
  %86 = sub i32 %84, %85
  %87 = sub i32 %86, %83
  %88 = mul i32 %87, 177
  %89 = icmp slt i32 %88, 0
  br i1 %89, label %1092, label %921

90:                                               ; preds = %20
  %91 = load ptr, ptr %5, align 8
  %92 = getelementptr inbounds ptr, ptr %91, i64 2
  %93 = load ptr, ptr %92, align 8
  %94 = call i64 @strlen(ptr noundef %93) #8
  %95 = icmp eq i64 %94, 0
  %96 = select i1 %95, i32 1644199277, i32 2052623573
  store i32 %96, ptr %4, align 4
  %97 = xor i32 %1, 1176801953
  %98 = and i32 %1, %97
  %99 = or i32 %1, %97
  %100 = xor i32 %1, %97
  %101 = add i32 %98, %99
  %102 = sub i32 %101, %1
  %103 = sub i32 %102, %97
  %104 = mul i32 %103, 203
  %105 = icmp ugt i32 %104, 0
  br i1 %105, label %1102, label %921

106:                                              ; preds = %20
  %107 = load ptr, ptr %5, align 8
  %108 = getelementptr inbounds ptr, ptr %107, i64 2
  %109 = load ptr, ptr %108, align 8
  %110 = call i64 @strlen(ptr noundef %109) #8
  %111 = icmp uge i64 %110, 30
  %112 = select i1 %111, i32 1644199277, i32 128026015
  store i32 %112, ptr %4, align 4
  %113 = xor i32 %1, 1093589269
  %114 = and i32 %1, %113
  %115 = or i32 %1, %113
  %116 = xor i32 %1, %113
  %117 = mul i32 %115, 2
  %118 = sub i32 %117, %116
  %119 = sub i32 %118, %1
  %120 = sub i32 %119, %113
  %121 = mul i32 %120, 169
  %122 = xor i32 %1, -590391813
  %123 = and i32 %1, %122
  %124 = or i32 %1, %122
  %125 = xor i32 %1, %122
  %126 = add i32 %1, %122
  %127 = sub i32 %126, %125
  %128 = mul i32 %123, 2
  %129 = sub i32 %127, %128
  %130 = mul i32 %129, 160
  %131 = icmp ne i32 %121, %130
  br i1 %131, label %1110, label %921

132:                                              ; preds = %20
  %133 = call i32 (ptr, ...) @printf(ptr noundef @.str.69)
  store i32 498326159, ptr %4, align 4
  %134 = xor i32 %1, 1638453389
  %135 = and i32 %1, %134
  %136 = or i32 %1, %134
  %137 = xor i32 %1, %134
  %138 = add i32 %135, %136
  %139 = sub i32 %138, %1
  %140 = sub i32 %139, %134
  %141 = mul i32 %140, 230
  %142 = icmp slt i32 %141, 0
  br i1 %142, label %1118, label %921

143:                                              ; preds = %20
  %144 = load ptr, ptr %5, align 8
  %145 = getelementptr inbounds ptr, ptr %144, i64 3
  %146 = load ptr, ptr %145, align 8
  %147 = call i64 @strlen(ptr noundef %146) #8
  %148 = icmp eq i64 %147, 0
  %149 = select i1 %148, i32 -889356607, i32 -1026434792
  store i32 %149, ptr %4, align 4
  %150 = xor i32 %1, -1768823967
  %151 = and i32 %1, %150
  %152 = or i32 %1, %150
  %153 = xor i32 %1, %150
  %154 = mul i32 %152, 2
  %155 = sub i32 %154, %153
  %156 = sub i32 %155, %1
  %157 = sub i32 %156, %150
  %158 = mul i32 %157, 70
  %159 = xor i32 %1, 196399745
  %160 = and i32 %1, %159
  %161 = or i32 %1, %159
  %162 = xor i32 %1, %159
  %163 = mul i32 %161, 2
  %164 = sub i32 %163, %162
  %165 = sub i32 %164, %1
  %166 = sub i32 %165, %159
  %167 = mul i32 %166, 133
  %168 = icmp ne i32 %158, %167
  br i1 %168, label %1126, label %921

169:                                              ; preds = %20
  %170 = call i32 (ptr, ...) @printf(ptr noundef @.str.70)
  store i32 498326159, ptr %4, align 4
  %171 = xor i32 %1, 1878357647
  %172 = and i32 %1, %171
  %173 = or i32 %1, %171
  %174 = xor i32 %1, %171
  %175 = add i32 %172, %173
  %176 = sub i32 %175, %1
  %177 = sub i32 %176, %171
  %178 = mul i32 %177, 221
  %179 = icmp sle i32 %178, 0
  br i1 %179, label %921, label %1133

180:                                              ; preds = %20
  %181 = load i32, ptr @orderCount, align 4
  %182 = icmp sge i32 %181, 1000
  %183 = select i1 %182, i32 229163858, i32 1231225219
  store i32 %183, ptr %4, align 4
  %184 = xor i32 %1, -327970471
  %185 = and i32 %1, %184
  %186 = or i32 %1, %184
  %187 = xor i32 %1, %184
  %188 = add i32 %1, %184
  %189 = sub i32 %188, %187
  %190 = mul i32 %185, 2
  %191 = sub i32 %189, %190
  %192 = mul i32 %191, 79
  %193 = xor i32 %1, -1048092227
  %194 = and i32 %1, %193
  %195 = or i32 %1, %193
  %196 = xor i32 %1, %193
  %197 = add i32 %1, %193
  %198 = sub i32 %197, %196
  %199 = mul i32 %194, 2
  %200 = sub i32 %198, %199
  %201 = mul i32 %200, 19
  %202 = icmp ne i32 %192, %201
  br i1 %202, label %1140, label %921

203:                                              ; preds = %20
  %204 = call i32 (ptr, ...) @printf(ptr noundef @.str.71)
  store i32 498326159, ptr %4, align 4
  %205 = xor i32 %1, 1373797821
  %206 = and i32 %1, %205
  %207 = or i32 %1, %205
  %208 = xor i32 %1, %205
  %209 = add i32 %1, %205
  %210 = sub i32 %209, %208
  %211 = mul i32 %206, 2
  %212 = sub i32 %210, %211
  %213 = mul i32 %212, 20
  %214 = icmp eq i32 %213, 0
  br i1 %214, label %921, label %1150

215:                                              ; preds = %20
  %216 = load ptr, ptr %5, align 8
  %217 = getelementptr inbounds ptr, ptr %216, i64 2
  %218 = load ptr, ptr %217, align 8
  %219 = call i64 @calculateDiscount(i64 noundef 1000, ptr noundef %218)
  store i64 %219, ptr %11, align 8
  %220 = load i64, ptr %11, align 8
  %221 = icmp slt i64 %220, 0
  %222 = select i1 %221, i32 -678014681, i32 1374814483
  store i32 %222, ptr %4, align 4
  %223 = xor i32 %1, 1390261433
  %224 = and i32 %1, %223
  %225 = or i32 %1, %223
  %226 = xor i32 %1, %223
  %227 = add i32 %1, %223
  %228 = sub i32 %227, %226
  %229 = mul i32 %224, 2
  %230 = sub i32 %228, %229
  %231 = mul i32 %230, 151
  %232 = icmp ugt i32 %231, 0
  br i1 %232, label %1159, label %921

233:                                              ; preds = %20
  %234 = load ptr, ptr %5, align 8
  %235 = getelementptr inbounds ptr, ptr %234, i64 2
  %236 = load ptr, ptr %235, align 8
  %237 = call i32 (ptr, ...) @printf(ptr noundef @.str.72, ptr noundef %236)
  store i32 498326159, ptr %4, align 4
  %238 = xor i32 %1, -1421821559
  %239 = and i32 %1, %238
  %240 = or i32 %1, %238
  %241 = xor i32 %1, %238
  %242 = mul i32 %240, 2
  %243 = sub i32 %242, %241
  %244 = sub i32 %243, %1
  %245 = sub i32 %244, %238
  %246 = mul i32 %245, 186
  %247 = icmp sle i32 %246, 0
  br i1 %247, label %921, label %1167

248:                                              ; preds = %20
  call void @llvm.memset.p0.i64(ptr align 8 %7, i8 0, i64 6832, i1 false)
  %249 = getelementptr inbounds [1000 x i32], ptr %14, i64 0, i64 0
  call void @llvm.memset.p0.i64(ptr align 16 %249, i8 0, i64 4000, i1 false)
  %250 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 1
  %251 = getelementptr inbounds [80 x i8], ptr %250, i64 0, i64 0
  %252 = load ptr, ptr %5, align 8
  %253 = getelementptr inbounds ptr, ptr %252, i64 1
  %254 = load ptr, ptr %253, align 8
  %255 = call ptr @strcpy(ptr noundef %251, ptr noundef %254) #9
  %256 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 2
  %257 = getelementptr inbounds [30 x i8], ptr %256, i64 0, i64 0
  %258 = load ptr, ptr %5, align 8
  %259 = getelementptr inbounds ptr, ptr %258, i64 2
  %260 = load ptr, ptr %259, align 8
  %261 = call ptr @strcpy(ptr noundef %257, ptr noundef %260) #9
  %262 = getelementptr inbounds [2048 x i8], ptr %8, i64 0, i64 0
  %263 = load ptr, ptr %5, align 8
  %264 = getelementptr inbounds ptr, ptr %263, i64 3
  %265 = load ptr, ptr %264, align 8
  %266 = call ptr @strcpy(ptr noundef %262, ptr noundef %265) #9
  %267 = getelementptr inbounds [2048 x i8], ptr %8, i64 0, i64 0
  %268 = call ptr @strtok(ptr noundef %267, ptr noundef @.str.73) #9
  store ptr %268, ptr %9, align 8
  store i32 -1509314322, ptr %4, align 4
  %269 = xor i32 %1, 1259140783
  %270 = and i32 %1, %269
  %271 = or i32 %1, %269
  %272 = xor i32 %1, %269
  %273 = add i32 %270, %271
  %274 = sub i32 %273, %1
  %275 = sub i32 %274, %269
  %276 = mul i32 %275, 190
  %277 = icmp slt i32 %276, 0
  br i1 %277, label %1175, label %921

278:                                              ; preds = %20
  %279 = load ptr, ptr %9, align 8
  %280 = icmp ne ptr %279, null
  %281 = select i1 %280, i32 -704580466, i32 1331964427
  store i32 %281, ptr %4, align 4
  %282 = xor i32 %1, 1999788369
  %283 = and i32 %1, %282
  %284 = or i32 %1, %282
  %285 = xor i32 %1, %282
  %286 = add i32 %1, %282
  %287 = sub i32 %286, %285
  %288 = mul i32 %283, 2
  %289 = sub i32 %287, %288
  %290 = mul i32 %289, 9
  %291 = xor i32 %1, -2092883611
  %292 = and i32 %1, %291
  %293 = or i32 %1, %291
  %294 = xor i32 %1, %291
  %295 = add i32 %292, %293
  %296 = sub i32 %295, %1
  %297 = sub i32 %296, %291
  %298 = mul i32 %297, 78
  %299 = icmp ne i32 %290, %298
  br i1 %299, label %1184, label %921

300:                                              ; preds = %20
  %301 = load ptr, ptr %9, align 8
  call void @trim(ptr noundef %301)
  %302 = load ptr, ptr %9, align 8
  %303 = call i32 @parseCartItem(ptr noundef %302, ptr noundef %15, ptr noundef %16)
  %304 = icmp ne i32 %303, 0
  %305 = select i1 %304, i32 -1369467174, i32 676774014
  store i32 %305, ptr %4, align 4
  %306 = xor i32 %1, -1441871485
  %307 = and i32 %1, %306
  %308 = or i32 %1, %306
  %309 = xor i32 %1, %306
  %310 = mul i32 %308, 2
  %311 = sub i32 %310, %309
  %312 = sub i32 %311, %1
  %313 = sub i32 %312, %306
  %314 = mul i32 %313, 36
  %315 = icmp eq i32 %314, 0
  br i1 %315, label %921, label %1193

316:                                              ; preds = %20
  %317 = call i32 (ptr, ...) @printf(ptr noundef @.str.74)
  store i32 498326159, ptr %4, align 4
  %318 = xor i32 %1, -95934171
  %319 = and i32 %1, %318
  %320 = or i32 %1, %318
  %321 = xor i32 %1, %318
  %322 = sub i32 %320, %321
  %323 = sub i32 %322, %319
  %324 = mul i32 %323, 222
  %325 = xor i32 %1, -408412105
  %326 = and i32 %1, %325
  %327 = or i32 %1, %325
  %328 = xor i32 %1, %325
  %329 = add i32 %326, %327
  %330 = sub i32 %329, %1
  %331 = sub i32 %330, %325
  %332 = mul i32 %331, 201
  %333 = icmp ne i32 %324, %332
  br i1 %333, label %1201, label %921

334:                                              ; preds = %20
  %335 = load i32, ptr %15, align 4
  %336 = call i32 @findProductIndexById(i32 noundef %335)
  store i32 %336, ptr %17, align 4
  %337 = load i32, ptr %17, align 4
  %338 = icmp eq i32 %337, -1
  %339 = select i1 %338, i32 -2120289030, i32 -1497142223
  store i32 %339, ptr %4, align 4
  %340 = xor i32 %1, -1694527231
  %341 = and i32 %1, %340
  %342 = or i32 %1, %340
  %343 = xor i32 %1, %340
  %344 = sub i32 %342, %343
  %345 = sub i32 %344, %341
  %346 = mul i32 %345, 196
  %347 = icmp ne i32 %346, 0
  br i1 %347, label %1208, label %921

348:                                              ; preds = %20
  %349 = load i32, ptr %17, align 4
  %350 = sext i32 %349 to i64
  %351 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %350
  %352 = getelementptr inbounds nuw %struct.Product, ptr %351, i32 0, i32 6
  %353 = load i32, ptr %352, align 8
  %354 = icmp ne i32 %353, 0
  %355 = select i1 %354, i32 1119910685, i32 -2120289030
  store i32 %355, ptr %4, align 4
  %356 = xor i32 %1, -1104362727
  %357 = and i32 %1, %356
  %358 = or i32 %1, %356
  %359 = xor i32 %1, %356
  %360 = sub i32 %358, %359
  %361 = sub i32 %360, %357
  %362 = mul i32 %361, 64
  %363 = xor i32 %1, 577972387
  %364 = and i32 %1, %363
  %365 = or i32 %1, %363
  %366 = xor i32 %1, %363
  %367 = sub i32 %365, %366
  %368 = sub i32 %367, %364
  %369 = mul i32 %368, 148
  %370 = icmp eq i32 %362, %369
  br i1 %370, label %921, label %1218

371:                                              ; preds = %20
  %372 = load i32, ptr %15, align 4
  %373 = call i32 (ptr, ...) @printf(ptr noundef @.str.75, i32 noundef %372)
  store i32 498326159, ptr %4, align 4
  %374 = xor i32 %1, -1572459661
  %375 = and i32 %1, %374
  %376 = or i32 %1, %374
  %377 = xor i32 %1, %374
  %378 = mul i32 %376, 2
  %379 = sub i32 %378, %377
  %380 = sub i32 %379, %1
  %381 = sub i32 %380, %374
  %382 = mul i32 %381, 202
  %383 = xor i32 %1, -866663925
  %384 = and i32 %1, %383
  %385 = or i32 %1, %383
  %386 = xor i32 %1, %383
  %387 = add i32 %384, %385
  %388 = sub i32 %387, %1
  %389 = sub i32 %388, %383
  %390 = mul i32 %389, 176
  %391 = icmp eq i32 %382, %390
  br i1 %391, label %921, label %1227

392:                                              ; preds = %20
  %393 = load i32, ptr %16, align 4
  %394 = load i32, ptr %17, align 4
  %395 = sext i32 %394 to i64
  %396 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %395
  %397 = getelementptr inbounds nuw %struct.Product, ptr %396, i32 0, i32 4
  %398 = load i32, ptr %397, align 16
  %399 = load i32, ptr %17, align 4
  %400 = sext i32 %399 to i64
  %401 = getelementptr inbounds [1000 x i32], ptr %14, i64 0, i64 %400
  %402 = load i32, ptr %401, align 4
  %403 = load i32, ptr %4, align 4
  %404 = xor i32 %403, 1119910684
  %405 = add i32 %402, %404
  %406 = load i32, ptr %4, align 4
  %407 = xor i32 %406, 1119910684
  %408 = add i32 %398, %407
  %409 = mul i32 %398, %405
  %410 = mul i32 %402, %408
  %411 = sub i32 %409, %410
  %412 = icmp sgt i32 %393, %411
  %413 = select i1 %412, i32 -1910196360, i32 -2045046112
  store i32 %413, ptr %4, align 4
  %414 = xor i32 %1, -501531679
  %415 = and i32 %1, %414
  %416 = or i32 %1, %414
  %417 = xor i32 %1, %414
  %418 = sub i32 %416, %417
  %419 = sub i32 %418, %415
  %420 = mul i32 %419, 88
  %421 = icmp sgt i32 %420, 0
  br i1 %421, label %1237, label %921

422:                                              ; preds = %20
  %423 = load i32, ptr %15, align 4
  %424 = load i32, ptr %16, align 4
  %425 = load i32, ptr %17, align 4
  %426 = sext i32 %425 to i64
  %427 = getelementptr inbounds [1000 x i32], ptr %14, i64 0, i64 %426
  %428 = load i32, ptr %427, align 4
  %429 = load i32, ptr %4, align 4
  %430 = xor i32 %429, -1910196359
  %431 = add i32 %428, %430
  %432 = load i32, ptr %4, align 4
  %433 = xor i32 %432, -1910196359
  %434 = sub i32 %424, %433
  %435 = mul i32 %424, %431
  %436 = mul i32 %428, %434
  %437 = sub i32 %435, %436
  %438 = load i32, ptr %17, align 4
  %439 = sext i32 %438 to i64
  %440 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %439
  %441 = getelementptr inbounds nuw %struct.Product, ptr %440, i32 0, i32 4
  %442 = load i32, ptr %441, align 16
  %443 = call i32 (ptr, ...) @printf(ptr noundef @.str.76, i32 noundef %423, i32 noundef %437, i32 noundef %442)
  store i32 498326159, ptr %4, align 4
  %444 = xor i32 %1, -1475330201
  %445 = and i32 %1, %444
  %446 = or i32 %1, %444
  %447 = xor i32 %1, %444
  %448 = add i32 %1, %444
  %449 = sub i32 %448, %447
  %450 = mul i32 %445, 2
  %451 = sub i32 %449, %450
  %452 = mul i32 %451, 40
  %453 = xor i32 %1, 2021510161
  %454 = and i32 %1, %453
  %455 = or i32 %1, %453
  %456 = xor i32 %1, %453
  %457 = add i32 %454, %455
  %458 = sub i32 %457, %1
  %459 = sub i32 %458, %453
  %460 = mul i32 %459, 152
  %461 = icmp ne i32 %452, %460
  br i1 %461, label %1244, label %921

462:                                              ; preds = %20
  %463 = load i32, ptr %15, align 4
  %464 = call i32 @cartAlreadyHas(ptr noundef %7, i32 noundef %463)
  store i32 %464, ptr %18, align 4
  %465 = load i32, ptr %18, align 4
  %466 = icmp ne i32 %465, -1
  %467 = select i1 %466, i32 1565720544, i32 -987705428
  store i32 %467, ptr %4, align 4
  %468 = xor i32 %1, -460167835
  %469 = and i32 %1, %468
  %470 = or i32 %1, %468
  %471 = xor i32 %1, %468
  %472 = add i32 %469, %470
  %473 = sub i32 %472, %1
  %474 = sub i32 %473, %468
  %475 = mul i32 %474, 49
  %476 = icmp sgt i32 %475, 0
  br i1 %476, label %1253, label %921

477:                                              ; preds = %20
  %478 = load i32, ptr %16, align 4
  %479 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 3
  %480 = load i32, ptr %18, align 4
  %481 = sext i32 %480 to i64
  %482 = getelementptr inbounds [64 x %struct.OrderItem], ptr %479, i64 0, i64 %481
  %483 = getelementptr inbounds nuw %struct.OrderItem, ptr %482, i32 0, i32 2
  %484 = load i32, ptr %483, align 4
  %485 = or i32 %484, %478
  %486 = and i32 %484, %478
  %487 = add i32 %485, %486
  store i32 %487, ptr %483, align 4
  %488 = load i32, ptr %17, align 4
  %489 = sext i32 %488 to i64
  %490 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %489
  %491 = getelementptr inbounds nuw %struct.Product, ptr %490, i32 0, i32 3
  %492 = load i64, ptr %491, align 8
  %493 = load i32, ptr %16, align 4
  %494 = sext i32 %493 to i64
  %495 = mul nsw i64 %492, %494
  %496 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 3
  %497 = load i32, ptr %18, align 4
  %498 = sext i32 %497 to i64
  %499 = getelementptr inbounds [64 x %struct.OrderItem], ptr %496, i64 0, i64 %498
  %500 = getelementptr inbounds nuw %struct.OrderItem, ptr %499, i32 0, i32 4
  %501 = load i64, ptr %500, align 8
  %502 = add i64 %495, 1
  %503 = sub i64 %501, 1
  %504 = mul i64 %501, %502
  %505 = mul i64 %495, %503
  %506 = sub i64 %504, %505
  store i64 %506, ptr %500, align 8
  store i32 1227428161, ptr %4, align 4
  %507 = xor i32 %1, -1038761717
  %508 = and i32 %1, %507
  %509 = or i32 %1, %507
  %510 = xor i32 %1, %507
  %511 = mul i32 %509, 2
  %512 = sub i32 %511, %510
  %513 = sub i32 %512, %1
  %514 = sub i32 %513, %507
  %515 = mul i32 %514, 136
  %516 = icmp slt i32 %515, 0
  br i1 %516, label %1262, label %921

517:                                              ; preds = %20
  %518 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %519 = load i32, ptr %518, align 8
  %520 = icmp sge i32 %519, 64
  %521 = select i1 %520, i32 1228442308, i32 1618034054
  store i32 %521, ptr %4, align 4
  %522 = xor i32 %1, 1285952705
  %523 = and i32 %1, %522
  %524 = or i32 %1, %522
  %525 = xor i32 %1, %522
  %526 = mul i32 %524, 2
  %527 = sub i32 %526, %525
  %528 = sub i32 %527, %1
  %529 = sub i32 %528, %522
  %530 = mul i32 %529, 200
  %531 = xor i32 %1, -977657137
  %532 = and i32 %1, %531
  %533 = or i32 %1, %531
  %534 = xor i32 %1, %531
  %535 = add i32 %532, %533
  %536 = sub i32 %535, %1
  %537 = sub i32 %536, %531
  %538 = mul i32 %537, 125
  %539 = icmp eq i32 %530, %538
  br i1 %539, label %921, label %1271

540:                                              ; preds = %20
  %541 = call i32 (ptr, ...) @printf(ptr noundef @.str.77)
  store i32 498326159, ptr %4, align 4
  %542 = xor i32 %1, -394798329
  %543 = and i32 %1, %542
  %544 = or i32 %1, %542
  %545 = xor i32 %1, %542
  %546 = sub i32 %544, %545
  %547 = sub i32 %546, %543
  %548 = mul i32 %547, 13
  %549 = icmp sgt i32 %548, 0
  br i1 %549, label %1280, label %921

550:                                              ; preds = %20
  %551 = load i32, ptr %15, align 4
  %552 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 3
  %553 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %554 = load i32, ptr %553, align 8
  %555 = sext i32 %554 to i64
  %556 = getelementptr inbounds [64 x %struct.OrderItem], ptr %552, i64 0, i64 %555
  %557 = getelementptr inbounds nuw %struct.OrderItem, ptr %556, i32 0, i32 0
  store i32 %551, ptr %557, align 8
  %558 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 3
  %559 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %560 = load i32, ptr %559, align 8
  %561 = sext i32 %560 to i64
  %562 = getelementptr inbounds [64 x %struct.OrderItem], ptr %558, i64 0, i64 %561
  %563 = getelementptr inbounds nuw %struct.OrderItem, ptr %562, i32 0, i32 1
  %564 = getelementptr inbounds [80 x i8], ptr %563, i64 0, i64 0
  %565 = load i32, ptr %17, align 4
  %566 = sext i32 %565 to i64
  %567 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %566
  %568 = getelementptr inbounds nuw %struct.Product, ptr %567, i32 0, i32 1
  %569 = getelementptr inbounds [80 x i8], ptr %568, i64 0, i64 0
  %570 = call ptr @strcpy(ptr noundef %564, ptr noundef %569) #9
  %571 = load i32, ptr %16, align 4
  %572 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 3
  %573 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %574 = load i32, ptr %573, align 8
  %575 = sext i32 %574 to i64
  %576 = getelementptr inbounds [64 x %struct.OrderItem], ptr %572, i64 0, i64 %575
  %577 = getelementptr inbounds nuw %struct.OrderItem, ptr %576, i32 0, i32 2
  store i32 %571, ptr %577, align 4
  %578 = load i32, ptr %17, align 4
  %579 = sext i32 %578 to i64
  %580 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %579
  %581 = getelementptr inbounds nuw %struct.Product, ptr %580, i32 0, i32 3
  %582 = load i64, ptr %581, align 8
  %583 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 3
  %584 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %585 = load i32, ptr %584, align 8
  %586 = sext i32 %585 to i64
  %587 = getelementptr inbounds [64 x %struct.OrderItem], ptr %583, i64 0, i64 %586
  %588 = getelementptr inbounds nuw %struct.OrderItem, ptr %587, i32 0, i32 3
  store i64 %582, ptr %588, align 8
  %589 = load i32, ptr %17, align 4
  %590 = sext i32 %589 to i64
  %591 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %590
  %592 = getelementptr inbounds nuw %struct.Product, ptr %591, i32 0, i32 3
  %593 = load i64, ptr %592, align 8
  %594 = load i32, ptr %16, align 4
  %595 = sext i32 %594 to i64
  %596 = mul nsw i64 %593, %595
  %597 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 3
  %598 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %599 = load i32, ptr %598, align 8
  %600 = sext i32 %599 to i64
  %601 = getelementptr inbounds [64 x %struct.OrderItem], ptr %597, i64 0, i64 %600
  %602 = getelementptr inbounds nuw %struct.OrderItem, ptr %601, i32 0, i32 4
  store i64 %596, ptr %602, align 8
  %603 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %604 = load i32, ptr %603, align 8
  %605 = load i32, ptr %4, align 4
  %606 = xor i32 %605, 1618034055
  %607 = xor i32 %604, %606
  %608 = load i32, ptr %4, align 4
  %609 = xor i32 %608, 1618034055
  %610 = and i32 %604, %609
  %611 = add i32 %610, %610
  %612 = add i32 %607, %611
  store i32 %612, ptr %603, align 8
  store i32 1227428161, ptr %4, align 4
  %613 = xor i32 %1, 33388475
  %614 = and i32 %1, %613
  %615 = or i32 %1, %613
  %616 = xor i32 %1, %613
  %617 = mul i32 %615, 2
  %618 = sub i32 %617, %616
  %619 = sub i32 %618, %1
  %620 = sub i32 %619, %613
  %621 = mul i32 %620, 184
  %622 = icmp ne i32 %621, 0
  br i1 %622, label %1288, label %921

623:                                              ; preds = %20
  %624 = load i32, ptr %16, align 4
  %625 = load i32, ptr %17, align 4
  %626 = sext i32 %625 to i64
  %627 = getelementptr inbounds [1000 x i32], ptr %14, i64 0, i64 %626
  %628 = load i32, ptr %627, align 4
  %629 = xor i32 %628, %624
  %630 = and i32 %628, %624
  %631 = add i32 %630, %630
  %632 = add i32 %629, %631
  store i32 %632, ptr %627, align 4
  %633 = load i32, ptr %17, align 4
  %634 = sext i32 %633 to i64
  %635 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %634
  %636 = getelementptr inbounds nuw %struct.Product, ptr %635, i32 0, i32 3
  %637 = load i64, ptr %636, align 8
  %638 = load i32, ptr %16, align 4
  %639 = sext i32 %638 to i64
  %640 = mul nsw i64 %637, %639
  %641 = load i64, ptr %10, align 8
  %642 = or i64 %641, %640
  %643 = and i64 %641, %640
  %644 = add i64 %642, %643
  store i64 %644, ptr %10, align 8
  %645 = call ptr @strtok(ptr noundef null, ptr noundef @.str.73) #9
  store ptr %645, ptr %9, align 8
  store i32 -1509314322, ptr %4, align 4
  %646 = xor i32 %1, -593837493
  %647 = and i32 %1, %646
  %648 = or i32 %1, %646
  %649 = xor i32 %1, %646
  %650 = add i32 %1, %646
  %651 = sub i32 %650, %649
  %652 = mul i32 %647, 2
  %653 = sub i32 %651, %652
  %654 = mul i32 %653, 9
  %655 = icmp slt i32 %654, 1
  br i1 %655, label %921, label %1298

656:                                              ; preds = %20
  %657 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 4
  %658 = load i32, ptr %657, align 8
  %659 = icmp eq i32 %658, 0
  %660 = select i1 %659, i32 -2025476413, i32 -2132346648
  store i32 %660, ptr %4, align 4
  %661 = xor i32 %1, 1604590757
  %662 = and i32 %1, %661
  %663 = or i32 %1, %661
  %664 = xor i32 %1, %661
  %665 = add i32 %662, %663
  %666 = sub i32 %665, %1
  %667 = sub i32 %666, %661
  %668 = mul i32 %667, 141
  %669 = icmp uge i32 %668, 0
  br i1 %669, label %921, label %1308

670:                                              ; preds = %20
  %671 = call i32 (ptr, ...) @printf(ptr noundef @.str.70)
  store i32 498326159, ptr %4, align 4
  %672 = xor i32 %1, 108623075
  %673 = and i32 %1, %672
  %674 = or i32 %1, %672
  %675 = xor i32 %1, %672
  %676 = add i32 %1, %672
  %677 = sub i32 %676, %675
  %678 = mul i32 %673, 2
  %679 = sub i32 %677, %678
  %680 = mul i32 %679, 109
  %681 = xor i32 %1, -1216710161
  %682 = and i32 %1, %681
  %683 = or i32 %1, %681
  %684 = xor i32 %1, %681
  %685 = add i32 %1, %681
  %686 = sub i32 %685, %684
  %687 = mul i32 %682, 2
  %688 = sub i32 %686, %687
  %689 = mul i32 %688, 105
  %690 = icmp ne i32 %680, %689
  br i1 %690, label %1318, label %921

691:                                              ; preds = %20
  %692 = load i64, ptr %10, align 8
  %693 = load ptr, ptr %5, align 8
  %694 = getelementptr inbounds ptr, ptr %693, i64 2
  %695 = load ptr, ptr %694, align 8
  %696 = call i64 @calculateDiscount(i64 noundef %692, ptr noundef %695)
  store i64 %696, ptr %11, align 8
  %697 = load ptr, ptr %5, align 8
  %698 = getelementptr inbounds ptr, ptr %697, i64 2
  %699 = load ptr, ptr %698, align 8
  %700 = call i32 @equalsIgnoreCase(ptr noundef %699, ptr noundef @.str.46)
  %701 = icmp ne i32 %700, 0
  %702 = zext i1 %701 to i64
  %703 = select i1 %701, i32 0, i32 300
  %704 = sext i32 %703 to i64
  store i64 %704, ptr %12, align 8
  %705 = load i64, ptr %10, align 8
  %706 = load i64, ptr %11, align 8
  %707 = xor i64 %705, %706
  %708 = xor i64 %705, -1
  %709 = and i64 %708, %706
  %710 = add i64 %709, %709
  %711 = sub i64 %707, %710
  %712 = mul nsw i64 %711, 8
  %713 = sdiv i64 %712, 100
  store i64 %713, ptr %13, align 8
  %714 = load i32, ptr @nextOrderId, align 4
  %715 = load i32, ptr %4, align 4
  %716 = xor i32 %715, -2132346647
  %717 = or i32 %714, %716
  %718 = load i32, ptr %4, align 4
  %719 = xor i32 %718, -2132346647
  %720 = and i32 %714, %719
  %721 = add i32 %717, %720
  store i32 %721, ptr @nextOrderId, align 4
  %722 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 0
  store i32 %714, ptr %722, align 8
  %723 = load i64, ptr %10, align 8
  %724 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 5
  store i64 %723, ptr %724, align 8
  %725 = load i64, ptr %11, align 8
  %726 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 6
  store i64 %725, ptr %726, align 8
  %727 = load i64, ptr %12, align 8
  %728 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 7
  store i64 %727, ptr %728, align 8
  %729 = load i64, ptr %13, align 8
  %730 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 8
  store i64 %729, ptr %730, align 8
  %731 = load i64, ptr %10, align 8
  %732 = load i64, ptr %11, align 8
  %733 = xor i64 %731, %732
  %734 = xor i64 %731, -1
  %735 = and i64 %734, %732
  %736 = add i64 %735, %735
  %737 = sub i64 %733, %736
  %738 = load i64, ptr %12, align 8
  %739 = xor i64 %737, %738
  %740 = and i64 %737, %738
  %741 = add i64 %740, %740
  %742 = add i64 %739, %741
  %743 = load i64, ptr %13, align 8
  %744 = xor i64 %742, %743
  %745 = and i64 %742, %743
  %746 = add i64 %745, %745
  %747 = add i64 %744, %746
  %748 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 9
  store i64 %747, ptr %748, align 8
  %749 = getelementptr inbounds nuw %struct.Order, ptr %7, i32 0, i32 10
  store i32 0, ptr %749, align 8
  store i32 0, ptr %19, align 4
  store i32 479435512, ptr %4, align 4
  %750 = xor i32 %1, 1871049389
  %751 = and i32 %1, %750
  %752 = or i32 %1, %750
  %753 = xor i32 %1, %750
  %754 = mul i32 %752, 2
  %755 = sub i32 %754, %753
  %756 = sub i32 %755, %1
  %757 = sub i32 %756, %750
  %758 = mul i32 %757, 89
  %759 = xor i32 %1, -1047277753
  %760 = and i32 %1, %759
  %761 = or i32 %1, %759
  %762 = xor i32 %1, %759
  %763 = sub i32 %761, %762
  %764 = sub i32 %763, %760
  %765 = mul i32 %764, 77
  %766 = icmp eq i32 %758, %765
  br i1 %766, label %921, label %1326

767:                                              ; preds = %20
  %768 = load i32, ptr %19, align 4
  %769 = load i32, ptr @productCount, align 4
  %770 = icmp slt i32 %768, %769
  %771 = select i1 %770, i32 370505730, i32 1302675105
  store i32 %771, ptr %4, align 4
  %772 = xor i32 %1, -1988596959
  %773 = and i32 %1, %772
  %774 = or i32 %1, %772
  %775 = xor i32 %1, %772
  %776 = add i32 %773, %774
  %777 = sub i32 %776, %1
  %778 = sub i32 %777, %772
  %779 = mul i32 %778, 137
  %780 = icmp uge i32 %779, 0
  br i1 %780, label %921, label %1336

781:                                              ; preds = %20
  %782 = load i32, ptr %19, align 4
  %783 = sext i32 %782 to i64
  %784 = getelementptr inbounds [1000 x i32], ptr %14, i64 0, i64 %783
  %785 = load i32, ptr %784, align 4
  %786 = icmp sgt i32 %785, 0
  %787 = select i1 %786, i32 -1567689985, i32 -1769026146
  store i32 %787, ptr %4, align 4
  %788 = xor i32 %1, 1490901529
  %789 = and i32 %1, %788
  %790 = or i32 %1, %788
  %791 = xor i32 %1, %788
  %792 = add i32 %789, %790
  %793 = sub i32 %792, %1
  %794 = sub i32 %793, %788
  %795 = mul i32 %794, 28
  %796 = icmp slt i32 %795, 0
  br i1 %796, label %1345, label %921

797:                                              ; preds = %20
  %798 = load i32, ptr %19, align 4
  %799 = sext i32 %798 to i64
  %800 = getelementptr inbounds [1000 x i32], ptr %14, i64 0, i64 %799
  %801 = load i32, ptr %800, align 4
  %802 = load i32, ptr %19, align 4
  %803 = sext i32 %802 to i64
  %804 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %803
  %805 = getelementptr inbounds nuw %struct.Product, ptr %804, i32 0, i32 4
  %806 = load i32, ptr %805, align 16
  %807 = load i32, ptr %4, align 4
  %808 = xor i32 %807, -1567689986
  %809 = add i32 %801, %808
  %810 = load i32, ptr %4, align 4
  %811 = xor i32 %810, -1567689986
  %812 = add i32 %806, %811
  %813 = mul i32 %806, %809
  %814 = mul i32 %801, %812
  %815 = sub i32 %813, %814
  store i32 %815, ptr %805, align 16
  %816 = load i32, ptr %19, align 4
  %817 = sext i32 %816 to i64
  %818 = getelementptr inbounds [1000 x i32], ptr %14, i64 0, i64 %817
  %819 = load i32, ptr %818, align 4
  %820 = load i32, ptr %19, align 4
  %821 = sext i32 %820 to i64
  %822 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %821
  %823 = getelementptr inbounds nuw %struct.Product, ptr %822, i32 0, i32 5
  %824 = load i32, ptr %823, align 4
  %825 = xor i32 %824, %819
  %826 = and i32 %824, %819
  %827 = add i32 %826, %826
  %828 = add i32 %825, %827
  store i32 %828, ptr %823, align 4
  store i32 -1769026146, ptr %4, align 4
  %829 = xor i32 %1, -138096403
  %830 = and i32 %1, %829
  %831 = or i32 %1, %829
  %832 = xor i32 %1, %829
  %833 = mul i32 %831, 2
  %834 = sub i32 %833, %832
  %835 = sub i32 %834, %1
  %836 = sub i32 %835, %829
  %837 = mul i32 %836, 91
  %838 = icmp uge i32 %837, 0
  br i1 %838, label %921, label %1352

839:                                              ; preds = %20
  %840 = load i32, ptr %19, align 4
  %841 = load i32, ptr %4, align 4
  %842 = xor i32 %841, -1769026145
  %843 = or i32 %840, %842
  %844 = load i32, ptr %4, align 4
  %845 = xor i32 %844, -1769026145
  %846 = and i32 %840, %845
  %847 = add i32 %843, %846
  store i32 %847, ptr %19, align 4
  store i32 479435512, ptr %4, align 4
  %848 = xor i32 %1, -322328433
  %849 = and i32 %1, %848
  %850 = or i32 %1, %848
  %851 = xor i32 %1, %848
  %852 = add i32 %849, %850
  %853 = sub i32 %852, %1
  %854 = sub i32 %853, %848
  %855 = mul i32 %854, 227
  %856 = icmp slt i32 %855, 0
  br i1 %856, label %1360, label %921

857:                                              ; preds = %20
  %858 = load i32, ptr @orderCount, align 4
  %859 = load i32, ptr %4, align 4
  %860 = xor i32 %859, 1302675104
  %861 = sub i32 %858, %860
  %862 = load i32, ptr %4, align 4
  %863 = xor i32 %862, 1302675107
  %864 = mul i32 %858, %863
  %865 = load i32, ptr %4, align 4
  %866 = xor i32 %865, 1302675104
  %867 = mul i32 %866, %861
  %868 = sub i32 %864, %867
  store i32 %868, ptr @orderCount, align 4
  %869 = sext i32 %858 to i64
  %870 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %869
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %870, ptr align 8 %7, i64 6832, i1 false)
  %871 = call i32 (ptr, ...) @printf(ptr noundef @.str.78)
  call void @printOrderShort(ptr noundef %7)
  %872 = load ptr, ptr %5, align 8
  %873 = getelementptr inbounds ptr, ptr %872, i64 2
  %874 = load ptr, ptr %873, align 8
  %875 = call i32 @equalsIgnoreCase(ptr noundef %874, ptr noundef @.str.45)
  %876 = icmp ne i32 %875, 0
  %877 = select i1 %876, i32 287452285, i32 498326159
  store i32 %877, ptr %4, align 4
  %878 = xor i32 %1, -103898529
  %879 = and i32 %1, %878
  %880 = or i32 %1, %878
  %881 = xor i32 %1, %878
  %882 = mul i32 %880, 2
  %883 = sub i32 %882, %881
  %884 = sub i32 %883, %1
  %885 = sub i32 %884, %878
  %886 = mul i32 %885, 148
  %887 = icmp sgt i32 %886, 0
  br i1 %887, label %1367, label %921

888:                                              ; preds = %20
  %889 = load i64, ptr %11, align 8
  %890 = icmp eq i64 %889, 0
  %891 = select i1 %890, i32 -1280519082, i32 498326159
  store i32 %891, ptr %4, align 4
  %892 = xor i32 %1, 301040927
  %893 = and i32 %1, %892
  %894 = or i32 %1, %892
  %895 = xor i32 %1, %892
  %896 = add i32 %893, %894
  %897 = sub i32 %896, %1
  %898 = sub i32 %897, %892
  %899 = mul i32 %898, 79
  %900 = icmp uge i32 %899, 0
  br i1 %900, label %921, label %1376

901:                                              ; preds = %20
  %902 = call i32 (ptr, ...) @printf(ptr noundef @.str.79)
  store i32 498326159, ptr %4, align 4
  %903 = xor i32 %1, -1760714737
  %904 = and i32 %1, %903
  %905 = or i32 %1, %903
  %906 = xor i32 %1, %903
  %907 = add i32 %1, %903
  %908 = sub i32 %907, %906
  %909 = mul i32 %904, 2
  %910 = sub i32 %908, %909
  %911 = mul i32 %910, 45
  %912 = xor i32 %1, -519634869
  %913 = and i32 %1, %912
  %914 = or i32 %1, %912
  %915 = xor i32 %1, %912
  %916 = sub i32 %914, %915
  %917 = sub i32 %916, %913
  %918 = mul i32 %917, 234
  %919 = icmp eq i32 %911, %918
  br i1 %919, label %921, label %1385

920:                                              ; preds = %20
  ret void

921:                                              ; preds = %1457, %1450, %1443, %1434, %1424, %1416, %1407, %1399, %1385, %1376, %1367, %1360, %1352, %1345, %1336, %1326, %1318, %1308, %1298, %1288, %1280, %1271, %1262, %1253, %1244, %1237, %1227, %1218, %1208, %1201, %1193, %1184, %1175, %1167, %1159, %1150, %1140, %1133, %1126, %1118, %1110, %1102, %1092, %1082, %1074, %1065, %1057, %1044, %1022, %1011, %1000, %987, %974, %953, %941, %901, %888, %857, %839, %797, %781, %767, %691, %670, %656, %623, %550, %540, %517, %477, %462, %422, %392, %371, %348, %334, %316, %300, %278, %248, %233, %215, %203, %180, %169, %143, %132, %106, %90, %80, %64, %48, %36, %24
  br label %20

922:                                              ; preds = %20
  store i32 416623745, ptr %4, align 4
  call void asm sideeffect "", ""()
  %923 = xor i32 %1, 136866999
  %924 = and i32 %1, %923
  %925 = or i32 %1, %923
  %926 = xor i32 %1, %923
  %927 = add i32 %1, %923
  %928 = sub i32 %927, %926
  %929 = mul i32 %924, 2
  %930 = sub i32 %928, %929
  %931 = mul i32 %930, 116
  %932 = xor i32 %1, 975864301
  %933 = and i32 %1, %932
  %934 = or i32 %1, %932
  %935 = xor i32 %1, %932
  %936 = add i32 %933, %934
  %937 = sub i32 %936, %1
  %938 = sub i32 %937, %932
  %939 = mul i32 %938, 156
  %940 = icmp eq i32 %931, %939
  br i1 %940, label %20, label %1392

941:                                              ; preds = %20
  %942 = load i32, ptr %4, align 4
  %943 = xor i32 %942, -2133490136
  store i32 %943, ptr %4, align 4
  %944 = xor i32 %1, -60055667
  %945 = and i32 %1, %944
  %946 = or i32 %1, %944
  %947 = xor i32 %1, %944
  %948 = add i32 %945, %946
  %949 = sub i32 %948, %1
  %950 = sub i32 %949, %944
  %951 = mul i32 %950, 176
  %952 = icmp slt i32 %951, 0
  br i1 %952, label %1399, label %921

953:                                              ; preds = %20
  %954 = load i32, ptr %4, align 4
  %955 = xor i32 %954, -343030688
  store i32 %955, ptr %4, align 4
  %956 = xor i32 %1, 386010375
  %957 = and i32 %1, %956
  %958 = or i32 %1, %956
  %959 = xor i32 %1, %956
  %960 = add i32 %957, %958
  %961 = sub i32 %960, %1
  %962 = sub i32 %961, %956
  %963 = mul i32 %962, 134
  %964 = xor i32 %1, -583561843
  %965 = and i32 %1, %964
  %966 = or i32 %1, %964
  %967 = xor i32 %1, %964
  %968 = add i32 %1, %964
  %969 = sub i32 %968, %967
  %970 = mul i32 %965, 2
  %971 = sub i32 %969, %970
  %972 = mul i32 %971, 59
  %973 = icmp eq i32 %963, %972
  br i1 %973, label %921, label %1407

974:                                              ; preds = %20
  %975 = load i32, ptr %4, align 4
  %976 = xor i32 %975, 924674852
  store i32 %976, ptr %4, align 4
  %977 = xor i32 %1, -1867977641
  %978 = and i32 %1, %977
  %979 = or i32 %1, %977
  %980 = xor i32 %1, %977
  %981 = mul i32 %979, 2
  %982 = sub i32 %981, %980
  %983 = sub i32 %982, %1
  %984 = sub i32 %983, %977
  %985 = mul i32 %984, 192
  %986 = icmp ne i32 %985, 0
  br i1 %986, label %1416, label %921

987:                                              ; preds = %20
  %988 = load i32, ptr %4, align 4
  %989 = xor i32 %988, 794734270
  store i32 %989, ptr %4, align 4
  %990 = xor i32 %1, -537233083
  %991 = and i32 %1, %990
  %992 = or i32 %1, %990
  %993 = xor i32 %1, %990
  %994 = add i32 %1, %990
  %995 = sub i32 %994, %993
  %996 = mul i32 %991, 2
  %997 = sub i32 %995, %996
  %998 = mul i32 %997, 224
  %999 = icmp slt i32 %998, 1
  br i1 %999, label %921, label %1424

1000:                                             ; preds = %20
  %1001 = load i32, ptr %4, align 4
  %1002 = xor i32 %1001, 744536455
  store i32 %1002, ptr %4, align 4
  %1003 = xor i32 %1, -950250653
  %1004 = and i32 %1, %1003
  %1005 = or i32 %1, %1003
  %1006 = xor i32 %1, %1003
  %1007 = sub i32 %1005, %1006
  %1008 = sub i32 %1007, %1004
  %1009 = mul i32 %1008, 28
  %1010 = icmp slt i32 %1009, 1
  br i1 %1010, label %921, label %1434

1011:                                             ; preds = %20
  %1012 = load i32, ptr %4, align 4
  %1013 = xor i32 %1012, -1014746671
  store i32 %1013, ptr %4, align 4
  %1014 = xor i32 %1, 1873845833
  %1015 = and i32 %1, %1014
  %1016 = or i32 %1, %1014
  %1017 = xor i32 %1, %1014
  %1018 = sub i32 %1016, %1017
  %1019 = sub i32 %1018, %1015
  %1020 = mul i32 %1019, 62
  %1021 = icmp uge i32 %1020, 0
  br i1 %1021, label %921, label %1443

1022:                                             ; preds = %20
  %1023 = load i32, ptr %4, align 4
  %1024 = xor i32 %1023, -712559600
  store i32 %1024, ptr %4, align 4
  %1025 = xor i32 %1, 1007488775
  %1026 = and i32 %1, %1025
  %1027 = or i32 %1, %1025
  %1028 = xor i32 %1, %1025
  %1029 = add i32 %1, %1025
  %1030 = sub i32 %1029, %1028
  %1031 = mul i32 %1026, 2
  %1032 = sub i32 %1030, %1031
  %1033 = mul i32 %1032, 143
  %1034 = xor i32 %1, -1003203527
  %1035 = and i32 %1, %1034
  %1036 = or i32 %1, %1034
  %1037 = xor i32 %1, %1034
  %1038 = mul i32 %1036, 2
  %1039 = sub i32 %1038, %1037
  %1040 = sub i32 %1039, %1
  %1041 = sub i32 %1040, %1034
  %1042 = mul i32 %1041, 96
  %1043 = icmp ne i32 %1033, %1042
  br i1 %1043, label %1450, label %921

1044:                                             ; preds = %20
  %1045 = load i32, ptr %4, align 4
  %1046 = xor i32 %1045, 16239920
  store i32 %1046, ptr %4, align 4
  %1047 = xor i32 %1, 1742794003
  %1048 = and i32 %1, %1047
  %1049 = or i32 %1, %1047
  %1050 = xor i32 %1, %1047
  %1051 = add i32 %1, %1047
  %1052 = sub i32 %1051, %1050
  %1053 = mul i32 %1048, 2
  %1054 = sub i32 %1052, %1053
  %1055 = mul i32 %1054, 52
  %1056 = icmp ugt i32 %1055, 0
  br i1 %1056, label %1457, label %921

1057:                                             ; preds = %24
  %1058 = load i64, ptr %3, align 8
  %1059 = ptrtoint ptr %0 to i64
  %1060 = zext i32 %1 to i64
  %1061 = add i64 %1059, %1060
  %1062 = or i64 %1061, %1060
  %1063 = or i64 %1062, %1058
  %1064 = mul i64 %1063, %1059
  store i64 %1064, ptr %3, align 8
  br label %921

1065:                                             ; preds = %36
  %1066 = load i64, ptr %3, align 8
  %1067 = ptrtoint ptr %0 to i64
  %1068 = zext i32 %1 to i64
  %1069 = and i64 %1067, %1068
  %1070 = add i64 %1069, %1067
  %1071 = sub i64 %1070, %1067
  %1072 = and i64 %1071, %1067
  %1073 = xor i64 %1072, %1068
  store i64 %1073, ptr %3, align 8
  br label %921

1074:                                             ; preds = %48
  %1075 = load i64, ptr %3, align 8
  %1076 = ptrtoint ptr %0 to i64
  %1077 = zext i32 %1 to i64
  %1078 = sub i64 %1075, %1075
  %1079 = sub i64 %1078, %1075
  %1080 = add i64 %1079, %1076
  %1081 = sub i64 %1080, %1075
  store i64 %1081, ptr %3, align 8
  br label %921

1082:                                             ; preds = %64
  %1083 = load i64, ptr %3, align 8
  %1084 = ptrtoint ptr %0 to i64
  %1085 = zext i32 %1 to i64
  %1086 = xor i64 %1083, %1084
  %1087 = or i64 %1086, %1084
  %1088 = add i64 %1087, %1083
  %1089 = xor i64 %1088, %1084
  %1090 = mul i64 %1089, %1085
  %1091 = xor i64 %1090, %1085
  store i64 %1091, ptr %3, align 8
  br label %921

1092:                                             ; preds = %80
  %1093 = load i64, ptr %3, align 8
  %1094 = ptrtoint ptr %0 to i64
  %1095 = zext i32 %1 to i64
  %1096 = or i64 %1095, %1095
  %1097 = mul i64 %1096, %1095
  %1098 = sub i64 %1097, %1093
  %1099 = sub i64 %1098, %1094
  %1100 = mul i64 %1099, %1094
  %1101 = or i64 %1100, %1094
  store i64 %1101, ptr %3, align 8
  br label %921

1102:                                             ; preds = %90
  %1103 = load i64, ptr %3, align 8
  %1104 = ptrtoint ptr %0 to i64
  %1105 = zext i32 %1 to i64
  %1106 = or i64 %1104, %1104
  %1107 = and i64 %1106, %1103
  %1108 = xor i64 %1107, %1104
  %1109 = sub i64 %1108, %1105
  store i64 %1109, ptr %3, align 8
  br label %921

1110:                                             ; preds = %106
  %1111 = load i64, ptr %3, align 8
  %1112 = ptrtoint ptr %0 to i64
  %1113 = zext i32 %1 to i64
  %1114 = add i64 %1111, %1111
  %1115 = sub i64 %1114, %1111
  %1116 = sub i64 %1115, %1113
  %1117 = mul i64 %1116, %1112
  store i64 %1117, ptr %3, align 8
  br label %921

1118:                                             ; preds = %132
  %1119 = load i64, ptr %3, align 8
  %1120 = ptrtoint ptr %0 to i64
  %1121 = zext i32 %1 to i64
  %1122 = xor i64 %1120, %1120
  %1123 = add i64 %1122, %1119
  %1124 = sub i64 %1123, %1120
  %1125 = and i64 %1124, %1121
  store i64 %1125, ptr %3, align 8
  br label %921

1126:                                             ; preds = %143
  %1127 = load i64, ptr %3, align 8
  %1128 = ptrtoint ptr %0 to i64
  %1129 = zext i32 %1 to i64
  %1130 = xor i64 %1128, %1127
  %1131 = add i64 %1130, %1128
  %1132 = add i64 %1131, %1129
  store i64 %1132, ptr %3, align 8
  br label %921

1133:                                             ; preds = %169
  %1134 = load i64, ptr %3, align 8
  %1135 = ptrtoint ptr %0 to i64
  %1136 = zext i32 %1 to i64
  %1137 = and i64 %1134, %1135
  %1138 = sub i64 %1137, %1134
  %1139 = add i64 %1138, %1135
  store i64 %1139, ptr %3, align 8
  br label %921

1140:                                             ; preds = %180
  %1141 = load i64, ptr %3, align 8
  %1142 = ptrtoint ptr %0 to i64
  %1143 = zext i32 %1 to i64
  %1144 = xor i64 %1142, %1143
  %1145 = xor i64 %1144, %1141
  %1146 = and i64 %1145, %1142
  %1147 = add i64 %1146, %1142
  %1148 = or i64 %1147, %1143
  %1149 = and i64 %1148, %1143
  store i64 %1149, ptr %3, align 8
  br label %921

1150:                                             ; preds = %203
  %1151 = load i64, ptr %3, align 8
  %1152 = ptrtoint ptr %0 to i64
  %1153 = zext i32 %1 to i64
  %1154 = and i64 %1153, %1153
  %1155 = or i64 %1154, %1153
  %1156 = xor i64 %1155, %1152
  %1157 = xor i64 %1156, %1152
  %1158 = mul i64 %1157, %1152
  store i64 %1158, ptr %3, align 8
  br label %921

1159:                                             ; preds = %215
  %1160 = load i64, ptr %3, align 8
  %1161 = ptrtoint ptr %0 to i64
  %1162 = zext i32 %1 to i64
  %1163 = add i64 %1162, %1162
  %1164 = or i64 %1163, %1162
  %1165 = add i64 %1164, %1160
  %1166 = sub i64 %1165, %1161
  store i64 %1166, ptr %3, align 8
  br label %921

1167:                                             ; preds = %233
  %1168 = load i64, ptr %3, align 8
  %1169 = ptrtoint ptr %0 to i64
  %1170 = zext i32 %1 to i64
  %1171 = mul i64 %1168, %1170
  %1172 = xor i64 %1171, %1169
  %1173 = sub i64 %1172, %1170
  %1174 = or i64 %1173, %1169
  store i64 %1174, ptr %3, align 8
  br label %921

1175:                                             ; preds = %248
  %1176 = load i64, ptr %3, align 8
  %1177 = ptrtoint ptr %0 to i64
  %1178 = zext i32 %1 to i64
  %1179 = and i64 %1177, %1177
  %1180 = sub i64 %1179, %1177
  %1181 = add i64 %1180, %1177
  %1182 = xor i64 %1181, %1178
  %1183 = add i64 %1182, %1178
  store i64 %1183, ptr %3, align 8
  br label %921

1184:                                             ; preds = %278
  %1185 = load i64, ptr %3, align 8
  %1186 = ptrtoint ptr %0 to i64
  %1187 = zext i32 %1 to i64
  %1188 = add i64 %1187, %1187
  %1189 = sub i64 %1188, %1186
  %1190 = or i64 %1189, %1186
  %1191 = add i64 %1190, %1185
  %1192 = sub i64 %1191, %1187
  store i64 %1192, ptr %3, align 8
  br label %921

1193:                                             ; preds = %300
  %1194 = load i64, ptr %3, align 8
  %1195 = ptrtoint ptr %0 to i64
  %1196 = zext i32 %1 to i64
  %1197 = add i64 %1195, %1194
  %1198 = mul i64 %1197, %1195
  %1199 = xor i64 %1198, %1194
  %1200 = mul i64 %1199, %1195
  store i64 %1200, ptr %3, align 8
  br label %921

1201:                                             ; preds = %316
  %1202 = load i64, ptr %3, align 8
  %1203 = ptrtoint ptr %0 to i64
  %1204 = zext i32 %1 to i64
  %1205 = and i64 %1203, %1204
  %1206 = add i64 %1205, %1203
  %1207 = xor i64 %1206, %1203
  store i64 %1207, ptr %3, align 8
  br label %921

1208:                                             ; preds = %334
  %1209 = load i64, ptr %3, align 8
  %1210 = ptrtoint ptr %0 to i64
  %1211 = zext i32 %1 to i64
  %1212 = sub i64 %1209, %1210
  %1213 = sub i64 %1212, %1210
  %1214 = sub i64 %1213, %1210
  %1215 = add i64 %1214, %1209
  %1216 = sub i64 %1215, %1209
  %1217 = and i64 %1216, %1209
  store i64 %1217, ptr %3, align 8
  br label %921

1218:                                             ; preds = %348
  %1219 = load i64, ptr %3, align 8
  %1220 = ptrtoint ptr %0 to i64
  %1221 = zext i32 %1 to i64
  %1222 = mul i64 %1221, %1221
  %1223 = and i64 %1222, %1221
  %1224 = or i64 %1223, %1219
  %1225 = mul i64 %1224, %1219
  %1226 = add i64 %1225, %1221
  store i64 %1226, ptr %3, align 8
  br label %921

1227:                                             ; preds = %371
  %1228 = load i64, ptr %3, align 8
  %1229 = ptrtoint ptr %0 to i64
  %1230 = zext i32 %1 to i64
  %1231 = or i64 %1230, %1230
  %1232 = sub i64 %1231, %1230
  %1233 = mul i64 %1232, %1229
  %1234 = and i64 %1233, %1230
  %1235 = and i64 %1234, %1229
  %1236 = sub i64 %1235, %1230
  store i64 %1236, ptr %3, align 8
  br label %921

1237:                                             ; preds = %392
  %1238 = load i64, ptr %3, align 8
  %1239 = ptrtoint ptr %0 to i64
  %1240 = zext i32 %1 to i64
  %1241 = mul i64 %1238, %1239
  %1242 = xor i64 %1241, %1240
  %1243 = mul i64 %1242, %1240
  store i64 %1243, ptr %3, align 8
  br label %921

1244:                                             ; preds = %422
  %1245 = load i64, ptr %3, align 8
  %1246 = ptrtoint ptr %0 to i64
  %1247 = zext i32 %1 to i64
  %1248 = sub i64 %1247, %1246
  %1249 = and i64 %1248, %1247
  %1250 = sub i64 %1249, %1245
  %1251 = add i64 %1250, %1245
  %1252 = add i64 %1251, %1246
  store i64 %1252, ptr %3, align 8
  br label %921

1253:                                             ; preds = %462
  %1254 = load i64, ptr %3, align 8
  %1255 = ptrtoint ptr %0 to i64
  %1256 = zext i32 %1 to i64
  %1257 = add i64 %1256, %1255
  %1258 = add i64 %1257, %1255
  %1259 = and i64 %1258, %1256
  %1260 = mul i64 %1259, %1256
  %1261 = or i64 %1260, %1254
  store i64 %1261, ptr %3, align 8
  br label %921

1262:                                             ; preds = %477
  %1263 = load i64, ptr %3, align 8
  %1264 = ptrtoint ptr %0 to i64
  %1265 = zext i32 %1 to i64
  %1266 = mul i64 %1265, %1265
  %1267 = xor i64 %1266, %1264
  %1268 = or i64 %1267, %1263
  %1269 = or i64 %1268, %1265
  %1270 = mul i64 %1269, %1265
  store i64 %1270, ptr %3, align 8
  br label %921

1271:                                             ; preds = %517
  %1272 = load i64, ptr %3, align 8
  %1273 = ptrtoint ptr %0 to i64
  %1274 = zext i32 %1 to i64
  %1275 = sub i64 %1272, %1272
  %1276 = sub i64 %1275, %1273
  %1277 = add i64 %1276, %1272
  %1278 = xor i64 %1277, %1273
  %1279 = add i64 %1278, %1272
  store i64 %1279, ptr %3, align 8
  br label %921

1280:                                             ; preds = %540
  %1281 = load i64, ptr %3, align 8
  %1282 = ptrtoint ptr %0 to i64
  %1283 = zext i32 %1 to i64
  %1284 = sub i64 %1283, %1282
  %1285 = sub i64 %1284, %1283
  %1286 = and i64 %1285, %1281
  %1287 = add i64 %1286, %1282
  store i64 %1287, ptr %3, align 8
  br label %921

1288:                                             ; preds = %550
  %1289 = load i64, ptr %3, align 8
  %1290 = ptrtoint ptr %0 to i64
  %1291 = zext i32 %1 to i64
  %1292 = and i64 %1290, %1290
  %1293 = sub i64 %1292, %1291
  %1294 = and i64 %1293, %1291
  %1295 = and i64 %1294, %1289
  %1296 = add i64 %1295, %1290
  %1297 = and i64 %1296, %1290
  store i64 %1297, ptr %3, align 8
  br label %921

1298:                                             ; preds = %623
  %1299 = load i64, ptr %3, align 8
  %1300 = ptrtoint ptr %0 to i64
  %1301 = zext i32 %1 to i64
  %1302 = add i64 %1300, %1301
  %1303 = xor i64 %1302, %1301
  %1304 = xor i64 %1303, %1299
  %1305 = and i64 %1304, %1299
  %1306 = and i64 %1305, %1300
  %1307 = and i64 %1306, %1299
  store i64 %1307, ptr %3, align 8
  br label %921

1308:                                             ; preds = %656
  %1309 = load i64, ptr %3, align 8
  %1310 = ptrtoint ptr %0 to i64
  %1311 = zext i32 %1 to i64
  %1312 = xor i64 %1311, %1310
  %1313 = add i64 %1312, %1311
  %1314 = sub i64 %1313, %1310
  %1315 = or i64 %1314, %1310
  %1316 = xor i64 %1315, %1309
  %1317 = and i64 %1316, %1310
  store i64 %1317, ptr %3, align 8
  br label %921

1318:                                             ; preds = %670
  %1319 = load i64, ptr %3, align 8
  %1320 = ptrtoint ptr %0 to i64
  %1321 = zext i32 %1 to i64
  %1322 = xor i64 %1321, %1320
  %1323 = or i64 %1322, %1320
  %1324 = xor i64 %1323, %1320
  %1325 = xor i64 %1324, %1321
  store i64 %1325, ptr %3, align 8
  br label %921

1326:                                             ; preds = %691
  %1327 = load i64, ptr %3, align 8
  %1328 = ptrtoint ptr %0 to i64
  %1329 = zext i32 %1 to i64
  %1330 = sub i64 %1327, %1327
  %1331 = sub i64 %1330, %1328
  %1332 = add i64 %1331, %1329
  %1333 = mul i64 %1332, %1329
  %1334 = sub i64 %1333, %1328
  %1335 = sub i64 %1334, %1329
  store i64 %1335, ptr %3, align 8
  br label %921

1336:                                             ; preds = %767
  %1337 = load i64, ptr %3, align 8
  %1338 = ptrtoint ptr %0 to i64
  %1339 = zext i32 %1 to i64
  %1340 = sub i64 %1339, %1339
  %1341 = add i64 %1340, %1338
  %1342 = xor i64 %1341, %1338
  %1343 = mul i64 %1342, %1338
  %1344 = and i64 %1343, %1339
  store i64 %1344, ptr %3, align 8
  br label %921

1345:                                             ; preds = %781
  %1346 = load i64, ptr %3, align 8
  %1347 = ptrtoint ptr %0 to i64
  %1348 = zext i32 %1 to i64
  %1349 = and i64 %1347, %1347
  %1350 = add i64 %1349, %1347
  %1351 = sub i64 %1350, %1348
  store i64 %1351, ptr %3, align 8
  br label %921

1352:                                             ; preds = %797
  %1353 = load i64, ptr %3, align 8
  %1354 = ptrtoint ptr %0 to i64
  %1355 = zext i32 %1 to i64
  %1356 = or i64 %1353, %1354
  %1357 = add i64 %1356, %1355
  %1358 = sub i64 %1357, %1355
  %1359 = or i64 %1358, %1355
  store i64 %1359, ptr %3, align 8
  br label %921

1360:                                             ; preds = %839
  %1361 = load i64, ptr %3, align 8
  %1362 = ptrtoint ptr %0 to i64
  %1363 = zext i32 %1 to i64
  %1364 = and i64 %1361, %1363
  %1365 = and i64 %1364, %1361
  %1366 = xor i64 %1365, %1361
  store i64 %1366, ptr %3, align 8
  br label %921

1367:                                             ; preds = %857
  %1368 = load i64, ptr %3, align 8
  %1369 = ptrtoint ptr %0 to i64
  %1370 = zext i32 %1 to i64
  %1371 = or i64 %1369, %1369
  %1372 = mul i64 %1371, %1370
  %1373 = or i64 %1372, %1369
  %1374 = sub i64 %1373, %1369
  %1375 = sub i64 %1374, %1369
  store i64 %1375, ptr %3, align 8
  br label %921

1376:                                             ; preds = %888
  %1377 = load i64, ptr %3, align 8
  %1378 = ptrtoint ptr %0 to i64
  %1379 = zext i32 %1 to i64
  %1380 = sub i64 %1378, %1379
  %1381 = xor i64 %1380, %1378
  %1382 = sub i64 %1381, %1377
  %1383 = mul i64 %1382, %1379
  %1384 = sub i64 %1383, %1379
  store i64 %1384, ptr %3, align 8
  br label %921

1385:                                             ; preds = %901
  %1386 = load i64, ptr %3, align 8
  %1387 = ptrtoint ptr %0 to i64
  %1388 = zext i32 %1 to i64
  %1389 = add i64 %1386, %1388
  %1390 = mul i64 %1389, %1388
  %1391 = add i64 %1390, %1387
  store i64 %1391, ptr %3, align 8
  br label %921

1392:                                             ; preds = %922
  %1393 = load i64, ptr %3, align 8
  %1394 = ptrtoint ptr %0 to i64
  %1395 = zext i32 %1 to i64
  %1396 = add i64 %1395, %1395
  %1397 = mul i64 %1396, %1394
  %1398 = xor i64 %1397, %1393
  store i64 %1398, ptr %3, align 8
  br label %20

1399:                                             ; preds = %941
  %1400 = load i64, ptr %3, align 8
  %1401 = ptrtoint ptr %0 to i64
  %1402 = zext i32 %1 to i64
  %1403 = mul i64 %1402, %1402
  %1404 = add i64 %1403, %1400
  %1405 = and i64 %1404, %1402
  %1406 = add i64 %1405, %1400
  store i64 %1406, ptr %3, align 8
  br label %921

1407:                                             ; preds = %953
  %1408 = load i64, ptr %3, align 8
  %1409 = ptrtoint ptr %0 to i64
  %1410 = zext i32 %1 to i64
  %1411 = add i64 %1410, %1409
  %1412 = sub i64 %1411, %1410
  %1413 = mul i64 %1412, %1408
  %1414 = mul i64 %1413, %1409
  %1415 = or i64 %1414, %1410
  store i64 %1415, ptr %3, align 8
  br label %921

1416:                                             ; preds = %974
  %1417 = load i64, ptr %3, align 8
  %1418 = ptrtoint ptr %0 to i64
  %1419 = zext i32 %1 to i64
  %1420 = sub i64 %1418, %1419
  %1421 = sub i64 %1420, %1417
  %1422 = mul i64 %1421, %1417
  %1423 = or i64 %1422, %1418
  store i64 %1423, ptr %3, align 8
  br label %921

1424:                                             ; preds = %987
  %1425 = load i64, ptr %3, align 8
  %1426 = ptrtoint ptr %0 to i64
  %1427 = zext i32 %1 to i64
  %1428 = or i64 %1426, %1425
  %1429 = xor i64 %1428, %1425
  %1430 = add i64 %1429, %1427
  %1431 = and i64 %1430, %1425
  %1432 = mul i64 %1431, %1425
  %1433 = and i64 %1432, %1426
  store i64 %1433, ptr %3, align 8
  br label %921

1434:                                             ; preds = %1000
  %1435 = load i64, ptr %3, align 8
  %1436 = ptrtoint ptr %0 to i64
  %1437 = zext i32 %1 to i64
  %1438 = mul i64 %1435, %1437
  %1439 = xor i64 %1438, %1436
  %1440 = or i64 %1439, %1437
  %1441 = add i64 %1440, %1435
  %1442 = sub i64 %1441, %1437
  store i64 %1442, ptr %3, align 8
  br label %921

1443:                                             ; preds = %1011
  %1444 = load i64, ptr %3, align 8
  %1445 = ptrtoint ptr %0 to i64
  %1446 = zext i32 %1 to i64
  %1447 = and i64 %1444, %1446
  %1448 = and i64 %1447, %1445
  %1449 = mul i64 %1448, %1446
  store i64 %1449, ptr %3, align 8
  br label %921

1450:                                             ; preds = %1022
  %1451 = load i64, ptr %3, align 8
  %1452 = ptrtoint ptr %0 to i64
  %1453 = zext i32 %1 to i64
  %1454 = sub i64 %1453, %1452
  %1455 = add i64 %1454, %1452
  %1456 = mul i64 %1455, %1451
  store i64 %1456, ptr %3, align 8
  br label %921

1457:                                             ; preds = %1044
  %1458 = load i64, ptr %3, align 8
  %1459 = ptrtoint ptr %0 to i64
  %1460 = zext i32 %1 to i64
  %1461 = or i64 %1459, %1459
  %1462 = mul i64 %1461, %1460
  %1463 = add i64 %1462, %1458
  %1464 = mul i64 %1463, %1458
  %1465 = sub i64 %1464, %1460
  store i64 %1465, ptr %3, align 8
  br label %921
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #6

; Function Attrs: nounwind
declare ptr @strtok(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdCancel(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 -77337815, ptr %4, align 4
  br label %11

11:                                               ; preds = %577, %309, %308, %2
  %12 = load i32, ptr %4, align 4
  %13 = sub i32 %12, 1318784138
  %14 = mul i32 %13, 483973189
  switch i32 %14, label %309 [
    i32 1210198235, label %15
    i32 471227901, label %29
    i32 907105938, label %46
    i32 502075970, label %58
    i32 359936766, label %74
    i32 928793432, label %86
    i32 979658178, label %102
    i32 703167542, label %113
    i32 1771559804, label %124
    i32 958265576, label %141
    i32 286043233, label %164
    i32 733865015, label %208
    i32 2053121472, label %242
    i32 1273663746, label %264
    i32 515201357, label %273
    i32 7257728, label %292
    i32 112435714, label %307
    i32 1045296826, label %328
    i32 1823737524, label %341
    i32 1434429592, label %354
    i32 2080698760, label %366
    i32 314732342, label %387
    i32 480949198, label %400
    i32 206544329, label %413
    i32 298622350, label %432
  ]

15:                                               ; preds = %11
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %16 = load i32, ptr %6, align 4
  %17 = icmp ne i32 %16, 2
  %18 = select i1 %17, i32 543772404, i32 423060195
  store i32 %18, ptr %4, align 4
  %19 = xor i32 %1, 1348638453
  %20 = and i32 %1, %19
  %21 = or i32 %1, %19
  %22 = xor i32 %1, %19
  %23 = mul i32 %21, 2
  %24 = sub i32 %23, %22
  %25 = sub i32 %24, %1
  %26 = sub i32 %25, %19
  %27 = mul i32 %26, 243
  %28 = icmp uge i32 %27, 0
  br i1 %28, label %308, label %443

29:                                               ; preds = %11
  %30 = load ptr, ptr %5, align 8
  %31 = getelementptr inbounds ptr, ptr %30, i64 1
  %32 = load ptr, ptr %31, align 8
  %33 = call i32 @parseIntStrict(ptr noundef %32, ptr noundef %7)
  %34 = icmp ne i32 %33, 0
  %35 = select i1 %34, i32 870420196, i32 543772404
  store i32 %35, ptr %4, align 4
  %36 = xor i32 %1, -1652255659
  %37 = and i32 %1, %36
  %38 = or i32 %1, %36
  %39 = xor i32 %1, %36
  %40 = add i32 %1, %36
  %41 = sub i32 %40, %39
  %42 = mul i32 %37, 2
  %43 = sub i32 %41, %42
  %44 = mul i32 %43, 143
  %45 = icmp uge i32 %44, 0
  br i1 %45, label %308, label %451

46:                                               ; preds = %11
  %47 = call i32 (ptr, ...) @printf(ptr noundef @.str.80)
  store i32 700464036, ptr %4, align 4
  %48 = xor i32 %1, 1344390021
  %49 = and i32 %1, %48
  %50 = or i32 %1, %48
  %51 = xor i32 %1, %48
  %52 = add i32 %1, %48
  %53 = sub i32 %52, %51
  %54 = mul i32 %49, 2
  %55 = sub i32 %53, %54
  %56 = mul i32 %55, 78
  %57 = icmp ne i32 %56, 0
  br i1 %57, label %458, label %308

58:                                               ; preds = %11
  %59 = load i32, ptr %7, align 4
  %60 = call i32 @findOrderIndexById(i32 noundef %59)
  store i32 %60, ptr %8, align 4
  %61 = load i32, ptr %8, align 4
  %62 = icmp eq i32 %61, -1
  %63 = select i1 %62, i32 1894264432, i32 -662432766
  store i32 %63, ptr %4, align 4
  %64 = xor i32 %1, 1952356295
  %65 = and i32 %1, %64
  %66 = or i32 %1, %64
  %67 = xor i32 %1, %64
  %68 = add i32 %1, %64
  %69 = sub i32 %68, %67
  %70 = mul i32 %65, 2
  %71 = sub i32 %69, %70
  %72 = mul i32 %71, 54
  %73 = icmp ne i32 %72, 0
  br i1 %73, label %467, label %308

74:                                               ; preds = %11
  %75 = load i32, ptr %7, align 4
  %76 = call i32 (ptr, ...) @printf(ptr noundef @.str.81, i32 noundef %75)
  store i32 700464036, ptr %4, align 4
  %77 = xor i32 %1, 627577045
  %78 = and i32 %1, %77
  %79 = or i32 %1, %77
  %80 = xor i32 %1, %77
  %81 = add i32 %78, %79
  %82 = sub i32 %81, %1
  %83 = sub i32 %82, %77
  %84 = mul i32 %83, 230
  %85 = icmp ne i32 %84, 0
  br i1 %85, label %474, label %308

86:                                               ; preds = %11
  %87 = load i32, ptr %8, align 4
  %88 = sext i32 %87 to i64
  %89 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %88
  %90 = getelementptr inbounds nuw %struct.Order, ptr %89, i32 0, i32 10
  %91 = load i32, ptr %90, align 8
  %92 = icmp ne i32 %91, 0
  %93 = select i1 %92, i32 -10122140, i32 -1100598712
  store i32 %93, ptr %4, align 4
  %94 = xor i32 %1, -612436481
  %95 = and i32 %1, %94
  %96 = or i32 %1, %94
  %97 = xor i32 %1, %94
  %98 = sub i32 %96, %97
  %99 = sub i32 %98, %95
  %100 = mul i32 %99, 115
  %101 = icmp eq i32 %100, 0
  br i1 %101, label %308, label %483

102:                                              ; preds = %11
  %103 = load i32, ptr %7, align 4
  %104 = call i32 (ptr, ...) @printf(ptr noundef @.str.82, i32 noundef %103)
  store i32 700464036, ptr %4, align 4
  %105 = xor i32 %1, 1263745283
  %106 = and i32 %1, %105
  %107 = or i32 %1, %105
  %108 = xor i32 %1, %105
  %109 = sub i32 %107, %108
  %110 = sub i32 %109, %106
  %111 = mul i32 %110, 242
  %112 = icmp slt i32 %111, 0
  br i1 %112, label %490, label %308

113:                                              ; preds = %11
  store i32 0, ptr %9, align 4
  store i32 -136837162, ptr %4, align 4
  %114 = xor i32 %1, -196643357
  %115 = and i32 %1, %114
  %116 = or i32 %1, %114
  %117 = xor i32 %1, %114
  %118 = mul i32 %116, 2
  %119 = sub i32 %118, %117
  %120 = sub i32 %119, %1
  %121 = sub i32 %120, %114
  %122 = mul i32 %121, 225
  %123 = icmp slt i32 %122, 1
  br i1 %123, label %308, label %498

124:                                              ; preds = %11
  %125 = load i32, ptr %9, align 4
  %126 = load i32, ptr %8, align 4
  %127 = sext i32 %126 to i64
  %128 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %127
  %129 = getelementptr inbounds nuw %struct.Order, ptr %128, i32 0, i32 4
  %130 = load i32, ptr %129, align 8
  %131 = icmp slt i32 %125, %130
  %132 = select i1 %131, i32 -658787246, i32 308476170
  store i32 %132, ptr %4, align 4
  %133 = xor i32 %1, -1712213323
  %134 = and i32 %1, %133
  %135 = or i32 %1, %133
  %136 = xor i32 %1, %133
  %137 = sub i32 %135, %136
  %138 = sub i32 %137, %134
  %139 = mul i32 %138, 186
  %140 = icmp slt i32 %139, 0
  br i1 %140, label %505, label %308

141:                                              ; preds = %11
  %142 = load i32, ptr %8, align 4
  %143 = sext i32 %142 to i64
  %144 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %143
  %145 = getelementptr inbounds nuw %struct.Order, ptr %144, i32 0, i32 3
  %146 = load i32, ptr %9, align 4
  %147 = sext i32 %146 to i64
  %148 = getelementptr inbounds [64 x %struct.OrderItem], ptr %145, i64 0, i64 %147
  %149 = getelementptr inbounds nuw %struct.OrderItem, ptr %148, i32 0, i32 0
  %150 = load i32, ptr %149, align 8
  %151 = call i32 @findProductIndexById(i32 noundef %150)
  store i32 %151, ptr %10, align 4
  %152 = load i32, ptr %10, align 4
  %153 = icmp ne i32 %152, -1
  %154 = select i1 %153, i32 1413232631, i32 646704627
  store i32 %154, ptr %4, align 4
  %155 = xor i32 %1, -1621229305
  %156 = and i32 %1, %155
  %157 = or i32 %1, %155
  %158 = xor i32 %1, %155
  %159 = add i32 %156, %157
  %160 = sub i32 %159, %1
  %161 = sub i32 %160, %155
  %162 = mul i32 %161, 135
  %163 = icmp sgt i32 %162, 0
  br i1 %163, label %515, label %308

164:                                              ; preds = %11
  %165 = load i32, ptr %8, align 4
  %166 = sext i32 %165 to i64
  %167 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %166
  %168 = getelementptr inbounds nuw %struct.Order, ptr %167, i32 0, i32 3
  %169 = load i32, ptr %9, align 4
  %170 = sext i32 %169 to i64
  %171 = getelementptr inbounds [64 x %struct.OrderItem], ptr %168, i64 0, i64 %170
  %172 = getelementptr inbounds nuw %struct.OrderItem, ptr %171, i32 0, i32 2
  %173 = load i32, ptr %172, align 4
  %174 = load i32, ptr %10, align 4
  %175 = sext i32 %174 to i64
  %176 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %175
  %177 = getelementptr inbounds nuw %struct.Product, ptr %176, i32 0, i32 4
  %178 = load i32, ptr %177, align 16
  %179 = or i32 %178, %173
  %180 = and i32 %178, %173
  %181 = add i32 %179, %180
  store i32 %181, ptr %177, align 16
  %182 = load i32, ptr %10, align 4
  %183 = sext i32 %182 to i64
  %184 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %183
  %185 = getelementptr inbounds nuw %struct.Product, ptr %184, i32 0, i32 5
  %186 = load i32, ptr %185, align 4
  %187 = load i32, ptr %8, align 4
  %188 = sext i32 %187 to i64
  %189 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %188
  %190 = getelementptr inbounds nuw %struct.Order, ptr %189, i32 0, i32 3
  %191 = load i32, ptr %9, align 4
  %192 = sext i32 %191 to i64
  %193 = getelementptr inbounds [64 x %struct.OrderItem], ptr %190, i64 0, i64 %192
  %194 = getelementptr inbounds nuw %struct.OrderItem, ptr %193, i32 0, i32 2
  %195 = load i32, ptr %194, align 4
  %196 = icmp sge i32 %186, %195
  %197 = select i1 %196, i32 -1049365291, i32 -1483909302
  store i32 %197, ptr %4, align 4
  %198 = xor i32 %1, 81333675
  %199 = and i32 %1, %198
  %200 = or i32 %1, %198
  %201 = xor i32 %1, %198
  %202 = mul i32 %200, 2
  %203 = sub i32 %202, %201
  %204 = sub i32 %203, %1
  %205 = sub i32 %204, %198
  %206 = mul i32 %205, 147
  %207 = icmp eq i32 %206, 0
  br i1 %207, label %308, label %525

208:                                              ; preds = %11
  %209 = load i32, ptr %8, align 4
  %210 = sext i32 %209 to i64
  %211 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %210
  %212 = getelementptr inbounds nuw %struct.Order, ptr %211, i32 0, i32 3
  %213 = load i32, ptr %9, align 4
  %214 = sext i32 %213 to i64
  %215 = getelementptr inbounds [64 x %struct.OrderItem], ptr %212, i64 0, i64 %214
  %216 = getelementptr inbounds nuw %struct.OrderItem, ptr %215, i32 0, i32 2
  %217 = load i32, ptr %216, align 4
  %218 = load i32, ptr %10, align 4
  %219 = sext i32 %218 to i64
  %220 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %219
  %221 = getelementptr inbounds nuw %struct.Product, ptr %220, i32 0, i32 5
  %222 = load i32, ptr %221, align 4
  %223 = load i32, ptr %4, align 4
  %224 = xor i32 %223, -1049365292
  %225 = add i32 %217, %224
  %226 = load i32, ptr %4, align 4
  %227 = xor i32 %226, -1049365292
  %228 = add i32 %222, %227
  %229 = mul i32 %222, %225
  %230 = mul i32 %217, %228
  %231 = sub i32 %229, %230
  store i32 %231, ptr %221, align 4
  store i32 -152576348, ptr %4, align 4
  %232 = xor i32 %1, 1208472627
  %233 = and i32 %1, %232
  %234 = or i32 %1, %232
  %235 = xor i32 %1, %232
  %236 = add i32 %1, %232
  %237 = sub i32 %236, %235
  %238 = mul i32 %233, 2
  %239 = sub i32 %237, %238
  %240 = mul i32 %239, 56
  %241 = icmp uge i32 %240, 0
  br i1 %241, label %308, label %532

242:                                              ; preds = %11
  %243 = load i32, ptr %10, align 4
  %244 = sext i32 %243 to i64
  %245 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %244
  %246 = getelementptr inbounds nuw %struct.Product, ptr %245, i32 0, i32 5
  store i32 0, ptr %246, align 4
  store i32 -152576348, ptr %4, align 4
  %247 = xor i32 %1, 700835715
  %248 = and i32 %1, %247
  %249 = or i32 %1, %247
  %250 = xor i32 %1, %247
  %251 = sub i32 %249, %250
  %252 = sub i32 %251, %248
  %253 = mul i32 %252, 118
  %254 = xor i32 %1, 420017773
  %255 = and i32 %1, %254
  %256 = or i32 %1, %254
  %257 = xor i32 %1, %254
  %258 = mul i32 %256, 2
  %259 = sub i32 %258, %257
  %260 = sub i32 %259, %1
  %261 = sub i32 %260, %254
  %262 = mul i32 %261, 164
  %263 = icmp eq i32 %253, %262
  br i1 %263, label %308, label %542

264:                                              ; preds = %11
  store i32 646704627, ptr %4, align 4
  %265 = xor i32 %1, 1667802541
  %266 = and i32 %1, %265
  %267 = or i32 %1, %265
  %268 = xor i32 %1, %265
  %269 = sub i32 %267, %268
  %270 = sub i32 %269, %266
  %271 = mul i32 %270, 15
  %272 = icmp ne i32 %271, 0
  br i1 %272, label %550, label %308

273:                                              ; preds = %11
  %274 = load i32, ptr %9, align 4
  %275 = load i32, ptr %4, align 4
  %276 = xor i32 %275, 646704626
  %277 = xor i32 %274, %276
  %278 = load i32, ptr %4, align 4
  %279 = xor i32 %278, 646704626
  %280 = and i32 %274, %279
  %281 = add i32 %280, %280
  %282 = add i32 %277, %281
  store i32 %282, ptr %9, align 4
  store i32 -136837162, ptr %4, align 4
  %283 = xor i32 %1, -92145319
  %284 = and i32 %1, %283
  %285 = or i32 %1, %283
  %286 = xor i32 %1, %283
  %287 = add i32 %284, %285
  %288 = sub i32 %287, %1
  %289 = sub i32 %288, %283
  %290 = mul i32 %289, 154
  %291 = icmp uge i32 %290, 0
  br i1 %291, label %308, label %559

292:                                              ; preds = %11
  %293 = load i32, ptr %8, align 4
  %294 = sext i32 %293 to i64
  %295 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %294
  %296 = getelementptr inbounds nuw %struct.Order, ptr %295, i32 0, i32 10
  store i32 1, ptr %296, align 8
  %297 = load i32, ptr %7, align 4
  %298 = call i32 (ptr, ...) @printf(ptr noundef @.str.83, i32 noundef %297)
  store i32 700464036, ptr %4, align 4
  %299 = xor i32 %1, -1296392847
  %300 = and i32 %1, %299
  %301 = or i32 %1, %299
  %302 = xor i32 %1, %299
  %303 = sub i32 %301, %302
  %304 = sub i32 %303, %300
  %305 = mul i32 %304, 152
  %306 = icmp slt i32 %305, 1
  br i1 %306, label %308, label %569

307:                                              ; preds = %11
  ret void

308:                                              ; preds = %648, %638, %628, %618, %609, %600, %593, %586, %569, %559, %550, %542, %532, %525, %515, %505, %498, %490, %483, %474, %467, %458, %451, %443, %432, %413, %400, %387, %366, %354, %341, %328, %292, %273, %264, %242, %208, %164, %141, %124, %113, %102, %86, %74, %58, %46, %29, %15
  br label %11

309:                                              ; preds = %11
  store i32 -77337815, ptr %4, align 4
  call void asm sideeffect "", ""()
  %310 = xor i32 %1, -1547805771
  %311 = and i32 %1, %310
  %312 = or i32 %1, %310
  %313 = xor i32 %1, %310
  %314 = add i32 %311, %312
  %315 = sub i32 %314, %1
  %316 = sub i32 %315, %310
  %317 = mul i32 %316, 218
  %318 = xor i32 %1, 368596249
  %319 = and i32 %1, %318
  %320 = or i32 %1, %318
  %321 = xor i32 %1, %318
  %322 = add i32 %1, %318
  %323 = sub i32 %322, %321
  %324 = mul i32 %319, 2
  %325 = sub i32 %323, %324
  %326 = mul i32 %325, 176
  %327 = icmp ne i32 %317, %326
  br i1 %327, label %577, label %11

328:                                              ; preds = %11
  %329 = load i32, ptr %4, align 4
  %330 = xor i32 %329, 2132309054
  store i32 %330, ptr %4, align 4
  %331 = xor i32 %1, 121073311
  %332 = and i32 %1, %331
  %333 = or i32 %1, %331
  %334 = xor i32 %1, %331
  %335 = add i32 %1, %331
  %336 = sub i32 %335, %334
  %337 = mul i32 %332, 2
  %338 = sub i32 %336, %337
  %339 = mul i32 %338, 147
  %340 = icmp eq i32 %339, 0
  br i1 %340, label %308, label %586

341:                                              ; preds = %11
  %342 = load i32, ptr %4, align 4
  %343 = xor i32 %342, -457575485
  store i32 %343, ptr %4, align 4
  %344 = xor i32 %1, -1021608105
  %345 = and i32 %1, %344
  %346 = or i32 %1, %344
  %347 = xor i32 %1, %344
  %348 = mul i32 %346, 2
  %349 = sub i32 %348, %347
  %350 = sub i32 %349, %1
  %351 = sub i32 %350, %344
  %352 = mul i32 %351, 111
  %353 = icmp eq i32 %352, 0
  br i1 %353, label %308, label %593

354:                                              ; preds = %11
  %355 = load i32, ptr %4, align 4
  %356 = xor i32 %355, -782460352
  store i32 %356, ptr %4, align 4
  %357 = xor i32 %1, 1413710203
  %358 = and i32 %1, %357
  %359 = or i32 %1, %357
  %360 = xor i32 %1, %357
  %361 = add i32 %358, %359
  %362 = sub i32 %361, %1
  %363 = sub i32 %362, %357
  %364 = mul i32 %363, 203
  %365 = icmp slt i32 %364, 1
  br i1 %365, label %308, label %600

366:                                              ; preds = %11
  %367 = load i32, ptr %4, align 4
  %368 = xor i32 %367, 1041922113
  store i32 %368, ptr %4, align 4
  %369 = xor i32 %1, 1527469375
  %370 = and i32 %1, %369
  %371 = or i32 %1, %369
  %372 = xor i32 %1, %369
  %373 = add i32 %370, %371
  %374 = sub i32 %373, %1
  %375 = sub i32 %374, %369
  %376 = mul i32 %375, 120
  %377 = xor i32 %1, -560114909
  %378 = and i32 %1, %377
  %379 = or i32 %1, %377
  %380 = xor i32 %1, %377
  %381 = add i32 %1, %377
  %382 = sub i32 %381, %380
  %383 = mul i32 %378, 2
  %384 = sub i32 %382, %383
  %385 = mul i32 %384, 241
  %386 = icmp ne i32 %376, %385
  br i1 %386, label %609, label %308

387:                                              ; preds = %11
  %388 = load i32, ptr %4, align 4
  %389 = xor i32 %388, -2019240347
  store i32 %389, ptr %4, align 4
  %390 = xor i32 %1, -1829793465
  %391 = and i32 %1, %390
  %392 = or i32 %1, %390
  %393 = xor i32 %1, %390
  %394 = mul i32 %392, 2
  %395 = sub i32 %394, %393
  %396 = sub i32 %395, %1
  %397 = sub i32 %396, %390
  %398 = mul i32 %397, 77
  %399 = icmp ne i32 %398, 0
  br i1 %399, label %618, label %308

400:                                              ; preds = %11
  %401 = load i32, ptr %4, align 4
  %402 = xor i32 %401, 1176381362
  store i32 %402, ptr %4, align 4
  %403 = xor i32 %1, 1701368057
  %404 = and i32 %1, %403
  %405 = or i32 %1, %403
  %406 = xor i32 %1, %403
  %407 = mul i32 %405, 2
  %408 = sub i32 %407, %406
  %409 = sub i32 %408, %1
  %410 = sub i32 %409, %403
  %411 = mul i32 %410, 181
  %412 = icmp uge i32 %411, 0
  br i1 %412, label %308, label %628

413:                                              ; preds = %11
  %414 = load i32, ptr %4, align 4
  %415 = xor i32 %414, -1480021599
  store i32 %415, ptr %4, align 4
  %416 = xor i32 %1, 1247449099
  %417 = and i32 %1, %416
  %418 = or i32 %1, %416
  %419 = xor i32 %1, %416
  %420 = add i32 %417, %418
  %421 = sub i32 %420, %1
  %422 = sub i32 %421, %416
  %423 = mul i32 %422, 227
  %424 = xor i32 %1, 1627005711
  %425 = and i32 %1, %424
  %426 = or i32 %1, %424
  %427 = xor i32 %1, %424
  %428 = sub i32 %426, %427
  %429 = sub i32 %428, %425
  %430 = mul i32 %429, 92
  %431 = icmp eq i32 %423, %430
  br i1 %431, label %308, label %638

432:                                              ; preds = %11
  %433 = load i32, ptr %4, align 4
  %434 = xor i32 %433, 1036614979
  store i32 %434, ptr %4, align 4
  %435 = xor i32 %1, 108185551
  %436 = and i32 %1, %435
  %437 = or i32 %1, %435
  %438 = xor i32 %1, %435
  %439 = sub i32 %437, %438
  %440 = sub i32 %439, %436
  %441 = mul i32 %440, 10
  %442 = icmp ne i32 %441, 0
  br i1 %442, label %648, label %308

443:                                              ; preds = %15
  %444 = load i64, ptr %3, align 8
  %445 = ptrtoint ptr %0 to i64
  %446 = zext i32 %1 to i64
  %447 = or i64 %446, %446
  %448 = or i64 %447, %446
  %449 = add i64 %448, %445
  %450 = add i64 %449, %445
  store i64 %450, ptr %3, align 8
  br label %308

451:                                              ; preds = %29
  %452 = load i64, ptr %3, align 8
  %453 = ptrtoint ptr %0 to i64
  %454 = zext i32 %1 to i64
  %455 = xor i64 %452, %454
  %456 = or i64 %455, %454
  %457 = and i64 %456, %453
  store i64 %457, ptr %3, align 8
  br label %308

458:                                              ; preds = %46
  %459 = load i64, ptr %3, align 8
  %460 = ptrtoint ptr %0 to i64
  %461 = zext i32 %1 to i64
  %462 = and i64 %459, %459
  %463 = or i64 %462, %460
  %464 = mul i64 %463, %461
  %465 = mul i64 %464, %459
  %466 = or i64 %465, %460
  store i64 %466, ptr %3, align 8
  br label %308

467:                                              ; preds = %58
  %468 = load i64, ptr %3, align 8
  %469 = ptrtoint ptr %0 to i64
  %470 = zext i32 %1 to i64
  %471 = sub i64 %470, %468
  %472 = mul i64 %471, %468
  %473 = and i64 %472, %470
  store i64 %473, ptr %3, align 8
  br label %308

474:                                              ; preds = %74
  %475 = load i64, ptr %3, align 8
  %476 = ptrtoint ptr %0 to i64
  %477 = zext i32 %1 to i64
  %478 = xor i64 %477, %475
  %479 = add i64 %478, %476
  %480 = sub i64 %479, %476
  %481 = add i64 %480, %475
  %482 = xor i64 %481, %475
  store i64 %482, ptr %3, align 8
  br label %308

483:                                              ; preds = %86
  %484 = load i64, ptr %3, align 8
  %485 = ptrtoint ptr %0 to i64
  %486 = zext i32 %1 to i64
  %487 = add i64 %486, %486
  %488 = xor i64 %487, %484
  %489 = add i64 %488, %484
  store i64 %489, ptr %3, align 8
  br label %308

490:                                              ; preds = %102
  %491 = load i64, ptr %3, align 8
  %492 = ptrtoint ptr %0 to i64
  %493 = zext i32 %1 to i64
  %494 = xor i64 %493, %493
  %495 = sub i64 %494, %491
  %496 = sub i64 %495, %492
  %497 = xor i64 %496, %493
  store i64 %497, ptr %3, align 8
  br label %308

498:                                              ; preds = %113
  %499 = load i64, ptr %3, align 8
  %500 = ptrtoint ptr %0 to i64
  %501 = zext i32 %1 to i64
  %502 = sub i64 %499, %500
  %503 = add i64 %502, %499
  %504 = add i64 %503, %501
  store i64 %504, ptr %3, align 8
  br label %308

505:                                              ; preds = %124
  %506 = load i64, ptr %3, align 8
  %507 = ptrtoint ptr %0 to i64
  %508 = zext i32 %1 to i64
  %509 = add i64 %506, %508
  %510 = mul i64 %509, %508
  %511 = add i64 %510, %506
  %512 = xor i64 %511, %507
  %513 = or i64 %512, %506
  %514 = xor i64 %513, %508
  store i64 %514, ptr %3, align 8
  br label %308

515:                                              ; preds = %141
  %516 = load i64, ptr %3, align 8
  %517 = ptrtoint ptr %0 to i64
  %518 = zext i32 %1 to i64
  %519 = sub i64 %517, %516
  %520 = or i64 %519, %518
  %521 = or i64 %520, %516
  %522 = add i64 %521, %516
  %523 = or i64 %522, %518
  %524 = and i64 %523, %516
  store i64 %524, ptr %3, align 8
  br label %308

525:                                              ; preds = %164
  %526 = load i64, ptr %3, align 8
  %527 = ptrtoint ptr %0 to i64
  %528 = zext i32 %1 to i64
  %529 = sub i64 %528, %528
  %530 = or i64 %529, %527
  %531 = and i64 %530, %527
  store i64 %531, ptr %3, align 8
  br label %308

532:                                              ; preds = %208
  %533 = load i64, ptr %3, align 8
  %534 = ptrtoint ptr %0 to i64
  %535 = zext i32 %1 to i64
  %536 = sub i64 %533, %534
  %537 = mul i64 %536, %534
  %538 = xor i64 %537, %535
  %539 = add i64 %538, %533
  %540 = add i64 %539, %534
  %541 = add i64 %540, %534
  store i64 %541, ptr %3, align 8
  br label %308

542:                                              ; preds = %242
  %543 = load i64, ptr %3, align 8
  %544 = ptrtoint ptr %0 to i64
  %545 = zext i32 %1 to i64
  %546 = or i64 %543, %544
  %547 = and i64 %546, %544
  %548 = mul i64 %547, %544
  %549 = xor i64 %548, %544
  store i64 %549, ptr %3, align 8
  br label %308

550:                                              ; preds = %264
  %551 = load i64, ptr %3, align 8
  %552 = ptrtoint ptr %0 to i64
  %553 = zext i32 %1 to i64
  %554 = mul i64 %553, %552
  %555 = and i64 %554, %552
  %556 = or i64 %555, %551
  %557 = add i64 %556, %553
  %558 = add i64 %557, %552
  store i64 %558, ptr %3, align 8
  br label %308

559:                                              ; preds = %273
  %560 = load i64, ptr %3, align 8
  %561 = ptrtoint ptr %0 to i64
  %562 = zext i32 %1 to i64
  %563 = sub i64 %561, %562
  %564 = add i64 %563, %561
  %565 = or i64 %564, %561
  %566 = xor i64 %565, %561
  %567 = or i64 %566, %562
  %568 = mul i64 %567, %561
  store i64 %568, ptr %3, align 8
  br label %308

569:                                              ; preds = %292
  %570 = load i64, ptr %3, align 8
  %571 = ptrtoint ptr %0 to i64
  %572 = zext i32 %1 to i64
  %573 = add i64 %572, %571
  %574 = or i64 %573, %570
  %575 = xor i64 %574, %570
  %576 = sub i64 %575, %571
  store i64 %576, ptr %3, align 8
  br label %308

577:                                              ; preds = %309
  %578 = load i64, ptr %3, align 8
  %579 = ptrtoint ptr %0 to i64
  %580 = zext i32 %1 to i64
  %581 = or i64 %580, %580
  %582 = mul i64 %581, %580
  %583 = sub i64 %582, %580
  %584 = sub i64 %583, %580
  %585 = xor i64 %584, %579
  store i64 %585, ptr %3, align 8
  br label %11

586:                                              ; preds = %328
  %587 = load i64, ptr %3, align 8
  %588 = ptrtoint ptr %0 to i64
  %589 = zext i32 %1 to i64
  %590 = mul i64 %587, %588
  %591 = mul i64 %590, %589
  %592 = mul i64 %591, %589
  store i64 %592, ptr %3, align 8
  br label %308

593:                                              ; preds = %341
  %594 = load i64, ptr %3, align 8
  %595 = ptrtoint ptr %0 to i64
  %596 = zext i32 %1 to i64
  %597 = add i64 %595, %595
  %598 = mul i64 %597, %594
  %599 = or i64 %598, %594
  store i64 %599, ptr %3, align 8
  br label %308

600:                                              ; preds = %354
  %601 = load i64, ptr %3, align 8
  %602 = ptrtoint ptr %0 to i64
  %603 = zext i32 %1 to i64
  %604 = xor i64 %601, %601
  %605 = xor i64 %604, %603
  %606 = mul i64 %605, %601
  %607 = xor i64 %606, %603
  %608 = or i64 %607, %603
  store i64 %608, ptr %3, align 8
  br label %308

609:                                              ; preds = %366
  %610 = load i64, ptr %3, align 8
  %611 = ptrtoint ptr %0 to i64
  %612 = zext i32 %1 to i64
  %613 = add i64 %611, %610
  %614 = mul i64 %613, %610
  %615 = add i64 %614, %610
  %616 = sub i64 %615, %611
  %617 = sub i64 %616, %612
  store i64 %617, ptr %3, align 8
  br label %308

618:                                              ; preds = %387
  %619 = load i64, ptr %3, align 8
  %620 = ptrtoint ptr %0 to i64
  %621 = zext i32 %1 to i64
  %622 = and i64 %620, %620
  %623 = xor i64 %622, %619
  %624 = sub i64 %623, %620
  %625 = and i64 %624, %620
  %626 = add i64 %625, %620
  %627 = sub i64 %626, %621
  store i64 %627, ptr %3, align 8
  br label %308

628:                                              ; preds = %400
  %629 = load i64, ptr %3, align 8
  %630 = ptrtoint ptr %0 to i64
  %631 = zext i32 %1 to i64
  %632 = mul i64 %631, %631
  %633 = and i64 %632, %631
  %634 = sub i64 %633, %630
  %635 = mul i64 %634, %630
  %636 = add i64 %635, %629
  %637 = mul i64 %636, %629
  store i64 %637, ptr %3, align 8
  br label %308

638:                                              ; preds = %413
  %639 = load i64, ptr %3, align 8
  %640 = ptrtoint ptr %0 to i64
  %641 = zext i32 %1 to i64
  %642 = or i64 %640, %639
  %643 = mul i64 %642, %639
  %644 = and i64 %643, %641
  %645 = mul i64 %644, %639
  %646 = sub i64 %645, %639
  %647 = add i64 %646, %639
  store i64 %647, ptr %3, align 8
  br label %308

648:                                              ; preds = %432
  %649 = load i64, ptr %3, align 8
  %650 = ptrtoint ptr %0 to i64
  %651 = zext i32 %1 to i64
  %652 = mul i64 %649, %649
  %653 = and i64 %652, %649
  %654 = xor i64 %653, %650
  store i64 %654, ptr %3, align 8
  br label %308
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdOrder(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 1253398051, ptr %4, align 4
  br label %9

9:                                                ; preds = %305, %107, %106, %2
  %10 = load i32, ptr %4, align 4
  %11 = sub i32 %10, 878511248
  %12 = mul i32 %11, 35116085
  %13 = icmp slt i32 %12, 740805329
  br i1 %13, label %220, label %222

14:                                               ; preds = %248
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %15 = load i32, ptr %6, align 4
  %16 = icmp ne i32 %15, 2
  %17 = select i1 %16, i32 -1435017987, i32 1939000441
  store i32 %17, ptr %4, align 4
  %18 = xor i32 %1, 1431588257
  %19 = and i32 %1, %18
  %20 = or i32 %1, %18
  %21 = xor i32 %1, %18
  %22 = add i32 %1, %18
  %23 = sub i32 %22, %21
  %24 = mul i32 %19, 2
  %25 = sub i32 %23, %24
  %26 = mul i32 %25, 64
  %27 = icmp sgt i32 %26, 0
  br i1 %27, label %260, label %106

28:                                               ; preds = %254
  %29 = load ptr, ptr %5, align 8
  %30 = getelementptr inbounds ptr, ptr %29, i64 1
  %31 = load ptr, ptr %30, align 8
  %32 = call i32 @parseIntStrict(ptr noundef %31, ptr noundef %7)
  %33 = icmp ne i32 %32, 0
  %34 = select i1 %33, i32 -843453804, i32 -1435017987
  store i32 %34, ptr %4, align 4
  %35 = xor i32 %1, -271928715
  %36 = and i32 %1, %35
  %37 = or i32 %1, %35
  %38 = xor i32 %1, %35
  %39 = add i32 %1, %35
  %40 = sub i32 %39, %38
  %41 = mul i32 %36, 2
  %42 = sub i32 %40, %41
  %43 = mul i32 %42, 63
  %44 = icmp eq i32 %43, 0
  br i1 %44, label %106, label %268

45:                                               ; preds = %238
  %46 = call i32 (ptr, ...) @printf(ptr noundef @.str.84)
  store i32 -886628830, ptr %4, align 4
  %47 = xor i32 %1, -1276913033
  %48 = and i32 %1, %47
  %49 = or i32 %1, %47
  %50 = xor i32 %1, %47
  %51 = add i32 %48, %49
  %52 = sub i32 %51, %1
  %53 = sub i32 %52, %47
  %54 = mul i32 %53, 20
  %55 = icmp slt i32 %54, 1
  br i1 %55, label %106, label %276

56:                                               ; preds = %250
  %57 = load i32, ptr %7, align 4
  %58 = call i32 @findOrderIndexById(i32 noundef %57)
  store i32 %58, ptr %8, align 4
  %59 = load i32, ptr %8, align 4
  %60 = icmp eq i32 %59, -1
  %61 = select i1 %60, i32 1383129433, i32 213597245
  store i32 %61, ptr %4, align 4
  %62 = xor i32 %1, 505162137
  %63 = and i32 %1, %62
  %64 = or i32 %1, %62
  %65 = xor i32 %1, %62
  %66 = add i32 %63, %64
  %67 = sub i32 %66, %1
  %68 = sub i32 %67, %62
  %69 = mul i32 %68, 123
  %70 = icmp uge i32 %69, 0
  br i1 %70, label %106, label %283

71:                                               ; preds = %240
  %72 = load i32, ptr %7, align 4
  %73 = call i32 (ptr, ...) @printf(ptr noundef @.str.85, i32 noundef %72)
  store i32 -886628830, ptr %4, align 4
  %74 = xor i32 %1, 67993979
  %75 = and i32 %1, %74
  %76 = or i32 %1, %74
  %77 = xor i32 %1, %74
  %78 = sub i32 %76, %77
  %79 = sub i32 %78, %75
  %80 = mul i32 %79, 49
  %81 = xor i32 %1, -2112943037
  %82 = and i32 %1, %81
  %83 = or i32 %1, %81
  %84 = xor i32 %1, %81
  %85 = mul i32 %83, 2
  %86 = sub i32 %85, %84
  %87 = sub i32 %86, %1
  %88 = sub i32 %87, %81
  %89 = mul i32 %88, 230
  %90 = icmp eq i32 %80, %89
  br i1 %90, label %106, label %291

91:                                               ; preds = %246
  %92 = load i32, ptr %8, align 4
  %93 = sext i32 %92 to i64
  %94 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %93
  call void @printOrderDetail(ptr noundef %94)
  store i32 -886628830, ptr %4, align 4
  %95 = xor i32 %1, -1549197995
  %96 = and i32 %1, %95
  %97 = or i32 %1, %95
  %98 = xor i32 %1, %95
  %99 = add i32 %1, %95
  %100 = sub i32 %99, %98
  %101 = mul i32 %96, 2
  %102 = sub i32 %100, %101
  %103 = mul i32 %102, 4
  %104 = icmp sle i32 %103, 0
  br i1 %104, label %106, label %298

105:                                              ; preds = %230
  ret void

106:                                              ; preds = %367, %359, %351, %343, %333, %325, %315, %298, %291, %283, %276, %268, %260, %208, %196, %174, %153, %142, %130, %117, %91, %71, %56, %45, %28, %14
  br label %9

107:                                              ; preds = %258, %256, %250, %246, %240, %238, %232, %228
  store i32 1253398051, ptr %4, align 4
  call void asm sideeffect "", ""()
  %108 = xor i32 %1, 1984611443
  %109 = and i32 %1, %108
  %110 = or i32 %1, %108
  %111 = xor i32 %1, %108
  %112 = add i32 %109, %110
  %113 = sub i32 %112, %1
  %114 = sub i32 %113, %108
  %115 = mul i32 %114, 104
  %116 = icmp ugt i32 %115, 0
  br i1 %116, label %305, label %9

117:                                              ; preds = %258
  %118 = load i32, ptr %4, align 4
  %119 = xor i32 %118, 1035010022
  store i32 %119, ptr %4, align 4
  %120 = xor i32 %1, -153736985
  %121 = and i32 %1, %120
  %122 = or i32 %1, %120
  %123 = xor i32 %1, %120
  %124 = add i32 %1, %120
  %125 = sub i32 %124, %123
  %126 = mul i32 %121, 2
  %127 = sub i32 %125, %126
  %128 = mul i32 %127, 227
  %129 = icmp sle i32 %128, 0
  br i1 %129, label %106, label %315

130:                                              ; preds = %232
  %131 = load i32, ptr %4, align 4
  %132 = xor i32 %131, -561251804
  store i32 %132, ptr %4, align 4
  %133 = xor i32 %1, -410791197
  %134 = and i32 %1, %133
  %135 = or i32 %1, %133
  %136 = xor i32 %1, %133
  %137 = add i32 %134, %135
  %138 = sub i32 %137, %1
  %139 = sub i32 %138, %133
  %140 = mul i32 %139, 61
  %141 = icmp slt i32 %140, 1
  br i1 %141, label %106, label %325

142:                                              ; preds = %234
  %143 = load i32, ptr %4, align 4
  %144 = xor i32 %143, -1190443033
  store i32 %144, ptr %4, align 4
  %145 = xor i32 %1, 1734015321
  %146 = and i32 %1, %145
  %147 = or i32 %1, %145
  %148 = xor i32 %1, %145
  %149 = sub i32 %147, %148
  %150 = sub i32 %149, %146
  %151 = mul i32 %150, 111
  %152 = icmp sgt i32 %151, 0
  br i1 %152, label %333, label %106

153:                                              ; preds = %228
  %154 = load i32, ptr %4, align 4
  %155 = xor i32 %154, 687989566
  store i32 %155, ptr %4, align 4
  %156 = xor i32 %1, 1553307665
  %157 = and i32 %1, %156
  %158 = or i32 %1, %156
  %159 = xor i32 %1, %156
  %160 = add i32 %1, %156
  %161 = sub i32 %160, %159
  %162 = mul i32 %157, 2
  %163 = sub i32 %161, %162
  %164 = mul i32 %163, 182
  %165 = xor i32 %1, -1627769591
  %166 = and i32 %1, %165
  %167 = or i32 %1, %165
  %168 = xor i32 %1, %165
  %169 = add i32 %166, %167
  %170 = sub i32 %169, %1
  %171 = sub i32 %170, %165
  %172 = mul i32 %171, 15
  %173 = icmp ne i32 %164, %172
  br i1 %173, label %343, label %106

174:                                              ; preds = %256
  %175 = load i32, ptr %4, align 4
  %176 = xor i32 %175, 866357593
  store i32 %176, ptr %4, align 4
  %177 = xor i32 %1, 1583544189
  %178 = and i32 %1, %177
  %179 = or i32 %1, %177
  %180 = xor i32 %1, %177
  %181 = mul i32 %179, 2
  %182 = sub i32 %181, %180
  %183 = sub i32 %182, %1
  %184 = sub i32 %183, %177
  %185 = mul i32 %184, 177
  %186 = xor i32 %1, 364218677
  %187 = and i32 %1, %186
  %188 = or i32 %1, %186
  %189 = xor i32 %1, %186
  %190 = mul i32 %188, 2
  %191 = sub i32 %190, %189
  %192 = sub i32 %191, %1
  %193 = sub i32 %192, %186
  %194 = mul i32 %193, 232
  %195 = icmp eq i32 %185, %194
  br i1 %195, label %106, label %351

196:                                              ; preds = %252
  %197 = load i32, ptr %4, align 4
  %198 = xor i32 %197, 1417404565
  store i32 %198, ptr %4, align 4
  %199 = xor i32 %1, 1164551307
  %200 = and i32 %1, %199
  %201 = or i32 %1, %199
  %202 = xor i32 %1, %199
  %203 = add i32 %200, %201
  %204 = sub i32 %203, %1
  %205 = sub i32 %204, %199
  %206 = mul i32 %205, 172
  %207 = icmp sle i32 %206, 0
  br i1 %207, label %106, label %359

208:                                              ; preds = %236
  %209 = load i32, ptr %4, align 4
  %210 = xor i32 %209, -1739724502
  store i32 %210, ptr %4, align 4
  %211 = xor i32 %1, 2048649101
  %212 = and i32 %1, %211
  %213 = or i32 %1, %211
  %214 = xor i32 %1, %211
  %215 = add i32 %212, %213
  %216 = sub i32 %215, %1
  %217 = sub i32 %216, %211
  %218 = mul i32 %217, 103
  %219 = icmp ne i32 %218, 0
  br i1 %219, label %367, label %106

220:                                              ; preds = %9
  %221 = icmp slt i32 %12, 157716498
  br i1 %221, label %224, label %226

222:                                              ; preds = %9
  %223 = icmp slt i32 %12, 1669104412
  br i1 %223, label %242, label %244

224:                                              ; preds = %220
  %225 = icmp slt i32 %12, 86127418
  br i1 %225, label %228, label %230

226:                                              ; preds = %220
  %227 = icmp slt i32 %12, 333362265
  br i1 %227, label %234, label %236

228:                                              ; preds = %224
  %229 = icmp eq i32 %12, 43015094
  br i1 %229, label %153, label %107

230:                                              ; preds = %224
  %231 = icmp eq i32 %12, 86127418
  br i1 %231, label %105, label %232

232:                                              ; preds = %230
  %233 = icmp eq i32 %12, 123291366
  br i1 %233, label %130, label %107

234:                                              ; preds = %226
  %235 = icmp eq i32 %12, 157716498
  br i1 %235, label %142, label %238

236:                                              ; preds = %226
  %237 = icmp eq i32 %12, 333362265
  br i1 %237, label %208, label %240

238:                                              ; preds = %234
  %239 = icmp eq i32 %12, 276402833
  br i1 %239, label %45, label %107

240:                                              ; preds = %236
  %241 = icmp eq i32 %12, 352463261
  br i1 %241, label %71, label %107

242:                                              ; preds = %222
  %243 = icmp slt i32 %12, 1040949103
  br i1 %243, label %246, label %248

244:                                              ; preds = %222
  %245 = icmp slt i32 %12, 1738430269
  br i1 %245, label %252, label %254

246:                                              ; preds = %242
  %247 = icmp eq i32 %12, 740805329
  br i1 %247, label %91, label %107

248:                                              ; preds = %242
  %249 = icmp eq i32 %12, 1040949103
  br i1 %249, label %14, label %250

250:                                              ; preds = %248
  %251 = icmp eq i32 %12, 1628630740
  br i1 %251, label %56, label %107

252:                                              ; preds = %244
  %253 = icmp eq i32 %12, 1669104412
  br i1 %253, label %196, label %256

254:                                              ; preds = %244
  %255 = icmp eq i32 %12, 1738430269
  br i1 %255, label %28, label %258

256:                                              ; preds = %252
  %257 = icmp eq i32 %12, 1676315713
  br i1 %257, label %174, label %107

258:                                              ; preds = %254
  %259 = icmp eq i32 %12, 1784598837
  br i1 %259, label %117, label %107

260:                                              ; preds = %14
  %261 = load i64, ptr %3, align 8
  %262 = ptrtoint ptr %0 to i64
  %263 = zext i32 %1 to i64
  %264 = and i64 %262, %262
  %265 = or i64 %264, %263
  %266 = add i64 %265, %263
  %267 = mul i64 %266, %263
  store i64 %267, ptr %3, align 8
  br label %106

268:                                              ; preds = %28
  %269 = load i64, ptr %3, align 8
  %270 = ptrtoint ptr %0 to i64
  %271 = zext i32 %1 to i64
  %272 = sub i64 %270, %269
  %273 = sub i64 %272, %271
  %274 = mul i64 %273, %270
  %275 = or i64 %274, %269
  store i64 %275, ptr %3, align 8
  br label %106

276:                                              ; preds = %45
  %277 = load i64, ptr %3, align 8
  %278 = ptrtoint ptr %0 to i64
  %279 = zext i32 %1 to i64
  %280 = xor i64 %277, %277
  %281 = or i64 %280, %279
  %282 = mul i64 %281, %278
  store i64 %282, ptr %3, align 8
  br label %106

283:                                              ; preds = %56
  %284 = load i64, ptr %3, align 8
  %285 = ptrtoint ptr %0 to i64
  %286 = zext i32 %1 to i64
  %287 = or i64 %285, %284
  %288 = xor i64 %287, %285
  %289 = add i64 %288, %286
  %290 = sub i64 %289, %284
  store i64 %290, ptr %3, align 8
  br label %106

291:                                              ; preds = %71
  %292 = load i64, ptr %3, align 8
  %293 = ptrtoint ptr %0 to i64
  %294 = zext i32 %1 to i64
  %295 = sub i64 %293, %292
  %296 = sub i64 %295, %293
  %297 = add i64 %296, %292
  store i64 %297, ptr %3, align 8
  br label %106

298:                                              ; preds = %91
  %299 = load i64, ptr %3, align 8
  %300 = ptrtoint ptr %0 to i64
  %301 = zext i32 %1 to i64
  %302 = or i64 %300, %300
  %303 = add i64 %302, %300
  %304 = and i64 %303, %300
  store i64 %304, ptr %3, align 8
  br label %106

305:                                              ; preds = %107
  %306 = load i64, ptr %3, align 8
  %307 = ptrtoint ptr %0 to i64
  %308 = zext i32 %1 to i64
  %309 = xor i64 %307, %306
  %310 = or i64 %309, %307
  %311 = sub i64 %310, %307
  %312 = sub i64 %311, %306
  %313 = or i64 %312, %307
  %314 = sub i64 %313, %308
  store i64 %314, ptr %3, align 8
  br label %9

315:                                              ; preds = %117
  %316 = load i64, ptr %3, align 8
  %317 = ptrtoint ptr %0 to i64
  %318 = zext i32 %1 to i64
  %319 = xor i64 %316, %316
  %320 = xor i64 %319, %316
  %321 = mul i64 %320, %318
  %322 = mul i64 %321, %318
  %323 = xor i64 %322, %317
  %324 = sub i64 %323, %317
  store i64 %324, ptr %3, align 8
  br label %106

325:                                              ; preds = %130
  %326 = load i64, ptr %3, align 8
  %327 = ptrtoint ptr %0 to i64
  %328 = zext i32 %1 to i64
  %329 = or i64 %327, %328
  %330 = sub i64 %329, %328
  %331 = sub i64 %330, %328
  %332 = xor i64 %331, %328
  store i64 %332, ptr %3, align 8
  br label %106

333:                                              ; preds = %142
  %334 = load i64, ptr %3, align 8
  %335 = ptrtoint ptr %0 to i64
  %336 = zext i32 %1 to i64
  %337 = sub i64 %335, %334
  %338 = or i64 %337, %334
  %339 = sub i64 %338, %336
  %340 = mul i64 %339, %334
  %341 = sub i64 %340, %335
  %342 = and i64 %341, %335
  store i64 %342, ptr %3, align 8
  br label %106

343:                                              ; preds = %153
  %344 = load i64, ptr %3, align 8
  %345 = ptrtoint ptr %0 to i64
  %346 = zext i32 %1 to i64
  %347 = mul i64 %344, %344
  %348 = xor i64 %347, %344
  %349 = and i64 %348, %344
  %350 = xor i64 %349, %345
  store i64 %350, ptr %3, align 8
  br label %106

351:                                              ; preds = %174
  %352 = load i64, ptr %3, align 8
  %353 = ptrtoint ptr %0 to i64
  %354 = zext i32 %1 to i64
  %355 = sub i64 %352, %352
  %356 = xor i64 %355, %353
  %357 = and i64 %356, %354
  %358 = add i64 %357, %354
  store i64 %358, ptr %3, align 8
  br label %106

359:                                              ; preds = %196
  %360 = load i64, ptr %3, align 8
  %361 = ptrtoint ptr %0 to i64
  %362 = zext i32 %1 to i64
  %363 = and i64 %362, %362
  %364 = or i64 %363, %362
  %365 = or i64 %364, %360
  %366 = xor i64 %365, %360
  store i64 %366, ptr %3, align 8
  br label %106

367:                                              ; preds = %208
  %368 = load i64, ptr %3, align 8
  %369 = ptrtoint ptr %0 to i64
  %370 = zext i32 %1 to i64
  %371 = xor i64 %370, %370
  %372 = mul i64 %371, %368
  %373 = add i64 %372, %368
  %374 = xor i64 %373, %369
  %375 = sub i64 %374, %370
  store i64 %375, ptr %3, align 8
  br label %106
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdOrders() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @1, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 983634682, ptr %3, align 4
  br label %6

6:                                                ; preds = %215, %106, %105, %0
  %7 = load i32, ptr %3, align 4
  %8 = sub i32 %7, -446642527
  %9 = mul i32 %8, 1939195251
  switch i32 %9, label %106 [
    i32 829409531, label %10
    i32 1187046164, label %28
    i32 1310873344, label %42
    i32 421324923, label %71
    i32 303161691, label %94
    i32 1501840768, label %104
    i32 721763871, label %116
    i32 810055902, label %127
    i32 1675494046, label %138
    i32 79440379, label %159
    i32 1477312200, label %172
    i32 989280759, label %184
  ]

10:                                               ; preds = %6
  store i32 0, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 -1372212675, ptr %3, align 4
  %11 = xor i32 %2, -74700367
  %12 = and i32 %2, %11
  %13 = or i32 %2, %11
  %14 = xor i32 %2, %11
  %15 = add i32 %2, %11
  %16 = sub i32 %15, %14
  %17 = mul i32 %12, 2
  %18 = sub i32 %16, %17
  %19 = mul i32 %18, 166
  %20 = xor i32 %2, -2135361281
  %21 = and i32 %2, %20
  %22 = or i32 %2, %20
  %23 = xor i32 %2, %20
  %24 = sub i32 %22, %23
  %25 = sub i32 %24, %21
  %26 = mul i32 %25, 93
  %27 = icmp ne i32 %19, %26
  br i1 %27, label %195, label %105

28:                                               ; preds = %6
  %29 = load i32, ptr %5, align 4
  %30 = load i32, ptr @orderCount, align 4
  %31 = icmp slt i32 %29, %30
  %32 = select i1 %31, i32 -1963502687, i32 -1065118342
  store i32 %32, ptr %3, align 4
  %33 = xor i32 %2, -1432543439
  %34 = and i32 %2, %33
  %35 = or i32 %2, %33
  %36 = xor i32 %2, %33
  %37 = add i32 %34, %35
  %38 = sub i32 %37, %2
  %39 = sub i32 %38, %33
  %40 = mul i32 %39, 192
  %41 = icmp sgt i32 %40, 0
  br i1 %41, label %202, label %105

42:                                               ; preds = %6
  %43 = load i32, ptr %5, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %44
  call void @printOrderShort(ptr noundef %45)
  store i32 1, ptr %4, align 4
  %46 = load i32, ptr %5, align 4
  %47 = load i32, ptr %3, align 4
  %48 = xor i32 %47, -1963502688
  %49 = or i32 %46, %48
  %50 = load i32, ptr %3, align 4
  %51 = xor i32 %50, -1963502688
  %52 = and i32 %46, %51
  %53 = add i32 %49, %52
  store i32 %53, ptr %5, align 4
  store i32 -1372212675, ptr %3, align 4
  %54 = xor i32 %2, -116440191
  %55 = and i32 %2, %54
  %56 = or i32 %2, %54
  %57 = xor i32 %2, %54
  %58 = mul i32 %56, 2
  %59 = sub i32 %58, %57
  %60 = sub i32 %59, %2
  %61 = sub i32 %60, %54
  %62 = mul i32 %61, 199
  %63 = xor i32 %2, -631817917
  %64 = and i32 %2, %63
  %65 = or i32 %2, %63
  %66 = xor i32 %2, %63
  %67 = sub i32 %65, %66
  %68 = sub i32 %67, %64
  %69 = mul i32 %68, 7
  %70 = icmp eq i32 %62, %69
  br i1 %70, label %105, label %204

71:                                               ; preds = %6
  %72 = load i32, ptr %4, align 4
  %73 = icmp ne i32 %72, 0
  %74 = select i1 %73, i32 313920289, i32 1724350746
  store i32 %74, ptr %3, align 4
  %75 = xor i32 %2, -1874981421
  %76 = and i32 %2, %75
  %77 = or i32 %2, %75
  %78 = xor i32 %2, %75
  %79 = mul i32 %77, 2
  %80 = sub i32 %79, %78
  %81 = sub i32 %80, %2
  %82 = sub i32 %81, %75
  %83 = mul i32 %82, 164
  %84 = xor i32 %2, -2045134445
  %85 = and i32 %2, %84
  %86 = or i32 %2, %84
  %87 = xor i32 %2, %84
  %88 = mul i32 %86, 2
  %89 = sub i32 %88, %87
  %90 = sub i32 %89, %2
  %91 = sub i32 %90, %84
  %92 = mul i32 %91, 213
  %93 = icmp eq i32 %83, %92
  br i1 %93, label %105, label %208

94:                                               ; preds = %6
  %95 = call i32 (ptr, ...) @printf(ptr noundef @.str.86)
  store i32 313920289, ptr %3, align 4
  %96 = xor i32 %2, -1703708971
  %97 = and i32 %2, %96
  %98 = or i32 %2, %96
  %99 = xor i32 %2, %96
  %100 = sub i32 %98, %99
  %101 = sub i32 %100, %97
  %102 = mul i32 %101, 57
  %103 = icmp eq i32 %102, 0
  br i1 %103, label %105, label %213

104:                                              ; preds = %6
  ret void

105:                                              ; preds = %242, %240, %237, %231, %228, %221, %213, %208, %204, %202, %195, %184, %172, %159, %138, %127, %116, %94, %71, %42, %28, %10
  br label %6

106:                                              ; preds = %6
  store i32 983634682, ptr %3, align 4
  call void asm sideeffect "", ""()
  %107 = xor i32 %2, -897749469
  %108 = and i32 %2, %107
  %109 = or i32 %2, %107
  %110 = xor i32 %2, %107
  %111 = add i32 %108, %109
  %112 = sub i32 %111, %2
  %113 = sub i32 %112, %107
  %114 = mul i32 %113, 157
  %115 = icmp ugt i32 %114, 0
  br i1 %115, label %215, label %6

116:                                              ; preds = %6
  %117 = load i32, ptr %3, align 4
  %118 = xor i32 %117, -923275509
  store i32 %118, ptr %3, align 4
  %119 = xor i32 %2, -742646827
  %120 = and i32 %2, %119
  %121 = or i32 %2, %119
  %122 = xor i32 %2, %119
  %123 = sub i32 %121, %122
  %124 = sub i32 %123, %120
  %125 = mul i32 %124, 37
  %126 = icmp slt i32 %125, 0
  br i1 %126, label %221, label %105

127:                                              ; preds = %6
  %128 = load i32, ptr %3, align 4
  %129 = xor i32 %128, -112719493
  store i32 %129, ptr %3, align 4
  %130 = xor i32 %2, 1512899521
  %131 = and i32 %2, %130
  %132 = or i32 %2, %130
  %133 = xor i32 %2, %130
  %134 = sub i32 %132, %133
  %135 = sub i32 %134, %131
  %136 = mul i32 %135, 106
  %137 = icmp eq i32 %136, 0
  br i1 %137, label %105, label %228

138:                                              ; preds = %6
  %139 = load i32, ptr %3, align 4
  %140 = xor i32 %139, 700569508
  store i32 %140, ptr %3, align 4
  %141 = xor i32 %2, 1385316515
  %142 = and i32 %2, %141
  %143 = or i32 %2, %141
  %144 = xor i32 %2, %141
  %145 = add i32 %142, %143
  %146 = sub i32 %145, %2
  %147 = sub i32 %146, %141
  %148 = mul i32 %147, 199
  %149 = xor i32 %2, 114053475
  %150 = and i32 %2, %149
  %151 = or i32 %2, %149
  %152 = xor i32 %2, %149
  %153 = add i32 %2, %149
  %154 = sub i32 %153, %152
  %155 = mul i32 %150, 2
  %156 = sub i32 %154, %155
  %157 = mul i32 %156, 79
  %158 = icmp ne i32 %148, %157
  br i1 %158, label %231, label %105

159:                                              ; preds = %6
  %160 = load i32, ptr %3, align 4
  %161 = xor i32 %160, -96047220
  store i32 %161, ptr %3, align 4
  %162 = xor i32 %2, 357386851
  %163 = and i32 %2, %162
  %164 = or i32 %2, %162
  %165 = xor i32 %2, %162
  %166 = add i32 %2, %162
  %167 = sub i32 %166, %165
  %168 = mul i32 %163, 2
  %169 = sub i32 %167, %168
  %170 = mul i32 %169, 27
  %171 = icmp ne i32 %170, 0
  br i1 %171, label %237, label %105

172:                                              ; preds = %6
  %173 = load i32, ptr %3, align 4
  %174 = xor i32 %173, 823755804
  store i32 %174, ptr %3, align 4
  %175 = xor i32 %2, 593939877
  %176 = and i32 %2, %175
  %177 = or i32 %2, %175
  %178 = xor i32 %2, %175
  %179 = add i32 %176, %177
  %180 = sub i32 %179, %2
  %181 = sub i32 %180, %175
  %182 = mul i32 %181, 79
  %183 = icmp sle i32 %182, 0
  br i1 %183, label %105, label %240

184:                                              ; preds = %6
  %185 = load i32, ptr %3, align 4
  %186 = xor i32 %185, 833747865
  store i32 %186, ptr %3, align 4
  %187 = xor i32 %2, -1956088075
  %188 = and i32 %2, %187
  %189 = or i32 %2, %187
  %190 = xor i32 %2, %187
  %191 = sub i32 %189, %190
  %192 = sub i32 %191, %188
  %193 = mul i32 %192, 240
  %194 = icmp ne i32 %193, 0
  br i1 %194, label %242, label %105

195:                                              ; preds = %10
  %196 = load i64, ptr %1, align 8
  %197 = and i64 512261409, %196
  %198 = xor i64 %197, %196
  %199 = xor i64 %198, %196
  %200 = and i64 %199, %196
  %201 = sub i64 %200, 2374960231
  store i64 %201, ptr %1, align 8
  br label %105

202:                                              ; preds = %28
  %203 = load i64, ptr %1, align 8
  store i64 -3550475525, ptr %1, align 8
  br label %105

204:                                              ; preds = %42
  %205 = load i64, ptr %1, align 8
  %206 = add i64 3186093993, %205
  %207 = and i64 %206, 3186093993
  store i64 %207, ptr %1, align 8
  br label %105

208:                                              ; preds = %71
  %209 = load i64, ptr %1, align 8
  %210 = xor i64 %209, 197314992
  %211 = and i64 %210, 128321693
  %212 = add i64 %211, 197314992
  store i64 %212, ptr %1, align 8
  br label %105

213:                                              ; preds = %94
  %214 = load i64, ptr %1, align 8
  store i64 2501340841, ptr %1, align 8
  br label %105

215:                                              ; preds = %106
  %216 = load i64, ptr %1, align 8
  %217 = sub i64 294857748, %216
  %218 = or i64 %217, 488259761
  %219 = mul i64 %218, %216
  %220 = add i64 %219, %216
  store i64 %220, ptr %1, align 8
  br label %6

221:                                              ; preds = %116
  %222 = load i64, ptr %1, align 8
  %223 = or i64 %222, %222
  %224 = sub i64 %223, %222
  %225 = add i64 %224, 991924795
  %226 = xor i64 %225, 991924795
  %227 = mul i64 %226, 2301442532
  store i64 %227, ptr %1, align 8
  br label %105

228:                                              ; preds = %127
  %229 = load i64, ptr %1, align 8
  %230 = mul i64 4291624958, %229
  store i64 %230, ptr %1, align 8
  br label %105

231:                                              ; preds = %138
  %232 = load i64, ptr %1, align 8
  %233 = and i64 2273541535, %232
  %234 = and i64 %233, 3296001401
  %235 = sub i64 %234, 3296001401
  %236 = sub i64 %235, %232
  store i64 %236, ptr %1, align 8
  br label %105

237:                                              ; preds = %159
  %238 = load i64, ptr %1, align 8
  %239 = or i64 1006073924, %238
  store i64 %239, ptr %1, align 8
  br label %105

240:                                              ; preds = %172
  %241 = load i64, ptr %1, align 8
  store i64 14688256, ptr %1, align 8
  br label %105

242:                                              ; preds = %184
  %243 = load i64, ptr %1, align 8
  %244 = and i64 3512167692, %243
  %245 = or i64 %244, %243
  %246 = mul i64 %245, %243
  %247 = and i64 %246, 2869517092
  %248 = mul i64 %247, 2869517092
  store i64 %248, ptr %1, align 8
  br label %105
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdReport() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @2, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i64, align 8
  %10 = alloca i64, align 8
  %11 = alloca i64, align 8
  %12 = alloca i64, align 8
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  %15 = alloca i32, align 4
  %16 = alloca i32, align 4
  %17 = alloca i32, align 4
  store i32 -1443923634, ptr %3, align 4
  br label %18

18:                                               ; preds = %695, %465, %464, %0
  %19 = load i32, ptr %3, align 4
  %20 = sub i32 %19, -120076212
  %21 = mul i32 %20, -975166275
  switch i32 %21, label %465 [
    i32 2132932218, label %22
    i32 1050976466, label %33
    i32 1596765115, label %47
    i32 1762423476, label %72
    i32 778322264, label %90
    i32 137363936, label %165
    i32 1341231293, label %183
    i32 325325493, label %215
    i32 365469322, label %225
    i32 331943481, label %245
    i32 988945122, label %264
    i32 181345405, label %278
    i32 487039232, label %302
    i32 1849951468, label %338
    i32 1442659, label %359
    i32 2000634525, label %370
    i32 279575091, label %388
    i32 2142639427, label %427
    i32 666278127, label %439
    i32 1194507512, label %450
    i32 1348584465, label %463
    i32 244278017, label %474
    i32 303666692, label %487
    i32 286221221, label %500
    i32 40112578, label %522
    i32 380542651, label %535
    i32 1374250028, label %554
    i32 1215426249, label %565
    i32 556783313, label %578
  ]

22:                                               ; preds = %18
  store i32 0, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  store i64 0, ptr %7, align 8
  store i64 0, ptr %8, align 8
  store i64 0, ptr %9, align 8
  store i64 0, ptr %10, align 8
  store i64 0, ptr %11, align 8
  store i64 0, ptr %12, align 8
  store i32 -1, ptr %13, align 4
  store i32 -1, ptr %14, align 4
  store i32 0, ptr %15, align 4
  store i32 -1761268090, ptr %3, align 4
  %23 = xor i32 %2, -1784580831
  %24 = and i32 %2, %23
  %25 = or i32 %2, %23
  %26 = xor i32 %2, %23
  %27 = mul i32 %25, 2
  %28 = sub i32 %27, %26
  %29 = sub i32 %28, %2
  %30 = sub i32 %29, %23
  %31 = mul i32 %30, 192
  %32 = icmp eq i32 %31, 0
  br i1 %32, label %464, label %589

33:                                               ; preds = %18
  %34 = load i32, ptr %15, align 4
  %35 = load i32, ptr @orderCount, align 4
  %36 = icmp slt i32 %34, %35
  %37 = select i1 %36, i32 -976415197, i32 -1321151111
  store i32 %37, ptr %3, align 4
  %38 = xor i32 %2, -1569388709
  %39 = and i32 %2, %38
  %40 = or i32 %2, %38
  %41 = xor i32 %2, %38
  %42 = add i32 %39, %40
  %43 = sub i32 %42, %2
  %44 = sub i32 %43, %38
  %45 = mul i32 %44, 255
  %46 = icmp sgt i32 %45, 0
  br i1 %46, label %594, label %464

47:                                               ; preds = %18
  %48 = load i32, ptr %15, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %49
  %51 = getelementptr inbounds nuw %struct.Order, ptr %50, i32 0, i32 10
  %52 = load i32, ptr %51, align 8
  %53 = icmp ne i32 %52, 0
  %54 = select i1 %53, i32 402883344, i32 1297375364
  store i32 %54, ptr %3, align 4
  %55 = xor i32 %2, -1675779361
  %56 = and i32 %2, %55
  %57 = or i32 %2, %55
  %58 = xor i32 %2, %55
  %59 = add i32 %56, %57
  %60 = sub i32 %59, %2
  %61 = sub i32 %60, %55
  %62 = mul i32 %61, 39
  %63 = xor i32 %2, 151607911
  %64 = and i32 %2, %63
  %65 = or i32 %2, %63
  %66 = xor i32 %2, %63
  %67 = add i32 %64, %65
  %68 = sub i32 %67, %2
  %69 = sub i32 %68, %63
  %70 = mul i32 %69, 39
  %71 = icmp ne i32 %62, %70
  br i1 %71, label %596, label %464

72:                                               ; preds = %18
  %73 = load i32, ptr %5, align 4
  %74 = load i32, ptr %3, align 4
  %75 = xor i32 %74, 402883345
  %76 = or i32 %73, %75
  %77 = load i32, ptr %3, align 4
  %78 = xor i32 %77, 402883345
  %79 = and i32 %73, %78
  %80 = add i32 %76, %79
  store i32 %80, ptr %5, align 4
  store i32 -1904301410, ptr %3, align 4
  %81 = xor i32 %2, -1632164985
  %82 = and i32 %2, %81
  %83 = or i32 %2, %81
  %84 = xor i32 %2, %81
  %85 = add i32 %82, %83
  %86 = sub i32 %85, %2
  %87 = sub i32 %86, %81
  %88 = mul i32 %87, 245
  %89 = icmp ne i32 %88, 0
  br i1 %89, label %601, label %464

90:                                               ; preds = %18
  %91 = load i32, ptr %4, align 4
  %92 = load i32, ptr %3, align 4
  %93 = xor i32 %92, 1297375365
  %94 = or i32 %91, %93
  %95 = load i32, ptr %3, align 4
  %96 = xor i32 %95, 1297375365
  %97 = and i32 %91, %96
  %98 = add i32 %94, %97
  store i32 %98, ptr %4, align 4
  %99 = load i32, ptr %15, align 4
  %100 = sext i32 %99 to i64
  %101 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %100
  %102 = getelementptr inbounds nuw %struct.Order, ptr %101, i32 0, i32 5
  %103 = load i64, ptr %102, align 16
  %104 = load i64, ptr %7, align 8
  %105 = add i64 %103, 1
  %106 = sub i64 %104, 1
  %107 = mul i64 %104, %105
  %108 = mul i64 %103, %106
  %109 = sub i64 %107, %108
  store i64 %109, ptr %7, align 8
  %110 = load i32, ptr %15, align 4
  %111 = sext i32 %110 to i64
  %112 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %111
  %113 = getelementptr inbounds nuw %struct.Order, ptr %112, i32 0, i32 6
  %114 = load i64, ptr %113, align 8
  %115 = load i64, ptr %8, align 8
  %116 = or i64 %115, %114
  %117 = and i64 %115, %114
  %118 = add i64 %116, %117
  store i64 %118, ptr %8, align 8
  %119 = load i32, ptr %15, align 4
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %120
  %122 = getelementptr inbounds nuw %struct.Order, ptr %121, i32 0, i32 7
  %123 = load i64, ptr %122, align 16
  %124 = load i64, ptr %9, align 8
  %125 = xor i64 %124, %123
  %126 = and i64 %124, %123
  %127 = add i64 %126, %126
  %128 = add i64 %125, %127
  store i64 %128, ptr %9, align 8
  %129 = load i32, ptr %15, align 4
  %130 = sext i32 %129 to i64
  %131 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %130
  %132 = getelementptr inbounds nuw %struct.Order, ptr %131, i32 0, i32 8
  %133 = load i64, ptr %132, align 8
  %134 = load i64, ptr %10, align 8
  %135 = or i64 %134, %133
  %136 = and i64 %134, %133
  %137 = add i64 %135, %136
  store i64 %137, ptr %10, align 8
  %138 = load i32, ptr %15, align 4
  %139 = sext i32 %138 to i64
  %140 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %139
  %141 = getelementptr inbounds nuw %struct.Order, ptr %140, i32 0, i32 9
  %142 = load i64, ptr %141, align 16
  %143 = load i64, ptr %11, align 8
  %144 = xor i64 %143, %142
  %145 = and i64 %143, %142
  %146 = add i64 %145, %145
  %147 = add i64 %144, %146
  store i64 %147, ptr %11, align 8
  store i32 0, ptr %16, align 4
  store i32 276176812, ptr %3, align 4
  %148 = xor i32 %2, 183433309
  %149 = and i32 %2, %148
  %150 = or i32 %2, %148
  %151 = xor i32 %2, %148
  %152 = mul i32 %150, 2
  %153 = sub i32 %152, %151
  %154 = sub i32 %153, %2
  %155 = sub i32 %154, %148
  %156 = mul i32 %155, 218
  %157 = xor i32 %2, 45058091
  %158 = and i32 %2, %157
  %159 = or i32 %2, %157
  %160 = xor i32 %2, %157
  %161 = sub i32 %159, %160
  %162 = sub i32 %161, %158
  %163 = mul i32 %162, 77
  %164 = icmp ne i32 %156, %163
  br i1 %164, label %609, label %464

165:                                              ; preds = %18
  %166 = load i32, ptr %16, align 4
  %167 = load i32, ptr %15, align 4
  %168 = sext i32 %167 to i64
  %169 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %168
  %170 = getelementptr inbounds nuw %struct.Order, ptr %169, i32 0, i32 4
  %171 = load i32, ptr %170, align 8
  %172 = icmp slt i32 %166, %171
  %173 = select i1 %172, i32 2126750797, i32 -1757046363
  store i32 %173, ptr %3, align 4
  %174 = xor i32 %2, -113294855
  %175 = and i32 %2, %174
  %176 = or i32 %2, %174
  %177 = xor i32 %2, %174
  %178 = add i32 %175, %176
  %179 = sub i32 %178, %2
  %180 = sub i32 %179, %174
  %181 = mul i32 %180, 13
  %182 = icmp sgt i32 %181, 0
  br i1 %182, label %612, label %464

183:                                              ; preds = %18
  %184 = load i32, ptr %15, align 4
  %185 = sext i32 %184 to i64
  %186 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %185
  %187 = getelementptr inbounds nuw %struct.Order, ptr %186, i32 0, i32 3
  %188 = load i32, ptr %16, align 4
  %189 = sext i32 %188 to i64
  %190 = getelementptr inbounds [64 x %struct.OrderItem], ptr %187, i64 0, i64 %189
  %191 = getelementptr inbounds nuw %struct.OrderItem, ptr %190, i32 0, i32 2
  %192 = load i32, ptr %191, align 4
  %193 = load i32, ptr %6, align 4
  %194 = xor i32 %193, %192
  %195 = and i32 %193, %192
  %196 = add i32 %195, %195
  %197 = add i32 %194, %196
  store i32 %197, ptr %6, align 4
  %198 = load i32, ptr %16, align 4
  %199 = load i32, ptr %3, align 4
  %200 = xor i32 %199, 2126750796
  %201 = or i32 %198, %200
  %202 = load i32, ptr %3, align 4
  %203 = xor i32 %202, 2126750796
  %204 = and i32 %198, %203
  %205 = add i32 %201, %204
  store i32 %205, ptr %16, align 4
  store i32 276176812, ptr %3, align 4
  %206 = xor i32 %2, -1207151091
  %207 = and i32 %2, %206
  %208 = or i32 %2, %206
  %209 = xor i32 %2, %206
  %210 = add i32 %207, %208
  %211 = sub i32 %210, %2
  %212 = sub i32 %211, %206
  %213 = mul i32 %212, 247
  %214 = icmp eq i32 %213, 0
  br i1 %214, label %464, label %617

215:                                              ; preds = %18
  store i32 -1904301410, ptr %3, align 4
  %216 = xor i32 %2, 1190966113
  %217 = and i32 %2, %216
  %218 = or i32 %2, %216
  %219 = xor i32 %2, %216
  %220 = add i32 %217, %218
  %221 = sub i32 %220, %2
  %222 = sub i32 %221, %216
  %223 = mul i32 %222, 223
  %224 = icmp ugt i32 %223, 0
  br i1 %224, label %625, label %464

225:                                              ; preds = %18
  %226 = load i32, ptr %15, align 4
  %227 = load i32, ptr %3, align 4
  %228 = xor i32 %227, -1904301409
  %229 = xor i32 %226, %228
  %230 = load i32, ptr %3, align 4
  %231 = xor i32 %230, -1904301409
  %232 = and i32 %226, %231
  %233 = add i32 %232, %232
  %234 = add i32 %229, %233
  store i32 %234, ptr %15, align 4
  store i32 -1761268090, ptr %3, align 4
  %235 = xor i32 %2, -311285203
  %236 = and i32 %2, %235
  %237 = or i32 %2, %235
  %238 = xor i32 %2, %235
  %239 = add i32 %2, %235
  %240 = sub i32 %239, %238
  %241 = mul i32 %236, 2
  %242 = sub i32 %240, %241
  %243 = mul i32 %242, 8
  %244 = icmp slt i32 %243, 0
  br i1 %244, label %633, label %464

245:                                              ; preds = %18
  store i32 0, ptr %17, align 4
  store i32 -981952042, ptr %3, align 4
  %246 = xor i32 %2, 1812671915
  %247 = and i32 %2, %246
  %248 = or i32 %2, %246
  %249 = xor i32 %2, %246
  %250 = add i32 %247, %248
  %251 = sub i32 %250, %2
  %252 = sub i32 %251, %246
  %253 = mul i32 %252, 196
  %254 = xor i32 %2, -551210487
  %255 = and i32 %2, %254
  %256 = or i32 %2, %254
  %257 = xor i32 %2, %254
  %258 = add i32 %2, %254
  %259 = sub i32 %258, %257
  %260 = mul i32 %255, 2
  %261 = sub i32 %259, %260
  %262 = mul i32 %261, 129
  %263 = icmp eq i32 %253, %262
  br i1 %263, label %464, label %641

264:                                              ; preds = %18
  %265 = load i32, ptr %17, align 4
  %266 = load i32, ptr @productCount, align 4
  %267 = icmp slt i32 %265, %266
  %268 = select i1 %267, i32 297827085, i32 -941200901
  store i32 %268, ptr %3, align 4
  %269 = xor i32 %2, -1280508233
  %270 = and i32 %2, %269
  %271 = or i32 %2, %269
  %272 = xor i32 %2, %269
  %273 = add i32 %270, %271
  %274 = sub i32 %273, %2
  %275 = sub i32 %274, %269
  %276 = mul i32 %275, 116
  %277 = icmp uge i32 %276, 0
  br i1 %277, label %464, label %648

278:                                              ; preds = %18
  %279 = load i32, ptr %17, align 4
  %280 = sext i32 %279 to i64
  %281 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %280
  %282 = getelementptr inbounds nuw %struct.Product, ptr %281, i32 0, i32 6
  %283 = load i32, ptr %282, align 8
  %284 = icmp ne i32 %283, 0
  %285 = select i1 %284, i32 1409187148, i32 -372675667
  store i32 %285, ptr %3, align 4
  %286 = xor i32 %2, 963990415
  %287 = and i32 %2, %286
  %288 = or i32 %2, %286
  %289 = xor i32 %2, %286
  %290 = add i32 %287, %288
  %291 = sub i32 %290, %2
  %292 = sub i32 %291, %286
  %293 = mul i32 %292, 140
  %294 = xor i32 %2, 126353963
  %295 = and i32 %2, %294
  %296 = or i32 %2, %294
  %297 = xor i32 %2, %294
  %298 = sub i32 %296, %297
  %299 = sub i32 %298, %295
  %300 = mul i32 %299, 243
  %301 = icmp ne i32 %293, %300
  br i1 %301, label %653, label %464

302:                                              ; preds = %18
  %303 = load i32, ptr %17, align 4
  %304 = sext i32 %303 to i64
  %305 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %304
  %306 = getelementptr inbounds nuw %struct.Product, ptr %305, i32 0, i32 3
  %307 = load i64, ptr %306, align 8
  %308 = load i32, ptr %17, align 4
  %309 = sext i32 %308 to i64
  %310 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %309
  %311 = getelementptr inbounds nuw %struct.Product, ptr %310, i32 0, i32 4
  %312 = load i32, ptr %311, align 16
  %313 = sext i32 %312 to i64
  %314 = mul nsw i64 %307, %313
  %315 = load i64, ptr %12, align 8
  %316 = xor i64 %315, %314
  %317 = and i64 %315, %314
  %318 = add i64 %317, %317
  %319 = add i64 %316, %318
  store i64 %319, ptr %12, align 8
  %320 = load i32, ptr %17, align 4
  %321 = sext i32 %320 to i64
  %322 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %321
  %323 = getelementptr inbounds nuw %struct.Product, ptr %322, i32 0, i32 5
  %324 = load i32, ptr %323, align 4
  %325 = load i32, ptr %14, align 4
  %326 = icmp sgt i32 %324, %325
  %327 = select i1 %326, i32 -2045416024, i32 -1278483733
  store i32 %327, ptr %3, align 4
  %328 = xor i32 %2, -1771687815
  %329 = and i32 %2, %328
  %330 = or i32 %2, %328
  %331 = xor i32 %2, %328
  %332 = mul i32 %330, 2
  %333 = sub i32 %332, %331
  %334 = sub i32 %333, %2
  %335 = sub i32 %334, %328
  %336 = mul i32 %335, 114
  %337 = icmp sgt i32 %336, 0
  br i1 %337, label %657, label %464

338:                                              ; preds = %18
  %339 = load i32, ptr %17, align 4
  %340 = sext i32 %339 to i64
  %341 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %340
  %342 = getelementptr inbounds nuw %struct.Product, ptr %341, i32 0, i32 5
  %343 = load i32, ptr %342, align 4
  store i32 %343, ptr %14, align 4
  %344 = load i32, ptr %17, align 4
  %345 = sext i32 %344 to i64
  %346 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %345
  %347 = getelementptr inbounds nuw %struct.Product, ptr %346, i32 0, i32 0
  %348 = load i32, ptr %347, align 16
  store i32 %348, ptr %13, align 4
  store i32 -1278483733, ptr %3, align 4
  %349 = xor i32 %2, -775778753
  %350 = and i32 %2, %349
  %351 = or i32 %2, %349
  %352 = xor i32 %2, %349
  %353 = add i32 %2, %349
  %354 = sub i32 %353, %352
  %355 = mul i32 %350, 2
  %356 = sub i32 %354, %355
  %357 = mul i32 %356, 156
  %358 = icmp uge i32 %357, 0
  br i1 %358, label %464, label %665

359:                                              ; preds = %18
  store i32 -372675667, ptr %3, align 4
  %360 = xor i32 %2, -756151505
  %361 = and i32 %2, %360
  %362 = or i32 %2, %360
  %363 = xor i32 %2, %360
  %364 = add i32 %2, %360
  %365 = sub i32 %364, %363
  %366 = mul i32 %361, 2
  %367 = sub i32 %365, %366
  %368 = mul i32 %367, 23
  %369 = icmp ne i32 %368, 0
  br i1 %369, label %667, label %464

370:                                              ; preds = %18
  %371 = load i32, ptr %17, align 4
  %372 = load i32, ptr %3, align 4
  %373 = xor i32 %372, -372675668
  %374 = xor i32 %371, %373
  %375 = load i32, ptr %3, align 4
  %376 = xor i32 %375, -372675668
  %377 = and i32 %371, %376
  %378 = add i32 %377, %377
  %379 = add i32 %374, %378
  store i32 %379, ptr %17, align 4
  store i32 -981952042, ptr %3, align 4
  %380 = xor i32 %2, 2080515985
  %381 = and i32 %2, %380
  %382 = or i32 %2, %380
  %383 = xor i32 %2, %380
  %384 = sub i32 %382, %383
  %385 = sub i32 %384, %381
  %386 = mul i32 %385, 225
  %387 = icmp eq i32 %386, 0
  br i1 %387, label %464, label %669

388:                                              ; preds = %18
  %389 = call i32 (ptr, ...) @printf(ptr noundef @.str.87)
  %390 = load i32, ptr %4, align 4
  %391 = call i32 (ptr, ...) @printf(ptr noundef @.str.88, i32 noundef %390)
  %392 = load i32, ptr %5, align 4
  %393 = call i32 (ptr, ...) @printf(ptr noundef @.str.89, i32 noundef %392)
  %394 = load i32, ptr %6, align 4
  %395 = call i32 (ptr, ...) @printf(ptr noundef @.str.90, i32 noundef %394)
  %396 = call i32 (ptr, ...) @printf(ptr noundef @.str.91)
  %397 = load i64, ptr %7, align 8
  call void @printMoney(i64 noundef %397)
  %398 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %399 = call i32 (ptr, ...) @printf(ptr noundef @.str.63)
  %400 = load i64, ptr %8, align 8
  call void @printMoney(i64 noundef %400)
  %401 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %402 = call i32 (ptr, ...) @printf(ptr noundef @.str.64)
  %403 = load i64, ptr %9, align 8
  call void @printMoney(i64 noundef %403)
  %404 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %405 = call i32 (ptr, ...) @printf(ptr noundef @.str.65)
  %406 = load i64, ptr %10, align 8
  call void @printMoney(i64 noundef %406)
  %407 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %408 = call i32 (ptr, ...) @printf(ptr noundef @.str.92)
  %409 = load i64, ptr %11, align 8
  call void @printMoney(i64 noundef %409)
  %410 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %411 = call i32 (ptr, ...) @printf(ptr noundef @.str.93)
  %412 = load i64, ptr %12, align 8
  call void @printMoney(i64 noundef %412)
  %413 = call i32 (ptr, ...) @printf(ptr noundef @.str.27)
  %414 = load i32, ptr %13, align 4
  %415 = icmp eq i32 %414, -1
  %416 = select i1 %415, i32 -1216121497, i32 251890251
  store i32 %416, ptr %3, align 4
  %417 = xor i32 %2, -1685086939
  %418 = and i32 %2, %417
  %419 = or i32 %2, %417
  %420 = xor i32 %2, %417
  %421 = mul i32 %419, 2
  %422 = sub i32 %421, %420
  %423 = sub i32 %422, %2
  %424 = sub i32 %423, %417
  %425 = mul i32 %424, 75
  %426 = icmp sle i32 %425, 0
  br i1 %426, label %464, label %675

427:                                              ; preds = %18
  %428 = load i32, ptr %14, align 4
  %429 = icmp sle i32 %428, 0
  %430 = select i1 %429, i32 -1216121497, i32 871240868
  store i32 %430, ptr %3, align 4
  %431 = xor i32 %2, -1384927183
  %432 = and i32 %2, %431
  %433 = or i32 %2, %431
  %434 = xor i32 %2, %431
  %435 = sub i32 %433, %434
  %436 = sub i32 %435, %432
  %437 = mul i32 %436, 176
  %438 = icmp slt i32 %437, 0
  br i1 %438, label %679, label %464

439:                                              ; preds = %18
  %440 = call i32 (ptr, ...) @printf(ptr noundef @.str.94)
  store i32 1723350065, ptr %3, align 4
  %441 = xor i32 %2, -979378375
  %442 = and i32 %2, %441
  %443 = or i32 %2, %441
  %444 = xor i32 %2, %441
  %445 = add i32 %442, %443
  %446 = sub i32 %445, %2
  %447 = sub i32 %446, %441
  %448 = mul i32 %447, 200
  %449 = icmp eq i32 %448, 0
  br i1 %449, label %464, label %682

450:                                              ; preds = %18
  %451 = load i32, ptr %13, align 4
  %452 = load i32, ptr %14, align 4
  %453 = call i32 (ptr, ...) @printf(ptr noundef @.str.95, i32 noundef %451, i32 noundef %452)
  store i32 1723350065, ptr %3, align 4
  %454 = xor i32 %2, -267358109
  %455 = and i32 %2, %454
  %456 = or i32 %2, %454
  %457 = xor i32 %2, %454
  %458 = add i32 %455, %456
  %459 = sub i32 %458, %2
  %460 = sub i32 %459, %454
  %461 = mul i32 %460, 61
  %462 = icmp sle i32 %461, 0
  br i1 %462, label %464, label %687

463:                                              ; preds = %18
  ret void

464:                                              ; preds = %740, %733, %731, %723, %718, %710, %708, %703, %687, %682, %679, %675, %669, %667, %665, %657, %653, %648, %641, %633, %625, %617, %612, %609, %601, %596, %594, %589, %578, %565, %554, %535, %522, %500, %487, %474, %450, %439, %427, %388, %370, %359, %338, %302, %278, %264, %245, %225, %215, %183, %165, %90, %72, %47, %33, %22
  br label %18

465:                                              ; preds = %18
  store i32 -1443923634, ptr %3, align 4
  call void asm sideeffect "", ""()
  %466 = xor i32 %2, 2101192125
  %467 = and i32 %2, %466
  %468 = or i32 %2, %466
  %469 = xor i32 %2, %466
  %470 = sub i32 %468, %469
  %471 = sub i32 %470, %467
  %472 = mul i32 %471, 99
  %473 = icmp ne i32 %472, 0
  br i1 %473, label %695, label %18

474:                                              ; preds = %18
  %475 = load i32, ptr %3, align 4
  %476 = xor i32 %475, -182720593
  store i32 %476, ptr %3, align 4
  %477 = xor i32 %2, 1783801107
  %478 = and i32 %2, %477
  %479 = or i32 %2, %477
  %480 = xor i32 %2, %477
  %481 = mul i32 %479, 2
  %482 = sub i32 %481, %480
  %483 = sub i32 %482, %2
  %484 = sub i32 %483, %477
  %485 = mul i32 %484, 132
  %486 = icmp sle i32 %485, 0
  br i1 %486, label %464, label %703

487:                                              ; preds = %18
  %488 = load i32, ptr %3, align 4
  %489 = xor i32 %488, 1419997743
  store i32 %489, ptr %3, align 4
  %490 = xor i32 %2, 274438771
  %491 = and i32 %2, %490
  %492 = or i32 %2, %490
  %493 = xor i32 %2, %490
  %494 = add i32 %2, %490
  %495 = sub i32 %494, %493
  %496 = mul i32 %491, 2
  %497 = sub i32 %495, %496
  %498 = mul i32 %497, 28
  %499 = icmp eq i32 %498, 0
  br i1 %499, label %464, label %708

500:                                              ; preds = %18
  %501 = load i32, ptr %3, align 4
  %502 = xor i32 %501, -1822857311
  store i32 %502, ptr %3, align 4
  %503 = xor i32 %2, -850101121
  %504 = and i32 %2, %503
  %505 = or i32 %2, %503
  %506 = xor i32 %2, %503
  %507 = mul i32 %505, 2
  %508 = sub i32 %507, %506
  %509 = sub i32 %508, %2
  %510 = sub i32 %509, %503
  %511 = mul i32 %510, 79
  %512 = xor i32 %2, 1318598363
  %513 = and i32 %2, %512
  %514 = or i32 %2, %512
  %515 = xor i32 %2, %512
  %516 = mul i32 %514, 2
  %517 = sub i32 %516, %515
  %518 = sub i32 %517, %2
  %519 = sub i32 %518, %512
  %520 = mul i32 %519, 15
  %521 = icmp eq i32 %511, %520
  br i1 %521, label %464, label %710

522:                                              ; preds = %18
  %523 = load i32, ptr %3, align 4
  %524 = xor i32 %523, -480986651
  store i32 %524, ptr %3, align 4
  %525 = xor i32 %2, -452919929
  %526 = and i32 %2, %525
  %527 = or i32 %2, %525
  %528 = xor i32 %2, %525
  %529 = add i32 %2, %525
  %530 = sub i32 %529, %528
  %531 = mul i32 %526, 2
  %532 = sub i32 %530, %531
  %533 = mul i32 %532, 231
  %534 = icmp sle i32 %533, 0
  br i1 %534, label %464, label %718

535:                                              ; preds = %18
  %536 = load i32, ptr %3, align 4
  %537 = xor i32 %536, -521207020
  store i32 %537, ptr %3, align 4
  %538 = xor i32 %2, -1654313977
  %539 = and i32 %2, %538
  %540 = or i32 %2, %538
  %541 = xor i32 %2, %538
  %542 = add i32 %539, %540
  %543 = sub i32 %542, %2
  %544 = sub i32 %543, %538
  %545 = mul i32 %544, 2
  %546 = xor i32 %2, -258724071
  %547 = and i32 %2, %546
  %548 = or i32 %2, %546
  %549 = xor i32 %2, %546
  %550 = sub i32 %548, %549
  %551 = sub i32 %550, %547
  %552 = mul i32 %551, 28
  %553 = icmp ne i32 %545, %552
  br i1 %553, label %723, label %464

554:                                              ; preds = %18
  %555 = load i32, ptr %3, align 4
  %556 = xor i32 %555, -542799479
  store i32 %556, ptr %3, align 4
  %557 = xor i32 %2, 789471837
  %558 = and i32 %2, %557
  %559 = or i32 %2, %557
  %560 = xor i32 %2, %557
  %561 = sub i32 %559, %560
  %562 = sub i32 %561, %558
  %563 = mul i32 %562, 136
  %564 = icmp uge i32 %563, 0
  br i1 %564, label %464, label %731

565:                                              ; preds = %18
  %566 = load i32, ptr %3, align 4
  %567 = xor i32 %566, -1311957621
  store i32 %567, ptr %3, align 4
  %568 = xor i32 %2, 1374699937
  %569 = and i32 %2, %568
  %570 = or i32 %2, %568
  %571 = xor i32 %2, %568
  %572 = mul i32 %570, 2
  %573 = sub i32 %572, %571
  %574 = sub i32 %573, %2
  %575 = sub i32 %574, %568
  %576 = mul i32 %575, 251
  %577 = icmp uge i32 %576, 0
  br i1 %577, label %464, label %733

578:                                              ; preds = %18
  %579 = load i32, ptr %3, align 4
  %580 = xor i32 %579, 1830325895
  store i32 %580, ptr %3, align 4
  %581 = xor i32 %2, 1140598489
  %582 = and i32 %2, %581
  %583 = or i32 %2, %581
  %584 = xor i32 %2, %581
  %585 = sub i32 %583, %584
  %586 = sub i32 %585, %582
  %587 = mul i32 %586, 91
  %588 = icmp slt i32 %587, 1
  br i1 %588, label %464, label %740

589:                                              ; preds = %22
  %590 = load i64, ptr %1, align 8
  %591 = xor i64 201851403, %590
  %592 = mul i64 %591, %590
  %593 = and i64 %592, 1067059083
  store i64 %593, ptr %1, align 8
  br label %464

594:                                              ; preds = %33
  %595 = load i64, ptr %1, align 8
  store i64 1418816793536479313, ptr %1, align 8
  br label %464

596:                                              ; preds = %47
  %597 = load i64, ptr %1, align 8
  %598 = and i64 1319520144, %597
  %599 = mul i64 %598, 1319520144
  %600 = mul i64 %599, 1319520144
  store i64 %600, ptr %1, align 8
  br label %464

601:                                              ; preds = %72
  %602 = load i64, ptr %1, align 8
  %603 = and i64 %602, 456062344
  %604 = or i64 %603, 2548789517
  %605 = mul i64 %604, 456062344
  %606 = and i64 %605, 2548789517
  %607 = mul i64 %606, 2548789517
  %608 = xor i64 %607, 2548789517
  store i64 %608, ptr %1, align 8
  br label %464

609:                                              ; preds = %90
  %610 = load i64, ptr %1, align 8
  %611 = sub i64 3495148276397297078, %610
  store i64 %611, ptr %1, align 8
  br label %464

612:                                              ; preds = %165
  %613 = load i64, ptr %1, align 8
  %614 = sub i64 %613, 498209019
  %615 = xor i64 %614, 1927410043
  %616 = and i64 %615, %613
  store i64 %616, ptr %1, align 8
  br label %464

617:                                              ; preds = %183
  %618 = load i64, ptr %1, align 8
  %619 = xor i64 %618, 3834848577
  %620 = sub i64 %619, %618
  %621 = or i64 %620, 3834848577
  %622 = or i64 %621, 3834848577
  %623 = mul i64 %622, 3834848577
  %624 = or i64 %623, 3556557012
  store i64 %624, ptr %1, align 8
  br label %464

625:                                              ; preds = %215
  %626 = load i64, ptr %1, align 8
  %627 = add i64 %626, %626
  %628 = xor i64 %627, %626
  %629 = or i64 %628, 781592560
  %630 = sub i64 %629, 781592560
  %631 = xor i64 %630, 1379001267
  %632 = and i64 %631, %626
  store i64 %632, ptr %1, align 8
  br label %464

633:                                              ; preds = %225
  %634 = load i64, ptr %1, align 8
  %635 = add i64 %634, 3937919581
  %636 = and i64 %635, 1099111519
  %637 = add i64 %636, 1099111519
  %638 = add i64 %637, %634
  %639 = or i64 %638, %634
  %640 = or i64 %639, 3937919581
  store i64 %640, ptr %1, align 8
  br label %464

641:                                              ; preds = %245
  %642 = load i64, ptr %1, align 8
  %643 = mul i64 0, %642
  %644 = and i64 %643, 31759567
  %645 = sub i64 %644, %642
  %646 = add i64 %645, 31759567
  %647 = or i64 %646, 31759567
  store i64 %647, ptr %1, align 8
  br label %464

648:                                              ; preds = %264
  %649 = load i64, ptr %1, align 8
  %650 = or i64 0, %649
  %651 = xor i64 %650, 1623488683
  %652 = xor i64 %651, %649
  store i64 %652, ptr %1, align 8
  br label %464

653:                                              ; preds = %278
  %654 = load i64, ptr %1, align 8
  %655 = and i64 1376636820557805625, %654
  %656 = and i64 %655, %654
  store i64 %656, ptr %1, align 8
  br label %464

657:                                              ; preds = %302
  %658 = load i64, ptr %1, align 8
  %659 = sub i64 %658, %658
  %660 = and i64 %659, 225578100
  %661 = add i64 %660, 655010222
  %662 = sub i64 %661, %658
  %663 = or i64 %662, 655010222
  %664 = add i64 %663, 225578100
  store i64 %664, ptr %1, align 8
  br label %464

665:                                              ; preds = %338
  %666 = load i64, ptr %1, align 8
  store i64 3059720527, ptr %1, align 8
  br label %464

667:                                              ; preds = %359
  %668 = load i64, ptr %1, align 8
  store i64 2309243697, ptr %1, align 8
  br label %464

669:                                              ; preds = %370
  %670 = load i64, ptr %1, align 8
  %671 = xor i64 265744137, %670
  %672 = or i64 %671, 265744137
  %673 = mul i64 %672, %670
  %674 = sub i64 %673, 2253182277
  store i64 %674, ptr %1, align 8
  br label %464

675:                                              ; preds = %388
  %676 = load i64, ptr %1, align 8
  %677 = add i64 -130141091, %676
  %678 = sub i64 %677, 2420259314
  store i64 %678, ptr %1, align 8
  br label %464

679:                                              ; preds = %427
  %680 = load i64, ptr %1, align 8
  %681 = mul i64 1068463231, %680
  store i64 %681, ptr %1, align 8
  br label %464

682:                                              ; preds = %439
  %683 = load i64, ptr %1, align 8
  %684 = mul i64 4784607457037764587, %683
  %685 = add i64 %684, %683
  %686 = add i64 %685, 3507897492
  store i64 %686, ptr %1, align 8
  br label %464

687:                                              ; preds = %450
  %688 = load i64, ptr %1, align 8
  %689 = xor i64 %688, %688
  %690 = or i64 %689, 3500676456
  %691 = sub i64 %690, 3500676456
  %692 = add i64 %691, 4153648414
  %693 = mul i64 %692, 3500676456
  %694 = xor i64 %693, 3500676456
  store i64 %694, ptr %1, align 8
  br label %464

695:                                              ; preds = %465
  %696 = load i64, ptr %1, align 8
  %697 = add i64 %696, 670956027
  %698 = or i64 %697, 1865358167
  %699 = mul i64 %698, 670956027
  %700 = or i64 %699, 1865358167
  %701 = sub i64 %700, 670956027
  %702 = xor i64 %701, 1865358167
  store i64 %702, ptr %1, align 8
  br label %18

703:                                              ; preds = %474
  %704 = load i64, ptr %1, align 8
  %705 = and i64 1859049643897414936, %704
  %706 = or i64 %705, 2689527544
  %707 = and i64 %706, %704
  store i64 %707, ptr %1, align 8
  br label %464

708:                                              ; preds = %487
  %709 = load i64, ptr %1, align 8
  store i64 3477769850940552047, ptr %1, align 8
  br label %464

710:                                              ; preds = %500
  %711 = load i64, ptr %1, align 8
  %712 = and i64 %711, 38246034
  %713 = sub i64 %712, 38246034
  %714 = or i64 %713, 38246034
  %715 = sub i64 %714, %711
  %716 = or i64 %715, %711
  %717 = and i64 %716, 38246034
  store i64 %717, ptr %1, align 8
  br label %464

718:                                              ; preds = %522
  %719 = load i64, ptr %1, align 8
  %720 = add i64 4002316367, %719
  %721 = or i64 %720, 4002316367
  %722 = add i64 %721, 4002316367
  store i64 %722, ptr %1, align 8
  br label %464

723:                                              ; preds = %535
  %724 = load i64, ptr %1, align 8
  %725 = mul i64 %724, %724
  %726 = or i64 %725, 1013744366
  %727 = xor i64 %726, %724
  %728 = mul i64 %727, %724
  %729 = add i64 %728, %724
  %730 = and i64 %729, 3915312139
  store i64 %730, ptr %1, align 8
  br label %464

731:                                              ; preds = %554
  %732 = load i64, ptr %1, align 8
  store i64 2534161049, ptr %1, align 8
  br label %464

733:                                              ; preds = %565
  %734 = load i64, ptr %1, align 8
  %735 = sub i64 %734, %734
  %736 = and i64 %735, 2692507111
  %737 = and i64 %736, 280397852
  %738 = xor i64 %737, 280397852
  %739 = mul i64 %738, 280397852
  store i64 %739, ptr %1, align 8
  br label %464

740:                                              ; preds = %578
  %741 = load i64, ptr %1, align 8
  store i64 9168903349101996145, ptr %1, align 8
  br label %464
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @cmdSave(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 -66943471, ptr %4, align 4
  br label %11

11:                                               ; preds = %645, %397, %396, %2
  %12 = load i32, ptr %4, align 4
  %13 = sub i32 %12, -198670312
  %14 = mul i32 %13, -2066587617
  switch i32 %14, label %397 [
    i32 1826955559, label %15
    i32 1183283223, label %29
    i32 915893628, label %48
    i32 864733435, label %66
    i32 1021367846, label %79
    i32 999312456, label %92
    i32 1434658205, label %107
    i32 2048072569, label %173
    i32 374645351, label %187
    i32 494850239, label %200
    i32 785066549, label %263
    i32 791275447, label %281
    i32 732882804, label %358
    i32 1960742385, label %378
    i32 1178623688, label %395
    i32 1501010717, label %408
    i32 1921353610, label %421
    i32 1526705418, label %434
    i32 1711412132, label %455
    i32 1521639961, label %467
    i32 2099867695, label %480
    i32 1352721800, label %493
    i32 1895039142, label %506
  ]

15:                                               ; preds = %11
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %16 = load i32, ptr %6, align 4
  %17 = icmp ne i32 %16, 2
  %18 = select i1 %17, i32 575115553, i32 -1912014052
  store i32 %18, ptr %4, align 4
  %19 = xor i32 %1, 265775321
  %20 = and i32 %1, %19
  %21 = or i32 %1, %19
  %22 = xor i32 %1, %19
  %23 = mul i32 %21, 2
  %24 = sub i32 %23, %22
  %25 = sub i32 %24, %1
  %26 = sub i32 %25, %19
  %27 = mul i32 %26, 72
  %28 = icmp sgt i32 %27, 0
  br i1 %28, label %527, label %396

29:                                               ; preds = %11
  %30 = call i32 (ptr, ...) @printf(ptr noundef @.str.96)
  store i32 -366858160, ptr %4, align 4
  %31 = xor i32 %1, -1022783247
  %32 = and i32 %1, %31
  %33 = or i32 %1, %31
  %34 = xor i32 %1, %31
  %35 = add i32 %1, %31
  %36 = sub i32 %35, %34
  %37 = mul i32 %32, 2
  %38 = sub i32 %36, %37
  %39 = mul i32 %38, 230
  %40 = xor i32 %1, -1398649227
  %41 = and i32 %1, %40
  %42 = or i32 %1, %40
  %43 = xor i32 %1, %40
  %44 = sub i32 %42, %43
  %45 = sub i32 %44, %41
  %46 = mul i32 %45, 64
  %47 = icmp ne i32 %39, %46
  br i1 %47, label %535, label %396

48:                                               ; preds = %11
  %49 = load ptr, ptr %5, align 8
  %50 = getelementptr inbounds ptr, ptr %49, i64 1
  %51 = load ptr, ptr %50, align 8
  %52 = call noalias ptr @fopen(ptr noundef %51, ptr noundef @.str.97)
  store ptr %52, ptr %7, align 8
  %53 = load ptr, ptr %7, align 8
  %54 = icmp ne ptr %53, null
  %55 = select i1 %54, i32 -111733454, i32 371659709
  store i32 %55, ptr %4, align 4
  %56 = xor i32 %1, 194670357
  %57 = and i32 %1, %56
  %58 = or i32 %1, %56
  %59 = xor i32 %1, %56
  %60 = mul i32 %58, 2
  %61 = sub i32 %60, %59
  %62 = sub i32 %61, %1
  %63 = sub i32 %62, %56
  %64 = mul i32 %63, 178
  %65 = icmp uge i32 %64, 0
  br i1 %65, label %396, label %545

66:                                               ; preds = %11
  %67 = load ptr, ptr %5, align 8
  %68 = getelementptr inbounds ptr, ptr %67, i64 1
  %69 = load ptr, ptr %68, align 8
  %70 = call i32 (ptr, ...) @printf(ptr noundef @.str.98, ptr noundef %69)
  store i32 -366858160, ptr %4, align 4
  %71 = xor i32 %1, -217059335
  %72 = and i32 %1, %71
  %73 = or i32 %1, %71
  %74 = xor i32 %1, %71
  %75 = sub i32 %73, %74
  %76 = sub i32 %75, %72
  %77 = mul i32 %76, 13
  %78 = icmp sle i32 %77, 0
  br i1 %78, label %396, label %552

79:                                               ; preds = %11
  %80 = load ptr, ptr %7, align 8
  %81 = load i32, ptr @productCount, align 4
  %82 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %80, ptr noundef @.str.99, i32 noundef %81) #9
  store i32 0, ptr %8, align 4
  store i32 -1404136752, ptr %4, align 4
  %83 = xor i32 %1, 1742343213
  %84 = and i32 %1, %83
  %85 = or i32 %1, %83
  %86 = xor i32 %1, %83
  %87 = add i32 %84, %85
  %88 = sub i32 %87, %1
  %89 = sub i32 %88, %83
  %90 = mul i32 %89, 220
  %91 = icmp uge i32 %90, 0
  br i1 %91, label %396, label %559

92:                                               ; preds = %11
  %93 = load i32, ptr %8, align 4
  %94 = load i32, ptr @productCount, align 4
  %95 = icmp slt i32 %93, %94
  %96 = select i1 %95, i32 -1234248997, i32 -66045569
  store i32 %96, ptr %4, align 4
  %97 = xor i32 %1, 1454505957
  %98 = and i32 %1, %97
  %99 = or i32 %1, %97
  %100 = xor i32 %1, %97
  %101 = add i32 %1, %97
  %102 = sub i32 %101, %100
  %103 = mul i32 %98, 2
  %104 = sub i32 %102, %103
  %105 = mul i32 %104, 216
  %106 = icmp sle i32 %105, 0
  br i1 %106, label %396, label %568

107:                                              ; preds = %11
  %108 = load ptr, ptr %7, align 8
  %109 = load i32, ptr %8, align 4
  %110 = sext i32 %109 to i64
  %111 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %110
  %112 = getelementptr inbounds nuw %struct.Product, ptr %111, i32 0, i32 0
  %113 = load i32, ptr %112, align 16
  %114 = load i32, ptr %8, align 4
  %115 = sext i32 %114 to i64
  %116 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %115
  %117 = getelementptr inbounds nuw %struct.Product, ptr %116, i32 0, i32 1
  %118 = getelementptr inbounds [80 x i8], ptr %117, i64 0, i64 0
  %119 = load i32, ptr %8, align 4
  %120 = sext i32 %119 to i64
  %121 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %120
  %122 = getelementptr inbounds nuw %struct.Product, ptr %121, i32 0, i32 2
  %123 = getelementptr inbounds [50 x i8], ptr %122, i64 0, i64 0
  %124 = load i32, ptr %8, align 4
  %125 = sext i32 %124 to i64
  %126 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %125
  %127 = getelementptr inbounds nuw %struct.Product, ptr %126, i32 0, i32 3
  %128 = load i64, ptr %127, align 8
  %129 = load i32, ptr %8, align 4
  %130 = sext i32 %129 to i64
  %131 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %130
  %132 = getelementptr inbounds nuw %struct.Product, ptr %131, i32 0, i32 4
  %133 = load i32, ptr %132, align 16
  %134 = load i32, ptr %8, align 4
  %135 = sext i32 %134 to i64
  %136 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %135
  %137 = getelementptr inbounds nuw %struct.Product, ptr %136, i32 0, i32 5
  %138 = load i32, ptr %137, align 4
  %139 = load i32, ptr %8, align 4
  %140 = sext i32 %139 to i64
  %141 = getelementptr inbounds [1000 x %struct.Product], ptr @products, i64 0, i64 %140
  %142 = getelementptr inbounds nuw %struct.Product, ptr %141, i32 0, i32 6
  %143 = load i32, ptr %142, align 8
  %144 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %108, ptr noundef @.str.100, i32 noundef %113, ptr noundef %118, ptr noundef %123, i64 noundef %128, i32 noundef %133, i32 noundef %138, i32 noundef %143) #9
  %145 = load i32, ptr %8, align 4
  %146 = load i32, ptr %4, align 4
  %147 = xor i32 %146, -1234248998
  %148 = sub i32 %145, %147
  %149 = load i32, ptr %4, align 4
  %150 = xor i32 %149, -1234248999
  %151 = mul i32 %145, %150
  %152 = load i32, ptr %4, align 4
  %153 = xor i32 %152, -1234248998
  %154 = mul i32 %153, %148
  %155 = sub i32 %151, %154
  store i32 %155, ptr %8, align 4
  store i32 -1404136752, ptr %4, align 4
  %156 = xor i32 %1, -2089856117
  %157 = and i32 %1, %156
  %158 = or i32 %1, %156
  %159 = xor i32 %1, %156
  %160 = add i32 %157, %158
  %161 = sub i32 %160, %1
  %162 = sub i32 %161, %156
  %163 = mul i32 %162, 161
  %164 = xor i32 %1, 9090667
  %165 = and i32 %1, %164
  %166 = or i32 %1, %164
  %167 = xor i32 %1, %164
  %168 = add i32 %165, %166
  %169 = sub i32 %168, %1
  %170 = sub i32 %169, %164
  %171 = mul i32 %170, 146
  %172 = icmp eq i32 %163, %171
  br i1 %172, label %396, label %575

173:                                              ; preds = %11
  %174 = load ptr, ptr %7, align 8
  %175 = load i32, ptr @orderCount, align 4
  %176 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %174, ptr noundef @.str.101, i32 noundef %175) #9
  store i32 0, ptr %9, align 4
  store i32 -586818351, ptr %4, align 4
  %177 = xor i32 %1, 646968043
  %178 = and i32 %1, %177
  %179 = or i32 %1, %177
  %180 = xor i32 %1, %177
  %181 = mul i32 %179, 2
  %182 = sub i32 %181, %180
  %183 = sub i32 %182, %1
  %184 = sub i32 %183, %177
  %185 = mul i32 %184, 22
  %186 = icmp uge i32 %185, 0
  br i1 %186, label %396, label %585

187:                                              ; preds = %11
  %188 = load i32, ptr %9, align 4
  %189 = load i32, ptr @orderCount, align 4
  %190 = icmp slt i32 %188, %189
  %191 = select i1 %190, i32 -715160711, i32 78878727
  store i32 %191, ptr %4, align 4
  %192 = xor i32 %1, -28224631
  %193 = and i32 %1, %192
  %194 = or i32 %1, %192
  %195 = xor i32 %1, %192
  %196 = sub i32 %194, %195
  %197 = sub i32 %196, %193
  %198 = mul i32 %197, 199
  %199 = icmp eq i32 %198, 0
  br i1 %199, label %396, label %594

200:                                              ; preds = %11
  %201 = load ptr, ptr %7, align 8
  %202 = load i32, ptr %9, align 4
  %203 = sext i32 %202 to i64
  %204 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %203
  %205 = getelementptr inbounds nuw %struct.Order, ptr %204, i32 0, i32 0
  %206 = load i32, ptr %205, align 16
  %207 = load i32, ptr %9, align 4
  %208 = sext i32 %207 to i64
  %209 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %208
  %210 = getelementptr inbounds nuw %struct.Order, ptr %209, i32 0, i32 1
  %211 = getelementptr inbounds [80 x i8], ptr %210, i64 0, i64 0
  %212 = load i32, ptr %9, align 4
  %213 = sext i32 %212 to i64
  %214 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %213
  %215 = getelementptr inbounds nuw %struct.Order, ptr %214, i32 0, i32 2
  %216 = getelementptr inbounds [30 x i8], ptr %215, i64 0, i64 0
  %217 = load i32, ptr %9, align 4
  %218 = sext i32 %217 to i64
  %219 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %218
  %220 = getelementptr inbounds nuw %struct.Order, ptr %219, i32 0, i32 4
  %221 = load i32, ptr %220, align 8
  %222 = load i32, ptr %9, align 4
  %223 = sext i32 %222 to i64
  %224 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %223
  %225 = getelementptr inbounds nuw %struct.Order, ptr %224, i32 0, i32 5
  %226 = load i64, ptr %225, align 16
  %227 = load i32, ptr %9, align 4
  %228 = sext i32 %227 to i64
  %229 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %228
  %230 = getelementptr inbounds nuw %struct.Order, ptr %229, i32 0, i32 6
  %231 = load i64, ptr %230, align 8
  %232 = load i32, ptr %9, align 4
  %233 = sext i32 %232 to i64
  %234 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %233
  %235 = getelementptr inbounds nuw %struct.Order, ptr %234, i32 0, i32 7
  %236 = load i64, ptr %235, align 16
  %237 = load i32, ptr %9, align 4
  %238 = sext i32 %237 to i64
  %239 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %238
  %240 = getelementptr inbounds nuw %struct.Order, ptr %239, i32 0, i32 8
  %241 = load i64, ptr %240, align 8
  %242 = load i32, ptr %9, align 4
  %243 = sext i32 %242 to i64
  %244 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %243
  %245 = getelementptr inbounds nuw %struct.Order, ptr %244, i32 0, i32 9
  %246 = load i64, ptr %245, align 16
  %247 = load i32, ptr %9, align 4
  %248 = sext i32 %247 to i64
  %249 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %248
  %250 = getelementptr inbounds nuw %struct.Order, ptr %249, i32 0, i32 10
  %251 = load i32, ptr %250, align 8
  %252 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %201, ptr noundef @.str.102, i32 noundef %206, ptr noundef %211, ptr noundef %216, i32 noundef %221, i64 noundef %226, i64 noundef %231, i64 noundef %236, i64 noundef %241, i64 noundef %246, i32 noundef %251) #9
  store i32 0, ptr %10, align 4
  store i32 194962243, ptr %4, align 4
  %253 = xor i32 %1, -955794149
  %254 = and i32 %1, %253
  %255 = or i32 %1, %253
  %256 = xor i32 %1, %253
  %257 = mul i32 %255, 2
  %258 = sub i32 %257, %256
  %259 = sub i32 %258, %1
  %260 = sub i32 %259, %253
  %261 = mul i32 %260, 98
  %262 = icmp uge i32 %261, 0
  br i1 %262, label %396, label %603

263:                                              ; preds = %11
  %264 = load i32, ptr %10, align 4
  %265 = load i32, ptr %9, align 4
  %266 = sext i32 %265 to i64
  %267 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %266
  %268 = getelementptr inbounds nuw %struct.Order, ptr %267, i32 0, i32 4
  %269 = load i32, ptr %268, align 8
  %270 = icmp slt i32 %264, %269
  %271 = select i1 %270, i32 -1750291071, i32 -919510492
  store i32 %271, ptr %4, align 4
  %272 = xor i32 %1, 1400027173
  %273 = and i32 %1, %272
  %274 = or i32 %1, %272
  %275 = xor i32 %1, %272
  %276 = add i32 %273, %274
  %277 = sub i32 %276, %1
  %278 = sub i32 %277, %272
  %279 = mul i32 %278, 70
  %280 = icmp ugt i32 %279, 0
  br i1 %280, label %611, label %396

281:                                              ; preds = %11
  %282 = load ptr, ptr %7, align 8
  %283 = load i32, ptr %9, align 4
  %284 = sext i32 %283 to i64
  %285 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %284
  %286 = getelementptr inbounds nuw %struct.Order, ptr %285, i32 0, i32 3
  %287 = load i32, ptr %10, align 4
  %288 = sext i32 %287 to i64
  %289 = getelementptr inbounds [64 x %struct.OrderItem], ptr %286, i64 0, i64 %288
  %290 = getelementptr inbounds nuw %struct.OrderItem, ptr %289, i32 0, i32 0
  %291 = load i32, ptr %290, align 8
  %292 = load i32, ptr %9, align 4
  %293 = sext i32 %292 to i64
  %294 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %293
  %295 = getelementptr inbounds nuw %struct.Order, ptr %294, i32 0, i32 3
  %296 = load i32, ptr %10, align 4
  %297 = sext i32 %296 to i64
  %298 = getelementptr inbounds [64 x %struct.OrderItem], ptr %295, i64 0, i64 %297
  %299 = getelementptr inbounds nuw %struct.OrderItem, ptr %298, i32 0, i32 1
  %300 = getelementptr inbounds [80 x i8], ptr %299, i64 0, i64 0
  %301 = load i32, ptr %9, align 4
  %302 = sext i32 %301 to i64
  %303 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %302
  %304 = getelementptr inbounds nuw %struct.Order, ptr %303, i32 0, i32 3
  %305 = load i32, ptr %10, align 4
  %306 = sext i32 %305 to i64
  %307 = getelementptr inbounds [64 x %struct.OrderItem], ptr %304, i64 0, i64 %306
  %308 = getelementptr inbounds nuw %struct.OrderItem, ptr %307, i32 0, i32 2
  %309 = load i32, ptr %308, align 4
  %310 = load i32, ptr %9, align 4
  %311 = sext i32 %310 to i64
  %312 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %311
  %313 = getelementptr inbounds nuw %struct.Order, ptr %312, i32 0, i32 3
  %314 = load i32, ptr %10, align 4
  %315 = sext i32 %314 to i64
  %316 = getelementptr inbounds [64 x %struct.OrderItem], ptr %313, i64 0, i64 %315
  %317 = getelementptr inbounds nuw %struct.OrderItem, ptr %316, i32 0, i32 3
  %318 = load i64, ptr %317, align 8
  %319 = load i32, ptr %9, align 4
  %320 = sext i32 %319 to i64
  %321 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %320
  %322 = getelementptr inbounds nuw %struct.Order, ptr %321, i32 0, i32 3
  %323 = load i32, ptr %10, align 4
  %324 = sext i32 %323 to i64
  %325 = getelementptr inbounds [64 x %struct.OrderItem], ptr %322, i64 0, i64 %324
  %326 = getelementptr inbounds nuw %struct.OrderItem, ptr %325, i32 0, i32 4
  %327 = load i64, ptr %326, align 8
  %328 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %282, ptr noundef @.str.103, i32 noundef %291, ptr noundef %300, i32 noundef %309, i64 noundef %318, i64 noundef %327) #9
  %329 = load i32, ptr %10, align 4
  %330 = load i32, ptr %4, align 4
  %331 = xor i32 %330, -1750291072
  %332 = sub i32 %329, %331
  %333 = load i32, ptr %4, align 4
  %334 = xor i32 %333, -1750291069
  %335 = mul i32 %329, %334
  %336 = load i32, ptr %4, align 4
  %337 = xor i32 %336, -1750291072
  %338 = mul i32 %337, %332
  %339 = sub i32 %335, %338
  store i32 %339, ptr %10, align 4
  store i32 194962243, ptr %4, align 4
  %340 = xor i32 %1, 367122875
  %341 = and i32 %1, %340
  %342 = or i32 %1, %340
  %343 = xor i32 %1, %340
  %344 = add i32 %341, %342
  %345 = sub i32 %344, %1
  %346 = sub i32 %345, %340
  %347 = mul i32 %346, 111
  %348 = xor i32 %1, 1817339595
  %349 = and i32 %1, %348
  %350 = or i32 %1, %348
  %351 = xor i32 %1, %348
  %352 = add i32 %1, %348
  %353 = sub i32 %352, %351
  %354 = mul i32 %349, 2
  %355 = sub i32 %353, %354
  %356 = mul i32 %355, 229
  %357 = icmp ne i32 %347, %356
  br i1 %357, label %619, label %396

358:                                              ; preds = %11
  %359 = load i32, ptr %9, align 4
  %360 = load i32, ptr %4, align 4
  %361 = xor i32 %360, -919510491
  %362 = sub i32 %359, %361
  %363 = load i32, ptr %4, align 4
  %364 = xor i32 %363, -919510490
  %365 = mul i32 %359, %364
  %366 = load i32, ptr %4, align 4
  %367 = xor i32 %366, -919510491
  %368 = mul i32 %367, %362
  %369 = sub i32 %365, %368
  store i32 %369, ptr %9, align 4
  store i32 -586818351, ptr %4, align 4
  %370 = xor i32 %1, -2061726483
  %371 = and i32 %1, %370
  %372 = or i32 %1, %370
  %373 = xor i32 %1, %370
  %374 = sub i32 %372, %373
  %375 = sub i32 %374, %371
  %376 = mul i32 %375, 17
  %377 = icmp ugt i32 %376, 0
  br i1 %377, label %627, label %396

378:                                              ; preds = %11
  %379 = load ptr, ptr %7, align 8
  %380 = call i32 @fclose(ptr noundef %379)
  %381 = load ptr, ptr %5, align 8
  %382 = getelementptr inbounds ptr, ptr %381, i64 1
  %383 = load ptr, ptr %382, align 8
  %384 = call i32 (ptr, ...) @printf(ptr noundef @.str.104, ptr noundef %383)
  store i32 -366858160, ptr %4, align 4
  %385 = xor i32 %1, 1238252607
  %386 = and i32 %1, %385
  %387 = or i32 %1, %385
  %388 = xor i32 %1, %385
  %389 = add i32 %1, %385
  %390 = sub i32 %389, %388
  %391 = mul i32 %386, 2
  %392 = sub i32 %390, %391
  %393 = mul i32 %392, 57
  %394 = icmp uge i32 %393, 0
  br i1 %394, label %396, label %635

395:                                              ; preds = %11
  ret void

396:                                              ; preds = %709, %702, %694, %685, %678, %668, %661, %653, %635, %627, %619, %611, %603, %594, %585, %575, %568, %559, %552, %545, %535, %527, %506, %493, %480, %467, %455, %434, %421, %408, %378, %358, %281, %263, %200, %187, %173, %107, %92, %79, %66, %48, %29, %15
  br label %11

397:                                              ; preds = %11
  store i32 -66943471, ptr %4, align 4
  call void asm sideeffect "", ""()
  %398 = xor i32 %1, -2084260937
  %399 = and i32 %1, %398
  %400 = or i32 %1, %398
  %401 = xor i32 %1, %398
  %402 = mul i32 %400, 2
  %403 = sub i32 %402, %401
  %404 = sub i32 %403, %1
  %405 = sub i32 %404, %398
  %406 = mul i32 %405, 95
  %407 = icmp slt i32 %406, 1
  br i1 %407, label %11, label %645

408:                                              ; preds = %11
  %409 = load i32, ptr %4, align 4
  %410 = xor i32 %409, 1393723247
  store i32 %410, ptr %4, align 4
  %411 = xor i32 %1, -865698879
  %412 = and i32 %1, %411
  %413 = or i32 %1, %411
  %414 = xor i32 %1, %411
  %415 = add i32 %1, %411
  %416 = sub i32 %415, %414
  %417 = mul i32 %412, 2
  %418 = sub i32 %416, %417
  %419 = mul i32 %418, 157
  %420 = icmp sgt i32 %419, 0
  br i1 %420, label %653, label %396

421:                                              ; preds = %11
  %422 = load i32, ptr %4, align 4
  %423 = xor i32 %422, 854253725
  store i32 %423, ptr %4, align 4
  %424 = xor i32 %1, 1007375991
  %425 = and i32 %1, %424
  %426 = or i32 %1, %424
  %427 = xor i32 %1, %424
  %428 = add i32 %1, %424
  %429 = sub i32 %428, %427
  %430 = mul i32 %425, 2
  %431 = sub i32 %429, %430
  %432 = mul i32 %431, 245
  %433 = icmp ne i32 %432, 0
  br i1 %433, label %661, label %396

434:                                              ; preds = %11
  %435 = load i32, ptr %4, align 4
  %436 = xor i32 %435, 1541779197
  store i32 %436, ptr %4, align 4
  %437 = xor i32 %1, -455931841
  %438 = and i32 %1, %437
  %439 = or i32 %1, %437
  %440 = xor i32 %1, %437
  %441 = mul i32 %439, 2
  %442 = sub i32 %441, %440
  %443 = sub i32 %442, %1
  %444 = sub i32 %443, %437
  %445 = mul i32 %444, 29
  %446 = xor i32 %1, -1189568231
  %447 = and i32 %1, %446
  %448 = or i32 %1, %446
  %449 = xor i32 %1, %446
  %450 = add i32 %447, %448
  %451 = sub i32 %450, %1
  %452 = sub i32 %451, %446
  %453 = mul i32 %452, 134
  %454 = icmp ne i32 %445, %453
  br i1 %454, label %668, label %396

455:                                              ; preds = %11
  %456 = load i32, ptr %4, align 4
  %457 = xor i32 %456, -1381779307
  store i32 %457, ptr %4, align 4
  %458 = xor i32 %1, 1806465505
  %459 = and i32 %1, %458
  %460 = or i32 %1, %458
  %461 = xor i32 %1, %458
  %462 = add i32 %459, %460
  %463 = sub i32 %462, %1
  %464 = sub i32 %463, %458
  %465 = mul i32 %464, 49
  %466 = icmp eq i32 %465, 0
  br i1 %466, label %396, label %678

467:                                              ; preds = %11
  %468 = load i32, ptr %4, align 4
  %469 = xor i32 %468, 1851078469
  store i32 %469, ptr %4, align 4
  %470 = xor i32 %1, -258526087
  %471 = and i32 %1, %470
  %472 = or i32 %1, %470
  %473 = xor i32 %1, %470
  %474 = mul i32 %472, 2
  %475 = sub i32 %474, %473
  %476 = sub i32 %475, %1
  %477 = sub i32 %476, %470
  %478 = mul i32 %477, 105
  %479 = icmp slt i32 %478, 1
  br i1 %479, label %396, label %685

480:                                              ; preds = %11
  %481 = load i32, ptr %4, align 4
  %482 = xor i32 %481, -1533626665
  store i32 %482, ptr %4, align 4
  %483 = xor i32 %1, 1869354693
  %484 = and i32 %1, %483
  %485 = or i32 %1, %483
  %486 = xor i32 %1, %483
  %487 = add i32 %1, %483
  %488 = sub i32 %487, %486
  %489 = mul i32 %484, 2
  %490 = sub i32 %488, %489
  %491 = mul i32 %490, 184
  %492 = icmp slt i32 %491, 0
  br i1 %492, label %694, label %396

493:                                              ; preds = %11
  %494 = load i32, ptr %4, align 4
  %495 = xor i32 %494, 421962273
  store i32 %495, ptr %4, align 4
  %496 = xor i32 %1, 804138467
  %497 = and i32 %1, %496
  %498 = or i32 %1, %496
  %499 = xor i32 %1, %496
  %500 = add i32 %1, %496
  %501 = sub i32 %500, %499
  %502 = mul i32 %497, 2
  %503 = sub i32 %501, %502
  %504 = mul i32 %503, 148
  %505 = icmp sgt i32 %504, 0
  br i1 %505, label %702, label %396

506:                                              ; preds = %11
  %507 = load i32, ptr %4, align 4
  %508 = xor i32 %507, -744298137
  store i32 %508, ptr %4, align 4
  %509 = xor i32 %1, 977585709
  %510 = and i32 %1, %509
  %511 = or i32 %1, %509
  %512 = xor i32 %1, %509
  %513 = add i32 %510, %511
  %514 = sub i32 %513, %1
  %515 = sub i32 %514, %509
  %516 = mul i32 %515, 71
  %517 = xor i32 %1, -893599461
  %518 = and i32 %1, %517
  %519 = or i32 %1, %517
  %520 = xor i32 %1, %517
  %521 = mul i32 %519, 2
  %522 = sub i32 %521, %520
  %523 = sub i32 %522, %1
  %524 = sub i32 %523, %517
  %525 = mul i32 %524, 222
  %526 = icmp eq i32 %516, %525
  br i1 %526, label %396, label %709

527:                                              ; preds = %15
  %528 = load i64, ptr %3, align 8
  %529 = ptrtoint ptr %0 to i64
  %530 = zext i32 %1 to i64
  %531 = or i64 %529, %530
  %532 = xor i64 %531, %529
  %533 = xor i64 %532, %530
  %534 = mul i64 %533, %530
  store i64 %534, ptr %3, align 8
  br label %396

535:                                              ; preds = %29
  %536 = load i64, ptr %3, align 8
  %537 = ptrtoint ptr %0 to i64
  %538 = zext i32 %1 to i64
  %539 = xor i64 %537, %537
  %540 = and i64 %539, %538
  %541 = xor i64 %540, %538
  %542 = xor i64 %541, %536
  %543 = add i64 %542, %536
  %544 = and i64 %543, %536
  store i64 %544, ptr %3, align 8
  br label %396

545:                                              ; preds = %48
  %546 = load i64, ptr %3, align 8
  %547 = ptrtoint ptr %0 to i64
  %548 = zext i32 %1 to i64
  %549 = add i64 %548, %546
  %550 = mul i64 %549, %546
  %551 = add i64 %550, %546
  store i64 %551, ptr %3, align 8
  br label %396

552:                                              ; preds = %66
  %553 = load i64, ptr %3, align 8
  %554 = ptrtoint ptr %0 to i64
  %555 = zext i32 %1 to i64
  %556 = sub i64 %554, %553
  %557 = sub i64 %556, %555
  %558 = sub i64 %557, %555
  store i64 %558, ptr %3, align 8
  br label %396

559:                                              ; preds = %79
  %560 = load i64, ptr %3, align 8
  %561 = ptrtoint ptr %0 to i64
  %562 = zext i32 %1 to i64
  %563 = add i64 %560, %561
  %564 = or i64 %563, %562
  %565 = sub i64 %564, %560
  %566 = or i64 %565, %562
  %567 = or i64 %566, %561
  store i64 %567, ptr %3, align 8
  br label %396

568:                                              ; preds = %92
  %569 = load i64, ptr %3, align 8
  %570 = ptrtoint ptr %0 to i64
  %571 = zext i32 %1 to i64
  %572 = xor i64 %570, %570
  %573 = sub i64 %572, %571
  %574 = xor i64 %573, %569
  store i64 %574, ptr %3, align 8
  br label %396

575:                                              ; preds = %107
  %576 = load i64, ptr %3, align 8
  %577 = ptrtoint ptr %0 to i64
  %578 = zext i32 %1 to i64
  %579 = sub i64 %578, %576
  %580 = add i64 %579, %577
  %581 = xor i64 %580, %578
  %582 = or i64 %581, %577
  %583 = mul i64 %582, %578
  %584 = sub i64 %583, %578
  store i64 %584, ptr %3, align 8
  br label %396

585:                                              ; preds = %173
  %586 = load i64, ptr %3, align 8
  %587 = ptrtoint ptr %0 to i64
  %588 = zext i32 %1 to i64
  %589 = and i64 %587, %587
  %590 = sub i64 %589, %588
  %591 = or i64 %590, %587
  %592 = and i64 %591, %587
  %593 = add i64 %592, %587
  store i64 %593, ptr %3, align 8
  br label %396

594:                                              ; preds = %187
  %595 = load i64, ptr %3, align 8
  %596 = ptrtoint ptr %0 to i64
  %597 = zext i32 %1 to i64
  %598 = or i64 %596, %595
  %599 = and i64 %598, %597
  %600 = mul i64 %599, %597
  %601 = sub i64 %600, %596
  %602 = xor i64 %601, %597
  store i64 %602, ptr %3, align 8
  br label %396

603:                                              ; preds = %200
  %604 = load i64, ptr %3, align 8
  %605 = ptrtoint ptr %0 to i64
  %606 = zext i32 %1 to i64
  %607 = sub i64 %604, %605
  %608 = add i64 %607, %604
  %609 = mul i64 %608, %605
  %610 = mul i64 %609, %606
  store i64 %610, ptr %3, align 8
  br label %396

611:                                              ; preds = %263
  %612 = load i64, ptr %3, align 8
  %613 = ptrtoint ptr %0 to i64
  %614 = zext i32 %1 to i64
  %615 = or i64 %612, %614
  %616 = xor i64 %615, %613
  %617 = add i64 %616, %613
  %618 = add i64 %617, %612
  store i64 %618, ptr %3, align 8
  br label %396

619:                                              ; preds = %281
  %620 = load i64, ptr %3, align 8
  %621 = ptrtoint ptr %0 to i64
  %622 = zext i32 %1 to i64
  %623 = sub i64 %620, %621
  %624 = xor i64 %623, %620
  %625 = or i64 %624, %621
  %626 = mul i64 %625, %622
  store i64 %626, ptr %3, align 8
  br label %396

627:                                              ; preds = %358
  %628 = load i64, ptr %3, align 8
  %629 = ptrtoint ptr %0 to i64
  %630 = zext i32 %1 to i64
  %631 = and i64 %629, %630
  %632 = xor i64 %631, %629
  %633 = and i64 %632, %628
  %634 = or i64 %633, %630
  store i64 %634, ptr %3, align 8
  br label %396

635:                                              ; preds = %378
  %636 = load i64, ptr %3, align 8
  %637 = ptrtoint ptr %0 to i64
  %638 = zext i32 %1 to i64
  %639 = sub i64 %638, %636
  %640 = or i64 %639, %636
  %641 = xor i64 %640, %636
  %642 = xor i64 %641, %636
  %643 = add i64 %642, %636
  %644 = mul i64 %643, %638
  store i64 %644, ptr %3, align 8
  br label %396

645:                                              ; preds = %397
  %646 = load i64, ptr %3, align 8
  %647 = ptrtoint ptr %0 to i64
  %648 = zext i32 %1 to i64
  %649 = xor i64 %648, %648
  %650 = add i64 %649, %647
  %651 = add i64 %650, %646
  %652 = or i64 %651, %648
  store i64 %652, ptr %3, align 8
  br label %11

653:                                              ; preds = %408
  %654 = load i64, ptr %3, align 8
  %655 = ptrtoint ptr %0 to i64
  %656 = zext i32 %1 to i64
  %657 = xor i64 %655, %655
  %658 = xor i64 %657, %655
  %659 = sub i64 %658, %655
  %660 = and i64 %659, %655
  store i64 %660, ptr %3, align 8
  br label %396

661:                                              ; preds = %421
  %662 = load i64, ptr %3, align 8
  %663 = ptrtoint ptr %0 to i64
  %664 = zext i32 %1 to i64
  %665 = and i64 %664, %664
  %666 = mul i64 %665, %663
  %667 = xor i64 %666, %663
  store i64 %667, ptr %3, align 8
  br label %396

668:                                              ; preds = %434
  %669 = load i64, ptr %3, align 8
  %670 = ptrtoint ptr %0 to i64
  %671 = zext i32 %1 to i64
  %672 = mul i64 %670, %670
  %673 = sub i64 %672, %671
  %674 = sub i64 %673, %669
  %675 = or i64 %674, %670
  %676 = mul i64 %675, %670
  %677 = mul i64 %676, %669
  store i64 %677, ptr %3, align 8
  br label %396

678:                                              ; preds = %455
  %679 = load i64, ptr %3, align 8
  %680 = ptrtoint ptr %0 to i64
  %681 = zext i32 %1 to i64
  %682 = sub i64 %681, %680
  %683 = xor i64 %682, %679
  %684 = add i64 %683, %679
  store i64 %684, ptr %3, align 8
  br label %396

685:                                              ; preds = %467
  %686 = load i64, ptr %3, align 8
  %687 = ptrtoint ptr %0 to i64
  %688 = zext i32 %1 to i64
  %689 = xor i64 %688, %686
  %690 = and i64 %689, %686
  %691 = sub i64 %690, %686
  %692 = and i64 %691, %688
  %693 = or i64 %692, %688
  store i64 %693, ptr %3, align 8
  br label %396

694:                                              ; preds = %480
  %695 = load i64, ptr %3, align 8
  %696 = ptrtoint ptr %0 to i64
  %697 = zext i32 %1 to i64
  %698 = xor i64 %695, %697
  %699 = sub i64 %698, %697
  %700 = mul i64 %699, %697
  %701 = or i64 %700, %695
  store i64 %701, ptr %3, align 8
  br label %396

702:                                              ; preds = %493
  %703 = load i64, ptr %3, align 8
  %704 = ptrtoint ptr %0 to i64
  %705 = zext i32 %1 to i64
  %706 = and i64 %705, %704
  %707 = add i64 %706, %704
  %708 = sub i64 %707, %703
  store i64 %708, ptr %3, align 8
  br label %396

709:                                              ; preds = %506
  %710 = load i64, ptr %3, align 8
  %711 = ptrtoint ptr %0 to i64
  %712 = zext i32 %1 to i64
  %713 = xor i64 %712, %712
  %714 = sub i64 %713, %710
  %715 = sub i64 %714, %710
  %716 = mul i64 %715, %711
  %717 = or i64 %716, %712
  store i64 %717, ptr %3, align 8
  br label %396
}

declare noalias ptr @fopen(ptr noundef, ptr noundef) #4

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #5

declare i32 @fclose(ptr noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @handleCommand(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i64, align 8
  store i64 0, ptr %3, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca [16 x ptr], align 16
  %8 = alloca i32, align 4
  %9 = alloca [64 x i8], align 16
  store i32 -18528230, ptr %4, align 4
  br label %10

10:                                               ; preds = %1393, %698, %697, %2
  %11 = load i32, ptr %4, align 4
  %12 = sub i32 %11, 1729033675
  %13 = mul i32 %12, -792615163
  %14 = icmp slt i32 %13, 1152236658
  br i1 %14, label %810, label %812

15:                                               ; preds = %828
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  %16 = load ptr, ptr %5, align 8
  call void @trim(ptr noundef %16)
  %17 = load ptr, ptr %5, align 8
  %18 = getelementptr inbounds i8, ptr %17, i64 0
  %19 = load i8, ptr %18, align 1
  %20 = sext i8 %19 to i32
  %21 = icmp eq i32 %20, 0
  %22 = select i1 %21, i32 -968667208, i32 -1691658136
  store i32 %22, ptr %4, align 4
  %23 = xor i32 %1, -765847221
  %24 = and i32 %1, %23
  %25 = or i32 %1, %23
  %26 = xor i32 %1, %23
  %27 = add i32 %1, %23
  %28 = sub i32 %27, %26
  %29 = mul i32 %24, 2
  %30 = sub i32 %28, %29
  %31 = mul i32 %30, 100
  %32 = xor i32 %1, -281228405
  %33 = and i32 %1, %32
  %34 = or i32 %1, %32
  %35 = xor i32 %1, %32
  %36 = add i32 %1, %32
  %37 = sub i32 %36, %35
  %38 = mul i32 %33, 2
  %39 = sub i32 %37, %38
  %40 = mul i32 %39, 4
  %41 = icmp ne i32 %31, %40
  br i1 %41, label %982, label %697

42:                                               ; preds = %936
  %43 = load i32, ptr %6, align 4
  %44 = call i32 (ptr, ...) @printf(ptr noundef @.str.105, i32 noundef %43)
  store i32 1784726114, ptr %4, align 4
  %45 = xor i32 %1, -91970125
  %46 = and i32 %1, %45
  %47 = or i32 %1, %45
  %48 = xor i32 %1, %45
  %49 = add i32 %46, %47
  %50 = sub i32 %49, %1
  %51 = sub i32 %50, %45
  %52 = mul i32 %51, 156
  %53 = icmp sle i32 %52, 0
  br i1 %53, label %697, label %991

54:                                               ; preds = %974
  %55 = load ptr, ptr %5, align 8
  %56 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %57 = call i32 @splitPipe(ptr noundef %55, ptr noundef %56, i32 noundef 16)
  store i32 %57, ptr %8, align 4
  %58 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %59 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %60 = load ptr, ptr %59, align 16
  %61 = call ptr @strcpy(ptr noundef %58, ptr noundef %60) #9
  %62 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  call void @upperString(ptr noundef %62)
  %63 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %64 = call i32 (ptr, ...) @printf(ptr noundef @.str.106, ptr noundef %63)
  %65 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %66 = call i32 @strcmp(ptr noundef %65, ptr noundef @.str.107) #8
  %67 = icmp eq i32 %66, 0
  %68 = select i1 %67, i32 1942798196, i32 733081105
  store i32 %68, ptr %4, align 4
  %69 = xor i32 %1, -1518325023
  %70 = and i32 %1, %69
  %71 = or i32 %1, %69
  %72 = xor i32 %1, %69
  %73 = add i32 %1, %69
  %74 = sub i32 %73, %72
  %75 = mul i32 %70, 2
  %76 = sub i32 %74, %75
  %77 = mul i32 %76, 109
  %78 = icmp slt i32 %77, 0
  br i1 %78, label %1000, label %697

79:                                               ; preds = %960
  %80 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %81 = load i32, ptr %8, align 4
  call void @cmdAdd(ptr noundef %80, i32 noundef %81)
  store i32 1784726114, ptr %4, align 4
  %82 = xor i32 %1, 1665633763
  %83 = and i32 %1, %82
  %84 = or i32 %1, %82
  %85 = xor i32 %1, %82
  %86 = add i32 %83, %84
  %87 = sub i32 %86, %1
  %88 = sub i32 %87, %82
  %89 = mul i32 %88, 171
  %90 = icmp ugt i32 %89, 0
  br i1 %90, label %1009, label %697

91:                                               ; preds = %874
  %92 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %93 = call i32 @strcmp(ptr noundef %92, ptr noundef @.str.108) #8
  %94 = icmp eq i32 %93, 0
  %95 = select i1 %94, i32 -736266794, i32 -2034751989
  store i32 %95, ptr %4, align 4
  %96 = xor i32 %1, 1574127195
  %97 = and i32 %1, %96
  %98 = or i32 %1, %96
  %99 = xor i32 %1, %96
  %100 = sub i32 %98, %99
  %101 = sub i32 %100, %97
  %102 = mul i32 %101, 229
  %103 = icmp ne i32 %102, 0
  br i1 %103, label %1016, label %697

104:                                              ; preds = %832
  %105 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %106 = load i32, ptr %8, align 4
  call void @cmdRemove(ptr noundef %105, i32 noundef %106)
  store i32 -752609016, ptr %4, align 4
  %107 = xor i32 %1, 266110565
  %108 = and i32 %1, %107
  %109 = or i32 %1, %107
  %110 = xor i32 %1, %107
  %111 = add i32 %108, %109
  %112 = sub i32 %111, %1
  %113 = sub i32 %112, %107
  %114 = mul i32 %113, 149
  %115 = xor i32 %1, 209791843
  %116 = and i32 %1, %115
  %117 = or i32 %1, %115
  %118 = xor i32 %1, %115
  %119 = mul i32 %117, 2
  %120 = sub i32 %119, %118
  %121 = sub i32 %120, %1
  %122 = sub i32 %121, %115
  %123 = mul i32 %122, 214
  %124 = icmp ne i32 %114, %123
  br i1 %124, label %1024, label %697

125:                                              ; preds = %934
  %126 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %127 = call i32 @strcmp(ptr noundef %126, ptr noundef @.str.109) #8
  %128 = icmp eq i32 %127, 0
  %129 = select i1 %128, i32 1458743201, i32 477848805
  store i32 %129, ptr %4, align 4
  %130 = xor i32 %1, -489652821
  %131 = and i32 %1, %130
  %132 = or i32 %1, %130
  %133 = xor i32 %1, %130
  %134 = mul i32 %132, 2
  %135 = sub i32 %134, %133
  %136 = sub i32 %135, %1
  %137 = sub i32 %136, %130
  %138 = mul i32 %137, 105
  %139 = icmp eq i32 %138, 0
  br i1 %139, label %697, label %1034

140:                                              ; preds = %872
  %141 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %142 = load i32, ptr %8, align 4
  call void @cmdRestock(ptr noundef %141, i32 noundef %142)
  store i32 -244937713, ptr %4, align 4
  %143 = xor i32 %1, 1689817341
  %144 = and i32 %1, %143
  %145 = or i32 %1, %143
  %146 = xor i32 %1, %143
  %147 = add i32 %1, %143
  %148 = sub i32 %147, %146
  %149 = mul i32 %144, 2
  %150 = sub i32 %148, %149
  %151 = mul i32 %150, 239
  %152 = icmp sgt i32 %151, 0
  br i1 %152, label %1044, label %697

153:                                              ; preds = %870
  %154 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %155 = call i32 @strcmp(ptr noundef %154, ptr noundef @.str.110) #8
  %156 = icmp eq i32 %155, 0
  %157 = select i1 %156, i32 594798222, i32 1691739456
  store i32 %157, ptr %4, align 4
  %158 = xor i32 %1, -1078310921
  %159 = and i32 %1, %158
  %160 = or i32 %1, %158
  %161 = xor i32 %1, %158
  %162 = sub i32 %160, %161
  %163 = sub i32 %162, %159
  %164 = mul i32 %163, 176
  %165 = xor i32 %1, -159636147
  %166 = and i32 %1, %165
  %167 = or i32 %1, %165
  %168 = xor i32 %1, %165
  %169 = sub i32 %167, %168
  %170 = sub i32 %169, %166
  %171 = mul i32 %170, 76
  %172 = icmp ne i32 %164, %171
  br i1 %172, label %1053, label %697

173:                                              ; preds = %978
  %174 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %175 = load i32, ptr %8, align 4
  call void @cmdUpdatePrice(ptr noundef %174, i32 noundef %175)
  store i32 -266830747, ptr %4, align 4
  %176 = xor i32 %1, -2041707503
  %177 = and i32 %1, %176
  %178 = or i32 %1, %176
  %179 = xor i32 %1, %176
  %180 = add i32 %1, %176
  %181 = sub i32 %180, %179
  %182 = mul i32 %177, 2
  %183 = sub i32 %181, %182
  %184 = mul i32 %183, 113
  %185 = icmp ugt i32 %184, 0
  br i1 %185, label %1060, label %697

186:                                              ; preds = %916
  %187 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %188 = call i32 @strcmp(ptr noundef %187, ptr noundef @.str.111) #8
  %189 = icmp eq i32 %188, 0
  %190 = select i1 %189, i32 -1557826485, i32 -1598981270
  store i32 %190, ptr %4, align 4
  %191 = xor i32 %1, -1616877147
  %192 = and i32 %1, %191
  %193 = or i32 %1, %191
  %194 = xor i32 %1, %191
  %195 = sub i32 %193, %194
  %196 = sub i32 %195, %192
  %197 = mul i32 %196, 55
  %198 = icmp slt i32 %197, 0
  br i1 %198, label %1067, label %697

199:                                              ; preds = %884
  call void @cmdList()
  store i32 -1057298102, ptr %4, align 4
  %200 = xor i32 %1, -757070443
  %201 = and i32 %1, %200
  %202 = or i32 %1, %200
  %203 = xor i32 %1, %200
  %204 = add i32 %201, %202
  %205 = sub i32 %204, %1
  %206 = sub i32 %205, %200
  %207 = mul i32 %206, 227
  %208 = icmp slt i32 %207, 0
  br i1 %208, label %1076, label %697

209:                                              ; preds = %848
  %210 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %211 = call i32 @strcmp(ptr noundef %210, ptr noundef @.str.112) #8
  %212 = icmp eq i32 %211, 0
  %213 = select i1 %212, i32 961127025, i32 1737327028
  store i32 %213, ptr %4, align 4
  %214 = xor i32 %1, 653731985
  %215 = and i32 %1, %214
  %216 = or i32 %1, %214
  %217 = xor i32 %1, %214
  %218 = mul i32 %216, 2
  %219 = sub i32 %218, %217
  %220 = sub i32 %219, %1
  %221 = sub i32 %220, %214
  %222 = mul i32 %221, 35
  %223 = icmp ne i32 %222, 0
  br i1 %223, label %1083, label %697

224:                                              ; preds = %962
  %225 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %226 = load i32, ptr %8, align 4
  call void @cmdSearchName(ptr noundef %225, i32 noundef %226)
  store i32 1833080615, ptr %4, align 4
  %227 = xor i32 %1, -1519287937
  %228 = and i32 %1, %227
  %229 = or i32 %1, %227
  %230 = xor i32 %1, %227
  %231 = mul i32 %229, 2
  %232 = sub i32 %231, %230
  %233 = sub i32 %232, %1
  %234 = sub i32 %233, %227
  %235 = mul i32 %234, 39
  %236 = icmp slt i32 %235, 0
  br i1 %236, label %1093, label %697

237:                                              ; preds = %918
  %238 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %239 = call i32 @strcmp(ptr noundef %238, ptr noundef @.str.113) #8
  %240 = icmp eq i32 %239, 0
  %241 = select i1 %240, i32 1184592317, i32 2041582039
  store i32 %241, ptr %4, align 4
  %242 = xor i32 %1, -1013925083
  %243 = and i32 %1, %242
  %244 = or i32 %1, %242
  %245 = xor i32 %1, %242
  %246 = add i32 %243, %244
  %247 = sub i32 %246, %1
  %248 = sub i32 %247, %242
  %249 = mul i32 %248, 216
  %250 = icmp uge i32 %249, 0
  br i1 %250, label %697, label %1102

251:                                              ; preds = %854
  %252 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %253 = load i32, ptr %8, align 4
  call void @cmdSearchCategory(ptr noundef %252, i32 noundef %253)
  store i32 -238322472, ptr %4, align 4
  %254 = xor i32 %1, 877377031
  %255 = and i32 %1, %254
  %256 = or i32 %1, %254
  %257 = xor i32 %1, %254
  %258 = add i32 %255, %256
  %259 = sub i32 %258, %1
  %260 = sub i32 %259, %254
  %261 = mul i32 %260, 236
  %262 = icmp sle i32 %261, 0
  br i1 %262, label %697, label %1111

263:                                              ; preds = %932
  %264 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %265 = call i32 @strcmp(ptr noundef %264, ptr noundef @.str.114) #8
  %266 = icmp eq i32 %265, 0
  %267 = select i1 %266, i32 1021362996, i32 492047258
  store i32 %267, ptr %4, align 4
  %268 = xor i32 %1, -1401330511
  %269 = and i32 %1, %268
  %270 = or i32 %1, %268
  %271 = xor i32 %1, %268
  %272 = sub i32 %270, %271
  %273 = sub i32 %272, %269
  %274 = mul i32 %273, 151
  %275 = icmp ne i32 %274, 0
  br i1 %275, label %1120, label %697

276:                                              ; preds = %878
  %277 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %278 = load i32, ptr %8, align 4
  call void @cmdLowStock(ptr noundef %277, i32 noundef %278)
  store i32 1295617042, ptr %4, align 4
  %279 = xor i32 %1, -388581639
  %280 = and i32 %1, %279
  %281 = or i32 %1, %279
  %282 = xor i32 %1, %279
  %283 = add i32 %280, %281
  %284 = sub i32 %283, %1
  %285 = sub i32 %284, %279
  %286 = mul i32 %285, 138
  %287 = icmp ugt i32 %286, 0
  br i1 %287, label %1129, label %697

288:                                              ; preds = %894
  %289 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %290 = call i32 @strcmp(ptr noundef %289, ptr noundef @.str.115) #8
  %291 = icmp eq i32 %290, 0
  %292 = select i1 %291, i32 -1327948236, i32 -2028017180
  store i32 %292, ptr %4, align 4
  %293 = xor i32 %1, -2118109175
  %294 = and i32 %1, %293
  %295 = or i32 %1, %293
  %296 = xor i32 %1, %293
  %297 = add i32 %294, %295
  %298 = sub i32 %297, %1
  %299 = sub i32 %298, %293
  %300 = mul i32 %299, 66
  %301 = icmp sle i32 %300, 0
  br i1 %301, label %697, label %1137

302:                                              ; preds = %856
  %303 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %304 = load i32, ptr %8, align 4
  call void @cmdSort(ptr noundef %303, i32 noundef %304)
  store i32 2000868930, ptr %4, align 4
  %305 = xor i32 %1, -360016181
  %306 = and i32 %1, %305
  %307 = or i32 %1, %305
  %308 = xor i32 %1, %305
  %309 = mul i32 %307, 2
  %310 = sub i32 %309, %308
  %311 = sub i32 %310, %1
  %312 = sub i32 %311, %305
  %313 = mul i32 %312, 93
  %314 = icmp eq i32 %313, 0
  br i1 %314, label %697, label %1144

315:                                              ; preds = %950
  %316 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %317 = call i32 @strcmp(ptr noundef %316, ptr noundef @.str.116) #8
  %318 = icmp eq i32 %317, 0
  %319 = select i1 %318, i32 -875162442, i32 -712704127
  store i32 %319, ptr %4, align 4
  %320 = xor i32 %1, 1450231423
  %321 = and i32 %1, %320
  %322 = or i32 %1, %320
  %323 = xor i32 %1, %320
  %324 = add i32 %1, %320
  %325 = sub i32 %324, %323
  %326 = mul i32 %321, 2
  %327 = sub i32 %325, %326
  %328 = mul i32 %327, 190
  %329 = icmp slt i32 %328, 1
  br i1 %329, label %697, label %1151

330:                                              ; preds = %866
  %331 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %332 = load i32, ptr %8, align 4
  call void @cmdBuy(ptr noundef %331, i32 noundef %332)
  store i32 1842598222, ptr %4, align 4
  %333 = xor i32 %1, 1339480069
  %334 = and i32 %1, %333
  %335 = or i32 %1, %333
  %336 = xor i32 %1, %333
  %337 = sub i32 %335, %336
  %338 = sub i32 %337, %334
  %339 = mul i32 %338, 86
  %340 = xor i32 %1, 556540307
  %341 = and i32 %1, %340
  %342 = or i32 %1, %340
  %343 = xor i32 %1, %340
  %344 = sub i32 %342, %343
  %345 = sub i32 %344, %341
  %346 = mul i32 %345, 131
  %347 = icmp ne i32 %339, %346
  br i1 %347, label %1160, label %697

348:                                              ; preds = %922
  %349 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %350 = call i32 @strcmp(ptr noundef %349, ptr noundef @.str.117) #8
  %351 = icmp eq i32 %350, 0
  %352 = select i1 %351, i32 1763065291, i32 960229180
  store i32 %352, ptr %4, align 4
  %353 = xor i32 %1, 867860261
  %354 = and i32 %1, %353
  %355 = or i32 %1, %353
  %356 = xor i32 %1, %353
  %357 = add i32 %354, %355
  %358 = sub i32 %357, %1
  %359 = sub i32 %358, %353
  %360 = mul i32 %359, 144
  %361 = icmp ne i32 %360, 0
  br i1 %361, label %1170, label %697

362:                                              ; preds = %844
  %363 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %364 = load i32, ptr %8, align 4
  call void @cmdCancel(ptr noundef %363, i32 noundef %364)
  store i32 505047473, ptr %4, align 4
  %365 = xor i32 %1, 1848654645
  %366 = and i32 %1, %365
  %367 = or i32 %1, %365
  %368 = xor i32 %1, %365
  %369 = mul i32 %367, 2
  %370 = sub i32 %369, %368
  %371 = sub i32 %370, %1
  %372 = sub i32 %371, %365
  %373 = mul i32 %372, 34
  %374 = icmp eq i32 %373, 0
  br i1 %374, label %697, label %1180

375:                                              ; preds = %914
  %376 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %377 = call i32 @strcmp(ptr noundef %376, ptr noundef @.str.118) #8
  %378 = icmp eq i32 %377, 0
  %379 = select i1 %378, i32 1554152188, i32 -726220752
  store i32 %379, ptr %4, align 4
  %380 = xor i32 %1, 2146500971
  %381 = and i32 %1, %380
  %382 = or i32 %1, %380
  %383 = xor i32 %1, %380
  %384 = add i32 %381, %382
  %385 = sub i32 %384, %1
  %386 = sub i32 %385, %380
  %387 = mul i32 %386, 70
  %388 = icmp ne i32 %387, 0
  br i1 %388, label %1188, label %697

389:                                              ; preds = %892
  %390 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %391 = load i32, ptr %8, align 4
  call void @cmdOrder(ptr noundef %390, i32 noundef %391)
  store i32 846775905, ptr %4, align 4
  %392 = xor i32 %1, -975559089
  %393 = and i32 %1, %392
  %394 = or i32 %1, %392
  %395 = xor i32 %1, %392
  %396 = add i32 %393, %394
  %397 = sub i32 %396, %1
  %398 = sub i32 %397, %392
  %399 = mul i32 %398, 16
  %400 = icmp ugt i32 %399, 0
  br i1 %400, label %1195, label %697

401:                                              ; preds = %890
  %402 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %403 = call i32 @strcmp(ptr noundef %402, ptr noundef @.str.119) #8
  %404 = icmp eq i32 %403, 0
  %405 = select i1 %404, i32 -504222983, i32 -925592821
  store i32 %405, ptr %4, align 4
  %406 = xor i32 %1, 482718725
  %407 = and i32 %1, %406
  %408 = or i32 %1, %406
  %409 = xor i32 %1, %406
  %410 = add i32 %1, %406
  %411 = sub i32 %410, %409
  %412 = mul i32 %407, 2
  %413 = sub i32 %411, %412
  %414 = mul i32 %413, 216
  %415 = icmp eq i32 %414, 0
  br i1 %415, label %697, label %1204

416:                                              ; preds = %852
  call void @cmdOrders()
  store i32 1425318389, ptr %4, align 4
  %417 = xor i32 %1, 935641667
  %418 = and i32 %1, %417
  %419 = or i32 %1, %417
  %420 = xor i32 %1, %417
  %421 = sub i32 %419, %420
  %422 = sub i32 %421, %418
  %423 = mul i32 %422, 88
  %424 = icmp sle i32 %423, 0
  br i1 %424, label %697, label %1211

425:                                              ; preds = %952
  %426 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %427 = call i32 @strcmp(ptr noundef %426, ptr noundef @.str.120) #8
  %428 = icmp eq i32 %427, 0
  %429 = select i1 %428, i32 -647597021, i32 -1279034969
  store i32 %429, ptr %4, align 4
  %430 = xor i32 %1, -1567365571
  %431 = and i32 %1, %430
  %432 = or i32 %1, %430
  %433 = xor i32 %1, %430
  %434 = add i32 %1, %430
  %435 = sub i32 %434, %433
  %436 = mul i32 %431, 2
  %437 = sub i32 %435, %436
  %438 = mul i32 %437, 13
  %439 = xor i32 %1, 945008385
  %440 = and i32 %1, %439
  %441 = or i32 %1, %439
  %442 = xor i32 %1, %439
  %443 = mul i32 %441, 2
  %444 = sub i32 %443, %442
  %445 = sub i32 %444, %1
  %446 = sub i32 %445, %439
  %447 = mul i32 %446, 88
  %448 = icmp eq i32 %438, %447
  br i1 %448, label %697, label %1220

449:                                              ; preds = %836
  call void @cmdReport()
  store i32 -1136770307, ptr %4, align 4
  %450 = xor i32 %1, -115107847
  %451 = and i32 %1, %450
  %452 = or i32 %1, %450
  %453 = xor i32 %1, %450
  %454 = add i32 %1, %450
  %455 = sub i32 %454, %453
  %456 = mul i32 %451, 2
  %457 = sub i32 %455, %456
  %458 = mul i32 %457, 198
  %459 = xor i32 %1, -290020777
  %460 = and i32 %1, %459
  %461 = or i32 %1, %459
  %462 = xor i32 %1, %459
  %463 = sub i32 %461, %462
  %464 = sub i32 %463, %460
  %465 = mul i32 %464, 80
  %466 = icmp eq i32 %458, %465
  br i1 %466, label %697, label %1228

467:                                              ; preds = %958
  %468 = getelementptr inbounds [64 x i8], ptr %9, i64 0, i64 0
  %469 = call i32 @strcmp(ptr noundef %468, ptr noundef @.str.121) #8
  %470 = icmp eq i32 %469, 0
  %471 = select i1 %470, i32 1786628789, i32 1520467088
  store i32 %471, ptr %4, align 4
  %472 = xor i32 %1, -1489030889
  %473 = and i32 %1, %472
  %474 = or i32 %1, %472
  %475 = xor i32 %1, %472
  %476 = add i32 %473, %474
  %477 = sub i32 %476, %1
  %478 = sub i32 %477, %472
  %479 = mul i32 %478, 181
  %480 = icmp sgt i32 %479, 0
  br i1 %480, label %1237, label %697

481:                                              ; preds = %826
  %482 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %483 = load i32, ptr %8, align 4
  call void @cmdSave(ptr noundef %482, i32 noundef %483)
  store i32 -1342505503, ptr %4, align 4
  %484 = xor i32 %1, -1030037343
  %485 = and i32 %1, %484
  %486 = or i32 %1, %484
  %487 = xor i32 %1, %484
  %488 = sub i32 %486, %487
  %489 = sub i32 %488, %485
  %490 = mul i32 %489, 208
  %491 = icmp slt i32 %490, 0
  br i1 %491, label %1247, label %697

492:                                              ; preds = %930
  %493 = getelementptr inbounds [16 x ptr], ptr %7, i64 0, i64 0
  %494 = load ptr, ptr %493, align 16
  %495 = call i32 (ptr, ...) @printf(ptr noundef @.str.122, ptr noundef %494)
  store i32 -1342505503, ptr %4, align 4
  %496 = xor i32 %1, 1552104195
  %497 = and i32 %1, %496
  %498 = or i32 %1, %496
  %499 = xor i32 %1, %496
  %500 = add i32 %1, %496
  %501 = sub i32 %500, %499
  %502 = mul i32 %497, 2
  %503 = sub i32 %501, %502
  %504 = mul i32 %503, 71
  %505 = icmp ne i32 %504, 0
  br i1 %505, label %1256, label %697

506:                                              ; preds = %940
  store i32 -1136770307, ptr %4, align 4
  %507 = xor i32 %1, 694069523
  %508 = and i32 %1, %507
  %509 = or i32 %1, %507
  %510 = xor i32 %1, %507
  %511 = add i32 %1, %507
  %512 = sub i32 %511, %510
  %513 = mul i32 %508, 2
  %514 = sub i32 %512, %513
  %515 = mul i32 %514, 174
  %516 = icmp ugt i32 %515, 0
  br i1 %516, label %1263, label %697

517:                                              ; preds = %920
  store i32 1425318389, ptr %4, align 4
  %518 = xor i32 %1, 1629739829
  %519 = and i32 %1, %518
  %520 = or i32 %1, %518
  %521 = xor i32 %1, %518
  %522 = add i32 %1, %518
  %523 = sub i32 %522, %521
  %524 = mul i32 %519, 2
  %525 = sub i32 %523, %524
  %526 = mul i32 %525, 228
  %527 = icmp slt i32 %526, 1
  br i1 %527, label %697, label %1272

528:                                              ; preds = %956
  store i32 846775905, ptr %4, align 4
  %529 = xor i32 %1, -1164987151
  %530 = and i32 %1, %529
  %531 = or i32 %1, %529
  %532 = xor i32 %1, %529
  %533 = mul i32 %531, 2
  %534 = sub i32 %533, %532
  %535 = sub i32 %534, %1
  %536 = sub i32 %535, %529
  %537 = mul i32 %536, 58
  %538 = xor i32 %1, 393354535
  %539 = and i32 %1, %538
  %540 = or i32 %1, %538
  %541 = xor i32 %1, %538
  %542 = add i32 %539, %540
  %543 = sub i32 %542, %1
  %544 = sub i32 %543, %538
  %545 = mul i32 %544, 54
  %546 = icmp eq i32 %537, %545
  br i1 %546, label %697, label %1282

547:                                              ; preds = %868
  store i32 505047473, ptr %4, align 4
  %548 = xor i32 %1, -889678049
  %549 = and i32 %1, %548
  %550 = or i32 %1, %548
  %551 = xor i32 %1, %548
  %552 = add i32 %549, %550
  %553 = sub i32 %552, %1
  %554 = sub i32 %553, %548
  %555 = mul i32 %554, 178
  %556 = icmp sgt i32 %555, 0
  br i1 %556, label %1289, label %697

557:                                              ; preds = %912
  store i32 1842598222, ptr %4, align 4
  %558 = xor i32 %1, -1011387423
  %559 = and i32 %1, %558
  %560 = or i32 %1, %558
  %561 = xor i32 %1, %558
  %562 = mul i32 %560, 2
  %563 = sub i32 %562, %561
  %564 = sub i32 %563, %1
  %565 = sub i32 %564, %558
  %566 = mul i32 %565, 70
  %567 = icmp slt i32 %566, 0
  br i1 %567, label %1299, label %697

568:                                              ; preds = %976
  store i32 2000868930, ptr %4, align 4
  %569 = xor i32 %1, -1420481331
  %570 = and i32 %1, %569
  %571 = or i32 %1, %569
  %572 = xor i32 %1, %569
  %573 = mul i32 %571, 2
  %574 = sub i32 %573, %572
  %575 = sub i32 %574, %1
  %576 = sub i32 %575, %569
  %577 = mul i32 %576, 231
  %578 = xor i32 %1, -1632058453
  %579 = and i32 %1, %578
  %580 = or i32 %1, %578
  %581 = xor i32 %1, %578
  %582 = add i32 %579, %580
  %583 = sub i32 %582, %1
  %584 = sub i32 %583, %578
  %585 = mul i32 %584, 4
  %586 = icmp eq i32 %577, %585
  br i1 %586, label %697, label %1308

587:                                              ; preds = %846
  store i32 1295617042, ptr %4, align 4
  %588 = xor i32 %1, -2147189947
  %589 = and i32 %1, %588
  %590 = or i32 %1, %588
  %591 = xor i32 %1, %588
  %592 = mul i32 %590, 2
  %593 = sub i32 %592, %591
  %594 = sub i32 %593, %1
  %595 = sub i32 %594, %588
  %596 = mul i32 %595, 162
  %597 = xor i32 %1, 1631322915
  %598 = and i32 %1, %597
  %599 = or i32 %1, %597
  %600 = xor i32 %1, %597
  %601 = sub i32 %599, %600
  %602 = sub i32 %601, %598
  %603 = mul i32 %602, 105
  %604 = icmp ne i32 %596, %603
  br i1 %604, label %1317, label %697

605:                                              ; preds = %896
  store i32 -238322472, ptr %4, align 4
  %606 = xor i32 %1, -715098201
  %607 = and i32 %1, %606
  %608 = or i32 %1, %606
  %609 = xor i32 %1, %606
  %610 = add i32 %1, %606
  %611 = sub i32 %610, %609
  %612 = mul i32 %607, 2
  %613 = sub i32 %611, %612
  %614 = mul i32 %613, 154
  %615 = icmp ne i32 %614, 0
  br i1 %615, label %1327, label %697

616:                                              ; preds = %850
  store i32 1833080615, ptr %4, align 4
  %617 = xor i32 %1, 769795195
  %618 = and i32 %1, %617
  %619 = or i32 %1, %617
  %620 = xor i32 %1, %617
  %621 = add i32 %1, %617
  %622 = sub i32 %621, %620
  %623 = mul i32 %618, 2
  %624 = sub i32 %622, %623
  %625 = mul i32 %624, 148
  %626 = xor i32 %1, -824389817
  %627 = and i32 %1, %626
  %628 = or i32 %1, %626
  %629 = xor i32 %1, %626
  %630 = add i32 %1, %626
  %631 = sub i32 %630, %629
  %632 = mul i32 %627, 2
  %633 = sub i32 %631, %632
  %634 = mul i32 %633, 212
  %635 = icmp eq i32 %625, %634
  br i1 %635, label %697, label %1337

636:                                              ; preds = %876
  store i32 -1057298102, ptr %4, align 4
  %637 = xor i32 %1, 1609310765
  %638 = and i32 %1, %637
  %639 = or i32 %1, %637
  %640 = xor i32 %1, %637
  %641 = mul i32 %639, 2
  %642 = sub i32 %641, %640
  %643 = sub i32 %642, %1
  %644 = sub i32 %643, %637
  %645 = mul i32 %644, 161
  %646 = xor i32 %1, -1545518655
  %647 = and i32 %1, %646
  %648 = or i32 %1, %646
  %649 = xor i32 %1, %646
  %650 = sub i32 %648, %649
  %651 = sub i32 %650, %647
  %652 = mul i32 %651, 219
  %653 = icmp eq i32 %645, %652
  br i1 %653, label %697, label %1347

654:                                              ; preds = %972
  store i32 -266830747, ptr %4, align 4
  %655 = xor i32 %1, -24708127
  %656 = and i32 %1, %655
  %657 = or i32 %1, %655
  %658 = xor i32 %1, %655
  %659 = add i32 %656, %657
  %660 = sub i32 %659, %1
  %661 = sub i32 %660, %655
  %662 = mul i32 %661, 149
  %663 = icmp slt i32 %662, 1
  br i1 %663, label %697, label %1357

664:                                              ; preds = %980
  store i32 -244937713, ptr %4, align 4
  %665 = xor i32 %1, 655538487
  %666 = and i32 %1, %665
  %667 = or i32 %1, %665
  %668 = xor i32 %1, %665
  %669 = add i32 %1, %665
  %670 = sub i32 %669, %668
  %671 = mul i32 %666, 2
  %672 = sub i32 %670, %671
  %673 = mul i32 %672, 18
  %674 = icmp uge i32 %673, 0
  br i1 %674, label %697, label %1366

675:                                              ; preds = %954
  store i32 -752609016, ptr %4, align 4
  %676 = xor i32 %1, 248407895
  %677 = and i32 %1, %676
  %678 = or i32 %1, %676
  %679 = xor i32 %1, %676
  %680 = add i32 %1, %676
  %681 = sub i32 %680, %679
  %682 = mul i32 %677, 2
  %683 = sub i32 %681, %682
  %684 = mul i32 %683, 108
  %685 = icmp eq i32 %684, 0
  br i1 %685, label %697, label %1376

686:                                              ; preds = %830
  store i32 1784726114, ptr %4, align 4
  %687 = xor i32 %1, 1070827851
  %688 = and i32 %1, %687
  %689 = or i32 %1, %687
  %690 = xor i32 %1, %687
  %691 = add i32 %688, %689
  %692 = sub i32 %691, %1
  %693 = sub i32 %692, %687
  %694 = mul i32 %693, 180
  %695 = icmp eq i32 %694, 0
  br i1 %695, label %697, label %1386

696:                                              ; preds = %928
  ret void

697:                                              ; preds = %1460, %1453, %1443, %1436, %1427, %1419, %1409, %1401, %1386, %1376, %1366, %1357, %1347, %1337, %1327, %1317, %1308, %1299, %1289, %1282, %1272, %1263, %1256, %1247, %1237, %1228, %1220, %1211, %1204, %1195, %1188, %1180, %1170, %1160, %1151, %1144, %1137, %1129, %1120, %1111, %1102, %1093, %1083, %1076, %1067, %1060, %1053, %1044, %1034, %1024, %1016, %1009, %1000, %991, %982, %789, %778, %767, %754, %743, %732, %721, %709, %686, %675, %664, %654, %636, %616, %605, %587, %568, %557, %547, %528, %517, %506, %492, %481, %467, %449, %425, %416, %401, %389, %375, %362, %348, %330, %315, %302, %288, %276, %263, %251, %237, %224, %209, %199, %186, %173, %153, %140, %125, %104, %91, %79, %54, %42, %15
  br label %10

698:                                              ; preds = %980, %978, %972, %968, %962, %960, %954, %950, %940, %938, %932, %928, %922, %920, %914, %910, %896, %894, %888, %884, %878, %876, %870, %866, %856, %854, %848, %844, %838, %836, %830, %826
  store i32 -18528230, ptr %4, align 4
  call void asm sideeffect "", ""()
  %699 = xor i32 %1, 555903191
  %700 = and i32 %1, %699
  %701 = or i32 %1, %699
  %702 = xor i32 %1, %699
  %703 = mul i32 %701, 2
  %704 = sub i32 %703, %702
  %705 = sub i32 %704, %1
  %706 = sub i32 %705, %699
  %707 = mul i32 %706, 11
  %708 = icmp sgt i32 %707, 0
  br i1 %708, label %1393, label %10

709:                                              ; preds = %886
  %710 = load i32, ptr %4, align 4
  %711 = xor i32 %710, -6457327
  store i32 %711, ptr %4, align 4
  %712 = xor i32 %1, -708314197
  %713 = and i32 %1, %712
  %714 = or i32 %1, %712
  %715 = xor i32 %1, %712
  %716 = add i32 %713, %714
  %717 = sub i32 %716, %1
  %718 = sub i32 %717, %712
  %719 = mul i32 %718, 184
  %720 = icmp slt i32 %719, 0
  br i1 %720, label %1401, label %697

721:                                              ; preds = %970
  %722 = load i32, ptr %4, align 4
  %723 = xor i32 %722, 1838176220
  store i32 %723, ptr %4, align 4
  %724 = xor i32 %1, 1402262607
  %725 = and i32 %1, %724
  %726 = or i32 %1, %724
  %727 = xor i32 %1, %724
  %728 = sub i32 %726, %727
  %729 = sub i32 %728, %725
  %730 = mul i32 %729, 166
  %731 = icmp uge i32 %730, 0
  br i1 %731, label %697, label %1409

732:                                              ; preds = %888
  %733 = load i32, ptr %4, align 4
  %734 = xor i32 %733, 1208763934
  store i32 %734, ptr %4, align 4
  %735 = xor i32 %1, 970895271
  %736 = and i32 %1, %735
  %737 = or i32 %1, %735
  %738 = xor i32 %1, %735
  %739 = sub i32 %737, %738
  %740 = sub i32 %739, %736
  %741 = mul i32 %740, 250
  %742 = icmp eq i32 %741, 0
  br i1 %742, label %697, label %1419

743:                                              ; preds = %834
  %744 = load i32, ptr %4, align 4
  %745 = xor i32 %744, 1170853490
  store i32 %745, ptr %4, align 4
  %746 = xor i32 %1, -573594865
  %747 = and i32 %1, %746
  %748 = or i32 %1, %746
  %749 = xor i32 %1, %746
  %750 = sub i32 %748, %749
  %751 = sub i32 %750, %747
  %752 = mul i32 %751, 25
  %753 = icmp eq i32 %752, 0
  br i1 %753, label %697, label %1427

754:                                              ; preds = %968
  %755 = load i32, ptr %4, align 4
  %756 = xor i32 %755, -375566299
  store i32 %756, ptr %4, align 4
  %757 = xor i32 %1, 234671803
  %758 = and i32 %1, %757
  %759 = or i32 %1, %757
  %760 = xor i32 %1, %757
  %761 = mul i32 %759, 2
  %762 = sub i32 %761, %760
  %763 = sub i32 %762, %1
  %764 = sub i32 %763, %757
  %765 = mul i32 %764, 56
  %766 = icmp uge i32 %765, 0
  br i1 %766, label %697, label %1436

767:                                              ; preds = %838
  %768 = load i32, ptr %4, align 4
  %769 = xor i32 %768, 1584629432
  store i32 %769, ptr %4, align 4
  %770 = xor i32 %1, -1322369685
  %771 = and i32 %1, %770
  %772 = or i32 %1, %770
  %773 = xor i32 %1, %770
  %774 = sub i32 %772, %773
  %775 = sub i32 %774, %771
  %776 = mul i32 %775, 181
  %777 = icmp eq i32 %776, 0
  br i1 %777, label %697, label %1443

778:                                              ; preds = %938
  %779 = load i32, ptr %4, align 4
  %780 = xor i32 %779, 797671119
  store i32 %780, ptr %4, align 4
  %781 = xor i32 %1, 1583481715
  %782 = and i32 %1, %781
  %783 = or i32 %1, %781
  %784 = xor i32 %1, %781
  %785 = sub i32 %783, %784
  %786 = sub i32 %785, %782
  %787 = mul i32 %786, 46
  %788 = icmp eq i32 %787, 0
  br i1 %788, label %697, label %1453

789:                                              ; preds = %910
  %790 = load i32, ptr %4, align 4
  %791 = xor i32 %790, -2099218289
  store i32 %791, ptr %4, align 4
  %792 = xor i32 %1, 1379707099
  %793 = and i32 %1, %792
  %794 = or i32 %1, %792
  %795 = xor i32 %1, %792
  %796 = add i32 %793, %794
  %797 = sub i32 %796, %1
  %798 = sub i32 %797, %792
  %799 = mul i32 %798, 90
  %800 = xor i32 %1, -206025681
  %801 = and i32 %1, %800
  %802 = or i32 %1, %800
  %803 = xor i32 %1, %800
  %804 = add i32 %1, %800
  %805 = sub i32 %804, %803
  %806 = mul i32 %801, 2
  %807 = sub i32 %805, %806
  %808 = mul i32 %807, 102
  %809 = icmp ne i32 %799, %808
  br i1 %809, label %1460, label %697

810:                                              ; preds = %10
  %811 = icmp slt i32 %13, 473556887
  br i1 %811, label %814, label %816

812:                                              ; preds = %10
  %813 = icmp slt i32 %13, 1600459645
  br i1 %813, label %898, label %900

814:                                              ; preds = %810
  %815 = icmp slt i32 %13, 303851520
  br i1 %815, label %818, label %820

816:                                              ; preds = %810
  %817 = icmp slt i32 %13, 930478208
  br i1 %817, label %858, label %860

818:                                              ; preds = %814
  %819 = icmp slt i32 %13, 253406519
  br i1 %819, label %822, label %824

820:                                              ; preds = %814
  %821 = icmp slt i32 %13, 311762497
  br i1 %821, label %840, label %842

822:                                              ; preds = %818
  %823 = icmp slt i32 %13, 74458251
  br i1 %823, label %826, label %828

824:                                              ; preds = %818
  %825 = icmp slt i32 %13, 274921552
  br i1 %825, label %832, label %834

826:                                              ; preds = %822
  %827 = icmp eq i32 %13, 41471634
  br i1 %827, label %481, label %698

828:                                              ; preds = %822
  %829 = icmp eq i32 %13, 74458251
  br i1 %829, label %15, label %830

830:                                              ; preds = %828
  %831 = icmp eq i32 %13, 123960113
  br i1 %831, label %686, label %698

832:                                              ; preds = %824
  %833 = icmp eq i32 %13, 253406519
  br i1 %833, label %104, label %836

834:                                              ; preds = %824
  %835 = icmp eq i32 %13, 274921552
  br i1 %835, label %743, label %838

836:                                              ; preds = %832
  %837 = icmp eq i32 %13, 259579832
  br i1 %837, label %449, label %698

838:                                              ; preds = %834
  %839 = icmp eq i32 %13, 281083196
  br i1 %839, label %767, label %698

840:                                              ; preds = %820
  %841 = icmp slt i32 %13, 304612179
  br i1 %841, label %844, label %846

842:                                              ; preds = %820
  %843 = icmp slt i32 %13, 365890534
  br i1 %843, label %850, label %852

844:                                              ; preds = %840
  %845 = icmp eq i32 %13, 303851520
  br i1 %845, label %362, label %698

846:                                              ; preds = %840
  %847 = icmp eq i32 %13, 304612179
  br i1 %847, label %587, label %848

848:                                              ; preds = %846
  %849 = icmp eq i32 %13, 305550619
  br i1 %849, label %209, label %698

850:                                              ; preds = %842
  %851 = icmp eq i32 %13, 311762497
  br i1 %851, label %616, label %854

852:                                              ; preds = %842
  %853 = icmp eq i32 %13, 365890534
  br i1 %853, label %416, label %856

854:                                              ; preds = %850
  %855 = icmp eq i32 %13, 336284090
  br i1 %855, label %251, label %698

856:                                              ; preds = %852
  %857 = icmp eq i32 %13, 410536205
  br i1 %857, label %302, label %698

858:                                              ; preds = %816
  %859 = icmp slt i32 %13, 717951790
  br i1 %859, label %862, label %864

860:                                              ; preds = %816
  %861 = icmp slt i32 %13, 1064556281
  br i1 %861, label %880, label %882

862:                                              ; preds = %858
  %863 = icmp slt i32 %13, 557378798
  br i1 %863, label %866, label %868

864:                                              ; preds = %858
  %865 = icmp slt i32 %13, 871007070
  br i1 %865, label %872, label %874

866:                                              ; preds = %862
  %867 = icmp eq i32 %13, 473556887
  br i1 %867, label %330, label %698

868:                                              ; preds = %862
  %869 = icmp eq i32 %13, 557378798
  br i1 %869, label %547, label %870

870:                                              ; preds = %868
  %871 = icmp eq i32 %13, 707928450
  br i1 %871, label %153, label %698

872:                                              ; preds = %864
  %873 = icmp eq i32 %13, 717951790
  br i1 %873, label %140, label %876

874:                                              ; preds = %864
  %875 = icmp eq i32 %13, 871007070
  br i1 %875, label %91, label %878

876:                                              ; preds = %872
  %877 = icmp eq i32 %13, 866200268
  br i1 %877, label %636, label %698

878:                                              ; preds = %874
  %879 = icmp eq i32 %13, 910262797
  br i1 %879, label %276, label %698

880:                                              ; preds = %860
  %881 = icmp slt i32 %13, 937056483
  br i1 %881, label %884, label %886

882:                                              ; preds = %860
  %883 = icmp slt i32 %13, 1102418165
  br i1 %883, label %890, label %892

884:                                              ; preds = %880
  %885 = icmp eq i32 %13, 930478208
  br i1 %885, label %199, label %698

886:                                              ; preds = %880
  %887 = icmp eq i32 %13, 937056483
  br i1 %887, label %709, label %888

888:                                              ; preds = %886
  %889 = icmp eq i32 %13, 1061837129
  br i1 %889, label %732, label %698

890:                                              ; preds = %882
  %891 = icmp eq i32 %13, 1064556281
  br i1 %891, label %401, label %894

892:                                              ; preds = %882
  %893 = icmp eq i32 %13, 1102418165
  br i1 %893, label %389, label %896

894:                                              ; preds = %890
  %895 = icmp eq i32 %13, 1101166091
  br i1 %895, label %288, label %698

896:                                              ; preds = %892
  %897 = icmp eq i32 %13, 1113866339
  br i1 %897, label %605, label %698

898:                                              ; preds = %812
  %899 = icmp slt i32 %13, 1525055475
  br i1 %899, label %902, label %904

900:                                              ; preds = %812
  %901 = icmp slt i32 %13, 1808873427
  br i1 %901, label %942, label %944

902:                                              ; preds = %898
  %903 = icmp slt i32 %13, 1380778057
  br i1 %903, label %906, label %908

904:                                              ; preds = %898
  %905 = icmp slt i32 %13, 1560785216
  br i1 %905, label %924, label %926

906:                                              ; preds = %902
  %907 = icmp slt i32 %13, 1278889342
  br i1 %907, label %910, label %912

908:                                              ; preds = %902
  %909 = icmp slt i32 %13, 1516681869
  br i1 %909, label %916, label %918

910:                                              ; preds = %906
  %911 = icmp eq i32 %13, 1152236658
  br i1 %911, label %789, label %698

912:                                              ; preds = %906
  %913 = icmp eq i32 %13, 1278889342
  br i1 %913, label %557, label %914

914:                                              ; preds = %912
  %915 = icmp eq i32 %13, 1338676789
  br i1 %915, label %375, label %698

916:                                              ; preds = %908
  %917 = icmp eq i32 %13, 1380778057
  br i1 %917, label %186, label %920

918:                                              ; preds = %908
  %919 = icmp eq i32 %13, 1516681869
  br i1 %919, label %237, label %922

920:                                              ; preds = %916
  %921 = icmp eq i32 %13, 1476009978
  br i1 %921, label %517, label %698

922:                                              ; preds = %918
  %923 = icmp eq i32 %13, 1524230798
  br i1 %923, label %348, label %698

924:                                              ; preds = %904
  %925 = icmp slt i32 %13, 1531389145
  br i1 %925, label %928, label %930

926:                                              ; preds = %904
  %927 = icmp slt i32 %13, 1583111329
  br i1 %927, label %934, label %936

928:                                              ; preds = %924
  %929 = icmp eq i32 %13, 1525055475
  br i1 %929, label %696, label %698

930:                                              ; preds = %924
  %931 = icmp eq i32 %13, 1531389145
  br i1 %931, label %492, label %932

932:                                              ; preds = %930
  %933 = icmp eq i32 %13, 1534943292
  br i1 %933, label %263, label %698

934:                                              ; preds = %926
  %935 = icmp eq i32 %13, 1560785216
  br i1 %935, label %125, label %938

936:                                              ; preds = %926
  %937 = icmp eq i32 %13, 1583111329
  br i1 %937, label %42, label %940

938:                                              ; preds = %934
  %939 = icmp eq i32 %13, 1574017620
  br i1 %939, label %778, label %698

940:                                              ; preds = %936
  %941 = icmp eq i32 %13, 1584956014
  br i1 %941, label %506, label %698

942:                                              ; preds = %900
  %943 = icmp slt i32 %13, 1685439186
  br i1 %943, label %946, label %948

944:                                              ; preds = %900
  %945 = icmp slt i32 %13, 1899976721
  br i1 %945, label %964, label %966

946:                                              ; preds = %942
  %947 = icmp slt i32 %13, 1605423680
  br i1 %947, label %950, label %952

948:                                              ; preds = %942
  %949 = icmp slt i32 %13, 1785141068
  br i1 %949, label %956, label %958

950:                                              ; preds = %946
  %951 = icmp eq i32 %13, 1600459645
  br i1 %951, label %315, label %698

952:                                              ; preds = %946
  %953 = icmp eq i32 %13, 1605423680
  br i1 %953, label %425, label %954

954:                                              ; preds = %952
  %955 = icmp eq i32 %13, 1610632020
  br i1 %955, label %675, label %698

956:                                              ; preds = %948
  %957 = icmp eq i32 %13, 1685439186
  br i1 %957, label %528, label %960

958:                                              ; preds = %948
  %959 = icmp eq i32 %13, 1785141068
  br i1 %959, label %467, label %962

960:                                              ; preds = %956
  %961 = icmp eq i32 %13, 1722494797
  br i1 %961, label %79, label %698

962:                                              ; preds = %958
  %963 = icmp eq i32 %13, 1793829182
  br i1 %963, label %224, label %698

964:                                              ; preds = %944
  %965 = icmp slt i32 %13, 1832874709
  br i1 %965, label %968, label %970

966:                                              ; preds = %944
  %967 = icmp slt i32 %13, 2060304015
  br i1 %967, label %974, label %976

968:                                              ; preds = %964
  %969 = icmp eq i32 %13, 1808873427
  br i1 %969, label %754, label %698

970:                                              ; preds = %964
  %971 = icmp eq i32 %13, 1832874709
  br i1 %971, label %721, label %972

972:                                              ; preds = %970
  %973 = icmp eq i32 %13, 1882364539
  br i1 %973, label %654, label %698

974:                                              ; preds = %966
  %975 = icmp eq i32 %13, 1899976721
  br i1 %975, label %54, label %978

976:                                              ; preds = %966
  %977 = icmp eq i32 %13, 2060304015
  br i1 %977, label %568, label %980

978:                                              ; preds = %974
  %979 = icmp eq i32 %13, 2047535311
  br i1 %979, label %173, label %698

980:                                              ; preds = %976
  %981 = icmp eq i32 %13, 2115507970
  br i1 %981, label %664, label %698

982:                                              ; preds = %15
  %983 = load i64, ptr %3, align 8
  %984 = ptrtoint ptr %0 to i64
  %985 = zext i32 %1 to i64
  %986 = sub i64 %984, %985
  %987 = sub i64 %986, %985
  %988 = mul i64 %987, %983
  %989 = mul i64 %988, %984
  %990 = sub i64 %989, %985
  store i64 %990, ptr %3, align 8
  br label %697

991:                                              ; preds = %42
  %992 = load i64, ptr %3, align 8
  %993 = ptrtoint ptr %0 to i64
  %994 = zext i32 %1 to i64
  %995 = xor i64 %994, %994
  %996 = or i64 %995, %994
  %997 = and i64 %996, %994
  %998 = add i64 %997, %992
  %999 = or i64 %998, %992
  store i64 %999, ptr %3, align 8
  br label %697

1000:                                             ; preds = %54
  %1001 = load i64, ptr %3, align 8
  %1002 = ptrtoint ptr %0 to i64
  %1003 = zext i32 %1 to i64
  %1004 = add i64 %1001, %1001
  %1005 = add i64 %1004, %1001
  %1006 = add i64 %1005, %1002
  %1007 = and i64 %1006, %1003
  %1008 = mul i64 %1007, %1003
  store i64 %1008, ptr %3, align 8
  br label %697

1009:                                             ; preds = %79
  %1010 = load i64, ptr %3, align 8
  %1011 = ptrtoint ptr %0 to i64
  %1012 = zext i32 %1 to i64
  %1013 = and i64 %1010, %1011
  %1014 = xor i64 %1013, %1010
  %1015 = or i64 %1014, %1010
  store i64 %1015, ptr %3, align 8
  br label %697

1016:                                             ; preds = %91
  %1017 = load i64, ptr %3, align 8
  %1018 = ptrtoint ptr %0 to i64
  %1019 = zext i32 %1 to i64
  %1020 = sub i64 %1018, %1018
  %1021 = mul i64 %1020, %1017
  %1022 = xor i64 %1021, %1018
  %1023 = add i64 %1022, %1019
  store i64 %1023, ptr %3, align 8
  br label %697

1024:                                             ; preds = %104
  %1025 = load i64, ptr %3, align 8
  %1026 = ptrtoint ptr %0 to i64
  %1027 = zext i32 %1 to i64
  %1028 = mul i64 %1027, %1025
  %1029 = or i64 %1028, %1026
  %1030 = add i64 %1029, %1025
  %1031 = mul i64 %1030, %1027
  %1032 = xor i64 %1031, %1027
  %1033 = add i64 %1032, %1026
  store i64 %1033, ptr %3, align 8
  br label %697

1034:                                             ; preds = %125
  %1035 = load i64, ptr %3, align 8
  %1036 = ptrtoint ptr %0 to i64
  %1037 = zext i32 %1 to i64
  %1038 = add i64 %1035, %1036
  %1039 = or i64 %1038, %1036
  %1040 = sub i64 %1039, %1036
  %1041 = xor i64 %1040, %1036
  %1042 = add i64 %1041, %1035
  %1043 = and i64 %1042, %1037
  store i64 %1043, ptr %3, align 8
  br label %697

1044:                                             ; preds = %140
  %1045 = load i64, ptr %3, align 8
  %1046 = ptrtoint ptr %0 to i64
  %1047 = zext i32 %1 to i64
  %1048 = or i64 %1046, %1047
  %1049 = add i64 %1048, %1047
  %1050 = mul i64 %1049, %1046
  %1051 = or i64 %1050, %1045
  %1052 = mul i64 %1051, %1045
  store i64 %1052, ptr %3, align 8
  br label %697

1053:                                             ; preds = %153
  %1054 = load i64, ptr %3, align 8
  %1055 = ptrtoint ptr %0 to i64
  %1056 = zext i32 %1 to i64
  %1057 = xor i64 %1056, %1054
  %1058 = xor i64 %1057, %1055
  %1059 = or i64 %1058, %1056
  store i64 %1059, ptr %3, align 8
  br label %697

1060:                                             ; preds = %173
  %1061 = load i64, ptr %3, align 8
  %1062 = ptrtoint ptr %0 to i64
  %1063 = zext i32 %1 to i64
  %1064 = and i64 %1062, %1063
  %1065 = or i64 %1064, %1063
  %1066 = and i64 %1065, %1061
  store i64 %1066, ptr %3, align 8
  br label %697

1067:                                             ; preds = %186
  %1068 = load i64, ptr %3, align 8
  %1069 = ptrtoint ptr %0 to i64
  %1070 = zext i32 %1 to i64
  %1071 = mul i64 %1070, %1070
  %1072 = sub i64 %1071, %1070
  %1073 = and i64 %1072, %1070
  %1074 = mul i64 %1073, %1069
  %1075 = and i64 %1074, %1069
  store i64 %1075, ptr %3, align 8
  br label %697

1076:                                             ; preds = %199
  %1077 = load i64, ptr %3, align 8
  %1078 = ptrtoint ptr %0 to i64
  %1079 = zext i32 %1 to i64
  %1080 = or i64 %1077, %1077
  %1081 = or i64 %1080, %1078
  %1082 = add i64 %1081, %1078
  store i64 %1082, ptr %3, align 8
  br label %697

1083:                                             ; preds = %209
  %1084 = load i64, ptr %3, align 8
  %1085 = ptrtoint ptr %0 to i64
  %1086 = zext i32 %1 to i64
  %1087 = sub i64 %1085, %1085
  %1088 = add i64 %1087, %1085
  %1089 = and i64 %1088, %1086
  %1090 = xor i64 %1089, %1086
  %1091 = xor i64 %1090, %1085
  %1092 = mul i64 %1091, %1084
  store i64 %1092, ptr %3, align 8
  br label %697

1093:                                             ; preds = %224
  %1094 = load i64, ptr %3, align 8
  %1095 = ptrtoint ptr %0 to i64
  %1096 = zext i32 %1 to i64
  %1097 = sub i64 %1096, %1095
  %1098 = sub i64 %1097, %1096
  %1099 = or i64 %1098, %1094
  %1100 = and i64 %1099, %1096
  %1101 = or i64 %1100, %1096
  store i64 %1101, ptr %3, align 8
  br label %697

1102:                                             ; preds = %237
  %1103 = load i64, ptr %3, align 8
  %1104 = ptrtoint ptr %0 to i64
  %1105 = zext i32 %1 to i64
  %1106 = or i64 %1103, %1103
  %1107 = mul i64 %1106, %1103
  %1108 = mul i64 %1107, %1103
  %1109 = and i64 %1108, %1103
  %1110 = xor i64 %1109, %1105
  store i64 %1110, ptr %3, align 8
  br label %697

1111:                                             ; preds = %251
  %1112 = load i64, ptr %3, align 8
  %1113 = ptrtoint ptr %0 to i64
  %1114 = zext i32 %1 to i64
  %1115 = or i64 %1114, %1114
  %1116 = add i64 %1115, %1113
  %1117 = and i64 %1116, %1113
  %1118 = mul i64 %1117, %1113
  %1119 = mul i64 %1118, %1114
  store i64 %1119, ptr %3, align 8
  br label %697

1120:                                             ; preds = %263
  %1121 = load i64, ptr %3, align 8
  %1122 = ptrtoint ptr %0 to i64
  %1123 = zext i32 %1 to i64
  %1124 = mul i64 %1123, %1123
  %1125 = sub i64 %1124, %1122
  %1126 = mul i64 %1125, %1121
  %1127 = sub i64 %1126, %1123
  %1128 = or i64 %1127, %1122
  store i64 %1128, ptr %3, align 8
  br label %697

1129:                                             ; preds = %276
  %1130 = load i64, ptr %3, align 8
  %1131 = ptrtoint ptr %0 to i64
  %1132 = zext i32 %1 to i64
  %1133 = xor i64 %1131, %1131
  %1134 = sub i64 %1133, %1132
  %1135 = or i64 %1134, %1130
  %1136 = sub i64 %1135, %1132
  store i64 %1136, ptr %3, align 8
  br label %697

1137:                                             ; preds = %288
  %1138 = load i64, ptr %3, align 8
  %1139 = ptrtoint ptr %0 to i64
  %1140 = zext i32 %1 to i64
  %1141 = sub i64 %1139, %1139
  %1142 = add i64 %1141, %1139
  %1143 = sub i64 %1142, %1138
  store i64 %1143, ptr %3, align 8
  br label %697

1144:                                             ; preds = %302
  %1145 = load i64, ptr %3, align 8
  %1146 = ptrtoint ptr %0 to i64
  %1147 = zext i32 %1 to i64
  %1148 = add i64 %1147, %1145
  %1149 = mul i64 %1148, %1146
  %1150 = or i64 %1149, %1147
  store i64 %1150, ptr %3, align 8
  br label %697

1151:                                             ; preds = %315
  %1152 = load i64, ptr %3, align 8
  %1153 = ptrtoint ptr %0 to i64
  %1154 = zext i32 %1 to i64
  %1155 = sub i64 %1153, %1153
  %1156 = or i64 %1155, %1152
  %1157 = add i64 %1156, %1154
  %1158 = or i64 %1157, %1153
  %1159 = xor i64 %1158, %1154
  store i64 %1159, ptr %3, align 8
  br label %697

1160:                                             ; preds = %330
  %1161 = load i64, ptr %3, align 8
  %1162 = ptrtoint ptr %0 to i64
  %1163 = zext i32 %1 to i64
  %1164 = sub i64 %1163, %1162
  %1165 = mul i64 %1164, %1163
  %1166 = sub i64 %1165, %1163
  %1167 = add i64 %1166, %1161
  %1168 = xor i64 %1167, %1163
  %1169 = add i64 %1168, %1161
  store i64 %1169, ptr %3, align 8
  br label %697

1170:                                             ; preds = %348
  %1171 = load i64, ptr %3, align 8
  %1172 = ptrtoint ptr %0 to i64
  %1173 = zext i32 %1 to i64
  %1174 = add i64 %1172, %1172
  %1175 = sub i64 %1174, %1173
  %1176 = or i64 %1175, %1172
  %1177 = add i64 %1176, %1172
  %1178 = sub i64 %1177, %1171
  %1179 = mul i64 %1178, %1171
  store i64 %1179, ptr %3, align 8
  br label %697

1180:                                             ; preds = %362
  %1181 = load i64, ptr %3, align 8
  %1182 = ptrtoint ptr %0 to i64
  %1183 = zext i32 %1 to i64
  %1184 = add i64 %1182, %1182
  %1185 = add i64 %1184, %1183
  %1186 = add i64 %1185, %1182
  %1187 = add i64 %1186, %1181
  store i64 %1187, ptr %3, align 8
  br label %697

1188:                                             ; preds = %375
  %1189 = load i64, ptr %3, align 8
  %1190 = ptrtoint ptr %0 to i64
  %1191 = zext i32 %1 to i64
  %1192 = and i64 %1191, %1189
  %1193 = add i64 %1192, %1189
  %1194 = xor i64 %1193, %1190
  store i64 %1194, ptr %3, align 8
  br label %697

1195:                                             ; preds = %389
  %1196 = load i64, ptr %3, align 8
  %1197 = ptrtoint ptr %0 to i64
  %1198 = zext i32 %1 to i64
  %1199 = mul i64 %1197, %1196
  %1200 = or i64 %1199, %1197
  %1201 = sub i64 %1200, %1196
  %1202 = add i64 %1201, %1198
  %1203 = sub i64 %1202, %1198
  store i64 %1203, ptr %3, align 8
  br label %697

1204:                                             ; preds = %401
  %1205 = load i64, ptr %3, align 8
  %1206 = ptrtoint ptr %0 to i64
  %1207 = zext i32 %1 to i64
  %1208 = sub i64 %1205, %1205
  %1209 = mul i64 %1208, %1207
  %1210 = mul i64 %1209, %1205
  store i64 %1210, ptr %3, align 8
  br label %697

1211:                                             ; preds = %416
  %1212 = load i64, ptr %3, align 8
  %1213 = ptrtoint ptr %0 to i64
  %1214 = zext i32 %1 to i64
  %1215 = or i64 %1212, %1213
  %1216 = sub i64 %1215, %1214
  %1217 = add i64 %1216, %1214
  %1218 = xor i64 %1217, %1214
  %1219 = mul i64 %1218, %1214
  store i64 %1219, ptr %3, align 8
  br label %697

1220:                                             ; preds = %425
  %1221 = load i64, ptr %3, align 8
  %1222 = ptrtoint ptr %0 to i64
  %1223 = zext i32 %1 to i64
  %1224 = xor i64 %1222, %1221
  %1225 = add i64 %1224, %1221
  %1226 = xor i64 %1225, %1223
  %1227 = or i64 %1226, %1221
  store i64 %1227, ptr %3, align 8
  br label %697

1228:                                             ; preds = %449
  %1229 = load i64, ptr %3, align 8
  %1230 = ptrtoint ptr %0 to i64
  %1231 = zext i32 %1 to i64
  %1232 = add i64 %1230, %1230
  %1233 = mul i64 %1232, %1230
  %1234 = sub i64 %1233, %1231
  %1235 = xor i64 %1234, %1231
  %1236 = and i64 %1235, %1230
  store i64 %1236, ptr %3, align 8
  br label %697

1237:                                             ; preds = %467
  %1238 = load i64, ptr %3, align 8
  %1239 = ptrtoint ptr %0 to i64
  %1240 = zext i32 %1 to i64
  %1241 = add i64 %1240, %1240
  %1242 = and i64 %1241, %1239
  %1243 = mul i64 %1242, %1240
  %1244 = or i64 %1243, %1238
  %1245 = mul i64 %1244, %1240
  %1246 = xor i64 %1245, %1238
  store i64 %1246, ptr %3, align 8
  br label %697

1247:                                             ; preds = %481
  %1248 = load i64, ptr %3, align 8
  %1249 = ptrtoint ptr %0 to i64
  %1250 = zext i32 %1 to i64
  %1251 = or i64 %1249, %1248
  %1252 = or i64 %1251, %1248
  %1253 = or i64 %1252, %1250
  %1254 = add i64 %1253, %1248
  %1255 = sub i64 %1254, %1250
  store i64 %1255, ptr %3, align 8
  br label %697

1256:                                             ; preds = %492
  %1257 = load i64, ptr %3, align 8
  %1258 = ptrtoint ptr %0 to i64
  %1259 = zext i32 %1 to i64
  %1260 = xor i64 %1257, %1258
  %1261 = or i64 %1260, %1258
  %1262 = xor i64 %1261, %1257
  store i64 %1262, ptr %3, align 8
  br label %697

1263:                                             ; preds = %506
  %1264 = load i64, ptr %3, align 8
  %1265 = ptrtoint ptr %0 to i64
  %1266 = zext i32 %1 to i64
  %1267 = xor i64 %1265, %1265
  %1268 = or i64 %1267, %1264
  %1269 = xor i64 %1268, %1265
  %1270 = sub i64 %1269, %1266
  %1271 = xor i64 %1270, %1264
  store i64 %1271, ptr %3, align 8
  br label %697

1272:                                             ; preds = %517
  %1273 = load i64, ptr %3, align 8
  %1274 = ptrtoint ptr %0 to i64
  %1275 = zext i32 %1 to i64
  %1276 = sub i64 %1274, %1275
  %1277 = and i64 %1276, %1275
  %1278 = mul i64 %1277, %1274
  %1279 = sub i64 %1278, %1274
  %1280 = add i64 %1279, %1274
  %1281 = and i64 %1280, %1275
  store i64 %1281, ptr %3, align 8
  br label %697

1282:                                             ; preds = %528
  %1283 = load i64, ptr %3, align 8
  %1284 = ptrtoint ptr %0 to i64
  %1285 = zext i32 %1 to i64
  %1286 = sub i64 %1285, %1284
  %1287 = mul i64 %1286, %1283
  %1288 = or i64 %1287, %1285
  store i64 %1288, ptr %3, align 8
  br label %697

1289:                                             ; preds = %547
  %1290 = load i64, ptr %3, align 8
  %1291 = ptrtoint ptr %0 to i64
  %1292 = zext i32 %1 to i64
  %1293 = or i64 %1290, %1292
  %1294 = xor i64 %1293, %1291
  %1295 = add i64 %1294, %1292
  %1296 = mul i64 %1295, %1292
  %1297 = mul i64 %1296, %1290
  %1298 = xor i64 %1297, %1292
  store i64 %1298, ptr %3, align 8
  br label %697

1299:                                             ; preds = %557
  %1300 = load i64, ptr %3, align 8
  %1301 = ptrtoint ptr %0 to i64
  %1302 = zext i32 %1 to i64
  %1303 = or i64 %1301, %1302
  %1304 = and i64 %1303, %1302
  %1305 = or i64 %1304, %1302
  %1306 = and i64 %1305, %1301
  %1307 = or i64 %1306, %1301
  store i64 %1307, ptr %3, align 8
  br label %697

1308:                                             ; preds = %568
  %1309 = load i64, ptr %3, align 8
  %1310 = ptrtoint ptr %0 to i64
  %1311 = zext i32 %1 to i64
  %1312 = xor i64 %1309, %1311
  %1313 = mul i64 %1312, %1310
  %1314 = xor i64 %1313, %1311
  %1315 = add i64 %1314, %1310
  %1316 = sub i64 %1315, %1311
  store i64 %1316, ptr %3, align 8
  br label %697

1317:                                             ; preds = %587
  %1318 = load i64, ptr %3, align 8
  %1319 = ptrtoint ptr %0 to i64
  %1320 = zext i32 %1 to i64
  %1321 = xor i64 %1319, %1318
  %1322 = xor i64 %1321, %1319
  %1323 = xor i64 %1322, %1320
  %1324 = mul i64 %1323, %1320
  %1325 = and i64 %1324, %1319
  %1326 = mul i64 %1325, %1319
  store i64 %1326, ptr %3, align 8
  br label %697

1327:                                             ; preds = %605
  %1328 = load i64, ptr %3, align 8
  %1329 = ptrtoint ptr %0 to i64
  %1330 = zext i32 %1 to i64
  %1331 = and i64 %1330, %1328
  %1332 = mul i64 %1331, %1329
  %1333 = sub i64 %1332, %1329
  %1334 = or i64 %1333, %1329
  %1335 = xor i64 %1334, %1328
  %1336 = or i64 %1335, %1329
  store i64 %1336, ptr %3, align 8
  br label %697

1337:                                             ; preds = %616
  %1338 = load i64, ptr %3, align 8
  %1339 = ptrtoint ptr %0 to i64
  %1340 = zext i32 %1 to i64
  %1341 = mul i64 %1340, %1338
  %1342 = add i64 %1341, %1339
  %1343 = sub i64 %1342, %1338
  %1344 = xor i64 %1343, %1340
  %1345 = or i64 %1344, %1339
  %1346 = mul i64 %1345, %1340
  store i64 %1346, ptr %3, align 8
  br label %697

1347:                                             ; preds = %636
  %1348 = load i64, ptr %3, align 8
  %1349 = ptrtoint ptr %0 to i64
  %1350 = zext i32 %1 to i64
  %1351 = and i64 %1348, %1350
  %1352 = and i64 %1351, %1349
  %1353 = and i64 %1352, %1349
  %1354 = add i64 %1353, %1349
  %1355 = xor i64 %1354, %1348
  %1356 = xor i64 %1355, %1349
  store i64 %1356, ptr %3, align 8
  br label %697

1357:                                             ; preds = %654
  %1358 = load i64, ptr %3, align 8
  %1359 = ptrtoint ptr %0 to i64
  %1360 = zext i32 %1 to i64
  %1361 = xor i64 %1359, %1359
  %1362 = and i64 %1361, %1358
  %1363 = and i64 %1362, %1358
  %1364 = and i64 %1363, %1360
  %1365 = sub i64 %1364, %1360
  store i64 %1365, ptr %3, align 8
  br label %697

1366:                                             ; preds = %664
  %1367 = load i64, ptr %3, align 8
  %1368 = ptrtoint ptr %0 to i64
  %1369 = zext i32 %1 to i64
  %1370 = xor i64 %1367, %1368
  %1371 = and i64 %1370, %1367
  %1372 = or i64 %1371, %1367
  %1373 = and i64 %1372, %1367
  %1374 = xor i64 %1373, %1368
  %1375 = mul i64 %1374, %1367
  store i64 %1375, ptr %3, align 8
  br label %697

1376:                                             ; preds = %675
  %1377 = load i64, ptr %3, align 8
  %1378 = ptrtoint ptr %0 to i64
  %1379 = zext i32 %1 to i64
  %1380 = or i64 %1378, %1377
  %1381 = or i64 %1380, %1378
  %1382 = add i64 %1381, %1377
  %1383 = and i64 %1382, %1379
  %1384 = and i64 %1383, %1378
  %1385 = mul i64 %1384, %1378
  store i64 %1385, ptr %3, align 8
  br label %697

1386:                                             ; preds = %686
  %1387 = load i64, ptr %3, align 8
  %1388 = ptrtoint ptr %0 to i64
  %1389 = zext i32 %1 to i64
  %1390 = xor i64 %1389, %1387
  %1391 = sub i64 %1390, %1388
  %1392 = add i64 %1391, %1387
  store i64 %1392, ptr %3, align 8
  br label %697

1393:                                             ; preds = %698
  %1394 = load i64, ptr %3, align 8
  %1395 = ptrtoint ptr %0 to i64
  %1396 = zext i32 %1 to i64
  %1397 = xor i64 %1395, %1395
  %1398 = add i64 %1397, %1395
  %1399 = and i64 %1398, %1394
  %1400 = and i64 %1399, %1395
  store i64 %1400, ptr %3, align 8
  br label %10

1401:                                             ; preds = %709
  %1402 = load i64, ptr %3, align 8
  %1403 = ptrtoint ptr %0 to i64
  %1404 = zext i32 %1 to i64
  %1405 = sub i64 %1404, %1403
  %1406 = and i64 %1405, %1403
  %1407 = and i64 %1406, %1402
  %1408 = mul i64 %1407, %1403
  store i64 %1408, ptr %3, align 8
  br label %697

1409:                                             ; preds = %721
  %1410 = load i64, ptr %3, align 8
  %1411 = ptrtoint ptr %0 to i64
  %1412 = zext i32 %1 to i64
  %1413 = and i64 %1412, %1412
  %1414 = sub i64 %1413, %1412
  %1415 = mul i64 %1414, %1410
  %1416 = mul i64 %1415, %1410
  %1417 = or i64 %1416, %1410
  %1418 = and i64 %1417, %1411
  store i64 %1418, ptr %3, align 8
  br label %697

1419:                                             ; preds = %732
  %1420 = load i64, ptr %3, align 8
  %1421 = ptrtoint ptr %0 to i64
  %1422 = zext i32 %1 to i64
  %1423 = sub i64 %1422, %1422
  %1424 = mul i64 %1423, %1420
  %1425 = and i64 %1424, %1420
  %1426 = or i64 %1425, %1420
  store i64 %1426, ptr %3, align 8
  br label %697

1427:                                             ; preds = %743
  %1428 = load i64, ptr %3, align 8
  %1429 = ptrtoint ptr %0 to i64
  %1430 = zext i32 %1 to i64
  %1431 = add i64 %1428, %1430
  %1432 = and i64 %1431, %1428
  %1433 = sub i64 %1432, %1430
  %1434 = mul i64 %1433, %1428
  %1435 = sub i64 %1434, %1428
  store i64 %1435, ptr %3, align 8
  br label %697

1436:                                             ; preds = %754
  %1437 = load i64, ptr %3, align 8
  %1438 = ptrtoint ptr %0 to i64
  %1439 = zext i32 %1 to i64
  %1440 = sub i64 %1438, %1439
  %1441 = sub i64 %1440, %1437
  %1442 = and i64 %1441, %1437
  store i64 %1442, ptr %3, align 8
  br label %697

1443:                                             ; preds = %767
  %1444 = load i64, ptr %3, align 8
  %1445 = ptrtoint ptr %0 to i64
  %1446 = zext i32 %1 to i64
  %1447 = sub i64 %1444, %1444
  %1448 = xor i64 %1447, %1444
  %1449 = mul i64 %1448, %1446
  %1450 = add i64 %1449, %1446
  %1451 = sub i64 %1450, %1444
  %1452 = mul i64 %1451, %1445
  store i64 %1452, ptr %3, align 8
  br label %697

1453:                                             ; preds = %778
  %1454 = load i64, ptr %3, align 8
  %1455 = ptrtoint ptr %0 to i64
  %1456 = zext i32 %1 to i64
  %1457 = or i64 %1456, %1455
  %1458 = and i64 %1457, %1456
  %1459 = or i64 %1458, %1455
  store i64 %1459, ptr %3, align 8
  br label %697

1460:                                             ; preds = %789
  %1461 = load i64, ptr %3, align 8
  %1462 = ptrtoint ptr %0 to i64
  %1463 = zext i32 %1 to i64
  %1464 = add i64 %1461, %1461
  %1465 = xor i64 %1464, %1463
  %1466 = and i64 %1465, %1463
  store i64 %1466, ptr %3, align 8
  br label %697
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load volatile i32, ptr @3, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca [2048 x i8], align 16
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 1101127944, ptr %3, align 4
  br label %8

8:                                                ; preds = %355, %179, %178, %0
  %9 = load i32, ptr %3, align 4
  %10 = sub i32 %9, 831149542
  %11 = mul i32 %10, 1659330379
  switch i32 %11, label %179 [
    i32 53829878, label %12
    i32 1719550590, label %26
    i32 1513730073, label %38
    i32 701519069, label %52
    i32 682149400, label %66
    i32 691140036, label %78
    i32 476547856, label %91
    i32 1201001371, label %104
    i32 2061819426, label %128
    i32 795826352, label %140
    i32 1525017635, label %164
    i32 1523121773, label %176
    i32 1533075121, label %190
    i32 1012647748, label %201
    i32 2022638670, label %214
    i32 1540324170, label %226
    i32 2124433898, label %239
    i32 1781945763, label %260
    i32 325376474, label %273
    i32 2082157752, label %286
  ]

12:                                               ; preds = %8
  store i32 0, ptr %4, align 4
  %13 = getelementptr inbounds [2048 x i8], ptr %5, i64 0, i64 0
  %14 = load ptr, ptr @stdin, align 8
  %15 = call ptr @fgets(ptr noundef %13, i32 noundef 2048, ptr noundef %14)
  %16 = icmp ne ptr %15, null
  %17 = select i1 %16, i32 -1414082159, i32 1476503712
  store i32 %17, ptr %3, align 4
  %18 = xor i32 %2, 1815127307
  %19 = and i32 %2, %18
  %20 = or i32 %2, %18
  %21 = xor i32 %2, %18
  %22 = sub i32 %20, %21
  %23 = sub i32 %22, %19
  %24 = mul i32 %23, 161
  %25 = icmp sgt i32 %24, 0
  br i1 %25, label %299, label %178

26:                                               ; preds = %8
  %27 = call i32 (ptr, ...) @printf(ptr noundef @.str.123)
  store i32 0, ptr %4, align 4
  store i32 1887994893, ptr %3, align 4
  %28 = xor i32 %2, 1799515437
  %29 = and i32 %2, %28
  %30 = or i32 %2, %28
  %31 = xor i32 %2, %28
  %32 = mul i32 %30, 2
  %33 = sub i32 %32, %31
  %34 = sub i32 %33, %2
  %35 = sub i32 %34, %28
  %36 = mul i32 %35, 142
  %37 = icmp ugt i32 %36, 0
  br i1 %37, label %304, label %178

38:                                               ; preds = %8
  %39 = getelementptr inbounds [2048 x i8], ptr %5, i64 0, i64 0
  call void @trim(ptr noundef %39)
  %40 = getelementptr inbounds [2048 x i8], ptr %5, i64 0, i64 0
  %41 = call i32 @parseIntStrict(ptr noundef %40, ptr noundef %6)
  %42 = icmp ne i32 %41, 0
  %43 = select i1 %42, i32 599314781, i32 1135321390
  store i32 %43, ptr %3, align 4
  %44 = xor i32 %2, -2095819665
  %45 = and i32 %2, %44
  %46 = or i32 %2, %44
  %47 = xor i32 %2, %44
  %48 = sub i32 %46, %47
  %49 = sub i32 %48, %45
  %50 = mul i32 %49, 155
  %51 = icmp eq i32 %50, 0
  br i1 %51, label %178, label %310

52:                                               ; preds = %8
  %53 = load i32, ptr %6, align 4
  %54 = icmp slt i32 %53, 0
  %55 = select i1 %54, i32 1135321390, i32 1525590194
  store i32 %55, ptr %3, align 4
  %56 = xor i32 %2, 1439435655
  %57 = and i32 %2, %56
  %58 = or i32 %2, %56
  %59 = xor i32 %2, %56
  %60 = add i32 %2, %56
  %61 = sub i32 %60, %59
  %62 = mul i32 %57, 2
  %63 = sub i32 %61, %62
  %64 = mul i32 %63, 225
  %65 = icmp eq i32 %64, 0
  br i1 %65, label %178, label %313

66:                                               ; preds = %8
  %67 = call i32 (ptr, ...) @printf(ptr noundef @.str.124)
  store i32 0, ptr %4, align 4
  store i32 1887994893, ptr %3, align 4
  %68 = xor i32 %2, 313942743
  %69 = and i32 %2, %68
  %70 = or i32 %2, %68
  %71 = xor i32 %2, %68
  %72 = mul i32 %70, 2
  %73 = sub i32 %72, %71
  %74 = sub i32 %73, %2
  %75 = sub i32 %74, %68
  %76 = mul i32 %75, 193
  %77 = icmp slt i32 %76, 1
  br i1 %77, label %178, label %315

78:                                               ; preds = %8
  %79 = load i32, ptr %6, align 4
  %80 = call i32 (ptr, ...) @printf(ptr noundef @.str.125, i32 noundef %79)
  store i32 1, ptr %7, align 4
  store i32 -1794753258, ptr %3, align 4
  %81 = xor i32 %2, -57657535
  %82 = and i32 %2, %81
  %83 = or i32 %2, %81
  %84 = xor i32 %2, %81
  %85 = mul i32 %83, 2
  %86 = sub i32 %85, %84
  %87 = sub i32 %86, %2
  %88 = sub i32 %87, %81
  %89 = mul i32 %88, 44
  %90 = icmp ne i32 %89, 0
  br i1 %90, label %322, label %178

91:                                               ; preds = %8
  %92 = load i32, ptr %7, align 4
  %93 = load i32, ptr %6, align 4
  %94 = icmp sle i32 %92, %93
  %95 = select i1 %94, i32 362868951, i32 -1761018513
  store i32 %95, ptr %3, align 4
  %96 = xor i32 %2, 277217471
  %97 = and i32 %2, %96
  %98 = or i32 %2, %96
  %99 = xor i32 %2, %96
  %100 = sub i32 %98, %99
  %101 = sub i32 %100, %97
  %102 = mul i32 %101, 141
  %103 = icmp ne i32 %102, 0
  br i1 %103, label %328, label %178

104:                                              ; preds = %8
  %105 = getelementptr inbounds [2048 x i8], ptr %5, i64 0, i64 0
  %106 = load ptr, ptr @stdin, align 8
  %107 = call ptr @fgets(ptr noundef %105, i32 noundef 2048, ptr noundef %106)
  %108 = icmp ne ptr %107, null
  %109 = select i1 %108, i32 -1450966538, i32 278389004
  store i32 %109, ptr %3, align 4
  %110 = xor i32 %2, -1191711451
  %111 = and i32 %2, %110
  %112 = or i32 %2, %110
  %113 = xor i32 %2, %110
  %114 = add i32 %2, %110
  %115 = sub i32 %114, %113
  %116 = mul i32 %111, 2
  %117 = sub i32 %115, %116
  %118 = mul i32 %117, 96
  %119 = xor i32 %2, 1965290767
  %120 = and i32 %2, %119
  %121 = or i32 %2, %119
  %122 = xor i32 %2, %119
  %123 = add i32 %120, %121
  %124 = sub i32 %123, %2
  %125 = sub i32 %124, %119
  %126 = mul i32 %125, 144
  %127 = icmp ne i32 %118, %126
  br i1 %127, label %333, label %178

128:                                              ; preds = %8
  %129 = load i32, ptr %7, align 4
  %130 = call i32 (ptr, ...) @printf(ptr noundef @.str.126, i32 noundef %129)
  store i32 -1761018513, ptr %3, align 4
  %131 = xor i32 %2, 613473933
  %132 = and i32 %2, %131
  %133 = or i32 %2, %131
  %134 = xor i32 %2, %131
  %135 = add i32 %132, %133
  %136 = sub i32 %135, %2
  %137 = sub i32 %136, %131
  %138 = mul i32 %137, 254
  %139 = icmp uge i32 %138, 0
  br i1 %139, label %178, label %340

140:                                              ; preds = %8
  %141 = getelementptr inbounds [2048 x i8], ptr %5, i64 0, i64 0
  %142 = load i32, ptr %7, align 4
  call void @handleCommand(ptr noundef %141, i32 noundef %142)
  %143 = load i32, ptr %7, align 4
  %144 = load i32, ptr %3, align 4
  %145 = xor i32 %144, -1450966537
  %146 = sub i32 %143, %145
  %147 = load i32, ptr %3, align 4
  %148 = xor i32 %147, -1450966540
  %149 = mul i32 %143, %148
  %150 = load i32, ptr %3, align 4
  %151 = xor i32 %150, -1450966537
  %152 = mul i32 %151, %146
  %153 = sub i32 %149, %152
  store i32 %153, ptr %7, align 4
  store i32 -1794753258, ptr %3, align 4
  %154 = xor i32 %2, 504377661
  %155 = and i32 %2, %154
  %156 = or i32 %2, %154
  %157 = xor i32 %2, %154
  %158 = add i32 %2, %154
  %159 = sub i32 %158, %157
  %160 = mul i32 %155, 2
  %161 = sub i32 %159, %160
  %162 = mul i32 %161, 225
  %163 = icmp sgt i32 %162, 0
  br i1 %163, label %348, label %178

164:                                              ; preds = %8
  %165 = load i32, ptr @productCount, align 4
  %166 = load i32, ptr @orderCount, align 4
  %167 = call i32 (ptr, ...) @printf(ptr noundef @.str.127, i32 noundef %165, i32 noundef %166)
  store i32 0, ptr %4, align 4
  store i32 1887994893, ptr %3, align 4
  %168 = xor i32 %2, -2101261153
  %169 = and i32 %2, %168
  %170 = or i32 %2, %168
  %171 = xor i32 %2, %168
  %172 = sub i32 %170, %171
  %173 = sub i32 %172, %169
  %174 = mul i32 %173, 198
  %175 = icmp uge i32 %174, 0
  br i1 %175, label %178, label %350

176:                                              ; preds = %8
  %177 = load i32, ptr %4, align 4
  ret i32 %177

178:                                              ; preds = %399, %394, %387, %383, %380, %376, %368, %360, %350, %348, %340, %333, %328, %322, %315, %313, %310, %304, %299, %286, %273, %260, %239, %226, %214, %201, %190, %164, %140, %128, %104, %91, %78, %66, %52, %38, %26, %12
  br label %8

179:                                              ; preds = %8
  store i32 1101127944, ptr %3, align 4
  call void asm sideeffect "", ""()
  %180 = xor i32 %2, -1450244459
  %181 = and i32 %2, %180
  %182 = or i32 %2, %180
  %183 = xor i32 %2, %180
  %184 = add i32 %2, %180
  %185 = sub i32 %184, %183
  %186 = mul i32 %181, 2
  %187 = sub i32 %185, %186
  %188 = mul i32 %187, 213
  %189 = icmp ugt i32 %188, 0
  br i1 %189, label %355, label %8

190:                                              ; preds = %8
  %191 = load i32, ptr %3, align 4
  %192 = xor i32 %191, 237559308
  store i32 %192, ptr %3, align 4
  %193 = xor i32 %2, -501998839
  %194 = and i32 %2, %193
  %195 = or i32 %2, %193
  %196 = xor i32 %2, %193
  %197 = sub i32 %195, %196
  %198 = sub i32 %197, %194
  %199 = mul i32 %198, 122
  %200 = icmp sle i32 %199, 0
  br i1 %200, label %178, label %360

201:                                              ; preds = %8
  %202 = load i32, ptr %3, align 4
  %203 = xor i32 %202, 2138874615
  store i32 %203, ptr %3, align 4
  %204 = xor i32 %2, -640425295
  %205 = and i32 %2, %204
  %206 = or i32 %2, %204
  %207 = xor i32 %2, %204
  %208 = add i32 %2, %204
  %209 = sub i32 %208, %207
  %210 = mul i32 %205, 2
  %211 = sub i32 %209, %210
  %212 = mul i32 %211, 162
  %213 = icmp sle i32 %212, 0
  br i1 %213, label %178, label %368

214:                                              ; preds = %8
  %215 = load i32, ptr %3, align 4
  %216 = xor i32 %215, -601668757
  store i32 %216, ptr %3, align 4
  %217 = xor i32 %2, -106108093
  %218 = and i32 %2, %217
  %219 = or i32 %2, %217
  %220 = xor i32 %2, %217
  %221 = add i32 %218, %219
  %222 = sub i32 %221, %2
  %223 = sub i32 %222, %217
  %224 = mul i32 %223, 159
  %225 = icmp uge i32 %224, 0
  br i1 %225, label %178, label %376

226:                                              ; preds = %8
  %227 = load i32, ptr %3, align 4
  %228 = xor i32 %227, -1530361916
  store i32 %228, ptr %3, align 4
  %229 = xor i32 %2, 678381009
  %230 = and i32 %2, %229
  %231 = or i32 %2, %229
  %232 = xor i32 %2, %229
  %233 = add i32 %2, %229
  %234 = sub i32 %233, %232
  %235 = mul i32 %230, 2
  %236 = sub i32 %234, %235
  %237 = mul i32 %236, 177
  %238 = icmp slt i32 %237, 1
  br i1 %238, label %178, label %380

239:                                              ; preds = %8
  %240 = load i32, ptr %3, align 4
  %241 = xor i32 %240, -2076914957
  store i32 %241, ptr %3, align 4
  %242 = xor i32 %2, -900599421
  %243 = and i32 %2, %242
  %244 = or i32 %2, %242
  %245 = xor i32 %2, %242
  %246 = add i32 %243, %244
  %247 = sub i32 %246, %2
  %248 = sub i32 %247, %242
  %249 = mul i32 %248, 138
  %250 = xor i32 %2, -2011061077
  %251 = and i32 %2, %250
  %252 = or i32 %2, %250
  %253 = xor i32 %2, %250
  %254 = add i32 %2, %250
  %255 = sub i32 %254, %253
  %256 = mul i32 %251, 2
  %257 = sub i32 %255, %256
  %258 = mul i32 %257, 226
  %259 = icmp ne i32 %249, %258
  br i1 %259, label %383, label %178

260:                                              ; preds = %8
  %261 = load i32, ptr %3, align 4
  %262 = xor i32 %261, 166190139
  store i32 %262, ptr %3, align 4
  %263 = xor i32 %2, -2075008181
  %264 = and i32 %2, %263
  %265 = or i32 %2, %263
  %266 = xor i32 %2, %263
  %267 = add i32 %2, %263
  %268 = sub i32 %267, %266
  %269 = mul i32 %264, 2
  %270 = sub i32 %268, %269
  %271 = mul i32 %270, 84
  %272 = icmp eq i32 %271, 0
  br i1 %272, label %178, label %387

273:                                              ; preds = %8
  %274 = load i32, ptr %3, align 4
  %275 = xor i32 %274, -440269798
  store i32 %275, ptr %3, align 4
  %276 = xor i32 %2, -2024003545
  %277 = and i32 %2, %276
  %278 = or i32 %2, %276
  %279 = xor i32 %2, %276
  %280 = mul i32 %278, 2
  %281 = sub i32 %280, %279
  %282 = sub i32 %281, %2
  %283 = sub i32 %282, %276
  %284 = mul i32 %283, 48
  %285 = icmp ne i32 %284, 0
  br i1 %285, label %394, label %178

286:                                              ; preds = %8
  %287 = load i32, ptr %3, align 4
  %288 = xor i32 %287, -811930885
  store i32 %288, ptr %3, align 4
  %289 = xor i32 %2, -1523057063
  %290 = and i32 %2, %289
  %291 = or i32 %2, %289
  %292 = xor i32 %2, %289
  %293 = add i32 %2, %289
  %294 = sub i32 %293, %292
  %295 = mul i32 %290, 2
  %296 = sub i32 %294, %295
  %297 = mul i32 %296, 220
  %298 = icmp uge i32 %297, 0
  br i1 %298, label %178, label %399

299:                                              ; preds = %12
  %300 = load i64, ptr %1, align 8
  %301 = and i64 1057559920, %300
  %302 = xor i64 %301, 1057559920
  %303 = xor i64 %302, 1057559920
  store i64 %303, ptr %1, align 8
  br label %178

304:                                              ; preds = %26
  %305 = load i64, ptr %1, align 8
  %306 = add i64 %305, %305
  %307 = and i64 %306, %305
  %308 = mul i64 %307, 130790708
  %309 = add i64 %308, 755444770
  store i64 %309, ptr %1, align 8
  br label %178

310:                                              ; preds = %38
  %311 = load i64, ptr %1, align 8
  %312 = mul i64 11176838598, %311
  store i64 %312, ptr %1, align 8
  br label %178

313:                                              ; preds = %52
  %314 = load i64, ptr %1, align 8
  store i64 2622144, ptr %1, align 8
  br label %178

315:                                              ; preds = %66
  %316 = load i64, ptr %1, align 8
  %317 = xor i64 %316, 292999435
  %318 = or i64 %317, 292999435
  %319 = mul i64 %318, 2625518618
  %320 = and i64 %319, 292999435
  %321 = and i64 %320, %316
  store i64 %321, ptr %1, align 8
  br label %178

322:                                              ; preds = %78
  %323 = load i64, ptr %1, align 8
  %324 = sub i64 %323, 2423391759
  %325 = xor i64 %324, 1703137882
  %326 = sub i64 %325, %323
  %327 = sub i64 %326, %323
  store i64 %327, ptr %1, align 8
  br label %178

328:                                              ; preds = %91
  %329 = load i64, ptr %1, align 8
  %330 = and i64 2327199713, %329
  %331 = mul i64 %330, 2543036285
  %332 = xor i64 %331, %329
  store i64 %332, ptr %1, align 8
  br label %178

333:                                              ; preds = %104
  %334 = load i64, ptr %1, align 8
  %335 = and i64 %334, 1990092959
  %336 = mul i64 %335, %334
  %337 = and i64 %336, 1990092959
  %338 = add i64 %337, 1990092959
  %339 = sub i64 %338, 1990092959
  store i64 %339, ptr %1, align 8
  br label %178

340:                                              ; preds = %128
  %341 = load i64, ptr %1, align 8
  %342 = sub i64 %341, 4121423430
  %343 = xor i64 %342, 2929569886
  %344 = or i64 %343, %341
  %345 = and i64 %344, %341
  %346 = and i64 %345, 4121423430
  %347 = sub i64 %346, 2929569886
  store i64 %347, ptr %1, align 8
  br label %178

348:                                              ; preds = %140
  %349 = load i64, ptr %1, align 8
  store i64 3460544926357991746, ptr %1, align 8
  br label %178

350:                                              ; preds = %164
  %351 = load i64, ptr %1, align 8
  %352 = add i64 8195, %351
  %353 = xor i64 %352, 2290262059
  %354 = mul i64 %353, 3468399676
  store i64 %354, ptr %1, align 8
  br label %178

355:                                              ; preds = %179
  %356 = load i64, ptr %1, align 8
  %357 = mul i64 %356, 2014071736
  %358 = xor i64 %357, 2014071736
  %359 = add i64 %358, 2208490439
  store i64 %359, ptr %1, align 8
  br label %8

360:                                              ; preds = %190
  %361 = load i64, ptr %1, align 8
  %362 = xor i64 4062062319, %361
  %363 = or i64 %362, %361
  %364 = add i64 %363, 1806257123
  %365 = add i64 %364, 1806257123
  %366 = or i64 %365, 1806257123
  %367 = xor i64 %366, %361
  store i64 %367, ptr %1, align 8
  br label %178

368:                                              ; preds = %201
  %369 = load i64, ptr %1, align 8
  %370 = or i64 3308385831, %369
  %371 = sub i64 %370, 3308385831
  %372 = mul i64 %371, 3308385831
  %373 = xor i64 %372, %369
  %374 = mul i64 %373, %369
  %375 = mul i64 %374, 468285073
  store i64 %375, ptr %1, align 8
  br label %178

376:                                              ; preds = %214
  %377 = load i64, ptr %1, align 8
  %378 = and i64 0, %377
  %379 = xor i64 %378, %377
  store i64 %379, ptr %1, align 8
  br label %178

380:                                              ; preds = %226
  %381 = load i64, ptr %1, align 8
  %382 = and i64 589458274, %381
  store i64 %382, ptr %1, align 8
  br label %178

383:                                              ; preds = %239
  %384 = load i64, ptr %1, align 8
  %385 = mul i64 -7749169206780729268, %384
  %386 = or i64 %385, 3253890534
  store i64 %386, ptr %1, align 8
  br label %178

387:                                              ; preds = %260
  %388 = load i64, ptr %1, align 8
  %389 = xor i64 913521664, %388
  %390 = add i64 %389, %388
  %391 = or i64 %390, 735317335
  %392 = add i64 %391, %388
  %393 = xor i64 %392, 735317335
  store i64 %393, ptr %1, align 8
  br label %178

394:                                              ; preds = %273
  %395 = load i64, ptr %1, align 8
  %396 = add i64 4164619175, %395
  %397 = sub i64 %396, %395
  %398 = xor i64 %397, %395
  store i64 %398, ptr %1, align 8
  br label %178

399:                                              ; preds = %286
  %400 = load i64, ptr %1, align 8
  %401 = add i64 3937818178, %400
  %402 = xor i64 %401, 3937818178
  %403 = or i64 %402, 4012265926
  %404 = or i64 %403, 4012265926
  %405 = or i64 %404, %400
  %406 = xor i64 %405, 3937818178
  store i64 %406, ptr %1, align 8
  br label %178
}

declare ptr @fgets(ptr noundef, i32 noundef, ptr noundef) #4

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+x87,-aes,-amx-avx512,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-f16c,-fma,-fma4,-gfni,-kl,-mmx,-pclmul,-sha,-sha512,-sm3,-sm4,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-widekl,-xop" "tune-cpu"="generic" }
attributes #1 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+x87,-aes,-amx-avx512,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-f16c,-fma,-fma4,-gfni,-kl,-mmx,-pclmul,-sha,-sha512,-sm3,-sm4,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-widekl,-xop" "tune-cpu"="generic" }
attributes #2 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+x87,-aes,-amx-avx512,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-f16c,-fma,-fma4,-gfni,-kl,-mmx,-pclmul,-sha,-sha512,-sm3,-sm4,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-widekl,-xop" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+x87,-aes,-amx-avx512,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-f16c,-fma,-fma4,-gfni,-kl,-mmx,-pclmul,-sha,-sha512,-sm3,-sm4,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-widekl,-xop" "tune-cpu"="generic" }
attributes #5 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+x87,-aes,-amx-avx512,-avx,-avx10.1-256,-avx10.1-512,-avx10.2-256,-avx10.2-512,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-f16c,-fma,-fma4,-gfni,-kl,-mmx,-pclmul,-sha,-sha512,-sm3,-sm4,-sse,-sse2,-sse3,-sse4.1,-sse4.2,-sse4a,-ssse3,-vaes,-vpclmulqdq,-widekl,-xop" "tune-cpu"="generic" }
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

; ModuleID = 'data/obfuscated/smart_shop/clean.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Product = type { i32, [80 x i8], [40 x i8], double, i32, i32, i32 }
%struct.Order = type { i32, [80 x i8], i32, [32 x %struct.OrderItem], double, double, double, double, [16 x i8], [32 x i8] }
%struct.OrderItem = type { i32, [80 x i8], i32, double, double }

@.str = private unnamed_addr constant [35 x i8] c"Loaded %d products and %d orders.\0A\00", align 1
@productCount = internal global i32 0, align 4
@orderCount = internal global i32 0, align 4
@.str.1 = private unnamed_addr constant [20 x i8] c"Data files: %s, %s\0A\00", align 1
@.str.2 = private unnamed_addr constant [12 x i8] c"products.db\00", align 1
@.str.3 = private unnamed_addr constant [10 x i8] c"orders.db\00", align 1
@.str.4 = private unnamed_addr constant [68 x i8] c"No products found. You can seed demo data from main menu option 6.\0A\00", align 1
@.str.5 = private unnamed_addr constant [2 x i8] c"r\00", align 1
@nextProductId = internal global i32 1, align 4
@.str.6 = private unnamed_addr constant [2 x i8] c"|\00", align 1
@products = internal global [500 x %struct.Product] zeroinitializer, align 16
@.str.7 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@nextOrderId = internal global i32 1, align 4
@.str.8 = private unnamed_addr constant [7 x i8] c"ORDER|\00", align 1
@.str.9 = private unnamed_addr constant [6 x i8] c"ITEM|\00", align 1
@.str.10 = private unnamed_addr constant [4 x i8] c"END\00", align 1
@orders = internal global [1000 x %struct.Order] zeroinitializer, align 16
@.str.11 = private unnamed_addr constant [33 x i8] c"\0A===== SMART SHOP MANAGER =====\0A\00", align 1
@.str.12 = private unnamed_addr constant [14 x i8] c"1. Dashboard\0A\00", align 1
@.str.13 = private unnamed_addr constant [13 x i8] c"2. Products\0A\00", align 1
@.str.14 = private unnamed_addr constant [11 x i8] c"3. Orders\0A\00", align 1
@.str.15 = private unnamed_addr constant [12 x i8] c"4. Reports\0A\00", align 1
@.str.16 = private unnamed_addr constant [14 x i8] c"5. Save data\0A\00", align 1
@.str.17 = private unnamed_addr constant [19 x i8] c"6. Seed demo data\0A\00", align 1
@.str.18 = private unnamed_addr constant [17 x i8] c"7. Clear screen\0A\00", align 1
@.str.19 = private unnamed_addr constant [18 x i8] c"0. Save and exit\0A\00", align 1
@.str.20 = private unnamed_addr constant [9 x i8] c"Choose: \00", align 1
@.str.21 = private unnamed_addr constant [6 x i8] c"Bye.\0A\00", align 1
@.str.22 = private unnamed_addr constant [36 x i8] c"[Invalid] Please enter an integer.\0A\00", align 1
@.str.23 = private unnamed_addr constant [44 x i8] c"[Invalid] Value must be between %d and %d.\0A\00", align 1
@.str.24 = private unnamed_addr constant [3 x i8] c"%s\00", align 1
@stdin = external global ptr, align 8
@.str.25 = private unnamed_addr constant [31 x i8] c"[OK] Data saved to %s and %s.\0A\00", align 1
@.str.26 = private unnamed_addr constant [2 x i8] c"w\00", align 1
@.str.27 = private unnamed_addr constant [30 x i8] c"[File error] Cannot write %s\0A\00", align 1
@.str.28 = private unnamed_addr constant [44 x i8] c"# id|name|category|price|stock|sold|active\0A\00", align 1
@.str.29 = private unnamed_addr constant [24 x i8] c"%d|%s|%s|%.2f|%d|%d|%d\0A\00", align 1
@.str.30 = private unnamed_addr constant [76 x i8] c"# ORDER|id|customer|itemCount|subtotal|discount|tax|total|status|createdAt\0A\00", align 1
@.str.31 = private unnamed_addr constant [54 x i8] c"# ITEM|productId|productName|qty|unitPrice|lineTotal\0A\00", align 1
@.str.32 = private unnamed_addr constant [42 x i8] c"ORDER|%d|%s|%d|%.2f|%.2f|%.2f|%.2f|%s|%s\0A\00", align 1
@.str.33 = private unnamed_addr constant [25 x i8] c"ITEM|%d|%s|%d|%.2f|%.2f\0A\00", align 1
@.str.34 = private unnamed_addr constant [5 x i8] c"END\0A\00", align 1
@.str.35 = private unnamed_addr constant [5 x i8] c"PAID\00", align 1
@.str.36 = private unnamed_addr constant [34 x i8] c"\0A========== DASHBOARD ==========\0A\00", align 1
@.str.37 = private unnamed_addr constant [22 x i8] c"Active products : %d\0A\00", align 1
@.str.38 = private unnamed_addr constant [22 x i8] c"Orders          : %d\0A\00", align 1
@.str.39 = private unnamed_addr constant [22 x i8] c"Low stock <= 5  : %d\0A\00", align 1
@.str.40 = private unnamed_addr constant [19 x i8] c"Inventory value : \00", align 1
@.str.41 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1
@.str.42 = private unnamed_addr constant [19 x i8] c"Revenue         : \00", align 1
@.str.43 = private unnamed_addr constant [6 x i8] c"$%.2f\00", align 1
@.str.44 = private unnamed_addr constant [27 x i8] c"\0A===== PRODUCT MENU =====\0A\00", align 1
@.str.45 = private unnamed_addr constant [18 x i8] c"1. List products\0A\00", align 1
@.str.46 = private unnamed_addr constant [16 x i8] c"2. Add product\0A\00", align 1
@.str.47 = private unnamed_addr constant [19 x i8] c"3. Update product\0A\00", align 1
@.str.48 = private unnamed_addr constant [20 x i8] c"4. Restock product\0A\00", align 1
@.str.49 = private unnamed_addr constant [19 x i8] c"5. Delete product\0A\00", align 1
@.str.50 = private unnamed_addr constant [20 x i8] c"6. Search products\0A\00", align 1
@.str.51 = private unnamed_addr constant [18 x i8] c"7. Sort products\0A\00", align 1
@.str.52 = private unnamed_addr constant [9 x i8] c"0. Back\0A\00", align 1
@.str.53 = private unnamed_addr constant [27 x i8] c"No active products found.\0A\00", align 1
@.str.54 = private unnamed_addr constant [86 x i8] c"+------+------------------------------+------------------+----------+-------+------+\0A\00", align 1
@.str.55 = private unnamed_addr constant [86 x i8] c"| ID   | Name                         | Category         | Price    | Stock | Sold |\0A\00", align 1
@.str.56 = private unnamed_addr constant [52 x i8] c"| %-4d | %-28.28s | %-16.16s | %8.2f | %5d | %4d |\0A\00", align 1
@.str.57 = private unnamed_addr constant [45 x i8] c"[Error] Product database is full. Max = %d.\0A\00", align 1
@.str.58 = private unnamed_addr constant [15 x i8] c"Product name: \00", align 1
@.str.59 = private unnamed_addr constant [72 x i8] c"[Duplicate] A product with this name already exists. Try another name.\0A\00", align 1
@.str.60 = private unnamed_addr constant [11 x i8] c"Category: \00", align 1
@.str.61 = private unnamed_addr constant [25 x i8] c"Price [0.01 - 1000000]: \00", align 1
@.str.62 = private unnamed_addr constant [30 x i8] c"Initial stock [0 - 1000000]: \00", align 1
@.str.63 = private unnamed_addr constant [32 x i8] c"[OK] Product added with ID %d.\0A\00", align 1
@.str.64 = private unnamed_addr constant [39 x i8] c"[Invalid] This field cannot be empty.\0A\00", align 1
@.str.65 = private unnamed_addr constant [34 x i8] c"[Invalid] Please enter a number.\0A\00", align 1
@.str.66 = private unnamed_addr constant [48 x i8] c"[Invalid] Value must be between %.2f and %.2f.\0A\00", align 1
@.str.67 = private unnamed_addr constant [24 x i8] c"No products to update.\0A\00", align 1
@.str.68 = private unnamed_addr constant [42 x i8] c"Enter product ID to update, 0 to cancel: \00", align 1
@.str.69 = private unnamed_addr constant [50 x i8] c"[Not found] Active product ID %d does not exist.\0A\00", align 1
@.str.70 = private unnamed_addr constant [14 x i8] c"Updating: %s\0A\00", align 1
@.str.71 = private unnamed_addr constant [37 x i8] c"Leave text empty to keep old value.\0A\00", align 1
@.str.72 = private unnamed_addr constant [11 x i8] c"New name: \00", align 1
@.str.73 = private unnamed_addr constant [50 x i8] c"[Duplicate] Name already exists. Name unchanged.\0A\00", align 1
@.str.74 = private unnamed_addr constant [15 x i8] c"New category: \00", align 1
@.str.75 = private unnamed_addr constant [22 x i8] c"Change price? (y/n): \00", align 1
@.str.76 = private unnamed_addr constant [29 x i8] c"New price [0.01 - 1000000]: \00", align 1
@.str.77 = private unnamed_addr constant [31 x i8] c"Change stock directly? (y/n): \00", align 1
@.str.78 = private unnamed_addr constant [26 x i8] c"New stock [0 - 1000000]: \00", align 1
@.str.79 = private unnamed_addr constant [23 x i8] c"[OK] Product updated.\0A\00", align 1
@.str.80 = private unnamed_addr constant [21 x i8] c"Please type y or n.\0A\00", align 1
@.str.81 = private unnamed_addr constant [25 x i8] c"No products to restock.\0A\00", align 1
@.str.82 = private unnamed_addr constant [37 x i8] c"Product ID to restock, 0 to cancel: \00", align 1
@.str.83 = private unnamed_addr constant [51 x i8] c"[Not found] Product does not exist or is deleted.\0A\00", align 1
@.str.84 = private unnamed_addr constant [30 x i8] c"Amount to add [1 - 1000000]: \00", align 1
@.str.85 = private unnamed_addr constant [73 x i8] c"[Overflow guard] Stock would exceed integer limit. Operation cancelled.\0A\00", align 1
@.str.86 = private unnamed_addr constant [28 x i8] c"[OK] New stock of %s = %d.\0A\00", align 1
@.str.87 = private unnamed_addr constant [24 x i8] c"No products to delete.\0A\00", align 1
@.str.88 = private unnamed_addr constant [36 x i8] c"Product ID to delete, 0 to cancel: \00", align 1
@.str.89 = private unnamed_addr constant [56 x i8] c"[Not found] Product does not exist or already deleted.\0A\00", align 1
@.str.90 = private unnamed_addr constant [99 x i8] c"Note: product appears in existing paid orders. It will be soft-deleted, not removed from history.\0A\00", align 1
@.str.91 = private unnamed_addr constant [22 x i8] c"Are you sure? (y/n): \00", align 1
@.str.92 = private unnamed_addr constant [28 x i8] c"[OK] Product soft-deleted.\0A\00", align 1
@.str.93 = private unnamed_addr constant [24 x i8] c"No products to search.\0A\00", align 1
@.str.94 = private unnamed_addr constant [15 x i8] c"\0ASearch mode:\0A\00", align 1
@.str.95 = private unnamed_addr constant [20 x i8] c"1. By name keyword\0A\00", align 1
@.str.96 = private unnamed_addr constant [24 x i8] c"2. By category keyword\0A\00", align 1
@.str.97 = private unnamed_addr constant [19 x i8] c"3. By price range\0A\00", align 1
@.str.98 = private unnamed_addr constant [24 x i8] c"4. Low stock threshold\0A\00", align 1
@.str.99 = private unnamed_addr constant [15 x i8] c"Name keyword: \00", align 1
@.str.100 = private unnamed_addr constant [19 x i8] c"Category keyword: \00", align 1
@.str.101 = private unnamed_addr constant [12 x i8] c"Min price: \00", align 1
@.str.102 = private unnamed_addr constant [12 x i8] c"Max price: \00", align 1
@.str.103 = private unnamed_addr constant [41 x i8] c"[Notice] Swapped min/max automatically.\0A\00", align 1
@.str.104 = private unnamed_addr constant [29 x i8] c"Show products with stock <= \00", align 1
@.str.105 = private unnamed_addr constant [29 x i8] c"No matching products found.\0A\00", align 1
@.str.106 = private unnamed_addr constant [30 x i8] c"Not enough products to sort.\0A\00", align 1
@.str.107 = private unnamed_addr constant [20 x i8] c"\0ASort products by:\0A\00", align 1
@.str.108 = private unnamed_addr constant [13 x i8] c"1. Name A-Z\0A\00", align 1
@.str.109 = private unnamed_addr constant [19 x i8] c"2. Price low-high\0A\00", align 1
@.str.110 = private unnamed_addr constant [19 x i8] c"3. Stock low-high\0A\00", align 1
@.str.111 = private unnamed_addr constant [18 x i8] c"4. Sold high-low\0A\00", align 1
@.str.112 = private unnamed_addr constant [23 x i8] c"[OK] Products sorted.\0A\00", align 1
@.str.113 = private unnamed_addr constant [25 x i8] c"\0A===== ORDER MENU =====\0A\00", align 1
@.str.114 = private unnamed_addr constant [17 x i8] c"1. Create order\0A\00", align 1
@.str.115 = private unnamed_addr constant [16 x i8] c"2. List orders\0A\00", align 1
@.str.116 = private unnamed_addr constant [22 x i8] c"3. View order detail\0A\00", align 1
@.str.117 = private unnamed_addr constant [17 x i8] c"4. Cancel order\0A\00", align 1
@.str.118 = private unnamed_addr constant [19 x i8] c"5. Export receipt\0A\00", align 1
@.str.119 = private unnamed_addr constant [43 x i8] c"[Error] Order database is full. Max = %d.\0A\00", align 1
@.str.120 = private unnamed_addr constant [42 x i8] c"Cannot create order: no active products.\0A\00", align 1
@.str.121 = private unnamed_addr constant [16 x i8] c"Customer name: \00", align 1
@.str.122 = private unnamed_addr constant [48 x i8] c"\0ADiscount codes: NONE, VIP10, BULK15, FREESHIP\0A\00", align 1
@.str.123 = private unnamed_addr constant [50 x i8] c"Add items to cart. Enter product ID 0 when done.\0A\00", align 1
@.str.124 = private unnamed_addr constant [24 x i8] c"Cart slots used: %d/%d\0A\00", align 1
@.str.125 = private unnamed_addr constant [26 x i8] c"Product ID, 0 to finish: \00", align 1
@.str.126 = private unnamed_addr constant [43 x i8] c"[Not found] Product not found or deleted.\0A\00", align 1
@.str.127 = private unnamed_addr constant [42 x i8] c"[Out of stock] %s currently has 0 stock.\0A\00", align 1
@.str.128 = private unnamed_addr constant [78 x i8] c"[Edge case] You already put all available stock of this product in the cart.\0A\00", align 1
@.str.129 = private unnamed_addr constant [33 x i8] c"Available now for this cart: %d\0A\00", align 1
@.str.130 = private unnamed_addr constant [11 x i8] c"Quantity: \00", align 1
@.str.131 = private unnamed_addr constant [38 x i8] c"[Cart full] Max distinct items = %d.\0A\00", align 1
@.str.132 = private unnamed_addr constant [44 x i8] c"[Cancelled] Empty cart. Order not created.\0A\00", align 1
@.str.133 = private unnamed_addr constant [45 x i8] c"Discount code [NONE/VIP10/BULK15/FREESHIP]: \00", align 1
@.str.134 = private unnamed_addr constant [5 x i8] c"NONE\00", align 1
@.str.135 = private unnamed_addr constant [23 x i8] c"\0AFinal order preview:\0A\00", align 1
@.str.136 = private unnamed_addr constant [11 x i8] c"Discount: \00", align 1
@.str.137 = private unnamed_addr constant [11 x i8] c"Tax     : \00", align 1
@.str.138 = private unnamed_addr constant [11 x i8] c"TOTAL   : \00", align 1
@.str.139 = private unnamed_addr constant [23 x i8] c"Confirm order? (y/n): \00", align 1
@.str.140 = private unnamed_addr constant [32 x i8] c"[Cancelled] Order not created.\0A\00", align 1
@.str.141 = private unnamed_addr constant [67 x i8] c"[Error] Product disappeared before checkout. Operation cancelled.\0A\00", align 1
@.str.142 = private unnamed_addr constant [70 x i8] c"[Error] Stock changed; not enough stock for %s. Operation cancelled.\0A\00", align 1
@.str.143 = private unnamed_addr constant [33 x i8] c"[OK] Order #%d created. Total = \00", align 1
@.str.144 = private unnamed_addr constant [13 x i8] c"unknown-time\00", align 1
@.str.145 = private unnamed_addr constant [18 x i8] c"%Y-%m-%d %H:%M:%S\00", align 1
@.str.146 = private unnamed_addr constant [16 x i8] c"\0ACurrent cart:\0A\00", align 1
@.str.147 = private unnamed_addr constant [75 x i8] c"+------+------------------------------+-------+------------+------------+\0A\00", align 1
@.str.148 = private unnamed_addr constant [75 x i8] c"| PID  | Product                      | Qty   | Unit       | Line       |\0A\00", align 1
@.str.149 = private unnamed_addr constant [45 x i8] c"| %-4d | %-28.28s | %5d | %10.2f | %10.2f |\0A\00", align 1
@.str.150 = private unnamed_addr constant [16 x i8] c"Cart subtotal: \00", align 1
@.str.151 = private unnamed_addr constant [6 x i8] c"VIP10\00", align 1
@.str.152 = private unnamed_addr constant [7 x i8] c"BULK15\00", align 1
@.str.153 = private unnamed_addr constant [65 x i8] c"[Notice] BULK15 requires subtotal >= $500. No discount applied.\0A\00", align 1
@.str.154 = private unnamed_addr constant [9 x i8] c"FREESHIP\00", align 1
@.str.155 = private unnamed_addr constant [64 x i8] c"[Notice] FREESHIP accepted, but this shop has no shipping fee.\0A\00", align 1
@.str.156 = private unnamed_addr constant [54 x i8] c"[Notice] Unknown discount code. No discount applied.\0A\00", align 1
@.str.157 = private unnamed_addr constant [16 x i8] c"No orders yet.\0A\00", align 1
@.str.158 = private unnamed_addr constant [102 x i8] c"+------+----------------------+-------+------------+------------+------------+---------------------+\0A\00", align 1
@.str.159 = private unnamed_addr constant [102 x i8] c"| ID   | Customer             | Items | Subtotal   | Total      | Status     | Created             |\0A\00", align 1
@.str.160 = private unnamed_addr constant [67 x i8] c"| %-4d | %-20.20s | %5d | %10.2f | %10.2f | %-10.10s | %-19.19s |\0A\00", align 1
@.str.161 = private unnamed_addr constant [20 x i8] c"No orders to view.\0A\00", align 1
@.str.162 = private unnamed_addr constant [32 x i8] c"Order ID to view, 0 to cancel: \00", align 1
@.str.163 = private unnamed_addr constant [36 x i8] c"[Not found] Order ID %d not found.\0A\00", align 1
@.str.164 = private unnamed_addr constant [12 x i8] c"\0AORDER #%d\0A\00", align 1
@.str.165 = private unnamed_addr constant [15 x i8] c"Customer : %s\0A\00", align 1
@.str.166 = private unnamed_addr constant [15 x i8] c"Status   : %s\0A\00", align 1
@.str.167 = private unnamed_addr constant [15 x i8] c"Created  : %s\0A\00", align 1
@.str.168 = private unnamed_addr constant [76 x i8] c"\0A+------+------------------------------+-------+------------+------------+\0A\00", align 1
@.str.169 = private unnamed_addr constant [12 x i8] c"Subtotal : \00", align 1
@.str.170 = private unnamed_addr constant [12 x i8] c"Discount : \00", align 1
@.str.171 = private unnamed_addr constant [12 x i8] c"Tax      : \00", align 1
@.str.172 = private unnamed_addr constant [12 x i8] c"Total    : \00", align 1
@.str.173 = private unnamed_addr constant [22 x i8] c"No orders to cancel.\0A\00", align 1
@.str.174 = private unnamed_addr constant [41 x i8] c"Order ID to cancel, 0 to cancel action: \00", align 1
@.str.175 = private unnamed_addr constant [10 x i8] c"CANCELLED\00", align 1
@.str.176 = private unnamed_addr constant [46 x i8] c"[Edge case] This order is already cancelled.\0A\00", align 1
@.str.177 = private unnamed_addr constant [52 x i8] c"Really cancel this order and restore stock? (y/n): \00", align 1
@.str.178 = private unnamed_addr constant [66 x i8] c"[OK] Order cancelled. Stock restored where product still exists.\0A\00", align 1
@.str.179 = private unnamed_addr constant [22 x i8] c"No orders to export.\0A\00", align 1
@.str.180 = private unnamed_addr constant [42 x i8] c"Order ID to export receipt, 0 to cancel: \00", align 1
@.str.181 = private unnamed_addr constant [35 x i8] c"[Not found] Order does not exist.\0A\00", align 1
@.str.182 = private unnamed_addr constant [15 x i8] c"receipt_%d.txt\00", align 1
@.str.183 = private unnamed_addr constant [37 x i8] c"[File error] Cannot create receipt.\0A\00", align 1
@.str.184 = private unnamed_addr constant [20 x i8] c"SMART SHOP RECEIPT\0A\00", align 1
@.str.185 = private unnamed_addr constant [20 x i8] c"==================\0A\00", align 1
@.str.186 = private unnamed_addr constant [15 x i8] c"Order ID : %d\0A\00", align 1
@.str.187 = private unnamed_addr constant [16 x i8] c"Created  : %s\0A\0A\00", align 1
@.str.188 = private unnamed_addr constant [26 x i8] c"%-6s %-30s %6s %12s %12s\0A\00", align 1
@.str.189 = private unnamed_addr constant [4 x i8] c"PID\00", align 1
@.str.190 = private unnamed_addr constant [8 x i8] c"Product\00", align 1
@.str.191 = private unnamed_addr constant [4 x i8] c"Qty\00", align 1
@.str.192 = private unnamed_addr constant [5 x i8] c"Unit\00", align 1
@.str.193 = private unnamed_addr constant [5 x i8] c"Line\00", align 1
@.str.194 = private unnamed_addr constant [33 x i8] c"%-6d %-30.30s %6d %12.2f %12.2f\0A\00", align 1
@.str.195 = private unnamed_addr constant [19 x i8] c"\0ASubtotal : $%.2f\0A\00", align 1
@.str.196 = private unnamed_addr constant [18 x i8] c"Discount : $%.2f\0A\00", align 1
@.str.197 = private unnamed_addr constant [18 x i8] c"Tax      : $%.2f\0A\00", align 1
@.str.198 = private unnamed_addr constant [18 x i8] c"Total    : $%.2f\0A\00", align 1
@.str.199 = private unnamed_addr constant [29 x i8] c"[OK] Receipt exported to %s\0A\00", align 1
@.str.200 = private unnamed_addr constant [22 x i8] c"\0A===== REPORTS =====\0A\00", align 1
@.str.201 = private unnamed_addr constant [19 x i8] c"1. Revenue report\0A\00", align 1
@.str.202 = private unnamed_addr constant [25 x i8] c"2. Top selling products\0A\00", align 1
@.str.203 = private unnamed_addr constant [21 x i8] c"3. Low stock report\0A\00", align 1
@.str.204 = private unnamed_addr constant [20 x i8] c"4. Inventory value\0A\00", align 1
@.str.205 = private unnamed_addr constant [39 x i8] c"\0A========== REVENUE REPORT ==========\0A\00", align 1
@.str.206 = private unnamed_addr constant [22 x i8] c"Paid orders     : %d\0A\00", align 1
@.str.207 = private unnamed_addr constant [22 x i8] c"Cancelled orders: %d\0A\00", align 1
@.str.208 = private unnamed_addr constant [22 x i8] c"Units sold      : %d\0A\00", align 1
@.str.209 = private unnamed_addr constant [19 x i8] c"Gross subtotal  : \00", align 1
@.str.210 = private unnamed_addr constant [19 x i8] c"Discount total  : \00", align 1
@.str.211 = private unnamed_addr constant [19 x i8] c"Tax collected   : \00", align 1
@.str.212 = private unnamed_addr constant [19 x i8] c"Net revenue     : \00", align 1
@.str.213 = private unnamed_addr constant [14 x i8] c"No products.\0A\00", align 1
@.str.214 = private unnamed_addr constant [45 x i8] c"\0A========== TOP SELLING PRODUCTS ==========\0A\00", align 1
@.str.215 = private unnamed_addr constant [22 x i8] c"Low stock threshold: \00", align 1
@.str.216 = private unnamed_addr constant [41 x i8] c"\0A========== LOW STOCK REPORT ==========\0A\00", align 1
@.str.217 = private unnamed_addr constant [39 x i8] c"No products at or below threshold %d.\0A\00", align 1
@.str.218 = private unnamed_addr constant [40 x i8] c"\0A========== INVENTORY VALUE ==========\0A\00", align 1
@.str.219 = private unnamed_addr constant [22 x i8] c"Units in stock  : %d\0A\00", align 1
@.str.220 = private unnamed_addr constant [42 x i8] c"Seed skipped: product list is not empty.\0A\00", align 1
@__const.seedDemoData.demo = private unnamed_addr constant [6 x { i32, [80 x i8], [40 x i8], [4 x i8], double, i32, i32, i32, [4 x i8] }] [{ i32, [80 x i8], [40 x i8], [4 x i8], double, i32, i32, i32, [4 x i8] } { i32 1, [80 x i8] c"Mechanical Keyboard\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [40 x i8] c"Electronics\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [4 x i8] zeroinitializer, double 0x40567F5C28F5C28F, i32 15, i32 0, i32 1, [4 x i8] zeroinitializer }, { i32, [80 x i8], [40 x i8], [4 x i8], double, i32, i32, i32, [4 x i8] } { i32 2, [80 x i8] c"Gaming Mouse\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [40 x i8] c"Electronics\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [4 x i8] zeroinitializer, double 3.950000e+01, i32 25, i32 0, i32 1, [4 x i8] zeroinitializer }, { i32, [80 x i8], [40 x i8], [4 x i8], double, i32, i32, i32, [4 x i8] } { i32 3, [80 x i8] c"USB-C Cable\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [40 x i8] c"Accessories\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [4 x i8] zeroinitializer, double 8.750000e+00, i32 100, i32 0, i32 1, [4 x i8] zeroinitializer }, { i32, [80 x i8], [40 x i8], [4 x i8], double, i32, i32, i32, [4 x i8] } { i32 4, [80 x i8] c"Office Chair\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [40 x i8] c"Furniture\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [4 x i8] zeroinitializer, double 1.290000e+02, i32 7, i32 0, i32 1, [4 x i8] zeroinitializer }, { i32, [80 x i8], [40 x i8], [4 x i8], double, i32, i32, i32, [4 x i8] } { i32 5, [80 x i8] c"Water Bottle\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [40 x i8] c"Lifestyle\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [4 x i8] zeroinitializer, double 1.225000e+01, i32 3, i32 0, i32 1, [4 x i8] zeroinitializer }, { i32, [80 x i8], [40 x i8], [4 x i8], double, i32, i32, i32, [4 x i8] } { i32 6, [80 x i8] c"Notebook A5\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [40 x i8] c"Stationery\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", [4 x i8] zeroinitializer, double 3.400000e+00, i32 60, i32 0, i32 1, [4 x i8] zeroinitializer }], align 16
@.str.221 = private unnamed_addr constant [30 x i8] c"[OK] Demo products inserted.\0A\00", align 1
@.str.222 = private unnamed_addr constant [28 x i8] c"\0APress ENTER to continue...\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  call void @loadAll()
  %2 = load i32, ptr @productCount, align 4
  %3 = load i32, ptr @orderCount, align 4
  %4 = call i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef %2, i32 noundef %3)
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.1, ptr noundef @.str.2, ptr noundef @.str.3)
  %6 = load i32, ptr @productCount, align 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %0
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.4)
  br label %10

10:                                               ; preds = %8, %0
  call void @mainMenu()
  ret i32 0
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @loadAll() #0 {
  call void @loadProducts()
  call void @loadOrders()
  ret void
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal void @mainMenu() #0 {
  %1 = alloca i32, align 4
  br label %2

2:                                                ; preds = %0, %55
  %3 = call i32 (ptr, ...) @printf(ptr noundef @.str.11)
  %4 = call i32 (ptr, ...) @printf(ptr noundef @.str.12)
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.13)
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str.14)
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.15)
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.16)
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.17)
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.18)
  %11 = call i32 (ptr, ...) @printf(ptr noundef @.str.19)
  %12 = call i32 @readIntRange(ptr noundef @.str.20, i32 noundef 0, i32 noundef 7)
  store i32 %12, ptr %1, align 4
  %13 = load i32, ptr %1, align 4
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %17

15:                                               ; preds = %2
  call void @saveAll()
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.21)
  ret void

17:                                               ; preds = %2
  %18 = load i32, ptr %1, align 4
  %19 = icmp eq i32 %18, 1
  br i1 %19, label %20, label %21

20:                                               ; preds = %17
  call void @printDashboard()
  br label %51

21:                                               ; preds = %17
  %22 = load i32, ptr %1, align 4
  %23 = icmp eq i32 %22, 2
  br i1 %23, label %24, label %25

24:                                               ; preds = %21
  call void @productMenu()
  br label %50

25:                                               ; preds = %21
  %26 = load i32, ptr %1, align 4
  %27 = icmp eq i32 %26, 3
  br i1 %27, label %28, label %29

28:                                               ; preds = %25
  call void @orderMenu()
  br label %49

29:                                               ; preds = %25
  %30 = load i32, ptr %1, align 4
  %31 = icmp eq i32 %30, 4
  br i1 %31, label %32, label %33

32:                                               ; preds = %29
  call void @reportsMenu()
  br label %48

33:                                               ; preds = %29
  %34 = load i32, ptr %1, align 4
  %35 = icmp eq i32 %34, 5
  br i1 %35, label %36, label %37

36:                                               ; preds = %33
  call void @saveAll()
  br label %47

37:                                               ; preds = %33
  %38 = load i32, ptr %1, align 4
  %39 = icmp eq i32 %38, 6
  br i1 %39, label %40, label %41

40:                                               ; preds = %37
  call void @seedDemoData()
  br label %46

41:                                               ; preds = %37
  %42 = load i32, ptr %1, align 4
  %43 = icmp eq i32 %42, 7
  br i1 %43, label %44, label %45

44:                                               ; preds = %41
  call void @clearScreen()
  br label %45

45:                                               ; preds = %44, %41
  br label %46

46:                                               ; preds = %45, %40
  br label %47

47:                                               ; preds = %46, %36
  br label %48

48:                                               ; preds = %47, %32
  br label %49

49:                                               ; preds = %48, %28
  br label %50

50:                                               ; preds = %49, %24
  br label %51

51:                                               ; preds = %50, %20
  %52 = load i32, ptr %1, align 4
  %53 = icmp ne i32 %52, 7
  br i1 %53, label %54, label %55

54:                                               ; preds = %51
  call void @pauseEnter()
  br label %55

55:                                               ; preds = %54, %51
  br label %2
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @readIntRange(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca [128 x i8], align 16
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  br label %9

9:                                                ; preds = %3, %15, %25
  %10 = load ptr, ptr %4, align 8
  %11 = getelementptr inbounds [128 x i8], ptr %7, i64 0, i64 0
  call void @readLine(ptr noundef %10, ptr noundef %11, i64 noundef 128)
  %12 = getelementptr inbounds [128 x i8], ptr %7, i64 0, i64 0
  %13 = call i32 @parseIntStrict(ptr noundef %12, ptr noundef %8)
  %14 = icmp ne i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %9
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.22)
  br label %9

17:                                               ; preds = %9
  %18 = load i32, ptr %8, align 4
  %19 = load i32, ptr %5, align 4
  %20 = icmp slt i32 %18, %19
  br i1 %20, label %25, label %21

21:                                               ; preds = %17
  %22 = load i32, ptr %8, align 4
  %23 = load i32, ptr %6, align 4
  %24 = icmp sgt i32 %22, %23
  br i1 %24, label %25, label %29

25:                                               ; preds = %21, %17
  %26 = load i32, ptr %5, align 4
  %27 = load i32, ptr %6, align 4
  %28 = call i32 (ptr, ...) @printf(ptr noundef @.str.23, i32 noundef %26, i32 noundef %27)
  br label %9

29:                                               ; preds = %21
  %30 = load i32, ptr %8, align 4
  ret i32 %30
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @saveAll() #0 {
  call void @saveProducts()
  call void @saveOrders()
  %1 = call i32 (ptr, ...) @printf(ptr noundef @.str.25, ptr noundef @.str.2, ptr noundef @.str.3)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printDashboard() #0 {
  %1 = alloca double, align 8
  %2 = alloca double, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store double 0.000000e+00, ptr %1, align 8
  store double 0.000000e+00, ptr %2, align 8
  store i32 0, ptr %3, align 4
  store i32 0, ptr %4, align 4
  br label %6

6:                                                ; preds = %42, %0
  %7 = load i32, ptr %4, align 4
  %8 = load i32, ptr @productCount, align 4
  %9 = icmp slt i32 %7, %8
  br i1 %9, label %10, label %45

10:                                               ; preds = %6
  %11 = load i32, ptr %4, align 4
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %12
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 6
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %15, 0
  br i1 %16, label %18, label %17

17:                                               ; preds = %10
  br label %42

18:                                               ; preds = %10
  %19 = load i32, ptr %4, align 4
  %20 = sext i32 %19 to i64
  %21 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %20
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 3
  %23 = load double, ptr %22, align 8
  %24 = load i32, ptr %4, align 4
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %25
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 4
  %28 = load i32, ptr %27, align 8
  %29 = sitofp i32 %28 to double
  %30 = load double, ptr %1, align 8
  %31 = call double @llvm.fmuladd.f64(double %23, double %29, double %30)
  store double %31, ptr %1, align 8
  %32 = load i32, ptr %4, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %33
  %35 = getelementptr inbounds nuw %struct.Product, ptr %34, i32 0, i32 4
  %36 = load i32, ptr %35, align 8
  %37 = icmp sle i32 %36, 5
  br i1 %37, label %38, label %41

38:                                               ; preds = %18
  %39 = load i32, ptr %3, align 4
  %40 = add nsw i32 %39, 1
  store i32 %40, ptr %3, align 4
  br label %41

41:                                               ; preds = %38, %18
  br label %42

42:                                               ; preds = %41, %17
  %43 = load i32, ptr %4, align 4
  %44 = add nsw i32 %43, 1
  store i32 %44, ptr %4, align 4
  br label %6, !llvm.loop !6

45:                                               ; preds = %6
  store i32 0, ptr %5, align 4
  br label %46

46:                                               ; preds = %67, %45
  %47 = load i32, ptr %5, align 4
  %48 = load i32, ptr @orderCount, align 4
  %49 = icmp slt i32 %47, %48
  br i1 %49, label %50, label %70

50:                                               ; preds = %46
  %51 = load i32, ptr %5, align 4
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %52
  %54 = getelementptr inbounds nuw %struct.Order, ptr %53, i32 0, i32 8
  %55 = getelementptr inbounds [16 x i8], ptr %54, i64 0, i64 0
  %56 = call i32 @strcmp(ptr noundef %55, ptr noundef @.str.35) #8
  %57 = icmp eq i32 %56, 0
  br i1 %57, label %58, label %66

58:                                               ; preds = %50
  %59 = load i32, ptr %5, align 4
  %60 = sext i32 %59 to i64
  %61 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %60
  %62 = getelementptr inbounds nuw %struct.Order, ptr %61, i32 0, i32 7
  %63 = load double, ptr %62, align 8
  %64 = load double, ptr %2, align 8
  %65 = fadd double %64, %63
  store double %65, ptr %2, align 8
  br label %66

66:                                               ; preds = %58, %50
  br label %67

67:                                               ; preds = %66
  %68 = load i32, ptr %5, align 4
  %69 = add nsw i32 %68, 1
  store i32 %69, ptr %5, align 4
  br label %46, !llvm.loop !8

70:                                               ; preds = %46
  %71 = call i32 (ptr, ...) @printf(ptr noundef @.str.36)
  %72 = call i32 @activeProductCount()
  %73 = call i32 (ptr, ...) @printf(ptr noundef @.str.37, i32 noundef %72)
  %74 = load i32, ptr @orderCount, align 4
  %75 = call i32 (ptr, ...) @printf(ptr noundef @.str.38, i32 noundef %74)
  %76 = load i32, ptr %3, align 4
  %77 = call i32 (ptr, ...) @printf(ptr noundef @.str.39, i32 noundef %76)
  %78 = call i32 (ptr, ...) @printf(ptr noundef @.str.40)
  %79 = load double, ptr %1, align 8
  call void @printMoney(double noundef %79)
  %80 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %81 = call i32 (ptr, ...) @printf(ptr noundef @.str.42)
  %82 = load double, ptr %2, align 8
  call void @printMoney(double noundef %82)
  %83 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @productMenu() #0 {
  %1 = alloca i32, align 4
  br label %2

2:                                                ; preds = %0, %50
  %3 = call i32 (ptr, ...) @printf(ptr noundef @.str.44)
  %4 = call i32 (ptr, ...) @printf(ptr noundef @.str.45)
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.46)
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str.47)
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.48)
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.49)
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.50)
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.51)
  %11 = call i32 (ptr, ...) @printf(ptr noundef @.str.52)
  %12 = call i32 @readIntRange(ptr noundef @.str.20, i32 noundef 0, i32 noundef 7)
  store i32 %12, ptr %1, align 4
  %13 = load i32, ptr %1, align 4
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %16

15:                                               ; preds = %2
  ret void

16:                                               ; preds = %2
  %17 = load i32, ptr %1, align 4
  %18 = icmp eq i32 %17, 1
  br i1 %18, label %19, label %20

19:                                               ; preds = %16
  call void @listProducts()
  br label %50

20:                                               ; preds = %16
  %21 = load i32, ptr %1, align 4
  %22 = icmp eq i32 %21, 2
  br i1 %22, label %23, label %24

23:                                               ; preds = %20
  call void @addProduct()
  br label %49

24:                                               ; preds = %20
  %25 = load i32, ptr %1, align 4
  %26 = icmp eq i32 %25, 3
  br i1 %26, label %27, label %28

27:                                               ; preds = %24
  call void @updateProduct()
  br label %48

28:                                               ; preds = %24
  %29 = load i32, ptr %1, align 4
  %30 = icmp eq i32 %29, 4
  br i1 %30, label %31, label %32

31:                                               ; preds = %28
  call void @restockProduct()
  br label %47

32:                                               ; preds = %28
  %33 = load i32, ptr %1, align 4
  %34 = icmp eq i32 %33, 5
  br i1 %34, label %35, label %36

35:                                               ; preds = %32
  call void @deleteProduct()
  br label %46

36:                                               ; preds = %32
  %37 = load i32, ptr %1, align 4
  %38 = icmp eq i32 %37, 6
  br i1 %38, label %39, label %40

39:                                               ; preds = %36
  call void @searchProducts()
  br label %45

40:                                               ; preds = %36
  %41 = load i32, ptr %1, align 4
  %42 = icmp eq i32 %41, 7
  br i1 %42, label %43, label %44

43:                                               ; preds = %40
  call void @sortProductsMenu()
  br label %44

44:                                               ; preds = %43, %40
  br label %45

45:                                               ; preds = %44, %39
  br label %46

46:                                               ; preds = %45, %35
  br label %47

47:                                               ; preds = %46, %31
  br label %48

48:                                               ; preds = %47, %27
  br label %49

49:                                               ; preds = %48, %23
  br label %50

50:                                               ; preds = %49, %19
  call void @pauseEnter()
  br label %2
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @orderMenu() #0 {
  %1 = alloca i32, align 4
  br label %2

2:                                                ; preds = %0, %38
  %3 = call i32 (ptr, ...) @printf(ptr noundef @.str.113)
  %4 = call i32 (ptr, ...) @printf(ptr noundef @.str.114)
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.115)
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str.116)
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.117)
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.118)
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.52)
  %10 = call i32 @readIntRange(ptr noundef @.str.20, i32 noundef 0, i32 noundef 5)
  store i32 %10, ptr %1, align 4
  %11 = load i32, ptr %1, align 4
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %14

13:                                               ; preds = %2
  ret void

14:                                               ; preds = %2
  %15 = load i32, ptr %1, align 4
  %16 = icmp eq i32 %15, 1
  br i1 %16, label %17, label %18

17:                                               ; preds = %14
  call void @createOrder()
  br label %38

18:                                               ; preds = %14
  %19 = load i32, ptr %1, align 4
  %20 = icmp eq i32 %19, 2
  br i1 %20, label %21, label %22

21:                                               ; preds = %18
  call void @listOrders()
  br label %37

22:                                               ; preds = %18
  %23 = load i32, ptr %1, align 4
  %24 = icmp eq i32 %23, 3
  br i1 %24, label %25, label %26

25:                                               ; preds = %22
  call void @viewOrderDetail()
  br label %36

26:                                               ; preds = %22
  %27 = load i32, ptr %1, align 4
  %28 = icmp eq i32 %27, 4
  br i1 %28, label %29, label %30

29:                                               ; preds = %26
  call void @cancelOrder()
  br label %35

30:                                               ; preds = %26
  %31 = load i32, ptr %1, align 4
  %32 = icmp eq i32 %31, 5
  br i1 %32, label %33, label %34

33:                                               ; preds = %30
  call void @exportReceipt()
  br label %34

34:                                               ; preds = %33, %30
  br label %35

35:                                               ; preds = %34, %29
  br label %36

36:                                               ; preds = %35, %25
  br label %37

37:                                               ; preds = %36, %21
  br label %38

38:                                               ; preds = %37, %17
  call void @pauseEnter()
  br label %2
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @reportsMenu() #0 {
  %1 = alloca i32, align 4
  br label %2

2:                                                ; preds = %0, %28
  %3 = call i32 (ptr, ...) @printf(ptr noundef @.str.200)
  %4 = call i32 (ptr, ...) @printf(ptr noundef @.str.201)
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.202)
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str.203)
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.204)
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.52)
  %9 = call i32 @readIntRange(ptr noundef @.str.20, i32 noundef 0, i32 noundef 4)
  store i32 %9, ptr %1, align 4
  %10 = load i32, ptr %1, align 4
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %13

12:                                               ; preds = %2
  ret void

13:                                               ; preds = %2
  %14 = load i32, ptr %1, align 4
  %15 = icmp eq i32 %14, 1
  br i1 %15, label %16, label %17

16:                                               ; preds = %13
  call void @revenueReport()
  br label %28

17:                                               ; preds = %13
  %18 = load i32, ptr %1, align 4
  %19 = icmp eq i32 %18, 2
  br i1 %19, label %20, label %21

20:                                               ; preds = %17
  call void @topSellingReport()
  br label %27

21:                                               ; preds = %17
  %22 = load i32, ptr %1, align 4
  %23 = icmp eq i32 %22, 3
  br i1 %23, label %24, label %25

24:                                               ; preds = %21
  call void @lowStockReport()
  br label %26

25:                                               ; preds = %21
  call void @inventoryValueReport()
  br label %26

26:                                               ; preds = %25, %24
  br label %27

27:                                               ; preds = %26, %20
  br label %28

28:                                               ; preds = %27, %16
  call void @pauseEnter()
  br label %2
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @seedDemoData() #0 {
  %1 = alloca [6 x %struct.Product], align 16
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = load i32, ptr @productCount, align 4
  %5 = icmp sgt i32 %4, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %0
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.220)
  br label %46

8:                                                ; preds = %0
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %1, ptr align 16 @__const.seedDemoData.demo, i64 912, i1 false)
  store i32 6, ptr %2, align 4
  store i32 0, ptr %3, align 4
  br label %9

9:                                                ; preds = %41, %8
  %10 = load i32, ptr %3, align 4
  %11 = load i32, ptr %2, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %16

13:                                               ; preds = %9
  %14 = load i32, ptr @productCount, align 4
  %15 = icmp slt i32 %14, 500
  br label %16

16:                                               ; preds = %13, %9
  %17 = phi i1 [ false, %9 ], [ %15, %13 ]
  br i1 %17, label %18, label %44

18:                                               ; preds = %16
  %19 = load i32, ptr @productCount, align 4
  %20 = add nsw i32 %19, 1
  store i32 %20, ptr @productCount, align 4
  %21 = sext i32 %19 to i64
  %22 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %21
  %23 = load i32, ptr %3, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds [6 x %struct.Product], ptr %1, i64 0, i64 %24
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %22, ptr align 8 %25, i64 152, i1 false)
  %26 = load i32, ptr %3, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds [6 x %struct.Product], ptr %1, i64 0, i64 %27
  %29 = getelementptr inbounds nuw %struct.Product, ptr %28, i32 0, i32 0
  %30 = load i32, ptr %29, align 8
  %31 = load i32, ptr @nextProductId, align 4
  %32 = icmp sge i32 %30, %31
  br i1 %32, label %33, label %40

33:                                               ; preds = %18
  %34 = load i32, ptr %3, align 4
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds [6 x %struct.Product], ptr %1, i64 0, i64 %35
  %37 = getelementptr inbounds nuw %struct.Product, ptr %36, i32 0, i32 0
  %38 = load i32, ptr %37, align 8
  %39 = add nsw i32 %38, 1
  store i32 %39, ptr @nextProductId, align 4
  br label %40

40:                                               ; preds = %33, %18
  br label %41

41:                                               ; preds = %40
  %42 = load i32, ptr %3, align 4
  %43 = add nsw i32 %42, 1
  store i32 %43, ptr %3, align 4
  br label %9, !llvm.loop !9

44:                                               ; preds = %16
  %45 = call i32 (ptr, ...) @printf(ptr noundef @.str.221)
  br label %46

46:                                               ; preds = %44, %6
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @clearScreen() #0 {
  %1 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %7, %0
  %3 = load i32, ptr %1, align 4
  %4 = icmp slt i32 %3, 30
  br i1 %4, label %5, label %10

5:                                                ; preds = %2
  %6 = call i32 @putchar(i32 noundef 10)
  br label %7

7:                                                ; preds = %5
  %8 = load i32, ptr %1, align 4
  %9 = add nsw i32 %8, 1
  store i32 %9, ptr %1, align 4
  br label %2, !llvm.loop !10

10:                                               ; preds = %2
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @pauseEnter() #0 {
  %1 = alloca [8 x i8], align 1
  %2 = call i32 (ptr, ...) @printf(ptr noundef @.str.222)
  %3 = getelementptr inbounds [8 x i8], ptr %1, i64 0, i64 0
  %4 = load ptr, ptr @stdin, align 8
  %5 = call ptr @fgets(ptr noundef %3, i32 noundef 8, ptr noundef %4)
  ret void
}

declare ptr @fgets(ptr noundef, i32 noundef, ptr noundef) #1

declare i32 @putchar(i32 noundef) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2

; Function Attrs: noinline nounwind optnone uwtable
define internal void @revenueReport() #0 {
  %1 = alloca double, align 8
  %2 = alloca double, align 8
  %3 = alloca double, align 8
  %4 = alloca double, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store double 0.000000e+00, ptr %1, align 8
  store double 0.000000e+00, ptr %2, align 8
  store double 0.000000e+00, ptr %3, align 8
  store double 0.000000e+00, ptr %4, align 8
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %10

10:                                               ; preds = %90, %0
  %11 = load i32, ptr %8, align 4
  %12 = load i32, ptr @orderCount, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %93

14:                                               ; preds = %10
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %16
  %18 = getelementptr inbounds nuw %struct.Order, ptr %17, i32 0, i32 8
  %19 = getelementptr inbounds [16 x i8], ptr %18, i64 0, i64 0
  %20 = call i32 @strcmp(ptr noundef %19, ptr noundef @.str.35) #8
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %22, label %77

22:                                               ; preds = %14
  %23 = load i32, ptr %5, align 4
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %5, align 4
  %25 = load i32, ptr %8, align 4
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %26
  %28 = getelementptr inbounds nuw %struct.Order, ptr %27, i32 0, i32 4
  %29 = load double, ptr %28, align 8
  %30 = load double, ptr %1, align 8
  %31 = fadd double %30, %29
  store double %31, ptr %1, align 8
  %32 = load i32, ptr %8, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %33
  %35 = getelementptr inbounds nuw %struct.Order, ptr %34, i32 0, i32 5
  %36 = load double, ptr %35, align 8
  %37 = load double, ptr %2, align 8
  %38 = fadd double %37, %36
  store double %38, ptr %2, align 8
  %39 = load i32, ptr %8, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %40
  %42 = getelementptr inbounds nuw %struct.Order, ptr %41, i32 0, i32 6
  %43 = load double, ptr %42, align 8
  %44 = load double, ptr %3, align 8
  %45 = fadd double %44, %43
  store double %45, ptr %3, align 8
  %46 = load i32, ptr %8, align 4
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %47
  %49 = getelementptr inbounds nuw %struct.Order, ptr %48, i32 0, i32 7
  %50 = load double, ptr %49, align 8
  %51 = load double, ptr %4, align 8
  %52 = fadd double %51, %50
  store double %52, ptr %4, align 8
  store i32 0, ptr %9, align 4
  br label %53

53:                                               ; preds = %73, %22
  %54 = load i32, ptr %9, align 4
  %55 = load i32, ptr %8, align 4
  %56 = sext i32 %55 to i64
  %57 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %56
  %58 = getelementptr inbounds nuw %struct.Order, ptr %57, i32 0, i32 2
  %59 = load i32, ptr %58, align 4
  %60 = icmp slt i32 %54, %59
  br i1 %60, label %61, label %76

61:                                               ; preds = %53
  %62 = load i32, ptr %8, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %63
  %65 = getelementptr inbounds nuw %struct.Order, ptr %64, i32 0, i32 3
  %66 = load i32, ptr %9, align 4
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds [32 x %struct.OrderItem], ptr %65, i64 0, i64 %67
  %69 = getelementptr inbounds nuw %struct.OrderItem, ptr %68, i32 0, i32 2
  %70 = load i32, ptr %69, align 4
  %71 = load i32, ptr %7, align 4
  %72 = add nsw i32 %71, %70
  store i32 %72, ptr %7, align 4
  br label %73

73:                                               ; preds = %61
  %74 = load i32, ptr %9, align 4
  %75 = add nsw i32 %74, 1
  store i32 %75, ptr %9, align 4
  br label %53, !llvm.loop !11

76:                                               ; preds = %53
  br label %89

77:                                               ; preds = %14
  %78 = load i32, ptr %8, align 4
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %79
  %81 = getelementptr inbounds nuw %struct.Order, ptr %80, i32 0, i32 8
  %82 = getelementptr inbounds [16 x i8], ptr %81, i64 0, i64 0
  %83 = call i32 @strcmp(ptr noundef %82, ptr noundef @.str.175) #8
  %84 = icmp eq i32 %83, 0
  br i1 %84, label %85, label %88

85:                                               ; preds = %77
  %86 = load i32, ptr %6, align 4
  %87 = add nsw i32 %86, 1
  store i32 %87, ptr %6, align 4
  br label %88

88:                                               ; preds = %85, %77
  br label %89

89:                                               ; preds = %88, %76
  br label %90

90:                                               ; preds = %89
  %91 = load i32, ptr %8, align 4
  %92 = add nsw i32 %91, 1
  store i32 %92, ptr %8, align 4
  br label %10, !llvm.loop !12

93:                                               ; preds = %10
  %94 = call i32 (ptr, ...) @printf(ptr noundef @.str.205)
  %95 = load i32, ptr %5, align 4
  %96 = call i32 (ptr, ...) @printf(ptr noundef @.str.206, i32 noundef %95)
  %97 = load i32, ptr %6, align 4
  %98 = call i32 (ptr, ...) @printf(ptr noundef @.str.207, i32 noundef %97)
  %99 = load i32, ptr %7, align 4
  %100 = call i32 (ptr, ...) @printf(ptr noundef @.str.208, i32 noundef %99)
  %101 = call i32 (ptr, ...) @printf(ptr noundef @.str.209)
  %102 = load double, ptr %1, align 8
  call void @printMoney(double noundef %102)
  %103 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %104 = call i32 (ptr, ...) @printf(ptr noundef @.str.210)
  %105 = load double, ptr %2, align 8
  call void @printMoney(double noundef %105)
  %106 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %107 = call i32 (ptr, ...) @printf(ptr noundef @.str.211)
  %108 = load double, ptr %3, align 8
  call void @printMoney(double noundef %108)
  %109 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %110 = call i32 (ptr, ...) @printf(ptr noundef @.str.212)
  %111 = load double, ptr %4, align 8
  call void @printMoney(double noundef %111)
  %112 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @topSellingReport() #0 {
  %1 = alloca [500 x %struct.Product], align 16
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = call i32 @activeProductCount()
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %0
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.213)
  br label %55

9:                                                ; preds = %0
  store i32 0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  br label %10

10:                                               ; preds = %30, %9
  %11 = load i32, ptr %3, align 4
  %12 = load i32, ptr @productCount, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %33

14:                                               ; preds = %10
  %15 = load i32, ptr %3, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %16
  %18 = getelementptr inbounds nuw %struct.Product, ptr %17, i32 0, i32 6
  %19 = load i32, ptr %18, align 8
  %20 = icmp ne i32 %19, 0
  br i1 %20, label %21, label %29

21:                                               ; preds = %14
  %22 = load i32, ptr %2, align 4
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %2, align 4
  %24 = sext i32 %22 to i64
  %25 = getelementptr inbounds [500 x %struct.Product], ptr %1, i64 0, i64 %24
  %26 = load i32, ptr %3, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %27
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %25, ptr align 8 %28, i64 152, i1 false)
  br label %29

29:                                               ; preds = %21, %14
  br label %30

30:                                               ; preds = %29
  %31 = load i32, ptr %3, align 4
  %32 = add nsw i32 %31, 1
  store i32 %32, ptr %3, align 4
  br label %10, !llvm.loop !13

33:                                               ; preds = %10
  %34 = getelementptr inbounds [500 x %struct.Product], ptr %1, i64 0, i64 0
  %35 = load i32, ptr %2, align 4
  %36 = sext i32 %35 to i64
  call void @qsort(ptr noundef %34, i64 noundef %36, i64 noundef 152, ptr noundef @cmpProductSoldDesc)
  %37 = call i32 (ptr, ...) @printf(ptr noundef @.str.214)
  call void @printProductHeader()
  store i32 0, ptr %4, align 4
  br label %38

38:                                               ; preds = %51, %33
  %39 = load i32, ptr %4, align 4
  %40 = load i32, ptr %2, align 4
  %41 = icmp slt i32 %39, %40
  br i1 %41, label %42, label %45

42:                                               ; preds = %38
  %43 = load i32, ptr %4, align 4
  %44 = icmp slt i32 %43, 10
  br label %45

45:                                               ; preds = %42, %38
  %46 = phi i1 [ false, %38 ], [ %44, %42 ]
  br i1 %46, label %47, label %54

47:                                               ; preds = %45
  %48 = load i32, ptr %4, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds [500 x %struct.Product], ptr %1, i64 0, i64 %49
  call void @printProductRow(ptr noundef %50)
  br label %51

51:                                               ; preds = %47
  %52 = load i32, ptr %4, align 4
  %53 = add nsw i32 %52, 1
  store i32 %53, ptr %4, align 4
  br label %38, !llvm.loop !14

54:                                               ; preds = %45
  call void @printProductFooter()
  br label %55

55:                                               ; preds = %54, %7
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @lowStockReport() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = call i32 @readIntRange(ptr noundef @.str.215, i32 noundef 0, i32 noundef 1000000)
  store i32 %4, ptr %1, align 4
  store i32 0, ptr %2, align 4
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.216)
  call void @printProductHeader()
  store i32 0, ptr %3, align 4
  br label %6

6:                                                ; preds = %30, %0
  %7 = load i32, ptr %3, align 4
  %8 = load i32, ptr @productCount, align 4
  %9 = icmp slt i32 %7, %8
  br i1 %9, label %10, label %33

10:                                               ; preds = %6
  %11 = load i32, ptr %3, align 4
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %12
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 6
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %15, 0
  br i1 %16, label %17, label %29

17:                                               ; preds = %10
  %18 = load i32, ptr %3, align 4
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %19
  %21 = getelementptr inbounds nuw %struct.Product, ptr %20, i32 0, i32 4
  %22 = load i32, ptr %21, align 8
  %23 = load i32, ptr %1, align 4
  %24 = icmp sle i32 %22, %23
  br i1 %24, label %25, label %29

25:                                               ; preds = %17
  %26 = load i32, ptr %3, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %27
  call void @printProductRow(ptr noundef %28)
  store i32 1, ptr %2, align 4
  br label %29

29:                                               ; preds = %25, %17, %10
  br label %30

30:                                               ; preds = %29
  %31 = load i32, ptr %3, align 4
  %32 = add nsw i32 %31, 1
  store i32 %32, ptr %3, align 4
  br label %6, !llvm.loop !15

33:                                               ; preds = %6
  call void @printProductFooter()
  %34 = load i32, ptr %2, align 4
  %35 = icmp ne i32 %34, 0
  br i1 %35, label %39, label %36

36:                                               ; preds = %33
  %37 = load i32, ptr %1, align 4
  %38 = call i32 (ptr, ...) @printf(ptr noundef @.str.217, i32 noundef %37)
  br label %39

39:                                               ; preds = %36, %33
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @inventoryValueReport() #0 {
  %1 = alloca double, align 8
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store double 0.000000e+00, ptr %1, align 8
  store i32 0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %37, %0
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr @productCount, align 4
  %7 = icmp slt i32 %5, %6
  br i1 %7, label %8, label %40

8:                                                ; preds = %4
  %9 = load i32, ptr %3, align 4
  %10 = sext i32 %9 to i64
  %11 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %10
  %12 = getelementptr inbounds nuw %struct.Product, ptr %11, i32 0, i32 6
  %13 = load i32, ptr %12, align 8
  %14 = icmp ne i32 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %8
  br label %37

16:                                               ; preds = %8
  %17 = load i32, ptr %3, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %18
  %20 = getelementptr inbounds nuw %struct.Product, ptr %19, i32 0, i32 3
  %21 = load double, ptr %20, align 8
  %22 = load i32, ptr %3, align 4
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %23
  %25 = getelementptr inbounds nuw %struct.Product, ptr %24, i32 0, i32 4
  %26 = load i32, ptr %25, align 8
  %27 = sitofp i32 %26 to double
  %28 = load double, ptr %1, align 8
  %29 = call double @llvm.fmuladd.f64(double %21, double %27, double %28)
  store double %29, ptr %1, align 8
  %30 = load i32, ptr %3, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %31
  %33 = getelementptr inbounds nuw %struct.Product, ptr %32, i32 0, i32 4
  %34 = load i32, ptr %33, align 8
  %35 = load i32, ptr %2, align 4
  %36 = add nsw i32 %35, %34
  store i32 %36, ptr %2, align 4
  br label %37

37:                                               ; preds = %16, %15
  %38 = load i32, ptr %3, align 4
  %39 = add nsw i32 %38, 1
  store i32 %39, ptr %3, align 4
  br label %4, !llvm.loop !16

40:                                               ; preds = %4
  %41 = call i32 (ptr, ...) @printf(ptr noundef @.str.218)
  %42 = call i32 @activeProductCount()
  %43 = call i32 (ptr, ...) @printf(ptr noundef @.str.37, i32 noundef %42)
  %44 = load i32, ptr %2, align 4
  %45 = call i32 (ptr, ...) @printf(ptr noundef @.str.219, i32 noundef %44)
  %46 = call i32 (ptr, ...) @printf(ptr noundef @.str.40)
  %47 = load double, ptr %1, align 8
  call void @printMoney(double noundef %47)
  %48 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @activeProductCount() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  store i32 0, ptr %1, align 4
  store i32 0, ptr %2, align 4
  br label %3

3:                                                ; preds = %18, %0
  %4 = load i32, ptr %2, align 4
  %5 = load i32, ptr @productCount, align 4
  %6 = icmp slt i32 %4, %5
  br i1 %6, label %7, label %21

7:                                                ; preds = %3
  %8 = load i32, ptr %2, align 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %9
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %14, label %17

14:                                               ; preds = %7
  %15 = load i32, ptr %1, align 4
  %16 = add nsw i32 %15, 1
  store i32 %16, ptr %1, align 4
  br label %17

17:                                               ; preds = %14, %7
  br label %18

18:                                               ; preds = %17
  %19 = load i32, ptr %2, align 4
  %20 = add nsw i32 %19, 1
  store i32 %20, ptr %2, align 4
  br label %3, !llvm.loop !17

21:                                               ; preds = %3
  %22 = load i32, ptr %1, align 4
  ret i32 %22
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printMoney(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8
  %3 = load double, ptr %2, align 8
  %4 = call i32 (ptr, ...) @printf(ptr noundef @.str.43, double noundef %3)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printProductHeader() #0 {
  %1 = call i32 (ptr, ...) @printf(ptr noundef @.str.54)
  %2 = call i32 (ptr, ...) @printf(ptr noundef @.str.55)
  %3 = call i32 (ptr, ...) @printf(ptr noundef @.str.54)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printProductRow(ptr noundef %0) #0 {
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
  %11 = getelementptr inbounds [40 x i8], ptr %10, i64 0, i64 0
  %12 = load ptr, ptr %2, align 8
  %13 = getelementptr inbounds nuw %struct.Product, ptr %12, i32 0, i32 3
  %14 = load double, ptr %13, align 8
  %15 = load ptr, ptr %2, align 8
  %16 = getelementptr inbounds nuw %struct.Product, ptr %15, i32 0, i32 4
  %17 = load i32, ptr %16, align 8
  %18 = load ptr, ptr %2, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 5
  %20 = load i32, ptr %19, align 4
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.56, i32 noundef %5, ptr noundef %8, ptr noundef %11, double noundef %14, i32 noundef %17, i32 noundef %20)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printProductFooter() #0 {
  %1 = call i32 (ptr, ...) @printf(ptr noundef @.str.54)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @cmpProductSoldDesc(ptr noundef %0, ptr noundef %1) #0 {
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
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 5
  %12 = load i32, ptr %11, align 4
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 5
  %15 = load i32, ptr %14, align 4
  %16 = icmp ne i32 %12, %15
  br i1 %16, label %17, label %25

17:                                               ; preds = %2
  %18 = load ptr, ptr %7, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 5
  %20 = load i32, ptr %19, align 4
  %21 = load ptr, ptr %6, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 5
  %23 = load i32, ptr %22, align 4
  %24 = sub nsw i32 %20, %23
  store i32 %24, ptr %3, align 4
  br label %33

25:                                               ; preds = %2
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 0
  %28 = load i32, ptr %27, align 8
  %29 = load ptr, ptr %7, align 8
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 0
  %31 = load i32, ptr %30, align 8
  %32 = sub nsw i32 %28, %31
  store i32 %32, ptr %3, align 4
  br label %33

33:                                               ; preds = %25, %17
  %34 = load i32, ptr %3, align 4
  ret i32 %34
}

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define internal void @createOrder() #0 {
  %1 = alloca %struct.Order, align 8
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca [32 x i8], align 16
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = load i32, ptr @orderCount, align 4
  %15 = icmp sge i32 %14, 1000
  br i1 %15, label %16, label %18

16:                                               ; preds = %0
  %17 = call i32 (ptr, ...) @printf(ptr noundef @.str.119, i32 noundef 1000)
  br label %292

18:                                               ; preds = %0
  %19 = call i32 @activeProductCount()
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %21, label %23

21:                                               ; preds = %18
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.120)
  br label %292

23:                                               ; preds = %18
  call void @llvm.memset.p0.i64(ptr align 8 %1, i8 0, i64 3496, i1 false)
  %24 = load i32, ptr @nextOrderId, align 4
  %25 = add nsw i32 %24, 1
  store i32 %25, ptr @nextOrderId, align 4
  %26 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 0
  store i32 %24, ptr %26, align 8
  %27 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 8
  %28 = getelementptr inbounds [16 x i8], ptr %27, i64 0, i64 0
  call void @safeCopy(ptr noundef %28, ptr noundef @.str.35, i64 noundef 16)
  %29 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 9
  %30 = getelementptr inbounds [32 x i8], ptr %29, i64 0, i64 0
  call void @nowString(ptr noundef %30, i64 noundef 32)
  %31 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 1
  %32 = getelementptr inbounds [80 x i8], ptr %31, i64 0, i64 0
  call void @readNonEmptyString(ptr noundef @.str.121, ptr noundef %32, i64 noundef 80)
  %33 = call i32 (ptr, ...) @printf(ptr noundef @.str.122)
  %34 = call i32 (ptr, ...) @printf(ptr noundef @.str.123)
  br label %35

35:                                               ; preds = %23, %48, %58, %79, %92, %94
  call void @listProducts()
  %36 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %37 = load i32, ptr %36, align 4
  %38 = call i32 (ptr, ...) @printf(ptr noundef @.str.124, i32 noundef %37, i32 noundef 32)
  %39 = call i32 @readIntRange(ptr noundef @.str.125, i32 noundef 0, i32 noundef 2147483647)
  store i32 %39, ptr %2, align 4
  %40 = load i32, ptr %2, align 4
  %41 = icmp eq i32 %40, 0
  br i1 %41, label %42, label %43

42:                                               ; preds = %35
  br label %104

43:                                               ; preds = %35
  %44 = load i32, ptr %2, align 4
  %45 = call i32 @findActiveProductIndexById(i32 noundef %44)
  store i32 %45, ptr %3, align 4
  %46 = load i32, ptr %3, align 4
  %47 = icmp slt i32 %46, 0
  br i1 %47, label %48, label %50

48:                                               ; preds = %43
  %49 = call i32 (ptr, ...) @printf(ptr noundef @.str.126)
  br label %35

50:                                               ; preds = %43
  %51 = load i32, ptr %3, align 4
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %52
  store ptr %53, ptr %4, align 8
  %54 = load ptr, ptr %4, align 8
  %55 = getelementptr inbounds nuw %struct.Product, ptr %54, i32 0, i32 4
  %56 = load i32, ptr %55, align 8
  %57 = icmp sle i32 %56, 0
  br i1 %57, label %58, label %63

58:                                               ; preds = %50
  %59 = load ptr, ptr %4, align 8
  %60 = getelementptr inbounds nuw %struct.Product, ptr %59, i32 0, i32 1
  %61 = getelementptr inbounds [80 x i8], ptr %60, i64 0, i64 0
  %62 = call i32 (ptr, ...) @printf(ptr noundef @.str.127, ptr noundef %61)
  br label %35

63:                                               ; preds = %50
  %64 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %65 = getelementptr inbounds [32 x %struct.OrderItem], ptr %64, i64 0, i64 0
  %66 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %67 = load i32, ptr %66, align 4
  %68 = load ptr, ptr %4, align 8
  %69 = getelementptr inbounds nuw %struct.Product, ptr %68, i32 0, i32 0
  %70 = load i32, ptr %69, align 8
  %71 = call i32 @getTempQtyForProduct(ptr noundef %65, i32 noundef %67, i32 noundef %70)
  store i32 %71, ptr %5, align 4
  %72 = load ptr, ptr %4, align 8
  %73 = getelementptr inbounds nuw %struct.Product, ptr %72, i32 0, i32 4
  %74 = load i32, ptr %73, align 8
  %75 = load i32, ptr %5, align 4
  %76 = sub nsw i32 %74, %75
  store i32 %76, ptr %6, align 4
  %77 = load i32, ptr %6, align 4
  %78 = icmp sle i32 %77, 0
  br i1 %78, label %79, label %81

79:                                               ; preds = %63
  %80 = call i32 (ptr, ...) @printf(ptr noundef @.str.128)
  br label %35

81:                                               ; preds = %63
  %82 = load i32, ptr %6, align 4
  %83 = call i32 (ptr, ...) @printf(ptr noundef @.str.129, i32 noundef %82)
  %84 = load i32, ptr %6, align 4
  %85 = call i32 @readIntRange(ptr noundef @.str.130, i32 noundef 1, i32 noundef %84)
  store i32 %85, ptr %7, align 4
  %86 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %87 = load i32, ptr %86, align 4
  %88 = icmp sge i32 %87, 32
  br i1 %88, label %89, label %94

89:                                               ; preds = %81
  %90 = load i32, ptr %5, align 4
  %91 = icmp eq i32 %90, 0
  br i1 %91, label %92, label %94

92:                                               ; preds = %89
  %93 = call i32 (ptr, ...) @printf(ptr noundef @.str.131, i32 noundef 32)
  br label %35

94:                                               ; preds = %89, %81
  %95 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %96 = getelementptr inbounds [32 x %struct.OrderItem], ptr %95, i64 0, i64 0
  %97 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %98 = load ptr, ptr %4, align 8
  %99 = load i32, ptr %7, align 4
  call void @mergeCartItem(ptr noundef %96, ptr noundef %97, ptr noundef %98, i32 noundef %99)
  %100 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %101 = getelementptr inbounds [32 x %struct.OrderItem], ptr %100, i64 0, i64 0
  %102 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %103 = load i32, ptr %102, align 4
  call void @printCart(ptr noundef %101, i32 noundef %103)
  br label %35

104:                                              ; preds = %42
  %105 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %106 = load i32, ptr %105, align 4
  %107 = icmp eq i32 %106, 0
  br i1 %107, label %108, label %112

108:                                              ; preds = %104
  %109 = call i32 (ptr, ...) @printf(ptr noundef @.str.132)
  %110 = load i32, ptr @nextOrderId, align 4
  %111 = add nsw i32 %110, -1
  store i32 %111, ptr @nextOrderId, align 4
  br label %292

112:                                              ; preds = %104
  store i32 0, ptr %8, align 4
  br label %113

113:                                              ; preds = %128, %112
  %114 = load i32, ptr %8, align 4
  %115 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %116 = load i32, ptr %115, align 4
  %117 = icmp slt i32 %114, %116
  br i1 %117, label %118, label %131

118:                                              ; preds = %113
  %119 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %120 = load i32, ptr %8, align 4
  %121 = sext i32 %120 to i64
  %122 = getelementptr inbounds [32 x %struct.OrderItem], ptr %119, i64 0, i64 %121
  %123 = getelementptr inbounds nuw %struct.OrderItem, ptr %122, i32 0, i32 4
  %124 = load double, ptr %123, align 8
  %125 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 4
  %126 = load double, ptr %125, align 8
  %127 = fadd double %126, %124
  store double %127, ptr %125, align 8
  br label %128

128:                                              ; preds = %118
  %129 = load i32, ptr %8, align 4
  %130 = add nsw i32 %129, 1
  store i32 %130, ptr %8, align 4
  br label %113, !llvm.loop !18

131:                                              ; preds = %113
  %132 = getelementptr inbounds [32 x i8], ptr %9, i64 0, i64 0
  call void @readLine(ptr noundef @.str.133, ptr noundef %132, i64 noundef 32)
  %133 = getelementptr inbounds [32 x i8], ptr %9, i64 0, i64 0
  call void @sanitizeField(ptr noundef %133)
  %134 = getelementptr inbounds [32 x i8], ptr %9, i64 0, i64 0
  %135 = call i64 @strlen(ptr noundef %134) #8
  %136 = icmp eq i64 %135, 0
  br i1 %136, label %137, label %139

137:                                              ; preds = %131
  %138 = getelementptr inbounds [32 x i8], ptr %9, i64 0, i64 0
  call void @safeCopy(ptr noundef %138, ptr noundef @.str.134, i64 noundef 32)
  br label %139

139:                                              ; preds = %137, %131
  %140 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 4
  %141 = load double, ptr %140, align 8
  %142 = getelementptr inbounds [32 x i8], ptr %9, i64 0, i64 0
  %143 = call double @calculateDiscount(double noundef %141, ptr noundef %142)
  %144 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 5
  store double %143, ptr %144, align 8
  %145 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 5
  %146 = load double, ptr %145, align 8
  %147 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 4
  %148 = load double, ptr %147, align 8
  %149 = fcmp ogt double %146, %148
  br i1 %149, label %150, label %154

150:                                              ; preds = %139
  %151 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 4
  %152 = load double, ptr %151, align 8
  %153 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 5
  store double %152, ptr %153, align 8
  br label %154

154:                                              ; preds = %150, %139
  %155 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 4
  %156 = load double, ptr %155, align 8
  %157 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 5
  %158 = load double, ptr %157, align 8
  %159 = fsub double %156, %158
  %160 = fmul double %159, 8.000000e-02
  %161 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 6
  store double %160, ptr %161, align 8
  %162 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 4
  %163 = load double, ptr %162, align 8
  %164 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 5
  %165 = load double, ptr %164, align 8
  %166 = fsub double %163, %165
  %167 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 6
  %168 = load double, ptr %167, align 8
  %169 = fadd double %166, %168
  %170 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 7
  store double %169, ptr %170, align 8
  %171 = call i32 (ptr, ...) @printf(ptr noundef @.str.135)
  %172 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %173 = getelementptr inbounds [32 x %struct.OrderItem], ptr %172, i64 0, i64 0
  %174 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %175 = load i32, ptr %174, align 4
  call void @printCart(ptr noundef %173, i32 noundef %175)
  %176 = call i32 (ptr, ...) @printf(ptr noundef @.str.136)
  %177 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 5
  %178 = load double, ptr %177, align 8
  call void @printMoney(double noundef %178)
  %179 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %180 = call i32 (ptr, ...) @printf(ptr noundef @.str.137)
  %181 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 6
  %182 = load double, ptr %181, align 8
  call void @printMoney(double noundef %182)
  %183 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %184 = call i32 (ptr, ...) @printf(ptr noundef @.str.138)
  %185 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 7
  %186 = load double, ptr %185, align 8
  call void @printMoney(double noundef %186)
  %187 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %188 = call i32 @askYesNo(ptr noundef @.str.139)
  %189 = icmp ne i32 %188, 0
  br i1 %189, label %194, label %190

190:                                              ; preds = %154
  %191 = call i32 (ptr, ...) @printf(ptr noundef @.str.140)
  %192 = load i32, ptr @nextOrderId, align 4
  %193 = add nsw i32 %192, -1
  store i32 %193, ptr @nextOrderId, align 4
  br label %292

194:                                              ; preds = %154
  store i32 0, ptr %10, align 4
  br label %195

195:                                              ; preds = %237, %194
  %196 = load i32, ptr %10, align 4
  %197 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %198 = load i32, ptr %197, align 4
  %199 = icmp slt i32 %196, %198
  br i1 %199, label %200, label %240

200:                                              ; preds = %195
  %201 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %202 = load i32, ptr %10, align 4
  %203 = sext i32 %202 to i64
  %204 = getelementptr inbounds [32 x %struct.OrderItem], ptr %201, i64 0, i64 %203
  %205 = getelementptr inbounds nuw %struct.OrderItem, ptr %204, i32 0, i32 0
  %206 = load i32, ptr %205, align 8
  %207 = call i32 @findActiveProductIndexById(i32 noundef %206)
  store i32 %207, ptr %11, align 4
  %208 = load i32, ptr %11, align 4
  %209 = icmp slt i32 %208, 0
  br i1 %209, label %210, label %214

210:                                              ; preds = %200
  %211 = call i32 (ptr, ...) @printf(ptr noundef @.str.141)
  %212 = load i32, ptr @nextOrderId, align 4
  %213 = add nsw i32 %212, -1
  store i32 %213, ptr @nextOrderId, align 4
  br label %292

214:                                              ; preds = %200
  %215 = load i32, ptr %11, align 4
  %216 = sext i32 %215 to i64
  %217 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %216
  %218 = getelementptr inbounds nuw %struct.Product, ptr %217, i32 0, i32 4
  %219 = load i32, ptr %218, align 8
  %220 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %221 = load i32, ptr %10, align 4
  %222 = sext i32 %221 to i64
  %223 = getelementptr inbounds [32 x %struct.OrderItem], ptr %220, i64 0, i64 %222
  %224 = getelementptr inbounds nuw %struct.OrderItem, ptr %223, i32 0, i32 2
  %225 = load i32, ptr %224, align 4
  %226 = icmp slt i32 %219, %225
  br i1 %226, label %227, label %236

227:                                              ; preds = %214
  %228 = load i32, ptr %11, align 4
  %229 = sext i32 %228 to i64
  %230 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %229
  %231 = getelementptr inbounds nuw %struct.Product, ptr %230, i32 0, i32 1
  %232 = getelementptr inbounds [80 x i8], ptr %231, i64 0, i64 0
  %233 = call i32 (ptr, ...) @printf(ptr noundef @.str.142, ptr noundef %232)
  %234 = load i32, ptr @nextOrderId, align 4
  %235 = add nsw i32 %234, -1
  store i32 %235, ptr @nextOrderId, align 4
  br label %292

236:                                              ; preds = %214
  br label %237

237:                                              ; preds = %236
  %238 = load i32, ptr %10, align 4
  %239 = add nsw i32 %238, 1
  store i32 %239, ptr %10, align 4
  br label %195, !llvm.loop !19

240:                                              ; preds = %195
  store i32 0, ptr %12, align 4
  br label %241

241:                                              ; preds = %278, %240
  %242 = load i32, ptr %12, align 4
  %243 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 2
  %244 = load i32, ptr %243, align 4
  %245 = icmp slt i32 %242, %244
  br i1 %245, label %246, label %281

246:                                              ; preds = %241
  %247 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %248 = load i32, ptr %12, align 4
  %249 = sext i32 %248 to i64
  %250 = getelementptr inbounds [32 x %struct.OrderItem], ptr %247, i64 0, i64 %249
  %251 = getelementptr inbounds nuw %struct.OrderItem, ptr %250, i32 0, i32 0
  %252 = load i32, ptr %251, align 8
  %253 = call i32 @findActiveProductIndexById(i32 noundef %252)
  store i32 %253, ptr %13, align 4
  %254 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %255 = load i32, ptr %12, align 4
  %256 = sext i32 %255 to i64
  %257 = getelementptr inbounds [32 x %struct.OrderItem], ptr %254, i64 0, i64 %256
  %258 = getelementptr inbounds nuw %struct.OrderItem, ptr %257, i32 0, i32 2
  %259 = load i32, ptr %258, align 4
  %260 = load i32, ptr %13, align 4
  %261 = sext i32 %260 to i64
  %262 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %261
  %263 = getelementptr inbounds nuw %struct.Product, ptr %262, i32 0, i32 4
  %264 = load i32, ptr %263, align 8
  %265 = sub nsw i32 %264, %259
  store i32 %265, ptr %263, align 8
  %266 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 3
  %267 = load i32, ptr %12, align 4
  %268 = sext i32 %267 to i64
  %269 = getelementptr inbounds [32 x %struct.OrderItem], ptr %266, i64 0, i64 %268
  %270 = getelementptr inbounds nuw %struct.OrderItem, ptr %269, i32 0, i32 2
  %271 = load i32, ptr %270, align 4
  %272 = load i32, ptr %13, align 4
  %273 = sext i32 %272 to i64
  %274 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %273
  %275 = getelementptr inbounds nuw %struct.Product, ptr %274, i32 0, i32 5
  %276 = load i32, ptr %275, align 4
  %277 = add nsw i32 %276, %271
  store i32 %277, ptr %275, align 4
  br label %278

278:                                              ; preds = %246
  %279 = load i32, ptr %12, align 4
  %280 = add nsw i32 %279, 1
  store i32 %280, ptr %12, align 4
  br label %241, !llvm.loop !20

281:                                              ; preds = %241
  %282 = load i32, ptr @orderCount, align 4
  %283 = add nsw i32 %282, 1
  store i32 %283, ptr @orderCount, align 4
  %284 = sext i32 %282 to i64
  %285 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %284
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %285, ptr align 8 %1, i64 3496, i1 false)
  %286 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 0
  %287 = load i32, ptr %286, align 8
  %288 = call i32 (ptr, ...) @printf(ptr noundef @.str.143, i32 noundef %287)
  %289 = getelementptr inbounds nuw %struct.Order, ptr %1, i32 0, i32 7
  %290 = load double, ptr %289, align 8
  call void @printMoney(double noundef %290)
  %291 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  br label %292

292:                                              ; preds = %281, %227, %210, %190, %108, %21, %16
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @listOrders() #0 {
  %1 = alloca i32, align 4
  %2 = load i32, ptr @orderCount, align 4
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.157)
  br label %19

6:                                                ; preds = %0
  call void @printOrderSummaryHeader()
  store i32 0, ptr %1, align 4
  br label %7

7:                                                ; preds = %15, %6
  %8 = load i32, ptr %1, align 4
  %9 = load i32, ptr @orderCount, align 4
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %11, label %18

11:                                               ; preds = %7
  %12 = load i32, ptr %1, align 4
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %13
  call void @printOrderSummaryRow(ptr noundef %14)
  br label %15

15:                                               ; preds = %11
  %16 = load i32, ptr %1, align 4
  %17 = add nsw i32 %16, 1
  store i32 %17, ptr %1, align 4
  br label %7, !llvm.loop !21

18:                                               ; preds = %7
  call void @printOrderSummaryFooter()
  br label %19

19:                                               ; preds = %18, %4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @viewOrderDetail() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = load i32, ptr @orderCount, align 4
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str.161)
  br label %24

7:                                                ; preds = %0
  call void @listOrders()
  %8 = call i32 @readIntRange(ptr noundef @.str.162, i32 noundef 0, i32 noundef 2147483647)
  store i32 %8, ptr %1, align 4
  %9 = load i32, ptr %1, align 4
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %12

11:                                               ; preds = %7
  br label %24

12:                                               ; preds = %7
  %13 = load i32, ptr %1, align 4
  %14 = call i32 @findOrderIndexById(i32 noundef %13)
  store i32 %14, ptr %2, align 4
  %15 = load i32, ptr %2, align 4
  %16 = icmp slt i32 %15, 0
  br i1 %16, label %17, label %20

17:                                               ; preds = %12
  %18 = load i32, ptr %1, align 4
  %19 = call i32 (ptr, ...) @printf(ptr noundef @.str.163, i32 noundef %18)
  br label %24

20:                                               ; preds = %12
  %21 = load i32, ptr %2, align 4
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %22
  call void @printOrderDetail(ptr noundef %23)
  br label %24

24:                                               ; preds = %20, %17, %11, %5
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @cancelOrder() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = load i32, ptr @orderCount, align 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %0
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.173)
  br label %129

10:                                               ; preds = %0
  call void @listOrders()
  %11 = call i32 @readIntRange(ptr noundef @.str.174, i32 noundef 0, i32 noundef 2147483647)
  store i32 %11, ptr %1, align 4
  %12 = load i32, ptr %1, align 4
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %15

14:                                               ; preds = %10
  br label %129

15:                                               ; preds = %10
  %16 = load i32, ptr %1, align 4
  %17 = call i32 @findOrderIndexById(i32 noundef %16)
  store i32 %17, ptr %2, align 4
  %18 = load i32, ptr %2, align 4
  %19 = icmp slt i32 %18, 0
  br i1 %19, label %20, label %23

20:                                               ; preds = %15
  %21 = load i32, ptr %1, align 4
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.163, i32 noundef %21)
  br label %129

23:                                               ; preds = %15
  %24 = load i32, ptr %2, align 4
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %25
  store ptr %26, ptr %3, align 8
  %27 = load ptr, ptr %3, align 8
  %28 = getelementptr inbounds nuw %struct.Order, ptr %27, i32 0, i32 8
  %29 = getelementptr inbounds [16 x i8], ptr %28, i64 0, i64 0
  %30 = call i32 @strcmp(ptr noundef %29, ptr noundef @.str.175) #8
  %31 = icmp eq i32 %30, 0
  br i1 %31, label %32, label %34

32:                                               ; preds = %23
  %33 = call i32 (ptr, ...) @printf(ptr noundef @.str.176)
  br label %129

34:                                               ; preds = %23
  %35 = load ptr, ptr %3, align 8
  call void @printOrderDetail(ptr noundef %35)
  %36 = call i32 @askYesNo(ptr noundef @.str.177)
  %37 = icmp ne i32 %36, 0
  br i1 %37, label %39, label %38

38:                                               ; preds = %34
  br label %129

39:                                               ; preds = %34
  store i32 0, ptr %4, align 4
  br label %40

40:                                               ; preds = %121, %39
  %41 = load i32, ptr %4, align 4
  %42 = load ptr, ptr %3, align 8
  %43 = getelementptr inbounds nuw %struct.Order, ptr %42, i32 0, i32 2
  %44 = load i32, ptr %43, align 4
  %45 = icmp slt i32 %41, %44
  br i1 %45, label %46, label %124

46:                                               ; preds = %40
  %47 = load ptr, ptr %3, align 8
  %48 = getelementptr inbounds nuw %struct.Order, ptr %47, i32 0, i32 3
  %49 = load i32, ptr %4, align 4
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds [32 x %struct.OrderItem], ptr %48, i64 0, i64 %50
  %52 = getelementptr inbounds nuw %struct.OrderItem, ptr %51, i32 0, i32 0
  %53 = load i32, ptr %52, align 8
  %54 = call i32 @findProductIndexById(i32 noundef %53)
  store i32 %54, ptr %5, align 4
  %55 = load i32, ptr %5, align 4
  %56 = icmp sge i32 %55, 0
  br i1 %56, label %57, label %120

57:                                               ; preds = %46
  %58 = load i32, ptr %5, align 4
  %59 = sext i32 %58 to i64
  %60 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %59
  %61 = getelementptr inbounds nuw %struct.Product, ptr %60, i32 0, i32 4
  %62 = load i32, ptr %61, align 8
  %63 = load ptr, ptr %3, align 8
  %64 = getelementptr inbounds nuw %struct.Order, ptr %63, i32 0, i32 3
  %65 = load i32, ptr %4, align 4
  %66 = sext i32 %65 to i64
  %67 = getelementptr inbounds [32 x %struct.OrderItem], ptr %64, i64 0, i64 %66
  %68 = getelementptr inbounds nuw %struct.OrderItem, ptr %67, i32 0, i32 2
  %69 = load i32, ptr %68, align 4
  %70 = sub nsw i32 2147483647, %69
  %71 = icmp sle i32 %62, %70
  br i1 %71, label %72, label %86

72:                                               ; preds = %57
  %73 = load ptr, ptr %3, align 8
  %74 = getelementptr inbounds nuw %struct.Order, ptr %73, i32 0, i32 3
  %75 = load i32, ptr %4, align 4
  %76 = sext i32 %75 to i64
  %77 = getelementptr inbounds [32 x %struct.OrderItem], ptr %74, i64 0, i64 %76
  %78 = getelementptr inbounds nuw %struct.OrderItem, ptr %77, i32 0, i32 2
  %79 = load i32, ptr %78, align 4
  %80 = load i32, ptr %5, align 4
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %81
  %83 = getelementptr inbounds nuw %struct.Product, ptr %82, i32 0, i32 4
  %84 = load i32, ptr %83, align 8
  %85 = add nsw i32 %84, %79
  store i32 %85, ptr %83, align 8
  br label %86

86:                                               ; preds = %72, %57
  %87 = load i32, ptr %5, align 4
  %88 = sext i32 %87 to i64
  %89 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %88
  %90 = getelementptr inbounds nuw %struct.Product, ptr %89, i32 0, i32 5
  %91 = load i32, ptr %90, align 4
  %92 = load ptr, ptr %3, align 8
  %93 = getelementptr inbounds nuw %struct.Order, ptr %92, i32 0, i32 3
  %94 = load i32, ptr %4, align 4
  %95 = sext i32 %94 to i64
  %96 = getelementptr inbounds [32 x %struct.OrderItem], ptr %93, i64 0, i64 %95
  %97 = getelementptr inbounds nuw %struct.OrderItem, ptr %96, i32 0, i32 2
  %98 = load i32, ptr %97, align 4
  %99 = icmp sge i32 %91, %98
  br i1 %99, label %100, label %114

100:                                              ; preds = %86
  %101 = load ptr, ptr %3, align 8
  %102 = getelementptr inbounds nuw %struct.Order, ptr %101, i32 0, i32 3
  %103 = load i32, ptr %4, align 4
  %104 = sext i32 %103 to i64
  %105 = getelementptr inbounds [32 x %struct.OrderItem], ptr %102, i64 0, i64 %104
  %106 = getelementptr inbounds nuw %struct.OrderItem, ptr %105, i32 0, i32 2
  %107 = load i32, ptr %106, align 4
  %108 = load i32, ptr %5, align 4
  %109 = sext i32 %108 to i64
  %110 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %109
  %111 = getelementptr inbounds nuw %struct.Product, ptr %110, i32 0, i32 5
  %112 = load i32, ptr %111, align 4
  %113 = sub nsw i32 %112, %107
  store i32 %113, ptr %111, align 4
  br label %119

114:                                              ; preds = %86
  %115 = load i32, ptr %5, align 4
  %116 = sext i32 %115 to i64
  %117 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %116
  %118 = getelementptr inbounds nuw %struct.Product, ptr %117, i32 0, i32 5
  store i32 0, ptr %118, align 4
  br label %119

119:                                              ; preds = %114, %100
  br label %120

120:                                              ; preds = %119, %46
  br label %121

121:                                              ; preds = %120
  %122 = load i32, ptr %4, align 4
  %123 = add nsw i32 %122, 1
  store i32 %123, ptr %4, align 4
  br label %40, !llvm.loop !22

124:                                              ; preds = %40
  %125 = load ptr, ptr %3, align 8
  %126 = getelementptr inbounds nuw %struct.Order, ptr %125, i32 0, i32 8
  %127 = getelementptr inbounds [16 x i8], ptr %126, i64 0, i64 0
  call void @safeCopy(ptr noundef %127, ptr noundef @.str.175, i64 noundef 16)
  %128 = call i32 (ptr, ...) @printf(ptr noundef @.str.178)
  br label %129

129:                                              ; preds = %124, %38, %32, %20, %14, %8
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @exportReceipt() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca [64 x i8], align 16
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = load i32, ptr @orderCount, align 4
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %11

9:                                                ; preds = %0
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.179)
  br label %135

11:                                               ; preds = %0
  call void @listOrders()
  %12 = call i32 @readIntRange(ptr noundef @.str.180, i32 noundef 0, i32 noundef 2147483647)
  store i32 %12, ptr %1, align 4
  %13 = load i32, ptr %1, align 4
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %16

15:                                               ; preds = %11
  br label %135

16:                                               ; preds = %11
  %17 = load i32, ptr %1, align 4
  %18 = call i32 @findOrderIndexById(i32 noundef %17)
  store i32 %18, ptr %2, align 4
  %19 = load i32, ptr %2, align 4
  %20 = icmp slt i32 %19, 0
  br i1 %20, label %21, label %23

21:                                               ; preds = %16
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.181)
  br label %135

23:                                               ; preds = %16
  %24 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 0
  %25 = load i32, ptr %1, align 4
  %26 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef %24, i64 noundef 64, ptr noundef @.str.182, i32 noundef %25) #9
  %27 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 0
  %28 = call noalias ptr @fopen(ptr noundef %27, ptr noundef @.str.26)
  store ptr %28, ptr %4, align 8
  %29 = load ptr, ptr %4, align 8
  %30 = icmp ne ptr %29, null
  br i1 %30, label %33, label %31

31:                                               ; preds = %23
  %32 = call i32 (ptr, ...) @printf(ptr noundef @.str.183)
  br label %135

33:                                               ; preds = %23
  %34 = load i32, ptr %2, align 4
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %35
  store ptr %36, ptr %5, align 8
  %37 = load ptr, ptr %4, align 8
  %38 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %37, ptr noundef @.str.184) #9
  %39 = load ptr, ptr %4, align 8
  %40 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %39, ptr noundef @.str.185) #9
  %41 = load ptr, ptr %4, align 8
  %42 = load ptr, ptr %5, align 8
  %43 = getelementptr inbounds nuw %struct.Order, ptr %42, i32 0, i32 0
  %44 = load i32, ptr %43, align 8
  %45 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %41, ptr noundef @.str.186, i32 noundef %44) #9
  %46 = load ptr, ptr %4, align 8
  %47 = load ptr, ptr %5, align 8
  %48 = getelementptr inbounds nuw %struct.Order, ptr %47, i32 0, i32 1
  %49 = getelementptr inbounds [80 x i8], ptr %48, i64 0, i64 0
  %50 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %46, ptr noundef @.str.165, ptr noundef %49) #9
  %51 = load ptr, ptr %4, align 8
  %52 = load ptr, ptr %5, align 8
  %53 = getelementptr inbounds nuw %struct.Order, ptr %52, i32 0, i32 8
  %54 = getelementptr inbounds [16 x i8], ptr %53, i64 0, i64 0
  %55 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %51, ptr noundef @.str.166, ptr noundef %54) #9
  %56 = load ptr, ptr %4, align 8
  %57 = load ptr, ptr %5, align 8
  %58 = getelementptr inbounds nuw %struct.Order, ptr %57, i32 0, i32 9
  %59 = getelementptr inbounds [32 x i8], ptr %58, i64 0, i64 0
  %60 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %56, ptr noundef @.str.187, ptr noundef %59) #9
  %61 = load ptr, ptr %4, align 8
  %62 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %61, ptr noundef @.str.188, ptr noundef @.str.189, ptr noundef @.str.190, ptr noundef @.str.191, ptr noundef @.str.192, ptr noundef @.str.193) #9
  store i32 0, ptr %6, align 4
  br label %63

63:                                               ; preds = %107, %33
  %64 = load i32, ptr %6, align 4
  %65 = load ptr, ptr %5, align 8
  %66 = getelementptr inbounds nuw %struct.Order, ptr %65, i32 0, i32 2
  %67 = load i32, ptr %66, align 4
  %68 = icmp slt i32 %64, %67
  br i1 %68, label %69, label %110

69:                                               ; preds = %63
  %70 = load ptr, ptr %4, align 8
  %71 = load ptr, ptr %5, align 8
  %72 = getelementptr inbounds nuw %struct.Order, ptr %71, i32 0, i32 3
  %73 = load i32, ptr %6, align 4
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds [32 x %struct.OrderItem], ptr %72, i64 0, i64 %74
  %76 = getelementptr inbounds nuw %struct.OrderItem, ptr %75, i32 0, i32 0
  %77 = load i32, ptr %76, align 8
  %78 = load ptr, ptr %5, align 8
  %79 = getelementptr inbounds nuw %struct.Order, ptr %78, i32 0, i32 3
  %80 = load i32, ptr %6, align 4
  %81 = sext i32 %80 to i64
  %82 = getelementptr inbounds [32 x %struct.OrderItem], ptr %79, i64 0, i64 %81
  %83 = getelementptr inbounds nuw %struct.OrderItem, ptr %82, i32 0, i32 1
  %84 = getelementptr inbounds [80 x i8], ptr %83, i64 0, i64 0
  %85 = load ptr, ptr %5, align 8
  %86 = getelementptr inbounds nuw %struct.Order, ptr %85, i32 0, i32 3
  %87 = load i32, ptr %6, align 4
  %88 = sext i32 %87 to i64
  %89 = getelementptr inbounds [32 x %struct.OrderItem], ptr %86, i64 0, i64 %88
  %90 = getelementptr inbounds nuw %struct.OrderItem, ptr %89, i32 0, i32 2
  %91 = load i32, ptr %90, align 4
  %92 = load ptr, ptr %5, align 8
  %93 = getelementptr inbounds nuw %struct.Order, ptr %92, i32 0, i32 3
  %94 = load i32, ptr %6, align 4
  %95 = sext i32 %94 to i64
  %96 = getelementptr inbounds [32 x %struct.OrderItem], ptr %93, i64 0, i64 %95
  %97 = getelementptr inbounds nuw %struct.OrderItem, ptr %96, i32 0, i32 3
  %98 = load double, ptr %97, align 8
  %99 = load ptr, ptr %5, align 8
  %100 = getelementptr inbounds nuw %struct.Order, ptr %99, i32 0, i32 3
  %101 = load i32, ptr %6, align 4
  %102 = sext i32 %101 to i64
  %103 = getelementptr inbounds [32 x %struct.OrderItem], ptr %100, i64 0, i64 %102
  %104 = getelementptr inbounds nuw %struct.OrderItem, ptr %103, i32 0, i32 4
  %105 = load double, ptr %104, align 8
  %106 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %70, ptr noundef @.str.194, i32 noundef %77, ptr noundef %84, i32 noundef %91, double noundef %98, double noundef %105) #9
  br label %107

107:                                              ; preds = %69
  %108 = load i32, ptr %6, align 4
  %109 = add nsw i32 %108, 1
  store i32 %109, ptr %6, align 4
  br label %63, !llvm.loop !23

110:                                              ; preds = %63
  %111 = load ptr, ptr %4, align 8
  %112 = load ptr, ptr %5, align 8
  %113 = getelementptr inbounds nuw %struct.Order, ptr %112, i32 0, i32 4
  %114 = load double, ptr %113, align 8
  %115 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %111, ptr noundef @.str.195, double noundef %114) #9
  %116 = load ptr, ptr %4, align 8
  %117 = load ptr, ptr %5, align 8
  %118 = getelementptr inbounds nuw %struct.Order, ptr %117, i32 0, i32 5
  %119 = load double, ptr %118, align 8
  %120 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %116, ptr noundef @.str.196, double noundef %119) #9
  %121 = load ptr, ptr %4, align 8
  %122 = load ptr, ptr %5, align 8
  %123 = getelementptr inbounds nuw %struct.Order, ptr %122, i32 0, i32 6
  %124 = load double, ptr %123, align 8
  %125 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %121, ptr noundef @.str.197, double noundef %124) #9
  %126 = load ptr, ptr %4, align 8
  %127 = load ptr, ptr %5, align 8
  %128 = getelementptr inbounds nuw %struct.Order, ptr %127, i32 0, i32 7
  %129 = load double, ptr %128, align 8
  %130 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %126, ptr noundef @.str.198, double noundef %129) #9
  %131 = load ptr, ptr %4, align 8
  %132 = call i32 @fclose(ptr noundef %131)
  %133 = getelementptr inbounds [64 x i8], ptr %3, i64 0, i64 0
  %134 = call i32 (ptr, ...) @printf(ptr noundef @.str.199, ptr noundef %133)
  br label %135

135:                                              ; preds = %110, %31, %21, %15, %9
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @findOrderIndexById(i32 noundef %0) #0 {
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
  %14 = load i32, ptr %13, align 8
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
  br label %5, !llvm.loop !24

23:                                               ; preds = %5
  store i32 -1, ptr %2, align 4
  br label %24

24:                                               ; preds = %23, %17
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: nounwind
declare i32 @snprintf(ptr noundef, i64 noundef, ptr noundef, ...) #5

declare noalias ptr @fopen(ptr noundef, ptr noundef) #1

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #5

declare i32 @fclose(ptr noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printOrderDetail(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds nuw %struct.Order, ptr %5, i32 0, i32 0
  %7 = load i32, ptr %6, align 8
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.164, i32 noundef %7)
  %9 = load ptr, ptr %2, align 8
  %10 = getelementptr inbounds nuw %struct.Order, ptr %9, i32 0, i32 1
  %11 = getelementptr inbounds [80 x i8], ptr %10, i64 0, i64 0
  %12 = call i32 (ptr, ...) @printf(ptr noundef @.str.165, ptr noundef %11)
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds nuw %struct.Order, ptr %13, i32 0, i32 8
  %15 = getelementptr inbounds [16 x i8], ptr %14, i64 0, i64 0
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.166, ptr noundef %15)
  %17 = load ptr, ptr %2, align 8
  %18 = getelementptr inbounds nuw %struct.Order, ptr %17, i32 0, i32 9
  %19 = getelementptr inbounds [32 x i8], ptr %18, i64 0, i64 0
  %20 = call i32 (ptr, ...) @printf(ptr noundef @.str.167, ptr noundef %19)
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.168)
  %22 = call i32 (ptr, ...) @printf(ptr noundef @.str.148)
  %23 = call i32 (ptr, ...) @printf(ptr noundef @.str.147)
  store i32 0, ptr %3, align 4
  br label %24

24:                                               ; preds = %52, %1
  %25 = load i32, ptr %3, align 4
  %26 = load ptr, ptr %2, align 8
  %27 = getelementptr inbounds nuw %struct.Order, ptr %26, i32 0, i32 2
  %28 = load i32, ptr %27, align 4
  %29 = icmp slt i32 %25, %28
  br i1 %29, label %30, label %55

30:                                               ; preds = %24
  %31 = load ptr, ptr %2, align 8
  %32 = getelementptr inbounds nuw %struct.Order, ptr %31, i32 0, i32 3
  %33 = load i32, ptr %3, align 4
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds [32 x %struct.OrderItem], ptr %32, i64 0, i64 %34
  store ptr %35, ptr %4, align 8
  %36 = load ptr, ptr %4, align 8
  %37 = getelementptr inbounds nuw %struct.OrderItem, ptr %36, i32 0, i32 0
  %38 = load i32, ptr %37, align 8
  %39 = load ptr, ptr %4, align 8
  %40 = getelementptr inbounds nuw %struct.OrderItem, ptr %39, i32 0, i32 1
  %41 = getelementptr inbounds [80 x i8], ptr %40, i64 0, i64 0
  %42 = load ptr, ptr %4, align 8
  %43 = getelementptr inbounds nuw %struct.OrderItem, ptr %42, i32 0, i32 2
  %44 = load i32, ptr %43, align 4
  %45 = load ptr, ptr %4, align 8
  %46 = getelementptr inbounds nuw %struct.OrderItem, ptr %45, i32 0, i32 3
  %47 = load double, ptr %46, align 8
  %48 = load ptr, ptr %4, align 8
  %49 = getelementptr inbounds nuw %struct.OrderItem, ptr %48, i32 0, i32 4
  %50 = load double, ptr %49, align 8
  %51 = call i32 (ptr, ...) @printf(ptr noundef @.str.149, i32 noundef %38, ptr noundef %41, i32 noundef %44, double noundef %47, double noundef %50)
  br label %52

52:                                               ; preds = %30
  %53 = load i32, ptr %3, align 4
  %54 = add nsw i32 %53, 1
  store i32 %54, ptr %3, align 4
  br label %24, !llvm.loop !25

55:                                               ; preds = %24
  %56 = call i32 (ptr, ...) @printf(ptr noundef @.str.147)
  %57 = call i32 (ptr, ...) @printf(ptr noundef @.str.169)
  %58 = load ptr, ptr %2, align 8
  %59 = getelementptr inbounds nuw %struct.Order, ptr %58, i32 0, i32 4
  %60 = load double, ptr %59, align 8
  call void @printMoney(double noundef %60)
  %61 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %62 = call i32 (ptr, ...) @printf(ptr noundef @.str.170)
  %63 = load ptr, ptr %2, align 8
  %64 = getelementptr inbounds nuw %struct.Order, ptr %63, i32 0, i32 5
  %65 = load double, ptr %64, align 8
  call void @printMoney(double noundef %65)
  %66 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %67 = call i32 (ptr, ...) @printf(ptr noundef @.str.171)
  %68 = load ptr, ptr %2, align 8
  %69 = getelementptr inbounds nuw %struct.Order, ptr %68, i32 0, i32 6
  %70 = load double, ptr %69, align 8
  call void @printMoney(double noundef %70)
  %71 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  %72 = call i32 (ptr, ...) @printf(ptr noundef @.str.172)
  %73 = load ptr, ptr %2, align 8
  %74 = getelementptr inbounds nuw %struct.Order, ptr %73, i32 0, i32 7
  %75 = load double, ptr %74, align 8
  call void @printMoney(double noundef %75)
  %76 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @askYesNo(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca [32 x i8], align 16
  store ptr %0, ptr %3, align 8
  br label %5

5:                                                ; preds = %1, %29
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds [32 x i8], ptr %4, i64 0, i64 0
  call void @readLine(ptr noundef %6, ptr noundef %7, i64 noundef 32)
  %8 = getelementptr inbounds [32 x i8], ptr %4, i64 0, i64 0
  %9 = load i8, ptr %8, align 16
  %10 = sext i8 %9 to i32
  %11 = icmp eq i32 %10, 121
  br i1 %11, label %17, label %12

12:                                               ; preds = %5
  %13 = getelementptr inbounds [32 x i8], ptr %4, i64 0, i64 0
  %14 = load i8, ptr %13, align 16
  %15 = sext i8 %14 to i32
  %16 = icmp eq i32 %15, 89
  br i1 %16, label %17, label %18

17:                                               ; preds = %12, %5
  store i32 1, ptr %2, align 4
  br label %31

18:                                               ; preds = %12
  %19 = getelementptr inbounds [32 x i8], ptr %4, i64 0, i64 0
  %20 = load i8, ptr %19, align 16
  %21 = sext i8 %20 to i32
  %22 = icmp eq i32 %21, 110
  br i1 %22, label %28, label %23

23:                                               ; preds = %18
  %24 = getelementptr inbounds [32 x i8], ptr %4, i64 0, i64 0
  %25 = load i8, ptr %24, align 16
  %26 = sext i8 %25 to i32
  %27 = icmp eq i32 %26, 78
  br i1 %27, label %28, label %29

28:                                               ; preds = %23, %18
  store i32 0, ptr %2, align 4
  br label %31

29:                                               ; preds = %23
  %30 = call i32 (ptr, ...) @printf(ptr noundef @.str.80)
  br label %5

31:                                               ; preds = %28, %17
  %32 = load i32, ptr %2, align 4
  ret i32 %32
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @findProductIndexById(i32 noundef %0) #0 {
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
  %12 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %11
  %13 = getelementptr inbounds nuw %struct.Product, ptr %12, i32 0, i32 0
  %14 = load i32, ptr %13, align 8
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
  br label %5, !llvm.loop !26

23:                                               ; preds = %5
  store i32 -1, ptr %2, align 4
  br label %24

24:                                               ; preds = %23, %17
  %25 = load i32, ptr %2, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @safeCopy(ptr noundef %0, ptr noundef %1, i64 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i64 %2, ptr %6, align 8
  %7 = load i64, ptr %6, align 8
  %8 = icmp eq i64 %7, 0
  br i1 %8, label %9, label %10

9:                                                ; preds = %3
  br label %24

10:                                               ; preds = %3
  %11 = load ptr, ptr %5, align 8
  %12 = icmp ne ptr %11, null
  br i1 %12, label %14, label %13

13:                                               ; preds = %10
  store ptr @.str.7, ptr %5, align 8
  br label %14

14:                                               ; preds = %13, %10
  %15 = load ptr, ptr %4, align 8
  %16 = load ptr, ptr %5, align 8
  %17 = load i64, ptr %6, align 8
  %18 = sub i64 %17, 1
  %19 = call ptr @strncpy(ptr noundef %15, ptr noundef %16, i64 noundef %18) #9
  %20 = load ptr, ptr %4, align 8
  %21 = load i64, ptr %6, align 8
  %22 = sub i64 %21, 1
  %23 = getelementptr inbounds nuw i8, ptr %20, i64 %22
  store i8 0, ptr %23, align 1
  br label %24

24:                                               ; preds = %14, %9
  ret void
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define internal void @readLine(ptr noundef %0, ptr noundef %1, i64 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i64 %2, ptr %6, align 8
  %7 = load ptr, ptr %4, align 8
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.24, ptr noundef %7)
  %9 = load ptr, ptr %5, align 8
  %10 = load i64, ptr %6, align 8
  %11 = trunc i64 %10 to i32
  %12 = load ptr, ptr @stdin, align 8
  %13 = call ptr @fgets(ptr noundef %9, i32 noundef %11, ptr noundef %12)
  %14 = icmp ne ptr %13, null
  br i1 %14, label %19, label %15

15:                                               ; preds = %3
  %16 = load ptr, ptr %5, align 8
  %17 = getelementptr inbounds i8, ptr %16, i64 0
  store i8 0, ptr %17, align 1
  %18 = load ptr, ptr @stdin, align 8
  call void @clearerr(ptr noundef %18) #9
  br label %23

19:                                               ; preds = %3
  %20 = load ptr, ptr %5, align 8
  %21 = load i64, ptr %6, align 8
  call void @flushLineIfNeeded(ptr noundef %20, i64 noundef %21)
  %22 = load ptr, ptr %5, align 8
  call void @trim(ptr noundef %22)
  br label %23

23:                                               ; preds = %19, %15
  ret void
}

; Function Attrs: nounwind
declare void @clearerr(ptr noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define internal void @flushLineIfNeeded(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  %7 = load ptr, ptr %3, align 8
  %8 = call i64 @strlen(ptr noundef %7) #8
  store i64 %8, ptr %5, align 8
  %9 = load i64, ptr %5, align 8
  %10 = icmp ugt i64 %9, 0
  br i1 %10, label %11, label %20

11:                                               ; preds = %2
  %12 = load ptr, ptr %3, align 8
  %13 = load i64, ptr %5, align 8
  %14 = sub i64 %13, 1
  %15 = getelementptr inbounds nuw i8, ptr %12, i64 %14
  %16 = load i8, ptr %15, align 1
  %17 = sext i8 %16 to i32
  %18 = icmp eq i32 %17, 10
  br i1 %18, label %19, label %20

19:                                               ; preds = %11
  br label %32

20:                                               ; preds = %11, %2
  br label %21

21:                                               ; preds = %29, %20
  %22 = call i32 @getchar()
  store i32 %22, ptr %6, align 4
  %23 = icmp ne i32 %22, 10
  br i1 %23, label %24, label %27

24:                                               ; preds = %21
  %25 = load i32, ptr %6, align 4
  %26 = icmp ne i32 %25, -1
  br label %27

27:                                               ; preds = %24, %21
  %28 = phi i1 [ false, %21 ], [ %26, %24 ]
  br i1 %28, label %29, label %30

29:                                               ; preds = %27
  br label %21, !llvm.loop !27

30:                                               ; preds = %27
  %31 = load i64, ptr %4, align 8
  br label %32

32:                                               ; preds = %30, %19
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @trim(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  store ptr %0, ptr %2, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = icmp ne ptr %5, null
  br i1 %6, label %8, label %7

7:                                                ; preds = %1
  br label %94

8:                                                ; preds = %1
  %9 = load ptr, ptr %2, align 8
  %10 = call i64 @strlen(ptr noundef %9) #8
  store i64 %10, ptr %3, align 8
  br label %11

11:                                               ; preds = %49, %8
  %12 = load i64, ptr %3, align 8
  %13 = icmp ugt i64 %12, 0
  br i1 %13, label %14, label %47

14:                                               ; preds = %11
  %15 = load ptr, ptr %2, align 8
  %16 = load i64, ptr %3, align 8
  %17 = sub i64 %16, 1
  %18 = getelementptr inbounds nuw i8, ptr %15, i64 %17
  %19 = load i8, ptr %18, align 1
  %20 = sext i8 %19 to i32
  %21 = icmp eq i32 %20, 10
  br i1 %21, label %45, label %22

22:                                               ; preds = %14
  %23 = load ptr, ptr %2, align 8
  %24 = load i64, ptr %3, align 8
  %25 = sub i64 %24, 1
  %26 = getelementptr inbounds nuw i8, ptr %23, i64 %25
  %27 = load i8, ptr %26, align 1
  %28 = sext i8 %27 to i32
  %29 = icmp eq i32 %28, 13
  br i1 %29, label %45, label %30

30:                                               ; preds = %22
  %31 = call ptr @__ctype_b_loc() #10
  %32 = load ptr, ptr %31, align 8
  %33 = load ptr, ptr %2, align 8
  %34 = load i64, ptr %3, align 8
  %35 = sub i64 %34, 1
  %36 = getelementptr inbounds nuw i8, ptr %33, i64 %35
  %37 = load i8, ptr %36, align 1
  %38 = zext i8 %37 to i32
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds i16, ptr %32, i64 %39
  %41 = load i16, ptr %40, align 2
  %42 = zext i16 %41 to i32
  %43 = and i32 %42, 8192
  %44 = icmp ne i32 %43, 0
  br label %45

45:                                               ; preds = %30, %22, %14
  %46 = phi i1 [ true, %22 ], [ true, %14 ], [ %44, %30 ]
  br label %47

47:                                               ; preds = %45, %11
  %48 = phi i1 [ false, %11 ], [ %46, %45 ]
  br i1 %48, label %49, label %54

49:                                               ; preds = %47
  %50 = load ptr, ptr %2, align 8
  %51 = load i64, ptr %3, align 8
  %52 = add i64 %51, -1
  store i64 %52, ptr %3, align 8
  %53 = getelementptr inbounds nuw i8, ptr %50, i64 %52
  store i8 0, ptr %53, align 1
  br label %11, !llvm.loop !28

54:                                               ; preds = %47
  store i64 0, ptr %4, align 8
  br label %55

55:                                               ; preds = %78, %54
  %56 = load ptr, ptr %2, align 8
  %57 = load i64, ptr %4, align 8
  %58 = getelementptr inbounds nuw i8, ptr %56, i64 %57
  %59 = load i8, ptr %58, align 1
  %60 = sext i8 %59 to i32
  %61 = icmp ne i32 %60, 0
  br i1 %61, label %62, label %76

62:                                               ; preds = %55
  %63 = call ptr @__ctype_b_loc() #10
  %64 = load ptr, ptr %63, align 8
  %65 = load ptr, ptr %2, align 8
  %66 = load i64, ptr %4, align 8
  %67 = getelementptr inbounds nuw i8, ptr %65, i64 %66
  %68 = load i8, ptr %67, align 1
  %69 = zext i8 %68 to i32
  %70 = sext i32 %69 to i64
  %71 = getelementptr inbounds i16, ptr %64, i64 %70
  %72 = load i16, ptr %71, align 2
  %73 = zext i16 %72 to i32
  %74 = and i32 %73, 8192
  %75 = icmp ne i32 %74, 0
  br label %76

76:                                               ; preds = %62, %55
  %77 = phi i1 [ false, %55 ], [ %75, %62 ]
  br i1 %77, label %78, label %81

78:                                               ; preds = %76
  %79 = load i64, ptr %4, align 8
  %80 = add i64 %79, 1
  store i64 %80, ptr %4, align 8
  br label %55, !llvm.loop !29

81:                                               ; preds = %76
  %82 = load i64, ptr %4, align 8
  %83 = icmp ugt i64 %82, 0
  br i1 %83, label %84, label %94

84:                                               ; preds = %81
  %85 = load ptr, ptr %2, align 8
  %86 = load ptr, ptr %2, align 8
  %87 = load i64, ptr %4, align 8
  %88 = getelementptr inbounds nuw i8, ptr %86, i64 %87
  %89 = load ptr, ptr %2, align 8
  %90 = load i64, ptr %4, align 8
  %91 = getelementptr inbounds nuw i8, ptr %89, i64 %90
  %92 = call i64 @strlen(ptr noundef %91) #8
  %93 = add i64 %92, 1
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %85, ptr align 1 %88, i64 %93, i1 false)
  br label %94

94:                                               ; preds = %7, %84, %81
  ret void
}

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #4

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #6

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr writeonly captures(none), ptr readonly captures(none), i64, i1 immarg) #2

declare i32 @getchar() #1

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printOrderSummaryHeader() #0 {
  %1 = call i32 (ptr, ...) @printf(ptr noundef @.str.158)
  %2 = call i32 (ptr, ...) @printf(ptr noundef @.str.159)
  %3 = call i32 (ptr, ...) @printf(ptr noundef @.str.158)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printOrderSummaryRow(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 0
  %5 = load i32, ptr %4, align 8
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds nuw %struct.Order, ptr %6, i32 0, i32 1
  %8 = getelementptr inbounds [80 x i8], ptr %7, i64 0, i64 0
  %9 = load ptr, ptr %2, align 8
  %10 = getelementptr inbounds nuw %struct.Order, ptr %9, i32 0, i32 2
  %11 = load i32, ptr %10, align 4
  %12 = load ptr, ptr %2, align 8
  %13 = getelementptr inbounds nuw %struct.Order, ptr %12, i32 0, i32 4
  %14 = load double, ptr %13, align 8
  %15 = load ptr, ptr %2, align 8
  %16 = getelementptr inbounds nuw %struct.Order, ptr %15, i32 0, i32 7
  %17 = load double, ptr %16, align 8
  %18 = load ptr, ptr %2, align 8
  %19 = getelementptr inbounds nuw %struct.Order, ptr %18, i32 0, i32 8
  %20 = getelementptr inbounds [16 x i8], ptr %19, i64 0, i64 0
  %21 = load ptr, ptr %2, align 8
  %22 = getelementptr inbounds nuw %struct.Order, ptr %21, i32 0, i32 9
  %23 = getelementptr inbounds [32 x i8], ptr %22, i64 0, i64 0
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.160, i32 noundef %5, ptr noundef %8, i32 noundef %11, double noundef %14, double noundef %17, ptr noundef %20, ptr noundef %23)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printOrderSummaryFooter() #0 {
  %1 = call i32 (ptr, ...) @printf(ptr noundef @.str.158)
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #7

; Function Attrs: noinline nounwind optnone uwtable
define internal void @nowString(ptr noundef %0, i64 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i64, align 8
  %6 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store i64 %1, ptr %4, align 8
  %7 = call i64 @time(ptr noundef null) #9
  store i64 %7, ptr %5, align 8
  %8 = call ptr @localtime(ptr noundef %5) #9
  store ptr %8, ptr %6, align 8
  %9 = load ptr, ptr %6, align 8
  %10 = icmp ne ptr %9, null
  br i1 %10, label %14, label %11

11:                                               ; preds = %2
  %12 = load ptr, ptr %3, align 8
  %13 = load i64, ptr %4, align 8
  call void @safeCopy(ptr noundef %12, ptr noundef @.str.144, i64 noundef %13)
  br label %19

14:                                               ; preds = %2
  %15 = load ptr, ptr %3, align 8
  %16 = load i64, ptr %4, align 8
  %17 = load ptr, ptr %6, align 8
  %18 = call i64 @strftime(ptr noundef %15, i64 noundef %16, ptr noundef @.str.145, ptr noundef %17) #9
  br label %19

19:                                               ; preds = %14, %11
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @readNonEmptyString(ptr noundef %0, ptr noundef %1, i64 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i64 %2, ptr %6, align 8
  br label %7

7:                                                ; preds = %3, %15
  %8 = load ptr, ptr %4, align 8
  %9 = load ptr, ptr %5, align 8
  %10 = load i64, ptr %6, align 8
  call void @readLine(ptr noundef %8, ptr noundef %9, i64 noundef %10)
  %11 = load ptr, ptr %5, align 8
  call void @sanitizeField(ptr noundef %11)
  %12 = load ptr, ptr %5, align 8
  %13 = call i64 @strlen(ptr noundef %12) #8
  %14 = icmp eq i64 %13, 0
  br i1 %14, label %15, label %17

15:                                               ; preds = %7
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.64)
  br label %7

17:                                               ; preds = %7
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @listProducts() #0 {
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
  %10 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %9
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %12 = load i32, ptr %11, align 8
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %14, label %18

14:                                               ; preds = %7
  %15 = load i32, ptr %2, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %16
  call void @printProductRow(ptr noundef %17)
  store i32 1, ptr %1, align 4
  br label %18

18:                                               ; preds = %14, %7
  br label %19

19:                                               ; preds = %18
  %20 = load i32, ptr %2, align 4
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %2, align 4
  br label %3, !llvm.loop !30

22:                                               ; preds = %3
  call void @printProductFooter()
  %23 = load i32, ptr %1, align 4
  %24 = icmp ne i32 %23, 0
  br i1 %24, label %27, label %25

25:                                               ; preds = %22
  %26 = call i32 (ptr, ...) @printf(ptr noundef @.str.53)
  br label %27

27:                                               ; preds = %25, %22
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @findActiveProductIndexById(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %5 = load i32, ptr %3, align 4
  %6 = call i32 @findProductIndexById(i32 noundef %5)
  store i32 %6, ptr %4, align 4
  %7 = load i32, ptr %4, align 4
  %8 = icmp slt i32 %7, 0
  br i1 %8, label %16, label %9

9:                                                ; preds = %1
  %10 = load i32, ptr %4, align 4
  %11 = sext i32 %10 to i64
  %12 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %11
  %13 = getelementptr inbounds nuw %struct.Product, ptr %12, i32 0, i32 6
  %14 = load i32, ptr %13, align 8
  %15 = icmp ne i32 %14, 0
  br i1 %15, label %17, label %16

16:                                               ; preds = %9, %1
  store i32 -1, ptr %2, align 4
  br label %19

17:                                               ; preds = %9
  %18 = load i32, ptr %4, align 4
  store i32 %18, ptr %2, align 4
  br label %19

19:                                               ; preds = %17, %16
  %20 = load i32, ptr %2, align 4
  ret i32 %20
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @getTempQtyForProduct(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %32, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %5, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %35

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds %struct.OrderItem, ptr %14, i64 %16
  %18 = getelementptr inbounds nuw %struct.OrderItem, ptr %17, i32 0, i32 0
  %19 = load i32, ptr %18, align 8
  %20 = load i32, ptr %6, align 4
  %21 = icmp eq i32 %19, %20
  br i1 %21, label %22, label %31

22:                                               ; preds = %13
  %23 = load ptr, ptr %4, align 8
  %24 = load i32, ptr %8, align 4
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds %struct.OrderItem, ptr %23, i64 %25
  %27 = getelementptr inbounds nuw %struct.OrderItem, ptr %26, i32 0, i32 2
  %28 = load i32, ptr %27, align 4
  %29 = load i32, ptr %7, align 4
  %30 = add nsw i32 %29, %28
  store i32 %30, ptr %7, align 4
  br label %31

31:                                               ; preds = %22, %13
  br label %32

32:                                               ; preds = %31
  %33 = load i32, ptr %8, align 4
  %34 = add nsw i32 %33, 1
  store i32 %34, ptr %8, align 4
  br label %9, !llvm.loop !31

35:                                               ; preds = %9
  %36 = load i32, ptr %7, align 4
  ret i32 %36
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @mergeCartItem(ptr noundef %0, ptr noundef %1, ptr noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca ptr, align 8
  store ptr %0, ptr %5, align 8
  store ptr %1, ptr %6, align 8
  store ptr %2, ptr %7, align 8
  store i32 %3, ptr %8, align 4
  store i32 0, ptr %9, align 4
  br label %11

11:                                               ; preds = %56, %4
  %12 = load i32, ptr %9, align 4
  %13 = load ptr, ptr %6, align 8
  %14 = load i32, ptr %13, align 4
  %15 = icmp slt i32 %12, %14
  br i1 %15, label %16, label %59

16:                                               ; preds = %11
  %17 = load ptr, ptr %5, align 8
  %18 = load i32, ptr %9, align 4
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds %struct.OrderItem, ptr %17, i64 %19
  %21 = getelementptr inbounds nuw %struct.OrderItem, ptr %20, i32 0, i32 0
  %22 = load i32, ptr %21, align 8
  %23 = load ptr, ptr %7, align 8
  %24 = getelementptr inbounds nuw %struct.Product, ptr %23, i32 0, i32 0
  %25 = load i32, ptr %24, align 8
  %26 = icmp eq i32 %22, %25
  br i1 %26, label %27, label %55

27:                                               ; preds = %16
  %28 = load i32, ptr %8, align 4
  %29 = load ptr, ptr %5, align 8
  %30 = load i32, ptr %9, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds %struct.OrderItem, ptr %29, i64 %31
  %33 = getelementptr inbounds nuw %struct.OrderItem, ptr %32, i32 0, i32 2
  %34 = load i32, ptr %33, align 4
  %35 = add nsw i32 %34, %28
  store i32 %35, ptr %33, align 4
  %36 = load ptr, ptr %5, align 8
  %37 = load i32, ptr %9, align 4
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds %struct.OrderItem, ptr %36, i64 %38
  %40 = getelementptr inbounds nuw %struct.OrderItem, ptr %39, i32 0, i32 2
  %41 = load i32, ptr %40, align 4
  %42 = sitofp i32 %41 to double
  %43 = load ptr, ptr %5, align 8
  %44 = load i32, ptr %9, align 4
  %45 = sext i32 %44 to i64
  %46 = getelementptr inbounds %struct.OrderItem, ptr %43, i64 %45
  %47 = getelementptr inbounds nuw %struct.OrderItem, ptr %46, i32 0, i32 3
  %48 = load double, ptr %47, align 8
  %49 = fmul double %42, %48
  %50 = load ptr, ptr %5, align 8
  %51 = load i32, ptr %9, align 4
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds %struct.OrderItem, ptr %50, i64 %52
  %54 = getelementptr inbounds nuw %struct.OrderItem, ptr %53, i32 0, i32 4
  store double %49, ptr %54, align 8
  br label %100

55:                                               ; preds = %16
  br label %56

56:                                               ; preds = %55
  %57 = load i32, ptr %9, align 4
  %58 = add nsw i32 %57, 1
  store i32 %58, ptr %9, align 4
  br label %11, !llvm.loop !32

59:                                               ; preds = %11
  %60 = load ptr, ptr %6, align 8
  %61 = load i32, ptr %60, align 4
  %62 = icmp sge i32 %61, 32
  br i1 %62, label %63, label %64

63:                                               ; preds = %59
  br label %100

64:                                               ; preds = %59
  %65 = load ptr, ptr %5, align 8
  %66 = load ptr, ptr %6, align 8
  %67 = load i32, ptr %66, align 4
  %68 = sext i32 %67 to i64
  %69 = getelementptr inbounds %struct.OrderItem, ptr %65, i64 %68
  store ptr %69, ptr %10, align 8
  %70 = load ptr, ptr %7, align 8
  %71 = getelementptr inbounds nuw %struct.Product, ptr %70, i32 0, i32 0
  %72 = load i32, ptr %71, align 8
  %73 = load ptr, ptr %10, align 8
  %74 = getelementptr inbounds nuw %struct.OrderItem, ptr %73, i32 0, i32 0
  store i32 %72, ptr %74, align 8
  %75 = load ptr, ptr %10, align 8
  %76 = getelementptr inbounds nuw %struct.OrderItem, ptr %75, i32 0, i32 1
  %77 = getelementptr inbounds [80 x i8], ptr %76, i64 0, i64 0
  %78 = load ptr, ptr %7, align 8
  %79 = getelementptr inbounds nuw %struct.Product, ptr %78, i32 0, i32 1
  %80 = getelementptr inbounds [80 x i8], ptr %79, i64 0, i64 0
  call void @safeCopy(ptr noundef %77, ptr noundef %80, i64 noundef 80)
  %81 = load i32, ptr %8, align 4
  %82 = load ptr, ptr %10, align 8
  %83 = getelementptr inbounds nuw %struct.OrderItem, ptr %82, i32 0, i32 2
  store i32 %81, ptr %83, align 4
  %84 = load ptr, ptr %7, align 8
  %85 = getelementptr inbounds nuw %struct.Product, ptr %84, i32 0, i32 3
  %86 = load double, ptr %85, align 8
  %87 = load ptr, ptr %10, align 8
  %88 = getelementptr inbounds nuw %struct.OrderItem, ptr %87, i32 0, i32 3
  store double %86, ptr %88, align 8
  %89 = load i32, ptr %8, align 4
  %90 = sitofp i32 %89 to double
  %91 = load ptr, ptr %7, align 8
  %92 = getelementptr inbounds nuw %struct.Product, ptr %91, i32 0, i32 3
  %93 = load double, ptr %92, align 8
  %94 = fmul double %90, %93
  %95 = load ptr, ptr %10, align 8
  %96 = getelementptr inbounds nuw %struct.OrderItem, ptr %95, i32 0, i32 4
  store double %94, ptr %96, align 8
  %97 = load ptr, ptr %6, align 8
  %98 = load i32, ptr %97, align 4
  %99 = add nsw i32 %98, 1
  store i32 %99, ptr %97, align 4
  br label %100

100:                                              ; preds = %64, %63, %27
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @printCart(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca double, align 8
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store double 0.000000e+00, ptr %5, align 8
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.146)
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.147)
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.148)
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.147)
  store i32 0, ptr %6, align 4
  br label %11

11:                                               ; preds = %55, %2
  %12 = load i32, ptr %6, align 4
  %13 = load i32, ptr %4, align 4
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %15, label %58

15:                                               ; preds = %11
  %16 = load ptr, ptr %3, align 8
  %17 = load i32, ptr %6, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds %struct.OrderItem, ptr %16, i64 %18
  %20 = getelementptr inbounds nuw %struct.OrderItem, ptr %19, i32 0, i32 0
  %21 = load i32, ptr %20, align 8
  %22 = load ptr, ptr %3, align 8
  %23 = load i32, ptr %6, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds %struct.OrderItem, ptr %22, i64 %24
  %26 = getelementptr inbounds nuw %struct.OrderItem, ptr %25, i32 0, i32 1
  %27 = getelementptr inbounds [80 x i8], ptr %26, i64 0, i64 0
  %28 = load ptr, ptr %3, align 8
  %29 = load i32, ptr %6, align 4
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds %struct.OrderItem, ptr %28, i64 %30
  %32 = getelementptr inbounds nuw %struct.OrderItem, ptr %31, i32 0, i32 2
  %33 = load i32, ptr %32, align 4
  %34 = load ptr, ptr %3, align 8
  %35 = load i32, ptr %6, align 4
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds %struct.OrderItem, ptr %34, i64 %36
  %38 = getelementptr inbounds nuw %struct.OrderItem, ptr %37, i32 0, i32 3
  %39 = load double, ptr %38, align 8
  %40 = load ptr, ptr %3, align 8
  %41 = load i32, ptr %6, align 4
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds %struct.OrderItem, ptr %40, i64 %42
  %44 = getelementptr inbounds nuw %struct.OrderItem, ptr %43, i32 0, i32 4
  %45 = load double, ptr %44, align 8
  %46 = call i32 (ptr, ...) @printf(ptr noundef @.str.149, i32 noundef %21, ptr noundef %27, i32 noundef %33, double noundef %39, double noundef %45)
  %47 = load ptr, ptr %3, align 8
  %48 = load i32, ptr %6, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds %struct.OrderItem, ptr %47, i64 %49
  %51 = getelementptr inbounds nuw %struct.OrderItem, ptr %50, i32 0, i32 4
  %52 = load double, ptr %51, align 8
  %53 = load double, ptr %5, align 8
  %54 = fadd double %53, %52
  store double %54, ptr %5, align 8
  br label %55

55:                                               ; preds = %15
  %56 = load i32, ptr %6, align 4
  %57 = add nsw i32 %56, 1
  store i32 %57, ptr %6, align 4
  br label %11, !llvm.loop !33

58:                                               ; preds = %11
  %59 = call i32 (ptr, ...) @printf(ptr noundef @.str.147)
  %60 = call i32 (ptr, ...) @printf(ptr noundef @.str.150)
  %61 = load double, ptr %5, align 8
  call void @printMoney(double noundef %61)
  %62 = call i32 (ptr, ...) @printf(ptr noundef @.str.41)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @sanitizeField(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %38, %1
  %5 = load ptr, ptr %2, align 8
  %6 = load i32, ptr %3, align 4
  %7 = sext i32 %6 to i64
  %8 = getelementptr inbounds i8, ptr %5, i64 %7
  %9 = load i8, ptr %8, align 1
  %10 = icmp ne i8 %9, 0
  br i1 %10, label %11, label %41

11:                                               ; preds = %4
  %12 = load ptr, ptr %2, align 8
  %13 = load i32, ptr %3, align 4
  %14 = sext i32 %13 to i64
  %15 = getelementptr inbounds i8, ptr %12, i64 %14
  %16 = load i8, ptr %15, align 1
  %17 = sext i8 %16 to i32
  %18 = icmp eq i32 %17, 124
  br i1 %18, label %19, label %24

19:                                               ; preds = %11
  %20 = load ptr, ptr %2, align 8
  %21 = load i32, ptr %3, align 4
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i8, ptr %20, i64 %22
  store i8 47, ptr %23, align 1
  br label %24

24:                                               ; preds = %19, %11
  %25 = load ptr, ptr %2, align 8
  %26 = load i32, ptr %3, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds i8, ptr %25, i64 %27
  %29 = load i8, ptr %28, align 1
  %30 = zext i8 %29 to i32
  %31 = icmp slt i32 %30, 32
  br i1 %31, label %32, label %37

32:                                               ; preds = %24
  %33 = load ptr, ptr %2, align 8
  %34 = load i32, ptr %3, align 4
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds i8, ptr %33, i64 %35
  store i8 32, ptr %36, align 1
  br label %37

37:                                               ; preds = %32, %24
  br label %38

38:                                               ; preds = %37
  %39 = load i32, ptr %3, align 4
  %40 = add nsw i32 %39, 1
  store i32 %40, ptr %3, align 4
  br label %4, !llvm.loop !34

41:                                               ; preds = %4
  %42 = load ptr, ptr %2, align 8
  call void @trim(ptr noundef %42)
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal double @calculateDiscount(double noundef %0, ptr noundef %1) #0 {
  %3 = alloca double, align 8
  %4 = alloca double, align 8
  %5 = alloca ptr, align 8
  store double %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %6 = load ptr, ptr %5, align 8
  %7 = call i32 @cmpIgnoreCase(ptr noundef %6, ptr noundef @.str.134)
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %13, label %9

9:                                                ; preds = %2
  %10 = load ptr, ptr %5, align 8
  %11 = call i64 @strlen(ptr noundef %10) #8
  %12 = icmp eq i64 %11, 0
  br i1 %12, label %13, label %14

13:                                               ; preds = %9, %2
  store double 0.000000e+00, ptr %3, align 8
  br label %41

14:                                               ; preds = %9
  %15 = load ptr, ptr %5, align 8
  %16 = call i32 @cmpIgnoreCase(ptr noundef %15, ptr noundef @.str.151)
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %21

18:                                               ; preds = %14
  %19 = load double, ptr %4, align 8
  %20 = fmul double %19, 1.000000e-01
  store double %20, ptr %3, align 8
  br label %41

21:                                               ; preds = %14
  %22 = load ptr, ptr %5, align 8
  %23 = call i32 @cmpIgnoreCase(ptr noundef %22, ptr noundef @.str.152)
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %25, label %33

25:                                               ; preds = %21
  %26 = load double, ptr %4, align 8
  %27 = fcmp oge double %26, 5.000000e+02
  br i1 %27, label %28, label %31

28:                                               ; preds = %25
  %29 = load double, ptr %4, align 8
  %30 = fmul double %29, 1.500000e-01
  store double %30, ptr %3, align 8
  br label %41

31:                                               ; preds = %25
  %32 = call i32 (ptr, ...) @printf(ptr noundef @.str.153)
  store double 0.000000e+00, ptr %3, align 8
  br label %41

33:                                               ; preds = %21
  %34 = load ptr, ptr %5, align 8
  %35 = call i32 @cmpIgnoreCase(ptr noundef %34, ptr noundef @.str.154)
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %37, label %39

37:                                               ; preds = %33
  %38 = call i32 (ptr, ...) @printf(ptr noundef @.str.155)
  store double 0.000000e+00, ptr %3, align 8
  br label %41

39:                                               ; preds = %33
  %40 = call i32 (ptr, ...) @printf(ptr noundef @.str.156)
  store double 0.000000e+00, ptr %3, align 8
  br label %41

41:                                               ; preds = %39, %37, %31, %28, %18, %13
  %42 = load double, ptr %3, align 8
  ret double %42
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @cmpIgnoreCase(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  br label %8

8:                                                ; preds = %36, %2
  %9 = load ptr, ptr %4, align 8
  %10 = load i8, ptr %9, align 1
  %11 = sext i8 %10 to i32
  %12 = icmp ne i32 %11, 0
  br i1 %12, label %13, label %18

13:                                               ; preds = %8
  %14 = load ptr, ptr %5, align 8
  %15 = load i8, ptr %14, align 1
  %16 = sext i8 %15 to i32
  %17 = icmp ne i32 %16, 0
  br label %18

18:                                               ; preds = %13, %8
  %19 = phi i1 [ false, %8 ], [ %17, %13 ]
  br i1 %19, label %20, label %41

20:                                               ; preds = %18
  %21 = load ptr, ptr %4, align 8
  %22 = load i8, ptr %21, align 1
  %23 = zext i8 %22 to i32
  %24 = call i32 @tolower(i32 noundef %23) #8
  store i32 %24, ptr %6, align 4
  %25 = load ptr, ptr %5, align 8
  %26 = load i8, ptr %25, align 1
  %27 = zext i8 %26 to i32
  %28 = call i32 @tolower(i32 noundef %27) #8
  store i32 %28, ptr %7, align 4
  %29 = load i32, ptr %6, align 4
  %30 = load i32, ptr %7, align 4
  %31 = icmp ne i32 %29, %30
  br i1 %31, label %32, label %36

32:                                               ; preds = %20
  %33 = load i32, ptr %6, align 4
  %34 = load i32, ptr %7, align 4
  %35 = sub nsw i32 %33, %34
  store i32 %35, ptr %3, align 4
  br label %51

36:                                               ; preds = %20
  %37 = load ptr, ptr %4, align 8
  %38 = getelementptr inbounds nuw i8, ptr %37, i32 1
  store ptr %38, ptr %4, align 8
  %39 = load ptr, ptr %5, align 8
  %40 = getelementptr inbounds nuw i8, ptr %39, i32 1
  store ptr %40, ptr %5, align 8
  br label %8, !llvm.loop !35

41:                                               ; preds = %18
  %42 = load ptr, ptr %4, align 8
  %43 = load i8, ptr %42, align 1
  %44 = zext i8 %43 to i32
  %45 = call i32 @tolower(i32 noundef %44) #8
  %46 = load ptr, ptr %5, align 8
  %47 = load i8, ptr %46, align 1
  %48 = zext i8 %47 to i32
  %49 = call i32 @tolower(i32 noundef %48) #8
  %50 = sub nsw i32 %45, %49
  store i32 %50, ptr %3, align 4
  br label %51

51:                                               ; preds = %41, %32
  %52 = load i32, ptr %3, align 4
  ret i32 %52
}

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #4

; Function Attrs: nounwind
declare i64 @time(ptr noundef) #5

; Function Attrs: nounwind
declare ptr @localtime(ptr noundef) #5

; Function Attrs: nounwind
declare i64 @strftime(ptr noundef, i64 noundef, ptr noundef, ptr noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define internal void @addProduct() #0 {
  %1 = alloca %struct.Product, align 8
  %2 = load i32, ptr @productCount, align 4
  %3 = icmp sge i32 %2, 500
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.57, i32 noundef 500)
  br label %36

6:                                                ; preds = %0
  call void @llvm.memset.p0.i64(ptr align 8 %1, i8 0, i64 152, i1 false)
  %7 = load i32, ptr @nextProductId, align 4
  %8 = add nsw i32 %7, 1
  store i32 %8, ptr @nextProductId, align 4
  %9 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 0
  store i32 %7, ptr %9, align 8
  %10 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 6
  store i32 1, ptr %10, align 8
  br label %11

11:                                               ; preds = %6, %18
  %12 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 1
  %13 = getelementptr inbounds [80 x i8], ptr %12, i64 0, i64 0
  call void @readNonEmptyString(ptr noundef @.str.58, ptr noundef %13, i64 noundef 80)
  %14 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 1
  %15 = getelementptr inbounds [80 x i8], ptr %14, i64 0, i64 0
  %16 = call i32 @productNameExists(ptr noundef %15, i32 noundef -1)
  %17 = icmp ne i32 %16, 0
  br i1 %17, label %18, label %20

18:                                               ; preds = %11
  %19 = call i32 (ptr, ...) @printf(ptr noundef @.str.59)
  br label %11

20:                                               ; preds = %11
  br label %21

21:                                               ; preds = %20
  %22 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 2
  %23 = getelementptr inbounds [40 x i8], ptr %22, i64 0, i64 0
  call void @readNonEmptyString(ptr noundef @.str.60, ptr noundef %23, i64 noundef 40)
  %24 = call double @readDoubleRange(ptr noundef @.str.61, double noundef 1.000000e-02, double noundef 1.000000e+06)
  %25 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 3
  store double %24, ptr %25, align 8
  %26 = call i32 @readIntRange(ptr noundef @.str.62, i32 noundef 0, i32 noundef 1000000)
  %27 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 4
  store i32 %26, ptr %27, align 8
  %28 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 5
  store i32 0, ptr %28, align 4
  %29 = load i32, ptr @productCount, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr @productCount, align 4
  %31 = sext i32 %29 to i64
  %32 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %31
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %32, ptr align 8 %1, i64 152, i1 false)
  %33 = getelementptr inbounds nuw %struct.Product, ptr %1, i32 0, i32 0
  %34 = load i32, ptr %33, align 8
  %35 = call i32 (ptr, ...) @printf(ptr noundef @.str.63, i32 noundef %34)
  br label %36

36:                                               ; preds = %21, %4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @updateProduct() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca [80 x i8], align 16
  %5 = call i32 @activeProductCount()
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %0
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.67)
  br label %78

9:                                                ; preds = %0
  call void @listProducts()
  %10 = call i32 @readIntRange(ptr noundef @.str.68, i32 noundef 0, i32 noundef 2147483647)
  store i32 %10, ptr %1, align 4
  %11 = load i32, ptr %1, align 4
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %14

13:                                               ; preds = %9
  br label %78

14:                                               ; preds = %9
  %15 = load i32, ptr %1, align 4
  %16 = call i32 @findActiveProductIndexById(i32 noundef %15)
  store i32 %16, ptr %2, align 4
  %17 = load i32, ptr %2, align 4
  %18 = icmp slt i32 %17, 0
  br i1 %18, label %19, label %22

19:                                               ; preds = %14
  %20 = load i32, ptr %1, align 4
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.69, i32 noundef %20)
  br label %78

22:                                               ; preds = %14
  %23 = load i32, ptr %2, align 4
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %24
  store ptr %25, ptr %3, align 8
  %26 = load ptr, ptr %3, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 1
  %28 = getelementptr inbounds [80 x i8], ptr %27, i64 0, i64 0
  %29 = call i32 (ptr, ...) @printf(ptr noundef @.str.70, ptr noundef %28)
  %30 = call i32 (ptr, ...) @printf(ptr noundef @.str.71)
  %31 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  call void @readLine(ptr noundef @.str.72, ptr noundef %31, i64 noundef 80)
  %32 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  call void @sanitizeField(ptr noundef %32)
  %33 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  %34 = call i64 @strlen(ptr noundef %33) #8
  %35 = icmp ugt i64 %34, 0
  br i1 %35, label %36, label %51

36:                                               ; preds = %22
  %37 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  %38 = load ptr, ptr %3, align 8
  %39 = getelementptr inbounds nuw %struct.Product, ptr %38, i32 0, i32 0
  %40 = load i32, ptr %39, align 8
  %41 = call i32 @productNameExists(ptr noundef %37, i32 noundef %40)
  %42 = icmp ne i32 %41, 0
  br i1 %42, label %43, label %45

43:                                               ; preds = %36
  %44 = call i32 (ptr, ...) @printf(ptr noundef @.str.73)
  br label %50

45:                                               ; preds = %36
  %46 = load ptr, ptr %3, align 8
  %47 = getelementptr inbounds nuw %struct.Product, ptr %46, i32 0, i32 1
  %48 = getelementptr inbounds [80 x i8], ptr %47, i64 0, i64 0
  %49 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  call void @safeCopy(ptr noundef %48, ptr noundef %49, i64 noundef 80)
  br label %50

50:                                               ; preds = %45, %43
  br label %51

51:                                               ; preds = %50, %22
  %52 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  call void @readLine(ptr noundef @.str.74, ptr noundef %52, i64 noundef 80)
  %53 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  call void @sanitizeField(ptr noundef %53)
  %54 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  %55 = call i64 @strlen(ptr noundef %54) #8
  %56 = icmp ugt i64 %55, 0
  br i1 %56, label %57, label %62

57:                                               ; preds = %51
  %58 = load ptr, ptr %3, align 8
  %59 = getelementptr inbounds nuw %struct.Product, ptr %58, i32 0, i32 2
  %60 = getelementptr inbounds [40 x i8], ptr %59, i64 0, i64 0
  %61 = getelementptr inbounds [80 x i8], ptr %4, i64 0, i64 0
  call void @safeCopy(ptr noundef %60, ptr noundef %61, i64 noundef 40)
  br label %62

62:                                               ; preds = %57, %51
  %63 = call i32 @askYesNo(ptr noundef @.str.75)
  %64 = icmp ne i32 %63, 0
  br i1 %64, label %65, label %69

65:                                               ; preds = %62
  %66 = call double @readDoubleRange(ptr noundef @.str.76, double noundef 1.000000e-02, double noundef 1.000000e+06)
  %67 = load ptr, ptr %3, align 8
  %68 = getelementptr inbounds nuw %struct.Product, ptr %67, i32 0, i32 3
  store double %66, ptr %68, align 8
  br label %69

69:                                               ; preds = %65, %62
  %70 = call i32 @askYesNo(ptr noundef @.str.77)
  %71 = icmp ne i32 %70, 0
  br i1 %71, label %72, label %76

72:                                               ; preds = %69
  %73 = call i32 @readIntRange(ptr noundef @.str.78, i32 noundef 0, i32 noundef 1000000)
  %74 = load ptr, ptr %3, align 8
  %75 = getelementptr inbounds nuw %struct.Product, ptr %74, i32 0, i32 4
  store i32 %73, ptr %75, align 8
  br label %76

76:                                               ; preds = %72, %69
  %77 = call i32 (ptr, ...) @printf(ptr noundef @.str.79)
  br label %78

78:                                               ; preds = %76, %19, %13, %7
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @restockProduct() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = call i32 @activeProductCount()
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %0
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.81)
  br label %51

8:                                                ; preds = %0
  call void @listProducts()
  %9 = call i32 @readIntRange(ptr noundef @.str.82, i32 noundef 0, i32 noundef 2147483647)
  store i32 %9, ptr %1, align 4
  %10 = load i32, ptr %1, align 4
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %13

12:                                               ; preds = %8
  br label %51

13:                                               ; preds = %8
  %14 = load i32, ptr %1, align 4
  %15 = call i32 @findActiveProductIndexById(i32 noundef %14)
  store i32 %15, ptr %2, align 4
  %16 = load i32, ptr %2, align 4
  %17 = icmp slt i32 %16, 0
  br i1 %17, label %18, label %20

18:                                               ; preds = %13
  %19 = call i32 (ptr, ...) @printf(ptr noundef @.str.83)
  br label %51

20:                                               ; preds = %13
  %21 = call i32 @readIntRange(ptr noundef @.str.84, i32 noundef 1, i32 noundef 1000000)
  store i32 %21, ptr %3, align 4
  %22 = load i32, ptr %2, align 4
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %23
  %25 = getelementptr inbounds nuw %struct.Product, ptr %24, i32 0, i32 4
  %26 = load i32, ptr %25, align 8
  %27 = load i32, ptr %3, align 4
  %28 = sub nsw i32 2147483647, %27
  %29 = icmp sgt i32 %26, %28
  br i1 %29, label %30, label %32

30:                                               ; preds = %20
  %31 = call i32 (ptr, ...) @printf(ptr noundef @.str.85)
  br label %51

32:                                               ; preds = %20
  %33 = load i32, ptr %3, align 4
  %34 = load i32, ptr %2, align 4
  %35 = sext i32 %34 to i64
  %36 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %35
  %37 = getelementptr inbounds nuw %struct.Product, ptr %36, i32 0, i32 4
  %38 = load i32, ptr %37, align 8
  %39 = add nsw i32 %38, %33
  store i32 %39, ptr %37, align 8
  %40 = load i32, ptr %2, align 4
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %41
  %43 = getelementptr inbounds nuw %struct.Product, ptr %42, i32 0, i32 1
  %44 = getelementptr inbounds [80 x i8], ptr %43, i64 0, i64 0
  %45 = load i32, ptr %2, align 4
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %46
  %48 = getelementptr inbounds nuw %struct.Product, ptr %47, i32 0, i32 4
  %49 = load i32, ptr %48, align 8
  %50 = call i32 (ptr, ...) @printf(ptr noundef @.str.86, ptr noundef %44, i32 noundef %49)
  br label %51

51:                                               ; preds = %32, %30, %18, %12, %6
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @deleteProduct() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = call i32 @activeProductCount()
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  %6 = call i32 (ptr, ...) @printf(ptr noundef @.str.87)
  br label %35

7:                                                ; preds = %0
  call void @listProducts()
  %8 = call i32 @readIntRange(ptr noundef @.str.88, i32 noundef 0, i32 noundef 2147483647)
  store i32 %8, ptr %1, align 4
  %9 = load i32, ptr %1, align 4
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %12

11:                                               ; preds = %7
  br label %35

12:                                               ; preds = %7
  %13 = load i32, ptr %1, align 4
  %14 = call i32 @findActiveProductIndexById(i32 noundef %13)
  store i32 %14, ptr %2, align 4
  %15 = load i32, ptr %2, align 4
  %16 = icmp slt i32 %15, 0
  br i1 %16, label %17, label %19

17:                                               ; preds = %12
  %18 = call i32 (ptr, ...) @printf(ptr noundef @.str.89)
  br label %35

19:                                               ; preds = %12
  %20 = load i32, ptr %1, align 4
  %21 = call i32 @productUsedInPaidOrder(i32 noundef %20)
  %22 = icmp ne i32 %21, 0
  br i1 %22, label %23, label %25

23:                                               ; preds = %19
  %24 = call i32 (ptr, ...) @printf(ptr noundef @.str.90)
  br label %25

25:                                               ; preds = %23, %19
  %26 = call i32 @askYesNo(ptr noundef @.str.91)
  %27 = icmp ne i32 %26, 0
  br i1 %27, label %29, label %28

28:                                               ; preds = %25
  br label %35

29:                                               ; preds = %25
  %30 = load i32, ptr %2, align 4
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %31
  %33 = getelementptr inbounds nuw %struct.Product, ptr %32, i32 0, i32 6
  store i32 0, ptr %33, align 8
  %34 = call i32 (ptr, ...) @printf(ptr noundef @.str.92)
  br label %35

35:                                               ; preds = %29, %28, %17, %11, %5
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @searchProducts() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca [80 x i8], align 16
  %4 = alloca double, align 8
  %5 = alloca double, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca double, align 8
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = call i32 @activeProductCount()
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %16

14:                                               ; preds = %0
  %15 = call i32 (ptr, ...) @printf(ptr noundef @.str.93)
  br label %178

16:                                               ; preds = %0
  %17 = call i32 (ptr, ...) @printf(ptr noundef @.str.94)
  %18 = call i32 (ptr, ...) @printf(ptr noundef @.str.95)
  %19 = call i32 (ptr, ...) @printf(ptr noundef @.str.96)
  %20 = call i32 (ptr, ...) @printf(ptr noundef @.str.97)
  %21 = call i32 (ptr, ...) @printf(ptr noundef @.str.98)
  %22 = call i32 @readIntRange(ptr noundef @.str.20, i32 noundef 1, i32 noundef 4)
  store i32 %22, ptr %1, align 4
  store i32 0, ptr %2, align 4
  call void @printProductHeader()
  %23 = load i32, ptr %1, align 4
  %24 = icmp eq i32 %23, 1
  br i1 %24, label %25, label %56

25:                                               ; preds = %16
  %26 = getelementptr inbounds [80 x i8], ptr %3, i64 0, i64 0
  call void @readNonEmptyString(ptr noundef @.str.99, ptr noundef %26, i64 noundef 80)
  store i32 0, ptr %7, align 4
  br label %27

27:                                               ; preds = %52, %25
  %28 = load i32, ptr %7, align 4
  %29 = load i32, ptr @productCount, align 4
  %30 = icmp slt i32 %28, %29
  br i1 %30, label %31, label %55

31:                                               ; preds = %27
  %32 = load i32, ptr %7, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %33
  %35 = getelementptr inbounds nuw %struct.Product, ptr %34, i32 0, i32 6
  %36 = load i32, ptr %35, align 8
  %37 = icmp ne i32 %36, 0
  br i1 %37, label %38, label %51

38:                                               ; preds = %31
  %39 = load i32, ptr %7, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %40
  %42 = getelementptr inbounds nuw %struct.Product, ptr %41, i32 0, i32 1
  %43 = getelementptr inbounds [80 x i8], ptr %42, i64 0, i64 0
  %44 = getelementptr inbounds [80 x i8], ptr %3, i64 0, i64 0
  %45 = call i32 @containsIgnoreCase(ptr noundef %43, ptr noundef %44)
  %46 = icmp ne i32 %45, 0
  br i1 %46, label %47, label %51

47:                                               ; preds = %38
  %48 = load i32, ptr %7, align 4
  %49 = sext i32 %48 to i64
  %50 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %49
  call void @printProductRow(ptr noundef %50)
  store i32 1, ptr %2, align 4
  br label %51

51:                                               ; preds = %47, %38, %31
  br label %52

52:                                               ; preds = %51
  %53 = load i32, ptr %7, align 4
  %54 = add nsw i32 %53, 1
  store i32 %54, ptr %7, align 4
  br label %27, !llvm.loop !36

55:                                               ; preds = %27
  br label %173

56:                                               ; preds = %16
  %57 = load i32, ptr %1, align 4
  %58 = icmp eq i32 %57, 2
  br i1 %58, label %59, label %90

59:                                               ; preds = %56
  %60 = getelementptr inbounds [80 x i8], ptr %3, i64 0, i64 0
  call void @readNonEmptyString(ptr noundef @.str.100, ptr noundef %60, i64 noundef 80)
  store i32 0, ptr %8, align 4
  br label %61

61:                                               ; preds = %86, %59
  %62 = load i32, ptr %8, align 4
  %63 = load i32, ptr @productCount, align 4
  %64 = icmp slt i32 %62, %63
  br i1 %64, label %65, label %89

65:                                               ; preds = %61
  %66 = load i32, ptr %8, align 4
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %67
  %69 = getelementptr inbounds nuw %struct.Product, ptr %68, i32 0, i32 6
  %70 = load i32, ptr %69, align 8
  %71 = icmp ne i32 %70, 0
  br i1 %71, label %72, label %85

72:                                               ; preds = %65
  %73 = load i32, ptr %8, align 4
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %74
  %76 = getelementptr inbounds nuw %struct.Product, ptr %75, i32 0, i32 2
  %77 = getelementptr inbounds [40 x i8], ptr %76, i64 0, i64 0
  %78 = getelementptr inbounds [80 x i8], ptr %3, i64 0, i64 0
  %79 = call i32 @containsIgnoreCase(ptr noundef %77, ptr noundef %78)
  %80 = icmp ne i32 %79, 0
  br i1 %80, label %81, label %85

81:                                               ; preds = %72
  %82 = load i32, ptr %8, align 4
  %83 = sext i32 %82 to i64
  %84 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %83
  call void @printProductRow(ptr noundef %84)
  store i32 1, ptr %2, align 4
  br label %85

85:                                               ; preds = %81, %72, %65
  br label %86

86:                                               ; preds = %85
  %87 = load i32, ptr %8, align 4
  %88 = add nsw i32 %87, 1
  store i32 %88, ptr %8, align 4
  br label %61, !llvm.loop !37

89:                                               ; preds = %61
  br label %172

90:                                               ; preds = %56
  %91 = load i32, ptr %1, align 4
  %92 = icmp eq i32 %91, 3
  br i1 %92, label %93, label %141

93:                                               ; preds = %90
  %94 = call double @readDoubleRange(ptr noundef @.str.101, double noundef 0.000000e+00, double noundef 1.000000e+06)
  store double %94, ptr %4, align 8
  %95 = call double @readDoubleRange(ptr noundef @.str.102, double noundef 0.000000e+00, double noundef 1.000000e+06)
  store double %95, ptr %5, align 8
  %96 = load double, ptr %4, align 8
  %97 = load double, ptr %5, align 8
  %98 = fcmp ogt double %96, %97
  br i1 %98, label %99, label %104

99:                                               ; preds = %93
  %100 = load double, ptr %4, align 8
  store double %100, ptr %9, align 8
  %101 = load double, ptr %5, align 8
  store double %101, ptr %4, align 8
  %102 = load double, ptr %9, align 8
  store double %102, ptr %5, align 8
  %103 = call i32 (ptr, ...) @printf(ptr noundef @.str.103)
  br label %104

104:                                              ; preds = %99, %93
  store i32 0, ptr %10, align 4
  br label %105

105:                                              ; preds = %137, %104
  %106 = load i32, ptr %10, align 4
  %107 = load i32, ptr @productCount, align 4
  %108 = icmp slt i32 %106, %107
  br i1 %108, label %109, label %140

109:                                              ; preds = %105
  %110 = load i32, ptr %10, align 4
  %111 = sext i32 %110 to i64
  %112 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %111
  %113 = getelementptr inbounds nuw %struct.Product, ptr %112, i32 0, i32 6
  %114 = load i32, ptr %113, align 8
  %115 = icmp ne i32 %114, 0
  br i1 %115, label %116, label %136

116:                                              ; preds = %109
  %117 = load i32, ptr %10, align 4
  %118 = sext i32 %117 to i64
  %119 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %118
  %120 = getelementptr inbounds nuw %struct.Product, ptr %119, i32 0, i32 3
  %121 = load double, ptr %120, align 8
  %122 = load double, ptr %4, align 8
  %123 = fcmp oge double %121, %122
  br i1 %123, label %124, label %136

124:                                              ; preds = %116
  %125 = load i32, ptr %10, align 4
  %126 = sext i32 %125 to i64
  %127 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %126
  %128 = getelementptr inbounds nuw %struct.Product, ptr %127, i32 0, i32 3
  %129 = load double, ptr %128, align 8
  %130 = load double, ptr %5, align 8
  %131 = fcmp ole double %129, %130
  br i1 %131, label %132, label %136

132:                                              ; preds = %124
  %133 = load i32, ptr %10, align 4
  %134 = sext i32 %133 to i64
  %135 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %134
  call void @printProductRow(ptr noundef %135)
  store i32 1, ptr %2, align 4
  br label %136

136:                                              ; preds = %132, %124, %116, %109
  br label %137

137:                                              ; preds = %136
  %138 = load i32, ptr %10, align 4
  %139 = add nsw i32 %138, 1
  store i32 %139, ptr %10, align 4
  br label %105, !llvm.loop !38

140:                                              ; preds = %105
  br label %171

141:                                              ; preds = %90
  %142 = call i32 @readIntRange(ptr noundef @.str.104, i32 noundef 0, i32 noundef 1000000)
  store i32 %142, ptr %6, align 4
  store i32 0, ptr %11, align 4
  br label %143

143:                                              ; preds = %167, %141
  %144 = load i32, ptr %11, align 4
  %145 = load i32, ptr @productCount, align 4
  %146 = icmp slt i32 %144, %145
  br i1 %146, label %147, label %170

147:                                              ; preds = %143
  %148 = load i32, ptr %11, align 4
  %149 = sext i32 %148 to i64
  %150 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %149
  %151 = getelementptr inbounds nuw %struct.Product, ptr %150, i32 0, i32 6
  %152 = load i32, ptr %151, align 8
  %153 = icmp ne i32 %152, 0
  br i1 %153, label %154, label %166

154:                                              ; preds = %147
  %155 = load i32, ptr %11, align 4
  %156 = sext i32 %155 to i64
  %157 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %156
  %158 = getelementptr inbounds nuw %struct.Product, ptr %157, i32 0, i32 4
  %159 = load i32, ptr %158, align 8
  %160 = load i32, ptr %6, align 4
  %161 = icmp sle i32 %159, %160
  br i1 %161, label %162, label %166

162:                                              ; preds = %154
  %163 = load i32, ptr %11, align 4
  %164 = sext i32 %163 to i64
  %165 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %164
  call void @printProductRow(ptr noundef %165)
  store i32 1, ptr %2, align 4
  br label %166

166:                                              ; preds = %162, %154, %147
  br label %167

167:                                              ; preds = %166
  %168 = load i32, ptr %11, align 4
  %169 = add nsw i32 %168, 1
  store i32 %169, ptr %11, align 4
  br label %143, !llvm.loop !39

170:                                              ; preds = %143
  br label %171

171:                                              ; preds = %170, %140
  br label %172

172:                                              ; preds = %171, %89
  br label %173

173:                                              ; preds = %172, %55
  call void @printProductFooter()
  %174 = load i32, ptr %2, align 4
  %175 = icmp ne i32 %174, 0
  br i1 %175, label %178, label %176

176:                                              ; preds = %173
  %177 = call i32 (ptr, ...) @printf(ptr noundef @.str.105)
  br label %178

178:                                              ; preds = %14, %176, %173
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @sortProductsMenu() #0 {
  %1 = alloca i32, align 4
  %2 = load i32, ptr @productCount, align 4
  %3 = icmp sle i32 %2, 1
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = call i32 (ptr, ...) @printf(ptr noundef @.str.106)
  br label %37

6:                                                ; preds = %0
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.107)
  %8 = call i32 (ptr, ...) @printf(ptr noundef @.str.108)
  %9 = call i32 (ptr, ...) @printf(ptr noundef @.str.109)
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.110)
  %11 = call i32 (ptr, ...) @printf(ptr noundef @.str.111)
  %12 = call i32 @readIntRange(ptr noundef @.str.20, i32 noundef 1, i32 noundef 4)
  store i32 %12, ptr %1, align 4
  %13 = load i32, ptr %1, align 4
  %14 = icmp eq i32 %13, 1
  br i1 %14, label %15, label %18

15:                                               ; preds = %6
  %16 = load i32, ptr @productCount, align 4
  %17 = sext i32 %16 to i64
  call void @qsort(ptr noundef @products, i64 noundef %17, i64 noundef 152, ptr noundef @cmpProductName)
  br label %35

18:                                               ; preds = %6
  %19 = load i32, ptr %1, align 4
  %20 = icmp eq i32 %19, 2
  br i1 %20, label %21, label %24

21:                                               ; preds = %18
  %22 = load i32, ptr @productCount, align 4
  %23 = sext i32 %22 to i64
  call void @qsort(ptr noundef @products, i64 noundef %23, i64 noundef 152, ptr noundef @cmpProductPriceAsc)
  br label %34

24:                                               ; preds = %18
  %25 = load i32, ptr %1, align 4
  %26 = icmp eq i32 %25, 3
  br i1 %26, label %27, label %30

27:                                               ; preds = %24
  %28 = load i32, ptr @productCount, align 4
  %29 = sext i32 %28 to i64
  call void @qsort(ptr noundef @products, i64 noundef %29, i64 noundef 152, ptr noundef @cmpProductStockAsc)
  br label %33

30:                                               ; preds = %24
  %31 = load i32, ptr @productCount, align 4
  %32 = sext i32 %31 to i64
  call void @qsort(ptr noundef @products, i64 noundef %32, i64 noundef 152, ptr noundef @cmpProductSoldDesc)
  br label %33

33:                                               ; preds = %30, %27
  br label %34

34:                                               ; preds = %33, %21
  br label %35

35:                                               ; preds = %34, %15
  %36 = call i32 (ptr, ...) @printf(ptr noundef @.str.112)
  call void @listProducts()
  br label %37

37:                                               ; preds = %35, %4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @cmpProductName(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %7 = load ptr, ptr %3, align 8
  store ptr %7, ptr %5, align 8
  %8 = load ptr, ptr %4, align 8
  store ptr %8, ptr %6, align 8
  %9 = load ptr, ptr %5, align 8
  %10 = getelementptr inbounds nuw %struct.Product, ptr %9, i32 0, i32 1
  %11 = getelementptr inbounds [80 x i8], ptr %10, i64 0, i64 0
  %12 = load ptr, ptr %6, align 8
  %13 = getelementptr inbounds nuw %struct.Product, ptr %12, i32 0, i32 1
  %14 = getelementptr inbounds [80 x i8], ptr %13, i64 0, i64 0
  %15 = call i32 @cmpIgnoreCase(ptr noundef %11, ptr noundef %14)
  ret i32 %15
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @cmpProductPriceAsc(ptr noundef %0, ptr noundef %1) #0 {
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
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 3
  %12 = load double, ptr %11, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 3
  %15 = load double, ptr %14, align 8
  %16 = fcmp olt double %12, %15
  br i1 %16, label %17, label %18

17:                                               ; preds = %2
  store i32 -1, ptr %3, align 4
  br label %35

18:                                               ; preds = %2
  %19 = load ptr, ptr %6, align 8
  %20 = getelementptr inbounds nuw %struct.Product, ptr %19, i32 0, i32 3
  %21 = load double, ptr %20, align 8
  %22 = load ptr, ptr %7, align 8
  %23 = getelementptr inbounds nuw %struct.Product, ptr %22, i32 0, i32 3
  %24 = load double, ptr %23, align 8
  %25 = fcmp ogt double %21, %24
  br i1 %25, label %26, label %27

26:                                               ; preds = %18
  store i32 1, ptr %3, align 4
  br label %35

27:                                               ; preds = %18
  %28 = load ptr, ptr %6, align 8
  %29 = getelementptr inbounds nuw %struct.Product, ptr %28, i32 0, i32 0
  %30 = load i32, ptr %29, align 8
  %31 = load ptr, ptr %7, align 8
  %32 = getelementptr inbounds nuw %struct.Product, ptr %31, i32 0, i32 0
  %33 = load i32, ptr %32, align 8
  %34 = sub nsw i32 %30, %33
  store i32 %34, ptr %3, align 4
  br label %35

35:                                               ; preds = %27, %26, %17
  %36 = load i32, ptr %3, align 4
  ret i32 %36
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @cmpProductStockAsc(ptr noundef %0, ptr noundef %1) #0 {
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
  %11 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 4
  %12 = load i32, ptr %11, align 8
  %13 = load ptr, ptr %7, align 8
  %14 = getelementptr inbounds nuw %struct.Product, ptr %13, i32 0, i32 4
  %15 = load i32, ptr %14, align 8
  %16 = icmp ne i32 %12, %15
  br i1 %16, label %17, label %25

17:                                               ; preds = %2
  %18 = load ptr, ptr %6, align 8
  %19 = getelementptr inbounds nuw %struct.Product, ptr %18, i32 0, i32 4
  %20 = load i32, ptr %19, align 8
  %21 = load ptr, ptr %7, align 8
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 4
  %23 = load i32, ptr %22, align 8
  %24 = sub nsw i32 %20, %23
  store i32 %24, ptr %3, align 4
  br label %33

25:                                               ; preds = %2
  %26 = load ptr, ptr %6, align 8
  %27 = getelementptr inbounds nuw %struct.Product, ptr %26, i32 0, i32 0
  %28 = load i32, ptr %27, align 8
  %29 = load ptr, ptr %7, align 8
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 0
  %31 = load i32, ptr %30, align 8
  %32 = sub nsw i32 %28, %31
  store i32 %32, ptr %3, align 4
  br label %33

33:                                               ; preds = %25, %17
  %34 = load i32, ptr %3, align 4
  ret i32 %34
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @containsIgnoreCase(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64, align 8
  %9 = alloca i64, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  %10 = load ptr, ptr %4, align 8
  %11 = icmp ne ptr %10, null
  br i1 %11, label %12, label %15

12:                                               ; preds = %2
  %13 = load ptr, ptr %5, align 8
  %14 = icmp ne ptr %13, null
  br i1 %14, label %16, label %15

15:                                               ; preds = %12, %2
  store i32 0, ptr %3, align 4
  br label %73

16:                                               ; preds = %12
  %17 = load ptr, ptr %5, align 8
  %18 = load i8, ptr %17, align 1
  %19 = icmp ne i8 %18, 0
  br i1 %19, label %21, label %20

20:                                               ; preds = %16
  store i32 1, ptr %3, align 4
  br label %73

21:                                               ; preds = %16
  %22 = load ptr, ptr %4, align 8
  %23 = call i64 @strlen(ptr noundef %22) #8
  store i64 %23, ptr %6, align 8
  %24 = load ptr, ptr %5, align 8
  %25 = call i64 @strlen(ptr noundef %24) #8
  store i64 %25, ptr %7, align 8
  %26 = load i64, ptr %7, align 8
  %27 = load i64, ptr %6, align 8
  %28 = icmp ugt i64 %26, %27
  br i1 %28, label %29, label %30

29:                                               ; preds = %21
  store i32 0, ptr %3, align 4
  br label %73

30:                                               ; preds = %21
  store i64 0, ptr %8, align 8
  br label %31

31:                                               ; preds = %69, %30
  %32 = load i64, ptr %8, align 8
  %33 = load i64, ptr %7, align 8
  %34 = add i64 %32, %33
  %35 = load i64, ptr %6, align 8
  %36 = icmp ule i64 %34, %35
  br i1 %36, label %37, label %72

37:                                               ; preds = %31
  store i64 0, ptr %9, align 8
  br label %38

38:                                               ; preds = %60, %37
  %39 = load i64, ptr %9, align 8
  %40 = load i64, ptr %7, align 8
  %41 = icmp ult i64 %39, %40
  br i1 %41, label %42, label %58

42:                                               ; preds = %38
  %43 = load ptr, ptr %4, align 8
  %44 = load i64, ptr %8, align 8
  %45 = load i64, ptr %9, align 8
  %46 = add i64 %44, %45
  %47 = getelementptr inbounds nuw i8, ptr %43, i64 %46
  %48 = load i8, ptr %47, align 1
  %49 = zext i8 %48 to i32
  %50 = call i32 @tolower(i32 noundef %49) #8
  %51 = load ptr, ptr %5, align 8
  %52 = load i64, ptr %9, align 8
  %53 = getelementptr inbounds nuw i8, ptr %51, i64 %52
  %54 = load i8, ptr %53, align 1
  %55 = zext i8 %54 to i32
  %56 = call i32 @tolower(i32 noundef %55) #8
  %57 = icmp eq i32 %50, %56
  br label %58

58:                                               ; preds = %42, %38
  %59 = phi i1 [ false, %38 ], [ %57, %42 ]
  br i1 %59, label %60, label %63

60:                                               ; preds = %58
  %61 = load i64, ptr %9, align 8
  %62 = add i64 %61, 1
  store i64 %62, ptr %9, align 8
  br label %38, !llvm.loop !40

63:                                               ; preds = %58
  %64 = load i64, ptr %9, align 8
  %65 = load i64, ptr %7, align 8
  %66 = icmp eq i64 %64, %65
  br i1 %66, label %67, label %68

67:                                               ; preds = %63
  store i32 1, ptr %3, align 4
  br label %73

68:                                               ; preds = %63
  br label %69

69:                                               ; preds = %68
  %70 = load i64, ptr %8, align 8
  %71 = add i64 %70, 1
  store i64 %71, ptr %8, align 8
  br label %31, !llvm.loop !41

72:                                               ; preds = %31
  store i32 0, ptr %3, align 4
  br label %73

73:                                               ; preds = %72, %67, %29, %20, %15
  %74 = load i32, ptr %3, align 4
  ret i32 %74
}

; Function Attrs: noinline nounwind optnone uwtable
define internal double @readDoubleRange(ptr noundef %0, double noundef %1, double noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca double, align 8
  %6 = alloca double, align 8
  %7 = alloca [128 x i8], align 16
  %8 = alloca double, align 8
  store ptr %0, ptr %4, align 8
  store double %1, ptr %5, align 8
  store double %2, ptr %6, align 8
  br label %9

9:                                                ; preds = %3, %15, %25
  %10 = load ptr, ptr %4, align 8
  %11 = getelementptr inbounds [128 x i8], ptr %7, i64 0, i64 0
  call void @readLine(ptr noundef %10, ptr noundef %11, i64 noundef 128)
  %12 = getelementptr inbounds [128 x i8], ptr %7, i64 0, i64 0
  %13 = call i32 @parseDoubleStrict(ptr noundef %12, ptr noundef %8)
  %14 = icmp ne i32 %13, 0
  br i1 %14, label %17, label %15

15:                                               ; preds = %9
  %16 = call i32 (ptr, ...) @printf(ptr noundef @.str.65)
  br label %9

17:                                               ; preds = %9
  %18 = load double, ptr %8, align 8
  %19 = load double, ptr %5, align 8
  %20 = fcmp olt double %18, %19
  br i1 %20, label %25, label %21

21:                                               ; preds = %17
  %22 = load double, ptr %8, align 8
  %23 = load double, ptr %6, align 8
  %24 = fcmp ogt double %22, %23
  br i1 %24, label %25, label %29

25:                                               ; preds = %21, %17
  %26 = load double, ptr %5, align 8
  %27 = load double, ptr %6, align 8
  %28 = call i32 (ptr, ...) @printf(ptr noundef @.str.66, double noundef %26, double noundef %27)
  br label %9

29:                                               ; preds = %21
  %30 = load double, ptr %8, align 8
  ret double %30
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @parseDoubleStrict(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca double, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr null, ptr %6, align 8
  %8 = call ptr @__errno_location() #10
  store i32 0, ptr %8, align 4
  %9 = load ptr, ptr %4, align 8
  %10 = icmp ne ptr %9, null
  br i1 %10, label %11, label %15

11:                                               ; preds = %2
  %12 = load ptr, ptr %4, align 8
  %13 = load i8, ptr %12, align 1
  %14 = icmp ne i8 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %11, %2
  store i32 0, ptr %3, align 4
  br label %51

16:                                               ; preds = %11
  %17 = load ptr, ptr %4, align 8
  %18 = call double @strtod(ptr noundef %17, ptr noundef %6) #9
  store double %18, ptr %7, align 8
  %19 = call ptr @__errno_location() #10
  %20 = load i32, ptr %19, align 4
  %21 = icmp ne i32 %20, 0
  br i1 %21, label %26, label %22

22:                                               ; preds = %16
  %23 = load ptr, ptr %6, align 8
  %24 = load ptr, ptr %4, align 8
  %25 = icmp eq ptr %23, %24
  br i1 %25, label %26, label %27

26:                                               ; preds = %22, %16
  store i32 0, ptr %3, align 4
  br label %51

27:                                               ; preds = %22
  br label %28

28:                                               ; preds = %45, %27
  %29 = load ptr, ptr %6, align 8
  %30 = load i8, ptr %29, align 1
  %31 = icmp ne i8 %30, 0
  br i1 %31, label %32, label %48

32:                                               ; preds = %28
  %33 = call ptr @__ctype_b_loc() #10
  %34 = load ptr, ptr %33, align 8
  %35 = load ptr, ptr %6, align 8
  %36 = load i8, ptr %35, align 1
  %37 = zext i8 %36 to i32
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds i16, ptr %34, i64 %38
  %40 = load i16, ptr %39, align 2
  %41 = zext i16 %40 to i32
  %42 = and i32 %41, 8192
  %43 = icmp ne i32 %42, 0
  br i1 %43, label %45, label %44

44:                                               ; preds = %32
  store i32 0, ptr %3, align 4
  br label %51

45:                                               ; preds = %32
  %46 = load ptr, ptr %6, align 8
  %47 = getelementptr inbounds nuw i8, ptr %46, i32 1
  store ptr %47, ptr %6, align 8
  br label %28, !llvm.loop !42

48:                                               ; preds = %28
  %49 = load double, ptr %7, align 8
  %50 = load ptr, ptr %5, align 8
  store double %49, ptr %50, align 8
  store i32 1, ptr %3, align 4
  br label %51

51:                                               ; preds = %48, %44, %26, %15
  %52 = load i32, ptr %3, align 4
  ret i32 %52
}

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__errno_location() #6

; Function Attrs: nounwind
declare double @strtod(ptr noundef, ptr noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @productUsedInPaidOrder(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 0, ptr %4, align 4
  br label %6

6:                                                ; preds = %46, %1
  %7 = load i32, ptr %4, align 4
  %8 = load i32, ptr @orderCount, align 4
  %9 = icmp slt i32 %7, %8
  br i1 %9, label %10, label %49

10:                                               ; preds = %6
  %11 = load i32, ptr %4, align 4
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %12
  %14 = getelementptr inbounds nuw %struct.Order, ptr %13, i32 0, i32 8
  %15 = getelementptr inbounds [16 x i8], ptr %14, i64 0, i64 0
  %16 = call i32 @strcmp(ptr noundef %15, ptr noundef @.str.35) #8
  %17 = icmp ne i32 %16, 0
  br i1 %17, label %18, label %19

18:                                               ; preds = %10
  br label %46

19:                                               ; preds = %10
  store i32 0, ptr %5, align 4
  br label %20

20:                                               ; preds = %42, %19
  %21 = load i32, ptr %5, align 4
  %22 = load i32, ptr %4, align 4
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %23
  %25 = getelementptr inbounds nuw %struct.Order, ptr %24, i32 0, i32 2
  %26 = load i32, ptr %25, align 4
  %27 = icmp slt i32 %21, %26
  br i1 %27, label %28, label %45

28:                                               ; preds = %20
  %29 = load i32, ptr %4, align 4
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %30
  %32 = getelementptr inbounds nuw %struct.Order, ptr %31, i32 0, i32 3
  %33 = load i32, ptr %5, align 4
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds [32 x %struct.OrderItem], ptr %32, i64 0, i64 %34
  %36 = getelementptr inbounds nuw %struct.OrderItem, ptr %35, i32 0, i32 0
  %37 = load i32, ptr %36, align 8
  %38 = load i32, ptr %3, align 4
  %39 = icmp eq i32 %37, %38
  br i1 %39, label %40, label %41

40:                                               ; preds = %28
  store i32 1, ptr %2, align 4
  br label %50

41:                                               ; preds = %28
  br label %42

42:                                               ; preds = %41
  %43 = load i32, ptr %5, align 4
  %44 = add nsw i32 %43, 1
  store i32 %44, ptr %5, align 4
  br label %20, !llvm.loop !43

45:                                               ; preds = %20
  br label %46

46:                                               ; preds = %45, %18
  %47 = load i32, ptr %4, align 4
  %48 = add nsw i32 %47, 1
  store i32 %48, ptr %4, align 4
  br label %6, !llvm.loop !44

49:                                               ; preds = %6
  store i32 0, ptr %2, align 4
  br label %50

50:                                               ; preds = %49, %40
  %51 = load i32, ptr %2, align 4
  ret i32 %51
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @productNameExists(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %7

7:                                                ; preds = %37, %2
  %8 = load i32, ptr %6, align 4
  %9 = load i32, ptr @productCount, align 4
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %11, label %40

11:                                               ; preds = %7
  %12 = load i32, ptr %6, align 4
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %13
  %15 = getelementptr inbounds nuw %struct.Product, ptr %14, i32 0, i32 6
  %16 = load i32, ptr %15, align 8
  %17 = icmp ne i32 %16, 0
  br i1 %17, label %18, label %36

18:                                               ; preds = %11
  %19 = load i32, ptr %6, align 4
  %20 = sext i32 %19 to i64
  %21 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %20
  %22 = getelementptr inbounds nuw %struct.Product, ptr %21, i32 0, i32 0
  %23 = load i32, ptr %22, align 8
  %24 = load i32, ptr %5, align 4
  %25 = icmp ne i32 %23, %24
  br i1 %25, label %26, label %36

26:                                               ; preds = %18
  %27 = load i32, ptr %6, align 4
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %28
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 1
  %31 = getelementptr inbounds [80 x i8], ptr %30, i64 0, i64 0
  %32 = load ptr, ptr %4, align 8
  %33 = call i32 @cmpIgnoreCase(ptr noundef %31, ptr noundef %32)
  %34 = icmp eq i32 %33, 0
  br i1 %34, label %35, label %36

35:                                               ; preds = %26
  store i32 1, ptr %3, align 4
  br label %41

36:                                               ; preds = %26, %18, %11
  br label %37

37:                                               ; preds = %36
  %38 = load i32, ptr %6, align 4
  %39 = add nsw i32 %38, 1
  store i32 %39, ptr %6, align 4
  br label %7, !llvm.loop !45

40:                                               ; preds = %7
  store i32 0, ptr %3, align 4
  br label %41

41:                                               ; preds = %40, %35
  %42 = load i32, ptr %3, align 4
  ret i32 %42
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @saveProducts() #0 {
  %1 = alloca ptr, align 8
  %2 = alloca i32, align 4
  %3 = call noalias ptr @fopen(ptr noundef @.str.2, ptr noundef @.str.26)
  store ptr %3, ptr %1, align 8
  %4 = load ptr, ptr %1, align 8
  %5 = icmp ne ptr %4, null
  br i1 %5, label %8, label %6

6:                                                ; preds = %0
  %7 = call i32 (ptr, ...) @printf(ptr noundef @.str.27, ptr noundef @.str.2)
  br label %59

8:                                                ; preds = %0
  %9 = load ptr, ptr %1, align 8
  %10 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %9, ptr noundef @.str.28) #9
  store i32 0, ptr %2, align 4
  br label %11

11:                                               ; preds = %53, %8
  %12 = load i32, ptr %2, align 4
  %13 = load i32, ptr @productCount, align 4
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %15, label %56

15:                                               ; preds = %11
  %16 = load ptr, ptr %1, align 8
  %17 = load i32, ptr %2, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %18
  %20 = getelementptr inbounds nuw %struct.Product, ptr %19, i32 0, i32 0
  %21 = load i32, ptr %20, align 8
  %22 = load i32, ptr %2, align 4
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %23
  %25 = getelementptr inbounds nuw %struct.Product, ptr %24, i32 0, i32 1
  %26 = getelementptr inbounds [80 x i8], ptr %25, i64 0, i64 0
  %27 = load i32, ptr %2, align 4
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %28
  %30 = getelementptr inbounds nuw %struct.Product, ptr %29, i32 0, i32 2
  %31 = getelementptr inbounds [40 x i8], ptr %30, i64 0, i64 0
  %32 = load i32, ptr %2, align 4
  %33 = sext i32 %32 to i64
  %34 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %33
  %35 = getelementptr inbounds nuw %struct.Product, ptr %34, i32 0, i32 3
  %36 = load double, ptr %35, align 8
  %37 = load i32, ptr %2, align 4
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %38
  %40 = getelementptr inbounds nuw %struct.Product, ptr %39, i32 0, i32 4
  %41 = load i32, ptr %40, align 8
  %42 = load i32, ptr %2, align 4
  %43 = sext i32 %42 to i64
  %44 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %43
  %45 = getelementptr inbounds nuw %struct.Product, ptr %44, i32 0, i32 5
  %46 = load i32, ptr %45, align 4
  %47 = load i32, ptr %2, align 4
  %48 = sext i32 %47 to i64
  %49 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %48
  %50 = getelementptr inbounds nuw %struct.Product, ptr %49, i32 0, i32 6
  %51 = load i32, ptr %50, align 8
  %52 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %16, ptr noundef @.str.29, i32 noundef %21, ptr noundef %26, ptr noundef %31, double noundef %36, i32 noundef %41, i32 noundef %46, i32 noundef %51) #9
  br label %53

53:                                               ; preds = %15
  %54 = load i32, ptr %2, align 4
  %55 = add nsw i32 %54, 1
  store i32 %55, ptr %2, align 4
  br label %11, !llvm.loop !46

56:                                               ; preds = %11
  %57 = load ptr, ptr %1, align 8
  %58 = call i32 @fclose(ptr noundef %57)
  br label %59

59:                                               ; preds = %56, %6
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @saveOrders() #0 {
  %1 = alloca ptr, align 8
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = call noalias ptr @fopen(ptr noundef @.str.3, ptr noundef @.str.26)
  store ptr %6, ptr %1, align 8
  %7 = load ptr, ptr %1, align 8
  %8 = icmp ne ptr %7, null
  br i1 %8, label %11, label %9

9:                                                ; preds = %0
  %10 = call i32 (ptr, ...) @printf(ptr noundef @.str.27, ptr noundef @.str.3)
  br label %94

11:                                               ; preds = %0
  %12 = load ptr, ptr %1, align 8
  %13 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %12, ptr noundef @.str.30) #9
  %14 = load ptr, ptr %1, align 8
  %15 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %14, ptr noundef @.str.31) #9
  store i32 0, ptr %2, align 4
  br label %16

16:                                               ; preds = %88, %11
  %17 = load i32, ptr %2, align 4
  %18 = load i32, ptr @orderCount, align 4
  %19 = icmp slt i32 %17, %18
  br i1 %19, label %20, label %91

20:                                               ; preds = %16
  %21 = load i32, ptr %2, align 4
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %22
  store ptr %23, ptr %3, align 8
  %24 = load ptr, ptr %1, align 8
  %25 = load ptr, ptr %3, align 8
  %26 = getelementptr inbounds nuw %struct.Order, ptr %25, i32 0, i32 0
  %27 = load i32, ptr %26, align 8
  %28 = load ptr, ptr %3, align 8
  %29 = getelementptr inbounds nuw %struct.Order, ptr %28, i32 0, i32 1
  %30 = getelementptr inbounds [80 x i8], ptr %29, i64 0, i64 0
  %31 = load ptr, ptr %3, align 8
  %32 = getelementptr inbounds nuw %struct.Order, ptr %31, i32 0, i32 2
  %33 = load i32, ptr %32, align 4
  %34 = load ptr, ptr %3, align 8
  %35 = getelementptr inbounds nuw %struct.Order, ptr %34, i32 0, i32 4
  %36 = load double, ptr %35, align 8
  %37 = load ptr, ptr %3, align 8
  %38 = getelementptr inbounds nuw %struct.Order, ptr %37, i32 0, i32 5
  %39 = load double, ptr %38, align 8
  %40 = load ptr, ptr %3, align 8
  %41 = getelementptr inbounds nuw %struct.Order, ptr %40, i32 0, i32 6
  %42 = load double, ptr %41, align 8
  %43 = load ptr, ptr %3, align 8
  %44 = getelementptr inbounds nuw %struct.Order, ptr %43, i32 0, i32 7
  %45 = load double, ptr %44, align 8
  %46 = load ptr, ptr %3, align 8
  %47 = getelementptr inbounds nuw %struct.Order, ptr %46, i32 0, i32 8
  %48 = getelementptr inbounds [16 x i8], ptr %47, i64 0, i64 0
  %49 = load ptr, ptr %3, align 8
  %50 = getelementptr inbounds nuw %struct.Order, ptr %49, i32 0, i32 9
  %51 = getelementptr inbounds [32 x i8], ptr %50, i64 0, i64 0
  %52 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %24, ptr noundef @.str.32, i32 noundef %27, ptr noundef %30, i32 noundef %33, double noundef %36, double noundef %39, double noundef %42, double noundef %45, ptr noundef %48, ptr noundef %51) #9
  store i32 0, ptr %4, align 4
  br label %53

53:                                               ; preds = %82, %20
  %54 = load i32, ptr %4, align 4
  %55 = load ptr, ptr %3, align 8
  %56 = getelementptr inbounds nuw %struct.Order, ptr %55, i32 0, i32 2
  %57 = load i32, ptr %56, align 4
  %58 = icmp slt i32 %54, %57
  br i1 %58, label %59, label %85

59:                                               ; preds = %53
  %60 = load ptr, ptr %3, align 8
  %61 = getelementptr inbounds nuw %struct.Order, ptr %60, i32 0, i32 3
  %62 = load i32, ptr %4, align 4
  %63 = sext i32 %62 to i64
  %64 = getelementptr inbounds [32 x %struct.OrderItem], ptr %61, i64 0, i64 %63
  store ptr %64, ptr %5, align 8
  %65 = load ptr, ptr %1, align 8
  %66 = load ptr, ptr %5, align 8
  %67 = getelementptr inbounds nuw %struct.OrderItem, ptr %66, i32 0, i32 0
  %68 = load i32, ptr %67, align 8
  %69 = load ptr, ptr %5, align 8
  %70 = getelementptr inbounds nuw %struct.OrderItem, ptr %69, i32 0, i32 1
  %71 = getelementptr inbounds [80 x i8], ptr %70, i64 0, i64 0
  %72 = load ptr, ptr %5, align 8
  %73 = getelementptr inbounds nuw %struct.OrderItem, ptr %72, i32 0, i32 2
  %74 = load i32, ptr %73, align 4
  %75 = load ptr, ptr %5, align 8
  %76 = getelementptr inbounds nuw %struct.OrderItem, ptr %75, i32 0, i32 3
  %77 = load double, ptr %76, align 8
  %78 = load ptr, ptr %5, align 8
  %79 = getelementptr inbounds nuw %struct.OrderItem, ptr %78, i32 0, i32 4
  %80 = load double, ptr %79, align 8
  %81 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %65, ptr noundef @.str.33, i32 noundef %68, ptr noundef %71, i32 noundef %74, double noundef %77, double noundef %80) #9
  br label %82

82:                                               ; preds = %59
  %83 = load i32, ptr %4, align 4
  %84 = add nsw i32 %83, 1
  store i32 %84, ptr %4, align 4
  br label %53, !llvm.loop !47

85:                                               ; preds = %53
  %86 = load ptr, ptr %1, align 8
  %87 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %86, ptr noundef @.str.34) #9
  br label %88

88:                                               ; preds = %85
  %89 = load i32, ptr %2, align 4
  %90 = add nsw i32 %89, 1
  store i32 %90, ptr %2, align 4
  br label %16, !llvm.loop !48

91:                                               ; preds = %16
  %92 = load ptr, ptr %1, align 8
  %93 = call i32 @fclose(ptr noundef %92)
  br label %94

94:                                               ; preds = %91, %9
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @parseIntStrict(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr null, ptr %6, align 8
  %8 = call ptr @__errno_location() #10
  store i32 0, ptr %8, align 4
  %9 = load ptr, ptr %4, align 8
  %10 = icmp ne ptr %9, null
  br i1 %10, label %11, label %15

11:                                               ; preds = %2
  %12 = load ptr, ptr %4, align 8
  %13 = load i8, ptr %12, align 1
  %14 = icmp ne i8 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %11, %2
  store i32 0, ptr %3, align 4
  br label %59

16:                                               ; preds = %11
  %17 = load ptr, ptr %4, align 8
  %18 = call i64 @strtol(ptr noundef %17, ptr noundef %6, i32 noundef 10) #9
  store i64 %18, ptr %7, align 8
  %19 = call ptr @__errno_location() #10
  %20 = load i32, ptr %19, align 4
  %21 = icmp ne i32 %20, 0
  br i1 %21, label %26, label %22

22:                                               ; preds = %16
  %23 = load ptr, ptr %6, align 8
  %24 = load ptr, ptr %4, align 8
  %25 = icmp eq ptr %23, %24
  br i1 %25, label %26, label %27

26:                                               ; preds = %22, %16
  store i32 0, ptr %3, align 4
  br label %59

27:                                               ; preds = %22
  br label %28

28:                                               ; preds = %45, %27
  %29 = load ptr, ptr %6, align 8
  %30 = load i8, ptr %29, align 1
  %31 = icmp ne i8 %30, 0
  br i1 %31, label %32, label %48

32:                                               ; preds = %28
  %33 = call ptr @__ctype_b_loc() #10
  %34 = load ptr, ptr %33, align 8
  %35 = load ptr, ptr %6, align 8
  %36 = load i8, ptr %35, align 1
  %37 = zext i8 %36 to i32
  %38 = sext i32 %37 to i64
  %39 = getelementptr inbounds i16, ptr %34, i64 %38
  %40 = load i16, ptr %39, align 2
  %41 = zext i16 %40 to i32
  %42 = and i32 %41, 8192
  %43 = icmp ne i32 %42, 0
  br i1 %43, label %45, label %44

44:                                               ; preds = %32
  store i32 0, ptr %3, align 4
  br label %59

45:                                               ; preds = %32
  %46 = load ptr, ptr %6, align 8
  %47 = getelementptr inbounds nuw i8, ptr %46, i32 1
  store ptr %47, ptr %6, align 8
  br label %28, !llvm.loop !49

48:                                               ; preds = %28
  %49 = load i64, ptr %7, align 8
  %50 = icmp slt i64 %49, -2147483648
  br i1 %50, label %54, label %51

51:                                               ; preds = %48
  %52 = load i64, ptr %7, align 8
  %53 = icmp sgt i64 %52, 2147483647
  br i1 %53, label %54, label %55

54:                                               ; preds = %51, %48
  store i32 0, ptr %3, align 4
  br label %59

55:                                               ; preds = %51
  %56 = load i64, ptr %7, align 8
  %57 = trunc i64 %56 to i32
  %58 = load ptr, ptr %5, align 8
  store i32 %57, ptr %58, align 4
  store i32 1, ptr %3, align 4
  br label %59

59:                                               ; preds = %55, %54, %44, %26, %15
  %60 = load i32, ptr %3, align 4
  ret i32 %60
}

; Function Attrs: nounwind
declare i64 @strtol(ptr noundef, ptr noundef, i32 noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define internal void @loadProducts() #0 {
  %1 = alloca ptr, align 8
  %2 = alloca [512 x i8], align 16
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca %struct.Product, align 8
  %11 = call noalias ptr @fopen(ptr noundef @.str.2, ptr noundef @.str.5)
  store ptr %11, ptr %1, align 8
  %12 = load ptr, ptr %1, align 8
  %13 = icmp ne ptr %12, null
  br i1 %13, label %15, label %14

14:                                               ; preds = %0
  br label %137

15:                                               ; preds = %0
  store i32 0, ptr @productCount, align 4
  store i32 1, ptr @nextProductId, align 4
  br label %16

16:                                               ; preds = %133, %119, %102, %96, %90, %84, %72, %66, %32, %15
  %17 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %18 = load ptr, ptr %1, align 8
  %19 = call ptr @fgets(ptr noundef %17, i32 noundef 512, ptr noundef %18)
  %20 = icmp ne ptr %19, null
  br i1 %20, label %21, label %134

21:                                               ; preds = %16
  %22 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  call void @trim(ptr noundef %22)
  %23 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %24 = load i8, ptr %23, align 16
  %25 = sext i8 %24 to i32
  %26 = icmp eq i32 %25, 0
  br i1 %26, label %32, label %27

27:                                               ; preds = %21
  %28 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %29 = load i8, ptr %28, align 16
  %30 = sext i8 %29 to i32
  %31 = icmp eq i32 %30, 35
  br i1 %31, label %32, label %33

32:                                               ; preds = %27, %21
  br label %16, !llvm.loop !50

33:                                               ; preds = %27
  %34 = load i32, ptr @productCount, align 4
  %35 = icmp sge i32 %34, 500
  br i1 %35, label %36, label %37

36:                                               ; preds = %33
  br label %134

37:                                               ; preds = %33
  %38 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %39 = call ptr @strtok(ptr noundef %38, ptr noundef @.str.6) #9
  store ptr %39, ptr %3, align 8
  %40 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %40, ptr %4, align 8
  %41 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %41, ptr %5, align 8
  %42 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %42, ptr %6, align 8
  %43 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %43, ptr %7, align 8
  %44 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %44, ptr %8, align 8
  %45 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %45, ptr %9, align 8
  %46 = load ptr, ptr %3, align 8
  %47 = icmp ne ptr %46, null
  br i1 %47, label %48, label %66

48:                                               ; preds = %37
  %49 = load ptr, ptr %4, align 8
  %50 = icmp ne ptr %49, null
  br i1 %50, label %51, label %66

51:                                               ; preds = %48
  %52 = load ptr, ptr %5, align 8
  %53 = icmp ne ptr %52, null
  br i1 %53, label %54, label %66

54:                                               ; preds = %51
  %55 = load ptr, ptr %6, align 8
  %56 = icmp ne ptr %55, null
  br i1 %56, label %57, label %66

57:                                               ; preds = %54
  %58 = load ptr, ptr %7, align 8
  %59 = icmp ne ptr %58, null
  br i1 %59, label %60, label %66

60:                                               ; preds = %57
  %61 = load ptr, ptr %8, align 8
  %62 = icmp ne ptr %61, null
  br i1 %62, label %63, label %66

63:                                               ; preds = %60
  %64 = load ptr, ptr %9, align 8
  %65 = icmp ne ptr %64, null
  br i1 %65, label %67, label %66

66:                                               ; preds = %63, %60, %57, %54, %51, %48, %37
  br label %16, !llvm.loop !50

67:                                               ; preds = %63
  call void @llvm.memset.p0.i64(ptr align 8 %10, i8 0, i64 152, i1 false)
  %68 = load ptr, ptr %3, align 8
  %69 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 0
  %70 = call i32 @parseIntStrict(ptr noundef %68, ptr noundef %69)
  %71 = icmp ne i32 %70, 0
  br i1 %71, label %73, label %72

72:                                               ; preds = %67
  br label %16, !llvm.loop !50

73:                                               ; preds = %67
  %74 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 1
  %75 = getelementptr inbounds [80 x i8], ptr %74, i64 0, i64 0
  %76 = load ptr, ptr %4, align 8
  call void @safeCopy(ptr noundef %75, ptr noundef %76, i64 noundef 80)
  %77 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 2
  %78 = getelementptr inbounds [40 x i8], ptr %77, i64 0, i64 0
  %79 = load ptr, ptr %5, align 8
  call void @safeCopy(ptr noundef %78, ptr noundef %79, i64 noundef 40)
  %80 = load ptr, ptr %6, align 8
  %81 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 3
  %82 = call i32 @parseDoubleStrict(ptr noundef %80, ptr noundef %81)
  %83 = icmp ne i32 %82, 0
  br i1 %83, label %85, label %84

84:                                               ; preds = %73
  br label %16, !llvm.loop !50

85:                                               ; preds = %73
  %86 = load ptr, ptr %7, align 8
  %87 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 4
  %88 = call i32 @parseIntStrict(ptr noundef %86, ptr noundef %87)
  %89 = icmp ne i32 %88, 0
  br i1 %89, label %91, label %90

90:                                               ; preds = %85
  br label %16, !llvm.loop !50

91:                                               ; preds = %85
  %92 = load ptr, ptr %8, align 8
  %93 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 5
  %94 = call i32 @parseIntStrict(ptr noundef %92, ptr noundef %93)
  %95 = icmp ne i32 %94, 0
  br i1 %95, label %97, label %96

96:                                               ; preds = %91
  br label %16, !llvm.loop !50

97:                                               ; preds = %91
  %98 = load ptr, ptr %9, align 8
  %99 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 6
  %100 = call i32 @parseIntStrict(ptr noundef %98, ptr noundef %99)
  %101 = icmp ne i32 %100, 0
  br i1 %101, label %103, label %102

102:                                              ; preds = %97
  br label %16, !llvm.loop !50

103:                                              ; preds = %97
  %104 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 0
  %105 = load i32, ptr %104, align 8
  %106 = icmp sle i32 %105, 0
  br i1 %106, label %119, label %107

107:                                              ; preds = %103
  %108 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 3
  %109 = load double, ptr %108, align 8
  %110 = fcmp olt double %109, 0.000000e+00
  br i1 %110, label %119, label %111

111:                                              ; preds = %107
  %112 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 4
  %113 = load i32, ptr %112, align 8
  %114 = icmp slt i32 %113, 0
  br i1 %114, label %119, label %115

115:                                              ; preds = %111
  %116 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 5
  %117 = load i32, ptr %116, align 4
  %118 = icmp slt i32 %117, 0
  br i1 %118, label %119, label %120

119:                                              ; preds = %115, %111, %107, %103
  br label %16, !llvm.loop !50

120:                                              ; preds = %115
  %121 = load i32, ptr @productCount, align 4
  %122 = add nsw i32 %121, 1
  store i32 %122, ptr @productCount, align 4
  %123 = sext i32 %121 to i64
  %124 = getelementptr inbounds [500 x %struct.Product], ptr @products, i64 0, i64 %123
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %124, ptr align 8 %10, i64 152, i1 false)
  %125 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 0
  %126 = load i32, ptr %125, align 8
  %127 = load i32, ptr @nextProductId, align 4
  %128 = icmp sge i32 %126, %127
  br i1 %128, label %129, label %133

129:                                              ; preds = %120
  %130 = getelementptr inbounds nuw %struct.Product, ptr %10, i32 0, i32 0
  %131 = load i32, ptr %130, align 8
  %132 = add nsw i32 %131, 1
  store i32 %132, ptr @nextProductId, align 4
  br label %133

133:                                              ; preds = %129, %120
  br label %16, !llvm.loop !50

134:                                              ; preds = %36, %16
  %135 = load ptr, ptr %1, align 8
  %136 = call i32 @fclose(ptr noundef %135)
  br label %137

137:                                              ; preds = %134, %14
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define internal void @loadOrders() #0 {
  %1 = alloca ptr, align 8
  %2 = alloca [512 x i8], align 16
  %3 = alloca %struct.Order, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca ptr, align 8
  %12 = alloca ptr, align 8
  %13 = alloca ptr, align 8
  %14 = alloca ptr, align 8
  %15 = alloca ptr, align 8
  %16 = alloca ptr, align 8
  %17 = alloca ptr, align 8
  %18 = alloca ptr, align 8
  %19 = alloca ptr, align 8
  %20 = alloca ptr, align 8
  %21 = alloca %struct.OrderItem, align 8
  %22 = call noalias ptr @fopen(ptr noundef @.str.3, ptr noundef @.str.5)
  store ptr %22, ptr %1, align 8
  %23 = load ptr, ptr %1, align 8
  %24 = icmp ne ptr %23, null
  br i1 %24, label %26, label %25

25:                                               ; preds = %0
  br label %250

26:                                               ; preds = %0
  store i32 0, ptr @orderCount, align 4
  store i32 1, ptr @nextOrderId, align 4
  store i32 0, ptr %4, align 4
  br label %27

27:                                               ; preds = %246, %212, %199, %193, %187, %178, %172, %148, %120, %114, %108, %102, %93, %87, %43, %26
  %28 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %29 = load ptr, ptr %1, align 8
  %30 = call ptr @fgets(ptr noundef %28, i32 noundef 512, ptr noundef %29)
  %31 = icmp ne ptr %30, null
  br i1 %31, label %32, label %247

32:                                               ; preds = %27
  %33 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  call void @trim(ptr noundef %33)
  %34 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %35 = load i8, ptr %34, align 16
  %36 = sext i8 %35 to i32
  %37 = icmp eq i32 %36, 0
  br i1 %37, label %43, label %38

38:                                               ; preds = %32
  %39 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %40 = load i8, ptr %39, align 16
  %41 = sext i8 %40 to i32
  %42 = icmp eq i32 %41, 35
  br i1 %42, label %43, label %44

43:                                               ; preds = %38, %32
  br label %27, !llvm.loop !51

44:                                               ; preds = %38
  %45 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %46 = call i32 @strncmp(ptr noundef %45, ptr noundef @.str.8, i64 noundef 6) #8
  %47 = icmp eq i32 %46, 0
  br i1 %47, label %48, label %137

48:                                               ; preds = %44
  call void @llvm.memset.p0.i64(ptr align 8 %3, i8 0, i64 3496, i1 false)
  store i32 1, ptr %4, align 4
  %49 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %50 = call ptr @strtok(ptr noundef %49, ptr noundef @.str.6) #9
  store ptr %50, ptr %5, align 8
  %51 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %51, ptr %6, align 8
  %52 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %52, ptr %7, align 8
  %53 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %53, ptr %8, align 8
  %54 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %54, ptr %9, align 8
  %55 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %55, ptr %10, align 8
  %56 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %56, ptr %11, align 8
  %57 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %57, ptr %12, align 8
  %58 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %58, ptr %13, align 8
  %59 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %59, ptr %14, align 8
  %60 = load ptr, ptr %5, align 8
  %61 = load ptr, ptr %6, align 8
  %62 = icmp ne ptr %61, null
  br i1 %62, label %63, label %87

63:                                               ; preds = %48
  %64 = load ptr, ptr %7, align 8
  %65 = icmp ne ptr %64, null
  br i1 %65, label %66, label %87

66:                                               ; preds = %63
  %67 = load ptr, ptr %8, align 8
  %68 = icmp ne ptr %67, null
  br i1 %68, label %69, label %87

69:                                               ; preds = %66
  %70 = load ptr, ptr %9, align 8
  %71 = icmp ne ptr %70, null
  br i1 %71, label %72, label %87

72:                                               ; preds = %69
  %73 = load ptr, ptr %10, align 8
  %74 = icmp ne ptr %73, null
  br i1 %74, label %75, label %87

75:                                               ; preds = %72
  %76 = load ptr, ptr %11, align 8
  %77 = icmp ne ptr %76, null
  br i1 %77, label %78, label %87

78:                                               ; preds = %75
  %79 = load ptr, ptr %12, align 8
  %80 = icmp ne ptr %79, null
  br i1 %80, label %81, label %87

81:                                               ; preds = %78
  %82 = load ptr, ptr %13, align 8
  %83 = icmp ne ptr %82, null
  br i1 %83, label %84, label %87

84:                                               ; preds = %81
  %85 = load ptr, ptr %14, align 8
  %86 = icmp ne ptr %85, null
  br i1 %86, label %88, label %87

87:                                               ; preds = %84, %81, %78, %75, %72, %69, %66, %63, %48
  store i32 0, ptr %4, align 4
  br label %27, !llvm.loop !51

88:                                               ; preds = %84
  %89 = load ptr, ptr %6, align 8
  %90 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 0
  %91 = call i32 @parseIntStrict(ptr noundef %89, ptr noundef %90)
  %92 = icmp ne i32 %91, 0
  br i1 %92, label %94, label %93

93:                                               ; preds = %88
  store i32 0, ptr %4, align 4
  br label %27, !llvm.loop !51

94:                                               ; preds = %88
  %95 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 1
  %96 = getelementptr inbounds [80 x i8], ptr %95, i64 0, i64 0
  %97 = load ptr, ptr %7, align 8
  call void @safeCopy(ptr noundef %96, ptr noundef %97, i64 noundef 80)
  %98 = load ptr, ptr %9, align 8
  %99 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 4
  %100 = call i32 @parseDoubleStrict(ptr noundef %98, ptr noundef %99)
  %101 = icmp ne i32 %100, 0
  br i1 %101, label %103, label %102

102:                                              ; preds = %94
  store i32 0, ptr %4, align 4
  br label %27, !llvm.loop !51

103:                                              ; preds = %94
  %104 = load ptr, ptr %10, align 8
  %105 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 5
  %106 = call i32 @parseDoubleStrict(ptr noundef %104, ptr noundef %105)
  %107 = icmp ne i32 %106, 0
  br i1 %107, label %109, label %108

108:                                              ; preds = %103
  store i32 0, ptr %4, align 4
  br label %27, !llvm.loop !51

109:                                              ; preds = %103
  %110 = load ptr, ptr %11, align 8
  %111 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 6
  %112 = call i32 @parseDoubleStrict(ptr noundef %110, ptr noundef %111)
  %113 = icmp ne i32 %112, 0
  br i1 %113, label %115, label %114

114:                                              ; preds = %109
  store i32 0, ptr %4, align 4
  br label %27, !llvm.loop !51

115:                                              ; preds = %109
  %116 = load ptr, ptr %12, align 8
  %117 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 7
  %118 = call i32 @parseDoubleStrict(ptr noundef %116, ptr noundef %117)
  %119 = icmp ne i32 %118, 0
  br i1 %119, label %121, label %120

120:                                              ; preds = %115
  store i32 0, ptr %4, align 4
  br label %27, !llvm.loop !51

121:                                              ; preds = %115
  %122 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 8
  %123 = getelementptr inbounds [16 x i8], ptr %122, i64 0, i64 0
  %124 = load ptr, ptr %13, align 8
  call void @safeCopy(ptr noundef %123, ptr noundef %124, i64 noundef 16)
  %125 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 9
  %126 = getelementptr inbounds [32 x i8], ptr %125, i64 0, i64 0
  %127 = load ptr, ptr %14, align 8
  call void @safeCopy(ptr noundef %126, ptr noundef %127, i64 noundef 32)
  %128 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 0
  %129 = load i32, ptr %128, align 8
  %130 = load i32, ptr @nextOrderId, align 4
  %131 = icmp sge i32 %129, %130
  br i1 %131, label %132, label %136

132:                                              ; preds = %121
  %133 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 0
  %134 = load i32, ptr %133, align 8
  %135 = add nsw i32 %134, 1
  store i32 %135, ptr @nextOrderId, align 4
  br label %136

136:                                              ; preds = %132, %121
  br label %246

137:                                              ; preds = %44
  %138 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %139 = call i32 @strncmp(ptr noundef %138, ptr noundef @.str.9, i64 noundef 5) #8
  %140 = icmp eq i32 %139, 0
  br i1 %140, label %141, label %220

141:                                              ; preds = %137
  %142 = load i32, ptr %4, align 4
  %143 = icmp ne i32 %142, 0
  br i1 %143, label %144, label %220

144:                                              ; preds = %141
  %145 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 2
  %146 = load i32, ptr %145, align 4
  %147 = icmp sge i32 %146, 32
  br i1 %147, label %148, label %149

148:                                              ; preds = %144
  br label %27, !llvm.loop !51

149:                                              ; preds = %144
  %150 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %151 = call ptr @strtok(ptr noundef %150, ptr noundef @.str.6) #9
  store ptr %151, ptr %15, align 8
  %152 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %152, ptr %16, align 8
  %153 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %153, ptr %17, align 8
  %154 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %154, ptr %18, align 8
  %155 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %155, ptr %19, align 8
  %156 = call ptr @strtok(ptr noundef null, ptr noundef @.str.6) #9
  store ptr %156, ptr %20, align 8
  %157 = load ptr, ptr %15, align 8
  %158 = load ptr, ptr %16, align 8
  %159 = icmp ne ptr %158, null
  br i1 %159, label %160, label %172

160:                                              ; preds = %149
  %161 = load ptr, ptr %17, align 8
  %162 = icmp ne ptr %161, null
  br i1 %162, label %163, label %172

163:                                              ; preds = %160
  %164 = load ptr, ptr %18, align 8
  %165 = icmp ne ptr %164, null
  br i1 %165, label %166, label %172

166:                                              ; preds = %163
  %167 = load ptr, ptr %19, align 8
  %168 = icmp ne ptr %167, null
  br i1 %168, label %169, label %172

169:                                              ; preds = %166
  %170 = load ptr, ptr %20, align 8
  %171 = icmp ne ptr %170, null
  br i1 %171, label %173, label %172

172:                                              ; preds = %169, %166, %163, %160, %149
  br label %27, !llvm.loop !51

173:                                              ; preds = %169
  call void @llvm.memset.p0.i64(ptr align 8 %21, i8 0, i64 104, i1 false)
  %174 = load ptr, ptr %16, align 8
  %175 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 0
  %176 = call i32 @parseIntStrict(ptr noundef %174, ptr noundef %175)
  %177 = icmp ne i32 %176, 0
  br i1 %177, label %179, label %178

178:                                              ; preds = %173
  br label %27, !llvm.loop !51

179:                                              ; preds = %173
  %180 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 1
  %181 = getelementptr inbounds [80 x i8], ptr %180, i64 0, i64 0
  %182 = load ptr, ptr %17, align 8
  call void @safeCopy(ptr noundef %181, ptr noundef %182, i64 noundef 80)
  %183 = load ptr, ptr %18, align 8
  %184 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 2
  %185 = call i32 @parseIntStrict(ptr noundef %183, ptr noundef %184)
  %186 = icmp ne i32 %185, 0
  br i1 %186, label %188, label %187

187:                                              ; preds = %179
  br label %27, !llvm.loop !51

188:                                              ; preds = %179
  %189 = load ptr, ptr %19, align 8
  %190 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 3
  %191 = call i32 @parseDoubleStrict(ptr noundef %189, ptr noundef %190)
  %192 = icmp ne i32 %191, 0
  br i1 %192, label %194, label %193

193:                                              ; preds = %188
  br label %27, !llvm.loop !51

194:                                              ; preds = %188
  %195 = load ptr, ptr %20, align 8
  %196 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 4
  %197 = call i32 @parseDoubleStrict(ptr noundef %195, ptr noundef %196)
  %198 = icmp ne i32 %197, 0
  br i1 %198, label %200, label %199

199:                                              ; preds = %194
  br label %27, !llvm.loop !51

200:                                              ; preds = %194
  %201 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 2
  %202 = load i32, ptr %201, align 4
  %203 = icmp sle i32 %202, 0
  br i1 %203, label %212, label %204

204:                                              ; preds = %200
  %205 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 3
  %206 = load double, ptr %205, align 8
  %207 = fcmp olt double %206, 0.000000e+00
  br i1 %207, label %212, label %208

208:                                              ; preds = %204
  %209 = getelementptr inbounds nuw %struct.OrderItem, ptr %21, i32 0, i32 4
  %210 = load double, ptr %209, align 8
  %211 = fcmp olt double %210, 0.000000e+00
  br i1 %211, label %212, label %213

212:                                              ; preds = %208, %204, %200
  br label %27, !llvm.loop !51

213:                                              ; preds = %208
  %214 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 3
  %215 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 2
  %216 = load i32, ptr %215, align 4
  %217 = add nsw i32 %216, 1
  store i32 %217, ptr %215, align 4
  %218 = sext i32 %216 to i64
  %219 = getelementptr inbounds [32 x %struct.OrderItem], ptr %214, i64 0, i64 %218
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %219, ptr align 8 %21, i64 104, i1 false)
  br label %245

220:                                              ; preds = %141, %137
  %221 = getelementptr inbounds [512 x i8], ptr %2, i64 0, i64 0
  %222 = call i32 @strcmp(ptr noundef %221, ptr noundef @.str.10) #8
  %223 = icmp eq i32 %222, 0
  br i1 %223, label %224, label %244

224:                                              ; preds = %220
  %225 = load i32, ptr %4, align 4
  %226 = icmp ne i32 %225, 0
  br i1 %226, label %227, label %244

227:                                              ; preds = %224
  %228 = load i32, ptr @orderCount, align 4
  %229 = icmp slt i32 %228, 1000
  br i1 %229, label %230, label %243

230:                                              ; preds = %227
  %231 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 0
  %232 = load i32, ptr %231, align 8
  %233 = icmp sgt i32 %232, 0
  br i1 %233, label %234, label %243

234:                                              ; preds = %230
  %235 = getelementptr inbounds nuw %struct.Order, ptr %3, i32 0, i32 2
  %236 = load i32, ptr %235, align 4
  %237 = icmp sgt i32 %236, 0
  br i1 %237, label %238, label %243

238:                                              ; preds = %234
  %239 = load i32, ptr @orderCount, align 4
  %240 = add nsw i32 %239, 1
  store i32 %240, ptr @orderCount, align 4
  %241 = sext i32 %239 to i64
  %242 = getelementptr inbounds [1000 x %struct.Order], ptr @orders, i64 0, i64 %241
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %242, ptr align 8 %3, i64 3496, i1 false)
  br label %243

243:                                              ; preds = %238, %234, %230, %227
  store i32 0, ptr %4, align 4
  br label %244

244:                                              ; preds = %243, %224, %220
  br label %245

245:                                              ; preds = %244, %213
  br label %246

246:                                              ; preds = %245, %136
  br label %27, !llvm.loop !51

247:                                              ; preds = %27
  %248 = load ptr, ptr %1, align 8
  %249 = call i32 @fclose(ptr noundef %248)
  br label %250

250:                                              ; preds = %247, %25
  ret void
}

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strncmp(ptr noundef, ptr noundef, i64 noundef) #4

; Function Attrs: nounwind
declare ptr @strtok(ptr noundef, ptr noundef) #5

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #8 = { nounwind willreturn memory(read) }
attributes #9 = { nounwind }
attributes #10 = { nounwind willreturn memory(none) }

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
!42 = distinct !{!42, !7}
!43 = distinct !{!43, !7}
!44 = distinct !{!44, !7}
!45 = distinct !{!45, !7}
!46 = distinct !{!46, !7}
!47 = distinct !{!47, !7}
!48 = distinct !{!48, !7}
!49 = distinct !{!49, !7}
!50 = distinct !{!50, !7}
!51 = distinct !{!51, !7}

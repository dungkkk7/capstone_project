#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <errno.h>
#include <limits.h>

#define MAX_PRODUCTS 500
#define MAX_ORDERS 1000
#define MAX_ITEMS_PER_ORDER 32
#define NAME_LEN 80
#define CATEGORY_LEN 40
#define STATUS_LEN 16
#define DATE_LEN 32
#define PRODUCT_FILE "products.db"
#define ORDER_FILE "orders.db"
#define TAX_RATE 0.08

/*
    SMART SHOP MANAGER - Console C Project
    ----------------------------------------------------
    Features:
    - Interactive menu
    - Product CRUD
    - Search / sort / low stock report
    - Create order with multiple items
    - Discount codes
    - Stock validation including duplicated items in same cart
    - Cancel order and restore stock
    - Save/load data from files
    - Defensive input parsing and edge case handling

    Build:
        gcc smart_shop_manager.c -std=c11 -O2 -Wall -Wextra -o shop
*/

typedef struct {
    int id;
    char name[NAME_LEN];
    char category[CATEGORY_LEN];
    double price;
    int stock;
    int sold;
    int active;
} Product;

typedef struct {
    int productId;
    char productName[NAME_LEN];
    int qty;
    double unitPrice;
    double lineTotal;
} OrderItem;

typedef struct {
    int id;
    char customer[NAME_LEN];
    int itemCount;
    OrderItem items[MAX_ITEMS_PER_ORDER];
    double subtotal;
    double discount;
    double tax;
    double total;
    char status[STATUS_LEN];
    char createdAt[DATE_LEN];
} Order;

static Product products[MAX_PRODUCTS];
static Order orders[MAX_ORDERS];
static int productCount = 0;
static int orderCount = 0;
static int nextProductId = 1;
static int nextOrderId = 1;

/* ======================= Utility ======================= */

static void clearScreen(void) {
    /* Portable-ish: just prints many newlines instead of system("clear") */
    for (int i = 0; i < 30; i++) putchar('\n');
}

static void pauseEnter(void) {
    char buf[8];
    printf("\nPress ENTER to continue...");
    fgets(buf, sizeof(buf), stdin);
}

static void flushLineIfNeeded(char *buf, size_t size) {
    size_t len = strlen(buf);
    if (len > 0 && buf[len - 1] == '\n') return;
    int c;
    while ((c = getchar()) != '\n' && c != EOF) {}
    (void)size;
}

static void trim(char *s) {
    if (!s) return;
    size_t len = strlen(s);
    while (len > 0 && (s[len - 1] == '\n' || s[len - 1] == '\r' || isspace((unsigned char)s[len - 1]))) {
        s[--len] = '\0';
    }
    size_t start = 0;
    while (s[start] && isspace((unsigned char)s[start])) start++;
    if (start > 0) memmove(s, s + start, strlen(s + start) + 1);
}

static void sanitizeField(char *s) {
    /* Avoid breaking pipe-delimited file format. */
    for (int i = 0; s[i]; i++) {
        if (s[i] == '|') s[i] = '/';
        if ((unsigned char)s[i] < 32) s[i] = ' ';
    }
    trim(s);
}

static void safeCopy(char *dst, const char *src, size_t n) {
    if (n == 0) return;
    if (!src) src = "";
    strncpy(dst, src, n - 1);
    dst[n - 1] = '\0';
}

static void readLine(const char *prompt, char *buf, size_t size) {
    printf("%s", prompt);
    if (!fgets(buf, size, stdin)) {
        buf[0] = '\0';
        clearerr(stdin);
        return;
    }
    flushLineIfNeeded(buf, size);
    trim(buf);
}

static int parseIntStrict(const char *s, int *out) {
    char *end = NULL;
    long v;
    errno = 0;
    if (!s || !*s) return 0;
    v = strtol(s, &end, 10);
    if (errno != 0 || end == s) return 0;
    while (*end) {
        if (!isspace((unsigned char)*end)) return 0;
        end++;
    }
    if (v < INT_MIN || v > INT_MAX) return 0;
    *out = (int)v;
    return 1;
}

static int parseDoubleStrict(const char *s, double *out) {
    char *end = NULL;
    double v;
    errno = 0;
    if (!s || !*s) return 0;
    v = strtod(s, &end);
    if (errno != 0 || end == s) return 0;
    while (*end) {
        if (!isspace((unsigned char)*end)) return 0;
        end++;
    }
    *out = v;
    return 1;
}

static int readIntRange(const char *prompt, int min, int max) {
    char buf[128];
    int value;
    while (1) {
        readLine(prompt, buf, sizeof(buf));
        if (!parseIntStrict(buf, &value)) {
            printf("[Invalid] Please enter an integer.\n");
            continue;
        }
        if (value < min || value > max) {
            printf("[Invalid] Value must be between %d and %d.\n", min, max);
            continue;
        }
        return value;
    }
}

static double readDoubleRange(const char *prompt, double min, double max) {
    char buf[128];
    double value;
    while (1) {
        readLine(prompt, buf, sizeof(buf));
        if (!parseDoubleStrict(buf, &value)) {
            printf("[Invalid] Please enter a number.\n");
            continue;
        }
        if (value < min || value > max) {
            printf("[Invalid] Value must be between %.2f and %.2f.\n", min, max);
            continue;
        }
        return value;
    }
}

static void readNonEmptyString(const char *prompt, char *out, size_t size) {
    while (1) {
        readLine(prompt, out, size);
        sanitizeField(out);
        if (strlen(out) == 0) {
            printf("[Invalid] This field cannot be empty.\n");
            continue;
        }
        return;
    }
}

static int askYesNo(const char *prompt) {
    char buf[32];
    while (1) {
        readLine(prompt, buf, sizeof(buf));
        if (buf[0] == 'y' || buf[0] == 'Y') return 1;
        if (buf[0] == 'n' || buf[0] == 'N') return 0;
        printf("Please type y or n.\n");
    }
}

static int containsIgnoreCase(const char *text, const char *key) {
    if (!text || !key) return 0;
    if (!*key) return 1;

    size_t n = strlen(text), m = strlen(key);
    if (m > n) return 0;

    for (size_t i = 0; i + m <= n; i++) {
        size_t j = 0;
        while (j < m && tolower((unsigned char)text[i + j]) == tolower((unsigned char)key[j])) {
            j++;
        }
        if (j == m) return 1;
    }
    return 0;
}

static int cmpIgnoreCase(const char *a, const char *b) {
    while (*a && *b) {
        int ca = tolower((unsigned char)*a);
        int cb = tolower((unsigned char)*b);
        if (ca != cb) return ca - cb;
        a++; b++;
    }
    return tolower((unsigned char)*a) - tolower((unsigned char)*b);
}

static void nowString(char *out, size_t size) {
    time_t t = time(NULL);
    struct tm *tmv = localtime(&t);
    if (!tmv) {
        safeCopy(out, "unknown-time", size);
        return;
    }
    strftime(out, size, "%Y-%m-%d %H:%M:%S", tmv);
}

static void printMoney(double x) {
    printf("$%.2f", x);
}

/* ======================= Product Helpers ======================= */

static int findProductIndexById(int id) {
    for (int i = 0; i < productCount; i++) {
        if (products[i].id == id) return i;
    }
    return -1;
}

static int findActiveProductIndexById(int id) {
    int idx = findProductIndexById(id);
    if (idx < 0 || !products[idx].active) return -1;
    return idx;
}

static int productNameExists(const char *name, int ignoreId) {
    for (int i = 0; i < productCount; i++) {
        if (products[i].active && products[i].id != ignoreId && cmpIgnoreCase(products[i].name, name) == 0) {
            return 1;
        }
    }
    return 0;
}

static int activeProductCount(void) {
    int c = 0;
    for (int i = 0; i < productCount; i++) {
        if (products[i].active) c++;
    }
    return c;
}

static void printProductHeader(void) {
    printf("+------+------------------------------+------------------+----------+-------+------+\n");
    printf("| ID   | Name                         | Category         | Price    | Stock | Sold |\n");
    printf("+------+------------------------------+------------------+----------+-------+------+\n");
}

static void printProductRow(const Product *p) {
    printf("| %-4d | %-28.28s | %-16.16s | %8.2f | %5d | %4d |\n",
           p->id, p->name, p->category, p->price, p->stock, p->sold);
}

static void printProductFooter(void) {
    printf("+------+------------------------------+------------------+----------+-------+------+\n");
}

static void listProducts(void) {
    int found = 0;
    printProductHeader();
    for (int i = 0; i < productCount; i++) {
        if (products[i].active) {
            printProductRow(&products[i]);
            found = 1;
        }
    }
    printProductFooter();
    if (!found) printf("No active products found.\n");
}

static void addProduct(void) {
    if (productCount >= MAX_PRODUCTS) {
        printf("[Error] Product database is full. Max = %d.\n", MAX_PRODUCTS);
        return;
    }

    Product p;
    memset(&p, 0, sizeof(p));
    p.id = nextProductId++;
    p.active = 1;

    while (1) {
        readNonEmptyString("Product name: ", p.name, sizeof(p.name));
        if (productNameExists(p.name, -1)) {
            printf("[Duplicate] A product with this name already exists. Try another name.\n");
            continue;
        }
        break;
    }

    readNonEmptyString("Category: ", p.category, sizeof(p.category));
    p.price = readDoubleRange("Price [0.01 - 1000000]: ", 0.01, 1000000.0);
    p.stock = readIntRange("Initial stock [0 - 1000000]: ", 0, 1000000);
    p.sold = 0;

    products[productCount++] = p;
    printf("[OK] Product added with ID %d.\n", p.id);
}

static void updateProduct(void) {
    if (activeProductCount() == 0) {
        printf("No products to update.\n");
        return;
    }

    listProducts();
    int id = readIntRange("Enter product ID to update, 0 to cancel: ", 0, INT_MAX);
    if (id == 0) return;

    int idx = findActiveProductIndexById(id);
    if (idx < 0) {
        printf("[Not found] Active product ID %d does not exist.\n", id);
        return;
    }

    Product *p = &products[idx];
    printf("Updating: %s\n", p->name);
    printf("Leave text empty to keep old value.\n");

    char buf[NAME_LEN];
    readLine("New name: ", buf, sizeof(buf));
    sanitizeField(buf);
    if (strlen(buf) > 0) {
        if (productNameExists(buf, p->id)) {
            printf("[Duplicate] Name already exists. Name unchanged.\n");
        } else {
            safeCopy(p->name, buf, sizeof(p->name));
        }
    }

    readLine("New category: ", buf, sizeof(buf));
    sanitizeField(buf);
    if (strlen(buf) > 0) {
        safeCopy(p->category, buf, sizeof(p->category));
    }

    if (askYesNo("Change price? (y/n): ")) {
        p->price = readDoubleRange("New price [0.01 - 1000000]: ", 0.01, 1000000.0);
    }

    if (askYesNo("Change stock directly? (y/n): ")) {
        p->stock = readIntRange("New stock [0 - 1000000]: ", 0, 1000000);
    }

    printf("[OK] Product updated.\n");
}

static void restockProduct(void) {
    if (activeProductCount() == 0) {
        printf("No products to restock.\n");
        return;
    }

    listProducts();
    int id = readIntRange("Product ID to restock, 0 to cancel: ", 0, INT_MAX);
    if (id == 0) return;

    int idx = findActiveProductIndexById(id);
    if (idx < 0) {
        printf("[Not found] Product does not exist or is deleted.\n");
        return;
    }

    int amount = readIntRange("Amount to add [1 - 1000000]: ", 1, 1000000);
    if (products[idx].stock > INT_MAX - amount) {
        printf("[Overflow guard] Stock would exceed integer limit. Operation cancelled.\n");
        return;
    }

    products[idx].stock += amount;
    printf("[OK] New stock of %s = %d.\n", products[idx].name, products[idx].stock);
}

static int productUsedInPaidOrder(int productId) {
    for (int i = 0; i < orderCount; i++) {
        if (strcmp(orders[i].status, "PAID") != 0) continue;
        for (int j = 0; j < orders[i].itemCount; j++) {
            if (orders[i].items[j].productId == productId) return 1;
        }
    }
    return 0;
}

static void deleteProduct(void) {
    if (activeProductCount() == 0) {
        printf("No products to delete.\n");
        return;
    }

    listProducts();
    int id = readIntRange("Product ID to delete, 0 to cancel: ", 0, INT_MAX);
    if (id == 0) return;

    int idx = findActiveProductIndexById(id);
    if (idx < 0) {
        printf("[Not found] Product does not exist or already deleted.\n");
        return;
    }

    if (productUsedInPaidOrder(id)) {
        printf("Note: product appears in existing paid orders. It will be soft-deleted, not removed from history.\n");
    }

    if (!askYesNo("Are you sure? (y/n): ")) return;
    products[idx].active = 0;
    printf("[OK] Product soft-deleted.\n");
}

static void searchProducts(void) {
    if (activeProductCount() == 0) {
        printf("No products to search.\n");
        return;
    }

    printf("\nSearch mode:\n");
    printf("1. By name keyword\n");
    printf("2. By category keyword\n");
    printf("3. By price range\n");
    printf("4. Low stock threshold\n");

    int choice = readIntRange("Choose: ", 1, 4);
    int found = 0;
    char key[NAME_LEN];
    double minPrice, maxPrice;
    int threshold;

    printProductHeader();

    if (choice == 1) {
        readNonEmptyString("Name keyword: ", key, sizeof(key));
        for (int i = 0; i < productCount; i++) {
            if (products[i].active && containsIgnoreCase(products[i].name, key)) {
                printProductRow(&products[i]);
                found = 1;
            }
        }
    } else if (choice == 2) {
        readNonEmptyString("Category keyword: ", key, sizeof(key));
        for (int i = 0; i < productCount; i++) {
            if (products[i].active && containsIgnoreCase(products[i].category, key)) {
                printProductRow(&products[i]);
                found = 1;
            }
        }
    } else if (choice == 3) {
        minPrice = readDoubleRange("Min price: ", 0.0, 1000000.0);
        maxPrice = readDoubleRange("Max price: ", 0.0, 1000000.0);
        if (minPrice > maxPrice) {
            double tmp = minPrice;
            minPrice = maxPrice;
            maxPrice = tmp;
            printf("[Notice] Swapped min/max automatically.\n");
        }
        for (int i = 0; i < productCount; i++) {
            if (products[i].active && products[i].price >= minPrice && products[i].price <= maxPrice) {
                printProductRow(&products[i]);
                found = 1;
            }
        }
    } else {
        threshold = readIntRange("Show products with stock <= ", 0, 1000000);
        for (int i = 0; i < productCount; i++) {
            if (products[i].active && products[i].stock <= threshold) {
                printProductRow(&products[i]);
                found = 1;
            }
        }
    }

    printProductFooter();
    if (!found) printf("No matching products found.\n");
}

static int cmpProductName(const void *a, const void *b) {
    const Product *pa = (const Product *)a;
    const Product *pb = (const Product *)b;
    return cmpIgnoreCase(pa->name, pb->name);
}

static int cmpProductPriceAsc(const void *a, const void *b) {
    const Product *pa = (const Product *)a;
    const Product *pb = (const Product *)b;
    if (pa->price < pb->price) return -1;
    if (pa->price > pb->price) return 1;
    return pa->id - pb->id;
}

static int cmpProductStockAsc(const void *a, const void *b) {
    const Product *pa = (const Product *)a;
    const Product *pb = (const Product *)b;
    if (pa->stock != pb->stock) return pa->stock - pb->stock;
    return pa->id - pb->id;
}

static int cmpProductSoldDesc(const void *a, const void *b) {
    const Product *pa = (const Product *)a;
    const Product *pb = (const Product *)b;
    if (pa->sold != pb->sold) return pb->sold - pa->sold;
    return pa->id - pb->id;
}

static void sortProductsMenu(void) {
    if (productCount <= 1) {
        printf("Not enough products to sort.\n");
        return;
    }

    printf("\nSort products by:\n");
    printf("1. Name A-Z\n");
    printf("2. Price low-high\n");
    printf("3. Stock low-high\n");
    printf("4. Sold high-low\n");
    int choice = readIntRange("Choose: ", 1, 4);

    if (choice == 1) qsort(products, productCount, sizeof(Product), cmpProductName);
    else if (choice == 2) qsort(products, productCount, sizeof(Product), cmpProductPriceAsc);
    else if (choice == 3) qsort(products, productCount, sizeof(Product), cmpProductStockAsc);
    else qsort(products, productCount, sizeof(Product), cmpProductSoldDesc);

    printf("[OK] Products sorted.\n");
    listProducts();
}

/* ======================= Order Helpers ======================= */

static int findOrderIndexById(int id) {
    for (int i = 0; i < orderCount; i++) {
        if (orders[i].id == id) return i;
    }
    return -1;
}

static void printOrderSummaryHeader(void) {
    printf("+------+----------------------+-------+------------+------------+------------+---------------------+\n");
    printf("| ID   | Customer             | Items | Subtotal   | Total      | Status     | Created             |\n");
    printf("+------+----------------------+-------+------------+------------+------------+---------------------+\n");
}

static void printOrderSummaryRow(const Order *o) {
    printf("| %-4d | %-20.20s | %5d | %10.2f | %10.2f | %-10.10s | %-19.19s |\n",
           o->id, o->customer, o->itemCount, o->subtotal, o->total, o->status, o->createdAt);
}

static void printOrderSummaryFooter(void) {
    printf("+------+----------------------+-------+------------+------------+------------+---------------------+\n");
}

static void listOrders(void) {
    if (orderCount == 0) {
        printf("No orders yet.\n");
        return;
    }
    printOrderSummaryHeader();
    for (int i = 0; i < orderCount; i++) {
        printOrderSummaryRow(&orders[i]);
    }
    printOrderSummaryFooter();
}

static void printOrderDetail(const Order *o) {
    printf("\nORDER #%d\n", o->id);
    printf("Customer : %s\n", o->customer);
    printf("Status   : %s\n", o->status);
    printf("Created  : %s\n", o->createdAt);
    printf("\n+------+------------------------------+-------+------------+------------+\n");
    printf("| PID  | Product                      | Qty   | Unit       | Line       |\n");
    printf("+------+------------------------------+-------+------------+------------+\n");
    for (int i = 0; i < o->itemCount; i++) {
        const OrderItem *it = &o->items[i];
        printf("| %-4d | %-28.28s | %5d | %10.2f | %10.2f |\n",
               it->productId, it->productName, it->qty, it->unitPrice, it->lineTotal);
    }
    printf("+------+------------------------------+-------+------------+------------+\n");
    printf("Subtotal : "); printMoney(o->subtotal); printf("\n");
    printf("Discount : "); printMoney(o->discount); printf("\n");
    printf("Tax      : "); printMoney(o->tax); printf("\n");
    printf("Total    : "); printMoney(o->total); printf("\n");
}

static void viewOrderDetail(void) {
    if (orderCount == 0) {
        printf("No orders to view.\n");
        return;
    }

    listOrders();
    int id = readIntRange("Order ID to view, 0 to cancel: ", 0, INT_MAX);
    if (id == 0) return;

    int idx = findOrderIndexById(id);
    if (idx < 0) {
        printf("[Not found] Order ID %d not found.\n", id);
        return;
    }

    printOrderDetail(&orders[idx]);
}

static int getTempQtyForProduct(OrderItem *items, int itemCount, int productId) {
    int qty = 0;
    for (int i = 0; i < itemCount; i++) {
        if (items[i].productId == productId) qty += items[i].qty;
    }
    return qty;
}

static void mergeCartItem(OrderItem *items, int *itemCount, const Product *p, int qty) {
    for (int i = 0; i < *itemCount; i++) {
        if (items[i].productId == p->id) {
            items[i].qty += qty;
            items[i].lineTotal = items[i].qty * items[i].unitPrice;
            return;
        }
    }

    if (*itemCount >= MAX_ITEMS_PER_ORDER) return;
    OrderItem *it = &items[*itemCount];
    it->productId = p->id;
    safeCopy(it->productName, p->name, sizeof(it->productName));
    it->qty = qty;
    it->unitPrice = p->price;
    it->lineTotal = qty * p->price;
    (*itemCount)++;
}

static double calculateDiscount(double subtotal, const char *code) {
    if (cmpIgnoreCase(code, "NONE") == 0 || strlen(code) == 0) return 0.0;
    if (cmpIgnoreCase(code, "VIP10") == 0) return subtotal * 0.10;
    if (cmpIgnoreCase(code, "BULK15") == 0) {
        if (subtotal >= 500.0) return subtotal * 0.15;
        printf("[Notice] BULK15 requires subtotal >= $500. No discount applied.\n");
        return 0.0;
    }
    if (cmpIgnoreCase(code, "FREESHIP") == 0) {
        /* In this program there is no shipping fee, so this code is accepted but has no effect. */
        printf("[Notice] FREESHIP accepted, but this shop has no shipping fee.\n");
        return 0.0;
    }
    printf("[Notice] Unknown discount code. No discount applied.\n");
    return 0.0;
}

static void printCart(OrderItem *items, int itemCount) {
    double subtotal = 0;
    printf("\nCurrent cart:\n");
    printf("+------+------------------------------+-------+------------+------------+\n");
    printf("| PID  | Product                      | Qty   | Unit       | Line       |\n");
    printf("+------+------------------------------+-------+------------+------------+\n");
    for (int i = 0; i < itemCount; i++) {
        printf("| %-4d | %-28.28s | %5d | %10.2f | %10.2f |\n",
               items[i].productId, items[i].productName, items[i].qty, items[i].unitPrice, items[i].lineTotal);
        subtotal += items[i].lineTotal;
    }
    printf("+------+------------------------------+-------+------------+------------+\n");
    printf("Cart subtotal: "); printMoney(subtotal); printf("\n");
}

static void createOrder(void) {
    if (orderCount >= MAX_ORDERS) {
        printf("[Error] Order database is full. Max = %d.\n", MAX_ORDERS);
        return;
    }
    if (activeProductCount() == 0) {
        printf("Cannot create order: no active products.\n");
        return;
    }

    Order newOrder;
    memset(&newOrder, 0, sizeof(newOrder));
    newOrder.id = nextOrderId++;
    safeCopy(newOrder.status, "PAID", sizeof(newOrder.status));
    nowString(newOrder.createdAt, sizeof(newOrder.createdAt));

    readNonEmptyString("Customer name: ", newOrder.customer, sizeof(newOrder.customer));

    printf("\nDiscount codes: NONE, VIP10, BULK15, FREESHIP\n");
    printf("Add items to cart. Enter product ID 0 when done.\n");

    while (1) {
        listProducts();
        printf("Cart slots used: %d/%d\n", newOrder.itemCount, MAX_ITEMS_PER_ORDER);
        int id = readIntRange("Product ID, 0 to finish: ", 0, INT_MAX);
        if (id == 0) break;

        int idx = findActiveProductIndexById(id);
        if (idx < 0) {
            printf("[Not found] Product not found or deleted.\n");
            continue;
        }

        Product *p = &products[idx];
        if (p->stock <= 0) {
            printf("[Out of stock] %s currently has 0 stock.\n", p->name);
            continue;
        }

        int alreadyInCart = getTempQtyForProduct(newOrder.items, newOrder.itemCount, p->id);
        int available = p->stock - alreadyInCart;
        if (available <= 0) {
            printf("[Edge case] You already put all available stock of this product in the cart.\n");
            continue;
        }

        printf("Available now for this cart: %d\n", available);
        int qty = readIntRange("Quantity: ", 1, available);

        if (newOrder.itemCount >= MAX_ITEMS_PER_ORDER && alreadyInCart == 0) {
            printf("[Cart full] Max distinct items = %d.\n", MAX_ITEMS_PER_ORDER);
            continue;
        }

        mergeCartItem(newOrder.items, &newOrder.itemCount, p, qty);
        printCart(newOrder.items, newOrder.itemCount);
    }

    if (newOrder.itemCount == 0) {
        printf("[Cancelled] Empty cart. Order not created.\n");
        nextOrderId--;
        return;
    }

    for (int i = 0; i < newOrder.itemCount; i++) {
        newOrder.subtotal += newOrder.items[i].lineTotal;
    }

    char code[32];
    readLine("Discount code [NONE/VIP10/BULK15/FREESHIP]: ", code, sizeof(code));
    sanitizeField(code);
    if (strlen(code) == 0) safeCopy(code, "NONE", sizeof(code));

    newOrder.discount = calculateDiscount(newOrder.subtotal, code);
    if (newOrder.discount > newOrder.subtotal) newOrder.discount = newOrder.subtotal;
    newOrder.tax = (newOrder.subtotal - newOrder.discount) * TAX_RATE;
    newOrder.total = newOrder.subtotal - newOrder.discount + newOrder.tax;

    printf("\nFinal order preview:\n");
    printCart(newOrder.items, newOrder.itemCount);
    printf("Discount: "); printMoney(newOrder.discount); printf("\n");
    printf("Tax     : "); printMoney(newOrder.tax); printf("\n");
    printf("TOTAL   : "); printMoney(newOrder.total); printf("\n");

    if (!askYesNo("Confirm order? (y/n): ")) {
        printf("[Cancelled] Order not created.\n");
        nextOrderId--;
        return;
    }

    /* Final stock validation before committing. */
    for (int i = 0; i < newOrder.itemCount; i++) {
        int idx = findActiveProductIndexById(newOrder.items[i].productId);
        if (idx < 0) {
            printf("[Error] Product disappeared before checkout. Operation cancelled.\n");
            nextOrderId--;
            return;
        }
        if (products[idx].stock < newOrder.items[i].qty) {
            printf("[Error] Stock changed; not enough stock for %s. Operation cancelled.\n", products[idx].name);
            nextOrderId--;
            return;
        }
    }

    for (int i = 0; i < newOrder.itemCount; i++) {
        int idx = findActiveProductIndexById(newOrder.items[i].productId);
        products[idx].stock -= newOrder.items[i].qty;
        products[idx].sold += newOrder.items[i].qty;
    }

    orders[orderCount++] = newOrder;
    printf("[OK] Order #%d created. Total = ", newOrder.id);
    printMoney(newOrder.total);
    printf("\n");
}

static void cancelOrder(void) {
    if (orderCount == 0) {
        printf("No orders to cancel.\n");
        return;
    }

    listOrders();
    int id = readIntRange("Order ID to cancel, 0 to cancel action: ", 0, INT_MAX);
    if (id == 0) return;

    int idx = findOrderIndexById(id);
    if (idx < 0) {
        printf("[Not found] Order ID %d not found.\n", id);
        return;
    }

    Order *o = &orders[idx];
    if (strcmp(o->status, "CANCELLED") == 0) {
        printf("[Edge case] This order is already cancelled.\n");
        return;
    }

    printOrderDetail(o);
    if (!askYesNo("Really cancel this order and restore stock? (y/n): ")) return;

    for (int i = 0; i < o->itemCount; i++) {
        int pidx = findProductIndexById(o->items[i].productId);
        if (pidx >= 0) {
            if (products[pidx].stock <= INT_MAX - o->items[i].qty) {
                products[pidx].stock += o->items[i].qty;
            }
            if (products[pidx].sold >= o->items[i].qty) {
                products[pidx].sold -= o->items[i].qty;
            } else {
                products[pidx].sold = 0;
            }
        }
    }

    safeCopy(o->status, "CANCELLED", sizeof(o->status));
    printf("[OK] Order cancelled. Stock restored where product still exists.\n");
}

/* ======================= Reports ======================= */

static void revenueReport(void) {
    double gross = 0.0, discount = 0.0, tax = 0.0, net = 0.0;
    int paidOrders = 0, cancelledOrders = 0;
    int soldUnits = 0;

    for (int i = 0; i < orderCount; i++) {
        if (strcmp(orders[i].status, "PAID") == 0) {
            paidOrders++;
            gross += orders[i].subtotal;
            discount += orders[i].discount;
            tax += orders[i].tax;
            net += orders[i].total;
            for (int j = 0; j < orders[i].itemCount; j++) {
                soldUnits += orders[i].items[j].qty;
            }
        } else if (strcmp(orders[i].status, "CANCELLED") == 0) {
            cancelledOrders++;
        }
    }

    printf("\n========== REVENUE REPORT ==========" "\n");
    printf("Paid orders     : %d\n", paidOrders);
    printf("Cancelled orders: %d\n", cancelledOrders);
    printf("Units sold      : %d\n", soldUnits);
    printf("Gross subtotal  : "); printMoney(gross); printf("\n");
    printf("Discount total  : "); printMoney(discount); printf("\n");
    printf("Tax collected   : "); printMoney(tax); printf("\n");
    printf("Net revenue     : "); printMoney(net); printf("\n");
}

static void topSellingReport(void) {
    if (activeProductCount() == 0) {
        printf("No products.\n");
        return;
    }

    Product copy[MAX_PRODUCTS];
    int c = 0;
    for (int i = 0; i < productCount; i++) {
        if (products[i].active) copy[c++] = products[i];
    }

    qsort(copy, c, sizeof(Product), cmpProductSoldDesc);

    printf("\n========== TOP SELLING PRODUCTS ==========" "\n");
    printProductHeader();
    for (int i = 0; i < c && i < 10; i++) {
        printProductRow(&copy[i]);
    }
    printProductFooter();
}

static void lowStockReport(void) {
    int threshold = readIntRange("Low stock threshold: ", 0, 1000000);
    int found = 0;
    printf("\n========== LOW STOCK REPORT ==========" "\n");
    printProductHeader();
    for (int i = 0; i < productCount; i++) {
        if (products[i].active && products[i].stock <= threshold) {
            printProductRow(&products[i]);
            found = 1;
        }
    }
    printProductFooter();
    if (!found) printf("No products at or below threshold %d.\n", threshold);
}

static void inventoryValueReport(void) {
    double total = 0.0;
    int units = 0;
    for (int i = 0; i < productCount; i++) {
        if (!products[i].active) continue;
        total += products[i].price * products[i].stock;
        units += products[i].stock;
    }
    printf("\n========== INVENTORY VALUE ==========" "\n");
    printf("Active products : %d\n", activeProductCount());
    printf("Units in stock  : %d\n", units);
    printf("Inventory value : "); printMoney(total); printf("\n");
}

static void reportsMenu(void) {
    while (1) {
        printf("\n===== REPORTS =====\n");
        printf("1. Revenue report\n");
        printf("2. Top selling products\n");
        printf("3. Low stock report\n");
        printf("4. Inventory value\n");
        printf("0. Back\n");
        int choice = readIntRange("Choose: ", 0, 4);
        if (choice == 0) return;
        if (choice == 1) revenueReport();
        else if (choice == 2) topSellingReport();
        else if (choice == 3) lowStockReport();
        else inventoryValueReport();
        pauseEnter();
    }
}

/* ======================= Persistence ======================= */

static void saveProducts(void) {
    FILE *f = fopen(PRODUCT_FILE, "w");
    if (!f) {
        printf("[File error] Cannot write %s\n", PRODUCT_FILE);
        return;
    }
    fprintf(f, "# id|name|category|price|stock|sold|active\n");
    for (int i = 0; i < productCount; i++) {
        fprintf(f, "%d|%s|%s|%.2f|%d|%d|%d\n",
                products[i].id,
                products[i].name,
                products[i].category,
                products[i].price,
                products[i].stock,
                products[i].sold,
                products[i].active);
    }
    fclose(f);
}

static void saveOrders(void) {
    FILE *f = fopen(ORDER_FILE, "w");
    if (!f) {
        printf("[File error] Cannot write %s\n", ORDER_FILE);
        return;
    }
    fprintf(f, "# ORDER|id|customer|itemCount|subtotal|discount|tax|total|status|createdAt\n");
    fprintf(f, "# ITEM|productId|productName|qty|unitPrice|lineTotal\n");
    for (int i = 0; i < orderCount; i++) {
        Order *o = &orders[i];
        fprintf(f, "ORDER|%d|%s|%d|%.2f|%.2f|%.2f|%.2f|%s|%s\n",
                o->id, o->customer, o->itemCount, o->subtotal, o->discount, o->tax, o->total, o->status, o->createdAt);
        for (int j = 0; j < o->itemCount; j++) {
            OrderItem *it = &o->items[j];
            fprintf(f, "ITEM|%d|%s|%d|%.2f|%.2f\n",
                    it->productId, it->productName, it->qty, it->unitPrice, it->lineTotal);
        }
        fprintf(f, "END\n");
    }
    fclose(f);
}

static void saveAll(void) {
    saveProducts();
    saveOrders();
    printf("[OK] Data saved to %s and %s.\n", PRODUCT_FILE, ORDER_FILE);
}

static void loadProducts(void) {
    FILE *f = fopen(PRODUCT_FILE, "r");
    if (!f) {
        return;
    }

    char line[512];
    productCount = 0;
    nextProductId = 1;

    while (fgets(line, sizeof(line), f)) {
        trim(line);
        if (line[0] == '\0' || line[0] == '#') continue;
        if (productCount >= MAX_PRODUCTS) break;

        char *id = strtok(line, "|");
        char *name = strtok(NULL, "|");
        char *cat = strtok(NULL, "|");
        char *price = strtok(NULL, "|");
        char *stock = strtok(NULL, "|");
        char *sold = strtok(NULL, "|");
        char *active = strtok(NULL, "|");

        if (!id || !name || !cat || !price || !stock || !sold || !active) continue;

        Product p;
        memset(&p, 0, sizeof(p));
        if (!parseIntStrict(id, &p.id)) continue;
        safeCopy(p.name, name, sizeof(p.name));
        safeCopy(p.category, cat, sizeof(p.category));
        if (!parseDoubleStrict(price, &p.price)) continue;
        if (!parseIntStrict(stock, &p.stock)) continue;
        if (!parseIntStrict(sold, &p.sold)) continue;
        if (!parseIntStrict(active, &p.active)) continue;

        if (p.id <= 0 || p.price < 0 || p.stock < 0 || p.sold < 0) continue;
        products[productCount++] = p;
        if (p.id >= nextProductId) nextProductId = p.id + 1;
    }

    fclose(f);
}

static void loadOrders(void) {
    FILE *f = fopen(ORDER_FILE, "r");
    if (!f) {
        return;
    }

    char line[512];
    orderCount = 0;
    nextOrderId = 1;
    Order current;
    int readingOrder = 0;

    while (fgets(line, sizeof(line), f)) {
        trim(line);
        if (line[0] == '\0' || line[0] == '#') continue;

        if (strncmp(line, "ORDER|", 6) == 0) {
            memset(&current, 0, sizeof(current));
            readingOrder = 1;

            char *tag = strtok(line, "|");
            char *id = strtok(NULL, "|");
            char *customer = strtok(NULL, "|");
            char *itemCountStr = strtok(NULL, "|");
            char *subtotal = strtok(NULL, "|");
            char *discount = strtok(NULL, "|");
            char *tax = strtok(NULL, "|");
            char *total = strtok(NULL, "|");
            char *status = strtok(NULL, "|");
            char *createdAt = strtok(NULL, "|");
            (void)tag;

            if (!id || !customer || !itemCountStr || !subtotal || !discount || !tax || !total || !status || !createdAt) {
                readingOrder = 0;
                continue;
            }

            if (!parseIntStrict(id, &current.id)) { readingOrder = 0; continue; }
            safeCopy(current.customer, customer, sizeof(current.customer));
            /* itemCount is rebuilt from ITEM lines to avoid trusting corrupt files. */
            if (!parseDoubleStrict(subtotal, &current.subtotal)) { readingOrder = 0; continue; }
            if (!parseDoubleStrict(discount, &current.discount)) { readingOrder = 0; continue; }
            if (!parseDoubleStrict(tax, &current.tax)) { readingOrder = 0; continue; }
            if (!parseDoubleStrict(total, &current.total)) { readingOrder = 0; continue; }
            safeCopy(current.status, status, sizeof(current.status));
            safeCopy(current.createdAt, createdAt, sizeof(current.createdAt));

            if (current.id >= nextOrderId) nextOrderId = current.id + 1;
        } else if (strncmp(line, "ITEM|", 5) == 0 && readingOrder) {
            if (current.itemCount >= MAX_ITEMS_PER_ORDER) continue;
            char *tag = strtok(line, "|");
            char *pid = strtok(NULL, "|");
            char *pname = strtok(NULL, "|");
            char *qty = strtok(NULL, "|");
            char *unit = strtok(NULL, "|");
            char *lineTotal = strtok(NULL, "|");
            (void)tag;
            if (!pid || !pname || !qty || !unit || !lineTotal) continue;

            OrderItem it;
            memset(&it, 0, sizeof(it));
            if (!parseIntStrict(pid, &it.productId)) continue;
            safeCopy(it.productName, pname, sizeof(it.productName));
            if (!parseIntStrict(qty, &it.qty)) continue;
            if (!parseDoubleStrict(unit, &it.unitPrice)) continue;
            if (!parseDoubleStrict(lineTotal, &it.lineTotal)) continue;
            if (it.qty <= 0 || it.unitPrice < 0 || it.lineTotal < 0) continue;

            current.items[current.itemCount++] = it;
        } else if (strcmp(line, "END") == 0 && readingOrder) {
            if (orderCount < MAX_ORDERS && current.id > 0 && current.itemCount > 0) {
                orders[orderCount++] = current;
            }
            readingOrder = 0;
        }
    }

    fclose(f);
}

static void loadAll(void) {
    loadProducts();
    loadOrders();
}

static void exportReceipt(void) {
    if (orderCount == 0) {
        printf("No orders to export.\n");
        return;
    }

    listOrders();
    int id = readIntRange("Order ID to export receipt, 0 to cancel: ", 0, INT_MAX);
    if (id == 0) return;

    int idx = findOrderIndexById(id);
    if (idx < 0) {
        printf("[Not found] Order does not exist.\n");
        return;
    }

    char filename[64];
    snprintf(filename, sizeof(filename), "receipt_%d.txt", id);
    FILE *f = fopen(filename, "w");
    if (!f) {
        printf("[File error] Cannot create receipt.\n");
        return;
    }

    Order *o = &orders[idx];
    fprintf(f, "SMART SHOP RECEIPT\n");
    fprintf(f, "==================\n");
    fprintf(f, "Order ID : %d\n", o->id);
    fprintf(f, "Customer : %s\n", o->customer);
    fprintf(f, "Status   : %s\n", o->status);
    fprintf(f, "Created  : %s\n\n", o->createdAt);
    fprintf(f, "%-6s %-30s %6s %12s %12s\n", "PID", "Product", "Qty", "Unit", "Line");
    for (int i = 0; i < o->itemCount; i++) {
        fprintf(f, "%-6d %-30.30s %6d %12.2f %12.2f\n",
                o->items[i].productId, o->items[i].productName,
                o->items[i].qty, o->items[i].unitPrice, o->items[i].lineTotal);
    }
    fprintf(f, "\nSubtotal : $%.2f\n", o->subtotal);
    fprintf(f, "Discount : $%.2f\n", o->discount);
    fprintf(f, "Tax      : $%.2f\n", o->tax);
    fprintf(f, "Total    : $%.2f\n", o->total);
    fclose(f);

    printf("[OK] Receipt exported to %s\n", filename);
}

/* ======================= Demo Data ======================= */

static void seedDemoData(void) {
    if (productCount > 0) {
        printf("Seed skipped: product list is not empty.\n");
        return;
    }

    Product demo[] = {
        {1, "Mechanical Keyboard", "Electronics", 89.99, 15, 0, 1},
        {2, "Gaming Mouse", "Electronics", 39.50, 25, 0, 1},
        {3, "USB-C Cable", "Accessories", 8.75, 100, 0, 1},
        {4, "Office Chair", "Furniture", 129.00, 7, 0, 1},
        {5, "Water Bottle", "Lifestyle", 12.25, 3, 0, 1},
        {6, "Notebook A5", "Stationery", 3.40, 60, 0, 1}
    };

    int n = (int)(sizeof(demo) / sizeof(demo[0]));
    for (int i = 0; i < n && productCount < MAX_PRODUCTS; i++) {
        products[productCount++] = demo[i];
        if (demo[i].id >= nextProductId) nextProductId = demo[i].id + 1;
    }
    printf("[OK] Demo products inserted.\n");
}

/* ======================= Menus ======================= */

static void productMenu(void) {
    while (1) {
        printf("\n===== PRODUCT MENU =====\n");
        printf("1. List products\n");
        printf("2. Add product\n");
        printf("3. Update product\n");
        printf("4. Restock product\n");
        printf("5. Delete product\n");
        printf("6. Search products\n");
        printf("7. Sort products\n");
        printf("0. Back\n");
        int choice = readIntRange("Choose: ", 0, 7);

        if (choice == 0) return;
        if (choice == 1) listProducts();
        else if (choice == 2) addProduct();
        else if (choice == 3) updateProduct();
        else if (choice == 4) restockProduct();
        else if (choice == 5) deleteProduct();
        else if (choice == 6) searchProducts();
        else if (choice == 7) sortProductsMenu();
        pauseEnter();
    }
}

static void orderMenu(void) {
    while (1) {
        printf("\n===== ORDER MENU =====\n");
        printf("1. Create order\n");
        printf("2. List orders\n");
        printf("3. View order detail\n");
        printf("4. Cancel order\n");
        printf("5. Export receipt\n");
        printf("0. Back\n");
        int choice = readIntRange("Choose: ", 0, 5);

        if (choice == 0) return;
        if (choice == 1) createOrder();
        else if (choice == 2) listOrders();
        else if (choice == 3) viewOrderDetail();
        else if (choice == 4) cancelOrder();
        else if (choice == 5) exportReceipt();
        pauseEnter();
    }
}

static void printDashboard(void) {
    double inventoryValue = 0.0;
    double revenue = 0.0;
    int lowStock = 0;

    for (int i = 0; i < productCount; i++) {
        if (!products[i].active) continue;
        inventoryValue += products[i].price * products[i].stock;
        if (products[i].stock <= 5) lowStock++;
    }

    for (int i = 0; i < orderCount; i++) {
        if (strcmp(orders[i].status, "PAID") == 0) revenue += orders[i].total;
    }

    printf("\n========== DASHBOARD ==========" "\n");
    printf("Active products : %d\n", activeProductCount());
    printf("Orders          : %d\n", orderCount);
    printf("Low stock <= 5  : %d\n", lowStock);
    printf("Inventory value : "); printMoney(inventoryValue); printf("\n");
    printf("Revenue         : "); printMoney(revenue); printf("\n");
}

static void mainMenu(void) {
    while (1) {
        printf("\n===== SMART SHOP MANAGER =====\n");
        printf("1. Dashboard\n");
        printf("2. Products\n");
        printf("3. Orders\n");
        printf("4. Reports\n");
        printf("5. Save data\n");
        printf("6. Seed demo data\n");
        printf("7. Clear screen\n");
        printf("0. Save and exit\n");

        int choice = readIntRange("Choose: ", 0, 7);
        if (choice == 0) {
            saveAll();
            printf("Bye.\n");
            return;
        }
        if (choice == 1) printDashboard();
        else if (choice == 2) productMenu();
        else if (choice == 3) orderMenu();
        else if (choice == 4) reportsMenu();
        else if (choice == 5) saveAll();
        else if (choice == 6) seedDemoData();
        else if (choice == 7) clearScreen();

        if (choice != 7) pauseEnter();
    }
}

int main(void) {
    loadAll();

    printf("Loaded %d products and %d orders.\n", productCount, orderCount);
    printf("Data files: %s, %s\n", PRODUCT_FILE, ORDER_FILE);

    if (productCount == 0) {
        printf("No products found. You can seed demo data from main menu option 6.\n");
    }

    mainMenu();
    return 0;
}
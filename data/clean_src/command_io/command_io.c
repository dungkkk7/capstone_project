#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <limits.h>

/*
    SHOP COMMAND I/O - NO SSE VERSION
    ---------------------------------
    - No float, no double, no strtod, no %f
    - Money is stored as integer cents: 89.99 -> 8999
    - Input is command-based. Paste input once, get output immediately.

    Format:
        First line: Q = number of commands
        Then Q lines, each command uses | as separator.

    Example commands:
        ADD|1|Keyboard|Electronics|89.99|15
        LIST
        BUY|Nguyen Van A|VIP10|1:2,3:5
        REPORT
*/

#define MAX_PRODUCTS 1000
#define MAX_ORDERS 1000
#define MAX_ORDER_ITEMS 64
#define MAX_LINE 2048
#define MAX_NAME 80
#define MAX_CATEGORY 50
#define SHIPPING_CENTS 300
#define TAX_PERCENT 8

#define OK 1
#define FAIL 0

typedef long long ll;

typedef struct {
    int id;
    char name[MAX_NAME];
    char category[MAX_CATEGORY];
    ll price;             /* cents */
    int stock;
    int sold;
    int active;
} Product;

typedef struct {
    int productId;
    char productName[MAX_NAME];
    int qty;
    ll unitPrice;
    ll lineTotal;
} OrderItem;

typedef struct {
    int id;
    char customer[MAX_NAME];
    char discountCode[30];
    OrderItem items[MAX_ORDER_ITEMS];
    int itemCount;
    ll subtotal;
    ll discount;
    ll shipping;
    ll tax;
    ll total;
    int cancelled;
} Order;

Product products[MAX_PRODUCTS];
Order orders[MAX_ORDERS];
int productCount = 0;
int orderCount = 0;
int nextOrderId = 1;

void trim(char *s) {
    int len;
    int start = 0;
    while (s[start] && isspace((unsigned char)s[start])) start++;
    if (start > 0) memmove(s, s + start, strlen(s + start) + 1);
    len = (int)strlen(s);
    while (len > 0 && isspace((unsigned char)s[len - 1])) {
        s[len - 1] = '\0';
        len--;
    }
}

void upperString(char *s) {
    int i;
    for (i = 0; s[i]; i++) s[i] = (char)toupper((unsigned char)s[i]);
}

int equalsIgnoreCase(const char *a, const char *b) {
    while (*a && *b) {
        if (toupper((unsigned char)*a) != toupper((unsigned char)*b)) return 0;
        a++;
        b++;
    }
    return *a == '\0' && *b == '\0';
}

int containsIgnoreCase(const char *text, const char *key) {
    int n = (int)strlen(text);
    int m = (int)strlen(key);
    int i, j;
    if (m == 0) return 1;
    if (m > n) return 0;
    for (i = 0; i <= n - m; i++) {
        int ok = 1;
        for (j = 0; j < m; j++) {
            if (toupper((unsigned char)text[i + j]) != toupper((unsigned char)key[j])) {
                ok = 0;
                break;
            }
        }
        if (ok) return 1;
    }
    return 0;
}

void printMoney(ll cents) {
    if (cents < 0) {
        putchar('-');
        cents = -cents;
    }
    printf("%lld.%02lld", cents / 100, cents % 100);
}

int parseIntStrict(const char *s, int *out) {
    long val = 0;
    int sign = 1;
    int i = 0;
    if (s == NULL || s[0] == '\0') return FAIL;
    if (s[i] == '-') {
        sign = -1;
        i++;
        if (!s[i]) return FAIL;
    }
    while (s[i]) {
        if (!isdigit((unsigned char)s[i])) return FAIL;
        val = val * 10 + (s[i] - '0');
        if (sign == 1 && val > INT_MAX) return FAIL;
        if (sign == -1 && -val < INT_MIN) return FAIL;
        i++;
    }
    *out = (int)(val * sign);
    return OK;
}

int parseMoneyStrict(const char *s, ll *out) {
    ll dollars = 0;
    ll cents = 0;
    int i = 0;
    int decimalSeen = 0;
    int decimalDigits = 0;

    if (s == NULL || s[0] == '\0') return FAIL;
    if (s[0] == '-') return FAIL;

    while (s[i]) {
        if (s[i] == '.') {
            if (decimalSeen) return FAIL;
            decimalSeen = 1;
        } else if (isdigit((unsigned char)s[i])) {
            if (!decimalSeen) {
                dollars = dollars * 10 + (s[i] - '0');
                if (dollars > 9000000000000LL) return FAIL;
            } else {
                if (decimalDigits >= 2) return FAIL;
                cents = cents * 10 + (s[i] - '0');
                decimalDigits++;
            }
        } else {
            return FAIL;
        }
        i++;
    }

    if (decimalSeen && decimalDigits == 1) cents *= 10;
    if (decimalSeen && decimalDigits == 0) cents = 0;
    *out = dollars * 100 + cents;
    return OK;
}

int splitPipe(char *line, char *parts[], int maxParts) {
    int count = 0;
    char *p = line;
    parts[count++] = p;

    while (*p && count < maxParts) {
        if (*p == '|') {
            *p = '\0';
            parts[count++] = p + 1;
        }
        p++;
    }

    for (int i = 0; i < count; i++) trim(parts[i]);
    return count;
}

int findProductIndexById(int id) {
    int i;
    for (i = 0; i < productCount; i++) {
        if (products[i].id == id) return i;
    }
    return -1;
}

int findOrderIndexById(int id) {
    int i;
    for (i = 0; i < orderCount; i++) {
        if (orders[i].id == id) return i;
    }
    return -1;
}

void printProductHeader(void) {
    printf("ID | NAME | CATEGORY | PRICE | STOCK | SOLD | STATUS\n");
}

void printProduct(const Product *p) {
    printf("%d | %s | %s | ", p->id, p->name, p->category);
    printMoney(p->price);
    printf(" | %d | %d | %s\n", p->stock, p->sold, p->active ? "ACTIVE" : "REMOVED");
}

void cmdAdd(char *parts[], int n) {
    int id, stock;
    ll price;

    if (n != 6) {
        printf("ERR ADD needs 5 fields: ADD|id|name|category|price|stock\n");
        return;
    }

    if (!parseIntStrict(parts[1], &id) || id <= 0) {
        printf("ERR ADD invalid id\n");
        return;
    }
    if (findProductIndexById(id) != -1) {
        printf("ERR ADD duplicate id %d\n", id);
        return;
    }
    if (strlen(parts[2]) == 0 || strlen(parts[2]) >= MAX_NAME) {
        printf("ERR ADD invalid name\n");
        return;
    }
    if (strlen(parts[3]) == 0 || strlen(parts[3]) >= MAX_CATEGORY) {
        printf("ERR ADD invalid category\n");
        return;
    }
    if (!parseMoneyStrict(parts[4], &price) || price <= 0) {
        printf("ERR ADD invalid price\n");
        return;
    }
    if (!parseIntStrict(parts[5], &stock) || stock < 0) {
        printf("ERR ADD invalid stock\n");
        return;
    }
    if (productCount >= MAX_PRODUCTS) {
        printf("ERR ADD product storage full\n");
        return;
    }

    products[productCount].id = id;
    strcpy(products[productCount].name, parts[2]);
    strcpy(products[productCount].category, parts[3]);
    products[productCount].price = price;
    products[productCount].stock = stock;
    products[productCount].sold = 0;
    products[productCount].active = 1;
    productCount++;

    printf("OK ADD %d %s\n", id, parts[2]);
}

void cmdRemove(char *parts[], int n) {
    int id, idx;
    if (n != 2 || !parseIntStrict(parts[1], &id)) {
        printf("ERR REMOVE invalid format\n");
        return;
    }
    idx = findProductIndexById(id);
    if (idx == -1) {
        printf("ERR REMOVE product %d not found\n", id);
        return;
    }
    if (!products[idx].active) {
        printf("ERR REMOVE product %d already removed\n", id);
        return;
    }
    products[idx].active = 0;
    printf("OK REMOVE %d\n", id);
}

void cmdRestock(char *parts[], int n) {
    int id, qty, idx;
    if (n != 3 || !parseIntStrict(parts[1], &id) || !parseIntStrict(parts[2], &qty)) {
        printf("ERR RESTOCK invalid format\n");
        return;
    }
    if (qty <= 0) {
        printf("ERR RESTOCK qty must be positive\n");
        return;
    }
    idx = findProductIndexById(id);
    if (idx == -1 || !products[idx].active) {
        printf("ERR RESTOCK product %d not found or removed\n", id);
        return;
    }
    if (products[idx].stock > INT_MAX - qty) {
        printf("ERR RESTOCK stock overflow\n");
        return;
    }
    products[idx].stock += qty;
    printf("OK RESTOCK %d STOCK=%d\n", id, products[idx].stock);
}

void cmdUpdatePrice(char *parts[], int n) {
    int id, idx;
    ll price;
    if (n != 3 || !parseIntStrict(parts[1], &id) || !parseMoneyStrict(parts[2], &price) || price <= 0) {
        printf("ERR UPDATE_PRICE invalid format\n");
        return;
    }
    idx = findProductIndexById(id);
    if (idx == -1 || !products[idx].active) {
        printf("ERR UPDATE_PRICE product %d not found or removed\n", id);
        return;
    }
    products[idx].price = price;
    printf("OK UPDATE_PRICE %d PRICE=", id);
    printMoney(price);
    printf("\n");
}

void cmdList(void) {
    int any = 0;
    printProductHeader();
    for (int i = 0; i < productCount; i++) {
        if (products[i].active) {
            printProduct(&products[i]);
            any = 1;
        }
    }
    if (!any) printf("EMPTY PRODUCT_LIST\n");
}

void cmdSearchName(char *parts[], int n) {
    int any = 0;
    if (n != 2 || strlen(parts[1]) == 0) {
        printf("ERR SEARCH_NAME invalid format\n");
        return;
    }
    printProductHeader();
    for (int i = 0; i < productCount; i++) {
        if (products[i].active && containsIgnoreCase(products[i].name, parts[1])) {
            printProduct(&products[i]);
            any = 1;
        }
    }
    if (!any) printf("NO_MATCH NAME %s\n", parts[1]);
}

void cmdSearchCategory(char *parts[], int n) {
    int any = 0;
    if (n != 2 || strlen(parts[1]) == 0) {
        printf("ERR SEARCH_CATEGORY invalid format\n");
        return;
    }
    printProductHeader();
    for (int i = 0; i < productCount; i++) {
        if (products[i].active && containsIgnoreCase(products[i].category, parts[1])) {
            printProduct(&products[i]);
            any = 1;
        }
    }
    if (!any) printf("NO_MATCH CATEGORY %s\n", parts[1]);
}

void cmdLowStock(char *parts[], int n) {
    int limit, any = 0;
    if (n != 2 || !parseIntStrict(parts[1], &limit) || limit < 0) {
        printf("ERR LOW_STOCK invalid format\n");
        return;
    }
    printProductHeader();
    for (int i = 0; i < productCount; i++) {
        if (products[i].active && products[i].stock <= limit) {
            printProduct(&products[i]);
            any = 1;
        }
    }
    if (!any) printf("NO_LOW_STOCK <= %d\n", limit);
}

int cmpPriceAsc(const void *a, const void *b) {
    const Product *x = (const Product *)a;
    const Product *y = (const Product *)b;
    if (x->active != y->active) return y->active - x->active;
    if (x->price < y->price) return -1;
    if (x->price > y->price) return 1;
    return x->id - y->id;
}

int cmpPriceDesc(const void *a, const void *b) {
    const Product *x = (const Product *)a;
    const Product *y = (const Product *)b;
    if (x->active != y->active) return y->active - x->active;
    if (x->price > y->price) return -1;
    if (x->price < y->price) return 1;
    return x->id - y->id;
}

int cmpStockAsc(const void *a, const void *b) {
    const Product *x = (const Product *)a;
    const Product *y = (const Product *)b;
    if (x->active != y->active) return y->active - x->active;
    if (x->stock != y->stock) return x->stock - y->stock;
    return x->id - y->id;
}

int cmpSoldDesc(const void *a, const void *b) {
    const Product *x = (const Product *)a;
    const Product *y = (const Product *)b;
    if (x->active != y->active) return y->active - x->active;
    if (x->sold != y->sold) return y->sold - x->sold;
    return x->id - y->id;
}

int cmpNameAsc(const void *a, const void *b) {
    const Product *x = (const Product *)a;
    const Product *y = (const Product *)b;
    if (x->active != y->active) return y->active - x->active;
    return strcmp(x->name, y->name);
}

void cmdSort(char *parts[], int n) {
    char mode[64];
    if (n != 2) {
        printf("ERR SORT invalid format\n");
        return;
    }
    strcpy(mode, parts[1]);
    upperString(mode);

    if (equalsIgnoreCase(mode, "PRICE_ASC")) qsort(products, productCount, sizeof(Product), cmpPriceAsc);
    else if (equalsIgnoreCase(mode, "PRICE_DESC")) qsort(products, productCount, sizeof(Product), cmpPriceDesc);
    else if (equalsIgnoreCase(mode, "STOCK_ASC")) qsort(products, productCount, sizeof(Product), cmpStockAsc);
    else if (equalsIgnoreCase(mode, "SOLD_DESC")) qsort(products, productCount, sizeof(Product), cmpSoldDesc);
    else if (equalsIgnoreCase(mode, "NAME_ASC")) qsort(products, productCount, sizeof(Product), cmpNameAsc);
    else {
        printf("ERR SORT unknown mode %s\n", parts[1]);
        return;
    }

    printf("OK SORT %s\n", mode);
    cmdList();
}

ll calculateDiscount(ll subtotal, const char *code) {
    if (equalsIgnoreCase(code, "NONE")) return 0;
    if (equalsIgnoreCase(code, "VIP10")) return subtotal * 10 / 100;
    if (equalsIgnoreCase(code, "BULK15")) {
        if (subtotal >= 50000) return subtotal * 15 / 100;
        return 0;
    }
    if (equalsIgnoreCase(code, "FREESHIP")) return 0;
    return -1;
}

void printOrderShort(const Order *o) {
    printf("ORDER %d | CUSTOMER=%s | ITEMS=%d | SUBTOTAL=", o->id, o->customer, o->itemCount);
    printMoney(o->subtotal);
    printf(" | DISCOUNT=");
    printMoney(o->discount);
    printf(" | SHIPPING=");
    printMoney(o->shipping);
    printf(" | TAX=");
    printMoney(o->tax);
    printf(" | TOTAL=");
    printMoney(o->total);
    printf(" | STATUS=%s\n", o->cancelled ? "CANCELLED" : "PAID");
}

void printOrderDetail(const Order *o) {
    printf("ORDER_DETAIL %d\n", o->id);
    printf("CUSTOMER %s\n", o->customer);
    printf("DISCOUNT_CODE %s\n", o->discountCode);
    printf("STATUS %s\n", o->cancelled ? "CANCELLED" : "PAID");
    printf("ITEMS\n");
    for (int i = 0; i < o->itemCount; i++) {
        printf("%d | %s | QTY=%d | UNIT=", o->items[i].productId, o->items[i].productName, o->items[i].qty);
        printMoney(o->items[i].unitPrice);
        printf(" | LINE=");
        printMoney(o->items[i].lineTotal);
        printf("\n");
    }
    printf("SUBTOTAL "); printMoney(o->subtotal); printf("\n");
    printf("DISCOUNT "); printMoney(o->discount); printf("\n");
    printf("SHIPPING "); printMoney(o->shipping); printf("\n");
    printf("TAX "); printMoney(o->tax); printf("\n");
    printf("TOTAL "); printMoney(o->total); printf("\n");
}

int parseCartItem(char *token, int *productId, int *qty) {
    char *colon = strchr(token, ':');
    if (colon == NULL) return FAIL;
    *colon = '\0';
    trim(token);
    trim(colon + 1);
    if (!parseIntStrict(token, productId)) return FAIL;
    if (!parseIntStrict(colon + 1, qty)) return FAIL;
    if (*productId <= 0 || *qty <= 0) return FAIL;
    return OK;
}

int cartAlreadyHas(Order *o, int productId) {
    for (int i = 0; i < o->itemCount; i++) {
        if (o->items[i].productId == productId) return i;
    }
    return -1;
}

void cmdBuy(char *parts[], int n) {
    Order tmp;
    char cartCopy[MAX_LINE];
    char *token;
    ll subtotal = 0;
    ll discount;
    ll shipping;
    ll tax;
    int stockNeed[MAX_PRODUCTS];

    if (n != 4) {
        printf("ERR BUY needs 3 fields: BUY|customer|discount|id:qty,id:qty\n");
        return;
    }
    if (strlen(parts[1]) == 0 || strlen(parts[1]) >= MAX_NAME) {
        printf("ERR BUY invalid customer\n");
        return;
    }
    if (strlen(parts[2]) == 0 || strlen(parts[2]) >= 30) {
        printf("ERR BUY invalid discount code\n");
        return;
    }
    if (strlen(parts[3]) == 0) {
        printf("ERR BUY empty cart\n");
        return;
    }
    if (orderCount >= MAX_ORDERS) {
        printf("ERR BUY order storage full\n");
        return;
    }

    discount = calculateDiscount(1000, parts[2]);
    if (discount < 0) {
        printf("ERR BUY unknown discount code %s\n", parts[2]);
        return;
    }

    memset(&tmp, 0, sizeof(tmp));
    memset(stockNeed, 0, sizeof(stockNeed));
    strcpy(tmp.customer, parts[1]);
    strcpy(tmp.discountCode, parts[2]);

    strcpy(cartCopy, parts[3]);
    token = strtok(cartCopy, ",");
    while (token != NULL) {
        int pid, qty, idx, existing;
        trim(token);
        if (!parseCartItem(token, &pid, &qty)) {
            printf("ERR BUY bad cart item\n");
            return;
        }
        idx = findProductIndexById(pid);
        if (idx == -1 || !products[idx].active) {
            printf("ERR BUY product %d not found or removed\n", pid);
            return;
        }
        if (qty > products[idx].stock - stockNeed[idx]) {
            printf("ERR BUY product %d insufficient stock requested=%d available=%d\n",
                   pid, qty + stockNeed[idx], products[idx].stock);
            return;
        }
        existing = cartAlreadyHas(&tmp, pid);
        if (existing != -1) {
            tmp.items[existing].qty += qty;
            tmp.items[existing].lineTotal += products[idx].price * qty;
        } else {
            if (tmp.itemCount >= MAX_ORDER_ITEMS) {
                printf("ERR BUY too many distinct items\n");
                return;
            }
            tmp.items[tmp.itemCount].productId = pid;
            strcpy(tmp.items[tmp.itemCount].productName, products[idx].name);
            tmp.items[tmp.itemCount].qty = qty;
            tmp.items[tmp.itemCount].unitPrice = products[idx].price;
            tmp.items[tmp.itemCount].lineTotal = products[idx].price * qty;
            tmp.itemCount++;
        }
        stockNeed[idx] += qty;
        subtotal += products[idx].price * qty;
        token = strtok(NULL, ",");
    }

    if (tmp.itemCount == 0) {
        printf("ERR BUY empty cart\n");
        return;
    }

    discount = calculateDiscount(subtotal, parts[2]);
    shipping = equalsIgnoreCase(parts[2], "FREESHIP") ? 0 : SHIPPING_CENTS;
    tax = (subtotal - discount) * TAX_PERCENT / 100;

    tmp.id = nextOrderId++;
    tmp.subtotal = subtotal;
    tmp.discount = discount;
    tmp.shipping = shipping;
    tmp.tax = tax;
    tmp.total = subtotal - discount + shipping + tax;
    tmp.cancelled = 0;

    for (int i = 0; i < productCount; i++) {
        if (stockNeed[i] > 0) {
            products[i].stock -= stockNeed[i];
            products[i].sold += stockNeed[i];
        }
    }

    orders[orderCount++] = tmp;

    printf("OK BUY ");
    printOrderShort(&tmp);
    if (equalsIgnoreCase(parts[2], "BULK15") && discount == 0) {
        printf("NOTICE BULK15 requires subtotal >= 500.00\n");
    }
}

void cmdCancel(char *parts[], int n) {
    int id, oi;
    if (n != 2 || !parseIntStrict(parts[1], &id)) {
        printf("ERR CANCEL invalid format\n");
        return;
    }
    oi = findOrderIndexById(id);
    if (oi == -1) {
        printf("ERR CANCEL order %d not found\n", id);
        return;
    }
    if (orders[oi].cancelled) {
        printf("ERR CANCEL order %d already cancelled\n", id);
        return;
    }

    for (int i = 0; i < orders[oi].itemCount; i++) {
        int pi = findProductIndexById(orders[oi].items[i].productId);
        if (pi != -1) {
            products[pi].stock += orders[oi].items[i].qty;
            if (products[pi].sold >= orders[oi].items[i].qty) {
                products[pi].sold -= orders[oi].items[i].qty;
            } else {
                products[pi].sold = 0;
            }
        }
    }
    orders[oi].cancelled = 1;
    printf("OK CANCEL %d REFUNDED_STOCK\n", id);
}

void cmdOrder(char *parts[], int n) {
    int id, idx;
    if (n != 2 || !parseIntStrict(parts[1], &id)) {
        printf("ERR ORDER invalid format\n");
        return;
    }
    idx = findOrderIndexById(id);
    if (idx == -1) {
        printf("ERR ORDER %d not found\n", id);
        return;
    }
    printOrderDetail(&orders[idx]);
}

void cmdOrders(void) {
    int any = 0;
    for (int i = 0; i < orderCount; i++) {
        printOrderShort(&orders[i]);
        any = 1;
    }
    if (!any) printf("EMPTY ORDER_LIST\n");
}

void cmdReport(void) {
    int paid = 0, cancelled = 0, units = 0;
    ll gross = 0, discount = 0, shipping = 0, tax = 0, total = 0, inventoryValue = 0;
    int topId = -1;
    int topSold = -1;

    for (int i = 0; i < orderCount; i++) {
        if (orders[i].cancelled) {
            cancelled++;
        } else {
            paid++;
            gross += orders[i].subtotal;
            discount += orders[i].discount;
            shipping += orders[i].shipping;
            tax += orders[i].tax;
            total += orders[i].total;
            for (int j = 0; j < orders[i].itemCount; j++) units += orders[i].items[j].qty;
        }
    }

    for (int i = 0; i < productCount; i++) {
        if (products[i].active) {
            inventoryValue += products[i].price * products[i].stock;
            if (products[i].sold > topSold) {
                topSold = products[i].sold;
                topId = products[i].id;
            }
        }
    }

    printf("REPORT\n");
    printf("PAID_ORDERS %d\n", paid);
    printf("CANCELLED_ORDERS %d\n", cancelled);
    printf("UNITS_SOLD %d\n", units);
    printf("GROSS "); printMoney(gross); printf("\n");
    printf("DISCOUNT "); printMoney(discount); printf("\n");
    printf("SHIPPING "); printMoney(shipping); printf("\n");
    printf("TAX "); printMoney(tax); printf("\n");
    printf("NET_REVENUE "); printMoney(total); printf("\n");
    printf("INVENTORY_VALUE "); printMoney(inventoryValue); printf("\n");
    if (topId == -1 || topSold <= 0) printf("TOP_PRODUCT NONE\n");
    else printf("TOP_PRODUCT %d SOLD=%d\n", topId, topSold);
}

void cmdSave(char *parts[], int n) {
    FILE *fp;
    if (n != 2) {
        printf("ERR SAVE invalid format: SAVE|filename\n");
        return;
    }
    fp = fopen(parts[1], "w");
    if (!fp) {
        printf("ERR SAVE cannot open %s\n", parts[1]);
        return;
    }

    fprintf(fp, "PRODUCTS %d\n", productCount);
    for (int i = 0; i < productCount; i++) {
        fprintf(fp, "%d|%s|%s|%lld|%d|%d|%d\n",
                products[i].id,
                products[i].name,
                products[i].category,
                products[i].price,
                products[i].stock,
                products[i].sold,
                products[i].active);
    }

    fprintf(fp, "ORDERS %d\n", orderCount);
    for (int i = 0; i < orderCount; i++) {
        fprintf(fp, "%d|%s|%s|%d|%lld|%lld|%lld|%lld|%lld|%d\n",
                orders[i].id,
                orders[i].customer,
                orders[i].discountCode,
                orders[i].itemCount,
                orders[i].subtotal,
                orders[i].discount,
                orders[i].shipping,
                orders[i].tax,
                orders[i].total,
                orders[i].cancelled);
        for (int j = 0; j < orders[i].itemCount; j++) {
            fprintf(fp, "%d|%s|%d|%lld|%lld\n",
                    orders[i].items[j].productId,
                    orders[i].items[j].productName,
                    orders[i].items[j].qty,
                    orders[i].items[j].unitPrice,
                    orders[i].items[j].lineTotal);
        }
    }

    fclose(fp);
    printf("OK SAVE %s\n", parts[1]);
}

void handleCommand(char *line, int commandNumber) {
    char *parts[16];
    int n;
    char cmd[64];

    trim(line);
    if (line[0] == '\0') {
        printf("ERR LINE %d empty command\n", commandNumber);
        return;
    }

    n = splitPipe(line, parts, 16);
    strcpy(cmd, parts[0]);
    upperString(cmd);

    printf(">>> %s\n", cmd);

    if (strcmp(cmd, "ADD") == 0) cmdAdd(parts, n);
    else if (strcmp(cmd, "REMOVE") == 0) cmdRemove(parts, n);
    else if (strcmp(cmd, "RESTOCK") == 0) cmdRestock(parts, n);
    else if (strcmp(cmd, "UPDATE_PRICE") == 0) cmdUpdatePrice(parts, n);
    else if (strcmp(cmd, "LIST") == 0) cmdList();
    else if (strcmp(cmd, "SEARCH_NAME") == 0) cmdSearchName(parts, n);
    else if (strcmp(cmd, "SEARCH_CATEGORY") == 0) cmdSearchCategory(parts, n);
    else if (strcmp(cmd, "LOW_STOCK") == 0) cmdLowStock(parts, n);
    else if (strcmp(cmd, "SORT") == 0) cmdSort(parts, n);
    else if (strcmp(cmd, "BUY") == 0) cmdBuy(parts, n);
    else if (strcmp(cmd, "CANCEL") == 0) cmdCancel(parts, n);
    else if (strcmp(cmd, "ORDER") == 0) cmdOrder(parts, n);
    else if (strcmp(cmd, "ORDERS") == 0) cmdOrders();
    else if (strcmp(cmd, "REPORT") == 0) cmdReport();
    else if (strcmp(cmd, "SAVE") == 0) cmdSave(parts, n);
    else printf("ERR UNKNOWN_COMMAND %s\n", parts[0]);
}

int main(void) {
    char line[MAX_LINE];
    int q;

    if (!fgets(line, sizeof(line), stdin)) {
        printf("ERR missing command count\n");
        return 0;
    }
    trim(line);
    if (!parseIntStrict(line, &q) || q < 0) {
        printf("ERR invalid command count\n");
        return 0;
    }

    printf("SHOP_COMMAND_IO_START Q=%d\n", q);

    for (int i = 1; i <= q; i++) {
        if (!fgets(line, sizeof(line), stdin)) {
            printf("ERR missing command at line %d\n", i);
            break;
        }
        handleCommand(line, i);
    }

    printf("SHOP_COMMAND_IO_END PRODUCTS=%d ORDERS=%d\n", productCount, orderCount);
    return 0;
}
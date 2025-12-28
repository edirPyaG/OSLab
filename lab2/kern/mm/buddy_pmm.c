#include <buddy_pmm.h>
#include <assert.h>
#include <string.h>
#include <stdio.h>

static buddy_system_t buddy;
static struct Page *buddy_base;
static size_t buddy_npages;


// 获取页索引
static inline size_t page_index(struct Page *page){
    return page - buddy_base;
}

// 判断是否在范围内
static inline int in_range(struct Page *page){
    return page >= buddy_base && page < buddy_base + buddy_npages;
}

// 获取伙伴页
static inline struct Page *buddy_of(struct Page *page, int order){
    size_t idx = page_index(page);
    size_t buddy_idx = idx ^ (1 << order);
    if (buddy_idx >= buddy_npages)
        return NULL;
    return buddy_base + buddy_idx;
}

// 初始化
static void buddy_init(void){
    for (int i = 0; i <= MAX_ORDER; i++)
    {
        list_init(&buddy.free_list[i]);
        buddy.nr_free[i] = 0;
    }
    cprintf("buddy_pmm initialized.\n");
}

// 初始化空闲区
static void buddy_init_memmap(struct Page *base, size_t n){
    assert(n > 0);
    buddy_base = base;
    buddy_npages = n;

    for (size_t i = 0; i < n; i++){
        ClearPageReserved(base + i);
        ClearPageProperty(base + i);
        base[i].property = 0;
    }

    // 尽可能按最大块划分
    size_t idx = 0;
    while (n > 0){
        int order = MAX_ORDER;
        while ((1 << order) > n)
            order--;
        struct Page *p = base + idx;
        SetPageProperty(p);
        p->property = order;
        list_add(&buddy.free_list[order], &(p->page_link));
        buddy.nr_free[order]++;
        idx += (1 << order);
        n -= (1 << order);
    }
}

// 分配页
static struct Page *buddy_alloc_pages(size_t n){
    if (n == 0)
        return NULL;

    int order = 0;
    while ((1U << order) < n && order <= MAX_ORDER)
        order++;
    if (order > MAX_ORDER)
        return NULL;

    int cur = order;
    while (cur <= MAX_ORDER && list_empty(&buddy.free_list[cur]))
        cur++;

    if (cur > MAX_ORDER)
        return NULL; // 没有足够大的块

    
    struct Page *page;
    list_entry_t *le = list_next(&buddy.free_list[cur]);
    page = le2page(le, page_link);
    list_del(le);
    buddy.nr_free[cur]--;

    // 从更高阶分裂下来，如果不需要寻找更高阶则不进入循环
    while (cur > order){
        cur--;
        struct Page *buddy_page = page + (1 << cur); // 计算伙伴页地址
        SetPageProperty(buddy_page); 
        buddy_page->property = cur;
        list_add(&buddy.free_list[cur], &(buddy_page->page_link)); // 伙伴页并入低一阶链表
        buddy.nr_free[cur]++;
    }

    ClearPageProperty(page);
    page->property = order;
    return page; 
}

// 释放页
static void buddy_free_pages(struct Page *base, size_t n){
    assert(in_range(base));

    int order = 0;
    while ((1U << order) < n && order <= MAX_ORDER)
        order++;
    assert(order <= MAX_ORDER);

    struct Page *page = base;
    while (order < MAX_ORDER){
        struct Page *buddy_page = buddy_of(page, order);
        if (buddy_page == NULL || !PageProperty(buddy_page) || buddy_page->property != order)
            break;
        // 从链表中移除伙伴
        list_del(&(buddy_page->page_link));
        buddy.nr_free[order]--;
        // 合并
        if (buddy_page < page)
            page = buddy_page;
        order++;
    }

    SetPageProperty(page);
    page->property = order;
    list_add(&buddy.free_list[order], &(page->page_link));
    buddy.nr_free[order]++;
}


// 空闲页数量统计
static size_t buddy_nr_free_pages(void){
    size_t sum = 0;
    for (int i = 0; i <= MAX_ORDER; i++)
        sum += buddy.nr_free[i] * (1 << i);
    return sum;
}

// 自检函数
static void buddy_check(void){
    cprintf("========== buddy_check() START ==========\n");

    struct Page *p1, *p2, *p3, *p4, *p5;

    // 基本分配测试
    p1 = buddy_alloc_pages(1);
    p2 = buddy_alloc_pages(2);
    assert(p1 && p2);
    cprintf("[OK] Basic alloc (1, 2 pages)\n");

    // 非2的幂次分配（3页应该分配为4页块）
    p3 = buddy_alloc_pages(3);
    assert(p3);
    cprintf("[OK] Non-power-of-two alloc (3 pages => 4)\n");

    // 边界测试：申请超过总页数
    struct Page *fail = buddy_alloc_pages(buddy_npages + 1);
    assert(fail == NULL);
    cprintf("[OK] Oversized alloc rejected\n");

    // 释放部分块，测试是否可重用
    free_pages(p1, 1);
    free_pages(p2, 2);
    cprintf("[OK] Partial free\n");

    // 交错分配与释放
    p4 = buddy_alloc_pages(5); // 分配5页（应该拿8页块）
    assert(p4);
    p5 = buddy_alloc_pages(1);
    assert(p5);
    free_pages(p4, 5);
    free_pages(p3, 3);
    free_pages(p5, 1);
    cprintf("[OK] Interleaved alloc/free\n");

    // 检查完全恢复
    size_t max_npages = 1;
    while(max_npages << 1 <= buddy_npages)
        max_npages <<= 1;
    struct Page *big = buddy_alloc_pages(max_npages);
    assert(big);
    free_pages(big, max_npages);
    cprintf("[OK] Full merge check passed\n");

    cprintf("========== buddy_check() PASSED ==========\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

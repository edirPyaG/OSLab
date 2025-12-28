#include <pmm.h>
#include <slub.h>
#include <list.h>
#include <stdio.h>
#include <string.h>

//全局缓存链表,管理所有的kmem_cache
static list_entry_t cacheChain;

//用于kmalloc的预定义缓存大小
#define KMALLOC_MIN_SIZE 8
#define KMALLOC_MAX_SIZE 4096

static kmem_cache_t *kmallocCaches[10];//对应8,16,32...4096字节

// 辅助函数：从slab的freelist中分配一个对象
static void *slab_alloc_object(slab_t *slabp) {
    if (slabp->freelist == NULL) {
        return NULL;
    }
    void *obj = slabp->freelist;
    slabp->freelist = *((void **)obj); // freelist指向下一个空闲对象
    return obj;
}

// 创建一个新的slab（从底层页分配器获取页面）
static slab_t *kmemCacheGrow(kmem_cache_t *cachep) {
    // 1. 分配一个物理页
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }
    
    // 2. 将页转换为虚拟地址 (物理地址 + 偏移)
    uintptr_t pa = page2pa(page);
    void *page_va = (void *)(pa + va_pa_offset);
    
    // 3. slab描述符放在页的起始位置
    slab_t *slabp = (slab_t *)page_va;
    slabp->cachep = cachep;
    slabp->inuse = 0;
    list_init(&slabp->slabLink);
    
    // 4. 计算能容纳多少个对象（扣除slab_t自身占用的空间）
    size_t available = PGSIZE - sizeof(slab_t);
    slabp->total = available / cachep->objSize;
    
    // 5. 初始化freelist：将所有对象串成链表
    void *obj_start = (char *)page_va + sizeof(slab_t);
    slabp->freelist = obj_start;
    
    void *current = obj_start;
    for (int i = 0; i < slabp->total - 1; i++) {
        void *next = (char *)current + cachep->objSize;
        *((void **)current) = next;
        current = next;
    }
    *((void **)current) = NULL; // 最后一个对象的next为NULL
    
    // 6. 将新slab添加到slabPartial链表
    list_add(&cachep->slabPartial, &slabp->slabLink);
    
    return slabp;
}

//初始化slub系统
void slubInit() {
    list_init(&cacheChain);//初始化全局缓存表
    
    //创建用于kmalloc的预定义缓存
    kmallocCaches[0] = kmemCacheCreate(8);
    kmallocCaches[1] = kmemCacheCreate(16);
    kmallocCaches[2] = kmemCacheCreate(32);
    kmallocCaches[3] = kmemCacheCreate(64);
    kmallocCaches[4] = kmemCacheCreate(128);
    kmallocCaches[5] = kmemCacheCreate(256);
    kmallocCaches[6] = kmemCacheCreate(512);
    kmallocCaches[7] = kmemCacheCreate(1024);
    kmallocCaches[8] = kmemCacheCreate(2048);
    kmallocCaches[9] = kmemCacheCreate(4096);
    
    cprintf("slub_init: SLUB allocator initialized\n");
}

//创建一个缓存
kmem_cache_t *kmemCacheCreate(size_t size) {
    // 分配一个页作为缓存描述符（简化实现，实际应该用更小的内存）
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }
    
    uintptr_t pa = page2pa(page);
    kmem_cache_t *cachep = (kmem_cache_t *)(pa + va_pa_offset);
    
    //初始化缓存描述符
    list_init(&cachep->slabFull);
    list_init(&cachep->slabPartial);
    list_init(&cachep->slabFree);
    cachep->objSize = size;
    cachep->slabSize = PGSIZE;
    list_init(&cachep->cacheLink);
    
    //将新创建的缓存加入全局缓存链表
    list_add_after(&cacheChain, &cachep->cacheLink);
    
    return cachep;
}

//从缓存中分配一个对象
void *kmemCacheAlloc(kmem_cache_t *cachep) {
    slab_t *slabp = NULL;
    
    //优先从部分分配的slab链表中取出slab
    if (!list_empty(&cachep->slabPartial)) {
        list_entry_t *le = list_next(&cachep->slabPartial);
        slabp = le2slab(le, slabLink);
    }
    //如果partial为空,则从free中取出一个slab
    else if (!list_empty(&cachep->slabFree)) {
        list_entry_t *le = list_next(&cachep->slabFree);
        slabp = le2slab(le, slabLink);
        // 将slab从free移到partial
        list_del(&slabp->slabLink);
        list_add(&cachep->slabPartial, &slabp->slabLink);
    }
    //如果free也为空,则扩展缓存,创建新的slab
    else {
        slabp = kmemCacheGrow(cachep);
        if (slabp == NULL) {
            return NULL; // 内存耗尽
        }
    }
    
    // 从slabp中分配一个对象
    void *obj = slab_alloc_object(slabp);
    if (obj == NULL) {
        return NULL;
    }
    
    // 更新slab的inuse计数
    slabp->inuse++;
    
    // 如果slab已经满了,移到slabFull链表
    if (slabp->inuse == slabp->total) {
        list_del(&slabp->slabLink);
        list_add(&cachep->slabFull, &slabp->slabLink);
    }
    
    return obj;
}

//释放一个对象
void kmemCacheFree(kmem_cache_t *cachep, void *objp) {
    // 计算objp所属的slab的起始地址（页对齐）
    slab_t *slabp = (slab_t *)((uintptr_t)objp & ~(PGSIZE - 1));
    
    // 将对象插回到slab的freelist头部
    *((void **)objp) = slabp->freelist;
    slabp->freelist = objp;
    
    // 更新slab的inuse计数
    slabp->inuse--;
    
    // 如果slab从full变为partial,移动到slabPartial链表
    if (slabp->inuse == slabp->total - 1) {
        list_del(&slabp->slabLink);
        list_add(&cachep->slabPartial, &slabp->slabLink);    
    }
    // 如果slab从partial变为free,移动到slabFree链表
    else if (slabp->inuse == 0) {
        list_del(&slabp->slabLink);
        list_add(&cachep->slabFree, &slabp->slabLink);
    }
}

// 通用分配接口
void *kmalloc(size_t size) {
    // 选择合适的kmalloc缓存
    int index = -1;
    if (size <= 8) index = 0;
    else if (size <= 16) index = 1;
    else if (size <= 32) index = 2;
    else if (size <= 64) index = 3;
    else if (size <= 128) index = 4;
    else if (size <= 256) index = 5;
    else if (size <= 512) index = 6;
    else if (size <= 1024) index = 7;
    else if (size <= 2048) index = 8;
    else if (size <= 4096) index = 9;
    else return NULL; // 超过最大支持大小
    
    return kmemCacheAlloc(kmallocCaches[index]);
}

// 通用释放接口
void kfree(void *objp) {
    if (objp == NULL) {
        return;
    }
    
    // 计算objp所属的slab的起始地址
    slab_t *slabp = (slab_t *)((uintptr_t)objp & ~(PGSIZE - 1));
    kmem_cache_t *cachep = slabp->cachep;
    kmemCacheFree(cachep, objp);
}

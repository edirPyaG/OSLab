#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__
//防止头文件重复包含宏定义

#include<list.h>//双向链表的库
#include<assert.h>//标准库中包含,断言库

//SLUB缓存描述符
//管理一类特定大小的对对象
typedef struct kmemCache{
    list_entry_t slabFull ;//完全分配的slab链表
    list_entry_t slabPartial;//部分分配的slab链表
    list_entry_t slabFree ;//空闲的slab链表
    
    size_t objSize;//每个对象的大小
    size_t slabSize;//每个slab的大小        
    /* 在同一个 kmem_cache 中，所有对象（object）的大小是完全一样的。
     一个页（page）在这个 cache 中被切割时，的确会被切割成多个大小
     相同的对象。
    */
    list_entry_t cacheLink;//用于链接所有的kemeCache节点
} kmem_cache_t;

//slab描述符
//通常放在一个物理页的起始地址
typedef struct slabTag{
    kmem_cache_t * cachep; //指向所属的kmem_cache
    void * freelist ;//slab内的空闲对象表头
    int inuse;//已经分配的对象的数量
    int total;//slab中总对象数量
    list_entry_t slabLink;// 用于链接到kemme-_cache的slab链表中
}slab_t;

void slubInit();//slub初始化函数
kmem_cache_t * kmemCacheCreate(size_t objSize);//创建kmem_cache
void kmemCacheDestroy(kmem_cache_t * cachep);//销毁kmem_cache
void * kmemCacheAlloc(kmem_cache_t * cachep);//从kmem_cache中分配对象
void kmemCacheFree(kmem_cache_t * cachep, void * objp);//释放对象到kmem_cache中

//通用分配接口
void *kmalloc(size_t size);//分配内存
void kfree(void * objp);//释放内存

// convert list entry to slab
#define le2slab(le, member)                 \
    to_struct((le), slab_t, member)

#endif // !__KERN_MM_SLUB_H__

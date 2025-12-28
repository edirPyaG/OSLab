#ifndef __KERN_MM_BUDDY_PMM_H__
#define __KERN_MM_BUDDY_PMM_H__

#include <pmm.h>
#include <list.h>
#include <memlayout.h>

#define MAX_ORDER 15

typedef struct
{
    list_entry_t free_list[MAX_ORDER + 1]; // 各阶空闲块链表
    unsigned int nr_free[MAX_ORDER + 1];   // 各阶空闲块数量
} buddy_system_t;

extern const struct pmm_manager buddy_pmm_manager;

#endif /* !__KERN_MM_BUDDY_PMM_H__ */

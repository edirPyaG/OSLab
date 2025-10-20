练习1：理解first-fit连续物理内存分配算法
原理阐述：
first-fit算法：连续物理内存分配算法的一种，将空闲内存块按照地址从小到大的方式连起来，具体实现时使用了双向链表的方式。当分配内存时，从链表头开始向后找，这意味着从低地址向高地址查找，一旦找到可以满足要求的内存块，即将该内存块分配出去即可。
代码分析：
整体思路：
首先，我们先从宏观的角度来对问题进行分析，再从整段代码的分配的算法和逻辑进行说明。
该内存管理器使用一个双向循环链表来维护所有空闲的、连续的页块，并按这些空闲页块在物理内存中的起始地址升序进行排列。每个空闲页块的起始页的字段存储了该块的大小。
1.内存初始化
在系统启动时，将一块或多块连续的、可用的物理页块添加到空闲链表。
2.内存分配
遍历空闲链表，找到第一个大小满足请求的空闲页块。
如果找到大小符合要求的空闲页块，就将该页块进行分割，通过分配请求所需的大小n页，如果还有剩余的页，则将剩余的部分作为一个新的、更小的空闲页块保留在链表中。
3.内存释放
将归还的页块标记为空闲，并将其插入到空闲链表中的正确位置，其插入的思想仍然为升序的顺序进行插入。
在插入之后，会检查并合并该页块与它的物理地址上相邻的前一个和/或后一个空闲页块，以减少外部碎片。
具体代码实现
default_init
static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}
首先，通过定义一个静态函数default_init来初始化空闲内存块的链表和计数器。其中的list_init(&free_list);是一个链表初始化函数，其定义在链表操作库中。nr_free=0;其中变量nr_free用来记录当前空闲内存块的数量，在初始化时将其设为0，表示此时系统还没有可分配的空闲内存块。
default_init_memmap
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
这一段代码的目的是把从base开始的连续n个struct Page初始化为一个可分配的“空闲块”，并把该块挂入全局的空闲链表free_list中。同时更新空闲页计数nr_free。这是简单物理内存分配器中将一段页变成“可用”的典型初始化函数。
- assert(n>0);
确保传入的页数n至少为1，作为参数前置条件检查。
- struct Page *p = base;
指针p用于遍历以base为起点的Page数组。
for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
遍历base到base+n-1的每个结构体，来判断每个待初始化的Page是否是被标记为“保留”的页面，如果不是保留页面，程序会触发断言错误并终止，如果是保留页面，然后会清除页面标志和属性，设置页面引用计数为0，将其转换为可用的空闲页面。通过上述操作来确保只对原本就是保留页面的内存区域进行初始化，以及确保内存管理系统的安全性和一致性。
base->property = n;在本段连续内存的首页上设置property=n，表示从base开始的连续自由页块长度是n。且只有块首才需要存放property，用于合并、分配时快速知道块大小。SetPageProperty(base);设置首页的“property”标志，表明这个页是一个空闲块的头，这样其他代码可以通过检查PageProperty(p)来判断某页是不是一个块头。nr_free+=n;全局可用页计数nr_free增加n。
if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } 
如果当前空闲链表是空的，就直接把base的page_link加入链表。否则进入else分支，把新块插入到free_list中合适的位置，也就是下面这一段代码的逻辑。
else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
这一段代码是在有序列表中插入新节点的经典算法，其整体的逻辑为将一个新空闲内存块按照地址从低到高的顺序，插入到已排序的空闲链表中。首先从头节点的下一个节点开始遍历，直到再次遇到头节点为止，也就是遍历整个链表。接下来在循环体中，通过获取页面结构体，当新块的地址小于当前遍历块的地址时，将新块放到当前块的前面，插入完成之后，退出循环；如果新块的地址比所有现有块都大，则将新块插入到当前节点之后，即链表末尾。
default_alloc_pages
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
这一段代码主要是用来分配空闲内存块。通过遍历空闲链表，找到第一个大小足够容纳请求的连续空闲内存块，然后进行分配，如有剩余则分割并放回空闲链表。
assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
首先是可行性分析，检查请求的页面数n是否合法，也就是大于0，同时，检查系统中是否有足够的空闲页面，如果不够，则直接返回NULL表示分配失败。
struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
在这一步，通过初始化page为NULL，表示尚未找到合适块，然后遍历空闲链表free_list，对每个空闲块，检查其property，也就是连续空闲页面数，是否大于等于请求的n，根据first fit的逻辑可知，我们找到第一个满足条件的块就立即停止，如果遍历完都没找到，page保持NULL。
if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
如果page不是NULL，也就是找到了合适的块，首先记录前驱节点，然后将其从链表中移除，之后这整个块就不再属于空闲链表，之后就进入了这一段代码的关键步骤，对块进行分割，如果找到的块比请求的n大，也就是说有剩余，则需要计算剩余部分的起始页面，在原有的page的基础上再加上n，来重新调整剩余部分的起始页面，同时，设置剩余块的大小，标记剩余块为空闲状态，同时再将剩余块插回原位置，来保持链表有序。更新系统的状态，更新全局空闲页面计数，清除分配块的“空闲属性”标记，返回分配块的起始页面指针。
default_free_pages
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
这段代码整体是用来进行内存的释放与空闲块的合并。通过释放已分配的物理页面，并将它们与相邻的空闲块合并，以减少内存碎片。
for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
首先，进行页面的初始化，先确保要释放的页面既不是保留页面也不是空闲页面，也就是说确认其为已分配页面，然后清除页面标志，引用计数归零。从而将这些页面恢复到“干净状态”，准备作为空闲页面重用。
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
将释放的n个页面标记为一个连续空闲块。base作为该块的头页面，记录块大小，然后标记标记base为空闲状态，最后再更新全局空闲页面计数器。
if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
然后是插入有序空闲链表，如果空闲链表为空，则直接插入，否则的话按照地址从低到高的顺序找到正确位置插入，以此来保持链表有序，便于后续的操作。
list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
这一部分是函数的核心部分：空闲块的合并。分为前向合并和后向合并。前向合并的逻辑为先获取前一个块，检查是否是地址连续，如果地址连续，也就是满足条件：p+p->property==base，则合并大小，清除当前块的标记，从链表移除当前块，base指向前一个块，也就是合并之后的块。
然后进行后向合并的逻辑判断，先获取后一个块，检查地址是否连续，如果地址连续，则合并大小，然后清除后块的标记，从链表中移除后块。
default_free_pages
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
这一段函数用于释放内存块。将释放的内存块按照顺序插入空闲内存块的链表中，并合并与之相邻且连续的空闲内存块。
首先，如果该页面的保留属性和页面数量属性均不为初始值了，我们就重置页面的对应属性，将引用设置定义为0。然后对应的更新空闲块数的数量。将页面添加到空闲块列表中，同时尝试合并相邻的空闲块。如果释放的页面与前一个页面或后一个页面相邻，会尝试将它们合并为一个更大的空闲块。
default_nr_free_pages
static size_t
default_nr_free_pages(void) {
    return nr_free;
}
这个一段代码是用来获取系统当前空闲数量的函数。类型为size_t，表示空闲页面的数量。其直接返回全局变量nr_free的值。
basic_check
static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}
总的来说，这一段代码是一个内存管理基础功能的单元测试函数，用于验证页面分配和释放的核心逻辑是否正确工作。这段代码分别验证单个页面的分配、释放、状态管理是否正常工作。是对上述的函数的功能的验证。
default_check
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
这一段函数实现了比上述的basic_check()函数更加全面的内存管理算法验证测试，比之前的basci_check()更加复杂和完整。测试了部分页面的释放和精确分配，碎片化内存管理，以及完全分配与合并。
结构体pmm_manager default_pmm_manager
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};
这一部分是完整的内存管理模块接口的实现，采用了面向对象的设计模式。以下是对这个结构体的各个成员的解释：
- .name = "default_pmm_manager"：用于标识这个内存管理器的名称。
- .init = default_init：函数指针，用于初始化内存管理器的某些状态。
- .init_memmap = default_init_memmap：函数指针，用于设置内存页面的初始状态。
- .alloc_pages = default_alloc_pages：函数指针，指向一个用于分配页面的函数。
- .free_pages = default_free_pages：函数指针，指向一个用于释放页面的函数。
- .nr_free_pages = default_nr_free_pages：函数指针，指向一个用于获取空闲页面数量的函数。
- .check = default_check：函数指针，用于分配情况的检查。
改进空间:
通过理论课的学习以及查阅资料，我认为可以进行对以下的方面进行相应的改进：由于每次查找链表都需要进行遍历，时间复杂度较高，且会在空闲链表开头产生许多小的空闲块，仍然有优化的空间。

练习2：实现 Best-Fit 连续物理内存分配算法
Best-Fit连续物理内存分配算法的前面部分与First-Fit的是一样的。因此我们就不过多赘述了。只有以下这一部分的代码与First-Fit的代码的逻辑不同。
while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n&&p->property<min_size) {
            min_size=p->property;
            page = p;
        }
    }
用min_size来记录大于n但是最接近n的空闲块的大小，同时用page来记录min_size对应的空闲块，最终得到的结果非空的空闲块就是最接近n大小的空闲块。运行代码的结果如下图所示：
[图片]
改进空间：
- 时间复杂度优化：现在每次分配都要从头到尾扫描一遍free_list，时间复杂度为O(n)。如果空闲块数量多，这会拖慢分配速度。可以引入更加高效的数据结构，比如平衡二叉树，分级空闲链表。
扩展练习Challenge：buddy system（伙伴系统）分配算法
设计文档
1. 基本思想
我们用页号（Page index）来表示页的位置：
+----+----+----+----+----+----+----+----+----+----+----+----+
| P0 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10| P11| ...
+----+----+----+----+----+----+----+----+----+----+----+----+
按阶（order） 管理空闲块：阶k表示大小为2^k页的块。
MAX_ORDER为最大的阶。
以order = 2（每块4页）为例，举一个简单的例子：
页号
页号的二进制表示
所属块
块号
伙伴块号
0
0000
[0,1,2,3]
0
1
4
0100
[4,5,6,7]
1
0
8
1000
[8,9,10,11]
2
3
12
1100
[12,13,14,15]
3
2
分配时，找到最小order使得2^order >= n，分配该阶（可能通过从更高阶拆分得到）。
释放时，先把n转成对应order，释放并尝试与伙伴合并到更高阶。
2. 关键数据结构
- buddy_system_t buddy：核心结构体
  - list_entry_t free_list[MAX_ORDER + 1]：每个阶一个链表头，存放各阶空闲块头（块头由 struct Page承担）。
  - unsigned int nr_free[MAX_ORDER + 1]：每阶的空闲块数量，用于统计和检查是否有空闲块。
order是从0开始取值，故数组大小应该为MAX_ORDER + 1。
- static struct Page *buddy_base和static size_t buddy_npages
  - buddy_base指向pmm->init_memmap传入的base（即&pages[first_free_index]），所有对页的索引与伙伴计算都以它为基准。
3. 辅助函数
- page_index：计算相对页索引，便于伙伴计算。
- in_range：边界检查，防止越界。
- buddy_of：计算伙伴页面，确保在范围内否则返回 NULL。
  核心逻辑：buddy_idx = idx ^ (1 << order)
  - 1 << order对应的二进制位是当前块的“层级位”；
  - XOR（异或）操作相当于“翻转”这个层级位；
  - 翻转该位，意味着从当前块跳到它的“另一半”——伙伴块。
例如，在上面的表格中，order = 2。对于idx = 12的块，计算它的伙伴块buddy_idx = idx ^ (1 << order) = 12 ^ (1 << 2) = 12 ^ 4 = 8。
- buddy_nr_free_pages：空闲页数量统计。将每一个order的空闲页累加即可。
4. 全局初始化：buddy_init(void)
目标：清空所有链表和计数器，便于内核启动时调用。
5. 初始化空闲区：buddy_init_memmap(base, n)
目标：把从base开始的n个物理页划分成尽可能大的$$2^k$$连续页块，并把这些块加入各阶（order）空闲链表free lists中，同时保证每个放入的块头满足对齐要求（每个块的起始地址必须是块大小的倍数，即按2^order对齐）。
对齐才能通过异或运算(idx ^ (1 << order))快速计算伙伴块。
实现要点：
- 记录buddy_base = base; buddy_npages = n;。
- 对所有新加入的页先清除Reserved/Property标志（ClearPageReserved/ClearPageProperty），并让property=0。
- 使用贪心分割：从当前位置idx开始，找出最大的order使得(1<<order) <= remain（剩余页数），并把该块放入该阶链表。这里假定base本身就按页对齐并且我们从连续区段0开始编号，从而idx自然满足idx % (1<<order) == 0（即刚好对齐）。
6. 分配流程：buddy_alloc_pages(size_t n)
目标：分配至少n个连续的空闲页，返回块头struct Page*（实质上会分配连续1<<order页）。
步骤与设计理由：
1. 计算order = ceil_log2(n)（最小的order使1<<order >= n）。
2. 从 order 开始向上查找第一个非空free_list（cur）。如果到MAX_ORDER都没有，分配失败返回NULL。
3. 从free_list[cur]取一个块头，把它从链表中移除 (list_del) 并更新buddy.nr_free[cur]（维护计数）。
4. 如果cur == order，则无需拆分，直接分配。
  如果cur > order，则不断拆分：
    把当前阶为cur块拆成两个阶为cur-1的块：左侧保持作为待继续拆分/返回的块，右侧块头为page + (1 << (cur-1))（即伙伴页地址），将右侧加入free_list[cur-1]并buddy.nr_free[cur-1]++。
    重复直到cur == order。
5. 在最终返回前做状态标记：清PageProperty、把page->property = order。
7. 释放流程与合并：buddy_free_pages(base, n)
目标：把base指向的一段连续页（n页）释放回伙伴系统，并尽可能向上合并成更大阶的块。
步骤与设计理由：
1. 通过第1个while循环计算order = ceil_log2(n)（和分配一样，得到最小的order使1<<order >= n）。
2. 从当前块头page=base开始，进入第2个while循环：
- 以下3个条件任意一个条件成立，就停止合并，退出循环：
  - buddy_page == NULL表示计算出来的“伙伴页”不在有效的内存管理范围之内。
  - !PageProperty(buddy_page)表示伙伴页不在空闲状态，即被分配（正在使用）。
  - buddy_page->property != order表示伙伴块的阶次与当前块的阶次不同。
- 否则就要进行合并：把伙伴从free_list[order]删除 (list_del)，buddy.nr_free[order]--；然后把page指向合并后的新块头（min(page, buddy_page)）；order++阶加1；继续向上尝试合并。
3. 把合并后的块加入free_list[order]（此时order已经完成了加1），SetPageProperty(page)，page->property = order，并更新buddy.nr_free[order]++。
代码实现
#ifndef __KERN_MM_BUDDY_PMM_H__
#define __KERN_MM_BUDDY_PMM_H__

#include <pmm.h>
#include <list.h>
#include <memlayout.h>

#define MAX_ORDER 10 // 最大阶数 (1 << 10) 页 = 4MB

typedef struct
{
    list_entry_t free_list[MAX_ORDER + 1]; // 各阶空闲块链表
    unsigned int nr_free[MAX_ORDER + 1];   // 各阶空闲块数量
} buddy_system_t;

extern const struct pmm_manager buddy_pmm_manager;

#endif /* !__KERN_MM_BUDDY_PMM_H__ */
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

    cprintf("========== buddy_check_full() PASSED ==========\n");
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
自检测试
自检函数buddy_check()将测试以下几种情况：
测试类型
说明
基本分配
申请 1、2、4页等标准块
非2的幂次分配
比如申请3页、5页，测试伙伴系统自动“向上取整”行为
多次分配 + 释放
检查是否出现空洞、链表破坏
交错分配与释放
检查合并逻辑是否稳定
边界测试
尝试分配超出总页数的请求
完整回收验证
最后尝试分配整个内存，验证系统完全恢复
自检函数buddy_check()的完整代码详见“代码实现”部分。执行make qemu，输出如下内容，说明通过了自检，编写的伙伴系统运行正确。
[图片]
扩展练习Challenge：任意大小的内存单元slub分配算法
设计文档
1. 基本思想
SLUB 是一种高效的小对象内存分配机制。它将内存页（Page）划分为若干个对象池（Slab），每个 Slab 存放相同大小的对象。系统为不同对象大小维护独立的 Cache，每个 Cache 包含若干个 Slab，并按使用状态分为 Full、Partial、Free 三类链表。
分配时，从 Partial 或 Free 的 Slab 中取出一个对象；释放时，将对象插回 Slab 的空闲链表（freelist），并根据使用计数调整 Slab 的归属。当一个 Slab 中的所有对象都释放后，对应页即可归还系统。
这种方式通过对象大小分级、页内对象池管理与空闲链表快速分配，显著降低碎片，提高了小对象分配的效率与缓存命中率。
2. 关键数据结构(slub.h)
- kmem_cache_t：描述某一固定对象尺寸的缓存，维护三个 slab 链表（full/partial/free）、对象大小 obj_size、每 slab 对象数量 total（由 slab 计算）、以及全局缓存链表节点 cache_link。
- slab_t：位于页起始处的 slab 元数据，包含指向所属 cache 的指针、空闲对象链表头 freelist、在用计数 inuse、总对象数 total、以及链接到 cache 的 slab_link。
- le2slab 宏：从双向链表节点还原到 slab 指针，便于链表与结构体互转。
核心结构在 kern/mm/slub.h 中定义。关键片段如下：

// kern/mm/slub.h
typedef struct kmemCache{
    list_entry_t slabFull;    // 满载slab
    list_entry_t slabPartial; // 部分占用slab
    list_entry_t slabFree;    // 空闲slab
    size_t objSize;           // 对象大小
    size_t slabSize;          // slab大小，简化为一页
    list_entry_t cacheLink;   // 加入全局cache链
} kmem_cache_t;

typedef struct slabTag{
    kmem_cache_t * cachep;    // 反向指向所属cache
    void * freelist;          // 页内空闲对象单链表
    int inuse;                // 已分配对象数
    int total;                // 总对象数
    list_entry_t slabLink;    // 链接到cache的slab链
} slab_t;

#define le2slab(le, member) to_struct((le), slab_t, member)
3. 辅助函数
对象从 slab freelist 分配的核心在 slab_alloc_object，代码如下（kern/mm/slub.c）：

static void *slab_alloc_object(slab_t *slabp) {
    if (slabp->freelist == NULL) return NULL;
    void *obj = slabp->freelist;
    slabp->freelist = *((void **)obj); // 下一空闲
    return obj;
}
说明：
- 错误模式：freelist==NULL 时返回 NULL，由上层决定是否 grow。
- 不进行对象构造（ctor）与清零（为性能考虑）；调用方如需置零可自行 memset。
- 单链表头插，常数时间；避免跨 cache/sizes 的对象混用。
4. 全局初始化
在 pmm_init() 之后调用，创建 kmalloc 用的预定义 cache（8~4096B）：
void slubInit() {
    list_init(&cacheChain);
    kmallocCaches[0] = kmemCacheCreate(8);
    kmallocCaches[1] = kmemCacheCreate(16);
    // ... 32,64,...,4096
    kmallocCaches[9] = kmemCacheCreate(4096);
    cprintf("slub_init: SLUB allocator initialized\n");
}
在 kern/init/init.c 中集成：

// kern/init/init.c
#include <slub.h>
...
pmm_init();
slubInit();
5. 初始化空闲区
当缓存没有可用 slab 时，从 PMM 申请一页并格式化。下列片段展示了页到内核 VA 的转换、页内对象数量的计算，以及将对象串成 freelist 的要点：

uintptr_t pa = page2pa(page);
void *page_va = (void *)(pa + va_pa_offset);
size_t available = PGSIZE - sizeof(slab_t);
slabp->total = available / cachep->objSize;
void *obj = (char *)page_va + sizeof(slab_t);
// 将页内对象串成 freelist（步长为 objSize）
6. 分配流程
分配的决策顺序是“优先 partial → 其次 free → 否则 grow”。成功取到对象后更新 inuse，若恰好满载则迁移到 full。核心逻辑可以压缩为：

if (!list_empty(&cachep->slabPartial)) pick_partial();
else if (!list_empty(&cachep->slabFree)) move_free_to_partial();
else slabp = kmemCacheGrow(cachep);
obj = pop_from_freelist(slabp);
if (++slabp->inuse == slabp->total) move_to_full(slabp);
7. 释放流程：
释放通过页对齐回溯到所属 slab，将对象头插回 freelist，更新计数后根据阈值在 full/partial/free 之间迁移：
slab_t *slabp = (slab_t *)((uintptr_t)objp & ~(PGSIZE - 1));
*((void **)objp) = slabp->freelist; slabp->freelist = objp;
if (--slabp->inuse == slabp->total - 1) move_full_to_partial(slabp);
else if (slabp->inuse == 0) move_partial_to_free(slabp);

说明：
- 通过页对齐反推 slab 常数时间完成，避免额外 map；要求 slab 元数据在页首。
- 双条件迁移保障分类不变量：full→partial（释放1个）、partial→free（变为0）。
- 潜在风险：并发环境下需加锁/关中断；对象二次释放需上层保证或加调试魔数。
运行结果
采用指令 timeout 10 make qemu 编译运行内核，验证 SLUB 初始化与运行正确性：
[图片]
[图片]

- slubInit：初始化全局缓存链表，并建立用于 kmalloc 的一组常用尺寸缓存（8/16/32/…/4096 字节）。该函数在 kern/init/init.c 的 pmm_init 之后被调用，确保底层页分配器已就绪。
- kmemCacheCreate(size)：创建指定对象尺寸的缓存，初始化其三个 slab 链表，并挂到全局缓存链表。
- kmemCacheAlloc(cachep)：从给定缓存分配一个对象，内部自动选择或创建合适的 slab，并更新 inuse 与链表归属（partial→full）。
- kmemCacheFree(cachep, objp)：释放对象回其所属 slab，更新 inuse，并在 full/partial/free 之间迁移。
- kmalloc/kfree：面向通用调用者的接口。kmalloc 根据 size 选择最小可容纳的预定义 cache，再调用 kmemCacheAlloc；kfree 通过对象地址定位所属 slab 与 cache，然后调用 kmemCacheFree。
目前实现的缺陷
- 简化版实现，slab 元数据直接占用页首，尚未实现更灵活的元数据布局或对象对齐优化。
- 未实现 kmemCacheDestroy 以及 slab 回收至 PMM 的策略（可在 free 列表过多时回收）。
- 未引入多核/中断上下文并发保护（生产实现需加锁或禁用中断临界区）。



扩展练习Challenge：硬件的可用物理内存范围的获取方法
通过查阅资料，可以使用15h中断，具体的步骤如下：
1. 将寄存器ax赋值为0E820h
2. 将寄存器ebx初始化为0，该寄存器的内容会被BIOS修改，同时，我们需要保证在内存查询过程中，该寄存器不会被修改。
3. es:di指向一块足够大的内存地址，BIOS会把有关内存的信息写到这个地址，内存信息是一种数据结构，称之为地址范围描述符。
4. ecx寄存器存储es:di所指向的内存大小，以字节为单位，BIOS最多会填充ecx个字节的数据，通常情况下，无论ecx的数值是多少，BIOS都只填充20字节，有些BIOS直接忽略ecx的值，总是填充20字节。
5. edx寄存器的值设置为0534D4150h，这个数值其实对应的是字符组合“SMAP”，其作用我们可以暂时忽略。
完成上述配置之后，执行int 15h中断，中断结果的分析过程如下：
1. 判断CF位，如果CF位设置为1，则表示出错
2. eax会被设置为0534D4150h，也就是字符串SMAP
3. es:di返回地址范围描述符结构指针，跟输入时相同
4. 如果ebx的值为0，表明查询结束，如果不为0，则继续调用15h获取有关内存的信息。
实验中的重要知识点与 OS 原理中对应的知识点
 1.使用 双向循环链表 管理空闲内存块：
涉及到连续内存分配机制、空闲块管理结构。
1. 实验中通过链表结构来维护物理内存空闲块，是具体实现。
2. OS 原理中讲的是分区分配算法理论，强调“如何管理空闲内存”的思想，如空闲分区表、空闲分区链。
3. 二者的关系是：实验实现了理论中的“空闲分区链”形式；差异在于实验使用的是页为单位，实际 OS 可能还涉及段页式、Buddy 等更复杂机制。
2.First-Fit 算法的实现与代码
也就是First-Fit 连续内存分配算法原理。
1. 原理上：从低地址开始查找第一个足够大的空闲块，然后分配。
2. 实验上：通过遍历空闲链表，从头开始顺序查找，找到第一个满足要求的块并分割。
3. 二者关系：实验是对原理的直接编码实现；差异在于实验用页粒度实现连续页分配，而原理通常是以字节/分区大小描述。
3.Best-Fit 算法的实现
Best-Fit 连续内存分配算法原理。
1. 原理上：从所有空闲块中找出最“合适”的（剩余空间最少但仍够用）的空闲块，减少内部碎片。
2. 实验上：遍历链表，记录符合条件的最小块，再进行分割。
3. 二者关系：实验是原理的直接实现；差异在于实验是以页块为单位实现，OS 课本讲的是抽象分区大小。
4.内存释放与块合并机制
外部碎片管理与空闲块合并
1. 原理上：释放后需合并相邻空闲块，以减少外部碎片，维持空闲块的连续性。
2. 实验中：释放时将块按地址插入到链表正确位置，并检查前后相邻块进行合并。
3. 二者关系：实验很好地还原了理论中的“合并空闲分区”的思想；差异在于实验以页为单位，而理论强调连续分区管理。
5.初始化空闲内存链表
系统启动时内存布局与空闲内存初始化。
1. 原理上：系统启动时，内核需建立内存管理的数据结构，记录可用物理内存区域。
2. 实验中：通过手动设置可用页块，并把它们插入空闲链表。
OS 原理中重要但实验中未对应的知识点
1.内存保护与访问控制
OS 通过页表和权限位来实现内存保护，在本次实验中只是简单地管理空闲块，没有进程/用户态的概念，也没有权限控制。
2.交换与页置换算法
当内存不足时，通过磁盘交换、LRU、FIFO等算法回收物理页，本次实验中假设物理内存是固定的，也没有涉及磁盘交换机制。
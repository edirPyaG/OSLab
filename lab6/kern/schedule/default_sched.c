#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * RR_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 *
 *   - run_list: should be an empty list after initialization.
 *   - proc_num: set to 0
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_init(struct run_queue *rq)
{
    // LAB6: 2312130
    list_init(&(rq->run_list)); // 初始化就绪队列链表头(空队列)
    rq->proc_num = 0;           // 当前就绪进程数为0
}

/*
 * RR_enqueue inserts the process ``proc'' into the tail of run-queue
 * ``rq''. The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``run_link'' node into the queue.
 * The procedure should also update the meta data in ``rq'' structure.
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312130
    assert(rq != NULL && proc != NULL);    // 基本健壮性检查
    assert(list_empty(&(proc->run_link))); // 关键：防止重复入队破坏链表

    proc->rq = rq; // 记录该进程所在的 run_queue
    if (proc->time_slice <= 0)
    {                                          // 时间片用尽/新建进程，需重新分配
        proc->time_slice = rq->max_time_slice; // 统一设置为最大时间片
    }

    // RR: 入队到队尾(链表头 run_list 的前一个位置即队尾)
    list_add_before(&(rq->run_list), &(proc->run_link)); // 将进程挂到队尾
    rq->proc_num++;                                      // 更新就绪队列进程数
}

/*
 * RR_dequeue removes the process ``proc'' from the front of run-queue
 * ``rq'', the operation would be finished by the list_del_init operation.
 * Remember to update the ``rq'' structure.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312130
    assert(rq != NULL && proc != NULL); // 基本健壮性检查
    assert(proc->rq == rq);
    list_del_init(&(proc->run_link)); // 从就绪队列中摘除并重新初始化结点
    rq->proc_num--;                   // 更新就绪队列进程数
}

/*
 * RR_pick_next picks the element from the front of ``run-queue'',
 * and returns the corresponding process pointer. The process pointer
 * would be calculated by macro le2proc, see kern/process/proc.h
 * for definition. Return NULL if there is no process in the queue.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: 2312130
    assert(rq != NULL); // run_queue 必须存在

    if (list_empty(&(rq->run_list)))
    { // 队列为空，无可运行进程
        return NULL;
    }
    list_entry_t *le = list_next(&(rq->run_list)); // 取队头元素(链表头的下一个)
    return le2proc(le, run_link);                  // 由链表结点反推出 proc_struct
}

/*
 * RR_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2312130
    assert(rq != NULL && proc != NULL); // 基本健壮性检查
    assert(proc->rq == rq);
    if (proc->time_slice > 0)
    {                       // 仍有剩余时间片
        proc->time_slice--; // 每次时钟中断消耗一个时间片
    }
    if (proc->time_slice <= 0)
    { // 时间片耗尽，需要触发调度
        proc->need_resched = 1;
    } // 设置重调度标志，trap 返回前将调用 schedule()
}

struct sched_class default_sched_class = {
    .name = "RR_scheduler",
    .init = RR_init,
    .enqueue = RR_enqueue,
    .dequeue = RR_dequeue,
    .pick_next = RR_pick_next,
    .proc_tick = RR_proc_tick,
};

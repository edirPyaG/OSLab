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
    // LAB6: YOUR CODE
    list_init(&(rq->run_list));  // 初始化运行队列的链表
    rq->proc_num = 0;             // 初始进程数为0
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
    // LAB6: YOUR CODE
    assert(list_empty(&(proc->run_link)));           // 确保进程不在其他队列中
    list_add_before(&(rq->run_list), &(proc->run_link));  // 加入队列尾部
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;       // 设置时间片
    }
    proc->rq = rq;                                   // 设置进程所属队列
    rq->proc_num++;                                  // 队列进程数加1
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
    // LAB6: YOUR CODE
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);  // 确保进程在队列中
    list_del_init(&(proc->run_link));  // 从队列中移除
    rq->proc_num--;                     // 队列进程数减1
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
    list_entry_t *le = list_next(&(rq->run_list));  // 获取队列头部的下一个节点
    if (le != &(rq->run_list)) {                     // 队列非空
        return le2proc(le, run_link);                 // 返回对应的进程
    }
    return NULL;  // 队列为空返回NULL
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
}

/*
 * RR_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
    if (proc->time_slice > 0) {      // 如果时间片还有剩余
        proc->time_slice--;           // 时间片减1
    }
    if (proc->time_slice == 0) {      // 时间片用完
        proc->need_resched = 1;       // 设置需要重新调度标志
    }
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
}

struct sched_class default_sched_class = {
    .name = "RR_scheduler",
    .init = RR_init,
    .enqueue = RR_enqueue,
    .dequeue = RR_dequeue,
    .pick_next = RR_pick_next,
    .proc_tick = RR_proc_tick,
};

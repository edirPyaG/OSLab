#ifndef __KERN_DRIVER_CLOCK_H__
#define __KERN_DRIVER_CLOCK_H__

#include <defs.h>

extern volatile size_t ticks;

void clock_init(void);
void clock_set_next_event(void);
/*，头文件中声明的函数（clock_init、clock_set_next_event）默认具有全局属性（外部链接，external linkage），可以被其他文件通过 extern 引用（甚至无需显式写 extern，因为函数声明默认隐含 extern）。*/
#endif /* !__KERN_DRIVER_CLOCK_H__ */


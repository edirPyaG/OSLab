#include <ulib.h>
#include <stdio.h>

static char buf[4096];

int main(void) {
    buf[0] = 10;
    int pid = fork();
    if (pid == 0) {
        for (volatile int i=0;i<100000;i++); // let parent run first
        cprintf("child reads: buf[0]=%d\n", buf[0]);
        exit(0);
    } else {
        buf[0] = 20;
        cprintf("parent wrote buf[0]=%d\n", buf[0]);
        wait();
    }
    return 0;
}

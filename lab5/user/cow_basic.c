#include <ulib.h>
#include <stdio.h>

static char buf[4096]; // one page

int main(void) {
    buf[0] = 1;
    int pid = fork();
    if (pid == 0) {
        buf[0] = 2;
        cprintf("child: buf[0]=%d\n", buf[0]);
        exit(0);
    } else {
        wait();
        cprintf("parent: buf[0]=%d\n", buf[0]);
    }
    return 0;
}

#include <ulib.h>
#include <stdio.h>

#define NCH 4
static char bigbuf[4096 * NCH];

int main(void) {
    for (int i=0;i<NCH;i++) bigbuf[i*4096] = i;
    for (int i=0;i<NCH;i++) {
        int pid = fork();
        if (pid == 0) {
            bigbuf[i*4096] = i + 100;
            cprintf("child %d: buf[%d]=%d\n", i, i, bigbuf[i*4096]);
            exit(0);
        }
    }
    for (int i=0;i<NCH;i++) wait();
    for (int i=0;i<NCH;i++) cprintf("parent: buf[%d]=%d\n", i, bigbuf[i*4096]);
    return 0;
}

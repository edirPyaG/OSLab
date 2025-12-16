#include <ulib.h>
#include <stdio.h>

static char a[4096];
static char b[4096];

int main(void) {
    a[0] = 1; b[0] = 2;
    int pid = fork();
    if (pid == 0) {
        a[0] = 11;
        cprintf("child: a=%d b=%d\n", a[0], b[0]);
        exit(0);
    } else {
        b[0] = 22;
        wait();
        cprintf("parent: a=%d b=%d\n", a[0], b[0]);
    }
    return 0;
}

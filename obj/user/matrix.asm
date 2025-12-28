
obj/__user_matrix.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	13a000ef          	jal	ra,80015a <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <__panic>:
#include <stdio.h>
#include <ulib.h>
#include <error.h>

void
__panic(const char *file, int line, const char *fmt, ...) {
  800026:	715d                	addi	sp,sp,-80
  800028:	8e2e                	mv	t3,a1
  80002a:	e822                	sd	s0,16(sp)
    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("user panic at %s:%d:\n    ", file, line);
  80002c:	85aa                	mv	a1,a0
__panic(const char *file, int line, const char *fmt, ...) {
  80002e:	8432                	mv	s0,a2
  800030:	fc3e                	sd	a5,56(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  800032:	8672                	mv	a2,t3
    va_start(ap, fmt);
  800034:	103c                	addi	a5,sp,40
    cprintf("user panic at %s:%d:\n    ", file, line);
  800036:	00000517          	auipc	a0,0x0
  80003a:	77250513          	addi	a0,a0,1906 # 8007a8 <main+0xc6>
__panic(const char *file, int line, const char *fmt, ...) {
  80003e:	ec06                	sd	ra,24(sp)
  800040:	f436                	sd	a3,40(sp)
  800042:	f83a                	sd	a4,48(sp)
  800044:	e0c2                	sd	a6,64(sp)
  800046:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800048:	e43e                	sd	a5,8(sp)
    cprintf("user panic at %s:%d:\n    ", file, line);
  80004a:	058000ef          	jal	ra,8000a2 <cprintf>
    vcprintf(fmt, ap);
  80004e:	65a2                	ld	a1,8(sp)
  800050:	8522                	mv	a0,s0
  800052:	030000ef          	jal	ra,800082 <vcprintf>
    cprintf("\n");
  800056:	00001517          	auipc	a0,0x1
  80005a:	ada50513          	addi	a0,a0,-1318 # 800b30 <error_string+0x100>
  80005e:	044000ef          	jal	ra,8000a2 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0d2000ef          	jal	ra,800136 <exit>

0000000000800068 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800068:	1141                	addi	sp,sp,-16
  80006a:	e022                	sd	s0,0(sp)
  80006c:	e406                	sd	ra,8(sp)
  80006e:	842e                	mv	s0,a1
    sys_putc(c);
  800070:	0c0000ef          	jal	ra,800130 <sys_putc>
    (*cnt) ++;
  800074:	401c                	lw	a5,0(s0)
}
  800076:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800078:	2785                	addiw	a5,a5,1
  80007a:	c01c                	sw	a5,0(s0)
}
  80007c:	6402                	ld	s0,0(sp)
  80007e:	0141                	addi	sp,sp,16
  800080:	8082                	ret

0000000000800082 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
  800082:	1101                	addi	sp,sp,-32
  800084:	862a                	mv	a2,a0
  800086:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800088:	00000517          	auipc	a0,0x0
  80008c:	fe050513          	addi	a0,a0,-32 # 800068 <cputch>
  800090:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
  800092:	ec06                	sd	ra,24(sp)
    int cnt = 0;
  800094:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  800096:	13c000ef          	jal	ra,8001d2 <vprintfmt>
    return cnt;
}
  80009a:	60e2                	ld	ra,24(sp)
  80009c:	4532                	lw	a0,12(sp)
  80009e:	6105                	addi	sp,sp,32
  8000a0:	8082                	ret

00000000008000a2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  8000a2:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  8000a4:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  8000a8:	8e2a                	mv	t3,a0
  8000aa:	f42e                	sd	a1,40(sp)
  8000ac:	f832                	sd	a2,48(sp)
  8000ae:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000b0:	00000517          	auipc	a0,0x0
  8000b4:	fb850513          	addi	a0,a0,-72 # 800068 <cputch>
  8000b8:	004c                	addi	a1,sp,4
  8000ba:	869a                	mv	a3,t1
  8000bc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  8000be:	ec06                	sd	ra,24(sp)
  8000c0:	e0ba                	sd	a4,64(sp)
  8000c2:	e4be                	sd	a5,72(sp)
  8000c4:	e8c2                	sd	a6,80(sp)
  8000c6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  8000c8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  8000ca:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  8000cc:	106000ef          	jal	ra,8001d2 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  8000d0:	60e2                	ld	ra,24(sp)
  8000d2:	4512                	lw	a0,4(sp)
  8000d4:	6125                	addi	sp,sp,96
  8000d6:	8082                	ret

00000000008000d8 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  8000d8:	7175                	addi	sp,sp,-144
  8000da:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  8000dc:	e0ba                	sd	a4,64(sp)
  8000de:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  8000e0:	e42a                	sd	a0,8(sp)
  8000e2:	ecae                	sd	a1,88(sp)
  8000e4:	f0b2                	sd	a2,96(sp)
  8000e6:	f4b6                	sd	a3,104(sp)
  8000e8:	fcbe                	sd	a5,120(sp)
  8000ea:	e142                	sd	a6,128(sp)
  8000ec:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  8000ee:	f42e                	sd	a1,40(sp)
  8000f0:	f832                	sd	a2,48(sp)
  8000f2:	fc36                	sd	a3,56(sp)
  8000f4:	f03a                	sd	a4,32(sp)
  8000f6:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);
    asm volatile (
  8000f8:	4522                	lw	a0,8(sp)
  8000fa:	55a2                	lw	a1,40(sp)
  8000fc:	5642                	lw	a2,48(sp)
  8000fe:	56e2                	lw	a3,56(sp)
  800100:	4706                	lw	a4,64(sp)
  800102:	47a6                	lw	a5,72(sp)
  800104:	00000073          	ecall
  800108:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  80010a:	4572                	lw	a0,28(sp)
  80010c:	6149                	addi	sp,sp,144
  80010e:	8082                	ret

0000000000800110 <sys_exit>:

int
sys_exit(int64_t error_code) {
  800110:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  800112:	4505                	li	a0,1
  800114:	b7d1                	j	8000d8 <syscall>

0000000000800116 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  800116:	4509                	li	a0,2
  800118:	b7c1                	j	8000d8 <syscall>

000000000080011a <sys_wait>:
}

int
sys_wait(int64_t pid, int *store) {
  80011a:	862e                	mv	a2,a1
    return syscall(SYS_wait, pid, store);
  80011c:	85aa                	mv	a1,a0
  80011e:	450d                	li	a0,3
  800120:	bf65                	j	8000d8 <syscall>

0000000000800122 <sys_yield>:
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  800122:	4529                	li	a0,10
  800124:	bf55                	j	8000d8 <syscall>

0000000000800126 <sys_kill>:
}

int
sys_kill(int64_t pid) {
  800126:	85aa                	mv	a1,a0
    return syscall(SYS_kill, pid);
  800128:	4531                	li	a0,12
  80012a:	b77d                	j	8000d8 <syscall>

000000000080012c <sys_getpid>:
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  80012c:	4549                	li	a0,18
  80012e:	b76d                	j	8000d8 <syscall>

0000000000800130 <sys_putc>:
}

int
sys_putc(int64_t c) {
  800130:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800132:	4579                	li	a0,30
  800134:	b755                	j	8000d8 <syscall>

0000000000800136 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  800136:	1141                	addi	sp,sp,-16
  800138:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  80013a:	fd7ff0ef          	jal	ra,800110 <sys_exit>
    cprintf("BUG: exit failed.\n");
  80013e:	00000517          	auipc	a0,0x0
  800142:	68a50513          	addi	a0,a0,1674 # 8007c8 <main+0xe6>
  800146:	f5dff0ef          	jal	ra,8000a2 <cprintf>
    while (1);
  80014a:	a001                	j	80014a <exit+0x14>

000000000080014c <fork>:
}

int
fork(void) {
    return sys_fork();
  80014c:	b7e9                	j	800116 <sys_fork>

000000000080014e <wait>:
}

int
wait(void) {
    return sys_wait(0, NULL);
  80014e:	4581                	li	a1,0
  800150:	4501                	li	a0,0
  800152:	b7e1                	j	80011a <sys_wait>

0000000000800154 <yield>:
    return sys_wait(pid, store);
}

void
yield(void) {
    sys_yield();
  800154:	b7f9                	j	800122 <sys_yield>

0000000000800156 <kill>:
}

int
kill(int pid) {
    return sys_kill(pid);
  800156:	bfc1                	j	800126 <sys_kill>

0000000000800158 <getpid>:
}

int
getpid(void) {
    return sys_getpid();
  800158:	bfd1                	j	80012c <sys_getpid>

000000000080015a <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  80015a:	1141                	addi	sp,sp,-16
  80015c:	e406                	sd	ra,8(sp)
    int ret = main();
  80015e:	584000ef          	jal	ra,8006e2 <main>
    exit(ret);
  800162:	fd5ff0ef          	jal	ra,800136 <exit>

0000000000800166 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  800166:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  80016a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  80016c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800170:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  800172:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  800176:	f022                	sd	s0,32(sp)
  800178:	ec26                	sd	s1,24(sp)
  80017a:	e84a                	sd	s2,16(sp)
  80017c:	f406                	sd	ra,40(sp)
  80017e:	e44e                	sd	s3,8(sp)
  800180:	84aa                	mv	s1,a0
  800182:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800184:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800188:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80018a:	03067e63          	bgeu	a2,a6,8001c6 <printnum+0x60>
  80018e:	89be                	mv	s3,a5
        while (-- width > 0)
  800190:	00805763          	blez	s0,80019e <printnum+0x38>
  800194:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800196:	85ca                	mv	a1,s2
  800198:	854e                	mv	a0,s3
  80019a:	9482                	jalr	s1
        while (-- width > 0)
  80019c:	fc65                	bnez	s0,800194 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  80019e:	1a02                	slli	s4,s4,0x20
  8001a0:	00000797          	auipc	a5,0x0
  8001a4:	64078793          	addi	a5,a5,1600 # 8007e0 <main+0xfe>
  8001a8:	020a5a13          	srli	s4,s4,0x20
  8001ac:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  8001ae:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001b0:	000a4503          	lbu	a0,0(s4)
}
  8001b4:	70a2                	ld	ra,40(sp)
  8001b6:	69a2                	ld	s3,8(sp)
  8001b8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  8001ba:	85ca                	mv	a1,s2
  8001bc:	87a6                	mv	a5,s1
}
  8001be:	6942                	ld	s2,16(sp)
  8001c0:	64e2                	ld	s1,24(sp)
  8001c2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  8001c4:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  8001c6:	03065633          	divu	a2,a2,a6
  8001ca:	8722                	mv	a4,s0
  8001cc:	f9bff0ef          	jal	ra,800166 <printnum>
  8001d0:	b7f9                	j	80019e <printnum+0x38>

00000000008001d2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001d2:	7119                	addi	sp,sp,-128
  8001d4:	f4a6                	sd	s1,104(sp)
  8001d6:	f0ca                	sd	s2,96(sp)
  8001d8:	ecce                	sd	s3,88(sp)
  8001da:	e8d2                	sd	s4,80(sp)
  8001dc:	e4d6                	sd	s5,72(sp)
  8001de:	e0da                	sd	s6,64(sp)
  8001e0:	fc5e                	sd	s7,56(sp)
  8001e2:	f06a                	sd	s10,32(sp)
  8001e4:	fc86                	sd	ra,120(sp)
  8001e6:	f8a2                	sd	s0,112(sp)
  8001e8:	f862                	sd	s8,48(sp)
  8001ea:	f466                	sd	s9,40(sp)
  8001ec:	ec6e                	sd	s11,24(sp)
  8001ee:	892a                	mv	s2,a0
  8001f0:	84ae                	mv	s1,a1
  8001f2:	8d32                	mv	s10,a2
  8001f4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001f6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  8001fa:	5b7d                	li	s6,-1
  8001fc:	00000a97          	auipc	s5,0x0
  800200:	618a8a93          	addi	s5,s5,1560 # 800814 <main+0x132>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800204:	00001b97          	auipc	s7,0x1
  800208:	82cb8b93          	addi	s7,s7,-2004 # 800a30 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80020c:	000d4503          	lbu	a0,0(s10)
  800210:	001d0413          	addi	s0,s10,1
  800214:	01350a63          	beq	a0,s3,800228 <vprintfmt+0x56>
            if (ch == '\0') {
  800218:	c121                	beqz	a0,800258 <vprintfmt+0x86>
            putch(ch, putdat);
  80021a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80021c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  80021e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800220:	fff44503          	lbu	a0,-1(s0)
  800224:	ff351ae3          	bne	a0,s3,800218 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  800228:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  80022c:	02000793          	li	a5,32
        lflag = altflag = 0;
  800230:	4c81                	li	s9,0
  800232:	4881                	li	a7,0
        width = precision = -1;
  800234:	5c7d                	li	s8,-1
  800236:	5dfd                	li	s11,-1
  800238:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  80023c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  80023e:	fdd6059b          	addiw	a1,a2,-35
  800242:	0ff5f593          	zext.b	a1,a1
  800246:	00140d13          	addi	s10,s0,1
  80024a:	04b56263          	bltu	a0,a1,80028e <vprintfmt+0xbc>
  80024e:	058a                	slli	a1,a1,0x2
  800250:	95d6                	add	a1,a1,s5
  800252:	4194                	lw	a3,0(a1)
  800254:	96d6                	add	a3,a3,s5
  800256:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800258:	70e6                	ld	ra,120(sp)
  80025a:	7446                	ld	s0,112(sp)
  80025c:	74a6                	ld	s1,104(sp)
  80025e:	7906                	ld	s2,96(sp)
  800260:	69e6                	ld	s3,88(sp)
  800262:	6a46                	ld	s4,80(sp)
  800264:	6aa6                	ld	s5,72(sp)
  800266:	6b06                	ld	s6,64(sp)
  800268:	7be2                	ld	s7,56(sp)
  80026a:	7c42                	ld	s8,48(sp)
  80026c:	7ca2                	ld	s9,40(sp)
  80026e:	7d02                	ld	s10,32(sp)
  800270:	6de2                	ld	s11,24(sp)
  800272:	6109                	addi	sp,sp,128
  800274:	8082                	ret
            padc = '0';
  800276:	87b2                	mv	a5,a2
            goto reswitch;
  800278:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80027c:	846a                	mv	s0,s10
  80027e:	00140d13          	addi	s10,s0,1
  800282:	fdd6059b          	addiw	a1,a2,-35
  800286:	0ff5f593          	zext.b	a1,a1
  80028a:	fcb572e3          	bgeu	a0,a1,80024e <vprintfmt+0x7c>
            putch('%', putdat);
  80028e:	85a6                	mv	a1,s1
  800290:	02500513          	li	a0,37
  800294:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800296:	fff44783          	lbu	a5,-1(s0)
  80029a:	8d22                	mv	s10,s0
  80029c:	f73788e3          	beq	a5,s3,80020c <vprintfmt+0x3a>
  8002a0:	ffed4783          	lbu	a5,-2(s10)
  8002a4:	1d7d                	addi	s10,s10,-1
  8002a6:	ff379de3          	bne	a5,s3,8002a0 <vprintfmt+0xce>
  8002aa:	b78d                	j	80020c <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  8002ac:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  8002b0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  8002b4:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  8002b6:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  8002ba:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002be:	02d86463          	bltu	a6,a3,8002e6 <vprintfmt+0x114>
                ch = *fmt;
  8002c2:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  8002c6:	002c169b          	slliw	a3,s8,0x2
  8002ca:	0186873b          	addw	a4,a3,s8
  8002ce:	0017171b          	slliw	a4,a4,0x1
  8002d2:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  8002d4:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  8002d8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002da:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  8002de:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002e2:	fed870e3          	bgeu	a6,a3,8002c2 <vprintfmt+0xf0>
            if (width < 0)
  8002e6:	f40ddce3          	bgez	s11,80023e <vprintfmt+0x6c>
                width = precision, precision = -1;
  8002ea:	8de2                	mv	s11,s8
  8002ec:	5c7d                	li	s8,-1
  8002ee:	bf81                	j	80023e <vprintfmt+0x6c>
            if (width < 0)
  8002f0:	fffdc693          	not	a3,s11
  8002f4:	96fd                	srai	a3,a3,0x3f
  8002f6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  8002fa:	00144603          	lbu	a2,1(s0)
  8002fe:	2d81                	sext.w	s11,s11
  800300:	846a                	mv	s0,s10
            goto reswitch;
  800302:	bf35                	j	80023e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  800304:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  800308:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  80030c:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  80030e:	846a                	mv	s0,s10
            goto process_precision;
  800310:	bfd9                	j	8002e6 <vprintfmt+0x114>
    if (lflag >= 2) {
  800312:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800314:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800318:	01174463          	blt	a4,a7,800320 <vprintfmt+0x14e>
    else if (lflag) {
  80031c:	1a088e63          	beqz	a7,8004d8 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  800320:	000a3603          	ld	a2,0(s4)
  800324:	46c1                	li	a3,16
  800326:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  800328:	2781                	sext.w	a5,a5
  80032a:	876e                	mv	a4,s11
  80032c:	85a6                	mv	a1,s1
  80032e:	854a                	mv	a0,s2
  800330:	e37ff0ef          	jal	ra,800166 <printnum>
            break;
  800334:	bde1                	j	80020c <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  800336:	000a2503          	lw	a0,0(s4)
  80033a:	85a6                	mv	a1,s1
  80033c:	0a21                	addi	s4,s4,8
  80033e:	9902                	jalr	s2
            break;
  800340:	b5f1                	j	80020c <vprintfmt+0x3a>
    if (lflag >= 2) {
  800342:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800344:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800348:	01174463          	blt	a4,a7,800350 <vprintfmt+0x17e>
    else if (lflag) {
  80034c:	18088163          	beqz	a7,8004ce <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  800350:	000a3603          	ld	a2,0(s4)
  800354:	46a9                	li	a3,10
  800356:	8a2e                	mv	s4,a1
  800358:	bfc1                	j	800328 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  80035a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  80035e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800360:	846a                	mv	s0,s10
            goto reswitch;
  800362:	bdf1                	j	80023e <vprintfmt+0x6c>
            putch(ch, putdat);
  800364:	85a6                	mv	a1,s1
  800366:	02500513          	li	a0,37
  80036a:	9902                	jalr	s2
            break;
  80036c:	b545                	j	80020c <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  80036e:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800372:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800374:	846a                	mv	s0,s10
            goto reswitch;
  800376:	b5e1                	j	80023e <vprintfmt+0x6c>
    if (lflag >= 2) {
  800378:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80037a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80037e:	01174463          	blt	a4,a7,800386 <vprintfmt+0x1b4>
    else if (lflag) {
  800382:	14088163          	beqz	a7,8004c4 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800386:	000a3603          	ld	a2,0(s4)
  80038a:	46a1                	li	a3,8
  80038c:	8a2e                	mv	s4,a1
  80038e:	bf69                	j	800328 <vprintfmt+0x156>
            putch('0', putdat);
  800390:	03000513          	li	a0,48
  800394:	85a6                	mv	a1,s1
  800396:	e03e                	sd	a5,0(sp)
  800398:	9902                	jalr	s2
            putch('x', putdat);
  80039a:	85a6                	mv	a1,s1
  80039c:	07800513          	li	a0,120
  8003a0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8003a2:	0a21                	addi	s4,s4,8
            goto number;
  8003a4:	6782                	ld	a5,0(sp)
  8003a6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  8003a8:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  8003ac:	bfb5                	j	800328 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003ae:	000a3403          	ld	s0,0(s4)
  8003b2:	008a0713          	addi	a4,s4,8
  8003b6:	e03a                	sd	a4,0(sp)
  8003b8:	14040263          	beqz	s0,8004fc <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  8003bc:	0fb05763          	blez	s11,8004aa <vprintfmt+0x2d8>
  8003c0:	02d00693          	li	a3,45
  8003c4:	0cd79163          	bne	a5,a3,800486 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003c8:	00044783          	lbu	a5,0(s0)
  8003cc:	0007851b          	sext.w	a0,a5
  8003d0:	cf85                	beqz	a5,800408 <vprintfmt+0x236>
  8003d2:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003d6:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003da:	000c4563          	bltz	s8,8003e4 <vprintfmt+0x212>
  8003de:	3c7d                	addiw	s8,s8,-1
  8003e0:	036c0263          	beq	s8,s6,800404 <vprintfmt+0x232>
                    putch('?', putdat);
  8003e4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003e6:	0e0c8e63          	beqz	s9,8004e2 <vprintfmt+0x310>
  8003ea:	3781                	addiw	a5,a5,-32
  8003ec:	0ef47b63          	bgeu	s0,a5,8004e2 <vprintfmt+0x310>
                    putch('?', putdat);
  8003f0:	03f00513          	li	a0,63
  8003f4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003f6:	000a4783          	lbu	a5,0(s4)
  8003fa:	3dfd                	addiw	s11,s11,-1
  8003fc:	0a05                	addi	s4,s4,1
  8003fe:	0007851b          	sext.w	a0,a5
  800402:	ffe1                	bnez	a5,8003da <vprintfmt+0x208>
            for (; width > 0; width --) {
  800404:	01b05963          	blez	s11,800416 <vprintfmt+0x244>
  800408:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  80040a:	85a6                	mv	a1,s1
  80040c:	02000513          	li	a0,32
  800410:	9902                	jalr	s2
            for (; width > 0; width --) {
  800412:	fe0d9be3          	bnez	s11,800408 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  800416:	6a02                	ld	s4,0(sp)
  800418:	bbd5                	j	80020c <vprintfmt+0x3a>
    if (lflag >= 2) {
  80041a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80041c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  800420:	01174463          	blt	a4,a7,800428 <vprintfmt+0x256>
    else if (lflag) {
  800424:	08088d63          	beqz	a7,8004be <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  800428:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  80042c:	0a044d63          	bltz	s0,8004e6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  800430:	8622                	mv	a2,s0
  800432:	8a66                	mv	s4,s9
  800434:	46a9                	li	a3,10
  800436:	bdcd                	j	800328 <vprintfmt+0x156>
            err = va_arg(ap, int);
  800438:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80043c:	4761                	li	a4,24
            err = va_arg(ap, int);
  80043e:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800440:	41f7d69b          	sraiw	a3,a5,0x1f
  800444:	8fb5                	xor	a5,a5,a3
  800446:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80044a:	02d74163          	blt	a4,a3,80046c <vprintfmt+0x29a>
  80044e:	00369793          	slli	a5,a3,0x3
  800452:	97de                	add	a5,a5,s7
  800454:	639c                	ld	a5,0(a5)
  800456:	cb99                	beqz	a5,80046c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  800458:	86be                	mv	a3,a5
  80045a:	00000617          	auipc	a2,0x0
  80045e:	3b660613          	addi	a2,a2,950 # 800810 <main+0x12e>
  800462:	85a6                	mv	a1,s1
  800464:	854a                	mv	a0,s2
  800466:	0ce000ef          	jal	ra,800534 <printfmt>
  80046a:	b34d                	j	80020c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  80046c:	00000617          	auipc	a2,0x0
  800470:	39460613          	addi	a2,a2,916 # 800800 <main+0x11e>
  800474:	85a6                	mv	a1,s1
  800476:	854a                	mv	a0,s2
  800478:	0bc000ef          	jal	ra,800534 <printfmt>
  80047c:	bb41                	j	80020c <vprintfmt+0x3a>
                p = "(null)";
  80047e:	00000417          	auipc	s0,0x0
  800482:	37a40413          	addi	s0,s0,890 # 8007f8 <main+0x116>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800486:	85e2                	mv	a1,s8
  800488:	8522                	mv	a0,s0
  80048a:	e43e                	sd	a5,8(sp)
  80048c:	108000ef          	jal	ra,800594 <strnlen>
  800490:	40ad8dbb          	subw	s11,s11,a0
  800494:	01b05b63          	blez	s11,8004aa <vprintfmt+0x2d8>
                    putch(padc, putdat);
  800498:	67a2                	ld	a5,8(sp)
  80049a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  80049e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  8004a0:	85a6                	mv	a1,s1
  8004a2:	8552                	mv	a0,s4
  8004a4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  8004a6:	fe0d9ce3          	bnez	s11,80049e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004aa:	00044783          	lbu	a5,0(s0)
  8004ae:	00140a13          	addi	s4,s0,1
  8004b2:	0007851b          	sext.w	a0,a5
  8004b6:	d3a5                	beqz	a5,800416 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  8004b8:	05e00413          	li	s0,94
  8004bc:	bf39                	j	8003da <vprintfmt+0x208>
        return va_arg(*ap, int);
  8004be:	000a2403          	lw	s0,0(s4)
  8004c2:	b7ad                	j	80042c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  8004c4:	000a6603          	lwu	a2,0(s4)
  8004c8:	46a1                	li	a3,8
  8004ca:	8a2e                	mv	s4,a1
  8004cc:	bdb1                	j	800328 <vprintfmt+0x156>
  8004ce:	000a6603          	lwu	a2,0(s4)
  8004d2:	46a9                	li	a3,10
  8004d4:	8a2e                	mv	s4,a1
  8004d6:	bd89                	j	800328 <vprintfmt+0x156>
  8004d8:	000a6603          	lwu	a2,0(s4)
  8004dc:	46c1                	li	a3,16
  8004de:	8a2e                	mv	s4,a1
  8004e0:	b5a1                	j	800328 <vprintfmt+0x156>
                    putch(ch, putdat);
  8004e2:	9902                	jalr	s2
  8004e4:	bf09                	j	8003f6 <vprintfmt+0x224>
                putch('-', putdat);
  8004e6:	85a6                	mv	a1,s1
  8004e8:	02d00513          	li	a0,45
  8004ec:	e03e                	sd	a5,0(sp)
  8004ee:	9902                	jalr	s2
                num = -(long long)num;
  8004f0:	6782                	ld	a5,0(sp)
  8004f2:	8a66                	mv	s4,s9
  8004f4:	40800633          	neg	a2,s0
  8004f8:	46a9                	li	a3,10
  8004fa:	b53d                	j	800328 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  8004fc:	03b05163          	blez	s11,80051e <vprintfmt+0x34c>
  800500:	02d00693          	li	a3,45
  800504:	f6d79de3          	bne	a5,a3,80047e <vprintfmt+0x2ac>
                p = "(null)";
  800508:	00000417          	auipc	s0,0x0
  80050c:	2f040413          	addi	s0,s0,752 # 8007f8 <main+0x116>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800510:	02800793          	li	a5,40
  800514:	02800513          	li	a0,40
  800518:	00140a13          	addi	s4,s0,1
  80051c:	bd6d                	j	8003d6 <vprintfmt+0x204>
  80051e:	00000a17          	auipc	s4,0x0
  800522:	2dba0a13          	addi	s4,s4,731 # 8007f9 <main+0x117>
  800526:	02800513          	li	a0,40
  80052a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  80052e:	05e00413          	li	s0,94
  800532:	b565                	j	8003da <vprintfmt+0x208>

0000000000800534 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800534:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  800536:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80053a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80053c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80053e:	ec06                	sd	ra,24(sp)
  800540:	f83a                	sd	a4,48(sp)
  800542:	fc3e                	sd	a5,56(sp)
  800544:	e0c2                	sd	a6,64(sp)
  800546:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800548:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  80054a:	c89ff0ef          	jal	ra,8001d2 <vprintfmt>
}
  80054e:	60e2                	ld	ra,24(sp)
  800550:	6161                	addi	sp,sp,80
  800552:	8082                	ret

0000000000800554 <rand>:
 *
 * The rand() function return a value in the range [0, RAND_MAX].
 * */
int
rand(void) {
    next = (next * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
  800554:	00001697          	auipc	a3,0x1
  800558:	aac68693          	addi	a3,a3,-1364 # 801000 <next>
  80055c:	629c                	ld	a5,0(a3)
  80055e:	00000717          	auipc	a4,0x0
  800562:	61a73703          	ld	a4,1562(a4) # 800b78 <error_string+0x148>
  800566:	02e787b3          	mul	a5,a5,a4
    unsigned long long result = (next >> 12);
    return (int)do_div(result, RAND_MAX + 1);
  80056a:	80000737          	lui	a4,0x80000
  80056e:	fff74713          	not	a4,a4
    next = (next * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
  800572:	07ad                	addi	a5,a5,11
  800574:	07c2                	slli	a5,a5,0x10
  800576:	83c1                	srli	a5,a5,0x10
    unsigned long long result = (next >> 12);
  800578:	00c7d513          	srli	a0,a5,0xc
    return (int)do_div(result, RAND_MAX + 1);
  80057c:	02e57533          	remu	a0,a0,a4
    next = (next * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
  800580:	e29c                	sd	a5,0(a3)
}
  800582:	2505                	addiw	a0,a0,1
  800584:	8082                	ret

0000000000800586 <srand>:
 * srand - seed the random number generator with the given number
 * @seed:   the required seed number
 * */
void
srand(unsigned int seed) {
    next = seed;
  800586:	1502                	slli	a0,a0,0x20
  800588:	9101                	srli	a0,a0,0x20
  80058a:	00001797          	auipc	a5,0x1
  80058e:	a6a7bb23          	sd	a0,-1418(a5) # 801000 <next>
}
  800592:	8082                	ret

0000000000800594 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  800594:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  800596:	e589                	bnez	a1,8005a0 <strnlen+0xc>
  800598:	a811                	j	8005ac <strnlen+0x18>
        cnt ++;
  80059a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  80059c:	00f58863          	beq	a1,a5,8005ac <strnlen+0x18>
  8005a0:	00f50733          	add	a4,a0,a5
  8005a4:	00074703          	lbu	a4,0(a4) # ffffffff80000000 <matc+0xffffffff7f7fecd8>
  8005a8:	fb6d                	bnez	a4,80059a <strnlen+0x6>
  8005aa:	85be                	mv	a1,a5
    }
    return cnt;
}
  8005ac:	852e                	mv	a0,a1
  8005ae:	8082                	ret

00000000008005b0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
  8005b0:	ca01                	beqz	a2,8005c0 <memset+0x10>
  8005b2:	962a                	add	a2,a2,a0
    char *p = s;
  8005b4:	87aa                	mv	a5,a0
        *p ++ = c;
  8005b6:	0785                	addi	a5,a5,1
  8005b8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
  8005bc:	fec79de3          	bne	a5,a2,8005b6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
  8005c0:	8082                	ret

00000000008005c2 <work>:
static int mata[MATSIZE][MATSIZE];
static int matb[MATSIZE][MATSIZE];
static int matc[MATSIZE][MATSIZE];

void
work(unsigned int times) {
  8005c2:	7179                	addi	sp,sp,-48
  8005c4:	ec26                	sd	s1,24(sp)
  8005c6:	00001497          	auipc	s1,0x1
  8005ca:	a4248493          	addi	s1,s1,-1470 # 801008 <mata>
  8005ce:	f022                	sd	s0,32(sp)
  8005d0:	e84a                	sd	s2,16(sp)
  8005d2:	e44e                	sd	s3,8(sp)
  8005d4:	f406                	sd	ra,40(sp)
  8005d6:	89aa                	mv	s3,a0
  8005d8:	00001917          	auipc	s2,0x1
  8005dc:	bc090913          	addi	s2,s2,-1088 # 801198 <matb>
  8005e0:	00001597          	auipc	a1,0x1
  8005e4:	be058593          	addi	a1,a1,-1056 # 8011c0 <matb+0x28>
  8005e8:	00001417          	auipc	s0,0x1
  8005ec:	d6840413          	addi	s0,s0,-664 # 801350 <matc+0x28>
  8005f0:	8626                	mv	a2,s1
    int i, j, k, size = MATSIZE;
    for (i = 0; i < size; i ++) {
        for (j = 0; j < size; j ++) {
            mata[i][j] = matb[i][j] = 1;
  8005f2:	4685                	li	a3,1
        for (j = 0; j < size; j ++) {
  8005f4:	fd858793          	addi	a5,a1,-40
work(unsigned int times) {
  8005f8:	8732                	mv	a4,a2
            mata[i][j] = matb[i][j] = 1;
  8005fa:	c394                	sw	a3,0(a5)
  8005fc:	c314                	sw	a3,0(a4)
        for (j = 0; j < size; j ++) {
  8005fe:	0791                	addi	a5,a5,4
  800600:	0711                	addi	a4,a4,4
  800602:	feb79ce3          	bne	a5,a1,8005fa <work+0x38>
    for (i = 0; i < size; i ++) {
  800606:	02878593          	addi	a1,a5,40
  80060a:	02860613          	addi	a2,a2,40
  80060e:	fe8593e3          	bne	a1,s0,8005f4 <work+0x32>
        }
    }

    yield();
  800612:	b43ff0ef          	jal	ra,800154 <yield>

    cprintf("pid %d is running (%d times)!.\n", getpid(), times);
  800616:	b43ff0ef          	jal	ra,800158 <getpid>
  80061a:	85aa                	mv	a1,a0
  80061c:	864e                	mv	a2,s3
  80061e:	00000517          	auipc	a0,0x0
  800622:	4da50513          	addi	a0,a0,1242 # 800af8 <error_string+0xc8>
  800626:	a7dff0ef          	jal	ra,8000a2 <cprintf>

    while (times -- > 0) {
  80062a:	fff9839b          	addiw	t2,s3,-1
  80062e:	00001297          	auipc	t0,0x1
  800632:	e8a28293          	addi	t0,t0,-374 # 8014b8 <matc+0x190>
  800636:	00001f97          	auipc	t6,0x1
  80063a:	b62f8f93          	addi	t6,t6,-1182 # 801198 <matb>
  80063e:	00001f17          	auipc	t5,0x1
  800642:	ceaf0f13          	addi	t5,t5,-790 # 801328 <matc>
                    matc[i][j] += mata[i][k] * matb[k][j];
                }
            }
        }
        for (i = 0; i < size; i ++) {
            for (j = 0; j < size; j ++) {
  800646:	02800e13          	li	t3,40
    while (times -- > 0) {
  80064a:	50fd                	li	ra,-1
  80064c:	06098f63          	beqz	s3,8006ca <work+0x108>
  800650:	00001897          	auipc	a7,0x1
  800654:	cd888893          	addi	a7,a7,-808 # 801328 <matc>
work(unsigned int times) {
  800658:	8ec6                	mv	t4,a7
  80065a:	8326                	mv	t1,s1
            for (j = 0; j < size; j ++) {
  80065c:	857a                	mv	a0,t5
work(unsigned int times) {
  80065e:	8876                	mv	a6,t4
                for (k = 0; k < size; k ++) {
  800660:	e7050793          	addi	a5,a0,-400
work(unsigned int times) {
  800664:	869a                	mv	a3,t1
  800666:	4601                	li	a2,0
                    matc[i][j] += mata[i][k] * matb[k][j];
  800668:	4298                	lw	a4,0(a3)
  80066a:	438c                	lw	a1,0(a5)
                for (k = 0; k < size; k ++) {
  80066c:	02878793          	addi	a5,a5,40
  800670:	0691                	addi	a3,a3,4
                    matc[i][j] += mata[i][k] * matb[k][j];
  800672:	02b7073b          	mulw	a4,a4,a1
  800676:	9e39                	addw	a2,a2,a4
                for (k = 0; k < size; k ++) {
  800678:	fea798e3          	bne	a5,a0,800668 <work+0xa6>
  80067c:	00c82023          	sw	a2,0(a6)
            for (j = 0; j < size; j ++) {
  800680:	00478513          	addi	a0,a5,4
  800684:	0811                	addi	a6,a6,4
  800686:	fc851de3          	bne	a0,s0,800660 <work+0x9e>
        for (i = 0; i < size; i ++) {
  80068a:	02830313          	addi	t1,t1,40
  80068e:	028e8e93          	addi	t4,t4,40
  800692:	fc6f95e3          	bne	t6,t1,80065c <work+0x9a>
  800696:	8526                	mv	a0,s1
  800698:	85ca                	mv	a1,s2
work(unsigned int times) {
  80069a:	4781                	li	a5,0
                mata[i][j] = matb[i][j] = matc[i][j];
  80069c:	00f88733          	add	a4,a7,a5
  8006a0:	4318                	lw	a4,0(a4)
  8006a2:	00f58633          	add	a2,a1,a5
  8006a6:	00f506b3          	add	a3,a0,a5
  8006aa:	c218                	sw	a4,0(a2)
  8006ac:	c298                	sw	a4,0(a3)
            for (j = 0; j < size; j ++) {
  8006ae:	0791                	addi	a5,a5,4
  8006b0:	ffc796e3          	bne	a5,t3,80069c <work+0xda>
        for (i = 0; i < size; i ++) {
  8006b4:	02888893          	addi	a7,a7,40
  8006b8:	02858593          	addi	a1,a1,40
  8006bc:	02850513          	addi	a0,a0,40
  8006c0:	fc589de3          	bne	a7,t0,80069a <work+0xd8>
    while (times -- > 0) {
  8006c4:	33fd                	addiw	t2,t2,-1
  8006c6:	f81395e3          	bne	t2,ra,800650 <work+0x8e>
            }
        }
    }
    cprintf("pid %d done!.\n", getpid());
  8006ca:	a8fff0ef          	jal	ra,800158 <getpid>
  8006ce:	85aa                	mv	a1,a0
  8006d0:	00000517          	auipc	a0,0x0
  8006d4:	44850513          	addi	a0,a0,1096 # 800b18 <error_string+0xe8>
  8006d8:	9cbff0ef          	jal	ra,8000a2 <cprintf>
    exit(0);
  8006dc:	4501                	li	a0,0
  8006de:	a59ff0ef          	jal	ra,800136 <exit>

00000000008006e2 <main>:
}

const int total = 21;

int
main(void) {
  8006e2:	7175                	addi	sp,sp,-144
  8006e4:	f4ce                	sd	s3,104(sp)
    int pids[total];
    memset(pids, 0, sizeof(pids));
  8006e6:	05400613          	li	a2,84
  8006ea:	4581                	li	a1,0
  8006ec:	0028                	addi	a0,sp,8
  8006ee:	00810993          	addi	s3,sp,8
main(void) {
  8006f2:	e122                	sd	s0,128(sp)
  8006f4:	fca6                	sd	s1,120(sp)
  8006f6:	f8ca                	sd	s2,112(sp)
  8006f8:	e506                	sd	ra,136(sp)
    memset(pids, 0, sizeof(pids));
  8006fa:	84ce                	mv	s1,s3
  8006fc:	eb5ff0ef          	jal	ra,8005b0 <memset>

    int i;
    for (i = 0; i < total; i ++) {
  800700:	4401                	li	s0,0
  800702:	4955                	li	s2,21
        if ((pids[i] = fork()) == 0) {
  800704:	a49ff0ef          	jal	ra,80014c <fork>
  800708:	c088                	sw	a0,0(s1)
  80070a:	cd2d                	beqz	a0,800784 <main+0xa2>
            srand(i * i);
            int times = (((unsigned int)rand()) % total);
            times = (times * times + 10) * 100;
            work(times);
        }
        if (pids[i] < 0) {
  80070c:	04054663          	bltz	a0,800758 <main+0x76>
    for (i = 0; i < total; i ++) {
  800710:	2405                	addiw	s0,s0,1
  800712:	0491                	addi	s1,s1,4
  800714:	ff2418e3          	bne	s0,s2,800704 <main+0x22>
            goto failed;
        }
    }

    cprintf("fork ok.\n");
  800718:	00000517          	auipc	a0,0x0
  80071c:	41050513          	addi	a0,a0,1040 # 800b28 <error_string+0xf8>
  800720:	983ff0ef          	jal	ra,8000a2 <cprintf>
  800724:	4455                	li	s0,21

    for (i = 0; i < total; i ++) {
        if (wait() != 0) {
  800726:	a29ff0ef          	jal	ra,80014e <wait>
  80072a:	e10d                	bnez	a0,80074c <main+0x6a>
    for (i = 0; i < total; i ++) {
  80072c:	347d                	addiw	s0,s0,-1
  80072e:	fc65                	bnez	s0,800726 <main+0x44>
            cprintf("wait failed.\n");
            goto failed;
        }
    }

    cprintf("matrix pass.\n");
  800730:	00000517          	auipc	a0,0x0
  800734:	41850513          	addi	a0,a0,1048 # 800b48 <error_string+0x118>
  800738:	96bff0ef          	jal	ra,8000a2 <cprintf>
        if (pids[i] > 0) {
            kill(pids[i]);
        }
    }
    panic("FAIL: T.T\n");
}
  80073c:	60aa                	ld	ra,136(sp)
  80073e:	640a                	ld	s0,128(sp)
  800740:	74e6                	ld	s1,120(sp)
  800742:	7946                	ld	s2,112(sp)
  800744:	79a6                	ld	s3,104(sp)
  800746:	4501                	li	a0,0
  800748:	6149                	addi	sp,sp,144
  80074a:	8082                	ret
            cprintf("wait failed.\n");
  80074c:	00000517          	auipc	a0,0x0
  800750:	3ec50513          	addi	a0,a0,1004 # 800b38 <error_string+0x108>
  800754:	94fff0ef          	jal	ra,8000a2 <cprintf>
            goto failed;
  800758:	08e0                	addi	s0,sp,92
        if (pids[i] > 0) {
  80075a:	0009a503          	lw	a0,0(s3)
  80075e:	00a05463          	blez	a0,800766 <main+0x84>
            kill(pids[i]);
  800762:	9f5ff0ef          	jal	ra,800156 <kill>
    for (i = 0; i < total; i ++) {
  800766:	0991                	addi	s3,s3,4
  800768:	fe8999e3          	bne	s3,s0,80075a <main+0x78>
    panic("FAIL: T.T\n");
  80076c:	00000617          	auipc	a2,0x0
  800770:	3ec60613          	addi	a2,a2,1004 # 800b58 <error_string+0x128>
  800774:	05200593          	li	a1,82
  800778:	00000517          	auipc	a0,0x0
  80077c:	3f050513          	addi	a0,a0,1008 # 800b68 <error_string+0x138>
  800780:	8a7ff0ef          	jal	ra,800026 <__panic>
            srand(i * i);
  800784:	0284053b          	mulw	a0,s0,s0
  800788:	dffff0ef          	jal	ra,800586 <srand>
            int times = (((unsigned int)rand()) % total);
  80078c:	dc9ff0ef          	jal	ra,800554 <rand>
  800790:	47d5                	li	a5,21
  800792:	02f577bb          	remuw	a5,a0,a5
            work(times);
  800796:	06400513          	li	a0,100
            times = (times * times + 10) * 100;
  80079a:	02f787bb          	mulw	a5,a5,a5
  80079e:	27a9                	addiw	a5,a5,10
            work(times);
  8007a0:	02f5053b          	mulw	a0,a0,a5
  8007a4:	e1fff0ef          	jal	ra,8005c2 <work>

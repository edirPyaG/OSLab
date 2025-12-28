
obj/__user_forktree.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0c2000ef          	jal	ra,8000e2 <umain>
1:  j 1b
  800024:	a001                	j	800024 <_start+0x4>

0000000000800026 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
  800026:	1141                	addi	sp,sp,-16
  800028:	e022                	sd	s0,0(sp)
  80002a:	e406                	sd	ra,8(sp)
  80002c:	842e                	mv	s0,a1
    sys_putc(c);
  80002e:	092000ef          	jal	ra,8000c0 <sys_putc>
    (*cnt) ++;
  800032:	401c                	lw	a5,0(s0)
}
  800034:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
  800036:	2785                	addiw	a5,a5,1
  800038:	c01c                	sw	a5,0(s0)
}
  80003a:	6402                	ld	s0,0(sp)
  80003c:	0141                	addi	sp,sp,16
  80003e:	8082                	ret

0000000000800040 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
  800040:	711d                	addi	sp,sp,-96
    va_list ap;

    va_start(ap, fmt);
  800042:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
  800046:	8e2a                	mv	t3,a0
  800048:	f42e                	sd	a1,40(sp)
  80004a:	f832                	sd	a2,48(sp)
  80004c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80004e:	00000517          	auipc	a0,0x0
  800052:	fd850513          	addi	a0,a0,-40 # 800026 <cputch>
  800056:	004c                	addi	a1,sp,4
  800058:	869a                	mv	a3,t1
  80005a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
  80005c:	ec06                	sd	ra,24(sp)
  80005e:	e0ba                	sd	a4,64(sp)
  800060:	e4be                	sd	a5,72(sp)
  800062:	e8c2                	sd	a6,80(sp)
  800064:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  800066:	e41a                	sd	t1,8(sp)
    int cnt = 0;
  800068:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
  80006a:	10a000ef          	jal	ra,800174 <vprintfmt>
    int cnt = vcprintf(fmt, ap);
    va_end(ap);

    return cnt;
}
  80006e:	60e2                	ld	ra,24(sp)
  800070:	4512                	lw	a0,4(sp)
  800072:	6125                	addi	sp,sp,96
  800074:	8082                	ret

0000000000800076 <syscall>:
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
  800076:	7175                	addi	sp,sp,-144
  800078:	f8ba                	sd	a4,112(sp)
    va_list ap;
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
  80007a:	e0ba                	sd	a4,64(sp)
  80007c:	0118                	addi	a4,sp,128
syscall(int64_t num, ...) {
  80007e:	e42a                	sd	a0,8(sp)
  800080:	ecae                	sd	a1,88(sp)
  800082:	f0b2                	sd	a2,96(sp)
  800084:	f4b6                	sd	a3,104(sp)
  800086:	fcbe                	sd	a5,120(sp)
  800088:	e142                	sd	a6,128(sp)
  80008a:	e546                	sd	a7,136(sp)
        a[i] = va_arg(ap, uint64_t);
  80008c:	f42e                	sd	a1,40(sp)
  80008e:	f832                	sd	a2,48(sp)
  800090:	fc36                	sd	a3,56(sp)
  800092:	f03a                	sd	a4,32(sp)
  800094:	e4be                	sd	a5,72(sp)
    }
    va_end(ap);
    asm volatile (
  800096:	4522                	lw	a0,8(sp)
  800098:	55a2                	lw	a1,40(sp)
  80009a:	5642                	lw	a2,48(sp)
  80009c:	56e2                	lw	a3,56(sp)
  80009e:	4706                	lw	a4,64(sp)
  8000a0:	47a6                	lw	a5,72(sp)
  8000a2:	00000073          	ecall
  8000a6:	ce2a                	sw	a0,28(sp)
          "m" (a[3]),
          "m" (a[4])
        : "memory"
      );
    return ret;
}
  8000a8:	4572                	lw	a0,28(sp)
  8000aa:	6149                	addi	sp,sp,144
  8000ac:	8082                	ret

00000000008000ae <sys_exit>:

int
sys_exit(int64_t error_code) {
  8000ae:	85aa                	mv	a1,a0
    return syscall(SYS_exit, error_code);
  8000b0:	4505                	li	a0,1
  8000b2:	b7d1                	j	800076 <syscall>

00000000008000b4 <sys_fork>:
}

int
sys_fork(void) {
    return syscall(SYS_fork);
  8000b4:	4509                	li	a0,2
  8000b6:	b7c1                	j	800076 <syscall>

00000000008000b8 <sys_yield>:
    return syscall(SYS_wait, pid, store);
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  8000b8:	4529                	li	a0,10
  8000ba:	bf75                	j	800076 <syscall>

00000000008000bc <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000bc:	4549                	li	a0,18
  8000be:	bf65                	j	800076 <syscall>

00000000008000c0 <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000c0:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000c2:	4579                	li	a0,30
  8000c4:	bf4d                	j	800076 <syscall>

00000000008000c6 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000c6:	1141                	addi	sp,sp,-16
  8000c8:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000ca:	fe5ff0ef          	jal	ra,8000ae <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000ce:	00000517          	auipc	a0,0x0
  8000d2:	57250513          	addi	a0,a0,1394 # 800640 <main+0x1e>
  8000d6:	f6bff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000da:	a001                	j	8000da <exit+0x14>

00000000008000dc <fork>:
}

int
fork(void) {
    return sys_fork();
  8000dc:	bfe1                	j	8000b4 <sys_fork>

00000000008000de <yield>:
    return sys_wait(pid, store);
}

void
yield(void) {
    sys_yield();
  8000de:	bfe9                	j	8000b8 <sys_yield>

00000000008000e0 <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000e0:	bff1                	j	8000bc <sys_getpid>

00000000008000e2 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000e2:	1141                	addi	sp,sp,-16
  8000e4:	e406                	sd	ra,8(sp)
    int ret = main();
  8000e6:	53c000ef          	jal	ra,800622 <main>
    exit(ret);
  8000ea:	fddff0ef          	jal	ra,8000c6 <exit>

00000000008000ee <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000ee:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000f2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  8000f4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000f8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  8000fa:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  8000fe:	f022                	sd	s0,32(sp)
  800100:	ec26                	sd	s1,24(sp)
  800102:	e84a                	sd	s2,16(sp)
  800104:	f406                	sd	ra,40(sp)
  800106:	e44e                	sd	s3,8(sp)
  800108:	84aa                	mv	s1,a0
  80010a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  80010c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800110:	2a01                	sext.w	s4,s4
    if (num >= base) {
  800112:	03067e63          	bgeu	a2,a6,80014e <printnum+0x60>
  800116:	89be                	mv	s3,a5
        while (-- width > 0)
  800118:	00805763          	blez	s0,800126 <printnum+0x38>
  80011c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80011e:	85ca                	mv	a1,s2
  800120:	854e                	mv	a0,s3
  800122:	9482                	jalr	s1
        while (-- width > 0)
  800124:	fc65                	bnez	s0,80011c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800126:	1a02                	slli	s4,s4,0x20
  800128:	00000797          	auipc	a5,0x0
  80012c:	53078793          	addi	a5,a5,1328 # 800658 <main+0x36>
  800130:	020a5a13          	srli	s4,s4,0x20
  800134:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800136:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800138:	000a4503          	lbu	a0,0(s4)
}
  80013c:	70a2                	ld	ra,40(sp)
  80013e:	69a2                	ld	s3,8(sp)
  800140:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  800142:	85ca                	mv	a1,s2
  800144:	87a6                	mv	a5,s1
}
  800146:	6942                	ld	s2,16(sp)
  800148:	64e2                	ld	s1,24(sp)
  80014a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  80014c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80014e:	03065633          	divu	a2,a2,a6
  800152:	8722                	mv	a4,s0
  800154:	f9bff0ef          	jal	ra,8000ee <printnum>
  800158:	b7f9                	j	800126 <printnum+0x38>

000000000080015a <sprintputch>:
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
    b->cnt ++;
  80015a:	499c                	lw	a5,16(a1)
    if (b->buf < b->ebuf) {
  80015c:	6198                	ld	a4,0(a1)
  80015e:	6594                	ld	a3,8(a1)
    b->cnt ++;
  800160:	2785                	addiw	a5,a5,1
  800162:	c99c                	sw	a5,16(a1)
    if (b->buf < b->ebuf) {
  800164:	00d77763          	bgeu	a4,a3,800172 <sprintputch+0x18>
        *b->buf ++ = ch;
  800168:	00170793          	addi	a5,a4,1
  80016c:	e19c                	sd	a5,0(a1)
  80016e:	00a70023          	sb	a0,0(a4)
    }
}
  800172:	8082                	ret

0000000000800174 <vprintfmt>:
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800174:	7119                	addi	sp,sp,-128
  800176:	f4a6                	sd	s1,104(sp)
  800178:	f0ca                	sd	s2,96(sp)
  80017a:	ecce                	sd	s3,88(sp)
  80017c:	e8d2                	sd	s4,80(sp)
  80017e:	e4d6                	sd	s5,72(sp)
  800180:	e0da                	sd	s6,64(sp)
  800182:	fc5e                	sd	s7,56(sp)
  800184:	f06a                	sd	s10,32(sp)
  800186:	fc86                	sd	ra,120(sp)
  800188:	f8a2                	sd	s0,112(sp)
  80018a:	f862                	sd	s8,48(sp)
  80018c:	f466                	sd	s9,40(sp)
  80018e:	ec6e                	sd	s11,24(sp)
  800190:	892a                	mv	s2,a0
  800192:	84ae                	mv	s1,a1
  800194:	8d32                	mv	s10,a2
  800196:	8a36                	mv	s4,a3
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800198:	02500993          	li	s3,37
        width = precision = -1;
  80019c:	5b7d                	li	s6,-1
  80019e:	00000a97          	auipc	s5,0x0
  8001a2:	4eea8a93          	addi	s5,s5,1262 # 80068c <main+0x6a>
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8001a6:	00000b97          	auipc	s7,0x0
  8001aa:	702b8b93          	addi	s7,s7,1794 # 8008a8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001ae:	000d4503          	lbu	a0,0(s10)
  8001b2:	001d0413          	addi	s0,s10,1
  8001b6:	01350a63          	beq	a0,s3,8001ca <vprintfmt+0x56>
            if (ch == '\0') {
  8001ba:	c121                	beqz	a0,8001fa <vprintfmt+0x86>
            putch(ch, putdat);
  8001bc:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001be:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001c0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001c2:	fff44503          	lbu	a0,-1(s0)
  8001c6:	ff351ae3          	bne	a0,s3,8001ba <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001ca:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001ce:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001d2:	4c81                	li	s9,0
  8001d4:	4881                	li	a7,0
        width = precision = -1;
  8001d6:	5c7d                	li	s8,-1
  8001d8:	5dfd                	li	s11,-1
  8001da:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001de:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001e0:	fdd6059b          	addiw	a1,a2,-35
  8001e4:	0ff5f593          	zext.b	a1,a1
  8001e8:	00140d13          	addi	s10,s0,1
  8001ec:	04b56263          	bltu	a0,a1,800230 <vprintfmt+0xbc>
  8001f0:	058a                	slli	a1,a1,0x2
  8001f2:	95d6                	add	a1,a1,s5
  8001f4:	4194                	lw	a3,0(a1)
  8001f6:	96d6                	add	a3,a3,s5
  8001f8:	8682                	jr	a3
}
  8001fa:	70e6                	ld	ra,120(sp)
  8001fc:	7446                	ld	s0,112(sp)
  8001fe:	74a6                	ld	s1,104(sp)
  800200:	7906                	ld	s2,96(sp)
  800202:	69e6                	ld	s3,88(sp)
  800204:	6a46                	ld	s4,80(sp)
  800206:	6aa6                	ld	s5,72(sp)
  800208:	6b06                	ld	s6,64(sp)
  80020a:	7be2                	ld	s7,56(sp)
  80020c:	7c42                	ld	s8,48(sp)
  80020e:	7ca2                	ld	s9,40(sp)
  800210:	7d02                	ld	s10,32(sp)
  800212:	6de2                	ld	s11,24(sp)
  800214:	6109                	addi	sp,sp,128
  800216:	8082                	ret
            padc = '0';
  800218:	87b2                	mv	a5,a2
            goto reswitch;
  80021a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80021e:	846a                	mv	s0,s10
  800220:	00140d13          	addi	s10,s0,1
  800224:	fdd6059b          	addiw	a1,a2,-35
  800228:	0ff5f593          	zext.b	a1,a1
  80022c:	fcb572e3          	bgeu	a0,a1,8001f0 <vprintfmt+0x7c>
            putch('%', putdat);
  800230:	85a6                	mv	a1,s1
  800232:	02500513          	li	a0,37
  800236:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800238:	fff44783          	lbu	a5,-1(s0)
  80023c:	8d22                	mv	s10,s0
  80023e:	f73788e3          	beq	a5,s3,8001ae <vprintfmt+0x3a>
  800242:	ffed4783          	lbu	a5,-2(s10)
  800246:	1d7d                	addi	s10,s10,-1
  800248:	ff379de3          	bne	a5,s3,800242 <vprintfmt+0xce>
  80024c:	b78d                	j	8001ae <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  80024e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800252:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800256:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  800258:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  80025c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800260:	02d86463          	bltu	a6,a3,800288 <vprintfmt+0x114>
                ch = *fmt;
  800264:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  800268:	002c169b          	slliw	a3,s8,0x2
  80026c:	0186873b          	addw	a4,a3,s8
  800270:	0017171b          	slliw	a4,a4,0x1
  800274:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  800276:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  80027a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80027c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800280:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800284:	fed870e3          	bgeu	a6,a3,800264 <vprintfmt+0xf0>
            if (width < 0)
  800288:	f40ddce3          	bgez	s11,8001e0 <vprintfmt+0x6c>
                width = precision, precision = -1;
  80028c:	8de2                	mv	s11,s8
  80028e:	5c7d                	li	s8,-1
  800290:	bf81                	j	8001e0 <vprintfmt+0x6c>
            if (width < 0)
  800292:	fffdc693          	not	a3,s11
  800296:	96fd                	srai	a3,a3,0x3f
  800298:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  80029c:	00144603          	lbu	a2,1(s0)
  8002a0:	2d81                	sext.w	s11,s11
  8002a2:	846a                	mv	s0,s10
            goto reswitch;
  8002a4:	bf35                	j	8001e0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  8002a6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002aa:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002ae:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002b0:	846a                	mv	s0,s10
            goto process_precision;
  8002b2:	bfd9                	j	800288 <vprintfmt+0x114>
    if (lflag >= 2) {
  8002b4:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002b6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ba:	01174463          	blt	a4,a7,8002c2 <vprintfmt+0x14e>
    else if (lflag) {
  8002be:	1a088e63          	beqz	a7,80047a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002c2:	000a3603          	ld	a2,0(s4)
  8002c6:	46c1                	li	a3,16
  8002c8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002ca:	2781                	sext.w	a5,a5
  8002cc:	876e                	mv	a4,s11
  8002ce:	85a6                	mv	a1,s1
  8002d0:	854a                	mv	a0,s2
  8002d2:	e1dff0ef          	jal	ra,8000ee <printnum>
            break;
  8002d6:	bde1                	j	8001ae <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002d8:	000a2503          	lw	a0,0(s4)
  8002dc:	85a6                	mv	a1,s1
  8002de:	0a21                	addi	s4,s4,8
  8002e0:	9902                	jalr	s2
            break;
  8002e2:	b5f1                	j	8001ae <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002e4:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002e6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ea:	01174463          	blt	a4,a7,8002f2 <vprintfmt+0x17e>
    else if (lflag) {
  8002ee:	18088163          	beqz	a7,800470 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002f2:	000a3603          	ld	a2,0(s4)
  8002f6:	46a9                	li	a3,10
  8002f8:	8a2e                	mv	s4,a1
  8002fa:	bfc1                	j	8002ca <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002fc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  800300:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800302:	846a                	mv	s0,s10
            goto reswitch;
  800304:	bdf1                	j	8001e0 <vprintfmt+0x6c>
            putch(ch, putdat);
  800306:	85a6                	mv	a1,s1
  800308:	02500513          	li	a0,37
  80030c:	9902                	jalr	s2
            break;
  80030e:	b545                	j	8001ae <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800310:	00144603          	lbu	a2,1(s0)
            lflag ++;
  800314:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  800316:	846a                	mv	s0,s10
            goto reswitch;
  800318:	b5e1                	j	8001e0 <vprintfmt+0x6c>
    if (lflag >= 2) {
  80031a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80031c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800320:	01174463          	blt	a4,a7,800328 <vprintfmt+0x1b4>
    else if (lflag) {
  800324:	14088163          	beqz	a7,800466 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800328:	000a3603          	ld	a2,0(s4)
  80032c:	46a1                	li	a3,8
  80032e:	8a2e                	mv	s4,a1
  800330:	bf69                	j	8002ca <vprintfmt+0x156>
            putch('0', putdat);
  800332:	03000513          	li	a0,48
  800336:	85a6                	mv	a1,s1
  800338:	e03e                	sd	a5,0(sp)
  80033a:	9902                	jalr	s2
            putch('x', putdat);
  80033c:	85a6                	mv	a1,s1
  80033e:	07800513          	li	a0,120
  800342:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800344:	0a21                	addi	s4,s4,8
            goto number;
  800346:	6782                	ld	a5,0(sp)
  800348:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80034a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  80034e:	bfb5                	j	8002ca <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800350:	000a3403          	ld	s0,0(s4)
  800354:	008a0713          	addi	a4,s4,8
  800358:	e03a                	sd	a4,0(sp)
  80035a:	14040263          	beqz	s0,80049e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  80035e:	0fb05763          	blez	s11,80044c <vprintfmt+0x2d8>
  800362:	02d00693          	li	a3,45
  800366:	0cd79163          	bne	a5,a3,800428 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80036a:	00044783          	lbu	a5,0(s0)
  80036e:	0007851b          	sext.w	a0,a5
  800372:	cf85                	beqz	a5,8003aa <vprintfmt+0x236>
  800374:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  800378:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80037c:	000c4563          	bltz	s8,800386 <vprintfmt+0x212>
  800380:	3c7d                	addiw	s8,s8,-1
  800382:	036c0263          	beq	s8,s6,8003a6 <vprintfmt+0x232>
                    putch('?', putdat);
  800386:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  800388:	0e0c8e63          	beqz	s9,800484 <vprintfmt+0x310>
  80038c:	3781                	addiw	a5,a5,-32
  80038e:	0ef47b63          	bgeu	s0,a5,800484 <vprintfmt+0x310>
                    putch('?', putdat);
  800392:	03f00513          	li	a0,63
  800396:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800398:	000a4783          	lbu	a5,0(s4)
  80039c:	3dfd                	addiw	s11,s11,-1
  80039e:	0a05                	addi	s4,s4,1
  8003a0:	0007851b          	sext.w	a0,a5
  8003a4:	ffe1                	bnez	a5,80037c <vprintfmt+0x208>
            for (; width > 0; width --) {
  8003a6:	01b05963          	blez	s11,8003b8 <vprintfmt+0x244>
  8003aa:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  8003ac:	85a6                	mv	a1,s1
  8003ae:	02000513          	li	a0,32
  8003b2:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003b4:	fe0d9be3          	bnez	s11,8003aa <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003b8:	6a02                	ld	s4,0(sp)
  8003ba:	bbd5                	j	8001ae <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003bc:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003be:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003c2:	01174463          	blt	a4,a7,8003ca <vprintfmt+0x256>
    else if (lflag) {
  8003c6:	08088d63          	beqz	a7,800460 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003ca:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003ce:	0a044d63          	bltz	s0,800488 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003d2:	8622                	mv	a2,s0
  8003d4:	8a66                	mv	s4,s9
  8003d6:	46a9                	li	a3,10
  8003d8:	bdcd                	j	8002ca <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003da:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003de:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003e0:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003e2:	41f7d69b          	sraiw	a3,a5,0x1f
  8003e6:	8fb5                	xor	a5,a5,a3
  8003e8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003ec:	02d74163          	blt	a4,a3,80040e <vprintfmt+0x29a>
  8003f0:	00369793          	slli	a5,a3,0x3
  8003f4:	97de                	add	a5,a5,s7
  8003f6:	639c                	ld	a5,0(a5)
  8003f8:	cb99                	beqz	a5,80040e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003fa:	86be                	mv	a3,a5
  8003fc:	00000617          	auipc	a2,0x0
  800400:	28c60613          	addi	a2,a2,652 # 800688 <main+0x66>
  800404:	85a6                	mv	a1,s1
  800406:	854a                	mv	a0,s2
  800408:	0ce000ef          	jal	ra,8004d6 <printfmt>
  80040c:	b34d                	j	8001ae <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  80040e:	00000617          	auipc	a2,0x0
  800412:	26a60613          	addi	a2,a2,618 # 800678 <main+0x56>
  800416:	85a6                	mv	a1,s1
  800418:	854a                	mv	a0,s2
  80041a:	0bc000ef          	jal	ra,8004d6 <printfmt>
  80041e:	bb41                	j	8001ae <vprintfmt+0x3a>
                p = "(null)";
  800420:	00000417          	auipc	s0,0x0
  800424:	25040413          	addi	s0,s0,592 # 800670 <main+0x4e>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800428:	85e2                	mv	a1,s8
  80042a:	8522                	mv	a0,s0
  80042c:	e43e                	sd	a5,8(sp)
  80042e:	128000ef          	jal	ra,800556 <strnlen>
  800432:	40ad8dbb          	subw	s11,s11,a0
  800436:	01b05b63          	blez	s11,80044c <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80043a:	67a2                	ld	a5,8(sp)
  80043c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800440:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800442:	85a6                	mv	a1,s1
  800444:	8552                	mv	a0,s4
  800446:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  800448:	fe0d9ce3          	bnez	s11,800440 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80044c:	00044783          	lbu	a5,0(s0)
  800450:	00140a13          	addi	s4,s0,1
  800454:	0007851b          	sext.w	a0,a5
  800458:	d3a5                	beqz	a5,8003b8 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  80045a:	05e00413          	li	s0,94
  80045e:	bf39                	j	80037c <vprintfmt+0x208>
        return va_arg(*ap, int);
  800460:	000a2403          	lw	s0,0(s4)
  800464:	b7ad                	j	8003ce <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  800466:	000a6603          	lwu	a2,0(s4)
  80046a:	46a1                	li	a3,8
  80046c:	8a2e                	mv	s4,a1
  80046e:	bdb1                	j	8002ca <vprintfmt+0x156>
  800470:	000a6603          	lwu	a2,0(s4)
  800474:	46a9                	li	a3,10
  800476:	8a2e                	mv	s4,a1
  800478:	bd89                	j	8002ca <vprintfmt+0x156>
  80047a:	000a6603          	lwu	a2,0(s4)
  80047e:	46c1                	li	a3,16
  800480:	8a2e                	mv	s4,a1
  800482:	b5a1                	j	8002ca <vprintfmt+0x156>
                    putch(ch, putdat);
  800484:	9902                	jalr	s2
  800486:	bf09                	j	800398 <vprintfmt+0x224>
                putch('-', putdat);
  800488:	85a6                	mv	a1,s1
  80048a:	02d00513          	li	a0,45
  80048e:	e03e                	sd	a5,0(sp)
  800490:	9902                	jalr	s2
                num = -(long long)num;
  800492:	6782                	ld	a5,0(sp)
  800494:	8a66                	mv	s4,s9
  800496:	40800633          	neg	a2,s0
  80049a:	46a9                	li	a3,10
  80049c:	b53d                	j	8002ca <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  80049e:	03b05163          	blez	s11,8004c0 <vprintfmt+0x34c>
  8004a2:	02d00693          	li	a3,45
  8004a6:	f6d79de3          	bne	a5,a3,800420 <vprintfmt+0x2ac>
                p = "(null)";
  8004aa:	00000417          	auipc	s0,0x0
  8004ae:	1c640413          	addi	s0,s0,454 # 800670 <main+0x4e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004b2:	02800793          	li	a5,40
  8004b6:	02800513          	li	a0,40
  8004ba:	00140a13          	addi	s4,s0,1
  8004be:	bd6d                	j	800378 <vprintfmt+0x204>
  8004c0:	00000a17          	auipc	s4,0x0
  8004c4:	1b1a0a13          	addi	s4,s4,433 # 800671 <main+0x4f>
  8004c8:	02800513          	li	a0,40
  8004cc:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004d0:	05e00413          	li	s0,94
  8004d4:	b565                	j	80037c <vprintfmt+0x208>

00000000008004d6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004d6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004d8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004dc:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004de:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004e0:	ec06                	sd	ra,24(sp)
  8004e2:	f83a                	sd	a4,48(sp)
  8004e4:	fc3e                	sd	a5,56(sp)
  8004e6:	e0c2                	sd	a6,64(sp)
  8004e8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004ea:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004ec:	c89ff0ef          	jal	ra,800174 <vprintfmt>
}
  8004f0:	60e2                	ld	ra,24(sp)
  8004f2:	6161                	addi	sp,sp,80
  8004f4:	8082                	ret

00000000008004f6 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
  8004f6:	711d                	addi	sp,sp,-96
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
    struct sprintbuf b = {str, str + size - 1, 0};
  8004f8:	15fd                	addi	a1,a1,-1
    va_start(ap, fmt);
  8004fa:	03810313          	addi	t1,sp,56
    struct sprintbuf b = {str, str + size - 1, 0};
  8004fe:	95aa                	add	a1,a1,a0
snprintf(char *str, size_t size, const char *fmt, ...) {
  800500:	f406                	sd	ra,40(sp)
  800502:	fc36                	sd	a3,56(sp)
  800504:	e0ba                	sd	a4,64(sp)
  800506:	e4be                	sd	a5,72(sp)
  800508:	e8c2                	sd	a6,80(sp)
  80050a:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
  80050c:	e01a                	sd	t1,0(sp)
    struct sprintbuf b = {str, str + size - 1, 0};
  80050e:	e42a                	sd	a0,8(sp)
  800510:	e82e                	sd	a1,16(sp)
  800512:	cc02                	sw	zero,24(sp)
    if (str == NULL || b.buf > b.ebuf) {
  800514:	c115                	beqz	a0,800538 <snprintf+0x42>
  800516:	02a5e163          	bltu	a1,a0,800538 <snprintf+0x42>
        return -E_INVAL;
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
  80051a:	00000517          	auipc	a0,0x0
  80051e:	c4050513          	addi	a0,a0,-960 # 80015a <sprintputch>
  800522:	869a                	mv	a3,t1
  800524:	002c                	addi	a1,sp,8
  800526:	c4fff0ef          	jal	ra,800174 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
  80052a:	67a2                	ld	a5,8(sp)
  80052c:	00078023          	sb	zero,0(a5)
    return b.cnt;
  800530:	4562                	lw	a0,24(sp)
}
  800532:	70a2                	ld	ra,40(sp)
  800534:	6125                	addi	sp,sp,96
  800536:	8082                	ret
        return -E_INVAL;
  800538:	5575                	li	a0,-3
  80053a:	bfe5                	j	800532 <snprintf+0x3c>

000000000080053c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
  80053c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
  800540:	872a                	mv	a4,a0
    size_t cnt = 0;
  800542:	4501                	li	a0,0
    while (*s ++ != '\0') {
  800544:	cb81                	beqz	a5,800554 <strlen+0x18>
        cnt ++;
  800546:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
  800548:	00a707b3          	add	a5,a4,a0
  80054c:	0007c783          	lbu	a5,0(a5)
  800550:	fbfd                	bnez	a5,800546 <strlen+0xa>
  800552:	8082                	ret
    }
    return cnt;
}
  800554:	8082                	ret

0000000000800556 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  800556:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  800558:	e589                	bnez	a1,800562 <strnlen+0xc>
  80055a:	a811                	j	80056e <strnlen+0x18>
        cnt ++;
  80055c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  80055e:	00f58863          	beq	a1,a5,80056e <strnlen+0x18>
  800562:	00f50733          	add	a4,a0,a5
  800566:	00074703          	lbu	a4,0(a4)
  80056a:	fb6d                	bnez	a4,80055c <strnlen+0x6>
  80056c:	85be                	mv	a1,a5
    }
    return cnt;
}
  80056e:	852e                	mv	a0,a1
  800570:	8082                	ret

0000000000800572 <forktree>:
        exit(0);
    }
}

void
forktree(const char *cur) {
  800572:	1101                	addi	sp,sp,-32
  800574:	ec06                	sd	ra,24(sp)
  800576:	e822                	sd	s0,16(sp)
  800578:	842a                	mv	s0,a0
    cprintf("%04x: I am '%s'\n", getpid(), cur);
  80057a:	b67ff0ef          	jal	ra,8000e0 <getpid>
  80057e:	85aa                	mv	a1,a0
  800580:	8622                	mv	a2,s0
  800582:	00000517          	auipc	a0,0x0
  800586:	3ee50513          	addi	a0,a0,1006 # 800970 <error_string+0xc8>
  80058a:	ab7ff0ef          	jal	ra,800040 <cprintf>

    forkchild(cur, '0');
  80058e:	03000593          	li	a1,48
  800592:	8522                	mv	a0,s0
  800594:	044000ef          	jal	ra,8005d8 <forkchild>
    if (strlen(cur) >= DEPTH)
  800598:	8522                	mv	a0,s0
  80059a:	fa3ff0ef          	jal	ra,80053c <strlen>
  80059e:	478d                	li	a5,3
  8005a0:	00a7f663          	bgeu	a5,a0,8005ac <forktree+0x3a>
    forkchild(cur, '1');
}
  8005a4:	60e2                	ld	ra,24(sp)
  8005a6:	6442                	ld	s0,16(sp)
  8005a8:	6105                	addi	sp,sp,32
  8005aa:	8082                	ret
    snprintf(nxt, DEPTH + 1, "%s%c", cur, branch);
  8005ac:	03100713          	li	a4,49
  8005b0:	86a2                	mv	a3,s0
  8005b2:	00000617          	auipc	a2,0x0
  8005b6:	3d660613          	addi	a2,a2,982 # 800988 <error_string+0xe0>
  8005ba:	4595                	li	a1,5
  8005bc:	0028                	addi	a0,sp,8
  8005be:	f39ff0ef          	jal	ra,8004f6 <snprintf>
    if (fork() == 0) {
  8005c2:	b1bff0ef          	jal	ra,8000dc <fork>
  8005c6:	fd79                	bnez	a0,8005a4 <forktree+0x32>
        forktree(nxt);
  8005c8:	0028                	addi	a0,sp,8
  8005ca:	fa9ff0ef          	jal	ra,800572 <forktree>
        yield();
  8005ce:	b11ff0ef          	jal	ra,8000de <yield>
        exit(0);
  8005d2:	4501                	li	a0,0
  8005d4:	af3ff0ef          	jal	ra,8000c6 <exit>

00000000008005d8 <forkchild>:
forkchild(const char *cur, char branch) {
  8005d8:	7179                	addi	sp,sp,-48
  8005da:	f022                	sd	s0,32(sp)
  8005dc:	ec26                	sd	s1,24(sp)
  8005de:	f406                	sd	ra,40(sp)
  8005e0:	842a                	mv	s0,a0
  8005e2:	84ae                	mv	s1,a1
    if (strlen(cur) >= DEPTH)
  8005e4:	f59ff0ef          	jal	ra,80053c <strlen>
  8005e8:	478d                	li	a5,3
  8005ea:	00a7f763          	bgeu	a5,a0,8005f8 <forkchild+0x20>
}
  8005ee:	70a2                	ld	ra,40(sp)
  8005f0:	7402                	ld	s0,32(sp)
  8005f2:	64e2                	ld	s1,24(sp)
  8005f4:	6145                	addi	sp,sp,48
  8005f6:	8082                	ret
    snprintf(nxt, DEPTH + 1, "%s%c", cur, branch);
  8005f8:	8726                	mv	a4,s1
  8005fa:	86a2                	mv	a3,s0
  8005fc:	00000617          	auipc	a2,0x0
  800600:	38c60613          	addi	a2,a2,908 # 800988 <error_string+0xe0>
  800604:	4595                	li	a1,5
  800606:	0028                	addi	a0,sp,8
  800608:	eefff0ef          	jal	ra,8004f6 <snprintf>
    if (fork() == 0) {
  80060c:	ad1ff0ef          	jal	ra,8000dc <fork>
  800610:	fd79                	bnez	a0,8005ee <forkchild+0x16>
        forktree(nxt);
  800612:	0028                	addi	a0,sp,8
  800614:	f5fff0ef          	jal	ra,800572 <forktree>
        yield();
  800618:	ac7ff0ef          	jal	ra,8000de <yield>
        exit(0);
  80061c:	4501                	li	a0,0
  80061e:	aa9ff0ef          	jal	ra,8000c6 <exit>

0000000000800622 <main>:

int
main(void) {
  800622:	1141                	addi	sp,sp,-16
    forktree("");
  800624:	00000517          	auipc	a0,0x0
  800628:	35c50513          	addi	a0,a0,860 # 800980 <error_string+0xd8>
main(void) {
  80062c:	e406                	sd	ra,8(sp)
    forktree("");
  80062e:	f45ff0ef          	jal	ra,800572 <forktree>
    return 0;
}
  800632:	60a2                	ld	ra,8(sp)
  800634:	4501                	li	a0,0
  800636:	0141                	addi	sp,sp,16
  800638:	8082                	ret


obj/__user_yield.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0bc000ef          	jal	ra,8000dc <umain>
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
  80002e:	08e000ef          	jal	ra,8000bc <sys_putc>
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
  80006a:	0ea000ef          	jal	ra,800154 <vprintfmt>
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

00000000008000b4 <sys_yield>:
    return syscall(SYS_wait, pid, store);
}

int
sys_yield(void) {
    return syscall(SYS_yield);
  8000b4:	4529                	li	a0,10
  8000b6:	b7c1                	j	800076 <syscall>

00000000008000b8 <sys_getpid>:
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
  8000b8:	4549                	li	a0,18
  8000ba:	bf75                	j	800076 <syscall>

00000000008000bc <sys_putc>:
}

int
sys_putc(int64_t c) {
  8000bc:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000be:	4579                	li	a0,30
  8000c0:	bf5d                	j	800076 <syscall>

00000000008000c2 <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000c2:	1141                	addi	sp,sp,-16
  8000c4:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000c6:	fe9ff0ef          	jal	ra,8000ae <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000ca:	00000517          	auipc	a0,0x0
  8000ce:	49650513          	addi	a0,a0,1174 # 800560 <main+0x6e>
  8000d2:	f6fff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000d6:	a001                	j	8000d6 <exit+0x14>

00000000008000d8 <yield>:
    return sys_wait(pid, store);
}

void
yield(void) {
    sys_yield();
  8000d8:	bff1                	j	8000b4 <sys_yield>

00000000008000da <getpid>:
    return sys_kill(pid);
}

int
getpid(void) {
    return sys_getpid();
  8000da:	bff9                	j	8000b8 <sys_getpid>

00000000008000dc <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000dc:	1141                	addi	sp,sp,-16
  8000de:	e406                	sd	ra,8(sp)
    int ret = main();
  8000e0:	412000ef          	jal	ra,8004f2 <main>
    exit(ret);
  8000e4:	fdfff0ef          	jal	ra,8000c2 <exit>

00000000008000e8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000e8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000ec:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  8000ee:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000f2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  8000f4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  8000f8:	f022                	sd	s0,32(sp)
  8000fa:	ec26                	sd	s1,24(sp)
  8000fc:	e84a                	sd	s2,16(sp)
  8000fe:	f406                	sd	ra,40(sp)
  800100:	e44e                	sd	s3,8(sp)
  800102:	84aa                	mv	s1,a0
  800104:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  800106:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  80010a:	2a01                	sext.w	s4,s4
    if (num >= base) {
  80010c:	03067e63          	bgeu	a2,a6,800148 <printnum+0x60>
  800110:	89be                	mv	s3,a5
        while (-- width > 0)
  800112:	00805763          	blez	s0,800120 <printnum+0x38>
  800116:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  800118:	85ca                	mv	a1,s2
  80011a:	854e                	mv	a0,s3
  80011c:	9482                	jalr	s1
        while (-- width > 0)
  80011e:	fc65                	bnez	s0,800116 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800120:	1a02                	slli	s4,s4,0x20
  800122:	00000797          	auipc	a5,0x0
  800126:	45678793          	addi	a5,a5,1110 # 800578 <main+0x86>
  80012a:	020a5a13          	srli	s4,s4,0x20
  80012e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800130:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800132:	000a4503          	lbu	a0,0(s4)
}
  800136:	70a2                	ld	ra,40(sp)
  800138:	69a2                	ld	s3,8(sp)
  80013a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  80013c:	85ca                	mv	a1,s2
  80013e:	87a6                	mv	a5,s1
}
  800140:	6942                	ld	s2,16(sp)
  800142:	64e2                	ld	s1,24(sp)
  800144:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  800146:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  800148:	03065633          	divu	a2,a2,a6
  80014c:	8722                	mv	a4,s0
  80014e:	f9bff0ef          	jal	ra,8000e8 <printnum>
  800152:	b7f9                	j	800120 <printnum+0x38>

0000000000800154 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800154:	7119                	addi	sp,sp,-128
  800156:	f4a6                	sd	s1,104(sp)
  800158:	f0ca                	sd	s2,96(sp)
  80015a:	ecce                	sd	s3,88(sp)
  80015c:	e8d2                	sd	s4,80(sp)
  80015e:	e4d6                	sd	s5,72(sp)
  800160:	e0da                	sd	s6,64(sp)
  800162:	fc5e                	sd	s7,56(sp)
  800164:	f06a                	sd	s10,32(sp)
  800166:	fc86                	sd	ra,120(sp)
  800168:	f8a2                	sd	s0,112(sp)
  80016a:	f862                	sd	s8,48(sp)
  80016c:	f466                	sd	s9,40(sp)
  80016e:	ec6e                	sd	s11,24(sp)
  800170:	892a                	mv	s2,a0
  800172:	84ae                	mv	s1,a1
  800174:	8d32                	mv	s10,a2
  800176:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800178:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  80017c:	5b7d                	li	s6,-1
  80017e:	00000a97          	auipc	s5,0x0
  800182:	42ea8a93          	addi	s5,s5,1070 # 8005ac <main+0xba>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800186:	00000b97          	auipc	s7,0x0
  80018a:	642b8b93          	addi	s7,s7,1602 # 8007c8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80018e:	000d4503          	lbu	a0,0(s10)
  800192:	001d0413          	addi	s0,s10,1
  800196:	01350a63          	beq	a0,s3,8001aa <vprintfmt+0x56>
            if (ch == '\0') {
  80019a:	c121                	beqz	a0,8001da <vprintfmt+0x86>
            putch(ch, putdat);
  80019c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80019e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001a0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001a2:	fff44503          	lbu	a0,-1(s0)
  8001a6:	ff351ae3          	bne	a0,s3,80019a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  8001aa:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001ae:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001b2:	4c81                	li	s9,0
  8001b4:	4881                	li	a7,0
        width = precision = -1;
  8001b6:	5c7d                	li	s8,-1
  8001b8:	5dfd                	li	s11,-1
  8001ba:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001be:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001c0:	fdd6059b          	addiw	a1,a2,-35
  8001c4:	0ff5f593          	zext.b	a1,a1
  8001c8:	00140d13          	addi	s10,s0,1
  8001cc:	04b56263          	bltu	a0,a1,800210 <vprintfmt+0xbc>
  8001d0:	058a                	slli	a1,a1,0x2
  8001d2:	95d6                	add	a1,a1,s5
  8001d4:	4194                	lw	a3,0(a1)
  8001d6:	96d6                	add	a3,a3,s5
  8001d8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001da:	70e6                	ld	ra,120(sp)
  8001dc:	7446                	ld	s0,112(sp)
  8001de:	74a6                	ld	s1,104(sp)
  8001e0:	7906                	ld	s2,96(sp)
  8001e2:	69e6                	ld	s3,88(sp)
  8001e4:	6a46                	ld	s4,80(sp)
  8001e6:	6aa6                	ld	s5,72(sp)
  8001e8:	6b06                	ld	s6,64(sp)
  8001ea:	7be2                	ld	s7,56(sp)
  8001ec:	7c42                	ld	s8,48(sp)
  8001ee:	7ca2                	ld	s9,40(sp)
  8001f0:	7d02                	ld	s10,32(sp)
  8001f2:	6de2                	ld	s11,24(sp)
  8001f4:	6109                	addi	sp,sp,128
  8001f6:	8082                	ret
            padc = '0';
  8001f8:	87b2                	mv	a5,a2
            goto reswitch;
  8001fa:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  8001fe:	846a                	mv	s0,s10
  800200:	00140d13          	addi	s10,s0,1
  800204:	fdd6059b          	addiw	a1,a2,-35
  800208:	0ff5f593          	zext.b	a1,a1
  80020c:	fcb572e3          	bgeu	a0,a1,8001d0 <vprintfmt+0x7c>
            putch('%', putdat);
  800210:	85a6                	mv	a1,s1
  800212:	02500513          	li	a0,37
  800216:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  800218:	fff44783          	lbu	a5,-1(s0)
  80021c:	8d22                	mv	s10,s0
  80021e:	f73788e3          	beq	a5,s3,80018e <vprintfmt+0x3a>
  800222:	ffed4783          	lbu	a5,-2(s10)
  800226:	1d7d                	addi	s10,s10,-1
  800228:	ff379de3          	bne	a5,s3,800222 <vprintfmt+0xce>
  80022c:	b78d                	j	80018e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  80022e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800232:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800236:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  800238:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  80023c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800240:	02d86463          	bltu	a6,a3,800268 <vprintfmt+0x114>
                ch = *fmt;
  800244:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  800248:	002c169b          	slliw	a3,s8,0x2
  80024c:	0186873b          	addw	a4,a3,s8
  800250:	0017171b          	slliw	a4,a4,0x1
  800254:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  800256:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  80025a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  80025c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800260:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800264:	fed870e3          	bgeu	a6,a3,800244 <vprintfmt+0xf0>
            if (width < 0)
  800268:	f40ddce3          	bgez	s11,8001c0 <vprintfmt+0x6c>
                width = precision, precision = -1;
  80026c:	8de2                	mv	s11,s8
  80026e:	5c7d                	li	s8,-1
  800270:	bf81                	j	8001c0 <vprintfmt+0x6c>
            if (width < 0)
  800272:	fffdc693          	not	a3,s11
  800276:	96fd                	srai	a3,a3,0x3f
  800278:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  80027c:	00144603          	lbu	a2,1(s0)
  800280:	2d81                	sext.w	s11,s11
  800282:	846a                	mv	s0,s10
            goto reswitch;
  800284:	bf35                	j	8001c0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  800286:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  80028a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  80028e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  800290:	846a                	mv	s0,s10
            goto process_precision;
  800292:	bfd9                	j	800268 <vprintfmt+0x114>
    if (lflag >= 2) {
  800294:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800296:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80029a:	01174463          	blt	a4,a7,8002a2 <vprintfmt+0x14e>
    else if (lflag) {
  80029e:	1a088e63          	beqz	a7,80045a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002a2:	000a3603          	ld	a2,0(s4)
  8002a6:	46c1                	li	a3,16
  8002a8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  8002aa:	2781                	sext.w	a5,a5
  8002ac:	876e                	mv	a4,s11
  8002ae:	85a6                	mv	a1,s1
  8002b0:	854a                	mv	a0,s2
  8002b2:	e37ff0ef          	jal	ra,8000e8 <printnum>
            break;
  8002b6:	bde1                	j	80018e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002b8:	000a2503          	lw	a0,0(s4)
  8002bc:	85a6                	mv	a1,s1
  8002be:	0a21                	addi	s4,s4,8
  8002c0:	9902                	jalr	s2
            break;
  8002c2:	b5f1                	j	80018e <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002c4:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002c6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002ca:	01174463          	blt	a4,a7,8002d2 <vprintfmt+0x17e>
    else if (lflag) {
  8002ce:	18088163          	beqz	a7,800450 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002d2:	000a3603          	ld	a2,0(s4)
  8002d6:	46a9                	li	a3,10
  8002d8:	8a2e                	mv	s4,a1
  8002da:	bfc1                	j	8002aa <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002dc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  8002e0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002e2:	846a                	mv	s0,s10
            goto reswitch;
  8002e4:	bdf1                	j	8001c0 <vprintfmt+0x6c>
            putch(ch, putdat);
  8002e6:	85a6                	mv	a1,s1
  8002e8:	02500513          	li	a0,37
  8002ec:	9902                	jalr	s2
            break;
  8002ee:	b545                	j	80018e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  8002f0:	00144603          	lbu	a2,1(s0)
            lflag ++;
  8002f4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002f6:	846a                	mv	s0,s10
            goto reswitch;
  8002f8:	b5e1                	j	8001c0 <vprintfmt+0x6c>
    if (lflag >= 2) {
  8002fa:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002fc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800300:	01174463          	blt	a4,a7,800308 <vprintfmt+0x1b4>
    else if (lflag) {
  800304:	14088163          	beqz	a7,800446 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  800308:	000a3603          	ld	a2,0(s4)
  80030c:	46a1                	li	a3,8
  80030e:	8a2e                	mv	s4,a1
  800310:	bf69                	j	8002aa <vprintfmt+0x156>
            putch('0', putdat);
  800312:	03000513          	li	a0,48
  800316:	85a6                	mv	a1,s1
  800318:	e03e                	sd	a5,0(sp)
  80031a:	9902                	jalr	s2
            putch('x', putdat);
  80031c:	85a6                	mv	a1,s1
  80031e:	07800513          	li	a0,120
  800322:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800324:	0a21                	addi	s4,s4,8
            goto number;
  800326:	6782                	ld	a5,0(sp)
  800328:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80032a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  80032e:	bfb5                	j	8002aa <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800330:	000a3403          	ld	s0,0(s4)
  800334:	008a0713          	addi	a4,s4,8
  800338:	e03a                	sd	a4,0(sp)
  80033a:	14040263          	beqz	s0,80047e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  80033e:	0fb05763          	blez	s11,80042c <vprintfmt+0x2d8>
  800342:	02d00693          	li	a3,45
  800346:	0cd79163          	bne	a5,a3,800408 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80034a:	00044783          	lbu	a5,0(s0)
  80034e:	0007851b          	sext.w	a0,a5
  800352:	cf85                	beqz	a5,80038a <vprintfmt+0x236>
  800354:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  800358:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80035c:	000c4563          	bltz	s8,800366 <vprintfmt+0x212>
  800360:	3c7d                	addiw	s8,s8,-1
  800362:	036c0263          	beq	s8,s6,800386 <vprintfmt+0x232>
                    putch('?', putdat);
  800366:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  800368:	0e0c8e63          	beqz	s9,800464 <vprintfmt+0x310>
  80036c:	3781                	addiw	a5,a5,-32
  80036e:	0ef47b63          	bgeu	s0,a5,800464 <vprintfmt+0x310>
                    putch('?', putdat);
  800372:	03f00513          	li	a0,63
  800376:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800378:	000a4783          	lbu	a5,0(s4)
  80037c:	3dfd                	addiw	s11,s11,-1
  80037e:	0a05                	addi	s4,s4,1
  800380:	0007851b          	sext.w	a0,a5
  800384:	ffe1                	bnez	a5,80035c <vprintfmt+0x208>
            for (; width > 0; width --) {
  800386:	01b05963          	blez	s11,800398 <vprintfmt+0x244>
  80038a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  80038c:	85a6                	mv	a1,s1
  80038e:	02000513          	li	a0,32
  800392:	9902                	jalr	s2
            for (; width > 0; width --) {
  800394:	fe0d9be3          	bnez	s11,80038a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  800398:	6a02                	ld	s4,0(sp)
  80039a:	bbd5                	j	80018e <vprintfmt+0x3a>
    if (lflag >= 2) {
  80039c:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80039e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003a2:	01174463          	blt	a4,a7,8003aa <vprintfmt+0x256>
    else if (lflag) {
  8003a6:	08088d63          	beqz	a7,800440 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  8003aa:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003ae:	0a044d63          	bltz	s0,800468 <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003b2:	8622                	mv	a2,s0
  8003b4:	8a66                	mv	s4,s9
  8003b6:	46a9                	li	a3,10
  8003b8:	bdcd                	j	8002aa <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003ba:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003be:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003c0:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003c2:	41f7d69b          	sraiw	a3,a5,0x1f
  8003c6:	8fb5                	xor	a5,a5,a3
  8003c8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003cc:	02d74163          	blt	a4,a3,8003ee <vprintfmt+0x29a>
  8003d0:	00369793          	slli	a5,a3,0x3
  8003d4:	97de                	add	a5,a5,s7
  8003d6:	639c                	ld	a5,0(a5)
  8003d8:	cb99                	beqz	a5,8003ee <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003da:	86be                	mv	a3,a5
  8003dc:	00000617          	auipc	a2,0x0
  8003e0:	1cc60613          	addi	a2,a2,460 # 8005a8 <main+0xb6>
  8003e4:	85a6                	mv	a1,s1
  8003e6:	854a                	mv	a0,s2
  8003e8:	0ce000ef          	jal	ra,8004b6 <printfmt>
  8003ec:	b34d                	j	80018e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  8003ee:	00000617          	auipc	a2,0x0
  8003f2:	1aa60613          	addi	a2,a2,426 # 800598 <main+0xa6>
  8003f6:	85a6                	mv	a1,s1
  8003f8:	854a                	mv	a0,s2
  8003fa:	0bc000ef          	jal	ra,8004b6 <printfmt>
  8003fe:	bb41                	j	80018e <vprintfmt+0x3a>
                p = "(null)";
  800400:	00000417          	auipc	s0,0x0
  800404:	19040413          	addi	s0,s0,400 # 800590 <main+0x9e>
                for (width -= strnlen(p, precision); width > 0; width --) {
  800408:	85e2                	mv	a1,s8
  80040a:	8522                	mv	a0,s0
  80040c:	e43e                	sd	a5,8(sp)
  80040e:	0c8000ef          	jal	ra,8004d6 <strnlen>
  800412:	40ad8dbb          	subw	s11,s11,a0
  800416:	01b05b63          	blez	s11,80042c <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80041a:	67a2                	ld	a5,8(sp)
  80041c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800420:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800422:	85a6                	mv	a1,s1
  800424:	8552                	mv	a0,s4
  800426:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  800428:	fe0d9ce3          	bnez	s11,800420 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80042c:	00044783          	lbu	a5,0(s0)
  800430:	00140a13          	addi	s4,s0,1
  800434:	0007851b          	sext.w	a0,a5
  800438:	d3a5                	beqz	a5,800398 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  80043a:	05e00413          	li	s0,94
  80043e:	bf39                	j	80035c <vprintfmt+0x208>
        return va_arg(*ap, int);
  800440:	000a2403          	lw	s0,0(s4)
  800444:	b7ad                	j	8003ae <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  800446:	000a6603          	lwu	a2,0(s4)
  80044a:	46a1                	li	a3,8
  80044c:	8a2e                	mv	s4,a1
  80044e:	bdb1                	j	8002aa <vprintfmt+0x156>
  800450:	000a6603          	lwu	a2,0(s4)
  800454:	46a9                	li	a3,10
  800456:	8a2e                	mv	s4,a1
  800458:	bd89                	j	8002aa <vprintfmt+0x156>
  80045a:	000a6603          	lwu	a2,0(s4)
  80045e:	46c1                	li	a3,16
  800460:	8a2e                	mv	s4,a1
  800462:	b5a1                	j	8002aa <vprintfmt+0x156>
                    putch(ch, putdat);
  800464:	9902                	jalr	s2
  800466:	bf09                	j	800378 <vprintfmt+0x224>
                putch('-', putdat);
  800468:	85a6                	mv	a1,s1
  80046a:	02d00513          	li	a0,45
  80046e:	e03e                	sd	a5,0(sp)
  800470:	9902                	jalr	s2
                num = -(long long)num;
  800472:	6782                	ld	a5,0(sp)
  800474:	8a66                	mv	s4,s9
  800476:	40800633          	neg	a2,s0
  80047a:	46a9                	li	a3,10
  80047c:	b53d                	j	8002aa <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  80047e:	03b05163          	blez	s11,8004a0 <vprintfmt+0x34c>
  800482:	02d00693          	li	a3,45
  800486:	f6d79de3          	bne	a5,a3,800400 <vprintfmt+0x2ac>
                p = "(null)";
  80048a:	00000417          	auipc	s0,0x0
  80048e:	10640413          	addi	s0,s0,262 # 800590 <main+0x9e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800492:	02800793          	li	a5,40
  800496:	02800513          	li	a0,40
  80049a:	00140a13          	addi	s4,s0,1
  80049e:	bd6d                	j	800358 <vprintfmt+0x204>
  8004a0:	00000a17          	auipc	s4,0x0
  8004a4:	0f1a0a13          	addi	s4,s4,241 # 800591 <main+0x9f>
  8004a8:	02800513          	li	a0,40
  8004ac:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004b0:	05e00413          	li	s0,94
  8004b4:	b565                	j	80035c <vprintfmt+0x208>

00000000008004b6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004b6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004b8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004bc:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004be:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004c0:	ec06                	sd	ra,24(sp)
  8004c2:	f83a                	sd	a4,48(sp)
  8004c4:	fc3e                	sd	a5,56(sp)
  8004c6:	e0c2                	sd	a6,64(sp)
  8004c8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004ca:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004cc:	c89ff0ef          	jal	ra,800154 <vprintfmt>
}
  8004d0:	60e2                	ld	ra,24(sp)
  8004d2:	6161                	addi	sp,sp,80
  8004d4:	8082                	ret

00000000008004d6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004d6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004d8:	e589                	bnez	a1,8004e2 <strnlen+0xc>
  8004da:	a811                	j	8004ee <strnlen+0x18>
        cnt ++;
  8004dc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004de:	00f58863          	beq	a1,a5,8004ee <strnlen+0x18>
  8004e2:	00f50733          	add	a4,a0,a5
  8004e6:	00074703          	lbu	a4,0(a4)
  8004ea:	fb6d                	bnez	a4,8004dc <strnlen+0x6>
  8004ec:	85be                	mv	a1,a5
    }
    return cnt;
}
  8004ee:	852e                	mv	a0,a1
  8004f0:	8082                	ret

00000000008004f2 <main>:
#include <ulib.h>
#include <stdio.h>

int
main(void) {
  8004f2:	1101                	addi	sp,sp,-32
  8004f4:	ec06                	sd	ra,24(sp)
  8004f6:	e822                	sd	s0,16(sp)
  8004f8:	e426                	sd	s1,8(sp)
  8004fa:	e04a                	sd	s2,0(sp)
    int i;
    cprintf("Hello, I am process %d.\n", getpid());
  8004fc:	bdfff0ef          	jal	ra,8000da <getpid>
  800500:	85aa                	mv	a1,a0
  800502:	00000517          	auipc	a0,0x0
  800506:	38e50513          	addi	a0,a0,910 # 800890 <error_string+0xc8>
  80050a:	b37ff0ef          	jal	ra,800040 <cprintf>
    for (i = 0; i < 5; i ++) {
  80050e:	4401                	li	s0,0
        yield();
        cprintf("Back in process %d, iteration %d.\n", getpid(), i);
  800510:	00000917          	auipc	s2,0x0
  800514:	3a090913          	addi	s2,s2,928 # 8008b0 <error_string+0xe8>
    for (i = 0; i < 5; i ++) {
  800518:	4495                	li	s1,5
        yield();
  80051a:	bbfff0ef          	jal	ra,8000d8 <yield>
        cprintf("Back in process %d, iteration %d.\n", getpid(), i);
  80051e:	bbdff0ef          	jal	ra,8000da <getpid>
  800522:	85aa                	mv	a1,a0
  800524:	8622                	mv	a2,s0
  800526:	854a                	mv	a0,s2
    for (i = 0; i < 5; i ++) {
  800528:	2405                	addiw	s0,s0,1
        cprintf("Back in process %d, iteration %d.\n", getpid(), i);
  80052a:	b17ff0ef          	jal	ra,800040 <cprintf>
    for (i = 0; i < 5; i ++) {
  80052e:	fe9416e3          	bne	s0,s1,80051a <main+0x28>
    }
    cprintf("All done in process %d.\n", getpid());
  800532:	ba9ff0ef          	jal	ra,8000da <getpid>
  800536:	85aa                	mv	a1,a0
  800538:	00000517          	auipc	a0,0x0
  80053c:	3a050513          	addi	a0,a0,928 # 8008d8 <error_string+0x110>
  800540:	b01ff0ef          	jal	ra,800040 <cprintf>
    cprintf("yield pass.\n");
  800544:	00000517          	auipc	a0,0x0
  800548:	3b450513          	addi	a0,a0,948 # 8008f8 <error_string+0x130>
  80054c:	af5ff0ef          	jal	ra,800040 <cprintf>
    return 0;
}
  800550:	60e2                	ld	ra,24(sp)
  800552:	6442                	ld	s0,16(sp)
  800554:	64a2                	ld	s1,8(sp)
  800556:	6902                	ld	s2,0(sp)
  800558:	4501                	li	a0,0
  80055a:	6105                	addi	sp,sp,32
  80055c:	8082                	ret

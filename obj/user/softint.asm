
obj/__user_softint.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	0b0000ef          	jal	ra,8000d0 <umain>
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
  80002e:	086000ef          	jal	ra,8000b4 <sys_putc>
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
  80006a:	0de000ef          	jal	ra,800148 <vprintfmt>
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

00000000008000b4 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  8000b4:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  8000b6:	4579                	li	a0,30
  8000b8:	bf7d                	j	800076 <syscall>

00000000008000ba <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  8000ba:	1141                	addi	sp,sp,-16
  8000bc:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  8000be:	ff1ff0ef          	jal	ra,8000ae <sys_exit>
    cprintf("BUG: exit failed.\n");
  8000c2:	00000517          	auipc	a0,0x0
  8000c6:	42e50513          	addi	a0,a0,1070 # 8004f0 <main+0xa>
  8000ca:	f77ff0ef          	jal	ra,800040 <cprintf>
    while (1);
  8000ce:	a001                	j	8000ce <exit+0x14>

00000000008000d0 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  8000d0:	1141                	addi	sp,sp,-16
  8000d2:	e406                	sd	ra,8(sp)
    int ret = main();
  8000d4:	412000ef          	jal	ra,8004e6 <main>
    exit(ret);
  8000d8:	fe3ff0ef          	jal	ra,8000ba <exit>

00000000008000dc <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  8000dc:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000e0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  8000e2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  8000e6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  8000e8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  8000ec:	f022                	sd	s0,32(sp)
  8000ee:	ec26                	sd	s1,24(sp)
  8000f0:	e84a                	sd	s2,16(sp)
  8000f2:	f406                	sd	ra,40(sp)
  8000f4:	e44e                	sd	s3,8(sp)
  8000f6:	84aa                	mv	s1,a0
  8000f8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  8000fa:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  8000fe:	2a01                	sext.w	s4,s4
    if (num >= base) {
  800100:	03067e63          	bgeu	a2,a6,80013c <printnum+0x60>
  800104:	89be                	mv	s3,a5
        while (-- width > 0)
  800106:	00805763          	blez	s0,800114 <printnum+0x38>
  80010a:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80010c:	85ca                	mv	a1,s2
  80010e:	854e                	mv	a0,s3
  800110:	9482                	jalr	s1
        while (-- width > 0)
  800112:	fc65                	bnez	s0,80010a <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800114:	1a02                	slli	s4,s4,0x20
  800116:	00000797          	auipc	a5,0x0
  80011a:	3f278793          	addi	a5,a5,1010 # 800508 <main+0x22>
  80011e:	020a5a13          	srli	s4,s4,0x20
  800122:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800124:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800126:	000a4503          	lbu	a0,0(s4)
}
  80012a:	70a2                	ld	ra,40(sp)
  80012c:	69a2                	ld	s3,8(sp)
  80012e:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  800130:	85ca                	mv	a1,s2
  800132:	87a6                	mv	a5,s1
}
  800134:	6942                	ld	s2,16(sp)
  800136:	64e2                	ld	s1,24(sp)
  800138:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  80013a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80013c:	03065633          	divu	a2,a2,a6
  800140:	8722                	mv	a4,s0
  800142:	f9bff0ef          	jal	ra,8000dc <printnum>
  800146:	b7f9                	j	800114 <printnum+0x38>

0000000000800148 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  800148:	7119                	addi	sp,sp,-128
  80014a:	f4a6                	sd	s1,104(sp)
  80014c:	f0ca                	sd	s2,96(sp)
  80014e:	ecce                	sd	s3,88(sp)
  800150:	e8d2                	sd	s4,80(sp)
  800152:	e4d6                	sd	s5,72(sp)
  800154:	e0da                	sd	s6,64(sp)
  800156:	fc5e                	sd	s7,56(sp)
  800158:	f06a                	sd	s10,32(sp)
  80015a:	fc86                	sd	ra,120(sp)
  80015c:	f8a2                	sd	s0,112(sp)
  80015e:	f862                	sd	s8,48(sp)
  800160:	f466                	sd	s9,40(sp)
  800162:	ec6e                	sd	s11,24(sp)
  800164:	892a                	mv	s2,a0
  800166:	84ae                	mv	s1,a1
  800168:	8d32                	mv	s10,a2
  80016a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  80016c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  800170:	5b7d                	li	s6,-1
  800172:	00000a97          	auipc	s5,0x0
  800176:	3caa8a93          	addi	s5,s5,970 # 80053c <main+0x56>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  80017a:	00000b97          	auipc	s7,0x0
  80017e:	5deb8b93          	addi	s7,s7,1502 # 800758 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800182:	000d4503          	lbu	a0,0(s10)
  800186:	001d0413          	addi	s0,s10,1
  80018a:	01350a63          	beq	a0,s3,80019e <vprintfmt+0x56>
            if (ch == '\0') {
  80018e:	c121                	beqz	a0,8001ce <vprintfmt+0x86>
            putch(ch, putdat);
  800190:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800192:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  800194:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  800196:	fff44503          	lbu	a0,-1(s0)
  80019a:	ff351ae3          	bne	a0,s3,80018e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  80019e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  8001a2:	02000793          	li	a5,32
        lflag = altflag = 0;
  8001a6:	4c81                	li	s9,0
  8001a8:	4881                	li	a7,0
        width = precision = -1;
  8001aa:	5c7d                	li	s8,-1
  8001ac:	5dfd                	li	s11,-1
  8001ae:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  8001b2:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  8001b4:	fdd6059b          	addiw	a1,a2,-35
  8001b8:	0ff5f593          	zext.b	a1,a1
  8001bc:	00140d13          	addi	s10,s0,1
  8001c0:	04b56263          	bltu	a0,a1,800204 <vprintfmt+0xbc>
  8001c4:	058a                	slli	a1,a1,0x2
  8001c6:	95d6                	add	a1,a1,s5
  8001c8:	4194                	lw	a3,0(a1)
  8001ca:	96d6                	add	a3,a3,s5
  8001cc:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  8001ce:	70e6                	ld	ra,120(sp)
  8001d0:	7446                	ld	s0,112(sp)
  8001d2:	74a6                	ld	s1,104(sp)
  8001d4:	7906                	ld	s2,96(sp)
  8001d6:	69e6                	ld	s3,88(sp)
  8001d8:	6a46                	ld	s4,80(sp)
  8001da:	6aa6                	ld	s5,72(sp)
  8001dc:	6b06                	ld	s6,64(sp)
  8001de:	7be2                	ld	s7,56(sp)
  8001e0:	7c42                	ld	s8,48(sp)
  8001e2:	7ca2                	ld	s9,40(sp)
  8001e4:	7d02                	ld	s10,32(sp)
  8001e6:	6de2                	ld	s11,24(sp)
  8001e8:	6109                	addi	sp,sp,128
  8001ea:	8082                	ret
            padc = '0';
  8001ec:	87b2                	mv	a5,a2
            goto reswitch;
  8001ee:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  8001f2:	846a                	mv	s0,s10
  8001f4:	00140d13          	addi	s10,s0,1
  8001f8:	fdd6059b          	addiw	a1,a2,-35
  8001fc:	0ff5f593          	zext.b	a1,a1
  800200:	fcb572e3          	bgeu	a0,a1,8001c4 <vprintfmt+0x7c>
            putch('%', putdat);
  800204:	85a6                	mv	a1,s1
  800206:	02500513          	li	a0,37
  80020a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  80020c:	fff44783          	lbu	a5,-1(s0)
  800210:	8d22                	mv	s10,s0
  800212:	f73788e3          	beq	a5,s3,800182 <vprintfmt+0x3a>
  800216:	ffed4783          	lbu	a5,-2(s10)
  80021a:	1d7d                	addi	s10,s10,-1
  80021c:	ff379de3          	bne	a5,s3,800216 <vprintfmt+0xce>
  800220:	b78d                	j	800182 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  800222:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800226:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80022a:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  80022c:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  800230:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800234:	02d86463          	bltu	a6,a3,80025c <vprintfmt+0x114>
                ch = *fmt;
  800238:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  80023c:	002c169b          	slliw	a3,s8,0x2
  800240:	0186873b          	addw	a4,a3,s8
  800244:	0017171b          	slliw	a4,a4,0x1
  800248:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  80024a:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  80024e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  800250:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  800254:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800258:	fed870e3          	bgeu	a6,a3,800238 <vprintfmt+0xf0>
            if (width < 0)
  80025c:	f40ddce3          	bgez	s11,8001b4 <vprintfmt+0x6c>
                width = precision, precision = -1;
  800260:	8de2                	mv	s11,s8
  800262:	5c7d                	li	s8,-1
  800264:	bf81                	j	8001b4 <vprintfmt+0x6c>
            if (width < 0)
  800266:	fffdc693          	not	a3,s11
  80026a:	96fd                	srai	a3,a3,0x3f
  80026c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  800270:	00144603          	lbu	a2,1(s0)
  800274:	2d81                	sext.w	s11,s11
  800276:	846a                	mv	s0,s10
            goto reswitch;
  800278:	bf35                	j	8001b4 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  80027a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  80027e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  800282:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  800284:	846a                	mv	s0,s10
            goto process_precision;
  800286:	bfd9                	j	80025c <vprintfmt+0x114>
    if (lflag >= 2) {
  800288:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80028a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  80028e:	01174463          	blt	a4,a7,800296 <vprintfmt+0x14e>
    else if (lflag) {
  800292:	1a088e63          	beqz	a7,80044e <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  800296:	000a3603          	ld	a2,0(s4)
  80029a:	46c1                	li	a3,16
  80029c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  80029e:	2781                	sext.w	a5,a5
  8002a0:	876e                	mv	a4,s11
  8002a2:	85a6                	mv	a1,s1
  8002a4:	854a                	mv	a0,s2
  8002a6:	e37ff0ef          	jal	ra,8000dc <printnum>
            break;
  8002aa:	bde1                	j	800182 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  8002ac:	000a2503          	lw	a0,0(s4)
  8002b0:	85a6                	mv	a1,s1
  8002b2:	0a21                	addi	s4,s4,8
  8002b4:	9902                	jalr	s2
            break;
  8002b6:	b5f1                	j	800182 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8002b8:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002ba:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002be:	01174463          	blt	a4,a7,8002c6 <vprintfmt+0x17e>
    else if (lflag) {
  8002c2:	18088163          	beqz	a7,800444 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  8002c6:	000a3603          	ld	a2,0(s4)
  8002ca:	46a9                	li	a3,10
  8002cc:	8a2e                	mv	s4,a1
  8002ce:	bfc1                	j	80029e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  8002d0:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  8002d4:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002d6:	846a                	mv	s0,s10
            goto reswitch;
  8002d8:	bdf1                	j	8001b4 <vprintfmt+0x6c>
            putch(ch, putdat);
  8002da:	85a6                	mv	a1,s1
  8002dc:	02500513          	li	a0,37
  8002e0:	9902                	jalr	s2
            break;
  8002e2:	b545                	j	800182 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  8002e4:	00144603          	lbu	a2,1(s0)
            lflag ++;
  8002e8:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  8002ea:	846a                	mv	s0,s10
            goto reswitch;
  8002ec:	b5e1                	j	8001b4 <vprintfmt+0x6c>
    if (lflag >= 2) {
  8002ee:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002f0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002f4:	01174463          	blt	a4,a7,8002fc <vprintfmt+0x1b4>
    else if (lflag) {
  8002f8:	14088163          	beqz	a7,80043a <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  8002fc:	000a3603          	ld	a2,0(s4)
  800300:	46a1                	li	a3,8
  800302:	8a2e                	mv	s4,a1
  800304:	bf69                	j	80029e <vprintfmt+0x156>
            putch('0', putdat);
  800306:	03000513          	li	a0,48
  80030a:	85a6                	mv	a1,s1
  80030c:	e03e                	sd	a5,0(sp)
  80030e:	9902                	jalr	s2
            putch('x', putdat);
  800310:	85a6                	mv	a1,s1
  800312:	07800513          	li	a0,120
  800316:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800318:	0a21                	addi	s4,s4,8
            goto number;
  80031a:	6782                	ld	a5,0(sp)
  80031c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80031e:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  800322:	bfb5                	j	80029e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800324:	000a3403          	ld	s0,0(s4)
  800328:	008a0713          	addi	a4,s4,8
  80032c:	e03a                	sd	a4,0(sp)
  80032e:	14040263          	beqz	s0,800472 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  800332:	0fb05763          	blez	s11,800420 <vprintfmt+0x2d8>
  800336:	02d00693          	li	a3,45
  80033a:	0cd79163          	bne	a5,a3,8003fc <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80033e:	00044783          	lbu	a5,0(s0)
  800342:	0007851b          	sext.w	a0,a5
  800346:	cf85                	beqz	a5,80037e <vprintfmt+0x236>
  800348:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  80034c:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800350:	000c4563          	bltz	s8,80035a <vprintfmt+0x212>
  800354:	3c7d                	addiw	s8,s8,-1
  800356:	036c0263          	beq	s8,s6,80037a <vprintfmt+0x232>
                    putch('?', putdat);
  80035a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  80035c:	0e0c8e63          	beqz	s9,800458 <vprintfmt+0x310>
  800360:	3781                	addiw	a5,a5,-32
  800362:	0ef47b63          	bgeu	s0,a5,800458 <vprintfmt+0x310>
                    putch('?', putdat);
  800366:	03f00513          	li	a0,63
  80036a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  80036c:	000a4783          	lbu	a5,0(s4)
  800370:	3dfd                	addiw	s11,s11,-1
  800372:	0a05                	addi	s4,s4,1
  800374:	0007851b          	sext.w	a0,a5
  800378:	ffe1                	bnez	a5,800350 <vprintfmt+0x208>
            for (; width > 0; width --) {
  80037a:	01b05963          	blez	s11,80038c <vprintfmt+0x244>
  80037e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  800380:	85a6                	mv	a1,s1
  800382:	02000513          	li	a0,32
  800386:	9902                	jalr	s2
            for (; width > 0; width --) {
  800388:	fe0d9be3          	bnez	s11,80037e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  80038c:	6a02                	ld	s4,0(sp)
  80038e:	bbd5                	j	800182 <vprintfmt+0x3a>
    if (lflag >= 2) {
  800390:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800392:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  800396:	01174463          	blt	a4,a7,80039e <vprintfmt+0x256>
    else if (lflag) {
  80039a:	08088d63          	beqz	a7,800434 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  80039e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  8003a2:	0a044d63          	bltz	s0,80045c <vprintfmt+0x314>
            num = getint(&ap, lflag);
  8003a6:	8622                	mv	a2,s0
  8003a8:	8a66                	mv	s4,s9
  8003aa:	46a9                	li	a3,10
  8003ac:	bdcd                	j	80029e <vprintfmt+0x156>
            err = va_arg(ap, int);
  8003ae:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003b2:	4761                	li	a4,24
            err = va_arg(ap, int);
  8003b4:	0a21                	addi	s4,s4,8
            if (err < 0) {
  8003b6:	41f7d69b          	sraiw	a3,a5,0x1f
  8003ba:	8fb5                	xor	a5,a5,a3
  8003bc:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8003c0:	02d74163          	blt	a4,a3,8003e2 <vprintfmt+0x29a>
  8003c4:	00369793          	slli	a5,a3,0x3
  8003c8:	97de                	add	a5,a5,s7
  8003ca:	639c                	ld	a5,0(a5)
  8003cc:	cb99                	beqz	a5,8003e2 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  8003ce:	86be                	mv	a3,a5
  8003d0:	00000617          	auipc	a2,0x0
  8003d4:	16860613          	addi	a2,a2,360 # 800538 <main+0x52>
  8003d8:	85a6                	mv	a1,s1
  8003da:	854a                	mv	a0,s2
  8003dc:	0ce000ef          	jal	ra,8004aa <printfmt>
  8003e0:	b34d                	j	800182 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  8003e2:	00000617          	auipc	a2,0x0
  8003e6:	14660613          	addi	a2,a2,326 # 800528 <main+0x42>
  8003ea:	85a6                	mv	a1,s1
  8003ec:	854a                	mv	a0,s2
  8003ee:	0bc000ef          	jal	ra,8004aa <printfmt>
  8003f2:	bb41                	j	800182 <vprintfmt+0x3a>
                p = "(null)";
  8003f4:	00000417          	auipc	s0,0x0
  8003f8:	12c40413          	addi	s0,s0,300 # 800520 <main+0x3a>
                for (width -= strnlen(p, precision); width > 0; width --) {
  8003fc:	85e2                	mv	a1,s8
  8003fe:	8522                	mv	a0,s0
  800400:	e43e                	sd	a5,8(sp)
  800402:	0c8000ef          	jal	ra,8004ca <strnlen>
  800406:	40ad8dbb          	subw	s11,s11,a0
  80040a:	01b05b63          	blez	s11,800420 <vprintfmt+0x2d8>
                    putch(padc, putdat);
  80040e:	67a2                	ld	a5,8(sp)
  800410:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800414:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800416:	85a6                	mv	a1,s1
  800418:	8552                	mv	a0,s4
  80041a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  80041c:	fe0d9ce3          	bnez	s11,800414 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800420:	00044783          	lbu	a5,0(s0)
  800424:	00140a13          	addi	s4,s0,1
  800428:	0007851b          	sext.w	a0,a5
  80042c:	d3a5                	beqz	a5,80038c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  80042e:	05e00413          	li	s0,94
  800432:	bf39                	j	800350 <vprintfmt+0x208>
        return va_arg(*ap, int);
  800434:	000a2403          	lw	s0,0(s4)
  800438:	b7ad                	j	8003a2 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  80043a:	000a6603          	lwu	a2,0(s4)
  80043e:	46a1                	li	a3,8
  800440:	8a2e                	mv	s4,a1
  800442:	bdb1                	j	80029e <vprintfmt+0x156>
  800444:	000a6603          	lwu	a2,0(s4)
  800448:	46a9                	li	a3,10
  80044a:	8a2e                	mv	s4,a1
  80044c:	bd89                	j	80029e <vprintfmt+0x156>
  80044e:	000a6603          	lwu	a2,0(s4)
  800452:	46c1                	li	a3,16
  800454:	8a2e                	mv	s4,a1
  800456:	b5a1                	j	80029e <vprintfmt+0x156>
                    putch(ch, putdat);
  800458:	9902                	jalr	s2
  80045a:	bf09                	j	80036c <vprintfmt+0x224>
                putch('-', putdat);
  80045c:	85a6                	mv	a1,s1
  80045e:	02d00513          	li	a0,45
  800462:	e03e                	sd	a5,0(sp)
  800464:	9902                	jalr	s2
                num = -(long long)num;
  800466:	6782                	ld	a5,0(sp)
  800468:	8a66                	mv	s4,s9
  80046a:	40800633          	neg	a2,s0
  80046e:	46a9                	li	a3,10
  800470:	b53d                	j	80029e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  800472:	03b05163          	blez	s11,800494 <vprintfmt+0x34c>
  800476:	02d00693          	li	a3,45
  80047a:	f6d79de3          	bne	a5,a3,8003f4 <vprintfmt+0x2ac>
                p = "(null)";
  80047e:	00000417          	auipc	s0,0x0
  800482:	0a240413          	addi	s0,s0,162 # 800520 <main+0x3a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800486:	02800793          	li	a5,40
  80048a:	02800513          	li	a0,40
  80048e:	00140a13          	addi	s4,s0,1
  800492:	bd6d                	j	80034c <vprintfmt+0x204>
  800494:	00000a17          	auipc	s4,0x0
  800498:	08da0a13          	addi	s4,s4,141 # 800521 <main+0x3b>
  80049c:	02800513          	li	a0,40
  8004a0:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  8004a4:	05e00413          	li	s0,94
  8004a8:	b565                	j	800350 <vprintfmt+0x208>

00000000008004aa <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004aa:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  8004ac:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004b0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004b2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  8004b4:	ec06                	sd	ra,24(sp)
  8004b6:	f83a                	sd	a4,48(sp)
  8004b8:	fc3e                	sd	a5,56(sp)
  8004ba:	e0c2                	sd	a6,64(sp)
  8004bc:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  8004be:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  8004c0:	c89ff0ef          	jal	ra,800148 <vprintfmt>
}
  8004c4:	60e2                	ld	ra,24(sp)
  8004c6:	6161                	addi	sp,sp,80
  8004c8:	8082                	ret

00000000008004ca <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  8004ca:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  8004cc:	e589                	bnez	a1,8004d6 <strnlen+0xc>
  8004ce:	a811                	j	8004e2 <strnlen+0x18>
        cnt ++;
  8004d0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  8004d2:	00f58863          	beq	a1,a5,8004e2 <strnlen+0x18>
  8004d6:	00f50733          	add	a4,a0,a5
  8004da:	00074703          	lbu	a4,0(a4)
  8004de:	fb6d                	bnez	a4,8004d0 <strnlen+0x6>
  8004e0:	85be                	mv	a1,a5
    }
    return cnt;
}
  8004e2:	852e                	mv	a0,a1
  8004e4:	8082                	ret

00000000008004e6 <main>:
#include <stdio.h>
#include <ulib.h>

int
main(void) {
  8004e6:	1141                	addi	sp,sp,-16
    // asm volatile("int $14");
    exit(0);
  8004e8:	4501                	li	a0,0
main(void) {
  8004ea:	e406                	sd	ra,8(sp)
    exit(0);
  8004ec:	bcfff0ef          	jal	ra,8000ba <exit>

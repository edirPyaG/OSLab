
obj/__user_divzero.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <_start>:
    # move down the esp register
    # since it may cause page fault in backtrace
    // subl $0x20, %esp

    # call user-program function
    call umain
  800020:	112000ef          	jal	ra,800132 <umain>
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
  80003a:	54a50513          	addi	a0,a0,1354 # 800580 <main+0x38>
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
  800056:	00000517          	auipc	a0,0x0
  80005a:	54a50513          	addi	a0,a0,1354 # 8005a0 <main+0x58>
  80005e:	044000ef          	jal	ra,8000a2 <cprintf>
    va_end(ap);
    exit(-E_PANIC);
  800062:	5559                	li	a0,-10
  800064:	0b8000ef          	jal	ra,80011c <exit>

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
  800070:	0a6000ef          	jal	ra,800116 <sys_putc>
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
  800096:	114000ef          	jal	ra,8001aa <vprintfmt>
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
  8000cc:	0de000ef          	jal	ra,8001aa <vprintfmt>
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

0000000000800116 <sys_putc>:
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
  800116:	85aa                	mv	a1,a0
    return syscall(SYS_putc, c);
  800118:	4579                	li	a0,30
  80011a:	bf7d                	j	8000d8 <syscall>

000000000080011c <exit>:
#include <syscall.h>
#include <stdio.h>
#include <ulib.h>

void
exit(int error_code) {
  80011c:	1141                	addi	sp,sp,-16
  80011e:	e406                	sd	ra,8(sp)
    sys_exit(error_code);
  800120:	ff1ff0ef          	jal	ra,800110 <sys_exit>
    cprintf("BUG: exit failed.\n");
  800124:	00000517          	auipc	a0,0x0
  800128:	48450513          	addi	a0,a0,1156 # 8005a8 <main+0x60>
  80012c:	f77ff0ef          	jal	ra,8000a2 <cprintf>
    while (1);
  800130:	a001                	j	800130 <exit+0x14>

0000000000800132 <umain>:
#include <ulib.h>

int main(void);

void
umain(void) {
  800132:	1141                	addi	sp,sp,-16
  800134:	e406                	sd	ra,8(sp)
    int ret = main();
  800136:	412000ef          	jal	ra,800548 <main>
    exit(ret);
  80013a:	fe3ff0ef          	jal	ra,80011c <exit>

000000000080013e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
  80013e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800142:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
  800144:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
  800148:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
  80014a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
  80014e:	f022                	sd	s0,32(sp)
  800150:	ec26                	sd	s1,24(sp)
  800152:	e84a                	sd	s2,16(sp)
  800154:	f406                	sd	ra,40(sp)
  800156:	e44e                	sd	s3,8(sp)
  800158:	84aa                	mv	s1,a0
  80015a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
  80015c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
  800160:	2a01                	sext.w	s4,s4
    if (num >= base) {
  800162:	03067e63          	bgeu	a2,a6,80019e <printnum+0x60>
  800166:	89be                	mv	s3,a5
        while (-- width > 0)
  800168:	00805763          	blez	s0,800176 <printnum+0x38>
  80016c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
  80016e:	85ca                	mv	a1,s2
  800170:	854e                	mv	a0,s3
  800172:	9482                	jalr	s1
        while (-- width > 0)
  800174:	fc65                	bnez	s0,80016c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
  800176:	1a02                	slli	s4,s4,0x20
  800178:	00000797          	auipc	a5,0x0
  80017c:	44878793          	addi	a5,a5,1096 # 8005c0 <main+0x78>
  800180:	020a5a13          	srli	s4,s4,0x20
  800184:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
  800186:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
  800188:	000a4503          	lbu	a0,0(s4)
}
  80018c:	70a2                	ld	ra,40(sp)
  80018e:	69a2                	ld	s3,8(sp)
  800190:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
  800192:	85ca                	mv	a1,s2
  800194:	87a6                	mv	a5,s1
}
  800196:	6942                	ld	s2,16(sp)
  800198:	64e2                	ld	s1,24(sp)
  80019a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
  80019c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
  80019e:	03065633          	divu	a2,a2,a6
  8001a2:	8722                	mv	a4,s0
  8001a4:	f9bff0ef          	jal	ra,80013e <printnum>
  8001a8:	b7f9                	j	800176 <printnum+0x38>

00000000008001aa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
  8001aa:	7119                	addi	sp,sp,-128
  8001ac:	f4a6                	sd	s1,104(sp)
  8001ae:	f0ca                	sd	s2,96(sp)
  8001b0:	ecce                	sd	s3,88(sp)
  8001b2:	e8d2                	sd	s4,80(sp)
  8001b4:	e4d6                	sd	s5,72(sp)
  8001b6:	e0da                	sd	s6,64(sp)
  8001b8:	fc5e                	sd	s7,56(sp)
  8001ba:	f06a                	sd	s10,32(sp)
  8001bc:	fc86                	sd	ra,120(sp)
  8001be:	f8a2                	sd	s0,112(sp)
  8001c0:	f862                	sd	s8,48(sp)
  8001c2:	f466                	sd	s9,40(sp)
  8001c4:	ec6e                	sd	s11,24(sp)
  8001c6:	892a                	mv	s2,a0
  8001c8:	84ae                	mv	s1,a1
  8001ca:	8d32                	mv	s10,a2
  8001cc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001ce:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
  8001d2:	5b7d                	li	s6,-1
  8001d4:	00000a97          	auipc	s5,0x0
  8001d8:	420a8a93          	addi	s5,s5,1056 # 8005f4 <main+0xac>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  8001dc:	00000b97          	auipc	s7,0x0
  8001e0:	634b8b93          	addi	s7,s7,1588 # 800810 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001e4:	000d4503          	lbu	a0,0(s10)
  8001e8:	001d0413          	addi	s0,s10,1
  8001ec:	01350a63          	beq	a0,s3,800200 <vprintfmt+0x56>
            if (ch == '\0') {
  8001f0:	c121                	beqz	a0,800230 <vprintfmt+0x86>
            putch(ch, putdat);
  8001f2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001f4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
  8001f6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
  8001f8:	fff44503          	lbu	a0,-1(s0)
  8001fc:	ff351ae3          	bne	a0,s3,8001f0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
  800200:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
  800204:	02000793          	li	a5,32
        lflag = altflag = 0;
  800208:	4c81                	li	s9,0
  80020a:	4881                	li	a7,0
        width = precision = -1;
  80020c:	5c7d                	li	s8,-1
  80020e:	5dfd                	li	s11,-1
  800210:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
  800214:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
  800216:	fdd6059b          	addiw	a1,a2,-35
  80021a:	0ff5f593          	zext.b	a1,a1
  80021e:	00140d13          	addi	s10,s0,1
  800222:	04b56263          	bltu	a0,a1,800266 <vprintfmt+0xbc>
  800226:	058a                	slli	a1,a1,0x2
  800228:	95d6                	add	a1,a1,s5
  80022a:	4194                	lw	a3,0(a1)
  80022c:	96d6                	add	a3,a3,s5
  80022e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
  800230:	70e6                	ld	ra,120(sp)
  800232:	7446                	ld	s0,112(sp)
  800234:	74a6                	ld	s1,104(sp)
  800236:	7906                	ld	s2,96(sp)
  800238:	69e6                	ld	s3,88(sp)
  80023a:	6a46                	ld	s4,80(sp)
  80023c:	6aa6                	ld	s5,72(sp)
  80023e:	6b06                	ld	s6,64(sp)
  800240:	7be2                	ld	s7,56(sp)
  800242:	7c42                	ld	s8,48(sp)
  800244:	7ca2                	ld	s9,40(sp)
  800246:	7d02                	ld	s10,32(sp)
  800248:	6de2                	ld	s11,24(sp)
  80024a:	6109                	addi	sp,sp,128
  80024c:	8082                	ret
            padc = '0';
  80024e:	87b2                	mv	a5,a2
            goto reswitch;
  800250:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  800254:	846a                	mv	s0,s10
  800256:	00140d13          	addi	s10,s0,1
  80025a:	fdd6059b          	addiw	a1,a2,-35
  80025e:	0ff5f593          	zext.b	a1,a1
  800262:	fcb572e3          	bgeu	a0,a1,800226 <vprintfmt+0x7c>
            putch('%', putdat);
  800266:	85a6                	mv	a1,s1
  800268:	02500513          	li	a0,37
  80026c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
  80026e:	fff44783          	lbu	a5,-1(s0)
  800272:	8d22                	mv	s10,s0
  800274:	f73788e3          	beq	a5,s3,8001e4 <vprintfmt+0x3a>
  800278:	ffed4783          	lbu	a5,-2(s10)
  80027c:	1d7d                	addi	s10,s10,-1
  80027e:	ff379de3          	bne	a5,s3,800278 <vprintfmt+0xce>
  800282:	b78d                	j	8001e4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
  800284:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
  800288:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
  80028c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
  80028e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
  800292:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  800296:	02d86463          	bltu	a6,a3,8002be <vprintfmt+0x114>
                ch = *fmt;
  80029a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
  80029e:	002c169b          	slliw	a3,s8,0x2
  8002a2:	0186873b          	addw	a4,a3,s8
  8002a6:	0017171b          	slliw	a4,a4,0x1
  8002aa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
  8002ac:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
  8002b0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
  8002b2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
  8002b6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
  8002ba:	fed870e3          	bgeu	a6,a3,80029a <vprintfmt+0xf0>
            if (width < 0)
  8002be:	f40ddce3          	bgez	s11,800216 <vprintfmt+0x6c>
                width = precision, precision = -1;
  8002c2:	8de2                	mv	s11,s8
  8002c4:	5c7d                	li	s8,-1
  8002c6:	bf81                	j	800216 <vprintfmt+0x6c>
            if (width < 0)
  8002c8:	fffdc693          	not	a3,s11
  8002cc:	96fd                	srai	a3,a3,0x3f
  8002ce:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
  8002d2:	00144603          	lbu	a2,1(s0)
  8002d6:	2d81                	sext.w	s11,s11
  8002d8:	846a                	mv	s0,s10
            goto reswitch;
  8002da:	bf35                	j	800216 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
  8002dc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
  8002e0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
  8002e4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
  8002e6:	846a                	mv	s0,s10
            goto process_precision;
  8002e8:	bfd9                	j	8002be <vprintfmt+0x114>
    if (lflag >= 2) {
  8002ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8002ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  8002f0:	01174463          	blt	a4,a7,8002f8 <vprintfmt+0x14e>
    else if (lflag) {
  8002f4:	1a088e63          	beqz	a7,8004b0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
  8002f8:	000a3603          	ld	a2,0(s4)
  8002fc:	46c1                	li	a3,16
  8002fe:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
  800300:	2781                	sext.w	a5,a5
  800302:	876e                	mv	a4,s11
  800304:	85a6                	mv	a1,s1
  800306:	854a                	mv	a0,s2
  800308:	e37ff0ef          	jal	ra,80013e <printnum>
            break;
  80030c:	bde1                	j	8001e4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
  80030e:	000a2503          	lw	a0,0(s4)
  800312:	85a6                	mv	a1,s1
  800314:	0a21                	addi	s4,s4,8
  800316:	9902                	jalr	s2
            break;
  800318:	b5f1                	j	8001e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
  80031a:	4705                	li	a4,1
            precision = va_arg(ap, int);
  80031c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800320:	01174463          	blt	a4,a7,800328 <vprintfmt+0x17e>
    else if (lflag) {
  800324:	18088163          	beqz	a7,8004a6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
  800328:	000a3603          	ld	a2,0(s4)
  80032c:	46a9                	li	a3,10
  80032e:	8a2e                	mv	s4,a1
  800330:	bfc1                	j	800300 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
  800332:	00144603          	lbu	a2,1(s0)
            altflag = 1;
  800336:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
  800338:	846a                	mv	s0,s10
            goto reswitch;
  80033a:	bdf1                	j	800216 <vprintfmt+0x6c>
            putch(ch, putdat);
  80033c:	85a6                	mv	a1,s1
  80033e:	02500513          	li	a0,37
  800342:	9902                	jalr	s2
            break;
  800344:	b545                	j	8001e4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
  800346:	00144603          	lbu	a2,1(s0)
            lflag ++;
  80034a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
  80034c:	846a                	mv	s0,s10
            goto reswitch;
  80034e:	b5e1                	j	800216 <vprintfmt+0x6c>
    if (lflag >= 2) {
  800350:	4705                	li	a4,1
            precision = va_arg(ap, int);
  800352:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
  800356:	01174463          	blt	a4,a7,80035e <vprintfmt+0x1b4>
    else if (lflag) {
  80035a:	14088163          	beqz	a7,80049c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
  80035e:	000a3603          	ld	a2,0(s4)
  800362:	46a1                	li	a3,8
  800364:	8a2e                	mv	s4,a1
  800366:	bf69                	j	800300 <vprintfmt+0x156>
            putch('0', putdat);
  800368:	03000513          	li	a0,48
  80036c:	85a6                	mv	a1,s1
  80036e:	e03e                	sd	a5,0(sp)
  800370:	9902                	jalr	s2
            putch('x', putdat);
  800372:	85a6                	mv	a1,s1
  800374:	07800513          	li	a0,120
  800378:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  80037a:	0a21                	addi	s4,s4,8
            goto number;
  80037c:	6782                	ld	a5,0(sp)
  80037e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
  800380:	ff8a3603          	ld	a2,-8(s4)
            goto number;
  800384:	bfb5                	j	800300 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
  800386:	000a3403          	ld	s0,0(s4)
  80038a:	008a0713          	addi	a4,s4,8
  80038e:	e03a                	sd	a4,0(sp)
  800390:	14040263          	beqz	s0,8004d4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
  800394:	0fb05763          	blez	s11,800482 <vprintfmt+0x2d8>
  800398:	02d00693          	li	a3,45
  80039c:	0cd79163          	bne	a5,a3,80045e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003a0:	00044783          	lbu	a5,0(s0)
  8003a4:	0007851b          	sext.w	a0,a5
  8003a8:	cf85                	beqz	a5,8003e0 <vprintfmt+0x236>
  8003aa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003ae:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003b2:	000c4563          	bltz	s8,8003bc <vprintfmt+0x212>
  8003b6:	3c7d                	addiw	s8,s8,-1
  8003b8:	036c0263          	beq	s8,s6,8003dc <vprintfmt+0x232>
                    putch('?', putdat);
  8003bc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
  8003be:	0e0c8e63          	beqz	s9,8004ba <vprintfmt+0x310>
  8003c2:	3781                	addiw	a5,a5,-32
  8003c4:	0ef47b63          	bgeu	s0,a5,8004ba <vprintfmt+0x310>
                    putch('?', putdat);
  8003c8:	03f00513          	li	a0,63
  8003cc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8003ce:	000a4783          	lbu	a5,0(s4)
  8003d2:	3dfd                	addiw	s11,s11,-1
  8003d4:	0a05                	addi	s4,s4,1
  8003d6:	0007851b          	sext.w	a0,a5
  8003da:	ffe1                	bnez	a5,8003b2 <vprintfmt+0x208>
            for (; width > 0; width --) {
  8003dc:	01b05963          	blez	s11,8003ee <vprintfmt+0x244>
  8003e0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
  8003e2:	85a6                	mv	a1,s1
  8003e4:	02000513          	li	a0,32
  8003e8:	9902                	jalr	s2
            for (; width > 0; width --) {
  8003ea:	fe0d9be3          	bnez	s11,8003e0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
  8003ee:	6a02                	ld	s4,0(sp)
  8003f0:	bbd5                	j	8001e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
  8003f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
  8003f4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
  8003f8:	01174463          	blt	a4,a7,800400 <vprintfmt+0x256>
    else if (lflag) {
  8003fc:	08088d63          	beqz	a7,800496 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
  800400:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
  800404:	0a044d63          	bltz	s0,8004be <vprintfmt+0x314>
            num = getint(&ap, lflag);
  800408:	8622                	mv	a2,s0
  80040a:	8a66                	mv	s4,s9
  80040c:	46a9                	li	a3,10
  80040e:	bdcd                	j	800300 <vprintfmt+0x156>
            err = va_arg(ap, int);
  800410:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800414:	4761                	li	a4,24
            err = va_arg(ap, int);
  800416:	0a21                	addi	s4,s4,8
            if (err < 0) {
  800418:	41f7d69b          	sraiw	a3,a5,0x1f
  80041c:	8fb5                	xor	a5,a5,a3
  80041e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
  800422:	02d74163          	blt	a4,a3,800444 <vprintfmt+0x29a>
  800426:	00369793          	slli	a5,a3,0x3
  80042a:	97de                	add	a5,a5,s7
  80042c:	639c                	ld	a5,0(a5)
  80042e:	cb99                	beqz	a5,800444 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
  800430:	86be                	mv	a3,a5
  800432:	00000617          	auipc	a2,0x0
  800436:	1be60613          	addi	a2,a2,446 # 8005f0 <main+0xa8>
  80043a:	85a6                	mv	a1,s1
  80043c:	854a                	mv	a0,s2
  80043e:	0ce000ef          	jal	ra,80050c <printfmt>
  800442:	b34d                	j	8001e4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
  800444:	00000617          	auipc	a2,0x0
  800448:	19c60613          	addi	a2,a2,412 # 8005e0 <main+0x98>
  80044c:	85a6                	mv	a1,s1
  80044e:	854a                	mv	a0,s2
  800450:	0bc000ef          	jal	ra,80050c <printfmt>
  800454:	bb41                	j	8001e4 <vprintfmt+0x3a>
                p = "(null)";
  800456:	00000417          	auipc	s0,0x0
  80045a:	18240413          	addi	s0,s0,386 # 8005d8 <main+0x90>
                for (width -= strnlen(p, precision); width > 0; width --) {
  80045e:	85e2                	mv	a1,s8
  800460:	8522                	mv	a0,s0
  800462:	e43e                	sd	a5,8(sp)
  800464:	0c8000ef          	jal	ra,80052c <strnlen>
  800468:	40ad8dbb          	subw	s11,s11,a0
  80046c:	01b05b63          	blez	s11,800482 <vprintfmt+0x2d8>
                    putch(padc, putdat);
  800470:	67a2                	ld	a5,8(sp)
  800472:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
  800476:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
  800478:	85a6                	mv	a1,s1
  80047a:	8552                	mv	a0,s4
  80047c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
  80047e:	fe0d9ce3          	bnez	s11,800476 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  800482:	00044783          	lbu	a5,0(s0)
  800486:	00140a13          	addi	s4,s0,1
  80048a:	0007851b          	sext.w	a0,a5
  80048e:	d3a5                	beqz	a5,8003ee <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
  800490:	05e00413          	li	s0,94
  800494:	bf39                	j	8003b2 <vprintfmt+0x208>
        return va_arg(*ap, int);
  800496:	000a2403          	lw	s0,0(s4)
  80049a:	b7ad                	j	800404 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
  80049c:	000a6603          	lwu	a2,0(s4)
  8004a0:	46a1                	li	a3,8
  8004a2:	8a2e                	mv	s4,a1
  8004a4:	bdb1                	j	800300 <vprintfmt+0x156>
  8004a6:	000a6603          	lwu	a2,0(s4)
  8004aa:	46a9                	li	a3,10
  8004ac:	8a2e                	mv	s4,a1
  8004ae:	bd89                	j	800300 <vprintfmt+0x156>
  8004b0:	000a6603          	lwu	a2,0(s4)
  8004b4:	46c1                	li	a3,16
  8004b6:	8a2e                	mv	s4,a1
  8004b8:	b5a1                	j	800300 <vprintfmt+0x156>
                    putch(ch, putdat);
  8004ba:	9902                	jalr	s2
  8004bc:	bf09                	j	8003ce <vprintfmt+0x224>
                putch('-', putdat);
  8004be:	85a6                	mv	a1,s1
  8004c0:	02d00513          	li	a0,45
  8004c4:	e03e                	sd	a5,0(sp)
  8004c6:	9902                	jalr	s2
                num = -(long long)num;
  8004c8:	6782                	ld	a5,0(sp)
  8004ca:	8a66                	mv	s4,s9
  8004cc:	40800633          	neg	a2,s0
  8004d0:	46a9                	li	a3,10
  8004d2:	b53d                	j	800300 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
  8004d4:	03b05163          	blez	s11,8004f6 <vprintfmt+0x34c>
  8004d8:	02d00693          	li	a3,45
  8004dc:	f6d79de3          	bne	a5,a3,800456 <vprintfmt+0x2ac>
                p = "(null)";
  8004e0:	00000417          	auipc	s0,0x0
  8004e4:	0f840413          	addi	s0,s0,248 # 8005d8 <main+0x90>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
  8004e8:	02800793          	li	a5,40
  8004ec:	02800513          	li	a0,40
  8004f0:	00140a13          	addi	s4,s0,1
  8004f4:	bd6d                	j	8003ae <vprintfmt+0x204>
  8004f6:	00000a17          	auipc	s4,0x0
  8004fa:	0e3a0a13          	addi	s4,s4,227 # 8005d9 <main+0x91>
  8004fe:	02800513          	li	a0,40
  800502:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
  800506:	05e00413          	li	s0,94
  80050a:	b565                	j	8003b2 <vprintfmt+0x208>

000000000080050c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  80050c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
  80050e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800512:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800514:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
  800516:	ec06                	sd	ra,24(sp)
  800518:	f83a                	sd	a4,48(sp)
  80051a:	fc3e                	sd	a5,56(sp)
  80051c:	e0c2                	sd	a6,64(sp)
  80051e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
  800520:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
  800522:	c89ff0ef          	jal	ra,8001aa <vprintfmt>
}
  800526:	60e2                	ld	ra,24(sp)
  800528:	6161                	addi	sp,sp,80
  80052a:	8082                	ret

000000000080052c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
  80052c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
  80052e:	e589                	bnez	a1,800538 <strnlen+0xc>
  800530:	a811                	j	800544 <strnlen+0x18>
        cnt ++;
  800532:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
  800534:	00f58863          	beq	a1,a5,800544 <strnlen+0x18>
  800538:	00f50733          	add	a4,a0,a5
  80053c:	00074703          	lbu	a4,0(a4)
  800540:	fb6d                	bnez	a4,800532 <strnlen+0x6>
  800542:	85be                	mv	a1,a5
    }
    return cnt;
}
  800544:	852e                	mv	a0,a1
  800546:	8082                	ret

0000000000800548 <main>:

int zero;

int
main(void) {
    cprintf("value is %d.\n", 1 / zero);
  800548:	00001797          	auipc	a5,0x1
  80054c:	ab87a783          	lw	a5,-1352(a5) # 801000 <zero>
  800550:	4585                	li	a1,1
  800552:	02f5c5bb          	divw	a1,a1,a5
main(void) {
  800556:	1141                	addi	sp,sp,-16
    cprintf("value is %d.\n", 1 / zero);
  800558:	00000517          	auipc	a0,0x0
  80055c:	38050513          	addi	a0,a0,896 # 8008d8 <error_string+0xc8>
main(void) {
  800560:	e406                	sd	ra,8(sp)
    cprintf("value is %d.\n", 1 / zero);
  800562:	b41ff0ef          	jal	ra,8000a2 <cprintf>
    panic("FAIL: T.T\n");
  800566:	00000617          	auipc	a2,0x0
  80056a:	38260613          	addi	a2,a2,898 # 8008e8 <error_string+0xd8>
  80056e:	45a5                	li	a1,9
  800570:	00000517          	auipc	a0,0x0
  800574:	38850513          	addi	a0,a0,904 # 8008f8 <error_string+0xe8>
  800578:	aafff0ef          	jal	ra,800026 <__panic>

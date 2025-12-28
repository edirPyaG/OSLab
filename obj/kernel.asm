
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000c2517          	auipc	a0,0xc2
ffffffffc020004e:	85e50513          	addi	a0,a0,-1954 # ffffffffc02c18a8 <buf>
ffffffffc0200052:	000c6617          	auipc	a2,0xc6
ffffffffc0200056:	d3660613          	addi	a2,a2,-714 # ffffffffc02c5d88 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5f6050ef          	jal	ra,ffffffffc0205658 <memset>
    cons_init(); // init the console
ffffffffc0200066:	508000ef          	jal	ra,ffffffffc020056e <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006a:	00005597          	auipc	a1,0x5
ffffffffc020006e:	61e58593          	addi	a1,a1,1566 # ffffffffc0205688 <etext+0x6>
ffffffffc0200072:	00005517          	auipc	a0,0x5
ffffffffc0200076:	63650513          	addi	a0,a0,1590 # ffffffffc02056a8 <etext+0x26>
ffffffffc020007a:	11e000ef          	jal	ra,ffffffffc0200198 <cprintf>

    print_kerninfo();
ffffffffc020007e:	1a2000ef          	jal	ra,ffffffffc0200220 <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc0200082:	55e000ef          	jal	ra,ffffffffc02005e0 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc0200086:	71a020ef          	jal	ra,ffffffffc02027a0 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	113000ef          	jal	ra,ffffffffc020099c <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	111000ef          	jal	ra,ffffffffc020099e <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc0200092:	786030ef          	jal	ra,ffffffffc0203818 <vmm_init>
    sched_init();
ffffffffc0200096:	659040ef          	jal	ra,ffffffffc0204eee <sched_init>
    proc_init(); // init process table
ffffffffc020009a:	3f5040ef          	jal	ra,ffffffffc0204c8e <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009e:	4a0000ef          	jal	ra,ffffffffc020053e <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000a2:	0ef000ef          	jal	ra,ffffffffc0200990 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a6:	581040ef          	jal	ra,ffffffffc0204e26 <cpu_idle>

ffffffffc02000aa <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000aa:	715d                	addi	sp,sp,-80
ffffffffc02000ac:	e486                	sd	ra,72(sp)
ffffffffc02000ae:	e0a6                	sd	s1,64(sp)
ffffffffc02000b0:	fc4a                	sd	s2,56(sp)
ffffffffc02000b2:	f84e                	sd	s3,48(sp)
ffffffffc02000b4:	f452                	sd	s4,40(sp)
ffffffffc02000b6:	f056                	sd	s5,32(sp)
ffffffffc02000b8:	ec5a                	sd	s6,24(sp)
ffffffffc02000ba:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000bc:	c901                	beqz	a0,ffffffffc02000cc <readline+0x22>
ffffffffc02000be:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000c0:	00005517          	auipc	a0,0x5
ffffffffc02000c4:	5f050513          	addi	a0,a0,1520 # ffffffffc02056b0 <etext+0x2e>
ffffffffc02000c8:	0d0000ef          	jal	ra,ffffffffc0200198 <cprintf>
readline(const char *prompt) {
ffffffffc02000cc:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ce:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000d2:	4aa9                	li	s5,10
ffffffffc02000d4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d6:	000c1b97          	auipc	s7,0xc1
ffffffffc02000da:	7d2b8b93          	addi	s7,s7,2002 # ffffffffc02c18a8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000de:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000e2:	12e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000e6:	00054a63          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ea:	00a95a63          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc02000ee:	029a5263          	bge	s4,s1,ffffffffc0200112 <readline+0x68>
        c = getchar();
ffffffffc02000f2:	11e000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc02000f6:	fe055ae3          	bgez	a0,ffffffffc02000ea <readline+0x40>
            return NULL;
ffffffffc02000fa:	4501                	li	a0,0
ffffffffc02000fc:	a091                	j	ffffffffc0200140 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fe:	03351463          	bne	a0,s3,ffffffffc0200126 <readline+0x7c>
ffffffffc0200102:	e8a9                	bnez	s1,ffffffffc0200154 <readline+0xaa>
        c = getchar();
ffffffffc0200104:	10c000ef          	jal	ra,ffffffffc0200210 <getchar>
        if (c < 0) {
ffffffffc0200108:	fe0549e3          	bltz	a0,ffffffffc02000fa <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010c:	fea959e3          	bge	s2,a0,ffffffffc02000fe <readline+0x54>
ffffffffc0200110:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200112:	e42a                	sd	a0,8(sp)
ffffffffc0200114:	0ba000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i ++] = c;
ffffffffc0200118:	6522                	ld	a0,8(sp)
ffffffffc020011a:	009b87b3          	add	a5,s7,s1
ffffffffc020011e:	2485                	addiw	s1,s1,1
ffffffffc0200120:	00a78023          	sb	a0,0(a5)
ffffffffc0200124:	bf7d                	j	ffffffffc02000e2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200126:	01550463          	beq	a0,s5,ffffffffc020012e <readline+0x84>
ffffffffc020012a:	fb651ce3          	bne	a0,s6,ffffffffc02000e2 <readline+0x38>
            cputchar(c);
ffffffffc020012e:	0a0000ef          	jal	ra,ffffffffc02001ce <cputchar>
            buf[i] = '\0';
ffffffffc0200132:	000c1517          	auipc	a0,0xc1
ffffffffc0200136:	77650513          	addi	a0,a0,1910 # ffffffffc02c18a8 <buf>
ffffffffc020013a:	94aa                	add	s1,s1,a0
ffffffffc020013c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200140:	60a6                	ld	ra,72(sp)
ffffffffc0200142:	6486                	ld	s1,64(sp)
ffffffffc0200144:	7962                	ld	s2,56(sp)
ffffffffc0200146:	79c2                	ld	s3,48(sp)
ffffffffc0200148:	7a22                	ld	s4,40(sp)
ffffffffc020014a:	7a82                	ld	s5,32(sp)
ffffffffc020014c:	6b62                	ld	s6,24(sp)
ffffffffc020014e:	6bc2                	ld	s7,16(sp)
ffffffffc0200150:	6161                	addi	sp,sp,80
ffffffffc0200152:	8082                	ret
            cputchar(c);
ffffffffc0200154:	4521                	li	a0,8
ffffffffc0200156:	078000ef          	jal	ra,ffffffffc02001ce <cputchar>
            i --;
ffffffffc020015a:	34fd                	addiw	s1,s1,-1
ffffffffc020015c:	b759                	j	ffffffffc02000e2 <readline+0x38>

ffffffffc020015e <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	e022                	sd	s0,0(sp)
ffffffffc0200162:	e406                	sd	ra,8(sp)
ffffffffc0200164:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200166:	40a000ef          	jal	ra,ffffffffc0200570 <cons_putc>
    (*cnt)++;
ffffffffc020016a:	401c                	lw	a5,0(s0)
}
ffffffffc020016c:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016e:	2785                	addiw	a5,a5,1
ffffffffc0200170:	c01c                	sw	a5,0(s0)
}
ffffffffc0200172:	6402                	ld	s0,0(sp)
ffffffffc0200174:	0141                	addi	sp,sp,16
ffffffffc0200176:	8082                	ret

ffffffffc0200178 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200178:	1101                	addi	sp,sp,-32
ffffffffc020017a:	862a                	mv	a2,a0
ffffffffc020017c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017e:	00000517          	auipc	a0,0x0
ffffffffc0200182:	fe050513          	addi	a0,a0,-32 # ffffffffc020015e <cputch>
ffffffffc0200186:	006c                	addi	a1,sp,12
{
ffffffffc0200188:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020018a:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020018c:	0a8050ef          	jal	ra,ffffffffc0205234 <vprintfmt>
    return cnt;
}
ffffffffc0200190:	60e2                	ld	ra,24(sp)
ffffffffc0200192:	4532                	lw	a0,12(sp)
ffffffffc0200194:	6105                	addi	sp,sp,32
ffffffffc0200196:	8082                	ret

ffffffffc0200198 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200198:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020019a:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019e:	8e2a                	mv	t3,a0
ffffffffc02001a0:	f42e                	sd	a1,40(sp)
ffffffffc02001a2:	f832                	sd	a2,48(sp)
ffffffffc02001a4:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a6:	00000517          	auipc	a0,0x0
ffffffffc02001aa:	fb850513          	addi	a0,a0,-72 # ffffffffc020015e <cputch>
ffffffffc02001ae:	004c                	addi	a1,sp,4
ffffffffc02001b0:	869a                	mv	a3,t1
ffffffffc02001b2:	8672                	mv	a2,t3
{
ffffffffc02001b4:	ec06                	sd	ra,24(sp)
ffffffffc02001b6:	e0ba                	sd	a4,64(sp)
ffffffffc02001b8:	e4be                	sd	a5,72(sp)
ffffffffc02001ba:	e8c2                	sd	a6,80(sp)
ffffffffc02001bc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001be:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001c0:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c2:	072050ef          	jal	ra,ffffffffc0205234 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	4512                	lw	a0,4(sp)
ffffffffc02001ca:	6125                	addi	sp,sp,96
ffffffffc02001cc:	8082                	ret

ffffffffc02001ce <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ce:	a64d                	j	ffffffffc0200570 <cons_putc>

ffffffffc02001d0 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001d0:	1101                	addi	sp,sp,-32
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	ec06                	sd	ra,24(sp)
ffffffffc02001d6:	e426                	sd	s1,8(sp)
ffffffffc02001d8:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001da:	00054503          	lbu	a0,0(a0)
ffffffffc02001de:	c51d                	beqz	a0,ffffffffc020020c <cputs+0x3c>
ffffffffc02001e0:	0405                	addi	s0,s0,1
ffffffffc02001e2:	4485                	li	s1,1
ffffffffc02001e4:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e6:	38a000ef          	jal	ra,ffffffffc0200570 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001ea:	00044503          	lbu	a0,0(s0)
ffffffffc02001ee:	008487bb          	addw	a5,s1,s0
ffffffffc02001f2:	0405                	addi	s0,s0,1
ffffffffc02001f4:	f96d                	bnez	a0,ffffffffc02001e6 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f6:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001fa:	4529                	li	a0,10
ffffffffc02001fc:	374000ef          	jal	ra,ffffffffc0200570 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200200:	60e2                	ld	ra,24(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	6442                	ld	s0,16(sp)
ffffffffc0200206:	64a2                	ld	s1,8(sp)
ffffffffc0200208:	6105                	addi	sp,sp,32
ffffffffc020020a:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc020020c:	4405                	li	s0,1
ffffffffc020020e:	b7f5                	j	ffffffffc02001fa <cputs+0x2a>

ffffffffc0200210 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200210:	1141                	addi	sp,sp,-16
ffffffffc0200212:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200214:	390000ef          	jal	ra,ffffffffc02005a4 <cons_getc>
ffffffffc0200218:	dd75                	beqz	a0,ffffffffc0200214 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	0141                	addi	sp,sp,16
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200220:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	49650513          	addi	a0,a0,1174 # ffffffffc02056b8 <etext+0x36>
void print_kerninfo(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020022c:	f6dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200230:	00000597          	auipc	a1,0x0
ffffffffc0200234:	e1a58593          	addi	a1,a1,-486 # ffffffffc020004a <kern_init>
ffffffffc0200238:	00005517          	auipc	a0,0x5
ffffffffc020023c:	4a050513          	addi	a0,a0,1184 # ffffffffc02056d8 <etext+0x56>
ffffffffc0200240:	f59ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200244:	00005597          	auipc	a1,0x5
ffffffffc0200248:	43e58593          	addi	a1,a1,1086 # ffffffffc0205682 <etext>
ffffffffc020024c:	00005517          	auipc	a0,0x5
ffffffffc0200250:	4ac50513          	addi	a0,a0,1196 # ffffffffc02056f8 <etext+0x76>
ffffffffc0200254:	f45ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200258:	000c1597          	auipc	a1,0xc1
ffffffffc020025c:	65058593          	addi	a1,a1,1616 # ffffffffc02c18a8 <buf>
ffffffffc0200260:	00005517          	auipc	a0,0x5
ffffffffc0200264:	4b850513          	addi	a0,a0,1208 # ffffffffc0205718 <etext+0x96>
ffffffffc0200268:	f31ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020026c:	000c6597          	auipc	a1,0xc6
ffffffffc0200270:	b1c58593          	addi	a1,a1,-1252 # ffffffffc02c5d88 <end>
ffffffffc0200274:	00005517          	auipc	a0,0x5
ffffffffc0200278:	4c450513          	addi	a0,a0,1220 # ffffffffc0205738 <etext+0xb6>
ffffffffc020027c:	f1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200280:	000c6597          	auipc	a1,0xc6
ffffffffc0200284:	f0758593          	addi	a1,a1,-249 # ffffffffc02c6187 <end+0x3ff>
ffffffffc0200288:	00000797          	auipc	a5,0x0
ffffffffc020028c:	dc278793          	addi	a5,a5,-574 # ffffffffc020004a <kern_init>
ffffffffc0200290:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029a:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029e:	95be                	add	a1,a1,a5
ffffffffc02002a0:	85a9                	srai	a1,a1,0xa
ffffffffc02002a2:	00005517          	auipc	a0,0x5
ffffffffc02002a6:	4b650513          	addi	a0,a0,1206 # ffffffffc0205758 <etext+0xd6>
}
ffffffffc02002aa:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002ac:	b5f5                	j	ffffffffc0200198 <cprintf>

ffffffffc02002ae <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002ae:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b0:	00005617          	auipc	a2,0x5
ffffffffc02002b4:	4d860613          	addi	a2,a2,1240 # ffffffffc0205788 <etext+0x106>
ffffffffc02002b8:	04d00593          	li	a1,77
ffffffffc02002bc:	00005517          	auipc	a0,0x5
ffffffffc02002c0:	4e450513          	addi	a0,a0,1252 # ffffffffc02057a0 <etext+0x11e>
void print_stackframe(void) {
ffffffffc02002c4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c6:	1cc000ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02002ca <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ca:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002cc:	00005617          	auipc	a2,0x5
ffffffffc02002d0:	4ec60613          	addi	a2,a2,1260 # ffffffffc02057b8 <etext+0x136>
ffffffffc02002d4:	00005597          	auipc	a1,0x5
ffffffffc02002d8:	50458593          	addi	a1,a1,1284 # ffffffffc02057d8 <etext+0x156>
ffffffffc02002dc:	00005517          	auipc	a0,0x5
ffffffffc02002e0:	50450513          	addi	a0,a0,1284 # ffffffffc02057e0 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e4:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	eb3ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc02002ea:	00005617          	auipc	a2,0x5
ffffffffc02002ee:	50660613          	addi	a2,a2,1286 # ffffffffc02057f0 <etext+0x16e>
ffffffffc02002f2:	00005597          	auipc	a1,0x5
ffffffffc02002f6:	52658593          	addi	a1,a1,1318 # ffffffffc0205818 <etext+0x196>
ffffffffc02002fa:	00005517          	auipc	a0,0x5
ffffffffc02002fe:	4e650513          	addi	a0,a0,1254 # ffffffffc02057e0 <etext+0x15e>
ffffffffc0200302:	e97ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200306:	00005617          	auipc	a2,0x5
ffffffffc020030a:	52260613          	addi	a2,a2,1314 # ffffffffc0205828 <etext+0x1a6>
ffffffffc020030e:	00005597          	auipc	a1,0x5
ffffffffc0200312:	53a58593          	addi	a1,a1,1338 # ffffffffc0205848 <etext+0x1c6>
ffffffffc0200316:	00005517          	auipc	a0,0x5
ffffffffc020031a:	4ca50513          	addi	a0,a0,1226 # ffffffffc02057e0 <etext+0x15e>
ffffffffc020031e:	e7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    return 0;
}
ffffffffc0200322:	60a2                	ld	ra,8(sp)
ffffffffc0200324:	4501                	li	a0,0
ffffffffc0200326:	0141                	addi	sp,sp,16
ffffffffc0200328:	8082                	ret

ffffffffc020032a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032a:	1141                	addi	sp,sp,-16
ffffffffc020032c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032e:	ef3ff0ef          	jal	ra,ffffffffc0200220 <print_kerninfo>
    return 0;
}
ffffffffc0200332:	60a2                	ld	ra,8(sp)
ffffffffc0200334:	4501                	li	a0,0
ffffffffc0200336:	0141                	addi	sp,sp,16
ffffffffc0200338:	8082                	ret

ffffffffc020033a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033a:	1141                	addi	sp,sp,-16
ffffffffc020033c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033e:	f71ff0ef          	jal	ra,ffffffffc02002ae <print_stackframe>
    return 0;
}
ffffffffc0200342:	60a2                	ld	ra,8(sp)
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	0141                	addi	sp,sp,16
ffffffffc0200348:	8082                	ret

ffffffffc020034a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034a:	7115                	addi	sp,sp,-224
ffffffffc020034c:	ed5e                	sd	s7,152(sp)
ffffffffc020034e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200350:	00005517          	auipc	a0,0x5
ffffffffc0200354:	50850513          	addi	a0,a0,1288 # ffffffffc0205858 <etext+0x1d6>
kmonitor(struct trapframe *tf) {
ffffffffc0200358:	ed86                	sd	ra,216(sp)
ffffffffc020035a:	e9a2                	sd	s0,208(sp)
ffffffffc020035c:	e5a6                	sd	s1,200(sp)
ffffffffc020035e:	e1ca                	sd	s2,192(sp)
ffffffffc0200360:	fd4e                	sd	s3,184(sp)
ffffffffc0200362:	f952                	sd	s4,176(sp)
ffffffffc0200364:	f556                	sd	s5,168(sp)
ffffffffc0200366:	f15a                	sd	s6,160(sp)
ffffffffc0200368:	e962                	sd	s8,144(sp)
ffffffffc020036a:	e566                	sd	s9,136(sp)
ffffffffc020036c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036e:	e2bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200372:	00005517          	auipc	a0,0x5
ffffffffc0200376:	50e50513          	addi	a0,a0,1294 # ffffffffc0205880 <etext+0x1fe>
ffffffffc020037a:	e1fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (tf != NULL) {
ffffffffc020037e:	000b8563          	beqz	s7,ffffffffc0200388 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200382:	855e                	mv	a0,s7
ffffffffc0200384:	003000ef          	jal	ra,ffffffffc0200b86 <print_trapframe>
ffffffffc0200388:	00005c17          	auipc	s8,0x5
ffffffffc020038c:	568c0c13          	addi	s8,s8,1384 # ffffffffc02058f0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200390:	00005917          	auipc	s2,0x5
ffffffffc0200394:	51890913          	addi	s2,s2,1304 # ffffffffc02058a8 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200398:	00005497          	auipc	s1,0x5
ffffffffc020039c:	51848493          	addi	s1,s1,1304 # ffffffffc02058b0 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc02003a0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003a2:	00005b17          	auipc	s6,0x5
ffffffffc02003a6:	516b0b13          	addi	s6,s6,1302 # ffffffffc02058b8 <etext+0x236>
        argv[argc ++] = buf;
ffffffffc02003aa:	00005a17          	auipc	s4,0x5
ffffffffc02003ae:	42ea0a13          	addi	s4,s4,1070 # ffffffffc02057d8 <etext+0x156>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003b4:	854a                	mv	a0,s2
ffffffffc02003b6:	cf5ff0ef          	jal	ra,ffffffffc02000aa <readline>
ffffffffc02003ba:	842a                	mv	s0,a0
ffffffffc02003bc:	dd65                	beqz	a0,ffffffffc02003b4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003c2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c4:	e1bd                	bnez	a1,ffffffffc020042a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003c6:	fe0c87e3          	beqz	s9,ffffffffc02003b4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ca:	6582                	ld	a1,0(sp)
ffffffffc02003cc:	00005d17          	auipc	s10,0x5
ffffffffc02003d0:	524d0d13          	addi	s10,s10,1316 # ffffffffc02058f0 <commands>
        argv[argc ++] = buf;
ffffffffc02003d4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d6:	4401                	li	s0,0
ffffffffc02003d8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	224050ef          	jal	ra,ffffffffc02055fe <strcmp>
ffffffffc02003de:	c919                	beqz	a0,ffffffffc02003f4 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	2405                	addiw	s0,s0,1
ffffffffc02003e2:	0b540063          	beq	s0,s5,ffffffffc0200482 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e6:	000d3503          	ld	a0,0(s10)
ffffffffc02003ea:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ec:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ee:	210050ef          	jal	ra,ffffffffc02055fe <strcmp>
ffffffffc02003f2:	f57d                	bnez	a0,ffffffffc02003e0 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f4:	00141793          	slli	a5,s0,0x1
ffffffffc02003f8:	97a2                	add	a5,a5,s0
ffffffffc02003fa:	078e                	slli	a5,a5,0x3
ffffffffc02003fc:	97e2                	add	a5,a5,s8
ffffffffc02003fe:	6b9c                	ld	a5,16(a5)
ffffffffc0200400:	865e                	mv	a2,s7
ffffffffc0200402:	002c                	addi	a1,sp,8
ffffffffc0200404:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200408:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020040a:	fa0555e3          	bgez	a0,ffffffffc02003b4 <kmonitor+0x6a>
}
ffffffffc020040e:	60ee                	ld	ra,216(sp)
ffffffffc0200410:	644e                	ld	s0,208(sp)
ffffffffc0200412:	64ae                	ld	s1,200(sp)
ffffffffc0200414:	690e                	ld	s2,192(sp)
ffffffffc0200416:	79ea                	ld	s3,184(sp)
ffffffffc0200418:	7a4a                	ld	s4,176(sp)
ffffffffc020041a:	7aaa                	ld	s5,168(sp)
ffffffffc020041c:	7b0a                	ld	s6,160(sp)
ffffffffc020041e:	6bea                	ld	s7,152(sp)
ffffffffc0200420:	6c4a                	ld	s8,144(sp)
ffffffffc0200422:	6caa                	ld	s9,136(sp)
ffffffffc0200424:	6d0a                	ld	s10,128(sp)
ffffffffc0200426:	612d                	addi	sp,sp,224
ffffffffc0200428:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042a:	8526                	mv	a0,s1
ffffffffc020042c:	216050ef          	jal	ra,ffffffffc0205642 <strchr>
ffffffffc0200430:	c901                	beqz	a0,ffffffffc0200440 <kmonitor+0xf6>
ffffffffc0200432:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200436:	00040023          	sb	zero,0(s0)
ffffffffc020043a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043c:	d5c9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc020043e:	b7f5                	j	ffffffffc020042a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200440:	00044783          	lbu	a5,0(s0)
ffffffffc0200444:	d3c9                	beqz	a5,ffffffffc02003c6 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	033c8963          	beq	s9,s3,ffffffffc0200478 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020044a:	003c9793          	slli	a5,s9,0x3
ffffffffc020044e:	0118                	addi	a4,sp,128
ffffffffc0200450:	97ba                	add	a5,a5,a4
ffffffffc0200452:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020045a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020045c:	e591                	bnez	a1,ffffffffc0200468 <kmonitor+0x11e>
ffffffffc020045e:	b7b5                	j	ffffffffc02003ca <kmonitor+0x80>
ffffffffc0200460:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200464:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	d1a5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200468:	8526                	mv	a0,s1
ffffffffc020046a:	1d8050ef          	jal	ra,ffffffffc0205642 <strchr>
ffffffffc020046e:	d96d                	beqz	a0,ffffffffc0200460 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200470:	00044583          	lbu	a1,0(s0)
ffffffffc0200474:	d9a9                	beqz	a1,ffffffffc02003c6 <kmonitor+0x7c>
ffffffffc0200476:	bf55                	j	ffffffffc020042a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200478:	45c1                	li	a1,16
ffffffffc020047a:	855a                	mv	a0,s6
ffffffffc020047c:	d1dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0200480:	b7e9                	j	ffffffffc020044a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00005517          	auipc	a0,0x5
ffffffffc0200488:	45450513          	addi	a0,a0,1108 # ffffffffc02058d8 <etext+0x256>
ffffffffc020048c:	d0dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
ffffffffc0200490:	b715                	j	ffffffffc02003b4 <kmonitor+0x6a>

ffffffffc0200492 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200492:	000c6317          	auipc	t1,0xc6
ffffffffc0200496:	86e30313          	addi	t1,t1,-1938 # ffffffffc02c5d00 <is_panic>
ffffffffc020049a:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020049e:	715d                	addi	sp,sp,-80
ffffffffc02004a0:	ec06                	sd	ra,24(sp)
ffffffffc02004a2:	e822                	sd	s0,16(sp)
ffffffffc02004a4:	f436                	sd	a3,40(sp)
ffffffffc02004a6:	f83a                	sd	a4,48(sp)
ffffffffc02004a8:	fc3e                	sd	a5,56(sp)
ffffffffc02004aa:	e0c2                	sd	a6,64(sp)
ffffffffc02004ac:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004ae:	020e1a63          	bnez	t3,ffffffffc02004e2 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004b2:	4785                	li	a5,1
ffffffffc02004b4:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b8:	8432                	mv	s0,a2
ffffffffc02004ba:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004bc:	862e                	mv	a2,a1
ffffffffc02004be:	85aa                	mv	a1,a0
ffffffffc02004c0:	00005517          	auipc	a0,0x5
ffffffffc02004c4:	47850513          	addi	a0,a0,1144 # ffffffffc0205938 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c8:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004ca:	ccfff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ce:	65a2                	ld	a1,8(sp)
ffffffffc02004d0:	8522                	mv	a0,s0
ffffffffc02004d2:	ca7ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc02004d6:	00006517          	auipc	a0,0x6
ffffffffc02004da:	57a50513          	addi	a0,a0,1402 # ffffffffc0206a50 <default_pmm_manager+0x598>
ffffffffc02004de:	cbbff0ef          	jal	ra,ffffffffc0200198 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004e2:	4501                	li	a0,0
ffffffffc02004e4:	4581                	li	a1,0
ffffffffc02004e6:	4601                	li	a2,0
ffffffffc02004e8:	48a1                	li	a7,8
ffffffffc02004ea:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ee:	4a8000ef          	jal	ra,ffffffffc0200996 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	e57ff0ef          	jal	ra,ffffffffc020034a <kmonitor>
    while (1) {
ffffffffc02004f8:	bfed                	j	ffffffffc02004f2 <__panic+0x60>

ffffffffc02004fa <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	715d                	addi	sp,sp,-80
ffffffffc02004fc:	832e                	mv	t1,a1
ffffffffc02004fe:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200500:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200502:	8432                	mv	s0,a2
ffffffffc0200504:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200508:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020050a:	00005517          	auipc	a0,0x5
ffffffffc020050e:	44e50513          	addi	a0,a0,1102 # ffffffffc0205958 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200512:	ec06                	sd	ra,24(sp)
ffffffffc0200514:	f436                	sd	a3,40(sp)
ffffffffc0200516:	f83a                	sd	a4,48(sp)
ffffffffc0200518:	e0c2                	sd	a6,64(sp)
ffffffffc020051a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020051c:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051e:	c7bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200522:	65a2                	ld	a1,8(sp)
ffffffffc0200524:	8522                	mv	a0,s0
ffffffffc0200526:	c53ff0ef          	jal	ra,ffffffffc0200178 <vcprintf>
    cprintf("\n");
ffffffffc020052a:	00006517          	auipc	a0,0x6
ffffffffc020052e:	52650513          	addi	a0,a0,1318 # ffffffffc0206a50 <default_pmm_manager+0x598>
ffffffffc0200532:	c67ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    va_end(ap);
}
ffffffffc0200536:	60e2                	ld	ra,24(sp)
ffffffffc0200538:	6442                	ld	s0,16(sp)
ffffffffc020053a:	6161                	addi	sp,sp,80
ffffffffc020053c:	8082                	ret

ffffffffc020053e <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc020053e:	02000793          	li	a5,32
ffffffffc0200542:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200546:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054a:	67e1                	lui	a5,0x18
ffffffffc020054c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xbf78>
ffffffffc0200550:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200552:	4581                	li	a1,0
ffffffffc0200554:	4601                	li	a2,0
ffffffffc0200556:	4881                	li	a7,0
ffffffffc0200558:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	00005517          	auipc	a0,0x5
ffffffffc0200560:	41c50513          	addi	a0,a0,1052 # ffffffffc0205978 <commands+0x88>
    ticks = 0;
ffffffffc0200564:	000c5797          	auipc	a5,0xc5
ffffffffc0200568:	7a07b223          	sd	zero,1956(a5) # ffffffffc02c5d08 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056c:	b135                	j	ffffffffc0200198 <cprintf>

ffffffffc020056e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020056e:	8082                	ret

ffffffffc0200570 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200570:	100027f3          	csrr	a5,sstatus
ffffffffc0200574:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200576:	0ff57513          	zext.b	a0,a0
ffffffffc020057a:	e799                	bnez	a5,ffffffffc0200588 <cons_putc+0x18>
ffffffffc020057c:	4581                	li	a1,0
ffffffffc020057e:	4601                	li	a2,0
ffffffffc0200580:	4885                	li	a7,1
ffffffffc0200582:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc0200586:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200588:	1101                	addi	sp,sp,-32
ffffffffc020058a:	ec06                	sd	ra,24(sp)
ffffffffc020058c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020058e:	408000ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0200592:	6522                	ld	a0,8(sp)
ffffffffc0200594:	4581                	li	a1,0
ffffffffc0200596:	4601                	li	a2,0
ffffffffc0200598:	4885                	li	a7,1
ffffffffc020059a:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020059e:	60e2                	ld	ra,24(sp)
ffffffffc02005a0:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005a2:	a6fd                	j	ffffffffc0200990 <intr_enable>

ffffffffc02005a4 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005a4:	100027f3          	csrr	a5,sstatus
ffffffffc02005a8:	8b89                	andi	a5,a5,2
ffffffffc02005aa:	eb89                	bnez	a5,ffffffffc02005bc <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ac:	4501                	li	a0,0
ffffffffc02005ae:	4581                	li	a1,0
ffffffffc02005b0:	4601                	li	a2,0
ffffffffc02005b2:	4889                	li	a7,2
ffffffffc02005b4:	00000073          	ecall
ffffffffc02005b8:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005ba:	8082                	ret
int cons_getc(void) {
ffffffffc02005bc:	1101                	addi	sp,sp,-32
ffffffffc02005be:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005c0:	3d6000ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc02005c4:	4501                	li	a0,0
ffffffffc02005c6:	4581                	li	a1,0
ffffffffc02005c8:	4601                	li	a2,0
ffffffffc02005ca:	4889                	li	a7,2
ffffffffc02005cc:	00000073          	ecall
ffffffffc02005d0:	2501                	sext.w	a0,a0
ffffffffc02005d2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005d4:	3bc000ef          	jal	ra,ffffffffc0200990 <intr_enable>
}
ffffffffc02005d8:	60e2                	ld	ra,24(sp)
ffffffffc02005da:	6522                	ld	a0,8(sp)
ffffffffc02005dc:	6105                	addi	sp,sp,32
ffffffffc02005de:	8082                	ret

ffffffffc02005e0 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005e0:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02005e2:	00005517          	auipc	a0,0x5
ffffffffc02005e6:	3b650513          	addi	a0,a0,950 # ffffffffc0205998 <commands+0xa8>
void dtb_init(void) {
ffffffffc02005ea:	fc86                	sd	ra,120(sp)
ffffffffc02005ec:	f8a2                	sd	s0,112(sp)
ffffffffc02005ee:	e8d2                	sd	s4,80(sp)
ffffffffc02005f0:	f4a6                	sd	s1,104(sp)
ffffffffc02005f2:	f0ca                	sd	s2,96(sp)
ffffffffc02005f4:	ecce                	sd	s3,88(sp)
ffffffffc02005f6:	e4d6                	sd	s5,72(sp)
ffffffffc02005f8:	e0da                	sd	s6,64(sp)
ffffffffc02005fa:	fc5e                	sd	s7,56(sp)
ffffffffc02005fc:	f862                	sd	s8,48(sp)
ffffffffc02005fe:	f466                	sd	s9,40(sp)
ffffffffc0200600:	f06a                	sd	s10,32(sp)
ffffffffc0200602:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200604:	b95ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200608:	0000b597          	auipc	a1,0xb
ffffffffc020060c:	9f85b583          	ld	a1,-1544(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc0200610:	00005517          	auipc	a0,0x5
ffffffffc0200614:	39850513          	addi	a0,a0,920 # ffffffffc02059a8 <commands+0xb8>
ffffffffc0200618:	b81ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020061c:	0000b417          	auipc	s0,0xb
ffffffffc0200620:	9ec40413          	addi	s0,s0,-1556 # ffffffffc020b008 <boot_dtb>
ffffffffc0200624:	600c                	ld	a1,0(s0)
ffffffffc0200626:	00005517          	auipc	a0,0x5
ffffffffc020062a:	39250513          	addi	a0,a0,914 # ffffffffc02059b8 <commands+0xc8>
ffffffffc020062e:	b6bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200632:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200636:	00005517          	auipc	a0,0x5
ffffffffc020063a:	39a50513          	addi	a0,a0,922 # ffffffffc02059d0 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020063e:	120a0463          	beqz	s4,ffffffffc0200766 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200642:	57f5                	li	a5,-3
ffffffffc0200644:	07fa                	slli	a5,a5,0x1e
ffffffffc0200646:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020064a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200652:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200656:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200662:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200666:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200668:	8ec9                	or	a3,a3,a0
ffffffffc020066a:	0087979b          	slliw	a5,a5,0x8
ffffffffc020066e:	1b7d                	addi	s6,s6,-1
ffffffffc0200670:	0167f7b3          	and	a5,a5,s6
ffffffffc0200674:	8dd5                	or	a1,a1,a3
ffffffffc0200676:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200678:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067c:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020067e:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe1a165>
ffffffffc0200682:	10f59163          	bne	a1,a5,ffffffffc0200784 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200686:	471c                	lw	a5,8(a4)
ffffffffc0200688:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020068a:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200690:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200694:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200698:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069c:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ac:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	01146433          	or	s0,s0,a7
ffffffffc02006ba:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006be:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c4:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006c8:	8c49                	or	s0,s0,a0
ffffffffc02006ca:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ce:	00ca6a33          	or	s4,s4,a2
ffffffffc02006d2:	0167f7b3          	and	a5,a5,s6
ffffffffc02006d6:	8c55                	or	s0,s0,a3
ffffffffc02006d8:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006dc:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006de:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006e0:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006e2:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006e6:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006e8:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ea:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02006ee:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f0:	00005917          	auipc	s2,0x5
ffffffffc02006f4:	33090913          	addi	s2,s2,816 # ffffffffc0205a20 <commands+0x130>
ffffffffc02006f8:	49bd                	li	s3,15
        switch (token) {
ffffffffc02006fa:	4d91                	li	s11,4
ffffffffc02006fc:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006fe:	00005497          	auipc	s1,0x5
ffffffffc0200702:	31a48493          	addi	s1,s1,794 # ffffffffc0205a18 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200706:	000a2703          	lw	a4,0(s4)
ffffffffc020070a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200712:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200722:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200724:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200728:	0087171b          	slliw	a4,a4,0x8
ffffffffc020072c:	8fd5                	or	a5,a5,a3
ffffffffc020072e:	00eb7733          	and	a4,s6,a4
ffffffffc0200732:	8fd9                	or	a5,a5,a4
ffffffffc0200734:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200736:	09778c63          	beq	a5,s7,ffffffffc02007ce <dtb_init+0x1ee>
ffffffffc020073a:	00fbea63          	bltu	s7,a5,ffffffffc020074e <dtb_init+0x16e>
ffffffffc020073e:	07a78663          	beq	a5,s10,ffffffffc02007aa <dtb_init+0x1ca>
ffffffffc0200742:	4709                	li	a4,2
ffffffffc0200744:	00e79763          	bne	a5,a4,ffffffffc0200752 <dtb_init+0x172>
ffffffffc0200748:	4c81                	li	s9,0
ffffffffc020074a:	8a56                	mv	s4,s5
ffffffffc020074c:	bf6d                	j	ffffffffc0200706 <dtb_init+0x126>
ffffffffc020074e:	ffb78ee3          	beq	a5,s11,ffffffffc020074a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200752:	00005517          	auipc	a0,0x5
ffffffffc0200756:	34650513          	addi	a0,a0,838 # ffffffffc0205a98 <commands+0x1a8>
ffffffffc020075a:	a3fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020075e:	00005517          	auipc	a0,0x5
ffffffffc0200762:	37250513          	addi	a0,a0,882 # ffffffffc0205ad0 <commands+0x1e0>
}
ffffffffc0200766:	7446                	ld	s0,112(sp)
ffffffffc0200768:	70e6                	ld	ra,120(sp)
ffffffffc020076a:	74a6                	ld	s1,104(sp)
ffffffffc020076c:	7906                	ld	s2,96(sp)
ffffffffc020076e:	69e6                	ld	s3,88(sp)
ffffffffc0200770:	6a46                	ld	s4,80(sp)
ffffffffc0200772:	6aa6                	ld	s5,72(sp)
ffffffffc0200774:	6b06                	ld	s6,64(sp)
ffffffffc0200776:	7be2                	ld	s7,56(sp)
ffffffffc0200778:	7c42                	ld	s8,48(sp)
ffffffffc020077a:	7ca2                	ld	s9,40(sp)
ffffffffc020077c:	7d02                	ld	s10,32(sp)
ffffffffc020077e:	6de2                	ld	s11,24(sp)
ffffffffc0200780:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200782:	bc19                	j	ffffffffc0200198 <cprintf>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020079e:	00005517          	auipc	a0,0x5
ffffffffc02007a2:	25250513          	addi	a0,a0,594 # ffffffffc02059f0 <commands+0x100>
}
ffffffffc02007a6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007a8:	bac5                	j	ffffffffc0200198 <cprintf>
                int name_len = strlen(name);
ffffffffc02007aa:	8556                	mv	a0,s5
ffffffffc02007ac:	60b040ef          	jal	ra,ffffffffc02055b6 <strlen>
ffffffffc02007b0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007b2:	4619                	li	a2,6
ffffffffc02007b4:	85a6                	mv	a1,s1
ffffffffc02007b6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007b8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007ba:	663040ef          	jal	ra,ffffffffc020561c <strncmp>
ffffffffc02007be:	e111                	bnez	a0,ffffffffc02007c2 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007c0:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007c2:	0a91                	addi	s5,s5,4
ffffffffc02007c4:	9ad2                	add	s5,s5,s4
ffffffffc02007c6:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007ca:	8a56                	mv	s4,s5
ffffffffc02007cc:	bf2d                	j	ffffffffc0200706 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ce:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007d2:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d6:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007da:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007de:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007e2:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e6:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007ea:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ee:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007f6:	00eaeab3          	or	s5,s5,a4
ffffffffc02007fa:	00fb77b3          	and	a5,s6,a5
ffffffffc02007fe:	00faeab3          	or	s5,s5,a5
ffffffffc0200802:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200804:	000c9c63          	bnez	s9,ffffffffc020081c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200808:	1a82                	slli	s5,s5,0x20
ffffffffc020080a:	00368793          	addi	a5,a3,3
ffffffffc020080e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200812:	9abe                	add	s5,s5,a5
ffffffffc0200814:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200818:	8a56                	mv	s4,s5
ffffffffc020081a:	b5f5                	j	ffffffffc0200706 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020081c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200820:	85ca                	mv	a1,s2
ffffffffc0200822:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200824:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200828:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020082c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200830:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200834:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200838:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020083a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020083e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200842:	8d59                	or	a0,a0,a4
ffffffffc0200844:	00fb77b3          	and	a5,s6,a5
ffffffffc0200848:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020084a:	1502                	slli	a0,a0,0x20
ffffffffc020084c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020084e:	9522                	add	a0,a0,s0
ffffffffc0200850:	5af040ef          	jal	ra,ffffffffc02055fe <strcmp>
ffffffffc0200854:	66a2                	ld	a3,8(sp)
ffffffffc0200856:	f94d                	bnez	a0,ffffffffc0200808 <dtb_init+0x228>
ffffffffc0200858:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200808 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020085c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200860:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200864:	00005517          	auipc	a0,0x5
ffffffffc0200868:	1c450513          	addi	a0,a0,452 # ffffffffc0205a28 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020086c:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200870:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200874:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200878:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020087c:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200880:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200884:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200888:	0187d693          	srli	a3,a5,0x18
ffffffffc020088c:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200890:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200894:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200898:	0106561b          	srliw	a2,a2,0x10
ffffffffc020089c:	010f6f33          	or	t5,t5,a6
ffffffffc02008a0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008a4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ac:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008b0:	0186f6b3          	and	a3,a3,s8
ffffffffc02008b4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008b8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008bc:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008c0:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c4:	8361                	srli	a4,a4,0x18
ffffffffc02008c6:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ce:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008d2:	00cb7633          	and	a2,s6,a2
ffffffffc02008d6:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008da:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008de:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e6:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ea:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ee:	0088989b          	slliw	a7,a7,0x8
ffffffffc02008f2:	011b78b3          	and	a7,s6,a7
ffffffffc02008f6:	005eeeb3          	or	t4,t4,t0
ffffffffc02008fa:	00c6e733          	or	a4,a3,a2
ffffffffc02008fe:	006c6c33          	or	s8,s8,t1
ffffffffc0200902:	010b76b3          	and	a3,s6,a6
ffffffffc0200906:	00bb7b33          	and	s6,s6,a1
ffffffffc020090a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020090e:	016c6b33          	or	s6,s8,s6
ffffffffc0200912:	01146433          	or	s0,s0,a7
ffffffffc0200916:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200918:	1702                	slli	a4,a4,0x20
ffffffffc020091a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020091c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020091e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200920:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200922:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200926:	0167eb33          	or	s6,a5,s6
ffffffffc020092a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020092c:	86dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200930:	85a2                	mv	a1,s0
ffffffffc0200932:	00005517          	auipc	a0,0x5
ffffffffc0200936:	11650513          	addi	a0,a0,278 # ffffffffc0205a48 <commands+0x158>
ffffffffc020093a:	85fff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020093e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200942:	85da                	mv	a1,s6
ffffffffc0200944:	00005517          	auipc	a0,0x5
ffffffffc0200948:	11c50513          	addi	a0,a0,284 # ffffffffc0205a60 <commands+0x170>
ffffffffc020094c:	84dff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200950:	008b05b3          	add	a1,s6,s0
ffffffffc0200954:	15fd                	addi	a1,a1,-1
ffffffffc0200956:	00005517          	auipc	a0,0x5
ffffffffc020095a:	12a50513          	addi	a0,a0,298 # ffffffffc0205a80 <commands+0x190>
ffffffffc020095e:	83bff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	16e50513          	addi	a0,a0,366 # ffffffffc0205ad0 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc020096a:	000c5797          	auipc	a5,0xc5
ffffffffc020096e:	3a87b323          	sd	s0,934(a5) # ffffffffc02c5d10 <memory_base>
        memory_size = mem_size;
ffffffffc0200972:	000c5797          	auipc	a5,0xc5
ffffffffc0200976:	3b67b323          	sd	s6,934(a5) # ffffffffc02c5d18 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc020097a:	b3f5                	j	ffffffffc0200766 <dtb_init+0x186>

ffffffffc020097c <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020097c:	000c5517          	auipc	a0,0xc5
ffffffffc0200980:	39453503          	ld	a0,916(a0) # ffffffffc02c5d10 <memory_base>
ffffffffc0200984:	8082                	ret

ffffffffc0200986 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200986:	000c5517          	auipc	a0,0xc5
ffffffffc020098a:	39253503          	ld	a0,914(a0) # ffffffffc02c5d18 <memory_size>
ffffffffc020098e:	8082                	ret

ffffffffc0200990 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200990:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200994:	8082                	ret

ffffffffc0200996 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200996:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020099a:	8082                	ret

ffffffffc020099c <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020099c:	8082                	ret

ffffffffc020099e <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020099e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009a2:	00000797          	auipc	a5,0x0
ffffffffc02009a6:	41678793          	addi	a5,a5,1046 # ffffffffc0200db8 <__alltraps>
ffffffffc02009aa:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009ae:	000407b7          	lui	a5,0x40
ffffffffc02009b2:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009b6:	8082                	ret

ffffffffc02009b8 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009b8:	610c                	ld	a1,0(a0)
{
ffffffffc02009ba:	1141                	addi	sp,sp,-16
ffffffffc02009bc:	e022                	sd	s0,0(sp)
ffffffffc02009be:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009c0:	00005517          	auipc	a0,0x5
ffffffffc02009c4:	12850513          	addi	a0,a0,296 # ffffffffc0205ae8 <commands+0x1f8>
{
ffffffffc02009c8:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009ca:	fceff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ce:	640c                	ld	a1,8(s0)
ffffffffc02009d0:	00005517          	auipc	a0,0x5
ffffffffc02009d4:	13050513          	addi	a0,a0,304 # ffffffffc0205b00 <commands+0x210>
ffffffffc02009d8:	fc0ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009dc:	680c                	ld	a1,16(s0)
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	13a50513          	addi	a0,a0,314 # ffffffffc0205b18 <commands+0x228>
ffffffffc02009e6:	fb2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02009ea:	6c0c                	ld	a1,24(s0)
ffffffffc02009ec:	00005517          	auipc	a0,0x5
ffffffffc02009f0:	14450513          	addi	a0,a0,324 # ffffffffc0205b30 <commands+0x240>
ffffffffc02009f4:	fa4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02009f8:	700c                	ld	a1,32(s0)
ffffffffc02009fa:	00005517          	auipc	a0,0x5
ffffffffc02009fe:	14e50513          	addi	a0,a0,334 # ffffffffc0205b48 <commands+0x258>
ffffffffc0200a02:	f96ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a06:	740c                	ld	a1,40(s0)
ffffffffc0200a08:	00005517          	auipc	a0,0x5
ffffffffc0200a0c:	15850513          	addi	a0,a0,344 # ffffffffc0205b60 <commands+0x270>
ffffffffc0200a10:	f88ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a14:	780c                	ld	a1,48(s0)
ffffffffc0200a16:	00005517          	auipc	a0,0x5
ffffffffc0200a1a:	16250513          	addi	a0,a0,354 # ffffffffc0205b78 <commands+0x288>
ffffffffc0200a1e:	f7aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a22:	7c0c                	ld	a1,56(s0)
ffffffffc0200a24:	00005517          	auipc	a0,0x5
ffffffffc0200a28:	16c50513          	addi	a0,a0,364 # ffffffffc0205b90 <commands+0x2a0>
ffffffffc0200a2c:	f6cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a30:	602c                	ld	a1,64(s0)
ffffffffc0200a32:	00005517          	auipc	a0,0x5
ffffffffc0200a36:	17650513          	addi	a0,a0,374 # ffffffffc0205ba8 <commands+0x2b8>
ffffffffc0200a3a:	f5eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a3e:	642c                	ld	a1,72(s0)
ffffffffc0200a40:	00005517          	auipc	a0,0x5
ffffffffc0200a44:	18050513          	addi	a0,a0,384 # ffffffffc0205bc0 <commands+0x2d0>
ffffffffc0200a48:	f50ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a4c:	682c                	ld	a1,80(s0)
ffffffffc0200a4e:	00005517          	auipc	a0,0x5
ffffffffc0200a52:	18a50513          	addi	a0,a0,394 # ffffffffc0205bd8 <commands+0x2e8>
ffffffffc0200a56:	f42ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a5a:	6c2c                	ld	a1,88(s0)
ffffffffc0200a5c:	00005517          	auipc	a0,0x5
ffffffffc0200a60:	19450513          	addi	a0,a0,404 # ffffffffc0205bf0 <commands+0x300>
ffffffffc0200a64:	f34ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a68:	702c                	ld	a1,96(s0)
ffffffffc0200a6a:	00005517          	auipc	a0,0x5
ffffffffc0200a6e:	19e50513          	addi	a0,a0,414 # ffffffffc0205c08 <commands+0x318>
ffffffffc0200a72:	f26ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a76:	742c                	ld	a1,104(s0)
ffffffffc0200a78:	00005517          	auipc	a0,0x5
ffffffffc0200a7c:	1a850513          	addi	a0,a0,424 # ffffffffc0205c20 <commands+0x330>
ffffffffc0200a80:	f18ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a84:	782c                	ld	a1,112(s0)
ffffffffc0200a86:	00005517          	auipc	a0,0x5
ffffffffc0200a8a:	1b250513          	addi	a0,a0,434 # ffffffffc0205c38 <commands+0x348>
ffffffffc0200a8e:	f0aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a92:	7c2c                	ld	a1,120(s0)
ffffffffc0200a94:	00005517          	auipc	a0,0x5
ffffffffc0200a98:	1bc50513          	addi	a0,a0,444 # ffffffffc0205c50 <commands+0x360>
ffffffffc0200a9c:	efcff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200aa0:	604c                	ld	a1,128(s0)
ffffffffc0200aa2:	00005517          	auipc	a0,0x5
ffffffffc0200aa6:	1c650513          	addi	a0,a0,454 # ffffffffc0205c68 <commands+0x378>
ffffffffc0200aaa:	eeeff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200aae:	644c                	ld	a1,136(s0)
ffffffffc0200ab0:	00005517          	auipc	a0,0x5
ffffffffc0200ab4:	1d050513          	addi	a0,a0,464 # ffffffffc0205c80 <commands+0x390>
ffffffffc0200ab8:	ee0ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200abc:	684c                	ld	a1,144(s0)
ffffffffc0200abe:	00005517          	auipc	a0,0x5
ffffffffc0200ac2:	1da50513          	addi	a0,a0,474 # ffffffffc0205c98 <commands+0x3a8>
ffffffffc0200ac6:	ed2ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200aca:	6c4c                	ld	a1,152(s0)
ffffffffc0200acc:	00005517          	auipc	a0,0x5
ffffffffc0200ad0:	1e450513          	addi	a0,a0,484 # ffffffffc0205cb0 <commands+0x3c0>
ffffffffc0200ad4:	ec4ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200ad8:	704c                	ld	a1,160(s0)
ffffffffc0200ada:	00005517          	auipc	a0,0x5
ffffffffc0200ade:	1ee50513          	addi	a0,a0,494 # ffffffffc0205cc8 <commands+0x3d8>
ffffffffc0200ae2:	eb6ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200ae6:	744c                	ld	a1,168(s0)
ffffffffc0200ae8:	00005517          	auipc	a0,0x5
ffffffffc0200aec:	1f850513          	addi	a0,a0,504 # ffffffffc0205ce0 <commands+0x3f0>
ffffffffc0200af0:	ea8ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200af4:	784c                	ld	a1,176(s0)
ffffffffc0200af6:	00005517          	auipc	a0,0x5
ffffffffc0200afa:	20250513          	addi	a0,a0,514 # ffffffffc0205cf8 <commands+0x408>
ffffffffc0200afe:	e9aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b02:	7c4c                	ld	a1,184(s0)
ffffffffc0200b04:	00005517          	auipc	a0,0x5
ffffffffc0200b08:	20c50513          	addi	a0,a0,524 # ffffffffc0205d10 <commands+0x420>
ffffffffc0200b0c:	e8cff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b10:	606c                	ld	a1,192(s0)
ffffffffc0200b12:	00005517          	auipc	a0,0x5
ffffffffc0200b16:	21650513          	addi	a0,a0,534 # ffffffffc0205d28 <commands+0x438>
ffffffffc0200b1a:	e7eff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b1e:	646c                	ld	a1,200(s0)
ffffffffc0200b20:	00005517          	auipc	a0,0x5
ffffffffc0200b24:	22050513          	addi	a0,a0,544 # ffffffffc0205d40 <commands+0x450>
ffffffffc0200b28:	e70ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b2c:	686c                	ld	a1,208(s0)
ffffffffc0200b2e:	00005517          	auipc	a0,0x5
ffffffffc0200b32:	22a50513          	addi	a0,a0,554 # ffffffffc0205d58 <commands+0x468>
ffffffffc0200b36:	e62ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b3a:	6c6c                	ld	a1,216(s0)
ffffffffc0200b3c:	00005517          	auipc	a0,0x5
ffffffffc0200b40:	23450513          	addi	a0,a0,564 # ffffffffc0205d70 <commands+0x480>
ffffffffc0200b44:	e54ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b48:	706c                	ld	a1,224(s0)
ffffffffc0200b4a:	00005517          	auipc	a0,0x5
ffffffffc0200b4e:	23e50513          	addi	a0,a0,574 # ffffffffc0205d88 <commands+0x498>
ffffffffc0200b52:	e46ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b56:	746c                	ld	a1,232(s0)
ffffffffc0200b58:	00005517          	auipc	a0,0x5
ffffffffc0200b5c:	24850513          	addi	a0,a0,584 # ffffffffc0205da0 <commands+0x4b0>
ffffffffc0200b60:	e38ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b64:	786c                	ld	a1,240(s0)
ffffffffc0200b66:	00005517          	auipc	a0,0x5
ffffffffc0200b6a:	25250513          	addi	a0,a0,594 # ffffffffc0205db8 <commands+0x4c8>
ffffffffc0200b6e:	e2aff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b72:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b74:	6402                	ld	s0,0(sp)
ffffffffc0200b76:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b78:	00005517          	auipc	a0,0x5
ffffffffc0200b7c:	25850513          	addi	a0,a0,600 # ffffffffc0205dd0 <commands+0x4e0>
}
ffffffffc0200b80:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b82:	e16ff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200b86 <print_trapframe>:
{
ffffffffc0200b86:	1141                	addi	sp,sp,-16
ffffffffc0200b88:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b8a:	85aa                	mv	a1,a0
{
ffffffffc0200b8c:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	25a50513          	addi	a0,a0,602 # ffffffffc0205de8 <commands+0x4f8>
{
ffffffffc0200b96:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b98:	e00ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b9c:	8522                	mv	a0,s0
ffffffffc0200b9e:	e1bff0ef          	jal	ra,ffffffffc02009b8 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200ba2:	10043583          	ld	a1,256(s0)
ffffffffc0200ba6:	00005517          	auipc	a0,0x5
ffffffffc0200baa:	25a50513          	addi	a0,a0,602 # ffffffffc0205e00 <commands+0x510>
ffffffffc0200bae:	deaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bb2:	10843583          	ld	a1,264(s0)
ffffffffc0200bb6:	00005517          	auipc	a0,0x5
ffffffffc0200bba:	26250513          	addi	a0,a0,610 # ffffffffc0205e18 <commands+0x528>
ffffffffc0200bbe:	ddaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200bc2:	11043583          	ld	a1,272(s0)
ffffffffc0200bc6:	00005517          	auipc	a0,0x5
ffffffffc0200bca:	26a50513          	addi	a0,a0,618 # ffffffffc0205e30 <commands+0x540>
ffffffffc0200bce:	dcaff0ef          	jal	ra,ffffffffc0200198 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bd2:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bd6:	6402                	ld	s0,0(sp)
ffffffffc0200bd8:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bda:	00005517          	auipc	a0,0x5
ffffffffc0200bde:	26650513          	addi	a0,a0,614 # ffffffffc0205e40 <commands+0x550>
}
ffffffffc0200be2:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200be4:	db4ff06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0200be8 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200be8:	11853783          	ld	a5,280(a0)
ffffffffc0200bec:	472d                	li	a4,11
ffffffffc0200bee:	0786                	slli	a5,a5,0x1
ffffffffc0200bf0:	8385                	srli	a5,a5,0x1
ffffffffc0200bf2:	04f76a63          	bltu	a4,a5,ffffffffc0200c46 <interrupt_handler+0x5e>
ffffffffc0200bf6:	00005717          	auipc	a4,0x5
ffffffffc0200bfa:	30270713          	addi	a4,a4,770 # ffffffffc0205ef8 <commands+0x608>
ffffffffc0200bfe:	078a                	slli	a5,a5,0x2
ffffffffc0200c00:	97ba                	add	a5,a5,a4
ffffffffc0200c02:	439c                	lw	a5,0(a5)
ffffffffc0200c04:	97ba                	add	a5,a5,a4
ffffffffc0200c06:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c08:	00005517          	auipc	a0,0x5
ffffffffc0200c0c:	2b050513          	addi	a0,a0,688 # ffffffffc0205eb8 <commands+0x5c8>
ffffffffc0200c10:	d88ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c14:	00005517          	auipc	a0,0x5
ffffffffc0200c18:	28450513          	addi	a0,a0,644 # ffffffffc0205e98 <commands+0x5a8>
ffffffffc0200c1c:	d7cff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c20:	00005517          	auipc	a0,0x5
ffffffffc0200c24:	23850513          	addi	a0,a0,568 # ffffffffc0205e58 <commands+0x568>
ffffffffc0200c28:	d70ff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c2c:	00005517          	auipc	a0,0x5
ffffffffc0200c30:	24c50513          	addi	a0,a0,588 # ffffffffc0205e78 <commands+0x588>
ffffffffc0200c34:	d64ff06f          	j	ffffffffc0200198 <cprintf>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c38:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c3a:	00005517          	auipc	a0,0x5
ffffffffc0200c3e:	29e50513          	addi	a0,a0,670 # ffffffffc0205ed8 <commands+0x5e8>
ffffffffc0200c42:	d56ff06f          	j	ffffffffc0200198 <cprintf>
        print_trapframe(tf);
ffffffffc0200c46:	b781                	j	ffffffffc0200b86 <print_trapframe>

ffffffffc0200c48 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c48:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c4c:	1141                	addi	sp,sp,-16
ffffffffc0200c4e:	e022                	sd	s0,0(sp)
ffffffffc0200c50:	e406                	sd	ra,8(sp)
ffffffffc0200c52:	473d                	li	a4,15
ffffffffc0200c54:	842a                	mv	s0,a0
ffffffffc0200c56:	0af76b63          	bltu	a4,a5,ffffffffc0200d0c <exception_handler+0xc4>
ffffffffc0200c5a:	00005717          	auipc	a4,0x5
ffffffffc0200c5e:	45e70713          	addi	a4,a4,1118 # ffffffffc02060b8 <commands+0x7c8>
ffffffffc0200c62:	078a                	slli	a5,a5,0x2
ffffffffc0200c64:	97ba                	add	a5,a5,a4
ffffffffc0200c66:	439c                	lw	a5,0(a5)
ffffffffc0200c68:	97ba                	add	a5,a5,a4
ffffffffc0200c6a:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c6c:	00005517          	auipc	a0,0x5
ffffffffc0200c70:	3a450513          	addi	a0,a0,932 # ffffffffc0206010 <commands+0x720>
ffffffffc0200c74:	d24ff0ef          	jal	ra,ffffffffc0200198 <cprintf>
        tf->epc += 4;
ffffffffc0200c78:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c7c:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200c7e:	0791                	addi	a5,a5,4
ffffffffc0200c80:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200c84:	6402                	ld	s0,0(sp)
ffffffffc0200c86:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200c88:	4a80406f          	j	ffffffffc0205130 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	3a450513          	addi	a0,a0,932 # ffffffffc0206030 <commands+0x740>
}
ffffffffc0200c94:	6402                	ld	s0,0(sp)
ffffffffc0200c96:	60a2                	ld	ra,8(sp)
ffffffffc0200c98:	0141                	addi	sp,sp,16
        cprintf("Instruction access fault\n");
ffffffffc0200c9a:	cfeff06f          	j	ffffffffc0200198 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200c9e:	00005517          	auipc	a0,0x5
ffffffffc0200ca2:	3b250513          	addi	a0,a0,946 # ffffffffc0206050 <commands+0x760>
ffffffffc0200ca6:	b7fd                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200ca8:	00005517          	auipc	a0,0x5
ffffffffc0200cac:	3c850513          	addi	a0,a0,968 # ffffffffc0206070 <commands+0x780>
ffffffffc0200cb0:	b7d5                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Load page fault\n");
ffffffffc0200cb2:	00005517          	auipc	a0,0x5
ffffffffc0200cb6:	3d650513          	addi	a0,a0,982 # ffffffffc0206088 <commands+0x798>
ffffffffc0200cba:	bfe9                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200cbc:	00005517          	auipc	a0,0x5
ffffffffc0200cc0:	3e450513          	addi	a0,a0,996 # ffffffffc02060a0 <commands+0x7b0>
ffffffffc0200cc4:	bfc1                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200cc6:	00005517          	auipc	a0,0x5
ffffffffc0200cca:	26250513          	addi	a0,a0,610 # ffffffffc0205f28 <commands+0x638>
ffffffffc0200cce:	b7d9                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Instruction access fault\n");
ffffffffc0200cd0:	00005517          	auipc	a0,0x5
ffffffffc0200cd4:	27850513          	addi	a0,a0,632 # ffffffffc0205f48 <commands+0x658>
ffffffffc0200cd8:	bf75                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Illegal instruction\n");
ffffffffc0200cda:	00005517          	auipc	a0,0x5
ffffffffc0200cde:	28e50513          	addi	a0,a0,654 # ffffffffc0205f68 <commands+0x678>
ffffffffc0200ce2:	bf4d                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Breakpoint\n");
ffffffffc0200ce4:	00005517          	auipc	a0,0x5
ffffffffc0200ce8:	29c50513          	addi	a0,a0,668 # ffffffffc0205f80 <commands+0x690>
ffffffffc0200cec:	b765                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Load address misaligned\n");
ffffffffc0200cee:	00005517          	auipc	a0,0x5
ffffffffc0200cf2:	2a250513          	addi	a0,a0,674 # ffffffffc0205f90 <commands+0x6a0>
ffffffffc0200cf6:	bf79                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Load access fault\n");
ffffffffc0200cf8:	00005517          	auipc	a0,0x5
ffffffffc0200cfc:	2b850513          	addi	a0,a0,696 # ffffffffc0205fb0 <commands+0x6c0>
ffffffffc0200d00:	bf51                	j	ffffffffc0200c94 <exception_handler+0x4c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d02:	00005517          	auipc	a0,0x5
ffffffffc0200d06:	2f650513          	addi	a0,a0,758 # ffffffffc0205ff8 <commands+0x708>
ffffffffc0200d0a:	b769                	j	ffffffffc0200c94 <exception_handler+0x4c>
        print_trapframe(tf);
ffffffffc0200d0c:	8522                	mv	a0,s0
}
ffffffffc0200d0e:	6402                	ld	s0,0(sp)
ffffffffc0200d10:	60a2                	ld	ra,8(sp)
ffffffffc0200d12:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200d14:	bd8d                	j	ffffffffc0200b86 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d16:	00005617          	auipc	a2,0x5
ffffffffc0200d1a:	2b260613          	addi	a2,a2,690 # ffffffffc0205fc8 <commands+0x6d8>
ffffffffc0200d1e:	0b800593          	li	a1,184
ffffffffc0200d22:	00005517          	auipc	a0,0x5
ffffffffc0200d26:	2be50513          	addi	a0,a0,702 # ffffffffc0205fe0 <commands+0x6f0>
ffffffffc0200d2a:	f68ff0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0200d2e <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200d2e:	1101                	addi	sp,sp,-32
ffffffffc0200d30:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d32:	000c5417          	auipc	s0,0xc5
ffffffffc0200d36:	02640413          	addi	s0,s0,38 # ffffffffc02c5d58 <current>
ffffffffc0200d3a:	6018                	ld	a4,0(s0)
{
ffffffffc0200d3c:	ec06                	sd	ra,24(sp)
ffffffffc0200d3e:	e426                	sd	s1,8(sp)
ffffffffc0200d40:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d42:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200d46:	cf1d                	beqz	a4,ffffffffc0200d84 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d48:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d4c:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200d50:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d52:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d56:	0206c463          	bltz	a3,ffffffffc0200d7e <trap+0x50>
        exception_handler(tf);
ffffffffc0200d5a:	eefff0ef          	jal	ra,ffffffffc0200c48 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d5e:	601c                	ld	a5,0(s0)
ffffffffc0200d60:	0b27b023          	sd	s2,160(a5) # 400a0 <_binary_obj___user_matrix_out_size+0x33978>
        if (!in_kernel)
ffffffffc0200d64:	e499                	bnez	s1,ffffffffc0200d72 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200d66:	0b07a703          	lw	a4,176(a5)
ffffffffc0200d6a:	8b05                	andi	a4,a4,1
ffffffffc0200d6c:	e329                	bnez	a4,ffffffffc0200dae <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200d6e:	6f9c                	ld	a5,24(a5)
ffffffffc0200d70:	eb85                	bnez	a5,ffffffffc0200da0 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200d72:	60e2                	ld	ra,24(sp)
ffffffffc0200d74:	6442                	ld	s0,16(sp)
ffffffffc0200d76:	64a2                	ld	s1,8(sp)
ffffffffc0200d78:	6902                	ld	s2,0(sp)
ffffffffc0200d7a:	6105                	addi	sp,sp,32
ffffffffc0200d7c:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200d7e:	e6bff0ef          	jal	ra,ffffffffc0200be8 <interrupt_handler>
ffffffffc0200d82:	bff1                	j	ffffffffc0200d5e <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d84:	0006c863          	bltz	a3,ffffffffc0200d94 <trap+0x66>
}
ffffffffc0200d88:	6442                	ld	s0,16(sp)
ffffffffc0200d8a:	60e2                	ld	ra,24(sp)
ffffffffc0200d8c:	64a2                	ld	s1,8(sp)
ffffffffc0200d8e:	6902                	ld	s2,0(sp)
ffffffffc0200d90:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200d92:	bd5d                	j	ffffffffc0200c48 <exception_handler>
}
ffffffffc0200d94:	6442                	ld	s0,16(sp)
ffffffffc0200d96:	60e2                	ld	ra,24(sp)
ffffffffc0200d98:	64a2                	ld	s1,8(sp)
ffffffffc0200d9a:	6902                	ld	s2,0(sp)
ffffffffc0200d9c:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200d9e:	b5a9                	j	ffffffffc0200be8 <interrupt_handler>
}
ffffffffc0200da0:	6442                	ld	s0,16(sp)
ffffffffc0200da2:	60e2                	ld	ra,24(sp)
ffffffffc0200da4:	64a2                	ld	s1,8(sp)
ffffffffc0200da6:	6902                	ld	s2,0(sp)
ffffffffc0200da8:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200daa:	2480406f          	j	ffffffffc0204ff2 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200dae:	555d                	li	a0,-9
ffffffffc0200db0:	42a030ef          	jal	ra,ffffffffc02041da <do_exit>
            if (current->need_resched)
ffffffffc0200db4:	601c                	ld	a5,0(s0)
ffffffffc0200db6:	bf65                	j	ffffffffc0200d6e <trap+0x40>

ffffffffc0200db8 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200db8:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200dbc:	00011463          	bnez	sp,ffffffffc0200dc4 <__alltraps+0xc>
ffffffffc0200dc0:	14002173          	csrr	sp,sscratch
ffffffffc0200dc4:	712d                	addi	sp,sp,-288
ffffffffc0200dc6:	e002                	sd	zero,0(sp)
ffffffffc0200dc8:	e406                	sd	ra,8(sp)
ffffffffc0200dca:	ec0e                	sd	gp,24(sp)
ffffffffc0200dcc:	f012                	sd	tp,32(sp)
ffffffffc0200dce:	f416                	sd	t0,40(sp)
ffffffffc0200dd0:	f81a                	sd	t1,48(sp)
ffffffffc0200dd2:	fc1e                	sd	t2,56(sp)
ffffffffc0200dd4:	e0a2                	sd	s0,64(sp)
ffffffffc0200dd6:	e4a6                	sd	s1,72(sp)
ffffffffc0200dd8:	e8aa                	sd	a0,80(sp)
ffffffffc0200dda:	ecae                	sd	a1,88(sp)
ffffffffc0200ddc:	f0b2                	sd	a2,96(sp)
ffffffffc0200dde:	f4b6                	sd	a3,104(sp)
ffffffffc0200de0:	f8ba                	sd	a4,112(sp)
ffffffffc0200de2:	fcbe                	sd	a5,120(sp)
ffffffffc0200de4:	e142                	sd	a6,128(sp)
ffffffffc0200de6:	e546                	sd	a7,136(sp)
ffffffffc0200de8:	e94a                	sd	s2,144(sp)
ffffffffc0200dea:	ed4e                	sd	s3,152(sp)
ffffffffc0200dec:	f152                	sd	s4,160(sp)
ffffffffc0200dee:	f556                	sd	s5,168(sp)
ffffffffc0200df0:	f95a                	sd	s6,176(sp)
ffffffffc0200df2:	fd5e                	sd	s7,184(sp)
ffffffffc0200df4:	e1e2                	sd	s8,192(sp)
ffffffffc0200df6:	e5e6                	sd	s9,200(sp)
ffffffffc0200df8:	e9ea                	sd	s10,208(sp)
ffffffffc0200dfa:	edee                	sd	s11,216(sp)
ffffffffc0200dfc:	f1f2                	sd	t3,224(sp)
ffffffffc0200dfe:	f5f6                	sd	t4,232(sp)
ffffffffc0200e00:	f9fa                	sd	t5,240(sp)
ffffffffc0200e02:	fdfe                	sd	t6,248(sp)
ffffffffc0200e04:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e08:	100024f3          	csrr	s1,sstatus
ffffffffc0200e0c:	14102973          	csrr	s2,sepc
ffffffffc0200e10:	143029f3          	csrr	s3,stval
ffffffffc0200e14:	14202a73          	csrr	s4,scause
ffffffffc0200e18:	e822                	sd	s0,16(sp)
ffffffffc0200e1a:	e226                	sd	s1,256(sp)
ffffffffc0200e1c:	e64a                	sd	s2,264(sp)
ffffffffc0200e1e:	ea4e                	sd	s3,272(sp)
ffffffffc0200e20:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e22:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e24:	f0bff0ef          	jal	ra,ffffffffc0200d2e <trap>

ffffffffc0200e28 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e28:	6492                	ld	s1,256(sp)
ffffffffc0200e2a:	6932                	ld	s2,264(sp)
ffffffffc0200e2c:	1004f413          	andi	s0,s1,256
ffffffffc0200e30:	e401                	bnez	s0,ffffffffc0200e38 <__trapret+0x10>
ffffffffc0200e32:	1200                	addi	s0,sp,288
ffffffffc0200e34:	14041073          	csrw	sscratch,s0
ffffffffc0200e38:	10049073          	csrw	sstatus,s1
ffffffffc0200e3c:	14191073          	csrw	sepc,s2
ffffffffc0200e40:	60a2                	ld	ra,8(sp)
ffffffffc0200e42:	61e2                	ld	gp,24(sp)
ffffffffc0200e44:	7202                	ld	tp,32(sp)
ffffffffc0200e46:	72a2                	ld	t0,40(sp)
ffffffffc0200e48:	7342                	ld	t1,48(sp)
ffffffffc0200e4a:	73e2                	ld	t2,56(sp)
ffffffffc0200e4c:	6406                	ld	s0,64(sp)
ffffffffc0200e4e:	64a6                	ld	s1,72(sp)
ffffffffc0200e50:	6546                	ld	a0,80(sp)
ffffffffc0200e52:	65e6                	ld	a1,88(sp)
ffffffffc0200e54:	7606                	ld	a2,96(sp)
ffffffffc0200e56:	76a6                	ld	a3,104(sp)
ffffffffc0200e58:	7746                	ld	a4,112(sp)
ffffffffc0200e5a:	77e6                	ld	a5,120(sp)
ffffffffc0200e5c:	680a                	ld	a6,128(sp)
ffffffffc0200e5e:	68aa                	ld	a7,136(sp)
ffffffffc0200e60:	694a                	ld	s2,144(sp)
ffffffffc0200e62:	69ea                	ld	s3,152(sp)
ffffffffc0200e64:	7a0a                	ld	s4,160(sp)
ffffffffc0200e66:	7aaa                	ld	s5,168(sp)
ffffffffc0200e68:	7b4a                	ld	s6,176(sp)
ffffffffc0200e6a:	7bea                	ld	s7,184(sp)
ffffffffc0200e6c:	6c0e                	ld	s8,192(sp)
ffffffffc0200e6e:	6cae                	ld	s9,200(sp)
ffffffffc0200e70:	6d4e                	ld	s10,208(sp)
ffffffffc0200e72:	6dee                	ld	s11,216(sp)
ffffffffc0200e74:	7e0e                	ld	t3,224(sp)
ffffffffc0200e76:	7eae                	ld	t4,232(sp)
ffffffffc0200e78:	7f4e                	ld	t5,240(sp)
ffffffffc0200e7a:	7fee                	ld	t6,248(sp)
ffffffffc0200e7c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200e7e:	10200073          	sret

ffffffffc0200e82 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200e82:	812a                	mv	sp,a0
ffffffffc0200e84:	b755                	j	ffffffffc0200e28 <__trapret>

ffffffffc0200e86 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e86:	000c1797          	auipc	a5,0xc1
ffffffffc0200e8a:	e2278793          	addi	a5,a5,-478 # ffffffffc02c1ca8 <free_area>
ffffffffc0200e8e:	e79c                	sd	a5,8(a5)
ffffffffc0200e90:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e92:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e96:	8082                	ret

ffffffffc0200e98 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200e98:	000c1517          	auipc	a0,0xc1
ffffffffc0200e9c:	e2056503          	lwu	a0,-480(a0) # ffffffffc02c1cb8 <free_area+0x10>
ffffffffc0200ea0:	8082                	ret

ffffffffc0200ea2 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200ea2:	715d                	addi	sp,sp,-80
ffffffffc0200ea4:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ea6:	000c1417          	auipc	s0,0xc1
ffffffffc0200eaa:	e0240413          	addi	s0,s0,-510 # ffffffffc02c1ca8 <free_area>
ffffffffc0200eae:	641c                	ld	a5,8(s0)
ffffffffc0200eb0:	e486                	sd	ra,72(sp)
ffffffffc0200eb2:	fc26                	sd	s1,56(sp)
ffffffffc0200eb4:	f84a                	sd	s2,48(sp)
ffffffffc0200eb6:	f44e                	sd	s3,40(sp)
ffffffffc0200eb8:	f052                	sd	s4,32(sp)
ffffffffc0200eba:	ec56                	sd	s5,24(sp)
ffffffffc0200ebc:	e85a                	sd	s6,16(sp)
ffffffffc0200ebe:	e45e                	sd	s7,8(sp)
ffffffffc0200ec0:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ec2:	2a878d63          	beq	a5,s0,ffffffffc020117c <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200ec6:	4481                	li	s1,0
ffffffffc0200ec8:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200eca:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ece:	8b09                	andi	a4,a4,2
ffffffffc0200ed0:	2a070a63          	beqz	a4,ffffffffc0201184 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200ed4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ed8:	679c                	ld	a5,8(a5)
ffffffffc0200eda:	2905                	addiw	s2,s2,1
ffffffffc0200edc:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ede:	fe8796e3          	bne	a5,s0,ffffffffc0200eca <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200ee2:	89a6                	mv	s3,s1
ffffffffc0200ee4:	6df000ef          	jal	ra,ffffffffc0201dc2 <nr_free_pages>
ffffffffc0200ee8:	6f351e63          	bne	a0,s3,ffffffffc02015e4 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200eec:	4505                	li	a0,1
ffffffffc0200eee:	657000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200ef2:	8aaa                	mv	s5,a0
ffffffffc0200ef4:	42050863          	beqz	a0,ffffffffc0201324 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ef8:	4505                	li	a0,1
ffffffffc0200efa:	64b000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200efe:	89aa                	mv	s3,a0
ffffffffc0200f00:	70050263          	beqz	a0,ffffffffc0201604 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f04:	4505                	li	a0,1
ffffffffc0200f06:	63f000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200f0a:	8a2a                	mv	s4,a0
ffffffffc0200f0c:	48050c63          	beqz	a0,ffffffffc02013a4 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f10:	293a8a63          	beq	s5,s3,ffffffffc02011a4 <default_check+0x302>
ffffffffc0200f14:	28aa8863          	beq	s5,a0,ffffffffc02011a4 <default_check+0x302>
ffffffffc0200f18:	28a98663          	beq	s3,a0,ffffffffc02011a4 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f1c:	000aa783          	lw	a5,0(s5)
ffffffffc0200f20:	2a079263          	bnez	a5,ffffffffc02011c4 <default_check+0x322>
ffffffffc0200f24:	0009a783          	lw	a5,0(s3)
ffffffffc0200f28:	28079e63          	bnez	a5,ffffffffc02011c4 <default_check+0x322>
ffffffffc0200f2c:	411c                	lw	a5,0(a0)
ffffffffc0200f2e:	28079b63          	bnez	a5,ffffffffc02011c4 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f32:	000c5797          	auipc	a5,0xc5
ffffffffc0200f36:	e0e7b783          	ld	a5,-498(a5) # ffffffffc02c5d40 <pages>
ffffffffc0200f3a:	40fa8733          	sub	a4,s5,a5
ffffffffc0200f3e:	00007617          	auipc	a2,0x7
ffffffffc0200f42:	fc263603          	ld	a2,-62(a2) # ffffffffc0207f00 <nbase>
ffffffffc0200f46:	8719                	srai	a4,a4,0x6
ffffffffc0200f48:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f4a:	000c5697          	auipc	a3,0xc5
ffffffffc0200f4e:	dee6b683          	ld	a3,-530(a3) # ffffffffc02c5d38 <npage>
ffffffffc0200f52:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f54:	0732                	slli	a4,a4,0xc
ffffffffc0200f56:	28d77763          	bgeu	a4,a3,ffffffffc02011e4 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200f5a:	40f98733          	sub	a4,s3,a5
ffffffffc0200f5e:	8719                	srai	a4,a4,0x6
ffffffffc0200f60:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f62:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f64:	4cd77063          	bgeu	a4,a3,ffffffffc0201424 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200f68:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f6c:	8799                	srai	a5,a5,0x6
ffffffffc0200f6e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f70:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f72:	30d7f963          	bgeu	a5,a3,ffffffffc0201284 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200f76:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f78:	00043c03          	ld	s8,0(s0)
ffffffffc0200f7c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f80:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f84:	e400                	sd	s0,8(s0)
ffffffffc0200f86:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f88:	000c1797          	auipc	a5,0xc1
ffffffffc0200f8c:	d207a823          	sw	zero,-720(a5) # ffffffffc02c1cb8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f90:	5b5000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200f94:	2c051863          	bnez	a0,ffffffffc0201264 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200f98:	4585                	li	a1,1
ffffffffc0200f9a:	8556                	mv	a0,s5
ffffffffc0200f9c:	5e7000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    free_page(p1);
ffffffffc0200fa0:	4585                	li	a1,1
ffffffffc0200fa2:	854e                	mv	a0,s3
ffffffffc0200fa4:	5df000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    free_page(p2);
ffffffffc0200fa8:	4585                	li	a1,1
ffffffffc0200faa:	8552                	mv	a0,s4
ffffffffc0200fac:	5d7000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    assert(nr_free == 3);
ffffffffc0200fb0:	4818                	lw	a4,16(s0)
ffffffffc0200fb2:	478d                	li	a5,3
ffffffffc0200fb4:	28f71863          	bne	a4,a5,ffffffffc0201244 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fb8:	4505                	li	a0,1
ffffffffc0200fba:	58b000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200fbe:	89aa                	mv	s3,a0
ffffffffc0200fc0:	26050263          	beqz	a0,ffffffffc0201224 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	57f000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200fca:	8aaa                	mv	s5,a0
ffffffffc0200fcc:	3a050c63          	beqz	a0,ffffffffc0201384 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	573000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200fd6:	8a2a                	mv	s4,a0
ffffffffc0200fd8:	38050663          	beqz	a0,ffffffffc0201364 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200fdc:	4505                	li	a0,1
ffffffffc0200fde:	567000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200fe2:	36051163          	bnez	a0,ffffffffc0201344 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200fe6:	4585                	li	a1,1
ffffffffc0200fe8:	854e                	mv	a0,s3
ffffffffc0200fea:	599000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fee:	641c                	ld	a5,8(s0)
ffffffffc0200ff0:	20878a63          	beq	a5,s0,ffffffffc0201204 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	54f000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0200ffa:	30a99563          	bne	s3,a0,ffffffffc0201304 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200ffe:	4505                	li	a0,1
ffffffffc0201000:	545000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0201004:	2e051063          	bnez	a0,ffffffffc02012e4 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201008:	481c                	lw	a5,16(s0)
ffffffffc020100a:	2a079d63          	bnez	a5,ffffffffc02012c4 <default_check+0x422>
    free_page(p);
ffffffffc020100e:	854e                	mv	a0,s3
ffffffffc0201010:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201012:	01843023          	sd	s8,0(s0)
ffffffffc0201016:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020101a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020101e:	565000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    free_page(p1);
ffffffffc0201022:	4585                	li	a1,1
ffffffffc0201024:	8556                	mv	a0,s5
ffffffffc0201026:	55d000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    free_page(p2);
ffffffffc020102a:	4585                	li	a1,1
ffffffffc020102c:	8552                	mv	a0,s4
ffffffffc020102e:	555000ef          	jal	ra,ffffffffc0201d82 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201032:	4515                	li	a0,5
ffffffffc0201034:	511000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0201038:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020103a:	26050563          	beqz	a0,ffffffffc02012a4 <default_check+0x402>
ffffffffc020103e:	651c                	ld	a5,8(a0)
ffffffffc0201040:	8385                	srli	a5,a5,0x1
ffffffffc0201042:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201044:	54079063          	bnez	a5,ffffffffc0201584 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201048:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104a:	00043b03          	ld	s6,0(s0)
ffffffffc020104e:	00843a83          	ld	s5,8(s0)
ffffffffc0201052:	e000                	sd	s0,0(s0)
ffffffffc0201054:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201056:	4ef000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc020105a:	50051563          	bnez	a0,ffffffffc0201564 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020105e:	08098a13          	addi	s4,s3,128
ffffffffc0201062:	8552                	mv	a0,s4
ffffffffc0201064:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201066:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020106a:	000c1797          	auipc	a5,0xc1
ffffffffc020106e:	c407a723          	sw	zero,-946(a5) # ffffffffc02c1cb8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201072:	511000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201076:	4511                	li	a0,4
ffffffffc0201078:	4cd000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc020107c:	4c051463          	bnez	a0,ffffffffc0201544 <default_check+0x6a2>
ffffffffc0201080:	0889b783          	ld	a5,136(s3)
ffffffffc0201084:	8385                	srli	a5,a5,0x1
ffffffffc0201086:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201088:	48078e63          	beqz	a5,ffffffffc0201524 <default_check+0x682>
ffffffffc020108c:	0909a703          	lw	a4,144(s3)
ffffffffc0201090:	478d                	li	a5,3
ffffffffc0201092:	48f71963          	bne	a4,a5,ffffffffc0201524 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201096:	450d                	li	a0,3
ffffffffc0201098:	4ad000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc020109c:	8c2a                	mv	s8,a0
ffffffffc020109e:	46050363          	beqz	a0,ffffffffc0201504 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02010a2:	4505                	li	a0,1
ffffffffc02010a4:	4a1000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc02010a8:	42051e63          	bnez	a0,ffffffffc02014e4 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02010ac:	418a1c63          	bne	s4,s8,ffffffffc02014c4 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010b0:	4585                	li	a1,1
ffffffffc02010b2:	854e                	mv	a0,s3
ffffffffc02010b4:	4cf000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    free_pages(p1, 3);
ffffffffc02010b8:	458d                	li	a1,3
ffffffffc02010ba:	8552                	mv	a0,s4
ffffffffc02010bc:	4c7000ef          	jal	ra,ffffffffc0201d82 <free_pages>
ffffffffc02010c0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010c4:	04098c13          	addi	s8,s3,64
ffffffffc02010c8:	8385                	srli	a5,a5,0x1
ffffffffc02010ca:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010cc:	3c078c63          	beqz	a5,ffffffffc02014a4 <default_check+0x602>
ffffffffc02010d0:	0109a703          	lw	a4,16(s3)
ffffffffc02010d4:	4785                	li	a5,1
ffffffffc02010d6:	3cf71763          	bne	a4,a5,ffffffffc02014a4 <default_check+0x602>
ffffffffc02010da:	008a3783          	ld	a5,8(s4)
ffffffffc02010de:	8385                	srli	a5,a5,0x1
ffffffffc02010e0:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010e2:	3a078163          	beqz	a5,ffffffffc0201484 <default_check+0x5e2>
ffffffffc02010e6:	010a2703          	lw	a4,16(s4)
ffffffffc02010ea:	478d                	li	a5,3
ffffffffc02010ec:	38f71c63          	bne	a4,a5,ffffffffc0201484 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010f0:	4505                	li	a0,1
ffffffffc02010f2:	453000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc02010f6:	36a99763          	bne	s3,a0,ffffffffc0201464 <default_check+0x5c2>
    free_page(p0);
ffffffffc02010fa:	4585                	li	a1,1
ffffffffc02010fc:	487000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201100:	4509                	li	a0,2
ffffffffc0201102:	443000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0201106:	32aa1f63          	bne	s4,a0,ffffffffc0201444 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020110a:	4589                	li	a1,2
ffffffffc020110c:	477000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    free_page(p2);
ffffffffc0201110:	4585                	li	a1,1
ffffffffc0201112:	8562                	mv	a0,s8
ffffffffc0201114:	46f000ef          	jal	ra,ffffffffc0201d82 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201118:	4515                	li	a0,5
ffffffffc020111a:	42b000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc020111e:	89aa                	mv	s3,a0
ffffffffc0201120:	48050263          	beqz	a0,ffffffffc02015a4 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201124:	4505                	li	a0,1
ffffffffc0201126:	41f000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc020112a:	2c051d63          	bnez	a0,ffffffffc0201404 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020112e:	481c                	lw	a5,16(s0)
ffffffffc0201130:	2a079a63          	bnez	a5,ffffffffc02013e4 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201134:	4595                	li	a1,5
ffffffffc0201136:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201138:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020113c:	01643023          	sd	s6,0(s0)
ffffffffc0201140:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201144:	43f000ef          	jal	ra,ffffffffc0201d82 <free_pages>
    return listelm->next;
ffffffffc0201148:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020114a:	00878963          	beq	a5,s0,ffffffffc020115c <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020114e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201152:	679c                	ld	a5,8(a5)
ffffffffc0201154:	397d                	addiw	s2,s2,-1
ffffffffc0201156:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201158:	fe879be3          	bne	a5,s0,ffffffffc020114e <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc020115c:	26091463          	bnez	s2,ffffffffc02013c4 <default_check+0x522>
    assert(total == 0);
ffffffffc0201160:	46049263          	bnez	s1,ffffffffc02015c4 <default_check+0x722>
}
ffffffffc0201164:	60a6                	ld	ra,72(sp)
ffffffffc0201166:	6406                	ld	s0,64(sp)
ffffffffc0201168:	74e2                	ld	s1,56(sp)
ffffffffc020116a:	7942                	ld	s2,48(sp)
ffffffffc020116c:	79a2                	ld	s3,40(sp)
ffffffffc020116e:	7a02                	ld	s4,32(sp)
ffffffffc0201170:	6ae2                	ld	s5,24(sp)
ffffffffc0201172:	6b42                	ld	s6,16(sp)
ffffffffc0201174:	6ba2                	ld	s7,8(sp)
ffffffffc0201176:	6c02                	ld	s8,0(sp)
ffffffffc0201178:	6161                	addi	sp,sp,80
ffffffffc020117a:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc020117c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020117e:	4481                	li	s1,0
ffffffffc0201180:	4901                	li	s2,0
ffffffffc0201182:	b38d                	j	ffffffffc0200ee4 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201184:	00005697          	auipc	a3,0x5
ffffffffc0201188:	f7468693          	addi	a3,a3,-140 # ffffffffc02060f8 <commands+0x808>
ffffffffc020118c:	00005617          	auipc	a2,0x5
ffffffffc0201190:	f7c60613          	addi	a2,a2,-132 # ffffffffc0206108 <commands+0x818>
ffffffffc0201194:	11000593          	li	a1,272
ffffffffc0201198:	00005517          	auipc	a0,0x5
ffffffffc020119c:	f8850513          	addi	a0,a0,-120 # ffffffffc0206120 <commands+0x830>
ffffffffc02011a0:	af2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011a4:	00005697          	auipc	a3,0x5
ffffffffc02011a8:	01468693          	addi	a3,a3,20 # ffffffffc02061b8 <commands+0x8c8>
ffffffffc02011ac:	00005617          	auipc	a2,0x5
ffffffffc02011b0:	f5c60613          	addi	a2,a2,-164 # ffffffffc0206108 <commands+0x818>
ffffffffc02011b4:	0db00593          	li	a1,219
ffffffffc02011b8:	00005517          	auipc	a0,0x5
ffffffffc02011bc:	f6850513          	addi	a0,a0,-152 # ffffffffc0206120 <commands+0x830>
ffffffffc02011c0:	ad2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011c4:	00005697          	auipc	a3,0x5
ffffffffc02011c8:	01c68693          	addi	a3,a3,28 # ffffffffc02061e0 <commands+0x8f0>
ffffffffc02011cc:	00005617          	auipc	a2,0x5
ffffffffc02011d0:	f3c60613          	addi	a2,a2,-196 # ffffffffc0206108 <commands+0x818>
ffffffffc02011d4:	0dc00593          	li	a1,220
ffffffffc02011d8:	00005517          	auipc	a0,0x5
ffffffffc02011dc:	f4850513          	addi	a0,a0,-184 # ffffffffc0206120 <commands+0x830>
ffffffffc02011e0:	ab2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011e4:	00005697          	auipc	a3,0x5
ffffffffc02011e8:	03c68693          	addi	a3,a3,60 # ffffffffc0206220 <commands+0x930>
ffffffffc02011ec:	00005617          	auipc	a2,0x5
ffffffffc02011f0:	f1c60613          	addi	a2,a2,-228 # ffffffffc0206108 <commands+0x818>
ffffffffc02011f4:	0de00593          	li	a1,222
ffffffffc02011f8:	00005517          	auipc	a0,0x5
ffffffffc02011fc:	f2850513          	addi	a0,a0,-216 # ffffffffc0206120 <commands+0x830>
ffffffffc0201200:	a92ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201204:	00005697          	auipc	a3,0x5
ffffffffc0201208:	0a468693          	addi	a3,a3,164 # ffffffffc02062a8 <commands+0x9b8>
ffffffffc020120c:	00005617          	auipc	a2,0x5
ffffffffc0201210:	efc60613          	addi	a2,a2,-260 # ffffffffc0206108 <commands+0x818>
ffffffffc0201214:	0f700593          	li	a1,247
ffffffffc0201218:	00005517          	auipc	a0,0x5
ffffffffc020121c:	f0850513          	addi	a0,a0,-248 # ffffffffc0206120 <commands+0x830>
ffffffffc0201220:	a72ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201224:	00005697          	auipc	a3,0x5
ffffffffc0201228:	f3468693          	addi	a3,a3,-204 # ffffffffc0206158 <commands+0x868>
ffffffffc020122c:	00005617          	auipc	a2,0x5
ffffffffc0201230:	edc60613          	addi	a2,a2,-292 # ffffffffc0206108 <commands+0x818>
ffffffffc0201234:	0f000593          	li	a1,240
ffffffffc0201238:	00005517          	auipc	a0,0x5
ffffffffc020123c:	ee850513          	addi	a0,a0,-280 # ffffffffc0206120 <commands+0x830>
ffffffffc0201240:	a52ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 3);
ffffffffc0201244:	00005697          	auipc	a3,0x5
ffffffffc0201248:	05468693          	addi	a3,a3,84 # ffffffffc0206298 <commands+0x9a8>
ffffffffc020124c:	00005617          	auipc	a2,0x5
ffffffffc0201250:	ebc60613          	addi	a2,a2,-324 # ffffffffc0206108 <commands+0x818>
ffffffffc0201254:	0ee00593          	li	a1,238
ffffffffc0201258:	00005517          	auipc	a0,0x5
ffffffffc020125c:	ec850513          	addi	a0,a0,-312 # ffffffffc0206120 <commands+0x830>
ffffffffc0201260:	a32ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201264:	00005697          	auipc	a3,0x5
ffffffffc0201268:	01c68693          	addi	a3,a3,28 # ffffffffc0206280 <commands+0x990>
ffffffffc020126c:	00005617          	auipc	a2,0x5
ffffffffc0201270:	e9c60613          	addi	a2,a2,-356 # ffffffffc0206108 <commands+0x818>
ffffffffc0201274:	0e900593          	li	a1,233
ffffffffc0201278:	00005517          	auipc	a0,0x5
ffffffffc020127c:	ea850513          	addi	a0,a0,-344 # ffffffffc0206120 <commands+0x830>
ffffffffc0201280:	a12ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201284:	00005697          	auipc	a3,0x5
ffffffffc0201288:	fdc68693          	addi	a3,a3,-36 # ffffffffc0206260 <commands+0x970>
ffffffffc020128c:	00005617          	auipc	a2,0x5
ffffffffc0201290:	e7c60613          	addi	a2,a2,-388 # ffffffffc0206108 <commands+0x818>
ffffffffc0201294:	0e000593          	li	a1,224
ffffffffc0201298:	00005517          	auipc	a0,0x5
ffffffffc020129c:	e8850513          	addi	a0,a0,-376 # ffffffffc0206120 <commands+0x830>
ffffffffc02012a0:	9f2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 != NULL);
ffffffffc02012a4:	00005697          	auipc	a3,0x5
ffffffffc02012a8:	04c68693          	addi	a3,a3,76 # ffffffffc02062f0 <commands+0xa00>
ffffffffc02012ac:	00005617          	auipc	a2,0x5
ffffffffc02012b0:	e5c60613          	addi	a2,a2,-420 # ffffffffc0206108 <commands+0x818>
ffffffffc02012b4:	11800593          	li	a1,280
ffffffffc02012b8:	00005517          	auipc	a0,0x5
ffffffffc02012bc:	e6850513          	addi	a0,a0,-408 # ffffffffc0206120 <commands+0x830>
ffffffffc02012c0:	9d2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc02012c4:	00005697          	auipc	a3,0x5
ffffffffc02012c8:	01c68693          	addi	a3,a3,28 # ffffffffc02062e0 <commands+0x9f0>
ffffffffc02012cc:	00005617          	auipc	a2,0x5
ffffffffc02012d0:	e3c60613          	addi	a2,a2,-452 # ffffffffc0206108 <commands+0x818>
ffffffffc02012d4:	0fd00593          	li	a1,253
ffffffffc02012d8:	00005517          	auipc	a0,0x5
ffffffffc02012dc:	e4850513          	addi	a0,a0,-440 # ffffffffc0206120 <commands+0x830>
ffffffffc02012e0:	9b2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e4:	00005697          	auipc	a3,0x5
ffffffffc02012e8:	f9c68693          	addi	a3,a3,-100 # ffffffffc0206280 <commands+0x990>
ffffffffc02012ec:	00005617          	auipc	a2,0x5
ffffffffc02012f0:	e1c60613          	addi	a2,a2,-484 # ffffffffc0206108 <commands+0x818>
ffffffffc02012f4:	0fb00593          	li	a1,251
ffffffffc02012f8:	00005517          	auipc	a0,0x5
ffffffffc02012fc:	e2850513          	addi	a0,a0,-472 # ffffffffc0206120 <commands+0x830>
ffffffffc0201300:	992ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201304:	00005697          	auipc	a3,0x5
ffffffffc0201308:	fbc68693          	addi	a3,a3,-68 # ffffffffc02062c0 <commands+0x9d0>
ffffffffc020130c:	00005617          	auipc	a2,0x5
ffffffffc0201310:	dfc60613          	addi	a2,a2,-516 # ffffffffc0206108 <commands+0x818>
ffffffffc0201314:	0fa00593          	li	a1,250
ffffffffc0201318:	00005517          	auipc	a0,0x5
ffffffffc020131c:	e0850513          	addi	a0,a0,-504 # ffffffffc0206120 <commands+0x830>
ffffffffc0201320:	972ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201324:	00005697          	auipc	a3,0x5
ffffffffc0201328:	e3468693          	addi	a3,a3,-460 # ffffffffc0206158 <commands+0x868>
ffffffffc020132c:	00005617          	auipc	a2,0x5
ffffffffc0201330:	ddc60613          	addi	a2,a2,-548 # ffffffffc0206108 <commands+0x818>
ffffffffc0201334:	0d700593          	li	a1,215
ffffffffc0201338:	00005517          	auipc	a0,0x5
ffffffffc020133c:	de850513          	addi	a0,a0,-536 # ffffffffc0206120 <commands+0x830>
ffffffffc0201340:	952ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201344:	00005697          	auipc	a3,0x5
ffffffffc0201348:	f3c68693          	addi	a3,a3,-196 # ffffffffc0206280 <commands+0x990>
ffffffffc020134c:	00005617          	auipc	a2,0x5
ffffffffc0201350:	dbc60613          	addi	a2,a2,-580 # ffffffffc0206108 <commands+0x818>
ffffffffc0201354:	0f400593          	li	a1,244
ffffffffc0201358:	00005517          	auipc	a0,0x5
ffffffffc020135c:	dc850513          	addi	a0,a0,-568 # ffffffffc0206120 <commands+0x830>
ffffffffc0201360:	932ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201364:	00005697          	auipc	a3,0x5
ffffffffc0201368:	e3468693          	addi	a3,a3,-460 # ffffffffc0206198 <commands+0x8a8>
ffffffffc020136c:	00005617          	auipc	a2,0x5
ffffffffc0201370:	d9c60613          	addi	a2,a2,-612 # ffffffffc0206108 <commands+0x818>
ffffffffc0201374:	0f200593          	li	a1,242
ffffffffc0201378:	00005517          	auipc	a0,0x5
ffffffffc020137c:	da850513          	addi	a0,a0,-600 # ffffffffc0206120 <commands+0x830>
ffffffffc0201380:	912ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201384:	00005697          	auipc	a3,0x5
ffffffffc0201388:	df468693          	addi	a3,a3,-524 # ffffffffc0206178 <commands+0x888>
ffffffffc020138c:	00005617          	auipc	a2,0x5
ffffffffc0201390:	d7c60613          	addi	a2,a2,-644 # ffffffffc0206108 <commands+0x818>
ffffffffc0201394:	0f100593          	li	a1,241
ffffffffc0201398:	00005517          	auipc	a0,0x5
ffffffffc020139c:	d8850513          	addi	a0,a0,-632 # ffffffffc0206120 <commands+0x830>
ffffffffc02013a0:	8f2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013a4:	00005697          	auipc	a3,0x5
ffffffffc02013a8:	df468693          	addi	a3,a3,-524 # ffffffffc0206198 <commands+0x8a8>
ffffffffc02013ac:	00005617          	auipc	a2,0x5
ffffffffc02013b0:	d5c60613          	addi	a2,a2,-676 # ffffffffc0206108 <commands+0x818>
ffffffffc02013b4:	0d900593          	li	a1,217
ffffffffc02013b8:	00005517          	auipc	a0,0x5
ffffffffc02013bc:	d6850513          	addi	a0,a0,-664 # ffffffffc0206120 <commands+0x830>
ffffffffc02013c0:	8d2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(count == 0);
ffffffffc02013c4:	00005697          	auipc	a3,0x5
ffffffffc02013c8:	07c68693          	addi	a3,a3,124 # ffffffffc0206440 <commands+0xb50>
ffffffffc02013cc:	00005617          	auipc	a2,0x5
ffffffffc02013d0:	d3c60613          	addi	a2,a2,-708 # ffffffffc0206108 <commands+0x818>
ffffffffc02013d4:	14600593          	li	a1,326
ffffffffc02013d8:	00005517          	auipc	a0,0x5
ffffffffc02013dc:	d4850513          	addi	a0,a0,-696 # ffffffffc0206120 <commands+0x830>
ffffffffc02013e0:	8b2ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free == 0);
ffffffffc02013e4:	00005697          	auipc	a3,0x5
ffffffffc02013e8:	efc68693          	addi	a3,a3,-260 # ffffffffc02062e0 <commands+0x9f0>
ffffffffc02013ec:	00005617          	auipc	a2,0x5
ffffffffc02013f0:	d1c60613          	addi	a2,a2,-740 # ffffffffc0206108 <commands+0x818>
ffffffffc02013f4:	13a00593          	li	a1,314
ffffffffc02013f8:	00005517          	auipc	a0,0x5
ffffffffc02013fc:	d2850513          	addi	a0,a0,-728 # ffffffffc0206120 <commands+0x830>
ffffffffc0201400:	892ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201404:	00005697          	auipc	a3,0x5
ffffffffc0201408:	e7c68693          	addi	a3,a3,-388 # ffffffffc0206280 <commands+0x990>
ffffffffc020140c:	00005617          	auipc	a2,0x5
ffffffffc0201410:	cfc60613          	addi	a2,a2,-772 # ffffffffc0206108 <commands+0x818>
ffffffffc0201414:	13800593          	li	a1,312
ffffffffc0201418:	00005517          	auipc	a0,0x5
ffffffffc020141c:	d0850513          	addi	a0,a0,-760 # ffffffffc0206120 <commands+0x830>
ffffffffc0201420:	872ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201424:	00005697          	auipc	a3,0x5
ffffffffc0201428:	e1c68693          	addi	a3,a3,-484 # ffffffffc0206240 <commands+0x950>
ffffffffc020142c:	00005617          	auipc	a2,0x5
ffffffffc0201430:	cdc60613          	addi	a2,a2,-804 # ffffffffc0206108 <commands+0x818>
ffffffffc0201434:	0df00593          	li	a1,223
ffffffffc0201438:	00005517          	auipc	a0,0x5
ffffffffc020143c:	ce850513          	addi	a0,a0,-792 # ffffffffc0206120 <commands+0x830>
ffffffffc0201440:	852ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201444:	00005697          	auipc	a3,0x5
ffffffffc0201448:	fbc68693          	addi	a3,a3,-68 # ffffffffc0206400 <commands+0xb10>
ffffffffc020144c:	00005617          	auipc	a2,0x5
ffffffffc0201450:	cbc60613          	addi	a2,a2,-836 # ffffffffc0206108 <commands+0x818>
ffffffffc0201454:	13200593          	li	a1,306
ffffffffc0201458:	00005517          	auipc	a0,0x5
ffffffffc020145c:	cc850513          	addi	a0,a0,-824 # ffffffffc0206120 <commands+0x830>
ffffffffc0201460:	832ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201464:	00005697          	auipc	a3,0x5
ffffffffc0201468:	f7c68693          	addi	a3,a3,-132 # ffffffffc02063e0 <commands+0xaf0>
ffffffffc020146c:	00005617          	auipc	a2,0x5
ffffffffc0201470:	c9c60613          	addi	a2,a2,-868 # ffffffffc0206108 <commands+0x818>
ffffffffc0201474:	13000593          	li	a1,304
ffffffffc0201478:	00005517          	auipc	a0,0x5
ffffffffc020147c:	ca850513          	addi	a0,a0,-856 # ffffffffc0206120 <commands+0x830>
ffffffffc0201480:	812ff0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201484:	00005697          	auipc	a3,0x5
ffffffffc0201488:	f3468693          	addi	a3,a3,-204 # ffffffffc02063b8 <commands+0xac8>
ffffffffc020148c:	00005617          	auipc	a2,0x5
ffffffffc0201490:	c7c60613          	addi	a2,a2,-900 # ffffffffc0206108 <commands+0x818>
ffffffffc0201494:	12e00593          	li	a1,302
ffffffffc0201498:	00005517          	auipc	a0,0x5
ffffffffc020149c:	c8850513          	addi	a0,a0,-888 # ffffffffc0206120 <commands+0x830>
ffffffffc02014a0:	ff3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014a4:	00005697          	auipc	a3,0x5
ffffffffc02014a8:	eec68693          	addi	a3,a3,-276 # ffffffffc0206390 <commands+0xaa0>
ffffffffc02014ac:	00005617          	auipc	a2,0x5
ffffffffc02014b0:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206108 <commands+0x818>
ffffffffc02014b4:	12d00593          	li	a1,301
ffffffffc02014b8:	00005517          	auipc	a0,0x5
ffffffffc02014bc:	c6850513          	addi	a0,a0,-920 # ffffffffc0206120 <commands+0x830>
ffffffffc02014c0:	fd3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014c4:	00005697          	auipc	a3,0x5
ffffffffc02014c8:	ebc68693          	addi	a3,a3,-324 # ffffffffc0206380 <commands+0xa90>
ffffffffc02014cc:	00005617          	auipc	a2,0x5
ffffffffc02014d0:	c3c60613          	addi	a2,a2,-964 # ffffffffc0206108 <commands+0x818>
ffffffffc02014d4:	12800593          	li	a1,296
ffffffffc02014d8:	00005517          	auipc	a0,0x5
ffffffffc02014dc:	c4850513          	addi	a0,a0,-952 # ffffffffc0206120 <commands+0x830>
ffffffffc02014e0:	fb3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e4:	00005697          	auipc	a3,0x5
ffffffffc02014e8:	d9c68693          	addi	a3,a3,-612 # ffffffffc0206280 <commands+0x990>
ffffffffc02014ec:	00005617          	auipc	a2,0x5
ffffffffc02014f0:	c1c60613          	addi	a2,a2,-996 # ffffffffc0206108 <commands+0x818>
ffffffffc02014f4:	12700593          	li	a1,295
ffffffffc02014f8:	00005517          	auipc	a0,0x5
ffffffffc02014fc:	c2850513          	addi	a0,a0,-984 # ffffffffc0206120 <commands+0x830>
ffffffffc0201500:	f93fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201504:	00005697          	auipc	a3,0x5
ffffffffc0201508:	e5c68693          	addi	a3,a3,-420 # ffffffffc0206360 <commands+0xa70>
ffffffffc020150c:	00005617          	auipc	a2,0x5
ffffffffc0201510:	bfc60613          	addi	a2,a2,-1028 # ffffffffc0206108 <commands+0x818>
ffffffffc0201514:	12600593          	li	a1,294
ffffffffc0201518:	00005517          	auipc	a0,0x5
ffffffffc020151c:	c0850513          	addi	a0,a0,-1016 # ffffffffc0206120 <commands+0x830>
ffffffffc0201520:	f73fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201524:	00005697          	auipc	a3,0x5
ffffffffc0201528:	e0c68693          	addi	a3,a3,-500 # ffffffffc0206330 <commands+0xa40>
ffffffffc020152c:	00005617          	auipc	a2,0x5
ffffffffc0201530:	bdc60613          	addi	a2,a2,-1060 # ffffffffc0206108 <commands+0x818>
ffffffffc0201534:	12500593          	li	a1,293
ffffffffc0201538:	00005517          	auipc	a0,0x5
ffffffffc020153c:	be850513          	addi	a0,a0,-1048 # ffffffffc0206120 <commands+0x830>
ffffffffc0201540:	f53fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201544:	00005697          	auipc	a3,0x5
ffffffffc0201548:	dd468693          	addi	a3,a3,-556 # ffffffffc0206318 <commands+0xa28>
ffffffffc020154c:	00005617          	auipc	a2,0x5
ffffffffc0201550:	bbc60613          	addi	a2,a2,-1092 # ffffffffc0206108 <commands+0x818>
ffffffffc0201554:	12400593          	li	a1,292
ffffffffc0201558:	00005517          	auipc	a0,0x5
ffffffffc020155c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0206120 <commands+0x830>
ffffffffc0201560:	f33fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201564:	00005697          	auipc	a3,0x5
ffffffffc0201568:	d1c68693          	addi	a3,a3,-740 # ffffffffc0206280 <commands+0x990>
ffffffffc020156c:	00005617          	auipc	a2,0x5
ffffffffc0201570:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0206108 <commands+0x818>
ffffffffc0201574:	11e00593          	li	a1,286
ffffffffc0201578:	00005517          	auipc	a0,0x5
ffffffffc020157c:	ba850513          	addi	a0,a0,-1112 # ffffffffc0206120 <commands+0x830>
ffffffffc0201580:	f13fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201584:	00005697          	auipc	a3,0x5
ffffffffc0201588:	d7c68693          	addi	a3,a3,-644 # ffffffffc0206300 <commands+0xa10>
ffffffffc020158c:	00005617          	auipc	a2,0x5
ffffffffc0201590:	b7c60613          	addi	a2,a2,-1156 # ffffffffc0206108 <commands+0x818>
ffffffffc0201594:	11900593          	li	a1,281
ffffffffc0201598:	00005517          	auipc	a0,0x5
ffffffffc020159c:	b8850513          	addi	a0,a0,-1144 # ffffffffc0206120 <commands+0x830>
ffffffffc02015a0:	ef3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015a4:	00005697          	auipc	a3,0x5
ffffffffc02015a8:	e7c68693          	addi	a3,a3,-388 # ffffffffc0206420 <commands+0xb30>
ffffffffc02015ac:	00005617          	auipc	a2,0x5
ffffffffc02015b0:	b5c60613          	addi	a2,a2,-1188 # ffffffffc0206108 <commands+0x818>
ffffffffc02015b4:	13700593          	li	a1,311
ffffffffc02015b8:	00005517          	auipc	a0,0x5
ffffffffc02015bc:	b6850513          	addi	a0,a0,-1176 # ffffffffc0206120 <commands+0x830>
ffffffffc02015c0:	ed3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == 0);
ffffffffc02015c4:	00005697          	auipc	a3,0x5
ffffffffc02015c8:	e8c68693          	addi	a3,a3,-372 # ffffffffc0206450 <commands+0xb60>
ffffffffc02015cc:	00005617          	auipc	a2,0x5
ffffffffc02015d0:	b3c60613          	addi	a2,a2,-1220 # ffffffffc0206108 <commands+0x818>
ffffffffc02015d4:	14700593          	li	a1,327
ffffffffc02015d8:	00005517          	auipc	a0,0x5
ffffffffc02015dc:	b4850513          	addi	a0,a0,-1208 # ffffffffc0206120 <commands+0x830>
ffffffffc02015e0:	eb3fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(total == nr_free_pages());
ffffffffc02015e4:	00005697          	auipc	a3,0x5
ffffffffc02015e8:	b5468693          	addi	a3,a3,-1196 # ffffffffc0206138 <commands+0x848>
ffffffffc02015ec:	00005617          	auipc	a2,0x5
ffffffffc02015f0:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0206108 <commands+0x818>
ffffffffc02015f4:	11300593          	li	a1,275
ffffffffc02015f8:	00005517          	auipc	a0,0x5
ffffffffc02015fc:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206120 <commands+0x830>
ffffffffc0201600:	e93fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201604:	00005697          	auipc	a3,0x5
ffffffffc0201608:	b7468693          	addi	a3,a3,-1164 # ffffffffc0206178 <commands+0x888>
ffffffffc020160c:	00005617          	auipc	a2,0x5
ffffffffc0201610:	afc60613          	addi	a2,a2,-1284 # ffffffffc0206108 <commands+0x818>
ffffffffc0201614:	0d800593          	li	a1,216
ffffffffc0201618:	00005517          	auipc	a0,0x5
ffffffffc020161c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0206120 <commands+0x830>
ffffffffc0201620:	e73fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201624 <default_free_pages>:
{
ffffffffc0201624:	1141                	addi	sp,sp,-16
ffffffffc0201626:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201628:	14058463          	beqz	a1,ffffffffc0201770 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc020162c:	00659693          	slli	a3,a1,0x6
ffffffffc0201630:	96aa                	add	a3,a3,a0
ffffffffc0201632:	87aa                	mv	a5,a0
ffffffffc0201634:	02d50263          	beq	a0,a3,ffffffffc0201658 <default_free_pages+0x34>
ffffffffc0201638:	6798                	ld	a4,8(a5)
ffffffffc020163a:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020163c:	10071a63          	bnez	a4,ffffffffc0201750 <default_free_pages+0x12c>
ffffffffc0201640:	6798                	ld	a4,8(a5)
ffffffffc0201642:	8b09                	andi	a4,a4,2
ffffffffc0201644:	10071663          	bnez	a4,ffffffffc0201750 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201648:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc020164c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201650:	04078793          	addi	a5,a5,64
ffffffffc0201654:	fed792e3          	bne	a5,a3,ffffffffc0201638 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201658:	2581                	sext.w	a1,a1
ffffffffc020165a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020165c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201660:	4789                	li	a5,2
ffffffffc0201662:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201666:	000c0697          	auipc	a3,0xc0
ffffffffc020166a:	64268693          	addi	a3,a3,1602 # ffffffffc02c1ca8 <free_area>
ffffffffc020166e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201670:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201672:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201676:	9db9                	addw	a1,a1,a4
ffffffffc0201678:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020167a:	0ad78463          	beq	a5,a3,ffffffffc0201722 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc020167e:	fe878713          	addi	a4,a5,-24
ffffffffc0201682:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201686:	4581                	li	a1,0
            if (base < page)
ffffffffc0201688:	00e56a63          	bltu	a0,a4,ffffffffc020169c <default_free_pages+0x78>
    return listelm->next;
ffffffffc020168c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020168e:	04d70c63          	beq	a4,a3,ffffffffc02016e6 <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201692:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201694:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201698:	fee57ae3          	bgeu	a0,a4,ffffffffc020168c <default_free_pages+0x68>
ffffffffc020169c:	c199                	beqz	a1,ffffffffc02016a2 <default_free_pages+0x7e>
ffffffffc020169e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016a2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016a4:	e390                	sd	a2,0(a5)
ffffffffc02016a6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016a8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016aa:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02016ac:	00d70d63          	beq	a4,a3,ffffffffc02016c6 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02016b0:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016b4:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02016b8:	02059813          	slli	a6,a1,0x20
ffffffffc02016bc:	01a85793          	srli	a5,a6,0x1a
ffffffffc02016c0:	97b2                	add	a5,a5,a2
ffffffffc02016c2:	02f50c63          	beq	a0,a5,ffffffffc02016fa <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02016c6:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02016c8:	00d78c63          	beq	a5,a3,ffffffffc02016e0 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02016cc:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02016ce:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02016d2:	02061593          	slli	a1,a2,0x20
ffffffffc02016d6:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02016da:	972a                	add	a4,a4,a0
ffffffffc02016dc:	04e68a63          	beq	a3,a4,ffffffffc0201730 <default_free_pages+0x10c>
}
ffffffffc02016e0:	60a2                	ld	ra,8(sp)
ffffffffc02016e2:	0141                	addi	sp,sp,16
ffffffffc02016e4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016e6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016e8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016ea:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016ec:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02016ee:	02d70763          	beq	a4,a3,ffffffffc020171c <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02016f2:	8832                	mv	a6,a2
ffffffffc02016f4:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02016f6:	87ba                	mv	a5,a4
ffffffffc02016f8:	bf71                	j	ffffffffc0201694 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02016fa:	491c                	lw	a5,16(a0)
ffffffffc02016fc:	9dbd                	addw	a1,a1,a5
ffffffffc02016fe:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201702:	57f5                	li	a5,-3
ffffffffc0201704:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201708:	01853803          	ld	a6,24(a0)
ffffffffc020170c:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020170e:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201710:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201714:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201716:	0105b023          	sd	a6,0(a1)
ffffffffc020171a:	b77d                	j	ffffffffc02016c8 <default_free_pages+0xa4>
ffffffffc020171c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc020171e:	873e                	mv	a4,a5
ffffffffc0201720:	bf41                	j	ffffffffc02016b0 <default_free_pages+0x8c>
}
ffffffffc0201722:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201724:	e390                	sd	a2,0(a5)
ffffffffc0201726:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201728:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020172a:	ed1c                	sd	a5,24(a0)
ffffffffc020172c:	0141                	addi	sp,sp,16
ffffffffc020172e:	8082                	ret
            base->property += p->property;
ffffffffc0201730:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201734:	ff078693          	addi	a3,a5,-16
ffffffffc0201738:	9e39                	addw	a2,a2,a4
ffffffffc020173a:	c910                	sw	a2,16(a0)
ffffffffc020173c:	5775                	li	a4,-3
ffffffffc020173e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201742:	6398                	ld	a4,0(a5)
ffffffffc0201744:	679c                	ld	a5,8(a5)
}
ffffffffc0201746:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201748:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020174a:	e398                	sd	a4,0(a5)
ffffffffc020174c:	0141                	addi	sp,sp,16
ffffffffc020174e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201750:	00005697          	auipc	a3,0x5
ffffffffc0201754:	d1868693          	addi	a3,a3,-744 # ffffffffc0206468 <commands+0xb78>
ffffffffc0201758:	00005617          	auipc	a2,0x5
ffffffffc020175c:	9b060613          	addi	a2,a2,-1616 # ffffffffc0206108 <commands+0x818>
ffffffffc0201760:	09400593          	li	a1,148
ffffffffc0201764:	00005517          	auipc	a0,0x5
ffffffffc0201768:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206120 <commands+0x830>
ffffffffc020176c:	d27fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201770:	00005697          	auipc	a3,0x5
ffffffffc0201774:	cf068693          	addi	a3,a3,-784 # ffffffffc0206460 <commands+0xb70>
ffffffffc0201778:	00005617          	auipc	a2,0x5
ffffffffc020177c:	99060613          	addi	a2,a2,-1648 # ffffffffc0206108 <commands+0x818>
ffffffffc0201780:	09000593          	li	a1,144
ffffffffc0201784:	00005517          	auipc	a0,0x5
ffffffffc0201788:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206120 <commands+0x830>
ffffffffc020178c:	d07fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201790 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201790:	c941                	beqz	a0,ffffffffc0201820 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201792:	000c0597          	auipc	a1,0xc0
ffffffffc0201796:	51658593          	addi	a1,a1,1302 # ffffffffc02c1ca8 <free_area>
ffffffffc020179a:	0105a803          	lw	a6,16(a1)
ffffffffc020179e:	872a                	mv	a4,a0
ffffffffc02017a0:	02081793          	slli	a5,a6,0x20
ffffffffc02017a4:	9381                	srli	a5,a5,0x20
ffffffffc02017a6:	00a7ee63          	bltu	a5,a0,ffffffffc02017c2 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017aa:	87ae                	mv	a5,a1
ffffffffc02017ac:	a801                	j	ffffffffc02017bc <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02017ae:	ff87a683          	lw	a3,-8(a5)
ffffffffc02017b2:	02069613          	slli	a2,a3,0x20
ffffffffc02017b6:	9201                	srli	a2,a2,0x20
ffffffffc02017b8:	00e67763          	bgeu	a2,a4,ffffffffc02017c6 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02017bc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02017be:	feb798e3          	bne	a5,a1,ffffffffc02017ae <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02017c2:	4501                	li	a0,0
}
ffffffffc02017c4:	8082                	ret
    return listelm->prev;
ffffffffc02017c6:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017ca:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02017ce:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02017d2:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02017d6:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02017da:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02017de:	02c77863          	bgeu	a4,a2,ffffffffc020180e <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02017e2:	071a                	slli	a4,a4,0x6
ffffffffc02017e4:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02017e6:	41c686bb          	subw	a3,a3,t3
ffffffffc02017ea:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017ec:	00870613          	addi	a2,a4,8
ffffffffc02017f0:	4689                	li	a3,2
ffffffffc02017f2:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02017f6:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02017fa:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02017fe:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201802:	e290                	sd	a2,0(a3)
ffffffffc0201804:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201808:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020180a:	01173c23          	sd	a7,24(a4)
ffffffffc020180e:	41c8083b          	subw	a6,a6,t3
ffffffffc0201812:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201816:	5775                	li	a4,-3
ffffffffc0201818:	17c1                	addi	a5,a5,-16
ffffffffc020181a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020181e:	8082                	ret
{
ffffffffc0201820:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201822:	00005697          	auipc	a3,0x5
ffffffffc0201826:	c3e68693          	addi	a3,a3,-962 # ffffffffc0206460 <commands+0xb70>
ffffffffc020182a:	00005617          	auipc	a2,0x5
ffffffffc020182e:	8de60613          	addi	a2,a2,-1826 # ffffffffc0206108 <commands+0x818>
ffffffffc0201832:	06c00593          	li	a1,108
ffffffffc0201836:	00005517          	auipc	a0,0x5
ffffffffc020183a:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0206120 <commands+0x830>
{
ffffffffc020183e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201840:	c53fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201844 <default_init_memmap>:
{
ffffffffc0201844:	1141                	addi	sp,sp,-16
ffffffffc0201846:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201848:	c5f1                	beqz	a1,ffffffffc0201914 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc020184a:	00659693          	slli	a3,a1,0x6
ffffffffc020184e:	96aa                	add	a3,a3,a0
ffffffffc0201850:	87aa                	mv	a5,a0
ffffffffc0201852:	00d50f63          	beq	a0,a3,ffffffffc0201870 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201856:	6798                	ld	a4,8(a5)
ffffffffc0201858:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc020185a:	cf49                	beqz	a4,ffffffffc02018f4 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020185c:	0007a823          	sw	zero,16(a5)
ffffffffc0201860:	0007b423          	sd	zero,8(a5)
ffffffffc0201864:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201868:	04078793          	addi	a5,a5,64
ffffffffc020186c:	fed795e3          	bne	a5,a3,ffffffffc0201856 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201870:	2581                	sext.w	a1,a1
ffffffffc0201872:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201874:	4789                	li	a5,2
ffffffffc0201876:	00850713          	addi	a4,a0,8
ffffffffc020187a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020187e:	000c0697          	auipc	a3,0xc0
ffffffffc0201882:	42a68693          	addi	a3,a3,1066 # ffffffffc02c1ca8 <free_area>
ffffffffc0201886:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201888:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020188a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020188e:	9db9                	addw	a1,a1,a4
ffffffffc0201890:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201892:	04d78a63          	beq	a5,a3,ffffffffc02018e6 <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201896:	fe878713          	addi	a4,a5,-24
ffffffffc020189a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020189e:	4581                	li	a1,0
            if (base < page)
ffffffffc02018a0:	00e56a63          	bltu	a0,a4,ffffffffc02018b4 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02018a4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02018a6:	02d70263          	beq	a4,a3,ffffffffc02018ca <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02018aa:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02018ac:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02018b0:	fee57ae3          	bgeu	a0,a4,ffffffffc02018a4 <default_init_memmap+0x60>
ffffffffc02018b4:	c199                	beqz	a1,ffffffffc02018ba <default_init_memmap+0x76>
ffffffffc02018b6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018ba:	6398                	ld	a4,0(a5)
}
ffffffffc02018bc:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018be:	e390                	sd	a2,0(a5)
ffffffffc02018c0:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018c2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018c4:	ed18                	sd	a4,24(a0)
ffffffffc02018c6:	0141                	addi	sp,sp,16
ffffffffc02018c8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018ca:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018cc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018ce:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018d0:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018d2:	00d70663          	beq	a4,a3,ffffffffc02018de <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02018d6:	8832                	mv	a6,a2
ffffffffc02018d8:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02018da:	87ba                	mv	a5,a4
ffffffffc02018dc:	bfc1                	j	ffffffffc02018ac <default_init_memmap+0x68>
}
ffffffffc02018de:	60a2                	ld	ra,8(sp)
ffffffffc02018e0:	e290                	sd	a2,0(a3)
ffffffffc02018e2:	0141                	addi	sp,sp,16
ffffffffc02018e4:	8082                	ret
ffffffffc02018e6:	60a2                	ld	ra,8(sp)
ffffffffc02018e8:	e390                	sd	a2,0(a5)
ffffffffc02018ea:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018ec:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018ee:	ed1c                	sd	a5,24(a0)
ffffffffc02018f0:	0141                	addi	sp,sp,16
ffffffffc02018f2:	8082                	ret
        assert(PageReserved(p));
ffffffffc02018f4:	00005697          	auipc	a3,0x5
ffffffffc02018f8:	b9c68693          	addi	a3,a3,-1124 # ffffffffc0206490 <commands+0xba0>
ffffffffc02018fc:	00005617          	auipc	a2,0x5
ffffffffc0201900:	80c60613          	addi	a2,a2,-2036 # ffffffffc0206108 <commands+0x818>
ffffffffc0201904:	04b00593          	li	a1,75
ffffffffc0201908:	00005517          	auipc	a0,0x5
ffffffffc020190c:	81850513          	addi	a0,a0,-2024 # ffffffffc0206120 <commands+0x830>
ffffffffc0201910:	b83fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(n > 0);
ffffffffc0201914:	00005697          	auipc	a3,0x5
ffffffffc0201918:	b4c68693          	addi	a3,a3,-1204 # ffffffffc0206460 <commands+0xb70>
ffffffffc020191c:	00004617          	auipc	a2,0x4
ffffffffc0201920:	7ec60613          	addi	a2,a2,2028 # ffffffffc0206108 <commands+0x818>
ffffffffc0201924:	04700593          	li	a1,71
ffffffffc0201928:	00004517          	auipc	a0,0x4
ffffffffc020192c:	7f850513          	addi	a0,a0,2040 # ffffffffc0206120 <commands+0x830>
ffffffffc0201930:	b63fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201934 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201934:	c94d                	beqz	a0,ffffffffc02019e6 <slob_free+0xb2>
{
ffffffffc0201936:	1141                	addi	sp,sp,-16
ffffffffc0201938:	e022                	sd	s0,0(sp)
ffffffffc020193a:	e406                	sd	ra,8(sp)
ffffffffc020193c:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020193e:	e9c1                	bnez	a1,ffffffffc02019ce <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201940:	100027f3          	csrr	a5,sstatus
ffffffffc0201944:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201946:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201948:	ebd9                	bnez	a5,ffffffffc02019de <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020194a:	000c0617          	auipc	a2,0xc0
ffffffffc020194e:	f4e60613          	addi	a2,a2,-178 # ffffffffc02c1898 <slobfree>
ffffffffc0201952:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201954:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201956:	679c                	ld	a5,8(a5)
ffffffffc0201958:	02877a63          	bgeu	a4,s0,ffffffffc020198c <slob_free+0x58>
ffffffffc020195c:	00f46463          	bltu	s0,a5,ffffffffc0201964 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201960:	fef76ae3          	bltu	a4,a5,ffffffffc0201954 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201964:	400c                	lw	a1,0(s0)
ffffffffc0201966:	00459693          	slli	a3,a1,0x4
ffffffffc020196a:	96a2                	add	a3,a3,s0
ffffffffc020196c:	02d78a63          	beq	a5,a3,ffffffffc02019a0 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201970:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201972:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201974:	00469793          	slli	a5,a3,0x4
ffffffffc0201978:	97ba                	add	a5,a5,a4
ffffffffc020197a:	02f40e63          	beq	s0,a5,ffffffffc02019b6 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc020197e:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201980:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201982:	e129                	bnez	a0,ffffffffc02019c4 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201984:	60a2                	ld	ra,8(sp)
ffffffffc0201986:	6402                	ld	s0,0(sp)
ffffffffc0201988:	0141                	addi	sp,sp,16
ffffffffc020198a:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020198c:	fcf764e3          	bltu	a4,a5,ffffffffc0201954 <slob_free+0x20>
ffffffffc0201990:	fcf472e3          	bgeu	s0,a5,ffffffffc0201954 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201994:	400c                	lw	a1,0(s0)
ffffffffc0201996:	00459693          	slli	a3,a1,0x4
ffffffffc020199a:	96a2                	add	a3,a3,s0
ffffffffc020199c:	fcd79ae3          	bne	a5,a3,ffffffffc0201970 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02019a0:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02019a2:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02019a4:	9db5                	addw	a1,a1,a3
ffffffffc02019a6:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02019a8:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02019aa:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02019ac:	00469793          	slli	a5,a3,0x4
ffffffffc02019b0:	97ba                	add	a5,a5,a4
ffffffffc02019b2:	fcf416e3          	bne	s0,a5,ffffffffc020197e <slob_free+0x4a>
		cur->units += b->units;
ffffffffc02019b6:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc02019b8:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc02019ba:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc02019bc:	9ebd                	addw	a3,a3,a5
ffffffffc02019be:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc02019c0:	e70c                	sd	a1,8(a4)
ffffffffc02019c2:	d169                	beqz	a0,ffffffffc0201984 <slob_free+0x50>
}
ffffffffc02019c4:	6402                	ld	s0,0(sp)
ffffffffc02019c6:	60a2                	ld	ra,8(sp)
ffffffffc02019c8:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02019ca:	fc7fe06f          	j	ffffffffc0200990 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02019ce:	25bd                	addiw	a1,a1,15
ffffffffc02019d0:	8191                	srli	a1,a1,0x4
ffffffffc02019d2:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019d4:	100027f3          	csrr	a5,sstatus
ffffffffc02019d8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019da:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02019dc:	d7bd                	beqz	a5,ffffffffc020194a <slob_free+0x16>
        intr_disable();
ffffffffc02019de:	fb9fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        return 1;
ffffffffc02019e2:	4505                	li	a0,1
ffffffffc02019e4:	b79d                	j	ffffffffc020194a <slob_free+0x16>
ffffffffc02019e6:	8082                	ret

ffffffffc02019e8 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc02019e8:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02019ea:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc02019ec:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02019f0:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc02019f2:	352000ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
	if (!page)
ffffffffc02019f6:	c91d                	beqz	a0,ffffffffc0201a2c <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02019f8:	000c4697          	auipc	a3,0xc4
ffffffffc02019fc:	3486b683          	ld	a3,840(a3) # ffffffffc02c5d40 <pages>
ffffffffc0201a00:	8d15                	sub	a0,a0,a3
ffffffffc0201a02:	8519                	srai	a0,a0,0x6
ffffffffc0201a04:	00006697          	auipc	a3,0x6
ffffffffc0201a08:	4fc6b683          	ld	a3,1276(a3) # ffffffffc0207f00 <nbase>
ffffffffc0201a0c:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201a0e:	00c51793          	slli	a5,a0,0xc
ffffffffc0201a12:	83b1                	srli	a5,a5,0xc
ffffffffc0201a14:	000c4717          	auipc	a4,0xc4
ffffffffc0201a18:	32473703          	ld	a4,804(a4) # ffffffffc02c5d38 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201a1c:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201a1e:	00e7fa63          	bgeu	a5,a4,ffffffffc0201a32 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201a22:	000c4697          	auipc	a3,0xc4
ffffffffc0201a26:	32e6b683          	ld	a3,814(a3) # ffffffffc02c5d50 <va_pa_offset>
ffffffffc0201a2a:	9536                	add	a0,a0,a3
}
ffffffffc0201a2c:	60a2                	ld	ra,8(sp)
ffffffffc0201a2e:	0141                	addi	sp,sp,16
ffffffffc0201a30:	8082                	ret
ffffffffc0201a32:	86aa                	mv	a3,a0
ffffffffc0201a34:	00005617          	auipc	a2,0x5
ffffffffc0201a38:	abc60613          	addi	a2,a2,-1348 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0201a3c:	07100593          	li	a1,113
ffffffffc0201a40:	00005517          	auipc	a0,0x5
ffffffffc0201a44:	ad850513          	addi	a0,a0,-1320 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0201a48:	a4bfe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201a4c <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201a4c:	1101                	addi	sp,sp,-32
ffffffffc0201a4e:	ec06                	sd	ra,24(sp)
ffffffffc0201a50:	e822                	sd	s0,16(sp)
ffffffffc0201a52:	e426                	sd	s1,8(sp)
ffffffffc0201a54:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a56:	01050713          	addi	a4,a0,16
ffffffffc0201a5a:	6785                	lui	a5,0x1
ffffffffc0201a5c:	0cf77363          	bgeu	a4,a5,ffffffffc0201b22 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201a60:	00f50493          	addi	s1,a0,15
ffffffffc0201a64:	8091                	srli	s1,s1,0x4
ffffffffc0201a66:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a68:	10002673          	csrr	a2,sstatus
ffffffffc0201a6c:	8a09                	andi	a2,a2,2
ffffffffc0201a6e:	e25d                	bnez	a2,ffffffffc0201b14 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201a70:	000c0917          	auipc	s2,0xc0
ffffffffc0201a74:	e2890913          	addi	s2,s2,-472 # ffffffffc02c1898 <slobfree>
ffffffffc0201a78:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a7c:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201a7e:	4398                	lw	a4,0(a5)
ffffffffc0201a80:	08975e63          	bge	a4,s1,ffffffffc0201b1c <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201a84:	00f68b63          	beq	a3,a5,ffffffffc0201a9a <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a88:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201a8a:	4018                	lw	a4,0(s0)
ffffffffc0201a8c:	02975a63          	bge	a4,s1,ffffffffc0201ac0 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201a90:	00093683          	ld	a3,0(s2)
ffffffffc0201a94:	87a2                	mv	a5,s0
ffffffffc0201a96:	fef699e3          	bne	a3,a5,ffffffffc0201a88 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201a9a:	ee31                	bnez	a2,ffffffffc0201af6 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201a9c:	4501                	li	a0,0
ffffffffc0201a9e:	f4bff0ef          	jal	ra,ffffffffc02019e8 <__slob_get_free_pages.constprop.0>
ffffffffc0201aa2:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201aa4:	cd05                	beqz	a0,ffffffffc0201adc <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201aa6:	6585                	lui	a1,0x1
ffffffffc0201aa8:	e8dff0ef          	jal	ra,ffffffffc0201934 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aac:	10002673          	csrr	a2,sstatus
ffffffffc0201ab0:	8a09                	andi	a2,a2,2
ffffffffc0201ab2:	ee05                	bnez	a2,ffffffffc0201aea <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201ab4:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ab8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201aba:	4018                	lw	a4,0(s0)
ffffffffc0201abc:	fc974ae3          	blt	a4,s1,ffffffffc0201a90 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201ac0:	04e48763          	beq	s1,a4,ffffffffc0201b0e <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201ac4:	00449693          	slli	a3,s1,0x4
ffffffffc0201ac8:	96a2                	add	a3,a3,s0
ffffffffc0201aca:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201acc:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201ace:	9f05                	subw	a4,a4,s1
ffffffffc0201ad0:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201ad2:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201ad4:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201ad6:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201ada:	e20d                	bnez	a2,ffffffffc0201afc <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201adc:	60e2                	ld	ra,24(sp)
ffffffffc0201ade:	8522                	mv	a0,s0
ffffffffc0201ae0:	6442                	ld	s0,16(sp)
ffffffffc0201ae2:	64a2                	ld	s1,8(sp)
ffffffffc0201ae4:	6902                	ld	s2,0(sp)
ffffffffc0201ae6:	6105                	addi	sp,sp,32
ffffffffc0201ae8:	8082                	ret
        intr_disable();
ffffffffc0201aea:	eadfe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
			cur = slobfree;
ffffffffc0201aee:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201af2:	4605                	li	a2,1
ffffffffc0201af4:	b7d1                	j	ffffffffc0201ab8 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201af6:	e9bfe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0201afa:	b74d                	j	ffffffffc0201a9c <slob_alloc.constprop.0+0x50>
ffffffffc0201afc:	e95fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
}
ffffffffc0201b00:	60e2                	ld	ra,24(sp)
ffffffffc0201b02:	8522                	mv	a0,s0
ffffffffc0201b04:	6442                	ld	s0,16(sp)
ffffffffc0201b06:	64a2                	ld	s1,8(sp)
ffffffffc0201b08:	6902                	ld	s2,0(sp)
ffffffffc0201b0a:	6105                	addi	sp,sp,32
ffffffffc0201b0c:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201b0e:	6418                	ld	a4,8(s0)
ffffffffc0201b10:	e798                	sd	a4,8(a5)
ffffffffc0201b12:	b7d1                	j	ffffffffc0201ad6 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201b14:	e83fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        return 1;
ffffffffc0201b18:	4605                	li	a2,1
ffffffffc0201b1a:	bf99                	j	ffffffffc0201a70 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201b1c:	843e                	mv	s0,a5
ffffffffc0201b1e:	87b6                	mv	a5,a3
ffffffffc0201b20:	b745                	j	ffffffffc0201ac0 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201b22:	00005697          	auipc	a3,0x5
ffffffffc0201b26:	a0668693          	addi	a3,a3,-1530 # ffffffffc0206528 <default_pmm_manager+0x70>
ffffffffc0201b2a:	00004617          	auipc	a2,0x4
ffffffffc0201b2e:	5de60613          	addi	a2,a2,1502 # ffffffffc0206108 <commands+0x818>
ffffffffc0201b32:	06300593          	li	a1,99
ffffffffc0201b36:	00005517          	auipc	a0,0x5
ffffffffc0201b3a:	a1250513          	addi	a0,a0,-1518 # ffffffffc0206548 <default_pmm_manager+0x90>
ffffffffc0201b3e:	955fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201b42 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201b42:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201b44:	00005517          	auipc	a0,0x5
ffffffffc0201b48:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0206560 <default_pmm_manager+0xa8>
{
ffffffffc0201b4c:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201b4e:	e4afe0ef          	jal	ra,ffffffffc0200198 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201b52:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b54:	00005517          	auipc	a0,0x5
ffffffffc0201b58:	a2450513          	addi	a0,a0,-1500 # ffffffffc0206578 <default_pmm_manager+0xc0>
}
ffffffffc0201b5c:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b5e:	e3afe06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0201b62 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201b62:	4501                	li	a0,0
ffffffffc0201b64:	8082                	ret

ffffffffc0201b66 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201b66:	1101                	addi	sp,sp,-32
ffffffffc0201b68:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201b6a:	6905                	lui	s2,0x1
{
ffffffffc0201b6c:	e822                	sd	s0,16(sp)
ffffffffc0201b6e:	ec06                	sd	ra,24(sp)
ffffffffc0201b70:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201b72:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8f61>
{
ffffffffc0201b76:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201b78:	04a7f963          	bgeu	a5,a0,ffffffffc0201bca <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201b7c:	4561                	li	a0,24
ffffffffc0201b7e:	ecfff0ef          	jal	ra,ffffffffc0201a4c <slob_alloc.constprop.0>
ffffffffc0201b82:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201b84:	c929                	beqz	a0,ffffffffc0201bd6 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201b86:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201b8a:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201b8c:	00f95763          	bge	s2,a5,ffffffffc0201b9a <kmalloc+0x34>
ffffffffc0201b90:	6705                	lui	a4,0x1
ffffffffc0201b92:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201b94:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201b96:	fef74ee3          	blt	a4,a5,ffffffffc0201b92 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201b9a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201b9c:	e4dff0ef          	jal	ra,ffffffffc02019e8 <__slob_get_free_pages.constprop.0>
ffffffffc0201ba0:	e488                	sd	a0,8(s1)
ffffffffc0201ba2:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201ba4:	c525                	beqz	a0,ffffffffc0201c0c <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ba6:	100027f3          	csrr	a5,sstatus
ffffffffc0201baa:	8b89                	andi	a5,a5,2
ffffffffc0201bac:	ef8d                	bnez	a5,ffffffffc0201be6 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201bae:	000c4797          	auipc	a5,0xc4
ffffffffc0201bb2:	17278793          	addi	a5,a5,370 # ffffffffc02c5d20 <bigblocks>
ffffffffc0201bb6:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201bb8:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201bba:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201bbc:	60e2                	ld	ra,24(sp)
ffffffffc0201bbe:	8522                	mv	a0,s0
ffffffffc0201bc0:	6442                	ld	s0,16(sp)
ffffffffc0201bc2:	64a2                	ld	s1,8(sp)
ffffffffc0201bc4:	6902                	ld	s2,0(sp)
ffffffffc0201bc6:	6105                	addi	sp,sp,32
ffffffffc0201bc8:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201bca:	0541                	addi	a0,a0,16
ffffffffc0201bcc:	e81ff0ef          	jal	ra,ffffffffc0201a4c <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201bd0:	01050413          	addi	s0,a0,16
ffffffffc0201bd4:	f565                	bnez	a0,ffffffffc0201bbc <kmalloc+0x56>
ffffffffc0201bd6:	4401                	li	s0,0
}
ffffffffc0201bd8:	60e2                	ld	ra,24(sp)
ffffffffc0201bda:	8522                	mv	a0,s0
ffffffffc0201bdc:	6442                	ld	s0,16(sp)
ffffffffc0201bde:	64a2                	ld	s1,8(sp)
ffffffffc0201be0:	6902                	ld	s2,0(sp)
ffffffffc0201be2:	6105                	addi	sp,sp,32
ffffffffc0201be4:	8082                	ret
        intr_disable();
ffffffffc0201be6:	db1fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201bea:	000c4797          	auipc	a5,0xc4
ffffffffc0201bee:	13678793          	addi	a5,a5,310 # ffffffffc02c5d20 <bigblocks>
ffffffffc0201bf2:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201bf4:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201bf6:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201bf8:	d99fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
		return bb->pages;
ffffffffc0201bfc:	6480                	ld	s0,8(s1)
}
ffffffffc0201bfe:	60e2                	ld	ra,24(sp)
ffffffffc0201c00:	64a2                	ld	s1,8(sp)
ffffffffc0201c02:	8522                	mv	a0,s0
ffffffffc0201c04:	6442                	ld	s0,16(sp)
ffffffffc0201c06:	6902                	ld	s2,0(sp)
ffffffffc0201c08:	6105                	addi	sp,sp,32
ffffffffc0201c0a:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c0c:	45e1                	li	a1,24
ffffffffc0201c0e:	8526                	mv	a0,s1
ffffffffc0201c10:	d25ff0ef          	jal	ra,ffffffffc0201934 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201c14:	b765                	j	ffffffffc0201bbc <kmalloc+0x56>

ffffffffc0201c16 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201c16:	c169                	beqz	a0,ffffffffc0201cd8 <kfree+0xc2>
{
ffffffffc0201c18:	1101                	addi	sp,sp,-32
ffffffffc0201c1a:	e822                	sd	s0,16(sp)
ffffffffc0201c1c:	ec06                	sd	ra,24(sp)
ffffffffc0201c1e:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201c20:	03451793          	slli	a5,a0,0x34
ffffffffc0201c24:	842a                	mv	s0,a0
ffffffffc0201c26:	e3d9                	bnez	a5,ffffffffc0201cac <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c28:	100027f3          	csrr	a5,sstatus
ffffffffc0201c2c:	8b89                	andi	a5,a5,2
ffffffffc0201c2e:	e7d9                	bnez	a5,ffffffffc0201cbc <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c30:	000c4797          	auipc	a5,0xc4
ffffffffc0201c34:	0f07b783          	ld	a5,240(a5) # ffffffffc02c5d20 <bigblocks>
    return 0;
ffffffffc0201c38:	4601                	li	a2,0
ffffffffc0201c3a:	cbad                	beqz	a5,ffffffffc0201cac <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201c3c:	000c4697          	auipc	a3,0xc4
ffffffffc0201c40:	0e468693          	addi	a3,a3,228 # ffffffffc02c5d20 <bigblocks>
ffffffffc0201c44:	a021                	j	ffffffffc0201c4c <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c46:	01048693          	addi	a3,s1,16
ffffffffc0201c4a:	c3a5                	beqz	a5,ffffffffc0201caa <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201c4c:	6798                	ld	a4,8(a5)
ffffffffc0201c4e:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201c50:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201c52:	fe871ae3          	bne	a4,s0,ffffffffc0201c46 <kfree+0x30>
				*last = bb->next;
ffffffffc0201c56:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201c58:	ee2d                	bnez	a2,ffffffffc0201cd2 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201c5a:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201c5e:	4098                	lw	a4,0(s1)
ffffffffc0201c60:	08f46963          	bltu	s0,a5,ffffffffc0201cf2 <kfree+0xdc>
ffffffffc0201c64:	000c4697          	auipc	a3,0xc4
ffffffffc0201c68:	0ec6b683          	ld	a3,236(a3) # ffffffffc02c5d50 <va_pa_offset>
ffffffffc0201c6c:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201c6e:	8031                	srli	s0,s0,0xc
ffffffffc0201c70:	000c4797          	auipc	a5,0xc4
ffffffffc0201c74:	0c87b783          	ld	a5,200(a5) # ffffffffc02c5d38 <npage>
ffffffffc0201c78:	06f47163          	bgeu	s0,a5,ffffffffc0201cda <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201c7c:	00006517          	auipc	a0,0x6
ffffffffc0201c80:	28453503          	ld	a0,644(a0) # ffffffffc0207f00 <nbase>
ffffffffc0201c84:	8c09                	sub	s0,s0,a0
ffffffffc0201c86:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201c88:	000c4517          	auipc	a0,0xc4
ffffffffc0201c8c:	0b853503          	ld	a0,184(a0) # ffffffffc02c5d40 <pages>
ffffffffc0201c90:	4585                	li	a1,1
ffffffffc0201c92:	9522                	add	a0,a0,s0
ffffffffc0201c94:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201c98:	0ea000ef          	jal	ra,ffffffffc0201d82 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201c9c:	6442                	ld	s0,16(sp)
ffffffffc0201c9e:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ca0:	8526                	mv	a0,s1
}
ffffffffc0201ca2:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ca4:	45e1                	li	a1,24
}
ffffffffc0201ca6:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ca8:	b171                	j	ffffffffc0201934 <slob_free>
ffffffffc0201caa:	e20d                	bnez	a2,ffffffffc0201ccc <kfree+0xb6>
ffffffffc0201cac:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201cb0:	6442                	ld	s0,16(sp)
ffffffffc0201cb2:	60e2                	ld	ra,24(sp)
ffffffffc0201cb4:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cb6:	4581                	li	a1,0
}
ffffffffc0201cb8:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201cba:	b9ad                	j	ffffffffc0201934 <slob_free>
        intr_disable();
ffffffffc0201cbc:	cdbfe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201cc0:	000c4797          	auipc	a5,0xc4
ffffffffc0201cc4:	0607b783          	ld	a5,96(a5) # ffffffffc02c5d20 <bigblocks>
        return 1;
ffffffffc0201cc8:	4605                	li	a2,1
ffffffffc0201cca:	fbad                	bnez	a5,ffffffffc0201c3c <kfree+0x26>
        intr_enable();
ffffffffc0201ccc:	cc5fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0201cd0:	bff1                	j	ffffffffc0201cac <kfree+0x96>
ffffffffc0201cd2:	cbffe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0201cd6:	b751                	j	ffffffffc0201c5a <kfree+0x44>
ffffffffc0201cd8:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201cda:	00005617          	auipc	a2,0x5
ffffffffc0201cde:	8e660613          	addi	a2,a2,-1818 # ffffffffc02065c0 <default_pmm_manager+0x108>
ffffffffc0201ce2:	06900593          	li	a1,105
ffffffffc0201ce6:	00005517          	auipc	a0,0x5
ffffffffc0201cea:	83250513          	addi	a0,a0,-1998 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0201cee:	fa4fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201cf2:	86a2                	mv	a3,s0
ffffffffc0201cf4:	00005617          	auipc	a2,0x5
ffffffffc0201cf8:	8a460613          	addi	a2,a2,-1884 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc0201cfc:	07700593          	li	a1,119
ffffffffc0201d00:	00005517          	auipc	a0,0x5
ffffffffc0201d04:	81850513          	addi	a0,a0,-2024 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0201d08:	f8afe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d0c <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201d0c:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201d0e:	00005617          	auipc	a2,0x5
ffffffffc0201d12:	8b260613          	addi	a2,a2,-1870 # ffffffffc02065c0 <default_pmm_manager+0x108>
ffffffffc0201d16:	06900593          	li	a1,105
ffffffffc0201d1a:	00004517          	auipc	a0,0x4
ffffffffc0201d1e:	7fe50513          	addi	a0,a0,2046 # ffffffffc0206518 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201d22:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201d24:	f6efe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d28 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201d28:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201d2a:	00005617          	auipc	a2,0x5
ffffffffc0201d2e:	8b660613          	addi	a2,a2,-1866 # ffffffffc02065e0 <default_pmm_manager+0x128>
ffffffffc0201d32:	07f00593          	li	a1,127
ffffffffc0201d36:	00004517          	auipc	a0,0x4
ffffffffc0201d3a:	7e250513          	addi	a0,a0,2018 # ffffffffc0206518 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201d3e:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201d40:	f52fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0201d44 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d44:	100027f3          	csrr	a5,sstatus
ffffffffc0201d48:	8b89                	andi	a5,a5,2
ffffffffc0201d4a:	e799                	bnez	a5,ffffffffc0201d58 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d4c:	000c4797          	auipc	a5,0xc4
ffffffffc0201d50:	ffc7b783          	ld	a5,-4(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201d54:	6f9c                	ld	a5,24(a5)
ffffffffc0201d56:	8782                	jr	a5
{
ffffffffc0201d58:	1141                	addi	sp,sp,-16
ffffffffc0201d5a:	e406                	sd	ra,8(sp)
ffffffffc0201d5c:	e022                	sd	s0,0(sp)
ffffffffc0201d5e:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201d60:	c37fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d64:	000c4797          	auipc	a5,0xc4
ffffffffc0201d68:	fe47b783          	ld	a5,-28(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201d6c:	6f9c                	ld	a5,24(a5)
ffffffffc0201d6e:	8522                	mv	a0,s0
ffffffffc0201d70:	9782                	jalr	a5
ffffffffc0201d72:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d74:	c1dfe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201d78:	60a2                	ld	ra,8(sp)
ffffffffc0201d7a:	8522                	mv	a0,s0
ffffffffc0201d7c:	6402                	ld	s0,0(sp)
ffffffffc0201d7e:	0141                	addi	sp,sp,16
ffffffffc0201d80:	8082                	ret

ffffffffc0201d82 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d82:	100027f3          	csrr	a5,sstatus
ffffffffc0201d86:	8b89                	andi	a5,a5,2
ffffffffc0201d88:	e799                	bnez	a5,ffffffffc0201d96 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201d8a:	000c4797          	auipc	a5,0xc4
ffffffffc0201d8e:	fbe7b783          	ld	a5,-66(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201d92:	739c                	ld	a5,32(a5)
ffffffffc0201d94:	8782                	jr	a5
{
ffffffffc0201d96:	1101                	addi	sp,sp,-32
ffffffffc0201d98:	ec06                	sd	ra,24(sp)
ffffffffc0201d9a:	e822                	sd	s0,16(sp)
ffffffffc0201d9c:	e426                	sd	s1,8(sp)
ffffffffc0201d9e:	842a                	mv	s0,a0
ffffffffc0201da0:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201da2:	bf5fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201da6:	000c4797          	auipc	a5,0xc4
ffffffffc0201daa:	fa27b783          	ld	a5,-94(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201dae:	739c                	ld	a5,32(a5)
ffffffffc0201db0:	85a6                	mv	a1,s1
ffffffffc0201db2:	8522                	mv	a0,s0
ffffffffc0201db4:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201db6:	6442                	ld	s0,16(sp)
ffffffffc0201db8:	60e2                	ld	ra,24(sp)
ffffffffc0201dba:	64a2                	ld	s1,8(sp)
ffffffffc0201dbc:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201dbe:	bd3fe06f          	j	ffffffffc0200990 <intr_enable>

ffffffffc0201dc2 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dc2:	100027f3          	csrr	a5,sstatus
ffffffffc0201dc6:	8b89                	andi	a5,a5,2
ffffffffc0201dc8:	e799                	bnez	a5,ffffffffc0201dd6 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201dca:	000c4797          	auipc	a5,0xc4
ffffffffc0201dce:	f7e7b783          	ld	a5,-130(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201dd2:	779c                	ld	a5,40(a5)
ffffffffc0201dd4:	8782                	jr	a5
{
ffffffffc0201dd6:	1141                	addi	sp,sp,-16
ffffffffc0201dd8:	e406                	sd	ra,8(sp)
ffffffffc0201dda:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201ddc:	bbbfe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201de0:	000c4797          	auipc	a5,0xc4
ffffffffc0201de4:	f687b783          	ld	a5,-152(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201de8:	779c                	ld	a5,40(a5)
ffffffffc0201dea:	9782                	jalr	a5
ffffffffc0201dec:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201dee:	ba3fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201df2:	60a2                	ld	ra,8(sp)
ffffffffc0201df4:	8522                	mv	a0,s0
ffffffffc0201df6:	6402                	ld	s0,0(sp)
ffffffffc0201df8:	0141                	addi	sp,sp,16
ffffffffc0201dfa:	8082                	ret

ffffffffc0201dfc <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201dfc:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e00:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201e04:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e06:	078e                	slli	a5,a5,0x3
{
ffffffffc0201e08:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e0a:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201e0e:	6094                	ld	a3,0(s1)
{
ffffffffc0201e10:	f04a                	sd	s2,32(sp)
ffffffffc0201e12:	ec4e                	sd	s3,24(sp)
ffffffffc0201e14:	e852                	sd	s4,16(sp)
ffffffffc0201e16:	fc06                	sd	ra,56(sp)
ffffffffc0201e18:	f822                	sd	s0,48(sp)
ffffffffc0201e1a:	e456                	sd	s5,8(sp)
ffffffffc0201e1c:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201e1e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201e22:	892e                	mv	s2,a1
ffffffffc0201e24:	8a32                	mv	s4,a2
ffffffffc0201e26:	000c4997          	auipc	s3,0xc4
ffffffffc0201e2a:	f1298993          	addi	s3,s3,-238 # ffffffffc02c5d38 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201e2e:	efbd                	bnez	a5,ffffffffc0201eac <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e30:	14060c63          	beqz	a2,ffffffffc0201f88 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e34:	100027f3          	csrr	a5,sstatus
ffffffffc0201e38:	8b89                	andi	a5,a5,2
ffffffffc0201e3a:	14079963          	bnez	a5,ffffffffc0201f8c <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e3e:	000c4797          	auipc	a5,0xc4
ffffffffc0201e42:	f0a7b783          	ld	a5,-246(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201e46:	6f9c                	ld	a5,24(a5)
ffffffffc0201e48:	4505                	li	a0,1
ffffffffc0201e4a:	9782                	jalr	a5
ffffffffc0201e4c:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e4e:	12040d63          	beqz	s0,ffffffffc0201f88 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e52:	000c4b17          	auipc	s6,0xc4
ffffffffc0201e56:	eeeb0b13          	addi	s6,s6,-274 # ffffffffc02c5d40 <pages>
ffffffffc0201e5a:	000b3503          	ld	a0,0(s6)
ffffffffc0201e5e:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e62:	000c4997          	auipc	s3,0xc4
ffffffffc0201e66:	ed698993          	addi	s3,s3,-298 # ffffffffc02c5d38 <npage>
ffffffffc0201e6a:	40a40533          	sub	a0,s0,a0
ffffffffc0201e6e:	8519                	srai	a0,a0,0x6
ffffffffc0201e70:	9556                	add	a0,a0,s5
ffffffffc0201e72:	0009b703          	ld	a4,0(s3)
ffffffffc0201e76:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e7a:	4685                	li	a3,1
ffffffffc0201e7c:	c014                	sw	a3,0(s0)
ffffffffc0201e7e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e80:	0532                	slli	a0,a0,0xc
ffffffffc0201e82:	16e7f763          	bgeu	a5,a4,ffffffffc0201ff0 <get_pte+0x1f4>
ffffffffc0201e86:	000c4797          	auipc	a5,0xc4
ffffffffc0201e8a:	eca7b783          	ld	a5,-310(a5) # ffffffffc02c5d50 <va_pa_offset>
ffffffffc0201e8e:	6605                	lui	a2,0x1
ffffffffc0201e90:	4581                	li	a1,0
ffffffffc0201e92:	953e                	add	a0,a0,a5
ffffffffc0201e94:	7c4030ef          	jal	ra,ffffffffc0205658 <memset>
    return page - pages + nbase;
ffffffffc0201e98:	000b3683          	ld	a3,0(s6)
ffffffffc0201e9c:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ea0:	8699                	srai	a3,a3,0x6
ffffffffc0201ea2:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ea4:	06aa                	slli	a3,a3,0xa
ffffffffc0201ea6:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201eaa:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201eac:	77fd                	lui	a5,0xfffff
ffffffffc0201eae:	068a                	slli	a3,a3,0x2
ffffffffc0201eb0:	0009b703          	ld	a4,0(s3)
ffffffffc0201eb4:	8efd                	and	a3,a3,a5
ffffffffc0201eb6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201eba:	10e7ff63          	bgeu	a5,a4,ffffffffc0201fd8 <get_pte+0x1dc>
ffffffffc0201ebe:	000c4a97          	auipc	s5,0xc4
ffffffffc0201ec2:	e92a8a93          	addi	s5,s5,-366 # ffffffffc02c5d50 <va_pa_offset>
ffffffffc0201ec6:	000ab403          	ld	s0,0(s5)
ffffffffc0201eca:	01595793          	srli	a5,s2,0x15
ffffffffc0201ece:	1ff7f793          	andi	a5,a5,511
ffffffffc0201ed2:	96a2                	add	a3,a3,s0
ffffffffc0201ed4:	00379413          	slli	s0,a5,0x3
ffffffffc0201ed8:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201eda:	6014                	ld	a3,0(s0)
ffffffffc0201edc:	0016f793          	andi	a5,a3,1
ffffffffc0201ee0:	ebad                	bnez	a5,ffffffffc0201f52 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201ee2:	0a0a0363          	beqz	s4,ffffffffc0201f88 <get_pte+0x18c>
ffffffffc0201ee6:	100027f3          	csrr	a5,sstatus
ffffffffc0201eea:	8b89                	andi	a5,a5,2
ffffffffc0201eec:	efcd                	bnez	a5,ffffffffc0201fa6 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eee:	000c4797          	auipc	a5,0xc4
ffffffffc0201ef2:	e5a7b783          	ld	a5,-422(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201ef6:	6f9c                	ld	a5,24(a5)
ffffffffc0201ef8:	4505                	li	a0,1
ffffffffc0201efa:	9782                	jalr	a5
ffffffffc0201efc:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201efe:	c4c9                	beqz	s1,ffffffffc0201f88 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201f00:	000c4b17          	auipc	s6,0xc4
ffffffffc0201f04:	e40b0b13          	addi	s6,s6,-448 # ffffffffc02c5d40 <pages>
ffffffffc0201f08:	000b3503          	ld	a0,0(s6)
ffffffffc0201f0c:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f10:	0009b703          	ld	a4,0(s3)
ffffffffc0201f14:	40a48533          	sub	a0,s1,a0
ffffffffc0201f18:	8519                	srai	a0,a0,0x6
ffffffffc0201f1a:	9552                	add	a0,a0,s4
ffffffffc0201f1c:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f20:	4685                	li	a3,1
ffffffffc0201f22:	c094                	sw	a3,0(s1)
ffffffffc0201f24:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f26:	0532                	slli	a0,a0,0xc
ffffffffc0201f28:	0ee7f163          	bgeu	a5,a4,ffffffffc020200a <get_pte+0x20e>
ffffffffc0201f2c:	000ab783          	ld	a5,0(s5)
ffffffffc0201f30:	6605                	lui	a2,0x1
ffffffffc0201f32:	4581                	li	a1,0
ffffffffc0201f34:	953e                	add	a0,a0,a5
ffffffffc0201f36:	722030ef          	jal	ra,ffffffffc0205658 <memset>
    return page - pages + nbase;
ffffffffc0201f3a:	000b3683          	ld	a3,0(s6)
ffffffffc0201f3e:	40d486b3          	sub	a3,s1,a3
ffffffffc0201f42:	8699                	srai	a3,a3,0x6
ffffffffc0201f44:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f46:	06aa                	slli	a3,a3,0xa
ffffffffc0201f48:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f4c:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f4e:	0009b703          	ld	a4,0(s3)
ffffffffc0201f52:	068a                	slli	a3,a3,0x2
ffffffffc0201f54:	757d                	lui	a0,0xfffff
ffffffffc0201f56:	8ee9                	and	a3,a3,a0
ffffffffc0201f58:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f5c:	06e7f263          	bgeu	a5,a4,ffffffffc0201fc0 <get_pte+0x1c4>
ffffffffc0201f60:	000ab503          	ld	a0,0(s5)
ffffffffc0201f64:	00c95913          	srli	s2,s2,0xc
ffffffffc0201f68:	1ff97913          	andi	s2,s2,511
ffffffffc0201f6c:	96aa                	add	a3,a3,a0
ffffffffc0201f6e:	00391513          	slli	a0,s2,0x3
ffffffffc0201f72:	9536                	add	a0,a0,a3
}
ffffffffc0201f74:	70e2                	ld	ra,56(sp)
ffffffffc0201f76:	7442                	ld	s0,48(sp)
ffffffffc0201f78:	74a2                	ld	s1,40(sp)
ffffffffc0201f7a:	7902                	ld	s2,32(sp)
ffffffffc0201f7c:	69e2                	ld	s3,24(sp)
ffffffffc0201f7e:	6a42                	ld	s4,16(sp)
ffffffffc0201f80:	6aa2                	ld	s5,8(sp)
ffffffffc0201f82:	6b02                	ld	s6,0(sp)
ffffffffc0201f84:	6121                	addi	sp,sp,64
ffffffffc0201f86:	8082                	ret
            return NULL;
ffffffffc0201f88:	4501                	li	a0,0
ffffffffc0201f8a:	b7ed                	j	ffffffffc0201f74 <get_pte+0x178>
        intr_disable();
ffffffffc0201f8c:	a0bfe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f90:	000c4797          	auipc	a5,0xc4
ffffffffc0201f94:	db87b783          	ld	a5,-584(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201f98:	6f9c                	ld	a5,24(a5)
ffffffffc0201f9a:	4505                	li	a0,1
ffffffffc0201f9c:	9782                	jalr	a5
ffffffffc0201f9e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201fa0:	9f1fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0201fa4:	b56d                	j	ffffffffc0201e4e <get_pte+0x52>
        intr_disable();
ffffffffc0201fa6:	9f1fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0201faa:	000c4797          	auipc	a5,0xc4
ffffffffc0201fae:	d9e7b783          	ld	a5,-610(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0201fb2:	6f9c                	ld	a5,24(a5)
ffffffffc0201fb4:	4505                	li	a0,1
ffffffffc0201fb6:	9782                	jalr	a5
ffffffffc0201fb8:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201fba:	9d7fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0201fbe:	b781                	j	ffffffffc0201efe <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201fc0:	00004617          	auipc	a2,0x4
ffffffffc0201fc4:	53060613          	addi	a2,a2,1328 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0201fc8:	0fa00593          	li	a1,250
ffffffffc0201fcc:	00004517          	auipc	a0,0x4
ffffffffc0201fd0:	63c50513          	addi	a0,a0,1596 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0201fd4:	cbefe0ef          	jal	ra,ffffffffc0200492 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201fd8:	00004617          	auipc	a2,0x4
ffffffffc0201fdc:	51860613          	addi	a2,a2,1304 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0201fe0:	0ed00593          	li	a1,237
ffffffffc0201fe4:	00004517          	auipc	a0,0x4
ffffffffc0201fe8:	62450513          	addi	a0,a0,1572 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0201fec:	ca6fe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ff0:	86aa                	mv	a3,a0
ffffffffc0201ff2:	00004617          	auipc	a2,0x4
ffffffffc0201ff6:	4fe60613          	addi	a2,a2,1278 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0201ffa:	0e900593          	li	a1,233
ffffffffc0201ffe:	00004517          	auipc	a0,0x4
ffffffffc0202002:	60a50513          	addi	a0,a0,1546 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202006:	c8cfe0ef          	jal	ra,ffffffffc0200492 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020200a:	86aa                	mv	a3,a0
ffffffffc020200c:	00004617          	auipc	a2,0x4
ffffffffc0202010:	4e460613          	addi	a2,a2,1252 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0202014:	0f700593          	li	a1,247
ffffffffc0202018:	00004517          	auipc	a0,0x4
ffffffffc020201c:	5f050513          	addi	a0,a0,1520 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202020:	c72fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202024 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202024:	1141                	addi	sp,sp,-16
ffffffffc0202026:	e022                	sd	s0,0(sp)
ffffffffc0202028:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020202a:	4601                	li	a2,0
{
ffffffffc020202c:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020202e:	dcfff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
    if (ptep_store != NULL)
ffffffffc0202032:	c011                	beqz	s0,ffffffffc0202036 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202034:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202036:	c511                	beqz	a0,ffffffffc0202042 <get_page+0x1e>
ffffffffc0202038:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020203a:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020203c:	0017f713          	andi	a4,a5,1
ffffffffc0202040:	e709                	bnez	a4,ffffffffc020204a <get_page+0x26>
}
ffffffffc0202042:	60a2                	ld	ra,8(sp)
ffffffffc0202044:	6402                	ld	s0,0(sp)
ffffffffc0202046:	0141                	addi	sp,sp,16
ffffffffc0202048:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020204a:	078a                	slli	a5,a5,0x2
ffffffffc020204c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020204e:	000c4717          	auipc	a4,0xc4
ffffffffc0202052:	cea73703          	ld	a4,-790(a4) # ffffffffc02c5d38 <npage>
ffffffffc0202056:	00e7ff63          	bgeu	a5,a4,ffffffffc0202074 <get_page+0x50>
ffffffffc020205a:	60a2                	ld	ra,8(sp)
ffffffffc020205c:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc020205e:	fff80537          	lui	a0,0xfff80
ffffffffc0202062:	97aa                	add	a5,a5,a0
ffffffffc0202064:	079a                	slli	a5,a5,0x6
ffffffffc0202066:	000c4517          	auipc	a0,0xc4
ffffffffc020206a:	cda53503          	ld	a0,-806(a0) # ffffffffc02c5d40 <pages>
ffffffffc020206e:	953e                	add	a0,a0,a5
ffffffffc0202070:	0141                	addi	sp,sp,16
ffffffffc0202072:	8082                	ret
ffffffffc0202074:	c99ff0ef          	jal	ra,ffffffffc0201d0c <pa2page.part.0>

ffffffffc0202078 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202078:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020207a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020207e:	f486                	sd	ra,104(sp)
ffffffffc0202080:	f0a2                	sd	s0,96(sp)
ffffffffc0202082:	eca6                	sd	s1,88(sp)
ffffffffc0202084:	e8ca                	sd	s2,80(sp)
ffffffffc0202086:	e4ce                	sd	s3,72(sp)
ffffffffc0202088:	e0d2                	sd	s4,64(sp)
ffffffffc020208a:	fc56                	sd	s5,56(sp)
ffffffffc020208c:	f85a                	sd	s6,48(sp)
ffffffffc020208e:	f45e                	sd	s7,40(sp)
ffffffffc0202090:	f062                	sd	s8,32(sp)
ffffffffc0202092:	ec66                	sd	s9,24(sp)
ffffffffc0202094:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202096:	17d2                	slli	a5,a5,0x34
ffffffffc0202098:	e3ed                	bnez	a5,ffffffffc020217a <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc020209a:	002007b7          	lui	a5,0x200
ffffffffc020209e:	842e                	mv	s0,a1
ffffffffc02020a0:	0ef5ed63          	bltu	a1,a5,ffffffffc020219a <unmap_range+0x122>
ffffffffc02020a4:	8932                	mv	s2,a2
ffffffffc02020a6:	0ec5fa63          	bgeu	a1,a2,ffffffffc020219a <unmap_range+0x122>
ffffffffc02020aa:	4785                	li	a5,1
ffffffffc02020ac:	07fe                	slli	a5,a5,0x1f
ffffffffc02020ae:	0ec7e663          	bltu	a5,a2,ffffffffc020219a <unmap_range+0x122>
ffffffffc02020b2:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02020b4:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc02020b6:	000c4c97          	auipc	s9,0xc4
ffffffffc02020ba:	c82c8c93          	addi	s9,s9,-894 # ffffffffc02c5d38 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02020be:	000c4c17          	auipc	s8,0xc4
ffffffffc02020c2:	c82c0c13          	addi	s8,s8,-894 # ffffffffc02c5d40 <pages>
ffffffffc02020c6:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02020ca:	000c4d17          	auipc	s10,0xc4
ffffffffc02020ce:	c7ed0d13          	addi	s10,s10,-898 # ffffffffc02c5d48 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02020d2:	00200b37          	lui	s6,0x200
ffffffffc02020d6:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02020da:	4601                	li	a2,0
ffffffffc02020dc:	85a2                	mv	a1,s0
ffffffffc02020de:	854e                	mv	a0,s3
ffffffffc02020e0:	d1dff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
ffffffffc02020e4:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02020e6:	cd29                	beqz	a0,ffffffffc0202140 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc02020e8:	611c                	ld	a5,0(a0)
ffffffffc02020ea:	e395                	bnez	a5,ffffffffc020210e <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02020ec:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02020ee:	ff2466e3          	bltu	s0,s2,ffffffffc02020da <unmap_range+0x62>
}
ffffffffc02020f2:	70a6                	ld	ra,104(sp)
ffffffffc02020f4:	7406                	ld	s0,96(sp)
ffffffffc02020f6:	64e6                	ld	s1,88(sp)
ffffffffc02020f8:	6946                	ld	s2,80(sp)
ffffffffc02020fa:	69a6                	ld	s3,72(sp)
ffffffffc02020fc:	6a06                	ld	s4,64(sp)
ffffffffc02020fe:	7ae2                	ld	s5,56(sp)
ffffffffc0202100:	7b42                	ld	s6,48(sp)
ffffffffc0202102:	7ba2                	ld	s7,40(sp)
ffffffffc0202104:	7c02                	ld	s8,32(sp)
ffffffffc0202106:	6ce2                	ld	s9,24(sp)
ffffffffc0202108:	6d42                	ld	s10,16(sp)
ffffffffc020210a:	6165                	addi	sp,sp,112
ffffffffc020210c:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc020210e:	0017f713          	andi	a4,a5,1
ffffffffc0202112:	df69                	beqz	a4,ffffffffc02020ec <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc0202114:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202118:	078a                	slli	a5,a5,0x2
ffffffffc020211a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020211c:	08e7ff63          	bgeu	a5,a4,ffffffffc02021ba <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0202120:	000c3503          	ld	a0,0(s8)
ffffffffc0202124:	97de                	add	a5,a5,s7
ffffffffc0202126:	079a                	slli	a5,a5,0x6
ffffffffc0202128:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020212a:	411c                	lw	a5,0(a0)
ffffffffc020212c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202130:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202132:	cf11                	beqz	a4,ffffffffc020214e <unmap_range+0xd6>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202134:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202138:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020213c:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020213e:	bf45                	j	ffffffffc02020ee <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202140:	945a                	add	s0,s0,s6
ffffffffc0202142:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202146:	d455                	beqz	s0,ffffffffc02020f2 <unmap_range+0x7a>
ffffffffc0202148:	f92469e3          	bltu	s0,s2,ffffffffc02020da <unmap_range+0x62>
ffffffffc020214c:	b75d                	j	ffffffffc02020f2 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020214e:	100027f3          	csrr	a5,sstatus
ffffffffc0202152:	8b89                	andi	a5,a5,2
ffffffffc0202154:	e799                	bnez	a5,ffffffffc0202162 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc0202156:	000d3783          	ld	a5,0(s10)
ffffffffc020215a:	4585                	li	a1,1
ffffffffc020215c:	739c                	ld	a5,32(a5)
ffffffffc020215e:	9782                	jalr	a5
    if (flag)
ffffffffc0202160:	bfd1                	j	ffffffffc0202134 <unmap_range+0xbc>
ffffffffc0202162:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202164:	833fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0202168:	000d3783          	ld	a5,0(s10)
ffffffffc020216c:	6522                	ld	a0,8(sp)
ffffffffc020216e:	4585                	li	a1,1
ffffffffc0202170:	739c                	ld	a5,32(a5)
ffffffffc0202172:	9782                	jalr	a5
        intr_enable();
ffffffffc0202174:	81dfe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202178:	bf75                	j	ffffffffc0202134 <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020217a:	00004697          	auipc	a3,0x4
ffffffffc020217e:	49e68693          	addi	a3,a3,1182 # ffffffffc0206618 <default_pmm_manager+0x160>
ffffffffc0202182:	00004617          	auipc	a2,0x4
ffffffffc0202186:	f8660613          	addi	a2,a2,-122 # ffffffffc0206108 <commands+0x818>
ffffffffc020218a:	12200593          	li	a1,290
ffffffffc020218e:	00004517          	auipc	a0,0x4
ffffffffc0202192:	47a50513          	addi	a0,a0,1146 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202196:	afcfe0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020219a:	00004697          	auipc	a3,0x4
ffffffffc020219e:	4ae68693          	addi	a3,a3,1198 # ffffffffc0206648 <default_pmm_manager+0x190>
ffffffffc02021a2:	00004617          	auipc	a2,0x4
ffffffffc02021a6:	f6660613          	addi	a2,a2,-154 # ffffffffc0206108 <commands+0x818>
ffffffffc02021aa:	12300593          	li	a1,291
ffffffffc02021ae:	00004517          	auipc	a0,0x4
ffffffffc02021b2:	45a50513          	addi	a0,a0,1114 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02021b6:	adcfe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc02021ba:	b53ff0ef          	jal	ra,ffffffffc0201d0c <pa2page.part.0>

ffffffffc02021be <exit_range>:
{
ffffffffc02021be:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021c0:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021c4:	fc86                	sd	ra,120(sp)
ffffffffc02021c6:	f8a2                	sd	s0,112(sp)
ffffffffc02021c8:	f4a6                	sd	s1,104(sp)
ffffffffc02021ca:	f0ca                	sd	s2,96(sp)
ffffffffc02021cc:	ecce                	sd	s3,88(sp)
ffffffffc02021ce:	e8d2                	sd	s4,80(sp)
ffffffffc02021d0:	e4d6                	sd	s5,72(sp)
ffffffffc02021d2:	e0da                	sd	s6,64(sp)
ffffffffc02021d4:	fc5e                	sd	s7,56(sp)
ffffffffc02021d6:	f862                	sd	s8,48(sp)
ffffffffc02021d8:	f466                	sd	s9,40(sp)
ffffffffc02021da:	f06a                	sd	s10,32(sp)
ffffffffc02021dc:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021de:	17d2                	slli	a5,a5,0x34
ffffffffc02021e0:	20079a63          	bnez	a5,ffffffffc02023f4 <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02021e4:	002007b7          	lui	a5,0x200
ffffffffc02021e8:	24f5e463          	bltu	a1,a5,ffffffffc0202430 <exit_range+0x272>
ffffffffc02021ec:	8ab2                	mv	s5,a2
ffffffffc02021ee:	24c5f163          	bgeu	a1,a2,ffffffffc0202430 <exit_range+0x272>
ffffffffc02021f2:	4785                	li	a5,1
ffffffffc02021f4:	07fe                	slli	a5,a5,0x1f
ffffffffc02021f6:	22c7ed63          	bltu	a5,a2,ffffffffc0202430 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02021fa:	c00009b7          	lui	s3,0xc0000
ffffffffc02021fe:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202202:	ffe00937          	lui	s2,0xffe00
ffffffffc0202206:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc020220a:	5cfd                	li	s9,-1
ffffffffc020220c:	8c2a                	mv	s8,a0
ffffffffc020220e:	0125f933          	and	s2,a1,s2
ffffffffc0202212:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc0202214:	000c4d17          	auipc	s10,0xc4
ffffffffc0202218:	b24d0d13          	addi	s10,s10,-1244 # ffffffffc02c5d38 <npage>
    return KADDR(page2pa(page));
ffffffffc020221c:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202220:	000c4717          	auipc	a4,0xc4
ffffffffc0202224:	b2070713          	addi	a4,a4,-1248 # ffffffffc02c5d40 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc0202228:	000c4d97          	auipc	s11,0xc4
ffffffffc020222c:	b20d8d93          	addi	s11,s11,-1248 # ffffffffc02c5d48 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202230:	c0000437          	lui	s0,0xc0000
ffffffffc0202234:	944e                	add	s0,s0,s3
ffffffffc0202236:	8079                	srli	s0,s0,0x1e
ffffffffc0202238:	1ff47413          	andi	s0,s0,511
ffffffffc020223c:	040e                	slli	s0,s0,0x3
ffffffffc020223e:	9462                	add	s0,s0,s8
ffffffffc0202240:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_matrix_out_size+0xffffffffbfff38d8>
        if (pde1 & PTE_V)
ffffffffc0202244:	001a7793          	andi	a5,s4,1
ffffffffc0202248:	eb99                	bnez	a5,ffffffffc020225e <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc020224a:	12098463          	beqz	s3,ffffffffc0202372 <exit_range+0x1b4>
ffffffffc020224e:	400007b7          	lui	a5,0x40000
ffffffffc0202252:	97ce                	add	a5,a5,s3
ffffffffc0202254:	894e                	mv	s2,s3
ffffffffc0202256:	1159fe63          	bgeu	s3,s5,ffffffffc0202372 <exit_range+0x1b4>
ffffffffc020225a:	89be                	mv	s3,a5
ffffffffc020225c:	bfd1                	j	ffffffffc0202230 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc020225e:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202262:	0a0a                	slli	s4,s4,0x2
ffffffffc0202264:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202268:	1cfa7263          	bgeu	s4,a5,ffffffffc020242c <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020226c:	fff80637          	lui	a2,0xfff80
ffffffffc0202270:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0202272:	000806b7          	lui	a3,0x80
ffffffffc0202276:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202278:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc020227c:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020227e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202280:	18f5fa63          	bgeu	a1,a5,ffffffffc0202414 <exit_range+0x256>
ffffffffc0202284:	000c4817          	auipc	a6,0xc4
ffffffffc0202288:	acc80813          	addi	a6,a6,-1332 # ffffffffc02c5d50 <va_pa_offset>
ffffffffc020228c:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202290:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202292:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202296:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202298:	00080337          	lui	t1,0x80
ffffffffc020229c:	6885                	lui	a7,0x1
ffffffffc020229e:	a819                	j	ffffffffc02022b4 <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc02022a0:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02022a2:	002007b7          	lui	a5,0x200
ffffffffc02022a6:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02022a8:	08090c63          	beqz	s2,ffffffffc0202340 <exit_range+0x182>
ffffffffc02022ac:	09397a63          	bgeu	s2,s3,ffffffffc0202340 <exit_range+0x182>
ffffffffc02022b0:	0f597063          	bgeu	s2,s5,ffffffffc0202390 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02022b4:	01595493          	srli	s1,s2,0x15
ffffffffc02022b8:	1ff4f493          	andi	s1,s1,511
ffffffffc02022bc:	048e                	slli	s1,s1,0x3
ffffffffc02022be:	94da                	add	s1,s1,s6
ffffffffc02022c0:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc02022c2:	0017f693          	andi	a3,a5,1
ffffffffc02022c6:	dee9                	beqz	a3,ffffffffc02022a0 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc02022c8:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02022cc:	078a                	slli	a5,a5,0x2
ffffffffc02022ce:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022d0:	14b7fe63          	bgeu	a5,a1,ffffffffc020242c <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022d4:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02022d6:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02022da:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02022de:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02022e2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02022e4:	12bef863          	bgeu	t4,a1,ffffffffc0202414 <exit_range+0x256>
ffffffffc02022e8:	00083783          	ld	a5,0(a6)
ffffffffc02022ec:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02022ee:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc02022f2:	629c                	ld	a5,0(a3)
ffffffffc02022f4:	8b85                	andi	a5,a5,1
ffffffffc02022f6:	f7d5                	bnez	a5,ffffffffc02022a2 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02022f8:	06a1                	addi	a3,a3,8
ffffffffc02022fa:	fed59ce3          	bne	a1,a3,ffffffffc02022f2 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02022fe:	631c                	ld	a5,0(a4)
ffffffffc0202300:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202302:	100027f3          	csrr	a5,sstatus
ffffffffc0202306:	8b89                	andi	a5,a5,2
ffffffffc0202308:	e7d9                	bnez	a5,ffffffffc0202396 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc020230a:	000db783          	ld	a5,0(s11)
ffffffffc020230e:	4585                	li	a1,1
ffffffffc0202310:	e032                	sd	a2,0(sp)
ffffffffc0202312:	739c                	ld	a5,32(a5)
ffffffffc0202314:	9782                	jalr	a5
    if (flag)
ffffffffc0202316:	6602                	ld	a2,0(sp)
ffffffffc0202318:	000c4817          	auipc	a6,0xc4
ffffffffc020231c:	a3880813          	addi	a6,a6,-1480 # ffffffffc02c5d50 <va_pa_offset>
ffffffffc0202320:	fff80e37          	lui	t3,0xfff80
ffffffffc0202324:	00080337          	lui	t1,0x80
ffffffffc0202328:	6885                	lui	a7,0x1
ffffffffc020232a:	000c4717          	auipc	a4,0xc4
ffffffffc020232e:	a1670713          	addi	a4,a4,-1514 # ffffffffc02c5d40 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202332:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0202336:	002007b7          	lui	a5,0x200
ffffffffc020233a:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020233c:	f60918e3          	bnez	s2,ffffffffc02022ac <exit_range+0xee>
            if (free_pd0)
ffffffffc0202340:	f00b85e3          	beqz	s7,ffffffffc020224a <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc0202344:	000d3783          	ld	a5,0(s10)
ffffffffc0202348:	0efa7263          	bgeu	s4,a5,ffffffffc020242c <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020234c:	6308                	ld	a0,0(a4)
ffffffffc020234e:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202350:	100027f3          	csrr	a5,sstatus
ffffffffc0202354:	8b89                	andi	a5,a5,2
ffffffffc0202356:	efad                	bnez	a5,ffffffffc02023d0 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202358:	000db783          	ld	a5,0(s11)
ffffffffc020235c:	4585                	li	a1,1
ffffffffc020235e:	739c                	ld	a5,32(a5)
ffffffffc0202360:	9782                	jalr	a5
ffffffffc0202362:	000c4717          	auipc	a4,0xc4
ffffffffc0202366:	9de70713          	addi	a4,a4,-1570 # ffffffffc02c5d40 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc020236a:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc020236e:	ee0990e3          	bnez	s3,ffffffffc020224e <exit_range+0x90>
}
ffffffffc0202372:	70e6                	ld	ra,120(sp)
ffffffffc0202374:	7446                	ld	s0,112(sp)
ffffffffc0202376:	74a6                	ld	s1,104(sp)
ffffffffc0202378:	7906                	ld	s2,96(sp)
ffffffffc020237a:	69e6                	ld	s3,88(sp)
ffffffffc020237c:	6a46                	ld	s4,80(sp)
ffffffffc020237e:	6aa6                	ld	s5,72(sp)
ffffffffc0202380:	6b06                	ld	s6,64(sp)
ffffffffc0202382:	7be2                	ld	s7,56(sp)
ffffffffc0202384:	7c42                	ld	s8,48(sp)
ffffffffc0202386:	7ca2                	ld	s9,40(sp)
ffffffffc0202388:	7d02                	ld	s10,32(sp)
ffffffffc020238a:	6de2                	ld	s11,24(sp)
ffffffffc020238c:	6109                	addi	sp,sp,128
ffffffffc020238e:	8082                	ret
            if (free_pd0)
ffffffffc0202390:	ea0b8fe3          	beqz	s7,ffffffffc020224e <exit_range+0x90>
ffffffffc0202394:	bf45                	j	ffffffffc0202344 <exit_range+0x186>
ffffffffc0202396:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202398:	e42a                	sd	a0,8(sp)
ffffffffc020239a:	dfcfe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020239e:	000db783          	ld	a5,0(s11)
ffffffffc02023a2:	6522                	ld	a0,8(sp)
ffffffffc02023a4:	4585                	li	a1,1
ffffffffc02023a6:	739c                	ld	a5,32(a5)
ffffffffc02023a8:	9782                	jalr	a5
        intr_enable();
ffffffffc02023aa:	de6fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc02023ae:	6602                	ld	a2,0(sp)
ffffffffc02023b0:	000c4717          	auipc	a4,0xc4
ffffffffc02023b4:	99070713          	addi	a4,a4,-1648 # ffffffffc02c5d40 <pages>
ffffffffc02023b8:	6885                	lui	a7,0x1
ffffffffc02023ba:	00080337          	lui	t1,0x80
ffffffffc02023be:	fff80e37          	lui	t3,0xfff80
ffffffffc02023c2:	000c4817          	auipc	a6,0xc4
ffffffffc02023c6:	98e80813          	addi	a6,a6,-1650 # ffffffffc02c5d50 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02023ca:	0004b023          	sd	zero,0(s1)
ffffffffc02023ce:	b7a5                	j	ffffffffc0202336 <exit_range+0x178>
ffffffffc02023d0:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc02023d2:	dc4fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02023d6:	000db783          	ld	a5,0(s11)
ffffffffc02023da:	6502                	ld	a0,0(sp)
ffffffffc02023dc:	4585                	li	a1,1
ffffffffc02023de:	739c                	ld	a5,32(a5)
ffffffffc02023e0:	9782                	jalr	a5
        intr_enable();
ffffffffc02023e2:	daefe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc02023e6:	000c4717          	auipc	a4,0xc4
ffffffffc02023ea:	95a70713          	addi	a4,a4,-1702 # ffffffffc02c5d40 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02023ee:	00043023          	sd	zero,0(s0)
ffffffffc02023f2:	bfb5                	j	ffffffffc020236e <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023f4:	00004697          	auipc	a3,0x4
ffffffffc02023f8:	22468693          	addi	a3,a3,548 # ffffffffc0206618 <default_pmm_manager+0x160>
ffffffffc02023fc:	00004617          	auipc	a2,0x4
ffffffffc0202400:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206108 <commands+0x818>
ffffffffc0202404:	13700593          	li	a1,311
ffffffffc0202408:	00004517          	auipc	a0,0x4
ffffffffc020240c:	20050513          	addi	a0,a0,512 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202410:	882fe0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202414:	00004617          	auipc	a2,0x4
ffffffffc0202418:	0dc60613          	addi	a2,a2,220 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc020241c:	07100593          	li	a1,113
ffffffffc0202420:	00004517          	auipc	a0,0x4
ffffffffc0202424:	0f850513          	addi	a0,a0,248 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0202428:	86afe0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc020242c:	8e1ff0ef          	jal	ra,ffffffffc0201d0c <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202430:	00004697          	auipc	a3,0x4
ffffffffc0202434:	21868693          	addi	a3,a3,536 # ffffffffc0206648 <default_pmm_manager+0x190>
ffffffffc0202438:	00004617          	auipc	a2,0x4
ffffffffc020243c:	cd060613          	addi	a2,a2,-816 # ffffffffc0206108 <commands+0x818>
ffffffffc0202440:	13800593          	li	a1,312
ffffffffc0202444:	00004517          	auipc	a0,0x4
ffffffffc0202448:	1c450513          	addi	a0,a0,452 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020244c:	846fe0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0202450 <copy_range>:
{
ffffffffc0202450:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202452:	00d667b3          	or	a5,a2,a3
{
ffffffffc0202456:	fc86                	sd	ra,120(sp)
ffffffffc0202458:	f8a2                	sd	s0,112(sp)
ffffffffc020245a:	f4a6                	sd	s1,104(sp)
ffffffffc020245c:	f0ca                	sd	s2,96(sp)
ffffffffc020245e:	ecce                	sd	s3,88(sp)
ffffffffc0202460:	e8d2                	sd	s4,80(sp)
ffffffffc0202462:	e4d6                	sd	s5,72(sp)
ffffffffc0202464:	e0da                	sd	s6,64(sp)
ffffffffc0202466:	fc5e                	sd	s7,56(sp)
ffffffffc0202468:	f862                	sd	s8,48(sp)
ffffffffc020246a:	f466                	sd	s9,40(sp)
ffffffffc020246c:	f06a                	sd	s10,32(sp)
ffffffffc020246e:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202470:	17d2                	slli	a5,a5,0x34
ffffffffc0202472:	16079e63          	bnez	a5,ffffffffc02025ee <copy_range+0x19e>
    assert(USER_ACCESS(start, end));
ffffffffc0202476:	002007b7          	lui	a5,0x200
ffffffffc020247a:	8db2                	mv	s11,a2
ffffffffc020247c:	12f66d63          	bltu	a2,a5,ffffffffc02025b6 <copy_range+0x166>
ffffffffc0202480:	84b6                	mv	s1,a3
ffffffffc0202482:	12d67a63          	bgeu	a2,a3,ffffffffc02025b6 <copy_range+0x166>
ffffffffc0202486:	4785                	li	a5,1
ffffffffc0202488:	07fe                	slli	a5,a5,0x1f
ffffffffc020248a:	12d7e663          	bltu	a5,a3,ffffffffc02025b6 <copy_range+0x166>
ffffffffc020248e:	8a2a                	mv	s4,a0
ffffffffc0202490:	892e                	mv	s2,a1
        start += PGSIZE;
ffffffffc0202492:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage)
ffffffffc0202494:	000c4c17          	auipc	s8,0xc4
ffffffffc0202498:	8a4c0c13          	addi	s8,s8,-1884 # ffffffffc02c5d38 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020249c:	000c4b97          	auipc	s7,0xc4
ffffffffc02024a0:	8a4b8b93          	addi	s7,s7,-1884 # ffffffffc02c5d40 <pages>
ffffffffc02024a4:	fff80b37          	lui	s6,0xfff80
        page = pmm_manager->alloc_pages(n);
ffffffffc02024a8:	000c4a97          	auipc	s5,0xc4
ffffffffc02024ac:	8a0a8a93          	addi	s5,s5,-1888 # ffffffffc02c5d48 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02024b0:	00200d37          	lui	s10,0x200
ffffffffc02024b4:	ffe00cb7          	lui	s9,0xffe00
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02024b8:	4601                	li	a2,0
ffffffffc02024ba:	85ee                	mv	a1,s11
ffffffffc02024bc:	854a                	mv	a0,s2
ffffffffc02024be:	93fff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
ffffffffc02024c2:	842a                	mv	s0,a0
        if (ptep == NULL)
ffffffffc02024c4:	c559                	beqz	a0,ffffffffc0202552 <copy_range+0x102>
        if (*ptep & PTE_V)
ffffffffc02024c6:	611c                	ld	a5,0(a0)
ffffffffc02024c8:	8b85                	andi	a5,a5,1
ffffffffc02024ca:	e785                	bnez	a5,ffffffffc02024f2 <copy_range+0xa2>
        start += PGSIZE;
ffffffffc02024cc:	9dce                	add	s11,s11,s3
    } while (start != 0 && start < end);
ffffffffc02024ce:	fe9de5e3          	bltu	s11,s1,ffffffffc02024b8 <copy_range+0x68>
    return 0;
ffffffffc02024d2:	4501                	li	a0,0
}
ffffffffc02024d4:	70e6                	ld	ra,120(sp)
ffffffffc02024d6:	7446                	ld	s0,112(sp)
ffffffffc02024d8:	74a6                	ld	s1,104(sp)
ffffffffc02024da:	7906                	ld	s2,96(sp)
ffffffffc02024dc:	69e6                	ld	s3,88(sp)
ffffffffc02024de:	6a46                	ld	s4,80(sp)
ffffffffc02024e0:	6aa6                	ld	s5,72(sp)
ffffffffc02024e2:	6b06                	ld	s6,64(sp)
ffffffffc02024e4:	7be2                	ld	s7,56(sp)
ffffffffc02024e6:	7c42                	ld	s8,48(sp)
ffffffffc02024e8:	7ca2                	ld	s9,40(sp)
ffffffffc02024ea:	7d02                	ld	s10,32(sp)
ffffffffc02024ec:	6de2                	ld	s11,24(sp)
ffffffffc02024ee:	6109                	addi	sp,sp,128
ffffffffc02024f0:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02024f2:	4605                	li	a2,1
ffffffffc02024f4:	85ee                	mv	a1,s11
ffffffffc02024f6:	8552                	mv	a0,s4
ffffffffc02024f8:	905ff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
ffffffffc02024fc:	cd3d                	beqz	a0,ffffffffc020257a <copy_range+0x12a>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02024fe:	601c                	ld	a5,0(s0)
    if (!(pte & PTE_V))
ffffffffc0202500:	0017f713          	andi	a4,a5,1
ffffffffc0202504:	cb69                	beqz	a4,ffffffffc02025d6 <copy_range+0x186>
    if (PPN(pa) >= npage)
ffffffffc0202506:	000c3703          	ld	a4,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020250a:	078a                	slli	a5,a5,0x2
ffffffffc020250c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020250e:	08e7f863          	bgeu	a5,a4,ffffffffc020259e <copy_range+0x14e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202512:	000bb403          	ld	s0,0(s7)
ffffffffc0202516:	97da                	add	a5,a5,s6
ffffffffc0202518:	079a                	slli	a5,a5,0x6
ffffffffc020251a:	943e                	add	s0,s0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020251c:	100027f3          	csrr	a5,sstatus
ffffffffc0202520:	8b89                	andi	a5,a5,2
ffffffffc0202522:	e3a1                	bnez	a5,ffffffffc0202562 <copy_range+0x112>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202524:	000ab783          	ld	a5,0(s5)
ffffffffc0202528:	4505                	li	a0,1
ffffffffc020252a:	6f9c                	ld	a5,24(a5)
ffffffffc020252c:	9782                	jalr	a5
            assert(page != NULL);
ffffffffc020252e:	c821                	beqz	s0,ffffffffc020257e <copy_range+0x12e>
            assert(npage != NULL);
ffffffffc0202530:	fd51                	bnez	a0,ffffffffc02024cc <copy_range+0x7c>
ffffffffc0202532:	00004697          	auipc	a3,0x4
ffffffffc0202536:	13e68693          	addi	a3,a3,318 # ffffffffc0206670 <default_pmm_manager+0x1b8>
ffffffffc020253a:	00004617          	auipc	a2,0x4
ffffffffc020253e:	bce60613          	addi	a2,a2,-1074 # ffffffffc0206108 <commands+0x818>
ffffffffc0202542:	19700593          	li	a1,407
ffffffffc0202546:	00004517          	auipc	a0,0x4
ffffffffc020254a:	0c250513          	addi	a0,a0,194 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020254e:	f45fd0ef          	jal	ra,ffffffffc0200492 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202552:	9dea                	add	s11,s11,s10
ffffffffc0202554:	019dfdb3          	and	s11,s11,s9
    } while (start != 0 && start < end);
ffffffffc0202558:	f60d8de3          	beqz	s11,ffffffffc02024d2 <copy_range+0x82>
ffffffffc020255c:	f49deee3          	bltu	s11,s1,ffffffffc02024b8 <copy_range+0x68>
ffffffffc0202560:	bf8d                	j	ffffffffc02024d2 <copy_range+0x82>
        intr_disable();
ffffffffc0202562:	c34fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202566:	000ab783          	ld	a5,0(s5)
ffffffffc020256a:	4505                	li	a0,1
ffffffffc020256c:	6f9c                	ld	a5,24(a5)
ffffffffc020256e:	9782                	jalr	a5
ffffffffc0202570:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202572:	c1efe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202576:	6522                	ld	a0,8(sp)
ffffffffc0202578:	bf5d                	j	ffffffffc020252e <copy_range+0xde>
                return -E_NO_MEM;
ffffffffc020257a:	5571                	li	a0,-4
ffffffffc020257c:	bfa1                	j	ffffffffc02024d4 <copy_range+0x84>
            assert(page != NULL);
ffffffffc020257e:	00004697          	auipc	a3,0x4
ffffffffc0202582:	0e268693          	addi	a3,a3,226 # ffffffffc0206660 <default_pmm_manager+0x1a8>
ffffffffc0202586:	00004617          	auipc	a2,0x4
ffffffffc020258a:	b8260613          	addi	a2,a2,-1150 # ffffffffc0206108 <commands+0x818>
ffffffffc020258e:	19600593          	li	a1,406
ffffffffc0202592:	00004517          	auipc	a0,0x4
ffffffffc0202596:	07650513          	addi	a0,a0,118 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020259a:	ef9fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020259e:	00004617          	auipc	a2,0x4
ffffffffc02025a2:	02260613          	addi	a2,a2,34 # ffffffffc02065c0 <default_pmm_manager+0x108>
ffffffffc02025a6:	06900593          	li	a1,105
ffffffffc02025aa:	00004517          	auipc	a0,0x4
ffffffffc02025ae:	f6e50513          	addi	a0,a0,-146 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc02025b2:	ee1fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02025b6:	00004697          	auipc	a3,0x4
ffffffffc02025ba:	09268693          	addi	a3,a3,146 # ffffffffc0206648 <default_pmm_manager+0x190>
ffffffffc02025be:	00004617          	auipc	a2,0x4
ffffffffc02025c2:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0206108 <commands+0x818>
ffffffffc02025c6:	17e00593          	li	a1,382
ffffffffc02025ca:	00004517          	auipc	a0,0x4
ffffffffc02025ce:	03e50513          	addi	a0,a0,62 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02025d2:	ec1fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02025d6:	00004617          	auipc	a2,0x4
ffffffffc02025da:	00a60613          	addi	a2,a2,10 # ffffffffc02065e0 <default_pmm_manager+0x128>
ffffffffc02025de:	07f00593          	li	a1,127
ffffffffc02025e2:	00004517          	auipc	a0,0x4
ffffffffc02025e6:	f3650513          	addi	a0,a0,-202 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc02025ea:	ea9fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025ee:	00004697          	auipc	a3,0x4
ffffffffc02025f2:	02a68693          	addi	a3,a3,42 # ffffffffc0206618 <default_pmm_manager+0x160>
ffffffffc02025f6:	00004617          	auipc	a2,0x4
ffffffffc02025fa:	b1260613          	addi	a2,a2,-1262 # ffffffffc0206108 <commands+0x818>
ffffffffc02025fe:	17d00593          	li	a1,381
ffffffffc0202602:	00004517          	auipc	a0,0x4
ffffffffc0202606:	00650513          	addi	a0,a0,6 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020260a:	e89fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020260e <page_remove>:
{
ffffffffc020260e:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202610:	4601                	li	a2,0
{
ffffffffc0202612:	ec26                	sd	s1,24(sp)
ffffffffc0202614:	f406                	sd	ra,40(sp)
ffffffffc0202616:	f022                	sd	s0,32(sp)
ffffffffc0202618:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020261a:	fe2ff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
    if (ptep != NULL)
ffffffffc020261e:	c511                	beqz	a0,ffffffffc020262a <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0202620:	611c                	ld	a5,0(a0)
ffffffffc0202622:	842a                	mv	s0,a0
ffffffffc0202624:	0017f713          	andi	a4,a5,1
ffffffffc0202628:	e711                	bnez	a4,ffffffffc0202634 <page_remove+0x26>
}
ffffffffc020262a:	70a2                	ld	ra,40(sp)
ffffffffc020262c:	7402                	ld	s0,32(sp)
ffffffffc020262e:	64e2                	ld	s1,24(sp)
ffffffffc0202630:	6145                	addi	sp,sp,48
ffffffffc0202632:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202634:	078a                	slli	a5,a5,0x2
ffffffffc0202636:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202638:	000c3717          	auipc	a4,0xc3
ffffffffc020263c:	70073703          	ld	a4,1792(a4) # ffffffffc02c5d38 <npage>
ffffffffc0202640:	06e7f363          	bgeu	a5,a4,ffffffffc02026a6 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202644:	fff80537          	lui	a0,0xfff80
ffffffffc0202648:	97aa                	add	a5,a5,a0
ffffffffc020264a:	079a                	slli	a5,a5,0x6
ffffffffc020264c:	000c3517          	auipc	a0,0xc3
ffffffffc0202650:	6f453503          	ld	a0,1780(a0) # ffffffffc02c5d40 <pages>
ffffffffc0202654:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202656:	411c                	lw	a5,0(a0)
ffffffffc0202658:	fff7871b          	addiw	a4,a5,-1
ffffffffc020265c:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020265e:	cb11                	beqz	a4,ffffffffc0202672 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202660:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202664:	12048073          	sfence.vma	s1
}
ffffffffc0202668:	70a2                	ld	ra,40(sp)
ffffffffc020266a:	7402                	ld	s0,32(sp)
ffffffffc020266c:	64e2                	ld	s1,24(sp)
ffffffffc020266e:	6145                	addi	sp,sp,48
ffffffffc0202670:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202672:	100027f3          	csrr	a5,sstatus
ffffffffc0202676:	8b89                	andi	a5,a5,2
ffffffffc0202678:	eb89                	bnez	a5,ffffffffc020268a <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc020267a:	000c3797          	auipc	a5,0xc3
ffffffffc020267e:	6ce7b783          	ld	a5,1742(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0202682:	739c                	ld	a5,32(a5)
ffffffffc0202684:	4585                	li	a1,1
ffffffffc0202686:	9782                	jalr	a5
    if (flag)
ffffffffc0202688:	bfe1                	j	ffffffffc0202660 <page_remove+0x52>
        intr_disable();
ffffffffc020268a:	e42a                	sd	a0,8(sp)
ffffffffc020268c:	b0afe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0202690:	000c3797          	auipc	a5,0xc3
ffffffffc0202694:	6b87b783          	ld	a5,1720(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0202698:	739c                	ld	a5,32(a5)
ffffffffc020269a:	6522                	ld	a0,8(sp)
ffffffffc020269c:	4585                	li	a1,1
ffffffffc020269e:	9782                	jalr	a5
        intr_enable();
ffffffffc02026a0:	af0fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc02026a4:	bf75                	j	ffffffffc0202660 <page_remove+0x52>
ffffffffc02026a6:	e66ff0ef          	jal	ra,ffffffffc0201d0c <pa2page.part.0>

ffffffffc02026aa <page_insert>:
{
ffffffffc02026aa:	7139                	addi	sp,sp,-64
ffffffffc02026ac:	e852                	sd	s4,16(sp)
ffffffffc02026ae:	8a32                	mv	s4,a2
ffffffffc02026b0:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026b2:	4605                	li	a2,1
{
ffffffffc02026b4:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026b6:	85d2                	mv	a1,s4
{
ffffffffc02026b8:	f426                	sd	s1,40(sp)
ffffffffc02026ba:	fc06                	sd	ra,56(sp)
ffffffffc02026bc:	f04a                	sd	s2,32(sp)
ffffffffc02026be:	ec4e                	sd	s3,24(sp)
ffffffffc02026c0:	e456                	sd	s5,8(sp)
ffffffffc02026c2:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026c4:	f38ff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
    if (ptep == NULL)
ffffffffc02026c8:	c961                	beqz	a0,ffffffffc0202798 <page_insert+0xee>
    page->ref += 1;
ffffffffc02026ca:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026cc:	611c                	ld	a5,0(a0)
ffffffffc02026ce:	89aa                	mv	s3,a0
ffffffffc02026d0:	0016871b          	addiw	a4,a3,1
ffffffffc02026d4:	c018                	sw	a4,0(s0)
ffffffffc02026d6:	0017f713          	andi	a4,a5,1
ffffffffc02026da:	ef05                	bnez	a4,ffffffffc0202712 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02026dc:	000c3717          	auipc	a4,0xc3
ffffffffc02026e0:	66473703          	ld	a4,1636(a4) # ffffffffc02c5d40 <pages>
ffffffffc02026e4:	8c19                	sub	s0,s0,a4
ffffffffc02026e6:	000807b7          	lui	a5,0x80
ffffffffc02026ea:	8419                	srai	s0,s0,0x6
ffffffffc02026ec:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026ee:	042a                	slli	s0,s0,0xa
ffffffffc02026f0:	8cc1                	or	s1,s1,s0
ffffffffc02026f2:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026f6:	0099b023          	sd	s1,0(s3) # 1000 <_binary_obj___user_faultread_out_size-0x8f50>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026fa:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02026fe:	4501                	li	a0,0
}
ffffffffc0202700:	70e2                	ld	ra,56(sp)
ffffffffc0202702:	7442                	ld	s0,48(sp)
ffffffffc0202704:	74a2                	ld	s1,40(sp)
ffffffffc0202706:	7902                	ld	s2,32(sp)
ffffffffc0202708:	69e2                	ld	s3,24(sp)
ffffffffc020270a:	6a42                	ld	s4,16(sp)
ffffffffc020270c:	6aa2                	ld	s5,8(sp)
ffffffffc020270e:	6121                	addi	sp,sp,64
ffffffffc0202710:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202712:	078a                	slli	a5,a5,0x2
ffffffffc0202714:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202716:	000c3717          	auipc	a4,0xc3
ffffffffc020271a:	62273703          	ld	a4,1570(a4) # ffffffffc02c5d38 <npage>
ffffffffc020271e:	06e7ff63          	bgeu	a5,a4,ffffffffc020279c <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202722:	000c3a97          	auipc	s5,0xc3
ffffffffc0202726:	61ea8a93          	addi	s5,s5,1566 # ffffffffc02c5d40 <pages>
ffffffffc020272a:	000ab703          	ld	a4,0(s5)
ffffffffc020272e:	fff80937          	lui	s2,0xfff80
ffffffffc0202732:	993e                	add	s2,s2,a5
ffffffffc0202734:	091a                	slli	s2,s2,0x6
ffffffffc0202736:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202738:	01240c63          	beq	s0,s2,ffffffffc0202750 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc020273c:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcba278>
ffffffffc0202740:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202744:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0202748:	c691                	beqz	a3,ffffffffc0202754 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020274a:	120a0073          	sfence.vma	s4
}
ffffffffc020274e:	bf59                	j	ffffffffc02026e4 <page_insert+0x3a>
ffffffffc0202750:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202752:	bf49                	j	ffffffffc02026e4 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202754:	100027f3          	csrr	a5,sstatus
ffffffffc0202758:	8b89                	andi	a5,a5,2
ffffffffc020275a:	ef91                	bnez	a5,ffffffffc0202776 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020275c:	000c3797          	auipc	a5,0xc3
ffffffffc0202760:	5ec7b783          	ld	a5,1516(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0202764:	739c                	ld	a5,32(a5)
ffffffffc0202766:	4585                	li	a1,1
ffffffffc0202768:	854a                	mv	a0,s2
ffffffffc020276a:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020276c:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202770:	120a0073          	sfence.vma	s4
ffffffffc0202774:	bf85                	j	ffffffffc02026e4 <page_insert+0x3a>
        intr_disable();
ffffffffc0202776:	a20fe0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020277a:	000c3797          	auipc	a5,0xc3
ffffffffc020277e:	5ce7b783          	ld	a5,1486(a5) # ffffffffc02c5d48 <pmm_manager>
ffffffffc0202782:	739c                	ld	a5,32(a5)
ffffffffc0202784:	4585                	li	a1,1
ffffffffc0202786:	854a                	mv	a0,s2
ffffffffc0202788:	9782                	jalr	a5
        intr_enable();
ffffffffc020278a:	a06fe0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc020278e:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202792:	120a0073          	sfence.vma	s4
ffffffffc0202796:	b7b9                	j	ffffffffc02026e4 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202798:	5571                	li	a0,-4
ffffffffc020279a:	b79d                	j	ffffffffc0202700 <page_insert+0x56>
ffffffffc020279c:	d70ff0ef          	jal	ra,ffffffffc0201d0c <pa2page.part.0>

ffffffffc02027a0 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027a0:	00004797          	auipc	a5,0x4
ffffffffc02027a4:	d1878793          	addi	a5,a5,-744 # ffffffffc02064b8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027a8:	638c                	ld	a1,0(a5)
{
ffffffffc02027aa:	7159                	addi	sp,sp,-112
ffffffffc02027ac:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027ae:	00004517          	auipc	a0,0x4
ffffffffc02027b2:	ed250513          	addi	a0,a0,-302 # ffffffffc0206680 <default_pmm_manager+0x1c8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027b6:	000c3b17          	auipc	s6,0xc3
ffffffffc02027ba:	592b0b13          	addi	s6,s6,1426 # ffffffffc02c5d48 <pmm_manager>
{
ffffffffc02027be:	f486                	sd	ra,104(sp)
ffffffffc02027c0:	e8ca                	sd	s2,80(sp)
ffffffffc02027c2:	e4ce                	sd	s3,72(sp)
ffffffffc02027c4:	f0a2                	sd	s0,96(sp)
ffffffffc02027c6:	eca6                	sd	s1,88(sp)
ffffffffc02027c8:	e0d2                	sd	s4,64(sp)
ffffffffc02027ca:	fc56                	sd	s5,56(sp)
ffffffffc02027cc:	f45e                	sd	s7,40(sp)
ffffffffc02027ce:	f062                	sd	s8,32(sp)
ffffffffc02027d0:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027d2:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027d6:	9c3fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    pmm_manager->init();
ffffffffc02027da:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027de:	000c3997          	auipc	s3,0xc3
ffffffffc02027e2:	57298993          	addi	s3,s3,1394 # ffffffffc02c5d50 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027e6:	679c                	ld	a5,8(a5)
ffffffffc02027e8:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027ea:	57f5                	li	a5,-3
ffffffffc02027ec:	07fa                	slli	a5,a5,0x1e
ffffffffc02027ee:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027f2:	98afe0ef          	jal	ra,ffffffffc020097c <get_memory_base>
ffffffffc02027f6:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027f8:	98efe0ef          	jal	ra,ffffffffc0200986 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027fc:	200505e3          	beqz	a0,ffffffffc0203206 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202800:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202802:	00004517          	auipc	a0,0x4
ffffffffc0202806:	eb650513          	addi	a0,a0,-330 # ffffffffc02066b8 <default_pmm_manager+0x200>
ffffffffc020280a:	98ffd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc020280e:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202812:	fff40693          	addi	a3,s0,-1
ffffffffc0202816:	864a                	mv	a2,s2
ffffffffc0202818:	85a6                	mv	a1,s1
ffffffffc020281a:	00004517          	auipc	a0,0x4
ffffffffc020281e:	eb650513          	addi	a0,a0,-330 # ffffffffc02066d0 <default_pmm_manager+0x218>
ffffffffc0202822:	977fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202826:	c8000737          	lui	a4,0xc8000
ffffffffc020282a:	87a2                	mv	a5,s0
ffffffffc020282c:	54876163          	bltu	a4,s0,ffffffffc0202d6e <pmm_init+0x5ce>
ffffffffc0202830:	757d                	lui	a0,0xfffff
ffffffffc0202832:	000c4617          	auipc	a2,0xc4
ffffffffc0202836:	55560613          	addi	a2,a2,1365 # ffffffffc02c6d87 <end+0xfff>
ffffffffc020283a:	8e69                	and	a2,a2,a0
ffffffffc020283c:	000c3497          	auipc	s1,0xc3
ffffffffc0202840:	4fc48493          	addi	s1,s1,1276 # ffffffffc02c5d38 <npage>
ffffffffc0202844:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202848:	000c3b97          	auipc	s7,0xc3
ffffffffc020284c:	4f8b8b93          	addi	s7,s7,1272 # ffffffffc02c5d40 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202850:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202852:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202856:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020285a:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020285c:	02f50863          	beq	a0,a5,ffffffffc020288c <pmm_init+0xec>
ffffffffc0202860:	4781                	li	a5,0
ffffffffc0202862:	4585                	li	a1,1
ffffffffc0202864:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202868:	00679513          	slli	a0,a5,0x6
ffffffffc020286c:	9532                	add	a0,a0,a2
ffffffffc020286e:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd39280>
ffffffffc0202872:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202876:	6088                	ld	a0,0(s1)
ffffffffc0202878:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020287a:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020287e:	00d50733          	add	a4,a0,a3
ffffffffc0202882:	fee7e3e3          	bltu	a5,a4,ffffffffc0202868 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202886:	071a                	slli	a4,a4,0x6
ffffffffc0202888:	00e606b3          	add	a3,a2,a4
ffffffffc020288c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202890:	2ef6ece3          	bltu	a3,a5,ffffffffc0203388 <pmm_init+0xbe8>
ffffffffc0202894:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202898:	77fd                	lui	a5,0xfffff
ffffffffc020289a:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020289c:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc020289e:	5086eb63          	bltu	a3,s0,ffffffffc0202db4 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028a2:	00004517          	auipc	a0,0x4
ffffffffc02028a6:	e5650513          	addi	a0,a0,-426 # ffffffffc02066f8 <default_pmm_manager+0x240>
ffffffffc02028aa:	8effd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028ae:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028b2:	000c3917          	auipc	s2,0xc3
ffffffffc02028b6:	47e90913          	addi	s2,s2,1150 # ffffffffc02c5d30 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02028ba:	7b9c                	ld	a5,48(a5)
ffffffffc02028bc:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028be:	00004517          	auipc	a0,0x4
ffffffffc02028c2:	e5250513          	addi	a0,a0,-430 # ffffffffc0206710 <default_pmm_manager+0x258>
ffffffffc02028c6:	8d3fd0ef          	jal	ra,ffffffffc0200198 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028ca:	00007697          	auipc	a3,0x7
ffffffffc02028ce:	73668693          	addi	a3,a3,1846 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02028d2:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02028da:	28f6ebe3          	bltu	a3,a5,ffffffffc0203370 <pmm_init+0xbd0>
ffffffffc02028de:	0009b783          	ld	a5,0(s3)
ffffffffc02028e2:	8e9d                	sub	a3,a3,a5
ffffffffc02028e4:	000c3797          	auipc	a5,0xc3
ffffffffc02028e8:	44d7b223          	sd	a3,1092(a5) # ffffffffc02c5d28 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028ec:	100027f3          	csrr	a5,sstatus
ffffffffc02028f0:	8b89                	andi	a5,a5,2
ffffffffc02028f2:	4a079763          	bnez	a5,ffffffffc0202da0 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028f6:	000b3783          	ld	a5,0(s6)
ffffffffc02028fa:	779c                	ld	a5,40(a5)
ffffffffc02028fc:	9782                	jalr	a5
ffffffffc02028fe:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202900:	6098                	ld	a4,0(s1)
ffffffffc0202902:	c80007b7          	lui	a5,0xc8000
ffffffffc0202906:	83b1                	srli	a5,a5,0xc
ffffffffc0202908:	66e7e363          	bltu	a5,a4,ffffffffc0202f6e <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020290c:	00093503          	ld	a0,0(s2)
ffffffffc0202910:	62050f63          	beqz	a0,ffffffffc0202f4e <pmm_init+0x7ae>
ffffffffc0202914:	03451793          	slli	a5,a0,0x34
ffffffffc0202918:	62079b63          	bnez	a5,ffffffffc0202f4e <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020291c:	4601                	li	a2,0
ffffffffc020291e:	4581                	li	a1,0
ffffffffc0202920:	f04ff0ef          	jal	ra,ffffffffc0202024 <get_page>
ffffffffc0202924:	60051563          	bnez	a0,ffffffffc0202f2e <pmm_init+0x78e>
ffffffffc0202928:	100027f3          	csrr	a5,sstatus
ffffffffc020292c:	8b89                	andi	a5,a5,2
ffffffffc020292e:	44079e63          	bnez	a5,ffffffffc0202d8a <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202932:	000b3783          	ld	a5,0(s6)
ffffffffc0202936:	4505                	li	a0,1
ffffffffc0202938:	6f9c                	ld	a5,24(a5)
ffffffffc020293a:	9782                	jalr	a5
ffffffffc020293c:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020293e:	00093503          	ld	a0,0(s2)
ffffffffc0202942:	4681                	li	a3,0
ffffffffc0202944:	4601                	li	a2,0
ffffffffc0202946:	85d2                	mv	a1,s4
ffffffffc0202948:	d63ff0ef          	jal	ra,ffffffffc02026aa <page_insert>
ffffffffc020294c:	26051ae3          	bnez	a0,ffffffffc02033c0 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202950:	00093503          	ld	a0,0(s2)
ffffffffc0202954:	4601                	li	a2,0
ffffffffc0202956:	4581                	li	a1,0
ffffffffc0202958:	ca4ff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
ffffffffc020295c:	240502e3          	beqz	a0,ffffffffc02033a0 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202960:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202962:	0017f713          	andi	a4,a5,1
ffffffffc0202966:	5a070263          	beqz	a4,ffffffffc0202f0a <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020296a:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020296c:	078a                	slli	a5,a5,0x2
ffffffffc020296e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202970:	58e7fb63          	bgeu	a5,a4,ffffffffc0202f06 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202974:	000bb683          	ld	a3,0(s7)
ffffffffc0202978:	fff80637          	lui	a2,0xfff80
ffffffffc020297c:	97b2                	add	a5,a5,a2
ffffffffc020297e:	079a                	slli	a5,a5,0x6
ffffffffc0202980:	97b6                	add	a5,a5,a3
ffffffffc0202982:	14fa17e3          	bne	s4,a5,ffffffffc02032d0 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202986:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f50>
ffffffffc020298a:	4785                	li	a5,1
ffffffffc020298c:	12f692e3          	bne	a3,a5,ffffffffc02032b0 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202990:	00093503          	ld	a0,0(s2)
ffffffffc0202994:	77fd                	lui	a5,0xfffff
ffffffffc0202996:	6114                	ld	a3,0(a0)
ffffffffc0202998:	068a                	slli	a3,a3,0x2
ffffffffc020299a:	8efd                	and	a3,a3,a5
ffffffffc020299c:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029a0:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203298 <pmm_init+0xaf8>
ffffffffc02029a4:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029a8:	96e2                	add	a3,a3,s8
ffffffffc02029aa:	0006ba83          	ld	s5,0(a3)
ffffffffc02029ae:	0a8a                	slli	s5,s5,0x2
ffffffffc02029b0:	00fafab3          	and	s5,s5,a5
ffffffffc02029b4:	00cad793          	srli	a5,s5,0xc
ffffffffc02029b8:	0ce7f3e3          	bgeu	a5,a4,ffffffffc020327e <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029bc:	4601                	li	a2,0
ffffffffc02029be:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029c0:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029c2:	c3aff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029c6:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029c8:	55551363          	bne	a0,s5,ffffffffc0202f0e <pmm_init+0x76e>
ffffffffc02029cc:	100027f3          	csrr	a5,sstatus
ffffffffc02029d0:	8b89                	andi	a5,a5,2
ffffffffc02029d2:	3a079163          	bnez	a5,ffffffffc0202d74 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029d6:	000b3783          	ld	a5,0(s6)
ffffffffc02029da:	4505                	li	a0,1
ffffffffc02029dc:	6f9c                	ld	a5,24(a5)
ffffffffc02029de:	9782                	jalr	a5
ffffffffc02029e0:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029e2:	00093503          	ld	a0,0(s2)
ffffffffc02029e6:	46d1                	li	a3,20
ffffffffc02029e8:	6605                	lui	a2,0x1
ffffffffc02029ea:	85e2                	mv	a1,s8
ffffffffc02029ec:	cbfff0ef          	jal	ra,ffffffffc02026aa <page_insert>
ffffffffc02029f0:	060517e3          	bnez	a0,ffffffffc020325e <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029f4:	00093503          	ld	a0,0(s2)
ffffffffc02029f8:	4601                	li	a2,0
ffffffffc02029fa:	6585                	lui	a1,0x1
ffffffffc02029fc:	c00ff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
ffffffffc0202a00:	02050fe3          	beqz	a0,ffffffffc020323e <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc0202a04:	611c                	ld	a5,0(a0)
ffffffffc0202a06:	0107f713          	andi	a4,a5,16
ffffffffc0202a0a:	7c070e63          	beqz	a4,ffffffffc02031e6 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202a0e:	8b91                	andi	a5,a5,4
ffffffffc0202a10:	7a078b63          	beqz	a5,ffffffffc02031c6 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a14:	00093503          	ld	a0,0(s2)
ffffffffc0202a18:	611c                	ld	a5,0(a0)
ffffffffc0202a1a:	8bc1                	andi	a5,a5,16
ffffffffc0202a1c:	78078563          	beqz	a5,ffffffffc02031a6 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc0202a20:	000c2703          	lw	a4,0(s8)
ffffffffc0202a24:	4785                	li	a5,1
ffffffffc0202a26:	76f71063          	bne	a4,a5,ffffffffc0203186 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a2a:	4681                	li	a3,0
ffffffffc0202a2c:	6605                	lui	a2,0x1
ffffffffc0202a2e:	85d2                	mv	a1,s4
ffffffffc0202a30:	c7bff0ef          	jal	ra,ffffffffc02026aa <page_insert>
ffffffffc0202a34:	72051963          	bnez	a0,ffffffffc0203166 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a38:	000a2703          	lw	a4,0(s4)
ffffffffc0202a3c:	4789                	li	a5,2
ffffffffc0202a3e:	70f71463          	bne	a4,a5,ffffffffc0203146 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a42:	000c2783          	lw	a5,0(s8)
ffffffffc0202a46:	6e079063          	bnez	a5,ffffffffc0203126 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a4a:	00093503          	ld	a0,0(s2)
ffffffffc0202a4e:	4601                	li	a2,0
ffffffffc0202a50:	6585                	lui	a1,0x1
ffffffffc0202a52:	baaff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
ffffffffc0202a56:	6a050863          	beqz	a0,ffffffffc0203106 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a5a:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a5c:	00177793          	andi	a5,a4,1
ffffffffc0202a60:	4a078563          	beqz	a5,ffffffffc0202f0a <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a64:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a66:	00271793          	slli	a5,a4,0x2
ffffffffc0202a6a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a6c:	48d7fd63          	bgeu	a5,a3,ffffffffc0202f06 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a70:	000bb683          	ld	a3,0(s7)
ffffffffc0202a74:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a78:	97d6                	add	a5,a5,s5
ffffffffc0202a7a:	079a                	slli	a5,a5,0x6
ffffffffc0202a7c:	97b6                	add	a5,a5,a3
ffffffffc0202a7e:	66fa1463          	bne	s4,a5,ffffffffc02030e6 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a82:	8b41                	andi	a4,a4,16
ffffffffc0202a84:	64071163          	bnez	a4,ffffffffc02030c6 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a88:	00093503          	ld	a0,0(s2)
ffffffffc0202a8c:	4581                	li	a1,0
ffffffffc0202a8e:	b81ff0ef          	jal	ra,ffffffffc020260e <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a92:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a96:	4785                	li	a5,1
ffffffffc0202a98:	60fc9763          	bne	s9,a5,ffffffffc02030a6 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a9c:	000c2783          	lw	a5,0(s8)
ffffffffc0202aa0:	5e079363          	bnez	a5,ffffffffc0203086 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202aa4:	00093503          	ld	a0,0(s2)
ffffffffc0202aa8:	6585                	lui	a1,0x1
ffffffffc0202aaa:	b65ff0ef          	jal	ra,ffffffffc020260e <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202aae:	000a2783          	lw	a5,0(s4)
ffffffffc0202ab2:	52079a63          	bnez	a5,ffffffffc0202fe6 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202ab6:	000c2783          	lw	a5,0(s8)
ffffffffc0202aba:	50079663          	bnez	a5,ffffffffc0202fc6 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202abe:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202ac2:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ac4:	000a3683          	ld	a3,0(s4)
ffffffffc0202ac8:	068a                	slli	a3,a3,0x2
ffffffffc0202aca:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202acc:	42b6fd63          	bgeu	a3,a1,ffffffffc0202f06 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ad0:	000bb503          	ld	a0,0(s7)
ffffffffc0202ad4:	96d6                	add	a3,a3,s5
ffffffffc0202ad6:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202ad8:	00d507b3          	add	a5,a0,a3
ffffffffc0202adc:	439c                	lw	a5,0(a5)
ffffffffc0202ade:	4d979463          	bne	a5,s9,ffffffffc0202fa6 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202ae2:	8699                	srai	a3,a3,0x6
ffffffffc0202ae4:	00080637          	lui	a2,0x80
ffffffffc0202ae8:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202aea:	00c69713          	slli	a4,a3,0xc
ffffffffc0202aee:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202af0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202af2:	48b77e63          	bgeu	a4,a1,ffffffffc0202f8e <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202af6:	0009b703          	ld	a4,0(s3)
ffffffffc0202afa:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202afc:	629c                	ld	a5,0(a3)
ffffffffc0202afe:	078a                	slli	a5,a5,0x2
ffffffffc0202b00:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b02:	40b7f263          	bgeu	a5,a1,ffffffffc0202f06 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b06:	8f91                	sub	a5,a5,a2
ffffffffc0202b08:	079a                	slli	a5,a5,0x6
ffffffffc0202b0a:	953e                	add	a0,a0,a5
ffffffffc0202b0c:	100027f3          	csrr	a5,sstatus
ffffffffc0202b10:	8b89                	andi	a5,a5,2
ffffffffc0202b12:	30079963          	bnez	a5,ffffffffc0202e24 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202b16:	000b3783          	ld	a5,0(s6)
ffffffffc0202b1a:	4585                	li	a1,1
ffffffffc0202b1c:	739c                	ld	a5,32(a5)
ffffffffc0202b1e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b20:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b24:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b26:	078a                	slli	a5,a5,0x2
ffffffffc0202b28:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b2a:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202f06 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b2e:	000bb503          	ld	a0,0(s7)
ffffffffc0202b32:	fff80737          	lui	a4,0xfff80
ffffffffc0202b36:	97ba                	add	a5,a5,a4
ffffffffc0202b38:	079a                	slli	a5,a5,0x6
ffffffffc0202b3a:	953e                	add	a0,a0,a5
ffffffffc0202b3c:	100027f3          	csrr	a5,sstatus
ffffffffc0202b40:	8b89                	andi	a5,a5,2
ffffffffc0202b42:	2c079563          	bnez	a5,ffffffffc0202e0c <pmm_init+0x66c>
ffffffffc0202b46:	000b3783          	ld	a5,0(s6)
ffffffffc0202b4a:	4585                	li	a1,1
ffffffffc0202b4c:	739c                	ld	a5,32(a5)
ffffffffc0202b4e:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b50:	00093783          	ld	a5,0(s2)
ffffffffc0202b54:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd39278>
    asm volatile("sfence.vma");
ffffffffc0202b58:	12000073          	sfence.vma
ffffffffc0202b5c:	100027f3          	csrr	a5,sstatus
ffffffffc0202b60:	8b89                	andi	a5,a5,2
ffffffffc0202b62:	28079b63          	bnez	a5,ffffffffc0202df8 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b66:	000b3783          	ld	a5,0(s6)
ffffffffc0202b6a:	779c                	ld	a5,40(a5)
ffffffffc0202b6c:	9782                	jalr	a5
ffffffffc0202b6e:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b70:	4b441b63          	bne	s0,s4,ffffffffc0203026 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b74:	00004517          	auipc	a0,0x4
ffffffffc0202b78:	ec450513          	addi	a0,a0,-316 # ffffffffc0206a38 <default_pmm_manager+0x580>
ffffffffc0202b7c:	e1cfd0ef          	jal	ra,ffffffffc0200198 <cprintf>
ffffffffc0202b80:	100027f3          	csrr	a5,sstatus
ffffffffc0202b84:	8b89                	andi	a5,a5,2
ffffffffc0202b86:	24079f63          	bnez	a5,ffffffffc0202de4 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b8a:	000b3783          	ld	a5,0(s6)
ffffffffc0202b8e:	779c                	ld	a5,40(a5)
ffffffffc0202b90:	9782                	jalr	a5
ffffffffc0202b92:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b94:	6098                	ld	a4,0(s1)
ffffffffc0202b96:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b9a:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b9c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202ba0:	6a05                	lui	s4,0x1
ffffffffc0202ba2:	02f47c63          	bgeu	s0,a5,ffffffffc0202bda <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ba6:	00c45793          	srli	a5,s0,0xc
ffffffffc0202baa:	00093503          	ld	a0,0(s2)
ffffffffc0202bae:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202eac <pmm_init+0x70c>
ffffffffc0202bb2:	0009b583          	ld	a1,0(s3)
ffffffffc0202bb6:	4601                	li	a2,0
ffffffffc0202bb8:	95a2                	add	a1,a1,s0
ffffffffc0202bba:	a42ff0ef          	jal	ra,ffffffffc0201dfc <get_pte>
ffffffffc0202bbe:	32050463          	beqz	a0,ffffffffc0202ee6 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bc2:	611c                	ld	a5,0(a0)
ffffffffc0202bc4:	078a                	slli	a5,a5,0x2
ffffffffc0202bc6:	0157f7b3          	and	a5,a5,s5
ffffffffc0202bca:	2e879e63          	bne	a5,s0,ffffffffc0202ec6 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bce:	6098                	ld	a4,0(s1)
ffffffffc0202bd0:	9452                	add	s0,s0,s4
ffffffffc0202bd2:	00c71793          	slli	a5,a4,0xc
ffffffffc0202bd6:	fcf468e3          	bltu	s0,a5,ffffffffc0202ba6 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202bda:	00093783          	ld	a5,0(s2)
ffffffffc0202bde:	639c                	ld	a5,0(a5)
ffffffffc0202be0:	42079363          	bnez	a5,ffffffffc0203006 <pmm_init+0x866>
ffffffffc0202be4:	100027f3          	csrr	a5,sstatus
ffffffffc0202be8:	8b89                	andi	a5,a5,2
ffffffffc0202bea:	24079963          	bnez	a5,ffffffffc0202e3c <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bee:	000b3783          	ld	a5,0(s6)
ffffffffc0202bf2:	4505                	li	a0,1
ffffffffc0202bf4:	6f9c                	ld	a5,24(a5)
ffffffffc0202bf6:	9782                	jalr	a5
ffffffffc0202bf8:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bfa:	00093503          	ld	a0,0(s2)
ffffffffc0202bfe:	4699                	li	a3,6
ffffffffc0202c00:	10000613          	li	a2,256
ffffffffc0202c04:	85d2                	mv	a1,s4
ffffffffc0202c06:	aa5ff0ef          	jal	ra,ffffffffc02026aa <page_insert>
ffffffffc0202c0a:	44051e63          	bnez	a0,ffffffffc0203066 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202c0e:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f50>
ffffffffc0202c12:	4785                	li	a5,1
ffffffffc0202c14:	42f71963          	bne	a4,a5,ffffffffc0203046 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c18:	00093503          	ld	a0,0(s2)
ffffffffc0202c1c:	6405                	lui	s0,0x1
ffffffffc0202c1e:	4699                	li	a3,6
ffffffffc0202c20:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8e50>
ffffffffc0202c24:	85d2                	mv	a1,s4
ffffffffc0202c26:	a85ff0ef          	jal	ra,ffffffffc02026aa <page_insert>
ffffffffc0202c2a:	72051363          	bnez	a0,ffffffffc0203350 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202c2e:	000a2703          	lw	a4,0(s4)
ffffffffc0202c32:	4789                	li	a5,2
ffffffffc0202c34:	6ef71e63          	bne	a4,a5,ffffffffc0203330 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c38:	00004597          	auipc	a1,0x4
ffffffffc0202c3c:	f4858593          	addi	a1,a1,-184 # ffffffffc0206b80 <default_pmm_manager+0x6c8>
ffffffffc0202c40:	10000513          	li	a0,256
ffffffffc0202c44:	1a9020ef          	jal	ra,ffffffffc02055ec <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c48:	10040593          	addi	a1,s0,256
ffffffffc0202c4c:	10000513          	li	a0,256
ffffffffc0202c50:	1af020ef          	jal	ra,ffffffffc02055fe <strcmp>
ffffffffc0202c54:	6a051e63          	bnez	a0,ffffffffc0203310 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c58:	000bb683          	ld	a3,0(s7)
ffffffffc0202c5c:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c60:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202c62:	40da06b3          	sub	a3,s4,a3
ffffffffc0202c66:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202c68:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202c6a:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202c6c:	8031                	srli	s0,s0,0xc
ffffffffc0202c6e:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c72:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c74:	30f77d63          	bgeu	a4,a5,ffffffffc0202f8e <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c78:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c7c:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c80:	96be                	add	a3,a3,a5
ffffffffc0202c82:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c86:	131020ef          	jal	ra,ffffffffc02055b6 <strlen>
ffffffffc0202c8a:	66051363          	bnez	a0,ffffffffc02032f0 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c8e:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c92:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c94:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd39278>
ffffffffc0202c98:	068a                	slli	a3,a3,0x2
ffffffffc0202c9a:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c9c:	26f6f563          	bgeu	a3,a5,ffffffffc0202f06 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202ca0:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ca2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ca4:	2ef47563          	bgeu	s0,a5,ffffffffc0202f8e <pmm_init+0x7ee>
ffffffffc0202ca8:	0009b403          	ld	s0,0(s3)
ffffffffc0202cac:	9436                	add	s0,s0,a3
ffffffffc0202cae:	100027f3          	csrr	a5,sstatus
ffffffffc0202cb2:	8b89                	andi	a5,a5,2
ffffffffc0202cb4:	1e079163          	bnez	a5,ffffffffc0202e96 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202cb8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cbc:	4585                	li	a1,1
ffffffffc0202cbe:	8552                	mv	a0,s4
ffffffffc0202cc0:	739c                	ld	a5,32(a5)
ffffffffc0202cc2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cc4:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202cc6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cc8:	078a                	slli	a5,a5,0x2
ffffffffc0202cca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ccc:	22e7fd63          	bgeu	a5,a4,ffffffffc0202f06 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cd0:	000bb503          	ld	a0,0(s7)
ffffffffc0202cd4:	fff80737          	lui	a4,0xfff80
ffffffffc0202cd8:	97ba                	add	a5,a5,a4
ffffffffc0202cda:	079a                	slli	a5,a5,0x6
ffffffffc0202cdc:	953e                	add	a0,a0,a5
ffffffffc0202cde:	100027f3          	csrr	a5,sstatus
ffffffffc0202ce2:	8b89                	andi	a5,a5,2
ffffffffc0202ce4:	18079d63          	bnez	a5,ffffffffc0202e7e <pmm_init+0x6de>
ffffffffc0202ce8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cec:	4585                	li	a1,1
ffffffffc0202cee:	739c                	ld	a5,32(a5)
ffffffffc0202cf0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cf2:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202cf6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cf8:	078a                	slli	a5,a5,0x2
ffffffffc0202cfa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cfc:	20e7f563          	bgeu	a5,a4,ffffffffc0202f06 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d00:	000bb503          	ld	a0,0(s7)
ffffffffc0202d04:	fff80737          	lui	a4,0xfff80
ffffffffc0202d08:	97ba                	add	a5,a5,a4
ffffffffc0202d0a:	079a                	slli	a5,a5,0x6
ffffffffc0202d0c:	953e                	add	a0,a0,a5
ffffffffc0202d0e:	100027f3          	csrr	a5,sstatus
ffffffffc0202d12:	8b89                	andi	a5,a5,2
ffffffffc0202d14:	14079963          	bnez	a5,ffffffffc0202e66 <pmm_init+0x6c6>
ffffffffc0202d18:	000b3783          	ld	a5,0(s6)
ffffffffc0202d1c:	4585                	li	a1,1
ffffffffc0202d1e:	739c                	ld	a5,32(a5)
ffffffffc0202d20:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d22:	00093783          	ld	a5,0(s2)
ffffffffc0202d26:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d2a:	12000073          	sfence.vma
ffffffffc0202d2e:	100027f3          	csrr	a5,sstatus
ffffffffc0202d32:	8b89                	andi	a5,a5,2
ffffffffc0202d34:	10079f63          	bnez	a5,ffffffffc0202e52 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d38:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3c:	779c                	ld	a5,40(a5)
ffffffffc0202d3e:	9782                	jalr	a5
ffffffffc0202d40:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d42:	4c8c1e63          	bne	s8,s0,ffffffffc020321e <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d46:	00004517          	auipc	a0,0x4
ffffffffc0202d4a:	eb250513          	addi	a0,a0,-334 # ffffffffc0206bf8 <default_pmm_manager+0x740>
ffffffffc0202d4e:	c4afd0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc0202d52:	7406                	ld	s0,96(sp)
ffffffffc0202d54:	70a6                	ld	ra,104(sp)
ffffffffc0202d56:	64e6                	ld	s1,88(sp)
ffffffffc0202d58:	6946                	ld	s2,80(sp)
ffffffffc0202d5a:	69a6                	ld	s3,72(sp)
ffffffffc0202d5c:	6a06                	ld	s4,64(sp)
ffffffffc0202d5e:	7ae2                	ld	s5,56(sp)
ffffffffc0202d60:	7b42                	ld	s6,48(sp)
ffffffffc0202d62:	7ba2                	ld	s7,40(sp)
ffffffffc0202d64:	7c02                	ld	s8,32(sp)
ffffffffc0202d66:	6ce2                	ld	s9,24(sp)
ffffffffc0202d68:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d6a:	dd9fe06f          	j	ffffffffc0201b42 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202d6e:	c80007b7          	lui	a5,0xc8000
ffffffffc0202d72:	bc7d                	j	ffffffffc0202830 <pmm_init+0x90>
        intr_disable();
ffffffffc0202d74:	c23fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d78:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7c:	4505                	li	a0,1
ffffffffc0202d7e:	6f9c                	ld	a5,24(a5)
ffffffffc0202d80:	9782                	jalr	a5
ffffffffc0202d82:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d84:	c0dfd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202d88:	b9a9                	j	ffffffffc02029e2 <pmm_init+0x242>
        intr_disable();
ffffffffc0202d8a:	c0dfd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0202d8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d92:	4505                	li	a0,1
ffffffffc0202d94:	6f9c                	ld	a5,24(a5)
ffffffffc0202d96:	9782                	jalr	a5
ffffffffc0202d98:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d9a:	bf7fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202d9e:	b645                	j	ffffffffc020293e <pmm_init+0x19e>
        intr_disable();
ffffffffc0202da0:	bf7fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202da4:	000b3783          	ld	a5,0(s6)
ffffffffc0202da8:	779c                	ld	a5,40(a5)
ffffffffc0202daa:	9782                	jalr	a5
ffffffffc0202dac:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dae:	be3fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202db2:	b6b9                	j	ffffffffc0202900 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202db4:	6705                	lui	a4,0x1
ffffffffc0202db6:	177d                	addi	a4,a4,-1
ffffffffc0202db8:	96ba                	add	a3,a3,a4
ffffffffc0202dba:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202dbc:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202dc0:	14a77363          	bgeu	a4,a0,ffffffffc0202f06 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202dc4:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202dc8:	fff80537          	lui	a0,0xfff80
ffffffffc0202dcc:	972a                	add	a4,a4,a0
ffffffffc0202dce:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202dd0:	8c1d                	sub	s0,s0,a5
ffffffffc0202dd2:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202dd6:	00c45593          	srli	a1,s0,0xc
ffffffffc0202dda:	9532                	add	a0,a0,a2
ffffffffc0202ddc:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202dde:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202de2:	b4c1                	j	ffffffffc02028a2 <pmm_init+0x102>
        intr_disable();
ffffffffc0202de4:	bb3fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202de8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dec:	779c                	ld	a5,40(a5)
ffffffffc0202dee:	9782                	jalr	a5
ffffffffc0202df0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202df2:	b9ffd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202df6:	bb79                	j	ffffffffc0202b94 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202df8:	b9ffd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0202dfc:	000b3783          	ld	a5,0(s6)
ffffffffc0202e00:	779c                	ld	a5,40(a5)
ffffffffc0202e02:	9782                	jalr	a5
ffffffffc0202e04:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e06:	b8bfd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202e0a:	b39d                	j	ffffffffc0202b70 <pmm_init+0x3d0>
ffffffffc0202e0c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e0e:	b89fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e12:	000b3783          	ld	a5,0(s6)
ffffffffc0202e16:	6522                	ld	a0,8(sp)
ffffffffc0202e18:	4585                	li	a1,1
ffffffffc0202e1a:	739c                	ld	a5,32(a5)
ffffffffc0202e1c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e1e:	b73fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202e22:	b33d                	j	ffffffffc0202b50 <pmm_init+0x3b0>
ffffffffc0202e24:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e26:	b71fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0202e2a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2e:	6522                	ld	a0,8(sp)
ffffffffc0202e30:	4585                	li	a1,1
ffffffffc0202e32:	739c                	ld	a5,32(a5)
ffffffffc0202e34:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e36:	b5bfd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202e3a:	b1dd                	j	ffffffffc0202b20 <pmm_init+0x380>
        intr_disable();
ffffffffc0202e3c:	b5bfd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e40:	000b3783          	ld	a5,0(s6)
ffffffffc0202e44:	4505                	li	a0,1
ffffffffc0202e46:	6f9c                	ld	a5,24(a5)
ffffffffc0202e48:	9782                	jalr	a5
ffffffffc0202e4a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e4c:	b45fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202e50:	b36d                	j	ffffffffc0202bfa <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e52:	b45fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e56:	000b3783          	ld	a5,0(s6)
ffffffffc0202e5a:	779c                	ld	a5,40(a5)
ffffffffc0202e5c:	9782                	jalr	a5
ffffffffc0202e5e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e60:	b31fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202e64:	bdf9                	j	ffffffffc0202d42 <pmm_init+0x5a2>
ffffffffc0202e66:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e68:	b2ffd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e6c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e70:	6522                	ld	a0,8(sp)
ffffffffc0202e72:	4585                	li	a1,1
ffffffffc0202e74:	739c                	ld	a5,32(a5)
ffffffffc0202e76:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e78:	b19fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202e7c:	b55d                	j	ffffffffc0202d22 <pmm_init+0x582>
ffffffffc0202e7e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e80:	b17fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0202e84:	000b3783          	ld	a5,0(s6)
ffffffffc0202e88:	6522                	ld	a0,8(sp)
ffffffffc0202e8a:	4585                	li	a1,1
ffffffffc0202e8c:	739c                	ld	a5,32(a5)
ffffffffc0202e8e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e90:	b01fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202e94:	bdb9                	j	ffffffffc0202cf2 <pmm_init+0x552>
        intr_disable();
ffffffffc0202e96:	b01fd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc0202e9a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e9e:	4585                	li	a1,1
ffffffffc0202ea0:	8552                	mv	a0,s4
ffffffffc0202ea2:	739c                	ld	a5,32(a5)
ffffffffc0202ea4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ea6:	aebfd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0202eaa:	bd29                	j	ffffffffc0202cc4 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202eac:	86a2                	mv	a3,s0
ffffffffc0202eae:	00003617          	auipc	a2,0x3
ffffffffc0202eb2:	64260613          	addi	a2,a2,1602 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0202eb6:	24d00593          	li	a1,589
ffffffffc0202eba:	00003517          	auipc	a0,0x3
ffffffffc0202ebe:	74e50513          	addi	a0,a0,1870 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202ec2:	dd0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ec6:	00004697          	auipc	a3,0x4
ffffffffc0202eca:	bd268693          	addi	a3,a3,-1070 # ffffffffc0206a98 <default_pmm_manager+0x5e0>
ffffffffc0202ece:	00003617          	auipc	a2,0x3
ffffffffc0202ed2:	23a60613          	addi	a2,a2,570 # ffffffffc0206108 <commands+0x818>
ffffffffc0202ed6:	24e00593          	li	a1,590
ffffffffc0202eda:	00003517          	auipc	a0,0x3
ffffffffc0202ede:	72e50513          	addi	a0,a0,1838 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202ee2:	db0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ee6:	00004697          	auipc	a3,0x4
ffffffffc0202eea:	b7268693          	addi	a3,a3,-1166 # ffffffffc0206a58 <default_pmm_manager+0x5a0>
ffffffffc0202eee:	00003617          	auipc	a2,0x3
ffffffffc0202ef2:	21a60613          	addi	a2,a2,538 # ffffffffc0206108 <commands+0x818>
ffffffffc0202ef6:	24d00593          	li	a1,589
ffffffffc0202efa:	00003517          	auipc	a0,0x3
ffffffffc0202efe:	70e50513          	addi	a0,a0,1806 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202f02:	d90fd0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0202f06:	e07fe0ef          	jal	ra,ffffffffc0201d0c <pa2page.part.0>
ffffffffc0202f0a:	e1ffe0ef          	jal	ra,ffffffffc0201d28 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202f0e:	00004697          	auipc	a3,0x4
ffffffffc0202f12:	94268693          	addi	a3,a3,-1726 # ffffffffc0206850 <default_pmm_manager+0x398>
ffffffffc0202f16:	00003617          	auipc	a2,0x3
ffffffffc0202f1a:	1f260613          	addi	a2,a2,498 # ffffffffc0206108 <commands+0x818>
ffffffffc0202f1e:	21d00593          	li	a1,541
ffffffffc0202f22:	00003517          	auipc	a0,0x3
ffffffffc0202f26:	6e650513          	addi	a0,a0,1766 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202f2a:	d68fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202f2e:	00004697          	auipc	a3,0x4
ffffffffc0202f32:	86268693          	addi	a3,a3,-1950 # ffffffffc0206790 <default_pmm_manager+0x2d8>
ffffffffc0202f36:	00003617          	auipc	a2,0x3
ffffffffc0202f3a:	1d260613          	addi	a2,a2,466 # ffffffffc0206108 <commands+0x818>
ffffffffc0202f3e:	21000593          	li	a1,528
ffffffffc0202f42:	00003517          	auipc	a0,0x3
ffffffffc0202f46:	6c650513          	addi	a0,a0,1734 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202f4a:	d48fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f4e:	00004697          	auipc	a3,0x4
ffffffffc0202f52:	80268693          	addi	a3,a3,-2046 # ffffffffc0206750 <default_pmm_manager+0x298>
ffffffffc0202f56:	00003617          	auipc	a2,0x3
ffffffffc0202f5a:	1b260613          	addi	a2,a2,434 # ffffffffc0206108 <commands+0x818>
ffffffffc0202f5e:	20f00593          	li	a1,527
ffffffffc0202f62:	00003517          	auipc	a0,0x3
ffffffffc0202f66:	6a650513          	addi	a0,a0,1702 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202f6a:	d28fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f6e:	00003697          	auipc	a3,0x3
ffffffffc0202f72:	7c268693          	addi	a3,a3,1986 # ffffffffc0206730 <default_pmm_manager+0x278>
ffffffffc0202f76:	00003617          	auipc	a2,0x3
ffffffffc0202f7a:	19260613          	addi	a2,a2,402 # ffffffffc0206108 <commands+0x818>
ffffffffc0202f7e:	20e00593          	li	a1,526
ffffffffc0202f82:	00003517          	auipc	a0,0x3
ffffffffc0202f86:	68650513          	addi	a0,a0,1670 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202f8a:	d08fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f8e:	00003617          	auipc	a2,0x3
ffffffffc0202f92:	56260613          	addi	a2,a2,1378 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0202f96:	07100593          	li	a1,113
ffffffffc0202f9a:	00003517          	auipc	a0,0x3
ffffffffc0202f9e:	57e50513          	addi	a0,a0,1406 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0202fa2:	cf0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fa6:	00004697          	auipc	a3,0x4
ffffffffc0202faa:	a3a68693          	addi	a3,a3,-1478 # ffffffffc02069e0 <default_pmm_manager+0x528>
ffffffffc0202fae:	00003617          	auipc	a2,0x3
ffffffffc0202fb2:	15a60613          	addi	a2,a2,346 # ffffffffc0206108 <commands+0x818>
ffffffffc0202fb6:	23600593          	li	a1,566
ffffffffc0202fba:	00003517          	auipc	a0,0x3
ffffffffc0202fbe:	64e50513          	addi	a0,a0,1614 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202fc2:	cd0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fc6:	00004697          	auipc	a3,0x4
ffffffffc0202fca:	9d268693          	addi	a3,a3,-1582 # ffffffffc0206998 <default_pmm_manager+0x4e0>
ffffffffc0202fce:	00003617          	auipc	a2,0x3
ffffffffc0202fd2:	13a60613          	addi	a2,a2,314 # ffffffffc0206108 <commands+0x818>
ffffffffc0202fd6:	23400593          	li	a1,564
ffffffffc0202fda:	00003517          	auipc	a0,0x3
ffffffffc0202fde:	62e50513          	addi	a0,a0,1582 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0202fe2:	cb0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fe6:	00004697          	auipc	a3,0x4
ffffffffc0202fea:	9e268693          	addi	a3,a3,-1566 # ffffffffc02069c8 <default_pmm_manager+0x510>
ffffffffc0202fee:	00003617          	auipc	a2,0x3
ffffffffc0202ff2:	11a60613          	addi	a2,a2,282 # ffffffffc0206108 <commands+0x818>
ffffffffc0202ff6:	23300593          	li	a1,563
ffffffffc0202ffa:	00003517          	auipc	a0,0x3
ffffffffc0202ffe:	60e50513          	addi	a0,a0,1550 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203002:	c90fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203006:	00004697          	auipc	a3,0x4
ffffffffc020300a:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0206ab0 <default_pmm_manager+0x5f8>
ffffffffc020300e:	00003617          	auipc	a2,0x3
ffffffffc0203012:	0fa60613          	addi	a2,a2,250 # ffffffffc0206108 <commands+0x818>
ffffffffc0203016:	25100593          	li	a1,593
ffffffffc020301a:	00003517          	auipc	a0,0x3
ffffffffc020301e:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203022:	c70fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203026:	00004697          	auipc	a3,0x4
ffffffffc020302a:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0206a10 <default_pmm_manager+0x558>
ffffffffc020302e:	00003617          	auipc	a2,0x3
ffffffffc0203032:	0da60613          	addi	a2,a2,218 # ffffffffc0206108 <commands+0x818>
ffffffffc0203036:	23e00593          	li	a1,574
ffffffffc020303a:	00003517          	auipc	a0,0x3
ffffffffc020303e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203042:	c50fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203046:	00004697          	auipc	a3,0x4
ffffffffc020304a:	ac268693          	addi	a3,a3,-1342 # ffffffffc0206b08 <default_pmm_manager+0x650>
ffffffffc020304e:	00003617          	auipc	a2,0x3
ffffffffc0203052:	0ba60613          	addi	a2,a2,186 # ffffffffc0206108 <commands+0x818>
ffffffffc0203056:	25600593          	li	a1,598
ffffffffc020305a:	00003517          	auipc	a0,0x3
ffffffffc020305e:	5ae50513          	addi	a0,a0,1454 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203062:	c30fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203066:	00004697          	auipc	a3,0x4
ffffffffc020306a:	a6268693          	addi	a3,a3,-1438 # ffffffffc0206ac8 <default_pmm_manager+0x610>
ffffffffc020306e:	00003617          	auipc	a2,0x3
ffffffffc0203072:	09a60613          	addi	a2,a2,154 # ffffffffc0206108 <commands+0x818>
ffffffffc0203076:	25500593          	li	a1,597
ffffffffc020307a:	00003517          	auipc	a0,0x3
ffffffffc020307e:	58e50513          	addi	a0,a0,1422 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203082:	c10fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203086:	00004697          	auipc	a3,0x4
ffffffffc020308a:	91268693          	addi	a3,a3,-1774 # ffffffffc0206998 <default_pmm_manager+0x4e0>
ffffffffc020308e:	00003617          	auipc	a2,0x3
ffffffffc0203092:	07a60613          	addi	a2,a2,122 # ffffffffc0206108 <commands+0x818>
ffffffffc0203096:	23000593          	li	a1,560
ffffffffc020309a:	00003517          	auipc	a0,0x3
ffffffffc020309e:	56e50513          	addi	a0,a0,1390 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02030a2:	bf0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030a6:	00003697          	auipc	a3,0x3
ffffffffc02030aa:	79268693          	addi	a3,a3,1938 # ffffffffc0206838 <default_pmm_manager+0x380>
ffffffffc02030ae:	00003617          	auipc	a2,0x3
ffffffffc02030b2:	05a60613          	addi	a2,a2,90 # ffffffffc0206108 <commands+0x818>
ffffffffc02030b6:	22f00593          	li	a1,559
ffffffffc02030ba:	00003517          	auipc	a0,0x3
ffffffffc02030be:	54e50513          	addi	a0,a0,1358 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02030c2:	bd0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02030c6:	00004697          	auipc	a3,0x4
ffffffffc02030ca:	8ea68693          	addi	a3,a3,-1814 # ffffffffc02069b0 <default_pmm_manager+0x4f8>
ffffffffc02030ce:	00003617          	auipc	a2,0x3
ffffffffc02030d2:	03a60613          	addi	a2,a2,58 # ffffffffc0206108 <commands+0x818>
ffffffffc02030d6:	22c00593          	li	a1,556
ffffffffc02030da:	00003517          	auipc	a0,0x3
ffffffffc02030de:	52e50513          	addi	a0,a0,1326 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02030e2:	bb0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030e6:	00003697          	auipc	a3,0x3
ffffffffc02030ea:	73a68693          	addi	a3,a3,1850 # ffffffffc0206820 <default_pmm_manager+0x368>
ffffffffc02030ee:	00003617          	auipc	a2,0x3
ffffffffc02030f2:	01a60613          	addi	a2,a2,26 # ffffffffc0206108 <commands+0x818>
ffffffffc02030f6:	22b00593          	li	a1,555
ffffffffc02030fa:	00003517          	auipc	a0,0x3
ffffffffc02030fe:	50e50513          	addi	a0,a0,1294 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203102:	b90fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203106:	00003697          	auipc	a3,0x3
ffffffffc020310a:	7ba68693          	addi	a3,a3,1978 # ffffffffc02068c0 <default_pmm_manager+0x408>
ffffffffc020310e:	00003617          	auipc	a2,0x3
ffffffffc0203112:	ffa60613          	addi	a2,a2,-6 # ffffffffc0206108 <commands+0x818>
ffffffffc0203116:	22a00593          	li	a1,554
ffffffffc020311a:	00003517          	auipc	a0,0x3
ffffffffc020311e:	4ee50513          	addi	a0,a0,1262 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203122:	b70fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203126:	00004697          	auipc	a3,0x4
ffffffffc020312a:	87268693          	addi	a3,a3,-1934 # ffffffffc0206998 <default_pmm_manager+0x4e0>
ffffffffc020312e:	00003617          	auipc	a2,0x3
ffffffffc0203132:	fda60613          	addi	a2,a2,-38 # ffffffffc0206108 <commands+0x818>
ffffffffc0203136:	22900593          	li	a1,553
ffffffffc020313a:	00003517          	auipc	a0,0x3
ffffffffc020313e:	4ce50513          	addi	a0,a0,1230 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203142:	b50fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203146:	00004697          	auipc	a3,0x4
ffffffffc020314a:	83a68693          	addi	a3,a3,-1990 # ffffffffc0206980 <default_pmm_manager+0x4c8>
ffffffffc020314e:	00003617          	auipc	a2,0x3
ffffffffc0203152:	fba60613          	addi	a2,a2,-70 # ffffffffc0206108 <commands+0x818>
ffffffffc0203156:	22800593          	li	a1,552
ffffffffc020315a:	00003517          	auipc	a0,0x3
ffffffffc020315e:	4ae50513          	addi	a0,a0,1198 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203162:	b30fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203166:	00003697          	auipc	a3,0x3
ffffffffc020316a:	7ea68693          	addi	a3,a3,2026 # ffffffffc0206950 <default_pmm_manager+0x498>
ffffffffc020316e:	00003617          	auipc	a2,0x3
ffffffffc0203172:	f9a60613          	addi	a2,a2,-102 # ffffffffc0206108 <commands+0x818>
ffffffffc0203176:	22700593          	li	a1,551
ffffffffc020317a:	00003517          	auipc	a0,0x3
ffffffffc020317e:	48e50513          	addi	a0,a0,1166 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203182:	b10fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203186:	00003697          	auipc	a3,0x3
ffffffffc020318a:	7b268693          	addi	a3,a3,1970 # ffffffffc0206938 <default_pmm_manager+0x480>
ffffffffc020318e:	00003617          	auipc	a2,0x3
ffffffffc0203192:	f7a60613          	addi	a2,a2,-134 # ffffffffc0206108 <commands+0x818>
ffffffffc0203196:	22500593          	li	a1,549
ffffffffc020319a:	00003517          	auipc	a0,0x3
ffffffffc020319e:	46e50513          	addi	a0,a0,1134 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02031a2:	af0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031a6:	00003697          	auipc	a3,0x3
ffffffffc02031aa:	77268693          	addi	a3,a3,1906 # ffffffffc0206918 <default_pmm_manager+0x460>
ffffffffc02031ae:	00003617          	auipc	a2,0x3
ffffffffc02031b2:	f5a60613          	addi	a2,a2,-166 # ffffffffc0206108 <commands+0x818>
ffffffffc02031b6:	22400593          	li	a1,548
ffffffffc02031ba:	00003517          	auipc	a0,0x3
ffffffffc02031be:	44e50513          	addi	a0,a0,1102 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02031c2:	ad0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02031c6:	00003697          	auipc	a3,0x3
ffffffffc02031ca:	74268693          	addi	a3,a3,1858 # ffffffffc0206908 <default_pmm_manager+0x450>
ffffffffc02031ce:	00003617          	auipc	a2,0x3
ffffffffc02031d2:	f3a60613          	addi	a2,a2,-198 # ffffffffc0206108 <commands+0x818>
ffffffffc02031d6:	22300593          	li	a1,547
ffffffffc02031da:	00003517          	auipc	a0,0x3
ffffffffc02031de:	42e50513          	addi	a0,a0,1070 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02031e2:	ab0fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031e6:	00003697          	auipc	a3,0x3
ffffffffc02031ea:	71268693          	addi	a3,a3,1810 # ffffffffc02068f8 <default_pmm_manager+0x440>
ffffffffc02031ee:	00003617          	auipc	a2,0x3
ffffffffc02031f2:	f1a60613          	addi	a2,a2,-230 # ffffffffc0206108 <commands+0x818>
ffffffffc02031f6:	22200593          	li	a1,546
ffffffffc02031fa:	00003517          	auipc	a0,0x3
ffffffffc02031fe:	40e50513          	addi	a0,a0,1038 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203202:	a90fd0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("DTB memory info not available");
ffffffffc0203206:	00003617          	auipc	a2,0x3
ffffffffc020320a:	49260613          	addi	a2,a2,1170 # ffffffffc0206698 <default_pmm_manager+0x1e0>
ffffffffc020320e:	06500593          	li	a1,101
ffffffffc0203212:	00003517          	auipc	a0,0x3
ffffffffc0203216:	3f650513          	addi	a0,a0,1014 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020321a:	a78fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020321e:	00003697          	auipc	a3,0x3
ffffffffc0203222:	7f268693          	addi	a3,a3,2034 # ffffffffc0206a10 <default_pmm_manager+0x558>
ffffffffc0203226:	00003617          	auipc	a2,0x3
ffffffffc020322a:	ee260613          	addi	a2,a2,-286 # ffffffffc0206108 <commands+0x818>
ffffffffc020322e:	26800593          	li	a1,616
ffffffffc0203232:	00003517          	auipc	a0,0x3
ffffffffc0203236:	3d650513          	addi	a0,a0,982 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020323a:	a58fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020323e:	00003697          	auipc	a3,0x3
ffffffffc0203242:	68268693          	addi	a3,a3,1666 # ffffffffc02068c0 <default_pmm_manager+0x408>
ffffffffc0203246:	00003617          	auipc	a2,0x3
ffffffffc020324a:	ec260613          	addi	a2,a2,-318 # ffffffffc0206108 <commands+0x818>
ffffffffc020324e:	22100593          	li	a1,545
ffffffffc0203252:	00003517          	auipc	a0,0x3
ffffffffc0203256:	3b650513          	addi	a0,a0,950 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020325a:	a38fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020325e:	00003697          	auipc	a3,0x3
ffffffffc0203262:	62268693          	addi	a3,a3,1570 # ffffffffc0206880 <default_pmm_manager+0x3c8>
ffffffffc0203266:	00003617          	auipc	a2,0x3
ffffffffc020326a:	ea260613          	addi	a2,a2,-350 # ffffffffc0206108 <commands+0x818>
ffffffffc020326e:	22000593          	li	a1,544
ffffffffc0203272:	00003517          	auipc	a0,0x3
ffffffffc0203276:	39650513          	addi	a0,a0,918 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020327a:	a18fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020327e:	86d6                	mv	a3,s5
ffffffffc0203280:	00003617          	auipc	a2,0x3
ffffffffc0203284:	27060613          	addi	a2,a2,624 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0203288:	21c00593          	li	a1,540
ffffffffc020328c:	00003517          	auipc	a0,0x3
ffffffffc0203290:	37c50513          	addi	a0,a0,892 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203294:	9fefd0ef          	jal	ra,ffffffffc0200492 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203298:	00003617          	auipc	a2,0x3
ffffffffc020329c:	25860613          	addi	a2,a2,600 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc02032a0:	21b00593          	li	a1,539
ffffffffc02032a4:	00003517          	auipc	a0,0x3
ffffffffc02032a8:	36450513          	addi	a0,a0,868 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02032ac:	9e6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032b0:	00003697          	auipc	a3,0x3
ffffffffc02032b4:	58868693          	addi	a3,a3,1416 # ffffffffc0206838 <default_pmm_manager+0x380>
ffffffffc02032b8:	00003617          	auipc	a2,0x3
ffffffffc02032bc:	e5060613          	addi	a2,a2,-432 # ffffffffc0206108 <commands+0x818>
ffffffffc02032c0:	21900593          	li	a1,537
ffffffffc02032c4:	00003517          	auipc	a0,0x3
ffffffffc02032c8:	34450513          	addi	a0,a0,836 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02032cc:	9c6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032d0:	00003697          	auipc	a3,0x3
ffffffffc02032d4:	55068693          	addi	a3,a3,1360 # ffffffffc0206820 <default_pmm_manager+0x368>
ffffffffc02032d8:	00003617          	auipc	a2,0x3
ffffffffc02032dc:	e3060613          	addi	a2,a2,-464 # ffffffffc0206108 <commands+0x818>
ffffffffc02032e0:	21800593          	li	a1,536
ffffffffc02032e4:	00003517          	auipc	a0,0x3
ffffffffc02032e8:	32450513          	addi	a0,a0,804 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02032ec:	9a6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032f0:	00004697          	auipc	a3,0x4
ffffffffc02032f4:	8e068693          	addi	a3,a3,-1824 # ffffffffc0206bd0 <default_pmm_manager+0x718>
ffffffffc02032f8:	00003617          	auipc	a2,0x3
ffffffffc02032fc:	e1060613          	addi	a2,a2,-496 # ffffffffc0206108 <commands+0x818>
ffffffffc0203300:	25f00593          	li	a1,607
ffffffffc0203304:	00003517          	auipc	a0,0x3
ffffffffc0203308:	30450513          	addi	a0,a0,772 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020330c:	986fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203310:	00004697          	auipc	a3,0x4
ffffffffc0203314:	88868693          	addi	a3,a3,-1912 # ffffffffc0206b98 <default_pmm_manager+0x6e0>
ffffffffc0203318:	00003617          	auipc	a2,0x3
ffffffffc020331c:	df060613          	addi	a2,a2,-528 # ffffffffc0206108 <commands+0x818>
ffffffffc0203320:	25c00593          	li	a1,604
ffffffffc0203324:	00003517          	auipc	a0,0x3
ffffffffc0203328:	2e450513          	addi	a0,a0,740 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020332c:	966fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203330:	00004697          	auipc	a3,0x4
ffffffffc0203334:	83868693          	addi	a3,a3,-1992 # ffffffffc0206b68 <default_pmm_manager+0x6b0>
ffffffffc0203338:	00003617          	auipc	a2,0x3
ffffffffc020333c:	dd060613          	addi	a2,a2,-560 # ffffffffc0206108 <commands+0x818>
ffffffffc0203340:	25800593          	li	a1,600
ffffffffc0203344:	00003517          	auipc	a0,0x3
ffffffffc0203348:	2c450513          	addi	a0,a0,708 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020334c:	946fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203350:	00003697          	auipc	a3,0x3
ffffffffc0203354:	7d068693          	addi	a3,a3,2000 # ffffffffc0206b20 <default_pmm_manager+0x668>
ffffffffc0203358:	00003617          	auipc	a2,0x3
ffffffffc020335c:	db060613          	addi	a2,a2,-592 # ffffffffc0206108 <commands+0x818>
ffffffffc0203360:	25700593          	li	a1,599
ffffffffc0203364:	00003517          	auipc	a0,0x3
ffffffffc0203368:	2a450513          	addi	a0,a0,676 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020336c:	926fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203370:	00003617          	auipc	a2,0x3
ffffffffc0203374:	22860613          	addi	a2,a2,552 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc0203378:	0c900593          	li	a1,201
ffffffffc020337c:	00003517          	auipc	a0,0x3
ffffffffc0203380:	28c50513          	addi	a0,a0,652 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc0203384:	90efd0ef          	jal	ra,ffffffffc0200492 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203388:	00003617          	auipc	a2,0x3
ffffffffc020338c:	21060613          	addi	a2,a2,528 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc0203390:	08100593          	li	a1,129
ffffffffc0203394:	00003517          	auipc	a0,0x3
ffffffffc0203398:	27450513          	addi	a0,a0,628 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020339c:	8f6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033a0:	00003697          	auipc	a3,0x3
ffffffffc02033a4:	45068693          	addi	a3,a3,1104 # ffffffffc02067f0 <default_pmm_manager+0x338>
ffffffffc02033a8:	00003617          	auipc	a2,0x3
ffffffffc02033ac:	d6060613          	addi	a2,a2,-672 # ffffffffc0206108 <commands+0x818>
ffffffffc02033b0:	21700593          	li	a1,535
ffffffffc02033b4:	00003517          	auipc	a0,0x3
ffffffffc02033b8:	25450513          	addi	a0,a0,596 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02033bc:	8d6fd0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02033c0:	00003697          	auipc	a3,0x3
ffffffffc02033c4:	40068693          	addi	a3,a3,1024 # ffffffffc02067c0 <default_pmm_manager+0x308>
ffffffffc02033c8:	00003617          	auipc	a2,0x3
ffffffffc02033cc:	d4060613          	addi	a2,a2,-704 # ffffffffc0206108 <commands+0x818>
ffffffffc02033d0:	21400593          	li	a1,532
ffffffffc02033d4:	00003517          	auipc	a0,0x3
ffffffffc02033d8:	23450513          	addi	a0,a0,564 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc02033dc:	8b6fd0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02033e0 <pgdir_alloc_page>:
{
ffffffffc02033e0:	7179                	addi	sp,sp,-48
ffffffffc02033e2:	ec26                	sd	s1,24(sp)
ffffffffc02033e4:	e84a                	sd	s2,16(sp)
ffffffffc02033e6:	e052                	sd	s4,0(sp)
ffffffffc02033e8:	f406                	sd	ra,40(sp)
ffffffffc02033ea:	f022                	sd	s0,32(sp)
ffffffffc02033ec:	e44e                	sd	s3,8(sp)
ffffffffc02033ee:	8a2a                	mv	s4,a0
ffffffffc02033f0:	84ae                	mv	s1,a1
ffffffffc02033f2:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02033f4:	100027f3          	csrr	a5,sstatus
ffffffffc02033f8:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc02033fa:	000c3997          	auipc	s3,0xc3
ffffffffc02033fe:	94e98993          	addi	s3,s3,-1714 # ffffffffc02c5d48 <pmm_manager>
ffffffffc0203402:	ef8d                	bnez	a5,ffffffffc020343c <pgdir_alloc_page+0x5c>
ffffffffc0203404:	0009b783          	ld	a5,0(s3)
ffffffffc0203408:	4505                	li	a0,1
ffffffffc020340a:	6f9c                	ld	a5,24(a5)
ffffffffc020340c:	9782                	jalr	a5
ffffffffc020340e:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203410:	cc09                	beqz	s0,ffffffffc020342a <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203412:	86ca                	mv	a3,s2
ffffffffc0203414:	8626                	mv	a2,s1
ffffffffc0203416:	85a2                	mv	a1,s0
ffffffffc0203418:	8552                	mv	a0,s4
ffffffffc020341a:	a90ff0ef          	jal	ra,ffffffffc02026aa <page_insert>
ffffffffc020341e:	e915                	bnez	a0,ffffffffc0203452 <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203420:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc0203422:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc0203424:	4785                	li	a5,1
ffffffffc0203426:	04f71e63          	bne	a4,a5,ffffffffc0203482 <pgdir_alloc_page+0xa2>
}
ffffffffc020342a:	70a2                	ld	ra,40(sp)
ffffffffc020342c:	8522                	mv	a0,s0
ffffffffc020342e:	7402                	ld	s0,32(sp)
ffffffffc0203430:	64e2                	ld	s1,24(sp)
ffffffffc0203432:	6942                	ld	s2,16(sp)
ffffffffc0203434:	69a2                	ld	s3,8(sp)
ffffffffc0203436:	6a02                	ld	s4,0(sp)
ffffffffc0203438:	6145                	addi	sp,sp,48
ffffffffc020343a:	8082                	ret
        intr_disable();
ffffffffc020343c:	d5afd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203440:	0009b783          	ld	a5,0(s3)
ffffffffc0203444:	4505                	li	a0,1
ffffffffc0203446:	6f9c                	ld	a5,24(a5)
ffffffffc0203448:	9782                	jalr	a5
ffffffffc020344a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020344c:	d44fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0203450:	b7c1                	j	ffffffffc0203410 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203452:	100027f3          	csrr	a5,sstatus
ffffffffc0203456:	8b89                	andi	a5,a5,2
ffffffffc0203458:	eb89                	bnez	a5,ffffffffc020346a <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc020345a:	0009b783          	ld	a5,0(s3)
ffffffffc020345e:	8522                	mv	a0,s0
ffffffffc0203460:	4585                	li	a1,1
ffffffffc0203462:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203464:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203466:	9782                	jalr	a5
    if (flag)
ffffffffc0203468:	b7c9                	j	ffffffffc020342a <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc020346a:	d2cfd0ef          	jal	ra,ffffffffc0200996 <intr_disable>
ffffffffc020346e:	0009b783          	ld	a5,0(s3)
ffffffffc0203472:	8522                	mv	a0,s0
ffffffffc0203474:	4585                	li	a1,1
ffffffffc0203476:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203478:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020347a:	9782                	jalr	a5
        intr_enable();
ffffffffc020347c:	d14fd0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0203480:	b76d                	j	ffffffffc020342a <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc0203482:	00003697          	auipc	a3,0x3
ffffffffc0203486:	79668693          	addi	a3,a3,1942 # ffffffffc0206c18 <default_pmm_manager+0x760>
ffffffffc020348a:	00003617          	auipc	a2,0x3
ffffffffc020348e:	c7e60613          	addi	a2,a2,-898 # ffffffffc0206108 <commands+0x818>
ffffffffc0203492:	1f500593          	li	a1,501
ffffffffc0203496:	00003517          	auipc	a0,0x3
ffffffffc020349a:	17250513          	addi	a0,a0,370 # ffffffffc0206608 <default_pmm_manager+0x150>
ffffffffc020349e:	ff5fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02034a2 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02034a2:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02034a4:	00003697          	auipc	a3,0x3
ffffffffc02034a8:	78c68693          	addi	a3,a3,1932 # ffffffffc0206c30 <default_pmm_manager+0x778>
ffffffffc02034ac:	00003617          	auipc	a2,0x3
ffffffffc02034b0:	c5c60613          	addi	a2,a2,-932 # ffffffffc0206108 <commands+0x818>
ffffffffc02034b4:	07400593          	li	a1,116
ffffffffc02034b8:	00003517          	auipc	a0,0x3
ffffffffc02034bc:	79850513          	addi	a0,a0,1944 # ffffffffc0206c50 <default_pmm_manager+0x798>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02034c0:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02034c2:	fd1fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02034c6 <mm_create>:
{
ffffffffc02034c6:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02034c8:	04000513          	li	a0,64
{
ffffffffc02034cc:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02034ce:	e98fe0ef          	jal	ra,ffffffffc0201b66 <kmalloc>
    if (mm != NULL)
ffffffffc02034d2:	cd19                	beqz	a0,ffffffffc02034f0 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02034d4:	e508                	sd	a0,8(a0)
ffffffffc02034d6:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02034d8:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02034dc:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02034e0:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02034e4:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02034e8:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02034ec:	02053c23          	sd	zero,56(a0)
}
ffffffffc02034f0:	60a2                	ld	ra,8(sp)
ffffffffc02034f2:	0141                	addi	sp,sp,16
ffffffffc02034f4:	8082                	ret

ffffffffc02034f6 <find_vma>:
{
ffffffffc02034f6:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc02034f8:	c505                	beqz	a0,ffffffffc0203520 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02034fa:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02034fc:	c501                	beqz	a0,ffffffffc0203504 <find_vma+0xe>
ffffffffc02034fe:	651c                	ld	a5,8(a0)
ffffffffc0203500:	02f5f263          	bgeu	a1,a5,ffffffffc0203524 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203504:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0203506:	00f68d63          	beq	a3,a5,ffffffffc0203520 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020350a:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7d3a260>
ffffffffc020350e:	00e5e663          	bltu	a1,a4,ffffffffc020351a <find_vma+0x24>
ffffffffc0203512:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203516:	00e5ec63          	bltu	a1,a4,ffffffffc020352e <find_vma+0x38>
ffffffffc020351a:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020351c:	fef697e3          	bne	a3,a5,ffffffffc020350a <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203520:	4501                	li	a0,0
}
ffffffffc0203522:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203524:	691c                	ld	a5,16(a0)
ffffffffc0203526:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0203504 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020352a:	ea88                	sd	a0,16(a3)
ffffffffc020352c:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc020352e:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203532:	ea88                	sd	a0,16(a3)
ffffffffc0203534:	8082                	ret

ffffffffc0203536 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203536:	6590                	ld	a2,8(a1)
ffffffffc0203538:	0105b803          	ld	a6,16(a1)
{
ffffffffc020353c:	1141                	addi	sp,sp,-16
ffffffffc020353e:	e406                	sd	ra,8(sp)
ffffffffc0203540:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203542:	01066763          	bltu	a2,a6,ffffffffc0203550 <insert_vma_struct+0x1a>
ffffffffc0203546:	a085                	j	ffffffffc02035a6 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203548:	fe87b703          	ld	a4,-24(a5)
ffffffffc020354c:	04e66863          	bltu	a2,a4,ffffffffc020359c <insert_vma_struct+0x66>
ffffffffc0203550:	86be                	mv	a3,a5
ffffffffc0203552:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203554:	fef51ae3          	bne	a0,a5,ffffffffc0203548 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203558:	02a68463          	beq	a3,a0,ffffffffc0203580 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020355c:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203560:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203564:	08e8f163          	bgeu	a7,a4,ffffffffc02035e6 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203568:	04e66f63          	bltu	a2,a4,ffffffffc02035c6 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc020356c:	00f50a63          	beq	a0,a5,ffffffffc0203580 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203570:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203574:	05076963          	bltu	a4,a6,ffffffffc02035c6 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203578:	ff07b603          	ld	a2,-16(a5)
ffffffffc020357c:	02c77363          	bgeu	a4,a2,ffffffffc02035a2 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203580:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203582:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203584:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203588:	e390                	sd	a2,0(a5)
ffffffffc020358a:	e690                	sd	a2,8(a3)
}
ffffffffc020358c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020358e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203590:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203592:	0017079b          	addiw	a5,a4,1
ffffffffc0203596:	d11c                	sw	a5,32(a0)
}
ffffffffc0203598:	0141                	addi	sp,sp,16
ffffffffc020359a:	8082                	ret
    if (le_prev != list)
ffffffffc020359c:	fca690e3          	bne	a3,a0,ffffffffc020355c <insert_vma_struct+0x26>
ffffffffc02035a0:	bfd1                	j	ffffffffc0203574 <insert_vma_struct+0x3e>
ffffffffc02035a2:	f01ff0ef          	jal	ra,ffffffffc02034a2 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035a6:	00003697          	auipc	a3,0x3
ffffffffc02035aa:	6ba68693          	addi	a3,a3,1722 # ffffffffc0206c60 <default_pmm_manager+0x7a8>
ffffffffc02035ae:	00003617          	auipc	a2,0x3
ffffffffc02035b2:	b5a60613          	addi	a2,a2,-1190 # ffffffffc0206108 <commands+0x818>
ffffffffc02035b6:	07a00593          	li	a1,122
ffffffffc02035ba:	00003517          	auipc	a0,0x3
ffffffffc02035be:	69650513          	addi	a0,a0,1686 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc02035c2:	ed1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02035c6:	00003697          	auipc	a3,0x3
ffffffffc02035ca:	6da68693          	addi	a3,a3,1754 # ffffffffc0206ca0 <default_pmm_manager+0x7e8>
ffffffffc02035ce:	00003617          	auipc	a2,0x3
ffffffffc02035d2:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0206108 <commands+0x818>
ffffffffc02035d6:	07300593          	li	a1,115
ffffffffc02035da:	00003517          	auipc	a0,0x3
ffffffffc02035de:	67650513          	addi	a0,a0,1654 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc02035e2:	eb1fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02035e6:	00003697          	auipc	a3,0x3
ffffffffc02035ea:	69a68693          	addi	a3,a3,1690 # ffffffffc0206c80 <default_pmm_manager+0x7c8>
ffffffffc02035ee:	00003617          	auipc	a2,0x3
ffffffffc02035f2:	b1a60613          	addi	a2,a2,-1254 # ffffffffc0206108 <commands+0x818>
ffffffffc02035f6:	07200593          	li	a1,114
ffffffffc02035fa:	00003517          	auipc	a0,0x3
ffffffffc02035fe:	65650513          	addi	a0,a0,1622 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203602:	e91fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203606 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203606:	591c                	lw	a5,48(a0)
{
ffffffffc0203608:	1141                	addi	sp,sp,-16
ffffffffc020360a:	e406                	sd	ra,8(sp)
ffffffffc020360c:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020360e:	e78d                	bnez	a5,ffffffffc0203638 <mm_destroy+0x32>
ffffffffc0203610:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203612:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203614:	00a40c63          	beq	s0,a0,ffffffffc020362c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203618:	6118                	ld	a4,0(a0)
ffffffffc020361a:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020361c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020361e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203620:	e398                	sd	a4,0(a5)
ffffffffc0203622:	df4fe0ef          	jal	ra,ffffffffc0201c16 <kfree>
    return listelm->next;
ffffffffc0203626:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203628:	fea418e3          	bne	s0,a0,ffffffffc0203618 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc020362c:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020362e:	6402                	ld	s0,0(sp)
ffffffffc0203630:	60a2                	ld	ra,8(sp)
ffffffffc0203632:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203634:	de2fe06f          	j	ffffffffc0201c16 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203638:	00003697          	auipc	a3,0x3
ffffffffc020363c:	68868693          	addi	a3,a3,1672 # ffffffffc0206cc0 <default_pmm_manager+0x808>
ffffffffc0203640:	00003617          	auipc	a2,0x3
ffffffffc0203644:	ac860613          	addi	a2,a2,-1336 # ffffffffc0206108 <commands+0x818>
ffffffffc0203648:	09e00593          	li	a1,158
ffffffffc020364c:	00003517          	auipc	a0,0x3
ffffffffc0203650:	60450513          	addi	a0,a0,1540 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203654:	e3ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203658 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203658:	7139                	addi	sp,sp,-64
ffffffffc020365a:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020365c:	6405                	lui	s0,0x1
ffffffffc020365e:	147d                	addi	s0,s0,-1
ffffffffc0203660:	77fd                	lui	a5,0xfffff
ffffffffc0203662:	9622                	add	a2,a2,s0
ffffffffc0203664:	962e                	add	a2,a2,a1
{
ffffffffc0203666:	f426                	sd	s1,40(sp)
ffffffffc0203668:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020366a:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc020366e:	f04a                	sd	s2,32(sp)
ffffffffc0203670:	ec4e                	sd	s3,24(sp)
ffffffffc0203672:	e852                	sd	s4,16(sp)
ffffffffc0203674:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203676:	002005b7          	lui	a1,0x200
ffffffffc020367a:	00f67433          	and	s0,a2,a5
ffffffffc020367e:	06b4e363          	bltu	s1,a1,ffffffffc02036e4 <mm_map+0x8c>
ffffffffc0203682:	0684f163          	bgeu	s1,s0,ffffffffc02036e4 <mm_map+0x8c>
ffffffffc0203686:	4785                	li	a5,1
ffffffffc0203688:	07fe                	slli	a5,a5,0x1f
ffffffffc020368a:	0487ed63          	bltu	a5,s0,ffffffffc02036e4 <mm_map+0x8c>
ffffffffc020368e:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203690:	cd21                	beqz	a0,ffffffffc02036e8 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203692:	85a6                	mv	a1,s1
ffffffffc0203694:	8ab6                	mv	s5,a3
ffffffffc0203696:	8a3a                	mv	s4,a4
ffffffffc0203698:	e5fff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
ffffffffc020369c:	c501                	beqz	a0,ffffffffc02036a4 <mm_map+0x4c>
ffffffffc020369e:	651c                	ld	a5,8(a0)
ffffffffc02036a0:	0487e263          	bltu	a5,s0,ffffffffc02036e4 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02036a4:	03000513          	li	a0,48
ffffffffc02036a8:	cbefe0ef          	jal	ra,ffffffffc0201b66 <kmalloc>
ffffffffc02036ac:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02036ae:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02036b0:	02090163          	beqz	s2,ffffffffc02036d2 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02036b4:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02036b6:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02036ba:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02036be:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02036c2:	85ca                	mv	a1,s2
ffffffffc02036c4:	e73ff0ef          	jal	ra,ffffffffc0203536 <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02036c8:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02036ca:	000a0463          	beqz	s4,ffffffffc02036d2 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02036ce:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc02036d2:	70e2                	ld	ra,56(sp)
ffffffffc02036d4:	7442                	ld	s0,48(sp)
ffffffffc02036d6:	74a2                	ld	s1,40(sp)
ffffffffc02036d8:	7902                	ld	s2,32(sp)
ffffffffc02036da:	69e2                	ld	s3,24(sp)
ffffffffc02036dc:	6a42                	ld	s4,16(sp)
ffffffffc02036de:	6aa2                	ld	s5,8(sp)
ffffffffc02036e0:	6121                	addi	sp,sp,64
ffffffffc02036e2:	8082                	ret
        return -E_INVAL;
ffffffffc02036e4:	5575                	li	a0,-3
ffffffffc02036e6:	b7f5                	j	ffffffffc02036d2 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02036e8:	00003697          	auipc	a3,0x3
ffffffffc02036ec:	5f068693          	addi	a3,a3,1520 # ffffffffc0206cd8 <default_pmm_manager+0x820>
ffffffffc02036f0:	00003617          	auipc	a2,0x3
ffffffffc02036f4:	a1860613          	addi	a2,a2,-1512 # ffffffffc0206108 <commands+0x818>
ffffffffc02036f8:	0b300593          	li	a1,179
ffffffffc02036fc:	00003517          	auipc	a0,0x3
ffffffffc0203700:	55450513          	addi	a0,a0,1364 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203704:	d8ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203708 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203708:	7139                	addi	sp,sp,-64
ffffffffc020370a:	fc06                	sd	ra,56(sp)
ffffffffc020370c:	f822                	sd	s0,48(sp)
ffffffffc020370e:	f426                	sd	s1,40(sp)
ffffffffc0203710:	f04a                	sd	s2,32(sp)
ffffffffc0203712:	ec4e                	sd	s3,24(sp)
ffffffffc0203714:	e852                	sd	s4,16(sp)
ffffffffc0203716:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203718:	c52d                	beqz	a0,ffffffffc0203782 <dup_mmap+0x7a>
ffffffffc020371a:	892a                	mv	s2,a0
ffffffffc020371c:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020371e:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203720:	e595                	bnez	a1,ffffffffc020374c <dup_mmap+0x44>
ffffffffc0203722:	a085                	j	ffffffffc0203782 <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203724:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc0203726:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_matrix_out_size+0x1f38e0>
        vma->vm_end = vm_end;
ffffffffc020372a:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020372e:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0203732:	e05ff0ef          	jal	ra,ffffffffc0203536 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203736:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8f60>
ffffffffc020373a:	fe843603          	ld	a2,-24(s0)
ffffffffc020373e:	6c8c                	ld	a1,24(s1)
ffffffffc0203740:	01893503          	ld	a0,24(s2)
ffffffffc0203744:	4701                	li	a4,0
ffffffffc0203746:	d0bfe0ef          	jal	ra,ffffffffc0202450 <copy_range>
ffffffffc020374a:	e105                	bnez	a0,ffffffffc020376a <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020374c:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc020374e:	02848863          	beq	s1,s0,ffffffffc020377e <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203752:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0203756:	fe843a83          	ld	s5,-24(s0)
ffffffffc020375a:	ff043a03          	ld	s4,-16(s0)
ffffffffc020375e:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203762:	c04fe0ef          	jal	ra,ffffffffc0201b66 <kmalloc>
ffffffffc0203766:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203768:	fd55                	bnez	a0,ffffffffc0203724 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc020376a:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020376c:	70e2                	ld	ra,56(sp)
ffffffffc020376e:	7442                	ld	s0,48(sp)
ffffffffc0203770:	74a2                	ld	s1,40(sp)
ffffffffc0203772:	7902                	ld	s2,32(sp)
ffffffffc0203774:	69e2                	ld	s3,24(sp)
ffffffffc0203776:	6a42                	ld	s4,16(sp)
ffffffffc0203778:	6aa2                	ld	s5,8(sp)
ffffffffc020377a:	6121                	addi	sp,sp,64
ffffffffc020377c:	8082                	ret
    return 0;
ffffffffc020377e:	4501                	li	a0,0
ffffffffc0203780:	b7f5                	j	ffffffffc020376c <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0203782:	00003697          	auipc	a3,0x3
ffffffffc0203786:	56668693          	addi	a3,a3,1382 # ffffffffc0206ce8 <default_pmm_manager+0x830>
ffffffffc020378a:	00003617          	auipc	a2,0x3
ffffffffc020378e:	97e60613          	addi	a2,a2,-1666 # ffffffffc0206108 <commands+0x818>
ffffffffc0203792:	0cf00593          	li	a1,207
ffffffffc0203796:	00003517          	auipc	a0,0x3
ffffffffc020379a:	4ba50513          	addi	a0,a0,1210 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc020379e:	cf5fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02037a2 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02037a2:	1101                	addi	sp,sp,-32
ffffffffc02037a4:	ec06                	sd	ra,24(sp)
ffffffffc02037a6:	e822                	sd	s0,16(sp)
ffffffffc02037a8:	e426                	sd	s1,8(sp)
ffffffffc02037aa:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02037ac:	c531                	beqz	a0,ffffffffc02037f8 <exit_mmap+0x56>
ffffffffc02037ae:	591c                	lw	a5,48(a0)
ffffffffc02037b0:	84aa                	mv	s1,a0
ffffffffc02037b2:	e3b9                	bnez	a5,ffffffffc02037f8 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02037b4:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02037b6:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02037ba:	02850663          	beq	a0,s0,ffffffffc02037e6 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02037be:	ff043603          	ld	a2,-16(s0)
ffffffffc02037c2:	fe843583          	ld	a1,-24(s0)
ffffffffc02037c6:	854a                	mv	a0,s2
ffffffffc02037c8:	8b1fe0ef          	jal	ra,ffffffffc0202078 <unmap_range>
ffffffffc02037cc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02037ce:	fe8498e3          	bne	s1,s0,ffffffffc02037be <exit_mmap+0x1c>
ffffffffc02037d2:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02037d4:	00848c63          	beq	s1,s0,ffffffffc02037ec <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02037d8:	ff043603          	ld	a2,-16(s0)
ffffffffc02037dc:	fe843583          	ld	a1,-24(s0)
ffffffffc02037e0:	854a                	mv	a0,s2
ffffffffc02037e2:	9ddfe0ef          	jal	ra,ffffffffc02021be <exit_range>
ffffffffc02037e6:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02037e8:	fe8498e3          	bne	s1,s0,ffffffffc02037d8 <exit_mmap+0x36>
    }
}
ffffffffc02037ec:	60e2                	ld	ra,24(sp)
ffffffffc02037ee:	6442                	ld	s0,16(sp)
ffffffffc02037f0:	64a2                	ld	s1,8(sp)
ffffffffc02037f2:	6902                	ld	s2,0(sp)
ffffffffc02037f4:	6105                	addi	sp,sp,32
ffffffffc02037f6:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02037f8:	00003697          	auipc	a3,0x3
ffffffffc02037fc:	51068693          	addi	a3,a3,1296 # ffffffffc0206d08 <default_pmm_manager+0x850>
ffffffffc0203800:	00003617          	auipc	a2,0x3
ffffffffc0203804:	90860613          	addi	a2,a2,-1784 # ffffffffc0206108 <commands+0x818>
ffffffffc0203808:	0e800593          	li	a1,232
ffffffffc020380c:	00003517          	auipc	a0,0x3
ffffffffc0203810:	44450513          	addi	a0,a0,1092 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203814:	c7ffc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203818 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203818:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020381a:	04000513          	li	a0,64
{
ffffffffc020381e:	fc06                	sd	ra,56(sp)
ffffffffc0203820:	f822                	sd	s0,48(sp)
ffffffffc0203822:	f426                	sd	s1,40(sp)
ffffffffc0203824:	f04a                	sd	s2,32(sp)
ffffffffc0203826:	ec4e                	sd	s3,24(sp)
ffffffffc0203828:	e852                	sd	s4,16(sp)
ffffffffc020382a:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020382c:	b3afe0ef          	jal	ra,ffffffffc0201b66 <kmalloc>
    if (mm != NULL)
ffffffffc0203830:	2e050663          	beqz	a0,ffffffffc0203b1c <vmm_init+0x304>
ffffffffc0203834:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203836:	e508                	sd	a0,8(a0)
ffffffffc0203838:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020383a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020383e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203842:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203846:	02053423          	sd	zero,40(a0)
ffffffffc020384a:	02052823          	sw	zero,48(a0)
ffffffffc020384e:	02053c23          	sd	zero,56(a0)
ffffffffc0203852:	03200413          	li	s0,50
ffffffffc0203856:	a811                	j	ffffffffc020386a <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203858:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc020385a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020385c:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203860:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203862:	8526                	mv	a0,s1
ffffffffc0203864:	cd3ff0ef          	jal	ra,ffffffffc0203536 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203868:	c80d                	beqz	s0,ffffffffc020389a <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020386a:	03000513          	li	a0,48
ffffffffc020386e:	af8fe0ef          	jal	ra,ffffffffc0201b66 <kmalloc>
ffffffffc0203872:	85aa                	mv	a1,a0
ffffffffc0203874:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203878:	f165                	bnez	a0,ffffffffc0203858 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc020387a:	00003697          	auipc	a3,0x3
ffffffffc020387e:	62668693          	addi	a3,a3,1574 # ffffffffc0206ea0 <default_pmm_manager+0x9e8>
ffffffffc0203882:	00003617          	auipc	a2,0x3
ffffffffc0203886:	88660613          	addi	a2,a2,-1914 # ffffffffc0206108 <commands+0x818>
ffffffffc020388a:	12c00593          	li	a1,300
ffffffffc020388e:	00003517          	auipc	a0,0x3
ffffffffc0203892:	3c250513          	addi	a0,a0,962 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203896:	bfdfc0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc020389a:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc020389e:	1f900913          	li	s2,505
ffffffffc02038a2:	a819                	j	ffffffffc02038b8 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc02038a4:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02038a6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02038a8:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02038ac:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02038ae:	8526                	mv	a0,s1
ffffffffc02038b0:	c87ff0ef          	jal	ra,ffffffffc0203536 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02038b4:	03240a63          	beq	s0,s2,ffffffffc02038e8 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038b8:	03000513          	li	a0,48
ffffffffc02038bc:	aaafe0ef          	jal	ra,ffffffffc0201b66 <kmalloc>
ffffffffc02038c0:	85aa                	mv	a1,a0
ffffffffc02038c2:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc02038c6:	fd79                	bnez	a0,ffffffffc02038a4 <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc02038c8:	00003697          	auipc	a3,0x3
ffffffffc02038cc:	5d868693          	addi	a3,a3,1496 # ffffffffc0206ea0 <default_pmm_manager+0x9e8>
ffffffffc02038d0:	00003617          	auipc	a2,0x3
ffffffffc02038d4:	83860613          	addi	a2,a2,-1992 # ffffffffc0206108 <commands+0x818>
ffffffffc02038d8:	13300593          	li	a1,307
ffffffffc02038dc:	00003517          	auipc	a0,0x3
ffffffffc02038e0:	37450513          	addi	a0,a0,884 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc02038e4:	baffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return listelm->next;
ffffffffc02038e8:	649c                	ld	a5,8(s1)
ffffffffc02038ea:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02038ec:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc02038f0:	16f48663          	beq	s1,a5,ffffffffc0203a5c <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02038f4:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd39260>
ffffffffc02038f8:	ffe70693          	addi	a3,a4,-2 # ffe <_binary_obj___user_faultread_out_size-0x8f52>
ffffffffc02038fc:	10d61063          	bne	a2,a3,ffffffffc02039fc <vmm_init+0x1e4>
ffffffffc0203900:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203904:	0ed71c63          	bne	a4,a3,ffffffffc02039fc <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203908:	0715                	addi	a4,a4,5
ffffffffc020390a:	679c                	ld	a5,8(a5)
ffffffffc020390c:	feb712e3          	bne	a4,a1,ffffffffc02038f0 <vmm_init+0xd8>
ffffffffc0203910:	4a1d                	li	s4,7
ffffffffc0203912:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203914:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203918:	85a2                	mv	a1,s0
ffffffffc020391a:	8526                	mv	a0,s1
ffffffffc020391c:	bdbff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
ffffffffc0203920:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203922:	16050d63          	beqz	a0,ffffffffc0203a9c <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203926:	00140593          	addi	a1,s0,1
ffffffffc020392a:	8526                	mv	a0,s1
ffffffffc020392c:	bcbff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
ffffffffc0203930:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203932:	14050563          	beqz	a0,ffffffffc0203a7c <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203936:	85d2                	mv	a1,s4
ffffffffc0203938:	8526                	mv	a0,s1
ffffffffc020393a:	bbdff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
        assert(vma3 == NULL);
ffffffffc020393e:	16051f63          	bnez	a0,ffffffffc0203abc <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203942:	00340593          	addi	a1,s0,3
ffffffffc0203946:	8526                	mv	a0,s1
ffffffffc0203948:	bafff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
        assert(vma4 == NULL);
ffffffffc020394c:	1a051863          	bnez	a0,ffffffffc0203afc <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203950:	00440593          	addi	a1,s0,4
ffffffffc0203954:	8526                	mv	a0,s1
ffffffffc0203956:	ba1ff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
        assert(vma5 == NULL);
ffffffffc020395a:	18051163          	bnez	a0,ffffffffc0203adc <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020395e:	00893783          	ld	a5,8(s2)
ffffffffc0203962:	0a879d63          	bne	a5,s0,ffffffffc0203a1c <vmm_init+0x204>
ffffffffc0203966:	01093783          	ld	a5,16(s2)
ffffffffc020396a:	0b479963          	bne	a5,s4,ffffffffc0203a1c <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020396e:	0089b783          	ld	a5,8(s3)
ffffffffc0203972:	0c879563          	bne	a5,s0,ffffffffc0203a3c <vmm_init+0x224>
ffffffffc0203976:	0109b783          	ld	a5,16(s3)
ffffffffc020397a:	0d479163          	bne	a5,s4,ffffffffc0203a3c <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc020397e:	0415                	addi	s0,s0,5
ffffffffc0203980:	0a15                	addi	s4,s4,5
ffffffffc0203982:	f9541be3          	bne	s0,s5,ffffffffc0203918 <vmm_init+0x100>
ffffffffc0203986:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203988:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc020398a:	85a2                	mv	a1,s0
ffffffffc020398c:	8526                	mv	a0,s1
ffffffffc020398e:	b69ff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
ffffffffc0203992:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203996:	c90d                	beqz	a0,ffffffffc02039c8 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203998:	6914                	ld	a3,16(a0)
ffffffffc020399a:	6510                	ld	a2,8(a0)
ffffffffc020399c:	00003517          	auipc	a0,0x3
ffffffffc02039a0:	48c50513          	addi	a0,a0,1164 # ffffffffc0206e28 <default_pmm_manager+0x970>
ffffffffc02039a4:	ff4fc0ef          	jal	ra,ffffffffc0200198 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02039a8:	00003697          	auipc	a3,0x3
ffffffffc02039ac:	4a868693          	addi	a3,a3,1192 # ffffffffc0206e50 <default_pmm_manager+0x998>
ffffffffc02039b0:	00002617          	auipc	a2,0x2
ffffffffc02039b4:	75860613          	addi	a2,a2,1880 # ffffffffc0206108 <commands+0x818>
ffffffffc02039b8:	15900593          	li	a1,345
ffffffffc02039bc:	00003517          	auipc	a0,0x3
ffffffffc02039c0:	29450513          	addi	a0,a0,660 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc02039c4:	acffc0ef          	jal	ra,ffffffffc0200492 <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc02039c8:	147d                	addi	s0,s0,-1
ffffffffc02039ca:	fd2410e3          	bne	s0,s2,ffffffffc020398a <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc02039ce:	8526                	mv	a0,s1
ffffffffc02039d0:	c37ff0ef          	jal	ra,ffffffffc0203606 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02039d4:	00003517          	auipc	a0,0x3
ffffffffc02039d8:	49450513          	addi	a0,a0,1172 # ffffffffc0206e68 <default_pmm_manager+0x9b0>
ffffffffc02039dc:	fbcfc0ef          	jal	ra,ffffffffc0200198 <cprintf>
}
ffffffffc02039e0:	7442                	ld	s0,48(sp)
ffffffffc02039e2:	70e2                	ld	ra,56(sp)
ffffffffc02039e4:	74a2                	ld	s1,40(sp)
ffffffffc02039e6:	7902                	ld	s2,32(sp)
ffffffffc02039e8:	69e2                	ld	s3,24(sp)
ffffffffc02039ea:	6a42                	ld	s4,16(sp)
ffffffffc02039ec:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02039ee:	00003517          	auipc	a0,0x3
ffffffffc02039f2:	49a50513          	addi	a0,a0,1178 # ffffffffc0206e88 <default_pmm_manager+0x9d0>
}
ffffffffc02039f6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02039f8:	fa0fc06f          	j	ffffffffc0200198 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02039fc:	00003697          	auipc	a3,0x3
ffffffffc0203a00:	34468693          	addi	a3,a3,836 # ffffffffc0206d40 <default_pmm_manager+0x888>
ffffffffc0203a04:	00002617          	auipc	a2,0x2
ffffffffc0203a08:	70460613          	addi	a2,a2,1796 # ffffffffc0206108 <commands+0x818>
ffffffffc0203a0c:	13d00593          	li	a1,317
ffffffffc0203a10:	00003517          	auipc	a0,0x3
ffffffffc0203a14:	24050513          	addi	a0,a0,576 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203a18:	a7bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203a1c:	00003697          	auipc	a3,0x3
ffffffffc0203a20:	3ac68693          	addi	a3,a3,940 # ffffffffc0206dc8 <default_pmm_manager+0x910>
ffffffffc0203a24:	00002617          	auipc	a2,0x2
ffffffffc0203a28:	6e460613          	addi	a2,a2,1764 # ffffffffc0206108 <commands+0x818>
ffffffffc0203a2c:	14e00593          	li	a1,334
ffffffffc0203a30:	00003517          	auipc	a0,0x3
ffffffffc0203a34:	22050513          	addi	a0,a0,544 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203a38:	a5bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203a3c:	00003697          	auipc	a3,0x3
ffffffffc0203a40:	3bc68693          	addi	a3,a3,956 # ffffffffc0206df8 <default_pmm_manager+0x940>
ffffffffc0203a44:	00002617          	auipc	a2,0x2
ffffffffc0203a48:	6c460613          	addi	a2,a2,1732 # ffffffffc0206108 <commands+0x818>
ffffffffc0203a4c:	14f00593          	li	a1,335
ffffffffc0203a50:	00003517          	auipc	a0,0x3
ffffffffc0203a54:	20050513          	addi	a0,a0,512 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203a58:	a3bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203a5c:	00003697          	auipc	a3,0x3
ffffffffc0203a60:	2cc68693          	addi	a3,a3,716 # ffffffffc0206d28 <default_pmm_manager+0x870>
ffffffffc0203a64:	00002617          	auipc	a2,0x2
ffffffffc0203a68:	6a460613          	addi	a2,a2,1700 # ffffffffc0206108 <commands+0x818>
ffffffffc0203a6c:	13b00593          	li	a1,315
ffffffffc0203a70:	00003517          	auipc	a0,0x3
ffffffffc0203a74:	1e050513          	addi	a0,a0,480 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203a78:	a1bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma2 != NULL);
ffffffffc0203a7c:	00003697          	auipc	a3,0x3
ffffffffc0203a80:	30c68693          	addi	a3,a3,780 # ffffffffc0206d88 <default_pmm_manager+0x8d0>
ffffffffc0203a84:	00002617          	auipc	a2,0x2
ffffffffc0203a88:	68460613          	addi	a2,a2,1668 # ffffffffc0206108 <commands+0x818>
ffffffffc0203a8c:	14600593          	li	a1,326
ffffffffc0203a90:	00003517          	auipc	a0,0x3
ffffffffc0203a94:	1c050513          	addi	a0,a0,448 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203a98:	9fbfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma1 != NULL);
ffffffffc0203a9c:	00003697          	auipc	a3,0x3
ffffffffc0203aa0:	2dc68693          	addi	a3,a3,732 # ffffffffc0206d78 <default_pmm_manager+0x8c0>
ffffffffc0203aa4:	00002617          	auipc	a2,0x2
ffffffffc0203aa8:	66460613          	addi	a2,a2,1636 # ffffffffc0206108 <commands+0x818>
ffffffffc0203aac:	14400593          	li	a1,324
ffffffffc0203ab0:	00003517          	auipc	a0,0x3
ffffffffc0203ab4:	1a050513          	addi	a0,a0,416 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203ab8:	9dbfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma3 == NULL);
ffffffffc0203abc:	00003697          	auipc	a3,0x3
ffffffffc0203ac0:	2dc68693          	addi	a3,a3,732 # ffffffffc0206d98 <default_pmm_manager+0x8e0>
ffffffffc0203ac4:	00002617          	auipc	a2,0x2
ffffffffc0203ac8:	64460613          	addi	a2,a2,1604 # ffffffffc0206108 <commands+0x818>
ffffffffc0203acc:	14800593          	li	a1,328
ffffffffc0203ad0:	00003517          	auipc	a0,0x3
ffffffffc0203ad4:	18050513          	addi	a0,a0,384 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203ad8:	9bbfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma5 == NULL);
ffffffffc0203adc:	00003697          	auipc	a3,0x3
ffffffffc0203ae0:	2dc68693          	addi	a3,a3,732 # ffffffffc0206db8 <default_pmm_manager+0x900>
ffffffffc0203ae4:	00002617          	auipc	a2,0x2
ffffffffc0203ae8:	62460613          	addi	a2,a2,1572 # ffffffffc0206108 <commands+0x818>
ffffffffc0203aec:	14c00593          	li	a1,332
ffffffffc0203af0:	00003517          	auipc	a0,0x3
ffffffffc0203af4:	16050513          	addi	a0,a0,352 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203af8:	99bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        assert(vma4 == NULL);
ffffffffc0203afc:	00003697          	auipc	a3,0x3
ffffffffc0203b00:	2ac68693          	addi	a3,a3,684 # ffffffffc0206da8 <default_pmm_manager+0x8f0>
ffffffffc0203b04:	00002617          	auipc	a2,0x2
ffffffffc0203b08:	60460613          	addi	a2,a2,1540 # ffffffffc0206108 <commands+0x818>
ffffffffc0203b0c:	14a00593          	li	a1,330
ffffffffc0203b10:	00003517          	auipc	a0,0x3
ffffffffc0203b14:	14050513          	addi	a0,a0,320 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203b18:	97bfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(mm != NULL);
ffffffffc0203b1c:	00003697          	auipc	a3,0x3
ffffffffc0203b20:	1bc68693          	addi	a3,a3,444 # ffffffffc0206cd8 <default_pmm_manager+0x820>
ffffffffc0203b24:	00002617          	auipc	a2,0x2
ffffffffc0203b28:	5e460613          	addi	a2,a2,1508 # ffffffffc0206108 <commands+0x818>
ffffffffc0203b2c:	12400593          	li	a1,292
ffffffffc0203b30:	00003517          	auipc	a0,0x3
ffffffffc0203b34:	12050513          	addi	a0,a0,288 # ffffffffc0206c50 <default_pmm_manager+0x798>
ffffffffc0203b38:	95bfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203b3c <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203b3c:	7179                	addi	sp,sp,-48
ffffffffc0203b3e:	f022                	sd	s0,32(sp)
ffffffffc0203b40:	f406                	sd	ra,40(sp)
ffffffffc0203b42:	ec26                	sd	s1,24(sp)
ffffffffc0203b44:	e84a                	sd	s2,16(sp)
ffffffffc0203b46:	e44e                	sd	s3,8(sp)
ffffffffc0203b48:	e052                	sd	s4,0(sp)
ffffffffc0203b4a:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203b4c:	c135                	beqz	a0,ffffffffc0203bb0 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203b4e:	002007b7          	lui	a5,0x200
ffffffffc0203b52:	04f5e663          	bltu	a1,a5,ffffffffc0203b9e <user_mem_check+0x62>
ffffffffc0203b56:	00c584b3          	add	s1,a1,a2
ffffffffc0203b5a:	0495f263          	bgeu	a1,s1,ffffffffc0203b9e <user_mem_check+0x62>
ffffffffc0203b5e:	4785                	li	a5,1
ffffffffc0203b60:	07fe                	slli	a5,a5,0x1f
ffffffffc0203b62:	0297ee63          	bltu	a5,s1,ffffffffc0203b9e <user_mem_check+0x62>
ffffffffc0203b66:	892a                	mv	s2,a0
ffffffffc0203b68:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203b6a:	6a05                	lui	s4,0x1
ffffffffc0203b6c:	a821                	j	ffffffffc0203b84 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203b6e:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203b72:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203b74:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203b76:	c685                	beqz	a3,ffffffffc0203b9e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203b78:	c399                	beqz	a5,ffffffffc0203b7e <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203b7a:	02e46263          	bltu	s0,a4,ffffffffc0203b9e <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203b7e:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203b80:	04947663          	bgeu	s0,s1,ffffffffc0203bcc <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203b84:	85a2                	mv	a1,s0
ffffffffc0203b86:	854a                	mv	a0,s2
ffffffffc0203b88:	96fff0ef          	jal	ra,ffffffffc02034f6 <find_vma>
ffffffffc0203b8c:	c909                	beqz	a0,ffffffffc0203b9e <user_mem_check+0x62>
ffffffffc0203b8e:	6518                	ld	a4,8(a0)
ffffffffc0203b90:	00e46763          	bltu	s0,a4,ffffffffc0203b9e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203b94:	4d1c                	lw	a5,24(a0)
ffffffffc0203b96:	fc099ce3          	bnez	s3,ffffffffc0203b6e <user_mem_check+0x32>
ffffffffc0203b9a:	8b85                	andi	a5,a5,1
ffffffffc0203b9c:	f3ed                	bnez	a5,ffffffffc0203b7e <user_mem_check+0x42>
            return 0;
ffffffffc0203b9e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203ba0:	70a2                	ld	ra,40(sp)
ffffffffc0203ba2:	7402                	ld	s0,32(sp)
ffffffffc0203ba4:	64e2                	ld	s1,24(sp)
ffffffffc0203ba6:	6942                	ld	s2,16(sp)
ffffffffc0203ba8:	69a2                	ld	s3,8(sp)
ffffffffc0203baa:	6a02                	ld	s4,0(sp)
ffffffffc0203bac:	6145                	addi	sp,sp,48
ffffffffc0203bae:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203bb0:	c02007b7          	lui	a5,0xc0200
ffffffffc0203bb4:	4501                	li	a0,0
ffffffffc0203bb6:	fef5e5e3          	bltu	a1,a5,ffffffffc0203ba0 <user_mem_check+0x64>
ffffffffc0203bba:	962e                	add	a2,a2,a1
ffffffffc0203bbc:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203ba0 <user_mem_check+0x64>
ffffffffc0203bc0:	c8000537          	lui	a0,0xc8000
ffffffffc0203bc4:	0505                	addi	a0,a0,1
ffffffffc0203bc6:	00a63533          	sltu	a0,a2,a0
ffffffffc0203bca:	bfd9                	j	ffffffffc0203ba0 <user_mem_check+0x64>
        return 1;
ffffffffc0203bcc:	4505                	li	a0,1
ffffffffc0203bce:	bfc9                	j	ffffffffc0203ba0 <user_mem_check+0x64>

ffffffffc0203bd0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203bd0:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203bd2:	9402                	jalr	s0

	jal do_exit
ffffffffc0203bd4:	606000ef          	jal	ra,ffffffffc02041da <do_exit>

ffffffffc0203bd8 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203bd8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203bda:	14800513          	li	a0,328
{
ffffffffc0203bde:	e022                	sd	s0,0(sp)
ffffffffc0203be0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203be2:	f85fd0ef          	jal	ra,ffffffffc0201b66 <kmalloc>
ffffffffc0203be6:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203be8:	cd35                	beqz	a0,ffffffffc0203c64 <alloc_proc+0x8c>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state=PROC_UNINIT;
ffffffffc0203bea:	57fd                	li	a5,-1
ffffffffc0203bec:	1782                	slli	a5,a5,0x20
ffffffffc0203bee:	e11c                	sd	a5,0(a0)
        proc->runs=0;
        proc->kstack=0;
        proc->need_resched=0;
        proc->parent=NULL;
        proc->mm=NULL;
        memset(&(proc->context),0,sizeof(struct context));
ffffffffc0203bf0:	07000613          	li	a2,112
ffffffffc0203bf4:	4581                	li	a1,0
        proc->runs=0;
ffffffffc0203bf6:	00052423          	sw	zero,8(a0) # ffffffffc8000008 <end+0x7d3a280>
        proc->kstack=0;
ffffffffc0203bfa:	00053823          	sd	zero,16(a0)
        proc->need_resched=0;
ffffffffc0203bfe:	00053c23          	sd	zero,24(a0)
        proc->parent=NULL;
ffffffffc0203c02:	02053023          	sd	zero,32(a0)
        proc->mm=NULL;
ffffffffc0203c06:	02053423          	sd	zero,40(a0)
        memset(&(proc->context),0,sizeof(struct context));
ffffffffc0203c0a:	03050513          	addi	a0,a0,48
ffffffffc0203c0e:	24b010ef          	jal	ra,ffffffffc0205658 <memset>
        proc->tf=NULL;
        proc->pgdir=boot_pgdir_pa;
ffffffffc0203c12:	000c2797          	auipc	a5,0xc2
ffffffffc0203c16:	1167b783          	ld	a5,278(a5) # ffffffffc02c5d28 <boot_pgdir_pa>
ffffffffc0203c1a:	f45c                	sd	a5,168(s0)
        proc->tf=NULL;
ffffffffc0203c1c:	0a043023          	sd	zero,160(s0)
        proc->flags=0;
ffffffffc0203c20:	0a042823          	sw	zero,176(s0)
        memset(proc->name,0,PROC_NAME_LEN+1);
ffffffffc0203c24:	4641                	li	a2,16
ffffffffc0203c26:	4581                	li	a1,0
ffffffffc0203c28:	0b440513          	addi	a0,s0,180
ffffffffc0203c2c:	22d010ef          	jal	ra,ffffffffc0205658 <memset>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */
        proc->rq = NULL;                        // 初始时进程未加入任何运行队列
        list_init(&(proc->run_link));           // 初始化运行队列链表节点
ffffffffc0203c30:	11040793          	addi	a5,s0,272
        proc->wait_state = 0;//初始化为非等待状态
ffffffffc0203c34:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;//暂无子进程，弟弟进程，哥哥进程
ffffffffc0203c38:	10043023          	sd	zero,256(s0)
ffffffffc0203c3c:	0e043c23          	sd	zero,248(s0)
ffffffffc0203c40:	0e043823          	sd	zero,240(s0)
        proc->rq = NULL;                        // 初始时进程未加入任何运行队列
ffffffffc0203c44:	10043423          	sd	zero,264(s0)
    elm->prev = elm->next = elm;
ffffffffc0203c48:	10f43c23          	sd	a5,280(s0)
ffffffffc0203c4c:	10f43823          	sd	a5,272(s0)
        proc->time_slice = 0;                   // 初始时间片为0，加入队列时会被设置
ffffffffc0203c50:	12042023          	sw	zero,288(s0)
        proc->lab6_run_pool.left = proc->lab6_run_pool.right = proc->lab6_run_pool.parent = NULL;  // 初始化斜堆节点
ffffffffc0203c54:	12043423          	sd	zero,296(s0)
ffffffffc0203c58:	12043823          	sd	zero,304(s0)
ffffffffc0203c5c:	12043c23          	sd	zero,312(s0)
        proc->lab6_stride = 0;                  // 初始stride值为0
ffffffffc0203c60:	14043023          	sd	zero,320(s0)
        proc->lab6_priority = 0;                // 初始优先级为0

    }
    return proc;
}
ffffffffc0203c64:	60a2                	ld	ra,8(sp)
ffffffffc0203c66:	8522                	mv	a0,s0
ffffffffc0203c68:	6402                	ld	s0,0(sp)
ffffffffc0203c6a:	0141                	addi	sp,sp,16
ffffffffc0203c6c:	8082                	ret

ffffffffc0203c6e <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203c6e:	000c2797          	auipc	a5,0xc2
ffffffffc0203c72:	0ea7b783          	ld	a5,234(a5) # ffffffffc02c5d58 <current>
ffffffffc0203c76:	73c8                	ld	a0,160(a5)
ffffffffc0203c78:	a0afd06f          	j	ffffffffc0200e82 <forkrets>

ffffffffc0203c7c <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203c7c:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203c7e:	1141                	addi	sp,sp,-16
ffffffffc0203c80:	e406                	sd	ra,8(sp)
ffffffffc0203c82:	c02007b7          	lui	a5,0xc0200
ffffffffc0203c86:	02f6ee63          	bltu	a3,a5,ffffffffc0203cc2 <put_pgdir+0x46>
ffffffffc0203c8a:	000c2517          	auipc	a0,0xc2
ffffffffc0203c8e:	0c653503          	ld	a0,198(a0) # ffffffffc02c5d50 <va_pa_offset>
ffffffffc0203c92:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc0203c94:	82b1                	srli	a3,a3,0xc
ffffffffc0203c96:	000c2797          	auipc	a5,0xc2
ffffffffc0203c9a:	0a27b783          	ld	a5,162(a5) # ffffffffc02c5d38 <npage>
ffffffffc0203c9e:	02f6fe63          	bgeu	a3,a5,ffffffffc0203cda <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ca2:	00004517          	auipc	a0,0x4
ffffffffc0203ca6:	25e53503          	ld	a0,606(a0) # ffffffffc0207f00 <nbase>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203caa:	60a2                	ld	ra,8(sp)
ffffffffc0203cac:	8e89                	sub	a3,a3,a0
ffffffffc0203cae:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203cb0:	000c2517          	auipc	a0,0xc2
ffffffffc0203cb4:	09053503          	ld	a0,144(a0) # ffffffffc02c5d40 <pages>
ffffffffc0203cb8:	4585                	li	a1,1
ffffffffc0203cba:	9536                	add	a0,a0,a3
}
ffffffffc0203cbc:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203cbe:	8c4fe06f          	j	ffffffffc0201d82 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203cc2:	00003617          	auipc	a2,0x3
ffffffffc0203cc6:	8d660613          	addi	a2,a2,-1834 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc0203cca:	07700593          	li	a1,119
ffffffffc0203cce:	00003517          	auipc	a0,0x3
ffffffffc0203cd2:	84a50513          	addi	a0,a0,-1974 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0203cd6:	fbcfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203cda:	00003617          	auipc	a2,0x3
ffffffffc0203cde:	8e660613          	addi	a2,a2,-1818 # ffffffffc02065c0 <default_pmm_manager+0x108>
ffffffffc0203ce2:	06900593          	li	a1,105
ffffffffc0203ce6:	00003517          	auipc	a0,0x3
ffffffffc0203cea:	83250513          	addi	a0,a0,-1998 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0203cee:	fa4fc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0203cf2 <proc_run>:
{
ffffffffc0203cf2:	7179                	addi	sp,sp,-48
ffffffffc0203cf4:	ec26                	sd	s1,24(sp)
    if (proc != current)
ffffffffc0203cf6:	000c2497          	auipc	s1,0xc2
ffffffffc0203cfa:	06248493          	addi	s1,s1,98 # ffffffffc02c5d58 <current>
ffffffffc0203cfe:	609c                	ld	a5,0(s1)
{
ffffffffc0203d00:	f406                	sd	ra,40(sp)
ffffffffc0203d02:	f022                	sd	s0,32(sp)
ffffffffc0203d04:	e84a                	sd	s2,16(sp)
    if (proc != current)
ffffffffc0203d06:	02a78b63          	beq	a5,a0,ffffffffc0203d3c <proc_run+0x4a>
ffffffffc0203d0a:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203d0c:	10002773          	csrr	a4,sstatus
ffffffffc0203d10:	8b09                	andi	a4,a4,2
        switch_to(&(prev->context),&(next->context));
ffffffffc0203d12:	03050593          	addi	a1,a0,48
ffffffffc0203d16:	eb39                	bnez	a4,ffffffffc0203d6c <proc_run+0x7a>
        if(next->pgdir!=prev->pgdir){
ffffffffc0203d18:	7558                	ld	a4,168(a0)
ffffffffc0203d1a:	77d4                	ld	a3,168(a5)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203d1c:	03078513          	addi	a0,a5,48
    return 0;
ffffffffc0203d20:	4901                	li	s2,0
        if(next->pgdir!=prev->pgdir){
ffffffffc0203d22:	02d70d63          	beq	a4,a3,ffffffffc0203d5c <proc_run+0x6a>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203d26:	57fd                	li	a5,-1
ffffffffc0203d28:	17fe                	slli	a5,a5,0x3f
ffffffffc0203d2a:	8361                	srli	a4,a4,0x18
ffffffffc0203d2c:	8f5d                	or	a4,a4,a5
ffffffffc0203d2e:	18071073          	csrw	satp,a4
        current=next; //切换current指针
ffffffffc0203d32:	e080                	sd	s0,0(s1)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203d34:	146010ef          	jal	ra,ffffffffc0204e7a <switch_to>
    if (flag)
ffffffffc0203d38:	00091b63          	bnez	s2,ffffffffc0203d4e <proc_run+0x5c>
}
ffffffffc0203d3c:	70a2                	ld	ra,40(sp)
ffffffffc0203d3e:	7402                	ld	s0,32(sp)
ffffffffc0203d40:	64e2                	ld	s1,24(sp)
ffffffffc0203d42:	6942                	ld	s2,16(sp)
ffffffffc0203d44:	6145                	addi	sp,sp,48
ffffffffc0203d46:	8082                	ret
        current=next; //切换current指针
ffffffffc0203d48:	e080                	sd	s0,0(s1)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203d4a:	130010ef          	jal	ra,ffffffffc0204e7a <switch_to>
}
ffffffffc0203d4e:	7402                	ld	s0,32(sp)
ffffffffc0203d50:	70a2                	ld	ra,40(sp)
ffffffffc0203d52:	64e2                	ld	s1,24(sp)
ffffffffc0203d54:	6942                	ld	s2,16(sp)
ffffffffc0203d56:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203d58:	c39fc06f          	j	ffffffffc0200990 <intr_enable>
        current=next; //切换current指针
ffffffffc0203d5c:	e080                	sd	s0,0(s1)
}
ffffffffc0203d5e:	7402                	ld	s0,32(sp)
ffffffffc0203d60:	70a2                	ld	ra,40(sp)
ffffffffc0203d62:	64e2                	ld	s1,24(sp)
ffffffffc0203d64:	6942                	ld	s2,16(sp)
ffffffffc0203d66:	6145                	addi	sp,sp,48
        switch_to(&(prev->context),&(next->context));
ffffffffc0203d68:	1120106f          	j	ffffffffc0204e7a <switch_to>
ffffffffc0203d6c:	e42e                	sd	a1,8(sp)
        intr_disable();
ffffffffc0203d6e:	c29fc0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        struct proc_struct *prev=current; //记录之前的进程
ffffffffc0203d72:	6088                	ld	a0,0(s1)
        if(next->pgdir!=prev->pgdir){
ffffffffc0203d74:	7458                	ld	a4,168(s0)
ffffffffc0203d76:	65a2                	ld	a1,8(sp)
ffffffffc0203d78:	755c                	ld	a5,168(a0)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203d7a:	03050513          	addi	a0,a0,48
        if(next->pgdir!=prev->pgdir){
ffffffffc0203d7e:	fcf705e3          	beq	a4,a5,ffffffffc0203d48 <proc_run+0x56>
        return 1;
ffffffffc0203d82:	4905                	li	s2,1
ffffffffc0203d84:	b74d                	j	ffffffffc0203d26 <proc_run+0x34>

ffffffffc0203d86 <do_fork>:
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
ffffffffc0203d86:	7119                	addi	sp,sp,-128
ffffffffc0203d88:	f0ca                	sd	s2,96(sp)
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc0203d8a:	000c2917          	auipc	s2,0xc2
ffffffffc0203d8e:	fe690913          	addi	s2,s2,-26 # ffffffffc02c5d70 <nr_process>
ffffffffc0203d92:	00092703          	lw	a4,0(s2)
{
ffffffffc0203d96:	fc86                	sd	ra,120(sp)
ffffffffc0203d98:	f8a2                	sd	s0,112(sp)
ffffffffc0203d9a:	f4a6                	sd	s1,104(sp)
ffffffffc0203d9c:	ecce                	sd	s3,88(sp)
ffffffffc0203d9e:	e8d2                	sd	s4,80(sp)
ffffffffc0203da0:	e4d6                	sd	s5,72(sp)
ffffffffc0203da2:	e0da                	sd	s6,64(sp)
ffffffffc0203da4:	fc5e                	sd	s7,56(sp)
ffffffffc0203da6:	f862                	sd	s8,48(sp)
ffffffffc0203da8:	f466                	sd	s9,40(sp)
ffffffffc0203daa:	f06a                	sd	s10,32(sp)
ffffffffc0203dac:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203dae:	6785                	lui	a5,0x1
ffffffffc0203db0:	32f75b63          	bge	a4,a5,ffffffffc02040e6 <do_fork+0x360>
ffffffffc0203db4:	8a2a                	mv	s4,a0
ffffffffc0203db6:	89ae                	mv	s3,a1
ffffffffc0203db8:	8432                	mv	s0,a2
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    proc = alloc_proc();
ffffffffc0203dba:	e1fff0ef          	jal	ra,ffffffffc0203bd8 <alloc_proc>
ffffffffc0203dbe:	84aa                	mv	s1,a0
    if (proc == NULL) {
ffffffffc0203dc0:	30050863          	beqz	a0,ffffffffc02040d0 <do_fork+0x34a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203dc4:	4509                	li	a0,2
ffffffffc0203dc6:	f7ffd0ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
    if (page != NULL)
ffffffffc0203dca:	30050063          	beqz	a0,ffffffffc02040ca <do_fork+0x344>
    return page - pages + nbase;
ffffffffc0203dce:	000c2a97          	auipc	s5,0xc2
ffffffffc0203dd2:	f72a8a93          	addi	s5,s5,-142 # ffffffffc02c5d40 <pages>
ffffffffc0203dd6:	000ab683          	ld	a3,0(s5)
ffffffffc0203dda:	00004797          	auipc	a5,0x4
ffffffffc0203dde:	12678793          	addi	a5,a5,294 # ffffffffc0207f00 <nbase>
ffffffffc0203de2:	6398                	ld	a4,0(a5)
ffffffffc0203de4:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0203de8:	000c2b97          	auipc	s7,0xc2
ffffffffc0203dec:	f50b8b93          	addi	s7,s7,-176 # ffffffffc02c5d38 <npage>
    return page - pages + nbase;
ffffffffc0203df0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203df2:	57fd                	li	a5,-1
ffffffffc0203df4:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc0203df8:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203dfa:	00c7db13          	srli	s6,a5,0xc
ffffffffc0203dfe:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203e02:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203e04:	34c5fb63          	bgeu	a1,a2,ffffffffc020415a <do_fork+0x3d4>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0203e08:	000c2c97          	auipc	s9,0xc2
ffffffffc0203e0c:	f50c8c93          	addi	s9,s9,-176 # ffffffffc02c5d58 <current>
ffffffffc0203e10:	000cb303          	ld	t1,0(s9)
ffffffffc0203e14:	000c2c17          	auipc	s8,0xc2
ffffffffc0203e18:	f3cc0c13          	addi	s8,s8,-196 # ffffffffc02c5d50 <va_pa_offset>
ffffffffc0203e1c:	000c3603          	ld	a2,0(s8)
ffffffffc0203e20:	02833d83          	ld	s11,40(t1) # 80028 <_binary_obj___user_matrix_out_size+0x73900>
ffffffffc0203e24:	e43a                	sd	a4,8(sp)
ffffffffc0203e26:	96b2                	add	a3,a3,a2
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203e28:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0203e2a:	020d8a63          	beqz	s11,ffffffffc0203e5e <do_fork+0xd8>
    if (clone_flags & CLONE_VM)
ffffffffc0203e2e:	100a7a13          	andi	s4,s4,256
ffffffffc0203e32:	1a0a0863          	beqz	s4,ffffffffc0203fe2 <do_fork+0x25c>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0203e36:	030da703          	lw	a4,48(s11)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203e3a:	018db783          	ld	a5,24(s11)
ffffffffc0203e3e:	c02006b7          	lui	a3,0xc0200
ffffffffc0203e42:	2705                	addiw	a4,a4,1
ffffffffc0203e44:	02eda823          	sw	a4,48(s11)
    proc->mm = mm;
ffffffffc0203e48:	03b4b423          	sd	s11,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203e4c:	2cd7e263          	bltu	a5,a3,ffffffffc0204110 <do_fork+0x38a>
ffffffffc0203e50:	000c3703          	ld	a4,0(s8)
     *    -------------------
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */
    /* LAB5 update step1: set parent and clear parent's wait_state */
    proc->parent = current;
ffffffffc0203e54:	000cb303          	ld	t1,0(s9)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203e58:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0203e5a:	8f99                	sub	a5,a5,a4
ffffffffc0203e5c:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203e5e:	6789                	lui	a5,0x2
ffffffffc0203e60:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8070>
ffffffffc0203e64:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0203e66:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0203e68:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc0203e6a:	87b6                	mv	a5,a3
ffffffffc0203e6c:	12040893          	addi	a7,s0,288
ffffffffc0203e70:	00063803          	ld	a6,0(a2)
ffffffffc0203e74:	6608                	ld	a0,8(a2)
ffffffffc0203e76:	6a0c                	ld	a1,16(a2)
ffffffffc0203e78:	6e18                	ld	a4,24(a2)
ffffffffc0203e7a:	0107b023          	sd	a6,0(a5)
ffffffffc0203e7e:	e788                	sd	a0,8(a5)
ffffffffc0203e80:	eb8c                	sd	a1,16(a5)
ffffffffc0203e82:	ef98                	sd	a4,24(a5)
ffffffffc0203e84:	02060613          	addi	a2,a2,32
ffffffffc0203e88:	02078793          	addi	a5,a5,32
ffffffffc0203e8c:	ff1612e3          	bne	a2,a7,ffffffffc0203e70 <do_fork+0xea>
    proc->tf->gpr.a0 = 0;
ffffffffc0203e90:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203e94:	14098563          	beqz	s3,ffffffffc0203fde <do_fork+0x258>
    assert(current->wait_state == 0);
ffffffffc0203e98:	0ec32783          	lw	a5,236(t1)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203e9c:	00000717          	auipc	a4,0x0
ffffffffc0203ea0:	dd270713          	addi	a4,a4,-558 # ffffffffc0203c6e <forkret>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203ea4:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203ea8:	f898                	sd	a4,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203eaa:	fc94                	sd	a3,56(s1)
    proc->parent = current;
ffffffffc0203eac:	0264b023          	sd	t1,32(s1)
    assert(current->wait_state == 0);
ffffffffc0203eb0:	24079063          	bnez	a5,ffffffffc02040f0 <do_fork+0x36a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203eb4:	100027f3          	csrr	a5,sstatus
ffffffffc0203eb8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203eba:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203ebc:	20079c63          	bnez	a5,ffffffffc02040d4 <do_fork+0x34e>
    if (++last_pid >= MAX_PID)
ffffffffc0203ec0:	000be817          	auipc	a6,0xbe
ffffffffc0203ec4:	9e080813          	addi	a6,a6,-1568 # ffffffffc02c18a0 <last_pid.1>
ffffffffc0203ec8:	00082783          	lw	a5,0(a6)
ffffffffc0203ecc:	6709                	lui	a4,0x2
ffffffffc0203ece:	0017851b          	addiw	a0,a5,1
ffffffffc0203ed2:	00a82023          	sw	a0,0(a6)
ffffffffc0203ed6:	08e55d63          	bge	a0,a4,ffffffffc0203f70 <do_fork+0x1ea>
    if (last_pid >= next_safe)
ffffffffc0203eda:	000be317          	auipc	t1,0xbe
ffffffffc0203ede:	9ca30313          	addi	t1,t1,-1590 # ffffffffc02c18a4 <next_safe.0>
ffffffffc0203ee2:	00032783          	lw	a5,0(t1)
ffffffffc0203ee6:	000c2417          	auipc	s0,0xc2
ffffffffc0203eea:	dda40413          	addi	s0,s0,-550 # ffffffffc02c5cc0 <proc_list>
ffffffffc0203eee:	08f55963          	bge	a0,a5,ffffffffc0203f80 <do_fork+0x1fa>

    // LAB5: Step 5 - use set_links to handle process list and relations
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
ffffffffc0203ef2:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203ef4:	45a9                	li	a1,10
ffffffffc0203ef6:	2501                	sext.w	a0,a0
ffffffffc0203ef8:	2ba010ef          	jal	ra,ffffffffc02051b2 <hash32>
ffffffffc0203efc:	02051793          	slli	a5,a0,0x20
ffffffffc0203f00:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203f04:	000be797          	auipc	a5,0xbe
ffffffffc0203f08:	dbc78793          	addi	a5,a5,-580 # ffffffffc02c1cc0 <hash_list>
ffffffffc0203f0c:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0203f0e:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203f10:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203f12:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0203f16:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0203f18:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0203f1a:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203f1c:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0203f1e:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0203f22:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0203f24:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0203f26:	e21c                	sd	a5,0(a2)
ffffffffc0203f28:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0203f2a:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0203f2c:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0203f2e:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0203f32:	10e4b023          	sd	a4,256(s1)
ffffffffc0203f36:	c311                	beqz	a4,ffffffffc0203f3a <do_fork+0x1b4>
        proc->optr->yptr = proc;
ffffffffc0203f38:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0203f3a:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0203f3e:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc0203f40:	2785                	addiw	a5,a5,1
ffffffffc0203f42:	00f92023          	sw	a5,0(s2)
    if (flag)
ffffffffc0203f46:	12099c63          	bnez	s3,ffffffffc020407e <do_fork+0x2f8>
        hash_proc(proc);
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    wakeup_proc(proc);
ffffffffc0203f4a:	8526                	mv	a0,s1
ffffffffc0203f4c:	7f5000ef          	jal	ra,ffffffffc0204f40 <wakeup_proc>
    ret = proc->pid;
ffffffffc0203f50:	40c8                	lw	a0,4(s1)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc0203f52:	70e6                	ld	ra,120(sp)
ffffffffc0203f54:	7446                	ld	s0,112(sp)
ffffffffc0203f56:	74a6                	ld	s1,104(sp)
ffffffffc0203f58:	7906                	ld	s2,96(sp)
ffffffffc0203f5a:	69e6                	ld	s3,88(sp)
ffffffffc0203f5c:	6a46                	ld	s4,80(sp)
ffffffffc0203f5e:	6aa6                	ld	s5,72(sp)
ffffffffc0203f60:	6b06                	ld	s6,64(sp)
ffffffffc0203f62:	7be2                	ld	s7,56(sp)
ffffffffc0203f64:	7c42                	ld	s8,48(sp)
ffffffffc0203f66:	7ca2                	ld	s9,40(sp)
ffffffffc0203f68:	7d02                	ld	s10,32(sp)
ffffffffc0203f6a:	6de2                	ld	s11,24(sp)
ffffffffc0203f6c:	6109                	addi	sp,sp,128
ffffffffc0203f6e:	8082                	ret
        last_pid = 1;
ffffffffc0203f70:	4785                	li	a5,1
ffffffffc0203f72:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0203f76:	4505                	li	a0,1
ffffffffc0203f78:	000be317          	auipc	t1,0xbe
ffffffffc0203f7c:	92c30313          	addi	t1,t1,-1748 # ffffffffc02c18a4 <next_safe.0>
    return listelm->next;
ffffffffc0203f80:	000c2417          	auipc	s0,0xc2
ffffffffc0203f84:	d4040413          	addi	s0,s0,-704 # ffffffffc02c5cc0 <proc_list>
ffffffffc0203f88:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0203f8c:	6789                	lui	a5,0x2
ffffffffc0203f8e:	00f32023          	sw	a5,0(t1)
ffffffffc0203f92:	86aa                	mv	a3,a0
ffffffffc0203f94:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0203f96:	6e89                	lui	t4,0x2
ffffffffc0203f98:	148e0263          	beq	t3,s0,ffffffffc02040dc <do_fork+0x356>
ffffffffc0203f9c:	88ae                	mv	a7,a1
ffffffffc0203f9e:	87f2                	mv	a5,t3
ffffffffc0203fa0:	6609                	lui	a2,0x2
ffffffffc0203fa2:	a811                	j	ffffffffc0203fb6 <do_fork+0x230>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203fa4:	00e6d663          	bge	a3,a4,ffffffffc0203fb0 <do_fork+0x22a>
ffffffffc0203fa8:	00c75463          	bge	a4,a2,ffffffffc0203fb0 <do_fork+0x22a>
ffffffffc0203fac:	863a                	mv	a2,a4
ffffffffc0203fae:	4885                	li	a7,1
ffffffffc0203fb0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203fb2:	00878d63          	beq	a5,s0,ffffffffc0203fcc <do_fork+0x246>
            if (proc->pid == last_pid)
ffffffffc0203fb6:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x8014>
ffffffffc0203fba:	fed715e3          	bne	a4,a3,ffffffffc0203fa4 <do_fork+0x21e>
                if (++last_pid >= next_safe)
ffffffffc0203fbe:	2685                	addiw	a3,a3,1
ffffffffc0203fc0:	0cc6d263          	bge	a3,a2,ffffffffc0204084 <do_fork+0x2fe>
ffffffffc0203fc4:	679c                	ld	a5,8(a5)
ffffffffc0203fc6:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0203fc8:	fe8797e3          	bne	a5,s0,ffffffffc0203fb6 <do_fork+0x230>
ffffffffc0203fcc:	c581                	beqz	a1,ffffffffc0203fd4 <do_fork+0x24e>
ffffffffc0203fce:	00d82023          	sw	a3,0(a6)
ffffffffc0203fd2:	8536                	mv	a0,a3
ffffffffc0203fd4:	f0088fe3          	beqz	a7,ffffffffc0203ef2 <do_fork+0x16c>
ffffffffc0203fd8:	00c32023          	sw	a2,0(t1)
ffffffffc0203fdc:	bf19                	j	ffffffffc0203ef2 <do_fork+0x16c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203fde:	89b6                	mv	s3,a3
ffffffffc0203fe0:	bd65                	j	ffffffffc0203e98 <do_fork+0x112>
    if ((mm = mm_create()) == NULL)
ffffffffc0203fe2:	ce4ff0ef          	jal	ra,ffffffffc02034c6 <mm_create>
ffffffffc0203fe6:	8d2a                	mv	s10,a0
ffffffffc0203fe8:	c555                	beqz	a0,ffffffffc0204094 <do_fork+0x30e>
    if ((page = alloc_page()) == NULL)
ffffffffc0203fea:	4505                	li	a0,1
ffffffffc0203fec:	d59fd0ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc0203ff0:	cd59                	beqz	a0,ffffffffc020408e <do_fork+0x308>
    return page - pages + nbase;
ffffffffc0203ff2:	000ab683          	ld	a3,0(s5)
ffffffffc0203ff6:	6722                	ld	a4,8(sp)
    return KADDR(page2pa(page));
ffffffffc0203ff8:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc0203ffc:	40d506b3          	sub	a3,a0,a3
ffffffffc0204000:	8699                	srai	a3,a3,0x6
ffffffffc0204002:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204004:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0204008:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020400a:	14c7f863          	bgeu	a5,a2,ffffffffc020415a <do_fork+0x3d4>
ffffffffc020400e:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204012:	6605                	lui	a2,0x1
ffffffffc0204014:	000c2597          	auipc	a1,0xc2
ffffffffc0204018:	d1c5b583          	ld	a1,-740(a1) # ffffffffc02c5d30 <boot_pgdir_va>
ffffffffc020401c:	9a36                	add	s4,s4,a3
ffffffffc020401e:	8552                	mv	a0,s4
ffffffffc0204020:	64a010ef          	jal	ra,ffffffffc020566a <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204024:	038d8b13          	addi	s6,s11,56
    mm->pgdir = pgdir;
ffffffffc0204028:	014d3c23          	sd	s4,24(s10) # 200018 <_binary_obj___user_matrix_out_size+0x1f38f0>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020402c:	4785                	li	a5,1
ffffffffc020402e:	40fb37af          	amoor.d	a5,a5,(s6)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204032:	8b85                	andi	a5,a5,1
ffffffffc0204034:	4a05                	li	s4,1
ffffffffc0204036:	c799                	beqz	a5,ffffffffc0204044 <do_fork+0x2be>
    {
        schedule();
ffffffffc0204038:	7bb000ef          	jal	ra,ffffffffc0204ff2 <schedule>
ffffffffc020403c:	414b37af          	amoor.d	a5,s4,(s6)
    while (!try_lock(lock))
ffffffffc0204040:	8b85                	andi	a5,a5,1
ffffffffc0204042:	fbfd                	bnez	a5,ffffffffc0204038 <do_fork+0x2b2>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204044:	85ee                	mv	a1,s11
ffffffffc0204046:	856a                	mv	a0,s10
ffffffffc0204048:	ec0ff0ef          	jal	ra,ffffffffc0203708 <dup_mmap>
ffffffffc020404c:	8a2a                	mv	s4,a0
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020404e:	57f9                	li	a5,-2
ffffffffc0204050:	60fb37af          	amoand.d	a5,a5,(s6)
ffffffffc0204054:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204056:	10078e63          	beqz	a5,ffffffffc0204172 <do_fork+0x3ec>
good_mm:
ffffffffc020405a:	8dea                	mv	s11,s10
    if (ret != 0)
ffffffffc020405c:	dc050de3          	beqz	a0,ffffffffc0203e36 <do_fork+0xb0>
    exit_mmap(mm);
ffffffffc0204060:	856a                	mv	a0,s10
ffffffffc0204062:	f40ff0ef          	jal	ra,ffffffffc02037a2 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204066:	856a                	mv	a0,s10
ffffffffc0204068:	c15ff0ef          	jal	ra,ffffffffc0203c7c <put_pgdir>
    mm_destroy(mm);
ffffffffc020406c:	856a                	mv	a0,s10
ffffffffc020406e:	d98ff0ef          	jal	ra,ffffffffc0203606 <mm_destroy>
    if (copy_mm(clone_flags, proc) < 0) {
ffffffffc0204072:	020a4163          	bltz	s4,ffffffffc0204094 <do_fork+0x30e>
    proc->parent = current;
ffffffffc0204076:	000cb303          	ld	t1,0(s9)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020407a:	6894                	ld	a3,16(s1)
ffffffffc020407c:	b3cd                	j	ffffffffc0203e5e <do_fork+0xd8>
        intr_enable();
ffffffffc020407e:	913fc0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0204082:	b5e1                	j	ffffffffc0203f4a <do_fork+0x1c4>
                    if (last_pid >= MAX_PID)
ffffffffc0204084:	01d6c363          	blt	a3,t4,ffffffffc020408a <do_fork+0x304>
                        last_pid = 1;
ffffffffc0204088:	4685                	li	a3,1
                    goto repeat;
ffffffffc020408a:	4585                	li	a1,1
ffffffffc020408c:	b731                	j	ffffffffc0203f98 <do_fork+0x212>
    mm_destroy(mm);
ffffffffc020408e:	856a                	mv	a0,s10
ffffffffc0204090:	d76ff0ef          	jal	ra,ffffffffc0203606 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204094:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0204096:	c02007b7          	lui	a5,0xc0200
ffffffffc020409a:	0af6e463          	bltu	a3,a5,ffffffffc0204142 <do_fork+0x3bc>
ffffffffc020409e:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02040a2:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02040a6:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02040aa:	83b1                	srli	a5,a5,0xc
ffffffffc02040ac:	06e7ff63          	bgeu	a5,a4,ffffffffc020412a <do_fork+0x3a4>
    return &pages[PPN(pa) - nbase];
ffffffffc02040b0:	00004717          	auipc	a4,0x4
ffffffffc02040b4:	e5070713          	addi	a4,a4,-432 # ffffffffc0207f00 <nbase>
ffffffffc02040b8:	6318                	ld	a4,0(a4)
ffffffffc02040ba:	000ab503          	ld	a0,0(s5)
ffffffffc02040be:	4589                	li	a1,2
ffffffffc02040c0:	8f99                	sub	a5,a5,a4
ffffffffc02040c2:	079a                	slli	a5,a5,0x6
ffffffffc02040c4:	953e                	add	a0,a0,a5
ffffffffc02040c6:	cbdfd0ef          	jal	ra,ffffffffc0201d82 <free_pages>
    kfree(proc);
ffffffffc02040ca:	8526                	mv	a0,s1
ffffffffc02040cc:	b4bfd0ef          	jal	ra,ffffffffc0201c16 <kfree>
    ret = -E_NO_MEM;
ffffffffc02040d0:	5571                	li	a0,-4
    return ret;
ffffffffc02040d2:	b541                	j	ffffffffc0203f52 <do_fork+0x1cc>
        intr_disable();
ffffffffc02040d4:	8c3fc0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        return 1;
ffffffffc02040d8:	4985                	li	s3,1
ffffffffc02040da:	b3dd                	j	ffffffffc0203ec0 <do_fork+0x13a>
ffffffffc02040dc:	c599                	beqz	a1,ffffffffc02040ea <do_fork+0x364>
ffffffffc02040de:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02040e2:	8536                	mv	a0,a3
ffffffffc02040e4:	b539                	j	ffffffffc0203ef2 <do_fork+0x16c>
    int ret = -E_NO_FREE_PROC;
ffffffffc02040e6:	556d                	li	a0,-5
ffffffffc02040e8:	b5ad                	j	ffffffffc0203f52 <do_fork+0x1cc>
    return last_pid;
ffffffffc02040ea:	00082503          	lw	a0,0(a6)
ffffffffc02040ee:	b511                	j	ffffffffc0203ef2 <do_fork+0x16c>
    assert(current->wait_state == 0);
ffffffffc02040f0:	00003697          	auipc	a3,0x3
ffffffffc02040f4:	e0068693          	addi	a3,a3,-512 # ffffffffc0206ef0 <default_pmm_manager+0xa38>
ffffffffc02040f8:	00002617          	auipc	a2,0x2
ffffffffc02040fc:	01060613          	addi	a2,a2,16 # ffffffffc0206108 <commands+0x818>
ffffffffc0204100:	20000593          	li	a1,512
ffffffffc0204104:	00003517          	auipc	a0,0x3
ffffffffc0204108:	dd450513          	addi	a0,a0,-556 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc020410c:	b86fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204110:	86be                	mv	a3,a5
ffffffffc0204112:	00002617          	auipc	a2,0x2
ffffffffc0204116:	48660613          	addi	a2,a2,1158 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc020411a:	1a100593          	li	a1,417
ffffffffc020411e:	00003517          	auipc	a0,0x3
ffffffffc0204122:	dba50513          	addi	a0,a0,-582 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204126:	b6cfc0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020412a:	00002617          	auipc	a2,0x2
ffffffffc020412e:	49660613          	addi	a2,a2,1174 # ffffffffc02065c0 <default_pmm_manager+0x108>
ffffffffc0204132:	06900593          	li	a1,105
ffffffffc0204136:	00002517          	auipc	a0,0x2
ffffffffc020413a:	3e250513          	addi	a0,a0,994 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc020413e:	b54fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204142:	00002617          	auipc	a2,0x2
ffffffffc0204146:	45660613          	addi	a2,a2,1110 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc020414a:	07700593          	li	a1,119
ffffffffc020414e:	00002517          	auipc	a0,0x2
ffffffffc0204152:	3ca50513          	addi	a0,a0,970 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0204156:	b3cfc0ef          	jal	ra,ffffffffc0200492 <__panic>
    return KADDR(page2pa(page));
ffffffffc020415a:	00002617          	auipc	a2,0x2
ffffffffc020415e:	39660613          	addi	a2,a2,918 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0204162:	07100593          	li	a1,113
ffffffffc0204166:	00002517          	auipc	a0,0x2
ffffffffc020416a:	3b250513          	addi	a0,a0,946 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc020416e:	b24fc0ef          	jal	ra,ffffffffc0200492 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204172:	00003617          	auipc	a2,0x3
ffffffffc0204176:	d3e60613          	addi	a2,a2,-706 # ffffffffc0206eb0 <default_pmm_manager+0x9f8>
ffffffffc020417a:	04000593          	li	a1,64
ffffffffc020417e:	00003517          	auipc	a0,0x3
ffffffffc0204182:	d4250513          	addi	a0,a0,-702 # ffffffffc0206ec0 <default_pmm_manager+0xa08>
ffffffffc0204186:	b0cfc0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020418a <kernel_thread>:
{
ffffffffc020418a:	7129                	addi	sp,sp,-320
ffffffffc020418c:	fa22                	sd	s0,304(sp)
ffffffffc020418e:	f626                	sd	s1,296(sp)
ffffffffc0204190:	f24a                	sd	s2,288(sp)
ffffffffc0204192:	84ae                	mv	s1,a1
ffffffffc0204194:	892a                	mv	s2,a0
ffffffffc0204196:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204198:	4581                	li	a1,0
ffffffffc020419a:	12000613          	li	a2,288
ffffffffc020419e:	850a                	mv	a0,sp
{
ffffffffc02041a0:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02041a2:	4b6010ef          	jal	ra,ffffffffc0205658 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02041a6:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02041a8:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02041aa:	100027f3          	csrr	a5,sstatus
ffffffffc02041ae:	edd7f793          	andi	a5,a5,-291
ffffffffc02041b2:	1207e793          	ori	a5,a5,288
ffffffffc02041b6:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02041b8:	860a                	mv	a2,sp
ffffffffc02041ba:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02041be:	00000797          	auipc	a5,0x0
ffffffffc02041c2:	a1278793          	addi	a5,a5,-1518 # ffffffffc0203bd0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02041c6:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02041c8:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02041ca:	bbdff0ef          	jal	ra,ffffffffc0203d86 <do_fork>
}
ffffffffc02041ce:	70f2                	ld	ra,312(sp)
ffffffffc02041d0:	7452                	ld	s0,304(sp)
ffffffffc02041d2:	74b2                	ld	s1,296(sp)
ffffffffc02041d4:	7912                	ld	s2,288(sp)
ffffffffc02041d6:	6131                	addi	sp,sp,320
ffffffffc02041d8:	8082                	ret

ffffffffc02041da <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc02041da:	7179                	addi	sp,sp,-48
ffffffffc02041dc:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02041de:	000c2417          	auipc	s0,0xc2
ffffffffc02041e2:	b7a40413          	addi	s0,s0,-1158 # ffffffffc02c5d58 <current>
ffffffffc02041e6:	601c                	ld	a5,0(s0)
{
ffffffffc02041e8:	f406                	sd	ra,40(sp)
ffffffffc02041ea:	ec26                	sd	s1,24(sp)
ffffffffc02041ec:	e84a                	sd	s2,16(sp)
ffffffffc02041ee:	e44e                	sd	s3,8(sp)
ffffffffc02041f0:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02041f2:	000c2717          	auipc	a4,0xc2
ffffffffc02041f6:	b6e73703          	ld	a4,-1170(a4) # ffffffffc02c5d60 <idleproc>
ffffffffc02041fa:	0ce78c63          	beq	a5,a4,ffffffffc02042d2 <do_exit+0xf8>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02041fe:	000c2497          	auipc	s1,0xc2
ffffffffc0204202:	b6a48493          	addi	s1,s1,-1174 # ffffffffc02c5d68 <initproc>
ffffffffc0204206:	6098                	ld	a4,0(s1)
ffffffffc0204208:	0ee78b63          	beq	a5,a4,ffffffffc02042fe <do_exit+0x124>
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc020420c:	0287b983          	ld	s3,40(a5)
ffffffffc0204210:	892a                	mv	s2,a0
    if (mm != NULL)
ffffffffc0204212:	02098663          	beqz	s3,ffffffffc020423e <do_exit+0x64>
ffffffffc0204216:	000c2797          	auipc	a5,0xc2
ffffffffc020421a:	b127b783          	ld	a5,-1262(a5) # ffffffffc02c5d28 <boot_pgdir_pa>
ffffffffc020421e:	577d                	li	a4,-1
ffffffffc0204220:	177e                	slli	a4,a4,0x3f
ffffffffc0204222:	83b1                	srli	a5,a5,0xc
ffffffffc0204224:	8fd9                	or	a5,a5,a4
ffffffffc0204226:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020422a:	0309a783          	lw	a5,48(s3)
ffffffffc020422e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204232:	02e9a823          	sw	a4,48(s3)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc0204236:	cb55                	beqz	a4,ffffffffc02042ea <do_exit+0x110>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc0204238:	601c                	ld	a5,0(s0)
ffffffffc020423a:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc020423e:	601c                	ld	a5,0(s0)
ffffffffc0204240:	470d                	li	a4,3
ffffffffc0204242:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0204244:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204248:	100027f3          	csrr	a5,sstatus
ffffffffc020424c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020424e:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204250:	e3f9                	bnez	a5,ffffffffc0204316 <do_exit+0x13c>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc0204252:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204254:	800007b7          	lui	a5,0x80000
ffffffffc0204258:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020425a:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc020425c:	0ec52703          	lw	a4,236(a0)
ffffffffc0204260:	0af70f63          	beq	a4,a5,ffffffffc020431e <do_exit+0x144>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc0204264:	6018                	ld	a4,0(s0)
ffffffffc0204266:	7b7c                	ld	a5,240(a4)
ffffffffc0204268:	c3a1                	beqz	a5,ffffffffc02042a8 <do_exit+0xce>
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc020426a:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc020426e:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204270:	0985                	addi	s3,s3,1
ffffffffc0204272:	a021                	j	ffffffffc020427a <do_exit+0xa0>
        while (current->cptr != NULL)
ffffffffc0204274:	6018                	ld	a4,0(s0)
ffffffffc0204276:	7b7c                	ld	a5,240(a4)
ffffffffc0204278:	cb85                	beqz	a5,ffffffffc02042a8 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc020427a:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_matrix_out_size+0xffffffff7fff39d8>
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020427e:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204280:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204282:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0204284:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204288:	10e7b023          	sd	a4,256(a5)
ffffffffc020428c:	c311                	beqz	a4,ffffffffc0204290 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc020428e:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204290:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204292:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204294:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204296:	fd271fe3          	bne	a4,s2,ffffffffc0204274 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc020429a:	0ec52783          	lw	a5,236(a0)
ffffffffc020429e:	fd379be3          	bne	a5,s3,ffffffffc0204274 <do_exit+0x9a>
                {
                    wakeup_proc(initproc);
ffffffffc02042a2:	49f000ef          	jal	ra,ffffffffc0204f40 <wakeup_proc>
ffffffffc02042a6:	b7f9                	j	ffffffffc0204274 <do_exit+0x9a>
    if (flag)
ffffffffc02042a8:	020a1263          	bnez	s4,ffffffffc02042cc <do_exit+0xf2>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc02042ac:	547000ef          	jal	ra,ffffffffc0204ff2 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02042b0:	601c                	ld	a5,0(s0)
ffffffffc02042b2:	00003617          	auipc	a2,0x3
ffffffffc02042b6:	c7e60613          	addi	a2,a2,-898 # ffffffffc0206f30 <default_pmm_manager+0xa78>
ffffffffc02042ba:	25500593          	li	a1,597
ffffffffc02042be:	43d4                	lw	a3,4(a5)
ffffffffc02042c0:	00003517          	auipc	a0,0x3
ffffffffc02042c4:	c1850513          	addi	a0,a0,-1000 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc02042c8:	9cafc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_enable();
ffffffffc02042cc:	ec4fc0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc02042d0:	bff1                	j	ffffffffc02042ac <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02042d2:	00003617          	auipc	a2,0x3
ffffffffc02042d6:	c3e60613          	addi	a2,a2,-962 # ffffffffc0206f10 <default_pmm_manager+0xa58>
ffffffffc02042da:	22100593          	li	a1,545
ffffffffc02042de:	00003517          	auipc	a0,0x3
ffffffffc02042e2:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc02042e6:	9acfc0ef          	jal	ra,ffffffffc0200492 <__panic>
            exit_mmap(mm);
ffffffffc02042ea:	854e                	mv	a0,s3
ffffffffc02042ec:	cb6ff0ef          	jal	ra,ffffffffc02037a2 <exit_mmap>
            put_pgdir(mm);
ffffffffc02042f0:	854e                	mv	a0,s3
ffffffffc02042f2:	98bff0ef          	jal	ra,ffffffffc0203c7c <put_pgdir>
            mm_destroy(mm);
ffffffffc02042f6:	854e                	mv	a0,s3
ffffffffc02042f8:	b0eff0ef          	jal	ra,ffffffffc0203606 <mm_destroy>
ffffffffc02042fc:	bf35                	j	ffffffffc0204238 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02042fe:	00003617          	auipc	a2,0x3
ffffffffc0204302:	c2260613          	addi	a2,a2,-990 # ffffffffc0206f20 <default_pmm_manager+0xa68>
ffffffffc0204306:	22500593          	li	a1,549
ffffffffc020430a:	00003517          	auipc	a0,0x3
ffffffffc020430e:	bce50513          	addi	a0,a0,-1074 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204312:	980fc0ef          	jal	ra,ffffffffc0200492 <__panic>
        intr_disable();
ffffffffc0204316:	e80fc0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        return 1;
ffffffffc020431a:	4a05                	li	s4,1
ffffffffc020431c:	bf1d                	j	ffffffffc0204252 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc020431e:	423000ef          	jal	ra,ffffffffc0204f40 <wakeup_proc>
ffffffffc0204322:	b789                	j	ffffffffc0204264 <do_exit+0x8a>

ffffffffc0204324 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc0204324:	715d                	addi	sp,sp,-80
ffffffffc0204326:	f84a                	sd	s2,48(sp)
ffffffffc0204328:	f44e                	sd	s3,40(sp)
        }
    }
    if (haskid)
    {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
ffffffffc020432a:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc020432e:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc0204330:	fc26                	sd	s1,56(sp)
ffffffffc0204332:	f052                	sd	s4,32(sp)
ffffffffc0204334:	ec56                	sd	s5,24(sp)
ffffffffc0204336:	e85a                	sd	s6,16(sp)
ffffffffc0204338:	e45e                	sd	s7,8(sp)
ffffffffc020433a:	e486                	sd	ra,72(sp)
ffffffffc020433c:	e0a2                	sd	s0,64(sp)
ffffffffc020433e:	84aa                	mv	s1,a0
ffffffffc0204340:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0204342:	000c2b97          	auipc	s7,0xc2
ffffffffc0204346:	a16b8b93          	addi	s7,s7,-1514 # ffffffffc02c5d58 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc020434a:	00050b1b          	sext.w	s6,a0
ffffffffc020434e:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0204352:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204354:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204356:	ccbd                	beqz	s1,ffffffffc02043d4 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204358:	0359e863          	bltu	s3,s5,ffffffffc0204388 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020435c:	45a9                	li	a1,10
ffffffffc020435e:	855a                	mv	a0,s6
ffffffffc0204360:	653000ef          	jal	ra,ffffffffc02051b2 <hash32>
ffffffffc0204364:	02051793          	slli	a5,a0,0x20
ffffffffc0204368:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020436c:	000be797          	auipc	a5,0xbe
ffffffffc0204370:	95478793          	addi	a5,a5,-1708 # ffffffffc02c1cc0 <hash_list>
ffffffffc0204374:	953e                	add	a0,a0,a5
ffffffffc0204376:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204378:	a029                	j	ffffffffc0204382 <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc020437a:	f2c42783          	lw	a5,-212(s0)
ffffffffc020437e:	02978163          	beq	a5,s1,ffffffffc02043a0 <do_wait.part.0+0x7c>
ffffffffc0204382:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204384:	fe851be3          	bne	a0,s0,ffffffffc020437a <do_wait.part.0+0x56>
        {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;
ffffffffc0204388:	5579                	li	a0,-2
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc020438a:	60a6                	ld	ra,72(sp)
ffffffffc020438c:	6406                	ld	s0,64(sp)
ffffffffc020438e:	74e2                	ld	s1,56(sp)
ffffffffc0204390:	7942                	ld	s2,48(sp)
ffffffffc0204392:	79a2                	ld	s3,40(sp)
ffffffffc0204394:	7a02                	ld	s4,32(sp)
ffffffffc0204396:	6ae2                	ld	s5,24(sp)
ffffffffc0204398:	6b42                	ld	s6,16(sp)
ffffffffc020439a:	6ba2                	ld	s7,8(sp)
ffffffffc020439c:	6161                	addi	sp,sp,80
ffffffffc020439e:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02043a0:	000bb683          	ld	a3,0(s7)
ffffffffc02043a4:	f4843783          	ld	a5,-184(s0)
ffffffffc02043a8:	fed790e3          	bne	a5,a3,ffffffffc0204388 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02043ac:	f2842703          	lw	a4,-216(s0)
ffffffffc02043b0:	478d                	li	a5,3
ffffffffc02043b2:	0ef70b63          	beq	a4,a5,ffffffffc02044a8 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02043b6:	4785                	li	a5,1
ffffffffc02043b8:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02043ba:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02043be:	435000ef          	jal	ra,ffffffffc0204ff2 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02043c2:	000bb783          	ld	a5,0(s7)
ffffffffc02043c6:	0b07a783          	lw	a5,176(a5)
ffffffffc02043ca:	8b85                	andi	a5,a5,1
ffffffffc02043cc:	d7c9                	beqz	a5,ffffffffc0204356 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02043ce:	555d                	li	a0,-9
ffffffffc02043d0:	e0bff0ef          	jal	ra,ffffffffc02041da <do_exit>
        proc = current->cptr;
ffffffffc02043d4:	000bb683          	ld	a3,0(s7)
ffffffffc02043d8:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02043da:	d45d                	beqz	s0,ffffffffc0204388 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02043dc:	470d                	li	a4,3
ffffffffc02043de:	a021                	j	ffffffffc02043e6 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02043e0:	10043403          	ld	s0,256(s0)
ffffffffc02043e4:	d869                	beqz	s0,ffffffffc02043b6 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02043e6:	401c                	lw	a5,0(s0)
ffffffffc02043e8:	fee79ce3          	bne	a5,a4,ffffffffc02043e0 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02043ec:	000c2797          	auipc	a5,0xc2
ffffffffc02043f0:	9747b783          	ld	a5,-1676(a5) # ffffffffc02c5d60 <idleproc>
ffffffffc02043f4:	0c878963          	beq	a5,s0,ffffffffc02044c6 <do_wait.part.0+0x1a2>
ffffffffc02043f8:	000c2797          	auipc	a5,0xc2
ffffffffc02043fc:	9707b783          	ld	a5,-1680(a5) # ffffffffc02c5d68 <initproc>
ffffffffc0204400:	0cf40363          	beq	s0,a5,ffffffffc02044c6 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc0204404:	000a0663          	beqz	s4,ffffffffc0204410 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0204408:	0e842783          	lw	a5,232(s0)
ffffffffc020440c:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8f50>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204410:	100027f3          	csrr	a5,sstatus
ffffffffc0204414:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204416:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204418:	e7c1                	bnez	a5,ffffffffc02044a0 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020441a:	6c70                	ld	a2,216(s0)
ffffffffc020441c:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020441e:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0204422:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204424:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204426:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204428:	6470                	ld	a2,200(s0)
ffffffffc020442a:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020442c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020442e:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc0204430:	c319                	beqz	a4,ffffffffc0204436 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0204432:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204434:	7c7c                	ld	a5,248(s0)
ffffffffc0204436:	c3b5                	beqz	a5,ffffffffc020449a <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204438:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc020443c:	000c2717          	auipc	a4,0xc2
ffffffffc0204440:	93470713          	addi	a4,a4,-1740 # ffffffffc02c5d70 <nr_process>
ffffffffc0204444:	431c                	lw	a5,0(a4)
ffffffffc0204446:	37fd                	addiw	a5,a5,-1
ffffffffc0204448:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc020444a:	e5a9                	bnez	a1,ffffffffc0204494 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020444c:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020444e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204452:	04f6ee63          	bltu	a3,a5,ffffffffc02044ae <do_wait.part.0+0x18a>
ffffffffc0204456:	000c2797          	auipc	a5,0xc2
ffffffffc020445a:	8fa7b783          	ld	a5,-1798(a5) # ffffffffc02c5d50 <va_pa_offset>
ffffffffc020445e:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204460:	82b1                	srli	a3,a3,0xc
ffffffffc0204462:	000c2797          	auipc	a5,0xc2
ffffffffc0204466:	8d67b783          	ld	a5,-1834(a5) # ffffffffc02c5d38 <npage>
ffffffffc020446a:	06f6fa63          	bgeu	a3,a5,ffffffffc02044de <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020446e:	00004517          	auipc	a0,0x4
ffffffffc0204472:	a9253503          	ld	a0,-1390(a0) # ffffffffc0207f00 <nbase>
ffffffffc0204476:	8e89                	sub	a3,a3,a0
ffffffffc0204478:	069a                	slli	a3,a3,0x6
ffffffffc020447a:	000c2517          	auipc	a0,0xc2
ffffffffc020447e:	8c653503          	ld	a0,-1850(a0) # ffffffffc02c5d40 <pages>
ffffffffc0204482:	9536                	add	a0,a0,a3
ffffffffc0204484:	4589                	li	a1,2
ffffffffc0204486:	8fdfd0ef          	jal	ra,ffffffffc0201d82 <free_pages>
    kfree(proc);
ffffffffc020448a:	8522                	mv	a0,s0
ffffffffc020448c:	f8afd0ef          	jal	ra,ffffffffc0201c16 <kfree>
    return 0;
ffffffffc0204490:	4501                	li	a0,0
ffffffffc0204492:	bde5                	j	ffffffffc020438a <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204494:	cfcfc0ef          	jal	ra,ffffffffc0200990 <intr_enable>
ffffffffc0204498:	bf55                	j	ffffffffc020444c <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc020449a:	701c                	ld	a5,32(s0)
ffffffffc020449c:	fbf8                	sd	a4,240(a5)
ffffffffc020449e:	bf79                	j	ffffffffc020443c <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02044a0:	cf6fc0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        return 1;
ffffffffc02044a4:	4585                	li	a1,1
ffffffffc02044a6:	bf95                	j	ffffffffc020441a <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02044a8:	f2840413          	addi	s0,s0,-216
ffffffffc02044ac:	b781                	j	ffffffffc02043ec <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02044ae:	00002617          	auipc	a2,0x2
ffffffffc02044b2:	0ea60613          	addi	a2,a2,234 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc02044b6:	07700593          	li	a1,119
ffffffffc02044ba:	00002517          	auipc	a0,0x2
ffffffffc02044be:	05e50513          	addi	a0,a0,94 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc02044c2:	fd1fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02044c6:	00003617          	auipc	a2,0x3
ffffffffc02044ca:	a8a60613          	addi	a2,a2,-1398 # ffffffffc0206f50 <default_pmm_manager+0xa98>
ffffffffc02044ce:	37e00593          	li	a1,894
ffffffffc02044d2:	00003517          	auipc	a0,0x3
ffffffffc02044d6:	a0650513          	addi	a0,a0,-1530 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc02044da:	fb9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02044de:	00002617          	auipc	a2,0x2
ffffffffc02044e2:	0e260613          	addi	a2,a2,226 # ffffffffc02065c0 <default_pmm_manager+0x108>
ffffffffc02044e6:	06900593          	li	a1,105
ffffffffc02044ea:	00002517          	auipc	a0,0x2
ffffffffc02044ee:	02e50513          	addi	a0,a0,46 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc02044f2:	fa1fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02044f6 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02044f6:	1141                	addi	sp,sp,-16
ffffffffc02044f8:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02044fa:	8c9fd0ef          	jal	ra,ffffffffc0201dc2 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02044fe:	e64fd0ef          	jal	ra,ffffffffc0201b62 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204502:	4601                	li	a2,0
ffffffffc0204504:	4581                	li	a1,0
ffffffffc0204506:	00000517          	auipc	a0,0x0
ffffffffc020450a:	62850513          	addi	a0,a0,1576 # ffffffffc0204b2e <user_main>
ffffffffc020450e:	c7dff0ef          	jal	ra,ffffffffc020418a <kernel_thread>
    if (pid <= 0)
ffffffffc0204512:	00a04563          	bgtz	a0,ffffffffc020451c <init_main+0x26>
ffffffffc0204516:	a071                	j	ffffffffc02045a2 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204518:	2db000ef          	jal	ra,ffffffffc0204ff2 <schedule>
    if (code_store != NULL)
ffffffffc020451c:	4581                	li	a1,0
ffffffffc020451e:	4501                	li	a0,0
ffffffffc0204520:	e05ff0ef          	jal	ra,ffffffffc0204324 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204524:	d975                	beqz	a0,ffffffffc0204518 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204526:	00003517          	auipc	a0,0x3
ffffffffc020452a:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0206f90 <default_pmm_manager+0xad8>
ffffffffc020452e:	c6bfb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204532:	000c2797          	auipc	a5,0xc2
ffffffffc0204536:	8367b783          	ld	a5,-1994(a5) # ffffffffc02c5d68 <initproc>
ffffffffc020453a:	7bf8                	ld	a4,240(a5)
ffffffffc020453c:	e339                	bnez	a4,ffffffffc0204582 <init_main+0x8c>
ffffffffc020453e:	7ff8                	ld	a4,248(a5)
ffffffffc0204540:	e329                	bnez	a4,ffffffffc0204582 <init_main+0x8c>
ffffffffc0204542:	1007b703          	ld	a4,256(a5)
ffffffffc0204546:	ef15                	bnez	a4,ffffffffc0204582 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204548:	000c2697          	auipc	a3,0xc2
ffffffffc020454c:	8286a683          	lw	a3,-2008(a3) # ffffffffc02c5d70 <nr_process>
ffffffffc0204550:	4709                	li	a4,2
ffffffffc0204552:	0ae69463          	bne	a3,a4,ffffffffc02045fa <init_main+0x104>
    return listelm->next;
ffffffffc0204556:	000c1697          	auipc	a3,0xc1
ffffffffc020455a:	76a68693          	addi	a3,a3,1898 # ffffffffc02c5cc0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020455e:	6698                	ld	a4,8(a3)
ffffffffc0204560:	0c878793          	addi	a5,a5,200
ffffffffc0204564:	06f71b63          	bne	a4,a5,ffffffffc02045da <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204568:	629c                	ld	a5,0(a3)
ffffffffc020456a:	04f71863          	bne	a4,a5,ffffffffc02045ba <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020456e:	00003517          	auipc	a0,0x3
ffffffffc0204572:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0207078 <default_pmm_manager+0xbc0>
ffffffffc0204576:	c23fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    return 0;
}
ffffffffc020457a:	60a2                	ld	ra,8(sp)
ffffffffc020457c:	4501                	li	a0,0
ffffffffc020457e:	0141                	addi	sp,sp,16
ffffffffc0204580:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204582:	00003697          	auipc	a3,0x3
ffffffffc0204586:	a3668693          	addi	a3,a3,-1482 # ffffffffc0206fb8 <default_pmm_manager+0xb00>
ffffffffc020458a:	00002617          	auipc	a2,0x2
ffffffffc020458e:	b7e60613          	addi	a2,a2,-1154 # ffffffffc0206108 <commands+0x818>
ffffffffc0204592:	3ea00593          	li	a1,1002
ffffffffc0204596:	00003517          	auipc	a0,0x3
ffffffffc020459a:	94250513          	addi	a0,a0,-1726 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc020459e:	ef5fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("create user_main failed.\n");
ffffffffc02045a2:	00003617          	auipc	a2,0x3
ffffffffc02045a6:	9ce60613          	addi	a2,a2,-1586 # ffffffffc0206f70 <default_pmm_manager+0xab8>
ffffffffc02045aa:	3e100593          	li	a1,993
ffffffffc02045ae:	00003517          	auipc	a0,0x3
ffffffffc02045b2:	92a50513          	addi	a0,a0,-1750 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc02045b6:	eddfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02045ba:	00003697          	auipc	a3,0x3
ffffffffc02045be:	a8e68693          	addi	a3,a3,-1394 # ffffffffc0207048 <default_pmm_manager+0xb90>
ffffffffc02045c2:	00002617          	auipc	a2,0x2
ffffffffc02045c6:	b4660613          	addi	a2,a2,-1210 # ffffffffc0206108 <commands+0x818>
ffffffffc02045ca:	3ed00593          	li	a1,1005
ffffffffc02045ce:	00003517          	auipc	a0,0x3
ffffffffc02045d2:	90a50513          	addi	a0,a0,-1782 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc02045d6:	ebdfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02045da:	00003697          	auipc	a3,0x3
ffffffffc02045de:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0207018 <default_pmm_manager+0xb60>
ffffffffc02045e2:	00002617          	auipc	a2,0x2
ffffffffc02045e6:	b2660613          	addi	a2,a2,-1242 # ffffffffc0206108 <commands+0x818>
ffffffffc02045ea:	3ec00593          	li	a1,1004
ffffffffc02045ee:	00003517          	auipc	a0,0x3
ffffffffc02045f2:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc02045f6:	e9dfb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(nr_process == 2);
ffffffffc02045fa:	00003697          	auipc	a3,0x3
ffffffffc02045fe:	a0e68693          	addi	a3,a3,-1522 # ffffffffc0207008 <default_pmm_manager+0xb50>
ffffffffc0204602:	00002617          	auipc	a2,0x2
ffffffffc0204606:	b0660613          	addi	a2,a2,-1274 # ffffffffc0206108 <commands+0x818>
ffffffffc020460a:	3eb00593          	li	a1,1003
ffffffffc020460e:	00003517          	auipc	a0,0x3
ffffffffc0204612:	8ca50513          	addi	a0,a0,-1846 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204616:	e7dfb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc020461a <do_execve>:
{
ffffffffc020461a:	7171                	addi	sp,sp,-176
ffffffffc020461c:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020461e:	000c1d97          	auipc	s11,0xc1
ffffffffc0204622:	73ad8d93          	addi	s11,s11,1850 # ffffffffc02c5d58 <current>
ffffffffc0204626:	000db783          	ld	a5,0(s11)
{
ffffffffc020462a:	e54e                	sd	s3,136(sp)
ffffffffc020462c:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020462e:	0287b983          	ld	s3,40(a5)
{
ffffffffc0204632:	e94a                	sd	s2,144(sp)
ffffffffc0204634:	f4de                	sd	s7,104(sp)
ffffffffc0204636:	892a                	mv	s2,a0
ffffffffc0204638:	8bb2                	mv	s7,a2
ffffffffc020463a:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020463c:	862e                	mv	a2,a1
ffffffffc020463e:	4681                	li	a3,0
ffffffffc0204640:	85aa                	mv	a1,a0
ffffffffc0204642:	854e                	mv	a0,s3
{
ffffffffc0204644:	f506                	sd	ra,168(sp)
ffffffffc0204646:	f122                	sd	s0,160(sp)
ffffffffc0204648:	e152                	sd	s4,128(sp)
ffffffffc020464a:	fcd6                	sd	s5,120(sp)
ffffffffc020464c:	f8da                	sd	s6,112(sp)
ffffffffc020464e:	f0e2                	sd	s8,96(sp)
ffffffffc0204650:	ece6                	sd	s9,88(sp)
ffffffffc0204652:	e8ea                	sd	s10,80(sp)
ffffffffc0204654:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204656:	ce6ff0ef          	jal	ra,ffffffffc0203b3c <user_mem_check>
ffffffffc020465a:	40050a63          	beqz	a0,ffffffffc0204a6e <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020465e:	4641                	li	a2,16
ffffffffc0204660:	4581                	li	a1,0
ffffffffc0204662:	1808                	addi	a0,sp,48
ffffffffc0204664:	7f5000ef          	jal	ra,ffffffffc0205658 <memset>
    memcpy(local_name, name, len);
ffffffffc0204668:	47bd                	li	a5,15
ffffffffc020466a:	8626                	mv	a2,s1
ffffffffc020466c:	1e97e263          	bltu	a5,s1,ffffffffc0204850 <do_execve+0x236>
ffffffffc0204670:	85ca                	mv	a1,s2
ffffffffc0204672:	1808                	addi	a0,sp,48
ffffffffc0204674:	7f7000ef          	jal	ra,ffffffffc020566a <memcpy>
    if (mm != NULL)
ffffffffc0204678:	1e098363          	beqz	s3,ffffffffc020485e <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc020467c:	00002517          	auipc	a0,0x2
ffffffffc0204680:	65c50513          	addi	a0,a0,1628 # ffffffffc0206cd8 <default_pmm_manager+0x820>
ffffffffc0204684:	b4dfb0ef          	jal	ra,ffffffffc02001d0 <cputs>
ffffffffc0204688:	000c1797          	auipc	a5,0xc1
ffffffffc020468c:	6a07b783          	ld	a5,1696(a5) # ffffffffc02c5d28 <boot_pgdir_pa>
ffffffffc0204690:	577d                	li	a4,-1
ffffffffc0204692:	177e                	slli	a4,a4,0x3f
ffffffffc0204694:	83b1                	srli	a5,a5,0xc
ffffffffc0204696:	8fd9                	or	a5,a5,a4
ffffffffc0204698:	18079073          	csrw	satp,a5
ffffffffc020469c:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7f20>
ffffffffc02046a0:	fff7871b          	addiw	a4,a5,-1
ffffffffc02046a4:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc02046a8:	2c070463          	beqz	a4,ffffffffc0204970 <do_execve+0x356>
        current->mm = NULL;
ffffffffc02046ac:	000db783          	ld	a5,0(s11)
ffffffffc02046b0:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02046b4:	e13fe0ef          	jal	ra,ffffffffc02034c6 <mm_create>
ffffffffc02046b8:	84aa                	mv	s1,a0
ffffffffc02046ba:	1c050d63          	beqz	a0,ffffffffc0204894 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc02046be:	4505                	li	a0,1
ffffffffc02046c0:	e84fd0ef          	jal	ra,ffffffffc0201d44 <alloc_pages>
ffffffffc02046c4:	3a050963          	beqz	a0,ffffffffc0204a76 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc02046c8:	000c1c97          	auipc	s9,0xc1
ffffffffc02046cc:	678c8c93          	addi	s9,s9,1656 # ffffffffc02c5d40 <pages>
ffffffffc02046d0:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02046d4:	000c1c17          	auipc	s8,0xc1
ffffffffc02046d8:	664c0c13          	addi	s8,s8,1636 # ffffffffc02c5d38 <npage>
    return page - pages + nbase;
ffffffffc02046dc:	00004717          	auipc	a4,0x4
ffffffffc02046e0:	82473703          	ld	a4,-2012(a4) # ffffffffc0207f00 <nbase>
ffffffffc02046e4:	40d506b3          	sub	a3,a0,a3
ffffffffc02046e8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02046ea:	5afd                	li	s5,-1
ffffffffc02046ec:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02046f0:	96ba                	add	a3,a3,a4
ffffffffc02046f2:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02046f4:	00cad713          	srli	a4,s5,0xc
ffffffffc02046f8:	ec3a                	sd	a4,24(sp)
ffffffffc02046fa:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02046fc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02046fe:	38f77063          	bgeu	a4,a5,ffffffffc0204a7e <do_execve+0x464>
ffffffffc0204702:	000c1b17          	auipc	s6,0xc1
ffffffffc0204706:	64eb0b13          	addi	s6,s6,1614 # ffffffffc02c5d50 <va_pa_offset>
ffffffffc020470a:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020470e:	6605                	lui	a2,0x1
ffffffffc0204710:	000c1597          	auipc	a1,0xc1
ffffffffc0204714:	6205b583          	ld	a1,1568(a1) # ffffffffc02c5d30 <boot_pgdir_va>
ffffffffc0204718:	9936                	add	s2,s2,a3
ffffffffc020471a:	854a                	mv	a0,s2
ffffffffc020471c:	74f000ef          	jal	ra,ffffffffc020566a <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204720:	7782                	ld	a5,32(sp)
ffffffffc0204722:	4398                	lw	a4,0(a5)
ffffffffc0204724:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204728:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc020472c:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b7e57>
ffffffffc0204730:	14f71863          	bne	a4,a5,ffffffffc0204880 <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204734:	7682                	ld	a3,32(sp)
ffffffffc0204736:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020473a:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020473e:	00371793          	slli	a5,a4,0x3
ffffffffc0204742:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204744:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204746:	078e                	slli	a5,a5,0x3
ffffffffc0204748:	97ce                	add	a5,a5,s3
ffffffffc020474a:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc020474c:	00f9fc63          	bgeu	s3,a5,ffffffffc0204764 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204750:	0009a783          	lw	a5,0(s3)
ffffffffc0204754:	4705                	li	a4,1
ffffffffc0204756:	14e78163          	beq	a5,a4,ffffffffc0204898 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc020475a:	77a2                	ld	a5,40(sp)
ffffffffc020475c:	03898993          	addi	s3,s3,56
ffffffffc0204760:	fef9e8e3          	bltu	s3,a5,ffffffffc0204750 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204764:	4701                	li	a4,0
ffffffffc0204766:	46ad                	li	a3,11
ffffffffc0204768:	00100637          	lui	a2,0x100
ffffffffc020476c:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204770:	8526                	mv	a0,s1
ffffffffc0204772:	ee7fe0ef          	jal	ra,ffffffffc0203658 <mm_map>
ffffffffc0204776:	8a2a                	mv	s4,a0
ffffffffc0204778:	1e051263          	bnez	a0,ffffffffc020495c <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc020477c:	6c88                	ld	a0,24(s1)
ffffffffc020477e:	467d                	li	a2,31
ffffffffc0204780:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204784:	c5dfe0ef          	jal	ra,ffffffffc02033e0 <pgdir_alloc_page>
ffffffffc0204788:	38050363          	beqz	a0,ffffffffc0204b0e <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc020478c:	6c88                	ld	a0,24(s1)
ffffffffc020478e:	467d                	li	a2,31
ffffffffc0204790:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204794:	c4dfe0ef          	jal	ra,ffffffffc02033e0 <pgdir_alloc_page>
ffffffffc0204798:	34050b63          	beqz	a0,ffffffffc0204aee <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc020479c:	6c88                	ld	a0,24(s1)
ffffffffc020479e:	467d                	li	a2,31
ffffffffc02047a0:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02047a4:	c3dfe0ef          	jal	ra,ffffffffc02033e0 <pgdir_alloc_page>
ffffffffc02047a8:	32050363          	beqz	a0,ffffffffc0204ace <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc02047ac:	6c88                	ld	a0,24(s1)
ffffffffc02047ae:	467d                	li	a2,31
ffffffffc02047b0:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02047b4:	c2dfe0ef          	jal	ra,ffffffffc02033e0 <pgdir_alloc_page>
ffffffffc02047b8:	2e050b63          	beqz	a0,ffffffffc0204aae <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc02047bc:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc02047be:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02047c2:	6c94                	ld	a3,24(s1)
ffffffffc02047c4:	2785                	addiw	a5,a5,1
ffffffffc02047c6:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc02047c8:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc02047ca:	c02007b7          	lui	a5,0xc0200
ffffffffc02047ce:	2cf6e463          	bltu	a3,a5,ffffffffc0204a96 <do_execve+0x47c>
ffffffffc02047d2:	000b3783          	ld	a5,0(s6)
ffffffffc02047d6:	577d                	li	a4,-1
ffffffffc02047d8:	177e                	slli	a4,a4,0x3f
ffffffffc02047da:	8e9d                	sub	a3,a3,a5
ffffffffc02047dc:	00c6d793          	srli	a5,a3,0xc
ffffffffc02047e0:	f654                	sd	a3,168(a2)
ffffffffc02047e2:	8fd9                	or	a5,a5,a4
ffffffffc02047e4:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02047e8:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02047ea:	4581                	li	a1,0
ffffffffc02047ec:	12000613          	li	a2,288
ffffffffc02047f0:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc02047f2:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02047f6:	663000ef          	jal	ra,ffffffffc0205658 <memset>
    tf->epc = elf->e_entry;
ffffffffc02047fa:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02047fc:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc0204800:	edd4f493          	andi	s1,s1,-291
    tf->epc = elf->e_entry;
ffffffffc0204804:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204806:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204808:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_matrix_out_size+0xffffffff7fff398c>
    tf->gpr.sp = USTACKTOP;
ffffffffc020480c:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc020480e:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204812:	4641                	li	a2,16
ffffffffc0204814:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204816:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204818:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~SSTATUS_SPP & ~SSTATUS_SIE) | SSTATUS_SPIE;
ffffffffc020481c:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204820:	854a                	mv	a0,s2
ffffffffc0204822:	637000ef          	jal	ra,ffffffffc0205658 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204826:	463d                	li	a2,15
ffffffffc0204828:	180c                	addi	a1,sp,48
ffffffffc020482a:	854a                	mv	a0,s2
ffffffffc020482c:	63f000ef          	jal	ra,ffffffffc020566a <memcpy>
}
ffffffffc0204830:	70aa                	ld	ra,168(sp)
ffffffffc0204832:	740a                	ld	s0,160(sp)
ffffffffc0204834:	64ea                	ld	s1,152(sp)
ffffffffc0204836:	694a                	ld	s2,144(sp)
ffffffffc0204838:	69aa                	ld	s3,136(sp)
ffffffffc020483a:	7ae6                	ld	s5,120(sp)
ffffffffc020483c:	7b46                	ld	s6,112(sp)
ffffffffc020483e:	7ba6                	ld	s7,104(sp)
ffffffffc0204840:	7c06                	ld	s8,96(sp)
ffffffffc0204842:	6ce6                	ld	s9,88(sp)
ffffffffc0204844:	6d46                	ld	s10,80(sp)
ffffffffc0204846:	6da6                	ld	s11,72(sp)
ffffffffc0204848:	8552                	mv	a0,s4
ffffffffc020484a:	6a0a                	ld	s4,128(sp)
ffffffffc020484c:	614d                	addi	sp,sp,176
ffffffffc020484e:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204850:	463d                	li	a2,15
ffffffffc0204852:	85ca                	mv	a1,s2
ffffffffc0204854:	1808                	addi	a0,sp,48
ffffffffc0204856:	615000ef          	jal	ra,ffffffffc020566a <memcpy>
    if (mm != NULL)
ffffffffc020485a:	e20991e3          	bnez	s3,ffffffffc020467c <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc020485e:	000db783          	ld	a5,0(s11)
ffffffffc0204862:	779c                	ld	a5,40(a5)
ffffffffc0204864:	e40788e3          	beqz	a5,ffffffffc02046b4 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204868:	00003617          	auipc	a2,0x3
ffffffffc020486c:	83060613          	addi	a2,a2,-2000 # ffffffffc0207098 <default_pmm_manager+0xbe0>
ffffffffc0204870:	26100593          	li	a1,609
ffffffffc0204874:	00002517          	auipc	a0,0x2
ffffffffc0204878:	66450513          	addi	a0,a0,1636 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc020487c:	c17fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    put_pgdir(mm);
ffffffffc0204880:	8526                	mv	a0,s1
ffffffffc0204882:	bfaff0ef          	jal	ra,ffffffffc0203c7c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204886:	8526                	mv	a0,s1
ffffffffc0204888:	d7ffe0ef          	jal	ra,ffffffffc0203606 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc020488c:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc020488e:	8552                	mv	a0,s4
ffffffffc0204890:	94bff0ef          	jal	ra,ffffffffc02041da <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204894:	5a71                	li	s4,-4
ffffffffc0204896:	bfe5                	j	ffffffffc020488e <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204898:	0289b603          	ld	a2,40(s3)
ffffffffc020489c:	0209b783          	ld	a5,32(s3)
ffffffffc02048a0:	1cf66d63          	bltu	a2,a5,ffffffffc0204a7a <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc02048a4:	0049a783          	lw	a5,4(s3)
ffffffffc02048a8:	0017f693          	andi	a3,a5,1
ffffffffc02048ac:	c291                	beqz	a3,ffffffffc02048b0 <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc02048ae:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02048b0:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc02048b4:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc02048b6:	e779                	bnez	a4,ffffffffc0204984 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc02048b8:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc02048ba:	c781                	beqz	a5,ffffffffc02048c2 <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc02048bc:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc02048c0:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc02048c2:	0026f793          	andi	a5,a3,2
ffffffffc02048c6:	e3f1                	bnez	a5,ffffffffc020498a <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc02048c8:	0046f793          	andi	a5,a3,4
ffffffffc02048cc:	c399                	beqz	a5,ffffffffc02048d2 <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc02048ce:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc02048d2:	0109b583          	ld	a1,16(s3)
ffffffffc02048d6:	4701                	li	a4,0
ffffffffc02048d8:	8526                	mv	a0,s1
ffffffffc02048da:	d7ffe0ef          	jal	ra,ffffffffc0203658 <mm_map>
ffffffffc02048de:	8a2a                	mv	s4,a0
ffffffffc02048e0:	ed35                	bnez	a0,ffffffffc020495c <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02048e2:	0109bb83          	ld	s7,16(s3)
ffffffffc02048e6:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc02048e8:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc02048ec:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc02048f0:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc02048f4:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc02048f6:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc02048f8:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc02048fa:	054be963          	bltu	s7,s4,ffffffffc020494c <do_execve+0x332>
ffffffffc02048fe:	aa95                	j	ffffffffc0204a72 <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204900:	6785                	lui	a5,0x1
ffffffffc0204902:	415b8533          	sub	a0,s7,s5
ffffffffc0204906:	9abe                	add	s5,s5,a5
ffffffffc0204908:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc020490c:	015a7463          	bgeu	s4,s5,ffffffffc0204914 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204910:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204914:	000cb683          	ld	a3,0(s9)
ffffffffc0204918:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc020491a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc020491e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204922:	8699                	srai	a3,a3,0x6
ffffffffc0204924:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204926:	67e2                	ld	a5,24(sp)
ffffffffc0204928:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc020492c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020492e:	14b87863          	bgeu	a6,a1,ffffffffc0204a7e <do_execve+0x464>
ffffffffc0204932:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204936:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204938:	9bb2                	add	s7,s7,a2
ffffffffc020493a:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc020493c:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc020493e:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204940:	52b000ef          	jal	ra,ffffffffc020566a <memcpy>
            start += size, from += size;
ffffffffc0204944:	6622                	ld	a2,8(sp)
ffffffffc0204946:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204948:	054bf363          	bgeu	s7,s4,ffffffffc020498e <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc020494c:	6c88                	ld	a0,24(s1)
ffffffffc020494e:	866a                	mv	a2,s10
ffffffffc0204950:	85d6                	mv	a1,s5
ffffffffc0204952:	a8ffe0ef          	jal	ra,ffffffffc02033e0 <pgdir_alloc_page>
ffffffffc0204956:	842a                	mv	s0,a0
ffffffffc0204958:	f545                	bnez	a0,ffffffffc0204900 <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc020495a:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc020495c:	8526                	mv	a0,s1
ffffffffc020495e:	e45fe0ef          	jal	ra,ffffffffc02037a2 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204962:	8526                	mv	a0,s1
ffffffffc0204964:	b18ff0ef          	jal	ra,ffffffffc0203c7c <put_pgdir>
    mm_destroy(mm);
ffffffffc0204968:	8526                	mv	a0,s1
ffffffffc020496a:	c9dfe0ef          	jal	ra,ffffffffc0203606 <mm_destroy>
    return ret;
ffffffffc020496e:	b705                	j	ffffffffc020488e <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204970:	854e                	mv	a0,s3
ffffffffc0204972:	e31fe0ef          	jal	ra,ffffffffc02037a2 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204976:	854e                	mv	a0,s3
ffffffffc0204978:	b04ff0ef          	jal	ra,ffffffffc0203c7c <put_pgdir>
            mm_destroy(mm);
ffffffffc020497c:	854e                	mv	a0,s3
ffffffffc020497e:	c89fe0ef          	jal	ra,ffffffffc0203606 <mm_destroy>
ffffffffc0204982:	b32d                	j	ffffffffc02046ac <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204984:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204988:	fb95                	bnez	a5,ffffffffc02048bc <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc020498a:	4d5d                	li	s10,23
ffffffffc020498c:	bf35                	j	ffffffffc02048c8 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc020498e:	0109b683          	ld	a3,16(s3)
ffffffffc0204992:	0289b903          	ld	s2,40(s3)
ffffffffc0204996:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204998:	075bfd63          	bgeu	s7,s5,ffffffffc0204a12 <do_execve+0x3f8>
            if (start == end)
ffffffffc020499c:	db790fe3          	beq	s2,s7,ffffffffc020475a <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc02049a0:	6785                	lui	a5,0x1
ffffffffc02049a2:	00fb8533          	add	a0,s7,a5
ffffffffc02049a6:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc02049aa:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc02049ae:	0b597d63          	bgeu	s2,s5,ffffffffc0204a68 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc02049b2:	000cb683          	ld	a3,0(s9)
ffffffffc02049b6:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02049b8:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02049bc:	40d406b3          	sub	a3,s0,a3
ffffffffc02049c0:	8699                	srai	a3,a3,0x6
ffffffffc02049c2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02049c4:	67e2                	ld	a5,24(sp)
ffffffffc02049c6:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02049ca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049cc:	0ac5f963          	bgeu	a1,a2,ffffffffc0204a7e <do_execve+0x464>
ffffffffc02049d0:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc02049d4:	8652                	mv	a2,s4
ffffffffc02049d6:	4581                	li	a1,0
ffffffffc02049d8:	96c2                	add	a3,a3,a6
ffffffffc02049da:	9536                	add	a0,a0,a3
ffffffffc02049dc:	47d000ef          	jal	ra,ffffffffc0205658 <memset>
            start += size;
ffffffffc02049e0:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc02049e4:	03597463          	bgeu	s2,s5,ffffffffc0204a0c <do_execve+0x3f2>
ffffffffc02049e8:	d6e909e3          	beq	s2,a4,ffffffffc020475a <do_execve+0x140>
ffffffffc02049ec:	00002697          	auipc	a3,0x2
ffffffffc02049f0:	6d468693          	addi	a3,a3,1748 # ffffffffc02070c0 <default_pmm_manager+0xc08>
ffffffffc02049f4:	00001617          	auipc	a2,0x1
ffffffffc02049f8:	71460613          	addi	a2,a2,1812 # ffffffffc0206108 <commands+0x818>
ffffffffc02049fc:	2ca00593          	li	a1,714
ffffffffc0204a00:	00002517          	auipc	a0,0x2
ffffffffc0204a04:	4d850513          	addi	a0,a0,1240 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204a08:	a8bfb0ef          	jal	ra,ffffffffc0200492 <__panic>
ffffffffc0204a0c:	ff5710e3          	bne	a4,s5,ffffffffc02049ec <do_execve+0x3d2>
ffffffffc0204a10:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204a12:	d52bf4e3          	bgeu	s7,s2,ffffffffc020475a <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204a16:	6c88                	ld	a0,24(s1)
ffffffffc0204a18:	866a                	mv	a2,s10
ffffffffc0204a1a:	85d6                	mv	a1,s5
ffffffffc0204a1c:	9c5fe0ef          	jal	ra,ffffffffc02033e0 <pgdir_alloc_page>
ffffffffc0204a20:	842a                	mv	s0,a0
ffffffffc0204a22:	dd05                	beqz	a0,ffffffffc020495a <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204a24:	6785                	lui	a5,0x1
ffffffffc0204a26:	415b8533          	sub	a0,s7,s5
ffffffffc0204a2a:	9abe                	add	s5,s5,a5
ffffffffc0204a2c:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204a30:	01597463          	bgeu	s2,s5,ffffffffc0204a38 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204a34:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204a38:	000cb683          	ld	a3,0(s9)
ffffffffc0204a3c:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204a3e:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204a42:	40d406b3          	sub	a3,s0,a3
ffffffffc0204a46:	8699                	srai	a3,a3,0x6
ffffffffc0204a48:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204a4a:	67e2                	ld	a5,24(sp)
ffffffffc0204a4c:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a50:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a52:	02b87663          	bgeu	a6,a1,ffffffffc0204a7e <do_execve+0x464>
ffffffffc0204a56:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204a5a:	4581                	li	a1,0
            start += size;
ffffffffc0204a5c:	9bb2                	add	s7,s7,a2
ffffffffc0204a5e:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204a60:	9536                	add	a0,a0,a3
ffffffffc0204a62:	3f7000ef          	jal	ra,ffffffffc0205658 <memset>
ffffffffc0204a66:	b775                	j	ffffffffc0204a12 <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204a68:	417a8a33          	sub	s4,s5,s7
ffffffffc0204a6c:	b799                	j	ffffffffc02049b2 <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204a6e:	5a75                	li	s4,-3
ffffffffc0204a70:	b3c1                	j	ffffffffc0204830 <do_execve+0x216>
        while (start < end)
ffffffffc0204a72:	86de                	mv	a3,s7
ffffffffc0204a74:	bf39                	j	ffffffffc0204992 <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204a76:	5a71                	li	s4,-4
ffffffffc0204a78:	bdc5                	j	ffffffffc0204968 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204a7a:	5a61                	li	s4,-8
ffffffffc0204a7c:	b5c5                	j	ffffffffc020495c <do_execve+0x342>
ffffffffc0204a7e:	00002617          	auipc	a2,0x2
ffffffffc0204a82:	a7260613          	addi	a2,a2,-1422 # ffffffffc02064f0 <default_pmm_manager+0x38>
ffffffffc0204a86:	07100593          	li	a1,113
ffffffffc0204a8a:	00002517          	auipc	a0,0x2
ffffffffc0204a8e:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0206518 <default_pmm_manager+0x60>
ffffffffc0204a92:	a01fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204a96:	00002617          	auipc	a2,0x2
ffffffffc0204a9a:	b0260613          	addi	a2,a2,-1278 # ffffffffc0206598 <default_pmm_manager+0xe0>
ffffffffc0204a9e:	2e900593          	li	a1,745
ffffffffc0204aa2:	00002517          	auipc	a0,0x2
ffffffffc0204aa6:	43650513          	addi	a0,a0,1078 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204aaa:	9e9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204aae:	00002697          	auipc	a3,0x2
ffffffffc0204ab2:	72a68693          	addi	a3,a3,1834 # ffffffffc02071d8 <default_pmm_manager+0xd20>
ffffffffc0204ab6:	00001617          	auipc	a2,0x1
ffffffffc0204aba:	65260613          	addi	a2,a2,1618 # ffffffffc0206108 <commands+0x818>
ffffffffc0204abe:	2e400593          	li	a1,740
ffffffffc0204ac2:	00002517          	auipc	a0,0x2
ffffffffc0204ac6:	41650513          	addi	a0,a0,1046 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204aca:	9c9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ace:	00002697          	auipc	a3,0x2
ffffffffc0204ad2:	6c268693          	addi	a3,a3,1730 # ffffffffc0207190 <default_pmm_manager+0xcd8>
ffffffffc0204ad6:	00001617          	auipc	a2,0x1
ffffffffc0204ada:	63260613          	addi	a2,a2,1586 # ffffffffc0206108 <commands+0x818>
ffffffffc0204ade:	2e300593          	li	a1,739
ffffffffc0204ae2:	00002517          	auipc	a0,0x2
ffffffffc0204ae6:	3f650513          	addi	a0,a0,1014 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204aea:	9a9fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204aee:	00002697          	auipc	a3,0x2
ffffffffc0204af2:	65a68693          	addi	a3,a3,1626 # ffffffffc0207148 <default_pmm_manager+0xc90>
ffffffffc0204af6:	00001617          	auipc	a2,0x1
ffffffffc0204afa:	61260613          	addi	a2,a2,1554 # ffffffffc0206108 <commands+0x818>
ffffffffc0204afe:	2e200593          	li	a1,738
ffffffffc0204b02:	00002517          	auipc	a0,0x2
ffffffffc0204b06:	3d650513          	addi	a0,a0,982 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204b0a:	989fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204b0e:	00002697          	auipc	a3,0x2
ffffffffc0204b12:	5f268693          	addi	a3,a3,1522 # ffffffffc0207100 <default_pmm_manager+0xc48>
ffffffffc0204b16:	00001617          	auipc	a2,0x1
ffffffffc0204b1a:	5f260613          	addi	a2,a2,1522 # ffffffffc0206108 <commands+0x818>
ffffffffc0204b1e:	2e100593          	li	a1,737
ffffffffc0204b22:	00002517          	auipc	a0,0x2
ffffffffc0204b26:	3b650513          	addi	a0,a0,950 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204b2a:	969fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204b2e <user_main>:
{
ffffffffc0204b2e:	1101                	addi	sp,sp,-32
ffffffffc0204b30:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204b32:	000c1917          	auipc	s2,0xc1
ffffffffc0204b36:	22690913          	addi	s2,s2,550 # ffffffffc02c5d58 <current>
ffffffffc0204b3a:	00093783          	ld	a5,0(s2)
ffffffffc0204b3e:	00002617          	auipc	a2,0x2
ffffffffc0204b42:	6e260613          	addi	a2,a2,1762 # ffffffffc0207220 <default_pmm_manager+0xd68>
ffffffffc0204b46:	00002517          	auipc	a0,0x2
ffffffffc0204b4a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0207230 <default_pmm_manager+0xd78>
ffffffffc0204b4e:	43cc                	lw	a1,4(a5)
{
ffffffffc0204b50:	ec06                	sd	ra,24(sp)
ffffffffc0204b52:	e822                	sd	s0,16(sp)
ffffffffc0204b54:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE(priority);
ffffffffc0204b56:	e42fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    size_t len = strlen(name);
ffffffffc0204b5a:	00002517          	auipc	a0,0x2
ffffffffc0204b5e:	6c650513          	addi	a0,a0,1734 # ffffffffc0207220 <default_pmm_manager+0xd68>
ffffffffc0204b62:	255000ef          	jal	ra,ffffffffc02055b6 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204b66:	00093783          	ld	a5,0(s2)
    size_t len = strlen(name);
ffffffffc0204b6a:	84aa                	mv	s1,a0
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204b6c:	12000613          	li	a2,288
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204b70:	6b80                	ld	s0,16(a5)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204b72:	73cc                	ld	a1,160(a5)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204b74:	6789                	lui	a5,0x2
ffffffffc0204b76:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x8070>
ffffffffc0204b7a:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204b7c:	8522                	mv	a0,s0
ffffffffc0204b7e:	2ed000ef          	jal	ra,ffffffffc020566a <memcpy>
    current->tf = new_tf;
ffffffffc0204b82:	00093783          	ld	a5,0(s2)
    ret = do_execve(name, len, binary, size);
ffffffffc0204b86:	3fe07697          	auipc	a3,0x3fe07
ffffffffc0204b8a:	bd268693          	addi	a3,a3,-1070 # b758 <_binary_obj___user_priority_out_size>
ffffffffc0204b8e:	0007c617          	auipc	a2,0x7c
ffffffffc0204b92:	28260613          	addi	a2,a2,642 # ffffffffc0280e10 <_binary_obj___user_priority_out_start>
    current->tf = new_tf;
ffffffffc0204b96:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204b98:	85a6                	mv	a1,s1
ffffffffc0204b9a:	00002517          	auipc	a0,0x2
ffffffffc0204b9e:	68650513          	addi	a0,a0,1670 # ffffffffc0207220 <default_pmm_manager+0xd68>
ffffffffc0204ba2:	a79ff0ef          	jal	ra,ffffffffc020461a <do_execve>
    asm volatile(
ffffffffc0204ba6:	8122                	mv	sp,s0
ffffffffc0204ba8:	a80fc06f          	j	ffffffffc0200e28 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204bac:	00002617          	auipc	a2,0x2
ffffffffc0204bb0:	6ac60613          	addi	a2,a2,1708 # ffffffffc0207258 <default_pmm_manager+0xda0>
ffffffffc0204bb4:	3d400593          	li	a1,980
ffffffffc0204bb8:	00002517          	auipc	a0,0x2
ffffffffc0204bbc:	32050513          	addi	a0,a0,800 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204bc0:	8d3fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204bc4 <do_yield>:
    current->need_resched = 1;
ffffffffc0204bc4:	000c1797          	auipc	a5,0xc1
ffffffffc0204bc8:	1947b783          	ld	a5,404(a5) # ffffffffc02c5d58 <current>
ffffffffc0204bcc:	4705                	li	a4,1
ffffffffc0204bce:	ef98                	sd	a4,24(a5)
}
ffffffffc0204bd0:	4501                	li	a0,0
ffffffffc0204bd2:	8082                	ret

ffffffffc0204bd4 <do_wait>:
{
ffffffffc0204bd4:	1101                	addi	sp,sp,-32
ffffffffc0204bd6:	e822                	sd	s0,16(sp)
ffffffffc0204bd8:	e426                	sd	s1,8(sp)
ffffffffc0204bda:	ec06                	sd	ra,24(sp)
ffffffffc0204bdc:	842e                	mv	s0,a1
ffffffffc0204bde:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204be0:	c999                	beqz	a1,ffffffffc0204bf6 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204be2:	000c1797          	auipc	a5,0xc1
ffffffffc0204be6:	1767b783          	ld	a5,374(a5) # ffffffffc02c5d58 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204bea:	7788                	ld	a0,40(a5)
ffffffffc0204bec:	4685                	li	a3,1
ffffffffc0204bee:	4611                	li	a2,4
ffffffffc0204bf0:	f4dfe0ef          	jal	ra,ffffffffc0203b3c <user_mem_check>
ffffffffc0204bf4:	c909                	beqz	a0,ffffffffc0204c06 <do_wait+0x32>
ffffffffc0204bf6:	85a2                	mv	a1,s0
}
ffffffffc0204bf8:	6442                	ld	s0,16(sp)
ffffffffc0204bfa:	60e2                	ld	ra,24(sp)
ffffffffc0204bfc:	8526                	mv	a0,s1
ffffffffc0204bfe:	64a2                	ld	s1,8(sp)
ffffffffc0204c00:	6105                	addi	sp,sp,32
ffffffffc0204c02:	f22ff06f          	j	ffffffffc0204324 <do_wait.part.0>
ffffffffc0204c06:	60e2                	ld	ra,24(sp)
ffffffffc0204c08:	6442                	ld	s0,16(sp)
ffffffffc0204c0a:	64a2                	ld	s1,8(sp)
ffffffffc0204c0c:	5575                	li	a0,-3
ffffffffc0204c0e:	6105                	addi	sp,sp,32
ffffffffc0204c10:	8082                	ret

ffffffffc0204c12 <do_kill>:
{
ffffffffc0204c12:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204c14:	6789                	lui	a5,0x2
{
ffffffffc0204c16:	e406                	sd	ra,8(sp)
ffffffffc0204c18:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204c1a:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204c1e:	17f9                	addi	a5,a5,-2
ffffffffc0204c20:	02e7e963          	bltu	a5,a4,ffffffffc0204c52 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204c24:	842a                	mv	s0,a0
ffffffffc0204c26:	45a9                	li	a1,10
ffffffffc0204c28:	2501                	sext.w	a0,a0
ffffffffc0204c2a:	588000ef          	jal	ra,ffffffffc02051b2 <hash32>
ffffffffc0204c2e:	02051793          	slli	a5,a0,0x20
ffffffffc0204c32:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204c36:	000bd797          	auipc	a5,0xbd
ffffffffc0204c3a:	08a78793          	addi	a5,a5,138 # ffffffffc02c1cc0 <hash_list>
ffffffffc0204c3e:	953e                	add	a0,a0,a5
ffffffffc0204c40:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204c42:	a029                	j	ffffffffc0204c4c <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204c44:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204c48:	00870b63          	beq	a4,s0,ffffffffc0204c5e <do_kill+0x4c>
ffffffffc0204c4c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204c4e:	fef51be3          	bne	a0,a5,ffffffffc0204c44 <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204c52:	5475                	li	s0,-3
}
ffffffffc0204c54:	60a2                	ld	ra,8(sp)
ffffffffc0204c56:	8522                	mv	a0,s0
ffffffffc0204c58:	6402                	ld	s0,0(sp)
ffffffffc0204c5a:	0141                	addi	sp,sp,16
ffffffffc0204c5c:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204c5e:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204c62:	00177693          	andi	a3,a4,1
ffffffffc0204c66:	e295                	bnez	a3,ffffffffc0204c8a <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204c68:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204c6a:	00176713          	ori	a4,a4,1
ffffffffc0204c6e:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204c72:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204c74:	fe06d0e3          	bgez	a3,ffffffffc0204c54 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204c78:	f2878513          	addi	a0,a5,-216
ffffffffc0204c7c:	2c4000ef          	jal	ra,ffffffffc0204f40 <wakeup_proc>
}
ffffffffc0204c80:	60a2                	ld	ra,8(sp)
ffffffffc0204c82:	8522                	mv	a0,s0
ffffffffc0204c84:	6402                	ld	s0,0(sp)
ffffffffc0204c86:	0141                	addi	sp,sp,16
ffffffffc0204c88:	8082                	ret
        return -E_KILLED;
ffffffffc0204c8a:	545d                	li	s0,-9
ffffffffc0204c8c:	b7e1                	j	ffffffffc0204c54 <do_kill+0x42>

ffffffffc0204c8e <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204c8e:	1101                	addi	sp,sp,-32
ffffffffc0204c90:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204c92:	000c1797          	auipc	a5,0xc1
ffffffffc0204c96:	02e78793          	addi	a5,a5,46 # ffffffffc02c5cc0 <proc_list>
ffffffffc0204c9a:	ec06                	sd	ra,24(sp)
ffffffffc0204c9c:	e822                	sd	s0,16(sp)
ffffffffc0204c9e:	e04a                	sd	s2,0(sp)
ffffffffc0204ca0:	000bd497          	auipc	s1,0xbd
ffffffffc0204ca4:	02048493          	addi	s1,s1,32 # ffffffffc02c1cc0 <hash_list>
ffffffffc0204ca8:	e79c                	sd	a5,8(a5)
ffffffffc0204caa:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204cac:	000c1717          	auipc	a4,0xc1
ffffffffc0204cb0:	01470713          	addi	a4,a4,20 # ffffffffc02c5cc0 <proc_list>
ffffffffc0204cb4:	87a6                	mv	a5,s1
ffffffffc0204cb6:	e79c                	sd	a5,8(a5)
ffffffffc0204cb8:	e39c                	sd	a5,0(a5)
ffffffffc0204cba:	07c1                	addi	a5,a5,16
ffffffffc0204cbc:	fef71de3          	bne	a4,a5,ffffffffc0204cb6 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204cc0:	f19fe0ef          	jal	ra,ffffffffc0203bd8 <alloc_proc>
ffffffffc0204cc4:	000c1917          	auipc	s2,0xc1
ffffffffc0204cc8:	09c90913          	addi	s2,s2,156 # ffffffffc02c5d60 <idleproc>
ffffffffc0204ccc:	00a93023          	sd	a0,0(s2)
ffffffffc0204cd0:	0e050f63          	beqz	a0,ffffffffc0204dce <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204cd4:	4789                	li	a5,2
ffffffffc0204cd6:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204cd8:	00003797          	auipc	a5,0x3
ffffffffc0204cdc:	32878793          	addi	a5,a5,808 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ce0:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204ce4:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204ce6:	4785                	li	a5,1
ffffffffc0204ce8:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204cea:	4641                	li	a2,16
ffffffffc0204cec:	4581                	li	a1,0
ffffffffc0204cee:	8522                	mv	a0,s0
ffffffffc0204cf0:	169000ef          	jal	ra,ffffffffc0205658 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204cf4:	463d                	li	a2,15
ffffffffc0204cf6:	00002597          	auipc	a1,0x2
ffffffffc0204cfa:	59a58593          	addi	a1,a1,1434 # ffffffffc0207290 <default_pmm_manager+0xdd8>
ffffffffc0204cfe:	8522                	mv	a0,s0
ffffffffc0204d00:	16b000ef          	jal	ra,ffffffffc020566a <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204d04:	000c1717          	auipc	a4,0xc1
ffffffffc0204d08:	06c70713          	addi	a4,a4,108 # ffffffffc02c5d70 <nr_process>
ffffffffc0204d0c:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204d0e:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204d12:	4601                	li	a2,0
    nr_process++;
ffffffffc0204d14:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204d16:	4581                	li	a1,0
ffffffffc0204d18:	fffff517          	auipc	a0,0xfffff
ffffffffc0204d1c:	7de50513          	addi	a0,a0,2014 # ffffffffc02044f6 <init_main>
    nr_process++;
ffffffffc0204d20:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204d22:	000c1797          	auipc	a5,0xc1
ffffffffc0204d26:	02d7bb23          	sd	a3,54(a5) # ffffffffc02c5d58 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204d2a:	c60ff0ef          	jal	ra,ffffffffc020418a <kernel_thread>
ffffffffc0204d2e:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204d30:	08a05363          	blez	a0,ffffffffc0204db6 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204d34:	6789                	lui	a5,0x2
ffffffffc0204d36:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204d3a:	17f9                	addi	a5,a5,-2
ffffffffc0204d3c:	2501                	sext.w	a0,a0
ffffffffc0204d3e:	02e7e363          	bltu	a5,a4,ffffffffc0204d64 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204d42:	45a9                	li	a1,10
ffffffffc0204d44:	46e000ef          	jal	ra,ffffffffc02051b2 <hash32>
ffffffffc0204d48:	02051793          	slli	a5,a0,0x20
ffffffffc0204d4c:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204d50:	96a6                	add	a3,a3,s1
ffffffffc0204d52:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204d54:	a029                	j	ffffffffc0204d5e <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204d56:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x8024>
ffffffffc0204d5a:	04870b63          	beq	a4,s0,ffffffffc0204db0 <proc_init+0x122>
    return listelm->next;
ffffffffc0204d5e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204d60:	fef69be3          	bne	a3,a5,ffffffffc0204d56 <proc_init+0xc8>
    return NULL;
ffffffffc0204d64:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d66:	0b478493          	addi	s1,a5,180
ffffffffc0204d6a:	4641                	li	a2,16
ffffffffc0204d6c:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204d6e:	000c1417          	auipc	s0,0xc1
ffffffffc0204d72:	ffa40413          	addi	s0,s0,-6 # ffffffffc02c5d68 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d76:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204d78:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204d7a:	0df000ef          	jal	ra,ffffffffc0205658 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204d7e:	463d                	li	a2,15
ffffffffc0204d80:	00002597          	auipc	a1,0x2
ffffffffc0204d84:	53858593          	addi	a1,a1,1336 # ffffffffc02072b8 <default_pmm_manager+0xe00>
ffffffffc0204d88:	8526                	mv	a0,s1
ffffffffc0204d8a:	0e1000ef          	jal	ra,ffffffffc020566a <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204d8e:	00093783          	ld	a5,0(s2)
ffffffffc0204d92:	cbb5                	beqz	a5,ffffffffc0204e06 <proc_init+0x178>
ffffffffc0204d94:	43dc                	lw	a5,4(a5)
ffffffffc0204d96:	eba5                	bnez	a5,ffffffffc0204e06 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204d98:	601c                	ld	a5,0(s0)
ffffffffc0204d9a:	c7b1                	beqz	a5,ffffffffc0204de6 <proc_init+0x158>
ffffffffc0204d9c:	43d8                	lw	a4,4(a5)
ffffffffc0204d9e:	4785                	li	a5,1
ffffffffc0204da0:	04f71363          	bne	a4,a5,ffffffffc0204de6 <proc_init+0x158>
}
ffffffffc0204da4:	60e2                	ld	ra,24(sp)
ffffffffc0204da6:	6442                	ld	s0,16(sp)
ffffffffc0204da8:	64a2                	ld	s1,8(sp)
ffffffffc0204daa:	6902                	ld	s2,0(sp)
ffffffffc0204dac:	6105                	addi	sp,sp,32
ffffffffc0204dae:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204db0:	f2878793          	addi	a5,a5,-216
ffffffffc0204db4:	bf4d                	j	ffffffffc0204d66 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0204db6:	00002617          	auipc	a2,0x2
ffffffffc0204dba:	4e260613          	addi	a2,a2,1250 # ffffffffc0207298 <default_pmm_manager+0xde0>
ffffffffc0204dbe:	41000593          	li	a1,1040
ffffffffc0204dc2:	00002517          	auipc	a0,0x2
ffffffffc0204dc6:	11650513          	addi	a0,a0,278 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204dca:	ec8fb0ef          	jal	ra,ffffffffc0200492 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0204dce:	00002617          	auipc	a2,0x2
ffffffffc0204dd2:	4aa60613          	addi	a2,a2,1194 # ffffffffc0207278 <default_pmm_manager+0xdc0>
ffffffffc0204dd6:	40100593          	li	a1,1025
ffffffffc0204dda:	00002517          	auipc	a0,0x2
ffffffffc0204dde:	0fe50513          	addi	a0,a0,254 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204de2:	eb0fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204de6:	00002697          	auipc	a3,0x2
ffffffffc0204dea:	50268693          	addi	a3,a3,1282 # ffffffffc02072e8 <default_pmm_manager+0xe30>
ffffffffc0204dee:	00001617          	auipc	a2,0x1
ffffffffc0204df2:	31a60613          	addi	a2,a2,794 # ffffffffc0206108 <commands+0x818>
ffffffffc0204df6:	41700593          	li	a1,1047
ffffffffc0204dfa:	00002517          	auipc	a0,0x2
ffffffffc0204dfe:	0de50513          	addi	a0,a0,222 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204e02:	e90fb0ef          	jal	ra,ffffffffc0200492 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204e06:	00002697          	auipc	a3,0x2
ffffffffc0204e0a:	4ba68693          	addi	a3,a3,1210 # ffffffffc02072c0 <default_pmm_manager+0xe08>
ffffffffc0204e0e:	00001617          	auipc	a2,0x1
ffffffffc0204e12:	2fa60613          	addi	a2,a2,762 # ffffffffc0206108 <commands+0x818>
ffffffffc0204e16:	41600593          	li	a1,1046
ffffffffc0204e1a:	00002517          	auipc	a0,0x2
ffffffffc0204e1e:	0be50513          	addi	a0,a0,190 # ffffffffc0206ed8 <default_pmm_manager+0xa20>
ffffffffc0204e22:	e70fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204e26 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0204e26:	1141                	addi	sp,sp,-16
ffffffffc0204e28:	e022                	sd	s0,0(sp)
ffffffffc0204e2a:	e406                	sd	ra,8(sp)
ffffffffc0204e2c:	000c1417          	auipc	s0,0xc1
ffffffffc0204e30:	f2c40413          	addi	s0,s0,-212 # ffffffffc02c5d58 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0204e34:	6018                	ld	a4,0(s0)
ffffffffc0204e36:	6f1c                	ld	a5,24(a4)
ffffffffc0204e38:	dffd                	beqz	a5,ffffffffc0204e36 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0204e3a:	1b8000ef          	jal	ra,ffffffffc0204ff2 <schedule>
ffffffffc0204e3e:	bfdd                	j	ffffffffc0204e34 <cpu_idle+0xe>

ffffffffc0204e40 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc0204e40:	1141                	addi	sp,sp,-16
ffffffffc0204e42:	e022                	sd	s0,0(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204e44:	85aa                	mv	a1,a0
{
ffffffffc0204e46:	842a                	mv	s0,a0
    cprintf("set priority to %d\n", priority);
ffffffffc0204e48:	00002517          	auipc	a0,0x2
ffffffffc0204e4c:	4c850513          	addi	a0,a0,1224 # ffffffffc0207310 <default_pmm_manager+0xe58>
{
ffffffffc0204e50:	e406                	sd	ra,8(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc0204e52:	b46fb0ef          	jal	ra,ffffffffc0200198 <cprintf>
    if (priority == 0)
        current->lab6_priority = 1;
ffffffffc0204e56:	000c1797          	auipc	a5,0xc1
ffffffffc0204e5a:	f027b783          	ld	a5,-254(a5) # ffffffffc02c5d58 <current>
    if (priority == 0)
ffffffffc0204e5e:	e801                	bnez	s0,ffffffffc0204e6e <lab6_set_priority+0x2e>
    else
        current->lab6_priority = priority;
}
ffffffffc0204e60:	60a2                	ld	ra,8(sp)
ffffffffc0204e62:	6402                	ld	s0,0(sp)
        current->lab6_priority = 1;
ffffffffc0204e64:	4705                	li	a4,1
ffffffffc0204e66:	14e7a223          	sw	a4,324(a5)
}
ffffffffc0204e6a:	0141                	addi	sp,sp,16
ffffffffc0204e6c:	8082                	ret
ffffffffc0204e6e:	60a2                	ld	ra,8(sp)
        current->lab6_priority = priority;
ffffffffc0204e70:	1487a223          	sw	s0,324(a5)
}
ffffffffc0204e74:	6402                	ld	s0,0(sp)
ffffffffc0204e76:	0141                	addi	sp,sp,16
ffffffffc0204e78:	8082                	ret

ffffffffc0204e7a <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204e7a:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204e7e:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204e82:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204e84:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204e86:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204e8a:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204e8e:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204e92:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204e96:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204e9a:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204e9e:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204ea2:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204ea6:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204eaa:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204eae:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204eb2:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204eb6:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204eb8:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204eba:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204ebe:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204ec2:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204ec6:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204eca:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204ece:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204ed2:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204ed6:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204eda:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204ede:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204ee2:	8082                	ret

ffffffffc0204ee4 <RR_init>:
 */
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
}
ffffffffc0204ee4:	8082                	ret

ffffffffc0204ee6 <RR_enqueue>:
 */
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
}
ffffffffc0204ee6:	8082                	ret

ffffffffc0204ee8 <RR_pick_next>:
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
}
ffffffffc0204ee8:	8082                	ret

ffffffffc0204eea <RR_dequeue>:
ffffffffc0204eea:	8082                	ret

ffffffffc0204eec <RR_proc_tick>:
ffffffffc0204eec:	8082                	ret

ffffffffc0204eee <sched_init>:
}

static struct run_queue __rq;

void sched_init(void)
{
ffffffffc0204eee:	1141                	addi	sp,sp,-16
    list_init(&timer_list);

    sched_class = &default_sched_class;
ffffffffc0204ef0:	000bd717          	auipc	a4,0xbd
ffffffffc0204ef4:	97870713          	addi	a4,a4,-1672 # ffffffffc02c1868 <default_sched_class>
{
ffffffffc0204ef8:	e022                	sd	s0,0(sp)
ffffffffc0204efa:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204efc:	000c1797          	auipc	a5,0xc1
ffffffffc0204f00:	df478793          	addi	a5,a5,-524 # ffffffffc02c5cf0 <timer_list>

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc0204f04:	6714                	ld	a3,8(a4)
    rq = &__rq;
ffffffffc0204f06:	000c1517          	auipc	a0,0xc1
ffffffffc0204f0a:	dca50513          	addi	a0,a0,-566 # ffffffffc02c5cd0 <__rq>
ffffffffc0204f0e:	e79c                	sd	a5,8(a5)
ffffffffc0204f10:	e39c                	sd	a5,0(a5)
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0204f12:	4795                	li	a5,5
ffffffffc0204f14:	c95c                	sw	a5,20(a0)
    sched_class = &default_sched_class;
ffffffffc0204f16:	000c1417          	auipc	s0,0xc1
ffffffffc0204f1a:	e6a40413          	addi	s0,s0,-406 # ffffffffc02c5d80 <sched_class>
    rq = &__rq;
ffffffffc0204f1e:	000c1797          	auipc	a5,0xc1
ffffffffc0204f22:	e4a7bd23          	sd	a0,-422(a5) # ffffffffc02c5d78 <rq>
    sched_class = &default_sched_class;
ffffffffc0204f26:	e018                	sd	a4,0(s0)
    sched_class->init(rq);
ffffffffc0204f28:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0204f2a:	601c                	ld	a5,0(s0)
}
ffffffffc0204f2c:	6402                	ld	s0,0(sp)
ffffffffc0204f2e:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0204f30:	638c                	ld	a1,0(a5)
ffffffffc0204f32:	00002517          	auipc	a0,0x2
ffffffffc0204f36:	40650513          	addi	a0,a0,1030 # ffffffffc0207338 <default_pmm_manager+0xe80>
}
ffffffffc0204f3a:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0204f3c:	a5cfb06f          	j	ffffffffc0200198 <cprintf>

ffffffffc0204f40 <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204f40:	4118                	lw	a4,0(a0)
{
ffffffffc0204f42:	1101                	addi	sp,sp,-32
ffffffffc0204f44:	ec06                	sd	ra,24(sp)
ffffffffc0204f46:	e822                	sd	s0,16(sp)
ffffffffc0204f48:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204f4a:	478d                	li	a5,3
ffffffffc0204f4c:	08f70363          	beq	a4,a5,ffffffffc0204fd2 <wakeup_proc+0x92>
ffffffffc0204f50:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204f52:	100027f3          	csrr	a5,sstatus
ffffffffc0204f56:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204f58:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204f5a:	e7bd                	bnez	a5,ffffffffc0204fc8 <wakeup_proc+0x88>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0204f5c:	4789                	li	a5,2
ffffffffc0204f5e:	04f70863          	beq	a4,a5,ffffffffc0204fae <wakeup_proc+0x6e>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0204f62:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0204f64:	0e042623          	sw	zero,236(s0)
            if (proc != current)
ffffffffc0204f68:	000c1797          	auipc	a5,0xc1
ffffffffc0204f6c:	df07b783          	ld	a5,-528(a5) # ffffffffc02c5d58 <current>
ffffffffc0204f70:	02878363          	beq	a5,s0,ffffffffc0204f96 <wakeup_proc+0x56>
    if (proc != idleproc)
ffffffffc0204f74:	000c1797          	auipc	a5,0xc1
ffffffffc0204f78:	dec7b783          	ld	a5,-532(a5) # ffffffffc02c5d60 <idleproc>
ffffffffc0204f7c:	00f40d63          	beq	s0,a5,ffffffffc0204f96 <wakeup_proc+0x56>
        sched_class->enqueue(rq, proc);
ffffffffc0204f80:	000c1797          	auipc	a5,0xc1
ffffffffc0204f84:	e007b783          	ld	a5,-512(a5) # ffffffffc02c5d80 <sched_class>
ffffffffc0204f88:	6b9c                	ld	a5,16(a5)
ffffffffc0204f8a:	85a2                	mv	a1,s0
ffffffffc0204f8c:	000c1517          	auipc	a0,0xc1
ffffffffc0204f90:	dec53503          	ld	a0,-532(a0) # ffffffffc02c5d78 <rq>
ffffffffc0204f94:	9782                	jalr	a5
    if (flag)
ffffffffc0204f96:	e491                	bnez	s1,ffffffffc0204fa2 <wakeup_proc+0x62>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0204f98:	60e2                	ld	ra,24(sp)
ffffffffc0204f9a:	6442                	ld	s0,16(sp)
ffffffffc0204f9c:	64a2                	ld	s1,8(sp)
ffffffffc0204f9e:	6105                	addi	sp,sp,32
ffffffffc0204fa0:	8082                	ret
ffffffffc0204fa2:	6442                	ld	s0,16(sp)
ffffffffc0204fa4:	60e2                	ld	ra,24(sp)
ffffffffc0204fa6:	64a2                	ld	s1,8(sp)
ffffffffc0204fa8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204faa:	9e7fb06f          	j	ffffffffc0200990 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0204fae:	00002617          	auipc	a2,0x2
ffffffffc0204fb2:	3da60613          	addi	a2,a2,986 # ffffffffc0207388 <default_pmm_manager+0xed0>
ffffffffc0204fb6:	05100593          	li	a1,81
ffffffffc0204fba:	00002517          	auipc	a0,0x2
ffffffffc0204fbe:	3b650513          	addi	a0,a0,950 # ffffffffc0207370 <default_pmm_manager+0xeb8>
ffffffffc0204fc2:	d38fb0ef          	jal	ra,ffffffffc02004fa <__warn>
ffffffffc0204fc6:	bfc1                	j	ffffffffc0204f96 <wakeup_proc+0x56>
        intr_disable();
ffffffffc0204fc8:	9cffb0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0204fcc:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0204fce:	4485                	li	s1,1
ffffffffc0204fd0:	b771                	j	ffffffffc0204f5c <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0204fd2:	00002697          	auipc	a3,0x2
ffffffffc0204fd6:	37e68693          	addi	a3,a3,894 # ffffffffc0207350 <default_pmm_manager+0xe98>
ffffffffc0204fda:	00001617          	auipc	a2,0x1
ffffffffc0204fde:	12e60613          	addi	a2,a2,302 # ffffffffc0206108 <commands+0x818>
ffffffffc0204fe2:	04200593          	li	a1,66
ffffffffc0204fe6:	00002517          	auipc	a0,0x2
ffffffffc0204fea:	38a50513          	addi	a0,a0,906 # ffffffffc0207370 <default_pmm_manager+0xeb8>
ffffffffc0204fee:	ca4fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc0204ff2 <schedule>:

void schedule(void)
{
ffffffffc0204ff2:	7179                	addi	sp,sp,-48
ffffffffc0204ff4:	f406                	sd	ra,40(sp)
ffffffffc0204ff6:	f022                	sd	s0,32(sp)
ffffffffc0204ff8:	ec26                	sd	s1,24(sp)
ffffffffc0204ffa:	e84a                	sd	s2,16(sp)
ffffffffc0204ffc:	e44e                	sd	s3,8(sp)
ffffffffc0204ffe:	e052                	sd	s4,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205000:	100027f3          	csrr	a5,sstatus
ffffffffc0205004:	8b89                	andi	a5,a5,2
ffffffffc0205006:	4a01                	li	s4,0
ffffffffc0205008:	e3cd                	bnez	a5,ffffffffc02050aa <schedule+0xb8>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020500a:	000c1497          	auipc	s1,0xc1
ffffffffc020500e:	d4e48493          	addi	s1,s1,-690 # ffffffffc02c5d58 <current>
ffffffffc0205012:	608c                	ld	a1,0(s1)
        sched_class->enqueue(rq, proc);
ffffffffc0205014:	000c1997          	auipc	s3,0xc1
ffffffffc0205018:	d6c98993          	addi	s3,s3,-660 # ffffffffc02c5d80 <sched_class>
ffffffffc020501c:	000c1917          	auipc	s2,0xc1
ffffffffc0205020:	d5c90913          	addi	s2,s2,-676 # ffffffffc02c5d78 <rq>
        if (current->state == PROC_RUNNABLE)
ffffffffc0205024:	4194                	lw	a3,0(a1)
        current->need_resched = 0;
ffffffffc0205026:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc020502a:	4709                	li	a4,2
        sched_class->enqueue(rq, proc);
ffffffffc020502c:	0009b783          	ld	a5,0(s3)
ffffffffc0205030:	00093503          	ld	a0,0(s2)
        if (current->state == PROC_RUNNABLE)
ffffffffc0205034:	04e68e63          	beq	a3,a4,ffffffffc0205090 <schedule+0x9e>
    return sched_class->pick_next(rq);
ffffffffc0205038:	739c                	ld	a5,32(a5)
ffffffffc020503a:	9782                	jalr	a5
ffffffffc020503c:	842a                	mv	s0,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc020503e:	c521                	beqz	a0,ffffffffc0205086 <schedule+0x94>
    sched_class->dequeue(rq, proc);
ffffffffc0205040:	0009b783          	ld	a5,0(s3)
ffffffffc0205044:	00093503          	ld	a0,0(s2)
ffffffffc0205048:	85a2                	mv	a1,s0
ffffffffc020504a:	6f9c                	ld	a5,24(a5)
ffffffffc020504c:	9782                	jalr	a5
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc020504e:	441c                	lw	a5,8(s0)
        if (next != current)
ffffffffc0205050:	6098                	ld	a4,0(s1)
        next->runs++;
ffffffffc0205052:	2785                	addiw	a5,a5,1
ffffffffc0205054:	c41c                	sw	a5,8(s0)
        if (next != current)
ffffffffc0205056:	00870563          	beq	a4,s0,ffffffffc0205060 <schedule+0x6e>
        {
            proc_run(next);
ffffffffc020505a:	8522                	mv	a0,s0
ffffffffc020505c:	c97fe0ef          	jal	ra,ffffffffc0203cf2 <proc_run>
    if (flag)
ffffffffc0205060:	000a1a63          	bnez	s4,ffffffffc0205074 <schedule+0x82>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205064:	70a2                	ld	ra,40(sp)
ffffffffc0205066:	7402                	ld	s0,32(sp)
ffffffffc0205068:	64e2                	ld	s1,24(sp)
ffffffffc020506a:	6942                	ld	s2,16(sp)
ffffffffc020506c:	69a2                	ld	s3,8(sp)
ffffffffc020506e:	6a02                	ld	s4,0(sp)
ffffffffc0205070:	6145                	addi	sp,sp,48
ffffffffc0205072:	8082                	ret
ffffffffc0205074:	7402                	ld	s0,32(sp)
ffffffffc0205076:	70a2                	ld	ra,40(sp)
ffffffffc0205078:	64e2                	ld	s1,24(sp)
ffffffffc020507a:	6942                	ld	s2,16(sp)
ffffffffc020507c:	69a2                	ld	s3,8(sp)
ffffffffc020507e:	6a02                	ld	s4,0(sp)
ffffffffc0205080:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0205082:	90ffb06f          	j	ffffffffc0200990 <intr_enable>
            next = idleproc;
ffffffffc0205086:	000c1417          	auipc	s0,0xc1
ffffffffc020508a:	cda43403          	ld	s0,-806(s0) # ffffffffc02c5d60 <idleproc>
ffffffffc020508e:	b7c1                	j	ffffffffc020504e <schedule+0x5c>
    if (proc != idleproc)
ffffffffc0205090:	000c1717          	auipc	a4,0xc1
ffffffffc0205094:	cd073703          	ld	a4,-816(a4) # ffffffffc02c5d60 <idleproc>
ffffffffc0205098:	fae580e3          	beq	a1,a4,ffffffffc0205038 <schedule+0x46>
        sched_class->enqueue(rq, proc);
ffffffffc020509c:	6b9c                	ld	a5,16(a5)
ffffffffc020509e:	9782                	jalr	a5
    return sched_class->pick_next(rq);
ffffffffc02050a0:	0009b783          	ld	a5,0(s3)
ffffffffc02050a4:	00093503          	ld	a0,0(s2)
ffffffffc02050a8:	bf41                	j	ffffffffc0205038 <schedule+0x46>
        intr_disable();
ffffffffc02050aa:	8edfb0ef          	jal	ra,ffffffffc0200996 <intr_disable>
        return 1;
ffffffffc02050ae:	4a05                	li	s4,1
ffffffffc02050b0:	bfa9                	j	ffffffffc020500a <schedule+0x18>

ffffffffc02050b2 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02050b2:	000c1797          	auipc	a5,0xc1
ffffffffc02050b6:	ca67b783          	ld	a5,-858(a5) # ffffffffc02c5d58 <current>
}
ffffffffc02050ba:	43c8                	lw	a0,4(a5)
ffffffffc02050bc:	8082                	ret

ffffffffc02050be <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02050be:	4501                	li	a0,0
ffffffffc02050c0:	8082                	ret

ffffffffc02050c2 <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc02050c2:	000c1797          	auipc	a5,0xc1
ffffffffc02050c6:	c467b783          	ld	a5,-954(a5) # ffffffffc02c5d08 <ticks>
ffffffffc02050ca:	0027951b          	slliw	a0,a5,0x2
ffffffffc02050ce:	9d3d                	addw	a0,a0,a5
}
ffffffffc02050d0:	0015151b          	slliw	a0,a0,0x1
ffffffffc02050d4:	8082                	ret

ffffffffc02050d6 <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc02050d6:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc02050d8:	1141                	addi	sp,sp,-16
ffffffffc02050da:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc02050dc:	d65ff0ef          	jal	ra,ffffffffc0204e40 <lab6_set_priority>
    return 0;
}
ffffffffc02050e0:	60a2                	ld	ra,8(sp)
ffffffffc02050e2:	4501                	li	a0,0
ffffffffc02050e4:	0141                	addi	sp,sp,16
ffffffffc02050e6:	8082                	ret

ffffffffc02050e8 <sys_putc>:
    cputchar(c);
ffffffffc02050e8:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02050ea:	1141                	addi	sp,sp,-16
ffffffffc02050ec:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02050ee:	8e0fb0ef          	jal	ra,ffffffffc02001ce <cputchar>
}
ffffffffc02050f2:	60a2                	ld	ra,8(sp)
ffffffffc02050f4:	4501                	li	a0,0
ffffffffc02050f6:	0141                	addi	sp,sp,16
ffffffffc02050f8:	8082                	ret

ffffffffc02050fa <sys_kill>:
    return do_kill(pid);
ffffffffc02050fa:	4108                	lw	a0,0(a0)
ffffffffc02050fc:	b17ff06f          	j	ffffffffc0204c12 <do_kill>

ffffffffc0205100 <sys_yield>:
    return do_yield();
ffffffffc0205100:	ac5ff06f          	j	ffffffffc0204bc4 <do_yield>

ffffffffc0205104 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205104:	6d14                	ld	a3,24(a0)
ffffffffc0205106:	6910                	ld	a2,16(a0)
ffffffffc0205108:	650c                	ld	a1,8(a0)
ffffffffc020510a:	6108                	ld	a0,0(a0)
ffffffffc020510c:	d0eff06f          	j	ffffffffc020461a <do_execve>

ffffffffc0205110 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205110:	650c                	ld	a1,8(a0)
ffffffffc0205112:	4108                	lw	a0,0(a0)
ffffffffc0205114:	ac1ff06f          	j	ffffffffc0204bd4 <do_wait>

ffffffffc0205118 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205118:	000c1797          	auipc	a5,0xc1
ffffffffc020511c:	c407b783          	ld	a5,-960(a5) # ffffffffc02c5d58 <current>
ffffffffc0205120:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205122:	4501                	li	a0,0
ffffffffc0205124:	6a0c                	ld	a1,16(a2)
ffffffffc0205126:	c61fe06f          	j	ffffffffc0203d86 <do_fork>

ffffffffc020512a <sys_exit>:
    return do_exit(error_code);
ffffffffc020512a:	4108                	lw	a0,0(a0)
ffffffffc020512c:	8aeff06f          	j	ffffffffc02041da <do_exit>

ffffffffc0205130 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205130:	715d                	addi	sp,sp,-80
ffffffffc0205132:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205134:	000c1497          	auipc	s1,0xc1
ffffffffc0205138:	c2448493          	addi	s1,s1,-988 # ffffffffc02c5d58 <current>
ffffffffc020513c:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020513e:	e0a2                	sd	s0,64(sp)
ffffffffc0205140:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205142:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205144:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205146:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc020514a:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020514e:	0327ee63          	bltu	a5,s2,ffffffffc020518a <syscall+0x5a>
        if (syscalls[num] != NULL) {
ffffffffc0205152:	00391713          	slli	a4,s2,0x3
ffffffffc0205156:	00002797          	auipc	a5,0x2
ffffffffc020515a:	29a78793          	addi	a5,a5,666 # ffffffffc02073f0 <syscalls>
ffffffffc020515e:	97ba                	add	a5,a5,a4
ffffffffc0205160:	639c                	ld	a5,0(a5)
ffffffffc0205162:	c785                	beqz	a5,ffffffffc020518a <syscall+0x5a>
            arg[0] = tf->gpr.a1;
ffffffffc0205164:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205166:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205168:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020516a:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc020516c:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc020516e:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205170:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205172:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205174:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205176:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205178:	0028                	addi	a0,sp,8
ffffffffc020517a:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020517c:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020517e:	e828                	sd	a0,80(s0)
}
ffffffffc0205180:	6406                	ld	s0,64(sp)
ffffffffc0205182:	74e2                	ld	s1,56(sp)
ffffffffc0205184:	7942                	ld	s2,48(sp)
ffffffffc0205186:	6161                	addi	sp,sp,80
ffffffffc0205188:	8082                	ret
    print_trapframe(tf);
ffffffffc020518a:	8522                	mv	a0,s0
ffffffffc020518c:	9fbfb0ef          	jal	ra,ffffffffc0200b86 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205190:	609c                	ld	a5,0(s1)
ffffffffc0205192:	86ca                	mv	a3,s2
ffffffffc0205194:	00002617          	auipc	a2,0x2
ffffffffc0205198:	21460613          	addi	a2,a2,532 # ffffffffc02073a8 <default_pmm_manager+0xef0>
ffffffffc020519c:	43d8                	lw	a4,4(a5)
ffffffffc020519e:	06c00593          	li	a1,108
ffffffffc02051a2:	0b478793          	addi	a5,a5,180
ffffffffc02051a6:	00002517          	auipc	a0,0x2
ffffffffc02051aa:	23250513          	addi	a0,a0,562 # ffffffffc02073d8 <default_pmm_manager+0xf20>
ffffffffc02051ae:	ae4fb0ef          	jal	ra,ffffffffc0200492 <__panic>

ffffffffc02051b2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02051b2:	9e3707b7          	lui	a5,0x9e370
ffffffffc02051b6:	2785                	addiw	a5,a5,1
ffffffffc02051b8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02051bc:	02000793          	li	a5,32
ffffffffc02051c0:	9f8d                	subw	a5,a5,a1
}
ffffffffc02051c2:	00f5553b          	srlw	a0,a0,a5
ffffffffc02051c6:	8082                	ret

ffffffffc02051c8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02051c8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02051cc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02051ce:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02051d2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02051d4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02051d8:	f022                	sd	s0,32(sp)
ffffffffc02051da:	ec26                	sd	s1,24(sp)
ffffffffc02051dc:	e84a                	sd	s2,16(sp)
ffffffffc02051de:	f406                	sd	ra,40(sp)
ffffffffc02051e0:	e44e                	sd	s3,8(sp)
ffffffffc02051e2:	84aa                	mv	s1,a0
ffffffffc02051e4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02051e6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02051ea:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02051ec:	03067e63          	bgeu	a2,a6,ffffffffc0205228 <printnum+0x60>
ffffffffc02051f0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02051f2:	00805763          	blez	s0,ffffffffc0205200 <printnum+0x38>
ffffffffc02051f6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02051f8:	85ca                	mv	a1,s2
ffffffffc02051fa:	854e                	mv	a0,s3
ffffffffc02051fc:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02051fe:	fc65                	bnez	s0,ffffffffc02051f6 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205200:	1a02                	slli	s4,s4,0x20
ffffffffc0205202:	00003797          	auipc	a5,0x3
ffffffffc0205206:	9ee78793          	addi	a5,a5,-1554 # ffffffffc0207bf0 <syscalls+0x800>
ffffffffc020520a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020520e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc0205210:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205212:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205216:	70a2                	ld	ra,40(sp)
ffffffffc0205218:	69a2                	ld	s3,8(sp)
ffffffffc020521a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020521c:	85ca                	mv	a1,s2
ffffffffc020521e:	87a6                	mv	a5,s1
}
ffffffffc0205220:	6942                	ld	s2,16(sp)
ffffffffc0205222:	64e2                	ld	s1,24(sp)
ffffffffc0205224:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205226:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205228:	03065633          	divu	a2,a2,a6
ffffffffc020522c:	8722                	mv	a4,s0
ffffffffc020522e:	f9bff0ef          	jal	ra,ffffffffc02051c8 <printnum>
ffffffffc0205232:	b7f9                	j	ffffffffc0205200 <printnum+0x38>

ffffffffc0205234 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0205234:	7119                	addi	sp,sp,-128
ffffffffc0205236:	f4a6                	sd	s1,104(sp)
ffffffffc0205238:	f0ca                	sd	s2,96(sp)
ffffffffc020523a:	ecce                	sd	s3,88(sp)
ffffffffc020523c:	e8d2                	sd	s4,80(sp)
ffffffffc020523e:	e4d6                	sd	s5,72(sp)
ffffffffc0205240:	e0da                	sd	s6,64(sp)
ffffffffc0205242:	fc5e                	sd	s7,56(sp)
ffffffffc0205244:	f06a                	sd	s10,32(sp)
ffffffffc0205246:	fc86                	sd	ra,120(sp)
ffffffffc0205248:	f8a2                	sd	s0,112(sp)
ffffffffc020524a:	f862                	sd	s8,48(sp)
ffffffffc020524c:	f466                	sd	s9,40(sp)
ffffffffc020524e:	ec6e                	sd	s11,24(sp)
ffffffffc0205250:	892a                	mv	s2,a0
ffffffffc0205252:	84ae                	mv	s1,a1
ffffffffc0205254:	8d32                	mv	s10,a2
ffffffffc0205256:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205258:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020525c:	5b7d                	li	s6,-1
ffffffffc020525e:	00003a97          	auipc	s5,0x3
ffffffffc0205262:	9bea8a93          	addi	s5,s5,-1602 # ffffffffc0207c1c <syscalls+0x82c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205266:	00003b97          	auipc	s7,0x3
ffffffffc020526a:	bd2b8b93          	addi	s7,s7,-1070 # ffffffffc0207e38 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020526e:	000d4503          	lbu	a0,0(s10)
ffffffffc0205272:	001d0413          	addi	s0,s10,1
ffffffffc0205276:	01350a63          	beq	a0,s3,ffffffffc020528a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020527a:	c121                	beqz	a0,ffffffffc02052ba <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020527c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020527e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0205280:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205282:	fff44503          	lbu	a0,-1(s0)
ffffffffc0205286:	ff351ae3          	bne	a0,s3,ffffffffc020527a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020528a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020528e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0205292:	4c81                	li	s9,0
ffffffffc0205294:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0205296:	5c7d                	li	s8,-1
ffffffffc0205298:	5dfd                	li	s11,-1
ffffffffc020529a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020529e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052a0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02052a4:	0ff5f593          	zext.b	a1,a1
ffffffffc02052a8:	00140d13          	addi	s10,s0,1
ffffffffc02052ac:	04b56263          	bltu	a0,a1,ffffffffc02052f0 <vprintfmt+0xbc>
ffffffffc02052b0:	058a                	slli	a1,a1,0x2
ffffffffc02052b2:	95d6                	add	a1,a1,s5
ffffffffc02052b4:	4194                	lw	a3,0(a1)
ffffffffc02052b6:	96d6                	add	a3,a3,s5
ffffffffc02052b8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02052ba:	70e6                	ld	ra,120(sp)
ffffffffc02052bc:	7446                	ld	s0,112(sp)
ffffffffc02052be:	74a6                	ld	s1,104(sp)
ffffffffc02052c0:	7906                	ld	s2,96(sp)
ffffffffc02052c2:	69e6                	ld	s3,88(sp)
ffffffffc02052c4:	6a46                	ld	s4,80(sp)
ffffffffc02052c6:	6aa6                	ld	s5,72(sp)
ffffffffc02052c8:	6b06                	ld	s6,64(sp)
ffffffffc02052ca:	7be2                	ld	s7,56(sp)
ffffffffc02052cc:	7c42                	ld	s8,48(sp)
ffffffffc02052ce:	7ca2                	ld	s9,40(sp)
ffffffffc02052d0:	7d02                	ld	s10,32(sp)
ffffffffc02052d2:	6de2                	ld	s11,24(sp)
ffffffffc02052d4:	6109                	addi	sp,sp,128
ffffffffc02052d6:	8082                	ret
            padc = '0';
ffffffffc02052d8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02052da:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02052de:	846a                	mv	s0,s10
ffffffffc02052e0:	00140d13          	addi	s10,s0,1
ffffffffc02052e4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02052e8:	0ff5f593          	zext.b	a1,a1
ffffffffc02052ec:	fcb572e3          	bgeu	a0,a1,ffffffffc02052b0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02052f0:	85a6                	mv	a1,s1
ffffffffc02052f2:	02500513          	li	a0,37
ffffffffc02052f6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02052f8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02052fc:	8d22                	mv	s10,s0
ffffffffc02052fe:	f73788e3          	beq	a5,s3,ffffffffc020526e <vprintfmt+0x3a>
ffffffffc0205302:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205306:	1d7d                	addi	s10,s10,-1
ffffffffc0205308:	ff379de3          	bne	a5,s3,ffffffffc0205302 <vprintfmt+0xce>
ffffffffc020530c:	b78d                	j	ffffffffc020526e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020530e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0205312:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205316:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205318:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020531c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205320:	02d86463          	bltu	a6,a3,ffffffffc0205348 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0205324:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205328:	002c169b          	slliw	a3,s8,0x2
ffffffffc020532c:	0186873b          	addw	a4,a3,s8
ffffffffc0205330:	0017171b          	slliw	a4,a4,0x1
ffffffffc0205334:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205336:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020533a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020533c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0205340:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0205344:	fed870e3          	bgeu	a6,a3,ffffffffc0205324 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205348:	f40ddce3          	bgez	s11,ffffffffc02052a0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020534c:	8de2                	mv	s11,s8
ffffffffc020534e:	5c7d                	li	s8,-1
ffffffffc0205350:	bf81                	j	ffffffffc02052a0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0205352:	fffdc693          	not	a3,s11
ffffffffc0205356:	96fd                	srai	a3,a3,0x3f
ffffffffc0205358:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020535c:	00144603          	lbu	a2,1(s0)
ffffffffc0205360:	2d81                	sext.w	s11,s11
ffffffffc0205362:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205364:	bf35                	j	ffffffffc02052a0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0205366:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020536a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020536e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205370:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0205372:	bfd9                	j	ffffffffc0205348 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0205374:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205376:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020537a:	01174463          	blt	a4,a7,ffffffffc0205382 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020537e:	1a088e63          	beqz	a7,ffffffffc020553a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0205382:	000a3603          	ld	a2,0(s4)
ffffffffc0205386:	46c1                	li	a3,16
ffffffffc0205388:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020538a:	2781                	sext.w	a5,a5
ffffffffc020538c:	876e                	mv	a4,s11
ffffffffc020538e:	85a6                	mv	a1,s1
ffffffffc0205390:	854a                	mv	a0,s2
ffffffffc0205392:	e37ff0ef          	jal	ra,ffffffffc02051c8 <printnum>
            break;
ffffffffc0205396:	bde1                	j	ffffffffc020526e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0205398:	000a2503          	lw	a0,0(s4)
ffffffffc020539c:	85a6                	mv	a1,s1
ffffffffc020539e:	0a21                	addi	s4,s4,8
ffffffffc02053a0:	9902                	jalr	s2
            break;
ffffffffc02053a2:	b5f1                	j	ffffffffc020526e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02053a4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053a6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02053aa:	01174463          	blt	a4,a7,ffffffffc02053b2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02053ae:	18088163          	beqz	a7,ffffffffc0205530 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02053b2:	000a3603          	ld	a2,0(s4)
ffffffffc02053b6:	46a9                	li	a3,10
ffffffffc02053b8:	8a2e                	mv	s4,a1
ffffffffc02053ba:	bfc1                	j	ffffffffc020538a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053bc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02053c0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053c2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02053c4:	bdf1                	j	ffffffffc02052a0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02053c6:	85a6                	mv	a1,s1
ffffffffc02053c8:	02500513          	li	a0,37
ffffffffc02053cc:	9902                	jalr	s2
            break;
ffffffffc02053ce:	b545                	j	ffffffffc020526e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053d0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02053d4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053d6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02053d8:	b5e1                	j	ffffffffc02052a0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02053da:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02053dc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02053e0:	01174463          	blt	a4,a7,ffffffffc02053e8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02053e4:	14088163          	beqz	a7,ffffffffc0205526 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02053e8:	000a3603          	ld	a2,0(s4)
ffffffffc02053ec:	46a1                	li	a3,8
ffffffffc02053ee:	8a2e                	mv	s4,a1
ffffffffc02053f0:	bf69                	j	ffffffffc020538a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02053f2:	03000513          	li	a0,48
ffffffffc02053f6:	85a6                	mv	a1,s1
ffffffffc02053f8:	e03e                	sd	a5,0(sp)
ffffffffc02053fa:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02053fc:	85a6                	mv	a1,s1
ffffffffc02053fe:	07800513          	li	a0,120
ffffffffc0205402:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205404:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205406:	6782                	ld	a5,0(sp)
ffffffffc0205408:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020540a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020540e:	bfb5                	j	ffffffffc020538a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205410:	000a3403          	ld	s0,0(s4)
ffffffffc0205414:	008a0713          	addi	a4,s4,8
ffffffffc0205418:	e03a                	sd	a4,0(sp)
ffffffffc020541a:	14040263          	beqz	s0,ffffffffc020555e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020541e:	0fb05763          	blez	s11,ffffffffc020550c <vprintfmt+0x2d8>
ffffffffc0205422:	02d00693          	li	a3,45
ffffffffc0205426:	0cd79163          	bne	a5,a3,ffffffffc02054e8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020542a:	00044783          	lbu	a5,0(s0)
ffffffffc020542e:	0007851b          	sext.w	a0,a5
ffffffffc0205432:	cf85                	beqz	a5,ffffffffc020546a <vprintfmt+0x236>
ffffffffc0205434:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205438:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020543c:	000c4563          	bltz	s8,ffffffffc0205446 <vprintfmt+0x212>
ffffffffc0205440:	3c7d                	addiw	s8,s8,-1
ffffffffc0205442:	036c0263          	beq	s8,s6,ffffffffc0205466 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205446:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205448:	0e0c8e63          	beqz	s9,ffffffffc0205544 <vprintfmt+0x310>
ffffffffc020544c:	3781                	addiw	a5,a5,-32
ffffffffc020544e:	0ef47b63          	bgeu	s0,a5,ffffffffc0205544 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0205452:	03f00513          	li	a0,63
ffffffffc0205456:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205458:	000a4783          	lbu	a5,0(s4)
ffffffffc020545c:	3dfd                	addiw	s11,s11,-1
ffffffffc020545e:	0a05                	addi	s4,s4,1
ffffffffc0205460:	0007851b          	sext.w	a0,a5
ffffffffc0205464:	ffe1                	bnez	a5,ffffffffc020543c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0205466:	01b05963          	blez	s11,ffffffffc0205478 <vprintfmt+0x244>
ffffffffc020546a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020546c:	85a6                	mv	a1,s1
ffffffffc020546e:	02000513          	li	a0,32
ffffffffc0205472:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0205474:	fe0d9be3          	bnez	s11,ffffffffc020546a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205478:	6a02                	ld	s4,0(sp)
ffffffffc020547a:	bbd5                	j	ffffffffc020526e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020547c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020547e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0205482:	01174463          	blt	a4,a7,ffffffffc020548a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0205486:	08088d63          	beqz	a7,ffffffffc0205520 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020548a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020548e:	0a044d63          	bltz	s0,ffffffffc0205548 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0205492:	8622                	mv	a2,s0
ffffffffc0205494:	8a66                	mv	s4,s9
ffffffffc0205496:	46a9                	li	a3,10
ffffffffc0205498:	bdcd                	j	ffffffffc020538a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020549a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020549e:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02054a0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02054a2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02054a6:	8fb5                	xor	a5,a5,a3
ffffffffc02054a8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02054ac:	02d74163          	blt	a4,a3,ffffffffc02054ce <vprintfmt+0x29a>
ffffffffc02054b0:	00369793          	slli	a5,a3,0x3
ffffffffc02054b4:	97de                	add	a5,a5,s7
ffffffffc02054b6:	639c                	ld	a5,0(a5)
ffffffffc02054b8:	cb99                	beqz	a5,ffffffffc02054ce <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02054ba:	86be                	mv	a3,a5
ffffffffc02054bc:	00000617          	auipc	a2,0x0
ffffffffc02054c0:	1f460613          	addi	a2,a2,500 # ffffffffc02056b0 <etext+0x2e>
ffffffffc02054c4:	85a6                	mv	a1,s1
ffffffffc02054c6:	854a                	mv	a0,s2
ffffffffc02054c8:	0ce000ef          	jal	ra,ffffffffc0205596 <printfmt>
ffffffffc02054cc:	b34d                	j	ffffffffc020526e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02054ce:	00002617          	auipc	a2,0x2
ffffffffc02054d2:	74260613          	addi	a2,a2,1858 # ffffffffc0207c10 <syscalls+0x820>
ffffffffc02054d6:	85a6                	mv	a1,s1
ffffffffc02054d8:	854a                	mv	a0,s2
ffffffffc02054da:	0bc000ef          	jal	ra,ffffffffc0205596 <printfmt>
ffffffffc02054de:	bb41                	j	ffffffffc020526e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02054e0:	00002417          	auipc	s0,0x2
ffffffffc02054e4:	72840413          	addi	s0,s0,1832 # ffffffffc0207c08 <syscalls+0x818>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02054e8:	85e2                	mv	a1,s8
ffffffffc02054ea:	8522                	mv	a0,s0
ffffffffc02054ec:	e43e                	sd	a5,8(sp)
ffffffffc02054ee:	0e2000ef          	jal	ra,ffffffffc02055d0 <strnlen>
ffffffffc02054f2:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02054f6:	01b05b63          	blez	s11,ffffffffc020550c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02054fa:	67a2                	ld	a5,8(sp)
ffffffffc02054fc:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205500:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0205502:	85a6                	mv	a1,s1
ffffffffc0205504:	8552                	mv	a0,s4
ffffffffc0205506:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205508:	fe0d9ce3          	bnez	s11,ffffffffc0205500 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020550c:	00044783          	lbu	a5,0(s0)
ffffffffc0205510:	00140a13          	addi	s4,s0,1
ffffffffc0205514:	0007851b          	sext.w	a0,a5
ffffffffc0205518:	d3a5                	beqz	a5,ffffffffc0205478 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020551a:	05e00413          	li	s0,94
ffffffffc020551e:	bf39                	j	ffffffffc020543c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0205520:	000a2403          	lw	s0,0(s4)
ffffffffc0205524:	b7ad                	j	ffffffffc020548e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205526:	000a6603          	lwu	a2,0(s4)
ffffffffc020552a:	46a1                	li	a3,8
ffffffffc020552c:	8a2e                	mv	s4,a1
ffffffffc020552e:	bdb1                	j	ffffffffc020538a <vprintfmt+0x156>
ffffffffc0205530:	000a6603          	lwu	a2,0(s4)
ffffffffc0205534:	46a9                	li	a3,10
ffffffffc0205536:	8a2e                	mv	s4,a1
ffffffffc0205538:	bd89                	j	ffffffffc020538a <vprintfmt+0x156>
ffffffffc020553a:	000a6603          	lwu	a2,0(s4)
ffffffffc020553e:	46c1                	li	a3,16
ffffffffc0205540:	8a2e                	mv	s4,a1
ffffffffc0205542:	b5a1                	j	ffffffffc020538a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0205544:	9902                	jalr	s2
ffffffffc0205546:	bf09                	j	ffffffffc0205458 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205548:	85a6                	mv	a1,s1
ffffffffc020554a:	02d00513          	li	a0,45
ffffffffc020554e:	e03e                	sd	a5,0(sp)
ffffffffc0205550:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0205552:	6782                	ld	a5,0(sp)
ffffffffc0205554:	8a66                	mv	s4,s9
ffffffffc0205556:	40800633          	neg	a2,s0
ffffffffc020555a:	46a9                	li	a3,10
ffffffffc020555c:	b53d                	j	ffffffffc020538a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020555e:	03b05163          	blez	s11,ffffffffc0205580 <vprintfmt+0x34c>
ffffffffc0205562:	02d00693          	li	a3,45
ffffffffc0205566:	f6d79de3          	bne	a5,a3,ffffffffc02054e0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020556a:	00002417          	auipc	s0,0x2
ffffffffc020556e:	69e40413          	addi	s0,s0,1694 # ffffffffc0207c08 <syscalls+0x818>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205572:	02800793          	li	a5,40
ffffffffc0205576:	02800513          	li	a0,40
ffffffffc020557a:	00140a13          	addi	s4,s0,1
ffffffffc020557e:	bd6d                	j	ffffffffc0205438 <vprintfmt+0x204>
ffffffffc0205580:	00002a17          	auipc	s4,0x2
ffffffffc0205584:	689a0a13          	addi	s4,s4,1673 # ffffffffc0207c09 <syscalls+0x819>
ffffffffc0205588:	02800513          	li	a0,40
ffffffffc020558c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205590:	05e00413          	li	s0,94
ffffffffc0205594:	b565                	j	ffffffffc020543c <vprintfmt+0x208>

ffffffffc0205596 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205596:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205598:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020559c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020559e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02055a0:	ec06                	sd	ra,24(sp)
ffffffffc02055a2:	f83a                	sd	a4,48(sp)
ffffffffc02055a4:	fc3e                	sd	a5,56(sp)
ffffffffc02055a6:	e0c2                	sd	a6,64(sp)
ffffffffc02055a8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02055aa:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02055ac:	c89ff0ef          	jal	ra,ffffffffc0205234 <vprintfmt>
}
ffffffffc02055b0:	60e2                	ld	ra,24(sp)
ffffffffc02055b2:	6161                	addi	sp,sp,80
ffffffffc02055b4:	8082                	ret

ffffffffc02055b6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02055b6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02055ba:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02055bc:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02055be:	cb81                	beqz	a5,ffffffffc02055ce <strlen+0x18>
        cnt ++;
ffffffffc02055c0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02055c2:	00a707b3          	add	a5,a4,a0
ffffffffc02055c6:	0007c783          	lbu	a5,0(a5)
ffffffffc02055ca:	fbfd                	bnez	a5,ffffffffc02055c0 <strlen+0xa>
ffffffffc02055cc:	8082                	ret
    }
    return cnt;
}
ffffffffc02055ce:	8082                	ret

ffffffffc02055d0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02055d0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02055d2:	e589                	bnez	a1,ffffffffc02055dc <strnlen+0xc>
ffffffffc02055d4:	a811                	j	ffffffffc02055e8 <strnlen+0x18>
        cnt ++;
ffffffffc02055d6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02055d8:	00f58863          	beq	a1,a5,ffffffffc02055e8 <strnlen+0x18>
ffffffffc02055dc:	00f50733          	add	a4,a0,a5
ffffffffc02055e0:	00074703          	lbu	a4,0(a4)
ffffffffc02055e4:	fb6d                	bnez	a4,ffffffffc02055d6 <strnlen+0x6>
ffffffffc02055e6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02055e8:	852e                	mv	a0,a1
ffffffffc02055ea:	8082                	ret

ffffffffc02055ec <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02055ec:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02055ee:	0005c703          	lbu	a4,0(a1)
ffffffffc02055f2:	0785                	addi	a5,a5,1
ffffffffc02055f4:	0585                	addi	a1,a1,1
ffffffffc02055f6:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02055fa:	fb75                	bnez	a4,ffffffffc02055ee <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02055fc:	8082                	ret

ffffffffc02055fe <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02055fe:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205602:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205606:	cb89                	beqz	a5,ffffffffc0205618 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205608:	0505                	addi	a0,a0,1
ffffffffc020560a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020560c:	fee789e3          	beq	a5,a4,ffffffffc02055fe <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205610:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205614:	9d19                	subw	a0,a0,a4
ffffffffc0205616:	8082                	ret
ffffffffc0205618:	4501                	li	a0,0
ffffffffc020561a:	bfed                	j	ffffffffc0205614 <strcmp+0x16>

ffffffffc020561c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020561c:	c20d                	beqz	a2,ffffffffc020563e <strncmp+0x22>
ffffffffc020561e:	962e                	add	a2,a2,a1
ffffffffc0205620:	a031                	j	ffffffffc020562c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0205622:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205624:	00e79a63          	bne	a5,a4,ffffffffc0205638 <strncmp+0x1c>
ffffffffc0205628:	00b60b63          	beq	a2,a1,ffffffffc020563e <strncmp+0x22>
ffffffffc020562c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205630:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205632:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205636:	f7f5                	bnez	a5,ffffffffc0205622 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205638:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020563c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020563e:	4501                	li	a0,0
ffffffffc0205640:	8082                	ret

ffffffffc0205642 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205642:	00054783          	lbu	a5,0(a0)
ffffffffc0205646:	c799                	beqz	a5,ffffffffc0205654 <strchr+0x12>
        if (*s == c) {
ffffffffc0205648:	00f58763          	beq	a1,a5,ffffffffc0205656 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020564c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0205650:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205652:	fbfd                	bnez	a5,ffffffffc0205648 <strchr+0x6>
    }
    return NULL;
ffffffffc0205654:	4501                	li	a0,0
}
ffffffffc0205656:	8082                	ret

ffffffffc0205658 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205658:	ca01                	beqz	a2,ffffffffc0205668 <memset+0x10>
ffffffffc020565a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020565c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020565e:	0785                	addi	a5,a5,1
ffffffffc0205660:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205664:	fec79de3          	bne	a5,a2,ffffffffc020565e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205668:	8082                	ret

ffffffffc020566a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020566a:	ca19                	beqz	a2,ffffffffc0205680 <memcpy+0x16>
ffffffffc020566c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020566e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205670:	0005c703          	lbu	a4,0(a1)
ffffffffc0205674:	0585                	addi	a1,a1,1
ffffffffc0205676:	0785                	addi	a5,a5,1
ffffffffc0205678:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020567c:	fec59ae3          	bne	a1,a2,ffffffffc0205670 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205680:	8082                	ret

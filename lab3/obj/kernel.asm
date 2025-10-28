
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
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
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0205ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	72f010ef          	jal	ffffffffc0201f9a <memset>
    dtb_init();
ffffffffc0200070:	40a000ef          	jal	ffffffffc020047a <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3f8000ef          	jal	ffffffffc020046c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f3850513          	addi	a0,a0,-200 # ffffffffc0201fb0 <etext+0x4>
ffffffffc0200080:	08e000ef          	jal	ffffffffc020010e <cputs>

    print_kerninfo();
ffffffffc0200084:	0e8000ef          	jal	ffffffffc020016c <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	77a000ef          	jal	ffffffffc0200802 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	758010ef          	jal	ffffffffc02017e4 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	772000ef          	jal	ffffffffc0200802 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	396000ef          	jal	ffffffffc020042a <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	75e000ef          	jal	ffffffffc02007f6 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	3c8000ef          	jal	ffffffffc020046e <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	18b010ef          	jal	ffffffffc0201a56 <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000de:	f42e                	sd	a1,40(sp)
ffffffffc02000e0:	f832                	sd	a2,48(sp)
ffffffffc02000e2:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	862a                	mv	a2,a0
ffffffffc02000e6:	004c                	addi	a1,sp,4
ffffffffc02000e8:	00000517          	auipc	a0,0x0
ffffffffc02000ec:	fb650513          	addi	a0,a0,-74 # ffffffffc020009e <cputch>
ffffffffc02000f0:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e0ba                	sd	a4,64(sp)
ffffffffc02000f6:	e4be                	sd	a5,72(sp)
ffffffffc02000f8:	e8c2                	sd	a6,80(sp)
ffffffffc02000fa:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fc:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000fe:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200100:	157010ef          	jal	ffffffffc0201a56 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200104:	60e2                	ld	ra,24(sp)
ffffffffc0200106:	4512                	lw	a0,4(sp)
ffffffffc0200108:	6125                	addi	sp,sp,96
ffffffffc020010a:	8082                	ret

ffffffffc020010c <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010c:	a68d                	j	ffffffffc020046e <cons_putc>

ffffffffc020010e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020010e:	1101                	addi	sp,sp,-32
ffffffffc0200110:	ec06                	sd	ra,24(sp)
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200116:	00054503          	lbu	a0,0(a0)
ffffffffc020011a:	c905                	beqz	a0,ffffffffc020014a <cputs+0x3c>
ffffffffc020011c:	e426                	sd	s1,8(sp)
ffffffffc020011e:	00178493          	addi	s1,a5,1
ffffffffc0200122:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200124:	34a000ef          	jal	ffffffffc020046e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200128:	00044503          	lbu	a0,0(s0)
ffffffffc020012c:	87a2                	mv	a5,s0
ffffffffc020012e:	0405                	addi	s0,s0,1
ffffffffc0200130:	f975                	bnez	a0,ffffffffc0200124 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200132:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc0200134:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200136:	0027841b          	addiw	s0,a5,2
ffffffffc020013a:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc020013c:	332000ef          	jal	ffffffffc020046e <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret
    cons_putc(c);
ffffffffc020014a:	4529                	li	a0,10
ffffffffc020014c:	322000ef          	jal	ffffffffc020046e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200150:	4405                	li	s0,1
}
ffffffffc0200152:	60e2                	ld	ra,24(sp)
ffffffffc0200154:	8522                	mv	a0,s0
ffffffffc0200156:	6442                	ld	s0,16(sp)
ffffffffc0200158:	6105                	addi	sp,sp,32
ffffffffc020015a:	8082                	ret

ffffffffc020015c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020015c:	1141                	addi	sp,sp,-16
ffffffffc020015e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200160:	316000ef          	jal	ffffffffc0200476 <cons_getc>
ffffffffc0200164:	dd75                	beqz	a0,ffffffffc0200160 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200166:	60a2                	ld	ra,8(sp)
ffffffffc0200168:	0141                	addi	sp,sp,16
ffffffffc020016a:	8082                	ret

ffffffffc020016c <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020016c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020016e:	00002517          	auipc	a0,0x2
ffffffffc0200172:	e6250513          	addi	a0,a0,-414 # ffffffffc0201fd0 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200176:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200178:	f61ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020017c:	00000597          	auipc	a1,0x0
ffffffffc0200180:	ed858593          	addi	a1,a1,-296 # ffffffffc0200054 <kern_init>
ffffffffc0200184:	00002517          	auipc	a0,0x2
ffffffffc0200188:	e6c50513          	addi	a0,a0,-404 # ffffffffc0201ff0 <etext+0x44>
ffffffffc020018c:	f4dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200190:	00002597          	auipc	a1,0x2
ffffffffc0200194:	e1c58593          	addi	a1,a1,-484 # ffffffffc0201fac <etext>
ffffffffc0200198:	00002517          	auipc	a0,0x2
ffffffffc020019c:	e7850513          	addi	a0,a0,-392 # ffffffffc0202010 <etext+0x64>
ffffffffc02001a0:	f39ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a4:	00007597          	auipc	a1,0x7
ffffffffc02001a8:	e8458593          	addi	a1,a1,-380 # ffffffffc0207028 <free_area>
ffffffffc02001ac:	00002517          	auipc	a0,0x2
ffffffffc02001b0:	e8450513          	addi	a0,a0,-380 # ffffffffc0202030 <etext+0x84>
ffffffffc02001b4:	f25ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b8:	00007597          	auipc	a1,0x7
ffffffffc02001bc:	2e858593          	addi	a1,a1,744 # ffffffffc02074a0 <end>
ffffffffc02001c0:	00002517          	auipc	a0,0x2
ffffffffc02001c4:	e9050513          	addi	a0,a0,-368 # ffffffffc0202050 <etext+0xa4>
ffffffffc02001c8:	f11ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001cc:	00007797          	auipc	a5,0x7
ffffffffc02001d0:	6d378793          	addi	a5,a5,1747 # ffffffffc020789f <end+0x3ff>
ffffffffc02001d4:	00000717          	auipc	a4,0x0
ffffffffc02001d8:	e8070713          	addi	a4,a4,-384 # ffffffffc0200054 <kern_init>
ffffffffc02001dc:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001de:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001e2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e8:	95be                	add	a1,a1,a5
ffffffffc02001ea:	85a9                	srai	a1,a1,0xa
ffffffffc02001ec:	00002517          	auipc	a0,0x2
ffffffffc02001f0:	e8450513          	addi	a0,a0,-380 # ffffffffc0202070 <etext+0xc4>
}
ffffffffc02001f4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f6:	b5cd                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001f8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f8:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001fa:	00002617          	auipc	a2,0x2
ffffffffc02001fe:	ea660613          	addi	a2,a2,-346 # ffffffffc02020a0 <etext+0xf4>
ffffffffc0200202:	04d00593          	li	a1,77
ffffffffc0200206:	00002517          	auipc	a0,0x2
ffffffffc020020a:	eb250513          	addi	a0,a0,-334 # ffffffffc02020b8 <etext+0x10c>
void print_stackframe(void) {
ffffffffc020020e:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200210:	1bc000ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0200214 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200214:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200216:	00002617          	auipc	a2,0x2
ffffffffc020021a:	eba60613          	addi	a2,a2,-326 # ffffffffc02020d0 <etext+0x124>
ffffffffc020021e:	00002597          	auipc	a1,0x2
ffffffffc0200222:	ed258593          	addi	a1,a1,-302 # ffffffffc02020f0 <etext+0x144>
ffffffffc0200226:	00002517          	auipc	a0,0x2
ffffffffc020022a:	ed250513          	addi	a0,a0,-302 # ffffffffc02020f8 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022e:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200230:	ea9ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200234:	00002617          	auipc	a2,0x2
ffffffffc0200238:	ed460613          	addi	a2,a2,-300 # ffffffffc0202108 <etext+0x15c>
ffffffffc020023c:	00002597          	auipc	a1,0x2
ffffffffc0200240:	ef458593          	addi	a1,a1,-268 # ffffffffc0202130 <etext+0x184>
ffffffffc0200244:	00002517          	auipc	a0,0x2
ffffffffc0200248:	eb450513          	addi	a0,a0,-332 # ffffffffc02020f8 <etext+0x14c>
ffffffffc020024c:	e8dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200250:	00002617          	auipc	a2,0x2
ffffffffc0200254:	ef060613          	addi	a2,a2,-272 # ffffffffc0202140 <etext+0x194>
ffffffffc0200258:	00002597          	auipc	a1,0x2
ffffffffc020025c:	f0858593          	addi	a1,a1,-248 # ffffffffc0202160 <etext+0x1b4>
ffffffffc0200260:	00002517          	auipc	a0,0x2
ffffffffc0200264:	e9850513          	addi	a0,a0,-360 # ffffffffc02020f8 <etext+0x14c>
ffffffffc0200268:	e71ff0ef          	jal	ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc020026c:	60a2                	ld	ra,8(sp)
ffffffffc020026e:	4501                	li	a0,0
ffffffffc0200270:	0141                	addi	sp,sp,16
ffffffffc0200272:	8082                	ret

ffffffffc0200274 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200274:	1141                	addi	sp,sp,-16
ffffffffc0200276:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200278:	ef5ff0ef          	jal	ffffffffc020016c <print_kerninfo>
    return 0;
}
ffffffffc020027c:	60a2                	ld	ra,8(sp)
ffffffffc020027e:	4501                	li	a0,0
ffffffffc0200280:	0141                	addi	sp,sp,16
ffffffffc0200282:	8082                	ret

ffffffffc0200284 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200284:	1141                	addi	sp,sp,-16
ffffffffc0200286:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200288:	f71ff0ef          	jal	ffffffffc02001f8 <print_stackframe>
    return 0;
}
ffffffffc020028c:	60a2                	ld	ra,8(sp)
ffffffffc020028e:	4501                	li	a0,0
ffffffffc0200290:	0141                	addi	sp,sp,16
ffffffffc0200292:	8082                	ret

ffffffffc0200294 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200294:	7115                	addi	sp,sp,-224
ffffffffc0200296:	f15a                	sd	s6,160(sp)
ffffffffc0200298:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020029a:	00002517          	auipc	a0,0x2
ffffffffc020029e:	ed650513          	addi	a0,a0,-298 # ffffffffc0202170 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc02002a2:	ed86                	sd	ra,216(sp)
ffffffffc02002a4:	e9a2                	sd	s0,208(sp)
ffffffffc02002a6:	e5a6                	sd	s1,200(sp)
ffffffffc02002a8:	e1ca                	sd	s2,192(sp)
ffffffffc02002aa:	fd4e                	sd	s3,184(sp)
ffffffffc02002ac:	f952                	sd	s4,176(sp)
ffffffffc02002ae:	f556                	sd	s5,168(sp)
ffffffffc02002b0:	ed5e                	sd	s7,152(sp)
ffffffffc02002b2:	e962                	sd	s8,144(sp)
ffffffffc02002b4:	e566                	sd	s9,136(sp)
ffffffffc02002b6:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b8:	e21ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002bc:	00002517          	auipc	a0,0x2
ffffffffc02002c0:	edc50513          	addi	a0,a0,-292 # ffffffffc0202198 <etext+0x1ec>
ffffffffc02002c4:	e15ff0ef          	jal	ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002c8:	000b0563          	beqz	s6,ffffffffc02002d2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002cc:	855a                	mv	a0,s6
ffffffffc02002ce:	714000ef          	jal	ffffffffc02009e2 <print_trapframe>
ffffffffc02002d2:	00003c17          	auipc	s8,0x3
ffffffffc02002d6:	b16c0c13          	addi	s8,s8,-1258 # ffffffffc0202de8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002da:	00002917          	auipc	s2,0x2
ffffffffc02002de:	ee690913          	addi	s2,s2,-282 # ffffffffc02021c0 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	00002497          	auipc	s1,0x2
ffffffffc02002e6:	ee648493          	addi	s1,s1,-282 # ffffffffc02021c8 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ea:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002ec:	00002a97          	auipc	s5,0x2
ffffffffc02002f0:	ee4a8a93          	addi	s5,s5,-284 # ffffffffc02021d0 <etext+0x224>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f4:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002f6:	00002b97          	auipc	s7,0x2
ffffffffc02002fa:	efab8b93          	addi	s7,s7,-262 # ffffffffc02021f0 <etext+0x244>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fe:	854a                	mv	a0,s2
ffffffffc0200300:	2d1010ef          	jal	ffffffffc0201dd0 <readline>
ffffffffc0200304:	842a                	mv	s0,a0
ffffffffc0200306:	dd65                	beqz	a0,ffffffffc02002fe <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200308:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030c:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	e59d                	bnez	a1,ffffffffc020033c <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc0200310:	fe0c87e3          	beqz	s9,ffffffffc02002fe <kmonitor+0x6a>
ffffffffc0200314:	00003d17          	auipc	s10,0x3
ffffffffc0200318:	ad4d0d13          	addi	s10,s10,-1324 # ffffffffc0202de8 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031e:	6582                	ld	a1,0(sp)
ffffffffc0200320:	000d3503          	ld	a0,0(s10)
ffffffffc0200324:	401010ef          	jal	ffffffffc0201f24 <strcmp>
ffffffffc0200328:	c53d                	beqz	a0,ffffffffc0200396 <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	2405                	addiw	s0,s0,1
ffffffffc020032c:	0d61                	addi	s10,s10,24
ffffffffc020032e:	ff4418e3          	bne	s0,s4,ffffffffc020031e <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200332:	6582                	ld	a1,0(sp)
ffffffffc0200334:	855e                	mv	a0,s7
ffffffffc0200336:	da3ff0ef          	jal	ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc020033a:	b7d1                	j	ffffffffc02002fe <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	8526                	mv	a0,s1
ffffffffc020033e:	447010ef          	jal	ffffffffc0201f84 <strchr>
ffffffffc0200342:	c901                	beqz	a0,ffffffffc0200352 <kmonitor+0xbe>
ffffffffc0200344:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200348:	00040023          	sb	zero,0(s0)
ffffffffc020034c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020034e:	d1e9                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc0200350:	b7f5                	j	ffffffffc020033c <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc0200352:	00044783          	lbu	a5,0(s0)
ffffffffc0200356:	dfcd                	beqz	a5,ffffffffc0200310 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200358:	033c8a63          	beq	s9,s3,ffffffffc020038c <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc020035c:	003c9793          	slli	a5,s9,0x3
ffffffffc0200360:	08078793          	addi	a5,a5,128
ffffffffc0200364:	978a                	add	a5,a5,sp
ffffffffc0200366:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020036a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020036e:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	e591                	bnez	a1,ffffffffc020037c <kmonitor+0xe8>
ffffffffc0200372:	bf79                	j	ffffffffc0200310 <kmonitor+0x7c>
ffffffffc0200374:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200378:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037a:	d9d9                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc020037c:	8526                	mv	a0,s1
ffffffffc020037e:	407010ef          	jal	ffffffffc0201f84 <strchr>
ffffffffc0200382:	d96d                	beqz	a0,ffffffffc0200374 <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200384:	00044583          	lbu	a1,0(s0)
ffffffffc0200388:	d5c1                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc020038a:	bf4d                	j	ffffffffc020033c <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020038c:	45c1                	li	a1,16
ffffffffc020038e:	8556                	mv	a0,s5
ffffffffc0200390:	d49ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200394:	b7e1                	j	ffffffffc020035c <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200396:	00141793          	slli	a5,s0,0x1
ffffffffc020039a:	97a2                	add	a5,a5,s0
ffffffffc020039c:	078e                	slli	a5,a5,0x3
ffffffffc020039e:	97e2                	add	a5,a5,s8
ffffffffc02003a0:	6b9c                	ld	a5,16(a5)
ffffffffc02003a2:	865a                	mv	a2,s6
ffffffffc02003a4:	002c                	addi	a1,sp,8
ffffffffc02003a6:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003aa:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003ac:	f40559e3          	bgez	a0,ffffffffc02002fe <kmonitor+0x6a>
}
ffffffffc02003b0:	60ee                	ld	ra,216(sp)
ffffffffc02003b2:	644e                	ld	s0,208(sp)
ffffffffc02003b4:	64ae                	ld	s1,200(sp)
ffffffffc02003b6:	690e                	ld	s2,192(sp)
ffffffffc02003b8:	79ea                	ld	s3,184(sp)
ffffffffc02003ba:	7a4a                	ld	s4,176(sp)
ffffffffc02003bc:	7aaa                	ld	s5,168(sp)
ffffffffc02003be:	7b0a                	ld	s6,160(sp)
ffffffffc02003c0:	6bea                	ld	s7,152(sp)
ffffffffc02003c2:	6c4a                	ld	s8,144(sp)
ffffffffc02003c4:	6caa                	ld	s9,136(sp)
ffffffffc02003c6:	6d0a                	ld	s10,128(sp)
ffffffffc02003c8:	612d                	addi	sp,sp,224
ffffffffc02003ca:	8082                	ret

ffffffffc02003cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003cc:	00007317          	auipc	t1,0x7
ffffffffc02003d0:	07430313          	addi	t1,t1,116 # ffffffffc0207440 <is_panic>
ffffffffc02003d4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003d8:	715d                	addi	sp,sp,-80
ffffffffc02003da:	ec06                	sd	ra,24(sp)
ffffffffc02003dc:	f436                	sd	a3,40(sp)
ffffffffc02003de:	f83a                	sd	a4,48(sp)
ffffffffc02003e0:	fc3e                	sd	a5,56(sp)
ffffffffc02003e2:	e0c2                	sd	a6,64(sp)
ffffffffc02003e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003e6:	020e1c63          	bnez	t3,ffffffffc020041e <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003ea:	4785                	li	a5,1
ffffffffc02003ec:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f0:	e822                	sd	s0,16(sp)
ffffffffc02003f2:	103c                	addi	a5,sp,40
ffffffffc02003f4:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003f6:	862e                	mv	a2,a1
ffffffffc02003f8:	85aa                	mv	a1,a0
ffffffffc02003fa:	00002517          	auipc	a0,0x2
ffffffffc02003fe:	e0e50513          	addi	a0,a0,-498 # ffffffffc0202208 <etext+0x25c>
    va_start(ap, fmt);
ffffffffc0200402:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200404:	cd5ff0ef          	jal	ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200408:	65a2                	ld	a1,8(sp)
ffffffffc020040a:	8522                	mv	a0,s0
ffffffffc020040c:	cadff0ef          	jal	ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200410:	00002517          	auipc	a0,0x2
ffffffffc0200414:	e1850513          	addi	a0,a0,-488 # ffffffffc0202228 <etext+0x27c>
ffffffffc0200418:	cc1ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc020041c:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020041e:	3de000ef          	jal	ffffffffc02007fc <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200422:	4501                	li	a0,0
ffffffffc0200424:	e71ff0ef          	jal	ffffffffc0200294 <kmonitor>
    while (1) {
ffffffffc0200428:	bfed                	j	ffffffffc0200422 <__panic+0x56>

ffffffffc020042a <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042a:	1141                	addi	sp,sp,-16
ffffffffc020042c:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020042e:	02000793          	li	a5,32
ffffffffc0200432:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200436:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	67e1                	lui	a5,0x18
ffffffffc020043c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	25d010ef          	jal	ffffffffc0201e9e <sbi_set_timer>
}
ffffffffc0200446:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200448:	00007797          	auipc	a5,0x7
ffffffffc020044c:	0007b023          	sd	zero,0(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200450:	00002517          	auipc	a0,0x2
ffffffffc0200454:	de050513          	addi	a0,a0,-544 # ffffffffc0202230 <etext+0x284>
}
ffffffffc0200458:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045a:	b9bd                	j	ffffffffc02000d8 <cprintf>

ffffffffc020045c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020045c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200460:	67e1                	lui	a5,0x18
ffffffffc0200462:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200466:	953e                	add	a0,a0,a5
ffffffffc0200468:	2370106f          	j	ffffffffc0201e9e <sbi_set_timer>

ffffffffc020046c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020046c:	8082                	ret

ffffffffc020046e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020046e:	0ff57513          	zext.b	a0,a0
ffffffffc0200472:	2130106f          	j	ffffffffc0201e84 <sbi_console_putchar>

ffffffffc0200476 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200476:	2430106f          	j	ffffffffc0201eb8 <sbi_console_getchar>

ffffffffc020047a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020047a:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020047c:	00002517          	auipc	a0,0x2
ffffffffc0200480:	dd450513          	addi	a0,a0,-556 # ffffffffc0202250 <etext+0x2a4>
void dtb_init(void) {
ffffffffc0200484:	ec86                	sd	ra,88(sp)
ffffffffc0200486:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc0200488:	c51ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020048c:	00007597          	auipc	a1,0x7
ffffffffc0200490:	b745b583          	ld	a1,-1164(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	dcc50513          	addi	a0,a0,-564 # ffffffffc0202260 <etext+0x2b4>
ffffffffc020049c:	c3dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004a0:	00007417          	auipc	s0,0x7
ffffffffc02004a4:	b6840413          	addi	s0,s0,-1176 # ffffffffc0207008 <boot_dtb>
ffffffffc02004a8:	600c                	ld	a1,0(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	dc650513          	addi	a0,a0,-570 # ffffffffc0202270 <etext+0x2c4>
ffffffffc02004b2:	c27ff0ef          	jal	ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004b6:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	dd050513          	addi	a0,a0,-560 # ffffffffc0202288 <etext+0x2dc>
    if (boot_dtb == 0) {
ffffffffc02004c0:	12070d63          	beqz	a4,ffffffffc02005fa <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004c4:	57f5                	li	a5,-3
ffffffffc02004c6:	07fa                	slli	a5,a5,0x1e
ffffffffc02004c8:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004ca:	431c                	lw	a5,0(a4)
ffffffffc02004cc:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ce:	00ff0637          	lui	a2,0xff0
ffffffffc02004d2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004d6:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004da:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004de:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02004e6:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ea:	8ec9                	or	a3,a3,a0
ffffffffc02004ec:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004f0:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02004f2:	0157f7b3          	and	a5,a5,s5
ffffffffc02004f6:	8dd5                	or	a1,a1,a3
ffffffffc02004f8:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02004fa:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fe:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200500:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200504:	0ef59f63          	bne	a1,a5,ffffffffc0200602 <dtb_init+0x188>
ffffffffc0200508:	471c                	lw	a5,8(a4)
ffffffffc020050a:	4754                	lw	a3,12(a4)
ffffffffc020050c:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050e:	0087d99b          	srliw	s3,a5,0x8
ffffffffc0200512:	0086d41b          	srliw	s0,a3,0x8
ffffffffc0200516:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051e:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200522:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200526:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052a:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052e:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	8c71                	and	s0,s0,a2
ffffffffc0200538:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	01156533          	or	a0,a0,a7
ffffffffc0200540:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200544:	0105e633          	or	a2,a1,a6
ffffffffc0200548:	0087979b          	slliw	a5,a5,0x8
ffffffffc020054c:	8c49                	or	s0,s0,a0
ffffffffc020054e:	0156f6b3          	and	a3,a3,s5
ffffffffc0200552:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200556:	0157f7b3          	and	a5,a5,s5
ffffffffc020055a:	8c55                	or	s0,s0,a3
ffffffffc020055c:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200560:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200562:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200564:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200566:	0209d993          	srli	s3,s3,0x20
ffffffffc020056a:	e4a6                	sd	s1,72(sp)
ffffffffc020056c:	e0ca                	sd	s2,64(sp)
ffffffffc020056e:	ec5e                	sd	s7,24(sp)
ffffffffc0200570:	e862                	sd	s8,16(sp)
ffffffffc0200572:	e466                	sd	s9,8(sp)
ffffffffc0200574:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200576:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc0200578:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057e:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200582:	4c0d                	li	s8,3
ffffffffc0200584:	4911                	li	s2,4
ffffffffc0200586:	4d05                	li	s10,1
ffffffffc0200588:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020058a:	0009a703          	lw	a4,0(s3)
ffffffffc020058e:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200592:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200596:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059e:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a2:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005a6:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a8:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ac:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005b0:	8fd5                	or	a5,a5,a3
ffffffffc02005b2:	00eaf733          	and	a4,s5,a4
ffffffffc02005b6:	8fd9                	or	a5,a5,a4
ffffffffc02005b8:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005ba:	09878263          	beq	a5,s8,ffffffffc020063e <dtb_init+0x1c4>
ffffffffc02005be:	00fc6963          	bltu	s8,a5,ffffffffc02005d0 <dtb_init+0x156>
ffffffffc02005c2:	05a78963          	beq	a5,s10,ffffffffc0200614 <dtb_init+0x19a>
ffffffffc02005c6:	00979763          	bne	a5,s1,ffffffffc02005d4 <dtb_init+0x15a>
ffffffffc02005ca:	4b81                	li	s7,0
ffffffffc02005cc:	89d2                	mv	s3,s4
ffffffffc02005ce:	bf75                	j	ffffffffc020058a <dtb_init+0x110>
ffffffffc02005d0:	ff278ee3          	beq	a5,s2,ffffffffc02005cc <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005d4:	00002517          	auipc	a0,0x2
ffffffffc02005d8:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202350 <etext+0x3a4>
ffffffffc02005dc:	afdff0ef          	jal	ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005e0:	64a6                	ld	s1,72(sp)
ffffffffc02005e2:	6906                	ld	s2,64(sp)
ffffffffc02005e4:	79e2                	ld	s3,56(sp)
ffffffffc02005e6:	7a42                	ld	s4,48(sp)
ffffffffc02005e8:	7aa2                	ld	s5,40(sp)
ffffffffc02005ea:	6be2                	ld	s7,24(sp)
ffffffffc02005ec:	6c42                	ld	s8,16(sp)
ffffffffc02005ee:	6ca2                	ld	s9,8(sp)
ffffffffc02005f0:	6d02                	ld	s10,0(sp)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	d9650513          	addi	a0,a0,-618 # ffffffffc0202388 <etext+0x3dc>
}
ffffffffc02005fa:	6446                	ld	s0,80(sp)
ffffffffc02005fc:	60e6                	ld	ra,88(sp)
ffffffffc02005fe:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc0200600:	bce1                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200602:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200604:	7aa2                	ld	s5,40(sp)
}
ffffffffc0200606:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	ca050513          	addi	a0,a0,-864 # ffffffffc02022a8 <etext+0x2fc>
}
ffffffffc0200610:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200612:	b4d9                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc0200614:	8552                	mv	a0,s4
ffffffffc0200616:	0d9010ef          	jal	ffffffffc0201eee <strlen>
ffffffffc020061a:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020061c:	4619                	li	a2,6
ffffffffc020061e:	00002597          	auipc	a1,0x2
ffffffffc0200622:	cb258593          	addi	a1,a1,-846 # ffffffffc02022d0 <etext+0x324>
ffffffffc0200626:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc0200628:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020062a:	133010ef          	jal	ffffffffc0201f5c <strncmp>
ffffffffc020062e:	e111                	bnez	a0,ffffffffc0200632 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc0200630:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200632:	0a11                	addi	s4,s4,4
ffffffffc0200634:	9a4e                	add	s4,s4,s3
ffffffffc0200636:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc020063a:	89d2                	mv	s3,s4
ffffffffc020063c:	b7b9                	j	ffffffffc020058a <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0049a783          	lw	a5,4(s3)
ffffffffc0200642:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200644:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200648:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020064c:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200654:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200658:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020065c:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200660:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200664:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200668:	00eb6b33          	or	s6,s6,a4
ffffffffc020066c:	00faf7b3          	and	a5,s5,a5
ffffffffc0200670:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200674:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020067a:	000b9c63          	bnez	s7,ffffffffc0200692 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020067e:	1b02                	slli	s6,s6,0x20
ffffffffc0200680:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200684:	0a0d                	addi	s4,s4,3
ffffffffc0200686:	9a5a                	add	s4,s4,s6
ffffffffc0200688:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020068c:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc020068e:	89d2                	mv	s3,s4
ffffffffc0200690:	bded                	j	ffffffffc020058a <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200692:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200696:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006aa:	8fd9                	or	a5,a5,a4
ffffffffc02006ac:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006b0:	8d5d                	or	a0,a0,a5
ffffffffc02006b2:	00daf6b3          	and	a3,s5,a3
ffffffffc02006b6:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006b8:	1502                	slli	a0,a0,0x20
ffffffffc02006ba:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006bc:	00002597          	auipc	a1,0x2
ffffffffc02006c0:	c1c58593          	addi	a1,a1,-996 # ffffffffc02022d8 <etext+0x32c>
ffffffffc02006c4:	9522                	add	a0,a0,s0
ffffffffc02006c6:	05f010ef          	jal	ffffffffc0201f24 <strcmp>
ffffffffc02006ca:	f955                	bnez	a0,ffffffffc020067e <dtb_init+0x204>
ffffffffc02006cc:	47bd                	li	a5,15
ffffffffc02006ce:	fb67f8e3          	bgeu	a5,s6,ffffffffc020067e <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006d2:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006d6:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	c0650513          	addi	a0,a0,-1018 # ffffffffc02022e0 <etext+0x334>
           fdt32_to_cpu(x >> 32);
ffffffffc02006e2:	4207d693          	srai	a3,a5,0x20
ffffffffc02006e6:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ea:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02006ee:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02006f2:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02006f6:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fa:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02006fe:	0087541b          	srliw	s0,a4,0x8
ffffffffc0200702:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	01869e1b          	slliw	t3,a3,0x18
ffffffffc020070e:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	0188189b          	slliw	a7,a6,0x18
ffffffffc020071a:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200720:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0108581b          	srliw	a6,a6,0x10
ffffffffc0200726:	005e6e33          	or	t3,t3,t0
ffffffffc020072a:	01e8e8b3          	or	a7,a7,t5
ffffffffc020072e:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0104949b          	slliw	s1,s1,0x10
ffffffffc0200736:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073a:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073e:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200742:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200746:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074a:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074e:	00daf6b3          	and	a3,s5,a3
ffffffffc0200752:	007eeeb3          	or	t4,t4,t2
ffffffffc0200756:	01f36333          	or	t1,t1,t6
ffffffffc020075a:	01c7e7b3          	or	a5,a5,t3
ffffffffc020075e:	00caf633          	and	a2,s5,a2
ffffffffc0200762:	01176733          	or	a4,a4,a7
ffffffffc0200766:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020076e:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200772:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200776:	01d4e4b3          	or	s1,s1,t4
ffffffffc020077a:	00646433          	or	s0,s0,t1
ffffffffc020077e:	8fd5                	or	a5,a5,a3
ffffffffc0200780:	01576733          	or	a4,a4,s5
ffffffffc0200784:	8c51                	or	s0,s0,a2
ffffffffc0200786:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc0200788:	1782                	slli	a5,a5,0x20
ffffffffc020078a:	1702                	slli	a4,a4,0x20
ffffffffc020078c:	9381                	srli	a5,a5,0x20
ffffffffc020078e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200790:	1482                	slli	s1,s1,0x20
ffffffffc0200792:	1402                	slli	s0,s0,0x20
ffffffffc0200794:	8cdd                	or	s1,s1,a5
ffffffffc0200796:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200798:	941ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020079c:	85a6                	mv	a1,s1
ffffffffc020079e:	00002517          	auipc	a0,0x2
ffffffffc02007a2:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202300 <etext+0x354>
ffffffffc02007a6:	933ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007aa:	01445613          	srli	a2,s0,0x14
ffffffffc02007ae:	85a2                	mv	a1,s0
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	b6850513          	addi	a0,a0,-1176 # ffffffffc0202318 <etext+0x36c>
ffffffffc02007b8:	921ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007bc:	009405b3          	add	a1,s0,s1
ffffffffc02007c0:	15fd                	addi	a1,a1,-1
ffffffffc02007c2:	00002517          	auipc	a0,0x2
ffffffffc02007c6:	b7650513          	addi	a0,a0,-1162 # ffffffffc0202338 <etext+0x38c>
ffffffffc02007ca:	90fff0ef          	jal	ffffffffc02000d8 <cprintf>
        memory_base = mem_base;
ffffffffc02007ce:	7b02                	ld	s6,32(sp)
ffffffffc02007d0:	00007797          	auipc	a5,0x7
ffffffffc02007d4:	c897b423          	sd	s1,-888(a5) # ffffffffc0207458 <memory_base>
        memory_size = mem_size;
ffffffffc02007d8:	00007797          	auipc	a5,0x7
ffffffffc02007dc:	c687bc23          	sd	s0,-904(a5) # ffffffffc0207450 <memory_size>
ffffffffc02007e0:	b501                	j	ffffffffc02005e0 <dtb_init+0x166>

ffffffffc02007e2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007e2:	00007517          	auipc	a0,0x7
ffffffffc02007e6:	c7653503          	ld	a0,-906(a0) # ffffffffc0207458 <memory_base>
ffffffffc02007ea:	8082                	ret

ffffffffc02007ec <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007ec:	00007517          	auipc	a0,0x7
ffffffffc02007f0:	c6453503          	ld	a0,-924(a0) # ffffffffc0207450 <memory_size>
ffffffffc02007f4:	8082                	ret

ffffffffc02007f6 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007f6:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02007fa:	8082                	ret

ffffffffc02007fc <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007fc:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200800:	8082                	ret

ffffffffc0200802 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200802:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200806:	00000797          	auipc	a5,0x0
ffffffffc020080a:	38678793          	addi	a5,a5,902 # ffffffffc0200b8c <__alltraps>
ffffffffc020080e:	10579073          	csrw	stvec,a5
}
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200814:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200816:	1141                	addi	sp,sp,-16
ffffffffc0200818:	e022                	sd	s0,0(sp)
ffffffffc020081a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020081c:	00002517          	auipc	a0,0x2
ffffffffc0200820:	b8450513          	addi	a0,a0,-1148 # ffffffffc02023a0 <etext+0x3f4>
void print_regs(struct pushregs *gpr) {
ffffffffc0200824:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200826:	8b3ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020082a:	640c                	ld	a1,8(s0)
ffffffffc020082c:	00002517          	auipc	a0,0x2
ffffffffc0200830:	b8c50513          	addi	a0,a0,-1140 # ffffffffc02023b8 <etext+0x40c>
ffffffffc0200834:	8a5ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200838:	680c                	ld	a1,16(s0)
ffffffffc020083a:	00002517          	auipc	a0,0x2
ffffffffc020083e:	b9650513          	addi	a0,a0,-1130 # ffffffffc02023d0 <etext+0x424>
ffffffffc0200842:	897ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200846:	6c0c                	ld	a1,24(s0)
ffffffffc0200848:	00002517          	auipc	a0,0x2
ffffffffc020084c:	ba050513          	addi	a0,a0,-1120 # ffffffffc02023e8 <etext+0x43c>
ffffffffc0200850:	889ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200854:	700c                	ld	a1,32(s0)
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202400 <etext+0x454>
ffffffffc020085e:	87bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200862:	740c                	ld	a1,40(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202418 <etext+0x46c>
ffffffffc020086c:	86dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200870:	780c                	ld	a1,48(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202430 <etext+0x484>
ffffffffc020087a:	85fff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020087e:	7c0c                	ld	a1,56(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202448 <etext+0x49c>
ffffffffc0200888:	851ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020088c:	602c                	ld	a1,64(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202460 <etext+0x4b4>
ffffffffc0200896:	843ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020089a:	642c                	ld	a1,72(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202478 <etext+0x4cc>
ffffffffc02008a4:	835ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008a8:	682c                	ld	a1,80(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	be650513          	addi	a0,a0,-1050 # ffffffffc0202490 <etext+0x4e4>
ffffffffc02008b2:	827ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008b6:	6c2c                	ld	a1,88(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02024a8 <etext+0x4fc>
ffffffffc02008c0:	819ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008c4:	702c                	ld	a1,96(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	bfa50513          	addi	a0,a0,-1030 # ffffffffc02024c0 <etext+0x514>
ffffffffc02008ce:	80bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008d2:	742c                	ld	a1,104(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	c0450513          	addi	a0,a0,-1020 # ffffffffc02024d8 <etext+0x52c>
ffffffffc02008dc:	ffcff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008e0:	782c                	ld	a1,112(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	c0e50513          	addi	a0,a0,-1010 # ffffffffc02024f0 <etext+0x544>
ffffffffc02008ea:	feeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02008ee:	7c2c                	ld	a1,120(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	c1850513          	addi	a0,a0,-1000 # ffffffffc0202508 <etext+0x55c>
ffffffffc02008f8:	fe0ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02008fc:	604c                	ld	a1,128(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	c2250513          	addi	a0,a0,-990 # ffffffffc0202520 <etext+0x574>
ffffffffc0200906:	fd2ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020090a:	644c                	ld	a1,136(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202538 <etext+0x58c>
ffffffffc0200914:	fc4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200918:	684c                	ld	a1,144(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	c3650513          	addi	a0,a0,-970 # ffffffffc0202550 <etext+0x5a4>
ffffffffc0200922:	fb6ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200926:	6c4c                	ld	a1,152(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	c4050513          	addi	a0,a0,-960 # ffffffffc0202568 <etext+0x5bc>
ffffffffc0200930:	fa8ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200934:	704c                	ld	a1,160(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	c4a50513          	addi	a0,a0,-950 # ffffffffc0202580 <etext+0x5d4>
ffffffffc020093e:	f9aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200942:	744c                	ld	a1,168(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	c5450513          	addi	a0,a0,-940 # ffffffffc0202598 <etext+0x5ec>
ffffffffc020094c:	f8cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200950:	784c                	ld	a1,176(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	c5e50513          	addi	a0,a0,-930 # ffffffffc02025b0 <etext+0x604>
ffffffffc020095a:	f7eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020095e:	7c4c                	ld	a1,184(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	c6850513          	addi	a0,a0,-920 # ffffffffc02025c8 <etext+0x61c>
ffffffffc0200968:	f70ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc020096c:	606c                	ld	a1,192(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	c7250513          	addi	a0,a0,-910 # ffffffffc02025e0 <etext+0x634>
ffffffffc0200976:	f62ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc020097a:	646c                	ld	a1,200(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	c7c50513          	addi	a0,a0,-900 # ffffffffc02025f8 <etext+0x64c>
ffffffffc0200984:	f54ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200988:	686c                	ld	a1,208(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	c8650513          	addi	a0,a0,-890 # ffffffffc0202610 <etext+0x664>
ffffffffc0200992:	f46ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200996:	6c6c                	ld	a1,216(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	c9050513          	addi	a0,a0,-880 # ffffffffc0202628 <etext+0x67c>
ffffffffc02009a0:	f38ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009a4:	706c                	ld	a1,224(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	c9a50513          	addi	a0,a0,-870 # ffffffffc0202640 <etext+0x694>
ffffffffc02009ae:	f2aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009b2:	746c                	ld	a1,232(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	ca450513          	addi	a0,a0,-860 # ffffffffc0202658 <etext+0x6ac>
ffffffffc02009bc:	f1cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009c0:	786c                	ld	a1,240(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	cae50513          	addi	a0,a0,-850 # ffffffffc0202670 <etext+0x6c4>
ffffffffc02009ca:	f0eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009ce:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009d0:	6402                	ld	s0,0(sp)
ffffffffc02009d2:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009d4:	00002517          	auipc	a0,0x2
ffffffffc02009d8:	cb450513          	addi	a0,a0,-844 # ffffffffc0202688 <etext+0x6dc>
}
ffffffffc02009dc:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009de:	efaff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc02009e2 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009e2:	1141                	addi	sp,sp,-16
ffffffffc02009e4:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009e6:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009e8:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	cb650513          	addi	a0,a0,-842 # ffffffffc02026a0 <etext+0x6f4>
void print_trapframe(struct trapframe *tf) {
ffffffffc02009f2:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009f4:	ee4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc02009f8:	8522                	mv	a0,s0
ffffffffc02009fa:	e1bff0ef          	jal	ffffffffc0200814 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc02009fe:	10043583          	ld	a1,256(s0)
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	cb650513          	addi	a0,a0,-842 # ffffffffc02026b8 <etext+0x70c>
ffffffffc0200a0a:	eceff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a0e:	10843583          	ld	a1,264(s0)
ffffffffc0200a12:	00002517          	auipc	a0,0x2
ffffffffc0200a16:	cbe50513          	addi	a0,a0,-834 # ffffffffc02026d0 <etext+0x724>
ffffffffc0200a1a:	ebeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a1e:	11043583          	ld	a1,272(s0)
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	cc650513          	addi	a0,a0,-826 # ffffffffc02026e8 <etext+0x73c>
ffffffffc0200a2a:	eaeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a2e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a32:	6402                	ld	s0,0(sp)
ffffffffc0200a34:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a36:	00002517          	auipc	a0,0x2
ffffffffc0200a3a:	cca50513          	addi	a0,a0,-822 # ffffffffc0202700 <etext+0x754>
}
ffffffffc0200a3e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a40:	e98ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a44 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc0200a44:	11853783          	ld	a5,280(a0)
ffffffffc0200a48:	472d                	li	a4,11
ffffffffc0200a4a:	0786                	slli	a5,a5,0x1
ffffffffc0200a4c:	8385                	srli	a5,a5,0x1
ffffffffc0200a4e:	08f76963          	bltu	a4,a5,ffffffffc0200ae0 <interrupt_handler+0x9c>
ffffffffc0200a52:	00002717          	auipc	a4,0x2
ffffffffc0200a56:	3de70713          	addi	a4,a4,990 # ffffffffc0202e30 <commands+0x48>
ffffffffc0200a5a:	078a                	slli	a5,a5,0x2
ffffffffc0200a5c:	97ba                	add	a5,a5,a4
ffffffffc0200a5e:	439c                	lw	a5,0(a5)
ffffffffc0200a60:	97ba                	add	a5,a5,a4
ffffffffc0200a62:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a64:	00002517          	auipc	a0,0x2
ffffffffc0200a68:	d1450513          	addi	a0,a0,-748 # ffffffffc0202778 <etext+0x7cc>
ffffffffc0200a6c:	e6cff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	ce850513          	addi	a0,a0,-792 # ffffffffc0202758 <etext+0x7ac>
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a7c:	00002517          	auipc	a0,0x2
ffffffffc0200a80:	c9c50513          	addi	a0,a0,-868 # ffffffffc0202718 <etext+0x76c>
ffffffffc0200a84:	e54ff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a88:	00002517          	auipc	a0,0x2
ffffffffc0200a8c:	d1050513          	addi	a0,a0,-752 # ffffffffc0202798 <etext+0x7ec>
ffffffffc0200a90:	e48ff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a94:	1141                	addi	sp,sp,-16
ffffffffc0200a96:	e406                	sd	ra,8(sp)
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            //2312130 景千夏BEGIN
            /*clcok_set_next_event的实现和声明在driver/clock*/
            clock_set_next_event();
ffffffffc0200a98:	9c5ff0ef          	jal	ffffffffc020045c <clock_set_next_event>
            tickNum++;
ffffffffc0200a9c:	00007697          	auipc	a3,0x7
ffffffffc0200aa0:	9c868693          	addi	a3,a3,-1592 # ffffffffc0207464 <tickNum>
ffffffffc0200aa4:	429c                	lw	a5,0(a3)
            if(tickNum%TICK_NUM==0){
ffffffffc0200aa6:	06400713          	li	a4,100
            tickNum++;
ffffffffc0200aaa:	2785                	addiw	a5,a5,1
            if(tickNum%TICK_NUM==0){
ffffffffc0200aac:	02e7e73b          	remw	a4,a5,a4
            tickNum++;
ffffffffc0200ab0:	c29c                	sw	a5,0(a3)
            if(tickNum%TICK_NUM==0){
ffffffffc0200ab2:	cb05                	beqz	a4,ffffffffc0200ae2 <interrupt_handler+0x9e>
                print_ticks();
                printCount++;
            }
            if(printCount==10){
ffffffffc0200ab4:	00007717          	auipc	a4,0x7
ffffffffc0200ab8:	9ac72703          	lw	a4,-1620(a4) # ffffffffc0207460 <printCount>
ffffffffc0200abc:	47a9                	li	a5,10
ffffffffc0200abe:	04f70363          	beq	a4,a5,ffffffffc0200b04 <interrupt_handler+0xc0>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ac2:	60a2                	ld	ra,8(sp)
ffffffffc0200ac4:	0141                	addi	sp,sp,16
ffffffffc0200ac6:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200ac8:	00002517          	auipc	a0,0x2
ffffffffc0200acc:	cf850513          	addi	a0,a0,-776 # ffffffffc02027c0 <etext+0x814>
ffffffffc0200ad0:	e08ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200ad4:	00002517          	auipc	a0,0x2
ffffffffc0200ad8:	c6450513          	addi	a0,a0,-924 # ffffffffc0202738 <etext+0x78c>
ffffffffc0200adc:	dfcff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200ae0:	b709                	j	ffffffffc02009e2 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ae2:	06400593          	li	a1,100
ffffffffc0200ae6:	00002517          	auipc	a0,0x2
ffffffffc0200aea:	cca50513          	addi	a0,a0,-822 # ffffffffc02027b0 <etext+0x804>
ffffffffc0200aee:	deaff0ef          	jal	ffffffffc02000d8 <cprintf>
                printCount++;
ffffffffc0200af2:	00007697          	auipc	a3,0x7
ffffffffc0200af6:	96e68693          	addi	a3,a3,-1682 # ffffffffc0207460 <printCount>
ffffffffc0200afa:	429c                	lw	a5,0(a3)
ffffffffc0200afc:	0017871b          	addiw	a4,a5,1
ffffffffc0200b00:	c298                	sw	a4,0(a3)
ffffffffc0200b02:	bf6d                	j	ffffffffc0200abc <interrupt_handler+0x78>
}
ffffffffc0200b04:	60a2                	ld	ra,8(sp)
ffffffffc0200b06:	0141                	addi	sp,sp,16
                sbi_shutdown();
ffffffffc0200b08:	3cc0106f          	j	ffffffffc0201ed4 <sbi_shutdown>

ffffffffc0200b0c <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b0c:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b10:	1141                	addi	sp,sp,-16
ffffffffc0200b12:	e022                	sd	s0,0(sp)
ffffffffc0200b14:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b16:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b18:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b1a:	04e78e63          	beq	a5,a4,ffffffffc0200b76 <exception_handler+0x6a>
ffffffffc0200b1e:	04f76463          	bltu	a4,a5,ffffffffc0200b66 <exception_handler+0x5a>
ffffffffc0200b22:	4709                	li	a4,2
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            //2312130 景千夏BEGIN
            cprintf("Illegal instruction\n");
ffffffffc0200b24:	00002517          	auipc	a0,0x2
ffffffffc0200b28:	cbc50513          	addi	a0,a0,-836 # ffffffffc02027e0 <etext+0x834>
    switch (tf->cause) {
ffffffffc0200b2c:	02e79963          	bne	a5,a4,ffffffffc0200b5e <exception_handler+0x52>
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            //2312130 景千夏BEGIN
            cprintf("breakpoint\n");
ffffffffc0200b30:	da8ff0ef          	jal	ffffffffc02000d8 <cprintf>
            cprintf("Scaused:%llx \n",tf->cause);//输出长16进制数(64位二进制)异常指令类型
ffffffffc0200b34:	11843583          	ld	a1,280(s0)
ffffffffc0200b38:	00002517          	auipc	a0,0x2
ffffffffc0200b3c:	cc050513          	addi	a0,a0,-832 # ffffffffc02027f8 <etext+0x84c>
ffffffffc0200b40:	d98ff0ef          	jal	ffffffffc02000d8 <cprintf>
            cprintf("EPC:%llx \n",tf->epc);//输出长16进制数(64位二进制)异常指令地址
ffffffffc0200b44:	10843583          	ld	a1,264(s0)
ffffffffc0200b48:	00002517          	auipc	a0,0x2
ffffffffc0200b4c:	cc050513          	addi	a0,a0,-832 # ffffffffc0202808 <etext+0x85c>
ffffffffc0200b50:	d88ff0ef          	jal	ffffffffc02000d8 <cprintf>
            tf->epc += 4;//更新 tf->epc寄存器，指向下一条指令
ffffffffc0200b54:	10843783          	ld	a5,264(s0)
ffffffffc0200b58:	0791                	addi	a5,a5,4
ffffffffc0200b5a:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b5e:	60a2                	ld	ra,8(sp)
ffffffffc0200b60:	6402                	ld	s0,0(sp)
ffffffffc0200b62:	0141                	addi	sp,sp,16
ffffffffc0200b64:	8082                	ret
    switch (tf->cause) {
ffffffffc0200b66:	17f1                	addi	a5,a5,-4
ffffffffc0200b68:	471d                	li	a4,7
ffffffffc0200b6a:	fef77ae3          	bgeu	a4,a5,ffffffffc0200b5e <exception_handler+0x52>
}
ffffffffc0200b6e:	6402                	ld	s0,0(sp)
ffffffffc0200b70:	60a2                	ld	ra,8(sp)
ffffffffc0200b72:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b74:	b5bd                	j	ffffffffc02009e2 <print_trapframe>
            cprintf("breakpoint\n");
ffffffffc0200b76:	00002517          	auipc	a0,0x2
ffffffffc0200b7a:	ca250513          	addi	a0,a0,-862 # ffffffffc0202818 <etext+0x86c>
ffffffffc0200b7e:	bf4d                	j	ffffffffc0200b30 <exception_handler+0x24>

ffffffffc0200b80 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b80:	11853783          	ld	a5,280(a0)
ffffffffc0200b84:	0007c363          	bltz	a5,ffffffffc0200b8a <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b88:	b751                	j	ffffffffc0200b0c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b8a:	bd6d                	j	ffffffffc0200a44 <interrupt_handler>

ffffffffc0200b8c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b8c:	14011073          	csrw	sscratch,sp
ffffffffc0200b90:	712d                	addi	sp,sp,-288
ffffffffc0200b92:	e002                	sd	zero,0(sp)
ffffffffc0200b94:	e406                	sd	ra,8(sp)
ffffffffc0200b96:	ec0e                	sd	gp,24(sp)
ffffffffc0200b98:	f012                	sd	tp,32(sp)
ffffffffc0200b9a:	f416                	sd	t0,40(sp)
ffffffffc0200b9c:	f81a                	sd	t1,48(sp)
ffffffffc0200b9e:	fc1e                	sd	t2,56(sp)
ffffffffc0200ba0:	e0a2                	sd	s0,64(sp)
ffffffffc0200ba2:	e4a6                	sd	s1,72(sp)
ffffffffc0200ba4:	e8aa                	sd	a0,80(sp)
ffffffffc0200ba6:	ecae                	sd	a1,88(sp)
ffffffffc0200ba8:	f0b2                	sd	a2,96(sp)
ffffffffc0200baa:	f4b6                	sd	a3,104(sp)
ffffffffc0200bac:	f8ba                	sd	a4,112(sp)
ffffffffc0200bae:	fcbe                	sd	a5,120(sp)
ffffffffc0200bb0:	e142                	sd	a6,128(sp)
ffffffffc0200bb2:	e546                	sd	a7,136(sp)
ffffffffc0200bb4:	e94a                	sd	s2,144(sp)
ffffffffc0200bb6:	ed4e                	sd	s3,152(sp)
ffffffffc0200bb8:	f152                	sd	s4,160(sp)
ffffffffc0200bba:	f556                	sd	s5,168(sp)
ffffffffc0200bbc:	f95a                	sd	s6,176(sp)
ffffffffc0200bbe:	fd5e                	sd	s7,184(sp)
ffffffffc0200bc0:	e1e2                	sd	s8,192(sp)
ffffffffc0200bc2:	e5e6                	sd	s9,200(sp)
ffffffffc0200bc4:	e9ea                	sd	s10,208(sp)
ffffffffc0200bc6:	edee                	sd	s11,216(sp)
ffffffffc0200bc8:	f1f2                	sd	t3,224(sp)
ffffffffc0200bca:	f5f6                	sd	t4,232(sp)
ffffffffc0200bcc:	f9fa                	sd	t5,240(sp)
ffffffffc0200bce:	fdfe                	sd	t6,248(sp)
ffffffffc0200bd0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200bd4:	100024f3          	csrr	s1,sstatus
ffffffffc0200bd8:	14102973          	csrr	s2,sepc
ffffffffc0200bdc:	143029f3          	csrr	s3,stval
ffffffffc0200be0:	14202a73          	csrr	s4,scause
ffffffffc0200be4:	e822                	sd	s0,16(sp)
ffffffffc0200be6:	e226                	sd	s1,256(sp)
ffffffffc0200be8:	e64a                	sd	s2,264(sp)
ffffffffc0200bea:	ea4e                	sd	s3,272(sp)
ffffffffc0200bec:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bee:	850a                	mv	a0,sp
    jal trap
ffffffffc0200bf0:	f91ff0ef          	jal	ffffffffc0200b80 <trap>

ffffffffc0200bf4 <__trapret>:
C 文件 trap.c 里定义了一个函数名字也叫 trap；
所以链接器就自动把这两个引用匹配到一起。
完全不需要显式声明，只要符号名字对得上。*/
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200bf4:	6492                	ld	s1,256(sp)
ffffffffc0200bf6:	6932                	ld	s2,264(sp)
ffffffffc0200bf8:	10049073          	csrw	sstatus,s1
ffffffffc0200bfc:	14191073          	csrw	sepc,s2
ffffffffc0200c00:	60a2                	ld	ra,8(sp)
ffffffffc0200c02:	61e2                	ld	gp,24(sp)
ffffffffc0200c04:	7202                	ld	tp,32(sp)
ffffffffc0200c06:	72a2                	ld	t0,40(sp)
ffffffffc0200c08:	7342                	ld	t1,48(sp)
ffffffffc0200c0a:	73e2                	ld	t2,56(sp)
ffffffffc0200c0c:	6406                	ld	s0,64(sp)
ffffffffc0200c0e:	64a6                	ld	s1,72(sp)
ffffffffc0200c10:	6546                	ld	a0,80(sp)
ffffffffc0200c12:	65e6                	ld	a1,88(sp)
ffffffffc0200c14:	7606                	ld	a2,96(sp)
ffffffffc0200c16:	76a6                	ld	a3,104(sp)
ffffffffc0200c18:	7746                	ld	a4,112(sp)
ffffffffc0200c1a:	77e6                	ld	a5,120(sp)
ffffffffc0200c1c:	680a                	ld	a6,128(sp)
ffffffffc0200c1e:	68aa                	ld	a7,136(sp)
ffffffffc0200c20:	694a                	ld	s2,144(sp)
ffffffffc0200c22:	69ea                	ld	s3,152(sp)
ffffffffc0200c24:	7a0a                	ld	s4,160(sp)
ffffffffc0200c26:	7aaa                	ld	s5,168(sp)
ffffffffc0200c28:	7b4a                	ld	s6,176(sp)
ffffffffc0200c2a:	7bea                	ld	s7,184(sp)
ffffffffc0200c2c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c2e:	6cae                	ld	s9,200(sp)
ffffffffc0200c30:	6d4e                	ld	s10,208(sp)
ffffffffc0200c32:	6dee                	ld	s11,216(sp)
ffffffffc0200c34:	7e0e                	ld	t3,224(sp)
ffffffffc0200c36:	7eae                	ld	t4,232(sp)
ffffffffc0200c38:	7f4e                	ld	t5,240(sp)
ffffffffc0200c3a:	7fee                	ld	t6,248(sp)
ffffffffc0200c3c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c3e:	10200073          	sret

ffffffffc0200c42 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c42:	00006797          	auipc	a5,0x6
ffffffffc0200c46:	3e678793          	addi	a5,a5,998 # ffffffffc0207028 <free_area>
ffffffffc0200c4a:	e79c                	sd	a5,8(a5)
ffffffffc0200c4c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c4e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c52:	8082                	ret

ffffffffc0200c54 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c54:	00006517          	auipc	a0,0x6
ffffffffc0200c58:	3e456503          	lwu	a0,996(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200c5c:	8082                	ret

ffffffffc0200c5e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200c5e:	715d                	addi	sp,sp,-80
ffffffffc0200c60:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c62:	00006417          	auipc	s0,0x6
ffffffffc0200c66:	3c640413          	addi	s0,s0,966 # ffffffffc0207028 <free_area>
ffffffffc0200c6a:	641c                	ld	a5,8(s0)
ffffffffc0200c6c:	e486                	sd	ra,72(sp)
ffffffffc0200c6e:	fc26                	sd	s1,56(sp)
ffffffffc0200c70:	f84a                	sd	s2,48(sp)
ffffffffc0200c72:	f44e                	sd	s3,40(sp)
ffffffffc0200c74:	f052                	sd	s4,32(sp)
ffffffffc0200c76:	ec56                	sd	s5,24(sp)
ffffffffc0200c78:	e85a                	sd	s6,16(sp)
ffffffffc0200c7a:	e45e                	sd	s7,8(sp)
ffffffffc0200c7c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c7e:	2e878063          	beq	a5,s0,ffffffffc0200f5e <default_check+0x300>
    int count = 0, total = 0;
ffffffffc0200c82:	4481                	li	s1,0
ffffffffc0200c84:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c86:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c8a:	8b09                	andi	a4,a4,2
ffffffffc0200c8c:	2c070d63          	beqz	a4,ffffffffc0200f66 <default_check+0x308>
        count ++, total += p->property;
ffffffffc0200c90:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c94:	679c                	ld	a5,8(a5)
ffffffffc0200c96:	2905                	addiw	s2,s2,1
ffffffffc0200c98:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c9a:	fe8796e3          	bne	a5,s0,ffffffffc0200c86 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200c9e:	89a6                	mv	s3,s1
ffffffffc0200ca0:	30b000ef          	jal	ffffffffc02017aa <nr_free_pages>
ffffffffc0200ca4:	73351163          	bne	a0,s3,ffffffffc02013c6 <default_check+0x768>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ca8:	4505                	li	a0,1
ffffffffc0200caa:	283000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200cae:	8a2a                	mv	s4,a0
ffffffffc0200cb0:	44050b63          	beqz	a0,ffffffffc0201106 <default_check+0x4a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cb4:	4505                	li	a0,1
ffffffffc0200cb6:	277000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200cba:	89aa                	mv	s3,a0
ffffffffc0200cbc:	72050563          	beqz	a0,ffffffffc02013e6 <default_check+0x788>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cc0:	4505                	li	a0,1
ffffffffc0200cc2:	26b000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200cc6:	8aaa                	mv	s5,a0
ffffffffc0200cc8:	4a050f63          	beqz	a0,ffffffffc0201186 <default_check+0x528>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ccc:	2b3a0d63          	beq	s4,s3,ffffffffc0200f86 <default_check+0x328>
ffffffffc0200cd0:	2aaa0b63          	beq	s4,a0,ffffffffc0200f86 <default_check+0x328>
ffffffffc0200cd4:	2aa98963          	beq	s3,a0,ffffffffc0200f86 <default_check+0x328>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200cd8:	000a2783          	lw	a5,0(s4)
ffffffffc0200cdc:	2c079563          	bnez	a5,ffffffffc0200fa6 <default_check+0x348>
ffffffffc0200ce0:	0009a783          	lw	a5,0(s3)
ffffffffc0200ce4:	2c079163          	bnez	a5,ffffffffc0200fa6 <default_check+0x348>
ffffffffc0200ce8:	411c                	lw	a5,0(a0)
ffffffffc0200cea:	2a079e63          	bnez	a5,ffffffffc0200fa6 <default_check+0x348>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cee:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200cf2:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac582d>
ffffffffc0200cf6:	07b2                	slli	a5,a5,0xc
ffffffffc0200cf8:	ccd78793          	addi	a5,a5,-819
ffffffffc0200cfc:	07b2                	slli	a5,a5,0xc
ffffffffc0200cfe:	00006717          	auipc	a4,0x6
ffffffffc0200d02:	79273703          	ld	a4,1938(a4) # ffffffffc0207490 <pages>
ffffffffc0200d06:	ccd78793          	addi	a5,a5,-819
ffffffffc0200d0a:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200d0e:	07b2                	slli	a5,a5,0xc
ffffffffc0200d10:	868d                	srai	a3,a3,0x3
ffffffffc0200d12:	ccd78793          	addi	a5,a5,-819
ffffffffc0200d16:	02f686b3          	mul	a3,a3,a5
ffffffffc0200d1a:	00002597          	auipc	a1,0x2
ffffffffc0200d1e:	30e5b583          	ld	a1,782(a1) # ffffffffc0203028 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d22:	00006617          	auipc	a2,0x6
ffffffffc0200d26:	76663603          	ld	a2,1894(a2) # ffffffffc0207488 <npage>
ffffffffc0200d2a:	0632                	slli	a2,a2,0xc
ffffffffc0200d2c:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d2e:	06b2                	slli	a3,a3,0xc
ffffffffc0200d30:	28c6fb63          	bgeu	a3,a2,ffffffffc0200fc6 <default_check+0x368>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d34:	40e986b3          	sub	a3,s3,a4
ffffffffc0200d38:	868d                	srai	a3,a3,0x3
ffffffffc0200d3a:	02f686b3          	mul	a3,a3,a5
ffffffffc0200d3e:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d40:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d42:	4cc6f263          	bgeu	a3,a2,ffffffffc0201206 <default_check+0x5a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d46:	40e50733          	sub	a4,a0,a4
ffffffffc0200d4a:	870d                	srai	a4,a4,0x3
ffffffffc0200d4c:	02f707b3          	mul	a5,a4,a5
ffffffffc0200d50:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d52:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d54:	30c7f963          	bgeu	a5,a2,ffffffffc0201066 <default_check+0x408>
    assert(alloc_page() == NULL);
ffffffffc0200d58:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d5a:	00043c03          	ld	s8,0(s0)
ffffffffc0200d5e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d62:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200d66:	e400                	sd	s0,8(s0)
ffffffffc0200d68:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200d6a:	00006797          	auipc	a5,0x6
ffffffffc0200d6e:	2c07a723          	sw	zero,718(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d72:	1bb000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200d76:	2c051863          	bnez	a0,ffffffffc0201046 <default_check+0x3e8>
    free_page(p0);
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	8552                	mv	a0,s4
ffffffffc0200d7e:	1ed000ef          	jal	ffffffffc020176a <free_pages>
    free_page(p1);
ffffffffc0200d82:	4585                	li	a1,1
ffffffffc0200d84:	854e                	mv	a0,s3
ffffffffc0200d86:	1e5000ef          	jal	ffffffffc020176a <free_pages>
    free_page(p2);
ffffffffc0200d8a:	4585                	li	a1,1
ffffffffc0200d8c:	8556                	mv	a0,s5
ffffffffc0200d8e:	1dd000ef          	jal	ffffffffc020176a <free_pages>
    assert(nr_free == 3);
ffffffffc0200d92:	4818                	lw	a4,16(s0)
ffffffffc0200d94:	478d                	li	a5,3
ffffffffc0200d96:	28f71863          	bne	a4,a5,ffffffffc0201026 <default_check+0x3c8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d9a:	4505                	li	a0,1
ffffffffc0200d9c:	191000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200da0:	89aa                	mv	s3,a0
ffffffffc0200da2:	26050263          	beqz	a0,ffffffffc0201006 <default_check+0x3a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200da6:	4505                	li	a0,1
ffffffffc0200da8:	185000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200dac:	8aaa                	mv	s5,a0
ffffffffc0200dae:	3a050c63          	beqz	a0,ffffffffc0201166 <default_check+0x508>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200db2:	4505                	li	a0,1
ffffffffc0200db4:	179000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200db8:	8a2a                	mv	s4,a0
ffffffffc0200dba:	38050663          	beqz	a0,ffffffffc0201146 <default_check+0x4e8>
    assert(alloc_page() == NULL);
ffffffffc0200dbe:	4505                	li	a0,1
ffffffffc0200dc0:	16d000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200dc4:	36051163          	bnez	a0,ffffffffc0201126 <default_check+0x4c8>
    free_page(p0);
ffffffffc0200dc8:	4585                	li	a1,1
ffffffffc0200dca:	854e                	mv	a0,s3
ffffffffc0200dcc:	19f000ef          	jal	ffffffffc020176a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200dd0:	641c                	ld	a5,8(s0)
ffffffffc0200dd2:	20878a63          	beq	a5,s0,ffffffffc0200fe6 <default_check+0x388>
    assert((p = alloc_page()) == p0);
ffffffffc0200dd6:	4505                	li	a0,1
ffffffffc0200dd8:	155000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200ddc:	30a99563          	bne	s3,a0,ffffffffc02010e6 <default_check+0x488>
    assert(alloc_page() == NULL);
ffffffffc0200de0:	4505                	li	a0,1
ffffffffc0200de2:	14b000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200de6:	2e051063          	bnez	a0,ffffffffc02010c6 <default_check+0x468>
    assert(nr_free == 0);
ffffffffc0200dea:	481c                	lw	a5,16(s0)
ffffffffc0200dec:	2a079d63          	bnez	a5,ffffffffc02010a6 <default_check+0x448>
    free_page(p);
ffffffffc0200df0:	854e                	mv	a0,s3
ffffffffc0200df2:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200df4:	01843023          	sd	s8,0(s0)
ffffffffc0200df8:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200dfc:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e00:	16b000ef          	jal	ffffffffc020176a <free_pages>
    free_page(p1);
ffffffffc0200e04:	4585                	li	a1,1
ffffffffc0200e06:	8556                	mv	a0,s5
ffffffffc0200e08:	163000ef          	jal	ffffffffc020176a <free_pages>
    free_page(p2);
ffffffffc0200e0c:	4585                	li	a1,1
ffffffffc0200e0e:	8552                	mv	a0,s4
ffffffffc0200e10:	15b000ef          	jal	ffffffffc020176a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e14:	4515                	li	a0,5
ffffffffc0200e16:	117000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200e1a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e1c:	26050563          	beqz	a0,ffffffffc0201086 <default_check+0x428>
ffffffffc0200e20:	651c                	ld	a5,8(a0)
ffffffffc0200e22:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e24:	8b85                	andi	a5,a5,1
ffffffffc0200e26:	54079063          	bnez	a5,ffffffffc0201366 <default_check+0x708>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e2a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e2c:	00043b03          	ld	s6,0(s0)
ffffffffc0200e30:	00843a83          	ld	s5,8(s0)
ffffffffc0200e34:	e000                	sd	s0,0(s0)
ffffffffc0200e36:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200e38:	0f5000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200e3c:	50051563          	bnez	a0,ffffffffc0201346 <default_check+0x6e8>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200e40:	05098a13          	addi	s4,s3,80
ffffffffc0200e44:	8552                	mv	a0,s4
ffffffffc0200e46:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e48:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200e4c:	00006797          	auipc	a5,0x6
ffffffffc0200e50:	1e07a623          	sw	zero,492(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e54:	117000ef          	jal	ffffffffc020176a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e58:	4511                	li	a0,4
ffffffffc0200e5a:	0d3000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200e5e:	4c051463          	bnez	a0,ffffffffc0201326 <default_check+0x6c8>
ffffffffc0200e62:	0589b783          	ld	a5,88(s3)
ffffffffc0200e66:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200e68:	8b85                	andi	a5,a5,1
ffffffffc0200e6a:	48078e63          	beqz	a5,ffffffffc0201306 <default_check+0x6a8>
ffffffffc0200e6e:	0609a703          	lw	a4,96(s3)
ffffffffc0200e72:	478d                	li	a5,3
ffffffffc0200e74:	48f71963          	bne	a4,a5,ffffffffc0201306 <default_check+0x6a8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e78:	450d                	li	a0,3
ffffffffc0200e7a:	0b3000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200e7e:	8c2a                	mv	s8,a0
ffffffffc0200e80:	46050363          	beqz	a0,ffffffffc02012e6 <default_check+0x688>
    assert(alloc_page() == NULL);
ffffffffc0200e84:	4505                	li	a0,1
ffffffffc0200e86:	0a7000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200e8a:	42051e63          	bnez	a0,ffffffffc02012c6 <default_check+0x668>
    assert(p0 + 2 == p1);
ffffffffc0200e8e:	418a1c63          	bne	s4,s8,ffffffffc02012a6 <default_check+0x648>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200e92:	4585                	li	a1,1
ffffffffc0200e94:	854e                	mv	a0,s3
ffffffffc0200e96:	0d5000ef          	jal	ffffffffc020176a <free_pages>
    free_pages(p1, 3);
ffffffffc0200e9a:	458d                	li	a1,3
ffffffffc0200e9c:	8552                	mv	a0,s4
ffffffffc0200e9e:	0cd000ef          	jal	ffffffffc020176a <free_pages>
ffffffffc0200ea2:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200ea6:	02898c13          	addi	s8,s3,40
ffffffffc0200eaa:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200eac:	8b85                	andi	a5,a5,1
ffffffffc0200eae:	3c078c63          	beqz	a5,ffffffffc0201286 <default_check+0x628>
ffffffffc0200eb2:	0109a703          	lw	a4,16(s3)
ffffffffc0200eb6:	4785                	li	a5,1
ffffffffc0200eb8:	3cf71763          	bne	a4,a5,ffffffffc0201286 <default_check+0x628>
ffffffffc0200ebc:	008a3783          	ld	a5,8(s4)
ffffffffc0200ec0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200ec2:	8b85                	andi	a5,a5,1
ffffffffc0200ec4:	3a078163          	beqz	a5,ffffffffc0201266 <default_check+0x608>
ffffffffc0200ec8:	010a2703          	lw	a4,16(s4)
ffffffffc0200ecc:	478d                	li	a5,3
ffffffffc0200ece:	38f71c63          	bne	a4,a5,ffffffffc0201266 <default_check+0x608>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200ed2:	4505                	li	a0,1
ffffffffc0200ed4:	059000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200ed8:	36a99763          	bne	s3,a0,ffffffffc0201246 <default_check+0x5e8>
    free_page(p0);
ffffffffc0200edc:	4585                	li	a1,1
ffffffffc0200ede:	08d000ef          	jal	ffffffffc020176a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200ee2:	4509                	li	a0,2
ffffffffc0200ee4:	049000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200ee8:	32aa1f63          	bne	s4,a0,ffffffffc0201226 <default_check+0x5c8>

    free_pages(p0, 2);
ffffffffc0200eec:	4589                	li	a1,2
ffffffffc0200eee:	07d000ef          	jal	ffffffffc020176a <free_pages>
    free_page(p2);
ffffffffc0200ef2:	4585                	li	a1,1
ffffffffc0200ef4:	8562                	mv	a0,s8
ffffffffc0200ef6:	075000ef          	jal	ffffffffc020176a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200efa:	4515                	li	a0,5
ffffffffc0200efc:	031000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200f00:	89aa                	mv	s3,a0
ffffffffc0200f02:	48050263          	beqz	a0,ffffffffc0201386 <default_check+0x728>
    assert(alloc_page() == NULL);
ffffffffc0200f06:	4505                	li	a0,1
ffffffffc0200f08:	025000ef          	jal	ffffffffc020172c <alloc_pages>
ffffffffc0200f0c:	2c051d63          	bnez	a0,ffffffffc02011e6 <default_check+0x588>

    assert(nr_free == 0);
ffffffffc0200f10:	481c                	lw	a5,16(s0)
ffffffffc0200f12:	2a079a63          	bnez	a5,ffffffffc02011c6 <default_check+0x568>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f16:	4595                	li	a1,5
ffffffffc0200f18:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f1a:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200f1e:	01643023          	sd	s6,0(s0)
ffffffffc0200f22:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200f26:	045000ef          	jal	ffffffffc020176a <free_pages>
    return listelm->next;
ffffffffc0200f2a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f2c:	00878963          	beq	a5,s0,ffffffffc0200f3e <default_check+0x2e0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200f30:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f34:	679c                	ld	a5,8(a5)
ffffffffc0200f36:	397d                	addiw	s2,s2,-1
ffffffffc0200f38:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f3a:	fe879be3          	bne	a5,s0,ffffffffc0200f30 <default_check+0x2d2>
    }
    assert(count == 0);
ffffffffc0200f3e:	26091463          	bnez	s2,ffffffffc02011a6 <default_check+0x548>
    assert(total == 0);
ffffffffc0200f42:	46049263          	bnez	s1,ffffffffc02013a6 <default_check+0x748>
}
ffffffffc0200f46:	60a6                	ld	ra,72(sp)
ffffffffc0200f48:	6406                	ld	s0,64(sp)
ffffffffc0200f4a:	74e2                	ld	s1,56(sp)
ffffffffc0200f4c:	7942                	ld	s2,48(sp)
ffffffffc0200f4e:	79a2                	ld	s3,40(sp)
ffffffffc0200f50:	7a02                	ld	s4,32(sp)
ffffffffc0200f52:	6ae2                	ld	s5,24(sp)
ffffffffc0200f54:	6b42                	ld	s6,16(sp)
ffffffffc0200f56:	6ba2                	ld	s7,8(sp)
ffffffffc0200f58:	6c02                	ld	s8,0(sp)
ffffffffc0200f5a:	6161                	addi	sp,sp,80
ffffffffc0200f5c:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f5e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f60:	4481                	li	s1,0
ffffffffc0200f62:	4901                	li	s2,0
ffffffffc0200f64:	bb35                	j	ffffffffc0200ca0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200f66:	00002697          	auipc	a3,0x2
ffffffffc0200f6a:	8c268693          	addi	a3,a3,-1854 # ffffffffc0202828 <etext+0x87c>
ffffffffc0200f6e:	00002617          	auipc	a2,0x2
ffffffffc0200f72:	8ca60613          	addi	a2,a2,-1846 # ffffffffc0202838 <etext+0x88c>
ffffffffc0200f76:	0f000593          	li	a1,240
ffffffffc0200f7a:	00002517          	auipc	a0,0x2
ffffffffc0200f7e:	8d650513          	addi	a0,a0,-1834 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0200f82:	c4aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f86:	00002697          	auipc	a3,0x2
ffffffffc0200f8a:	96268693          	addi	a3,a3,-1694 # ffffffffc02028e8 <etext+0x93c>
ffffffffc0200f8e:	00002617          	auipc	a2,0x2
ffffffffc0200f92:	8aa60613          	addi	a2,a2,-1878 # ffffffffc0202838 <etext+0x88c>
ffffffffc0200f96:	0bd00593          	li	a1,189
ffffffffc0200f9a:	00002517          	auipc	a0,0x2
ffffffffc0200f9e:	8b650513          	addi	a0,a0,-1866 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0200fa2:	c2aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200fa6:	00002697          	auipc	a3,0x2
ffffffffc0200faa:	96a68693          	addi	a3,a3,-1686 # ffffffffc0202910 <etext+0x964>
ffffffffc0200fae:	00002617          	auipc	a2,0x2
ffffffffc0200fb2:	88a60613          	addi	a2,a2,-1910 # ffffffffc0202838 <etext+0x88c>
ffffffffc0200fb6:	0be00593          	li	a1,190
ffffffffc0200fba:	00002517          	auipc	a0,0x2
ffffffffc0200fbe:	89650513          	addi	a0,a0,-1898 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0200fc2:	c0aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200fc6:	00002697          	auipc	a3,0x2
ffffffffc0200fca:	98a68693          	addi	a3,a3,-1654 # ffffffffc0202950 <etext+0x9a4>
ffffffffc0200fce:	00002617          	auipc	a2,0x2
ffffffffc0200fd2:	86a60613          	addi	a2,a2,-1942 # ffffffffc0202838 <etext+0x88c>
ffffffffc0200fd6:	0c000593          	li	a1,192
ffffffffc0200fda:	00002517          	auipc	a0,0x2
ffffffffc0200fde:	87650513          	addi	a0,a0,-1930 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0200fe2:	beaff0ef          	jal	ffffffffc02003cc <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200fe6:	00002697          	auipc	a3,0x2
ffffffffc0200fea:	9f268693          	addi	a3,a3,-1550 # ffffffffc02029d8 <etext+0xa2c>
ffffffffc0200fee:	00002617          	auipc	a2,0x2
ffffffffc0200ff2:	84a60613          	addi	a2,a2,-1974 # ffffffffc0202838 <etext+0x88c>
ffffffffc0200ff6:	0d900593          	li	a1,217
ffffffffc0200ffa:	00002517          	auipc	a0,0x2
ffffffffc0200ffe:	85650513          	addi	a0,a0,-1962 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201002:	bcaff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201006:	00002697          	auipc	a3,0x2
ffffffffc020100a:	88268693          	addi	a3,a3,-1918 # ffffffffc0202888 <etext+0x8dc>
ffffffffc020100e:	00002617          	auipc	a2,0x2
ffffffffc0201012:	82a60613          	addi	a2,a2,-2006 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201016:	0d200593          	li	a1,210
ffffffffc020101a:	00002517          	auipc	a0,0x2
ffffffffc020101e:	83650513          	addi	a0,a0,-1994 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201022:	baaff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 3);
ffffffffc0201026:	00002697          	auipc	a3,0x2
ffffffffc020102a:	9a268693          	addi	a3,a3,-1630 # ffffffffc02029c8 <etext+0xa1c>
ffffffffc020102e:	00002617          	auipc	a2,0x2
ffffffffc0201032:	80a60613          	addi	a2,a2,-2038 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201036:	0d000593          	li	a1,208
ffffffffc020103a:	00002517          	auipc	a0,0x2
ffffffffc020103e:	81650513          	addi	a0,a0,-2026 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201042:	b8aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201046:	00002697          	auipc	a3,0x2
ffffffffc020104a:	96a68693          	addi	a3,a3,-1686 # ffffffffc02029b0 <etext+0xa04>
ffffffffc020104e:	00001617          	auipc	a2,0x1
ffffffffc0201052:	7ea60613          	addi	a2,a2,2026 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201056:	0cb00593          	li	a1,203
ffffffffc020105a:	00001517          	auipc	a0,0x1
ffffffffc020105e:	7f650513          	addi	a0,a0,2038 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201062:	b6aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201066:	00002697          	auipc	a3,0x2
ffffffffc020106a:	92a68693          	addi	a3,a3,-1750 # ffffffffc0202990 <etext+0x9e4>
ffffffffc020106e:	00001617          	auipc	a2,0x1
ffffffffc0201072:	7ca60613          	addi	a2,a2,1994 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201076:	0c200593          	li	a1,194
ffffffffc020107a:	00001517          	auipc	a0,0x1
ffffffffc020107e:	7d650513          	addi	a0,a0,2006 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201082:	b4aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 != NULL);
ffffffffc0201086:	00002697          	auipc	a3,0x2
ffffffffc020108a:	99a68693          	addi	a3,a3,-1638 # ffffffffc0202a20 <etext+0xa74>
ffffffffc020108e:	00001617          	auipc	a2,0x1
ffffffffc0201092:	7aa60613          	addi	a2,a2,1962 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201096:	0f800593          	li	a1,248
ffffffffc020109a:	00001517          	auipc	a0,0x1
ffffffffc020109e:	7b650513          	addi	a0,a0,1974 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02010a2:	b2aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 0);
ffffffffc02010a6:	00002697          	auipc	a3,0x2
ffffffffc02010aa:	96a68693          	addi	a3,a3,-1686 # ffffffffc0202a10 <etext+0xa64>
ffffffffc02010ae:	00001617          	auipc	a2,0x1
ffffffffc02010b2:	78a60613          	addi	a2,a2,1930 # ffffffffc0202838 <etext+0x88c>
ffffffffc02010b6:	0df00593          	li	a1,223
ffffffffc02010ba:	00001517          	auipc	a0,0x1
ffffffffc02010be:	79650513          	addi	a0,a0,1942 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02010c2:	b0aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010c6:	00002697          	auipc	a3,0x2
ffffffffc02010ca:	8ea68693          	addi	a3,a3,-1814 # ffffffffc02029b0 <etext+0xa04>
ffffffffc02010ce:	00001617          	auipc	a2,0x1
ffffffffc02010d2:	76a60613          	addi	a2,a2,1898 # ffffffffc0202838 <etext+0x88c>
ffffffffc02010d6:	0dd00593          	li	a1,221
ffffffffc02010da:	00001517          	auipc	a0,0x1
ffffffffc02010de:	77650513          	addi	a0,a0,1910 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02010e2:	aeaff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02010e6:	00002697          	auipc	a3,0x2
ffffffffc02010ea:	90a68693          	addi	a3,a3,-1782 # ffffffffc02029f0 <etext+0xa44>
ffffffffc02010ee:	00001617          	auipc	a2,0x1
ffffffffc02010f2:	74a60613          	addi	a2,a2,1866 # ffffffffc0202838 <etext+0x88c>
ffffffffc02010f6:	0dc00593          	li	a1,220
ffffffffc02010fa:	00001517          	auipc	a0,0x1
ffffffffc02010fe:	75650513          	addi	a0,a0,1878 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201102:	acaff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201106:	00001697          	auipc	a3,0x1
ffffffffc020110a:	78268693          	addi	a3,a3,1922 # ffffffffc0202888 <etext+0x8dc>
ffffffffc020110e:	00001617          	auipc	a2,0x1
ffffffffc0201112:	72a60613          	addi	a2,a2,1834 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201116:	0b900593          	li	a1,185
ffffffffc020111a:	00001517          	auipc	a0,0x1
ffffffffc020111e:	73650513          	addi	a0,a0,1846 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201122:	aaaff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201126:	00002697          	auipc	a3,0x2
ffffffffc020112a:	88a68693          	addi	a3,a3,-1910 # ffffffffc02029b0 <etext+0xa04>
ffffffffc020112e:	00001617          	auipc	a2,0x1
ffffffffc0201132:	70a60613          	addi	a2,a2,1802 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201136:	0d600593          	li	a1,214
ffffffffc020113a:	00001517          	auipc	a0,0x1
ffffffffc020113e:	71650513          	addi	a0,a0,1814 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201142:	a8aff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201146:	00001697          	auipc	a3,0x1
ffffffffc020114a:	78268693          	addi	a3,a3,1922 # ffffffffc02028c8 <etext+0x91c>
ffffffffc020114e:	00001617          	auipc	a2,0x1
ffffffffc0201152:	6ea60613          	addi	a2,a2,1770 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201156:	0d400593          	li	a1,212
ffffffffc020115a:	00001517          	auipc	a0,0x1
ffffffffc020115e:	6f650513          	addi	a0,a0,1782 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201162:	a6aff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201166:	00001697          	auipc	a3,0x1
ffffffffc020116a:	74268693          	addi	a3,a3,1858 # ffffffffc02028a8 <etext+0x8fc>
ffffffffc020116e:	00001617          	auipc	a2,0x1
ffffffffc0201172:	6ca60613          	addi	a2,a2,1738 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201176:	0d300593          	li	a1,211
ffffffffc020117a:	00001517          	auipc	a0,0x1
ffffffffc020117e:	6d650513          	addi	a0,a0,1750 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201182:	a4aff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201186:	00001697          	auipc	a3,0x1
ffffffffc020118a:	74268693          	addi	a3,a3,1858 # ffffffffc02028c8 <etext+0x91c>
ffffffffc020118e:	00001617          	auipc	a2,0x1
ffffffffc0201192:	6aa60613          	addi	a2,a2,1706 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201196:	0bb00593          	li	a1,187
ffffffffc020119a:	00001517          	auipc	a0,0x1
ffffffffc020119e:	6b650513          	addi	a0,a0,1718 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02011a2:	a2aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(count == 0);
ffffffffc02011a6:	00002697          	auipc	a3,0x2
ffffffffc02011aa:	9ca68693          	addi	a3,a3,-1590 # ffffffffc0202b70 <etext+0xbc4>
ffffffffc02011ae:	00001617          	auipc	a2,0x1
ffffffffc02011b2:	68a60613          	addi	a2,a2,1674 # ffffffffc0202838 <etext+0x88c>
ffffffffc02011b6:	12500593          	li	a1,293
ffffffffc02011ba:	00001517          	auipc	a0,0x1
ffffffffc02011be:	69650513          	addi	a0,a0,1686 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02011c2:	a0aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 0);
ffffffffc02011c6:	00002697          	auipc	a3,0x2
ffffffffc02011ca:	84a68693          	addi	a3,a3,-1974 # ffffffffc0202a10 <etext+0xa64>
ffffffffc02011ce:	00001617          	auipc	a2,0x1
ffffffffc02011d2:	66a60613          	addi	a2,a2,1642 # ffffffffc0202838 <etext+0x88c>
ffffffffc02011d6:	11a00593          	li	a1,282
ffffffffc02011da:	00001517          	auipc	a0,0x1
ffffffffc02011de:	67650513          	addi	a0,a0,1654 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02011e2:	9eaff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011e6:	00001697          	auipc	a3,0x1
ffffffffc02011ea:	7ca68693          	addi	a3,a3,1994 # ffffffffc02029b0 <etext+0xa04>
ffffffffc02011ee:	00001617          	auipc	a2,0x1
ffffffffc02011f2:	64a60613          	addi	a2,a2,1610 # ffffffffc0202838 <etext+0x88c>
ffffffffc02011f6:	11800593          	li	a1,280
ffffffffc02011fa:	00001517          	auipc	a0,0x1
ffffffffc02011fe:	65650513          	addi	a0,a0,1622 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201202:	9caff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201206:	00001697          	auipc	a3,0x1
ffffffffc020120a:	76a68693          	addi	a3,a3,1898 # ffffffffc0202970 <etext+0x9c4>
ffffffffc020120e:	00001617          	auipc	a2,0x1
ffffffffc0201212:	62a60613          	addi	a2,a2,1578 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201216:	0c100593          	li	a1,193
ffffffffc020121a:	00001517          	auipc	a0,0x1
ffffffffc020121e:	63650513          	addi	a0,a0,1590 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201222:	9aaff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201226:	00002697          	auipc	a3,0x2
ffffffffc020122a:	90a68693          	addi	a3,a3,-1782 # ffffffffc0202b30 <etext+0xb84>
ffffffffc020122e:	00001617          	auipc	a2,0x1
ffffffffc0201232:	60a60613          	addi	a2,a2,1546 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201236:	11200593          	li	a1,274
ffffffffc020123a:	00001517          	auipc	a0,0x1
ffffffffc020123e:	61650513          	addi	a0,a0,1558 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201242:	98aff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201246:	00002697          	auipc	a3,0x2
ffffffffc020124a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0202b10 <etext+0xb64>
ffffffffc020124e:	00001617          	auipc	a2,0x1
ffffffffc0201252:	5ea60613          	addi	a2,a2,1514 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201256:	11000593          	li	a1,272
ffffffffc020125a:	00001517          	auipc	a0,0x1
ffffffffc020125e:	5f650513          	addi	a0,a0,1526 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201262:	96aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201266:	00002697          	auipc	a3,0x2
ffffffffc020126a:	88268693          	addi	a3,a3,-1918 # ffffffffc0202ae8 <etext+0xb3c>
ffffffffc020126e:	00001617          	auipc	a2,0x1
ffffffffc0201272:	5ca60613          	addi	a2,a2,1482 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201276:	10e00593          	li	a1,270
ffffffffc020127a:	00001517          	auipc	a0,0x1
ffffffffc020127e:	5d650513          	addi	a0,a0,1494 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201282:	94aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201286:	00002697          	auipc	a3,0x2
ffffffffc020128a:	83a68693          	addi	a3,a3,-1990 # ffffffffc0202ac0 <etext+0xb14>
ffffffffc020128e:	00001617          	auipc	a2,0x1
ffffffffc0201292:	5aa60613          	addi	a2,a2,1450 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201296:	10d00593          	li	a1,269
ffffffffc020129a:	00001517          	auipc	a0,0x1
ffffffffc020129e:	5b650513          	addi	a0,a0,1462 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02012a2:	92aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 + 2 == p1);
ffffffffc02012a6:	00002697          	auipc	a3,0x2
ffffffffc02012aa:	80a68693          	addi	a3,a3,-2038 # ffffffffc0202ab0 <etext+0xb04>
ffffffffc02012ae:	00001617          	auipc	a2,0x1
ffffffffc02012b2:	58a60613          	addi	a2,a2,1418 # ffffffffc0202838 <etext+0x88c>
ffffffffc02012b6:	10800593          	li	a1,264
ffffffffc02012ba:	00001517          	auipc	a0,0x1
ffffffffc02012be:	59650513          	addi	a0,a0,1430 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02012c2:	90aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012c6:	00001697          	auipc	a3,0x1
ffffffffc02012ca:	6ea68693          	addi	a3,a3,1770 # ffffffffc02029b0 <etext+0xa04>
ffffffffc02012ce:	00001617          	auipc	a2,0x1
ffffffffc02012d2:	56a60613          	addi	a2,a2,1386 # ffffffffc0202838 <etext+0x88c>
ffffffffc02012d6:	10700593          	li	a1,263
ffffffffc02012da:	00001517          	auipc	a0,0x1
ffffffffc02012de:	57650513          	addi	a0,a0,1398 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02012e2:	8eaff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02012e6:	00001697          	auipc	a3,0x1
ffffffffc02012ea:	7aa68693          	addi	a3,a3,1962 # ffffffffc0202a90 <etext+0xae4>
ffffffffc02012ee:	00001617          	auipc	a2,0x1
ffffffffc02012f2:	54a60613          	addi	a2,a2,1354 # ffffffffc0202838 <etext+0x88c>
ffffffffc02012f6:	10600593          	li	a1,262
ffffffffc02012fa:	00001517          	auipc	a0,0x1
ffffffffc02012fe:	55650513          	addi	a0,a0,1366 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201302:	8caff0ef          	jal	ffffffffc02003cc <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201306:	00001697          	auipc	a3,0x1
ffffffffc020130a:	75a68693          	addi	a3,a3,1882 # ffffffffc0202a60 <etext+0xab4>
ffffffffc020130e:	00001617          	auipc	a2,0x1
ffffffffc0201312:	52a60613          	addi	a2,a2,1322 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201316:	10500593          	li	a1,261
ffffffffc020131a:	00001517          	auipc	a0,0x1
ffffffffc020131e:	53650513          	addi	a0,a0,1334 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201322:	8aaff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201326:	00001697          	auipc	a3,0x1
ffffffffc020132a:	72268693          	addi	a3,a3,1826 # ffffffffc0202a48 <etext+0xa9c>
ffffffffc020132e:	00001617          	auipc	a2,0x1
ffffffffc0201332:	50a60613          	addi	a2,a2,1290 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201336:	10400593          	li	a1,260
ffffffffc020133a:	00001517          	auipc	a0,0x1
ffffffffc020133e:	51650513          	addi	a0,a0,1302 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201342:	88aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201346:	00001697          	auipc	a3,0x1
ffffffffc020134a:	66a68693          	addi	a3,a3,1642 # ffffffffc02029b0 <etext+0xa04>
ffffffffc020134e:	00001617          	auipc	a2,0x1
ffffffffc0201352:	4ea60613          	addi	a2,a2,1258 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201356:	0fe00593          	li	a1,254
ffffffffc020135a:	00001517          	auipc	a0,0x1
ffffffffc020135e:	4f650513          	addi	a0,a0,1270 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201362:	86aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(!PageProperty(p0));
ffffffffc0201366:	00001697          	auipc	a3,0x1
ffffffffc020136a:	6ca68693          	addi	a3,a3,1738 # ffffffffc0202a30 <etext+0xa84>
ffffffffc020136e:	00001617          	auipc	a2,0x1
ffffffffc0201372:	4ca60613          	addi	a2,a2,1226 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201376:	0f900593          	li	a1,249
ffffffffc020137a:	00001517          	auipc	a0,0x1
ffffffffc020137e:	4d650513          	addi	a0,a0,1238 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201382:	84aff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201386:	00001697          	auipc	a3,0x1
ffffffffc020138a:	7ca68693          	addi	a3,a3,1994 # ffffffffc0202b50 <etext+0xba4>
ffffffffc020138e:	00001617          	auipc	a2,0x1
ffffffffc0201392:	4aa60613          	addi	a2,a2,1194 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201396:	11700593          	li	a1,279
ffffffffc020139a:	00001517          	auipc	a0,0x1
ffffffffc020139e:	4b650513          	addi	a0,a0,1206 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02013a2:	82aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(total == 0);
ffffffffc02013a6:	00001697          	auipc	a3,0x1
ffffffffc02013aa:	7da68693          	addi	a3,a3,2010 # ffffffffc0202b80 <etext+0xbd4>
ffffffffc02013ae:	00001617          	auipc	a2,0x1
ffffffffc02013b2:	48a60613          	addi	a2,a2,1162 # ffffffffc0202838 <etext+0x88c>
ffffffffc02013b6:	12600593          	li	a1,294
ffffffffc02013ba:	00001517          	auipc	a0,0x1
ffffffffc02013be:	49650513          	addi	a0,a0,1174 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02013c2:	80aff0ef          	jal	ffffffffc02003cc <__panic>
    assert(total == nr_free_pages());
ffffffffc02013c6:	00001697          	auipc	a3,0x1
ffffffffc02013ca:	4a268693          	addi	a3,a3,1186 # ffffffffc0202868 <etext+0x8bc>
ffffffffc02013ce:	00001617          	auipc	a2,0x1
ffffffffc02013d2:	46a60613          	addi	a2,a2,1130 # ffffffffc0202838 <etext+0x88c>
ffffffffc02013d6:	0f300593          	li	a1,243
ffffffffc02013da:	00001517          	auipc	a0,0x1
ffffffffc02013de:	47650513          	addi	a0,a0,1142 # ffffffffc0202850 <etext+0x8a4>
ffffffffc02013e2:	febfe0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013e6:	00001697          	auipc	a3,0x1
ffffffffc02013ea:	4c268693          	addi	a3,a3,1218 # ffffffffc02028a8 <etext+0x8fc>
ffffffffc02013ee:	00001617          	auipc	a2,0x1
ffffffffc02013f2:	44a60613          	addi	a2,a2,1098 # ffffffffc0202838 <etext+0x88c>
ffffffffc02013f6:	0ba00593          	li	a1,186
ffffffffc02013fa:	00001517          	auipc	a0,0x1
ffffffffc02013fe:	45650513          	addi	a0,a0,1110 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201402:	fcbfe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0201406 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201406:	1141                	addi	sp,sp,-16
ffffffffc0201408:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020140a:	14058a63          	beqz	a1,ffffffffc020155e <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020140e:	00259713          	slli	a4,a1,0x2
ffffffffc0201412:	972e                	add	a4,a4,a1
ffffffffc0201414:	070e                	slli	a4,a4,0x3
ffffffffc0201416:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020141a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020141c:	c30d                	beqz	a4,ffffffffc020143e <default_free_pages+0x38>
ffffffffc020141e:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201420:	8b05                	andi	a4,a4,1
ffffffffc0201422:	10071e63          	bnez	a4,ffffffffc020153e <default_free_pages+0x138>
ffffffffc0201426:	6798                	ld	a4,8(a5)
ffffffffc0201428:	8b09                	andi	a4,a4,2
ffffffffc020142a:	10071a63          	bnez	a4,ffffffffc020153e <default_free_pages+0x138>
        p->flags = 0;
ffffffffc020142e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201432:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201436:	02878793          	addi	a5,a5,40
ffffffffc020143a:	fed792e3          	bne	a5,a3,ffffffffc020141e <default_free_pages+0x18>
    base->property = n;
ffffffffc020143e:	2581                	sext.w	a1,a1
ffffffffc0201440:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201442:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201446:	4789                	li	a5,2
ffffffffc0201448:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020144c:	00006697          	auipc	a3,0x6
ffffffffc0201450:	bdc68693          	addi	a3,a3,-1060 # ffffffffc0207028 <free_area>
ffffffffc0201454:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201456:	669c                	ld	a5,8(a3)
ffffffffc0201458:	9f2d                	addw	a4,a4,a1
ffffffffc020145a:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020145c:	0ad78563          	beq	a5,a3,ffffffffc0201506 <default_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc0201460:	fe878713          	addi	a4,a5,-24
ffffffffc0201464:	4581                	li	a1,0
ffffffffc0201466:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc020146a:	00e56a63          	bltu	a0,a4,ffffffffc020147e <default_free_pages+0x78>
    return listelm->next;
ffffffffc020146e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201470:	06d70263          	beq	a4,a3,ffffffffc02014d4 <default_free_pages+0xce>
    struct Page *p = base;
ffffffffc0201474:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201476:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020147a:	fee57ae3          	bgeu	a0,a4,ffffffffc020146e <default_free_pages+0x68>
ffffffffc020147e:	c199                	beqz	a1,ffffffffc0201484 <default_free_pages+0x7e>
ffffffffc0201480:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201484:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201486:	e390                	sd	a2,0(a5)
ffffffffc0201488:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020148a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020148c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020148e:	02d70063          	beq	a4,a3,ffffffffc02014ae <default_free_pages+0xa8>
        if (p + p->property == base) {
ffffffffc0201492:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201496:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc020149a:	02081613          	slli	a2,a6,0x20
ffffffffc020149e:	9201                	srli	a2,a2,0x20
ffffffffc02014a0:	00261793          	slli	a5,a2,0x2
ffffffffc02014a4:	97b2                	add	a5,a5,a2
ffffffffc02014a6:	078e                	slli	a5,a5,0x3
ffffffffc02014a8:	97ae                	add	a5,a5,a1
ffffffffc02014aa:	02f50f63          	beq	a0,a5,ffffffffc02014e8 <default_free_pages+0xe2>
    return listelm->next;
ffffffffc02014ae:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014b0:	00d70f63          	beq	a4,a3,ffffffffc02014ce <default_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc02014b4:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02014b6:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02014ba:	02059613          	slli	a2,a1,0x20
ffffffffc02014be:	9201                	srli	a2,a2,0x20
ffffffffc02014c0:	00261793          	slli	a5,a2,0x2
ffffffffc02014c4:	97b2                	add	a5,a5,a2
ffffffffc02014c6:	078e                	slli	a5,a5,0x3
ffffffffc02014c8:	97aa                	add	a5,a5,a0
ffffffffc02014ca:	04f68a63          	beq	a3,a5,ffffffffc020151e <default_free_pages+0x118>
}
ffffffffc02014ce:	60a2                	ld	ra,8(sp)
ffffffffc02014d0:	0141                	addi	sp,sp,16
ffffffffc02014d2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014d4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014d6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02014d8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014da:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02014dc:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014de:	02d70d63          	beq	a4,a3,ffffffffc0201518 <default_free_pages+0x112>
ffffffffc02014e2:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02014e4:	87ba                	mv	a5,a4
ffffffffc02014e6:	bf41                	j	ffffffffc0201476 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02014e8:	491c                	lw	a5,16(a0)
ffffffffc02014ea:	010787bb          	addw	a5,a5,a6
ffffffffc02014ee:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014f2:	57f5                	li	a5,-3
ffffffffc02014f4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014f8:	6d10                	ld	a2,24(a0)
ffffffffc02014fa:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02014fc:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02014fe:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201500:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201502:	e390                	sd	a2,0(a5)
ffffffffc0201504:	b775                	j	ffffffffc02014b0 <default_free_pages+0xaa>
}
ffffffffc0201506:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201508:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020150c:	e398                	sd	a4,0(a5)
ffffffffc020150e:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201510:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201512:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201514:	0141                	addi	sp,sp,16
ffffffffc0201516:	8082                	ret
ffffffffc0201518:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020151a:	873e                	mv	a4,a5
ffffffffc020151c:	bf8d                	j	ffffffffc020148e <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020151e:	ff872783          	lw	a5,-8(a4)
ffffffffc0201522:	ff070693          	addi	a3,a4,-16
ffffffffc0201526:	9fad                	addw	a5,a5,a1
ffffffffc0201528:	c91c                	sw	a5,16(a0)
ffffffffc020152a:	57f5                	li	a5,-3
ffffffffc020152c:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201530:	6314                	ld	a3,0(a4)
ffffffffc0201532:	671c                	ld	a5,8(a4)
}
ffffffffc0201534:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201536:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201538:	e394                	sd	a3,0(a5)
ffffffffc020153a:	0141                	addi	sp,sp,16
ffffffffc020153c:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020153e:	00001697          	auipc	a3,0x1
ffffffffc0201542:	65a68693          	addi	a3,a3,1626 # ffffffffc0202b98 <etext+0xbec>
ffffffffc0201546:	00001617          	auipc	a2,0x1
ffffffffc020154a:	2f260613          	addi	a2,a2,754 # ffffffffc0202838 <etext+0x88c>
ffffffffc020154e:	08300593          	li	a1,131
ffffffffc0201552:	00001517          	auipc	a0,0x1
ffffffffc0201556:	2fe50513          	addi	a0,a0,766 # ffffffffc0202850 <etext+0x8a4>
ffffffffc020155a:	e73fe0ef          	jal	ffffffffc02003cc <__panic>
    assert(n > 0);
ffffffffc020155e:	00001697          	auipc	a3,0x1
ffffffffc0201562:	63268693          	addi	a3,a3,1586 # ffffffffc0202b90 <etext+0xbe4>
ffffffffc0201566:	00001617          	auipc	a2,0x1
ffffffffc020156a:	2d260613          	addi	a2,a2,722 # ffffffffc0202838 <etext+0x88c>
ffffffffc020156e:	08000593          	li	a1,128
ffffffffc0201572:	00001517          	auipc	a0,0x1
ffffffffc0201576:	2de50513          	addi	a0,a0,734 # ffffffffc0202850 <etext+0x8a4>
ffffffffc020157a:	e53fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc020157e <default_alloc_pages>:
    assert(n > 0);
ffffffffc020157e:	c959                	beqz	a0,ffffffffc0201614 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0201580:	00006617          	auipc	a2,0x6
ffffffffc0201584:	aa860613          	addi	a2,a2,-1368 # ffffffffc0207028 <free_area>
ffffffffc0201588:	4a0c                	lw	a1,16(a2)
ffffffffc020158a:	86aa                	mv	a3,a0
ffffffffc020158c:	02059793          	slli	a5,a1,0x20
ffffffffc0201590:	9381                	srli	a5,a5,0x20
ffffffffc0201592:	00a7eb63          	bltu	a5,a0,ffffffffc02015a8 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc0201596:	87b2                	mv	a5,a2
ffffffffc0201598:	a029                	j	ffffffffc02015a2 <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc020159a:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020159e:	00d77763          	bgeu	a4,a3,ffffffffc02015ac <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc02015a2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015a4:	fec79be3          	bne	a5,a2,ffffffffc020159a <default_alloc_pages+0x1c>
        return NULL;
ffffffffc02015a8:	4501                	li	a0,0
}
ffffffffc02015aa:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc02015ac:	6798                	ld	a4,8(a5)
    return listelm->prev;
ffffffffc02015ae:	0007b803          	ld	a6,0(a5)
        if (page->property > n) {
ffffffffc02015b2:	ff87a883          	lw	a7,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02015b6:	fe878513          	addi	a0,a5,-24
    prev->next = next;
ffffffffc02015ba:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02015be:	01073023          	sd	a6,0(a4)
        if (page->property > n) {
ffffffffc02015c2:	02089713          	slli	a4,a7,0x20
ffffffffc02015c6:	9301                	srli	a4,a4,0x20
            p->property = page->property - n;
ffffffffc02015c8:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc02015cc:	02e6fc63          	bgeu	a3,a4,ffffffffc0201604 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02015d0:	00269713          	slli	a4,a3,0x2
ffffffffc02015d4:	9736                	add	a4,a4,a3
ffffffffc02015d6:	070e                	slli	a4,a4,0x3
ffffffffc02015d8:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02015da:	406888bb          	subw	a7,a7,t1
ffffffffc02015de:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015e2:	4689                	li	a3,2
ffffffffc02015e4:	00870593          	addi	a1,a4,8
ffffffffc02015e8:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015ec:	00883683          	ld	a3,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02015f0:	01870893          	addi	a7,a4,24
        nr_free -= n;
ffffffffc02015f4:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc02015f6:	0116b023          	sd	a7,0(a3)
ffffffffc02015fa:	01183423          	sd	a7,8(a6)
    elm->next = next;
ffffffffc02015fe:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201600:	01073c23          	sd	a6,24(a4)
ffffffffc0201604:	406585bb          	subw	a1,a1,t1
ffffffffc0201608:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020160a:	5775                	li	a4,-3
ffffffffc020160c:	17c1                	addi	a5,a5,-16
ffffffffc020160e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201612:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201614:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201616:	00001697          	auipc	a3,0x1
ffffffffc020161a:	57a68693          	addi	a3,a3,1402 # ffffffffc0202b90 <etext+0xbe4>
ffffffffc020161e:	00001617          	auipc	a2,0x1
ffffffffc0201622:	21a60613          	addi	a2,a2,538 # ffffffffc0202838 <etext+0x88c>
ffffffffc0201626:	06200593          	li	a1,98
ffffffffc020162a:	00001517          	auipc	a0,0x1
ffffffffc020162e:	22650513          	addi	a0,a0,550 # ffffffffc0202850 <etext+0x8a4>
default_alloc_pages(size_t n) {
ffffffffc0201632:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201634:	d99fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0201638 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201638:	1141                	addi	sp,sp,-16
ffffffffc020163a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020163c:	c9e1                	beqz	a1,ffffffffc020170c <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020163e:	00259713          	slli	a4,a1,0x2
ffffffffc0201642:	972e                	add	a4,a4,a1
ffffffffc0201644:	070e                	slli	a4,a4,0x3
ffffffffc0201646:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020164a:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020164c:	cf11                	beqz	a4,ffffffffc0201668 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020164e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201650:	8b05                	andi	a4,a4,1
ffffffffc0201652:	cf49                	beqz	a4,ffffffffc02016ec <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201654:	0007a823          	sw	zero,16(a5)
ffffffffc0201658:	0007b423          	sd	zero,8(a5)
ffffffffc020165c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201660:	02878793          	addi	a5,a5,40
ffffffffc0201664:	fed795e3          	bne	a5,a3,ffffffffc020164e <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201668:	2581                	sext.w	a1,a1
ffffffffc020166a:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020166c:	4789                	li	a5,2
ffffffffc020166e:	00850713          	addi	a4,a0,8
ffffffffc0201672:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201676:	00006697          	auipc	a3,0x6
ffffffffc020167a:	9b268693          	addi	a3,a3,-1614 # ffffffffc0207028 <free_area>
ffffffffc020167e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201680:	669c                	ld	a5,8(a3)
ffffffffc0201682:	9f2d                	addw	a4,a4,a1
ffffffffc0201684:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201686:	04d78663          	beq	a5,a3,ffffffffc02016d2 <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc020168a:	fe878713          	addi	a4,a5,-24
ffffffffc020168e:	4581                	li	a1,0
ffffffffc0201690:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201694:	00e56a63          	bltu	a0,a4,ffffffffc02016a8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201698:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020169a:	02d70263          	beq	a4,a3,ffffffffc02016be <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc020169e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016a0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016a4:	fee57ae3          	bgeu	a0,a4,ffffffffc0201698 <default_init_memmap+0x60>
ffffffffc02016a8:	c199                	beqz	a1,ffffffffc02016ae <default_init_memmap+0x76>
ffffffffc02016aa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016ae:	6398                	ld	a4,0(a5)
}
ffffffffc02016b0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016b2:	e390                	sd	a2,0(a5)
ffffffffc02016b4:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016b6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016b8:	ed18                	sd	a4,24(a0)
ffffffffc02016ba:	0141                	addi	sp,sp,16
ffffffffc02016bc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016be:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016c0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016c2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016c4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02016c6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016c8:	00d70e63          	beq	a4,a3,ffffffffc02016e4 <default_init_memmap+0xac>
ffffffffc02016cc:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02016ce:	87ba                	mv	a5,a4
ffffffffc02016d0:	bfc1                	j	ffffffffc02016a0 <default_init_memmap+0x68>
}
ffffffffc02016d2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02016d4:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02016d8:	e398                	sd	a4,0(a5)
ffffffffc02016da:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02016dc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016de:	ed1c                	sd	a5,24(a0)
}
ffffffffc02016e0:	0141                	addi	sp,sp,16
ffffffffc02016e2:	8082                	ret
ffffffffc02016e4:	60a2                	ld	ra,8(sp)
ffffffffc02016e6:	e290                	sd	a2,0(a3)
ffffffffc02016e8:	0141                	addi	sp,sp,16
ffffffffc02016ea:	8082                	ret
        assert(PageReserved(p));
ffffffffc02016ec:	00001697          	auipc	a3,0x1
ffffffffc02016f0:	4d468693          	addi	a3,a3,1236 # ffffffffc0202bc0 <etext+0xc14>
ffffffffc02016f4:	00001617          	auipc	a2,0x1
ffffffffc02016f8:	14460613          	addi	a2,a2,324 # ffffffffc0202838 <etext+0x88c>
ffffffffc02016fc:	04900593          	li	a1,73
ffffffffc0201700:	00001517          	auipc	a0,0x1
ffffffffc0201704:	15050513          	addi	a0,a0,336 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201708:	cc5fe0ef          	jal	ffffffffc02003cc <__panic>
    assert(n > 0);
ffffffffc020170c:	00001697          	auipc	a3,0x1
ffffffffc0201710:	48468693          	addi	a3,a3,1156 # ffffffffc0202b90 <etext+0xbe4>
ffffffffc0201714:	00001617          	auipc	a2,0x1
ffffffffc0201718:	12460613          	addi	a2,a2,292 # ffffffffc0202838 <etext+0x88c>
ffffffffc020171c:	04600593          	li	a1,70
ffffffffc0201720:	00001517          	auipc	a0,0x1
ffffffffc0201724:	13050513          	addi	a0,a0,304 # ffffffffc0202850 <etext+0x8a4>
ffffffffc0201728:	ca5fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc020172c <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020172c:	100027f3          	csrr	a5,sstatus
ffffffffc0201730:	8b89                	andi	a5,a5,2
ffffffffc0201732:	e799                	bnez	a5,ffffffffc0201740 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201734:	00006797          	auipc	a5,0x6
ffffffffc0201738:	d347b783          	ld	a5,-716(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc020173c:	6f9c                	ld	a5,24(a5)
ffffffffc020173e:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201740:	1141                	addi	sp,sp,-16
ffffffffc0201742:	e406                	sd	ra,8(sp)
ffffffffc0201744:	e022                	sd	s0,0(sp)
ffffffffc0201746:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201748:	8b4ff0ef          	jal	ffffffffc02007fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020174c:	00006797          	auipc	a5,0x6
ffffffffc0201750:	d1c7b783          	ld	a5,-740(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc0201754:	6f9c                	ld	a5,24(a5)
ffffffffc0201756:	8522                	mv	a0,s0
ffffffffc0201758:	9782                	jalr	a5
ffffffffc020175a:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020175c:	89aff0ef          	jal	ffffffffc02007f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201760:	60a2                	ld	ra,8(sp)
ffffffffc0201762:	8522                	mv	a0,s0
ffffffffc0201764:	6402                	ld	s0,0(sp)
ffffffffc0201766:	0141                	addi	sp,sp,16
ffffffffc0201768:	8082                	ret

ffffffffc020176a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020176a:	100027f3          	csrr	a5,sstatus
ffffffffc020176e:	8b89                	andi	a5,a5,2
ffffffffc0201770:	e799                	bnez	a5,ffffffffc020177e <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201772:	00006797          	auipc	a5,0x6
ffffffffc0201776:	cf67b783          	ld	a5,-778(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc020177a:	739c                	ld	a5,32(a5)
ffffffffc020177c:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020177e:	1101                	addi	sp,sp,-32
ffffffffc0201780:	ec06                	sd	ra,24(sp)
ffffffffc0201782:	e822                	sd	s0,16(sp)
ffffffffc0201784:	e426                	sd	s1,8(sp)
ffffffffc0201786:	842a                	mv	s0,a0
ffffffffc0201788:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020178a:	872ff0ef          	jal	ffffffffc02007fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020178e:	00006797          	auipc	a5,0x6
ffffffffc0201792:	cda7b783          	ld	a5,-806(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc0201796:	739c                	ld	a5,32(a5)
ffffffffc0201798:	85a6                	mv	a1,s1
ffffffffc020179a:	8522                	mv	a0,s0
ffffffffc020179c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020179e:	6442                	ld	s0,16(sp)
ffffffffc02017a0:	60e2                	ld	ra,24(sp)
ffffffffc02017a2:	64a2                	ld	s1,8(sp)
ffffffffc02017a4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02017a6:	850ff06f          	j	ffffffffc02007f6 <intr_enable>

ffffffffc02017aa <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017aa:	100027f3          	csrr	a5,sstatus
ffffffffc02017ae:	8b89                	andi	a5,a5,2
ffffffffc02017b0:	e799                	bnez	a5,ffffffffc02017be <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02017b2:	00006797          	auipc	a5,0x6
ffffffffc02017b6:	cb67b783          	ld	a5,-842(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017ba:	779c                	ld	a5,40(a5)
ffffffffc02017bc:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02017be:	1141                	addi	sp,sp,-16
ffffffffc02017c0:	e406                	sd	ra,8(sp)
ffffffffc02017c2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02017c4:	838ff0ef          	jal	ffffffffc02007fc <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02017c8:	00006797          	auipc	a5,0x6
ffffffffc02017cc:	ca07b783          	ld	a5,-864(a5) # ffffffffc0207468 <pmm_manager>
ffffffffc02017d0:	779c                	ld	a5,40(a5)
ffffffffc02017d2:	9782                	jalr	a5
ffffffffc02017d4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02017d6:	820ff0ef          	jal	ffffffffc02007f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02017da:	60a2                	ld	ra,8(sp)
ffffffffc02017dc:	8522                	mv	a0,s0
ffffffffc02017de:	6402                	ld	s0,0(sp)
ffffffffc02017e0:	0141                	addi	sp,sp,16
ffffffffc02017e2:	8082                	ret

ffffffffc02017e4 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02017e4:	00001797          	auipc	a5,0x1
ffffffffc02017e8:	67c78793          	addi	a5,a5,1660 # ffffffffc0202e60 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017ec:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017ee:	7179                	addi	sp,sp,-48
ffffffffc02017f0:	f406                	sd	ra,40(sp)
ffffffffc02017f2:	f022                	sd	s0,32(sp)
ffffffffc02017f4:	ec26                	sd	s1,24(sp)
ffffffffc02017f6:	e052                	sd	s4,0(sp)
ffffffffc02017f8:	e84a                	sd	s2,16(sp)
ffffffffc02017fa:	e44e                	sd	s3,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02017fc:	00006417          	auipc	s0,0x6
ffffffffc0201800:	c6c40413          	addi	s0,s0,-916 # ffffffffc0207468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201804:	00001517          	auipc	a0,0x1
ffffffffc0201808:	3e450513          	addi	a0,a0,996 # ffffffffc0202be8 <etext+0xc3c>
    pmm_manager = &default_pmm_manager;
ffffffffc020180c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020180e:	8cbfe0ef          	jal	ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0201812:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201814:	00006497          	auipc	s1,0x6
ffffffffc0201818:	c6c48493          	addi	s1,s1,-916 # ffffffffc0207480 <va_pa_offset>
    pmm_manager->init();
ffffffffc020181c:	679c                	ld	a5,8(a5)
ffffffffc020181e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201820:	57f5                	li	a5,-3
ffffffffc0201822:	07fa                	slli	a5,a5,0x1e
ffffffffc0201824:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201826:	fbdfe0ef          	jal	ffffffffc02007e2 <get_memory_base>
ffffffffc020182a:	8a2a                	mv	s4,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020182c:	fc1fe0ef          	jal	ffffffffc02007ec <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201830:	18050363          	beqz	a0,ffffffffc02019b6 <pmm_init+0x1d2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201834:	89aa                	mv	s3,a0
    cprintf("physcial memory map:\n");
ffffffffc0201836:	00001517          	auipc	a0,0x1
ffffffffc020183a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0202c30 <etext+0xc84>
ffffffffc020183e:	89bfe0ef          	jal	ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201842:	013a0933          	add	s2,s4,s3
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201846:	fff90693          	addi	a3,s2,-1
ffffffffc020184a:	8652                	mv	a2,s4
ffffffffc020184c:	85ce                	mv	a1,s3
ffffffffc020184e:	00001517          	auipc	a0,0x1
ffffffffc0201852:	3fa50513          	addi	a0,a0,1018 # ffffffffc0202c48 <etext+0xc9c>
ffffffffc0201856:	883fe0ef          	jal	ffffffffc02000d8 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020185a:	c8000737          	lui	a4,0xc8000
ffffffffc020185e:	87ca                	mv	a5,s2
ffffffffc0201860:	0f276863          	bltu	a4,s2,ffffffffc0201950 <pmm_init+0x16c>
ffffffffc0201864:	00007697          	auipc	a3,0x7
ffffffffc0201868:	c3b68693          	addi	a3,a3,-965 # ffffffffc020849f <end+0xfff>
ffffffffc020186c:	777d                	lui	a4,0xfffff
ffffffffc020186e:	8ef9                	and	a3,a3,a4
    npage = maxpa / PGSIZE;
ffffffffc0201870:	83b1                	srli	a5,a5,0xc
ffffffffc0201872:	00006817          	auipc	a6,0x6
ffffffffc0201876:	c1680813          	addi	a6,a6,-1002 # ffffffffc0207488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020187a:	00006597          	auipc	a1,0x6
ffffffffc020187e:	c1658593          	addi	a1,a1,-1002 # ffffffffc0207490 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201882:	00f83023          	sd	a5,0(a6)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201886:	e194                	sd	a3,0(a1)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201888:	00080637          	lui	a2,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020188c:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020188e:	04c78463          	beq	a5,a2,ffffffffc02018d6 <pmm_init+0xf2>
ffffffffc0201892:	4785                	li	a5,1
ffffffffc0201894:	00868713          	addi	a4,a3,8
ffffffffc0201898:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc020189c:	00083783          	ld	a5,0(a6)
ffffffffc02018a0:	4705                	li	a4,1
ffffffffc02018a2:	02800693          	li	a3,40
ffffffffc02018a6:	40c78633          	sub	a2,a5,a2
ffffffffc02018aa:	4885                	li	a7,1
ffffffffc02018ac:	fff80537          	lui	a0,0xfff80
ffffffffc02018b0:	02c77063          	bgeu	a4,a2,ffffffffc02018d0 <pmm_init+0xec>
        SetPageReserved(pages + i);
ffffffffc02018b4:	619c                	ld	a5,0(a1)
ffffffffc02018b6:	97b6                	add	a5,a5,a3
ffffffffc02018b8:	07a1                	addi	a5,a5,8
ffffffffc02018ba:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018be:	00083783          	ld	a5,0(a6)
ffffffffc02018c2:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0x3fdf7b61>
ffffffffc02018c4:	02868693          	addi	a3,a3,40
ffffffffc02018c8:	00a78633          	add	a2,a5,a0
ffffffffc02018cc:	fec764e3          	bltu	a4,a2,ffffffffc02018b4 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018d0:	0005b883          	ld	a7,0(a1)
ffffffffc02018d4:	86c6                	mv	a3,a7
ffffffffc02018d6:	00279713          	slli	a4,a5,0x2
ffffffffc02018da:	973e                	add	a4,a4,a5
ffffffffc02018dc:	fec00637          	lui	a2,0xfec00
ffffffffc02018e0:	070e                	slli	a4,a4,0x3
ffffffffc02018e2:	96b2                	add	a3,a3,a2
ffffffffc02018e4:	96ba                	add	a3,a3,a4
ffffffffc02018e6:	c0200737          	lui	a4,0xc0200
ffffffffc02018ea:	0ae6ea63          	bltu	a3,a4,ffffffffc020199e <pmm_init+0x1ba>
ffffffffc02018ee:	6090                	ld	a2,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018f0:	777d                	lui	a4,0xfffff
ffffffffc02018f2:	00e97933          	and	s2,s2,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018f6:	8e91                	sub	a3,a3,a2
    if (freemem < mem_end) {
ffffffffc02018f8:	0526ef63          	bltu	a3,s2,ffffffffc0201956 <pmm_init+0x172>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018fc:	601c                	ld	a5,0(s0)
ffffffffc02018fe:	7b9c                	ld	a5,48(a5)
ffffffffc0201900:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201902:	00001517          	auipc	a0,0x1
ffffffffc0201906:	3ce50513          	addi	a0,a0,974 # ffffffffc0202cd0 <etext+0xd24>
ffffffffc020190a:	fcefe0ef          	jal	ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020190e:	00004597          	auipc	a1,0x4
ffffffffc0201912:	6f258593          	addi	a1,a1,1778 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201916:	00006797          	auipc	a5,0x6
ffffffffc020191a:	b6b7b123          	sd	a1,-1182(a5) # ffffffffc0207478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020191e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201922:	0af5e663          	bltu	a1,a5,ffffffffc02019ce <pmm_init+0x1ea>
ffffffffc0201926:	609c                	ld	a5,0(s1)
}
ffffffffc0201928:	7402                	ld	s0,32(sp)
ffffffffc020192a:	70a2                	ld	ra,40(sp)
ffffffffc020192c:	64e2                	ld	s1,24(sp)
ffffffffc020192e:	6942                	ld	s2,16(sp)
ffffffffc0201930:	69a2                	ld	s3,8(sp)
ffffffffc0201932:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201934:	40f586b3          	sub	a3,a1,a5
ffffffffc0201938:	00006797          	auipc	a5,0x6
ffffffffc020193c:	b2d7bc23          	sd	a3,-1224(a5) # ffffffffc0207470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201940:	00001517          	auipc	a0,0x1
ffffffffc0201944:	3b050513          	addi	a0,a0,944 # ffffffffc0202cf0 <etext+0xd44>
ffffffffc0201948:	8636                	mv	a2,a3
}
ffffffffc020194a:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020194c:	f8cfe06f          	j	ffffffffc02000d8 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201950:	c80007b7          	lui	a5,0xc8000
ffffffffc0201954:	bf01                	j	ffffffffc0201864 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201956:	6605                	lui	a2,0x1
ffffffffc0201958:	167d                	addi	a2,a2,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020195a:	96b2                	add	a3,a3,a2
ffffffffc020195c:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020195e:	00c6d713          	srli	a4,a3,0xc
ffffffffc0201962:	02f77263          	bgeu	a4,a5,ffffffffc0201986 <pmm_init+0x1a2>
    pmm_manager->init_memmap(base, n);
ffffffffc0201966:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201968:	fff807b7          	lui	a5,0xfff80
ffffffffc020196c:	97ba                	add	a5,a5,a4
ffffffffc020196e:	00279513          	slli	a0,a5,0x2
ffffffffc0201972:	953e                	add	a0,a0,a5
ffffffffc0201974:	6a1c                	ld	a5,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201976:	40d90933          	sub	s2,s2,a3
ffffffffc020197a:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020197c:	00c95593          	srli	a1,s2,0xc
ffffffffc0201980:	9546                	add	a0,a0,a7
ffffffffc0201982:	9782                	jalr	a5
}
ffffffffc0201984:	bfa5                	j	ffffffffc02018fc <pmm_init+0x118>
        panic("pa2page called with invalid pa");
ffffffffc0201986:	00001617          	auipc	a2,0x1
ffffffffc020198a:	31a60613          	addi	a2,a2,794 # ffffffffc0202ca0 <etext+0xcf4>
ffffffffc020198e:	06b00593          	li	a1,107
ffffffffc0201992:	00001517          	auipc	a0,0x1
ffffffffc0201996:	32e50513          	addi	a0,a0,814 # ffffffffc0202cc0 <etext+0xd14>
ffffffffc020199a:	a33fe0ef          	jal	ffffffffc02003cc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020199e:	00001617          	auipc	a2,0x1
ffffffffc02019a2:	2da60613          	addi	a2,a2,730 # ffffffffc0202c78 <etext+0xccc>
ffffffffc02019a6:	07100593          	li	a1,113
ffffffffc02019aa:	00001517          	auipc	a0,0x1
ffffffffc02019ae:	27650513          	addi	a0,a0,630 # ffffffffc0202c20 <etext+0xc74>
ffffffffc02019b2:	a1bfe0ef          	jal	ffffffffc02003cc <__panic>
        panic("DTB memory info not available");
ffffffffc02019b6:	00001617          	auipc	a2,0x1
ffffffffc02019ba:	24a60613          	addi	a2,a2,586 # ffffffffc0202c00 <etext+0xc54>
ffffffffc02019be:	05a00593          	li	a1,90
ffffffffc02019c2:	00001517          	auipc	a0,0x1
ffffffffc02019c6:	25e50513          	addi	a0,a0,606 # ffffffffc0202c20 <etext+0xc74>
ffffffffc02019ca:	a03fe0ef          	jal	ffffffffc02003cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019ce:	86ae                	mv	a3,a1
ffffffffc02019d0:	00001617          	auipc	a2,0x1
ffffffffc02019d4:	2a860613          	addi	a2,a2,680 # ffffffffc0202c78 <etext+0xccc>
ffffffffc02019d8:	08c00593          	li	a1,140
ffffffffc02019dc:	00001517          	auipc	a0,0x1
ffffffffc02019e0:	24450513          	addi	a0,a0,580 # ffffffffc0202c20 <etext+0xc74>
ffffffffc02019e4:	9e9fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc02019e8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02019e8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019ec:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019ee:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019f2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019f4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019f8:	f022                	sd	s0,32(sp)
ffffffffc02019fa:	ec26                	sd	s1,24(sp)
ffffffffc02019fc:	e84a                	sd	s2,16(sp)
ffffffffc02019fe:	f406                	sd	ra,40(sp)
ffffffffc0201a00:	84aa                	mv	s1,a0
ffffffffc0201a02:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a04:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf7b5f>
    unsigned mod = do_div(result, base);
ffffffffc0201a08:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a0a:	05067063          	bgeu	a2,a6,ffffffffc0201a4a <printnum+0x62>
ffffffffc0201a0e:	e44e                	sd	s3,8(sp)
ffffffffc0201a10:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a12:	4785                	li	a5,1
ffffffffc0201a14:	00e7d763          	bge	a5,a4,ffffffffc0201a22 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0201a18:	85ca                	mv	a1,s2
ffffffffc0201a1a:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201a1c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a1e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a20:	fc65                	bnez	s0,ffffffffc0201a18 <printnum+0x30>
ffffffffc0201a22:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a24:	1a02                	slli	s4,s4,0x20
ffffffffc0201a26:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a2a:	00001797          	auipc	a5,0x1
ffffffffc0201a2e:	30678793          	addi	a5,a5,774 # ffffffffc0202d30 <etext+0xd84>
ffffffffc0201a32:	97d2                	add	a5,a5,s4
}
ffffffffc0201a34:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a36:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201a3a:	70a2                	ld	ra,40(sp)
ffffffffc0201a3c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a3e:	85ca                	mv	a1,s2
ffffffffc0201a40:	87a6                	mv	a5,s1
}
ffffffffc0201a42:	6942                	ld	s2,16(sp)
ffffffffc0201a44:	64e2                	ld	s1,24(sp)
ffffffffc0201a46:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a48:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a4a:	03065633          	divu	a2,a2,a6
ffffffffc0201a4e:	8722                	mv	a4,s0
ffffffffc0201a50:	f99ff0ef          	jal	ffffffffc02019e8 <printnum>
ffffffffc0201a54:	bfc1                	j	ffffffffc0201a24 <printnum+0x3c>

ffffffffc0201a56 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a56:	7119                	addi	sp,sp,-128
ffffffffc0201a58:	f4a6                	sd	s1,104(sp)
ffffffffc0201a5a:	f0ca                	sd	s2,96(sp)
ffffffffc0201a5c:	ecce                	sd	s3,88(sp)
ffffffffc0201a5e:	e8d2                	sd	s4,80(sp)
ffffffffc0201a60:	e4d6                	sd	s5,72(sp)
ffffffffc0201a62:	e0da                	sd	s6,64(sp)
ffffffffc0201a64:	f862                	sd	s8,48(sp)
ffffffffc0201a66:	fc86                	sd	ra,120(sp)
ffffffffc0201a68:	f8a2                	sd	s0,112(sp)
ffffffffc0201a6a:	fc5e                	sd	s7,56(sp)
ffffffffc0201a6c:	f466                	sd	s9,40(sp)
ffffffffc0201a6e:	f06a                	sd	s10,32(sp)
ffffffffc0201a70:	ec6e                	sd	s11,24(sp)
ffffffffc0201a72:	892a                	mv	s2,a0
ffffffffc0201a74:	84ae                	mv	s1,a1
ffffffffc0201a76:	8c32                	mv	s8,a2
ffffffffc0201a78:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a7a:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a7e:	05500b13          	li	s6,85
ffffffffc0201a82:	00001a97          	auipc	s5,0x1
ffffffffc0201a86:	416a8a93          	addi	s5,s5,1046 # ffffffffc0202e98 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a8a:	000c4503          	lbu	a0,0(s8)
ffffffffc0201a8e:	001c0413          	addi	s0,s8,1
ffffffffc0201a92:	01350a63          	beq	a0,s3,ffffffffc0201aa6 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201a96:	cd0d                	beqz	a0,ffffffffc0201ad0 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201a98:	85a6                	mv	a1,s1
ffffffffc0201a9a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a9c:	00044503          	lbu	a0,0(s0)
ffffffffc0201aa0:	0405                	addi	s0,s0,1
ffffffffc0201aa2:	ff351ae3          	bne	a0,s3,ffffffffc0201a96 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0201aa6:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201aaa:	4b81                	li	s7,0
ffffffffc0201aac:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0201aae:	5d7d                	li	s10,-1
ffffffffc0201ab0:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ab2:	00044683          	lbu	a3,0(s0)
ffffffffc0201ab6:	00140c13          	addi	s8,s0,1
ffffffffc0201aba:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201abe:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ac2:	02bb6663          	bltu	s6,a1,ffffffffc0201aee <vprintfmt+0x98>
ffffffffc0201ac6:	058a                	slli	a1,a1,0x2
ffffffffc0201ac8:	95d6                	add	a1,a1,s5
ffffffffc0201aca:	4198                	lw	a4,0(a1)
ffffffffc0201acc:	9756                	add	a4,a4,s5
ffffffffc0201ace:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201ad0:	70e6                	ld	ra,120(sp)
ffffffffc0201ad2:	7446                	ld	s0,112(sp)
ffffffffc0201ad4:	74a6                	ld	s1,104(sp)
ffffffffc0201ad6:	7906                	ld	s2,96(sp)
ffffffffc0201ad8:	69e6                	ld	s3,88(sp)
ffffffffc0201ada:	6a46                	ld	s4,80(sp)
ffffffffc0201adc:	6aa6                	ld	s5,72(sp)
ffffffffc0201ade:	6b06                	ld	s6,64(sp)
ffffffffc0201ae0:	7be2                	ld	s7,56(sp)
ffffffffc0201ae2:	7c42                	ld	s8,48(sp)
ffffffffc0201ae4:	7ca2                	ld	s9,40(sp)
ffffffffc0201ae6:	7d02                	ld	s10,32(sp)
ffffffffc0201ae8:	6de2                	ld	s11,24(sp)
ffffffffc0201aea:	6109                	addi	sp,sp,128
ffffffffc0201aec:	8082                	ret
            putch('%', putdat);
ffffffffc0201aee:	85a6                	mv	a1,s1
ffffffffc0201af0:	02500513          	li	a0,37
ffffffffc0201af4:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201af6:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201afa:	02500793          	li	a5,37
ffffffffc0201afe:	8c22                	mv	s8,s0
ffffffffc0201b00:	f8f705e3          	beq	a4,a5,ffffffffc0201a8a <vprintfmt+0x34>
ffffffffc0201b04:	02500713          	li	a4,37
ffffffffc0201b08:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201b0c:	1c7d                	addi	s8,s8,-1
ffffffffc0201b0e:	fee79de3          	bne	a5,a4,ffffffffc0201b08 <vprintfmt+0xb2>
ffffffffc0201b12:	bfa5                	j	ffffffffc0201a8a <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201b14:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201b18:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0201b1a:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201b1e:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc0201b22:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b26:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0201b28:	02b76563          	bltu	a4,a1,ffffffffc0201b52 <vprintfmt+0xfc>
ffffffffc0201b2c:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0201b2e:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b32:	002d171b          	slliw	a4,s10,0x2
ffffffffc0201b36:	01a7073b          	addw	a4,a4,s10
ffffffffc0201b3a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b3e:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201b40:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b44:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b46:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0201b4a:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201b4e:	feb570e3          	bgeu	a0,a1,ffffffffc0201b2e <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0201b52:	f60cd0e3          	bgez	s9,ffffffffc0201ab2 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201b56:	8cea                	mv	s9,s10
ffffffffc0201b58:	5d7d                	li	s10,-1
ffffffffc0201b5a:	bfa1                	j	ffffffffc0201ab2 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b5c:	8db6                	mv	s11,a3
ffffffffc0201b5e:	8462                	mv	s0,s8
ffffffffc0201b60:	bf89                	j	ffffffffc0201ab2 <vprintfmt+0x5c>
ffffffffc0201b62:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201b64:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201b66:	b7b1                	j	ffffffffc0201ab2 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201b68:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201b6a:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201b6e:	00c7c463          	blt	a5,a2,ffffffffc0201b76 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201b72:	1a060163          	beqz	a2,ffffffffc0201d14 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0201b76:	000a3603          	ld	a2,0(s4)
ffffffffc0201b7a:	46c1                	li	a3,16
ffffffffc0201b7c:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b7e:	000d879b          	sext.w	a5,s11
ffffffffc0201b82:	8766                	mv	a4,s9
ffffffffc0201b84:	85a6                	mv	a1,s1
ffffffffc0201b86:	854a                	mv	a0,s2
ffffffffc0201b88:	e61ff0ef          	jal	ffffffffc02019e8 <printnum>
            break;
ffffffffc0201b8c:	bdfd                	j	ffffffffc0201a8a <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b8e:	000a2503          	lw	a0,0(s4)
ffffffffc0201b92:	85a6                	mv	a1,s1
ffffffffc0201b94:	0a21                	addi	s4,s4,8
ffffffffc0201b96:	9902                	jalr	s2
            break;
ffffffffc0201b98:	bdcd                	j	ffffffffc0201a8a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201b9a:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201b9c:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201ba0:	00c7c463          	blt	a5,a2,ffffffffc0201ba8 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0201ba4:	16060363          	beqz	a2,ffffffffc0201d0a <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0201ba8:	000a3603          	ld	a2,0(s4)
ffffffffc0201bac:	46a9                	li	a3,10
ffffffffc0201bae:	8a3a                	mv	s4,a4
ffffffffc0201bb0:	b7f9                	j	ffffffffc0201b7e <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0201bb2:	85a6                	mv	a1,s1
ffffffffc0201bb4:	03000513          	li	a0,48
ffffffffc0201bb8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201bba:	85a6                	mv	a1,s1
ffffffffc0201bbc:	07800513          	li	a0,120
ffffffffc0201bc0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bc2:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201bc6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201bc8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201bca:	bf55                	j	ffffffffc0201b7e <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201bcc:	85a6                	mv	a1,s1
ffffffffc0201bce:	02500513          	li	a0,37
ffffffffc0201bd2:	9902                	jalr	s2
            break;
ffffffffc0201bd4:	bd5d                	j	ffffffffc0201a8a <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201bd6:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bda:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201bdc:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201bde:	bf95                	j	ffffffffc0201b52 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201be0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201be2:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201be6:	00c7c463          	blt	a5,a2,ffffffffc0201bee <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201bea:	10060b63          	beqz	a2,ffffffffc0201d00 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201bee:	000a3603          	ld	a2,0(s4)
ffffffffc0201bf2:	46a1                	li	a3,8
ffffffffc0201bf4:	8a3a                	mv	s4,a4
ffffffffc0201bf6:	b761                	j	ffffffffc0201b7e <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201bf8:	fffcc793          	not	a5,s9
ffffffffc0201bfc:	97fd                	srai	a5,a5,0x3f
ffffffffc0201bfe:	00fcf7b3          	and	a5,s9,a5
ffffffffc0201c02:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c06:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201c08:	b56d                	j	ffffffffc0201ab2 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c0a:	000a3403          	ld	s0,0(s4)
ffffffffc0201c0e:	008a0793          	addi	a5,s4,8
ffffffffc0201c12:	e43e                	sd	a5,8(sp)
ffffffffc0201c14:	12040063          	beqz	s0,ffffffffc0201d34 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201c18:	0d905963          	blez	s9,ffffffffc0201cea <vprintfmt+0x294>
ffffffffc0201c1c:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c20:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0201c24:	12fd9763          	bne	s11,a5,ffffffffc0201d52 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c28:	00044783          	lbu	a5,0(s0)
ffffffffc0201c2c:	0007851b          	sext.w	a0,a5
ffffffffc0201c30:	cb9d                	beqz	a5,ffffffffc0201c66 <vprintfmt+0x210>
ffffffffc0201c32:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c34:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c38:	000d4563          	bltz	s10,ffffffffc0201c42 <vprintfmt+0x1ec>
ffffffffc0201c3c:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c3e:	028d0263          	beq	s10,s0,ffffffffc0201c62 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0201c42:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c44:	0c0b8d63          	beqz	s7,ffffffffc0201d1e <vprintfmt+0x2c8>
ffffffffc0201c48:	3781                	addiw	a5,a5,-32
ffffffffc0201c4a:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201d1e <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201c4e:	03f00513          	li	a0,63
ffffffffc0201c52:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c54:	000a4783          	lbu	a5,0(s4)
ffffffffc0201c58:	3cfd                	addiw	s9,s9,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0201c5a:	0a05                	addi	s4,s4,1
ffffffffc0201c5c:	0007851b          	sext.w	a0,a5
ffffffffc0201c60:	ffe1                	bnez	a5,ffffffffc0201c38 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0201c62:	01905963          	blez	s9,ffffffffc0201c74 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0201c66:	85a6                	mv	a1,s1
ffffffffc0201c68:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201c6c:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0201c6e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c70:	fe0c9be3          	bnez	s9,ffffffffc0201c66 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c74:	6a22                	ld	s4,8(sp)
ffffffffc0201c76:	bd11                	j	ffffffffc0201a8a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201c78:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201c7a:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201c7e:	00c7c363          	blt	a5,a2,ffffffffc0201c84 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201c82:	ce25                	beqz	a2,ffffffffc0201cfa <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0201c84:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c88:	08044d63          	bltz	s0,ffffffffc0201d22 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201c8c:	8622                	mv	a2,s0
ffffffffc0201c8e:	8a5e                	mv	s4,s7
ffffffffc0201c90:	46a9                	li	a3,10
ffffffffc0201c92:	b5f5                	j	ffffffffc0201b7e <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0201c94:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c98:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201c9a:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201c9e:	8fb9                	xor	a5,a5,a4
ffffffffc0201ca0:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ca4:	02d64663          	blt	a2,a3,ffffffffc0201cd0 <vprintfmt+0x27a>
ffffffffc0201ca8:	00369713          	slli	a4,a3,0x3
ffffffffc0201cac:	00001797          	auipc	a5,0x1
ffffffffc0201cb0:	34478793          	addi	a5,a5,836 # ffffffffc0202ff0 <error_string>
ffffffffc0201cb4:	97ba                	add	a5,a5,a4
ffffffffc0201cb6:	639c                	ld	a5,0(a5)
ffffffffc0201cb8:	cf81                	beqz	a5,ffffffffc0201cd0 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201cba:	86be                	mv	a3,a5
ffffffffc0201cbc:	00001617          	auipc	a2,0x1
ffffffffc0201cc0:	0a460613          	addi	a2,a2,164 # ffffffffc0202d60 <etext+0xdb4>
ffffffffc0201cc4:	85a6                	mv	a1,s1
ffffffffc0201cc6:	854a                	mv	a0,s2
ffffffffc0201cc8:	0e8000ef          	jal	ffffffffc0201db0 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201ccc:	0a21                	addi	s4,s4,8
ffffffffc0201cce:	bb75                	j	ffffffffc0201a8a <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cd0:	00001617          	auipc	a2,0x1
ffffffffc0201cd4:	08060613          	addi	a2,a2,128 # ffffffffc0202d50 <etext+0xda4>
ffffffffc0201cd8:	85a6                	mv	a1,s1
ffffffffc0201cda:	854a                	mv	a0,s2
ffffffffc0201cdc:	0d4000ef          	jal	ffffffffc0201db0 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201ce0:	0a21                	addi	s4,s4,8
ffffffffc0201ce2:	b365                	j	ffffffffc0201a8a <vprintfmt+0x34>
            lflag ++;
ffffffffc0201ce4:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ce6:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201ce8:	b3e9                	j	ffffffffc0201ab2 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cea:	00044783          	lbu	a5,0(s0)
ffffffffc0201cee:	0007851b          	sext.w	a0,a5
ffffffffc0201cf2:	d3c9                	beqz	a5,ffffffffc0201c74 <vprintfmt+0x21e>
ffffffffc0201cf4:	00140a13          	addi	s4,s0,1
ffffffffc0201cf8:	bf2d                	j	ffffffffc0201c32 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201cfa:	000a2403          	lw	s0,0(s4)
ffffffffc0201cfe:	b769                	j	ffffffffc0201c88 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0201d00:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d04:	46a1                	li	a3,8
ffffffffc0201d06:	8a3a                	mv	s4,a4
ffffffffc0201d08:	bd9d                	j	ffffffffc0201b7e <vprintfmt+0x128>
ffffffffc0201d0a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d0e:	46a9                	li	a3,10
ffffffffc0201d10:	8a3a                	mv	s4,a4
ffffffffc0201d12:	b5b5                	j	ffffffffc0201b7e <vprintfmt+0x128>
ffffffffc0201d14:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d18:	46c1                	li	a3,16
ffffffffc0201d1a:	8a3a                	mv	s4,a4
ffffffffc0201d1c:	b58d                	j	ffffffffc0201b7e <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201d1e:	9902                	jalr	s2
ffffffffc0201d20:	bf15                	j	ffffffffc0201c54 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0201d22:	85a6                	mv	a1,s1
ffffffffc0201d24:	02d00513          	li	a0,45
ffffffffc0201d28:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d2a:	40800633          	neg	a2,s0
ffffffffc0201d2e:	8a5e                	mv	s4,s7
ffffffffc0201d30:	46a9                	li	a3,10
ffffffffc0201d32:	b5b1                	j	ffffffffc0201b7e <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0201d34:	01905663          	blez	s9,ffffffffc0201d40 <vprintfmt+0x2ea>
ffffffffc0201d38:	02d00793          	li	a5,45
ffffffffc0201d3c:	04fd9263          	bne	s11,a5,ffffffffc0201d80 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d40:	02800793          	li	a5,40
ffffffffc0201d44:	00001a17          	auipc	s4,0x1
ffffffffc0201d48:	005a0a13          	addi	s4,s4,5 # ffffffffc0202d49 <etext+0xd9d>
ffffffffc0201d4c:	02800513          	li	a0,40
ffffffffc0201d50:	b5cd                	j	ffffffffc0201c32 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d52:	85ea                	mv	a1,s10
ffffffffc0201d54:	8522                	mv	a0,s0
ffffffffc0201d56:	1b2000ef          	jal	ffffffffc0201f08 <strnlen>
ffffffffc0201d5a:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0201d5e:	01905963          	blez	s9,ffffffffc0201d70 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0201d62:	2d81                	sext.w	s11,s11
ffffffffc0201d64:	85a6                	mv	a1,s1
ffffffffc0201d66:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d68:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201d6a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d6c:	fe0c9ce3          	bnez	s9,ffffffffc0201d64 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d70:	00044783          	lbu	a5,0(s0)
ffffffffc0201d74:	0007851b          	sext.w	a0,a5
ffffffffc0201d78:	ea079de3          	bnez	a5,ffffffffc0201c32 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d7c:	6a22                	ld	s4,8(sp)
ffffffffc0201d7e:	b331                	j	ffffffffc0201a8a <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d80:	85ea                	mv	a1,s10
ffffffffc0201d82:	00001517          	auipc	a0,0x1
ffffffffc0201d86:	fc650513          	addi	a0,a0,-58 # ffffffffc0202d48 <etext+0xd9c>
ffffffffc0201d8a:	17e000ef          	jal	ffffffffc0201f08 <strnlen>
ffffffffc0201d8e:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201d92:	00001417          	auipc	s0,0x1
ffffffffc0201d96:	fb640413          	addi	s0,s0,-74 # ffffffffc0202d48 <etext+0xd9c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d9a:	00001a17          	auipc	s4,0x1
ffffffffc0201d9e:	fafa0a13          	addi	s4,s4,-81 # ffffffffc0202d49 <etext+0xd9d>
ffffffffc0201da2:	02800793          	li	a5,40
ffffffffc0201da6:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201daa:	fb904ce3          	bgtz	s9,ffffffffc0201d62 <vprintfmt+0x30c>
ffffffffc0201dae:	b551                	j	ffffffffc0201c32 <vprintfmt+0x1dc>

ffffffffc0201db0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201db0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201db2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201db6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201db8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201dba:	ec06                	sd	ra,24(sp)
ffffffffc0201dbc:	f83a                	sd	a4,48(sp)
ffffffffc0201dbe:	fc3e                	sd	a5,56(sp)
ffffffffc0201dc0:	e0c2                	sd	a6,64(sp)
ffffffffc0201dc2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201dc4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201dc6:	c91ff0ef          	jal	ffffffffc0201a56 <vprintfmt>
}
ffffffffc0201dca:	60e2                	ld	ra,24(sp)
ffffffffc0201dcc:	6161                	addi	sp,sp,80
ffffffffc0201dce:	8082                	ret

ffffffffc0201dd0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201dd0:	715d                	addi	sp,sp,-80
ffffffffc0201dd2:	e486                	sd	ra,72(sp)
ffffffffc0201dd4:	e0a2                	sd	s0,64(sp)
ffffffffc0201dd6:	fc26                	sd	s1,56(sp)
ffffffffc0201dd8:	f84a                	sd	s2,48(sp)
ffffffffc0201dda:	f44e                	sd	s3,40(sp)
ffffffffc0201ddc:	f052                	sd	s4,32(sp)
ffffffffc0201dde:	ec56                	sd	s5,24(sp)
ffffffffc0201de0:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0201de2:	c901                	beqz	a0,ffffffffc0201df2 <readline+0x22>
ffffffffc0201de4:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201de6:	00001517          	auipc	a0,0x1
ffffffffc0201dea:	f7a50513          	addi	a0,a0,-134 # ffffffffc0202d60 <etext+0xdb4>
ffffffffc0201dee:	aeafe0ef          	jal	ffffffffc02000d8 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201df2:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201df4:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201df6:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201df8:	4a29                	li	s4,10
ffffffffc0201dfa:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0201dfc:	00005b17          	auipc	s6,0x5
ffffffffc0201e00:	244b0b13          	addi	s6,s6,580 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e04:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0201e08:	b54fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201e0c:	00054a63          	bltz	a0,ffffffffc0201e20 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e10:	00a4da63          	bge	s1,a0,ffffffffc0201e24 <readline+0x54>
ffffffffc0201e14:	0289d263          	bge	s3,s0,ffffffffc0201e38 <readline+0x68>
        c = getchar();
ffffffffc0201e18:	b44fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201e1c:	fe055ae3          	bgez	a0,ffffffffc0201e10 <readline+0x40>
            return NULL;
ffffffffc0201e20:	4501                	li	a0,0
ffffffffc0201e22:	a091                	j	ffffffffc0201e66 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e24:	03251463          	bne	a0,s2,ffffffffc0201e4c <readline+0x7c>
ffffffffc0201e28:	04804963          	bgtz	s0,ffffffffc0201e7a <readline+0xaa>
        c = getchar();
ffffffffc0201e2c:	b30fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201e30:	fe0548e3          	bltz	a0,ffffffffc0201e20 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e34:	fea4d8e3          	bge	s1,a0,ffffffffc0201e24 <readline+0x54>
            cputchar(c);
ffffffffc0201e38:	e42a                	sd	a0,8(sp)
ffffffffc0201e3a:	ad2fe0ef          	jal	ffffffffc020010c <cputchar>
            buf[i ++] = c;
ffffffffc0201e3e:	6522                	ld	a0,8(sp)
ffffffffc0201e40:	008b07b3          	add	a5,s6,s0
ffffffffc0201e44:	2405                	addiw	s0,s0,1
ffffffffc0201e46:	00a78023          	sb	a0,0(a5)
ffffffffc0201e4a:	bf7d                	j	ffffffffc0201e08 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e4c:	01450463          	beq	a0,s4,ffffffffc0201e54 <readline+0x84>
ffffffffc0201e50:	fb551ce3          	bne	a0,s5,ffffffffc0201e08 <readline+0x38>
            cputchar(c);
ffffffffc0201e54:	ab8fe0ef          	jal	ffffffffc020010c <cputchar>
            buf[i] = '\0';
ffffffffc0201e58:	00005517          	auipc	a0,0x5
ffffffffc0201e5c:	1e850513          	addi	a0,a0,488 # ffffffffc0207040 <buf>
ffffffffc0201e60:	942a                	add	s0,s0,a0
ffffffffc0201e62:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0201e66:	60a6                	ld	ra,72(sp)
ffffffffc0201e68:	6406                	ld	s0,64(sp)
ffffffffc0201e6a:	74e2                	ld	s1,56(sp)
ffffffffc0201e6c:	7942                	ld	s2,48(sp)
ffffffffc0201e6e:	79a2                	ld	s3,40(sp)
ffffffffc0201e70:	7a02                	ld	s4,32(sp)
ffffffffc0201e72:	6ae2                	ld	s5,24(sp)
ffffffffc0201e74:	6b42                	ld	s6,16(sp)
ffffffffc0201e76:	6161                	addi	sp,sp,80
ffffffffc0201e78:	8082                	ret
            cputchar(c);
ffffffffc0201e7a:	4521                	li	a0,8
ffffffffc0201e7c:	a90fe0ef          	jal	ffffffffc020010c <cputchar>
            i --;
ffffffffc0201e80:	347d                	addiw	s0,s0,-1
ffffffffc0201e82:	b759                	j	ffffffffc0201e08 <readline+0x38>

ffffffffc0201e84 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e84:	4781                	li	a5,0
ffffffffc0201e86:	00005717          	auipc	a4,0x5
ffffffffc0201e8a:	19a73703          	ld	a4,410(a4) # ffffffffc0207020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e8e:	88ba                	mv	a7,a4
ffffffffc0201e90:	852a                	mv	a0,a0
ffffffffc0201e92:	85be                	mv	a1,a5
ffffffffc0201e94:	863e                	mv	a2,a5
ffffffffc0201e96:	00000073          	ecall
ffffffffc0201e9a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e9c:	8082                	ret

ffffffffc0201e9e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e9e:	4781                	li	a5,0
ffffffffc0201ea0:	00005717          	auipc	a4,0x5
ffffffffc0201ea4:	5f873703          	ld	a4,1528(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201ea8:	88ba                	mv	a7,a4
ffffffffc0201eaa:	852a                	mv	a0,a0
ffffffffc0201eac:	85be                	mv	a1,a5
ffffffffc0201eae:	863e                	mv	a2,a5
ffffffffc0201eb0:	00000073          	ecall
ffffffffc0201eb4:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201eb6:	8082                	ret

ffffffffc0201eb8 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201eb8:	4501                	li	a0,0
ffffffffc0201eba:	00005797          	auipc	a5,0x5
ffffffffc0201ebe:	15e7b783          	ld	a5,350(a5) # ffffffffc0207018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201ec2:	88be                	mv	a7,a5
ffffffffc0201ec4:	852a                	mv	a0,a0
ffffffffc0201ec6:	85aa                	mv	a1,a0
ffffffffc0201ec8:	862a                	mv	a2,a0
ffffffffc0201eca:	00000073          	ecall
ffffffffc0201ece:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201ed0:	2501                	sext.w	a0,a0
ffffffffc0201ed2:	8082                	ret

ffffffffc0201ed4 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201ed4:	4781                	li	a5,0
ffffffffc0201ed6:	00005717          	auipc	a4,0x5
ffffffffc0201eda:	13a73703          	ld	a4,314(a4) # ffffffffc0207010 <SBI_SHUTDOWN>
ffffffffc0201ede:	88ba                	mv	a7,a4
ffffffffc0201ee0:	853e                	mv	a0,a5
ffffffffc0201ee2:	85be                	mv	a1,a5
ffffffffc0201ee4:	863e                	mv	a2,a5
ffffffffc0201ee6:	00000073          	ecall
ffffffffc0201eea:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201eec:	8082                	ret

ffffffffc0201eee <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201eee:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201ef2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201ef4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201ef6:	cb81                	beqz	a5,ffffffffc0201f06 <strlen+0x18>
        cnt ++;
ffffffffc0201ef8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201efa:	00a707b3          	add	a5,a4,a0
ffffffffc0201efe:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f02:	fbfd                	bnez	a5,ffffffffc0201ef8 <strlen+0xa>
ffffffffc0201f04:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f06:	8082                	ret

ffffffffc0201f08 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f08:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f0a:	e589                	bnez	a1,ffffffffc0201f14 <strnlen+0xc>
ffffffffc0201f0c:	a811                	j	ffffffffc0201f20 <strnlen+0x18>
        cnt ++;
ffffffffc0201f0e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f10:	00f58863          	beq	a1,a5,ffffffffc0201f20 <strnlen+0x18>
ffffffffc0201f14:	00f50733          	add	a4,a0,a5
ffffffffc0201f18:	00074703          	lbu	a4,0(a4)
ffffffffc0201f1c:	fb6d                	bnez	a4,ffffffffc0201f0e <strnlen+0x6>
ffffffffc0201f1e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f20:	852e                	mv	a0,a1
ffffffffc0201f22:	8082                	ret

ffffffffc0201f24 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f24:	00054783          	lbu	a5,0(a0)
ffffffffc0201f28:	e791                	bnez	a5,ffffffffc0201f34 <strcmp+0x10>
ffffffffc0201f2a:	a02d                	j	ffffffffc0201f54 <strcmp+0x30>
ffffffffc0201f2c:	00054783          	lbu	a5,0(a0)
ffffffffc0201f30:	cf89                	beqz	a5,ffffffffc0201f4a <strcmp+0x26>
ffffffffc0201f32:	85b6                	mv	a1,a3
ffffffffc0201f34:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201f38:	0505                	addi	a0,a0,1
ffffffffc0201f3a:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f3e:	fef707e3          	beq	a4,a5,ffffffffc0201f2c <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f42:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f46:	9d19                	subw	a0,a0,a4
ffffffffc0201f48:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f4a:	0015c703          	lbu	a4,1(a1)
ffffffffc0201f4e:	4501                	li	a0,0
}
ffffffffc0201f50:	9d19                	subw	a0,a0,a4
ffffffffc0201f52:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f54:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f58:	4501                	li	a0,0
ffffffffc0201f5a:	b7f5                	j	ffffffffc0201f46 <strcmp+0x22>

ffffffffc0201f5c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f5c:	ce01                	beqz	a2,ffffffffc0201f74 <strncmp+0x18>
ffffffffc0201f5e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f62:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f64:	cb91                	beqz	a5,ffffffffc0201f78 <strncmp+0x1c>
ffffffffc0201f66:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f6a:	00f71763          	bne	a4,a5,ffffffffc0201f78 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201f6e:	0505                	addi	a0,a0,1
ffffffffc0201f70:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f72:	f675                	bnez	a2,ffffffffc0201f5e <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f74:	4501                	li	a0,0
ffffffffc0201f76:	8082                	ret
ffffffffc0201f78:	00054503          	lbu	a0,0(a0)
ffffffffc0201f7c:	0005c783          	lbu	a5,0(a1)
ffffffffc0201f80:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201f82:	8082                	ret

ffffffffc0201f84 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f84:	00054783          	lbu	a5,0(a0)
ffffffffc0201f88:	c799                	beqz	a5,ffffffffc0201f96 <strchr+0x12>
        if (*s == c) {
ffffffffc0201f8a:	00f58763          	beq	a1,a5,ffffffffc0201f98 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f8e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201f92:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f94:	fbfd                	bnez	a5,ffffffffc0201f8a <strchr+0x6>
    }
    return NULL;
ffffffffc0201f96:	4501                	li	a0,0
}
ffffffffc0201f98:	8082                	ret

ffffffffc0201f9a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f9a:	ca01                	beqz	a2,ffffffffc0201faa <memset+0x10>
ffffffffc0201f9c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f9e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fa0:	0785                	addi	a5,a5,1
ffffffffc0201fa2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fa6:	fef61de3          	bne	a2,a5,ffffffffc0201fa0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201faa:	8082                	ret

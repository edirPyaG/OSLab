
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

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
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5f1030ef          	jal	ra,ffffffffc0203e52 <memset>
    dtb_init();
ffffffffc0200066:	514000ef          	jal	ra,ffffffffc020057a <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	49e000ef          	jal	ra,ffffffffc0200508 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e3258593          	addi	a1,a1,-462 # ffffffffc0203ea0 <etext>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e4a50513          	addi	a0,a0,-438 # ffffffffc0203ec0 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0c0020ef          	jal	ra,ffffffffc0202146 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0ad000ef          	jal	ra,ffffffffc0200936 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0ab000ef          	jal	ra,ffffffffc0200938 <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	629020ef          	jal	ra,ffffffffc0202eba <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	57c030ef          	jal	ra,ffffffffc0203612 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	08d000ef          	jal	ra,ffffffffc020092a <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7be030ef          	jal	ra,ffffffffc0203860 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	e0c50513          	addi	a0,a0,-500 # ffffffffc0203ec8 <etext+0x28>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	3a8000ef          	jal	ra,ffffffffc020050a <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	0a7030ef          	jal	ra,ffffffffc0203a2e <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	071030ef          	jal	ra,ffffffffc0203a2e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a681                	j	ffffffffc020050a <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	36e000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	cf250513          	addi	a0,a0,-782 # ffffffffc0203ed0 <etext+0x30>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	cfc50513          	addi	a0,a0,-772 # ffffffffc0203ef0 <etext+0x50>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	ca058593          	addi	a1,a1,-864 # ffffffffc0203ea0 <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	d0850513          	addi	a0,a0,-760 # ffffffffc0203f10 <etext+0x70>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	d1450513          	addi	a0,a0,-748 # ffffffffc0203f30 <etext+0x90>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2c458593          	addi	a1,a1,708 # ffffffffc020d4ec <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	d2050513          	addi	a0,a0,-736 # ffffffffc0203f50 <etext+0xb0>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6af58593          	addi	a1,a1,1711 # ffffffffc020d8eb <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	d1250513          	addi	a0,a0,-750 # ffffffffc0203f70 <etext+0xd0>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	d3460613          	addi	a2,a2,-716 # ffffffffc0203fa0 <etext+0x100>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	d4050513          	addi	a0,a0,-704 # ffffffffc0203fb8 <etext+0x118>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	d4860613          	addi	a2,a2,-696 # ffffffffc0203fd0 <etext+0x130>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	d6058593          	addi	a1,a1,-672 # ffffffffc0203ff0 <etext+0x150>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	d6050513          	addi	a0,a0,-672 # ffffffffc0203ff8 <etext+0x158>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	d6260613          	addi	a2,a2,-670 # ffffffffc0204008 <etext+0x168>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	d8258593          	addi	a1,a1,-638 # ffffffffc0204030 <etext+0x190>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	d4250513          	addi	a0,a0,-702 # ffffffffc0203ff8 <etext+0x158>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	d7e60613          	addi	a2,a2,-642 # ffffffffc0204040 <etext+0x1a0>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	d9658593          	addi	a1,a1,-618 # ffffffffc0204060 <etext+0x1c0>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	d2650513          	addi	a0,a0,-730 # ffffffffc0203ff8 <etext+0x158>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	d6450513          	addi	a0,a0,-668 # ffffffffc0204070 <etext+0x1d0>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	d6a50513          	addi	a0,a0,-662 # ffffffffc0204098 <etext+0x1f8>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7e0000ef          	jal	ra,ffffffffc0200b20 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	db8c0c13          	addi	s8,s8,-584 # ffffffffc0204108 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	d6890913          	addi	s2,s2,-664 # ffffffffc02040c0 <etext+0x220>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	d6848493          	addi	s1,s1,-664 # ffffffffc02040c8 <etext+0x228>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	d66b0b13          	addi	s6,s6,-666 # ffffffffc02040d0 <etext+0x230>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	c7ea0a13          	addi	s4,s4,-898 # ffffffffc0203ff0 <etext+0x150>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	d74d0d13          	addi	s10,s10,-652 # ffffffffc0204108 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	257030ef          	jal	ra,ffffffffc0203df8 <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	243030ef          	jal	ra,ffffffffc0203df8 <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	249030ef          	jal	ra,ffffffffc0203e3c <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	20b030ef          	jal	ra,ffffffffc0203e3c <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	ca450513          	addi	a0,a0,-860 # ffffffffc02040f0 <etext+0x250>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	cc850513          	addi	a0,a0,-824 # ffffffffc0204150 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	d6250513          	addi	a0,a0,-670 # ffffffffc0205200 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	486000ef          	jal	ra,ffffffffc0200930 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	c9450513          	addi	a0,a0,-876 # ffffffffc0204170 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ee:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004f2:	0000d797          	auipc	a5,0xd
ffffffffc02004f6:	f867b783          	ld	a5,-122(a5) # ffffffffc020d478 <timebase>
ffffffffc02004fa:	953e                	add	a0,a0,a5
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4881                	li	a7,0
ffffffffc0200502:	00000073          	ecall
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200508:	8082                	ret

ffffffffc020050a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020050a:	100027f3          	csrr	a5,sstatus
ffffffffc020050e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200510:	0ff57513          	zext.b	a0,a0
ffffffffc0200514:	e799                	bnez	a5,ffffffffc0200522 <cons_putc+0x18>
ffffffffc0200516:	4581                	li	a1,0
ffffffffc0200518:	4601                	li	a2,0
ffffffffc020051a:	4885                	li	a7,1
ffffffffc020051c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200520:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200522:	1101                	addi	sp,sp,-32
ffffffffc0200524:	ec06                	sd	ra,24(sp)
ffffffffc0200526:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200528:	408000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020052c:	6522                	ld	a0,8(sp)
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4885                	li	a7,1
ffffffffc0200534:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200538:	60e2                	ld	ra,24(sp)
ffffffffc020053a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053c:	a6fd                	j	ffffffffc020092a <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	3d6000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	3bc000ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020057a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020057c:	00004517          	auipc	a0,0x4
ffffffffc0200580:	c1450513          	addi	a0,a0,-1004 # ffffffffc0204190 <commands+0x88>
void dtb_init(void) {
ffffffffc0200584:	fc86                	sd	ra,120(sp)
ffffffffc0200586:	f8a2                	sd	s0,112(sp)
ffffffffc0200588:	e8d2                	sd	s4,80(sp)
ffffffffc020058a:	f4a6                	sd	s1,104(sp)
ffffffffc020058c:	f0ca                	sd	s2,96(sp)
ffffffffc020058e:	ecce                	sd	s3,88(sp)
ffffffffc0200590:	e4d6                	sd	s5,72(sp)
ffffffffc0200592:	e0da                	sd	s6,64(sp)
ffffffffc0200594:	fc5e                	sd	s7,56(sp)
ffffffffc0200596:	f862                	sd	s8,48(sp)
ffffffffc0200598:	f466                	sd	s9,40(sp)
ffffffffc020059a:	f06a                	sd	s10,32(sp)
ffffffffc020059c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020059e:	bf7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005a2:	00009597          	auipc	a1,0x9
ffffffffc02005a6:	a5e5b583          	ld	a1,-1442(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	bf650513          	addi	a0,a0,-1034 # ffffffffc02041a0 <commands+0x98>
ffffffffc02005b2:	be3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005b6:	00009417          	auipc	s0,0x9
ffffffffc02005ba:	a5240413          	addi	s0,s0,-1454 # ffffffffc0209008 <boot_dtb>
ffffffffc02005be:	600c                	ld	a1,0(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	bf050513          	addi	a0,a0,-1040 # ffffffffc02041b0 <commands+0xa8>
ffffffffc02005c8:	bcdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005cc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005d0:	00004517          	auipc	a0,0x4
ffffffffc02005d4:	bf850513          	addi	a0,a0,-1032 # ffffffffc02041c8 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005d8:	120a0463          	beqz	s4,ffffffffc0200700 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005dc:	57f5                	li	a5,-3
ffffffffc02005de:	07fa                	slli	a5,a5,0x1e
ffffffffc02005e0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005e4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200600:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ec9                	or	a3,a3,a0
ffffffffc0200604:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200608:	1b7d                	addi	s6,s6,-1
ffffffffc020060a:	0167f7b3          	and	a5,a5,s6
ffffffffc020060e:	8dd5                	or	a1,a1,a3
ffffffffc0200610:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200612:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200618:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020061c:	10f59163          	bne	a1,a5,ffffffffc020071e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200620:	471c                	lw	a5,8(a4)
ffffffffc0200622:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200624:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020062a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020062e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200632:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200636:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020063a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200642:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200646:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	01146433          	or	s0,s0,a7
ffffffffc0200654:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200658:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	8c49                	or	s0,s0,a0
ffffffffc0200664:	0166f6b3          	and	a3,a3,s6
ffffffffc0200668:	00ca6a33          	or	s4,s4,a2
ffffffffc020066c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200670:	8c55                	or	s0,s0,a3
ffffffffc0200672:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200676:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200678:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020067a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020067c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200680:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200682:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200688:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	00004917          	auipc	s2,0x4
ffffffffc020068e:	b8e90913          	addi	s2,s2,-1138 # ffffffffc0204218 <commands+0x110>
ffffffffc0200692:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200694:	4d91                	li	s11,4
ffffffffc0200696:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	00004497          	auipc	s1,0x4
ffffffffc020069c:	b7848493          	addi	s1,s1,-1160 # ffffffffc0204210 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a0:	000a2703          	lw	a4,0(s4)
ffffffffc02006a4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02006ac:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006bc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006c6:	8fd5                	or	a5,a5,a3
ffffffffc02006c8:	00eb7733          	and	a4,s6,a4
ffffffffc02006cc:	8fd9                	or	a5,a5,a4
ffffffffc02006ce:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006d0:	09778c63          	beq	a5,s7,ffffffffc0200768 <dtb_init+0x1ee>
ffffffffc02006d4:	00fbea63          	bltu	s7,a5,ffffffffc02006e8 <dtb_init+0x16e>
ffffffffc02006d8:	07a78663          	beq	a5,s10,ffffffffc0200744 <dtb_init+0x1ca>
ffffffffc02006dc:	4709                	li	a4,2
ffffffffc02006de:	00e79763          	bne	a5,a4,ffffffffc02006ec <dtb_init+0x172>
ffffffffc02006e2:	4c81                	li	s9,0
ffffffffc02006e4:	8a56                	mv	s4,s5
ffffffffc02006e6:	bf6d                	j	ffffffffc02006a0 <dtb_init+0x126>
ffffffffc02006e8:	ffb78ee3          	beq	a5,s11,ffffffffc02006e4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	ba450513          	addi	a0,a0,-1116 # ffffffffc0204290 <commands+0x188>
ffffffffc02006f4:	aa1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	bd050513          	addi	a0,a0,-1072 # ffffffffc02042c8 <commands+0x1c0>
}
ffffffffc0200700:	7446                	ld	s0,112(sp)
ffffffffc0200702:	70e6                	ld	ra,120(sp)
ffffffffc0200704:	74a6                	ld	s1,104(sp)
ffffffffc0200706:	7906                	ld	s2,96(sp)
ffffffffc0200708:	69e6                	ld	s3,88(sp)
ffffffffc020070a:	6a46                	ld	s4,80(sp)
ffffffffc020070c:	6aa6                	ld	s5,72(sp)
ffffffffc020070e:	6b06                	ld	s6,64(sp)
ffffffffc0200710:	7be2                	ld	s7,56(sp)
ffffffffc0200712:	7c42                	ld	s8,48(sp)
ffffffffc0200714:	7ca2                	ld	s9,40(sp)
ffffffffc0200716:	7d02                	ld	s10,32(sp)
ffffffffc0200718:	6de2                	ld	s11,24(sp)
ffffffffc020071a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020071c:	bca5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc020071e:	7446                	ld	s0,112(sp)
ffffffffc0200720:	70e6                	ld	ra,120(sp)
ffffffffc0200722:	74a6                	ld	s1,104(sp)
ffffffffc0200724:	7906                	ld	s2,96(sp)
ffffffffc0200726:	69e6                	ld	s3,88(sp)
ffffffffc0200728:	6a46                	ld	s4,80(sp)
ffffffffc020072a:	6aa6                	ld	s5,72(sp)
ffffffffc020072c:	6b06                	ld	s6,64(sp)
ffffffffc020072e:	7be2                	ld	s7,56(sp)
ffffffffc0200730:	7c42                	ld	s8,48(sp)
ffffffffc0200732:	7ca2                	ld	s9,40(sp)
ffffffffc0200734:	7d02                	ld	s10,32(sp)
ffffffffc0200736:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	ab050513          	addi	a0,a0,-1360 # ffffffffc02041e8 <commands+0xe0>
}
ffffffffc0200740:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200742:	bc89                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200744:	8556                	mv	a0,s5
ffffffffc0200746:	66a030ef          	jal	ra,ffffffffc0203db0 <strlen>
ffffffffc020074a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020074c:	4619                	li	a2,6
ffffffffc020074e:	85a6                	mv	a1,s1
ffffffffc0200750:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200752:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200754:	6c2030ef          	jal	ra,ffffffffc0203e16 <strncmp>
ffffffffc0200758:	e111                	bnez	a0,ffffffffc020075c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020075a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020075c:	0a91                	addi	s5,s5,4
ffffffffc020075e:	9ad2                	add	s5,s5,s4
ffffffffc0200760:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200764:	8a56                	mv	s4,s5
ffffffffc0200766:	bf2d                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200768:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200774:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200784:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200790:	00eaeab3          	or	s5,s5,a4
ffffffffc0200794:	00fb77b3          	and	a5,s6,a5
ffffffffc0200798:	00faeab3          	or	s5,s5,a5
ffffffffc020079c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020079e:	000c9c63          	bnez	s9,ffffffffc02007b6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02007a2:	1a82                	slli	s5,s5,0x20
ffffffffc02007a4:	00368793          	addi	a5,a3,3
ffffffffc02007a8:	020ada93          	srli	s5,s5,0x20
ffffffffc02007ac:	9abe                	add	s5,s5,a5
ffffffffc02007ae:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007b2:	8a56                	mv	s4,s5
ffffffffc02007b4:	b5f5                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007b6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	85ca                	mv	a1,s2
ffffffffc02007bc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007ca:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007d2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007dc:	8d59                	or	a0,a0,a4
ffffffffc02007de:	00fb77b3          	and	a5,s6,a5
ffffffffc02007e2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007e4:	1502                	slli	a0,a0,0x20
ffffffffc02007e6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007e8:	9522                	add	a0,a0,s0
ffffffffc02007ea:	60e030ef          	jal	ra,ffffffffc0203df8 <strcmp>
ffffffffc02007ee:	66a2                	ld	a3,8(sp)
ffffffffc02007f0:	f94d                	bnez	a0,ffffffffc02007a2 <dtb_init+0x228>
ffffffffc02007f2:	fb59f8e3          	bgeu	s3,s5,ffffffffc02007a2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007f6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007fa:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007fe:	00004517          	auipc	a0,0x4
ffffffffc0200802:	a2250513          	addi	a0,a0,-1502 # ffffffffc0204220 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020080e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200812:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200816:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020081a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200822:	0187d693          	srli	a3,a5,0x18
ffffffffc0200826:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020082a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020082e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200836:	010f6f33          	or	t5,t5,a6
ffffffffc020083a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020083e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0186f6b3          	and	a3,a3,s8
ffffffffc020084e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200852:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0107581b          	srliw	a6,a4,0x10
ffffffffc020085a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	8361                	srli	a4,a4,0x18
ffffffffc0200860:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200868:	01e6e6b3          	or	a3,a3,t5
ffffffffc020086c:	00cb7633          	and	a2,s6,a2
ffffffffc0200870:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200874:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200878:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020087c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200880:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200884:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200888:	0088989b          	slliw	a7,a7,0x8
ffffffffc020088c:	011b78b3          	and	a7,s6,a7
ffffffffc0200890:	005eeeb3          	or	t4,t4,t0
ffffffffc0200894:	00c6e733          	or	a4,a3,a2
ffffffffc0200898:	006c6c33          	or	s8,s8,t1
ffffffffc020089c:	010b76b3          	and	a3,s6,a6
ffffffffc02008a0:	00bb7b33          	and	s6,s6,a1
ffffffffc02008a4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02008a8:	016c6b33          	or	s6,s8,s6
ffffffffc02008ac:	01146433          	or	s0,s0,a7
ffffffffc02008b0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02008b2:	1702                	slli	a4,a4,0x20
ffffffffc02008b4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008b8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008ba:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008bc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008c0:	0167eb33          	or	s6,a5,s6
ffffffffc02008c4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008c6:	8cfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008ca:	85a2                	mv	a1,s0
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	97450513          	addi	a0,a0,-1676 # ffffffffc0204240 <commands+0x138>
ffffffffc02008d4:	8c1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008d8:	014b5613          	srli	a2,s6,0x14
ffffffffc02008dc:	85da                	mv	a1,s6
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0204258 <commands+0x150>
ffffffffc02008e6:	8afff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008ea:	008b05b3          	add	a1,s6,s0
ffffffffc02008ee:	15fd                	addi	a1,a1,-1
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	98850513          	addi	a0,a0,-1656 # ffffffffc0204278 <commands+0x170>
ffffffffc02008f8:	89dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	9cc50513          	addi	a0,a0,-1588 # ffffffffc02042c8 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200904:	0000d797          	auipc	a5,0xd
ffffffffc0200908:	b687be23          	sd	s0,-1156(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc020090c:	0000d797          	auipc	a5,0xd
ffffffffc0200910:	b767be23          	sd	s6,-1156(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200914:	b3f5                	j	ffffffffc0200700 <dtb_init+0x186>

ffffffffc0200916 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200916:	0000d517          	auipc	a0,0xd
ffffffffc020091a:	b6a53503          	ld	a0,-1174(a0) # ffffffffc020d480 <memory_base>
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200920:	0000d517          	auipc	a0,0xd
ffffffffc0200924:	b6853503          	ld	a0,-1176(a0) # ffffffffc020d488 <memory_size>
ffffffffc0200928:	8082                	ret

ffffffffc020092a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020092a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200938:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020093c:	00000797          	auipc	a5,0x0
ffffffffc0200940:	3dc78793          	addi	a5,a5,988 # ffffffffc0200d18 <__alltraps>
ffffffffc0200944:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200948:	000407b7          	lui	a5,0x40
ffffffffc020094c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200950:	8082                	ret

ffffffffc0200952 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200952:	610c                	ld	a1,0(a0)
{
ffffffffc0200954:	1141                	addi	sp,sp,-16
ffffffffc0200956:	e022                	sd	s0,0(sp)
ffffffffc0200958:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095a:	00004517          	auipc	a0,0x4
ffffffffc020095e:	98650513          	addi	a0,a0,-1658 # ffffffffc02042e0 <commands+0x1d8>
{
ffffffffc0200962:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200964:	831ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200968:	640c                	ld	a1,8(s0)
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	98e50513          	addi	a0,a0,-1650 # ffffffffc02042f8 <commands+0x1f0>
ffffffffc0200972:	823ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200976:	680c                	ld	a1,16(s0)
ffffffffc0200978:	00004517          	auipc	a0,0x4
ffffffffc020097c:	99850513          	addi	a0,a0,-1640 # ffffffffc0204310 <commands+0x208>
ffffffffc0200980:	815ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200984:	6c0c                	ld	a1,24(s0)
ffffffffc0200986:	00004517          	auipc	a0,0x4
ffffffffc020098a:	9a250513          	addi	a0,a0,-1630 # ffffffffc0204328 <commands+0x220>
ffffffffc020098e:	807ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200992:	700c                	ld	a1,32(s0)
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0204340 <commands+0x238>
ffffffffc020099c:	ff8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a0:	740c                	ld	a1,40(s0)
ffffffffc02009a2:	00004517          	auipc	a0,0x4
ffffffffc02009a6:	9b650513          	addi	a0,a0,-1610 # ffffffffc0204358 <commands+0x250>
ffffffffc02009aa:	feaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009ae:	780c                	ld	a1,48(s0)
ffffffffc02009b0:	00004517          	auipc	a0,0x4
ffffffffc02009b4:	9c050513          	addi	a0,a0,-1600 # ffffffffc0204370 <commands+0x268>
ffffffffc02009b8:	fdcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009bc:	7c0c                	ld	a1,56(s0)
ffffffffc02009be:	00004517          	auipc	a0,0x4
ffffffffc02009c2:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0204388 <commands+0x280>
ffffffffc02009c6:	fceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ca:	602c                	ld	a1,64(s0)
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	9d450513          	addi	a0,a0,-1580 # ffffffffc02043a0 <commands+0x298>
ffffffffc02009d4:	fc0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d8:	642c                	ld	a1,72(s0)
ffffffffc02009da:	00004517          	auipc	a0,0x4
ffffffffc02009de:	9de50513          	addi	a0,a0,-1570 # ffffffffc02043b8 <commands+0x2b0>
ffffffffc02009e2:	fb2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009e6:	682c                	ld	a1,80(s0)
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	9e850513          	addi	a0,a0,-1560 # ffffffffc02043d0 <commands+0x2c8>
ffffffffc02009f0:	fa4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f4:	6c2c                	ld	a1,88(s0)
ffffffffc02009f6:	00004517          	auipc	a0,0x4
ffffffffc02009fa:	9f250513          	addi	a0,a0,-1550 # ffffffffc02043e8 <commands+0x2e0>
ffffffffc02009fe:	f96ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a02:	702c                	ld	a1,96(s0)
ffffffffc0200a04:	00004517          	auipc	a0,0x4
ffffffffc0200a08:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0204400 <commands+0x2f8>
ffffffffc0200a0c:	f88ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a10:	742c                	ld	a1,104(s0)
ffffffffc0200a12:	00004517          	auipc	a0,0x4
ffffffffc0200a16:	a0650513          	addi	a0,a0,-1530 # ffffffffc0204418 <commands+0x310>
ffffffffc0200a1a:	f7aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a1e:	782c                	ld	a1,112(s0)
ffffffffc0200a20:	00004517          	auipc	a0,0x4
ffffffffc0200a24:	a1050513          	addi	a0,a0,-1520 # ffffffffc0204430 <commands+0x328>
ffffffffc0200a28:	f6cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a2c:	7c2c                	ld	a1,120(s0)
ffffffffc0200a2e:	00004517          	auipc	a0,0x4
ffffffffc0200a32:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0204448 <commands+0x340>
ffffffffc0200a36:	f5eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3a:	604c                	ld	a1,128(s0)
ffffffffc0200a3c:	00004517          	auipc	a0,0x4
ffffffffc0200a40:	a2450513          	addi	a0,a0,-1500 # ffffffffc0204460 <commands+0x358>
ffffffffc0200a44:	f50ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a48:	644c                	ld	a1,136(s0)
ffffffffc0200a4a:	00004517          	auipc	a0,0x4
ffffffffc0200a4e:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0204478 <commands+0x370>
ffffffffc0200a52:	f42ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a56:	684c                	ld	a1,144(s0)
ffffffffc0200a58:	00004517          	auipc	a0,0x4
ffffffffc0200a5c:	a3850513          	addi	a0,a0,-1480 # ffffffffc0204490 <commands+0x388>
ffffffffc0200a60:	f34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a64:	6c4c                	ld	a1,152(s0)
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	a4250513          	addi	a0,a0,-1470 # ffffffffc02044a8 <commands+0x3a0>
ffffffffc0200a6e:	f26ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a72:	704c                	ld	a1,160(s0)
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	a4c50513          	addi	a0,a0,-1460 # ffffffffc02044c0 <commands+0x3b8>
ffffffffc0200a7c:	f18ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a80:	744c                	ld	a1,168(s0)
ffffffffc0200a82:	00004517          	auipc	a0,0x4
ffffffffc0200a86:	a5650513          	addi	a0,a0,-1450 # ffffffffc02044d8 <commands+0x3d0>
ffffffffc0200a8a:	f0aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a8e:	784c                	ld	a1,176(s0)
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	a6050513          	addi	a0,a0,-1440 # ffffffffc02044f0 <commands+0x3e8>
ffffffffc0200a98:	efcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a9c:	7c4c                	ld	a1,184(s0)
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0204508 <commands+0x400>
ffffffffc0200aa6:	eeeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aaa:	606c                	ld	a1,192(s0)
ffffffffc0200aac:	00004517          	auipc	a0,0x4
ffffffffc0200ab0:	a7450513          	addi	a0,a0,-1420 # ffffffffc0204520 <commands+0x418>
ffffffffc0200ab4:	ee0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab8:	646c                	ld	a1,200(s0)
ffffffffc0200aba:	00004517          	auipc	a0,0x4
ffffffffc0200abe:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0204538 <commands+0x430>
ffffffffc0200ac2:	ed2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ac6:	686c                	ld	a1,208(s0)
ffffffffc0200ac8:	00004517          	auipc	a0,0x4
ffffffffc0200acc:	a8850513          	addi	a0,a0,-1400 # ffffffffc0204550 <commands+0x448>
ffffffffc0200ad0:	ec4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad4:	6c6c                	ld	a1,216(s0)
ffffffffc0200ad6:	00004517          	auipc	a0,0x4
ffffffffc0200ada:	a9250513          	addi	a0,a0,-1390 # ffffffffc0204568 <commands+0x460>
ffffffffc0200ade:	eb6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae2:	706c                	ld	a1,224(s0)
ffffffffc0200ae4:	00004517          	auipc	a0,0x4
ffffffffc0200ae8:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0204580 <commands+0x478>
ffffffffc0200aec:	ea8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af0:	746c                	ld	a1,232(s0)
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	aa650513          	addi	a0,a0,-1370 # ffffffffc0204598 <commands+0x490>
ffffffffc0200afa:	e9aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200afe:	786c                	ld	a1,240(s0)
ffffffffc0200b00:	00004517          	auipc	a0,0x4
ffffffffc0200b04:	ab050513          	addi	a0,a0,-1360 # ffffffffc02045b0 <commands+0x4a8>
ffffffffc0200b08:	e8cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b0e:	6402                	ld	s0,0(sp)
ffffffffc0200b10:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b12:	00004517          	auipc	a0,0x4
ffffffffc0200b16:	ab650513          	addi	a0,a0,-1354 # ffffffffc02045c8 <commands+0x4c0>
}
ffffffffc0200b1a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b1c:	e78ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b20 <print_trapframe>:
{
ffffffffc0200b20:	1141                	addi	sp,sp,-16
ffffffffc0200b22:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b24:	85aa                	mv	a1,a0
{
ffffffffc0200b26:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	00004517          	auipc	a0,0x4
ffffffffc0200b2c:	ab850513          	addi	a0,a0,-1352 # ffffffffc02045e0 <commands+0x4d8>
{
ffffffffc0200b30:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b32:	e62ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b36:	8522                	mv	a0,s0
ffffffffc0200b38:	e1bff0ef          	jal	ra,ffffffffc0200952 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b3c:	10043583          	ld	a1,256(s0)
ffffffffc0200b40:	00004517          	auipc	a0,0x4
ffffffffc0200b44:	ab850513          	addi	a0,a0,-1352 # ffffffffc02045f8 <commands+0x4f0>
ffffffffc0200b48:	e4cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b4c:	10843583          	ld	a1,264(s0)
ffffffffc0200b50:	00004517          	auipc	a0,0x4
ffffffffc0200b54:	ac050513          	addi	a0,a0,-1344 # ffffffffc0204610 <commands+0x508>
ffffffffc0200b58:	e3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b5c:	11043583          	ld	a1,272(s0)
ffffffffc0200b60:	00004517          	auipc	a0,0x4
ffffffffc0200b64:	ac850513          	addi	a0,a0,-1336 # ffffffffc0204628 <commands+0x520>
ffffffffc0200b68:	e2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b6c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b70:	6402                	ld	s0,0(sp)
ffffffffc0200b72:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	acc50513          	addi	a0,a0,-1332 # ffffffffc0204640 <commands+0x538>
}
ffffffffc0200b7c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b82 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b82:	11853783          	ld	a5,280(a0)
ffffffffc0200b86:	472d                	li	a4,11
ffffffffc0200b88:	0786                	slli	a5,a5,0x1
ffffffffc0200b8a:	8385                	srli	a5,a5,0x1
ffffffffc0200b8c:	06f76c63          	bltu	a4,a5,ffffffffc0200c04 <interrupt_handler+0x82>
ffffffffc0200b90:	00004717          	auipc	a4,0x4
ffffffffc0200b94:	b7870713          	addi	a4,a4,-1160 # ffffffffc0204708 <commands+0x600>
ffffffffc0200b98:	078a                	slli	a5,a5,0x2
ffffffffc0200b9a:	97ba                	add	a5,a5,a4
ffffffffc0200b9c:	439c                	lw	a5,0(a5)
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba2:	00004517          	auipc	a0,0x4
ffffffffc0200ba6:	b1650513          	addi	a0,a0,-1258 # ffffffffc02046b8 <commands+0x5b0>
ffffffffc0200baa:	deaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bae:	00004517          	auipc	a0,0x4
ffffffffc0200bb2:	aea50513          	addi	a0,a0,-1302 # ffffffffc0204698 <commands+0x590>
ffffffffc0200bb6:	ddeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0204658 <commands+0x550>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bc6:	00004517          	auipc	a0,0x4
ffffffffc0200bca:	ab250513          	addi	a0,a0,-1358 # ffffffffc0204678 <commands+0x570>
ffffffffc0200bce:	dc6ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200bd2:	1141                	addi	sp,sp,-16
ffffffffc0200bd4:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event();//设置下次时钟中断
ffffffffc0200bd6:	919ff0ef          	jal	ra,ffffffffc02004ee <clock_set_next_event>
        if(++ticks%TICK_NUM==0)
ffffffffc0200bda:	0000d697          	auipc	a3,0xd
ffffffffc0200bde:	89668693          	addi	a3,a3,-1898 # ffffffffc020d470 <ticks>
ffffffffc0200be2:	629c                	ld	a5,0(a3)
ffffffffc0200be4:	06400713          	li	a4,100
ffffffffc0200be8:	0785                	addi	a5,a5,1
ffffffffc0200bea:	02e7f733          	remu	a4,a5,a4
ffffffffc0200bee:	e29c                	sd	a5,0(a3)
ffffffffc0200bf0:	cb19                	beqz	a4,ffffffffc0200c06 <interrupt_handler+0x84>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bf2:	60a2                	ld	ra,8(sp)
ffffffffc0200bf4:	0141                	addi	sp,sp,16
ffffffffc0200bf6:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bf8:	00004517          	auipc	a0,0x4
ffffffffc0200bfc:	af050513          	addi	a0,a0,-1296 # ffffffffc02046e8 <commands+0x5e0>
ffffffffc0200c00:	d94ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c04:	bf31                	j	ffffffffc0200b20 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c06:	06400593          	li	a1,100
ffffffffc0200c0a:	00004517          	auipc	a0,0x4
ffffffffc0200c0e:	ace50513          	addi	a0,a0,-1330 # ffffffffc02046d8 <commands+0x5d0>
ffffffffc0200c12:	d82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            num++;
ffffffffc0200c16:	0000d717          	auipc	a4,0xd
ffffffffc0200c1a:	87a70713          	addi	a4,a4,-1926 # ffffffffc020d490 <num>
ffffffffc0200c1e:	431c                	lw	a5,0(a4)
            if(num>=10)
ffffffffc0200c20:	46a5                	li	a3,9
            num++;
ffffffffc0200c22:	0017861b          	addiw	a2,a5,1
ffffffffc0200c26:	c310                	sw	a2,0(a4)
            if(num>=10)
ffffffffc0200c28:	fcc6f5e3          	bgeu	a3,a2,ffffffffc0200bf2 <interrupt_handler+0x70>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c2c:	4501                	li	a0,0
ffffffffc0200c2e:	4581                	li	a1,0
ffffffffc0200c30:	4601                	li	a2,0
ffffffffc0200c32:	48a1                	li	a7,8
ffffffffc0200c34:	00000073          	ecall
}
ffffffffc0200c38:	bf6d                	j	ffffffffc0200bf2 <interrupt_handler+0x70>

ffffffffc0200c3a <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c3a:	11853783          	ld	a5,280(a0)
ffffffffc0200c3e:	473d                	li	a4,15
ffffffffc0200c40:	0cf76563          	bltu	a4,a5,ffffffffc0200d0a <exception_handler+0xd0>
ffffffffc0200c44:	00004717          	auipc	a4,0x4
ffffffffc0200c48:	c8c70713          	addi	a4,a4,-884 # ffffffffc02048d0 <commands+0x7c8>
ffffffffc0200c4c:	078a                	slli	a5,a5,0x2
ffffffffc0200c4e:	97ba                	add	a5,a5,a4
ffffffffc0200c50:	439c                	lw	a5,0(a5)
ffffffffc0200c52:	97ba                	add	a5,a5,a4
ffffffffc0200c54:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c56:	00004517          	auipc	a0,0x4
ffffffffc0200c5a:	c6250513          	addi	a0,a0,-926 # ffffffffc02048b8 <commands+0x7b0>
ffffffffc0200c5e:	d36ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c62:	00004517          	auipc	a0,0x4
ffffffffc0200c66:	ad650513          	addi	a0,a0,-1322 # ffffffffc0204738 <commands+0x630>
ffffffffc0200c6a:	d2aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c6e:	00004517          	auipc	a0,0x4
ffffffffc0200c72:	aea50513          	addi	a0,a0,-1302 # ffffffffc0204758 <commands+0x650>
ffffffffc0200c76:	d1eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c7a:	00004517          	auipc	a0,0x4
ffffffffc0200c7e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0204778 <commands+0x670>
ffffffffc0200c82:	d12ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c86:	00004517          	auipc	a0,0x4
ffffffffc0200c8a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0204790 <commands+0x688>
ffffffffc0200c8e:	d06ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200c92:	00004517          	auipc	a0,0x4
ffffffffc0200c96:	b0e50513          	addi	a0,a0,-1266 # ffffffffc02047a0 <commands+0x698>
ffffffffc0200c9a:	cfaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200c9e:	00004517          	auipc	a0,0x4
ffffffffc0200ca2:	b2250513          	addi	a0,a0,-1246 # ffffffffc02047c0 <commands+0x6b8>
ffffffffc0200ca6:	ceeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200caa:	00004517          	auipc	a0,0x4
ffffffffc0200cae:	b2e50513          	addi	a0,a0,-1234 # ffffffffc02047d8 <commands+0x6d0>
ffffffffc0200cb2:	ce2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200cb6:	00004517          	auipc	a0,0x4
ffffffffc0200cba:	b3a50513          	addi	a0,a0,-1222 # ffffffffc02047f0 <commands+0x6e8>
ffffffffc0200cbe:	cd6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cc2:	00004517          	auipc	a0,0x4
ffffffffc0200cc6:	b4650513          	addi	a0,a0,-1210 # ffffffffc0204808 <commands+0x700>
ffffffffc0200cca:	ccaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200cce:	00004517          	auipc	a0,0x4
ffffffffc0200cd2:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0204828 <commands+0x720>
ffffffffc0200cd6:	cbeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200cda:	00004517          	auipc	a0,0x4
ffffffffc0200cde:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0204848 <commands+0x740>
ffffffffc0200ce2:	cb2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200ce6:	00004517          	auipc	a0,0x4
ffffffffc0200cea:	b8250513          	addi	a0,a0,-1150 # ffffffffc0204868 <commands+0x760>
ffffffffc0200cee:	ca6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200cf2:	00004517          	auipc	a0,0x4
ffffffffc0200cf6:	b9650513          	addi	a0,a0,-1130 # ffffffffc0204888 <commands+0x780>
ffffffffc0200cfa:	c9aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200cfe:	00004517          	auipc	a0,0x4
ffffffffc0200d02:	ba250513          	addi	a0,a0,-1118 # ffffffffc02048a0 <commands+0x798>
ffffffffc0200d06:	c8eff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200d0a:	bd19                	j	ffffffffc0200b20 <print_trapframe>

ffffffffc0200d0c <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d0c:	11853783          	ld	a5,280(a0)
ffffffffc0200d10:	0007c363          	bltz	a5,ffffffffc0200d16 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d14:	b71d                	j	ffffffffc0200c3a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d16:	b5b5                	j	ffffffffc0200b82 <interrupt_handler>

ffffffffc0200d18 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d18:	14011073          	csrw	sscratch,sp
ffffffffc0200d1c:	712d                	addi	sp,sp,-288
ffffffffc0200d1e:	e406                	sd	ra,8(sp)
ffffffffc0200d20:	ec0e                	sd	gp,24(sp)
ffffffffc0200d22:	f012                	sd	tp,32(sp)
ffffffffc0200d24:	f416                	sd	t0,40(sp)
ffffffffc0200d26:	f81a                	sd	t1,48(sp)
ffffffffc0200d28:	fc1e                	sd	t2,56(sp)
ffffffffc0200d2a:	e0a2                	sd	s0,64(sp)
ffffffffc0200d2c:	e4a6                	sd	s1,72(sp)
ffffffffc0200d2e:	e8aa                	sd	a0,80(sp)
ffffffffc0200d30:	ecae                	sd	a1,88(sp)
ffffffffc0200d32:	f0b2                	sd	a2,96(sp)
ffffffffc0200d34:	f4b6                	sd	a3,104(sp)
ffffffffc0200d36:	f8ba                	sd	a4,112(sp)
ffffffffc0200d38:	fcbe                	sd	a5,120(sp)
ffffffffc0200d3a:	e142                	sd	a6,128(sp)
ffffffffc0200d3c:	e546                	sd	a7,136(sp)
ffffffffc0200d3e:	e94a                	sd	s2,144(sp)
ffffffffc0200d40:	ed4e                	sd	s3,152(sp)
ffffffffc0200d42:	f152                	sd	s4,160(sp)
ffffffffc0200d44:	f556                	sd	s5,168(sp)
ffffffffc0200d46:	f95a                	sd	s6,176(sp)
ffffffffc0200d48:	fd5e                	sd	s7,184(sp)
ffffffffc0200d4a:	e1e2                	sd	s8,192(sp)
ffffffffc0200d4c:	e5e6                	sd	s9,200(sp)
ffffffffc0200d4e:	e9ea                	sd	s10,208(sp)
ffffffffc0200d50:	edee                	sd	s11,216(sp)
ffffffffc0200d52:	f1f2                	sd	t3,224(sp)
ffffffffc0200d54:	f5f6                	sd	t4,232(sp)
ffffffffc0200d56:	f9fa                	sd	t5,240(sp)
ffffffffc0200d58:	fdfe                	sd	t6,248(sp)
ffffffffc0200d5a:	14002473          	csrr	s0,sscratch
ffffffffc0200d5e:	100024f3          	csrr	s1,sstatus
ffffffffc0200d62:	14102973          	csrr	s2,sepc
ffffffffc0200d66:	143029f3          	csrr	s3,stval
ffffffffc0200d6a:	14202a73          	csrr	s4,scause
ffffffffc0200d6e:	e822                	sd	s0,16(sp)
ffffffffc0200d70:	e226                	sd	s1,256(sp)
ffffffffc0200d72:	e64a                	sd	s2,264(sp)
ffffffffc0200d74:	ea4e                	sd	s3,272(sp)
ffffffffc0200d76:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d78:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d7a:	f93ff0ef          	jal	ra,ffffffffc0200d0c <trap>

ffffffffc0200d7e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d7e:	6492                	ld	s1,256(sp)
ffffffffc0200d80:	6932                	ld	s2,264(sp)
ffffffffc0200d82:	10049073          	csrw	sstatus,s1
ffffffffc0200d86:	14191073          	csrw	sepc,s2
ffffffffc0200d8a:	60a2                	ld	ra,8(sp)
ffffffffc0200d8c:	61e2                	ld	gp,24(sp)
ffffffffc0200d8e:	7202                	ld	tp,32(sp)
ffffffffc0200d90:	72a2                	ld	t0,40(sp)
ffffffffc0200d92:	7342                	ld	t1,48(sp)
ffffffffc0200d94:	73e2                	ld	t2,56(sp)
ffffffffc0200d96:	6406                	ld	s0,64(sp)
ffffffffc0200d98:	64a6                	ld	s1,72(sp)
ffffffffc0200d9a:	6546                	ld	a0,80(sp)
ffffffffc0200d9c:	65e6                	ld	a1,88(sp)
ffffffffc0200d9e:	7606                	ld	a2,96(sp)
ffffffffc0200da0:	76a6                	ld	a3,104(sp)
ffffffffc0200da2:	7746                	ld	a4,112(sp)
ffffffffc0200da4:	77e6                	ld	a5,120(sp)
ffffffffc0200da6:	680a                	ld	a6,128(sp)
ffffffffc0200da8:	68aa                	ld	a7,136(sp)
ffffffffc0200daa:	694a                	ld	s2,144(sp)
ffffffffc0200dac:	69ea                	ld	s3,152(sp)
ffffffffc0200dae:	7a0a                	ld	s4,160(sp)
ffffffffc0200db0:	7aaa                	ld	s5,168(sp)
ffffffffc0200db2:	7b4a                	ld	s6,176(sp)
ffffffffc0200db4:	7bea                	ld	s7,184(sp)
ffffffffc0200db6:	6c0e                	ld	s8,192(sp)
ffffffffc0200db8:	6cae                	ld	s9,200(sp)
ffffffffc0200dba:	6d4e                	ld	s10,208(sp)
ffffffffc0200dbc:	6dee                	ld	s11,216(sp)
ffffffffc0200dbe:	7e0e                	ld	t3,224(sp)
ffffffffc0200dc0:	7eae                	ld	t4,232(sp)
ffffffffc0200dc2:	7f4e                	ld	t5,240(sp)
ffffffffc0200dc4:	7fee                	ld	t6,248(sp)
ffffffffc0200dc6:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200dc8:	10200073          	sret

ffffffffc0200dcc <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200dcc:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dce:	bf45                	j	ffffffffc0200d7e <__trapret>
	...

ffffffffc0200dd2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200dd2:	00008797          	auipc	a5,0x8
ffffffffc0200dd6:	65e78793          	addi	a5,a5,1630 # ffffffffc0209430 <free_area>
ffffffffc0200dda:	e79c                	sd	a5,8(a5)
ffffffffc0200ddc:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200dde:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200de2:	8082                	ret

ffffffffc0200de4 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200de4:	00008517          	auipc	a0,0x8
ffffffffc0200de8:	65c56503          	lwu	a0,1628(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200dec:	8082                	ret

ffffffffc0200dee <default_alloc_pages>:
    assert(n > 0);
ffffffffc0200dee:	cd51                	beqz	a0,ffffffffc0200e8a <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc0200df0:	00008617          	auipc	a2,0x8
ffffffffc0200df4:	64060613          	addi	a2,a2,1600 # ffffffffc0209430 <free_area>
ffffffffc0200df8:	01062803          	lw	a6,16(a2)
ffffffffc0200dfc:	86aa                	mv	a3,a0
ffffffffc0200dfe:	02081793          	slli	a5,a6,0x20
ffffffffc0200e02:	9381                	srli	a5,a5,0x20
ffffffffc0200e04:	08a7e163          	bltu	a5,a0,ffffffffc0200e86 <default_alloc_pages+0x98>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e08:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200e0a:	0018059b          	addiw	a1,a6,1
ffffffffc0200e0e:	1582                	slli	a1,a1,0x20
ffffffffc0200e10:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200e12:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e14:	06c78863          	beq	a5,a2,ffffffffc0200e84 <default_alloc_pages+0x96>
        if (p->property >= n&&p->property<min_size) {
ffffffffc0200e18:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200e1c:	00d76763          	bltu	a4,a3,ffffffffc0200e2a <default_alloc_pages+0x3c>
ffffffffc0200e20:	00b77563          	bgeu	a4,a1,ffffffffc0200e2a <default_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200e24:	fe878513          	addi	a0,a5,-24
ffffffffc0200e28:	85ba                	mv	a1,a4
ffffffffc0200e2a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e2c:	fec796e3          	bne	a5,a2,ffffffffc0200e18 <default_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200e30:	c931                	beqz	a0,ffffffffc0200e84 <default_alloc_pages+0x96>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e32:	710c                	ld	a1,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200e34:	6d1c                	ld	a5,24(a0)
        if (page->property > n) {
ffffffffc0200e36:	4918                	lw	a4,16(a0)
            p->property = page->property - n;
ffffffffc0200e38:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200e3c:	e78c                	sd	a1,8(a5)
    next->prev = prev;
ffffffffc0200e3e:	e19c                	sd	a5,0(a1)
        if (page->property > n) {
ffffffffc0200e40:	02071593          	slli	a1,a4,0x20
ffffffffc0200e44:	9181                	srli	a1,a1,0x20
ffffffffc0200e46:	02b6f563          	bgeu	a3,a1,ffffffffc0200e70 <default_alloc_pages+0x82>
            struct Page *p = page + n;
ffffffffc0200e4a:	069a                	slli	a3,a3,0x6
ffffffffc0200e4c:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0200e4e:	4117073b          	subw	a4,a4,a7
ffffffffc0200e52:	ca98                	sw	a4,16(a3)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200e54:	00868593          	addi	a1,a3,8
ffffffffc0200e58:	4709                	li	a4,2
ffffffffc0200e5a:	40e5b02f          	amoor.d	zero,a4,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e5e:	6798                	ld	a4,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200e60:	01868593          	addi	a1,a3,24
        nr_free -= n;
ffffffffc0200e64:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200e68:	e30c                	sd	a1,0(a4)
ffffffffc0200e6a:	e78c                	sd	a1,8(a5)
    elm->next = next;
ffffffffc0200e6c:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0200e6e:	ee9c                	sd	a5,24(a3)
ffffffffc0200e70:	4118083b          	subw	a6,a6,a7
ffffffffc0200e74:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200e78:	57f5                	li	a5,-3
ffffffffc0200e7a:	00850713          	addi	a4,a0,8
ffffffffc0200e7e:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200e82:	8082                	ret
}
ffffffffc0200e84:	8082                	ret
        return NULL;
ffffffffc0200e86:	4501                	li	a0,0
ffffffffc0200e88:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0200e8a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200e8c:	00004697          	auipc	a3,0x4
ffffffffc0200e90:	a8468693          	addi	a3,a3,-1404 # ffffffffc0204910 <commands+0x808>
ffffffffc0200e94:	00004617          	auipc	a2,0x4
ffffffffc0200e98:	a8460613          	addi	a2,a2,-1404 # ffffffffc0204918 <commands+0x810>
ffffffffc0200e9c:	06600593          	li	a1,102
ffffffffc0200ea0:	00004517          	auipc	a0,0x4
ffffffffc0200ea4:	a9050513          	addi	a0,a0,-1392 # ffffffffc0204930 <commands+0x828>
default_alloc_pages(size_t n) {
ffffffffc0200ea8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200eaa:	db0ff0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200eae <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200eae:	715d                	addi	sp,sp,-80
ffffffffc0200eb0:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200eb2:	00008417          	auipc	s0,0x8
ffffffffc0200eb6:	57e40413          	addi	s0,s0,1406 # ffffffffc0209430 <free_area>
ffffffffc0200eba:	641c                	ld	a5,8(s0)
ffffffffc0200ebc:	e486                	sd	ra,72(sp)
ffffffffc0200ebe:	fc26                	sd	s1,56(sp)
ffffffffc0200ec0:	f84a                	sd	s2,48(sp)
ffffffffc0200ec2:	f44e                	sd	s3,40(sp)
ffffffffc0200ec4:	f052                	sd	s4,32(sp)
ffffffffc0200ec6:	ec56                	sd	s5,24(sp)
ffffffffc0200ec8:	e85a                	sd	s6,16(sp)
ffffffffc0200eca:	e45e                	sd	s7,8(sp)
ffffffffc0200ecc:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ece:	2a878d63          	beq	a5,s0,ffffffffc0201188 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200ed2:	4481                	li	s1,0
ffffffffc0200ed4:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ed6:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200eda:	8b09                	andi	a4,a4,2
ffffffffc0200edc:	2a070a63          	beqz	a4,ffffffffc0201190 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200ee0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ee4:	679c                	ld	a5,8(a5)
ffffffffc0200ee6:	2905                	addiw	s2,s2,1
ffffffffc0200ee8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eea:	fe8796e3          	bne	a5,s0,ffffffffc0200ed6 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200eee:	89a6                	mv	s3,s1
ffffffffc0200ef0:	60f000ef          	jal	ra,ffffffffc0201cfe <nr_free_pages>
ffffffffc0200ef4:	6f351e63          	bne	a0,s3,ffffffffc02015f0 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ef8:	4505                	li	a0,1
ffffffffc0200efa:	587000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200efe:	8aaa                	mv	s5,a0
ffffffffc0200f00:	42050863          	beqz	a0,ffffffffc0201330 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f04:	4505                	li	a0,1
ffffffffc0200f06:	57b000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200f0a:	89aa                	mv	s3,a0
ffffffffc0200f0c:	70050263          	beqz	a0,ffffffffc0201610 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f10:	4505                	li	a0,1
ffffffffc0200f12:	56f000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200f16:	8a2a                	mv	s4,a0
ffffffffc0200f18:	48050c63          	beqz	a0,ffffffffc02013b0 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f1c:	293a8a63          	beq	s5,s3,ffffffffc02011b0 <default_check+0x302>
ffffffffc0200f20:	28aa8863          	beq	s5,a0,ffffffffc02011b0 <default_check+0x302>
ffffffffc0200f24:	28a98663          	beq	s3,a0,ffffffffc02011b0 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f28:	000aa783          	lw	a5,0(s5)
ffffffffc0200f2c:	2a079263          	bnez	a5,ffffffffc02011d0 <default_check+0x322>
ffffffffc0200f30:	0009a783          	lw	a5,0(s3)
ffffffffc0200f34:	28079e63          	bnez	a5,ffffffffc02011d0 <default_check+0x322>
ffffffffc0200f38:	411c                	lw	a5,0(a0)
ffffffffc0200f3a:	28079b63          	bnez	a5,ffffffffc02011d0 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200f3e:	0000c797          	auipc	a5,0xc
ffffffffc0200f42:	57a7b783          	ld	a5,1402(a5) # ffffffffc020d4b8 <pages>
ffffffffc0200f46:	40fa8733          	sub	a4,s5,a5
ffffffffc0200f4a:	00005617          	auipc	a2,0x5
ffffffffc0200f4e:	a9e63603          	ld	a2,-1378(a2) # ffffffffc02059e8 <nbase>
ffffffffc0200f52:	8719                	srai	a4,a4,0x6
ffffffffc0200f54:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f56:	0000c697          	auipc	a3,0xc
ffffffffc0200f5a:	55a6b683          	ld	a3,1370(a3) # ffffffffc020d4b0 <npage>
ffffffffc0200f5e:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f60:	0732                	slli	a4,a4,0xc
ffffffffc0200f62:	28d77763          	bgeu	a4,a3,ffffffffc02011f0 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200f66:	40f98733          	sub	a4,s3,a5
ffffffffc0200f6a:	8719                	srai	a4,a4,0x6
ffffffffc0200f6c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f6e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f70:	4cd77063          	bgeu	a4,a3,ffffffffc0201430 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200f74:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f78:	8799                	srai	a5,a5,0x6
ffffffffc0200f7a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f7c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f7e:	30d7f963          	bgeu	a5,a3,ffffffffc0201290 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200f82:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f84:	00043c03          	ld	s8,0(s0)
ffffffffc0200f88:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f8c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f90:	e400                	sd	s0,8(s0)
ffffffffc0200f92:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f94:	00008797          	auipc	a5,0x8
ffffffffc0200f98:	4a07a623          	sw	zero,1196(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f9c:	4e5000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200fa0:	2c051863          	bnez	a0,ffffffffc0201270 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200fa4:	4585                	li	a1,1
ffffffffc0200fa6:	8556                	mv	a0,s5
ffffffffc0200fa8:	517000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    free_page(p1);
ffffffffc0200fac:	4585                	li	a1,1
ffffffffc0200fae:	854e                	mv	a0,s3
ffffffffc0200fb0:	50f000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    free_page(p2);
ffffffffc0200fb4:	4585                	li	a1,1
ffffffffc0200fb6:	8552                	mv	a0,s4
ffffffffc0200fb8:	507000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    assert(nr_free == 3);
ffffffffc0200fbc:	4818                	lw	a4,16(s0)
ffffffffc0200fbe:	478d                	li	a5,3
ffffffffc0200fc0:	28f71863          	bne	a4,a5,ffffffffc0201250 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	4bb000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200fca:	89aa                	mv	s3,a0
ffffffffc0200fcc:	26050263          	beqz	a0,ffffffffc0201230 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	4af000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200fd6:	8aaa                	mv	s5,a0
ffffffffc0200fd8:	3a050c63          	beqz	a0,ffffffffc0201390 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fdc:	4505                	li	a0,1
ffffffffc0200fde:	4a3000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200fe2:	8a2a                	mv	s4,a0
ffffffffc0200fe4:	38050663          	beqz	a0,ffffffffc0201370 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200fe8:	4505                	li	a0,1
ffffffffc0200fea:	497000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0200fee:	36051163          	bnez	a0,ffffffffc0201350 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200ff2:	4585                	li	a1,1
ffffffffc0200ff4:	854e                	mv	a0,s3
ffffffffc0200ff6:	4c9000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ffa:	641c                	ld	a5,8(s0)
ffffffffc0200ffc:	20878a63          	beq	a5,s0,ffffffffc0201210 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0201000:	4505                	li	a0,1
ffffffffc0201002:	47f000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201006:	30a99563          	bne	s3,a0,ffffffffc0201310 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc020100a:	4505                	li	a0,1
ffffffffc020100c:	475000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201010:	2e051063          	bnez	a0,ffffffffc02012f0 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201014:	481c                	lw	a5,16(s0)
ffffffffc0201016:	2a079d63          	bnez	a5,ffffffffc02012d0 <default_check+0x422>
    free_page(p);
ffffffffc020101a:	854e                	mv	a0,s3
ffffffffc020101c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020101e:	01843023          	sd	s8,0(s0)
ffffffffc0201022:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201026:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020102a:	495000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    free_page(p1);
ffffffffc020102e:	4585                	li	a1,1
ffffffffc0201030:	8556                	mv	a0,s5
ffffffffc0201032:	48d000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    free_page(p2);
ffffffffc0201036:	4585                	li	a1,1
ffffffffc0201038:	8552                	mv	a0,s4
ffffffffc020103a:	485000ef          	jal	ra,ffffffffc0201cbe <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020103e:	4515                	li	a0,5
ffffffffc0201040:	441000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201044:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201046:	26050563          	beqz	a0,ffffffffc02012b0 <default_check+0x402>
ffffffffc020104a:	651c                	ld	a5,8(a0)
ffffffffc020104c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc020104e:	8b85                	andi	a5,a5,1
ffffffffc0201050:	54079063          	bnez	a5,ffffffffc0201590 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201054:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201056:	00043b03          	ld	s6,0(s0)
ffffffffc020105a:	00843a83          	ld	s5,8(s0)
ffffffffc020105e:	e000                	sd	s0,0(s0)
ffffffffc0201060:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201062:	41f000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201066:	50051563          	bnez	a0,ffffffffc0201570 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020106a:	08098a13          	addi	s4,s3,128
ffffffffc020106e:	8552                	mv	a0,s4
ffffffffc0201070:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201072:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201076:	00008797          	auipc	a5,0x8
ffffffffc020107a:	3c07a523          	sw	zero,970(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020107e:	441000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201082:	4511                	li	a0,4
ffffffffc0201084:	3fd000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201088:	4c051463          	bnez	a0,ffffffffc0201550 <default_check+0x6a2>
ffffffffc020108c:	0889b783          	ld	a5,136(s3)
ffffffffc0201090:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201092:	8b85                	andi	a5,a5,1
ffffffffc0201094:	48078e63          	beqz	a5,ffffffffc0201530 <default_check+0x682>
ffffffffc0201098:	0909a703          	lw	a4,144(s3)
ffffffffc020109c:	478d                	li	a5,3
ffffffffc020109e:	48f71963          	bne	a4,a5,ffffffffc0201530 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010a2:	450d                	li	a0,3
ffffffffc02010a4:	3dd000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc02010a8:	8c2a                	mv	s8,a0
ffffffffc02010aa:	46050363          	beqz	a0,ffffffffc0201510 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02010ae:	4505                	li	a0,1
ffffffffc02010b0:	3d1000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc02010b4:	42051e63          	bnez	a0,ffffffffc02014f0 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc02010b8:	418a1c63          	bne	s4,s8,ffffffffc02014d0 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010bc:	4585                	li	a1,1
ffffffffc02010be:	854e                	mv	a0,s3
ffffffffc02010c0:	3ff000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    free_pages(p1, 3);
ffffffffc02010c4:	458d                	li	a1,3
ffffffffc02010c6:	8552                	mv	a0,s4
ffffffffc02010c8:	3f7000ef          	jal	ra,ffffffffc0201cbe <free_pages>
ffffffffc02010cc:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010d0:	04098c13          	addi	s8,s3,64
ffffffffc02010d4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010d6:	8b85                	andi	a5,a5,1
ffffffffc02010d8:	3c078c63          	beqz	a5,ffffffffc02014b0 <default_check+0x602>
ffffffffc02010dc:	0109a703          	lw	a4,16(s3)
ffffffffc02010e0:	4785                	li	a5,1
ffffffffc02010e2:	3cf71763          	bne	a4,a5,ffffffffc02014b0 <default_check+0x602>
ffffffffc02010e6:	008a3783          	ld	a5,8(s4)
ffffffffc02010ea:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010ec:	8b85                	andi	a5,a5,1
ffffffffc02010ee:	3a078163          	beqz	a5,ffffffffc0201490 <default_check+0x5e2>
ffffffffc02010f2:	010a2703          	lw	a4,16(s4)
ffffffffc02010f6:	478d                	li	a5,3
ffffffffc02010f8:	38f71c63          	bne	a4,a5,ffffffffc0201490 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010fc:	4505                	li	a0,1
ffffffffc02010fe:	383000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201102:	36a99763          	bne	s3,a0,ffffffffc0201470 <default_check+0x5c2>
    free_page(p0);
ffffffffc0201106:	4585                	li	a1,1
ffffffffc0201108:	3b7000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020110c:	4509                	li	a0,2
ffffffffc020110e:	373000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201112:	32aa1f63          	bne	s4,a0,ffffffffc0201450 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201116:	4589                	li	a1,2
ffffffffc0201118:	3a7000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    free_page(p2);
ffffffffc020111c:	4585                	li	a1,1
ffffffffc020111e:	8562                	mv	a0,s8
ffffffffc0201120:	39f000ef          	jal	ra,ffffffffc0201cbe <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201124:	4515                	li	a0,5
ffffffffc0201126:	35b000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc020112a:	89aa                	mv	s3,a0
ffffffffc020112c:	48050263          	beqz	a0,ffffffffc02015b0 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201130:	4505                	li	a0,1
ffffffffc0201132:	34f000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
ffffffffc0201136:	2c051d63          	bnez	a0,ffffffffc0201410 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020113a:	481c                	lw	a5,16(s0)
ffffffffc020113c:	2a079a63          	bnez	a5,ffffffffc02013f0 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201140:	4595                	li	a1,5
ffffffffc0201142:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201144:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201148:	01643023          	sd	s6,0(s0)
ffffffffc020114c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201150:	36f000ef          	jal	ra,ffffffffc0201cbe <free_pages>
    return listelm->next;
ffffffffc0201154:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201156:	00878963          	beq	a5,s0,ffffffffc0201168 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020115a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020115e:	679c                	ld	a5,8(a5)
ffffffffc0201160:	397d                	addiw	s2,s2,-1
ffffffffc0201162:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201164:	fe879be3          	bne	a5,s0,ffffffffc020115a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201168:	26091463          	bnez	s2,ffffffffc02013d0 <default_check+0x522>
    assert(total == 0);
ffffffffc020116c:	46049263          	bnez	s1,ffffffffc02015d0 <default_check+0x722>
}
ffffffffc0201170:	60a6                	ld	ra,72(sp)
ffffffffc0201172:	6406                	ld	s0,64(sp)
ffffffffc0201174:	74e2                	ld	s1,56(sp)
ffffffffc0201176:	7942                	ld	s2,48(sp)
ffffffffc0201178:	79a2                	ld	s3,40(sp)
ffffffffc020117a:	7a02                	ld	s4,32(sp)
ffffffffc020117c:	6ae2                	ld	s5,24(sp)
ffffffffc020117e:	6b42                	ld	s6,16(sp)
ffffffffc0201180:	6ba2                	ld	s7,8(sp)
ffffffffc0201182:	6c02                	ld	s8,0(sp)
ffffffffc0201184:	6161                	addi	sp,sp,80
ffffffffc0201186:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201188:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020118a:	4481                	li	s1,0
ffffffffc020118c:	4901                	li	s2,0
ffffffffc020118e:	b38d                	j	ffffffffc0200ef0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201190:	00003697          	auipc	a3,0x3
ffffffffc0201194:	7b868693          	addi	a3,a3,1976 # ffffffffc0204948 <commands+0x840>
ffffffffc0201198:	00003617          	auipc	a2,0x3
ffffffffc020119c:	78060613          	addi	a2,a2,1920 # ffffffffc0204918 <commands+0x810>
ffffffffc02011a0:	0f500593          	li	a1,245
ffffffffc02011a4:	00003517          	auipc	a0,0x3
ffffffffc02011a8:	78c50513          	addi	a0,a0,1932 # ffffffffc0204930 <commands+0x828>
ffffffffc02011ac:	aaeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011b0:	00004697          	auipc	a3,0x4
ffffffffc02011b4:	82868693          	addi	a3,a3,-2008 # ffffffffc02049d8 <commands+0x8d0>
ffffffffc02011b8:	00003617          	auipc	a2,0x3
ffffffffc02011bc:	76060613          	addi	a2,a2,1888 # ffffffffc0204918 <commands+0x810>
ffffffffc02011c0:	0c200593          	li	a1,194
ffffffffc02011c4:	00003517          	auipc	a0,0x3
ffffffffc02011c8:	76c50513          	addi	a0,a0,1900 # ffffffffc0204930 <commands+0x828>
ffffffffc02011cc:	a8eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011d0:	00004697          	auipc	a3,0x4
ffffffffc02011d4:	83068693          	addi	a3,a3,-2000 # ffffffffc0204a00 <commands+0x8f8>
ffffffffc02011d8:	00003617          	auipc	a2,0x3
ffffffffc02011dc:	74060613          	addi	a2,a2,1856 # ffffffffc0204918 <commands+0x810>
ffffffffc02011e0:	0c300593          	li	a1,195
ffffffffc02011e4:	00003517          	auipc	a0,0x3
ffffffffc02011e8:	74c50513          	addi	a0,a0,1868 # ffffffffc0204930 <commands+0x828>
ffffffffc02011ec:	a6eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011f0:	00004697          	auipc	a3,0x4
ffffffffc02011f4:	85068693          	addi	a3,a3,-1968 # ffffffffc0204a40 <commands+0x938>
ffffffffc02011f8:	00003617          	auipc	a2,0x3
ffffffffc02011fc:	72060613          	addi	a2,a2,1824 # ffffffffc0204918 <commands+0x810>
ffffffffc0201200:	0c500593          	li	a1,197
ffffffffc0201204:	00003517          	auipc	a0,0x3
ffffffffc0201208:	72c50513          	addi	a0,a0,1836 # ffffffffc0204930 <commands+0x828>
ffffffffc020120c:	a4eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201210:	00004697          	auipc	a3,0x4
ffffffffc0201214:	8b868693          	addi	a3,a3,-1864 # ffffffffc0204ac8 <commands+0x9c0>
ffffffffc0201218:	00003617          	auipc	a2,0x3
ffffffffc020121c:	70060613          	addi	a2,a2,1792 # ffffffffc0204918 <commands+0x810>
ffffffffc0201220:	0de00593          	li	a1,222
ffffffffc0201224:	00003517          	auipc	a0,0x3
ffffffffc0201228:	70c50513          	addi	a0,a0,1804 # ffffffffc0204930 <commands+0x828>
ffffffffc020122c:	a2eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201230:	00003697          	auipc	a3,0x3
ffffffffc0201234:	74868693          	addi	a3,a3,1864 # ffffffffc0204978 <commands+0x870>
ffffffffc0201238:	00003617          	auipc	a2,0x3
ffffffffc020123c:	6e060613          	addi	a2,a2,1760 # ffffffffc0204918 <commands+0x810>
ffffffffc0201240:	0d700593          	li	a1,215
ffffffffc0201244:	00003517          	auipc	a0,0x3
ffffffffc0201248:	6ec50513          	addi	a0,a0,1772 # ffffffffc0204930 <commands+0x828>
ffffffffc020124c:	a0eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc0201250:	00004697          	auipc	a3,0x4
ffffffffc0201254:	86868693          	addi	a3,a3,-1944 # ffffffffc0204ab8 <commands+0x9b0>
ffffffffc0201258:	00003617          	auipc	a2,0x3
ffffffffc020125c:	6c060613          	addi	a2,a2,1728 # ffffffffc0204918 <commands+0x810>
ffffffffc0201260:	0d500593          	li	a1,213
ffffffffc0201264:	00003517          	auipc	a0,0x3
ffffffffc0201268:	6cc50513          	addi	a0,a0,1740 # ffffffffc0204930 <commands+0x828>
ffffffffc020126c:	9eeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201270:	00004697          	auipc	a3,0x4
ffffffffc0201274:	83068693          	addi	a3,a3,-2000 # ffffffffc0204aa0 <commands+0x998>
ffffffffc0201278:	00003617          	auipc	a2,0x3
ffffffffc020127c:	6a060613          	addi	a2,a2,1696 # ffffffffc0204918 <commands+0x810>
ffffffffc0201280:	0d000593          	li	a1,208
ffffffffc0201284:	00003517          	auipc	a0,0x3
ffffffffc0201288:	6ac50513          	addi	a0,a0,1708 # ffffffffc0204930 <commands+0x828>
ffffffffc020128c:	9ceff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201290:	00003697          	auipc	a3,0x3
ffffffffc0201294:	7f068693          	addi	a3,a3,2032 # ffffffffc0204a80 <commands+0x978>
ffffffffc0201298:	00003617          	auipc	a2,0x3
ffffffffc020129c:	68060613          	addi	a2,a2,1664 # ffffffffc0204918 <commands+0x810>
ffffffffc02012a0:	0c700593          	li	a1,199
ffffffffc02012a4:	00003517          	auipc	a0,0x3
ffffffffc02012a8:	68c50513          	addi	a0,a0,1676 # ffffffffc0204930 <commands+0x828>
ffffffffc02012ac:	9aeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc02012b0:	00004697          	auipc	a3,0x4
ffffffffc02012b4:	86068693          	addi	a3,a3,-1952 # ffffffffc0204b10 <commands+0xa08>
ffffffffc02012b8:	00003617          	auipc	a2,0x3
ffffffffc02012bc:	66060613          	addi	a2,a2,1632 # ffffffffc0204918 <commands+0x810>
ffffffffc02012c0:	0fd00593          	li	a1,253
ffffffffc02012c4:	00003517          	auipc	a0,0x3
ffffffffc02012c8:	66c50513          	addi	a0,a0,1644 # ffffffffc0204930 <commands+0x828>
ffffffffc02012cc:	98eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc02012d0:	00004697          	auipc	a3,0x4
ffffffffc02012d4:	83068693          	addi	a3,a3,-2000 # ffffffffc0204b00 <commands+0x9f8>
ffffffffc02012d8:	00003617          	auipc	a2,0x3
ffffffffc02012dc:	64060613          	addi	a2,a2,1600 # ffffffffc0204918 <commands+0x810>
ffffffffc02012e0:	0e400593          	li	a1,228
ffffffffc02012e4:	00003517          	auipc	a0,0x3
ffffffffc02012e8:	64c50513          	addi	a0,a0,1612 # ffffffffc0204930 <commands+0x828>
ffffffffc02012ec:	96eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012f0:	00003697          	auipc	a3,0x3
ffffffffc02012f4:	7b068693          	addi	a3,a3,1968 # ffffffffc0204aa0 <commands+0x998>
ffffffffc02012f8:	00003617          	auipc	a2,0x3
ffffffffc02012fc:	62060613          	addi	a2,a2,1568 # ffffffffc0204918 <commands+0x810>
ffffffffc0201300:	0e200593          	li	a1,226
ffffffffc0201304:	00003517          	auipc	a0,0x3
ffffffffc0201308:	62c50513          	addi	a0,a0,1580 # ffffffffc0204930 <commands+0x828>
ffffffffc020130c:	94eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201310:	00003697          	auipc	a3,0x3
ffffffffc0201314:	7d068693          	addi	a3,a3,2000 # ffffffffc0204ae0 <commands+0x9d8>
ffffffffc0201318:	00003617          	auipc	a2,0x3
ffffffffc020131c:	60060613          	addi	a2,a2,1536 # ffffffffc0204918 <commands+0x810>
ffffffffc0201320:	0e100593          	li	a1,225
ffffffffc0201324:	00003517          	auipc	a0,0x3
ffffffffc0201328:	60c50513          	addi	a0,a0,1548 # ffffffffc0204930 <commands+0x828>
ffffffffc020132c:	92eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201330:	00003697          	auipc	a3,0x3
ffffffffc0201334:	64868693          	addi	a3,a3,1608 # ffffffffc0204978 <commands+0x870>
ffffffffc0201338:	00003617          	auipc	a2,0x3
ffffffffc020133c:	5e060613          	addi	a2,a2,1504 # ffffffffc0204918 <commands+0x810>
ffffffffc0201340:	0be00593          	li	a1,190
ffffffffc0201344:	00003517          	auipc	a0,0x3
ffffffffc0201348:	5ec50513          	addi	a0,a0,1516 # ffffffffc0204930 <commands+0x828>
ffffffffc020134c:	90eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201350:	00003697          	auipc	a3,0x3
ffffffffc0201354:	75068693          	addi	a3,a3,1872 # ffffffffc0204aa0 <commands+0x998>
ffffffffc0201358:	00003617          	auipc	a2,0x3
ffffffffc020135c:	5c060613          	addi	a2,a2,1472 # ffffffffc0204918 <commands+0x810>
ffffffffc0201360:	0db00593          	li	a1,219
ffffffffc0201364:	00003517          	auipc	a0,0x3
ffffffffc0201368:	5cc50513          	addi	a0,a0,1484 # ffffffffc0204930 <commands+0x828>
ffffffffc020136c:	8eeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201370:	00003697          	auipc	a3,0x3
ffffffffc0201374:	64868693          	addi	a3,a3,1608 # ffffffffc02049b8 <commands+0x8b0>
ffffffffc0201378:	00003617          	auipc	a2,0x3
ffffffffc020137c:	5a060613          	addi	a2,a2,1440 # ffffffffc0204918 <commands+0x810>
ffffffffc0201380:	0d900593          	li	a1,217
ffffffffc0201384:	00003517          	auipc	a0,0x3
ffffffffc0201388:	5ac50513          	addi	a0,a0,1452 # ffffffffc0204930 <commands+0x828>
ffffffffc020138c:	8ceff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201390:	00003697          	auipc	a3,0x3
ffffffffc0201394:	60868693          	addi	a3,a3,1544 # ffffffffc0204998 <commands+0x890>
ffffffffc0201398:	00003617          	auipc	a2,0x3
ffffffffc020139c:	58060613          	addi	a2,a2,1408 # ffffffffc0204918 <commands+0x810>
ffffffffc02013a0:	0d800593          	li	a1,216
ffffffffc02013a4:	00003517          	auipc	a0,0x3
ffffffffc02013a8:	58c50513          	addi	a0,a0,1420 # ffffffffc0204930 <commands+0x828>
ffffffffc02013ac:	8aeff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013b0:	00003697          	auipc	a3,0x3
ffffffffc02013b4:	60868693          	addi	a3,a3,1544 # ffffffffc02049b8 <commands+0x8b0>
ffffffffc02013b8:	00003617          	auipc	a2,0x3
ffffffffc02013bc:	56060613          	addi	a2,a2,1376 # ffffffffc0204918 <commands+0x810>
ffffffffc02013c0:	0c000593          	li	a1,192
ffffffffc02013c4:	00003517          	auipc	a0,0x3
ffffffffc02013c8:	56c50513          	addi	a0,a0,1388 # ffffffffc0204930 <commands+0x828>
ffffffffc02013cc:	88eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc02013d0:	00004697          	auipc	a3,0x4
ffffffffc02013d4:	89068693          	addi	a3,a3,-1904 # ffffffffc0204c60 <commands+0xb58>
ffffffffc02013d8:	00003617          	auipc	a2,0x3
ffffffffc02013dc:	54060613          	addi	a2,a2,1344 # ffffffffc0204918 <commands+0x810>
ffffffffc02013e0:	12a00593          	li	a1,298
ffffffffc02013e4:	00003517          	auipc	a0,0x3
ffffffffc02013e8:	54c50513          	addi	a0,a0,1356 # ffffffffc0204930 <commands+0x828>
ffffffffc02013ec:	86eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc02013f0:	00003697          	auipc	a3,0x3
ffffffffc02013f4:	71068693          	addi	a3,a3,1808 # ffffffffc0204b00 <commands+0x9f8>
ffffffffc02013f8:	00003617          	auipc	a2,0x3
ffffffffc02013fc:	52060613          	addi	a2,a2,1312 # ffffffffc0204918 <commands+0x810>
ffffffffc0201400:	11f00593          	li	a1,287
ffffffffc0201404:	00003517          	auipc	a0,0x3
ffffffffc0201408:	52c50513          	addi	a0,a0,1324 # ffffffffc0204930 <commands+0x828>
ffffffffc020140c:	84eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201410:	00003697          	auipc	a3,0x3
ffffffffc0201414:	69068693          	addi	a3,a3,1680 # ffffffffc0204aa0 <commands+0x998>
ffffffffc0201418:	00003617          	auipc	a2,0x3
ffffffffc020141c:	50060613          	addi	a2,a2,1280 # ffffffffc0204918 <commands+0x810>
ffffffffc0201420:	11d00593          	li	a1,285
ffffffffc0201424:	00003517          	auipc	a0,0x3
ffffffffc0201428:	50c50513          	addi	a0,a0,1292 # ffffffffc0204930 <commands+0x828>
ffffffffc020142c:	82eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201430:	00003697          	auipc	a3,0x3
ffffffffc0201434:	63068693          	addi	a3,a3,1584 # ffffffffc0204a60 <commands+0x958>
ffffffffc0201438:	00003617          	auipc	a2,0x3
ffffffffc020143c:	4e060613          	addi	a2,a2,1248 # ffffffffc0204918 <commands+0x810>
ffffffffc0201440:	0c600593          	li	a1,198
ffffffffc0201444:	00003517          	auipc	a0,0x3
ffffffffc0201448:	4ec50513          	addi	a0,a0,1260 # ffffffffc0204930 <commands+0x828>
ffffffffc020144c:	80eff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201450:	00003697          	auipc	a3,0x3
ffffffffc0201454:	7d068693          	addi	a3,a3,2000 # ffffffffc0204c20 <commands+0xb18>
ffffffffc0201458:	00003617          	auipc	a2,0x3
ffffffffc020145c:	4c060613          	addi	a2,a2,1216 # ffffffffc0204918 <commands+0x810>
ffffffffc0201460:	11700593          	li	a1,279
ffffffffc0201464:	00003517          	auipc	a0,0x3
ffffffffc0201468:	4cc50513          	addi	a0,a0,1228 # ffffffffc0204930 <commands+0x828>
ffffffffc020146c:	feffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201470:	00003697          	auipc	a3,0x3
ffffffffc0201474:	79068693          	addi	a3,a3,1936 # ffffffffc0204c00 <commands+0xaf8>
ffffffffc0201478:	00003617          	auipc	a2,0x3
ffffffffc020147c:	4a060613          	addi	a2,a2,1184 # ffffffffc0204918 <commands+0x810>
ffffffffc0201480:	11500593          	li	a1,277
ffffffffc0201484:	00003517          	auipc	a0,0x3
ffffffffc0201488:	4ac50513          	addi	a0,a0,1196 # ffffffffc0204930 <commands+0x828>
ffffffffc020148c:	fcffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201490:	00003697          	auipc	a3,0x3
ffffffffc0201494:	74868693          	addi	a3,a3,1864 # ffffffffc0204bd8 <commands+0xad0>
ffffffffc0201498:	00003617          	auipc	a2,0x3
ffffffffc020149c:	48060613          	addi	a2,a2,1152 # ffffffffc0204918 <commands+0x810>
ffffffffc02014a0:	11300593          	li	a1,275
ffffffffc02014a4:	00003517          	auipc	a0,0x3
ffffffffc02014a8:	48c50513          	addi	a0,a0,1164 # ffffffffc0204930 <commands+0x828>
ffffffffc02014ac:	faffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014b0:	00003697          	auipc	a3,0x3
ffffffffc02014b4:	70068693          	addi	a3,a3,1792 # ffffffffc0204bb0 <commands+0xaa8>
ffffffffc02014b8:	00003617          	auipc	a2,0x3
ffffffffc02014bc:	46060613          	addi	a2,a2,1120 # ffffffffc0204918 <commands+0x810>
ffffffffc02014c0:	11200593          	li	a1,274
ffffffffc02014c4:	00003517          	auipc	a0,0x3
ffffffffc02014c8:	46c50513          	addi	a0,a0,1132 # ffffffffc0204930 <commands+0x828>
ffffffffc02014cc:	f8ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014d0:	00003697          	auipc	a3,0x3
ffffffffc02014d4:	6d068693          	addi	a3,a3,1744 # ffffffffc0204ba0 <commands+0xa98>
ffffffffc02014d8:	00003617          	auipc	a2,0x3
ffffffffc02014dc:	44060613          	addi	a2,a2,1088 # ffffffffc0204918 <commands+0x810>
ffffffffc02014e0:	10d00593          	li	a1,269
ffffffffc02014e4:	00003517          	auipc	a0,0x3
ffffffffc02014e8:	44c50513          	addi	a0,a0,1100 # ffffffffc0204930 <commands+0x828>
ffffffffc02014ec:	f6ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014f0:	00003697          	auipc	a3,0x3
ffffffffc02014f4:	5b068693          	addi	a3,a3,1456 # ffffffffc0204aa0 <commands+0x998>
ffffffffc02014f8:	00003617          	auipc	a2,0x3
ffffffffc02014fc:	42060613          	addi	a2,a2,1056 # ffffffffc0204918 <commands+0x810>
ffffffffc0201500:	10c00593          	li	a1,268
ffffffffc0201504:	00003517          	auipc	a0,0x3
ffffffffc0201508:	42c50513          	addi	a0,a0,1068 # ffffffffc0204930 <commands+0x828>
ffffffffc020150c:	f4ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201510:	00003697          	auipc	a3,0x3
ffffffffc0201514:	67068693          	addi	a3,a3,1648 # ffffffffc0204b80 <commands+0xa78>
ffffffffc0201518:	00003617          	auipc	a2,0x3
ffffffffc020151c:	40060613          	addi	a2,a2,1024 # ffffffffc0204918 <commands+0x810>
ffffffffc0201520:	10b00593          	li	a1,267
ffffffffc0201524:	00003517          	auipc	a0,0x3
ffffffffc0201528:	40c50513          	addi	a0,a0,1036 # ffffffffc0204930 <commands+0x828>
ffffffffc020152c:	f2ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201530:	00003697          	auipc	a3,0x3
ffffffffc0201534:	62068693          	addi	a3,a3,1568 # ffffffffc0204b50 <commands+0xa48>
ffffffffc0201538:	00003617          	auipc	a2,0x3
ffffffffc020153c:	3e060613          	addi	a2,a2,992 # ffffffffc0204918 <commands+0x810>
ffffffffc0201540:	10a00593          	li	a1,266
ffffffffc0201544:	00003517          	auipc	a0,0x3
ffffffffc0201548:	3ec50513          	addi	a0,a0,1004 # ffffffffc0204930 <commands+0x828>
ffffffffc020154c:	f0ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201550:	00003697          	auipc	a3,0x3
ffffffffc0201554:	5e868693          	addi	a3,a3,1512 # ffffffffc0204b38 <commands+0xa30>
ffffffffc0201558:	00003617          	auipc	a2,0x3
ffffffffc020155c:	3c060613          	addi	a2,a2,960 # ffffffffc0204918 <commands+0x810>
ffffffffc0201560:	10900593          	li	a1,265
ffffffffc0201564:	00003517          	auipc	a0,0x3
ffffffffc0201568:	3cc50513          	addi	a0,a0,972 # ffffffffc0204930 <commands+0x828>
ffffffffc020156c:	eeffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201570:	00003697          	auipc	a3,0x3
ffffffffc0201574:	53068693          	addi	a3,a3,1328 # ffffffffc0204aa0 <commands+0x998>
ffffffffc0201578:	00003617          	auipc	a2,0x3
ffffffffc020157c:	3a060613          	addi	a2,a2,928 # ffffffffc0204918 <commands+0x810>
ffffffffc0201580:	10300593          	li	a1,259
ffffffffc0201584:	00003517          	auipc	a0,0x3
ffffffffc0201588:	3ac50513          	addi	a0,a0,940 # ffffffffc0204930 <commands+0x828>
ffffffffc020158c:	ecffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc0201590:	00003697          	auipc	a3,0x3
ffffffffc0201594:	59068693          	addi	a3,a3,1424 # ffffffffc0204b20 <commands+0xa18>
ffffffffc0201598:	00003617          	auipc	a2,0x3
ffffffffc020159c:	38060613          	addi	a2,a2,896 # ffffffffc0204918 <commands+0x810>
ffffffffc02015a0:	0fe00593          	li	a1,254
ffffffffc02015a4:	00003517          	auipc	a0,0x3
ffffffffc02015a8:	38c50513          	addi	a0,a0,908 # ffffffffc0204930 <commands+0x828>
ffffffffc02015ac:	eaffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015b0:	00003697          	auipc	a3,0x3
ffffffffc02015b4:	69068693          	addi	a3,a3,1680 # ffffffffc0204c40 <commands+0xb38>
ffffffffc02015b8:	00003617          	auipc	a2,0x3
ffffffffc02015bc:	36060613          	addi	a2,a2,864 # ffffffffc0204918 <commands+0x810>
ffffffffc02015c0:	11c00593          	li	a1,284
ffffffffc02015c4:	00003517          	auipc	a0,0x3
ffffffffc02015c8:	36c50513          	addi	a0,a0,876 # ffffffffc0204930 <commands+0x828>
ffffffffc02015cc:	e8ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc02015d0:	00003697          	auipc	a3,0x3
ffffffffc02015d4:	6a068693          	addi	a3,a3,1696 # ffffffffc0204c70 <commands+0xb68>
ffffffffc02015d8:	00003617          	auipc	a2,0x3
ffffffffc02015dc:	34060613          	addi	a2,a2,832 # ffffffffc0204918 <commands+0x810>
ffffffffc02015e0:	12b00593          	li	a1,299
ffffffffc02015e4:	00003517          	auipc	a0,0x3
ffffffffc02015e8:	34c50513          	addi	a0,a0,844 # ffffffffc0204930 <commands+0x828>
ffffffffc02015ec:	e6ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc02015f0:	00003697          	auipc	a3,0x3
ffffffffc02015f4:	36868693          	addi	a3,a3,872 # ffffffffc0204958 <commands+0x850>
ffffffffc02015f8:	00003617          	auipc	a2,0x3
ffffffffc02015fc:	32060613          	addi	a2,a2,800 # ffffffffc0204918 <commands+0x810>
ffffffffc0201600:	0f800593          	li	a1,248
ffffffffc0201604:	00003517          	auipc	a0,0x3
ffffffffc0201608:	32c50513          	addi	a0,a0,812 # ffffffffc0204930 <commands+0x828>
ffffffffc020160c:	e4ffe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201610:	00003697          	auipc	a3,0x3
ffffffffc0201614:	38868693          	addi	a3,a3,904 # ffffffffc0204998 <commands+0x890>
ffffffffc0201618:	00003617          	auipc	a2,0x3
ffffffffc020161c:	30060613          	addi	a2,a2,768 # ffffffffc0204918 <commands+0x810>
ffffffffc0201620:	0bf00593          	li	a1,191
ffffffffc0201624:	00003517          	auipc	a0,0x3
ffffffffc0201628:	30c50513          	addi	a0,a0,780 # ffffffffc0204930 <commands+0x828>
ffffffffc020162c:	e2ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201630 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201630:	1141                	addi	sp,sp,-16
ffffffffc0201632:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201634:	14058463          	beqz	a1,ffffffffc020177c <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0201638:	00659693          	slli	a3,a1,0x6
ffffffffc020163c:	96aa                	add	a3,a3,a0
ffffffffc020163e:	87aa                	mv	a5,a0
ffffffffc0201640:	02d50263          	beq	a0,a3,ffffffffc0201664 <default_free_pages+0x34>
ffffffffc0201644:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201646:	8b05                	andi	a4,a4,1
ffffffffc0201648:	10071a63          	bnez	a4,ffffffffc020175c <default_free_pages+0x12c>
ffffffffc020164c:	6798                	ld	a4,8(a5)
ffffffffc020164e:	8b09                	andi	a4,a4,2
ffffffffc0201650:	10071663          	bnez	a4,ffffffffc020175c <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201654:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201658:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020165c:	04078793          	addi	a5,a5,64
ffffffffc0201660:	fed792e3          	bne	a5,a3,ffffffffc0201644 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201664:	2581                	sext.w	a1,a1
ffffffffc0201666:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201668:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020166c:	4789                	li	a5,2
ffffffffc020166e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201672:	00008697          	auipc	a3,0x8
ffffffffc0201676:	dbe68693          	addi	a3,a3,-578 # ffffffffc0209430 <free_area>
ffffffffc020167a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020167c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020167e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201682:	9db9                	addw	a1,a1,a4
ffffffffc0201684:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201686:	0ad78463          	beq	a5,a3,ffffffffc020172e <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc020168a:	fe878713          	addi	a4,a5,-24
ffffffffc020168e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201692:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201694:	00e56a63          	bltu	a0,a4,ffffffffc02016a8 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201698:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020169a:	04d70c63          	beq	a4,a3,ffffffffc02016f2 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc020169e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016a0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016a4:	fee57ae3          	bgeu	a0,a4,ffffffffc0201698 <default_free_pages+0x68>
ffffffffc02016a8:	c199                	beqz	a1,ffffffffc02016ae <default_free_pages+0x7e>
ffffffffc02016aa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016ae:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02016b0:	e390                	sd	a2,0(a5)
ffffffffc02016b2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016b4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016b6:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02016b8:	00d70d63          	beq	a4,a3,ffffffffc02016d2 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc02016bc:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016c0:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc02016c4:	02059813          	slli	a6,a1,0x20
ffffffffc02016c8:	01a85793          	srli	a5,a6,0x1a
ffffffffc02016cc:	97b2                	add	a5,a5,a2
ffffffffc02016ce:	02f50c63          	beq	a0,a5,ffffffffc0201706 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02016d2:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02016d4:	00d78c63          	beq	a5,a3,ffffffffc02016ec <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc02016d8:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02016da:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02016de:	02061593          	slli	a1,a2,0x20
ffffffffc02016e2:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02016e6:	972a                	add	a4,a4,a0
ffffffffc02016e8:	04e68a63          	beq	a3,a4,ffffffffc020173c <default_free_pages+0x10c>
}
ffffffffc02016ec:	60a2                	ld	ra,8(sp)
ffffffffc02016ee:	0141                	addi	sp,sp,16
ffffffffc02016f0:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016f2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016f4:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016f6:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016f8:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016fa:	02d70763          	beq	a4,a3,ffffffffc0201728 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02016fe:	8832                	mv	a6,a2
ffffffffc0201700:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201702:	87ba                	mv	a5,a4
ffffffffc0201704:	bf71                	j	ffffffffc02016a0 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201706:	491c                	lw	a5,16(a0)
ffffffffc0201708:	9dbd                	addw	a1,a1,a5
ffffffffc020170a:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020170e:	57f5                	li	a5,-3
ffffffffc0201710:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201714:	01853803          	ld	a6,24(a0)
ffffffffc0201718:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020171a:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc020171c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201720:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201722:	0105b023          	sd	a6,0(a1)
ffffffffc0201726:	b77d                	j	ffffffffc02016d4 <default_free_pages+0xa4>
ffffffffc0201728:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020172a:	873e                	mv	a4,a5
ffffffffc020172c:	bf41                	j	ffffffffc02016bc <default_free_pages+0x8c>
}
ffffffffc020172e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201730:	e390                	sd	a2,0(a5)
ffffffffc0201732:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201734:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201736:	ed1c                	sd	a5,24(a0)
ffffffffc0201738:	0141                	addi	sp,sp,16
ffffffffc020173a:	8082                	ret
            base->property += p->property;
ffffffffc020173c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201740:	ff078693          	addi	a3,a5,-16
ffffffffc0201744:	9e39                	addw	a2,a2,a4
ffffffffc0201746:	c910                	sw	a2,16(a0)
ffffffffc0201748:	5775                	li	a4,-3
ffffffffc020174a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020174e:	6398                	ld	a4,0(a5)
ffffffffc0201750:	679c                	ld	a5,8(a5)
}
ffffffffc0201752:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201754:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201756:	e398                	sd	a4,0(a5)
ffffffffc0201758:	0141                	addi	sp,sp,16
ffffffffc020175a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020175c:	00003697          	auipc	a3,0x3
ffffffffc0201760:	52468693          	addi	a3,a3,1316 # ffffffffc0204c80 <commands+0xb78>
ffffffffc0201764:	00003617          	auipc	a2,0x3
ffffffffc0201768:	1b460613          	addi	a2,a2,436 # ffffffffc0204918 <commands+0x810>
ffffffffc020176c:	08800593          	li	a1,136
ffffffffc0201770:	00003517          	auipc	a0,0x3
ffffffffc0201774:	1c050513          	addi	a0,a0,448 # ffffffffc0204930 <commands+0x828>
ffffffffc0201778:	ce3fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc020177c:	00003697          	auipc	a3,0x3
ffffffffc0201780:	19468693          	addi	a3,a3,404 # ffffffffc0204910 <commands+0x808>
ffffffffc0201784:	00003617          	auipc	a2,0x3
ffffffffc0201788:	19460613          	addi	a2,a2,404 # ffffffffc0204918 <commands+0x810>
ffffffffc020178c:	08500593          	li	a1,133
ffffffffc0201790:	00003517          	auipc	a0,0x3
ffffffffc0201794:	1a050513          	addi	a0,a0,416 # ffffffffc0204930 <commands+0x828>
ffffffffc0201798:	cc3fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020179c <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020179c:	1141                	addi	sp,sp,-16
ffffffffc020179e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017a0:	c9d5                	beqz	a1,ffffffffc0201854 <default_init_memmap+0xb8>
    for (; p != base + n; p ++) {
ffffffffc02017a2:	00659693          	slli	a3,a1,0x6
ffffffffc02017a6:	96aa                	add	a3,a3,a0
ffffffffc02017a8:	87aa                	mv	a5,a0
ffffffffc02017aa:	00d50f63          	beq	a0,a3,ffffffffc02017c8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017ae:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02017b0:	8b05                	andi	a4,a4,1
ffffffffc02017b2:	c349                	beqz	a4,ffffffffc0201834 <default_init_memmap+0x98>
        p->flags=0;
ffffffffc02017b4:	0007b423          	sd	zero,8(a5)
        p->property=0;
ffffffffc02017b8:	0007a823          	sw	zero,16(a5)
ffffffffc02017bc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017c0:	04078793          	addi	a5,a5,64
ffffffffc02017c4:	fed795e3          	bne	a5,a3,ffffffffc02017ae <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017c8:	2581                	sext.w	a1,a1
ffffffffc02017ca:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017cc:	4789                	li	a5,2
ffffffffc02017ce:	00850713          	addi	a4,a0,8
ffffffffc02017d2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017d6:	00008697          	auipc	a3,0x8
ffffffffc02017da:	c5a68693          	addi	a3,a3,-934 # ffffffffc0209430 <free_area>
ffffffffc02017de:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017e0:	669c                	ld	a5,8(a3)
ffffffffc02017e2:	9db9                	addw	a1,a1,a4
ffffffffc02017e4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02017e6:	00d79763          	bne	a5,a3,ffffffffc02017f4 <default_init_memmap+0x58>
ffffffffc02017ea:	a01d                	j	ffffffffc0201810 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02017ec:	6798                	ld	a4,8(a5)
            }else if(list_next(le)==&free_list)
ffffffffc02017ee:	02d70a63          	beq	a4,a3,ffffffffc0201822 <default_init_memmap+0x86>
ffffffffc02017f2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02017f4:	fe878713          	addi	a4,a5,-24
            if(base<page)
ffffffffc02017f8:	fee57ae3          	bgeu	a0,a4,ffffffffc02017ec <default_init_memmap+0x50>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017fc:	6398                	ld	a4,0(a5)
                list_add_before(le,&(base->page_link));
ffffffffc02017fe:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0201802:	e394                	sd	a3,0(a5)
}
ffffffffc0201804:	60a2                	ld	ra,8(sp)
ffffffffc0201806:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0201808:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020180a:	ed18                	sd	a4,24(a0)
ffffffffc020180c:	0141                	addi	sp,sp,16
ffffffffc020180e:	8082                	ret
ffffffffc0201810:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201812:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201816:	e398                	sd	a4,0(a5)
ffffffffc0201818:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020181a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020181c:	ed1c                	sd	a5,24(a0)
}
ffffffffc020181e:	0141                	addi	sp,sp,16
ffffffffc0201820:	8082                	ret
ffffffffc0201822:	60a2                	ld	ra,8(sp)
                list_add(le,&(base->page_link));
ffffffffc0201824:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201828:	e798                	sd	a4,8(a5)
ffffffffc020182a:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc020182c:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc020182e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201830:	0141                	addi	sp,sp,16
ffffffffc0201832:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201834:	00003697          	auipc	a3,0x3
ffffffffc0201838:	47468693          	addi	a3,a3,1140 # ffffffffc0204ca8 <commands+0xba0>
ffffffffc020183c:	00003617          	auipc	a2,0x3
ffffffffc0201840:	0dc60613          	addi	a2,a2,220 # ffffffffc0204918 <commands+0x810>
ffffffffc0201844:	04900593          	li	a1,73
ffffffffc0201848:	00003517          	auipc	a0,0x3
ffffffffc020184c:	0e850513          	addi	a0,a0,232 # ffffffffc0204930 <commands+0x828>
ffffffffc0201850:	c0bfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc0201854:	00003697          	auipc	a3,0x3
ffffffffc0201858:	0bc68693          	addi	a3,a3,188 # ffffffffc0204910 <commands+0x808>
ffffffffc020185c:	00003617          	auipc	a2,0x3
ffffffffc0201860:	0bc60613          	addi	a2,a2,188 # ffffffffc0204918 <commands+0x810>
ffffffffc0201864:	04600593          	li	a1,70
ffffffffc0201868:	00003517          	auipc	a0,0x3
ffffffffc020186c:	0c850513          	addi	a0,a0,200 # ffffffffc0204930 <commands+0x828>
ffffffffc0201870:	bebfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201874 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201874:	c94d                	beqz	a0,ffffffffc0201926 <slob_free+0xb2>
{
ffffffffc0201876:	1141                	addi	sp,sp,-16
ffffffffc0201878:	e022                	sd	s0,0(sp)
ffffffffc020187a:	e406                	sd	ra,8(sp)
ffffffffc020187c:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020187e:	e9c1                	bnez	a1,ffffffffc020190e <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201880:	100027f3          	csrr	a5,sstatus
ffffffffc0201884:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201886:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201888:	ebd9                	bnez	a5,ffffffffc020191e <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020188a:	00007617          	auipc	a2,0x7
ffffffffc020188e:	79660613          	addi	a2,a2,1942 # ffffffffc0209020 <slobfree>
ffffffffc0201892:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201894:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201896:	679c                	ld	a5,8(a5)
ffffffffc0201898:	02877a63          	bgeu	a4,s0,ffffffffc02018cc <slob_free+0x58>
ffffffffc020189c:	00f46463          	bltu	s0,a5,ffffffffc02018a4 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018a0:	fef76ae3          	bltu	a4,a5,ffffffffc0201894 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02018a4:	400c                	lw	a1,0(s0)
ffffffffc02018a6:	00459693          	slli	a3,a1,0x4
ffffffffc02018aa:	96a2                	add	a3,a3,s0
ffffffffc02018ac:	02d78a63          	beq	a5,a3,ffffffffc02018e0 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02018b0:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02018b2:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018b4:	00469793          	slli	a5,a3,0x4
ffffffffc02018b8:	97ba                	add	a5,a5,a4
ffffffffc02018ba:	02f40e63          	beq	s0,a5,ffffffffc02018f6 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02018be:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02018c0:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02018c2:	e129                	bnez	a0,ffffffffc0201904 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018c4:	60a2                	ld	ra,8(sp)
ffffffffc02018c6:	6402                	ld	s0,0(sp)
ffffffffc02018c8:	0141                	addi	sp,sp,16
ffffffffc02018ca:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018cc:	fcf764e3          	bltu	a4,a5,ffffffffc0201894 <slob_free+0x20>
ffffffffc02018d0:	fcf472e3          	bgeu	s0,a5,ffffffffc0201894 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02018d4:	400c                	lw	a1,0(s0)
ffffffffc02018d6:	00459693          	slli	a3,a1,0x4
ffffffffc02018da:	96a2                	add	a3,a3,s0
ffffffffc02018dc:	fcd79ae3          	bne	a5,a3,ffffffffc02018b0 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02018e0:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018e2:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02018e4:	9db5                	addw	a1,a1,a3
ffffffffc02018e6:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02018e8:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02018ea:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018ec:	00469793          	slli	a5,a3,0x4
ffffffffc02018f0:	97ba                	add	a5,a5,a4
ffffffffc02018f2:	fcf416e3          	bne	s0,a5,ffffffffc02018be <slob_free+0x4a>
		cur->units += b->units;
ffffffffc02018f6:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc02018f8:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc02018fa:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc02018fc:	9ebd                	addw	a3,a3,a5
ffffffffc02018fe:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201900:	e70c                	sd	a1,8(a4)
ffffffffc0201902:	d169                	beqz	a0,ffffffffc02018c4 <slob_free+0x50>
}
ffffffffc0201904:	6402                	ld	s0,0(sp)
ffffffffc0201906:	60a2                	ld	ra,8(sp)
ffffffffc0201908:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020190a:	820ff06f          	j	ffffffffc020092a <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc020190e:	25bd                	addiw	a1,a1,15
ffffffffc0201910:	8191                	srli	a1,a1,0x4
ffffffffc0201912:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201914:	100027f3          	csrr	a5,sstatus
ffffffffc0201918:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020191a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020191c:	d7bd                	beqz	a5,ffffffffc020188a <slob_free+0x16>
        intr_disable();
ffffffffc020191e:	812ff0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201922:	4505                	li	a0,1
ffffffffc0201924:	b79d                	j	ffffffffc020188a <slob_free+0x16>
ffffffffc0201926:	8082                	ret

ffffffffc0201928 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201928:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020192a:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc020192c:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201930:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201932:	34e000ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
	if (!page)
ffffffffc0201936:	c91d                	beqz	a0,ffffffffc020196c <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201938:	0000c697          	auipc	a3,0xc
ffffffffc020193c:	b806b683          	ld	a3,-1152(a3) # ffffffffc020d4b8 <pages>
ffffffffc0201940:	8d15                	sub	a0,a0,a3
ffffffffc0201942:	8519                	srai	a0,a0,0x6
ffffffffc0201944:	00004697          	auipc	a3,0x4
ffffffffc0201948:	0a46b683          	ld	a3,164(a3) # ffffffffc02059e8 <nbase>
ffffffffc020194c:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc020194e:	00c51793          	slli	a5,a0,0xc
ffffffffc0201952:	83b1                	srli	a5,a5,0xc
ffffffffc0201954:	0000c717          	auipc	a4,0xc
ffffffffc0201958:	b5c73703          	ld	a4,-1188(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc020195c:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc020195e:	00e7fa63          	bgeu	a5,a4,ffffffffc0201972 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201962:	0000c697          	auipc	a3,0xc
ffffffffc0201966:	b666b683          	ld	a3,-1178(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc020196a:	9536                	add	a0,a0,a3
}
ffffffffc020196c:	60a2                	ld	ra,8(sp)
ffffffffc020196e:	0141                	addi	sp,sp,16
ffffffffc0201970:	8082                	ret
ffffffffc0201972:	86aa                	mv	a3,a0
ffffffffc0201974:	00003617          	auipc	a2,0x3
ffffffffc0201978:	39460613          	addi	a2,a2,916 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc020197c:	07100593          	li	a1,113
ffffffffc0201980:	00003517          	auipc	a0,0x3
ffffffffc0201984:	3b050513          	addi	a0,a0,944 # ffffffffc0204d30 <default_pmm_manager+0x60>
ffffffffc0201988:	ad3fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020198c <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020198c:	1101                	addi	sp,sp,-32
ffffffffc020198e:	ec06                	sd	ra,24(sp)
ffffffffc0201990:	e822                	sd	s0,16(sp)
ffffffffc0201992:	e426                	sd	s1,8(sp)
ffffffffc0201994:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201996:	01050713          	addi	a4,a0,16
ffffffffc020199a:	6785                	lui	a5,0x1
ffffffffc020199c:	0cf77363          	bgeu	a4,a5,ffffffffc0201a62 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019a0:	00f50493          	addi	s1,a0,15
ffffffffc02019a4:	8091                	srli	s1,s1,0x4
ffffffffc02019a6:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a8:	10002673          	csrr	a2,sstatus
ffffffffc02019ac:	8a09                	andi	a2,a2,2
ffffffffc02019ae:	e25d                	bnez	a2,ffffffffc0201a54 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019b0:	00007917          	auipc	s2,0x7
ffffffffc02019b4:	67090913          	addi	s2,s2,1648 # ffffffffc0209020 <slobfree>
ffffffffc02019b8:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019bc:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02019be:	4398                	lw	a4,0(a5)
ffffffffc02019c0:	08975e63          	bge	a4,s1,ffffffffc0201a5c <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02019c4:	00d78b63          	beq	a5,a3,ffffffffc02019da <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019c8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019ca:	4018                	lw	a4,0(s0)
ffffffffc02019cc:	02975a63          	bge	a4,s1,ffffffffc0201a00 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02019d0:	00093683          	ld	a3,0(s2)
ffffffffc02019d4:	87a2                	mv	a5,s0
ffffffffc02019d6:	fed799e3          	bne	a5,a3,ffffffffc02019c8 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02019da:	ee31                	bnez	a2,ffffffffc0201a36 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019dc:	4501                	li	a0,0
ffffffffc02019de:	f4bff0ef          	jal	ra,ffffffffc0201928 <__slob_get_free_pages.constprop.0>
ffffffffc02019e2:	842a                	mv	s0,a0
			if (!cur)
ffffffffc02019e4:	cd05                	beqz	a0,ffffffffc0201a1c <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019e6:	6585                	lui	a1,0x1
ffffffffc02019e8:	e8dff0ef          	jal	ra,ffffffffc0201874 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019ec:	10002673          	csrr	a2,sstatus
ffffffffc02019f0:	8a09                	andi	a2,a2,2
ffffffffc02019f2:	ee05                	bnez	a2,ffffffffc0201a2a <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc02019f4:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019f8:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019fa:	4018                	lw	a4,0(s0)
ffffffffc02019fc:	fc974ae3          	blt	a4,s1,ffffffffc02019d0 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a00:	04e48763          	beq	s1,a4,ffffffffc0201a4e <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a04:	00449693          	slli	a3,s1,0x4
ffffffffc0201a08:	96a2                	add	a3,a3,s0
ffffffffc0201a0a:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a0c:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a0e:	9f05                	subw	a4,a4,s1
ffffffffc0201a10:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a12:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a14:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a16:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a1a:	e20d                	bnez	a2,ffffffffc0201a3c <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a1c:	60e2                	ld	ra,24(sp)
ffffffffc0201a1e:	8522                	mv	a0,s0
ffffffffc0201a20:	6442                	ld	s0,16(sp)
ffffffffc0201a22:	64a2                	ld	s1,8(sp)
ffffffffc0201a24:	6902                	ld	s2,0(sp)
ffffffffc0201a26:	6105                	addi	sp,sp,32
ffffffffc0201a28:	8082                	ret
        intr_disable();
ffffffffc0201a2a:	f07fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
			cur = slobfree;
ffffffffc0201a2e:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a32:	4605                	li	a2,1
ffffffffc0201a34:	b7d1                	j	ffffffffc02019f8 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a36:	ef5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201a3a:	b74d                	j	ffffffffc02019dc <slob_alloc.constprop.0+0x50>
ffffffffc0201a3c:	eeffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0201a40:	60e2                	ld	ra,24(sp)
ffffffffc0201a42:	8522                	mv	a0,s0
ffffffffc0201a44:	6442                	ld	s0,16(sp)
ffffffffc0201a46:	64a2                	ld	s1,8(sp)
ffffffffc0201a48:	6902                	ld	s2,0(sp)
ffffffffc0201a4a:	6105                	addi	sp,sp,32
ffffffffc0201a4c:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a4e:	6418                	ld	a4,8(s0)
ffffffffc0201a50:	e798                	sd	a4,8(a5)
ffffffffc0201a52:	b7d1                	j	ffffffffc0201a16 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a54:	eddfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201a58:	4605                	li	a2,1
ffffffffc0201a5a:	bf99                	j	ffffffffc02019b0 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201a5c:	843e                	mv	s0,a5
ffffffffc0201a5e:	87b6                	mv	a5,a3
ffffffffc0201a60:	b745                	j	ffffffffc0201a00 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a62:	00003697          	auipc	a3,0x3
ffffffffc0201a66:	2de68693          	addi	a3,a3,734 # ffffffffc0204d40 <default_pmm_manager+0x70>
ffffffffc0201a6a:	00003617          	auipc	a2,0x3
ffffffffc0201a6e:	eae60613          	addi	a2,a2,-338 # ffffffffc0204918 <commands+0x810>
ffffffffc0201a72:	06300593          	li	a1,99
ffffffffc0201a76:	00003517          	auipc	a0,0x3
ffffffffc0201a7a:	2ea50513          	addi	a0,a0,746 # ffffffffc0204d60 <default_pmm_manager+0x90>
ffffffffc0201a7e:	9ddfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201a82 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a82:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a84:	00003517          	auipc	a0,0x3
ffffffffc0201a88:	2f450513          	addi	a0,a0,756 # ffffffffc0204d78 <default_pmm_manager+0xa8>
{
ffffffffc0201a8c:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a8e:	f06fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a92:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a94:	00003517          	auipc	a0,0x3
ffffffffc0201a98:	2fc50513          	addi	a0,a0,764 # ffffffffc0204d90 <default_pmm_manager+0xc0>
}
ffffffffc0201a9c:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a9e:	ef6fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201aa2 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201aa2:	1101                	addi	sp,sp,-32
ffffffffc0201aa4:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aa6:	6905                	lui	s2,0x1
{
ffffffffc0201aa8:	e822                	sd	s0,16(sp)
ffffffffc0201aaa:	ec06                	sd	ra,24(sp)
ffffffffc0201aac:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201aae:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201ab2:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ab4:	04a7f963          	bgeu	a5,a0,ffffffffc0201b06 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ab8:	4561                	li	a0,24
ffffffffc0201aba:	ed3ff0ef          	jal	ra,ffffffffc020198c <slob_alloc.constprop.0>
ffffffffc0201abe:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ac0:	c929                	beqz	a0,ffffffffc0201b12 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201ac2:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ac6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ac8:	00f95763          	bge	s2,a5,ffffffffc0201ad6 <kmalloc+0x34>
ffffffffc0201acc:	6705                	lui	a4,0x1
ffffffffc0201ace:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201ad0:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ad2:	fef74ee3          	blt	a4,a5,ffffffffc0201ace <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201ad6:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ad8:	e51ff0ef          	jal	ra,ffffffffc0201928 <__slob_get_free_pages.constprop.0>
ffffffffc0201adc:	e488                	sd	a0,8(s1)
ffffffffc0201ade:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201ae0:	c525                	beqz	a0,ffffffffc0201b48 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ae2:	100027f3          	csrr	a5,sstatus
ffffffffc0201ae6:	8b89                	andi	a5,a5,2
ffffffffc0201ae8:	ef8d                	bnez	a5,ffffffffc0201b22 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201aea:	0000c797          	auipc	a5,0xc
ffffffffc0201aee:	9ae78793          	addi	a5,a5,-1618 # ffffffffc020d498 <bigblocks>
ffffffffc0201af2:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201af4:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201af6:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201af8:	60e2                	ld	ra,24(sp)
ffffffffc0201afa:	8522                	mv	a0,s0
ffffffffc0201afc:	6442                	ld	s0,16(sp)
ffffffffc0201afe:	64a2                	ld	s1,8(sp)
ffffffffc0201b00:	6902                	ld	s2,0(sp)
ffffffffc0201b02:	6105                	addi	sp,sp,32
ffffffffc0201b04:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b06:	0541                	addi	a0,a0,16
ffffffffc0201b08:	e85ff0ef          	jal	ra,ffffffffc020198c <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b0c:	01050413          	addi	s0,a0,16
ffffffffc0201b10:	f565                	bnez	a0,ffffffffc0201af8 <kmalloc+0x56>
ffffffffc0201b12:	4401                	li	s0,0
}
ffffffffc0201b14:	60e2                	ld	ra,24(sp)
ffffffffc0201b16:	8522                	mv	a0,s0
ffffffffc0201b18:	6442                	ld	s0,16(sp)
ffffffffc0201b1a:	64a2                	ld	s1,8(sp)
ffffffffc0201b1c:	6902                	ld	s2,0(sp)
ffffffffc0201b1e:	6105                	addi	sp,sp,32
ffffffffc0201b20:	8082                	ret
        intr_disable();
ffffffffc0201b22:	e0ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b26:	0000c797          	auipc	a5,0xc
ffffffffc0201b2a:	97278793          	addi	a5,a5,-1678 # ffffffffc020d498 <bigblocks>
ffffffffc0201b2e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b30:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b32:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b34:	df7fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
		return bb->pages;
ffffffffc0201b38:	6480                	ld	s0,8(s1)
}
ffffffffc0201b3a:	60e2                	ld	ra,24(sp)
ffffffffc0201b3c:	64a2                	ld	s1,8(sp)
ffffffffc0201b3e:	8522                	mv	a0,s0
ffffffffc0201b40:	6442                	ld	s0,16(sp)
ffffffffc0201b42:	6902                	ld	s2,0(sp)
ffffffffc0201b44:	6105                	addi	sp,sp,32
ffffffffc0201b46:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b48:	45e1                	li	a1,24
ffffffffc0201b4a:	8526                	mv	a0,s1
ffffffffc0201b4c:	d29ff0ef          	jal	ra,ffffffffc0201874 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201b50:	b765                	j	ffffffffc0201af8 <kmalloc+0x56>

ffffffffc0201b52 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b52:	c169                	beqz	a0,ffffffffc0201c14 <kfree+0xc2>
{
ffffffffc0201b54:	1101                	addi	sp,sp,-32
ffffffffc0201b56:	e822                	sd	s0,16(sp)
ffffffffc0201b58:	ec06                	sd	ra,24(sp)
ffffffffc0201b5a:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b5c:	03451793          	slli	a5,a0,0x34
ffffffffc0201b60:	842a                	mv	s0,a0
ffffffffc0201b62:	e3d9                	bnez	a5,ffffffffc0201be8 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b64:	100027f3          	csrr	a5,sstatus
ffffffffc0201b68:	8b89                	andi	a5,a5,2
ffffffffc0201b6a:	e7d9                	bnez	a5,ffffffffc0201bf8 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b6c:	0000c797          	auipc	a5,0xc
ffffffffc0201b70:	92c7b783          	ld	a5,-1748(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b74:	4601                	li	a2,0
ffffffffc0201b76:	cbad                	beqz	a5,ffffffffc0201be8 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b78:	0000c697          	auipc	a3,0xc
ffffffffc0201b7c:	92068693          	addi	a3,a3,-1760 # ffffffffc020d498 <bigblocks>
ffffffffc0201b80:	a021                	j	ffffffffc0201b88 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b82:	01048693          	addi	a3,s1,16
ffffffffc0201b86:	c3a5                	beqz	a5,ffffffffc0201be6 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201b88:	6798                	ld	a4,8(a5)
ffffffffc0201b8a:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201b8c:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b8e:	fe871ae3          	bne	a4,s0,ffffffffc0201b82 <kfree+0x30>
				*last = bb->next;
ffffffffc0201b92:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201b94:	ee2d                	bnez	a2,ffffffffc0201c0e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201b96:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201b9a:	4098                	lw	a4,0(s1)
ffffffffc0201b9c:	08f46963          	bltu	s0,a5,ffffffffc0201c2e <kfree+0xdc>
ffffffffc0201ba0:	0000c697          	auipc	a3,0xc
ffffffffc0201ba4:	9286b683          	ld	a3,-1752(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201ba8:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201baa:	8031                	srli	s0,s0,0xc
ffffffffc0201bac:	0000c797          	auipc	a5,0xc
ffffffffc0201bb0:	9047b783          	ld	a5,-1788(a5) # ffffffffc020d4b0 <npage>
ffffffffc0201bb4:	06f47163          	bgeu	s0,a5,ffffffffc0201c16 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bb8:	00004517          	auipc	a0,0x4
ffffffffc0201bbc:	e3053503          	ld	a0,-464(a0) # ffffffffc02059e8 <nbase>
ffffffffc0201bc0:	8c09                	sub	s0,s0,a0
ffffffffc0201bc2:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201bc4:	0000c517          	auipc	a0,0xc
ffffffffc0201bc8:	8f453503          	ld	a0,-1804(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201bcc:	4585                	li	a1,1
ffffffffc0201bce:	9522                	add	a0,a0,s0
ffffffffc0201bd0:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201bd4:	0ea000ef          	jal	ra,ffffffffc0201cbe <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201bd8:	6442                	ld	s0,16(sp)
ffffffffc0201bda:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bdc:	8526                	mv	a0,s1
}
ffffffffc0201bde:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201be0:	45e1                	li	a1,24
}
ffffffffc0201be2:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201be4:	b941                	j	ffffffffc0201874 <slob_free>
ffffffffc0201be6:	e20d                	bnez	a2,ffffffffc0201c08 <kfree+0xb6>
ffffffffc0201be8:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201bec:	6442                	ld	s0,16(sp)
ffffffffc0201bee:	60e2                	ld	ra,24(sp)
ffffffffc0201bf0:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bf2:	4581                	li	a1,0
}
ffffffffc0201bf4:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bf6:	b9bd                	j	ffffffffc0201874 <slob_free>
        intr_disable();
ffffffffc0201bf8:	d39fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201bfc:	0000c797          	auipc	a5,0xc
ffffffffc0201c00:	89c7b783          	ld	a5,-1892(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201c04:	4605                	li	a2,1
ffffffffc0201c06:	fbad                	bnez	a5,ffffffffc0201b78 <kfree+0x26>
        intr_enable();
ffffffffc0201c08:	d23fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c0c:	bff1                	j	ffffffffc0201be8 <kfree+0x96>
ffffffffc0201c0e:	d1dfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c12:	b751                	j	ffffffffc0201b96 <kfree+0x44>
ffffffffc0201c14:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c16:	00003617          	auipc	a2,0x3
ffffffffc0201c1a:	1c260613          	addi	a2,a2,450 # ffffffffc0204dd8 <default_pmm_manager+0x108>
ffffffffc0201c1e:	06900593          	li	a1,105
ffffffffc0201c22:	00003517          	auipc	a0,0x3
ffffffffc0201c26:	10e50513          	addi	a0,a0,270 # ffffffffc0204d30 <default_pmm_manager+0x60>
ffffffffc0201c2a:	831fe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c2e:	86a2                	mv	a3,s0
ffffffffc0201c30:	00003617          	auipc	a2,0x3
ffffffffc0201c34:	18060613          	addi	a2,a2,384 # ffffffffc0204db0 <default_pmm_manager+0xe0>
ffffffffc0201c38:	07700593          	li	a1,119
ffffffffc0201c3c:	00003517          	auipc	a0,0x3
ffffffffc0201c40:	0f450513          	addi	a0,a0,244 # ffffffffc0204d30 <default_pmm_manager+0x60>
ffffffffc0201c44:	817fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c48 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c48:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c4a:	00003617          	auipc	a2,0x3
ffffffffc0201c4e:	18e60613          	addi	a2,a2,398 # ffffffffc0204dd8 <default_pmm_manager+0x108>
ffffffffc0201c52:	06900593          	li	a1,105
ffffffffc0201c56:	00003517          	auipc	a0,0x3
ffffffffc0201c5a:	0da50513          	addi	a0,a0,218 # ffffffffc0204d30 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201c5e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c60:	ffafe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c64 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c64:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c66:	00003617          	auipc	a2,0x3
ffffffffc0201c6a:	19260613          	addi	a2,a2,402 # ffffffffc0204df8 <default_pmm_manager+0x128>
ffffffffc0201c6e:	07f00593          	li	a1,127
ffffffffc0201c72:	00003517          	auipc	a0,0x3
ffffffffc0201c76:	0be50513          	addi	a0,a0,190 # ffffffffc0204d30 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201c7a:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c7c:	fdefe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c80 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c80:	100027f3          	csrr	a5,sstatus
ffffffffc0201c84:	8b89                	andi	a5,a5,2
ffffffffc0201c86:	e799                	bnez	a5,ffffffffc0201c94 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c88:	0000c797          	auipc	a5,0xc
ffffffffc0201c8c:	8387b783          	ld	a5,-1992(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201c90:	6f9c                	ld	a5,24(a5)
ffffffffc0201c92:	8782                	jr	a5
{
ffffffffc0201c94:	1141                	addi	sp,sp,-16
ffffffffc0201c96:	e406                	sd	ra,8(sp)
ffffffffc0201c98:	e022                	sd	s0,0(sp)
ffffffffc0201c9a:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201c9c:	c95fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ca0:	0000c797          	auipc	a5,0xc
ffffffffc0201ca4:	8207b783          	ld	a5,-2016(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ca8:	6f9c                	ld	a5,24(a5)
ffffffffc0201caa:	8522                	mv	a0,s0
ffffffffc0201cac:	9782                	jalr	a5
ffffffffc0201cae:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cb0:	c7bfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201cb4:	60a2                	ld	ra,8(sp)
ffffffffc0201cb6:	8522                	mv	a0,s0
ffffffffc0201cb8:	6402                	ld	s0,0(sp)
ffffffffc0201cba:	0141                	addi	sp,sp,16
ffffffffc0201cbc:	8082                	ret

ffffffffc0201cbe <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cbe:	100027f3          	csrr	a5,sstatus
ffffffffc0201cc2:	8b89                	andi	a5,a5,2
ffffffffc0201cc4:	e799                	bnez	a5,ffffffffc0201cd2 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201cc6:	0000b797          	auipc	a5,0xb
ffffffffc0201cca:	7fa7b783          	ld	a5,2042(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cce:	739c                	ld	a5,32(a5)
ffffffffc0201cd0:	8782                	jr	a5
{
ffffffffc0201cd2:	1101                	addi	sp,sp,-32
ffffffffc0201cd4:	ec06                	sd	ra,24(sp)
ffffffffc0201cd6:	e822                	sd	s0,16(sp)
ffffffffc0201cd8:	e426                	sd	s1,8(sp)
ffffffffc0201cda:	842a                	mv	s0,a0
ffffffffc0201cdc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201cde:	c53fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ce2:	0000b797          	auipc	a5,0xb
ffffffffc0201ce6:	7de7b783          	ld	a5,2014(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cea:	739c                	ld	a5,32(a5)
ffffffffc0201cec:	85a6                	mv	a1,s1
ffffffffc0201cee:	8522                	mv	a0,s0
ffffffffc0201cf0:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201cf2:	6442                	ld	s0,16(sp)
ffffffffc0201cf4:	60e2                	ld	ra,24(sp)
ffffffffc0201cf6:	64a2                	ld	s1,8(sp)
ffffffffc0201cf8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201cfa:	c31fe06f          	j	ffffffffc020092a <intr_enable>

ffffffffc0201cfe <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cfe:	100027f3          	csrr	a5,sstatus
ffffffffc0201d02:	8b89                	andi	a5,a5,2
ffffffffc0201d04:	e799                	bnez	a5,ffffffffc0201d12 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d06:	0000b797          	auipc	a5,0xb
ffffffffc0201d0a:	7ba7b783          	ld	a5,1978(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d0e:	779c                	ld	a5,40(a5)
ffffffffc0201d10:	8782                	jr	a5
{
ffffffffc0201d12:	1141                	addi	sp,sp,-16
ffffffffc0201d14:	e406                	sd	ra,8(sp)
ffffffffc0201d16:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201d18:	c19fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d1c:	0000b797          	auipc	a5,0xb
ffffffffc0201d20:	7a47b783          	ld	a5,1956(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d24:	779c                	ld	a5,40(a5)
ffffffffc0201d26:	9782                	jalr	a5
ffffffffc0201d28:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d2a:	c01fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d2e:	60a2                	ld	ra,8(sp)
ffffffffc0201d30:	8522                	mv	a0,s0
ffffffffc0201d32:	6402                	ld	s0,0(sp)
ffffffffc0201d34:	0141                	addi	sp,sp,16
ffffffffc0201d36:	8082                	ret

ffffffffc0201d38 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d38:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d3c:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201d40:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d42:	078e                	slli	a5,a5,0x3
{
ffffffffc0201d44:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d46:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d4a:	6094                	ld	a3,0(s1)
{
ffffffffc0201d4c:	f04a                	sd	s2,32(sp)
ffffffffc0201d4e:	ec4e                	sd	s3,24(sp)
ffffffffc0201d50:	e852                	sd	s4,16(sp)
ffffffffc0201d52:	fc06                	sd	ra,56(sp)
ffffffffc0201d54:	f822                	sd	s0,48(sp)
ffffffffc0201d56:	e456                	sd	s5,8(sp)
ffffffffc0201d58:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d5a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d5e:	892e                	mv	s2,a1
ffffffffc0201d60:	8a32                	mv	s4,a2
ffffffffc0201d62:	0000b997          	auipc	s3,0xb
ffffffffc0201d66:	74e98993          	addi	s3,s3,1870 # ffffffffc020d4b0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d6a:	efbd                	bnez	a5,ffffffffc0201de8 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d6c:	14060c63          	beqz	a2,ffffffffc0201ec4 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d70:	100027f3          	csrr	a5,sstatus
ffffffffc0201d74:	8b89                	andi	a5,a5,2
ffffffffc0201d76:	14079963          	bnez	a5,ffffffffc0201ec8 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d7a:	0000b797          	auipc	a5,0xb
ffffffffc0201d7e:	7467b783          	ld	a5,1862(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d82:	6f9c                	ld	a5,24(a5)
ffffffffc0201d84:	4505                	li	a0,1
ffffffffc0201d86:	9782                	jalr	a5
ffffffffc0201d88:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d8a:	12040d63          	beqz	s0,ffffffffc0201ec4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201d8e:	0000bb17          	auipc	s6,0xb
ffffffffc0201d92:	72ab0b13          	addi	s6,s6,1834 # ffffffffc020d4b8 <pages>
ffffffffc0201d96:	000b3503          	ld	a0,0(s6)
ffffffffc0201d9a:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d9e:	0000b997          	auipc	s3,0xb
ffffffffc0201da2:	71298993          	addi	s3,s3,1810 # ffffffffc020d4b0 <npage>
ffffffffc0201da6:	40a40533          	sub	a0,s0,a0
ffffffffc0201daa:	8519                	srai	a0,a0,0x6
ffffffffc0201dac:	9556                	add	a0,a0,s5
ffffffffc0201dae:	0009b703          	ld	a4,0(s3)
ffffffffc0201db2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201db6:	4685                	li	a3,1
ffffffffc0201db8:	c014                	sw	a3,0(s0)
ffffffffc0201dba:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dbc:	0532                	slli	a0,a0,0xc
ffffffffc0201dbe:	16e7f763          	bgeu	a5,a4,ffffffffc0201f2c <get_pte+0x1f4>
ffffffffc0201dc2:	0000b797          	auipc	a5,0xb
ffffffffc0201dc6:	7067b783          	ld	a5,1798(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201dca:	6605                	lui	a2,0x1
ffffffffc0201dcc:	4581                	li	a1,0
ffffffffc0201dce:	953e                	add	a0,a0,a5
ffffffffc0201dd0:	082020ef          	jal	ra,ffffffffc0203e52 <memset>
    return page - pages + nbase;
ffffffffc0201dd4:	000b3683          	ld	a3,0(s6)
ffffffffc0201dd8:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ddc:	8699                	srai	a3,a3,0x6
ffffffffc0201dde:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201de0:	06aa                	slli	a3,a3,0xa
ffffffffc0201de2:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201de6:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201de8:	77fd                	lui	a5,0xfffff
ffffffffc0201dea:	068a                	slli	a3,a3,0x2
ffffffffc0201dec:	0009b703          	ld	a4,0(s3)
ffffffffc0201df0:	8efd                	and	a3,a3,a5
ffffffffc0201df2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201df6:	10e7ff63          	bgeu	a5,a4,ffffffffc0201f14 <get_pte+0x1dc>
ffffffffc0201dfa:	0000ba97          	auipc	s5,0xb
ffffffffc0201dfe:	6cea8a93          	addi	s5,s5,1742 # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201e02:	000ab403          	ld	s0,0(s5)
ffffffffc0201e06:	01595793          	srli	a5,s2,0x15
ffffffffc0201e0a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e0e:	96a2                	add	a3,a3,s0
ffffffffc0201e10:	00379413          	slli	s0,a5,0x3
ffffffffc0201e14:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201e16:	6014                	ld	a3,0(s0)
ffffffffc0201e18:	0016f793          	andi	a5,a3,1
ffffffffc0201e1c:	ebad                	bnez	a5,ffffffffc0201e8e <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e1e:	0a0a0363          	beqz	s4,ffffffffc0201ec4 <get_pte+0x18c>
ffffffffc0201e22:	100027f3          	csrr	a5,sstatus
ffffffffc0201e26:	8b89                	andi	a5,a5,2
ffffffffc0201e28:	efcd                	bnez	a5,ffffffffc0201ee2 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e2a:	0000b797          	auipc	a5,0xb
ffffffffc0201e2e:	6967b783          	ld	a5,1686(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201e32:	6f9c                	ld	a5,24(a5)
ffffffffc0201e34:	4505                	li	a0,1
ffffffffc0201e36:	9782                	jalr	a5
ffffffffc0201e38:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e3a:	c4c9                	beqz	s1,ffffffffc0201ec4 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e3c:	0000bb17          	auipc	s6,0xb
ffffffffc0201e40:	67cb0b13          	addi	s6,s6,1660 # ffffffffc020d4b8 <pages>
ffffffffc0201e44:	000b3503          	ld	a0,0(s6)
ffffffffc0201e48:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e4c:	0009b703          	ld	a4,0(s3)
ffffffffc0201e50:	40a48533          	sub	a0,s1,a0
ffffffffc0201e54:	8519                	srai	a0,a0,0x6
ffffffffc0201e56:	9552                	add	a0,a0,s4
ffffffffc0201e58:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e5c:	4685                	li	a3,1
ffffffffc0201e5e:	c094                	sw	a3,0(s1)
ffffffffc0201e60:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e62:	0532                	slli	a0,a0,0xc
ffffffffc0201e64:	0ee7f163          	bgeu	a5,a4,ffffffffc0201f46 <get_pte+0x20e>
ffffffffc0201e68:	000ab783          	ld	a5,0(s5)
ffffffffc0201e6c:	6605                	lui	a2,0x1
ffffffffc0201e6e:	4581                	li	a1,0
ffffffffc0201e70:	953e                	add	a0,a0,a5
ffffffffc0201e72:	7e1010ef          	jal	ra,ffffffffc0203e52 <memset>
    return page - pages + nbase;
ffffffffc0201e76:	000b3683          	ld	a3,0(s6)
ffffffffc0201e7a:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e7e:	8699                	srai	a3,a3,0x6
ffffffffc0201e80:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e82:	06aa                	slli	a3,a3,0xa
ffffffffc0201e84:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e88:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e8a:	0009b703          	ld	a4,0(s3)
ffffffffc0201e8e:	068a                	slli	a3,a3,0x2
ffffffffc0201e90:	757d                	lui	a0,0xfffff
ffffffffc0201e92:	8ee9                	and	a3,a3,a0
ffffffffc0201e94:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e98:	06e7f263          	bgeu	a5,a4,ffffffffc0201efc <get_pte+0x1c4>
ffffffffc0201e9c:	000ab503          	ld	a0,0(s5)
ffffffffc0201ea0:	00c95913          	srli	s2,s2,0xc
ffffffffc0201ea4:	1ff97913          	andi	s2,s2,511
ffffffffc0201ea8:	96aa                	add	a3,a3,a0
ffffffffc0201eaa:	00391513          	slli	a0,s2,0x3
ffffffffc0201eae:	9536                	add	a0,a0,a3
}
ffffffffc0201eb0:	70e2                	ld	ra,56(sp)
ffffffffc0201eb2:	7442                	ld	s0,48(sp)
ffffffffc0201eb4:	74a2                	ld	s1,40(sp)
ffffffffc0201eb6:	7902                	ld	s2,32(sp)
ffffffffc0201eb8:	69e2                	ld	s3,24(sp)
ffffffffc0201eba:	6a42                	ld	s4,16(sp)
ffffffffc0201ebc:	6aa2                	ld	s5,8(sp)
ffffffffc0201ebe:	6b02                	ld	s6,0(sp)
ffffffffc0201ec0:	6121                	addi	sp,sp,64
ffffffffc0201ec2:	8082                	ret
            return NULL;
ffffffffc0201ec4:	4501                	li	a0,0
ffffffffc0201ec6:	b7ed                	j	ffffffffc0201eb0 <get_pte+0x178>
        intr_disable();
ffffffffc0201ec8:	a69fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ecc:	0000b797          	auipc	a5,0xb
ffffffffc0201ed0:	5f47b783          	ld	a5,1524(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ed4:	6f9c                	ld	a5,24(a5)
ffffffffc0201ed6:	4505                	li	a0,1
ffffffffc0201ed8:	9782                	jalr	a5
ffffffffc0201eda:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201edc:	a4ffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201ee0:	b56d                	j	ffffffffc0201d8a <get_pte+0x52>
        intr_disable();
ffffffffc0201ee2:	a4ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201ee6:	0000b797          	auipc	a5,0xb
ffffffffc0201eea:	5da7b783          	ld	a5,1498(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201eee:	6f9c                	ld	a5,24(a5)
ffffffffc0201ef0:	4505                	li	a0,1
ffffffffc0201ef2:	9782                	jalr	a5
ffffffffc0201ef4:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201ef6:	a35fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201efa:	b781                	j	ffffffffc0201e3a <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201efc:	00003617          	auipc	a2,0x3
ffffffffc0201f00:	e0c60613          	addi	a2,a2,-500 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc0201f04:	0fb00593          	li	a1,251
ffffffffc0201f08:	00003517          	auipc	a0,0x3
ffffffffc0201f0c:	f1850513          	addi	a0,a0,-232 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0201f10:	d4afe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f14:	00003617          	auipc	a2,0x3
ffffffffc0201f18:	df460613          	addi	a2,a2,-524 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc0201f1c:	0ee00593          	li	a1,238
ffffffffc0201f20:	00003517          	auipc	a0,0x3
ffffffffc0201f24:	f0050513          	addi	a0,a0,-256 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0201f28:	d32fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f2c:	86aa                	mv	a3,a0
ffffffffc0201f2e:	00003617          	auipc	a2,0x3
ffffffffc0201f32:	dda60613          	addi	a2,a2,-550 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc0201f36:	0eb00593          	li	a1,235
ffffffffc0201f3a:	00003517          	auipc	a0,0x3
ffffffffc0201f3e:	ee650513          	addi	a0,a0,-282 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0201f42:	d18fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f46:	86aa                	mv	a3,a0
ffffffffc0201f48:	00003617          	auipc	a2,0x3
ffffffffc0201f4c:	dc060613          	addi	a2,a2,-576 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc0201f50:	0f800593          	li	a1,248
ffffffffc0201f54:	00003517          	auipc	a0,0x3
ffffffffc0201f58:	ecc50513          	addi	a0,a0,-308 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0201f5c:	cfefe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201f60 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f60:	1141                	addi	sp,sp,-16
ffffffffc0201f62:	e022                	sd	s0,0(sp)
ffffffffc0201f64:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f66:	4601                	li	a2,0
{
ffffffffc0201f68:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f6a:	dcfff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f6e:	c011                	beqz	s0,ffffffffc0201f72 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f70:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f72:	c511                	beqz	a0,ffffffffc0201f7e <get_page+0x1e>
ffffffffc0201f74:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f76:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f78:	0017f713          	andi	a4,a5,1
ffffffffc0201f7c:	e709                	bnez	a4,ffffffffc0201f86 <get_page+0x26>
}
ffffffffc0201f7e:	60a2                	ld	ra,8(sp)
ffffffffc0201f80:	6402                	ld	s0,0(sp)
ffffffffc0201f82:	0141                	addi	sp,sp,16
ffffffffc0201f84:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f86:	078a                	slli	a5,a5,0x2
ffffffffc0201f88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f8a:	0000b717          	auipc	a4,0xb
ffffffffc0201f8e:	52673703          	ld	a4,1318(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201f92:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fb0 <get_page+0x50>
ffffffffc0201f96:	60a2                	ld	ra,8(sp)
ffffffffc0201f98:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201f9a:	fff80537          	lui	a0,0xfff80
ffffffffc0201f9e:	97aa                	add	a5,a5,a0
ffffffffc0201fa0:	079a                	slli	a5,a5,0x6
ffffffffc0201fa2:	0000b517          	auipc	a0,0xb
ffffffffc0201fa6:	51653503          	ld	a0,1302(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201faa:	953e                	add	a0,a0,a5
ffffffffc0201fac:	0141                	addi	sp,sp,16
ffffffffc0201fae:	8082                	ret
ffffffffc0201fb0:	c99ff0ef          	jal	ra,ffffffffc0201c48 <pa2page.part.0>

ffffffffc0201fb4 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fb4:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fb6:	4601                	li	a2,0
{
ffffffffc0201fb8:	ec26                	sd	s1,24(sp)
ffffffffc0201fba:	f406                	sd	ra,40(sp)
ffffffffc0201fbc:	f022                	sd	s0,32(sp)
ffffffffc0201fbe:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fc0:	d79ff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
    if (ptep != NULL)
ffffffffc0201fc4:	c511                	beqz	a0,ffffffffc0201fd0 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201fc6:	611c                	ld	a5,0(a0)
ffffffffc0201fc8:	842a                	mv	s0,a0
ffffffffc0201fca:	0017f713          	andi	a4,a5,1
ffffffffc0201fce:	e711                	bnez	a4,ffffffffc0201fda <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201fd0:	70a2                	ld	ra,40(sp)
ffffffffc0201fd2:	7402                	ld	s0,32(sp)
ffffffffc0201fd4:	64e2                	ld	s1,24(sp)
ffffffffc0201fd6:	6145                	addi	sp,sp,48
ffffffffc0201fd8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fda:	078a                	slli	a5,a5,0x2
ffffffffc0201fdc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fde:	0000b717          	auipc	a4,0xb
ffffffffc0201fe2:	4d273703          	ld	a4,1234(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201fe6:	06e7f363          	bgeu	a5,a4,ffffffffc020204c <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fea:	fff80537          	lui	a0,0xfff80
ffffffffc0201fee:	97aa                	add	a5,a5,a0
ffffffffc0201ff0:	079a                	slli	a5,a5,0x6
ffffffffc0201ff2:	0000b517          	auipc	a0,0xb
ffffffffc0201ff6:	4c653503          	ld	a0,1222(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201ffa:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201ffc:	411c                	lw	a5,0(a0)
ffffffffc0201ffe:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202002:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202004:	cb11                	beqz	a4,ffffffffc0202018 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202006:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020200a:	12048073          	sfence.vma	s1
}
ffffffffc020200e:	70a2                	ld	ra,40(sp)
ffffffffc0202010:	7402                	ld	s0,32(sp)
ffffffffc0202012:	64e2                	ld	s1,24(sp)
ffffffffc0202014:	6145                	addi	sp,sp,48
ffffffffc0202016:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202018:	100027f3          	csrr	a5,sstatus
ffffffffc020201c:	8b89                	andi	a5,a5,2
ffffffffc020201e:	eb89                	bnez	a5,ffffffffc0202030 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202020:	0000b797          	auipc	a5,0xb
ffffffffc0202024:	4a07b783          	ld	a5,1184(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202028:	739c                	ld	a5,32(a5)
ffffffffc020202a:	4585                	li	a1,1
ffffffffc020202c:	9782                	jalr	a5
    if (flag) {
ffffffffc020202e:	bfe1                	j	ffffffffc0202006 <page_remove+0x52>
        intr_disable();
ffffffffc0202030:	e42a                	sd	a0,8(sp)
ffffffffc0202032:	8fffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202036:	0000b797          	auipc	a5,0xb
ffffffffc020203a:	48a7b783          	ld	a5,1162(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020203e:	739c                	ld	a5,32(a5)
ffffffffc0202040:	6522                	ld	a0,8(sp)
ffffffffc0202042:	4585                	li	a1,1
ffffffffc0202044:	9782                	jalr	a5
        intr_enable();
ffffffffc0202046:	8e5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020204a:	bf75                	j	ffffffffc0202006 <page_remove+0x52>
ffffffffc020204c:	bfdff0ef          	jal	ra,ffffffffc0201c48 <pa2page.part.0>

ffffffffc0202050 <page_insert>:
{
ffffffffc0202050:	7139                	addi	sp,sp,-64
ffffffffc0202052:	e852                	sd	s4,16(sp)
ffffffffc0202054:	8a32                	mv	s4,a2
ffffffffc0202056:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202058:	4605                	li	a2,1
{
ffffffffc020205a:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020205c:	85d2                	mv	a1,s4
{
ffffffffc020205e:	f426                	sd	s1,40(sp)
ffffffffc0202060:	fc06                	sd	ra,56(sp)
ffffffffc0202062:	f04a                	sd	s2,32(sp)
ffffffffc0202064:	ec4e                	sd	s3,24(sp)
ffffffffc0202066:	e456                	sd	s5,8(sp)
ffffffffc0202068:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020206a:	ccfff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
    if (ptep == NULL)
ffffffffc020206e:	c961                	beqz	a0,ffffffffc020213e <page_insert+0xee>
    page->ref += 1;
ffffffffc0202070:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202072:	611c                	ld	a5,0(a0)
ffffffffc0202074:	89aa                	mv	s3,a0
ffffffffc0202076:	0016871b          	addiw	a4,a3,1
ffffffffc020207a:	c018                	sw	a4,0(s0)
ffffffffc020207c:	0017f713          	andi	a4,a5,1
ffffffffc0202080:	ef05                	bnez	a4,ffffffffc02020b8 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202082:	0000b717          	auipc	a4,0xb
ffffffffc0202086:	43673703          	ld	a4,1078(a4) # ffffffffc020d4b8 <pages>
ffffffffc020208a:	8c19                	sub	s0,s0,a4
ffffffffc020208c:	000807b7          	lui	a5,0x80
ffffffffc0202090:	8419                	srai	s0,s0,0x6
ffffffffc0202092:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202094:	042a                	slli	s0,s0,0xa
ffffffffc0202096:	8cc1                	or	s1,s1,s0
ffffffffc0202098:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020209c:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020a0:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02020a4:	4501                	li	a0,0
}
ffffffffc02020a6:	70e2                	ld	ra,56(sp)
ffffffffc02020a8:	7442                	ld	s0,48(sp)
ffffffffc02020aa:	74a2                	ld	s1,40(sp)
ffffffffc02020ac:	7902                	ld	s2,32(sp)
ffffffffc02020ae:	69e2                	ld	s3,24(sp)
ffffffffc02020b0:	6a42                	ld	s4,16(sp)
ffffffffc02020b2:	6aa2                	ld	s5,8(sp)
ffffffffc02020b4:	6121                	addi	sp,sp,64
ffffffffc02020b6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020b8:	078a                	slli	a5,a5,0x2
ffffffffc02020ba:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020bc:	0000b717          	auipc	a4,0xb
ffffffffc02020c0:	3f473703          	ld	a4,1012(a4) # ffffffffc020d4b0 <npage>
ffffffffc02020c4:	06e7ff63          	bgeu	a5,a4,ffffffffc0202142 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020c8:	0000ba97          	auipc	s5,0xb
ffffffffc02020cc:	3f0a8a93          	addi	s5,s5,1008 # ffffffffc020d4b8 <pages>
ffffffffc02020d0:	000ab703          	ld	a4,0(s5)
ffffffffc02020d4:	fff80937          	lui	s2,0xfff80
ffffffffc02020d8:	993e                	add	s2,s2,a5
ffffffffc02020da:	091a                	slli	s2,s2,0x6
ffffffffc02020dc:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02020de:	01240c63          	beq	s0,s2,ffffffffc02020f6 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02020e2:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc02020e6:	fff7869b          	addiw	a3,a5,-1
ffffffffc02020ea:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02020ee:	c691                	beqz	a3,ffffffffc02020fa <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020f0:	120a0073          	sfence.vma	s4
}
ffffffffc02020f4:	bf59                	j	ffffffffc020208a <page_insert+0x3a>
ffffffffc02020f6:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02020f8:	bf49                	j	ffffffffc020208a <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020fa:	100027f3          	csrr	a5,sstatus
ffffffffc02020fe:	8b89                	andi	a5,a5,2
ffffffffc0202100:	ef91                	bnez	a5,ffffffffc020211c <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202102:	0000b797          	auipc	a5,0xb
ffffffffc0202106:	3be7b783          	ld	a5,958(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc020210a:	739c                	ld	a5,32(a5)
ffffffffc020210c:	4585                	li	a1,1
ffffffffc020210e:	854a                	mv	a0,s2
ffffffffc0202110:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202112:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202116:	120a0073          	sfence.vma	s4
ffffffffc020211a:	bf85                	j	ffffffffc020208a <page_insert+0x3a>
        intr_disable();
ffffffffc020211c:	815fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202120:	0000b797          	auipc	a5,0xb
ffffffffc0202124:	3a07b783          	ld	a5,928(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202128:	739c                	ld	a5,32(a5)
ffffffffc020212a:	4585                	li	a1,1
ffffffffc020212c:	854a                	mv	a0,s2
ffffffffc020212e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202130:	ffafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202134:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202138:	120a0073          	sfence.vma	s4
ffffffffc020213c:	b7b9                	j	ffffffffc020208a <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020213e:	5571                	li	a0,-4
ffffffffc0202140:	b79d                	j	ffffffffc02020a6 <page_insert+0x56>
ffffffffc0202142:	b07ff0ef          	jal	ra,ffffffffc0201c48 <pa2page.part.0>

ffffffffc0202146 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202146:	00003797          	auipc	a5,0x3
ffffffffc020214a:	b8a78793          	addi	a5,a5,-1142 # ffffffffc0204cd0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020214e:	638c                	ld	a1,0(a5)
{
ffffffffc0202150:	7159                	addi	sp,sp,-112
ffffffffc0202152:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202154:	00003517          	auipc	a0,0x3
ffffffffc0202158:	cdc50513          	addi	a0,a0,-804 # ffffffffc0204e30 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc020215c:	0000bb17          	auipc	s6,0xb
ffffffffc0202160:	364b0b13          	addi	s6,s6,868 # ffffffffc020d4c0 <pmm_manager>
{
ffffffffc0202164:	f486                	sd	ra,104(sp)
ffffffffc0202166:	e8ca                	sd	s2,80(sp)
ffffffffc0202168:	e4ce                	sd	s3,72(sp)
ffffffffc020216a:	f0a2                	sd	s0,96(sp)
ffffffffc020216c:	eca6                	sd	s1,88(sp)
ffffffffc020216e:	e0d2                	sd	s4,64(sp)
ffffffffc0202170:	fc56                	sd	s5,56(sp)
ffffffffc0202172:	f45e                	sd	s7,40(sp)
ffffffffc0202174:	f062                	sd	s8,32(sp)
ffffffffc0202176:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202178:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020217c:	818fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202180:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202184:	0000b997          	auipc	s3,0xb
ffffffffc0202188:	34498993          	addi	s3,s3,836 # ffffffffc020d4c8 <va_pa_offset>
    pmm_manager->init();
ffffffffc020218c:	679c                	ld	a5,8(a5)
ffffffffc020218e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202190:	57f5                	li	a5,-3
ffffffffc0202192:	07fa                	slli	a5,a5,0x1e
ffffffffc0202194:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202198:	f7efe0ef          	jal	ra,ffffffffc0200916 <get_memory_base>
ffffffffc020219c:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020219e:	f82fe0ef          	jal	ra,ffffffffc0200920 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021a2:	200505e3          	beqz	a0,ffffffffc0202bac <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021a6:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021a8:	00003517          	auipc	a0,0x3
ffffffffc02021ac:	cc050513          	addi	a0,a0,-832 # ffffffffc0204e68 <default_pmm_manager+0x198>
ffffffffc02021b0:	fe5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021b4:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021b8:	fff40693          	addi	a3,s0,-1
ffffffffc02021bc:	864a                	mv	a2,s2
ffffffffc02021be:	85a6                	mv	a1,s1
ffffffffc02021c0:	00003517          	auipc	a0,0x3
ffffffffc02021c4:	cc050513          	addi	a0,a0,-832 # ffffffffc0204e80 <default_pmm_manager+0x1b0>
ffffffffc02021c8:	fcdfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02021cc:	c8000737          	lui	a4,0xc8000
ffffffffc02021d0:	87a2                	mv	a5,s0
ffffffffc02021d2:	54876163          	bltu	a4,s0,ffffffffc0202714 <pmm_init+0x5ce>
ffffffffc02021d6:	757d                	lui	a0,0xfffff
ffffffffc02021d8:	0000c617          	auipc	a2,0xc
ffffffffc02021dc:	31360613          	addi	a2,a2,787 # ffffffffc020e4eb <end+0xfff>
ffffffffc02021e0:	8e69                	and	a2,a2,a0
ffffffffc02021e2:	0000b497          	auipc	s1,0xb
ffffffffc02021e6:	2ce48493          	addi	s1,s1,718 # ffffffffc020d4b0 <npage>
ffffffffc02021ea:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021ee:	0000bb97          	auipc	s7,0xb
ffffffffc02021f2:	2cab8b93          	addi	s7,s7,714 # ffffffffc020d4b8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02021f6:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021f8:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021fc:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202200:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202202:	02f50863          	beq	a0,a5,ffffffffc0202232 <pmm_init+0xec>
ffffffffc0202206:	4781                	li	a5,0
ffffffffc0202208:	4585                	li	a1,1
ffffffffc020220a:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc020220e:	00679513          	slli	a0,a5,0x6
ffffffffc0202212:	9532                	add	a0,a0,a2
ffffffffc0202214:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc0202218:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020221c:	6088                	ld	a0,0(s1)
ffffffffc020221e:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202220:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202224:	00d50733          	add	a4,a0,a3
ffffffffc0202228:	fee7e3e3          	bltu	a5,a4,ffffffffc020220e <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020222c:	071a                	slli	a4,a4,0x6
ffffffffc020222e:	00e606b3          	add	a3,a2,a4
ffffffffc0202232:	c02007b7          	lui	a5,0xc0200
ffffffffc0202236:	2ef6ece3          	bltu	a3,a5,ffffffffc0202d2e <pmm_init+0xbe8>
ffffffffc020223a:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020223e:	77fd                	lui	a5,0xfffff
ffffffffc0202240:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202242:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202244:	5086eb63          	bltu	a3,s0,ffffffffc020275a <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202248:	00003517          	auipc	a0,0x3
ffffffffc020224c:	c6050513          	addi	a0,a0,-928 # ffffffffc0204ea8 <default_pmm_manager+0x1d8>
ffffffffc0202250:	f45fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202254:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202258:	0000b917          	auipc	s2,0xb
ffffffffc020225c:	25090913          	addi	s2,s2,592 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202260:	7b9c                	ld	a5,48(a5)
ffffffffc0202262:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202264:	00003517          	auipc	a0,0x3
ffffffffc0202268:	c5c50513          	addi	a0,a0,-932 # ffffffffc0204ec0 <default_pmm_manager+0x1f0>
ffffffffc020226c:	f29fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202270:	00006697          	auipc	a3,0x6
ffffffffc0202274:	d9068693          	addi	a3,a3,-624 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202278:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020227c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202280:	28f6ebe3          	bltu	a3,a5,ffffffffc0202d16 <pmm_init+0xbd0>
ffffffffc0202284:	0009b783          	ld	a5,0(s3)
ffffffffc0202288:	8e9d                	sub	a3,a3,a5
ffffffffc020228a:	0000b797          	auipc	a5,0xb
ffffffffc020228e:	20d7bb23          	sd	a3,534(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202292:	100027f3          	csrr	a5,sstatus
ffffffffc0202296:	8b89                	andi	a5,a5,2
ffffffffc0202298:	4a079763          	bnez	a5,ffffffffc0202746 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc020229c:	000b3783          	ld	a5,0(s6)
ffffffffc02022a0:	779c                	ld	a5,40(a5)
ffffffffc02022a2:	9782                	jalr	a5
ffffffffc02022a4:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022a6:	6098                	ld	a4,0(s1)
ffffffffc02022a8:	c80007b7          	lui	a5,0xc8000
ffffffffc02022ac:	83b1                	srli	a5,a5,0xc
ffffffffc02022ae:	66e7e363          	bltu	a5,a4,ffffffffc0202914 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022b2:	00093503          	ld	a0,0(s2)
ffffffffc02022b6:	62050f63          	beqz	a0,ffffffffc02028f4 <pmm_init+0x7ae>
ffffffffc02022ba:	03451793          	slli	a5,a0,0x34
ffffffffc02022be:	62079b63          	bnez	a5,ffffffffc02028f4 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022c2:	4601                	li	a2,0
ffffffffc02022c4:	4581                	li	a1,0
ffffffffc02022c6:	c9bff0ef          	jal	ra,ffffffffc0201f60 <get_page>
ffffffffc02022ca:	60051563          	bnez	a0,ffffffffc02028d4 <pmm_init+0x78e>
ffffffffc02022ce:	100027f3          	csrr	a5,sstatus
ffffffffc02022d2:	8b89                	andi	a5,a5,2
ffffffffc02022d4:	44079e63          	bnez	a5,ffffffffc0202730 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022d8:	000b3783          	ld	a5,0(s6)
ffffffffc02022dc:	4505                	li	a0,1
ffffffffc02022de:	6f9c                	ld	a5,24(a5)
ffffffffc02022e0:	9782                	jalr	a5
ffffffffc02022e2:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022e4:	00093503          	ld	a0,0(s2)
ffffffffc02022e8:	4681                	li	a3,0
ffffffffc02022ea:	4601                	li	a2,0
ffffffffc02022ec:	85d2                	mv	a1,s4
ffffffffc02022ee:	d63ff0ef          	jal	ra,ffffffffc0202050 <page_insert>
ffffffffc02022f2:	26051ae3          	bnez	a0,ffffffffc0202d66 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02022f6:	00093503          	ld	a0,0(s2)
ffffffffc02022fa:	4601                	li	a2,0
ffffffffc02022fc:	4581                	li	a1,0
ffffffffc02022fe:	a3bff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
ffffffffc0202302:	240502e3          	beqz	a0,ffffffffc0202d46 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202306:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202308:	0017f713          	andi	a4,a5,1
ffffffffc020230c:	5a070263          	beqz	a4,ffffffffc02028b0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202310:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202312:	078a                	slli	a5,a5,0x2
ffffffffc0202314:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202316:	58e7fb63          	bgeu	a5,a4,ffffffffc02028ac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020231a:	000bb683          	ld	a3,0(s7)
ffffffffc020231e:	fff80637          	lui	a2,0xfff80
ffffffffc0202322:	97b2                	add	a5,a5,a2
ffffffffc0202324:	079a                	slli	a5,a5,0x6
ffffffffc0202326:	97b6                	add	a5,a5,a3
ffffffffc0202328:	14fa17e3          	bne	s4,a5,ffffffffc0202c76 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc020232c:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0202330:	4785                	li	a5,1
ffffffffc0202332:	12f692e3          	bne	a3,a5,ffffffffc0202c56 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202336:	00093503          	ld	a0,0(s2)
ffffffffc020233a:	77fd                	lui	a5,0xfffff
ffffffffc020233c:	6114                	ld	a3,0(a0)
ffffffffc020233e:	068a                	slli	a3,a3,0x2
ffffffffc0202340:	8efd                	and	a3,a3,a5
ffffffffc0202342:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202346:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202c3e <pmm_init+0xaf8>
ffffffffc020234a:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020234e:	96e2                	add	a3,a3,s8
ffffffffc0202350:	0006ba83          	ld	s5,0(a3)
ffffffffc0202354:	0a8a                	slli	s5,s5,0x2
ffffffffc0202356:	00fafab3          	and	s5,s5,a5
ffffffffc020235a:	00cad793          	srli	a5,s5,0xc
ffffffffc020235e:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202c24 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202362:	4601                	li	a2,0
ffffffffc0202364:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202366:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202368:	9d1ff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020236c:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020236e:	55551363          	bne	a0,s5,ffffffffc02028b4 <pmm_init+0x76e>
ffffffffc0202372:	100027f3          	csrr	a5,sstatus
ffffffffc0202376:	8b89                	andi	a5,a5,2
ffffffffc0202378:	3a079163          	bnez	a5,ffffffffc020271a <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020237c:	000b3783          	ld	a5,0(s6)
ffffffffc0202380:	4505                	li	a0,1
ffffffffc0202382:	6f9c                	ld	a5,24(a5)
ffffffffc0202384:	9782                	jalr	a5
ffffffffc0202386:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202388:	00093503          	ld	a0,0(s2)
ffffffffc020238c:	46d1                	li	a3,20
ffffffffc020238e:	6605                	lui	a2,0x1
ffffffffc0202390:	85e2                	mv	a1,s8
ffffffffc0202392:	cbfff0ef          	jal	ra,ffffffffc0202050 <page_insert>
ffffffffc0202396:	060517e3          	bnez	a0,ffffffffc0202c04 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020239a:	00093503          	ld	a0,0(s2)
ffffffffc020239e:	4601                	li	a2,0
ffffffffc02023a0:	6585                	lui	a1,0x1
ffffffffc02023a2:	997ff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
ffffffffc02023a6:	02050fe3          	beqz	a0,ffffffffc0202be4 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02023aa:	611c                	ld	a5,0(a0)
ffffffffc02023ac:	0107f713          	andi	a4,a5,16
ffffffffc02023b0:	7c070e63          	beqz	a4,ffffffffc0202b8c <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02023b4:	8b91                	andi	a5,a5,4
ffffffffc02023b6:	7a078b63          	beqz	a5,ffffffffc0202b6c <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023ba:	00093503          	ld	a0,0(s2)
ffffffffc02023be:	611c                	ld	a5,0(a0)
ffffffffc02023c0:	8bc1                	andi	a5,a5,16
ffffffffc02023c2:	78078563          	beqz	a5,ffffffffc0202b4c <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02023c6:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02023ca:	4785                	li	a5,1
ffffffffc02023cc:	76f71063          	bne	a4,a5,ffffffffc0202b2c <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023d0:	4681                	li	a3,0
ffffffffc02023d2:	6605                	lui	a2,0x1
ffffffffc02023d4:	85d2                	mv	a1,s4
ffffffffc02023d6:	c7bff0ef          	jal	ra,ffffffffc0202050 <page_insert>
ffffffffc02023da:	72051963          	bnez	a0,ffffffffc0202b0c <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02023de:	000a2703          	lw	a4,0(s4)
ffffffffc02023e2:	4789                	li	a5,2
ffffffffc02023e4:	70f71463          	bne	a4,a5,ffffffffc0202aec <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02023e8:	000c2783          	lw	a5,0(s8)
ffffffffc02023ec:	6e079063          	bnez	a5,ffffffffc0202acc <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023f0:	00093503          	ld	a0,0(s2)
ffffffffc02023f4:	4601                	li	a2,0
ffffffffc02023f6:	6585                	lui	a1,0x1
ffffffffc02023f8:	941ff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
ffffffffc02023fc:	6a050863          	beqz	a0,ffffffffc0202aac <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202400:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202402:	00177793          	andi	a5,a4,1
ffffffffc0202406:	4a078563          	beqz	a5,ffffffffc02028b0 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020240a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020240c:	00271793          	slli	a5,a4,0x2
ffffffffc0202410:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202412:	48d7fd63          	bgeu	a5,a3,ffffffffc02028ac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202416:	000bb683          	ld	a3,0(s7)
ffffffffc020241a:	fff80ab7          	lui	s5,0xfff80
ffffffffc020241e:	97d6                	add	a5,a5,s5
ffffffffc0202420:	079a                	slli	a5,a5,0x6
ffffffffc0202422:	97b6                	add	a5,a5,a3
ffffffffc0202424:	66fa1463          	bne	s4,a5,ffffffffc0202a8c <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202428:	8b41                	andi	a4,a4,16
ffffffffc020242a:	64071163          	bnez	a4,ffffffffc0202a6c <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc020242e:	00093503          	ld	a0,0(s2)
ffffffffc0202432:	4581                	li	a1,0
ffffffffc0202434:	b81ff0ef          	jal	ra,ffffffffc0201fb4 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202438:	000a2c83          	lw	s9,0(s4)
ffffffffc020243c:	4785                	li	a5,1
ffffffffc020243e:	60fc9763          	bne	s9,a5,ffffffffc0202a4c <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202442:	000c2783          	lw	a5,0(s8)
ffffffffc0202446:	5e079363          	bnez	a5,ffffffffc0202a2c <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020244a:	00093503          	ld	a0,0(s2)
ffffffffc020244e:	6585                	lui	a1,0x1
ffffffffc0202450:	b65ff0ef          	jal	ra,ffffffffc0201fb4 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202454:	000a2783          	lw	a5,0(s4)
ffffffffc0202458:	52079a63          	bnez	a5,ffffffffc020298c <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc020245c:	000c2783          	lw	a5,0(s8)
ffffffffc0202460:	50079663          	bnez	a5,ffffffffc020296c <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202464:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202468:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020246a:	000a3683          	ld	a3,0(s4)
ffffffffc020246e:	068a                	slli	a3,a3,0x2
ffffffffc0202470:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202472:	42b6fd63          	bgeu	a3,a1,ffffffffc02028ac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202476:	000bb503          	ld	a0,0(s7)
ffffffffc020247a:	96d6                	add	a3,a3,s5
ffffffffc020247c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020247e:	00d507b3          	add	a5,a0,a3
ffffffffc0202482:	439c                	lw	a5,0(a5)
ffffffffc0202484:	4d979463          	bne	a5,s9,ffffffffc020294c <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202488:	8699                	srai	a3,a3,0x6
ffffffffc020248a:	00080637          	lui	a2,0x80
ffffffffc020248e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202490:	00c69713          	slli	a4,a3,0xc
ffffffffc0202494:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202496:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202498:	48b77e63          	bgeu	a4,a1,ffffffffc0202934 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020249c:	0009b703          	ld	a4,0(s3)
ffffffffc02024a0:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02024a2:	629c                	ld	a5,0(a3)
ffffffffc02024a4:	078a                	slli	a5,a5,0x2
ffffffffc02024a6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024a8:	40b7f263          	bgeu	a5,a1,ffffffffc02028ac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ac:	8f91                	sub	a5,a5,a2
ffffffffc02024ae:	079a                	slli	a5,a5,0x6
ffffffffc02024b0:	953e                	add	a0,a0,a5
ffffffffc02024b2:	100027f3          	csrr	a5,sstatus
ffffffffc02024b6:	8b89                	andi	a5,a5,2
ffffffffc02024b8:	30079963          	bnez	a5,ffffffffc02027ca <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02024bc:	000b3783          	ld	a5,0(s6)
ffffffffc02024c0:	4585                	li	a1,1
ffffffffc02024c2:	739c                	ld	a5,32(a5)
ffffffffc02024c4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024ca:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024cc:	078a                	slli	a5,a5,0x2
ffffffffc02024ce:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024d0:	3ce7fe63          	bgeu	a5,a4,ffffffffc02028ac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024d4:	000bb503          	ld	a0,0(s7)
ffffffffc02024d8:	fff80737          	lui	a4,0xfff80
ffffffffc02024dc:	97ba                	add	a5,a5,a4
ffffffffc02024de:	079a                	slli	a5,a5,0x6
ffffffffc02024e0:	953e                	add	a0,a0,a5
ffffffffc02024e2:	100027f3          	csrr	a5,sstatus
ffffffffc02024e6:	8b89                	andi	a5,a5,2
ffffffffc02024e8:	2c079563          	bnez	a5,ffffffffc02027b2 <pmm_init+0x66c>
ffffffffc02024ec:	000b3783          	ld	a5,0(s6)
ffffffffc02024f0:	4585                	li	a1,1
ffffffffc02024f2:	739c                	ld	a5,32(a5)
ffffffffc02024f4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02024f6:	00093783          	ld	a5,0(s2)
ffffffffc02024fa:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc02024fe:	12000073          	sfence.vma
ffffffffc0202502:	100027f3          	csrr	a5,sstatus
ffffffffc0202506:	8b89                	andi	a5,a5,2
ffffffffc0202508:	28079b63          	bnez	a5,ffffffffc020279e <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc020250c:	000b3783          	ld	a5,0(s6)
ffffffffc0202510:	779c                	ld	a5,40(a5)
ffffffffc0202512:	9782                	jalr	a5
ffffffffc0202514:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202516:	4b441b63          	bne	s0,s4,ffffffffc02029cc <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020251a:	00003517          	auipc	a0,0x3
ffffffffc020251e:	cce50513          	addi	a0,a0,-818 # ffffffffc02051e8 <default_pmm_manager+0x518>
ffffffffc0202522:	c73fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202526:	100027f3          	csrr	a5,sstatus
ffffffffc020252a:	8b89                	andi	a5,a5,2
ffffffffc020252c:	24079f63          	bnez	a5,ffffffffc020278a <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202530:	000b3783          	ld	a5,0(s6)
ffffffffc0202534:	779c                	ld	a5,40(a5)
ffffffffc0202536:	9782                	jalr	a5
ffffffffc0202538:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020253a:	6098                	ld	a4,0(s1)
ffffffffc020253c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202540:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202542:	00c71793          	slli	a5,a4,0xc
ffffffffc0202546:	6a05                	lui	s4,0x1
ffffffffc0202548:	02f47c63          	bgeu	s0,a5,ffffffffc0202580 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020254c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202550:	00093503          	ld	a0,0(s2)
ffffffffc0202554:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202852 <pmm_init+0x70c>
ffffffffc0202558:	0009b583          	ld	a1,0(s3)
ffffffffc020255c:	4601                	li	a2,0
ffffffffc020255e:	95a2                	add	a1,a1,s0
ffffffffc0202560:	fd8ff0ef          	jal	ra,ffffffffc0201d38 <get_pte>
ffffffffc0202564:	32050463          	beqz	a0,ffffffffc020288c <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202568:	611c                	ld	a5,0(a0)
ffffffffc020256a:	078a                	slli	a5,a5,0x2
ffffffffc020256c:	0157f7b3          	and	a5,a5,s5
ffffffffc0202570:	2e879e63          	bne	a5,s0,ffffffffc020286c <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202574:	6098                	ld	a4,0(s1)
ffffffffc0202576:	9452                	add	s0,s0,s4
ffffffffc0202578:	00c71793          	slli	a5,a4,0xc
ffffffffc020257c:	fcf468e3          	bltu	s0,a5,ffffffffc020254c <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202580:	00093783          	ld	a5,0(s2)
ffffffffc0202584:	639c                	ld	a5,0(a5)
ffffffffc0202586:	42079363          	bnez	a5,ffffffffc02029ac <pmm_init+0x866>
ffffffffc020258a:	100027f3          	csrr	a5,sstatus
ffffffffc020258e:	8b89                	andi	a5,a5,2
ffffffffc0202590:	24079963          	bnez	a5,ffffffffc02027e2 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202594:	000b3783          	ld	a5,0(s6)
ffffffffc0202598:	4505                	li	a0,1
ffffffffc020259a:	6f9c                	ld	a5,24(a5)
ffffffffc020259c:	9782                	jalr	a5
ffffffffc020259e:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025a0:	00093503          	ld	a0,0(s2)
ffffffffc02025a4:	4699                	li	a3,6
ffffffffc02025a6:	10000613          	li	a2,256
ffffffffc02025aa:	85d2                	mv	a1,s4
ffffffffc02025ac:	aa5ff0ef          	jal	ra,ffffffffc0202050 <page_insert>
ffffffffc02025b0:	44051e63          	bnez	a0,ffffffffc0202a0c <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc02025b4:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02025b8:	4785                	li	a5,1
ffffffffc02025ba:	42f71963          	bne	a4,a5,ffffffffc02029ec <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025be:	00093503          	ld	a0,0(s2)
ffffffffc02025c2:	6405                	lui	s0,0x1
ffffffffc02025c4:	4699                	li	a3,6
ffffffffc02025c6:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025ca:	85d2                	mv	a1,s4
ffffffffc02025cc:	a85ff0ef          	jal	ra,ffffffffc0202050 <page_insert>
ffffffffc02025d0:	72051363          	bnez	a0,ffffffffc0202cf6 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc02025d4:	000a2703          	lw	a4,0(s4)
ffffffffc02025d8:	4789                	li	a5,2
ffffffffc02025da:	6ef71e63          	bne	a4,a5,ffffffffc0202cd6 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025de:	00003597          	auipc	a1,0x3
ffffffffc02025e2:	d5258593          	addi	a1,a1,-686 # ffffffffc0205330 <default_pmm_manager+0x660>
ffffffffc02025e6:	10000513          	li	a0,256
ffffffffc02025ea:	7fc010ef          	jal	ra,ffffffffc0203de6 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025ee:	10040593          	addi	a1,s0,256
ffffffffc02025f2:	10000513          	li	a0,256
ffffffffc02025f6:	003010ef          	jal	ra,ffffffffc0203df8 <strcmp>
ffffffffc02025fa:	6a051e63          	bnez	a0,ffffffffc0202cb6 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc02025fe:	000bb683          	ld	a3,0(s7)
ffffffffc0202602:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202606:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202608:	40da06b3          	sub	a3,s4,a3
ffffffffc020260c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020260e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202610:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202612:	8031                	srli	s0,s0,0xc
ffffffffc0202614:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202618:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020261a:	30f77d63          	bgeu	a4,a5,ffffffffc0202934 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020261e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202622:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202626:	96be                	add	a3,a3,a5
ffffffffc0202628:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020262c:	784010ef          	jal	ra,ffffffffc0203db0 <strlen>
ffffffffc0202630:	66051363          	bnez	a0,ffffffffc0202c96 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202634:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202638:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020263a:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc020263e:	068a                	slli	a3,a3,0x2
ffffffffc0202640:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202642:	26f6f563          	bgeu	a3,a5,ffffffffc02028ac <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202646:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202648:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020264a:	2ef47563          	bgeu	s0,a5,ffffffffc0202934 <pmm_init+0x7ee>
ffffffffc020264e:	0009b403          	ld	s0,0(s3)
ffffffffc0202652:	9436                	add	s0,s0,a3
ffffffffc0202654:	100027f3          	csrr	a5,sstatus
ffffffffc0202658:	8b89                	andi	a5,a5,2
ffffffffc020265a:	1e079163          	bnez	a5,ffffffffc020283c <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc020265e:	000b3783          	ld	a5,0(s6)
ffffffffc0202662:	4585                	li	a1,1
ffffffffc0202664:	8552                	mv	a0,s4
ffffffffc0202666:	739c                	ld	a5,32(a5)
ffffffffc0202668:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020266a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc020266c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020266e:	078a                	slli	a5,a5,0x2
ffffffffc0202670:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202672:	22e7fd63          	bgeu	a5,a4,ffffffffc02028ac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202676:	000bb503          	ld	a0,0(s7)
ffffffffc020267a:	fff80737          	lui	a4,0xfff80
ffffffffc020267e:	97ba                	add	a5,a5,a4
ffffffffc0202680:	079a                	slli	a5,a5,0x6
ffffffffc0202682:	953e                	add	a0,a0,a5
ffffffffc0202684:	100027f3          	csrr	a5,sstatus
ffffffffc0202688:	8b89                	andi	a5,a5,2
ffffffffc020268a:	18079d63          	bnez	a5,ffffffffc0202824 <pmm_init+0x6de>
ffffffffc020268e:	000b3783          	ld	a5,0(s6)
ffffffffc0202692:	4585                	li	a1,1
ffffffffc0202694:	739c                	ld	a5,32(a5)
ffffffffc0202696:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202698:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc020269c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020269e:	078a                	slli	a5,a5,0x2
ffffffffc02026a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026a2:	20e7f563          	bgeu	a5,a4,ffffffffc02028ac <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02026a6:	000bb503          	ld	a0,0(s7)
ffffffffc02026aa:	fff80737          	lui	a4,0xfff80
ffffffffc02026ae:	97ba                	add	a5,a5,a4
ffffffffc02026b0:	079a                	slli	a5,a5,0x6
ffffffffc02026b2:	953e                	add	a0,a0,a5
ffffffffc02026b4:	100027f3          	csrr	a5,sstatus
ffffffffc02026b8:	8b89                	andi	a5,a5,2
ffffffffc02026ba:	14079963          	bnez	a5,ffffffffc020280c <pmm_init+0x6c6>
ffffffffc02026be:	000b3783          	ld	a5,0(s6)
ffffffffc02026c2:	4585                	li	a1,1
ffffffffc02026c4:	739c                	ld	a5,32(a5)
ffffffffc02026c6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026c8:	00093783          	ld	a5,0(s2)
ffffffffc02026cc:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026d0:	12000073          	sfence.vma
ffffffffc02026d4:	100027f3          	csrr	a5,sstatus
ffffffffc02026d8:	8b89                	andi	a5,a5,2
ffffffffc02026da:	10079f63          	bnez	a5,ffffffffc02027f8 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026de:	000b3783          	ld	a5,0(s6)
ffffffffc02026e2:	779c                	ld	a5,40(a5)
ffffffffc02026e4:	9782                	jalr	a5
ffffffffc02026e6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026e8:	4c8c1e63          	bne	s8,s0,ffffffffc0202bc4 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026ec:	00003517          	auipc	a0,0x3
ffffffffc02026f0:	cbc50513          	addi	a0,a0,-836 # ffffffffc02053a8 <default_pmm_manager+0x6d8>
ffffffffc02026f4:	aa1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02026f8:	7406                	ld	s0,96(sp)
ffffffffc02026fa:	70a6                	ld	ra,104(sp)
ffffffffc02026fc:	64e6                	ld	s1,88(sp)
ffffffffc02026fe:	6946                	ld	s2,80(sp)
ffffffffc0202700:	69a6                	ld	s3,72(sp)
ffffffffc0202702:	6a06                	ld	s4,64(sp)
ffffffffc0202704:	7ae2                	ld	s5,56(sp)
ffffffffc0202706:	7b42                	ld	s6,48(sp)
ffffffffc0202708:	7ba2                	ld	s7,40(sp)
ffffffffc020270a:	7c02                	ld	s8,32(sp)
ffffffffc020270c:	6ce2                	ld	s9,24(sp)
ffffffffc020270e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202710:	b72ff06f          	j	ffffffffc0201a82 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202714:	c80007b7          	lui	a5,0xc8000
ffffffffc0202718:	bc7d                	j	ffffffffc02021d6 <pmm_init+0x90>
        intr_disable();
ffffffffc020271a:	a16fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020271e:	000b3783          	ld	a5,0(s6)
ffffffffc0202722:	4505                	li	a0,1
ffffffffc0202724:	6f9c                	ld	a5,24(a5)
ffffffffc0202726:	9782                	jalr	a5
ffffffffc0202728:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020272a:	a00fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020272e:	b9a9                	j	ffffffffc0202388 <pmm_init+0x242>
        intr_disable();
ffffffffc0202730:	a00fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202734:	000b3783          	ld	a5,0(s6)
ffffffffc0202738:	4505                	li	a0,1
ffffffffc020273a:	6f9c                	ld	a5,24(a5)
ffffffffc020273c:	9782                	jalr	a5
ffffffffc020273e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202740:	9eafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202744:	b645                	j	ffffffffc02022e4 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202746:	9eafe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020274a:	000b3783          	ld	a5,0(s6)
ffffffffc020274e:	779c                	ld	a5,40(a5)
ffffffffc0202750:	9782                	jalr	a5
ffffffffc0202752:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202754:	9d6fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202758:	b6b9                	j	ffffffffc02022a6 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020275a:	6705                	lui	a4,0x1
ffffffffc020275c:	177d                	addi	a4,a4,-1
ffffffffc020275e:	96ba                	add	a3,a3,a4
ffffffffc0202760:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202762:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202766:	14a77363          	bgeu	a4,a0,ffffffffc02028ac <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc020276a:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc020276e:	fff80537          	lui	a0,0xfff80
ffffffffc0202772:	972a                	add	a4,a4,a0
ffffffffc0202774:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202776:	8c1d                	sub	s0,s0,a5
ffffffffc0202778:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020277c:	00c45593          	srli	a1,s0,0xc
ffffffffc0202780:	9532                	add	a0,a0,a2
ffffffffc0202782:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202784:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202788:	b4c1                	j	ffffffffc0202248 <pmm_init+0x102>
        intr_disable();
ffffffffc020278a:	9a6fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020278e:	000b3783          	ld	a5,0(s6)
ffffffffc0202792:	779c                	ld	a5,40(a5)
ffffffffc0202794:	9782                	jalr	a5
ffffffffc0202796:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202798:	992fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020279c:	bb79                	j	ffffffffc020253a <pmm_init+0x3f4>
        intr_disable();
ffffffffc020279e:	992fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027a2:	000b3783          	ld	a5,0(s6)
ffffffffc02027a6:	779c                	ld	a5,40(a5)
ffffffffc02027a8:	9782                	jalr	a5
ffffffffc02027aa:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027ac:	97efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027b0:	b39d                	j	ffffffffc0202516 <pmm_init+0x3d0>
ffffffffc02027b2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027b4:	97cfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027b8:	000b3783          	ld	a5,0(s6)
ffffffffc02027bc:	6522                	ld	a0,8(sp)
ffffffffc02027be:	4585                	li	a1,1
ffffffffc02027c0:	739c                	ld	a5,32(a5)
ffffffffc02027c2:	9782                	jalr	a5
        intr_enable();
ffffffffc02027c4:	966fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027c8:	b33d                	j	ffffffffc02024f6 <pmm_init+0x3b0>
ffffffffc02027ca:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027cc:	964fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027d0:	000b3783          	ld	a5,0(s6)
ffffffffc02027d4:	6522                	ld	a0,8(sp)
ffffffffc02027d6:	4585                	li	a1,1
ffffffffc02027d8:	739c                	ld	a5,32(a5)
ffffffffc02027da:	9782                	jalr	a5
        intr_enable();
ffffffffc02027dc:	94efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027e0:	b1dd                	j	ffffffffc02024c6 <pmm_init+0x380>
        intr_disable();
ffffffffc02027e2:	94efe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027e6:	000b3783          	ld	a5,0(s6)
ffffffffc02027ea:	4505                	li	a0,1
ffffffffc02027ec:	6f9c                	ld	a5,24(a5)
ffffffffc02027ee:	9782                	jalr	a5
ffffffffc02027f0:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027f2:	938fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027f6:	b36d                	j	ffffffffc02025a0 <pmm_init+0x45a>
        intr_disable();
ffffffffc02027f8:	938fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027fc:	000b3783          	ld	a5,0(s6)
ffffffffc0202800:	779c                	ld	a5,40(a5)
ffffffffc0202802:	9782                	jalr	a5
ffffffffc0202804:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202806:	924fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020280a:	bdf9                	j	ffffffffc02026e8 <pmm_init+0x5a2>
ffffffffc020280c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020280e:	922fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202812:	000b3783          	ld	a5,0(s6)
ffffffffc0202816:	6522                	ld	a0,8(sp)
ffffffffc0202818:	4585                	li	a1,1
ffffffffc020281a:	739c                	ld	a5,32(a5)
ffffffffc020281c:	9782                	jalr	a5
        intr_enable();
ffffffffc020281e:	90cfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202822:	b55d                	j	ffffffffc02026c8 <pmm_init+0x582>
ffffffffc0202824:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202826:	90afe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020282a:	000b3783          	ld	a5,0(s6)
ffffffffc020282e:	6522                	ld	a0,8(sp)
ffffffffc0202830:	4585                	li	a1,1
ffffffffc0202832:	739c                	ld	a5,32(a5)
ffffffffc0202834:	9782                	jalr	a5
        intr_enable();
ffffffffc0202836:	8f4fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020283a:	bdb9                	j	ffffffffc0202698 <pmm_init+0x552>
        intr_disable();
ffffffffc020283c:	8f4fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202840:	000b3783          	ld	a5,0(s6)
ffffffffc0202844:	4585                	li	a1,1
ffffffffc0202846:	8552                	mv	a0,s4
ffffffffc0202848:	739c                	ld	a5,32(a5)
ffffffffc020284a:	9782                	jalr	a5
        intr_enable();
ffffffffc020284c:	8defe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202850:	bd29                	j	ffffffffc020266a <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202852:	86a2                	mv	a3,s0
ffffffffc0202854:	00002617          	auipc	a2,0x2
ffffffffc0202858:	4b460613          	addi	a2,a2,1204 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc020285c:	1a400593          	li	a1,420
ffffffffc0202860:	00002517          	auipc	a0,0x2
ffffffffc0202864:	5c050513          	addi	a0,a0,1472 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202868:	bf3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020286c:	00003697          	auipc	a3,0x3
ffffffffc0202870:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0205248 <default_pmm_manager+0x578>
ffffffffc0202874:	00002617          	auipc	a2,0x2
ffffffffc0202878:	0a460613          	addi	a2,a2,164 # ffffffffc0204918 <commands+0x810>
ffffffffc020287c:	1a500593          	li	a1,421
ffffffffc0202880:	00002517          	auipc	a0,0x2
ffffffffc0202884:	5a050513          	addi	a0,a0,1440 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202888:	bd3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020288c:	00003697          	auipc	a3,0x3
ffffffffc0202890:	97c68693          	addi	a3,a3,-1668 # ffffffffc0205208 <default_pmm_manager+0x538>
ffffffffc0202894:	00002617          	auipc	a2,0x2
ffffffffc0202898:	08460613          	addi	a2,a2,132 # ffffffffc0204918 <commands+0x810>
ffffffffc020289c:	1a400593          	li	a1,420
ffffffffc02028a0:	00002517          	auipc	a0,0x2
ffffffffc02028a4:	58050513          	addi	a0,a0,1408 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc02028a8:	bb3fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc02028ac:	b9cff0ef          	jal	ra,ffffffffc0201c48 <pa2page.part.0>
ffffffffc02028b0:	bb4ff0ef          	jal	ra,ffffffffc0201c64 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028b4:	00002697          	auipc	a3,0x2
ffffffffc02028b8:	74c68693          	addi	a3,a3,1868 # ffffffffc0205000 <default_pmm_manager+0x330>
ffffffffc02028bc:	00002617          	auipc	a2,0x2
ffffffffc02028c0:	05c60613          	addi	a2,a2,92 # ffffffffc0204918 <commands+0x810>
ffffffffc02028c4:	17400593          	li	a1,372
ffffffffc02028c8:	00002517          	auipc	a0,0x2
ffffffffc02028cc:	55850513          	addi	a0,a0,1368 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc02028d0:	b8bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028d4:	00002697          	auipc	a3,0x2
ffffffffc02028d8:	66c68693          	addi	a3,a3,1644 # ffffffffc0204f40 <default_pmm_manager+0x270>
ffffffffc02028dc:	00002617          	auipc	a2,0x2
ffffffffc02028e0:	03c60613          	addi	a2,a2,60 # ffffffffc0204918 <commands+0x810>
ffffffffc02028e4:	16700593          	li	a1,359
ffffffffc02028e8:	00002517          	auipc	a0,0x2
ffffffffc02028ec:	53850513          	addi	a0,a0,1336 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc02028f0:	b6bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028f4:	00002697          	auipc	a3,0x2
ffffffffc02028f8:	60c68693          	addi	a3,a3,1548 # ffffffffc0204f00 <default_pmm_manager+0x230>
ffffffffc02028fc:	00002617          	auipc	a2,0x2
ffffffffc0202900:	01c60613          	addi	a2,a2,28 # ffffffffc0204918 <commands+0x810>
ffffffffc0202904:	16600593          	li	a1,358
ffffffffc0202908:	00002517          	auipc	a0,0x2
ffffffffc020290c:	51850513          	addi	a0,a0,1304 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202910:	b4bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202914:	00002697          	auipc	a3,0x2
ffffffffc0202918:	5cc68693          	addi	a3,a3,1484 # ffffffffc0204ee0 <default_pmm_manager+0x210>
ffffffffc020291c:	00002617          	auipc	a2,0x2
ffffffffc0202920:	ffc60613          	addi	a2,a2,-4 # ffffffffc0204918 <commands+0x810>
ffffffffc0202924:	16500593          	li	a1,357
ffffffffc0202928:	00002517          	auipc	a0,0x2
ffffffffc020292c:	4f850513          	addi	a0,a0,1272 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202930:	b2bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202934:	00002617          	auipc	a2,0x2
ffffffffc0202938:	3d460613          	addi	a2,a2,980 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc020293c:	07100593          	li	a1,113
ffffffffc0202940:	00002517          	auipc	a0,0x2
ffffffffc0202944:	3f050513          	addi	a0,a0,1008 # ffffffffc0204d30 <default_pmm_manager+0x60>
ffffffffc0202948:	b13fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020294c:	00003697          	auipc	a3,0x3
ffffffffc0202950:	84468693          	addi	a3,a3,-1980 # ffffffffc0205190 <default_pmm_manager+0x4c0>
ffffffffc0202954:	00002617          	auipc	a2,0x2
ffffffffc0202958:	fc460613          	addi	a2,a2,-60 # ffffffffc0204918 <commands+0x810>
ffffffffc020295c:	18d00593          	li	a1,397
ffffffffc0202960:	00002517          	auipc	a0,0x2
ffffffffc0202964:	4c050513          	addi	a0,a0,1216 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202968:	af3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020296c:	00002697          	auipc	a3,0x2
ffffffffc0202970:	7dc68693          	addi	a3,a3,2012 # ffffffffc0205148 <default_pmm_manager+0x478>
ffffffffc0202974:	00002617          	auipc	a2,0x2
ffffffffc0202978:	fa460613          	addi	a2,a2,-92 # ffffffffc0204918 <commands+0x810>
ffffffffc020297c:	18b00593          	li	a1,395
ffffffffc0202980:	00002517          	auipc	a0,0x2
ffffffffc0202984:	4a050513          	addi	a0,a0,1184 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202988:	ad3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020298c:	00002697          	auipc	a3,0x2
ffffffffc0202990:	7ec68693          	addi	a3,a3,2028 # ffffffffc0205178 <default_pmm_manager+0x4a8>
ffffffffc0202994:	00002617          	auipc	a2,0x2
ffffffffc0202998:	f8460613          	addi	a2,a2,-124 # ffffffffc0204918 <commands+0x810>
ffffffffc020299c:	18a00593          	li	a1,394
ffffffffc02029a0:	00002517          	auipc	a0,0x2
ffffffffc02029a4:	48050513          	addi	a0,a0,1152 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc02029a8:	ab3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029ac:	00003697          	auipc	a3,0x3
ffffffffc02029b0:	8b468693          	addi	a3,a3,-1868 # ffffffffc0205260 <default_pmm_manager+0x590>
ffffffffc02029b4:	00002617          	auipc	a2,0x2
ffffffffc02029b8:	f6460613          	addi	a2,a2,-156 # ffffffffc0204918 <commands+0x810>
ffffffffc02029bc:	1a800593          	li	a1,424
ffffffffc02029c0:	00002517          	auipc	a0,0x2
ffffffffc02029c4:	46050513          	addi	a0,a0,1120 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc02029c8:	a93fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029cc:	00002697          	auipc	a3,0x2
ffffffffc02029d0:	7f468693          	addi	a3,a3,2036 # ffffffffc02051c0 <default_pmm_manager+0x4f0>
ffffffffc02029d4:	00002617          	auipc	a2,0x2
ffffffffc02029d8:	f4460613          	addi	a2,a2,-188 # ffffffffc0204918 <commands+0x810>
ffffffffc02029dc:	19500593          	li	a1,405
ffffffffc02029e0:	00002517          	auipc	a0,0x2
ffffffffc02029e4:	44050513          	addi	a0,a0,1088 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc02029e8:	a73fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029ec:	00003697          	auipc	a3,0x3
ffffffffc02029f0:	8cc68693          	addi	a3,a3,-1844 # ffffffffc02052b8 <default_pmm_manager+0x5e8>
ffffffffc02029f4:	00002617          	auipc	a2,0x2
ffffffffc02029f8:	f2460613          	addi	a2,a2,-220 # ffffffffc0204918 <commands+0x810>
ffffffffc02029fc:	1ad00593          	li	a1,429
ffffffffc0202a00:	00002517          	auipc	a0,0x2
ffffffffc0202a04:	42050513          	addi	a0,a0,1056 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202a08:	a53fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a0c:	00003697          	auipc	a3,0x3
ffffffffc0202a10:	86c68693          	addi	a3,a3,-1940 # ffffffffc0205278 <default_pmm_manager+0x5a8>
ffffffffc0202a14:	00002617          	auipc	a2,0x2
ffffffffc0202a18:	f0460613          	addi	a2,a2,-252 # ffffffffc0204918 <commands+0x810>
ffffffffc0202a1c:	1ac00593          	li	a1,428
ffffffffc0202a20:	00002517          	auipc	a0,0x2
ffffffffc0202a24:	40050513          	addi	a0,a0,1024 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202a28:	a33fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a2c:	00002697          	auipc	a3,0x2
ffffffffc0202a30:	71c68693          	addi	a3,a3,1820 # ffffffffc0205148 <default_pmm_manager+0x478>
ffffffffc0202a34:	00002617          	auipc	a2,0x2
ffffffffc0202a38:	ee460613          	addi	a2,a2,-284 # ffffffffc0204918 <commands+0x810>
ffffffffc0202a3c:	18700593          	li	a1,391
ffffffffc0202a40:	00002517          	auipc	a0,0x2
ffffffffc0202a44:	3e050513          	addi	a0,a0,992 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202a48:	a13fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a4c:	00002697          	auipc	a3,0x2
ffffffffc0202a50:	59c68693          	addi	a3,a3,1436 # ffffffffc0204fe8 <default_pmm_manager+0x318>
ffffffffc0202a54:	00002617          	auipc	a2,0x2
ffffffffc0202a58:	ec460613          	addi	a2,a2,-316 # ffffffffc0204918 <commands+0x810>
ffffffffc0202a5c:	18600593          	li	a1,390
ffffffffc0202a60:	00002517          	auipc	a0,0x2
ffffffffc0202a64:	3c050513          	addi	a0,a0,960 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202a68:	9f3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a6c:	00002697          	auipc	a3,0x2
ffffffffc0202a70:	6f468693          	addi	a3,a3,1780 # ffffffffc0205160 <default_pmm_manager+0x490>
ffffffffc0202a74:	00002617          	auipc	a2,0x2
ffffffffc0202a78:	ea460613          	addi	a2,a2,-348 # ffffffffc0204918 <commands+0x810>
ffffffffc0202a7c:	18300593          	li	a1,387
ffffffffc0202a80:	00002517          	auipc	a0,0x2
ffffffffc0202a84:	3a050513          	addi	a0,a0,928 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202a88:	9d3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a8c:	00002697          	auipc	a3,0x2
ffffffffc0202a90:	54468693          	addi	a3,a3,1348 # ffffffffc0204fd0 <default_pmm_manager+0x300>
ffffffffc0202a94:	00002617          	auipc	a2,0x2
ffffffffc0202a98:	e8460613          	addi	a2,a2,-380 # ffffffffc0204918 <commands+0x810>
ffffffffc0202a9c:	18200593          	li	a1,386
ffffffffc0202aa0:	00002517          	auipc	a0,0x2
ffffffffc0202aa4:	38050513          	addi	a0,a0,896 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202aa8:	9b3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202aac:	00002697          	auipc	a3,0x2
ffffffffc0202ab0:	5c468693          	addi	a3,a3,1476 # ffffffffc0205070 <default_pmm_manager+0x3a0>
ffffffffc0202ab4:	00002617          	auipc	a2,0x2
ffffffffc0202ab8:	e6460613          	addi	a2,a2,-412 # ffffffffc0204918 <commands+0x810>
ffffffffc0202abc:	18100593          	li	a1,385
ffffffffc0202ac0:	00002517          	auipc	a0,0x2
ffffffffc0202ac4:	36050513          	addi	a0,a0,864 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202ac8:	993fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202acc:	00002697          	auipc	a3,0x2
ffffffffc0202ad0:	67c68693          	addi	a3,a3,1660 # ffffffffc0205148 <default_pmm_manager+0x478>
ffffffffc0202ad4:	00002617          	auipc	a2,0x2
ffffffffc0202ad8:	e4460613          	addi	a2,a2,-444 # ffffffffc0204918 <commands+0x810>
ffffffffc0202adc:	18000593          	li	a1,384
ffffffffc0202ae0:	00002517          	auipc	a0,0x2
ffffffffc0202ae4:	34050513          	addi	a0,a0,832 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202ae8:	973fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202aec:	00002697          	auipc	a3,0x2
ffffffffc0202af0:	64468693          	addi	a3,a3,1604 # ffffffffc0205130 <default_pmm_manager+0x460>
ffffffffc0202af4:	00002617          	auipc	a2,0x2
ffffffffc0202af8:	e2460613          	addi	a2,a2,-476 # ffffffffc0204918 <commands+0x810>
ffffffffc0202afc:	17f00593          	li	a1,383
ffffffffc0202b00:	00002517          	auipc	a0,0x2
ffffffffc0202b04:	32050513          	addi	a0,a0,800 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202b08:	953fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b0c:	00002697          	auipc	a3,0x2
ffffffffc0202b10:	5f468693          	addi	a3,a3,1524 # ffffffffc0205100 <default_pmm_manager+0x430>
ffffffffc0202b14:	00002617          	auipc	a2,0x2
ffffffffc0202b18:	e0460613          	addi	a2,a2,-508 # ffffffffc0204918 <commands+0x810>
ffffffffc0202b1c:	17e00593          	li	a1,382
ffffffffc0202b20:	00002517          	auipc	a0,0x2
ffffffffc0202b24:	30050513          	addi	a0,a0,768 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202b28:	933fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b2c:	00002697          	auipc	a3,0x2
ffffffffc0202b30:	5bc68693          	addi	a3,a3,1468 # ffffffffc02050e8 <default_pmm_manager+0x418>
ffffffffc0202b34:	00002617          	auipc	a2,0x2
ffffffffc0202b38:	de460613          	addi	a2,a2,-540 # ffffffffc0204918 <commands+0x810>
ffffffffc0202b3c:	17c00593          	li	a1,380
ffffffffc0202b40:	00002517          	auipc	a0,0x2
ffffffffc0202b44:	2e050513          	addi	a0,a0,736 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202b48:	913fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b4c:	00002697          	auipc	a3,0x2
ffffffffc0202b50:	57c68693          	addi	a3,a3,1404 # ffffffffc02050c8 <default_pmm_manager+0x3f8>
ffffffffc0202b54:	00002617          	auipc	a2,0x2
ffffffffc0202b58:	dc460613          	addi	a2,a2,-572 # ffffffffc0204918 <commands+0x810>
ffffffffc0202b5c:	17b00593          	li	a1,379
ffffffffc0202b60:	00002517          	auipc	a0,0x2
ffffffffc0202b64:	2c050513          	addi	a0,a0,704 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202b68:	8f3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b6c:	00002697          	auipc	a3,0x2
ffffffffc0202b70:	54c68693          	addi	a3,a3,1356 # ffffffffc02050b8 <default_pmm_manager+0x3e8>
ffffffffc0202b74:	00002617          	auipc	a2,0x2
ffffffffc0202b78:	da460613          	addi	a2,a2,-604 # ffffffffc0204918 <commands+0x810>
ffffffffc0202b7c:	17a00593          	li	a1,378
ffffffffc0202b80:	00002517          	auipc	a0,0x2
ffffffffc0202b84:	2a050513          	addi	a0,a0,672 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202b88:	8d3fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b8c:	00002697          	auipc	a3,0x2
ffffffffc0202b90:	51c68693          	addi	a3,a3,1308 # ffffffffc02050a8 <default_pmm_manager+0x3d8>
ffffffffc0202b94:	00002617          	auipc	a2,0x2
ffffffffc0202b98:	d8460613          	addi	a2,a2,-636 # ffffffffc0204918 <commands+0x810>
ffffffffc0202b9c:	17900593          	li	a1,377
ffffffffc0202ba0:	00002517          	auipc	a0,0x2
ffffffffc0202ba4:	28050513          	addi	a0,a0,640 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202ba8:	8b3fd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202bac:	00002617          	auipc	a2,0x2
ffffffffc0202bb0:	29c60613          	addi	a2,a2,668 # ffffffffc0204e48 <default_pmm_manager+0x178>
ffffffffc0202bb4:	06400593          	li	a1,100
ffffffffc0202bb8:	00002517          	auipc	a0,0x2
ffffffffc0202bbc:	26850513          	addi	a0,a0,616 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202bc0:	89bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202bc4:	00002697          	auipc	a3,0x2
ffffffffc0202bc8:	5fc68693          	addi	a3,a3,1532 # ffffffffc02051c0 <default_pmm_manager+0x4f0>
ffffffffc0202bcc:	00002617          	auipc	a2,0x2
ffffffffc0202bd0:	d4c60613          	addi	a2,a2,-692 # ffffffffc0204918 <commands+0x810>
ffffffffc0202bd4:	1bf00593          	li	a1,447
ffffffffc0202bd8:	00002517          	auipc	a0,0x2
ffffffffc0202bdc:	24850513          	addi	a0,a0,584 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202be0:	87bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202be4:	00002697          	auipc	a3,0x2
ffffffffc0202be8:	48c68693          	addi	a3,a3,1164 # ffffffffc0205070 <default_pmm_manager+0x3a0>
ffffffffc0202bec:	00002617          	auipc	a2,0x2
ffffffffc0202bf0:	d2c60613          	addi	a2,a2,-724 # ffffffffc0204918 <commands+0x810>
ffffffffc0202bf4:	17800593          	li	a1,376
ffffffffc0202bf8:	00002517          	auipc	a0,0x2
ffffffffc0202bfc:	22850513          	addi	a0,a0,552 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202c00:	85bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c04:	00002697          	auipc	a3,0x2
ffffffffc0202c08:	42c68693          	addi	a3,a3,1068 # ffffffffc0205030 <default_pmm_manager+0x360>
ffffffffc0202c0c:	00002617          	auipc	a2,0x2
ffffffffc0202c10:	d0c60613          	addi	a2,a2,-756 # ffffffffc0204918 <commands+0x810>
ffffffffc0202c14:	17700593          	li	a1,375
ffffffffc0202c18:	00002517          	auipc	a0,0x2
ffffffffc0202c1c:	20850513          	addi	a0,a0,520 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202c20:	83bfd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c24:	86d6                	mv	a3,s5
ffffffffc0202c26:	00002617          	auipc	a2,0x2
ffffffffc0202c2a:	0e260613          	addi	a2,a2,226 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc0202c2e:	17300593          	li	a1,371
ffffffffc0202c32:	00002517          	auipc	a0,0x2
ffffffffc0202c36:	1ee50513          	addi	a0,a0,494 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202c3a:	821fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c3e:	00002617          	auipc	a2,0x2
ffffffffc0202c42:	0ca60613          	addi	a2,a2,202 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc0202c46:	17200593          	li	a1,370
ffffffffc0202c4a:	00002517          	auipc	a0,0x2
ffffffffc0202c4e:	1d650513          	addi	a0,a0,470 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202c52:	809fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c56:	00002697          	auipc	a3,0x2
ffffffffc0202c5a:	39268693          	addi	a3,a3,914 # ffffffffc0204fe8 <default_pmm_manager+0x318>
ffffffffc0202c5e:	00002617          	auipc	a2,0x2
ffffffffc0202c62:	cba60613          	addi	a2,a2,-838 # ffffffffc0204918 <commands+0x810>
ffffffffc0202c66:	17000593          	li	a1,368
ffffffffc0202c6a:	00002517          	auipc	a0,0x2
ffffffffc0202c6e:	1b650513          	addi	a0,a0,438 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202c72:	fe8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c76:	00002697          	auipc	a3,0x2
ffffffffc0202c7a:	35a68693          	addi	a3,a3,858 # ffffffffc0204fd0 <default_pmm_manager+0x300>
ffffffffc0202c7e:	00002617          	auipc	a2,0x2
ffffffffc0202c82:	c9a60613          	addi	a2,a2,-870 # ffffffffc0204918 <commands+0x810>
ffffffffc0202c86:	16f00593          	li	a1,367
ffffffffc0202c8a:	00002517          	auipc	a0,0x2
ffffffffc0202c8e:	19650513          	addi	a0,a0,406 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202c92:	fc8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c96:	00002697          	auipc	a3,0x2
ffffffffc0202c9a:	6ea68693          	addi	a3,a3,1770 # ffffffffc0205380 <default_pmm_manager+0x6b0>
ffffffffc0202c9e:	00002617          	auipc	a2,0x2
ffffffffc0202ca2:	c7a60613          	addi	a2,a2,-902 # ffffffffc0204918 <commands+0x810>
ffffffffc0202ca6:	1b600593          	li	a1,438
ffffffffc0202caa:	00002517          	auipc	a0,0x2
ffffffffc0202cae:	17650513          	addi	a0,a0,374 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202cb2:	fa8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cb6:	00002697          	auipc	a3,0x2
ffffffffc0202cba:	69268693          	addi	a3,a3,1682 # ffffffffc0205348 <default_pmm_manager+0x678>
ffffffffc0202cbe:	00002617          	auipc	a2,0x2
ffffffffc0202cc2:	c5a60613          	addi	a2,a2,-934 # ffffffffc0204918 <commands+0x810>
ffffffffc0202cc6:	1b300593          	li	a1,435
ffffffffc0202cca:	00002517          	auipc	a0,0x2
ffffffffc0202cce:	15650513          	addi	a0,a0,342 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202cd2:	f88fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202cd6:	00002697          	auipc	a3,0x2
ffffffffc0202cda:	64268693          	addi	a3,a3,1602 # ffffffffc0205318 <default_pmm_manager+0x648>
ffffffffc0202cde:	00002617          	auipc	a2,0x2
ffffffffc0202ce2:	c3a60613          	addi	a2,a2,-966 # ffffffffc0204918 <commands+0x810>
ffffffffc0202ce6:	1af00593          	li	a1,431
ffffffffc0202cea:	00002517          	auipc	a0,0x2
ffffffffc0202cee:	13650513          	addi	a0,a0,310 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202cf2:	f68fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202cf6:	00002697          	auipc	a3,0x2
ffffffffc0202cfa:	5da68693          	addi	a3,a3,1498 # ffffffffc02052d0 <default_pmm_manager+0x600>
ffffffffc0202cfe:	00002617          	auipc	a2,0x2
ffffffffc0202d02:	c1a60613          	addi	a2,a2,-998 # ffffffffc0204918 <commands+0x810>
ffffffffc0202d06:	1ae00593          	li	a1,430
ffffffffc0202d0a:	00002517          	auipc	a0,0x2
ffffffffc0202d0e:	11650513          	addi	a0,a0,278 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202d12:	f48fd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d16:	00002617          	auipc	a2,0x2
ffffffffc0202d1a:	09a60613          	addi	a2,a2,154 # ffffffffc0204db0 <default_pmm_manager+0xe0>
ffffffffc0202d1e:	0cb00593          	li	a1,203
ffffffffc0202d22:	00002517          	auipc	a0,0x2
ffffffffc0202d26:	0fe50513          	addi	a0,a0,254 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202d2a:	f30fd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202d2e:	00002617          	auipc	a2,0x2
ffffffffc0202d32:	08260613          	addi	a2,a2,130 # ffffffffc0204db0 <default_pmm_manager+0xe0>
ffffffffc0202d36:	08000593          	li	a1,128
ffffffffc0202d3a:	00002517          	auipc	a0,0x2
ffffffffc0202d3e:	0e650513          	addi	a0,a0,230 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202d42:	f18fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d46:	00002697          	auipc	a3,0x2
ffffffffc0202d4a:	25a68693          	addi	a3,a3,602 # ffffffffc0204fa0 <default_pmm_manager+0x2d0>
ffffffffc0202d4e:	00002617          	auipc	a2,0x2
ffffffffc0202d52:	bca60613          	addi	a2,a2,-1078 # ffffffffc0204918 <commands+0x810>
ffffffffc0202d56:	16e00593          	li	a1,366
ffffffffc0202d5a:	00002517          	auipc	a0,0x2
ffffffffc0202d5e:	0c650513          	addi	a0,a0,198 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202d62:	ef8fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d66:	00002697          	auipc	a3,0x2
ffffffffc0202d6a:	20a68693          	addi	a3,a3,522 # ffffffffc0204f70 <default_pmm_manager+0x2a0>
ffffffffc0202d6e:	00002617          	auipc	a2,0x2
ffffffffc0202d72:	baa60613          	addi	a2,a2,-1110 # ffffffffc0204918 <commands+0x810>
ffffffffc0202d76:	16b00593          	li	a1,363
ffffffffc0202d7a:	00002517          	auipc	a0,0x2
ffffffffc0202d7e:	0a650513          	addi	a0,a0,166 # ffffffffc0204e20 <default_pmm_manager+0x150>
ffffffffc0202d82:	ed8fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202d86 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d86:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d88:	00002697          	auipc	a3,0x2
ffffffffc0202d8c:	64068693          	addi	a3,a3,1600 # ffffffffc02053c8 <default_pmm_manager+0x6f8>
ffffffffc0202d90:	00002617          	auipc	a2,0x2
ffffffffc0202d94:	b8860613          	addi	a2,a2,-1144 # ffffffffc0204918 <commands+0x810>
ffffffffc0202d98:	08800593          	li	a1,136
ffffffffc0202d9c:	00002517          	auipc	a0,0x2
ffffffffc0202da0:	64c50513          	addi	a0,a0,1612 # ffffffffc02053e8 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202da4:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202da6:	eb4fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202daa <find_vma>:
{
ffffffffc0202daa:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202dac:	c505                	beqz	a0,ffffffffc0202dd4 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202dae:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202db0:	c501                	beqz	a0,ffffffffc0202db8 <find_vma+0xe>
ffffffffc0202db2:	651c                	ld	a5,8(a0)
ffffffffc0202db4:	02f5f263          	bgeu	a1,a5,ffffffffc0202dd8 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202db8:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202dba:	00f68d63          	beq	a3,a5,ffffffffc0202dd4 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dbe:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0202dc2:	00e5e663          	bltu	a1,a4,ffffffffc0202dce <find_vma+0x24>
ffffffffc0202dc6:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202dca:	00e5ec63          	bltu	a1,a4,ffffffffc0202de2 <find_vma+0x38>
ffffffffc0202dce:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202dd0:	fef697e3          	bne	a3,a5,ffffffffc0202dbe <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202dd4:	4501                	li	a0,0
}
ffffffffc0202dd6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dd8:	691c                	ld	a5,16(a0)
ffffffffc0202dda:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202db8 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202dde:	ea88                	sd	a0,16(a3)
ffffffffc0202de0:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202de2:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202de6:	ea88                	sd	a0,16(a3)
ffffffffc0202de8:	8082                	ret

ffffffffc0202dea <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dea:	6590                	ld	a2,8(a1)
ffffffffc0202dec:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202df0:	1141                	addi	sp,sp,-16
ffffffffc0202df2:	e406                	sd	ra,8(sp)
ffffffffc0202df4:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202df6:	01066763          	bltu	a2,a6,ffffffffc0202e04 <insert_vma_struct+0x1a>
ffffffffc0202dfa:	a085                	j	ffffffffc0202e5a <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202dfc:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e00:	04e66863          	bltu	a2,a4,ffffffffc0202e50 <insert_vma_struct+0x66>
ffffffffc0202e04:	86be                	mv	a3,a5
ffffffffc0202e06:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e08:	fef51ae3          	bne	a0,a5,ffffffffc0202dfc <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e0c:	02a68463          	beq	a3,a0,ffffffffc0202e34 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e10:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e14:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e18:	08e8f163          	bgeu	a7,a4,ffffffffc0202e9a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e1c:	04e66f63          	bltu	a2,a4,ffffffffc0202e7a <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202e20:	00f50a63          	beq	a0,a5,ffffffffc0202e34 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e24:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e28:	05076963          	bltu	a4,a6,ffffffffc0202e7a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e2c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e30:	02c77363          	bgeu	a4,a2,ffffffffc0202e56 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e34:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e36:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e38:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e3c:	e390                	sd	a2,0(a5)
ffffffffc0202e3e:	e690                	sd	a2,8(a3)
}
ffffffffc0202e40:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e42:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e44:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e46:	0017079b          	addiw	a5,a4,1
ffffffffc0202e4a:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e4c:	0141                	addi	sp,sp,16
ffffffffc0202e4e:	8082                	ret
    if (le_prev != list)
ffffffffc0202e50:	fca690e3          	bne	a3,a0,ffffffffc0202e10 <insert_vma_struct+0x26>
ffffffffc0202e54:	bfd1                	j	ffffffffc0202e28 <insert_vma_struct+0x3e>
ffffffffc0202e56:	f31ff0ef          	jal	ra,ffffffffc0202d86 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e5a:	00002697          	auipc	a3,0x2
ffffffffc0202e5e:	59e68693          	addi	a3,a3,1438 # ffffffffc02053f8 <default_pmm_manager+0x728>
ffffffffc0202e62:	00002617          	auipc	a2,0x2
ffffffffc0202e66:	ab660613          	addi	a2,a2,-1354 # ffffffffc0204918 <commands+0x810>
ffffffffc0202e6a:	08e00593          	li	a1,142
ffffffffc0202e6e:	00002517          	auipc	a0,0x2
ffffffffc0202e72:	57a50513          	addi	a0,a0,1402 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc0202e76:	de4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e7a:	00002697          	auipc	a3,0x2
ffffffffc0202e7e:	5be68693          	addi	a3,a3,1470 # ffffffffc0205438 <default_pmm_manager+0x768>
ffffffffc0202e82:	00002617          	auipc	a2,0x2
ffffffffc0202e86:	a9660613          	addi	a2,a2,-1386 # ffffffffc0204918 <commands+0x810>
ffffffffc0202e8a:	08700593          	li	a1,135
ffffffffc0202e8e:	00002517          	auipc	a0,0x2
ffffffffc0202e92:	55a50513          	addi	a0,a0,1370 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc0202e96:	dc4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e9a:	00002697          	auipc	a3,0x2
ffffffffc0202e9e:	57e68693          	addi	a3,a3,1406 # ffffffffc0205418 <default_pmm_manager+0x748>
ffffffffc0202ea2:	00002617          	auipc	a2,0x2
ffffffffc0202ea6:	a7660613          	addi	a2,a2,-1418 # ffffffffc0204918 <commands+0x810>
ffffffffc0202eaa:	08600593          	li	a1,134
ffffffffc0202eae:	00002517          	auipc	a0,0x2
ffffffffc0202eb2:	53a50513          	addi	a0,a0,1338 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc0202eb6:	da4fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202eba <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202eba:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ebc:	03000513          	li	a0,48
{
ffffffffc0202ec0:	fc06                	sd	ra,56(sp)
ffffffffc0202ec2:	f822                	sd	s0,48(sp)
ffffffffc0202ec4:	f426                	sd	s1,40(sp)
ffffffffc0202ec6:	f04a                	sd	s2,32(sp)
ffffffffc0202ec8:	ec4e                	sd	s3,24(sp)
ffffffffc0202eca:	e852                	sd	s4,16(sp)
ffffffffc0202ecc:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ece:	bd5fe0ef          	jal	ra,ffffffffc0201aa2 <kmalloc>
    if (mm != NULL)
ffffffffc0202ed2:	2e050f63          	beqz	a0,ffffffffc02031d0 <vmm_init+0x316>
ffffffffc0202ed6:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202ed8:	e508                	sd	a0,8(a0)
ffffffffc0202eda:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202edc:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202ee0:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202ee4:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202ee8:	02053423          	sd	zero,40(a0)
ffffffffc0202eec:	03200413          	li	s0,50
ffffffffc0202ef0:	a811                	j	ffffffffc0202f04 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202ef2:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202ef4:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202ef6:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202efa:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202efc:	8526                	mv	a0,s1
ffffffffc0202efe:	eedff0ef          	jal	ra,ffffffffc0202dea <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f02:	c80d                	beqz	s0,ffffffffc0202f34 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f04:	03000513          	li	a0,48
ffffffffc0202f08:	b9bfe0ef          	jal	ra,ffffffffc0201aa2 <kmalloc>
ffffffffc0202f0c:	85aa                	mv	a1,a0
ffffffffc0202f0e:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f12:	f165                	bnez	a0,ffffffffc0202ef2 <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202f14:	00002697          	auipc	a3,0x2
ffffffffc0202f18:	6bc68693          	addi	a3,a3,1724 # ffffffffc02055d0 <default_pmm_manager+0x900>
ffffffffc0202f1c:	00002617          	auipc	a2,0x2
ffffffffc0202f20:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0204918 <commands+0x810>
ffffffffc0202f24:	0da00593          	li	a1,218
ffffffffc0202f28:	00002517          	auipc	a0,0x2
ffffffffc0202f2c:	4c050513          	addi	a0,a0,1216 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc0202f30:	d2afd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202f34:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f38:	1f900913          	li	s2,505
ffffffffc0202f3c:	a819                	j	ffffffffc0202f52 <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202f3e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f40:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f42:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f46:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f48:	8526                	mv	a0,s1
ffffffffc0202f4a:	ea1ff0ef          	jal	ra,ffffffffc0202dea <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f4e:	03240a63          	beq	s0,s2,ffffffffc0202f82 <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f52:	03000513          	li	a0,48
ffffffffc0202f56:	b4dfe0ef          	jal	ra,ffffffffc0201aa2 <kmalloc>
ffffffffc0202f5a:	85aa                	mv	a1,a0
ffffffffc0202f5c:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f60:	fd79                	bnez	a0,ffffffffc0202f3e <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202f62:	00002697          	auipc	a3,0x2
ffffffffc0202f66:	66e68693          	addi	a3,a3,1646 # ffffffffc02055d0 <default_pmm_manager+0x900>
ffffffffc0202f6a:	00002617          	auipc	a2,0x2
ffffffffc0202f6e:	9ae60613          	addi	a2,a2,-1618 # ffffffffc0204918 <commands+0x810>
ffffffffc0202f72:	0e100593          	li	a1,225
ffffffffc0202f76:	00002517          	auipc	a0,0x2
ffffffffc0202f7a:	47250513          	addi	a0,a0,1138 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc0202f7e:	cdcfd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202f82:	649c                	ld	a5,8(s1)
ffffffffc0202f84:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f86:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f8a:	18f48363          	beq	s1,a5,ffffffffc0203110 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f8e:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f92:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202f96:	10d61d63          	bne	a2,a3,ffffffffc02030b0 <vmm_init+0x1f6>
ffffffffc0202f9a:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f9e:	10e69963          	bne	a3,a4,ffffffffc02030b0 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202fa2:	0715                	addi	a4,a4,5
ffffffffc0202fa4:	679c                	ld	a5,8(a5)
ffffffffc0202fa6:	feb712e3          	bne	a4,a1,ffffffffc0202f8a <vmm_init+0xd0>
ffffffffc0202faa:	4a1d                	li	s4,7
ffffffffc0202fac:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fae:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202fb2:	85a2                	mv	a1,s0
ffffffffc0202fb4:	8526                	mv	a0,s1
ffffffffc0202fb6:	df5ff0ef          	jal	ra,ffffffffc0202daa <find_vma>
ffffffffc0202fba:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202fbc:	18050a63          	beqz	a0,ffffffffc0203150 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202fc0:	00140593          	addi	a1,s0,1
ffffffffc0202fc4:	8526                	mv	a0,s1
ffffffffc0202fc6:	de5ff0ef          	jal	ra,ffffffffc0202daa <find_vma>
ffffffffc0202fca:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202fcc:	16050263          	beqz	a0,ffffffffc0203130 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202fd0:	85d2                	mv	a1,s4
ffffffffc0202fd2:	8526                	mv	a0,s1
ffffffffc0202fd4:	dd7ff0ef          	jal	ra,ffffffffc0202daa <find_vma>
        assert(vma3 == NULL);
ffffffffc0202fd8:	18051c63          	bnez	a0,ffffffffc0203170 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202fdc:	00340593          	addi	a1,s0,3
ffffffffc0202fe0:	8526                	mv	a0,s1
ffffffffc0202fe2:	dc9ff0ef          	jal	ra,ffffffffc0202daa <find_vma>
        assert(vma4 == NULL);
ffffffffc0202fe6:	1c051563          	bnez	a0,ffffffffc02031b0 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202fea:	00440593          	addi	a1,s0,4
ffffffffc0202fee:	8526                	mv	a0,s1
ffffffffc0202ff0:	dbbff0ef          	jal	ra,ffffffffc0202daa <find_vma>
        assert(vma5 == NULL);
ffffffffc0202ff4:	18051e63          	bnez	a0,ffffffffc0203190 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202ff8:	00893783          	ld	a5,8(s2)
ffffffffc0202ffc:	0c879a63          	bne	a5,s0,ffffffffc02030d0 <vmm_init+0x216>
ffffffffc0203000:	01093783          	ld	a5,16(s2)
ffffffffc0203004:	0d479663          	bne	a5,s4,ffffffffc02030d0 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203008:	0089b783          	ld	a5,8(s3)
ffffffffc020300c:	0e879263          	bne	a5,s0,ffffffffc02030f0 <vmm_init+0x236>
ffffffffc0203010:	0109b783          	ld	a5,16(s3)
ffffffffc0203014:	0d479e63          	bne	a5,s4,ffffffffc02030f0 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203018:	0415                	addi	s0,s0,5
ffffffffc020301a:	0a15                	addi	s4,s4,5
ffffffffc020301c:	f9541be3          	bne	s0,s5,ffffffffc0202fb2 <vmm_init+0xf8>
ffffffffc0203020:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203022:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203024:	85a2                	mv	a1,s0
ffffffffc0203026:	8526                	mv	a0,s1
ffffffffc0203028:	d83ff0ef          	jal	ra,ffffffffc0202daa <find_vma>
ffffffffc020302c:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203030:	c90d                	beqz	a0,ffffffffc0203062 <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203032:	6914                	ld	a3,16(a0)
ffffffffc0203034:	6510                	ld	a2,8(a0)
ffffffffc0203036:	00002517          	auipc	a0,0x2
ffffffffc020303a:	52250513          	addi	a0,a0,1314 # ffffffffc0205558 <default_pmm_manager+0x888>
ffffffffc020303e:	956fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203042:	00002697          	auipc	a3,0x2
ffffffffc0203046:	53e68693          	addi	a3,a3,1342 # ffffffffc0205580 <default_pmm_manager+0x8b0>
ffffffffc020304a:	00002617          	auipc	a2,0x2
ffffffffc020304e:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0204918 <commands+0x810>
ffffffffc0203052:	10700593          	li	a1,263
ffffffffc0203056:	00002517          	auipc	a0,0x2
ffffffffc020305a:	39250513          	addi	a0,a0,914 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc020305e:	bfcfd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203062:	147d                	addi	s0,s0,-1
ffffffffc0203064:	fd2410e3          	bne	s0,s2,ffffffffc0203024 <vmm_init+0x16a>
ffffffffc0203068:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020306a:	00a48c63          	beq	s1,a0,ffffffffc0203082 <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc020306e:	6118                	ld	a4,0(a0)
ffffffffc0203070:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203072:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203074:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203076:	e398                	sd	a4,0(a5)
ffffffffc0203078:	adbfe0ef          	jal	ra,ffffffffc0201b52 <kfree>
    return listelm->next;
ffffffffc020307c:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020307e:	fea498e3          	bne	s1,a0,ffffffffc020306e <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc0203082:	8526                	mv	a0,s1
ffffffffc0203084:	acffe0ef          	jal	ra,ffffffffc0201b52 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203088:	00002517          	auipc	a0,0x2
ffffffffc020308c:	51050513          	addi	a0,a0,1296 # ffffffffc0205598 <default_pmm_manager+0x8c8>
ffffffffc0203090:	904fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203094:	7442                	ld	s0,48(sp)
ffffffffc0203096:	70e2                	ld	ra,56(sp)
ffffffffc0203098:	74a2                	ld	s1,40(sp)
ffffffffc020309a:	7902                	ld	s2,32(sp)
ffffffffc020309c:	69e2                	ld	s3,24(sp)
ffffffffc020309e:	6a42                	ld	s4,16(sp)
ffffffffc02030a0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030a2:	00002517          	auipc	a0,0x2
ffffffffc02030a6:	51650513          	addi	a0,a0,1302 # ffffffffc02055b8 <default_pmm_manager+0x8e8>
}
ffffffffc02030aa:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030ac:	8e8fd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030b0:	00002697          	auipc	a3,0x2
ffffffffc02030b4:	3c068693          	addi	a3,a3,960 # ffffffffc0205470 <default_pmm_manager+0x7a0>
ffffffffc02030b8:	00002617          	auipc	a2,0x2
ffffffffc02030bc:	86060613          	addi	a2,a2,-1952 # ffffffffc0204918 <commands+0x810>
ffffffffc02030c0:	0eb00593          	li	a1,235
ffffffffc02030c4:	00002517          	auipc	a0,0x2
ffffffffc02030c8:	32450513          	addi	a0,a0,804 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc02030cc:	b8efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030d0:	00002697          	auipc	a3,0x2
ffffffffc02030d4:	42868693          	addi	a3,a3,1064 # ffffffffc02054f8 <default_pmm_manager+0x828>
ffffffffc02030d8:	00002617          	auipc	a2,0x2
ffffffffc02030dc:	84060613          	addi	a2,a2,-1984 # ffffffffc0204918 <commands+0x810>
ffffffffc02030e0:	0fc00593          	li	a1,252
ffffffffc02030e4:	00002517          	auipc	a0,0x2
ffffffffc02030e8:	30450513          	addi	a0,a0,772 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc02030ec:	b6efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02030f0:	00002697          	auipc	a3,0x2
ffffffffc02030f4:	43868693          	addi	a3,a3,1080 # ffffffffc0205528 <default_pmm_manager+0x858>
ffffffffc02030f8:	00002617          	auipc	a2,0x2
ffffffffc02030fc:	82060613          	addi	a2,a2,-2016 # ffffffffc0204918 <commands+0x810>
ffffffffc0203100:	0fd00593          	li	a1,253
ffffffffc0203104:	00002517          	auipc	a0,0x2
ffffffffc0203108:	2e450513          	addi	a0,a0,740 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc020310c:	b4efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203110:	00002697          	auipc	a3,0x2
ffffffffc0203114:	34868693          	addi	a3,a3,840 # ffffffffc0205458 <default_pmm_manager+0x788>
ffffffffc0203118:	00002617          	auipc	a2,0x2
ffffffffc020311c:	80060613          	addi	a2,a2,-2048 # ffffffffc0204918 <commands+0x810>
ffffffffc0203120:	0e900593          	li	a1,233
ffffffffc0203124:	00002517          	auipc	a0,0x2
ffffffffc0203128:	2c450513          	addi	a0,a0,708 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc020312c:	b2efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc0203130:	00002697          	auipc	a3,0x2
ffffffffc0203134:	38868693          	addi	a3,a3,904 # ffffffffc02054b8 <default_pmm_manager+0x7e8>
ffffffffc0203138:	00001617          	auipc	a2,0x1
ffffffffc020313c:	7e060613          	addi	a2,a2,2016 # ffffffffc0204918 <commands+0x810>
ffffffffc0203140:	0f400593          	li	a1,244
ffffffffc0203144:	00002517          	auipc	a0,0x2
ffffffffc0203148:	2a450513          	addi	a0,a0,676 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc020314c:	b0efd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc0203150:	00002697          	auipc	a3,0x2
ffffffffc0203154:	35868693          	addi	a3,a3,856 # ffffffffc02054a8 <default_pmm_manager+0x7d8>
ffffffffc0203158:	00001617          	auipc	a2,0x1
ffffffffc020315c:	7c060613          	addi	a2,a2,1984 # ffffffffc0204918 <commands+0x810>
ffffffffc0203160:	0f200593          	li	a1,242
ffffffffc0203164:	00002517          	auipc	a0,0x2
ffffffffc0203168:	28450513          	addi	a0,a0,644 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc020316c:	aeefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc0203170:	00002697          	auipc	a3,0x2
ffffffffc0203174:	35868693          	addi	a3,a3,856 # ffffffffc02054c8 <default_pmm_manager+0x7f8>
ffffffffc0203178:	00001617          	auipc	a2,0x1
ffffffffc020317c:	7a060613          	addi	a2,a2,1952 # ffffffffc0204918 <commands+0x810>
ffffffffc0203180:	0f600593          	li	a1,246
ffffffffc0203184:	00002517          	auipc	a0,0x2
ffffffffc0203188:	26450513          	addi	a0,a0,612 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc020318c:	acefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc0203190:	00002697          	auipc	a3,0x2
ffffffffc0203194:	35868693          	addi	a3,a3,856 # ffffffffc02054e8 <default_pmm_manager+0x818>
ffffffffc0203198:	00001617          	auipc	a2,0x1
ffffffffc020319c:	78060613          	addi	a2,a2,1920 # ffffffffc0204918 <commands+0x810>
ffffffffc02031a0:	0fa00593          	li	a1,250
ffffffffc02031a4:	00002517          	auipc	a0,0x2
ffffffffc02031a8:	24450513          	addi	a0,a0,580 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc02031ac:	aaefd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc02031b0:	00002697          	auipc	a3,0x2
ffffffffc02031b4:	32868693          	addi	a3,a3,808 # ffffffffc02054d8 <default_pmm_manager+0x808>
ffffffffc02031b8:	00001617          	auipc	a2,0x1
ffffffffc02031bc:	76060613          	addi	a2,a2,1888 # ffffffffc0204918 <commands+0x810>
ffffffffc02031c0:	0f800593          	li	a1,248
ffffffffc02031c4:	00002517          	auipc	a0,0x2
ffffffffc02031c8:	22450513          	addi	a0,a0,548 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc02031cc:	a8efd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc02031d0:	00002697          	auipc	a3,0x2
ffffffffc02031d4:	41068693          	addi	a3,a3,1040 # ffffffffc02055e0 <default_pmm_manager+0x910>
ffffffffc02031d8:	00001617          	auipc	a2,0x1
ffffffffc02031dc:	74060613          	addi	a2,a2,1856 # ffffffffc0204918 <commands+0x810>
ffffffffc02031e0:	0d200593          	li	a1,210
ffffffffc02031e4:	00002517          	auipc	a0,0x2
ffffffffc02031e8:	20450513          	addi	a0,a0,516 # ffffffffc02053e8 <default_pmm_manager+0x718>
ffffffffc02031ec:	a6efd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02031f0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02031f0:	8526                	mv	a0,s1
	jalr s0
ffffffffc02031f2:	9402                	jalr	s0

	jal do_exit
ffffffffc02031f4:	402000ef          	jal	ra,ffffffffc02035f6 <do_exit>

ffffffffc02031f8 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02031f8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02031fa:	0e800513          	li	a0,232
{
ffffffffc02031fe:	e022                	sd	s0,0(sp)
ffffffffc0203200:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203202:	8a1fe0ef          	jal	ra,ffffffffc0201aa2 <kmalloc>
ffffffffc0203206:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203208:	c521                	beqz	a0,ffffffffc0203250 <alloc_proc+0x58>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */

        proc->state=PROC_UNINIT;
ffffffffc020320a:	57fd                	li	a5,-1
ffffffffc020320c:	1782                	slli	a5,a5,0x20
ffffffffc020320e:	e11c                	sd	a5,0(a0)
        proc->runs=0;
        proc->kstack=0;
        proc->need_resched=0;
        proc->parent=NULL;
        proc->mm=NULL;
        memset(&(proc->context),0,sizeof(struct context));
ffffffffc0203210:	07000613          	li	a2,112
ffffffffc0203214:	4581                	li	a1,0
        proc->runs=0;
ffffffffc0203216:	00052423          	sw	zero,8(a0)
        proc->kstack=0;
ffffffffc020321a:	00053823          	sd	zero,16(a0)
        proc->need_resched=0;
ffffffffc020321e:	00052c23          	sw	zero,24(a0)
        proc->parent=NULL;
ffffffffc0203222:	02053023          	sd	zero,32(a0)
        proc->mm=NULL;
ffffffffc0203226:	02053423          	sd	zero,40(a0)
        memset(&(proc->context),0,sizeof(struct context));
ffffffffc020322a:	03050513          	addi	a0,a0,48
ffffffffc020322e:	425000ef          	jal	ra,ffffffffc0203e52 <memset>
        proc->tf=NULL;
        proc->pgdir=boot_pgdir_pa;
ffffffffc0203232:	0000a797          	auipc	a5,0xa
ffffffffc0203236:	26e7b783          	ld	a5,622(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
        proc->tf=NULL;
ffffffffc020323a:	0a043023          	sd	zero,160(s0)
        proc->pgdir=boot_pgdir_pa;
ffffffffc020323e:	f45c                	sd	a5,168(s0)
        proc->flags=0;
ffffffffc0203240:	0a042823          	sw	zero,176(s0)
        memset(proc->name,0,PROC_NAME_LEN+1);
ffffffffc0203244:	4641                	li	a2,16
ffffffffc0203246:	4581                	li	a1,0
ffffffffc0203248:	0b440513          	addi	a0,s0,180
ffffffffc020324c:	407000ef          	jal	ra,ffffffffc0203e52 <memset>
    }
    return proc;
}
ffffffffc0203250:	60a2                	ld	ra,8(sp)
ffffffffc0203252:	8522                	mv	a0,s0
ffffffffc0203254:	6402                	ld	s0,0(sp)
ffffffffc0203256:	0141                	addi	sp,sp,16
ffffffffc0203258:	8082                	ret

ffffffffc020325a <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc020325a:	0000a797          	auipc	a5,0xa
ffffffffc020325e:	2767b783          	ld	a5,630(a5) # ffffffffc020d4d0 <current>
ffffffffc0203262:	73c8                	ld	a0,160(a5)
ffffffffc0203264:	b69fd06f          	j	ffffffffc0200dcc <forkrets>

ffffffffc0203268 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203268:	7179                	addi	sp,sp,-48
ffffffffc020326a:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc020326c:	0000a497          	auipc	s1,0xa
ffffffffc0203270:	1dc48493          	addi	s1,s1,476 # ffffffffc020d448 <name.2>
{
ffffffffc0203274:	f022                	sd	s0,32(sp)
ffffffffc0203276:	e84a                	sd	s2,16(sp)
ffffffffc0203278:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020327a:	0000a917          	auipc	s2,0xa
ffffffffc020327e:	25693903          	ld	s2,598(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc0203282:	4641                	li	a2,16
ffffffffc0203284:	4581                	li	a1,0
ffffffffc0203286:	8526                	mv	a0,s1
{
ffffffffc0203288:	f406                	sd	ra,40(sp)
ffffffffc020328a:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020328c:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc0203290:	3c3000ef          	jal	ra,ffffffffc0203e52 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0203294:	0b490593          	addi	a1,s2,180
ffffffffc0203298:	463d                	li	a2,15
ffffffffc020329a:	8526                	mv	a0,s1
ffffffffc020329c:	3c9000ef          	jal	ra,ffffffffc0203e64 <memcpy>
ffffffffc02032a0:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032a2:	85ce                	mv	a1,s3
ffffffffc02032a4:	00002517          	auipc	a0,0x2
ffffffffc02032a8:	34c50513          	addi	a0,a0,844 # ffffffffc02055f0 <default_pmm_manager+0x920>
ffffffffc02032ac:	ee9fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032b0:	85a2                	mv	a1,s0
ffffffffc02032b2:	00002517          	auipc	a0,0x2
ffffffffc02032b6:	36650513          	addi	a0,a0,870 # ffffffffc0205618 <default_pmm_manager+0x948>
ffffffffc02032ba:	edbfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032be:	00002517          	auipc	a0,0x2
ffffffffc02032c2:	36a50513          	addi	a0,a0,874 # ffffffffc0205628 <default_pmm_manager+0x958>
ffffffffc02032c6:	ecffc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032ca:	70a2                	ld	ra,40(sp)
ffffffffc02032cc:	7402                	ld	s0,32(sp)
ffffffffc02032ce:	64e2                	ld	s1,24(sp)
ffffffffc02032d0:	6942                	ld	s2,16(sp)
ffffffffc02032d2:	69a2                	ld	s3,8(sp)
ffffffffc02032d4:	4501                	li	a0,0
ffffffffc02032d6:	6145                	addi	sp,sp,48
ffffffffc02032d8:	8082                	ret

ffffffffc02032da <proc_run>:
{
ffffffffc02032da:	7179                	addi	sp,sp,-48
ffffffffc02032dc:	ec26                	sd	s1,24(sp)
    if (proc != current)
ffffffffc02032de:	0000a497          	auipc	s1,0xa
ffffffffc02032e2:	1f248493          	addi	s1,s1,498 # ffffffffc020d4d0 <current>
ffffffffc02032e6:	609c                	ld	a5,0(s1)
{
ffffffffc02032e8:	f406                	sd	ra,40(sp)
ffffffffc02032ea:	f022                	sd	s0,32(sp)
ffffffffc02032ec:	e84a                	sd	s2,16(sp)
    if (proc != current)
ffffffffc02032ee:	02a78d63          	beq	a5,a0,ffffffffc0203328 <proc_run+0x4e>
ffffffffc02032f2:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032f4:	10002773          	csrr	a4,sstatus
ffffffffc02032f8:	8b09                	andi	a4,a4,2
        switch_to(&(prev->context),&(next->context));
ffffffffc02032fa:	03050593          	addi	a1,a0,48
ffffffffc02032fe:	ef21                	bnez	a4,ffffffffc0203356 <proc_run+0x7c>
        if(next->pgdir!=prev->pgdir){
ffffffffc0203300:	7558                	ld	a4,168(a0)
ffffffffc0203302:	77d4                	ld	a3,168(a5)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203304:	03078513          	addi	a0,a5,48
    return 0;
ffffffffc0203308:	4901                	li	s2,0
        if(next->pgdir!=prev->pgdir){
ffffffffc020330a:	02d70f63          	beq	a4,a3,ffffffffc0203348 <proc_run+0x6e>
            lsatp(next->pgdir>>12|SATP_MODE_SV39);
ffffffffc020330e:	8331                	srli	a4,a4,0xc
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203310:	800007b7          	lui	a5,0x80000
ffffffffc0203314:	00c7571b          	srliw	a4,a4,0xc
ffffffffc0203318:	8f5d                	or	a4,a4,a5
ffffffffc020331a:	18071073          	csrw	satp,a4
        current=next; //切换current指针
ffffffffc020331e:	e080                	sd	s0,0(s1)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203320:	55c000ef          	jal	ra,ffffffffc020387c <switch_to>
    if (flag) {
ffffffffc0203324:	00091b63          	bnez	s2,ffffffffc020333a <proc_run+0x60>
}
ffffffffc0203328:	70a2                	ld	ra,40(sp)
ffffffffc020332a:	7402                	ld	s0,32(sp)
ffffffffc020332c:	64e2                	ld	s1,24(sp)
ffffffffc020332e:	6942                	ld	s2,16(sp)
ffffffffc0203330:	6145                	addi	sp,sp,48
ffffffffc0203332:	8082                	ret
        current=next; //切换current指针
ffffffffc0203334:	e080                	sd	s0,0(s1)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203336:	546000ef          	jal	ra,ffffffffc020387c <switch_to>
}
ffffffffc020333a:	7402                	ld	s0,32(sp)
ffffffffc020333c:	70a2                	ld	ra,40(sp)
ffffffffc020333e:	64e2                	ld	s1,24(sp)
ffffffffc0203340:	6942                	ld	s2,16(sp)
ffffffffc0203342:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203344:	de6fd06f          	j	ffffffffc020092a <intr_enable>
        current=next; //切换current指针
ffffffffc0203348:	e080                	sd	s0,0(s1)
}
ffffffffc020334a:	7402                	ld	s0,32(sp)
ffffffffc020334c:	70a2                	ld	ra,40(sp)
ffffffffc020334e:	64e2                	ld	s1,24(sp)
ffffffffc0203350:	6942                	ld	s2,16(sp)
ffffffffc0203352:	6145                	addi	sp,sp,48
        switch_to(&(prev->context),&(next->context));
ffffffffc0203354:	a325                	j	ffffffffc020387c <switch_to>
ffffffffc0203356:	e42e                	sd	a1,8(sp)
        intr_disable();
ffffffffc0203358:	dd8fd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        struct proc_struct *prev=current; //记录之前的进程
ffffffffc020335c:	6088                	ld	a0,0(s1)
        if(next->pgdir!=prev->pgdir){
ffffffffc020335e:	7458                	ld	a4,168(s0)
ffffffffc0203360:	65a2                	ld	a1,8(sp)
ffffffffc0203362:	755c                	ld	a5,168(a0)
        switch_to(&(prev->context),&(next->context));
ffffffffc0203364:	03050513          	addi	a0,a0,48
        if(next->pgdir!=prev->pgdir){
ffffffffc0203368:	fcf706e3          	beq	a4,a5,ffffffffc0203334 <proc_run+0x5a>
        return 1;
ffffffffc020336c:	4905                	li	s2,1
ffffffffc020336e:	b745                	j	ffffffffc020330e <proc_run+0x34>

ffffffffc0203370 <do_fork>:
{
ffffffffc0203370:	7179                	addi	sp,sp,-48
ffffffffc0203372:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203374:	0000a497          	auipc	s1,0xa
ffffffffc0203378:	17448493          	addi	s1,s1,372 # ffffffffc020d4e8 <nr_process>
ffffffffc020337c:	4098                	lw	a4,0(s1)
{
ffffffffc020337e:	f406                	sd	ra,40(sp)
ffffffffc0203380:	f022                	sd	s0,32(sp)
ffffffffc0203382:	e84a                	sd	s2,16(sp)
ffffffffc0203384:	e44e                	sd	s3,8(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203386:	6785                	lui	a5,0x1
ffffffffc0203388:	1cf75c63          	bge	a4,a5,ffffffffc0203560 <do_fork+0x1f0>
ffffffffc020338c:	892e                	mv	s2,a1
ffffffffc020338e:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc0203390:	e69ff0ef          	jal	ra,ffffffffc02031f8 <alloc_proc>
ffffffffc0203394:	89aa                	mv	s3,a0
    if (proc == NULL) {
ffffffffc0203396:	1c050a63          	beqz	a0,ffffffffc020356a <do_fork+0x1fa>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020339a:	4509                	li	a0,2
ffffffffc020339c:	8e5fe0ef          	jal	ra,ffffffffc0201c80 <alloc_pages>
    if (page != NULL)
ffffffffc02033a0:	1a050b63          	beqz	a0,ffffffffc0203556 <do_fork+0x1e6>
    return page - pages + nbase;
ffffffffc02033a4:	0000a697          	auipc	a3,0xa
ffffffffc02033a8:	1146b683          	ld	a3,276(a3) # ffffffffc020d4b8 <pages>
ffffffffc02033ac:	40d506b3          	sub	a3,a0,a3
ffffffffc02033b0:	8699                	srai	a3,a3,0x6
ffffffffc02033b2:	00002517          	auipc	a0,0x2
ffffffffc02033b6:	63653503          	ld	a0,1590(a0) # ffffffffc02059e8 <nbase>
ffffffffc02033ba:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033bc:	00c69793          	slli	a5,a3,0xc
ffffffffc02033c0:	83b1                	srli	a5,a5,0xc
ffffffffc02033c2:	0000a717          	auipc	a4,0xa
ffffffffc02033c6:	0ee73703          	ld	a4,238(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033ca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033cc:	1ce7f163          	bgeu	a5,a4,ffffffffc020358e <do_fork+0x21e>
    assert(current->mm == NULL);
ffffffffc02033d0:	0000ae17          	auipc	t3,0xa
ffffffffc02033d4:	100e3e03          	ld	t3,256(t3) # ffffffffc020d4d0 <current>
ffffffffc02033d8:	028e3783          	ld	a5,40(t3)
ffffffffc02033dc:	0000a717          	auipc	a4,0xa
ffffffffc02033e0:	0ec73703          	ld	a4,236(a4) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc02033e4:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033e6:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc02033ea:	18079263          	bnez	a5,ffffffffc020356e <do_fork+0x1fe>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033ee:	6789                	lui	a5,0x2
ffffffffc02033f0:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033f4:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02033f6:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033f8:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc02033fc:	87b6                	mv	a5,a3
ffffffffc02033fe:	12040893          	addi	a7,s0,288
ffffffffc0203402:	00063803          	ld	a6,0(a2)
ffffffffc0203406:	6608                	ld	a0,8(a2)
ffffffffc0203408:	6a0c                	ld	a1,16(a2)
ffffffffc020340a:	6e18                	ld	a4,24(a2)
ffffffffc020340c:	0107b023          	sd	a6,0(a5)
ffffffffc0203410:	e788                	sd	a0,8(a5)
ffffffffc0203412:	eb8c                	sd	a1,16(a5)
ffffffffc0203414:	ef98                	sd	a4,24(a5)
ffffffffc0203416:	02060613          	addi	a2,a2,32
ffffffffc020341a:	02078793          	addi	a5,a5,32
ffffffffc020341e:	ff1612e3          	bne	a2,a7,ffffffffc0203402 <do_fork+0x92>
    proc->tf->gpr.a0 = 0;
ffffffffc0203422:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203426:	10090b63          	beqz	s2,ffffffffc020353c <do_fork+0x1cc>
    if (++last_pid >= MAX_PID)
ffffffffc020342a:	00006317          	auipc	t1,0x6
ffffffffc020342e:	bfe30313          	addi	t1,t1,-1026 # ffffffffc0209028 <last_pid.1>
ffffffffc0203432:	00032783          	lw	a5,0(t1)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203436:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020343a:	00000717          	auipc	a4,0x0
ffffffffc020343e:	e2070713          	addi	a4,a4,-480 # ffffffffc020325a <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0203442:	0017851b          	addiw	a0,a5,1
ffffffffc0203446:	0000a617          	auipc	a2,0xa
ffffffffc020344a:	01260613          	addi	a2,a2,18 # ffffffffc020d458 <proc_list>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020344e:	02e9b823          	sd	a4,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203452:	02d9bc23          	sd	a3,56(s3)
    proc->parent = current;
ffffffffc0203456:	03c9b023          	sd	t3,32(s3)
    if (++last_pid >= MAX_PID)
ffffffffc020345a:	00a32023          	sw	a0,0(t1)
ffffffffc020345e:	6789                	lui	a5,0x2
ffffffffc0203460:	00863883          	ld	a7,8(a2)
ffffffffc0203464:	06f55a63          	bge	a0,a5,ffffffffc02034d8 <do_fork+0x168>
    if (last_pid >= next_safe)
ffffffffc0203468:	00006e97          	auipc	t4,0x6
ffffffffc020346c:	bc4e8e93          	addi	t4,t4,-1084 # ffffffffc020902c <next_safe.0>
ffffffffc0203470:	000ea783          	lw	a5,0(t4)
ffffffffc0203474:	06f55a63          	bge	a0,a5,ffffffffc02034e8 <do_fork+0x178>
    proc->pid = get_pid();
ffffffffc0203478:	00a9a223          	sw	a0,4(s3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020347c:	0c898793          	addi	a5,s3,200
    prev->next = next->prev = elm;
ffffffffc0203480:	00f8b023          	sd	a5,0(a7)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203484:	45a9                	li	a1,10
    elm->next = next;
ffffffffc0203486:	0d19b823          	sd	a7,208(s3)
    elm->prev = prev;
ffffffffc020348a:	0cc9b423          	sd	a2,200(s3)
ffffffffc020348e:	2501                	sext.w	a0,a0
    prev->next = next->prev = elm;
ffffffffc0203490:	e61c                	sd	a5,8(a2)
ffffffffc0203492:	51a000ef          	jal	ra,ffffffffc02039ac <hash32>
ffffffffc0203496:	02051713          	slli	a4,a0,0x20
ffffffffc020349a:	01c75793          	srli	a5,a4,0x1c
ffffffffc020349e:	00006517          	auipc	a0,0x6
ffffffffc02034a2:	faa50513          	addi	a0,a0,-86 # ffffffffc0209448 <hash_list>
ffffffffc02034a6:	97aa                	add	a5,a5,a0
    __list_add(elm, listelm, listelm->next);
ffffffffc02034a8:	6798                	ld	a4,8(a5)
ffffffffc02034aa:	0d898693          	addi	a3,s3,216
    wakeup_proc(proc);
ffffffffc02034ae:	854e                	mv	a0,s3
    prev->next = next->prev = elm;
ffffffffc02034b0:	e314                	sd	a3,0(a4)
ffffffffc02034b2:	e794                	sd	a3,8(a5)
    elm->prev = prev;
ffffffffc02034b4:	0cf9bc23          	sd	a5,216(s3)
    elm->next = next;
ffffffffc02034b8:	0ee9b023          	sd	a4,224(s3)
ffffffffc02034bc:	42a000ef          	jal	ra,ffffffffc02038e6 <wakeup_proc>
    nr_process++;
ffffffffc02034c0:	409c                	lw	a5,0(s1)
    ret = proc->pid;
ffffffffc02034c2:	0049a503          	lw	a0,4(s3)
    nr_process++;
ffffffffc02034c6:	2785                	addiw	a5,a5,1
ffffffffc02034c8:	c09c                	sw	a5,0(s1)
}
ffffffffc02034ca:	70a2                	ld	ra,40(sp)
ffffffffc02034cc:	7402                	ld	s0,32(sp)
ffffffffc02034ce:	64e2                	ld	s1,24(sp)
ffffffffc02034d0:	6942                	ld	s2,16(sp)
ffffffffc02034d2:	69a2                	ld	s3,8(sp)
ffffffffc02034d4:	6145                	addi	sp,sp,48
ffffffffc02034d6:	8082                	ret
        last_pid = 1;
ffffffffc02034d8:	4785                	li	a5,1
ffffffffc02034da:	00f32023          	sw	a5,0(t1)
        goto inside;
ffffffffc02034de:	4505                	li	a0,1
ffffffffc02034e0:	00006e97          	auipc	t4,0x6
ffffffffc02034e4:	b4ce8e93          	addi	t4,t4,-1204 # ffffffffc020902c <next_safe.0>
        next_safe = MAX_PID;
ffffffffc02034e8:	6789                	lui	a5,0x2
ffffffffc02034ea:	00fea023          	sw	a5,0(t4)
ffffffffc02034ee:	86aa                	mv	a3,a0
ffffffffc02034f0:	4801                	li	a6,0
        while ((le = list_next(le)) != list) // 遍历proc_list链表，寻找pid冲突
ffffffffc02034f2:	6f09                	lui	t5,0x2
ffffffffc02034f4:	04c88b63          	beq	a7,a2,ffffffffc020354a <do_fork+0x1da>
ffffffffc02034f8:	8e42                	mv	t3,a6
ffffffffc02034fa:	87c6                	mv	a5,a7
ffffffffc02034fc:	6589                	lui	a1,0x2
ffffffffc02034fe:	a811                	j	ffffffffc0203512 <do_fork+0x1a2>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203500:	00e6d663          	bge	a3,a4,ffffffffc020350c <do_fork+0x19c>
ffffffffc0203504:	00b75463          	bge	a4,a1,ffffffffc020350c <do_fork+0x19c>
ffffffffc0203508:	85ba                	mv	a1,a4
ffffffffc020350a:	4e05                	li	t3,1
    return listelm->next;
ffffffffc020350c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) // 遍历proc_list链表，寻找pid冲突
ffffffffc020350e:	00c78d63          	beq	a5,a2,ffffffffc0203528 <do_fork+0x1b8>
            if (proc->pid == last_pid) // proc->pid与last_pid冲突，last_pid++，尝试下一个PID
ffffffffc0203512:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0203516:	fed715e3          	bne	a4,a3,ffffffffc0203500 <do_fork+0x190>
                if (++last_pid >= next_safe) // last_pid达到next_safe，说明需要重新遍历链表寻找下一个安全的PID
ffffffffc020351a:	2685                	addiw	a3,a3,1
ffffffffc020351c:	02b6d263          	bge	a3,a1,ffffffffc0203540 <do_fork+0x1d0>
ffffffffc0203520:	679c                	ld	a5,8(a5)
ffffffffc0203522:	4805                	li	a6,1
        while ((le = list_next(le)) != list) // 遍历proc_list链表，寻找pid冲突
ffffffffc0203524:	fec797e3          	bne	a5,a2,ffffffffc0203512 <do_fork+0x1a2>
ffffffffc0203528:	00080563          	beqz	a6,ffffffffc0203532 <do_fork+0x1c2>
ffffffffc020352c:	00d32023          	sw	a3,0(t1)
ffffffffc0203530:	8536                	mv	a0,a3
ffffffffc0203532:	f40e03e3          	beqz	t3,ffffffffc0203478 <do_fork+0x108>
ffffffffc0203536:	00bea023          	sw	a1,0(t4)
ffffffffc020353a:	bf3d                	j	ffffffffc0203478 <do_fork+0x108>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020353c:	8936                	mv	s2,a3
ffffffffc020353e:	b5f5                	j	ffffffffc020342a <do_fork+0xba>
                    if (last_pid >= MAX_PID)
ffffffffc0203540:	01e6c363          	blt	a3,t5,ffffffffc0203546 <do_fork+0x1d6>
                        last_pid = 1;
ffffffffc0203544:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203546:	4805                	li	a6,1
ffffffffc0203548:	b775                	j	ffffffffc02034f4 <do_fork+0x184>
ffffffffc020354a:	00080d63          	beqz	a6,ffffffffc0203564 <do_fork+0x1f4>
ffffffffc020354e:	00d32023          	sw	a3,0(t1)
    return last_pid;
ffffffffc0203552:	8536                	mv	a0,a3
ffffffffc0203554:	b715                	j	ffffffffc0203478 <do_fork+0x108>
    kfree(proc);
ffffffffc0203556:	854e                	mv	a0,s3
ffffffffc0203558:	dfafe0ef          	jal	ra,ffffffffc0201b52 <kfree>
    ret = -E_NO_MEM;
ffffffffc020355c:	5571                	li	a0,-4
    goto fork_out;
ffffffffc020355e:	b7b5                	j	ffffffffc02034ca <do_fork+0x15a>
    int ret = -E_NO_FREE_PROC;
ffffffffc0203560:	556d                	li	a0,-5
ffffffffc0203562:	b7a5                	j	ffffffffc02034ca <do_fork+0x15a>
    return last_pid;
ffffffffc0203564:	00032503          	lw	a0,0(t1)
ffffffffc0203568:	bf01                	j	ffffffffc0203478 <do_fork+0x108>
    ret = -E_NO_MEM;
ffffffffc020356a:	5571                	li	a0,-4
    return ret;
ffffffffc020356c:	bfb9                	j	ffffffffc02034ca <do_fork+0x15a>
    assert(current->mm == NULL);
ffffffffc020356e:	00002697          	auipc	a3,0x2
ffffffffc0203572:	0da68693          	addi	a3,a3,218 # ffffffffc0205648 <default_pmm_manager+0x978>
ffffffffc0203576:	00001617          	auipc	a2,0x1
ffffffffc020357a:	3a260613          	addi	a2,a2,930 # ffffffffc0204918 <commands+0x810>
ffffffffc020357e:	12c00593          	li	a1,300
ffffffffc0203582:	00002517          	auipc	a0,0x2
ffffffffc0203586:	0de50513          	addi	a0,a0,222 # ffffffffc0205660 <default_pmm_manager+0x990>
ffffffffc020358a:	ed1fc0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc020358e:	00001617          	auipc	a2,0x1
ffffffffc0203592:	77a60613          	addi	a2,a2,1914 # ffffffffc0204d08 <default_pmm_manager+0x38>
ffffffffc0203596:	07100593          	li	a1,113
ffffffffc020359a:	00001517          	auipc	a0,0x1
ffffffffc020359e:	79650513          	addi	a0,a0,1942 # ffffffffc0204d30 <default_pmm_manager+0x60>
ffffffffc02035a2:	eb9fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02035a6 <kernel_thread>:
{
ffffffffc02035a6:	7129                	addi	sp,sp,-320
ffffffffc02035a8:	fa22                	sd	s0,304(sp)
ffffffffc02035aa:	f626                	sd	s1,296(sp)
ffffffffc02035ac:	f24a                	sd	s2,288(sp)
ffffffffc02035ae:	84ae                	mv	s1,a1
ffffffffc02035b0:	892a                	mv	s2,a0
ffffffffc02035b2:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035b4:	4581                	li	a1,0
ffffffffc02035b6:	12000613          	li	a2,288
ffffffffc02035ba:	850a                	mv	a0,sp
{
ffffffffc02035bc:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035be:	095000ef          	jal	ra,ffffffffc0203e52 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02035c2:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02035c4:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02035c6:	100027f3          	csrr	a5,sstatus
ffffffffc02035ca:	edd7f793          	andi	a5,a5,-291
ffffffffc02035ce:	1207e793          	ori	a5,a5,288
ffffffffc02035d2:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035d4:	860a                	mv	a2,sp
ffffffffc02035d6:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035da:	00000797          	auipc	a5,0x0
ffffffffc02035de:	c1678793          	addi	a5,a5,-1002 # ffffffffc02031f0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035e2:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035e4:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035e6:	d8bff0ef          	jal	ra,ffffffffc0203370 <do_fork>
}
ffffffffc02035ea:	70f2                	ld	ra,312(sp)
ffffffffc02035ec:	7452                	ld	s0,304(sp)
ffffffffc02035ee:	74b2                	ld	s1,296(sp)
ffffffffc02035f0:	7912                	ld	s2,288(sp)
ffffffffc02035f2:	6131                	addi	sp,sp,320
ffffffffc02035f4:	8082                	ret

ffffffffc02035f6 <do_exit>:
{
ffffffffc02035f6:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02035f8:	00002617          	auipc	a2,0x2
ffffffffc02035fc:	08060613          	addi	a2,a2,128 # ffffffffc0205678 <default_pmm_manager+0x9a8>
ffffffffc0203600:	18b00593          	li	a1,395
ffffffffc0203604:	00002517          	auipc	a0,0x2
ffffffffc0203608:	05c50513          	addi	a0,a0,92 # ffffffffc0205660 <default_pmm_manager+0x990>
{
ffffffffc020360c:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc020360e:	e4dfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203612 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0203612:	7179                	addi	sp,sp,-48
ffffffffc0203614:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203616:	0000a797          	auipc	a5,0xa
ffffffffc020361a:	e4278793          	addi	a5,a5,-446 # ffffffffc020d458 <proc_list>
ffffffffc020361e:	f406                	sd	ra,40(sp)
ffffffffc0203620:	f022                	sd	s0,32(sp)
ffffffffc0203622:	e84a                	sd	s2,16(sp)
ffffffffc0203624:	e44e                	sd	s3,8(sp)
ffffffffc0203626:	00006497          	auipc	s1,0x6
ffffffffc020362a:	e2248493          	addi	s1,s1,-478 # ffffffffc0209448 <hash_list>
ffffffffc020362e:	e79c                	sd	a5,8(a5)
ffffffffc0203630:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203632:	0000a717          	auipc	a4,0xa
ffffffffc0203636:	e1670713          	addi	a4,a4,-490 # ffffffffc020d448 <name.2>
ffffffffc020363a:	87a6                	mv	a5,s1
ffffffffc020363c:	e79c                	sd	a5,8(a5)
ffffffffc020363e:	e39c                	sd	a5,0(a5)
ffffffffc0203640:	07c1                	addi	a5,a5,16
ffffffffc0203642:	fef71de3          	bne	a4,a5,ffffffffc020363c <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203646:	bb3ff0ef          	jal	ra,ffffffffc02031f8 <alloc_proc>
ffffffffc020364a:	0000a917          	auipc	s2,0xa
ffffffffc020364e:	e8e90913          	addi	s2,s2,-370 # ffffffffc020d4d8 <idleproc>
ffffffffc0203652:	00a93023          	sd	a0,0(s2)
ffffffffc0203656:	18050d63          	beqz	a0,ffffffffc02037f0 <proc_init+0x1de>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020365a:	07000513          	li	a0,112
ffffffffc020365e:	c44fe0ef          	jal	ra,ffffffffc0201aa2 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203662:	07000613          	li	a2,112
ffffffffc0203666:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203668:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020366a:	7e8000ef          	jal	ra,ffffffffc0203e52 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020366e:	00093503          	ld	a0,0(s2)
ffffffffc0203672:	85a2                	mv	a1,s0
ffffffffc0203674:	07000613          	li	a2,112
ffffffffc0203678:	03050513          	addi	a0,a0,48
ffffffffc020367c:	001000ef          	jal	ra,ffffffffc0203e7c <memcmp>
ffffffffc0203680:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203682:	453d                	li	a0,15
ffffffffc0203684:	c1efe0ef          	jal	ra,ffffffffc0201aa2 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203688:	463d                	li	a2,15
ffffffffc020368a:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020368c:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020368e:	7c4000ef          	jal	ra,ffffffffc0203e52 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0203692:	00093503          	ld	a0,0(s2)
ffffffffc0203696:	463d                	li	a2,15
ffffffffc0203698:	85a2                	mv	a1,s0
ffffffffc020369a:	0b450513          	addi	a0,a0,180
ffffffffc020369e:	7de000ef          	jal	ra,ffffffffc0203e7c <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc02036a2:	00093783          	ld	a5,0(s2)
ffffffffc02036a6:	0000a717          	auipc	a4,0xa
ffffffffc02036aa:	dfa73703          	ld	a4,-518(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc02036ae:	77d4                	ld	a3,168(a5)
ffffffffc02036b0:	0ee68463          	beq	a3,a4,ffffffffc0203798 <proc_init+0x186>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02036b4:	4709                	li	a4,2
ffffffffc02036b6:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036b8:	00003717          	auipc	a4,0x3
ffffffffc02036bc:	94870713          	addi	a4,a4,-1720 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036c0:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036c4:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02036c6:	4705                	li	a4,1
ffffffffc02036c8:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036ca:	4641                	li	a2,16
ffffffffc02036cc:	4581                	li	a1,0
ffffffffc02036ce:	8522                	mv	a0,s0
ffffffffc02036d0:	782000ef          	jal	ra,ffffffffc0203e52 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036d4:	463d                	li	a2,15
ffffffffc02036d6:	00002597          	auipc	a1,0x2
ffffffffc02036da:	fea58593          	addi	a1,a1,-22 # ffffffffc02056c0 <default_pmm_manager+0x9f0>
ffffffffc02036de:	8522                	mv	a0,s0
ffffffffc02036e0:	784000ef          	jal	ra,ffffffffc0203e64 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02036e4:	0000a717          	auipc	a4,0xa
ffffffffc02036e8:	e0470713          	addi	a4,a4,-508 # ffffffffc020d4e8 <nr_process>
ffffffffc02036ec:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02036ee:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036f2:	4601                	li	a2,0
    nr_process++;
ffffffffc02036f4:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036f6:	00002597          	auipc	a1,0x2
ffffffffc02036fa:	fd258593          	addi	a1,a1,-46 # ffffffffc02056c8 <default_pmm_manager+0x9f8>
ffffffffc02036fe:	00000517          	auipc	a0,0x0
ffffffffc0203702:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0203268 <init_main>
    nr_process++;
ffffffffc0203706:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0203708:	0000a797          	auipc	a5,0xa
ffffffffc020370c:	dcd7b423          	sd	a3,-568(a5) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0203710:	e97ff0ef          	jal	ra,ffffffffc02035a6 <kernel_thread>
ffffffffc0203714:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203716:	0ea05963          	blez	a0,ffffffffc0203808 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc020371a:	6789                	lui	a5,0x2
ffffffffc020371c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203720:	17f9                	addi	a5,a5,-2
ffffffffc0203722:	2501                	sext.w	a0,a0
ffffffffc0203724:	02e7e363          	bltu	a5,a4,ffffffffc020374a <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203728:	45a9                	li	a1,10
ffffffffc020372a:	282000ef          	jal	ra,ffffffffc02039ac <hash32>
ffffffffc020372e:	02051793          	slli	a5,a0,0x20
ffffffffc0203732:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0203736:	96a6                	add	a3,a3,s1
ffffffffc0203738:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020373a:	a029                	j	ffffffffc0203744 <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc020373c:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0203740:	0a870563          	beq	a4,s0,ffffffffc02037ea <proc_init+0x1d8>
    return listelm->next;
ffffffffc0203744:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203746:	fef69be3          	bne	a3,a5,ffffffffc020373c <proc_init+0x12a>
    return NULL;
ffffffffc020374a:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020374c:	0b478493          	addi	s1,a5,180
ffffffffc0203750:	4641                	li	a2,16
ffffffffc0203752:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203754:	0000a417          	auipc	s0,0xa
ffffffffc0203758:	d8c40413          	addi	s0,s0,-628 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020375c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020375e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203760:	6f2000ef          	jal	ra,ffffffffc0203e52 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203764:	463d                	li	a2,15
ffffffffc0203766:	00002597          	auipc	a1,0x2
ffffffffc020376a:	f9258593          	addi	a1,a1,-110 # ffffffffc02056f8 <default_pmm_manager+0xa28>
ffffffffc020376e:	8526                	mv	a0,s1
ffffffffc0203770:	6f4000ef          	jal	ra,ffffffffc0203e64 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203774:	00093783          	ld	a5,0(s2)
ffffffffc0203778:	c7e1                	beqz	a5,ffffffffc0203840 <proc_init+0x22e>
ffffffffc020377a:	43dc                	lw	a5,4(a5)
ffffffffc020377c:	e3f1                	bnez	a5,ffffffffc0203840 <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020377e:	601c                	ld	a5,0(s0)
ffffffffc0203780:	c3c5                	beqz	a5,ffffffffc0203820 <proc_init+0x20e>
ffffffffc0203782:	43d8                	lw	a4,4(a5)
ffffffffc0203784:	4785                	li	a5,1
ffffffffc0203786:	08f71d63          	bne	a4,a5,ffffffffc0203820 <proc_init+0x20e>
}
ffffffffc020378a:	70a2                	ld	ra,40(sp)
ffffffffc020378c:	7402                	ld	s0,32(sp)
ffffffffc020378e:	64e2                	ld	s1,24(sp)
ffffffffc0203790:	6942                	ld	s2,16(sp)
ffffffffc0203792:	69a2                	ld	s3,8(sp)
ffffffffc0203794:	6145                	addi	sp,sp,48
ffffffffc0203796:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203798:	73d8                	ld	a4,160(a5)
ffffffffc020379a:	ff09                	bnez	a4,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc020379c:	f0099ce3          	bnez	s3,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc02037a0:	6394                	ld	a3,0(a5)
ffffffffc02037a2:	577d                	li	a4,-1
ffffffffc02037a4:	1702                	slli	a4,a4,0x20
ffffffffc02037a6:	f0e697e3          	bne	a3,a4,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc02037aa:	4798                	lw	a4,8(a5)
ffffffffc02037ac:	f00714e3          	bnez	a4,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc02037b0:	6b98                	ld	a4,16(a5)
ffffffffc02037b2:	f00711e3          	bnez	a4,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc02037b6:	4f98                	lw	a4,24(a5)
ffffffffc02037b8:	2701                	sext.w	a4,a4
ffffffffc02037ba:	ee071de3          	bnez	a4,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc02037be:	7398                	ld	a4,32(a5)
ffffffffc02037c0:	ee071ae3          	bnez	a4,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc02037c4:	7798                	ld	a4,40(a5)
ffffffffc02037c6:	ee0717e3          	bnez	a4,ffffffffc02036b4 <proc_init+0xa2>
ffffffffc02037ca:	0b07a703          	lw	a4,176(a5)
ffffffffc02037ce:	8d59                	or	a0,a0,a4
ffffffffc02037d0:	0005071b          	sext.w	a4,a0
ffffffffc02037d4:	ee0710e3          	bnez	a4,ffffffffc02036b4 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc02037d8:	00002517          	auipc	a0,0x2
ffffffffc02037dc:	ed050513          	addi	a0,a0,-304 # ffffffffc02056a8 <default_pmm_manager+0x9d8>
ffffffffc02037e0:	9b5fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc02037e4:	00093783          	ld	a5,0(s2)
ffffffffc02037e8:	b5f1                	j	ffffffffc02036b4 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02037ea:	f2878793          	addi	a5,a5,-216
ffffffffc02037ee:	bfb9                	j	ffffffffc020374c <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc02037f0:	00002617          	auipc	a2,0x2
ffffffffc02037f4:	ea060613          	addi	a2,a2,-352 # ffffffffc0205690 <default_pmm_manager+0x9c0>
ffffffffc02037f8:	1a600593          	li	a1,422
ffffffffc02037fc:	00002517          	auipc	a0,0x2
ffffffffc0203800:	e6450513          	addi	a0,a0,-412 # ffffffffc0205660 <default_pmm_manager+0x990>
ffffffffc0203804:	c57fc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc0203808:	00002617          	auipc	a2,0x2
ffffffffc020380c:	ed060613          	addi	a2,a2,-304 # ffffffffc02056d8 <default_pmm_manager+0xa08>
ffffffffc0203810:	1c300593          	li	a1,451
ffffffffc0203814:	00002517          	auipc	a0,0x2
ffffffffc0203818:	e4c50513          	addi	a0,a0,-436 # ffffffffc0205660 <default_pmm_manager+0x990>
ffffffffc020381c:	c3ffc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203820:	00002697          	auipc	a3,0x2
ffffffffc0203824:	f0868693          	addi	a3,a3,-248 # ffffffffc0205728 <default_pmm_manager+0xa58>
ffffffffc0203828:	00001617          	auipc	a2,0x1
ffffffffc020382c:	0f060613          	addi	a2,a2,240 # ffffffffc0204918 <commands+0x810>
ffffffffc0203830:	1ca00593          	li	a1,458
ffffffffc0203834:	00002517          	auipc	a0,0x2
ffffffffc0203838:	e2c50513          	addi	a0,a0,-468 # ffffffffc0205660 <default_pmm_manager+0x990>
ffffffffc020383c:	c1ffc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203840:	00002697          	auipc	a3,0x2
ffffffffc0203844:	ec068693          	addi	a3,a3,-320 # ffffffffc0205700 <default_pmm_manager+0xa30>
ffffffffc0203848:	00001617          	auipc	a2,0x1
ffffffffc020384c:	0d060613          	addi	a2,a2,208 # ffffffffc0204918 <commands+0x810>
ffffffffc0203850:	1c900593          	li	a1,457
ffffffffc0203854:	00002517          	auipc	a0,0x2
ffffffffc0203858:	e0c50513          	addi	a0,a0,-500 # ffffffffc0205660 <default_pmm_manager+0x990>
ffffffffc020385c:	bfffc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203860 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203860:	1141                	addi	sp,sp,-16
ffffffffc0203862:	e022                	sd	s0,0(sp)
ffffffffc0203864:	e406                	sd	ra,8(sp)
ffffffffc0203866:	0000a417          	auipc	s0,0xa
ffffffffc020386a:	c6a40413          	addi	s0,s0,-918 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020386e:	6018                	ld	a4,0(s0)
ffffffffc0203870:	4f1c                	lw	a5,24(a4)
ffffffffc0203872:	2781                	sext.w	a5,a5
ffffffffc0203874:	dff5                	beqz	a5,ffffffffc0203870 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0203876:	0a2000ef          	jal	ra,ffffffffc0203918 <schedule>
ffffffffc020387a:	bfd5                	j	ffffffffc020386e <cpu_idle+0xe>

ffffffffc020387c <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020387c:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0203880:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203884:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203886:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0203888:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020388c:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0203890:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203894:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0203898:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020389c:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02038a0:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02038a4:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02038a8:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02038ac:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02038b0:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02038b4:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02038b8:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038ba:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038bc:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038c0:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02038c4:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02038c8:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02038cc:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02038d0:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02038d4:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02038d8:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02038dc:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02038e0:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02038e4:	8082                	ret

ffffffffc02038e6 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038e6:	411c                	lw	a5,0(a0)
ffffffffc02038e8:	4705                	li	a4,1
ffffffffc02038ea:	37f9                	addiw	a5,a5,-2
ffffffffc02038ec:	00f77563          	bgeu	a4,a5,ffffffffc02038f6 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02038f0:	4789                	li	a5,2
ffffffffc02038f2:	c11c                	sw	a5,0(a0)
ffffffffc02038f4:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038f6:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038f8:	00002697          	auipc	a3,0x2
ffffffffc02038fc:	e5868693          	addi	a3,a3,-424 # ffffffffc0205750 <default_pmm_manager+0xa80>
ffffffffc0203900:	00001617          	auipc	a2,0x1
ffffffffc0203904:	01860613          	addi	a2,a2,24 # ffffffffc0204918 <commands+0x810>
ffffffffc0203908:	45a5                	li	a1,9
ffffffffc020390a:	00002517          	auipc	a0,0x2
ffffffffc020390e:	e8650513          	addi	a0,a0,-378 # ffffffffc0205790 <default_pmm_manager+0xac0>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203912:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203914:	b47fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203918 <schedule>:
}

void
schedule(void) {
ffffffffc0203918:	1141                	addi	sp,sp,-16
ffffffffc020391a:	e406                	sd	ra,8(sp)
ffffffffc020391c:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020391e:	100027f3          	csrr	a5,sstatus
ffffffffc0203922:	8b89                	andi	a5,a5,2
ffffffffc0203924:	4401                	li	s0,0
ffffffffc0203926:	efbd                	bnez	a5,ffffffffc02039a4 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203928:	0000a897          	auipc	a7,0xa
ffffffffc020392c:	ba88b883          	ld	a7,-1112(a7) # ffffffffc020d4d0 <current>
ffffffffc0203930:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203934:	0000a517          	auipc	a0,0xa
ffffffffc0203938:	ba453503          	ld	a0,-1116(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc020393c:	04a88e63          	beq	a7,a0,ffffffffc0203998 <schedule+0x80>
ffffffffc0203940:	0c888693          	addi	a3,a7,200
ffffffffc0203944:	0000a617          	auipc	a2,0xa
ffffffffc0203948:	b1460613          	addi	a2,a2,-1260 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc020394c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020394e:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203950:	4809                	li	a6,2
ffffffffc0203952:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203954:	00c78863          	beq	a5,a2,ffffffffc0203964 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203958:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020395c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203960:	03070163          	beq	a4,a6,ffffffffc0203982 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203964:	fef697e3          	bne	a3,a5,ffffffffc0203952 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203968:	ed89                	bnez	a1,ffffffffc0203982 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020396a:	451c                	lw	a5,8(a0)
ffffffffc020396c:	2785                	addiw	a5,a5,1
ffffffffc020396e:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0203970:	00a88463          	beq	a7,a0,ffffffffc0203978 <schedule+0x60>
            proc_run(next);
ffffffffc0203974:	967ff0ef          	jal	ra,ffffffffc02032da <proc_run>
    if (flag) {
ffffffffc0203978:	e819                	bnez	s0,ffffffffc020398e <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020397a:	60a2                	ld	ra,8(sp)
ffffffffc020397c:	6402                	ld	s0,0(sp)
ffffffffc020397e:	0141                	addi	sp,sp,16
ffffffffc0203980:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203982:	4198                	lw	a4,0(a1)
ffffffffc0203984:	4789                	li	a5,2
ffffffffc0203986:	fef712e3          	bne	a4,a5,ffffffffc020396a <schedule+0x52>
ffffffffc020398a:	852e                	mv	a0,a1
ffffffffc020398c:	bff9                	j	ffffffffc020396a <schedule+0x52>
}
ffffffffc020398e:	6402                	ld	s0,0(sp)
ffffffffc0203990:	60a2                	ld	ra,8(sp)
ffffffffc0203992:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203994:	f97fc06f          	j	ffffffffc020092a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203998:	0000a617          	auipc	a2,0xa
ffffffffc020399c:	ac060613          	addi	a2,a2,-1344 # ffffffffc020d458 <proc_list>
ffffffffc02039a0:	86b2                	mv	a3,a2
ffffffffc02039a2:	b76d                	j	ffffffffc020394c <schedule+0x34>
        intr_disable();
ffffffffc02039a4:	f8dfc0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc02039a8:	4405                	li	s0,1
ffffffffc02039aa:	bfbd                	j	ffffffffc0203928 <schedule+0x10>

ffffffffc02039ac <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02039ac:	9e3707b7          	lui	a5,0x9e370
ffffffffc02039b0:	2785                	addiw	a5,a5,1
ffffffffc02039b2:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02039b6:	02000793          	li	a5,32
ffffffffc02039ba:	9f8d                	subw	a5,a5,a1
}
ffffffffc02039bc:	00f5553b          	srlw	a0,a0,a5
ffffffffc02039c0:	8082                	ret

ffffffffc02039c2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02039c2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039c6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02039c8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039cc:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02039ce:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039d2:	f022                	sd	s0,32(sp)
ffffffffc02039d4:	ec26                	sd	s1,24(sp)
ffffffffc02039d6:	e84a                	sd	s2,16(sp)
ffffffffc02039d8:	f406                	sd	ra,40(sp)
ffffffffc02039da:	e44e                	sd	s3,8(sp)
ffffffffc02039dc:	84aa                	mv	s1,a0
ffffffffc02039de:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02039e0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02039e4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02039e6:	03067e63          	bgeu	a2,a6,ffffffffc0203a22 <printnum+0x60>
ffffffffc02039ea:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02039ec:	00805763          	blez	s0,ffffffffc02039fa <printnum+0x38>
ffffffffc02039f0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02039f2:	85ca                	mv	a1,s2
ffffffffc02039f4:	854e                	mv	a0,s3
ffffffffc02039f6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02039f8:	fc65                	bnez	s0,ffffffffc02039f0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039fa:	1a02                	slli	s4,s4,0x20
ffffffffc02039fc:	00002797          	auipc	a5,0x2
ffffffffc0203a00:	dac78793          	addi	a5,a5,-596 # ffffffffc02057a8 <default_pmm_manager+0xad8>
ffffffffc0203a04:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203a08:	9a3e                	add	s4,s4,a5
}
ffffffffc0203a0a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a0c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203a10:	70a2                	ld	ra,40(sp)
ffffffffc0203a12:	69a2                	ld	s3,8(sp)
ffffffffc0203a14:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a16:	85ca                	mv	a1,s2
ffffffffc0203a18:	87a6                	mv	a5,s1
}
ffffffffc0203a1a:	6942                	ld	s2,16(sp)
ffffffffc0203a1c:	64e2                	ld	s1,24(sp)
ffffffffc0203a1e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a20:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a22:	03065633          	divu	a2,a2,a6
ffffffffc0203a26:	8722                	mv	a4,s0
ffffffffc0203a28:	f9bff0ef          	jal	ra,ffffffffc02039c2 <printnum>
ffffffffc0203a2c:	b7f9                	j	ffffffffc02039fa <printnum+0x38>

ffffffffc0203a2e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a2e:	7119                	addi	sp,sp,-128
ffffffffc0203a30:	f4a6                	sd	s1,104(sp)
ffffffffc0203a32:	f0ca                	sd	s2,96(sp)
ffffffffc0203a34:	ecce                	sd	s3,88(sp)
ffffffffc0203a36:	e8d2                	sd	s4,80(sp)
ffffffffc0203a38:	e4d6                	sd	s5,72(sp)
ffffffffc0203a3a:	e0da                	sd	s6,64(sp)
ffffffffc0203a3c:	fc5e                	sd	s7,56(sp)
ffffffffc0203a3e:	f06a                	sd	s10,32(sp)
ffffffffc0203a40:	fc86                	sd	ra,120(sp)
ffffffffc0203a42:	f8a2                	sd	s0,112(sp)
ffffffffc0203a44:	f862                	sd	s8,48(sp)
ffffffffc0203a46:	f466                	sd	s9,40(sp)
ffffffffc0203a48:	ec6e                	sd	s11,24(sp)
ffffffffc0203a4a:	892a                	mv	s2,a0
ffffffffc0203a4c:	84ae                	mv	s1,a1
ffffffffc0203a4e:	8d32                	mv	s10,a2
ffffffffc0203a50:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a52:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203a56:	5b7d                	li	s6,-1
ffffffffc0203a58:	00002a97          	auipc	s5,0x2
ffffffffc0203a5c:	d7ca8a93          	addi	s5,s5,-644 # ffffffffc02057d4 <default_pmm_manager+0xb04>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203a60:	00002b97          	auipc	s7,0x2
ffffffffc0203a64:	f50b8b93          	addi	s7,s7,-176 # ffffffffc02059b0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a68:	000d4503          	lbu	a0,0(s10)
ffffffffc0203a6c:	001d0413          	addi	s0,s10,1
ffffffffc0203a70:	01350a63          	beq	a0,s3,ffffffffc0203a84 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203a74:	c121                	beqz	a0,ffffffffc0203ab4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203a76:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a78:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203a7a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a7c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203a80:	ff351ae3          	bne	a0,s3,ffffffffc0203a74 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a84:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203a88:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203a8c:	4c81                	li	s9,0
ffffffffc0203a8e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203a90:	5c7d                	li	s8,-1
ffffffffc0203a92:	5dfd                	li	s11,-1
ffffffffc0203a94:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203a98:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a9a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203a9e:	0ff5f593          	zext.b	a1,a1
ffffffffc0203aa2:	00140d13          	addi	s10,s0,1
ffffffffc0203aa6:	04b56263          	bltu	a0,a1,ffffffffc0203aea <vprintfmt+0xbc>
ffffffffc0203aaa:	058a                	slli	a1,a1,0x2
ffffffffc0203aac:	95d6                	add	a1,a1,s5
ffffffffc0203aae:	4194                	lw	a3,0(a1)
ffffffffc0203ab0:	96d6                	add	a3,a3,s5
ffffffffc0203ab2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203ab4:	70e6                	ld	ra,120(sp)
ffffffffc0203ab6:	7446                	ld	s0,112(sp)
ffffffffc0203ab8:	74a6                	ld	s1,104(sp)
ffffffffc0203aba:	7906                	ld	s2,96(sp)
ffffffffc0203abc:	69e6                	ld	s3,88(sp)
ffffffffc0203abe:	6a46                	ld	s4,80(sp)
ffffffffc0203ac0:	6aa6                	ld	s5,72(sp)
ffffffffc0203ac2:	6b06                	ld	s6,64(sp)
ffffffffc0203ac4:	7be2                	ld	s7,56(sp)
ffffffffc0203ac6:	7c42                	ld	s8,48(sp)
ffffffffc0203ac8:	7ca2                	ld	s9,40(sp)
ffffffffc0203aca:	7d02                	ld	s10,32(sp)
ffffffffc0203acc:	6de2                	ld	s11,24(sp)
ffffffffc0203ace:	6109                	addi	sp,sp,128
ffffffffc0203ad0:	8082                	ret
            padc = '0';
ffffffffc0203ad2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203ad4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ad8:	846a                	mv	s0,s10
ffffffffc0203ada:	00140d13          	addi	s10,s0,1
ffffffffc0203ade:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203ae2:	0ff5f593          	zext.b	a1,a1
ffffffffc0203ae6:	fcb572e3          	bgeu	a0,a1,ffffffffc0203aaa <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203aea:	85a6                	mv	a1,s1
ffffffffc0203aec:	02500513          	li	a0,37
ffffffffc0203af0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203af2:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203af6:	8d22                	mv	s10,s0
ffffffffc0203af8:	f73788e3          	beq	a5,s3,ffffffffc0203a68 <vprintfmt+0x3a>
ffffffffc0203afc:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203b00:	1d7d                	addi	s10,s10,-1
ffffffffc0203b02:	ff379de3          	bne	a5,s3,ffffffffc0203afc <vprintfmt+0xce>
ffffffffc0203b06:	b78d                	j	ffffffffc0203a68 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203b08:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203b0c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b10:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203b12:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203b16:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b1a:	02d86463          	bltu	a6,a3,ffffffffc0203b42 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203b1e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b22:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203b26:	0186873b          	addw	a4,a3,s8
ffffffffc0203b2a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b2e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203b30:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b34:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b36:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203b3a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b3e:	fed870e3          	bgeu	a6,a3,ffffffffc0203b1e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b42:	f40ddce3          	bgez	s11,ffffffffc0203a9a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203b46:	8de2                	mv	s11,s8
ffffffffc0203b48:	5c7d                	li	s8,-1
ffffffffc0203b4a:	bf81                	j	ffffffffc0203a9a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203b4c:	fffdc693          	not	a3,s11
ffffffffc0203b50:	96fd                	srai	a3,a3,0x3f
ffffffffc0203b52:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b56:	00144603          	lbu	a2,1(s0)
ffffffffc0203b5a:	2d81                	sext.w	s11,s11
ffffffffc0203b5c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b5e:	bf35                	j	ffffffffc0203a9a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203b60:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b64:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203b68:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b6a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203b6c:	bfd9                	j	ffffffffc0203b42 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203b6e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b70:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b74:	01174463          	blt	a4,a7,ffffffffc0203b7c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203b78:	1a088e63          	beqz	a7,ffffffffc0203d34 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203b7c:	000a3603          	ld	a2,0(s4)
ffffffffc0203b80:	46c1                	li	a3,16
ffffffffc0203b82:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b84:	2781                	sext.w	a5,a5
ffffffffc0203b86:	876e                	mv	a4,s11
ffffffffc0203b88:	85a6                	mv	a1,s1
ffffffffc0203b8a:	854a                	mv	a0,s2
ffffffffc0203b8c:	e37ff0ef          	jal	ra,ffffffffc02039c2 <printnum>
            break;
ffffffffc0203b90:	bde1                	j	ffffffffc0203a68 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b92:	000a2503          	lw	a0,0(s4)
ffffffffc0203b96:	85a6                	mv	a1,s1
ffffffffc0203b98:	0a21                	addi	s4,s4,8
ffffffffc0203b9a:	9902                	jalr	s2
            break;
ffffffffc0203b9c:	b5f1                	j	ffffffffc0203a68 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203b9e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203ba0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203ba4:	01174463          	blt	a4,a7,ffffffffc0203bac <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203ba8:	18088163          	beqz	a7,ffffffffc0203d2a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203bac:	000a3603          	ld	a2,0(s4)
ffffffffc0203bb0:	46a9                	li	a3,10
ffffffffc0203bb2:	8a2e                	mv	s4,a1
ffffffffc0203bb4:	bfc1                	j	ffffffffc0203b84 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bb6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203bba:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bbc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bbe:	bdf1                	j	ffffffffc0203a9a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203bc0:	85a6                	mv	a1,s1
ffffffffc0203bc2:	02500513          	li	a0,37
ffffffffc0203bc6:	9902                	jalr	s2
            break;
ffffffffc0203bc8:	b545                	j	ffffffffc0203a68 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bca:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203bce:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bd0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bd2:	b5e1                	j	ffffffffc0203a9a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203bd4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bd6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bda:	01174463          	blt	a4,a7,ffffffffc0203be2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203bde:	14088163          	beqz	a7,ffffffffc0203d20 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203be2:	000a3603          	ld	a2,0(s4)
ffffffffc0203be6:	46a1                	li	a3,8
ffffffffc0203be8:	8a2e                	mv	s4,a1
ffffffffc0203bea:	bf69                	j	ffffffffc0203b84 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203bec:	03000513          	li	a0,48
ffffffffc0203bf0:	85a6                	mv	a1,s1
ffffffffc0203bf2:	e03e                	sd	a5,0(sp)
ffffffffc0203bf4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203bf6:	85a6                	mv	a1,s1
ffffffffc0203bf8:	07800513          	li	a0,120
ffffffffc0203bfc:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bfe:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203c00:	6782                	ld	a5,0(sp)
ffffffffc0203c02:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203c04:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203c08:	bfb5                	j	ffffffffc0203b84 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c0a:	000a3403          	ld	s0,0(s4)
ffffffffc0203c0e:	008a0713          	addi	a4,s4,8
ffffffffc0203c12:	e03a                	sd	a4,0(sp)
ffffffffc0203c14:	14040263          	beqz	s0,ffffffffc0203d58 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203c18:	0fb05763          	blez	s11,ffffffffc0203d06 <vprintfmt+0x2d8>
ffffffffc0203c1c:	02d00693          	li	a3,45
ffffffffc0203c20:	0cd79163          	bne	a5,a3,ffffffffc0203ce2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c24:	00044783          	lbu	a5,0(s0)
ffffffffc0203c28:	0007851b          	sext.w	a0,a5
ffffffffc0203c2c:	cf85                	beqz	a5,ffffffffc0203c64 <vprintfmt+0x236>
ffffffffc0203c2e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c32:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c36:	000c4563          	bltz	s8,ffffffffc0203c40 <vprintfmt+0x212>
ffffffffc0203c3a:	3c7d                	addiw	s8,s8,-1
ffffffffc0203c3c:	036c0263          	beq	s8,s6,ffffffffc0203c60 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c40:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c42:	0e0c8e63          	beqz	s9,ffffffffc0203d3e <vprintfmt+0x310>
ffffffffc0203c46:	3781                	addiw	a5,a5,-32
ffffffffc0203c48:	0ef47b63          	bgeu	s0,a5,ffffffffc0203d3e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203c4c:	03f00513          	li	a0,63
ffffffffc0203c50:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c52:	000a4783          	lbu	a5,0(s4)
ffffffffc0203c56:	3dfd                	addiw	s11,s11,-1
ffffffffc0203c58:	0a05                	addi	s4,s4,1
ffffffffc0203c5a:	0007851b          	sext.w	a0,a5
ffffffffc0203c5e:	ffe1                	bnez	a5,ffffffffc0203c36 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203c60:	01b05963          	blez	s11,ffffffffc0203c72 <vprintfmt+0x244>
ffffffffc0203c64:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203c66:	85a6                	mv	a1,s1
ffffffffc0203c68:	02000513          	li	a0,32
ffffffffc0203c6c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203c6e:	fe0d9be3          	bnez	s11,ffffffffc0203c64 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c72:	6a02                	ld	s4,0(sp)
ffffffffc0203c74:	bbd5                	j	ffffffffc0203a68 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203c76:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c78:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203c7c:	01174463          	blt	a4,a7,ffffffffc0203c84 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203c80:	08088d63          	beqz	a7,ffffffffc0203d1a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203c84:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203c88:	0a044d63          	bltz	s0,ffffffffc0203d42 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203c8c:	8622                	mv	a2,s0
ffffffffc0203c8e:	8a66                	mv	s4,s9
ffffffffc0203c90:	46a9                	li	a3,10
ffffffffc0203c92:	bdcd                	j	ffffffffc0203b84 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203c94:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c98:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203c9a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203c9c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203ca0:	8fb5                	xor	a5,a5,a3
ffffffffc0203ca2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203ca6:	02d74163          	blt	a4,a3,ffffffffc0203cc8 <vprintfmt+0x29a>
ffffffffc0203caa:	00369793          	slli	a5,a3,0x3
ffffffffc0203cae:	97de                	add	a5,a5,s7
ffffffffc0203cb0:	639c                	ld	a5,0(a5)
ffffffffc0203cb2:	cb99                	beqz	a5,ffffffffc0203cc8 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203cb4:	86be                	mv	a3,a5
ffffffffc0203cb6:	00000617          	auipc	a2,0x0
ffffffffc0203cba:	21260613          	addi	a2,a2,530 # ffffffffc0203ec8 <etext+0x28>
ffffffffc0203cbe:	85a6                	mv	a1,s1
ffffffffc0203cc0:	854a                	mv	a0,s2
ffffffffc0203cc2:	0ce000ef          	jal	ra,ffffffffc0203d90 <printfmt>
ffffffffc0203cc6:	b34d                	j	ffffffffc0203a68 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203cc8:	00002617          	auipc	a2,0x2
ffffffffc0203ccc:	b0060613          	addi	a2,a2,-1280 # ffffffffc02057c8 <default_pmm_manager+0xaf8>
ffffffffc0203cd0:	85a6                	mv	a1,s1
ffffffffc0203cd2:	854a                	mv	a0,s2
ffffffffc0203cd4:	0bc000ef          	jal	ra,ffffffffc0203d90 <printfmt>
ffffffffc0203cd8:	bb41                	j	ffffffffc0203a68 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203cda:	00002417          	auipc	s0,0x2
ffffffffc0203cde:	ae640413          	addi	s0,s0,-1306 # ffffffffc02057c0 <default_pmm_manager+0xaf0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203ce2:	85e2                	mv	a1,s8
ffffffffc0203ce4:	8522                	mv	a0,s0
ffffffffc0203ce6:	e43e                	sd	a5,8(sp)
ffffffffc0203ce8:	0e2000ef          	jal	ra,ffffffffc0203dca <strnlen>
ffffffffc0203cec:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203cf0:	01b05b63          	blez	s11,ffffffffc0203d06 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203cf4:	67a2                	ld	a5,8(sp)
ffffffffc0203cf6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cfa:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203cfc:	85a6                	mv	a1,s1
ffffffffc0203cfe:	8552                	mv	a0,s4
ffffffffc0203d00:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203d02:	fe0d9ce3          	bnez	s11,ffffffffc0203cfa <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d06:	00044783          	lbu	a5,0(s0)
ffffffffc0203d0a:	00140a13          	addi	s4,s0,1
ffffffffc0203d0e:	0007851b          	sext.w	a0,a5
ffffffffc0203d12:	d3a5                	beqz	a5,ffffffffc0203c72 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d14:	05e00413          	li	s0,94
ffffffffc0203d18:	bf39                	j	ffffffffc0203c36 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203d1a:	000a2403          	lw	s0,0(s4)
ffffffffc0203d1e:	b7ad                	j	ffffffffc0203c88 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203d20:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d24:	46a1                	li	a3,8
ffffffffc0203d26:	8a2e                	mv	s4,a1
ffffffffc0203d28:	bdb1                	j	ffffffffc0203b84 <vprintfmt+0x156>
ffffffffc0203d2a:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d2e:	46a9                	li	a3,10
ffffffffc0203d30:	8a2e                	mv	s4,a1
ffffffffc0203d32:	bd89                	j	ffffffffc0203b84 <vprintfmt+0x156>
ffffffffc0203d34:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d38:	46c1                	li	a3,16
ffffffffc0203d3a:	8a2e                	mv	s4,a1
ffffffffc0203d3c:	b5a1                	j	ffffffffc0203b84 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203d3e:	9902                	jalr	s2
ffffffffc0203d40:	bf09                	j	ffffffffc0203c52 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d42:	85a6                	mv	a1,s1
ffffffffc0203d44:	02d00513          	li	a0,45
ffffffffc0203d48:	e03e                	sd	a5,0(sp)
ffffffffc0203d4a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203d4c:	6782                	ld	a5,0(sp)
ffffffffc0203d4e:	8a66                	mv	s4,s9
ffffffffc0203d50:	40800633          	neg	a2,s0
ffffffffc0203d54:	46a9                	li	a3,10
ffffffffc0203d56:	b53d                	j	ffffffffc0203b84 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203d58:	03b05163          	blez	s11,ffffffffc0203d7a <vprintfmt+0x34c>
ffffffffc0203d5c:	02d00693          	li	a3,45
ffffffffc0203d60:	f6d79de3          	bne	a5,a3,ffffffffc0203cda <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203d64:	00002417          	auipc	s0,0x2
ffffffffc0203d68:	a5c40413          	addi	s0,s0,-1444 # ffffffffc02057c0 <default_pmm_manager+0xaf0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d6c:	02800793          	li	a5,40
ffffffffc0203d70:	02800513          	li	a0,40
ffffffffc0203d74:	00140a13          	addi	s4,s0,1
ffffffffc0203d78:	bd6d                	j	ffffffffc0203c32 <vprintfmt+0x204>
ffffffffc0203d7a:	00002a17          	auipc	s4,0x2
ffffffffc0203d7e:	a47a0a13          	addi	s4,s4,-1465 # ffffffffc02057c1 <default_pmm_manager+0xaf1>
ffffffffc0203d82:	02800513          	li	a0,40
ffffffffc0203d86:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d8a:	05e00413          	li	s0,94
ffffffffc0203d8e:	b565                	j	ffffffffc0203c36 <vprintfmt+0x208>

ffffffffc0203d90 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d90:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203d92:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d96:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d98:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d9a:	ec06                	sd	ra,24(sp)
ffffffffc0203d9c:	f83a                	sd	a4,48(sp)
ffffffffc0203d9e:	fc3e                	sd	a5,56(sp)
ffffffffc0203da0:	e0c2                	sd	a6,64(sp)
ffffffffc0203da2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203da4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203da6:	c89ff0ef          	jal	ra,ffffffffc0203a2e <vprintfmt>
}
ffffffffc0203daa:	60e2                	ld	ra,24(sp)
ffffffffc0203dac:	6161                	addi	sp,sp,80
ffffffffc0203dae:	8082                	ret

ffffffffc0203db0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203db0:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203db4:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203db6:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203db8:	cb81                	beqz	a5,ffffffffc0203dc8 <strlen+0x18>
        cnt ++;
ffffffffc0203dba:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203dbc:	00a707b3          	add	a5,a4,a0
ffffffffc0203dc0:	0007c783          	lbu	a5,0(a5)
ffffffffc0203dc4:	fbfd                	bnez	a5,ffffffffc0203dba <strlen+0xa>
ffffffffc0203dc6:	8082                	ret
    }
    return cnt;
}
ffffffffc0203dc8:	8082                	ret

ffffffffc0203dca <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203dca:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dcc:	e589                	bnez	a1,ffffffffc0203dd6 <strnlen+0xc>
ffffffffc0203dce:	a811                	j	ffffffffc0203de2 <strnlen+0x18>
        cnt ++;
ffffffffc0203dd0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dd2:	00f58863          	beq	a1,a5,ffffffffc0203de2 <strnlen+0x18>
ffffffffc0203dd6:	00f50733          	add	a4,a0,a5
ffffffffc0203dda:	00074703          	lbu	a4,0(a4)
ffffffffc0203dde:	fb6d                	bnez	a4,ffffffffc0203dd0 <strnlen+0x6>
ffffffffc0203de0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203de2:	852e                	mv	a0,a1
ffffffffc0203de4:	8082                	ret

ffffffffc0203de6 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203de6:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203de8:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dec:	0785                	addi	a5,a5,1
ffffffffc0203dee:	0585                	addi	a1,a1,1
ffffffffc0203df0:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203df4:	fb75                	bnez	a4,ffffffffc0203de8 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203df6:	8082                	ret

ffffffffc0203df8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203df8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dfc:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e00:	cb89                	beqz	a5,ffffffffc0203e12 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203e02:	0505                	addi	a0,a0,1
ffffffffc0203e04:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203e06:	fee789e3          	beq	a5,a4,ffffffffc0203df8 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e0a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203e0e:	9d19                	subw	a0,a0,a4
ffffffffc0203e10:	8082                	ret
ffffffffc0203e12:	4501                	li	a0,0
ffffffffc0203e14:	bfed                	j	ffffffffc0203e0e <strcmp+0x16>

ffffffffc0203e16 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e16:	c20d                	beqz	a2,ffffffffc0203e38 <strncmp+0x22>
ffffffffc0203e18:	962e                	add	a2,a2,a1
ffffffffc0203e1a:	a031                	j	ffffffffc0203e26 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203e1c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e1e:	00e79a63          	bne	a5,a4,ffffffffc0203e32 <strncmp+0x1c>
ffffffffc0203e22:	00b60b63          	beq	a2,a1,ffffffffc0203e38 <strncmp+0x22>
ffffffffc0203e26:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e2a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e2c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e30:	f7f5                	bnez	a5,ffffffffc0203e1c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e32:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203e36:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e38:	4501                	li	a0,0
ffffffffc0203e3a:	8082                	ret

ffffffffc0203e3c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e3c:	00054783          	lbu	a5,0(a0)
ffffffffc0203e40:	c799                	beqz	a5,ffffffffc0203e4e <strchr+0x12>
        if (*s == c) {
ffffffffc0203e42:	00f58763          	beq	a1,a5,ffffffffc0203e50 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e46:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e4a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e4c:	fbfd                	bnez	a5,ffffffffc0203e42 <strchr+0x6>
    }
    return NULL;
ffffffffc0203e4e:	4501                	li	a0,0
}
ffffffffc0203e50:	8082                	ret

ffffffffc0203e52 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e52:	ca01                	beqz	a2,ffffffffc0203e62 <memset+0x10>
ffffffffc0203e54:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e56:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e58:	0785                	addi	a5,a5,1
ffffffffc0203e5a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e5e:	fec79de3          	bne	a5,a2,ffffffffc0203e58 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e62:	8082                	ret

ffffffffc0203e64 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e64:	ca19                	beqz	a2,ffffffffc0203e7a <memcpy+0x16>
ffffffffc0203e66:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e68:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e6a:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e6e:	0585                	addi	a1,a1,1
ffffffffc0203e70:	0785                	addi	a5,a5,1
ffffffffc0203e72:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e76:	fec59ae3          	bne	a1,a2,ffffffffc0203e6a <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e7a:	8082                	ret

ffffffffc0203e7c <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e7c:	c205                	beqz	a2,ffffffffc0203e9c <memcmp+0x20>
ffffffffc0203e7e:	962e                	add	a2,a2,a1
ffffffffc0203e80:	a019                	j	ffffffffc0203e86 <memcmp+0xa>
ffffffffc0203e82:	00c58d63          	beq	a1,a2,ffffffffc0203e9c <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203e86:	00054783          	lbu	a5,0(a0)
ffffffffc0203e8a:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203e8e:	0505                	addi	a0,a0,1
ffffffffc0203e90:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203e92:	fee788e3          	beq	a5,a4,ffffffffc0203e82 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e96:	40e7853b          	subw	a0,a5,a4
ffffffffc0203e9a:	8082                	ret
    }
    return 0;
ffffffffc0203e9c:	4501                	li	a0,0
}
ffffffffc0203e9e:	8082                	ret


bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00005297          	auipc	t0,0x5
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0205000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00005297          	auipc	t0,0x5
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0205008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02042b7          	lui	t0,0xc0204
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
ffffffffc020003c:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0203ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	60450513          	addi	a0,a0,1540 # ffffffffc0201650 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	60e50513          	addi	a0,a0,1550 # ffffffffc0201670 <etext+0x22>
ffffffffc020006a:	0e0000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	5e058593          	addi	a1,a1,1504 # ffffffffc020164e <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	61a50513          	addi	a0,a0,1562 # ffffffffc0201690 <etext+0x42>
ffffffffc020007e:	0cc000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00005597          	auipc	a1,0x5
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0205018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	62650513          	addi	a0,a0,1574 # ffffffffc02016b0 <etext+0x62>
ffffffffc0200092:	0b8000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00005597          	auipc	a1,0x5
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0205078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	63250513          	addi	a0,a0,1586 # ffffffffc02016d0 <etext+0x82>
ffffffffc02000a6:	0a4000ef          	jal	ffffffffc020014a <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00005797          	auipc	a5,0x5
ffffffffc02000ae:	3cd78793          	addi	a5,a5,973 # ffffffffc0205477 <end+0x3ff>
ffffffffc02000b2:	00000717          	auipc	a4,0x0
ffffffffc02000b6:	02470713          	addi	a4,a4,36 # ffffffffc02000d6 <kern_init>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	62650513          	addi	a0,a0,1574 # ffffffffc02016f0 <etext+0xa2>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a89d                	j	ffffffffc020014a <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00005517          	auipc	a0,0x5
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0205018 <free_area>
ffffffffc02000de:	00005617          	auipc	a2,0x5
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0205078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	54e010ef          	jal	ffffffffc020163c <memset>
    dtb_init();
ffffffffc02000f2:	13a000ef          	jal	ffffffffc020022c <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	12c000ef          	jal	ffffffffc0200222 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	ce650513          	addi	a0,a0,-794 # ffffffffc0201de0 <etext+0x792>
ffffffffc0200102:	07c000ef          	jal	ffffffffc020017e <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	6bf000ef          	jal	ffffffffc0200fc8 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1141                	addi	sp,sp,-16
ffffffffc0200112:	e022                	sd	s0,0(sp)
ffffffffc0200114:	e406                	sd	ra,8(sp)
ffffffffc0200116:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200118:	10c000ef          	jal	ffffffffc0200224 <cons_putc>
    (*cnt) ++;
ffffffffc020011c:	401c                	lw	a5,0(s0)
}
ffffffffc020011e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c01c                	sw	a5,0(s0)
}
ffffffffc0200124:	6402                	ld	s0,0(sp)
ffffffffc0200126:	0141                	addi	sp,sp,16
ffffffffc0200128:	8082                	ret

ffffffffc020012a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012a:	1101                	addi	sp,sp,-32
ffffffffc020012c:	862a                	mv	a2,a0
ffffffffc020012e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200130:	00000517          	auipc	a0,0x0
ffffffffc0200134:	fe050513          	addi	a0,a0,-32 # ffffffffc0200110 <cputch>
ffffffffc0200138:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013a:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013c:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013e:	0d4010ef          	jal	ffffffffc0201212 <vprintfmt>
    return cnt;
}
ffffffffc0200142:	60e2                	ld	ra,24(sp)
ffffffffc0200144:	4532                	lw	a0,12(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret

ffffffffc020014a <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014a:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014c:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200150:	f42e                	sd	a1,40(sp)
ffffffffc0200152:	f832                	sd	a2,48(sp)
ffffffffc0200154:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200156:	862a                	mv	a2,a0
ffffffffc0200158:	004c                	addi	a1,sp,4
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb650513          	addi	a0,a0,-74 # ffffffffc0200110 <cputch>
ffffffffc0200162:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200164:	ec06                	sd	ra,24(sp)
ffffffffc0200166:	e0ba                	sd	a4,64(sp)
ffffffffc0200168:	e4be                	sd	a5,72(sp)
ffffffffc020016a:	e8c2                	sd	a6,80(sp)
ffffffffc020016c:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200170:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200172:	0a0010ef          	jal	ffffffffc0201212 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200176:	60e2                	ld	ra,24(sp)
ffffffffc0200178:	4512                	lw	a0,4(sp)
ffffffffc020017a:	6125                	addi	sp,sp,96
ffffffffc020017c:	8082                	ret

ffffffffc020017e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017e:	1101                	addi	sp,sp,-32
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	e822                	sd	s0,16(sp)
ffffffffc0200184:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200186:	00054503          	lbu	a0,0(a0)
ffffffffc020018a:	c905                	beqz	a0,ffffffffc02001ba <cputs+0x3c>
ffffffffc020018c:	e426                	sd	s1,8(sp)
ffffffffc020018e:	00178493          	addi	s1,a5,1
ffffffffc0200192:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200194:	090000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200198:	00044503          	lbu	a0,0(s0)
ffffffffc020019c:	87a2                	mv	a5,s0
ffffffffc020019e:	0405                	addi	s0,s0,1
ffffffffc02001a0:	f975                	bnez	a0,ffffffffc0200194 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a2:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc02001a4:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a6:	0027841b          	addiw	s0,a5,2
ffffffffc02001aa:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001ac:	078000ef          	jal	ffffffffc0200224 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
ffffffffc02001b2:	8522                	mv	a0,s0
ffffffffc02001b4:	6442                	ld	s0,16(sp)
ffffffffc02001b6:	6105                	addi	sp,sp,32
ffffffffc02001b8:	8082                	ret
    cons_putc(c);
ffffffffc02001ba:	4529                	li	a0,10
ffffffffc02001bc:	068000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001cc:	00005317          	auipc	t1,0x5
ffffffffc02001d0:	e6430313          	addi	t1,t1,-412 # ffffffffc0205030 <is_panic>
ffffffffc02001d4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d8:	715d                	addi	sp,sp,-80
ffffffffc02001da:	ec06                	sd	ra,24(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	000e0363          	beqz	t3,ffffffffc02001ec <__panic+0x20>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x1e>
    is_panic = 1;
ffffffffc02001ec:	4785                	li	a5,1
ffffffffc02001ee:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001f2:	e822                	sd	s0,16(sp)
ffffffffc02001f4:	103c                	addi	a5,sp,40
ffffffffc02001f6:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	862e                	mv	a2,a1
ffffffffc02001fa:	85aa                	mv	a1,a0
ffffffffc02001fc:	00001517          	auipc	a0,0x1
ffffffffc0200200:	52450513          	addi	a0,a0,1316 # ffffffffc0201720 <etext+0xd2>
    va_start(ap, fmt);
ffffffffc0200204:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200206:	f45ff0ef          	jal	ffffffffc020014a <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020a:	65a2                	ld	a1,8(sp)
ffffffffc020020c:	8522                	mv	a0,s0
ffffffffc020020e:	f1dff0ef          	jal	ffffffffc020012a <vcprintf>
    cprintf("\n");
ffffffffc0200212:	00001517          	auipc	a0,0x1
ffffffffc0200216:	52e50513          	addi	a0,a0,1326 # ffffffffc0201740 <etext+0xf2>
ffffffffc020021a:	f31ff0ef          	jal	ffffffffc020014a <cprintf>
ffffffffc020021e:	6442                	ld	s0,16(sp)
ffffffffc0200220:	b7e9                	j	ffffffffc02001ea <__panic+0x1e>

ffffffffc0200222 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200222:	8082                	ret

ffffffffc0200224 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200224:	0ff57513          	zext.b	a0,a0
ffffffffc0200228:	3640106f          	j	ffffffffc020158c <sbi_console_putchar>

ffffffffc020022c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020022c:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020022e:	00001517          	auipc	a0,0x1
ffffffffc0200232:	51a50513          	addi	a0,a0,1306 # ffffffffc0201748 <etext+0xfa>
void dtb_init(void) {
ffffffffc0200236:	ec86                	sd	ra,88(sp)
ffffffffc0200238:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f11ff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00005597          	auipc	a1,0x5
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0205000 <boot_hartid>
ffffffffc0200246:	00001517          	auipc	a0,0x1
ffffffffc020024a:	51250513          	addi	a0,a0,1298 # ffffffffc0201758 <etext+0x10a>
ffffffffc020024e:	efdff0ef          	jal	ffffffffc020014a <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00005417          	auipc	s0,0x5
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0205008 <boot_dtb>
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00001517          	auipc	a0,0x1
ffffffffc0200260:	50c50513          	addi	a0,a0,1292 # ffffffffc0201768 <etext+0x11a>
ffffffffc0200264:	ee7ff0ef          	jal	ffffffffc020014a <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026a:	00001517          	auipc	a0,0x1
ffffffffc020026e:	51650513          	addi	a0,a0,1302 # ffffffffc0201780 <etext+0x132>
    if (boot_dtb == 0) {
ffffffffc0200272:	12070d63          	beqz	a4,ffffffffc02003ac <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200276:	57f5                	li	a5,-3
ffffffffc0200278:	07fa                	slli	a5,a5,0x1e
ffffffffc020027a:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020027c:	431c                	lw	a5,0(a4)
ffffffffc020027e:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200280:	00ff0637          	lui	a2,0xff0
ffffffffc0200284:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200288:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028c:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200290:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200294:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200298:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029c:	8ec9                	or	a3,a3,a0
ffffffffc020029e:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002a2:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02002a4:	0157f7b3          	and	a5,a5,s5
ffffffffc02002a8:	8dd5                	or	a1,a1,a3
ffffffffc02002aa:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002ac:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002b0:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002b2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfedae75>
ffffffffc02002b6:	0ef59f63          	bne	a1,a5,ffffffffc02003b4 <dtb_init+0x188>
ffffffffc02002ba:	471c                	lw	a5,8(a4)
ffffffffc02002bc:	4754                	lw	a3,12(a4)
ffffffffc02002be:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c0:	0087d99b          	srliw	s3,a5,0x8
ffffffffc02002c4:	0086d41b          	srliw	s0,a3,0x8
ffffffffc02002c8:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002cc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d0:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d4:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002dc:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e0:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e4:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e8:	8c71                	and	s0,s0,a2
ffffffffc02002ea:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	01156533          	or	a0,a0,a7
ffffffffc02002f2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002f6:	0105e633          	or	a2,a1,a6
ffffffffc02002fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002fe:	8c49                	or	s0,s0,a0
ffffffffc0200300:	0156f6b3          	and	a3,a3,s5
ffffffffc0200304:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200308:	0157f7b3          	and	a5,a5,s5
ffffffffc020030c:	8c55                	or	s0,s0,a3
ffffffffc020030e:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200318:	0209d993          	srli	s3,s3,0x20
ffffffffc020031c:	e4a6                	sd	s1,72(sp)
ffffffffc020031e:	e0ca                	sd	s2,64(sp)
ffffffffc0200320:	ec5e                	sd	s7,24(sp)
ffffffffc0200322:	e862                	sd	s8,16(sp)
ffffffffc0200324:	e466                	sd	s9,8(sp)
ffffffffc0200326:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200328:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc020032a:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032c:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032e:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200330:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200334:	4c0d                	li	s8,3
ffffffffc0200336:	4911                	li	s2,4
ffffffffc0200338:	4d05                	li	s10,1
ffffffffc020033a:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033c:	0009a703          	lw	a4,0(s3)
ffffffffc0200340:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200344:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200348:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034c:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200350:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200354:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200358:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200362:	8fd5                	or	a5,a5,a3
ffffffffc0200364:	00eaf733          	and	a4,s5,a4
ffffffffc0200368:	8fd9                	or	a5,a5,a4
ffffffffc020036a:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020036c:	09878263          	beq	a5,s8,ffffffffc02003f0 <dtb_init+0x1c4>
ffffffffc0200370:	00fc6963          	bltu	s8,a5,ffffffffc0200382 <dtb_init+0x156>
ffffffffc0200374:	05a78963          	beq	a5,s10,ffffffffc02003c6 <dtb_init+0x19a>
ffffffffc0200378:	00979763          	bne	a5,s1,ffffffffc0200386 <dtb_init+0x15a>
ffffffffc020037c:	4b81                	li	s7,0
ffffffffc020037e:	89d2                	mv	s3,s4
ffffffffc0200380:	bf75                	j	ffffffffc020033c <dtb_init+0x110>
ffffffffc0200382:	ff278ee3          	beq	a5,s2,ffffffffc020037e <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200386:	00001517          	auipc	a0,0x1
ffffffffc020038a:	4c250513          	addi	a0,a0,1218 # ffffffffc0201848 <etext+0x1fa>
ffffffffc020038e:	dbdff0ef          	jal	ffffffffc020014a <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200392:	64a6                	ld	s1,72(sp)
ffffffffc0200394:	6906                	ld	s2,64(sp)
ffffffffc0200396:	79e2                	ld	s3,56(sp)
ffffffffc0200398:	7a42                	ld	s4,48(sp)
ffffffffc020039a:	7aa2                	ld	s5,40(sp)
ffffffffc020039c:	6be2                	ld	s7,24(sp)
ffffffffc020039e:	6c42                	ld	s8,16(sp)
ffffffffc02003a0:	6ca2                	ld	s9,8(sp)
ffffffffc02003a2:	6d02                	ld	s10,0(sp)
ffffffffc02003a4:	00001517          	auipc	a0,0x1
ffffffffc02003a8:	4dc50513          	addi	a0,a0,1244 # ffffffffc0201880 <etext+0x232>
}
ffffffffc02003ac:	6446                	ld	s0,80(sp)
ffffffffc02003ae:	60e6                	ld	ra,88(sp)
ffffffffc02003b0:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc02003b2:	bb61                	j	ffffffffc020014a <cprintf>
}
ffffffffc02003b4:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003b6:	7aa2                	ld	s5,40(sp)
}
ffffffffc02003b8:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003ba:	00001517          	auipc	a0,0x1
ffffffffc02003be:	3e650513          	addi	a0,a0,998 # ffffffffc02017a0 <etext+0x152>
}
ffffffffc02003c2:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003c4:	b359                	j	ffffffffc020014a <cprintf>
                int name_len = strlen(name);
ffffffffc02003c6:	8552                	mv	a0,s4
ffffffffc02003c8:	1de010ef          	jal	ffffffffc02015a6 <strlen>
ffffffffc02003cc:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ce:	4619                	li	a2,6
ffffffffc02003d0:	00001597          	auipc	a1,0x1
ffffffffc02003d4:	3f858593          	addi	a1,a1,1016 # ffffffffc02017c8 <etext+0x17a>
ffffffffc02003d8:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc02003da:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003dc:	238010ef          	jal	ffffffffc0201614 <strncmp>
ffffffffc02003e0:	e111                	bnez	a0,ffffffffc02003e4 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc02003e2:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e4:	0a11                	addi	s4,s4,4
ffffffffc02003e6:	9a4e                	add	s4,s4,s3
ffffffffc02003e8:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc02003ec:	89d2                	mv	s3,s4
ffffffffc02003ee:	b7b9                	j	ffffffffc020033c <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f0:	0049a783          	lw	a5,4(s3)
ffffffffc02003f4:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003fa:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02003fe:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200402:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200406:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020040e:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200412:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200416:	0087979b          	slliw	a5,a5,0x8
ffffffffc020041a:	00eb6b33          	or	s6,s6,a4
ffffffffc020041e:	00faf7b3          	and	a5,s5,a5
ffffffffc0200422:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200426:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042a:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042c:	000b9c63          	bnez	s7,ffffffffc0200444 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200430:	1b02                	slli	s6,s6,0x20
ffffffffc0200432:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200436:	0a0d                	addi	s4,s4,3
ffffffffc0200438:	9a5a                	add	s4,s4,s6
ffffffffc020043a:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020043e:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc0200440:	89d2                	mv	s3,s4
ffffffffc0200442:	bded                	j	ffffffffc020033c <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200444:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200448:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020044c:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200450:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200454:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200458:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020045c:	8fd9                	or	a5,a5,a4
ffffffffc020045e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200462:	8d5d                	or	a0,a0,a5
ffffffffc0200464:	00daf6b3          	and	a3,s5,a3
ffffffffc0200468:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020046a:	1502                	slli	a0,a0,0x20
ffffffffc020046c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020046e:	00001597          	auipc	a1,0x1
ffffffffc0200472:	36258593          	addi	a1,a1,866 # ffffffffc02017d0 <etext+0x182>
ffffffffc0200476:	9522                	add	a0,a0,s0
ffffffffc0200478:	164010ef          	jal	ffffffffc02015dc <strcmp>
ffffffffc020047c:	f955                	bnez	a0,ffffffffc0200430 <dtb_init+0x204>
ffffffffc020047e:	47bd                	li	a5,15
ffffffffc0200480:	fb67f8e3          	bgeu	a5,s6,ffffffffc0200430 <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200484:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200488:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020048c:	00001517          	auipc	a0,0x1
ffffffffc0200490:	34c50513          	addi	a0,a0,844 # ffffffffc02017d8 <etext+0x18a>
           fdt32_to_cpu(x >> 32);
ffffffffc0200494:	4207d693          	srai	a3,a5,0x20
ffffffffc0200498:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049c:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02004a0:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02004a4:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02004a8:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ac:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02004b0:	0087541b          	srliw	s0,a4,0x8
ffffffffc02004b4:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004bc:	01869e1b          	slliw	t3,a3,0x18
ffffffffc02004c0:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0188189b          	slliw	a7,a6,0x18
ffffffffc02004cc:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d4:	0108581b          	srliw	a6,a6,0x10
ffffffffc02004d8:	005e6e33          	or	t3,t3,t0
ffffffffc02004dc:	01e8e8b3          	or	a7,a7,t5
ffffffffc02004e0:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e4:	0104949b          	slliw	s1,s1,0x10
ffffffffc02004e8:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f4:	0086969b          	slliw	a3,a3,0x8
ffffffffc02004f8:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	00daf6b3          	and	a3,s5,a3
ffffffffc0200504:	007eeeb3          	or	t4,t4,t2
ffffffffc0200508:	01f36333          	or	t1,t1,t6
ffffffffc020050c:	01c7e7b3          	or	a5,a5,t3
ffffffffc0200510:	00caf633          	and	a2,s5,a2
ffffffffc0200514:	01176733          	or	a4,a4,a7
ffffffffc0200518:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051c:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200520:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200524:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200528:	01d4e4b3          	or	s1,s1,t4
ffffffffc020052c:	00646433          	or	s0,s0,t1
ffffffffc0200530:	8fd5                	or	a5,a5,a3
ffffffffc0200532:	01576733          	or	a4,a4,s5
ffffffffc0200536:	8c51                	or	s0,s0,a2
ffffffffc0200538:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc020053a:	1782                	slli	a5,a5,0x20
ffffffffc020053c:	1702                	slli	a4,a4,0x20
ffffffffc020053e:	9381                	srli	a5,a5,0x20
ffffffffc0200540:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200542:	1482                	slli	s1,s1,0x20
ffffffffc0200544:	1402                	slli	s0,s0,0x20
ffffffffc0200546:	8cdd                	or	s1,s1,a5
ffffffffc0200548:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020054a:	c01ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020054e:	85a6                	mv	a1,s1
ffffffffc0200550:	00001517          	auipc	a0,0x1
ffffffffc0200554:	2a850513          	addi	a0,a0,680 # ffffffffc02017f8 <etext+0x1aa>
ffffffffc0200558:	bf3ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020055c:	01445613          	srli	a2,s0,0x14
ffffffffc0200560:	85a2                	mv	a1,s0
ffffffffc0200562:	00001517          	auipc	a0,0x1
ffffffffc0200566:	2ae50513          	addi	a0,a0,686 # ffffffffc0201810 <etext+0x1c2>
ffffffffc020056a:	be1ff0ef          	jal	ffffffffc020014a <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020056e:	009405b3          	add	a1,s0,s1
ffffffffc0200572:	15fd                	addi	a1,a1,-1
ffffffffc0200574:	00001517          	auipc	a0,0x1
ffffffffc0200578:	2bc50513          	addi	a0,a0,700 # ffffffffc0201830 <etext+0x1e2>
ffffffffc020057c:	bcfff0ef          	jal	ffffffffc020014a <cprintf>
        memory_base = mem_base;
ffffffffc0200580:	7b02                	ld	s6,32(sp)
ffffffffc0200582:	00005797          	auipc	a5,0x5
ffffffffc0200586:	aa97bf23          	sd	s1,-1346(a5) # ffffffffc0205040 <memory_base>
        memory_size = mem_size;
ffffffffc020058a:	00005797          	auipc	a5,0x5
ffffffffc020058e:	aa87b723          	sd	s0,-1362(a5) # ffffffffc0205038 <memory_size>
ffffffffc0200592:	b501                	j	ffffffffc0200392 <dtb_init+0x166>

ffffffffc0200594 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200594:	00005517          	auipc	a0,0x5
ffffffffc0200598:	aac53503          	ld	a0,-1364(a0) # ffffffffc0205040 <memory_base>
ffffffffc020059c:	8082                	ret

ffffffffc020059e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020059e:	00005517          	auipc	a0,0x5
ffffffffc02005a2:	a9a53503          	ld	a0,-1382(a0) # ffffffffc0205038 <memory_size>
ffffffffc02005a6:	8082                	ret

ffffffffc02005a8 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005a8:	00005797          	auipc	a5,0x5
ffffffffc02005ac:	a7078793          	addi	a5,a5,-1424 # ffffffffc0205018 <free_area>
ffffffffc02005b0:	e79c                	sd	a5,8(a5)
ffffffffc02005b2:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005b4:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005b8:	8082                	ret

ffffffffc02005ba <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005ba:	00005517          	auipc	a0,0x5
ffffffffc02005be:	a6e56503          	lwu	a0,-1426(a0) # ffffffffc0205028 <free_area+0x10>
ffffffffc02005c2:	8082                	ret

ffffffffc02005c4 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005c4:	cd49                	beqz	a0,ffffffffc020065e <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02005c6:	00005617          	auipc	a2,0x5
ffffffffc02005ca:	a5260613          	addi	a2,a2,-1454 # ffffffffc0205018 <free_area>
ffffffffc02005ce:	01062803          	lw	a6,16(a2)
ffffffffc02005d2:	86aa                	mv	a3,a0
ffffffffc02005d4:	02081793          	slli	a5,a6,0x20
ffffffffc02005d8:	9381                	srli	a5,a5,0x20
ffffffffc02005da:	08a7e063          	bltu	a5,a0,ffffffffc020065a <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005de:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc02005e0:	0018059b          	addiw	a1,a6,1
ffffffffc02005e4:	1582                	slli	a1,a1,0x20
ffffffffc02005e6:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc02005e8:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005ea:	06c78763          	beq	a5,a2,ffffffffc0200658 <best_fit_alloc_pages+0x94>
        if (p->property >= n&&p->property<min_size) {
ffffffffc02005ee:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02005f2:	00d76763          	bltu	a4,a3,ffffffffc0200600 <best_fit_alloc_pages+0x3c>
ffffffffc02005f6:	00b77563          	bgeu	a4,a1,ffffffffc0200600 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc02005fa:	fe878513          	addi	a0,a5,-24
            min_size=p->property;
ffffffffc02005fe:	85ba                	mv	a1,a4
ffffffffc0200600:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200602:	fec796e3          	bne	a5,a2,ffffffffc02005ee <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200606:	c929                	beqz	a0,ffffffffc0200658 <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc0200608:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc020060c:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc020060e:	710c                	ld	a1,32(a0)
ffffffffc0200610:	02089793          	slli	a5,a7,0x20
ffffffffc0200614:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200616:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200618:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc020061a:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc020061e:	02f6f563          	bgeu	a3,a5,ffffffffc0200648 <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc0200622:	00269793          	slli	a5,a3,0x2
ffffffffc0200626:	97b6                	add	a5,a5,a3
ffffffffc0200628:	078e                	slli	a5,a5,0x3
ffffffffc020062a:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc020062c:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc020062e:	406888bb          	subw	a7,a7,t1
ffffffffc0200632:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc0200636:	0026e693          	ori	a3,a3,2
ffffffffc020063a:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020063c:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200640:	e194                	sd	a3,0(a1)
ffffffffc0200642:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200644:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200646:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200648:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc020064a:	4068083b          	subw	a6,a6,t1
ffffffffc020064e:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc0200652:	9bf5                	andi	a5,a5,-3
ffffffffc0200654:	e51c                	sd	a5,8(a0)
ffffffffc0200656:	8082                	ret
}
ffffffffc0200658:	8082                	ret
        return NULL;
ffffffffc020065a:	4501                	li	a0,0
ffffffffc020065c:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc020065e:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200660:	00001697          	auipc	a3,0x1
ffffffffc0200664:	23868693          	addi	a3,a3,568 # ffffffffc0201898 <etext+0x24a>
ffffffffc0200668:	00001617          	auipc	a2,0x1
ffffffffc020066c:	23860613          	addi	a2,a2,568 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200670:	06d00593          	li	a1,109
ffffffffc0200674:	00001517          	auipc	a0,0x1
ffffffffc0200678:	24450513          	addi	a0,a0,580 # ffffffffc02018b8 <etext+0x26a>
best_fit_alloc_pages(size_t n) {
ffffffffc020067c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020067e:	b4fff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200682 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200682:	715d                	addi	sp,sp,-80
ffffffffc0200684:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200686:	00005417          	auipc	s0,0x5
ffffffffc020068a:	99240413          	addi	s0,s0,-1646 # ffffffffc0205018 <free_area>
ffffffffc020068e:	641c                	ld	a5,8(s0)
ffffffffc0200690:	e486                	sd	ra,72(sp)
ffffffffc0200692:	fc26                	sd	s1,56(sp)
ffffffffc0200694:	f84a                	sd	s2,48(sp)
ffffffffc0200696:	f44e                	sd	s3,40(sp)
ffffffffc0200698:	f052                	sd	s4,32(sp)
ffffffffc020069a:	ec56                	sd	s5,24(sp)
ffffffffc020069c:	e85a                	sd	s6,16(sp)
ffffffffc020069e:	e45e                	sd	s7,8(sp)
ffffffffc02006a0:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006a2:	28878263          	beq	a5,s0,ffffffffc0200926 <best_fit_check+0x2a4>
    int count = 0, total = 0;
ffffffffc02006a6:	4481                	li	s1,0
ffffffffc02006a8:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006aa:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006ae:	8b09                	andi	a4,a4,2
ffffffffc02006b0:	26070f63          	beqz	a4,ffffffffc020092e <best_fit_check+0x2ac>
        count ++, total += p->property;
ffffffffc02006b4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006b8:	679c                	ld	a5,8(a5)
ffffffffc02006ba:	2905                	addiw	s2,s2,1
ffffffffc02006bc:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006be:	fe8796e3          	bne	a5,s0,ffffffffc02006aa <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006c2:	89a6                	mv	s3,s1
ffffffffc02006c4:	0f9000ef          	jal	ffffffffc0200fbc <nr_free_pages>
ffffffffc02006c8:	35351363          	bne	a0,s3,ffffffffc0200a0e <best_fit_check+0x38c>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006cc:	4505                	li	a0,1
ffffffffc02006ce:	0d7000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02006d2:	8a2a                	mv	s4,a0
ffffffffc02006d4:	36050d63          	beqz	a0,ffffffffc0200a4e <best_fit_check+0x3cc>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006d8:	4505                	li	a0,1
ffffffffc02006da:	0cb000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02006de:	89aa                	mv	s3,a0
ffffffffc02006e0:	34050763          	beqz	a0,ffffffffc0200a2e <best_fit_check+0x3ac>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006e4:	4505                	li	a0,1
ffffffffc02006e6:	0bf000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02006ea:	8aaa                	mv	s5,a0
ffffffffc02006ec:	2e050163          	beqz	a0,ffffffffc02009ce <best_fit_check+0x34c>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006f0:	253a0f63          	beq	s4,s3,ffffffffc020094e <best_fit_check+0x2cc>
ffffffffc02006f4:	24aa0d63          	beq	s4,a0,ffffffffc020094e <best_fit_check+0x2cc>
ffffffffc02006f8:	24a98b63          	beq	s3,a0,ffffffffc020094e <best_fit_check+0x2cc>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02006fc:	000a2783          	lw	a5,0(s4)
ffffffffc0200700:	26079763          	bnez	a5,ffffffffc020096e <best_fit_check+0x2ec>
ffffffffc0200704:	0009a783          	lw	a5,0(s3)
ffffffffc0200708:	26079363          	bnez	a5,ffffffffc020096e <best_fit_check+0x2ec>
ffffffffc020070c:	411c                	lw	a5,0(a0)
ffffffffc020070e:	26079063          	bnez	a5,ffffffffc020096e <best_fit_check+0x2ec>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200712:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200716:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac7c55>
ffffffffc020071a:	07b2                	slli	a5,a5,0xc
ffffffffc020071c:	ccd78793          	addi	a5,a5,-819
ffffffffc0200720:	07b2                	slli	a5,a5,0xc
ffffffffc0200722:	00005717          	auipc	a4,0x5
ffffffffc0200726:	94e73703          	ld	a4,-1714(a4) # ffffffffc0205070 <pages>
ffffffffc020072a:	ccd78793          	addi	a5,a5,-819
ffffffffc020072e:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200732:	07b2                	slli	a5,a5,0xc
ffffffffc0200734:	868d                	srai	a3,a3,0x3
ffffffffc0200736:	ccd78793          	addi	a5,a5,-819
ffffffffc020073a:	02f686b3          	mul	a3,a3,a5
ffffffffc020073e:	00002597          	auipc	a1,0x2
ffffffffc0200742:	88a5b583          	ld	a1,-1910(a1) # ffffffffc0201fc8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200746:	00005617          	auipc	a2,0x5
ffffffffc020074a:	92263603          	ld	a2,-1758(a2) # ffffffffc0205068 <npage>
ffffffffc020074e:	0632                	slli	a2,a2,0xc
ffffffffc0200750:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200752:	06b2                	slli	a3,a3,0xc
ffffffffc0200754:	22c6fd63          	bgeu	a3,a2,ffffffffc020098e <best_fit_check+0x30c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200758:	40e986b3          	sub	a3,s3,a4
ffffffffc020075c:	868d                	srai	a3,a3,0x3
ffffffffc020075e:	02f686b3          	mul	a3,a3,a5
ffffffffc0200762:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200764:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200766:	3ec6f463          	bgeu	a3,a2,ffffffffc0200b4e <best_fit_check+0x4cc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020076a:	40e50733          	sub	a4,a0,a4
ffffffffc020076e:	870d                	srai	a4,a4,0x3
ffffffffc0200770:	02f707b3          	mul	a5,a4,a5
ffffffffc0200774:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200776:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200778:	3ac7fb63          	bgeu	a5,a2,ffffffffc0200b2e <best_fit_check+0x4ac>
    assert(alloc_page() == NULL);
ffffffffc020077c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020077e:	00043c03          	ld	s8,0(s0)
ffffffffc0200782:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200786:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020078a:	e400                	sd	s0,8(s0)
ffffffffc020078c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020078e:	00005797          	auipc	a5,0x5
ffffffffc0200792:	8807ad23          	sw	zero,-1894(a5) # ffffffffc0205028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200796:	00f000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc020079a:	36051a63          	bnez	a0,ffffffffc0200b0e <best_fit_check+0x48c>
    free_page(p0);
ffffffffc020079e:	4585                	li	a1,1
ffffffffc02007a0:	8552                	mv	a0,s4
ffffffffc02007a2:	00f000ef          	jal	ffffffffc0200fb0 <free_pages>
    free_page(p1);
ffffffffc02007a6:	4585                	li	a1,1
ffffffffc02007a8:	854e                	mv	a0,s3
ffffffffc02007aa:	007000ef          	jal	ffffffffc0200fb0 <free_pages>
    free_page(p2);
ffffffffc02007ae:	4585                	li	a1,1
ffffffffc02007b0:	8556                	mv	a0,s5
ffffffffc02007b2:	7fe000ef          	jal	ffffffffc0200fb0 <free_pages>
    assert(nr_free == 3);
ffffffffc02007b6:	4818                	lw	a4,16(s0)
ffffffffc02007b8:	478d                	li	a5,3
ffffffffc02007ba:	32f71a63          	bne	a4,a5,ffffffffc0200aee <best_fit_check+0x46c>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007be:	4505                	li	a0,1
ffffffffc02007c0:	7e4000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02007c4:	89aa                	mv	s3,a0
ffffffffc02007c6:	30050463          	beqz	a0,ffffffffc0200ace <best_fit_check+0x44c>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007ca:	4505                	li	a0,1
ffffffffc02007cc:	7d8000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02007d0:	8aaa                	mv	s5,a0
ffffffffc02007d2:	2c050e63          	beqz	a0,ffffffffc0200aae <best_fit_check+0x42c>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007d6:	4505                	li	a0,1
ffffffffc02007d8:	7cc000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02007dc:	8a2a                	mv	s4,a0
ffffffffc02007de:	2a050863          	beqz	a0,ffffffffc0200a8e <best_fit_check+0x40c>
    assert(alloc_page() == NULL);
ffffffffc02007e2:	4505                	li	a0,1
ffffffffc02007e4:	7c0000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02007e8:	28051363          	bnez	a0,ffffffffc0200a6e <best_fit_check+0x3ec>
    free_page(p0);
ffffffffc02007ec:	4585                	li	a1,1
ffffffffc02007ee:	854e                	mv	a0,s3
ffffffffc02007f0:	7c0000ef          	jal	ffffffffc0200fb0 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02007f4:	641c                	ld	a5,8(s0)
ffffffffc02007f6:	1a878c63          	beq	a5,s0,ffffffffc02009ae <best_fit_check+0x32c>
    assert((p = alloc_page()) == p0);
ffffffffc02007fa:	4505                	li	a0,1
ffffffffc02007fc:	7a8000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc0200800:	52a99763          	bne	s3,a0,ffffffffc0200d2e <best_fit_check+0x6ac>
    assert(alloc_page() == NULL);
ffffffffc0200804:	4505                	li	a0,1
ffffffffc0200806:	79e000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc020080a:	50051263          	bnez	a0,ffffffffc0200d0e <best_fit_check+0x68c>
    assert(nr_free == 0);
ffffffffc020080e:	481c                	lw	a5,16(s0)
ffffffffc0200810:	4c079f63          	bnez	a5,ffffffffc0200cee <best_fit_check+0x66c>
    free_page(p);
ffffffffc0200814:	854e                	mv	a0,s3
ffffffffc0200816:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200818:	01843023          	sd	s8,0(s0)
ffffffffc020081c:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200820:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200824:	78c000ef          	jal	ffffffffc0200fb0 <free_pages>
    free_page(p1);
ffffffffc0200828:	4585                	li	a1,1
ffffffffc020082a:	8556                	mv	a0,s5
ffffffffc020082c:	784000ef          	jal	ffffffffc0200fb0 <free_pages>
    free_page(p2);
ffffffffc0200830:	4585                	li	a1,1
ffffffffc0200832:	8552                	mv	a0,s4
ffffffffc0200834:	77c000ef          	jal	ffffffffc0200fb0 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200838:	4515                	li	a0,5
ffffffffc020083a:	76a000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc020083e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200840:	48050763          	beqz	a0,ffffffffc0200cce <best_fit_check+0x64c>
    assert(!PageProperty(p0));
ffffffffc0200844:	651c                	ld	a5,8(a0)
ffffffffc0200846:	8b89                	andi	a5,a5,2
ffffffffc0200848:	46079363          	bnez	a5,ffffffffc0200cae <best_fit_check+0x62c>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020084c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020084e:	00043b03          	ld	s6,0(s0)
ffffffffc0200852:	00843a83          	ld	s5,8(s0)
ffffffffc0200856:	e000                	sd	s0,0(s0)
ffffffffc0200858:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020085a:	74a000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc020085e:	42051863          	bnez	a0,ffffffffc0200c8e <best_fit_check+0x60c>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200862:	4589                	li	a1,2
ffffffffc0200864:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200868:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc020086c:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200870:	00004797          	auipc	a5,0x4
ffffffffc0200874:	7a07ac23          	sw	zero,1976(a5) # ffffffffc0205028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200878:	738000ef          	jal	ffffffffc0200fb0 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc020087c:	8562                	mv	a0,s8
ffffffffc020087e:	4585                	li	a1,1
ffffffffc0200880:	730000ef          	jal	ffffffffc0200fb0 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200884:	4511                	li	a0,4
ffffffffc0200886:	71e000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc020088a:	3e051263          	bnez	a0,ffffffffc0200c6e <best_fit_check+0x5ec>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc020088e:	0309b783          	ld	a5,48(s3)
ffffffffc0200892:	8b89                	andi	a5,a5,2
ffffffffc0200894:	3a078d63          	beqz	a5,ffffffffc0200c4e <best_fit_check+0x5cc>
ffffffffc0200898:	0389a703          	lw	a4,56(s3)
ffffffffc020089c:	4789                	li	a5,2
ffffffffc020089e:	3af71863          	bne	a4,a5,ffffffffc0200c4e <best_fit_check+0x5cc>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008a2:	4505                	li	a0,1
ffffffffc02008a4:	700000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02008a8:	8a2a                	mv	s4,a0
ffffffffc02008aa:	38050263          	beqz	a0,ffffffffc0200c2e <best_fit_check+0x5ac>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008ae:	4509                	li	a0,2
ffffffffc02008b0:	6f4000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02008b4:	34050d63          	beqz	a0,ffffffffc0200c0e <best_fit_check+0x58c>
    assert(p0 + 4 == p1);
ffffffffc02008b8:	334c1b63          	bne	s8,s4,ffffffffc0200bee <best_fit_check+0x56c>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008bc:	854e                	mv	a0,s3
ffffffffc02008be:	4595                	li	a1,5
ffffffffc02008c0:	6f0000ef          	jal	ffffffffc0200fb0 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008c4:	4515                	li	a0,5
ffffffffc02008c6:	6de000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02008ca:	89aa                	mv	s3,a0
ffffffffc02008cc:	30050163          	beqz	a0,ffffffffc0200bce <best_fit_check+0x54c>
    assert(alloc_page() == NULL);
ffffffffc02008d0:	4505                	li	a0,1
ffffffffc02008d2:	6d2000ef          	jal	ffffffffc0200fa4 <alloc_pages>
ffffffffc02008d6:	2c051c63          	bnez	a0,ffffffffc0200bae <best_fit_check+0x52c>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008da:	481c                	lw	a5,16(s0)
ffffffffc02008dc:	2a079963          	bnez	a5,ffffffffc0200b8e <best_fit_check+0x50c>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008e0:	4595                	li	a1,5
ffffffffc02008e2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02008e4:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02008e8:	01643023          	sd	s6,0(s0)
ffffffffc02008ec:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02008f0:	6c0000ef          	jal	ffffffffc0200fb0 <free_pages>
    return listelm->next;
ffffffffc02008f4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008f6:	00878963          	beq	a5,s0,ffffffffc0200908 <best_fit_check+0x286>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02008fa:	ff87a703          	lw	a4,-8(a5)
ffffffffc02008fe:	679c                	ld	a5,8(a5)
ffffffffc0200900:	397d                	addiw	s2,s2,-1
ffffffffc0200902:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200904:	fe879be3          	bne	a5,s0,ffffffffc02008fa <best_fit_check+0x278>
    }
    assert(count == 0);
ffffffffc0200908:	26091363          	bnez	s2,ffffffffc0200b6e <best_fit_check+0x4ec>
    assert(total == 0);
ffffffffc020090c:	e0ed                	bnez	s1,ffffffffc02009ee <best_fit_check+0x36c>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc020090e:	60a6                	ld	ra,72(sp)
ffffffffc0200910:	6406                	ld	s0,64(sp)
ffffffffc0200912:	74e2                	ld	s1,56(sp)
ffffffffc0200914:	7942                	ld	s2,48(sp)
ffffffffc0200916:	79a2                	ld	s3,40(sp)
ffffffffc0200918:	7a02                	ld	s4,32(sp)
ffffffffc020091a:	6ae2                	ld	s5,24(sp)
ffffffffc020091c:	6b42                	ld	s6,16(sp)
ffffffffc020091e:	6ba2                	ld	s7,8(sp)
ffffffffc0200920:	6c02                	ld	s8,0(sp)
ffffffffc0200922:	6161                	addi	sp,sp,80
ffffffffc0200924:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200926:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200928:	4481                	li	s1,0
ffffffffc020092a:	4901                	li	s2,0
ffffffffc020092c:	bb61                	j	ffffffffc02006c4 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc020092e:	00001697          	auipc	a3,0x1
ffffffffc0200932:	fa268693          	addi	a3,a3,-94 # ffffffffc02018d0 <etext+0x282>
ffffffffc0200936:	00001617          	auipc	a2,0x1
ffffffffc020093a:	f6a60613          	addi	a2,a2,-150 # ffffffffc02018a0 <etext+0x252>
ffffffffc020093e:	11200593          	li	a1,274
ffffffffc0200942:	00001517          	auipc	a0,0x1
ffffffffc0200946:	f7650513          	addi	a0,a0,-138 # ffffffffc02018b8 <etext+0x26a>
ffffffffc020094a:	883ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020094e:	00001697          	auipc	a3,0x1
ffffffffc0200952:	01268693          	addi	a3,a3,18 # ffffffffc0201960 <etext+0x312>
ffffffffc0200956:	00001617          	auipc	a2,0x1
ffffffffc020095a:	f4a60613          	addi	a2,a2,-182 # ffffffffc02018a0 <etext+0x252>
ffffffffc020095e:	0de00593          	li	a1,222
ffffffffc0200962:	00001517          	auipc	a0,0x1
ffffffffc0200966:	f5650513          	addi	a0,a0,-170 # ffffffffc02018b8 <etext+0x26a>
ffffffffc020096a:	863ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020096e:	00001697          	auipc	a3,0x1
ffffffffc0200972:	01a68693          	addi	a3,a3,26 # ffffffffc0201988 <etext+0x33a>
ffffffffc0200976:	00001617          	auipc	a2,0x1
ffffffffc020097a:	f2a60613          	addi	a2,a2,-214 # ffffffffc02018a0 <etext+0x252>
ffffffffc020097e:	0df00593          	li	a1,223
ffffffffc0200982:	00001517          	auipc	a0,0x1
ffffffffc0200986:	f3650513          	addi	a0,a0,-202 # ffffffffc02018b8 <etext+0x26a>
ffffffffc020098a:	843ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020098e:	00001697          	auipc	a3,0x1
ffffffffc0200992:	03a68693          	addi	a3,a3,58 # ffffffffc02019c8 <etext+0x37a>
ffffffffc0200996:	00001617          	auipc	a2,0x1
ffffffffc020099a:	f0a60613          	addi	a2,a2,-246 # ffffffffc02018a0 <etext+0x252>
ffffffffc020099e:	0e100593          	li	a1,225
ffffffffc02009a2:	00001517          	auipc	a0,0x1
ffffffffc02009a6:	f1650513          	addi	a0,a0,-234 # ffffffffc02018b8 <etext+0x26a>
ffffffffc02009aa:	823ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009ae:	00001697          	auipc	a3,0x1
ffffffffc02009b2:	0a268693          	addi	a3,a3,162 # ffffffffc0201a50 <etext+0x402>
ffffffffc02009b6:	00001617          	auipc	a2,0x1
ffffffffc02009ba:	eea60613          	addi	a2,a2,-278 # ffffffffc02018a0 <etext+0x252>
ffffffffc02009be:	0fa00593          	li	a1,250
ffffffffc02009c2:	00001517          	auipc	a0,0x1
ffffffffc02009c6:	ef650513          	addi	a0,a0,-266 # ffffffffc02018b8 <etext+0x26a>
ffffffffc02009ca:	803ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009ce:	00001697          	auipc	a3,0x1
ffffffffc02009d2:	f7268693          	addi	a3,a3,-142 # ffffffffc0201940 <etext+0x2f2>
ffffffffc02009d6:	00001617          	auipc	a2,0x1
ffffffffc02009da:	eca60613          	addi	a2,a2,-310 # ffffffffc02018a0 <etext+0x252>
ffffffffc02009de:	0dc00593          	li	a1,220
ffffffffc02009e2:	00001517          	auipc	a0,0x1
ffffffffc02009e6:	ed650513          	addi	a0,a0,-298 # ffffffffc02018b8 <etext+0x26a>
ffffffffc02009ea:	fe2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == 0);
ffffffffc02009ee:	00001697          	auipc	a3,0x1
ffffffffc02009f2:	19268693          	addi	a3,a3,402 # ffffffffc0201b80 <etext+0x532>
ffffffffc02009f6:	00001617          	auipc	a2,0x1
ffffffffc02009fa:	eaa60613          	addi	a2,a2,-342 # ffffffffc02018a0 <etext+0x252>
ffffffffc02009fe:	15400593          	li	a1,340
ffffffffc0200a02:	00001517          	auipc	a0,0x1
ffffffffc0200a06:	eb650513          	addi	a0,a0,-330 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200a0a:	fc2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a0e:	00001697          	auipc	a3,0x1
ffffffffc0200a12:	ed268693          	addi	a3,a3,-302 # ffffffffc02018e0 <etext+0x292>
ffffffffc0200a16:	00001617          	auipc	a2,0x1
ffffffffc0200a1a:	e8a60613          	addi	a2,a2,-374 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200a1e:	11500593          	li	a1,277
ffffffffc0200a22:	00001517          	auipc	a0,0x1
ffffffffc0200a26:	e9650513          	addi	a0,a0,-362 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200a2a:	fa2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a2e:	00001697          	auipc	a3,0x1
ffffffffc0200a32:	ef268693          	addi	a3,a3,-270 # ffffffffc0201920 <etext+0x2d2>
ffffffffc0200a36:	00001617          	auipc	a2,0x1
ffffffffc0200a3a:	e6a60613          	addi	a2,a2,-406 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200a3e:	0db00593          	li	a1,219
ffffffffc0200a42:	00001517          	auipc	a0,0x1
ffffffffc0200a46:	e7650513          	addi	a0,a0,-394 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200a4a:	f82ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a4e:	00001697          	auipc	a3,0x1
ffffffffc0200a52:	eb268693          	addi	a3,a3,-334 # ffffffffc0201900 <etext+0x2b2>
ffffffffc0200a56:	00001617          	auipc	a2,0x1
ffffffffc0200a5a:	e4a60613          	addi	a2,a2,-438 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200a5e:	0da00593          	li	a1,218
ffffffffc0200a62:	00001517          	auipc	a0,0x1
ffffffffc0200a66:	e5650513          	addi	a0,a0,-426 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200a6a:	f62ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a6e:	00001697          	auipc	a3,0x1
ffffffffc0200a72:	fba68693          	addi	a3,a3,-70 # ffffffffc0201a28 <etext+0x3da>
ffffffffc0200a76:	00001617          	auipc	a2,0x1
ffffffffc0200a7a:	e2a60613          	addi	a2,a2,-470 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200a7e:	0f700593          	li	a1,247
ffffffffc0200a82:	00001517          	auipc	a0,0x1
ffffffffc0200a86:	e3650513          	addi	a0,a0,-458 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200a8a:	f42ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a8e:	00001697          	auipc	a3,0x1
ffffffffc0200a92:	eb268693          	addi	a3,a3,-334 # ffffffffc0201940 <etext+0x2f2>
ffffffffc0200a96:	00001617          	auipc	a2,0x1
ffffffffc0200a9a:	e0a60613          	addi	a2,a2,-502 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200a9e:	0f500593          	li	a1,245
ffffffffc0200aa2:	00001517          	auipc	a0,0x1
ffffffffc0200aa6:	e1650513          	addi	a0,a0,-490 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200aaa:	f22ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200aae:	00001697          	auipc	a3,0x1
ffffffffc0200ab2:	e7268693          	addi	a3,a3,-398 # ffffffffc0201920 <etext+0x2d2>
ffffffffc0200ab6:	00001617          	auipc	a2,0x1
ffffffffc0200aba:	dea60613          	addi	a2,a2,-534 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200abe:	0f400593          	li	a1,244
ffffffffc0200ac2:	00001517          	auipc	a0,0x1
ffffffffc0200ac6:	df650513          	addi	a0,a0,-522 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200aca:	f02ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ace:	00001697          	auipc	a3,0x1
ffffffffc0200ad2:	e3268693          	addi	a3,a3,-462 # ffffffffc0201900 <etext+0x2b2>
ffffffffc0200ad6:	00001617          	auipc	a2,0x1
ffffffffc0200ada:	dca60613          	addi	a2,a2,-566 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200ade:	0f300593          	li	a1,243
ffffffffc0200ae2:	00001517          	auipc	a0,0x1
ffffffffc0200ae6:	dd650513          	addi	a0,a0,-554 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200aea:	ee2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 3);
ffffffffc0200aee:	00001697          	auipc	a3,0x1
ffffffffc0200af2:	f5268693          	addi	a3,a3,-174 # ffffffffc0201a40 <etext+0x3f2>
ffffffffc0200af6:	00001617          	auipc	a2,0x1
ffffffffc0200afa:	daa60613          	addi	a2,a2,-598 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200afe:	0f100593          	li	a1,241
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	db650513          	addi	a0,a0,-586 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200b0a:	ec2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b0e:	00001697          	auipc	a3,0x1
ffffffffc0200b12:	f1a68693          	addi	a3,a3,-230 # ffffffffc0201a28 <etext+0x3da>
ffffffffc0200b16:	00001617          	auipc	a2,0x1
ffffffffc0200b1a:	d8a60613          	addi	a2,a2,-630 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200b1e:	0ec00593          	li	a1,236
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	d9650513          	addi	a0,a0,-618 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200b2a:	ea2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b2e:	00001697          	auipc	a3,0x1
ffffffffc0200b32:	eda68693          	addi	a3,a3,-294 # ffffffffc0201a08 <etext+0x3ba>
ffffffffc0200b36:	00001617          	auipc	a2,0x1
ffffffffc0200b3a:	d6a60613          	addi	a2,a2,-662 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200b3e:	0e300593          	li	a1,227
ffffffffc0200b42:	00001517          	auipc	a0,0x1
ffffffffc0200b46:	d7650513          	addi	a0,a0,-650 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200b4a:	e82ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b4e:	00001697          	auipc	a3,0x1
ffffffffc0200b52:	e9a68693          	addi	a3,a3,-358 # ffffffffc02019e8 <etext+0x39a>
ffffffffc0200b56:	00001617          	auipc	a2,0x1
ffffffffc0200b5a:	d4a60613          	addi	a2,a2,-694 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200b5e:	0e200593          	li	a1,226
ffffffffc0200b62:	00001517          	auipc	a0,0x1
ffffffffc0200b66:	d5650513          	addi	a0,a0,-682 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200b6a:	e62ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(count == 0);
ffffffffc0200b6e:	00001697          	auipc	a3,0x1
ffffffffc0200b72:	00268693          	addi	a3,a3,2 # ffffffffc0201b70 <etext+0x522>
ffffffffc0200b76:	00001617          	auipc	a2,0x1
ffffffffc0200b7a:	d2a60613          	addi	a2,a2,-726 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200b7e:	15300593          	li	a1,339
ffffffffc0200b82:	00001517          	auipc	a0,0x1
ffffffffc0200b86:	d3650513          	addi	a0,a0,-714 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200b8a:	e42ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200b8e:	00001697          	auipc	a3,0x1
ffffffffc0200b92:	efa68693          	addi	a3,a3,-262 # ffffffffc0201a88 <etext+0x43a>
ffffffffc0200b96:	00001617          	auipc	a2,0x1
ffffffffc0200b9a:	d0a60613          	addi	a2,a2,-758 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200b9e:	14800593          	li	a1,328
ffffffffc0200ba2:	00001517          	auipc	a0,0x1
ffffffffc0200ba6:	d1650513          	addi	a0,a0,-746 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200baa:	e22ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bae:	00001697          	auipc	a3,0x1
ffffffffc0200bb2:	e7a68693          	addi	a3,a3,-390 # ffffffffc0201a28 <etext+0x3da>
ffffffffc0200bb6:	00001617          	auipc	a2,0x1
ffffffffc0200bba:	cea60613          	addi	a2,a2,-790 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200bbe:	14200593          	li	a1,322
ffffffffc0200bc2:	00001517          	auipc	a0,0x1
ffffffffc0200bc6:	cf650513          	addi	a0,a0,-778 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200bca:	e02ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bce:	00001697          	auipc	a3,0x1
ffffffffc0200bd2:	f8268693          	addi	a3,a3,-126 # ffffffffc0201b50 <etext+0x502>
ffffffffc0200bd6:	00001617          	auipc	a2,0x1
ffffffffc0200bda:	cca60613          	addi	a2,a2,-822 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200bde:	14100593          	li	a1,321
ffffffffc0200be2:	00001517          	auipc	a0,0x1
ffffffffc0200be6:	cd650513          	addi	a0,a0,-810 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200bea:	de2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200bee:	00001697          	auipc	a3,0x1
ffffffffc0200bf2:	f5268693          	addi	a3,a3,-174 # ffffffffc0201b40 <etext+0x4f2>
ffffffffc0200bf6:	00001617          	auipc	a2,0x1
ffffffffc0200bfa:	caa60613          	addi	a2,a2,-854 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200bfe:	13900593          	li	a1,313
ffffffffc0200c02:	00001517          	auipc	a0,0x1
ffffffffc0200c06:	cb650513          	addi	a0,a0,-842 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200c0a:	dc2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c0e:	00001697          	auipc	a3,0x1
ffffffffc0200c12:	f1a68693          	addi	a3,a3,-230 # ffffffffc0201b28 <etext+0x4da>
ffffffffc0200c16:	00001617          	auipc	a2,0x1
ffffffffc0200c1a:	c8a60613          	addi	a2,a2,-886 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200c1e:	13800593          	li	a1,312
ffffffffc0200c22:	00001517          	auipc	a0,0x1
ffffffffc0200c26:	c9650513          	addi	a0,a0,-874 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200c2a:	da2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c2e:	00001697          	auipc	a3,0x1
ffffffffc0200c32:	eda68693          	addi	a3,a3,-294 # ffffffffc0201b08 <etext+0x4ba>
ffffffffc0200c36:	00001617          	auipc	a2,0x1
ffffffffc0200c3a:	c6a60613          	addi	a2,a2,-918 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200c3e:	13700593          	li	a1,311
ffffffffc0200c42:	00001517          	auipc	a0,0x1
ffffffffc0200c46:	c7650513          	addi	a0,a0,-906 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200c4a:	d82ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c4e:	00001697          	auipc	a3,0x1
ffffffffc0200c52:	e8a68693          	addi	a3,a3,-374 # ffffffffc0201ad8 <etext+0x48a>
ffffffffc0200c56:	00001617          	auipc	a2,0x1
ffffffffc0200c5a:	c4a60613          	addi	a2,a2,-950 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200c5e:	13500593          	li	a1,309
ffffffffc0200c62:	00001517          	auipc	a0,0x1
ffffffffc0200c66:	c5650513          	addi	a0,a0,-938 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200c6a:	d62ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c6e:	00001697          	auipc	a3,0x1
ffffffffc0200c72:	e5268693          	addi	a3,a3,-430 # ffffffffc0201ac0 <etext+0x472>
ffffffffc0200c76:	00001617          	auipc	a2,0x1
ffffffffc0200c7a:	c2a60613          	addi	a2,a2,-982 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200c7e:	13400593          	li	a1,308
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	c3650513          	addi	a0,a0,-970 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200c8a:	d42ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c8e:	00001697          	auipc	a3,0x1
ffffffffc0200c92:	d9a68693          	addi	a3,a3,-614 # ffffffffc0201a28 <etext+0x3da>
ffffffffc0200c96:	00001617          	auipc	a2,0x1
ffffffffc0200c9a:	c0a60613          	addi	a2,a2,-1014 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200c9e:	12800593          	li	a1,296
ffffffffc0200ca2:	00001517          	auipc	a0,0x1
ffffffffc0200ca6:	c1650513          	addi	a0,a0,-1002 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200caa:	d22ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cae:	00001697          	auipc	a3,0x1
ffffffffc0200cb2:	dfa68693          	addi	a3,a3,-518 # ffffffffc0201aa8 <etext+0x45a>
ffffffffc0200cb6:	00001617          	auipc	a2,0x1
ffffffffc0200cba:	bea60613          	addi	a2,a2,-1046 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200cbe:	11f00593          	li	a1,287
ffffffffc0200cc2:	00001517          	auipc	a0,0x1
ffffffffc0200cc6:	bf650513          	addi	a0,a0,-1034 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200cca:	d02ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != NULL);
ffffffffc0200cce:	00001697          	auipc	a3,0x1
ffffffffc0200cd2:	dca68693          	addi	a3,a3,-566 # ffffffffc0201a98 <etext+0x44a>
ffffffffc0200cd6:	00001617          	auipc	a2,0x1
ffffffffc0200cda:	bca60613          	addi	a2,a2,-1078 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200cde:	11e00593          	li	a1,286
ffffffffc0200ce2:	00001517          	auipc	a0,0x1
ffffffffc0200ce6:	bd650513          	addi	a0,a0,-1066 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200cea:	ce2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200cee:	00001697          	auipc	a3,0x1
ffffffffc0200cf2:	d9a68693          	addi	a3,a3,-614 # ffffffffc0201a88 <etext+0x43a>
ffffffffc0200cf6:	00001617          	auipc	a2,0x1
ffffffffc0200cfa:	baa60613          	addi	a2,a2,-1110 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200cfe:	10000593          	li	a1,256
ffffffffc0200d02:	00001517          	auipc	a0,0x1
ffffffffc0200d06:	bb650513          	addi	a0,a0,-1098 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200d0a:	cc2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d0e:	00001697          	auipc	a3,0x1
ffffffffc0200d12:	d1a68693          	addi	a3,a3,-742 # ffffffffc0201a28 <etext+0x3da>
ffffffffc0200d16:	00001617          	auipc	a2,0x1
ffffffffc0200d1a:	b8a60613          	addi	a2,a2,-1142 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200d1e:	0fe00593          	li	a1,254
ffffffffc0200d22:	00001517          	auipc	a0,0x1
ffffffffc0200d26:	b9650513          	addi	a0,a0,-1130 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200d2a:	ca2ff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d2e:	00001697          	auipc	a3,0x1
ffffffffc0200d32:	d3a68693          	addi	a3,a3,-710 # ffffffffc0201a68 <etext+0x41a>
ffffffffc0200d36:	00001617          	auipc	a2,0x1
ffffffffc0200d3a:	b6a60613          	addi	a2,a2,-1174 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200d3e:	0fd00593          	li	a1,253
ffffffffc0200d42:	00001517          	auipc	a0,0x1
ffffffffc0200d46:	b7650513          	addi	a0,a0,-1162 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200d4a:	c82ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200d4e <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d4e:	1141                	addi	sp,sp,-16
ffffffffc0200d50:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d52:	14058c63          	beqz	a1,ffffffffc0200eaa <best_fit_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0200d56:	00259713          	slli	a4,a1,0x2
ffffffffc0200d5a:	972e                	add	a4,a4,a1
ffffffffc0200d5c:	070e                	slli	a4,a4,0x3
ffffffffc0200d5e:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200d62:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200d64:	cf09                	beqz	a4,ffffffffc0200d7e <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d66:	6798                	ld	a4,8(a5)
ffffffffc0200d68:	8b0d                	andi	a4,a4,3
ffffffffc0200d6a:	12071063          	bnez	a4,ffffffffc0200e8a <best_fit_free_pages+0x13c>
        p->flags = 0;
ffffffffc0200d6e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d72:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d76:	02878793          	addi	a5,a5,40
ffffffffc0200d7a:	fed796e3          	bne	a5,a3,ffffffffc0200d66 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d7e:	00853883          	ld	a7,8(a0)
    nr_free+=n;
ffffffffc0200d82:	00004697          	auipc	a3,0x4
ffffffffc0200d86:	29668693          	addi	a3,a3,662 # ffffffffc0205018 <free_area>
ffffffffc0200d8a:	4a98                	lw	a4,16(a3)
    base->property=n;
ffffffffc0200d8c:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200d8e:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200d90:	0028e613          	ori	a2,a7,2
    base->property=n;
ffffffffc0200d94:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200d96:	e510                	sd	a2,8(a0)
    nr_free+=n;
ffffffffc0200d98:	9f2d                	addw	a4,a4,a1
ffffffffc0200d9a:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200d9c:	0ad78763          	beq	a5,a3,ffffffffc0200e4a <best_fit_free_pages+0xfc>
            struct Page* page = le2page(le, page_link);
ffffffffc0200da0:	fe878713          	addi	a4,a5,-24
ffffffffc0200da4:	4801                	li	a6,0
ffffffffc0200da6:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200daa:	00e56a63          	bltu	a0,a4,ffffffffc0200dbe <best_fit_free_pages+0x70>
    return listelm->next;
ffffffffc0200dae:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200db0:	06d70563          	beq	a4,a3,ffffffffc0200e1a <best_fit_free_pages+0xcc>
    struct Page *p = base;
ffffffffc0200db4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200db6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dba:	fee57ae3          	bgeu	a0,a4,ffffffffc0200dae <best_fit_free_pages+0x60>
ffffffffc0200dbe:	00080463          	beqz	a6,ffffffffc0200dc6 <best_fit_free_pages+0x78>
ffffffffc0200dc2:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dc6:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200dca:	e390                	sd	a2,0(a5)
ffffffffc0200dcc:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc0200dd0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200dd2:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200dd6:	02d80063          	beq	a6,a3,ffffffffc0200df6 <best_fit_free_pages+0xa8>
        if(p+p->property==base)
ffffffffc0200dda:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200dde:	fe880313          	addi	t1,a6,-24
        if(p+p->property==base)
ffffffffc0200de2:	020e1613          	slli	a2,t3,0x20
ffffffffc0200de6:	9201                	srli	a2,a2,0x20
ffffffffc0200de8:	00261713          	slli	a4,a2,0x2
ffffffffc0200dec:	9732                	add	a4,a4,a2
ffffffffc0200dee:	070e                	slli	a4,a4,0x3
ffffffffc0200df0:	971a                	add	a4,a4,t1
ffffffffc0200df2:	02e50e63          	beq	a0,a4,ffffffffc0200e2e <best_fit_free_pages+0xe0>
    if (le != &free_list) {
ffffffffc0200df6:	00d78f63          	beq	a5,a3,ffffffffc0200e14 <best_fit_free_pages+0xc6>
        if (base + base->property == p) {
ffffffffc0200dfa:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200dfc:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0200e00:	02059613          	slli	a2,a1,0x20
ffffffffc0200e04:	9201                	srli	a2,a2,0x20
ffffffffc0200e06:	00261713          	slli	a4,a2,0x2
ffffffffc0200e0a:	9732                	add	a4,a4,a2
ffffffffc0200e0c:	070e                	slli	a4,a4,0x3
ffffffffc0200e0e:	972a                	add	a4,a4,a0
ffffffffc0200e10:	04e68a63          	beq	a3,a4,ffffffffc0200e64 <best_fit_free_pages+0x116>
}
ffffffffc0200e14:	60a2                	ld	ra,8(sp)
ffffffffc0200e16:	0141                	addi	sp,sp,16
ffffffffc0200e18:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e1a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e1c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e1e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e20:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200e22:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e24:	02d70c63          	beq	a4,a3,ffffffffc0200e5c <best_fit_free_pages+0x10e>
ffffffffc0200e28:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc0200e2a:	87ba                	mv	a5,a4
ffffffffc0200e2c:	b769                	j	ffffffffc0200db6 <best_fit_free_pages+0x68>
            p->property+=base->property;
ffffffffc0200e2e:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e32:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e36:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e3a:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e3e:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e42:	0107b023          	sd	a6,0(a5)
            base=p;//更新base的值
ffffffffc0200e46:	851a                	mv	a0,t1
ffffffffc0200e48:	b77d                	j	ffffffffc0200df6 <best_fit_free_pages+0xa8>
}
ffffffffc0200e4a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e4c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e50:	e398                	sd	a4,0(a5)
ffffffffc0200e52:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200e54:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e56:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200e58:	0141                	addi	sp,sp,16
ffffffffc0200e5a:	8082                	ret
    return listelm->prev;
ffffffffc0200e5c:	883e                	mv	a6,a5
ffffffffc0200e5e:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e60:	87b6                	mv	a5,a3
ffffffffc0200e62:	bf95                	j	ffffffffc0200dd6 <best_fit_free_pages+0x88>
            base->property += p->property;
ffffffffc0200e64:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e68:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200e6c:	0007b803          	ld	a6,0(a5)
ffffffffc0200e70:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e72:	9ead                	addw	a3,a3,a1
ffffffffc0200e74:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200e76:	9b75                	andi	a4,a4,-3
ffffffffc0200e78:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e7c:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e7e:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e82:	01063023          	sd	a6,0(a2)
ffffffffc0200e86:	0141                	addi	sp,sp,16
ffffffffc0200e88:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200e8a:	00001697          	auipc	a3,0x1
ffffffffc0200e8e:	d0668693          	addi	a3,a3,-762 # ffffffffc0201b90 <etext+0x542>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200e9a:	09500593          	li	a1,149
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	a1a50513          	addi	a0,a0,-1510 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200ea6:	b26ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200eaa:	00001697          	auipc	a3,0x1
ffffffffc0200eae:	9ee68693          	addi	a3,a3,-1554 # ffffffffc0201898 <etext+0x24a>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	9ee60613          	addi	a2,a2,-1554 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200eba:	09200593          	li	a1,146
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200ec6:	b06ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200eca <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200eca:	1141                	addi	sp,sp,-16
ffffffffc0200ecc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ece:	c9dd                	beqz	a1,ffffffffc0200f84 <best_fit_init_memmap+0xba>
    for (; p != base + n; p ++) {
ffffffffc0200ed0:	00259713          	slli	a4,a1,0x2
ffffffffc0200ed4:	972e                	add	a4,a4,a1
ffffffffc0200ed6:	070e                	slli	a4,a4,0x3
ffffffffc0200ed8:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200edc:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200ede:	cf11                	beqz	a4,ffffffffc0200efa <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200ee0:	6798                	ld	a4,8(a5)
ffffffffc0200ee2:	8b05                	andi	a4,a4,1
ffffffffc0200ee4:	c341                	beqz	a4,ffffffffc0200f64 <best_fit_init_memmap+0x9a>
        p->flags=0;
ffffffffc0200ee6:	0007b423          	sd	zero,8(a5)
        p->property=0;
ffffffffc0200eea:	0007a823          	sw	zero,16(a5)
ffffffffc0200eee:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200ef2:	02878793          	addi	a5,a5,40
ffffffffc0200ef6:	fed795e3          	bne	a5,a3,ffffffffc0200ee0 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200efa:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200efc:	00004697          	auipc	a3,0x4
ffffffffc0200f00:	11c68693          	addi	a3,a3,284 # ffffffffc0205018 <free_area>
ffffffffc0200f04:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f06:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200f08:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f0a:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f0e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f10:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f12:	9f2d                	addw	a4,a4,a1
ffffffffc0200f14:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f16:	00d79763          	bne	a5,a3,ffffffffc0200f24 <best_fit_init_memmap+0x5a>
ffffffffc0200f1a:	a01d                	j	ffffffffc0200f40 <best_fit_init_memmap+0x76>
    return listelm->next;
ffffffffc0200f1c:	6798                	ld	a4,8(a5)
            }else if(list_next(le)==&free_list)
ffffffffc0200f1e:	02d70a63          	beq	a4,a3,ffffffffc0200f52 <best_fit_init_memmap+0x88>
ffffffffc0200f22:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f24:	fe878713          	addi	a4,a5,-24
            if(base<page)
ffffffffc0200f28:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f1c <best_fit_init_memmap+0x52>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f2c:	6398                	ld	a4,0(a5)
                list_add_before(le,&(base->page_link));
ffffffffc0200f2e:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f32:	e394                	sd	a3,0(a5)
}
ffffffffc0200f34:	60a2                	ld	ra,8(sp)
ffffffffc0200f36:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200f38:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f3a:	ed18                	sd	a4,24(a0)
ffffffffc0200f3c:	0141                	addi	sp,sp,16
ffffffffc0200f3e:	8082                	ret
ffffffffc0200f40:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f42:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f46:	e398                	sd	a4,0(a5)
ffffffffc0200f48:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200f4a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f4c:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200f4e:	0141                	addi	sp,sp,16
ffffffffc0200f50:	8082                	ret
ffffffffc0200f52:	60a2                	ld	ra,8(sp)
                list_add(le,&(base->page_link));
ffffffffc0200f54:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f58:	e798                	sd	a4,8(a5)
ffffffffc0200f5a:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc0200f5c:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200f5e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200f60:	0141                	addi	sp,sp,16
ffffffffc0200f62:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f64:	00001697          	auipc	a3,0x1
ffffffffc0200f68:	c5468693          	addi	a3,a3,-940 # ffffffffc0201bb8 <etext+0x56a>
ffffffffc0200f6c:	00001617          	auipc	a2,0x1
ffffffffc0200f70:	93460613          	addi	a2,a2,-1740 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200f74:	04a00593          	li	a1,74
ffffffffc0200f78:	00001517          	auipc	a0,0x1
ffffffffc0200f7c:	94050513          	addi	a0,a0,-1728 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200f80:	a4cff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200f84:	00001697          	auipc	a3,0x1
ffffffffc0200f88:	91468693          	addi	a3,a3,-1772 # ffffffffc0201898 <etext+0x24a>
ffffffffc0200f8c:	00001617          	auipc	a2,0x1
ffffffffc0200f90:	91460613          	addi	a2,a2,-1772 # ffffffffc02018a0 <etext+0x252>
ffffffffc0200f94:	04700593          	li	a1,71
ffffffffc0200f98:	00001517          	auipc	a0,0x1
ffffffffc0200f9c:	92050513          	addi	a0,a0,-1760 # ffffffffc02018b8 <etext+0x26a>
ffffffffc0200fa0:	a2cff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200fa4 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200fa4:	00004797          	auipc	a5,0x4
ffffffffc0200fa8:	0a47b783          	ld	a5,164(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fac:	6f9c                	ld	a5,24(a5)
ffffffffc0200fae:	8782                	jr	a5

ffffffffc0200fb0 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200fb0:	00004797          	auipc	a5,0x4
ffffffffc0200fb4:	0987b783          	ld	a5,152(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fb8:	739c                	ld	a5,32(a5)
ffffffffc0200fba:	8782                	jr	a5

ffffffffc0200fbc <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200fbc:	00004797          	auipc	a5,0x4
ffffffffc0200fc0:	08c7b783          	ld	a5,140(a5) # ffffffffc0205048 <pmm_manager>
ffffffffc0200fc4:	779c                	ld	a5,40(a5)
ffffffffc0200fc6:	8782                	jr	a5

ffffffffc0200fc8 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200fc8:	00001797          	auipc	a5,0x1
ffffffffc0200fcc:	e3878793          	addi	a5,a5,-456 # ffffffffc0201e00 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fd0:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200fd2:	7179                	addi	sp,sp,-48
ffffffffc0200fd4:	f406                	sd	ra,40(sp)
ffffffffc0200fd6:	f022                	sd	s0,32(sp)
ffffffffc0200fd8:	ec26                	sd	s1,24(sp)
ffffffffc0200fda:	e44e                	sd	s3,8(sp)
ffffffffc0200fdc:	e84a                	sd	s2,16(sp)
ffffffffc0200fde:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200fe0:	00004417          	auipc	s0,0x4
ffffffffc0200fe4:	06840413          	addi	s0,s0,104 # ffffffffc0205048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fe8:	00001517          	auipc	a0,0x1
ffffffffc0200fec:	bf850513          	addi	a0,a0,-1032 # ffffffffc0201be0 <etext+0x592>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200ff0:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ff2:	958ff0ef          	jal	ffffffffc020014a <cprintf>
    pmm_manager->init();
ffffffffc0200ff6:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ff8:	00004497          	auipc	s1,0x4
ffffffffc0200ffc:	06848493          	addi	s1,s1,104 # ffffffffc0205060 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201000:	679c                	ld	a5,8(a5)
ffffffffc0201002:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201004:	57f5                	li	a5,-3
ffffffffc0201006:	07fa                	slli	a5,a5,0x1e
ffffffffc0201008:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc020100a:	d8aff0ef          	jal	ffffffffc0200594 <get_memory_base>
ffffffffc020100e:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201010:	d8eff0ef          	jal	ffffffffc020059e <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201014:	14050f63          	beqz	a0,ffffffffc0201172 <pmm_init+0x1aa>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201018:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc020101a:	00001517          	auipc	a0,0x1
ffffffffc020101e:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0201c28 <etext+0x5da>
ffffffffc0201022:	928ff0ef          	jal	ffffffffc020014a <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201026:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020102a:	864e                	mv	a2,s3
ffffffffc020102c:	fffa0693          	addi	a3,s4,-1
ffffffffc0201030:	85ca                	mv	a1,s2
ffffffffc0201032:	00001517          	auipc	a0,0x1
ffffffffc0201036:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0201c40 <etext+0x5f2>
ffffffffc020103a:	910ff0ef          	jal	ffffffffc020014a <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc020103e:	c80007b7          	lui	a5,0xc8000
ffffffffc0201042:	8652                	mv	a2,s4
ffffffffc0201044:	0d47e663          	bltu	a5,s4,ffffffffc0201110 <pmm_init+0x148>
ffffffffc0201048:	77fd                	lui	a5,0xfffff
ffffffffc020104a:	00005817          	auipc	a6,0x5
ffffffffc020104e:	02d80813          	addi	a6,a6,45 # ffffffffc0206077 <end+0xfff>
ffffffffc0201052:	00f87833          	and	a6,a6,a5
    npage = maxpa / PGSIZE;
ffffffffc0201056:	8231                	srli	a2,a2,0xc
ffffffffc0201058:	00004797          	auipc	a5,0x4
ffffffffc020105c:	00c7b823          	sd	a2,16(a5) # ffffffffc0205068 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201060:	00004797          	auipc	a5,0x4
ffffffffc0201064:	0107b823          	sd	a6,16(a5) # ffffffffc0205070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201068:	000807b7          	lui	a5,0x80
ffffffffc020106c:	002005b7          	lui	a1,0x200
ffffffffc0201070:	02f60563          	beq	a2,a5,ffffffffc020109a <pmm_init+0xd2>
ffffffffc0201074:	00261593          	slli	a1,a2,0x2
ffffffffc0201078:	00c587b3          	add	a5,a1,a2
ffffffffc020107c:	fec006b7          	lui	a3,0xfec00
ffffffffc0201080:	078e                	slli	a5,a5,0x3
ffffffffc0201082:	96c2                	add	a3,a3,a6
ffffffffc0201084:	96be                	add	a3,a3,a5
ffffffffc0201086:	87c2                	mv	a5,a6
        SetPageReserved(pages + i);
ffffffffc0201088:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020108a:	02878793          	addi	a5,a5,40 # 80028 <kern_entry-0xffffffffc017ffd8>
        SetPageReserved(pages + i);
ffffffffc020108e:	00176713          	ori	a4,a4,1
ffffffffc0201092:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201096:	fed799e3          	bne	a5,a3,ffffffffc0201088 <pmm_init+0xc0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020109a:	95b2                	add	a1,a1,a2
ffffffffc020109c:	fec006b7          	lui	a3,0xfec00
ffffffffc02010a0:	96c2                	add	a3,a3,a6
ffffffffc02010a2:	058e                	slli	a1,a1,0x3
ffffffffc02010a4:	96ae                	add	a3,a3,a1
ffffffffc02010a6:	c02007b7          	lui	a5,0xc0200
ffffffffc02010aa:	0af6e863          	bltu	a3,a5,ffffffffc020115a <pmm_init+0x192>
ffffffffc02010ae:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02010b0:	77fd                	lui	a5,0xfffff
ffffffffc02010b2:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010b6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010b8:	04b6ef63          	bltu	a3,a1,ffffffffc0201116 <pmm_init+0x14e>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010bc:	601c                	ld	a5,0(s0)
ffffffffc02010be:	7b9c                	ld	a5,48(a5)
ffffffffc02010c0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010c2:	00001517          	auipc	a0,0x1
ffffffffc02010c6:	c0650513          	addi	a0,a0,-1018 # ffffffffc0201cc8 <etext+0x67a>
ffffffffc02010ca:	880ff0ef          	jal	ffffffffc020014a <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02010ce:	00003597          	auipc	a1,0x3
ffffffffc02010d2:	f3258593          	addi	a1,a1,-206 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc02010d6:	00004797          	auipc	a5,0x4
ffffffffc02010da:	f8b7b123          	sd	a1,-126(a5) # ffffffffc0205058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010de:	c02007b7          	lui	a5,0xc0200
ffffffffc02010e2:	0af5e463          	bltu	a1,a5,ffffffffc020118a <pmm_init+0x1c2>
ffffffffc02010e6:	609c                	ld	a5,0(s1)
}
ffffffffc02010e8:	7402                	ld	s0,32(sp)
ffffffffc02010ea:	70a2                	ld	ra,40(sp)
ffffffffc02010ec:	64e2                	ld	s1,24(sp)
ffffffffc02010ee:	6942                	ld	s2,16(sp)
ffffffffc02010f0:	69a2                	ld	s3,8(sp)
ffffffffc02010f2:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02010f4:	40f586b3          	sub	a3,a1,a5
ffffffffc02010f8:	00004797          	auipc	a5,0x4
ffffffffc02010fc:	f4d7bc23          	sd	a3,-168(a5) # ffffffffc0205050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201100:	00001517          	auipc	a0,0x1
ffffffffc0201104:	be850513          	addi	a0,a0,-1048 # ffffffffc0201ce8 <etext+0x69a>
ffffffffc0201108:	8636                	mv	a2,a3
}
ffffffffc020110a:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020110c:	83eff06f          	j	ffffffffc020014a <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201110:	c8000637          	lui	a2,0xc8000
ffffffffc0201114:	bf15                	j	ffffffffc0201048 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201116:	6705                	lui	a4,0x1
ffffffffc0201118:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020111a:	96ba                	add	a3,a3,a4
ffffffffc020111c:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020111e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201122:	02c7f063          	bgeu	a5,a2,ffffffffc0201142 <pmm_init+0x17a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201126:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201128:	fff80637          	lui	a2,0xfff80
ffffffffc020112c:	97b2                	add	a5,a5,a2
ffffffffc020112e:	00279513          	slli	a0,a5,0x2
ffffffffc0201132:	953e                	add	a0,a0,a5
ffffffffc0201134:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201136:	8d95                	sub	a1,a1,a3
ffffffffc0201138:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020113a:	81b1                	srli	a1,a1,0xc
ffffffffc020113c:	9542                	add	a0,a0,a6
ffffffffc020113e:	9782                	jalr	a5
}
ffffffffc0201140:	bfb5                	j	ffffffffc02010bc <pmm_init+0xf4>
        panic("pa2page called with invalid pa");
ffffffffc0201142:	00001617          	auipc	a2,0x1
ffffffffc0201146:	b5660613          	addi	a2,a2,-1194 # ffffffffc0201c98 <etext+0x64a>
ffffffffc020114a:	06a00593          	li	a1,106
ffffffffc020114e:	00001517          	auipc	a0,0x1
ffffffffc0201152:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0201cb8 <etext+0x66a>
ffffffffc0201156:	876ff0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020115a:	00001617          	auipc	a2,0x1
ffffffffc020115e:	b1660613          	addi	a2,a2,-1258 # ffffffffc0201c70 <etext+0x622>
ffffffffc0201162:	05f00593          	li	a1,95
ffffffffc0201166:	00001517          	auipc	a0,0x1
ffffffffc020116a:	ab250513          	addi	a0,a0,-1358 # ffffffffc0201c18 <etext+0x5ca>
ffffffffc020116e:	85eff0ef          	jal	ffffffffc02001cc <__panic>
        panic("DTB memory info not available");
ffffffffc0201172:	00001617          	auipc	a2,0x1
ffffffffc0201176:	a8660613          	addi	a2,a2,-1402 # ffffffffc0201bf8 <etext+0x5aa>
ffffffffc020117a:	04700593          	li	a1,71
ffffffffc020117e:	00001517          	auipc	a0,0x1
ffffffffc0201182:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0201c18 <etext+0x5ca>
ffffffffc0201186:	846ff0ef          	jal	ffffffffc02001cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020118a:	86ae                	mv	a3,a1
ffffffffc020118c:	00001617          	auipc	a2,0x1
ffffffffc0201190:	ae460613          	addi	a2,a2,-1308 # ffffffffc0201c70 <etext+0x622>
ffffffffc0201194:	07a00593          	li	a1,122
ffffffffc0201198:	00001517          	auipc	a0,0x1
ffffffffc020119c:	a8050513          	addi	a0,a0,-1408 # ffffffffc0201c18 <etext+0x5ca>
ffffffffc02011a0:	82cff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02011a4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02011a4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011a8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02011aa:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011ae:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011b0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011b4:	f022                	sd	s0,32(sp)
ffffffffc02011b6:	ec26                	sd	s1,24(sp)
ffffffffc02011b8:	e84a                	sd	s2,16(sp)
ffffffffc02011ba:	f406                	sd	ra,40(sp)
ffffffffc02011bc:	84aa                	mv	s1,a0
ffffffffc02011be:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011c0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02011c4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02011c6:	05067063          	bgeu	a2,a6,ffffffffc0201206 <printnum+0x62>
ffffffffc02011ca:	e44e                	sd	s3,8(sp)
ffffffffc02011cc:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02011ce:	4785                	li	a5,1
ffffffffc02011d0:	00e7d763          	bge	a5,a4,ffffffffc02011de <printnum+0x3a>
            putch(padc, putdat);
ffffffffc02011d4:	85ca                	mv	a1,s2
ffffffffc02011d6:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02011d8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02011da:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02011dc:	fc65                	bnez	s0,ffffffffc02011d4 <printnum+0x30>
ffffffffc02011de:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011e0:	1a02                	slli	s4,s4,0x20
ffffffffc02011e2:	020a5a13          	srli	s4,s4,0x20
ffffffffc02011e6:	00001797          	auipc	a5,0x1
ffffffffc02011ea:	b4278793          	addi	a5,a5,-1214 # ffffffffc0201d28 <etext+0x6da>
ffffffffc02011ee:	97d2                	add	a5,a5,s4
}
ffffffffc02011f0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011f2:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02011f6:	70a2                	ld	ra,40(sp)
ffffffffc02011f8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02011fa:	85ca                	mv	a1,s2
ffffffffc02011fc:	87a6                	mv	a5,s1
}
ffffffffc02011fe:	6942                	ld	s2,16(sp)
ffffffffc0201200:	64e2                	ld	s1,24(sp)
ffffffffc0201202:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201204:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201206:	03065633          	divu	a2,a2,a6
ffffffffc020120a:	8722                	mv	a4,s0
ffffffffc020120c:	f99ff0ef          	jal	ffffffffc02011a4 <printnum>
ffffffffc0201210:	bfc1                	j	ffffffffc02011e0 <printnum+0x3c>

ffffffffc0201212 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201212:	7119                	addi	sp,sp,-128
ffffffffc0201214:	f4a6                	sd	s1,104(sp)
ffffffffc0201216:	f0ca                	sd	s2,96(sp)
ffffffffc0201218:	ecce                	sd	s3,88(sp)
ffffffffc020121a:	e8d2                	sd	s4,80(sp)
ffffffffc020121c:	e4d6                	sd	s5,72(sp)
ffffffffc020121e:	e0da                	sd	s6,64(sp)
ffffffffc0201220:	f862                	sd	s8,48(sp)
ffffffffc0201222:	fc86                	sd	ra,120(sp)
ffffffffc0201224:	f8a2                	sd	s0,112(sp)
ffffffffc0201226:	fc5e                	sd	s7,56(sp)
ffffffffc0201228:	f466                	sd	s9,40(sp)
ffffffffc020122a:	f06a                	sd	s10,32(sp)
ffffffffc020122c:	ec6e                	sd	s11,24(sp)
ffffffffc020122e:	892a                	mv	s2,a0
ffffffffc0201230:	84ae                	mv	s1,a1
ffffffffc0201232:	8c32                	mv	s8,a2
ffffffffc0201234:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201236:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020123a:	05500b13          	li	s6,85
ffffffffc020123e:	00001a97          	auipc	s5,0x1
ffffffffc0201242:	bfaa8a93          	addi	s5,s5,-1030 # ffffffffc0201e38 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201246:	000c4503          	lbu	a0,0(s8)
ffffffffc020124a:	001c0413          	addi	s0,s8,1
ffffffffc020124e:	01350a63          	beq	a0,s3,ffffffffc0201262 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201252:	cd0d                	beqz	a0,ffffffffc020128c <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201254:	85a6                	mv	a1,s1
ffffffffc0201256:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201258:	00044503          	lbu	a0,0(s0)
ffffffffc020125c:	0405                	addi	s0,s0,1
ffffffffc020125e:	ff351ae3          	bne	a0,s3,ffffffffc0201252 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0201262:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201266:	4b81                	li	s7,0
ffffffffc0201268:	4601                	li	a2,0
        width = precision = -1;
ffffffffc020126a:	5d7d                	li	s10,-1
ffffffffc020126c:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020126e:	00044683          	lbu	a3,0(s0)
ffffffffc0201272:	00140c13          	addi	s8,s0,1
ffffffffc0201276:	fdd6859b          	addiw	a1,a3,-35 # fffffffffebfffdd <end+0x3e9faf65>
ffffffffc020127a:	0ff5f593          	zext.b	a1,a1
ffffffffc020127e:	02bb6663          	bltu	s6,a1,ffffffffc02012aa <vprintfmt+0x98>
ffffffffc0201282:	058a                	slli	a1,a1,0x2
ffffffffc0201284:	95d6                	add	a1,a1,s5
ffffffffc0201286:	4198                	lw	a4,0(a1)
ffffffffc0201288:	9756                	add	a4,a4,s5
ffffffffc020128a:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020128c:	70e6                	ld	ra,120(sp)
ffffffffc020128e:	7446                	ld	s0,112(sp)
ffffffffc0201290:	74a6                	ld	s1,104(sp)
ffffffffc0201292:	7906                	ld	s2,96(sp)
ffffffffc0201294:	69e6                	ld	s3,88(sp)
ffffffffc0201296:	6a46                	ld	s4,80(sp)
ffffffffc0201298:	6aa6                	ld	s5,72(sp)
ffffffffc020129a:	6b06                	ld	s6,64(sp)
ffffffffc020129c:	7be2                	ld	s7,56(sp)
ffffffffc020129e:	7c42                	ld	s8,48(sp)
ffffffffc02012a0:	7ca2                	ld	s9,40(sp)
ffffffffc02012a2:	7d02                	ld	s10,32(sp)
ffffffffc02012a4:	6de2                	ld	s11,24(sp)
ffffffffc02012a6:	6109                	addi	sp,sp,128
ffffffffc02012a8:	8082                	ret
            putch('%', putdat);
ffffffffc02012aa:	85a6                	mv	a1,s1
ffffffffc02012ac:	02500513          	li	a0,37
ffffffffc02012b0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02012b2:	fff44703          	lbu	a4,-1(s0)
ffffffffc02012b6:	02500793          	li	a5,37
ffffffffc02012ba:	8c22                	mv	s8,s0
ffffffffc02012bc:	f8f705e3          	beq	a4,a5,ffffffffc0201246 <vprintfmt+0x34>
ffffffffc02012c0:	02500713          	li	a4,37
ffffffffc02012c4:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02012c8:	1c7d                	addi	s8,s8,-1
ffffffffc02012ca:	fee79de3          	bne	a5,a4,ffffffffc02012c4 <vprintfmt+0xb2>
ffffffffc02012ce:	bfa5                	j	ffffffffc0201246 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02012d0:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02012d4:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc02012d6:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02012da:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc02012de:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e2:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc02012e4:	02b76563          	bltu	a4,a1,ffffffffc020130e <vprintfmt+0xfc>
ffffffffc02012e8:	4525                	li	a0,9
                ch = *fmt;
ffffffffc02012ea:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02012ee:	002d171b          	slliw	a4,s10,0x2
ffffffffc02012f2:	01a7073b          	addw	a4,a4,s10
ffffffffc02012f6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02012fa:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc02012fc:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201300:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201302:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0201306:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc020130a:	feb570e3          	bgeu	a0,a1,ffffffffc02012ea <vprintfmt+0xd8>
            if (width < 0)
ffffffffc020130e:	f60cd0e3          	bgez	s9,ffffffffc020126e <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201312:	8cea                	mv	s9,s10
ffffffffc0201314:	5d7d                	li	s10,-1
ffffffffc0201316:	bfa1                	j	ffffffffc020126e <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201318:	8db6                	mv	s11,a3
ffffffffc020131a:	8462                	mv	s0,s8
ffffffffc020131c:	bf89                	j	ffffffffc020126e <vprintfmt+0x5c>
ffffffffc020131e:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201320:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201322:	b7b1                	j	ffffffffc020126e <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201324:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201326:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc020132a:	00c7c463          	blt	a5,a2,ffffffffc0201332 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc020132e:	1a060163          	beqz	a2,ffffffffc02014d0 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0201332:	000a3603          	ld	a2,0(s4)
ffffffffc0201336:	46c1                	li	a3,16
ffffffffc0201338:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020133a:	000d879b          	sext.w	a5,s11
ffffffffc020133e:	8766                	mv	a4,s9
ffffffffc0201340:	85a6                	mv	a1,s1
ffffffffc0201342:	854a                	mv	a0,s2
ffffffffc0201344:	e61ff0ef          	jal	ffffffffc02011a4 <printnum>
            break;
ffffffffc0201348:	bdfd                	j	ffffffffc0201246 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc020134a:	000a2503          	lw	a0,0(s4)
ffffffffc020134e:	85a6                	mv	a1,s1
ffffffffc0201350:	0a21                	addi	s4,s4,8
ffffffffc0201352:	9902                	jalr	s2
            break;
ffffffffc0201354:	bdcd                	j	ffffffffc0201246 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201356:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201358:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc020135c:	00c7c463          	blt	a5,a2,ffffffffc0201364 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0201360:	16060363          	beqz	a2,ffffffffc02014c6 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0201364:	000a3603          	ld	a2,0(s4)
ffffffffc0201368:	46a9                	li	a3,10
ffffffffc020136a:	8a3a                	mv	s4,a4
ffffffffc020136c:	b7f9                	j	ffffffffc020133a <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc020136e:	85a6                	mv	a1,s1
ffffffffc0201370:	03000513          	li	a0,48
ffffffffc0201374:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201376:	85a6                	mv	a1,s1
ffffffffc0201378:	07800513          	li	a0,120
ffffffffc020137c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020137e:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201382:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201384:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201386:	bf55                	j	ffffffffc020133a <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201388:	85a6                	mv	a1,s1
ffffffffc020138a:	02500513          	li	a0,37
ffffffffc020138e:	9902                	jalr	s2
            break;
ffffffffc0201390:	bd5d                	j	ffffffffc0201246 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201392:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201396:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201398:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc020139a:	bf95                	j	ffffffffc020130e <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc020139c:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020139e:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc02013a2:	00c7c463          	blt	a5,a2,ffffffffc02013aa <vprintfmt+0x198>
    else if (lflag) {
ffffffffc02013a6:	10060b63          	beqz	a2,ffffffffc02014bc <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc02013aa:	000a3603          	ld	a2,0(s4)
ffffffffc02013ae:	46a1                	li	a3,8
ffffffffc02013b0:	8a3a                	mv	s4,a4
ffffffffc02013b2:	b761                	j	ffffffffc020133a <vprintfmt+0x128>
            if (width < 0)
ffffffffc02013b4:	fffcc793          	not	a5,s9
ffffffffc02013b8:	97fd                	srai	a5,a5,0x3f
ffffffffc02013ba:	00fcf7b3          	and	a5,s9,a5
ffffffffc02013be:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013c2:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02013c4:	b56d                	j	ffffffffc020126e <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013c6:	000a3403          	ld	s0,0(s4)
ffffffffc02013ca:	008a0793          	addi	a5,s4,8
ffffffffc02013ce:	e43e                	sd	a5,8(sp)
ffffffffc02013d0:	12040063          	beqz	s0,ffffffffc02014f0 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02013d4:	0d905963          	blez	s9,ffffffffc02014a6 <vprintfmt+0x294>
ffffffffc02013d8:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013dc:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc02013e0:	12fd9763          	bne	s11,a5,ffffffffc020150e <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013e4:	00044783          	lbu	a5,0(s0)
ffffffffc02013e8:	0007851b          	sext.w	a0,a5
ffffffffc02013ec:	cb9d                	beqz	a5,ffffffffc0201422 <vprintfmt+0x210>
ffffffffc02013ee:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013f0:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013f4:	000d4563          	bltz	s10,ffffffffc02013fe <vprintfmt+0x1ec>
ffffffffc02013f8:	3d7d                	addiw	s10,s10,-1
ffffffffc02013fa:	028d0263          	beq	s10,s0,ffffffffc020141e <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc02013fe:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201400:	0c0b8d63          	beqz	s7,ffffffffc02014da <vprintfmt+0x2c8>
ffffffffc0201404:	3781                	addiw	a5,a5,-32
ffffffffc0201406:	0cfdfa63          	bgeu	s11,a5,ffffffffc02014da <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc020140a:	03f00513          	li	a0,63
ffffffffc020140e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201410:	000a4783          	lbu	a5,0(s4)
ffffffffc0201414:	3cfd                	addiw	s9,s9,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0201416:	0a05                	addi	s4,s4,1
ffffffffc0201418:	0007851b          	sext.w	a0,a5
ffffffffc020141c:	ffe1                	bnez	a5,ffffffffc02013f4 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc020141e:	01905963          	blez	s9,ffffffffc0201430 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0201422:	85a6                	mv	a1,s1
ffffffffc0201424:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201428:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc020142a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020142c:	fe0c9be3          	bnez	s9,ffffffffc0201422 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201430:	6a22                	ld	s4,8(sp)
ffffffffc0201432:	bd11                	j	ffffffffc0201246 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201434:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201436:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc020143a:	00c7c363          	blt	a5,a2,ffffffffc0201440 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc020143e:	ce25                	beqz	a2,ffffffffc02014b6 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0201440:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201444:	08044d63          	bltz	s0,ffffffffc02014de <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201448:	8622                	mv	a2,s0
ffffffffc020144a:	8a5e                	mv	s4,s7
ffffffffc020144c:	46a9                	li	a3,10
ffffffffc020144e:	b5f5                	j	ffffffffc020133a <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0201450:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201454:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201456:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc020145a:	8fb9                	xor	a5,a5,a4
ffffffffc020145c:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201460:	02d64663          	blt	a2,a3,ffffffffc020148c <vprintfmt+0x27a>
ffffffffc0201464:	00369713          	slli	a4,a3,0x3
ffffffffc0201468:	00001797          	auipc	a5,0x1
ffffffffc020146c:	b2878793          	addi	a5,a5,-1240 # ffffffffc0201f90 <error_string>
ffffffffc0201470:	97ba                	add	a5,a5,a4
ffffffffc0201472:	639c                	ld	a5,0(a5)
ffffffffc0201474:	cf81                	beqz	a5,ffffffffc020148c <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201476:	86be                	mv	a3,a5
ffffffffc0201478:	00001617          	auipc	a2,0x1
ffffffffc020147c:	8e060613          	addi	a2,a2,-1824 # ffffffffc0201d58 <etext+0x70a>
ffffffffc0201480:	85a6                	mv	a1,s1
ffffffffc0201482:	854a                	mv	a0,s2
ffffffffc0201484:	0e8000ef          	jal	ffffffffc020156c <printfmt>
            err = va_arg(ap, int);
ffffffffc0201488:	0a21                	addi	s4,s4,8
ffffffffc020148a:	bb75                	j	ffffffffc0201246 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020148c:	00001617          	auipc	a2,0x1
ffffffffc0201490:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0201d48 <etext+0x6fa>
ffffffffc0201494:	85a6                	mv	a1,s1
ffffffffc0201496:	854a                	mv	a0,s2
ffffffffc0201498:	0d4000ef          	jal	ffffffffc020156c <printfmt>
            err = va_arg(ap, int);
ffffffffc020149c:	0a21                	addi	s4,s4,8
ffffffffc020149e:	b365                	j	ffffffffc0201246 <vprintfmt+0x34>
            lflag ++;
ffffffffc02014a0:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014a2:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02014a4:	b3e9                	j	ffffffffc020126e <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014a6:	00044783          	lbu	a5,0(s0)
ffffffffc02014aa:	0007851b          	sext.w	a0,a5
ffffffffc02014ae:	d3c9                	beqz	a5,ffffffffc0201430 <vprintfmt+0x21e>
ffffffffc02014b0:	00140a13          	addi	s4,s0,1
ffffffffc02014b4:	bf2d                	j	ffffffffc02013ee <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc02014b6:	000a2403          	lw	s0,0(s4)
ffffffffc02014ba:	b769                	j	ffffffffc0201444 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc02014bc:	000a6603          	lwu	a2,0(s4)
ffffffffc02014c0:	46a1                	li	a3,8
ffffffffc02014c2:	8a3a                	mv	s4,a4
ffffffffc02014c4:	bd9d                	j	ffffffffc020133a <vprintfmt+0x128>
ffffffffc02014c6:	000a6603          	lwu	a2,0(s4)
ffffffffc02014ca:	46a9                	li	a3,10
ffffffffc02014cc:	8a3a                	mv	s4,a4
ffffffffc02014ce:	b5b5                	j	ffffffffc020133a <vprintfmt+0x128>
ffffffffc02014d0:	000a6603          	lwu	a2,0(s4)
ffffffffc02014d4:	46c1                	li	a3,16
ffffffffc02014d6:	8a3a                	mv	s4,a4
ffffffffc02014d8:	b58d                	j	ffffffffc020133a <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc02014da:	9902                	jalr	s2
ffffffffc02014dc:	bf15                	j	ffffffffc0201410 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc02014de:	85a6                	mv	a1,s1
ffffffffc02014e0:	02d00513          	li	a0,45
ffffffffc02014e4:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02014e6:	40800633          	neg	a2,s0
ffffffffc02014ea:	8a5e                	mv	s4,s7
ffffffffc02014ec:	46a9                	li	a3,10
ffffffffc02014ee:	b5b1                	j	ffffffffc020133a <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc02014f0:	01905663          	blez	s9,ffffffffc02014fc <vprintfmt+0x2ea>
ffffffffc02014f4:	02d00793          	li	a5,45
ffffffffc02014f8:	04fd9263          	bne	s11,a5,ffffffffc020153c <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014fc:	02800793          	li	a5,40
ffffffffc0201500:	00001a17          	auipc	s4,0x1
ffffffffc0201504:	841a0a13          	addi	s4,s4,-1983 # ffffffffc0201d41 <etext+0x6f3>
ffffffffc0201508:	02800513          	li	a0,40
ffffffffc020150c:	b5cd                	j	ffffffffc02013ee <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020150e:	85ea                	mv	a1,s10
ffffffffc0201510:	8522                	mv	a0,s0
ffffffffc0201512:	0ae000ef          	jal	ffffffffc02015c0 <strnlen>
ffffffffc0201516:	40ac8cbb          	subw	s9,s9,a0
ffffffffc020151a:	01905963          	blez	s9,ffffffffc020152c <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc020151e:	2d81                	sext.w	s11,s11
ffffffffc0201520:	85a6                	mv	a1,s1
ffffffffc0201522:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201524:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201526:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201528:	fe0c9ce3          	bnez	s9,ffffffffc0201520 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020152c:	00044783          	lbu	a5,0(s0)
ffffffffc0201530:	0007851b          	sext.w	a0,a5
ffffffffc0201534:	ea079de3          	bnez	a5,ffffffffc02013ee <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201538:	6a22                	ld	s4,8(sp)
ffffffffc020153a:	b331                	j	ffffffffc0201246 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020153c:	85ea                	mv	a1,s10
ffffffffc020153e:	00001517          	auipc	a0,0x1
ffffffffc0201542:	80250513          	addi	a0,a0,-2046 # ffffffffc0201d40 <etext+0x6f2>
ffffffffc0201546:	07a000ef          	jal	ffffffffc02015c0 <strnlen>
ffffffffc020154a:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc020154e:	00000417          	auipc	s0,0x0
ffffffffc0201552:	7f240413          	addi	s0,s0,2034 # ffffffffc0201d40 <etext+0x6f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201556:	00000a17          	auipc	s4,0x0
ffffffffc020155a:	7eba0a13          	addi	s4,s4,2027 # ffffffffc0201d41 <etext+0x6f3>
ffffffffc020155e:	02800793          	li	a5,40
ffffffffc0201562:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201566:	fb904ce3          	bgtz	s9,ffffffffc020151e <vprintfmt+0x30c>
ffffffffc020156a:	b551                	j	ffffffffc02013ee <vprintfmt+0x1dc>

ffffffffc020156c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020156c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020156e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201572:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201574:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201576:	ec06                	sd	ra,24(sp)
ffffffffc0201578:	f83a                	sd	a4,48(sp)
ffffffffc020157a:	fc3e                	sd	a5,56(sp)
ffffffffc020157c:	e0c2                	sd	a6,64(sp)
ffffffffc020157e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201580:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201582:	c91ff0ef          	jal	ffffffffc0201212 <vprintfmt>
}
ffffffffc0201586:	60e2                	ld	ra,24(sp)
ffffffffc0201588:	6161                	addi	sp,sp,80
ffffffffc020158a:	8082                	ret

ffffffffc020158c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020158c:	4781                	li	a5,0
ffffffffc020158e:	00004717          	auipc	a4,0x4
ffffffffc0201592:	a8273703          	ld	a4,-1406(a4) # ffffffffc0205010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201596:	88ba                	mv	a7,a4
ffffffffc0201598:	852a                	mv	a0,a0
ffffffffc020159a:	85be                	mv	a1,a5
ffffffffc020159c:	863e                	mv	a2,a5
ffffffffc020159e:	00000073          	ecall
ffffffffc02015a2:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015a4:	8082                	ret

ffffffffc02015a6 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02015a6:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02015aa:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02015ac:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02015ae:	cb81                	beqz	a5,ffffffffc02015be <strlen+0x18>
        cnt ++;
ffffffffc02015b0:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02015b2:	00a707b3          	add	a5,a4,a0
ffffffffc02015b6:	0007c783          	lbu	a5,0(a5)
ffffffffc02015ba:	fbfd                	bnez	a5,ffffffffc02015b0 <strlen+0xa>
ffffffffc02015bc:	8082                	ret
    }
    return cnt;
}
ffffffffc02015be:	8082                	ret

ffffffffc02015c0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02015c0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015c2:	e589                	bnez	a1,ffffffffc02015cc <strnlen+0xc>
ffffffffc02015c4:	a811                	j	ffffffffc02015d8 <strnlen+0x18>
        cnt ++;
ffffffffc02015c6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015c8:	00f58863          	beq	a1,a5,ffffffffc02015d8 <strnlen+0x18>
ffffffffc02015cc:	00f50733          	add	a4,a0,a5
ffffffffc02015d0:	00074703          	lbu	a4,0(a4)
ffffffffc02015d4:	fb6d                	bnez	a4,ffffffffc02015c6 <strnlen+0x6>
ffffffffc02015d6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02015d8:	852e                	mv	a0,a1
ffffffffc02015da:	8082                	ret

ffffffffc02015dc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015dc:	00054783          	lbu	a5,0(a0)
ffffffffc02015e0:	e791                	bnez	a5,ffffffffc02015ec <strcmp+0x10>
ffffffffc02015e2:	a02d                	j	ffffffffc020160c <strcmp+0x30>
ffffffffc02015e4:	00054783          	lbu	a5,0(a0)
ffffffffc02015e8:	cf89                	beqz	a5,ffffffffc0201602 <strcmp+0x26>
ffffffffc02015ea:	85b6                	mv	a1,a3
ffffffffc02015ec:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02015f0:	0505                	addi	a0,a0,1
ffffffffc02015f2:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015f6:	fef707e3          	beq	a4,a5,ffffffffc02015e4 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015fa:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02015fe:	9d19                	subw	a0,a0,a4
ffffffffc0201600:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201602:	0015c703          	lbu	a4,1(a1)
ffffffffc0201606:	4501                	li	a0,0
}
ffffffffc0201608:	9d19                	subw	a0,a0,a4
ffffffffc020160a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020160c:	0005c703          	lbu	a4,0(a1)
ffffffffc0201610:	4501                	li	a0,0
ffffffffc0201612:	b7f5                	j	ffffffffc02015fe <strcmp+0x22>

ffffffffc0201614 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201614:	ce01                	beqz	a2,ffffffffc020162c <strncmp+0x18>
ffffffffc0201616:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020161a:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020161c:	cb91                	beqz	a5,ffffffffc0201630 <strncmp+0x1c>
ffffffffc020161e:	0005c703          	lbu	a4,0(a1)
ffffffffc0201622:	00f71763          	bne	a4,a5,ffffffffc0201630 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201626:	0505                	addi	a0,a0,1
ffffffffc0201628:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020162a:	f675                	bnez	a2,ffffffffc0201616 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020162c:	4501                	li	a0,0
ffffffffc020162e:	8082                	ret
ffffffffc0201630:	00054503          	lbu	a0,0(a0)
ffffffffc0201634:	0005c783          	lbu	a5,0(a1)
ffffffffc0201638:	9d1d                	subw	a0,a0,a5
}
ffffffffc020163a:	8082                	ret

ffffffffc020163c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020163c:	ca01                	beqz	a2,ffffffffc020164c <memset+0x10>
ffffffffc020163e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201640:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201642:	0785                	addi	a5,a5,1
ffffffffc0201644:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201648:	fef61de3          	bne	a2,a5,ffffffffc0201642 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020164c:	8082                	ret

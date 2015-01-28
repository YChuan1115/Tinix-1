
#ifndef __TYPE_H__
#define __TYPE_H__

#define PUBLIC 
#define PRIVATE static

/*权限*/
#define	PRIVILEGE_KRNL	0
#define	PRIVILEGE_TASK	1
#define	PRIVILEGE_USER	3

/*布尔值*/
#define FALSE 0
#define TRUE  1

#define GDT_SIZE 128
#define IDT_SIZE 256

#define INT_M_CTL     0x20
#define INT_M_CTLMASK 0x21
#define INT_S_CTL     0xA0
#define INT_S_CTLMASK 0xA1

/*系统段描述符类型值说明 */
#define	DA_LDT          0x82   /*局部描述符表段类型值*/  
#define	DA_TaskGate     0x85   /*任务门类型值*/
#define	DA_386TSS       0x89   /*可用 386 任务状态段类型值 */
#define	DA_386CGate     0x8C   /*386 调用门类型值 */
#define	DA_386IGate     0x8E   /*386 中断门类型值 */
#define	DA_386TGate     0x8F   /*386 陷阱门类型值 */

/*中断向量*/
#define INT_VECTOR_DIVIDE       0x0
#define INT_VECTOR_DEBUG        0x1
#define INT_VECTOR_NMI          0x2
#define INT_VECTOR_BREAKPOINT   0x3
#define INT_VECTOR_OVERFLOW     0x4
#define INT_VECTOR_BOUNDS       0x5
#define INT_VECTOR_INVAL_OP     0x6
#define INT_VECTOR_COPROC_NOT   0x7
#define INT_VECTOR_DOUBLE_FAULT 0x8
#define INT_VECTOR_COPROC_SEG   0x9
#define INT_VECTOR_INVAL_TSS    0xA
#define INT_VECTOR_SEG_NOT      0xB
#define INT_VECTOR_STACK_FAULT  0xC
#define INT_VECTOR_PROTECTION   0xD
#define INT_VECTOR_PAGE_FAULT   0xE
#define INT_VECTOR_COPROC_ERR   0x10

/*中断向量*/
#define INT_VECTOR_IRQ0  0x20
#define INT_VECTOR_IRQ8  0x28

#define NR_TASKS 1

/*GDT描述符索引*/
#define INDEX_DUMMY     0
#define INDEX_FLAT_C    1
#define INDEX_FLAT_RW   2
#define INDEX_VIDEO     3
#define INDEX_TSS       4
#define INDEX_LDT_FIRST 5

/*选择子*/
#define SELECTOR_DUMMY     0
#define SELECTOR_FLAT_C    0x08
#define SELECTOR_FLAT_RW   0x10
#define SELECTOR_VIDEO    (0x18+3)
#define SELECTOR_TSS       0x20
#define SELECTOR_LDT_FIRST 0x28

#define SELECTOR_KERNEL_CS SELECTOR_FLAT_C
#define SELECTOR_KERNEL_DS SELECTOR_FLAT_RW
#define SELECTOR_KERNEL_GS SELECTOR_VIDEO

/*每个任务有一个单独的LDT, 每个LDT中的描述符个数为：*/
#define LDT_SIZE 2
/* stacks of tasks */
#define STACK_SIZE_TESTA 0x8000
#define STACK_SIZE_TOTAL STACK_SIZE_TESTA

/*选择子类型说明*/
#define SA_RPL_MASK  0xFFFC
#define SA_RPL0      0
#define SA_RPL1      1
#define SA_RPL2      2
#define SA_RPL3      3

#define SA_TI_MASK   0xFFFB
#define SA_TIG       0
#define SA_TIL       4

/* 描述符类型值说明 */
#define	DA_32			0x4000	/* 32位段 */
#define	DA_LIMIT_4K		0x8000	/* 段界限粒度为 4K 字节 */
#define	DA_DPL0			0x00	/* DPL = 0 */
#define	DA_DPL1			0x20	/* DPL = 1 */
#define	DA_DPL2			0x40	/* DPL = 2 */
#define	DA_DPL3			0x60	/* DPL = 3 */
/* 存储段描述符类型值说明 */
#define	DA_DR			0x90	/* 存在的只读数据段类型值 */
#define	DA_DRW			0x92	/* 存在的可读写数据段属性值 */
#define	DA_DRWA			0x93	/* 存在的已访问可读写数据段类型值 */
#define	DA_C			0x98	/* 存在的只执行代码段属性值 */
#define	DA_CR			0x9A	/* 存在的可执行可读代码段属性值 */
#define	DA_CCO			0x9C	/* 存在的只执行一致代码段属性值 */
#define	DA_CCOR			0x9E	/* 存在的可执行可读一致代码段属性值 */

/* 系统段描述符类型值说明 */
#define	DA_LDT			0x82	/* 局部描述符表段类型值 */
#define	DA_TaskGate		0x85	/* 任务门类型值 */
#define	DA_386TSS		0x89	/* 可用 386 任务状态段类型值 */
#define	DA_386CGate		0x8C	/* 386 调用门类型值 */
#define	DA_386IGate		0x8E	/* 386 中断门类型值 */
#define	DA_386TGate		0x8F	/* 386 陷阱门类型值 */

/* 权限 */
#define	PRIVILEGE_KRNL	0
#define	PRIVILEGE_TASK	1
#define	PRIVILEGE_USER	3

/* RPL */
#define	RPL_KRNL	SA_RPL0
#define	RPL_TASK	SA_RPL1
#define	RPL_USER	SA_RPL3

typedef unsigned int t_bool;
typedef unsigned int t_32;
typedef unsigned short t_16;
typedef unsigned char t_8;
typedef unsigned int t_port;

/*存储段描述符 系统段描述符*/
typedef struct s_descriptor
{
  t_16 limit_low;
  t_16 base_low;
  t_8 base_mid;
  t_8 attr1;
  t_8 limit_high_attr2;
  t_8 base_high;
}DESCRIPTOR;

typedef struct s_gate
{
  t_16 offset_low;
  t_16 selector;
  t_8  dcount;
  t_8  attr;
  t_16 offset_high;
}GATE;

typedef struct s_stackframe
{
  t_32 gs;
  t_32 fs;
  t_32 es;
  t_32 ds;
  t_32 edi;
  t_32 esi;
  t_32 ebp;
  t_32 kernel_esp;
  t_32 ebx;
  t_32 edx;
  t_32 ecx;
  t_32 eax;
  t_32 retaddr;
  t_32 eip;
  t_32 cs;
  t_32 eflags;
  t_32 esp;
  t_32 ss;
}STACK_FRAME;

typedef struct s_proc
{
  STACK_FRAME regs;
  t_16        ldt_sel;
  DESCRIPTOR  ldts[LDT_SIZE];
  t_32        pid;
  char        p_name[16];
}PROCESS;

typedef void (*t_pf_int_handler)();

/*outer function*/
void* memcpy(void* pDest, void* pSrc, int iSize);
void disp_str(char* pszInfo);
void disp_color_str(char* pszInfo, int text_color);
void out_byte(t_port port, t_8 value);
void in_byte(t_port port);
void spurious_irq(int irq);

/*exception function*/
void divide_error();
void single_step_exception();
void nmi();
void breakpoint_exception();
void overflow();
void bounds_check();
void inval_opcode();
void copr_not_available();
void double_fault();
void copr_seg_overrun();
void inval_tss();
void segment_not_present();
void stack_exception();
void general_protection();
void page_fault();
void copr_error();
void hwint00();
void hwint01();
void hwint02();
void hwint03();
void hwint04();
void hwint05();
void hwint06();
void hwint07();
void hwint08();
void hwint09();
void hwint10();
void hwint11();
void hwint12();
void hwint13();
void hwint14();
void hwint15();

/*inner function*/
void cstart();
char* itoa(char* str, int num);
void disp_int(int input);
void exception_handler(int vec_no, int err_code, int eip, int cs, int eflags);
void init_8259A();
void init_idt_desc(unsigned char vector, t_8 desc_type, t_pf_int_handler handler, unsigned char privilege);
void init_prot();

/*定义的外部变量*/
extern int disp_pos;
extern t_8 gdt_ptr[6];
extern DESCRIPTOR gdt[GDT_SIZE];
extern t_8 idt_ptr[6];
extern DESCRIPTOR idt[IDT_SIZE];

#endif //__TYPE_H__

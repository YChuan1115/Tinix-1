
#include "type.h"

typedef void (*t_pf_int_handler)();

/*outer function*/
PUBLIC void* memcpy(void* pDest, void* pSrc, int iSize);
PUBLIC void disp_str(char* pszInfo);
PUBLIC void disp_color_str(char* pszInfo, int text_color);
PUBLIC void out_byte(t_port port, t_8 value);
PUBLIC void in_byte(t_port port);
PUBLIC void spurious_irq(int irq);

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
PUBLIC void cstart();
PUBLIC char* itoa(char* str, int num);
PUBLIC void disp_int(int input);
PUBLIC void exception_handler(int vec_no, int err_code, int eip, int cs, int eflags);
PUBLIC void init_8259A();
PUBLIC void init_idt_desc(unsigned char vector, t_8 desc_type, t_pf_int_handler handler, unsigned char privilege);
PUBLIC void init_prot();

/*variable*/
PUBLIC int disp_pos;
PUBLIC t_8 gdt_ptr[6];
PUBLIC DESCRIPTOR gdt[GDT_SIZE];
PUBLIC t_8 idt_ptr[6];
PUBLIC DESCRIPTOR idt[IDT_SIZE];

PUBLIC void cstart()
{
  disp_pos = 0;
  disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n------\"cstart\"  begins------\n");
  memcpy(&gdt, /*要复制到的目的地 -- 新的gdt*/
         (void*)(*((t_32*) (&gdt_ptr[2]))), /*段基址 表示要复制的起始地址*/
		 *((t_16*)(&gdt_ptr[0]))+1 /*段界限+1 表示要复制的长度*/
		);
  
  t_16* p_gdt_limit = (t_16*)(&gdt_ptr[0]); /*段界限 低2个字节*/
  t_32* p_gdt_base  = (t_32*)(&gdt_ptr[2]); /*段基址 高4个字节*/
  *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1; /*新gdt的段界限*/
  *p_gdt_base  = (t_32)&gdt; /*新gdt的段基址*/
  
  t_16* p_idt_limit = (t_16*)(&idt_ptr[0]); /*段界限 低2个字节*/
  t_32* p_idt_base  = (t_32*)(&idt_ptr[2]); /*段基址 高4个字节*/
  *p_idt_limit = IDT_SIZE * sizeof(GATE) - 1; /*idt的段界限*/
  *p_idt_base  = (t_32)&idt; /*idt的段基址*/
  
  init_prot();
  
  disp_str("------\"cstart\"  finished------\n");
} 

PUBLIC char* itoa(char* str, int num)
{
  char* p = str;
  char ch;
  int i;
  t_bool flag = FALSE;
  *p++ = '0';
  *p++ = 'x';
  if (num==0) {
    *p++ = '0';
  } else {
    for (i=28; i>=0; i-=4) {
	  ch = (num >> i) & 0xf;
	  if (flag || ch > 0) {
	    flag = TRUE;
		ch += '0';
		if (ch > '9') {
		  ch += 7;
		}
		*p++ = ch;
	  }
	}
  }
  *p = 0;
  return str;
}

PUBLIC void disp_int(int input)
{
  char output[16];
  itoa(output, input);
  disp_str(output);
}

PUBLIC void exception_handler(int vec_no, int err_code, int eip, int cs, int eflags)
{
  int i;
  int text_color = 0x74;
  char err_description[][64] = {
    "#DE Divide Error",
	"#DB RESERVED",
	"- NMI Interrupt",
	"#BP BreakPoint",
	"#OF Overflow",
	"#BR Bound Range Exceeded",
	"#UD Invalid Opcode (Undefined Opcode)",
	"#NM Device not Available (No Math Coprocessor)",
	"#DF Double Fault",
    "Coprocessor Segment Overrun (reserved)",
	"#TS Invalid TSS",
	"#NP Segment not Present",
	"#SS Stak-Segment Fault",
	"#GP General Protected",
	"#PF Page Fault",
	"- (Intel reserved. Do not use)",
	"#MF x87 FPU Floating-Point Error (Math Fault)",
	"#AC Alignment Check",
	"#MC Machine Check",
	"#XF SIMD Floating-Point Exception"
  };
  
  disp_pos = 0;
  for (i=0; i<80*5; i++) {
    disp_str(" ");
  }
  
  disp_pos = 0;
  disp_color_str("Exception --> ", text_color);
  disp_color_str(err_description[vec_no], text_color);
  disp_color_str("\n\n", text_color);
  disp_color_str("EFLAGS:", text_color);
  
  disp_int(eflags);
  disp_color_str("CS:", text_color);
  disp_int(cs);
  disp_color_str("EIP:", text_color);
  disp_int(eip);
  
  if (err_code != 0xffffffff) {
    disp_color_str("Error Code: ", text_color);
	disp_int(err_code);
  }
}

PUBLIC void init_8259A()
{
  out_byte(INT_M_CTL,     0x11);
  out_byte(INT_S_CTL,     0x11);
  out_byte(INT_M_CTLMASK, INT_VECTOR_IRQ0);
  out_byte(INT_S_CTLMASK, INT_VECTOR_IRQ8);
  out_byte(INT_M_CTLMASK, 0x4);
  out_byte(INT_S_CTLMASK, 0x2);
  out_byte(INT_M_CTLMASK, 0x1);
  out_byte(INT_S_CTLMASK, 0x1);
  out_byte(INT_M_CTLMASK, 0xFD);
  out_byte(INT_S_CTLMASK, 0xFF);
}

PUBLIC void init_idt_desc(unsigned char vector, t_8 desc_type, t_pf_int_handler handler, unsigned char privilege)
{
  GATE* p_gate = (GATE*)&idt[vector];
  t_32 base = (t_32)handler;
  p_gate->offset_low = base & 0xffff;
  p_gate->selector = SELECTOR_KERNEL_CS;
  p_gate->dcount = 0;
  p_gate->attr = desc_type | (privilege << 5);
  p_gate->offset_high = (base >> 16) & 0xffff;  
}

PUBLIC void init_prot()
{
  init_8259A();
  
  /*全局初始化成中断门(没有陷阱门)*/
  init_idt_desc(INT_VECTOR_DIVIDE,       DA_386IGate, divide_error,          PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_DEBUG,        DA_386IGate, single_step_exception, PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_NMI,          DA_386IGate, nmi,                   PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_BREAKPOINT,   DA_386IGate, breakpoint_exception,  PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_OVERFLOW,     DA_386IGate, overflow,              PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_BOUNDS,       DA_386IGate, bounds_check,          PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_INVAL_OP,     DA_386IGate, inval_opcode,          PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_COPROC_NOT,   DA_386IGate, copr_not_available,    PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_DOUBLE_FAULT, DA_386IGate, double_fault,          PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_COPROC_SEG,   DA_386IGate, copr_seg_overrun,      PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_INVAL_TSS,    DA_386IGate, inval_tss,             PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_SEG_NOT,      DA_386IGate, segment_not_present,   PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_STACK_FAULT,  DA_386IGate, stack_exception,       PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_PROTECTION,   DA_386IGate, general_protection,    PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_PAGE_FAULT,   DA_386IGate, page_fault,            PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_COPROC_ERR,   DA_386IGate, copr_error,            PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+0,       DA_386IGate, hwint00,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+1,       DA_386IGate, hwint01,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+2,       DA_386IGate, hwint02,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+3,       DA_386IGate, hwint03,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+4,       DA_386IGate, hwint04,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+5,       DA_386IGate, hwint05,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+6,       DA_386IGate, hwint06,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ0+7,       DA_386IGate, hwint07,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+0,       DA_386IGate, hwint08,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+1,       DA_386IGate, hwint09,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+2,       DA_386IGate, hwint10,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+3,       DA_386IGate, hwint11,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+4,       DA_386IGate, hwint12,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+5,       DA_386IGate, hwint13,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+6,       DA_386IGate, hwint14,               PRIVILEGE_KRNL);
  init_idt_desc(INT_VECTOR_IRQ8+7,       DA_386IGate, hwint15,               PRIVILEGE_KRNL);  
}

PUBLIC void spurious_irq(int irq)
{
  disp_str("spurious_irq:  ");
  disp_int(irq);
  disp_str("\n");
}




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
#define INT_VECTOR_DIVIDE 0x0
#define INT_VECTOR_DEBUG 0x1
#define INT_VECTOR_NMI 0x2
#define INT_VECTOR_BREAKPOINT 0x3
#define INT_VECTOR_OVERFLOW 0x4
#define INT_VECTOR_BOUNDS 0x5
#define INT_VECTOR_INVAL_OP 0x6
#define INT_VECTOR_COPROC_NOT 0x7
#define INT_VECTOR_DOUBLE_FAULT 0x8
#define INT_VECTOR_COPROC_SEG 0x9
#define INT_VECTOR_INVAL_TSS 0xA
#define INT_VECTOR_SEG_NOT 0xB
#define INT_VECTOR_STACK_FAULT 0xC
#define INT_VECTOR_PROTECTION 0xD
#define INT_VECTOR_PAGE_FAULT 0xE
#define INT_VECTOR_COPROC_ERR 0x10

/*中断向量*/
#define INT_VECTOR_IRQ0  0x20
#define INT_VECTOR_IRQ8  0x28

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

#endif //__TYPE_H__

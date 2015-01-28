
#include "type.h"

PUBLIC PROCESS proc_table[NR_TASKS];
PUBLIC char	task_stack[STACK_SIZE_TOTAL];

void delay(int time)
{
  int i, j, k;
  for (i=0; i<time; i++)
    for (j=0; j<10000; j++)
      for (k=0; k<10000; k++){}
}

void TestA()
{
  while (1) {
    disp_str("A.");
    delay(10);
  }
}

void TestB()
{
  while (1) {
    disp_str("B.");
    delay(10);
  }
}

void TestC()
{
  while (1) {
    disp_str("C.");
    delay(10);
  }
}

PUBLIC int tinix_main()
{
  disp_str("------\"tinix_main\" begins------");
  
  PROCESS* p_proc = proc_table;
  p_proc->ldt_sel = SELECTOR_LDT_FIRST;
  memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
  
  //改变DPL值
  p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5;
  memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
  
  //改变DPL值
  p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5;
  p_proc->regs.cs  = ((8*0) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
  p_proc->regs.ds  = ((8*1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
  p_proc->regs.es  = ((8*1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
  p_proc->regs.fs  = ((8*1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
  p_proc->regs.ss  = ((8*1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
  
  p_proc->regs.gs  = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;
  p_proc->regs.eip = (t_32)TestA;
  p_proc->regs.esp = (t_32)task_stack + STACK_SIZE_TOTAL;
  p_proc->regs.eflags = 0x1200;
  
  while (1) {}  
}

SELECTOR_KERNEL_CS equ 8

; 外部定义符号
extern cstart
extern gdt_ptr
extern idt_ptr
extern exception_handler

[section .bss]
; resb resw resd resq rest被设计用在bss段中，用来声明未初始化的存储空间
StackSpace resb 2 * 1024  ; 栈空间 2KB
StackTop:  ; 栈顶

[section .text]

global _start
global divide_error
global single_step_exception
global nmi
global breakpoint_exception
global overflow
global bounds_check
global inval_opcode
global copr_not_available
global double_fault
global copr_seg_overrun
global inval_tss
global segment_not_present
global stack_exception
global general_protection
global page_fault
global copr_error

_start:
  ; 显示成功跳转至内核
  ;mov ah, 0Fh
  ;mov al, 'K'
  ;mov [gs:((80*1+39)*2)], ax
  ;jmp $
  
  ;切换gdt
  mov esp, StackTop ; 把esp从loader切换至kernel中
  sgdt [gdt_ptr] ; 保存全局描述符至gdt_ptr中
  call cstart    ; 在cstart中更新全局描述符 -- 切换
  lgdt [gdt_ptr] ; 从gdt_ptr中加载全局描述符
  lidt [idt_ptr] ; 从idt_ptr中加载中断描述符
  jmp SELECTOR_KERNEL_CS:csinit
  
csinit:
  ud2  ; 产生UD2异常
  hlt
  
divide_error:
  push 0xffffffff
  push 0
  jmp exception
single_step_exception:
  push 0xffffffff
  push 1
  jmp exception
nmi:
  push 0xffffffff
  push 2
  jmp exception
breakpoint_exception:
  push 0xffffffff
  push 3
  jmp exception  
overflow:
  push 0xffffffff
  push 4
  jmp exception  
bounds_check:
  push 0xffffffff
  push 5
  jmp exception  
inval_opcode:
  push 0xffffffff
  push 6
  jmp exception
copr_not_available:
  push 0xffffffff
  push 7
  jmp exception  
double_fault:
  push 8
  jmp exception
copr_seg_overrun:
  push 0xffffffff
  push 9
  jmp exception
inval_tss:
  push 10
  jmp exception  
segment_not_present:
  push 11
  jmp exception  
stack_exception:
  push 12
  jmp exception  
general_protection:
  push 13
  jmp exception  
page_fault:
  push 14
  jmp exception  
copr_error:
  push 0xffffffff
  push 16
  jmp exception
exception:
  call exception_handler
  add esp, 4*2
  hlt
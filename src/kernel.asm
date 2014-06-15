SELECTOR_KERNEL_CS equ 8

; 外部定义符号
extern cstart
extern gdt_ptr

[section .bss]
; resb resw resd resq rest被设计用在bss段中，用来声明未初始化的存储空间
StackSpace resb 2 * 1024  ; 栈空间 2KB
StackTop:  ; 栈顶

[section .text]
global _start
_start:
  ; 显示成功跳转至内核
  ;mov ah, 0Fh
  ;mov al, 'K'
  ;mov [gs:((80*1+39)*2)], ax
  ;jmp $
  
  ;
  mov esp, StackTop ; 把esp从loader切换至kernel中
  sgdt [gdt_ptr] ; 保存全局描述符至gdt_ptr中
  call cstart    ; 在cstart中更新全局描述符 -- 切换
  lgdt [gdt_ptr] ; 从gdt_ptr中加载全局描述符
  jmp SELECTOR_KERNEL_CS:csinit
  
csinit:
  hlt
  

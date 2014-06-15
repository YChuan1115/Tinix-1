
[section .text]

global memcpy

; 函数原型 void* memcpy(void* es:pDest, void* ds:pSrc, int iSize);  
memcpy:
  push ebp   ; addr = 0x905ae
  mov ebp, esp
  push esi
  push edi
  push ecx

  mov edi, [ebp + 8]  ; dst
  mov esi, [ebp + 12] ; src
  mov ecx, [ebp + 16] ; size
  
.1:
  cmp ecx, 0 ; 判断计数器
  jz .2	 ; 计数器为零时跳出

  ; 逐字节拷贝移动
  mov al, [ds:esi]
  inc esi
  mov byte [es:edi], al  ; ------- es:0x28 为SelectorPageTbl的值
  inc edi
  dec ecx ; 计数器减一
  jmp .1; 循环
  
.2:
  mov eax, [ebp + 8] ; 返回值

  pop ecx
  pop edi
  pop esi
  mov esp, ebp
  pop ebp
  ret
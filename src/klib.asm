
[section .data]
disp_pos dd 0

[section .text]

;�������� 
global out_byte
global in_byte
global disp_str
global disp_color_str

disp_str:
  push ebp
  mov ebp, esp
  mov esi, [ebp+8]
  mov edi, [disp_pos]
  mov ah, 0fh
.1:
  lodsb
  test al, al
  jz .2
  cmp al, 0ah ; �ǻس���
  jnz .3
  push eax
  mov eax, edi
  mov bl, 160
  div bl
  and eax, 0ffh
  inc eax
  mov bl, 160
  mul bl
  mov edi, eax
  pop eax
  jmp .1
.3:
  mov [gs:edi], ax
  add edi, 2
  jmp .1
.2:
  mov [disp_pos], edi
  pop ebp
  ret
  
disp_color_str:
  push ebp
  mov ebp, esp
  mov esi, [ebp+8]
  mov edi, [disp_pos]
  mov ah, [esp+12] ; color
.1:
  lodsb
  test al, al
  jz .2
  cmp al, 0ah ; �ǻس���
  jnz .3
  push eax
  mov eax, edi
  mov bl, 160
  div bl
  and eax, 0ffh
  inc eax
  mov bl, 160
  mul bl
  mov edi, eax
  pop eax
  jmp .1
.3:
  mov [gs:edi], ax
  add edi, 2
  jmp .1
.2:
  mov [disp_pos], edi
  pop ebp
  ret  
  
out_byte:
  mov edx, [esp+4]
  mov al, [esp+4+4]
  out dx, al
  nop
  nop
  ret
  
in_byte:
  mov edx, [esp+4]
  xor eax, eax
  in al, dx
  nop
  nop
  ret
 
  
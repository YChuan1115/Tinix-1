
[section .text]

global memcpy

; ����ԭ�� void* memcpy(void* es:pDest, void* ds:pSrc, int iSize);  
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
  cmp ecx, 0 ; �жϼ�����
  jz .2	 ; ������Ϊ��ʱ����

  ; ���ֽڿ����ƶ�
  mov al, [ds:esi]
  inc esi
  mov byte [es:edi], al  ; ------- es:0x28 ΪSelectorPageTbl��ֵ
  inc edi
  dec ecx ; ��������һ
  jmp .1; ѭ��
  
.2:
  mov eax, [ebp + 8] ; ����ֵ

  pop ecx
  pop edi
  pop esi
  mov esp, ebp
  pop ebp
  ret
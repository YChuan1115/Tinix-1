org 0100h

jmp LABEL_START

; 下面是FAT12磁盘的头
BS_OEMName      DB 'ForrestY'    ; OEM String  必须是8字节
BPB_BytesPerSec DW 512           ; 每扇区字节数
BPB_SecPerClus  DB 1             ; 每簇多少扇区
BPB_RsvdSecCnt  DW 1             ; boot记录占用多少扇区
BPB_NumFATs     DB 2             ; 共有多少FAT表
BPB_RootEntCnt  DW 224           ; 根目录文件数最大值
BPB_TotSec16    DW 2880          ; 逻辑扇区总数
BPP_Media       DB 0xF0          ; 媒体描述符
BPB_FATSz16     DW 9             ; 每FAT扇区数
BPB_SecPerTrk   DW 18            ; 每磁道扇区数
BPB_NumHeads    DW 2             ; 磁头数（面数）
BPB_HiddSec     DD 0             ; 隐藏扇区数
BPB_TotSec32    DD 0             ; 如果wTotalSectorCount是0，则由这个值记录扇区数
BS_DrvNum       DB 0             ; 中断13的驱动器号
BS_Reserved1    DB 0             ; 未使用
BS_BootSig      DB 0x29          ; 扩展引导标记(29h)
BS_VolID        DD 0             ; 卷序列号
BS_VolLab       DB 'Tinix0.01  ' ; 卷标，必须11字节
BS_FileSysType  DB 'FAT12   '    ; 文件系统类型，必须8字节

%include  "pm.inc"

; =============================================================================

; 常量
BaseOfStack               equ   0100h            ; 堆栈基地址 (栈底，从这个位置向地址生长)
BaseOfLoader              equ   09000h
OffsetOfLoader            equ   0100h
BaseOfLoaderPhyAddr       equ   BaseOfLoader*10h
BaseOfKernelFile          equ   08000h           ; Kernel.bin被加载到的位置 -- 段地址
BaseOfKernelPhyAddr       equ   BaseOfKernelFile*10h
OffsetOfKernelFile        equ   0                ; Kernel.bin被加载到的位置 -- 偏移地址
KernelEntryPointPhyAddr   equ   0x30400
RootDirSectors            equ   14               ; 根目录占用空间
SectorNoOfRootDirectory   equ   19               ; Root Directory 的第一个扇区
DeltaSectorNo             equ   17
SectorNoOfFAT1            equ   1

; 变量
dwKernelSize              dw    0                ; Kernel文件大小
wRootDirSizeForLoop       dw    RootDirSectors   ; Root Dir占用的扇区数 在循环中减至0
wSectorNo                 dw    0                ; 要读的扇区号
bOdd                      dd    0                ; 奇数还是偶数
 
; 字符串
KernelFileName            db    "KERNEL  BIN", 0 ; kernel.bin的文件名
MessageLength             equ   9                ; 为简单起见，下面每个字符串的长度均为9个字节
LoadMessage               db    "Loading  "
Message1                  db    "Ready.   "
Message2                  db    "No KERNEL"
Message3                  db    "LOADER OK"    	

PageDirBase    equ  200000h
PageTblBase    equ  201000h

; =============================================================================

LABEL_GDT           : Descriptor 0,           0,        0                        ; 空描述符
LABEL_DESC_FLAT_C   : Descriptor 0,           0fffffh,  DA_CR|DA_32|DA_LIMIT_4K  ; 0-4G可执行段
LABEL_DESC_FLAT_RW  : Descriptor 0,           0fffffh,  DA_DRW|DA_32|DA_LIMIT_4K ; 0-4G可读写段
LABEL_DESC_VIDEO    : Descriptor 0B8000h,     0ffffh,   DA_DRW|DA_DPL3           ; 指向缓存的段
LABEL_DESC_PAGE_DIR : Descriptor PageDirBase, 4095,     DA_DRW
LABEL_DESC_PAGE_TBL : Descriptor PageTblBase, 1023,     DA_DRW|DA_LIMIT_4K

GdtLen          equ    $ - LABEL_GDT
GdtPtr          dw     GdtLen - 1
                dd     BaseOfLoaderPhyAddr + LABEL_GDT
                
SelectorFlatC   equ    LABEL_DESC_FLAT_C   - LABEL_GDT  ;
SelectorFlatRW  equ    LABEL_DESC_FLAT_RW  - LABEL_GDT
SelectorVideo   equ    LABEL_DESC_VIDEO    - LABEL_GDT + SA_RPL3
SelectorPageDir equ    LABEL_DESC_PAGE_DIR - LABEL_GDT
SelectorPageTbl equ    LABEL_DESC_PAGE_TBL - LABEL_GDT

; =============================================================================

LABEL_START:
  mov ax, cs
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, BaseOfStack
  
  mov dh, 0
  call DispStrRealMode
  
  ; 获取内存数
  mov ebx, 0
  mov di, _MemChkBuf
.MemChkLoop:
  mov eax, 0e820h
  mov ecx, 20
  mov edx, 0534d4150h   ; SMAP
  int 15h
  jc .MemChkFail
  add di, 20
  inc dword [_dwMCRNumber]
  cmp ebx, 0
  jne .MemChkLoop
  jmp .MemChkOK
.MemChkFail:
  mov dword [_dwMCRNumber], 0
.MemChkOK:
  
  xor ah, ah     ; --|
  xor dl, dl     ;   |--软驱复位
  int 13h        ; --|
  
  ; 在A盘的根目录寻找kernel.bin文件
  mov word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
  cmp word [wRootDirSizeForLoop], 0  ; 根目录区共14个扇区 
  jz LABEL_NO_KERNELBIN
  dec word [wRootDirSizeForLoop]
  
  mov ax, BaseOfKernelFile
  mov es, ax
  mov bx, OffsetOfKernelFile
  
  mov ax, [wSectorNo]  ; 开始第19个扇区号 
  mov cl, 1
  call ReadSector ; 从ax扇区开始，读取cl个扇区，数据存储至 es:bx
  
  mov si, KernelFileName  ; ds:si --> "KERNEL  BIN"
  mov di, OffsetOfKernelFile  ; es:di --> BaseOfKernelFile:0000 = BaseOfKernelFile*10h
  
  cld  ; 清方向标志
  mov dx, 10h ; 表示一个扇区有16个目录项 16*32 = 512
  
LABEL_SEARCH_FOR_KERNELBIN:
  cmp dx, 0
  jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
  dec dx
  mov cx, 11  ; 文件名共11个字节 8+3
  
LABEL_CMP_FILENAME:
  cmp cx, 0
  jz LABEL_FILENAME_FOUND
  dec cx
  lodsb  ; 把SI指向的存储单元读入AL,然后SI自动增加1
  cmp al, byte [es:di]
  jz LABEL_GO_ON
  jmp LABEL_DIFFERENT
  
LABEL_GO_ON:
  inc di
  jmp LABEL_CMP_FILENAME
  
LABEL_DIFFERENT:
  and di, 0ffe0h 
  add di, 20h
  mov si, KernelFileName
  jmp LABEL_SEARCH_FOR_KERNELBIN
  
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
  add word [wSectorNo], 1
  jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN
  
LABEL_NO_KERNELBIN:
  mov dh, 2
  call DispStrRealMode
  jmp $
  
LABEL_FILENAME_FOUND:
  mov ax, RootDirSectors   ; 共14个根目录区 
  and di, 0fff0h   ; 低4位清0  --->  boot中是低5位清0
  push eax
  mov eax, [es:di + 01ch]
  mov dword [dwKernelSize], eax
  pop eax
  
  add di, 01ah
  mov cx, word [es:di]
  push cx
  add cx, ax
  add cx, DeltaSectorNo
  mov ax, BaseOfKernelFile
  mov es, ax
  mov bx, OffsetOfKernelFile
  
  mov ax, cx
LABEL_GOON_LOADING_FILE:
  push ax
  push bx
  mov ah, 0eh
  
  mov al, '.'
  mov bl, 0fh
  int 10h
  pop bx
  pop ax
  mov cl, 1
  call ReadSector
  pop ax
  call GetFATEntry
  cmp ax, 0fffh
  jz LABEL_FILE_LOADER
  push ax
  mov dx, RootDirSectors
  add ax, dx
  add ax, DeltaSectorNo
  add bx, [BPB_BytesPerSec]
  jmp LABEL_GOON_LOADING_FILE
  
LABEL_FILE_LOADER:
  call KillMotor
  mov dh, 1
  call DispStrRealMode

  lgdt [GdtPtr]
  cli
  in al, 92h
  or al, 00000010b
  out 92h, al
  mov eax, cr0
  or eax, 1
  mov cr0, eax  
  jmp dword SelectorFlatC:(BaseOfLoaderPhyAddr+LABEL_PM_START)

; 打印消息  
DispStrRealMode:
  mov ax, MessageLength
  mul dh
  add ax, LoadMessage
  mov bp, ax
  mov ax, ds
  mov es, ax
  mov cx, MessageLength
  mov ax, 01301h
  mov bx, 0007h
  mov dl, 0
  add dh, 3  ; 从第三行往下显示
  int 10h
  ret  
  
GetFATEntry:
  push es
  push bx
  push ax
  
  mov ax, BaseOfKernelFile
  sub ax, 0100h
  mov es, ax
  
  pop ax
  mov byte [bOdd], 0
  mov bx, 3
  mul bx
  mov bx, 2
  div bx
  cmp dx, 0
  jz LABEL_EVEN
  mov byte [bOdd], 1
LABEL_EVEN:
  xor dx, dx
  mov bx, [BPB_BytesPerSec]
  div bx
  push dx
  mov bx, 0
  add ax, SectorNoOfFAT1
  
  mov cl, 2
  call ReadSector
  pop dx
  add bx, dx
  mov ax, [es:bx]
  cmp byte [bOdd], 1
  jnz LABEL_EVEN_2
  shr ax, 4
LABEL_EVEN_2:
  and ax, 0fffh
LABEL_GET_FAT_ENTRY_OK:
  pop bx
  pop es
  ret

; 读取扇区
ReadSector:
  push bp
  mov bp, sp
  sub esp, 2
  mov byte [bp-2], cl
  push bx
  mov bl, [BPB_SecPerTrk]
  div bl
  inc ah
  mov cl, ah
  mov dh, al
  shr al, 1
  mov ch, al
  and dh, 1
  pop bx
  mov dl, [BS_DrvNum]
  
.GoOnReading:
  mov ah, 2
  mov al, byte [bp-2]
  int 13h
  jc .GoOnReading
  
  add esp, 2
  pop bp
  ret  
  
KillMotor:
  push dx
  mov dx, 03f2h
  mov al, 0
  out dx, al
  pop dx
  ret
  
[section .s32]
ALIGN 32
[BITS 32]
LABEL_PM_START:
  mov ax, SelectorVideo
  mov gs, ax
  mov ax, SelectorFlatRW
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov fs, ax
  mov esp, TopOfStack
  
  push szMemChkTitle
  call DispStr
  
  add esp, 4
  call DispMemInfo  ; addr = 0x903a4
  call SetupPaging  ; addr = 0x903a9
  
  ; mov ah, 0fh
  ; mov al, 'P'
  ; mov [gs:((80*0+39)*2)], ax  
  ; jmp $
  
  ; 恢复es寄存器 （SetupPaging中改变了es值）
  mov ax, SelectorFlatRW
  mov es, ax
  
  call InitKernel  ; addr = 0x903b9 
  jmp SelectorFlatC:KernelEntryPointPhyAddr ; addr = 0x903be
  
DispAL:
  push ecx
  push edx
  push edi
  
  mov edi, [dwDispPos]
  
  mov ah, 0fH
  mov dl, al
  shr al, 4
  mov ecx, 2
  
.begin:
  and al, 01111b
  cmp al, 9
  ja .1
  add al, '0'
  jmp .2
  
.1:
  sub al, 0AH
  add al, 'A'
  
.2:
  mov [gs:edi], ax
  add edi, 2
  mov al, dl
  loop .begin
  ;add edi, 2
  mov [dwDispPos], edi
  
  pop edi
  pop edx
  pop ecx
  ret  
  
DispInt:
  mov eax, [esp+4]
  shr eax, 24
  call DispAL
  
  mov eax, [esp+4]
  shr eax, 16
  call DispAL
  
  mov eax, [esp+4]
  shr eax, 8
  call DispAL
  
  mov eax, [esp+4]
  call DispAL
  
  mov ah, 07h
  mov al, 'h'
  push edi
  mov edi, [dwDispPos]
  mov [gs:edi], ax
  add edi, 4
  mov [dwDispPos], edi
  pop edi
  ret

DispStr:
  push ebp
  mov ebp, esp
  push ebx
  push esi
  push edi 
  mov esi, [ebp+8]
  mov edi, [dwDispPos]
  mov ah, 0fh
  
.1:
  lodsb
  test al, al 
  jz .2
  cmp al, 0AH 
  jnz .3
  push eax
  mov eax, edi
  mov bl, 160
  div bl 
  and eax, 0FFH 
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
  mov [dwDispPos], edi  
  pop edi
  pop esi 
  pop ebx
  pop ebp
  ret
  
DispReturn:
  push szReturn
  call DispStr
  add esp, 4
  ret
  
DispMemInfo:
  push esi
  push edi
  push ecx

  mov esi, MemChkBuf
  mov ecx, [dwMCRNumber]
  
.loop:
  mov edx, 5
  mov edi, ARDStruct
  
.1:
  push dword [esi]
  call DispInt
  pop eax
  stosd
  add esi, 4
  dec edx
  cmp edx, 0
  jnz .1
  call DispReturn
  cmp dword [dwType], 1
  jne .2
  mov eax, [dwBaseAddrLow]
  add eax, [dwLengthLow]
  cmp eax, [dwMemSize]
  jb .2
  mov [dwMemSize], eax

.2:
  loop .loop
  call DispReturn
  push szRAMSize
  call DispStr
  add esp, 4
  push dword [dwMemSize]
  call DispInt
  add esp, 4
  pop ecx
  pop edi
  pop esi
  ret 

SetupPaging:
  xor edx, edx
  mov eax, [dwMemSize]
  mov ebx, 400000h; 4M=1024*1024 一个页表对应的内存大小
  div ebx
  mov ecx, eax  ;此时ecx为页表的个数
  test edx, edx
  jz .no_remainder
  inc ecx ;如果余数不为0就增加一个页表
.no_remainder:
  push ecx ;暂存页表个数
  
  ; 为简化处理，所有线性地址对应相等的物理地址，并且不考虑内存空洞
  ; 首先初始化页目录
  mov ax, SelectorPageDir
  mov es, ax
  xor edi, edi
  xor eax, eax
  mov eax, PageTblBase | PG_P | PG_USU | PG_RWW
.1:
  stosd  ; 将EAX中的值保存到ES:EDI指向的地址中 --- 初始化页目录
  add eax, 4096 ; 为了简化，所有页表在内存中都是连续的
  loop .1 ; 初始化ecx个页表目录项
  
  ; 再初始化所有页表(1024个 4M内存空间)
  mov ax, SelectorPageTbl
  mov es, ax
  pop eax        ; 页表个数 
  mov ebx, 1024  ; 每个页表1024个PTE
  mul ebx
  mov ecx, eax   ; PTE个数=1024*页表个数
  xor edi, edi
  xor eax, eax
  mov eax, PG_P | PG_USU | PG_RWW
.2:
  stosd
  add eax, 4096
  loop .2    
  
  mov eax, PageDirBase
  mov cr3, eax
  mov eax, cr0
  or eax, 80000000h
  mov cr0, eax
  jmp short .3
.3:
  nop 
  ret
  
InitKernel:
  xor esi, esi
  mov cx, word [BaseOfKernelPhyAddr + 2ch] ; ELF头中的e_phnum -- Program Header Table中条目个数
  movzx ecx, cx
  mov esi, [BaseOfKernelPhyAddr + 1ch] ; ELF头中e_phoff -- Program Header Table在文件中的偏移
  add esi, BaseOfKernelPhyAddr
.Begin:
  mov eax, [esi]
  cmp eax, 0 ; 检查p_type是否为PT_NULL，PT_LOAD（1）表示加载项
  jz .NoAction
  
  ;调用函数MemCpy压栈传参
  push dword [esi + 010h] ; p_filesz值      --- size
  mov eax, [esi + 04h]
  add eax, BaseOfKernelPhyAddr ; p_offset值 --- src
  push eax
  push dword [esi + 08h] ;  p_vaddr值       --- dst
  call MemCpy
  add esp, 12
.NoAction:
  add esi, 020h
  dec ecx
  jnz .Begin
  ret

; 内存拷贝 将 kernel.bin内容拷贝至 0x30000中 
; 函数原型 void* MemCpy(void* es:pDest, void* ds:pSrc, int iSize);  
MemCpy:
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
  
[section .data1]
ALIGN 32
LABEL_DATA:
   ; 实模式下使用
  _szMemChkTitle:   db "BaseAddrL BaseAddrH LengthLow LengthHigh Type", 0Ah, 0
  _szRAMSize:       db "RAM Size: ", 0 
  _szReturn:        db 0Ah, 0
                    
  _dwMCRNumber:     dd 0
  _dwDispPos:       dd (80*6+0)*2
  _dwMemSize:       dd 0
  _ARDStruct:
    _dwBaseAddrLow: dd 0
	_dwBaseAddrHigh:dd 0
	_dwLengthLow:   dd 0
	_dwLengthHigh:  dd 0
	_dwType:        dd 0
  _MemChkBuf: times 256 db 0
  
  ; 保护模式下使用
  szMemChkTitle    equ  BaseOfLoaderPhyAddr + _szMemChkTitle
  szRAMSize        equ  BaseOfLoaderPhyAddr + _szRAMSize
  szReturn         equ  BaseOfLoaderPhyAddr + _szReturn
  dwDispPos        equ  BaseOfLoaderPhyAddr + _dwDispPos
  dwMemSize        equ  BaseOfLoaderPhyAddr + _dwMemSize
  dwMCRNumber      equ  BaseOfLoaderPhyAddr + _dwMCRNumber
  ARDStruct        equ  BaseOfLoaderPhyAddr + _ARDStruct
    dwBaseAddrLow  equ  BaseOfLoaderPhyAddr + _dwBaseAddrLow
	dwBaseAddrHigh equ  BaseOfLoaderPhyAddr + _dwBaseAddrHigh
	dwLengthLow    equ  BaseOfLoaderPhyAddr + _dwLengthLow
	dwLengthHigh   equ  BaseOfLoaderPhyAddr + _dwLengthHigh
	dwType         equ  BaseOfLoaderPhyAddr + _dwType
  MemChkBuf        equ  BaseOfLoaderPhyAddr + _MemChkBuf
  
StackSpace: times 1024 db 0  
TopOfStack: equ BaseOfLoaderPhyAddr + $  ; 栈顶


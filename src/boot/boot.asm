
org 07c00h

jmp short LABEL_BEGIN
nop

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

; =============================================================================

; 常量
BaseOfStack               equ   07c00h           ; 堆栈基地址 (栈底，从这个位置向地址生长)
BaseOfLoader              equ   09000h           ; Loader.bin被加载到的位置 -- 段地址
OffsetOfLoader            equ   0100h            ; Loader.bin被加载到的位置 -- 偏移地址
RootDirSectors            equ   14               ; 根目录占用空间
SectorNoOfRootDirectory   equ   19               ; Root Directory 的第一个扇区
DeltaSectorNo             equ   17
SectorNoOfFAT1            equ   1
; 变量
wRootDirSizeForLoop       dw    RootDirSectors   ; Root Dir占用的扇区数 在循环中减至0
wSectorNo                 dw    0                ; 要读的扇区号
bOdd                      dd    0                ; 奇数还是偶数
 
; 字符串
LoaderFileName            db    "LOADER  BIN", 0 ; loader.bin的文件名
MessageLength             equ   9                ; 为简单起见，下面每个字符串的长度均为9个字节
BootMessage               db    "Booting  "
Message1                  db    "Ready.   "
Message2                  db    "No LOADER"
Message3                  db    "LOADER OK"

; =============================================================================

LABEL_BEGIN:
  mov ax, cs
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, BaseOfStack
  
  ; 清屏
  mov ax, 0600h
  mov bx, 0700h
  mov cx, 0
  mov dx, 0184fh
  int 10h
  
  ; 输出Booting  
  mov dh, 0
  call DispStr
  
  xor ah, ah     ; --|
  xor dl, dl     ;   |--软驱复位
  int 13h        ; --|
  
  ; 在A盘的根目录寻找loader.bin文件
  mov word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
  cmp word [wRootDirSizeForLoop], 0  ; 根目录区共14个扇区 
  jz LABEL_NO_LOADERBIN
  dec word [wRootDirSizeForLoop]
  
  mov ax, BaseOfLoader
  mov es, ax
  mov bx, OffsetOfLoader
  
  mov ax, [wSectorNo]  ; 开始第19个扇区号 
  mov cl, 1
  call ReadSector ; 从ax扇区开始，读取cl个扇区，数据存储至 es:bx
  
  mov si, LoaderFileName  ; ds:si --> "LOADER  BIN"
  mov di, OffsetOfLoader  ; es:di --> BaseOfLoader:0100 = BaseOfLoader*10h + 100
  
  cld  ; 清方向标志
  mov dx, 10h ; 表示一个扇区有16个目录项 16*32 = 512
  
LABEL_SEARCH_FOR_LOADERBIN:
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
  mov si, LoaderFileName
  jmp LABEL_SEARCH_FOR_LOADERBIN
  
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
  add word [wSectorNo], 1
  jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN
  
LABEL_NO_LOADERBIN:
  mov dh, 2
  call DispStr
  jmp $
  
LABEL_FILENAME_FOUND:
  mov ax, RootDirSectors   ; 共14个根目录区 
  and di, 0ffe0h
  add di, 01ah
  mov cx, word [es:di]
  push cx
  add cx, ax
  add cx, DeltaSectorNo
  mov ax, BaseOfLoader
  mov es, ax
  mov bx, OffsetOfLoader
  
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
  mov dh, 1
  call DispStr
  jmp BaseOfLoader:OffsetOfLoader

; 打印消息  
DispStr:
  mov ax, MessageLength
  mul dh
  add ax, BootMessage
  mov bp, ax
  mov ax, ds
  mov es, ax
  mov cx, MessageLength
  mov ax, 01301h
  mov bx, 0007h
  mov dl, 0
  int 10h
  ret  
  
GetFATEntry:
  push es
  push bx
  push ax
  
  mov ax, BaseOfLoader
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
  
times 510-($-$$) db 0
dw 0xaa55
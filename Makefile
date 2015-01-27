
AS   = nasm
LD   = ld
CC   = gcc
DASM = ndisasm

INCLUDE  = -I src/
AS_FLAGS = $(INCLUDE)
CC_FLAGS = $(INCLUDE) -m32 -c 
# -s 链接文件的时候删除其中的符号信息
# -Ttext 0x30400 设置链接文件输出的地址
LD_FLAGS = -s -Ttext 0x30400 -melf_i386
# -u 和 -b 32相同，表示反汇编成32位处理器指令集
# -o 反汇编的指令地址
# -e 反汇编指令的偏移地址
DASM_FLAGS = -u -o 0x30400 -e 0x400

all : boot kernel buildimg
		
boot : 
	$(AS) $(AS_FLAGS) ./src/boot.asm   -o ./bin/boot.bin 
	$(AS) $(AS_FLAGS) ./src/loader.asm -o ./bin/loader.bin	
	
kernel : 
	$(AS) $(AS_FLAGS) ./src/kernel.asm -f elf -o ./bin/kernel.o
	$(AS) $(AS_FLAGS) ./src/string.asm -f elf -o ./bin/string.o
	$(AS) $(AS_FLAGS) ./src/klib.asm -f elf -o ./bin/klib.o
	$(CC) $(CC_FLAGS) ./src/start.c -o ./bin/start.o
	$(CC) $(CC_FLAGS) ./src/main.c -o ./bin/main.o
	$(LD) $(LD_FLAGS) -o ./bin/kernel.bin ./bin/kernel.o ./bin/string.o ./bin/start.o ./bin/klib.o ./bin/main.o
	
buildimg:
	mount ./img/Tinix.img /mnt/floppy -o loop
	cp -f ./bin/loader.bin /mnt/floppy/
	cp -f ./bin/kernel.bin /mnt/floppy/
	umount  /mnt/floppy
	
disasm:
	$(DASM) $(DASM_FLAGS) ./bin/kernel.bin > ./bin/dis_kernel.asm

clean:
	rm -rf ./bin/*.*

	
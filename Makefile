
AS = nasm
LD = ld
CC = gcc

INCLUDE = -I src/
AS_FLAGS = $(INCLUDE)
CC_FLAGS = $(INCLUDE) -c 


all : boot kernel buildimg
		
boot : 
	$(AS) $(AS_FLAGS) ./src/boot.asm   -o ./bin/boot.bin 
	$(AS) $(AS_FLAGS) ./src/loader.asm -o ./bin/loader.bin	
	
kernel : 
	$(AS) $(AS_FLAGS) ./src/kernel.asm -f elf -o ./bin/kernel.o
	$(AS) $(AS_FLAGS) ./src/string.asm -f elf -o ./bin/string.o
	$(AS) $(AS_FLAGS) ./src/klib.asm -f elf -o ./bin/klib.o
	$(CC) $(CC_FLAGS) ./src/start.c -o ./bin/start.o
	$(LD) -s -Ttext 0x30400 -o ./bin/kernel.bin ./bin/kernel.o ./bin/string.o ./bin/start.o ./bin/klib.o
	
buildimg:
	mount ./img/Tinix.img /mnt/floppy -o loop
	cp -f ./bin/loader.bin /mnt/floppy/
	cp -f ./bin/kernel.bin /mnt/floppy/
	umount  /mnt/floppy

clean:
	rm -rf ./bin/*.*

	
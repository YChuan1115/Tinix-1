
AS = nasm
LD = ld

INCLUDE = -I src/boot/
FLAGS = $(INCLUDE)

all : boot kernel buildimg
		
boot : 
	$(AS) $(FLAGS) ./src/boot/boot.asm -o ./bin/boot.bin 
	$(AS) $(FLAGS) ./src/boot/loader.asm -o ./bin/loader.bin	
	
kernel : 
	$(AS) $(FLAGS) ./src/boot/kernel.asm -f elf -o ./bin/kernel.o
	$(LD) $(FLAGS) -s -Ttext 0x30400 ./bin/kernel.o -o ./bin/kernel.bin
	
buildimg:
	mount ./img/Tinix.img /mnt/floppy -o loop
	cp -f ./bin/loader.bin /mnt/floppy/
	cp -f ./bin/kernel.bin /mnt/floppy/
	umount  /mnt/floppy

clean:
	rm -rf ./bin/*.*

	
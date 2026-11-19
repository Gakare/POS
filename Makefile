ASM=nasm
SOURCE_DIR=code
BUILD_DIR=build
TARGET=main

.PHONY: compile clean

# TODO: Figure out how to make run a debugger with this img
$(BUILD_DIR)/main.img: $(BUILD_DIR)/main.bin
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main.img
	truncate -s 1440k $(BUILD_DIR)/main.img

$(BUILD_DIR)/main.bin: $(SOURCE_DIR)/Booty0.asm $(SOURCE_DIR)/Booty1.asm
	$(ASM) -i$(SOURCE_DIR) $(SOURCE_DIR)/Booty0.asm -f bin -o $(BUILD_DIR)/Booty0.bin
	$(ASM) -i$(SOURCE_DIR) $(SOURCE_DIR)/Booty1.asm -f bin -o $(BUILD_DIR)/Booty1.bin
	cat $(BUILD_DIR)/Booty0.bin $(BUILD_DIR)/Booty1.bin > $(BUILD_DIR)/main.bin

compile:
	nasm -f elf32 -g -F dwarf -o $(BUILD_DIR)/main.o $(SOURCE_DIR)/main.asm
	ld -m i386pe -Ttext=0x7c00 -o $(BUILD_DIR)/main.exe $(BUILD_DIR)/main.o

clean:
	rm build/*

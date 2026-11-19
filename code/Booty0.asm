; NOTE: This is following Cambridge project 4. this is boot0
; [x] Disables interrupts
; [x] Canonicalize %CS:%IP
; [x] Load segment registers
; [x] Sets the stack pointer
; [x] Enable interrupts
; [x] Check if cpu is 32 bit
; [x] Reset the floppy disk controller
; [x] Read boot1 sectors from the disk
; [x] Jump to boot1 code
; [x] Print error message, disable interrupts, and permanently suspend progress in execution

; NOTE: Uninitialized variables
section .bss
DriveNumber: resb 1

section .code
; NOTE: When creating an .obj file omit org instruction
; TODO: Find a way to remove the org instruction while still making it work. Maybe with a linker?
org 0x7C00 ; Sets the offset
bits 16

Start:
; NOTE: Save drive number which is passed to dl when BIOS passes to bootloader
mov [DriveNumber], dl

; NOTE: This is how to perform long jumps in NASM
jmp 0x0000:Main ; This should canonicalize CS:IP => 0x0000:0x????, currently don't know where IP would be?

; --- Main entry point ---
Main:

; --- Bootloading ---
; (IMPORTANT): The bootloader's entire purpose is to be overruled by the kernel!
; The bootloader ultimately has to bring the kernel in memory,
; switch to an environment that the kernel will like and then transfer control
; to the kernel.

; NOTE: Early environment in MBR
cli ; Disable interrupt flag
cld ; Clear DF flag
clc ; Clear carry flag

; NOTE: Setup data segments
xor ax, ax
; TODO: Technically supposed to do (7C00 - BOOT_ORG) / 16
mov ds, ax ; NOTE: Will use this segment to refer to the first 64 kB.

mov es, ax ; NOTE: Will use this segment to refer when loading a portion of the kernel
; NOTE: fs and gs are not available on 16 bit real mode
;mov fs, ax ; NOTE: General purpose segment
;mov gs, ax ; NOTE: General purpose segment

; Setup stack
; NOTE: ss:sp => 0x0000:0x7C00 (segment:offset) => (segment << 4) + offset
; TODO: Search up if there are other instructions to add to set up the stack, but I think this is good?
mov ss, ax
mov bp, 0x7C00 ; TODO: Is this even necessary?
mov sp, bp ; Stack grows downwards from where we are loaded in memory

; NOTE: Enable interrupts
sti

; NOTE: Printing booty0 setup message
mov si, msg_setup
call PrintString

; NOTE: Checking if cpu is 32 bit
CheckIfCpuIs32Bit:
push bx
pushf
pushf
pop bx ; NOTE: old flags -> BX
mov ax, bx
xor ah, 0x70 ; NOTE: Try to change b14 (NT)
push ax ; or b13:b12 (IOPL)
popf
pushf
pop ax ; NOTE: new flags -> AX
popf
xor al, al
xor ah, bh ; NOTE: 32-bit cpu if we changed NT
je .CpuIs32Bit ; NOTE: Checks zero flag if it is set
and ah, 0x70 ; or IOPL
je .CpuIs32Bit

.CpuIsNot32Bit:
mov si, msg_cpu_not_32_bit
call PrintString
jmp .CheckCpuDone

.CpuIs32Bit:
mov si, msg_cpu_is_32_bit
call PrintString

.CheckCpuDone:

; --- Establishing boot1 execution environment ---
; NOTE: Reset floppy disk controller
mov ah, 0x00 ; NOTE: Reset disk drives
int 0x13 ; NOTE: disk services

; NOTE: Set up DX register for disk loading
mov dh, 1 ; NOTE: Number of sectors we want to load in memory, MAX is 53
mov dl, [DriveNumber] ; Drive number to load

; NOTE: Set up ES:BX memory address, we want 0x0000:0x1000 for booty1
mov bx, 0x1000

; TODO: Figure out how many bytes are in a sector, typically only 512 bytes
; NOTE: Read the sector and load it to 0x0000:0x1000
push dx  ; Store dx on stack so we can compare number of sectors we actually read

; NOTE: We can only read up to 53 sectors. Anything greater results in overlapping 0x7C00.
.ReadDisk:
mov ah, 0x02 ; Read sector command with int 0x13
; NOTE: If we are in 0x0000:0x1000, we can only go up to 53 sectors. Anymore will overwrite Booty0
mov al, dh ; Read number of sectors we want, i.e., 1
mov ch, 0x00 ; Cylinder number, i.e., 0
mov cl, 0x02 ; Sector number, i.e., 2
mov dh, 0x00 ; Head number, i.e., 0
int 0x13

jc .DiskError ; Jumps if disk read error (indicated by cf = 1)

pop dx
cmp al, dh ; Compares if we actually read the number of sectors we wanted
jne .DiskError

; NOTE: Past this point means that we loaded the sector successfully
mov si, msg_disk_successful
call PrintString

jmp 0x0000:0x1000 ; Far jump to the next sector

.DiskError:
mov si, msg_disk_error
call PrintString ; Notify the user of failure with reading the sector
cli ; Disable interrupts
hlt
jmp .Halt

.Error:
jmp .Halt

.Halt:
; Should never go pass this
hlt
jmp .Halt

; Include files
%include 'PrintString.asm'

; NOTE: Initialized variables
msg_setup: db 'Booty0 setup...', ENDL, 0
msg_disk_error: db 'Failed to read disk sector.', ENDL, 0
msg_disk_successful: db 'Successfully read disk sector to Booty1.', ENDL, 0
msg_cpu_not_32_bit: db 'Detected that cpu is not 32/64 bit.', ENDL, 0
msg_cpu_is_32_bit: db 'Detected that cpu is 32/64 bit.'

times 510-($-$$) db 0
dw 0xAA55 ; BIOS boot signature
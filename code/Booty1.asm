; NOTE: Booty1
; [x] Set the stack pointer
; [x] Query the BIOS for the size of lower memory
; [x] Query the BIOS for the size of upper memory
; [] Iterate through the ES:DI buffer to parse each type and print to screen
; [] Read kernel sectors from the floppy into lower memory
; [] Enable the A20 gate
; [] Disable interrupts
; [] Load the Global Descriptor Table (and Local Descriptor Table?)
; [] Switch to protected mode
; [] Invoke the Multiboot loader
; [] Begin execution of the kernel

org 0x1000

section .bss

section .code

jmp Start

; NOTE: Displays the base, size, and memory type
DisplayMemoryInfo:
push dx
push bx
push ax
xor dx, dx
mov ax, es
mov bx, 16 ; NOTE: bx seems to change the base, base16
call PrintNumber
pop ax
pop bx
pop dx
ret

Start:
mov si, msg_booty1_successful
call PrintString

; TODO: Implement int 15h AX=E801h, int 15h AH=88h, INT 12h
; NOTE: Get physical memory map BIOS int 15h EAX E820h (32-bit CPU only)
; NOTE: ES:DI points to buffer of 24 byte entries
; NOTE: BP will = number of total entries
MemoryMapEntryCountBase equ 0x8000

GetMemoryMap:
mov si, msg_checking_memory
call PrintString

pusha
clc ; NOTE: Clear carry flag
mov di, MemoryMapEntryCountBase + 4 ; NOTE: Where I will be storing the entries (ES:DI => 0x0000:0x8004)
xor ebx, ebx ; NOTE: Clear to start retrieving entries
xor bp, bp ; NOTE: This will keep track of memory entries
mov edx, 0x534D4150 ; NOTE: 'SMAP' signature which will be compared to EAX. (In little endian => 'PAMS')
mov eax, 0xE820 ; NOTE: Bios interrupt function number
mov [ES:DI + 20], dword 1 ; NOTE: Stores 1 imm as 4 bytes, to force a valid 3.x ACPI entry
mov ecx, 24 ; NOTE: Each entry can be up to 24 bytes
int 0x15
jc short .MemoryError ; NOTE: Carry flag will be set, if function is not supported or errored

mov edx, 0x534D4150 ; NOTE: Some BIOSes will trash this register.
cmp eax, edx ; NOTE: Verify success by checking register signatures
jne short .MemoryError

test ebx, ebx ; NOTE: If clear, list is only 1 entry long (which is worthless)
je short .MemoryError
jmp short .JumpStart

.NextEntry:
mov eax, 0xE820 ; NOTE: Eax gets trashed after every int 0x15 call
mov [es:di + 20], dword 1 ; NOTE: Forces a valid ACPI 3.X entry
mov ecx, 24 ; NOTE: Reset ECX
int 0x15
jc short .FinishedQuery ; NOTE: If carry is set, end of list is reached
mov edx, 0x0534D4150 ; NOTE: Edx gets trashed after every int 0x15 call

; NOTE: Start of the querying loop
.JumpStart:
jcxz .SkipEntry ; NOTE: If ecx is clear, this means that length == 0, skip
cmp cl, 20 ; NOTE: Checks if we get a 24 byte ACPI 3.X response
jbe short .NotExtended
test byte [es:di + 20], 1 ; NOTE: If it is there, check if the "ignore this data" bit is clear
je short .SkipEntry

.NotExtended:
mov ecx, [es:di + 8] ; NOTE: Get lower uint32_t bytes of memory region length
or ecx, [es:di + 12] ; NOTE: "or" with upper uint32_t to test for 0, which sets ZF
jz .SkipEntry ; NOTE: If uint64_t length is 0, skip entry
inc bp ; NOTE: Got a good entry, increment bp to move to the next storage spot
add di, 24 ; NOTE: offset by 24 for next entry

.SkipEntry:
test ebx, ebx ; If ebx is clear, list is complete
jne short .NextEntry

.FinishedQuery:
mov [es:MemoryMapEntryCountBase], bp ; NOTE: Store the entry count at 0x0000:0x8000
clc ; NOTE: Clear the carry flag because it was set to get here
popa
jmp .GetMemoryMapDone ; TODO: Maybe just turn this into a function

.MemoryError:
stc
mov si, msg_query_memory_error
call PrintString

.GetMemoryMapDone:

.Halt:
hlt
jmp short .Halt

%include 'PrintString.asm'

msg_booty1_successful: db 'Moved to booty1 successfully!', ENDL, 0
msg_checking_memory: db 'Checking memory map:', ENDL, 0
msg_query_memory_error: db 'Failed to query the size of memory.', ENDL, 0

msg_mem_base: db 'base=0x', 0

times 512-($-$$) db 0
; --- API ---
; PrintString
; PrintNumber
; ReadInputAndPrint
; -----------

%define ENDL 0x0D, 0x0A

; --- Prints a string to the screen. ---
; Params:
; - ds:si points to string
PrintString:
push si
push bx
push ax
cld ; NOTE: String operations go up

.LoadByte:
lodsb ; NOTE: Loads next character in al
or al, al ; NOTE: Verify if character is null
jz .Done

.PrintToScreen:
mov ah, 0x0e ; NOTE: Write character in TTY mode
xor bx, bx ; NOTE: video page 0
int 0x10

jmp .LoadByte

.Done:
pop ax
pop bx
pop si
ret

; TODO: Work on printing a number to the screen to make it easier to understand physical memory layout
; NOTE: Taken from Chris Giese (RIP, not actually sure if he is dead, his website is tho)
; --- Prints a number to the screen ---
; Params:
; - ds:si points to a string
times 40 db 0 ; NOTE: Best guess is that it places 40 0-bytes for the NumberBuffer
NumberBuffer: db 0

PrintNumber:
push si
push dx
push cx
push bx
push ax

mov si, NumberBuffer

; NOTE: From Randall Hyde's "Art of Assembly"
; start: DX=dividend MSW, AX=dividend LSW, BX=divisor
.ExtendedPreciseDivide:
push ax
mov ax, dx
xor dx, dx

; NOTE: before div: DX=0, AX=dividend MSW, BX=divisor
; NOTE: after div: AX=quotient LSW, DX=intermediate remainder
div bx
mov cx, ax
pop ax

; NOTE: before div: DX=intermediate remainder, AX=dividend LSW, BX=divisor
; NOTE: after div: AX=quotient LSW, DX=remainder
div bx ; NOTE: unsigned division

; NOTE: end: DX=quotient MSW, AX=quotient LSW, CX=remainder
xchg dx, cx
add cl, '0'
cmp cl, '9'
jbe .PushToBuffer
add cl, ('A'-('9'+1))

.PushToBuffer:
dec si
mov [si], cl

mov cx, ax
or cx, dx
jne .ExtendedPreciseDivide
call PrintString

pop ax
pop bx
pop cx
pop dx
pop si
ret

; --- Takes input and prints to screen ---
ReadInputAndPrint:
push ax
.Loop:
; Reads character
mov ah, 0x00
int 0x16 ; Waits for keypress

; Checks for keycode
cmp al, 0x08 ; Backspace
je .Backspace

cmp al, 0x0D ; Carriage return and line feed
je .Done

; Print to screen
mov ah, 0x0E
int 0x10

jmp .Loop

.Backspace:
mov ah, 0x0E
mov al, 0x08
int 0x10 ; Backspace on the screen

mov al, ' '
int 0x10 ; Blank character out

mov al, 0x08
int 0x10 ; Backspace again

jmp .Loop

.Done:
mov ah, 0x0E
mov al, 0x0D
int 0x10 ; Carriage return

mov al, 0x0A
int 0x10 ; Newline

jmp .Loop

pop ax
ret
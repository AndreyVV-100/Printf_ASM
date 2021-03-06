;.intel_syntax noprefix

%macro GetPush 0
    mov r11,  qword [rbp + r10]
    add r10, SizeOfPush
%endmacro

%macro PutChar 1
    mov byte [Buf + rdx], %1
    inc rdx
%endmacro

section .text  

global Printf
extern main
global _start

; _start:

;     push 0xEDA
;     push 0xEDA
;     push StrTest
;     push 'y'
;     push 'x'
;     push 0xEDA
;     push Msg
;     call Printf
;     add rsp, 56

;     mov rax, 0x3C
;     xor rdi, rdi
;     syscall

;---------------------------------------

Printf:

    pop rax
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi
    push rax

    push rbp 
    mov  rbp, rsp

    mov r8,  qword [rbp + 16]   ; pointer to start of format line
    mov rdx, 0                  ; shift of buffer
    mov r10, 24                 ; pointer to next element

    mov rsi, Buf                ; poiner to buffer

    While_no_zero:

        cmp byte [r8], 0
        je Printf_end

        mov bl, [r8]
        cmp bl, '%'
        je Process_percent

        mov bl, [r8]
        cmp bl, '\'
        je Process_backslash

        PutChar bl

        While_buf_check:

            inc r8
            mov rbx, BufLen
            sub rbx, 8
            cmp rdx, rbx
            jbe While_no_zero
            call Drop_Buf

        jmp While_no_zero

    Printf_end:
    call Drop_Buf

    pop rbp
    pop rax
    add rsp, 48
    push rax
    ret

;---------------------------------------

Process_percent:

    inc r8
    xor rbx, rbx
    mov bl, byte [r8]

    cmp bl, '%'
    je Process_dper

    cmp bl, 'a'
    jb Process_err

    cmp bl, 'z'
    ja Process_err

    jmp [8 * rbx + JumpTable - 8 * 'a']

;---------------------------------------

    Process_dper:

        PutChar '%'
        jmp While_buf_check

    Process_b:
    ; base of system count: 2

        mov byte [ShrShift], 1
        mov byte [NumMask],  1b
        call PrintPower2
        jmp While_buf_check

    Process_c:

        GetPush
        PutChar r11b
        jmp While_buf_check

    Process_d:

        call PrintDecimal
        jmp While_buf_check

    Process_o:
    ; base of system count: 8

        mov byte [ShrShift], 3
        mov byte [NumMask],  111b
        call PrintPower2
        jmp While_buf_check

    Process_s:

        call Drop_Buf
        GetPush
        mov rsi, r11
        call Strlen
        call Drop_Buf
        mov rsi, Buf
        jmp While_buf_check

    Process_x:
    ; base of system count: 16

        mov byte [ShrShift], 4
        mov byte [NumMask],  1111b
        call PrintPower2
        jmp While_buf_check

    Process_g:

        PutChar 0xE2
        PutChar 0x99 
        PutChar 0x82 
        jmp While_buf_check

    Process_err:

        PutChar 0xE2
        PutChar 0x98
        PutChar 0x92
        jmp While_buf_check

;---------------------------------------        

Process_backslash:

    inc r8
    xor rbx, rbx
    mov bl, byte [r8]

    cmp bl, '\'
    je BackSlash_dbslash

    cmp bl, '"'
    je BackSlash_dquote

    cmp bl, 'a'
    jb BackSlash_err

    cmp bl, 'v'
    ja BackSlash_err

    mov bl, [rbx + BackSlashTable - 'a']

    Process_backslash_end: 

        PutChar bl
        jmp While_buf_check
    
;---------------------------------------

        BackSlash_dbslash:
            
            mov bl, '\'
            jmp While_buf_check

        BackSlash_dquote:
            
            mov bl, '"'
            jmp While_buf_check

        BackSlash_err:
            
            mov bl, 0
            jmp While_buf_check

;---------------------------------------

Drop_Buf:

    mov rax, 0x01 ; syscall command
    mov rdi, 1    ; descriptor of file
    syscall
    xor rdx, rdx
    ret

;---------------------------------------

PrintPower2:
; Need ShrShift and NumMask

    call Drop_Buf
    GetPush ; In r11 - number
    xor rcx, rcx
    mov r13, Buf + BufLen - 1

    read_number_pow2:
        mov cl,  byte [NumMask]
        and rcx, r11
        mov cl,  byte [rcx + ListOfDigits]

        mov byte [r13], cl 
        mov cl, byte [ShrShift]
        shr r11, cl

        inc rdx
        dec r13
        cmp r11, 0
        jne read_number_pow2

    ; Adress
    mov rcx, Buf + BufLen
    sub rcx, rdx
    mov rsi, rcx
    
    call Drop_Buf

    mov rsi, Buf

    ret

;---------------------------------------

PrintDecimal:

    call Drop_Buf
    GetPush ; In r11 - number
    xor rcx, rcx
    xor r12, r12
    mov rax, r11
    mov rbx, 10

    mov rsi, Buf + BufLen - 1

    read_number_decimal:

        xor rdx, rdx
        div rbx
        mov cl, byte [rdx + ListOfDigits]
        mov byte [rsi], cl

        inc r12
        dec rsi
        cmp rax, 0
        jne read_number_decimal

    ; Number
    mov rdx, r12
    inc rsi

    call Drop_Buf

    mov rsi, Buf

    ret

;---------------------------------------

Strlen:

    xor rdx, rdx
    
    Strlen_while:

        mov bl, byte [rsi + rdx]
        inc rdx
        cmp bl, 0
        jne Strlen_while

    dec rdx
    ret

section .data

SizeOfPush: equ 8

Buf:    times 256 db '0'
BufLen: equ $ - Buf

ShrShift: db 0
NumMask:  db 0

ListOfDigits: db '0123456789ABCDEF'

; Jump table for Process_percent
JumpTable: dq   Process_err,    \
                Process_b,      \
                Process_c,      \
                Process_d,      \
                Process_err,    \
                Process_err,    \
                Process_g,      \
                Process_err,    \
                Process_err,    \
                Process_err,    \
                Process_err,    \
                Process_d,      \
                Process_err,    \
                Process_err,    \
                Process_o,      \
                Process_err,    \
                Process_err,    \
                Process_err,    \
                Process_s,      \
                Process_err,    \
                Process_err,    \
                Process_err,    \
                Process_err,    \
                Process_x,      \
                Process_err,    \
                Process_err     

;---------------------------------------

;                  a     b     c, d, e, f   , g, h, i, j, k, l, m, n   , o, p, q, r   , s, t   , u, v
BackSlashTable: db 0x07, 0x08, 0, 0, 0, 0x0c, 0, 0, 0, 0, 0, 0, 0, 0x0a, 0, 0, 0, 0x0d, 0, 0x09, 0, 0x0b

; \a 	0x07 	Звуковой сигнал
; \b 	0x08 	Перевод каретки на одно значение назад
; \f 	0x0c 	Новая страница
; \n 	0x0a 	Перевод строки, новая строка
; \r 	0x0d 	Возврат каретки
; \t 	0x09 	Табуляция
; \v 	0x0b 	Вертикальная табуляция
; \" 	0x22 	Двойная кавычка
; \\ 	0x5с 	Обратный слеш

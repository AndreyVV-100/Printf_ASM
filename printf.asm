;.intel_syntax noprefix

%macro GetPush 0
    mov r11,  qword [rbp + r10]
    add r10, SizeOfPush
%endmacro

section .text 
global _start

_start:

    push 0xEDA
    push 0xEDA
    push StrTest
    push 0xEDA
    push Msg
    call Printf
    add rsp, 40

    mov rax, 0x3C
    xor rdi, rdi
    syscall

Printf:

    push rbp 
    mov  rbp, rsp

    mov r8,  qword [rbp + 16]   ; pointer to start of format line
    mov r9,  0                  ; shift of line // ToDo: r8 & r9 -> r8
    mov rdx, 0                  ; shift of buffer
    mov r10, 24                 ; pointer to next element

    mov rsi, Buf                ; poiner to buffer

    While_no_zero:

        cmp byte [r8 + r9], 0
        je Printf_end

        mov bl, [r8 + r9]
        cmp bl, '%'
        je Process_percent

        mov byte [Buf + rdx], bl
        inc r9
        inc rdx

        While_buf_check:

            mov rbx, BufLen
            sub rbx, 8
            cmp rdx, rbx
            jbe While_no_zero
            call Drop_Buf

        jmp While_no_zero

    Printf_end:
    call Drop_Buf
    pop rbp
    ret

Process_percent:

    inc r9

    mov bl, byte [r8 + r9]

    cmp bl, 'b'
    je Process_b

    cmp bl, 'd'
    je Process_d

    cmp bl, 'o'
    je Process_o

    cmp bl, 's'
    je Process_s

    cmp bl, 'x'
    je Process_x

    Process_percent_end:
        inc r9
        jmp While_buf_check

;--------------------------------

    Process_b:
    ; base of system count: 2

        mov byte [ShrShift], 1
        mov byte [NumMask],  1b
        call PrintPower2
        jmp Process_percent_end

    Process_c:

        GetPush
        mov byte [Buf + rdx], r11b
        inc rdx
        jmp Process_percent_end

    Process_d:

        call PrintDecimal
        jmp Process_percent_end

    Process_o:
    ; base of system count: 8

        mov byte [ShrShift], 3
        mov byte [NumMask],  111b
        call PrintPower2
        jmp Process_percent_end

    Process_s:

        call Drop_Buf
        GetPush
        mov rsi, r11
        call Strlen
        call Drop_Buf
        mov rsi, Buf
        jmp Process_percent_end

    Process_x:
    ; base of system count: 16

        mov byte [ShrShift], 4
        mov byte [NumMask],  1111b
        call PrintPower2
        jmp Process_percent_end

Drop_Buf:

    mov rax, 0x01 ; syscall command
    mov rdi, 1    ; descriptor of file
    syscall
    xor rdx, rdx
    ret

PrintPower2:
; Need ShrShift and NumMask

    call Drop_Buf
    GetPush ; In r11 - number
    xor rcx, rcx

    read_number_pow2:
        mov cl,  byte [NumMask]
        and rcx, r11
        mov cl,  byte [rcx + ListOfDigits]

        mov r13, Buf + BufLen - 1
        sub r13, rdx
        mov byte [r13], cl 
        mov cl, byte [ShrShift]
        shr r11, cl

        inc rdx
        cmp r11, 0
        jne read_number_pow2

    ; Adress
    mov rcx, Buf + BufLen
    sub rcx, rdx
    mov rsi, rcx
    
    call Drop_Buf

    mov rsi, Buf

    ret

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
        
        ; ToDo: mov r13 -> dec r13 -> dec rsi
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

Msg:    db "azaz %x xx %s xx %d %o azaz", 0x0a, 0
MsgLen: equ $ - Msg

Buf:    times 256 db '0'
BufLen: equ $ - Buf

ShrShift: db 0
NumMask:  db 0

StrTest: db "Ахахаха быдло отсеялось, лол кек чебурек!!!! Ахахахаахахахахахаха", 0

ListOfDigits: db '0123456789ABCDEF'

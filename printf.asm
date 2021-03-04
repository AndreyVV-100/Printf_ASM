;.intel_syntax noprefix

section .text 
global _start

_start:

    push Msg
    call Printf
    add rsp, 8

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

    mov rax, 0x01               ; syscall command
    mov rdi, 1                  ; descriptor of file
    mov rsi, Buf                ; poiner to buffer

    While_no_zero:

        cmp byte [r8 + r9], 0
        je Printf_end

        mov bl, [r8 + r9]
        mov byte [Buf + rdx], bl
        inc r9
        inc rdx

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



Drop_Buf:

    syscall
    xor rdx, rdx
    ret


section .data

Msg:    db "azaz", 0x0a, 0
MsgLen: equ $ - Msg

Buf:    times 256 db '0'
BufLen: equ $ - Buf

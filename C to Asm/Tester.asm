section .text  

extern printf
global main

main:

    push rbp 
    mov  rbp, rsp

    mov rsi, 100
    mov rdi, Msg

    call printf

    pop rbp
    ret

section .data

Msg: db "Кажется, эта %d%%-ная хрень работает!", 0x0a, 0

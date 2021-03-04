;.intel_syntax noprefix

section .text 
global _start

_start:

    mov rax, 0x01
    mov rdi, 1
    mov rsi, Msg
    mov rdx, MsgLen
    syscall

    mov rax, 0x3C
    xor rdi, rdi
    syscall

section .data

Msg:    db "Ээээй бля куда прёшь, не видишь - машина на асме прогает!!!211212321оаоаоаоа", 0x0a
MsgLen: equ $ - Msg

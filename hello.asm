section .text

global _start                   ; predefined entry point name for MacOS ld

_start:
    mov rax, 0x2000004         ; write64bsd (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 1                 ; stdout
    mov rsi, Msg               ; address of the message
    mov rdx, MsgLen            ; length of the message
    int 0x80


    mov rax, 0x2000001         ; exit64bsd (rdi)
    xor rdi, rdi
    syscall

section     .data

Msg:        db "Hello, world", 0x0a
MsgLen      equ $ - Msg

;// ld -macosx_version_min 10.7.0 -o hello hello.o
;// nasm -f macho64 -o hello.o hello.asm

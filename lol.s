section .text
    extern _print
    global _SubFunc

_SubFunc:

    mov rax, rdi  ;// Перемещение значения аргумента a из rdi в rax
    mov rbx, rsi  ;// Перемещение значения аргумента b из rsi в rbx

    sub rax, rbx

    mov rdi, rax
    push rax
    call _print
    pop rax

    ret

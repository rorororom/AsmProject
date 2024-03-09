section .text

global MyPrintf
extern printf

MyPrintf:
    pop rax                         ; Извлекаем значение из вершины стека и помещаем его в регистр rax.
                                    ; rax = адрес возврата из функции, которая вызвала MyPrintf

    mov rax, [ret_adress]          ; Сохраняем это значение в переменную ret_adress
    xor rax, rax                    ; rax = 0

    ; Сохраняем значения всех регистров, которые были восстановлены как аргументы из функции
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    call PrintFFF

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    xor rax, rax

    ; Загружаем адрес из ret_adress и кладем его на стек
    mov rax, ret_adress            ; Загрузка адреса из переменной ret_adress
    push qword rax                 ; Кладем адрес на стек

    ret

PrintFFF:
    push rbp
    mov rbp, rsp
    sub rsp, 16                     ; Резервируем место для локальных переменных
    xor r8, r8                      ; r8 = 0
    mov r9, 8                       ; r9 = 8

    PrintFLoop:
        mov rbx, [rbp + r8]         ; Используем относительное смещение от rbp
        add rbx, r8
        cmp byte [rbx], string_end  ; Указываем размер операции byte
        je PrintExit

        ; Действия для обработки текущего символа

    jmp PrintFLoop

PrintExit:
    leave
    ret

section .data
string_end equ 0x00
ret_adress: dq 0

DEFAULT REL                             ; устанавливаем относительное адресование
                                        ; относительное адресование - адреса данных рассчитываются
                                        ; относительно значения регистра индекса
section .text
    global _MyPrintf                    ; делаем метку _MyPrintf доступной извне текущего модуля
                                        ; и говорим компилятору, что _MyPrintf является глобальной меткой,
                                        ; которую можно использовать для обращения к функции
                                        ; или символу в других модулях программы

; =====================================================================
;                          _MyPrintf
; =====================================================================
; Основная функция вывода форматированной строки.
;
; Вход:
;        - Аргументы передаются через стек (кроме первых 6, они в rdi, rsi, rdx, rcx, r8, r9)
; Выход:
;        - Выводит отформатированную строку на стандартный вывод
;        - Возвращает управление в вызывающую функцию
; Изменения:
;        - Изменяет регистры rax, rdi, rsi, rcx, rdx, r8, r9, rbx, rbp
;        - Записывает результат в буфер и на стандартный вывод
;---------------------------------------------------------------------
_MyPrintf:
    pop rax                             ; cохраняем адрес возврата в rax и
    mov [rel ret_adress], rax           ; копируем его в переменную ret_adress

    push r9                             ; сохраняем регистры
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    call PrintFFF

    pop rdi                             ; восстанавливаем регистры
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    push rax
    mov rax, 0x2000004
    mov rdi, 1
    mov rdx, msg_len
    mov rsi, buffer
    syscall

    mov rdi, buffer                     ; загружаем адрес буфера в rdi
    mov rcx, 512                        ; загружаем размер буфера в rcx
    xor al, al                          ; oбнуляем al
    rep stosb                           ; заполняем буфер нулями

    pop rax                             ; rax = len
    push qword [rel ret_adress]         ; Восстанавливаем адрес возврата
    ret

; =====================================================================
;                          PrintFFF
; =====================================================================
; Функция преобразования форматной строки.
;
; Вход:
;        - Адрес строки формата передается через стек
; Выход:
;        - rax сохраняется длину преобразования форматной строки
; Побочные эффекты:
;        - Изменяет регистры rdi, rbx, rax, r8, r9
;---------------------------------------------------------------------
PrintFFF:
    mov rdi, qword [rsp + 8]            ; берем адрес rdi
    push rbp                            ; cохраняем адрес текущего базового указателя

    lea rbx, [rel buffer]               ; загружаем адрес буфера в rbx
                                        ; r9 - счетчик форматной строки
    mov r9, 16                          ; пропускаем в стеке адрес возврата и адрес текущего базового указателя
                                        ; в программе при взятии какого-то значения из стека
                                        ; r9 всегда сначала увеличивается на 8

    xor r8, r8                          ; r8 - счетчик для буфера

    PrintFLoop:
        xor rax, rax
        mov al, byte [rdi]              ; загружаем текущий символ из строки
        cmp al, string_end              ; сравниваем с символом конца строки
        je PrintExit                    ; если это конец строки, завершаем цикл

        cmp al, '%'                     ; if (symbol == '%') ---> jmp InputType
        je InputType

        mov byte [rbx + r8], al         ; копируем символ в буфер
        inc r8

        inc rdi                         ; переходим к следующему символу
        jmp PrintFLoop                  ; переходим к следующей итерации цикла

    PrintExit:
        pop rbp                         ; восстанавливаем базовый указатель

        mov rax, r8                     ; rax -  регистр, в который кладется возвращаемое значение из функции
        ret                             ; возвращает управление из текущей функции обратно в вызывающую ее функцию

; =====================================================================
;                          InputType
; =====================================================================
; Обработчик разных типов %?.
;
; Вход:
;        - Символ '%' (в rax)
; Выход:
;        - Переход к обработке соответствующего типа данных
; Побочные эффекты:
;        - Изменяет регистры rdi, rax, rdx
;---------------------------------------------------------------------
InputType:
    inc rdi                             ; увеличиваем адрес строки на 1 байт,
                                        ; тем самым сдвигаемся на следующий символ
    xor rax, rax                        ; rax = 0
    mov al, byte [rdi]                  ; al = символ

    cmp al, '%'                         ; if (symbol == '%') ---> jmp TypeSymbolProcent
    je TypeSymbolProcent

    sub rax, 'b'                        ; rax = rax - 'b'
    xor rdx, rdx                        ; rdx = 0

    mov rdx, JmpTable                   ; ъ
    imul rax, rax, 8                    ;  |
                                        ;  |  ---> rdx = [JmpTable + 8 * (symbol - 'b')]
    add rdx, rax                        ;  |
    jmp [rdx]                           ; /

;---------------------------------------------------------------------
TypeSymbolProcent:
    mov byte [rbx + r8], al             ; копируем символ в буфер
    inc r8                              ; увеличиваем указатель на буфер
    inc rdi                             ; переходим к следующему символу в форматной строке
    jmp PrintFLoop                      ; переходим к следующей итерации цикла
;---------------------------------------------------------------------

;---------------------------------------------------------------------
TypeString:
    add r9, 8
    mov rsi, qword [rsp + r9]           ; получаем адрес строки из аргументов

    PrintFLoopS:
        mov al, byte [rsi]
        cmp al, string_end              ; сравниваем с символом конца строки
        je AfterStringLoop

        mov byte [rbx + r8], al

        inc r8
        inc rsi

        jmp PrintFLoopS

AfterStringLoop:
    inc rdi
    jmp PrintFLoop
;---------------------------------------------------------------------

;---------------------------------------------------------------------
TypeInt:
    push r9
    add r9, 16
    mov rax, qword [rsp + r9]           ; получаем значение аргумента из стека

    xor rdx, rdx
    xor rcx, rcx
    mov r9, 10                          ; r9 = основание системы счисления
    cmp rax, 0
    jne check_negative                  ; eсли число не ноль, проверяем на отрицательность
    mov byte [rbx], '0'                 ; eсли число ноль, записываем символ '0' в буфер
    inc r8
    jmp AfterItoaLoop

check_negative:
    test rax, 80000000h                 ; проверяем знак числа
    jz itoa_loop                        ; если число положительное, начинаем преобразование

    ; если число отрицательное, переходим к метке number_is_negative

number_is_negative:
    neg eax                             ; изменяем знак числа на положительный
    mov byte [rbx + r8], '-'            ; записываем минус перед числом
    inc r8

itoa_loop:
    test rax, rax                       ; проверяем, не закончилось ли число
    jz BuffNumLoop                      ; если число равно нулю, завершаем

    inc rcx
    xor rdx, rdx
    div r9                              ; делим число на основание системы счисления
    push rdx                            ; cохраняем остаток на стеке
    jmp itoa_loop                       ; повторяем цикл

BuffNumLoop:
    pop rax                             ; извлекаем сохраненные остатки из стека
    add al, '0'
    mov byte [rbx + r8], al             ; копируем символ в буфер
    inc r8
    dec rcx
    jnz BuffNumLoop                     ; повторяем, пока не завершим все разряды

AfterItoaLoop:
    pop r9
    add r9, 8
    inc rdi
    jmp PrintFLoop
;---------------------------------------------------------------------
; Как происходит деление:
;       DIV R9 ----> RDX:RAX \ r9
;                       ^
;                       |
;                       |
;       (64-битный регистр засчет конкатенации)

;                    RDX:RAX \ r9
;                     ^   ^
;                    /    |
;                   /     |
;                  /      |
;                 /       |
;              остаток  частное
;---------------------------------------------------------------------
TypeHex:
    add r9, 8
    mov rax, qword [rsp + r9]

itoa_hex:
    xor rcx, rcx                        ; rcx - счетчик(разрядов)

    cmp rax, 0                          ; проверяем, не является ли число нулем
    jnz itoa_hex_loop                   ; если число не ноль --> преобразование

    ; преобразование числа 0
    mov byte [rbx], '0'                 ; записываем символ '0'
    inc rcx                             ; Увеличиваем счетчик
    jmp AfterLoop

itoa_hex_loop:
    test rax, rax                       ; проверяем, не закончилось ли число
    jz BuffHexLoop                      ; если число равно нулю, завершаем

    inc rcx
    mov rdx, rax                        ; сохраняем число в rdx для деления
    and rdx, 0xF                        ; получаем остаток от деления на 16
    push rdx                            ; сохраняем остаток на стеке
    shr rax, 4                          ; делим число на основание системы счисления
                                        ; (сдвиг вправо на 4 бита эквивалентен делению на 16)
    jmp itoa_hex_loop

BuffHexLoop:
    pop rdx                             ; извлекаем сохраненные остатки из стека
    movzx rax, dl                       ; помещаем остаток в rax
    add al, '0'
    cmp al, '9'
    jbe HexLoopCheck                    ; переходим на проверку диапазона '0' - '9'
    add al, 7h                          ; корректируем символы 'A' - 'F'
HexLoopCheck:
    mov byte [rbx + r8], al             ; копируем символ в буфер
    inc r8
    dec rcx
    jnz BuffHexLoop                     ; повторяем, пока не завершим все разряды

AfterLoop:
    inc rdi
    jmp PrintFLoop
;---------------------------------------------------------------------

;---------------------------------------------------------------------
TypeOct:
    add r9, 8
    mov rax, qword [rsp + r9]

itoa_oct:
    xor rcx, rcx

    cmp rax, 0                          ; проверяем, не является ли число нулем
    jnz itoa_oct_loop                   ; если число не ноль -> преобразование

    mov byte [rbx], '0'                 ; записываем символ '0'
    inc rcx                             ; увеличиваем счетчик
    jmp AfterLoop

itoa_oct_loop:
    test rax, rax                       ; проверяем, не закончилось ли число
    jz BuffOctLoop                      ; если число равно нулю, завершаем

    inc rcx
    mov rdx, rax                        ; cохраняем число в rdx для деления
    and rdx, 7                          ; получаем остаток от деления на 8
    push rdx                            ; сохраняем остаток на стеке
    shr rax, 3                          ; делим число на основание системы счисления
                                        ; (сдвиг вправо на 3 бита эквивалентен делению на 8)
    jmp itoa_oct_loop

BuffOctLoop:
    pop rdx                             ; извлекаем сохраненные остатки из стека
    add dl, '0'
    mov byte [rbx + r8], dl             ; копируем символ в буфер
    inc r8
    dec rcx
    jnz BuffOctLoop                     ; повторяем, пока не завершим все разряды
;---------------------------------------------------------------------

;---------------------------------------------------------------------
TypeBinary:
    add r9, 8
    mov rax, qword [rsp + r9]           ; получаем адрес строки из аргументов

itoa_binary:
    xor rdx, rdx
    xor rcx, rcx

    cmp rax, 0                          ; проверяем, не является ли число нулем
    jnz itoa_binary_loop                ; если число не ноль -> преобразование

    mov byte [rbx], '0'                 ; записываем символ '0'
    inc rcx                             ; увеличиваем счетчик
    jmp AfterLoop                       ; завершаем функцию

itoa_binary_loop:
    test rax, rax                       ; проверяем, не закончилось ли число
    jz BuffBinaryLoop                   ; если число равно нулю, завершаем

    inc rcx
    mov rdx, rax                        ; сохраняем число в rdx для деления
    and rdx, 1                          ; получаем остаток от деления на 2
    push rdx                            ; сохраняем остаток на стеке
    shr rax, 1                          ; делим число на 2
    jmp itoa_binary_loop

BuffBinaryLoop:
    pop rdx                             ; извлекаем сохраненные остатки из стека
    add dl, '0'
    mov byte [rbx + r8], dl             ; копируем символ в буфер
    inc r8
    dec rcx
    jnz BuffBinaryLoop                  ; повторяем, пока не завершим все разряды

AfterItoaBinaryLoop:
    inc rdi
    jmp PrintFLoop
;---------------------------------------------------------------------

;---------------------------------------------------------------------
TypeChar:
    add r9, 8
    mov rax, qword [rsp + r9]

    mov byte [rbx + r8], al             ; копируем символ в буфер

    inc r8
    inc rsi

    jmp AfterLoop
;---------------------------------------------------------------------

;---------------------------------------------------------------------
align 8
JmpTable:
    dw qword TypeBinary
    dw qword TypeChar
    dw qword TypeInt
    times 10 dq 'd'                        ; times -> используется для повторения определенного блока кода
    dw qword TypeOct
    times 3 dq 'e'
    dw qword TypeString
    times 4 dq 'd'
    dw qword TypeHex
;---------------------------------------------------------------------

;=====================================================================
;                         DATA
;=====================================================================
section .data
    string_end equ 0x00
    ret_adress dq 0
    buffer times 512 db 0
    msg_len equ $ - buffer

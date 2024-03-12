section .text
    global _MyPrintf

_MyPrintf:
    pop rax                                 ; Сохраняем адрес возврата в rax и
                                            ; копируем его в переменную ret_adress
    mov [rel ret_adress], rax
    xor rax, rax

    push r9                                 ; Сохраняем регистры
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    mov rdi, 0

    call PrintFFF                           ; Вызываем функцию печати

    pop rdi                                 ; Восстанавливаем регистры
    pop rsi
    pop rdx
    pop rcx
    pop r8
    pop r9

    mov rax, 0x2000004                      ; Системный вызов sys_write
    mov rdi, 1                              ; Файловый дескриптор stdout
    mov rdx, msg_len                        ; Длина сообщения
    mov rsi, buffer                         ; Адрес сообщения
    syscall                                 ; Вызов ядра

    ; xor rax, rax                            ; Очищаем регистр rax
    push qword [rel ret_adress]             ; Восстанавливаем адрес возврата и
                                            ; возвращаемся из функции
    ret

PrintFFF:
    mov rdi, qword [rsp + 8]               ; берем адрес rdi
    mov r9, 16                              ; пропускаем в стеке адрес возврата вызова функции и rdi
    push rbp                                ; Сохраняем адрес текущего базового указателя
    mov r8, 0

    lea rbx, [rel buffer]                   ; Загружаем адрес буфера в rbx

    PrintFLoop:                             ; Цикл для печати строки
        mov al, byte [rdi]                  ; Загружаем текущий символ из строки
        cmp al, string_end                  ; Сравниваем с символом конца строки
        je PrintExit                        ; Если это конец строки, завершаем цикл

        cmp al, '%'
        je InputType

        mov byte [rbx + r8], al             ; Копируем символ в буфер
        inc r8

        inc rdi                             ; Переходим к следующему символу
        jmp PrintFLoop                      ; Переходим к следующей итерации цикла

    PrintExit:                              ; Метка выхода из функци
                                            ; Освобождаем резервированное место на стеке и
                                            ; восстанавливаем базовый указатель
        call AddNewLine
        pop rbp
        mov rax, r8
        ret

InputType:
    inc rdi
    mov al, byte [rdi]
    cmp al, 's'
    je TypeString
    cmp al, 'd'
    je TypeInt
    cmp al, 'c'
    je TypeChar
    cmp al, '%'
    je TypeSymbolProcent
    cmp al, 'x'
    je TypeHex
    cmp al, 'o'
    je TypeOct
    cmp al, 'b'
    je TypeBinary

    jmp PrintFLoop

TypeSymbolProcent:
    mov byte [rbx + r8], al             ; Копируем символ в буфер

    inc r8

    jmp PrintFLoop               ; Переходим к следующей итерации цикла

TypeString:
    add r9, 8
    mov rsi, qword [rsp + r9]  ; Получаем адрес строки из аргументов

    PrintFLoopS:
        mov al, byte [rsi]
        cmp al, string_end                  ; Сравниваем с символом конца строки
        je AfterStringLoop

        mov byte [rbx + r8], al             ; Копируем символ в буфер

        inc r8
        inc rsi                             ; Переходим к следующему символу

        jmp PrintFLoopS               ; Переходим к следующей итерации цикла

AfterStringLoop:
    inc rdi
    jmp PrintFLoop                         ; Если это конец строки, завершаем цикл
                           ; Прыжок обратно к выполнению PrintFFF


TypeInt:
    push r9
    add r9, 16
    mov rax, qword [rsp + r9]  ; Получаем адрес строки из аргументов

itoa:
    xor rdx, rdx          ; Обнуляем rdx для деления
    xor rcx, rcx          ; Обнуляем rdi для счетчика
    mov r9, 10           ; Сохраняем основание системы счисления
    cmp rax, 0
    jne check_negative  ; Если число не ноль, проверяем на отрицательность
    mov byte [rbx], '0' ; Если число ноль, записываем символ '0' в буфер
    inc r8              ; Увеличиваем счетчик
    jmp AfterItoaLoop   ; Завершаем функцию

check_negative:
    test rax, 80000000h    ; Проверяем знак числа
    jz itoa_loop                  ; Если число положительное, начинаем преобразование

    ; Если число отрицательное, переходим к метке number_is_negative

number_is_negative:
    ; Обработка отрицательных чисел
    neg eax                         ; Изменяем знак числа на положительный
    mov byte [rbx + r8], '-'        ; Записываем минус перед числом
    inc r8                          ; Увеличиваем счетчик

itoa_loop:
    test rax, rax         ; Проверяем, не закончилось ли число
    jz BuffNumLoop        ; Если число равно нулю, завершаем

    inc rcx               ; Увеличиваем счетчик разрядов
    xor rdx, rdx          ; Обнуляем rdx для деления
    div r9                ; Делим число на основание системы счисления (mod в rdx, res в rax)
    push rdx              ; Сохраняем остаток на стеке
    jmp itoa_loop         ; Повторяем цикл

BuffNumLoop:
    pop rax              ; Извлекаем сохраненные остатки из стека
    add al, '0'
    mov byte [rbx + r8], al             ; Копируем символ в буфер
    inc r8
    dec rcx              ; Уменьшаем счетчик
    jnz BuffNumLoop      ; Повторяем, пока не завершим все разряды

AfterItoaLoop:
    pop r9
    add r9, 8
    inc rdi
    jmp PrintFLoop  ; Завершаем цикл

TypeHex:
    push r9
    add r9, 16
    mov rax, qword [rsp + r9]  ; Получаем адрес строки из аргументов

itoa_hex:
    xor rdx, rdx          ; Обнуляем rdx для деления
    xor rcx, rcx          ; Обнуляем rcx для счетчика
    mov r9, 16            ; Сохраняем основание системы счисления (16 для шестнадцатеричной системы)

    cmp rax, 0            ; Проверяем, не является ли число нулем
    jnz itoa_hex_loop     ; Если число не ноль, начинаем преобразование

    ; Преобразование числа 0
    mov byte [rbx], '0'  ; Записываем символ '0'
    inc rcx               ; Увеличиваем счетчик
    jmp AfterItoaHexLoop ; Завершаем функцию

itoa_hex_loop:
    test rax, rax         ; Проверяем, не закончилось ли число
    jz BuffHexLoop        ; Если число равно нулю, завершаем

    inc rcx               ; Увеличиваем счетчик разрядов
    xor rdx, rdx          ; Обнуляем rdx для деления
    div r9                ; Делим число на основание системы счисления (mod в rdx, res в rax)
    push rdx              ; Сохраняем остаток на стеке
    jmp itoa_hex_loop     ; Повторяем цикл

BuffHexLoop:
    pop rax               ; Извлекаем сохраненные остатки из стека
    add al, '0'
    cmp al, '9'
    jbe HexLoopCheck      ; Переходим на проверку диапазона '0' - '9'
    add al, 7h            ; Корректируем символы 'A' - 'F'
HexLoopCheck:
    mov byte [rbx + r8], al  ; Копируем символ в буфер
    inc r8
    dec rcx               ; Уменьшаем счетчик
    jnz BuffHexLoop       ; Повторяем, пока не завершим все разряды

AfterItoaHexLoop:
    pop r9
    add r9, 8
    inc rdi
    jmp PrintFLoop  ; Завершаем цикл

TypeOct:
    push r9
    add r9, 16
    mov rax, qword [rsp + r9]  ; Получаем адрес строки из аргументов

itoa_oct:
    xor rdx, rdx          ; Обнуляем rdx для деления
    xor rcx, rcx          ; Обнуляем rcx для счетчика
    mov r9, 8             ; Сохраняем основание системы счисления (8 для восьмеричной системы)

    cmp rax, 0            ; Проверяем, не является ли число нулем
    jnz itoa_oct_loop     ; Если число не ноль, начинаем преобразование

    ; Преобразование числа 0
    mov byte [rbx], '0'  ; Записываем символ '0'
    inc rcx               ; Увеличиваем счетчик
    jmp AfterItoaOctLoop ; Завершаем функцию

itoa_oct_loop:
    test rax, rax         ; Проверяем, не закончилось ли число
    jz BuffOctLoop        ; Если число равно нулю, завершаем

    inc rcx               ; Увеличиваем счетчик разрядов
    xor rdx, rdx          ; Обнуляем rdx для деления
    div r9                ; Делим число на основание системы счисления (mod в rdx, res в rax)
    push rdx              ; Сохраняем остаток на стеке
    jmp itoa_oct_loop     ; Повторяем цикл

BuffOctLoop:
    pop rax               ; Извлекаем сохраненные остатки из стека
    add al, '0'
    mov byte [rbx + r8], al  ; Копируем символ в буфер
    inc r8
    dec rcx               ; Уменьшаем счетчик
    jnz BuffOctLoop       ; Повторяем, пока не завершим все разряды

AfterItoaOctLoop:
    pop r9
    add r9, 8
    inc rdi
    jmp PrintFLoop  ; Завершаем цикл

TypeBinary:
    push r9
    add r9, 16
    mov rax, qword [rsp + r9]  ; Получаем адрес строки из аргументов

itoa_binary:
    xor rdx, rdx          ; Обнуляем rdx для деления
    xor rcx, rcx          ; Обнуляем rcx для счетчика
    mov r9, 2             ; Сохраняем основание системы счисления (2 для бинарной системы)

    cmp rax, 0            ; Проверяем, не является ли число нулем
    jnz itoa_binary_loop  ; Если число не ноль, начинаем преобразование

    ; Преобразование числа 0
    mov byte [rbx], '0'  ; Записываем символ '0'
    inc rcx               ; Увеличиваем счетчик
    jmp AfterItoaBinaryLoop  ; Завершаем функцию

itoa_binary_loop:
    test rax, rax         ; Проверяем, не закончилось ли число
    jz BuffBinaryLoop     ; Если число равно нулю, завершаем

    inc rcx               ; Увеличиваем счетчик разрядов
    xor rdx, rdx          ; Обнуляем rdx для деления
    div r9                ; Делим число на основание системы счисления (mod в rdx, res в rax)
    push rdx              ; Сохраняем остаток на стеке
    jmp itoa_binary_loop  ; Повторяем цикл

BuffBinaryLoop:
    pop rax               ; Извлекаем сохраненные остатки из стека
    add al, '0'
    mov byte [rbx + r8], al  ; Копируем символ в буфер
    inc r8
    dec rcx               ; Уменьшаем счетчик
    jnz BuffBinaryLoop    ; Повторяем, пока не завершим все разряды

AfterItoaBinaryLoop:
    pop r9
    add r9, 8
    inc rdi
    jmp PrintFLoop  ; Завершаем цикл

TypeChar:
    add r9, 8
    mov rax, qword [rsp + r9]  ; Получаем адрес строки из аргументов

    mov byte [rbx + r8], al             ; Копируем символ в буфер

    inc r8
    inc rsi                             ; Переходим к следующему символу

    jmp AfterItoaLoop              ; Переходим к следующей итерации цикла

AddNewLine:
    mov byte [rbx + r8], 10                 ; добавляем символ новой строки (LF)
    inc r8
    ret

section .data
string_end equ 0x00
ret_adress dq 0
buffer_pointer dq 0
num_buffer times 256 db 0            ; Буфер для числа
buffer times 512 db 0
msg_len equ $ - buffer

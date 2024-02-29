.model tiny
.code
.286
org 100h

;=====================================================================
;                         CONST
;=====================================================================
LENGTH            equ 19d
HEIGHT            equ 1d
NEXT_LINE         equ 118d
LINE              equ 160d

COLOR_CORRECT     equ 02h
COLOR_INCORRECT   equ 04h
COLOR_ATTRIBUTE   equ 01h
;---------------------------------------------------------------------

Start:
    mov ah, 09h                         ; функция 09h - вывод строки
    lea dx, prompt                      ; загружаем адрес строки в dx
    int 21h                             ; вызываем прерывание 21h для вывода строки

    mov ah, 0Ah                         ; функция 0Ah - ввод строки
    mov dx, offset message              ; загружаем адрес буфера для хранения ввода
    int 21h                             ; вызываем прерывание 21h для ввода строки

    call CheckPassword                  ; функция, которая сравнивает буффер из ввода и пароль
    cmp ax, 0                           ; 0 - если совпали
    jne PrintErr                        ; если не 0 (то есть не совпали),
                                        ; то прыжок на метку вывода некорректного пароля

PrintCor:
    call PrintFrame                     ; вызов функии рисования рамки

    mov si, offset correct_input + 1    ; кладем в регистр начало строки (+1, потому что скипаем \n)
    mov dl, COLOR_CORRECT               ; устанавливаем цвет для текста о правильном пароле
    call PrintText                      ; функия рисования значения строки

    mov ah, 09h                         ; Функция 09h - вывод строки
    mov dx, offset correct_input        ; Загружаем адрес строки в dx
    int 21h                             ; Вызываем прерывание 21h для вывода строки

    jmp EndF

PrintErr:
    call PrintFrame                     ; вызов функии рисования рамки

    mov si, offset error_input + 1      ; кладем в регистр начало строки (+1, потому что скипаем \n)
    mov dl, COLOR_INCORRECT             ; устанавливаем цвет для текста о неправильном пароле
    call PrintText                      ; функия рисования значения строки

    mov ah, 09h                         ; Функция 09h - вывод строки
    mov dx, offset error_input          ; Загружаем адрес строки в dx
    int 21h                             ; Вызываем прерывание 21h для вывода строки

EndF:
    mov ax, 4c00h                       ; завершение программы
    int 21h

;=====================================================================
;                         CheckPassword
;=====================================================================
; CheckPassword - a procedure to check if two strings of characters are equal.
; Entry:
;       None
; Exit:
;       AX - 0 if strings are equal, 1 if not equal
; Destr:
;       BX, BP, DX, AL, CX
;--------------------------------------------------------------------
CheckPassword proc
    mov bx, offset message + 2      ; загружаем адрес первой строки
                                    ;(+2, потому что в первых двух байтах лежит max(size) и len)
    mov bp, offset cor_pass         ; загружаем адрес второй строки

    xor dx, dx                      ; dx = 0
    mov dl, 50d                     ; dl = 50
    mov cx, 5                       ; cx = 5
    DecryptPassword:
        mov al, [bp]                ; al = iый символ строки
        add al, dl                  ; прибавляем к значению первого сивола dl
        mov [bp], al                ; загружаем новый символ в строку
        inc bp                      ; bp++ (смещение по строке)
        inc dl                      ; dl++
        loop DecryptPassword        ; цикл

    mov bp, offset cor_pass         ; загружаем адрес второй строки

    mov cx, 4                       ; cx = 4
compare_strings:
    mov al, [bx]                    ; загружаем символ из первой строки в al
    call ReturSymbolKey             ; функция, которая возвращает значение символа
    mov dx, ax

    mov al, [bp]                    ; загружаем символ из второй строки в al
    call ReturSymbolKey

    cmp al, dl                      ; сравниваем возвращенное значение символов
    jne not_equal                   ; если они разные, то прыгаем на метку not_equal

    cmp cx, 0                       ; проверяем конец строки
    je strings_equal                ; если конец, то возвращаем success

    inc bx                          ; bp++ (смещение по строке)
    inc bp                          ; dl++ (смещение по строке)
    dec cx                          ; cx--;

    jmp compare_strings             ; повтор проверки символов

not_equal:                          ; если не совпадают сиволы, то возвращаем 1
    mov ax, 1
    jmp endCheck                    ; прыжок на конец программы

strings_equal:
    mov ax, 0                       ; если совпадают символы, то возвращаем 0
    jmp endCheck                    ; прыжок на конец программы

endCheck:
    ret
    endp

;=====================================================================
;                         ReturSymbolKey
;=====================================================================
; ReturSymbolKey - a function that returns a value corresponding to the ASCII character.
;
; Entry:
;       AL - the character to be analyzed
; Exit:
;       AX - the returned value
; Destr:
;        - AX, DX
;---------------------------------------------------------------------
ReturSymbolKey proc
    push dx                         ; Сохраняем значение регистра DX на стеке
    mov dx, '0'                     ; Загружаем значение '0' в регистр DX
    cmp al, dl                      ; Сравниваем значение в регистре AL с '0'
    jl not_digit                    ; Если значение в AL меньше '0', переходим к not_digit

    mov dx, '9'                     ; Загружаем значение '9' в регистр DX
    cmp al, dl                      ; Сравниваем значение в регистре AL с '9'
    jg not_digit                    ; Если значение в AL больше '9', переходим к not_digit

    mov ax, 1                       ; Если значение в AL находится в диапазоне '0'-'9', возвращаем 1
    jmp endQ                        ; Переходим к концу функции

;---------------------------------------------------------------------
not_digit:
    mov dx, 'a'
    cmp al, dl
    jl consonant

    mov dx, 'c'
    cmp al, dl
    jl SymbolAC

    mov dx, 'f'
    cmp al, dl
    jl SymbolDF

    mov dx, 'i'
    cmp al, dl
    jl SymbolGI

    mov dx, 'l'
    cmp al, dl
    jl SymbolJL

    mov dx, 'o'
    cmp al, dl
    jl SymbolMO

    mov dx, 'r'
    cmp al, dl
    jl SymbolPR

    mov dx, 'u'
    cmp al, dl
    jl SymbolSU

    mov ax, 10
    jmp endQ

;---------------------------------------------------------------------
SymbolAC:
    mov ax, 4                       ; if 'a' <= symbol <= 'b' return 4
    jmp endQ
SymbolDF:
    mov ax, 5                       ; if 'c' <= symbol <= 'e' return 5
    jmp endQ
SymbolGI:
    mov ax, 6                       ; if 'f' <= symbol <= 'h' return 6
    jmp endQ
SymbolJL:
    mov ax, 7                       ; if 'i' <= symbol <= 'k' return 7
    jmp endQ
SymbolMO:
    mov ax, 8                       ; if 'l' <= symbol <= 'n' return 8
    jmp endQ
SymbolPR:
    mov ax, 9                       ; if 'o' <= symbol <= 'p' return 9
    jmp endQ
SymbolSU:
    mov ax, 11                      ; if 'r' <= symbol <= 't' return 11
    jmp endQ
;---------------------------------------------------------------------

consonant:
    mov ax, 3                       ; если цифра или какой-то другой символ, то возвращаем 3
    jmp endQ

endQ:
    pop dx                          ; возвращаем значение регистра dx
    ret
    endp

; =====================================================================
;                          PrintFrame
; =====================================================================
; Draws a frame on the screen using a specified style and color.
;
; Entry:
;        - SI: Pointer to the style of the frame
;        - AH: Color of the frame
; Exit:
;        - No explicit exit values, returns to the calling function
; Destr:
;        - AX, CX, DI, ES, SI, DS
;---------------------------------------------------------------------
PrintFrame proc
    push 0b800h                     ; 0b800h - видеопамять
	pop es                          ; устанавливаем сегмент - видеопамять

    mov si, offset Style            ; стиль рамки
    mov ah, COLOR_ATTRIBUTE
    push cs                         ; cs может быть испорчен, поэтому сохрнаяем его в ds
    pop ds                          ; ds также data segment

    cld                             ; сброса флага направления
                                    ; что при использовании инструкций для работы со строками,
                                    ; индексы или адреса будут увеличиваться,
                                    ; что соответствует прямому (положительному) направлению в памяти.

    mov di, (160 * 20 + 30 * 2)     ; позиция рисования рамки

    mov cx, LENGTH                  ; счетчик = длина
    call DrawLine                   ; рисуем линию

    add di, NEXT_LINE               ; переход на следующую строку

    mov cx, HEIGHT                  ; выставляем длину

;------------------------------------------------
body:
    push cx                         ; сохраняем счетчик высоты рамки

    mov cx, LENGTH                  ; счетчик = длина
    call DrawLine                   ; рисуем рамку

    pop cx                          ; возвращаем счетчик высоты рамки
    sub si, 3                       ; возвращаемся к тем же символам для рамки

    add di, NEXT_LINE               ; переходим к следующей линии
    loop body                       ; повторяем цикл
;-------------------------------------------------

    add si, 3d                      ; переходим к завершающим 3 символам рамки

    mov cx, LENGTH                  ; счетчик = длина
    call DrawLine                   ; рисуем нижнюю линию рамки

    ret                             ; эффективно завершаем выполнение процедуры
                                    ; и возвращаемся к основной программе или к коду,
                                    ; который вызвал данную подпрограмму.
    endp

; =====================================================================
;                          PrintText
; =====================================================================
; Draws a LINE on the screen using characters from a string.
;
; Entry:
;       DI - Destination pointer to screen memory
;       SI - Source pointer to string containing characters to be drawn
;       CX - Counter indicating the number of characters to draw
; Exit:
;       - No explicit exit values
; Destr:
; - AX, CX, DI
;---------------------------------------------------------------------
PrintText proc
    push 0b800h                    ; 0b800h - видеопамять
	pop es

    mov di, 160 * 21 + 32 * 2
    mov cx, 17d

print_loop:
    lodsb                          ; Загрузка символа из строки в AL
    cmp cx, 0                      ; Проверяем, не является ли символ концом строки
    jz end_print                   ; Если символ нулевой, значит, строка закончилась

    call DrawSymbol                ; Вызов функции DrawSymbol для вывода символа

    dec cx
    jmp print_loop                 ; Повторяем цикл для следующего символа

end_print:
    ret                            ; эффективно завершаем выполнение процедуры
                                   ; и возвращаемся к основной программе или к коду,
                                    ; который вызвал данную подпрограмму.
    endp
; =====================================================================
;                          DrawLine
; =====================================================================
; Draws a LINE on the screen using characters from a string.
;
; Entry:
;        DI, SI, CX
; Exit:
;        - No explicit exit values, returns to the calling function
; Destr:
;        - AX, CX, DI
;---------------------------------------------------------------------

DrawLine proc
    lodsb                         ; получаем первый строковый символ
    stosw                         ; один символ

    lodsb                         ; получаем второй строковый символ
    rep stosw                     ; много символов

    lodsb                         ; получаем второй строковый символ
    stosw                         ; один символ

	ret
	endp

; =====================================================================
;                     DrawSymbol
; =====================================================================
; Draws a symbol for registers.
;
; Entry:
;        - AL: Symbol to draw
;        - DL: Color attribute
; Exit:
;        - No explicit exit values, returns to the calling function
; Side Effects:
;        - Modifies AL
;---------------------------------------------------------------------
DrawSymbol proc

    stosb                       ; Записать символ в память видеобуфера
    mov al, dl                  ; цвет
    stosb                       ; Записать атрибут цвета в память видеобуфера

    ret
    endp

;---------------------------------------------------------------------

Style	  db 0c9h, 0cdh, 0bbh, 0bah, ' ', 0bah, 0c8h, 0cdh, 0bch

prompt        db "Enter the string: $"
correct_input db 0ah, "Password received $"
error_input   db 0ah, "Password is wrong $"
aaaaa         db 0ah, "$"
message       db '0000000$'
cor_pass      db '12345$'

end Start

;; sefic ----> 12345
;; sefic?12345 ---> WIN



.286
.model tiny
.code

org 100h

;=====================================================================
;                         CONST
;=====================================================================
CNT_REGISTER      equ 13d
LENGTH            equ 10d
HEIGHT            equ 13d
NEXT_LINE         equ 136d
LINE              equ 160d
NEXT_LINE_FOR_REG equ 142d

COLOR_FOR_FRAME   equ 04h
COLOR_FOR_REG     equ 0ch
;---------------------------------------------------------------------
; es - регистр, отвечающий за сегмент
; cs - определяет местоположение части памяти, содержащей программу
;---------------------------------------------------------------------

Start:
     cli                           ; запрещаем прерывания
     mov ax, 3509h                 ; 35 функция 21 прерывания - передаем ей в al 9 (level клавиатуры)
     int 21h                       ; 21 занимается тем, что возвращает /ES/:/BX/ of IRQ + 8
                                   ; IRQ - это сигнал, посылаемый процессору компьютера для мгновенной остановки (прерывания) его операций.
                                   ; IRQ - иерархия прерываний

                                   ; так как мы делаем свое прерывание, то нужно сохранить оригинальный обработчик,
                                   ; чтобы обработка клавиш происходила корректно
                                   ; оригинальный обработчик: сканирует код и отправляет в буффер и
                                   ; дальше он как-то обрабатывается (в зависимости от скан кода)
     mov Old090fs, bx
     mov bx, es
     mov Old09Seg, bx              ; сохраняем смещение и сегмент в переменные

     push 0
     pop es                        ; сегмент = 0( смотрим нулевой сегмент)

     mov bx, 9 * 4                 ; кладем адрес вектора прерывания number 0f IRQ + 8

     mov es:[bx], offset Int09     ; кладем адрес нашей функции (es - 0 сегмент (выше es = 0), :[bx] - это в 0 сегменте смещение bx)

     push cs                       ; cs - сегмент кода
     pop ax                        ; ax = сs (старый сегмент)

     mov es:[bx + 2], ax           ; положили сегмент (выше клали смещение)
     sti                           ; разрешаем прерывания

     cli                           ; запрещаем прерывания
     mov ax, 3508h
     int 21h                       ; возвращает /ES/:/BX/ 8

     mov Old080fs, bx
     mov bx, es
     mov Old08Seg, bx              ; сохраняем смещение и сегмент

     push 0
     pop es                        ; в таблице адресов функции сейчас 0

     mov bx, 8 * 4                 ; кладем адрес вектора прерывания number 8

     mov es:[bx], offset Int08     ; кладем адрес нашей функции

     push cs
     pop ax                        ; ax = старый сегмент

     mov es:[bx + 2], ax           ; положили сегмент (выше клали смещение)
     sti                           ; разрешаем прерывания

     mov ax, 3100h                 ; 31 функция 21 прерывания (выйти и остаться в памяти и
                                   ; как аргумент функции сохранить кол-во параграфов, которые нельзя засорять)

     mov dx, offset EOP            ; адрес конца программы
     shr dx, 4                     ; находим количество параграфов
     inc dx                        ; добавляем 1 навсякий

     int 21h                       ; сохраняем в памяти начиная с cs

;=====================================================================
;                          Int09
; =====================================================================
; Handles interrupt 09 for keyboard hotkey processing.
;
; Entry:
;        - None
; Exit:
;        - No explicit exit values, returns to the calling function
; Side Effects:
;        - Modifies AX
;---------------------------------------------------------------------

Int09    proc
     push ax                       ; сохраняем ax

     in al, 60h                    ; считываем значение с клавиатуры

     cmp al, 11d                   ; сравниваем с горячей клавиша
     jne NotHotKey                 ; прыгаем, если не горячая клавиша

IsHotKey:
     mov cs:KEY, 1                 ; кладем значение ключа 1 (то есть горячая клавиша нажалась)

     in al, 61h                    ; статус клавиатуры
     or al, 80h                    ; al or 1000 0000 (выставляем старший бит)
     out 61h, al                   ; кладем в состояние клавиатуры

     and al, not 80h               ; al and 0111 1111 (выставляем 0 в старшем бите)
     out 61h, al                   ; кладем в состояние клавиатуры
                                   ; делает мигание, чтобы клавиатура продолжила работу и передавала дальше сканКоды

     mov al, 20h                   ; говорим PPI, что наше прерывание окончено
     out 20h, al                   ; чтобы другие прерывания могли воспроизводиться
                                   ; PPI = ПРОГРАММИРУЕМЫЙ ПЕРИФЕРИЙНЫЙ ИНТЕРФЕЙС

     pop ax                        ; возвращаем значение ax

     iret                          ; выход из прерывания, при котором выпапливаются флаги

NotHotKey:
     pop ax                        ; возвращаем значение ax и ничего не делаем

     db          0Eah              ; напрямую в память кладем 0Eah (код лог джампа)
Old090fs    dw 0                   ; а за лог джампоп идет сегмент и смещение, куда прыгаем
Old09Seg    dw 0                   ; jmp on Old090Seg:Old090fs

            endp

; =====================================================================
;                          Int08
; =====================================================================
; Handles interrupt 08 for specific key processing.
;
; Entry:
;        - None
; Exit:
;        - No explicit exit values, returns to the calling function
; Side Effects:
;        - SP (все регистры сохраняются)
;        - Calls the PrintFrame and DrawRegister subroutines
;---------------------------------------------------------------------

Int08       proc
     cmp cs:KEY, 1                 ; если была зажата горячая клавиша, то выполняем действия ниже
                                   ; иначе скипаем
     jne NotKey

     push ss es ds sp bp di si dx cx bx ax
     mov bp, sp

     push 0b800h                   ; 0b800h - видеопамять
	pop es                        ; устанавливаем сегмент - видеопамять

     push cs                       ; cs может быть испорчен, поэтому сохрнаяем его в ds
     pop ds                        ; ds также data segment

     call PrintFrame               ; рисование рамки
     call DrawRegister             ; вывод регистров

     pop ax bx cx dx si di bp sp ds es ss

NotKey:

     db          0Eah                   ; напрямую в память кладем 0Eah (код лог джампа)
Old080fs    dw 0                   ; а за лог джампоп идет сегмент и смещение, куда прыгаем
Old08Seg    dw 0                   ; jmp on Old090Seg:Old090fs

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
; Side Effects:
;        - Modifies DI, CX, SI
;        - Calls the DrawLine subroutine
;---------------------------------------------------------------------
PrintFrame proc
     mov si, offset Style          ; стиль рамки
     mov ah, COLOR_FOR_FRAME       ; цвет

     cld                           ; сброса флага направления
                                   ; что при использовании инструкций для работы со строками,
                                   ; индексы или адреса будут увеличиваться,
                                   ; что соответствует прямому (положительному) направлению в памяти.

     mov di, 0                     ; позиция рисования рамки

     mov cx, LENGTH                ; счетчик = длина
     call DrawLine                 ; рисуем линию

     add di, NEXT_LINE             ; переход на следующую строку

     mov cx, HEIGHT                ; выставляем длину

;------------------------------------------------
body:
     push cx                       ; сохраняем счетчик высоты рамки

     mov cx, LENGTH                ; счетчик = длина
     call DrawLine                 ; рисуем рамку

     pop cx                        ; возвращаем счетчик высоты рамки
     sub si, 3                     ; возвращаемся к тем же символам для рамки

     add di, NEXT_LINE             ; переходим к следующей линии
     loop body                     ; повторяем цикл
;-------------------------------------------------

     add si, 3d                    ; переходим к завершающим 3 символам рамки

     mov cx, LENGTH                ; счетчик = длина
     call DrawLine                 ; рисуем нижнюю линию рамки

     ret                           ; эффективно завершаем выполнение процедуры
                                   ; и возвращаемся к основной программе или к коду,
                                   ; который вызвал данную подпрограмму.
     endp

; =====================================================================
;                          DrawLine
; =====================================================================
; Draws a LINE on the screen using characters from a string.
;
; Entry:
;        - DI: Address of the first byte of the position
;        - SI: Address of the string of symbols
;        - CX: LENGTH of the string (excluding start and end symbols)
;
; Exit:
;        - No explicit exit values, returns to the calling function
;
; Side Effects:
;        - Modifies DI
;        - Reads characters from the SI string
;        - Writes characters to the screen memory at DI
;
; Destr:
;        - AX, CX, DI
;---------------------------------------------------------------------

DrawLine proc
     lodsb                         ; GET FIRST STRING SYMBOL
     stosw                         ; PLACE LINE'S START

     lodsb                         ; GET SECOND STRING SYMBOL
     rep stosw                     ; PLACE LINE'S BODY

     lodsb                         ; GET LAST STRING SYMBOL
     stosw                         ; PLACE LINE'S ENDING

	ret
	endp


; =====================================================================
;                          DrawRegister
; =====================================================================
; Draws the register values on the screen.
;
; Entry:  - No explicit entry parameters, assumes values on the stack
;             - si: offset to the RegText string
;             - cx: number of registers to draw
;             - bp: stack pointer
;
; Exit:   No explicit exit values, returns to the calling function
;
; Side Effects:
;        - Modifies di, dl
;        - Calls DrawLineRegister for each register
;        - Assumes DrawLineRegister properly updates di and dl
;
; Destr:  AX, CX, DI
;---------------------------------------------------------------------
DrawRegister proc
                                   ; SI - используется для работы с источниками данных
     mov si, offset RegText        ; в операциях копирования и обработки строк
     mov cx, CNT_REGISTER          ; количество регистров

     mov di, LINE + 2              ; смещаемся на следующую строку и на один вправо, чтобы рисовать после символа рамки
     mov dl, COLOR_FOR_REG

     printRegLoop:                 ; цикл рисования регистро
          call DrawLineRegister    ; рисуем регистр
          add di, NEXT_LINE_FOR_REG  ; переходим к следующей строке для рисования след. регистра
          loop printRegLoop        ; возвращение к циклу

     ret
     endp

; =====================================================================
;                        DrawLineRegister
; =====================================================================
; Draws a LINE for register values, including the register symbol,
; hexadecimal value, and delimiter ':'.
;
; Entry:
;        - DS:SI points to the register symbol
;        - BP points to the value of the register
; Exit:
;        - No explicit exit values, returns to the calling function
; Side Effects:
;        - Modifies AX, BL
;        - Calls the DrawSymbol and DrawValueReg subroutines
;---------------------------------------------------------------------
DrawLineRegister proc
     push ax                            ; сохраняем значения регистров ax, bx
     push bx

     mov al, ' '                        ; печатаем пробел
     call DrawSymbol

     lodsb                              ; байт данных из памяти по адресу, который указан в регистре `SI`, в регистр `AL`.
     call DrawSymbol                    ; печатаем первую букву регистра

     lodsb                              ; байт данных из памяти по адресу, который указан в регистре `SI`, в регистр `AL`.
     call DrawSymbol                    ; печатаем вторую букву регистра

     mov al, ':'
     call DrawSymbol                    ; печатаем ':'

     mov al, ' '
     call DrawSymbol                    ; печатаем пробел

     mov ax, [bp]                       ; берем из стека значение

     mov bl, al                         ; кладет младшие цифры значения
     mov al, ah                         ; al = ah

     call DrawValueReg                  ; печатаем страшие цифры

     mov al, bl
     call DrawValueReg                  ; печатаем младшие цифры

     inc bp                             ; bp = bp - 2 (столько места занимает регистр)
     inc bp

     pop bx                             ; возвращаем старые значения регистров AX, BX
     pop ax

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

     stosb               ; Записать символ в память видеобуфера
     mov al, dl          ; цвет
     stosb               ; Записать атрибут цвета в память видеобуфера

     ret
     endp

; =====================================================================
;                     DrawValueReg
; =====================================================================
; Draws the value of a register as a hexadecimal number.
;
; Entry:
;        - AL: Register value (byte)
;        - DL: Color attribute
; Exit:
;        - No explicit exit values, returns to the calling function
; Side Effects:
;        - Modifies AL, AH, BX, CL
;---------------------------------------------------------------------
DrawValueReg  proc

     push ax                  ; сохраняем ax, bx, cx, потому что в этой функции они будут изменены
     push bx
     push cx

     xor ah, ah               ; ah = 0
     mov cl, al               ; сохраняем al

     and al, 11110000b        ; маска страших цифр

     rol al, 4                ; смешение на 4 вправо

     mov bx, offset HexAlphabet

     add bx, ax               ; находим нужную цифру

     mov al, [bx]             ; печатаем страший символ
     stosb                    ; Записать символ в память видеобуфера

     mov al, dl               ; цвет
     stosb                    ; Записать цвет в память видеобуфера

     mov al, cl
     and al, 00001111b        ; маска для младщих символов

     mov bx, offset HexAlphabet
     add bx, ax               ; находим нужную цифру

     mov al, [bx]             ; печатаем младшие символы
     stosb                    ; Записать символ в память видеобуфера

     mov al, dl               ; цвет
     stosb                    ; Записать символ в память видеобуфера

     pop cx
     pop bx
     pop ax                   ; возвращаем старые значения регистров


     ret
     endp

Style	  db 003h, 003h, 003h, 003h, ' ', 003h, 003h, 003h, 003h
RegText     db 'axbxcxdxsidibpspdsesssipcs'
HexAlphabet db '0123456789abcdef'

KEY         db 0                   ; переменная флага горячей клавиши

EOP:

end Start

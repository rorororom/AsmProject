.286
.model tiny
.code
org 100h

VMEM = 0b800h

Start:      push 0
            pop es
            mov bx, 9 * 4                   ; Вычисляет смещение для вектора прерываний 9 и сохраняет его в регистре BX

            cli                             ; Очищает флаг прерываний, отключая прерывания
            mov es:[bx], offset New09       ; Сохраняет смещение обработчика прерываний New09 в таблице векторов прерываний

            push cs
            pop ax

            mov es:[bx + 2], ax             ; Сохраняет сегмент текущего кода в таблице векторов прерываний
            sti                             ; Устанавливает флаг прерываний, разрешая прерывания

            mov ax, 3100h                   ; Загружает регистр AH значением 31h (функция BIOS для установки вектора прерывания)
            mov dx, offset EOP
            shr dx, 4                       ; Сдвигает значение DX вправо на 4 бита, делит его на 16
            inc dx

            int 21h

New09       proc
            push ax bx es
            push VMEM                       ; Помещаем адрес видеопамяти в стек
            pop es                          ; es = video memory

            mov bx, (80 * 5 + 40) * 2       ; screen offset (смещение по экрану)
            mov ah, 4eh                     ; put color

            in al, 60h                      ; считывает байт данных из порта ввода-вывода 60h и
                                            ;загружает его в регистр AL. В скан-кодах клавиатуры
                                            ;содержится информация о нажатых клавишах.Трио Рон, Гарри и Гермиона попало в очередную западню. Для открытия двери им нужно осветить все

            mov es:[bx], ax                 ; Записываем скан-код клавиши в память по адресу, соответствующему выбранному смещению
            in al, 61h                      ; Считываем состояние порта 61h, который используется для управления звуком и клавишей
            or al, 80h
            out 61h, al

            and al, not 80h
            out 61h, al

            mov al, 20h                     ; Загружаем значение 20h (32d) в регистр AL
            out 20h, al                     ; Отправляем сигнал контроллеру прерываний PIC, указывая, что прерывание обработано
            pop es bx ax
            iret
            endp
EOP:

end         Start

;Start:
            ;push 0b800h
            ;pop es                          ; es = video memory

            ;mov bx, (80 * 5 + 40) * 2       ; screen offset (смещение по экрану)
            ;mov ah, 4eh                     ; put color

;Next:       in al, 60h                      ; считывает байт данных из порта ввода-вывода 60h и
                                            ;загружает его в регистр AL. В скан-кодах клавиатуры
                                            ;содержится информация о нажатых клавишах.
            ;mov es:[bx], ax                 ; записываем данные в память по адресу

            ;cmp al, 11d                     ; код для прерывания
            ;jne Next                        ; если это не '0', то продолжаем работу программы

            ;ret

;end Start

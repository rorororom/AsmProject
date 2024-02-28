.286
.model tiny
.code
org 100h


Start:
            push 0b800h
            pop es                          ; es = video memory

            mov bx, (80 * 5 + 40) * 2       ; screen offset (смещение по экрану)
            mov ah, 4eh                     ; put color

Next:       in al, 60h                      ; считывает байт данных из порта ввода-вывода 60h и
                                            ;загружает его в регистр AL. В скан-кодах клавиатуры
                                            ;содержится информация о нажатых клавишах.
            mov es:[bx], ax                 ; записываем данные в память по адресу

            cmp al, 11d                     ; код для прерывания
            jne Next                        ; если это не '0', то продолжаем работу программы

            ret

end Start

.286
.model tiny
.code
org 100h

VMEM = 0b800h

Start:      mov ax, 3509h
            int 21h
            mov Old090fs, bx
            mov bx, es
            mov Old09Seg, bx

            push 0
            pop es
            mov bx, 9 * 4

            cli
            mov es:[bx], offset New09

            push cs
            pop ax

            mov es:[bx + 2], ax
            sti

            mov ax, 3100h
            mov dx, offset EOP
            shr dx, 4
            inc dx

            int 21h

New09       proc
            push ax bx es

            push VMEM
            pop es
            mov bx, cs:PrintOfs
            mov ah, 4eh

            in al, 60h

            mov es:[bx], ax

            add bx, 2
            and bx, 00FFh
            mov cs:PrintOfs, bx

            pop es bx ax

db    0EAh

Old090fs  dw 0
Old09Seg  dw 0

Next:
            iret
PrintOfs    dw (80 * 10 + 40) * 2
            endp

EOP:

end         Start

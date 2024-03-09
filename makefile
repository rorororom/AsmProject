#        -g создает отладочные символы
#           -O0 нужен чтобы компилятор не выкобенивался
FLAGS	=-g -O0
# имя исполняемого файла
NAME    =app
OBJS    =main.o myPrintf.o
CC		=clang
AS		=nasm
AFLAGS  =-f macho64

${NAME}: ${OBJS} main.c myPrintf.s
	${CC} ${FLAGS} ${OBJS} -o ${NAME}

main.o: main.c
#                  -c позволяет получить просто объектник
	${CC} ${FLAGS} -c main.c

myPrintf.o: myPrintf.s
	${AS} ${FLAGS} ${AFLAGS} myPrintf.s

clean:
	rm -f ${OBJS} ${NAME}

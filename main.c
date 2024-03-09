#include <stdio.h>

int MyPrintf (char* s, ...);

int main() {
    MyPrintf ("I %s %x %d %% %c\n", "love", 1, 1, 1);
    return 0;
}

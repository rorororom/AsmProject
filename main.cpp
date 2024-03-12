#include <stdio.h>

extern "C" int MyPrintf (char* s, ...);

int main() {
    int len = MyPrintf("I %x %o %d %b", 345, 345, -345, 345);
    printf("len = %d\n", len);
    // MyPrintf("I %s %s %s", "asd", "asdsg", "qwert");
    // MyPrintf("I %d", -5);
    return 0;
}

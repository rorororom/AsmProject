#include <stdio.h>
#include <stdint.h>

extern "C" int MyPrintf (char* s, ...);

int main() {
    // int len = MyPrintf("I %x %o %o %d %x %b %b", 345, 345, 346, -345, 346, 127, 128);
    // printf("\n");
//     printf("len = %d\n", len);
//     // MyPrintf("\t I %s %s %s\n", "asd", "asdsg", "qwert");
//
//     len = MyPrintf("qqqqqqqq %d", 5);
//     printf("\n");
//     printf("len = %d\n", len);
    // printf("lol%clol\n", 55);

    long long c = 4;
    int len = MyPrintf("%d %s %x %d%%%c%b\n", -1, "love", 3802, 100, 33, 127, UINT64_MAX);;
    printf("len = %d\n", len);

    // int len = MyPrintf("%b \n", 127);
    // printf("len = %d\n", len);
    return 0;
}

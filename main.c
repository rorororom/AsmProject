#include <stdio.h>

extern int SubFunc(int a, int b);

void print(int x) {
    printf("x is %d\n", x);
}

int main() {
    printf("\n>>> main(): start\n\n");

    int a = 85, b = 14;

    int c = SubFunc(a, b);

    printf("main(): %d - %d = %d\n", a, b, c);

    printf("\n<<< main(): end\n\n");
    return 0;
}

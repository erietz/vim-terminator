#include "stdio.h"

int main() {
    for (int i=0; i<10; i++) {
        printf("hello from c %d\n", i);
    }

    printf("line that doesn't end in a newline character");

    return 0;
}

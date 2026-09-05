/* Host-only OpenSSH acceptance helper. Matches the explicit Recovery login. */
#include <stdio.h>
int main(void) { return fputs("rosebud\n", stdout) < 0; }

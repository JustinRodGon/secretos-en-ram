/* seguro2.c - Lee con read(2) (sin bufer de stdio), bloquea con mlock y borra con explicit_bzero. */
#define _DEFAULT_SOURCE
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

int main(void) {
    char clave[64];
    if (mlock(clave, sizeof clave) != 0) perror("mlock");
    if (write(1, "Contrasena: ", 12) < 0) return 1;
    ssize_t n = read(0, clave, sizeof clave - 1);     /* directo del kernel: sin copia intermedia */
    if (n <= 0) return 1;
    clave[n] = '\0';
    clave[strcspn(clave, "\n")] = '\0';
    printf("Usando la clave (%zu caracteres)...\n", strlen(clave));
    fflush(stdout);
    explicit_bzero(clave, sizeof clave);
    pause();
    return 0;
}

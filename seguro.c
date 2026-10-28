/* seguro.c - Bloquea la pagina con mlock y borra el secreto con explicit_bzero. */
#define _DEFAULT_SOURCE
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>

int main(void) {
    char clave[64];
    if (mlock(clave, sizeof clave) != 0)              /* impide que la pagina vaya a swap */
        perror("mlock (revise ulimit -l)");
    printf("Contrasena: ");
    fflush(stdout);
    if (!fgets(clave, sizeof clave, stdin)) return 1; /* la copia en el bufer de stdio queda viva */
    clave[strcspn(clave, "\n")] = '\0';
    printf("Usando la clave (%zu caracteres)...\n", strlen(clave));
    fflush(stdout);
    explicit_bzero(clave, sizeof clave);              /* el compilador no puede eliminar esta llamada */
    pause();
    return 0;
}

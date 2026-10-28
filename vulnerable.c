/* vulnerable.c - Lee una contraseña, la "usa" y NO la borra de la RAM. */
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    char clave[64];                                   /* espacio en RAM (pila) */
    printf("Contrasena: ");
    fflush(stdout);
    if (!fgets(clave, sizeof clave, stdin)) return 1; /* fgets pasa por el bufer interno de stdio (heap) */
    clave[strcspn(clave, "\n")] = '\0';               /* quita el salto de linea */
    printf("Usando la clave (%zu caracteres)...\n", strlen(clave));
    fflush(stdout);
    pause();                                          /* el proceso queda vivo: se puede atacar */
    return 0;
}

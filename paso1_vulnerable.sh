#!/bin/bash
# paso1_vulnerable.sh : ataque contra el programa vulnerable (fgets y no borra la clave)
source "$(dirname "$0")/comun.sh"                          # colores, funciones y la funcion ataque
titulo "1 · Programa vulnerable"
que "vulnerable.c lee la contraseña con fgets, la usa y NO la borra. Copiamos su memoria y buscamos la contraseña."
ataque vulnerable                                          # corre atacar.sh y resume la salida
significa "Cualquiera con permisos sobre el proceso lee la clave con herramientas básicas.
Una copia está en la variable (stack) y otra en el búfer interno de fgets (heap)."

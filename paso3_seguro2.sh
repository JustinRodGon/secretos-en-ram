#!/bin/bash
# paso3_seguro2.sh : ataque contra seguro2 (read(2) + mlock + explicit_bzero)
source "$(dirname "$0")/comun.sh"                          # colores, funciones y la funcion ataque
titulo "3 · seguro2.c: read(2) + mlock + explicit_bzero"
que "Igual que seguro.c, pero lee con read(2), que no usa búfer intermedio. Repetimos el ataque."
ataque seguro2                                             # corre atacar.sh y resume la salida
significa "read(2) escribe directo en la variable: no hay copia oculta, y explicit_bzero borra la única que hay."

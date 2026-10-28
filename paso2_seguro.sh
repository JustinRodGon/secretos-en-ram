#!/bin/bash
# paso2_seguro.sh : ataque contra seguro (mlock + explicit_bzero, pero todavia usa fgets)
source "$(dirname "$0")/comun.sh"                          # colores, funciones y la funcion ataque
titulo "2 · seguro.c: mlock + explicit_bzero"
que "Corrección de la guía: bloquea la variable en RAM (mlock) y la borra (explicit_bzero). ¿Basta?"
ataque seguro                                              # corre atacar.sh y resume la salida
significa "Borrar la variable visible no basta: fgets dejó una copia oculta en el búfer de stdio (heap)."

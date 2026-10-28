#!/bin/bash
# demo.sh : corre los pasos 0 a 7 seguidos, con una pausa entre cada uno (respaldo de la demo de 9 minutos)
cd "$(dirname "$0")"                                       # trabaja siempre dentro de la carpeta de la demo
./paso0_preparar.sh || exit 1                              # si algo no esta listo, se detiene aqui
for p in paso1_vulnerable paso2_seguro paso3_seguro2 paso4_python paso5_core paso6_tpm paso7_resumen; do
  echo; read -rp "--- Enter para el siguiente paso ---"    # pausa entre pasos
  ./$p.sh                                                  # cada paso limpia la pantalla y muestra su titulo
done

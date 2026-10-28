#!/bin/bash
# paso5_core.sh : volcado por falla (core dump) con vulnerable, seguro2 y ulimit -c 0
source "$(dirname "$0")/comun.sh"                          # colores y funciones de formato
titulo "5 · Volcado por falla (core dump)"
que "Provocamos un fallo (SIGSEGV) en el programa. Linux escribe su memoria en un archivo 'core' en el disco."

caso() {                                                   # caso <programa> <limite de core>
  echo -e "${NEG}$1 con ulimit -c $2${FIN}"
  cmd "./core_experimento.sh $1 $2"
  local salida
  salida=$(./core_experimento.sh "$1" "$2" 2>/dev/null)    # 2>/dev/null oculta el aviso "Segmentation fault" de bash
  resultado
  if grep -q 'No se genero' <<<"$salida"; then
    bien "No se generó archivo core: la memoria no llegó al disco"
    return
  fi
  if ! grep -q 'Archivo generado' <<<"$salida"; then       # no hubo core aunque el limite lo permite
    mal "No se generó el core → ejecute ./preparar.sh (core_pattern)"; return
  fi
  echo "  Archivo en disco: $(sed -n 's/.*Archivo generado: //p' <<<"$salida")"
  local n; n=$(sed -n 's/.*core: //p' <<<"$salida")       # copias de la clave en el core
  if [ "$n" -gt 0 ]; then mal "CONTRASEÑA ENCONTRADA EN EL CORE ($n copias)"
  else bien "La contraseña NO aparece en el core"; fi
}

caso vulnerable unlimited
significa "La falla copió la memoria del proceso, con la clave, a un archivo en el disco."; pausa; echo
caso seguro2 unlimited
significa "Hay archivo core, pero seguro2 ya había borrado la clave: no hay nada que robar."; pausa; echo
caso vulnerable 0
significa "Con ulimit -c 0 el sistema no escribe el core: la memoria nunca llega al disco."

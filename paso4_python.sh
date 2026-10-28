#!/bin/bash
# paso4_python.sh : experimento de Python, str frente a bytearray (tres modos)
source "$(dirname "$0")/comun.sh"                          # colores y funciones de formato
titulo "4 · Python: str frente a bytearray"
que "Un programa Python lee la contraseña, intenta borrarla y contamos las copias en su memoria antes y después."

copias() { local n=${1%% *} r=${1#"${1%% *}"}; echo "$n $([ "$n" = 1 ] && echo copia || echo copias)$(tr -d '[]' <<<"$r")"; }   # "3  ([heap] x1)" -> "3 copias  (heap x1)"
modo() {                                                   # modo <nombre> <linea de python que lee la clave>
  echo -e "${NEG}Modo $1:${FIN}  $2"                       # muestra como se lee la clave en ese modo
  cmd "./python_experimento.sh $1"
  local salida antes despues
  salida=$(./python_experimento.sh "$1" 2>&1)              # salida completa del experimento
  antes=$(sed -n '/Antes/{n;s/ *copias: //p}' <<<"$salida")      # linea siguiente a "Antes de borrar"
  despues=$(sed -n '/Despues/{n;s/ *copias: //p}' <<<"$salida")  # linea siguiente a "Despues de borrar"
  resultado
  echo "  Antes de borrar:   $(copias "$antes")"
  echo "  Después de borrar: $(copias "$despues")"
  if [ "${despues%% *}" = 0 ]; then bien "La contraseña NO aparece en memoria"
  else mal "CONTRASEÑA TODAVÍA EN MEMORIA (${despues%% *} copias)"; fi
}

modo str 'clave = input()  …  del clave'
significa "str es inmutable: del solo quita el nombre, el texto sigue en memoria."; pausa; echo
modo bytes_a_bytearray 'clave = bytearray(sys.stdin.buffer.readline())  …  clave[i] = 0'
significa "Se borró el bytearray, pero readline() creó antes un bytes inmutable que no se puede borrar."; pausa; echo
modo bytearray_directo 'os.readv(0, [clave])  …  clave[i] = 0'
significa "os.readv hace que el kernel escriba directo en el bytearray: única copia, y se pone en ceros."

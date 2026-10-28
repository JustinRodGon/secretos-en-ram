#!/bin/bash
# comun.sh : colores y funciones de formato que comparten los scripts pasoN (se carga con "source comun.sh")
cd "$(dirname "${BASH_SOURCE[0]}")"                       # trabaja siempre dentro de la carpeta de la demo
CLAVE='ClaveSecreta2026!'                                 # contrasena de PRUEBA inventada (no es real)
ROJO='\033[1;31m'; VERDE='\033[1;32m'; AZUL='\033[1;36m'; NEG='\033[1m'; FIN='\033[0m'   # codigos ANSI de color

titulo()    { clear; echo -e "${NEG}════════ PASO $1 ════════${FIN}\n"; }        # 1. encabezado del paso
que()       { echo -e "${AZUL}Qué vamos a hacer:${FIN} $*\n"; }               # 2. explicacion corta
cmd()       { echo -e "${NEG}\$ $*${FIN}"; }                                 # 3. muestra el comando real antes de correrlo
resultado() { echo -e "\n${AZUL}Resultado:${FIN}"; }                         # 4. inicio del resultado resumido
bien()      { echo -e "  ${VERDE}✔ $*${FIN}"; }                              #    resultado bueno en verde
mal()       { echo -e "  ${ROJO}✘ $*${FIN}"; }                               #    resultado malo en rojo
significa() { echo -e "\n${AZUL}Qué significa:${FIN} $*"; }                  # 5. conclusion
pausa()     { echo; read -rp "Enter para continuar..."; }                    # espera entre sub-partes

# ataque <programa> : corre atacar.sh y resume su salida (lo usan paso1, paso2 y paso3)
ataque() {
  local prog=$1 salida n regiones lck
  cmd "./atacar.sh $prog '$CLAVE'"                                          # muestra el comando
  echo "  (lanza $prog, le pasa la clave, copia su memoria con gcore y la busca con strings | grep)"
  salida=$(./atacar.sh "$prog" "$CLAVE" 2>&1)                               # salida completa del ataque
  if grep -q 'gcore fallo' <<<"$salida"; then                               # gcore no pudo leer el proceso
    mal "gcore falló → ejecute ./preparar.sh (ptrace_scope)"; exit 1
  fi
  n=$(sed -n 's/.*strings | grep: //p' <<<"$salida")                       # copias encontradas en el volcado
  regiones=$(sed -n 's/.*ENCONTRADA .* en //p' <<<"$salida" | tr -d '[]' | paste -sd, | sed 's/,\([^,]*\)$/ y \1/; s/,/, /g')  # "heap y stack"
  lck=$(sed -n 's/.*VmLck:[[:space:]]*//p' <<<"$salida")                    # memoria bloqueada con mlock
  resultado
  echo "  Volcado: $(ls volcado_$prog.* 2>/dev/null) ($(sed -n 's/.*Volcado: //p' <<<"$salida"))"
  sed -n 's/ *offset \([0-9]*\):\(.*\)/  byte \1 del volcado → \2/p' <<<"$salida"   # donde esta cada copia
  if [ "$n" -gt 0 ]; then
    mal "CONTRASEÑA ENCONTRADA ($n $( [ "$n" = 1 ] && echo copia || echo copias): $regiones)"
  else
    bien "La contraseña NO aparece en memoria"
  fi
  echo "  Memoria bloqueada con mlock (VmLck): $lck"
}

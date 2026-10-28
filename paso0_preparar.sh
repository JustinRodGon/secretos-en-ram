#!/bin/bash
# paso0_preparar.sh : comprueba que todo esta listo antes de la demo
source "$(dirname "$0")/comun.sh"                          # colores y funciones de formato
titulo "0 · ¿Está todo listo?"
que "Revisamos que los programas estén compilados y que la VM tenga la configuración de la demo."
cmd "sysctl kernel.yama.ptrace_scope kernel.core_pattern"  # muestra el comando
sysctl kernel.yama.ptrace_scope kernel.core_pattern        # valores actuales del kernel
resultado
FALLOS=0                                                   # cuenta los puntos que fallan
chequeo() {                                                # chequeo <descripcion> <condicion> <que hacer si falla>
  if eval "$2"; then bien "$1"; else mal "$1 → $3"; FALLOS=$((FALLOS+1)); fi
}
chequeo "Programas compilados (vulnerable, seguro, seguro2)" '[ -x vulnerable ] && [ -x seguro ] && [ -x seguro2 ]' "gcc -O0 -o vulnerable vulnerable.c (igual con seguro y seguro2)"
chequeo "Herramientas instaladas (gcore, strings, swtpm, tpm2)" 'command -v gcore strings swtpm tpm2_startup > /dev/null' "sudo apt install gdb binutils swtpm swtpm-tools tpm2-tools"
chequeo "ptrace_scope = 0 (gcore puede leer la memoria)" '[ "$(cat /proc/sys/kernel/yama/ptrace_scope)" = 0 ]' "ejecute ./preparar.sh"
chequeo "core_pattern = core.%p (el core se guarda aquí)" '[ "$(cat /proc/sys/kernel/core_pattern)" = core.%p ]' "ejecute ./preparar.sh"
chequeo "No hay swtpm viejos abiertos" '! pgrep -x swtpm > /dev/null' "pkill swtpm"
if [ $FALLOS = 0 ]; then
  significa "Todo listo: podemos empezar."
else
  significa "Faltan $FALLOS punto(s): corríjalos antes de seguir."; exit 1
fi

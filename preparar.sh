#!/bin/bash
# preparar.sh : configura la VM para la demo (se revierte con restaurar.sh)
cd "$(dirname "$0")"                                          # trabaja siempre dentro de la carpeta de la demo
[ -f .ptrace_original ]      || cat /proc/sys/kernel/yama/ptrace_scope > .ptrace_original     # guarda el original solo la 1a vez (si no, la 2a guardaria el 0)
[ -f .core_pattern_original ] || cat /proc/sys/kernel/core_pattern     > .core_pattern_original
sudo sysctl -w kernel.yama.ptrace_scope=0      # permite que gcore lea procesos del mismo usuario
sudo sysctl -w kernel.core_pattern=core.%p     # los core dumps se escriben como core.<PID> en la carpeta actual
pkill swtpm 2>/dev/null                         # cierra TPM emulados que hayan quedado abiertos
echo "VM lista para la demo"

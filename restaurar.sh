#!/bin/bash
# restaurar.sh : devuelve la VM a su configuración original
cd "$(dirname "$0")"                                          # los archivos .ptrace_original y .core_pattern_original estan aqui
sudo sysctl -w kernel.yama.ptrace_scope="$(cat .ptrace_original)" &&
sudo sysctl -w kernel.core_pattern="$(cat .core_pattern_original)" &&
echo "Configuracion restaurada" || echo "✘ No se pudo restaurar: revise la clave de sudo"   # solo dice "restaurada" si ambos sysctl funcionaron
pkill swtpm 2>/dev/null

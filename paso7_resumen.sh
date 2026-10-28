#!/bin/bash
# paso7_resumen.sh : tabla resumen final
source "$(dirname "$0")/comun.sh"                          # colores y funciones de formato
titulo "7 · Resumen"
que "Cada tipo de memoria: ¿sobrevive al reinicio?, qué riesgo tiene y cómo se protege."
echo -e "${NEG}Memoria             | ¿Sobrevive reinicio? | Riesgo                     | Protección${FIN}"
cat <<'TABLA'
--------------------|----------------------|----------------------------|--------------------------------
RAM (DRAM)          | No (remanencia)      | Volcados, arranque en frío | explicit_bzero, apagar del todo
Swap                | Sí                   | Secretos escritos a disco  | mlock, swap cifrada
Hibernación         | Sí                   | Copia completa de la RAM   | Volumen cifrado, no hibernar
Core dump           | Sí                   | Memoria del proceso        | ulimit -c 0, permisos
Disco / flash       | Sí                   | Robo del medio             | LUKS, BitLocker
TPM NV/persistente  | Sí                   | Autorización indebida      | Políticas PCR + contraseña
TPM transitorio/PCR | No                   | -                          | -
TABLA
significa "Cifrar el disco no protege lo que está en uso en la RAM: el programa debe borrar sus secretos."

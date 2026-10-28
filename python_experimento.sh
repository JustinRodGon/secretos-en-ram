#!/bin/bash
# python_experimento.sh <modo> : cuenta las copias del secreto antes y despues de borrarlo
cd "$(dirname "$0")"                                       # trabaja siempre dentro de la carpeta de la demo
MODO=$1; CLAVE="ClaveSecreta2026!"
rm -f salida_py.txt
echo "$CLAVE" | python3 py_secreto.py "$MODO" > salida_py.txt &
PID=$!                                                     # PID del proceso python (ultimo de la tuberia)
esperar() { until grep -q "$1" salida_py.txt 2>/dev/null; do sleep 0.1; done; }
echo "[*] Modo: $MODO (PID $PID)"
esperar FASE1; sleep 0.5
echo "[*] Antes de borrar:";   python3 escanear_cuenta.py $PID "$CLAVE"
esperar FASE2; sleep 0.5
echo "[*] Despues de borrar:"; python3 escanear_cuenta.py $PID "$CLAVE"
wait $PID 2>/dev/null

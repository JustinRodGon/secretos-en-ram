#!/bin/bash
# atacar.sh <programa> <contraseña> : lanza el programa, vuelca su memoria y busca la contraseña
cd "$(dirname "$0")"                                           # trabaja siempre dentro de la carpeta de la demo
PROG=$1; CLAVE=$2
rm -f volcado_$PROG.* fifo_$PROG; mkfifo fifo_$PROG           # FIFO: tuberia con nombre para pasar la clave
( echo "$CLAVE"; sleep 30 ) > fifo_$PROG &                     # escribe la clave y mantiene la FIFO abierta
FEEDER=$!
./$PROG < fifo_$PROG > salida_$PROG.txt &                      # el programa lee la clave desde la FIFO
APP=$!
sleep 1
echo "[*] PID de $PROG: $APP"
gcore -o volcado_$PROG $APP > /dev/null 2>&1                   # copia toda la memoria del proceso a un archivo
if [ ! -f volcado_$PROG.$APP ]; then
  echo "[!] gcore fallo: ejecute ./preparar.sh (ptrace_scope)"; kill $APP; pkill -P $FEEDER; exit 1
fi
echo "[*] Volcado: $(stat -c %s volcado_$PROG.$APP) bytes"
echo "[*] Ocurrencias con strings | grep: $(strings -n 8 volcado_$PROG.$APP | grep -c -F "$CLAVE")"
grep -a -b -o -F "$CLAVE" volcado_$PROG.$APP | head -5 | sed 's/^/    offset /'   # posicion de cada copia
echo "[*] Regiones (lectura viva de /proc/$APP/mem):"
python3 escanear_proc.py $APP "$CLAVE"
echo "[*] Paginas bloqueadas en RAM: $(grep VmLck /proc/$APP/status | tr -s ' ')"  # efecto de mlock
kill $APP 2>/dev/null; pkill -P $FEEDER 2>/dev/null; kill $FEEDER 2>/dev/null
rm -f fifo_$PROG

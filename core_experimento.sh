#!/bin/bash
# core_experimento.sh <programa> <limite_core> : provoca un fallo (SIGSEGV) y busca la clave en el core
cd "$(dirname "$0")"                                            # el core se escribe en la carpeta actual
PROG=$1; LIM=$2; CLAVE="ClaveSecreta2026!"
rm -f core core.[0-9]* fifo_core; mkfifo fifo_core
( echo "$CLAVE"; sleep 20 ) > fifo_core &
FEEDER=$!
( ulimit -c $LIM; exec ./$PROG < fifo_core > /dev/null ) &     # ulimit -c: tamano maximo del core
sleep 1
APP=$(pgrep -n -x $PROG)
echo "[*] Programa: $PROG | limite de core (ulimit -c): $LIM | PID $APP"
kill -SEGV $APP                                                 # simula un fallo de segmentacion
sleep 1
CORE=$(ls core core.[0-9]* 2>/dev/null | head -1)
if [ -n "$CORE" ]; then
  echo "[*] Archivo generado: $CORE ($(stat -c %s $CORE) bytes, permisos $(stat -c %A $CORE))"
  echo "[*] Ocurrencias de la contrasena en el core: $(grep -a -o -F "$CLAVE" $CORE | wc -l)"
else
  echo "[*] No se genero archivo core"
fi
pkill -P $FEEDER 2>/dev/null; kill $FEEDER 2>/dev/null; rm -f fifo_core

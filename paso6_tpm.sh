#!/bin/bash
# paso6_tpm.sh : TPM emulado, que sobrevive y que se pierde al reiniciar
source "$(dirname "$0")/comun.sh"                          # colores y funciones de formato
titulo "6 · TPM: volátil frente a no volátil"
que "En un TPM emulado (swtpm) creamos 4 cosas, reiniciamos el TPM y vemos cuáles siguen ahí."
cmd "./tpm_experimento.sh"
echo "  Dentro, el script ejecuta:"                            # comandos clave de tpm_experimento.sh
echo "    tpm2_createprimary -C o -c transitoria.ctx          (llave transitoria)"
echo "    tpm2_evictcontrol -C o -c para_persistir.ctx 0x81010001   (llave persistente)"
echo "    tpm2_nvdefine / tpm2_nvwrite 0x01500016             (texto en índice NV)"
echo "    tpm2_pcrextend 16:sha256=...                        (cambia el PCR 16)"
echo "    tpm2_shutdown -c ; reinicio de swtpm ; tpm2_startup -c"
salida=$(./tpm_experimento.sh 2>&1)                            # salida completa del experimento
antes=$(sed -n '/== 2/,/== 3/p' <<<"$salida")                  # seccion ANTES del reinicio
despues=$(sed -n '/== 4/,$p' <<<"$salida")                     # seccion DESPUES del reinicio
resultado
if ! grep -q 0x81010001 <<<"$antes"; then                      # el TPM no respondio
  if grep -qi tcti <<<"$salida"; then mal "Error de TCTI → sudo apt install libtss2-tcti-swtpm0t64"
  else mal "El TPM no respondió → ejecute pkill swtpm (puerto 2321 ocupado) y repita"; fi
  tail -3 swtpm.log 2>/dev/null; exit 1
fi
pcr() { sed -n 's/.*16: 0x\(.\{12\}\).*/\1…/p' <<<"$1"; }        # primeros 12 hex del PCR 16
nv()  { sed -n 's/.*lectura NV *: //p' <<<"$1"; }               # texto leido del indice NV
col() { printf "%s%*s" "$1" $(( $2 - ${#1} )) ""; }           # rellena contando letras (printf %-Ns cuenta bytes y desalinea Í y …)
fila() {                                                        # fila <objeto> <antes> <despues> <sobrevivio 0/1>
  echo -n "  $(col "$1" 26) $(col "$2" 22) $(col "$3" 22) "
  if [ "$4" = 1 ]; then echo -e "${VERDE}✔ sobrevivió${FIN}"; else echo -e "${ROJO}✘ se perdió${FIN}"; fi
}
echo -e "  ${NEG}$(col Objeto 26) $(col ANTES 22) $(col DESPUÉS 22)${FIN}"     # encabezado de la tabla
t_d=$(grep -c 'transitorios.*0x80' <<<"$despues")              # 1 si hay transitorios despues
fila "Transitorio (0x80000000)" "$(grep -q 'transitorios.*0x80' <<<"$antes" && echo presente || echo -)" "$([ $t_d = 1 ] && echo presente || echo 'no existe')" "$t_d"
p_d=$(grep -c 'persistentes.*0x81010001' <<<"$despues")
fila "Persistente (0x81010001)" "presente" "$([ $p_d = 1 ] && echo presente || echo 'no existe')" "$p_d"
nv_a=$(nv "$antes"); nv_d=$(nv "$despues")
fila "Índice NV (0x01500016)" "\"$nv_a\"" "\"$nv_d\"" "$([ "$nv_d" = "$nv_a" ] && echo 1 || echo 0)"
pcr_a=$(pcr "$antes"); pcr_d=$(pcr "$despues")
fila "PCR 16" "$pcr_a" "$pcr_d" "$([ "$pcr_d" = "$pcr_a" ] && echo 1 || echo 0)"
significa "El índice NV y el objeto persistente se guardan en la memoria no volátil del TPM.
El objeto transitorio y el PCR viven en su RAM: el PCR vuelve a ceros en cada arranque."

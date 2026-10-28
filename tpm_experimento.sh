#!/bin/bash
# tpm_experimento.sh : objeto transitorio vs persistente vs indice NV, antes y despues de reiniciar el TPM
set -u
cd "$(dirname "$0")"
pkill swtpm 2>/dev/null; sleep 0.5
rm -rf tpm_state *.ctx && mkdir tpm_state
export TPM2TOOLS_TCTI="swtpm:host=127.0.0.1,port=2321"     # tpm2-tools habla con el TPM emulado

iniciar_tpm() {
  swtpm socket --tpm2 --tpmstate dir=tpm_state \
    --server type=tcp,port=2321 --ctrl type=tcp,port=2322 \
    --flags not-need-init > swtpm.log 2>&1 &
  SWTPM_PID=$!; sleep 1
}
listar() {
  echo "    transitorios : $(tpm2_getcap handles-transient 2>&1 | tr '\n' ' ')"
  echo "    persistentes : $(tpm2_getcap handles-persistent 2>&1 | tr '\n' ' ')"
  echo "    indices NV   : $(tpm2_getcap handles-nv-index 2>&1 | tr '\n' ' ')"
  echo "    PCR 16       : $(tpm2_pcrread sha256:16 2>&1 | grep -E '16 *:' | tr -s ' ')"
}

iniciar_tpm
tpm2_startup -c
echo "== 1. Creando objetos =="
tpm2_createprimary -C o -c transitoria.ctx > /dev/null                    # llave primaria: objeto TRANSITORIO
tpm2_createprimary -C o -c para_persistir.ctx > /dev/null
tpm2_evictcontrol -C o -c para_persistir.ctx 0x81010001 > /dev/null       # copia a memoria PERSISTENTE
tpm2_nvdefine 0x01500016 -C o -s 32 -a "ownerread|ownerwrite" > /dev/null # define un indice NV de 32 bytes
echo -n "secreto-en-NV-2026" | tpm2_nvwrite 0x01500016 -C o -i-           # escribe el texto en el indice NV
tpm2_pcrextend 16:sha256=$(echo -n "malware" | sha256sum | cut -d' ' -f1) # cambia el PCR 16 (volatil)

echo "== 2. Estado ANTES del reinicio =="
listar
echo "    lectura NV   : $(tpm2_nvread 0x01500016 -C o -s 18 2>&1)"

echo "== 3. Reiniciando el TPM (apagado ordenado + nuevo arranque) =="
tpm2_shutdown -c 2>/dev/null
kill $SWTPM_PID; wait $SWTPM_PID 2>/dev/null; sleep 1
iniciar_tpm
tpm2_startup -c

echo "== 4. Estado DESPUES del reinicio =="
listar
echo "    lectura NV   : $(tpm2_nvread 0x01500016 -C o -s 18 2>&1)"
echo "    usar la primaria transitoria: $(tpm2_readpublic -c transitoria.ctx 2>&1 | grep -o 'TPM Error.*\|ERROR.*' | head -1)"
echo "    usar la persistente 0x81010001: $(tpm2_readpublic -c 0x81010001 2>&1 | head -1 | cut -c1-60)"
kill $SWTPM_PID 2>/dev/null; wait 2>/dev/null

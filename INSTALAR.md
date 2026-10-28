# INSTALAR — Demo "Secretos en RAM" (ITI-922, Proyecto 3, Grupo 3)

Instrucciones para dejar la demo funcionando en **otra VM Ubuntu 24.04** (VirtualBox, KVM, etc.) exactamente igual que en la VM original.
Están escritas para que las siga una persona o un agente (Claude Code). Hay una sección al final con reglas para el agente.

> Alcance: todo corre **dentro de una VM propia**. Los "ataques" son solo contra procesos que crea la propia demo, con una contraseña de **prueba** inventada (`ClaveSecreta2026!`). El TPM es un **emulador** (swtpm). Fuera de la carpeta solo se cambian dos parámetros del kernel, que `restaurar.sh` devuelve a su valor original.

---

## 0. Requisitos

- Ubuntu **24.04** (probado en 24.04.5 LTS, kernel 7.0, Python 3.12.3, gcc 13.3, gdb 15.1, swtpm 0.7.3, tpm2-tools 5.6).
- Un usuario normal con `sudo`. **No** corra la demo como root.
- Unos 200 MB libres para los paquetes.
- **Recomendado:** tome un snapshot de la VM antes de empezar (VirtualBox: *Máquina → Tomar instantánea*).

## 1. Descargar el proyecto

```bash
sudo apt install -y git
cd ~
git clone https://github.com/JustinRodGon/secretos-en-ram.git
cd ~/secretos-en-ram
```

El repo es privado: necesita haber aceptado la invitación de colaborador en GitHub.
La carpeta puede estar en cualquier lugar: todos los scripts trabajan relativos a su propia ubicación.

## 2. Instalar paquetes

```bash
sudo apt update
sudo apt install -y gcc gdb binutils python3 swtpm swtpm-tools tpm2-tools
```

| Paquete | Para qué |
|---|---|
| `gcc` | compila los programas en C |
| `gdb` | trae `gcore`, que vuelca la memoria de un proceso vivo |
| `binutils` | trae `strings` |
| `swtpm`, `swtpm-tools` | TPM 2.0 emulado por software |
| `tpm2-tools` | comandos `tpm2_*` |

Compruebe la librería TCTI de swtpm (se instala sola con tpm2-tools):

```bash
dpkg -l | grep tcti-swtpm          # debe salir libtss2-tcti-swtpm0t64
```

Si no sale: `sudo apt install -y libtss2-tcti-swtpm0t64`.

## 3. Compilar y dar permisos

Los binarios **no** van en el repo; hay que compilarlos en cada máquina:

```bash
gcc -O0 -o vulnerable vulnerable.c
gcc -O0 -o seguro     seguro.c
gcc -O0 -o seguro2    seguro2.c
chmod +x *.sh *.py
```

`-O0` desactiva las optimizaciones para que el comportamiento sea predecible.

## 4. Preparar la VM (antes de CADA demo)

```bash
./preparar.sh                      # pide la clave de sudo
```

Cambia dos parámetros del kernel (se pierden al reiniciar la VM, por eso hay que repetirlo antes de cada demo):

- `kernel.yama.ptrace_scope=0` → sin esto `gcore` falla con "Operation not permitted".
- `kernel.core_pattern=core.%p` → sin esto Ubuntu manda los core dumps a apport y no aparece el archivo.

La primera vez guarda los valores originales en `.ptrace_original` y `.core_pattern_original` (archivos ocultos). **No los borre**: `restaurar.sh` los usa.

## 5. Comprobar y correr

```bash
./paso0_preparar.sh                # deben salir 5 ✔ verdes
./demo.sh                          # demo completa, Enter entre pasos
```

O paso por paso (así se hace en clase):

```bash
./paso1_vulnerable.sh
./paso2_seguro.sh
./paso3_seguro2.sh
./paso4_python.sh                  # tiene pausas: Enter
./paso5_core.sh                    # tiene pausas: Enter
./paso6_tpm.sh
./paso7_resumen.sh
```

Al terminar:

```bash
./restaurar.sh                     # devuelve ptrace_scope y core_pattern a sus valores originales
```

## 6. Resultados esperados

Si la instalación está bien, debe ver **exactamente** esto (mismos números que en `RESULTADOS.md`):

| Paso | Resultado esperado |
|---|---|
| 1 vulnerable | ✘ CONTRASEÑA ENCONTRADA (2 copias: heap y stack), VmLck 0 kB |
| 2 seguro | ✘ CONTRASEÑA ENCONTRADA (1 copia: heap), VmLck 4 kB |
| 3 seguro2 | ✔ La contraseña NO aparece en memoria, VmLck 4 kB |
| 4 Python `str` | 3 → 3 copias |
| 4 Python `bytes_a_bytearray` | 3 → 2 copias |
| 4 Python `bytearray_directo` | 1 → 0 copias |
| 5 core de vulnerable | archivo `core.NNNN` ~450 KB, `-rw-------`, 2 copias |
| 5 core de seguro2 | archivo `core.NNNN`, 0 copias |
| 5 core con `ulimit -c 0` | ✔ No se generó archivo core |
| 6 TPM | transitorio ✘, persistente 0x81010001 ✔, índice NV ✔ («secreto-en-NV-2026»), PCR 16 ✘ (vuelve a 000…) |

Normal que cambie entre corridas: PID, offsets en el volcado (ASLR), tamaños de volcado en unos pocos bytes. Las cifras de Python podrían variar con otra versión de Python; en ese caso se corrige el informe, no la demo.

## 7. Problemas comunes

| Síntoma | Solución |
|---|---|
| `✘ gcore falló → ejecute ./preparar.sh` | `./preparar.sh` (la VM se reinició o nunca se corrió) |
| `paso0` marca ✘ en ptrace_scope / core_pattern | `./preparar.sh` |
| `✘ No se generó el core` | `./preparar.sh`; luego `sysctl kernel.core_pattern` debe decir `core.%p` |
| `✘ El TPM no respondió` / puerto 2321 ocupado | `pkill swtpm` y repetir |
| `✘ Error de TCTI` | `sudo apt install -y libtss2-tcti-swtpm0t64` |
| `'xterm-ghostty': unknown terminal type` (o `kitty`, `alacritty`…) al entrar por SSH | En la sesión: `export TERM=xterm-256color`. Permanente, desde la PC: `infocmp -x xterm-ghostty \| ssh usuario@IP tic -x -` |
| `Permission denied` al correr un script | `chmod +x *.sh *.py` |
| `./vulnerable: No such file` | falta el paso 3 (compilar) |
| `mlock: Cannot allocate memory` en paso 2/3 | `ulimit -l` muy bajo; en Ubuntu normal es 8 MB y alcanza |
| `restaurar.sh` dice "No se pudo restaurar" | la clave de sudo falló; córralo en una terminal interactiva |

## 8. Contenido del repo

| Archivo | Qué es |
|---|---|
| `README.md` | descripción del proyecto |
| `INSTALAR.md` | este archivo |
| `RESULTADOS.md` | salida real de la VM original (referencia para comparar) |
| `vulnerable.c`, `seguro.c`, `seguro2.c` | los tres programas en C |
| `preparar.sh`, `restaurar.sh` | configuran / restauran el kernel |
| `atacar.sh`, `escanear_proc.py`, `escanear_cuenta.py` | ataque con gcore y lectura de `/proc/PID/mem` |
| `py_secreto.py`, `python_experimento.sh` | experimento de Python |
| `core_experimento.sh` | experimento de core dump |
| `tpm_experimento.sh` | experimento con el TPM emulado |
| `comun.sh` | colores y formato compartidos por los `pasoN` |
| `paso0_…sh` a `paso7_…sh` | un script por parte de la demo |
| `demo.sh` | corre paso0 a paso7 seguidos |

---

## Para Claude Code (u otro agente)

Si le piden instalar o verificar esta demo, siga estas reglas:

1. **Pida al usuario que tome un snapshot de la VM y espere su confirmación** antes de instalar o correr `preparar.sh`.
2. Ejecute las secciones 2 → 3 → 4 → 5 en orden, explicando cada paso al usuario en español simple.
3. **No modifique los scripts** para "arreglar" algo sin antes leer el error. Ya están probados en Ubuntu 24.04.5 con tpm2-tools 5.6 y funcionaron sin cambios. Si un comando `tpm2_*` falla, compruebe sus opciones con `--help` o `man` antes de cambiarlo, y anote cualquier corrección en `RESULTADOS.md`.
4. Para verificar sin interacción (sin pulsar Enter): `yes "" | ./demo.sh`. Para quitar los colores de la salida: `| sed 's/\x1b\[[0-9;]*[mHJ]//g'`.
5. Compare los resultados con la tabla de la sección 6 y con `RESULTADOS.md`. **No invente resultados**: si algo difiere, repórtelo tal cual con la salida real.
6. `sudo` no lee la clave sin terminal. Si corre los comandos por SSH no interactivo, use `echo CLAVE | sudo -S ./preparar.sh`, o pida al usuario que lo corra con `! ./preparar.sh`.
7. Al terminar, ejecute `./restaurar.sh` y recuerde al usuario que debe correr `./preparar.sh` antes de presentar.
8. No use contraseñas reales: la única es `ClaveSecreta2026!`, ya escrita en los scripts.

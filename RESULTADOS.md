# RESULTADOS — Proyecto 3 "Secretos en RAM" (Grupo 3)

Ejecutado el 2026-10-27 en la VM `ubuntu24.04` (KVM/libvirt), usuario `ubud`, carpeta `~/demo-secretos-ram`.
Contraseña de prueba: `ClaveSecreta2026!` (inventada, no es real). La salida completa de cada script está al final, tal cual la imprimió.

## Comparación con el informe

| Caso | Valor en el informe | Valor real en la VM | ¿Coincide? |
|---|---|---|---|
| C vulnerable | 2 copias, en [heap] y [stack]; VmLck 0 kB | 2 copias, [heap] x1 y [stack] x1; VmLck 0 kB | ✔ |
| C seguro | 1 copia, en [heap]; VmLck 4 kB | 1 copia, [heap]; VmLck 4 kB | ✔ |
| C seguro2 | 0 copias; VmLck 4 kB | 0 copias; VmLck 4 kB | ✔ |
| Python str | 3 → 3 | 3 → 3 | ✔ |
| Python bytes_a_bytearray | 3 → 2 | 3 → 2 | ✔ |
| Python bytearray_directo | 1 → 0 | 1 → 0 | ✔ |
| Core de vulnerable | 2 copias, permisos rw------- | 2 copias, `-rw-------` | ✔ |
| Core de seguro2 | 0 copias | 0 copias | ✔ |
| Core con ulimit -c 0 | No se genera archivo | No se generó archivo | ✔ |
| TPM | Sobreviven 0x81010001 y el índice NV («secreto-en-NV-2026»); se pierden el transitorio y el PCR 16 (vuelve a ceros) | Igual: 0x81010001 y 0x1500016 («secreto-en-NV-2026») siguen; transitorios vacíos; PCR 16 = 0x000…0 | ✔ |

**No hay diferencias con el informe.** Todos los valores coinciden en las 3 corridas completas que se hicieron (scripts técnicos, scripts `pasoN` uno por uno y `demo.sh`).

### Tamaños

| Archivo | Tamaño |
|---|---|
| Volcado gcore de `vulnerable` | 598 840 bytes |
| Volcado gcore de `seguro` | 599 056 bytes (598 936 en otra corrida) |
| Volcado gcore de `seguro2` | 599 064 bytes |
| Core de `vulnerable` (SIGSEGV) | 450 560 bytes |
| Core de `seguro2` (SIGSEGV) | 450 560 bytes |

### Detalles observados (no son diferencias, pero conviene saberlos)

- La posición (offset) de la copia en la **pila** cambia en cada corrida (565 144, 567 496, 572 136…). Es ASLR: Linux coloca la pila en una dirección aleatoria cada vez. La copia del heap queda siempre cerca del byte 18 000.
- Antes del reinicio, el TPM muestra **3** handles transitorios (0x80000000–0x80000002), no 1. Sin gestor de recursos (`tpm2-abrmd`), los objetos que carga cada comando (las dos primarias y la recarga de `para_persistir.ctx` que hace `tpm2_evictcontrol`) se quedan cargados. Después del reinicio no queda ninguno.
- El error al usar la primaria transitoria después del reinicio es `Esys_ContextLoad(0x1DF) - tpm:parameter(1):integrity check failed`. El archivo `.ctx` está protegido con una clave que el TPM cambia en cada arranque, así que ya no se puede recargar.
- En Python, `bytes_a_bytearray` a veces cuenta las dos copias anónimas en la misma región (`[anonima] x2`) y a veces en dos regiones distintas (`x1, x1`). El total es siempre 3 → 2.

## Correcciones y cambios respecto a la guía

1. **tpm2-tools (5.6): no hubo que corregir ningún comando.** `tpm2_createprimary`, `evictcontrol`, `nvdefine`, `nvwrite -i-`, `nvread -s`, `pcrextend`, `pcrread`, `getcap handles-*`, `shutdown -c` y `startup -c` funcionaron tal como están en la guía.
2. **TCTI de swtpm:** en Ubuntu 24.04 el paquete es `libtss2-tcti-swtpm0t64`. Ya se instala como dependencia de `tpm2-tools`, así que no hubo error de TCTI.
3. **`preparar.sh` guarda el valor original solo la primera vez.** En la versión original, si se corría dos veces, la segunda guardaba `0` como "original" y `restaurar.sh` ya no restauraba nada. Ahora usa `[ -f .ptrace_original ] || ...`.
4. **`cd "$(dirname "$0")"`** se añadió al inicio de `preparar.sh`, `restaurar.sh`, `atacar.sh`, `python_experimento.sh` y `core_experimento.sh`, para que funcionen aunque se llamen desde otra carpeta. `tpm_experimento.sh` y `demo.sh` ya lo tenían.
5. **`comun.sh` (nuevo):** colores y funciones de formato que comparten los scripts `pasoN`, para no repetir el mismo código ocho veces.
6. `paso5_core.sh` oculta el aviso "Segmentation fault (core dumped)" que imprime bash. Es esperado, porque el script envía SIGSEGV a propósito.

---

# Salida real de cada script

## Entorno

```
Ubuntu 24.04.5 LTS
7.0.0-38-generic
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
GNU gdb (Ubuntu 15.1-1ubuntu1~24.04.1) 15.1
Python 3.12.3
TPM emulator version 0.7.3, Copyright (c) 2014-2021 IBM Corp.
tool="tpm2_startup" version="5.6" tctis="libtss2-tctildr" tcti-default=tcti-device
```

### ./atacar.sh vulnerable

```
[*] PID de vulnerable: 7404
[*] Volcado: 598840 bytes
[*] Ocurrencias con strings | grep: 2
    offset 18088:ClaveSecreta2026!
    offset 572136:ClaveSecreta2026!
[*] Regiones (lectura viva de /proc/7404/mem):
    ENCONTRADA 1x en [heap]
    ENCONTRADA 1x en [stack]
[*] Paginas bloqueadas en RAM: VmLck:	 0 kB
```

### ./atacar.sh seguro

```
[*] PID de seguro: 7434
[*] Volcado: 599056 bytes
[*] Ocurrencias con strings | grep: 1
    offset 18200:ClaveSecreta2026!
[*] Regiones (lectura viva de /proc/7434/mem):
    ENCONTRADA 1x en [heap]
[*] Paginas bloqueadas en RAM: VmLck:	 4 kB
```

### ./atacar.sh seguro2

```
[*] PID de seguro2: 7464
[*] Volcado: 599064 bytes
[*] Ocurrencias con strings | grep: 0
[*] Regiones (lectura viva de /proc/7464/mem):
    no aparece en ninguna region
[*] Paginas bloqueadas en RAM: VmLck:	 4 kB
```

### ./python_experimento.sh str

```
[*] Modo: str (PID 7493)
[*] Antes de borrar:
    copias: 3  ([heap] x1, [anonima] x2)
[*] Despues de borrar:
    copias: 3  ([heap] x1, [anonima] x2)
```

### ./python_experimento.sh bytes_a_bytearray

```
[*] Modo: bytes_a_bytearray (PID 7554)
[*] Antes de borrar:
    copias: 3  ([heap] x1, [anonima] x2)
[*] Despues de borrar:
    copias: 2  ([heap] x1, [anonima] x1)
```

### ./python_experimento.sh bytearray_directo

```
[*] Modo: bytearray_directo (PID 7615)
[*] Antes de borrar:
    copias: 1  ([anonima] x1)
[*] Despues de borrar:
    copias: 0
```

### ./core_experimento.sh vulnerable unlimited

```
[*] Programa: vulnerable | limite de core (ulimit -c): unlimited | PID 7677
[*] Archivo generado: core.7677 (450560 bytes, permisos -rw-------)
[*] Ocurrencias de la contrasena en el core: 2
```

### ./core_experimento.sh seguro2 unlimited

```
[*] Programa: seguro2 | limite de core (ulimit -c): unlimited | PID 7696
[*] Archivo generado: core.7696 (450560 bytes, permisos -rw-------)
[*] Ocurrencias de la contrasena en el core: 0
```

### ./core_experimento.sh vulnerable 0

```
[*] Programa: vulnerable | limite de core (ulimit -c): 0 | PID 7715
[*] No se genero archivo core
```

### ./tpm_experimento.sh

```
== 1. Creando objetos ==
== 2. Estado ANTES del reinicio ==
    transitorios : - 0x80000000 - 0x80000001 - 0x80000002 
    persistentes : - 0x81010001 
    indices NV   : - 0x1500016 
    PCR 16       :  16: 0xF54326D990A8430C2F5540A428ADA12780842007187AAFB249997E135221266F
    lectura NV   : secreto-en-NV-2026
== 3. Reiniciando el TPM (apagado ordenado + nuevo arranque) ==
== 4. Estado DESPUES del reinicio ==
    transitorios : 
    persistentes : - 0x81010001 
    indices NV   : - 0x1500016 
    PCR 16       :  16: 0x0000000000000000000000000000000000000000000000000000000000000000
    lectura NV   : secreto-en-NV-2026
    usar la primaria transitoria: TPM Error 
    usar la persistente 0x81010001: name: 000b53aa9b23abda800ac9752e7d177913d5f2a25c47f16acf6d8e
```

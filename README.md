# Secretos en RAM

> ¿Qué pasa con una contraseña después de que un programa la usa? Si no se borra,
> se queda en la memoria y cualquiera con acceso al proceso puede leerla.

Demo en vivo (~9 minutos) para el curso **ITI-922 Seguridad de TI II** — Universidad
Técnica Nacional. Unidad III, Proyecto 3, Grupo 3.

El proyecto muestra, paso a paso, cómo un secreto queda expuesto en la RAM y cómo
las distintas mitigaciones (`mlock`, `explicit_bzero`, `read(2)`, `bytearray`, TPM)
reducen —o no— esa exposición.

## Qué demuestra

| Paso | Script | Qué se ve |
|------|--------|-----------|
| 0 | `paso0_preparar.sh` | Comprueba que la VM está lista (herramientas y permisos). |
| 1 | `paso1_vulnerable.sh` | Un programa en C que **no** borra la contraseña: aparece en su volcado de memoria (`gcore`). |
| 2 | `paso2_seguro.sh` | `seguro.c` con `mlock` + `explicit_bzero`, y por qué **aún así** queda una copia. |
| 3 | `paso3_seguro2.sh` | `seguro2.c` lee con `read(2)` para no dejar copia en los buffers de stdio. |
| 4 | `paso4_python.sh` | Python: `str` (inmutable, no se puede borrar) frente a `bytearray` (sí). |
| 5 | `paso5_core.sh` | Volcado por falla (*core dump*) y cómo `ulimit -c 0` lo evita. |
| 6 | `paso6_tpm.sh` | TPM emulado (swtpm): qué sobrevive al reinicio y qué se pierde. |
| 7 | `paso7_resumen.sh` | Tabla resumen de todos los resultados. |

## Requisitos

Una VM con Ubuntu 24.04 (o similar). La instalación de dependencias y la
preparación del entorno están en **[INSTALAR.md](INSTALAR.md)**.

## Cómo correr la demo

```bash
# 1. Preparar el entorno (ajusta ptrace_scope y core_pattern)
./preparar.sh

# 2. Correr la demo completa, encadena los pasos 0 a 7
./demo.sh

# 3. Dejar el sistema como estaba
./restaurar.sh
```

También podés correr cada paso por separado (`./paso1_vulnerable.sh`, etc.)
después de `./preparar.sh`.

## Estructura del repo

```
Programas en C      vulnerable.c  seguro.c  seguro2.c
Programas Python    py_secreto.py  escanear_proc.py  escanear_cuenta.py
Experimentos        atacar.sh  python_experimento.sh  core_experimento.sh  tpm_experimento.sh
Pasos de la demo    paso0..paso7_*.sh  comun.sh
Entorno             preparar.sh  restaurar.sh
Orquestador         demo.sh
Documentación       INSTALAR.md  RESULTADOS.md
```

Los resultados reales obtenidos en la VM están en **[RESULTADOS.md](RESULTADOS.md)**.

## Ámbito y ética

Todo corre en una **VM propia y aislada**, contra **procesos creados por la misma
demo**, con una **contraseña de prueba inventada** (`ClaveSecreta2026!`). Es un
ejercicio académico sobre manejo seguro de secretos en memoria; no ataca sistemas
ni datos de terceros.

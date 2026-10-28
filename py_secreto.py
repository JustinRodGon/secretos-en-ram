#!/usr/bin/env python3
"""py_secreto.py <modo> : modo = str | bytes_a_bytearray | bytearray_directo
Lee una contrasena, espera (FASE 1), intenta borrarla y espera de nuevo (FASE 2)."""
import gc, os, sys, time

modo = sys.argv[1]
if modo == "str":
    clave = input()                                              # str inmutable: no se puede sobrescribir
elif modo == "bytes_a_bytearray":
    clave = bytearray(sys.stdin.buffer.readline().rstrip(b"\n")) # pasa antes por un bytes inmutable
elif modo == "bytearray_directo":
    clave = bytearray(64)
    n = os.readv(0, [clave])                                     # el kernel escribe directo en el bytearray
    del clave[n:]
    if clave.endswith(b"\n"):
        del clave[-1:]

print("FASE1", flush=True)
time.sleep(3)

# --- intento de borrado ---
if isinstance(clave, bytearray):
    for i in range(len(clave)):                                  # sobrescribe en el sitio
        clave[i] = 0
else:
    del clave                                                    # solo elimina la referencia
gc.collect()

print("FASE2", flush=True)
time.sleep(8)

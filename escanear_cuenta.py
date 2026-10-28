#!/usr/bin/env python3
"""escanear_cuenta.py <PID> <secreto> : cuenta las copias del secreto en la memoria viva del proceso."""
import sys

pid, secreto = sys.argv[1], sys.argv[2].encode()
total, regiones = 0, []
with open(f"/proc/{pid}/maps") as maps, open(f"/proc/{pid}/mem", "rb", 0) as mem:
    for linea in maps:
        partes = linea.split()
        inicio, fin = (int(x, 16) for x in partes[0].split("-"))
        if "r" not in partes[1]:
            continue
        try:
            mem.seek(inicio)
            n = mem.read(fin - inicio).count(secreto)
        except (OSError, ValueError, OverflowError):
            continue
        if n:
            total += n
            regiones.append(f"{partes[5] if len(partes) > 5 else '[anonima]'} x{n}")
print(f"    copias: {total}" + (f"  ({', '.join(regiones)})" if regiones else ""))

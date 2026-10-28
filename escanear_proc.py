#!/usr/bin/env python3
"""escanear_proc.py <PID> <secreto>
Lee la memoria viva del proceso (/proc/PID/mem) region por region
y reporta en cual region ([heap], [stack], anonima...) aparece el secreto."""
import sys

pid, secreto = sys.argv[1], sys.argv[2].encode()
encontrado = {}

with open(f"/proc/{pid}/maps") as maps, open(f"/proc/{pid}/mem", "rb", 0) as mem:
    for linea in maps:                                  # cada linea describe una region de memoria
        partes = linea.split()
        inicio, fin = (int(x, 16) for x in partes[0].split("-"))
        permisos = partes[1]
        nombre = partes[5] if len(partes) > 5 else "[anonima]"
        if "r" not in permisos:                         # solo regiones legibles
            continue
        try:
            mem.seek(inicio)
            datos = mem.read(fin - inicio)
        except (OSError, ValueError, OverflowError):    # regiones especiales como [vvar] no se pueden leer
            continue
        n = datos.count(secreto)
        if n:
            encontrado[nombre] = encontrado.get(nombre, 0) + n

if encontrado:
    for nombre, n in encontrado.items():
        print(f"    ENCONTRADA {n}x en {nombre}")
else:
    print("    no aparece en ninguna region")

# Secretos en RAM

ITI-922 Seguridad de TI II — Universidad Técnica Nacional. Unidad III, Proyecto 3, Grupo 3.

Demo en vivo (9 minutos) que muestra por qué un programa debe borrar sus secretos de la memoria:

1. Un programa en C que no borra la contraseña: se encuentra en su volcado de memoria (`gcore`).
2. Las correcciones con `mlock`, `explicit_bzero` y `read(2)`, y por qué la primera todavía filtra una copia.
3. Python: `str` frente a `bytearray`.
4. Volcado por falla (*core dump*) y `ulimit -c 0`.
5. TPM emulado (swtpm): qué sobrevive al reinicio y qué se pierde.

Todo corre en una VM propia, contra procesos creados por la demo, con una contraseña de prueba inventada (`ClaveSecreta2026!`).

- Instalación: [INSTALAR.md](INSTALAR.md)

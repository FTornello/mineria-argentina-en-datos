"""Saca del PDF de metodología de SIACAM la lista de productos mineros.

La Secretaría de Minería define qué posiciones arancelarias (NCM) cuenta como
minería y a qué rubro y grupo pertenece cada una (por ejemplo, 71081210 es
Metalíferos / Oro). La lista está en una tabla de 28 páginas dentro del PDF
"Metodología del comercio exterior de minerales del SIACAM". Este script la
convierte en data/ncm_minero_siacam.csv, que sí va al repositorio.

Con esa lista se clasifican las exportaciones del INDEC igual que lo hace la
Secretaría, y por eso se pueden comparar las dos fuentes.

Cómo lee la tabla: cada producto empieza con una línea de 8 dígitos; siguen las
líneas de la descripción, después una línea con el rubro y al final el grupo.
"""
import csv
import re
from pathlib import Path

import fitz  # PyMuPDF

RAIZ = Path(__file__).resolve().parent.parent
PDF = RAIZ / "data" / "raw" / "siacam" / "Comercio" / "Metodologia-comercio-minerales.pdf"
SALIDA = RAIZ / "data" / "ncm_minero_siacam.csv"

RUBROS = ("Metalíferos", "No metalíferos", "Rocas de aplicación", "Combustibles")

# Tres productos en los que el PDF trae rubro y grupo en la misma línea y no
# se pueden separar solos. Se cargan a mano, copiados del PDF.
A_MANO = {
    "27011900": ("Las demás hullas, incluso pulverizadas, pero sin aglomerar:", "Combustibles", "Hullas"),
    "71031000": ("Piedras preciosas o semipreciosas naturales, en bruto o simplemente aserradas o desbastadas",
                 "Piedras preciosas o semipreciosas", "Piedras preciosas o semipreciosas"),
    "71039900": ("Las demás piedras preciosas o semipreciosas, trabajadas de otro modo",
                 "Piedras preciosas o semipreciosas", "Piedras preciosas o semipreciosas"),
}

lineas = []
for pagina in fitz.open(PDF):
    for linea in pagina.get_text().split("\n"):
        linea = linea.strip()
        es_pie = linea.startswith("Comercio exterior del SIACAM") or re.fullmatch(r"\d{1,2}", linea)
        if linea and not es_pie:
            lineas.append(linea)

productos = []
actual = None
for linea in lineas:
    if re.fullmatch(r"\d{8}", linea):
        actual = {"ncm": linea, "descripcion": [], "rubro": None, "grupo": []}
        productos.append(actual)
    elif actual is None:
        continue  # texto anterior a la tabla
    elif actual["rubro"] is None and linea in RUBROS:
        actual["rubro"] = linea
    elif actual["rubro"] is None:
        actual["descripcion"].append(linea)
    else:
        actual["grupo"].append(linea)

with open(SALIDA, "w", newline="", encoding="utf-8") as salida:
    escritor = csv.writer(salida)
    escritor.writerow(["ncm", "descripcion", "rubro", "grupo"])
    for producto in productos:
        if producto["ncm"] in A_MANO:
            descripcion, rubro, grupo = A_MANO[producto["ncm"]]
        else:
            descripcion = " ".join(producto["descripcion"])
            rubro = producto["rubro"]
            grupo = " ".join(producto["grupo"])
        if not rubro or not grupo:
            raise ValueError(f"Producto sin rubro o grupo: {producto}")
        escritor.writerow([producto["ncm"], descripcion, rubro, grupo])

print(f"{len(productos)} productos -> {SALIDA}")

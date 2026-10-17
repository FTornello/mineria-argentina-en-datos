"""Junta los ZIP anuales del INDEC en un solo CSV para cargar en la base.

Cada ZIP trae las exportaciones de un año, una fila por producto (NCM a 8
dígitos), país de destino y mes, con kilos y dólares FOB. Este script no cambia
ningún valor: solo saca los espacios de relleno y agrega de qué archivo salió
cada fila. Los números siguen como texto, con coma decimal y con la "s" del
secreto estadístico; eso se interpreta después, en la capa limpia.

Desde 2018 cada ZIP trae dos tablas con las mismas operaciones. Se usa la que
"prioriza NCM" (exponm), que es la que conserva exacto el total de cada
producto: los destinos tapados se compensan con una fila de país 999.

También arma totales_control.csv con el total de filas que el propio INDEC
declara para cada año, que después se usa como control de la carga.

Salidas en data/raw/indec/: exportaciones_ncm_pais_mes.csv y totales_control.csv
"""
import csv
import re
import zipfile
from pathlib import Path

CARPETA = Path(__file__).resolve().parent.parent / "data" / "raw" / "indec"


def tabla_de_datos(nombres):
    """Elige la tabla de exportaciones del ZIP: exponmAA.csv o, antes de 2018, expomAA.csv."""
    for patron in (r"exponm\d\d\.csv", r"expom\d\d\.csv"):
        for nombre in nombres:
            if re.fullmatch(patron, nombre.lower()):
                return nombre
    raise ValueError(f"No encuentro la tabla de exportaciones entre {nombres}")


def tabla_de_totales(nombres):
    for patron in (r"etotnm\d\d\.csv", r"etotm\d\d\.csv"):
        for nombre in nombres:
            if re.fullmatch(patron, nombre.lower()):
                return nombre
    raise ValueError(f"No encuentro la tabla de totales entre {nombres}")


filas_totales = 0
with open(CARPETA / "exportaciones_ncm_pais_mes.csv", "w", newline="", encoding="utf-8") as salida, \
     open(CARPETA / "totales_control.csv", "w", newline="", encoding="utf-8") as control:
    datos = csv.writer(salida)
    datos.writerow(["anio", "mes", "ncm", "pais", "peso_neto_kg", "fob_usd", "archivo"])
    totales = csv.writer(control)
    totales.writerow(["anio", "registros", "peso_neto_kg", "fob_usd", "archivo"])

    for ruta in sorted(CARPETA.glob("exports_*_M.zip")):
        with zipfile.ZipFile(ruta) as comprimido:
            nombre = tabla_de_datos(comprimido.namelist())
            lineas = comprimido.read(nombre).decode("latin-1").splitlines()
            for linea in lineas[1:]:
                campos = [campo.strip() for campo in linea.split(";")]
                if len(campos) >= 6 and campos[0]:
                    datos.writerow(campos[:6] + [nombre])
                    filas_totales += 1

            nombre_totales = tabla_de_totales(comprimido.namelist())
            fila = comprimido.read(nombre_totales).decode("latin-1").splitlines()[1]
            campos = [campo.strip() for campo in fila.split(";")]
            totales.writerow([campos[1], campos[3], campos[4], campos[5], nombre_totales])
        print(f"{ruta.name}: {nombre}, {len(lineas) - 1} filas")

print(f"{filas_totales} filas -> {CARPETA / 'exportaciones_ncm_pais_mes.csv'}")

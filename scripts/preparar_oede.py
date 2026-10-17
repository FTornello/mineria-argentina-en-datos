"""Pasa a CSV los Excel provinciales del OEDE (Ministerio de Trabajo).

El OEDE publica el empleo y los salarios registrados del sector privado en
Excel con una hoja por provincia y una columna por mes (o trimestre), desde
1995. Así no se pueden cargar en la base. Este script los pasa a formato
largo: una fila por provincia, rama y período. No cambia ningún valor; las
celdas vacías o con "s.d." (sin dato, por secreto estadístico) no se copian.

Las ramas están a cuatro dígitos de la clasificación CIIU revisión 3. Las de
minería empiezan con 10 a 14 (por ejemplo 1320: minerales metalíferos no
ferrosos).

Salidas en data/raw/oede/convertidos/.
"""
import csv
from pathlib import Path

import pandas as pd

OEDE = Path(__file__).resolve().parent.parent / "data" / "raw" / "oede"
SALIDA = OEDE / "convertidos"
SALIDA.mkdir(exist_ok=True)

# archivo Excel -> (CSV de salida, nombre de la columna del valor)
ARCHIVOS = {
    "provinciales_serie_remuneraciones_mensual_4dig_8.xlsx": ("remuneraciones_provincia_rama_mensual.csv", "remuneracion"),
    "provinciales_serie_empleo_trimestral_4dig_8.xlsx": ("empleo_provincia_rama_trimestral.csv", "empleo"),
}
HOJAS_QUE_NO_SON_PROVINCIAS = {"Carátula", "Indice", "Metodología"}

def texto_periodo(periodo):
    """Los meses vienen como fecha y los trimestres como texto ("1° Trim 2026")."""
    if hasattr(periodo, "strftime"):
        return periodo.strftime("%Y-%m-%d")
    return str(periodo).strip()


for excel, (destino, columna) in ARCHIVOS.items():
    libro = pd.ExcelFile(OEDE / excel)
    filas = 0
    with open(SALIDA / destino, "w", newline="", encoding="utf-8") as salida:
        escritor = csv.writer(salida)
        escritor.writerow(["provincia", "rama", "descripcion", "periodo", columna])
        for hoja in libro.sheet_names:
            if hoja in HOJAS_QUE_NO_SON_PROVINCIAS:
                continue
            tabla = libro.parse(hoja, header=None, dtype=object)
            # Los dos archivos no empiezan en la misma columna. Se busca la celda
            # que dice "Ramas": esa columna tiene el código, la siguiente la
            # descripción y de ahí en adelante hay una columna por período.
            fila_encabezado, col = next(
                (i, c) for c in (0, 1, 2) for i, valor in enumerate(tabla[c])
                if str(valor).strip().lower() == "ramas")
            periodos = tabla.iloc[fila_encabezado, col + 2:]
            for _, fila in tabla.iloc[fila_encabezado + 1:].iterrows():
                rama, descripcion = fila[col], fila[col + 1]
                if pd.isna(rama) or pd.isna(descripcion):
                    continue
                for periodo, valor in zip(periodos, fila[col + 2:]):
                    if pd.isna(periodo) or pd.isna(valor) or isinstance(valor, str):
                        continue
                    escritor.writerow([hoja, str(rama).strip(), str(descripcion).strip(), texto_periodo(periodo), valor])
                    filas += 1
    print(f"{destino}: {filas} filas")

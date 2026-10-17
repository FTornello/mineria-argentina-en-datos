"""Pasa a CSV los Excel de SIACAM que se cargan en la base.

Los Excel no se pueden cargar directo en PostgreSQL. Este script copia la hoja
de datos de cada uno a un CSV, sin cambiar valores: todas las celdas se leen
como texto. Solo descarta las filas totalmente vacías y las columnas sin
encabezado que algunos archivos traen de relleno.

Salidas en data/raw/siacam/convertidos/.
"""
from pathlib import Path

import pandas as pd

SIACAM = Path(__file__).resolve().parent.parent / "data" / "raw" / "siacam"
SALIDA = SIACAM / "convertidos"
SALIDA.mkdir(exist_ok=True)

# archivo Excel -> (hoja, nombre del CSV)
HOJAS = {
    "Cartera-de-Proyectos-Mineros-Metaliferos-y-Litio-del-SIACAM.xlsx": (0, "cartera_metaliferos_litio.csv"),
    "Cartera-de-Proyectos-Mineros-No-Metaliferos-y-Roca-de-Aplicacion-del-SIACAM.xlsx": (0, "cartera_no_metaliferos.csv"),
    "precios-internacionales-minerales.xlsx": ("Sheet1", "precios_internacionales.csv"),
    "Balance_cambiario_argentina.xlsx": ("LONG", "balance_cambiario.csv"),
}

for excel, (hoja, destino) in HOJAS.items():
    tabla = pd.read_excel(SIACAM / excel, sheet_name=hoja, dtype=str)
    tabla = tabla.loc[:, ~tabla.columns.astype(str).str.startswith("Unnamed")]
    tabla = tabla.dropna(how="all")
    tabla.to_csv(SALIDA / destino, index=False)
    print(f"{destino}: {len(tabla)} filas, {len(tabla.columns)} columnas")

"""Pasa a un CSV simple el tipo de cambio del Banco de Canadá.

El archivo que devuelve el Banco de Canadá trae varias líneas de descripción
antes de los datos. Este script copia solo la tabla de observaciones: fecha y
cuántos dólares canadienses vale un dólar estadounidense. No cambia valores.

Salida: data/raw/boc/fx_usdcad_diario.csv
"""
import csv
import io
from pathlib import Path

CARPETA = Path(__file__).resolve().parent.parent / "data" / "raw" / "boc"
texto = (CARPETA / "FXUSDCAD.csv").read_text(encoding="utf-8")
inicio = texto.find('"date","FXUSDCAD"')
filas = list(csv.reader(io.StringIO(texto[inicio:])))
with open(CARPETA / "fx_usdcad_diario.csv", "w", newline="", encoding="utf-8") as salida:
    escritor = csv.writer(salida)
    escritor.writerow(["fecha", "cad_por_usd"])
    escritor.writerows(fila[:2] for fila in filas[1:] if len(fila) >= 2 and fila[1])
print(f"{len(filas) - 1} días -> {CARPETA / 'fx_usdcad_diario.csv'}")

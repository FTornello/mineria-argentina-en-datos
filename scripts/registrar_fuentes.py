"""Deja constancia de qué archivos se descargaron y cuándo.

Las fuentes se actualizan todos los meses y los archivos originales no se suben
al repositorio. Este script recorre data/raw/ y escribe data/FUENTES.csv con,
para cada archivo: de dónde salió, fecha de descarga, tamaño, cantidad de filas
y una huella (SHA-256) que cambia si cambia el contenido. Así se puede saber si
una descarga nueva es igual a la del análisis.

Los archivos que arman los scripts de preparación (el CSV unificado del INDEC y
los Excel pasados a CSV) también se registran, marcados como "derivado".

Correr después de scripts/descargar_datos.sh.
"""
import csv
import hashlib
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CRUDOS = RAIZ / "data" / "raw"
SALIDA = RAIZ / "data" / "FUENTES.csv"

DERIVADOS = {"exportaciones_ncm_pais_mes.csv", "totales_control.csv"}


def origen(ruta):
    """Devuelve (organismo, url, tipo) según la carpeta del archivo."""
    relativa = ruta.relative_to(CRUDOS)
    if relativa.parts[0] == "indec":
        if ruta.name in DERIVADOS:
            return "INDEC", "armado por scripts/preparar_indec.py", "derivado"
        return "INDEC", f"https://comex.indec.gob.ar/files/zips/{ruta.name}", "original"
    if relativa.parts[0] == "siacam":
        if relativa.parts[1] == "convertidos":
            return "Secretaría de Minería (SIACAM)", "armado por scripts/preparar_siacam.py", "derivado"
        resto = "/".join(relativa.parts[1:])
        return "Secretaría de Minería (SIACAM)", f"https://www.mecon.gob.ar/dataset/{resto}", "original"
    if relativa.parts[0] == "comtrade":
        if ruta.suffix == ".csv":
            return "UN Comtrade", "armado por scripts/descargar_comtrade.py", "derivado"
        if ruta.name == "Reporters.json":
            return "UN Comtrade", "https://comtradeapi.un.org/files/v1/app/reference/Reporters.json", "original"
        if ruta.name.startswith("EEUU_CL_"):
            return "UN Comtrade", f"consulta pública, importaciones de EE.UU. desde Chile, {ruta.stem[-4:]}", "original"
        frecuencia, periodo = ruta.stem.split("_")
        return "UN Comtrade", f"consulta pública, importaciones desde Argentina, {frecuencia} {periodo}", "original"
    if relativa.parts[0] == "oede":
        if relativa.parts[1] == "convertidos":
            return "OEDE, Ministerio de Trabajo", "armado por scripts/preparar_oede.py", "derivado"
        return "OEDE, Ministerio de Trabajo", f"https://www.argentina.gob.ar/sites/default/files/{ruta.name}", "original"
    if relativa.parts[0] == "caem":
        return "CAEM", f"https://caem.com.ar/storage/2026/05/{ruta.name}", "original"
    if relativa.parts[0] == "empresas":
        return relativa.parts[1].capitalize(), "informe anual, página de inversores de la empresa (ver scripts/descargar_datos.sh)", "original"
    if relativa.parts[0] == "sanjuan_hacienda":
        return "Ministerio de Hacienda de San Juan", "https://web.sanjuan.gob.ar/hacienda/transparencia/ (lista en scripts/sanjuan_hacienda_archivos.txt)", "original"
    if relativa.parts[0] == "bna":
        return "datos.gob.ar, series de tiempo", "serie 168.1_T_CAMBIOR_D_0_0_26, tipo de cambio BNA vendedor, promedio mensual", "original"
    if relativa.parts[0] == "estma":
        return "Natural Resources Canada / Statistics Canada (ESTMA)", "https://www150.statcan.gc.ca/n1/pub/71-607-x/2022008/STC_DF_ESTMA-eng.csv", "original"
    if relativa.parts[0] == "boc":
        if ruta.name == "fx_usdcad_diario.csv":
            return "Banco de Canadá", "armado por scripts/preparar_boc.py", "derivado"
        return "Banco de Canadá", "https://www.bankofcanada.ca/valet/observations/FXUSDCAD/csv", "original"
    if relativa.parts[0] == "geo":
        return "Instituto Geográfico Nacional (vía argentina.gob.ar)", "https://www.argentina.gob.ar/profiles/argentinagobar/themes/contrib/poncho/resources/jsons/geo-provincias-argentinas.json", "original"
    return "", "", "original"


def describir(ruta):
    contenido = ruta.read_bytes()
    organismo, url, tipo = origen(ruta)
    return {
        "archivo": str(ruta.relative_to(CRUDOS)),
        "organismo": organismo,
        "tipo": tipo,
        "url": url,
        "descargado": datetime.fromtimestamp(ruta.stat().st_mtime).strftime("%Y-%m-%d"),
        "tamano_mb": round(len(contenido) / 1_048_576, 2),
        "filas": contenido.count(b"\n") - 1 if ruta.suffix == ".csv" else "",
        "sha256": hashlib.sha256(contenido).hexdigest(),
    }


archivos = sorted(a for a in CRUDOS.rglob("*") if a.is_file() and a.name != ".DS_Store")
registro = [describir(a) for a in archivos]
with open(SALIDA, "w", newline="", encoding="utf-8") as salida:
    escritor = csv.DictWriter(salida, fieldnames=list(registro[0]))
    escritor.writeheader()
    escritor.writerows(registro)
print(f"{len(registro)} archivos registrados -> {SALIDA}")

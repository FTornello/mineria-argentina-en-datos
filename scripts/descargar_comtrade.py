"""Baja de UN Comtrade lo que otros países declaran importar desde Argentina.

Son los "datos espejo": la exportación argentina vista desde la aduana del
país comprador. Sirven para dos cosas. Primero, para saber a dónde va lo que
el INDEC tapa por secreto estadístico desde 2018. Segundo, como comprobación
independiente: es otro organismo, en otro país, contando la misma mercadería.

Qué se baja: importaciones (flujo M) con Argentina como país de origen, para
los diez productos de PRODUCTOS, de todos los países que informan.
  - Anual, 2002 a 2025.
  - Mensual, desde enero de 2018 (cuando empieza el secreto estadístico).

La consulta pública de Comtrade no pide clave, pero acepta un solo período por
pedido y devuelve hasta 500 filas. Por eso se hace un pedido por año y uno por
mes, con una pausa entre pedidos. Cada respuesta se guarda tal cual en
data/raw/comtrade/ y al final se arma un CSV con todas juntas.

Si un período ya está bajado no se vuelve a pedir; para refrescarlo hay que
borrar su archivo.

Cuidados al leer estos datos:
  - Los productos están a 6 dígitos (el INDEC publica a 8). 282739 son "los
    demás cloruros": incluye el cloruro de litio pero también otros.
  - Las importaciones se declaran en valor CIF (con flete y seguro) y en la
    fecha de llegada, no en la de salida.
  - No todos los países informan todos los meses.
"""
import csv
import json
import time
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path

CARPETA = Path(__file__).resolve().parent.parent / "data" / "raw" / "comtrade"
CARPETA.mkdir(parents=True, exist_ok=True)

API = "https://comtradeapi.un.org/public/v1/preview/C"
REFERENCIA_PAISES = "https://comtradeapi.un.org/files/v1/app/reference/Reporters.json"
ARGENTINA = 32
PRODUCTOS = {
    "710812": "Oro en bruto, uso no monetario",
    "710691": "Plata en bruto",
    "261610": "Minerales de plata y sus concentrados",
    "260300": "Minerales de cobre y sus concentrados",
    "283691": "Carbonatos de litio",
    "282520": "Óxido e hidróxido de litio",
    "282739": "Los demás cloruros (incluye cloruro de litio)",
    "260700": "Minerales de plomo y sus concentrados",
    "260800": "Minerales de cinc y sus concentrados",
    "261390": "Minerales de molibdeno sin tostar",
}
PRIMER_ANIO = 2002
PRIMER_MES = (2018, 1)
PAUSA_SEGUNDOS = 2.5
MAXIMO_FILAS = 500

COLUMNAS = ["freqCode", "period", "refYear", "refMonth", "reporterCode", "partnerCode", "flowCode",
            "cmdCode", "qtyUnitCode", "qty", "netWgt", "cifvalue", "fobvalue", "primaryValue"]


def pedir(url):
    """Hace el pedido y reintenta si el servidor pide esperar o falla."""
    for intento in range(6):
        try:
            pedido = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(pedido, timeout=90) as respuesta:
                return respuesta.read()
        except urllib.error.HTTPError as error:
            if error.code not in (429, 500, 502, 503, 504):
                raise
        except (urllib.error.URLError, TimeoutError):
            pass
        time.sleep(20 * (intento + 1))
    raise RuntimeError(f"Sin respuesta después de 6 intentos: {url}")


def bajar_periodo(frecuencia, periodo):
    destino = CARPETA / f"{frecuencia}_{periodo}.json"
    if destino.exists():
        return
    url = (f"{API}/{frecuencia}/HS?partnerCode={ARGENTINA}&flowCode=M&period={periodo}"
           f"&cmdCode={','.join(PRODUCTOS)}&partner2Code=0&customsCode=C00&motCode=0")
    contenido = pedir(url)
    filas = json.loads(contenido).get("data", [])
    if len(filas) >= MAXIMO_FILAS:
        raise RuntimeError(f"{frecuencia} {periodo}: llegó al tope de {MAXIMO_FILAS} filas, hay que partir el pedido")
    destino.write_bytes(contenido)
    print(f"{frecuencia} {periodo}: {len(filas)} filas")
    time.sleep(PAUSA_SEGUNDOS)


hoy = date.today()
for anio in range(PRIMER_ANIO, hoy.year):
    bajar_periodo("A", anio)

anio, mes = PRIMER_MES
while (anio, mes) < (hoy.year, hoy.month):
    bajar_periodo("M", f"{anio}{mes:02d}")
    anio, mes = (anio, mes + 1) if mes < 12 else (anio + 1, 1)

# Comparación: a qué precio importa Estados Unidos carbonato de litio de Chile.
# Sirve para saber si el precio que paga por el litio argentino es bajo para
# cualquier proveedor o solo para la Argentina. Un pedido por año.
ESTADOS_UNIDOS, CHILE = 842, 152
for anio in range(2012, hoy.year):
    destino = CARPETA / f"EEUU_CL_{anio}.json"
    if destino.exists():
        continue
    url = (f"{API}/A/HS?reporterCode={ESTADOS_UNIDOS}&partnerCode={CHILE}&flowCode=M&period={anio}"
           f"&cmdCode=283691&partner2Code=0&customsCode=C00&motCode=0")
    destino.write_bytes(pedir(url))
    print(f"EEUU desde Chile {anio}")
    time.sleep(PAUSA_SEGUNDOS)

with open(CARPETA / "importaciones_eeuu_desde_chile.csv", "w", newline="", encoding="utf-8") as salida:
    escritor = csv.writer(salida)
    escritor.writerow(COLUMNAS + ["archivo"])
    for archivo in sorted(CARPETA.glob("EEUU_CL_*.json")):
        for fila in json.loads(archivo.read_text(encoding="utf-8")).get("data", []):
            escritor.writerow([fila.get(columna) for columna in COLUMNAS] + [archivo.name])

# Nombres de los países que informan.
paises = CARPETA / "Reporters.json"
if not paises.exists():
    paises.write_bytes(pedir(REFERENCIA_PAISES))
with open(CARPETA / "paises_comtrade.csv", "w", newline="", encoding="utf-8") as salida:
    escritor = csv.writer(salida)
    escritor.writerow(["reporterCode", "pais", "iso3"])
    for pais in json.loads(paises.read_text(encoding="utf-8-sig"))["results"]:
        escritor.writerow([pais["reporterCode"], pais["reporterDesc"], pais.get("reporterCodeIsoAlpha3", "")])

# Todas las respuestas en un solo CSV, sin cambiar valores.
total = 0
with open(CARPETA / "importaciones_desde_argentina.csv", "w", newline="", encoding="utf-8") as salida:
    escritor = csv.writer(salida)
    escritor.writerow(COLUMNAS + ["archivo"])
    for archivo in sorted(CARPETA.glob("[AM]_*.json")):
        for fila in json.loads(archivo.read_text(encoding="utf-8")).get("data", []):
            escritor.writerow([fila.get(columna) for columna in COLUMNAS] + [archivo.name])
            total += 1
print(f"{total} filas -> {CARPETA / 'importaciones_desde_argentina.csv'}")

with open(CARPETA / "productos_comtrade.csv", "w", newline="", encoding="utf-8") as salida:
    escritor = csv.writer(salida)
    escritor.writerow(["cmdCode", "descripcion"])
    escritor.writerows(PRODUCTOS.items())

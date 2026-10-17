"""Achica el mapa oficial de provincias para poder meterlo en las páginas.

El archivo del Instituto Geográfico Nacional que publica argentina.gob.ar pesa
2,3 MB: demasiado para una página. Este script:
  - descarta la Antártida, las islas al sur del paralelo 56 y las Georgias
    del Sur (al este del meridiano 53);
  - descarta la Ciudad de Buenos Aires: el archivo la trae ampliada, como un
    recuadro dibujado sobre el mar, y a esta escala no se vería;
  - simplifica cada contorno con el algoritmo de Douglas-Peucker (saca los
    puntos que casi no cambian la forma, con una tolerancia de 0,04 grados,
    unos 4 km);
  - redondea las coordenadas a dos decimales.

Salida: data/mapa_provincias.json, que sí va al repositorio.
"""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "data" / "raw" / "geo" / "geo-provincias-argentinas.json"
SALIDA = RAIZ / "data" / "mapa_provincias.json"
TOLERANCIA = 0.04


def distancia(p, a, b):
    """Distancia del punto p a la recta que pasa por a y b."""
    (x, y), (x1, y1), (x2, y2) = p, a, b
    if (x1, y1) == (x2, y2):
        return ((x - x1) ** 2 + (y - y1) ** 2) ** 0.5
    return abs((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1) / ((y2 - y1) ** 2 + (x2 - x1) ** 2) ** 0.5


def simplificar(puntos):
    if len(puntos) < 3:
        return puntos
    mayor, indice = 0, 0
    for i in range(1, len(puntos) - 1):
        d = distancia(puntos[i], puntos[0], puntos[-1])
        if d > mayor:
            mayor, indice = d, i
    if mayor <= TOLERANCIA:
        return [puntos[0], puntos[-1]]
    return simplificar(puntos[:indice + 1])[:-1] + simplificar(puntos[indice:])


provincias = []
for f in json.loads(ORIGEN.read_text(encoding="utf-8"))["features"]:
    nombre = f["properties"]["nam"]
    geometria = f["geometry"]
    if nombre.startswith("Ciudad"):
        continue
    poligonos = geometria["coordinates"] if geometria["type"] == "MultiPolygon" else [geometria["coordinates"]]
    anillos = []
    for poligono in poligonos:
        exterior = poligono[0]
        if min(p[1] for p in exterior) < -56 or max(p[0] for p in exterior) > -53:
            continue
        corto = simplificar([(p[0], p[1]) for p in exterior])
        if len(corto) >= 4:
            anillos.append([[round(x, 2), round(y, 2)] for x, y in corto])
    if anillos:
        provincias.append({"nombre": nombre, "anillos": anillos})

SALIDA.write_text(json.dumps(provincias, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
print(f"{len(provincias)} provincias, {SALIDA.stat().st_size / 1024:.0f} KB -> {SALIDA}")

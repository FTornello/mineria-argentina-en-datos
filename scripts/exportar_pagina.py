"""Saca de la base los datos que usan las páginas y las arma.

La página es un solo archivo HTML, sin conexión a nada: los datos van adentro.
Este script corre una consulta por gráfico contra la base `mineria` (cada una
sale de una pregunta de sql/analisis/, citada al lado), junta los resultados en
un JSON y lo inserta en cada plantilla de pagina/ donde dice /*DATOS*/, junto
con el estilo (estilo.css) y el código de los gráficos (graficos.js).

Correr después de scripts/reconstruir.sh, para que la página muestre los mismos
números que las consultas.
"""
import json
import subprocess
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PSQL = "/opt/homebrew/opt/postgresql@17/bin/psql"

CONSULTAS = {
    # P24: Cerro Negro, ley y toneladas.
    "cerro_negro": """
        SELECT anio,
               max(valor) FILTER (WHERE indicador = 'ley') AS ley,
               max(valor) FILTER (WHERE indicador = 'toneladas_procesadas') AS toneladas
        FROM mineria.operacion_mina WHERE mina = 'Cerro Negro'
        GROUP BY anio HAVING max(valor) FILTER (WHERE indicador = 'ley') IS NOT NULL
        ORDER BY anio""",
    # P25: margen por onza en Veladero.
    "veladero_margen": """
        SELECT o.anio, round(avg(p.precio)) AS precio, max(o.valor) AS aisc
        FROM mineria.operacion_mina o
        JOIN mineria.precio p ON p.mineral = 'Oro (Au)' AND extract(year FROM p.fecha) = o.anio
        WHERE o.mina = 'Veladero' AND o.indicador = 'aisc' AND o.anio >= 2017
        GROUP BY o.anio ORDER BY o.anio""",
    # P27: pagado al Estado como parte del valor producido.
    "pagos_oro": """
        WITH precio AS (SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS p
                        FROM mineria.precio WHERE mineral = 'Oro (Au)' GROUP BY 1),
             pagos AS (SELECT mina, anio, sum(usd) / 1e6 AS musd FROM mineria.pago_gobierno
                       WHERE sector = 'Minería' AND mina IN ('Cerro Negro', 'Cerro Vanguardia', 'Lindero')
                       GROUP BY 1, 2
                       UNION ALL SELECT mina, anio, millones_usd FROM mineria.contribucion_tributaria)
        SELECT g.mina, g.anio, round(m.produccion_total * p.p / 1000) AS valor_musd, round(g.musd) AS pagado_musd,
               round(100 * g.musd / (m.produccion_total * p.p / 1000), 1) AS pct
        FROM pagos g JOIN precio p USING (anio)
        JOIN mineria.produccion_mina m ON m.mina = g.mina AND m.anio = g.anio AND m.mineral = 'Oro'
        WHERE m.produccion_total IS NOT NULL AND g.anio >= 2022
        ORDER BY g.mina, g.anio""",
    # P07: destinos del litio.
    "litio_destinos": """
        WITH t AS (SELECT anio, sum(millones_usd) AS total FROM mineria.exportacion_litio_destino GROUP BY anio)
        SELECT d.anio, round(t.total) AS total_musd,
               round(100 * coalesce(sum(millones_usd) FILTER (WHERE destino = 'China'), 0) / t.total) AS china,
               round(100 * coalesce(sum(millones_usd) FILTER (WHERE destino = 'Estados Unidos'), 0) / t.total) AS eeuu,
               round(100 * coalesce(sum(millones_usd) FILTER (WHERE destino = 'Japon'), 0) / t.total) AS japon,
               round(100 * coalesce(sum(millones_usd) FILTER (WHERE destino = 'Corea, Republica de'), 0) / t.total) AS corea
        FROM mineria.exportacion_litio_destino d JOIN t USING (anio)
        WHERE d.anio >= 2012 GROUP BY d.anio, t.total ORDER BY d.anio""",
    # P21: precio al que llega a EE.UU. desde Argentina y desde Chile.
    "litio_eeuu": """
        WITH ar AS (SELECT extract(year FROM fecha)::int AS anio,
                           sum(valor_usd) / (sum(peso_neto_kg) / 1000) AS p
                    FROM mineria.importacion_espejo
                    WHERE frecuencia = 'A' AND hs6 = '283691' AND pais = 'USA' GROUP BY 1),
             ref AS (SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS p
                     FROM mineria.precio WHERE mineral LIKE 'Carbonato de Litio%' GROUP BY 1)
        SELECT ar.anio, round(ar.p) AS argentina, round(c.valor_usd / (c.peso_neto_kg / 1000)) AS chile,
               round(ref.p) AS referencia
        FROM ar JOIN mineria.litio_eeuu_desde_chile c USING (anio) LEFT JOIN ref USING (anio)
        ORDER BY ar.anio""",
    # P29 y P30: Olaroz y Cauchari-Olaroz.
    "litio_operaciones": """
        SELECT mina, to_char(periodo_inicio, 'MM/YYYY') || ' a ' || to_char(periodo_fin, 'MM/YYYY') AS periodo,
               ingresos_musd, ebitda_musd, resultado_bruto_musd, costos_financieros_musd, resultado_neto_musd
        FROM mineria.resultado_operacion ORDER BY mina DESC, periodo_inicio""",
    "olaroz_pagos": """
        SELECT anio, round(sum(usd) / 1e6, 1) AS musd FROM mineria.pago_gobierno
        WHERE mina = 'Olaroz' GROUP BY anio ORDER BY anio""",
    # P12: San Juan, exportaciones y puestos.
    "san_juan": """
        SELECT x.anio, round(x.millones_usd) AS exportado_musd, round(avg(e.empleo)) AS puestos
        FROM mineria.exportacion_provincia x
        LEFT JOIN mineria.empleo_rama e ON e.provincia = 'San Juan' AND e.rama = '1320'
             AND extract(year FROM e.fecha) = x.anio
        WHERE x.provincia = 'San Juan' AND x.anio BETWEEN 2003 AND 2025
        GROUP BY x.anio, x.millones_usd ORDER BY x.anio""",
    # P14: cuántas veces paga la minería el salario del resto.
    "salarios": """
        WITH s AS (SELECT extract(year FROM fecha)::int AS anio, rama, avg(salario) AS sal
                   FROM mineria.salario_rama WHERE provincia = 'San Juan'
                   AND extract(month FROM fecha) BETWEEN 1 AND 5 GROUP BY 1, 2),
             e AS (SELECT extract(year FROM fecha)::int AS anio, rama, empleo
                   FROM mineria.empleo_rama WHERE provincia = 'San Juan' AND extract(month FROM fecha) = 1)
        SELECT anio, round(max(sal) FILTER (WHERE rama = '1320')
               / (sum(sal * empleo) FILTER (WHERE rama <> '1320') / sum(empleo) FILTER (WHERE rama <> '1320')), 1) AS veces
        FROM s JOIN e USING (anio, rama) WHERE anio >= 2004 GROUP BY anio ORDER BY anio""",
    # P18: calendario de inversión del cobre.
    "rigi_calendario": """
        SELECT anio, max(musd) FILTER (WHERE rubro = 'Cobre') AS cobre,
               max(musd) FILTER (WHERE rubro = 'Litio') AS litio,
               max(musd) FILTER (WHERE rubro = 'Oro y plata') AS oro_plata
        FROM mineria.rigi_plan_inversion WHERE anio BETWEEN 2024 AND 2033 GROUP BY anio ORDER BY anio""",
    # P19: Catamarca después de Bajo la Alumbrera.
    "catamarca": """
        SELECT extract(year FROM fecha)::int AS anio,
               round(avg(m)) AS metaliferos, round(avg(l)) AS litio
        FROM (SELECT fecha, sum(puestos) FILTER (WHERE rubro = 'Metalíferos') AS m,
                     sum(puestos) FILTER (WHERE rubro = 'Litio') AS l
              FROM mineria.empleo WHERE provincia = 'Catamarca' GROUP BY fecha) x
        WHERE fecha < '2026-01-01' GROUP BY 1 ORDER BY 1""",
    # Mapa del oro: dónde está cada mina y cuánto produjo en 2015 y en 2025.
    # Los nombres de la producción y de la cartera de proyectos no siempre
    # coinciden, por eso la tabla de equivalencias.
    "oro_mapa": """
        WITH nombres(mina, proyecto, provincia) AS (VALUES
               ('Veladero', 'Veladero', 'San Juan'), ('Cerro Negro', 'Cerro Negro', 'Santa Cruz'),
               ('Cerro Vanguardia', 'Cerro Vanguardia', 'Santa Cruz'), ('Lindero', 'Lindero', 'Salta'),
               ('Cerro Moro', 'Cerro Moro', 'Santa Cruz'), ('San José', 'San José', 'Santa Cruz'),
               ('Gualcamayo', 'Gualcamayo / Carbonatos Profundos', 'San Juan'),
               ('Bajo la Alumbrera', 'Bajo de la Alumbrera', 'Catamarca'))
        SELECT n.mina, p.provincia, p.latitud AS lat, p.longitud AS lon,
               max(m.produccion_total) FILTER (WHERE m.anio = 2015) AS q2015,
               max(m.produccion_total) FILTER (WHERE m.anio = 2025) AS q2025,
               max(m.anio) FILTER (WHERE m.produccion_total IS NOT NULL) AS ultimo_anio
        FROM nombres n
        JOIN mineria.proyecto p ON p.nombre = n.proyecto AND p.provincia = n.provincia
        JOIN mineria.produccion_mina m ON m.mina = n.mina AND m.mineral = 'Oro'
        GROUP BY n.mina, p.provincia, p.latitud, p.longitud ORDER BY q2025 DESC NULLS LAST""",
    # P23: de dónde vino la caída entre 2015 y 2025 (cascada). "Resto" es la
    # diferencia entre el total del país y las minas nombradas.
    "oro_cascada": """
        WITH m AS (SELECT mina, coalesce(max(produccion_total) FILTER (WHERE anio = 2015), 0) AS a,
                          coalesce(max(produccion_total) FILTER (WHERE anio = 2025), 0) AS b
                   FROM mineria.produccion_mina
                   WHERE mineral = 'Oro' AND mina IN ('Cerro Negro', 'Veladero', 'Bajo la Alumbrera', 'Cerro Moro', 'Lindero')
                   GROUP BY mina),
             pais AS (SELECT max(produccion) FILTER (WHERE anio = 2015) AS a,
                             max(produccion) FILTER (WHERE anio = 2025) AS b
                      FROM mineria.produccion_anual WHERE mineral = 'Oro')
        SELECT 'Resto de las minas' AS mina, round(pais.a - sum(m.a)) AS q2015, round(pais.b - sum(m.b)) AS q2025
        FROM m CROSS JOIN pais GROUP BY pais.a, pais.b
        UNION ALL SELECT mina, round(a), round(b) FROM m
        UNION ALL SELECT 'País', a, b FROM pais""",
    # P31: Cerro Negro, producción de cada año contra lo prometido en 2023.
    "cerro_negro_promesa": """
        SELECT m.anio, m.produccion_total AS producido,
               CASE WHEN m.anio >= h.desde_anio THEN h.onzas_anunciadas_miles END AS prometido
        FROM mineria.produccion_mina m
        CROSS JOIN (SELECT * FROM mineria.hecho_mina WHERE mina = 'Cerro Negro' AND tipo = 'Promesa') h
        WHERE m.mina = 'Cerro Negro' AND m.mineral = 'Oro' AND m.anio >= 2015
        ORDER BY m.anio""",
    # Fechas para la línea de tiempo, con su fuente.
    "hechos": """
        SELECT mina, fecha, precision, tipo, descripcion, fuente FROM mineria.hecho_mina ORDER BY fecha""",
    # P32: cómo se detectó cada error.
    "correcciones": """
        SELECT numero, fecha, tipo, lo_que_se_dijo, lo_correcto, como_se_detecto, que_quedo
        FROM mineria.correccion_ia ORDER BY numero""",
    # P33: lo que publicó la prensa del litio en octubre de 2026, contra los datos.
    "litio_prensa": (RAIZ / "sql" / "analisis" / "p33_litio_la_prensa_contra_los_datos.sql").read_text(encoding="utf-8").rstrip().rstrip(";"),
    # P20 y P34: regalías de San Juan, y si se ve el empleo del cobre.
    "sj_regalias": (RAIZ / "sql" / "analisis" / "p20_cuanto_cobra_san_juan_de_regalias.sql").read_text(encoding="utf-8").rstrip().rstrip(";"),
    "sj_empleo_cobre": (RAIZ / "sql" / "analisis" / "p34_se_ve_el_empleo_del_cobre.sql").read_text(encoding="utf-8").rstrip().rstrip(";"),
    # Datos sueltos para las cifras destacadas.
    "cifras": """
        SELECT json_build_object(
          'puestos_metal_sj_2026', (SELECT empleo FROM mineria.empleo_rama WHERE provincia = 'San Juan' AND rama = '1320' AND fecha = '2026-01-01'),
          'puestos_privados_sj_2026', (SELECT round(sum(empleo)) FROM mineria.empleo_rama WHERE provincia = 'San Juan' AND fecha = '2026-01-01'),
          'rigi_empleos_sj', (SELECT sum(empleos) FROM mineria.rigi_proyecto WHERE provincia = 'San Juan' AND sector = 'Minería'),
          'rigi_inversion_sj', (SELECT sum(inversion_musd) FROM mineria.rigi_proyecto WHERE provincia = 'San Juan' AND sector = 'Minería'),
          'expo_mineria_2025', (SELECT round(sum(fob_usd) / 1e6) FROM mineria.exportacion_siacam WHERE fecha BETWEEN '2025-01-01' AND '2025-12-01'),
          'controles', 63,
          'preguntas', 34)""",
}


def consultar(sql):
    envuelto = f"SELECT coalesce(json_agg(t), '[]') FROM ({sql}) t" if not sql.strip().startswith("SELECT json_build_object") else sql
    salida = subprocess.run([PSQL, "-d", "mineria", "-At", "-v", "ON_ERROR_STOP=1", "-c", envuelto],
                            check=True, capture_output=True, text=True).stdout
    return json.loads(salida)


datos = {nombre: consultar(sql) for nombre, sql in CONSULTAS.items()}
# Contorno de las provincias, ya simplificado por scripts/preparar_mapa.py.
datos["mapa"] = json.loads((RAIZ / "data" / "mapa_provincias.json").read_text(encoding="utf-8"))
estilo = (RAIZ / "pagina" / "estilo.css").read_text(encoding="utf-8")
graficos = (RAIZ / "pagina" / "graficos.js").read_text(encoding="utf-8")
bloque_datos = "const DATOS = " + json.dumps(datos, ensure_ascii=False) + ";"

# plantilla -> página que se genera. Todas comparten estilo, gráficos y datos.
PAGINAS = {
    "plantilla_nota_oro.html": "notas/oro.html",
    "plantilla_nota_litio.html": "notas/litio.html",
    "plantilla_nota_san_juan.html": "notas/san-juan.html",
    "plantilla_portada.html": "index.html",
}
for plantilla, destino in PAGINAS.items():
    texto = (RAIZ / "pagina" / plantilla).read_text(encoding="utf-8")
    texto = texto.replace("/*ESTILO*/", estilo).replace("/*GRAFICOS*/", graficos).replace("/*DATOS*/", bloque_datos)
    salida = RAIZ / "pagina" / destino
    salida.parent.mkdir(exist_ok=True)
    salida.write_text(texto, encoding="utf-8")
    print(f"{plantilla} -> pagina/{destino}")

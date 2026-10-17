-- P21. Estados Unidos pagó muy poco por el litio argentino durante la suba de
-- precios (P09). ¿Le pagó igual de poco a Chile?
--
-- Cómo: comparo, según la aduana de Estados Unidos, el precio promedio por
-- tonelada del carbonato de litio que importó desde Argentina y desde Chile,
-- año por año. Mismo comprador, mismo producto, dos proveedores. Agrego el
-- precio de referencia en Asia.
--
-- Contexto verificado en prensa: en julio de 2022 la Aduana argentina denunció
-- a Livent, que exporta desde Catamarca, por declarar ventas a 5.100 dólares
-- la tonelada en 403 operaciones de 2018 y 2019, y un mes antes había fijado
-- un precio de referencia de 53.000 (Bloomberg Línea, 14-7-2022).
--
-- Límites: los datos no dicen qué empresa vende ni a quién; que la diferencia
-- se deba a ventas entre empresas del mismo grupo es una lectura, apoyada en
-- esa denuncia. Tampoco distinguen calidades del producto.

WITH argentina AS (
    SELECT extract(year FROM fecha)::int AS anio,
           sum(peso_neto_kg) / 1000                   AS toneladas,
           sum(valor_usd) / (sum(peso_neto_kg) / 1000) AS usd_por_ton
    FROM mineria.importacion_espejo
    WHERE frecuencia = 'A' AND hs6 = '283691' AND pais = 'USA'
    GROUP BY 1
),
referencia AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_ton
    FROM mineria.precio WHERE mineral LIKE 'Carbonato de Litio%' GROUP BY 1
)
SELECT a.anio,
       round(a.toneladas)                          AS ton_desde_argentina,
       round(a.usd_por_ton)                        AS precio_argentina,
       round(c.peso_neto_kg / 1000)                AS ton_desde_chile,
       round(c.valor_usd / (c.peso_neto_kg / 1000)) AS precio_chile,
       round(100 * a.usd_por_ton / (c.valor_usd / (c.peso_neto_kg / 1000))) AS argentina_pct_de_chile,
       round(r.usd_por_ton)                        AS referencia_asia
FROM argentina a
JOIN mineria.litio_eeuu_desde_chile c USING (anio)
LEFT JOIN referencia r USING (anio)
ORDER BY a.anio;

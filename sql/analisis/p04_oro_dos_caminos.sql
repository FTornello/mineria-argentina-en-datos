-- P04. ¿Coinciden las fuentes sobre la caída de la producción de oro?
--
-- Cómo: comparo tres medidas independientes del volumen de oro, año por año.
--   1. onzas_caem: lo que suman los informes de las empresas (CAEM).
--   2. onzas_implicitas: los dólares exportados divididos por el precio
--      promedio del año. Es cuántas onzas "caben" en lo que se exportó.
--   3. indice_dore: el índice oficial de producción de bullón dorado
--      (Secretaría de Minería), que empieza en 2017.
-- Si las tres bajan parecido, la caída no depende de una sola fuente.
-- Resultado al 13-10-2026: las dos primeras coinciden (caen a 61 y 66); el
-- índice oficial cae mucho más (a 23) y no sé por qué.
-- Para compararlas las llevo a índice con base 2017 = 100.
--
-- Límite: las onzas implícitas salen algo distintas de las de CAEM porque el
-- oro exportado incluye la plata que va dentro del doré y porque producción y
-- embarque no caen en el mismo mes.

WITH precio AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_onza
    FROM mineria.precio WHERE mineral = 'Oro (Au)' GROUP BY 1
),
exportado AS (
    SELECT extract(year FROM fecha)::int AS anio, sum(fob_usd) AS usd
    FROM mineria.exportacion_siacam WHERE grupo = 'Oro' GROUP BY 1
),
dore AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(indice) AS indice
    FROM mineria.indice_produccion WHERE rama LIKE 'Bullón Dorado%' GROUP BY 1
),
datos AS (
    SELECT c.anio,
           c.produccion                         AS onzas_caem,
           e.usd / p.usd_por_onza / 1000        AS onzas_implicitas,
           d.indice                             AS indice_dore
    FROM mineria.produccion_anual c
    JOIN precio p USING (anio)
    JOIN exportado e USING (anio)
    LEFT JOIN dore d USING (anio)
    WHERE c.mineral = 'Oro'
),
base AS (SELECT * FROM datos WHERE anio = 2017)
SELECT d.anio,
       d.onzas_caem                                        AS miles_onzas_caem,
       round(d.onzas_implicitas)                           AS miles_onzas_implicitas,
       round(100 * d.onzas_implicitas / d.onzas_caem)      AS implicitas_pct_de_caem,
       round(100 * d.onzas_caem / b.onzas_caem)            AS caem_base_2017,
       round(100 * d.onzas_implicitas / b.onzas_implicitas) AS implicitas_base_2017,
       round(100 * d.indice_dore / b.indice_dore)          AS dore_base_2017
FROM datos d
CROSS JOIN base b
ORDER BY d.anio;

-- P03. El oro exportado pasó de 2.156 millones de dólares en 2019 a 4.094 en
-- 2025. ¿Cuánto de esa suba es precio y cuánto es producción?
--
-- Cómo: para cada año junto tres datos de fuentes distintas: las onzas
-- producidas (CAEM), el precio promedio del año (SIACAM) y los dólares
-- exportados (SIACAM). Después calculo:
--   - a_precio_2019: cuánto valdría la producción de cada año si el oro
--     siguiera costando lo que costaba en 2019. Aísla el efecto de la
--     producción.
--   - los tres índices con base 2019 = 100, para verlos en la misma escala.
--
-- Límites: producción y exportación no son lo mismo (lo producido en
-- diciembre se exporta en enero, y el doré también lleva plata). Por eso
-- onzas por precio no da exactamente lo exportado; P04 mide esa diferencia.

WITH precio AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_onza
    FROM mineria.precio
    WHERE mineral = 'Oro (Au)'
    GROUP BY 1
),
exportado AS (
    SELECT extract(year FROM fecha)::int AS anio, sum(fob_usd) / 1e6 AS musd
    FROM mineria.exportacion_siacam
    WHERE grupo = 'Oro'
    GROUP BY 1
),
datos AS (
    SELECT c.anio, c.produccion AS miles_onzas, p.usd_por_onza, e.musd
    FROM mineria.produccion_anual c
    JOIN precio p USING (anio)
    JOIN exportado e USING (anio)
    WHERE c.mineral = 'Oro'
),
base AS (SELECT * FROM datos WHERE anio = 2019)
SELECT d.anio,
       d.miles_onzas,
       round(d.usd_por_onza)                             AS usd_por_onza,
       round(d.musd)                                     AS exportado_musd,
       round(d.miles_onzas * b.usd_por_onza / 1000)      AS a_precio_2019_musd,
       round(100 * d.miles_onzas / b.miles_onzas)        AS indice_produccion,
       round(100 * d.usd_por_onza / b.usd_por_onza)      AS indice_precio,
       round(100 * d.musd / b.musd)                      AS indice_exportado
FROM datos d
CROSS JOIN base b
ORDER BY d.anio;

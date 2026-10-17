-- P16. ¿Qué parte de lo que produce Veladero queda en impuestos nacionales?
--
-- Cómo: para 2019 a 2023 comparo los impuestos que pagó Minera Andina del
-- Sol (la empresa que opera Veladero) con el valor de lo que produjo la mina.
-- El valor de la producción lo calculo yo: onzas de oro producidas por el
-- precio promedio del año.
--
-- Límites: los impuestos son solo los nacionales que releva SIACAM; las
-- regalías provinciales casi no figuran en esa fuente y no las tengo. El
-- valor de la producción no cuenta la plata que también saca la mina, así
-- que el porcentaje real es algo menor. No es la ganancia de la empresa: es
-- valor bruto, antes de costos.

WITH impuestos AS (
    SELECT anio,
           sum(millones_usd)                                                    AS total,
           sum(millones_usd) FILTER (WHERE impuesto = 'Derechos de exportación') AS derechos_exportacion,
           sum(millones_usd) FILTER (WHERE impuesto = 'Ganancias')               AS ganancias,
           sum(millones_usd) FILTER (WHERE impuesto = 'Seguridad social')        AS seguridad_social
    FROM mineria.impuesto_empresa
    WHERE empresa = 'MINERA ANDINA DEL SOL S.R.L.'
    GROUP BY anio
),
precio AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_onza
    FROM mineria.precio WHERE mineral = 'Oro (Au)' GROUP BY 1
)
SELECT i.anio,
       v.produccion_total                                       AS miles_onzas,
       round(v.produccion_total * p.usd_por_onza / 1000)        AS valor_producido_musd,
       round(i.derechos_exportacion)                            AS derechos_exportacion,
       round(i.ganancias)                                       AS ganancias,
       round(i.seguridad_social)                                AS seguridad_social,
       round(i.total)                                           AS impuestos_musd,
       round(100 * i.total / (v.produccion_total * p.usd_por_onza / 1000), 1) AS pct_del_valor
FROM impuestos i
JOIN mineria.produccion_mina v ON v.anio = i.anio AND v.mina = 'Veladero' AND v.mineral = 'Oro'
JOIN precio p ON p.anio = i.anio
ORDER BY i.anio;

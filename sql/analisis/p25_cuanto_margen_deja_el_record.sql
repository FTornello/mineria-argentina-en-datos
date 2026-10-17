-- P25. Con el oro a precio récord, ¿cuánto le queda a la mina por cada onza?
-- ¿Y cuánto suben los costos?
--
-- Cómo: para Veladero y Cerro Negro pongo al lado, por año, el precio
-- promedio del oro y el costo total por onza que informa cada empresa (AISC:
-- costo de operar más la inversión para sostener la mina). La diferencia es
-- el margen por onza antes de impuestos a las ganancias. Multiplicado por las
-- onzas producidas da un orden de magnitud del margen total.
--
-- Límites: el AISC no incluye impuestos a las ganancias ni la inversión en
-- proyectos nuevos, así que no es la ganancia. Goldcorp (Cerro Negro hasta
-- 2018) y Newmont (desde 2019) lo calculan distinto: la serie de Cerro Negro
-- tiene un salto de definición en 2019. El precio es el promedio del mercado,
-- no el que cobró cada empresa.

WITH precio AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_onza
    FROM mineria.precio WHERE mineral = 'Oro (Au)' GROUP BY 1
),
costo AS (
    SELECT mina, anio, valor AS aisc
    FROM mineria.operacion_mina WHERE indicador = 'aisc'
)
SELECT c.mina,
       c.anio,
       round(p.usd_por_onza)                           AS precio_oro,
       c.aisc,
       round(p.usd_por_onza - c.aisc)                  AS margen_por_onza,
       round(100 * (p.usd_por_onza - c.aisc) / p.usd_por_onza) AS margen_pct,
       m.produccion_total                              AS miles_onzas,
       round((p.usd_por_onza - c.aisc) * m.produccion_total / 1000) AS margen_total_musd
FROM costo c
JOIN precio p USING (anio)
LEFT JOIN mineria.produccion_mina m ON m.mina = c.mina AND m.anio = c.anio AND m.mineral = 'Oro'
WHERE c.mina IN ('Veladero', 'Cerro Negro')
ORDER BY c.mina DESC, c.anio;

-- P10. Mes a mes, ¿el precio al que China recibe el litio argentino sigue al
-- precio de referencia?
--
-- Cómo: para cada mes desde 2022 calculo el precio de llegada a China
-- (dólares sobre toneladas de carbonato, según la aduana china) y lo pongo
-- al lado del precio de referencia de ese mes. Resumo por semestre para que
-- se lea.
--
-- Límites: los datos mensuales de China en UN Comtrade llegan hasta diciembre
-- de 2024; para 2025 solo está el total anual. Además, un barco tarda semanas y el precio se fija antes de embarcar, así
-- que el precio de llegada va siempre atrasado respecto de la referencia.

WITH llegada AS (
    SELECT fecha, sum(valor_usd) AS usd, sum(peso_neto_kg) / 1000 AS toneladas
    FROM mineria.importacion_espejo
    WHERE frecuencia = 'M' AND hs6 = '283691' AND pais = 'China' AND fecha >= '2022-01-01'
    GROUP BY fecha
),
referencia AS (
    SELECT fecha, precio FROM mineria.precio WHERE mineral LIKE 'Carbonato de Litio%'
)
SELECT extract(year FROM l.fecha)::int                           AS anio,
       CASE WHEN extract(month FROM l.fecha) <= 6 THEN 1 ELSE 2 END AS semestre,
       count(*)                                                  AS meses_con_dato,
       round(sum(l.toneladas))                                   AS toneladas,
       round(sum(l.usd) / sum(l.toneladas))                      AS llegada_usd_por_ton,
       round(avg(r.precio))                                      AS referencia_usd_por_ton,
       round(100 * (sum(l.usd) / sum(l.toneladas)) / avg(r.precio)) AS llegada_pct_de_referencia
FROM llegada l
JOIN referencia r USING (fecha)
GROUP BY 1, 2
ORDER BY 1, 2;

-- P05. En el litio pasa lo contrario que en el oro: ¿la producción sube y el
-- valor no acompaña?
--
-- Cómo: junto por año las toneladas producidas (CAEM, en carbonato de litio
-- equivalente), los dólares exportados (total anual de SIACAM) y el precio de
-- referencia en Asia (SIACAM, disponible desde fines de 2018). Con los dos
-- primeros calculo cuántos dólares entraron por cada tonelada producida.
--
-- Límites: divido exportaciones por producción, no por toneladas exportadas,
-- así que es una aproximación (hay stock y demora entre producir y embarcar).
-- El precio de referencia es el del mercado al contado en China; buena parte
-- del litio argentino se vende por contrato a un precio fijado antes.

WITH precio AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_ton
    FROM mineria.precio
    WHERE mineral LIKE 'Carbonato de Litio%'
    GROUP BY 1
)
SELECT c.anio,
       c.produccion                                          AS miles_ton_lce,
       round(l.millones_usd)                                 AS exportado_musd,
       round(l.millones_usd * 1000 / c.produccion)           AS usd_por_ton_producida,
       round(p.usd_por_ton)                                  AS precio_referencia_asia,
       round(100 * (l.millones_usd * 1000 / c.produccion) / p.usd_por_ton) AS pct_de_la_referencia
FROM mineria.produccion_anual c
JOIN mineria.exportacion_litio_anual l USING (anio)
LEFT JOIN precio p USING (anio)
WHERE c.mineral = 'Litio'
ORDER BY c.anio;

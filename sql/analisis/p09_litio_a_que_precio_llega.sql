-- P09. ¿Todos los compradores pagan lo mismo por el litio argentino?
--
-- Cómo: con los datos de las aduanas de los países compradores (UN Comtrade)
-- divido los dólares por las toneladas de carbonato de litio que cada país
-- declara haber importado desde Argentina. Da el precio promedio de llegada
-- por país y por año. Al lado pongo el precio de referencia en Asia.
-- Solo cuento un país en un año si importó más de 1.000 toneladas, para que
-- un embarque chico no distorsione el promedio.
--
-- Límites: es precio de llegada (con flete y seguro). No distingue calidades
-- del producto ni si la venta es entre empresas del mismo grupo.

WITH llegada AS (
    SELECT extract(year FROM fecha)::int AS anio,
           pais,
           sum(valor_usd) / (sum(peso_neto_kg) / 1000) AS usd_por_ton,
           sum(peso_neto_kg) / 1000                    AS toneladas
    FROM mineria.importacion_espejo
    WHERE frecuencia = 'A' AND hs6 = '283691'
      AND pais IN ('China', 'USA', 'Japan', 'Rep. of Korea')
      AND peso_neto_kg > 0
    GROUP BY 1, 2
    HAVING sum(peso_neto_kg) > 1000000
),
referencia AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_ton
    FROM mineria.precio
    WHERE mineral LIKE 'Carbonato de Litio%'
    GROUP BY 1
)
SELECT l.anio,
       round(max(l.usd_por_ton) FILTER (WHERE l.pais = 'China'))         AS china,
       round(max(l.usd_por_ton) FILTER (WHERE l.pais = 'Japan'))         AS japon,
       round(max(l.usd_por_ton) FILTER (WHERE l.pais = 'Rep. of Korea')) AS corea,
       round(max(l.usd_por_ton) FILTER (WHERE l.pais = 'USA'))           AS eeuu,
       round(max(r.usd_por_ton))                                         AS referencia_asia
FROM llegada l
LEFT JOIN referencia r USING (anio)
WHERE l.anio >= 2017
GROUP BY l.anio
ORDER BY l.anio;

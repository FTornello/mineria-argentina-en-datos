-- P24. Cerro Negro pasó de unas 500 mil onzas por año a 202 mil. ¿Es que el
-- mineral es más pobre, que se procesa menos, o las dos cosas?
--
-- Cómo: junto por año la producción de oro (informes de Goldcorp y Newmont),
-- las toneladas que entraron a la planta, la ley (gramos de oro por tonelada)
-- y la recuperación. La producción es, a grandes rasgos, toneladas por ley
-- por recuperación: si una de las tres cae, cae la producción. La columna
-- oro_en_lo_procesado hace esa cuenta (en miles de onzas) para ver si cierra
-- con lo informado.
--
-- Límites: 2015 no trae ley ni toneladas en el documento que leí; 2019 y 2020
-- tampoco. 2020 fue un año con la mina parada por la pandemia. Goldcorp y
-- Newmont pueden medir la ley de manera algo distinta.

WITH op AS (
    SELECT anio,
           max(valor) FILTER (WHERE indicador = 'toneladas_procesadas') AS miles_toneladas,
           max(valor) FILTER (WHERE indicador = 'ley')                  AS ley_g_t,
           max(valor) FILTER (WHERE indicador = 'recuperacion')         AS recuperacion_pct
    FROM mineria.operacion_mina
    WHERE mina = 'Cerro Negro'
    GROUP BY anio
)
SELECT p.anio,
       p.publicado                AS miles_onzas,
       o.miles_toneladas,
       o.ley_g_t,
       o.recuperacion_pct,
       round(o.miles_toneladas * o.ley_g_t * o.recuperacion_pct / 100 / 31.1035) AS oro_en_lo_procesado
FROM mineria.produccion_mina p
LEFT JOIN op o USING (anio)
WHERE p.mina = 'Cerro Negro'
ORDER BY p.anio;

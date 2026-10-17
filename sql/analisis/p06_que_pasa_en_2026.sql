-- P06. ¿Sigue en 2026 lo que se ve hasta 2025? Oro: más dólares con menos
-- producción. Litio: más producción.
--
-- Cómo: comparo enero a julio de 2026 contra enero a julio de 2025, que es
-- hasta donde llega el índice de producción. Para cada mineral miro el
-- volumen producido, el precio promedio y los dólares exportados.
--   - Oro: el volumen es el índice de producción de bullón dorado.
--   - Litio: el volumen son las toneladas de carbonato de litio.
--
-- Límite: son siete meses de datos provisorios.

WITH oro AS (
    SELECT extract(year FROM i.fecha)::int AS anio, 'Oro' AS mineral,
           avg(i.indice) AS volumen, 'índice de doré' AS unidad_volumen
    FROM mineria.indice_produccion i
    WHERE i.rama LIKE 'Bullón Dorado%' AND extract(month FROM i.fecha) <= 7 AND i.fecha >= '2025-01-01'
    GROUP BY 1
),
litio AS (
    SELECT extract(year FROM fecha)::int AS anio, 'Litio' AS mineral,
           sum(carbonato_litio_ton) AS volumen, 'toneladas de carbonato' AS unidad_volumen
    FROM mineria.produccion_litio
    WHERE extract(month FROM fecha) <= 7 AND fecha >= '2025-01-01'
    GROUP BY 1
),
volumen AS (SELECT * FROM oro UNION ALL SELECT * FROM litio),
precio AS (
    SELECT extract(year FROM fecha)::int AS anio,
           CASE WHEN mineral = 'Oro (Au)' THEN 'Oro' ELSE 'Litio' END AS mineral,
           avg(precio) AS precio
    FROM mineria.precio
    WHERE (mineral = 'Oro (Au)' OR mineral LIKE 'Carbonato de Litio%')
      AND extract(month FROM fecha) <= 7 AND fecha >= '2025-01-01'
    GROUP BY 1, 2
),
exportado AS (
    SELECT extract(year FROM fecha)::int AS anio, grupo AS mineral, sum(fob_usd) / 1e6 AS musd
    FROM mineria.exportacion_siacam
    WHERE grupo IN ('Oro', 'Litio') AND extract(month FROM fecha) <= 7 AND fecha >= '2025-01-01'
    GROUP BY 1, 2
)
SELECT v.mineral,
       v.unidad_volumen,
       round(max(v.volumen) FILTER (WHERE v.anio = 2025), 1) AS volumen_2025,
       round(max(v.volumen) FILTER (WHERE v.anio = 2026), 1) AS volumen_2026,
       round(100 * (max(v.volumen) FILTER (WHERE v.anio = 2026) / max(v.volumen) FILTER (WHERE v.anio = 2025) - 1)) AS volumen_var_pct,
       round(100 * (max(p.precio) FILTER (WHERE p.anio = 2026) / max(p.precio) FILTER (WHERE p.anio = 2025) - 1))   AS precio_var_pct,
       round(max(e.musd) FILTER (WHERE e.anio = 2025))        AS exportado_2025_musd,
       round(max(e.musd) FILTER (WHERE e.anio = 2026))        AS exportado_2026_musd,
       round(100 * (max(e.musd) FILTER (WHERE e.anio = 2026) / max(e.musd) FILTER (WHERE e.anio = 2025) - 1))       AS exportado_var_pct
FROM volumen v
JOIN precio p USING (anio, mineral)
JOIN exportado e USING (anio, mineral)
GROUP BY v.mineral, v.unidad_volumen
ORDER BY v.mineral DESC;

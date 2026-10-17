-- P33. En octubre de 2026 la prensa y la Secretaría de Minería publicaron tres
-- números del litio. ¿Coinciden con los datos?
--   - Exportaciones de enero a agosto de 2026: 1.467 millones de dólares,
--     190,5% más que un año antes (Acero y Roca, 16-10-2026).
--   - Exportaciones de 2025: más de 914 millones (informe de la Secretaría,
--     según El Pregón Minero, 7-10-2026).
--   - China compró el 81,1% en 2025 (mismo informe).
--
-- Cómo: calculo cada número con los archivos de la Secretaría que están en la
-- base: el mensual por mineral y el anual de litio por destino.
--
-- Límites: los dos primeros salen de la misma Secretaría que publica los
-- archivos, así que coincidir no es una validación independiente; sirve para
-- ver que se lee igual. El 81,1% no coincide y no encontré el informe completo
-- para ver cómo se calcula (puede ser en toneladas y no en dólares, o con otros
-- productos).

WITH ene_ago AS (
    SELECT extract(year FROM fecha)::int AS anio, sum(fob_usd) / 1e6 AS musd
    FROM mineria.exportacion_siacam
    WHERE grupo = 'Litio' AND extract(month FROM fecha) <= 8
    GROUP BY 1
),
china AS (
    SELECT 100 * sum(millones_usd) FILTER (WHERE destino = 'China') / sum(millones_usd) AS pct
    FROM mineria.exportacion_litio_destino WHERE anio = 2025
)
SELECT 'Exportado enero a agosto de 2026 (millones de USD)' AS dato, 1467 AS publicado,
       round((SELECT musd FROM ene_ago WHERE anio = 2026)) AS mis_datos
UNION ALL
SELECT 'Variación contra enero a agosto de 2025 (%)', 190.5,
       round(100 * ((SELECT musd FROM ene_ago WHERE anio = 2026) / (SELECT musd FROM ene_ago WHERE anio = 2025) - 1), 1)
UNION ALL
SELECT 'Exportado en 2025 (millones de USD)', 914,
       round((SELECT millones_usd FROM mineria.exportacion_litio_anual WHERE anio = 2025))
UNION ALL
SELECT 'China, parte de lo exportado en 2025 (%)', 81.1, round((SELECT pct FROM china), 1);

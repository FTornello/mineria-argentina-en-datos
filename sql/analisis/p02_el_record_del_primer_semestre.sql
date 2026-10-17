-- P02. La prensa dijo que en el primer semestre de 2026 la minería exportó
-- 4.742 millones de dólares, 75% más que un año antes, que el oro fue el 61%
-- y el litio una cuarta parte, y que la minería fue "casi el 10%" de las
-- exportaciones del país (EconoJournal, 16-9-2026). ¿Da lo mismo con los datos?
--
-- Cómo: sumo enero a junio de cada año en la serie de SIACAM. Para el peso en
-- el total del país uso las exportaciones de todos los productos del INDEC
-- (capa raw), que para el total anual no están afectadas por el secreto.
--
-- Límite: los datos de 2026 son provisorios y se revisan; por eso una
-- diferencia chica con la nota es esperable.

WITH mineria_semestre AS (
    SELECT extract(year FROM fecha)::int AS anio,
           sum(fob_usd) / 1e6                                AS total,
           sum(fob_usd) FILTER (WHERE grupo = 'Oro') / 1e6   AS oro,
           sum(fob_usd) FILTER (WHERE grupo = 'Litio') / 1e6 AS litio,
           sum(fob_usd) FILTER (WHERE grupo = 'Plata') / 1e6 AS plata
    FROM mineria.exportacion_siacam
    WHERE extract(month FROM fecha) <= 6 AND fecha >= '2024-01-01'
    GROUP BY 1
),
pais_semestre AS (
    SELECT anio::int AS anio, sum(mineria.numero_indec(fob_usd)) / 1e6 AS total_pais
    FROM raw.indec_exportaciones
    WHERE mes::int <= 6 AND anio::int >= 2024
    GROUP BY 1
)
SELECT m.anio,
       round(m.total)                                             AS mineria_musd,
       round(100 * (m.total / lag(m.total) OVER (ORDER BY m.anio) - 1)) AS variacion_pct,
       round(100 * m.oro / m.total)                               AS pct_oro,
       round(100 * m.litio / m.total)                             AS pct_litio,
       round(100 * m.plata / m.total)                             AS pct_plata,
       round(p.total_pais)                                        AS pais_musd,
       round(100 * m.total / p.total_pais, 1)                     AS pct_del_pais
FROM mineria_semestre m
JOIN pais_semestre p USING (anio)
ORDER BY m.anio;

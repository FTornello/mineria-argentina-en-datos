-- P01. ¿Cuánto exporta la minería argentina y qué parte es cada mineral?
--
-- Cómo: sumo por año las exportaciones de minerales de SIACAM y separo oro y
-- plata. El litio lo tomo de la tabla anual, porque entre 2018 y 2023 la serie
-- mensual manda parte del litio al grupo "Otro" (ver DICCIONARIO.md).
-- "Resto" es todo lo demás: cobre, plomo, cales, boratos y lo no clasificado.
--
-- Límite: 2026 no está porque el año no terminó (ver P02 para el semestre).

WITH por_anio AS (
    SELECT extract(year FROM fecha)::int AS anio,
           sum(fob_usd) / 1e6                                AS total,
           sum(fob_usd) FILTER (WHERE grupo = 'Oro') / 1e6   AS oro,
           sum(fob_usd) FILTER (WHERE grupo = 'Plata') / 1e6 AS plata
    FROM mineria.exportacion_siacam
    WHERE fecha BETWEEN '2010-01-01' AND '2025-12-01'
    GROUP BY 1
)
SELECT p.anio,
       round(p.total)                                    AS total_musd,
       round(p.oro)                                      AS oro,
       round(p.plata)                                    AS plata,
       round(l.millones_usd)                             AS litio,
       round(p.total - p.oro - p.plata - l.millones_usd) AS resto,
       round(100 * p.oro / p.total)                      AS pct_oro,
       round(100 * l.millones_usd / p.total)             AS pct_litio
FROM por_anio p
JOIN mineria.exportacion_litio_anual l USING (anio)
ORDER BY p.anio;

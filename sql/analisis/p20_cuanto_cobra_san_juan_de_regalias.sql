-- P20. ¿Cuánto cobra San Juan de regalías y qué parte es de lo que exporta la
-- minería de la provincia?
--
-- Cómo: tomo las regalías cobradas cada año según la ejecución presupuestaria
-- de la provincia (en pesos), las paso a dólares con el tipo de cambio oficial
-- promedio del año y las comparo con las exportaciones mineras de San Juan.
-- La ley provincial fija la regalía en 3% del valor en boca de mina, que es
-- lo exportado menos algunos costos; por eso se espera algo menos de 3%.
--
-- Límites: el renglón del presupuesto dice "Regalías" y no separa las mineras
-- de las hidroeléctricas, así que lo minero es algo menos. Pasar a dólares
-- con el promedio anual es una aproximación: en años de devaluación fuerte
-- (2018, 2019, 2023) importa mucho en qué mes se cobró.

WITH tipo_cambio AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(pesos_por_usd) AS pesos_por_usd
    FROM mineria.tipo_cambio
    GROUP BY 1
)
SELECT r.anio,
       round(r.regalias_total_pesos / 1e6)                         AS regalias_millones_pesos,
       round(t.pesos_por_usd, 1)                                   AS pesos_por_usd,
       round(r.regalias_total_pesos / t.pesos_por_usd / 1e6, 1)    AS regalias_musd,
       round(x.millones_usd)                                       AS exportado_san_juan_musd,
       round(100 * (r.regalias_total_pesos / t.pesos_por_usd / 1e6) / x.millones_usd, 1) AS pct_de_lo_exportado
FROM mineria.regalias_san_juan r
JOIN tipo_cambio t USING (anio)
JOIN mineria.exportacion_provincia x ON x.anio = r.anio AND x.provincia = 'San Juan'
ORDER BY r.anio;

-- P31. En junio de 2023 Newmont anunció 540 millones de dólares para Cerro
-- Negro y más de 350 mil onzas por año desde 2024. ¿Cuánto produjo?
--
-- Cómo: tomo la promesa de la tabla de hechos (con su fuente) y la comparo,
-- año por año desde el año prometido, con la producción que informa Newmont.
-- Sumo los hechos de cada año para ver qué pasó en el medio.
--
-- Límites:
--   - La promesa la publicó Bloomberg Línea citando el anuncio; no encontré el
--     comunicado original de Newmont con esa cifra.
--   - El accidente de abril de 2024 frenó la mina seis semanas: explica una
--     parte de 2024, no de 2025. La ley del mineral (P24) explica otra parte.

WITH promesa AS (
    SELECT onzas_anunciadas_miles AS prometido, desde_anio, inversion_musd, fecha
    FROM mineria.hecho_mina
    WHERE mina = 'Cerro Negro' AND tipo = 'Promesa'
)
SELECT m.anio,
       p.prometido                                         AS prometido_miles_onzas,
       m.produccion_total                                  AS producido_miles_onzas,
       round(100 * (m.produccion_total / p.prometido - 1)) AS diferencia_pct,
       (SELECT string_agg(h.descripcion, ' ')
        FROM mineria.hecho_mina h
        WHERE h.mina = 'Cerro Negro' AND extract(year FROM h.fecha) = m.anio) AS que_paso
FROM mineria.produccion_mina m
CROSS JOIN promesa p
WHERE m.mina = 'Cerro Negro' AND m.mineral = 'Oro' AND m.anio >= p.desde_anio
ORDER BY m.anio;

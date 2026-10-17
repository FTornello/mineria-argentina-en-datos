-- P07. ¿A quién le vende Argentina el litio, y cómo cambió?
--
-- Cómo: tomo las exportaciones de litio por país de destino de SIACAM y
-- calculo qué porcentaje del año fue a cada uno. Muestro los cuatro
-- compradores principales y junto el resto.
--
-- Límite: el destino es el país al que se declara la venta, que no siempre
-- es donde el litio termina usándose. SIACAM agrupa los destinos chicos en
-- "Resto", así que un país puede estar ahí en algunos años.

WITH por_destino AS (
    SELECT anio, destino, millones_usd,
           sum(millones_usd) OVER (PARTITION BY anio) AS total_anio
    FROM mineria.exportacion_litio_destino
    WHERE anio >= 2012
)
SELECT anio,
       round(max(total_anio))                                                               AS total_musd,
       round(100 * sum(millones_usd) FILTER (WHERE destino = 'China') / max(total_anio))            AS pct_china,
       round(100 * sum(millones_usd) FILTER (WHERE destino = 'Estados Unidos') / max(total_anio))   AS pct_eeuu,
       round(100 * sum(millones_usd) FILTER (WHERE destino = 'Japon') / max(total_anio))            AS pct_japon,
       round(100 * sum(millones_usd) FILTER (WHERE destino = 'Corea, Republica de') / max(total_anio)) AS pct_corea,
       round(100 * sum(millones_usd) FILTER (WHERE destino NOT IN
             ('China', 'Estados Unidos', 'Japon', 'Corea, Republica de')) / max(total_anio))        AS pct_otros
FROM por_destino
GROUP BY anio
ORDER BY anio;

-- P08. ¿Los países compradores confirman a dónde va el litio?
--
-- Cómo: comparo dos fuentes que no dependen una de la otra. De un lado, lo
-- que la Argentina declara exportar a cada país (SIACAM). Del otro, lo que la
-- aduana de cada país declara importar desde Argentina (UN Comtrade),
-- sumando carbonato e hidróxido de litio. Lo hago para los cuatro
-- compradores principales, de 2019 a 2025.
--
-- Límites: el comprador declara con flete y seguro incluidos y en la fecha de
-- llegada, así que es normal que declare algo más y con atraso. Una
-- diferencia grande en un país y un año sí es una señal para mirar: puede
-- ser mercadería que cambió de destino en el camino.

WITH argentina AS (
    SELECT anio,
           CASE destino WHEN 'Estados Unidos' THEN 'Estados Unidos'
                        WHEN 'Japon' THEN 'Japón'
                        WHEN 'Corea, Republica de' THEN 'Corea del Sur'
                        ELSE destino END AS pais,
           millones_usd
    FROM mineria.exportacion_litio_destino
    WHERE destino IN ('China', 'Estados Unidos', 'Japon', 'Corea, Republica de')
),
compradores AS (
    SELECT extract(year FROM fecha)::int AS anio,
           CASE pais WHEN 'USA' THEN 'Estados Unidos'
                     WHEN 'Japan' THEN 'Japón'
                     WHEN 'Rep. of Korea' THEN 'Corea del Sur'
                     ELSE pais END AS pais,
           sum(valor_usd) / 1e6 AS millones_usd
    FROM mineria.importacion_espejo
    WHERE frecuencia = 'A' AND hs6 IN ('283691', '282520')
      AND pais IN ('China', 'USA', 'Japan', 'Rep. of Korea')
    GROUP BY 1, 2
)
SELECT c.anio, c.pais,
       round(a.millones_usd)                              AS declara_argentina_musd,
       round(c.millones_usd)                              AS declara_el_comprador_musd,
       round(c.millones_usd - coalesce(a.millones_usd, 0)) AS diferencia_musd
FROM compradores c
LEFT JOIN argentina a USING (anio, pais)
WHERE c.anio BETWEEN 2019 AND 2025
ORDER BY c.pais, c.anio;

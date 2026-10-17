-- P22. Si Estados Unidos hubiera pagado por el litio argentino lo mismo que
-- por el chileno, ¿cuánto más habría valido lo exportado? ¿Y cuánto habría
-- entrado de más en derechos de exportación y regalías?
--
-- Cómo: para cada año de la brecha (2018 a 2023, ver P21) multiplico las
-- toneladas que Estados Unidos importó desde Argentina por la diferencia
-- entre el precio chileno y el argentino. Eso da el valor que "faltó".
-- Después le aplico dos tasas para tener un orden de magnitud de lo que se
-- dejó de cobrar: 4,5%, que es el derecho de exportación del litio hoy, y
-- 7,5%, que le suma una regalía provincial de 3%.
--
-- Esto es un ejercicio, no una medición:
--   - Supone que el precio "correcto" era el que pagó Estados Unidos a Chile.
--     Puede haber diferencias de calidad o de contrato que lo expliquen.
--   - Las tasas cambiaron en el período (los derechos de exportación fueron
--     más altos en 2018 y 2019) y acá uso las mismas para todos los años.
--   - Los precios son de llegada, con flete; los impuestos se calculan sobre
--     el precio de salida.
-- Referencia para comparar: la Aduana reclamó 8 millones de dólares de
-- derechos de exportación por 2018 y 2019 (Bloomberg Línea, 14-7-2022).

WITH argentina AS (
    SELECT extract(year FROM fecha)::int AS anio,
           sum(peso_neto_kg) / 1000                    AS toneladas,
           sum(valor_usd) / (sum(peso_neto_kg) / 1000) AS precio
    FROM mineria.importacion_espejo
    WHERE frecuencia = 'A' AND hs6 = '283691' AND pais = 'USA'
    GROUP BY 1
),
brecha AS (
    SELECT a.anio, a.toneladas, a.precio AS precio_argentina,
           c.valor_usd / (c.peso_neto_kg / 1000) AS precio_chile,
           a.toneladas * (c.valor_usd / (c.peso_neto_kg / 1000) - a.precio) / 1e6 AS valor_faltante_musd
    FROM argentina a
    JOIN mineria.litio_eeuu_desde_chile c USING (anio)
    WHERE a.anio BETWEEN 2018 AND 2023
)
SELECT anio::text,
       round(toneladas)                    AS toneladas,
       round(precio_argentina)             AS precio_argentina,
       round(precio_chile)                 AS precio_chile,
       round(valor_faltante_musd, 1)       AS valor_faltante_musd,
       round(valor_faltante_musd * 0.045, 1) AS al_4_5_pct_musd,
       round(valor_faltante_musd * 0.075, 1) AS al_7_5_pct_musd
FROM brecha
UNION ALL
SELECT 'Total', round(sum(toneladas)), NULL, NULL,
       round(sum(valor_faltante_musd), 1),
       round(sum(valor_faltante_musd) * 0.045, 1),
       round(sum(valor_faltante_musd) * 0.075, 1)
FROM brecha
ORDER BY 1;

-- P27. Con el oro a precio récord en 2024 y 2025, ¿cuánto pagaron las minas a
-- los gobiernos argentinos, comparado con el valor de lo que produjeron?
--
-- Cómo: para cada mina de oro sumo lo que declara haber pagado en el año
-- (impuestos, regalías, tasas y otros pagos al Estado) y lo comparo con el
-- valor del oro que produjo (onzas por precio promedio del año).
--   - Veladero: informe de contribución tributaria de Barrick (100% de la
--     mina). Incluye impuestos y regalías nacionales y provinciales.
--   - Las demás: base canadiense ESTMA, pasada a dólares estadounidenses con
--     el tipo de cambio promedio del año. Cubre impuestos sobre la renta y la
--     producción, regalías, tasas, bonos y pagos por infraestructura.
--
-- Límites:
--   - Las dos fuentes no miden exactamente lo mismo; ninguna incluye las
--     cargas sociales ni el IVA. Son pagos en efectivo del año, no lo
--     devengado: un impuesto a las ganancias de 2025 se paga en 2026.
--   - El valor producido cuenta solo el oro. Cerro Moro y San José sacan
--     mucha plata, así que para ellas el porcentaje sale más alto de lo real.
--   - No es la ganancia de la empresa. Para el margen ver P25.

WITH precio AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_por_onza
    FROM mineria.precio WHERE mineral = 'Oro (Au)' GROUP BY 1
),
pagos AS (
    SELECT mina, anio, sum(usd) / 1e6 AS musd, 'ESTMA' AS fuente
    FROM mineria.pago_gobierno
    WHERE sector = 'Minería' AND mina IN ('Cerro Negro', 'Cerro Vanguardia', 'Lindero', 'Cerro Moro')
    GROUP BY mina, anio
    UNION ALL
    SELECT mina, anio, millones_usd, 'Barrick'
    FROM mineria.contribucion_tributaria
)
SELECT g.mina,
       g.anio,
       round(m.produccion_total)                                     AS miles_onzas,
       round(m.produccion_total * p.usd_por_onza / 1000)             AS valor_producido_musd,
       round(g.musd)                                                 AS pagado_al_estado_musd,
       round(100 * g.musd / (m.produccion_total * p.usd_por_onza / 1000), 1) AS pct_del_valor,
       g.fuente
FROM pagos g
JOIN precio p USING (anio)
JOIN mineria.produccion_mina m ON m.mina = g.mina AND m.anio = g.anio AND m.mineral = 'Oro'
WHERE m.produccion_total IS NOT NULL
ORDER BY g.mina, g.anio;

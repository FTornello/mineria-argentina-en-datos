-- P29. Olaroz, en Jujuy, es la operación de litio más antigua del país. En el
-- pico de precios, ¿cuánto facturó, cuánto ganó y cuánto pagó al Estado?
--
-- Cómo: junto, para cada ejercicio de julio a junio, los ingresos y el
-- margen operativo (EBITDA) que Allkem informó para Olaroz, y lo que la misma
-- empresa declaró haber pagado a gobiernos argentinos por ese proyecto en la
-- base canadiense ESTMA (impuestos, regalías, tasas y dividendos a la
-- empresa provincial JEMSE, que es socia con 8,5%). Agrego el precio al que
-- vendió y el precio de referencia en Asia del mismo período.
--
-- Límites:
--   - Los pagos son en efectivo: el impuesto a las ganancias del ejercicio
--     2023 se pagó en buena parte en el semestre siguiente (julio a diciembre
--     de 2023), que figura aparte en ESTMA con 66 millones de dólares.
--   - El EBITDA es antes de impuestos, intereses y amortizaciones: no es la
--     ganancia final.
--   - ESTMA informa Olaroz bajo dos nombres (Olaroz y Sales de Jujuy, la
--     empresa operadora); acá están sumados.

WITH pagos AS (
    SELECT anio, sum(usd) / 1e6 AS musd,
           sum(usd) FILTER (WHERE tipo_pago = 'Impuestos') / 1e6 AS impuestos,
           sum(usd) FILTER (WHERE tipo_pago = 'Regalías') / 1e6  AS regalias
    FROM mineria.pago_gobierno
    WHERE mina = 'Olaroz'
    GROUP BY anio
),
referencia AS (
    SELECT r.periodo_inicio, avg(p.precio) AS usd_t
    FROM mineria.resultado_operacion r
    JOIN mineria.precio p ON p.mineral LIKE 'Carbonato de Litio%' AND p.fecha BETWEEN r.periodo_inicio AND r.periodo_fin
    GROUP BY r.periodo_inicio
)
SELECT to_char(r.periodo_inicio, 'MM/YYYY') || ' a ' || to_char(r.periodo_fin, 'MM/YYYY') AS ejercicio,
       r.ingresos_musd,
       r.ebitda_musd,
       round(100 * r.ebitda_musd / r.ingresos_musd)        AS margen_pct,
       round(g.musd, 1)                                     AS pagado_al_estado_musd,
       round(g.impuestos, 1)                                AS impuestos,
       round(g.regalias, 1)                                 AS regalias,
       round(100 * g.musd / r.ingresos_musd, 1)             AS pct_de_los_ingresos,
       round(100 * g.musd / r.ebitda_musd, 1)               AS pct_del_ebitda,
       r.precio_usd_t                                       AS precio_de_venta,
       round(f.usd_t)                                       AS referencia_asia
FROM mineria.resultado_operacion r
LEFT JOIN pagos g ON g.anio = extract(year FROM r.periodo_fin)
LEFT JOIN referencia f USING (periodo_inicio)
WHERE r.mina = 'Olaroz'
ORDER BY r.periodo_inicio;

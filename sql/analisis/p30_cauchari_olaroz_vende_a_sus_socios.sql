-- P30. Cauchari-Olaroz es la operación de litio más grande del país. ¿Cuánto
-- vende, cuánto le queda y, por lo tanto, cuánto podría pagar de impuesto a
-- las ganancias?
--
-- Cómo: uso los estados contables de Minera Exar, la empresa que la opera,
-- que Lithium Argentina publica en su informe anual ante la SEC. Pongo al lado
-- los ingresos, el resultado bruto (ventas menos costo de producir), los
-- costos financieros (intereses de los préstamos) y el resultado final.
-- Calculo un precio implícito dividiendo las ventas por lo producido y lo
-- comparo con la referencia de Asia. Al final pongo Olaroz, la vecina, para
-- comparar márgenes.
--
-- Límites:
--   - El precio implícito divide por toneladas producidas, no vendidas: es una
--     aproximación (hay stock entre producir y embarcar).
--   - Los costos financieros son en buena parte intereses de préstamos de los
--     propios socios (a través de Exar Capital). Eso es lo que dicen los
--     informes; que la estructura sea normal o no para un proyecto financiado
--     por sus dueños no lo puedo juzgar con estos datos.
--   - 2023 fue el año de arranque. Su resultado positivo se explica por una
--     ganancia contable por derivados, no por la operación.
--   - Olaroz y Cauchari-Olaroz no son comparables año a año: Olaroz es del
--     pico de precios (2022-2023) y Cauchari-Olaroz de la baja (2024-2025).

WITH referencia AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(precio) AS usd_t
    FROM mineria.precio WHERE mineral LIKE 'Carbonato de Litio%' GROUP BY 1
)
SELECT r.mina,
       to_char(r.periodo_inicio, 'MM/YYYY') || ' a ' || to_char(r.periodo_fin, 'MM/YYYY') AS periodo,
       r.ingresos_musd,
       r.resultado_bruto_musd,
       round(100 * r.resultado_bruto_musd / r.ingresos_musd)          AS margen_bruto_pct,
       r.costos_financieros_musd,
       r.resultado_neto_musd,
       r.ebitda_musd,
       r.toneladas_producidas,
       round(r.ingresos_musd * 1e6 / r.toneladas_producidas)          AS precio_implicito,
       round(f.usd_t)                                                 AS referencia_asia
FROM mineria.resultado_operacion r
LEFT JOIN referencia f ON f.anio = extract(year FROM r.periodo_fin) AND r.mina = 'Cauchari-Olaroz'
ORDER BY r.mina DESC, r.periodo_inicio;

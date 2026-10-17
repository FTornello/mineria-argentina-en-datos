-- P12. ¿Cómo fue el ciclo del oro en San Juan desde que arrancó Veladero?
--
-- Cómo: junto por año tres series de la provincia: las exportaciones mineras
-- (SIACAM), los puestos de trabajo en la minería de metales (OEDE, rama 1320,
-- promedio de los cuatro trimestres) y la producción de Veladero (informes de
-- Barrick). Veladero empezó a producir a fines de 2005.
--
-- Límites: las exportaciones son de toda la minería de San Juan, no solo de
-- Veladero. La producción de Veladero está cargada desde 2011 y falta 2017.

WITH exportado AS (
    SELECT anio, millones_usd FROM mineria.exportacion_provincia WHERE provincia = 'San Juan'
),
puestos AS (
    SELECT extract(year FROM fecha)::int AS anio, avg(empleo) AS puestos
    FROM mineria.empleo_rama
    WHERE provincia = 'San Juan' AND rama = '1320'
    GROUP BY 1
),
veladero AS (
    SELECT anio, produccion_total FROM mineria.produccion_mina WHERE mina = 'Veladero' AND mineral = 'Oro'
)
SELECT e.anio,
       round(e.millones_usd)   AS exportado_musd,
       round(p.puestos)        AS puestos_mineria_metales,
       v.produccion_total      AS veladero_miles_onzas
FROM exportado e
LEFT JOIN puestos p USING (anio)
LEFT JOIN veladero v USING (anio)
WHERE e.anio >= 2003
ORDER BY e.anio;

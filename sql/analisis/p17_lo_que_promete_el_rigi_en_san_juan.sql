-- P17. ¿De qué tamaño es lo que prometen los proyectos del RIGI en San Juan,
-- comparado con la minería que la provincia tiene hoy?
--
-- Cómo: pongo al lado de cada proyecto aprobado dos referencias de hoy: los
-- puestos registrados en la minería de metales de San Juan (primer trimestre
-- de 2026) y lo que exportó la minería sanjuanina en 2025.
--
-- Límites: no son números comparables uno a uno, y por eso van como
-- referencia y no como cuenta. Los empleos del RIGI son "directos e
-- indirectos" declarados por cada proyecto, sin separar obra de operación;
-- los puestos de hoy son solo directos y registrados. La inversión se
-- reparte en varios años; la exportación es de un año.

WITH hoy AS (
    SELECT (SELECT empleo FROM mineria.empleo_rama
            WHERE provincia = 'San Juan' AND rama = '1320' AND fecha = '2026-01-01') AS puestos_hoy,
           (SELECT millones_usd FROM mineria.exportacion_provincia
            WHERE provincia = 'San Juan' AND anio = 2025)                           AS exportado_2025
)
SELECT r.proyecto,
       r.mineral,
       r.fecha_resolucion,
       r.inversion_musd,
       r.empleos                                    AS empleos_declarados,
       round(r.empleos / h.puestos_hoy, 1)          AS veces_los_puestos_de_hoy,
       round(r.inversion_musd / h.exportado_2025, 1) AS veces_lo_exportado_en_2025
FROM mineria.rigi_proyecto r
CROSS JOIN hoy h
WHERE r.provincia = 'San Juan' AND r.sector = 'Minería'
UNION ALL
SELECT 'TOTAL San Juan', NULL, NULL, sum(r.inversion_musd), sum(r.empleos),
       round(sum(r.empleos) / max(h.puestos_hoy), 1),
       round(sum(r.inversion_musd) / max(h.exportado_2025), 1)
FROM mineria.rigi_proyecto r
CROSS JOIN hoy h
WHERE r.provincia = 'San Juan' AND r.sector = 'Minería'
ORDER BY inversion_musd;

-- P34. Vicuña, el proyecto de cobre más grande de San Juan, informó que en
-- 2025 trabajaban 2.576 personas de sus contratistas, 80% sanjuaninas
-- (primer Reporte de Sostenibilidad, según Ámbito, 25-9-2026). ¿Se ve ese
-- empleo en las estadísticas oficiales?
--
-- Cómo: dos miradas al empleo privado registrado (OEDE).
--   1. El departamento Iglesia, donde están Vicuña y Veladero: total de
--      puestos por año, sumando todos los sectores.
--   2. La provincia, en las ramas donde se anotaría el trabajo de obra y de
--      servicios para una mina: enero de cada año contra enero del anterior,
--      para no mezclar meses distintos.
--
-- Límites:
--   - El empleo se cuenta donde lo declara la empresa, no donde se trabaja.
--     Un contratista con sede en la Capital anota a su gente en la Capital.
--   - Que una rama crezca no dice que sea por el cobre: puede ser obra pública,
--     otra mina o cualquier otra cosa. Es una señal, no una medida.
--   - La cifra de Vicuña la informa la empresa; no la puedo verificar.

WITH iglesia AS (
    SELECT extract(year FROM fecha)::int AS anio, sum(empleo) / count(DISTINCT fecha) AS puestos
    FROM mineria.empleo_departamento
    WHERE provincia = 'SAN JUAN' AND departamento = 'IGLESIA'
    GROUP BY 1
),
ramas AS (
    SELECT extract(year FROM e.fecha)::int AS anio, r.rama, r.descripcion, e.empleo
    FROM mineria.empleo_rama e JOIN mineria.rama r USING (rama)
    WHERE e.provincia = 'San Juan' AND extract(month FROM e.fecha) = 1
      AND r.rama IN ('1320', '1429', '4519', '4520', '7499')
)
SELECT 'Iglesia, todos los sectores (promedio del año)' AS serie, anio, round(puestos) AS puestos
FROM iglesia
UNION ALL
SELECT rama || ' ' || left(descripcion, 45) || ' (enero)', anio, empleo
FROM ramas WHERE anio >= 2023
ORDER BY 1, 2;

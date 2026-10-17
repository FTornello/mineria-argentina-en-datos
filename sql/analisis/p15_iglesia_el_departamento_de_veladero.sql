-- P15. Iglesia es el departamento donde está Veladero. ¿Los salarios de los
-- que no trabajan en la mina son más altos ahí que en el resto de San Juan?
--
-- Cómo: para cada sector comparo el salario promedio de 2025 en Iglesia con
-- el del mismo sector en toda la provincia, y muestro cuántos puestos tiene
-- cada sector en Iglesia. Si la minería "derrama", comercio, servicios o
-- construcción deberían pagar más en Iglesia que en el promedio provincial.
-- Promedio enero a mayo y julio a noviembre, sin los meses de aguinaldo.
--
-- Límites: el trabajador se cuenta donde lo declara la empresa, no donde
-- vive: muchos mineros de Veladero viven en el Gran San Juan y figuran en
-- Iglesia. Con pocas empresas el dato del sector se tapa.

WITH datos AS (
    SELECT departamento, sector, fecha, empleo, salario
    FROM mineria.empleo_departamento
    WHERE provincia = 'SAN JUAN'
      AND fecha BETWEEN '2025-01-01' AND '2025-12-01'
      AND extract(month FROM fecha) NOT IN (6, 12)
      AND empleo IS NOT NULL AND salario IS NOT NULL
),
iglesia AS (
    SELECT sector, avg(empleo) AS puestos, avg(salario) AS salario
    FROM datos WHERE departamento = 'IGLESIA' GROUP BY sector
),
provincia AS (
    SELECT sector, sum(salario * empleo) / sum(empleo) AS salario
    FROM datos GROUP BY sector
)
SELECT i.sector,
       round(i.puestos)                         AS puestos_en_iglesia,
       round(i.salario)                         AS salario_en_iglesia,
       round(p.salario)                         AS salario_en_la_provincia,
       round(100 * (i.salario / p.salario - 1)) AS diferencia_pct
FROM iglesia i
JOIN provincia p USING (sector)
ORDER BY i.puestos DESC;

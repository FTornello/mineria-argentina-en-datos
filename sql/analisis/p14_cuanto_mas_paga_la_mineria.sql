-- P14. Se habla de una "guerra por profesionales" y de que la industria de
-- San Juan pierde empleados con la minería. ¿Cuánto más paga la minería?
--
-- Cómo: comparo el salario bruto promedio de la minería de metales (rama
-- 1320) con el del resto del empleo privado de la provincia. El salario del
-- resto es un promedio ponderado: cada rama pesa según cuántos puestos tiene.
-- Uso enero a mayo de cada año para no mezclar el aguinaldo, y el empleo del
-- primer trimestre como peso. Como son pesos corrientes, lo que se puede
-- comparar entre años es la relación ("veces"), no los montos.
-- Agrego la misma relación contra la industria manufacturera (ramas 15 a 37).
--
-- Límites: es un promedio; no distingue un ingeniero de un operario. Compara
-- salarios brutos registrados.

WITH salario AS (
    SELECT extract(year FROM fecha)::int AS anio, rama, avg(salario) AS salario
    FROM mineria.salario_rama
    WHERE provincia = 'San Juan' AND extract(month FROM fecha) BETWEEN 1 AND 5
    GROUP BY 1, 2
),
empleo AS (
    SELECT extract(year FROM fecha)::int AS anio, rama, empleo
    FROM mineria.empleo_rama
    WHERE provincia = 'San Juan' AND extract(month FROM fecha) = 1
),
junto AS (
    SELECT s.anio, s.rama, s.salario, e.empleo,
           s.rama ~ '^(1[5-9]|2[0-9]|3[0-7])[0-9][0-9]$' AS es_industria
    FROM salario s
    JOIN empleo e USING (anio, rama)
)
SELECT anio,
       round(max(salario) FILTER (WHERE rama = '1320'))                                               AS salario_mineria_metales,
       round(sum(salario * empleo) FILTER (WHERE rama <> '1320') / sum(empleo) FILTER (WHERE rama <> '1320')) AS salario_resto,
       round(sum(salario * empleo) FILTER (WHERE es_industria) / sum(empleo) FILTER (WHERE es_industria))     AS salario_industria,
       round(max(salario) FILTER (WHERE rama = '1320')
             / (sum(salario * empleo) FILTER (WHERE rama <> '1320') / sum(empleo) FILTER (WHERE rama <> '1320')), 1) AS veces_el_resto,
       round(max(salario) FILTER (WHERE rama = '1320')
             / (sum(salario * empleo) FILTER (WHERE es_industria) / sum(empleo) FILTER (WHERE es_industria)), 1)     AS veces_la_industria
FROM junto
WHERE anio IN (1998, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, 2023, 2024, 2025, 2026)
GROUP BY anio
ORDER BY anio;

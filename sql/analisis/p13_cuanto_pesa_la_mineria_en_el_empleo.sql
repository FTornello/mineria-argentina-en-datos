-- P13. ¿Cuánto pesa la minería en el empleo privado de San Juan?
--
-- Cómo: para el primer trimestre de cada año sumo los puestos registrados de
-- todas las ramas de la provincia y calculo qué parte son de minería. Separo
-- la minería de metales (rama 1320) del resto de minas y canteras (cal,
-- áridos y otras).
--
-- Límites: solo cuenta empleo directo y registrado en empresas cuya actividad
-- principal es minera. Los contratistas (transporte, comedor, construcción)
-- figuran en sus propias ramas, así que el empleo que mueve la minería es
-- mayor que este número. Las ramas con muy pocas empresas no se publican.

SELECT extract(year FROM e.fecha)::int AS anio,
       round(sum(e.empleo))                                          AS puestos_privados,
       round(sum(e.empleo) FILTER (WHERE e.rama = '1320'))           AS mineria_metales,
       round(sum(e.empleo) FILTER (WHERE r.es_mineria AND e.rama <> '1320')) AS otras_minas_y_canteras,
       round(100 * sum(e.empleo) FILTER (WHERE r.es_mineria) / sum(e.empleo), 1) AS pct_mineria
FROM mineria.empleo_rama e
JOIN mineria.rama r USING (rama)
WHERE e.provincia = 'San Juan'
  AND extract(month FROM e.fecha) = 1
  AND extract(year FROM e.fecha) IN (1996, 2000, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, 2024, 2025, 2026)
GROUP BY 1
ORDER BY 1;

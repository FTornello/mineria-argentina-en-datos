-- P19. Catamarca ya vivió el final de una mina grande: Bajo la Alumbrera
-- dejó de producir en 2018. ¿Qué pasó con las exportaciones y el empleo?
--
-- Cómo: junto por año la producción de cobre del país (CAEM; hasta 2018 es
-- prácticamente toda de Alumbrera), las exportaciones mineras de Catamarca
-- (SIACAM) y el empleo en minería metalífera de la provincia (SIACAM,
-- promedio del año). Agrego el empleo en litio, que es lo que vino después.
--
-- Límites: el empleo de SIACAM empieza en 2007. Las exportaciones de
-- Catamarca desde 2022 son sobre todo litio. Del cobre faltan 2019 a 2021 en
-- la fuente (fueron años sin producción relevante).

WITH empleo AS (
    SELECT anio,
           avg(metal) AS metaliferos,
           avg(litio) AS litio
    FROM (SELECT extract(year FROM fecha)::int AS anio, fecha,
                 sum(puestos) FILTER (WHERE rubro = 'Metalíferos') AS metal,
                 sum(puestos) FILTER (WHERE rubro = 'Litio')       AS litio
          FROM mineria.empleo
          WHERE provincia = 'Catamarca'
          GROUP BY 1, 2) por_mes
    GROUP BY anio
)
SELECT x.anio,
       c.produccion              AS cobre_pais_miles_ton,
       round(x.millones_usd)     AS catamarca_exportado_musd,
       round(e.metaliferos)      AS puestos_metaliferos,
       round(e.litio)            AS puestos_litio
FROM mineria.exportacion_provincia x
LEFT JOIN mineria.produccion_anual c ON c.anio = x.anio AND c.mineral = 'Cobre'
LEFT JOIN empleo e ON e.anio = x.anio
WHERE x.provincia = 'Catamarca' AND x.anio >= 2005
ORDER BY x.anio;

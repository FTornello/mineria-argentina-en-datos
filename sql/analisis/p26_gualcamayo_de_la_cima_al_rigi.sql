-- P26. Gualcamayo, en Jáchal, fue la segunda mina de oro de San Juan. ¿Cómo
-- terminó su producción, y qué promete el proyecto que entró al RIGI?
--
-- Cómo: junto la producción anual de la mina (informes de Yamana hasta 2018
-- y de Mineros desde 2020), la ley, la recuperación y el costo total por
-- onza, y al final la inversión y el empleo que declara el proyecto de
-- Carbonatos Profundos aprobado en el RIGI en enero de 2026.
--
-- Límites: falta 2019 (no encontré el informe de Mineros de ese año) y 2023
-- cubre solo hasta septiembre, cuando la mina se vendió a una empresa que no
-- publica datos. Desde entonces no hay producción informada.

SELECT p.anio::text,
       p.empresa,
       p.publicado                                                    AS miles_onzas,
       max(o.valor) FILTER (WHERE o.indicador = 'ley')                AS ley_g_t,
       max(o.valor) FILTER (WHERE o.indicador = 'recuperacion')       AS recuperacion_pct,
       max(o.valor) FILTER (WHERE o.indicador = 'aisc')               AS aisc_usd_oz,
       p.nota
FROM mineria.produccion_mina p
LEFT JOIN mineria.operacion_mina o ON o.mina = p.mina AND o.anio = p.anio
WHERE p.mina = 'Gualcamayo'
GROUP BY p.anio, p.empresa, p.publicado, p.nota
UNION ALL
SELECT 'RIGI', empresa, NULL, NULL, NULL, NULL,
       'Carbonatos Profundos: ' || inversion_musd || ' millones de dólares, ' || empleos
       || ' empleos declarados, resolución del ' || to_char(fecha_resolucion, 'DD-MM-YYYY')
FROM mineria.rigi_proyecto
WHERE proyecto LIKE '%Carbonatos Profundos%'
ORDER BY 1;

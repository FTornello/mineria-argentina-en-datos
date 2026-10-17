-- P18. Los proyectos de cobre ya están aprobados. ¿Cuándo se invierte la plata?
--
-- Cómo: tomo el plan de inversión por año del tablero oficial del RIGI y
-- muestro, para cobre, litio y oro y plata, cuánto se prevé invertir cada año
-- y cuánto va acumulado como porcentaje del total.
--
-- Límite: es el plan que declararon los proyectos al adherir. No es
-- inversión hecha; los proyectos mineros suelen atrasarse.

SELECT anio,
       max(musd) FILTER (WHERE rubro = 'Cobre')        AS cobre_musd,
       max(musd) FILTER (WHERE rubro = 'Litio')        AS litio_musd,
       max(musd) FILTER (WHERE rubro = 'Oro y plata')  AS oro_plata_musd,
       round(100 * sum(max(musd) FILTER (WHERE rubro = 'Cobre')) OVER (ORDER BY anio)
             / sum(max(musd) FILTER (WHERE rubro = 'Cobre')) OVER ())  AS cobre_acumulado_pct,
       round(100 * sum(max(musd) FILTER (WHERE rubro = 'Litio')) OVER (ORDER BY anio)
             / sum(max(musd) FILTER (WHERE rubro = 'Litio')) OVER ())  AS litio_acumulado_pct
FROM mineria.rigi_plan_inversion
WHERE anio <= 2033
GROUP BY anio
ORDER BY anio;

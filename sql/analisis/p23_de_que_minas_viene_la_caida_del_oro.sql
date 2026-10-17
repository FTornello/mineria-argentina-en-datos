-- P23. La producción de oro del país cayó. ¿De qué minas viene la caída?
--
-- Cómo: pongo al lado, año por año, la producción total del país (CAEM) y la
-- de cada mina que tengo cargada desde los informes de su empresa, siempre
-- llevada al 100% de la mina. "resto" es lo que queda: las minas que no tengo.
--
-- Límites:
--   - Tres datos cubren parte del año y no entran en la suma: Veladero 2017,
--     Cerro Negro 2019 y Cerro Moro 2023 (cambios de dueño a mitad de año).
--     En esos años el "resto" queda inflado; la columna minas_con_dato avisa.
--   - Faltan Gualcamayo desde 2019, San José antes de 2021, Cerro Vanguardia
--     antes de 2019, Bajo la Alumbrera de 2016 a 2018 (producía oro además
--     de cobre) y las minas chicas (Don Nicolás, Casposo, Cap Oeste,
--     Manantial Espejo, Farallón Negro).
--   - Son dos fuentes distintas (las empresas y la cámara), así que la suma
--     de las minas no tiene por qué dar exacto el total.

WITH minas AS (
    SELECT anio,
           max(produccion_total) FILTER (WHERE mina = 'Veladero')         AS veladero,
           max(produccion_total) FILTER (WHERE mina = 'Gualcamayo')       AS gualcamayo,
           max(produccion_total) FILTER (WHERE mina = 'Cerro Negro')      AS cerro_negro,
           max(produccion_total) FILTER (WHERE mina = 'Cerro Vanguardia') AS cerro_vanguardia,
           max(produccion_total) FILTER (WHERE mina = 'Cerro Moro')       AS cerro_moro,
           max(produccion_total) FILTER (WHERE mina = 'San José')         AS san_jose,
           max(produccion_total) FILTER (WHERE mina = 'Lindero')          AS lindero,
           max(produccion_total) FILTER (WHERE mina = 'Bajo la Alumbrera') AS alumbrera,
           sum(produccion_total)                                          AS suma,
           count(produccion_total)                                        AS minas_con_dato
    FROM mineria.produccion_mina
    WHERE mineral = 'Oro'
    GROUP BY anio
)
SELECT p.anio,
       p.produccion            AS pais,
       round(m.veladero)         AS veladero,
       round(m.gualcamayo)       AS gualcamayo,
       round(m.cerro_negro)      AS cerro_negro,
       round(m.cerro_vanguardia) AS c_vanguardia,
       round(m.cerro_moro)       AS cerro_moro,
       round(m.san_jose)         AS san_jose,
       round(m.lindero)          AS lindero,
       round(m.alumbrera)        AS alumbrera,
       m.minas_con_dato,
       round(p.produccion - m.suma)        AS resto,
       round(100 * m.suma / p.produccion)  AS pct_cubierto
FROM mineria.produccion_anual p
JOIN minas m USING (anio)
WHERE p.mineral = 'Oro'
ORDER BY p.anio;

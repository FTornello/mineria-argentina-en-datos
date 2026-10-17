-- P28. ¿Cuánto pagan al Estado, en total, las mineras que informan en Canadá,
-- y cómo se reparte entre oro y plata, litio y proyectos en construcción?
--
-- Cómo: sumo por año los pagos de la base canadiense ESTMA (solo minería),
-- agrupando los proyectos en tres tipos. Le sumo Veladero, que no está en
-- ESTMA, con el informe de Barrick.
--
-- Límites: no están todas las mineras del país, solo las que cotizan en
-- Canadá o tienen filiales allá (faltan, por ejemplo, Livent y Eramet en
-- litio, y Hochschild en oro y plata). Algunos proyectos de litio entran y
-- salen de la base según quién era el dueño ese año (Allkem hasta 2023, Rio
-- Tinto desde 2024). Los montos son pagos en efectivo de cada año.

WITH tipo AS (
    SELECT anio, usd / 1e6 AS musd,
           CASE WHEN mina IN ('Olaroz', 'Sal de Vida', 'Rincón', 'Cauchari', 'Proyecto Pastos Grandes',
                              'Hombre Muerto', 'Tolillar', 'Borax', 'Lithium Exploration') THEN 'Litio'
                WHEN mina IN ('Cerro Negro', 'Cerro Vanguardia', 'Lindero', 'Cerro Moro', 'Gualcamayo',
                              'Don Nicolás', 'Casposo', 'Manantial Espejo', 'Puna (Pirquitas y Chinchillas)',
                              'Aguilar') THEN 'Oro, plata y zinc en producción'
                ELSE 'Proyectos y exploración' END AS grupo
    FROM mineria.pago_gobierno
    WHERE sector = 'Minería'
    UNION ALL
    SELECT anio, millones_usd, 'Oro, plata y zinc en producción' FROM mineria.contribucion_tributaria
)
SELECT anio,
       round(sum(musd) FILTER (WHERE grupo = 'Oro, plata y zinc en producción')) AS oro_plata_zinc,
       round(sum(musd) FILTER (WHERE grupo = 'Litio'))                           AS litio,
       round(sum(musd) FILTER (WHERE grupo = 'Proyectos y exploración'))         AS proyectos,
       round(sum(musd))                                                          AS total_musd
FROM tipo
WHERE anio BETWEEN 2021 AND 2025
GROUP BY anio
ORDER BY anio;

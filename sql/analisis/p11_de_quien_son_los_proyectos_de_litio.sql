-- P11. Se habla del litio argentino como estratégico para Estados Unidos.
-- ¿De qué países son las empresas que lo producen y las que están por producir?
--
-- Cómo: en la cartera de proyectos de la Secretaría de Minería miro los
-- proyectos de litio en producción, en construcción y con factibilidad, y
-- cuento por país del primer controlante (el dueño principal).
--
-- Límites: es una foto a junio de 2026. El "país de origen" es el que anota
-- la Secretaría para la empresa controlante: Rio Tinto figura como Reino
-- Unido y Lithium Argentina como Suiza, aunque coticen o tengan accionistas
-- en otros lados. Solo cuento al primer controlante.

SELECT estado,
       coalesce(origen_1, 'sin dato') AS pais_del_controlante,
       count(*)                       AS proyectos,
       string_agg(nombre, ', ' ORDER BY nombre) AS cuales
FROM mineria.proyecto
WHERE mineral = 'Litio'
  AND estado IN ('Producción', 'Construcción', 'Factibilidad')
GROUP BY estado, origen_1
ORDER BY CASE estado WHEN 'Producción' THEN 1 WHEN 'Construcción' THEN 2 ELSE 3 END, proyectos DESC;

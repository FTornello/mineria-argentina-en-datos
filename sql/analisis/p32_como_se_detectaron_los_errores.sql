-- P32. De las afirmaciones que resultaron estar mal durante el proyecto (casi
-- todas propuestas por la IA), ¿cómo se detectó cada una?
--
-- Cómo: cuento las correcciones registradas en correccion_ia por forma de
-- detección y por tipo de error.
--
-- Límites: solo están las que se detectaron y quedaron escritas en la
-- bitácora. Las que no se detectaron, por definición, no están.

SELECT como_se_detecto,
       count(*)                                    AS casos,
       string_agg(DISTINCT tipo, ', ')             AS tipos_de_error,
       string_agg(numero::text, ', ' ORDER BY numero) AS correcciones
FROM mineria.correccion_ia
GROUP BY como_se_detecto
ORDER BY casos DESC, como_se_detecto;

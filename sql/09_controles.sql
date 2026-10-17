-- Controles: cada fila compara dos números que tienen que coincidir. La
-- columna ok tiene que dar true en todas; si alguna da false, el script corta
-- con error y la reconstrucción se frena.
--   psql -d mineria -f sql/09_controles.sql

CREATE TEMP TABLE control AS
WITH indec_por_anio AS (
    SELECT anio, count(*) AS filas, sum(mineria.numero_indec(fob_usd)) AS fob
    FROM raw.indec_exportaciones
    GROUP BY anio
),
-- Oro y litio por año según cada fuente, para el cruce entre INDEC y SIACAM.
cruce AS (
    SELECT i.anio, i.grupo, i.fob AS indec, s.fob AS siacam
    FROM (SELECT extract(year FROM e.fecha) AS anio, p.grupo, sum(e.fob_usd) AS fob
          FROM mineria.exportacion e JOIN mineria.producto p USING (ncm)
          GROUP BY 1, 2) i
    JOIN (SELECT extract(year FROM fecha) AS anio, grupo, sum(fob_usd) AS fob
          FROM mineria.exportacion_siacam
          GROUP BY 1, 2) s USING (anio, grupo)
)
-- 1. La carga del INDEC está completa: el propio INDEC declara cuántas filas
--    y cuántos dólares tiene cada archivo anual.
SELECT 'INDEC: años con distinta cantidad de filas que la declarada' AS control,
       0::numeric AS esperado,
       (SELECT count(*) FROM raw.indec_totales_control t JOIN indec_por_anio c USING (anio)
        WHERE t.registros::int <> c.filas)::numeric AS obtenido
UNION ALL
SELECT 'INDEC: años con distintos dólares que los declarados (más de 1 USD)',
       0,
       (SELECT count(*) FROM raw.indec_totales_control t JOIN indec_por_anio c USING (anio)
        WHERE abs(mineria.numero_indec(t.fob_usd) - c.fob) > 1)
UNION ALL
SELECT 'INDEC: años cargados',
       (SELECT count(*) FROM raw.indec_totales_control),
       (SELECT count(*) FROM indec_por_anio)
UNION ALL
-- 2. La capa limpia no pierde ni inventa filas.
SELECT 'exportaciones mineras: filas',
       (SELECT count(*) FROM raw.indec_exportaciones e JOIN raw.ncm_minero n USING (ncm)),
       (SELECT count(*) FROM mineria.exportacion)
UNION ALL
SELECT 'exportaciones mineras: dólares visibles',
       (SELECT round(sum(mineria.numero_indec(e.fob_usd)))
        FROM raw.indec_exportaciones e JOIN raw.ncm_minero n USING (ncm)),
       (SELECT round(sum(fob_usd)) FROM mineria.exportacion)
UNION ALL
SELECT 'exportaciones mineras: filas tapadas',
       (SELECT count(*) FROM raw.indec_exportaciones e JOIN raw.ncm_minero n USING (ncm)
        WHERE e.fob_usd ~ '^s'),
       (SELECT count(*) FROM mineria.exportacion WHERE confidencial)
UNION ALL
SELECT 'exportaciones mineras: filas tapadas anteriores a 2018',
       0,
       (SELECT count(*) FROM mineria.exportacion WHERE confidencial AND fecha < '2018-01-01')
UNION ALL
SELECT 'productos mineros', (SELECT count(*) FROM raw.ncm_minero), (SELECT count(*) FROM mineria.producto)
UNION ALL
SELECT 'SIACAM exportaciones: filas',
       (SELECT count(*) FROM raw.siacam_expo_minerales), (SELECT count(*) FROM mineria.exportacion_siacam)
UNION ALL
SELECT 'SIACAM exportaciones: dólares',
       (SELECT round(sum(fob::numeric)) FROM raw.siacam_expo_minerales),
       (SELECT round(sum(fob_usd)) FROM mineria.exportacion_siacam)
UNION ALL
SELECT 'empleo: filas', (SELECT count(*) FROM raw.siacam_empleo), (SELECT count(*) FROM mineria.empleo)
UNION ALL
SELECT 'empleo: puestos sumados',
       (SELECT sum(cantidad::numeric) FROM raw.siacam_empleo), (SELECT sum(puestos) FROM mineria.empleo)
UNION ALL
SELECT 'precios: filas', (SELECT count(*) FROM raw.siacam_precios), (SELECT count(*) FROM mineria.precio)
UNION ALL
SELECT 'proyectos', (SELECT count(*) FROM raw.siacam_cartera), (SELECT count(*) FROM mineria.proyecto)
UNION ALL
SELECT 'anuncios de inversión', (SELECT count(*) FROM raw.siacam_anuncios), (SELECT count(*) FROM mineria.anuncio_inversion)
UNION ALL
SELECT 'anuncios de inversión: dólares',
       (SELECT sum(dolares::numeric) FROM raw.siacam_anuncios), (SELECT sum(usd) FROM mineria.anuncio_inversion)
UNION ALL
-- El acumulado que trae el archivo en su última fila tiene que ser la suma.
SELECT 'anuncios de inversión: suma contra el acumulado del archivo',
       (SELECT max(acumulado::numeric) FROM raw.siacam_anuncios), (SELECT sum(usd) FROM mineria.anuncio_inversion)
UNION ALL
SELECT 'impuestos: filas (6 impuestos por empresa y año)',
       (SELECT count(*) * 6 FROM raw.siacam_impuestos_pesos), (SELECT count(*) FROM mineria.impuesto_empresa)
UNION ALL
-- El archivo en pesos trae el total por empresa; tiene que coincidir con la
-- suma de los seis impuestos (redondeado a millones).
SELECT 'impuestos: empresas-año cuyo total en pesos no es la suma (más de 1 millón)',
       0,
       (SELECT count(*) FROM raw.siacam_impuestos_pesos p
        JOIN (SELECT anio, empresa, sum(millones_pesos) AS suma FROM mineria.impuesto_empresa GROUP BY 1, 2) i
          ON i.anio = p.anio::int AND i.empresa = trim(p.empresa)
        WHERE abs(p.total_empresa::numeric - i.suma) > 1)
UNION ALL
SELECT 'índice de producción: filas con dato',
       (SELECT count(*) FROM raw.siacam_ipi_ramas WHERE indice IS NOT NULL), (SELECT count(*) FROM mineria.indice_produccion)
UNION ALL
SELECT 'producción de litio: filas', (SELECT count(*) FROM raw.siacam_ipi_litio), (SELECT count(*) FROM mineria.produccion_litio)
UNION ALL
SELECT 'empresas por rubro: filas', (SELECT count(*) FROM raw.siacam_empresas), (SELECT count(*) FROM mineria.empresas_por_rubro)
UNION ALL
SELECT 'cuentas nacionales: filas', (SELECT count(*) FROM raw.siacam_cuentas_nacionales), (SELECT count(*) FROM mineria.cuentas_nacionales)
UNION ALL
SELECT 'balance cambiario: filas', (SELECT count(*) FROM raw.siacam_balance_cambiario), (SELECT count(*) FROM mineria.balance_cambiario)
UNION ALL
-- Dos archivos de SIACAM que tienen que dar el mismo total: las exportaciones
-- por provincia y las exportaciones por grupo de mineral, año por año.
SELECT 'exportaciones por provincia: años que difieren del total por grupo (más de 1%)',
       0,
       (SELECT count(*)
        FROM (SELECT anio, sum(millones_usd) AS m FROM mineria.exportacion_provincia GROUP BY 1) p
        JOIN (SELECT extract(year FROM fecha) AS anio, sum(fob_usd) / 1e6 AS m
              FROM mineria.exportacion_siacam GROUP BY 1) s USING (anio)
        WHERE abs(p.m / s.m - 1) > 0.01)
UNION ALL
-- Lo mismo para el litio: la suma por destino contra el total anual.
SELECT 'litio: años en que la suma por destino difiere del total anual (más de 1%)',
       0,
       (SELECT count(*)
        FROM (SELECT anio, sum(millones_usd) AS m FROM mineria.exportacion_litio_destino GROUP BY 1) d
        JOIN mineria.exportacion_litio_anual a USING (anio)
        WHERE abs(d.m / a.millones_usd - 1) > 0.01)
UNION ALL
-- 3. Dos fuentes, el mismo número. El oro exportado según el INDEC y según
--    SIACAM tiene que diferir menos de 5% cada año desde 2006. Para el litio
--    vale hasta 2017: después el INDEC tapa parte del total.
SELECT 'oro 2006-2025: años en que INDEC y SIACAM difieren más de 5%',
       0,
       (SELECT count(*) FROM cruce
        WHERE grupo = 'Oro' AND anio BETWEEN 2006 AND 2025 AND abs(indec / siacam - 1) > 0.05)
UNION ALL
SELECT 'litio 2002-2017: años en que INDEC y SIACAM difieren más de 5%',
       0,
       (SELECT count(*) FROM cruce
        WHERE grupo = 'Litio' AND anio BETWEEN 2002 AND 2017 AND abs(indec / siacam - 1) > 0.05);

-- 4. Datos espejo. Esta sí es una comprobación independiente: lo que suman las
--    aduanas de los países compradores contra lo que declara la Argentina.
INSERT INTO control
SELECT 'datos espejo: filas',
       (SELECT count(*) FROM raw.comtrade_importaciones)::numeric,
       (SELECT count(*) FROM mineria.importacion_espejo)::numeric
UNION ALL
SELECT 'datos espejo: dólares',
       (SELECT round(sum(primary_value::numeric)) FROM raw.comtrade_importaciones),
       (SELECT round(sum(valor_usd)) FROM mineria.importacion_espejo)
UNION ALL
SELECT 'oro 2012-2025: años en que los compradores y el INDEC difieren más de 6%',
       0,
       (SELECT count(*)
        FROM (SELECT extract(year FROM fecha) AS anio, sum(valor_usd) AS v
              FROM mineria.importacion_espejo WHERE frecuencia = 'A' AND hs6 = '710812' GROUP BY 1) m
        JOIN (SELECT extract(year FROM fecha) AS anio, sum(fob_usd) AS v
              FROM mineria.exportacion WHERE ncm LIKE '710812%' GROUP BY 1) i USING (anio)
        WHERE anio BETWEEN 2012 AND 2025 AND abs(m.v / i.v - 1) > 0.06)
UNION ALL
-- Los doce meses de un año tienen que sumar lo mismo que el dato anual.
SELECT 'oro espejo 2018-2025: años en que la suma mensual difiere de la anual más de 1%',
       0,
       (SELECT count(*)
        FROM (SELECT extract(year FROM fecha) AS anio,
                     sum(valor_usd) FILTER (WHERE frecuencia = 'M') AS mensual,
                     sum(valor_usd) FILTER (WHERE frecuencia = 'A') AS anual
              FROM mineria.importacion_espejo
              WHERE hs6 = '710812' AND fecha BETWEEN '2018-01-01' AND '2025-12-01' GROUP BY 1) x
        WHERE abs(mensual / anual - 1) > 0.01);

-- 5. Empleo y salarios del OEDE.
INSERT INTO control
SELECT 'OEDE por departamento: filas',
       (SELECT count(*) FROM raw.oede_departamento_sector)::numeric, (SELECT count(*) FROM mineria.empleo_departamento)::numeric
UNION ALL
SELECT 'OEDE por departamento: filas con dato de empleo',
       (SELECT count(*) FROM raw.oede_departamento_sector WHERE empleo <> 's.d.'),
       (SELECT count(empleo) FROM mineria.empleo_departamento)
UNION ALL
SELECT 'OEDE por departamento: empleo sumado',
       (SELECT sum(empleo::numeric) FROM raw.oede_departamento_sector WHERE empleo <> 's.d.'),
       (SELECT sum(empleo) FROM mineria.empleo_departamento)
UNION ALL
SELECT 'OEDE salarios por rama: filas',
       (SELECT count(*) FROM raw.oede_remuneraciones_rama), (SELECT count(*) FROM mineria.salario_rama)
UNION ALL
SELECT 'OEDE empleo por rama: filas',
       (SELECT count(*) FROM raw.oede_empleo_rama), (SELECT count(*) FROM mineria.empleo_rama)
UNION ALL
SELECT 'OEDE empleo por rama: puestos sumados',
       (SELECT round(sum(empleo::numeric)) FROM raw.oede_empleo_rama), (SELECT round(sum(empleo)) FROM mineria.empleo_rama)
UNION ALL
-- 6. RIGI. Los totales son los que mostraba el tablero oficial el 13-10-2026.
--    Si se actualizan los CSV, hay que actualizar estos tres números.
SELECT 'RIGI: proyectos aprobados', 24, (SELECT count(*) FROM mineria.rigi_proyecto)
UNION ALL
SELECT 'RIGI: inversión total (millones de USD)', 56198, (SELECT sum(inversion_musd) FROM mineria.rigi_proyecto)
UNION ALL
SELECT 'RIGI: empleos declarados', 116350, (SELECT sum(empleos) FROM mineria.rigi_proyecto)
UNION ALL
SELECT 'RIGI: proyectos mineros', 12, (SELECT count(*) FROM mineria.rigi_proyecto WHERE sector = 'Minería')
UNION ALL
SELECT 'RIGI: plan de inversión, filas (33 años por 7 rubros)', 231, (SELECT count(*) FROM mineria.rigi_plan_inversion);

-- 7. Producción anual de CAEM, copiada a mano del PDF. Se controla contra
--    los promedios que el propio informe publica en la página 12.
INSERT INTO control
SELECT 'CAEM: filas', (SELECT count(*) FROM raw.caem_produccion)::numeric, (SELECT count(*) FROM mineria.produccion_anual)::numeric
UNION ALL
SELECT 'CAEM: promedio de oro 2014-2019 (miles de onzas)', 1865,
       (SELECT round(avg(produccion)) FROM mineria.produccion_anual WHERE mineral = 'Oro' AND anio BETWEEN 2014 AND 2019)
UNION ALL
SELECT 'CAEM: promedio de oro 2020-2025 (miles de onzas)', 1215,
       (SELECT round(avg(produccion)) FROM mineria.produccion_anual WHERE mineral = 'Oro' AND anio BETWEEN 2020 AND 2025);

-- 8. Producción por mina, copiada a mano de los informes de las empresas.
--    El informe de Barrick de 2024 da los dos números de Veladero: 252 mil
--    onzas por su 50% y 505 mil por el total. Sirve para controlar la cuenta.
INSERT INTO control
SELECT 'producción por mina: filas', (SELECT count(*) FROM raw.produccion_mina)::numeric, (SELECT count(*) FROM mineria.produccion_mina)::numeric
UNION ALL
SELECT 'Veladero 2024 al 100%: diferencia con las 505 mil onzas del informe (tolerancia 1)', 0,
       (SELECT CASE WHEN abs(produccion_total - 505) <= 1 THEN 0 ELSE 1 END
        FROM mineria.produccion_mina WHERE mina = 'Veladero' AND anio = 2024 AND mineral = 'Oro');

-- 9. Regalías de San Juan y tipo de cambio.
INSERT INTO control
SELECT 'regalías de San Juan: filas', (SELECT count(*) FROM raw.sanjuan_regalias)::numeric, (SELECT count(*) FROM mineria.regalias_san_juan)::numeric
UNION ALL
SELECT 'tipo de cambio: filas', (SELECT count(*) FROM raw.tipo_cambio_bna), (SELECT count(*) FROM mineria.tipo_cambio)
UNION ALL
-- Dos caminos: la ley fija la regalía en 3% del valor en boca de mina. Lo
-- cobrado, pasado a dólares, tiene que quedar cerca del 3% de las
-- exportaciones mineras de la provincia cada año. El rango es de 2% a 4%
-- porque el renglón incluye regalías hidroeléctricas y porque paso a dólares
-- con el tipo de cambio promedio del año. (Primero puse 1,5% a 3,5% y 2022,
-- con 3,6%, hizo saltar el control.)
SELECT 'regalías de San Juan 2017-2025: años fuera del rango 2% a 4% de lo exportado', 0,
       (SELECT count(*)
        FROM mineria.regalias_san_juan r
        JOIN (SELECT extract(year FROM fecha) AS anio, avg(pesos_por_usd) AS tc FROM mineria.tipo_cambio GROUP BY 1) t USING (anio)
        JOIN mineria.exportacion_provincia x ON x.anio = r.anio AND x.provincia = 'San Juan'
        WHERE r.regalias_total_pesos / t.tc / 1e6 / x.millones_usd NOT BETWEEN 0.02 AND 0.04);

INSERT INTO control
SELECT 'operación por mina: filas', (SELECT count(*) FROM raw.operacion_mina)::numeric, (SELECT count(*) FROM mineria.operacion_mina)::numeric
UNION ALL
-- Dos caminos dentro de los mismos informes: el oro producido tiene que ser
-- toneladas por ley por recuperación. Sirve para detectar un error al copiar.
SELECT 'Cerro Negro: años en que toneladas por ley por recuperación difiere más de 3% de lo producido', 0,
       (SELECT count(*)
        FROM (SELECT anio,
                     max(valor) FILTER (WHERE indicador = 'toneladas_procesadas')
                     * max(valor) FILTER (WHERE indicador = 'ley')
                     * max(valor) FILTER (WHERE indicador = 'recuperacion') / 100 / 31.1035 AS calculado
              FROM mineria.operacion_mina WHERE mina = 'Cerro Negro' GROUP BY anio) o
        JOIN mineria.produccion_mina p ON p.mina = 'Cerro Negro' AND p.anio = o.anio
        WHERE o.calculado IS NOT NULL AND abs(o.calculado / p.publicado - 1) > 0.03);

-- 10. Pagos a gobiernos.
INSERT INTO control
SELECT 'ESTMA: filas de Argentina por proyecto y distintas de cero',
       (SELECT count(*) FROM raw.estma WHERE pais LIKE 'AR:%' AND tipo_fila LIKE 'PROJECT%'
          AND sub_proyecto LIKE '\_Z%' AND valor::numeric <> 0)::numeric,
       (SELECT count(*) FROM mineria.pago_gobierno)
       + (SELECT coalesce(sum(veces_repetido), 0) FROM mineria.pago_gobierno_repetido)
UNION ALL
SELECT 'ESTMA: dólares canadienses de Argentina (los que quedaron más los repetidos)',
       (SELECT round(sum(valor::numeric)) FROM raw.estma WHERE pais LIKE 'AR:%' AND tipo_fila LIKE 'PROJECT%'
          AND sub_proyecto LIKE '\_Z%'),
       (SELECT round(sum(cad)) FROM mineria.pago_gobierno)
       + (SELECT round(coalesce(sum(cad * veces_repetido), 0)) FROM mineria.pago_gobierno_repetido)
UNION ALL
SELECT 'tipo de cambio canadiense: años', 9, (SELECT count(*) FROM mineria.tipo_cambio_cad)
UNION ALL
SELECT 'contribución tributaria: filas', (SELECT count(*) FROM raw.contribucion_tributaria), (SELECT count(*) FROM mineria.contribucion_tributaria);

INSERT INTO control
SELECT 'resultados por operación: filas', (SELECT count(*) FROM raw.resultados_operacion)::numeric, (SELECT count(*) FROM mineria.resultado_operacion)::numeric
UNION ALL
-- Dentro del mismo informe: ingresos tiene que ser toneladas vendidas por
-- precio, con una diferencia chica por ventas de subproductos.
SELECT 'Olaroz: ejercicios en que toneladas por precio difiere de los ingresos más de 5%', 0,
       (SELECT count(*) FROM mineria.resultado_operacion
        WHERE abs(toneladas_vendidas * precio_usd_t / 1e6 / ingresos_musd - 1) > 0.05);

INSERT INTO control
SELECT 'correcciones: filas cargadas', (SELECT count(*) FROM raw.correcciones_ia)::numeric, (SELECT count(*) FROM mineria.correccion_ia)::numeric
UNION ALL
-- Los números de corrección van de 1 en 1, sin saltos: si se borra una, se nota.
SELECT 'correcciones: números salteados', 0, (SELECT max(numero) - count(*) FROM mineria.correccion_ia)
UNION ALL
-- Cada hecho es de una mina que está en la producción o en la cartera de proyectos.
SELECT 'hechos: minas que no están en la producción ni en la cartera', 0,
       (SELECT count(*) FROM mineria.hecho_mina h
        WHERE h.mina <> 'Argentina'    -- hechos de todo el país
          AND NOT EXISTS (SELECT 1 FROM mineria.produccion_mina m WHERE m.mina = h.mina)
          AND NOT EXISTS (SELECT 1 FROM mineria.proyecto p WHERE p.nombre LIKE h.mina || '%'))
UNION ALL
-- Las entradas al RIGI tienen que coincidir con el tablero oficial.
SELECT 'hechos: inversión RIGI distinta del tablero', 0,
       (SELECT count(*) FROM mineria.hecho_mina h
        WHERE h.tipo = 'RIGI' AND NOT EXISTS (
            SELECT 1 FROM mineria.rigi_proyecto r
            WHERE r.inversion_musd = h.inversion_musd AND r.provincia = 'San Juan'));

SELECT control, esperado, obtenido, esperado = obtenido AS ok FROM control;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM control WHERE esperado IS DISTINCT FROM obtenido) THEN
        RAISE EXCEPTION 'Hay controles que no cierran';
    END IF;
END $$;

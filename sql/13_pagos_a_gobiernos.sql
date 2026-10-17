-- Pagos de las mineras a los gobiernos argentinos, por proyecto y año.
--   psql -d mineria -f sql/13_pagos_a_gobiernos.sql
--
-- Fuente principal: ESTMA, la ley canadiense que obliga a las empresas
-- extractivas que cotizan en Canadá a publicar lo que pagan a cada gobierno
-- del mundo, proyecto por proyecto. Statistics Canada junta todos los
-- informes en una base. Cubre 2021 a 2025 y viene en dólares canadienses.
-- Veladero no está, porque Barrick la comparte con Shandong; para esa mina se
-- usa el informe de contribución tributaria de Barrick.

DROP TABLE IF EXISTS raw.estma;
CREATE TABLE raw.estma (
    structure text, structure_id text, action text, frecuencia text, continente text, pais text,
    entidad_legal text, jurisdiccion text, proyecto text, sub_proyecto text, tipo_fila text,
    tipo_pago text, anio text, valor text, inicio_ejercicio text, fin_ejercicio text,
    tipo_informe text, nota_total text, moneda text, multiplicador text, enlace text,
    empresa_madre text, notas text
);
\copy raw.estma FROM 'data/raw/estma/STC_DF_ESTMA-eng.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS raw.boc_usdcad;
CREATE TABLE raw.boc_usdcad (fecha text, cad_por_usd text);
\copy raw.boc_usdcad FROM 'data/raw/boc/fx_usdcad_diario.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS raw.contribucion_tributaria;
CREATE TABLE raw.contribucion_tributaria (mina text, anio text, millones_usd text, concepto text, fuente text, pagina text, nota text);
\copy raw.contribucion_tributaria FROM 'data/contribucion_tributaria_empresas.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Dólares canadienses por dólar estadounidense, promedio de cada año.
DROP TABLE IF EXISTS mineria.tipo_cambio_cad;
CREATE TABLE mineria.tipo_cambio_cad (
    anio         integer PRIMARY KEY,
    cad_por_usd  numeric NOT NULL
);
INSERT INTO mineria.tipo_cambio_cad
SELECT extract(year FROM fecha::date)::int, avg(cad_por_usd::numeric)
FROM raw.boc_usdcad GROUP BY 1;

-- Una fila por proyecto, año y tipo de pago, solo Argentina.
-- La base trae cada pago dos veces: una vez por gobierno que lo recibe
-- ("Payee") y otra por proyecto ("Project"). Se usan solo las filas por
-- proyecto, sin las subdivisiones, y sin las filas en cero.
--   mina:      unifica cómo escribe cada empresa el nombre del proyecto
--              ("CERRO NEGRO - GOLD/UNDERGROUND/AR-Z", "ESTELAR" para Cerro
--              Moro, "SALES DE JUJUY" para Olaroz).
--   sector:    Hidrocarburos para TotalEnergies, Equinor y Crown Point, que
--              también informan en Argentina; Minería para el resto.
--   tipo_pago: Impuestos (sobre la renta, la producción o las ganancias; no
--              incluye IVA ni lo retenido a empleados), Regalías, Tasas y
--              cánones, Bonos, Pagos por infraestructura, Derechos de
--              producción, Dividendos.
CREATE TEMP TABLE pagos_crudos AS
SELECT e.anio::int AS anio,
       CASE WHEN e.proyecto ILIKE '%CERRO NEGRO%' AND e.entidad_legal ILIKE '%NEWMONT%' THEN 'Cerro Negro'
            WHEN e.proyecto ILIKE '%CERRO VANGUARDIA%' THEN 'Cerro Vanguardia'
            WHEN e.proyecto ILIKE '%LINDERO%'          THEN 'Lindero'
            WHEN e.proyecto ILIKE '%CERRO MORO%' OR e.proyecto ILIKE '%: ESTELAR' THEN 'Cerro Moro'
            WHEN e.proyecto ILIKE '%PUNA%'             THEN 'Puna (Pirquitas y Chinchillas)'
            WHEN e.proyecto ILIKE '%OLAROZ%' OR e.proyecto ILIKE '%SALES DE JUJUY%' THEN 'Olaroz'
            WHEN e.proyecto ILIKE '%SAL DE VIDA%'      THEN 'Sal de Vida'
            WHEN e.proyecto ILIKE '%RINCON%'           THEN 'Rincón'
            WHEN e.proyecto ILIKE '%MANANTIAL ESPEJO%' THEN 'Manantial Espejo'
            WHEN e.proyecto ILIKE '%CASPOSO%'          THEN 'Casposo'
            WHEN e.proyecto ILIKE '%DON NICOLAS%'      THEN 'Don Nicolás'
            WHEN e.proyecto ILIKE '%PACH_N%'           THEN 'Pachón'
            WHEN e.proyecto ILIKE '%AGUA RICA%'        THEN 'Agua Rica'
            WHEN e.proyecto ILIKE '%JOSEMARIA%'        THEN 'Josemaría'
            WHEN e.proyecto ILIKE '%VICU_A%'           THEN 'Vicuña'
            WHEN e.proyecto ILIKE '%GUALCAMAYO%'       THEN 'Gualcamayo'
            WHEN e.proyecto ILIKE '%AGUILAR%'          THEN 'Aguilar'
            ELSE initcap(split_part(e.proyecto, ': ', 2)) END AS mina,
       split_part(e.proyecto, ': ', 2)      AS proyecto_estma,
       split_part(e.entidad_legal, ': ', 2) AS empresa,
       CASE WHEN e.entidad_legal ~* '(EQUINOR|TOTALENERGIES|CROWN POINT)' THEN 'Hidrocarburos' ELSE 'Minería' END AS sector,
       CASE split_part(e.tipo_pago, ':', 1)
            WHEN 'TAXES' THEN 'Impuestos'           WHEN 'ROYALT' THEN 'Regalías'
            WHEN 'FEES' THEN 'Tasas y cánones'      WHEN 'BONUSES' THEN 'Bonos'
            WHEN 'INFR_IMP_PAY' THEN 'Pagos por infraestructura'
            WHEN 'PROD_ENTITL' THEN 'Derechos de producción'
            WHEN 'DIVID' THEN 'Dividendos' ELSE e.tipo_pago END AS tipo_pago,
       e.valor::numeric AS cad
FROM raw.estma e
WHERE e.pais LIKE 'AR:%'
  AND e.tipo_fila LIKE 'PROJECT%'
  AND e.sub_proyecto LIKE '\_Z%'
  AND e.valor::numeric <> 0;

-- El mismo pago a veces aparece en dos informes (por ejemplo Pachón, que en
-- 2025 informan Glencore y su filial Elk Valley con los mismos montos). Se
-- deja una sola fila por año, mina, tipo de pago y monto; las repetidas
-- quedan en pago_gobierno_repetido para poder controlarlas.
DROP TABLE IF EXISTS mineria.pago_gobierno_repetido;
CREATE TABLE mineria.pago_gobierno_repetido AS
SELECT anio, mina, tipo_pago, cad, count(*) - 1 AS veces_repetido
FROM pagos_crudos GROUP BY anio, mina, tipo_pago, cad HAVING count(*) > 1;

DROP TABLE IF EXISTS mineria.pago_gobierno;
CREATE TABLE mineria.pago_gobierno (
    anio            integer NOT NULL,
    mina            text NOT NULL,
    proyecto_estma  text NOT NULL,
    empresa         text NOT NULL,
    sector          text NOT NULL,
    tipo_pago       text NOT NULL,
    cad             numeric NOT NULL,
    usd             numeric NOT NULL
);
INSERT INTO mineria.pago_gobierno
SELECT DISTINCT ON (p.anio, p.mina, p.tipo_pago, p.cad)
       p.anio, p.mina, p.proyecto_estma, p.empresa, p.sector, p.tipo_pago, p.cad, p.cad / t.cad_por_usd
FROM pagos_crudos p
JOIN mineria.tipo_cambio_cad t ON t.anio = p.anio
ORDER BY p.anio, p.mina, p.tipo_pago, p.cad, p.empresa;

-- Lo que Barrick informa haber pagado por Veladero (100% de la mina).
DROP TABLE IF EXISTS mineria.contribucion_tributaria;
CREATE TABLE mineria.contribucion_tributaria (
    mina          text NOT NULL,
    anio          integer NOT NULL,
    millones_usd  numeric NOT NULL,
    concepto      text NOT NULL,
    fuente        text NOT NULL,
    pagina        integer,
    nota          text,
    PRIMARY KEY (mina, anio)
);
INSERT INTO mineria.contribucion_tributaria
SELECT mina, anio::int, millones_usd::numeric, concepto, fuente, pagina::int, nota FROM raw.contribucion_tributaria;

-- Resultados de una operación por período, de los informes de la empresa.
-- Olaroz (ejercicios de Allkem de julio a junio) y Cauchari-Olaroz (años
-- calendario, estados de Minera Exar), las dos de litio en Jujuy.
DROP TABLE IF EXISTS raw.resultados_operacion;
CREATE TABLE raw.resultados_operacion (
    mina text, periodo_inicio text, periodo_fin text, ingresos_musd text, ebitda_musd text,
    toneladas_vendidas text, precio_usd_t text, resultado_bruto_musd text, costos_financieros_musd text,
    resultado_neto_musd text, toneladas_producidas text, fuente text, pagina text, nota text
);
\copy raw.resultados_operacion FROM 'data/resultados_por_operacion.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.resultado_operacion;
CREATE TABLE mineria.resultado_operacion (
    mina                text NOT NULL,
    periodo_inicio      date NOT NULL,
    periodo_fin         date NOT NULL,
    ingresos_musd       numeric NOT NULL,
    ebitda_musd         numeric,
    toneladas_vendidas  numeric,
    precio_usd_t        numeric,
    resultado_bruto_musd     numeric,
    costos_financieros_musd  numeric,
    resultado_neto_musd      numeric,
    toneladas_producidas     numeric,
    fuente              text NOT NULL,
    pagina              integer,
    nota                text,
    PRIMARY KEY (mina, periodo_inicio)
);
INSERT INTO mineria.resultado_operacion
SELECT mina, periodo_inicio::date, periodo_fin::date, ingresos_musd::numeric, NULLIF(ebitda_musd, '')::numeric,
       NULLIF(toneladas_vendidas, '')::numeric, NULLIF(precio_usd_t, '')::numeric,
       NULLIF(resultado_bruto_musd, '')::numeric, NULLIF(costos_financieros_musd, '')::numeric,
       NULLIF(resultado_neto_musd, '')::numeric, NULLIF(toneladas_producidas, '')::numeric,
       fuente, NULLIF(pagina, '')::int, nota
FROM raw.resultados_operacion;


-- Empleo y salarios registrados del sector privado (OEDE, Ministerio de
-- Trabajo, en base a SIPA). Tres tablas: por departamento y sector, y por
-- provincia y rama a cuatro dígitos (salarios mensuales y empleo trimestral).
--   psql -d mineria -f sql/07_oede.sql

DROP TABLE IF EXISTS raw.oede_departamento_sector;
CREATE TABLE raw.oede_departamento_sector (
    id_reg text, region text, id_prov text, provincia text, id_depto text, departamento text,
    id_sec text, sector text, periodo text, empleo text, salario text
);
\copy raw.oede_departamento_sector FROM 'data/raw/oede/departamento_series_empleo_y_salarios_mensual_sector_1.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'LATIN1')

DROP TABLE IF EXISTS raw.oede_remuneraciones_rama;
CREATE TABLE raw.oede_remuneraciones_rama (provincia text, rama text, descripcion text, periodo text, remuneracion text);
\copy raw.oede_remuneraciones_rama FROM 'data/raw/oede/convertidos/remuneraciones_provincia_rama_mensual.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS raw.oede_empleo_rama;
CREATE TABLE raw.oede_empleo_rama (provincia text, rama text, descripcion text, periodo text, empleo text);
\copy raw.oede_empleo_rama FROM 'data/raw/oede/convertidos/empleo_provincia_rama_trimestral.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Empleo y salario promedio por departamento y gran sector, mensual desde
-- 2019. Cuando en un departamento hay muy pocas empresas del sector, la
-- fuente pone "s.d." y acá queda en NULL.
-- El salario es el bruto promedio del mes, en pesos corrientes. Junio y
-- diciembre incluyen el aguinaldo.
DROP TABLE IF EXISTS mineria.empleo_departamento;
CREATE TABLE mineria.empleo_departamento (
    fecha         date NOT NULL,
    provincia     text NOT NULL,
    departamento  text NOT NULL,
    depto_codigo  text NOT NULL,
    sector        text NOT NULL,
    empleo        integer,
    salario       numeric,
    PRIMARY KEY (fecha, depto_codigo, sector)
);
INSERT INTO mineria.empleo_departamento
SELECT to_date(periodo, 'YYYYMM'), provincia, departamento, id_depto, sector,
       CASE WHEN empleo <> 's.d.' THEN empleo::integer END,
       CASE WHEN salario <> 's.d.' THEN replace(salario, ',', '.')::numeric END
FROM raw.oede_departamento_sector;

-- Ramas de actividad a cuatro dígitos (CIIU revisión 3). es_mineria marca las
-- que empiezan con 10 a 14: carbón, petróleo y gas, uranio, minerales
-- metalíferos y otras minas y canteras.
DROP TABLE IF EXISTS mineria.rama CASCADE;
CREATE TABLE mineria.rama (
    rama         text PRIMARY KEY,
    descripcion  text NOT NULL,
    es_mineria   boolean NOT NULL
);
INSERT INTO mineria.rama
SELECT rama, min(descripcion), rama ~ '^1[0-4][0-9][0-9]$'
FROM (SELECT rama, descripcion FROM raw.oede_remuneraciones_rama
      UNION ALL SELECT rama, descripcion FROM raw.oede_empleo_rama) r
GROUP BY rama;

-- Salario bruto promedio por provincia y rama, mensual desde 1995, en pesos
-- corrientes. Están todas las ramas, no solo las mineras, para poder comparar.
DROP TABLE IF EXISTS mineria.salario_rama;
CREATE TABLE mineria.salario_rama (
    fecha      date NOT NULL,
    provincia  text NOT NULL,
    rama       text NOT NULL REFERENCES mineria.rama,
    salario    numeric NOT NULL,
    PRIMARY KEY (fecha, provincia, rama)
);
INSERT INTO mineria.salario_rama
SELECT periodo::date, provincia, rama, remuneracion::numeric
FROM raw.oede_remuneraciones_rama;

-- Puestos de trabajo por provincia y rama, trimestral desde 1996. La fecha es
-- el primer día del trimestre.
DROP TABLE IF EXISTS mineria.empleo_rama;
CREATE TABLE mineria.empleo_rama (
    fecha      date NOT NULL,
    provincia  text NOT NULL,
    rama       text NOT NULL REFERENCES mineria.rama,
    empleo     numeric NOT NULL,
    PRIMARY KEY (fecha, provincia, rama)
);
INSERT INTO mineria.empleo_rama
SELECT make_date(right(periodo, 4)::int, (left(periodo, 1)::int - 1) * 3 + 1, 1), provincia, rama, empleo::numeric
FROM raw.oede_empleo_rama;

-- Dos tablas armadas a mano que no son datos de minería en sentido estricto:
--   psql -d mineria -f sql/14_correcciones_y_hechos.sql
--
-- correccion_ia: cada vez que algo que se dijo durante el proyecto (casi
-- siempre propuesto por la IA) resultó estar mal, cómo se detectó y qué quedó.
-- Sale de BITACORA.md; la columna seccion_bitacora dice dónde está contado.
DROP TABLE IF EXISTS raw.correcciones_ia;
CREATE TABLE raw.correcciones_ia (numero text, fecha text, seccion_bitacora text, tipo text,
    lo_que_se_dijo text, lo_correcto text, como_se_detecto text, que_quedo text);
\copy raw.correcciones_ia FROM 'data/correcciones_ia.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.correccion_ia;
CREATE TABLE mineria.correccion_ia (
    numero            integer PRIMARY KEY,
    fecha             date NOT NULL,
    seccion_bitacora  integer NOT NULL,
    tipo              text NOT NULL,
    lo_que_se_dijo    text NOT NULL,
    lo_correcto       text NOT NULL,
    como_se_detecto   text NOT NULL,
    que_quedo         text NOT NULL
);
INSERT INTO mineria.correccion_ia
SELECT numero::int, fecha::date, seccion_bitacora::int, tipo, lo_que_se_dijo, lo_correcto, como_se_detecto, que_quedo
FROM raw.correcciones_ia;

-- hecho_mina: fechas que explican lo que pasa en la producción (inicios,
-- cierres, cambios de dueño, accidentes, promesas, entradas al RIGI), cada una
-- con su fuente. Las promesas guardan lo anunciado para compararlo con lo
-- producido.
DROP TABLE IF EXISTS raw.hechos_minas;
CREATE TABLE raw.hechos_minas (mina text, fecha text, precision text, tipo text, descripcion text,
    inversion_musd text, onzas_anunciadas_miles text, desde_anio text, fuente text);
\copy raw.hechos_minas FROM 'data/hechos_minas.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.hecho_mina;
CREATE TABLE mineria.hecho_mina (
    mina                     text NOT NULL,
    fecha                    date NOT NULL,
    precision                text NOT NULL CHECK (precision IN ('día', 'mes', 'año')),
    tipo                     text NOT NULL,
    descripcion              text NOT NULL,
    inversion_musd           numeric,
    onzas_anunciadas_miles   numeric,
    desde_anio               integer,
    fuente                   text NOT NULL,
    PRIMARY KEY (mina, fecha, tipo)
);
INSERT INTO mineria.hecho_mina
SELECT mina, fecha::date, precision, tipo, descripcion, nullif(inversion_musd, '')::numeric,
       nullif(onzas_anunciadas_miles, '')::numeric, nullif(desde_anio, '')::int, fuente
FROM raw.hechos_minas;

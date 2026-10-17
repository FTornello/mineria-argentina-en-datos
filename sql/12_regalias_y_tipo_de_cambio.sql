-- Regalías cobradas por San Juan, tipo de cambio oficial y una serie de
-- comparación para el litio (importaciones de Estados Unidos desde Chile).
--   psql -d mineria -f sql/12_regalias_y_tipo_de_cambio.sql

-- Regalías: copiadas a mano de las planillas de ejecución presupuestaria que
-- publica el Ministerio de Hacienda de San Juan al cierre de cada año
-- (Planilla 1.1, renglón "Regalías", columna devengado).
DROP TABLE IF EXISTS raw.sanjuan_regalias;
CREATE TABLE raw.sanjuan_regalias (anio text, regalias_adm_central_pesos text, regalias_total_pesos text, archivo text);
\copy raw.sanjuan_regalias FROM 'data/sanjuan_regalias.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- regalias_total_pesos suma la administración central y los organismos
-- descentralizados. El renglón no separa regalías mineras de hidroeléctricas.
DROP TABLE IF EXISTS mineria.regalias_san_juan;
CREATE TABLE mineria.regalias_san_juan (
    anio                        integer PRIMARY KEY,
    regalias_adm_central_pesos  numeric NOT NULL,
    regalias_total_pesos        numeric NOT NULL,
    archivo                     text NOT NULL
);
INSERT INTO mineria.regalias_san_juan
SELECT anio::int, regalias_adm_central_pesos::numeric, regalias_total_pesos::numeric, archivo
FROM raw.sanjuan_regalias;

-- Tipo de cambio oficial del Banco Nación (vendedor), promedio de cada mes.
DROP TABLE IF EXISTS raw.tipo_cambio_bna;
CREATE TABLE raw.tipo_cambio_bna (indice_tiempo text, tipo_cambio_bna_vendedor text);
\copy raw.tipo_cambio_bna FROM 'data/raw/bna/tipo_de_cambio_bna.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.tipo_cambio;
CREATE TABLE mineria.tipo_cambio (
    fecha          date PRIMARY KEY,
    pesos_por_usd  numeric NOT NULL
);
INSERT INTO mineria.tipo_cambio
SELECT indice_tiempo::date, tipo_cambio_bna_vendedor::numeric FROM raw.tipo_cambio_bna;

-- Carbonato de litio que Estados Unidos declara importar desde Chile, por año
-- (UN Comtrade). Solo para comparar con lo que importa desde Argentina.
DROP TABLE IF EXISTS raw.comtrade_eeuu_chile;
CREATE TABLE raw.comtrade_eeuu_chile (LIKE raw.comtrade_importaciones);
\copy raw.comtrade_eeuu_chile FROM 'data/raw/comtrade/importaciones_eeuu_desde_chile.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.litio_eeuu_desde_chile;
CREATE TABLE mineria.litio_eeuu_desde_chile (
    anio          integer PRIMARY KEY,
    peso_neto_kg  numeric NOT NULL,
    valor_usd     numeric NOT NULL
);
INSERT INTO mineria.litio_eeuu_desde_chile
SELECT ref_year::int, net_wgt::numeric, primary_value::numeric FROM raw.comtrade_eeuu_chile;

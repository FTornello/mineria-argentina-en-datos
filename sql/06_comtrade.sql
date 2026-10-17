-- Datos espejo de UN Comtrade: lo que otros países declaran importar desde
-- Argentina. Los baja scripts/descargar_comtrade.py.
--   psql -d mineria -f sql/06_comtrade.sql

DROP TABLE IF EXISTS raw.comtrade_importaciones;
CREATE TABLE raw.comtrade_importaciones (
    freq_code      text,
    period         text,
    ref_year       text,
    ref_month      text,
    reporter_code  text,
    partner_code   text,
    flow_code      text,
    cmd_code       text,
    qty_unit_code  text,
    qty            text,
    net_wgt        text,
    cifvalue       text,
    fobvalue       text,
    primary_value  text,
    archivo        text
);
\copy raw.comtrade_importaciones FROM 'data/raw/comtrade/importaciones_desde_argentina.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS raw.comtrade_paises;
CREATE TABLE raw.comtrade_paises (reporter_code text, pais text, iso3 text);
\copy raw.comtrade_paises FROM 'data/raw/comtrade/paises_comtrade.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Los diez productos que se bajan, a 6 dígitos, con el grupo de SIACAM al que
-- corresponden. El grupo se asignó a mano mirando mineria.producto.
DROP TABLE IF EXISTS mineria.producto_hs6 CASCADE;
CREATE TABLE mineria.producto_hs6 (
    hs6          text PRIMARY KEY,
    descripcion  text NOT NULL,
    grupo        text NOT NULL
);
INSERT INTO mineria.producto_hs6 VALUES
    ('710812', 'Oro en bruto, uso no monetario', 'Oro'),
    ('710691', 'Plata en bruto', 'Plata'),
    ('261610', 'Minerales de plata y sus concentrados', 'Plata'),
    ('260300', 'Minerales de cobre y sus concentrados', 'Cobre'),
    ('283691', 'Carbonatos de litio', 'Litio'),
    ('282520', 'Óxido e hidróxido de litio', 'Litio'),
    ('282739', 'Los demás cloruros (incluye cloruro de litio)', 'Litio'),
    ('260700', 'Minerales de plomo y sus concentrados', 'Plomo'),
    ('260800', 'Minerales de cinc y sus concentrados', 'Cinc'),
    ('261390', 'Minerales de molibdeno sin tostar', 'Molibdeno');

-- Una fila por país que informa, producto y período.
--   frecuencia: 'A' es un año entero (fecha = 1 de enero); 'M' es un mes.
--   Las filas anuales y las mensuales cuentan lo mismo dos veces: nunca
--   sumarlas juntas, siempre filtrar por frecuencia.
--   valor_usd: el valor que declara el importador, casi siempre CIF.
DROP TABLE IF EXISTS mineria.importacion_espejo;
CREATE TABLE mineria.importacion_espejo (
    frecuencia    char(1) NOT NULL,
    fecha         date NOT NULL,
    pais_codigo   text NOT NULL,
    pais          text NOT NULL,
    hs6           text NOT NULL REFERENCES mineria.producto_hs6,
    peso_neto_kg  numeric,
    valor_usd     numeric,
    PRIMARY KEY (frecuencia, fecha, pais_codigo, hs6)
);
INSERT INTO mineria.importacion_espejo
SELECT i.freq_code,
       CASE WHEN i.freq_code = 'A' THEN make_date(i.ref_year::int, 1, 1)
            ELSE to_date(i.period, 'YYYYMM') END,
       i.reporter_code,
       coalesce(p.pais, 'Código ' || i.reporter_code),
       i.cmd_code,
       NULLIF(i.net_wgt, '')::numeric,
       NULLIF(i.primary_value, '')::numeric
FROM raw.comtrade_importaciones i
LEFT JOIN raw.comtrade_paises p ON p.reporter_code = i.reporter_code;

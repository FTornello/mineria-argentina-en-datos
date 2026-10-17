-- Producción mina por mina y año, copiada a mano de los informes anuales de
-- las empresas (data/produccion_por_mina.csv). Cada fila dice de qué informe
-- y de qué página o dirección salió. Hay siete minas de oro: Veladero y
-- Gualcamayo (San Juan), Cerro Negro, Cerro Vanguardia, Cerro Moro y San José
-- (Santa Cruz), Lindero (Salta) y dos años de Bajo la Alumbrera (Catamarca).
--   psql -d mineria -f sql/11_produccion_mina.sql

DROP TABLE IF EXISTS raw.produccion_mina;
CREATE TABLE raw.produccion_mina (
    mina text, provincia text, empresa text, anio text, mineral text, unidad text,
    publicado text, participacion_pct text, fuente text, pagina text, nota text
);
\copy raw.produccion_mina FROM 'data/produccion_por_mina.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Las empresas publican la parte que les toca. Barrick tiene el 50% de
-- Veladero desde mediados de 2017, así que desde 2018 informa la mitad.
--   publicado:         el número tal cual está en el informe.
--   participacion_pct: qué parte de la mina representa ese número.
--   produccion_total:  lo que produjo la mina entera (publicado dividido por
--                      la participación). Vacío cuando no se puede calcular.
DROP TABLE IF EXISTS mineria.produccion_mina;
CREATE TABLE mineria.produccion_mina (
    mina               text NOT NULL,
    anio               integer NOT NULL,
    mineral            text NOT NULL,
    provincia          text NOT NULL,
    empresa            text NOT NULL,
    unidad             text NOT NULL,
    publicado          numeric NOT NULL,
    participacion_pct  numeric,
    produccion_total   numeric,
    fuente             text NOT NULL,
    pagina             integer,
    nota               text,
    PRIMARY KEY (mina, anio, mineral)
);
INSERT INTO mineria.produccion_mina
SELECT mina, anio::int, mineral, provincia, empresa, unidad, publicado::numeric,
       NULLIF(participacion_pct, '')::numeric,
       round(publicado::numeric * 100 / NULLIF(participacion_pct, '')::numeric, 1),
       fuente, NULLIF(pagina, '')::int, NULLIF(nota, '')
FROM raw.produccion_mina;

-- Datos de operación de cada mina, copiados de los mismos informes: ley del
-- mineral, toneladas procesadas, recuperación y costos por onza. Formato
-- largo: una fila por mina, año e indicador.
--   ley:                   gramos de oro por tonelada procesada.
--   toneladas_procesadas:  miles de toneladas que entraron a la planta (o a
--                          la pila de lixiviación).
--   recuperacion:          porcentaje del oro que se logra extraer.
--   costo_de_ventas, cash_cost, aisc: dólares por onza. AISC es el costo total
--                          para sostener la operación (incluye inversión de
--                          mantenimiento). Cada empresa los calcula a su manera.
DROP TABLE IF EXISTS raw.operacion_mina;
CREATE TABLE raw.operacion_mina (mina text, anio text, indicador text, valor text, unidad text, fuente text, pagina text, nota text);
\copy raw.operacion_mina FROM 'data/operacion_por_mina.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.operacion_mina;
CREATE TABLE mineria.operacion_mina (
    mina       text NOT NULL,
    anio       integer NOT NULL,
    indicador  text NOT NULL,
    valor      numeric NOT NULL,
    unidad     text NOT NULL,
    fuente     text NOT NULL,
    pagina     integer,
    nota       text,
    PRIMARY KEY (mina, anio, indicador)
);
INSERT INTO mineria.operacion_mina
SELECT mina, anio::int, indicador, valor::numeric, unidad, fuente, NULLIF(pagina, '')::int, NULLIF(nota, '')
FROM raw.operacion_mina;


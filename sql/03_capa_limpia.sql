-- Capa limpia (esquema mineria): los datos con tipos, nombres claros y claves.
-- Se reconstruye entera a partir de la capa raw.
--   psql -d mineria -f sql/03_capa_limpia.sql

DROP SCHEMA IF EXISTS mineria CASCADE;
CREATE SCHEMA mineria;

-- Convierte un número escrito al estilo del INDEC ("8205,390", ",00") en
-- numeric. Devuelve NULL si el dato está tapado por secreto estadístico ("s").
CREATE FUNCTION mineria.numero_indec(texto text) RETURNS numeric
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN texto ~ '^s' THEN NULL
        WHEN texto ~ '^,' THEN ('0' || replace(texto, ',', '.'))::numeric
        ELSE replace(texto, ',', '.')::numeric
    END
$$;

-- Productos mineros: la lista de la Secretaría de Minería.
CREATE TABLE mineria.producto (
    ncm          text PRIMARY KEY,
    descripcion  text NOT NULL,
    rubro        text NOT NULL,
    grupo        text NOT NULL
);
INSERT INTO mineria.producto
SELECT ncm, descripcion, rubro, grupo FROM raw.ncm_minero;

-- Países. El INDEC publica solo el código; el nombre sale del archivo de
-- importaciones de SIACAM, que usa los mismos códigos de la Aduana. Los pocos
-- códigos que no aparecen ahí quedan con el nombre "Código NNN".
-- El 999 no es un país: es la fila donde el INDEC junta los destinos tapados.
CREATE TABLE mineria.pais (
    pais_codigo  text PRIMARY KEY,
    pais         text NOT NULL
);
INSERT INTO mineria.pais
SELECT DISTINCT ppro, procedenc FROM raw.siacam_impo_minerales;
INSERT INTO mineria.pais VALUES ('999', 'Confidencial')
ON CONFLICT (pais_codigo) DO UPDATE SET pais = 'Confidencial';
INSERT INTO mineria.pais
SELECT DISTINCT e.pais, 'Código ' || e.pais
FROM raw.indec_exportaciones e
JOIN raw.ncm_minero n USING (ncm)
ON CONFLICT DO NOTHING;

-- Exportaciones mineras del INDEC: una fila por producto, país de destino y mes.
-- Es la tabla central. De todas las exportaciones del país se dejan solo las
-- de productos mineros.
--   confidencial:   el INDEC tapó los kilos y los dólares de esa fila.
--   rango_secreto:  desde 2020, tramo de dólares de la fila tapada (1 a 10).
CREATE TABLE mineria.exportacion (
    fecha          date NOT NULL,
    ncm            text NOT NULL REFERENCES mineria.producto,
    pais_codigo    text NOT NULL REFERENCES mineria.pais,
    peso_neto_kg   numeric,
    fob_usd        numeric,
    confidencial   boolean NOT NULL,
    rango_secreto  smallint,
    PRIMARY KEY (fecha, ncm, pais_codigo)
);
INSERT INTO mineria.exportacion
SELECT make_date(e.anio::int, e.mes::int, 1),
       e.ncm,
       e.pais,
       mineria.numero_indec(e.peso_neto_kg),
       mineria.numero_indec(e.fob_usd),
       e.fob_usd ~ '^s',
       CASE WHEN e.fob_usd ~ '^s[0-9]+$' THEN substr(e.fob_usd, 2)::smallint END
FROM raw.indec_exportaciones e
JOIN raw.ncm_minero n USING (ncm);

-- Tramos de dólares que corresponden a cada rango_secreto (instructivo del INDEC).
CREATE TABLE mineria.rango_secreto (
    rango_secreto  smallint PRIMARY KEY,
    desde_usd      numeric NOT NULL,
    hasta_usd      numeric
);
INSERT INTO mineria.rango_secreto VALUES
    (1, 0, 5000), (2, 5000, 25000), (3, 25000, 150000), (4, 150000, 500000),
    (5, 500000, 2000000), (6, 2000000, 5000000), (7, 5000000, 15000000),
    (8, 15000000, 100000000), (9, 100000000, 500000000), (10, 500000000, NULL);

-- Exportaciones de minerales según SIACAM: por grupo y mes, total país.
CREATE TABLE mineria.exportacion_siacam (
    fecha    date NOT NULL,
    grupo    text NOT NULL,
    rubro    text NOT NULL,
    fob_usd  numeric NOT NULL,
    PRIMARY KEY (fecha, grupo, rubro)
);
INSERT INTO mineria.exportacion_siacam
SELECT make_date(anyo::int, mes::int, 1), grupo, sector, fob::numeric
FROM raw.siacam_expo_minerales;

-- Empleo minero registrado por mes, provincia, género y rubro.
-- puestos es numeric y no entero: en cuatro meses (jun-2009, oct-2009,
-- dic-2012 y ene-2013) la fuente trae valores con medio puesto (11,5).
CREATE TABLE mineria.empleo (
    fecha      date NOT NULL,
    provincia  text NOT NULL,
    genero     text NOT NULL,
    rubro      text NOT NULL,
    puestos    numeric NOT NULL,
    PRIMARY KEY (fecha, provincia, genero, rubro)
);
INSERT INTO mineria.empleo
SELECT anio_mes::date, provincia_zona, genero, rubro, cantidad::numeric
FROM raw.siacam_empleo;

-- Precios internacionales de minerales por mes.
CREATE TABLE mineria.precio (
    fecha    date NOT NULL,
    mineral  text NOT NULL,
    unidad   text NOT NULL,
    precio   numeric,
    PRIMARY KEY (fecha, mineral, unidad)
);
INSERT INTO mineria.precio
SELECT make_date(anio::int, mes::int, 1), mineral, unidad_medida, precio::numeric
FROM raw.siacam_precios;

-- Cartera de proyectos metalíferos y de litio. Es una foto: el estado es el
-- del día de la descarga, no tiene historia. Donde no hay segundo o tercer
-- controlante el archivo trae un guion, que acá queda en NULL.
CREATE TABLE mineria.proyecto (
    proyecto_id    integer PRIMARY KEY,
    nombre         text NOT NULL,
    latitud        numeric,
    longitud       numeric,
    mineral        text NOT NULL,
    provincia      text NOT NULL,
    estado         text NOT NULL,
    controlante_1  text,
    origen_1       text,
    porcentaje_1   numeric,
    controlante_2  text,
    origen_2       text,
    porcentaje_2   numeric,
    controlante_3  text,
    origen_3       text,
    porcentaje_3   numeric
);
INSERT INTO mineria.proyecto
SELECT nro::numeric::integer, trim(nombre), latitud::numeric, longitud::numeric,
       trim(mineral), trim(provincia), trim(estado),
       trim(controlante_1), trim(origen_1), porcentaje_1::numeric,
       NULLIF(trim(controlante_2), '-'), NULLIF(trim(origen_2), '-'), NULLIF(trim(porcentaje_2), '-')::numeric,
       NULLIF(trim(controlante_3), '-'), NULLIF(trim(origen_3), '-'), NULLIF(trim(porcentaje_3), '-')::numeric
FROM raw.siacam_cartera;

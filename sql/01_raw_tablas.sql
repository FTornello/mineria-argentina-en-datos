-- Capa raw: los archivos tal cual se publican.
-- Todas las columnas son text; los tipos se asignan en la capa limpia.

CREATE SCHEMA IF NOT EXISTS raw;

-- INDEC: exportaciones por producto (NCM a 8 dígitos), país de destino y mes.
-- Todos los productos del país, no solo los mineros. 2002 en adelante.
DROP TABLE IF EXISTS raw.indec_exportaciones;
CREATE TABLE raw.indec_exportaciones (
    anio          text,
    mes           text,
    ncm           text,
    pais          text,
    peso_neto_kg  text,
    fob_usd       text,
    archivo       text
);

-- INDEC: total de filas, kilos y dólares que el propio INDEC declara por año.
DROP TABLE IF EXISTS raw.indec_totales_control;
CREATE TABLE raw.indec_totales_control (
    anio          text,
    registros     text,
    peso_neto_kg  text,
    fob_usd       text,
    archivo       text
);

-- SIACAM: lista de productos (NCM) que la Secretaría de Minería cuenta como
-- minería, con su rubro y grupo. Sale del PDF de metodología.
DROP TABLE IF EXISTS raw.ncm_minero;
CREATE TABLE raw.ncm_minero (
    ncm          text,
    descripcion  text,
    rubro        text,
    grupo        text
);

-- SIACAM: exportaciones de minerales por grupo y mes, desde 1994.
DROP TABLE IF EXISTS raw.siacam_expo_minerales;
CREATE TABLE raw.siacam_expo_minerales (
    anyo    text,
    mes     text,
    grupo   text,
    sector  text,
    fob     text
);

-- SIACAM: importaciones de minerales por país de origen y de procedencia.
DROP TABLE IF EXISTS raw.siacam_impo_minerales;
CREATE TABLE raw.siacam_impo_minerales (
    anyo       text,
    origen     text,
    ppro       text,
    procedenc  text,
    mes        text,
    grupo      text,
    sector     text,
    cif        text
);

-- SIACAM: puestos de trabajo por mes, provincia, género y rubro, desde 2007.
DROP TABLE IF EXISTS raw.siacam_empleo;
CREATE TABLE raw.siacam_empleo (
    anio_mes        text,
    provincia_zona  text,
    genero          text,
    rubro           text,
    cantidad        text
);

-- SIACAM: precios internacionales de minerales por mes, desde 1990.
DROP TABLE IF EXISTS raw.siacam_precios;
CREATE TABLE raw.siacam_precios (
    anio           text,
    mes            text,
    fecha          text,
    precio         text,
    mineral        text,
    unidad_medida  text,
    numero_indice  text
);

-- SIACAM: cartera de proyectos metalíferos y de litio.
DROP TABLE IF EXISTS raw.siacam_cartera;
CREATE TABLE raw.siacam_cartera (
    nro            text,
    nombre         text,
    latitud        text,
    longitud       text,
    mineral        text,
    provincia      text,
    estado         text,
    controlante_1  text,
    porcentaje_1   text,
    origen_1       text,
    controlante_2  text,
    origen_2       text,
    porcentaje_2   text,
    controlante_3  text,
    porcentaje_3   text,
    origen_3       text
);

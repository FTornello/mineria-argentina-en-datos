-- El resto de los archivos de SIACAM: inversión, impuestos, producción,
-- empresas, exportaciones por provincia, destinos del litio y balance cambiario.
-- Cada bloque crea la tabla raw (todo text), la carga y arma la tabla limpia.
--   psql -d mineria -f sql/05_siacam_complementarios.sql

-- Las fechas de varios archivos vienen como día/mes/año ("1/2/2017" es
-- febrero); se leen con to_date(..., 'DD/MM/YYYY').

---------------------------------------------------------------------------
-- Anuncios de inversión: uno por fila, con empresa, proyecto y monto.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_anuncios;
CREATE TABLE raw.siacam_anuncios (
    empresa    text,
    anio       text,
    fecha      text,
    dolares    text,
    mineral    text,
    provincia  text,
    concepto   text,
    proyecto   text,
    acumulado  text
);
\copy raw.siacam_anuncios FROM 'data/raw/siacam/Anuncios-de-inversion.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- El archivo no trae identificador; se numera en el orden en que viene.
-- La fecha viene como mes/año ("11/20").
DROP TABLE IF EXISTS mineria.anuncio_inversion;
CREATE TABLE mineria.anuncio_inversion (
    anuncio_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha       date NOT NULL,
    empresa     text NOT NULL,
    proyecto    text,
    mineral     text NOT NULL,
    provincia   text NOT NULL,
    concepto    text,
    usd         numeric NOT NULL
);
INSERT INTO mineria.anuncio_inversion (fecha, empresa, proyecto, mineral, provincia, concepto, usd)
SELECT to_date('01/' || trim(fecha), 'DD/MM/YY'), trim(empresa), trim(proyecto), trim(mineral),
       trim(provincia), trim(concepto), dolares::numeric
FROM raw.siacam_anuncios;

---------------------------------------------------------------------------
-- Impuestos nacionales pagados por las grandes mineras, por empresa y año.
-- Hay un archivo en pesos y otro en dólares, los dos en millones.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_impuestos_usd;
CREATE TABLE raw.siacam_impuestos_usd (
    anio text, empresa text, ganancias text, derechos_exportacion text, seguridad_social text,
    creditos_debitos text, regalias_canon text, tasa_ambiental text, total_empresa text
);
\copy raw.siacam_impuestos_usd FROM 'data/raw/siacam/Impuestos/Impuestos-ImpuestosDolares.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- El archivo en pesos trae tres columnas vacías al final.
DROP TABLE IF EXISTS raw.siacam_impuestos_pesos;
CREATE TABLE raw.siacam_impuestos_pesos (
    anio text, empresa text, ganancias text, derechos_exportacion text, seguridad_social text,
    creditos_debitos text, regalias_canon text, tasa_ambiental text, total_empresa text,
    vacia_1 text, vacia_2 text, vacia_3 text
);
\copy raw.siacam_impuestos_pesos FROM 'data/raw/siacam/Impuestos/Impuestos-ImpuestosPesos.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Una fila por empresa, año e impuesto. La columna "Total Empresa" del
-- archivo en dólares trae valores imposibles en varios años, así que no se
-- usa: el total se obtiene sumando los impuestos.
DROP TABLE IF EXISTS mineria.impuesto_empresa;
CREATE TABLE mineria.impuesto_empresa (
    anio            integer NOT NULL,
    empresa         text NOT NULL,
    impuesto        text NOT NULL,
    millones_pesos  numeric NOT NULL,
    millones_usd    numeric NOT NULL,
    PRIMARY KEY (anio, empresa, impuesto)
);
INSERT INTO mineria.impuesto_empresa
SELECT p.anio::int, trim(p.empresa), i.impuesto, i.pesos::numeric, i.usd::numeric
FROM raw.siacam_impuestos_pesos p
JOIN raw.siacam_impuestos_usd u ON u.anio = p.anio AND trim(u.empresa) = trim(p.empresa)
CROSS JOIN LATERAL (VALUES
    ('Ganancias',               p.ganancias,            u.ganancias),
    ('Derechos de exportación', p.derechos_exportacion, u.derechos_exportacion),
    ('Seguridad social',        p.seguridad_social,     u.seguridad_social),
    ('Créditos y débitos',      p.creditos_debitos,     u.creditos_debitos),
    ('Regalías y canon',        p.regalias_canon,       u.regalias_canon),
    ('Tasa ambiental',          p.tasa_ambiental,       u.tasa_ambiental)
) AS i (impuesto, pesos, usd);

---------------------------------------------------------------------------
-- Índice de producción minero (IPI minero), mensual por rama, desde 2017.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_ipi_ramas;
CREATE TABLE raw.siacam_ipi_ramas (fecha text, serie text, indice text);
\copy raw.siacam_ipi_ramas FROM 'data/raw/siacam/ipi-minero/ipi-minero-ramas-actividad.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Es un índice, no toneladas: sirve para ver si una rama sube o baja, no
-- cuánto produce. Incluye petróleo y gas, que el índice cuenta como minería.
-- Algunas ramas no tienen dato en todos los meses (las arenas de fractura,
-- por ejemplo, empiezan más tarde); esas filas vacías no se cargan.
DROP TABLE IF EXISTS mineria.indice_produccion;
CREATE TABLE mineria.indice_produccion (
    fecha   date NOT NULL,
    rama    text NOT NULL,
    indice  numeric NOT NULL,
    PRIMARY KEY (fecha, rama)
);
INSERT INTO mineria.indice_produccion
SELECT to_date(fecha, 'DD/MM/YYYY'), trim(serie), indice::numeric
FROM raw.siacam_ipi_ramas
WHERE indice IS NOT NULL;

-- Producción de carbonato de litio en toneladas, mensual desde junio de 2023.
DROP TABLE IF EXISTS raw.siacam_ipi_litio;
CREATE TABLE raw.siacam_ipi_litio (periodo text, carbonato_tn text, indice text);
\copy raw.siacam_ipi_litio FROM 'data/raw/siacam/ipi-minero/ipi-minero-produccion-litio.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.produccion_litio;
CREATE TABLE mineria.produccion_litio (
    fecha                date PRIMARY KEY,
    carbonato_litio_ton  numeric NOT NULL
);
INSERT INTO mineria.produccion_litio
SELECT to_date(periodo, 'DD/MM/YYYY'), carbonato_tn::numeric FROM raw.siacam_ipi_litio;

---------------------------------------------------------------------------
-- Cantidad de empresas mineras por mes y rubro.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_empresas;
CREATE TABLE raw.siacam_empresas (anio_mes text, rubro text, cantidad text);
\copy raw.siacam_empresas FROM 'data/raw/siacam/empresas_cantidad_mineras.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.empresas_por_rubro;
CREATE TABLE mineria.empresas_por_rubro (
    fecha     date NOT NULL,
    rubro     text NOT NULL,
    empresas  numeric NOT NULL,
    PRIMARY KEY (fecha, rubro)
);
INSERT INTO mineria.empresas_por_rubro
SELECT anio_mes::date, rubro, cantidad::numeric FROM raw.siacam_empresas;

---------------------------------------------------------------------------
-- Exportaciones mineras por provincia y año.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_expo_provincia;
CREATE TABLE raw.siacam_expo_provincia (anyo text, provincia text, usd_fob text);
\copy raw.siacam_expo_provincia FROM 'data/raw/siacam/Comercio/expo-mineria-por-provincia.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.exportacion_provincia;
CREATE TABLE mineria.exportacion_provincia (
    anio          integer NOT NULL,
    provincia     text NOT NULL,
    millones_usd  numeric NOT NULL,
    PRIMARY KEY (anio, provincia)
);
INSERT INTO mineria.exportacion_provincia
SELECT anyo::int, provincia, usd_fob::numeric FROM raw.siacam_expo_provincia;

---------------------------------------------------------------------------
-- Exportaciones de litio por país de destino y año, según SIACAM.
-- Cubre los años en que el INDEC tapa los destinos.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_litio_destino;
CREATE TABLE raw.siacam_litio_destino (anio text, destino text, suma_fob text);
\copy raw.siacam_litio_destino FROM 'data/raw/siacam/Tablero-Litio/Exportaciones-por-destino-litio.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.exportacion_litio_destino;
CREATE TABLE mineria.exportacion_litio_destino (
    anio          integer NOT NULL,
    destino       text NOT NULL,
    millones_usd  numeric NOT NULL,
    PRIMARY KEY (anio, destino)
);
INSERT INTO mineria.exportacion_litio_destino
SELECT anio::int, destino, suma_fob::numeric FROM raw.siacam_litio_destino;

-- Exportaciones de litio por año, total. Es el número de referencia para el
-- litio: entre 2018 y 2023 la serie mensual por grupo (exportacion_siacam)
-- manda parte del litio al grupo "Otro" por el secreto estadístico.
DROP TABLE IF EXISTS raw.siacam_litio_anual;
CREATE TABLE raw.siacam_litio_anual (anio text, exportaciones_fob text, variacion text, participacion text);
\copy raw.siacam_litio_anual FROM 'data/raw/siacam/Tablero-Litio/Exportaciones-litio.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.exportacion_litio_anual;
CREATE TABLE mineria.exportacion_litio_anual (
    anio          integer PRIMARY KEY,
    millones_usd  numeric NOT NULL
);
INSERT INTO mineria.exportacion_litio_anual
SELECT anio::int, exportaciones_fob::numeric FROM raw.siacam_litio_anual;

---------------------------------------------------------------------------
-- Valor de la producción minera en las Cuentas Nacionales, por año.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_cuentas_nacionales;
CREATE TABLE raw.siacam_cuentas_nacionales (
    anio text, variable text, rama text, valor text, pct_economia text,
    unidad text, a_precios text, medicion text
);
\copy raw.siacam_cuentas_nacionales FROM 'data/raw/siacam/VBP-VAP-Mineria.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS mineria.cuentas_nacionales;
CREATE TABLE mineria.cuentas_nacionales (
    anio            integer NOT NULL,
    variable        text NOT NULL,
    precios         text NOT NULL,
    millones_pesos  numeric NOT NULL,
    pct_economia    numeric,
    PRIMARY KEY (anio, variable, precios)
);
INSERT INTO mineria.cuentas_nacionales
SELECT anio::int, variable, a_precios, valor::numeric, replace(pct_economia, '%', '')::numeric
FROM raw.siacam_cuentas_nacionales;

---------------------------------------------------------------------------
-- Balance cambiario: dólares que entran y salen por el mercado de cambios,
-- por sector de la economía y mes, en millones. Fuente original: BCRA.
---------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.siacam_balance_cambiario;
CREATE TABLE raw.siacam_balance_cambiario (
    sector text, anio text, mes text, fecha text, cuenta_corriente text, balance_comercial text,
    bienes text, servicios text, ingreso_primario text, intereses text, utilidades_dividendos text,
    ingreso_secundario text, capital text, cuenta_financiera text, ied_neto text, prestamos text,
    fae text, resultado_cambiario text, sumatoria text, sumatoria_no_informado text, no_informados text
);
\copy raw.siacam_balance_cambiario FROM 'data/raw/siacam/convertidos/balance_cambiario.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Se dejan todos los sectores para poder comparar la minería con el resto.
-- De las 17 cuentas se guardan las principales.
DROP TABLE IF EXISTS mineria.balance_cambiario;
CREATE TABLE mineria.balance_cambiario (
    fecha                  date NOT NULL,
    sector                 text NOT NULL,
    bienes                 numeric,
    servicios              numeric,
    intereses              numeric,
    utilidades_dividendos  numeric,
    cuenta_corriente       numeric,
    ied_neto               numeric,
    prestamos              numeric,
    cuenta_financiera      numeric,
    resultado_cambiario    numeric,
    PRIMARY KEY (fecha, sector)
);
INSERT INTO mineria.balance_cambiario
SELECT make_date(anio::int, mes::int, 1), sector, bienes::numeric, servicios::numeric, intereses::numeric,
       utilidades_dividendos::numeric, cuenta_corriente::numeric, ied_neto::numeric, prestamos::numeric,
       cuenta_financiera::numeric, resultado_cambiario::numeric
FROM raw.siacam_balance_cambiario;

-- Carga de los archivos en la capa raw. Correr con psql desde la raíz del proyecto:
--   psql -d mineria -f sql/02_raw_carga.sql

TRUNCATE raw.indec_exportaciones;
\copy raw.indec_exportaciones FROM 'data/raw/indec/exportaciones_ncm_pais_mes.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

TRUNCATE raw.indec_totales_control;
\copy raw.indec_totales_control FROM 'data/raw/indec/totales_control.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

TRUNCATE raw.ncm_minero;
\copy raw.ncm_minero FROM 'data/ncm_minero_siacam.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

TRUNCATE raw.siacam_expo_minerales;
\copy raw.siacam_expo_minerales FROM 'data/raw/siacam/Comercio/expominerales-siacam.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

TRUNCATE raw.siacam_impo_minerales;
\copy raw.siacam_impo_minerales FROM 'data/raw/siacam/Comercio/impominerales-siacam.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

TRUNCATE raw.siacam_empleo;
\copy raw.siacam_empleo FROM 'data/raw/siacam/Empleo-rubro-genero-prov.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

TRUNCATE raw.siacam_precios;
\copy raw.siacam_precios FROM 'data/raw/siacam/convertidos/precios_internacionales.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

TRUNCATE raw.siacam_cartera;
\copy raw.siacam_cartera FROM 'data/raw/siacam/convertidos/cartera_metaliferos_litio.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Producción física anual de oro, plata, litio y cobre según CAEM.
-- Es la única serie larga en onzas y toneladas. CAEM la arma sumando lo que
-- informan las empresas, y la publica en un PDF: los números de
-- data/caem_produccion_anual.csv se copiaron a mano de los gráficos del
-- "Informe productivo de la minería argentina" de mayo de 2026.
--   psql -d mineria -f sql/10_caem.sql

DROP TABLE IF EXISTS raw.caem_produccion;
CREATE TABLE raw.caem_produccion (anio text, mineral text, produccion text, unidad text, pagina text);
\copy raw.caem_produccion FROM 'data/caem_produccion_anual.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Cada mineral tiene su unidad: no se pueden sumar entre sí.
-- Del cobre faltan 2019, 2020 y 2021: el gráfico trae un solo valor (cero)
-- para esos años y no se puede saber a cuál corresponde. Bajo la Alumbrera
-- dejó de producir en 2018 y Martín Bronce empezó en 2022.
DROP TABLE IF EXISTS mineria.produccion_anual;
CREATE TABLE mineria.produccion_anual (
    anio        integer NOT NULL,
    mineral     text NOT NULL,
    produccion  numeric NOT NULL,
    unidad      text NOT NULL,
    PRIMARY KEY (anio, mineral)
);
INSERT INTO mineria.produccion_anual
SELECT anio::int, mineral, produccion::numeric, unidad FROM raw.caem_produccion;

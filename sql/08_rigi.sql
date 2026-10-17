-- RIGI (Régimen de Incentivo para Grandes Inversiones): proyectos aprobados y
-- plan de inversión por año. Los dos CSV se armaron a mano el 13-10-2026 desde
-- el tablero oficial (argentina.gob.ar/economia/rigi); la fecha y el número de
-- resolución salen de la página de normativa de cada proyecto.
--   psql -d mineria -f sql/08_rigi.sql

DROP TABLE IF EXISTS raw.rigi_proyectos;
CREATE TABLE raw.rigi_proyectos (
    proyecto text, empresa text, sector text, mineral text, provincia text, provincias_compartidas text,
    inversion_musd text, empleos text, resolucion text, fecha_resolucion text, fecha_boletin text, enlace_norma text
);
\copy raw.rigi_proyectos FROM 'data/rigi_proyectos.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DROP TABLE IF EXISTS raw.rigi_plan_inversion;
CREATE TABLE raw.rigi_plan_inversion (
    anio text, cobre text, litio text, oro_plata text, mineria text,
    petroleo_gas text, energia_electrica text, siderurgia text, infraestructura text
);
\copy raw.rigi_plan_inversion FROM 'data/rigi_plan_inversion_anual.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Un proyecto por fila. "Aprobado" quiere decir que tiene resolución
-- publicada en el Boletín Oficial.
--   mineral: lo asigné yo leyendo la descripción oficial de cada proyecto
--            minero; vacío en los que no son de minería.
--   empleos: directos e indirectos, según lo declara el proyecto. Es una
--            promesa, no empleo registrado.
DROP TABLE IF EXISTS mineria.rigi_proyecto;
CREATE TABLE mineria.rigi_proyecto (
    proyecto                text PRIMARY KEY,
    empresa                 text NOT NULL,
    sector                  text NOT NULL,
    mineral                 text,
    provincia               text NOT NULL,
    provincias_compartidas  text,
    inversion_musd          numeric NOT NULL,
    empleos                 integer NOT NULL,
    resolucion              text NOT NULL,
    fecha_resolucion        date NOT NULL,
    fecha_boletin           date NOT NULL,
    enlace_norma            text NOT NULL
);
INSERT INTO mineria.rigi_proyecto
SELECT proyecto, empresa, sector, NULLIF(mineral, ''), provincia, NULLIF(provincias_compartidas, ''),
       inversion_musd::numeric, empleos::integer, resolucion, fecha_resolucion::date, fecha_boletin::date, enlace_norma
FROM raw.rigi_proyectos;

-- Inversión prevista por año y rubro, en millones de dólares, sumando los
-- planes de los proyectos. El tablero no aclara si incluye solo los aprobados.
DROP TABLE IF EXISTS mineria.rigi_plan_inversion;
CREATE TABLE mineria.rigi_plan_inversion (
    anio   integer NOT NULL,
    rubro  text NOT NULL,
    musd   numeric NOT NULL,
    PRIMARY KEY (anio, rubro)
);
INSERT INTO mineria.rigi_plan_inversion
SELECT p.anio::int, r.rubro, r.musd::numeric
FROM raw.rigi_plan_inversion p
CROSS JOIN LATERAL (VALUES
    ('Cobre', p.cobre), ('Litio', p.litio), ('Oro y plata', p.oro_plata),
    ('Petróleo y gas', p.petroleo_gas), ('Energía eléctrica', p.energia_electrica),
    ('Siderurgia', p.siderurgia), ('Infraestructura', p.infraestructura)
) AS r (rubro, musd);

# Relevamiento de fuentes

Primera pasada: 2026-10-13. Todavía no se bajó nada a `data/raw/`; cada archivo se abrió en memoria para
ver columnas, cantidad de filas y fechas. La columna "Detalle" dice qué tan fino es el dato, que es lo que
decide si una fuente puede ser la tabla central.

## 1. Secretaría de Minería (SIACAM), en datos.gob.ar

22 datasets. Los archivos están en `https://www.mecon.gob.ar/dataset/`.

| Fuente | Qué trae | Período | Filas | Detalle |
|---|---|---|---|---|
| Cartera de proyectos metalíferos y litio (XLSX) | nombre, coordenadas, mineral, provincia, estado, hasta 3 controlantes con país y porcentaje | foto a junio 2026 | 235 | **por proyecto**, sin historia |
| Cartera de no metalíferos y rocas (XLSX) | nombre, coordenadas, mineral, provincia, estado, operador | foto a junio 2026 | hasta 1.000 (no conté las vacías) | por cantera, sin historia |
| Exportaciones de minerales (CSV) | año, mes, grupo de mineral, sector, dólares FOB | 1994 a ago-2026 | 17.697 | mensual por mineral, total país |
| Importaciones de minerales (CSV) | año, mes, origen, procedencia, grupo, sector, CIF | 1994 a ago-2026 | 101.983 | mensual por mineral y país |
| Exportaciones por provincia (CSV) | año, provincia, dólares | 1994 a 2025 | 620 | anual |
| Empleo por provincia, rubro y género (CSV) | mes, provincia, género, rubro, puestos | ene-2007 a mar-2026 | 46.576 | mensual por provincia y rubro |
| Cantidad de empresas por rubro (CSV) | mes, rubro, empresas | 2007 a mar-2026 | 1.610 | mensual, total país |
| Anuncios de inversión (CSV) | empresa, fecha, dólares, mineral, provincia, concepto, proyecto | 2020 a sep-2025 | 55 | **por anuncio y proyecto** |
| Impuestos de grandes empresas (CSV) | año, empresa, ganancias, retenciones, seguridad social, regalías y canon | 2019 a 2023 | 80 | **por empresa**, anual |
| IPI minero (4 CSV) | índice de producción por rama; toneladas de carbonato de litio | 2017 a jul-2026 (litio desde jun-2023) | 5.405 | mensual por rama, total país |
| Precios internacionales (XLSX) | mes, mineral, precio, unidad | 1990 a ago-2026 | 4.934 | mensual por mineral |
| Balance cambiario (XLSX) | mes, sector, cuentas del balance | 2003 a jul-2026 | 8.490 | mensual por sector de la economía |
| Producción en Cuentas Nacionales (CSV) | valor bruto y valor agregado de la minería | 2004 a 2025 | 88 | anual |
| Tablero del litio (varios CSV) | exportaciones, empleo por provincia, oferta, demanda y reservas mundiales | variable | chico | agregado |
| Tablero del cobre (4 XLSX) | producción de las principales minas del mundo, reservas, demanda | corte único | chico | por mina, a nivel mundial |
| Comercio mundial (CEPII BACI) | exportaciones e importaciones mineras por país | — | sin abrir | por país |
| Minería comparada, compras a proveedores | perfil de trabajadores, compras por rama | 2016-2021, 2019 | chico | agregado |
| Indicadores de sustentabilidad | agua, energía y emisiones por proyecto | — | — | el enlace de agua dio error 404; falta probar los otros |

Aparte, en el nodo de Energía hay `proyectos-mineros-ubicacion-aproximada` (82 proyectos con empresa,
estado y mineral, actualizado sep-2026) y dos series viejas del régimen de inversiones mineras (1993-2015).

## 2. INDEC, comercio exterior

`https://comex.indec.gob.ar/files/zips/exports_AAAA_M.zip`, un archivo por año desde 2002. El de 2026 se
actualizó el 18-09-2026.

Columnas: año, mes, NCM a 8 dígitos, país de destino, kilos netos, dólares FOB. Es lo más detallado que
encontré: cada fila es un producto vendido a un país en un mes.

**El límite:** el secreto estadístico. En el archivo de 2015 los productos mineros figuran completos (por
ejemplo, oro a Suiza en enero: 8.205 kg y 107,6 millones de dólares). En el de 2026 la mayoría figura con
una "s" en lugar del número:

| Producto (NCM) | Filas en 2026 | Tapadas |
|---|---|---|
| Concentrado de cobre (2603) | 7 | 7 |
| Hidróxido de litio (282520) | 31 | 31 |
| Carbonato de litio (283691) | 78 | 62 |
| Oro (7108) | 49 | 31 |
| Plata (7106) | 10 | 10 |
| Concentrados de plata y oro (2616) | 43 | 36 |

Falta ubicar en qué año empieza el secreto (no lo verifiqué; hay que abrir los archivos intermedios) y
leer el `Leame` para entender qué significa el número que acompaña a la "s".

## 3. CEP XXI (ex Ministerio de Producción)

Archivos en `cdn.produccion.gob.ar/cdn-cep/`. **Todos tienen fecha de marzo de 2024 o anterior**: las
series quedaron congeladas. Sirven para historia, no para el presente.

| Fuente | Detalle | Tamaño |
|---|---|---|
| Salario promedio por departamento y actividad (CLAE 2 dígitos) | mensual por departamento | 104 MB |
| Puestos por provincia y actividad (CLAE 2 dígitos) | mensual por provincia | 11 MB |
| Salario mediano por actividad (CLAE 6 dígitos) | mensual, total país, actividad muy fina | 4,6 MB |
| Establecimientos productivos | **por establecimiento**: CUIT anonimizado, coordenadas, actividad a 6 dígitos, departamento, tramo de empleo. Solo 2021 y 2022 | 96 MB |
| Puestos por departamento, puestos por CLAE 6 | el servidor devuelve "acceso denegado" | — |

## 4. Lo que busqué y no encontré

- **Producción por mina.** No hay en datos abiertos nacionales. La Secretaría se comprometió a publicar un
  indicador de producción (plan de Gobierno Abierto 2025-2027). Santa Cruz publicó un PDF con onzas y
  regalías por operadora, solo de 2022. La única vía para tenerla es armarla a mano con los informes
  trimestrales de las empresas (no lo empecé).
- **Regalías de San Juan.** No encontré dataset. El portal `datosabiertos.sanjuan.gob.ar` redirige a la
  página principal del gobierno; el catastro en KMZ que mencionan otras páginas no lo pude ubicar.
- **Historia de la cartera de proyectos.** En Wayback Machine hay una sola copia vieja útil: la lista de
  82 proyectos de Energía, de septiembre de 2022. Las carteras anteriores existen como PDF anuales.
- **Catastro minero nacional.** Sin descarga unificada; cada provincia publica lo suyo (Río Negro sí).

## 5. Pendiente de relevar

- Año en que empieza el secreto estadístico del INDEC, por producto.
- Datos espejo: lo que los países compradores declaran importar desde Argentina (UN Comtrade). Serviría
  para reconstruir lo que el INDEC tapa y como validación por dos caminos. Requiere una clave gratuita.
- Informe productivo de CAEM 2026 (PDF de 40 páginas, no lo pude leer: falta `poppler` en la Mac).
- Informes trimestrales de las operadoras (Barrick por Veladero, Newmont por Cerro Negro, etc.).
- Carteras de proyectos en PDF de años anteriores, para reconstruir cambios de estado.
- Informes EITI Argentina, USGS Minerals Yearbook, BCRA (inversión extranjera), RIGI.
- Datos de San Juan por otra vía: Ministerio de Minería, Instituto de Investigaciones Económicas y
  Estadísticas, presupuesto provincial (regalías recaudadas).

## 6. Dónde estamos respecto de la tabla central

Todavía no hay una tabla como la de pozos. Los candidatos, de más a menos detalle:

1. **Exportaciones INDEC por producto, país y mes.** Completa hasta algún año entre 2015 y 2026, después
   tapada en lo minero. Sirve como tabla central solo para el tramo abierto, o completándola con datos
   espejo.
2. **Proyectos en el tiempo.** La cartera da 235 proyectos con dueño y estado, pero es una foto. Con las
   carteras viejas, los anuncios de inversión, los impuestos por empresa y la producción de los informes
   de las empresas se podría armar a mano una tabla proyecto por año. Es trabajo de compilación.
3. **Empleo por provincia, rubro y mes.** Es la serie larga y viva más detallada (46.576 filas), pero es
   agregada: no sigue unidades.

## 7. Segunda pasada: los tres caminos (2026-10-13)

Esta sección corrige y completa las secciones 2, 4 y 6.

### 7.1 El secreto estadístico del INDEC

Abrí los 25 archivos anuales (2002 a 2026, 70 MB comprimidos, en una carpeta temporal).

- **De 2002 a 2017 no hay ninguna fila tapada** en los productos mineros que revisé.
- **Empieza en 2018.** El instructivo del INDEC lo fecha en marzo de 2018, cuando la Aduana dejó de
  publicar el detalle.
- Desde 2018 el INDEC tapa los destinos con pocas empresas pero agrega una fila con país `999`
  (confidencial) que junta el resto. Por eso **el total mensual de cada producto sigue siendo exacto**; lo
  que se pierde es a qué país fue una parte.
- Desde 2020 la "s" lleva un número del 1 al 10 que indica el rango de dólares de la fila tapada (por
  ejemplo `s8` es entre 15 y 100 millones).

Qué queda visible en 2025:

| Producto | Con país visible | En "confidencial" (999) |
|---|---|---|
| Oro (7108) | Suiza 2.018 M USD, Canadá y EE.UU. 103 M | 1.975 M USD |
| Carbonato de litio (283691) | China 644 M, otro 6 M | 192 M USD |
| Concentrado de cobre (2603) | nada | no hay fila 999; todo tapado |

Comprobación por dos caminos: el oro del INDEC (suma de visibles más 999) contra el grupo "Oro" de SIACAM.

| Año | INDEC, NCM 7108 (M USD) | SIACAM, Oro (M USD) |
|---|---|---|
| 2015 | 2.261 | 2.275 |
| 2018 | 2.232 | 2.203 |
| 2024 | 3.155 | 3.141 |
| 2025 | 4.097 | 4.094 |

No son idénticos; falta leer la metodología de SIACAM para saber qué posiciones incluye en "Oro".

### 7.2 Datos espejo (UN Comtrade)

La consulta pública funciona **sin clave** para datos anuales (hasta 500 filas por consulta). La consulta
mensual que probé dio error; falta ver si es el formato del pedido o si exige clave.

Oro, lo que declaran haber importado desde Argentina en 2024: Suiza 1.614 M USD, Estados Unidos 772 M,
India 474 M, Canadá 250 M, otros 13 M. Suma 3.123 M contra 3.155 M del INDEC. Coincide, y además da los
destinos que el INDEC tapa.

Carbonato de litio en 2024: China 584 M, Corea 96 M, Estados Unidos 79 M, Japón 66 M y otros. Los ocho
mayores suman unos 840 M contra 614 M del INDEC. **No coincide y no sé por qué.** Los importadores
declaran valor CIF (con flete y seguro) y en otra fecha, pero no verifiqué si eso alcanza para explicar
la diferencia. Queda como pregunta para la etapa de análisis.

### 7.3 Producción mina por mina

- El informe productivo de CAEM (mayo 2026, datos de 2025) arma la producción nacional "en base a
  reportes de empresas": 13 operaciones de oro, 14 de plata, 7 de litio. Publica los totales (oro
  2014-2025, plata 2018-2025, litio 2016-2025, cobre) y la lista de operaciones, **no los números por
  mina**. Sirve como total contra el cual validar una tabla propia.
- Barrick publica en cada informe trimestral una tabla de Veladero (su 50%): onzas producidas, costo de
  ventas, costo total y capital invertido. Los informes están en la SEC.
- **Lo que no pude hacer:** leer esa tabla directamente. La SEC rechaza las descargas automáticas que no
  se identifican con un correo de contacto, y la otra herramienta corta el documento antes de la sección
  de Veladero. Los números de Veladero que vi (36 mil onzas en el segundo trimestre de 2026, 55 mil en el
  primero) salen del resumen de un buscador, no del documento.

Costo estimado de la tabla: unas 20 operaciones, un informe por trimestre o por año cada una, de unas
diez empresas con formatos distintos. Es compilación manual.

### 7.4 Candidatos a tabla central, actualizado

1. **Exportaciones INDEC por producto, país y mes, 2002-2026.** Total exacto por producto todo el
   período; destino completo hasta 2017 y parcial después, completable por año con datos espejo. Trae
   kilos y dólares, así que da precio implícito por kilo.
2. **Operaciones por año** (producción, costos, dueño), compilada de informes de empresas y validada
   contra los totales de CAEM. No existe hecha.
3. **Empleo por provincia, rubro y mes**, como estaba.

## 8. Corrección después de cargar todo en la base (2026-10-13)

En 7.1 escribí que desde 2018 "el total mensual de cada producto sigue siendo exacto". **Vale para el
oro, no para todos.** Al cargar las 4,6 millones de filas y cruzar contra SIACAM por año:

| Año | Oro INDEC | Oro SIACAM | Litio INDEC | Litio SIACAM | Plata INDEC | Plata SIACAM |
|---|---|---|---|---|---|---|
| 2017 | 2.267 | 2.258 | 225 | 224 | 447 | 450 |
| 2019 | 2.213 | 2.156 | 21 | 38 | 519 | 623 |
| 2022 | 2.140 | 2.159 | 76 | 207 | 509 | 802 |
| 2025 | 4.097 | 4.094 | 845 | 915 | 670 | 785 |

(millones de dólares; INDEC es la suma de lo visible)

Hasta 2017 las dos fuentes coinciden en los tres. Desde 2018 el oro sigue coincidiendo, pero en el litio
y la plata el INDEC muestra menos que el total: hay productos donde ni siquiera la fila "confidencial"
alcanza a cubrir lo tapado. En el cobre no queda nada visible entre 2019 y 2025.

Otras dos cosas que aparecieron:

- **SIACAM no es independiente del INDEC.** Su metodología dice que las series son "estimaciones en base
  a Aduana, INDEC y comercio espejo con otros países". Que coincidan confirma que clasifico los productos
  igual que la Secretaría, no que el dato esté bien por dos caminos distintos. La comprobación realmente
  independiente es la de los países compradores (7.2).
- **Cobre 2002-2011:** SIACAM y el INDEC difieren bastante (2002: 639 contra 451 millones) y no sé por
  qué. Desde 2013 coinciden.

Lo que sí cierra exacto: la cantidad de filas y los dólares de cada uno de los 25 archivos del INDEC
contra los totales que el propio INDEC declara.

## 9. Salarios, proveedores y RIGI (2026-10-13)

| Fuente | Qué trae | Período | Detalle |
|---|---|---|---|
| OEDE, por departamento y sector (CSV) | empleo y salario promedio | ene-2019 a dic-2025 | mensual, 486 departamentos, 8 sectores |
| OEDE, remuneraciones por provincia y rama (XLSX) | salario promedio | ene-1995 a jun-2026 | mensual, rama a 4 dígitos |
| OEDE, empleo por provincia y rama (XLSX) | puestos | 1T-1996 a 1T-2026 | trimestral, rama a 4 dígitos |
| RIGI, tablero oficial | 24 proyectos aprobados con inversión, empleo y resolución; plan de inversión anual 2024-2056 | al 13-10-2026 | por proyecto; se arma a mano |

Página del OEDE: `argentina.gob.ar/trabajo/estadisticas/oede-estadisticas-provinciales`. También publica
empleo y salarios por departamento y tamaño de empresa, cantidad de empresas por rama y series anuales,
que no bajé.

**Proveedores y compras locales: sin datos abiertos.** No encontré registro público ni estadística de la
provincia. SIACAM tiene un solo corte, de 2019. Lo que circula son cifras de las empresas en la prensa: por
ejemplo, que Vicuña trabajó en 2025 con 580 proveedores, 60% de San Juan, y que de 318 millones de dólares
pagados, 63,5 fueron a la provincia. No leí el informe original. Queda pendiente revisar los reportes de
sostenibilidad de las empresas y pedir el dato a la provincia.

## 10. Pagos a gobiernos (2026-10-14)

| Fuente | Qué trae | Período |
|---|---|---|
| ESTMA (Natural Resources Canada y Statistics Canada), CSV de 53 MB | pagos por proyecto, gobierno receptor y tipo de pago de todas las extractivas que cotizan en Canadá; 1.498 filas de Argentina | 2021-2025 |
| Barrick, Tax Contribution Report | impuestos y regalías pagados por Veladero, por año | 2022-2025 |
| Newmont, Taxes and Royalties Contribution Report | pagos por país | 2024 (bajado); el de 2025 está en una página que rechaza la descarga |


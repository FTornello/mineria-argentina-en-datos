# Diccionario de datos

Qué significa cada tabla y cada columna del modelo limpio (esquema `mineria`). Fuentes: INDEC (comercio exterior) y Secretaría de Minería de la Nación (SIACAM), descargadas el 13 de octubre de 2026.

## Conceptos, en dos líneas cada uno

- **NCM:** Nomenclatura Común del Mercosur. Es el código de 8 dígitos con que la Aduana clasifica cada producto. `71081210` es oro en bruto para uso no monetario; `28369100` es carbonato de litio.
- **FOB:** el valor de la mercadería puesta arriba del barco en el puerto de salida, sin flete ni seguro. Es como se miden las exportaciones.
- **Secreto estadístico:** la ley prohíbe al INDEC publicar un dato si permite identificar a una empresa. Desde 2018, cuando un producto lo exportan muy pocas empresas a un país, el INDEC tapa los kilos y los dólares de esa fila con una "s".
- **País 999 (Confidencial):** la fila donde el INDEC suma, para un producto y un mes, parte de lo que tapó. No es un destino real.
- **Rubro y grupo:** la clasificación de la Secretaría de Minería. El rubro es amplio (Metalíferos, No metalíferos, Rocas de aplicación) y el grupo es el mineral (Oro, Litio, Plata, Cales).
- **Controlante:** la empresa dueña de un proyecto minero. Un proyecto puede tener hasta tres, cada una con su porcentaje.

## Cómo se conectan las tablas

```
producto ──< exportacion >── pais
                 │
                 └── rango_secreto

producto_hs6 ──< importacion_espejo

Sueltas (se cruzan por fecha, grupo, provincia o empresa):
exportacion_siacam, exportacion_provincia, exportacion_litio_anual, exportacion_litio_destino,
empleo, empresas_por_rubro, precio, proyecto, anuncio_inversion, impuesto_empresa,
indice_produccion, produccion_litio, cuentas_nacionales, balance_cambiario,
empleo_departamento, rigi_proyecto, rigi_plan_inversion

rama ──< salario_rama
rama ──< empleo_rama
```

`exportacion` es la tabla central. La base hace cumplir que cada fila tenga un producto de `producto` y un país de `pais`.

## Tablas

### `exportacion`: exportaciones mineras del INDEC

Una fila por producto, país de destino y mes. Enero de 2002 a agosto de 2026. 67.988 filas.

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes de la exportación. |
| `ncm` | Código del producto. |
| `pais_codigo` | Código del país de destino. |
| `peso_neto_kg` | Kilos exportados. Vacío si la fila está tapada. |
| `fob_usd` | Dólares FOB. Vacío si la fila está tapada. |
| `confidencial` | Verdadero si el INDEC tapó la fila. Solo ocurre desde 2018. |
| `rango_secreto` | Desde 2020, tramo de dólares de la fila tapada (1 a 10). Vacío antes de 2020 y en las filas visibles. |

Límites: 16.778 filas están tapadas. En el oro, la suma de lo visible sigue coincidiendo con SIACAM todos los años. En el litio y la plata no: desde 2018 lo visible es menos que el total (litio 2022: 76 millones de dólares visibles contra 695 del total anual de SIACAM). En el cobre no queda nada visible entre 2019 y 2025.

### `producto`: productos mineros

464 productos. Sale del PDF de metodología de SIACAM.

| Columna | Qué es |
|---|---|
| `ncm` | Código de 8 dígitos. |
| `descripcion` | Descripción del producto. |
| `rubro` | Metalíferos, No metalíferos, Rocas de aplicación, Combustibles o Piedras preciosas o semipreciosas. |
| `grupo` | El mineral (109 grupos). |

Límite: en tres productos el PDF trae rubro y grupo pegados y se cargaron a mano (ver `scripts/preparar_ncm_minero.py`).

### `pais`: países de destino

180 códigos.

| Columna | Qué es |
|---|---|
| `pais_codigo` | Código de la Aduana, el que usa el INDEC. |
| `pais` | Nombre. |

Límite: el INDEC publica solo el código. Los nombres salen del archivo de importaciones de SIACAM, que usa los mismos códigos. 26 códigos no aparecen ahí y quedan como "Código NNN"; son destinos de montos muy chicos.

### `rango_secreto`: tramos de las filas tapadas

| Columna | Qué es |
|---|---|
| `rango_secreto` | Número del 1 al 10. |
| `desde_usd`, `hasta_usd` | Tramo de dólares. El rango 10 no tiene techo (más de 500 millones). |

### `exportacion_siacam`: exportaciones según la Secretaría de Minería

Una fila por grupo de mineral y mes, total país. Enero de 1994 a agosto de 2026. 17.697 filas.

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. |
| `grupo` | Mineral. |
| `rubro` | Rubro (en el archivo se llama "sector"). |
| `fob_usd` | Dólares FOB. |

Límites: desde 2018 existe un grupo "Otro" que junta lo que cae bajo secreto estadístico. Por eso entre 2018 y 2023 el grupo "Litio" de esta tabla muestra menos que lo exportado (2022: 207 millones, contra 695 en `exportacion_litio_anual`); el resto está dentro de "Otro". Para el litio de esos años usar las tablas anuales. Además, la metodología dice que son "estimaciones en base a Aduana, INDEC y comercio espejo con otros países". No es un dato independiente del INDEC. En el cobre, entre 2002 y 2011 difiere bastante del INDEC (2002: 639 millones contra 451) y no sé por qué.

### `empleo`: empleo minero registrado

Una fila por mes, provincia, género y rubro. Enero de 2007 a marzo de 2026. 46.576 filas.

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. |
| `provincia` | Provincia o zona. |
| `genero` | Femenino o Masculino. |
| `rubro` | Rubro de la actividad (Metalíferos, Litio, Rocas de aplicación, etc.). |
| `puestos` | Cantidad de puestos de trabajo. |

Límite: en cuatro meses (junio y octubre de 2009, diciembre de 2012, enero de 2013) hay 268 filas con medio puesto (11,5). No verifiqué a qué se debe.

### `precio`: precios internacionales

Una fila por mes, mineral y unidad. Enero de 1990 a agosto de 2026. 4.934 filas.

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. |
| `mineral` | Mineral, con su símbolo. |
| `unidad` | Unidad del precio (dólares por tonelada, por onza, etc.). |
| `precio` | Precio. |

### `proyecto`: cartera de proyectos metalíferos y de litio

Una fila por proyecto. 235 proyectos, foto a junio de 2026.

| Columna | Qué es |
|---|---|
| `proyecto_id` | Número de orden en el archivo de la Secretaría. |
| `nombre` | Nombre del proyecto. |
| `latitud`, `longitud` | Ubicación. |
| `mineral` | Mineral principal. |
| `provincia` | Provincia. |
| `estado` | Etapa: Prospección, Exploración inicial, Exploración avanzada, Evaluación Económica Preliminar, Prefactibilidad, Factibilidad, Construcción, Producción, Reingeniería o Cese de operaciones. |
| `controlante_1` a `_3` | Empresas dueñas. |
| `origen_1` a `_3` | País de cada controlante. |
| `porcentaje_1` a `_3` | Participación, de 0 a 1. |

Límite: no tiene historia. El número de orden puede cambiar si la Secretaría reordena la lista, así que no sirve para seguir un proyecto entre descargas.

### `anuncio_inversion`: anuncios de inversión

Una fila por anuncio. 55 anuncios, de marzo de 2020 a septiembre de 2025.

| Columna | Qué es |
|---|---|
| `anuncio_id` | Número de orden en el archivo. |
| `fecha` | Primer día del mes del anuncio. |
| `empresa` | Empresa o empresas que anuncian. |
| `proyecto` | Proyecto al que va la inversión. |
| `mineral` | Cobre, Litio, Oro, Plata o Potasio. |
| `provincia` | Provincia. |
| `concepto` | Para qué es (ampliación, exploración, construcción, etc.). |
| `usd` | Monto anunciado, en dólares. |

Límite: son anuncios, no plata invertida. El nombre del proyecto está escrito a mano y no siempre coincide con el de `proyecto`.

### `impuesto_empresa`: impuestos nacionales de las grandes mineras

Una fila por empresa, año e impuesto. 2019 a 2023, entre 14 y 18 empresas por año.

| Columna | Qué es |
|---|---|
| `anio` | Año. |
| `empresa` | Razón social. |
| `impuesto` | Ganancias, Derechos de exportación, Seguridad social, Créditos y débitos, Regalías y canon, o Tasa ambiental. |
| `millones_pesos` | Monto en millones de pesos. |
| `millones_usd` | Monto en millones de dólares. |

Límite: son impuestos nacionales; las regalías provinciales casi no figuran. La columna de total del archivo en dólares trae valores imposibles y no se cargó.

### `indice_produccion`: índice de producción minero

Una fila por mes y rama. Enero de 2017 a julio de 2026, 47 ramas.

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. |
| `rama` | Rama o producto (por ejemplo "Bullón Dorado, Doré" o "Nivel general"). |
| `indice` | Índice de volumen físico. |

Límite: es un índice, no toneladas ni onzas. Incluye petróleo y gas.

### `produccion_litio`: producción de carbonato de litio

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. Junio de 2023 a julio de 2026. |
| `carbonato_litio_ton` | Toneladas producidas en el país. |

### `empresas_por_rubro`: cantidad de empresas mineras

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. Enero de 2007 a marzo de 2026. |
| `rubro` | Rubro de la actividad. |
| `empresas` | Cantidad de empresas con empleo registrado. |

### `exportacion_provincia`: exportaciones mineras por provincia

| Columna | Qué es |
|---|---|
| `anio` | Año. 1994 a 2025. |
| `provincia` | Provincia de origen ("Indeterminado" cuando no se sabe). |
| `millones_usd` | Millones de dólares FOB. |

### `exportacion_litio_anual` y `exportacion_litio_destino`: litio

El total exportado de litio por año (2000 a 2025) y su reparto por país de destino (1995 a 2025), en millones de dólares. Son el número de referencia del litio para 2018-2023.

Límite: son anuales, y los destinos chicos vienen agrupados en "Resto".

### `cuentas_nacionales`: valor de la producción minera

| Columna | Qué es |
|---|---|
| `anio` | Año. 2004 a 2025. |
| `variable` | Valor bruto de la producción o Valor agregado bruto. |
| `precios` | Constantes (pesos de 2004) o Corrientes. |
| `millones_pesos` | Valor. |
| `pct_economia` | Porcentaje sobre el total de la economía. |

### `balance_cambiario`: dólares que entran y salen por sector

Una fila por mes y sector de la economía (30 sectores, uno es "Mineria"). Enero de 2003 a julio de 2026. Millones de dólares; positivo es ingreso neto.

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. |
| `sector` | Sector de la economía. |
| `bienes` | Cobros de exportaciones menos pagos de importaciones. |
| `servicios` | Saldo de servicios. |
| `intereses` | Intereses cobrados menos pagados. |
| `utilidades_dividendos` | Utilidades y dividendos girados al exterior (negativo es salida). |
| `cuenta_corriente` | Suma de lo anterior y otros conceptos corrientes. |
| `ied_neto` | Inversión extranjera directa, neta. |
| `prestamos` | Préstamos financieros, títulos y líneas de crédito. |
| `cuenta_financiera` | Saldo de la cuenta financiera. |
| `resultado_cambiario` | Saldo total del sector. |

Límite: mide dólares que pasan por el mercado de cambios, no exportaciones. Una exportación cuenta cuando se cobra y se liquida, no cuando sale el barco.

### `importacion_espejo`: lo que otros países declaran importar desde Argentina

Datos de UN Comtrade. Una fila por país que informa, producto y período. 4.328 filas.

| Columna | Qué es |
|---|---|
| `frecuencia` | `A` es un año entero (2002 a 2025); `M` es un mes (enero de 2018 a agosto de 2026). |
| `fecha` | Primer día del año o del mes. |
| `pais_codigo`, `pais` | País que declara la importación (código y nombre de Comtrade, en inglés). |
| `hs6` | Producto a 6 dígitos. |
| `peso_neto_kg` | Kilos declarados. |
| `valor_usd` | Valor declarado por el importador, casi siempre CIF (con flete y seguro). |

Límites:
- Las filas anuales y las mensuales cuentan la misma mercadería: filtrar siempre por `frecuencia`.
- Los códigos de país de Comtrade no son los del INDEC; esta tabla no se une con `pais`.
- En el oro, los compradores recién cubren el total argentino desde 2012. Antes informan mucho menos (2008: 53 millones contra 700 del INDEC); no verifiqué por qué.
- El valor es CIF y la fecha es la de llegada, así que no tiene por qué coincidir con el FOB argentino mes a mes.

### `producto_hs6`: los diez productos de los datos espejo

| Columna | Qué es |
|---|---|
| `hs6` | Código a 6 dígitos. |
| `descripcion` | Descripción. |
| `grupo` | Grupo de SIACAM al que corresponde, asignado a mano. |

Límite: `282739` son "los demás cloruros"; incluye el cloruro de litio pero también otros productos.

### `empleo_departamento`: empleo y salario por departamento y sector

Fuente: OEDE (Ministerio de Trabajo), en base a los registros de la seguridad social (SIPA). Una fila por mes, departamento y gran sector. Enero de 2019 a diciembre de 2025, 486 departamentos, 269.724 filas.

| Columna | Qué es |
|---|---|
| `fecha` | Primer día del mes. |
| `provincia`, `departamento` | En mayúsculas, como vienen. |
| `depto_codigo` | Código del departamento. |
| `sector` | Ocho grandes sectores; la minería es "Explotacion de minas y canteras" (incluye petróleo y gas). |
| `empleo` | Puestos de trabajo registrados del sector privado. Vacío si la fuente dice "s.d.". |
| `salario` | Salario bruto promedio del mes, en pesos corrientes. Junio y diciembre incluyen el aguinaldo. |

Límites: una de cada cuatro filas no tiene dato, porque con pocas empresas el dato se tapa. En San Juan, Jáchal (donde está Gualcamayo) no tiene dato de minería en ningún mes. El trabajador se cuenta donde la empresa lo declara, que no siempre es donde vive ni donde está la mina.

### `rama`, `salario_rama` y `empleo_rama`: salarios y empleo por provincia y rama

Fuente: OEDE. Todas las ramas de actividad a cuatro dígitos, no solo las mineras, para poder comparar.

- `rama`: código, descripción y `es_mineria` (verdadero para las ramas 10 a 14). La de los metales es la `1320`.
- `salario_rama`: salario bruto promedio por mes, provincia y rama, en pesos corrientes. Enero de 1995 a junio de 2026. 1.769.430 filas.
- `empleo_rama`: puestos de trabajo por trimestre, provincia y rama. Primer trimestre de 1996 al primero de 2026. 566.369 filas. `fecha` es el primer día del trimestre.

Límites: son pesos corrientes; para comparar años hay que comparar entre ramas o deflactar. Buenos Aires viene partida en "GBA", "CABA" y "Resto de Buenos Aires". Las combinaciones con pocas empresas no figuran. El empleo de la rama 1320 no coincide con el rubro "Metalíferos" de la tabla `empleo` (San Juan, primer trimestre de 2026: 2.264 contra unos 2.770): son clasificaciones distintas y no verifiqué la diferencia.

### `rigi_proyecto`: proyectos aprobados en el RIGI

Armada a mano el 13 de octubre de 2026 desde el tablero oficial. 24 proyectos, 12 de minería.

| Columna | Qué es |
|---|---|
| `proyecto`, `empresa` | Como figuran en el tablero. |
| `sector` | Minería, Petróleo y gas, Energía eléctrica, Siderurgia o Infraestructura. |
| `mineral` | Cobre, Litio, Oro u Oro y plata. Lo asigné yo leyendo la descripción oficial. |
| `provincia`, `provincias_compartidas` | Provincia principal y las otras que comparten el proyecto. |
| `inversion_musd` | Inversión total comprometida, en millones de dólares. |
| `empleos` | Empleos directos e indirectos declarados. |
| `resolucion`, `fecha_resolucion`, `fecha_boletin` | Resolución del Ministerio de Economía que lo aprueba y su publicación. |
| `enlace_norma` | Página oficial de la norma. |

Límites: son compromisos, no inversión hecha ni empleo registrado. El tablero no separa empleo directo de indirecto ni de construcción y operación. Hay que rearmarla a mano cuando se aprueben proyectos nuevos.

### `rigi_plan_inversion`: inversión prevista por año

Una fila por año (2024 a 2056) y rubro, en millones de dólares. Para el cobre, la suma de todos los años da 13.300, igual que la suma de los tres proyectos de cobre aprobados.


### `produccion_anual`: producción física por año

Fuente: CAEM, "Informe productivo de la minería argentina" (mayo de 2026). Copiada a mano de los gráficos del PDF. 56 filas.

| Columna | Qué es |
|---|---|
| `anio` | Año. Oro 2014-2025, plata 2018-2025, litio 2016-2025, cobre 1997-2018 y 2022-2025. |
| `mineral` | Oro, Plata, Litio o Cobre. |
| `produccion` | Cantidad producida en el país. |
| `unidad` | Oro en miles de onzas; plata en millones de onzas; litio en miles de toneladas de carbonato de litio equivalente; cobre en miles de toneladas. |

Límites: CAEM suma lo que informan las empresas; no es una estadística oficial. Cada mineral tiene su unidad y no se pueden sumar. Del cobre faltan 2019 a 2021 porque el gráfico no deja saber a qué año corresponde el valor. Es el total del país: no trae el detalle por mina.

### `produccion_mina`: producción mina por mina

Copiada a mano de los informes anuales de las empresas. Ocho minas de oro, 63 filas: Veladero (2011-2025), Cerro Negro (2014-2025), Cerro Moro (2018-2025), Cerro Vanguardia (2019-2025), San José (2021-2025), Lindero (2021-2025), Gualcamayo (2014-2023, sin 2019) y Bajo la Alumbrera (2014 y 2015).

| Columna | Qué es |
|---|---|
| `mina`, `provincia`, `empresa` | La mina, dónde está y la empresa de cuyo informe sale el dato. |
| `anio`, `mineral`, `unidad` | Año, mineral y unidad (oro en miles de onzas). |
| `publicado` | El número tal cual figura en el informe. |
| `participacion_pct` | Qué parte de la mina representa ese número. |
| `produccion_total` | Producción de la mina entera: publicado dividido por la participación. |
| `fuente`, `pagina` | Informe y página de donde se copió. Cuando el documento se leyó en el navegador (la SEC y la página de Fortuna no dejan bajarlo), la fuente trae la dirección y no hay copia en `data/raw/`. |
| `nota` | Aclaraciones. |

Límites: cada empresa informa a su manera (su parte o el total de la mina, oro pagable o contenido), así que la suma de las minas no da exacto el total del país. Tres datos cubren solo parte del año por cambios de dueño (Veladero 2017, Cerro Negro 2019, Cerro Moro 2023) y no tienen `produccion_total`. De Cerro Vanguardia 2019 y 2020 el informe no aclara si es la parte de la empresa o el total. Faltan Gualcamayo desde 2019 y las minas chicas. Sobre Veladero: el dato de 2017 mezcla seis meses al 100% y seis al 50% (Barrick vendió la mitad a mitad de año), así que no se puede calcular el total. De 2006 a 2010 los informes no traen la tabla de la mina en el mismo formato y no los cargué. El dato de Cerro Negro de 2019 cubre solo desde abril, cuando Newmont compró la mina; los años anteriores eran de Goldcorp y no los tengo.

### `regalias_san_juan`: regalías cobradas por la provincia

Copiada a mano de las planillas de ejecución presupuestaria del Ministerio de Hacienda de San Juan (Planilla 1.1 al cierre de cada año, renglón "Regalías", columna devengado). 2017 a 2025.

| Columna | Qué es |
|---|---|
| `anio` | Año. |
| `regalias_adm_central_pesos` | Lo que cobró la administración central, en pesos corrientes. |
| `regalias_total_pesos` | Administración central más organismos descentralizados. Es la que uso. |
| `archivo` | Planilla de donde salió. |

Límites: el renglón no separa regalías mineras de hidroeléctricas. No incluye los fondos fiduciarios que las mineras aportan aparte ni lo que cobra el instituto provincial dueño de Veladero. De 2014 a 2016 las planillas están en PDF y solo pude leer la columna de la administración central, así que no las cargué. En 2025 cambió el formato de la planilla y las dos columnas dan lo mismo.

### `tipo_cambio`: dólar oficial

Tipo de cambio vendedor del Banco Nación, promedio de cada mes, desde diciembre de 2014. Fuente: series de tiempo de datos.gob.ar.

### `litio_eeuu_desde_chile`: comparación para el litio

Carbonato de litio que Estados Unidos declara importar desde Chile, por año, 2012 a 2025 (UN Comtrade): kilos y valor en dólares. Solo sirve para comparar con lo que importa desde Argentina.

### `operacion_mina`: ley, toneladas y costos por mina

Copiada a mano de los mismos informes que `produccion_mina`. Formato largo: una fila por mina, año e indicador. 96 filas, de Veladero, Cerro Negro y Gualcamayo.

| Columna | Qué es |
|---|---|
| `mina`, `anio` | Mina y año. |
| `indicador` | `ley` (gramos de oro por tonelada), `toneladas_procesadas` (miles de toneladas que entraron a la planta o a la pila), `recuperacion` (porcentaje del oro que se extrae), `costo_de_ventas`, `cash_cost` y `aisc` (dólares por onza). |
| `valor`, `unidad` | El número y su unidad. |
| `fuente`, `pagina`, `nota` | De dónde salió y aclaraciones. |

Límites: cada empresa define los costos a su manera. En Cerro Negro, Goldcorp (hasta 2018) descuenta la plata vendida y Newmont (desde 2019) no, así que la serie de costos tiene un salto en 2019. El AISC no incluye el impuesto a las ganancias ni la inversión en proyectos nuevos: no es la ganancia.

### `pago_gobierno`: pagos de las mineras a los gobiernos argentinos

Fuente: ESTMA, la ley canadiense que obliga a las empresas extractivas que cotizan en Canadá a publicar lo que pagan a cada gobierno del mundo, proyecto por proyecto. Statistics Canada junta todos los informes. 2021 a 2025.

| Columna | Qué es |
|---|---|
| `anio` | Año del pago. |
| `mina` | Proyecto, con el nombre unificado (cada empresa lo escribe distinto). |
| `proyecto_estma` | Nombre tal como figura en la base. |
| `empresa` | Empresa que informa. |
| `sector` | Minería o Hidrocarburos (TotalEnergies, Equinor y Crown Point también informan en Argentina). |
| `tipo_pago` | Impuestos (sobre la renta y la producción), Regalías, Tasas y cánones, Bonos, Pagos por infraestructura, Derechos de producción, Dividendos. |
| `cad`, `usd` | Monto en dólares canadienses y pasado a dólares estadounidenses con el promedio del año (`tipo_cambio_cad`). |

Límites: solo empresas que cotizan en Canadá o tienen filiales allá; faltan, entre otras, Veladero (Barrick la comparte con Shandong y no la incluye), Hochschild y varias de litio. Son pagos en efectivo del año: el impuesto a las ganancias de un año se paga en buena parte al año siguiente. No incluye cargas sociales, IVA ni lo retenido a empleados. Las filas repetidas entre informes de una misma empresa se quitaron y quedaron registradas en `pago_gobierno_repetido`.

### `contribucion_tributaria`: lo que Barrick informa haber pagado por Veladero

Del informe anual de contribución tributaria de Barrick, 2022 a 2025, en millones de dólares. Barrick informa la mina al 100% aunque tiene el 50%. Incluye impuestos nacionales y provinciales y regalías.

### `resultado_operacion`: ingresos y margen de una operación

Copiada a mano de los informes de las empresas. Olaroz (ejercicios de julio a junio de 2022 y 2023, informe anual de Allkem en la bolsa australiana) y Cauchari-Olaroz (2023 a 2025, estados de Minera Exar en el informe anual de Lithium Argentina ante la SEC).

| Columna | Qué es |
|---|---|
| `mina`, `periodo_inicio`, `periodo_fin` | Operación y período. |
| `ingresos_musd`, `ebitda_musd` | Ingresos y margen operativo antes de intereses, impuestos y amortizaciones, en millones de dólares. |
| `toneladas_vendidas`, `precio_usd_t` | Carbonato de litio vendido y precio promedio cobrado. |
| `resultado_bruto_musd`, `costos_financieros_musd`, `resultado_neto_musd` | Ventas menos costo de producir; intereses y otros costos de financiamiento (negativo); resultado final. Solo Cauchari-Olaroz. |
| `toneladas_producidas` | Producción aproximada del año. Solo Cauchari-Olaroz. |
| `fuente`, `pagina`, `nota` | De dónde salió y aclaraciones (incluye quiénes son los dueños). |

### `correccion_ia`: lo que se dijo mal y cómo se detectó

Armada a mano desde `BITACORA.md` (`data/correcciones_ia.csv`). Una fila por cada afirmación hecha durante el proyecto que resultó estar mal. Casi todas las propuso la IA (Claude Code); el registro muestra cómo se detectaron.

| Columna | Qué es |
|---|---|
| `numero` | Orden, de 1 en 1 y sin saltos (hay un control que lo verifica). |
| `fecha`, `seccion_bitacora` | Cuándo pasó y en qué sección de la bitácora está contado. |
| `tipo` | Dato, interpretación, método, modelo de datos, cuenta, presentación, contexto desactualizado u omitido, causa sin respaldo, originalidad, supuesto de un control. |
| `lo_que_se_dijo`, `lo_correcto` | La afirmación y su corrección. |
| `como_se_detecto` | Volver a la fuente, control automático, cruce de fuentes, rehacer la cuenta, revisión en pantalla, buscar más datos o Francisco. |
| `que_quedo` | Qué cambió en el proyecto: un control, una nota, un texto corregido. |

### `hecho_mina`: fechas que explican la producción

Armada a mano (`data/hechos_minas.csv`), cada fila con su fuente. Inicios, cierres, cambios de dueño, accidentes, promesas de producción y entradas al RIGI.

| Columna | Qué es |
|---|---|
| `mina`, `fecha`, `tipo` | Clave de la tabla. `mina` dice `Argentina` cuando el hecho es de todo el país (por ejemplo, un acuerdo). |
| `precision` | Si la fecha es exacta (`día`) o solo se sabe el `mes` o el `año`; en ese caso la fecha es el primer día. |
| `descripcion`, `fuente` | Qué pasó y de dónde sale. |
| `inversion_musd` | Inversión anunciada, en millones de dólares (promesas y RIGI). Las del RIGI tienen que coincidir con `rigi_proyecto` (control). |
| `onzas_anunciadas_miles`, `desde_anio` | En las promesas: producción anual anunciada y desde qué año, para compararla con `produccion_mina`. |

## Archivos que usan las páginas

### `data/mapa_provincias.json`: contorno de las provincias

No es una tabla de la base: lo usan solamente los mapas de las notas. Sale del archivo de provincias del Instituto Geográfico Nacional, achicado por `scripts/preparar_mapa.py` (de 2,2 MB a 25 KB): saca la Antártida, las islas del Atlántico Sur y la Ciudad de Buenos Aires, simplifica los bordes con una tolerancia de unos 4 km y redondea a dos decimales. Es una lista de provincias, cada una con `nombre` y `anillos` (contornos como pares longitud, latitud).


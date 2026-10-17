# Bitácora

Acá voy anotando cómo razono el proyecto: qué decido, por qué y qué descarto. Trabajo con Claude Code como
asistente.

## 1. De dónde vengo

Terminé un proyecto sobre Vaca Muerta: 55 preguntas en SQL sobre 23 fuentes oficiales. Me gustó cómo
trabajé y quiero repetir el método con minería.

Esta vez quiero arrancar distinto. Primero voy a buscar muchos datasets y recién voy a empezar a analizar
cuando el conjunto esté bien nutrido y dé para contar una buena historia. Creo que el valor de estos
análisis está ahí.

## 2. Primera pasada del relevamiento (13 de octubre de 2026)

Todavía no elegí el recorte (San Juan, litio o todo el país), así que relevé todo el país y todos los
minerales para decidir viendo qué datos hay. No bajé nada: abrí cada archivo para ver columnas, filas y
fechas. El detalle está en `docs/relevamiento_fuentes.md`.

Lo que encontré:

| Fuente | Qué aporta | Límite |
|---|---|---|
| Secretaría de Minería (SIACAM) | 22 datasets, casi todos actualizados en 2026 | casi todo agregado |
| Cartera de proyectos | 235 proyectos con dueño, estado y ubicación | es una foto, no tiene historia |
| INDEC, comercio exterior | producto, país y mes desde 2002 | lo minero está tapado por secreto estadístico en los años recientes |
| CEP XXI | salarios y empleo por departamento y actividad | congelado en marzo de 2024 |

El screening de hace unos días había dicho que SIACAM era chico. En parte se corrige: ahora hay cartera de
proyectos, anuncios de inversión e impuestos por empresa. Lo que sigue sin existir es la producción mina
por mina.

Sobre el secreto estadístico: en el archivo del INDEC de 2015 el oro, el cobre y el litio figuran con
kilos y dólares por país. En el de 2026, las 7 filas de concentrado de cobre y las 31 de hidróxido de
litio están tapadas, y también 31 de las 49 de oro. Todavía no sé en qué año empieza.

Todavía no tengo la tabla central que me puse como condición para empezar a analizar.

## 3. Segunda pasada: tres caminos hacia la tabla central (13 de octubre de 2026)

Seguí los tres caminos que habían quedado abiertos.

**El secreto estadístico empieza en 2018.** Abrí los 25 archivos anuales del INDEC. De 2002 a 2017 no hay
ninguna fila minera tapada. Desde 2018 se tapan los destinos con pocas empresas, pero el INDEC agrega una
fila "confidencial" con el resto, así que el total mensual de cada producto sigue siendo exacto. En 2025
el oro tiene 2.018 millones de dólares con destino Suiza a la vista y 1.975 millones sin destino.

**Los países compradores cuentan lo que el INDEC tapa.** En UN Comtrade, Suiza, Estados Unidos, India y
Canadá declaran haber importado 3.123 millones de dólares de oro argentino en 2024. El INDEC da 3.155 y
SIACAM 3.141. Tres fuentes, casi el mismo número.

Con el litio no cierra: los compradores declaran unos 840 millones en 2024 y el INDEC 614. No sé por qué;
lo dejo anotado como pregunta y no como hallazgo.

**La producción mina por mina hay que armarla.** La cámara minera (CAEM) la compila de los informes de las
empresas y publica solo los totales. Probé con Veladero: Barrick publica la tabla cada trimestre, pero no
logré leerla de forma automática desde la SEC.

| Camino | Resultado |
|---|---|
| Año del secreto estadístico | 2018; los totales por producto se salvan |
| Datos espejo | funcionan sin clave para datos anuales; el oro coincide, el litio no |
| Producción por mina | existe en informes de empresas; es compilación manual |

Me equivoqué en la pasada anterior al dar por perdida la base del INDEC desde 2018: lo que se pierde es
parte del destino, no el total.

## 4. Estructura del proyecto y primera carga (13 de octubre de 2026)

Armé el proyecto con la misma estructura que Vaca Muerta y bajé las dos fuentes principales.

| Pieza | Qué hace |
|---|---|
| `scripts/descargar_datos.sh` | baja 25 archivos del INDEC y 59 de SIACAM a `data/raw/` |
| `data/FUENTES.csv` | registra cada archivo con fecha, tamaño y huella |
| capa `raw` | los archivos tal cual, todo como texto |
| esquema `mineria` | el modelo limpio: 8 tablas |
| `sql/04_controles.sql` | 16 controles; si uno falla, la reconstrucción se corta |
| `DICCIONARIO.md` | cada tabla y columna, con sus límites |

La tabla central es `exportacion`: 67.988 filas de exportaciones mineras por producto, país y mes, de
2002 a agosto de 2026. Salen de filtrar las 4,6 millones de filas de exportaciones de todo el país con la
lista de 464 productos que la Secretaría de Minería cuenta como minería. Esa lista estaba en un PDF y la
pasé a tabla.

Decisiones:

- **Cargué las exportaciones de todo el país en la capa cruda, no solo las mineras.** Así puedo controlar
  la carga contra los totales que declara el INDEC, y más adelante comparar la minería con el resto.
- **Los nombres de los países los saqué de SIACAM**, porque el INDEC publica solo el código. Quedaron 26
  códigos sin nombre, todos de montos muy chicos.
- **Saqué de la lista de descarga los cuatro archivos de sustentabilidad de SIACAM**: figuran en el
  catálogo pero dan error 404.

Los controles encontraron dos cosas que no esperaba. En el empleo hay 268 filas con medio puesto de
trabajo (11,5) en cuatro meses de 2009, 2012 y 2013; había definido la columna como número entero y el
control de la suma lo detectó. Y la cartera trae guiones donde un proyecto no tiene segundo controlante.

**Tuve que corregir lo que había anotado en la sección 3.** Ahí escribí que desde 2018 el total de cada
producto seguía siendo exacto. Es cierto para el oro, pero no para el litio ni la plata: en 2022 el INDEC
muestra 76 millones de dólares de litio y SIACAM informa 207. Lo dejé como control: el oro tiene que
coincidir entre las dos fuentes todos los años; el litio, solo hasta 2017.

También aprendí que SIACAM arma sus series con datos del INDEC, de la Aduana y de los países compradores.
Entonces que coincida con el INDEC no es una validación por dos caminos independientes. La independiente
es la de los países compradores, que todavía no está cargada en la base.

Un tropiezo de herramientas: intenté instalar poppler para leer PDF y Homebrew empezó a compilarlo desde
el código fuente e instaló un Python nuevo que tapó al que uso. Corté la instalación y desvinculé ese
Python. Los PDF los leo con PyMuPDF, que ya estaba instalado.

## 5. El resto de SIACAM y una segunda corrección sobre el litio (13 de octubre de 2026)

Marqué el criterio para lo que sigue: el objetivo es contar una buena historia sobre la
minería. Si para eso hay que apartarse de cómo armé Vaca Muerta o construir datasets propios, se hace.

Cargué once tablas más de SIACAM:

| Tabla | Qué trae |
|---|---|
| `anuncio_inversion` | 55 anuncios con empresa, proyecto y monto (2020-2025) |
| `impuesto_empresa` | impuestos nacionales por empresa y año (2019-2023) |
| `indice_produccion` | índice mensual por rama desde 2017; incluye el doré de oro |
| `produccion_litio` | toneladas de carbonato de litio por mes desde junio de 2023 |
| `balance_cambiario` | dólares que entran y salen por sector, mensual desde 2003 |
| `exportacion_provincia` | exportaciones mineras por provincia y año |
| `exportacion_litio_anual` y `_destino` | litio por año y por país comprador |
| `empresas_por_rubro`, `cuentas_nacionales` | cantidad de empresas; valor de la producción |

No cargué las series desestacionalizadas ni las variaciones del índice de producción, porque se calculan
a partir de lo que ya está.

**Segunda corrección sobre el litio.** En la sección 4 comparé el litio del INDEC de 2022 (76 millones de
dólares visibles) contra los 207 millones del archivo mensual de SIACAM y tomé 207 como el total. No lo
es. El archivo mensual de SIACAM tiene desde 2018 un grupo "Otro" donde va lo que cae bajo secreto
estadístico, y parte del litio está ahí. El total real de 2022 es 695 millones, que es lo que dan los dos
archivos anuales del tablero del litio y lo que publica la cámara minera.

| Litio exportado, millones de dólares | 2018 | 2020 | 2022 | 2023 | 2024 |
|---|---|---|---|---|---|
| INDEC, lo visible | 101 | 37 | 76 | 301 | 614 |
| SIACAM mensual, grupo "Litio" | 150 | 43 | 207 | 479 | 645 |
| SIACAM anual | 275 | 129 | 695 | 849 | 645 |

Consecuencia: para el litio, entre 2018 y 2023 no hay serie mensual confiable en los datos abiertos
argentinos. Hay total anual y destinos anuales. El oro no tiene este problema.

Los controles pasaron de 16 a 28. Dos de los nuevos comparan archivos distintos de la Secretaría que
tienen que dar lo mismo: exportaciones por provincia contra exportaciones por mineral, y litio por
destino contra litio total. Cierran todos los años.

## 6. Los datos espejo: la primera validación realmente independiente (13 de octubre de 2026)

Bajé de UN Comtrade lo que los demás países declaran importar desde Argentina, para diez productos:
anual desde 2002 y mensual desde 2018. Fueron 128 pedidos a la consulta pública, que no pide clave pero
acepta un período por pedido. Quedaron 4.328 filas en la tabla `importacion_espejo`.

**El oro cierra.** Entre 2012 y 2025, lo que suman las aduanas de los países compradores y lo que declara
el INDEC difieren menos de 6% todos los años. En 2025: 4.117 millones de dólares contra 4.097. Lo dejé
como control automático. Antes de 2012 los compradores informan mucho menos que el INDEC y no sé por qué.

Además los compradores muestran los destinos que el INDEC tapa desde 2018:

| Oro argentino según el país comprador, millones de dólares | 2017 | 2021 | 2025 |
|---|---|---|---|
| Suiza | 1.117 | 758 | 2.028 |
| Canadá | 1.030 | 233 | 401 |
| Estados Unidos | 55 | 638 | 952 |
| India | menos de 20 | 538 | 723 |

**El litio no cierra igual, y ahí puede haber una pregunta.** Los compradores declaran más que el total
anual de SIACAM en varios años (30% más en 2024, 2% más en 2025, 4% menos en 2022). Parte tiene que ser
el flete y el seguro, y que la mercadería llega semanas después de salir. No sé si alcanza para explicarlo.

Lo que sí se ve en las tres fuentes es el precio por tonelada de carbonato de litio:

| Dólares por tonelada | 2021 | 2022 | 2023 | 2025 |
|---|---|---|---|---|
| Declarado al salir de Argentina (INDEC, filas visibles) | 6.366 | 26.234 | 15.536 | 8.190 |
| Declarado al llegar (países compradores) | 8.431 | 22.259 | 27.737 | 10.412 |
| Precio de referencia en Asia (SIACAM) | 15.542 | 69.500 | 39.386 | 9.485 |

En 2022, con el precio de referencia en 69.500, el litio argentino llegó a destino a 22.259. Esto es lo
que muestran los datos. No es prueba de nada por sí solo: gran parte del litio se vende con contratos de
largo plazo a precio fijado antes, y el precio de referencia es el del mercado al contado en China. Queda
como pregunta para la etapa de análisis. El dato de salida de 2022 se apoya en pocas filas visibles
(2.906 toneladas de unas 30.000).

Los controles son ahora 32 y cierran todos.

## 7. Qué se discute hoy (13 de octubre de 2026)

Había armado un primer panorama de historias con notas de prensa de marzo a junio, y dos de los temas ya
estaban resueltos: la Ley de Glaciares se reformó en abril y los grandes proyectos ya entraron al RIGI. Lo
rehice mirando las portadas de esta semana de cinco medios mineros. Quedó en `docs/agenda_2026-10.md`.

La discusión se corrió. Ya no es si las inversiones van a venir, sino quién se queda con los contratos y
los empleos, si hay gente e infraestructura para hacerlas, y si el récord de exportaciones es producción o
es precio.

## 8. Salarios, proveedores y RIGI (13 de octubre de 2026)

Busqué datos para los tres temas que faltaban para la agenda de hoy.

**Salarios y empleo: apareció la mejor fuente del proyecto.** El Observatorio de Empleo del Ministerio de
Trabajo (OEDE) publica empleo y salarios registrados por provincia y rama a cuatro dígitos desde 1995, y
por departamento desde 2019, actualizados a 2026. Reemplaza lo del CEP XXI, que estaba congelado en 2024.
Cargué tres tablas, con todas las ramas y no solo las mineras, para poder comparar.

**RIGI: hay lista oficial.** El tablero del Ministerio de Economía muestra los 24 proyectos aprobados. Los
datos no se pueden bajar como archivo, así que armé la tabla a mano y busqué la resolución de cada uno en
la página oficial de normativa. La suma da exactamente los totales del tablero (56.198 millones de dólares
y 116.350 empleos), y quedó como control. Agua Rica, que la prensa dio por aprobado el 2 de octubre, no
figura todavía: el tablero cuenta solo los que tienen resolución publicada.

**Proveedores: no encontré datos.** No hay registro público de compras locales. Lo único son números
sueltos de las empresas en notas de prensa.

Lo primero que muestran las tablas nuevas, sin análisis todavía:

| | Dato |
|---|---|
| Salario en la minería metalífera de San Juan, enero a mayo de 2026 | 8,6 millones de pesos, 5,3 veces el promedio del resto del empleo privado |
| Esa misma relación en 2010 y en 2019 | 3,6 veces y 4,8 veces |
| Puestos en esa rama en San Juan, primer trimestre de 2012 y de 2026 | 2.302 y 2.264 |
| Empleos que declaran los cuatro proyectos mineros de San Juan en el RIGI | 44.639 |
| Peso de la minería en el empleo privado de Iglesia, diciembre de 2025 | 36% |
| Año de mayor inversión prevista en cobre | 2028 |

El promedio del "resto" lo calculé ponderando el salario de cada rama por su empleo; usé enero a mayo para
no mezclar el aguinaldo.

Los controles son 43 y cierran todos.

## 9. Empieza el análisis: el récord de exportaciones (13 de octubre de 2026)

Definí con Claude tres historias y un calendario: si el récord de exportaciones es precio o
producción; a quién se le vende el litio; qué dejaron 21 años de Veladero ahora que llega el cobre; y
cuándo empiezan a producir los proyectos aprobados. Doy por cumplida la condición de la etapa 1: la tabla
central es la de exportaciones por producto, país y mes, con el límite de que sigue productos y no minas.

Antes de arrancar sumé una tabla hecha a mano: la producción física anual de oro, plata, litio y cobre que
publica la cámara minera (CAEM) en un PDF. Sin onzas y toneladas no se puede separar precio de volumen.
Copié los números de los gráficos y los controlé contra dos promedios que trae el mismo informe.

Las consultas están en `sql/analisis/`, una por pregunta.

**P01. Cuánto exporta la minería.** 6.074 millones de dólares en 2025, el máximo de la serie. El oro es
el 67% y el litio el 15%.

**P02. Lo que dijo la prensa sobre el primer semestre de 2026, contra los datos.**

| | Prensa | Mis datos |
|---|---|---|
| Exportaciones mineras del semestre | 4.742 M USD | 4.799 |
| Variación contra 2025 | +75% | +76% |
| Parte del oro | 61% | 61% |
| Parte del litio | cerca de una cuarta parte | 23% |
| Parte de la minería en las exportaciones del país | casi 10% | 9,7% |

Coincide. La diferencia chica en el total es esperable porque los datos de 2026 se revisan.

**P03. Oro: precio o producción.** Entre 2019 y 2025:

| | 2019 | 2025 | Cambio |
|---|---|---|---|
| Producción, miles de onzas | 1.626 | 1.184 | -27% |
| Precio promedio, dólares por onza | 1.393 | 3.442 | +147% |
| Exportado, millones de dólares | 2.156 | 4.094 | +90% |

Si el oro costara lo que costaba en 2019, la producción de 2025 valdría 1.649 millones de dólares en lugar
de 4.094. Todo el aumento es precio; la producción resta.

**P04. Si las fuentes coinciden sobre la caída.** Comparé tres medidas del volumen con base 2017 = 100.
Las onzas que suman las empresas (CAEM) quedan en 61 en 2025. Las onzas que salen de dividir los dólares
exportados por el precio quedan en 66. Coinciden. El índice oficial de producción de doré queda en 23: la
misma dirección, pero una caída mucho mayor. No sé a qué se debe esa diferencia. Para la magnitud me
quedo con las dos que coinciden y dejo anotada la tercera.

Esto corrige algo que venía diciendo: usé varias veces el índice de doré ("de 156 a 35") como medida de la
caída. Sirve para la dirección, no para el tamaño.

**P05. Litio: al revés.** La producción pasó de 35 mil toneladas en 2022 a 116,6 mil en 2025 y lo
exportado de 695 a 915 millones. Por cada tonelada producida entraron 19.858 dólares en 2022 y 7.847 en
2025. Comparado con el precio de referencia en Asia, eso fue el 29% en 2022 y el 83% en 2025. Lo que
muestran los datos es que en el pico de precios el litio argentino se vendió muy por debajo de la
referencia y que hoy la brecha es mucho menor. Por qué, no lo sé todavía: contratos a precio fijado antes
es una explicación posible y no la verifiqué.

**P06. Qué pasa en 2026** (enero a julio contra el mismo período de 2025).

| | Volumen | Precio | Exportado |
|---|---|---|---|
| Oro | -2% | +48% | +44% |
| Litio | +44% | +126% | +199% |

El oro sigue igual: menos producción, más dólares. En el litio en 2026 se juntan las dos cosas, más
producción y precio en alza.

**Dónde estamos después de seis preguntas.** La historia se sostiene y tiene dos mitades opuestas: el oro
exporta récord con minas que producen menos, y el litio produce récord pero su valor depende de a cuánto
se vende. Lo que falta para cerrarla es el detalle por mina, para mostrar cuáles se están agotando.

## 10. A quién se le vende el litio (13 de octubre de 2026)

Cinco consultas más, de P07 a P11.

**P07. Los destinos se dieron vuelta.** En 2012 Estados Unidos compraba el 59% del litio argentino y China
el 20%. En 2025 China compró el 75% y Estados Unidos el 9%. El salto de China es reciente: 43% en 2023,
67% en 2024.

**P08. Los compradores lo confirman, con una diferencia que no sé explicar.** Estados Unidos y Japón
declaran importar más o menos lo que la Argentina declara venderles. China declara más casi todos los
años: 479 millones de dólares contra 365 en 2023, 584 contra 432 en 2024, 777 contra 685 en 2025. El flete
y el seguro explican una parte. Otra posibilidad es que haya litio que sale declarado hacia otro destino
y termina en China. No lo verifiqué.

**P09. No todos pagan lo mismo.** Precio promedio de llegada del carbonato de litio argentino, en dólares
por tonelada, según la aduana de cada comprador:

| | 2021 | 2022 | 2023 | 2025 |
|---|---|---|---|---|
| Japón | 8.069 | 38.366 | 49.413 | 8.784 |
| Corea del Sur | 8.927 | 29.508 | 44.792 | sin dato |
| China | 9.788 | 22.659 | 26.223 | 10.441 |
| Estados Unidos | 6.056 | 7.106 | 10.920 | 10.864 |
| Precio de referencia en Asia | 15.542 | 69.500 | 39.386 | 9.485 |

En 2022, con la referencia en 69.500, a Estados Unidos el litio argentino le llegó a 7.106: casi lo mismo
que pagaba antes de la suba. Entre 2012 y 2022 ese precio se movió entre 4.400 y 7.100 dólares mientras
el mercado se multiplicaba. Eso es lo que muestran los datos. Mi lectura, sin verificar, es que son ventas
con precio fijado por contrato de largo plazo o entre empresas del mismo grupo; son entre 6.000 y 10.000
toneladas por año, siempre un volumen parecido.

**P10. China, por semestre.** En el primer semestre de 2022 el litio argentino llegó a China al 29% del
precio de referencia; en el segundo de 2023 al 91% y en 2024 a la par. El precio de llegada sigue a la
referencia, pero con mucho atraso en la subida. Los datos mensuales de China llegan hasta diciembre de 2024.

**P11. De quién son los proyectos.** De los siete proyectos de litio en producción, tres tienen como dueño
principal a una empresa china, dos a una del Reino Unido (Rio Tinto), uno a una francesa y uno a una
coreana. Entre los que están en producción, construcción o factibilidad, ninguno tiene como primer
controlante a una empresa de Estados Unidos, según la cartera de la Secretaría a junio de 2026.

**Parada a las once preguntas.** Lo que se está armando:

1. El oro exporta récord produciendo 27% menos que en 2019. El récord es precio.
2. El litio produce récord, pero durante la suba de 2022 se vendió a una fracción del precio de mercado,
   y el comprador que menos pagó fue Estados Unidos.
3. Mientras se discute si el litio argentino es estratégico para Estados Unidos, tres cuartos van a China
   y ningún proyecto en marcha tiene dueño principal estadounidense.

Las tres cosas tienen la misma forma: un titular que circula y un dato que lo matiza. Falta la tercera
historia (qué dejó Veladero y qué promete el cobre) y el detalle por mina.

## 11. Producción mina por mina: prueba con Veladero (13 de octubre de 2026)

Decidimos bajar los informes de las empresas a mano desde sus páginas, sin pasar por la SEC. Probé con
Veladero: bajé los veinte informes anuales de Barrick (2006 a 2025, 118 MB) y busqué en cada uno la tabla
de la mina. Salió la serie de 2011 a 2025, con el informe y la página de cada número.

Barrick tiene la mitad de Veladero desde mediados de 2017 y publica solo su parte, así que desde 2018
multiplico por dos. El informe de 2024 trae los dos números (252 mil onzas por su parte y 505 mil por el
total) y lo usé como control de esa cuenta.

| | 2011 | 2014 | 2019 | 2021 | 2024 | 2025 |
|---|---|---|---|---|---|---|
| Veladero, miles de onzas | 957 | 722 | 548 | 344 | 504 | 460 |
| Parte de la producción del país | sin dato | 38% | 34% | 29% | 40% | 39% |

Dos cosas que no esperaba. Veladero produce hoy la mitad que en 2011, pero la caída fuerte fue antes de
2016; desde 2018 se mueve entre 340 y 550 mil onzas sin una tendencia clara. Y entre 2019 y 2025 el país
perdió 442 mil onzas de producción mientras Veladero perdió 88 mil: la mayor parte de la caída reciente
viene de otras minas. Para saber de cuáles hay que cargar las demás.

Costo de la tabla completa: una mina me llevó veinte informes. Quedan unas doce operaciones de oro y
plata y siete de litio, de unas diez empresas. Es trabajo de varias sesiones.

Los controles son 48 y cierran todos.

## 12. Qué dejó el oro en San Juan y qué promete el cobre (13 de octubre de 2026)

Ocho consultas, de P12 a P19. Desde acá hago commit en cada avance; lo puse como regla.

**P12. El ciclo del oro en San Juan.** Las exportaciones mineras de la provincia pasaron de 26 millones de
dólares en 2005 a un máximo de 1.909 en 2011. Después bajaron y estuvieron diez años cerca de 900. En 2025
fueron 1.759, con Veladero produciendo menos de la mitad que en 2011: otra vez el precio. El empleo en la
minería de metales llegó a 2.732 puestos en 2017 y en 2025 fue de 2.054.

**P13. Cuánto pesa en el empleo.** La minería (metales más canteras) es entre el 3,3% y el 3,8% del empleo
privado registrado de San Juan desde 2010. Es solo el empleo directo: los contratistas figuran en otras
ramas y no los puedo separar.

**P14. Cuánto más paga.** En 2026 la minería de metales paga 5,3 veces el promedio del resto del empleo
privado de la provincia y 4,6 veces el de la industria. La brecha era de 3,6 veces en 2010 y pasó de 5
desde 2020. Esto le pone número a la queja de la industria sanjuanina de que compite con la minería por
empleados.

**P15. Iglesia.** En el departamento de Veladero, el sector servicios paga el triple que en el promedio
provincial y la construcción el doble. Mi lectura es que no es un derrame hacia el comercio del pueblo
sino los contratistas de la mina, que declaran a su gente en Iglesia: el comercio de Iglesia paga solo 15%
más que el promedio. No lo puedo verificar con estos datos, porque el trabajador se cuenta donde lo
declara la empresa y no donde vive.

**P16. Impuestos de Veladero.** Entre 2019 y 2023 la empresa que opera la mina pagó entre 103 y 149
millones de dólares por año en impuestos nacionales, entre el 13% y el 23% del valor del oro producido
(onzas por precio, calculado por mí). En 2023 no pagó impuesto a las ganancias. No tengo las regalías
provinciales.

**P17. El tamaño de lo que se promete.** Los cuatro proyectos de San Juan aprobados en el RIGI declaran
44.639 empleos directos e indirectos. La minería de metales de la provincia tiene hoy 2.264 puestos
registrados, y todo el empleo privado registrado de San Juan son 85.493. Solo Vicuña declara 31.700. Los
números no son comparables uno a uno (los del RIGI mezclan obra, operación e indirectos), pero dan la
escala de lo que se está prometiendo. La inversión comprometida, 13.510 millones, equivale a casi ocho
años de las exportaciones mineras de San Juan de 2025.

**P18. Cuándo llega.** Según el plan oficial, a fin de 2026 se habrá invertido el 11% de lo comprometido
en cobre. La mitad llega recién en 2028 y el plan termina en 2031. En litio ya va el 46%.

**P19. El antecedente de Catamarca.** Bajo la Alumbrera dejó de producir en 2018. Las exportaciones
mineras de Catamarca pasaron de 2.024 millones de dólares en 2007 a 99 en 2020. El empleo metalífero de la
provincia bajó de 1.963 puestos en 2013 a 511 en 2020. Lo que vino después fue el litio: 1.546 puestos en
2025, con exportaciones de 354 millones.

**Parada a las diecinueve preguntas.** Las tres historias están armadas y comparten una idea: en minería,
los dólares que se anuncian y lo que pasa en el terreno no se mueven juntos.

1. El oro: récord de dólares con 27% menos de producción.
2. El litio: récord de producción, vendido a una fracción del precio en el pico, y con destino China.
3. San Juan: veinte años de oro dejaron unos 2.000 puestos directos muy bien pagos y 3,5% del empleo
   privado; el cobre promete veinte veces eso, con la mayor parte de la inversión todavía por llegar.

Lo que falta: las regalías de San Juan, el empleo indirecto, la producción de las demás minas y revisar
las lecturas que dejé marcadas como sin verificar (contratos del litio, contratistas en Iglesia).

## 13. Regalías de San Juan y el litio que compra Estados Unidos (13 de octubre de 2026)

**Regalías: encontré la fuente oficial.** No hay un dataset, pero el Ministerio de Hacienda de San Juan
publica la ejecución presupuestaria al cierre de cada año, con un renglón de regalías. Bajé las planillas
de diciembre de 2017 a 2025 y copié ese renglón a una tabla. Para pasarlo a dólares sumé el tipo de cambio
oficial mensual.

**P20. Cuánto cobra San Juan.**

| | 2017 | 2019 | 2021 | 2023 | 2024 | 2025 |
|---|---|---|---|---|---|---|
| Regalías, millones de dólares | 37 | 31 | 29 | 24 | 45 | 49 |
| Parte de lo exportado por la minería de la provincia | 3,3% | 3,4% | 3,4% | 2,7% | 3,0% | 2,8% |

La regalía que fija la ley es 3% y lo cobrado da entre 2,7% y 3,6% de lo exportado todos los años. Son
dos fuentes distintas (el presupuesto provincial y las exportaciones de la Secretaría de Minería) y
cierran, así que lo dejé como control. El primer rango que puse (1,5% a 3,5%) hizo saltar el control con
2022, que da 3,6%; lo amplié a 2% a 4% y dejé anotado por qué. Que algunos años pase de 3% puede ser por
las regalías hidroeléctricas, que están en el mismo renglón, o por pasar a dólares con el promedio anual.

Para tener la escala: en 2025 San Juan cobró 49 millones de dólares de regalías sobre 1.759 millones
exportados. La empresa que opera Veladero pagó en impuestos nacionales entre 103 y 149 millones por año.

**P21. El litio que compra Estados Unidos: verifiqué la lectura que había dejado abierta.** En P09 vi que
a Estados Unidos el litio argentino le llegó a 7.106 dólares la tonelada en 2022, con la referencia en
69.500, y supuse ventas por contrato o entre empresas del mismo grupo. Hice dos cosas.

Primero busqué si había antecedentes. Los hay: en julio de 2022 la Aduana denunció a Livent, que exporta
desde Catamarca, por declarar 5.100 dólares la tonelada en 403 operaciones de 2018 y 2019, un mes después
de fijar un precio de referencia de 53.000.

Segundo, comparé con Chile. Bajé de UN Comtrade lo que Estados Unidos importa de carbonato de litio desde
Chile: mismo comprador, mismo producto, otro proveedor.

| Dólares por tonelada, según la aduana de EE.UU. | 2016 | 2019 | 2022 | 2023 | 2025 |
|---|---|---|---|---|---|
| Desde Argentina | 5.284 | 5.605 | 7.106 | 10.920 | 10.864 |
| Desde Chile | 4.589 | 12.804 | 13.585 | 19.625 | 9.551 |
| Argentina como porcentaje de Chile | 115% | 44% | 52% | 56% | 114% |

Hasta 2017 Estados Unidos pagaba lo mismo por el litio de los dos países. Entre 2018 y 2023 pagó por el
argentino alrededor de la mitad que por el chileno. En 2025 volvieron a estar a la par. Los años de la
brecha incluyen los de la denuncia de la Aduana.

Dos cosas quedan separadas. Que el precio a Estados Unidos fuera bajo frente a la referencia de Asia pasa
también con Chile (13.585 contra 69.500 en 2022), así que una parte es cómo se vende el litio a ese
mercado. Lo propio de la Argentina es la otra mitad: vender a la mitad que Chile al mismo comprador
durante seis años. Los datos no dicen qué empresa vendió; que sea Livent es lo que sugiere la denuncia,
no algo que yo pueda ver en la aduana.

Los controles son 51 y cierran todos. Van 21 preguntas.

## 14. El costo fiscal del litio barato y la segunda mina (13 de octubre de 2026)

**P22. Cuánto valor faltó.** Hice la cuenta que había quedado planteada: si entre 2018 y 2023 Estados
Unidos hubiera pagado por el litio argentino lo mismo que por el chileno, lo exportado habría valido 222
millones de dólares más en esos seis años. Con el derecho de exportación de hoy (4,5%) eso son 10 millones
de dólares no cobrados; sumando una regalía de 3%, unos 17 millones.

Es un ejercicio y lo dejé dicho en la consulta: supone que el precio chileno era el correcto y usa las
mismas tasas para todos los años. Como referencia, la Aduana reclamó 8 millones de dólares solo por 2018 y
2019, años en que los derechos de exportación eran más altos; mi cuenta para esos dos años da entre 3,5 y
5,7 millones. El orden de magnitud es el mismo.

Lo que me llevo: la brecha de precio es grande y duró seis años, pero la plata que el Estado dejó de
cobrar es chica, porque los impuestos sobre el litio son bajos. El tema de fondo no es la subfacturación
sino cuánto del valor del litio queda en el país aun facturando bien.

**Cerro Negro, la segunda mina.** Bajé los informes de Newmont desde su página y saqué la producción de
Cerro Negro (Santa Cruz) de 2019 a 2025. Antes de abril de 2019 la mina era de Goldcorp y no tengo esos
años.

**P23. De qué minas viene la caída.**

| Miles de onzas | 2020 | 2022 | 2024 | 2025 |
|---|---|---|---|---|
| País (CAEM) | 1.120 | 1.304 | 1.259 | 1.184 |
| Veladero | 452 | 390 | 504 | 460 |
| Cerro Negro | 216 | 278 | 238 | 202 |
| Resto de las minas | 452 | 636 | 517 | 522 |

Las dos minas juntas son entre la mitad y el 60% del oro del país. Entre 2022 y 2025 el país perdió 120
mil onzas: Veladero subió 70 mil, Cerro Negro bajó 76 mil y el resto bajó 114 mil. Con dos minas cargadas
se confirma que la caída reciente no es de Veladero: es de Santa Cruz y de las minas más chicas.

Lo que no logré: la página de informes de AngloGold Ashanti (Cerro Vanguardia) no cargó, y Gualcamayo hoy
es de una empresa que no publica informes. Los números de Cerro Vanguardia que encontré salen de un
buscador y no los cargué porque no los leí en el documento.

Van 23 preguntas y 51 controles, todos en verde.

## 15. Más minas, con lo que dejaron bajar las empresas (14 de octubre de 2026)

Decidí que el tablero de este proyecto va a ser una página en HTML, no Tableau ni Power BI.

Seguí con las minas que faltaban. Lo que pude leer directamente en documentos bajados de la página de
cada empresa:

| Mina | Empresa | Años cargados | Oro en 2025, miles de onzas |
|---|---|---|---|
| Veladero (San Juan) | Barrick | 2011 a 2025 | 460 |
| Cerro Negro (Santa Cruz) | Newmont | 2019 a 2025 | 202 |
| Cerro Moro (Santa Cruz) | Pan American Silver | 2023 parcial y 2025 | 83 |
| San José (Santa Cruz) | Hochschild | 2024 y 2025 | 77 |

Las cuatro suman 822 mil onzas en 2025, el 69% de las 1.184 mil del país.

Lo que no pude cargar y por qué:

- **Cerro Vanguardia (AngloGold Ashanti).** La página de informes de la empresa no carga con mis
  herramientas. Un buscador da 179 mil onzas para 2025 y 175 mil para 2024, tomadas de la presentación
  ante la SEC; no lo leí en el documento y no lo cargué.
- **Lindero (Fortuna, Salta).** La página de la empresa arma el contenido con JavaScript y no la pude
  leer. El buscador da 87 mil onzas para 2025.
- **Cerro Moro 2024 y San José antes de 2024.** Hay un informe por año y no encontré la dirección de los
  anteriores en las páginas de las empresas.
- **Gualcamayo.** Hoy es de una empresa que no publica informes.
- **Cerro Negro antes de 2019** era de Goldcorp, y Cerro Moro antes de 2023 era de Yamana: empresas que ya
  no existen y cuyos informes solo están en la SEC.

Este camino rinde cada vez menos. Las dos minas grandes tienen serie y alcanzan para lo que la historia
necesita: mostrar que la caída reciente no es de Veladero. Abrir el resto mina por mina pide entrar a la
SEC con un correo de contacto, o bajar a mano los seis o siete documentos que faltan.

## 16. Las minas, completas hasta donde se puede (14 de octubre de 2026)

Preferí completar las minas. Lo destrabé leyendo los documentos en el navegador en lugar
de bajarlos: la SEC y algunas páginas de empresas rechazan las descargas automáticas pero se abren
normalmente. La contra es que de esos documentos no queda copia en `data/raw/`; dejé la dirección exacta
de cada uno en la tabla.

Así pude leer los informes de empresas que ya no existen (Goldcorp, dueña de Cerro Negro hasta 2019, y
Yamana, dueña de Gualcamayo y Cerro Moro) y los de AngloGold Ashanti y Fortuna. La tabla pasó de dos minas
a ocho.

**P23, rehecha. De qué minas viene la caída del oro.**

| Miles de onzas | 2015 | 2018 | 2021 | 2024 | 2025 |
|---|---|---|---|---|---|
| País (CAEM) | 2.038 | 1.865 | 1.183 | 1.259 | 1.184 |
| Veladero | 602 | 556 | 344 | 504 | 460 |
| Cerro Negro | 507 | 489 | 270 | 238 | 202 |
| Cerro Vanguardia | sin dato | sin dato | 157 | 175 | 179 |
| Gualcamayo | 181 | 92 | sin dato | sin dato | sin dato |
| Cerro Moro | no existía | 93 | 80 | 78 | 83 |
| San José | sin dato | sin dato | 84 | 74 | 77 |
| Lindero | no existía | no existía | 104 | 97 | 88 |
| Bajo la Alumbrera | 197 | sin dato | cerrada | cerrada | cerrada |
| Parte del país cubierta | 73% | 66% | 88% | 93% | 92% |

Lo que cambia respecto de lo que venía diciendo:

- **La mina que más cayó es Cerro Negro, no Veladero.** Pasó de 507 mil onzas en 2015 a 202 mil en 2025:
  300 mil onzas menos, el 60%. Veladero perdió 142 mil en el mismo período.
- **Bajo la Alumbrera también era una mina de oro.** Produjo 320 mil onzas en 2014 y 197 mil en 2015,
  además del cobre. Su cierre en 2018 explica una parte de la caída del oro del país que yo estaba
  atribuyendo a "minas que se agotan".
- **Gualcamayo se redujo a la mitad antes de cambiar de dueño**: de 181 mil onzas en 2015 a 92 mil en 2018.
- **Las minas nuevas no compensaron.** Cerro Moro (2018) y Lindero (2020) suman unas 170 mil onzas; solo
  la caída de Cerro Negro es casi el doble.

Con esto la historia del oro queda mejor contada: el país produce 850 mil onzas menos que en 2015, y eso
se reparte entre una mina grande de Santa Cruz que rinde mucho menos, una que cerró en Catamarca, dos de
San Juan que bajaron, y dos nuevas que no alcanzaron a reemplazarlas. Mientras tanto el valor exportado se
duplicó.

Lo que sigue faltando: Gualcamayo desde 2019 (pasó a Mineros, que informa en Canadá, y después a una
empresa que no publica), Cerro Vanguardia y San José en los años anteriores, y las minas chicas. En 2024 y
2025 lo que falta es el 7% u 8% del país.

## 17. Por qué cayó Cerro Negro, cuánto margen deja el récord y el final de Gualcamayo (14 de octubre de 2026)

Sumé una tabla con datos de operación de las minas, sacados de los mismos informes: ley del mineral,
toneladas procesadas, recuperación y costo por onza. Y completé Gualcamayo de 2020 a 2023 con los informes
de Mineros, que sí están en su página.

**P24. Por qué cayó Cerro Negro.**

| | 2018 | 2021 | 2023 | 2025 |
|---|---|---|---|---|
| Oro producido, miles de onzas | 489 | 270 | 269 | 202 |
| Toneladas procesadas, miles | 1.126 | 885 | 1.076 | 789 |
| Ley, gramos de oro por tonelada | 13,9 | 10,2 | 8,3 | 8,3 |

Las dos cosas a la vez: el mineral es 40% más pobre que en 2018 y se procesa 30% menos. La cuenta
toneladas por ley por recuperación da casi exacto lo que la empresa informa como producido, todos los años;
la dejé como control. Es la definición de una mina que se va agotando: lo más rico ya se sacó.

**P25. Cuánto margen deja el récord.**

| | 2018 | 2021 | 2023 | 2025 |
|---|---|---|---|---|
| Precio del oro, dólares por onza | 1.269 | 1.800 | 1.943 | 3.442 |
| Veladero, costo total por onza (AISC) | 1.154 | 1.493 | 1.516 | 1.450 |
| Veladero, margen por onza | 115 | 307 | 427 | 1.992 |
| Cerro Negro, costo total por onza | 535 | 1.247 | 1.509 | 2.220 |
| Cerro Negro, margen por onza | 734 | 553 | 434 | 1.222 |

En Veladero el costo por onza está igual que en 2021 y el precio casi se duplicó: el margen por onza pasó
de 300 a casi 2.000 dólares. Multiplicado por la producción, de 64 millones de dólares en 2018 a unos 900
millones en 2025. En Cerro Negro el costo por onza se cuadruplicó (en parte porque cambió el dueño y la
forma de calcularlo), y el precio lo compensa. El AISC no incluye el impuesto a las ganancias: no es la
ganancia, es el margen antes de ese impuesto.

Para comparar con lo que queda: entre 2019 y 2023, años de margen chico, la operadora de Veladero pagó entre
103 y 149 millones por año de impuestos nacionales y San Juan cobró entre 24 y 31 millones de regalías.
Para 2024 y 2025, con márgenes mucho mayores, todavía no hay datos de impuestos por empresa.

**P26. Gualcamayo.** Produjo 181 mil onzas en 2015 y 31 mil en los nueve meses de 2023 antes de venderse.
En 2021 su costo total fue de 1.969 dólares por onza con el oro a 1.800: perdía plata por cada onza. La ley
era de 1,4 a 1,8 gramos por tonelada y recuperaba la mitad del oro. Desde septiembre de 2023 es de una
empresa que no publica datos, y en enero de 2026 su proyecto de reactivación (Carbonatos Profundos) entró
al RIGI con 665 millones de dólares y 4.500 empleos declarados.

Lo que se suma a la historia del oro: el récord de exportaciones no es solo precio; para las minas que
siguen es también un margen que se multiplicó, mientras lo que cobra el Estado (regalías del 3% sobre el
valor) crece en proporción al valor y no al margen.

Los controles son 53 y cierran todos. Van 26 preguntas.

## 18. Cuánto pagaron al Estado en los años de precio récord (14 de octubre de 2026)

Los impuestos por empresa de SIACAM llegan hasta 2023. Para 2024 y 2025 encontré dos fuentes:

- **ESTMA**, una ley canadiense que obliga a las mineras que cotizan en Canadá a publicar lo que pagan a cada
  gobierno, proyecto por proyecto. Statistics Canada junta todo en una base pública. Para Argentina tiene
  pagos de 2021 a 2025 de Newmont, AngloGold, Pan American, Fortuna, SSR, Rio Tinto, Glencore y otras.
  Viene en dólares canadienses; sumé el tipo de cambio del Banco de Canadá.
- **El informe de contribución tributaria de Barrick**, porque Veladero no está en ESTMA (Barrick la
  comparte con Shandong). Barrick informa la mina al 100%.

En la base canadiense algunos pagos aparecen dos veces (Pachón, que en 2025 informan Glencore y su filial
con los mismos montos). Los quité y dejé registrado cuáles para que el control cierre.

**P27. Pagado al Estado como parte del valor producido.**

| | 2022 | 2023 | 2024 | 2025 |
|---|---|---|---|---|
| Veladero | 31% | 31% | 18% | 23% |
| Cerro Negro | 18% | 14% | 6% | 8% |
| Lindero | 10% | 9% | 7% | 3% |
| Cerro Vanguardia | sin dato | sin dato | 14% | 20% |

En Veladero el valor producido pasó de 804 millones de dólares en 2023 a 1.583 en 2025 (casi el doble) y
lo pagado al Estado de 253 a 363 millones (43% más). En Cerro Negro y Lindero la parte pagada bajó a la
mitad o menos justo en los años de precio récord. Cerro Vanguardia es la excepción.

Esto es lo que muestran los datos, con un límite importante: son pagos en efectivo de cada año. El
impuesto a las ganancias de un año se paga en buena parte al siguiente, así que lo que corresponde a las
ganancias de 2025 se va a ver recién en los pagos de 2026. Hay que volver a mirar cuando salgan.

**P28. Total pagado por las mineras que informan en Canadá, más Veladero.**

| Millones de dólares | 2021 | 2022 | 2023 | 2024 | 2025 |
|---|---|---|---|---|---|
| Oro, plata y zinc en producción | 154 | 408 | 412 | 379 | 623 |
| Litio | 8 | 32 | 87 | 105 | 52 |
| Proyectos y exploración | 9 | 11 | 11 | 20 | 23 |

No son todas las mineras del país. La baja del litio en 2025 puede ser un cambio de dueño (Olaroz pasó de
Allkem a Rio Tinto) y no un cambio en lo pagado; no lo verifiqué.

Como comprobación quise comparar Cerro Negro en ESTMA con los impuestos nacionales que SIACAM informa para
su empresa (Oroplata) en 2021-2023. Dan parecido en 2021 y 2022 y se separan en 2023, pero miden cosas
distintas (SIACAM incluye cargas sociales y no incluye regalías provinciales), así que no lo dejé como
control.

Van 28 preguntas y 57 controles, todos en verde.

## 19. Cuánto deja el litio: el caso Olaroz (14 de octubre de 2026)

En la base canadiense los pagos del litio están proyecto por proyecto, pero para medir qué parte queda
hace falta saber cuánto facturó cada uno. Lo encontré para Olaroz: Allkem, su dueña hasta 2024, publicaba
ingresos y margen por operación en la bolsa australiana, y los pagos en ESTMA los informaba con el mismo
ejercicio de julio a junio. Las otras operaciones de litio no tienen las dos cosas a la vez: Fénix era de
una empresa estadounidense que no informa en Canadá, y de Cauchari-Olaroz no encontré pagos.

**P29. Olaroz.**

| Ejercicio | Jul-2021 a jun-2022 | Jul-2022 a jun-2023 |
|---|---|---|
| Ingresos, millones de dólares | 293 | 592 |
| Margen operativo (EBITDA) | 220 (75%) | 475 (80%) |
| Pagado al Estado | 22,5 | 74,2 |
| como parte de los ingresos | 7,7% | 12,5% |
| como parte del margen | 10,2% | 15,6% |
| Precio de venta, dólares por tonelada | 23.398 | 43.981 |
| Precio de referencia en Asia | 41.854 | 64.195 |

Tres cosas:

- **El margen fue enorme**: 80 centavos de cada dólar vendido, antes de impuestos, en el pico.
- **Lo pagado al Estado en el ejercicio fue entre el 10% y el 16% de ese margen.** Como el impuesto a las
  ganancias se paga con atraso, en el semestre siguiente (julio a diciembre de 2023) Olaroz pagó otros 66
  millones. Sumando los dos, lo pagado por el ejercicio del pico ronda el 30% del margen. No puedo separar
  qué parte de esos 66 millones corresponde a cada período.
- **Las regalías fueron chicas**: 4,6 millones en el primer ejercicio y 15,9 en el segundo, entre 1,6% y
  2,7% de los ingresos. El tope legal es 3% del valor en boca de mina.

El precio de venta de Olaroz fue el 56% y el 69% de la referencia de Asia. Es la misma brecha que vi en
P05 para todo el país, ahora en una operación con nombre: no es una empresa que vendió a la mitad, es
cómo se vendía el litio por contrato en esos años. Lo que P21 mostró para Estados Unidos (la mitad que
Chile) sigue siendo un caso aparte.

Van 29 preguntas y 59 controles, todos en verde.

## 20. Cauchari-Olaroz: la más grande, sin ganancias (14 de octubre de 2026)

Cauchari-Olaroz no aparece en la base canadiense de pagos: su operadora, Minera Exar, es compartida
(Lithium Argentina 44,8%, Ganfeng 46,7%, JEMSE 8,5%) y ninguna de las dueñas la consolida. Pero Lithium
Argentina publica en su informe anual ante la SEC los estados contables de Minera Exar. Los leí en el
navegador para 2023, 2024 y 2025.

**P30. Cuánto vende y cuánto le queda.**

| Millones de dólares | 2023 | 2024 | 2025 |
|---|---|---|---|
| Ventas | 35 | 198 | 271 |
| Resultado bruto (ventas menos costo de producir) | 7 | 20 | 33 |
| Margen bruto | 19% | 10% | 12% |
| Costos financieros | 0 | -36 | -139 |
| Resultado final | 130 | -33 | -39 |
| Producción, toneladas | 6.000 | 25.400 | 35.100 |
| Precio implícito, dólares por tonelada | 5.754 | 7.783 | 7.734 |
| Referencia de Asia | 39.386 | 12.526 | 9.485 |

Lo que muestran los datos:

- **La operación más grande del país da pérdida.** El margen bruto es de 10% a 12%, contra el 80% de
  Olaroz en el pico. Con pérdidas no hay impuesto a las ganancias que pagar.
- **En 2025 los costos financieros (139 millones) cuadruplicaron el resultado bruto (33).** Según el mismo
  informe, buena parte de esa deuda son préstamos de los propios socios a través de Exar Capital, que
  Minera Exar tiene que devolver en dólares al tipo de cambio implícito del mercado.
- **Vende toda su producción a sus socios**: Ganfeng y, a través de Lithium Argentina, la tailandesa
  Bangchak.
- **El precio implícito fue el 62% de la referencia en 2024 y el 82% en 2025.** Es una aproximación
  (divido por toneladas producidas, no vendidas).
- **2023 fue el año de arranque** y su ganancia de 130 millones es contable (derivados), no de la operación.

Esto es lo que dicen los informes. Que una operación financiada por sus dueños les venda a ellos y les
pague intereses es una estructura que existe en muchos proyectos y no dice por sí sola que haya algo
irregular; lo que sí dice es que, con esa estructura y estos precios, el Estado no cobra impuesto a las
ganancias de la operación de litio más grande del país. Cobra regalías (3% en boca de mina) y JEMSE tiene
su 8,5%.

La comparación con Olaroz tiene un límite que hay que decir siempre: Olaroz está medida en el pico de
precios y Cauchari-Olaroz en la baja.

Van 30 preguntas y 59 controles, todos en verde.

## 21. Primer borrador de la página (14 de octubre de 2026)

Decidí que el tablero sea una página en HTML. La armé en `pagina/`:

- `plantilla.html` tiene el texto, el diseño y el código de los gráficos (sin bibliotecas externas).
- `scripts/exportar_pagina.py` corre una consulta por gráfico contra la base y mete los datos en la
  plantilla. Así la página siempre muestra los mismos números que las consultas.
- El resultado, `mineria-en-datos.html`, es un solo archivo que se abre sin conexión.

Tiene las tres historias, once gráficos y cuatro tablas. Cada gráfico tiene etiquetas al final de cada
línea, un recuadro con los valores al pasar el mouse y una tabla con los datos debajo. Los colores son
una paleta validada para personas con daltonismo, con versión para modo oscuro. Cada historia lleva sus
límites escritos al lado del dato.

La revisé en el navegador y corregí cinco cosas: un eje que cortaba los valores más altos, años que se
superponían en el eje, una cifra de empleo mal rotulada (era solo minería de metales, 2,6%; con canteras
es 3,6%), una tabla del litio que decía algo incorrecto para 2023, y una línea que unía años sin dato.

La página no está publicada todavía.

## 22. Un video corto y una frase corregida (14 de octubre de 2026)

Quise un video corto que explique la página. Lo armé con un script (`video/armar_video.py`):
saca una captura de cada parte de la página con Chrome sin ventana, le pone al lado el mensaje clave y
el texto de la narración, graba la narración con la voz en español de la Mac y une todo con ffmpeg. Son
diez escenas y unos dos minutos y medio. Para ffmpeg instalé el paquete de Python `imageio-ffmpeg`, que
lo trae incluido sin tocar el resto del sistema. La voz es de México: la Mac no trae una rioplatense.

Al escribir el guion corregí una frase que venía repitiendo desde P21: que Estados Unidos pagó por el
litio argentino "alrededor de la mitad" que por el chileno entre 2018 y 2023. Mirando año por año, fue
entre el 44% y el 86%; la mitad fue en 2019 y en 2022. Lo cambié en la página y en el video.

## 23. Cambio de formato: de página de análisis a notas (14 de octubre de 2026)

No me terminó de gustar la página: la encontré muy de análisis. Le pedí a Claude mirar Acero y Roca,
un medio minero de San Juan, que cuenta las cosas más en forma de crónica periodística.

Lo que tienen sus notas y la página no tenía: una sola historia por nota; un título que es una idea
("la eterna promesa del cobre"), no un tema; un recuadro "lo esencial en 10 segundos"; empresas,
lugares y fechas con nombre propio; intertítulos que cuentan; pocos gráficos y los números metidos en el
texto.

Armé una nota de prueba con la historia del oro en ese formato (`pagina/notas/oro.html`): tres gráficos
en lugar de cinco, el recorrido de Cerro Negro y de Veladero con sus dueños y sus fechas, y lo que se
paga al Estado. Para no duplicar código separé el estilo y los gráficos en archivos compartidos
(`pagina/estilo.css` y `pagina/graficos.js`) que el exportador mete en cada página.

Al escribirla corregí dos cosas que iba a afirmar sin respaldo: que Cerro Negro paró en 2020 "por la
pandemia" (el informe de Newmont solo dice que la puso en cuidado y mantenimiento) y que las regalías de
San Juan son "el 3% del valor" (son cerca del 3% de lo exportado; la ley fija 3% en boca de mina).

## 24. La nota del oro, contada con gráficos (14 de octubre de 2026)

El formato de nota me gustó, pero quería que la historia se contara más con imágenes que con párrafos.
Rehíce la nota del oro con Claude Code como asistente: cada sección es ahora un gráfico y dos o tres
líneas de texto.

| Pieza | Qué muestra |
|---|---|
| Dos cifras grandes | +147% el precio y −27% las onzas, entre 2019 y 2025 |
| Mapa | Cada mina con un círculo del tamaño de su producción: lleno para 2025, punteado para 2015 |
| Cascada | Cómo se pasa de 2.038 a 1.184 mil onzas: cuánto restó cada mina y cuánto sumaron las nuevas |
| Antes y después | Cerro Negro en 2018 y en 2025: ley, toneladas procesadas y onzas |
| Barras apiladas | Veladero: el precio de cada onza partido en costo total y margen |
| De cada 100 | Cuántos dólares de cada 100 producidos pagó al Estado cada mina en 2025 |
| Línea de tiempo | Diez años en ocho fechas |

Para el mapa bajé el contorno de las provincias del Instituto Geográfico Nacional y lo achiqué con un
script nuevo (`scripts/preparar_mapa.py`). El archivo trae la Ciudad de Buenos Aires ampliada y dibujada
sobre el mar, como un recuadro; la saqué porque en el mapa aparecía como un círculo en el océano.

En la cascada, "resto de las minas" es la diferencia entre el total del país y las minas que tienen
nombre en el gráfico. Las dos minas nuevas suman 171 mil onzas contra 1.025 mil que perdieron las
demás: compensan una sexta parte. Al escribirlo había puesto "una quinta parte" y lo corregí con la
cuenta.

También cambié cómo se dibujan todos los gráficos: antes se achicaban enteros para entrar en la pantalla
y en un celular los rótulos quedaban ilegibles. Ahora se dibujan al ancho real. Lo revisé en pantalla en
ancho de celular, de computadora y en modo oscuro.

## 25. Para qué es todo esto (14 de octubre de 2026)

La nota gráfica me gustó, pero no tanto. Le pedí a Claude que se alejara y mirara el proyecto con ojo
crítico. Lo que salió, y en lo que coincido:

- El título "el récord del oro es precio" no es nuevo: lo dicen la cámara minera y la Bolsa de Comercio
  de Rosario en su informe de 2025. Lo original lo estábamos dejando para el final: cuánto paga cada
  mina al Estado.
- A Cerro Negro le faltaba contexto que estaba en la prensa: en junio de 2023 Newmont anunció 540
  millones de dólares y más de 350 mil onzas por año desde 2024, y produjo 238 mil y 202 mil. En abril de
  2024 murieron dos trabajadores y la mina estuvo parada seis semanas.
- Pasamos mucho tiempo en la presentación (página, video, nota, nota gráfica) y poco en la sustancia.

Después definí el objetivo, que no estaba escrito: un proyecto interesante, que llame la atención y que
muestre que sé analizar datos apoyado en una IA. El trabajo con IA no se esconde, se muestra. Lo dejé
escrito en las instrucciones del proyecto.

Con ese objetivo, lo más valioso del proyecto es algo que estaba enterrado en esta bitácora: las veces que
algo que se dijo (casi siempre propuesto por la IA) estaba mal, y cómo se detectó. Lo pasé a una tabla,
`correccion_ia`, con 19 casos:

| Cómo se detectó | Casos |
|---|---|
| Volver a la fuente | 5 |
| Control automático | 3 |
| Cruce de fuentes | 3 |
| Yo (Francisco) | 3 |
| Revisión en pantalla | 2 |
| Rehacer la cuenta | 2 |
| Buscar más datos | 1 |

Los controles automáticos atraparon solo 3. La mayoría se detectó volviendo a leer la fuente o cruzando
con otra.

También armé `hecho_mina`: las fechas que explican la producción, cada una con su fuente, incluidas la
promesa de Newmont y el accidente. Confirmé la promesa en Bloomberg Línea (1 de junio de 2023) y el
accidente en el comunicado de Newmont (10 de abril de 2024). La fecha de la venta de la mitad de Veladero
a Shandong la tenía como "2017"; la precisé con el comunicado de Barrick: 30 de junio de 2017, por 960
millones de dólares.

Sumé cuatro controles: que las correcciones estén todas cargadas y numeradas sin saltos, que cada hecho
sea de una mina conocida, y que las inversiones del RIGI coincidan con el tablero oficial. Son 63 y cierran
todos.

## 26. La nota del oro, reordenada (14 de octubre de 2026)

Reescribí la nota con el objetivo nuevo. Ahora se llama "El oro bate récords. ¿Cuánto le queda al país?"
y abre con lo que no publica nadie: cuánto pagó cada mina al Estado de cada 100 dólares que produjo. El
récord por precio pasa a ser la explicación, citando que ya lo dijeron la cámara minera y la Bolsa de
Comercio de Rosario.

Orden nuevo:

| Sección | Pieza principal |
|---|---|
| Cuánto llega al Estado | De cada 100 dólares en 2025, y 2023 contra 2025 |
| Por qué | Veladero: costo y margen de cada onza |
| Cerro Negro | Producido contra lo prometido por Newmont, con el anuncio y el accidente marcados |
| Dónde se saca el oro | Mapa y cascada |
| Veinte años en doce fechas | Línea de tiempo que sale de la tabla `hecho_mina` |
| Cómo lo hice con una IA | Cifras del método, cómo se detectaron los 19 errores y cuatro ejemplos |

Dos consultas nuevas: P31 (Cerro Negro, lo prometido contra lo producido: 32% menos en 2024 y 42% menos
en 2025) y P32 (cómo se detectaron los errores).

Una cuenta que hice y conviene leer con cuidado: si a 2024 se le suman las seis semanas que la mina
estuvo parada, suponiendo que produce parejo todo el año, habría dado unas 270 mil onzas. Sigue lejos de
350 mil.

Al revisar la nota en pantalla vi que el gráfico mostraba 32 para Veladero en 2023 y el texto decía 31
(el dato es 31,5). Dejé 32 en los dos. También precisé cómo estaba escrita la corrección 9: lo que se
venía diciendo era que la caída se explicaba por minas que se agotan, no algo específico de San Juan.

Reconstruí la base desde cero: los 63 controles cierran.

## 27. Un README para quien llega al repositorio (17 de octubre de 2026)

Reescribí el README pensando en alguien que lo lee un minuto. Arriba: el link a la nota, tres hallazgos
(lo que llega al Estado del oro, la promesa de Cerro Negro y el litio barato a Estados Unidos) y una
tabla de qué tan firme es cada uno, con su límite al lado. Después, cómo trabajé con la IA, con la tabla
de cómo se detectaron los 19 errores y cuatro ejemplos. Siguen las tablas que armé a mano porque no
existían, las 32 preguntas con una respuesta de una línea, cómo está hecho y cómo reproducirlo.

Seguí el formato del README de Vaca Muerta, que ya tenía la tabla de "qué tan firme es cada cosa". Lo
nuevo es la sección sobre la IA.

## 28. La nota del litio (17 de octubre de 2026)

Armé la segunda nota con el mismo formato: "El litio argentino: tres cuartos para China y a mitad de
precio para Estados Unidos". Antes de escribirla miré qué se publicó sobre el litio esta semana y lo
probé contra los datos (P33):

| Lo que se publicó | Publicado | Mis datos |
|---|---|---|
| Exportado de enero a agosto de 2026 (Acero y Roca, 16-10) | 1.467 millones | 1.467 |
| Variación contra 2025 | +190,5% | +190,5% |
| Exportado en 2025 (informe de la Secretaría, según El Pregón Minero) | 914 millones | 915 |
| China, parte de 2025 (mismo informe) | 81,1% | 74,9% |

Los tres primeros coinciden, pero salen de la misma Secretaría, así que no es una validación
independiente. El 81,1% no cierra con el archivo de destinos de la propia Secretaría. No encontré el
informe completo para ver cómo lo calcula; puede ser en toneladas. Lo dejé dicho en la nota.

La nota tiene tres partes: a quién se lo vendemos (China, con el acuerdo marco de minerales críticos que
Argentina y Estados Unidos firmaron en febrero de 2026), a qué precio se lo vendimos a Estados Unidos
(entre 44% y 86% de lo que pagó por el chileno entre 2018 y 2023) y cuánto queda en el país (Olaroz en el
pico, con 80 centavos de margen por dólar vendido, contra Cauchari-Olaroz en 2025, que termina en
pérdida). Para Cauchari-Olaroz hice una cascada que va de las ventas al resultado; "todo lo demás" es la
diferencia entre el resultado y las líneas que tengo, y así está rotulado.

Verifiqué dos hechos para la tabla `hecho_mina`: la denuncia de la Aduana a Livent (Bloomberg Línea,
julio de 2022) y el acuerdo con Estados Unidos (Energiminas, 5 de febrero de 2026). El texto del acuerdo
no menciona el litio ni da prioridad a Estados Unidos; eso último lo dijo el canciller en declaraciones,
así que en la nota solo digo que se firmó. Encontré una nota de El Ancasti (junio de 2023) que dice que
Livent pagó la multa, pero el mismo artículo dice que el caso se apeló; como no cierra, no lo usé.

La tabla de hechos ahora admite `Argentina` como "mina" para hechos de todo el país, y el control que
verifica que cada hecho sea de una mina conocida los deja pasar.

## 29. La nota de San Juan (17 de octubre de 2026)

Tercera nota: "San Juan: lo que dejaron veinte años de oro y lo que promete el cobre". Junta lo que ya
tenía (exportaciones, empleo y salarios de la minería, regalías, RIGI y el antecedente de Catamarca) con
una pregunta nueva que salió de leer la prensa de esta semana.

Ámbito publicó el 25 de septiembre las cifras del primer Reporte de Sostenibilidad de Vicuña: 2.576
trabajadores de contratistas en 2025, 80% sanjuaninos, y 580 proveedores. Quise ver si ese empleo aparece
en las estadísticas oficiales (P34):

| Puestos registrados | 2023 | 2024 | 2025 |
|---|---|---|---|
| Departamento Iglesia, todos los sectores | 3.724 | 3.666 | 3.634 |

Iglesia, donde están Vicuña y Veladero, no creció. Los trabajadores se cuentan donde los declara la
empresa, y los contratistas los anotan donde tienen la sede. En la provincia sí crecieron, de enero de
2025 a enero de 2026, algunas ramas de obra y servicios: movimiento de suelos (+22%), minas y canteras
n.c.p. (+24%), servicios empresariales n.c.p. (+10%). No puedo saber cuánto de eso es por el cobre, y así
lo dice la nota: es una señal, no una medida. La conclusión es que con las estadísticas oficiales no se
puede medir el empleo que genera el cobre; hoy la única cifra es la de la empresa.

En la nota corregí antes de publicar una frase que atribuía el 3,3% a 3,8% del empleo a la minería de
metales: ese rango suma las canteras.

## 30. La portada (17 de octubre de 2026)

Armé una portada (`pagina/index.html`) que presenta las tres notas con la pregunta que las une: cuánto del
récord minero le queda al país. Cada nota tiene una tarjeta con su título, tres líneas y un gráfico chico
(lo que pagó Veladero de cada 100 dólares, la barra de compradores del litio, el empleo de hoy contra el
declarado en el RIGI). Abajo van el método con IA, con el gráfico de cómo se detectaron los 19 errores, y
una lista de lo que todavía no se sabe. Las notas tienen un link de vuelta a la portada.

La página larga del principio (`mineria-en-datos.html`) sigue en el repositorio, pero la portada no la
enlaza: las notas la reemplazan.

Después decidí borrar la página larga: las notas la reemplazan y no quería que quedara una versión vieja
dando vueltas. Saqué también las tres consultas del exportador que solo usaba ella. Sigue estando en el
historial de git.

Borré también el script del video (`video/armar_video.py`), que filmaba la página larga y ya no podía
funcionar. El video que armé con él quedó en mi computadora, fuera del repositorio.

## 31. Versión pública (17 de octubre de 2026)

Subí el proyecto a un repositorio privado en GitHub (`mineria-argentina`) y armé una versión pública
aparte. Decidí publicar todo menos el archivo de instrucciones para la IA, que tiene datos personales, y
que la versión pública arranque con un solo commit, sin el historial de idas y vueltas, que queda en el
privado.

Antes de armarla revisé que no quedaran datos personales en lo público y pasé a primera persona unas diez
frases de esta bitácora que hablaban de mí en tercera persona.
La versión pública quedó en `FTornello/mineria-argentina-en-datos`. Para actualizarla dejé un script,
`scripts/armar_publico.sh`, que arma la rama `publicar` con todo lo de `main` menos lo privado, como un
commit nuevo. No sube nada solo: publicar sigue siendo un paso aparte.

Activé GitHub Pages en el repositorio público. La portada quedó en
https://ftornello.github.io/mineria-argentina-en-datos/pagina/ y la revisé en el navegador: carga, dibuja
los gráficos y los links entre las notas funcionan.

## 32. Otro encuadre para las notas (17 de octubre de 2026)

Me plantearon un riesgo: si postulo a mineras o a sus contratistas, los títulos de las notas se podían
leer como de denuncia ("la mina que más cayó es la que había prometido crecer", "a mitad de precio para
Estados Unidos", "no paga impuesto a las ganancias"). Cada frase era cierta y tenía fuente, pero juntas
armaban una línea editorial.

Revisándolo apareció algo más importante: el hallazgo principal del oro ("la parte que llega al Estado se
achicó") se apoya en pagos en efectivo, y el impuesto a las ganancias del récord de 2025 se paga en
2026. En dólares, Veladero pagó en 2025 más que nunca. El título presentaba como conclusión algo que
todavía no se puede saber.

Cambié títulos, bajadas y algunas frases en las tres notas, la portada y el README, sin tocar ningún
número:

| Antes | Ahora |
|---|---|
| ¿Cuánto del récord minero le queda al país? | El récord minero argentino, mina por mina |
| El oro bate récords. ¿Cuánto le queda al país? | Precio récord del oro: cuánto aporta cada mina y qué falta saber |
| Cerro Negro: lo prometido y lo producido | Cerro Negro: el plan de 2023 y la producción real |
| Tres cuartos para China y a mitad de precio para Estados Unidos | Litio: a quién se lo vende Argentina, a qué precio y cuánto queda en el país |
| Lo que promete el cobre | Lo que proyecta el cobre |

Lo de los pagos del oro quedó como pregunta abierta hasta que salgan los datos de 2026.


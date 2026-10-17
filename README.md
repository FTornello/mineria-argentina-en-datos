# Minería en Argentina: ¿cuánto del récord le queda al país?

Análisis en SQL de la minería argentina con fuentes públicas e informes de las empresas, hecho con una IA (Claude Code) como asistente. 34 preguntas, 63 controles automáticos y 19 errores detectados y corregidos en el camino, todos registrados.

**[Ver la portada publicada](https://ftornello.github.io/mineria-argentina-en-datos/pagina/)** · **[Portada](pagina/index.html)** · **[La nota del oro](pagina/notas/oro.html)** · **[La del litio](pagina/notas/litio.html)** · **[La de San Juan](pagina/notas/san-juan.html)** · [Cómo lo hice con una IA](#cómo-lo-hice-con-una-ia) · [Las 34 preguntas](#las-34-preguntas)

## Tres hallazgos

**1. El oro bate récords, pero la parte que llega al Estado se achicó.** En 2025 la minería exportó 6.074 millones de dólares, el máximo de la serie, y dos de cada tres son oro. El récord es de precio: la onza subió 147% desde 2019 y la producción bajó 27%. En tres de las cuatro minas de oro de las que hay datos de pagos, lo pagado al Estado fue una parte menor de lo producido justo en los años de precio récord. Veladero pagó 32 dólares de cada 100 producidos en 2023 y 23 en 2025; Cerro Negro, 14 y 8; Lindero, 9 y 3. *(Preguntas 3, 25 y 27)*

**2. La mina que más cayó es la que había prometido crecer.** En junio de 2023 Newmont anunció 540 millones de dólares para Cerro Negro, en Santa Cruz, y más de 350 mil onzas por año desde 2024. Produjo 238 mil en 2024 y 202 mil en 2025. Cada tonelada de mineral trae hoy 8,3 gramos de oro; en 2018 traía 13,9. *(23, 24 y 31)*

**3. El litio argentino se vendió barato a Estados Unidos.** Entre 2018 y 2023 Estados Unidos pagó por el litio argentino entre el 44% y el 86% de lo que pagó por el chileno, según su propia aduana. Si hubiera pagado lo mismo, se habrían exportado 222 millones de dólares más, y el Estado habría cobrado entre 10 y 17 millones más (con los derechos de exportación de hoy, y sumando una regalía de 3%). *(9, 21 y 22)*

### Qué tan firme es cada cosa

| Lo que digo | Cómo está respaldado | El límite |
|---|---|---|
| El récord del oro es precio | Tres medidas del volumen; dos coinciden (P04). Lo mismo dicen la cámara minera y la Bolsa de Comercio de Rosario | No es un hallazgo nuevo |
| La parte que llega al Estado bajó | Informe de Barrick para Veladero y base canadiense ESTMA para las demás, mina por mina | El impuesto a las ganancias de 2025 se paga en 2026: hay que volver a mirar cuando salgan esos pagos |
| Cerro Negro no llegó a lo prometido | Producción informada por Newmont; promesa citada por Bloomberg Línea | No encontré el comunicado original de Newmont con la cifra. En 2024 la mina estuvo parada seis semanas por un accidente fatal |
| El litio se vendió barato a EE.UU. | Aduana de Estados Unidos (UN Comtrade), comparando el mismo producto desde Chile | Es un ejercicio: supone que el precio chileno era el correcto |

## Cómo lo hice con una IA

Trabajé con Claude Code, una IA que escribe código. Buscó fuentes, bajó los datos, escribió las consultas y armó la página. Yo marqué el rumbo, revisé lo que hacía y decidí qué contar.

La IA se equivoca. Cada vez que algo que se dijo resultó estar mal quedó registrado en la tabla [`correccion_ia`](data/correcciones_ia.csv): qué se dijo, qué era y cómo se detectó.

| Cómo se detectó | Errores |
|---|---|
| Volver a leer la fuente original | 5 |
| Cruzar con otra fuente | 3 |
| Un control automático | 3 |
| Yo | 3 |
| Revisar la página en pantalla | 2 |
| Rehacer la cuenta | 2 |
| Buscar más datos | 1 |

Algunos ejemplos:

- **"El litio exportado en 2022 fue de 207 millones de dólares."** Fueron 695. El archivo mensual de la Secretaría de Minería pone lo que está bajo secreto estadístico en un grupo "Otro". Se detectó cruzando con los totales anuales. *(Error 5)*
- **"Cerro Negro paró en 2020 por la pandemia."** El informe de Newmont solo dice que la puso en cuidado y mantenimiento, sin dar la causa. *(Error 14)*
- **El primer panorama de temas daba por abiertos la reforma de la Ley de Glaciares y la llegada del RIGI.** Ya estaban resueltos: la IA había leído notas de marzo a junio. Lo marqué yo, y lo rehicimos con las portadas de esa semana. *(Error 6)*
- **"Estados Unidos pagó la mitad que a Chile."** Fue entre 44% y 86%, según el año. Se detectó rehaciendo la cuenta año por año. *(Error 13)*

Lo que me llevo: los controles automáticos atraparon solo 3 de los 19. La mayoría apareció al volver a la fuente o al cruzarla con otra.

## Lo que no existía y armé a mano

No hay datos públicos de producción mina por mina. Los armé a partir de los informes anuales de las empresas:

| Tabla | Qué tiene | De dónde |
|---|---|---|
| `produccion_mina` | Onzas de oro por mina y año, 2011 a 2025; cubre el 92% del país en 2025 | Informes de Barrick, Goldcorp, Newmont, AngloGold Ashanti, Fortuna, Yamana, Pan American y Hochschild |
| `operacion_mina` | Ley, toneladas procesadas, recuperación y costo por onza | Los mismos informes |
| `pago_gobierno` | Lo que cada minera pagó a los gobiernos argentinos, proyecto por proyecto | Base ESTMA de Canadá |
| `resultado_operacion` | Ventas, margen y resultado de Olaroz y Cauchari-Olaroz | Allkem (bolsa australiana) y Lithium Argentina (SEC) |
| `hecho_mina` | Inicios, cierres, cambios de dueño, accidentes y promesas, cada uno con su fuente | Comunicados y prensa |

## Las 34 preguntas

| # | Pregunta | Respuesta en una línea |
|---|---|---|
| [1](sql/analisis/p01_cuanto_exporta_la_mineria.sql) | ¿Cuánto exporta la minería? | 6.074 millones de dólares en 2025, el máximo; oro 67%, litio 15% |
| [2](sql/analisis/p02_el_record_del_primer_semestre.sql) | ¿Lo que dijo la prensa del primer semestre de 2026 es cierto? | Sí: 4.799 millones contra 4.742 publicados; +76% contra +75% |
| [3](sql/analisis/p03_oro_precio_o_produccion.sql) | El oro exportado casi se duplicó: ¿precio o producción? | Precio: +147%. La producción bajó 27% |
| [4](sql/analisis/p04_oro_dos_caminos.sql) | ¿Las fuentes coinciden sobre la caída? | Dos de tres medidas coinciden (unos 40%); el índice oficial de doré exagera |
| [5](sql/analisis/p05_litio_precio_o_produccion.sql) | ¿Y el litio? | Al revés: la producción se triplicó y el valor por tonelada cayó |
| [6](sql/analisis/p06_que_pasa_en_2026.sql) | ¿Sigue en 2026? | Sí: oro −2% en volumen y +44% en dólares; litio +44% en volumen |
| [7](sql/analisis/p07_a_quien_le_vendemos_el_litio.sql) | ¿A quién le vendemos el litio? | China compró el 75% en 2025; en 2012 compraba el 20% y EE.UU. el 59% |
| [8](sql/analisis/p08_litio_que_dicen_los_compradores.sql) | ¿Los compradores lo confirman? | Sí, pero China declara más de lo que Argentina declara venderle. No sé por qué |
| [9](sql/analisis/p09_litio_a_que_precio_llega.sql) | ¿Todos pagan lo mismo? | No: en 2022 EE.UU. pagó una fracción de lo que pagó Japón |
| [10](sql/analisis/p10_litio_china_mes_a_mes.sql) | ¿China paga el precio de referencia? | Con atraso: 29% de la referencia a principios de 2022, a la par en 2024 |
| [11](sql/analisis/p11_de_quien_son_los_proyectos_de_litio.sql) | ¿De quién son los proyectos de litio? | De los siete en producción, tres son de empresas chinas; ninguno de EE.UU. |
| [12](sql/analisis/p12_san_juan_veinte_anios_de_oro.sql) | ¿Cómo fueron veinte años de oro en San Juan? | Exportaciones de 26 a 1.759 millones; el empleo metalífero llegó a 2.732 en 2017 |
| [13](sql/analisis/p13_cuanto_pesa_la_mineria_en_el_empleo.sql) | ¿Cuánto pesa en el empleo de San Juan? | Entre 3,3% y 3,8% del empleo privado registrado |
| [14](sql/analisis/p14_cuanto_mas_paga_la_mineria.sql) | ¿Cuánto más paga la minería? | 5,3 veces el resto del empleo privado de la provincia |
| [15](sql/analisis/p15_iglesia_el_departamento_de_veladero.sql) | ¿Se derrama en Iglesia, donde está Veladero? | Pagan más los servicios y la construcción (mi lectura: los contratistas de la mina); el comercio, apenas 15% más |
| [16](sql/analisis/p16_cuanto_paga_veladero_en_impuestos.sql) | ¿Cuánto paga Veladero de impuestos nacionales? | Entre 103 y 149 millones por año (2019-2023) |
| [17](sql/analisis/p17_lo_que_promete_el_rigi_en_san_juan.sql) | ¿Cuánto promete el RIGI en San Juan? | 44.639 empleos y 13.510 millones; hoy la minería de metales tiene 2.264 puestos |
| [18](sql/analisis/p18_cuando_llega_la_plata_del_cobre.sql) | ¿Cuándo llega la plata del cobre? | A fin de 2026, el 11%; la mitad recién en 2028 |
| [19](sql/analisis/p19_que_pasa_cuando_cierra_una_mina.sql) | ¿Qué pasó en Catamarca cuando cerró Alumbrera? | Exportaciones de 2.024 millones (2007) a 99 (2020); después vino el litio |
| [20](sql/analisis/p20_cuanto_cobra_san_juan_de_regalias.sql) | ¿Cuánto cobra San Juan de regalías? | 49 millones en 2025, cerca del 3% de lo exportado; coincide con la ley |
| [21](sql/analisis/p21_litio_eeuu_argentina_contra_chile.sql) | ¿EE.UU. le pagó igual de poco a Chile? | No: al argentino le pagó entre 44% y 86% del precio chileno |
| [22](sql/analisis/p22_cuanto_valor_falto_en_el_litio_a_eeuu.sql) | ¿Cuánto valor faltó? | 222 millones en seis años; entre 10 y 17 millones para el Estado |
| [23](sql/analisis/p23_de_que_minas_viene_la_caida_del_oro.sql) | ¿De qué minas viene la caída del oro? | Sobre todo de Cerro Negro (−305 mil onzas desde 2015), del cierre de Alumbrera y de Veladero |
| [24](sql/analisis/p24_por_que_cayo_cerro_negro.sql) | ¿Por qué cayó Cerro Negro? | Mineral más pobre (13,9 a 8,3 g/t) y menos toneladas procesadas |
| [25](sql/analisis/p25_cuanto_margen_deja_el_record.sql) | ¿Cuánto margen deja el récord? | En Veladero, casi 2.000 dólares por onza en 2025; unos 900 millones en el año |
| [26](sql/analisis/p26_gualcamayo_de_la_cima_al_rigi.sql) | ¿Qué pasó con Gualcamayo? | De 181 mil onzas (2015) a perder plata por onza; en 2026 entró al RIGI |
| [27](sql/analisis/p27_cuanto_del_valor_queda_en_impuestos.sql) | ¿Qué parte de lo producido se paga al Estado? | Bajó en tres de las cuatro minas con datos en los años de precio récord |
| [28](sql/analisis/p28_pagos_al_estado_oro_y_litio.sql) | ¿Cuánto pagan en total las mineras que informan en Canadá? | 623 millones el oro y la plata en 2025 (con Veladero); 52 el litio |
| [29](sql/analisis/p29_cuanto_deja_olaroz.sql) | ¿Cuánto deja Olaroz? | En el pico, 80 centavos de margen por dólar vendido |
| [30](sql/analisis/p30_cauchari_olaroz_vende_a_sus_socios.sql) | ¿Y Cauchari-Olaroz, la más grande? | Le vende a sus socios, gana poco, paga intereses y da pérdida: no paga ganancias |
| [31](sql/analisis/p31_cerro_negro_lo_prometido.sql) | ¿Cerro Negro cumplió lo prometido? | No: 32% menos en 2024 y 42% menos en 2025 |
| [32](sql/analisis/p32_como_se_detectaron_los_errores.sql) | ¿Cómo se detectaron los errores? | Volviendo a la fuente (5), cruzando fuentes (3), controles (3) y yo (3), entre otros |
| [33](sql/analisis/p33_litio_la_prensa_contra_los_datos.sql) | ¿Lo que se publicó del litio en octubre de 2026 cierra? | Las exportaciones de 2025 y de 2026 sí; el 81,1% de China no: el archivo de la misma Secretaría da 74,9% |
| [34](sql/analisis/p34_se_ve_el_empleo_del_cobre.sql) | ¿Se ve en las estadísticas el empleo que ya genera el cobre? | No: Vicuña informa 2.576 trabajadores de contratistas en 2025 y el empleo registrado de Iglesia no creció. Se cuentan donde los declara la empresa |

El detalle de cada respuesta, con sus límites, está en la [bitácora](BITACORA.md).

## Cómo está hecho

PostgreSQL en dos capas: `raw` guarda cada archivo tal cual se publica y `mineria` es el modelo limpio. Un script rearma todo desde cero y corre 63 controles; si alguno no cierra, la reconstrucción se frena. Varios controles comparan dos fuentes que no dependen una de la otra: el oro que Argentina declara exportar contra el que Suiza, Estados Unidos, India y Canadá declaran importar; las regalías que cobra San Juan contra lo que exporta su minería; la producción de una mina contra toneladas por ley por recuperación.

- [BITACORA.md](BITACORA.md): qué se decidió, por qué y qué se descartó, paso por paso.
- [DICCIONARIO.md](DICCIONARIO.md): qué significa cada tabla y cada columna.
- [data/FUENTES.csv](data/FUENTES.csv): cada archivo descargado, con fecha y huella.
- [docs/relevamiento_fuentes.md](docs/relevamiento_fuentes.md): qué fuentes se revisaron y qué trae cada una.
- [sql/](sql/): la carga, el modelo y los controles. [sql/analisis/](sql/analisis/): una consulta comentada por pregunta.

## Cómo reproducirlo

Requiere PostgreSQL 17 y Python 3 con los paquetes de `requirements.txt`.

```bash
createdb mineria
./scripts/descargar_datos.sh         # baja unos 310 MB a data/raw/
./scripts/reconstruir.sh             # arma la base y corre los controles
python3 scripts/exportar_pagina.py   # arma la portada y las notas en pagina/ con los datos de la base
```

Los informes de algunas empresas no se pueden bajar de forma automática (la SEC bloquea las descargas sin identificación); sus números están copiados a mano en `data/`, con la fuente y la página de cada uno.

## Fuentes

INDEC (comercio exterior por producto y país), Secretaría de Minería de la Nación (SIACAM: exportaciones, empleo, cartera de proyectos, precios), UN Comtrade (lo que declaran los países compradores), Observatorio de Empleo y Dinámica Empresarial del Ministerio de Trabajo (empleo y salarios por rama y departamento), tablero del RIGI del Ministerio de Economía, Ministerio de Hacienda de San Juan (regalías), Banco Nación y Banco de Canadá (tipo de cambio), Cámara Argentina de Empresarios Mineros (producción total), Natural Resources Canada (ESTMA), Instituto Geográfico Nacional (mapa) e informes anuales de las empresas.

Francisco Tornello, 2026. Trabajé con Claude Code como asistente.

# Mining in Argentina: the record, mine by mine

*[Versión en español](README.md)*

A SQL analysis of Argentine mining built from public sources and company reports, with an AI (Claude Code) as assistant. 34 questions, 63 automated checks and 19 errors caught and corrected along the way, all on record.

**[Published front page](https://ftornello.github.io/mineria-argentina-en-datos/pagina/)** (in Spanish) · [How I built it with an AI](#how-i-built-it-with-an-ai) · [What did not exist and I built by hand](#what-did-not-exist-and-i-built-by-hand) · [The 34 questions](#the-34-questions)

## Three findings

**1. The gold record is about price, and each mine's contribution is not yet fully visible.** In 2025 mining exports reached 6,074 million dollars, the highest in the series, and two out of three dollars are gold. The record is about price: the ounce rose 147% since 2019 while output fell 27%. What was paid to the State during the year rose, but less than the value produced: Veladero paid 363 million in 2025, its highest, which is 23 dollars of every 100 produced vs. 32 in 2023. Income tax on the record year is paid in 2026, so the full comparison is still pending. *(Questions 3, 25 and 27)*

**2. Cerro Negro: the 2023 plan and actual output.** In June 2023, 540 million dollars were announced for Cerro Negro, in Santa Cruz, with the goal of exceeding 350 thousand ounces per year from 2024. It produced 238 thousand in 2024 and 202 thousand in 2025. Each tonne of ore now carries 8.3 grams of gold; in 2018 it carried 13.9. *(23, 24 and 31)*

**3. The price of Argentine lithium depends on the buyer.** Between 2018 and 2023 the United States paid for Argentine lithium between 44% and 86% of what it paid for Chilean lithium, according to its own customs data. As an exercise: had it paid the same, exports would have been 222 million dollars higher, and the State would have collected between 10 and 17 million more (with today's export duties, plus a 3% royalty). *(9, 21 and 22)*

### How solid each claim is

| What I say | How it is backed | The limit |
|---|---|---|
| The gold record is about price | Three volume measures; two agree (Q4). The mining chamber and the Rosario Stock Exchange say the same | Not a new finding |
| Payments grew less than the value produced | Barrick's report for Veladero and Canada's ESTMA database for the rest, mine by mine | 2025 income tax is paid in 2026: needs a second look when those payments come out |
| Cerro Negro produced less than the 2023 goal | Output reported by Newmont; goal cited by Bloomberg Línea | The goal was published by Bloomberg Línea; I did not find the original release. In 2024 the mine was stopped for six weeks after a fatal accident |
| The U.S. paid less for Argentine than for Chilean lithium | U.S. customs (UN Comtrade), comparing the same product from Chile | Customs data do not say which company sold or under what contract. The "missing value" estimate assumes the Chilean price was the right one |

## How I built it with an AI

I worked with Claude Code, an AI that writes code. It looked for sources, downloaded the data, wrote the queries and built the page. I set the direction, reviewed what it did and decided what to tell.

The AI makes mistakes. Every time something that had been stated turned out to be wrong, it was recorded in the [`correccion_ia`](data/correcciones_ia.csv) table: what was said, what was true and how it was caught.

| How it was caught | Errors |
|---|---|
| Re-reading the original source | 5 |
| Cross-checking with another source | 3 |
| An automated check | 3 |
| Me | 3 |
| Reviewing the page on screen | 2 |
| Redoing the calculation | 2 |
| Looking for more data | 1 |

Some examples:

- **"Lithium exports in 2022 were 207 million dollars."** They were 695. The Mining Secretariat's monthly file puts everything under statistical confidentiality in an "Other" group. Caught by cross-checking against the annual totals. *(Error 5)*
- **"Cerro Negro stopped in 2020 because of the pandemic."** Newmont's report only says it was placed on care and maintenance, without giving a reason. *(Error 14)*
- **The first overview of current topics treated the Glaciers Law reform and the arrival of the RIGI investment regime as open issues.** They were already settled: the AI had read news from March to June. I flagged it, and we redid it with that week's front pages. *(Error 6)*
- **"The United States paid half of what it paid Chile."** It was between 44% and 86%, depending on the year. Caught by redoing the calculation year by year. *(Error 13)*

What I take away: automated checks caught only 3 of the 19. Most surfaced when going back to the source or cross-checking it with another.

## What did not exist and I built by hand

There is no public mine-by-mine production data. I built it from the companies' annual reports:

| Table | What it holds | Source |
|---|---|---|
| `produccion_mina` | Gold ounces by mine and year, 2011 to 2025; covers 92% of national output in 2025 | Reports from Barrick, Goldcorp, Newmont, AngloGold Ashanti, Fortuna, Yamana, Pan American and Hochschild |
| `operacion_mina` | Grade, tonnes processed, recovery and cost per ounce | The same reports |
| `pago_gobierno` | What each miner paid to Argentine governments, project by project | Canada's ESTMA database |
| `resultado_operacion` | Sales, margin and results of Olaroz and Cauchari-Olaroz | Allkem (Australian exchange) and Lithium Argentina (SEC) |
| `hecho_mina` | Start-ups, closures, ownership changes, accidents and announcements, each with its source | Releases and press |

## The 34 questions

| # | Question | One-line answer |
|---|---|---|
| [1](sql/analisis/p01_cuanto_exporta_la_mineria.sql) | How much does mining export? | 6,074 million dollars in 2025, the highest; gold 67%, lithium 15% |
| [2](sql/analisis/p02_el_record_del_primer_semestre.sql) | Is what the press reported for the first half of 2026 right? | Yes: 4,799 million vs. 4,742 published; +76% vs. +75% |
| [3](sql/analisis/p03_oro_precio_o_produccion.sql) | Gold exports almost doubled: price or output? | Price: +147%. Output fell 27% |
| [4](sql/analisis/p04_oro_dos_caminos.sql) | Do sources agree on the decline? | Two of three measures agree (about 40%); the official doré index overstates it |
| [5](sql/analisis/p05_litio_precio_o_produccion.sql) | And lithium? | The opposite: output tripled and value per tonne fell |
| [6](sql/analisis/p06_que_pasa_en_2026.sql) | Does it continue in 2026? | Yes: gold −2% in volume and +44% in dollars; lithium +44% in volume |
| [7](sql/analisis/p07_a_quien_le_vendemos_el_litio.sql) | Who buys our lithium? | China bought 75% in 2025; in 2012 it bought 20% and the U.S. 59% |
| [8](sql/analisis/p08_litio_que_dicen_los_compradores.sql) | Do buyers confirm it? | Yes, but China declares more than Argentina declares selling to it. I don't know why |
| [9](sql/analisis/p09_litio_a_que_precio_llega.sql) | Does everyone pay the same? | No: in 2022 the U.S. paid a fraction of what Japan paid |
| [10](sql/analisis/p10_litio_china_mes_a_mes.sql) | Does China pay the benchmark price? | With a lag: 29% of the benchmark in early 2022, on par in 2024 |
| [11](sql/analisis/p11_de_quien_son_los_proyectos_de_litio.sql) | Who owns the lithium projects? | Of the seven in production, three belong to Chinese companies; none to U.S. ones |
| [12](sql/analisis/p12_san_juan_veinte_anios_de_oro.sql) | What did twenty years of gold look like in San Juan? | Exports from 26 to 1,759 million; metal-mining employment peaked at 2,732 in 2017 |
| [13](sql/analisis/p13_cuanto_pesa_la_mineria_en_el_empleo.sql) | How much of San Juan's employment is mining? | Between 3.3% and 3.8% of registered private employment |
| [14](sql/analisis/p14_cuanto_mas_paga_la_mineria.sql) | How much more does mining pay? | 5.3 times the rest of the province's private employment |
| [15](sql/analisis/p15_iglesia_el_departamento_de_veladero.sql) | Does it spill over in Iglesia, where Veladero is? | Services and construction pay more (my reading: the mine's contractors); retail, barely 15% more |
| [16](sql/analisis/p16_cuanto_paga_veladero_en_impuestos.sql) | How much does Veladero pay in national taxes? | Between 103 and 149 million per year (2019–2023) |
| [17](sql/analisis/p17_lo_que_promete_el_rigi_en_san_juan.sql) | What does the RIGI project for San Juan? | 44,639 jobs and 13,510 million; metal mining has 2,264 jobs today |
| [18](sql/analisis/p18_cuando_llega_la_plata_del_cobre.sql) | When does the copper money arrive? | 11% by end of 2026; half only in 2028 |
| [19](sql/analisis/p19_que_pasa_cuando_cierra_una_mina.sql) | What happened in Catamarca when Alumbrera closed? | Exports from 2,024 million (2007) to 99 (2020); then lithium came |
| [20](sql/analisis/p20_cuanto_cobra_san_juan_de_regalias.sql) | How much does San Juan collect in royalties? | 49 million in 2025, about 3% of exports; consistent with the law |
| [21](sql/analisis/p21_litio_eeuu_argentina_contra_chile.sql) | Did the U.S. pay Chile as little? | No: it paid between 44% and 86% of the Chilean price for Argentine lithium |
| [22](sql/analisis/p22_cuanto_valor_falto_en_el_litio_a_eeuu.sql) | How much value was missing? | 222 million over six years; between 10 and 17 million for the State |
| [23](sql/analisis/p23_de_que_minas_viene_la_caida_del_oro.sql) | Which mines explain the gold decline? | Mainly Cerro Negro (−305 thousand ounces since 2015), the Alumbrera closure and Veladero |
| [24](sql/analisis/p24_por_que_cayo_cerro_negro.sql) | Why did Cerro Negro fall? | Poorer ore (13.9 to 8.3 g/t) and fewer tonnes processed |
| [25](sql/analisis/p25_cuanto_margen_deja_el_record.sql) | What margin does the record leave? | At Veladero, almost 2,000 dollars per ounce in 2025; about 900 million in the year |
| [26](sql/analisis/p26_gualcamayo_de_la_cima_al_rigi.sql) | What happened to Gualcamayo? | From 181 thousand ounces (2015) to losing money per ounce; entered the RIGI in 2026 |
| [27](sql/analisis/p27_cuanto_del_valor_queda_en_impuestos.sql) | What share of output value is paid to the State? | It fell at three of the four mines with data during the record-price years |
| [28](sql/analisis/p28_pagos_al_estado_oro_y_litio.sql) | How much do miners reporting in Canada pay in total? | 623 million for gold and silver in 2025 (with Veladero); 52 for lithium |
| [29](sql/analisis/p29_cuanto_deja_olaroz.sql) | How much does Olaroz make? | At the peak, 80 cents of margin per dollar sold |
| [30](sql/analisis/p30_cauchari_olaroz_vende_a_sus_socios.sql) | And Cauchari-Olaroz, the largest? | It sells to its partners, has a 10%–12% gross margin and high financial costs; closed 2024 and 2025 with a loss |
| [31](sql/analisis/p31_cerro_negro_lo_prometido.sql) | Did Cerro Negro reach the goal announced in 2023? | No: it produced 32% less in 2024 and 42% less in 2025 |
| [32](sql/analisis/p32_como_se_detectaron_los_errores.sql) | How were the errors caught? | Going back to the source (5), cross-checking sources (3), checks (3) and me (3), among others |
| [33](sql/analisis/p33_litio_la_prensa_contra_los_datos.sql) | Do the lithium figures published in October 2026 add up? | 2025 and 2026 exports do; China's 81.1% does not: the same Secretariat's file gives 74.9% |
| [34](sql/analisis/p34_se_ve_el_empleo_del_cobre.sql) | Do statistics show the jobs copper already creates? | No: Vicuña reports 2,576 contractor workers in 2025 and Iglesia's registered employment did not grow. They are counted where the company declares them |

Each answer, with its limits, is detailed in the [log](BITACORA.md) (in Spanish).

## How it is built

PostgreSQL in two layers: `raw` keeps each file exactly as published and `mineria` is the clean model. A script rebuilds everything from scratch and runs 63 checks; if any fails, the rebuild stops. Several checks compare two sources that do not depend on each other: the gold Argentina declares exporting vs. what Switzerland, the United States, India and Canada declare importing; the royalties San Juan collects vs. what its mining exports; a mine's output vs. tonnes × grade × recovery.

- [BITACORA.md](BITACORA.md): what was decided, why and what was discarded, step by step.
- [DICCIONARIO.md](DICCIONARIO.md): what each table and column means.
- [data/FUENTES.csv](data/FUENTES.csv): each downloaded file, with date and hash.
- [docs/relevamiento_fuentes.md](docs/relevamiento_fuentes.md): which sources were reviewed and what each one contains.
- [sql/](sql/): loading, model and checks. [sql/analisis/](sql/analisis/): one commented query per question.

(The log, dictionary and source survey are in Spanish.)

## How to reproduce it

Requires PostgreSQL 17 and Python 3 with the packages in `requirements.txt`.

```bash
createdb mineria
./scripts/descargar_datos.sh         # downloads about 310 MB to data/raw/
./scripts/reconstruir.sh             # builds the database and runs the checks
python3 scripts/exportar_pagina.py   # builds the front page and articles in pagina/ from the database
```

Some company reports cannot be downloaded automatically (the SEC blocks downloads without identification); their figures are copied by hand into `data/`, with the source and page for each.

## Sources

INDEC (foreign trade by product and country), Argentina's Mining Secretariat (SIACAM: exports, employment, project pipeline, prices), UN Comtrade (what buyer countries declare), the Labour Ministry's Employment and Business Dynamics Observatory (employment and wages by sector and department), the Economy Ministry's RIGI dashboard, San Juan's Ministry of Finance (royalties), Banco Nación and the Bank of Canada (exchange rates), the Argentine Chamber of Mining Entrepreneurs (total output), Natural Resources Canada (ESTMA), the National Geographic Institute (map) and company annual reports.

Francisco Tornello, 2026. I worked with Claude Code as an assistant.

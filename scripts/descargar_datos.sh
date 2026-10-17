#!/bin/bash
# Descarga todas las fuentes del proyecto a data/raw/. Los archivos quedan tal
# cual se publican; nada de lo que está en data/raw/ se edita a mano.
# Las fuentes se actualizan todos los meses: los números del análisis
# corresponden a la descarga del 13 de octubre de 2026.
set -uo pipefail
cd "$(dirname "$0")/.."

fallas=0
bajar() {  # bajar URL DESTINO
    mkdir -p "$(dirname "$2")"
    if curl -L -sS -f --retry 3 --retry-delay 5 -m 300 -A "Mozilla/5.0" -o "$2" "$1"; then
        echo "ok    $2"
    else
        echo "FALLA $1"
        rm -f "$2"
        fallas=$((fallas + 1))
    fi
}

# INDEC: exportaciones mensuales por producto (NCM a 8 dígitos) y país de
# destino. Un ZIP por año desde 2002; el del año en curso se actualiza cada mes.
ANIO_ACTUAL=$(date +%Y)
for anio in $(seq 2002 "$ANIO_ACTUAL"); do
    bajar "https://comex.indec.gob.ar/files/zips/exports_${anio}_M.zip" "data/raw/indec/exports_${anio}_M.zip"
done

# Secretaría de Minería (SIACAM): todos los archivos que publica en
# datos.gob.ar. La lista está en scripts/siacam_archivos.txt.
while read -r archivo; do
    [ -n "$archivo" ] && bajar "https://www.mecon.gob.ar/dataset/$archivo" "data/raw/siacam/$archivo"
done < scripts/siacam_archivos.txt

# OEDE (Ministerio de Trabajo): empleo y salarios registrados por departamento
# y sector, y por provincia y rama a cuatro dígitos.
for archivo in departamento_series_empleo_y_salarios_mensual_sector_1.csv \
               provinciales_serie_remuneraciones_mensual_4dig_8.xlsx \
               provinciales_serie_empleo_trimestral_4dig_8.xlsx \
               nota_metodologica_3.pdf; do
    bajar "https://www.argentina.gob.ar/sites/default/files/$archivo" "data/raw/oede/$archivo"
done

# CAEM (cámara de empresas mineras): informe productivo anual, en PDF. De ahí
# se copió a mano data/caem_produccion_anual.csv.
bajar "https://caem.com.ar/storage/2026/05/informe-productivo-caem-2026.pdf" "data/raw/caem/informe-productivo-caem-2026.pdf"

# Informes anuales de las empresas, para la producción mina por mina. De ahí
# se copió a mano data/produccion_por_mina.csv.
BARRICK=https://s25.q4cdn.com/322814910/files/doc_financial/annual_reports
for anio in $(seq 2006 2025); do
    if [ "$anio" -ge 2021 ]; then nombre="Barrick_Annual_Report_$anio.pdf"; else nombre="Barrick-Annual-Report-$anio.pdf"; fi
    bajar "$BARRICK/$anio/$nombre" "data/raw/empresas/barrick/$nombre"
done

# Hacienda de San Juan: planillas de ejecución presupuestaria al cierre de cada
# año. De ahí se copió a mano data/sanjuan_regalias.csv.
while read -r archivo; do
    [ -n "$archivo" ] && bajar "https://web.sanjuan.gob.ar/hacienda/wp-content/uploads/sites/6/$archivo" "data/raw/sanjuan_hacienda/$(basename "$archivo")"
done < scripts/sanjuan_hacienda_archivos.txt

# Tipo de cambio oficial (Banco Nación, vendedor), promedio mensual.
bajar "https://apis.datos.gob.ar/series/api/series/?ids=168.1_T_CAMBIOR_D_0_0_26&collapse=month&collapse_aggregation=avg&start_date=2002-01-01&limit=1000&format=csv" "data/raw/bna/tipo_de_cambio_bna.csv"

NEWMONT=https://s24.q4cdn.com/382246808/files/doc_financials
bajar "$NEWMONT/quarterly/2019/q4/Newmont-Full-Year-and-Q4-2019-Regional-Operating-Statistics_Final.pdf" "data/raw/empresas/newmont/Newmont-Full-Year-and-Q4-2019-Regional-Operating-Statistics_Final.pdf"
bajar "$NEWMONT/2022/q4/Newmont-Full-Year-and-Fourth-Quarter-2022-Operating-Statistics_Final2.pdf" "data/raw/empresas/newmont/Newmont-Full-Year-and-Fourth-Quarter-2022-Operating-Statistics_Final2.pdf"
bajar "$NEWMONT/2020/ar/386219(1)_17_Newmont_AR_WR.pdf" "data/raw/empresas/newmont/Newmont_Annual_Report_2020.pdf"
bajar "$NEWMONT/2023/ar/newmont-2023-annual-report.pdf" "data/raw/empresas/newmont/Newmont_Annual_Report_2023.pdf"
bajar "$NEWMONT/2024/ar/Newmont-2024-Annual-Report.pdf" "data/raw/empresas/newmont/Newmont_Annual_Report_2024.pdf"
bajar "$NEWMONT/2025/ar/Newmont_Annual-Report_web-PDF_26-4060-1_client.pdf" "data/raw/empresas/newmont/Newmont_Annual_Report_2025.pdf"

bajar "https://s202.q4cdn.com/876548212/files/doc_news/Pan-American-Silver-Announces-Preliminary-2023-Production-Results-and-Guidance-for-2024-2024.pdf" "data/raw/empresas/panamerican/PAAS_produccion_2023_preliminar.pdf"
bajar "https://s202.q4cdn.com/876548212/files/doc_news/Pan-American-Silver-Achieves-2025-Production-Guidance-and-Provides-Guidance-for-2026-2026.pdf" "data/raw/empresas/panamerican/PAAS_produccion_2025.pdf"
bajar "https://www.hochschildmining.com/media/xfpdwhfn/1b_q4-2025.pdf" "data/raw/empresas/hochschild/Hochschild_Q4_2025_production_report.pdf"

bajar "https://s202.q4cdn.com/876548212/files/doc_news/Pan-American-Silver-achieves-2024-production-guidance-and-enters-2025-with-a-record-cash-balance-2025.pdf" "data/raw/empresas/panamerican/PAAS_produccion_2024_preliminar.pdf"
bajar "https://www.hochschildmining.com/media/4ludepu5/1d_fy-2023-results_final.pdf" "data/raw/empresas/hochschild/Hochschild_FY2023_results.pdf"
bajar "https://www.hochschildmining.com/media/5f1bwinx/1c_full-year-results_final.pdf" "data/raw/empresas/hochschild/Hochschild_FY2022_results.pdf"
# Los datos de AngloGold, Goldcorp, Yamana y Fortuna se leyeron en el navegador
# (la SEC y la página de Fortuna no dejan bajar los documentos con curl). La
# dirección de cada documento está en la columna "fuente" de
# data/produccion_por_mina.csv.

MINEROS=https://cdn.prod.website-files.com/66d5fe0b309d400659e06f21
bajar "$MINEROS/66db5fb834675ba7d950af92_Q4%20%26%20YE%202021%20MD%26A%20Mineros%20%20-%20English.pdf" "data/raw/empresas/mineros/Mineros_MDA_YE2021.pdf"
bajar "$MINEROS/66db640301ec93caee8ad652_Q4%20%26%20YE%202022%20MD%26A%20Mineros%20%20-%20English.pdf" "data/raw/empresas/mineros/Mineros_MDA_YE2022.pdf"
bajar "$MINEROS/66db684468b78ef565225e81_Q4%20%26%20YE%202023%20MD%26A%20Mineros%20-%20English.pdf" "data/raw/empresas/mineros/Mineros_MDA_YE2023.pdf"

# Pagos a gobiernos: base pública de Canadá (ESTMA) con los pagos por proyecto
# de las empresas que cotizan allá, y tipo de cambio del Banco de Canadá para
# pasarlos a dólares estadounidenses.
bajar "https://www150.statcan.gc.ca/n1/pub/71-607-x/2022008/STC_DF_ESTMA-eng.csv" "data/raw/estma/STC_DF_ESTMA-eng.csv"
bajar "https://www.bankofcanada.ca/valet/observations/FXUSDCAD/csv?start_date=2017-01-01&end_date=2025-12-31" "data/raw/boc/FXUSDCAD.csv"
# Informes de contribución tributaria de Barrick (Veladero no está en ESTMA).
for anio in 2023 2024 2025; do
    bajar "https://s25.q4cdn.com/322814910/files/doc_downloads/tax/Barrick_Tax_Contribution_Report_$anio.pdf" "data/raw/empresas/barrick/impuestos/Barrick_Tax_Contribution_Report_$anio.pdf"
done

# Allkem (Olaroz): informe anual y resultados del ejercicio 2023 en la bolsa australiana.
bajar "https://announcements.asx.com.au/asxpdf/20230822/pdf/05sw65j3sqfh4x.pdf" "data/raw/empresas/allkem/ASX_20230822_pdf_05sw65j3sqfh4x.pdf"
bajar "https://announcements.asx.com.au/asxpdf/20230822/pdf/05sw6fxfvf0h08.pdf" "data/raw/empresas/allkem/ASX_20230822_pdf_05sw6fxfvf0h08.pdf"
bajar "https://announcements.asx.com.au/asxpdf/20230727/pdf/05s09fhr18rv3v.pdf" "data/raw/empresas/allkem/ASX_20230727_pdf_05s09fhr18rv3v.pdf"

# Contorno de las provincias (Instituto Geográfico Nacional), para el mapa de las notas.
bajar "https://www.argentina.gob.ar/profiles/argentinagobar/themes/contrib/poncho/resources/jsons/geo-provincias-argentinas.json" "data/raw/geo/geo-provincias-argentinas.json"

echo "Descargas fallidas: $fallas"

# Los ZIP del INDEC y los Excel de SIACAM se pasan a CSV para poder cargarlos.
python3 scripts/preparar_indec.py
python3 scripts/preparar_siacam.py
python3 scripts/preparar_oede.py
python3 scripts/preparar_boc.py
python3 scripts/preparar_ncm_minero.py
python3 scripts/preparar_mapa.py

# UN Comtrade: lo que otros países declaran importar desde Argentina.
# Son unos 130 pedidos con pausa; tarda alrededor de 15 minutos la primera vez.
python3 scripts/descargar_comtrade.py

python3 scripts/registrar_fuentes.py

#!/bin/bash
# Reconstruye la base completa desde los archivos de data/raw/ y corre los
# controles. Si un control no cierra, corta con error.
# Requiere PostgreSQL con una base llamada mineria (createdb mineria).
# Tarda un par de minutos: las tablas del INDEC y del OEDE tienen millones de filas.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

correr() {
    echo "== sql/$1.sql"
    psql -q -d mineria -v ON_ERROR_STOP=1 -P pager=off -f "sql/$1.sql"
}

for archivo in 01_raw_tablas 02_raw_carga 03_capa_limpia 05_siacam_complementarios 06_comtrade 07_oede 08_rigi 10_caem 11_produccion_mina 12_regalias_y_tipo_de_cambio 13_pagos_a_gobiernos 14_correcciones_y_hechos 09_controles; do
    correr "$archivo"
done

#!/bin/bash
# Arma la rama `publicar` con lo que va al repositorio público
# (FTornello/mineria-argentina-en-datos): todo lo de `main` menos los archivos
# de PRIVADOS. Cada versión pública es un solo commit nuevo encima del
# anterior, sin el historial de trabajo, que queda en el repositorio privado.
#
# No toca la carpeta de trabajo ni sube nada. Para publicar, después:
#   git push publico publicar:main
set -euo pipefail
cd "$(dirname "$0")/.."

PRIVADOS="CLAUDE.md"

indice=$(mktemp)
trap 'rm -f "$indice"' EXIT
GIT_INDEX_FILE="$indice" git read-tree main
for archivo in $PRIVADOS; do
    GIT_INDEX_FILE="$indice" git rm -q --cached --ignore-unmatch "$archivo"
done
arbol=$(GIT_INDEX_FILE="$indice" git write-tree)

# Si ya hay una versión publicada, la nueva va encima; si no, arranca sola.
padre=""
git rev-parse -q --verify publicar >/dev/null && padre="-p publicar"
if [ -n "$padre" ] && [ "$(git rev-parse publicar^{tree})" = "$arbol" ]; then
    echo "La versión pública ya está al día."
    exit 0
fi
mensaje="${1:-Actualización de la versión pública ($(date +%Y-%m-%d))}"
commit=$(git commit-tree "$arbol" $padre -m "$mensaje")
git branch -f publicar "$commit"
echo "Rama publicar: $(git log publicar --oneline -1)"
echo "Archivos: $(git ls-tree -r --name-only publicar | wc -l | tr -d ' ')"

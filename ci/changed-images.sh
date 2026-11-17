#!/usr/bin/env bash
# Stampa (JSON) l'elenco delle immagini da costruire.
#
#   ci/changed-images.sh <base-ref|all> [head-ref]
#
# Con "all", o se la base non è valida (primo push), restituisce tutte le immagini.
set -euo pipefail

BASE="${1:-all}"
HEAD="${2:-HEAD}"

all_images() {
  find images -mindepth 2 -maxdepth 2 -name Dockerfile -printf '%h\n' | xargs -rn1 basename | sort -u
}

if [[ "${BASE}" == "all" || "${BASE}" =~ ^0+$ ]] || ! git cat-file -e "${BASE}^{commit}" 2>/dev/null; then
  LIST="$(all_images)"
elif git diff --name-only "${BASE}" "${HEAD}" -- ci/ .github/workflows/ | grep -q .; then
  # cambiata la pipeline: si ricostruisce tutto per verificarla
  LIST="$(all_images)"
else
  LIST="$(git diff --name-only "${BASE}" "${HEAD}" -- images/ \
          | awk -F/ 'NF>=3 {print $2}' | sort -u \
          | while read -r d; do [[ -f "images/${d}/Dockerfile" ]] && echo "${d}"; done || true)"
fi

# JSON array compatto, es. ["blender","pytorch"]
printf '%s\n' "${LIST}" | awk 'NF' | python3 -c 'import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))'

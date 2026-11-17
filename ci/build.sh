#!/usr/bin/env bash
# Build, test e (opzionale) pubblicazione di un'immagine.
#
#   ci/build.sh <immagine> [--push]
#
# Variabili d'ambiente:
#   REGISTRY      es. ghcr.io/ilbenni          (obbligatoria con --push)
#   BUILD_NUMBER  numero di build per il tag   (default: 0)
#
# Tag prodotti (immutabile + comodo):
#   $REGISTRY/<immagine>:<VERSION>-<BUILD_NUMBER>   OCI
#   $REGISTRY/<immagine>:<VERSION>                  OCI
#   $REGISTRY/<immagine>-sif:<stessi tag>           SIF via ORAS
#
# Lo script non contiene nulla di specifico di GitHub: gira uguale su un runner Forgejo.
set -euo pipefail

NAME="${1:?uso: ci/build.sh <immagine> [--push]}"
PUSH="${2:-}"
DIR="images/${NAME}"

[[ -f "${DIR}/Dockerfile" ]] || { echo "manca ${DIR}/Dockerfile" >&2; exit 1; }
[[ -f "${DIR}/VERSION" ]]    || { echo "manca ${DIR}/VERSION" >&2; exit 1; }

VERSION="$(tr -d '[:space:]' < "${DIR}/VERSION")"
BUILD_NUMBER="${BUILD_NUMBER:-0}"
REGISTRY="${REGISTRY:-local}"
REGISTRY="${REGISTRY,,}"                       # i registry OCI vogliono nomi minuscoli
IMG="${REGISTRY}/${NAME}"
TAG_IMMUTABLE="${VERSION}-${BUILD_NUMBER}"

echo "==> ${NAME} ${VERSION} (build ${BUILD_NUMBER})"

docker build "${DIR}" \
  --build-arg "VERSION=${VERSION}" \
  --label "org.opencontainers.image.revision=${GITHUB_SHA:-unknown}" \
  ${SOURCE_URL:+--label "org.opencontainers.image.source=${SOURCE_URL}"} \
  -t "${IMG}:${TAG_IMMUTABLE}" \
  -t "${IMG}:${VERSION}"

if [[ -f "${DIR}/test.sh" ]]; then
  echo "==> test"
  docker run --rm \
    -v "${PWD}/${DIR}/test.sh:/test.sh:ro" \
    --entrypoint /bin/sh "${IMG}:${TAG_IMMUTABLE}" /test.sh
fi

if [[ "${PUSH}" != "--push" ]]; then
  echo "==> nessun push (usa --push per pubblicare)"
  exit 0
fi

[[ "${REGISTRY}" != "local" ]] || { echo "REGISTRY non impostata" >&2; exit 1; }

echo "==> push OCI"
docker push "${IMG}:${TAG_IMMUTABLE}"
docker push "${IMG}:${VERSION}"

echo "==> conversione SIF"
SIF="${NAME}-${TAG_IMMUTABLE}.sif"
apptainer build --force "${SIF}" "docker-daemon://${IMG}:${TAG_IMMUTABLE}"
ls -lh "${SIF}"

echo "==> push SIF (ORAS)"
apptainer push "${SIF}" "oras://${IMG}-sif:${TAG_IMMUTABLE}"
apptainer push "${SIF}" "oras://${IMG}-sif:${VERSION}"
rm -f "${SIF}"

echo "==> fatto: ${IMG}:${TAG_IMMUTABLE}  e  ${IMG}-sif:${TAG_IMMUTABLE}"

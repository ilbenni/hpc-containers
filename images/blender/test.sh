#!/bin/sh
# Smoke test eseguito DENTRO il container (in CI senza GPU: solo Cycles su CPU).
set -eu

blender -b --version

OUT=$(mktemp -d)
# Scena di default, risoluzione e campioni minimi: verifica che Cycles renderizzi davvero.
blender -b --factory-startup -E CYCLES \
  --python-expr "import bpy; s=bpy.context.scene; s.render.resolution_percentage=10; s.cycles.samples=4; s.cycles.device='CPU'" \
  -o "$OUT/frame_####" -F PNG -f 1

test -s "$OUT/frame_0001.png"
echo "OK: render di prova completato ($OUT/frame_0001.png)"

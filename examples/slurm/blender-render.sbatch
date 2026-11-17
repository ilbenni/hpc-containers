#!/bin/bash
# Rendering di un'animazione Blender con un job array Slurm: un frame per task.
#
#   sbatch --array=1-250 blender-render.sbatch scena.blend
#
# Adattare partizione, GPU e percorso del SIF al cluster.
#SBATCH --job-name=blender
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=logs/%x_%A_%a.out

set -euo pipefail

BLEND="${1:?uso: sbatch --array=A-B blender-render.sbatch file.blend}"
SIF="${BLENDER_SIF:-/software/containers/blender/blender-5.2.0.sif}"
OUTDIR="${OUTDIR:-$PWD/render}"
mkdir -p "$OUTDIR" logs

# --nv monta nel container il driver NVIDIA dell'host; Slurm limita le GPU visibili
# tramite CUDA_VISIBLE_DEVICES, che Apptainer passa al container.
apptainer exec --nv "$SIF" blender -b "$BLEND" \
  -E CYCLES \
  -o "$OUTDIR/frame_####" \
  -f "${SLURM_ARRAY_TASK_ID}" \
  -- --cycles-device OPTIX

#!/bin/bash
# Swap a finished full GoalScope run into the site: archive the model's previous data, rename <src><SUFFIX> -> <src>,
# drop smoke sources, rebuild. Usage (from the goals-web root): bash site/finalize_run.sh <model-short-name> [suffix=-v2]
set -euo pipefail
M=$1; SUF=${2:--v2}
cd "$(dirname "$0")"
D=data/$M
[ -d "$D" ] || { echo "no site/$D"; exit 1; }
mkdir -p data_legacy/$M
for src in ds_and_algo humaneval mbpp; do
  [ -d "$D/$src$SUF" ] || continue
  if [ -d "$D/$src" ]; then mv "$D/$src" "data_legacy/$M/$src.$(date +%Y%m%d_%H%M%S)"; fi
  mv "$D/$src$SUF" "$D/$src"
done
rm -rf "$D"/*-v2-smoke
rm -rf pages/$M          # pages are regenerated from data
cd .. && make demo

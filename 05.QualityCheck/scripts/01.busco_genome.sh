#!/usr/bin/env bash
# ==============================================================================
# Step 1: BUSCO — Genome Assembly
# ==============================================================================
# Tool: BUSCO v5.6.1
# Lineage: ascomycota_odb10 (n = 1,706)
# Expected: ~97% complete for high-quality fungal assembly
#
# Usage:
#   export ASSEMBLY=/path/to/genome.fa
#   export BUSCO_LINEAGE=/path/to/ascomycota_odb10
#   export CPUS=48
#   bash 01.busco_genome.sh
# ==============================================================================

set -euo pipefail

: "${ASSEMBLY:=genome.fa}"
: "${BUSCO_LINEAGE:=ascomycota_odb10}"
: "${OUTDIR:=busco_genome}"
: "${CPUS:=48}"

busco -i "${ASSEMBLY}" \
  -l "${BUSCO_LINEAGE}" \
  -m genome \
  -o "${OUTDIR}" \
  -c "${CPUS}"

echo "=== BUSCO genome mode complete ==="
cat "${OUTDIR}/short_summary.specific.*.${OUTDIR}.txt"
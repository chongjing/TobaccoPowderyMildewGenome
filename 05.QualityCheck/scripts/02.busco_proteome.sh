#!/usr/bin/env bash
# ==============================================================================
# Step 2: BUSCO — Predicted Proteome
# ==============================================================================
# Tool: BUSCO v5.6.1
# Lineage: ascomycota_odb10 (n = 1,706)
# Expected: matches genome BUSCO score (confirms annotation completeness)
#
# Usage:
#   export PROTEOME=/path/to/proteins.fa
#   export BUSCO_LINEAGE=/path/to/ascomycota_odb10
#   export CPUS=48
#   bash 02.busco_proteome.sh
# ==============================================================================

set -euo pipefail

: "${PROTEOME:=proteins.fa}"
: "${BUSCO_LINEAGE:=ascomycota_odb10}"
: "${OUTDIR:=busco_proteome}"
: "${CPUS:=48}"

busco -i "${PROTEOME}" \
  -l "${BUSCO_LINEAGE}" \
  -m proteins \
  -o "${OUTDIR}" \
  -c "${CPUS}"

echo "=== BUSCO proteome mode complete ==="
cat "${OUTDIR}/short_summary.specific.*.${OUTDIR}.txt"
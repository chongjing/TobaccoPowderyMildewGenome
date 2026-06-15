#!/usr/bin/env bash
# ==============================================================================
# Step 4: Funannotate update — PASA UTR Refinement
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Gene Annotation
# Tool:     Funannotate v1.8.17 (Apptainer/Singularity container)
# Input:    predict_results/ (from Step 3) + raw RNA-seq FASTQ
# Output:   update_results/ with UTRs + alternative isoforms
#
# The PASA pipeline:
#   1. Trinity: de novo transcript assembly from RNA-seq reads
#   2. PASA: align transcripts to genome → correct exon boundaries
#   3. Add UTRs (5' and 3' untranslated regions)
#   4. Capture alternative splicing isoforms
#
# Expected runtime: ~2-3 days (PASA Expectation-Maximisation is the bottleneck)
#
# Known issue: salmon within PASA requires libboost 1.85.0.
# If the container is missing these libraries, bind-mount the host's boost libs:
#   -B /path/to/libboost-1.85.0/lib:/opt/boost185:ro
#   --env LD_LIBRARY_PATH=/opt/boost185
#
# Usage:
#   export PROJECT_ROOT=/path/to/project
#   export CONTAINER=/path/to/funannotate.v2.sif
#   export RNA_LEFT=/path/to/PM11_merged_R1.fastq.gz
#   export RNA_RIGHT=/path/to/PM11_merged_R2.fastq.gz
#   export CPUS=48
#   bash 04.funannotate_update.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (set before running) ---
: "${PROJECT_ROOT:=.}"
: "${CONTAINER:=funannotate.v2.sif}"
: "${CPUS:=48}"

# RNA-seq raw reads (merged R1 + R2)
: "${RNA_LEFT:=${PROJECT_ROOT}/rnaseq/PM11_merged_R1.fastq.gz}"
: "${RNA_RIGHT:=${PROJECT_ROOT}/rnaseq/PM11_merged_R2.fastq.gz}"

# Boost library fix (bind-mount from host if container lacks libboost 1.85.0)
: "${BOOST_LIB:=}"
BOOST_BIND=""
[[ -n "${BOOST_LIB}" ]] && BOOST_BIND="-B ${BOOST_LIB}:/opt/boost185 --env LD_LIBRARY_PATH=/opt/boost185"

echo "[$(date)] Starting funannotate update (PASA)..."
echo "  Input dir: ${PROJECT_ROOT}"
echo "  RNA left: ${RNA_LEFT}"
echo "  RNA right: ${RNA_RIGHT}"
echo "  Boost lib: ${BOOST_LIB:-not needed}"
echo "  Expected runtime: ~2-3 days"
echo ""

singularity exec \
  -B "${PROJECT_ROOT}:${PROJECT_ROOT}" \
  ${BOOST_BIND} \
  "${CONTAINER}" /venv/bin/funannotate update \
  -i "${PROJECT_ROOT}" \
  --left "${RNA_LEFT}" \
  --right "${RNA_RIGHT}" \
  --stranded RF \
  --no_trimmomatic --no_normalize_reads \
  --max_intronlen 3000 \
  --cpus "${CPUS}"

echo "[$(date)] === FUNANNOTATE UPDATE (PASA) DONE ==="
echo "Results: ${PROJECT_ROOT}/update_results/"
ls -lh "${PROJECT_ROOT}/update_results/" 2>/dev/null
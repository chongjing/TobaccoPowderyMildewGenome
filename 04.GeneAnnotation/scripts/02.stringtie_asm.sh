#!/usr/bin/env bash
# ==============================================================================
# Step 2: Transcript Assembly — StringTie + bam2hints
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Gene Annotation
# Tool:     StringTie v2.2.3 (inside Funannotate container), bam2hints (conda)
# Input:    Merged RNA-seq BAM (from Step 1)
# Output:   transcripts.gtf (StringTie), bam_hints.gff (intron hints for Augustus)
#
# Usage:
#   export PROJECT_ROOT=/path/to/project
#   export CONTAINER=/path/to/funannotate.sif
#   export BAM2HINTS=/path/to/bam2hints  # optional; Augustus can run internally
#   export CPUS=48
#   bash 02.stringtie_asm.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (set before running) ---
: "${PROJECT_ROOT:=.}"
: "${CONTAINER:=}"
: "${RUN:=${CONTAINER:+singularity exec ${CONTAINER}}}"
: "${BAM2HINTS:=bam2hints}"
: "${ALIGN_DIR:=${PROJECT_ROOT}/alignments}"
: "${TRANS_DIR:=${PROJECT_ROOT}/transcripts}"
: "${LOG_DIR:=${PROJECT_ROOT}/logs}"
: "${CPUS:=48}"

MERGED_BAM="${ALIGN_DIR}/merged.bam"
mkdir -p "${TRANS_DIR}" "${LOG_DIR}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_DIR}/step2_transcripts.log"; }

log "=== Step 2: Transcript Assembly ==="

# --- 2a. StringTie ---
if [[ ! -f "${TRANS_DIR}/transcripts.gtf" ]]; then
    log "Running StringTie (stranded RF)..."
    $RUN stringtie -p "${CPUS}" -fr \
        -o "${TRANS_DIR}/transcripts.gtf" \
        "${MERGED_BAM}" \
        2>&1 | tee -a "${LOG_DIR}/step2_transcripts.log"
else
    log "transcripts.gtf exists, skipping"
fi

TOTAL_TR=$(awk '$3=="transcript" {c++} END{print c}' "${TRANS_DIR}/transcripts.gtf")
log "Total transcripts assembled: ${TOTAL_TR}"

# --- 2b. bam2hints (intron hints for Augustus) ---
# Pre-generated externally to avoid the container's missing-binary issue
if [[ ! -f "${TRANS_DIR}/bam_hints.gff" ]]; then
    log "Running bam2hints..."
    ${BAM2HINTS} --intronsonly \
        --in "${MERGED_BAM}" \
        --out "${TRANS_DIR}/bam_hints.gff" \
        2>&1 | tee -a "${LOG_DIR}/step2_transcripts.log"
else
    log "bam_hints.gff exists, skipping"
fi

HINTS_LINES=$(wc -l < "${TRANS_DIR}/bam_hints.gff")
log "Hints file: ${HINTS_LINES} lines"

log "=== Step 2 Complete ==="
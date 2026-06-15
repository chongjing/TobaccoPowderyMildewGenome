#!/usr/bin/env bash
# ==============================================================================
# Step 1: RNA-seq Alignment — HISAT2
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Gene Annotation
# Tool:     HISAT2 v2.2.2 (inside Funannotate container)
# Input:    Repeat-soft-masked genome FASTA + trimmed RNA-seq FASTQ
# Output:   Sorted per-sample BAM → merged BAM
#
# NOTE: Low alignment rate (~8%) is EXPECTED for obligate biotrophs.
# Total RNA is extracted from infected tobacco tissue; most reads are host.
# ~3.6M fungal-aligned reads across 2 replicates is sufficient for annotation.
#
# Usage:
#   export PROJECT_ROOT=/path/to/project
#   export CONTAINER=/path/to/funannotate.sif  # or FUNANNOTATE=funannotate if native
#   export CPUS=48
#   bash 01.hisat2_align.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (set before running) ---
: "${PROJECT_ROOT:=.}"
: "${CONTAINER:=}"
: "${GENOME:=${PROJECT_ROOT}/genome.fa}"
: "${RNA_DIR:=${PROJECT_ROOT}/rnaseq}"
: "${ALIGN_DIR:=${PROJECT_ROOT}/alignments}"
: "${LOG_DIR:=${PROJECT_ROOT}/logs}"
: "${CPUS:=48}"

# Container execution prefix (empty if Funannotate is installed natively)
: "${RUN:=${CONTAINER:+singularity exec ${CONTAINER}}}"

mkdir -p "${ALIGN_DIR}/hisat2_index" "${LOG_DIR}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_DIR}/step1_alignment.log"; }

log "=== Step 1: RNA-seq Alignment ==="

# --- 1a. Build HISAT2 index ---
if [[ ! -f "${ALIGN_DIR}/hisat2_index/genome.1.ht2" ]]; then
    log "Building HISAT2 index..."
    $RUN hisat2-build -p "${CPUS}" "${GENOME}" "${ALIGN_DIR}/hisat2_index/genome"
else
    log "HISAT2 index already exists, skipping"
fi

# --- 1b. Align sample 1 ---
SAMPLE1_R1="${RNA_DIR}/PM11_1_R1.fastq.gz"
SAMPLE1_R2="${RNA_DIR}/PM11_1_R2.fastq.gz"
if [[ ! -f "${ALIGN_DIR}/PM11_1.bam" ]]; then
    log "Aligning PM11_1..."
    $RUN hisat2 -p "${CPUS}" --dta \
        -x "${ALIGN_DIR}/hisat2_index/genome" \
        -1 "${SAMPLE1_R1}" -2 "${SAMPLE1_R2}" \
        -S "${ALIGN_DIR}/PM11_1.sam" \
        2>> "${LOG_DIR}/step1_alignment.log"
    samtools sort -@ 8 -o "${ALIGN_DIR}/PM11_1.bam" "${ALIGN_DIR}/PM11_1.sam"
    rm -f "${ALIGN_DIR}/PM11_1.sam"
    samtools index "${ALIGN_DIR}/PM11_1.bam"
    log "PM11_1 aligned"
else
    log "PM11_1.bam exists, skipping"
fi

# --- 1c. Align sample 2 ---
SAMPLE2_R1="${RNA_DIR}/PM11_2_R1.fastq.gz"
SAMPLE2_R2="${RNA_DIR}/PM11_2_R2.fastq.gz"
if [[ ! -f "${ALIGN_DIR}/PM11_2.bam" ]]; then
    log "Aligning PM11_2..."
    $RUN hisat2 -p "${CPUS}" --dta \
        -x "${ALIGN_DIR}/hisat2_index/genome" \
        -1 "${SAMPLE2_R1}" -2 "${SAMPLE2_R2}" \
        -S "${ALIGN_DIR}/PM11_2.sam" \
        2>> "${LOG_DIR}/step1_alignment.log"
    samtools sort -@ 8 -o "${ALIGN_DIR}/PM11_2.bam" "${ALIGN_DIR}/PM11_2.sam"
    rm -f "${ALIGN_DIR}/PM11_2.sam"
    samtools index "${ALIGN_DIR}/PM11_2.bam"
    log "PM11_2 aligned"
else
    log "PM11_2.bam exists, skipping"
fi

# --- 1d. Merge BAMs ---
if [[ ! -f "${ALIGN_DIR}/merged.bam" ]]; then
    log "Merging BAMs..."
    samtools merge -@ 8 "${ALIGN_DIR}/merged.bam" \
        "${ALIGN_DIR}/PM11_1.bam" "${ALIGN_DIR}/PM11_2.bam"
    samtools index "${ALIGN_DIR}/merged.bam"
else
    log "merged.bam exists, skipping"
fi

# --- Summary ---
log "=== Alignment Summary ==="
for bam in PM11_1 PM11_2 merged; do
    log "${bam}:"
    samtools flagstat "${ALIGN_DIR}/${bam}.bam" 2>&1 | tee -a "${LOG_DIR}/step1_alignment.log"
done

log "=== Step 1 Complete ==="
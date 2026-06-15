#!/usr/bin/env bash
# ==============================================================================
# Step 3: Merqury — Reference-free Quality Value
# ==============================================================================
# Tool: Merqury v1.4.1 (meryl v1.4.1)
# Input: Assembly FASTA + Illumina WGS reads
# Output: QV (consensus accuracy), k-mer completeness
#
# Merqury computes a reference-free quality value (QV) by comparing
# k-mers from the short-read data against those present in the assembly.
#
# Usage:
#   export ASSEMBLY=/path/to/genome.fa
#   export WGS_READS=/path/to/illumina_wgs.fastq.gz  # R1 only or comma-R1,R2
#   export CPUS=48
#   bash 03.merqury_qv.sh
# ==============================================================================

set -euo pipefail

: "${ASSEMBLY:=genome.fa}"
: "${WGS_READS:=}"
: "${OUTDIR:=merqury_out}"
: "${MERYL:=meryl}"
: "${MERQURY_SH:=merqury.sh}"
: "${CPUS:=48}"

if [[ -z "${WGS_READS}" ]]; then
    echo "ERROR: WGS_READS not set. Provide Illumina WGS reads for k-mer counting."
    echo "Usage: WGS_READS=/path/to/reads.fastq.gz bash 03.merqury_qv.sh"
    exit 1
fi

mkdir -p "${OUTDIR}"

# Step 1: Count k-mers from WGS reads (k = 19)
echo "[$(date)] Counting k-mers from WGS reads..."
${MERYL} count k=19 "${WGS_READS}" output "${OUTDIR}/wgs.meryl"

# Step 2: Count k-mers from assembly
echo "[$(date)] Counting k-mers from assembly..."
${MERYL} count k=19 "${ASSEMBLY}" output "${OUTDIR}/asm.meryl"

# Step 3: Run Merqury
echo "[$(date)] Running Merqury..."
${MERQURY_SH} "${OUTDIR}/wgs.meryl" "${OUTDIR}/asm.meryl" "${ASSEMBLY}" "${OUTDIR}"

echo "[$(date)] === Merqury complete ==="
echo "Results in: ${OUTDIR}/"
cat "${OUTDIR}"/*.qv 2>/dev/null || echo "QV file not found"

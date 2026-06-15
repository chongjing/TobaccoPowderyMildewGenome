#!/usr/bin/env bash
# ==============================================================================
# Step 4: Read Mapping Rates
# ==============================================================================
# Tool: minimap2 (HiFi, RNA), bwa-mem2 (Hi-C), samtools
# Input: Assembly FASTA + raw reads
# Output: flagstat reports per data type
#
# Usage:
#   export GENOME=/path/to/genome.fa
#   export HIFI_READS=/path/to/hifi.fastq.gz
#   export HIC_DIR=/path/to/hic_trimmed
#   export RNA_DIR=/path/to/rnaseq_trimmed
#   export CPUS=48
#   bash 04.mapping_rates.sh
# ==============================================================================

set -euo pipefail

: "${GENOME:=genome.fa}"
: "${HIFI_READS:=}"
: "${HIC_R1:=}"
: "${HIC_R2:=}"
: "${RNA_R1:=}"
: "${RNA_R2:=}"
: "${MINIMAP2:=minimap2}"
: "${BWAMEM2:=bwa-mem2}"
: "${SAMTOOLS:=samtools}"
: "${OUTDIR:=.}"
: "${CPUS:=48}"

cd "${OUTDIR}"

# --- HiFi ---
if [[ -n "${HIFI_READS}" ]]; then
    echo "[$(date)] Mapping HiFi..."
    ${MINIMAP2} -ax map-hifi -t "${CPUS}" "${GENOME}" "${HIFI_READS}" 2> hifi_mm2.log \
      | ${SAMTOOLS} view -@ 8 -b - 2>/dev/null \
      | ${SAMTOOLS} sort -@ 8 -o hifi.bam -
    ${SAMTOOLS} flagstat hifi.bam > hifi.flagstat.txt
    echo "[$(date)] HiFi done"
fi

# --- RNA-seq ---
if [[ -n "${RNA_R1}" && -n "${RNA_R2}" ]]; then
    echo "[$(date)] Mapping RNA-seq..."
    ${MINIMAP2} -ax sr -t "${CPUS}" "${GENOME}" "${RNA_R1}" "${RNA_R2}" 2> rna_mm2.log \
      | ${SAMTOOLS} view -@ 8 -b - 2>/dev/null \
      | ${SAMTOOLS} sort -@ 8 -o rna.bam -
    ${SAMTOOLS} flagstat rna.bam > rna.flagstat.txt
    echo "[$(date)] RNA-seq done"
fi

# --- Hi-C ---
if [[ -n "${HIC_R1}" && -n "${HIC_R2}" ]]; then
    echo "[$(date)] Indexing genome for bwa-mem2..."
    ${BWAMEM2} index "${GENOME}" 2> bwa_index.log
    echo "[$(date)] Mapping Hi-C..."
    ${BWAMEM2} mem -5SP -t "${CPUS}" "${GENOME}" "${HIC_R1}" "${HIC_R2}" 2> hic_bwa.log \
      | ${SAMTOOLS} view -@ 8 -b - 2>/dev/null \
      | ${SAMTOOLS} sort -@ 8 -o hic.bam -
    ${SAMTOOLS} flagstat hic.bam > hic.flagstat.txt
    echo "[$(date)] Hi-C done"
fi

# --- Summary ---
echo "[$(date)] === MAPPING RATE SUMMARY ===" | tee mapping_summary.txt
for t in hifi rna hic; do
    if [[ -f "${t}.flagstat.txt" ]]; then
        echo "--- ${t} ---" | tee -a mapping_summary.txt
        cat "${t}.flagstat.txt" | tee -a mapping_summary.txt
    fi
done
echo "[$(date)] === DONE ==="
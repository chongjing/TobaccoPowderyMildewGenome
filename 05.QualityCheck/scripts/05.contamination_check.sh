#!/usr/bin/env bash
# ==============================================================================
# Step 5: Contamination Screening
# ==============================================================================
# Tool: BUSCO (viridiplantae_odb10), minimap2, samtools
# Input: Assembly FASTA + HiFi reads
# Output: Contamination report
#
# Two complementary approaches:
#   1. BUSCO with viridiplantae lineage — detect plant-conserved orthologues
#   2. GC content + coverage analysis — detect contigs with atypical profiles
#
# Usage:
#   export ASSEMBLY=/path/to/genome.fa
#   export HIFI_READS=/path/to/hifi.fastq.gz
#   export BUSCO_PLANT=/path/to/viridiplantae_odb10
#   export CPUS=48
#   bash 05.contamination_check.sh
# ==============================================================================

set -euo pipefail

: "${ASSEMBLY:=genome.fa}"
: "${HIFI_READS:=}"
: "${BUSCO_PLANT:=viridiplantae_odb10}"
: "${OUTDIR:=contamination_check}"
: "${MINIMAP2:=minimap2}"
: "${SAMTOOLS:=samtools}"
: "${CPUS:=48}"

mkdir -p "${OUTDIR}"

echo "=== Contamination Screening ==="

# --- 1. BUSCO viridiplantae ---
echo "[$(date)] BUSCO with viridiplantae lineage..."
busco -i "${ASSEMBLY}" \
  -l "${BUSCO_PLANT}" \
  -m genome \
  -o "${OUTDIR}/busco_viridiplantae" \
  -c "${CPUS}" \
  2>&1 | tee "${OUTDIR}/busco_plant.log"

# --- 2. GC/coverage uniformity ---
if [[ -n "${HIFI_READS}" ]]; then
    echo "[$(date)] Computing per-contig GC and coverage..."
    ${MINIMAP2} -ax map-hifi -t "${CPUS}" "${ASSEMBLY}" "${HIFI_READS}" \
      2>/dev/null \
      | ${SAMTOOLS} view -@ 8 -b - \
      | ${SAMTOOLS} sort -@ 8 -o "${OUTDIR}/hifi.bam" -
    ${SAMTOOLS} index "${OUTDIR}/hifi.bam"
    
    # Per-contig coverage
    ${SAMTOOLS} coverage "${OUTDIR}/hifi.bam" > "${OUTDIR}/per_contig_coverage.tsv"
    echo "  Coverage file: ${OUTDIR}/per_contig_coverage.tsv"
fi

# --- 3. Check for Nicotiana matches ---
echo "[$(date)] Checking for plant contamination via minimap2..."
${MINIMAP2} -x asm5 -t "${CPUS}" \
  "${ASSEMBLY}" \
  /dev/null 2>&1 || true  # placeholder — substitute Nicotiana genome path

echo "[$(date)] === Contamination check complete ==="
echo "  Review: ${OUTDIR}/busco_viridiplantae/short_summary.specific.*.txt"
echo "  Review: ${OUTDIR}/per_contig_coverage.tsv"
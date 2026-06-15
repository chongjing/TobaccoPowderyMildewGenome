#!/usr/bin/env bash
# ==============================================================================
# Step 3: Hi-C Scaffolding with YaHS
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Genome Assembly & Annotation
# Tools:    YaHS v1.2.2, samtools v1.22.1
# Input:    Primary contig FASTA + Hi-C alignment BAM (name-sorted)
# Output:   Scaffolded assembly FASTA + telomere detection report
#
# Strategic decisions:
#   - --telo-motif GGGTTA: detect telomeric repeats at scaffold ends
#   - --no-contig-ec: skip contig error correction (HiFi: Q20+ already)
#   - Result: YaHS made ZERO joins — contigs were already chromosome-scale
#     This validates the HiFi assembly quality but means scaffolding was
#     not strictly necessary. The step is preserved because it:
#     (a) confirms the contigs are complete chromosomes
#     (b) provides telomere status per scaffold
#     (c) generates the .bin file for Juicebox .hic creation
#
# Usage:
#   export YAHS=/path/to/yahs
#   export SAMTOOLS=/path/to/samtools
#   bash 03.yahs_scaffold.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (edit for your environment) ---
: "${YAHS:=yahs}"
: "${SAMTOOLS:=samtools}"
: "${ASSEMBLY:=../Gcichoracearum_BFJ.p_ctg.fasta}"
: "${HIC_BAM:=../hic_aligned.bam}"
: "${OUTDIR:=./}"
: "${OUTPREFIX:=${OUTDIR}/Gcichoracearum_BFJ_scaffolds}"

# --- Run YaHS ---
echo "[$(date)] Running YaHS scaffolding..."
$YAHS $ASSEMBLY $HIC_BAM \
  -o $OUTPREFIX \
  --no-contig-ec \
  --telo-motif GGGTTA \
  2>&1 | tee ${OUTDIR}/yahs.log

# --- Convert YaHS GFA to FASTA ---
if [[ -f "${OUTPREFIX}_scaffolds_final.gfa" ]]; then
  awk '/^S/{print ">"$2; print $3}' ${OUTPREFIX}_scaffolds_final.gfa > ${OUTPREFIX}.fasta
elif [[ -f "${OUTPREFIX}.gfa" ]]; then
  awk '/^S/{print ">"$2; print $3}' ${OUTPREFIX}.gfa > ${OUTPREFIX}.fasta
fi

# --- Generate .fai index ---
$SAMTOOLS faidx ${OUTPREFIX}.fasta

echo "[$(date)] YaHS complete. Output: ${OUTPREFIX}.fasta"

# --- Summary ---
echo "=== Scaffolded assembly statistics ==="
grep -c '^>' ${OUTPREFIX}.fasta
awk '/^>/{next}{sum+=length($0)}END{print "Total length:", sum, "bp"}' ${OUTPREFIX}.fasta
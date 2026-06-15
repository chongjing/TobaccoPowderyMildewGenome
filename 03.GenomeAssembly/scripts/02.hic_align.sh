#!/usr/bin/env bash
# ==============================================================================
# Step 2: Hi-C Read Alignment with bwa-mem2
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Genome Assembly & Annotation
# Tools:    bwa-mem2 v2.2.1, samtools v1.22.1
# Input:    Primary contig FASTA + Hi-C trimmed FASTQ (3 lanes, MboI digestion)
# Output:   Sorted, filtered Hi-C alignment BAM
#
# Strategic decisions:
#   - bwa-mem2 instead of bwa: 2-3x faster alignment, same accuracy for Hi-C
#   - -5SP flag: Hi-C standard paired-end mode (5' mate, singleton, paired)
#   - -F 2316 filter: remove unmapped (4), secondary (256), supplementary (2048)
#   - Sort by name (-n): required by YaHS for Hi-C pairing detection
#
# Usage:
#   export BWAMEM2=/path/to/bwa-mem2
#   export SAMTOOLS=/path/to/samtools
#   export THREADS=48
#   bash 02.hic_align.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (edit for your environment) ---
: "${BWAMEM2:=bwa-mem2}"
: "${SAMTOOLS:=samtools}"
: "${THREADS:=48}"
: "${ASSEMBLY:=../Gcichoracearum_BFJ.p_ctg.fasta}"
: "${OUTDIR:=./}"

# Hi-C trimmed FASTQ (3 lanes, MboI restriction enzyme)
HIC_DIR="/path/to/trimmed_hic"
HIC_R1="${HIC_DIR}/BFJ.2_L1_R1.fastq.gz ${HIC_DIR}/BFJ.2_L2_R1.fastq.gz ${HIC_DIR}/BFJ.2_L3_R1.fastq.gz"
HIC_R2="${HIC_DIR}/BFJ.2_L1_R2.fastq.gz ${HIC_DIR}/BFJ.2_L2_R2.fastq.gz ${HIC_DIR}/BFJ.2_L3_R2.fastq.gz"
HIC_BAM="${OUTDIR}/hic_aligned.bam"

# --- Index assembly (if not already done) ---
if [[ ! -f "${ASSEMBLY}.0123" ]]; then
  echo "[$(date)] Indexing assembly with bwa-mem2..."
  $BWAMEM2 index $ASSEMBLY
fi

# --- Align Hi-C reads ---
echo "[$(date)] Aligning Hi-C reads (3 lanes merged)..."
$BWAMEM2 mem -5SP -t $THREADS $ASSEMBLY \
  <(cat $HIC_R1) \
  <(cat $HIC_R2) \
  2>${OUTDIR}/bwa_mem2.log \
  | $SAMTOOLS view -bhS -F 2316 - \
  | $SAMTOOLS sort -n -@ 8 -o $HIC_BAM

echo "[$(date)] Alignment complete: $HIC_BAM"

# --- Alignment statistics ---
echo "=== Alignment statistics ==="
$SAMTOOLS flagstat -@ 8 $HIC_BAM
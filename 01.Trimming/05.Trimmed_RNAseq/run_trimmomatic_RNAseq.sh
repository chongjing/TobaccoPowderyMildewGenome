#!/bin/bash
# ==============================================================================
# Trimmomatic: RNAseq (PM11) — Golovinomyces cichoracearum genome project
# ==============================================================================
# Date: 2026-05-26
# Data: PM11_1 (rep1) and PM11_2 (rep2) — Illumina NovaSeq 6000, PE150
# Note: Raw Illumina data with detectable TruSeq adapter content.
#   ILLUMINACLIP with TruSeq3-PE adapters applied.
#   Same quality trimming parameters as WGS/Hi-C for consistency.
# ==============================================================================

JAVA=/home/cx264/program/jdk-11.0.30+7/bin/java
TRIMMOMATIC=/home/cx264/program/Trimmomatic-0.39/trimmomatic-0.39.jar
ADAPTERS=/home/cx264/program/Trimmomatic-0.39/adapters/TruSeq3-PE.fa

RNADIR=/home/cx264/project/03.TobaccoMildew/01.data/RNAseq
OUTDIR=/home/cx264/project/03.TobaccoMildew/00.workflow/01.Trimming/05.Trimmed_RNAseq

trim_rnaseq() {
  REP=$1
  echo "==========================================="
  echo "Trimming RNAseq PM11_$REP at $(date)"
  echo "==========================================="

  $JAVA -jar $TRIMMOMATIC PE -threads 4 -phred33 \
    $RNADIR/PM11_${REP}_1.fq.gz \
    $RNADIR/PM11_${REP}_2.fq.gz \
    $OUTDIR/PM11_${REP}_R1.fastq.gz \
    $OUTDIR/PM11_${REP}_unpaired_R1.fastq.gz \
    $OUTDIR/PM11_${REP}_R2.fastq.gz \
    $OUTDIR/PM11_${REP}_unpaired_R2.fastq.gz \
    ILLUMINACLIP:$ADAPTERS:2:30:10 \
    LEADING:5 \
    TRAILING:5 \
    SLIDINGWINDOW:4:15 \
    MINLEN:50 \
    -summary $OUTDIR/trimmomatic_PM11_${REP}_summary.log \
    2>&1 | tee $OUTDIR/trimmomatic_PM11_${REP}.log

  echo "PM11_$REP done (exit: $?)"
}

# Process both replicates
trim_rnaseq "1"
trim_rnaseq "2"

echo "==========================================="
echo "All RNAseq trimming completed at $(date)"
echo "==========================================="
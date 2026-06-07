#!/bin/bash
# ==============================================================================
# Trimmomatic: Illumina WGS — Golovinomyces cichoracearum genome project
# ==============================================================================
# Date: 2026-05-26
# Data: BFJ_WGS_L1 (paired-end, BGI DNBSEQ-T7, PE150)
# Parameter note: Data is exceptionally high quality (mean Q35+ at read end).
#   No adapter trimming needed (FastQC: adapter content PASS).
#   Minimal quality trimming applied for documentation/reproducibility.
# ==============================================================================

JAVA=/home/cx264/program/jdk-11.0.30+7/bin/java
TRIMMOMATIC=/home/cx264/program/Trimmomatic-0.39/trimmomatic-0.39.jar

RAW_R1=/home/cx264/project/03.TobaccoMildew/01.data/Illumina/BFJ_WGS_L1_1.clean.rd.fq.gz
RAW_R2=/home/cx264/project/03.TobaccoMildew/01.data/Illumina/BFJ_WGS_L1_2.clean.rd.fq.gz
OUTDIR=/home/cx264/project/03.TobaccoMildew/00.workflow/01.Trimming/01.Trimmed_WGS
LOGDIR=/home/cx264/project/03.TobaccoMildew/00.workflow/01.Trimming/01.Trimmed_WGS

OUT_R1_P=BFJ_WGS_L1_R1.fastq.gz
OUT_R1_U=BFJ_WGS_L1_unpaired_R1.fastq.gz
OUT_R2_P=BFJ_WGS_L1_R2.fastq.gz
OUT_R2_U=BFJ_WGS_L1_unpaired_R2.fastq.gz

$JAVA -jar $TRIMMOMATIC PE -threads 4 -phred33 \
  $RAW_R1 $RAW_R2 \
  $OUTDIR/$OUT_R1_P $OUTDIR/$OUT_R1_U \
  $OUTDIR/$OUT_R2_P $OUTDIR/$OUT_R2_U \
  LEADING:5 \
  TRAILING:5 \
  SLIDINGWINDOW:4:15 \
  MINLEN:50 \
  -summary $OUTDIR/trimmomatic_WGS_summary.log \
  2>&1 | tee $OUTDIR/trimmomatic_WGS.log
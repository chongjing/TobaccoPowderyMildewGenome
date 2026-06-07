#!/bin/bash
# ==============================================================================
# Trimmomatic: Hi-C (3 lanes) — Golovinomyces cichoracearum genome project
# ==============================================================================
# Date: 2026-05-26
# Enzyme: MboI (Hi-C library)
# Data: BFJ.2, 3 lanes (L1, L2, L3), BGI DNBSEQ-T7, PE150
# Note: Hi-C ligation junction filtering is handled downstream by scaffolding
#   tools (YaHS/3D-DNA). Trimmomatic handles only quality trimming here.
# ==============================================================================

JAVA=/home/cx264/program/jdk-11.0.30+7/bin/java
TRIMMOMATIC=/home/cx264/program/Trimmomatic-0.39/trimmomatic-0.39.jar

HICDIR=/home/cx264/project/03.TobaccoMildew/01.data/X101SC25057677-Z01-J007/clean_data/BFJ.2
OUTDIR=/home/cx264/project/03.TobaccoMildew/00.workflow/01.Trimming/02.Trimmed_HiC

# Function to run Trimmomatic on one lane
trim_lane() {
  LANE=$1
  echo "==========================================="
  echo "Trimming Hi-C Lane $LANE"
  echo "==========================================="

  $JAVA -jar $TRIMMOMATIC PE -threads 4 -phred33 \
    $HICDIR/BFJ.2_${LANE}_1.clean.rd.fq.gz \
    $HICDIR/BFJ.2_${LANE}_2.clean.rd.fq.gz \
    $OUTDIR/BFJ.2_${LANE}_R1.fastq.gz \
    $OUTDIR/BFJ.2_${LANE}_unpaired_R1.fastq.gz \
    $OUTDIR/BFJ.2_${LANE}_R2.fastq.gz \
    $OUTDIR/BFJ.2_${LANE}_unpaired_R2.fastq.gz \
    LEADING:5 \
    TRAILING:5 \
    SLIDINGWINDOW:4:15 \
    MINLEN:50 \
    -summary $OUTDIR/trimmomatic_${LANE}_summary.log \
    2>&1 | tee $OUTDIR/trimmomatic_${LANE}.log
  
  echo "Done Lane $LANE"
}

# Process all lanes sequentially (one per lane)
trim_lane "L1"
trim_lane "L2"
trim_lane "L3"

echo "==========================================="
echo "All Hi-C lanes trimmed"
echo "==========================================="
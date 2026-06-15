#!/bin/bash
set -euo pipefail
# ======================================================================
#  Phase 4b: Hi-C mapping rate (HiFi + RNA already done from existing BAMs)
#  Genome: ENA-submitted (Chr1-Chr11)
#  Hi-C -> bwa-mem2 mem -5SP (Hi-C standard), 3 lanes merged
# ======================================================================
WORK=/home/cx264/project/03.TobaccoMildew/06.Annotation/16.MappingRates
GENOME=/home/cx264/project/03.TobaccoMildew/07.ENA_Submit/genome/Golovinomyces_cichoracearum.scaffolds.fa
BWAMEM2=/home/cx264/program/bwa-mem2-2.2.1_x64-linux/bwa-mem2
SAMTOOLS=/home/cx264/.local/bin/samtools
THREADS=48
HIC_DIR=/home/cx264/project/03.TobaccoMildew/00.workflow/01.Trimming/02.Trimmed_HiC

cd "$WORK"

# Index genome locally (avoid touching ENA dir)
if [ ! -f genome.fa ]; then cp "$GENOME" genome.fa; fi
if [ ! -f genome.fa.bwt.2bit.64 ]; then
  echo "[$(date)] bwa-mem2 index..."
  $BWAMEM2 index genome.fa 2> bwa_index.log
fi

echo "[$(date)] Concatenating Hi-C 3 lanes..."
cat "$HIC_DIR"/BFJ.2_L1_R1.fastq.gz "$HIC_DIR"/BFJ.2_L2_R1.fastq.gz "$HIC_DIR"/BFJ.2_L3_R1.fastq.gz > hic_R1.fq.gz
cat "$HIC_DIR"/BFJ.2_L1_R2.fastq.gz "$HIC_DIR"/BFJ.2_L2_R2.fastq.gz "$HIC_DIR"/BFJ.2_L3_R2.fastq.gz > hic_R2.fq.gz

echo "[$(date)] bwa-mem2 mem -5SP (Hi-C)..."
$BWAMEM2 mem -5SP -t $THREADS genome.fa hic_R1.fq.gz hic_R2.fq.gz 2> hic_bwa.log \
  | $SAMTOOLS view -@ 8 -b - 2>/dev/null \
  | $SAMTOOLS sort -@ 8 -o hic.bam -
$SAMTOOLS flagstat -@ 8 hic.bam > hic.flagstat.txt
rm -f hic_R1.fq.gz hic_R2.fq.gz
echo "[$(date)] Hi-C done"
cat hic.flagstat.txt
echo "=== HIC DONE ==="

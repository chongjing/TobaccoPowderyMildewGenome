#!/bin/bash
# ==============================================================================
# FastQC - Step 01 (Trimming) - Golovinomyces cichoracearum (tobacco powdery mildew)
# ==============================================================================
# Documents the FastQC commands used to produce the QC reports in
#   ../00.RawQC/fastqc/   (pre-trim)   and   ../03.PostQC/fastqc/   (post-trim)
# Tool: FastQC v0.12.1 (run from the project conda environment).
#
# The original QC was run interactively; this driver records the exact inputs,
# outputs and parameters for reproducibility. FASTQ inputs are the project
# sequence data (NOT stored in git; archived at ENA, BioProject PRJEB114362).
# ==============================================================================
set -euo pipefail
THREADS=8

DATA=/home/cx264/project/03.TobaccoMildew/01.data
HICDIR=$DATA/X101SC25057677-Z01-J007/clean_data/BFJ.2
TRIM=/home/cx264/project/03.TobaccoMildew/00.workflow/01.Trimming
RAWQC=$TRIM/00.RawQC/fastqc
POSTQC=$TRIM/03.PostQC/fastqc
mkdir -p "$RAWQC" "$POSTQC"

# --- Pre-trim FastQC: raw WGS (2) + raw Hi-C 3 lanes (6) = 8 files ---
fastqc -t "$THREADS" -o "$RAWQC" \
  "$DATA/Illumina/BFJ_WGS_L1_1.clean.rd.fq.gz" \
  "$DATA/Illumina/BFJ_WGS_L1_2.clean.rd.fq.gz" \
  "$HICDIR/BFJ.2_L1_1.clean.rd.fq.gz" "$HICDIR/BFJ.2_L1_2.clean.rd.fq.gz" \
  "$HICDIR/BFJ.2_L2_1.clean.rd.fq.gz" "$HICDIR/BFJ.2_L2_2.clean.rd.fq.gz" \
  "$HICDIR/BFJ.2_L3_1.clean.rd.fq.gz" "$HICDIR/BFJ.2_L3_2.clean.rd.fq.gz"

# --- Post-trim FastQC: trimmed WGS (2) + trimmed Hi-C 3 lanes (6) = 8 files ---
fastqc -t "$THREADS" -o "$POSTQC" \
  "$TRIM/01.Trimmed_WGS/BFJ_WGS_L1_R1.fastq.gz" \
  "$TRIM/01.Trimmed_WGS/BFJ_WGS_L1_R2.fastq.gz" \
  "$TRIM/02.Trimmed_HiC/BFJ.2_L1_R1.fastq.gz" "$TRIM/02.Trimmed_HiC/BFJ.2_L1_R2.fastq.gz" \
  "$TRIM/02.Trimmed_HiC/BFJ.2_L2_R1.fastq.gz" "$TRIM/02.Trimmed_HiC/BFJ.2_L2_R2.fastq.gz" \
  "$TRIM/02.Trimmed_HiC/BFJ.2_L3_R1.fastq.gz" "$TRIM/02.Trimmed_HiC/BFJ.2_L3_R2.fastq.gz"

# Note: RNA-seq (PM11) FastQC was not part of this aggregate; RNA-seq read QC is
# captured by the Trimmomatic summary logs in ../05.Trimmed_RNAseq/.

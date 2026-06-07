#!/bin/bash
# ==============================================================================
# Genome Profiling: KMC + GenomeScope — Golovinomyces cichoracearum
# ==============================================================================
# Date: 2026-05-26
# Input: Trimmed WGS R1 reads (118,875,320 reads, PE150)
# Tools: KMC v3.2.4, kmc_tools, GenomeScope2 R script
# Plan:
#   1. KMC k=21 counting (primary estimate)
#   2. kmc_tools histogram generation
#   3. GenomeScope2 model fitting (haploid, -p 1)
#   4. KMC k=31 counting (validation)
#   5. kmc_tools histogram + GenomeScope for k=31
#   6. Compile summary report
# ==============================================================================

KMC=/home/cx264/program/KMC3.2.4/bin/kmc
KMC_TOOLS=/home/cx264/program/KMC3.2.4/bin/kmc_tools
GENOMESCOPE=/home/cx264/program/genomescope2.0/genomescope.R
RSCRIPT=/home/cx264/program/anaconda3/envs/R4.4.3/bin/Rscript

PROFILES_DIR=/home/cx264/project/03.TobaccoMildew/00.workflow/02.GenomeProfiling
FILES_LIST=$PROFILES_DIR/files_list_R1.txt

THREADS=16
MEM_GB=128

echo "==========================================="
echo "Step 2a: KMC k=21 counting"
echo "Started: $(date)"
echo "==========================================="

$KMC -k21 -m${MEM_GB} -t${THREADS} -fq -ci1 -cs1000000 \
  @$FILES_LIST \
  $PROFILES_DIR/kmc_21mer/kmc_db/bfj_wgs_k21 \
  $PROFILES_DIR/kmc_21mer/kmc_temp/ \
  2>&1 | tee $PROFILES_DIR/kmc_21mer/kmc_k21.log

echo "KMC k=21 exit: $?"
echo ""

echo "==========================================="
echo "Step 2b: kmc_tools histogram (k=21)"
echo "Started: $(date)"
echo "==========================================="

$KMC_TOOLS -t${THREADS} transform \
  $PROFILES_DIR/kmc_21mer/kmc_db/bfj_wgs_k21 \
  histogram $PROFILES_DIR/kmc_21mer/histogram_k21.txt \
  2>&1 | tee -a $PROFILES_DIR/kmc_21mer/kmc_k21.log

echo "Histogram exit: $?"
echo ""

echo "==========================================="
echo "Step 2c: GenomeScope (k=21, haploid)"
echo "Started: $(date)"
echo "==========================================="

$RSCRIPT $GENOMESCOPE \
  -i $PROFILES_DIR/kmc_21mer/histogram_k21.txt \
  -o $PROFILES_DIR/genomescope_21mer/ \
  -p 1 \
  -k 21 \
  -n "Gcichoracearum" \
  --json_report \
  2>&1 | tee $PROFILES_DIR/genomescope_21mer/genomescope_k21.log

echo "GenomeScope k=21 exit: $?"
echo ""

# ============================================
# Validation: k=31
# ============================================

echo "==========================================="
echo "Step 2d: KMC k=31 counting (validation)"
echo "Started: $(date)"
echo "==========================================="

$KMC -k31 -m${MEM_GB} -t${THREADS} -fq -ci1 -cs1000000 \
  @$FILES_LIST \
  $PROFILES_DIR/kmc_31mer/kmc_db/bfj_wgs_k31 \
  $PROFILES_DIR/kmc_31mer/kmc_temp/ \
  2>&1 | tee $PROFILES_DIR/kmc_31mer/kmc_k31.log

echo "KMC k=31 exit: $?"
echo ""

echo "==========================================="
echo "Step 2e: kmc_tools histogram (k=31)"
echo "Started: $(date)"
echo "==========================================="

$KMC_TOOLS -t${THREADS} transform \
  $PROFILES_DIR/kmc_31mer/kmc_db/bfj_wgs_k31 \
  histogram $PROFILES_DIR/kmc_31mer/histogram_k31.txt \
  2>&1 | tee -a $PROFILES_DIR/kmc_31mer/kmc_k31.log

echo "Histogram exit: $?"
echo ""

echo "==========================================="
echo "Step 2f: GenomeScope (k=31, haploid)"
echo "Started: $(date)"
echo "==========================================="

$RSCRIPT $GENOMESCOPE \
  -i $PROFILES_DIR/kmc_31mer/histogram_k31.txt \
  -o $PROFILES_DIR/genomescope_31mer/ \
  -p 1 \
  -k 31 \
  -n "Gcichoracearum" \
  --json_report \
  2>&1 | tee $PROFILES_DIR/genomescope_31mer/genomescope_k31.log

echo "GenomeScope k=31 exit: $?"
echo ""

echo "==========================================="
echo "All profiling complete at $(date)"
echo "==========================================="
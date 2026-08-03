#!/bin/bash
set -euo pipefail
# ======================================================================
#  Secreted Protein (Effector) Identification Pipeline
#  Organism: Golovinomyces cichoracearum (powdery mildew)
#  Input: Funannotate PASA-updated protein set (11,677 sequences)
#  Steps:
#    1. SignalP6     → Predict signal peptides (SP)
#    2. DeepTMHMM    → Predict transmembrane domains (TM)
#    3. Merge & Filter → SP+ AND TM-  = secreted protein candidates
#  Outputs:
#    results/03.SP.list              – Protein IDs with signal peptide
#    results/03.SP.protein.faa       – FASTA of SP-containing proteins
#    results/04.SP.secreted.list     – Protein IDs: SP+ AND no TM domain
#    results/04.SP.secreted.faa      – FASTA of secreted protein candidates
#    results/04.SP.with_TMHMM_types.tsv – All SP+ with topology class
#    results/04.TMHMM.types.mapping.tsv – DeepTMHMM type mapping
#    results/pipeline_stats.txt      – Summary statistics
# ======================================================================

# ---- Portable defaults ----
# All paths can be overridden via environment variables. Defaults point to the
# original Dr. Xia project workspace used to generate the published outputs.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKDIR=$(cd "${SCRIPT_DIR}/.." && pwd)
BASE_DIR="${BASE_DIR:-$WORKDIR}"
OUT="${BASE_DIR}/results"
SIGNALP_DIR="${BASE_DIR}/signalp"
DEEPTMHMM_DIR="${BASE_DIR}/DeepTMHMM"
LOG_DIR="${BASE_DIR}/logs"

# Input: protein FASTA from Funannotate PASA-update
PREDICT_DIR="${PREDICT_DIR:-/home/cx264/project/03.TobaccoMildew/06.Annotation/05b.FunannotatePredict/update_results}"
PROTEIN_FA="${PROTEIN_FA:-${PREDICT_DIR}/Golovinomyces_cichoracearum.proteins.fa}"

# Tool paths
SIGNALP6="${SIGNALP6:-/home/cx264/program/anaconda3/envs/python3.7.12/bin/signalp6}"
SIGNALP6_MODEL="${SIGNALP6_MODEL:-/home/cx264/program/signalp6_fast/signalp-6-package/models}"
DEEPTMHMM_PY="${DEEPTMHMM_PY:-/home/cx264/program/miniforge3/envs/python3.8/bin/python3}"
DEEPTMHMM_SCRIPT="${DEEPTMHMM_SCRIPT:-/home/cx264/program/DeepTMHMM/DeepTMHMM-Academic-License-v1.0/predict.py}"
SEQKIT="${SEQKIT:-/home/cx264/.local/bin/seqkit}"

mkdir -p "$OUT" "$SIGNALP_DIR" "$DEEPTMHMM_DIR" "$LOG_DIR"
cd "$BASE_DIR"

echo "================================================"
echo " Secreted Protein Pipeline — G. cichoracearum"
echo " (PASA-updated proteins)"
echo " Starting at: $(date)"
echo "================================================"

# ------------------------------------------------------------------
# Step 1: SignalP6
# ------------------------------------------------------------------
echo ""
echo "[Step 1/4] SignalP6 — predicting signal peptides"

export JAVA_HOME=/home/cx264/program/jdk-25.0.2/
export LD_LIBRARY_PATH=/home/cx264/program/anaconda3/envs/python3.7.12/lib:$LD_LIBRARY_PATH

"${SIGNALP6}" \
    --fastafile "${PROTEIN_FA}" \
    --output_dir "${SIGNALP_DIR}" \
    --format none \
    --organism euk \
    --mode fast \
    --model_dir "${SIGNALP6_MODEL}"

echo "  [Step 1] SignalP6 completed at $(date)"

# ------------------------------------------------------------------
# Step 2: Extract SP-containing proteins (score > 0.8)
# ------------------------------------------------------------------
echo ""
echo "[Step 2/4] Extracting proteins with signal peptide (score > 0.8)"

awk -F"\t" 'NR>1 && $3 == "signal_peptide" && $6+0 > 0.8 {print $1}' \
    "${SIGNALP_DIR}/output.gff3" | \
    awk -F" " '{print $1}' | sort -u \
    > "${OUT}/03.SP.list"

SP_COUNT=$(wc -l < "${OUT}/03.SP.list")
echo "  Found: ${SP_COUNT} proteins with signal peptide"

"${SEQKIT}" grep \
    --by-name \
    --pattern-file "${OUT}/03.SP.list" \
    --use-regexp \
    --out-file "${OUT}/03.SP.protein.faa" \
    "${PROTEIN_FA}"

echo "  Extracted: $(grep -c '^>' "${OUT}/03.SP.protein.faa") sequences"

# ------------------------------------------------------------------
# Step 3: DeepTMHMM
# ------------------------------------------------------------------
echo ""
echo "[Step 3/4] DeepTMHMM — predicting transmembrane domains"

rm -rf "${DEEPTMHMM_DIR}"

DEEPTMHMM_ROOT=$(dirname "$(dirname "$DEEPTMHMM_SCRIPT")")
cd "${DEEPTMHMM_ROOT}"

"${DEEPTMHMM_PY}" "${DEEPTMHMM_SCRIPT}" \
    --fasta "${OUT}/03.SP.protein.faa" \
    --output-dir "${DEEPTMHMM_DIR}"

cd "${BASE_DIR}"
echo "  [Step 3] DeepTMHMM completed at $(date)"

# ------------------------------------------------------------------
# Step 4: Filter — SP+ only, remove TM-containing
# ------------------------------------------------------------------
echo ""
echo "[Step 4/4] Filtering: keep secreted (SP+, no TM domain)"

awk '/^>/ {id=$1; gsub("^>", "", id); type=$NF; print id "\t" type}' \
    "${DEEPTMHMM_DIR}/predicted_topologies.3line" \
    > "${OUT}/04.TMHMM.types.mapping.tsv"

awk -F"\t" 'NR==FNR {map[$1]=$2; next} $1 in map {print $1 "\t" map[$1]}' \
    "${OUT}/04.TMHMM.types.mapping.tsv" \
    "${OUT}/03.SP.list" \
    > "${OUT}/04.SP.with_TMHMM_types.tsv"

awk -F"\t" '$2 == "SP" {print $1}' "${OUT}/04.SP.with_TMHMM_types.tsv" \
    > "${OUT}/04.SP.secreted.list"

SECRETED_COUNT=$(wc -l < "${OUT}/04.SP.secreted.list")

"${SEQKIT}" grep \
    --by-name \
    --pattern-file "${OUT}/04.SP.secreted.list" \
    --use-regexp \
    --out-file "${OUT}/04.SP.secreted.faa" \
    "${OUT}/03.SP.protein.faa"

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
TOTAL_PROTEINS=$(grep -c "^>" "${PROTEIN_FA}")
SP_ONLY=$(awk -F"\t" '$2 == "SP" {print $1}' "${OUT}/04.SP.with_TMHMM_types.tsv" | wc -l)
SP_TM=$(awk -F"\t" '$2 == "SP+TM" {print $1}' "${OUT}/04.SP.with_TMHMM_types.tsv" | wc -l)
TM_ONLY=$(awk -F"\t" '$2 == "TM" {print $1}' "${OUT}/04.SP.with_TMHMM_types.tsv" | wc -l)
GLOB=$(awk -F"\t" '$2 == "GLOB" {print $1}' "${OUT}/04.SP.with_TMHMM_types.tsv" | wc -l)

echo ""
echo "================================================"
echo " PIPELINE SUMMARY"
echo "================================================"
echo "  Total predicted proteins: ${TOTAL_PROTEINS}"
echo "  With signal peptide (SP+): ${SP_COUNT}"
echo "  └─ SP only (secreted):     ${SP_ONLY}"
echo "  └─ SP + TM domain:         ${SP_TM}"
echo "  └─ TM only (no SP):        ${TM_ONLY}"
echo "  └─ Globular (no SP, no TM): ${GLOB}"
echo "  Secreted candidates: ${SECRETED_COUNT}"
echo "  Completed at: $(date)"
echo "================================================"

cat > "${OUT}/pipeline_stats.txt" << EOF
Secreted Protein Pipeline — G. cichoracearum (PASA-updated)
Date: $(date)
---
Total predicted proteins:    ${TOTAL_PROTEINS}
SignalP6 SP+ (score>0.8):   ${SP_COUNT}
  SP only (secreted):        ${SP_ONLY}
  SP + TM:                   ${SP_TM}
  TM only:                   ${TM_ONLY}
  Globular:                  ${GLOB}
Secreted candidates (output): ${SECRETED_COUNT}
EOF
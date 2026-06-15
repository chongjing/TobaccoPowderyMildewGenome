#!/usr/bin/env bash
# ==============================================================================
# Step 3: Funannotate predict — Structural Gene Annotation
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Gene Annotation
# Tool:     Funannotate v1.8.17 (Apptainer/Singularity container)
# Input:    Repeat-soft-masked genome + RNA-seq BAM + StringTie GTF + proteins
# Output:   predict_results/ with GFF3, proteins, CDS, mRNA, GBK, TBL
#
# Evidence sources:
#   - Transcript: RNA-seq BAM (weight 10) + StringTie GTF (weight 10)
#   - Protein: combined Gc (6,532) + Bgt (8,347) = 14,879 sequences (weight 1)
#   - Ab initio: Augustus (3), SNAP (1), GlimmerHMM (1), CodingQuarry (2)
#
# Strategic decisions:
#   - Repeat-masked genome (81.91% masked): removes TE-derived false gene models
#   - --max_intronlen 3000: conservative for fungi (typical: 50-200 bp)
#   - --organism fungus: enables CodingQuarry + fungal-optimised parameters
#   - BUSCO training: all 4 predictors trained on ascomycota_odb10 markers
#   - GeneMark excluded: non-functional in container environment
#   - Transcript weighted 10× over ab initio: RNA evidence is most reliable
#
# Usage:
#   export PROJECT_ROOT=/path/to/project
#   export CONTAINER=/path/to/funannotate.v2.sif
#   export BUSCO_DB=/path/to/ascomycota_odb10
#   export CPUS=48
#   bash 03.funannotate_predict.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (set before running) ---
: "${PROJECT_ROOT:=.}"
: "${CONTAINER:=funannotate.v2.sif}"
: "${BUSCO_DB:=ascomycota_odb10}"
: "${CPUS:=48}"

# Input files
: "${GENOME:=${PROJECT_ROOT}/genome.masked.fa}"
: "${RNA_BAM:=${PROJECT_ROOT}/alignments/merged.bam}"
: "${STRINGTIE:=${PROJECT_ROOT}/transcripts/transcripts.gtf}"
: "${PROTEINS:=${PROJECT_ROOT}/protein_evidence/combined_proteins.faa}"
: "${OUTDIR:=${PROJECT_ROOT}}"

# --- Run funannotate predict ---
# The genome, BAM, GTF and protein paths are passed as container-internal paths
# (-B bind-mount) so the paths must be accessible inside the container.
echo "[$(date)] Starting funannotate predict..."
echo "  Genome: ${GENOME}"
echo "  RNA BAM: ${RNA_BAM}"
echo "  StringTie: ${STRINGTIE}"
echo "  Proteins: ${PROTEINS}"
echo "  Output: ${OUTDIR}"
echo "  BUSCO DB: ${BUSCO_DB}"
echo ""

singularity exec \
  -B "${PROJECT_ROOT}:${PROJECT_ROOT}" \
  -B "$(dirname ${BUSCO_DB}):/opt/databases" \
  "${CONTAINER}" /venv/bin/funannotate predict \
  -i "${GENOME}" \
  -o "${OUTDIR}" \
  -s "Golovinomyces_cichoracearum" \
  --organism fungus \
  --rna_bam "${RNA_BAM}" \
  --stringtie "${STRINGTIE}" \
  --protein_evidence "${PROTEINS}" \
  --weights augustus:3 \
  --weights transcripts:10 \
  --min_training_models 150 \
  --max_intronlen 3000 \
  --busco_db "${BUSCO_DB}" \
  --cpus "${CPUS}"

echo "[$(date)] === FUNANNOTATE PREDICT DONE ==="
echo "Results: ${OUTDIR}/predict_results/"
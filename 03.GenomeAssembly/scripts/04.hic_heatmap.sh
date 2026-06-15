#!/usr/bin/env bash
# ==============================================================================
# Step 4: Hi-C Contact Map (Heatmap) Visualisation
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Genome Assembly & Annotation
# Tools:    juicer_tools v1.22.01
# Input:    YaHS .bin file + assembly FASTA index (.fai)
# Output:   Juicebox .hic file → SVG heatmap via Juicer pre
#
# The .hic file can be opened in Juicebox (https://aidenlab.org/juicebox/)
# for interactive exploration of the Hi-C contact matrix.
# For publication-quality figures, the .hic file can be plotted with
# R/circlize (see 04.circos/ in this repository).
#
# Usage:
#   export JUICER_JAR=/path/to/juicer_tools.jar
#   export ASSEMBLY_FAI=../Gcichoracearum_BFJ.p_ctg.fasta.fai
#   bash 04.hic_heatmap.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (edit for your environment) ---
: "${JUICER_JAR:=juicer_tools.jar}"
: "${YAHS_BIN:=../Gcichoracearum_BFJ_scaffolds.bin}"
: "${ASSEMBLY_FAI:=../Gcichoracearum_BFJ.p_ctg.fasta.fai}"
: "${OUTDIR:=./}"
: "${OUTPREFIX:=${OUTDIR}/Gcichoracearum_BFJ_scaffolds}"

# --- Generate Juicebox .hic file ---
if [[ -f "$YAHS_BIN" && -f "$JUICER_JAR" ]]; then
  echo "[$(date)] Generating Juicebox .hic file..."
  java -Xmx4G -jar $JUICER_JAR pre \
    $YAHS_BIN \
    ${OUTPREFIX}.hic \
    $ASSEMBLY_FAI \
    2>&1 | tee -a ${OUTDIR}/juicer_pre.log
  echo "  .hic file: ${OUTPREFIX}.hic"
else
  echo "WARNING: Cannot generate .hic file."
  echo "  YaHS .bin: $([ -f "$YAHS_BIN" ] && echo 'found' || echo 'NOT found')"
  echo "  juicer_tools: $([ -f "$JUICER_JAR" ] && echo 'found' || echo 'NOT found')"
  echo ""
  echo "  To generate .hic manually, install juicer_tools from:"
  echo "  https://github.com/aidenlab/juicer/releases"
  echo "  Then run:"
  echo "    java -Xmx4G -jar juicer_tools.jar pre \\"
  echo "      ${YAHS_BIN} \\"
  echo "      ${OUTPREFIX}.hic \\"
  echo "      ${ASSEMBLY_FAI}"
  exit 1
fi

echo "[$(date)] Hi-C heatmap generation complete: ${OUTPREFIX}.hic"
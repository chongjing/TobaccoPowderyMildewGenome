#!/usr/bin/env bash
# ==============================================================================
# Step 6: Contig Renaming (contig_1-11 → Chr1-11)
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Genome Assembly & Annotation
# Input:    YaHS-scaffolded FASTA with default contig names (contig_1..contig_N)
# Output:   Renamed FASTA with chromosomes named Chr1-Chr11 by decreasing length
#
# The eleven largest contigs correspond to the eleven chromosomes.
# This script renames them Chr1-Chr11 (by decreasing length) and preserves
# the remaining contigs with their original contig_X names for ENA submission.
#
# Also generates a mapping file: contig_to_chr_mapping.tsv
#
# Usage:
#   bash 06.contig_rename.sh
# ==============================================================================

set -euo pipefail

# --- Configuration ---
: "${ASSEMBLY:=../Gcichoracearum_BFJ_scaffolds.fasta}"
: "${OUTDIR:=./}"

# Count all contigs sorted by length (descending)
echo "=== Contig lengths (sorted) ==="
awk '/^>/{if(name) print name, len; name=$1; sub(">","",name); len=0; next}{len+=length($0)}END{print name, len}' \
  $ASSEMBLY | sort -k2 -rn > ${OUTDIR}/contig_lengths.txt

head -15 ${OUTDIR}/contig_lengths.txt
echo "  ... (total contigs: $(wc -l < ${OUTDIR}/contig_lengths.txt))"

# --- Rename top 11 contigs to Chr1-Chr11 ---
echo ""
echo "=== Renaming top 11 contigs to Chr1-Chr11 ==="

# Build sed command for renaming
SED_CMD=""
CHR_NUM=1
while read name length; do
  if [[ $CHR_NUM -le 11 ]]; then
    echo "  $name (${length} bp) → Chr${CHR_NUM}"
    SED_CMD="${SED_CMD}s/^>${name}$/>Chr${CHR_NUM}/;"
    SED_CMD="${SED_CMD}s/\t${name}\t/\tChr${CHR_NUM}\t/g;"  # for GFF3/GFA consistency
    ((CHR_NUM++))
  fi
done < <(head -11 ${OUTDIR}/contig_lengths.txt)

# Apply renaming to FASTA
sed "$SED_CMD" $ASSEMBLY > ${OUTDIR}/Gcichoracearum_BFJ_chromosomes.fasta

echo ""
echo "=== Renamed assembly: ${OUTDIR}/Gcichoracearum_BFJ_chromosomes.fasta ==="
grep -c '^>' ${OUTDIR}/Gcichoracearum_BFJ_chromosomes.fasta
echo "  Chr prefix count: $(grep -c '^>Chr' ${OUTDIR}/Gcichoracearum_BFJ_chromosomes.fasta)"
echo "  contig_ prefix count: $(grep -c '^>contig_' ${OUTDIR}/Gcichoracearum_BFJ_chromosomes.fasta)"

# --- Generate mapping file ---
echo "contig_name	chr_name	length_bp" > ${OUTDIR}/contig_to_chr_mapping.tsv
CHR_NUM=1
while read name length; do
  if [[ $CHR_NUM -le 11 ]]; then
    echo -e "${name}\tChr${CHR_NUM}\t${length}"
    ((CHR_NUM++))
  else
    echo -e "${name}\t${name}\t${length}"
  fi
done < ${OUTDIR}/contig_lengths.txt >> ${OUTDIR}/contig_to_chr_mapping.tsv

echo ""
echo "=== Mapping file: ${OUTDIR}/contig_to_chr_mapping.tsv ==="
echo "Use this file to map between ENA accession, contig name, and chromosome name."
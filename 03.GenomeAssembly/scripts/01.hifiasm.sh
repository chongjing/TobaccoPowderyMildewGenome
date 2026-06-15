#!/usr/bin/env bash
# ==============================================================================
# Step 1: HiFi Genome Assembly with hifiasm
# ==============================================================================
# Project:  Golovinomyces cichoracearum BFJ — Genome Assembly & Annotation
# Tool:     hifiasm v0.25.0
# Input:    PacBio Revio HiFi BAM files (5 SMRT cells, 10.3 Gb, N50 ~19.9 kb)
# Output:   Primary contigs (.p_ctg.gfa) for downstream scaffolding
#
# Strategic decisions:
#   - NO Hi-C phasing (--h1/--h2): haploid genome, 0% heterozygosity
#   - NO haplotig purging (-l 0): nothing to purge in haploid assembly
#   - BAM input directly: hifiasm v0.25.0 supports PacBio CCS BAM natively
#   - --primary flag: output primary + alternate assemblies
#   - --hg-size 140m: from k-mer profiling (GenomeScope, ~137-144 Mb)
#
# Usage:
#   export HIFIASM=/path/to/hifiasm
#   export THREADS=48
#   bash 01.hifiasm.sh
# ==============================================================================

set -euo pipefail

# --- Configuration (edit for your environment) ---
: "${HIFIASM:=hifiasm}"
: "${THREADS:=48}"
: "${OUTDIR:=./}"
: "${OUTPREFIX:=${OUTDIR}/Gcichoracearum_BFJ}"

# --- Input HiFi BAM files ---
# 5 SMRT cells: 3 from batch 1 (X101SC25057677-Z01-J002) + 2 from batch 2 (X101SC25057677-Z01-J006)
HIFI_BAMS=(
  "path/to/FPAC25H002823-1A/ill.hifi_reads.bam"
  "path/to/FPAC25H003170-1A/ill.hifi_reads.bam"
  "path/to/FPAC25H003361-1A/ill.hifi_reads.bam"
  "path/to/BFJ.1/FPAC26H000089-1A/BFJ.1.hifi_reads.bam"
  "path/to/BFJ.1/FPAC26H000489-1A/BFJ.1.hifi_reads.bam"
)

# --- Run hifiasm ---
# Parameters:
#   -o PREFIX    : output file prefix
#   -t THREADS   : CPU threads
#   --primary    : output primary + alternate assemblies
#   --hg-size 140m : estimated haploid genome size (from k-mer profiling)
$HIFIASM -o ${OUTPREFIX} \
  -t $THREADS \
  --primary \
  --hg-size 140m \
  "${HIFI_BAMS[@]}" \
  2>&1 | tee ${OUTPREFIX}.hifiasm.log

# --- Extract primary contig FASTA from GFA ---
awk '/^S/{print ">"$2; print $3}' ${OUTPREFIX}.p_ctg.gfa > ${OUTPREFIX}.p_ctg.fasta

echo "Assembly complete. Primary contigs: ${OUTPREFIX}.p_ctg.fasta"

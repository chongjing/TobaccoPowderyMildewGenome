#!/bin/bash
# ==============================================================================
# MultiQC - Step 01 (Trimming) - Golovinomyces cichoracearum
# ==============================================================================
# Aggregates the FastQC reports into the pre- and post-trim MultiQC reports in
#   ../00.RawQC/multiqc/multiqc_raw.html
#   ../03.PostQC/multiqc/multiqc_trimmed.html
# Tool: MultiQC v1.35. Run after run_fastqc.sh.
# ==============================================================================
set -euo pipefail
TRIM=/home/cx264/project/03.TobaccoMildew/00.workflow/01.Trimming

# Pre-trim aggregate
multiqc "$TRIM/00.RawQC/fastqc" -o "$TRIM/00.RawQC/multiqc" -n multiqc_raw.html

# Post-trim aggregate
multiqc "$TRIM/03.PostQC/fastqc" -o "$TRIM/03.PostQC/multiqc" -n multiqc_trimmed.html

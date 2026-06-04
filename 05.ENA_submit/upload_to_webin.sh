#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ENA FTP Upload Script
# Project: PRJEB114362 (Tobacco powdery mildew genome)
# Total: ~46 GB (13 files)
#
# Uploads all data files to ENA Webin FTP server.
# Files are uploaded to: ftp://webin2.ebi.ac.uk/webin-cli/reads/<NAME>/
#
# Usage:
#   bash upload_to_webin.sh
#
# Estimated time: 30-60 min at 20-37 MB/s (depends on network)
# ============================================================

WEBIN_USER="Webin-69760"
WEBIN_PASS="Xia05578678409!"
FTP_BASE="ftp://webin2.ebi.ac.uk/webin-cli/reads"

# Data source directories
HIFI_DIR="/home/cx264/project/03.TobaccoMildew/01.data/HiFi/Data-X101SC25057677-Z01-J002/ill/Sequel-Revio"
HIC_DIR="/home/cx264/project/03.TobaccoMildew/01.data/X101SC25057677-Z01-J007/clean_data/BFJ.2"
RNASEQ_DIR="/home/cx264/project/03.TobaccoMildew/01.data/RNAseq"

# Upload one file with retry
upload_file() {
    local local_file="$1"
    local remote_name="$2"
    local exp_name="$3"
    local size_hint="$4"

    local remote_url="${FTP_BASE}/${exp_name}/${remote_name}"

    echo "=== ${exp_name}: ${remote_name} (${size_hint}) ==="
    if curl -T "${local_file}" \
        --retry 5 --retry-delay 30 \
        --connect-timeout 60 --max-time 7200 \
        --ftp-create-dirs \
        "${remote_url}" \
        --user "${WEBIN_USER}:${WEBIN_PASS}"; then
        echo "=== DONE ==="
    else
        echo "=== FAILED ==="
        return 1
    fi
}

# ============================================================
# HiFi BAMs (3 SMRT cells, ~28 GB total)
# ============================================================
upload_file "${HIFI_DIR}/FPAC25H002823-1A/ill.hifi_reads.bam" \
    "FPAC25H002823-1A.ill.hifi_reads.bam" "HiFi_2823" "12 GB"

upload_file "${HIFI_DIR}/FPAC25H003170-1A/ill.hifi_reads.bam" \
    "FPAC25H003170-1A.ill.hifi_reads.bam" "HiFi_3170" "9.5 GB"

upload_file "${HIFI_DIR}/FPAC25H003361-1A/ill.hifi_reads.bam" \
    "FPAC25H003361-1A.ill.hifi_reads.bam" "HiFi_3361" "6.9 GB"

# ============================================================
# Hi-C FASTQs (3 paired sets, ~8.6 GB total)
# ============================================================
upload_file "${HIC_DIR}/BFJ.2_L1_1.clean.rd.fq.gz" \
    "BFJ.2_L1_1.clean.rd.fq.gz" "HiC_L1" "2.9 GB"
upload_file "${HIC_DIR}/BFJ.2_L1_2.clean.rd.fq.gz" \
    "BFJ.2_L1_2.clean.rd.fq.gz" "HiC_L1" "2.9 GB"

upload_file "${HIC_DIR}/BFJ.2_L2_1.clean.rd.fq.gz" \
    "BFJ.2_L2_1.clean.rd.fq.gz" "HiC_L2" "781 MB"
upload_file "${HIC_DIR}/BFJ.2_L2_2.clean.rd.fq.gz" \
    "BFJ.2_L2_2.clean.rd.fq.gz" "HiC_L2" "855 MB"

upload_file "${HIC_DIR}/BFJ.2_L3_1.clean.rd.fq.gz" \
    "BFJ.2_L3_1.clean.rd.fq.gz" "HiC_L3" "609 MB"
upload_file "${HIC_DIR}/BFJ.2_L3_2.clean.rd.fq.gz" \
    "BFJ.2_L3_2.clean.rd.fq.gz" "HiC_L3" "606 MB"

# ============================================================
# RNA-seq FASTQs (2 paired sets, ~9 GB total)
# ============================================================
upload_file "${RNASEQ_DIR}/PM11_1_1.fq.gz" \
    "PM11_1_1.fq.gz" "RNAseq_PM11_1" "2.2 GB"
upload_file "${RNASEQ_DIR}/PM11_1_2.fq.gz" \
    "PM11_1_2.fq.gz" "RNAseq_PM11_1" "2.2 GB"

upload_file "${RNASEQ_DIR}/PM11_2_1.fq.gz" \
    "PM11_2_1.fq.gz" "RNAseq_PM11_2" "2.3 GB"
upload_file "${RNASEQ_DIR}/PM11_2_2.fq.gz" \
    "PM11_2_2.fq.gz" "RNAseq_PM11_2" "2.3 GB"

echo ""
echo "========================================"
echo "All 13 files uploaded successfully."
echo "========================================"

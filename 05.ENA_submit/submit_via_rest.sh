#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ENA REST API Submission Script
# Project: PRJEB114362 (Tobacco powdery mildew genome)
#
# Submits pre-generated XMLs via multipart POST to ENA drop-box.
# Run AFTER all files are uploaded via upload_to_webin.sh.
#
# Usage:
#   cd 05.ENA_submit
#   bash submit_via_rest.sh
#
# Each submission returns success="true" with accession numbers.
# ============================================================

WEBIN_USER="Webin-69760"
WEBIN_PASS="Xia05578678409!"
REST_URL="https://www.ebi.ac.uk/ena/submit/drop-box/submit/"
XML_DIR="ena_xmls"

# Experiments to submit (order: RNA-seq first, then Hi-C, then HiFi)
EXPERIMENTS=(
    RNAseq_PM11_1
    RNAseq_PM11_2
    HiC_L1
    HiC_L2
    HiC_L3
    HiFi_2823
    HiFi_3170
    HiFi_3361
)

echo "========================================="
echo "ENA REST API Submission"
echo "Project: PRJEB114362"
echo "========================================="
echo ""

for exp in "${EXPERIMENTS[@]}"; do
    dir="${XML_DIR}/${exp}"
    sub_xml="${dir}/submission.xml"
    exp_xml="${dir}/experiment.xml"
    run_xml="${dir}/run.xml"

    if [[ ! -f "$sub_xml" || ! -f "$exp_xml" || ! -f "$run_xml" ]]; then
        echo "ERROR: Missing XMLs for ${exp}, skipping."
        continue
    fi

    echo "--- Submitting ${exp} ---"
    response=$(curl -s -u "${WEBIN_USER}:${WEBIN_PASS}" \
        -F "SUBMISSION=@${sub_xml}" \
        -F "EXPERIMENT=@${exp_xml}" \
        -F "RUN=@${run_xml}" \
        "${REST_URL}")

    echo "Response: ${response}"

    # Check for success
    if echo "${response}" | grep -q 'success="true"'; then
        echo "SUCCESS: ${exp} submitted."
    else
        echo "WARNING: ${exp} may have failed. Check response above."
    fi
    echo ""
done

echo "========================================="
echo "Submission complete. Check responses above."
echo "========================================="

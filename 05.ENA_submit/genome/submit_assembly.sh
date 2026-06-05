#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ENA Genome Assembly Submission Script
# Project: PRJEB114362 (Tobacco powdery mildew genome)
# Assembly: Golovinomyces_cichoracearum_BFJ
#
# Two paths:
#   Path A: Webin-CLI (recommended - handles everything)
#   Path B: curl FTP + REST API (fallback if FTP timeout)
# ============================================================

WEBIN_USER="Webin-69760"
WEBIN_PASS="Xia05578678409!"
JAR="$HOME/rds/rds-csc_programmes-FTKWLWDeHys/programs/webin-cli/webin-cli-9.0.3.jar"
JAVA="/rds/project/rds-FTKWLWDeHys/programs/java/jdk-17.0.10/bin/java"

GBK="Golovinomyces_cichoracearum.gbk"
GBK_SIZE="222 MB"

# ============================================================
# Path A: Webin-CLI (validate + submit in one go)
# ============================================================
echo "========================================="
echo "Path A: Webin-CLI Genome Submission"
echo "========================================="
echo ""
echo "Manifest: assembly.manifest.txt"
echo ""
echo "Run:"
echo "  ${JAVA} -jar ${JAR} -context genome \\"
echo "    -manifest assembly.manifest.txt \\"
echo "    -userName ${WEBIN_USER} -password XXXXX \\"
echo "    -outputDir ./webin_out -validate"
echo ""
echo "Then submit:"
echo "  ${JAVA} -jar ${JAR} -context genome \\"
echo "    -manifest assembly.manifest.txt \\"
echo "    -userName ${WEBIN_USER} -password XXXXX \\"
echo "    -outputDir ./webin_out -submit"
echo ""

# ============================================================
# Path B: curl FTP upload + REST API (alternative)
# ============================================================
echo "========================================="
echo "Path B: curl FTP + REST API (fallback)"
echo "========================================="
echo ""
echo "Step 1: Upload GBK to FTP"
echo "  curl -T \"${GBK}\" \\"
echo "    --retry 5 --retry-delay 30 \\"
echo "    --connect-timeout 60 --max-time 7200 \\"
echo "    --ftp-create-dirs \\"
echo "    \"ftp://webin2.ebi.ac.uk/webin-cli/genome/Golovinomyces_cichoracearum_BFJ/${GBK}\" \\"
echo "    --user \"${WEBIN_USER}:XXXXX\""
echo ""
echo "Step 2: Submit via REST API (TODO - needs genome XMLs)"

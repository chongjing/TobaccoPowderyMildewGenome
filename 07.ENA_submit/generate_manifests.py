#!/usr/bin/env python3
"""
Generate webin-cli manifest files from metadata_template.tsv.

Handles three data types:
  - PacBio HiFi BAM (SINGLE layout)
  - Hi-C paired FASTQ (PAIRED layout)
  - RNA-seq paired FASTQ (PAIRED layout)

Also generates a combined checksums.md5 file.

Usage:
  python3 generate_manifests.py
"""

import csv
import os

# --- Configuration ---
INPUT_TSV = "metadata_template.tsv"
MANIFEST_DIR = "manifests"
CHECKSUM_FILE = "checksums.md5"

# --- Main ---
os.makedirs(MANIFEST_DIR, exist_ok=True)
checksums = []

with open(INPUT_TSV) as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in reader:
        name = row["library_name"]
        filetype = row["filetype"]

        # Build manifest content
        lines = [
            f"STUDY\t{row['study']}",
            f"SAMPLE\t{row['sample_acc']}",
            f"NAME\t{name}",
            f"INSTRUMENT\t{row['instrument']}",
            f"LIBRARY_NAME\t{name}",
            f"LIBRARY_SOURCE\t{row['source']}",
            f"LIBRARY_SELECTION\t{row['selection']}",
            f"LIBRARY_STRATEGY\t{row['strategy']}",
        ]

        if filetype == "bam":
            # PacBio HiFi BAM — single file
            lines.append(f"BAM\t{row['fq1']}")
            checksums.append(f"{row['fq1_md5']}  {row['fq1']}")
        else:
            # Paired FASTQ
            lines.append(f"FASTQ\t{row['fq1']}")
            lines.append(f"FASTQ\t{row['fq2']}")
            checksums.append(f"{row['fq1_md5']}  {row['fq1']}")
            checksums.append(f"{row['fq2_md5']}  {row['fq2']}")

        manifest_path = os.path.join(MANIFEST_DIR, f"{name}.manifest.txt")
        with open(manifest_path, "w") as out:
            out.write("\n".join(lines) + "\n")
        print(f"Wrote {manifest_path}")

# Write combined checksums
with open(CHECKSUM_FILE, "w") as out:
    out.write("\n".join(checksums) + "\n")
print(f"Wrote {CHECKSUM_FILE}")

#!/usr/bin/env python3
"""
Generate ENA submission XMLs from metadata_template.tsv.

Produces per-experiment XMLs with correct layout:
  - PacBio HiFi BAM → <SINGLE />, PACBIO_SMRT platform, filetype="bam"
  - Hi-C paired FASTQ → <PAIRED />, DNBSEQ platform, filetype="fastq"
  - RNA-seq paired FASTQ → <PAIRED />, ILLUMINA platform, filetype="fastq"

Output structure:
  ena_xmls/<NAME>/
    submission.xml   — ADD action with embedded manifest CDATA
    experiment.xml   — Experiment design with correct layout
    run.xml          — Run data block referencing FTP file paths

Usage:
  python3 generate_xmls.py
"""

import csv
import hashlib
import os
import xml.etree.ElementTree as ET
from xml.dom import minidom

# --- Configuration ---
INPUT_TSV = "metadata_template.tsv"
OUTPUT_DIR = "ena_xmls"

# --- Platform mapping ---
# ENA XML requires: <PLATFORM><INSTRUMENT_NAME><INSTRUMENT_MODEL>...</INSTRUMENT_MODEL></INSTRUMENT_NAME></PLATFORM>
PLATFORM_MAP = {
    "Revio": ("PACBIO_SMRT", "Revio"),
    "DNBSEQ-T7": ("DNBSEQ", "DNBSEQ-T7"),
    "Illumina NovaSeq 6000": ("ILLUMINA", "Illumina NovaSeq 6000"),
}


def prettify(elem):
    """Return pretty-printed XML string for an Element."""
    rough = ET.tostring(elem, encoding="unicode")
    parsed = minidom.parseString(rough)
    return parsed.toprettyxml(indent="  ", encoding=None)


def make_experiment_xml(row):
    """Build experiment.xml content."""
    name = row["library_name"]
    study = row["study"]
    sample = row["sample_acc"]
    strategy = row["strategy"]
    source = row["source"]
    selection = row["selection"]
    layout = row["layout"]
    instrument = row["instrument"]

    root = ET.Element("EXPERIMENT_SET")
    exp = ET.SubElement(root, "EXPERIMENT", alias=f"webin-reads-{name}")
    ET.SubElement(exp, "TITLE").text = f"Raw reads: {name}"
    ET.SubElement(exp, "STUDY_REF", accession=study)

    design = ET.SubElement(exp, "DESIGN")
    ET.SubElement(design, "DESIGN_DESCRIPTION").text = "unspecified"
    ET.SubElement(design, "SAMPLE_DESCRIPTOR", accession=sample)

    lib_desc = ET.SubElement(design, "LIBRARY_DESCRIPTOR")
    ET.SubElement(lib_desc, "LIBRARY_NAME").text = name
    ET.SubElement(lib_desc, "LIBRARY_STRATEGY").text = strategy
    ET.SubElement(lib_desc, "LIBRARY_SOURCE").text = source
    ET.SubElement(lib_desc, "LIBRARY_SELECTION").text = selection

    lib_layout = ET.SubElement(lib_desc, "LIBRARY_LAYOUT")
    if layout == "PAIRED":
        ET.SubElement(lib_layout, "PAIRED")
    else:
        ET.SubElement(lib_layout, "SINGLE")

    # Platform
    platform_tag, model = PLATFORM_MAP.get(instrument, ("UNSPECIFIED", instrument))
    platform = ET.SubElement(exp, "PLATFORM")
    platform_elem = ET.SubElement(platform, platform_tag)
    ET.SubElement(platform_elem, "INSTRUMENT_MODEL").text = model

    return root


def make_run_xml(row):
    """Build run.xml content."""
    name = row["library_name"]
    filetype = row["filetype"]
    fq1 = row["fq1"]
    fq1_md5 = row["fq1_md5"]

    root = ET.Element("RUN_SET")
    run = ET.SubElement(root, "RUN", alias=f"webin-reads-{name}")
    ET.SubElement(run, "TITLE").text = f"Raw reads: {name}"
    ET.SubElement(run, "EXPERIMENT_REF", refname=f"webin-reads-{name}")

    data_block = ET.SubElement(run, "DATA_BLOCK")
    files = ET.SubElement(data_block, "FILES")

    # FTP path: webin-cli/reads/<NAME>/<FILE>
    ftp_path = f"webin-cli/reads/{name}/{fq1}"
    ET.SubElement(
        files,
        "FILE",
        filename=ftp_path,
        filetype=filetype,
        checksum_method="MD5",
        checksum=fq1_md5,
    )

    # For paired FASTQ, add second file
    if row["layout"] == "PAIRED":
        fq2 = row["fq2"]
        fq2_md5 = row["fq2_md5"]
        ftp_path2 = f"webin-cli/reads/{name}/{fq2}"
        ET.SubElement(
            files,
            "FILE",
            filename=ftp_path2,
            filetype=filetype,
            checksum_method="MD5",
            checksum=fq2_md5,
        )

    return root


def make_submission_xml(row, manifest_text):
    """Build submission.xml with embedded manifest CDATA."""
    name = row["library_name"]

    # Calculate MD5 of manifest content
    manifest_md5 = hashlib.md5(manifest_text.encode()).hexdigest()

    # Build XML as string (CDATA doesn't work well with ElementTree)
    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<SUBMISSION_SET>
  <SUBMISSION alias="webin-reads-{name}">
    <ACTIONS>
      <ACTION>
        <ADD />
      </ACTION>
    </ACTIONS>
    <SUBMISSION_ATTRIBUTES>
      <SUBMISSION_ATTRIBUTE>
        <TAG>ENA-SUBMISSION-TOOL</TAG>
        <VALUE>HermesAgent:REST</VALUE>
      </SUBMISSION_ATTRIBUTE>
      <SUBMISSION_ATTRIBUTE>
        <TAG>ENA-MANIFEST-FILE</TAG>
        <VALUE><![CDATA[{manifest_text}]]></VALUE>
      </SUBMISSION_ATTRIBUTE>
      <SUBMISSION_ATTRIBUTE>
        <TAG>ENA-MANIFEST-FILE-MD5</TAG>
        <VALUE>{manifest_md5}</VALUE>
      </SUBMISSION_ATTRIBUTE>
    </SUBMISSION_ATTRIBUTES>
  </SUBMISSION>
</SUBMISSION_SET>"""
    return xml


def build_manifest_text(row):
    """Reconstruct the manifest text for embedding in submission.xml."""
    name = row["library_name"]
    filetype = row["filetype"]

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
        lines.append(f"BAM\t{row['fq1']}")
    else:
        lines.append(f"FASTQ\t{row['fq1']}")
        lines.append(f"FASTQ\t{row['fq2']}")

    return "\n".join(lines)


# --- Main ---
os.makedirs(OUTPUT_DIR, exist_ok=True)
count = 0

with open(INPUT_TSV) as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in reader:
        name = row["library_name"]
        exp_dir = os.path.join(OUTPUT_DIR, name)
        os.makedirs(exp_dir, exist_ok=True)

        # Generate experiment.xml
        exp_xml = make_experiment_xml(row)
        exp_path = os.path.join(exp_dir, "experiment.xml")
        with open(exp_path, "w") as out:
            out.write(prettify(exp_xml))
        print(f"Wrote {exp_path}")

        # Generate run.xml
        run_xml = make_run_xml(row)
        run_path = os.path.join(exp_dir, "run.xml")
        with open(run_path, "w") as out:
            out.write(prettify(run_xml))
        print(f"Wrote {run_path}")

        # Generate submission.xml
        manifest_text = build_manifest_text(row)
        sub_xml = make_submission_xml(row, manifest_text)
        sub_path = os.path.join(exp_dir, "submission.xml")
        with open(sub_path, "w") as out:
            out.write(sub_xml)
        count += 1
        print(f"Wrote {sub_path}")

print(f"\nGenerated XMLs for {count} experiments in {OUTPUT_DIR}/")

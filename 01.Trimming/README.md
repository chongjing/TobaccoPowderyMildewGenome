# Read QC and trimming for *Golovinomyces cichoracearum*

Step 01 of the tobacco powdery mildew (*Golovinomyces cichoracearum*, isolate BFJ)
genome project: quality control and trimming of the short-read sequencing data
(Illumina WGS and Hi-C) and the RNA-seq libraries, plus a read-level QC check of
the PacBio HiFi data.

The raw reads were delivered already adapter-trimmed by the sequencing provider
(BGI DNBSEQ-T7, `.clean.rd.fq.gz`). They were independently re-processed here with
a single documented parameter set so that raw-to-trimmed yields are uniform and
reproducible across all libraries for the manuscript (Supplementary Table 1).

## Workflow

1. **Pre-trim QC** — FastQC on all raw WGS and Hi-C FASTQ files; MultiQC aggregate.
2. **Trimming** — Trimmomatic (paired-end) on WGS, Hi-C (3 lanes) and RNA-seq (2 reps).
3. **Post-trim QC** — FastQC on the trimmed reads; MultiQC pre-vs-post comparison.
4. **HiFi QC** — read-count / yield / N50 summary of the PacBio HiFi SMRT cells
   (no trimming; HiFi reads are consensus-corrected on the instrument).

## Tools and parameters

| Tool | Version | Purpose |
|------|---------|---------|
| FastQC | 0.12.1 | per-file read QC (pre/post) |
| MultiQC | 1.35 | aggregate QC reports |
| Trimmomatic | 0.39 | paired-end quality trimming |

Trimmomatic (Phred+33, paired-end):

```
LEADING:5   TRAILING:5   SLIDINGWINDOW:4:15   MINLEN:50
```

Adapter content was negligible (FastQC PASS), so `ILLUMINACLIP` was **not** used for
WGS/Hi-C. RNA-seq additionally used `ILLUMINACLIP:TruSeq3-PE:2:30:10` to remove
residual TruSeq adapters.

## Results (read-pair retention)

| Library | Type | Raw pairs | Trimmed pairs | Retained |
|---------|------|-----------|---------------|----------|
| BFJ_WGS_L1 | WGS | 119,057,811 | 118,875,320 | 99.85% |
| BFJ.2_L1 | Hi-C | 50,028,193 | 49,827,295 | 99.60% |
| BFJ.2_L2 | Hi-C | 7,577,523 | 7,558,030 | 99.74% |
| BFJ.2_L3 | Hi-C | 10,391,156 | 10,349,890 | 99.60% |
| PM11_1 | RNA-seq | 37,788,574 | 36,500,674 | 96.59% |
| PM11_2 | RNA-seq | 37,990,840 | 36,247,087 | 95.41% |

PacBio HiFi: 591,720 CCS reads, 10.3 Gb, read N50 17.4–20.0 kb across 5 SMRT cells
(no trimming). Full per-file statistics:
[`04.Report/trimming_summary.tsv`](04.Report/trimming_summary.tsv).

## Directory layout

```
01.Trimming/
├── README.md                    this file
├── scripts/                     all scripts for this step
│   ├── run_trimmomatic_WGS.sh
│   ├── run_trimmomatic_HiC.sh
│   ├── run_trimmomatic_RNAseq.sh
│   ├── run_fastqc.sh            FastQC driver (pre/post-trim)
│   └── run_multiqc.sh           MultiQC aggregation
├── 00.RawQC/                    pre-trim FastQC + MultiQC reports
├── 03.PostQC/                   post-trim FastQC + MultiQC reports
├── 01.Trimmed_WGS/              Trimmomatic run logs (trimmed FASTQ -> ENA)
├── 02.Trimmed_HiC/              Trimmomatic run logs (trimmed FASTQ -> ENA)
├── 05.Trimmed_RNAseq/           Trimmomatic run logs (trimmed FASTQ -> ENA)
└── 04.Report/                   methods draft, QC report, Supplementary Table 1
```

## Data availability

No FASTQ files are stored in this repository. The Hi-C, RNA-seq and PacBio HiFi
reads are archived at the European Nucleotide Archive under BioProject
**PRJEB114362**; per-library run accessions are listed in
[`../05.ENA_submit/`](../05.ENA_submit/). Trimmed reads are reproduced from the raw
data with the scripts in [`scripts/`](scripts/).

## Reproducibility notes

- The three `run_trimmomatic_*.sh` scripts are the exact commands that were run.
- `run_fastqc.sh` and `run_multiqc.sh` document the QC commands, inputs and tool
  versions used to generate the reports under `00.RawQC/` and `03.PostQC/`.
- HiFi read QC metrics (reads, yield, N50 per SMRT cell; see
  `04.Report/qc_report.md`) were computed from the PacBio HiFi BAM files with
  `samtools` / `seqkit`.
- `04.Report/trimming_summary.tsv` (Supplementary Table 1) combines the
  Trimmomatic survival counts with per-file base/GC statistics from `seqkit`.

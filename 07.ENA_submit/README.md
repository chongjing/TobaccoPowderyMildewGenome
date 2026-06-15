# ENA Submission: Genome Assembly Sequencing Data

Submission of HiFi, Hi-C, and RNA-seq reads for *Golovinomyces cichoracearum* (tobacco powdery mildew) genome project to the European Nucleotide Archive (ENA) under BioProject **PRJEB114362**.

---

## Accessions

| Type       | Accession   | Alias                          |
|------------|-------------|--------------------------------|
| Project    | PRJEB114362 | aba78435-33d1-4e08-8431-b3ae7bff7ade |
| Submission | ERA36388322 | SUBMISSION-04-06-2026-21:18:28:463 |
| Sample     | ERS30398005 | Tobacco_powdery_mildew         |
| Submission | ERA36388479 | ena-SUBMISSION-TAB-04-06-2026-21:31:47:000-244267 |

---

## Run Accessions

| Library      | Type       | Platform         | Experiment  | Run         | Submission  |
|--------------|------------|------------------|-------------|-------------|-------------|
| HiFi_2823    | PacBio HiFi | PacBio Revio     | ERX16757614 | ERR17368092 | ERA36389087 |
| HiFi_3170    | PacBio HiFi | PacBio Revio     | ERX16757615 | ERR17368093 | ERA36389088 |
| HiFi_3361    | PacBio HiFi | PacBio Revio     | ERX16757616 | ERR17368094 | ERA36389089 |
| HiC_L1       | Hi-C       | DNBSEQ-T7        | ERX16757611 | ERR17368089 | ERA36389084 |
| HiC_L2       | Hi-C       | DNBSEQ-T7        | ERX16757612 | ERR17368090 | ERA36389085 |
| HiC_L3       | Hi-C       | DNBSEQ-T7        | ERX16757613 | ERR17368091 | ERA36389086 |
| RNAseq_PM11_1 | RNA-seq   | Illumina NovaSeq 6000 | ERX16757609 | ERR17368087 | ERA36389082 |
| RNAseq_PM11_2 | RNA-seq   | Illumina NovaSeq 6000 | ERX16757610 | ERR17368088 | ERA36389083 |

**Status:** All experiments PRIVATE (will be released upon publication)

---

## Data Summary

| Library      | Type       | Platform         | Files        | Size     | Strategy |
|--------------|------------|------------------|--------------|----------|----------|
| HiFi_2823    | PacBio HiFi | PacBio Revio     | 1 BAM        | 12 GB    | WGS      |
| HiFi_3170    | PacBio HiFi | PacBio Revio     | 1 BAM        | 9.5 GB   | WGS      |
| HiFi_3361    | PacBio HiFi | PacBio Revio     | 1 BAM        | 6.9 GB   | WGS      |
| HiC_L1       | Hi-C       | DNBSEQ-T7        | 2 FASTQ      | 5.8 GB   | Hi-C     |
| HiC_L2       | Hi-C       | DNBSEQ-T7        | 2 FASTQ      | 1.6 GB   | Hi-C     |
| HiC_L3       | Hi-C       | DNBSEQ-T7        | 2 FASTQ      | 1.2 GB   | Hi-C     |
| RNAseq_PM11_1 | RNA-seq   | Illumina NovaSeq 6000 | 2 FASTQ | 4.4 GB   | RNA-Seq  |
| RNAseq_PM11_2 | RNA-seq   | Illumina NovaSeq 6000 | 2 FASTQ | 4.6 GB   | RNA-Seq  |

**Total:** 8 experiments, 13 files, ~46 GB

---

## Submission Pipeline (Step by Step)

### 1. Metadata Preparation

`metadata_template.tsv` contains all sample metadata with columns:
- `sample_id`, `study`, `sample_acc` — registered accessions
- `instrument`, `library_name` — sequencing info
- `source`, `selection`, `strategy`, `layout`, `filetype` — library info
- `fq1`, `fq1_md5`, `fq2`, `fq2_md5` — file paths and checksums

### 2. Manifest Generation

`generate_manifests.py` reads the TSV and generates one webin-cli manifest per experiment:

```bash
python3 generate_manifests.py
```

Manifests are written to `manifests/` with fields: STUDY, SAMPLE, NAME, INSTRUMENT, LIBRARY_NAME, LIBRARY_SOURCE, LIBRARY_SELECTION, LIBRARY_STRATEGY, and BAM/FASTQ entries.

### 3. XML Generation

`generate_xmls.py` generates submission XMLs with correct layout:

```bash
python3 generate_xmls.py
```

For each experiment, generates:
- **submission.xml** — ADD action with manifest embedded as CDATA
- **experiment.xml** — Experiment design with correct `<PAIRED />` or `<SINGLE />` layout
- **run.xml** — Run data block referencing FTP file paths by MD5 checksum

Key layout handling:
- HiFi BAM → `<SINGLE />`, `filetype="bam"`, `<PACBIO_SMRT>` platform
- Hi-C FASTQ → `<PAIRED />`, `filetype="fastq"`, `<DNBSEQ>` platform
- RNA-seq FASTQ → `<PAIRED />`, `filetype="fastq"`, `<ILLUMINA>` platform

### 4. FTP Upload (curl)

Files are uploaded via curl (bypassing webin-cli's FTP timeout on large files):

```bash
# Example for one file
curl -T "local_file.bam" \
  --retry 5 --retry-delay 30 \
  --connect-timeout 60 --max-time 7200 \
  --ftp-create-dirs \
  "ftp://webin2.ebi.ac.uk/webin-cli/reads/<NAME>/<FILE>" \
  --user "Webin-XXXXX:password"
```

File path on ENA FTP: `webin-cli/reads/<EXPERIMENT_NAME>/<FILE>`

**Note:** Generate the upload script only when ready to submit (contains credentials and file paths).

### 5. REST API Submission

XMLs are submitted via multipart POST to the ENA Webin drop-box REST API:

```bash
curl -u "Webin-XXXXX:password" \
  -F "SUBMISSION=@submission.xml" \
  -F "EXPERIMENT=@experiment.xml" \
  -F "RUN=@run.xml" \
  "https://www.ebi.ac.uk/ena/submit/drop-box/submit/"
```

Each submission returns `success="true"` with assigned accession numbers.

### 6. Record Accessions

After successful submission, update this README.md with:
- Run accession numbers (ERR*)
- Experiment accession numbers (ERX*)
- Data availability statement

---

## Key Technical Notes

- **FTP timeout:** webin-cli's built-in FTP client times out on files >8 GB from HPC. Solution: upload via curl with `--max-time 7200`, then submit via REST API.
- **Library layout:** webin-cli previously generated incorrect `<SINGLE />` for paired-end data. generate_xmls.py handles layout correctly from the TSV.
- **HiFi BAM:** PacBio HiFi BAM files are submitted as BAM (not converted to FASTQ). ENA accepts BAM format for PacBio data.
- **File paths in RUN XML:** Must match the FTP path relative to the Webin account root: `webin-cli/reads/<NAME>/<FILE>`.

---

## Files in This Directory

| File / Directory | Description |
|-----------------|-------------|
| `metadata_template.tsv` | Master metadata and checksums (8 experiments) |
| `generate_manifests.py` | Script to generate webin-cli manifests |
| `generate_xmls.py` | Script to generate submission XMLs |
| `manifests/` | Generated webin-cli manifest files (×8) |
| `ena_xmls/` | Generated submission XMLs (×8 experiments, 3 files each) |
| `checksums.md5` | MD5 checksums for all data files |
| `01.info.md` | Project and sample registration info |

---

## Dependencies

- Python 3 (for XML/manifest generation)
- curl (for FTP upload)
- Java 17 + webin-cli (optional, for validation only — submission done via REST API)

---

## Data Source Paths

| File | Local Path |
|------|-----------|
| HiFi BAMs | `/home/cx264/project/03.TobaccoMildew/01.data/HiFi/Data-X101SC25057677-Z01-J002/ill/Sequel-Revio/` |
| Hi-C FASTQs | `/home/cx264/project/03.TobaccoMildew/01.data/X101SC25057677-Z01-J007/clean_data/BFJ.2/` |
| RNA-seq FASTQs | `/home/cx264/project/03.TobaccoMildew/01.data/RNAseq/` |

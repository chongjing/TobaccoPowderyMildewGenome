# Genome size profiling for *Golovinomyces cichoracearum*

Step 02 of the tobacco powdery mildew (*Golovinomyces cichoracearum*, isolate BFJ)
genome project: k-mer–based estimation of genome size, repeat content and
heterozygosity from the trimmed Illumina WGS reads, used to size the assembly and
set coverage expectations for Step 03.

## Workflow

K-mer counting with **KMC**, then model fitting with **GenomeScope2**, at two k-mer
sizes (k=21 primary, k=31 validation):

1. KMC count k-mers from the trimmed WGS R1 reads (`-ci1 -cs1000000`).
2. `kmc_tools transform … histogram` → k-mer frequency histogram.
3. GenomeScope2 haploid model (`-p 1`) → genome size / repeat / error estimates.

Driver: [`scripts/run_genome_profiling.sh`](scripts/run_genome_profiling.sh).

## Tools

| Tool | Version |
|------|---------|
| KMC | 3.2.4 |
| GenomeScope | 2.0 (R package 2.1.0) |

Input: trimmed WGS R1 — 118,875,320 reads, 17.8 Gb (from Step 01).

## Key results

| Metric | k=21 | k=31 | Consensus |
|--------|------|------|-----------|
| Haploid genome length | 137.2 Mb | 143.8 Mb | **~140 Mb** |
| Repeat content | 56.2% | 50.3% | ~50–56% |
| Heterozygosity | 0% | 0% | haploid / clonal |
| Model fit | 94.6% | 95.2% | good |
| Read error rate | 0.24% | 0.18% | very low |

**Interpretation:** ~140 Mb is large for a powdery mildew — ~2.8× *G. orontii*
(~50 Mb) and comparable to *Blumeria graminis* (~120 Mb), consistent with
repeat-driven genome expansion. Zero heterozygosity indicates a clonal, effectively
haploid isolate (no haplotig purging needed during assembly). Estimated coverage at
140 Mb: HiFi ~74×, WGS ~254×, Hi-C ~144×. Full analysis and interpretation:
[`report.md`](report.md).

## Directory layout

```
02.GenomeProfiling/
├── README.md                this file
├── report.md                detailed profiling report + interpretation
├── files_list_R1.txt        KMC input list (trimmed WGS R1)
├── scripts/
│   └── run_genome_profiling.sh
├── kmc_21mer/
│   ├── histogram_k21.txt     k-mer histogram (GenomeScope input)
│   └── kmc_k21.log           (kmc_db/ binary database excluded, ~2.4 GB)
├── kmc_31mer/
│   ├── histogram_k31.txt
│   └── kmc_k31.log           (kmc_db/ binary database excluded, ~3.5 GB)
├── genomescope_21mer/        GenomeScope2 plots, model, summary, JSON
└── genomescope_31mer/        GenomeScope2 plots, model, summary, JSON
```

## Data availability

The KMC binary k-mer databases (`kmc_*mer/kmc_db/`, ~5.9 GB) are **not** stored in
git; they are regenerated from the trimmed WGS reads with
[`scripts/run_genome_profiling.sh`](scripts/run_genome_profiling.sh). The k-mer
histograms (`histogram_k*.txt`) — the actual GenomeScope inputs — are retained here,
so the model fits are fully reproducible without the raw databases. Trimmed reads are
archived at ENA (BioProject **PRJEB114362**; see [`../05.ENA_submit/`](../05.ENA_submit/)).

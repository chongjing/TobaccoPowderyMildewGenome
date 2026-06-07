# Genome Profiling Report — *Golovinomyces cichoracearum* BFJ

**Date**: 2026-05-26  
**Tool**: KMC v3.2.4 → kmc_tools → GenomeScope v2.0 (R package 2.1.0)  
**Input**: Trimmed WGS R1 reads (118,875,320 reads, 150 bp, 17.8 Gb)  
**Pipeline**: `/home/cx264/project/03.TobaccoMildew/00.workflow/02.GenomeProfiling/scripts/run_genome_profiling.sh`

---

## 1. KMC Counting Statistics

| Metric | k=21 | k=31 |
|--------|------|------|
| Total k-mers counted | 15,438,886,037 | 14,250,132,797 |
| Unique k-mers | 359,730,240 | 407,279,881 |
| Reads processed | 118,875,320 | 118,875,320 |
| Super-k-mers | 2,304,396,483 | 1,225,199,560 |
| Stage 1 time (sorting) | 161 s | 152 s |
| Stage 2 time (merging) | 118 s | 152 s |
| **Total time** | **4.7 min** | **5.1 min** |
| Temp disk usage | 18.9 GB | 14.5 GB |

## 2. GenomeScope2 Haploid Model Results

### Genome Size Estimates

| Metric | k=21 | k=31 | Consensus |
|--------|------|------|-----------|
| **Genome haploid length** | **137.2 Mb** (137.1–137.4) | **143.8 Mb** (143.6–143.9) | **~140 Mb** |
| Repeat content | 77.1 Mb (56.2%) | 72.3 Mb (50.3%) | ~50-56% |
| Unique content | 60.1 Mb (43.8%) | 71.5 Mb (49.7%) | ~44-50% |
| Model fit (full range) | 94.6% | 95.2% | Good |
| K-mer coverage (kcov) | 64.8× | 59.5× | |
| Read error rate | 0.24% | 0.18% | Very low |
| Heterozygosity | 0% | 0% | Haploid, clonal |

### Parameter Estimates (k=21, from JSON)

| Parameter | Estimate | Std Error | t-value | p-value |
|-----------|----------|-----------|---------|---------|
| Repetitiveness (d) | 0.0601 | 0.00146 | 41.2 | <2e-16 |
| K-mer coverage (kmercov) | 64.77 | 0.037 | 1741.7 | 0 |
| Bias | 0.402 | 0.011 | 37.0 | <2e-16 |
| Length (scaling) | 63,964,213 | 233,288 | 274.2 | 0 |

### Parameter Estimates (k=31, from JSON)

| Parameter | Estimate | Std Error | t-value | p-value |
|-----------|----------|-----------|---------|---------|
| Repetitiveness (d) | 0.0539 | 0.00119 | 45.2 | <2e-16 |
| K-mer coverage (kmercov) | 59.53 | 0.029 | 2075.3 | 0 |
| Bias | 0.385 | 0.009 | 44.4 | <2e-16 |
| Length (scaling) | 75,554,516 | 223,468 | 338.1 | 0 |

## 3. Interpretation

### Genome Size: ~140 Mb — Larger than Expected

*G. cichoracearum* BFJ has a **~140 Mb** genome, which is:

| Species | Genome | Relationship |
|---------|--------|-------------|
| *Golovinomyces orontii* | ~50 Mb | Same genus, much smaller |
| *Erysiphe necator* | ~55 Mb | Same family, much smaller |
| *Blumeria graminis* f.sp. *hordei* | ~120 Mb | Same order (Erysiphales), comparable |
| *Golovinomyces cichoracearum* BFJ | **~140 Mb** | **This study** |

This is **2.8× larger than *G. orontii***, the closest sequenced relative. This suggests:
1. **Extensive transposable element expansion**, similar to what occurred in *B. graminis*
2. **Repeat-driven genome obesity** — ~50-56% of the genome is repetitive
3. **Different genome evolution trajectory** within the genus *Golovinomyces*

### Heterozygosity: 0%

No detectable heterozygosity — consistent with:
- Haploid ascomycete lifecycle
- Clonal reproduction (obligate biotroph with limited sexual recombination in agricultural settings)
- Simplifies assembly: no haplotig purging needed in hifiasm

### Coverage Estimates for Assembly

| Data type | Input | Coverage (at 140 Mb) |
|-----------|-------|----------------------|
| HiFi (5 SMRT cells) | 10.3 Gb | **~74×** |
| WGS (trimmed, PE) | 35.6 Gb | **~254×** |
| Hi-C (trimmed, PE) | 20.2 Gb | **~144×** |

HiFi coverage of 74× is well above the 30× minimum for hifiasm. WGS at 254× provides ample material for polishing.

## 4. Biological Implications for Manuscript

- *G. cichoracearum* joins the group of "expanded" powdery mildew genomes alongside *B. graminis*, reinforcing the pattern that obligate biotrophy in Erysiphales is associated with repeat-driven genome expansion
- In contrast, *G. orontii* (same genus, same host class) has a compact 50 Mb genome → suggests repeat expansion is lineage-specific within *Golovinomyces*, not universal
- The ~140 Mb genome ranks among the largest known powdery mildew genomes
- No heterozygosity detectable → the BFJ isolate is clonal, consistent with asexual overwintering on tobacco

## 5. Output Files

| File | Path |
|------|------|
| KMC k21 log | `02.GenomeProfiling/kmc_21mer/kmc_k21.log` |
| KMC k21 histogram | `02.GenomeProfiling/kmc_21mer/histogram_k21.txt` |
| GS k21 summary | `02.GenomeProfiling/genomescope_21mer/Gcichoracearum_summary.txt` |
| GS k21 JSON | `02.GenomeProfiling/genomescope_21mer/Gcichoracearum_report.json` |
| GS k21 linear plot | `02.GenomeProfiling/genomescope_21mer/Gcichoracearum_linear_plot.png` |
| GS k21 log plot | `02.GenomeProfiling/genomescope_21mer/Gcichoracearum_log_plot.png` |
| KMC k31 log | `02.GenomeProfiling/kmc_31mer/kmc_k31.log` |
| KMC k31 histogram | `02.GenomeProfiling/kmc_31mer/histogram_k31.txt` |
| GS k31 summary | `02.GenomeProfiling/genomescope_31mer/Gcichoracearum_summary.txt` |
| GS k31 linear plot | `02.GenomeProfiling/genomescope_31mer/Gcichoracearum_linear_plot.png` |
| Pipeline script | `02.GenomeProfiling/scripts/run_genome_profiling.sh` |
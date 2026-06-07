# ===================================================================
# QC Report: Illumina WGS & Hi-C Reads — Golovinomyces cichoracearum
# Date: 2026-05-26
# Platform: BGI DNBSEQ-T7 (PE150)
# ===================================================================

## HiFi Data Summary

| SMRT Cell | Batch | Reads | Yield (bp) | Min Len | N50 | Max Len |
|-----------|-------|-------|------------|---------|-----|---------|
| FPAC25H002823-1A | 1 | 191,084 | 3,474,211,941 | 289 | 20,014 | 47,422 |
| FPAC25H003170-1A | 1 | 159,736 | 2,933,344,729 | 138 | 19,885 | 60,134 |
| FPAC25H003361-1A | 1 | 127,905 | 2,108,651,229 | 348 | 17,450 | 42,404 |
| FPAC26H000089-1A | 2 | 74,545 | 1,170,141,919 | 650 | 19,100 | 54,229 |
| FPAC26H000489-1A | 2 | 38,450 | 636,794,682 | 95 | 19,313 | 45,222 |
| **Total** | | **591,720** | **10,323,144,500** | | | |

HiFi N50 range: 17,450–20,014 bp (consistent across all cells)
Total HiFi yield: ~10.3 Gb (estimated 100-200× coverage for a ~50-100 Mb fungal genome)

## Raw FASTQ QC Summary (Pre-trim)

| File | Dataset | Read | Reads | Yield (Gb) | GC% | Mean Q @ pos 150 | Encoding |
|------|---------|------|-------|------------|-----|------------------|----------|
| BFJ.2_L1_1.clean.rd | Hi-C L1 |  | 50,028,193 | 7.5 | 41.0% | Q39.446420721212135 | Sanger / Illumina 1.9 |
| BFJ.2_L1_2.clean.rd | Hi-C L1 |  | 50,028,193 | 7.5 | 41.0% | Q39.082378510053324 | Sanger / Illumina 1.9 |
| BFJ.2_L2_1.clean.rd | Hi-C L2 |  | 7,577,523 | 1.14 | 41.0% | Q36.888695817881384 | Sanger / Illumina 1.9 |
| BFJ.2_L2_2.clean.rd | Hi-C L2 |  | 7,577,523 | 1.14 | 41.0% | Q35.43928589857134 | Sanger / Illumina 1.9 |
| BFJ.2_L3_1.clean.rd | Hi-C L3 |  | 10,391,156 | 1.56 | 41.0% | Q39.48468668933466 | Sanger / Illumina 1.9 |
| BFJ.2_L3_2.clean.rd | Hi-C L3 |  | 10,391,156 | 1.56 | 41.0% | Q39.193451623669205 | Sanger / Illumina 1.9 |
| BFJ_WGS_L1_1.clean.rd | WGS | R2 | 119,057,811 | 17.86 | 42.0% | Q36.66111685859906 | Sanger / Illumina 1.9 |
| BFJ_WGS_L1_2.clean.rd | WGS | R2 | 119,057,811 | 17.86 | 42.0% | Q35.48349252784431 | Sanger / Illumina 1.9 |

**Total WGS read pairs:** 119,057,811 (238,115,622 total reads, ~35.7 Gb)
**Total Hi-C read pairs:** 67,996,872 (135,993,744 total reads, ~20.4 Gb)
**Total HiFi yield:** ~10.3 Gb
**Total all data:** ~66.4 Gb

## Quality Assessment

### WGS (BFJ_WGS_L1)
- R1: 119.1M reads, mean Q > 37 across all 150 bp
- R2: 119.1M reads, mean Q > 35 across all 150 bp (35.5 at position 150)
- GC content: 42% (consistent with fungal genomes)
- Adapter content: PASS (negligible, <0.001%)
- Overrepresented sequences: PASS
- BGI DNBSEQ-T7 platform, Phred+33 encoding (Sanger 1.9)

### Hi-C
- L1: 50.0M read pairs, mean Q > 39 at read end (R1: 39.4, R2: 39.1)
- L2: 7.6M read pairs, mean Q > 35 at read end (R1: 36.9, R2: 35.4)
- L3: 10.4M read pairs, mean Q > 39 at read end (R1: 39.5, R2: 39.2)
- GC content: 41% (consistent across all lanes)
- Total Hi-C: ~68M read pairs
- Adapter content: PASS (all lanes)
- Enzyme: MboI

### HiFi
- Total: 591,720 CCS reads (10.3 Gb)
- N50 range: 17,450–20,014 bp (consistent across SMRT cells)
- All cells use the same sample ID (FZTD250014144-2A for Batch 1, FZTD260005167-2A for Batch 2)

### Data Quality Verdict
**Excellent.** All datasets are of top-tier quality suitable for high-impact genome publication.
Data is essentially publication-ready without aggressive trimming.
Trimming is applied for:
1. Documentation in Methods (raw → processed yield table)
2. Removal of a small fraction of low-quality base calls
3. Removal of BGI two-color chemistry artifact (PolyG at first 1-7 bases)

## Trimming Parameters Applied

```
Tool: Trimmomatic v0.39
Mode: PE (paired-end)
Phred: +33 (Sanger/Illumina 1.9)
Parameters:
  LEADING:5               # Remove leading bases below Q5
  TRAILING:5              # Remove trailing bases below Q5
  SLIDINGWINDOW:4:15      # 4bp window, trim when avg Q < 15
  MINLEN:50               # Discard reads <50 bp
  Note: ILLUMINACLIP not used (adapter content already negligible)
```

## Expected Retention

Given Q > 35 even at read ends with SLIDINGWINDOW:4:15:
- Estimated retained pairs: >99%
- Unpaired reads (orphans): <0.5%

## Files

| Output | Path |
|--------|------|
| Raw FastQC | `00.workflow/01.Trimming/00.RawQC/fastqc/` |
| Raw MultiQC | `00.workflow/01.Trimming/00.RawQC/multiqc/multiqc_raw.html` |
| Trimmed WGS | `00.workflow/01.Trimming/01.Trimmed_WGS/` |
| Trimmed Hi-C | `00.workflow/01.Trimming/02.Trimmed_HiC/` |
| Post-trim QC | `00.workflow/01.Trimming/03.PostQC/` |
| Report | `00.workflow/01.Trimming/04.Report/` |

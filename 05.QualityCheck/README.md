# Quality Check — *Golovinomyces cichoracearum* BFJ

Assembly and annotation quality validation metrics for the *G. cichoracearum* BFJ genome project.

| Assessment | Method | Result |
|---|---|---|
| Base accuracy (QV) | Merqury (k = 19) | 47.18 |
| K-mer completeness | Merqury | 99.29% |
| Gene completeness (genome) | BUSCO, ascomycota_odb10 | 96.9% (S:96.0%, D:0.9%) |
| Gene completeness (proteome) | BUSCO, ascomycota_odb10 | 96.6% (S:95.5%, D:1.1%) |
| HiFi read mapping | minimap2 | 99.10% |
| Hi-C read mapping | bwa-mem2 | 89.72% |
| RNA-seq read mapping | minimap2 | 4.96% |
| Telomere completeness | motif scan (CCCTAA/TTAGGG) | 9 of 11 chromosomes T2T |
| Contamination | minimap2 + BUSCO viridiplantae | None detected |

## Pipeline overview

| Step | Script | Description |
|---|---|---|
| 1 | `01.busco_genome.sh` | BUSCO on genome assembly (ascomycota_odb10) |
| 2 | `02.busco_proteome.sh` | BUSCO on predicted proteome |
| 3 | `03.merqury_qv.sh` | Merqury: reference-free QV + k-mer completeness |
| 4 | `04.mapping_rates.sh` | Mapping rates: HiFi (minimap2), Hi-C (bwa-mem2), RNA-seq |
| 5 | `05.contamination_check.sh` | Contamination screen: plant BUSCO + GC/coverage |

## Results

### BUSCO comparison

| Mode | Complete (C) | Single (S) | Duplicated (D) | Fragmented (F) | Missing (M) |
|---|---|---|---|---|---|
| Genome | 96.9% | 96.0% | 0.9% | 0.5% | 2.6% |
| Proteome | 96.6% | 95.5% | 1.1% | 0.7% | 2.3% |

The proteome BUSCO score (96.6%) closely matches the genome score (96.9%), confirming that essentially all recoverable conserved orthologues are annotated.

### Mapping rates

| Data type | Mapper | Primary mapping | Notes |
|---|---|---|---|
| HiFi (PacBio Revio) | minimap2 -x map-hifi | 99.10% | ~62× coverage |
| Hi-C (DNBSEQ-T7) | bwa-mem2 -5SP | 89.72% | 3 lanes merged |
| RNA-seq (Illumina NovaSeq) | minimap2 -x sr | 4.96% | ~8% of host-derived total RNA is fungal |

The low RNA-seq mapping rate is expected for obligate biotrophs — total RNA from infected tobacco leaves is predominantly host-derived. The ~3.6M fungal-aligned read pairs provided sufficient evidence for annotation.

### Telomere status

9 of 11 chromosomes are assembled telomere-to-telomere (both ends confirmed). Chr3 and Chr11 each lack a telomere at the left end.

## Contamination

- Per-contig GC content and HiFi coverage are uniform across all 11 chromosomes
- Alignment to *Nicotiana* reference returned no contigs with substantial plant similarity
- BUSCO viridiplantae screen: no plant-conserved orthologues detected beyond those shared between fungi and plants

## Software versions

| Tool | Version |
|---|---|
| BUSCO | v5.6.1 |
| Merqury (meryl) | v1.4.1 |
| minimap2 | v2.28 |
| bwa-mem2 | v2.2.1 |
| samtools | v1.22.1 |
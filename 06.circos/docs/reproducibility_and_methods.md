## Reproduce the figure

From the repository root:

```bash
cd 04.circos

# Optional: override tools if they are not in the original local paths.
export BT=/path/to/bedtools
export ST=/path/to/samtools

# Optional: override input files if reproducing on another machine.
export FAI=/path/to/Golovinomyces_cichoracearum.scaffolds.fa.fai
export FASTA=/path/to/Golovinomyces_cichoracearum.scaffolds.fa
export GFF3=/path/to/Golovinomyces_cichoracearum.gff3
export LTR_GFF3=/path/to/EDTA_LTR_pass_list.gff3
export INFERNAL=/path/to/cmscan_fmt2.tblout
export SECRETED_LIST=/path/to/04.SP.secreted.list
export REPEATMASKER_BED=/path/to/repeatmasker.bed

bash scripts/prepare_engineA_data.sh 2>&1 | tee logs/prepare_engineA_data.rerun.log
Rscript scripts/plot_engineA_circlize.R 2>&1 | tee logs/plot_engineA_circlize.rerun.log
FINAL=1 Rscript scripts/plot_engineA_circlize.R 2>&1 | tee logs/plot_engineA_circlize_final.rerun.log
```

The script defaults point to the original Dr. Xia project workspace on the analysis machine. For a fresh clone elsewhere, set the input environment variables above. The derived plot-ready files in data/v2/ and final results in results/ are committed so the figure can be inspected without access to the full raw project workspace.

Software used in the verified run

- Linux x86_64
- bash
- bedtools v2.31.0
- samtools/faidx
- R 4.4.3
- R packages: circlize, Cairo, ComplexHeatmap/grid dependencies

Method summary

Genome coordinates were restricted to contig_1 through contig_11 and renamed chr1 through chr11 for plotting. Non-overlapping 100 kb windows were generated with bedtools makewindows. Gene density was calculated as the number of annotated genes per window. Total repeats, Copia LTRs, and Gypsy LTRs were first merged to avoid double-counting overlapping intervals, then summarized as coverage fractions per 100 kb window. GC content was calculated from the chr1-chr11 FASTA subset using bedtools nuc. Candidate secreted proteins were mapped from the final secreted-protein list back to mRNA coordinates in the GFF3. tRNA loci were taken from the Funannotate GFF3. snRNA and rRNA hits were parsed from cmscan tblout; rRNA hits were collapsed into rDNA/NOR loci using a 50 kb merge distance to avoid plotting hundreds of redundant tandem-array hits as independent events.

Color scaling

Heatmap rings are scaled using robust empirical caps rather than raw maxima. Per-track p98 caps are stored in data/v2/caps.tsv. This avoids washed-out tracks caused by a few extreme windows while preserving relative enrichment patterns.

Main result values represented in the figure

- 11 displayed scaffolds/chromosomes: chr1-chr11
- Displayed genome span: approximately 148 Mb
- Whole assembly size shown in centre label: 166.5 Mb
- Protein-coding genes shown in centre label: 22,907
- Candidate secreted proteins plotted: 255
- LTR retrotransposons summarized in centre label: 837
- Major rDNA/NOR locus: chr2, approximately 11.43-11.69 Mb, with 268 collapsed raw rRNA hits

Notes and limitations

- The figure is a genome-wide overview, not a per-gene browser. Fine-scale local interpretation should use the source GFF3/BED files.
- Copia/Gypsy tracks reflect EDTA/LTR_retriever intact LTR calls; total repeat coverage reflects RepeatMasker/funannotate repeat intervals.
- Small scaffolds outside contig_1-contig_11 are omitted for visual clarity.
- Engine B development files are intentionally not included in this curated repository.

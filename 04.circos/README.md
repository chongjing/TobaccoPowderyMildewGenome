# CIRCOS genome plot for Golovinomyces cichoracearum

This directory contains the curated, reproducible CIRCOS-style genome plot workflow used for the Tobacco powdery mildew genome project.

Species: Golovinomyces cichoracearum
Figure: genome-wide circular visualization of gene density, candidate secreted proteins, repeat content, LTR retrotransposons, ncRNA loci, and GC content.
Rendering engine kept in this repository: Engine A, R/circlize only.

Why only Engine A?

During development, two rendering engines were compared:

- Engine A: R/circlize
- Engine B: Perl Circos with post-processing

Engine A was retained because it is easier to reproduce from one R script, gives a true vector PDF, and keeps the visual design/data scaling in one place. Engine B was useful during design exploration but is intentionally excluded from this curated repository to avoid duplicated logic and long-term maintenance drift.

Directory layout

04.circos/
  README.md                         this file
  .gitignore                        ignore rules for local reruns
  data/v2/                          derived plot-ready tables used by the figure
  docs/strategy_engineA_vs_engineB.md design rationale and development notes
  logs/                             captured logs from data preparation and rendering
  qc/                               screenshot/visual QC crops from figure inspection
  results/                          final rendered figure files
  scripts/prepare_engineA_data.sh   data-preparation workflow
  scripts/plot_engineA_circlize.R   final R/circlize plotting workflow

Final outputs

- results/GC_circos.pdf   vector PDF, recommended for editing and manuscript assembly
- results/GC_circos.tiff  1200 dpi TIFF, recommended for journal submission
- results/GC_circos.jpeg  1200 dpi JPEG, high-quality preview/submission alternative
- results/GC_circos.png   1200 dpi PNG, high-resolution raster preview

Track order, outside to inside

1. Ideogram: 11 major pseudochromosomes/scaffolds, chr1-chr11.
2. Gene density: protein-coding gene counts per 100 kb window.
3. Candidate secreted proteins: SignalP-positive proteins without transmembrane domains after signal peptide filtering.
4. Total repeat coverage: RepeatMasker/funannotate repeat fragments merged before coverage calculation.
5. Copia LTR retrotransposon coverage: EDTA/LTR_retriever intact LTR calls.
6. Gypsy LTR retrotransposon coverage: EDTA/LTR_retriever intact LTR calls.
7. ncRNA: collapsed rDNA/NOR loci, tRNA, and snRNA features.
8. GC content: 100 kb non-overlapping windows.
9. Centre annotation: assembly and annotation summary statistics.

Key biological message

The figure summarizes the chromosome-scale landscape of a compact obligate-biotrophic powdery mildew genome. It highlights gene/repeat compartmentalisation, positions of candidate secreted proteins, LTR retrotransposon distribution, the major chr2 rDNA/NOR locus, and GC variation across the 11 major scaffolds.

Data scope

The plot focuses on contig_1 to contig_11, renamed chr1 to chr11 for display. These scaffolds represent the dominant assembly component used for the manuscript-style figure. Smaller scaffolds are excluded to preserve readability of the circular genome plot.

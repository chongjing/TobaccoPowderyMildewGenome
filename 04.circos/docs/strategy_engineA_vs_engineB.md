# CIRCOS v2 — Design & Strategy Note
**Date:** 2026-06-03
**Project:** *Golovinomyces cichoracearum* genome annotation — publication CIRCOS
**Goal:** match the quality of the citrus reference (`citrus.circos.png`), single haploid genome.

---

## 1. Why v1 (`02.plot_circos.R` → `Gc_circos.jpeg`) under-performed

Diagnosed from the v1 script + the actual data distributions (not aesthetics alone):

| # | Problem | Root cause | v2 fix |
|---|---------|-----------|--------|
| A | spiky, noisy density tracks | gene density & total-repeat drawn as **histograms** | **heatmap rings** (smooth gradients), citrus's signature |
| B | washed-out colours | colour scaled to **max** (gene max=104 vs median=14) | **p98 caps** + power-law colour gamma |
| C | empty white centre (~35%) | haploid → no hap1/hap2 links, hole left empty | **species + genome-stats block** in centre |
| D | rRNA = meaningless blob on chr2 | 268/316 hits = the **tandem 45S+5S array** plotted as points | **collapsed to 3 rDNA/NOR loci**, chr2 shown as a highlighted band |
| E | TE coverage could exceed 1.0 | v1 used `sum(bp)/win` on self-overlapping fragments | `bedtools merge | coverage` → true fraction ≤1 |
| F | **wrong ncRNA columns** | v1 parsed a cmscan `--fmt 2` tblout with standard-format indices | re-parsed with correct columns (family=$2, scaffold=$4, coords=$10/11, E=$18) |
| G | noisy GC line | 25 kb step (5 916 windows), area-fill on near-flat signal | 100 kb non-overlapping (1 487 win), de-noised area-line |
| H | plain grey ideogram, legend collisions | — | **coloured ideogram + Mb ticks**; legend in clean bottom band |
| I | wrong export | 1200 dpi **JPEG** (lossy, 12 MB) | vector **PDF/SVG** + 1200 dpi TIFF/JPEG/PNG |

> **Note on expectation:** citrus looks mirror-symmetric because it is **two haplotypes** with single-copy-ortholog links filling the centre. *G. cichoracearum* is **haploid** → a single concentric plot (correct), centre filled with a stats block instead of links.

---

## 2. Data (v2) — `03.prepare_v2.sh` → `data/v2/`

- 11 pseudochromosomes (`contig_1–11` → `chr1–11`), 148 Mb = **89%** of the 166.5 Mb assembly.
- Windows: **100 kb non-overlapping** (1 487 cells) for all heatmaps + GC line.
- Densities: gene = count/window; repeat/Copia/Gypsy = **coverage fraction** (merge+coverage).
- p98 colour caps (`caps.tsv`): gene 25, repeat 0.073, Copia 0.136, Gypsy 0.114; GC range 0.37–0.585.
- rDNA: rRNA hits merged within 50 kb → **chr2 NOR** (11.43–11.69 Mb, 268 copies), minor 5S clusters chr3/chr11.
- tRNA from **GFF** (614, canonical), snRNA from INFERNAL (23), effectors 255.

## 3. Track design (outside → in) — identical for both engines

1. **Ideogram** — per-chr colour + Mb tick scale + bold label
2. **Gene density** heatmap (orange)
3. **Candidate effectors** — red lollipops (the pathogen headline)
4. **Total repeats** heatmap (purple)
5. **Copia LTR** heatmap (vermillion)
6. **Gypsy LTR** heatmap (green)
7. **ncRNA** — rDNA/NOR band (blue) + tRNA (grey) + snRNA (cyan)
8. **GC content** — blue area-line, de-noised
9. **Centre** — *G. cichoracearum* + 166.5 Mb · 11 chr · 22,907 genes · 255 effectors · 837 LTR-RTs

Biology shown: gene-rich vs repeat-rich **compartmentalisation** (two-speed genome), effectors vs TE landscape, the chr2 NOR (corroborated by a GC spike at the same locus).

## 4. Rendering-engine decision

| | **A — R circlize** (`04.plot_circlize_v2.R`) | **B — Circos Perl** (`circos_conf/` + `05.finalize_circos.R`) |
|---|---|---|
| ideogram | filled colour blocks | thin colour arcs |
| heatmaps | `colorRamp2`, gamma `pw` | brewer `*-9-seq`, `scale_log_base` |
| centre/legend | native base graphics | overlaid in R on the native ring PNG |
| vector | true-vector PDF (Cairo) | native SVG; PDF = hi-res raster embed |
| outputs | `out_circlize/Gc_circos.{pdf,tiff,jpeg,png}` | `out_circos/Gc_circos.{pdf,tiff,jpeg,png}` + `.svg` |

Engine A was selected for the curated GitHub release. Engine B files are excluded from 04.circos/ because they duplicate the same biological tracks through a second plotting stack and would increase maintenance burden.

## 5. Curated scripts / logs
- `scripts/prepare_engineA_data.sh` → `logs/prepare_engineA_data.log`
- `scripts/plot_engineA_circlize.R` → `logs/plot_engineA_circlize_draft.log`, `logs/plot_engineA_circlize_final.log`
- final outputs → `results/GC_circos.{pdf,tiff,jpeg,png}`
- visual QC crops → `qc/*.png`

## 6. Open options (easy to toggle if wanted)
- ring spacing of circlize can be loosened to match Circos's airier look
- effector representation: lollipops (current) vs density heatmap
- add a LINE/Tad1 TE ring (needs RepeatMasker genome-wide output — not yet available)
- drop chr11 (1.17 Mb stub) if a cleaner ring is preferred

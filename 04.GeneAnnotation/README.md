# Gene Annotation — *Golovinomyces cichoracearum* BFJ

Protein-coding gene annotation of the *G. cichoracearum* BFJ genome using Funannotate v1.8.17, refined with PASA. The annotation was run on the repeat-soft-masked genome (81.91% repetitive). RNA-seq evidence from infected tobacco leaves and homology evidence from related powdery mildew species were integrated.

| Annotation metric | Value |
|---|---|
| Protein-coding genes | 11,700 |
| Messenger RNAs | 11,677 |
| Transcripts (incl. isoforms) | 12,569 |
| Mean protein length | 361 aa |
| mRNAs with 5′ and 3′ UTR | 63% |
| Complete CDS (start + stop) | 99.9% |
| Transfer RNAs | 892 |
| Proteins with functional assignment | 9,560 / 11,677 (81.9%) |
| BUSCO (Ascomycota, protein mode) | 96.6% complete |

## Pipeline overview

The annotation pipeline consists of four sequential steps:

| Step | Script | Description |
|---|---|---|
| 1 | `01.hisat2_align.sh` | RNA-seq alignment with HISAT2 (stranded RF, 2 biological replicates) |
| 2 | `02.stringtie_asm.sh` | Transcript assembly with StringTie + intron hints with bam2hints |
| 3 | `03.funannotate_predict.sh` | Structural annotation with Funannotate: 4 ab initio predictors (Augustus, SNAP, GlimmerHMM, CodingQuarry) integrated via EvidenceModeler |
| 4 | `04.funannotate_update.sh` | UTR refinement with PASA pipeline (Trinity + PASA alignment) |

### Step 3 — Funannotate predict details

**Evidence weighting:**
- Transcript alignments: weight 10 (highest — the most reliable evidence)
- Augustus: weight 3
- Other ab initio predictors, protein homology: weight 1

**Predictor training:**
All four ab initio predictors were trained on BUSCO-derived gene models (ascomycota_odb10, n = 1,345 validated training models).

**Key parameters:**
- `--max_intronlen 3000` (conservative for fungi; typical introns 50–200 bp)
- `--min_training_models 150` (minimum for robust training)
- `--organism fungus` (enables CodingQuarry + fungal-optimised parameters)
- GeneMark was excluded (non-functional in the container environment)

### Step 4 — Funannotate update (PASA)

The PASA pipeline uses Trinity to assemble transcripts de novo from the RNA-seq reads, then aligns them to the genome to correct exon boundaries, add UTRs, and capture alternative isoforms. The salmon quantifier within PASA requires libboost 1.85.0 (see script for bind-mount workaround).

## Data files

| File | Description |
|---|---|
| `Gcichoracearum_BFJ.gff3.gz` | Structural annotation in GFF3 format |
| `Gcichoracearum_BFJ.proteins.fa` | Predicted protein sequences |
| `Gcichoracearum_BFJ.cds-transcripts.fa.gz` | CDS nucleotide sequences |
| `Gcichoracearum_BFJ.mrna-transcripts.fa.gz` | Full mRNA transcripts |

## Data access

The genome annotation is deposited at the European Nucleotide Archive under analysis accession **ERZ29580609** (locus_tag prefix **GCICH**), linked to assembly GCA_984789755 under BioProject **PRJEB114362**.

## Software versions

| Tool | Version | Reference |
|---|---|---|
| Funannotate | v1.8.17 | Palmer & Stajich, 2020 |
| HISAT2 | v2.2.2 | Kim et al., *Nat. Biotechnol.* 37, 907–915 (2019) |
| StringTie | v2.2.3 | Pertea et al., *Nat. Biotechnol.* 33, 290–295 (2015) |
| Trinity | v2.8.5 | Grabherr et al., *Nat. Biotechnol.* 29, 644–652 (2011) |
| PASA | v2.4.1 | Haas et al., *Nucleic Acids Res.* 31, 5654–5666 (2003) |
| tRNAscan-SE | v2.0.9 | Chan & Lowe, *Methods Mol. Biol.* 1962, 1–14 (2019) |
| InterProScan | v6 | Jones et al., *Bioinformatics* 30, 1236–1240 (2014) |
| Infernal | v1.1.5 | Nawrocki & Eddy, *Bioinformatics* 29, 2933–2935 (2013) |
| SignalP | v6.0 | Teufel et al., *Nat. Biotechnol.* 40, 1023–1025 (2022) |
| DeepTMHMM | v1.0 | Hallgren et al., *bioRxiv* (2022) |

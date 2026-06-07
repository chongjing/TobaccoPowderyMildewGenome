## Methods: Sequencing and Quality Control

### Biological Material and DNA Extraction

*Golovinomyces cichoracearum* isolate BFJ was collected from infected tobacco leaves. Genomic DNA was extracted using [... method ...]. For Hi-C library preparation, crosslinked chromatin was digested with MboI restriction enzyme and proximity-ligated prior to sequencing.

### Library Preparation and Sequencing

Sequencing libraries were prepared and sequenced on the BGI DNBSEQ-T7 platform (PE150) and the PacBio Revio platform (HiFi CCS mode).

**Illumina whole-genome sequencing (WGS):** One paired-end library was sequenced, producing 119.1 million read pairs (35.7 Gb) with 150 bp read length.

**Hi-C sequencing:** Three sequencing lanes of a proximity-ligation library were sequenced, producing a total of ~68 million read pairs (13.2 Gb) with 150 bp read length.

**PacBio HiFi sequencing:** Five SMRT cells were sequenced on the Revio platform, producing 591,720 HiFi CCS reads (10.3 Gb) with an N50 read length of 19,885 bp (range: 17,450–20,014 bp across SMRT cells).

### Quality Control and Read Trimming

Raw sequencing data were pre-processed by the sequencing provider using the DNBSEQ standard pipeline to remove adapter sequences and low-quality bases. To ensure uniform processing and documentation, all datasets were independently re-processed using Trimmomatic v0.39 (Bolger et al., 2014) with the following parameters: LEADING:5, TRAILING:5, SLIDINGWINDOW:4:15, MINLEN:50, in paired-end mode with Phred+33 quality encoding. Adapter content was negligible in all datasets (confirmed by FastQC v0.12.1) and no additional adapter trimming was applied. Sequence quality statistics before and after trimming are provided in Supplementary Table 1. 

No trimming was required for PacBio HiFi reads, which are consensus-corrected by the Revio instrument.

**QC summary:** All datasets exhibited excellent quality. WGS read pairs had median Phred scores of 38 (R1) and 36 (R2) at the final base position. Hi-C lanes showed mean Phred scores > 35 at read ends across all lanes.

### Software Versions

- FastQC v0.12.1
- MultiQC v1.35
- Trimmomatic v0.39
- Java 11.0.30
- samtools (for HiFi BAM QC)

#!/bin/bash
set -euo pipefail
##############################################################################
# CIRCOS v2 data preparation  --  G. cichoracearum
#
# Redesign goals vs v1:
#   * heatmap-ready NON-OVERLAPPING 100 kb windows (v1 used overlapping
#     windows that overdraw as heatmap cells)
#   * coverage FRACTION via `bedtools merge | coverage` so self-overlapping
#     TE fragments are not double counted (v1 used sum(bp)/winsize -> >1.0)
#   * rRNA collapsed into merged rDNA / NOR loci (208/229 hits = one array)
#   * tRNA taken from the funannotate GFF (614 across chr1-11), not INFERNAL
#   * per-track p98 colour caps written to caps.tsv so circlize AND Circos
#     scale identically
#   * emits one generic "chr start end value" file set used by BOTH engines
#     + a Circos karyotype file
##############################################################################

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKDIR=$(cd "${SCRIPT_DIR}/.." && pwd)
OUT="${WORKDIR}/data/v2"
BT="${BT:-/home/cx264/bin/bedtools}"
ST="${ST:-/home/cx264/bin/samtools}"

# Input paths can be overridden via environment variables. Defaults match the
# original Dr. Xia project workspace used to generate the published outputs.
FAI="${FAI:-/home/cx264/project/03.TobaccoMildew/06.Annotation/05.FunannotatePredict/update_results/Golovinomyces_cichoracearum.scaffolds.fa.fai}"
GFF3="${GFF3:-/home/cx264/project/03.TobaccoMildew/06.Annotation/05.FunannotatePredict/update_results/Golovinomyces_cichoracearum.gff3}"
FASTA="${FASTA:-/home/cx264/project/03.TobaccoMildew/06.Annotation/05.FunannotatePredict/update_results/Golovinomyces_cichoracearum.scaffolds.fa}"
LTR_GFF3="${LTR_GFF3:-/home/cx264/project/03.TobaccoMildew/06.Annotation/11.TE/Golovinomyces_cichoracearum.scaffolds.fa.mod.EDTA.raw/LTR/Golovinomyces_cichoracearum.scaffolds.fa.mod.pass.list.gff3}"
INFERNAL="${INFERNAL:-/home/cx264/project/03.TobaccoMildew/06.Annotation/10.RNA/01.GcBFJ_final_scaffolds_final.tblout}"
SECRETED_LIST="${SECRETED_LIST:-/home/cx264/project/03.TobaccoMildew/06.Annotation/12.SecretedProtein/04.SP.secreted.list}"
REPEATMASKER_BED="${REPEATMASKER_BED:-/home/cx264/project/03.TobaccoMildew/06.Annotation/05.FunannotatePredict/predict_misc/repeatmasker.bed}"

WIN=100000        # heatmap / GC window (non-overlapping)
mkdir -p "$OUT"
cd "$WORKDIR"

log(){ echo "[$(date +%H:%M:%S)] $*"; }

##############################################################################
log "Step 1  karyotype (chr1-11, ordered)"
##############################################################################
awk '$1 ~ /^contig_([1-9]|10|11)$/ {split($1,a,"_"); print "chr"a[2]"\t"$2}' "$FAI" \
  | sort -t r -k2 -n > "${OUT}/karyotype.tsv"
# stable numeric order
python3 - "$OUT/karyotype.tsv" <<'PY'
import sys,re
p=sys.argv[1]
rows=[l.split() for l in open(p) if l.strip()]
rows.sort(key=lambda r:int(re.search(r'(\d+)',r[0]).group(1)))
open(p,'w').write(''.join(f"{c}\t{s}\n" for c,s in rows))
PY
cat "${OUT}/karyotype.tsv"

# Circos karyotype: chr - ID LABEL START END COLOR
#   11-colour qualitative palette (defined identically in the Circos conf)
python3 - "$OUT/karyotype.tsv" "$OUT/karyotype.circos.txt" <<'PY'
import sys
ink,out=sys.argv[1],sys.argv[2]
cols=["c1","c2","c3","c4","c5","c6","c7","c8","c9","c10","c11"]
with open(out,'w') as o:
    for i,l in enumerate(open(ink)):
        c,s=l.split()
        o.write(f"chr - {c} {c.replace('chr','')} 0 {s} {cols[i]}\n")
PY

##############################################################################
log "Step 2  non-overlapping ${WIN} bp windows"
##############################################################################
"$BT" makewindows -g "${OUT}/karyotype.tsv" -w "$WIN" > "${OUT}/windows.bed"
sort -k1,1 -k2,2n "${OUT}/windows.bed" -o "${OUT}/windows.bed"
log "windows: $(wc -l < "${OUT}/windows.bed")"

# helper: contig_N -> chrN for any 3-col bed on stdin
map_chr(){ awk 'BEGIN{OFS="\t"} $1 ~ /^contig_([1-9]|10|11)$/ {split($1,a,"_"); $1="chr"a[2]; print}'; }

##############################################################################
log "Step 3  gene density (count per window)"
##############################################################################
awk -F'\t' '$3=="gene"{print $1"\t"$4-1"\t"$5}' "$GFF3" | map_chr | sort -k1,1 -k2,2n > "${OUT}/genes.bed"
"$BT" intersect -a "${OUT}/windows.bed" -b "${OUT}/genes.bed" -c > "${OUT}/gene_density.bed"

##############################################################################
log "Step 4  TE coverage fractions (merge -> coverage), capped at 1.0"
##############################################################################
# total repeats (funannotate RepeatMasker fragments)
awk 'BEGIN{OFS="\t"}{print $1,$2,$3}' "$REPEATMASKER_BED" | map_chr | sort -k1,1 -k2,2n \
  | "$BT" merge -i - > "${OUT}/repeats.merged.bed"
"$BT" coverage -a "${OUT}/windows.bed" -b "${OUT}/repeats.merged.bed" \
  | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$NF}' > "${OUT}/total_repeat.bed"

# Copia / Gypsy from EDTA LTR pass list
for fam in Copia Gypsy; do
  low=$(echo "$fam" | tr 'A-Z' 'a-z')
  awk -F'\t' -v f="LTR/$fam" '$3=="repeat_region" && index($0,"classification="f){split($1,a,"_"); print "chr"a[2]"\t"$4-1"\t"$5}' "$LTR_GFF3" \
    | sort -k1,1 -k2,2n | "$BT" merge -i - > "${OUT}/${low}.merged.bed"
  "$BT" coverage -a "${OUT}/windows.bed" -b "${OUT}/${low}.merged.bed" \
    | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$NF}' > "${OUT}/${low}.bed"
  log "  $fam elements: $(wc -l < "${OUT}/${low}.merged.bed") merged"
done

##############################################################################
log "Step 5  GC content (${WIN} bp non-overlapping, de-noised line)"
##############################################################################
# build chr1-11 fasta once (reuse v1 copy if present & valid)
GFA="${WORKDIR}/data/genome_chr.fa"
if [ ! -s "${GFA}.fai" ]; then
  python3 - "$FASTA" "$GFA" <<'PY'
import sys
fa,out=sys.argv[1],sys.argv[2]
valid={f"contig_{i}":f"chr{i}" for i in range(1,12)}
w=False
with open(fa) as f,open(out,'w') as o:
    for line in f:
        if line[0]=='>':
            c=line[1:].split()[0]; w=c in valid
            if w:o.write(f">{valid[c]}\n")
        elif w:o.write(line)
PY
  "$ST" faidx "$GFA"
fi
"$BT" nuc -fi "$GFA" -bed "${OUT}/windows.bed" | awk 'NR>1{print $1"\t"$2"\t"$3"\t"$5}' > "${OUT}/gc.bed"

##############################################################################
log "Step 6  effectors (secreted proteins) -> points"
##############################################################################
python3 - "$GFF3" "$SECRETED_LIST" "${OUT}/effectors.bed" <<'PY'
import sys,re
gff,lst,out=sys.argv[1],sys.argv[2],sys.argv[3]
valid={f"contig_{i}":f"chr{i}" for i in range(1,12)}
ids=set(x.strip() for x in open(lst) if x.strip())
rows=[]
for line in open(gff):
    if line[0]=='#':continue
    p=line.rstrip('\n').split('\t')
    if len(p)<9 or p[2]!='mRNA' or p[0] not in valid:continue
    m=re.search(r'ID=([^;]+)',p[8])
    if m and m.group(1) in ids:
        rows.append((valid[p[0]],int(p[3]),int(p[4])))
rows.sort(key=lambda r:(int(r[0][3:]),r[1]))
open(out,'w').write(''.join(f"{c}\t{s}\t{e}\t1\n" for c,s,e in rows))
print("effectors:",len(rows))
PY

##############################################################################
log "Step 7  ncRNA  --  tRNA (GFF), snRNA (INFERNAL), rDNA collapsed loci"
##############################################################################
# tRNA from GFF
awk -F'\t' '$3=="tRNA"{print $1"\t"$4"\t"$5"\t1"}' "$GFF3" | map_chr | sort -k1,1 -k2,2n > "${OUT}/trna.bed"
log "  tRNA: $(wc -l < "${OUT}/trna.bed")"

# snRNA + rRNA from INFERNAL (E<1e-10), then collapse rRNA into NOR loci.
# NOTE: this is a cmscan --fmt 2 tblout (30 cols): family=$2 scaffold=$4
#       seq coords=$10/$11 E-value=$18  (verified against the file header).
awk 'BEGIN{OFS="\t"}
     !/^#/ && $18<1e-10 && $4 ~ /^contig_([1-9]|10|11)$/ {
       split($4,a,"_"); c="chr"a[2]
       s=($10<$11)?$10:$11; e=($10<$11)?$11:$10
       if($2 ~ /SU_rRNA/ || $2 ~ /5S_rRNA/ || $2 ~ /5_8S_rRNA/) print c,s,e > "'"${OUT}"'/rrna.raw.bed"
       else if($2 ~ /^U[0-9]/)                                   print c,s,e,"1" > "'"${OUT}"'/snrna.tmp"
     }' "$INFERNAL"
sort -k1,1 -k2,2n -u "${OUT}/snrna.tmp" > "${OUT}/snrna.bed" 2>/dev/null || : ; rm -f "${OUT}/snrna.tmp"
sort -k1,1 -k2,2n "${OUT}/rrna.raw.bed" -o "${OUT}/rrna.raw.bed"
log "  snRNA: $(wc -l < "${OUT}/snrna.bed")   raw rRNA hits: $(wc -l < "${OUT}/rrna.raw.bed")"
# collapse rRNA hits within 50 kb -> rDNA loci (NOR)
sort -k1,1 -k2,2n "${OUT}/rrna.raw.bed" | "$BT" merge -d 50000 -c 1 -o count \
  | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$4}' > "${OUT}/rdna_loci.bed"
log "  rDNA loci:"; cat "${OUT}/rdna_loci.bed"

##############################################################################
log "Step 8  per-track p98 colour caps + GC range -> caps.tsv"
##############################################################################
pct(){ awk '{print $4}' "$1" | sort -n | awk -v p="$2" '{a[NR]=$1} END{i=int(NR*p); if(i<1)i=1; print a[i]}'; }
{
  echo -e "track\tcap"
  echo -e "gene_p98\t$(pct "${OUT}/gene_density.bed" 0.98)"
  echo -e "repeat_p98\t$(pct "${OUT}/total_repeat.bed" 0.98)"
  echo -e "copia_p98\t$(pct "${OUT}/copia.bed" 0.98)"
  echo -e "gypsy_p98\t$(pct "${OUT}/gypsy.bed" 0.98)"
  echo -e "gc_p02\t$(pct "${OUT}/gc.bed" 0.02)"
  echo -e "gc_p98\t$(pct "${OUT}/gc.bed" 0.98)"
  echo -e "gc_min\t$(awk '{print $4}' "${OUT}/gc.bed" | sort -n | head -1)"
  echo -e "gc_max\t$(awk '{print $4}' "${OUT}/gc.bed" | sort -n | tail -1)"
} > "${OUT}/caps.tsv"
column -t "${OUT}/caps.tsv"

##############################################################################
log "DONE  ->  ${OUT}"
##############################################################################
for f in "${OUT}"/*.bed "${OUT}"/*.tsv "${OUT}"/karyotype.circos.txt; do
  printf "  %-26s %s\n" "$(basename "$f")" "$(wc -l < "$f") lines"
done

##############################################################################
# Publication-quality CIRCOS  --  G. cichoracearum  --  ENGINE: R circlize
#
# v2 redesign (vs 02.plot_circos.R):
#   * density tracks = HEATMAP rings (smooth gradients), not spiky histograms
#   * per-track p98 colour caps (from caps.tsv) so 95% of genome isn't washed out
#   * colored ideogram + Mb tick axis + bold chr labels
#   * rRNA collapsed to highlighted rDNA / NOR loci (not 268 fake points)
#   * effectors as red lollipops (the pathogen headline), tRNA/snRNA glyphs
#   * de-noised GC area-line (100 kb non-overlapping)
#   * filled centre: italic species name + genome-stats block
#   * legends drawn in base graphics in the bottom margin (citrus layout)
#   * Cairo devices -> true vector PDF + 1200 dpi TIFF/JPEG/PNG, Arial-like font
##############################################################################

suppressPackageStartupMessages({ library(circlize); library(Cairo) })

args <- commandArgs(trailingOnly = FALSE)
file_arg <- "--file="
script_path <- normalizePath(sub(file_arg, "", args[grep(file_arg, args)]))
DIR  <- normalizePath(file.path(dirname(script_path), ".."))
DAT  <- file.path(DIR, "data/v2")
OUT  <- file.path(DIR, "results"); dir.create(OUT, showWarnings=FALSE, recursive=TRUE)

## ---- palette ---------------------------------------------------------------
# 11 chromosome colours (clean qualitative, citrus-like)
CHR_COL <- c("#4E9D5B","#D9772B","#3F7FB3","#7E5BA6","#E0C13F","#2E7D4F",
             "#C85A2B","#9E2B25","#2C6FA6","#5BB8C4","#B07AA1")
COL_GENE   <- "#E6770B"   # orange
COL_REPEAT <- "#6A3D9A"   # purple
COL_COPIA  <- "#D7301F"   # vermillion
COL_GYPSY  <- "#1B7837"   # green
COL_EFF    <- "#CC2222"   # effector red
COL_RDNA   <- "#08519C"   # rDNA / rRNA blue
COL_TRNA   <- "#7F7F7F"   # tRNA grey
COL_SNRNA  <- "#2EA0C8"   # snRNA cyan
COL_GC     <- "#08519C"   # GC blue

ramp <- function(hi) colorRamp2(c(0, .5, 1), c("#FFFFFF", colorRampPalette(c("#FFFFFF",hi))(3)[2], hi))

## ---- load ------------------------------------------------------------------
rd  <- function(f,cn) { x <- read.table(file.path(DAT,f)); colnames(x) <- cn; x }
kar <- rd("karyotype.tsv", c("chr","size")); chrs <- kar$chr; sz <- setNames(kar$size,kar$chr)
gene <- rd("gene_density.bed", c("chr","s","e","v"))
rep_ <- rd("total_repeat.bed", c("chr","s","e","v"))
cop  <- rd("copia.bed",        c("chr","s","e","v"))
gyp  <- rd("gypsy.bed",        c("chr","s","e","v"))
gc   <- rd("gc.bed",           c("chr","s","e","v"))
eff  <- rd("effectors.bed",    c("chr","s","e","v"))
trna <- rd("trna.bed",         c("chr","s","e","v"))
snrna<- rd("snrna.bed",        c("chr","s","e","v"))
rdna <- rd("rdna_loci.bed",    c("chr","s","e","n"))
caps <- setNames(read.table(file.path(DAT,"caps.tsv"),header=TRUE)$cap,
                 read.table(file.path(DAT,"caps.tsv"),header=TRUE)$track)

GENE_CAP <- caps["gene_p98"]; REP_CAP <- caps["repeat_p98"]
COP_CAP  <- caps["copia_p98"]; GYP_CAP <- caps["gypsy_p98"]
GC_LO <- 0.37; GC_HI <- 0.585                       # show NOR spike, baseline low

cf_gene <- ramp(COL_GENE); cf_rep <- ramp(COL_REPEAT)
cf_cop  <- ramp(COL_COPIA); cf_gyp <- ramp(COL_GYPSY)

# genome stats for centre block
ST_SPECIES <- "G. cichoracearum"
ST_LINES <- c("166.5 Mb  |  11 chromosomes",
              "22,907 genes",
              "255 candidate effectors",
              "837 LTR-RTs (539 Copia / 298 Gypsy)")

## ---- heatmap panel factory -------------------------------------------------
# pw<1 spreads sparse low-density signal toward saturated colours (citrus-like
# vivid bands) without changing the data — purely a colour-mapping gamma.
heat_panel <- function(df, cap, cf, pw=0.65) function(x,y) {
  ch <- CELL_META$sector.index; d <- df[df$chr==ch,]
  if(nrow(d)) {
    val <- (pmin(d$v, cap)/cap)^pw
    circos.rect(d$s, 0, d$e, 1, col=cf(val), border=NA)
  }
  circos.rect(CELL_META$xlim[1],0,CELL_META$xlim[2],1, col=NA, border="#808080", lwd=0.3)
}

## ---- main draw -------------------------------------------------------------
draw_circos <- function() {
  par(family="sans", xpd=NA, mar=c(0.4,0.4,0.4,0.4))
  circos.clear()
  circos.par(start.degree=90, gap.after=c(rep(1.4,10),9),
             canvas.xlim=c(-1.18,1.18), canvas.ylim=c(-1.34,1.16),
             track.margin=c(0.004,0.004), cell.padding=c(0,0,0,0),
             points.overflow.warning=FALSE)
  circos.initialize(factors=chrs, xlim=cbind(rep(0,length(chrs)), as.numeric(sz)))

  ## 1. ideogram (coloured) + Mb ticks + chr label
  circos.track(ylim=c(0,1), track.height=0.052, bg.border=NA, panel.fun=function(x,y){
    ch <- CELL_META$sector.index; i <- which(chrs==ch); xl <- CELL_META$xlim
    circos.rect(xl[1],0,xl[2],1, col=CHR_COL[i], border="white", lwd=0.6)
    circos.text(mean(xl),0.5, sub("chr","",ch), facing="inside", niceFacing=TRUE,
                cex=0.78, font=2, col="white")
    mj <- seq(0, xl[2], by=5e6)
    circos.axis(h="top", major.at=mj, labels=paste0(mj/1e6), labels.cex=0.42,
                major.tick.length=convert_y(1.2,"mm"), lwd=0.5, labels.col="#333333",
                col="#333333", labels.facing="clockwise")
  })

  ## 2. gene density heatmap
  circos.track(ylim=c(0,1), track.height=0.078, bg.border=NA, panel.fun=heat_panel(gene,GENE_CAP,cf_gene,pw=0.85))

  ## 3. effectors (lollipops)
  circos.track(ylim=c(0,1), track.height=0.052, bg.col="#FBFBFB", bg.border="#E5E5E5", panel.fun=function(x,y){
    ch <- CELL_META$sector.index; d <- eff[eff$chr==ch,]
    if(nrow(d)){ m <- (d$s+d$e)/2
      circos.segments(m, 0, m, 0.78, col=COL_EFF, lwd=0.45)
      circos.points(m, rep(0.86,nrow(d)), pch=17, cex=0.34, col=COL_EFF) }
  })

  ## 4. total repeat heatmap
  circos.track(ylim=c(0,1), track.height=0.066, bg.border=NA, panel.fun=heat_panel(rep_,REP_CAP,cf_rep,pw=0.62))
  ## 5. Copia heatmap
  circos.track(ylim=c(0,1), track.height=0.052, bg.border=NA, panel.fun=heat_panel(cop,COP_CAP,cf_cop,pw=0.55))
  ## 6. Gypsy heatmap
  circos.track(ylim=c(0,1), track.height=0.052, bg.border=NA, panel.fun=heat_panel(gyp,GYP_CAP,cf_gyp,pw=0.55))

  ## 7. ncRNA: rDNA highlight band + tRNA + snRNA
  circos.track(ylim=c(0,1), track.height=0.058, bg.col="#FCFCFC", bg.border="#E5E5E5", panel.fun=function(x,y){
    ch <- CELL_META$sector.index
    dR <- rdna[rdna$chr==ch,]
    if(nrow(dR)) for(i in 1:nrow(dR)) circos.rect(dR$s[i],0,dR$e[i],1, col=COL_RDNA, border=NA)
    dT <- trna[trna$chr==ch,]; if(nrow(dT)) circos.points((dT$s+dT$e)/2, rep(0.34,nrow(dT)), pch=16, cex=0.20, col=COL_TRNA)
    dS <- snrna[snrna$chr==ch,]; if(nrow(dS)) circos.points((dS$s+dS$e)/2, rep(0.74,nrow(dS)), pch=17, cex=0.40, col=COL_SNRNA)
  })

  ## 8. GC content (area line)
  circos.track(ylim=c(GC_LO,GC_HI), track.height=0.085, bg.col="#F7F7F7", bg.border="#E5E5E5", panel.fun=function(x,y){
    ch <- CELL_META$sector.index; d <- gc[gc$chr==ch,]
    if(nrow(d)>1){ m <- (d$s+d$e)/2; v <- pmin(pmax(d$v,GC_LO),GC_HI)
      circos.lines(m, v, col=adjustcolor(COL_GC,0.30), area=TRUE, baseline=GC_LO, border=NA)
      circos.lines(m, v, col=COL_GC, lwd=0.5) }
  })

  ## ---- centre: species + stats ----
  text(0, 0.135, ST_SPECIES, font=4, cex=1.18, col="#222222")
  segments(-0.16,0.075,0.16,0.075, col="#999999", lwd=0.8)
  for(i in seq_along(ST_LINES))
    text(0, 0.018 - (i-1)*0.072, ST_LINES[i], cex=0.62, col="#444444")

  ## ---- title ----
  text(0, 1.115, "Golovinomyces cichoracearum", font=3, cex=1.28, col="#1A1A1A")

  ## ---- legends (base graphics, bottom margin, citrus-style 4 groups) ----
  ly <- -1.155; lcex <- 0.62; tcex <- 0.66
  # group 1: Genome features
  x1 <- -1.16
  text(x1, ly+0.10, "Genome features", adj=0, font=2, cex=tcex)
  points(x1+0.02, ly+0.02, pch=15, col=COL_GENE, cex=1.3); text(x1+0.06, ly+0.02, "Gene density", adj=0, cex=lcex)
  lines(c(x1+0.0,x1+0.04), c(ly-0.06,ly-0.06), col=COL_GC, lwd=3);  text(x1+0.06, ly-0.06, "GC content", adj=0, cex=lcex)
  # group 2: Transposable elements
  x2 <- -0.58
  text(x2, ly+0.10, "Transposable elements", adj=0, font=2, cex=tcex)
  points(x2+0.02, ly+0.02, pch=15, col=COL_COPIA, cex=1.3);  text(x2+0.06, ly+0.02, "Copia LTR", adj=0, cex=lcex)
  points(x2+0.02, ly-0.06, pch=15, col=COL_GYPSY, cex=1.3);  text(x2+0.06, ly-0.06, "Gypsy LTR", adj=0, cex=lcex)
  points(x2+0.02, ly-0.14, pch=15, col=COL_REPEAT, cex=1.3); text(x2+0.06, ly-0.14, "Total repeats", adj=0, cex=lcex)
  # group 3: ncRNA
  x3 <- 0.16
  text(x3, ly+0.10, "ncRNA", adj=0, font=2, cex=tcex)
  points(x3+0.02, ly+0.02, pch=15, col=COL_RDNA, cex=1.3);  text(x3+0.06, ly+0.02, "rDNA (NOR)", adj=0, cex=lcex)
  points(x3+0.02, ly-0.06, pch=16, col=COL_TRNA, cex=1.0);  text(x3+0.06, ly-0.06, "tRNA", adj=0, cex=lcex)
  points(x3+0.02, ly-0.14, pch=17, col=COL_SNRNA, cex=1.0); text(x3+0.06, ly-0.14, "snRNA", adj=0, cex=lcex)
  # group 4: Effectors
  x4 <- 0.72
  text(x4, ly+0.10, "Candidate effectors", adj=0, font=2, cex=tcex)
  points(x4+0.02, ly+0.02, pch=17, col=COL_EFF, cex=1.0);  text(x4+0.06, ly+0.02, "Secreted proteins", adj=0, cex=lcex)

  circos.clear()
}

## ---- render all formats ----------------------------------------------------
W <- 9; H <- 9.4
message("PDF (vector)...")
CairoPDF(file.path(OUT,"GC_circos.pdf"), width=W, height=H); draw_circos(); dev.off()
message("PNG draft (150 dpi for self-check)...")
CairoPNG(file.path(OUT,"GC_circos_draft.png"), width=W, height=H, units="in", dpi=150); draw_circos(); dev.off()

if (Sys.getenv("FINAL")=="1") {
  message("TIFF 1200 dpi..."); CairoTIFF(file.path(OUT,"GC_circos.tiff"), width=W, height=H, units="in", dpi=1200); draw_circos(); dev.off()
  message("JPEG 1200 dpi..."); CairoJPEG(file.path(OUT,"GC_circos.jpeg"), width=W, height=H, units="in", dpi=1200, quality=100); draw_circos(); dev.off()
  message("PNG 1200 dpi...");  CairoPNG (file.path(OUT,"GC_circos.png"),  width=W, height=H, units="in", dpi=1200); draw_circos(); dev.off()
}
message("circlize done -> ", OUT)

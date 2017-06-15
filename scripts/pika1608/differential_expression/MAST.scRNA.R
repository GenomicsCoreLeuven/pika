print("--R-MAST-- Loading packages needed--")
require(data.table)
library("MAST")
library("ggplot2")
library("pheatmap")
library("rsvd")
require("GGally")
require("limma")
require("reshape2")
require("knitr")
require("TxDb.Hsapiens.UCSC.hg19.knownGene")
require("stringr")
require("NMF")
require("RColorBrewer")

print("--R-MAST--defining variables--")
args = commandArgs(trailingOnly = TRUE)
condition1 <- args[1]
condition2 <- args[2]

print("--R-MAST--some predetermined arguments--")
freq_expressed <- 0.2
FCTHRESHOLD <- log2(1.5)

print("--R-MAST--Preparing data--")
expr <- read.delim("all_data.txt", row.names = 1)
cdata <- read.delim("sample_condition_wellkey.csv", row.names = 1, sep = ",")
noint <- rownames(expr) %in% c("__alignment_not_unique","__no_feature")
keep = !noint
expr <- expr[keep,]
fdata <- data.frame(Gene = rownames(expr))

print("--R-MAST--making dataset --")
RawDat <- FromMatrix(as.matrix(expr), cdata, fdata)

print("--R-MAST-adaptive thresholding--")

print("--R-MAST-making threshold plot--")
setEPS()
postscript(paste(condition1,"_vs_", condition2, "_thresholds.eps", sep=""))
thresh <- thresholdSCRNACountMatrix(assay(RawDat), nbins = 40, min_per_bin = 30, data_log=FALSE)
par(mfrow=c(5,4))
plot(thresh)
dev.off()

print("--R-MAST-filtering out low quality--")
assays(RawDat) <- list(thresh=thresh$counts_threshold, tpm=assay(RawDat))
expressed_genes <- freq(RawDat) > freq_expressed
RawDat <- RawDat[expressed_genes,]

print("--R-MAST-setting the reference to the normal level--")
cond<-factor(colData(RawDat)$CONDITION)
cond<-relevel(cond,condition1)
colData(RawDat)$CONDITION<-cond
zlmCond <- zlm(~CONDITION, RawDat)

print("--R-MAST-testing the condition coefficient--")
summaryCond <- summary(zlmCond, doLRT=condition2) 

print("--R-MAST-top 10 genes by contrast in log fold change--")
top10 <- print(summaryCond, n=10)
write.csv(top10, file=paste(condition1, "_vs_", condition2, ".top10_on_logFC.csv", sep = ""))

print("--R-MAST-top 10 genes by	discrete Z-score--")
discrete <- print(summaryCond, n=10, by='D')
write.csv(discrete, file=paste(condition1,"_vs_",condition2, ".top10_on_discrete.csv", sep = ""))

print("--R-MAST-top 10 genes by	continuous Z-score--")
continu <- print(summaryCond, n=10, by='C')
write.csv(continu, file=paste(condition1,"_vs_",condition2, ".top10_on_continuous.csv", sep = ""))

print("--R-MAST-all of the differentially expressed genes with fdr--")
summaryDt <- summaryCond$datatable
fcHurdle <- merge(summaryDt[contrast==condition2 & component=='H',.(primerid, `Pr(>Chisq)`)],summaryDt[contrast==condition2 & component=='logFC', .(primerid, coef, ci.hi, ci.lo)], by='primerid')
fcHurdle[,fdr:=p.adjust(`Pr(>Chisq)`, 'fdr')]
fcHurdleSig <- merge(fcHurdle[fdr<.10 & abs(coef)>FCTHRESHOLD],as.data.table(mcols(RawDat)), by='primerid')
setorder(fcHurdleSig, fdr)
write.csv(fcHurdleSig, file=paste(condition1, "_vs_", condition2, ".differentially_expressed_genes.csv", sep=""))

print("--R-MAST-make a violin plot to show difference between genes of each condition--")
entrez_to_plot <- fcHurdleSig[1:50, primerid]
flat_dat <- as(RawDat[entrez_to_plot,], 'data.table')
setEPS()
postscript(paste(condition1, "_vs_",condition2,"_top_50_DE_genes", sep=""))
dev.new(width=12, height=8)
ggbase <- ggplot(flat_dat, aes(x=CONDITION, y=thresh, color=CONDITION)) + geom_jitter()+facet_wrap(~primerid, scale='free_y')+ggtitle("DE Genes in Diabetes type 2 patients")
plot(ggbase+geom_violin())
dev.off()

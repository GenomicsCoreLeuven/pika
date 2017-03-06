library("DESeq2")
library("RColorBrewer")
library("gplots")
library("vsn")
library("pheatmap")
library("ggplot2")
#prepare the data
args = commandArgs(trailingOnly = TRUE)
print("--R--DESeq2-- Loading samples")
print(getwd())
samples = read.csv("samples.csv")
#HTSeq input
dds = DESeqDataSetFromHTSeqCount(sampleTable=samples, directory = getwd(), design = ~ condition)
#prefiltering
print("--R--DESeq2-- Prefiltering")
dds = dds[rowSums(counts(dds)) > 1,]
#factor levels
print("--R--DESeq2-- Factor Levels")
dds$condition = factor(dds$condition)
#DE analysis
print("--R--DESeq2-- DE analysis")
dds = DESeq(dds)
#res = results(dds)
#resOrdered = res[order(res$padj),]
#summary(res)
#write.csv(as.data.frame(resOrdered), file=paste(condition1, "_vs_", condition2, "_results.csv", sep=""))
#Visualization
print("--R--DESeq2-- Visualization")
#rld = rlog(dds, blind=FALSE)
#vsd = varianceStabilizingTransformation(dds, blind=FALSE)
vsd.fast = vst(dds, blind=FALSE)
#PCA
print("--R--DESeq2-- PCA plot")
#postscript(paste(condition1,"_vs_",condition2,".PCAplot.eps", sep=""))
#plotPCA(rld, intgroup=c("condition"))
#dev.off()
#postscript(paste(condition1,"_vs_",condition2,".PCAplot_adjusted.eps", sep=""))
data = plotPCA(vsd.fast, intgroup=c("condition"), returnData=TRUE)
#percentVar = round(100 * attr(data, "percentVar"))
#ggplot(data, aes(PC1, PC2, color=condition)) + geom_point(size=3) + xlab(paste0("PC1: ",percentVar[1],"% variance")) + ylab(paste0("PC2: ",percentVar[2],"% variance"))  + geom_text(aes(label=colnames(assay(rld))),hjust=0.6, vjust=-0.4)
#dev.off()




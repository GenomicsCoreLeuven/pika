library("DESeq2")
library("RColorBrewer")
library("gplots")
library("vsn")
library("pheatmap")
library("ggplot2")

#prepare the data
args = commandArgs(trailingOnly = TRUE)
condition1 <- args[1]
condition2 <- args[2]
print(paste("--R--DESeq2-- Condition ", condition1, " vs ", condition2))
print("--R--DESeq2-- Loading samples")
print(getwd())
all_samples = read.csv("samples.csv")
samples = subset(all_samples, condition %in% c(condition1, condition2))

#HTSeq input
dds = DESeqDataSetFromHTSeqCount(sampleTable=samples, directory = getwd(), design = ~ condition)

#prefiltering
print("--R--DESeq2-- Prefiltering")
dds = dds[rowSums(counts(dds) >= 5) >= 3,]

#factor levels
print("--R--DESeq2-- Factor Levels")
dds$condition = factor(dds$condition, levels=c(condition1, condition2))

#DE analysis
print("--R--DESeq2-- DE analysis")
dds = DESeq(dds)
res = results(dds)
resOrdered = res[order(res$padj),]
summary(res)
write.csv(as.data.frame(resOrdered), file=paste(condition1, "_vs_", condition2, "_results.csv", sep=""))

#Visualization
print("--R--DESeq2-- Visualization")
rld = rlog(dds, blind=FALSE)
vsd = varianceStabilizingTransformation(dds, blind=FALSE)
vsd.fast = vst(dds, blind=FALSE)

#Heatmap sample-to-sample distances
print("--R--DESeq2-- Heatmap sample-to-sample distances")
sampleDists = dist(t(assay(rld)))
sampleDistMatrix = as.matrix(sampleDists)
rownames(sampleDistMatrix) = paste(rld$ rld$condition)
colnames(sampleDistMatrix) = NULL
colors = colorRampPalette(rev(brewer.pal(9, "Blues")))(255)
setEPS()
postscript(paste(condition1,"_vs_",condition2,".heatmap_sample_to_sample_distances.eps", sep = ""))
pheatmap(sampleDistMatrix, clustering_distance_rows=sampleDists, clustering_distance_cols=sampleDists, col=colors)
dev.off()

#PCA
print("--R--DESeq2-- PCA plot")
postscript(paste(condition1,"_vs_",condition2,".PCAplot.eps", sep=""))
plotPCA(rld, intgroup=c("condition"))
dev.off()
postscript(paste(condition1,"_vs_",condition2,".PCAplot_adjusted.eps", sep=""))
data = plotPCA(rld, intgroup=c("condition"), returnData=TRUE)
percentVar = round(100 * attr(data, "percentVar"))
ggplot(data, aes(PC1, PC2, color=condition)) + geom_point(size=3) + xlab(paste0("PC1: ",percentVar[1],"% variance")) + ylab(paste0("PC2: ",percentVar[2],"% variance"))  + geom_text(aes(label=colnames(assay(rld))),hjust=0.6, vjust=-0.4)
dev.off()

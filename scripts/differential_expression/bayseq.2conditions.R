library("DESeq2")
library("RColorBrewer")
library("gplots")
library("vsn")
library("ggplot2")
library("baySeq")
#prepare the data
args = commandArgs(trailingOnly = TRUE)
condition1 <- args[1]
condition2 <- args[2]
print(paste("--R--baySeq-- Condition ", condition1, " vs ", condition2))
print("--R--baySeq-- Loading samples")
print(getwd())
all_samples = read.csv("samples.csv")
samples = subset(all_samples, condition %in% c(condition1, condition2))
#HTSeq input
dds = DESeqDataSetFromHTSeqCount(sampleTable=samples, directory = getwd(), design = ~ condition)
replicates=colData(dds)$condition
NDE=replace(c(1:length(colData(dds)$condition)),c(1:length(colData(dds)$condition)) %in% c(2:length(colData(dds)$condition)), 1)
groups=list(NDE=NDE,DE=replicates)
CD = new("countData", data=assay(dds), replicates=replicates,groups=groups)
libsizes(CD)=getLibsizes(CD)
#plot the MA
setEPS()
postscript(paste(condition1,"_vs_",condition2,".bayseq_maplot.eps", sep = ""))
plotMA.CD(CD, samplesA=condition1, samplesB=condition2, col=c(rep("red",100),rep("black",900)))
dev.off()
cl=NULL
#The Negative-Binomial Approach
CD=getPriors.NB(CD,samplesize=1000,estimation="QL",cl=cl)
CD=getLikelihoods(CD,cl=cl,bootStraps=3,verbose=FALSE)
#Output of the DE list
write.csv(as.data.frame(topCounts(CD,group="DE",normaliseData=TRUE, number=10,FDR=1)), file=paste(condition1, "_vs_", condition2, "_bayseq_results.csv", sep=""))
#creating the posteriors plot
setEPS()
postscript(paste(condition1,"_vs_",condition2,".bayseq_posteriors.eps", sep = ""))
plotPosteriors(CD,group="DE", col=c(rep("red",100), rep("black",900)), samplesA=which(replicates==condition1), samplesB=which(replicates==condition2))
dev.off()


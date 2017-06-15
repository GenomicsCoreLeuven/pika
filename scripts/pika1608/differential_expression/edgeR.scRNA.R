library("edgeR")
library(methods)
args = commandArgs(trailingOnly = TRUE)
condition1 <- args[1]
condition2 <- args[2]
smallest_group_count = 3

print("--R--edgeR-- Loading samples")
all_samples = read.csv("samples.csv")
samples = subset(all_samples, condition %in% c(condition1, condition2))
counts = readDGE(samples$countf)$counts
noint = rownames(counts) %in% c("no_feature","ambiguous","too_low_aQual","not_aligned","alignment_not_unique","__alignment_not_unique","__no_feature")

print("--R--edgeR-- Counts per Million/Reads per Kilobase per Million")
cpms = cpm(counts)
keep = rowSums(cpms>1)>=smallest_group_count &! noint
counts = counts[keep,]
colnames(counts) = samples$shortname

print("--R--edgeR-- Calculate Normalization Factors")
d = DGEList(counts=counts, group=samples$condition)
d = calcNormFactors(d)

print("--R--edgeR-- Create MDS plot")
setEPS()
postscript(paste(condition1, "_vs_", condition2, ".MDS_plot.eps", sep = ""))
plotMDS(d, labels=samples$shortname, col=c("darkgreen","blue","red","lawngreen","deepskyblue","brown","yellow","blueviolet","orange","chocolate")[samples$condition])
dev.off()

print("--R--edgeR-- Estimate Common Negative Binomial Despersion by Conditional Maximum Likelihood")
d = estimateCommonDisp(d, verbose=TRUE)

print("--R--edgeR-- Estimate Empirical Bayes Tagwise Dispersion Values")
d = estimateTagwiseDisp(d)

print("--R--edgeR-- Create plot of the Mean variance relationship")
setEPS()
postscript(paste(condition1, "_vs_", condition2, ".MeanVar_plot.eps", sep = ""))
plotMeanVar(d, show.tagwise.vars=TRUE,NBline=TRUE)
dev.off()

print("--R--edgeR-- Create plot of the Biological Coefficient of Variation")
setEPS()
postscript(paste(condition1, "_vs_", condition2, ".BCV_plot.eps", sep = ""))
plotBCV(d)
dev.off()

print("--R--edgeR-- Create Barplot")
setEPS()
postscript(paste(condition1, "_vs_", condition2, ".libsize_plot.eps", sep = ""))
barplot(d$samples$lib.size*1e-6, ylab="Library size (millions)")
dev.off()

print("--R--edgeR-- Test differential expression: Exact Test")
de = exactTest(d, pair=c(condition1, condition2))
tt = topTags(de, n=nrow(d))

print("--R--edgeR-- Depth-adjusted reads per million")
nc = cpm(d, normalized.lib.sizes=TRUE)
rn = rownames(tt$table)

print("--R--edgeR-- Create plot of the log-fold change vs log-average expression")
deg = rn[tt$table$FDR < 0.05]
setEPS()
postscript(paste(condition1, "_vs_", condition2, ".log-foldChange_vs_log-average_expression.eps", sep = ""))
plotSmear(d, de.tags=deg)
dev.off()
write.csv(tt$table, file=paste(condition1, "_vs_", condition2, ".toptags_edgeR.csv", sep = ""))

print("--R--edgeR-- Print file with summary of stats")
write.csv(d$samples, file=paste(condition1, "_vs_", condition2, ".normalization.summary.txt", sep = ""))

fileConn<-file(paste(condition1, "_vs_", condition2, ".BCV.summary.txt", sep = ""))
writeLines(c("Biological Coefficient of Variation:", "---------------",sqrt(d$common.disp)),fileConn)
close(fileConn)

##[HELP] This script has to be run on your local desktop
##[HELP] This script needs scater and mvoutlier installed to find the outliers
##[HELP] To install these packages type source("https://bioconductor.org/biocLite.R")
##[HELP] biocLite("scater") and install.packages("mvoutlier")
#
library("scater")
library("mvoutlier")

count_data <- read.delim("all_data.txt", row.names = 1)
cell_data <- read.delim("sample_condition.csv", row.names = 1, sep = ",")

pd <- new("AnnotatedDataFrame", data = cell_data)
gene_df <- data.frame(Gene = rownames(count_data))
rownames(gene_df) <- gene_df$Gene
fd <- new("AnnotatedDataFrame", data = gene_df)
example_sceset <- newSCESet(countData = count_data, phenoData = pd,
                            featureData = fd)
example_sceset

#the expressed genes that you can be checked and investigated for expression
plotExpression(example_sceset, rownames(example_sceset)[1:6],
               x = "CONDITION", exprs_values = "exprs", colour = "CONDITION")

example_sceset <- calculateQCMetrics(example_sceset, feature_controls = 1:20)
varLabels(example_sceset)

noint <- rownames(counts(example_sceset)) %in% c("__alignment_not_unique","__no_feature","__ambiguous")
keep_feature <- rowSums(counts(example_sceset) > 0) > 4 &! noint
example_sceset <- example_sceset[keep_feature,]

## Plot QC with features
plotQC(example_sceset, type = "highest-expression", exprs_values = "counts")

## cell QC
plotPhenoData(example_sceset, aes(x = CONDITION, y = total_features,
                                  colour = log10_total_counts))

## Make a PCA plot of the data
plotPCA(example_sceset, ncomponents=2 , colour_by="CONDITION", return_SCESet = TRUE)

## Check the outliers and identify them
example_sceset <- plotPCA(example_sceset, pca_data_input = "pdata", 
                          detect_outliers = TRUE, return_SCESet = TRUE)
qplot(example_sceset$total_features,binwidth=100,fill=example_sceset$CONDITION)

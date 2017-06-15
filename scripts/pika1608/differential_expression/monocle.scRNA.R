print("--R-monocle2-- Loading packages needed--")
library("monocle")
library("ggplot2")

print("--R-monocle2--defining variables--")
args = commandArgs(trailingOnly = TRUE)
condition1 <- args[1]
condition2 <- args[2]

print("--R-monocle2--Preparing data--")
HSMM_expr_matrix <- read.delim("all_data.txt", row.names = 1)
HSMM_sample_sheet <- read.delim("sample_condition.csv", row.names = 1, sep = ",")

print("--R-monocle2--making dataset --") 
pd <- new("AnnotatedDataFrame", data = HSMM_sample_sheet)
HSMM <- newCellDataSet(as.matrix(HSMM_expr_matrix), 
                       phenoData = pd, expressionFamily = negbinomial())

print("--R-monocle2--estimate normalisation factors--")
HSMM <- estimateSizeFactors(HSMM)
#HSMM <- estimateDispersions(HSMM)

print("--R-monocle2-filter out low quality genes--")
HSMM <- detectGenes(HSMM, min_expr = 0.1)

print("--R-monocle2-filter out low expressed genes or artefact genes--")
expressed_genes <- row.names(subset(fData(HSMM), num_cells_expressed >= 2))

print("--R-monocle2-making the pie chart in R--")
pie <- ggplot(pData(HSMM), aes(x = factor(1), fill = factor(CONDITION))) +
  geom_bar(width = 1)

print("--R-monocle2-trying to save the pie chart after analysis--")
setEPS()
postscript(paste(condition1, "_vs_", condition2, ".pie_chart.eps", sep =""))
pie + coord_polar(theta = "y") +
  theme(axis.title.x=element_blank(), axis.title.y=element_blank())
dev.off()

print("--R-monocle2-differential gene testing with the genes that were filtered--")
#test for differential gene expression in expressed genes over multiple cells
#use 10 cores for faster computing
#through the sample condition file we have to use CONDITION as fullModelFormulaStr or it won't differentiate between the different conidtions
diff_test_res <- differentialGeneTest(HSMM[expressed_genes,],
                                      fullModelFormulaStr="~CONDITION", cores = 10)

print("--R-monocle2-Only significant genes are kept in the results--")
# Select genes that are significant at an FDR < 10%
sig_genes <- subset(diff_test_res, qval < 0.1)
diff_test_res <- sig_genes[,c("pval", "qval")]
diff_test_res <- sig_genes[order(sig_genes[,"pval"]),]

print("--R-monocle2-printing relevant results in a table--")
#order on pvalue 
relevant_results <- diff_test_res[,c("pval", "qval")]
noint <- c("__alignment_not_unique","__ambiguous","__no_feature","__ambiguous","__too_low_aQual","__not_aligned")
relevant_results <- relevant_results[!(row.names(relevant_results) %in% noint),]
write.csv(relevant_results, file=paste(condition1, "_vs_", condition2, ".diff_test_res.csv", sep = ""))

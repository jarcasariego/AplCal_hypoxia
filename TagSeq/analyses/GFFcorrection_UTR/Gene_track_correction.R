library(dplyr)
library(tidyr)

## Fix gene track

gene <- read.delim("UTR_add_extend/AplCal.GFFannotation.gene_sorted.gff", 
           sep = "\t", header = FALSE)

three_UTR <- read.delim("UTR_add_extend/AplCal.GFFannotation.3UTR_3kb_corrected.gff", 
                         sep = "\t", header = FALSE)
five_UTR <- read.delim("UTR_add_extend/AplCal.GFFannotation.5UTR_3kb_corrected.gff", 
                        sep = "\t", header = FALSE)
mRNA <- read.delim("UTR_add_extend/AplCal.GFFannotation.mRNA_sorted.gff", 
                                sep = "\t", header = FALSE)

## 5' and 3'UTRs locate differently in fw and rev strands so i need to modify the gene track accordingly
gene2 <-merge(three_UTR, five_UTR, by = "V9")
gene2plus <- gene2[which(gene2$V7.x=="+"),]
gene2minus <- gene2[which(gene2$V7.x=="-"),]

head(gene2plus)
names(gene2plus)

geneplus <- gene2plus[,c(2:4,13,6:9,1)]
geneminus <- gene2minus[,c(2:5,14:17,1)]

head(geneplus)

colnames(geneminus) <- c("V1","V2","V3","V4","V5","V6","V7","V8","V9")
colnames(geneplus) <- c("V1","V2","V3","V4","V5","V6","V7","V8","V9")

gene_new <- rbind(geneplus, geneminus)                        

gene_new$V3 <- gsub("3prime_UTR", "gene", gene_new$V3)
gene_new$V3 <- gsub("5prime_UTR", "gene", gene_new$V3)

gene_new$ID <- gene_new$V9
gene_new <- separate(data = gene_new, col = ID, into = "ID", sep = ";")

gene$ID <- gene$V9
gene <- separate(data = gene, col = ID, into = "ID", sep = ";")

gene_new <- gene_new[!duplicated(gene_new$ID), ]

missing_genes <- anti_join(gene, gene_new
                           , by = c("ID"))
gene_new <- rbind(gene_new, missing_genes)

gene_new <- gene_new[,-10]

write.table(gene_new, file = "UTR_add_extend/AplCal.GFFannotation.gene_3UTR_3kb_extended.gff", 
            sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)


### Fix mRNA track
transcript <- mRNA

head(transcript)

trans_sep <- transcript
trans_sep$ID <- trans_sep$V9  
trans_sep <- separate(trans_sep, ID, c("V10", "ID"), sep = ";")
trans_sep$ID <- gsub("Parent", "ID", trans_sep$ID)

gene_sep <- gene_new
gene_sep$ID <- gene_sep$V9
gene_sep <- separate(data = gene_sep, col = ID, into = "ID", sep = ";")

trans_new <- merge(trans_sep, gene_sep, by = "ID")
trans_new <- trans_new[,c(2:4,15:16,7:11,1)]
colnames(trans_new) <- c("V1","V2","V3","V4","V5","V6","V7","V8","V9","V10","ID")
trans_new <- trans_new[!duplicated(trans_new$V10), ]
missing_trans <- anti_join(trans_sep, trans_new, by = c("V10"))
trans_new <- rbind(trans_new, missing_trans)
trans_new <- trans_new[, -c(10:11)]
write.table(trans_new, file = "UTR_add_extend/AplCal.GFFannotation.mRNA_3UTR_3kb_extended.gff", 
            sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)

## Eliminate duplicates from 5' and 3' UTR tracks and fix attributes

five_UTR_new <- five_UTR[!duplicated(five_UTR$V9), ]
five_UTR_new$ID <- five_UTR_new$V9 
five_UTR_new <- separate(five_UTR_new, ID, c("ID"), sep = ";")
five_UTR_new$ID <- gsub("gene", "5utr", five_UTR_new$ID)
five_UTR_new$V9 <- gsub("ID=", "Parent=", five_UTR_new$V9)

five_UTR_new <- five_UTR_new %>%
  mutate(V9 = paste(ID, V9, sep = ";"))
five_UTR_new <- five_UTR_new[, -c(10)]

three_UTR_new <- three_UTR[!duplicated(three_UTR$V9), ]
three_UTR_new$ID <- three_UTR_new$V9 
three_UTR_new <- separate(three_UTR_new, ID, c("ID"), sep = ";")
three_UTR_new$ID <- gsub("gene", "3utr", three_UTR_new$ID)
three_UTR_new$V9 <- gsub("ID=", "Parent=", three_UTR_new$V9)

three_UTR_new <- three_UTR_new %>%
  mutate(V9 = paste(ID, V9, sep = ";"))
three_UTR_new <- three_UTR_new[, -c(10)]


write.table(five_UTR_new, file = "UTR_add_extend/AplCal.GFFannotation.5UTR_3kb_uniq.gff", 
            sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)
write.table(three_UTR_new, file = "UTR_add_extend/AplCal.GFFannotation.3UTR_3kb_uniq.gff", 
            sep = "\t", row.names=FALSE, col.names=FALSE, quote=FALSE)

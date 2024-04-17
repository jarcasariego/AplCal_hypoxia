#!/bin/bash

#determine annotation types and display counts

grep -v '^#' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/genomic.gff | cut -s -f 3 | sort | uniq -c | sort -rn > all_features.txt

# Separate nuclear and mitochondrial genomes

grep -v $'NC_' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/genomic.gff > nuclear.gff
grep $'NC_' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/genomic.gff > mito.gff

#extract feature types and generate individual gff

grep $'\texon\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff > Acal.GFFannotation.exon.gff
grep $'\tCDS\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff > Acal.GFFannotation.CDS.gff
grep $'\tmRNA\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff > Acal.GFFannotation.mRNA.gff
grep $'\tgene\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.gene.gff
grep $'\tcDNA_match\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.cDNA_match.gff
grep $'\tlnc_RNA\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.lnc_RNA.gff
grep $'\ttranscript\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.transcript.gff
grep $'\ttRNA\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.tRNA.gff
grep $'\tpseudogene\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.pseudogene.gff
grep $'\tsnoRNA\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.snoRNA.gff
grep $'\tregion\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.region.gff
grep $'\tsnRNA\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.snRNA.gff
grep $'\trRNA\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.rRNA.gff
grep $'\tguide_RNA\t' /scratch/jeirinlo/jrodr979/ACAL_meth/genome/nuclear.gff> Acal.GFFannotation.guide_RNA.gff


##### CREATE OTHER GENOME TRACKS

#Obtain sequence lengths for each chromosome

awk 'BEGIN { FS=OFS="\t" } $0 ~ ">" {print c; c=0;printf substr($0,2,100) "\t"; } $0 !~ ">" {c+=length($0);} END { print c; }' \
/scratch/jeirinlo/jrodr979/ACAL_meth/genome/unplaced.scaf.fna |\
awk 'BEGIN { FS=OFS="\t" } {print $1"\t"$NF}' > Acal.genome_assembly-sequence-lengths.txt

# extract scaffold names  	

cut -f1 Acal.genome_assembly-sequence-lengths.txt > Acal.Chromosome-Names.txt

#Sort GFF files for downstream use

sortBed -faidx Acal.Chromosome-Names.txt -i Acal.GFFannotation.gene.gff > Acal.GFFannotation.gene_sorted.gff
sortBed -faidx Acal.Chromosome-Names.txt -i Acal.GFFannotation.exon.gff > Acal.GFFannotation.exon_sorted.gff
sortBed -faidx Acal.Chromosome-Names.txt -i Acal.GFFannotation.CDS.gff > Acal.GFFannotation.CDS_sorted.gff

# Intergenic regions (By definition, these are regions that aren't genes. I can use complementBed to find all regions that aren't genes, and subtractBed to remove exons and create this track)

complementBed -i Acal.GFFannotation.gene_sorted.gff -sorted -g Acal.genome_assembly-sequence-lengths.txt | subtractBed -a - -b Acal.GFFannotation.exon_sorted.gff > Acal.GFFannotation.intergenic.gff # track resulting here has an overlap of the first base with the last base of the gene track so I corrected it below

awk 'BEGIN { FS=OFS="\t" } {print $1"\t"$2+1"\t"$3"}' Acal.GFFannotation.intergenic.gff > Acal.GFFannotation.intergenic_corrected.gff #additionally the start region will be changed from 0 to 1 so need to be corrected.
sed -i 's/\<1\>/0/g' Acal.GFFannotation.intergenic_corrected.gff

#Non-coding Sequences (I can use complementBed to create a non-coding sequence track. This track can then be used to create an intron track)

complementBed -i  Acal.GFFannotation.exon_sorted.gff -g Acal.genome_assembly-sequence-lengths.txt > Acal.GFFannotation.noncoding.gff3

# Introns (The intersections betwen the non-coding sequences and genes are by definition introns)

intersectBed -a Acal.GFFannotation.noncoding.gff3 -b Acal.GFFannotation.gene_sorted.gff -sorted > Acal.GFFannotation.intron.gff3 # track resulting here has an overlap of the first base with the last base of the exon track so I corrected it below

awk 'BEGIN { FS=OFS="\t" } {print $1"\t"$2+1"\t"$3}' Acal.GFFannotation.intron.gff3 > Acal.GFFannotation.intron_corrected.gff3

# Untranslated regions 

flankBed -i Acal.GFFannotation.gene_sorted.gff -g Acal.genome_assembly-sequence-lengths.txt -l 0 -r 2000 -s | awk 'BEGIN { FS=OFS="\t" } { gsub("gene","3prime_UTR",$3); print $0 }'| awk 'BEGIN { FS=OFS="\t" } {if($5-$4 > 3)print $0}' > Acal.GFFannotation.3UTR.gff
subtractBed -a Acal.GFFannotation.3UTR.gff -b Acal.GFFannotation.gene_sorted.gff > Acer.GFFannotation.3UTR_corrected.gff # when genes are close to each other UTR region overlaps with the gene. 


# Putative promoters track P250, P1K, P6K

flankBed -i Acal.GFFannotation.gene_sorted.gff -g Acal.genome_assembly-sequence-lengths.txt -l 250 -r 0 -s | awk 'BEGIN { FS=OFS="\t" } { gsub("gene","P250_promoter",$3); print $0 }'| awk 'BEGIN { FS=OFS="\t" } {if($5-$4 > 3)print $0}' > Acal.GFFannotation.P250_promoter.gff
subtractBed -a Acal.GFFannotation.P250_promoter.gff -b Acal.GFFannotation.gene_sorted.gff > Acal.GFFannotation.P250_promoter_corrected.gff 

flankBed -i Acal.GFFannotation.gene_sorted.gff -g Acal.genome_assembly-sequence-lengths.txt -l 1000 -r 0 -s | awk 'BEGIN { FS=OFS="\t" } { gsub("gene","P1K_promoter",$3); print $0 }'| awk 'BEGIN { FS=OFS="\t" } {if($5-$4 > 3)print $0}' > Acal.GFFannotation.P1K_promoter.gff
subtractBed -a Acal.GFFannotation.P1K_promoter.gff -b Acal.GFFannotation.gene_sorted.gff > Acal.GFFannotation.P1K_promoter_temp.gff
subtractBed -a Acal.GFFannotation.P1K_promoter_temp.gff -b Acal.GFFannotation.P250_promoter_corrected.gff > Acal.GFFannotation.P1K_promoter_corrected.gff

flankBed -i Acal.GFFannotation.gene_sorted.gff -g Acal.genome_assembly-sequence-lengths.txt -l 6000 -r 0 -s | awk 'BEGIN { FS=OFS="\t" } { gsub("gene","P6K_promoter",$3); print $0 }'| awk 'BEGIN { FS=OFS="\t" } {if($5-$4 > 3)print $0}' > Acal.GFFannotation.P6K_promoter.gff
subtractBed -a Acal.GFFannotation.P6K_promoter.gff -b Acal.GFFannotation.gene_sorted.gff > Acal.GFFannotation.P6K_promoter_temp.gff
subtractBed -a Acal.GFFannotation.P6K_promoter_temp.gff -b Acal.GFFannotation.P250_promoter_corrected.gff > Acal.GFFannotation.P6K_promoter.gff
subtractBed -a Acal.GFFannotation.P6K_promoter.gff -b Acal.GFFannotation.P1K_promoter_corrected.gff > Acal.GFFannotation.P6K_promoter_corrected.gff


##### Create repetitive region tracks

# Run repeat masker

conda activate my_anaconda

RepeatMasker /scratch/jeirinlo/jrodr979/ACAL_meth/genome/GCF_900880675.1_fSpaAur1.1_genomic.fna -species "all" -par 8 -gff -excln 1> stdout.txt 2> stderr.txt  	

conda deactivate
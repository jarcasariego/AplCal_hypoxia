#! /usr/bin/env bash

if [ -d ../genomes/ANVIndex ]
  then
		rm -r ../genomes/ANVIndex
fi

# for small genomes, genomeSAindexNbases = min(14, log2(GenomeLength)/2 - 1)
#ANV genome is 35906 BP + 42 extra leader from Ben Neuman
#log2(35948)/2 -1 = 15.1/2 -1 = 6.6 ~= 7
#assume reads are 100bp PE for sjdbOverhang

if [ ! -d ../genomes/ANVIndex ]
  then
    mkdir ../genomes/ANVIndex
    STAR \
      --runThreadN 16 \
      --runMode genomeGenerate \
      --genomeDir ../genomes/ANVIndex \
      --genomeFastaFiles ../genomes/modified_ANV_genome.fasta \
      --sjdbGTFfile ../genomes/modified_ANV_genome.gff \
      --sjdbOverhang 99 \
      --genomeSAindexNbases 6 \
      --sjdbGTFfeatureExon CDS
fi

#--sjdbGTFtagExonParentTranscript Parent\
#--sjdbGTFfeatureExon CDS \
#--sjdbGTFtagExonParentTranscript gene_id \

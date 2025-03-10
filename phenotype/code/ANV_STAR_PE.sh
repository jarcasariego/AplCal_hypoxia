#! /usr/bin/env bash

#STAR parameters from https://urldefense.com/v3/__https://github.com/jnoms/virORF_direct/blob/master/bin/bash/star.sh__;!!FjuHKAHQs5udqho!L66rMQJ6KTqKXFObVAYOOiZ0vazFY4z9h1v30BQzz3KqqyfEMpJvwNkeCrtb1ggIDMSoDbJEe9lHezPr9gWx$  from Nomburg et al 2020 https://urldefense.com/v3/__https://github.com/jnoms/virORF_direct/blob/master/bin/bash/star.sh__;!!FjuHKAHQs5udqho!L66rMQJ6KTqKXFObVAYOOiZ0vazFY4z9h1v30BQzz3KqqyfEMpJvwNkeCrtb1ggIDMSoDbJEe9lHezPr9gWx$ 

#define variables for directories and files
SraAccList=$1

#check to make sure SRA accession file exists
[ ! -f ${SraAccList} ] && echo "ERROR! SRA file does not exist! Exiting..." && exit

[ ! -d ../logs/STAR_logs/ ] && mkdir ../logs/STAR_logs/

[ ! -d ../alignment_stats ] && mkdir ../alignment_stats


[ -d ../trimmed_reads ] && echo "../cleaned_reads dir found. Proceeding..." || (echo "Error: Directory ../cleaned_reads does not exist, did you skip a step?\nExiting..." && exit)

[ ! -d ../genomes/ANVIndex ] && echo "STAR index not found, please build index first" && exit

[ ! -d ../anv_aligned ] && echo "../unmapped_reads folder not detected. Making directory..." && mkdir "../anv_aligned"

samples=`cat ${SraAccList}`

for samp in ${samples}
do

#check for required input files
  [[ ! -f ../cleaned_reads/"${samp}".mate1.repaired.fastq.gz || ! -f ../cleaned_reads/"${samp}".mate2.repaired.fastq.gz ]] && ( printf "cleaned read files for "${samp}" not found!" && exit )
#clean out any old verions
  [ -d ../anv_aligned/${samp} ] && rm -r ../anv_aligned/${samp}
#make new one so STAR doesn't freak out
  [ ! -d ../anv_aligned/${samp} ] && mkdir ../anv_aligned/${samp}

[ -f ../anv_aligned/${samp}_Aligned.sortedByCoord.out.bam ] && echo "this sample has already been aligned, skipping..." && continue

#build script
echo \"Aligning ${samp} to ANV Genome using STAR...\"

ulimit -n 5000

STAR \
--runThreadN 16 \
--genomeDir ../genomes/ANVIndex \
--readFilesIn ../trimmed_reads/${samp}.mate1.repaired.fastq.gz \
../trimmed_reads/${samp}.mate2.repaired.fastq.gz \
--outFileNamePrefix ../anv_aligned/${samp}_ \
--readFilesCommand gunzip -c \
--outSAMtype BAM SortedByCoordinate \
--outBAMsortingBinsN 200 \
--limitBAMsortRAM 10000000000 \
--outFilterType BySJout \
--outFilterMultimapNmax 20 \
--alignSJoverhangMin 8 \
--outSJfilterOverhangMin 12 12 12 12 \
--outSJfilterCountUniqueMin 1 1 1 1 \
--outSJfilterCountTotalMin 1 1 1 1 \
--outSJfilterDistToOtherSJmin 0 0 0 0 \
--outFilterMismatchNmax 999 \
--outFilterMismatchNoverReadLmax 0.04\
--scoreGapNoncan -4 \
--scoreGapATAC -4 \
--chimOutType WithinBAM HardClip \
--chimScoreJunctionNonGTAG 0 \
--alignSJstitchMismatchNmax -1 -1 -1 -1 \
--alignIntronMin 20 \
--alignIntronMax 1000000 \
--alignMatesGapMax 1000000


if [ -f ../anv_aligned/${samp}_Log.final.out ]
then
  echo \"alignment successful! moving necessary files...\"
  mv ../anv_aligned/${samp}_Log.final.out ../logs/STAR_logs/
	mv ../anv_aligned/${samp}_Log.progress.out ../logs/STAR_logs/
	mv ../anv_aligned/${samp}_Log.out ../logs/STAR_logs/
	mv ../anv_aligned/${samp}_SJ.out.tab ../alignment_stats
	rmdir ../anv_aligned/${samp}

fi

done

echo "All done!"

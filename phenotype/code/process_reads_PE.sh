#! /usr/bin/env bash

SraAccList=$1


[ ! -d ../logs ] && mkdir ../logs
[ ! -d ../logs/BBDUK_logs ] && mkdir ../logs/BBDUK_logs
[ ! -d ../logs/sickle_logs ] && mkdir ../logs/sickle_logs

#check if unmapped_reads exists
[ -d ../raw_reads ] && echo "../raw_reads found. Proceeding..." || (echo "Error: Directory ../raw_reads does not exist. Exiting..." && exit)

#check if cleaned reads folder exists, and if not, make one

[ ! -d ../cleaned_reads ] && echo "../cleaned_reads folder not detected. Making directory..." && mkdir ../cleaned_reads


samples=`cat ${SraAccList}`

for samp in ${samples}
do
  [ -f ../raw_reads/"${samp}"_1.fastq ] && ( printf "compressing uncompressed file ${samp}_1.fastq" && gzip ../raw_reads/${samp}_1.fastq )
  [ -f ../raw_reads/"${samp}"_2.fastq ] && ( printf "compressing uncompressed file ${samp}_2.fastq" && gzip ../raw_reads/${samp}_2.fastq )
  [[ ! -f ../raw_reads/"${samp}"_1.fastq.gz || ! -f ../raw_reads/"${samp}"_2.fastq.gz ]] && (printf "Raw read files for "${samp}" not found!" && exit )

  #clean out any old versions
  rm ../cleaned_reads/${samp}*

  echo "trimming reads with BBDUK..."

  ##just in case so as not to stop BBDUK from running
  [ -f ../logs/BBDUK_logs/${samp}_stats.txt ] && rm ../logs/BBDUK_logs/${samp}_stats.txt

/Users/Nick_Kron/Programs/bbmap/bbduk.sh \
  in1=../raw_reads/${samp}_1.fastq.gz \
  in2=../raw_reads/${samp}_2.fastq.gz \
  out1=../trimmed_reads/${samp}.mate1.adaptor_trimmed.fastq.gz \
  out2=../trimmed_reads/${samp}.mate2.adaptor_trimmed.fastq.gz \
  outs=../trimmed_reads/${samp}.singletons.adaptor_trimmed.fastq.gz \
  stats=../logs/BBDUK_logs/${samp}_stats.txt \
  ref=/Users/Nick_Kron/Programs/bbmap/resources/adapters.fa \
  ktrim=r \
  k=23 \
  mink=8 \
  hdist=1 \
  tpe \
  tbo \
  qtrim=lr \
  trimq=10 \
  minlen=50 \
  maq=10 \
  1>../logs/BBDUK_logs/${samp}_bbduk.out \
  2>../logs/BBDUK_logs/${samp}_bbduk.err

  [[ ! -f ../trimmed_reads/${samp}.mate1.adaptor_trimmed.fastq.gz ||  ! -f ../trimmed_reads/${samp}.mate2.adaptor_trimmed.fastq.gz || ! -f ../trimmed_reads/${samp}.singletons.adaptor_trimmed.fastq.gz ]] \
  && ( echo "something went wrong, trimmed read files not found. Exiting..." && exit )

  echo "BBDUK trimming done!"
  echo "quality trimming PE reads with sickle..."

  sickle pe -g \
  -f ../trimmed_reads/${samp}.mate1.adaptor_trimmed.fastq.gz \
  -r ../trimmed_reads/${samp}.mate2.adaptor_trimmed.fastq.gz \
  -t sanger \
  -o ../trimmed_reads/${samp}.mate1.cleaned.fastq.gz \
  -p ../trimmed_reads/${samp}.mate2.cleaned.fastq.gz \
  -s ../trimmed_reads/${samp}.singletonS.cleaned.fastq.gz \
  1>../logs/sickle_logs/${samp}_pe_sickle.out \
  2>../logs/sickle_logs/${samp}_pe_sickle.err

  [[ ! -f ../trimmed_reads/${samp}.mate1.cleaned.fastq.gz ||  ! -f ../trimmed_reads/${samp}.mate2.cleaned.fastq.gz ]] \
  && ( echo "something went wrong, cleaned read files not found. Exiting..." && exit )

  echo "PE reads quality trimmed!"
  echo "quality trimming singletons with sickle..."

  sickle se \
  -f ../trimmed_reads/${samp}.singletons.adaptor_trimmed.fastq.gz \
  -t sanger \
  -o ../trimmed_reads/${samp}.singletonB.cleaned.fastq.gz \
  1>../logs/sickle_logs/${samp}_se_sickle.out \
  2>../logs/sickle_logs/${samp}_se_sickle.err

  [[ ! -f ../trimmed_reads/${samp}.singletonB.cleaned.fastq.gz ]] && ( echo "something went wrong, cleaned read file not found. Exiting..." && exit )
  echo "Singleton reads quality trimmed!"
  echo "reads quality trimmed, removing BBBDUK files..."

  rm ../trimmed_reads/${samp}.mate1.adaptor_trimmed.fastq.gz \
  ../trimmed_reads/${samp}.mate2.adaptor_trimmed.fastq.gz \
  ../trimmed_reads/${samp}.singletons.adaptor_trimmed.fastq.gz

  echo "BBDUK files reads removed!"

  echo "repairing reads with repair..."

  repair.sh \
  in1=../trimmed_reads/${samp}.mate1.cleaned.fastq.gz \
  in2=../trimmed_reads/${samp}.mate2.cleaned.fastq.gz \
  out1=../trimmed_reads/${samp}.mate1.repaired.fastq.gz \
  out2=../trimmed_reads/${samp}.mate2.repaired.fastq.gz \
  outs=../trimmed_reads/${samp}.singletonR.cleaned.fastq.gz \
  repair \
  1>../logs/BBDUK_logs/${samp}_repair.out \
  2>../logs/BBDUK_logs/${samp}_repair.err

  [[ ! -f ../trimmed_reads/${samp}.mate1.repaired.fastq.gz ||  ! -f ../trimmed_reads/${samp}.mate2.repaired.fastq.gz || -f ../trimmed_reads/${samp}.singletonR.cleaned.fastq.gz ]] \
  && ( echo "something went wrong, repaired read files not found. Exiting..." && exit )

  echo "reads repaired!"
  echo "combining singletons..."

  cat ../trimmed_reads/${samp}.singletonS.cleaned.fastq.gz \
  ../trimmed_reads/${samp}.singletonB.cleaned.fastq.gz \
  ../trimmed_reads/${samp}.singletonR.cleaned.fastq.gz > ../cleaned_reads/${samp}.singletons.repaired.fastq.gz

  echo "removing intermediate cleaned read files..."
  rm ../trimmed_reads/${samp}.mate1.cleaned.fastq.gz \
  ../trimmed_reads/${samp}.mate2.cleaned.fastq.gz

  echo "removing intermediate singleton files..."
  rm ../trimmed_reads/${samp}.singletonS.cleaned.fastq.gz \
  ../trimmed_reads/${samp}.singletonB.cleaned.fastq.gz \
  ../trimmed_reads/${samp}.singletonR.cleaned.fastq.gz

  echo "all done!"

done

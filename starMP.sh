#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 20
#SBATCH --mem=64g
#SBATCH -N 1
#SBATCH -J STAR
# ----------------Load Modules--------------------
module load STAR/2.7.6a-IGB-gcc-8.2.0

mkdir /scratch/starTMP/
cwd="/home" #working directory
clean="${cwd}/A3/trim/fastp" #path to cleaned data
scratch="/scratch/starTMP/$SLURM_JOB_ID" #temp directory
date="1Jan"

echo "Running Genome Indexer"
STAR --runThreadN $SLURM_NTASKS \
--runMode genomeGenerate --limitGenomeGenerateRAM 62000000000 \
--sjdbOverhang 136 --genomeDir "${cwd}"/db/STARfull \
--genomeFastaFiles "${cwd}"/ref/Zea_mays.AGPv4.dna.toplevel.fa \
--sjdbGTFfile "${cwd}"/ref/Zea_mays.B73_RefGen_v4.49.gtf

#each file was named [MUT/WT]_A3_REP[1-3]_trimmed_[FP/RP].fastq.gz so pull sample name
for f in $(ls -1 "${clean}" | cut -d "_" -f 1-3 | sort | uniq); do 
echo "Running Aligner for ${f}"
s=$(echo "${f}" | sed -E 's/([MUTW].+)_A3_REP[1-3]/\1/') #pull WT or MUT for SAM file
STAR --runThreadN $SLURM_NTASKS --genomeDir "${cwd}"/db/STARfull \
--readFilesIn "${clean}"/"${f}"_trimmed_FP.fastq.gz \
"${clean}"/"${f}"_trimmed_RP.fastq.gz \
--readFilesCommand zcat --sjdbGTFfile "${cwd}"/ref/Zea_mays.B73_RefGen_v4.49.gtf \
--outSAMtype BAM SortedByCoordinate \
--outFileNamePrefix "${cwd}"/A3/aligned/STAR/"${date}"/pass/"${f}". \
--outTmpDir "${scratch}" \
-–outSAMattrRGline ID:"${f}" LB:1 PL:Illumina PU:HYGYHDRXX SM:"${s}"
rm -fr "${scratch}";
done

echo "Begin Two-pass Mode"
echo "Indexing with the new transcriptome"
STAR --runThreadN $SLURM_NTASKS --runMode genomeGenerate \
--limitGenomeGenerateRAM 62000000000 --sjdbOverhang 136 \
--genomeDir "${cwd}"/db/two-pass \
--genomeFastaFiles "${cwd}"/ref/Zea_mays.AGPv4.dna.toplevel.fa \
--sjdbGTFfile "${cwd}"/ref/Zea_mays.B73_RefGen_v4.49.gtf \
--sjdbFileChrStartEnd "${cwd}"/A3/aligned/STAR/"${date}"/*.SJ.out.tab

echo "Begin the second pass"
for f in $(ls -1 "${clean}" | cut -d "_" -f 1-3 | sort | uniq); do
echo "Running Second Aligner for ${f}"
s=$(echo "${f}" | sed -E 's/([MUTW].+)_A3_REP[1-3]/\1/')
STAR --runThreadN $SLURM_NTASKS --genomeDir "${cwd}"/db/two-pass \
--readFilesIn "${clean}"/"${f}"_trimmed_FP.fastq.gz \
"${clean}"/"${f}"_trimmed_RP.fastq.gz --readFilesCommand zcat \
--sjdbGTFfile "${cwd}"/ref/Zea_mays.B73_RefGen_v4.49.gtf \
--sjdbFileChrStartEnd "${cwd}"/A3/aligned/STAR/"${date}"/*.SJ.out.tab \
--outSAMtype BAM SortedByCoordinate \
--outFileNamePrefix "${cwd}"/A3/aligned/STAR/"${date}"/pass2/"${f}". \
--outTmpDir "${scratch}" \
--outSAMattrRGline ID:"${f}" LB:1 PL:Illumina PU:HYGYHDRXX SM:"${s}"
rm -fr "${scratch}";
done

#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 16
#SBATCH --mem=64g
#SBATCH -N 1
#SBATCH -J fastp
# ----------------Load Modules--------------------
module load fastp/0.20.0-IGB-gcc-4.9.4
cwd="/home/trim/fastp" #working directory

#each file was named [MUT/WT]_A3_REP[1-3]_R[1-2].fastq.gz so pull sample name
for f in $(ls -1 /home/raw/ | grep "A3" | cut -d "_" -f 1-3 | sort | uniq); do 
	echo "Filtering ${f}"
	fastp -w $SLURM_NTASKS \
		-i /home/raw/"${f}"_R1.fastq.gz \
		-I /home/raw/"${f}"_R2.fastq.gz \
		-e 30 -l 50 -x --adapter_fasta="/home/raw/myAdapter.fa" \
		-t 3 -T 3 -f 10 -F 10 --overrepresentation_analysis \
		-o "${cwd}"/"${f}"_trimmed_FP.fastq.gz \
		-O "${cwd}"/"${f}"_trimmed_RP.fastq.gz \
		--unpaired1="${cwd}/${f}_trimmed_UP.fastq.gz" \
		--unpaired2="${cwd}/${f}_trimmed_UP.fastq.gz" \
		-j "${cwd}/${f}_fastp_results.json" \
		-h "${cwd}/${f}_fastp_results.html" \
		-R "${cwd}/${f}.results";
done

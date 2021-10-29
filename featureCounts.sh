#!/bin/bash
# ----------------SLURM Parameters----------------
#SBATCH -p normal
#SBATCH -n 6
#SBATCH --mem=64g
#SBATCH -N 1
#SBATCH -J FeatureCounts
# ----------------Load Modules--------------------
module load Subread/2.0.0-IGB-gcc-8.2.0
cwd="/home" #working directory
date="1Jan" #date ran STAR pipeline

for f in $(ls -1 "${cwd}"/A3/trim/fastp | cut -d "_" -f 1-3 | sort | uniq); do 
	echo "Running featureCounts for ${f}"
	featureCounts -p -T $SLURM_NTASKS -s 2 \
		-a "${cwd}"/ref/Zea_mays.B73_RefGen_v4.49.gtf \
		-t exon -g gene_id --verbose \
		-o "${cwd}"/deg/featureCounts/"${date}"/"${f}"_rev_featurecounts.txt \
		"${cwd}"/aligned/STAR/"${date}"/"${f}".Aligned.sortedByCoord.out.bam;
done


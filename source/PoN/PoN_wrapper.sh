#!/bin/bash

# Wrapper script for generating PoN. Script calls PoN1, PoN2, and PoN3, each running a step in the process of generating PoN. 
# INPUT: File containing list of processed normal sample BAM files (used to generate the PoN).
# OUTPUT: Panel of normals, used for downstream processing in Mutect2 somatic variant calling (normal-tumor mode).  
# NOTE: Make sure to be located in work_dir when executing the script. 

# PoN1 parameters: $1 = Ref, $2 = Input (BAM), $3 = Output (VCF)
# PoN2 parameters: $1 = Ref, $2 = Intervals list, $3 = Work dir, $4 = Input (VCF)
# Script3 parameters: 


# Set script variables

	BAM_FILE_PATH=/home/xlorda/anna_tmp/mapped_bam_files

	WORK_DIR=/home/xlorda/anna_tmp/PoN_wrapper_test

	PON1=/home/xlorda/Biomarkers-immuno-lungcancer/source/PoN/PoN1.sge

	PON2=/home/xlorda/Biomarkers-immuno-lungcancer/source/PoN/PoN2.sge

	PON3=/home/xlorda/Biomarkers-immuno-lungcancer/source/PoN/PoN3.sge

	HG38=/home/xlorda/anna_tmp/reference_and_misc_files/GRCh38.primary_assembly.genome.fa

	INTERVALS_LIST=/home/xlorda/anna_tmp/reference_and_misc_files/wgs_calling_regions.hg38.list
	
	GERMLINE_RESOURCE=/home/xlorda/anna_tmp//reference_and_misc_files/af-only-gnomad.hg38.vcf.gz

	#PoN_DB is generated during the PoN2 step:
	PON_DB=${WORK_DIR}/PON_DB


INPUT=$1

# Create a list, consisting of each entry (line) in the input file.
# Note: Instances in input file are separated by newlines, convert to spaces before appending to a list. 

IN_FILES=""
while read LINE; do
	FIRST=`echo $LINE | tr '\n' ' '`
	IN_FILES+=($FIRST)
done < $INPUT


# Run PoN1.sge for each item in input list
# PoN1 parameters: $1 = Ref, $2 = Input, $3 = Output
# Create a comma separated string, jobnames, used for parallelisation in qsub. 

for i in ${IN_FILES[@]}; do
	JOBNAME=Mutect2_${i}
	JOBLIST+=`echo ${JOBNAME},`
	qsub -N ${JOBNAME} -cwd $PON1 $HG38 ${BAM_FILE_PATH}/${i} ${WORK_DIR}/${i%.bam}.vcf.gz
done

# Remove comma from last item in list
JOBLIST=${JOBLIST%,}


# Create a string holding all outputs of PoN1, string will be passed as input parameter for PoN2. 

V_STR=""
for i in ${IN_FILES[@]}; do
	V_STR+="${WORK_DIR}/${i%.bam}.vcf.gz,"
done


# Start PoN2 when all PoN1 jobs are finished running
# PoN2 parameters: $1 = Ref, $2 = Intervals list, $3 = Work dir, $4 = Input

qsub -hold_jid $JOBLIST -N "PoN2.sge" -cwd $PON2 $HG38 $INTERVALS_LIST PON_DB $V_STR


# Start PoN3 when PoN2 is finished running
# PoN3 parameters: $1 = Ref, $2 = germline resource (VCF from populational resource, containing allele frequencies only), $3 = Input, PoN_DB (generated in previous step), $4 = Output, PoN (VCF).

qsub -hold_jid "PoN2.sge" -N "PoN3.sge" -cwd $PON3 $HG38 $GERMLINE_RESOURCE $PON_DB ${WORK_DIR}/PoN.vcf.gz



Rscript R/rna_pipeline.R QC \
--fqdir /home/renseb01/Documents/lord/raw_data/Terry_Fox_project/RNAseq/fastq \
--qcdir Terry_Fox_QC \
--outdir Terry_Fox_QC \
--threads 20 \
--fastqc fastqc

#--metadata data/Sommaire_1128_éch_ARN_RIN_FASTQ_31août2023.xlsx \

#make sure you activate the Rbase conda environnement to install the proper R librairies.
#You also need to have fastqc installed in you PATH, or need to specify where it with the --fastqc option. 

Rscript R/rna_pipeline.R kallisto \
--trimdir /home/renseb01/Documents/lord/LORD_project/RNAseq/LORD-YB-P03_part5/processed/fastq.trim \
--quantdir lord_kallisto/LORD-YB-P03_part5 \
--reftranscriptome data/reference_transcriptome/gencode.v44.transcripts.fa.gz \
--threads 12 \
--txdbdir data/reference_transcriptome/gencode.v44.annotation.gtf \
--outdir lord_kallisto/LORD-YB-P03_part5 \
--nbfiles all \
--fqdir /home/renseb01/Documents/lord/LORD_project/RNAseq/LORD-YB-P03_part5/FASTQ_files

Rscript R/rna_pipeline.R star \
--cutadapt /mnt/sde/renseb01/miniconda3/envs/Rbase/bin/cutadapt  \
--fqdir /home/renseb01/Documents/lord/RNAseq_LORD/LORD-YB-P03_part2/FASTQ_files/ \
--trimdir /home/renseb01/Documents/lord/RNAseq_LORD/LORD-YB-P03_part2/processed/fastq.trim \
--outdir /mnt/sde/renseb01/Documents/rnaseq/lord_alignments/part2 \
--threads 20 \
--genomeindexdir data/reference_genome/GRCh38/ \
--annotationgtf data/reference_genome/gencode.v43.basic.annotation.gtf \
--nbfiles 131,256 \
--genomefasta data/reference_genome/GRCh38.primary_assembly.genome.fa


#make sure to set ulimit -n 3000
#make sure you activate conda Rbase


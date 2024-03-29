# kallisto function
source('R/counts_functions.R')

#libraries needed: GenomicFeatures, AnnotationDbi, tximport & DESeq2

#=====================
# Index command
#=====================
index <- function(ref.transcriptome = 'data/reference_transcriptome/chr1.fasta.gz'){
    # Reference transcriptome: full transcriptome can be found here: https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_44/gencode.v44.transcripts.fa.gz

    # Kallisto index command 
    cmd <- paste0(ifelse(Sys.info()['sysname'] == 'Windows','wsl.exe ',''),
                  'kallisto index -i ',
                  gsub('fa.gz|fasta.gz','idx',ref.transcriptome),
                  ' --make-unique ',
                  ref.transcriptome)
    system(cmd)
    
    # Print message
    message(paste0('Done Kallisto indexing, Time is: ', Sys.time()))
    return('')
}


#=====================
# kallisto command
#=====================
kallisto <- function(trim1 = 'out/fastq.trim/RNA_0006_5598_Tumeur_R1_val_1.fq.gz',
                     trim2 = 'out/fastq.trim/RNA_0006_5598_Tumeur_R2_val_2.fq.gz',
                     quant.dir = 'out/kallisto',
                     ref.transcriptome = 'data/reference_transcriptome/chr1.fasta.gz',
                     threads = 12,
                     i = 1) {
    # Create output directory
    if (!file.exists(quant.dir)) {
        dir.create(quant.dir, recursive = TRUE)
    }
    
    
    # Kallisto quant command
    cmd <- paste0(ifelse(Sys.info()['sysname'] == 'Windows','wsl.exe ',''),
                  'kallisto quant -i ',
                  gsub('fa.gz|fasta.gz','idx',ref.transcriptome),
                  ' -o ',
                  file.path(quant.dir),
                  ' -b 0 ',
                  trim1,
                  ' ',
                  trim2,
                  ' --threads ', threads,
                  ' 1>',ifelse(i>1,'>',''),
                  file.path('out/logs', 'kallisto.out'),
                  ' 2>',ifelse(i>1,'>',''),
                  file.path('out/logs', 'kallisto.err'))
    
    system(cmd)
    
    # Print message
    message(paste0('Done Kallisto count, Time is: ', Sys.time()))
    return('')
}


#==========================================
# TxDb object step
#==========================================
ref_txb <- function(txdb.dir = "data/reference_transcriptome/gencode.v44.annotation.gtf",
                    txdb.file = "data/reference_transcriptome/gencode.v44.annotation.sqlite"){
    
    # Create TxDb database and save to SQLite for later use
    gtf = file.path(txdb.dir)
    txdb.filename = file.path("data/reference_transcriptome/gencode.v44.annotation.sqlite")
    txdb = GenomicFeatures::makeTxDbFromGFF(gtf)
    AnnotationDbi::saveDb(txdb, txdb.filename)
}


#==========================================
# tximport counts step
#==========================================
# gtf downloaded from here: https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_44/gencode.v44.annotation.gtf.gz
tximp_counts = function(#quant.dir = "out/kallisto",
                        sequencing_files =  sequences(trim.dir=trim.dir)[[5]],
                        out.dir = "out/gene_counts",
                        txdb.file = "data/reference_transcriptome/gencode.v44.annotation.sqlite"){
    
    # Load TxDB & create tx2gene
    txdb = AnnotationDbi::loadDb(txdb.file)
    k = AnnotationDbi::keys(txdb, keytype = "TXNAME")
    tx2gene = AnnotationDbi::select(txdb, k, "GENEID", "TXNAME")
    
    #Import kallisto data  
    files_kallisto = file.path(out.dir,sequencing_files,'abundance.h5')
    names(files_kallisto) = sequencing_files
    txi_tsv = tximport::tximport(files_kallisto, type = "kallisto", tx2gene = tx2gene, ignoreAfterBar = TRUE)
    counts_df = data.frame(counts = round(txi_tsv$counts,4))
    lengths_df = data.frame(lengths = txi_tsv$length)
    abundance_df = data.frame(abundance = txi_tsv$abundance)
    write.table(counts_df,file.path(out.dir,'kallisto_counts.tsv'),row.names = T, quote = F, sep = '\t')
    write.table(lengths_df,file.path(out.dir,'kallisto_lengths.tsv'),row.names = T, quote = F, sep = '\t')
    write.table(abundance_df,file.path(out.dir,'kallisto_abundance.tsv'),row.names = T, quote = F, sep = '\t')
    
    system(paste0('gzip ',out.dir,'/*tsv'))
    saveRDS(txi_tsv,file.path(out.dir,'txi.rds'))
    
    # Print message
    message(paste0('Done tximport, Time is: ', Sys.time()))
}


#==========================================
# Wrapper: kallisto_rnaseq
#==========================================
kallisto_rnaseq <- function(idx.dir ='data/index',
                            ref.transcriptome = 'data/reference_transcriptome/chr1.fasta.gz',
                            trim.dir = 'out/fastq.trim',
                            quant.dir = 'out/kallisto',
                            out.dir  = 'out',
                            threads = 12,
                            txdb.dir = "data/reference_transcriptome/gencode.v44.annotation.gtf",
                            txdb.file = "data/reference_transcriptome/gencode.v44.annotation.sqlite",
                            nbfiles = params$nbfiles,
                            fqdir = ''){
 
    # Index, if not present yet, but reference is there, otherwise, kaboom!...
    if(file.exists(ref.transcriptome) & !file.exists(gsub('fa.gz|fasta.gz','idx',ref.transcriptome))) {
        index(ref.transcriptome = ref.transcriptome)
    }
    
    # Name of sequencing files
    fastq_files <- sequences(trim.dir=trim.dir,fq.dir = fqdir)

    #files to process depends on nbfiles parameter
    files = seq_along(fastq_files[[5]])
    nbfiles =  strsplit(nbfiles,',')[[1]]
    if(nbfiles[1] == 'all') files = files
    if(length(nbfiles) == 1 & nbfiles[1] != 'all') {files = files[1:min(length(files),as.numeric(nbfiles))]}
    if(length(nbfiles) == 2) {files = files[as.numeric(nbfiles[1]):as.numeric(nbfiles[2])]}
    
    
    for (i in files) {
        # kallisto quant command
        kallisto(trim1 = fastq_files[[1]][i],
                 trim2 = fastq_files[[2]][i],
                 quant.dir =  file.path(quant.dir, fastq_files[[5]][i]),
                 ref.transcriptome = ref.transcriptome,
                 threads = threads,
                 i = i)
        
        # Message
        message(paste0('--- Done sample, ', fastq_files[[5]][i], ' Time is: ', Sys.time(), ' ---'))
    }
    
    # Create TxDb SQL if not present
    if(!file.exists(txdb.file)) {
        ref_txb(txdb.dir = txdb.dir,
                txdb.file = txdb.file)
    }
    
    # tximport for all
    tximp_counts(sequencing_files = fastq_files[[5]][files],
                 out.dir = out.dir)
    
}

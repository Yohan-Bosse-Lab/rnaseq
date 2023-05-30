#Sleuth
source('R/kallisto.R')
#=====================
#Load kallisto data
#=====================
load_data = function(in.dir = "data/",
                     sample_id = dir(file.path("data/kallisto")),
                     kal_dirs = file.path("data/kallisto", sample_id))
    
{
    #Grep info from run file csv & covert to txt
    #data_file = readxl::read_xlsx("/data/*.xlsx", sheet = 1, col_names = TRUE, col_types = NULL, na = "", skip = 0)
    #file.dir = file.path("/data/")
    #data_frame = write.csv(data_file, file.path(file.dir, "test.csv"))
    #df = read.csv("/data/test.csv")
    #col = df[, c("Name...2", "Sample...5", "Type")] > "/data/sampleTable.txt.txt
    
    #Text file of run info
    sampleTable = read.delim(file.path("data/sampleTable.txt"))
    rownames(sampleTable) = sampleTable$Name
    
    #load TxDB from gencode (Release 43 (GRCh38.p13)
    txdb_v31_hg19_chr1 = GenomicState::gencode_txdb("43", "hg19", chrs = "chr1") #chrs = paste0("chr", c(seq_len(22), "X", "Y", "M"))
    k = AnnotationDbi::keys(txdb_v31_hg19_chr1, keytype = "TXNAME")
    tx2gene = AnnotationDbi::select(txdb_v31_hg19_chr1, k, "GENEID", "TXNAME")
    tx2gene$TXNAME = sapply(strsplit(tx2gene$TXNAME,".",fixed = T), `[`, 1)
    
    #Load kallisto data
    files = file.path(paste0(in.dir, "kallisto"), list.files(paste0(in.dir, "kallisto")), "abundance.h5")
    names(files) = list.files(paste0(in.dir, "kallisto"))
    
    #import abundance.h5 files
    txi = tximport::tximport(files, type = "kallisto", tx2gene = tx2gene, 
                             txIn = TRUE, txOut = FALSE, countsFromAbundance = "lengthScaledTPM",  ignoreTxVersion = TRUE, ignoreAfterBar=TRUE)
    
    # Sleuth
    #SampleTable (info of samples associated with kallisto quant)
    s2c = read.table(file.path(in.dir, "sampleTable.txt"), header = TRUE, stringsAsFactors=FALSE)
    s2c = dplyr::select(s2c, sample = Name, Type)
    s2c = dplyr::mutate(s2c, path = kal_dirs)
    
    #Initialize sleuth object 
    so = sleuth::sleuth_prep(s2c, read_bootstrap_tpm = TRUE)
    
    #Including gene names for transcript-level analysis
    mart = biomaRt::useMart(biomart = "ENSEMBL_MART_ENSEMBL", 
                            dataset = "hsapiens_gene_ensembl",
                            host = 'https:///www.ensembl.org')
    
    t2g = biomaRt::getBM(attributes = c("ensembl_transcript_id","ensembl_transcript_id_version", "ensembl_gene_id", 
                                        "ensembl_gene_id_version","external_gene_name","description",
                                        "chromosome_name","start_position",
                                        "end_position","strand",
                                        "entrezgene_id"), mart = mart)
    
    t2g = dplyr::rename(t2g, target_id = ensembl_transcript_id, 
                        ens_gene = ensembl_gene_id, ext_gene = external_gene_name)
    
    t2g = dplyr::select(t2g, c('target_id', 'ens_gene', 'ext_gene'))
    
    #Adding gene names to sleuth table
    so = sleuth::sleuth_prep(s2c, target_mapping = t2g)
    
    #fitting measurement error models
    so = sleuth::sleuth_fit(so, ~1, 'reduced')
    so = sleuth::sleuth_lrt(so, 'reduced', 'reduced')
    
    #PCA plot
    sleuth::plot_pca(so, color_by = 'Type')
    
    #Group density plot for count distribution/sample type
    
    sleuth::plot_group_density(so, use_filtered = TRUE, units = "tpm", 
                               trans = "log", grouping = setdiff(colnames(so$sample_to_covariates),
                                                                 "sample"), offset = 1)
    #View results with sleuth_live(so)
    
    
    # message(cmd)
    message(paste0('Done data_load, Time is: ',Sys.time()))
}
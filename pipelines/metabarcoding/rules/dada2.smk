# DADA2 roda como script R via Snakemake
rule dada2:
    input:
        reads = expand(os.path.join(PROC, "trimmed/{sample}_R1.fastq.gz"), sample=SAMPLE_IDS),
        manifest = "samples.csv",
    output:
        asv_table = os.path.join(RESULTS, "dada2/asv_table.rds"),
        rep_seqs  = os.path.join(RESULTS, "dada2/rep_seqs.fasta"),
        stats     = os.path.join(RESULTS, "dada2/dada2_stats.csv"),
    params:
        indir    = os.path.join(PROC, "trimmed"),
        outdir   = os.path.join(RESULTS, "dada2"),
        trunc_f  = config["dada2"]["trunc_len_fwd"],
        trunc_r  = config["dada2"]["trunc_len_rev"],
        trunc_q  = config["dada2"]["trunc_q"],
        maxee_f  = config["qc"]["max_ee_fwd"],
        maxee_r  = config["qc"]["max_ee_rev"],
        chimera  = config["dada2"]["chimera_method"],
    log:    os.path.join(LOGS, "dada2.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/metabarcoding")
    script: os.path.expanduser("~/lab/utils/dada2_pipeline.R")

rule phyloseq_and_diversity:
    input:
        asv_table = os.path.join(RESULTS, "dada2/asv_table.rds"),
        tax_table = os.path.join(RESULTS, "taxonomy/taxonomy_table.rds"),
        metadata  = "samples.csv",
    output:
        phyloseq      = os.path.join(RESULTS, "phyloseq_object.rds"),
        alpha_csv     = os.path.join(RESULTS, "diversity/alpha_diversity.csv"),
        beta_rds      = os.path.join(RESULTS, "diversity/beta_diversity.rds"),
        rarefied_rds  = os.path.join(RESULTS, "diversity/phyloseq_rarefied.rds"),
    params:
        group_var   = GROUP_VAR,
        rare_depth  = config["diversity"]["rarefaction_depth"],
        min_reads   = config["diversity"]["min_reads_per_sample"],
        min_asv     = config["diversity"]["min_reads_per_asv"],
        alpha_idx   = config["diversity"]["alpha_indices"],
        beta_methods= config["diversity"]["beta_methods"],
        permanova_n = config["diversity"]["permanova_perm"],
        outdir      = os.path.join(RESULTS, "diversity"),
    log:    os.path.join(LOGS, "diversity.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/metabarcoding")
    script: os.path.expanduser("~/lab/utils/diversity_analysis.R")

rule taxonomy:
    input:
        rep_seqs = os.path.join(RESULTS, "dada2/rep_seqs.fasta"),
    output:
        tax_table = os.path.join(RESULTS, "taxonomy/taxonomy_table.rds"),
        tax_csv   = os.path.join(RESULTS, "taxonomy/taxonomy_table.csv"),
    params:
        train_db   = config["databases"]["dada2_train"],
        species_db = config["databases"]["dada2_species"],
        min_boot   = config["taxonomy"]["min_boot"],
        do_species = config["taxonomy"]["assign_species"],
        outdir     = os.path.join(RESULTS, "taxonomy"),
    log:    os.path.join(LOGS, "taxonomy.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/metabarcoding")
    script: os.path.expanduser("~/lab/utils/dada2_taxonomy.R")

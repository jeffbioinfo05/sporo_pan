rule eggnog_pangenome:
    input:  os.path.join(RESULTS, "panaroo/pan_genome_reference.fa")
    output: os.path.join(RESULTS, "functional/pan.emapper.annotations")
    params:
        outdir = os.path.join(RESULTS, "functional"),
        db     = config["databases"]["eggnog"],
    log:    os.path.join(LOGS, "eggnog_pangenome.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    shell:
        "emapper.py -i {input} -o pan --output_dir {params.outdir} "
        "--itype CDS --data_dir {params.db} --cpu {threads} --override > {log} 2>&1"

rule build_tables:
    input:
        pav      = os.path.join(RESULTS, "panaroo/gene_presence_absence.csv"),
        eggnog   = os.path.join(RESULTS, "functional/pan.emapper.annotations"),
        of_tree  = os.path.join(RESULTS, "orthofinder/Results/SpeciesTree_rooted.txt"),
    output:
        pav_clean = os.path.join(RESULTS, "tables/pav_matrix.csv"),
        func_tab  = os.path.join(RESULTS, "tables/functional_table.csv"),
        class_tab = os.path.join(RESULTS, "tables/gene_classification.csv"),
    params:
        core_freq = config["panaroo"]["min_freq_core"],
        soft_freq = config["panaroo"]["min_freq_soft"],
        n_genomes = len(GENOMES),
    log:    os.path.join(LOGS, "build_tables.log")
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    script: os.path.expanduser("~/lab/utils/build_pangenome_tables.py")

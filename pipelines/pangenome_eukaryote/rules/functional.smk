rule eggnog_representative:
    input:  os.path.join(RESULTS, "orthofinder/Results/SpeciesTree_rooted.txt")
    output: os.path.join(RESULTS, "functional/orthogroups.emapper.annotations")
    params:
        rep_faa = os.path.join(RESULTS, "orthofinder/Results/Representative_Sequences"),
        outdir  = os.path.join(RESULTS, "functional"),
        db      = config["databases"]["eggnog"],
    log:    os.path.join(LOGS, "eggnog.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    shell:
        "emapper.py -i {params.rep_faa} -o orthogroups --output_dir {params.outdir} "
        "--data_dir {params.db} --cpu {threads} --override > {log} 2>&1"

rule build_tables:
    input:
        pav    = os.path.join(RESULTS, "tables/pav_matrix.csv"),
        eggnog = os.path.join(RESULTS, "functional/orthogroups.emapper.annotations"),
    output:
        func_tab = os.path.join(RESULTS, "tables/functional_table.csv"),
    log:    os.path.join(LOGS, "build_tables.log")
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    script: os.path.expanduser("~/lab/utils/build_pangenome_tables.py")

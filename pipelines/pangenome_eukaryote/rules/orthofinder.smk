rule orthofinder:
    input:  FAA_DIR
    output: os.path.join(RESULTS, "orthofinder/Results/SpeciesTree_rooted.txt")
    params:
        outdir    = os.path.join(RESULTS, "orthofinder"),
        inflation = config["orthofinder"]["inflation"],
        method    = config["orthofinder"]["method"],
    log:    os.path.join(LOGS, "orthofinder.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    shell:
        "orthofinder -f {input} -o {params.outdir} -I {params.inflation} "
        "-S {params.method} -t {threads} -a {threads} > {log} 2>&1"

rule pav_from_orthofinder:
    input:  os.path.join(RESULTS, "orthofinder/Results/SpeciesTree_rooted.txt")
    output: os.path.join(RESULTS, "tables/pav_matrix.csv")
    log:    os.path.join(LOGS, "pav_matrix.log")
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    script: os.path.expanduser("~/lab/utils/orthofinder_to_pav.py")

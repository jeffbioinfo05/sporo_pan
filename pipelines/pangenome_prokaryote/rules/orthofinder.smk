rule orthofinder:
    input:  faa_dir = config["input"]["gff_dir"].replace("gff", "faa")
    output: os.path.join(RESULTS, "orthofinder/Results/SpeciesTree_rooted.txt")
    params:
        outdir    = os.path.join(RESULTS, "orthofinder"),
        inflation = config["orthofinder"]["inflation"],
        method    = config["orthofinder"]["method"],
    log:    os.path.join(LOGS, "orthofinder.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    shell:
        "orthofinder -f {input.faa_dir} -o {params.outdir} "
        "-I {params.inflation} -S {params.method} "
        "-t {threads} -a {threads} > {log} 2>&1"

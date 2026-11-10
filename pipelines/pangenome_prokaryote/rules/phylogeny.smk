rule core_phylogeny:
    input:  os.path.join(RESULTS, "panaroo/core_gene_alignment.aln")
    output: os.path.join(RESULTS, "phylogeny/core_tree.nwk")
    params:
        model = config["phylogeny"]["iqtree_model"],
        bs    = config["phylogeny"]["bootstrap"],
        pfx   = os.path.join(RESULTS, "phylogeny/iqtree_core"),
    log:    os.path.join(LOGS, "core_phylogeny.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    shell:
        "iqtree2 -s {input} -m {params.model} -bb {params.bs} "
        "-T {threads} --prefix {params.pfx} > {log} 2>&1 && "
        "cp {params.pfx}.treefile {output}"

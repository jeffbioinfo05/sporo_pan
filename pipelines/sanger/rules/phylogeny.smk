rule mafft:
    input:  os.path.join(RESULTS, "phylogeny/all_sequences.fasta")
    output: os.path.join(RESULTS, "phylogeny/aligned.fasta")
    params: mode = config["phylogeny"]["mafft_mode"]
    log:    os.path.join(LOGS, "mafft.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/sanger")
    shell:  "mafft --{params.mode} --thread {threads} {input} > {output} 2> {log}"

rule trimal:
    input:  os.path.join(RESULTS, "phylogeny/aligned.fasta")
    output: os.path.join(RESULTS, "phylogeny/aligned_trimmed.fasta")
    params: mode = config["phylogeny"]["trimal_mode"]
    log:    os.path.join(LOGS, "trimal.log")
    conda:  os.path.expanduser("~/lab/software/envs/sanger")
    shell:  "trimal -in {input} -out {output} -{params.mode} > {log} 2>&1"

rule iqtree:
    input:  os.path.join(RESULTS, "phylogeny/aligned_trimmed.fasta")
    output: os.path.join(RESULTS, "phylogeny/tree.nwk")
    params:
        model = config["phylogeny"]["iqtree_model"],
        bs    = config["phylogeny"]["bootstrap"],
        pfx   = os.path.join(RESULTS, "phylogeny/iqtree"),
    log:    os.path.join(LOGS, "iqtree.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/sanger")
    shell:
        "iqtree2 -s {input} -m {params.model} -bb {params.bs} "
        "-T {threads} --prefix {params.pfx} > {log} 2>&1 && "
        "cp {params.pfx}.treefile {output}"

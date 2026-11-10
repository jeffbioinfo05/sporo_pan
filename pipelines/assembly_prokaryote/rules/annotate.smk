rule annotate:
    input:  os.path.join(RESULTS, "assembly/{sample}/assembly.fasta")
    output:
        gff = os.path.join(RESULTS, "annotation/{sample}/{sample}.gff"),
        faa = os.path.join(RESULTS, "annotation/{sample}/{sample}.faa"),
    params:
        outdir  = os.path.join(RESULTS, "annotation/{sample}"),
        genus   = config["annotation"].get("genus", ""),
        species = config["annotation"].get("species", ""),
        db      = config["databases"]["bakta"],
        bindir  = os.path.expanduser("~/lab/software/envs/annotation/bin"),
    log:    os.path.join(LOGS, "annotate/{sample}.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/annotation")
    shell:
        "bakta --db {params.db} --output {params.outdir} "
        "--prefix {wildcards.sample} "
        "--genus '{params.genus}' --species '{params.species}' "
        "--threads {threads} --force {input} > {log} 2>&1"

rule eggnog:
    input:  os.path.join(RESULTS, "annotation/{sample}/{sample}.faa")
    output: os.path.join(RESULTS, "annotation/{sample}/{sample}.emapper.annotations")
    params:
        outdir = os.path.join(RESULTS, "annotation/{sample}"),
        db     = config["databases"]["eggnog"],
    log:    os.path.join(LOGS, "eggnog/{sample}.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/annotation")
    shell:
        "emapper.py -i {input} -o {wildcards.sample} "
        "--output_dir {params.outdir} "
        "--data_dir {params.db} --cpu {threads} --override > {log} 2>&1"

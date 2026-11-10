BRAKER3_SIF = os.path.expanduser("~/lab/software/containers/braker3.sif")

rule braker3:
    input:  os.path.join(RESULTS, "repeats/{sample}/assembly.masked.fasta")
    output:
        gtf = os.path.join(RESULTS, "annotation/{sample}/braker.gtf"),
        aa  = os.path.join(RESULTS, "annotation/{sample}/braker.aa"),
    params:
        outdir   = os.path.join(RESULTS, "annotation/{sample}"),
        orthodb  = config["databases"]["orthodb"],
        rnabam   = config["braker"].get("rnaseq_bam", ""),
        evidence = config["braker"]["evidence"],
    log:    os.path.join(LOGS, "braker3/{sample}.log")
    threads: THREADS_H
    container: BRAKER3_SIF
    run:
        import subprocess
        prot_flag = f"--prot_seq {params.orthodb}" if "proteins" in params.evidence else ""
        rna_flag  = f"--bam {params.rnabam}"       if "rnaseq"   in params.evidence else ""
        cmd = (f"braker.pl --genome {input} {prot_flag} {rna_flag} "
               f"--workingdir {params.outdir} --threads {threads} "
               f"--softmasking > {log} 2>&1")
        subprocess.run(cmd, shell=True, check=True)

rule eggnog:
    input:  os.path.join(RESULTS, "annotation/{sample}/braker.aa")
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

TOOL = config["assembly"]["tool"]

rule assembly:
    input:
        r1 = lambda wc: (os.path.join(PROC, f"decontam/{wc.sample}_R1.fastq.gz")
                         if config["decontam"]["run"] else
                         os.path.join(PROC, f"trimmed/{wc.sample}_R1.fastq.gz")),
        r2 = lambda wc: (os.path.join(PROC, f"decontam/{wc.sample}_R2.fastq.gz")
                         if config["decontam"]["run"] else
                         os.path.join(PROC, f"trimmed/{wc.sample}_R2.fastq.gz")),
    output:
        fasta = os.path.join(RESULTS, "assembly/{sample}/assembly.fasta")
    params:
        outdir = os.path.join(RESULTS, "assembly/{sample}"),
        gsize  = config["assembly"]["genome_size"],
        minlen = config["assembly"]["min_contig_len"],
        bindir = os.path.expanduser("~/lab/software/envs/assembly_core/bin"),
    log:    os.path.join(LOGS, "assembly/{sample}.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/assembly_core")
    run:
        import subprocess, os
        env = os.environ.copy()
        env["PATH"] = params.bindir + ":" + env.get("PATH", "")
        os.makedirs(params.outdir, exist_ok=True)
        if TOOL == "spades":
            cmd = (f"spades.py -1 {input.r1} -2 {input.r2} "
                   f"-o {params.outdir}/spades -t {threads} 2>{log} && "
                   f"cp {params.outdir}/spades/scaffolds.fasta {output.fasta}")
        elif TOOL == "flye":
            cmd = (f"flye --nano-raw {input.r1} --genome-size {params.gsize} "
                   f"--out-dir {params.outdir}/flye -t {threads} 2>{log} && "
                   f"cp {params.outdir}/flye/assembly.fasta {output.fasta}")
        elif TOOL == "unicycler":
            cmd = (f"unicycler -1 {input.r1} -2 {input.r2} "
                   f"-o {params.outdir}/unicycler -t {threads} 2>{log} && "
                   f"cp {params.outdir}/unicycler/assembly.fasta {output.fasta}")
        subprocess.run(cmd, shell=True, check=True, env=env)

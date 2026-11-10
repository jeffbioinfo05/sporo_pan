TOOL      = config["assembly"]["tool"]
DATA_TYPE = config["assembly"]["data_type"]

rule assembly:
    input:
        r1 = lambda wc: clean_reads(wc.sample, "R1"),
        r2 = lambda wc: clean_reads(wc.sample, "R2"),
    output:
        fasta = os.path.join(RESULTS, "assembly/{sample}/assembly.fasta"),
    params:
        outdir = os.path.join(RESULTS, "assembly/{sample}"),
        gsize  = config["assembly"]["genome_size"],
        minlen = config["assembly"]["min_contig_len"],
        depth  = config["assembly"].get("shovill_depth", 100),
        bindir = os.path.expanduser("~/lab/software/envs/assembly_core/bin"),
    log:    os.path.join(LOGS, "assembly/{sample}.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/assembly_core")
    run:
        import subprocess, os
        env = os.environ.copy()
        env["PATH"] = params.bindir + ":" + env.get("PATH", "")
        os.makedirs(params.outdir, exist_ok=True)
        if TOOL == "shovill":
            cmd = (f"shovill --R1 {input.r1} --R2 {input.r2} "
                   f"--outdir {params.outdir}/shovill --gsize {params.gsize} "
                   f"--depth {params.depth} --minlen {params.minlen} "
                   f"--cpus {threads} --force 2>{log} && "
                   f"cp {params.outdir}/shovill/contigs.fa {output.fasta}")
        elif TOOL == "spades":
            cmd = (f"spades.py -1 {input.r1} -2 {input.r2} "
                   f"-o {params.outdir}/spades -t {threads} 2>{log} && "
                   f"cp {params.outdir}/spades/contigs.fasta {output.fasta}")
        elif TOOL == "flye":
            cmd = (f"flye --nano-raw {input.r1} --genome-size {params.gsize} "
                   f"--out-dir {params.outdir}/flye --threads {threads} 2>{log} && "
                   f"cp {params.outdir}/flye/assembly.fasta {output.fasta}")
        elif TOOL == "unicycler":
            cmd = (f"unicycler -1 {input.r1} -2 {input.r2} "
                   f"-o {params.outdir}/unicycler -t {threads} 2>{log} && "
                   f"cp {params.outdir}/unicycler/assembly.fasta {output.fasta}")
        subprocess.run(cmd, shell=True, check=True, env=env)

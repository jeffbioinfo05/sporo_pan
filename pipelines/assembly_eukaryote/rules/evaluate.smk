rule quast:
    input:  os.path.join(RESULTS, "assembly/{sample}/assembly.fasta")
    output: os.path.join(RESULTS, "evaluate/quast/{sample}/report.tsv")
    params: outdir = os.path.join(RESULTS, "evaluate/quast/{sample}")
    log:    os.path.join(LOGS, "quast/{sample}.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/assembly_core")
    shell:  "quast {input} -o {params.outdir} -t {threads} > {log} 2>&1"

rule busco:
    input:  os.path.join(RESULTS, "assembly/{sample}/assembly.fasta")
    output: os.path.join(RESULTS, "evaluate/busco/{sample}/short_summary.txt")
    params:
        outdir  = os.path.join(RESULTS, "evaluate/busco/{sample}"),
        lineage = config["databases"]["busco_lineage"],
        db      = config["databases"]["busco"],
        tmp_dir = os.path.join(TMP, "busco/{sample}"),
    log:    os.path.join(LOGS, "busco/{sample}.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/assembly_core")
    run:
        import subprocess, glob, shutil, os
        env = os.environ.copy()
        env["PATH"] = os.path.expanduser("~/lab/software/envs/assembly_core/bin") + ":" + env.get("PATH","")

        os.makedirs(params.outdir, exist_ok=True)
        os.makedirs(params.tmp_dir, exist_ok=True)

        # Roda a partir de um diretório temporário com permissão de escrita
        # --out_path força o BUSCO 6 a escrever no caminho absoluto correto
        cmd = (
            f"cd {params.tmp_dir} && "
            f"busco -i {input} -o {params.outdir} -l {params.lineage} "
            f"--offline --download_path {params.db} -m genome "
            f"-c {threads} --force > {log[0]} 2>&1"
        )
        subprocess.run(cmd, shell=True, check=True, env=env)

        # BUSCO 6.x: short_summary.specific.<lineage>.<sample>.txt
        patterns = [
            os.path.join(params.outdir, "short_summary.specific.*.txt"),
            os.path.join(params.outdir, "short_summary*.txt"),
            os.path.join(params.outdir, "**", "short_summary*.txt"),
        ]
        found = []
        for pat in patterns:
            found.extend(glob.glob(pat, recursive=True))

        if found:
            shutil.copy(found[0], output[0])
        else:
            raise FileNotFoundError(
                f"BUSCO não gerou short_summary em {params.outdir}. "
                f"Verifique: {log[0]}"
            )

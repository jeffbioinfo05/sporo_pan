# repeats.smk
# Input: genoma filtrado (passou quality_filter)
# Container: tetools.sif (RepeatMasker + RepeatModeler)

TETOOLS_SIF = os.path.expanduser("~/lab/software/containers/tetools.sif")

rule repeatmodeler:
    input:
        # Usa o genoma FILTRADO — só chega aqui se passou quality_filter
        fasta = os.path.join(RESULTS, "filtered/{sample}/assembly.fasta")
    output:
        lib = os.path.join(RESULTS, "repeats/{sample}/repeat_library.fa")
    params:
        outdir  = os.path.join(RESULTS, "repeats/{sample}"),
        run_rm  = config["repeats"]["run_repeatmodeler"],
        lib     = config["repeats"].get("repeat_library", ""),
    log:    os.path.join(LOGS, "repeatmodeler/{sample}.log")
    threads: THREADS_H
    container: TETOOLS_SIF
    run:
        import subprocess, shutil, os

        # Verifica se o genoma realmente passou (não é arquivo vazio)
        if os.path.getsize(input.fasta) == 0:
            with open(log[0], "w") as f:
                f.write(f"SKIP: {wildcards.sample} não passou no quality_filter\n")
            open(output.lib, "w").close()  # cria arquivo vazio para Snakemake
        elif params.run_rm:
            os.makedirs(params.outdir, exist_ok=True)
            cmd = (
                f"cd {params.outdir} && "
                f"BuildDatabase -name {wildcards.sample}_db {input.fasta} >> {log[0]} 2>&1 && "
                f"RepeatModeler -database {wildcards.sample}_db -pa {threads} >> {log[0]} 2>&1 && "
                f"cat {params.outdir}/{wildcards.sample}_db-families.fa > {output.lib}"
            )
            subprocess.run(cmd, shell=True, check=True)
        elif params.lib and os.path.exists(params.lib):
            shutil.copy(params.lib, output.lib)
        else:
            raise ValueError(
                f"run_repeatmodeler: false mas repeat_library não definida ou não existe. "
                f"Defina 'repeat_library' no config.yaml ou mude 'run_repeatmodeler' para true."
            )

rule repeatmasker:
    input:
        fasta = os.path.join(RESULTS, "filtered/{sample}/assembly.fasta"),
        lib   = os.path.join(RESULTS, "repeats/{sample}/repeat_library.fa"),
    output:
        masked = os.path.join(RESULTS, "repeats/{sample}/assembly.masked.fasta")
    params:
        outdir    = os.path.join(RESULTS, "repeats/{sample}"),
        soft_mask = "-xsmall" if config["repeats"]["soft_mask"] else "",
    log:    os.path.join(LOGS, "repeatmasker/{sample}.log")
    threads: THREADS_H
    container: TETOOLS_SIF
    run:
        import subprocess, os

        # Pula se genoma não passou no filtro
        if os.path.getsize(input.fasta) == 0:
            with open(log[0], "w") as f:
                f.write(f"SKIP: {wildcards.sample} não passou no quality_filter\n")
            open(output.masked, "w").close()
        else:
            cmd = (
                f"RepeatMasker {params.soft_mask} -lib {input.lib} "
                f"-pa {threads} -dir {params.outdir} {input.fasta} > {log[0]} 2>&1 && "
                f"mv {params.outdir}/$(basename {input.fasta}).masked {output.masked}"
            )
            subprocess.run(cmd, shell=True, check=True)

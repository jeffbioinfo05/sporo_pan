rule cutadapt:
    input:
        r1 = lambda wc: SAMPLES.loc[wc.sample, "fastq_1"],
        r2 = lambda wc: SAMPLES.loc[wc.sample, "fastq_2"],
    output:
        r1  = os.path.join(PROC, "primers/{sample}_R1.fastq.gz"),
        r2  = os.path.join(PROC, "primers/{sample}_R2.fastq.gz"),
        log_tsv = os.path.join(RESULTS, "qc/cutadapt/{sample}.tsv"),
    params:
        fwd    = config["marker"]["forward_primer"],
        rev    = config["marker"]["reverse_primer"],
        err    = config["primers"]["error_rate"],
        minov  = config["primers"]["min_overlap"],
        minlen = config["primers"]["min_length"],
        discard= "--discard-untrimmed" if config["primers"]["discard_untrimmed"] else "",
    log: os.path.join(LOGS, "cutadapt/{sample}.log")
    threads: THREADS
    conda: os.path.expanduser("~/lab/software/envs/metabarcoding")
    shell:
        "mkdir -p $(dirname {output.r1}) $(dirname {output.log_tsv}) && "
        "cutadapt -g {params.fwd} -G {params.rev} "
        "-e {params.err} --overlap {params.minov} --minimum-length {params.minlen} "
        "{params.discard} -j {threads} "
        "--json {output.log_tsv} "
        "-o {output.r1} -p {output.r2} {input.r1} {input.r2} > {log} 2>&1"

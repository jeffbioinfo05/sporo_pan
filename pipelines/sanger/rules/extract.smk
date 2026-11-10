def get_ab1(wc, read):
    val = SAMPLES.loc[wc.sample, read]
    return val if pd.notna(val) and val != "" else None

rule tracy_fwd:
    input:  lambda wc: SAMPLES.loc[wc.sample, "ab1_fwd"]
    output: os.path.join(PROC, "tracy/{sample}_fwd.fastq")
    params:
        minq   = config["ab1"]["min_quality"],
        outdir = os.path.join(PROC, "tracy"),
    log: os.path.join(LOGS, "tracy/{sample}_fwd.log")
    conda: os.path.expanduser("~/lab/software/envs/sanger")
    shell:
        "mkdir -p {params.outdir} && "
        "tracy basecall -q {params.minq} -o {params.outdir}/{wildcards.sample}_fwd {input} > {log} 2>&1"

rule tracy_rev:
    input:  lambda wc: SAMPLES.loc[wc.sample, "ab1_rev"]
    output: os.path.join(PROC, "tracy/{sample}_rev.fastq")
    params:
        minq   = config["ab1"]["min_quality"],
        outdir = os.path.join(PROC, "tracy"),
    log: os.path.join(LOGS, "tracy/{sample}_rev.log")
    conda: os.path.expanduser("~/lab/software/envs/sanger")
    shell:
        "mkdir -p {params.outdir} && "
        "tracy basecall -q {params.minq} -o {params.outdir}/{wildcards.sample}_rev {input} > {log} 2>&1"

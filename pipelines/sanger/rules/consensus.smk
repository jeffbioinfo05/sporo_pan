rule consensus:
    input:
        fwd = os.path.join(PROC, "tracy/{sample}_fwd.fastq"),
        rev = lambda wc: (os.path.join(PROC, f"tracy/{wc.sample}_rev.fastq")
                          if pd.notna(SAMPLES.loc[wc.sample, "ab1_rev"])
                          and SAMPLES.loc[wc.sample, "ab1_rev"] != "" else []),
    output:
        fasta = os.path.join(RESULTS, "consensus/{sample}.fasta"),
        stats = os.path.join(RESULTS, "consensus/{sample}_stats.tsv"),
    params:
        min_overlap = config["consensus"]["min_overlap"],
        min_ident   = config["consensus"]["min_identity"],
        sample      = "{sample}",
    log: os.path.join(LOGS, "consensus/{sample}.log")
    conda: os.path.expanduser("~/lab/software/envs/sanger")
    script: os.path.expanduser("~/lab/utils/sanger_consensus.py")

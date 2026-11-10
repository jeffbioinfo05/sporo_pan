rule fastqc_raw:
    input:
        r1 = lambda wc: SAMPLES.loc[wc.sample, "fastq_1"],
        r2 = lambda wc: SAMPLES.loc[wc.sample, "fastq_2"]
    output:
        os.path.join(RESULTS, "qc/fastqc_raw/{sample}_R1_fastqc.html"),
        os.path.join(RESULTS, "qc/fastqc_raw/{sample}_R1_fastqc.zip"),
        os.path.join(RESULTS, "qc/fastqc_raw/{sample}_R2_fastqc.html"),
        os.path.join(RESULTS, "qc/fastqc_raw/{sample}_R2_fastqc.zip"),
    params: outdir = os.path.join(RESULTS, "qc/fastqc_raw")
    log:    os.path.join(LOGS, "fastqc_raw/{sample}.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/general")
    shell:  "mkdir -p {params.outdir} && fastqc -t {threads} -o {params.outdir} {input.r1} {input.r2} > {log} 2>&1"

rule fastp:
    input:
        r1 = lambda wc: SAMPLES.loc[wc.sample, "fastq_1"],
        r2 = lambda wc: SAMPLES.loc[wc.sample, "fastq_2"]
    output:
        r1   = os.path.join(PROC, "trimmed/{sample}_R1.fastq.gz"),
        r2   = os.path.join(PROC, "trimmed/{sample}_R2.fastq.gz"),
        json = os.path.join(RESULTS, "qc/fastp/{sample}.json"),
        html = os.path.join(RESULTS, "qc/fastp/{sample}.html"),
    params:
        qual   = config["qc"]["quality_threshold"],
        minlen = config["qc"]["min_length"],
        extra  = config["qc"]["extra_flags"],
    log:    os.path.join(LOGS, "fastp/{sample}.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/general")
    shell:
        "mkdir -p $(dirname {output.r1}) $(dirname {output.json}) && "
        "fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} "
        "--json {output.json} --html {output.html} "
        "--thread {threads} --qualified_quality_phred {params.qual} "
        "--length_required {params.minlen} {params.extra} 2> {log}"

rule multiqc:
    input:
        expand(os.path.join(RESULTS, "qc/fastqc_raw/{sample}_R1_fastqc.zip"), sample=SAMPLE_IDS),
        expand(os.path.join(RESULTS, "qc/fastp/{sample}.json"), sample=SAMPLE_IDS),
    output:
        report = os.path.join(RESULTS, "qc/multiqc_report.html"),
        data   = directory(os.path.join(RESULTS, "qc/multiqc_data")),
    log:    os.path.join(LOGS, "multiqc.log")
    conda:  os.path.expanduser("~/lab/software/envs/general")
    shell:  "multiqc {RESULTS}/qc -o {RESULTS}/qc -n multiqc_report --force > {log} 2>&1"

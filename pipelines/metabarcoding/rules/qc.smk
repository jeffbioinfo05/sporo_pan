rule fastp:
    input:
        r1 = os.path.join(PROC, "primers/{sample}_R1.fastq.gz"),
        r2 = os.path.join(PROC, "primers/{sample}_R2.fastq.gz"),
    output:
        r1   = os.path.join(PROC, "trimmed/{sample}_R1.fastq.gz"),
        r2   = os.path.join(PROC, "trimmed/{sample}_R2.fastq.gz"),
        json = os.path.join(RESULTS, "qc/fastp/{sample}.json"),
        html = os.path.join(RESULTS, "qc/fastp/{sample}.html"),
    params:
        qual   = config["qc"]["quality_threshold"],
        maxee  = config["qc"]["max_ee_fwd"],
        minlen = config["primers"]["min_length"],
        extra  = config["qc"]["extra_flags"],
    log:    os.path.join(LOGS, "fastp/{sample}.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/metabarcoding")
    shell:
        "mkdir -p $(dirname {output.r1}) $(dirname {output.json}) && "
        "fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} "
        "--json {output.json} --html {output.html} "
        "--thread {threads} --qualified_quality_phred {params.qual} "
        "--length_required {params.minlen} {params.extra} 2> {log}"

rule multiqc:
    input:
        expand(os.path.join(RESULTS, "qc/fastp/{sample}.json"),       sample=SAMPLE_IDS),
        expand(os.path.join(RESULTS, "qc/cutadapt/{sample}.tsv"),     sample=SAMPLE_IDS),
    output:
        report = os.path.join(RESULTS, "qc/multiqc_report.html"),
        data   = directory(os.path.join(RESULTS, "qc/multiqc_data")),
    log:    os.path.join(LOGS, "multiqc.log")
    conda:  os.path.expanduser("~/lab/software/envs/metabarcoding")
    shell:  "multiqc {RESULTS}/qc -o {RESULTS}/qc -n multiqc_report --force > {log} 2>&1"

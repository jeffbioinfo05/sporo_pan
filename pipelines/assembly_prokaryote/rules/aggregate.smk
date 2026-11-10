rule aggregate_metrics:
    input:
        fastp   = expand(os.path.join(RESULTS, "qc/fastp/{sample}.json"),        sample=SAMPLE_IDS),
        quast   = expand(os.path.join(RESULTS, "evaluate/quast/{sample}/report.tsv"),  sample=SAMPLE_IDS),
        busco   = expand(os.path.join(RESULTS, "evaluate/busco/{sample}/short_summary.txt"), sample=SAMPLE_IDS),
        checkm2 = expand(os.path.join(RESULTS, "evaluate/checkm2/{sample}/quality_report.tsv"), sample=SAMPLE_IDS),
        gff     = expand(os.path.join(RESULTS, "annotation/{sample}/{sample}.gff"),  sample=SAMPLE_IDS),
    output: os.path.join(RESULTS, "metrics_summary.xlsx")
    log:    os.path.join(LOGS, "aggregate_metrics.log")
    conda:  os.path.expanduser("~/lab/software/envs/general")
    script: os.path.expanduser("~/lab/utils/aggregate_assembly_prokaryote.py")

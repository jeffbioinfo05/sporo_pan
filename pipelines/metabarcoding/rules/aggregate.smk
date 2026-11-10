rule aggregate_metrics:
    input:
        cutadapt = expand(os.path.join(RESULTS, "qc/cutadapt/{sample}.tsv"), sample=SAMPLE_IDS),
        fastp    = expand(os.path.join(RESULTS, "qc/fastp/{sample}.json"),   sample=SAMPLE_IDS),
        dada2    = os.path.join(RESULTS, "dada2/dada2_stats.csv"),
        alpha    = os.path.join(RESULTS, "diversity/alpha_diversity.csv"),
    output: os.path.join(RESULTS, "metrics_summary.xlsx")
    log:    os.path.join(LOGS, "aggregate_metrics.log")
    conda:  os.path.expanduser("~/lab/software/envs/metabarcoding")
    script: os.path.expanduser("~/lab/utils/aggregate_metabarcoding.py")

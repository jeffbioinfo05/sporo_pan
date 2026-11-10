rule aggregate_metrics:
    input:
        consensus_stats = expand(os.path.join(RESULTS, "consensus/{sample}_stats.tsv"), sample=SAMPLE_IDS),
        blast_hits      = expand(os.path.join(RESULTS, "blast/{sample}_hits.tsv"),      sample=SAMPLE_IDS),
        tree            = os.path.join(RESULTS, "phylogeny/tree.nwk"),
    output: os.path.join(RESULTS, "metrics_summary.xlsx")
    log:    os.path.join(LOGS, "aggregate_metrics.log")
    conda:  os.path.expanduser("~/lab/software/envs/sanger")
    script: os.path.expanduser("~/lab/utils/aggregate_sanger.py")

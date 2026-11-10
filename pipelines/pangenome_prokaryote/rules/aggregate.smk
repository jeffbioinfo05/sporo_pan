rule aggregate_metrics:
    input:
        pav    = os.path.join(RESULTS, "tables/pav_matrix.csv"),
        func   = os.path.join(RESULTS, "tables/functional_table.csv"),
        class_ = os.path.join(RESULTS, "tables/gene_classification.csv"),
    output: os.path.join(RESULTS, "metrics_summary.xlsx")
    log:    os.path.join(LOGS, "aggregate_metrics.log")
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    script: os.path.expanduser("~/lab/utils/aggregate_pangenome.py")

rule panaroo:
    input:  gffs = expand(os.path.join(GFF_DIR, "{genome}.gff"), genome=GENOMES)
    output:
        pan_ref = os.path.join(RESULTS, "panaroo/pan_genome_reference.fa"),
        pav     = os.path.join(RESULTS, "panaroo/gene_presence_absence.csv"),
        core_fa = os.path.join(RESULTS, "panaroo/core_gene_alignment.aln"),
    params:
        outdir    = os.path.join(RESULTS, "panaroo"),
        mode      = config["panaroo"]["mode"],
        core_freq = config["panaroo"]["min_freq_core"],
        aligner   = config["panaroo"]["aligner"],
    log:    os.path.join(LOGS, "panaroo.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/pangenomics")
    shell:
        "panaroo -i {input.gffs} -o {params.outdir} "
        "--clean-mode {params.mode} --core_threshold {params.core_freq} "
        "--aligner {params.aligner} -t {threads} --force > {log} 2>&1"

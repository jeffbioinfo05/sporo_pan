BLAST_DB = {"16S": config["databases"]["blast_16s"],
            "ITS": config["databases"]["blast_its"]}

rule blast:
    input:  os.path.join(RESULTS, "consensus/{sample}.fasta")
    output: os.path.join(RESULTS, "blast/{sample}_hits.tsv")
    params:
        db      = lambda wc: BLAST_DB.get(GENE, config["databases"]["blast_16s"]),
        maxhits = config["blast"]["max_hits"],
        minid   = config["blast"]["min_identity"],
        mincov  = config["blast"]["min_coverage"],
        evalue  = config["blast"]["evalue"],
    log:    os.path.join(LOGS, "blast/{sample}.log")
    threads: THREADS
    conda:  os.path.expanduser("~/lab/software/envs/sanger")
    shell:
        "blastn -query {input} -db {params.db} "
        "-out {output} -outfmt '6 qseqid sseqid pident length qcovs evalue bitscore stitle' "
        "-max_target_seqs {params.maxhits} -evalue {params.evalue} "
        "-perc_identity {params.minid} -num_threads {threads} > {log} 2>&1"

rule fetch_neighbors:
    input:
        consensus = expand(os.path.join(RESULTS, "consensus/{sample}.fasta"), sample=SAMPLE_IDS),
        blast     = expand(os.path.join(RESULTS, "blast/{sample}_hits.tsv"),  sample=SAMPLE_IDS),
    output:
        combined  = os.path.join(RESULTS, "phylogeny/all_sequences.fasta"),
    params:
        n_neighbors     = config["neighbors"]["n_neighbors"],
        org_filter      = config["neighbors"]["organism_filter"],
        include_outgroup= config["neighbors"]["include_outgroup"],
        outgroup_taxid  = config["neighbors"]["outgroup_taxid"],
        sample_ids      = SAMPLE_IDS,
        consensus_dir   = os.path.join(RESULTS, "consensus"),
        blast_dir       = os.path.join(RESULTS, "blast"),
    log:    os.path.join(LOGS, "fetch_neighbors.log")
    conda:  os.path.expanduser("~/lab/software/envs/sanger")
    script: os.path.expanduser("~/lab/utils/fetch_ncbi_neighbors.py")

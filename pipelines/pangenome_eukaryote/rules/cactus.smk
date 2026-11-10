CACTUS_SIF = os.path.expanduser(CONTAINERS.get("cactus", "~/lab/software/containers/cactus.sif"))

rule cactus_align:
    input:  genomes = expand(os.path.join(GENOMES_DIR, "{genome}.fasta"), genome=GENOMES)
    output:
        hal = os.path.join(RESULTS, "cactus/pangenome.hal"),
        vcf = os.path.join(RESULTS, "cactus/pangenome.vcf.gz"),
    params:
        outdir   = os.path.join(RESULTS, "cactus"),
        seqfile  = os.path.join(RESULTS, "cactus/seqfile.txt"),
        tmp      = config["tmp_dir"],
    log:    os.path.join(LOGS, "cactus.log")
    threads: THREADS_H
    container: CACTUS_SIF
    script: os.path.expanduser("~/lab/utils/run_cactus.py")

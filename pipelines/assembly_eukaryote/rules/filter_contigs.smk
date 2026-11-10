# filter_contigs.smk
# 1. Kraken2 nos contigs montados — identifica contaminantes bacterianos
# 2. Remove contigs classificados como bacterianos
# 3. Avalia métricas e decide se o genoma passa para anotação

KRAKEN2_DB  = config["quality_filter"]["kraken2_db"]
MAX_BAC_PCT = config["quality_filter"]["max_bacterial_pct"]
MIN_BUSCO   = config["quality_filter"]["min_busco_complete"]
MAX_MISSING = config["quality_filter"]["max_busco_missing"]
MIN_N50     = config["quality_filter"]["min_n50"]
MAX_CONTIGS = config["quality_filter"]["max_contigs"]

rule kraken2_contigs:
    input:
        fasta = os.path.join(RESULTS, "assembly/{sample}/assembly.fasta")
    output:
        report    = os.path.join(RESULTS, "decontam_contigs/{sample}/kraken2_report.txt"),
        classified= os.path.join(RESULTS, "decontam_contigs/{sample}/classified.txt"),
    params:
        db = KRAKEN2_DB,
    log:    os.path.join(LOGS, "kraken2_contigs/{sample}.log")
    threads: THREADS_H
    conda:  os.path.expanduser("~/lab/software/envs/general")
    shell:
        "kraken2 --db {params.db} --threads {threads} "
        "--output {output.classified} --report {output.report} "
        "--use-names {input.fasta} > {log} 2>&1"

rule remove_bacterial_contigs:
    input:
        fasta      = os.path.join(RESULTS, "assembly/{sample}/assembly.fasta"),
        classified = os.path.join(RESULTS, "decontam_contigs/{sample}/classified.txt"),
        report     = os.path.join(RESULTS, "decontam_contigs/{sample}/kraken2_report.txt"),
    output:
        fasta_clean = os.path.join(RESULTS, "decontam_contigs/{sample}/assembly_clean.fasta"),
        summary     = os.path.join(RESULTS, "decontam_contigs/{sample}/decontam_summary.tsv"),
    params:
        max_bac_pct = MAX_BAC_PCT,
    log:    os.path.join(LOGS, "remove_bacterial_contigs/{sample}.log")
    conda:  os.path.expanduser("~/lab/software/envs/general")
    run:
        import subprocess, os
        env = os.environ.copy()
        env["PATH"] = os.path.expanduser("~/lab/software/envs/general/bin") + ":" + env.get("PATH","")

        # Lê contigs classificados como Bacteria (domínio 2)
        bacterial_contigs = set()
        total_contigs = 0
        with open(input.classified) as f:
            for line in f:
                parts = line.strip().split("\t")
                if len(parts) < 3:
                    continue
                total_contigs += 1
                status   = parts[0]   # C = classified, U = unclassified
                contig   = parts[1]
                taxon    = parts[2]
                # Marca como bacteriano se classificado e não fungo/eucarioto
                if status == "C" and any(x in taxon.lower() for x in
                    ["bacteria", "archaea", "virus", "phage"]):
                    bacterial_contigs.add(contig)

        bac_pct = len(bacterial_contigs) / total_contigs * 100 if total_contigs > 0 else 0

        # Filtra o FASTA removendo contigs bacterianos
        from Bio import SeqIO
        records = list(SeqIO.parse(input.fasta, "fasta"))
        clean   = [r for r in records if r.id not in bacterial_contigs]
        SeqIO.write(clean, output.fasta_clean, "fasta")

        # Resumo
        with open(output.summary, "w") as f:
            f.write("sample\ttotal_contigs\tbacterial_contigs\tbacterial_pct\tclean_contigs\n")
            f.write(f"{wildcards.sample}\t{total_contigs}\t{len(bacterial_contigs)}\t"
                    f"{bac_pct:.2f}\t{len(clean)}\n")

        with open(log[0], "w") as f:
            f.write(f"Total contigs: {total_contigs}\n")
            f.write(f"Bacterianos removidos: {len(bacterial_contigs)} ({bac_pct:.2f}%)\n")
            f.write(f"Contigs limpos: {len(clean)}\n")

rule quality_filter:
    input:
        fasta_clean = os.path.join(RESULTS, "decontam_contigs/{sample}/assembly_clean.fasta"),
        busco_sum   = os.path.join(RESULTS, "evaluate/busco/{sample}/short_summary.txt"),
        quast_rep   = os.path.join(RESULTS, "evaluate/quast/{sample}/report.tsv"),
        bac_summary = os.path.join(RESULTS, "decontam_contigs/{sample}/decontam_summary.tsv"),
    output:
        passed = os.path.join(RESULTS, "filtered/{sample}/assembly.fasta"),
        status = os.path.join(RESULTS, "filtered/{sample}/filter_status.tsv"),
    params:
        min_busco   = MIN_BUSCO,
        max_missing = MAX_MISSING,
        min_n50     = MIN_N50,
        max_contigs = MAX_CONTIGS,
        max_bac_pct = MAX_BAC_PCT,
    log: os.path.join(LOGS, "quality_filter/{sample}.log")
    conda: os.path.expanduser("~/lab/software/envs/general")
    run:
        import re, shutil, os
        import pandas as pd

        reasons = []

        # QUAST
        qdf = pd.read_csv(input.quast_rep, sep="\t", header=None, names=["metric","value"])
        qmap = dict(zip(qdf.metric, qdf.value))
        n50      = int(str(qmap.get("N50", 0)).replace(",",""))
        n_contigs= int(str(qmap.get("# contigs", 9999)).replace(",",""))
        if n50 < params.min_n50:
            reasons.append(f"N50={n50} < {params.min_n50}")
        if n_contigs > params.max_contigs:
            reasons.append(f"contigs={n_contigs} > {params.max_contigs}")

        # BUSCO
        with open(input.busco_sum) as f:
            txt = f.read()
        m = re.search(r"C:(\S+)%.*M:(\S+)%", txt)
        if m:
            busco_complete = float(m.group(1))
            busco_missing  = float(m.group(2))
            if busco_complete < params.min_busco:
                reasons.append(f"BUSCO_complete={busco_complete}% < {params.min_busco}%")
            if busco_missing > params.max_missing:
                reasons.append(f"BUSCO_missing={busco_missing}% > {params.max_missing}%")

        # Contaminação bacteriana
        bdf = pd.read_csv(input.bac_summary, sep="\t")
        bac_pct = float(bdf["bacterial_pct"].iloc[0])
        if bac_pct > params.max_bac_pct:
            reasons.append(f"bacterial_pct={bac_pct:.2f}% > {params.max_bac_pct}%")

        passed = len(reasons) == 0
        status = "PASSED" if passed else "FAILED"

        os.makedirs(os.path.dirname(output.passed), exist_ok=True)
        if passed:
            shutil.copy(input.fasta_clean, output.passed)
        else:
            # Cria arquivo vazio para o Snakemake não reclamar de output faltando
            open(output.passed, "w").close()

        with open(output.status, "w") as f:
            f.write("sample\tstatus\treasons\n")
            f.write(f"{wildcards.sample}\t{status}\t{'; '.join(reasons) if reasons else 'OK'}\n")

        with open(log[0], "w") as f:
            f.write(f"Status: {status}\n")
            if reasons:
                f.write("Razões:\n")
                for r in reasons: f.write(f"  - {r}\n")

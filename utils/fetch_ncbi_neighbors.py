"""
Busca sequências vizinhas no NCBI a partir dos resultados BLAST.
Baixa N sequências por amostra e opcionalmente um outgroup.
"""
import sys, os, time
import pandas as pd
from Bio import Entrez, SeqIO

Entrez.email = "lab@local"

def fetch_accessions(accessions, db="nucleotide"):
    ids = ",".join(accessions)
    handle = Entrez.efetch(db=db, id=ids, rettype="fasta", retmode="text")
    records = list(SeqIO.parse(handle, "fasta"))
    handle.close()
    time.sleep(0.4)
    return records

all_records = []
seen_ids    = set()

for blast_file, cons_file, sample in zip(
    snakemake.input.blast, snakemake.input.consensus, snakemake.params.sample_ids):

    # Adiciona consenso
    for rec in SeqIO.parse(cons_file, "fasta"):
        if rec.id not in seen_ids:
            all_records.append(rec)
            seen_ids.add(rec.id)

    # Lê hits BLAST
    try:
        bdf = pd.read_csv(blast_file, sep="\t", header=None,
                          names=["qseqid","sseqid","pident","length","qcovs","evalue","bitscore","stitle"])
        accs = bdf["sseqid"].head(snakemake.params.n_neighbors).tolist()
        for rec in fetch_accessions(accs):
            if rec.id not in seen_ids:
                all_records.append(rec)
                seen_ids.add(rec.id)
    except Exception as e:
        print(f"Aviso: {sample} — {e}", file=sys.stderr)

os.makedirs(os.path.dirname(snakemake.output.combined), exist_ok=True)
SeqIO.write(all_records, snakemake.output.combined, "fasta")
print(f"Total de sequências combinadas: {len(all_records)}", file=sys.stderr)

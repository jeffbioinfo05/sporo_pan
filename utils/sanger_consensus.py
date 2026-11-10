"""
Constrói sequência consenso a partir de leituras forward e reverse (Sanger).
Chamado via Snakemake script directive.
"""
import sys, os
from Bio import SeqIO
from Bio.Seq import Seq

sample     = snakemake.params.sample
min_ov     = snakemake.params.min_overlap
min_ident  = snakemake.params.min_identity
fwd_file   = snakemake.input.fwd
out_fasta  = snakemake.output.fasta
out_stats  = snakemake.output.stats

def read_first_seq(fq_file):
    recs = list(SeqIO.parse(fq_file, "fastq"))
    return recs[0] if recs else None

fwd_rec = read_first_seq(fwd_file)
rev_rec = None
rev_files = snakemake.input.rev if isinstance(snakemake.input.rev, list) else [snakemake.input.rev]
if rev_files and rev_files[0]:
    rev_rec = read_first_seq(rev_files[0])

consensus = None
method = "single"

if fwd_rec and rev_rec:
    fwd_seq = str(fwd_rec.seq)
    rev_seq = str(rev_rec.seq.reverse_complement())
    # Busca sobreposição
    best_ov, best_pos, best_id = 0, -1, 0.0
    for ov in range(min(len(fwd_seq), len(rev_seq), 300), min_ov - 1, -1):
        f_end = fwd_seq[-ov:]
        r_beg = rev_seq[:ov]
        matches = sum(a == b for a, b in zip(f_end, r_beg))
        ident = matches / ov
        if ident >= min_ident and ov > best_ov:
            best_ov, best_id = ov, ident
            best_pos = len(fwd_seq) - ov
    if best_pos >= 0:
        consensus = fwd_seq[:best_pos] + rev_seq
        method = f"consensus_overlap_{best_ov}bp_id{best_id:.2f}"
    else:
        consensus = fwd_seq
        method = "fwd_only_no_overlap"
elif fwd_rec:
    consensus = str(fwd_rec.seq)
    method = "fwd_only"
else:
    consensus = ""
    method = "failed"

os.makedirs(os.path.dirname(out_fasta), exist_ok=True)
os.makedirs(os.path.dirname(out_stats), exist_ok=True)

with open(out_fasta, "w") as f:
    if consensus:
        f.write(f">{sample}\n{consensus}\n")

with open(out_stats, "w") as f:
    f.write("sample\tmethod\tlength\n")
    f.write(f"{sample}\t{method}\t{len(consensus)}\n")

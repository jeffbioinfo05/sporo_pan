#!/usr/bin/env bash
set -uo pipefail

LINmap="/mnt/bioinfo/projects/2026-05_sporothrix_pan/results/to_manuscript_tables_english/to_manuscript/results/tables/virulence_isolates.tsv"
OUTDIR="results/synteny/summary"
mkdir -p "$OUTDIR"

python3 -I - "$LINmap" << 'PY'
import glob, os, sys
from collections import defaultdict

linfile = sys.argv[1]
BIN = 10000  # 10 kb

# SRR -> lineage
lineage = {}
with open(linfile) as fh:
    hdr = fh.readline().rstrip('\n').split('\t')
    i_iso, i_lin = hdr.index('isolate'), hdr.index('lineage')
    for line in fh:
        c = line.rstrip('\n').split('\t')
        lineage[c[i_iso]] = c[i_lin]

sr_types = {'INV':'inversion','TRANS':'translocation','INVTR':'inv_translocation',
            'DUP':'duplication','INVDP':'inv_duplication'}

# (type, chr, bin) -> set of isolates
hit = defaultdict(set)
samples = []

for f in sorted(glob.glob('results/synteny/*/syri.out')):
    sample = os.path.basename(os.path.dirname(f))
    samples.append(sample)
    with open(f) as fh:
        for line in fh:
            c = line.rstrip('\n').split('\t')
            if len(c) < 11: continue
            t = c[10]
            if t not in sr_types: continue
            chrom = c[0]
            try:
                start = int(c[1]); end = int(c[2])
            except ValueError:
                continue
            for b in range(start//BIN, end//BIN + 1):
                hit[(t, chrom, b)].add(sample)

lins = sorted(set(lineage.values()))
N = len(samples)

rows = []
for (t, chrom, b), isos in hit.items():
    n = len(isos)
    per_lin = {L: sum(1 for s in isos if lineage.get(s)==L) for L in lins}
    rows.append((t, chrom, b*BIN, (b+1)*BIN, n, round(100*n/N,1), per_lin, isos))

# Sort by recurrence
rows.sort(key=lambda r: -r[4])

with open('results/synteny/summary/recurrent_rearrangements.tsv','w') as out:
    out.write('type\tref_chr\tbin_start\tbin_end\tn_isolates\tpct_isolates\t' + '\t'.join(lins) + '\n')
    for t, chrom, s, e, n, pct, per_lin, isos in rows:
        out.write(f'{sr_types[t]}\t{chrom}\t{s}\t{e}\t{n}\t{pct}\t' +
                  '\t'.join(str(per_lin[L]) for L in lins) + '\n')

# Console summary: recurrent (>= 50% isolates) by type
print(f'Isolates: {N}  |  Lineages: {lins}')
print(f'\nRecurrent bins (>= 50% of isolates), by type:')
for t in sr_types:
    rec = [r for r in rows if r[0]==t and r[4] >= N*0.5]
    print(f'  {sr_types[t]:>18}: {len(rec)} recurrent bins')

print('\nTop 15 most recurrent rearrangements:')
print(f'{"type":>16} {"chr":>14} {"start":>9} {"n":>4} {"pct":>5}  lineage_breakdown')
for t, chrom, s, e, n, pct, per_lin, isos in rows[:15]:
    lb = ' '.join(f'{L}:{per_lin[L]}' for L in lins if per_lin[L]>0)
    print(f'{sr_types[t]:>16} {chrom:>14} {s:>9} {n:>4} {pct:>5}  {lb}')
PY

echo "Wrote results/synteny/summary/recurrent_rearrangements.tsv"

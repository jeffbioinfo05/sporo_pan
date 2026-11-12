#!/usr/bin/env bash
set -uo pipefail

LINmap="/mnt/bioinfo/projects/2026-05_sporothrix_pan/results/to_manuscript_tables_english/to_manuscript/results/tables/virulence_isolates.tsv"
OUTDIR="results/synteny/summary"
mkdir -p "$OUTDIR"

python3 -I - "$LINmap" << 'PY'
import glob, os, sys
from collections import defaultdict, Counter
linfile = sys.argv[1]
lineage = {}
with open(linfile) as fh:
    hdr = fh.readline().rstrip('\n').split('\t')
    i,j = hdr.index('isolate'), hdr.index('lineage')
    for line in fh:
        c = line.rstrip('\n').split('\t'); lineage[c[i]] = c[j]

lins = ['L01','L02','L03','L04','L05','L06','L07','L08','L09']
sizes = Counter(lineage.values())

# Collect all INV events: (chr, start, end, sample)
events = []
for f in sorted(glob.glob('results/synteny/*/syri.out')):
    s = os.path.basename(os.path.dirname(f))
    with open(f) as fh:
        for line in fh:
            c = line.rstrip('\n').split('\t')
            if len(c) < 11 or c[10] != 'INV': continue
            try: a,b = int(c[1]), int(c[2])
            except ValueError: continue
            events.append((c[0], a, b, s))

# Cluster by reciprocal overlap >= 50% within same chr
def overlap(a1,b1,a2,b2):
    inter = max(0, min(b1,b2)-max(a1,a2))
    if inter == 0: return 0
    return inter / min(b1-a1, b2-a2)

events.sort(key=lambda e:(e[0], e[1]))
clusters = []  # each: [chr, start, end, set(samples)]
for chrom,a,b,s in events:
    placed = False
    for cl in clusters:
        if cl[0]==chrom and overlap(cl[1],cl[2],a,b) >= 0.5:
            cl[3].add(s)
            cl[1] = min(cl[1],a); cl[2] = max(cl[2],b)
            placed = True; break
    if not placed:
        clusters.append([chrom,a,b,{s}])

# Keep clusters present in >= 3 isolates
clusters = [cl for cl in clusters if len(cl[3])>=3]
clusters.sort(key=lambda cl:-len(cl[3]))

print(f"{'chr':>14} {'start':>9} {'end':>9} {'kb':>6} {'n':>3}  carriers_by_lineage")
with open('results/synteny/summary/inversion_clusters.tsv','w') as out:
    out.write('ref_chr\tstart\tend\tlen_kb\tn_isolates\t'+'\t'.join(lins)+'\tclade_pattern\n')
    for chrom,a,b,ss in clusters:
        per = {L: sum(1 for x in ss if lineage.get(x)==L) for L in lins}
        # clade pattern: lineages where >=50% carry it
        pattern = '+'.join(L for L in lins if sizes.get(L,0) and per[L] >= 0.5*sizes[L])
        lb = ' '.join(f'{L}:{per[L]}' for L in lins if per[L]>0)
        print(f"{chrom:>14} {a:>9} {b:>9} {(b-a)/1000:>6.1f} {len(ss):>3}  {lb}")
        out.write(f"{chrom}\t{a}\t{b}\t{(b-a)/1000:.1f}\t{len(ss)}\t"+
                  '\t'.join(str(per[L]) for L in lins)+f'\t{pattern}\n')
print("\nWrote results/synteny/summary/inversion_clusters.tsv")
PY

#!/usr/bin/env bash
set -uo pipefail
LINmap="/mnt/bioinfo/projects/2026-05_sporothrix_pan/results/to_manuscript_tables_english/to_manuscript/results/tables/virulence_isolates.tsv"

python3 -I - "$LINmap" << 'PY'
import glob, os, sys
from collections import defaultdict, Counter
linfile = sys.argv[1]
lineage = {}
with open(linfile) as fh:
    hdr = fh.readline().rstrip('\n').split('\t'); i,j = hdr.index('isolate'), hdr.index('lineage')
    for line in fh:
        c = line.rstrip('\n').split('\t'); lineage[c[i]] = c[j]

contig_name = {f'NW_0244671{n}.1': f'Cont{12+(n-31)}' for n in range(31,44)}

# Collect INV events per isolate
inv = defaultdict(list)  # chrom -> [(start,end,sample)]
for f in sorted(glob.glob('results/synteny/*/syri.out')):
    s = os.path.basename(os.path.dirname(f))
    with open(f) as fh:
        for line in fh:
            c = line.rstrip('\n').split('\t')
            if len(c) < 11 or c[10]!='INV': continue
            try: a,b = int(c[1]), int(c[2])
            except ValueError: continue
            inv[c[0]].append((a,b,s))

# Clusters of interest (from inversion_clusters.tsv, kept rows)
clusters = []
lins = ['L01','L02','L03','L04','L05','L06','L07','L08','L09']
sizes = {'L01':47,'L02':7,'L03':6,'L04':4,'L05':3,'L06':1,'L07':1,'L08':1,'L09':1}
with open('results/synteny/summary/inversion_clusters.tsv') as fh:
    h = fh.readline().rstrip('\n').split('\t'); idx={x:k for k,x in enumerate(h)}
    for line in fh:
        c = line.rstrip('\n').split('\t')
        n = int(c[idx['n_isolates']])
        per = {L:int(c[idx[L]]) for L in lins}
        keep = n>=4 or any(sizes[L]>=3 and per[L]==sizes[L] for L in lins)
        if keep:
            clusters.append((c[idx['ref_chr']], int(c[idx['start']]), int(c[idx['end']])))

for chrom, cs, ce in clusters:
    name = contig_name.get(chrom, chrom)
    # all INV events overlapping this cluster window
    pairs = Counter()
    carriers = []
    for a,b,s in inv[chrom]:
        inter = max(0, min(b,ce)-max(a,cs))
        if inter >= 0.5*min(b-a, ce-cs):
            pairs[(a,b)] += 1
            carriers.append(s)
    lincnt = Counter(lineage.get(s,'?') for s in carriers)
    print(f"\n{name}:{cs}-{ce}  ({(ce-cs)/1000:.1f} kb, {len(carriers)} carriers)")
    print(f"  lineages: {dict(sorted(lincnt.items()))}")
    print(f"  distinct breakpoint pairs:")
    for (a,b),k in pairs.most_common():
        print(f"    {a:>9}-{b:>9} ({(b-a)/1000:>5.1f} kb)  x{k}")
PY

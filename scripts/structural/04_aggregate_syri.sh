#!/usr/bin/env bash
set -euo pipefail

SYNDIR="results/synteny"
OUTDIR="results/synteny/summary"
mkdir -p "$OUTDIR"

python3 -I << 'PY'
import glob, os
from collections import defaultdict

# SyRI annotation types of interest (structural rearrangements)
sr_types = {'INV':'inversion', 'TRANS':'translocation', 'INVTR':'inverted_translocation',
            'DUP':'duplication', 'INVDP':'inverted_duplication'}

rows = []
per_type = defaultdict(lambda: defaultdict(int))
per_type_bp = defaultdict(lambda: defaultdict(int))

for f in sorted(glob.glob('results/synteny/*/syri.out')):
    sample = os.path.basename(os.path.dirname(f))
    counts = defaultdict(int)
    bp = defaultdict(int)
    with open(f) as fh:
        for line in fh:
            c = line.rstrip('\n').split('\t')
            if len(c) < 11:
                continue
            ann = c[10]
            if ann in sr_types:
                # parent records only (ID not containing a dash suffix like INV1-...)
                rec_id = c[8]
                if rec_id == '-' or '-' not in rec_id:
                    counts[ann] += 1
                    try:
                        start, end = int(c[1]), int(c[2])
                        bp[ann] += abs(end - start)
                    except ValueError:
                        pass
    for ann in sr_types:
        per_type[sample][ann] = counts[ann]
        per_type_bp[sample][ann] = bp[ann]
    rows.append(sample)

# Write per-isolate counts
with open('results/synteny/summary/sv_counts.tsv','w') as out:
    hdr = ['sample'] + [sr_types[t] for t in sr_types] + ['total_SR']
    out.write('\t'.join(hdr) + '\n')
    for s in rows:
        vals = [per_type[s][t] for t in sr_types]
        out.write('\t'.join([s] + [str(v) for v in vals] + [str(sum(vals))]) + '\n')

# Write per-isolate bp
with open('results/synteny/summary/sv_bp.tsv','w') as out:
    hdr = ['sample'] + [sr_types[t]+'_bp' for t in sr_types]
    out.write('\t'.join(hdr) + '\n')
    for s in rows:
        out.write('\t'.join([s] + [str(per_type_bp[s][t]) for t in sr_types]) + '\n')

# Quick summary to stdout
import statistics as st
print(f'Isolates processed: {len(rows)}')
for t in sr_types:
    vals = [per_type[s][t] for s in rows]
    print(f'{sr_types[t]:>24}: median={st.median(vals):.0f}  min={min(vals)}  max={max(vals)}')
PY

echo "Wrote results/synteny/summary/sv_counts.tsv and sv_bp.tsv"

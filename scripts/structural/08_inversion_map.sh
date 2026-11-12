#!/usr/bin/env bash
set -uo pipefail
python3 -I << 'PY'
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

lins = ['L01','L02','L03','L04','L05','L06','L07','L08','L09']
sizes = {'L01':47,'L02':7,'L03':6,'L04':4,'L05':3,'L06':1,'L07':1,'L08':1,'L09':1}
contig_name = {f'NW_0244671{n}.1': f'Cont{12+(n-31)}' for n in range(31,44)}

rows = []
with open('results/synteny/summary/inversion_clusters.tsv') as fh:
    hdr = fh.readline().rstrip('\n').split('\t'); idx={h:k for k,h in enumerate(hdr)}
    for line in fh:
        c = line.rstrip('\n').split('\t')
        n = int(c[idx['n_isolates']]); per = {L:int(c[idx[L]]) for L in lins}
        keep = n>=4 or any(sizes[L]>=3 and per[L]==sizes[L] for L in lins)
        if not keep: continue
        cn = contig_name.get(c[idx['ref_chr']], c[idx['ref_chr']])
        label = f"{cn}:{int(c[idx['start']])//1000}k ({c[idx['len_kb']]} kb)"
        rows.append((label, n, per))

# order to show nesting: by lineage-membership vector, then size
rows.sort(key=lambda r:(tuple(-(1 if r[2][L]>0 else 0) for L in lins), -r[1]))

M = np.array([[ (r[2][L]/sizes[L]) for L in lins] for r in rows])
labels = [r[0] for r in rows]

fig, ax = plt.subplots(figsize=(7.5, 0.5*len(rows)+1.5))
im = ax.imshow(M, aspect='auto', cmap='Blues', vmin=0, vmax=1)
ax.set_xticks(range(len(lins)))
ax.set_xticklabels([f'{L}\n(n={sizes[L]})' for L in lins], fontsize=8)
ax.set_yticks(range(len(rows))); ax.set_yticklabels(labels, fontsize=8)
for i,r in enumerate(rows):
    for jj,L in enumerate(lins):
        v = r[2][L]
        if v>0:
            ax.text(jj, i, str(v), ha='center', va='center',
                    fontsize=7, color='white' if M[i,jj]>0.5 else 'black')
ax.set_xlabel('Lineage')
ax.set_title('Clade-associated inversions (carriers / lineage size)', fontsize=9)
cb = fig.colorbar(im, ax=ax, fraction=0.03, pad=0.02)
cb.set_label('Fraction of lineage carrying', fontsize=8)
plt.tight_layout()
fig.savefig('results/synteny/summary/inversion_map.pdf', dpi=300, bbox_inches='tight')
fig.savefig('results/synteny/summary/inversion_map.png', dpi=200, bbox_inches='tight')
print(f"Saved inversion_map with {len(rows)} inversions")
PY

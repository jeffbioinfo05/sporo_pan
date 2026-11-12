#!/usr/bin/env bash
set -uo pipefail
GFF="data/reference/GCF_000820605.1_genomic.gff"

python3 -I - "$GFF" << 'PY'
import sys
from collections import defaultdict
gff = sys.argv[1]

contig_name = {f'NW_0244671{n}.1': f'Cont{12+(n-31)}' for n in range(31,44)}

# gene features: id -> (chrom,start,end,locus,name)
genes = {}
# product per gene id (from CDS/mRNA Parent)
product = {}
def attrs(s):
    d={}
    for kv in s.split(';'):
        if '=' in kv:
            k,v = kv.split('=',1); d[k]=v
    return d

with open(gff) as fh:
    for line in fh:
        if line.startswith('#'): continue
        c = line.rstrip('\n').split('\t')
        if len(c) < 9: continue
        chrom, typ, start, end, at = c[0], c[2], int(c[3]), int(c[4]), attrs(c[8])
        if typ in ('gene','pseudogene'):
            gid = at.get('ID','')
            genes[gid] = (chrom, start, end,
                          at.get('locus_tag', at.get('Name','')),
                          at.get('gene',''))
        if typ in ('CDS','mRNA'):
            par = at.get('Parent','')
            # Parent of mRNA is gene; Parent of CDS is mRNA; climb one level is enough for mRNA
            if 'product' in at and par:
                product.setdefault(par, at['product'])

# Resolve product to gene id: mRNA Parent is gene id; CDS Parent is mRNA id.
# Build mRNA->gene map
mrna_gene = {}
with open(gff) as fh:
    for line in fh:
        if line.startswith('#'): continue
        c = line.rstrip('\n').split('\t')
        if len(c) < 9 or c[2] != 'mRNA': continue
        at = attrs(c[8]); mrna_gene[at.get('ID','')] = at.get('Parent','')

gene_product = {}
for par, prod in product.items():
    if par in genes:            # mRNA Parent is a gene
        gene_product.setdefault(par, prod)
    elif par in mrna_gene:      # CDS Parent is mRNA -> gene
        gene_product.setdefault(mrna_gene[par], prod)

# Inversions (chrom, start, end) from clusters, kept set
lins = ['L01','L02','L03','L04','L05','L06','L07','L08','L09']
sizes = {'L01':47,'L02':7,'L03':6,'L04':4,'L05':3,'L06':1,'L07':1,'L08':1,'L09':1}
invs = []
with open('results/synteny/summary/inversion_clusters.tsv') as fh:
    h=fh.readline().rstrip('\n').split('\t'); idx={x:k for k,x in enumerate(h)}
    for line in fh:
        c=line.rstrip('\n').split('\t'); n=int(c[idx['n_isolates']])
        per={L:int(c[idx[L]]) for L in lins}
        if n>=4 or any(sizes[L]>=3 and per[L]==sizes[L] for L in lins):
            invs.append((c[idx['ref_chr']],int(c[idx['start']]),int(c[idx['end']]),c[idx['clade_pattern']]))

out = open('results/synteny/summary/inversion_genes.tsv','w')
out.write('inversion\tclade\tgene\tlocus_tag\tproduct\n')
for chrom,s,e,clade in invs:
    cn = contig_name.get(chrom,chrom)
    inside = []
    for gid,(gc,gs,ge,loc,gname) in genes.items():
        if gc==chrom and gs<=e and ge>=s:
            inside.append((loc, gname, gene_product.get(gid,'')))
    print(f"\n{cn}:{s}-{e}  [{clade}]  {len(inside)} genes")
    for loc,gname,prod in inside:
        tag = gname if gname else loc
        print(f"    {loc:<16} {prod}")
        out.write(f"{cn}:{s}-{e}\t{clade}\t{gname}\t{loc}\t{prod}\n")
out.close()
print("\nWrote results/synteny/summary/inversion_genes.tsv")
PY

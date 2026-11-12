#!/usr/bin/env bash
set -uo pipefail

REFERENCE="data/reference/GCF_000820605.1_genomic.fna"
SCAFFDIR="results/scaffolding"
OUTDIR="results/synteny"
THREADS=16
REF_IDS="/tmp/ref_chroms.txt"

mkdir -p "$OUTDIR"
grep ">" "$REFERENCE" | awk '{print substr($1,2)}' > "$REF_IDS"

for d in "$SCAFFDIR"/*/; do
    sample=$(basename "$d")
    outpath="$OUTDIR/$sample"

    if [[ -f "$outpath/syri.out" ]]; then
        echo "SKIP: $sample"
        continue
    fi

    mkdir -p "$outpath"
    scaff="$d/ragtag.scaffold.fasta"

    python3 -I -c "
from Bio import SeqIO; import sys
ref_ids = set(open('$REF_IDS').read().split())
kept = 0
with open('${outpath}/query_placed.fasta','w') as out:
    for rec in SeqIO.parse('${scaff}','fasta'):
        name = rec.id.replace('_RagTag','')
        if name in ref_ids:
            rec.id = name; rec.description = name
            SeqIO.write(rec, out, 'fasta'); kept += 1
print(f'${sample}: {kept} placed', file=sys.stderr)
"

    nucmer --maxmatch -c 500 -b 500 -l 100 -t "$THREADS" \
        --prefix "$outpath/nucmer" \
        "$REFERENCE" "$outpath/query_placed.fasta" 2> "$outpath/nucmer.err"
    delta-filter -m -i 90 -l 100 "$outpath/nucmer.delta" > "$outpath/nucmer.filtered.delta"
    show-coords -THrd "$outpath/nucmer.filtered.delta" > "$outpath/nucmer.coords"

    echo "SyRI $sample ..."
    if ! syri -c "$outpath/nucmer.coords" -r "$REFERENCE" -q "$outpath/query_placed.fasta" \
         -k -F T --dir "$outpath" --nosnp 2> "$outpath/syri.err"; then
        echo "  -> retry with --no-chrmatch"
        syri -c "$outpath/nucmer.coords" -r "$REFERENCE" -q "$outpath/query_placed.fasta" \
             --no-chrmatch -F T --dir "$outpath" --nosnp 2>> "$outpath/syri.err" \
             || echo "  !! FAILED: $sample (see $outpath/syri.err)"
    fi
done

echo "Done."

#!/usr/bin/env bash
set -euo pipefail

REFERENCE="data/reference/GCF_000820605.1_genomic.fna"
ASSEMBLIES_DIR="data/assemblies"
OUTDIR="results/scaffolding"
THREADS=16

if [[ ! -f "$REFERENCE" ]]; then
    echo "ERROR: reference not found at $REFERENCE" >&2
    exit 1
fi

mkdir -p "$OUTDIR"

for asm in "$ASSEMBLIES_DIR"/*.fasta; do
    sample=$(basename "$asm" .fasta)
    outpath="$OUTDIR/$sample"

    if [[ -f "$outpath/ragtag.scaffold.fasta" ]]; then
        echo "SKIP: $sample (already done)"
        continue
    fi

    echo "Scaffolding $sample ..."
    ragtag.py scaffold \
        "$REFERENCE" \
        "$asm" \
        -o "$outpath" \
        -t "$THREADS" \
        --aligner minimap2 \
        -u
done

echo "Done. Scaffolded assemblies in $OUTDIR/*/ragtag.scaffold.fasta"

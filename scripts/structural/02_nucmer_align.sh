#!/usr/bin/env bash
set -euo pipefail

REFERENCE="data/reference/GCF_000820605.1_genomic.fna"
SCAFFDIR="results/scaffolding"
OUTDIR="results/alignment"
THREADS=16

mkdir -p "$OUTDIR"

for d in "$SCAFFDIR"/*/; do
    sample=$(basename "$d")
    query="$d/ragtag.scaffold.fasta"
    prefix="$OUTDIR/$sample"

    if [[ -f "${prefix}.delta" ]]; then
        echo "SKIP: $sample"
        continue
    fi

    echo "Aligning $sample ..."
    nucmer --maxmatch -c 500 -b 500 -l 100 \
        -t "$THREADS" \
        --prefix "$prefix" \
        "$REFERENCE" "$query"

    delta-filter -m -i 90 -l 100 "${prefix}.delta" > "${prefix}.filtered.delta"
    show-coords -THrd "${prefix}.filtered.delta" > "${prefix}.coords"
done

echo "Done."

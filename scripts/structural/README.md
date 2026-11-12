# Structural variation pipeline

Lineage-associated inversions in S. brasiliensis (Figure 10, Table S6).

## Steps
1. 01_ragtag_scaffold.sh  - RagTag scaffold of each assembly vs reference
2. 02_nucmer_align.sh     - NUCmer (MUMmer4) alignment of placed scaffolds
3. 03_syri.sh             - SyRI structural rearrangement calling
4. 04_aggregate_syri.sh   - per-isolate SV counts
5. 05_recurrent_rearrangements.sh - binned recurrence across isolates
6. 06_inversion_clusters.sh - cluster inversions by reciprocal overlap
7. 07_validate_breakpoints.sh - breakpoint consistency check
8. 08_inversion_map.sh    - Figure 10 (clade-associated inversion map)
9. 09_inversion_genes.sh  - genes within each inversion (RefSeq)

## Inputs
- Reference GCF_000820605.1 (genome + GFF)
- 71 assemblies (same set as the pangenome analysis)
- Lineage assignments: results/tables/virulence_isolates.tsv

## Dependencies
RagTag 2.1.1, MUMmer4, SyRI 1.8.2, samtools, Python (Biopython, numpy, matplotlib)
